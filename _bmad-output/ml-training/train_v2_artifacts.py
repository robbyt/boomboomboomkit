"""train_v2_artifacts.py — Story 7.5 Tasks 5/6/8.

Pure, stdlib-only producers for the develop-only v2-training downstream
contracts Story 7.6 consumes. Kept free of torch so they are ty-checkable +
fast-pytest-able independent of the (operator-gated, MPS) training loop:

  - ``build_seed_metadata``       (Task 5 / AC7)  — per-seed model_metadata.json
  - ``compute_split_version_hash``(Task 5 / DD #8) — canonical-json sha256 over
                                                     the Tony split
  - ``build_marginal_stability``  (Task 6 / AC11/AC13) — fills the Story-7.4
                                  marginal-watchlist v2Prediction stub PER TRACK
                                  across seeds (matchesExpected stays null -> 7.6)
  - ``feature_distribution_sanity``(Task 8 / AC13) — substrate-vs-librosa guard

DD #14: ``featureSetVersion`` is the FEATURE-contract axis; the multi-seed model
generation rides on ``modelGeneration`` + the giantsteps_v2_seed_* filename.
"""

from __future__ import annotations

import hashlib
import json
import math
from statistics import pvariance
from typing import Any

FEATURE_SET_VERSION = "v2"
TRAINING_VARIANT = "maskedMelPretrain"  # KDD-B2 winner (ablation/kdd-b2-comparison-v1.md)
# The winner is the default; the runner-up arm (FR-24 net-benefit comparison) is
# trained at v2 too and tags its metadata with this variant.
TRAINING_VARIANTS = ("maskedMelPretrain", "supervisedAugmented")
MODEL_GENERATION = "v2"
SEEDS = (42, 43, 44)
OCTAVE_AGREEMENT_TOL = 0.04  # 4% after octave normalization


# ---------------------------------------------------------------------------
# Task 5 — per-seed metadata + split version hash
# ---------------------------------------------------------------------------


def _canonical_sha256(payload: Any) -> str:
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def compute_split_version_hash(corpus_splits: dict[str, Any]) -> str:
    """sha256 over the Tony split's identity (train/val/leaveArtistOut ids +
    provenance) — same canonical-JSON approach as
    ``ablation_common.compute_corpus_version_hash`` (DD #8). Deterministic
    regardless of dict insertion order."""
    tony = corpus_splits.get("tony", {})
    lao = tony.get("leaveArtistOut", {}) or {}
    payload = {
        "train": sorted(str(x) for x in tony.get("train", [])),
        "val": sorted(str(x) for x in tony.get("val", [])),
        "leaveArtistOut": sorted(str(x) for x in lao.get("heldOutTrackIds", [])),
        "marginalTierExclusion": bool(tony.get("marginalTierExclusion", False)),
        "provenance": tony.get("_provenance", {}),
    }
    return _canonical_sha256(payload)


def build_seed_metadata(
    *,
    seed: int,
    epoch_count: int,
    weighting_profile: str,
    corpus_version_hash: str,
    split_version_hash: str,
    harness_git_sha: str = "unknown",
    variant: str = TRAINING_VARIANT,
) -> dict[str, Any]:
    """The per-seed model_metadata.json schema (AC7). ``promotable: true`` (the
    Story-7.3 ``false`` is flipped) + ``bundleEligibilityPendingFR18: true``
    (Story 7.6 owns the bundle decision). ``variant`` defaults to the KDD-B2
    winner; the FR-24 runner-up arm passes ``supervisedAugmented``."""
    if weighting_profile != "uniform":
        # Guardrail 3 / DD #6 — substrate OnsetFeaturesBuilder throws on
        # .subBandEmphasis, so uniform is the only valid declared profile.
        raise ValueError(
            f"weightingProfile must be 'uniform' for the v2 substrate run (got {weighting_profile!r})"
        )
    if seed not in SEEDS:
        raise ValueError(f"seed must be one of {SEEDS} (got {seed})")
    if variant not in TRAINING_VARIANTS:
        raise ValueError(f"variant must be one of {TRAINING_VARIANTS} (got {variant!r})")
    return {
        "metadataSchema": "train-v2",
        "architecture": "TempoCNN",
        "trainingVariant": variant,
        "weightingProfile": weighting_profile,
        "featureSetVersion": FEATURE_SET_VERSION,
        "modelGeneration": MODEL_GENERATION,
        "seed": seed,
        "epochCount": epoch_count,
        "corpusVersionHash": corpus_version_hash,
        "splitVersionHash": split_version_hash,
        "harnessGitSha": harness_git_sha,
        "promotable": True,
        "bundleEligibilityPendingFR18": True,
    }


# ---------------------------------------------------------------------------
# Task 6 — multi-seed marginal-watchlist stability (per track, per seed)
# ---------------------------------------------------------------------------


def _octave_fold(bpm: float, lo: float = 80.0, hi: float = 160.0) -> float:
    """Fold a BPM into the canonical octave ``[lo, hi)`` by doubling/halving."""
    # Guard non-finite FIRST: +inf would spin `while folded >= hi: folded /= 2`
    # forever (inf/2 == inf) — review BLOCKER B2 (a single blown-up model
    # prediction would HANG artifact generation). NaN/non-positive pass through.
    if not math.isfinite(bpm) or bpm <= 0:
        return bpm
    folded = float(bpm)
    while folded < lo:
        folded *= 2.0
    while folded >= hi:
        folded /= 2.0
    return folded


def octave_normalized_agreement(bpms: list[float], tol: float = OCTAVE_AGREEMENT_TOL) -> bool:
    """True iff all seeds' BPMs agree within ``tol`` after octave normalization.

    KDD-B3 trigger #5 "stable" means the seeds predict the SAME track's tempo
    (modulo octave), not merely a stable aggregate count (Mary)."""
    folded = [_octave_fold(b) for b in bpms if math.isfinite(b) and b > 0]
    if len(folded) < 2:
        return False
    ref = sorted(folded)[len(folded) // 2]  # median
    if ref <= 0:
        return False
    return all(abs(f - ref) / ref <= tol for f in folded)


def _finite_or_none(value: float) -> float | None:
    """Round a seed scalar to 4 dp, or ``None`` if non-finite. A blown-up model
    prediction (``inf``/``nan``) must never reach the emitted JSON: bare
    ``Infinity``/``NaN`` are NOT valid JSON and a strict ``json.loads`` (or a
    Swift ``JSONDecoder``) rejects the whole file, breaking Story 7.6's consumer
    (review pass 2 BLOCKER)."""
    v = float(value)
    return round(v, 4) if math.isfinite(v) else None


def build_marginal_stability(
    watchlist: dict[str, Any],
    per_seed_predictions: dict[str, dict[int, tuple[float, float]]],
) -> dict[str, Any]:
    """Fill the Story-7.4 marginal-watchlist ``v2Prediction`` stub PER TRACK
    across seeds (AC11/AC13). ``per_seed_predictions[track_id][seed] =
    (bpm, confidence)``. ``matchesExpected`` stays ``null`` — Story 7.6 grades
    it against ``verificationPredicate``. Output schema is the join contract."""
    rows = watchlist.get("watchlist", [])
    out_rows: list[dict[str, Any]] = []
    for row in rows:
        track_id = str(row["track_id"])
        # Restrict to the known seed universe so a stray seed (e.g. an operator
        # extra-run) can neither be serialized into `seeds[]` nor pollute the
        # variance/agreement stats nor inflate `status` to "filled-7.5" (the
        # sibling `build_seed_metadata` already rejects unknown seeds; this is
        # the batch-producer analogue — drop, don't crash a whole file).
        preds = {s: v for s, v in per_seed_predictions.get(track_id, {}).items() if s in SEEDS}
        seeds_payload = [
            {
                "seed": s,
                "bpm": _finite_or_none(preds[s][0]),
                "confidence": _finite_or_none(preds[s][1]),
            }
            for s in sorted(preds)
        ]
        # Variance + agreement over the finite POSITIVE-BPM seeds only. A
        # non-finite seed prediction is serialized as null (above) and excluded
        # here, so it can neither produce an invalid-JSON `Infinity` varianceBpm
        # nor silently inflate agreement to True while a seed is garbage. The
        # `> 0` filter matches `octave_normalized_agreement` (which folds only
        # `b > 0`): without it, a domain-invalid <=0 BPM would land in the
        # variance sample but be dropped by agreement, so the two stats would
        # disagree on which seeds count. agreement is None (not False) when fewer
        # than 2 such seeds survive, so Story 7.6 can tell "seeds disagree" from
        # "insufficient data" (Blind Hunter F2). The <=0 row is still serialized
        # in `seeds[]` (raw value) — only the stats sample is unified.
        finite_bpms = [p["bpm"] for p in seeds_payload if p["bpm"] is not None and p["bpm"] > 0]
        variance = round(pvariance(finite_bpms), 6) if len(finite_bpms) >= 2 else None
        agreement = octave_normalized_agreement(finite_bpms) if len(finite_bpms) >= 2 else None
        # Status reflects SEED COMPLETENESS so Story 7.6 never grades stability
        # off a partial seed set (review Codex S3): "filled-7.5" requires all of
        # {42,43,44}; a partial set is "incomplete-7.5"; none is "no-prediction-7.5".
        present_seeds = set(preds)
        missing_seeds = sorted(set(SEEDS) - present_seeds)
        if not seeds_payload:
            status = "no-prediction-7.5"
        elif missing_seeds:
            status = "incomplete-7.5"
        else:
            status = "filled-7.5"
        out_rows.append(
            {
                "track_id": track_id,
                "failureCategory": row.get("failureCategory"),
                "expectedFailureMode": row.get("expectedFailureMode"),
                "verificationPredicate": row.get("verificationPredicate"),
                "v2Prediction": {
                    "status": status,
                    "missingSeeds": missing_seeds,
                    "seeds": seeds_payload,
                    "varianceBpm": variance,
                    "octaveNormalizedAgreement": agreement,
                    "matchesExpected": None,  # Story 7.6 fills this
                },
            }
        )
    return {
        "_consumedBy": ["7.6"],
        "_schemaNote": (
            "Per-track per-seed v2 predictions across seeds 42/43/44. "
            "matchesExpected is null until Story 7.6 grades against verificationPredicate."
        ),
        "seeds": list(SEEDS),
        "marginalTierCount": len(out_rows),
        "stability": out_rows,
    }


# ---------------------------------------------------------------------------
# Task 8 — feature-distribution sanity (substrate vs the ablation's librosa)
# ---------------------------------------------------------------------------


def feature_distribution_sanity(
    substrate_band_stats: list[tuple[float, float]],
    librosa_band_stats: list[tuple[float, float]],
    *,
    mean_ratio_tol: float = 3.0,
) -> dict[str, Any]:
    """Training-independent guard (Mary, AC13): prove the substrate model-input
    bytes are not "a different planet" from the librosa features the KDD-B2
    winner was chosen on, WITHOUT requiring training convergence.

    ``*_band_stats[band] = (mean, variance)`` over a fixed handful of tracks.
    Flags all-zero-VARIANCE bands, non-finite MEAN/VARIANCE bands on the
    substrate side, non-finite MEAN/VARIANCE bands on the librosa REFERENCE side
    (a nan/inf reference mean would otherwise fail open through the ratio scan),
    and per-band mean ratios outside ``[1/mean_ratio_tol, mean_ratio_tol]``.
    All scans run over the common prefix ``n`` and a mismatched/empty length
    FAILS (review N1: a full-length zero/nonfinite scan mixed with a prefix-only
    ratio scan gave an inconsistent verdict; an empty librosa list previously
    passed vacuously). Review pass 2: a ``nan``/``inf`` VARIANCE band previously
    slipped through (``nan == 0.0`` is False, so it missed the zero-variance
    scan) — now caught explicitly."""
    n = min(len(substrate_band_stats), len(librosa_band_stats))
    length_mismatch = len(substrate_band_stats) != len(librosa_band_stats)
    zero_bands = [b for b in range(n) if substrate_band_stats[b][1] == 0.0]
    nonfinite_bands = [b for b in range(n) if not math.isfinite(substrate_band_stats[b][0])]
    nonfinite_var_bands = [b for b in range(n) if not math.isfinite(substrate_band_stats[b][1])]
    # Finite-check the librosa REFERENCE too (not just the substrate side). A
    # nan/inf librosa mean flows `lm = abs(...)` -> `denom = max(nan, 1e-9)`
    # (returns nan) -> `ratio = nan`, and `nan > tol` / `nan < 1/tol` are both
    # False, so the ratio-outlier scan silently waves it through — `passed`
    # could stay True against a garbage reference, defeating the guard. Scan the
    # variance too for symmetry (it is not a ratio input today, but a non-finite
    # reference variance is the same class of garbage).
    nonfinite_librosa_mean_bands = [
        b for b in range(n) if not math.isfinite(librosa_band_stats[b][0])
    ]
    nonfinite_librosa_var_bands = [
        b for b in range(n) if not math.isfinite(librosa_band_stats[b][1])
    ]
    ratio_outliers: list[int] = []
    for b in range(n):
        sm = abs(substrate_band_stats[b][0])
        lm = abs(librosa_band_stats[b][0])
        if lm < 1e-9 and sm < 1e-9:
            continue
        denom = max(lm, 1e-9)
        ratio = sm / denom
        if ratio > mean_ratio_tol or ratio < 1.0 / mean_ratio_tol:
            ratio_outliers.append(b)
    passed = (
        n > 0
        and not length_mismatch
        and not zero_bands
        and not nonfinite_bands
        and not nonfinite_var_bands
        and not nonfinite_librosa_mean_bands
        and not nonfinite_librosa_var_bands
        and len(ratio_outliers) <= max(1, n // 16)
    )
    return {
        "bandsCompared": n,
        "lengthMismatch": length_mismatch,
        "allZeroVarianceBands": zero_bands,
        "nonFiniteMeanBands": nonfinite_bands,
        "nonFiniteVarianceBands": nonfinite_var_bands,
        "nonFiniteLibrosaMeanBands": nonfinite_librosa_mean_bands,
        "nonFiniteLibrosaVarianceBands": nonfinite_librosa_var_bands,
        "meanRatioOutlierBands": ratio_outliers,
        "meanRatioTolerance": mean_ratio_tol,
        "passed": passed,
        "_note": (
            "Substrate model-input vs the ablation librosa features over a fixed track "
            "handful. A regression here would mean the KDD-B2 winner (chosen on librosa) "
            "trains on a different distribution — catch it BEFORE the operator's full run."
        ),
    }
