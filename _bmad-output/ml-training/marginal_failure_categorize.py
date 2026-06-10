"""
Story 7.4 — shared Marginal-tier failure-categorization module (develop-only).

This is the SINGLE source of the Marginal-cohort categorization logic. Its
hyphenated CLI sibling is `scripts/marginal-failure-categorize.py` (one
separator apart — a hyphenated path is not importable, so the logic lives here
and the CLI imports it; mirror of the `audit-corpus-splits.py` ->
`corpus_common` precedent, DD #3 / DD #14). `corpus_diagnostics.py` imports this
module directly to build the use-(b) `marginalTierDisagreementGeometry` block.
Do NOT re-implement `categorize()` / `expected_failure_mode()` / banding
anywhere else — import them (the `corpus_common.tier_for` single-source rule).

Guardrail 2: every field here is a dataset-side LABEL diagnostic over the
labeler's pre-computed disagreement signals + cluster geometry. NO model
predictions are consulted (DD #2); this produces no transferable FR-18 metric.

FR-15 boundary (DD #12): the artifacts this module produces CONTAIN BPM signals
(diagnostic content) but are NEVER read by any feature-transform / training
path. FR-15 governs MODEL INPUTS; these are labeling/diagnostic artifacts.

Stdlib-only at import time. numpy is imported lazily inside the proximity
helper so the categorization CLI does not drag numpy into a metadata-only run.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import TYPE_CHECKING

import corpus_common as cc

if TYPE_CHECKING:
    import numpy as np

CATEGORIZATION_JSON = cc.ML_TRAINING_DIR / "marginal-failure-categorization.json"
WATCHLIST_JSON = cc.ML_TRAINING_DIR / "marginal-watchlist.json"

# ---------------------------------------------------------------------------
# Closed category set — DECLARED ORDER == precedence order (DD #2).
# Per-category dicts iterate this tuple (AC8 determinism pin).
# ---------------------------------------------------------------------------

CATEGORIES = (
    "dspFailure",
    "metadataConflict",
    "halfDoubleOctave",
    "harmonicAmbiguity",
    "unresolved",
)

# Closed verificationPredicate enum (DD #7) — the mechanical check Story 7.6
# runs against `v2Prediction`. `unresolved -> none` names the absence visibly.
VERIFICATION_PREDICATES = (
    "octave_family_error",
    "model_corrects_metadata",
    "model_corrects_dsp",
    "harmonic_ratio_error",
    "none",
)

# Total mapping category -> (human expectedFailureMode label, verificationPredicate).
_EXPECTED_FAILURE_MODE: dict[str, tuple[str, str]] = {
    "halfDoubleOctave": ("off-by-octave", "octave_family_error"),
    "metadataConflict": ("DSP-wins-over-stale-tag", "model_corrects_metadata"),
    "dspFailure": ("DSP-outlier-vs-consensus", "model_corrects_dsp"),
    "harmonicAmbiguity": ("harmonic-ratio-confusion", "harmonic_ratio_error"),
    "unresolved": ("no-a-priori-expectation", "none"),
}


def expected_failure_mode(category: str) -> tuple[str, str]:
    """Return (expectedFailureMode label, verificationPredicate) for a category.

    Total over CATEGORIES; raises KeyError on an out-of-set category (a closed
    enum violation should fail loud, not silently produce a null).
    """
    return _EXPECTED_FAILURE_MODE[category]


# ---------------------------------------------------------------------------
# Marginal-cohort selection + categorization
# ---------------------------------------------------------------------------


def select_marginal(tracks: list[dict]) -> list[dict]:
    """The Marginal-tier cohort, re-derived via `corpus_common.tier_for`
    (NOT a hard-coded list). Sorted by string `track_id` (AC8 determinism).
    """
    marg = [
        t
        for t in tracks
        if cc.tier_for(t.get("truth_confidence"), t.get("bpm_truth")) == "Marginal"
    ]
    return sorted(marg, key=lambda t: str(t.get("track_id")))


def _relation(track: dict, signal: str) -> str | None:
    return track.get("signals", {}).get(signal, {}).get("relation")


def _centroid(cluster: dict | None) -> float | None:
    if not cluster:
        return None
    c = cluster.get("centroid")
    return float(c) if c is not None and cc._is_finite(c) else None


# ---------------------------------------------------------------------------
# Shared cluster-ratio predicates — the SINGLE definition of the octave /
# harmonic geometry tests (DD #2 / DD #3). `categorize`, `harmonic_candidate_count`,
# AND `corpus_diagnostics.marginal_tier_disagreement_geometry` all call these — do
# NOT re-implement the ratio windows anywhere else. All consume `_centroid`, so a
# non-finite / non-numeric centroid yields ratio 0.0 (no ratio), never a crash/NaN.
# ---------------------------------------------------------------------------


def cluster_ratio(track: dict) -> float:
    """The canonical (direction-symmetric, zero-guarded) truth/runner-up centroid
    ratio for a track. 0.0 when either centroid is absent/non-finite (DD #2 — the
    `runner_up_cluster`-null fallthrough).
    """
    truth_c = _centroid(track.get("truth_cluster"))
    runner_c = _centroid(track.get("runner_up_cluster"))
    return cc.canonical_ratio(truth_c, runner_c) if (truth_c and runner_c) else 0.0


def is_octave_ratio(ratio: float) -> bool:
    """A 2:1 / 1:2 (octave) cluster ratio within OCTAVE_RATIO_TOL of 2.0."""
    return ratio > 0 and abs(ratio - 2.0) <= cc.OCTAVE_RATIO_TOL * 2.0


def is_harmonic_ratio(ratio: float) -> bool:
    """A 3:2 or 3:1 (non-octave harmonic) cluster ratio within HARMONIC_RATIO_TOL."""
    return ratio > 0 and (
        abs(ratio - 1.5) <= cc.HARMONIC_RATIO_TOL * 1.5
        or abs(ratio - 3.0) <= cc.HARMONIC_RATIO_TOL * 3.0
    )


def categorize(track: dict) -> str:
    """Deterministic, precedence-ordered failureCategory (DD #2).

    Octave/harmonic structure comes from the truth_cluster / runner_up_cluster
    CENTROID RATIO (the `relation` enum has no `double` value), so the 0.5x
    direction needs no special branch (`canonical_ratio` is direction-symmetric).
    If `runner_up_cluster` is null/absent the ratio is 0.0 and both is_octave /
    is_harmonic are False -> the track falls through to the relation-only rules.

    Precedence (first match wins):
      1. dspFailure       — dsp 'far' while BOTH metadata sources 'same'
                            (the lone audio outlier; tested FIRST so the broad
                            octave sweep does not swallow it — rule-1 over-reach
                            guard, Mary/Codex).
      2. metadataConflict — rekordbox/grid non-octave disagreement while dsp
                            'same' (audio+DSP support truth against a stale tag).
      3. halfDoubleOctave — 2x cluster ratio AND a metadata/DSP 'half' relation.
      4. harmonicAmbiguity— 3:2 or 3:1 cluster ratio (measured, may be 0 — AC9).
      5. unresolved       — none of the above.
    """
    dsp = _relation(track, "dsp")
    rk = _relation(track, "rekordbox_average")
    grid = _relation(track, "grid_bpm")

    ratio = cluster_ratio(track)
    is_octave = is_octave_ratio(ratio)
    is_harmonic = is_harmonic_ratio(ratio)

    # 1. DSP outlier vs metadata consensus (over-reach guard: BEFORE the octave sweep).
    if dsp == "far" and rk == "same" and grid == "same":
        return "dspFailure"
    # 2. Non-octave metadata disagreement while DSP supports truth. The `not is_octave`
    #    guard is load-bearing (code-review 7-4, Codex thread 019e8f9f): an octave-geometry
    #    track with a 'half' relation belongs to rule 3, not here — first-match-wins would
    #    otherwise route it to metadataConflict despite the "non-octave" intent.
    if not is_octave and (rk in ("far", "near") or grid in ("far", "near")) and dsp == "same":
        return "metadataConflict"
    # 3. Half/double octave (dominant).
    if is_octave and "half" in (dsp, rk, grid):
        return "halfDoubleOctave"
    # 4. Non-2x harmonic ratio (3:2 / 3:1).
    if is_harmonic:
        return "harmonicAmbiguity"
    # 5. Fallthrough.
    return "unresolved"


def _round6(x) -> float | None:
    """round(float(x), 6) or None — never a raw np.float32 (AC8 determinism)."""
    if x is None or not cc._is_finite(x):
        return None
    return round(float(x), 6)


def _signal_bpm(track: dict, signal: str) -> float | None:
    return _round6(track.get("signals", {}).get(signal, {}).get("bpm"))


def categorization_records(tracks: list[dict]) -> list[dict]:
    """One record per Marginal track (use-a schema, AC1). Sorted by track_id.

    `idTagBPM` / `durationDerivedBPM` are structurally null (DD #1): the labeler
    never wired an ID3/`tmpo` BPM key (`tony-tunes-labels.py:64` "not yet
    wired"; ID3 BPM is also an FR-15-forbidden model input), and no
    duration-derived BPM signal exists in any planned story.
    """
    records: list[dict] = []
    for t in select_marginal(tracks):
        records.append(
            {
                "track_id": str(t.get("track_id")),
                "tonyLabel": _round6(t.get("bpm_truth")),
                "dspBPM": _signal_bpm(t, "dsp"),
                "rekordboxBPM": _signal_bpm(t, "rekordbox_average"),
                "gridBPM": _signal_bpm(t, "grid_bpm"),
                "idTagBPM": None,
                "durationDerivedBPM": None,
                "dspRelation": _relation(t, "dsp"),
                "rekordboxRelation": _relation(t, "rekordbox_average"),
                "gridRelation": _relation(t, "grid_bpm"),
                "playlistRelation": _relation(t, "playlist"),
                "failureCategory": categorize(t),
            }
        )
    return records


def category_counts(records: list[dict]) -> dict[str, int]:
    """Per-category counts iterating CATEGORIES in declared order (AC8)."""
    counts = {c: 0 for c in CATEGORIES}
    for r in records:
        counts[r["failureCategory"]] += 1
    return counts


def harmonic_candidate_count(tracks: list[dict]) -> int:
    """The 3:2 / 3:1 cluster-ratio candidate count over the Marginal cohort,
    measured independently of precedence (AC9 — `harmonicAmbiguity` must be
    measured before ship; ships as an explicit zero-count if 0).
    """
    n = 0
    for t in select_marginal(tracks):
        if is_harmonic_ratio(cluster_ratio(t)):
            n += 1
    return n


# ---------------------------------------------------------------------------
# Use-(a) + use-(c) artifact payloads (DD #13 typed v2Prediction seam).
#
# Built as pure functions so the AC8 byte-identity test can write each payload
# to two temp paths and compare bytes without touching the real output files.
# Dicts are built in a FIXED insertion order each run (no sort_keys), so the
# serialized bytes are deterministic AND the declared-order pins hold (AC8).
# ---------------------------------------------------------------------------

# The locked watchlist row schema (AC7) — exact key set, pytest-asserted (AC8).
WATCHLIST_ROW_KEYS = frozenset(
    {
        "track_id",
        "failureCategory",
        "expectedFailureMode",
        "verificationPredicate",
        "tonyLabel",
        "dspBPM",
        "rekordboxBPM",
        "gridBPM",
        "v2Prediction",
    }
)


def _v2_prediction_stub() -> dict:
    """The reserved typed `v2Prediction` shape (DD #13). Declared now, value
    null at 7.4 close: Story 7.5 fills `seeds[]` + variance/agreement, Story 7.6
    fills `matchesExpected`. This is the ONLY permitted empty stub.
    """
    return {
        "status": "pending-7.5",
        "seeds": [],
        "varianceBpm": None,
        "octaveNormalizedAgreement": None,
        "matchesExpected": None,
    }


def _watchlist_row(rec: dict) -> dict:
    label, predicate = expected_failure_mode(rec["failureCategory"])
    return {
        "track_id": rec["track_id"],
        "failureCategory": rec["failureCategory"],
        "expectedFailureMode": label,
        "verificationPredicate": predicate,
        "tonyLabel": rec["tonyLabel"],
        "dspBPM": rec["dspBPM"],
        "rekordboxBPM": rec["rekordboxBPM"],
        "gridBPM": rec["gridBPM"],
        "v2Prediction": _v2_prediction_stub(),
    }


def build_categorization_payload(tracks: list[dict]) -> dict:
    """Use-(a) `marginal-failure-categorization.json` payload (AC1)."""
    records = categorization_records(tracks)
    return {
        "_schemaNote": {
            "story": "7.4",
            "marginalBand": "[0.55, 0.65) on truth_confidence, via corpus_common.tier_for",
            "idTagBPM": "null — producer exists (ID3 TBPM/tmpo via mutagen) but UNWIRED "
            "(tony-tunes-labels.py:64 'not yet wired'); ID3 BPM is also an FR-15-forbidden "
            "model input. Tracked as deferred-work 7-4-D1.",
            "durationDerivedBPM": "null — no producer in any planned story (the survey "
            "carries total_time but no derived-BPM signal).",
            "relations": "dsp/rekordbox/grid/playlist relation-to-truth in "
            "{same, half, far, near, missing} (no 'double'); octave/harmonic come from "
            "the truth_cluster/runner_up_cluster centroid ratio.",
            "guardrail2": "dataset-side LABEL diagnostic; no model predictions consulted; "
            "no transferable FR-18 metric.",
        },
        "marginalTierCount": len(records),
        "records": records,
    }


def build_watchlist_payload(tracks: list[dict]) -> dict:
    """Use-(c) `marginal-watchlist.json` payload (AC4 / AC7 / DD #13)."""
    records = categorization_records(tracks)
    rows = [_watchlist_row(r) for r in records]
    return {
        "_consumedBy": ["7.5", "7.6"],
        "_schemaNote": {
            "story": "7.4 owns the schema + seed-INDEPENDENT fields "
            "(failureCategory, expectedFailureMode, verificationPredicate).",
            "v2Prediction": "reserved typed stub (DD #13): 7.5 fills seeds[] + "
            "varianceBpm/octaveNormalizedAgreement; 7.6 fills matchesExpected by grading "
            "the v2 prediction against verificationPredicate.",
            "rowSchema": "{track_id, failureCategory, expectedFailureMode, "
            "verificationPredicate, tonyLabel, dspBPM, rekordboxBPM, gridBPM, v2Prediction}",
            "fr15": "diagnostic artifact — never read by any feature-transform/training "
            "path (AC10).",
        },
        "marginalTierCount": len(rows),
        "watchlist": rows,
    }


def write_json_artifact(payload: dict, path: Path) -> None:
    """Deterministic write: indent=2, fixed insertion order, trailing newline.
    Byte-identical across runs for the same input (AC8 byte-identity).
    """
    path.write_text(json.dumps(payload, indent=2) + "\n")


# ---------------------------------------------------------------------------
# Use-(b) proximity math — nearest Strong-tier neighbor in fingerprint space.
#
# PURE + corpus-free: the caller supplies raw fingerprint vectors (the
# coverage-gating + fingerprint-cache load lives in corpus_diagnostics, DD #5).
# Per-dimension standardized across the supplied union, cosine distance,
# exhaustive argmin, ties broken by Strong track_id ascending (AC8).
# ---------------------------------------------------------------------------


def nearest_strong_distances(
    marginal_vecs: "dict[str, np.ndarray]",
    strong_vecs: "dict[str, np.ndarray]",
) -> "dict[str, tuple[str, float]]":
    """For each Marginal id, the (nearest Strong id, cosine distance).

    Vectors are standardized per-dimension across the union (mirrors the audit's
    fingerprint pass) before cosine; ties in the argmin break to the lowest
    Strong track_id. Returns {} if either side is empty. No RNG (exhaustive).
    """
    import numpy as np

    if not marginal_vecs or not strong_vecs:
        return {}

    strong_ids = sorted(strong_vecs)  # ascending -> argmin tie-break is lowest id
    marg_ids = sorted(marginal_vecs)
    union = np.stack(
        [np.asarray(marginal_vecs[m], dtype=np.float64) for m in marg_ids]
        + [np.asarray(strong_vecs[s], dtype=np.float64) for s in strong_ids]
    )
    mean = union.mean(axis=0)
    std = union.std(axis=0)
    std[std == 0.0] = 1.0  # zero-variance dim -> no contribution, no divide-by-zero
    union = (union - mean) / std

    n_marg = len(marg_ids)
    marg_std = union[:n_marg]
    strong_std = union[n_marg:]

    def _unit(rows: "np.ndarray") -> "np.ndarray":
        norms = np.linalg.norm(rows, axis=1, keepdims=True)
        norms[norms == 0.0] = 1.0
        return rows / norms

    marg_u = _unit(marg_std)
    strong_u = _unit(strong_std)
    # cosine distance matrix (n_marg, n_strong); argmin per row.
    dist = 1.0 - marg_u @ strong_u.T
    out: dict[str, tuple[str, float]] = {}
    for i, mid in enumerate(marg_ids):
        j = int(np.argmin(dist[i]))  # first minimum -> lowest Strong id on ties
        out[mid] = (strong_ids[j], round(float(dist[i][j]), 6))
    return out
