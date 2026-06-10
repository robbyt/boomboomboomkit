"""Story 7.5 Tasks 5/6/8 — unit tests for the v2 training downstream contracts
(per-seed metadata, split-version hash, multi-seed marginal stability,
feature-distribution sanity) + the feature_substrate_v2 model-input shape.

stdlib + numpy only; no torch / no corpus / no MPS — these are the pure
contracts Story 7.6 consumes, verifiable independent of the gated training loop.
"""

from __future__ import annotations

import math

import numpy as np
import pytest

import feature_substrate_v2 as fsv2
import train_v2_artifacts as tv2


# --- Task 5: per-seed metadata schema -------------------------------------


def test_seed_metadata_schema_and_promotable():
    md = tv2.build_seed_metadata(
        seed=42,
        epoch_count=60,
        weighting_profile="uniform",
        corpus_version_hash="c0ffee",
        split_version_hash="5p1175",
    )
    assert md["featureSetVersion"] == "v2"
    assert md["modelGeneration"] == "v2"  # DD #14: model-gen != feature version
    assert md["trainingVariant"] == "maskedMelPretrain"
    assert md["weightingProfile"] == "uniform"
    assert md["promotable"] is True  # flipped from Story 7.3's false
    assert md["bundleEligibilityPendingFR18"] is True
    assert md["architecture"] == "TempoCNN"
    assert md["seed"] == 42
    assert md["splitVersionHash"] == "5p1175"


def test_seed_metadata_rejects_non_uniform_profile():
    with pytest.raises(ValueError):
        tv2.build_seed_metadata(
            seed=42,
            epoch_count=1,
            weighting_profile="subBandEmphasis",  # substrate throws — DD #6
            corpus_version_hash="x",
            split_version_hash="y",
        )


def test_seed_metadata_rejects_unknown_seed():
    with pytest.raises(ValueError):
        tv2.build_seed_metadata(
            seed=7,
            epoch_count=1,
            weighting_profile="uniform",
            corpus_version_hash="x",
            split_version_hash="y",
        )


# --- Task 5: split version hash -------------------------------------------


def test_split_version_hash_is_order_independent():
    a = {
        "tony": {
            "train": ["3", "1", "2"],
            "val": ["9"],
            "leaveArtistOut": {"heldOutTrackIds": ["5"]},
        }
    }
    b = {
        "tony": {
            "val": ["9"],
            "train": ["2", "3", "1"],
            "leaveArtistOut": {"heldOutTrackIds": ["5"]},
        }
    }
    assert tv2.compute_split_version_hash(a) == tv2.compute_split_version_hash(b)


def test_split_version_hash_changes_with_membership():
    a = {"tony": {"train": ["1", "2"], "val": ["9"]}}
    b = {"tony": {"train": ["1", "2", "3"], "val": ["9"]}}
    assert tv2.compute_split_version_hash(a) != tv2.compute_split_version_hash(b)


# --- Task 6: octave-normalized agreement ----------------------------------


def test_octave_agreement_true_across_octaves():
    # 120 / 240 / 60 are all the same tempo modulo octave -> agree.
    assert tv2.octave_normalized_agreement([120.0, 240.0, 60.0]) is True


def test_octave_agreement_false_on_distinct_tempos():
    assert tv2.octave_normalized_agreement([120.0, 128.0, 145.0]) is False


# --- Task 6: marginal stability join contract -----------------------------


def test_build_marginal_stability_fills_per_track_per_seed():
    watchlist = {
        "watchlist": [
            {
                "track_id": "101",
                "failureCategory": "halfDoubleOctave",
                "expectedFailureMode": "off-by-octave",
                "verificationPredicate": "octave_family_error",
            }
        ]
    }
    preds = {"101": {42: (120.0, 0.9), 43: (240.0, 0.8), 44: (60.0, 0.7)}}
    out = tv2.build_marginal_stability(watchlist, preds)
    row = out["stability"][0]
    assert out["marginalTierCount"] == 1
    assert out["seeds"] == [42, 43, 44]
    v2 = row["v2Prediction"]
    assert [s["seed"] for s in v2["seeds"]] == [42, 43, 44]
    assert v2["status"] == "filled-7.5"
    assert v2["octaveNormalizedAgreement"] is True  # octave-equal seeds
    assert v2["varianceBpm"] is not None
    assert v2["matchesExpected"] is None  # Story 7.6 fills this
    # join-contract carries the 7.4 categorization forward
    assert row["verificationPredicate"] == "octave_family_error"


def test_build_marginal_stability_handles_missing_predictions():
    watchlist = {"watchlist": [{"track_id": "999", "failureCategory": "unresolved"}]}
    out = tv2.build_marginal_stability(watchlist, {})
    v2 = out["stability"][0]["v2Prediction"]
    assert v2["seeds"] == []
    assert v2["status"] == "no-prediction-7.5"
    assert v2["varianceBpm"] is None
    assert v2["matchesExpected"] is None


# --- Task 8: feature-distribution sanity ----------------------------------


def test_distribution_sanity_passes_on_similar_stats():
    sub = [(1.0, 0.5)] * 128
    lib = [(1.1, 0.6)] * 128
    report = tv2.feature_distribution_sanity(sub, lib)
    assert report["passed"] is True
    assert report["allZeroVarianceBands"] == []


def test_distribution_sanity_flags_zero_variance_bands():
    sub = [(1.0, 0.0)] * 128  # all-zero variance -> degenerate
    lib = [(1.0, 0.5)] * 128
    report = tv2.feature_distribution_sanity(sub, lib)
    assert report["passed"] is False
    assert len(report["allZeroVarianceBands"]) == 128


# --- feature_substrate_v2 model-input shape -------------------------------


def test_model_input_tensor_shape_and_determinism():
    rng = np.random.default_rng(0)
    log_mel = rng.standard_normal((128, 200)).astype(np.float32)  # mel-major [M, F]
    out1 = fsv2.model_input_tensor_from_log_mel(log_mel)
    out2 = fsv2.model_input_tensor_from_log_mel(log_mel)
    assert out1.shape == (128, 512)
    assert out1.dtype == np.float32
    assert np.array_equal(out1, out2)  # deterministic, no RNG


def test_model_input_rejects_wrong_mel_bands_and_short_clips():
    with pytest.raises(ValueError):
        fsv2.model_input_tensor_from_log_mel(np.zeros((64, 200), dtype=np.float32))
    with pytest.raises(ValueError):
        fsv2.model_input_tensor_from_log_mel(np.zeros((128, 16), dtype=np.float32))  # < 32 frames


def test_zscore_zeros_constant_rows():
    # A constant row has zero std -> featurize zeros it (not NaN/Inf).
    mel = np.ones((128, 100), dtype=np.float32)
    z = fsv2.zscore_per_band_featurize(mel)
    assert np.all(z == 0.0)
    assert np.all(np.isfinite(z))


# --- Review-fix regressions ------------------------------------------------


def test_version_pairing_swift_python():
    # Amelia #4 — the Python featurizer's version must equal the v2 metadata
    # version (the Swift `MLFeatureFrames.currentFeatureSetVersion` is "v2",
    # asserted in FeatureSubstrateTests:74). A one-sided bump fails here.
    assert fsv2.FEATURE_SET_VERSION == "v2"
    assert tv2.FEATURE_SET_VERSION == fsv2.FEATURE_SET_VERSION


def test_octave_agreement_does_not_hang_on_inf():
    # BLOCKER B2 — +inf used to spin _octave_fold forever. Must return, not hang.
    assert tv2.octave_normalized_agreement([120.0, float("inf")]) is False
    assert tv2.octave_normalized_agreement([float("inf"), float("nan")]) is False
    assert tv2._octave_fold(float("inf")) == float("inf")  # returns, no loop


def test_resample_control_vector_large_F_stays_linear():
    # Phase 1.5 (Epic 7) empirical correction: the control vector is i*step (f32),
    # matching what Swift vDSP_vramp ACTUALLY emits (verify_real_track_parity
    # disproved the earlier scalar-accumulation model — accumulation drifts ~1.2e-2
    # from the true ramp, i*step ~4.9e-4). A linear ramp row resampled to 512 must
    # stay ~linear (catches a broken control vector).
    frames = 20000
    ramp = np.tile(np.arange(frames, dtype=np.float32), (128, 1))  # every band is 0..F-1
    out = fsv2.resample_to_width_vlint(ramp, width=512)
    assert out.shape == (128, 512)
    expected = np.linspace(0.0, frames - 1, 512, dtype=np.float64)
    assert np.max(np.abs(out[0].astype(np.float64) - expected)) < 1.0
    assert out[0, 0] == 0.0  # control[0] == 0 exactly


def test_resample_last_column_in_bounds_and_near_F_minus_1():
    # Phase 1.5 empirical correction: with the i*step control, control[W-1] =
    # (W-1)*step ~= F-1. The last entry is clamped one ULP below min(control[W-1],
    # F-1) so vDSP_vlint's A[floor(c)+1] read stays in-bounds. For a linear ramp
    # row[i]=i, vlint at the last column returns the control value itself.
    frames = 60000
    width = 512
    ramp = np.tile(np.arange(frames, dtype=np.float32), (128, 1))
    out = fsv2.resample_to_width_vlint(ramp, width=width)
    last = float(out[0, -1])
    # In bounds: strictly below F-1 (clamp + nextDown guarantee floor(c)+1 <= F-1).
    assert last < float(frames - 1)
    # i*step lands the last control essentially at F-1 (within a frame).
    assert abs(last - float(frames - 1)) < 1.0


def test_marginal_stability_incomplete_seed_set():
    # Codex S3 — a partial seed set must NOT be marked filled-7.5.
    watchlist = {"watchlist": [{"track_id": "55", "failureCategory": "dspFailure"}]}
    preds = {"55": {42: (120.0, 0.9), 43: (121.0, 0.8)}}  # missing seed 44
    out = tv2.build_marginal_stability(watchlist, preds)
    v2 = out["stability"][0]["v2Prediction"]
    assert v2["status"] == "incomplete-7.5"
    assert v2["missingSeeds"] == [44]


def test_distribution_sanity_length_mismatch_fails():
    # N1 — mismatched/empty length must FAIL, not pass vacuously.
    report = tv2.feature_distribution_sanity([(1.0, 0.5)] * 128, [])
    assert report["passed"] is False
    assert report["lengthMismatch"] is True


def test_marginal_stability_nonfinite_seed_emits_valid_json():
    # Review pass 2 BLOCKER — a blown-up seed BPM (inf/nan) must NOT serialize as
    # bare `Infinity`/`NaN` (invalid JSON) and must NOT inflate agreement to True.
    import json

    watchlist = {"watchlist": [{"track_id": "77", "failureCategory": "dspFailure"}]}
    preds = {"77": {42: (120.0, 0.9), 43: (float("inf"), 0.8), 44: (60.0, 0.7)}}
    out = tv2.build_marginal_stability(watchlist, preds)
    v2 = out["stability"][0]["v2Prediction"]
    # The inf seed is serialized as null bpm...
    seed43 = next(s for s in v2["seeds"] if s["seed"] == 43)
    assert seed43["bpm"] is None
    # ...variance is computed over the 2 finite seeds (120, 60), never inf...
    assert v2["varianceBpm"] is not None
    assert math.isfinite(v2["varianceBpm"])
    # ...agreement is honest (120 vs 60 are octave-equal -> True over finite set)...
    assert v2["octaveNormalizedAgreement"] is True
    # ...and the whole payload round-trips through STRICT JSON (no Infinity/NaN).
    dumped = json.dumps(out)
    json.loads(dumped, parse_constant=_reject_constant)


def test_marginal_stability_agreement_none_when_under_two_finite():
    # Blind Hunter F2 — fewer than 2 finite seeds -> agreement None (insufficient),
    # NOT False (disagree). Story 7.6 must be able to tell them apart.
    watchlist = {"watchlist": [{"track_id": "78", "failureCategory": "dspFailure"}]}
    preds = {"78": {42: (120.0, 0.9), 43: (float("nan"), 0.8), 44: (float("inf"), 0.7)}}
    out = tv2.build_marginal_stability(watchlist, preds)
    v2 = out["stability"][0]["v2Prediction"]
    assert v2["octaveNormalizedAgreement"] is None
    assert v2["varianceBpm"] is None


def test_marginal_stability_excludes_nonpositive_bpm_from_stats():
    # Third pass P1 — a domain-invalid <=0 BPM must not land in `varianceBpm`
    # while `octaveNormalizedAgreement` (folds only b > 0) drops it: the two
    # stats must share ONE sample set. The <=0 row is still serialized raw.
    watchlist = {"watchlist": [{"track_id": "201", "failureCategory": "dspFailure"}]}
    preds = {"201": {42: (0.0, 0.9), 43: (120.0, 0.8), 44: (60.0, 0.7)}}
    out = tv2.build_marginal_stability(watchlist, preds)
    v2 = out["stability"][0]["v2Prediction"]
    # Variance over {120, 60} only (mean 90, dev +-30) == 900.0 — NOT the
    # pre-fix 2400.0 over {0, 120, 60}. This number IS the proof the sets unified.
    assert v2["varianceBpm"] == 900.0
    assert v2["octaveNormalizedAgreement"] is True  # 120 vs 60 octave-equal
    # The 0.0 seed still appears raw in seeds[] (serialized, not nulled).
    seed42 = next(s for s in v2["seeds"] if s["seed"] == 42)
    assert seed42["bpm"] == 0.0
    assert v2["status"] == "filled-7.5"  # all 3 seeds present


def test_marginal_stability_drops_unknown_seeds():
    # Third pass P2 — a stray seed (99) alongside the full {42,43,44} set must be
    # DROPPED, not serialized into seeds[] nor allowed to pollute the stats. Note
    # the full set is required to exercise the bug: {42,43,99} already reports
    # incomplete/missing-44 pre-fix (vacuous), so use {42,43,44,99}.
    watchlist = {"watchlist": [{"track_id": "202", "failureCategory": "dspFailure"}]}
    preds = {"202": {42: (120.0, 0.9), 43: (240.0, 0.8), 44: (60.0, 0.7), 99: (177.0, 0.6)}}
    out = tv2.build_marginal_stability(watchlist, preds)
    v2 = out["stability"][0]["v2Prediction"]
    assert [s["seed"] for s in v2["seeds"]] == [42, 43, 44]  # 99 dropped
    assert v2["status"] == "filled-7.5"
    assert v2["missingSeeds"] == []
    # Variance over the 3 KNOWN octave-equal seeds {120, 240, 60} — the stray
    # 177 must not be in the sample.
    assert v2["octaveNormalizedAgreement"] is True


def test_distribution_sanity_flags_nonfinite_librosa():
    # Third pass P3 — a non-finite librosa REFERENCE (mean or variance) must fail
    # the guard, not slip through the ratio scan via max(nan, 1e-9) -> nan.
    sub = [(1.0, 0.5)] * 128
    lib_nan_mean = [(1.0, 0.6)] * 128
    lib_nan_mean[7] = (float("nan"), 0.6)
    report = tv2.feature_distribution_sanity(sub, lib_nan_mean)
    assert report["passed"] is False
    assert 7 in report["nonFiniteLibrosaMeanBands"]

    lib_inf_var = [(1.0, 0.6)] * 128
    lib_inf_var[3] = (1.0, float("inf"))
    report2 = tv2.feature_distribution_sanity(sub, lib_inf_var)
    assert report2["passed"] is False
    assert 3 in report2["nonFiniteLibrosaVarianceBands"]


def _reject_constant(token: str):
    raise ValueError(f"invalid JSON constant: {token}")


def test_train_runnerup_delegates_to_ablation_arm():
    # Amelia #2 — the runpy delegation + sys.argv[0] rewrite must actually land
    # in the ablation runner-up arm. `--help` exercises the full forward path
    # (argparse fires after imports) and exits 0; the help text proves it's the
    # ablation arm's surface (it requires --weighting-profile).
    import os
    import subprocess
    import sys

    ml_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    result = subprocess.run(
        [sys.executable, os.path.join(ml_dir, "train_runnerup.py"), "--help"],
        cwd=ml_dir,
        capture_output=True,
        text=True,
        timeout=120,
    )
    assert result.returncode == 0, result.stderr
    assert "--weighting-profile" in result.stdout  # the ablation arm's flag surface
