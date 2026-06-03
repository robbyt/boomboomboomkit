"""FR-15-clean feature transform for the KDD-B2 ablation harness.

Story 7.3 / AC7 / DD #4. Develop-only v1 scaffolding.

THIS MODULE IS THE FR-15 GREP TARGET. It is the "feature-loading code path":
the pure transform from decoded PCM + a BPM label to a model-input tensor. It
references AUDIO ONLY. It MUST NOT contain any of:
  playlist | path | rekordbox | artist | id3
and MUST NOT import the locator (`ablation_locator`) — the one-way import
direction (locator imports features, never the reverse) makes the AC7 grep a
backstop rather than the primary defense. File resolution / manifest reads /
byte fetching all live in `ablation_locator.py` (a file LOCATOR is not a model
FEATURE — the Story 7.2 AC9 distinction).

Feature extraction reuses the FR-15-clean `dataset` helpers (mel + STFT contract
from the shared `feature_pipeline_v1.npz` fixture). The `sub-band-emphasis`
weighting profile is a v1 scaffolding STAND-IN (DD #7): it multiplies a mel-band
weight vector into the `extract_log_mel` OUTPUT (post-mel, PRE z-score) — it does
NOT fork `extract_log_mel` (DD #10 forbids forking), and it is NOT the headline
profile (the KDD-B2 winner is selected under `uniform`, AC3/AC10).
"""

from __future__ import annotations

import random

import numpy as np
import torch

# dataset helpers are PCM-only / FR-15-clean (verified): no forbidden signal.
from dataset import (  # noqa: E402  (sibling module on the inserted sys.path)
    BPM_BIN_COUNT,
    BPM_BIN_MIN,
    SAMPLE_RATE,
    TARGET_FRAMES,
    augment_pcm,
    extract_log_mel,
    sample_window,
    zscore_per_band,
)

UNIFORM = "uniform"
SUB_BAND_EMPHASIS = "sub-band-emphasis"
WEIGHTING_PROFILES = (UNIFORM, SUB_BAND_EMPHASIS)


# v1 sub-band-emphasis stand-in: a documented per-mel-band weight vector applied
# to the extract_log_mel OUTPUT. The four DnB-relevant bands (kick/snare/crack/
# hihat) get a modest boost; everything else stays 1.0. This is an explicit v1
# APPROXIMATION of the unimplemented Swift FeatureSubstrate.subBandEmphasis
# (Story 6.2 / 7.5) — recorded in masked-mel-recipe.md so no v1 sub-band metric
# is mistaken for a v2 claim. 128 mel bands over [30, 16000] Hz.
def _sub_band_weight_vector(n_mels: int) -> np.ndarray:
    w = np.ones(n_mels, dtype=np.float32)
    # Boost the low-mid (kick/snare body) third by 1.3x as a documented stand-in.
    lo = n_mels // 8
    hi = n_mels // 2
    w[lo:hi] = 1.3
    return w


def label_preserving_pitch_shift(
    audio: np.ndarray, rng: random.Random, sr: int = SAMPLE_RATE, max_semitones: float = 2.0
) -> np.ndarray:
    """Net-new octave-aware pitch-shift augmentation (DD #5).

    Pitch-shift does NOT alter tempo, so the BPM label is unchanged (truly
    tempo-preserving, unlike the resample tempo-stretch in `augment_pcm` which
    re-bins the label). Bounded to +/- `max_semitones` so it stays musically
    sensible ("octave-aware"). Applied identically in BOTH arms' fine-tune
    (DD #12 confound control).
    """
    import librosa

    steps = rng.uniform(-max_semitones, max_semitones)
    if abs(steps) < 1e-3:
        return audio
    return librosa.effects.pitch_shift(audio, sr=sr, n_steps=steps).astype(np.float32)


def _window_pcm(
    audio: np.ndarray,
    fixture,
    *,
    rng: random.Random,
    training: bool,
    headroom_frames: int = 16,
    stretch_headroom: float = 1.06,
) -> np.ndarray:
    """Slice a contiguous PCM window sized for >= TARGET_FRAMES output frames plus
    tempo-stretch headroom (rate up to 1.04 SHORTENS audio, so oversize by ~6%).
    Random offset when training (per-epoch window diversity preserved), centered
    for eval. Returns the audio unchanged if the track is shorter than the window
    (`sample_window` loop-pads the mel)."""
    hop = fixture.hop_size
    n_fft = fixture.n_fft
    need = (TARGET_FRAMES + headroom_frames - 1) * hop + n_fft
    win = int(need * stretch_headroom)
    n = audio.shape[0]
    if n <= win:
        return audio
    off = rng.randint(0, n - win) if training else (n - win) // 2
    return audio[off : off + win]


def transform(
    pcm: np.ndarray,
    sample_rate: int,
    bpm: float,
    fixture,
    *,
    augment: bool,
    rng: random.Random,
    weighting_profile: str = UNIFORM,
) -> tuple[torch.Tensor, int]:
    """Pure PCM -> (model-input tensor, bin label). NO path / manifest / metadata.

    Returns `(z-scored log-mel tensor (1, n_mels, TARGET_FRAMES), bin_idx)`.
    """
    if weighting_profile not in WEIGHTING_PROFILES:
        raise ValueError(
            f"weighting_profile must be one of {WEIGHTING_PROFILES}; got {weighting_profile!r}"
        )

    # Window the PCM to ~the segment the model actually consumes BEFORE the heavy
    # ops (cycle-2 perf-feasibility High): tempo-stretch + pitch-shift +
    # extract_log_mel previously ran on the FULL 3-6 min track (~52x more audio
    # than the 512-frame window needs), making a 60-epoch run days-long. Slicing a
    # ~6 s PCM window up front (random offset when augmenting, centered for eval)
    # collapses per-item cost ~25x while preserving augmentation semantics + the
    # DD #10 label-binding (tempo-stretch still rebins the label on the window).
    audio = _window_pcm(pcm.astype(np.float32), fixture, rng=rng, training=augment)
    label_bpm = float(bpm)
    if augment:
        # Tempo-stretch (label-rebinding) + gain + noise, then the net-new
        # label-preserving pitch-shift (DD #5). Skip stretch near the high BPM
        # edge to avoid clamp-collapse (mirrors dataset.TempoDataset).
        from dataset import BPM_BIN_MAX

        stretch_safe_ceiling = BPM_BIN_MAX / 1.04
        audio, label_bpm = augment_pcm(
            audio, label_bpm, rng, sr=sample_rate, allow_stretch=(label_bpm <= stretch_safe_ceiling)
        )
        audio = label_preserving_pitch_shift(audio, rng, sr=sample_rate)

    log_mel = extract_log_mel(audio, fixture)  # (n_mels, T)
    if weighting_profile == SUB_BAND_EMPHASIS:
        # v1 stand-in: weight applied post-extract_log_mel, PRE z-score (DD #7).
        w = _sub_band_weight_vector(log_mel.shape[0])[:, None]
        log_mel = (log_mel * w).astype(np.float32)
    log_mel = sample_window(log_mel, TARGET_FRAMES, rng=rng, training=augment)
    z = zscore_per_band(log_mel)

    bin_idx = max(0, min(BPM_BIN_COUNT - 1, int(round(label_bpm)) - BPM_BIN_MIN))
    return torch.from_numpy(z).unsqueeze(0), bin_idx


def transform_unlabeled(
    pcm: np.ndarray,
    sample_rate: int,
    fixture,
    *,
    rng: random.Random,
    weighting_profile: str = UNIFORM,
) -> torch.Tensor:
    """PCM -> z-scored log-mel tensor (1, n_mels, TARGET_FRAMES) with NO label.

    Used by masked-mel pretraining (self-supervised). No augmentation, no label.
    """
    tensor, _ = transform(
        pcm,
        sample_rate,
        120.0,
        fixture,
        augment=False,
        rng=rng,
        weighting_profile=weighting_profile,
    )
    return tensor
