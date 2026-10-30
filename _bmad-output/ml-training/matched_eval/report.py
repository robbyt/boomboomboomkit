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
        "Story 15.7: DSP stub observations -> metrical level selection seeded with the "
        "default BPM -> joint tempo and phase fit, on the default pass's decode; a nil "
        "at any step abstains"
    ),
    "variant-comb-best-phase": (
        "Story 15.10 follow-up: the default grid re-anchored at the onset-comb best phase "
        "(internal BeatGridAnalyzer hook); BPM answer unchanged from the default"
    ),
    "variant-fixed-time": (
        "Story 15.5 fixed-time model, BPM read from its scores files; tempo families only; "
        "Python inference, so runtime and memory are not comparable with the Swift rows"
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

# Words the summary must never contain: they would read as a claim that one
# system is level with or ahead of another. Directions are stated only as the
# sign of a paired difference with its pairing, n, interval and p beside it.
FORBIDDEN_WORDS = re.compile(
    r"\b(meet|meets|meeting|met|match|matches|matched|matching|approach|approaches|"
    r"approached|approaching|exceed|exceeds|exceeded|exceeding|parity|on par|outperform\w*|"
    r"surpass\w*|beats? the)\b",
    re.IGNORECASE,
)
# Literal names of this harness's own files and targets, which contain one of the
# words above and are removed before the scan.
ALLOWED_LITERALS = ("matched-eval-runs", "matched-eval-run", "matched-eval", "matched_eval")


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
        raise WordingViolation(f"summary contains forbidden comparison words: {hits}")


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
    if fixed_time_dir is None:
        return None
    path = fixed_time_dir / f"scores-{corpus}.json"
    if not path.is_file():
        return None
    doc = json.loads(path.read_text())
    doc["_sha256"] = cp.sha256_file(path)
    doc["_by_id"] = {r["trackId"]: r for r in doc["rows"]}
    return doc


def fixed_time_record(scores: dict[str, Any] | None, row: dict[str, Any]) -> dict[str, Any]:
    base: dict[str, Any] = {"gridFamilies": mt.NO_DATA, "runtimeStatus": mt.NOT_COMPARABLE}
    if scores is None:
        return {**base, "status": mt.NOT_RUN, "reason": "15.5 scores file absent"}
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
        return {**base, "status": mt.FAILED, "reason": "audio differs from the 15.5 scoring run"}
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
            records[FIXED_TIME] = fixed_time_record(scores, r)
            records[COMMERCIAL] = commercial_record(corpus, r)
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
                        and record.get("runtimeSeconds") is not None
                    )
                    if system in SWIFT_SYSTEMS and not comparable:
                        record = {**record, "runtimeStatus": mt.NO_DATA}
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
    """The only form a direction takes: the sign of the median paired difference,
    with pairing, label, n, interval and p beside it. None when the stratum is
    underpowered or the interval does not exclude zero."""
    if s.get("n", 0) == 0 or s["underpowered"] or not s["interval_excludes_zero"]:
        return None
    sign = "above zero" if s["median"] > 0 else "below zero"
    lo, hi = s["interval95"]
    tag_text = f", {tag}" if tag else ""
    return (
        f"{corpus}, `{a}` vs `{b}` ({label}{tag_text}), {metric}: the median paired "
        f"difference ({a} minus {b}) is {sign}: {s['median']:.6g}, n = {s['n']}, "
        f"95 % interval [{lo:.6g}, {hi:.6g}], Wilcoxon p = {s['wilcoxon_p']:.3g}."
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
    """Per system and stratum: status counts, family status counts and metric
    summaries (n, mean, median) of the system's own values."""
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
            fam_status = {
                f: dict(Counter(t["families"][f]["status"] for t in sel)) for f in mt.FAMILIES
            }
            metrics: dict[str, Any] = {}
            for _family, metric, get in mt.METRICS:
                vals = [v for v in (get(t["families"]) for t in sel) if v is not None]
                if vals:
                    metrics[metric] = {
                        "n": len(vals),
                        "mean": float(np.mean(vals)),
                        "median": float(np.median(vals)),
                    }
            per[stratum] = {
                "n": len(sel),
                "underpowered": len(sel) < st.UNDERPOWERED_BELOW,
                "outcomes": dict(Counter(t["status"] for t in sel)),
                "metrics": metrics,
            }
            if stratum == "overall":
                per[stratum]["familyStatus"] = fam_status
        out[system] = per
    return out


def pairing_summaries(
    rows: list[dict[str, Any]], corpus: str, strata: dict[str, list[str]], tag: str | None
) -> list[dict[str, Any]]:
    values = metric_values(rows, corpus)
    out: list[dict[str, Any]] = []
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
                s = st.paired_summary(diffs, f"{corpus}|{a}|{b}|{metric}|{stratum}")
                s["direction"] = direction_sentence(corpus, a, b, label, metric, s, tag)
                per[stratum] = s
            if per:
                entry: dict[str, Any] = {
                    "a": a,
                    "b": b,
                    "label": label,
                    "family": family,
                    "metric": metric,
                    "strata": per,
                }
                if tag:
                    entry["referenceTag"] = tag
                out.append(entry)
    return out


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
            "pairings": pairing_summaries(rows, corpus, strata, tag),
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
            "interval": "percentile 2.5 and 97.5 of the resampled medians of paired differences",
            "wilcoxon": "scipy.stats.wilcoxon, two-sided, zero differences dropped",
            "underpoweredBelow": st.UNDERPOWERED_BELOW,
        },
        "tempoBands": [b[0] for b in st.TEMPO_BANDS] + [st.OUTSIDE_BANDS],
        "styleTags": "OA300 and GiantSteps genre; 12.7 untagged",
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
        f"p: {stats_['wilcoxon']}.",
        f"- A stratum with n below {stats_['underpoweredBelow']} is underpowered and gets no "
        "direction. A direction is the sign of the median paired difference, stated only "
        "when the interval excludes zero, with its pairing, n, interval and p beside it.",
        "- Families 4 to 7 (grid phase, beat precision, recall and F, downbeat phase, "
        "drift) need a Story 15.8 hand annotation; a track without one reports "
        "no-reference and is left out of those pairings.",
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
            + f"; hand-annotated tracks: {c['annotatedTracks']}.",
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
            "| system | outcomes | level same | strict 0.10 | strict 0.05 | strict 0.02 | "
            "median abs error BPM | median abs error ppt | median runtime s | "
            "median peak memory MB | grid families |",
            "|---|---|---|---|---|---|---|---|---|---|---|",
        ]
        for system, per in c["systems"].items():
            o = per["overall"]
            m = o["metrics"]
            outcomes = ", ".join(f"{k} {v}" for k, v in sorted(o["outcomes"].items()))
            grid = ", ".join(f"{k} {v}" for k, v in sorted(o["familyStatus"]["grid_phase"].items()))
            lines.append(
                f"| `{system}` | {outcomes} | {_rate(m, 'level_same')} | "
                f"{_rate(m, 'strict_0.10')} | {_rate(m, 'strict_0.05')} | "
                f"{_rate(m, 'strict_0.02')} | {_median(m, 'abs_error_bpm')} | "
                f"{_median(m, 'abs_error_ppt')} | {_median(m, 'runtime_s')} | "
                f"{_median(m, 'peak_memory_bytes', 1 / 2**20)} | {grid} |"
            )
        lines.append("")

        # Strata: per-system rates with n and the underpowered mark.
        for kind, title in (("band:", "tempo band"), ("style:", "style tag")):
            lines += [
                f"### By {title}",
                "",
                "Rates are the share of tracks with a value; each cell shows n.",
                "",
                "| stratum | n | underpowered | system | level same | strict 0.05 | "
                "median abs error BPM |",
                "|---|---|---|---|---|---|---|",
            ]
            for stratum, n in c["strataN"].items():
                if not stratum.startswith(kind):
                    continue
                under = "yes" if n < stats_["underpoweredBelow"] else "no"
                for system, per in c["systems"].items():
                    if system == ORACLE:
                        continue
                    m = per[stratum]["metrics"]
                    if not m.get("level_same"):
                        continue
                    lines.append(
                        f"| {stratum.split(':', 1)[1]} | {n} | {under} | `{system}` | "
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
                "| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |",
                "|---|---|---|---|---|---|",
            ]
            for p in entries:
                s = p["strata"].get("overall")
                if s is None:
                    continue
                lo, hi = s["interval95"]
                lines.append(
                    f"| {p['metric']} | {s['n']} | {_fmt(s['median'])} | "
                    f"[{_fmt(lo)}, {_fmt(hi)}] | {s['wilcoxon_p']:.3g} | "
                    f"{'yes' if s['interval_excludes_zero'] else 'no'} |"
                )
                if s.get("direction"):
                    directions.append(s["direction"])
            lines.append("")
        lines += ["### Directions stated (all tracks)", ""]
        if directions:
            lines += [f"- {d}" for d in directions]
        else:
            lines.append("None: no overall interval excludes zero.")
        lines += [
            "",
            "Stratified pairings, each with n, interval, p and a direction only where the "
            "stratum is not underpowered, are in the JSON aggregate.",
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
        "and memory are not comparable with the Swift rows.",
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
