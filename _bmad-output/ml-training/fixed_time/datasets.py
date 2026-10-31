"""Fixed-time training datasets (Story 15.5, develop-only).

Drop-in siblings of `ablation_locator.LabeledTonyDataset` and
`UnlabeledPretrainDataset`: same lazy decode, same PCM cache, same
skip-and-shift on a failed decode, same per-song augmentation seeding. The only
change is the transform, which yields one [1, 128, 1200] fixed-time crop at the
start frame the crop plan assigns the song for the current epoch.

Every crop comes from the plan (`fixed_time.plan`); these datasets never run the
rhythm score. `set_epoch` selects the epoch's crop and must be called before the
epoch's DataLoader iterator starts, so worker processes copy the right epoch.

Feature caching covers the deterministic crops only (pretraining crops and the
validation crop), keyed by crop identity (file, size, mtime, start frame) under the
cache version below, so a 512-column cache entry is never read. Augmented
fine-tune crops are never cached.
"""

from __future__ import annotations

import hashlib
import os
import random
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import Dataset

from ablation_locator import _load_pcm
from fixed_time import features as ft

# Bump when a cached (deterministic) crop would change: crop rule, feature math,
# or contract constants.
FEATURE_CACHE_VERSION = "fixed-time-ft2"


def _feature_cache_dir() -> str | None:
    return os.environ.get("BBB_FEATURE_CACHE_DIR") or None


def pcm_source_for(path: Path) -> str:
    """Which PCM a decode of `path` yields right now: the float16 PCM cache entry
    when the cache is on and the entry exists, otherwise a float32 decode (which
    is what `_load_pcm` returns on the decode that first writes the entry)."""
    import ablation_locator as loc

    if loc._PCM_CACHE_DIR:
        try:
            if loc._pcm_cache_path(path).exists():
                return "pcm-cache-f16"
        except OSError:
            pass
    return "decode-f32"


def feature_cache_path(path: Path, start_frame: int, pcm_source: str) -> Path | None:
    """On-disk path for the cached crop at `start_frame` of `path` made from
    `pcm_source`, or None when caching is off."""
    cache_dir = _feature_cache_dir()
    if not cache_dir:
        return None
    try:
        st = path.stat()
        size, mtime_ns = st.st_size, st.st_mtime_ns
    except OSError:
        size, mtime_ns = -1, -1
    key = (
        f"{path}|sz{size}|mt{mtime_ns}|{FEATURE_CACHE_VERSION}|{ft.INPUT_CONTRACT}|"
        f"cap{ft.TRAINING_MAX_SAMPLES}|start{start_frame}|crop{ft.CROP_FRAMES}x{ft.N_MELS}|"
        f"pcm-{pcm_source}"
    )
    digest = hashlib.sha256(key.encode()).hexdigest()[:24]
    return Path(cache_dir) / f"ft-{digest}.f32.npy"


def _load_cached(cache_path: Path | None) -> np.ndarray | None:
    if cache_path is None or not cache_path.exists():
        return None
    try:
        arr = np.load(cache_path)
    except (OSError, ValueError):
        return None
    if arr.shape != (ft.N_MELS, ft.CROP_FRAMES):
        return None
    return arr


def _save_cached(cache_path: Path | None, crop: np.ndarray) -> None:
    if cache_path is None:
        return
    try:
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        tmp = cache_path.with_name(f"{cache_path.stem}.tmp{os.getpid()}.npy")
        np.save(tmp, np.ascontiguousarray(crop, dtype=np.float32))
        os.replace(tmp, cache_path)
    except OSError:
        pass  # best-effort, as in the legacy feature cache


def load_training_pcm(path: Path) -> np.ndarray | None:
    """Decode as the legacy loader does, then keep the first 120 s (the plan's span)."""
    audio = _load_pcm(path)
    if audio is None:
        return None
    return audio[: ft.TRAINING_MAX_SAMPLES]


def deterministic_crop(path: Path, start_frame: int, fixture) -> np.ndarray | None:
    """The unaugmented crop at `start_frame`, read from the feature cache when
    present (keyed by crop identity and PCM source), else decoded and cached.
    None when the decode fails."""
    cache_path = feature_cache_path(path, start_frame, pcm_source_for(path))
    cached = _load_cached(cache_path)
    if cached is not None:
        return cached
    audio = load_training_pcm(path)
    if audio is None:
        return None
    crop = ft.crop_tensor_at(audio, start_frame, fixture)
    _save_cached(cache_path, crop)
    return crop


class _EpochMixin:
    _epoch = 0

    def set_epoch(self, epoch: int) -> None:
        self._epoch = int(epoch)


class FixedTimeLabeledDataset(_EpochMixin, Dataset):
    """Labelled Tony tracks as planned fixed-time crops. Same constructor keywords
    as `LabeledTonyDataset` plus the plan's `schedules` ({path: start frame per
    epoch}) and `validation_crops` ({path: start frame}), so
    `ablation_train.finetune(dataset_factory=...)` can build it in place of the
    legacy set."""

    def __init__(
        self,
        records,
        fixture,
        *,
        augment: bool,
        seed: int,
        weighting_profile: str,
        strict: bool = False,
        feature_path: str = "fixed-time",
        schedules: dict[str, list[int]] | None = None,
        validation_crops: dict[str, int] | None = None,
    ):
        if weighting_profile != "uniform":
            raise ValueError(f"fixed-time crops support only 'uniform'; got {weighting_profile!r}")
        if feature_path != "fixed-time":
            raise ValueError(
                f"FixedTimeLabeledDataset needs feature_path='fixed-time'; got {feature_path!r}"
            )
        ft.check_fixture(fixture)
        self._records = list(records)
        self._fixture = fixture
        self._augment = augment
        self._seed = seed
        self._strict = strict
        self._schedules = dict(schedules or {})
        self._validation_crops = dict(validation_crops or {})
        lookup = self._schedules if augment else self._validation_crops
        missing = [str(r.audio_path) for r in self._records if str(r.audio_path) not in lookup]
        if missing:
            raise ValueError(f"{len(missing)} records have no planned crop: {missing[:3]}")
        self._failed: set[int] = set()

    def __len__(self) -> int:
        return len(self._records)

    def crop_start(self, index: int) -> int:
        """The planned start frame of record `index` in the current epoch."""
        key = str(self._records[index].audio_path)
        if self._augment:
            return self._schedules[key][self._epoch]
        return self._validation_crops[key]

    def _example(self, j: int):
        """Record j's example, or None when its audio does not decode. The
        validation crop is read from the feature cache before any decode."""
        record = self._records[j]
        start = self.crop_start(j)
        if self._augment:
            audio = load_training_pcm(record.audio_path)
            if audio is None:
                return None
            # Same per-song rng seeding as LabeledTonyDataset.
            rng = random.Random(self._seed * 1_000_003 + j)
            crop, label = ft.training_crop(audio, start, record.bpm, self._fixture, rng)
        else:
            crop = deterministic_crop(Path(record.audio_path), start, self._fixture)
            if crop is None:
                return None
            label = ft.bin_for(float(record.bpm))
        return torch.from_numpy(np.ascontiguousarray(crop, dtype=np.float32)).unsqueeze(0), label

    def __getitem__(self, index: int):
        if self._strict:
            example = self._example(index)
            if example is None:
                r = self._records[index]
                raise RuntimeError(
                    f"strict eval: failed to decode record idx={index} "
                    f"track_id={r.track_id} path={r.audio_path}"
                )
            return example
        n = len(self._records)
        for k in range(n):
            j = (index + k) % n
            example = self._example(j)
            if example is None:
                self._failed.add(j)
                continue
            return example
        raise RuntimeError("All labeled tracks failed to decode — check TONY_AUDIO_ROOT.")


class FixedTimePretrainDataset(_EpochMixin, Dataset):
    """Label-free masked-mel pretraining songs as planned fixed-time crops."""

    def __init__(self, audio_paths, fixture, *, schedules: dict[str, list[int]]):
        ft.check_fixture(fixture)
        self._paths = [Path(p) for p in audio_paths]
        self._fixture = fixture
        self._schedules = dict(schedules)
        missing = [str(p) for p in self._paths if str(p) not in self._schedules]
        if missing:
            raise ValueError(
                f"{len(missing)} pretraining songs have no planned crop: {missing[:3]}"
            )
        self._failed: set[int] = set()

    def __len__(self) -> int:
        return len(self._paths)

    def crop_start(self, index: int) -> int:
        return self._schedules[str(self._paths[index])][self._epoch]

    def __getitem__(self, index: int) -> torch.Tensor:
        n = len(self._paths)
        for k in range(n):
            j = (index + k) % n
            crop = deterministic_crop(self._paths[j], self.crop_start(j), self._fixture)
            if crop is None:
                self._failed.add(j)
                continue
            return torch.from_numpy(np.ascontiguousarray(crop, dtype=np.float32)).unsqueeze(0)
        raise RuntimeError("All pretrain tracks failed to decode — check manifests/paths.")
