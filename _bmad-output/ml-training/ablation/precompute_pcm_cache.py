#!/usr/bin/env python3
"""Pre-build the decode + feature caches for the Tony training corpus (Epic 7 perf).

librosa's MP3/M4A decode + soxr_hq resample AND the STFT/mel/resample substrate
are the training bottleneck — they re-run every epoch while the tiny model leaves
the GPU idle. Two caches remove that cost:

  1. PCM cache (``BBB_PCM_CACHE_DIR``) — decode every corpus file ONCE into
     float16 (capped to the v2 runtime's 120 s window). ALL paths benefit
     (decode happens regardless of augmentation).
  2. Feature cache (``BBB_FEATURE_CACHE_DIR``) — the deterministic ``[128,512]``
     substrate tensor for every NON-augmented consumer: the masked-mel pretrain
     pool (the 30-epoch bulk) plus the val + leaveArtistOut eval sets. Augmented
     finetune draws fresh windows/pitch each epoch and is intentionally skipped.

Both reuse the EXACT cache keys + code the dataset uses
(``ablation_locator._load_pcm`` / ``ablation_features_v2._feature_cache_path`` /
``transform_unlabeled_v2``) so there is zero drift between what's cached and what
training reads. Idempotent: already-cached entries are skipped.

Run: make pcm-cache-build   (sets BBB_PCM_CACHE_DIR + BBB_FEATURE_CACHE_DIR +
TONY_AUDIO_ROOT)
"""

from __future__ import annotations

import os
import random
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ML_TRAINING_DIR)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import ablation_features_v2 as feats_v2  # noqa: E402
import ablation_locator as loc  # noqa: E402
import dataset as ds  # noqa: E402

# Per-worker fixture (loaded once via the pool initializer, not per-task).
_FIXTURE = None


def _init_worker() -> None:
    global _FIXTURE
    _FIXTURE = ds.load_fixture()


def _decode_one(path_str: str) -> tuple[bool, bool]:
    """Returns (ok, was_already_cached). Decoding caches PCM as a side effect."""
    p = Path(path_str)
    if loc._PCM_CACHE_DIR and loc._pcm_cache_path(p).exists():
        return (True, True)
    return (loc._load_pcm(p) is not None, False)


def _feature_one(path_str: str) -> tuple[bool, bool]:
    """Returns (ok, was_already_cached). Computes + caches the deterministic v2
    feature tensor for one track (reads the warm PCM cache)."""
    p = Path(path_str)
    cp = feats_v2._feature_cache_path(str(p), _FIXTURE)
    if cp is not None and cp.exists():
        return (True, True)
    audio = loc._load_pcm(p)
    if audio is None:
        return (False, False)
    # augment=False inside -> deterministic window; rng is unused on that path.
    feats_v2.transform_unlabeled_v2(
        audio, ds.SAMPLE_RATE, _FIXTURE, rng=random.Random(0), cache_key=str(p)
    )
    return (True, False)


def _all_corpus_paths() -> list[str]:
    """Every corpus path — for the PCM cache (decode helps every consumer)."""
    paths: set[str] = set()
    for which in ("train", "val", "leaveArtistOut"):
        for r in loc.build_labeled_records(which):
            paths.add(str(r.audio_path))
    for p in loc.build_pretrain_audio_paths():
        paths.add(str(p))
    return sorted(paths)


def _deterministic_feature_paths() -> list[str]:
    """Paths consumed WITHOUT augmentation — the only ones whose features are
    cacheable: the masked-mel pretrain pool + the val/LAO eval sets. Train is
    augmented (fresh features each epoch) and is excluded."""
    paths: set[str] = set()
    for which in ("val", "leaveArtistOut"):
        for r in loc.build_labeled_records(which):
            paths.add(str(r.audio_path))
    for p in loc.build_pretrain_audio_paths():
        paths.add(str(p))
    return sorted(paths)


def _run_phase(label: str, paths: list[str], fn, workers: int) -> None:
    print(f"{label}: {len(paths)} tracks -> {workers} workers")
    ok = fail = hit = 0
    start = time.time()
    with ProcessPoolExecutor(max_workers=workers, initializer=_init_worker) as ex:
        futures = [ex.submit(fn, p) for p in paths]
        for i, fut in enumerate(as_completed(futures), 1):
            good, was_cached = fut.result()
            if was_cached:
                hit += 1
            elif good:
                ok += 1
            else:
                fail += 1
            if i % 250 == 0 or i == len(paths):
                el = time.time() - start
                print(f"  {i}/{len(paths)}  new={ok} cached={hit} failed={fail}  {el:.0f}s")
    print(
        f"{label} done: new {ok}, already-cached {hit}, failed {fail} in {time.time() - start:.0f}s"
    )


def main() -> int:
    if not loc._PCM_CACHE_DIR and not feats_v2._FEATURE_CACHE_DIR:
        raise SystemExit(
            "Neither BBB_PCM_CACHE_DIR nor BBB_FEATURE_CACHE_DIR set — nothing to "
            "cache. Run `make pcm-cache-build`."
        )
    workers = max(1, (os.cpu_count() or 4))
    if loc._PCM_CACHE_DIR:
        _run_phase("pcm-cache", _all_corpus_paths(), _decode_one, workers)
    if feats_v2._FEATURE_CACHE_DIR:
        _run_phase("feature-cache", _deterministic_feature_paths(), _feature_one, workers)
    return 0


if __name__ == "__main__":
    sys.exit(main())
