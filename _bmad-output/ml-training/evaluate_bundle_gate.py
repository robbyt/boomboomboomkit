"""Story 12.9 provisional paired bundle gate (develop-only).

Only the frozen cohort determines lift. Four original DnB sentinels are a
separate required check; OA300 and GiantSteps are contextual reports only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import struct
from datetime import datetime, timezone
from pathlib import Path

from build_fr18_input import _tony_index, resolve_giantsteps, resolve_oa300, resolve_sentinels
from evaluate_fr18 import acc1_correct, compute_ece_half_double

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
FOUR_SENTINELS = ROOT / "Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json"
ATTESTATION = ROOT / "_bmad-output/implementation-artifacts/12-7-signoff-attestation.json"
COMMITMENT = ROOT / "_bmad-output/implementation-artifacts/12-7-candidate-commitment.json"
LEDGER_HEAD = ROOT / "_bmad-output/implementation-artifacts/12-7-annotation-ledger-head.json"
SLOW_BANDS = ("sub-100", "100-120")
BANDS = (*SLOW_BANDS, "120-140", "140-160", "160-175", "175-plus")
SEEDS = (42, 43, 44)
FAILED_SEED42_CHECKPOINT_SHA256 = "89eb32933789aa222bb2ffc9da273c8df2e2ce5f99608a3861903ae4bbd9e3ba"


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def checkpoint_digest(path: Path) -> str:
    """Match the producer's path-and-bytes digest over a compiled model bundle."""
    if path.is_file():
        return digest_bytes(path.read_bytes())
    if not path.is_dir():
        raise ValueError(f"checkpoint absent: {path}")
    files = sorted(p for p in path.rglob("*") if p.is_file())
    if not files or any(p.is_symlink() for p in path.rglob("*")):
        raise ValueError(f"checkpoint has no regular files or contains a symlink: {path}")
    hasher = hashlib.sha256()
    for file in files:
        relative = file.relative_to(path).as_posix().encode()
        hasher.update(struct.pack("<Q", len(relative)))
        hasher.update(relative)
        hasher.update(struct.pack("<Q", file.stat().st_size))
        with file.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                hasher.update(chunk)
    return hasher.hexdigest()


def load_cohort(path: Path) -> dict:
    doc = json.loads(path.read_text())
    claim = doc.pop("cohortSha256")
    actual = digest_bytes(json.dumps(doc, sort_keys=True, separators=(",", ":")).encode())
    if claim != actual:
        raise ValueError("cohort digest mismatch")
    doc["cohortSha256"] = claim
    rows = doc["tracks"]
    if len(rows) != doc["count"] or len({r["trackId"] for r in rows}) != len(rows):
        raise ValueError("cohort count or unique IDs disagree")
    if sum(r["category"] == "locked-12.7-member" for r in rows) != 172:
        raise ValueError("locked member subset is not 172")
    source = doc["source"]
    generation = source["generation"]
    gen_dir = HERE / "eval-corpus/generations" / generation
    current = {
        "commitmentSha256": COMMITMENT,
        "membershipSha256": gen_dir / "membership.json",
        "signedJamsSha256": gen_dir / "258-corpus.jams.json",
        "annotationLedgerSha256": gen_dir / "annotation-ledger.jsonl",
    }
    for field, source_path in current.items():
        if digest_bytes(source_path.read_bytes()) != source[field]:
            raise ValueError(f"frozen cohort source changed: {field}")
    membership = json.loads(current["membershipSha256"].read_text())
    signed = json.loads(current["signedJamsSha256"].read_text())
    member_bands = {rid: band for band, record in membership.items() for rid in record["members"]}
    signed_labels = {
        entry["file_metadata"]["identifiers"]["row_id"]: entry["annotations"][0]["data"][0]["value"]
        for entry in signed["entries"]
    }
    locked = {r["trackId"]: r for r in rows if r["category"] == "locked-12.7-member"}
    if (
        len(member_bands) != 172
        or len(signed_labels) != len(signed["entries"])
        or set(locked) != set(member_bands)
        or set(locked) != set(signed_labels)
    ):
        raise ValueError("frozen locked IDs differ from signed 12.7 membership")
    for rid, row in locked.items():
        truth = signed_labels[rid]
        if (
            row["groundTruthBPM"] != truth
            or row["sourceBand"] != member_bands[rid]
            or row["verifiedBand"] != band_of(truth)
        ):
            raise ValueError(f"frozen locked label or band differs from signed 12.7: {rid}")
    return doc


def band_of(bpm: float) -> str:
    for name, low, high in (
        ("sub-100", 0, 100),
        ("100-120", 100, 120),
        ("120-140", 120, 140),
        ("140-160", 140, 160),
        ("160-175", 160, 175),
        ("175-plus", 175, math.inf),
    ):
        if low <= bpm < high:
            return name
    raise ValueError(f"invalid tempo {bpm}")


def four_sentinel_rows() -> list[dict]:
    fixture = json.loads(FOUR_SENTINELS.read_text())
    originals = fixture["entries"][:4]
    ids = [r["file_metadata"]["identifiers"]["track_id"] for r in originals]
    resolved = {
        r["trackId"]: r
        for r in resolve_sentinels(os.getenv("OA300_CORPUS_PATH", ""), _tony_index())
    }
    if set(ids) - resolved.keys():
        raise ValueError(f"four sentinels unresolved: {sorted(set(ids) - resolved.keys())}")
    rows = []
    for original in originals:
        track_id = original["file_metadata"]["identifiers"]["track_id"]
        r = resolved[track_id]
        truth = original["annotations"][0]["data"][0]["value"]
        if r["groundTruthBPM"] != truth:
            raise ValueError(f"expanded sentinel label differs from original for {track_id}")
        rows.append(
            {
                "trackId": f"sentinel:{track_id}",
                "audioPath": r["audioPath"],
                "audioSha256": digest_bytes(Path(r["audioPath"]).read_bytes()),
                "groundTruthBPM": truth,
                "sourceBand": "sentinel",
                "verifiedBand": band_of(truth),
                "category": "sentinel-four",
            }
        )
    return rows


def prepare(cohort: dict, seed: int, include_legacy: bool = False) -> dict:
    rows = list(cohort["tracks"])
    rows.extend(four_sentinel_rows())
    if include_legacy:
        sources = (
            ("legacy-oa300", resolve_oa300(os.getenv("OA300_CORPUS_PATH", ""))),
            ("legacy-giantsteps", resolve_giantsteps(os.getenv("GIANTSTEPS_CORPUS_PATH", ""))),
        )
        for category, source_rows in sources:
            for index, r in enumerate(source_rows):
                rows.append(
                    {
                        "trackId": f"{category}:{index:04d}:{r['trackId']}",
                        "audioPath": r["audioPath"],
                        "audioSha256": digest_bytes(Path(r["audioPath"]).read_bytes()),
                        "groundTruthBPM": r["groundTruthBPM"],
                        "sourceBand": category,
                        "verifiedBand": band_of(r["groundTruthBPM"]),
                        "category": category,
                    }
                )
    if len({r["trackId"] for r in rows}) != len(rows):
        raise ValueError("duplicate input track ID")
    return {"cohortSha256": cohort["cohortSha256"], "seed": seed, "tracks": rows}


def exact_mcnemar_p(gains: int, losses: int) -> float:
    """Exact two-sided binomial McNemar, including the zero-discordance case."""
    if gains < 0 or losses < 0:
        raise ValueError("negative discordance")
    d = gains + losses
    if d == 0:
        return 1.0
    tail = sum(math.comb(d, i) for i in range(min(gains, losses) + 1))
    return min(1.0, 2.0 * tail / (2**d))


def required_net_lift(discordance: int) -> int | None:
    for gains in range(discordance // 2 + 1, discordance + 1):
        losses = discordance - gains
        if exact_mcnemar_p(gains, losses) <= 0.05:
            return gains - losses
    return None


def paired_table(rows: list[dict]) -> dict:
    n = len(rows)
    dsp_correct = sum(acc1_correct(r.get("dspBPM"), r["groundTruthBPM"]) for r in rows)
    ml_correct = sum(acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"]) for r in rows)
    gains = sum(
        not acc1_correct(r.get("dspBPM"), r["groundTruthBPM"])
        and acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"])
        for r in rows
    )
    losses = sum(
        acc1_correct(r.get("dspBPM"), r["groundTruthBPM"])
        and not acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"])
        for r in rows
    )
    d = gains + losses
    return {
        "n": n,
        "dspCorrect": dsp_correct,
        "ensembleCorrect": ml_correct,
        "bGains": gains,
        "cLosses": losses,
        "dDiscordant": d,
        "netTracks": gains - losses,
        "exactTwoSidedP": exact_mcnemar_p(gains, losses),
        "requiredNetTracksAtObservedDiscordance": required_net_lift(d),
    }


def score_seed(cohort: dict, rows: list[dict]) -> dict:
    by_id = {r["trackId"]: r for r in rows}
    gate_ids = {r["trackId"] for r in cohort["tracks"]}
    if not gate_ids <= by_id.keys():
        raise ValueError("predictions omit frozen cohort rows")
    gate_rows = [by_id[rid] for rid in sorted(gate_ids)]
    paired = paired_table(gate_rows)
    paired["state"] = (
        "pass" if paired["netTracks"] > 0 and paired["exactTwoSidedP"] <= 0.05 else "fail"
    )
    band_reports = {}
    for band in BANDS:
        subset = [r for r in gate_rows if r["verifiedBand"] == band]
        table = paired_table(subset)
        threshold = math.ceil(30 * len(subset) / 43) if len(subset) >= 43 else None
        handled = threshold is not None and table["dspCorrect"] >= threshold
        table.update(
            {
                "dspHandledThreshold": threshold,
                "dspHandled": handled,
                "state": (
                    "unmeasurable"
                    if threshold is None
                    else "fail"
                    if handled and table["bGains"] < table["cLosses"]
                    else "pass"
                ),
            }
        )
        band_reports[band] = table
    locked = paired_table([r for r in gate_rows if r["category"] == "locked-12.7-member"])
    ece_rows = [
        {
            "groundTruthBPM": r["groundTruthBPM"],
            "fr18ModelBPM": r.get("modelBPM"),
            "softmaxMax": r.get("softmaxMax"),
            "dspCandidatesTop3": r.get("dspCandidatesTop3", []),
        }
        for r in gate_rows
    ]
    calibration = compute_ece_half_double(ece_rows)
    sentinel_rows = sorted(
        (r for r in rows if r["category"] == "sentinel-four"),
        key=lambda r: r["trackId"],
    )
    sentinels = {
        "state": (
            "pass"
            if len(sentinel_rows) == 4
            and all(acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"]) for r in sentinel_rows)
            else "fail"
        ),
        "correct": sum(
            acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"]) for r in sentinel_rows
        ),
        "n": len(sentinel_rows),
        "rows": [
            {
                "trackId": r["trackId"],
                "dspCorrect": acc1_correct(r.get("dspBPM"), r["groundTruthBPM"]),
                "ensembleCorrect": acc1_correct(r.get("ensembleBPM"), r["groundTruthBPM"]),
            }
            for r in sentinel_rows
        ],
    }
    legacy = {}
    for category in ("legacy-oa300", "legacy-giantsteps"):
        context_rows = [r for r in rows if r["category"] == category]
        legacy[category] = (
            paired_table(context_rows) if context_rows else {"state": "not-run", "n": 0}
        )
    return {
        "paired": paired,
        "bands": band_reports,
        "locked172": locked,
        "calibration": calibration,
        "fourSentinels": sentinels,
        "legacyContextOnly": legacy,
        "mlAbstains": sum(r.get("mlAbstained") is True for r in gate_rows),
    }


def _read_run(run_dir: Path, cohort: dict) -> tuple[int, list[dict], dict]:
    manifest = json.loads((run_dir / "manifest.json").read_text())
    prediction_bytes = (run_dir / "predictions.json").read_bytes()
    rows = json.loads(prediction_bytes)
    seed = manifest["seed"]
    input_path = run_dir.parent / f"bundle-gate-input-seed-{seed}.json"
    raw_input = input_path.read_bytes()
    input_doc = json.loads(raw_input)
    input_ids = {r["trackId"] for r in input_doc["tracks"]}
    row_ids = {r["trackId"] for r in rows}
    if (
        manifest["harnessVersion"] != 1
        or manifest["cohortSha256"] != cohort["cohortSha256"]
        or input_doc["cohortSha256"] != cohort["cohortSha256"]
        or input_doc["seed"] != seed
        or manifest["inputSha256"] != digest_bytes(raw_input)
        or manifest["ensemblePolicy"] != "default"
        or not re.fullmatch(r"[0-9a-f]{64}", manifest["checkpointSha256"])
        or manifest["checkpointSha256"] != checkpoint_digest(Path(manifest["checkpointPath"]))
        or manifest["predictionsSha256"] != digest_bytes(prediction_bytes)
        or manifest["expectedTrackCount"] != len(input_ids)
        or manifest["actualTrackCount"] != len(rows)
        or manifest["unresolvedTracks"]
        or input_ids != row_ids
        or len(rows) != len(row_ids)
    ):
        raise ValueError(f"incomplete, stale, or nondefault production run {run_dir}")
    expected = {r["trackId"]: r for r in input_doc["tracks"]}
    frozen = {r["trackId"]: r for r in cohort["tracks"]}
    for track_id, row in frozen.items():
        if expected.get(track_id) != row:
            raise ValueError(f"frozen gate input changed for {track_id}")
    sentinels = {r["trackId"]: r for r in four_sentinel_rows()}
    input_sentinels = {
        rid: row for rid, row in expected.items() if row["category"] == "sentinel-four"
    }
    if input_sentinels != sentinels:
        raise ValueError("four original sentinel IDs, labels, or audio hashes changed")
    for row in rows:
        source = expected[row["trackId"]]
        for field in ("groundTruthBPM", "sourceBand", "verifiedBand", "category"):
            if row[field] != source[field]:
                raise ValueError(f"prediction metadata changed for {row['trackId']}")
    provenance = {
        "checkpointSha256": manifest["checkpointSha256"],
        "modelIdentifier": manifest["modelIdentifier"],
        "gitSha": manifest["gitSha"],
        "inputSha256": manifest["inputSha256"],
        "predictionsSha256": manifest["predictionsSha256"],
        "expectedTrackCount": manifest["expectedTrackCount"],
        "actualTrackCount": manifest["actualTrackCount"],
    }
    return seed, rows, provenance


def member_signoff_reasons() -> list[str]:
    """Validate 12.7's attestation, which covers members but not new gate rows."""
    if not ATTESTATION.exists():
        return ["12.7 signoff attestation absent"]
    # This is the same validator used by the training gate. Import only
    # here; provisional negative-control runs need no mutable 12.7 state.
    import importlib.util
    import sys

    path = ROOT / "scripts/build-eval-corpus.py"
    spec = importlib.util.spec_from_file_location("eval_corpus_harness", path)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load signoff validator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.validate_attestation(
        ATTESTATION,
        COMMITMENT,
        LEDGER_HEAD,
        43,
        state_root=HERE / "eval-corpus",
    )


def signoff_reasons(cohort: dict) -> list[str]:
    reasons = []
    if any(cohort["verifiedBands"][band] < 43 for band in SLOW_BANDS):
        reasons.append("slow-band coverage below 43")
    reasons += member_signoff_reasons()
    # The 12.7 signoff covers only its 172 members. The 73 additional rows
    # have no FR-59d training-overlap certificate. Until a later story adds a
    # cohort-bound closure audit and validates it here, approval is impossible.
    reasons.append("expanded gate cohort training-partition closure is not certified")
    return reasons


def seed_robustness_state(reports: dict[int, dict], provenance: dict[int, dict]) -> str:
    if set(reports) != set(SEEDS):
        return "inconclusive"
    hashes = [provenance.get(seed, {}).get("checkpointSha256") for seed in SEEDS]
    if any(not value for value in hashes):
        return "inconclusive"
    if len(set(hashes)) != len(SEEDS):
        return "fail"
    net = [reports[seed]["paired"]["netTracks"] for seed in SEEDS]
    return "pass" if max(net) - min(net) <= 10 else "fail"


def negative_control_rejected(report: dict) -> bool:
    """Only the known failed seed-42 checkpoint's own gates count."""
    provenance = report.get("runProvenance", {})
    seed_provenance = provenance.get(42) or provenance.get("42") or {}
    if seed_provenance.get("checkpointSha256") != FAILED_SEED42_CHECKPOINT_SHA256:
        return False
    seed = report.get("seeds", {}).get(42) or report.get("seeds", {}).get("42")
    if seed is None:
        return False
    return bool(
        seed["paired"]["state"] == "fail"
        or seed["calibration"]["state"] == "fail"
        or seed["fourSentinels"]["state"] == "fail"
        or any(band["state"] == "fail" for band in seed["bands"].values())
    )


def evaluate(
    cohort: dict, runs: dict[int, list[dict]], provenance: dict[int, dict] | None = None
) -> dict:
    if not runs:
        raise ValueError("no production runs")
    reports = {seed: score_seed(cohort, rows) for seed, rows in sorted(runs.items())}
    gate_names = ("paired", "calibration", "fourSentinels")
    substantive = [
        f"seed {seed} {name}={report[name]['state']}"
        for seed, report in reports.items()
        for name in gate_names
        if report[name]["state"] == "fail"
    ]
    for seed, report in reports.items():
        substantive += [
            f"seed {seed} band {band} regression"
            for band, table in report["bands"].items()
            if table["state"] == "fail"
        ]
    stability = seed_robustness_state(reports, provenance or {})
    if stability == "fail":
        substantive.append("seed robustness failed: repeated checkpoint or net-lift dispersion")
    reasons = signoff_reasons(cohort)
    if set(runs) != set(SEEDS):
        reasons.append("three distinct frozen seeds 42/43/44 have not run")
    if stability != "pass":
        reasons.append(f"seed robustness {stability}")
    if any(r["calibration"]["state"] != "pass" for r in reports.values()):
        reasons.append("calibration failed or inconclusive")
    if any(r["fourSentinels"]["state"] != "pass" for r in reports.values()):
        reasons.append("four-sentinel gate failed")
    if any(r["paired"]["state"] != "pass" for r in reports.values()):
        reasons.append("paired lift gate failed")
    if any(
        table["state"] != "pass"
        for report in reports.values()
        for table in report["bands"].values()
    ):
        reasons.append("band regression or unmeasurable band")
    return {
        "schemaVersion": 1,
        "created": datetime.now(timezone.utc).isoformat(),
        "cohortSha256": cohort["cohortSha256"],
        "cohortCount": cohort["count"],
        "trainingOverlapLimit": (
            "Provisional only: 12.7 FR-59d training-manifest rebuild and partition "
            "closure have not been signed. Current model may have trained on gate audio."
        ),
        "seeds": reports,
        "seedRobustness": stability,
        "substantiveFailures": substantive,
        "approvalRefusals": reasons,
        "decision": "bundle" if not reasons else "refused",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cohort", required=True, type=Path)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--input-out", type=Path)
    parser.add_argument("--include-legacy", action="store_true")
    parser.add_argument("--predictions", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--request-approval", action="store_true")
    parser.add_argument("--negative-control", action="store_true")
    args = parser.parse_args()
    cohort = load_cohort(args.cohort)
    if args.input_out:
        if args.seed is None:
            parser.error("--input-out requires --seed")
        doc = prepare(cohort, args.seed, args.include_legacy)
        args.input_out.parent.mkdir(parents=True, exist_ok=True)
        args.input_out.write_text(json.dumps(doc, indent=2, sort_keys=True) + "\n")
        print(f"input: {len(doc['tracks'])} tracks, seed {args.seed} -> {args.input_out}")
        return 0
    if args.predictions is None or args.report is None:
        parser.error("evaluation requires --predictions and --report")
    runs = {}
    provenance = {}
    for run_dir in sorted(args.predictions.glob("seed_*")):
        if not run_dir.is_dir():
            continue
        seed, rows, run_provenance = _read_run(run_dir, cohort)
        if seed in runs or run_dir.name != f"seed_{seed}":
            raise ValueError("duplicate or mislabeled seed directory")
        runs[seed] = rows
        provenance[seed] = run_provenance
    report = evaluate(cohort, runs, provenance)
    report["runProvenance"] = provenance
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    summary = {
        "decision": report["decision"],
        "substantiveFailures": report["substantiveFailures"],
        "approvalRefusals": report["approvalRefusals"],
        "paired": {s: r["paired"] for s, r in report["seeds"].items()},
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    if args.negative_control and not negative_control_rejected(report):
        raise ValueError(
            "known failed seed-42 checkpoint had no substantive model/ensemble failure"
        )
    if args.request_approval and report["decision"] != "bundle":
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, KeyError, ValueError, TypeError) as exc:
        raise SystemExit(f"bundle gate refused: {exc}") from exc
