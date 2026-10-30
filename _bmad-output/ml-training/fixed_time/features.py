"""Fixed-time crop features: the single source for planning, training, inference and parity.

Input contract (Story 15.5):
  - Audio at 44.1 kHz mono (the training loader's resample policy).
  - The v2 substrate log-mel, unchanged: FFT 2048, hop 441, 128 mels from 30 Hz
    to 16 kHz, uncentered STFT framing with no padding, log1p(100 x).
    (`dataset.extract_log_mel`, parity-checked against Swift by stages 2-5.)
  - A crop is exactly 1200 frames, which is 530,807 samples, at 0.01 s per frame.
  - Each crop gets the per-band population z-score on its own (a band whose
    standard deviation is zero or not finite is zeroed, as the runtime does).
  - No resize. The model sees [1, 1, 128, 1200].

Candidate crops start every 600 frames. When those regular crops do not reach
the last frame, one tail crop ends on it. A clip with fewer than 1200 frames has
no crop.

Each candidate crop is scored on its own PCM samples with the rhythm score of
`RhythmicRegionSelector` (ported below as `rhythm_score`). A song keeps at most
4 crops, ranked by score with ties to the earlier start, each scoring above 0
and at least half the song's best (`rank_crops`).

Because frames come from an uncentered STFT, frame f of a long clip is computed
from samples [441 f, 441 f + 2048). A crop starting at frame s therefore equals
the log-mel of the 530,807 samples starting at 441 s, so slicing PCM and slicing
the whole-clip log-mel give the same tensor.
"""

from __future__ import annotations

import math
import random

import numpy as np

import feature_substrate_v2 as fsv2
from ablation_features import label_preserving_pitch_shift
from dataset import (
    BPM_BIN_COUNT,
    BPM_BIN_MAX,
    BPM_BIN_MIN,
    augment_pcm,
    extract_log_mel,
)

SAMPLE_RATE = 44_100
N_FFT = 2048
HOP_SAMPLES = 441
N_MELS = 128
MEL_F_MIN = 30.0
MEL_F_MAX = 16_000.0
LOG_COMPRESSION_SCALE = 100.0

CROP_FRAMES = 1200
CROP_HOP_FRAMES = 600
# (1200 - 1) * 441 + 2048: the fewest samples an uncentered STFT turns into 1200 frames.
CROP_SAMPLES = (CROP_FRAMES - 1) * HOP_SAMPLES + N_FFT
SECONDS_PER_FRAME = HOP_SAMPLES / SAMPLE_RATE
CROP_SECONDS = CROP_SAMPLES / SAMPLE_RATE
TENSOR_SHAPE = (1, 1, N_MELS, CROP_FRAMES)

# Training ranks crops over the first 120 s of each file: the PCM cache cap,
# applied whether or not the cache is set. Scoring reads whole files.
TRAINING_MAX_SECONDS = 120.0
TRAINING_MAX_SAMPLES = int(TRAINING_MAX_SECONDS * SAMPLE_RATE)

# Rhythm ranking.
MAX_KEPT_CROPS = 4
KEEP_FRACTION_OF_BEST = 0.5
RHYTHM_SCORE_SOURCE = (
    "RhythmicRegionSelector.score (Sources/BoomBoomBoomKit/RhythmicRegionSelector.swift), "
    "ported as fixed_time.features:rhythm_score; parity stage 7 checks it against Swift "
    "probeRegions on exact crop slices"
)

# Tempo stretch in `dataset.augment_pcm` draws a rate up to 1.04, and a rate
# above 1 shortens the audio to int(n / rate) samples. Augment a segment long
# enough that even the fastest stretch still leaves a full crop.
MAX_STRETCH_RATE = 1.04
AUG_SEGMENT_SAMPLES = math.ceil(CROP_SAMPLES * MAX_STRETCH_RATE) + 1

# Identity of this input contract. Deliberately not "v2": the legacy arm keeps
# that name, and nothing trained here may be loaded under it.
INPUT_CONTRACT = "fixed-time-crop1200-hop441-sr44100"

# The runtime range the legacy `decodedBPM` rows are reported against. The
# variant reports the raw `30 + argmax` like those rows and flags the range.
RUNTIME_MIN_BPM = 60.0
RUNTIME_MAX_BPM = 200.0

ABSTAIN_SHORT = "shorter-than-crop"
ABSTAIN_NO_RHYTHM = "no-rhythmic-crop"


def frame_count(n_samples: int) -> int:
    """Frames the uncentered STFT produces for `n_samples` (0 below one FFT)."""
    if n_samples < N_FFT:
        return 0
    return (n_samples - N_FFT) // HOP_SAMPLES + 1


def crop_plan(n_frames: int) -> list[int]:
    """Start frames of the candidate crops for a clip of `n_frames` frames.

    Regular crops start at 0, 600, 1200, ... while they fit. If the last regular
    crop does not end on the last frame, one tail crop is added that does.
    Fewer than 1200 frames gives no crop.
    """
    if n_frames < CROP_FRAMES:
        return []
    starts = list(range(0, n_frames - CROP_FRAMES + 1, CROP_HOP_FRAMES))
    if starts[-1] + CROP_FRAMES < n_frames:
        starts.append(n_frames - CROP_FRAMES)
    return starts


def start_seconds(start_frame: int) -> float:
    """Start time of a crop in seconds (frame f starts at sample 441 f)."""
    return start_frame * HOP_SAMPLES / SAMPLE_RATE


def crop_pcm(audio: np.ndarray, start_frame: int) -> np.ndarray:
    """The exact CROP_SAMPLES samples behind the crop starting at `start_frame`."""
    begin = start_frame * HOP_SAMPLES
    out = audio[begin : begin + CROP_SAMPLES]
    if out.shape[0] != CROP_SAMPLES:
        raise ValueError(
            f"crop at frame {start_frame} needs samples [{begin}, {begin + CROP_SAMPLES}), "
            f"audio has {audio.shape[0]}"
        )
    return out


# ---------------------------------------------------------------------------
# Rhythm score (port of RhythmicRegionSelector.score)
# ---------------------------------------------------------------------------

RHYTHM_MIN_LAG = 30  # 200 BPM at 100 onset bins per second
RHYTHM_MAX_LAG = 100  # 60 BPM


def rhythm_score(samples: np.ndarray, sample_rate: int = SAMPLE_RATE) -> float:
    """Rhythm score of one span of PCM: periodicity x activity (`rhythm_score_parts`)."""
    periodicity, activity = rhythm_score_parts(samples, sample_rate)
    return float(periodicity * activity)


def rhythm_score_parts(samples: np.ndarray, sample_rate: int = SAMPLE_RATE) -> tuple[float, float]:
    """(periodicity, activity) of one span of PCM, ported from
    `RhythmicRegionSelector.score`, whose score is their product.

    Bins of sample_rate / 100 samples; each bin's energy is the mean absolute
    value of every max(1, bin / 64)-th sample. Onset is the positive energy
    difference. The score is the best centred, normalised onset autocorrelation
    over lags 30 to 100 (60 to 200 BPM), clamped at 0, times the activity factor
    min(1, 8 x total onset / total energy). Returns (0, 0) for spans under 100
    bins and for spans with no energy, no onset or no onset variance.
    """
    x = np.asarray(samples, dtype=np.float32)
    bin_size = max(1, int(sample_rate / 100))
    bin_count = x.shape[0] // bin_size
    if bin_count < 100:
        return 0.0, 0.0
    step = max(1, bin_size // 64)
    bins = x[: bin_count * bin_size].reshape(bin_count, bin_size)[:, ::step]
    energy = np.abs(bins).astype(np.float64).mean(axis=1)
    onset = np.zeros(bin_count, dtype=np.float64)
    onset[1:] = np.maximum(0.0, energy[1:] - energy[:-1])
    # Swift sums energy over bins 1..<binCount, skipping bin 0.
    total_energy = float(energy[1:].sum())
    total_onset = float(onset.sum())
    if total_energy <= 0.0 or total_onset <= 0.0:
        return 0.0, 0.0
    centered = onset - total_onset / bin_count
    norm = float(np.dot(centered, centered))
    if norm <= 0.0:
        return 0.0, 0.0
    best = 0.0
    for lag in range(RHYTHM_MIN_LAG, RHYTHM_MAX_LAG + 1):
        if lag >= bin_count:
            break
        best = max(best, float(np.dot(centered[lag:], centered[:-lag])) / norm)
    activity = min(1.0, total_onset / max(total_energy, float(np.finfo(np.float32).tiny)) * 8.0)
    return float(max(0.0, best)), float(activity)


def candidate_scores(audio: np.ndarray) -> tuple[int, list[int], list[float]]:
    """44.1 kHz samples -> (frame count, candidate start frames, rhythm score per crop)."""
    audio = np.ascontiguousarray(audio, dtype=np.float32)
    n_frames = frame_count(audio.shape[0])
    starts = crop_plan(n_frames)
    scores = [rhythm_score(crop_pcm(audio, s)) for s in starts]
    return n_frames, starts, scores


def rank_crops(starts: list[int], scores: list[float]) -> list[int]:
    """Kept crops in rank order: at most 4, by score (ties to the earlier start),
    each above 0, at least half the best, and sharing no frame with a crop already
    kept (crops [s, s + 1200) overlap when their starts differ by less than 1200).
    A best score of 0 keeps nothing."""
    if len(starts) != len(scores):
        raise ValueError(f"{len(starts)} starts but {len(scores)} scores")
    order = sorted(range(len(starts)), key=lambda i: (-scores[i], starts[i]))
    if not order or not scores[order[0]] > 0.0:
        return []
    floor = KEEP_FRACTION_OF_BEST * scores[order[0]]
    kept: list[int] = []
    for i in order:
        if len(kept) == MAX_KEPT_CROPS or not (scores[i] > 0.0 and scores[i] >= floor):
            break
        if all(abs(starts[i] - k) >= CROP_FRAMES for k in kept):
            kept.append(starts[i])
    return kept


def ranking_rule() -> dict:
    """The ranking rule as recorded in the crop plan and the manifest."""
    return {
        "scoreSource": RHYTHM_SCORE_SOURCE,
        "scoredOn": "each candidate crop's own 530,807 PCM samples",
        "maxKeptCrops": MAX_KEPT_CROPS,
        "keepFractionOfBest": KEEP_FRACTION_OF_BEST,
        "rule": (
            "rank candidate crops by rhythm score, ties to the earlier start; keep at most "
            f"{MAX_KEPT_CROPS}, each with a score above 0 and at least "
            f"{KEEP_FRACTION_OF_BEST:g} x the song's best; walking the ranking, skip any "
            "crop that shares a frame with a crop already kept (starts less than "
            f"{CROP_FRAMES} frames apart); a best score of 0 keeps none"
        ),
        "keptCropsOverlap": False,
        "cropFrames": CROP_FRAMES,
        "cropHopFrames": CROP_HOP_FRAMES,
        "trainingMaxSeconds": TRAINING_MAX_SECONDS,
    }


# ---------------------------------------------------------------------------
# Crop tensors
# ---------------------------------------------------------------------------


def check_fixture(fixture) -> None:
    """Refuse a feature fixture whose STFT or mel settings differ from this contract."""
    expected = {
        "sample_rate": SAMPLE_RATE,
        "n_fft": N_FFT,
        "hop_size": HOP_SAMPLES,
        "n_mels": N_MELS,
    }
    for name, value in expected.items():
        got = getattr(fixture, name)
        if got != value:
            raise ValueError(f"feature fixture {name}={got}, the fixed-time contract needs {value}")
    if not (math.isclose(fixture.f_min, MEL_F_MIN) and math.isclose(fixture.f_max, MEL_F_MAX)):
        raise ValueError(
            f"feature fixture mel range {fixture.f_min}..{fixture.f_max} Hz, "
            f"the fixed-time contract needs {MEL_F_MIN}..{MEL_F_MAX} Hz"
        )


def zscore_crop(mel_major: np.ndarray) -> np.ndarray:
    """Per-band population z-score of one [128, 1200] crop (runtime-faithful)."""
    if mel_major.shape != (N_MELS, CROP_FRAMES):
        raise ValueError(f"crop shape {mel_major.shape}, expected {(N_MELS, CROP_FRAMES)}")
    return fsv2.zscore_per_band_featurize(mel_major)


def crops_from_log_mel(log_mel: np.ndarray) -> tuple[list[int], np.ndarray]:
    """Whole-clip mel-major log-mel [128, F] -> (start frames, z-scored crops [N, 128, 1200])."""
    if log_mel.shape[0] != N_MELS:
        raise ValueError(f"expected {N_MELS} mel bands, got {log_mel.shape[0]}")
    starts = crop_plan(int(log_mel.shape[1]))
    crops = np.empty((len(starts), N_MELS, CROP_FRAMES), dtype=np.float32)
    for i, start in enumerate(starts):
        crops[i] = zscore_crop(log_mel[:, start : start + CROP_FRAMES])
    return starts, crops


def crops_from_audio(audio: np.ndarray, fixture) -> tuple[int, list[int], np.ndarray]:
    """44.1 kHz mono samples -> (frame count, every candidate start, z-scored crops)."""
    audio = np.ascontiguousarray(audio, dtype=np.float32)
    n_frames = frame_count(audio.shape[0])
    if n_frames < CROP_FRAMES:
        return n_frames, [], np.empty((0, N_MELS, CROP_FRAMES), dtype=np.float32)
    starts, crops = crops_from_log_mel(extract_log_mel(audio, fixture))
    return n_frames, starts, crops


def crop_tensor_from_pcm(pcm: np.ndarray, fixture) -> np.ndarray:
    """Exactly CROP_SAMPLES samples -> one z-scored [128, 1200] crop."""
    if pcm.shape[0] != CROP_SAMPLES:
        raise ValueError(f"crop PCM has {pcm.shape[0]} samples, expected {CROP_SAMPLES}")
    log_mel = extract_log_mel(np.ascontiguousarray(pcm, dtype=np.float32), fixture)
    return zscore_crop(log_mel)


def crop_tensor_at(audio: np.ndarray, start_frame: int, fixture) -> np.ndarray:
    """The z-scored crop starting at `start_frame` of `audio` (no augmentation)."""
    return crop_tensor_from_pcm(crop_pcm(np.asarray(audio, dtype=np.float32), start_frame), fixture)


def bin_for(bpm: float) -> int:
    return max(0, min(BPM_BIN_COUNT - 1, int(round(bpm)) - BPM_BIN_MIN))


def augmentation_segment(n_samples: int, start_frame: int) -> tuple[int, int, bool]:
    """Where to cut the PCM segment augmented for the crop at `start_frame`.

    Returns (segment start sample, d, stretch allowed). The segment normally
    starts at the crop and runs AUG_SEGMENT_SAMPLES; when that would overrun the
    audio it shifts left by d samples, so the crop sits d samples into it. A song
    too short for a full segment gets the bare crop (d = 0) with stretch off.
    """
    crop_start = start_frame * HOP_SAMPLES
    if crop_start + CROP_SAMPLES > n_samples:
        raise ValueError(f"crop at frame {start_frame} overruns {n_samples} samples")
    if n_samples < AUG_SEGMENT_SAMPLES:
        return crop_start, 0, False
    d = max(0, crop_start + AUG_SEGMENT_SAMPLES - n_samples)
    return crop_start - d, d, True


def training_crop(
    pcm: np.ndarray, start_frame: int, bpm: float, fixture, rng: random.Random
) -> tuple[np.ndarray, int]:
    """Augmented fine-tune example for the planned crop: ([128, 1200] crop, bin label).

    Same augmentations in the same order as
    `ablation_features_v2.transform_v2(augment=True)` (tempo stretch, gain, pink
    noise, then pitch shift), applied to a PCM segment that starts at the crop
    (see `augmentation_segment`). After a stretch at rate r the crop is taken
    from sample round(d / r), so it covers the ranked audio. A rate above 1 can
    leave fewer than round(d / r) + CROP_SAMPLES samples when the crop is the
    song's last; then the crop ends on the stretched segment's last sample.
    """
    audio = np.ascontiguousarray(pcm, dtype=np.float32)
    seg_start, d, stretch_ok = augmentation_segment(audio.shape[0], start_frame)
    length = AUG_SEGMENT_SAMPLES if stretch_ok else CROP_SAMPLES
    segment = audio[seg_start : seg_start + length]
    label_bpm = float(bpm)
    stretch_safe_ceiling = BPM_BIN_MAX / MAX_STRETCH_RATE
    allow_stretch = stretch_ok and label_bpm <= stretch_safe_ceiling
    segment, new_bpm = augment_pcm(
        segment, label_bpm, rng, sr=SAMPLE_RATE, allow_stretch=allow_stretch
    )
    rate = new_bpm / label_bpm if allow_stretch and label_bpm > 0 else 1.0
    segment = label_preserving_pitch_shift(segment, rng, sr=SAMPLE_RATE)
    if segment.shape[0] < CROP_SAMPLES:
        raise RuntimeError(
            f"augmented segment has {segment.shape[0]} samples, fewer than one crop "
            f"({CROP_SAMPLES}); AUG_SEGMENT_SAMPLES is too small for the stretch range"
        )
    begin = min(int(round(d / rate)), segment.shape[0] - CROP_SAMPLES)
    crop = crop_tensor_from_pcm(segment[begin : begin + CROP_SAMPLES], fixture)
    return crop, bin_for(new_bpm)


def decode_bpm(probabilities: np.ndarray) -> tuple[float, bool]:
    """Class probabilities [256] -> (raw `30 + argmax` BPM, inside 60...200).

    The raw value is reported whatever it is, as the legacy `decodedBPM` /
    `fr18ModelBPM` rows are. No confidence gate.
    """
    if probabilities.shape != (BPM_BIN_COUNT,):
        raise ValueError(f"expected {BPM_BIN_COUNT} class probabilities, got {probabilities.shape}")
    raw = float(BPM_BIN_MIN + int(np.argmax(probabilities)))
    return raw, RUNTIME_MIN_BPM <= raw <= RUNTIME_MAX_BPM


def input_contract() -> dict:
    """Every input-contract axis, as recorded in the run manifest."""
    return {
        "inputContract": INPUT_CONTRACT,
        "frontendSampleRateHz": SAMPLE_RATE,
        "resamplePolicy": "every file decoded to 44.1 kHz mono (librosa soxr_hq) before features",
        "stft": {
            "fftSize": N_FFT,
            "hopSamples": HOP_SAMPLES,
            "window": "Hann, denormalized (vDSP hanningDenormalized), from the shared fixture",
            "padding": "none: uncentered framing, frames = (n - 2048) // 441 + 1",
            "power": "|X|^2 with the vDSP real-FFT x4 scale; bin 0 packs DC^2 + Nyquist^2",
        },
        "mel": {
            "bands": N_MELS,
            "fMinHz": MEL_F_MIN,
            "fMaxHz": MEL_F_MAX,
            "order": "mel-major rows, band 0 lowest frequency; columns are frames in time order",
            "logCompression": f"log1p({LOG_COMPRESSION_SCALE:g} * x)",
        },
        "normalization": (
            "per crop, per band: (x - mean) / std with population std (ddof=0) in float32; "
            "a band whose std is 0 or not finite is set to 0"
        ),
        "crop": {
            "frames": CROP_FRAMES,
            "samples": CROP_SAMPLES,
            "seconds": CROP_SECONDS,
            "hopFrames": CROP_HOP_FRAMES,
            "tailCropRule": (
                f"regular crops start every {CROP_HOP_FRAMES} frames while they fit; if the "
                "last regular crop does not end on the last frame, one tail crop ends on it"
            ),
            "shortClipRule": f"fewer than {CROP_FRAMES} frames: no crop, row abstains "
            f"'{ABSTAIN_SHORT}'",
            "resize": "none",
        },
        "rhythmRanking": {
            **ranking_rule(),
            "noKeptCropRule": f"scoring: row abstains '{ABSTAIN_NO_RHYTHM}'; training: song "
            "left out and counted",
        },
        "tensorShape": list(TENSOR_SHAPE),
        "classSchema": {
            "bins": BPM_BIN_COUNT,
            "bpmMin": BPM_BIN_MIN,
            "bpmMax": BPM_BIN_MAX,
            "decode": (
                "bpm = 30 + argmax, reported raw including values outside 60...200 (as the "
                "legacy decodedBPM rows are); inRuntimeRange flags 60...200; no confidence gate"
            ),
        },
        "secondsPerFrame": SECONDS_PER_FRAME,
    }
