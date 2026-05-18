"""
Corpus split logic + on-the-fly feature extraction for Story 4-4b training.

Splits per DD #3:
  - GiantSteps (~661 tracks): val = fold01.txt, train = folds 02-10
  - OA300 (82 tracks): held-out test (NEVER touched at train time)

Leak verification per AC #4:
  - Zero filename overlap between OA300 and GiantSteps GT.
  - 4 named DnB triplet tracks (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6)
    confirmed in OA300 only.

Feature pipeline per AC #3 (Story 4-4b DD #5):
  - Mel filterbank + STFT window loaded from shared fixture
    `_bmad-output/ml-training/fixtures/feature_pipeline_v1.npz`
  - Sample rate 44100, n_fft 2048, hop ~441, n_mels 128, fmin 30,
    fmax min(sr/2, 16000)
  - Log compression: np.log1p(100.0 * mel_spec)
  - Per-mel-band z-score across time axis (after log)
"""

from __future__ import annotations

import json
import os
import random
import sys
from dataclasses import dataclass
from pathlib import Path

import librosa
import numpy as np
import torch
from torch.utils.data import Dataset

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
FIXTURES_DIR = ML_TRAINING_DIR / "fixtures"
FIXTURE_PATH = FIXTURES_DIR / "feature_pipeline_v1.npz"
OA300_GT_PATH = REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures" / "oa300-ground-truth.json"

# 4-dnb-triplet-targets.json holds the dawproject-verified named-DnB targets
# (Yin Yang/HEFT_Anagram both 170, NOT the octave-down 85 in oa300-ground-truth.json)
DNB_TARGETS_PATH = REPO_ROOT / "_bmad-output" / "implementation-artifacts" / "4-dnb-triplet-targets.json"

# BPM bin schema per DD #7 — 256 integer bins from 30 to 285 BPM inclusive.
BPM_BIN_MIN = 30
BPM_BIN_MAX = 285
BPM_BIN_COUNT = BPM_BIN_MAX - BPM_BIN_MIN + 1  # 256

# Feature-pipeline contract (verified at fixture load time)
SAMPLE_RATE = 44100
N_FFT = 2048
N_MELS = 128
F_MIN = 30.0
F_MAX = min(SAMPLE_RATE / 2.0, 16000.0)
TARGET_FRAMES = 512  # W per DD #6 input shape
# Bumped when ANY part of the feature pipeline changes — invalidates the
# trained model and forces a re-export.
FEATURE_SET_VERSION = "v1"


def get_corpus_paths() -> tuple[Path, Path]:
    """Resolve OA300_CORPUS_PATH and GIANTSTEPS_CORPUS_PATH from env.

    Both env vars are REQUIRED — no hard-coded fallback paths (would break
    co-developers / CI / different machines). Per Story 4-4b training
    pipeline conventions: corpus paths are deployment-specific.
    """
    oa300 = os.environ.get("OA300_CORPUS_PATH")
    giantsteps = os.environ.get("GIANTSTEPS_CORPUS_PATH")
    if not oa300:
        raise EnvironmentError(
            "OA300_CORPUS_PATH env var must be set; no fallback. "
            "Example: export OA300_CORPUS_PATH=~/Dropbox/OA300_OnsetAudio300"
        )
    if not giantsteps:
        raise EnvironmentError(
            "GIANTSTEPS_CORPUS_PATH env var must be set; no fallback. "
            "Example: export GIANTSTEPS_CORPUS_PATH=~/Dropbox/research/giantsteps-tempo-dataset"
        )
    oa300_p = Path(oa300).expanduser()
    gs_p = Path(giantsteps).expanduser()
    if not oa300_p.is_dir():
        raise FileNotFoundError(f"OA300_CORPUS_PATH not a directory: {oa300}")
    if not gs_p.is_dir():
        raise FileNotFoundError(f"GIANTSTEPS_CORPUS_PATH not a directory: {giantsteps}")
    return oa300_p, gs_p


# ---------------------------------------------------------------------------
# Track records
# ---------------------------------------------------------------------------


@dataclass
class TrackRecord:
    """One labeled track in train, val, or test."""

    track_id: str
    audio_path: Path
    bpm: float
    corpus: str  # "giantsteps" | "oa300"
    genre: str | None
    fold: int | None  # GiantSteps fold number; None for OA300

    @property
    def label_bin(self) -> int:
        """Quantize BPM to [0, 255] bin index per DD #7."""
        idx = int(round(self.bpm)) - BPM_BIN_MIN
        return max(0, min(BPM_BIN_COUNT - 1, idx))


# ---------------------------------------------------------------------------
# Split builder
# ---------------------------------------------------------------------------


def _audio_path_for_oa300_track(oa300_root: Path, track: dict) -> Path | None:
    """OA300 ground-truth has filenames possibly nested under subdirs."""
    subdir = track.get("subdir") or ""
    candidate_dirs = [oa300_root] if not subdir else [oa300_root / subdir]
    # Some entries live in the root, some live under named subdirs. Walk all.
    candidate_dirs.append(oa300_root)
    for d in candidate_dirs:
        p = d / track["filename"]
        if p.exists():
            return p
    # Fallback: deep search.
    for p in oa300_root.rglob(track["filename"]):
        return p
    return None


def _audio_path_for_giantsteps_track(gs_root: Path, track: dict) -> Path | None:
    p = gs_root / "audio" / track["filename"]
    return p if p.exists() else None


def build_splits(verify: bool = True) -> dict[str, list[TrackRecord]]:
    """Return {"train": [...], "val": [...], "test": [...]} per DD #3."""
    oa300_root, gs_root = get_corpus_paths()

    # Load ground truth.
    with open(OA300_GT_PATH) as f:
        oa300_gt = json.load(f)
    with open(gs_root / "giantsteps-tempo-ground-truth.json") as f:
        gs_gt = json.load(f)

    # Read GiantSteps fold splits.
    fold_files: dict[int, list[str]] = {}
    for i in range(1, 11):
        with open(gs_root / "splits" / f"fold{i:02d}.txt") as f:
            fold_files[i] = [line.strip() for line in f if line.strip()]

    # Index GiantSteps GT by filename.
    gs_by_filename = {t["filename"]: t for t in gs_gt}

    # Build train/val records from GiantSteps.
    val: list[TrackRecord] = []
    train: list[TrackRecord] = []
    skipped_no_gt = 0
    skipped_audio_missing = 0
    for fold_num, filenames in fold_files.items():
        target_list = val if fold_num == 1 else train
        for filename in filenames:
            t = gs_by_filename.get(filename)
            if t is None:
                # 3 fold entries are not in the GT (verified at Task 1)
                skipped_no_gt += 1
                continue
            audio = _audio_path_for_giantsteps_track(gs_root, t)
            if audio is None:
                # Audio file missing on disk — skip and track in counter.
                skipped_audio_missing += 1
                continue
            target_list.append(
                TrackRecord(
                    track_id=t["track_id"],
                    audio_path=audio,
                    bpm=float(t["bpm"]),
                    corpus="giantsteps",
                    genre=t.get("genre"),
                    fold=fold_num,
                )
            )

    # Build test records from OA300.
    test: list[TrackRecord] = []
    test_missing_audio = 0
    for t in oa300_gt:
        audio = _audio_path_for_oa300_track(oa300_root, t)
        if audio is None:
            test_missing_audio += 1
            continue
        test.append(
            TrackRecord(
                track_id=t["title"],
                audio_path=audio,
                bpm=float(t["bpm"]),
                corpus="oa300",
                genre=t.get("genre"),
                fold=None,
            )
        )

    if verify:
        _verify_no_leak(oa300_gt, gs_gt)
        _verify_dnb_triplets_in_oa300(test, gs_gt)

    return {
        "train": train,
        "val": val,
        "test": test,
        "_meta": {
            "skipped_no_gt": skipped_no_gt,
            "skipped_audio_missing_giantsteps": skipped_audio_missing,
            "test_missing_audio": test_missing_audio,
        },
    }


def _normalize_track_key(s: str) -> str:
    """Normalize a filename or track-id for cross-corpus comparison.

    Strips: directory components, leading numbering ("4. ", "9. "), bracketed
    suffixes (e.g. "[Original Mix]"), trailing parenthetical artist tags,
    extension, whitespace, then lowercases. Catches the same recording stored
    under different naming conventions across OA300 and GiantSteps.
    """
    import os
    import re

    name = os.path.basename(s)
    # Strip extension
    name = os.path.splitext(name)[0]
    # Strip leading numeric prefix like "4. " or "12 - "
    name = re.sub(r"^\d+\s*[\.\-]\s*", "", name)
    # Drop bracketed/parenthesized suffixes (often artist/version tags)
    name = re.sub(r"\s*[\[\(].*$", "", name)
    # Squash whitespace, lowercase
    name = re.sub(r"\s+", " ", name).strip().lower()
    return name


def _verify_no_leak(oa300_gt: list[dict], gs_gt: list[dict]) -> None:
    """AC #4 leak prevention: zero overlap by exact filename AND by normalized
    title (case-insensitive, leading-numbering-stripped, extension-stripped)
    so the same recording stored under different naming conventions across
    corpora can't slip past as a false-negative.
    """
    oa_filenames = {t["filename"] for t in oa300_gt}
    gs_filenames = {t["filename"] for t in gs_gt}
    exact_overlap = oa_filenames & gs_filenames
    if exact_overlap:
        raise RuntimeError(
            f"Leak detected (exact filename): {len(exact_overlap)} in BOTH OA300 and GiantSteps GT. "
            f"First few: {list(exact_overlap)[:5]}"
        )
    oa_normalized = {_normalize_track_key(f) for f in oa_filenames}
    gs_normalized = {_normalize_track_key(f) for f in gs_filenames}
    norm_overlap = oa_normalized & gs_normalized
    if norm_overlap:
        raise RuntimeError(
            f"Leak detected (normalized title): {len(norm_overlap)} potential cross-corpus "
            f"duplicates. First few: {list(norm_overlap)[:5]}. If these are intentionally "
            f"distinct recordings, sharpen `_normalize_track_key` or whitelist."
        )


def _verify_dnb_triplets_in_oa300(test: list[TrackRecord], gs_gt: list[dict] | None = None) -> None:
    """AC #4 corollary: 4 named DnB triplets MUST be in OA300 (test set) AND
    MUST NOT appear in GiantSteps train+val under any normalized form. The
    original implementation only checked OA300 presence — it could not detect
    a true leak where a DnB triplet shows up in GiantSteps under a renamed
    file. Case-insensitive substring + cross-corpus exclusion check.
    """
    needles = ["charly", "faraday_bunker", "yin yang", "heft_anagram"]
    test_titles_normalized = " ".join(t.track_id.lower() for t in test)
    missing = [n for n in needles if n not in test_titles_normalized]
    if missing:
        raise RuntimeError(
            f"DnB triplets missing from OA300 test set: {missing}. "
            f"Cannot proceed: training set may have leaked DnB tracks."
        )
    if gs_gt is not None:
        gs_normalized_titles = " ".join(
            _normalize_track_key(t["filename"]) for t in gs_gt
        )
        leaked = [n for n in needles if n.replace("_", " ") in gs_normalized_titles
                  or n in gs_normalized_titles]
        if leaked:
            raise RuntimeError(
                f"DnB triplets ALSO appear in GiantSteps train+val: {leaked}. "
                f"Cross-corpus leak — the held-out test gate is compromised."
            )


def write_corpus_splits_json(splits: dict[str, list[TrackRecord]], out_path: Path) -> None:
    """Persist {train, val, test} as deterministic JSON per AC #4."""
    payload = {
        "schema_version": 1,
        "captured_at": "2026-05-09",
        "split_strategy": "GiantSteps fold01 = val; folds 02-10 = train; OA300 = held-out test (DD #3)",
        "counts": {k: len(v) for k, v in splits.items() if isinstance(v, list)},
        "leak_check": "PASS — zero filename overlap, 4 DnB triplets confined to OA300 test",
        "train_track_ids": sorted(t.track_id for t in splits["train"]),
        "val_track_ids": sorted(t.track_id for t in splits["val"]),
        "test_track_ids": sorted(t.track_id for t in splits["test"]),
        "_meta": splits.get("_meta", {}),
    }
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True))


# ---------------------------------------------------------------------------
# Feature extraction (uses shared fixture per AC #3 Part A)
# ---------------------------------------------------------------------------


@dataclass
class FeaturePipelineFixture:
    """Loaded shared filterbank + STFT window contract."""

    mel_filterbank: np.ndarray  # (N_MELS, n_fft//2 + 1) float32
    stft_window: np.ndarray  # (n_fft,) float32
    hop_size: int
    sample_rate: int
    f_min: float
    f_max: float
    n_fft: int
    n_mels: int
    feature_set_version: str
    sha256: str  # self-hash for tamper detection


def load_fixture(path: Path = FIXTURE_PATH) -> FeaturePipelineFixture:
    """Load `feature_pipeline_v1.npz` produced by the Swift CLI tool.

    Validates loaded fields against module constants so a stale or
    misconfigured fixture doesn't silently drive training with the wrong
    feature contract (e.g., 48k decodes feeding into a 44.1k filterbank).
    """
    if not path.exists():
        raise FileNotFoundError(
            f"Shared fixture not found: {path}\n"
            f"Run: cd swift_feature_extractor && swift run dump-fixture"
        )
    data = np.load(path)
    fixture = FeaturePipelineFixture(
        mel_filterbank=data["mel_filterbank"].astype(np.float32),
        stft_window=data["stft_window"].astype(np.float32),
        hop_size=int(data["hop_size"]),
        sample_rate=int(data["sample_rate"]),
        f_min=float(data["f_min"]),
        f_max=float(data["f_max"]),
        n_fft=int(data["n_fft"]),
        n_mels=int(data["n_mels"]),
        feature_set_version=str(data["feature_set_version"].item()),
        sha256=str(data["sha256"].item()),
    )
    # Validate shapes/constants against module-level expectations.
    if fixture.sample_rate != SAMPLE_RATE:
        raise ValueError(
            f"Fixture sample_rate={fixture.sample_rate} != SAMPLE_RATE={SAMPLE_RATE}. "
            f"Re-export with `swift run dump-fixture` after changing SAMPLE_RATE."
        )
    if fixture.n_mels != N_MELS:
        raise ValueError(
            f"Fixture n_mels={fixture.n_mels} != N_MELS={N_MELS}."
        )
    if fixture.n_fft != N_FFT:
        raise ValueError(f"Fixture n_fft={fixture.n_fft} != N_FFT={N_FFT}.")
    if fixture.feature_set_version != FEATURE_SET_VERSION:
        raise ValueError(
            f"Fixture feature_set_version={fixture.feature_set_version!r} "
            f"!= FEATURE_SET_VERSION={FEATURE_SET_VERSION!r}. The fixture is stale; "
            f"re-export to invalidate the trained model."
        )
    expected_fb_shape = (N_MELS, N_FFT // 2)
    if fixture.mel_filterbank.shape != expected_fb_shape:
        raise ValueError(
            f"Fixture mel_filterbank shape {fixture.mel_filterbank.shape} != {expected_fb_shape}"
        )
    expected_window_shape = (N_FFT,)
    if fixture.stft_window.shape != expected_window_shape:
        raise ValueError(
            f"Fixture stft_window shape {fixture.stft_window.shape} != {expected_window_shape}"
        )
    return fixture


def stft_frame_count(n_samples: int, n_fft: int, hop_size: int) -> int:
    """Uncentered Accelerate-style STFT framing matching BPMAnalyzer:
    `frames = (n_samples - n_fft) // hop_size + 1` for `n_samples >= n_fft`,
    else 0 (caller pads to a single padded frame).

    NB: this is NOT the librosa/`numpy.lib.stride_tricks`-style CENTERED
    framing (which would use `ceil((n + hop - 1) / hop)`). Stage 2/3/4 parity
    requires we match Swift's uncentered convention exactly; do not "fix"
    this without auditing the Swift side too.
    """
    if n_samples < n_fft:
        return 0
    return (n_samples - n_fft) // hop_size + 1


def extract_pre_log_mel(
    audio: np.ndarray,
    fixture: FeaturePipelineFixture,
) -> np.ndarray:
    """Compute (T, n_mels) pre-log mel POWER envelope matching BPMAnalyzer.

    Returns Stage 2 output (post-STFT-power, post-mel filterbank, PRE log).
    Layout: (n_frames, n_mels) — matches Swift CLI's Stage 2 dump exactly.

    Steps (mirrors Sources/BoomBoomBoomKit/BPMAnalyzer.swift §
    computeMelOnsetEnvelopeWithSubBands lines 490–585):
      1. Frame audio into n_fft windows hopping by hop_size.
      2. Apply STFT window (loaded from fixture, NOT reconstructed).
      3. Real-FFT → POWER spectrum (vDSP_zvmags = |z|^2, NOT magnitude).
      4. **Swift convention quirk:** the split-complex FFT packs Nyquist into
         the imaginary slot of bin 0, so vDSP_zvmags(bin 0) = DC^2 + Nyquist^2.
         BPMAnalyzer does not separate them; we mirror that. The 1025-bin
         numpy rfft output collapses to a 1024-bin Swift-equivalent: bin[0] =
         |DC|^2 + |Nyquist|^2, bin[1..1023] = |spec[1..1023]|^2.
      5. Mel filterbank multiply: (128, 1024) @ (1024, 1) — from fixture.
    """
    n_fft = fixture.n_fft
    hop = fixture.hop_size
    half_n = fixture.mel_filterbank.shape[1]  # 1024
    assert half_n == n_fft // 2, "fixture filterbank cols must equal n_fft / 2"

    n_frames = stft_frame_count(audio.shape[0], n_fft, hop)
    if n_frames <= 0:
        audio = np.pad(audio, (0, n_fft - audio.shape[0]), mode="constant")
        n_frames = 1

    # Power spectrum in Swift's halfN convention: (half_n, n_frames).
    #
    # Apple vDSP real-FFT scales the first N/2 output bins by 2 (per Apple
    # docs: "first N/2 elements multiplied by 2"). DC and Nyquist are also
    # in that scaled range. Therefore Swift's power = (2X)^2 = 4 * |X|^2 vs
    # numpy's unscaled rfft. Multiply Python power by 4 to match.
    SWIFT_RFFT_POWER_SCALE = 4.0

    # Vectorized framing — sliding_window_view + slice gives all frames at once.
    # Then a single batched rfft replaces per-frame Python loop. Bit-identical
    # to per-frame rfft (numpy's rfft is the same algorithm regardless of axis).
    if audio.shape[0] >= n_fft:
        frames = np.lib.stride_tricks.sliding_window_view(audio, n_fft)[::hop]
        # Defensive: trim to expected n_frames in case sliding_window_view
        # returns extras due to integer rounding.
        frames = frames[:n_frames]
    else:
        # Single padded frame
        padded = np.pad(audio, (0, n_fft - audio.shape[0]), mode="constant")
        frames = padded[np.newaxis, :]

    windowed = (frames.astype(np.float64) * fixture.stft_window.astype(np.float64))
    spec = np.fft.rfft(windowed, axis=1)  # (n_frames, n_fft//2 + 1) = (n_frames, 1025)

    # Build Swift-equivalent (n_frames, half_n) power array
    power_t = np.empty((n_frames, half_n), dtype=np.float64)
    # bin 0 packs DC^2 + Nyquist^2
    power_t[:, 0] = spec[:, 0].real ** 2 + spec[:, half_n].real ** 2
    # bins 1..half_n-1 are standard |z|^2
    power_t[:, 1:] = spec[:, 1:half_n].real ** 2 + spec[:, 1:half_n].imag ** 2
    power_t *= SWIFT_RFFT_POWER_SCALE

    # Mel projection: (n_frames, half_n) @ (half_n, n_mels) = (n_frames, n_mels)
    mel_power = power_t @ fixture.mel_filterbank.T.astype(np.float64)
    return mel_power.astype(np.float32)


def extract_log_mel(
    audio: np.ndarray,
    fixture: FeaturePipelineFixture,
) -> np.ndarray:
    """Compute (n_mels, T) log-mel envelope.

    Returns Stage 3 output as (n_mels, T) — model-input convention. Internally
    calls `extract_pre_log_mel` then applies log1p(100*x).
    """
    pre_log = extract_pre_log_mel(audio, fixture)  # (n_frames, n_mels)
    log_mel_t = np.log1p(100.0 * pre_log).astype(np.float32)
    # Transpose to (n_mels, n_frames) for downstream window/zscore convention.
    return log_mel_t.T


def sample_window(
    log_mel: np.ndarray,
    target_frames: int = TARGET_FRAMES,
    rng: random.Random | None = None,
    training: bool = True,
) -> np.ndarray:
    """Crop / loop to `target_frames` along the time axis.

    Per Task 3.4: random 512-frame contiguous slice for training; centered
    slice for eval; loop the array if T < 512 (do NOT zero-pad — distorts
    z-score statistics).
    """
    n_mels, n_frames = log_mel.shape
    if n_frames < target_frames:
        # Loop-pad
        repeats = (target_frames + n_frames - 1) // n_frames
        looped = np.tile(log_mel, (1, repeats))
        return looped[:, :target_frames]
    if n_frames == target_frames:
        return log_mel
    if training:
        if rng is None:
            rng = random
        offset = rng.randint(0, n_frames - target_frames)
    else:
        offset = (n_frames - target_frames) // 2
    return log_mel[:, offset : offset + target_frames]


def zscore_per_band(features: np.ndarray) -> np.ndarray:
    """Per-mel-band z-score across the time axis (mean 0, std 1).

    Matches BNNSTechnique.featurize step per AC #3.
    """
    mean = features.mean(axis=1, keepdims=True)
    std = features.std(axis=1, keepdims=True)
    return ((features - mean) / (std + 1e-8)).astype(np.float32)


# ---------------------------------------------------------------------------
# Augmentation (DD #10)
# ---------------------------------------------------------------------------


def augment_pcm(
    audio: np.ndarray,
    bpm: float,
    rng: random.Random,
    sr: int = SAMPLE_RATE,
    allow_stretch: bool = True,
) -> tuple[np.ndarray, float]:
    """Apply on-PCM augmentations BEFORE feature extraction (DD #10).

    Returns (augmented_audio, augmented_bpm). Tempo-stretch is the only one
    that re-binds the label per the corrected DD #10 derivation: rate > 1
    makes audio play FASTER (returns fewer samples), so new BPM = bpm * rate.

    `allow_stretch=False` skips tempo-stretch entirely — caller can use this
    to opt out for borderline-high BPM tracks where `bpm * 1.04` would exceed
    the BPM_BIN_MAX clamp and silently mis-label.

    **Stretch implementation note (perf):** `librosa.effects.time_stretch` uses
    phase vocoder (~277 ms / 30s @ 44.1k) and is the per-batch bottleneck. We
    use `scipy.signal.resample` instead (~44 ms / 30s @ 44.1k, 6× faster). This
    co-shifts pitch with tempo (analogous to a tape machine going faster), but
    a tempo classifier cares about the rhythmic period in the onset envelope
    and is approximately invariant to small pitch shifts of the underlying
    spectral content. Net: preserves DD #10's label-binding contract,
    sub-budget perf.
    """
    import scipy.signal

    if allow_stretch:
        # Tempo stretch ±4% — resample-based (pitch follows tempo)
        rate = rng.uniform(0.96, 1.04)
        new_len = int(audio.shape[0] / rate)
        audio = scipy.signal.resample(audio.astype(np.float32), new_len).astype(np.float32)
        new_bpm = bpm * rate
    else:
        new_bpm = bpm

    # Gain ±6 dB
    db = rng.uniform(-6.0, 6.0)
    audio = audio * (10.0 ** (db / 20.0))

    # Pink noise at SNR 30-50 dB. Use numpy's vectorized RNG seeded from the
    # python RNG (180ms→10ms per 30s call). Determinism preserved: each
    # __getitem__ call seeds numpy from `rng` so per-sample output stays
    # reproducible at the same training seed.
    snr_db = rng.uniform(30.0, 50.0)
    sig_power = float(np.mean(audio**2)) + 1e-12
    noise_power = sig_power / (10.0 ** (snr_db / 10.0))
    # Pseudo-pink: white noise with 1/sqrt(f) shaping in freq domain.
    white = rng_normal(rng, audio.shape[0])
    pink = _pink_shape(white).astype(np.float32)
    pink_power = float(np.mean(pink**2)) + 1e-12
    pink *= (noise_power / pink_power) ** 0.5
    audio = (audio + pink).astype(np.float32)

    return audio, float(new_bpm)


def rng_normal(rng: random.Random, n: int) -> np.ndarray:
    """Draw N samples from the unit normal — numpy-vectorized for speed.

    Uses the Python RNG to seed a numpy Generator; preserves per-sample
    determinism at fixed training seed but avoids the 180ms `gauss` loop.
    """
    seed = rng.randrange(2**32)
    np_rng = np.random.default_rng(seed)
    return np_rng.standard_normal(n).astype(np.float32)


def _pink_shape(x: np.ndarray) -> np.ndarray:
    """Apply 1/sqrt(f) freq-domain shaping to white noise (pseudo-pink).

    DC bin (bin 0) is zeroed — pink noise should NOT contain a DC component;
    the prior implementation gave bin 0 weight=1 (since `1/sqrt(1) == 1`),
    which injected a DC bias proportional to the white sample mean. Audible
    on long noise segments.
    """
    spec = np.fft.rfft(x.astype(np.float64))
    n = spec.shape[0]
    weights = 1.0 / np.sqrt(np.arange(1, n + 1))
    weights[0] = 0.0  # zero DC weighting; pink noise has no DC component
    spec *= weights
    return np.fft.irfft(spec, n=x.shape[0]).astype(np.float32)


# ---------------------------------------------------------------------------
# PyTorch Dataset
# ---------------------------------------------------------------------------


class TempoDataset(Dataset):
    """On-the-fly tempo classification dataset.

    Loads audio fresh each __getitem__ (no preprocessed-feature cache —
    augmentation lives on the PCM signal per DD #10). This is the throughput
    bottleneck on M5 Max but enables per-epoch label-bound augmentation.
    """

    def __init__(
        self,
        records: list[TrackRecord],
        fixture: FeaturePipelineFixture,
        augment: bool,
        seed: int = 42,
    ):
        self.records = records
        self.fixture = fixture
        self.augment = augment
        # Per-worker RNG; PyTorch DataLoader gives each worker a different
        # base_seed via worker_init_fn — see worker_init_fn below.
        self._base_seed = seed

    def __len__(self) -> int:
        return len(self.records)

    def _make_rng(self, idx: int) -> random.Random:
        """Index-deterministic RNG for reproducibility."""
        return random.Random(self._base_seed * 1_000_003 + idx)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, int]:
        record = self.records[idx]
        rng = self._make_rng(idx)

        # Load mono audio at the canonical sample rate. soxr_hq matches
        # Accelerate's resampler closer than kaiser_best.
        audio, _ = librosa.load(
            str(record.audio_path),
            sr=SAMPLE_RATE,
            mono=True,
            res_type="soxr_hq",
        )
        audio = audio.astype(np.float32)
        bpm = record.bpm

        if self.augment:
            # Skip tempo-stretch on borderline-high BPM tracks: 280 BPM ×
            # 1.04 = 291.2 → would clamp to bin 255 (=285) and silently mis-
            # label. The 285/1.04 ≈ 274 cutoff keeps stretched labels in
            # bounds without clamp-collapse.
            stretch_safe_ceiling = BPM_BIN_MAX / 1.04
            audio, bpm = augment_pcm(
                audio, bpm, rng,
                sr=SAMPLE_RATE,
                allow_stretch=(bpm <= stretch_safe_ceiling),
            )

        # Feature extraction
        log_mel = extract_log_mel(audio, self.fixture)
        log_mel = sample_window(log_mel, TARGET_FRAMES, rng=rng, training=self.augment)
        z = zscore_per_band(log_mel)

        # Label binning (DD #7). After the stretch-ceiling guard above, bpm
        # should always fall within [BPM_BIN_MIN, BPM_BIN_MAX]; the clamp
        # remains as a defense-in-depth backstop.
        bin_idx = max(0, min(BPM_BIN_COUNT - 1, int(round(bpm)) - BPM_BIN_MIN))

        # NCHW: (1, n_mels, T)
        return torch.from_numpy(z).unsqueeze(0), bin_idx


def worker_init_fn(worker_id: int) -> None:
    """Per-worker seed for reproducibility under DataLoader num_workers > 0."""
    seed = torch.initial_seed() % 2**32
    np.random.seed(seed)
    random.seed(seed)


# ---------------------------------------------------------------------------
# CLI: print split summary and write corpus_splits.json
# ---------------------------------------------------------------------------


def main() -> int:
    splits = build_splits(verify=True)
    print(f"train: {len(splits['train'])} GiantSteps tracks")
    print(f"val:   {len(splits['val'])} GiantSteps tracks (fold01)")
    print(f"test:  {len(splits['test'])} OA300 tracks (held-out)")
    print(f"meta:  {splits.get('_meta', {})}")

    # DnB triplet confirmation
    needles = ["Charly", "Faraday_Bunker", "Yin Yang", "HEFT_Anagram"]
    for n in needles:
        matches = [t.track_id for t in splits["test"] if n in t.track_id]
        print(f"  DnB needle {n!r}: {matches}")

    # Persist split manifest
    out = ML_TRAINING_DIR / "corpus_splits.json"
    write_corpus_splits_json(splits, out)
    print(f"\nWrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
