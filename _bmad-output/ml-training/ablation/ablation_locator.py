"""Data LOCATOR for the KDD-B2 ablation harness.

Story 7.3 / AC8 / DD #1 / DD #4. Develop-only v1 scaffolding.

This module is the FILE LOCATOR — it resolves the Story-7.1 Tony split + the
Story-7.2 expansion manifests to on-disk audio bytes and produces decoded PCM.
It necessarily references `local_path` / `relPath` (a file LOCATOR is NOT a model
FEATURE — the Story 7.2 AC9 / AC7 distinction), so it is OUT of the FR-15
feature-grep scope. It imports `ablation_features` (one-way: locator -> features,
NEVER the reverse).

Data-boundary contract (AC7): the only things that flow from here into the
feature pipeline are PCM bytes, the sample rate, an `audioHash`/`track_id` for
bookkeeping, and `bpm` — where for the supervised set `bpm` is ONLY the Tony
consensus `bpm_truth` from `tony-truth-labels.json` (never an ID3/DSP/Rekordbox
BPM), and for masked-mel pretraining there is NO label.
"""

from __future__ import annotations

import hashlib
import json
import os
import random
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import Dataset

# Make this module self-sufficient on sys.path so DataLoader workers (macOS spawn)
# can re-import it + its deps regardless of the parent's path setup or cwd: the
# ablation dir (for ablation_features) AND ML_TRAINING_DIR (for dataset/corpus_common).
_ABLATION_DIR = os.path.dirname(os.path.abspath(__file__))
for _p in (_ABLATION_DIR, os.path.dirname(_ABLATION_DIR)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

import ablation_features as feats  # noqa: E402  (one-way import: locator -> features)
import corpus_common as cc  # noqa: E402
import dataset as ds  # noqa: E402  (FIXTURE_PATH, SAMPLE_RATE, load_fixture, worker_init_fn)

ML_TRAINING_DIR = cc.ML_TRAINING_DIR
CORPUS_SPLITS = ML_TRAINING_DIR / "corpus_splits.json"
SECONDARY_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-secondary-supervised-manifest.json"
UNSUPERVISED_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-unsupervised-pretrain-manifest.json"


def tony_audio_root() -> Path:
    """`TONY_AUDIO_ROOT` (manifest relPath base). Env-resolved, Makefile default."""
    root = os.environ.get("TONY_AUDIO_ROOT", "/Users/rterhaar/Dropbox/tony-tunes")
    return Path(root).expanduser()


# ---------------------------------------------------------------------------
# Labeled records (Tony strong split) — net-new string-keyed join (DD #1)
# ---------------------------------------------------------------------------


@dataclass
class LabeledRecord:
    track_id: str
    audio_path: Path
    bpm: float  # Tony consensus bpm_truth ONLY (AC7 data-boundary)


def _load_corpus_splits() -> dict:
    if not CORPUS_SPLITS.exists():
        raise FileNotFoundError(f"{CORPUS_SPLITS} not found — run `make ml-splits`.")
    return json.loads(CORPUS_SPLITS.read_text())


def _split_ids(splits: dict, which: str) -> list[str]:
    """Return the id-list for a Tony split. `tony.train`/`tony.val` are flat
    lists; `tony.leaveArtistOut` is a DICT whose ids are at `.heldOutTrackIds`
    (AC8 — do not treat all three as the same shape)."""
    tony = splits["tony"]
    if which == "leaveArtistOut":
        return [str(x) for x in tony["leaveArtistOut"]["heldOutTrackIds"]]
    return [str(x) for x in tony[which]]


def build_labeled_records(which: str) -> list[LabeledRecord]:
    """Build labeled records for a Tony split via the net-new string-keyed join.

    `corpus_common.load_tony_corpus()` returns ALL 1,344 tracks (it does NOT read
    `corpus_splits.json`); we index by `track_id` (string-keyed — NO int cast)
    and select per the split id-list. Reconciles count vs the JSON (loud-fail on
    drift, DD #1).
    """
    splits = _load_corpus_splits()
    ids = _split_ids(splits, which)
    tracks, _prov = cc.load_tony_corpus()
    by_id = {str(t.get("track_id")): t for t in tracks}

    records: list[LabeledRecord] = []
    missing: list[str] = []
    for tid in ids:
        t = by_id.get(tid)
        if t is None:
            missing.append(tid)
            continue
        local_path = t.get("local_path")
        bpm_truth = t.get("bpm_truth")
        if not local_path or bpm_truth is None:
            missing.append(tid)
            continue
        records.append(
            LabeledRecord(track_id=tid, audio_path=Path(local_path), bpm=float(bpm_truth))
        )

    if missing:
        raise ValueError(
            f"tony.{which}: {len(missing)} split id(s) did not join to a labeled "
            f"track with local_path+bpm_truth (drift between corpus_splits.json and "
            f"tony-truth-labels.json): {missing[:5]}"
        )
    expected = len(ids)
    if len(records) != expected:
        raise ValueError(f"tony.{which}: joined {len(records)} != {expected} split ids (drift).")
    return records


# ---------------------------------------------------------------------------
# Random-split records (DD #6 run B) — the artist-BLIND baseline for the
# leave-artist-out delta. ONE shared seeded split, cardinality-matched to run A.
# ---------------------------------------------------------------------------

RANDOM_SPLIT_SEED = 20260602
_RUN_A_TRAIN_N = 820  # match run A's tony.train cardinality (DD #6)
_RUN_A_HELDOUT_N = 104  # match run A's leaveArtistOut cardinality (DD #6)


def build_random_split_records(seed: int = RANDOM_SPLIT_SEED):
    """Build the DD #6 run-B random split: pool the STRONG-only Tony set
    {tony.train ∪ tony.val ∪ tony.leaveArtistOut}, seed-shuffle artist-BLIND, and
    carve a held-out slice + train set cardinality-matched to run A (104 / 820).

    Returns `(train_records, heldout_records, split_sha)` where `split_sha` is a
    stable SHA-256 over the carved id-lists (the DD #8 random-split artifact hash —
    recorded in run B's sidecar). Floor caveat (DD #6): the pool is already
    artist-curated, so the resulting random-vs-grouped delta is a FLOOR, not a full
    estimate of random-split optimism.
    """
    pool = (
        build_labeled_records("train")
        + build_labeled_records("val")
        + build_labeled_records("leaveArtistOut")
    )
    pool = sorted(pool, key=lambda r: r.track_id)  # deterministic pre-shuffle order
    required = _RUN_A_HELDOUT_N + _RUN_A_TRAIN_N  # 924
    if len(pool) < required:
        raise ValueError(
            f"random-split pool has {len(pool)} records but the run-A carve requires "
            f">= {required} ({_RUN_A_HELDOUT_N} held-out + {_RUN_A_TRAIN_N} train). A Tony "
            f"split shrank below the cardinality-matched contract — update "
            f"_RUN_A_TRAIN_N/_RUN_A_HELDOUT_N or the split."
        )
    random.Random(seed).shuffle(pool)
    heldout = pool[:_RUN_A_HELDOUT_N]
    train = pool[_RUN_A_HELDOUT_N : _RUN_A_HELDOUT_N + _RUN_A_TRAIN_N]
    assert len(heldout) == _RUN_A_HELDOUT_N and len(train) == _RUN_A_TRAIN_N
    split_payload = {
        "seed": seed,
        "heldOutTrackIds": sorted(r.track_id for r in heldout),
        "trainTrackIds": sorted(r.track_id for r in train),
    }
    split_sha = hashlib.sha256(
        json.dumps(split_payload, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()
    return train, heldout, split_sha


# ---------------------------------------------------------------------------
# Unlabeled pretraining audio paths (masked-mel) — label-free (DD #12 hygiene)
# ---------------------------------------------------------------------------


def _read_manifest_relpaths(path: Path, key: str) -> list[str]:
    if not path.exists():
        raise FileNotFoundError(f"{path} not found — run the upstream survey/builder.")
    data = json.loads(path.read_text())
    rows = data[key]
    return [r["relPath"] for r in rows]


def build_pretrain_audio_paths() -> list[Path]:
    """Label-free masked-mel pretraining corpus (AC10 / DD #12).

    = unique resolved audio from {tony.train strong audio} + {secondarySupervised
    audio} + {unsupervisedPool audio}, EXCLUDING tony.val / tony.leaveArtistOut /
    sentinel / eval-leak audio (so the artist-generalization measurement is not
    contaminated). Sentinels + eval-leaks are already excluded from the Tony
    splits + the 7.2 pools (AC7 force-reject); we additionally subtract val/LAO
    local_paths here.
    """
    root = tony_audio_root()
    paths: list[Path] = []

    # Tony strong-train audio.
    for r in build_labeled_records("train"):
        paths.append(r.audio_path)
    # Secondary + unsupervised expansion audio (relPath vs TONY_AUDIO_ROOT).
    for rel in _read_manifest_relpaths(SECONDARY_MANIFEST, "secondarySupervised"):
        paths.append(root / rel)
    for rel in _read_manifest_relpaths(UNSUPERVISED_MANIFEST, "unsupervisedPool"):
        paths.append(root / rel)

    # Exclusion set: val + leaveArtistOut audio (no pretraining on eval audio).
    excluded = {r.audio_path.resolve() for r in build_labeled_records("val")}
    excluded |= {r.audio_path.resolve() for r in build_labeled_records("leaveArtistOut")}

    seen: set[Path] = set()
    out: list[Path] = []
    for p in paths:
        rp = p.resolve()
        if rp in excluded or rp in seen:
            continue
        seen.add(rp)
        out.append(p)
    return out


# ---------------------------------------------------------------------------
# Datasets — LAZY decode (cycle-2 perf High): decode per __getitem__ and let the
# array be GC'd, instead of holding every full track resident (~38 GB for
# tony.train, ~250 GB for the masked-mel pretrain pool would OOM). The feature
# transform windows the PCM before the heavy ops, so per-item cost is bounded;
# num_workers>0 overlaps the decode with GPU compute. Mirrors dataset.TempoDataset's
# lazy idiom. Decode failures are skipped (skip-and-shift, train.py precedent).
# ---------------------------------------------------------------------------


def _load_pcm(path: Path) -> np.ndarray | None:
    import librosa

    try:
        audio, _ = librosa.load(str(path), sr=ds.SAMPLE_RATE, mono=True, res_type="soxr_hq")
        return audio.astype(np.float32)
    except Exception as e:  # noqa: BLE001 — decode failure is data quality, not a bug
        print(f"WARN: failed to load {path}: {e}", file=sys.stderr)
        return None


class LabeledTonyDataset(Dataset):
    """Strong-label Tony dataset. LAZY: decodes the track in `__getitem__` (no
    resident PCM cache) and delegates the FR-15-clean feature transform to
    `ablation_features.transform`. `__getitem__` passes decoded PCM + bpm — never a
    path — into the transform."""

    def __init__(self, records, fixture, *, augment: bool, seed: int, weighting_profile: str):
        # NB: store only picklable state (records/fixture/scalars) — do NOT stash the
        # `random` module on self; that breaks DataLoader worker pickling
        # ("cannot pickle 'module' object"). Use the module-level `random` directly.
        self._records = list(records)
        self._fixture = fixture
        self._augment = augment
        self._seed = seed
        self._wp = weighting_profile
        self._failed: set[int] = set()

    def __len__(self) -> int:
        return len(self._records)

    def __getitem__(self, idx: int):
        # Bounded skip-and-shift on decode failure (NOT recursion — a fully-bad
        # TONY_AUDIO_ROOT over thousands of tracks would blow the recursion limit
        # before the all-failed guard fires; Codex 2026-06-02). Probe at most n
        # consecutive indices, then loud-fail.
        n = len(self._records)
        for k in range(n):
            j = (idx + k) % n
            audio = _load_pcm(self._records[j].audio_path)
            if audio is None:
                self._failed.add(j)
                continue
            r = self._records[j]
            rng = random.Random(self._seed * 1_000_003 + j)
            return feats.transform(
                audio,
                ds.SAMPLE_RATE,
                r.bpm,
                self._fixture,
                augment=self._augment,
                rng=rng,
                weighting_profile=self._wp,
            )
        raise RuntimeError("All labeled tracks failed to decode — check TONY_AUDIO_ROOT.")


class UnlabeledPretrainDataset(Dataset):
    """Label-free masked-mel pretraining dataset. LAZY (same rationale as
    LabeledTonyDataset). Delegates to `ablation_features.transform_unlabeled`.
    NO labels (AC10/DD #12)."""

    def __init__(self, audio_paths, fixture, *, seed: int, weighting_profile: str):
        # Store only picklable state (no `random` module on self — see LabeledTonyDataset).
        self._paths = list(audio_paths)
        self._fixture = fixture
        self._seed = seed
        self._wp = weighting_profile
        self._failed: set[int] = set()

    def __len__(self) -> int:
        return len(self._paths)

    def __getitem__(self, idx: int) -> torch.Tensor:
        # Bounded skip-and-shift (NOT recursion — see LabeledTonyDataset; the
        # pretrain corpus is thousands of paths, well past the recursion limit).
        n = len(self._paths)
        for k in range(n):
            j = (idx + k) % n
            audio = _load_pcm(self._paths[j])
            if audio is None:
                self._failed.add(j)
                continue
            rng = random.Random(self._seed * 1_000_003 + j)
            return feats.transform_unlabeled(
                audio, ds.SAMPLE_RATE, self._fixture, rng=rng, weighting_profile=self._wp
            )
        raise RuntimeError("All pretrain tracks failed to decode — check manifests/paths.")
