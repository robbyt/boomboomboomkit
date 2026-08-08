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
exclusion, per-band seeded membership draw sequences cryptographically
committed, blinded batch staging (opaque row IDs, copied audio), DSP-free
keep/reject ingest with first-43-cumulative membership, a fail-closed audit,
and a JAMS manifest emitter carrying the section-5 annotation-version tag,
the octave-sentinel tags (section 3), and the 175+ degeneracy note.

Subcommands: commit-pools, stage-batch, ingest, status, audit, emit-manifest.

State lives under the gitignored `_bmad-output/ml-training/eval-corpus/`.
Committed artifacts carry counts, seeds, band names, and the named commitment
digests ONLY (q9 privacy rule); the row-level inventory never enters git.

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
from datetime import date
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)

ARTIFACTS_DIR = REPO_ROOT / "_bmad-output" / "implementation-artifacts"
EVAL_CORPUS_DIR = ML_TRAINING_DIR / "eval-corpus"
POOLS_PATH = EVAL_CORPUS_DIR / "candidate-pools.json"
DRAWS_PATH = EVAL_CORPUS_DIR / "draw-sequences.json"
MEMBERSHIP_PATH = EVAL_CORPUS_DIR / "membership.json"
BATCHES_DIR = EVAL_CORPUS_DIR / "batches"
ANNOTATIONS_DIR = EVAL_CORPUS_DIR / "annotations"
STAGING_DIR = EVAL_CORPUS_DIR / "staging"
MANIFEST_PATH = EVAL_CORPUS_DIR / "258-corpus.jams.json"
COMMITMENT_JSON = ARTIFACTS_DIR / "12-7-candidate-commitment.json"
COMMITMENT_MD = ARTIFACTS_DIR / "12-7-candidate-commitment.md"

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


class HarnessError(RuntimeError):
    """Fatal harness error (exit 1)."""


class PrivacyError(RuntimeError):
    """Privacy-gate violation in a committed artifact (exit 3, q9 convention)."""


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


# ---------------------------------------------------------------------------
# Pure logic: candidate construction + FR-59a.2 exclusion
# ---------------------------------------------------------------------------


def build_candidates(
    pool_rows: list[dict],
    tony_rows: list[dict],
    oa300_rows: list[dict],
    manifest_hashes: set[str],
    tony_split_ids: set[str],
    training_artist_keys: set[str],
) -> tuple[dict[str, list[dict]], dict[str, Any]]:
    """Band candidates by face-value tag only; exclude FR-59a.2 matches.

    Returns (bands, accounting). No DSP quantity is read: pool rows contribute
    ONLY `fileMetadataBPM` + identity fields, Tony rows ONLY `average_bpm`
    as-entered + identity, OA300 ONLY the fixture value + identity.
    """
    bands: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    tagless = {"pool": 0, "tony": 0, "oa300": 0}
    exclusions: dict[str, dict[str, int]] = {
        name: {"manifest-hash": 0, "tony-split": 0, "artist": 0, "audio-unresolved": 0}
        for name in BAND_NAMES
    }

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
        "artist_limitation": (
            "Pool rows carry no artist field, so artist-based FR-59a.2 exclusion is "
            "enforceable only for Tony rows; recorded as a limitation, compensated by "
            "the audit fingerprint pass."
        ),
    }
    return bands, accounting


# ---------------------------------------------------------------------------
# Pure logic: seeded draw sequences + opaque row IDs
# ---------------------------------------------------------------------------


def draw_sequence(band_index: int, rows: list[dict], seed: int) -> list[dict]:
    """One global per-band permutation from `random.Random(seed)`, with opaque
    row IDs `e<band-index>-<zero-padded position>-<4-hex salt>` minted from the
    same PRNG at commitment. Deterministic for a given (rows, seed)."""
    ordered = sorted(rows, key=lambda r: (r["source"], r["identity"]))
    rng = random.Random(seed)
    rng.shuffle(ordered)
    out = []
    for pos, row in enumerate(ordered):
        salt = f"{rng.getrandbits(16):04x}"
        entry = dict(row)
        entry["rowId"] = f"e{band_index}-{pos:04d}-{salt}"
        entry["sequencePosition"] = pos
        out.append(entry)
    return out


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
    surplus keepers recorded; duplicate tie-break by sequence position (the
    earlier row kept, the later rejected as duplicate). Reads ONLY the draw
    sequence and annotator-entered fields — no DSP quantity."""
    keepers: list[str] = []
    rejects: dict[str, dict] = {}
    kept_identities: set[str] = set()
    # Duplicate registration covers ALL annotated rows, kept or rejected: a
    # keeper is a duplicate when its dup tag names an earlier-annotated row or
    # group, OR an earlier-annotated row's dup tag names this keeper -
    # whichever side carries the tag, the earlier sequence position wins.
    prior_row_ids: set[str] = set()
    prior_dup_groups: set[str] = set()
    for entry in sequence:  # sequence order IS the tie-break order
        row_id = entry["rowId"]
        ann = annotations.get(row_id)
        if ann is None:
            continue
        keep, reason = keep_or_reject(ann, band)
        dup_group = str(ann.get("duplicate_of") or "").strip()
        if keep:
            identity = entry["identity"]
            dup_hit = bool(dup_group) and (
                dup_group in prior_row_ids or dup_group in prior_dup_groups
            )
            if identity in kept_identities or dup_hit or row_id in prior_dup_groups:
                keep, reason = False, "duplicate"
            else:
                kept_identities.add(identity)
                keepers.append(row_id)
        prior_row_ids.add(row_id)
        if dup_group:
            prior_dup_groups.add(dup_group)
        if keep:
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
# Privacy gate (q9 recursive-allowlist precedent; exit code 3)
# ---------------------------------------------------------------------------

# Path ROOTS are forbidden at ANY string length; bare slashes only in short
# label-like strings (prose legitimately contains slashes).
_FORBIDDEN_ROOTS = ("~", "$HOME", "Users/", "Volumes/")
_FORBIDDEN_SLASHES = ("/", "\\")
_AUDIO_EXTENSIONS = (".mp3", ".wav", ".m4a", ".flac", ".aiff", ".aif", ".ogg", ".caf")
# An extension counts wherever it appears followed by a non-alphanumeric or the
# end of string (".mp3.bak", "x.mp3, y.wav" all leak), not only at the end.
_AUDIO_EXT_RE = re.compile(r"\.(?:mp3|wav|m4a|flac|aiff|aif|ogg|caf)(?:$|[^a-z0-9])", re.IGNORECASE)
_HEX = set("0123456789abcdef")
# The sole permitted hashes: the named commitment digests.
_DIGEST_PATHS = ("/pool_file_sha256", "/draw_file_sha256")
_PATH_EXEMPT = ("/protocol", "/seed_algorithm", "/run_command")


def _looks_like_hash(text: str) -> bool:
    stripped = text.strip().lower()
    return len(stripped) >= 32 and all(ch in _HEX for ch in stripped)


def privacy_gate(doc: dict) -> None:
    """Recursive allowlist over a committed artifact: counts, seeds, band
    names, prose notes, and the two named commitment digests only. Raises
    PrivacyError on any row-level path, audio filename, or stray hash."""

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


# ---------------------------------------------------------------------------
# Digests + IO helpers
# ---------------------------------------------------------------------------


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


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

    splits = _read_json(CORPUS_SPLITS, "corpus_splits.json")
    tony_ns = splits.get("tony")
    if not isinstance(tony_ns, dict) or "train" not in tony_ns or "val" not in tony_ns:
        raise HarnessError("corpus_splits.json: schema drift - expected tony.train/tony.val")
    tony_split_ids = {str(t) for t in tony_ns["train"]} | {str(t) for t in tony_ns["val"]}

    by_id = {str(r.get("track_id")): r for r in tony["tracks"]}
    training_artist_keys = set()
    for tid in tony_split_ids:
        row = by_id.get(tid)
        if row is not None:
            key = cc.canonical_artist_key(row.get("artist"))
            if key:
                training_artist_keys.add(key)

    return {
        "pool_rows": survey["tracks"],
        "pool_audio_root": survey.get("audio_root"),
        "tony_rows": tony["tracks"],
        "oa300_rows": oa300_rows,
        "manifest_hashes": manifest_hashes,
        "tony_split_ids": tony_split_ids,
        "training_artist_keys": training_artist_keys,
    }


# ---------------------------------------------------------------------------
# commit-pools
# ---------------------------------------------------------------------------


def cmd_commit_pools(args: argparse.Namespace) -> int:
    inputs = load_inputs()

    existing = None
    if COMMITMENT_JSON.exists():
        existing = _read_json(COMMITMENT_JSON, "existing commitment")
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

    bands, accounting = build_candidates(
        inputs["pool_rows"],
        inputs["tony_rows"],
        inputs["oa300_rows"],
        inputs["manifest_hashes"],
        inputs["tony_split_ids"],
        inputs["training_artist_keys"],
    )

    seed_rng = random.Random(master_seed)
    band_seeds = {name: seed_rng.getrandbits(32) for name in BAND_NAMES}

    sequences: dict[str, list[dict]] = {}
    for i, name in enumerate(BAND_NAMES):
        sequences[name] = draw_sequence(i, bands[name], band_seeds[name])

    pools_doc = {
        "schema_version": 1,
        "bands": {name: sequences[name] for name in BAND_NAMES},
        "pool_audio_root": inputs["pool_audio_root"],
        "seeds": band_seeds,
        "master_seed": master_seed,
    }
    draws_doc = {
        "schema_version": 1,
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
        # never rewrite the committed digests. Verify what is on disk; when a
        # row-level file is missing, regenerate DETERMINISTICALLY from the
        # recorded master seed and restore ONLY if the regenerated bytes hash
        # to the committed digests.
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
                    print(
                        f"ERROR: commitment digest mismatch - committed {label} "
                        f"{recorded} != on-disk {actual} for {path.name}. Inputs or "
                        "the row-level file drifted since commitment; refusing to "
                        "overwrite.",
                        file=sys.stderr,
                    )
                    return 2
            else:
                regenerated = _json_bytes(doc)
                if sha256_bytes(regenerated) != recorded:
                    raise HarnessError(
                        f"cannot restore {path.name}: deterministic regeneration from "
                        f"the recorded master seed does not hash to the committed "
                        f"{label} ({recorded}) - the source inputs have drifted since "
                        "commitment. Refusing; the committed digests are never rewritten."
                    )
                _write_bytes_atomic(path, regenerated)
                restored = True
        state = "restored" if restored else "verified"
        print(
            f"commitment {state}: pool_file_sha256 {recorded_pool}, "
            f"draw_file_sha256 {recorded_draw}"
        )
        short = existing.get("short_bands", [])
        return 4 if short else 0

    _write_json(POOLS_PATH, pools_doc)
    _write_json(DRAWS_PATH, draws_doc)
    pool_sha = sha256_file(POOLS_PATH)
    draw_sha = sha256_file(DRAWS_PATH)

    band_counts = {name: len(sequences[name]) for name in BAND_NAMES}
    short_bands = [name for name in BAND_NAMES if band_counts[name] < N_BAND]

    commitment = {
        "schema_version": 1,
        "story": "12.7",
        "generated": date.today().isoformat(),
        "protocol": PROTOCOL_POINTER,
        "run_command": "make eval-corpus-pools",
        "seed_algorithm": SEED_ALGORITHM,
        "master_seed": master_seed,
        "n_band_target": N_BAND,
        "bands": {
            name: {
                "candidates": band_counts[name],
                "seed": band_seeds[name],
                "exclusions": accounting["exclusions"][name],
            }
            for name in BAND_NAMES
        },
        "tagless_by_source": accounting["tagless"],
        "artist_exclusion_limitation": accounting["artist_limitation"],
        "pool_file_sha256": pool_sha,
        "draw_file_sha256": draw_sha,
        "short_bands": short_bands,
    }
    try:
        privacy_gate(commitment)
    except PrivacyError as exc:
        print(f"PRIVACY GATE FAILED on commitment artifact: {exc}", file=sys.stderr)
        return 3
    _write_json(COMMITMENT_JSON, commitment)
    _write_text_atomic(COMMITMENT_MD, render_commitment_md(commitment))

    for name in BAND_NAMES:
        excl = accounting["exclusions"][name]
        print(f"  {name:9s} candidates={band_counts[name]:4d} exclusions={excl}")
    print(f"tag-less by source: {accounting['tagless']}")
    print(f"pool_file_sha256: {pool_sha}")
    if short_bands:
        print(
            "HALT: bands below the 43-candidate floor at commitment: "
            f"{', '.join(short_bands)}. Exhaustion escalation is the operator's "
            "(signed fallback order: Tony as-entered rows, then OA300; committed as "
            "a dated addendum before any DSP statistic is consulted). No auto-extension.",
            file=sys.stderr,
        )
        return 4
    return 0


def render_commitment_md(c: dict) -> str:
    lines = [
        "# Story 12.7: candidate-pool commitment record",
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
        "| Band | Candidates | manifest-hash | tony-split | artist | audio-unresolved | Seed |",
        "|---|---|---|---|---|---|---|",
    ]
    for name in BAND_NAMES:
        b = c["bands"][name]
        e = b["exclusions"]
        lines.append(
            f"| {name} | {b['candidates']} | {e['manifest-hash']} | {e['tony-split']} | "
            f"{e['artist']} | {e['audio-unresolved']} | {b['seed']} |"
        )
    t = c["tagless_by_source"]
    lines += [
        "",
        f"Tag-less rows excluded before banding (face-value banding requires a value): "
        f"pool {t['pool']}, tony {t['tony']}, oa300 {t['oa300']}. Tag-less rows carry no "
        "band, so these counts are per source.",
        "",
        f"Artist-exclusion limitation: {c['artist_exclusion_limitation']}",
        "",
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
            f"committed pools: {shortfalls}. The operator's next action is the signed "
            "fallback addendum (Tony as-entered rows, then OA300, banded by the same "
            "face-value rule, committed as a dated addendum before any DSP statistic "
            "about it is consulted). No auto-extension was performed.",
            "",
        ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# stage-batch
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
        raise HarnessError("OA300_CORPUS_PATH not set; cannot stage an oa300 row")
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
    raise HarnessError(f"cannot resolve oa300 audio for row {entry['rowId']}")


def _existing_batch_indices(band_batches: Path) -> list[int]:
    """Batch record indices, verified contiguous 0..n-1 (a gap means a record
    was deleted by hand; recomputing a shifted start would silently re-stage
    the wrong span)."""
    indices = sorted(
        int(m.group(1))
        for p in band_batches.glob("batch-*.json")
        if (m := re.fullmatch(r"batch-(\d{3})\.json", p.name))
    )
    if indices != list(range(len(indices))):
        raise HarnessError(
            f"batch records in {band_batches} are not contiguous: {indices} - a record "
            "is missing; restore it before staging further batches"
        )
    return indices


def _stage_copies(
    span: list[dict], stage_dir: Path, pool_audio_root: str | None
) -> list[tuple[str, str]]:
    """Copy audio as blinded, opaque-ID-named copies. Re-run safe: an existing
    destination whose size mismatches the source (interrupted copy) is recopied."""
    stage_dir.mkdir(parents=True, exist_ok=True)
    worklist_rows = []
    for entry in span:
        src_path = _resolve_audio(entry, pool_audio_root)
        if not src_path.exists():
            raise HarnessError(f"audio missing for row {entry['rowId']}: cannot stage blinded copy")
        dest = stage_dir / f"{entry['rowId']}{src_path.suffix.lower()}"
        if not dest.exists() or dest.stat().st_size != src_path.stat().st_size:
            shutil.copyfile(src_path, dest)
        worklist_rows.append((entry["rowId"], str(dest)))
    return worklist_rows


def cmd_stage_batch(args: argparse.Namespace) -> int:
    if args.band not in BAND_NAMES:
        raise HarnessError(f"unknown band {args.band!r}; bands: {', '.join(BAND_NAMES)}")
    if int(args.size) < 1:
        raise HarnessError(f"--size must be >= 1, got {args.size}")
    if not POOLS_PATH.exists() or not COMMITMENT_JSON.exists():
        raise HarnessError("pools are not committed - run commit-pools first")
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    sequence = _require(_require(pools, "bands", "candidate pools"), args.band, "candidate pools")

    band_batches = BATCHES_DIR / args.band
    band_batches.mkdir(parents=True, exist_ok=True)
    indices = _existing_batch_indices(band_batches)
    next_index = len(indices)
    by_row_id = {e["rowId"]: e for e in sequence}

    if args.batch is not None and int(args.batch) == next_index - 1:
        # Resume: re-stage the last recorded batch (record-then-stage means an
        # interrupted copy leaves a record; recopy repair completes it).
        record = _read_json(band_batches / f"batch-{next_index - 1:03d}.json", "batch record")
        span = [by_row_id[rid] for rid in _require(record, "rowIds", "batch record")]
        stage_dir = STAGING_DIR / args.band / f"batch-{next_index - 1:03d}"
        worklist_rows = _stage_copies(span, stage_dir, pools.get("pool_audio_root"))
        _write_worklist(band_batches / f"batch-{next_index - 1:03d}-worklist.csv", worklist_rows)
        print(f"re-staged batch {next_index - 1} for {args.band}: {len(span)} rows -> {stage_dir}")
        return 0
    if args.batch is not None and int(args.batch) != next_index:
        raise HarnessError(
            f"batch out of sequence: next batch for {args.band} is {next_index}, "
            f"requested {args.batch} (pass the previous index to re-stage it)"
        )
    start = sum(
        len(
            _require(
                _read_json(band_batches / f"batch-{i:03d}.json", "batch record"),
                "rowIds",
                "batch record",
            )
        )
        for i in indices
    )
    size = int(args.size)
    span = sequence[start : start + size]
    if not span:
        raise HarnessError(f"band {args.band} draw sequence exhausted at position {start}")

    # Record BEFORE staging (record-then-stage): an interrupted copy leaves a
    # batch record rather than orphan audio files; re-run with --batch <this
    # index> repairs the copies.
    _write_json(
        band_batches / f"batch-{next_index:03d}.json",
        {
            "band": args.band,
            "batch": next_index,
            "size": len(span),
            "start": start,
            "rowIds": [e["rowId"] for e in span],
        },
    )
    stage_dir = STAGING_DIR / args.band / f"batch-{next_index:03d}"
    worklist_rows = _stage_copies(span, stage_dir, pools.get("pool_audio_root"))
    worklist = band_batches / f"batch-{next_index:03d}-worklist.csv"
    _write_worklist(worklist, worklist_rows)
    print(
        f"staged batch {next_index} for {args.band}: {len(span)} rows -> {stage_dir}\n"
        f"worklist: {worklist}"
    )
    return 0


def _write_worklist(path: Path, rows: list[tuple[str, str]]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["row_id", "audio"])  # opaque ID + staged copy ONLY
        writer.writerows(rows)


# ---------------------------------------------------------------------------
# ingest
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


def _load_all_annotations(band: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    band_dir = ANNOTATIONS_DIR / band
    if band_dir.exists():
        for p in sorted(band_dir.glob("batch-*.json")):
            doc = _read_json(p, "annotation record")
            out.update(_require(doc, "rows", f"annotation record {p.name}"))
    return out


def _recompute_membership(pools: dict) -> dict:
    membership = {}
    for name in BAND_NAMES:
        annotations = _load_all_annotations(name)
        membership[name] = compute_membership(pools["bands"][name], annotations, name)
    return membership


def cmd_ingest(args: argparse.Namespace) -> int:
    if args.band not in BAND_NAMES:
        raise HarnessError(f"unknown band {args.band!r}")
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    batch_record_path = BATCHES_DIR / args.band / f"batch-{int(args.batch):03d}.json"
    batch = _read_json(batch_record_path, "batch record")
    annotations = parse_annotations_csv(
        Path(args.annotations), _require(batch, "rowIds", "batch record")
    )

    record_path = ANNOTATIONS_DIR / args.band / f"batch-{int(args.batch):03d}.json"
    meta: dict[str, Any] = {"band": args.band, "batch": int(args.batch)}
    if record_path.exists():
        if not args.force:
            raise HarnessError(
                f"annotation record {record_path.name} already exists for {args.band}; "
                "re-ingest requires --force (the prior record's sha256 is then kept as "
                "replaced_sha256)"
            )
        meta["replaced_sha256"] = sha256_file(record_path)
    _write_json(record_path, {"_meta": meta, "rows": annotations})
    membership = _recompute_membership(pools)
    _write_json(MEMBERSHIP_PATH, membership)
    m = membership[args.band]
    print(
        f"ingested batch {args.batch} for {args.band}: members {len(m['members'])}/{N_BAND}, "
        f"surplus {len(m['surplus'])}, rejects {len(m['rejects'])}, annotated {m['annotated']}"
    )
    return 0


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def cmd_status(_args: argparse.Namespace) -> int:
    if not POOLS_PATH.exists():
        print("pools not committed; run commit-pools first")
        return 0
    pools = _read_json(POOLS_PATH, "candidate pools")
    membership = _recompute_membership(pools)
    print(f"{'band':10s} {'members':>8s} {'annotated':>10s} {'rate':>6s} {'est-reviews':>12s}")
    for name in BAND_NAMES:
        m = membership[name]
        annotated = m["annotated"]
        kept = len(m["members"]) + len(m["surplus"])
        rate = kept / annotated if annotated else None
        est = math.ceil(N_BAND / rate) if rate else None
        print(
            f"{name:10s} {len(m['members']):>5d}/{N_BAND} {annotated:>10d} "
            f"{('%.2f' % rate) if rate is not None else '-':>6s} "
            f"{(str(est) if est is not None else '-'):>12s}"
        )
    return 0


# ---------------------------------------------------------------------------
# audit (fail-closed)
# ---------------------------------------------------------------------------


def _check_allowed_keys(
    mapping: dict, allowed: frozenset[str], where: str, failures: list[str]
) -> None:
    """FR-59a.1 fail-closed shape: membership inputs may contain ONLY the
    expected keys; anything unexpected (DSP-derived or otherwise) fails."""
    for key in mapping:
        if key not in allowed:
            failures.append(f"FR-59a.1: unexpected field {key!r} in {where}")


def cmd_audit(_args: argparse.Namespace) -> int:
    failures: list[str] = []
    warnings: list[str] = []

    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")

    # 1. FR-59a.1: membership inputs read only verified tempi + the draw
    # sequence. Allowlist every annotation record, candidate row, and worklist
    # header; an unexpected key fails, whatever it is called.
    for name in BAND_NAMES:
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

    # 2. FR-59a.2 residual overlap: re-assert no candidate (member or not)
    # matches the training corpus, and title-overlap members vs GiantSteps.
    inputs = load_inputs()
    membership = _recompute_membership(pools)
    member_entries: list[dict] = []
    by_row_id = {e["rowId"]: e for name in BAND_NAMES for e in pools["bands"][name]}
    for name in BAND_NAMES:
        for rid in membership[name]["members"]:
            member_entries.append(by_row_id[rid])
    for name in BAND_NAMES:
        for entry in pools["bands"][name]:
            if entry["source"] == "pool" and entry["identity"] in inputs["manifest_hashes"]:
                failures.append(f"residual manifest-hash overlap: candidate {entry['rowId']}")
            if entry["source"] == "tony":
                if entry["identity"] in inputs["tony_split_ids"]:
                    failures.append(f"residual tony-split overlap: candidate {entry['rowId']}")
                akey = cc.canonical_artist_key(entry.get("artist"))
                if akey and akey in inputs["training_artist_keys"]:
                    failures.append(f"residual training-artist overlap: candidate {entry['rowId']}")
    gs_path = cc.resolve_giantsteps_gt_path()
    if gs_path is not None and gs_path.exists():
        external = cc.build_external_index(giantsteps_gt_path=gs_path)
        gs_titles = {
            cc.normalize_track_key(t)
            for (c, t) in [(c, t) for hits in external.by_norm.values() for (c, t) in hits]
            if c == "giantsteps"
        }
        for entry in member_entries:
            nk = cc.normalize_track_key(entry.get("title", ""))
            if nk and nk in gs_titles:
                failures.append(f"residual GiantSteps title overlap: member {entry['rowId']}")
    else:
        warnings.append("GiantSteps GT not resolvable in this env; title-overlap pass skipped")

    # 3. Duplicate check among members (cross-band, by identity + normalized title).
    seen_ids: dict[str, str] = {}
    seen_titles: dict[str, str] = {}
    for entry in member_entries:
        ident = f"{entry['source']}:{entry['identity']}"
        if ident in seen_ids:
            failures.append(f"duplicate member identity: {entry['rowId']} vs {seen_ids[ident]}")
        seen_ids[ident] = entry["rowId"]
        nk = cc.normalize_track_key(entry.get("title", ""))
        if nk:
            if nk in seen_titles:
                failures.append(
                    f"duplicate member title (normalized): {entry['rowId']} vs {seen_titles[nk]}"
                )
            seen_titles[nk] = entry["rowId"]

    # 4. oa300 18-vs-14 row-basis reconciliation (report). The census banded
    # the fixture as 14 / 1 / 7 / 16 / 44 / 0; the fixture at face value bands
    # 18 / 1 / 7 / 15 / 41 / 0. A half-open edge at 100 cannot remove sub-100
    # rows, so test the value-basis hypothesis: sub-100 rows whose DOUBLED
    # value lands in the bands the census over-counts.
    for r in inputs["oa300_rows"]:
        if "bpm" not in r:
            raise HarnessError("oa300 fixture row without a bpm key - schema drift, HALT")
    sub100 = [r for r in inputs["oa300_rows"] if r.get("bpm") is not None and r["bpm"] < 100.0]
    print(f"oa300 reconciliation: fixture rows with bpm < 100: {len(sub100)} (census banded 14)")
    doubled_bands: dict[str, int] = {}
    for r in sub100:
        b = band_of(2.0 * float(r["bpm"]))
        if b is not None and b != "sub-100":
            doubled_bands[b] = doubled_bands.get(b, 0) + 1
    print(
        f"oa300 reconciliation: doubled-value landing bands for the {len(sub100)} sub-100 "
        f"rows: {doubled_bands}. The census deltas (sub-100 -4, 140-160 +1, 160-175 +3) "
        "are consistent with the census having banded 4 of these rows at a doubled "
        "(full-tempo) value from a different value source - a row-basis difference, "
        "not a half-open-edge effect."
    )

    for w in warnings:
        print(f"WARNING: {w}")
    if failures:
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1
    print("audit clean: FR-59a.1 assertion, residual-overlap, and duplicate checks all pass")
    return 0


# ---------------------------------------------------------------------------
# emit-manifest
# ---------------------------------------------------------------------------


def _legacy_label_index(inputs: dict) -> tuple[dict[str, list[float]], dict[str, list[float]]]:
    """FR-59a.1-clean legacy labels (OA300 fixture values + as-entered tags),
    joined per the signed section-3 "same recording" rule: audio-fingerprint
    match where both sides carry hashes (here: the survey audioHash), with
    EXACT-FILENAME (basename) match as the fallback. Normalized-title joins are
    NOT used on the sentinel path. Octave-corrected and training truth labels
    are excluded by construction (never loaded).

    Returns (by_audio_hash, by_basename)."""
    by_hash: dict[str, list[float]] = {}
    by_basename: dict[str, list[float]] = {}

    def valid(value: Any) -> float | None:
        if value is None:
            return None
        try:
            v = float(value)
        except (TypeError, ValueError):
            return None
        return v if math.isfinite(v) and v > 0 else None

    for r in inputs["oa300_rows"]:
        v = valid(r.get("bpm"))
        if v is not None and r.get("filename"):
            by_basename.setdefault(str(r["filename"]), []).append(v)
    for r in inputs["tony_rows"]:
        v = valid(r.get("average_bpm"))
        if v is not None and r.get("basename"):
            by_basename.setdefault(str(r["basename"]), []).append(v)
    for r in inputs["pool_rows"]:
        v = valid(r.get("fileMetadataBPM"))
        if v is None:
            continue
        if r.get("audioHash"):
            by_hash.setdefault(str(r["audioHash"]), []).append(v)
        name = Path(str(r.get("path", ""))).name
        if name:
            by_basename.setdefault(name, []).append(v)
    return by_hash, by_basename


def _member_legacy_labels(
    entry: dict, by_hash: dict[str, list[float]], by_basename: dict[str, list[float]]
) -> list[float]:
    """Legacy labels for one corpus member: audioHash exact match where both
    sides carry hashes (pool rows), else exact basename; plus the member's own
    face-value tag (itself an FR-59a.1-clean label of the same recording)."""
    labels: list[float] = []
    if entry["source"] == "pool":
        labels += by_hash.get(str(entry["identity"]), [])
    if entry["source"] == "pool":
        basename = Path(str(entry.get("relPath", ""))).name
    elif entry["source"] == "tony":
        basename = Path(str(entry.get("localPath", ""))).name
    else:
        basename = str(entry.get("filename", ""))
    if basename:
        labels += by_basename.get(basename, [])
    labels.append(float(entry["faceBPM"]))
    return labels


def cmd_emit_manifest(_args: argparse.Namespace) -> int:
    verify_committed_digest(POOLS_PATH, DRAWS_PATH, COMMITMENT_JSON)
    pools = _read_json(POOLS_PATH, "candidate pools")
    membership = _recompute_membership(pools)
    incomplete = [n for n in BAND_NAMES if len(membership[n]["members"]) < N_BAND]
    if incomplete:
        print("emit-manifest refused: corpus incomplete. Per-band progress:")
        for name in BAND_NAMES:
            print(f"  {name:10s} {len(membership[name]['members'])}/{N_BAND}")
        return 1

    inputs = load_inputs()
    by_hash, by_basename = _legacy_label_index(inputs)
    by_row_id = {e["rowId"]: e for name in BAND_NAMES for e in pools["bands"][name]}

    entries = []
    sentinel_per_band = {name: 0 for name in BAND_NAMES}
    for name in BAND_NAMES:
        annotations = _load_all_annotations(name)
        for rid in membership[name]["members"]:
            entry = by_row_id[rid]
            ann = annotations[rid]
            verified = float(ann["verified_bpm"])
            labels = _member_legacy_labels(entry, by_hash, by_basename)
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
        help="overwrite an existing batch annotation record (prior sha256 retained)",
    )
    p_ingest.set_defaults(func=cmd_ingest)

    p_status = sub.add_parser("status", help="per-band progress + keeper-rate estimate")
    p_status.set_defaults(func=cmd_status)

    p_audit = sub.add_parser(
        "audit", help="fail-closed FR-59a.1 / residual-overlap / duplicate audit"
    )
    p_audit.set_defaults(func=cmd_audit)

    p_emit = sub.add_parser(
        "emit-manifest", help="emit the JAMS corpus manifest (refuses if incomplete)"
    )
    p_emit.set_defaults(func=cmd_emit_manifest)

    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except PrivacyError as exc:
        print(f"PRIVACY GATE FAILED: {exc}", file=sys.stderr)
        return 3
    except HarnessError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
