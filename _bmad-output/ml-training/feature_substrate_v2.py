"""feature_substrate_v2.py — Story 7.5 Task 2 / AC1 / AC4 / DD #13 / DD #15.

The v2 (substrate-locked) model-input feature producer. Reproduces, in numpy,
the EXACT ``[128, 512]`` mel-major, z-scored, resampled tensor that
``BNNSTechnique.featurize`` emits at runtime (the public
``BNNSTechnique.modelInputTensor(from:)`` seam,
Sources/BoomBoomBoomKitML/BNNSTechnique.swift). The training pipeline MUST
consume THIS — NOT the legacy ``dataset.crop_or_loop_to_target`` crop/loop path
the GiantSteps ablation used — so the model trains on the same tensor the Swift
runtime infers on (FR-21 train/runtime parity).

Parity-verified against the Swift ``dump-model-input`` CLI dump in
``test_feature_parity.py`` stage 5 at the 1e-4 abs / 1e-3 rel tolerance
(DD #15 — 1e-6 is unreachable for float STFT/log accumulation).

FR-15: only the substrate log-mel feeds the model. The per-band z-score +
resample-to-512 are SHAPE transforms (matching the runtime), NOT new signals —
no playlist/path/Rekordbox/artist/ID3/DSP-score signal enters here.

The three steps mirror ``featurize`` exactly:
  Step 1 (transpose) — already mel-major: ``extract_log_mel`` returns ``[M, F]``,
          which equals featurize's post-``vDSP_mtrans`` ``melMajor``.
  Step 2 (z-score)   — per band across time; constant/non-finite-std rows are
          ZEROED (matching featurize's ``stddev == 0`` guard), population std
          (ddof=0) matching ``vDSP_normalize``.
  Step 3 (resample)  — per band F -> W=512 via a float32 control ramp +
          ``vDSP_vlint`` linear interpolation, last control entry clamped one
          ULP below ``F-1`` (matching ``controlVector[W-1].nextDown``).
"""

from __future__ import annotations

import numpy as np

from dataset import extract_log_mel

TARGET_WIDTH = 512
EXPECTED_MEL_BANDS = 128
# Must equal Swift `MLFeatureFrames.currentFeatureSetVersion` /
# `BNNSTechnique.supportedFeatureSetVersion`. This is the Python half of the
# FR-21 train/runtime version-pairing (review Amelia #4): a test pins it so a
# one-sided Swift bump that forgets the Python featurizer fails loudly.
FEATURE_SET_VERSION = "v2"


def zscore_per_band_featurize(mel_major: np.ndarray) -> np.ndarray:
    """Per-band z-score matching ``BNNSTechnique.featurize`` Step 2.

    Uses population std (ddof=0, matching ``vDSP_normalize``) and ZEROES any
    row whose std is exactly zero or non-finite (matching featurize's
    constant-row guard, which ``vDSP_vclr``s the row rather than dividing by
    zero). Differs from ``dataset.zscore_per_band`` (which adds a 1e-8 floor
    and never zeroes) — that floor is harmless on active bands but diverges on
    degenerate bands, so the runtime-faithful version is used at the substrate
    boundary.
    """
    mel_major = np.ascontiguousarray(mel_major, dtype=np.float32)
    n_bands, _ = mel_major.shape
    out = np.empty_like(mel_major)
    # Reduce in float32 (NOT numpy's default float64 upcast) so the mean/std
    # accumulation matches vDSP_normalize's float32 path (review: Winston — the
    # 1e-4 residual was float64-vs-float32 accumulation, not a ddof mismatch).
    mean = mel_major.mean(axis=1, dtype=np.float32)
    std = mel_major.std(axis=1, dtype=np.float32)  # population (ddof=0), matches vDSP_normalize
    for band in range(n_bands):
        s = std[band]
        if s == 0.0 or not np.isfinite(s):
            out[band, :] = 0.0
        else:
            out[band, :] = (mel_major[band, :] - mean[band]) / s
    return out


def resample_to_width_vlint(mel_major: np.ndarray, width: int = TARGET_WIDTH) -> np.ndarray:
    """Per-band linear resample ``F -> width`` matching ``featurize`` Step 3.

    Builds the control vector as ``i * step`` in float32 — vectorized, matching
    what Swift ``vDSP_vramp`` (``rampStart=0``, ``rampStep=Float(F-1)/Float(W-1)``)
    ACTUALLY emits on hardware.

    Empirical correction (Epic 7 close-out, Phase 1.5 ``verify_real_track_parity``):
    the earlier B1/B2 review reasoning assumed ``vDSP_vramp`` performs strict
    scalar accumulation (``C[n]=*A; *A += *B``) and built the control by a
    ``cur += step`` loop. Dumping ``vDSP_vramp``'s real output for a live track
    (``dump-real-track`` -> ``control.f32``, F=2996) DISPROVED that: scalar
    accumulation diverges from the true ramp by ~1.2e-2 in control-index space
    (-> ~3.3e-2 in the model-input tensor, a systematic drift growing toward
    later frames), while ``i*step`` (f32) is the closest portable match (control
    error ~4.9e-4 -> tensor diff ~9.6e-4). The true ``vDSP_vramp`` is block-
    vectorized and NOT bit-reproducible in portable numpy; ``i*step`` is the
    correct, unbiased approximation. The F<=496 parity fixtures cannot see the
    difference (sub-ULP there); only a real multi-minute track surfaces it.
    Clamps the last entry one ULP below ``min(control[W-1], F-1)`` (mirroring
    Swift ``controlVector[W-1].nextDown`` + the in-bounds floor), then linear
    interpolates ``A[floor(c)] + frac * (A[floor(c)+1] - A[floor(c)])`` per band
    (matching ``vDSP_vlint``).
    """
    mel_major = np.ascontiguousarray(mel_major, dtype=np.float32)
    n_bands, frames = mel_major.shape
    step = np.float32(frames - 1) / np.float32(width - 1)
    # i*step in float32 — matches vDSP_vramp's actual (vectorized) output far
    # better than scalar accumulation (Phase 1.5 empirical dump).
    control = (np.arange(width, dtype=np.float32) * step).astype(np.float32)
    # Clamp the last entry one ULP below min(control[W-1], F-1): mirrors Swift
    # `controlVector[W-1].nextDown` while the min(., F-1) floor keeps vDSP_vlint's
    # `A[floor(c)+1]` read in-bounds when i*step rounding nudges the last index
    # to/above F-1 (Swift over-reads one float there — deferred 7-5-D1 — but
    # numpy would hard-crash).
    last = min(float(control[width - 1]), float(frames - 1))
    control[width - 1] = np.nextafter(np.float32(last), np.float32(-np.inf))
    floor_c = np.floor(control).astype(np.int64)
    frac = (control - floor_c.astype(np.float32)).astype(np.float32)
    out = np.empty((n_bands, width), dtype=np.float32)
    for band in range(n_bands):
        row = mel_major[band]
        lower = row[floor_c]
        upper = row[floor_c + 1]
        out[band] = lower + frac * (upper - lower)
    return out


def model_input_tensor_from_log_mel(mel_major_log_mel: np.ndarray) -> np.ndarray:
    """Substrate log-mel (mel-major ``[M, F]``) -> model-input ``[128, 512]``.

    Equivalent to ``BNNSTechnique.modelInputTensor(from:)`` for a payload whose
    ``logMelData`` is the given log-mel envelope.
    """
    mel_major_log_mel = np.ascontiguousarray(mel_major_log_mel, dtype=np.float32)
    if mel_major_log_mel.shape[0] != EXPECTED_MEL_BANDS:
        raise ValueError(
            f"expected {EXPECTED_MEL_BANDS} mel bands, got {mel_major_log_mel.shape[0]}"
        )
    if mel_major_log_mel.shape[1] < 32:
        raise ValueError(
            f"frames {mel_major_log_mel.shape[1]} < 32 — featurize abstains on sub-32-frame clips"
        )
    zscored = zscore_per_band_featurize(mel_major_log_mel)
    return resample_to_width_vlint(zscored, TARGET_WIDTH)


def model_input_tensor_from_audio(audio: np.ndarray, fixture) -> np.ndarray:
    """Audio samples -> substrate log-mel -> model-input tensor ``[128, 512]``."""
    log_mel = extract_log_mel(audio, fixture)  # mel-major [M, F]
    return model_input_tensor_from_log_mel(log_mel)
