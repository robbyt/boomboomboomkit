"""Runtime-faithful v2 feature transform for the substrate-bound training run.

Story 7.5 full-run wiring (Epic 7 close-out). Develop-only.

This is the v2 sibling of ``ablation_features.transform`` (v1). The v1 transform
sliced a ~6 s PCM window and sampled a 512-frame log-mel slice at native time
resolution; that is NOT what the Swift runtime feeds the model. The runtime
(``AudioAnalysisService`` -> ``BPMAnalyzer.estimateBPM``) reads up to
``maxSeconds`` (120), finds an energy transition, takes a 30/60/90 s window from
that offset, computes a log-mel over the WHOLE window, and ``BNNSTechnique``
resamples those F frames to W=512. So a v2-trained model must see the same thing:

  select runtime-faithful PCM window -> (augment) -> ``feature_substrate_v2``.

If we fed whole 3-6 min tracks resampled-to-512 the model would learn a global
song summary while inference sees a post-drop 30/60/90 s segment (train/inference
distribution mismatch — Codex plan review). FR-15: only the substrate log-mel
feeds the model; the window selection is a SHAPE/segment choice, no
playlist/path/Rekordbox/artist/ID3 signal enters here. One-way import (locator ->
features) is preserved: this module does NOT import ``ablation_locator``.

Only ``uniform`` weighting is valid for v2 — the Swift ``OnsetFeaturesBuilder``
throws on ``.subBandEmphasis`` (Guardrail 3 / Story 7.5 DD #6), and
``feature_substrate_v2`` has no sub-band-emphasis path.
"""

from __future__ import annotations

import random

import numpy as np
import torch

import feature_substrate_v2 as fsv2  # noqa: E402  (sibling on the inserted sys.path)
from ablation_features import UNIFORM, label_preserving_pitch_shift  # noqa: E402
from dataset import (  # noqa: E402
    BPM_BIN_COUNT,
    BPM_BIN_MIN,
    augment_pcm,
)

# Mirror of the Swift runtime constants (Sources/BoomBoomBoomKit/BPMAnalyzer.swift
# + AnalysisIntensity.swift). Kept literal here (develop-only) rather than parsed
# from Swift; the real-track parity check (Phase 1.5) reads the runtime's ACTUAL
# selected window from the dump manifest, so these only govern TRAINING window
# diversity, which need not be bit-exact with the runtime's deterministic pick.
ENERGY_TRANSITION_MULTIPLIER = 2.0  # BPMAnalyzer.energyTransitionMultiplier
SILENCE_THRESHOLD = 1e-3  # BPMAnalyzer.silenceThreshold
MAX_SECONDS = 120.0  # AudioAnalysisService.Options.maxSeconds default
MIN_DURATION_SECONDS = 4.0  # BPMAnalyzer.minimumDurationSeconds
# AnalysisIntensity.windowSizes for `.thorough` (intensity 7+), the FR-18 producer
# intensity (FR18EvaluationHarnessTests sets opts.intensity = .thorough).
WINDOW_SIZES = (30.0, 60.0, 90.0)
# Training window-size sampling weights (Codex plan review): expose all runtime
# window sizes without tripling epoch size. Longer windows slightly favored
# because `.thorough` progressive analysis tends to settle on them.
TRAIN_WINDOW_WEIGHTS = (0.25, 0.35, 0.40)


def find_energy_transition(audio: np.ndarray, sr: int) -> int:
    """Replicate ``BPMAnalyzer.findEnergyTransition``: scan 1-second RMS blocks
    (max 120) and return the start sample of the first block (after block 0)
    whose RMS exceeds ``2.0 * max(runningAvg, silenceThreshold)``; else 0.

    Float64 RMS here (vDSP uses float32); the ~1 s block granularity makes the
    precision difference immaterial for TRAINING window selection. The parity
    check uses the runtime's dumped offset, not this function.
    """
    window_size = int(sr)
    n = audio.shape[0]
    window_count = min(n // window_size, 120)
    if window_count < 2:
        return 0
    running_sum = 0.0
    for i in range(window_count):
        start = i * window_size
        block = audio[start : start + window_size]
        rms = float(np.sqrt(np.mean(np.square(block, dtype=np.float64)))) if block.size else 0.0
        if i > 0:
            running_avg = running_sum / i
            if rms > ENERGY_TRANSITION_MULTIPLIER * max(running_avg, SILENCE_THRESHOLD):
                return start
        running_sum += rms
    return 0


def _choose_window_seconds(avail_samples: int, sr: int, *, training: bool, rng: random.Random):
    """Pick a window length (seconds) given the samples available after the drop.

    Training: weighted-sample one of the fitting {30,60,90} sizes per call (per
    epoch) so the model sees all runtime window sizes. Eval/val: deterministic —
    the longest fitting size (the runtime's `.thorough` progressive analysis
    favors longer windows; deterministic val must not move). Returns ``None`` to
    signal "nothing fits — use the whole remainder"."""
    fitting = [w for w in WINDOW_SIZES if int(w * sr) <= avail_samples]
    if not fitting:
        return None
    if not training:
        return max(fitting)
    weights = [TRAIN_WINDOW_WEIGHTS[WINDOW_SIZES.index(w)] for w in fitting]
    total = sum(weights)
    r = rng.random() * total
    acc = 0.0
    for w, wt in zip(fitting, weights):
        acc += wt
        if r <= acc:
            return w
    return fitting[-1]


def select_window(audio: np.ndarray, sr: int, *, training: bool, rng: random.Random) -> np.ndarray:
    """Select a runtime-faithful PCM window: cap to ``maxSeconds``, find the energy
    transition, take a 30/60/90 s window from that offset. Falls back to a window
    from the start when the post-drop region is too short (the runtime would
    return nil there; for training we keep a usable window rather than drop the
    track)."""
    cap = int(MAX_SECONDS * sr)
    audio = np.ascontiguousarray(audio[:cap], dtype=np.float32)
    n = audio.shape[0]
    drop = find_energy_transition(audio, sr)
    avail = n - drop
    chosen = _choose_window_seconds(avail, sr, training=training, rng=rng)
    win = avail if chosen is None else int(chosen * sr)
    end = min(drop + win, n)
    window = audio[drop:end]
    min_samp = int(MIN_DURATION_SECONDS * sr)
    if window.shape[0] < min_samp:
        # Post-drop region too short — take a window from the start instead.
        window = audio[: min(win if win > 0 else n, n)]
    return np.ascontiguousarray(window, dtype=np.float32)


def transform_v2(
    pcm: np.ndarray,
    sample_rate: int,
    bpm: float,
    fixture,
    *,
    augment: bool,
    rng: random.Random,
    weighting_profile: str = UNIFORM,
) -> tuple[torch.Tensor, int]:
    """Pure PCM -> (model-input tensor ``(1, 128, 512)``, bin label) via the v2
    substrate. Runtime-faithful window selection + augmentation on the WINDOWED
    PCM, then ``feature_substrate_v2.model_input_tensor_from_audio``."""
    if weighting_profile != UNIFORM:
        raise ValueError(
            "v2 substrate supports only 'uniform' weighting "
            "(OnsetFeaturesBuilder throws on sub-band-emphasis); "
            f"got {weighting_profile!r}"
        )
    audio = np.ascontiguousarray(pcm, dtype=np.float32)
    window = select_window(audio, sample_rate, training=augment, rng=rng)
    label_bpm = float(bpm)
    if augment:
        from dataset import BPM_BIN_MAX

        stretch_safe_ceiling = BPM_BIN_MAX / 1.04
        window, label_bpm = augment_pcm(
            window,
            label_bpm,
            rng,
            sr=sample_rate,
            allow_stretch=(label_bpm <= stretch_safe_ceiling),
        )
        window = label_preserving_pitch_shift(window, rng, sr=sample_rate)
    tensor = fsv2.model_input_tensor_from_audio(
        np.ascontiguousarray(window, dtype=np.float32), fixture
    )  # (128, 512)
    bin_idx = max(0, min(BPM_BIN_COUNT - 1, int(round(label_bpm)) - BPM_BIN_MIN))
    return torch.from_numpy(np.ascontiguousarray(tensor)).unsqueeze(0), bin_idx


def transform_unlabeled_v2(
    pcm: np.ndarray,
    sample_rate: int,
    fixture,
    *,
    rng: random.Random,
    weighting_profile: str = UNIFORM,
) -> torch.Tensor:
    """PCM -> model-input tensor ``(1, 128, 512)`` with NO label, via the v2
    substrate. Used by masked-mel pretraining (self-supervised). No augmentation."""
    tensor, _ = transform_v2(
        pcm,
        sample_rate,
        120.0,
        fixture,
        augment=False,
        rng=rng,
        weighting_profile=weighting_profile,
    )
    return tensor
