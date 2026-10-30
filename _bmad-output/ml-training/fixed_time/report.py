"""Paired fixed-time report against the legacy model and tempo-CNN (Story 15.5).

Joins three arms per track and refuses to write anything unless the join is
exact:

  - variant: `scores-<corpus>.json` from `fixed_time.score`
  - legacy: the runtime dumps from `giantsteps_v2_seed_42.mlmodelc`
      GiantSteps: fr18-predictions-191/seed_42/predictions.json, `fr18ModelBPM`
      12.7:       eval-corpus/bundle-gate/predictions/seed_42/predictions.json,
                  `modelBPM`, the 172 `locked-12.7-member` rows
      OA300:      the `corpus == "oa300"` rows of the GiantSteps dump,
                  `fr18ModelBPM`; they carry only the title as id, so each is
                  paired to the variant rows sharing its (title, label) key
                  (`pair_legacy_oa300`)
  - tempo-CNN: tempocnn-baseline/predictions.json (`modelBPM`), carried forward
      verbatim, GiantSteps only; 12.7 and OA300 rows report `not-run`

Every arm must hold each track id exactly once (661, 172 and 82) with equal
ground-truth labels, and strict Acc1 (4 %) must still come out at the recorded
counts: legacy 348/661, 124/172 and 43/82, tempo-CNN 545/661. Otherwise the
run exits nonzero naming the problem and writes nothing.

Writes `fixed-time-report.json`, `fixed-time-report.md` and `manifest.json`
next to the variant scores.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import fixed_time  # noqa: F401  (sys.path setup for the sibling training modules)
from evaluate_fr18 import acc1_correct, octave_match
from fixed_time import features as ft

ML_TRAINING_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = ML_TRAINING_DIR.parent.parent
DEFAULT_RUN_DIR = ML_TRAINING_DIR / "fixed-time-runs" / "seed_42"
LEGACY_GIANTSTEPS_RELPATH = Path("fr18-predictions-191/seed_42/predictions.json")
LEGACY_12_7_RELPATH = Path("eval-corpus/bundle-gate/predictions/seed_42/predictions.json")
BUNDLE_GATE_INPUT_RELPATH = Path(
    "eval-corpus/bundle-gate/predictions/bundle-gate-input-seed-42.json"
)
TEMPOCNN_PREDICTIONS = ML_TRAINING_DIR / "tempocnn-baseline" / "predictions.json"
LOCKED_CATEGORY = "locked-12.7-member"

RUN_KIND = "infrastructure-smoke"
CORPORA = ("giantsteps", "eval-12-7", "oa300")
EXPECTED_COUNTS = {"giantsteps": 661, "eval-12-7": 172, "oa300": 82}
ARMS = ("variant", "legacy", "tempoCnn")
# Recorded strict Acc1 (4 %) counts the join must reproduce before any delta is written.
EXPECTED_ACC1 = {
    ("giantsteps", "legacy"): 348,
    ("eval-12-7", "legacy"): 124,
    ("oa300", "legacy"): 43,
    ("giantsteps", "tempoCnn"): 545,
}
NOT_RUN = "not-run"

BANDS = ("<100", "100-140", ">140")
CATEGORIES = (
    "within-4pct",
    "octave-halving",
    "octave-doubling",
    "non-octave-over-4pct",
    "abstained",
)
OCTAVE_TOL = 0.04


class ReportRefusal(RuntimeError):
    """The arms do not pair exactly; no report is written."""


# ---------------------------------------------------------------------------
# Pure scoring
# ---------------------------------------------------------------------------


def tempo_band(truth: float) -> str:
    """DJ tempo band by ground truth: <100, 100 to 140 (inclusive), >140."""
    if truth < 100.0:
        return "<100"
    if truth <= 140.0:
        return "100-140"
    return ">140"


def _usable(pred: float | None) -> bool:
    return pred is not None and math.isfinite(pred) and pred > 0


def error_category(pred: float | None, truth: float) -> str:
    """One of CATEGORIES. A hit is `within-4pct`; every miss is halving,
    doubling, non-octave over 4 % (triplet errors land here), or abstained."""
    if not _usable(pred):
        return "abstained"
    assert pred is not None
    if acc1_correct(pred, truth):
        return "within-4pct"
    if abs(2.0 * pred - truth) / truth <= OCTAVE_TOL:
        return "octave-halving"
    if abs(pred / 2.0 - truth) / truth <= OCTAVE_TOL:
        return "octave-doubling"
    return "non-octave-over-4pct"


def arm_result(pred: float | None, truth: float) -> dict[str, Any]:
    return {
        "bpm": pred,
        "acc1": acc1_correct(pred, truth),
        "acc2": octave_match(pred, truth),
        "category": error_category(pred, truth),
    }


# ---------------------------------------------------------------------------
# Join
# ---------------------------------------------------------------------------


def join_arms(
    corpus: str, arms: dict[str, list[tuple[str, float | None, float]]]
) -> list[dict[str, Any]]:
    """Exact, unique track-id join with equal labels across arms.

    `arms` maps arm name -> [(trackId, predicted BPM or None, groundTruthBPM)].
    Raises `ReportRefusal` listing every missing, duplicated or relabelled id.
    """
    problems: list[str] = []
    expected = EXPECTED_COUNTS[corpus]
    indexed: dict[str, dict[str, tuple[float | None, float]]] = {}
    for arm, rows in arms.items():
        ids = [r[0] for r in rows]
        counts = Counter(ids)
        dupes = sorted(i for i, c in counts.items() if c > 1)
        if dupes:
            problems.append(f"{corpus}/{arm}: duplicate ids {dupes}")
        if len(counts) != expected:
            problems.append(f"{corpus}/{arm}: {len(counts)} unique ids, expected {expected}")
        indexed[arm] = {r[0]: (r[1], r[2]) for r in rows}
    reference = next(iter(indexed))
    all_ids = set().union(*(set(v) for v in indexed.values()))
    for arm, by_id in indexed.items():
        missing = sorted(all_ids - set(by_id))
        if missing:
            problems.append(f"{corpus}/{arm}: missing ids {missing}")
    relabelled = sorted(
        tid
        for tid in all_ids
        if len({float(by_id[tid][1]) for by_id in indexed.values() if tid in by_id}) > 1
    )
    if relabelled:
        problems.append(f"{corpus}: ground-truth labels differ across arms for {relabelled}")
    if problems:
        raise ReportRefusal("; ".join(problems))
    joined = []
    for tid in sorted(all_ids):
        truth = float(indexed[reference][tid][1])
        joined.append(
            {
                "trackId": tid,
                "groundTruthBPM": truth,
                "band": tempo_band(truth),
                "arms": {arm: arm_result(by_id[tid][0], truth) for arm, by_id in indexed.items()},
            }
        )
    return joined


def check_expected_acc1(corpus: str, joined: list[dict[str, Any]]) -> dict[str, int]:
    """Strict Acc1 per arm; refuse unless every recorded count comes out the same."""
    counts = {arm: sum(1 for r in joined if r["arms"][arm]["acc1"]) for arm in joined[0]["arms"]}
    drift = [
        f"{corpus}/{arm} strict Acc1 recomputes to {counts[arm]}, expected {expected}"
        for (c, arm), expected in EXPECTED_ACC1.items()
        if c == corpus and counts.get(arm) != expected
    ]
    if drift:
        raise ReportRefusal("; ".join(drift))
    return counts


# ---------------------------------------------------------------------------
# Summaries
# ---------------------------------------------------------------------------


def paired(joined: list[dict[str, Any]], other: str) -> dict[str, int]:
    out = Counter()
    for r in joined:
        v = r["arms"]["variant"]["acc1"]
        o = r["arms"][other]["acc1"]
        out[
            "bothHit" if v and o else "variantOnly" if v else f"{other}Only" if o else "bothMiss"
        ] += 1
    return {k: out.get(k, 0) for k in ("bothHit", "variantOnly", f"{other}Only", "bothMiss")}


def mcnemar_exact_p(variant_only: int, other_only: int) -> float:
    """Exact two-sided McNemar p-value from the two discordant counts: the
    binomial test of min(b, c) out of b + c at p = 0.5, doubled and capped at 1.
    No discordant tracks gives 1.0."""
    n = variant_only + other_only
    if n == 0:
        return 1.0
    k = min(variant_only, other_only)
    tail = sum(math.comb(n, i) for i in range(k + 1)) / 2**n
    return min(1.0, 2.0 * tail)


def summarize(
    corpus: str,
    joined: list[dict[str, Any]],
    variant_rows_by_id: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    arms = list(joined[0]["arms"])
    n = len(joined)
    acc1 = {a: sum(1 for r in joined if r["arms"][a]["acc1"]) for a in arms}
    acc2 = {a: sum(1 for r in joined if r["arms"][a]["acc2"]) for a in arms}
    per_band: dict[str, Any] = {}
    for band in BANDS:
        rows = [r for r in joined if r["band"] == band]
        per_band[band] = {
            "tracks": len(rows),
            "acc1": {a: sum(1 for r in rows if r["arms"][a]["acc1"]) for a in arms},
        }
    categories = {
        a: {c: sum(1 for r in joined if r["arms"][a]["category"] == c) for c in CATEGORIES}
        for a in arms
    }
    band_by_category = {
        a: {
            band: {
                c: sum(1 for r in joined if r["band"] == band and r["arms"][a]["category"] == c)
                for c in CATEGORIES
                if c != "within-4pct"
            }
            for band in BANDS
        }
        for a in arms
    }
    others = [a for a in arms if a != "variant"]
    variant_rows = variant_rows_by_id or {}
    return {
        "corpus": corpus,
        "tracks": n,
        "acc1": acc1,
        "acc2": acc2,
        "deltaAcc1": {
            f"variantMinus{o[0].upper()}{o[1:]}": acc1["variant"] - acc1[o] for o in others
        },
        "paired": {o: paired(joined, o) for o in others},
        "mcnemarExactP": {
            o: mcnemar_exact_p(p["variantOnly"], p[f"{o}Only"])
            for o, p in ((o, paired(joined, o)) for o in others)
        },
        "perBand": per_band,
        "categories": categories,
        "missesByBandAndCategory": band_by_category,
        "tempoCnn": "carried forward verbatim" if "tempoCnn" in arms else NOT_RUN,
        "variantAbstained": dict(
            Counter(r["abstained"] for r in variant_rows.values() if r.get("abstained"))
        ),
        "variantOutsideRuntimeRange": sum(
            1 for r in variant_rows.values() if r.get("inRuntimeRange") is False
        ),
    }


LABELLED_SOURCE = "tony.train"
LABEL_FREE_SOURCES = ("secondarySupervised", "unsupervisedPool")
UNATTRIBUTED = "unattributed"
POOL_SOURCES = (LABELLED_SOURCE, *LABEL_FREE_SOURCES, UNATTRIBUTED)
# The manifests the legacy run pretrained on: before commit 1a697a5 removed the
# continuous DJ mixes (they reproduce the legacy corpus hash exactly).
LEGACY_MANIFEST_REF = "1a697a5~1"
EXPOSURE_MATCH_RULE = (
    "byte-identical audio files only (sha256 of the file): a re-encode, edit or other copy "
    "of the same recording is not matched, so these counts are a lower bound, not a "
    "complete overlap figure"
)


def exposure(hashes: dict[str, str], pools: dict[str, set[str]]) -> dict[str, Any]:
    """Tracks whose audio file hash is in one arm's pretraining pool.

    `tony.train` hits are labelled-training overlap (that audio was also seen with
    its label in fine-tuning) and are reported apart from the label-free manifest
    sources; `unattributed` holds pool files matched to neither."""
    union = set().union(*pools.values()) if pools else set()
    exposed = sorted(tid for tid, h in hashes.items() if h in union)

    def hits(source: str) -> int:
        pool = pools.get(source, set())
        return sum(1 for h in hashes.values() if h in pool)

    return {
        "tracks": len(hashes),
        "inPretrainingPool": len(exposed),
        "labelledTrainingOverlap": hits(LABELLED_SOURCE),
        "labelFreeBySource": {src: hits(src) for src in LABEL_FREE_SOURCES},
        UNATTRIBUTED: hits(UNATTRIBUTED),
        "matchRule": EXPOSURE_MATCH_RULE,
        "trackIds": exposed,
    }


# ---------------------------------------------------------------------------
# Inputs
# ---------------------------------------------------------------------------


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def repo_relative(path: Path) -> str:
    resolved = path.resolve()
    return str(resolved.relative_to(REPO_ROOT)) if resolved.is_relative_to(REPO_ROOT) else str(path)


def _require(path: Path, what: str) -> Path:
    if not path.is_file():
        raise ReportRefusal(f"{what} not found: {path}")
    return path


def _bpm(value: Any) -> float | None:
    return None if value is None else float(value)


def load_variant(run_dir: Path, corpus: str) -> tuple[dict, list]:
    doc = json.loads(_require(run_dir / f"scores-{corpus}.json", "variant scores").read_text())
    return doc, [
        (r["trackId"], _bpm(r["variantBPM"]), float(r["groundTruthBPM"])) for r in doc["rows"]
    ]


def load_legacy_giantsteps(path: Path) -> list:
    rows = json.loads(_require(path, "legacy GiantSteps predictions").read_text())
    return [
        (str(r["trackId"]), _bpm(r.get("fr18ModelBPM")), float(r["groundTruthBPM"]))
        for r in rows
        if r.get("corpus") == "giantsteps"
    ]


def load_legacy_12_7(path: Path) -> list:
    rows = json.loads(_require(path, "legacy 12.7 predictions").read_text())
    return [
        (str(r["trackId"]), _bpm(r.get("modelBPM")), float(r["groundTruthBPM"]))
        for r in rows
        if r.get("category") == LOCKED_CATEGORY
    ]


def load_legacy_oa300(path: Path) -> list[dict[str, Any]]:
    """The OA300 rows of the legacy GiantSteps dump: [{"title", "bpm", "truth"}].
    Their `trackId` is the ground-truth title, which is not unique."""
    rows = json.loads(_require(path, "legacy OA300 predictions").read_text())
    return [
        {
            "title": str(r["trackId"]),
            "bpm": _bpm(r.get("fr18ModelBPM")),
            "truth": float(r["groundTruthBPM"]),
        }
        for r in rows
        if r.get("corpus") == "oa300"
    ]


def pair_legacy_oa300(
    legacy: list[dict[str, Any]], variant_rows: list[dict[str, Any]]
) -> list[tuple[str, float | None, float]]:
    """Re-key the legacy OA300 rows to the variant's track ids.

    Rows pair by (title, ground-truth label). A key pairs only when the variant
    and legacy hold the same number of rows for it and, when that is more than
    one, every legacy row of the key predicts the same BPM; then each variant
    row of the key takes that prediction, so every legacy row is used exactly
    once. Raises `ReportRefusal` naming every key that breaks this."""
    legacy_by_key: dict[tuple[str, float], list[dict[str, Any]]] = {}
    for r in legacy:
        legacy_by_key.setdefault((r["title"], r["truth"]), []).append(r)
    variant_by_key: dict[tuple[str, float], list[dict[str, Any]]] = {}
    problems: list[str] = []
    for r in variant_rows:
        if not r.get("title"):
            problems.append(f"oa300 variant row {r['trackId']} has no title")
            continue
        variant_by_key.setdefault((str(r["title"]), float(r["groundTruthBPM"])), []).append(r)
    out: list[tuple[str, float | None, float]] = []
    for key in sorted(set(legacy_by_key) | set(variant_by_key)):
        leg = legacy_by_key.get(key, [])
        var = variant_by_key.get(key, [])
        if len(leg) != len(var):
            unused = len(leg) - len(var)
            problems.append(
                f"oa300 key {key}: {len(var)} variant rows, {len(leg)} legacy rows"
                + (
                    f" ({unused} legacy row{'s' if unused > 1 else ''} unused)"
                    if unused > 0
                    else ""
                )
            )
            continue
        predictions = {r["bpm"] for r in leg}
        if len(predictions) > 1:
            problems.append(
                f"oa300 key {key}: legacy rows predict different BPMs "
                f"{sorted(predictions, key=lambda b: (b is None, b or 0.0))}"
            )
            continue
        bpm = leg[0]["bpm"]
        out.extend((r["trackId"], bpm, key[1]) for r in var)
    if problems:
        raise ReportRefusal("; ".join(problems))
    return out


def load_tempocnn(path: Path) -> list:
    doc = json.loads(_require(path, "tempo-CNN predictions").read_text())
    return [
        (str(r["trackId"]), _bpm(r.get("modelBPM")), float(r["groundTruthBPM"]))
        for r in doc["tracks"]
    ]


def load_legacy_manifests() -> dict[str, dict[str, Any]]:
    """The two pretraining manifests as the legacy run read them (`git show
    1a697a5~1:<path>`): {source: {"path", "sha256", "rows"}}."""
    import subprocess

    import ablation_locator as loc

    out: dict[str, dict[str, Any]] = {}
    for manifest, key in (
        (loc.SECONDARY_MANIFEST, "secondarySupervised"),
        (loc.UNSUPERVISED_MANIFEST, "unsupervisedPool"),
    ):
        rel = repo_relative(manifest)
        try:
            data = subprocess.check_output(
                ["git", "show", f"{LEGACY_MANIFEST_REF}:{rel}"], cwd=str(REPO_ROOT)
            )
        except (OSError, subprocess.CalledProcessError) as e:
            raise ReportRefusal(
                f"cannot read the legacy manifest {LEGACY_MANIFEST_REF}:{rel}: {e}"
            ) from e
        out[key] = {
            "path": f"git:{LEGACY_MANIFEST_REF}:{rel}",
            "sha256": hashlib.sha256(data).hexdigest(),
            "rows": json.loads(data)[key],
        }
    return out


def pretraining_pool_hashes(
    cache: dict[str, str], legacy_manifests: dict[str, dict[str, Any]]
) -> dict[str, dict[str, set[str]]]:
    """File sha256s of each arm's masked-mel pretraining pool, split by source.

    The variant pool is what the training loader lists now
    (`build_pretrain_audio_paths`): a `tony.train` file counts as `tony.train`
    even when a manifest also lists it; any other file takes its manifest row's
    `audioHash`; a file matched to neither is hashed and counted `unattributed`.
    Hashed files are memoised in `cache` (path, size, mtime), which the caller
    writes only after the report succeeds. The legacy pool is the variant pool
    plus the rows found only in the legacy manifests (`legacy_manifests`).
    Returns {"variant": {source: hashes}, "legacy": {source: hashes}}."""
    import ablation_locator as loc

    root = loc.tony_audio_root()
    current_rels: dict[str, set[str]] = {}
    by_path: dict[Path, tuple[str, str]] = {}
    for manifest, key in (
        (loc.SECONDARY_MANIFEST, "secondarySupervised"),
        (loc.UNSUPERVISED_MANIFEST, "unsupervisedPool"),
    ):
        rows = json.loads(manifest.read_text())[key]
        current_rels[key] = {row["relPath"] for row in rows}
        for row in rows:
            by_path.setdefault((root / row["relPath"]).resolve(), (key, row["audioHash"]))
    train = {r.audio_path.resolve() for r in loc.build_labeled_records("train")}

    def file_hash(path: Path) -> str:
        st = path.stat()
        key = f"{path}|{st.st_size}|{st.st_mtime_ns}"
        if key not in cache:
            cache[key] = sha256_file(path)
        return cache[key]

    variant: dict[str, set[str]] = {src: set() for src in POOL_SOURCES}
    for path in loc.build_pretrain_audio_paths():
        resolved = path.resolve()
        if resolved in train:
            variant[LABELLED_SOURCE].add(file_hash(resolved))
        elif resolved in by_path:
            source, digest = by_path[resolved]
            variant[source].add(digest)
        else:
            variant[UNATTRIBUTED].add(file_hash(resolved))
    legacy = {src: set(hashes) for src, hashes in variant.items()}
    for source, doc in legacy_manifests.items():
        for row in doc["rows"]:
            if row["relPath"] not in current_rels.get(source, set()):
                legacy[source].add(row["audioHash"])
    return {"variant": variant, "legacy": legacy}


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

ARM_LABEL = {
    "variant": "fixed-time variant",
    "legacy": "legacy (512-column)",
    "tempoCnn": "tempo-CNN",
}
COVERAGE_NOTE = (
    "Crop choice and coverage differ by design: legacy rows come from the runtime's "
    "energy-transition analysis window (30, 60 or 90 s inside the first 120 s, resized to 512 "
    "columns), while the variant reads the whole file, scores every 12 s candidate crop with "
    "the DSP rhythm score and averages only the at most 4 most rhythmic. A delta therefore "
    "measures crop length and crop choice together, not crop length alone."
)


def arm_differences(training_md: dict[str, Any]) -> list[str]:
    """Everything besides the crop length that differs between the arms."""
    notes = [
        COVERAGE_NOTE,
        "Decode and engine differ: legacy rows come from AVFoundation decode plus BNNS "
        "inference on the compiled `.mlmodelc`; variant rows come from librosa soxr_hq "
        "decode plus PyTorch inference on `model.pt`.",
        "Training views differ: legacy fine-tuning saw one fixed view per song in every "
        "epoch (the same window and augmentation each epoch), while the variant's crop "
        "changes by epoch among the song's kept crops, per the crop plan. The variant's "
        "augmentation draws (stretch rate, gain, noise, pitch shift) keep the legacy "
        "per-song seeding, so a song gets the same draws in every epoch; only its crop "
        "changes.",
        "Pretraining input differs: the variant's masked-mel pretraining used the planned "
        "rhythm-ranked 12 s crops, one per song per epoch, where legacy pretraining used one "
        "fixed view per song, its whole 30/60/90 s window.",
        "Songs differ: training left out songs whose first 120 s gave no kept crop, "
        "because they were shorter than one crop or no crop scored above 0 (counts by list "
        f"and reason: {training_md.get('songsWithoutKeptCrop', {})}); legacy trained on "
        "every song.",
    ]
    pcm = training_md.get("pcmSource") or {}
    if pcm.get("kind") == "pcm-cache":
        notes.append(
            "PCM source differs between training and scoring: variant training read the "
            "float16 PCM cache capped at 120 s (as legacy training did), while scoring "
            "decodes float32 whole files."
        )
    elif pcm:
        notes.append(
            "PCM source: variant training decoded float32 (no PCM cache) and kept the first "
            "120 s, while legacy training read the float16 PCM cache capped at 120 s; scoring "
            "decodes float32 whole files."
        )
    drift = training_md.get("corpusDrift") or {}
    if drift and not drift.get("matches", True):
        rows = ", ".join(
            f"{k} {v['legacy']} vs {v['current']}"
            for k, v in drift.get("differingRows", {}).items()
        )
        notes.append(
            f"Pretraining corpus differs: legacy corpus hash {drift.get('legacyCorpusVersionHash')}, "
            f"variant {drift.get('currentCorpusVersionHash')} (manifest rows legacy vs variant: "
            f"{rows}). Commit 1a697a5 removed continuous DJ mixes from the manifests after "
            "the legacy run."
        )
    return notes


def _pct(k: int, n: int) -> str:
    return f"{k}/{n} ({100.0 * k / n:.1f} %)" if n else "0/0"


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Fixed-time ML input ablation report (Story 15.5)",
        "",
        f"Run kind: `{report['runKind']}`. This run proves the harness end to end. It is not a "
        "ranking input; Story 12.5 decides any ranking read.",
        "",
        f"Variant: `{report['variant']['modelIdentity']}`, weights sha256 "
        f"`{report['variant']['weightsSha256']}`, input `{report['variant']['inputContract']}`, "
        f"aggregator `{report['variant']['aggregator']}`.",
        "",
        "## How the arms differ besides crop length",
        "",
        *[f"- {note}" for note in report["armDifferences"]],
        "",
        "Acc1 is strict: within 4 % of the ground truth. Acc2 also accepts half or double "
        "within 4 %. Bands are by ground truth: <100, 100 to 140, >140 BPM.",
        "",
        "## Pretraining exposure",
        "",
        "The two arms pretrained on different pools. Each holds the `tony.train` audio, "
        "which fine-tuning also used with its labels, plus the label-free "
        "`secondarySupervised` and `unsupervisedPool` manifests. The variant read the "
        "current manifests; legacy read them as of commit 1a697a5~1, before the continuous "
        "DJ mixes were removed, so the legacy pool is the variant pool plus those rows. A "
        "track whose audio is in an arm's pool was seen by that arm in training, so that "
        "arm's result on it is not a measure of generalization to unseen audio. "
        "`tony.train` matches are labelled-training overlap and are counted apart from "
        "the label-free sources; `unattributed` counts pool files matched to neither. The "
        f"match is by {EXPOSURE_MATCH_RULE}.",
        "",
        "| corpus | arm | tracks in pool | tony.train (labelled) | secondarySupervised | "
        "unsupervisedPool | unattributed |",
        "|---|---|---|---|---|---|---|",
    ]
    for corpus in CORPORA:
        for arm in ("variant", "legacy"):
            e = report["exposure"][corpus][arm]
            free = e["labelFreeBySource"]
            lines.append(
                f"| {corpus} | {ARM_LABEL[arm]} | {e['inPretrainingPool']} of {e['tracks']} | "
                f"{e['labelledTrainingOverlap']} | {free['secondarySupervised']} | "
                f"{free['unsupervisedPool']} | {e[UNATTRIBUTED]} |"
            )
    for corpus in CORPORA:
        s = report["summaries"][corpus]
        arms = list(s["acc1"])
        n = s["tracks"]
        lines += ["", f"## {corpus} ({n} tracks)", "", "| arm | Acc1 | Acc2 |", "|---|---|---|"]
        for a in arms:
            lines.append(f"| {ARM_LABEL[a]} | {_pct(s['acc1'][a], n)} | {_pct(s['acc2'][a], n)} |")
        if "tempoCnn" not in arms:
            lines.append(f"| {ARM_LABEL['tempoCnn']} | {NOT_RUN} | {NOT_RUN} |")
        abstained = ", ".join(f"{k} {v}" for k, v in sorted(s["variantAbstained"].items()))
        lines += [
            "",
            f"Variant abstentions (counted as misses): {abstained or 'none'}. Variant BPMs "
            f"outside 60 to 200 (reported raw, as legacy rows are): "
            f"{s['variantOutsideRuntimeRange']}.",
        ]
        lines += ["", "Paired Acc1 deltas (variant minus the other arm):", ""]
        for key, delta in s["deltaAcc1"].items():
            lines.append(f"- {key}: {delta:+d} tracks")
        for other, p in s["paired"].items():
            lines.append(
                f"- against {ARM_LABEL[other]}: both hit {p['bothHit']}, variant only "
                f"{p['variantOnly']}, {ARM_LABEL[other]} only {p[f'{other}Only']}, "
                f"both miss {p['bothMiss']}; exact two-sided McNemar p = "
                f"{s['mcnemarExactP'][other]:.3g} (binomial on the {p['variantOnly']} + "
                f"{p[f'{other}Only']} discordant tracks, p = 0.5)"
            )
        lines += ["", "| band | tracks | " + " | ".join(ARM_LABEL[a] for a in arms) + " |"]
        lines.append("|---|---|" + "---|" * len(arms))
        for band in BANDS:
            b = s["perBand"][band]
            lines.append(
                f"| {band} | {b['tracks']} | " + " | ".join(str(b["acc1"][a]) for a in arms) + " |"
            )
        lines += ["", "| category | " + " | ".join(ARM_LABEL[a] for a in arms) + " |"]
        lines.append("|---|" + "---|" * len(arms))
        for c in CATEGORIES:
            lines.append(f"| {c} | " + " | ".join(str(s["categories"][a][c]) for a in arms) + " |")
        changed = [
            r
            for r in report["tracks"][corpus]
            if r["arms"]["variant"]["acc1"] != r["arms"]["legacy"]["acc1"]
        ]
        lines += [
            "",
            f"Tracks where the variant and legacy disagree on Acc1 ({len(changed)}):",
            "",
            "| track | truth | band | variant BPM | variant category | legacy BPM | legacy category |",
            "|---|---|---|---|---|---|---|",
        ]
        for r in changed:
            v, g = r["arms"]["variant"], r["arms"]["legacy"]
            lines.append(
                f"| {r['trackId']} | {r['groundTruthBPM']:g} | {r['band']} | {v['bpm']} | "
                f"{v['category']} | {g['bpm']} | {g['category']} |"
            )
        misses = [r for r in report["tracks"][corpus] if not r["arms"]["variant"]["acc1"]]
        lines += [
            "",
            "<details>",
            f"<summary>Every variant miss with band and category ({len(misses)})</summary>",
            "",
            "| track | truth | band | variant BPM | category |",
            "|---|---|---|---|---|",
        ]
        for r in misses:
            v = r["arms"]["variant"]
            lines.append(
                f"| {r['trackId']} | {r['groundTruthBPM']:g} | {r['band']} | {v['bpm']} | "
                f"{v['category']} |"
            )
        lines += ["", "</details>"]
    lines += [
        "",
        "## Inputs",
        "",
        "Every input file and its sha256 is recorded in `manifest.json`.",
        "",
    ]
    return "\n".join(lines)


def build_manifest(
    training_md: dict[str, Any],
    score_docs: dict[str, dict],
    inputs: dict[str, dict],
    *,
    code_git_sha: str = "unknown",
) -> dict[str, Any]:
    from fixed_time.score import AGGREGATOR_SYMBOL, LABEL_SOURCE_INPUT, resolve_aggregator

    train_spf = float(training_md["trainingSecondsPerFrame"])
    infer = {float(d["inferenceSecondsPerFrame"]) for d in score_docs.values()}
    if len(infer) != 1 or infer != {train_spf}:
        raise ReportRefusal(
            f"inference seconds per frame {sorted(infer)} differ from training {train_spf}"
        )
    weights = {d["weightsSha256"] for d in score_docs.values()}
    if weights != {training_md["weightsSha256"]}:
        raise ReportRefusal("scored weights differ from the trained weights")
    symbols = {d["aggregatorSymbol"] for d in score_docs.values()}
    if symbols != {AGGREGATOR_SYMBOL}:
        raise ReportRefusal(f"scores were aggregated by {sorted(symbols)}, not {AGGREGATOR_SYMBOL}")
    for corpus, doc in score_docs.items():
        # Only the corpus's own label source is checked; other entries an older
        # scores file may carry are ignored.
        name = LABEL_SOURCE_INPUT[corpus]
        sha = (doc.get("scoredInputs") or {}).get(name)
        if sha is None:
            raise ReportRefusal(f"scores-{corpus}.json does not record {name}")
        now = (inputs.get(name) or {}).get("sha256")
        if now != sha:
            raise ReportRefusal(
                f"{name} sha256 at report time ({now}) differs from the one scores-"
                f"{corpus}.json was scored against ({sha})"
            )
    rules = {json.dumps(d.get("rankingRule"), sort_keys=True) for d in score_docs.values()}
    if rules != {json.dumps(ft.ranking_rule(), sort_keys=True)}:
        raise ReportRefusal("scores were ranked under a different rule than this harness's")
    plan_md = training_md.get("cropPlan") or {}
    plan_input = inputs.get("cropPlan")
    if not plan_md.get("sha256") or plan_input is None:
        raise ReportRefusal("training metadata or run directory lacks the crop plan")
    if plan_input["sha256"] != plan_md["sha256"]:
        raise ReportRefusal(
            f"crop-plan.json sha256 {plan_input['sha256']} differs from the one training "
            f"recorded ({plan_md['sha256']})"
        )
    aggregator = resolve_aggregator(AGGREGATOR_SYMBOL)
    contract = ft.input_contract()
    return {
        "run_kind": RUN_KIND,
        "story": "15.5",
        **{k: v for k, v in contract.items() if k != "secondsPerFrame"},
        "tensorShape": list(ft.TENSOR_SHAPE),
        "modelIdentity": training_md["modelIdentity"],
        "weightsSha256": training_md["weightsSha256"],
        "trainingSecondsPerFrame": train_spf,
        "inferenceSecondsPerFrame": next(iter(infer)),
        "aggregator": {
            "name": aggregator.__name__,
            "symbol": AGGREGATOR_SYMBOL,
            "perCropProbabilities": {c: d["cropProbabilitiesFile"] for c, d in score_docs.items()},
        },
        "cropPlan": {
            "sha256": plan_md["sha256"],
            "keptSongs": plan_md.get("keptSongs"),
            "skippedSongs": plan_md.get("skippedSongs"),
        },
        "recipe": training_md["recipe"],
        "armDifferences": arm_differences(training_md),
        "corpusDrift": training_md.get("corpusDrift"),
        "codeGitSha": {
            "report": code_git_sha,
            "scores": {c: d.get("codeGitSha", "unknown") for c, d in score_docs.items()},
            "training": training_md.get("harnessGitSha", "unknown"),
        },
        "inputs": inputs,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def build_report(args: argparse.Namespace) -> tuple[dict, dict]:
    run_dir: Path = args.run_dir
    training_path = _require(run_dir / "metadata.json", "variant training metadata")
    training_md = json.loads(training_path.read_text())
    legacy_root: Path = args.legacy_root
    legacy_gs = args.legacy_giantsteps or legacy_root / LEGACY_GIANTSTEPS_RELPATH
    legacy_127 = args.legacy_12_7 or legacy_root / LEGACY_12_7_RELPATH
    # The legacy OA300 rows are in the same dump as the GiantSteps rows.
    legacy_oa300 = legacy_gs
    tempocnn = args.tempocnn
    bundle_input = _require(legacy_root / BUNDLE_GATE_INPUT_RELPATH, "bundle-gate input")

    score_docs: dict[str, dict] = {}
    variant_rows: dict[str, list] = {}
    for corpus in CORPORA:
        score_docs[corpus], variant_rows[corpus] = load_variant(run_dir, corpus)

    arms_by_corpus = {
        "giantsteps": {
            "variant": variant_rows["giantsteps"],
            "legacy": load_legacy_giantsteps(legacy_gs),
            "tempoCnn": load_tempocnn(tempocnn),
        },
        "eval-12-7": {
            "variant": variant_rows["eval-12-7"],
            "legacy": load_legacy_12_7(legacy_127),
        },
    }
    problems: list[str] = []
    try:
        arms_by_corpus["oa300"] = {
            "variant": variant_rows["oa300"],
            "legacy": pair_legacy_oa300(
                load_legacy_oa300(legacy_oa300), score_docs["oa300"]["rows"]
            ),
        }
    except ReportRefusal as e:
        problems.append(str(e))
    joined: dict[str, list] = {}
    expected_acc1: dict[str, dict] = {}
    for corpus, arms in arms_by_corpus.items():
        try:
            joined[corpus] = join_arms(corpus, arms)
            expected_acc1[corpus] = check_expected_acc1(corpus, joined[corpus])
        except ReportRefusal as e:
            problems.append(str(e))
    if problems:
        raise ReportRefusal(" | ".join(problems))

    inputs: dict[str, dict] = {}
    for name, path in (
        ("variantWeights", run_dir / "model.pt"),
        ("variantTrainingMetadata", training_path),
        ("cropPlan", run_dir / "crop-plan.json"),
        ("variantScoresGiantsteps", run_dir / "scores-giantsteps.json"),
        ("variantScoresEval127", run_dir / "scores-eval-12-7.json"),
        ("variantCropProbabilitiesGiantsteps", run_dir / "crops-giantsteps.npz"),
        ("variantCropProbabilitiesEval127", run_dir / "crops-eval-12-7.npz"),
        ("variantScoresOa300", run_dir / "scores-oa300.json"),
        ("variantCropProbabilitiesOa300", run_dir / "crops-oa300.npz"),
        ("legacyGiantstepsPredictions", legacy_gs),
        ("legacyEval127Predictions", legacy_127),
        ("legacyOa300Predictions", legacy_oa300),
        ("tempoCnnPredictions", tempocnn),
        ("bundleGateInput", bundle_input),
        ("giantstepsGroundTruth", Path(score_docs["giantsteps"]["labelSource"]["path"])),
    ):
        inputs[name] = {"path": str(path), "sha256": sha256_file(_require(path, name))}
    from fixed_time.score import oa300_ground_truth_path

    # The committed OA300 labels as they are now; build_manifest refuses if they
    # changed since scores-oa300.json was scored.
    oa300_truth = _require(oa300_ground_truth_path(), "oa300GroundTruth")
    inputs["oa300GroundTruth"] = {
        "path": repo_relative(oa300_truth),
        "sha256": sha256_file(oa300_truth),
    }
    legacy_md = training_md.get("recipeGuard", {})
    if legacy_md.get("legacyMetadataPath"):
        p = ML_TRAINING_DIR / legacy_md["legacyMetadataPath"]
        if p.is_file():
            inputs["legacyTrainingMetadata"] = {"path": str(p), "sha256": sha256_file(p)}
    import ablation_locator as loc
    import dataset as ds
    from fixed_time.score import code_git_sha

    fixture_path = _require(Path(ds.FIXTURE_PATH), "feature fixture")
    inputs["featureFixture"] = {
        "path": repo_relative(fixture_path),
        "sha256": sha256_file(fixture_path),
        "selfHash": score_docs["giantsteps"]["featureFixtureSha256"],
    }
    import corpus_common as cc

    # Files the exposure count reads: both pretraining manifests, the Tony split,
    # the Tony labels, and the mix-duration sidecar the manifest reader checks.
    for name, path in (
        (f"pretrainingManifest:{loc.SECONDARY_MANIFEST.name}", loc.SECONDARY_MANIFEST),
        (f"pretrainingManifest:{loc.UNSUPERVISED_MANIFEST.name}", loc.UNSUPERVISED_MANIFEST),
        ("corpusSplits", loc.CORPUS_SPLITS),
        ("tonyTruthLabels", cc.TONY_TRUTH_LABELS),
        ("poolDurations", loc.ML_TRAINING_DIR / "pool-durations.json"),
    ):
        inputs[name] = {
            "path": repo_relative(path),
            "sha256": sha256_file(_require(path, name)),
        }
    legacy_manifests = load_legacy_manifests()
    for source, doc in legacy_manifests.items():
        inputs[f"legacyPretrainingManifest:{source}"] = {
            "path": doc["path"],
            "sha256": doc["sha256"],
        }

    # Every refusal happens above or here, before anything is written.
    manifest = build_manifest(training_md, score_docs, inputs, code_git_sha=code_git_sha())

    pools = pretraining_pool_hashes(args.pool_hash_cache, legacy_manifests)
    exposures = {
        corpus: {
            arm: exposure(
                {r["trackId"]: r["audioSha256"] for r in score_docs[corpus]["rows"]},
                pools[arm],
            )
            for arm in ("variant", "legacy")
        }
        for corpus in CORPORA
    }
    report = {
        "story": "15.5",
        "runKind": RUN_KIND,
        "variant": {
            "modelIdentity": training_md["modelIdentity"],
            "weightsSha256": training_md["weightsSha256"],
            "inputContract": ft.INPUT_CONTRACT,
            "aggregator": score_docs["giantsteps"]["aggregator"],
        },
        "armDifferences": manifest["armDifferences"],
        "definitions": {
            "acc1": "strict: |pred - truth| / truth <= 0.04; abstain is a miss",
            "acc2": "pred, 2 x pred or pred / 2 within 4 % of truth (evaluate_fr18.octave_match)",
            "bands": "by ground truth: <100, 100 to 140 inclusive, >140",
            "categories": list(CATEGORIES),
        },
        "expectedAcc1": {
            f"{c}/{a}": {"recorded": v, "recomputed": expected_acc1[c][a]}
            for (c, a), v in EXPECTED_ACC1.items()
        },
        "exposure": exposures,
        "summaries": {
            c: summarize(c, joined[c], {r["trackId"]: r for r in score_docs[c]["rows"]})
            for c in CORPORA
        },
        "tracks": joined,
    }
    return report, manifest


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Paired fixed-time report (Story 15.5).")
    p.add_argument("--run-dir", type=Path, default=DEFAULT_RUN_DIR)
    p.add_argument(
        "--legacy-root",
        type=Path,
        default=ML_TRAINING_DIR,
        help="ml-training directory holding the gitignored legacy dumps (read-only)",
    )
    p.add_argument("--legacy-giantsteps", type=Path, default=None)
    p.add_argument("--legacy-12-7", type=Path, default=None)
    p.add_argument("--tempocnn", type=Path, default=TEMPOCNN_PREDICTIONS)
    args = p.parse_args(argv if argv is not None else sys.argv[1:])
    cache_path = args.run_dir / "pretraining-pool-hash-cache.json"
    args.pool_hash_cache = json.loads(cache_path.read_text()) if cache_path.is_file() else {}
    try:
        report, manifest = build_report(args)
    except ReportRefusal as e:
        print(f"ERROR: no report written. {e}", file=sys.stderr)
        return 3
    out = args.run_dir
    outputs = {
        "fixed-time-report.json": json.dumps(report, indent=2, sort_keys=True) + "\n",
        "fixed-time-report.md": render_markdown(report) + "\n",
        "manifest.json": json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        cache_path.name: json.dumps(args.pool_hash_cache, indent=0, sort_keys=True) + "\n",
    }
    for name, text in outputs.items():
        tmp = out / f"{name}.partial"
        tmp.write_text(text)
        tmp.replace(out / name)
    print(f"[report] wrote fixed-time-report.json, fixed-time-report.md, manifest.json to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
