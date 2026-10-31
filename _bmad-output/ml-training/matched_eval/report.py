"""Per-track rows, pairings and the tracked aggregate of the Story 15.9 evaluation.

Systems, in pairing order (the right-hand system of a pairing is always the later
one, so `oracle` is always on the right):

  boomboomboomkit-optimal   the shipped pipeline at default options
  variant-joint-fit         Story 15.7 joint tempo and phase fit
  variant-comb-best-phase   the default grid re-anchored at the onset-comb best phase
  variant-fixed-time        Story 15.5 fixed-time model, read from its scores files;
                            tempo families only, runtime and memory not comparable
  commercial-analyzer       a commercial DJ analyzer's BPM from the OA300 label file;
                            OA300 only, version and mode unrecorded, no grid
  oracle                    the corpus's independent reference

A pairing whose right-hand system is `oracle` is `system-vs-reference`; every
other pairing, including any `boomboomboomkit-*` against `commercial-analyzer`,
is `system-vs-system`. Agreement with the commercial analyzer is never evidence
of correctness.

The tracked aggregate holds counts, summaries, intervals and digests only. The
per-track rows go to the gitignored run directory.
"""

from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

import numpy as np

from matched_eval import corpora as cp
from matched_eval import metrics as mt
from matched_eval import stats as st

SYSTEMS = (
    "boomboomboomkit-optimal",
    "variant-joint-fit",
    "variant-comb-best-phase",
    "variant-fixed-time",
    "commercial-analyzer",
    "oracle",
)
SWIFT_SYSTEMS = SYSTEMS[:3]
FIXED_TIME = "variant-fixed-time"
COMMERCIAL = "commercial-analyzer"
ORACLE = "oracle"
SYSTEM_VS_REFERENCE = "system-vs-reference"
SYSTEM_VS_SYSTEM = "system-vs-system"
AGGREGATE_SCHEMA = "15.9-aggregate.v1"
ROWS_SCHEMA = "15.9-rows.v1"

SYSTEM_DESCRIPTIONS = {
    "boomboomboomkit-optimal": (
        "AudioAnalysisService.analyze(url:) at default options (TechniqueSet.optimal); "
        "grid = beat-grid tempo extrapolated from gridOrigin"
    ),
    "variant-joint-fit": (
        "Story 15.7: DSP stub observations -> bar-state decode at the default BPM and the "
        "quarter level (the level the BPM stage chose; the fit never changes octave) -> joint "
        "tempo and phase fit, on the default pass's decode; a nil decode or fit abstains; "
        "the metrical-level selector's choice is recorded per row as a diagnostic only"
    ),
    "variant-comb-best-phase": (
        "Story 15.10 follow-up: the default grid re-anchored at the onset-comb best phase "
        "(internal BeatGridAnalyzer hook), observed on the default pass's decode; BPM answer "
        "unchanged from the default; refused per track when the observed run's output "
        "differs; runtime and memory not-comparable"
    ),
    "variant-fixed-time": (
        "Story 15.5 fixed-time model, BPM read from its scores files; tempo families only; "
        "Python inference, so runtime and memory are not-comparable with the Swift rows"
    ),
    "commercial-analyzer": (
        "a commercial DJ analyzer's BPM as recorded in the OA300 label file; version "
        "unrecorded, analysis mode unrecorded; no grid; OA300 only; a system under test, "
        "never the reference"
    ),
    "oracle": "the corpus's independent reference",
}
COMMERCIAL_VERSION = "unrecorded"
COMMERCIAL_MODE = "unrecorded"

# Words the tracked summary and JSON must never contain: they would read as a
# claim about how two systems compare. Directions are stated only as the sign of a
# paired difference with its pairing, n, interval, p and q beside it.
FORBIDDEN_WORDS = re.compile(
    r"\b(meet|meets|meeting|met|match|matches|matched|matching|approach|approaches|"
    r"approached|approaching|exceed|exceeds|exceeded|exceeding|parity|on par|on a par|"
    r"outperform\w*|surpass\w*|better|worse|ahead|level with|equivalent|comparable|"
    r"beats)\b",
    re.IGNORECASE,
)
# Literal names this harness must emit that contain one of the words above (its own
# files and targets, and the spec's `not-comparable` status); removed before the scan.
ALLOWED_LITERALS = (
    "matched-eval-runs",
    "matched-eval-run",
    "matched-eval",
    "matched_eval",
    "not-comparable",
)
EXPECTED_RUNNER_BUILD = "release -Xswiftc -enable-testing"


class ReportRefusal(RuntimeError):
    """Inputs do not join exactly; nothing is written."""


class WordingViolation(ValueError):
    """The summary text contains a forbidden comparison word."""


def pairings() -> list[tuple[str, str]]:
    return [(a, b) for i, a in enumerate(SYSTEMS) for b in SYSTEMS[i + 1 :]]


def pairing_label(a: str, b: str) -> str:
    return SYSTEM_VS_REFERENCE if b == ORACLE else SYSTEM_VS_SYSTEM


def check_wording(text: str) -> None:
    scrubbed = text
    for literal in ALLOWED_LITERALS:
        scrubbed = scrubbed.replace(literal, "")
    hits = sorted({m.group(0).lower() for m in FORBIDDEN_WORDS.finditer(scrubbed)})
    if hits:
        raise WordingViolation(f"tracked output contains forbidden comparison words: {hits}")


def assert_no_track_identifiers(text: str, manifest: dict[str, Any]) -> None:
    """Refuse if any track id, audio path or audio hash appears in `text`."""
    leaked: set[str] = set()
    for doc in manifest["corpora"].values():
        for r in doc["rows"]:
            for value in (r["trackId"], r["audioPath"], r["audioSha256"]):
                if value and value in text:
                    leaked.add(str(r["corpus"]))
    if leaked:
        raise ReportRefusal(f"tracked aggregate would carry track identifiers: {sorted(leaked)}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json(doc: Any) -> bytes:
    return (json.dumps(doc, indent=2, sort_keys=True, allow_nan=False) + "\n").encode("utf-8")


# ---------------------------------------------------------------------------
# System records
# ---------------------------------------------------------------------------


def check_runner_provenance(runner_doc: dict[str, Any], git: dict[str, Any]) -> None:
    """Refuse a runner output built from other code or in another configuration."""
    problems = []
    if runner_doc.get("gitSha") != git["sha"] or runner_doc.get("dirty") != git["dirty"]:
        problems.append(
            f"runner output is from {runner_doc.get('gitSha')} (dirty {runner_doc.get('dirty')}), "
            f"the report is at {git['sha']} (dirty {git['dirty']})"
        )
    if runner_doc.get("buildConfiguration") != EXPECTED_RUNNER_BUILD:
        problems.append(
            f"runner build {runner_doc.get('buildConfiguration')!r}, expected "
            f"{EXPECTED_RUNNER_BUILD!r}"
        )
    if problems:
        raise ReportRefusal("; ".join(problems))


def restrict_to_runner(manifest: dict[str, Any], runner_doc: dict[str, Any]) -> dict[str, Any]:
    """For a runner output that declares `--limit N`: the manifest cut to the tracks
    the runner ran, which must be N tracks (or all of them) of the manifest."""
    limit = runner_doc.get("limit")
    if limit is None:
        return manifest
    ran = {(t["corpus"], t["trackId"]) for t in runner_doc["tracks"]}
    total = sum(len(d["rows"]) for d in manifest["corpora"].values())
    known = {(c, r["trackId"]) for c, d in manifest["corpora"].items() for r in d["rows"]}
    if not ran <= known or len(ran) != min(int(limit), total):
        raise ReportRefusal(f"runner output declares limit {limit} but covers {len(ran)} tracks")
    corpora = {}
    for c, d in manifest["corpora"].items():
        rows = [r for r in d["rows"] if (c, r["trackId"]) in ran]
        if rows:
            corpora[c] = {**d, "rows": rows}
    return {**manifest, "corpora": corpora, "limit": int(limit)}


def index_runner(runner_doc: dict[str, Any] | None) -> dict[tuple[str, str], dict[str, Any]]:
    if runner_doc is None:
        return {}
    out: dict[tuple[str, str], dict[str, Any]] = {}
    for t in runner_doc["tracks"]:
        key = (t["corpus"], t["trackId"])
        if key in out:
            raise ReportRefusal(f"runner output lists one {t['corpus']} track twice")
        out[key] = t
    return out


def load_fixed_time_scores(fixed_time_dir: Path | None, corpus: str) -> dict[str, Any] | None:
    """The 15.5 scores for `corpus`, or None when no 15.5 run was given or the 15.5
    run scored no such corpus (the synthetic clicks). A given run directory without
    the corpus's scores file refuses."""
    if fixed_time_dir is None or corpus == cp.SYNTHETIC:
        return None
    path = fixed_time_dir / f"scores-{corpus}.json"
    if not path.is_file():
        raise ReportRefusal(f"15.5 run directory has no scores-{corpus}.json")
    doc = json.loads(path.read_text())
    doc["_sha256"] = cp.sha256_file(path)
    doc["_by_id"] = {r["trackId"]: r for r in doc["rows"]}
    return doc


def fixed_time_record(scores: dict[str, Any] | None, row: dict[str, Any]) -> dict[str, Any]:
    base: dict[str, Any] = {"gridFamilies": mt.NO_DATA, "runtimeStatus": mt.NOT_COMPARABLE}
    if scores is None:
        return {**base, "status": mt.NOT_RUN, "reason": "no 15.5 scores for this corpus"}
    identity = (
        f"15.5 fixed-time model, weights sha256 {scores.get('weightsSha256')}, input contract "
        f"{scores.get('inputContract')}, aggregator {scores.get('aggregator')}, scores file "
        f"sha256 {scores['_sha256']}"
    )
    base.update(
        {
            "variantIdentity": identity,
            "buildConfiguration": f"python (15.5 score run at {scores.get('codeGitSha')})",
        }
    )
    scored = scores["_by_id"].get(row["trackId"])
    if scored is None:
        return {**base, "status": mt.NOT_RUN, "reason": "track not in the 15.5 scores file"}
    if scored.get("audioSha256") != row["audioSha256"]:
        raise ReportRefusal(f"{row['corpus']}: audio differs from the 15.5 scoring run")
    if scored.get("abstained"):
        return {**base, "status": mt.ABSTAINED, "reason": str(scored["abstained"])}
    if scored.get("variantBPM") is None:
        return {**base, "status": mt.ABSTAINED, "reason": "no BPM in the 15.5 scores"}
    return {
        **base,
        "status": mt.OK,
        "reason": None,
        "tempoBPM": float(scored["variantBPM"]),
        "inRuntimeRange": scored.get("inRuntimeRange"),
    }


def commercial_record(corpus: str, row: dict[str, Any]) -> dict[str, Any]:
    base: dict[str, Any] = {
        "gridFamilies": mt.NO_DATA,
        "runtimeStatus": mt.NOT_APPLICABLE,
        "variantIdentity": (
            f"commercial-analyzer, version {COMMERCIAL_VERSION}, mode {COMMERCIAL_MODE}, "
            "BPM from the OA300 label file"
        ),
        "buildConfiguration": "not-applicable (recorded values)",
        "analyzerVersion": COMMERCIAL_VERSION,
        "analyzerMode": COMMERCIAL_MODE,
    }
    if corpus != "oa300" or row.get("commercialBPM") is None:
        return {**base, "status": mt.NOT_RUN, "reason": "commercial-analyzer values: OA300 only"}
    return {**base, "status": mt.OK, "reason": None, "tempoBPM": float(row["commercialBPM"])}


# ---------------------------------------------------------------------------
# Per-track rows
# ---------------------------------------------------------------------------


def build_rows(
    manifest: dict[str, Any],
    manifest_sha256: str,
    runner_doc: dict[str, Any] | None,
    fixed_time_dir: Path | None,
    git: dict[str, Any],
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """One row per (track, system). Refuses unless the runner output covers
    exactly the manifest's tracks with the same audio hashes."""
    runner = index_runner(runner_doc)
    expected = {(c, r["trackId"]) for c, d in manifest["corpora"].items() for r in d["rows"]}
    if set(runner) != expected:
        missing = len(expected - set(runner))
        extra = len(set(runner) - expected)
        raise ReportRefusal(
            f"runner output does not cover the manifest: {missing} missing, {extra} extra"
        )
    rows: list[dict[str, Any]] = []
    fixed_time_digests: dict[str, str | None] = {}
    for corpus, doc in manifest["corpora"].items():
        scores = load_fixed_time_scores(fixed_time_dir, corpus)
        fixed_time_digests[corpus] = None if scores is None else scores["_sha256"]
        reference = doc["sources"]["reference"]
        for r in doc["rows"]:
            ran = runner[(corpus, r["trackId"])]
            if ran["audioSha256"] != r["audioSha256"]:
                raise ReportRefusal(f"{corpus}: runner audio hash differs from the manifest")
            records = {s: ran["systems"][s] for s in SWIFT_SYSTEMS}
            records[FIXED_TIME] = fixed_time_record(scores, {**r, "corpus": corpus})
            records[COMMERCIAL] = commercial_record(corpus, r)
            records = {k: mt.normalize_record(v) for k, v in records.items()}
            ref_bpm = float(r["referenceBPM"])
            for system in SYSTEMS:
                common = {
                    "corpus": corpus,
                    "trackId": r["trackId"],
                    "system": system,
                    "referenceBPM": ref_bpm,
                    "band": st.tempo_band(ref_bpm),
                    "style": r["style"],
                    "annotated": r.get("annotation") is not None,
                }
                if system == ORACLE:
                    record: dict[str, Any] = {
                        "status": mt.REFERENCE,
                        "reason": None,
                        "tempoBPM": ref_bpm,
                        "variantIdentity": f"{doc['referenceKind']} reference",
                        "buildConfiguration": "not-applicable (reference)",
                    }
                    families = mt.reference_families(r.get("annotation"))
                else:
                    record = records[system]
                    comparable = (
                        system in SWIFT_SYSTEMS
                        and record["status"] in (mt.OK, mt.ABSTAINED)
                        and record.get("runtimeComparable", True) is not False
                        and record.get("runtimeSeconds") is not None
                        and record.get("peakMemoryAboveBaselineBytes") is not None
                    )
                    if system in SWIFT_SYSTEMS and not comparable:
                        record = {**record, "runtimeStatus": mt.NOT_COMPARABLE}
                    families = mt.evaluate(
                        record, ref_bpm, r.get("annotation"), runtime_comparable=comparable
                    )
                rows.append(
                    {
                        **common,
                        "status": record["status"],
                        "reason": record.get("reason"),
                        "tempoBPM": record.get("tempoBPM"),
                        "families": families,
                        "details": {
                            k: v
                            for k, v in record.items()
                            if k not in ("status", "reason", "tempoBPM", "variantIdentity")
                        },
                        "provenance": {
                            "gitSha": git["sha"],
                            "dirty": git["dirty"],
                            "buildConfiguration": record.get("buildConfiguration"),
                            "system": system,
                            "variantIdentity": record.get("variantIdentity"),
                            "corpusManifestSha256": manifest_sha256,
                            "audioSha256": r["audioSha256"],
                            "referenceSource": reference["name"],
                            "referenceSha256": reference["sha256"],
                            "referenceKind": doc["referenceKind"],
                        },
                    }
                )
    return rows, fixed_time_digests


# ---------------------------------------------------------------------------
# Summaries
# ---------------------------------------------------------------------------


def _strata(rows: list[dict[str, Any]], corpus: str) -> dict[str, list[str]]:
    """Stratum -> track ids, from the oracle rows (one per track)."""
    out: dict[str, list[str]] = {}
    for r in rows:
        if r["corpus"] != corpus or r["system"] != ORACLE:
            continue
        for s in st.strata_of(r["referenceBPM"], r["style"]):
            out.setdefault(s, []).append(r["trackId"])
    return out


def _stratum_sort_key(name: str) -> tuple[int, int, str]:
    if name == "overall":
        return (0, 0, name)
    if name.startswith("band:"):
        band = name.split(":", 1)[1]
        names = [b[0] for b in st.TEMPO_BANDS]
        return (1, names.index(band) if band in names else len(names), name)
    return (2, 0, name)


def direction_sentence(
    corpus: str, a: str, b: str, label: str, metric: str, s: dict[str, Any], tag: str | None
) -> str | None:
    """The only form a direction takes: the sign of the paired difference's
    interval, with pairing, label, n, interval, p and q beside it. None unless
    `stats.direction_allowed` (paired n >= 10, interval excludes zero, q < 0.05)."""
    if not st.direction_allowed(s):
        return None
    lo, hi = s["interval95"]
    sign = "above zero" if lo > 0 else "below zero"
    tag_text = f", {tag}" if tag else ""
    return (
        f"{corpus}, `{a}` vs `{b}` ({label}{tag_text}), {metric}: the {s['statistic']} paired "
        f"difference ({a} minus {b}) is {sign}: {s['estimate']:.6g}, n = {s['n']}, "
        f"95 % interval [{lo:.6g}, {hi:.6g}], p = {s['p_value']:.3g} ({s['p_note']}), "
        f"q = {s['q_value']:.3g}."
    )


def metric_values(
    rows: list[dict[str, Any]], corpus: str
) -> dict[tuple[str, str], dict[str, float]]:
    """(system, metric) -> {trackId: value} for every value present."""
    out: dict[tuple[str, str], dict[str, float]] = {}
    for r in rows:
        if r["corpus"] != corpus:
            continue
        for _family, metric, get in mt.METRICS:
            v = get(r["families"])
            if v is not None:
                out.setdefault((r["system"], metric), {})[r["trackId"]] = v
    return out


def system_summaries(
    rows: list[dict[str, Any]], corpus: str, strata: dict[str, list[str]]
) -> dict[str, Any]:
    """Per system and stratum: status counts, coverage (share of the system's run
    tracks with an answer), and metric summaries (n, mean, median) of the system's
    own values. Accuracy rates count an abstention or failure as incorrect."""
    by_system: dict[str, dict[str, dict[str, Any]]] = {}
    for r in rows:
        if r["corpus"] == corpus:
            by_system.setdefault(r["system"], {})[r["trackId"]] = r
    out: dict[str, Any] = {}
    for system in SYSTEMS:
        tracks = by_system.get(system, {})
        per: dict[str, Any] = {}
        for stratum, ids in strata.items():
            sel = [tracks[i] for i in ids if i in tracks]
            outcomes = Counter(t["status"] for t in sel)
            ran = sum(outcomes[k] for k in (mt.OK, mt.ABSTAINED, mt.FAILED, mt.REFERENCE))
            metrics: dict[str, Any] = {}
            for _family, metric, get in mt.METRICS:
                vals = [v for v in (get(t["families"]) for t in sel) if v is not None]
                if vals:
                    metrics[metric] = {
                        "n": len(vals),
                        "mean": float(np.mean(vals)),
                        "median": float(np.median(vals)),
                        "underpowered": len(vals) < st.UNDERPOWERED_BELOW,
                    }
            per[stratum] = {
                "n": len(sel),
                "outcomes": dict(outcomes),
                "coverage": None if ran == 0 else (outcomes[mt.OK] + outcomes[mt.REFERENCE]) / ran,
                "metrics": metrics,
            }
            if stratum == "overall":
                per[stratum]["familyStatus"] = {
                    f: dict(Counter(t["families"][f]["status"] for t in sel)) for f in mt.FAMILIES
                }
        out[system] = per
    return out


def pairing_summaries(
    rows: list[dict[str, Any]], corpus: str, strata: dict[str, list[str]], tag: str | None
) -> tuple[list[dict[str, Any]], int]:
    """Every pairing x metric x stratum summary, with Benjamini-Hochberg q-values
    over all of them (the corpus's tests) and a direction where allowed. Returns
    the pairings and the number of tests."""
    values = metric_values(rows, corpus)
    out: list[dict[str, Any]] = []
    tests: list[dict[str, Any]] = []
    for a, b in pairings():
        label = pairing_label(a, b)
        for family, metric, _get in mt.METRICS:
            va = values.get((a, metric), {})
            vb = values.get((b, metric), {})
            if not va or not vb:
                continue
            per: dict[str, Any] = {}
            for stratum, ids in strata.items():
                diffs = [va[i] - vb[i] for i in ids if i in va and i in vb]
                if not diffs:
                    continue
                s = st.paired_summary(
                    diffs,
                    f"{corpus}|{a}|{b}|{metric}|{stratum}",
                    yes_no=metric in mt.YES_NO_METRICS,
                )
                per[stratum] = s
                tests.append(s)
            if per:
                entry: dict[str, Any] = {
                    "a": a,
                    "b": b,
                    "label": label,
                    "family": family,
                    "metric": metric,
                    "accuracyCountsAbstentionAsIncorrect": metric in mt.ACCURACY_METRICS,
                    "strata": per,
                }
                if tag:
                    entry["referenceTag"] = tag
                out.append(entry)
    for s, q in zip(tests, st.benjamini_hochberg([t["p_value"] for t in tests])):
        s["q_value"] = q
    for entry in out:
        for s in entry["strata"].values():
            s["direction"] = direction_sentence(
                corpus, entry["a"], entry["b"], entry["label"], entry["metric"], s, tag
            )
    return out, len(tests)


def aggregate(
    rows: list[dict[str, Any]],
    manifest: dict[str, Any],
    digests: dict[str, Any],
    git: dict[str, Any],
    runner_meta: dict[str, Any],
) -> dict[str, Any]:
    corpora_out: dict[str, Any] = {}
    for corpus, doc in manifest["corpora"].items():
        strata = _strata(rows, corpus)
        strata = {k: strata[k] for k in sorted(strata, key=_stratum_sort_key)}
        tag = cp.CROWDSOURCED_TAG if corpus == "giantsteps" else None
        sources = doc["sources"]
        pairs, test_count = pairing_summaries(rows, corpus, strata, tag)
        corpora_out[corpus] = {
            "n": len(doc["rows"]),
            "referenceKind": doc["referenceKind"],
            "referenceTag": tag,
            "referenceSource": sources["reference"],
            "commercialAnalyzerSource": sources.get("commercialAnalyzer"),
            "handAnnotations": sources.get("annotations"),
            "annotatedTracks": sum(1 for r in doc["rows"] if r.get("annotation") is not None),
            "duplicateRecordingsDropped": sources.get("duplicateRecordingsDropped", 0),
            "strataN": {k: len(v) for k, v in strata.items()},
            "systems": system_summaries(rows, corpus, strata),
            "testCount": test_count,
            "pairings": pairs,
        }
    return {
        "schema": AGGREGATE_SCHEMA,
        "story": "15.9",
        "gitSha": git["sha"],
        "dirty": git["dirty"],
        "runnerBuildConfiguration": runner_meta.get("buildConfiguration"),
        "memorySampling": runner_meta.get("memorySampling"),
        "systems": {s: SYSTEM_DESCRIPTIONS[s] for s in SYSTEMS},
        "commercialAnalyzer": {"version": COMMERCIAL_VERSION, "mode": COMMERCIAL_MODE},
        "pairingRule": (
            "pairs (a, b) with a before b in the systems order; label system-vs-reference "
            "when b is oracle, otherwise system-vs-system; differences are a minus b over the "
            "tracks where both have a value"
        ),
        "tolerances": {
            "strictTempoBPM": list(mt.STRICT_TOLERANCES),
            "levelClassRelative": mt.LEVEL_TOLERANCE,
            "beatWindowSeconds": mt.BEAT_WINDOW_S,
        },
        "statistics": {
            "bootstrapResamples": st.BOOTSTRAP_RESAMPLES,
            "bootstrapSeed": st.BOOTSTRAP_SEED,
            "interval": (
                "percentile 2.5 and 97.5 of the resampled statistic of paired differences: "
                "the median for continuous metrics, the mean for yes/no metrics"
            ),
            "continuousP": "scipy.stats.wilcoxon, two-sided, zero differences dropped",
            "yesNoP": "exact McNemar from the discordant counts",
            "yesNoMetrics": sorted(mt.YES_NO_METRICS),
            "accuracyRule": (
                "accuracy rates and paired accuracy differences count an abstention or "
                "failure as incorrect; coverage is reported beside them"
            ),
            "multipleComparisons": "Benjamini-Hochberg q-values over all tests in a corpus",
            "directionRule": (
                f"paired n >= {st.UNDERPOWERED_BELOW}, interval excludes zero, "
                f"q < {st.DIRECTION_Q_BELOW}"
            ),
            "underpoweredBelow": st.UNDERPOWERED_BELOW,
        },
        "tempoBands": [b[0] for b in st.TEMPO_BANDS] + [st.OUTSIDE_BANDS],
        "styleTags": "OA300 and GiantSteps genre; 12.7 untagged; synthetic clicks by click shape",
        "limit": manifest.get("limit"),
        "digests": digests,
        "corpora": corpora_out,
    }


# ---------------------------------------------------------------------------
# Markdown
# ---------------------------------------------------------------------------


def _fmt(v: Any, digits: int = 4) -> str:
    if v is None:
        return "-"
    if isinstance(v, float):
        return f"{v:.{digits}g}"
    return str(v)


def _rate(metrics: dict[str, Any], name: str) -> str:
    m = metrics.get(name)
    return "-" if m is None else f"{m['mean']:.3f} (n {m['n']})"


def _median(metrics: dict[str, Any], name: str, scale: float = 1.0) -> str:
    m = metrics.get(name)
    return "-" if m is None else f"{m['median'] * scale:.4g}"


def render_markdown(agg: dict[str, Any]) -> str:
    sha = agg["gitSha"]
    lines: list[str] = [
        f"# Story 15.9 evaluation summary ({sha})",
        "",
        f"Git {sha}, tracked changes present: {'yes' if agg['dirty'] else 'no'}. Swift runner "
        f"build: {agg['runnerBuildConfiguration']}. Produced by `make matched-eval`; per-track "
        "rows stay in the gitignored run directory. This file holds aggregates only.",
        "",
        "## How to read this",
        "",
        "- Systems:",
    ]
    for s, desc in agg["systems"].items():
        lines.append(f"  - `{s}`: {desc}.")
    stats_ = agg["statistics"]
    tol = agg["tolerances"]
    lines += [
        "- A pairing whose right-hand system is `oracle` is labelled system-vs-reference; "
        "every other pairing, including the library against `commercial-analyzer`, is "
        "system-vs-system. Agreement with `commercial-analyzer` says nothing about "
        "correctness.",
        "- GiantSteps labels are crowdsourced; every GiantSteps pairing carries the tag "
        "crowdsourced-reference.",
        f"- Metric families stay separate. Strict tempo at {tol['strictTempoBPM']} BPM; "
        f"level classes within {tol['levelClassRelative']:.0%} of 1, 1/2, 2, 2/3 and 3/2; "
        f"beat window {tol['beatWindowSeconds'] * 1000:.0f} ms.",
        f"- Paired differences are a minus b. Interval: {stats_['interval']}, "
        f"{stats_['bootstrapResamples']} resamples, seed {stats_['bootstrapSeed']}. "
        f"p: {stats_['continuousP']} for continuous metrics; {stats_['yesNoP']} for yes/no "
        f"metrics ({', '.join(stats_['yesNoMetrics'])}). Every p carries a "
        f"{stats_['multipleComparisons']}; each corpus states its test count.",
        f"- {stats_['accuracyRule'][0].upper()}{stats_['accuracyRule'][1:]}.",
        f"- n is the paired count everywhere; n below {stats_['underpoweredBelow']} is "
        "underpowered and gets no direction. A direction is the sign of the paired "
        f"difference's interval, stated only when {stats_['directionRule']}, with its "
        "pairing, n, interval, p and q beside it.",
        "- Families 4 to 7 (grid phase, beat precision, recall and F, downbeat phase, "
        "drift) need a reference annotation: a Story 15.8 hand annotation, or the planted "
        "click times of the synthetic corpus. A track without one reports no-reference and "
        "is left out of those pairings. Downbeat phase and drift are scored only when the "
        "grid is at the reference's tempo level (level-mismatch otherwise); drift is the "
        "grid's phase error at the last annotated bar line minus its phase error at the "
        "first.",
        f"- Memory: {agg['memorySampling']}.",
        "",
    ]

    for corpus, c in agg["corpora"].items():
        tag = c["referenceTag"]
        lines += [
            f"## {corpus}",
            "",
            f"n = {c['n']}; reference: {c['referenceKind']} (`{c['referenceSource']['name']}`, "
            f"sha256 {c['referenceSource']['sha256'][:16]}...)"
            + (f"; tag {tag}" if tag else "")
            + f"; tracks with a reference annotation: {c['annotatedTracks']}; tests run: "
            + f"{c['testCount']}.",
            "",
        ]
        if c.get("duplicateRecordingsDropped"):
            lines += [
                f"Recordings listed twice under two formats counted once: "
                f"{c['duplicateRecordingsDropped']} dropped.",
                "",
            ]
        lines += [
            "### Per-system results, all tracks",
            "",
            "Accuracy rates count an abstention or failure as incorrect; coverage is the "
            "share of tracks the system answered.",
            "",
            "| system | outcomes | coverage | level same | strict 0.10 | strict 0.05 | "
            "strict 0.02 | median abs error BPM | median abs error ppt | median abs phase "
            "error s | median F | median runtime s | median peak memory MB | grid families |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
        ]
        for system, per in c["systems"].items():
            o = per["overall"]
            m = o["metrics"]
            outcomes = ", ".join(f"{k} {v}" for k, v in sorted(o["outcomes"].items()))
            grid = ", ".join(f"{k} {v}" for k, v in sorted(o["familyStatus"]["grid_phase"].items()))
            coverage = "-" if o["coverage"] is None else f"{o['coverage']:.3f}"
            lines.append(
                f"| `{system}` | {outcomes} | {coverage} | {_rate(m, 'level_same')} | "
                f"{_rate(m, 'strict_0.10')} | {_rate(m, 'strict_0.05')} | "
                f"{_rate(m, 'strict_0.02')} | {_median(m, 'abs_error_bpm')} | "
                f"{_median(m, 'abs_error_ppt')} | {_median(m, 'abs_phase_error_s')} | "
                f"{_median(m, 'f_measure')} | {_median(m, 'runtime_s')} | "
                f"{_median(m, 'peak_memory_bytes', 1 / 2**20)} | {grid} |"
            )
        lines.append("")

        # Strata: per-system rates with n and the underpowered mark.
        for kind, title in (("band:", "tempo band"), ("style:", "style tag")):
            lines += [
                f"### By {title}",
                "",
                "Accuracy rates count an abstention or failure as incorrect; n is the "
                "system's count of tracks with a value, and underpowered is judged on it.",
                "",
                "| stratum | tracks | system | n | underpowered | level same | strict 0.05 | "
                "median abs error BPM |",
                "|---|---|---|---|---|---|---|---|",
            ]
            for stratum, count in c["strataN"].items():
                if not stratum.startswith(kind):
                    continue
                for system, per in c["systems"].items():
                    if system == ORACLE:
                        continue
                    m = per[stratum]["metrics"]
                    if not m.get("level_same"):
                        continue
                    n = m["level_same"]["n"]
                    under = "yes" if n < stats_["underpoweredBelow"] else "no"
                    lines.append(
                        f"| {stratum.split(':', 1)[1]} | {count} | `{system}` | {n} | {under} | "
                        f"{_rate(m, 'level_same')} | {_rate(m, 'strict_0.05')} | "
                        f"{_median(m, 'abs_error_bpm')} |"
                    )
            lines.append("")

        lines += ["### Paired differences, all tracks", ""]
        by_pair: dict[tuple[str, str], list[dict[str, Any]]] = {}
        for p in c["pairings"]:
            by_pair.setdefault((p["a"], p["b"]), []).append(p)
        directions: list[str] = []
        for (a, b), entries in by_pair.items():
            label = entries[0]["label"]
            lines += [
                f"#### `{a}` vs `{b}` ({label}" + (f", {tag}" if tag else "") + ")",
                "",
                "| metric | n | statistic | estimate | 95 % interval | p | q | interval "
                "excludes 0 |",
                "|---|---|---|---|---|---|---|---|",
            ]
            for p in entries:
                s = p["strata"].get("overall")
                if s is None:
                    continue
                lo, hi = s["interval95"]
                lines.append(
                    f"| {p['metric']} | {s['n']} | {s['statistic']} | {_fmt(s['estimate'])} | "
                    f"[{_fmt(lo)}, {_fmt(hi)}] | {s['p_value']:.3g} | {s['q_value']:.3g} | "
                    f"{'yes' if s['interval_excludes_zero'] else 'no'} |"
                )
                if s.get("direction"):
                    directions.append(s["direction"])
            lines.append("")
        lines += ["### Directions stated (all tracks)", ""]
        if directions:
            lines += [f"- {d}" for d in directions]
        else:
            lines.append("None: no overall pairing satisfies the direction rule.")
        lines += [
            "",
            "Stratified pairings, each with n, interval, p, q and a direction only where the "
            "direction rule holds, are in the JSON aggregate.",
            "",
        ]

    lines += [
        "## Limitations",
        "",
        "- `commercial-analyzer` values exist for OA300 only, where the DAW-verified "
        "reference covers 22 tracks; most of its strata are underpowered.",
        "- Its version and analysis mode were not recorded with the values; its grid is "
        "not available, so its grid families are no-data.",
        "- `variant-fixed-time` runs in Python from a separate scoring run; its runtime "
        "and memory are not-comparable with the Swift rows. `variant-comb-best-phase` is "
        "the default analysis plus an observation; its runtime and memory are "
        "not-comparable too.",
        "- The synthetic-clicks corpus is twelve clean click clips at one tempo; it "
        "measures grid timing on planted clicks, not on music.",
        "- The 12.7 corpus carries no style tags.",
        "",
        "## Digests",
        "",
    ]
    for k, v in agg["digests"].items():
        lines.append(f"- {k}: {json.dumps(v, sort_keys=True)}")
    lines.append("")
    text = "\n".join(lines)
    check_wording(text)
    return text
