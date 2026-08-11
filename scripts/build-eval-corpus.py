#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""
Story 12.7 construction harness for the 258-track band-balanced evaluation
corpus (develop-only; NOT shipped to main).

Implements the SIGNED protocol in
`_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md`
section 2 literally: face-value-tag candidate pools with FR-59a.2 training-set
exclusion (metadata AND the mandatory pre-commitment audio-fingerprint review),
per-band seeded membership draw sequences cryptographically committed, blinded
batch staging (position-independent opaque row IDs, randomized within-batch
work order, content-verified audio copies), DSP-free keep/reject ingest with
first-43-cumulative membership recorded in an append-only annotation ledger, a
fail-closed audit that gates emission and signoff, and a JAMS manifest emitter
carrying the section-5 annotation-version tag, the octave-sentinel tags
(section 3, fingerprint-first join), and the 175+ degeneracy note.

Subcommands: commit-pools, prepare-review, stage-batch, ingest, abandon,
status, audit, emit-manifest, signoff.

State lives under the gitignored `_bmad-output/ml-training/eval-corpus/`.
Committed artifacts carry counts, seeds, band names, prose, and named digests
ONLY (q9 privacy rule); the row-level inventory never enters git.

Exit codes: 0 ok, 1 error or audit failure, 2 commitment drift/tamper,
3 privacy-gate violation, 4 operator escalation (HALT).

Run: `uv run --project _bmad-output/ml-training python scripts/build-eval-corpus.py ...`
or the `make eval-corpus-*` targets.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import os
import random
import re
import secrets
import shutil
import sys
from collections.abc import Callable
from datetime import date
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)

# ---------------------------------------------------------------------------
# Paths. Every state/artifact path is module-global and rebindable through
# `configure_paths` so the command-level test suite can drive the real commands
# against a synthetic corpus in `tmp_path` without touching develop state.
# ---------------------------------------------------------------------------

ARTIFACTS_DIR = REPO_ROOT / "_bmad-output" / "implementation-artifacts"
EVAL_CORPUS_DIR = ML_TRAINING_DIR / "eval-corpus"
POOLS_PATH = EVAL_CORPUS_DIR / "candidate-pools.json"
DRAWS_PATH = EVAL_CORPUS_DIR / "draw-sequences.json"
MEMBERSHIP_PATH = EVAL_CORPUS_DIR / "membership.json"
BATCHES_DIR = EVAL_CORPUS_DIR / "batches"
ANNOTATIONS_DIR = EVAL_CORPUS_DIR / "annotations"
STAGING_DIR = EVAL_CORPUS_DIR / "staging"
MANIFEST_PATH = EVAL_CORPUS_DIR / "258-corpus.jams.json"
LEDGER_PATH = EVAL_CORPUS_DIR / "annotation-ledger.jsonl"
REVIEW_FLAGS_PATH = EVAL_CORPUS_DIR / "fingerprint-review.json"
DISPOSITIONS_TEMPLATE_PATH = EVAL_CORPUS_DIR / "fingerprint-dispositions.template.json"
DISPOSITIONS_PATH = EVAL_CORPUS_DIR / "fingerprint-dispositions.json"
DECISIONS_PATH = EVAL_CORPUS_DIR / "12-7-operator-decisions.json"
COMMITMENT_JSON = ARTIFACTS_DIR / "12-7-candidate-commitment.json"
COMMITMENT_MD = ARTIFACTS_DIR / "12-7-candidate-commitment.md"
LEDGER_HEAD_JSON = ARTIFACTS_DIR / "12-7-annotation-ledger-head.json"
ATTESTATION_JSON = ARTIFACTS_DIR / "12-7-signoff-attestation.json"


def configure_paths(state_root: Path, artifacts_dir: Path) -> None:
    """Rebind every state + committed-artifact path (test seam)."""
    global EVAL_CORPUS_DIR, POOLS_PATH, DRAWS_PATH, MEMBERSHIP_PATH, BATCHES_DIR
    global ANNOTATIONS_DIR, STAGING_DIR, MANIFEST_PATH, LEDGER_PATH, REVIEW_FLAGS_PATH
    global DISPOSITIONS_TEMPLATE_PATH, DISPOSITIONS_PATH, DECISIONS_PATH
    global ARTIFACTS_DIR, COMMITMENT_JSON, COMMITMENT_MD, LEDGER_HEAD_JSON, ATTESTATION_JSON
    EVAL_CORPUS_DIR = state_root
    POOLS_PATH = state_root / "candidate-pools.json"
    DRAWS_PATH = state_root / "draw-sequences.json"
    MEMBERSHIP_PATH = state_root / "membership.json"
    BATCHES_DIR = state_root / "batches"
    ANNOTATIONS_DIR = state_root / "annotations"
    STAGING_DIR = state_root / "staging"
    MANIFEST_PATH = state_root / "258-corpus.jams.json"
    LEDGER_PATH = state_root / "annotation-ledger.jsonl"
    REVIEW_FLAGS_PATH = state_root / "fingerprint-review.json"
    DISPOSITIONS_TEMPLATE_PATH = state_root / "fingerprint-dispositions.template.json"
    DISPOSITIONS_PATH = state_root / "fingerprint-dispositions.json"
    DECISIONS_PATH = state_root / "12-7-operator-decisions.json"
    ARTIFACTS_DIR = artifacts_dir
    COMMITMENT_JSON = artifacts_dir / "12-7-candidate-commitment.json"
    COMMITMENT_MD = artifacts_dir / "12-7-candidate-commitment.md"
    LEDGER_HEAD_JSON = artifacts_dir / "12-7-annotation-ledger-head.json"
    ATTESTATION_JSON = artifacts_dir / "12-7-signoff-attestation.json"


SURVEY_PATH = ML_TRAINING_DIR / "non-rekordbox-survey.json"
TONY_SURVEY_PATH = ML_TRAINING_DIR / "tony-corpus" / "tony-survey.json"
OA300_GT_PATH = cc.OA300_GT_PATH
SECONDARY_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-secondary-supervised-manifest.json"
UNSUPERVISED_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-unsupervised-pretrain-manifest.json"
CORPUS_SPLITS = ML_TRAINING_DIR / "corpus_splits.json"

N_BAND = 43
DEFAULT_BATCH_SIZE = 40
ANNOTATION_VERSION_TAG = "declared:metrical-full-tempo-v1-2026-08-08"
PROTOCOL_POINTER = (
    "_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md section 2"
)
SEED_ALGORITHM = "python-stdlib random.Random (Mersenne Twister), Random(seed).shuffle(sorted_rows)"

STATUS_ACTIVE = "active"
STATUS_SUPERSEDED = "superseded"

LEDGER_COMPLETED = "completed"
LEDGER_REPLACEMENT = "replacement"
LEDGER_ABANDONED = "abandoned"
LEDGER_STATUSES = (LEDGER_COMPLETED, LEDGER_REPLACEMENT, LEDGER_ABANDONED)
GENESIS_DIGEST = "0" * 64

# Review-flag cosine threshold, matching the audit-corpus-splits.py DD #3
# precedent (NEAR_DUP_REVIEW = 0.97). The algorithm FLAGS; a recorded human
# disposition is what excludes, so the coarse-signature blind spot never
# auto-removes a track and never auto-clears one either.
FINGERPRINT_REVIEW_COSINE = 0.97
SENTINEL_SAME_RECORDING_COSINE = 0.97

DISPOSITION_SAME = "same-recording"
DISPOSITION_NOT_SAME = "not-same-recording"
DISPOSITION_VALUES = (DISPOSITION_SAME, DISPOSITION_NOT_SAME)
FLAG_KIND_FINGERPRINT = "training-fingerprint"
FLAG_KIND_GIANTSTEPS = "giantsteps-title"
FLAG_KIND_CROSS_BAND = "cross-band-recording"

SHORT_BAND_POLICIES = ("fallback-addendum", "shrink-corpus")
CROSS_BAND_POLICIES = ("pre-commitment-recording-dedup", "audit-fails-on-cross-band-duplicate")

# All six band edges half-open [lo, hi) at 100/120/140/160/175 (signed protocol
# step 1; applies to pools, keep/reject band checks, and sentinel windows).
BANDS: list[tuple[str, float, float]] = [
    ("sub-100", 0.0, 100.0),
    ("100-120", 100.0, 120.0),
    ("120-140", 120.0, 140.0),
    ("140-160", 140.0, 160.0),
    ("160-175", 160.0, 175.0),
    ("175-plus", 175.0, math.inf),
]
BAND_NAMES = [b[0] for b in BANDS]

# Sentinel windows (section 3): two-directional octave pair, half-open.
SENTINEL_FULL = (160.0, 175.0)
SENTINEL_HALF = (80.0, 87.5)

EXCLUSION_REASONS = (
    "manifest-hash",
    "tony-split",
    "artist",
    "audio-unresolved",
    "audio-unhashable",
    "fingerprint-confirmed",
    "cross-band-duplicate",
)

# FR-59a.1 allowlists: membership inputs may contain ONLY these keys. Any
# unexpected key fails the audit (fail-closed shape) - a denylist of known DSP
# names would fail open on the next renamed DSP field.
ALLOWED_CANDIDATE_KEYS = frozenset(
    {
        "source",
        "identity",
        "faceBPM",
        "title",
        "relPath",
        "artist",
        "localPath",
        "filename",
        "subdir",
        "rowId",
        "sequencePosition",
        "contentSha256",
    }
)
ALLOWED_ANNOTATION_KEYS = frozenset(
    {
        "tempo_unstable",
        "irresolvable",
        "ambiguous",
        "audio_defect",
        "verified_bpm",
        "duplicate_of",
    }
)
ALLOWED_ANNOTATION_DOC_KEYS = frozenset({"_meta", "rows"})
ALLOWED_ANNOTATION_META_KEYS = frozenset({"replaced_sha256", "band", "batch"})
# The operator-facing annotation CSV: exactly these columns, no others.
EXPECTED_ANNOTATION_COLUMNS = frozenset(
    {
        "row_id",
        "verified_bpm",
        "tempo_unstable",
        "irresolvable",
        "ambiguous",
        "audio_defect",
        "duplicate_of",
    }
)

DEGENERACY_NOTE_175 = (
    "175+ near-degeneracy (recorded, not re-litigated): 130 of the census band's 140 "
    "tracks sit within 175-179, non-separable from 160-175 at the +/-4 percent Acc1 "
    "tolerance, with three to five genuinely above-180 tracks in the collection "
    "(three-source-band-census-2026-08-01.md finding 2; prd.md FR-59f (a))."
)

ARTIST_LIMITATION_NOTE = (
    "Pool rows carry no artist field, so artist-string FR-59a.2 exclusion is enforceable "
    "only for Tony rows. What compensates is NOT the artist check by another name: the "
    "mandatory pre-commitment fingerprint review covers every candidate against the "
    "training manifests by audio content, and confirmed matches are excluded before "
    "minting. The residual gap is a training track by the same artist that is a "
    "DIFFERENT recording, which artist-string exclusion would have removed and "
    "fingerprinting deliberately does not."
)

LEDGER_INTEGRITY_NOTE = (
    "The annotation ledger provides INTEGRITY, not backup or recovery. It detects "
    "editing, deletion, reordering, and stale-file reuse of annotation state; it cannot "
    "restore a lost annotation, and these labels cannot be regenerated."
)


class HarnessError(RuntimeError):
    """Fatal harness error (exit 1)."""


class DriftError(RuntimeError):
    """Committed inputs or row-level files drifted since commitment (exit 2)."""


class PrivacyError(RuntimeError):
    """Privacy-gate violation in a committed artifact (exit 3, q9 convention)."""


class OperatorHalt(RuntimeError):
    """Escalation the harness must not resolve on its own (exit 4)."""


# ---------------------------------------------------------------------------
# Pure logic: banding
# ---------------------------------------------------------------------------


def band_of(bpm: float | None) -> str | None:
    """Half-open [lo, hi) band for a face-value BPM; None when unbandable."""
    if bpm is None:
        return None
    try:
        v = float(bpm)
    except (TypeError, ValueError):
        return None
    if not math.isfinite(v) or v <= 0.0:
        return None
    for name, lo, hi in BANDS:
        if lo <= v < hi:
            return name
    return None


def _empty_exclusions() -> dict[str, dict[str, int]]:
    return {name: dict.fromkeys(EXCLUSION_REASONS, 0) for name in BAND_NAMES}


# ---------------------------------------------------------------------------
# Pure logic: candidate construction + FR-59a.2 metadata exclusion
# ---------------------------------------------------------------------------


def build_candidates(
    pool_rows: list[dict],
    tony_rows: list[dict],
    oa300_rows: list[dict],
    manifest_hashes: set[str],
    tony_split_ids: set[str],
    training_artist_keys: set[str],
) -> tuple[dict[str, list[dict]], dict[str, Any]]:
    """Band candidates by face-value tag only; exclude FR-59a.2 metadata matches.

    Returns (bands, accounting). No DSP quantity is read: pool rows contribute
    ONLY `fileMetadataBPM` + identity fields, Tony rows ONLY `average_bpm`
    as-entered + identity, OA300 ONLY the fixture value + identity. The
    fingerprint route (signed section 2) runs as a separate, mandatory
    pre-commitment review stage; see `prepare-review` and `apply_dispositions`.
    """
    bands: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    tagless = {"pool": 0, "tony": 0, "oa300": 0}
    exclusions = _empty_exclusions()

    for row in pool_rows:
        face = row.get("fileMetadataBPM")
        band = band_of(face)
        if band is None:
            tagless["pool"] += 1
            continue
        if str(row.get("audioHash", "")) in manifest_hashes:
            exclusions[band]["manifest-hash"] += 1
            continue
        bands[band].append(
            {
                "source": "pool",
                "identity": str(row["audioHash"]),
                "faceBPM": float(face or 0.0),
                "title": Path(str(row.get("path", ""))).stem,
                "relPath": str(row.get("path", "")),
            }
        )

    for row in tony_rows:
        face = row.get("average_bpm")
        band = band_of(face)
        if band is None:
            tagless["tony"] += 1
            continue
        track_id = str(row.get("track_id", ""))
        if track_id in tony_split_ids:
            exclusions[band]["tony-split"] += 1
            continue
        artist_key = cc.canonical_artist_key(row.get("artist"))
        if artist_key and artist_key in training_artist_keys:
            exclusions[band]["artist"] += 1
            continue
        local_path = row.get("local_path")
        if not local_path:
            # A row whose audio cannot be resolved can never be staged, blinded,
            # or annotated; it is excluded at construction with the count
            # recorded rather than deadlocking a batch later (intactness
            # precondition of the keep criteria, applied at the only point the
            # information exists without consulting any DSP quantity).
            exclusions[band]["audio-unresolved"] += 1
            continue
        bands[band].append(
            {
                "source": "tony",
                "identity": track_id,
                "faceBPM": float(face or 0.0),
                "title": str(row.get("name", "")),
                "artist": str(row.get("artist", "")),
                "localPath": str(local_path),
            }
        )

    for row in oa300_rows:
        face = row.get("bpm")
        band = band_of(face)
        if band is None:
            tagless["oa300"] += 1
            continue
        bands[band].append(
            {
                "source": "oa300",
                "identity": str(row.get("filename", "")),
                "faceBPM": float(face or 0.0),
                "title": str(row.get("title") or row.get("filename", "")),
                "filename": str(row.get("filename", "")),
                "subdir": row.get("subdir"),
            }
        )

    accounting = {
        "tagless": tagless,
        "exclusions": exclusions,
        "artist_limitation": ARTIST_LIMITATION_NOTE,
    }
    return bands, accounting


def candidate_universe_digest(bands: dict[str, list[dict]]) -> str:
    """Digest over the banded candidate universe (source + identity + band).

    Binds a fingerprint disposition set to the exact universe it adjudicated, so
    a Phase-2 allocation change cannot silently reuse stale adjudications.
    """
    rows = sorted(
        f"{name}|{entry['source']}|{entry['identity']}"
        for name in BAND_NAMES
        for entry in bands[name]
    )
    return sha256_bytes(_json_bytes({"universe": rows}))


# ---------------------------------------------------------------------------
# Content binding (finding 3): every candidate row carries a byte digest of the
# audio it names, so identity is content-bound for Tony (track_id) and OA300
# (filename) rows as well as pool rows.
# ---------------------------------------------------------------------------


def bind_content_hashes(
    bands: dict[str, list[dict]],
    exclusions: dict[str, dict[str, int]],
    resolver: Callable[[dict], Path | None],
    hasher: Callable[[Path], str | None],
) -> dict[str, list[dict]]:
    """Attach `contentSha256` to every row; drop rows whose audio cannot be
    hashed, counting them as `audio-unhashable`."""
    out: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    for name in BAND_NAMES:
        for entry in bands[name]:
            path = resolver(entry)
            digest = hasher(path) if path is not None else None
            if digest is None:
                exclusions[name]["audio-unhashable"] += 1
                continue
            bound = dict(entry)
            bound["contentSha256"] = digest
            out[name].append(bound)
    return out


def dedup_across_bands(
    bands: dict[str, list[dict]],
    exclusions: dict[str, dict[str, int]],
    band_priority: list[str],
    recording_groups: dict[str, str],
) -> dict[str, list[dict]]:
    """Cross-band recording-level dedup (finding 12, operator policy
    `pre-commitment-recording-dedup`). A recording appearing in two bands - the
    collection's dominant half-vs-full-tempo pattern - is kept only in the
    highest-priority band. Recording key = the confirmed fingerprint group where
    one exists, else the audio byte digest."""
    unknown = [b for b in band_priority if b not in BAND_NAMES]
    if unknown or sorted(band_priority) != sorted(BAND_NAMES):
        raise HarnessError(
            f"band_priority must be a permutation of {BAND_NAMES}, got {band_priority}"
        )
    out: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    seen: set[str] = set()
    for name in band_priority:
        for entry in bands[name]:
            key = recording_groups.get(
                f"{entry['source']}:{entry['identity']}", entry.get("contentSha256", "")
            )
            if key and key in seen:
                exclusions[name]["cross-band-duplicate"] += 1
                continue
            if key:
                seen.add(key)
            out[name].append(entry)
    return out


# ---------------------------------------------------------------------------
# Pure logic: seeded draw sequences + position-independent opaque row IDs
# ---------------------------------------------------------------------------


def draw_sequence(band_index: int, rows: list[dict], seed: int) -> list[dict]:
    """One global per-band permutation from `random.Random(seed)`.

    Row IDs are `e<band-index>-<12 hex>` minted from the same PRNG. The ID
    carries NO draw position (finding 16): a position-encoding ID plus a
    sequence-ordered worklist told an annotator who knows the first-43 rule
    which rows were likely members. `sequencePosition` stays in the gitignored
    row-level pool, which is never annotator-facing.
    """
    ordered = sorted(rows, key=lambda r: (r["source"], r["identity"]))
    rng = random.Random(seed)
    rng.shuffle(ordered)
    out = []
    used: set[str] = set()
    for pos, row in enumerate(ordered):
        while True:
            row_id = f"e{band_index}-{rng.getrandbits(48):012x}"
            if row_id not in used:
                break
        used.add(row_id)
        entry = dict(row)
        entry["rowId"] = row_id
        entry["sequencePosition"] = pos
        out.append(entry)
    return out


def work_order(row_ids: list[str], seed: int) -> list[str]:
    """Randomized within-batch annotation order (signed protocol step 2b permits
    ANY within-batch order; randomizing costs nothing and removes the draw-order
    signal from the annotator's worklist)."""
    order = list(row_ids)
    random.Random(seed).shuffle(order)
    return order


# ---------------------------------------------------------------------------
# Pure logic: keep/reject + first-43-cumulative membership
# ---------------------------------------------------------------------------


def keep_or_reject(annotation: dict, band: str) -> tuple[bool, str | None]:
    """Precommitted DSP-free keep/reject (signed protocol). Returns
    (keep, reject_reason). Reads ONLY annotator-entered fields."""

    def flag(name: str) -> bool:
        return bool(annotation.get(name))

    if flag("tempo_unstable"):
        return False, "tempo-unstable"
    if flag("irresolvable"):
        return False, "metrically-irresolvable"
    if flag("audio_defect"):
        return False, "audio-defect"
    bpm = annotation.get("verified_bpm")
    if bpm is None:
        return False, "no-verified-tempo"
    try:
        bpm_value = float(bpm)
    except (TypeError, ValueError) as exc:
        raise HarnessError(f"stored verified_bpm is non-numeric: {bpm!r}") from exc
    if band_of(bpm_value) != band:
        # Rejected from its band, never reassigned; verified tempo retained.
        return False, "out-of-band"
    return True, None


def compute_membership(
    sequence: list[dict],
    annotations: dict[str, dict],
    band: str,
    n_band: int = N_BAND,
) -> dict[str, Any]:
    """First `n_band` keepers in draw-sequence order, cumulative across batches;
    surplus keepers recorded; duplicate tie-break by sequence position.

    Duplicate suppression registers a row ONLY after it survives keep/reject
    including duplicate resolution (finding 11). The signed criterion is "not a
    duplicate/re-encode of a track already KEPT", so an earlier audio-defect or
    out-of-band rejection - a property of that file, not of the recording -
    must not suppress a later clean copy. Eventual surplus keepers register too,
    not just the final 43, so consecutive-span batching still lets an earlier
    eligible keeper suppress its later duplicate. Reads ONLY the draw sequence
    and annotator-entered fields - no DSP quantity.
    """
    keepers: list[str] = []
    rejects: dict[str, dict] = {}
    kept_identities: set[str] = set()
    kept_row_ids: set[str] = set()
    kept_dup_groups: set[str] = set()
    for entry in sequence:  # sequence order IS the tie-break order
        row_id = entry["rowId"]
        ann = annotations.get(row_id)
        if ann is None:
            continue
        keep, reason = keep_or_reject(ann, band)
        dup_group = str(ann.get("duplicate_of") or "").strip()
        if keep:
            # Bidirectional: whichever side carries the tag, the earlier KEPT
            # sequence position wins.
            dup_hit = bool(dup_group) and (
                dup_group in kept_row_ids or dup_group in kept_dup_groups
            )
            if entry["identity"] in kept_identities or dup_hit or row_id in kept_dup_groups:
                keep, reason = False, "duplicate"
        if keep:
            kept_identities.add(entry["identity"])
            kept_row_ids.add(row_id)
            if dup_group:
                kept_dup_groups.add(dup_group)
            keepers.append(row_id)
            continue
        record: dict[str, Any] = {"reason": reason}
        if ann.get("verified_bpm") is not None:
            record["verified_bpm"] = float(ann["verified_bpm"])  # retained as data
        if ann.get("ambiguous"):
            record["ambiguous"] = True
        rejects[row_id] = record
    return {
        "members": keepers[:n_band],
        "surplus": keepers[n_band:],
        "rejects": rejects,
        "annotated": len(annotations),
    }


# ---------------------------------------------------------------------------
# Pure logic: octave-sentinel rule (section 3)
# ---------------------------------------------------------------------------


def is_octave_sentinel(verified_bpm: float, legacy_labels: list[float]) -> bool:
    """Two-directional [80, 87.5) / [160, 175) rule against FR-59a.1-clean
    legacy labels (OA300 fixture values or as-entered tags) for the same
    recording. Half-open windows; no DSP quantity participates."""

    def in_window(v: float, window: tuple[float, float]) -> bool:
        return window[0] <= v < window[1]

    if in_window(verified_bpm, SENTINEL_FULL):
        return any(in_window(x, SENTINEL_HALF) for x in legacy_labels)
    if in_window(verified_bpm, SENTINEL_HALF):
        return any(in_window(x, SENTINEL_FULL) for x in legacy_labels)
    return False


# ---------------------------------------------------------------------------
# Fingerprint seam (injectable so tests never decode audio)
# ---------------------------------------------------------------------------


_FP_MEMO: dict[str, list[float] | None] = {}
_FP_DISK_CACHE: dict[str, list[float]] | None = None
_FP_DISK_DIRTY = False


def _load_fingerprint_cache() -> dict[str, list[float]]:
    """The method-versioned npz cache `scripts/audit-corpus-splits.py` maintains.

    Reusing it matters: the Phase-2 review fingerprints every candidate AND every
    training row, which is thousands of decodes. A method change invalidates the
    stale vectors, exactly as in the audit. Absent numpy or an unreadable cache
    degrades to recomputation, never to a silently empty flag set.
    """
    global _FP_DISK_CACHE
    if _FP_DISK_CACHE is not None:
        return _FP_DISK_CACHE
    cache: dict[str, list[float]] = {}
    try:
        import numpy as np  # noqa: PLC0415  (optional persistence path)

        if cc.FINGERPRINT_CACHE.exists():
            z = np.load(cc.FINGERPRINT_CACHE, allow_pickle=True)
            if "__method__" in z.files and str(z["__method__"]) == cc.FINGERPRINT_METHOD:
                for key in z.files:
                    if key == "__method__":
                        continue
                    vec = z[key]
                    if np.all(np.isfinite(vec)):
                        cache[key] = [float(x) for x in vec]
    except (ImportError, OSError, ValueError):
        cache = {}
    _FP_DISK_CACHE = cache
    return cache


def flush_fingerprint_cache() -> None:
    global _FP_DISK_DIRTY
    if not _FP_DISK_DIRTY or _FP_DISK_CACHE is None:
        return
    try:
        import numpy as np  # noqa: PLC0415  (optional persistence path)

        cc.FINGERPRINT_CACHE.parent.mkdir(parents=True, exist_ok=True)
        np.savez_compressed(
            cc.FINGERPRINT_CACHE,
            __method__=cc.FINGERPRINT_METHOD,
            **{k: np.asarray(v, dtype="float32") for k, v in _FP_DISK_CACHE.items()},
        )
    except (ImportError, OSError, ValueError):
        return
    _FP_DISK_DIRTY = False


def _default_fingerprint(path: str) -> list[float] | None:
    global _FP_DISK_DIRTY
    if path in _FP_MEMO:
        return _FP_MEMO[path]
    cache = _load_fingerprint_cache()
    key = cc.content_hash(path)
    if key in cache:
        _FP_MEMO[path] = cache[key]
        return cache[key]
    vec = cc.compute_fingerprint(path)
    result = None if vec is None else [float(x) for x in vec]
    if result is not None:
        cache[key] = result
        _FP_DISK_DIRTY = True
    _FP_MEMO[path] = result
    return result


FINGERPRINT_FN: Callable[[str], list[float] | None] = _default_fingerprint
FINGERPRINT_METHOD = cc.FINGERPRINT_METHOD


MIN_STANDARDIZATION_COHORT = 3


def cohort_stats(vectors: list[list[float]]) -> dict[int, tuple[list[float], list[float]]]:
    """Per-dimension mean and standard deviation, grouped by vector length.

    `scripts/audit-corpus-splits.py` standardizes across the cohort before
    cosine and `corpus_common` explains why: raw timbral vectors are
    near-degenerate, and an earlier signature scored cosine ~1.0 between
    unrelated dense electronic tracks. Comparing raw vectors would flag most of
    the corpus. A group smaller than MIN_STANDARDIZATION_COHORT cannot estimate
    per-dimension scale, so it is left raw rather than centred to zero.
    """
    groups: dict[int, list[list[float]]] = {}
    for vec in vectors:
        groups.setdefault(len(vec), []).append(vec)
    stats: dict[int, tuple[list[float], list[float]]] = {}
    for dim, group in groups.items():
        if dim == 0 or len(group) < MIN_STANDARDIZATION_COHORT:
            continue
        n = len(group)
        means = [sum(v[i] for v in group) / n for i in range(dim)]
        sds = []
        for i in range(dim):
            var = sum((v[i] - means[i]) ** 2 for v in group) / n
            sd = math.sqrt(var)
            sds.append(sd if sd > 1e-9 else 1.0)
        stats[dim] = (means, sds)
    return stats


def standardize(vec: list[float], stats: dict[int, tuple[list[float], list[float]]]) -> list[float]:
    entry = stats.get(len(vec))
    if entry is None:
        return vec
    means, sds = entry
    return [(vec[i] - means[i]) / sds[i] for i in range(len(vec))]


def cosine(a: list[float], b: list[float]) -> float:
    """Plain cosine over two equal-length vectors; 0.0 when either is degenerate."""
    if len(a) != len(b) or not a:
        return 0.0
    dot = sum(x * y for x, y in zip(a, b, strict=True))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na < 1e-12 or nb < 1e-12:
        return 0.0
    return dot / (na * nb)


def flag_id(kind: str, left: str, right: str) -> str:
    """Content-derived, stable review-flag identifier."""
    return hashlib.sha256(f"{kind}|{left}|{right}".encode()).hexdigest()[:16]


# ---------------------------------------------------------------------------
# Privacy gate (q9 recursive-allowlist precedent; exit code 3)
# ---------------------------------------------------------------------------

# Path ROOTS are forbidden at ANY string length; bare slashes only in short
# label-like strings (prose legitimately contains slashes).
_FORBIDDEN_ROOTS = ("~", "$HOME", "Users/", "Volumes/")
_FORBIDDEN_SLASHES = ("/", "\\")
# An extension counts wherever it appears followed by a non-alphanumeric or the
# end of string (".mp3.bak", "x.mp3, y.wav" all leak), not only at the end.
_AUDIO_EXT_RE = re.compile(r"\.(?:mp3|wav|m4a|flac|aiff|aif|ogg|caf)(?:$|[^a-z0-9])", re.IGNORECASE)
_HEX = set("0123456789abcdef")
# The sole permitted hashes: the named digests of committed artifacts.
_DIGEST_PATHS = frozenset(
    {
        "/pool_file_sha256",
        "/draw_file_sha256",
        "/head_sha256",
        "/commitment_sha256",
        "/annotation_ledger_head",
        "/attestation_sha256",
        "/fingerprint_review/dispositions_sha256",
        "/fingerprint_review/candidate_universe_sha256",
        "/fingerprint_review/training_input_sha256",
        "/operator_decisions/decisions_sha256",
    }
)
_PATH_EXEMPT = frozenset({"/protocol", "/seed_algorithm", "/run_command"})


def _looks_like_hash(text: str) -> bool:
    stripped = text.strip().lower()
    return len(stripped) >= 32 and all(ch in _HEX for ch in stripped)


def privacy_gate(doc: dict) -> None:
    """Recursive value screen over a committed artifact: counts, seeds, band
    names, prose notes, and the named digests only. Raises PrivacyError on any
    row-level path, audio filename, or stray hash.

    This is DEFENSE IN DEPTH, not the contract. The contract is the exact key
    schema asserted by `assert_commitment_schema` and its siblings: a
    pattern-only gate accepts arbitrary keys and screens only string values, so
    a track title would pass it (finding 15).
    """

    def walk(node: object, path: str) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                if not isinstance(key, str):
                    raise PrivacyError(f"non-string key at {path}")
                walk(value, f"{path}/{key}")
        elif isinstance(node, list):
            for i, value in enumerate(node):
                walk(value, f"{path}/{i}")
        elif isinstance(node, str):
            if path in _DIGEST_PATHS:
                if len(node) != 64 or not all(ch in _HEX for ch in node):
                    raise PrivacyError(f"{path} is not 64 lowercase hex")
                return
            if path in _PATH_EXEMPT:
                return
            if _AUDIO_EXT_RE.search(node):
                raise PrivacyError(f"audio extension leaked at {path}")
            if _looks_like_hash(node):
                raise PrivacyError(f"unexpected hash-shaped string at {path}")
            if any(bad in node for bad in _FORBIDDEN_ROOTS):
                raise PrivacyError(f"path root at {path}: {node!r}")
            if len(node) < 60 and any(bad in node for bad in _FORBIDDEN_SLASHES):
                raise PrivacyError(f"path-like label at {path}: {node!r}")

    walk(doc, "")


_COMMITMENT_COMMON_KEYS = frozenset(
    {
        "schema_version",
        "story",
        "status",
        "generated",
        "protocol",
        "run_command",
        "seed_algorithm",
        "master_seed",
        "n_band_target",
        "bands",
        "tagless_by_source",
        "artist_exclusion_limitation",
        "pool_file_sha256",
        "draw_file_sha256",
        "short_bands",
    }
)
_COMMITMENT_ACTIVE_KEYS = frozenset({"fingerprint_review", "operator_decisions", "notes"})
_COMMITMENT_SUPERSEDED_KEYS = frozenset({"superseded_note"})
_COMMITMENT_BAND_KEYS = frozenset({"candidates", "seed", "exclusions"})
_FINGERPRINT_REVIEW_KEYS = frozenset(
    {
        "method",
        "flags",
        "confirmed_same_recording",
        "cleared",
        "dispositions_sha256",
        "candidate_universe_sha256",
        "training_input_sha256",
    }
)
_OPERATOR_DECISIONS_KEYS = frozenset(
    {"decisions_sha256", "decided", "short_band_allocation", "cross_band_duplicate_rule"}
)


def _assert_keys(
    node: object, allowed: frozenset[str], where: str, allow_missing: bool = False
) -> dict:
    if not isinstance(node, dict):
        raise PrivacyError(f"{where}: expected an object, got {type(node).__name__}")
    keys = set(node)
    unexpected = sorted(keys - allowed)
    missing = [] if allow_missing else sorted(allowed - keys)
    if unexpected or missing:
        raise PrivacyError(
            f"{where}: key-schema violation - unexpected {unexpected}, missing {missing}"
        )
    return node


def assert_commitment_schema(doc: dict) -> None:
    """Exact key schema of the machine-generated commitment JSON (finding 15)."""
    if not isinstance(doc, dict):
        raise PrivacyError("commitment: expected an object")
    status = doc.get("status")
    if status not in (STATUS_ACTIVE, STATUS_SUPERSEDED):
        raise PrivacyError(f"commitment: status must be active or superseded, got {status!r}")
    extra = _COMMITMENT_ACTIVE_KEYS if status == STATUS_ACTIVE else _COMMITMENT_SUPERSEDED_KEYS
    _assert_keys(doc, _COMMITMENT_COMMON_KEYS | extra, "commitment")
    bands = _assert_keys(doc["bands"], frozenset(BAND_NAMES), "commitment/bands")
    for name, band in bands.items():
        _assert_keys(band, _COMMITMENT_BAND_KEYS, f"commitment/bands/{name}")
        # A superseded record is a historical artifact of an earlier mint whose
        # exclusion routes were a strict subset of today's; its exclusion keys
        # may be missing but never unexpected. Zero-filling them would claim the
        # fingerprint route ran and confirmed nothing, which is the dishonesty
        # finding 6 is about.
        _assert_keys(
            band["exclusions"],
            frozenset(EXCLUSION_REASONS),
            f"commitment/bands/{name}/exclusions",
            allow_missing=status == STATUS_SUPERSEDED,
        )
        for key in ("candidates", "seed"):
            if not isinstance(band[key], int):
                raise PrivacyError(f"commitment/bands/{name}/{key} must be an integer")
    _assert_keys(
        doc["tagless_by_source"],
        frozenset({"pool", "tony", "oa300"}),
        "commitment/tagless_by_source",
    )
    if status == STATUS_ACTIVE:
        _assert_keys(
            doc["fingerprint_review"], _FINGERPRINT_REVIEW_KEYS, "commitment/fingerprint_review"
        )
        _assert_keys(
            doc["operator_decisions"], _OPERATOR_DECISIONS_KEYS, "commitment/operator_decisions"
        )
    for name in ("short_bands", *(("notes",) if status == STATUS_ACTIVE else ())):
        if not isinstance(doc[name], list) or any(not isinstance(x, str) for x in doc[name]):
            raise PrivacyError(f"commitment/{name} must be a list of strings")


_LEDGER_HEAD_KEYS = frozenset(
    {"schema_version", "story", "head_sha256", "event_count", "commitment_sha256", "bands", "note"}
)
_ATTESTATION_KEYS = frozenset(
    {
        "schema_version",
        "story",
        "attested",
        "commitment_sha256",
        "annotation_ledger_head",
        "audit_result",
        "members_per_band",
        "attestation_sha256",
    }
)


def assert_ledger_head_schema(doc: dict) -> None:
    _assert_keys(doc, _LEDGER_HEAD_KEYS, "ledger-head")
    _assert_keys(doc["bands"], frozenset(BAND_NAMES), "ledger-head/bands")


def assert_attestation_schema(doc: dict) -> None:
    _assert_keys(doc, _ATTESTATION_KEYS, "attestation")
    _assert_keys(doc["members_per_band"], frozenset(BAND_NAMES), "attestation/members_per_band")


def gate_committed(doc: dict, schema: Callable[[dict], None]) -> None:
    schema(doc)
    privacy_gate(doc)


# ---------------------------------------------------------------------------
# Digests + IO helpers
# ---------------------------------------------------------------------------


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _safe_sha256_file(path: Path) -> str | None:
    try:
        return sha256_file(path)
    except OSError:
        return None


def _json_bytes(doc: dict) -> bytes:
    """The canonical serialization every JSON write (and digest) uses."""
    return (json.dumps(doc, indent=1, sort_keys=True) + "\n").encode("utf-8")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _write_bytes_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def _write_json(path: Path, doc: dict) -> None:
    _write_bytes_atomic(path, _json_bytes(doc))


def _write_text_atomic(path: Path, text: str) -> None:
    _write_bytes_atomic(path, text.encode("utf-8"))


def _read_json(path: Path, what: str) -> Any:
    if not path.exists():
        raise HarnessError(f"{what} not found at {path} - HALT (missing input, no degrade)")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise HarnessError(f"{what} at {path} is not valid JSON: {exc}") from exc


def _require(doc: dict, key: str, what: str) -> Any:
    if not isinstance(doc, dict) or key not in doc:
        raise HarnessError(f"{what}: required key {key!r} missing - schema drift, HALT")
    return doc[key]


# ---------------------------------------------------------------------------
# Commitment: status enforcement + drift/tamper verification
# ---------------------------------------------------------------------------


def read_commitment() -> dict:
    return _read_json(COMMITMENT_JSON, "commitment artifact")


def require_active_commitment() -> tuple[dict, str]:
    """Every consumer refuses to operate on a missing or superseded commitment
    (enforced supersession, not documented supersession)."""
    if not COMMITMENT_JSON.exists():
        raise HarnessError(
            "NO ACTIVE COMMITMENT: the candidate commitment artifact is absent. Nothing "
            "may be staged, ingested, audited, emitted, or signed off until "
            "`commit-pools` mints one."
        )
    commitment = read_commitment()
    status = commitment.get("status")
    if status != STATUS_ACTIVE:
        raise HarnessError(
            f"NO ACTIVE COMMITMENT: the commitment on record has status {status!r}. "
            "A superseded commitment can never be operated on - it was minted without "
            "the mandatory pre-commitment fingerprint review, its row IDs leak draw "
            "position, and its Tony/OA300 rows are not content-bound. Re-mint with "
            "`commit-pools` once the two operator decisions and the fingerprint "
            "dispositions are on record."
        )
    return commitment, sha256_file(COMMITMENT_JSON)


def verify_committed_digest(pools_path: Path, draws_path: Path, commitment_json: Path) -> dict:
    """Fail closed: BOTH row-level files must hash to their committed digests."""
    commitment = _read_json(commitment_json, "commitment artifact")
    for path, key in ((pools_path, "pool_file_sha256"), (draws_path, "draw_file_sha256")):
        recorded = _require(commitment, key, "commitment artifact")
        if not path.exists():
            raise HarnessError(
                f"committed row-level file {path.name} is missing; run commit-pools to "
                "restore it from the recorded seed (restore verifies against the "
                "committed digests)"
            )
        actual = sha256_file(path)
        if recorded != actual:
            raise HarnessError(
                f"commitment digest mismatch: committed {key} {recorded} != actual "
                f"{actual} for {path.name}; the row-level file has drifted since "
                "commitment - refusing to proceed"
            )
    return commitment


def verify_input_drift(commitment: dict, pools_doc: dict, draws_doc: dict) -> None:
    """Finding 1: hash the documents REGENERATED FROM TODAY'S INPUTS against the
    recorded digests. Verifying only the on-disk file is a tamper check; without
    this a changed survey or training manifest printed 'commitment verified'."""
    for doc, key, label in (
        (pools_doc, "pool_file_sha256", "candidate pools"),
        (draws_doc, "draw_file_sha256", "draw sequences"),
    ):
        recorded = _require(commitment, key, "commitment artifact")
        regenerated = sha256_bytes(_json_bytes(doc))
        if regenerated != recorded:
            raise DriftError(
                f"INPUT DRIFT: regenerating the {label} document from today's inputs "
                f"hashes to {regenerated}, but the commitment records {key} {recorded}. "
                "A source input (survey, training manifest, splits, or fixture) changed "
                "since commitment. Refusing to proceed; the committed digests are never "
                "rewritten."
            )


# ---------------------------------------------------------------------------
# Operator decisions + fingerprint dispositions (machine-readable gates)
# ---------------------------------------------------------------------------


def load_operator_decisions() -> dict:
    """The two pending operator decisions, supplied as machine-readable input.

    `commit-pools` refuses when the file is absent rather than inferring
    "pending" from prose. The file lives in the gitignored working directory
    because a fallback addendum enumerates row identities.
    """
    if not DECISIONS_PATH.exists():
        raise OperatorHalt(
            "MISSING OPERATOR DECISIONS: "
            f"{DECISIONS_PATH.name} is absent. Two decisions block re-minting:\n"
            "  (a) short-band allocation (finding 18): the precommitted fallback is empty "
            "by construction - Tony and OA300 rows are already in the initial pool and are "
            "also the signed fallback source, so the addendum cannot extend 160-175 or "
            f"175-plus at all. Accepted policies: {list(SHORT_BAND_POLICIES)}.\n"
            "  (b) cross-band duplicate rule (finding 12): the signed tie-break is "
            "'earlier in the membership draw sequence wins', but there is no ordering "
            "BETWEEN two per-band sequences, and the same recording tagged 85 in one "
            "source and 170 in another lands in two bands by construction. Accepted "
            f"policies: {list(CROSS_BAND_POLICIES)}."
        )
    doc = _read_json(DECISIONS_PATH, "operator decisions")
    for key in ("schema_version", "decided", "short_band_allocation", "cross_band_duplicate_rule"):
        _require(doc, key, "operator decisions")
    short = _require(doc["short_band_allocation"], "policy", "short_band_allocation")
    if short not in SHORT_BAND_POLICIES:
        raise HarnessError(
            f"operator decisions: short_band_allocation.policy {short!r} is not one of "
            f"{list(SHORT_BAND_POLICIES)}. A policy the harness does not implement cannot "
            "be recorded as decided."
        )
    if short == "shrink-corpus":
        n = _require(doc["short_band_allocation"], "n_band", "short_band_allocation")
        if not isinstance(n, int) or not 1 <= n <= N_BAND:
            raise HarnessError(f"operator decisions: shrink-corpus n_band must be 1..{N_BAND}")
    cross = _require(doc["cross_band_duplicate_rule"], "policy", "cross_band_duplicate_rule")
    if cross not in CROSS_BAND_POLICIES:
        raise HarnessError(
            f"operator decisions: cross_band_duplicate_rule.policy {cross!r} is not one of "
            f"{list(CROSS_BAND_POLICIES)}"
        )
    if cross == "pre-commitment-recording-dedup":
        prio = _require(
            doc["cross_band_duplicate_rule"], "band_priority", "cross_band_duplicate_rule"
        )
        if sorted(prio) != sorted(BAND_NAMES):
            raise HarnessError(
                f"operator decisions: band_priority must be a permutation of {BAND_NAMES}"
            )
    return doc


def training_input_digest() -> str:
    """Digest over the training inputs a fingerprint disposition adjudicated
    against, so a manifest change invalidates the dispositions."""
    parts = []
    for path in (SECONDARY_MANIFEST, UNSUPERVISED_MANIFEST, CORPUS_SPLITS):
        if not path.exists():
            raise HarnessError(f"training input {path.name} not found - HALT")
        parts.append(f"{path.name}:{sha256_file(path)}")
    return sha256_bytes(_json_bytes({"training_inputs": sorted(parts)}))


def load_dispositions(universe_digest: str, expected_flag_ids: set[str]) -> dict[str, dict]:
    """Fail-closed disposition gate (finding 5). Blocks minting while any
    generated review flag is unadjudicated, and refuses a disposition set bound
    to a different candidate universe, fingerprint method, or training input."""
    if not DISPOSITIONS_PATH.exists():
        raise OperatorHalt(
            "MISSING FINGERPRINT DISPOSITIONS: "
            f"{DISPOSITIONS_PATH.name} is absent. The signed section-2 exclusion route "
            "'by audio fingerprint (scripts/audit-corpus-splits.py precedent)' is "
            "MANDATORY and runs BEFORE commitment. Run `prepare-review` to generate the "
            f"flags plus {DISPOSITIONS_TEMPLATE_PATH.name}, record a human disposition for "
            "every flag, and save it as the dispositions file. The algorithm is advisory; "
            "the recorded human disposition is what excludes."
        )
    doc = _read_json(DISPOSITIONS_PATH, "fingerprint dispositions")
    recorded_universe = _require(doc, "candidate_universe_sha256", "fingerprint dispositions")
    if recorded_universe != universe_digest:
        raise DriftError(
            "fingerprint dispositions are bound to candidate universe "
            f"{recorded_universe}, but today's universe is {universe_digest}. Stale "
            "adjudications cannot carry across a changed candidate universe; re-run "
            "`prepare-review`."
        )
    recorded_method = _require(doc, "fingerprint_method", "fingerprint dispositions")
    if recorded_method != FINGERPRINT_METHOD:
        raise DriftError(
            f"fingerprint dispositions were recorded under method {recorded_method!r}, "
            f"current method is {FINGERPRINT_METHOD!r}"
        )
    recorded_training = _require(doc, "training_input_sha256", "fingerprint dispositions")
    actual_training = training_input_digest()
    if recorded_training != actual_training:
        raise DriftError(
            "fingerprint dispositions are bound to training inputs "
            f"{recorded_training}, but today's training inputs hash to {actual_training}"
        )
    by_id: dict[str, dict] = {}
    for row in _require(doc, "flags", "fingerprint dispositions"):
        fid = _require(row, "flag_id", "fingerprint disposition row")
        disp = row.get("disposition")
        if disp not in DISPOSITION_VALUES:
            raise OperatorHalt(
                f"UNRESOLVED FINGERPRINT DISPOSITION: flag {fid} carries "
                f"disposition {disp!r}; every flag needs one of {list(DISPOSITION_VALUES)} "
                "before a mint may proceed."
            )
        by_id[fid] = row
    missing = sorted(expected_flag_ids - set(by_id))
    stale = sorted(set(by_id) - expected_flag_ids)
    if missing or stale:
        raise OperatorHalt(
            f"FINGERPRINT DISPOSITION SET MISMATCH: {len(missing)} generated flag(s) have "
            f"no recorded disposition ({missing[:5]}), {len(stale)} recorded disposition(s) "
            f"match no current flag ({stale[:5]}). Re-run `prepare-review` and adjudicate "
            "the current flag set."
        )
    return by_id


def apply_dispositions(
    bands: dict[str, list[dict]],
    exclusions: dict[str, dict[str, int]],
    dispositions: dict[str, dict],
    flags: list[dict],
) -> tuple[dict[str, list[dict]], dict[str, str], int]:
    """Apply the recorded human dispositions.

    A confirmed training-fingerprint or GiantSteps-title flag EXCLUDES its
    candidate. A confirmed cross-band-recording flag excludes nothing; it
    supplies the recording group both sides share, which is what the operator's
    `pre-commitment-recording-dedup` policy collapses on. Returns
    (bands, recording_groups, confirmed)."""
    confirmed_keys: set[str] = set()
    recording_groups: dict[str, str] = {}
    for flag in flags:
        disp = dispositions.get(flag["flag_id"], {})
        if disp.get("disposition") != DISPOSITION_SAME:
            continue
        group = str(disp.get("recording_group") or flag["flag_id"])
        recording_groups[flag["candidate_key"]] = group
        if flag.get("peer_key"):
            recording_groups[str(flag["peer_key"])] = group
        if flag["kind"] in (FLAG_KIND_FINGERPRINT, FLAG_KIND_GIANTSTEPS):
            confirmed_keys.add(flag["candidate_key"])
    out: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    confirmed = 0
    for name in BAND_NAMES:
        for entry in bands[name]:
            key = f"{entry['source']}:{entry['identity']}"
            if key in confirmed_keys:
                exclusions[name]["fingerprint-confirmed"] += 1
                confirmed += 1
                continue
            out[name].append(entry)
    return out, recording_groups, confirmed


# ---------------------------------------------------------------------------
# Input loading (HALT on missing / schema drift)
# ---------------------------------------------------------------------------


def load_inputs() -> dict[str, Any]:
    survey = _read_json(SURVEY_PATH, "non-rekordbox survey (gitignored, develop-only)")
    if not isinstance(survey, dict) or "tracks" not in survey:
        raise HarnessError(f"{SURVEY_PATH.name}: schema drift - expected dict with 'tracks'")
    tony = _read_json(TONY_SURVEY_PATH, "tony survey")
    if not isinstance(tony, dict) or "tracks" not in tony:
        raise HarnessError(f"{TONY_SURVEY_PATH.name}: schema drift - expected dict with 'tracks'")
    from jams_corpus import load_oa300_rows  # noqa: PLC0415  (stdlib-only module)

    oa300_rows = load_oa300_rows(OA300_GT_PATH)
    if len(oa300_rows) != 82:
        raise HarnessError(f"oa300 fixture: expected 82 rows, found {len(oa300_rows)}")

    manifest_hashes: set[str] = set()
    manifest_paths: dict[str, str] = {}
    for path, key in (
        (SECONDARY_MANIFEST, "secondarySupervised"),
        (UNSUPERVISED_MANIFEST, "unsupervisedPool"),
    ):
        doc = _read_json(path, f"training manifest {path.name}")
        rows = doc.get(key)
        if not isinstance(rows, list) or not rows:
            raise HarnessError(f"{path.name}: schema drift - expected non-empty list at '{key}'")
        for r in rows:
            manifest_hashes.add(str(r["audioHash"]))
            if r.get("path"):
                manifest_paths[str(r["audioHash"])] = str(r["path"])

    splits = _read_json(CORPUS_SPLITS, "corpus_splits.json")
    tony_ns = splits.get("tony")
    if not isinstance(tony_ns, dict) or "train" not in tony_ns or "val" not in tony_ns:
        raise HarnessError("corpus_splits.json: schema drift - expected tony.train/tony.val")
    tony_split_ids = {str(t) for t in tony_ns["train"]} | {str(t) for t in tony_ns["val"]}

    by_id = {str(r.get("track_id")): r for r in tony["tracks"]}
    training_artist_keys = set()
    training_local_paths: dict[str, str] = {}
    for tid in tony_split_ids:
        row = by_id.get(tid)
        if row is not None:
            key = cc.canonical_artist_key(row.get("artist"))
            if key:
                training_artist_keys.add(key)
            if row.get("local_path"):
                training_local_paths[tid] = str(row["local_path"])

    return {
        "pool_rows": survey["tracks"],
        "pool_audio_root": survey.get("audio_root"),
        "tony_rows": tony["tracks"],
        "oa300_rows": oa300_rows,
        "manifest_hashes": manifest_hashes,
        "manifest_paths": manifest_paths,
        "tony_split_ids": tony_split_ids,
        "training_artist_keys": training_artist_keys,
        "training_local_paths": training_local_paths,
    }


def build_universe(inputs: dict) -> tuple[dict[str, list[dict]], dict[str, Any]]:
    return build_candidates(
        inputs["pool_rows"],
        inputs["tony_rows"],
        inputs["oa300_rows"],
        inputs["manifest_hashes"],
        inputs["tony_split_ids"],
        inputs["training_artist_keys"],
    )


# ---------------------------------------------------------------------------
# Audio resolution + content-verified staging
# ---------------------------------------------------------------------------


def _resolve_audio(entry: dict, pool_audio_root: str | None) -> Path:
    src = entry["source"]
    if src == "pool":
        if not pool_audio_root:
            raise HarnessError("pool audio_root missing from committed pools file")
        return Path(pool_audio_root) / entry["relPath"]
    if src == "tony":
        return Path(entry["localPath"])
    corpus_root = os.environ.get("OA300_CORPUS_PATH")
    if not corpus_root:
        raise HarnessError("OA300_CORPUS_PATH not set; cannot resolve an oa300 row")
    base = Path(corpus_root) / "corpus"
    subdir = entry.get("subdir")
    candidates = [base / subdir / entry["filename"]] if subdir else []
    candidates.append(base / entry["filename"])
    for c in candidates:
        if c.exists():
            return c
    hits = list(base.rglob(entry["filename"]))
    if len(hits) == 1:
        return hits[0]
    raise HarnessError(
        f"cannot resolve oa300 audio for row {entry.get('rowId', entry['identity'])}"
    )


def _safe_resolve(entry: dict, pool_audio_root: str | None) -> Path | None:
    try:
        path = _resolve_audio(entry, pool_audio_root)
    except HarnessError:
        return None
    return path if path.exists() else None


def _stage_copies(
    span: list[dict], stage_dir: Path, pool_audio_root: str | None, order: list[str]
) -> list[tuple[str, str]]:
    """Copy audio as blinded, opaque-ID-named copies, CONTENT-verified.

    A source that does not hash to the row's committed `contentSha256` is a hard
    failure (finding 4): the pre-rework size comparison passed an equal-size
    substitution and silently recopied it as a 'refresh'. Worklist rows come
    back in the randomized within-batch work order.
    """
    stage_dir.mkdir(parents=True, exist_ok=True)
    by_row_id = {e["rowId"]: e for e in span}
    staged: dict[str, str] = {}
    for entry in span:
        committed = entry.get("contentSha256")
        if not committed:
            raise HarnessError(
                f"row {entry['rowId']} carries no contentSha256; the commitment is not "
                "content-bound and cannot be staged"
            )
        src_path = _resolve_audio(entry, pool_audio_root)
        if not src_path.exists():
            raise HarnessError(f"audio missing for row {entry['rowId']}: cannot stage blinded copy")
        actual = sha256_file(src_path)
        if actual != committed:
            raise HarnessError(
                f"CONTENT MISMATCH for row {entry['rowId']}: the source audio hashes to "
                f"{actual}, the commitment records {committed}. The file was replaced or "
                "edited since commitment - refusing to stage (a substituted file of equal "
                "size is exactly what a size check misses)."
            )
        dest = stage_dir / f"{entry['rowId']}{src_path.suffix.lower()}"
        if not dest.exists() or sha256_file(dest) != committed:
            shutil.copyfile(src_path, dest)
        staged[entry["rowId"]] = str(dest)
    return [(rid, staged[rid]) for rid in order if rid in by_row_id]


def _write_worklist(path: Path, rows: list[tuple[str, str]]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["row_id", "audio"])  # opaque ID + staged copy ONLY
        writer.writerows(rows)


# ---------------------------------------------------------------------------
# Canonical batch-record validator (finding 9) - used by EVERY consumer
# ---------------------------------------------------------------------------

_BATCH_RECORD_KEYS = ("band", "batch", "size", "start", "rowIds", "work_order_seed", "work_order")


def validate_batch_records(band: str, sequence_row_ids: list[str]) -> list[dict]:
    """Validate every batch record for a band against the committed sequence.

    Checks filename index, band, batch index, start, size, the EXACT sequence
    slice, the work-order permutation, and a contiguous 0..n-1 prefix. Deriving
    `start` from prior record lengths alone (the pre-rework behaviour) trusted
    whatever row IDs a record happened to carry.
    """
    band_dir = BATCHES_DIR / band
    if not band_dir.exists():
        return []
    files: dict[int, Path] = {}
    for p in band_dir.glob("batch-*.json"):
        m = re.fullmatch(r"batch-(\d{3})\.json", p.name)
        if m:
            files[int(m.group(1))] = p
    indices = sorted(files)
    if indices != list(range(len(indices))):
        raise HarnessError(
            f"batch records for {band} are not a contiguous 0..n-1 prefix: {indices} - a "
            "record is missing or misnamed; restore it before proceeding"
        )
    records: list[dict] = []
    start = 0
    for i in indices:
        path = files[i]
        rec = _read_json(path, "batch record")
        for key in _BATCH_RECORD_KEYS:
            _require(rec, key, f"batch record {path.name}")
        if rec["band"] != band:
            raise HarnessError(f"batch record {path.name}: band {rec['band']!r} != {band!r}")
        if int(rec["batch"]) != i:
            raise HarnessError(
                f"batch record {path.name}: recorded batch index {rec['batch']} does not "
                "match the filename index"
            )
        row_ids = list(rec["rowIds"])
        if int(rec["size"]) != len(row_ids):
            raise HarnessError(
                f"batch record {path.name}: size {rec['size']} != {len(row_ids)} row ids"
            )
        if int(rec["start"]) != start:
            raise HarnessError(
                f"batch record {path.name}: start {rec['start']} != the cumulative "
                f"consecutive-span start {start}"
            )
        expected = sequence_row_ids[start : start + len(row_ids)]
        if row_ids != expected:
            raise HarnessError(
                f"batch record {path.name}: rowIds are not the committed draw-sequence "
                f"slice [{start}:{start + len(row_ids)}] - the batch was tampered with or "
                "reordered"
            )
        if sorted(rec["work_order"]) != sorted(row_ids):
            raise HarnessError(
                f"batch record {path.name}: work_order is not a permutation of rowIds"
            )
        records.append(rec)
        start += len(row_ids)
    return records


def _sequence_row_ids(pools: dict, band: str) -> list[str]:
    seq = _require(_require(pools, "bands", "candidate pools"), band, "candidate pools")
    return [e["rowId"] for e in seq]


# ---------------------------------------------------------------------------
# Append-only annotation ledger (finding 2 + finding 13)
# ---------------------------------------------------------------------------


def _ledger_lines() -> list[bytes]:
    if not LEDGER_PATH.exists():
        return []
    return [ln for ln in LEDGER_PATH.read_bytes().split(b"\n") if ln.strip()]


def ledger_head() -> tuple[str, int]:
    lines = _ledger_lines()
    if not lines:
        return GENESIS_DIGEST, 0
    return sha256_bytes(lines[-1]), len(lines)


def ledger_events() -> list[dict]:
    events: list[dict] = []
    for i, line in enumerate(_ledger_lines()):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError as exc:
            raise HarnessError(f"annotation ledger line {i} is not valid JSON: {exc}") from exc
        events.append(ev)
    return events


def append_ledger_event(event: dict) -> str:
    lines = _ledger_lines()
    prev = GENESIS_DIGEST if not lines else sha256_bytes(lines[-1])
    full = dict(event)
    full["index"] = len(lines)
    full["prev"] = prev
    line = json.dumps(full, sort_keys=True, separators=(",", ":")).encode("utf-8")
    LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(LEDGER_PATH, "ab") as fh:
        fh.write(line + b"\n")
    return sha256_bytes(line)


def active_ledger_events() -> dict[tuple[str, int], dict]:
    """Latest event per (band, batch); a `replacement` supersedes its predecessor
    without overwriting it."""
    active: dict[tuple[str, int], dict] = {}
    for ev in ledger_events():
        active[(str(ev.get("band")), int(ev.get("batch", -1)))] = ev
    return active


def verify_ledger(commitment_sha: str) -> list[str]:
    """Return failures. Detects chain breaks, a stale tracked head, an edited or
    deleted annotation file, an unreferenced (added or duplicated) annotation
    file, and an abandoned batch that still carries annotations."""
    failures: list[str] = []
    lines = _ledger_lines()
    prev = GENESIS_DIGEST
    events: list[dict] = []
    for i, line in enumerate(lines):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError as exc:
            failures.append(f"annotation ledger line {i} is not valid JSON: {exc}")
            return failures
        if int(ev.get("index", -1)) != i:
            failures.append(f"annotation ledger event {i} carries index {ev.get('index')!r}")
        if ev.get("prev") != prev:
            failures.append(
                f"annotation ledger chain break at event {i}: prev {ev.get('prev')!r} != "
                f"the previous event digest {prev}"
            )
        if ev.get("status") not in LEDGER_STATUSES:
            failures.append(f"annotation ledger event {i}: unknown status {ev.get('status')!r}")
        if ev.get("commitment_sha256") != commitment_sha:
            failures.append(
                f"annotation ledger event {i} is bound to commitment "
                f"{ev.get('commitment_sha256')!r}, not the active commitment"
            )
        prev = sha256_bytes(line)
        events.append(ev)

    head, count = ledger_head()
    if LEDGER_HEAD_JSON.exists():
        head_doc = _read_json(LEDGER_HEAD_JSON, "annotation ledger head")
        if head_doc.get("head_sha256") != head or int(head_doc.get("event_count", -1)) != count:
            failures.append(
                "tracked annotation-ledger head is stale: it records "
                f"{head_doc.get('head_sha256')!r}/{head_doc.get('event_count')!r}, the ledger "
                f"head is {head}/{count}"
            )
    elif count:
        failures.append("annotation ledger has events but the tracked head artifact is absent")

    active = active_ledger_events()
    referenced: set[Path] = set()
    for (band, batch), ev in sorted(active.items()):
        record_path = BATCHES_DIR / band / f"batch-{batch:03d}.json"
        if not record_path.exists():
            failures.append(f"ledger references a missing batch record {band}/batch-{batch:03d}")
        elif sha256_file(record_path) != ev.get("batch_record_sha256"):
            failures.append(
                f"batch record {band}/batch-{batch:03d} does not match its ledger digest"
            )
        ann_path = ANNOTATIONS_DIR / band / f"batch-{batch:03d}.json"
        if ev.get("status") == LEDGER_ABANDONED:
            if ann_path.exists():
                failures.append(
                    f"abandoned batch {band}/{batch} still carries an annotation record; an "
                    "abandoned batch yields no members and must contribute no annotations"
                )
            continue
        referenced.add(ann_path)
        if not ann_path.exists():
            failures.append(
                f"annotation record {band}/batch-{batch:03d} recorded in the ledger is missing"
            )
        elif sha256_file(ann_path) != ev.get("annotation_sha256"):
            failures.append(
                f"annotation record {band}/batch-{batch:03d} does not match its ledger "
                "digest - it was edited after ingest"
            )
    if ANNOTATIONS_DIR.exists():
        for p in sorted(ANNOTATIONS_DIR.glob("*/batch-*.json")):
            if p not in referenced:
                failures.append(
                    f"annotation record {p.parent.name}/{p.name} is not referenced by any "
                    "active ledger event - it was added, duplicated, or moved"
                )
    return failures


def write_ledger_head(commitment_sha: str) -> dict:
    head, count = ledger_head()
    active = active_ledger_events()
    bands = {
        name: {
            "completed": sum(
                1
                for (b, _), ev in active.items()
                if b == name and ev.get("status") in (LEDGER_COMPLETED, LEDGER_REPLACEMENT)
            ),
            "abandoned": sum(
                1
                for (b, _), ev in active.items()
                if b == name and ev.get("status") == LEDGER_ABANDONED
            ),
        }
        for name in BAND_NAMES
    }
    doc = {
        "schema_version": 1,
        "story": "12.7",
        "head_sha256": head,
        "event_count": count,
        "commitment_sha256": commitment_sha,
        "bands": bands,
        "note": LEDGER_INTEGRITY_NOTE,
    }
    gate_committed(doc, assert_ledger_head_schema)
    _write_json(LEDGER_HEAD_JSON, doc)
    return doc


def _load_all_annotations(band: str) -> dict[str, dict]:
    """Annotations for a band, LEDGER-DRIVEN: only files an active, non-abandoned
    ledger event names, each verified against its recorded digest. The
    pre-rework glob + `dict.update` merged whatever happened to be on disk."""
    out: dict[str, dict] = {}
    for (b, batch), ev in sorted(active_ledger_events().items()):
        if b != band or ev.get("status") == LEDGER_ABANDONED:
            continue
        path = ANNOTATIONS_DIR / b / f"batch-{batch:03d}.json"
        doc = _read_json(path, "annotation record")
        if sha256_file(path) != ev.get("annotation_sha256"):
            raise HarnessError(
                f"annotation record {b}/batch-{batch:03d} does not match its ledger digest"
            )
        rows = _require(doc, "rows", f"annotation record {path.name}")
        overlap = sorted(set(rows) & set(out))
        if overlap:
            raise HarnessError(
                f"annotation records for {band} overlap on row ids {overlap[:5]} - batches "
                "are disjoint consecutive spans"
            )
        out.update(rows)
    return out


def _recompute_membership(pools: dict, n_band: int = N_BAND) -> dict:
    membership = {}
    for name in BAND_NAMES:
        annotations = _load_all_annotations(name)
        membership[name] = compute_membership(pools["bands"][name], annotations, name, n_band)
    return membership


# ---------------------------------------------------------------------------
# commit-pools
# ---------------------------------------------------------------------------


def _superseded_halt(commitment: dict) -> None:
    lines = [
        "COMMITMENT SUPERSEDED: the candidate commitment on record has "
        f"status {commitment.get('status')!r} and CANNOT be operated on or extended.",
        "Reason: it was minted without the mandatory pre-commitment fingerprint review "
        "(signed section 2), its opaque row IDs encode draw position, and its Tony and "
        "OA300 rows are not content-bound.",
        "Re-minting is blocked on the following, all of which must be on record first:",
    ]
    if not DISPOSITIONS_PATH.exists():
        lines.append(
            f"  - MISSING fingerprint dispositions ({DISPOSITIONS_PATH.name}). Run "
            "`prepare-review` to generate the flag set plus the disposition template, then "
            "record a human disposition for every flag."
        )
    else:
        lines.append(f"  - fingerprint dispositions present ({DISPOSITIONS_PATH.name}).")
    if not DECISIONS_PATH.exists():
        lines.append(f"  - MISSING operator decisions ({DECISIONS_PATH.name}), both of them:")
        lines.append(
            "      (a) short-band allocation: the precommitted fallback is empty by "
            "construction - Tony and OA300 rows are already in the initial pool and are "
            "also the signed fallback source, so 160-175 and 175-plus cannot be extended "
            f"at all. Accepted policies: {list(SHORT_BAND_POLICIES)}."
        )
        lines.append(
            "      (b) cross-band duplicate rule: the signed tie-break orders rows WITHIN "
            "a band's draw sequence and defines no winner BETWEEN two bands, while the "
            "same recording tagged at half and full tempo lands in two bands by "
            f"construction. Accepted policies: {list(CROSS_BAND_POLICIES)}."
        )
    else:
        lines.append(f"  - operator decisions present ({DECISIONS_PATH.name}).")
    lines.append(
        "No mint was performed and no committed digest was rewritten. The existing "
        "commitment artifacts are retained (amend, never erase)."
    )
    raise OperatorHalt("\n".join(lines))


def cmd_commit_pools(args: argparse.Namespace) -> int:
    inputs = load_inputs()

    existing = None
    if COMMITMENT_JSON.exists():
        existing = read_commitment()
        if existing.get("status") != STATUS_ACTIVE:
            _superseded_halt(existing)
        master_seed = int(_require(existing, "master_seed", "existing commitment"))
        if args.seed is not None and int(args.seed) != master_seed:
            raise HarnessError(
                f"--seed {args.seed} conflicts with the recorded master seed "
                f"{master_seed}; a minted commitment's seed is immutable. Omit --seed "
                "to verify, or remove the commitment deliberately to re-commit."
            )
        print(f"existing commitment found; verifying with recorded master seed {master_seed}")
    elif args.seed is not None:
        master_seed = int(args.seed)
    else:
        master_seed = secrets.randbits(32)

    bands, accounting = build_universe(inputs)
    exclusions = accounting["exclusions"]
    universe_digest = candidate_universe_digest(bands)

    flags = build_review_flags(inputs, bands)
    dispositions = load_dispositions(universe_digest, {f["flag_id"] for f in flags})
    bands, recording_groups, confirmed = apply_dispositions(bands, exclusions, dispositions, flags)

    decisions = load_operator_decisions()
    n_band = N_BAND
    if decisions["short_band_allocation"]["policy"] == "shrink-corpus":
        n_band = int(decisions["short_band_allocation"]["n_band"])

    bands = bind_content_hashes(
        bands,
        exclusions,
        lambda entry: _safe_resolve(entry, inputs["pool_audio_root"]),
        _safe_sha256_file,
    )
    if decisions["cross_band_duplicate_rule"]["policy"] == "pre-commitment-recording-dedup":
        bands = dedup_across_bands(
            bands,
            exclusions,
            list(decisions["cross_band_duplicate_rule"]["band_priority"]),
            recording_groups,
        )

    seed_rng = random.Random(master_seed)
    band_seeds = {name: seed_rng.getrandbits(32) for name in BAND_NAMES}

    sequences: dict[str, list[dict]] = {}
    for i, name in enumerate(BAND_NAMES):
        sequences[name] = draw_sequence(i, bands[name], band_seeds[name])

    pools_doc = {
        "schema_version": 2,
        "bands": {name: sequences[name] for name in BAND_NAMES},
        "pool_audio_root": inputs["pool_audio_root"],
        "seeds": band_seeds,
        "master_seed": master_seed,
    }
    draws_doc = {
        "schema_version": 2,
        "seed_algorithm": SEED_ALGORITHM,
        "bands": {
            name: {
                "seed": band_seeds[name],
                "sequence": [e["rowId"] for e in sequences[name]],
            }
            for name in BAND_NAMES
        },
    }

    if existing is not None:
        # A minted commitment is immutable: never regenerate-and-overwrite, and
        # never rewrite the committed digests. Check BOTH directions - today's
        # regenerated documents against the recorded digests (input drift) and
        # the on-disk files against them (tamper) - then restore a missing
        # row-level file deterministically.
        verify_input_drift(existing, pools_doc, draws_doc)
        recorded_pool = _require(existing, "pool_file_sha256", "existing commitment")
        recorded_draw = _require(existing, "draw_file_sha256", "existing commitment")
        restored = False
        for path, doc, recorded, label in (
            (POOLS_PATH, pools_doc, recorded_pool, "pool_file_sha256"),
            (DRAWS_PATH, draws_doc, recorded_draw, "draw_file_sha256"),
        ):
            if path.exists():
                actual = sha256_file(path)
                if actual != recorded:
                    raise DriftError(
                        f"commitment digest mismatch - committed {label} {recorded} != "
                        f"on-disk {actual} for {path.name}. The row-level file was "
                        "tampered with; refusing to overwrite."
                    )
            else:
                _write_bytes_atomic(path, _json_bytes(doc))
                restored = True
        state = "restored" if restored else "verified"
        print(
            f"commitment {state} (inputs re-derived and digest-matched): "
            f"pool_file_sha256 {recorded_pool}, draw_file_sha256 {recorded_draw}"
        )
        short = existing.get("short_bands", [])
        if short:
            raise OperatorHalt(
                f"bands below the {existing.get('n_band_target', N_BAND)}-candidate floor "
                f"remain recorded: {', '.join(short)}"
            )
        return 0

    _write_json(POOLS_PATH, pools_doc)
    _write_json(DRAWS_PATH, draws_doc)
    pool_sha = sha256_file(POOLS_PATH)
    draw_sha = sha256_file(DRAWS_PATH)

    band_counts = {name: len(sequences[name]) for name in BAND_NAMES}
    short_bands = [name for name in BAND_NAMES if band_counts[name] < n_band]

    commitment = {
        "schema_version": 2,
        "story": "12.7",
        "status": STATUS_ACTIVE,
        "generated": date.today().isoformat(),
        "protocol": PROTOCOL_POINTER,
        "run_command": "make eval-corpus-pools",
        "seed_algorithm": SEED_ALGORITHM,
        "master_seed": master_seed,
        "n_band_target": n_band,
        "bands": {
            name: {
                "candidates": band_counts[name],
                "seed": band_seeds[name],
                "exclusions": exclusions[name],
            }
            for name in BAND_NAMES
        },
        "tagless_by_source": accounting["tagless"],
        "artist_exclusion_limitation": accounting["artist_limitation"],
        "fingerprint_review": {
            "method": FINGERPRINT_METHOD,
            "flags": len(flags),
            "confirmed_same_recording": confirmed,
            "cleared": len(flags) - confirmed,
            "dispositions_sha256": sha256_file(DISPOSITIONS_PATH),
            "candidate_universe_sha256": universe_digest,
            "training_input_sha256": training_input_digest(),
        },
        "operator_decisions": {
            "decisions_sha256": sha256_file(DECISIONS_PATH),
            "decided": str(decisions["decided"]),
            "short_band_allocation": decisions["short_band_allocation"]["policy"],
            "cross_band_duplicate_rule": decisions["cross_band_duplicate_rule"]["policy"],
        },
        "pool_file_sha256": pool_sha,
        "draw_file_sha256": draw_sha,
        "short_bands": short_bands,
        "notes": [LEDGER_INTEGRITY_NOTE],
    }
    try:
        gate_committed(commitment, assert_commitment_schema)
    except PrivacyError as exc:
        print(f"PRIVACY GATE FAILED on commitment artifact: {exc}", file=sys.stderr)
        return 3
    _write_json(COMMITMENT_JSON, commitment)
    _write_text_atomic(COMMITMENT_MD, render_commitment_md(commitment))
    write_ledger_head(sha256_file(COMMITMENT_JSON))

    for name in BAND_NAMES:
        print(f"  {name:9s} candidates={band_counts[name]:4d} exclusions={exclusions[name]}")
    print(f"tag-less by source: {accounting['tagless']}")
    print(f"pool_file_sha256: {pool_sha}")
    flush_fingerprint_cache()
    if short_bands:
        raise OperatorHalt(
            f"bands below the {n_band}-candidate floor at commitment: "
            f"{', '.join(short_bands)}. Exhaustion escalation is the operator's "
            "(signed fallback order: Tony as-entered rows, then OA300; committed as "
            "a dated addendum before any DSP statistic is consulted). No auto-extension."
        )
    return 0


def render_commitment_md(c: dict) -> str:
    lines = [
        "# Story 12.7: candidate-pool commitment record",
        "",
        f"Status: **{c['status']}**.",
        "",
        f"Generated {c['generated']} by `scripts/build-eval-corpus.py commit-pools` "
        f"(`{c['run_command']}`). Counts, seeds, and the named commitment digests only; "
        "the row-level candidate inventory is gitignored per the privacy rule "
        "(OA300 and the collection inventory are private).",
        "",
        f"Signed protocol: `{c['protocol']}`.",
        "",
        f"Seed algorithm: {c['seed_algorithm']}. Master seed: {c['master_seed']}.",
        "",
    ]
    if c["status"] == STATUS_SUPERSEDED:
        lines += [f"{c['superseded_note']}", ""]
    # Render only the exclusion routes this record actually ran. A superseded
    # v1 record predates the fingerprint route; printing a 0 under it would
    # claim the route ran and confirmed nothing.
    present = set()
    for name in BAND_NAMES:
        present |= set(c["bands"][name]["exclusions"])
    reasons = [r for r in EXCLUSION_REASONS if r in present]
    header = "| Band | Candidates | " + " | ".join(reasons) + " | Seed |"
    lines += [header, "|" + "---|" * (len(reasons) + 3)]
    for name in BAND_NAMES:
        b = c["bands"][name]
        e = b["exclusions"]
        cells = " | ".join(str(e[reason]) for reason in reasons)
        lines.append(f"| {name} | {b['candidates']} | {cells} | {b['seed']} |")
    t = c["tagless_by_source"]
    lines += [
        "",
        f"Tag-less rows excluded before banding (face-value banding requires a value): "
        f"pool {t['pool']}, tony {t['tony']}, oa300 {t['oa300']}. Tag-less rows carry no "
        "band, so these counts are per source.",
        "",
        f"Artist-exclusion limitation: {c['artist_exclusion_limitation']}",
        "",
    ]
    if c["status"] == STATUS_ACTIVE:
        fr = c["fingerprint_review"]
        od = c["operator_decisions"]
        lines += [
            f"Pre-commitment fingerprint review (mandatory, signed section 2): method "
            f"{fr['method']}, {fr['flags']} review flag(s), {fr['confirmed_same_recording']} "
            f"confirmed same-recording and excluded, {fr['cleared']} cleared by recorded "
            "human disposition. The algorithm flags; the disposition excludes.",
            "",
            f"Dispositions digest: `{fr['dispositions_sha256']}`",
            "",
            f"Candidate-universe digest: `{fr['candidate_universe_sha256']}`",
            "",
            f"Training-input digest: `{fr['training_input_sha256']}`",
            "",
            f"Operator decisions ({od['decided']}): short-band allocation "
            f"{od['short_band_allocation']}, cross-band duplicate rule "
            f"{od['cross_band_duplicate_rule']}; decisions digest "
            f"`{od['decisions_sha256']}`.",
            "",
        ]
    lines += [
        f"Row-level pool file SHA-256: `{c['pool_file_sha256']}`",
        "",
        f"Draw-sequence file SHA-256: `{c['draw_file_sha256']}`",
        "",
    ]
    if c["short_bands"]:
        target = c["n_band_target"]
        shortfalls = ", ".join(
            f"{name} ({c['bands'][name]['candidates']} of {target}, "
            f"short {target - c['bands'][name]['candidates']})"
            for name in c["short_bands"]
        )
        lines += [
            f"HALT recorded: these bands CANNOT reach {target} members from the "
            f"committed pools: {shortfalls}. No auto-extension was performed.",
            "",
            "The signed exhaustion fallback does NOT resolve this on its own. Its source "
            "order is Tony as-entered rows, then OA300 rows, and both are already inside "
            "the primary pools, so the fallback set is empty by construction: it can "
            "recover at most 25 rows for 100-120 and 44 for 120-140, and exactly ZERO for "
            "160-175 and 175-plus. A precommitted primary allocation plus reserves would "
            "draw across all three sources while preserving a real fallback; shrinking the "
            "corpus by operator decision is the other signed option. This is an operator "
            "decision, supplied as machine-readable input; the harness refuses to mint "
            "while it is absent rather than inferring a policy from prose.",
            "",
        ]
    for note in c.get("notes", []):
        lines += [note, ""]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# prepare-review (finding 5 machinery + finding 8 title flags)
# ---------------------------------------------------------------------------


def build_review_flags(inputs: dict, bands: dict[str, list[dict]]) -> list[dict]:
    """Generate the pre-commitment review flag set.

    Two kinds, both ADVISORY signals that a human disposition must resolve:
      - `training-fingerprint`: candidate audio whose 52-d timbral fingerprint
        matches a training-manifest or tony.train/val recording at or above the
        DD #3 review cosine. This is the signed section-2 "by audio fingerprint"
        route; DD #3 constrains fingerprint from being the SOLE AUTOMATIC signal,
        which is exactly why the human disposition gates rather than the score.
      - `giantsteps-title`: candidate whose normalized title collides with a
        GiantSteps title. `normalize_track_key` drops suffixes and parenthesized
        material, so a hit is a conservative heuristic, never proof of a shared
        recording (finding 8).
    """
    flags: list[dict] = []
    gs_titles = _giantsteps_titles()
    for name in BAND_NAMES:
        for entry in bands[name]:
            nk = cc.normalize_track_key(entry.get("title", ""))
            if nk and nk in gs_titles:
                key = f"{entry['source']}:{entry['identity']}"
                flags.append(
                    {
                        "flag_id": flag_id(FLAG_KIND_GIANTSTEPS, key, nk),
                        "kind": FLAG_KIND_GIANTSTEPS,
                        "band": name,
                        "candidate_key": key,
                        "evidence": "normalized-title collision with a GiantSteps row",
                        "score": None,
                    }
                )
    flags.extend(_fingerprint_flags(inputs, bands))
    flags.extend(_cross_band_recording_flags(inputs, bands))
    flags.sort(key=lambda f: f["flag_id"])
    return flags


def _giantsteps_titles() -> set[str]:
    gs_path = cc.resolve_giantsteps_gt_path()
    if gs_path is None or not gs_path.exists():
        raise HarnessError(
            "GiantSteps ground truth is not resolvable (GIANTSTEPS_CORPUS_PATH unset or "
            "the file is absent). FR-59a.2 coverage cannot be certified and this harness "
            "fails closed, matching scripts/audit-corpus-splits.py. Set "
            "GIANTSTEPS_CORPUS_PATH and re-run."
        )
    external = cc.build_external_index(giantsteps_gt_path=gs_path)
    return {
        cc.normalize_track_key(title)
        for hits in external.by_norm.values()
        for (corpus, title) in hits
        if corpus == "giantsteps"
    }


def _training_fingerprints(inputs: dict) -> list[tuple[str, list[float]]]:
    out: list[tuple[str, list[float]]] = []
    root = inputs.get("pool_audio_root")
    for audio_hash, rel in sorted(inputs.get("manifest_paths", {}).items()):
        path = Path(root) / rel if root else Path(rel)
        if not path.exists():
            continue
        vec = FINGERPRINT_FN(str(path))
        if vec:
            out.append((f"manifest:{audio_hash}", vec))
    for tid, local in sorted(inputs.get("training_local_paths", {}).items()):
        if not Path(local).exists():
            continue
        vec = FINGERPRINT_FN(local)
        if vec:
            out.append((f"tony-split:{tid}", vec))
    return out


def _candidate_fingerprints(
    inputs: dict, bands: dict[str, list[dict]]
) -> list[tuple[str, str, list[float]]]:
    root = inputs.get("pool_audio_root")
    out: list[tuple[str, str, list[float]]] = []
    for name in BAND_NAMES:
        for entry in bands[name]:
            path = _safe_resolve(entry, root)
            if path is None:
                continue
            vec = FINGERPRINT_FN(str(path))
            if vec:
                out.append((name, f"{entry['source']}:{entry['identity']}", vec))
    return out


def _fingerprint_flags(inputs: dict, bands: dict[str, list[dict]]) -> list[dict]:
    training = _training_fingerprints(inputs)
    if not training:
        return []
    candidates = _candidate_fingerprints(inputs, bands)
    stats = cohort_stats([v for _, v in training] + [v for _, _, v in candidates])
    training_z = [(k, standardize(v, stats)) for k, v in training]
    flags: list[dict] = []
    for name, key, raw in candidates:
        vec = standardize(raw, stats)
        for train_key, train_vec in training_z:
            score = cosine(vec, train_vec)
            if score >= FINGERPRINT_REVIEW_COSINE:
                flags.append(
                    {
                        "flag_id": flag_id(FLAG_KIND_FINGERPRINT, key, train_key),
                        "kind": FLAG_KIND_FINGERPRINT,
                        "band": name,
                        "candidate_key": key,
                        "evidence": f"standardized cosine {score:.4f} vs {train_key}",
                        "score": round(score, 6),
                    }
                )
    return flags


def _cross_band_recording_flags(inputs: dict, bands: dict[str, list[dict]]) -> list[dict]:
    """Candidate-vs-candidate fingerprint pairs in DIFFERENT bands (finding 12).

    The same recording tagged 85 in one source and 170 in another lands in two
    bands by construction, and a byte digest cannot see it because the two files
    are different encodes. These pairs are the evidence the operator's cross-band
    duplicate decision needs, and a confirmed disposition supplies the recording
    group that `pre-commitment-recording-dedup` collapses on. They are review
    flags, not exclusions: confirming one does not remove a candidate.
    """
    raw = _candidate_fingerprints(inputs, bands)
    stats = cohort_stats([v for _, _, v in raw])
    vectors = [(band, key, standardize(vec, stats)) for band, key, vec in raw]
    flags: list[dict] = []
    for i in range(len(vectors)):
        band_a, key_a, vec_a = vectors[i]
        for j in range(i + 1, len(vectors)):
            band_b, key_b, vec_b = vectors[j]
            if band_a == band_b:
                continue  # within a band the signed draw-sequence tie-break decides
            score = cosine(vec_a, vec_b)
            if score < FINGERPRINT_REVIEW_COSINE:
                continue
            left, right = sorted((key_a, key_b))
            flags.append(
                {
                    "flag_id": flag_id(FLAG_KIND_CROSS_BAND, left, right),
                    "kind": FLAG_KIND_CROSS_BAND,
                    "band": band_a if left == key_a else band_b,
                    "candidate_key": left,
                    "peer_key": right,
                    "evidence": (
                        f"standardized cosine {score:.4f} across bands {band_a} and {band_b}"
                    ),
                    "score": round(score, 6),
                }
            )
    return flags


def cmd_prepare_review(_args: argparse.Namespace) -> int:
    """Stage 1 of the mandatory fingerprint route: generate flags plus a
    disposition template. Minting consumes the filled template, so a mint can
    never demand dispositions that were never generated."""
    inputs = load_inputs()
    bands, _ = build_universe(inputs)
    universe = candidate_universe_digest(bands)
    flags = build_review_flags(inputs, bands)
    review = {
        "schema_version": 1,
        "candidate_universe_sha256": universe,
        "fingerprint_method": FINGERPRINT_METHOD,
        "review_cosine": FINGERPRINT_REVIEW_COSINE,
        "training_input_sha256": training_input_digest(),
        "flags": flags,
    }
    _write_json(REVIEW_FLAGS_PATH, review)
    template = {
        "schema_version": 1,
        "candidate_universe_sha256": universe,
        "fingerprint_method": FINGERPRINT_METHOD,
        "training_input_sha256": training_input_digest(),
        "flags": [
            {
                "flag_id": f["flag_id"],
                "kind": f["kind"],
                "band": f["band"],
                "evidence": f["evidence"],
                "disposition": None,
                "recording_group": None,
                "note": "",
            }
            for f in flags
        ],
    }
    _write_json(DISPOSITIONS_TEMPLATE_PATH, template)
    by_kind: dict[str, int] = {}
    for f in flags:
        by_kind[f["kind"]] = by_kind.get(f["kind"], 0) + 1
    print(
        f"review flags: {len(flags)} ({by_kind}); candidate universe {universe}\n"
        f"flags: {REVIEW_FLAGS_PATH}\ntemplate: {DISPOSITIONS_TEMPLATE_PATH}\n"
        f"Record a disposition ({' or '.join(DISPOSITION_VALUES)}) for every flag and save "
        f"as {DISPOSITIONS_PATH.name}; minting is blocked until then."
    )
    flush_fingerprint_cache()
    return 0


# ---------------------------------------------------------------------------
# stage-batch
# ---------------------------------------------------------------------------


def cmd_stage_batch(args: argparse.Namespace) -> int:
    if args.band not in BAND_NAMES:
        raise HarnessError(f"unknown band {args.band!r}; bands: {', '.join(BAND_NAMES)}")
    if int(args.size) < 1:
        raise HarnessError(f"--size must be >= 1, got {args.size}")
    _commitment, commitment_sha = require_active_commitment()
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    sequence = _require(_require(pools, "bands", "candidate pools"), args.band, "candidate pools")
    row_ids = [e["rowId"] for e in sequence]

    ledger_failures = verify_ledger(commitment_sha)
    if ledger_failures:
        raise HarnessError(
            "annotation ledger does not verify; refusing to stage:\n  "
            + "\n  ".join(ledger_failures)
        )

    records = validate_batch_records(args.band, row_ids)
    next_index = len(records)
    active = active_ledger_events()
    unanchored = [rec["batch"] for rec in records if (args.band, int(rec["batch"])) not in active]
    by_row_id = {e["rowId"]: e for e in sequence}

    if (
        args.batch is not None
        and int(args.batch) == next_index - 1
        and unanchored == [next_index - 1]
    ):
        # Resume: re-stage the last recorded but not-yet-anchored batch
        # (record-then-stage means an interrupted copy leaves a record).
        rec = records[next_index - 1]
        span = [by_row_id[rid] for rid in rec["rowIds"]]
        stage_dir = STAGING_DIR / args.band / f"batch-{next_index - 1:03d}"
        rows = _stage_copies(span, stage_dir, pools.get("pool_audio_root"), rec["work_order"])
        _write_worklist(BATCHES_DIR / args.band / f"batch-{next_index - 1:03d}-worklist.csv", rows)
        print(f"re-staged batch {next_index - 1} for {args.band}: {len(span)} rows -> {stage_dir}")
        return 0
    if unanchored:
        raise HarnessError(
            f"batch(es) {unanchored} for {args.band} are staged but not anchored in the "
            "annotation ledger. Ingest or abandon them before staging another; several "
            "unanchored batches cannot accumulate behind illusory tamper evidence."
        )
    if args.batch is not None and int(args.batch) != next_index:
        raise HarnessError(
            f"batch out of sequence: next batch for {args.band} is {next_index}, "
            f"requested {args.batch} (pass the previous index to re-stage it)"
        )
    start = sum(int(rec["size"]) for rec in records)
    size = int(args.size)
    span = sequence[start : start + size]
    if not span:
        raise HarnessError(f"band {args.band} draw sequence exhausted at position {start}")

    band_seed = int(_require(_require(pools, "seeds", "candidate pools"), args.band, "seeds"))
    order_seed = (band_seed ^ (next_index * 0x9E3779B1)) & 0xFFFFFFFF
    span_ids = [e["rowId"] for e in span]
    order = work_order(span_ids, order_seed)

    # Record BEFORE staging (record-then-stage): an interrupted copy leaves a
    # batch record rather than orphan audio files.
    band_batches = BATCHES_DIR / args.band
    band_batches.mkdir(parents=True, exist_ok=True)
    _write_json(
        band_batches / f"batch-{next_index:03d}.json",
        {
            "band": args.band,
            "batch": next_index,
            "size": len(span),
            "start": start,
            "rowIds": span_ids,
            "work_order_seed": order_seed,
            "work_order": order,
        },
    )
    stage_dir = STAGING_DIR / args.band / f"batch-{next_index:03d}"
    rows = _stage_copies(span, stage_dir, pools.get("pool_audio_root"), order)
    worklist = band_batches / f"batch-{next_index:03d}-worklist.csv"
    _write_worklist(worklist, rows)
    print(
        f"staged batch {next_index} for {args.band}: {len(span)} rows -> {stage_dir}\n"
        f"worklist: {worklist} (randomized within-batch work order)"
    )
    return 0


# ---------------------------------------------------------------------------
# ingest / abandon
# ---------------------------------------------------------------------------

_TRUE = {"1", "true", "yes", "y"}
_FALSE = {"", "0", "false", "no", "n"}


def _parse_flag(value: str, row_id: str, column: str) -> bool:
    v = value.strip().lower()
    if v in _TRUE:
        return True
    if v in _FALSE:
        return False
    raise HarnessError(f"row {row_id}: unparseable flag {column}={value!r}")


def parse_annotations_csv(path: Path, expected_row_ids: list[str]) -> dict[str, dict]:
    """Validate + parse the operator-filled annotation CSV. Every worklist row
    must appear exactly once and be well-formed, or NOTHING is applied."""
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        header = set(reader.fieldnames or [])
        if header != EXPECTED_ANNOTATION_COLUMNS:
            missing_cols = sorted(EXPECTED_ANNOTATION_COLUMNS - header)
            unknown_cols = sorted(header - EXPECTED_ANNOTATION_COLUMNS)
            raise HarnessError(
                f"annotation CSV header mismatch: missing columns {missing_cols}, "
                f"unknown columns {unknown_cols} - expected exactly "
                f"{sorted(EXPECTED_ANNOTATION_COLUMNS)}"
            )
        rows = list(reader)
    seen: dict[str, dict] = {}
    for raw in rows:
        row_id = (raw.get("row_id") or "").strip()
        if not row_id:
            raise HarnessError("annotation row with empty row_id")
        if row_id in seen:
            raise HarnessError(f"duplicate annotation for row {row_id}")
        ann: dict[str, Any] = {}
        for col in ("tempo_unstable", "irresolvable", "ambiguous", "audio_defect"):
            ann[col] = _parse_flag(raw.get(col, ""), row_id, col)
        bpm_raw = (raw.get("verified_bpm") or "").strip()
        if bpm_raw:
            try:
                bpm_value = float(bpm_raw)
            except ValueError:
                raise HarnessError(f"row {row_id}: unparseable verified_bpm {bpm_raw!r}") from None
            if not math.isfinite(bpm_value):
                raise HarnessError(f"row {row_id}: non-finite verified_bpm {bpm_raw!r}")
            ann["verified_bpm"] = round(bpm_value, 2)
        elif not (ann["tempo_unstable"] or ann["irresolvable"] or ann["audio_defect"]):
            raise HarnessError(f"row {row_id}: verified_bpm missing and no rejecting flag set")
        dup = (raw.get("duplicate_of") or "").strip()
        if dup:
            ann["duplicate_of"] = dup
        seen[row_id] = ann
    missing = [r for r in expected_row_ids if r not in seen]
    extra = [r for r in seen if r not in set(expected_row_ids)]
    if missing or extra:
        raise HarnessError(
            f"annotation set does not match the committed batch: missing={missing} extra={extra} "
            "- the entire committed batch is annotated (safe-ordering condition 2)"
        )
    return seen


def _batch_context(band: str, batch: int) -> tuple[dict, dict, dict]:
    """Active commitment + validated batch record for one (band, batch)."""
    if band not in BAND_NAMES:
        raise HarnessError(f"unknown band {band!r}")
    _, commitment_sha = require_active_commitment()
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    records = validate_batch_records(band, _sequence_row_ids(pools, band))
    if batch < 0 or batch >= len(records):
        raise HarnessError(
            f"batch {batch} for {band} has no validated record (records: {len(records)})"
        )
    return {"sha": commitment_sha}, pools, records[batch]


def cmd_ingest(args: argparse.Namespace) -> int:
    batch = int(args.batch)
    ctx, pools, record = _batch_context(args.band, batch)
    commitment_sha = ctx["sha"]
    failures = verify_ledger(commitment_sha)
    if failures:
        raise HarnessError(
            "annotation ledger does not verify; refusing to ingest:\n  " + "\n  ".join(failures)
        )
    active = active_ledger_events()
    prior = active.get((args.band, batch))
    if prior is not None and prior.get("status") == LEDGER_ABANDONED:
        raise HarnessError(
            f"batch {batch} for {args.band} is recorded ABANDONED; an abandoned batch "
            "yields no members and cannot be ingested."
        )

    annotations = parse_annotations_csv(Path(args.annotations), list(record["rowIds"]))
    record_path = ANNOTATIONS_DIR / args.band / f"batch-{batch:03d}.json"
    meta: dict[str, Any] = {"band": args.band, "batch": batch}
    status = LEDGER_COMPLETED
    if prior is not None:
        if not args.force:
            raise HarnessError(
                f"annotation record for {args.band}/batch-{batch:03d} is already anchored in "
                "the ledger; re-ingest requires --force (a replacement event is appended, "
                "the prior event is never overwritten)"
            )
        meta["replaced_sha256"] = str(prior.get("annotation_sha256"))
        status = LEDGER_REPLACEMENT
    _write_json(record_path, {"_meta": meta, "rows": annotations})

    keepers = sum(1 for rid in record["rowIds"] if keep_or_reject(annotations[rid], args.band)[0])
    batch_record_path = BATCHES_DIR / args.band / f"batch-{batch:03d}.json"
    worklist_path = BATCHES_DIR / args.band / f"batch-{batch:03d}-worklist.csv"
    append_ledger_event(
        {
            "commitment_sha256": commitment_sha,
            "band": args.band,
            "batch": batch,
            "status": status,
            "recorded": date.today().isoformat(),
            "batch_record_sha256": sha256_file(batch_record_path),
            "work_order_sha256": (
                sha256_file(worklist_path) if worklist_path.exists() else GENESIS_DIGEST
            ),
            "annotation_sha256": sha256_file(record_path),
            "counts": {"rows": len(annotations), "keepers": keepers},
        }
    )
    write_ledger_head(commitment_sha)

    membership = _recompute_membership(pools, _n_band())
    _write_json(MEMBERSHIP_PATH, membership)
    m = membership[args.band]
    print(
        f"ingested batch {batch} for {args.band}: members {len(m['members'])}/{_n_band()}, "
        f"surplus {len(m['surplus'])}, rejects {len(m['rejects'])}, annotated {m['annotated']}"
    )
    return 0


def cmd_abandon(args: argparse.Namespace) -> int:
    """Signed rule: an abandoned batch yields no members and its partial work is
    discarded. Recorded as an append-only ledger event (finding 13)."""
    batch = int(args.batch)
    ctx, pools, _record = _batch_context(args.band, batch)
    commitment_sha = ctx["sha"]
    failures = verify_ledger(commitment_sha)
    if failures:
        raise HarnessError(
            "annotation ledger does not verify; refusing to abandon:\n  " + "\n  ".join(failures)
        )
    ann_path = ANNOTATIONS_DIR / args.band / f"batch-{batch:03d}.json"
    if ann_path.exists():
        if not args.force:
            raise HarnessError(
                f"batch {batch} for {args.band} already has an annotation record; "
                "abandoning discards it - pass --force to confirm"
            )
        ann_path.unlink()
    batch_record_path = BATCHES_DIR / args.band / f"batch-{batch:03d}.json"
    append_ledger_event(
        {
            "commitment_sha256": commitment_sha,
            "band": args.band,
            "batch": batch,
            "status": LEDGER_ABANDONED,
            "recorded": date.today().isoformat(),
            "batch_record_sha256": sha256_file(batch_record_path),
            "work_order_sha256": GENESIS_DIGEST,
            "annotation_sha256": None,
            "counts": {"rows": 0, "keepers": 0},
            "reason": str(args.reason),
        }
    )
    write_ledger_head(commitment_sha)
    membership = _recompute_membership(pools, _n_band())
    _write_json(MEMBERSHIP_PATH, membership)
    print(f"abandoned batch {batch} for {args.band}: contributes no annotations and no members")
    return 0


def _n_band() -> int:
    if COMMITMENT_JSON.exists():
        doc = read_commitment()
        if isinstance(doc, dict) and isinstance(doc.get("n_band_target"), int):
            return int(doc["n_band_target"])
    return N_BAND


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def cmd_status(_args: argparse.Namespace) -> int:
    require_active_commitment()
    if not POOLS_PATH.exists():
        print("pools not committed; run commit-pools first")
        return 0
    pools = _read_json(POOLS_PATH, "candidate pools")
    for name in BAND_NAMES:
        validate_batch_records(name, _sequence_row_ids(pools, name))
    n_band = _n_band()
    membership = _recompute_membership(pools, n_band)
    print(f"{'band':10s} {'members':>8s} {'annotated':>10s} {'rate':>6s} {'est-reviews':>12s}")
    for name in BAND_NAMES:
        m = membership[name]
        annotated = m["annotated"]
        kept = len(m["members"]) + len(m["surplus"])
        rate = kept / annotated if annotated else None
        est = math.ceil(n_band / rate) if rate else None
        print(
            f"{name:10s} {len(m['members']):>5d}/{n_band} {annotated:>10d} "
            f"{('%.2f' % rate) if rate is not None else '-':>6s} "
            f"{(str(est) if est is not None else '-'):>12s}"
        )
    return 0


# ---------------------------------------------------------------------------
# audit (fail-closed, shared by emit-manifest and signoff)
# ---------------------------------------------------------------------------


def _check_allowed_keys(
    mapping: dict, allowed: frozenset[str], where: str, failures: list[str]
) -> None:
    """FR-59a.1 fail-closed shape: membership inputs may contain ONLY the
    expected keys; anything unexpected (DSP-derived or otherwise) fails."""
    for key in mapping:
        if key not in allowed:
            failures.append(f"FR-59a.1: unexpected field {key!r} in {where}")


def _load_dispositions_for_audit() -> dict[str, dict]:
    if not DISPOSITIONS_PATH.exists():
        return {}
    doc = _read_json(DISPOSITIONS_PATH, "fingerprint dispositions")
    return {str(r.get("flag_id")): r for r in doc.get("flags", [])}


def run_audit() -> tuple[list[str], list[str], list[str]]:
    """The shared fail-closed audit. Returns (failures, warnings, report)."""
    failures: list[str] = []
    warnings: list[str] = []
    report: list[str] = []

    _, commitment_sha = require_active_commitment()
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")

    failures.extend(verify_ledger(commitment_sha))

    # 1. FR-59a.1: membership inputs read only verified tempi + the draw
    # sequence. Allowlist every annotation record, candidate row, and worklist
    # header; an unexpected key fails, whatever it is called. Batch records are
    # validated by the canonical validator at every consumer, this one included.
    for name in BAND_NAMES:
        try:
            validate_batch_records(name, _sequence_row_ids(pools, name))
        except HarnessError as exc:
            failures.append(f"batch records for {name}: {exc}")
        ann_dir = ANNOTATIONS_DIR / name
        if ann_dir.exists():
            for p in sorted(ann_dir.glob("batch-*.json")):
                doc = _read_json(p, "annotation record")
                _check_allowed_keys(doc, ALLOWED_ANNOTATION_DOC_KEYS, f"{name}/{p.name}", failures)
                meta = doc.get("_meta", {})
                if isinstance(meta, dict):
                    _check_allowed_keys(
                        meta, ALLOWED_ANNOTATION_META_KEYS, f"{name}/{p.name}:_meta", failures
                    )
                for rid, ann in doc.get("rows", {}).items():
                    _check_allowed_keys(
                        ann, ALLOWED_ANNOTATION_KEYS, f"{name}/{p.name}:{rid}", failures
                    )
        for entry in pools["bands"][name]:
            _check_allowed_keys(
                entry,
                ALLOWED_CANDIDATE_KEYS,
                f"candidate pool {name}/{entry.get('rowId')}",
                failures,
            )
        band_dir = BATCHES_DIR / name
        if band_dir.exists():
            for wl in sorted(band_dir.glob("*-worklist.csv")):
                with open(wl, newline="", encoding="utf-8") as fh:
                    header = next(csv.reader(fh), [])
                if header != ["row_id", "audio"]:
                    failures.append(
                        f"worklist {wl.name} carries columns beyond row_id+audio: {header}"
                    )

    # 2. FR-59a.2 residual overlap over EVERY candidate, member or not.
    inputs = load_inputs()
    n_band = _n_band()
    try:
        membership = _recompute_membership(pools, n_band)
    except HarnessError as exc:
        # A ledger-detected annotation problem must be REPORTED as an audit
        # failure, not raised past the caller: emit-manifest and signoff decide
        # on this list, and an exception would skip the remaining checks.
        failures.append(f"membership cannot be recomputed: {exc}")
        membership = {name: {"members": [], "surplus": [], "rejects": {}} for name in BAND_NAMES}
    by_row_id = {e["rowId"]: e for name in BAND_NAMES for e in pools["bands"][name]}
    member_entries = [by_row_id[rid] for name in BAND_NAMES for rid in membership[name]["members"]]
    all_candidates = [e for name in BAND_NAMES for e in pools["bands"][name]]
    for entry in all_candidates:
        if entry["source"] == "pool" and entry["identity"] in inputs["manifest_hashes"]:
            failures.append(f"residual manifest-hash overlap: candidate {entry['rowId']}")
        if entry["source"] == "tony":
            if entry["identity"] in inputs["tony_split_ids"]:
                failures.append(f"residual tony-split overlap: candidate {entry['rowId']}")
            akey = cc.canonical_artist_key(entry.get("artist"))
            if akey and akey in inputs["training_artist_keys"]:
                failures.append(f"residual training-artist overlap: candidate {entry['rowId']}")

    # GiantSteps coverage is fail-closed: an unresolvable ground truth means the
    # gate cannot certify, and a gate that cannot certify must not pass
    # (audit-corpus-splits.py:221 precedent).
    gs_path = cc.resolve_giantsteps_gt_path()
    if gs_path is None or not gs_path.exists():
        failures.append(
            "GiantSteps GT not resolved (GIANTSTEPS_CORPUS_PATH unset or file absent) - "
            "FR-59a.2 coverage cannot be certified. Fails closed."
        )
    else:
        dispositions = _load_dispositions_for_audit()
        gs_titles = _giantsteps_titles()
        hits = 0
        for entry in all_candidates:
            nk = cc.normalize_track_key(entry.get("title", ""))
            if not nk or nk not in gs_titles:
                continue
            hits += 1
            key = f"{entry['source']}:{entry['identity']}"
            fid = flag_id(FLAG_KIND_GIANTSTEPS, key, nk)
            disp = dispositions.get(fid, {}).get("disposition")
            if disp is None:
                failures.append(
                    f"GiantSteps title collision for candidate {entry['rowId']} is an "
                    f"UNRESOLVED review flag ({fid}); normalize_track_key drops suffixes "
                    "and parenthesized material, so a hit is a conservative heuristic that "
                    "needs a recorded human disposition before certification."
                )
            elif disp == DISPOSITION_SAME:
                failures.append(
                    f"candidate {entry['rowId']} was adjudicated same-recording as a "
                    "GiantSteps row and must not be in the committed pools"
                )
        report.append(
            f"GiantSteps title pass: {hits} collision(s) over {len(all_candidates)} candidates "
            "(all candidates, not only members)."
        )

    # 3. Duplicate check among members (cross-band, by identity + normalized title
    # + audio content digest).
    seen_ids: dict[str, str] = {}
    seen_titles: dict[str, str] = {}
    seen_content: dict[str, str] = {}
    for entry in member_entries:
        ident = f"{entry['source']}:{entry['identity']}"
        if ident in seen_ids:
            failures.append(f"duplicate member identity: {entry['rowId']} vs {seen_ids[ident]}")
        seen_ids[ident] = entry["rowId"]
        content = str(entry.get("contentSha256") or "")
        if content:
            if content in seen_content:
                failures.append(
                    f"cross-band duplicate member audio: {entry['rowId']} vs "
                    f"{seen_content[content]} (same bytes in two bands)"
                )
            seen_content[content] = entry["rowId"]
        nk = cc.normalize_track_key(entry.get("title", ""))
        if nk:
            if nk in seen_titles:
                failures.append(
                    f"duplicate member title (normalized): {entry['rowId']} vs {seen_titles[nk]}"
                )
            seen_titles[nk] = entry["rowId"]

    # 4. oa300 18-vs-14 row-basis reconciliation (report).
    for r in inputs["oa300_rows"]:
        if "bpm" not in r:
            raise HarnessError("oa300 fixture row without a bpm key - schema drift, HALT")
    sub100 = [r for r in inputs["oa300_rows"] if r.get("bpm") is not None and r["bpm"] < 100.0]
    report.append(
        f"oa300 reconciliation: fixture rows with bpm < 100: {len(sub100)} (census banded 14)"
    )
    doubled_bands: dict[str, int] = {}
    for r in sub100:
        b = band_of(2.0 * float(r["bpm"]))
        if b is not None and b != "sub-100":
            doubled_bands[b] = doubled_bands.get(b, 0) + 1
    report.append(
        f"oa300 reconciliation: doubled-value landing bands for the {len(sub100)} sub-100 "
        f"rows: {doubled_bands}. The census deltas (sub-100 -4, 140-160 +1, 160-175 +3) "
        "are consistent with the census having banded 4 of these rows at a doubled "
        "(full-tempo) value from a different value source - a row-basis difference, "
        "not a half-open-edge effect."
    )
    return failures, warnings, report


def cmd_audit(_args: argparse.Namespace) -> int:
    failures, warnings, report = run_audit()
    for line in report:
        print(line)
    for w in warnings:
        print(f"WARNING: {w}")
    if failures:
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1
    print(
        "audit clean: ledger integrity, batch-record validation, FR-59a.1 assertion, "
        "residual-overlap (all candidates, GiantSteps included), and duplicate checks all pass"
    )
    return 0


# ---------------------------------------------------------------------------
# emit-manifest
# ---------------------------------------------------------------------------


def _sentinel_label_index(inputs: dict) -> dict[str, Any]:
    """FR-59a.1-clean legacy labels (OA300 fixture values + as-entered tags),
    indexed for the signed section-3 "same recording" join: audio FINGERPRINT
    match first, exact-filename (basename) match as the documented fallback.

    Only labels inside either sentinel window can ever change a sentinel
    outcome, so only those rows are fingerprinted.
    """
    by_hash: dict[str, list[float]] = {}
    by_basename: dict[str, list[float]] = {}
    fingerprinted: list[tuple[list[float], float]] = []
    root = inputs.get("pool_audio_root")

    def valid(value: Any) -> float | None:
        if value is None:
            return None
        try:
            v = float(value)
        except (TypeError, ValueError):
            return None
        return v if math.isfinite(v) and v > 0 else None

    def in_sentinel_window(v: float) -> bool:
        return (SENTINEL_FULL[0] <= v < SENTINEL_FULL[1]) or (
            SENTINEL_HALF[0] <= v < SENTINEL_HALF[1]
        )

    def add_fingerprint(path: Path | None, label: float) -> None:
        if path is None or not in_sentinel_window(label) or not path.exists():
            return
        vec = FINGERPRINT_FN(str(path))
        if vec:
            fingerprinted.append((vec, label))

    for r in inputs["oa300_rows"]:
        v = valid(r.get("bpm"))
        if v is None or not r.get("filename"):
            continue
        by_basename.setdefault(str(r["filename"]), []).append(v)
        add_fingerprint(
            _safe_resolve(
                {"source": "oa300", "filename": r["filename"], "subdir": r.get("subdir")}, root
            ),
            v,
        )
    for r in inputs["tony_rows"]:
        v = valid(r.get("average_bpm"))
        if v is None:
            continue
        if r.get("basename"):
            by_basename.setdefault(str(r["basename"]), []).append(v)
        if r.get("local_path"):
            add_fingerprint(Path(str(r["local_path"])), v)
    for r in inputs["pool_rows"]:
        v = valid(r.get("fileMetadataBPM"))
        if v is None:
            continue
        if r.get("audioHash"):
            by_hash.setdefault(str(r["audioHash"]), []).append(v)
        name = Path(str(r.get("path", ""))).name
        if name:
            by_basename.setdefault(name, []).append(v)
        if root and r.get("path"):
            add_fingerprint(Path(root) / str(r["path"]), v)
    # Standardize the legacy cohort once and keep its statistics, so a member's
    # vector is standardized against the SAME reference at compare time. Raw
    # timbral cosine is degenerate (corpus_common DD #3 note).
    stats = cohort_stats([v for v, _ in fingerprinted])
    return {
        "by_hash": by_hash,
        "by_basename": by_basename,
        "fingerprinted": [(standardize(v, stats), label) for v, label in fingerprinted],
        "stats": stats,
    }


def member_legacy_labels(
    entry: dict, index: dict[str, Any], pool_audio_root: str | None
) -> list[float]:
    """Legacy labels for one corpus member under the signed section-3 join:
    fingerprint match FIRST (a re-encode is exactly what a byte hash misses),
    exact basename as the fallback, plus the member's own face-value tag."""
    labels: list[float] = []
    path = _safe_resolve(entry, pool_audio_root)
    if path is not None:
        raw = FINGERPRINT_FN(str(path))
        if raw:
            vec = standardize(raw, index["stats"])
            for other, label in index["fingerprinted"]:
                if cosine(vec, other) >= SENTINEL_SAME_RECORDING_COSINE:
                    labels.append(label)
    if entry["source"] == "pool":
        labels += index["by_hash"].get(str(entry["identity"]), [])
        basename = Path(str(entry.get("relPath", ""))).name
    elif entry["source"] == "tony":
        basename = Path(str(entry.get("localPath", ""))).name
    else:
        basename = str(entry.get("filename", ""))
    if basename:
        labels += index["by_basename"].get(basename, [])
    labels.append(float(entry["faceBPM"]))
    return labels


def cmd_emit_manifest(_args: argparse.Namespace) -> int:
    require_active_commitment()
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    n_band = _n_band()
    membership = _recompute_membership(pools, n_band)
    incomplete = [n for n in BAND_NAMES if len(membership[n]["members"]) < n_band]
    if incomplete:
        print("emit-manifest refused: corpus incomplete. Per-band progress:")
        for name in BAND_NAMES:
            print(f"  {name:10s} {len(membership[name]['members'])}/{n_band}")
        return 1

    failures, _warnings, _report = run_audit()
    if failures:
        print("emit-manifest refused: the shared audit is not clean.", file=sys.stderr)
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1

    inputs = load_inputs()
    index = _sentinel_label_index(inputs)
    by_row_id = {e["rowId"]: e for name in BAND_NAMES for e in pools["bands"][name]}

    entries = []
    sentinel_per_band = {name: 0 for name in BAND_NAMES}
    for name in BAND_NAMES:
        annotations = _load_all_annotations(name)
        for rid in membership[name]["members"]:
            entry = by_row_id[rid]
            ann = annotations[rid]
            verified = float(ann["verified_bpm"])
            labels = member_legacy_labels(entry, index, pools.get("pool_audio_root"))
            sentinel = is_octave_sentinel(verified, labels)
            if sentinel:
                sentinel_per_band[name] += 1
            sandbox: dict[str, Any] = {"band": name, "source": entry["source"]}
            if sentinel:
                sandbox["sentinel"] = "octave-sentinel"
            if ann.get("ambiguous"):
                sandbox["ambiguous"] = True
            entries.append(
                {
                    "file_metadata": {
                        "jams_version": "0.4.0",
                        "identifiers": {"row_id": rid},
                        "title": entry.get("title", ""),
                    },
                    "annotations": [
                        {
                            "namespace": "tempo",
                            "data": [
                                {"time": 0.0, "duration": 0.0, "value": verified, "confidence": 1.0}
                            ],
                            "annotation_metadata": {
                                "annotation_version": ANNOTATION_VERSION_TAG,
                                "data_source": "Story 12.7 hand verification (FR-59f option 1)",
                            },
                        }
                    ],
                    "sandbox": sandbox,
                }
            )

    manifest = {
        "corpus": "12-7-band-balanced-258",
        "annotation_version": ANNOTATION_VERSION_TAG,
        "protocol": PROTOCOL_POINTER,
        "degeneracy_note_175_plus": DEGENERACY_NOTE_175,
        "sentinel_per_band": sentinel_per_band,
        "entries": entries,
    }
    _write_json(MANIFEST_PATH, manifest)
    print(
        f"manifest written: {MANIFEST_PATH} ({len(entries)} tracks; sentinel per band "
        f"{sentinel_per_band})"
    )
    return 0


# ---------------------------------------------------------------------------
# signoff (finding 14): an audit-bound attestation, not a hand-editable marker
# ---------------------------------------------------------------------------


def attestation_digest(doc: dict) -> str:
    body = {k: v for k, v in doc.items() if k != "attestation_sha256"}
    return sha256_bytes(_json_bytes(body))


def validate_attestation(
    attestation_path: Path, commitment_path: Path, ledger_head_path: Path, n_band: int
) -> list[str]:
    """Shared with `train.py`: the training gate validates THIS, not the
    human-editable REVIEWER_SIGNOFF marker text."""
    failures: list[str] = []
    if not attestation_path.exists():
        return [f"signoff attestation {attestation_path.name} is absent"]
    try:
        doc = json.loads(attestation_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"signoff attestation is not valid JSON: {exc}"]
    if not isinstance(doc, dict):
        return ["signoff attestation is not an object"]
    try:
        assert_attestation_schema(doc)
    except PrivacyError as exc:
        return [f"signoff attestation schema: {exc}"]
    if doc.get("attestation_sha256") != attestation_digest(doc):
        failures.append("signoff attestation digest does not match its contents (hand-edited)")
    if not commitment_path.exists():
        failures.append("signoff attestation references a commitment that is absent")
    else:
        commitment = json.loads(commitment_path.read_text(encoding="utf-8"))
        if commitment.get("status") != STATUS_ACTIVE:
            failures.append("signoff attestation is bound to a commitment that is not active")
        if doc.get("commitment_sha256") != sha256_file(commitment_path):
            failures.append(
                "signoff attestation is bound to a different commitment than the one on disk"
            )
    if not ledger_head_path.exists():
        failures.append("signoff attestation references a ledger head artifact that is absent")
    else:
        head_doc = json.loads(ledger_head_path.read_text(encoding="utf-8"))
        if doc.get("annotation_ledger_head") != head_doc.get("head_sha256"):
            failures.append(
                "signoff attestation ledger head does not match the tracked ledger head"
            )
    if doc.get("audit_result") != "clean":
        failures.append(f"signoff attestation records audit_result {doc.get('audit_result')!r}")
    members = doc.get("members_per_band", {})
    short = [b for b in BAND_NAMES if int(members.get(b, 0)) < n_band]
    if short:
        failures.append(f"signoff attestation records bands below {n_band}: {short}")
    return failures


def cmd_signoff(_args: argparse.Namespace) -> int:
    _, commitment_sha = require_active_commitment()
    n_band = _n_band()
    failures, _warnings, _report = run_audit()
    if failures:
        print("signoff refused: the shared audit is not clean.", file=sys.stderr)
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1
    pools = _read_json(POOLS_PATH, "candidate pools")
    membership = _recompute_membership(pools, n_band)
    members_per_band = {name: len(membership[name]["members"]) for name in BAND_NAMES}
    short = [name for name in BAND_NAMES if members_per_band[name] < n_band]
    if short:
        print(f"signoff refused: bands below {n_band} verified members: {short}", file=sys.stderr)
        return 1
    head, _count = ledger_head()
    doc = {
        "schema_version": 1,
        "story": "12.7",
        "attested": date.today().isoformat(),
        "commitment_sha256": commitment_sha,
        "annotation_ledger_head": head,
        "audit_result": "clean",
        "members_per_band": members_per_band,
    }
    doc["attestation_sha256"] = attestation_digest(doc)
    gate_committed(doc, assert_attestation_schema)
    _write_json(ATTESTATION_JSON, doc)
    print(
        f"signoff attestation written: {ATTESTATION_JSON} (commitment {commitment_sha}, "
        f"ledger head {head}). The training gate validates this attestation, not the "
        "REVIEWER_SIGNOFF marker text."
    )
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_commit = sub.add_parser("commit-pools", help="build + commit the banded candidate pools")
    p_commit.add_argument(
        "--seed", type=int, default=None, help="master seed (recorded; random if omitted)"
    )
    p_commit.set_defaults(func=cmd_commit_pools)

    p_review = sub.add_parser(
        "prepare-review", help="generate the mandatory pre-commitment fingerprint review flags"
    )
    p_review.set_defaults(func=cmd_prepare_review)

    p_stage = sub.add_parser("stage-batch", help="stage the next blinded batch for a band")
    p_stage.add_argument("--band", required=True)
    p_stage.add_argument("--batch", type=int, default=None, help="expected batch index (validated)")
    p_stage.add_argument("--size", type=int, default=DEFAULT_BATCH_SIZE)
    p_stage.set_defaults(func=cmd_stage_batch)

    p_ingest = sub.add_parser("ingest", help="ingest operator annotations for a committed batch")
    p_ingest.add_argument("--band", required=True)
    p_ingest.add_argument("--batch", type=int, required=True)
    p_ingest.add_argument("--annotations", required=True, help="operator-filled CSV")
    p_ingest.add_argument(
        "--force",
        action="store_true",
        help="append a replacement ledger event for an already-anchored batch",
    )
    p_ingest.set_defaults(func=cmd_ingest)

    p_abandon = sub.add_parser("abandon", help="record a batch as abandoned (yields no members)")
    p_abandon.add_argument("--band", required=True)
    p_abandon.add_argument("--batch", type=int, required=True)
    p_abandon.add_argument("--reason", default="operator-abandoned")
    p_abandon.add_argument(
        "--force", action="store_true", help="discard an existing annotation record"
    )
    p_abandon.set_defaults(func=cmd_abandon)

    p_status = sub.add_parser("status", help="per-band progress + keeper-rate estimate")
    p_status.set_defaults(func=cmd_status)

    p_audit = sub.add_parser(
        "audit", help="fail-closed FR-59a.1 / residual-overlap / duplicate / ledger audit"
    )
    p_audit.set_defaults(func=cmd_audit)

    p_emit = sub.add_parser(
        "emit-manifest", help="emit the JAMS corpus manifest (refuses if incomplete or dirty)"
    )
    p_emit.set_defaults(func=cmd_emit_manifest)

    p_signoff = sub.add_parser(
        "signoff", help="record the audit-bound signoff attestation the training gate validates"
    )
    p_signoff.set_defaults(func=cmd_signoff)

    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except PrivacyError as exc:
        print(f"PRIVACY GATE FAILED: {exc}", file=sys.stderr)
        return 3
    except OperatorHalt as exc:
        print(f"HALT: {exc}", file=sys.stderr)
        return 4
    except DriftError as exc:
        print(f"DRIFT: {exc}", file=sys.stderr)
        return 2
    except HarnessError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
