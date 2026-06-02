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
import math
import os
import random
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import librosa
import numpy as np
import torch
from torch.utils.data import Dataset

import corpus_common as cc

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
FIXTURES_DIR = ML_TRAINING_DIR / "fixtures"
FIXTURE_PATH = FIXTURES_DIR / "feature_pipeline_v1.npz"
OA300_GT_PATH = (
    REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures" / "oa300-ground-truth.json"
)

# 4-dnb-triplet-targets.json holds the dawproject-verified named-DnB targets
# (Yin Yang/HEFT_Anagram both 170, NOT the octave-down 85 in oa300-ground-truth.json)
DNB_TARGETS_PATH = (
    REPO_ROOT / "_bmad-output" / "implementation-artifacts" / "4-dnb-triplet-targets.json"
)

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


def build_splits(verify: bool = True) -> dict[str, Any]:
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

    KEPT IN SYNC with `corpus_common.normalize_track_key` (DD #10). This copy
    serves the existing OA300<->GiantSteps `_verify_no_leak`; the Story 7.1
    Tony audit imports the corpus_common copy. Identical logic — change both.
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
        gs_normalized_titles = " ".join(_normalize_track_key(t["filename"]) for t in gs_gt)
        leaked = [
            n
            for n in needles
            if n.replace("_", " ") in gs_normalized_titles or n in gs_normalized_titles
        ]
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
# Story 7.1 — Tony namespaced split (DD #2) + leave-artist-out (DD #4) +
# cross-corpus exclusion (AC5). Pure metadata over tony-truth-labels.json; needs
# NO external audio corpus. Deterministic at the seeds below.
# ---------------------------------------------------------------------------

TONY_SPLIT_SEED = 20260531
TONY_VAL_FRACTION = 0.10
LEAVE_ARTIST_OUT_MIN_FRACTION = 0.10  # AC6: held-out >= 10% of trainable (named only)
DNB_TRIPLET_NEEDLES = ("charly", "faraday_bunker", "yin yang", "heft_anagram")
SENTINELS_JAMS_PATH = (
    cc.REPO_ROOT
    / "Tests"
    / "BoomBoomBoomKitBenchmarkTests"
    / "Fixtures"
    / "12-dnb-sentinels-expanded.json"
)
# Operator-curated within-Tony duplicate exclusions (KDD-B4 signoff). The audit
# surfaces near-dup REVIEW FLAGS (same recording under inconsistent names, which
# title/artist normalization can't link); the operator confirms each by ear and
# lists the track_id to DROP here. Excluded before train/val assignment, same as
# the cross-corpus and sentinel exclusions. Optional — absent => no manual drops.
MANUAL_DUP_EXCLUSIONS_PATH = ML_TRAINING_DIR / "manual-dup-exclusions.json"


def load_manual_dup_exclusions() -> set[str]:
    if not MANUAL_DUP_EXCLUSIONS_PATH.exists():
        return set()
    data = json.loads(MANUAL_DUP_EXCLUSIONS_PATH.read_text())
    # Operator input — validate shape loudly (consistent with the sentinel loader)
    # rather than silently mis-reading a string/dict/null, or a misspelled key
    # (`excludedTrackIDs`), as "no exclusions".
    if not isinstance(data, dict) or "excludedTrackIds" not in data:
        raise ValueError(
            f"{MANUAL_DUP_EXCLUSIONS_PATH.name}: expected a JSON object with an "
            f"`excludedTrackIds` key (a list of track_ids; use [] for no drops)."
        )
    ids = data["excludedTrackIds"]
    if not isinstance(ids, list):
        raise ValueError(f"{MANUAL_DUP_EXCLUSIONS_PATH.name}: `excludedTrackIds` must be a list.")

    def _is_id(x) -> bool:
        # bool is an int subclass — exclude it so a JSON true/false fails here
        # with a precise message, not later as an ineligible "True"/"False".
        return isinstance(x, str) or (isinstance(x, int) and not isinstance(x, bool))

    if any(not _is_id(x) for x in ids):
        raise ValueError(
            f"{MANUAL_DUP_EXCLUSIONS_PATH.name}: every excludedTrackIds entry must be a "
            f"track_id string/int (found a {type(next(x for x in ids if not _is_id(x))).__name__})."
        )
    return {str(x) for x in ids}


def load_expanded_sentinel_ids() -> set[str]:
    """The 8 expanded sentinel track_ids (AC7) that MUST be held out of
    tony.train/val. Read from the JAMS fixture if it exists; empty otherwise
    (the split is still valid pre-curation, just without sentinel holdout)."""
    if not SENTINELS_JAMS_PATH.exists():
        return set()  # pre-curation: split is valid without sentinel holdout
    # File PRESENT but unparseable/empty is a corruption, not "no sentinels" —
    # fail loud rather than silently degrade the AC7 holdout to a no-op (the file
    # ships to main and is the FR-18 gate input).
    data = json.loads(SENTINELS_JAMS_PATH.read_text())
    ids = {str(x) for x in data.get("expandedTrackIds", [])}
    if not ids:
        raise ValueError(
            f"{SENTINELS_JAMS_PATH.name} is present but has no `expandedTrackIds` — "
            f"refusing to silently skip the sentinel holdout. Re-run `make curate-sentinels`."
        )
    return ids


class _UnionFind:
    def __init__(self, items: list[str]) -> None:
        self.parent = {i: i for i in items}

    def find(self, x: str) -> str:
        root = x
        while self.parent[root] != root:
            root = self.parent[root]
        while self.parent[x] != root:
            self.parent[x], x = root, self.parent[x]
        return root

    def union(self, a: str, b: str) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            # Deterministic merge: smaller root id wins.
            lo, hi = (ra, rb) if ra < rb else (rb, ra)
            self.parent[hi] = lo


def _recording_components(tracks: list[dict]) -> dict[str, list[dict]]:
    """Connected components over same-recording edges. All copies of one
    recording land in ONE component, so they cannot be split across train / val
    / leaveArtistOut. Two edge kinds:

      - SHARED CANONICAL ARTIST: every track by one canonical artist is one
        component (the artist-disjointness gate depends on this).
      - SHARED NORMALIZED TITLE, but ONLY when at least one endpoint has an EMPTY
        canonical artist. This targets the genuine same-recording case where one
        copy has the artist field populated ("X", "X - Song") and another has it
        empty (artist embedded in the name). It deliberately does NOT union two
        DIFFERENT named artists that merely share a generic title (e.g. two
        unrelated tracks both called "Axiom" or "Simulacra") — that over-merge
        previously fused unrelated artists into one giant component and silently
        distorted the leave-artist-out split (an audit found a 59-track merge of
        Ternion Sound + sinistarr + subject xero via generic titles). The audit's
        audio fingerprint flags the remaining differently-named residue for review.
    """
    if len({str(t.get("track_id")) for t in tracks}) != len(tracks):
        raise ValueError(
            "Duplicate track_id in the trainable set — refusing to build "
            "components (a dict would silently collapse duplicates)."
        )
    by_id = {str(t.get("track_id")): t for t in tracks}
    uf = _UnionFind(list(by_id))
    artist_groups: dict[str, list[str]] = {}
    title_groups: dict[str, list[str]] = {}
    empty_artist: set[str] = set()
    for tid, t in by_id.items():
        ak = cc.canonical_artist_key(t.get("artist"))
        if ak:
            artist_groups.setdefault(ak, []).append(tid)
        else:
            empty_artist.add(tid)
        tk = cc.normalize_track_key(t.get("name", ""))
        if tk:
            title_groups.setdefault(tk, []).append(tid)
    # Artist edges: union every track sharing a canonical artist.
    for group in artist_groups.values():
        for other in group[1:]:
            uf.union(group[0], other)
    # Title edges: only union an empty-artist track to its same-title peers
    # (one of which may be a named recording of that title). Named<->named title
    # collisions are NOT unioned. Anchor to a NAMED track when one exists so the
    # named copy and the artist-in-name copies merge — group[0] is corpus-order
    # and is not guaranteed named (was a bug: an empty group[0] left the named
    # same-title copy in a separate component, crossing split boundaries).
    for group in title_groups.values():
        named = [tid for tid in group if tid not in empty_artist]
        empties = [tid for tid in group if tid in empty_artist]
        if not empties:
            continue  # all named, different artists, same generic title — skip
        anchor = named[0] if named else empties[0]
        for tid in empties:
            uf.union(anchor, tid)
    comps: dict[str, list[dict]] = {}
    for tid, t in by_id.items():
        comps.setdefault(uf.find(tid), []).append(t)
    return comps


def build_tony_splits(external_index: "cc.ExternalIndex | None" = None) -> dict:
    """Build the Tony split: train / val / leaveArtistOut over the Strong+Solid
    trainable set, with Tony<->external-eval leaks EXCLUDED first (AC5).

    Returns a JSON-ready dict. Deterministic.
    """
    tracks, prov = cc.load_tony_corpus()
    trainable = [t for t in tracks if cc.is_trainable(t)]

    # --- AC5: exclude Tony tracks that collide with OA300 / GiantSteps eval ---
    if external_index is None:
        external_index = cc.build_external_index(giantsteps_gt_path=cc.resolve_giantsteps_gt_path())
    matches = cc.find_cross_corpus_matches(trainable, external_index)
    excluded_ids = {m.track_id for m in matches}

    # AC7: the 8 expanded DnB sentinels are held-out eval — exclude from train/val.
    sentinel_ids = load_expanded_sentinel_ids()
    # KDD-B4 signoff: operator-confirmed within-Tony duplicate drops (optional).
    manual_dup_ids = load_manual_dup_exclusions()
    # Fail on a typoed/unknown/redundant id: a silent no-op during the safety-critical
    # signoff would leave the confirmed duplicate in the split while the metadata claims
    # it was excluded. Every listed id must be a track this filter ACTUALLY drops —
    # i.e. trainable AND not already removed by the cross-corpus or sentinel filters —
    # so `manualDupExclusions.count` equals drops actually applied.
    trainable_ids = {str(t.get("track_id")) for t in trainable}
    eligible_ids = trainable_ids - excluded_ids - sentinel_ids
    ineligible_dups = manual_dup_ids - eligible_ids
    if ineligible_dups:
        raise ValueError(
            f"{MANUAL_DUP_EXCLUSIONS_PATH.name} lists {len(ineligible_dups)} track_id(s) that "
            f"this filter cannot drop — not in the Strong/Solid trainable set, or already "
            f"excluded by cross-corpus/sentinel (typo, or remove them): "
            f"{sorted(ineligible_dups)[:10]}"
        )

    clean = [
        t
        for t in trainable
        if str(t.get("track_id")) not in excluded_ids
        and str(t.get("track_id")) not in sentinel_ids
        and str(t.get("track_id")) not in manual_dup_ids
    ]

    # --- connected components over (shared artist OR shared title) ---
    components = _recording_components(clean)

    def comp_artists(members: list[dict]) -> set[str]:
        return {cc.canonical_artist_key(t.get("artist")) for t in members} - {""}

    def comp_key(members: list[dict]) -> str:
        return min(str(t.get("track_id")) for t in members)

    empties_total = [t for t in clean if not cc.canonical_artist_key(t.get("artist"))]

    # --- leave-artist-out: hold out whole NAMED components to >= 10% ---
    # ceil (not round): round() can land below 10% (e.g. round(0.10*1024)=102 is
    # 9.96%), and the audit checks against this same floor — an under-rounded
    # floor would silently pass a sub-10% held-out (AC6).
    target_heldout = math.ceil(LEAVE_ARTIST_OUT_MIN_FRACTION * len(clean))
    named_comps = sorted((c for c in components.values() if comp_artists(c)), key=comp_key)
    rng = random.Random(TONY_SPLIT_SEED)
    rng.shuffle(named_comps)
    held_out_ids: list[str] = []
    held_out_artists: set[str] = set()
    held_out_comp_keys: set[str] = set()
    for members in named_comps:
        if len(held_out_ids) >= target_heldout:
            break
        held_out_comp_keys.add(comp_key(members))
        held_out_ids.extend(str(t.get("track_id")) for t in members)
        held_out_artists |= comp_artists(members)
    held_out_id_set = set(held_out_ids)

    # --- train/val over the remaining components (whole component -> one side) ---
    # Greedy deterministic val accumulation to ~TONY_VAL_FRACTION (whole-component
    # assignment makes a hash-bucket undershoot when a big artist lands in train,
    # so accumulate to the target instead).
    remaining = [
        components[ckey]
        for ckey in sorted(components, key=lambda k: comp_key(components[k]))
        if comp_key(components[ckey]) not in held_out_comp_keys
    ]
    train_artists: set[str] = set()
    for members in remaining:
        train_artists |= comp_artists(members)
    pool_n = sum(len(m) for m in remaining)
    # max(1,...) so a small pool never yields an empty tony.val (Story 7.5's
    # validation loader would crash / silently skip on val == []).
    val_target = max(1, int(round(TONY_VAL_FRACTION * pool_n))) if pool_n else 0
    val_order = list(remaining)
    random.Random(TONY_SPLIT_SEED + 1).shuffle(val_order)
    train_ids: list[str] = []
    val_ids: list[str] = []
    val_n = 0
    for members in val_order:
        ids = [str(t.get("track_id")) for t in members]
        if val_n < val_target:
            val_ids.extend(ids)
            val_n += len(ids)
        else:
            train_ids.extend(ids)

    # Empty-artist tracks that ended up held-out (only as a title-linked dup of a
    # held-out recording) vs excluded from held-out (the standalone majority).
    empty_in_heldout = [t for t in empties_total if str(t.get("track_id")) in held_out_id_set]
    empty_excluded = [t for t in empties_total if str(t.get("track_id")) not in held_out_id_set]

    # --- named DnB triplet confirmation (AC5): none in train+val ---
    train_val_set = set(train_ids) | set(val_ids)
    remaining_names = " ".join(
        (t.get("name") or "").lower() for t in clean if str(t.get("track_id")) in train_val_set
    ).replace("_", " ")
    triplet_residue = [n for n in DNB_TRIPLET_NEEDLES if n.replace("_", " ") in remaining_names]

    return {
        "trainable_before_exclusion": len(trainable),
        "sentinelHoldout": {
            "expandedSentinelIds": sorted(sentinel_ids),
            "count": len(sentinel_ids),
            "note": "AC7 — the 8 expanded DnB sentinels are held-out eval; excluded from "
            "tony.train/val before assignment. Empty if 12-dnb-sentinels-expanded.json is "
            "not yet curated (run `make curate-sentinels`).",
        },
        "manualDupExclusions": {
            "excludedTrackIds": sorted(manual_dup_ids),
            "count": len(manual_dup_ids),
            "note": "Operator-confirmed within-Tony duplicate drops from the KDD-B4 signoff "
            "(manual-dup-exclusions.json). The audit surfaces near-dup REVIEW FLAGS; the "
            "operator confirms each by ear and lists the track_id to drop, then re-runs "
            "`make ml-splits`. Empty until the operator acts.",
        },
        "train": sorted(train_ids),
        "val": sorted(val_ids),
        "leaveArtistOut": {
            "trainArtists": sorted(train_artists),
            "heldOutArtists": sorted(held_out_artists),
            "heldOutTrackIds": sorted(held_out_ids),
            "heldOutCount": len(held_out_ids),
            "minRequired": target_heldout,
            "emptyArtistExcludedCount": len(empty_excluded),
            "emptyArtistTrackIds": sorted(str(t.get("track_id")) for t in empty_excluded),
            "emptyArtistHeldOutAsDupCount": len(empty_in_heldout),
            "note": "Grouping = connected components over (shared canonical artist OR "
            "shared normalized title), so every copy of a recording lands on one side "
            "deterministically (DD #4 + the same-recording gate AC4 needs). Disjoint on "
            "the canonical artist key. Empty-artist tracks are EXCLUDED from the held-out "
            "slice and the disjointness assertion, EXCEPT the few that are title-linked "
            "dups of a held-out recording (emptyArtistHeldOutAsDupCount — they correctly "
            "follow their duplicate). Held-out sized >= 10% of the cleaned trainable set "
            "for Story 7.6 FR-23.",
        },
        "excludedCrossCorpus": {
            "count": len(matches),
            "corporaChecked": external_index.corpora_checked,
            "matches": [
                {
                    "track_id": m.track_id,
                    "tony_name": m.tony_name,
                    "normalized_key": m.normalized_key,
                    "external_corpus": m.external_corpus,
                    "external_title": m.external_title,
                }
                for m in matches
            ],
            "namedDnBTripletResidueInTrain": triplet_residue,
            "note": "AC5 — detect AND remove. Tony is TRAIN; OA300/GiantSteps are FR-18 "
            "eval gates. Conservative: a normalized-title hit is excluded even for generic "
            "titles (excluding a false-positive from training is harmless; admitting a true "
            "leak inflates the gate). NOTE on Charly: Tony's `Charly (Neekeetone Jungle "
            "Rework)` shares an identical normalized title with the OA300 eval entry, but it "
            "is Marginal-tier (truth_confidence 0.627) so it is already excluded by TIERING "
            "and never reaches this cross-corpus pass — it is leak-safe via the tier filter, "
            "not via this exclusion set (which is why it does not appear in `matches`).",
        },
        "_provenance": {
            "labelsSha256": prov.labels_sha256,
            "labelerScriptSha256": prov.labeler_script_sha256,
            "trackCount": prov.track_count,
        },
    }


def hashlib_md5_int(s: str) -> int:
    """Stable cross-run integer hash (Python's builtin hash() is salted)."""
    import hashlib

    return int(hashlib.md5(s.encode()).hexdigest(), 16)


def _external_namespace(splits: dict) -> dict:
    """Shape the legacy GiantSteps/OA300 split into externalEval namespace."""
    return {
        "giantsteps": {
            "train": sorted(t.track_id for t in splits["train"]),
            "val": sorted(t.track_id for t in splits["val"]),
        },
        "oa300": {
            "test": sorted(t.track_id for t in splits["test"]),
        },
        "_meta": splits.get("_meta", {}),
    }


def write_namespaced_corpus_splits_json(
    tony_splits: dict, external: dict | None, out_path: Path
) -> None:
    """Persist the Story 7.1 namespaced split (DD #2). schema_version bumped to
    2 — the flat top-level train/val/test keys are GONE, so a stale-shape
    consumer reading `data["train"]` KeyErrors loudly instead of silently
    treating GiantSteps as Tony.
    """
    payload = {
        "schema_version": 2,
        "schema_note": "v2 namespaces the split: tony.{train,val,leaveArtistOut} is the "
        "TRAINING corpus; externalEval.{giantsteps,oa300} is held-out FR-18 eval. The flat "
        "v1 train/val/test keys are REMOVED — a v1 consumer must fail loud, not reinterpret.",
        "tony": tony_splits,
        "externalEval": external
        if external is not None
        else {
            "_note": "externalEval not rebuilt this run (OA300/GiantSteps corpora "
            "unavailable); re-run with corpus env vars set to populate."
        },
    }
    out_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


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
        raise ValueError(f"Fixture n_mels={fixture.n_mels} != N_MELS={N_MELS}.")
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

    windowed = frames.astype(np.float64) * fixture.stft_window.astype(np.float64)
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
            # Fresh unseeded instance (behaviorally equivalent to the module
            # global for this no-rng-given path; callers normally pass a seeded rng).
            rng = random.Random()
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

    def __getitem__(self, index: int) -> tuple[torch.Tensor, int]:
        record = self.records[index]
        rng = self._make_rng(index)

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
                audio,
                bpm,
                rng,
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
# CLI: build the Story 7.1 namespaced split and write corpus_splits.json
# ---------------------------------------------------------------------------


def main() -> int:
    # Tony split — always buildable (pure metadata, no external corpus).
    tony = build_tony_splits()
    lao = tony["leaveArtistOut"]
    print(
        f"tony.train: {len(tony['train'])}  tony.val: {len(tony['val'])}  "
        f"leaveArtistOut: {lao['heldOutCount']} tracks / {len(lao['heldOutArtists'])} artists "
        f"(min {lao['minRequired']})"
    )
    print(
        f"  excluded cross-corpus: {tony['excludedCrossCorpus']['count']} "
        f"(checked {tony['excludedCrossCorpus']['corporaChecked']})"
    )
    print(f"  empty-artist excluded from held-out: {lao['emptyArtistExcludedCount']}")
    residue = tony["excludedCrossCorpus"]["namedDnBTripletResidueInTrain"]
    print(f"  named DnB triplet residue in train (must be empty): {residue}")

    # externalEval — only when the OA300/GiantSteps corpora are available.
    external = None
    try:
        splits = build_splits(verify=True)
        external = _external_namespace(splits)
        print(
            f"externalEval.giantsteps: {len(external['giantsteps']['train'])} train / "
            f"{len(external['giantsteps']['val'])} val; oa300: "
            f"{len(external['oa300']['test'])} test"
        )
    except (EnvironmentError, FileNotFoundError) as exc:
        print(f"externalEval NOT rebuilt (corpora unavailable): {exc}")
        # Preserve a previously-built externalEval namespace if present.
        out = ML_TRAINING_DIR / "corpus_splits.json"
        if out.exists():
            try:
                prev = json.loads(out.read_text())
                if (
                    isinstance(prev, dict)
                    and isinstance(prev.get("externalEval"), dict)
                    and "giantsteps" in prev["externalEval"]
                ):
                    external = prev["externalEval"]
                    print("  carried forward externalEval from existing corpus_splits.json")
            except (json.JSONDecodeError, OSError):
                pass

    out = ML_TRAINING_DIR / "corpus_splits.json"
    write_namespaced_corpus_splits_json(tony, external, out)
    print(f"\nWrote {out} (schema_version 2, namespaced)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
