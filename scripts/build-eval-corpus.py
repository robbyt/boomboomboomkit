#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""
Story 12.7 construction harness for the 258-track band-balanced evaluation
corpus (develop-only; NOT shipped to main).

Implements the SIGNED protocol in
`_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md`
sections 2, 3 and 6 literally: face-value-tag candidate pools with FR-59a.2
training-set exclusion (metadata AND the mandatory pre-commitment
audio-fingerprint route, which fails CLOSED), per-band seeded membership draw
sequences cryptographically committed, blinded batch staging, DSP-free
keep/reject ingest with first-43-cumulative membership recorded in an
append-only event store, the section-6 10 percent blind re-pass, a fail-closed
audit that gates emission and signoff, and a JAMS manifest emitter.

FR-59a.2 PARTITION ORDER (signed amendment 2026-08-11). Exactly ONE of the three
exclusion routes reverses direction, and only under the `repartition` short-band
policy: matching a row in the two non-Rekordbox TRAINING MANIFESTS by audio
content (`audioHash`) no longer removes a candidate from the eval draw. The eval
corpus draws it and the training REBUILD drops it, so a confirmed match is
ENUMERATED as a must-drop obligation instead of excluding the candidate. The
`corpus_splits.json` tony.train/tony.val recording-identity route and the
artist-string route are UNCHANGED and still exclude at candidate construction;
so does a confirmed fingerprint match whose training peer is a tony.train or
tony.val row, which is the recording-identity route by another name. Under every
other short-band policy the pre-amendment order is in force unchanged. The
invariant is untouched: no track, no remix, and no artist appears in both
corpora. The audit therefore becomes two gates. The mint-time OBLIGATION gate
this harness runs asserts every overlapping member is enumerated; it does not
assert that FR-59a.2 currently holds, and it is labelled as such. The
signoff-time CLOSURE gate, a fresh audit against the REBUILT training corpus, is
FR-59d work in a later story, and `signoff` refuses until it exists.

Structure (PR #197 round 2). Command handlers are thin: load state, validate,
plan, write immutable artifacts, validate again.

  * a PURE PLANNING layer (`plan_commit`, `plan_batch`, `plan_repass`) that
    returns a plan and writes nothing;
  * an IMMUTABLE EVENT STORE (`annotation-ledger.jsonl`, `repass-ledger.jsonl`)
    with explicit event kinds and an allowed-transition table;
  * a single `validate_state()` run BEFORE and AFTER every mutation.

Every private row-level path is generation-scoped under
`generations/<generation>/`, where the generation id is derived from the
committed pool + draw bytes and recorded in the commitment. Preserving an
archived commitment's JSON is not enough on its own: if the canonical row-level
files could be replaced in place, the archived chain would be unverifiable.

Subcommands: prepare-review, commit-pools, remint, stage-batch, ingest,
abandon, status, audit, emit-manifest, repass-sample, repass-ingest, signoff.

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
import statistics
import sys
from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)

# ---------------------------------------------------------------------------
# Paths. Generation-INDEPENDENT state + committed artifacts are module globals,
# rebindable through `configure_paths` so the command-level suite can drive the
# real commands against a synthetic corpus in `tmp_path`. Every row-level path
# is generation-SCOPED and reached only through the accessors below.
# ---------------------------------------------------------------------------

ARTIFACTS_DIR = REPO_ROOT / "_bmad-output" / "implementation-artifacts"
EVAL_CORPUS_DIR = ML_TRAINING_DIR / "eval-corpus"
REVIEW_FLAGS_PATH = EVAL_CORPUS_DIR / "fingerprint-review.json"
COVERAGE_PATH = EVAL_CORPUS_DIR / "fingerprint-coverage.json"
DISPOSITIONS_TEMPLATE_PATH = EVAL_CORPUS_DIR / "fingerprint-dispositions.template.json"
DISPOSITIONS_PATH = EVAL_CORPUS_DIR / "fingerprint-dispositions.json"
DECISIONS_PATH = EVAL_CORPUS_DIR / "12-7-operator-decisions.json"
COMMITMENT_JSON = ARTIFACTS_DIR / "12-7-candidate-commitment.json"
COMMITMENT_MD = ARTIFACTS_DIR / "12-7-candidate-commitment.md"
LEDGER_HEAD_JSON = ARTIFACTS_DIR / "12-7-annotation-ledger-head.json"
ATTESTATION_JSON = ARTIFACTS_DIR / "12-7-signoff-attestation.json"
ADDENDUM_JSON = ARTIFACTS_DIR / "12-7-fallback-addendum.json"


def configure_paths(state_root: Path, artifacts_dir: Path) -> None:
    """Rebind every generation-independent state + committed-artifact path."""
    global EVAL_CORPUS_DIR, REVIEW_FLAGS_PATH, COVERAGE_PATH
    global DISPOSITIONS_TEMPLATE_PATH, DISPOSITIONS_PATH, DECISIONS_PATH
    global ARTIFACTS_DIR, COMMITMENT_JSON, COMMITMENT_MD, LEDGER_HEAD_JSON
    global ATTESTATION_JSON, ADDENDUM_JSON
    EVAL_CORPUS_DIR = state_root
    REVIEW_FLAGS_PATH = state_root / "fingerprint-review.json"
    COVERAGE_PATH = state_root / "fingerprint-coverage.json"
    DISPOSITIONS_TEMPLATE_PATH = state_root / "fingerprint-dispositions.template.json"
    DISPOSITIONS_PATH = state_root / "fingerprint-dispositions.json"
    DECISIONS_PATH = state_root / "12-7-operator-decisions.json"
    ARTIFACTS_DIR = artifacts_dir
    COMMITMENT_JSON = artifacts_dir / "12-7-candidate-commitment.json"
    COMMITMENT_MD = artifacts_dir / "12-7-candidate-commitment.md"
    LEDGER_HEAD_JSON = artifacts_dir / "12-7-annotation-ledger-head.json"
    ATTESTATION_JSON = artifacts_dir / "12-7-signoff-attestation.json"
    ADDENDUM_JSON = artifacts_dir / "12-7-fallback-addendum.json"


def generation_root(generation: str) -> Path:
    return EVAL_CORPUS_DIR / "generations" / generation


def pools_path(generation: str) -> Path:
    return generation_root(generation) / "candidate-pools.json"


def draws_path(generation: str) -> Path:
    return generation_root(generation) / "draw-sequences.json"


def batches_dir(generation: str) -> Path:
    return generation_root(generation) / "batches"


def annotations_dir(generation: str) -> Path:
    return generation_root(generation) / "annotations"


def staging_dir(generation: str) -> Path:
    return generation_root(generation) / "staging"


def membership_path(generation: str) -> Path:
    return generation_root(generation) / "membership.json"


def ledger_path(generation: str) -> Path:
    return generation_root(generation) / "annotation-ledger.jsonl"


def repass_dir(generation: str) -> Path:
    return generation_root(generation) / "repass"


def repass_ledger_path(generation: str) -> Path:
    return repass_dir(generation) / "repass-ledger.jsonl"


# Row-level must-drop obligations are PRIVATE and follow the coverage pattern:
# gitignored sidecars, only their digests and counts in git. `_DIGEST_PATHS`
# matches EXACT json paths, so `/must_drop/0/...` can never be allowlisted, and a
# bare `audioHash` row id is hash-shaped and trips the gate on its own.
#
# GENERATION-SCOPED, unlike the coverage record: the commitment PINS
# `must_drop_sha256`, and an archived predecessor's pinned digest has to stay
# verifiable. A state-root file would be clobbered by the next re-mint and make
# every archived commitment unverifiable, which is the exact failure the
# generation scoping of pools and draws already exists to prevent.
def must_drop_path(generation: str) -> Path:
    """The MINT-TIME obligation universe over candidates (digest pinned)."""
    return generation_root(generation) / "must-drop-obligation.json"


def must_drop_members_path(generation: str) -> Path:
    """The MEMBER-scoped provisional list, regenerated by a clean audit."""
    return generation_root(generation) / "must-drop-members.json"


def partition_closure_path(generation: str) -> Path:
    """The FR-59d closure record. Absent until a later story writes it; it is the
    forward path out of the signoff refusal and is deliberately NOT a mutation of
    the minted commitment, which is immutable."""
    return generation_root(generation) / "partition-closure.json"


def archive_path(digest: str, generated: str) -> Path:
    """Where a superseded commitment's byte-for-byte copy is kept (committed)."""
    return ARTIFACTS_DIR / f"12-7-candidate-commitment.{generated}.{digest[:12]}.json"


SURVEY_PATH = ML_TRAINING_DIR / "non-rekordbox-survey.json"
TONY_SURVEY_PATH = ML_TRAINING_DIR / "tony-corpus" / "tony-survey.json"
OA300_GT_PATH = cc.OA300_GT_PATH
SECONDARY_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-secondary-supervised-manifest.json"
UNSUPERVISED_MANIFEST = ML_TRAINING_DIR / "non-rekordbox-unsupervised-pretrain-manifest.json"
CORPUS_SPLITS = ML_TRAINING_DIR / "corpus_splits.json"
# The training inputs a fingerprint disposition adjudicates against, pinned
# per FILE. One opaque digest over all three could only ever report "something
# moved"; after the FR-59d rebuild the raise has to name WHICH manifest moved.
TRAINING_INPUT_NAMES = (
    SECONDARY_MANIFEST.name,
    UNSUPERVISED_MANIFEST.name,
    CORPUS_SPLITS.name,
)


def training_input_paths() -> tuple[Path, ...]:
    """Resolved at CALL time, not frozen at import.

    A module-level tuple of Path objects captures whatever the constants pointed
    at when the module loaded, so redirecting `SECONDARY_MANIFEST` (a test, or
    the FR-59d rebuild pointing at rebuilt manifests) would silently keep
    digesting the originals while every other reader followed the redirect.
    """
    return (SECONDARY_MANIFEST, UNSUPERVISED_MANIFEST, CORPUS_SPLITS)


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

# Explicit transition table for the primary-annotation state machine. The key is
# the CURRENT status of a (band, batch) - None when no event exists yet - and
# the value is every status that may follow. `abandoned` is terminal: the signed
# rule is that an abandoned batch yields no members, and re-opening one would
# make that reversible by a later append.
EVENT_TRANSITIONS: dict[str | None, frozenset[str]] = {
    None: frozenset({LEDGER_COMPLETED, LEDGER_ABANDONED}),
    LEDGER_COMPLETED: frozenset({LEDGER_REPLACEMENT, LEDGER_ABANDONED}),
    LEDGER_REPLACEMENT: frozenset({LEDGER_REPLACEMENT, LEDGER_ABANDONED}),
    LEDGER_ABANDONED: frozenset(),
}

# The section-6 blind re-pass runs its own state machine, deliberately NOT the
# primary one: a re-pass never feeds `compute_membership`, never replaces a
# primary annotation, and never appends an ordinary batch event.
REPASS_SAMPLED = "repass-sampled"
REPASS_INGESTED = "repass-ingested"
REPASS_STATUSES = (REPASS_SAMPLED, REPASS_INGESTED)
REPASS_TRANSITIONS: dict[str | None, frozenset[str]] = {
    None: frozenset({REPASS_SAMPLED}),
    REPASS_SAMPLED: frozenset({REPASS_INGESTED}),
    REPASS_INGESTED: frozenset(),
}

# Section 6, signoff 2026-08-08: "a random sample of roughly 26 kept tracks".
REPASS_FRACTION = 0.10
# Operator clarification 2026-08-11 (two-tier disagreement). A metrical-level
# disagreement is an OCTAVE-RATIO criterion, not the phrase "half/double": the
# second reading lies within +/-4 percent of 2x or 0.5x the first. A fine
# disagreement is a same-level absolute difference above 0.5 BPM - conservative,
# because two-decimal RECORDING precision does not imply two-decimal measurement
# accuracy after a manual 32-beat lock. There is NO pass/fail threshold: the
# signed text says the rate is RECORDED, and a gate would be a new bound item
# requiring its own signature.
REPASS_OCTAVE_TOLERANCE = 0.04
REPASS_FINE_TOLERANCE_BPM = 0.5

# Review-flag cosine threshold, matching the audit-corpus-splits.py DD #3
# precedent (NEAR_DUP_REVIEW = 0.97). The algorithm FLAGS; a recorded human
# disposition is what DISPOSES, so the coarse-signature blind spot never
# auto-removes a track and never auto-clears one either. What a confirmation
# then does depends on the partition order in force: under the pre-amendment
# order it excludes the candidate; under the signed 2026-08-11 `repartition`
# order a confirmed match against a training-MANIFEST row instead ENUMERATES
# what the training rebuild must drop, while a confirmed match against a
# tony.train or tony.val row still excludes.
FINGERPRINT_REVIEW_COSINE = 0.97
SENTINEL_SAME_RECORDING_COSINE = 0.97

DISPOSITION_SAME = "same-recording"
DISPOSITION_NOT_SAME = "not-same-recording"
DISPOSITION_VALUES = (DISPOSITION_SAME, DISPOSITION_NOT_SAME)
FLAG_KIND_FINGERPRINT = "training-fingerprint"
FLAG_KIND_GIANTSTEPS = "giantsteps-title"
FLAG_KIND_CROSS_BAND = "cross-band-recording"

# `repartition` is the signed 2026-08-11 amendment's policy: the short bands are
# built by REVERSING one FR-59a.2 route rather than by an addendum or by
# shrinking. It is the ONLY value that changes candidate construction.
SHORT_BAND_REPARTITION = "repartition"
SHORT_BAND_POLICIES = ("fallback-addendum", "shrink-corpus", SHORT_BAND_REPARTITION)
CROSS_BAND_POLICIES = ("pre-commitment-recording-dedup", "audit-fails-on-cross-band-duplicate")

# Training-row key namespaces, as `fingerprint_coverage` mints them. Only the
# `manifest` namespace is affected by the amendment.
TRAINING_SOURCE_MANIFEST = "manifest"
TRAINING_SOURCE_TONY_SPLIT = "tony-split"

# How a retained candidate acquired its must-drop obligation. One candidate can
# acquire the SAME obligation by more than one route - a retained manifest-hash
# row IS the training row, so it also fingerprints against itself at cosine 1.0 -
# so obligations are deduplicated on (candidate_key, training row) and carry
# every route that found them, ordered by this precedence. Metadata routes come
# first: they are content-addressed and exact, where the fingerprint route is a
# thresholded similarity that a human then adjudicates.
OBLIGATION_ROUTE_MANIFEST = "manifest-hash"
OBLIGATION_ROUTE_MANIFEST_CONTENT = "manifest-content"
OBLIGATION_ROUTE_FINGERPRINT = "training-fingerprint"
OBLIGATION_ROUTE_PRECEDENCE = (
    OBLIGATION_ROUTE_MANIFEST,
    OBLIGATION_ROUTE_MANIFEST_CONTENT,
    OBLIGATION_ROUTE_FINGERPRINT,
)

OBLIGATION_STATUS_PROVISIONAL = "provisional"
OBLIGATION_STATUS_NOT_APPLICABLE = "not-applicable"
PARTITION_ROUTE_REVERSED = "non-Rekordbox training manifest audioHash"

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
    "fingerprint-uncoverable",
    "fingerprint-confirmed",
    "cross-band-duplicate",
)

# Reason-stratified fingerprint coverage (finding B). `decode-failed`,
# `too-short` and `non-finite` are separated by
# `corpus_common.compute_fingerprint_with_reason`, which is the single decode
# implementation both this harness and the audit share.
COVERAGE_REASONS = (
    "resolved",
    "unresolved-path",
    "missing-file",
    "decode-failed",
    "too-short",
    "non-finite",
    "metadata-excluded",
    # A training-manifest row that carries NO path field at all. It never reached
    # the fingerprint stage, so before this reason existed it was absent from the
    # coverage denominators entirely and `assert_training_coverage` could not
    # block on it: uncoverable rows read as a clean pass.
    "no-path",
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
        "recordingGroup",
        "origin",
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
ALLOWED_ANNOTATION_META_KEYS = frozenset({"band", "batch", "version", "supersedes_sha256"})
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
    "training manifests by audio content, and every confirmed match is DISPOSED OF before "
    "minting. What disposal means depends on the recorded partition order. Under the "
    "pre-amendment order a confirmed match excludes the candidate. Under the signed "
    "2026-08-11 repartition order a confirmed match against a training-MANIFEST row "
    "instead retains the candidate and enumerates the training row the rebuild must drop, "
    "while a confirmed match against a tony.train or tony.val row still excludes. The "
    "residual gap is the same either way: a training track by the same artist that is a "
    "DIFFERENT recording, which artist-string exclusion would have removed and "
    "fingerprinting deliberately does not."
)

PARTITION_OBLIGATION_NOTE = (
    "Signed amendment 2026-08-11 (FR-59a.2 partition ORDER). Under the repartition policy "
    "one exclusion route reverses: a candidate matching a non-Rekordbox TRAINING MANIFEST "
    "by audioHash is drawn into the eval corpus, and the training rebuild drops it. The "
    "tony.train and tony.val recording-identity route and the artist-string route are "
    "unchanged and still exclude at candidate construction. The counts here are the "
    "MINT-TIME obligation universe over candidates; the list bound at signoff is derived "
    "from the final MEMBER roster, because dropping training rows for candidates that were "
    "rejected or ended up surplus would starve training for nothing. Row-level entries are "
    "private and live in a gitignored sidecar; only this digest and these counts are "
    "committed."
)

PARTITION_CLOSURE_NOTE = (
    "FR-59a.2 has two gates under the signed 2026-08-11 amendment. The mint-time OBLIGATION "
    "gate asserts every overlapping eval member is enumerated on the must-drop list; it "
    "does not assert the partition currently holds. The signoff-time CLOSURE gate is a "
    "fresh audit against the REBUILT training corpus, which re-runs the full comparison "
    "rather than confirming the listed rows disappeared, because a rebuild can introduce a "
    "re-encode that was never on the list. The rebuild is FR-59d work in a later story, so "
    "closure cannot be certified here and signoff refuses while the obligation is open."
)

MUST_DROP_NOTE = (
    "Row-level FR-59a.2 must-drop obligations (PRIVATE, gitignored). Each entry names an "
    "eval row and the training row the rebuild must drop, identified STRUCTURALLY by "
    "namespace and row id rather than by prose evidence, so the list is machine-checkable. "
    "The list is provisional until signoff binds it to the final member set, and it binds "
    "the eval commitment digest, the per-file training-input digests it was computed "
    "against, the fingerprint method, and the dispositions digest."
)

LEDGER_INTEGRITY_NOTE = (
    "The annotation ledger provides INTEGRITY, not backup or recovery. It detects "
    "editing, deletion, reordering, and stale-file reuse of annotation state; it cannot "
    "restore a lost annotation, and these labels cannot be regenerated. Annotation "
    "records are immutable and versioned: no command overwrites or unlinks one."
)

FALLBACK_EMPTY_NOTE = (
    "The signed exhaustion fallback source order is Tony as-entered rows, then OA300 "
    "rows. Both are already inside the primary pools, so the addendum's NET NEW set is "
    "empty by construction: enumerating it recovers nothing for any band. A short band "
    "still HALTS. This is reported rather than inferred so the operator can see it."
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


TRAINING_KEY_SOURCES = (TRAINING_SOURCE_MANIFEST, TRAINING_SOURCE_TONY_SPLIT)


def training_row_key(key: str) -> dict[str, str]:
    """Structured form of a training-row key (`manifest:<audioHash>` or
    `tony-split:<track_id>`, exactly as `fingerprint_coverage` mints them).

    The signed amendment requires the training peer of an obligation to be
    identified STRUCTURALLY, never as prose evidence: a string like
    "standardized cosine 0.9812 vs manifest:abc" cannot back a machine-checkable
    must-drop list, and the rebuild has to be able to join on the row id.

    The namespace is VALIDATED against the closed source set. `apply_dispositions`
    routes exclude-versus-enumerate on it, and the field round-trips through an
    operator-editable template, so an unrecognized namespace must fail loudly
    rather than fall through to a branch by accident.
    """
    text = str(key)
    source, sep, row_id = text.partition(":")
    if not sep or source not in TRAINING_KEY_SOURCES or not row_id:
        raise HarnessError(
            f"training row key {text!r} is malformed: expected "
            f"'<namespace>:<row id>' with the namespace one of "
            f"{list(TRAINING_KEY_SOURCES)}"
        )
    return {"source": source, "row_id": row_id, "key": text}


def _obligation(candidate_key_value: str, band: str, route: str, training: dict) -> dict:
    return {
        "candidate_key": candidate_key_value,
        "band": band,
        "routes": [route],
        "training_key": dict(training),
    }


def dedup_obligations(rows: list[dict]) -> list[dict]:
    """One obligation per (candidate, training row), carrying every route.

    A retained manifest-hash candidate IS the training row it matched, so it
    fingerprints against itself at cosine 1.0 and the confirmed flag records the
    SAME pair a second time. Left undeduplicated that doubled `must_drop_count`,
    which is pinned in the immutable commitment and which the FR-59d rebuild
    joins on.
    """
    merged: dict[tuple[str, str], dict] = {}
    for row in rows:
        key = (str(row["candidate_key"]), str(row["training_key"]["key"]))
        existing = merged.get(key)
        if existing is None:
            merged[key] = {**row, "routes": list(row["routes"])}
            continue
        for route in row["routes"]:
            if route not in existing["routes"]:
                existing["routes"].append(route)
    out = list(merged.values())
    for row in out:
        row["routes"].sort(
            key=lambda r: (
                OBLIGATION_ROUTE_PRECEDENCE.index(r)
                if r in OBLIGATION_ROUTE_PRECEDENCE
                else len(OBLIGATION_ROUTE_PRECEDENCE)
            )
        )
    out.sort(key=lambda row: (row["candidate_key"], row["training_key"]["key"]))
    return out


def build_candidates(
    pool_rows: list[dict],
    tony_rows: list[dict],
    oa300_rows: list[dict],
    manifest_hashes: set[str],
    tony_split_ids: set[str],
    training_artist_keys: set[str],
    *,
    retain_manifest_matches: bool = False,
) -> tuple[dict[str, list[dict]], dict[str, Any]]:
    """Band candidates by face-value tag only; exclude FR-59a.2 metadata matches.

    Returns (bands, accounting). No DSP quantity is read: pool rows contribute
    ONLY `fileMetadataBPM` + identity fields, Tony rows ONLY `average_bpm`
    as-entered + identity, OA300 ONLY the fixture value + identity. The
    fingerprint route (signed section 2) runs as a separate, mandatory
    pre-commitment stage; see `prepare-review` and `fingerprint_route`.

    `retain_manifest_matches` is the signed 2026-08-11 amendment, and it moves
    EXACTLY ONE route. When it is set, a pool row whose `audioHash` appears in a
    non-Rekordbox training manifest is KEPT as a candidate and the match is
    recorded as a partition obligation the training rebuild must honour; its
    `manifest-hash` exclusion count stays 0 rather than being removed from the
    reason set, because that key set is a frozen schema. The `tony-split` and
    `artist` routes below are UNCHANGED under either setting: they still exclude
    at candidate construction, so no track, remix, or artist crosses the two
    corpora. The flag is derived on both the prepare-review and the mint path by
    `retain_training_manifest_matches`, so `candidate_universe_sha256` cannot
    diverge between them.
    """
    bands: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    tagless = {"pool": 0, "tony": 0, "oa300": 0}
    exclusions = _empty_exclusions()
    obligations: list[dict] = []

    for row in pool_rows:
        face = row.get("fileMetadataBPM")
        band = band_of(face)
        if band is None:
            tagless["pool"] += 1
            continue
        audio_hash = str(row.get("audioHash", ""))
        in_manifest = audio_hash in manifest_hashes
        if in_manifest and not retain_manifest_matches:
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
        if in_manifest:
            obligations.append(
                _obligation(
                    f"pool:{audio_hash}",
                    band,
                    OBLIGATION_ROUTE_MANIFEST,
                    training_row_key(f"{TRAINING_SOURCE_MANIFEST}:{audio_hash}"),
                )
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
            # recorded rather than deadlocking a batch later.
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
        # Empty unless the reversed route is in force. These are candidate-level
        # and provisional; the list bound at signoff is member-scoped.
        "partition_obligations": obligations,
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


def candidate_key(entry: dict) -> str:
    return f"{entry['source']}:{entry['identity']}"


# ---------------------------------------------------------------------------
# Content binding: every candidate row carries a byte digest of the audio it
# names, so identity is content-bound for Tony (track_id) and OA300 (filename)
# rows as well as pool rows. Runs BEFORE the fingerprint route, so a row that
# cannot be staged safely is already gone by the time review flags are built.
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
    """Cross-band recording-level dedup (operator policy
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
            key = recording_groups.get(candidate_key(entry), entry.get("contentSha256", ""))
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


def draw_sequence(
    band_index: int, rows: list[dict], seed: int, offset: int = 0, origin: str = "primary"
) -> list[dict]:
    """One global per-band permutation from `random.Random(seed)`.

    Row IDs are `e<band-index>-<12 hex>` minted from the same PRNG. The ID
    carries NO draw position: a position-encoding ID plus a sequence-ordered
    worklist told an annotator who knows the first-43 rule which rows were
    likely members. `sequencePosition` stays in the gitignored row-level pool,
    which is never annotator-facing.

    `offset` and `origin` exist for the signed exhaustion fallback: an addendum
    sequence is appended AFTER the exhausted one and keeps globally increasing
    sequence positions.
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
        entry["sequencePosition"] = pos + offset
        entry["origin"] = origin
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
    including duplicate resolution. The signed criterion is "not a duplicate/
    re-encode of a track already KEPT", so an earlier audio-defect or
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
# Pure logic: two-tier re-pass disagreement (operator clarification 2026-08-11)
# ---------------------------------------------------------------------------

REPASS_AGREE = "agree"
REPASS_FINE = "fine-disagreement"
REPASS_METRICAL = "metrical-level-disagreement"
REPASS_NON_COMPARABLE = "non-comparable"


def classify_repass(first: float | None, second: float | None) -> str:
    """Two-tier classification of a blind re-pass reading against the primary.

    `non-comparable` is reserved for NO USABLE NUMERIC RESULT (unstable,
    irresolvable, or audio-defect on either pass). A stable numeric second
    reading that falls outside the track's original band is still comparable;
    the caller additionally flags `crossed_band`.
    """
    if first is None or second is None:
        return REPASS_NON_COMPARABLE
    if not (math.isfinite(first) and math.isfinite(second)) or first <= 0 or second <= 0:
        return REPASS_NON_COMPARABLE
    ratio = second / first
    for target in (2.0, 0.5):
        if abs(ratio - target) <= REPASS_OCTAVE_TOLERANCE * target:
            return REPASS_METRICAL
    if abs(second - first) > REPASS_FINE_TOLERANCE_BPM:
        return REPASS_FINE
    return REPASS_AGREE


# ---------------------------------------------------------------------------
# Fingerprint seam (injectable so tests never decode audio)
# ---------------------------------------------------------------------------


_FP_MEMO: dict[str, list[float] | None] = {}
_FP_REASON_MEMO: dict[str, str] = {}
_FP_DISK_CACHE: dict[str, list[float]] | None = None
_FP_DISK_DIRTY = False


def _load_fingerprint_cache() -> dict[str, list[float]]:
    """The method-versioned npz cache `scripts/audit-corpus-splits.py` maintains.

    Reusing it matters: the review fingerprints every candidate AND every
    training row, which is thousands of decodes. A method change invalidates the
    stale vectors, exactly as in the audit.
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


def assert_fingerprint_backend() -> None:
    """A missing decode backend is an ENVIRONMENT failure, raised immediately.

    Before this existed, `compute_fingerprint` returned None for every file when
    librosa was absent, `if vec:` absorbed it, and the mandatory route recorded
    `"flags": 0` - indistinguishable from "ran, found nothing". The mandatory
    route may not run at all without a working backend.
    """
    try:
        import librosa  # noqa: F401,PLC0415  (availability probe only)
    except Exception as exc:  # noqa: BLE001 - any import failure is fatal here
        raise HarnessError(
            "FINGERPRINT BACKEND UNAVAILABLE: librosa cannot be imported "
            f"({exc.__class__.__name__}: {exc}). The signed section-2 audio-fingerprint "
            "exclusion route is MANDATORY and cannot run without a decode backend. This "
            "is an environment failure, not an empty flag set: run "
            "`uv sync` in _bmad-output/ml-training and re-run. Refusing to proceed."
        ) from exc


def _default_fingerprint_reason(path: str) -> str:
    if path in _FP_REASON_MEMO:
        return _FP_REASON_MEMO[path]
    _, reason = cc.compute_fingerprint_with_reason(path)
    _FP_REASON_MEMO[path] = reason
    return reason


def _default_fingerprint(path: str) -> list[float] | None:
    global _FP_DISK_DIRTY
    if path in _FP_MEMO:
        return _FP_MEMO[path]
    cache = _load_fingerprint_cache()
    key = cc.content_hash(path)
    if key in cache:
        _FP_MEMO[path] = cache[key]
        return cache[key]
    vec, reason = cc.compute_fingerprint_with_reason(path)
    _FP_REASON_MEMO[path] = reason
    result = None if vec is None else [float(x) for x in vec]
    if result is not None:
        cache[key] = result
        _FP_DISK_DIRTY = True
    _FP_MEMO[path] = result
    return result


FINGERPRINT_FN: Callable[[str], list[float] | None] = _default_fingerprint
FINGERPRINT_REASON_FN: Callable[[str], str] = _default_fingerprint_reason
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
# Union-find over confirmed same-recording pairs.
#
# Writing `recording_groups[key] = group` per flag with no merge was wrong: with
# A-B then B-C confirmed, B is overwritten and the result is A->g1, B->g2,
# C->g2, so A and B both survive a confirmation that they are the same
# recording. Which flag won was decided by sha256 sort order.
# ---------------------------------------------------------------------------


def union_recording_groups(
    edges: list[tuple[str, str]], supplied: dict[str, str]
) -> dict[str, str]:
    """Transitive same-recording components over confirmed pair edges.

    `supplied` maps a member key to an operator-supplied group id. All supplied
    ids inside one component must agree; a component with none gets a
    deterministic id derived from its sorted member keys.
    """
    parent: dict[str, str] = {}

    def find(x: str) -> str:
        parent.setdefault(x, x)
        root = x
        while parent[root] != root:
            root = parent[root]
        while parent[x] != root:  # path compression
            parent[x], x = root, parent[x]
        return root

    def union(a: str, b: str) -> None:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[max(ra, rb)] = min(ra, rb)

    for left, right in edges:
        union(left, right)
    for key in supplied:
        find(key)

    components: dict[str, list[str]] = {}
    for key in parent:
        components.setdefault(find(key), []).append(key)

    groups: dict[str, str] = {}
    for members in components.values():
        members.sort()
        ids = sorted({supplied[m] for m in members if supplied.get(m)})
        if len(ids) > 1:
            raise HarnessError(
                "fingerprint dispositions assign conflicting recording_group ids "
                f"{ids} inside one confirmed same-recording component of "
                f"{len(members)} row(s). A component is one recording; give its rows "
                "one id or leave them all blank."
            )
        group = ids[0] if ids else "rg-" + sha256_bytes(_json_bytes({"c": members}))[:16]
        for m in members:
            groups[m] = group
    return groups


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
        "/supersedes_sha256",
        "/annotation_ledger_head",
        "/attestation_sha256",
        "/repass/record_sha256",
        "/repass/population_sha256",
        "/repass/sample_sha256",
        "/fingerprint_review/dispositions_sha256",
        "/fingerprint_review/candidate_universe_sha256",
        "/fingerprint_review/training_input_sha256",
        "/fingerprint_review/coverage_sha256",
        "/operator_decisions/decisions_sha256",
        "/fallback_addendum/addendum_sha256",
        # Only the DIGEST of the must-drop sidecar is committable. Matching is by
        # EXACT path, so `/partition_obligation/must_drop/0/training_key/row_id`
        # can never be allowlisted by adding an entry here, and a bare
        # `manifest:<audioHash>` row id is hash-shaped and trips the gate anyway.
        "/partition_obligation/must_drop_sha256",
        "/partition_closure/must_drop_sha256",
        "/partition_closure/closure_record_sha256",
        *(f"/fingerprint_review/training_input_digests/{name}" for name in TRAINING_INPUT_NAMES),
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
    a track title would pass it.
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
_COMMITMENT_ACTIVE_KEYS = frozenset(
    {
        "generation",
        "supersedes_sha256",
        "fingerprint_review",
        "operator_decisions",
        "partition_obligation",
        "fallback_addendum",
        "notes",
    }
)
_COMMITMENT_SUPERSEDED_KEYS = frozenset({"superseded_note", "generation", "supersedes_sha256"})
_COMMITMENT_BAND_KEYS = frozenset(
    {"candidates", "seed", "exclusions", "fallback_candidates", "fallback_seed"}
)
_FINGERPRINT_REVIEW_KEYS = frozenset(
    {
        "method",
        "flags",
        "confirmed_same_recording",
        "cleared",
        "recording_groups",
        "dispositions_sha256",
        "candidate_universe_sha256",
        "training_input_sha256",
        "training_input_digests",
        "coverage_sha256",
        "coverage",
    }
)
_PARTITION_OBLIGATION_KEYS = frozenset(
    {
        "policy",
        "route_reversed",
        "retained_manifest_matches",
        "enumerated_fingerprint_matches",
        "excluded_by_confirmed_disposition",
        "excluded_training_fingerprint_matches",
        "excluded_giantsteps_matches",
        "must_drop_sha256",
        "must_drop_count",
        "status",
        "note",
    }
)
_COVERAGE_KEYS = frozenset(
    {
        "candidates_total",
        "candidates_covered",
        "candidates_by_reason",
        "training_total",
        "training_covered",
        "training_by_reason",
        "amended_uncovered_training_rows",
    }
)
_OPERATOR_DECISIONS_KEYS = frozenset(
    {"decisions_sha256", "decided", "short_band_allocation", "cross_band_duplicate_rule"}
)
_FALLBACK_KEYS = frozenset(
    {
        "policy",
        "dated",
        "fallback_candidates_by_band",
        "already_in_primary_by_band",
        "net_new_by_band",
        "addendum_sha256",
        "note",
    }
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
    """Exact key schema of the machine-generated commitment JSON.

    A superseded record is a historical artifact of an earlier mint whose routes
    were a strict subset of today's; its keys may be MISSING but never
    unexpected. Zero-filling them would claim a route ran and confirmed nothing.
    """
    if not isinstance(doc, dict):
        raise PrivacyError("commitment: expected an object")
    status = doc.get("status")
    if status not in (STATUS_ACTIVE, STATUS_SUPERSEDED):
        raise PrivacyError(f"commitment: status must be active or superseded, got {status!r}")
    old = status == STATUS_SUPERSEDED
    extra = _COMMITMENT_ACTIVE_KEYS if status == STATUS_ACTIVE else _COMMITMENT_SUPERSEDED_KEYS
    _assert_keys(doc, _COMMITMENT_COMMON_KEYS | extra, "commitment", allow_missing=old)
    bands = _assert_keys(doc["bands"], frozenset(BAND_NAMES), "commitment/bands")
    for name, band in bands.items():
        _assert_keys(band, _COMMITMENT_BAND_KEYS, f"commitment/bands/{name}", allow_missing=old)
        _assert_keys(
            band["exclusions"],
            frozenset(EXCLUSION_REASONS),
            f"commitment/bands/{name}/exclusions",
            allow_missing=old,
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
        review = _assert_keys(
            doc["fingerprint_review"], _FINGERPRINT_REVIEW_KEYS, "commitment/fingerprint_review"
        )
        _assert_keys(review["coverage"], _COVERAGE_KEYS, "commitment/fingerprint_review/coverage")
        _assert_keys(
            review["training_input_digests"],
            frozenset(TRAINING_INPUT_NAMES),
            "commitment/fingerprint_review/training_input_digests",
        )
        _assert_keys(
            doc["operator_decisions"], _OPERATOR_DECISIONS_KEYS, "commitment/operator_decisions"
        )
        obligation = _assert_keys(
            doc["partition_obligation"],
            _PARTITION_OBLIGATION_KEYS,
            "commitment/partition_obligation",
        )
        if obligation["status"] not in (
            OBLIGATION_STATUS_PROVISIONAL,
            OBLIGATION_STATUS_NOT_APPLICABLE,
        ):
            raise PrivacyError(
                "commitment/partition_obligation/status must be "
                f"{OBLIGATION_STATUS_PROVISIONAL} or {OBLIGATION_STATUS_NOT_APPLICABLE}, "
                f"got {obligation['status']!r}"
            )
        _assert_keys(doc["fallback_addendum"], _FALLBACK_KEYS, "commitment/fallback_addendum")
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
        "repass",
        "partition_closure",
        "attestation_sha256",
    }
)
_ATTESTATION_CLOSURE_KEYS = frozenset(
    {
        "certified",
        "basis",
        "policy",
        "must_drop_sha256",
        "must_drop_count",
        "closure_record_sha256",
        "note",
    }
)
_CLOSURE_RECORD_KEYS = frozenset(
    {
        "schema_version",
        "story",
        "certified",
        "closed",
        "method",
        "commitment_sha256",
        "annotation_ledger_head",
        "must_drop_sha256",
        "member_must_drop_sha256",
        "residual_overlap",
        "training_input_digests",
        "note",
    }
)
_ATTESTATION_REPASS_KEYS = frozenset(
    {
        "record_sha256",
        "population_sha256",
        "sample_sha256",
        "sample_size",
        "population_size",
        "seed",
        "metrical_level_disagreements",
        "fine_disagreements",
        "non_comparable",
        "crossed_band",
        "metrical_level_disagreement_rate",
        "fine_disagreement_rate",
        "median_abs_diff_bpm",
        "max_abs_diff_bpm",
        "note",
    }
)
_ADDENDUM_KEYS = frozenset(
    {
        "schema_version",
        "story",
        "dated",
        "commitment_generation",
        "policy",
        "source_order",
        "bands",
        "note",
    }
)


def assert_ledger_head_schema(doc: dict) -> None:
    _assert_keys(doc, _LEDGER_HEAD_KEYS, "ledger-head")
    _assert_keys(doc["bands"], frozenset(BAND_NAMES), "ledger-head/bands")


def assert_attestation_schema(doc: dict) -> None:
    _assert_keys(doc, _ATTESTATION_KEYS, "attestation")
    _assert_keys(doc["members_per_band"], frozenset(BAND_NAMES), "attestation/members_per_band")
    _assert_keys(doc["repass"], _ATTESTATION_REPASS_KEYS, "attestation/repass")
    _assert_keys(
        doc["partition_closure"], _ATTESTATION_CLOSURE_KEYS, "attestation/partition_closure"
    )


def assert_addendum_schema(doc: dict) -> None:
    _assert_keys(doc, _ADDENDUM_KEYS, "fallback-addendum")
    _assert_keys(doc["bands"], frozenset(BAND_NAMES), "fallback-addendum/bands")


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


def is_sha256_hex(value: object) -> bool:
    """A 64-character LOWERCASE HEX digest, not merely a 64-character string.

    Length-only checks accept `"x" * 64`, which can never equal a real digest -
    so a guard comparing a recorded head against the live one reads the sentinel
    as "moved" and fails open in the permissive direction.
    """
    return (
        isinstance(value, str) and len(value) == 64 and all(c in "0123456789abcdef" for c in value)
    )


def _write_bytes_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def _write_json(path: Path, doc: dict) -> None:
    _write_bytes_atomic(path, _json_bytes(doc))


def _write_json_immutable(path: Path, doc: dict) -> None:
    """Write a record that may never be overwritten with different bytes.

    Re-writing identical bytes is allowed so an interrupted run is resumable;
    anything else raises. Annotation records, re-pass records, and commitment
    archives all go through this: these labels are one annotator's DAW work and
    cannot be regenerated.
    """
    data = _json_bytes(doc)
    if path.exists():
        if path.read_bytes() == data:
            return
        raise HarnessError(
            f"IMMUTABLE RECORD: {path.name} already exists with different content. "
            "Records are versioned and never overwritten; a correction appends a new "
            "version and a new event."
        )
    _write_bytes_atomic(path, data)


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


def _rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _under(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
    except (ValueError, OSError):
        return False
    return True


# ---------------------------------------------------------------------------
# Immutable event store
# ---------------------------------------------------------------------------


def _ledger_lines(path: Path) -> list[bytes]:
    if not path.exists():
        return []
    return [ln for ln in path.read_bytes().split(b"\n") if ln.strip()]


def head_of(path: Path) -> tuple[str, int]:
    lines = _ledger_lines(path)
    if not lines:
        return GENESIS_DIGEST, 0
    return sha256_bytes(lines[-1]), len(lines)


def read_events(path: Path) -> list[dict]:
    events: list[dict] = []
    for i, line in enumerate(_ledger_lines(path)):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError as exc:
            raise HarnessError(
                f"event store {path.name} line {i} is not valid JSON: {exc}"
            ) from exc
        events.append(ev)
    return events


def append_event(path: Path, event: dict) -> str:
    lines = _ledger_lines(path)
    prev = GENESIS_DIGEST if not lines else sha256_bytes(lines[-1])
    full = dict(event)
    full["index"] = len(lines)
    full["prev"] = prev
    line = json.dumps(full, sort_keys=True, separators=(",", ":")).encode("utf-8")
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "ab") as fh:
        fh.write(line + b"\n")
    return sha256_bytes(line)


def latest_by_batch(events: list[dict]) -> dict[tuple[str, int], dict]:
    """Latest event per (band, batch); a `replacement` supersedes its predecessor
    without overwriting it."""
    active: dict[tuple[str, int], dict] = {}
    for ev in events:
        active[(str(ev.get("band")), int(ev.get("batch", -1)))] = ev
    return active


def _chain_failures(
    path: Path,
    statuses: tuple[str, ...],
    transitions: dict[str | None, frozenset[str]],
    commitment_sha: str,
    key: Callable[[dict], Any],
) -> tuple[list[str], list[dict]]:
    """Chain integrity + allowed-transition walk shared by both event stores."""
    failures: list[str] = []
    events: list[dict] = []
    prev = GENESIS_DIGEST
    current: dict[Any, str] = {}
    for i, line in enumerate(_ledger_lines(path)):
        try:
            ev = json.loads(line)
        except json.JSONDecodeError as exc:
            failures.append(f"{path.name} line {i} is not valid JSON: {exc}")
            return failures, events
        if int(ev.get("index", -1)) != i:
            failures.append(f"{path.name} event {i} carries index {ev.get('index')!r}")
        if ev.get("prev") != prev:
            failures.append(
                f"{path.name} chain break at event {i}: prev {ev.get('prev')!r} != "
                f"the previous event digest {prev}"
            )
        status = ev.get("status")
        if status not in statuses:
            failures.append(f"{path.name} event {i}: unknown status {status!r}")
        else:
            k = key(ev)
            allowed = transitions.get(current.get(k))
            if allowed is None or status not in allowed:
                failures.append(
                    f"{path.name} event {i}: transition {current.get(k)!r} -> {status!r} for "
                    f"{k!r} is not in the allowed-transition table"
                )
            current[k] = status
        if ev.get("commitment_sha256") != commitment_sha:
            failures.append(
                f"{path.name} event {i} is bound to commitment "
                f"{ev.get('commitment_sha256')!r}, not the active commitment"
            )
        prev = sha256_bytes(line)
        events.append(ev)
    return failures, events


# ---------------------------------------------------------------------------
# Commitment: status, chain, drift/tamper
# ---------------------------------------------------------------------------


def read_commitment() -> dict:
    return _read_json(COMMITMENT_JSON, "commitment artifact")


def commitment_chain_failures(doc: dict, digest: str) -> list[str]:
    """Walk `supersedes_sha256` back through the committed archives.

    An archived predecessor cannot silently vanish: each link must name a file
    in the artifacts directory that hashes to the recorded digest.
    """
    failures: list[str] = []
    seen = {digest}
    current = doc
    while True:
        prior = current.get("supersedes_sha256")
        if not prior:
            return failures
        if prior in seen:
            failures.append(f"commitment chain loops at {prior[:12]}")
            return failures
        seen.add(prior)
        matches = [
            p
            for p in sorted(ARTIFACTS_DIR.glob("12-7-candidate-commitment.*.json"))
            if _safe_sha256_file(p) == prior
        ]
        if not matches:
            failures.append(
                f"commitment chain break: this record supersedes {prior[:12]} but no archived "
                "commitment in the artifacts directory hashes to it. An archived predecessor "
                "may never be deleted or edited."
            )
            return failures
        current = _read_json(matches[0], "archived commitment")


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
            "A superseded commitment can never be operated on. Mint a successor with "
            "`make eval-corpus-remint`, which archives this record byte-for-byte, "
            "records `supersedes_sha256`, and refuses while any prerequisite or any "
            "prior-generation annotation state is outstanding."
        )
    return commitment, sha256_file(COMMITMENT_JSON)


def verify_input_drift(commitment: dict, pools_doc: dict, draws_doc: dict) -> None:
    """Hash the documents REGENERATED FROM TODAY'S INPUTS against the recorded
    digests. Verifying only the on-disk file is a tamper check; without this a
    changed survey or training manifest printed 'commitment verified'."""
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
# Batch records + worklists
# ---------------------------------------------------------------------------

_BATCH_RECORD_KEYS = ("band", "batch", "size", "start", "rowIds", "work_order_seed", "work_order")


def validate_batch_records(generation: str, band: str, sequence_row_ids: list[str]) -> list[dict]:
    """Validate every batch record for a band against the committed sequence.

    Checks filename index, band, batch index, start, size, the EXACT sequence
    slice, the work-order permutation, and a contiguous 0..n-1 prefix.
    """
    band_dir = batches_dir(generation) / band
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


def worklist_path_for(generation: str, band: str, batch: int) -> Path:
    return batches_dir(generation) / band / f"batch-{batch:03d}-worklist.csv"


def read_worklist(path: Path) -> list[tuple[str, str]]:
    with open(path, newline="", encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    if not rows or rows[0] != ["row_id", "audio"]:
        raise HarnessError(
            f"worklist {path.name} header is {rows[0] if rows else '<empty>'}, expected "
            "exactly ['row_id', 'audio'] - the annotator-facing worklist carries an opaque "
            "row id and a staged path and nothing else"
        )
    out: list[tuple[str, str]] = []
    for i, row in enumerate(rows[1:], start=1):
        if len(row) != 2:
            raise HarnessError(f"worklist {path.name} line {i} has {len(row)} columns, expected 2")
        out.append((row[0], row[1]))
    return out


def validate_worklist(
    generation: str,
    band: str,
    batch: int,
    record: dict,
    by_row_id: dict[str, dict],
    require_audio: bool,
) -> list[str]:
    """Structural worklist validation, run BEFORE annotations are accepted.

    A recorded-but-unchecked digest is worse than none. Verifying only the
    ingest-recorded digest is also too late: a worklist altered BEFORE ingest
    has its altered digest anchored as the reference. So the worklist is checked
    against the batch record itself - the full row set in work order, every path
    confined to this batch's staging directory, and every staged file hashed
    against that row's committed `contentSha256`.
    """
    failures: list[str] = []
    path = worklist_path_for(generation, band, batch)
    if not path.exists():
        return [f"worklist for {band}/batch-{batch:03d} is missing"]
    try:
        rows = read_worklist(path)
    except HarnessError as exc:
        return [str(exc)]
    expected_order = list(record["work_order"])
    if [rid for rid, _ in rows] != expected_order:
        return [
            f"worklist {band}/batch-{batch:03d} row ids are not the batch record's work "
            "order - the worklist was edited, reordered, or re-pointed"
        ]
    stage = (staging_dir(generation) / band / f"batch-{batch:03d}").resolve()
    for rid, audio in rows:
        audio_path = Path(audio)
        if not _under(audio_path, stage):
            failures.append(
                f"worklist {band}/batch-{batch:03d} row {rid} points outside this batch's "
                "staging directory"
            )
            continue
        entry = by_row_id.get(rid)
        committed = str((entry or {}).get("contentSha256") or "")
        if not audio_path.exists():
            if require_audio:
                failures.append(
                    f"staged audio for {band}/batch-{batch:03d} row {rid} is missing; the "
                    "batch cannot be ingested without content-verifiable audio"
                )
            continue
        actual = sha256_file(audio_path)
        if committed and actual != committed:
            failures.append(
                f"staged audio for {band}/batch-{batch:03d} row {rid} hashes to {actual}, "
                f"the commitment records {committed} - this row was pointed at different "
                "audio, which would produce labels for the wrong track"
            )
    return failures


# ---------------------------------------------------------------------------
# Harness state: load once, validate before AND after every mutation
# ---------------------------------------------------------------------------


@dataclass
class HarnessState:
    commitment: dict
    commitment_sha: str
    generation: str
    pools: dict
    events: list[dict] = field(default_factory=list)
    repass_events: list[dict] = field(default_factory=list)

    @property
    def n_band(self) -> int:
        value = self.commitment.get("n_band_target")
        return int(value) if isinstance(value, int) else N_BAND

    def sequence(self, band: str) -> list[dict]:
        return _require(_require(self.pools, "bands", "candidate pools"), band, "candidate pools")

    def sequence_row_ids(self, band: str) -> list[str]:
        return [e["rowId"] for e in self.sequence(band)]

    @property
    def by_row_id(self) -> dict[str, dict]:
        return {e["rowId"]: e for band in BAND_NAMES for e in self.sequence(band)}


def load_state() -> HarnessState:
    commitment, sha = require_active_commitment()
    generation = str(_require(commitment, "generation", "commitment artifact"))
    pools = _read_json(pools_path(generation), "candidate pools")
    return HarnessState(
        commitment=commitment,
        commitment_sha=sha,
        generation=generation,
        pools=pools,
        events=read_events(ledger_path(generation)),
        repass_events=read_events(repass_ledger_path(generation)),
    )


def annotation_record_path(generation: str, ev: dict) -> Path | None:
    rel = ev.get("annotation_path")
    if not rel:
        return None
    return generation_root(generation) / str(rel)


def validate_state(state: HarnessState, require_audio: bool = False) -> list[str]:
    """The single coherence check, run BEFORE and AFTER every mutation.

    Round 1's command functions held planning, validation, and mutation at once,
    so no single place could assert the state machine was coherent. Everything
    that can be checked without re-deriving today's inputs is checked here.
    """
    failures: list[str] = []
    gen = state.generation

    # 1. Committed artifact: schema, privacy screens, supersession chain.
    try:
        gate_committed(state.commitment, assert_commitment_schema)
    except PrivacyError as exc:
        failures.append(f"commitment artifact: {exc}")
    failures.extend(commitment_chain_failures(state.commitment, state.commitment_sha))

    # 2. Row-level files: present, generation-scoped, and hashing to the
    # committed digests. Both directions matter; see verify_input_drift for the
    # other one.
    for path, key in (
        (pools_path(gen), "pool_file_sha256"),
        (draws_path(gen), "draw_file_sha256"),
    ):
        recorded = state.commitment.get(key)
        if not path.exists():
            failures.append(
                f"committed row-level file {path.name} is missing from generation {gen}"
            )
        elif sha256_file(path) != recorded:
            failures.append(
                f"commitment digest mismatch for {path.name}: committed {key} {recorded} != "
                f"actual {sha256_file(path)} - the row-level file drifted since commitment"
            )

    # 3. Batch records against the committed sequence.
    records: dict[tuple[str, int], dict] = {}
    for band in BAND_NAMES:
        try:
            for rec in validate_batch_records(gen, band, state.sequence_row_ids(band)):
                records[(band, int(rec["batch"]))] = rec
        except HarnessError as exc:
            failures.append(f"batch records for {band}: {exc}")

    # 4. Event store: chain, transitions, commitment binding.
    chain_failures, events = _chain_failures(
        ledger_path(gen),
        LEDGER_STATUSES,
        EVENT_TRANSITIONS,
        state.commitment_sha,
        lambda ev: (str(ev.get("band")), int(ev.get("batch", -1))),
    )
    failures.extend(chain_failures)

    # 5. Annotation records: allowed root, uniqueness, digests, and the
    # abandoned-batch invariant. Records are immutable and versioned, so EVERY
    # event's record (not only the latest) must still be present and intact.
    ann_root = annotations_dir(gen)
    referenced: set[Path] = set()
    for ev in events:
        band, batch = str(ev.get("band")), int(ev.get("batch", -1))
        rec = records.get((band, batch))
        if rec is None:
            failures.append(f"event references a missing batch record {band}/batch-{batch:03d}")
        elif sha256_file(batches_dir(gen) / band / f"batch-{batch:03d}.json") != ev.get(
            "batch_record_sha256"
        ):
            failures.append(
                f"batch record {band}/batch-{batch:03d} does not match its event digest"
            )
        path = annotation_record_path(gen, ev)
        if ev.get("status") == LEDGER_ABANDONED:
            if path is not None:
                failures.append(
                    f"abandoned event for {band}/{batch} names an annotation record; an "
                    "abandoned batch yields no members and contributes no annotations"
                )
            continue
        if path is None:
            failures.append(f"event for {band}/{batch} carries no annotation_path")
            continue
        if not _under(path, ann_root):
            failures.append(f"annotation record for {band}/{batch} is outside {ann_root.name}/")
            continue
        if path in referenced:
            failures.append(
                f"annotation record {path.name} is referenced by two events; each event "
                "carries its own immutable record path"
            )
        referenced.add(path)
        if not path.exists():
            failures.append(f"annotation record {path.name} recorded in the event store is missing")
        elif sha256_file(path) != ev.get("annotation_sha256"):
            failures.append(
                f"annotation record {path.name} does not match its event digest - it was "
                "edited after ingest"
            )
    if ann_root.exists():
        for p in sorted(ann_root.glob("*/*.json")):
            if p not in referenced:
                failures.append(
                    f"annotation record {p.parent.name}/{p.name} is not referenced by any "
                    "event - it was added, duplicated, or moved"
                )

    # 6. Worklists: structural validation plus the recorded digest.
    by_row_id = state.by_row_id
    latest = latest_by_batch(events)
    for (band, batch), rec in sorted(records.items()):
        failures.extend(
            validate_worklist(gen, band, batch, rec, by_row_id, require_audio=require_audio)
        )
        ev = latest.get((band, batch))
        if ev is None or ev.get("status") == LEDGER_ABANDONED:
            continue
        wl = worklist_path_for(gen, band, batch)
        if wl.exists() and sha256_file(wl) != ev.get("work_order_sha256"):
            failures.append(
                f"worklist {band}/batch-{batch:03d} does not match the digest recorded at "
                "ingest - it was edited after the annotations were accepted"
            )

    # 7. Tracked ledger head.
    head, count = head_of(ledger_path(gen))
    if LEDGER_HEAD_JSON.exists():
        head_doc = _read_json(LEDGER_HEAD_JSON, "annotation ledger head")
        if head_doc.get("head_sha256") != head or int(head_doc.get("event_count", -1)) != count:
            failures.append(
                "tracked annotation-ledger head is stale: it records "
                f"{head_doc.get('head_sha256')!r}/{head_doc.get('event_count')!r}, the ledger "
                f"head is {head}/{count}"
            )
        if head_doc.get("commitment_sha256") != state.commitment_sha:
            failures.append("tracked annotation-ledger head is bound to a different commitment")
    elif count:
        failures.append("annotation ledger has events but the tracked head artifact is absent")

    # 8. Re-pass event store (separate state machine, same guarantees).
    repass_failures, repass_events = _chain_failures(
        repass_ledger_path(gen),
        REPASS_STATUSES,
        REPASS_TRANSITIONS,
        state.commitment_sha,
        lambda ev: int(ev.get("version", -1)),
    )
    failures.extend(repass_failures)
    rp_root = repass_dir(gen)
    for ev in repass_events:
        rel = ev.get("record_path")
        if not rel:
            failures.append(f"re-pass event {ev.get('index')} carries no record_path")
            continue
        path = generation_root(gen) / str(rel)
        if not _under(path, rp_root):
            failures.append(f"re-pass record {path.name} is outside {rp_root.name}/")
        elif not path.exists():
            failures.append(f"re-pass record {path.name} recorded in the event store is missing")
        elif sha256_file(path) != ev.get("record_sha256"):
            failures.append(f"re-pass record {path.name} does not match its event digest")
    return failures


def require_valid_state(state: HarnessState, when: str, require_audio: bool = False) -> None:
    failures = validate_state(state, require_audio=require_audio)
    if failures:
        raise HarnessError(
            f"state validation failed {when}; refusing to proceed:\n  " + "\n  ".join(failures)
        )


def load_annotations(state: HarnessState, band: str) -> dict[str, dict]:
    """Annotations for a band, EVENT-DRIVEN: only the record the latest
    non-abandoned event for each batch names, verified against its digest."""
    out: dict[str, dict] = {}
    for (b, batch), ev in sorted(latest_by_batch(state.events).items()):
        if b != band or ev.get("status") == LEDGER_ABANDONED:
            continue
        path = annotation_record_path(state.generation, ev)
        if path is None:
            raise HarnessError(f"event for {b}/{batch} carries no annotation_path")
        doc = _read_json(path, "annotation record")
        if sha256_file(path) != ev.get("annotation_sha256"):
            raise HarnessError(f"annotation record {path.name} does not match its event digest")
        rows = _require(doc, "rows", f"annotation record {path.name}")
        overlap = sorted(set(rows) & set(out))
        if overlap:
            raise HarnessError(
                f"annotation records for {band} overlap on row ids {overlap[:5]} - batches "
                "are disjoint consecutive spans"
            )
        out.update(rows)
    return out


def recompute_membership(state: HarnessState) -> dict:
    return {
        name: compute_membership(
            state.sequence(name), load_annotations(state, name), name, state.n_band
        )
        for name in BAND_NAMES
    }


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
    manifest_pathless: set[str] = set()
    for path, key in (
        (SECONDARY_MANIFEST, "secondarySupervised"),
        (UNSUPERVISED_MANIFEST, "unsupervisedPool"),
    ):
        doc = _read_json(path, f"training manifest {path.name}")
        rows = doc.get(key)
        if not isinstance(rows, list) or not rows:
            raise HarnessError(f"{path.name}: schema drift - expected non-empty list at '{key}'")
        # PER FILE, not a shared accumulator: testing the accumulator let a
        # path-less SECOND manifest pass on the strength of the first one.
        found_here = 0
        for r in rows:
            audio_hash = str(r["audioHash"])
            manifest_hashes.add(audio_hash)
            # Both committed manifests key the path `relPath`; `path` is accepted
            # only for forward compatibility. Reading `path` alone (the state
            # between c2865b7 and this fix) left manifest_paths EMPTY in
            # production, so the training side of the mandatory fingerprint route
            # silently covered only the tony-split rows while the signed
            # amendment (12-6, "Coverage rules are untouched") requires every
            # training row. A missing path is a coverage GAP, not a skip: the row
            # is recorded as path-less so `fingerprint_coverage` counts it and
            # `assert_training_coverage` can block on it.
            rel = r.get("relPath") or r.get("path")
            if rel:
                manifest_paths[audio_hash] = str(rel)
                found_here += 1
            else:
                manifest_pathless.add(audio_hash)
        if not found_here:
            raise HarnessError(
                f"{path.name}: no row carries a usable path (looked for 'relPath', then "
                "'path'). The training side of the fingerprint route would cover nothing "
                "from this manifest, and the signed amendment requires every training row "
                "fingerprinted. Fails closed rather than reporting empty coverage as clean."
            )

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
        "manifest_pathless": manifest_pathless,
        "tony_split_ids": tony_split_ids,
        "training_artist_keys": training_artist_keys,
        "training_local_paths": training_local_paths,
    }


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


def stage_copies(
    span: list[dict],
    stage_dir: Path,
    pool_audio_root: str | None,
    order: list[str],
    alias: dict[str, str] | None = None,
) -> list[tuple[str, str]]:
    """Copy audio as blinded, opaque-ID-named copies, CONTENT-verified.

    A source that does not hash to the row's committed `contentSha256` is a hard
    failure: a size comparison passes an equal-size substitution. `alias` maps a
    row id to the visible identifier, which the re-pass uses to blind the
    annotator to the original row id. Worklist rows come back in `order`
    (already expressed in visible identifiers).
    """
    stage_dir.mkdir(parents=True, exist_ok=True)
    names = alias or {}
    staged: dict[str, str] = {}
    for entry in span:
        row_id = entry["rowId"]
        visible = names.get(row_id, row_id)
        committed = entry.get("contentSha256")
        if not committed:
            raise HarnessError(
                f"row {visible} carries no contentSha256; the commitment is not "
                "content-bound and cannot be staged"
            )
        src_path = _resolve_audio(entry, pool_audio_root)
        if not src_path.exists():
            raise HarnessError(f"audio missing for row {visible}: cannot stage blinded copy")
        actual = sha256_file(src_path)
        if actual != committed:
            raise HarnessError(
                f"CONTENT MISMATCH for row {visible}: the source audio hashes to "
                f"{actual}, the commitment records {committed}. The file was replaced or "
                "edited since commitment - refusing to stage (a substituted file of equal "
                "size is exactly what a size check misses)."
            )
        dest = stage_dir / f"{visible}{src_path.suffix.lower()}"
        if not dest.exists() or sha256_file(dest) != committed:
            shutil.copyfile(src_path, dest)
        staged[visible] = str(dest)
    return [(vid, staged[vid]) for vid in order if vid in staged]


def write_worklist(path: Path, rows: list[tuple[str, str]]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["row_id", "audio"])  # opaque ID + staged copy ONLY
        writer.writerows(rows)


# ---------------------------------------------------------------------------
# Operator decisions + fingerprint dispositions (machine-readable gates)
# ---------------------------------------------------------------------------


def load_operator_decisions() -> dict:
    """The two pending operator decisions, supplied as machine-readable input."""
    if not DECISIONS_PATH.exists():
        raise OperatorHalt(
            "MISSING OPERATOR DECISIONS: "
            f"{DECISIONS_PATH.name} is absent. Two decisions block minting:\n"
            "  (a) short-band allocation: the precommitted fallback is empty by "
            "construction - Tony and OA300 rows are already in the initial pool and are "
            "also the signed fallback source. The harness implements and ENUMERATES the "
            f"addendum so that emptiness is reported rather than inferred. "
            f"{SHORT_BAND_REPARTITION!r} instead applies the signed 2026-08-11 amendment, "
            "which reverses the training-manifest audioHash route only. Accepted "
            f"policies: {list(SHORT_BAND_POLICIES)}.\n"
            "  (b) cross-band duplicate rule: the signed tie-break is 'earlier in the "
            "membership draw sequence wins', but there is no ordering BETWEEN two per-band "
            "sequences, and the same recording tagged 85 in one source and 170 in another "
            f"lands in two bands by construction. Accepted policies: "
            f"{list(CROSS_BAND_POLICIES)}."
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


def load_operator_decisions_if_present() -> dict | None:
    """The recorded decisions, or None before the operator has supplied them.

    `prepare-review` runs BEFORE the decisions exist in the ordinary flow, so it
    cannot demand them; it falls back to the pre-amendment partition order. A
    decisions file that appears later and records `repartition` changes the
    candidate universe, which `load_dispositions` catches as a universe-digest
    drift and which forces the review to be re-run. That is the intended
    fail-safe, not an accident.
    """
    return load_operator_decisions() if DECISIONS_PATH.exists() else None


def retain_training_manifest_matches(decisions: dict | None) -> bool:
    """Is the signed 2026-08-11 reversed FR-59a.2 route in force?

    THE single derivation of that flag. `build_pool_universe` feeds both
    `cmd_prepare_review` and `plan_commit`; if the two computed this differently
    the candidate universe digests would diverge and every recorded fingerprint
    disposition would stop validating.

    True for exactly one policy value. It reverses exactly one route: the
    non-Rekordbox training-manifest `audioHash` route. It does NOT touch the
    tony.train / tony.val recording-identity route or the artist-string route.
    """
    if not isinstance(decisions, dict):
        return False
    allocation = decisions.get("short_band_allocation")
    if not isinstance(allocation, dict):
        return False
    return allocation.get("policy") == SHORT_BAND_REPARTITION


def partition_order_label(retain: bool) -> str:
    return (
        "repartition (signed 2026-08-11: the training-manifest audioHash route is "
        "reversed and enumerates a must-drop obligation)"
        if retain
        else "pre-amendment (all three FR-59a.2 routes exclude at candidate construction)"
    )


def accepted_uncovered_training_rows(decisions: dict) -> set[str]:
    """Rows a DATED operator amendment accepts as fingerprint-uncovered.

    Absence of evidence is not evidence of absence: a human cannot infer "not the
    same recording" from a failed decode, so the only ways to unblock are
    restoring the audio, correcting the manifest, or naming the row here.
    """
    amendment = decisions.get("fingerprint_coverage_amendment")
    if not isinstance(amendment, dict):
        return set()
    if not amendment.get("dated"):
        raise HarnessError(
            "operator decisions: fingerprint_coverage_amendment must carry a `dated` field; "
            "an undated amendment is not a record."
        )
    return {str(x) for x in amendment.get("accepted_uncovered", [])}


def training_input_digests() -> dict[str, str]:
    """PER-FILE digests of the training inputs, pinned as mint-time provenance.

    The FR-59d rebuild changes these manifests by design, and without the
    originals pinned that change reads as illegal input drift and makes the eval
    commitment unauditable (signed amendment, consequence 4). Per file rather
    than one opaque hash so the drift raise can name WHICH manifest moved
    instead of reporting a single mismatch the reader cannot act on.
    """
    digests: dict[str, str] = {}
    for path in training_input_paths():
        if not path.exists():
            raise HarnessError(f"training input {path.name} not found - HALT")
        digests[path.name] = sha256_file(path)
    return digests


def training_input_digest() -> str:
    """Single digest over the training inputs a fingerprint disposition
    adjudicated against, so a manifest change invalidates the dispositions.

    Derived from `training_input_digests` and byte-compatible with the value
    recorded before the per-file map existed.
    """
    parts = [f"{name}:{digest}" for name, digest in training_input_digests().items()]
    return sha256_bytes(_json_bytes({"training_inputs": sorted(parts)}))


def _training_input_drift_detail(recorded: object) -> str:
    """Name the manifests that moved, when the disposition set recorded a map."""
    if not isinstance(recorded, dict) or not recorded:
        return (
            " The recorded disposition set predates the per-file digest map, so the "
            "moved file cannot be named; re-run `prepare-review` to record one."
        )
    try:
        actual = training_input_digests()
    except HarnessError as exc:
        return f" Per-file comparison unavailable: {exc}"
    was: dict[str, str] = {}
    for name, digest in recorded.items():
        was[str(name)] = str(digest)
    moved = sorted(name for name in set(was) | set(actual) if was.get(name) != actual.get(name))
    if not moved:
        return (
            " Every per-file digest still matches, so the combined digest was recorded "
            "under a different derivation; re-run `prepare-review`."
        )
    return (
        " Moved training input(s): "
        + ", ".join(
            f"{name} {was.get(name, 'absent')[:12]} to {actual.get(name, 'absent')[:12]}"
            for name in moved
        )
        + ". A rebuild of the training manifests is expected to trigger this once (signed "
        "amendment, consequence 4); re-run `prepare-review` against the rebuilt inputs."
    )


def load_dispositions(
    universe_digest: str, expected_flag_ids: set[str], partition_order: str = ""
) -> dict[str, dict]:
    """Fail-closed disposition gate. Blocks minting while any generated review
    flag is unadjudicated, and refuses a disposition set bound to a different
    candidate universe, fingerprint method, or training input."""
    if not DISPOSITIONS_PATH.exists():
        raise OperatorHalt(
            "MISSING FINGERPRINT DISPOSITIONS: "
            f"{DISPOSITIONS_PATH.name} is absent. The signed section-2 fingerprint route "
            "is MANDATORY and runs BEFORE commitment. Run `prepare-review` to generate the "
            f"flags plus {DISPOSITIONS_TEMPLATE_PATH.name}, record a human disposition for "
            "every flag, and save it as the dispositions file. The algorithm is advisory; "
            "the recorded human disposition is what disposes. A confirmed match excludes "
            "the candidate, except that under the signed 2026-08-11 repartition order a "
            "confirmed match against a training-MANIFEST row instead enumerates what the "
            "training rebuild must drop."
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
    # Bound EXPLICITLY, not inferred from the universe digest. With zero overlap
    # between the pool and the training manifests both partition orders produce
    # an identical universe, so a review adjudicated under the pre-amendment
    # order would otherwise be silently accepted by a repartition mint - and the
    # two orders mean different things by "confirmed".
    recorded_order = doc.get("partition_order")
    if partition_order and recorded_order is not None and recorded_order != partition_order:
        raise DriftError(
            f"fingerprint dispositions were recorded under partition order "
            f"{recorded_order!r}, but today's order is {partition_order!r}. A confirmed "
            "training-manifest match excludes under one order and enumerates a must-drop "
            "obligation under the other, so the adjudications cannot carry across; re-run "
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
            f"{recorded_training}, but today's training inputs hash to {actual_training}."
            + _training_input_drift_detail(doc.get("training_input_digests"))
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


@dataclass(frozen=True)
class DispositionOutcome:
    """What the recorded human dispositions did to the candidate pools."""

    bands: dict[str, list[dict]]
    recording_groups: dict[str, str]
    # Candidates a confirmed disposition REMOVED. This is what the pre-amendment
    # harness reported as `confirmed`, and it equals the sum of the
    # `fingerprint-confirmed` exclusion counts.
    confirmed_excluded: int
    # ATTRIBUTIONS of those removals, not a partition of them: one candidate can
    # carry both a confirmed training-fingerprint flag and a confirmed
    # GiantSteps-title flag, in which case it is counted under both.
    excluded_by_training_fingerprint: int
    excluded_by_giantsteps: int
    # Candidates RETAINED and enumerated as a partition obligation. Zero unless
    # the reversed route is in force.
    confirmed_enumerated: int
    obligations: list[dict]

    @property
    def confirmed_total(self) -> int:
        return self.confirmed_excluded + self.confirmed_enumerated


def apply_dispositions(
    bands: dict[str, list[dict]],
    exclusions: dict[str, dict[str, int]],
    dispositions: dict[str, dict],
    flags: list[dict],
    retain_manifest_matches: bool = False,
) -> DispositionOutcome:
    """Apply the recorded human dispositions.

    A confirmed GiantSteps-title flag EXCLUDES its candidate, always.

    A confirmed training-fingerprint flag EXCLUDES its candidate too, except in
    the one case the signed 2026-08-11 amendment reverses: `repartition` is in
    force AND the training peer is a non-Rekordbox training-MANIFEST row. Then
    the candidate is RETAINED and the match is enumerated as a must-drop
    obligation for the training rebuild. A confirmed match whose peer is a
    tony.train or tony.val row is the recording-identity route under another
    name, which the amendment leaves alone, so it still excludes.

    A confirmed cross-band-recording flag excludes nothing; it supplies one edge
    of the same-recording graph, and the transitive components of that graph are
    what `pre-commitment-recording-dedup` collapses on and what
    `audit-fails-on-cross-band-duplicate` fails on.
    """
    confirmed_keys: set[str] = set()
    by_fingerprint: set[str] = set()
    by_giantsteps: set[str] = set()
    edges: list[tuple[str, str]] = []
    supplied: dict[str, str] = {}
    enumerated: list[dict] = []
    for flag in flags:
        disp = dispositions.get(flag["flag_id"], {})
        if disp.get("disposition") != DISPOSITION_SAME:
            continue
        group = disp.get("recording_group")
        left = str(flag["candidate_key"])
        peer = flag.get("peer_key")
        if peer:
            edges.append((left, str(peer)))
            if group:
                supplied[left] = str(group)
                supplied[str(peer)] = str(group)
        kind = flag["kind"]
        if kind == FLAG_KIND_GIANTSTEPS:
            confirmed_keys.add(left)
            by_giantsteps.add(left)
        elif kind == FLAG_KIND_FINGERPRINT:
            training = flag.get("training_key")
            # The operator's file round-trips `training_key`, and the namespace
            # decides exclude-versus-enumerate. An edited copy must never win
            # over the harness-generated flag it was derived from.
            recorded = disp.get("training_key")
            if recorded is not None and recorded != training:
                raise HarnessError(
                    f"fingerprint disposition {flag['flag_id']} records training_key "
                    f"{recorded!r}, but the harness generated {training!r} for that flag. "
                    "The training peer is derived evidence, not an operator field: it "
                    "decides whether a confirmed match excludes the candidate or "
                    "enumerates a must-drop obligation. Restore it or re-run "
                    "`prepare-review`."
                )
            reversed_route = (
                retain_manifest_matches
                and isinstance(training, dict)
                and training.get("source") == TRAINING_SOURCE_MANIFEST
            )
            if reversed_route:
                enumerated.append(
                    _obligation(left, flag["band"], OBLIGATION_ROUTE_FINGERPRINT, dict(training))
                )
            else:
                confirmed_keys.add(left)
                by_fingerprint.add(left)
    recording_groups = union_recording_groups(edges, supplied)
    out: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    confirmed_excluded = 0
    removed: set[str] = set()
    kept: set[str] = set()
    for name in BAND_NAMES:
        for entry in bands[name]:
            key = candidate_key(entry)
            if key in confirmed_keys:
                exclusions[name]["fingerprint-confirmed"] += 1
                confirmed_excluded += 1
                removed.add(key)
                continue
            kept.add(key)
            bound = dict(entry)
            if key in recording_groups:
                bound["recordingGroup"] = recording_groups[key]
            out[name].append(bound)
    # A candidate can carry both a manifest-peer confirmation and a tony-split
    # or GiantSteps one. Exclusion wins, so its obligation is dropped with it.
    obligations = [o for o in enumerated if o["candidate_key"] in kept]
    return DispositionOutcome(
        bands=out,
        recording_groups=recording_groups,
        confirmed_excluded=confirmed_excluded,
        excluded_by_training_fingerprint=len(by_fingerprint & removed),
        excluded_by_giantsteps=len(by_giantsteps & removed),
        confirmed_enumerated=len({o["candidate_key"] for o in obligations}),
        obligations=obligations,
    )


# ---------------------------------------------------------------------------
# The mandatory pre-commitment fingerprint route - now FAIL-CLOSED.
#
# Round 1's route failed open in four independent ways: missing audio was
# skipped by a bare `continue`, every decode failure returned None through a
# blanket `except Exception` absorbed by `if vec:`, a missing librosa returned
# None for EVERY file (zeroing the route entirely), and an empty training set
# short-circuited so the completeness check was trivially satisfied. The mint
# then recorded `"flags": 0` with no denominators - indistinguishable from
# "ran, found nothing". Coverage is now reason-stratified, digest-bound, and
# gating, and the two sides are treated ASYMMETRICALLY:
#
#   * an unfingerprintable CANDIDATE is hard-excluded with reasoned accounting
#     (there is no human escape: it cannot be staged safely anyway);
#   * an unfingerprintable TRAINING ROW BLOCKS certification, because it
#     potentially hides re-encoded overlap with every candidate and a human
#     cannot infer "not the same recording" from a failed decode.
# ---------------------------------------------------------------------------


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


def _fingerprint_one(key: str, path: Path | None) -> tuple[str, list[float] | None, str]:
    """(key, vector, coverage reason) for one row."""
    if path is None:
        return key, None, "unresolved-path"
    if not path.exists():
        return key, None, "missing-file"
    vec = FINGERPRINT_FN(str(path))
    if vec:
        return key, vec, "resolved"
    reason = FINGERPRINT_REASON_FN(str(path))
    if reason not in COVERAGE_REASONS:
        reason = "decode-failed"
    return key, None, reason


def fingerprint_coverage(
    inputs: dict, bands: dict[str, list[dict]]
) -> tuple[dict[str, Any], list[tuple[str, str, list[float]]], list[tuple[str, list[float]]]]:
    """Reason-stratified coverage over EVERY candidate and EVERY training row.

    Returns (coverage, candidate vectors, training vectors). The coverage record
    carries the private roster so "4,200 of 4,300" can still identify WHICH
    hundred after the inputs move; only its digest and the counts reach git.
    """
    assert_fingerprint_backend()
    root = inputs.get("pool_audio_root")

    candidates: list[tuple[str, str, list[float]]] = []
    cand_reasons: dict[str, int] = dict.fromkeys(COVERAGE_REASONS, 0)
    cand_roster: dict[str, str] = {}
    for name in BAND_NAMES:
        for entry in bands[name]:
            key, vec, reason = _fingerprint_one(candidate_key(entry), _safe_resolve(entry, root))
            cand_reasons[reason] += 1
            cand_roster[key] = reason
            if vec:
                candidates.append((name, key, vec))

    training: list[tuple[str, list[float]]] = []
    train_reasons: dict[str, int] = dict.fromkeys(COVERAGE_REASONS, 0)
    train_roster: dict[str, str] = {}
    for audio_hash, rel in sorted(inputs.get("manifest_paths", {}).items()):
        path = Path(root) / rel if root else Path(rel)
        key, vec, reason = _fingerprint_one(f"manifest:{audio_hash}", path)
        train_reasons[reason] += 1
        train_roster[key] = reason
        if vec:
            training.append((key, vec))
    # A manifest row with no path field never reaches `_fingerprint_one`, so
    # without this it would be absent from the denominators entirely and
    # `assert_training_coverage` could not block on it.
    for audio_hash in sorted(inputs.get("manifest_pathless", set())):
        key = f"{TRAINING_SOURCE_MANIFEST}:{audio_hash}"
        train_reasons["no-path"] += 1
        train_roster[key] = "no-path"
    for tid, local in sorted(inputs.get("training_local_paths", {}).items()):
        key, vec, reason = _fingerprint_one(f"tony-split:{tid}", Path(local))
        train_reasons[reason] += 1
        train_roster[key] = reason
        if vec:
            training.append((key, vec))

    coverage = {
        "schema_version": 1,
        "fingerprint_method": FINGERPRINT_METHOD,
        "review_cosine": FINGERPRINT_REVIEW_COSINE,
        "candidates_total": sum(cand_reasons.values()),
        "candidates_covered": cand_reasons["resolved"],
        "candidates_by_reason": cand_reasons,
        "training_total": sum(train_reasons.values()),
        "training_covered": train_reasons["resolved"],
        "training_by_reason": train_reasons,
        "candidate_roster": cand_roster,
        "training_roster": train_roster,
    }
    return coverage, candidates, training


def assert_training_coverage(coverage: dict, accepted: set[str]) -> list[str]:
    """Block certification on any uncovered training row not named by a dated
    operator amendment. Returns the accepted-and-still-uncovered roster."""
    uncovered = sorted(
        k for k, reason in coverage["training_roster"].items() if reason != "resolved"
    )
    unamended = [k for k in uncovered if k not in accepted]
    if unamended:
        raise OperatorHalt(
            "FINGERPRINT COVERAGE INCOMPLETE ON THE TRAINING SIDE: "
            f"{len(unamended)} of {coverage['training_total']} training rows could not be "
            f"fingerprinted (by reason: {coverage['training_by_reason']}). An uncovered "
            "training row potentially hides re-encoded overlap with EVERY candidate, and a "
            "human cannot infer 'not the same recording' from a failed decode - that would "
            "turn absence of evidence into evidence of absence. Unblock by restoring the "
            "audio, correcting the manifest, or naming the accepted rows in a dated "
            "`fingerprint_coverage_amendment` in the operator-decisions file. First few: "
            f"{unamended[:5]}"
        )
    if coverage["training_total"] == 0:
        raise OperatorHalt(
            "FINGERPRINT COVERAGE INCOMPLETE: the training side enumerated ZERO rows, so "
            "the mandatory route compared every candidate against nothing. An empty "
            "training set is an input failure, never a clean pass."
        )
    return [k for k in uncovered if k in accepted]


def build_review_flags(
    bands: dict[str, list[dict]],
    candidates: list[tuple[str, str, list[float]]],
    training: list[tuple[str, list[float]]],
) -> list[dict]:
    """Generate the pre-commitment review flag set from covered vectors.

    Three kinds, all ADVISORY signals a human disposition must resolve:
      - `training-fingerprint`: candidate audio matching a training-manifest or
        tony.train/val recording at or above the DD #3 review cosine. Carries a
        STRUCTURED `training_key` naming the peer row, because a confirmed
        manifest match under the signed repartition order enumerates a
        machine-checkable must-drop obligation and a prose `evidence` string
        cannot back one. `peer_key` deliberately stays None: it carries
        candidate-vs-candidate edges into `union_recording_groups`, and a
        training row is not a candidate, so putting it there would inject a
        non-candidate node into the recording-group graph and onto pool entries.
      - `giantsteps-title`: normalized-title collision with a GiantSteps row.
        `normalize_track_key` drops suffixes and parenthesized material, so a hit
        is a conservative heuristic, never proof of a shared recording.
      - `cross-band-recording`: candidate-vs-candidate pairs in DIFFERENT bands.
        A byte digest cannot see a half-tempo and a full-tempo encode of one
        recording; these pairs are the evidence the cross-band decision needs.
    """
    flags: list[dict] = []
    gs_titles = _giantsteps_titles()
    for name in BAND_NAMES:
        for entry in bands[name]:
            nk = cc.normalize_track_key(entry.get("title", ""))
            if nk and nk in gs_titles:
                key = candidate_key(entry)
                flags.append(
                    {
                        "flag_id": flag_id(FLAG_KIND_GIANTSTEPS, key, nk),
                        "kind": FLAG_KIND_GIANTSTEPS,
                        "band": name,
                        "candidate_key": key,
                        "peer_key": None,
                        "training_key": None,
                        "evidence": "normalized-title collision with a GiantSteps row",
                        "score": None,
                    }
                )

    stats = cohort_stats([v for _, v in training] + [v for _, _, v in candidates])
    training_z = [(k, standardize(v, stats)) for k, v in training]
    candidates_z = [(b, k, standardize(v, stats)) for b, k, v in candidates]
    for name, key, vec in candidates_z:
        for train_key, train_vec in training_z:
            score = cosine(vec, train_vec)
            if score >= FINGERPRINT_REVIEW_COSINE:
                flags.append(
                    {
                        "flag_id": flag_id(FLAG_KIND_FINGERPRINT, key, train_key),
                        "kind": FLAG_KIND_FINGERPRINT,
                        "band": name,
                        "candidate_key": key,
                        "peer_key": None,
                        "training_key": training_row_key(train_key),
                        "evidence": f"standardized cosine {score:.4f} vs {train_key}",
                        "score": round(score, 6),
                    }
                )

    cross_stats = cohort_stats([v for _, _, v in candidates])
    cross = [(b, k, standardize(v, cross_stats)) for b, k, v in candidates]
    for i in range(len(cross)):
        band_a, key_a, vec_a = cross[i]
        for j in range(i + 1, len(cross)):
            band_b, key_b, vec_b = cross[j]
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
                    "training_key": None,
                    "evidence": (
                        f"standardized cosine {score:.4f} across bands {band_a} and {band_b}"
                    ),
                    "score": round(score, 6),
                }
            )
    flags.sort(key=lambda f: f["flag_id"])
    return flags


def build_pool_universe(
    inputs: dict, retain_manifest_matches: bool = False
) -> tuple[dict[str, list[dict]], dict[str, Any], str]:
    """Steps shared by `prepare-review` and every mint, in the SAME order, so
    both compute the same candidate-universe digest: metadata exclusion, then
    content binding, then the digest. Content binding precedes the fingerprint
    route deliberately - a row whose audio cannot be resolved can never be
    staged, so it is excluded before review rather than dispositioned.

    `retain_manifest_matches` must reach BOTH callers identically, which is why
    both derive it from `retain_training_manifest_matches`. A divergence here
    would move `candidate_universe_sha256` on one path only, and every recorded
    fingerprint disposition would stop validating against it.
    """
    bands, accounting = build_candidates(
        inputs["pool_rows"],
        inputs["tony_rows"],
        inputs["oa300_rows"],
        inputs["manifest_hashes"],
        inputs["tony_split_ids"],
        inputs["training_artist_keys"],
        retain_manifest_matches=retain_manifest_matches,
    )
    bands = bind_content_hashes(
        bands,
        accounting["exclusions"],
        lambda entry: _safe_resolve(entry, inputs["pool_audio_root"]),
        _safe_sha256_file,
    )
    if retain_manifest_matches:
        # The SAME reversed route, applied to the same content-addressed key, for
        # rows whose identity is not itself the audio hash. A manifest
        # `audioHash` is `corpus_common.file_sha256` over the raw bytes, which is
        # exactly what `bind_content_hashes` computes, so a Tony or OA300
        # candidate can sit in a training manifest by content while its identity
        # (a track id, a filename) matches nothing. Those rows were previously
        # reachable only through the fingerprint route, which the obligation gate
        # cannot re-derive at audit time.
        #
        # STRICTLY ADDITIVE and repartition-only: it records an obligation and
        # never an exclusion, so candidate construction under every other policy
        # stays byte-identical, and no route is widened into an exclusion it did
        # not already have.
        manifest_hashes = inputs["manifest_hashes"]
        for name in BAND_NAMES:
            for entry in bands[name]:
                digest = str(entry.get("contentSha256") or "")
                if digest and digest in manifest_hashes:
                    accounting["partition_obligations"].append(
                        _obligation(
                            candidate_key(entry),
                            name,
                            OBLIGATION_ROUTE_MANIFEST_CONTENT,
                            training_row_key(f"{TRAINING_SOURCE_MANIFEST}:{digest}"),
                        )
                    )
    return bands, accounting, candidate_universe_digest(bands)


def drop_uncoverable(
    bands: dict[str, list[dict]], exclusions: dict[str, dict[str, int]], coverage: dict
) -> dict[str, list[dict]]:
    """Hard-exclude every candidate the mandatory route could not cover."""
    roster = coverage["candidate_roster"]
    out: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    for name in BAND_NAMES:
        for entry in bands[name]:
            if roster.get(candidate_key(entry)) != "resolved":
                exclusions[name]["fingerprint-uncoverable"] += 1
                continue
            out[name].append(entry)
    return out


# ---------------------------------------------------------------------------
# Signed exhaustion fallback (section 2, "Replacement rule")
# ---------------------------------------------------------------------------


def build_fallback_candidates(
    inputs: dict, primary: dict[str, list[dict]], excluded_for_cause: set[str]
) -> tuple[dict[str, list[dict]], dict[str, dict[str, int]]]:
    """Enumerate the precommitted fallback extension set, per band.

    Source order is fixed by the signed protocol: (1) Tony's Rekordbox
    as-entered rows, then (2) OA300 rows, each banded by the same face-value
    rule. Rows already inside the primary pool are not new material, and rows
    the primary construction excluded FOR CAUSE (training overlap, unresolvable
    or unhashable audio, a confirmed fingerprint match) are never re-admitted -
    the fallback extends a pool, it does not relax an exclusion.

    Both facts together are why the addendum's net-new set is empty in this
    collection. Implementing it faithfully is what lets the operator SEE that
    rather than infer it.
    """
    fallback: dict[str, list[dict]] = {name: [] for name in BAND_NAMES}
    counts = {
        name: {"fallback_candidates": 0, "already_in_primary": 0, "net_new": 0}
        for name in BAND_NAMES
    }
    in_primary = {candidate_key(e) for name in BAND_NAMES for e in primary[name]}
    eligible, _ = build_candidates(
        [],  # source order (1) Tony then (2) OA300; the pool is not a fallback source
        inputs["tony_rows"],
        inputs["oa300_rows"],
        inputs["manifest_hashes"],
        inputs["tony_split_ids"],
        inputs["training_artist_keys"],
        # The reversed route acts on POOL rows only, and no pool row is passed
        # here, so the flag would be inert. Left at its default deliberately:
        # the fallback never relaxes an exclusion.
    )
    for name in BAND_NAMES:
        for entry in eligible[name]:
            key = candidate_key(entry)
            counts[name]["fallback_candidates"] += 1
            if key in in_primary or key in excluded_for_cause:
                counts[name]["already_in_primary"] += 1
                continue
            counts[name]["net_new"] += 1
            fallback[name].append(entry)
    return fallback, counts


# ---------------------------------------------------------------------------
# PURE PLANNING LAYER. `plan_commit` writes nothing: it returns every document
# a mint would produce, so the mint itself is "validate, plan, write, validate".
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class CommitPlan:
    master_seed: int
    n_band: int
    generation: str
    pools_doc: dict
    draws_doc: dict
    commitment: dict
    coverage: dict
    addendum: dict | None
    short_bands: list[str]
    flags: list[dict]
    must_drop: dict


def plan_commit(
    inputs: dict, master_seed: int, supersedes: str | None, generated: str
) -> CommitPlan:
    # The decisions are read FIRST: the recorded short-band policy decides the
    # FR-59a.2 partition order, so it has to be known before a single candidate
    # is banded. `cmd_prepare_review` derives the same flag the same way.
    decisions = load_operator_decisions()
    short_policy = decisions["short_band_allocation"]["policy"]
    retain_manifest = retain_training_manifest_matches(decisions)
    bands, accounting, universe_digest = build_pool_universe(inputs, retain_manifest)
    exclusions = accounting["exclusions"]
    universe_keys = {candidate_key(e) for name in BAND_NAMES for e in bands[name]}

    coverage, cand_vectors, train_vectors = fingerprint_coverage(inputs, bands)
    amended = assert_training_coverage(coverage, accepted_uncovered_training_rows(decisions))
    coverage["amended_uncovered_training_rows"] = len(amended)

    flags = build_review_flags(bands, cand_vectors, train_vectors)
    dispositions = load_dispositions(
        universe_digest, {f["flag_id"] for f in flags}, partition_order_label(retain_manifest)
    )
    bands = drop_uncoverable(bands, exclusions, coverage)
    outcome = apply_dispositions(bands, exclusions, dispositions, flags, retain_manifest)
    bands = outcome.bands
    recording_groups = outcome.recording_groups
    confirmed = outcome.confirmed_total

    n_band = N_BAND
    if short_policy == "shrink-corpus":
        n_band = int(decisions["short_band_allocation"]["n_band"])
    if decisions["cross_band_duplicate_rule"]["policy"] == "pre-commitment-recording-dedup":
        bands = dedup_across_bands(
            bands,
            exclusions,
            list(decisions["cross_band_duplicate_rule"]["band_priority"]),
            recording_groups,
        )

    seed_rng = random.Random(master_seed)
    band_seeds = {name: seed_rng.getrandbits(32) for name in BAND_NAMES}
    fallback_seeds = {name: seed_rng.getrandbits(32) for name in BAND_NAMES}

    # The signed fallback is ENUMERATED whichever policy is in force, so its
    # emptiness is a reported measurement rather than an assumption; only
    # `fallback-addendum` appends it to the draw sequences and commits the
    # dated addendum artifact.
    kept_keys = {candidate_key(e) for name in BAND_NAMES for e in bands[name]}
    # Retaining confirmed training matches SHRINKS this set by design; the
    # fallback enumerator reads it, so its already-in-primary counts move too.
    # That is the amendment working, not a regression.
    excluded_for_cause = universe_keys - kept_keys
    fallback_rows, fallback_counts = build_fallback_candidates(inputs, bands, excluded_for_cause)
    fallback_rows = bind_content_hashes(
        fallback_rows,
        _empty_exclusions(),
        lambda entry: _safe_resolve(entry, inputs["pool_audio_root"]),
        _safe_sha256_file,
    )
    for name in BAND_NAMES:
        fallback_counts[name]["net_new"] = len(fallback_rows[name])
    use_fallback = short_policy == "fallback-addendum"

    # The MINT-TIME partition-obligation universe. Both reversed-route sources
    # feed it: the metadata route from `build_candidates` and the confirmed
    # training-fingerprint route from `apply_dispositions`. Rows that did not
    # survive dedup are dropped, because an obligation for a row that is not
    # even a candidate would ask the rebuild to drop training material for
    # nothing. The list bound at signoff is narrower still: MEMBERS only.
    obligations = dedup_obligations(
        [
            row
            for row in [*accounting["partition_obligations"], *outcome.obligations]
            if row["candidate_key"] in kept_keys
        ]
    )
    must_drop = {
        "schema_version": 1,
        "story": "12.7",
        "basis": "candidates-at-mint",
        "status": (
            OBLIGATION_STATUS_PROVISIONAL if retain_manifest else OBLIGATION_STATUS_NOT_APPLICABLE
        ),
        "policy": short_policy,
        "partition_order": partition_order_label(retain_manifest),
        "generated": generated,
        "protocol": PROTOCOL_POINTER,
        "fingerprint_method": FINGERPRINT_METHOD,
        "dispositions_sha256": sha256_file(DISPOSITIONS_PATH),
        "candidate_universe_sha256": universe_digest,
        "training_input_sha256": training_input_digest(),
        "training_input_digests": training_input_digests(),
        "note": MUST_DROP_NOTE,
        "obligations": obligations,
    }
    must_drop_sha256 = sha256_bytes(_json_bytes(must_drop))

    sequences: dict[str, list[dict]] = {}
    for i, name in enumerate(BAND_NAMES):
        primary_seq = draw_sequence(i, bands[name], band_seeds[name])
        extension: list[dict] = []
        if use_fallback and fallback_rows[name]:
            extension = draw_sequence(
                i,
                fallback_rows[name],
                fallback_seeds[name],
                offset=len(primary_seq),
                origin="fallback-addendum",
            )
        ids = [e["rowId"] for e in primary_seq + extension]
        if len(set(ids)) != len(ids):
            raise HarnessError(
                f"row-id collision between the primary and addendum sequences for {name}"
            )
        sequences[name] = primary_seq + extension

    pools_doc = {
        "schema_version": 3,
        "bands": {name: sequences[name] for name in BAND_NAMES},
        "pool_audio_root": inputs["pool_audio_root"],
        "seeds": band_seeds,
        "fallback_seeds": fallback_seeds,
        "master_seed": master_seed,
    }
    draws_doc = {
        "schema_version": 3,
        "seed_algorithm": SEED_ALGORITHM,
        "bands": {
            name: {
                "seed": band_seeds[name],
                "fallback_seed": fallback_seeds[name],
                "sequence": [e["rowId"] for e in sequences[name]],
            }
            for name in BAND_NAMES
        },
    }
    generation = "g" + sha256_bytes(_json_bytes({"p": pools_doc, "d": draws_doc}))[:16]

    band_counts = {name: len(sequences[name]) for name in BAND_NAMES}
    short_bands = [name for name in BAND_NAMES if band_counts[name] < n_band]

    addendum: dict | None = None
    if use_fallback:
        addendum = {
            "schema_version": 1,
            "story": "12.7",
            "dated": generated,
            "commitment_generation": generation,
            "policy": short_policy,
            "source_order": ["tony-as-entered", "oa300"],
            "bands": {name: dict(fallback_counts[name]) for name in BAND_NAMES},
            "note": FALLBACK_EMPTY_NOTE,
        }

    commitment = {
        # 4: the active record gained the required `partition_obligation` block
        # and `fingerprint_review.training_input_digests`. A reader keyed on the
        # version has to be able to tell a v3 record (no partition order on file)
        # from a v4 one.
        "schema_version": 4,
        "story": "12.7",
        "status": STATUS_ACTIVE,
        "generated": generated,
        "protocol": PROTOCOL_POINTER,
        "run_command": "make eval-corpus-pools",
        "seed_algorithm": SEED_ALGORITHM,
        "master_seed": master_seed,
        "n_band_target": n_band,
        "generation": generation,
        "supersedes_sha256": supersedes,
        "bands": {
            name: {
                "candidates": band_counts[name],
                "seed": band_seeds[name],
                "fallback_candidates": len(fallback_rows[name]) if use_fallback else 0,
                "fallback_seed": fallback_seeds[name],
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
            "recording_groups": len(set(recording_groups.values())),
            "dispositions_sha256": sha256_file(DISPOSITIONS_PATH),
            "candidate_universe_sha256": universe_digest,
            "training_input_sha256": training_input_digest(),
            # Immutable mint-time provenance (signed amendment, consequence 4):
            # the FR-59d rebuild changes these files by design, and without the
            # originals pinned per file that change reads as illegal drift.
            "training_input_digests": training_input_digests(),
            "coverage_sha256": sha256_bytes(_json_bytes(coverage)),
            "coverage": {
                "candidates_total": coverage["candidates_total"],
                "candidates_covered": coverage["candidates_covered"],
                "candidates_by_reason": coverage["candidates_by_reason"],
                "training_total": coverage["training_total"],
                "training_covered": coverage["training_covered"],
                "training_by_reason": coverage["training_by_reason"],
                "amended_uncovered_training_rows": len(amended),
            },
        },
        "operator_decisions": {
            "decisions_sha256": sha256_file(DECISIONS_PATH),
            "decided": str(decisions["decided"]),
            "short_band_allocation": short_policy,
            "cross_band_duplicate_rule": decisions["cross_band_duplicate_rule"]["policy"],
        },
        "partition_obligation": {
            "policy": short_policy,
            "route_reversed": PARTITION_ROUTE_REVERSED if retain_manifest else None,
            # ATTRIBUTIONS over the deduplicated obligations, not a partition of
            # them: one obligation can be found by more than one route.
            "retained_manifest_matches": sum(
                1
                for row in obligations
                if OBLIGATION_ROUTE_MANIFEST in row["routes"]
                or OBLIGATION_ROUTE_MANIFEST_CONTENT in row["routes"]
            ),
            "enumerated_fingerprint_matches": sum(
                1 for row in obligations if OBLIGATION_ROUTE_FINGERPRINT in row["routes"]
            ),
            "excluded_by_confirmed_disposition": outcome.confirmed_excluded,
            "excluded_training_fingerprint_matches": outcome.excluded_by_training_fingerprint,
            "excluded_giantsteps_matches": outcome.excluded_by_giantsteps,
            "must_drop_sha256": must_drop_sha256,
            "must_drop_count": len(obligations),
            "status": (
                OBLIGATION_STATUS_PROVISIONAL
                if retain_manifest
                else OBLIGATION_STATUS_NOT_APPLICABLE
            ),
            "note": PARTITION_OBLIGATION_NOTE,
        },
        "fallback_addendum": {
            "policy": short_policy,
            "dated": generated,
            "fallback_candidates_by_band": {
                n: fallback_counts[n]["fallback_candidates"] for n in BAND_NAMES
            },
            "already_in_primary_by_band": {
                n: fallback_counts[n]["already_in_primary"] for n in BAND_NAMES
            },
            "net_new_by_band": {
                n: (fallback_counts[n]["net_new"] if use_fallback else 0) for n in BAND_NAMES
            },
            "addendum_sha256": (sha256_bytes(_json_bytes(addendum)) if addendum else None),
            "note": FALLBACK_EMPTY_NOTE,
        },
        "pool_file_sha256": sha256_bytes(_json_bytes(pools_doc)),
        "draw_file_sha256": sha256_bytes(_json_bytes(draws_doc)),
        "short_bands": short_bands,
        "notes": [LEDGER_INTEGRITY_NOTE],
    }
    return CommitPlan(
        master_seed=master_seed,
        n_band=n_band,
        generation=generation,
        pools_doc=pools_doc,
        draws_doc=draws_doc,
        commitment=commitment,
        coverage=coverage,
        addendum=addendum,
        short_bands=short_bands,
        flags=flags,
        must_drop=must_drop,
    )


def _write_plan(plan: CommitPlan) -> None:
    """Write a plan's artifacts, canonical row-level files FIRST and the
    commitment LAST, so a crash never leaves an active commitment pointing at
    documents that do not exist."""
    gen = plan.generation
    _write_json(COVERAGE_PATH, plan.coverage)
    # Row-level obligations are PRIVATE (a member row id joined to a training
    # row id); only the digest and the counts go into the commitment. The check
    # hashes the FILE, like the sibling check below: hashing the in-memory object
    # against a digest computed from that same object is a tautology.
    _write_json(must_drop_path(gen), plan.must_drop)
    if sha256_file(must_drop_path(gen)) != plan.commitment["partition_obligation"].get(
        "must_drop_sha256"
    ):
        raise HarnessError(
            f"{must_drop_path(gen).name} does not hash to the planned must_drop_sha256 "
            "after writing"
        )
    _write_json(pools_path(gen), plan.pools_doc)
    _write_json(draws_path(gen), plan.draws_doc)
    for path, key in ((pools_path(gen), "pool_file_sha256"), (draws_path(gen), "draw_file_sha256")):
        if sha256_file(path) != plan.commitment[key]:
            raise HarnessError(f"{path.name} does not hash to the planned {key} after writing")
    if plan.addendum is not None:
        gate_committed(plan.addendum, assert_addendum_schema)
        _write_json(ADDENDUM_JSON, plan.addendum)
    gate_committed(plan.commitment, assert_commitment_schema)
    _write_json(COMMITMENT_JSON, plan.commitment)
    _write_text_atomic(COMMITMENT_MD, render_commitment_md(plan.commitment))


def _report_plan(plan: CommitPlan) -> None:
    c = plan.commitment
    for name in BAND_NAMES:
        print(
            f"  {name:9s} candidates={c['bands'][name]['candidates']:4d} "
            f"exclusions={c['bands'][name]['exclusions']}"
        )
    print(f"tag-less by source: {c['tagless_by_source']}")
    fr = c["fingerprint_review"]
    print(
        f"fingerprint coverage: candidates {fr['coverage']['candidates_covered']}/"
        f"{fr['coverage']['candidates_total']} {fr['coverage']['candidates_by_reason']}; "
        f"training {fr['coverage']['training_covered']}/{fr['coverage']['training_total']} "
        f"{fr['coverage']['training_by_reason']}"
    )
    po = c["partition_obligation"]
    print(
        f"FR-59a.2 partition order: {po['policy']} "
        f"(route reversed: {po['route_reversed'] or 'none'}); must-drop obligations "
        f"{po['must_drop_count']} distinct pair(s) (metadata "
        f"{po['retained_manifest_matches']}, fingerprint "
        f"{po['enumerated_fingerprint_matches']}, routes overlap), still excluded by a "
        f"confirmed disposition {po['excluded_by_confirmed_disposition']}; status "
        f"{po['status']}"
    )
    print(f"generation: {plan.generation}; pool_file_sha256: {c['pool_file_sha256']}")


def _missing_prerequisites() -> list[str]:
    """ONLY the prerequisites genuinely absent. Round 1 printed 'present' for
    each satisfied gate under the headline 'blocked on the following, all of
    which must be on record first' and then halted anyway, so satisfying every
    stated gate failed identically to satisfying none."""
    missing: list[str] = []
    if not DISPOSITIONS_PATH.exists():
        missing.append(
            f"MISSING fingerprint dispositions ({DISPOSITIONS_PATH.name}). Run "
            "`prepare-review` to generate the flag set plus the disposition template, then "
            "record a human disposition for every flag."
        )
    if not DECISIONS_PATH.exists():
        missing.append(
            f"MISSING operator decisions ({DECISIONS_PATH.name}), both of them: "
            f"(a) short-band allocation {list(SHORT_BAND_POLICIES)}; "
            f"(b) cross-band duplicate rule {list(CROSS_BAND_POLICIES)}."
        )
    return missing


def prior_generation_annotation_state(commitment: dict) -> list[str]:
    """A re-mint refuses while the prior generation carries annotation state.

    Every event references the active commitment while batches, annotations,
    staging and membership are generation-scoped; a successor over live
    annotation state would strand labels that cannot be regenerated.
    """
    gen = commitment.get("generation")
    if not gen:
        return []
    blockers: list[str] = []
    events = read_events(ledger_path(str(gen)))
    if events:
        blockers.append(f"{len(events)} annotation-ledger event(s) in generation {gen}")
    ann = annotations_dir(str(gen))
    if ann.exists():
        records = sorted(ann.glob("*/*.json"))
        if records:
            blockers.append(f"{len(records)} annotation record(s) in generation {gen}")
    rp = read_events(repass_ledger_path(str(gen)))
    if rp:
        blockers.append(f"{len(rp)} re-pass event(s) in generation {gen}")
    return blockers


# ---------------------------------------------------------------------------
# commit-pools / remint
# ---------------------------------------------------------------------------


def cmd_commit_pools(args: argparse.Namespace) -> int:
    inputs = load_inputs()

    if COMMITMENT_JSON.exists():
        existing = read_commitment()
        if existing.get("status") != STATUS_ACTIVE:
            missing = _missing_prerequisites()
            if missing:
                raise OperatorHalt(
                    "COMMITMENT SUPERSEDED: the candidate commitment on record has status "
                    f"{existing.get('status')!r} and cannot be operated on or extended.\n"
                    "Re-minting is blocked on the following, all of which must be on "
                    "record first:\n  - " + "\n  - ".join(missing) + "\nNo mint was "
                    "performed and no committed digest was rewritten."
                )
            raise OperatorHalt(
                "COMMITMENT SUPERSEDED: the candidate commitment on record has status "
                f"{existing.get('status')!r}. Every stated prerequisite IS on record, so "
                "the next action is an explicit re-mint: run `make eval-corpus-remint`. It "
                "archives this record byte-for-byte, records `supersedes_sha256`, writes a "
                "fresh generation, and refuses if the prior generation carries any "
                "annotation state. `commit-pools` never overwrites a commitment."
            )
        master_seed = int(_require(existing, "master_seed", "existing commitment"))
        if args.seed is not None and int(args.seed) != master_seed:
            raise HarnessError(
                f"--seed {args.seed} conflicts with the recorded master seed "
                f"{master_seed}; a minted commitment's seed is immutable. Omit --seed "
                "to verify, or re-mint deliberately with `remint`."
            )
        print(f"existing commitment found; verifying with recorded master seed {master_seed}")
        plan = plan_commit(
            inputs, master_seed, existing.get("supersedes_sha256"), str(existing["generated"])
        )
        # A minted commitment is immutable: never regenerate-and-overwrite.
        # Check BOTH directions - today's regenerated documents against the
        # recorded digests (input drift) and the on-disk files against them
        # (tamper) - then restore a missing row-level file deterministically.
        verify_input_drift(existing, plan.pools_doc, plan.draws_doc)
        gen = str(_require(existing, "generation", "existing commitment"))
        restored = False
        # ALL THREE digest-pinned row-level files `_write_plan` writes, not two.
        # `must-drop-obligation.json` is gitignored and generation-scoped, and
        # under the signed 2026-08-11 repartition order the audit hard-fails
        # without it. Omitting it here meant losing that sidecar left this
        # command printing "commitment restored (inputs re-derived and
        # digest-matched)" and exiting 0 while the file stayed missing, with no
        # other command able to regenerate it: `remint` refuses once the prior
        # generation carries annotation state, and `commit-pools` never
        # overwrites a commitment, so audit/emit-manifest/signoff could never
        # run again and 258 irreplaceable hand annotations were stranded.
        obligation_block = _require(existing, "partition_obligation", "existing commitment")
        for path, doc, key, recorded in (
            (
                pools_path(gen),
                plan.pools_doc,
                "pool_file_sha256",
                _require(existing, "pool_file_sha256", "existing commitment"),
            ),
            (
                draws_path(gen),
                plan.draws_doc,
                "draw_file_sha256",
                _require(existing, "draw_file_sha256", "existing commitment"),
            ),
            (
                must_drop_path(gen),
                plan.must_drop,
                "partition_obligation.must_drop_sha256",
                _require(
                    obligation_block,
                    "must_drop_sha256",
                    "existing commitment partition_obligation",
                ),
            ),
        ):
            if path.exists():
                actual = sha256_file(path)
                if actual != recorded:
                    raise DriftError(
                        f"commitment digest mismatch - committed {key} {recorded} != "
                        f"on-disk {actual} for {path.name}. The row-level file was "
                        "tampered with; refusing to overwrite."
                    )
            else:
                # Hash the candidate bytes BEFORE writing them. Writing first and
                # checking after installed the mismatching file and only then
                # raised, so the next invocation found it present, classified it
                # as tamper, and refused to overwrite - turning recoverable
                # missing state into permanently corrupt state, with an error
                # that claimed to be "refusing to install" a file it had already
                # written. `verify_input_drift` covers pools and draws only, so
                # this is the sole guard for the must-drop sidecar.
                payload = _json_bytes(doc)
                written = sha256_bytes(payload)
                if written != recorded:
                    raise DriftError(
                        f"cannot restore {path.name}: the re-derived document hashes to "
                        f"{written}, but the commitment pins {key} {recorded}. The mint "
                        "inputs have changed; refusing to install a file the commitment "
                        "does not describe. The missing file is left missing."
                    )
                _write_bytes_atomic(path, payload)
                restored = True
        state = "restored" if restored else "verified"
        print(
            f"commitment {state} (inputs re-derived and digest-matched) in generation {gen}: "
            f"pool_file_sha256 {existing['pool_file_sha256']}"
        )
        require_valid_state(load_state(), "after verifying the existing commitment")
        short = existing.get("short_bands", [])
        if short:
            raise OperatorHalt(
                f"bands below the {existing.get('n_band_target', N_BAND)}-candidate floor "
                f"remain recorded: {', '.join(short)}"
            )
        return 0

    master_seed = int(args.seed) if args.seed is not None else secrets.randbits(32)
    plan = plan_commit(inputs, master_seed, None, date.today().isoformat())
    _write_plan(plan)
    write_ledger_head(sha256_file(COMMITMENT_JSON), plan.generation)
    require_valid_state(load_state(), "after minting")
    _report_plan(plan)
    flush_fingerprint_cache()
    if plan.short_bands:
        raise OperatorHalt(
            f"bands below the {plan.n_band}-candidate floor at commitment: "
            f"{', '.join(plan.short_bands)}. Exhaustion escalation is the operator's. The "
            "signed fallback addendum was enumerated and recovers "
            f"{sum(plan.commitment['fallback_addendum']['net_new_by_band'].values())} net-new "
            "row(s); no auto-extension beyond it was performed."
        )
    return 0


def cmd_remint(args: argparse.Namespace) -> int:
    """Mint a successor to a superseded commitment.

    Ordering is crash-safe: validate everything first, archive the predecessor
    and verify the archive, build and verify every new artifact, and replace the
    canonical commitment LAST. Round 1 had no path here at all - `_superseded_halt`
    raised unconditionally while the artifacts told the operator to "re-mint with
    commit-pools", so the only escape was deleting a committed artifact.
    """
    if not COMMITMENT_JSON.exists():
        raise HarnessError(
            "nothing to re-mint: no commitment artifact exists. Run `commit-pools` to mint "
            "the first one."
        )
    existing = read_commitment()
    if existing.get("status") == STATUS_ACTIVE:
        raise HarnessError(
            "the commitment on record is ACTIVE. `remint` succeeds a SUPERSEDED record; "
            "supersede the active one deliberately before minting over it."
        )
    missing = _missing_prerequisites()
    if missing:
        raise OperatorHalt(
            "Re-minting is blocked on the following, all of which must be on record "
            "first:\n  - " + "\n  - ".join(missing)
        )
    blockers = prior_generation_annotation_state(existing)
    if blockers:
        raise OperatorHalt(
            "RE-MINT REFUSED: the prior generation carries annotation state ("
            + "; ".join(blockers)
            + "). Every event binds the active commitment while batches, annotations and "
            "membership are generation-scoped, so a successor here would strand labels that "
            "cannot be regenerated. Resolve the outstanding generation first."
        )

    inputs = load_inputs()
    prior_digest = sha256_file(COMMITMENT_JSON)
    prior_bytes = COMMITMENT_JSON.read_bytes()
    plan = plan_commit(
        inputs,
        int(args.seed) if args.seed is not None else secrets.randbits(32),
        prior_digest,
        date.today().isoformat(),
    )
    if plan.generation == existing.get("generation"):
        raise HarnessError(
            "the planned generation equals the superseded one; nothing would change. A "
            "re-mint must produce a distinct generation."
        )

    archive = archive_path(prior_digest, str(existing.get("generated", "undated")))
    if archive.exists() and archive.read_bytes() != prior_bytes:
        raise HarnessError(
            f"archive collision: {archive.name} exists with different bytes. An archived "
            "predecessor is never overwritten."
        )
    _write_bytes_atomic(archive, prior_bytes)
    if sha256_file(archive) != prior_digest:
        raise HarnessError("the archived commitment does not hash to the record it copied")

    _write_plan(plan)  # commitment replaced LAST, inside _write_plan
    write_ledger_head(sha256_file(COMMITMENT_JSON), plan.generation)
    require_valid_state(load_state(), "after re-minting")
    print(
        f"re-minted: archived {prior_digest[:12]} to {archive.name}; new generation "
        f"{plan.generation} supersedes it"
    )
    _report_plan(plan)
    flush_fingerprint_cache()
    if plan.short_bands:
        raise OperatorHalt(
            f"bands below the {plan.n_band}-candidate floor at commitment: "
            f"{', '.join(plan.short_bands)}. The signed fallback addendum was enumerated "
            f"and recovers "
            f"{sum(plan.commitment['fallback_addendum']['net_new_by_band'].values())} "
            "net-new row(s)."
        )
    return 0


def render_commitment_md(c: dict) -> str:
    lines = [
        "# Story 12.7: candidate-pool commitment record",
        "",
        f"Status: **{c['status']}**.",
        "",
        f"Generated {c['generated']} by `scripts/build-eval-corpus.py` "
        f"(`{c['run_command']}`). Counts, seeds, and the named commitment digests only; "
        "the row-level candidate inventory is gitignored per the privacy rule "
        "(OA300 and the collection inventory are private).",
        "",
        f"Signed protocol: `{c['protocol']}`.",
        "",
        f"Seed algorithm: {c['seed_algorithm']}. Master seed: {c['master_seed']}.",
        "",
    ]
    if c.get("generation"):
        lines += [f"Generation: `{c['generation']}` (every row-level path is scoped to it).", ""]
    if c.get("supersedes_sha256"):
        lines += [
            f"Supersedes commitment `{c['supersedes_sha256']}`, archived byte-for-byte "
            "alongside this record. Commitment validation walks the chain, so an archived "
            "predecessor cannot silently vanish.",
            "",
        ]
    if c["status"] == STATUS_SUPERSEDED:
        lines += [f"{c.get('superseded_note', '')}", ""]
    # Render only the exclusion routes this record actually ran. A superseded
    # v1 record predates the fingerprint route; printing a 0 under it would
    # claim the route ran and confirmed nothing.
    present: set[str] = set()
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
        cov = fr["coverage"]
        od = c["operator_decisions"]
        fb = c["fallback_addendum"]
        po = c["partition_obligation"]
        lines += [
            f"Pre-commitment fingerprint review (mandatory, signed section 2): method "
            f"{fr['method']}, {fr['flags']} review flag(s), {fr['confirmed_same_recording']} "
            f"confirmed same-recording, {fr['cleared']} cleared by recorded human "
            f"disposition, {fr['recording_groups']} transitive same-recording group(s). The "
            "algorithm flags; the disposition disposes. Outcomes of the confirmed "
            "dispositions, reported as ATTRIBUTIONS rather than as an arithmetic split "
            "(one candidate can carry several confirmed flags, and one obligation can be "
            f"found by several routes): {po['excluded_by_confirmed_disposition']} "
            f"candidate(s) excluded, of which {po['excluded_training_fingerprint_matches']} "
            f"attributable to a training-fingerprint match and "
            f"{po['excluded_giantsteps_matches']} to a GiantSteps-title match; "
            f"{po['enumerated_fingerprint_matches']} must-drop obligation(s) enumerated by "
            "a confirmed training-fingerprint match instead of excluding, per the partition "
            "order below.",
            "",
            f"Fingerprint coverage (the route fails closed): candidates "
            f"{cov['candidates_covered']} of {cov['candidates_total']} covered, by reason "
            f"{cov['candidates_by_reason']}; training rows {cov['training_covered']} of "
            f"{cov['training_total']} covered, by reason {cov['training_by_reason']}, with "
            f"{cov['amended_uncovered_training_rows']} accepted by dated operator amendment. "
            "An uncovered candidate is hard-excluded; an uncovered training row blocks "
            "certification.",
            "",
            f"Coverage digest: `{fr['coverage_sha256']}`",
            "",
            f"Dispositions digest: `{fr['dispositions_sha256']}`",
            "",
            f"Candidate-universe digest: `{fr['candidate_universe_sha256']}`",
            "",
            f"Training-input digest: `{fr['training_input_sha256']}`",
            "",
            "Mint-time training-input provenance, pinned per file so a later rebuild is "
            "attributable rather than one opaque mismatch: "
            + ", ".join(
                f"`{name}` `{digest}`"
                for name, digest in sorted(fr["training_input_digests"].items())
            ),
            "",
            f"FR-59a.2 partition order: **{po['policy']}**, status {po['status']}. Route "
            f"reversed: {po['route_reversed'] or 'none, all three routes exclude'}. Must-drop "
            f"obligations at mint: {po['must_drop_count']} distinct (eval row, training row) "
            f"pair(s), of which {po['retained_manifest_matches']} were found by the "
            f"training-manifest audioHash route and {po['enumerated_fingerprint_matches']} "
            "by a confirmed training-fingerprint disposition; a pair found by both is "
            "counted once in the total and under both routes. Must-drop digest "
            f"`{po['must_drop_sha256']}`; the row-level list is gitignored. {po['note']}",
            "",
            f"Operator decisions ({od['decided']}): short-band allocation "
            f"{od['short_band_allocation']}, cross-band duplicate rule "
            f"{od['cross_band_duplicate_rule']}; decisions digest "
            f"`{od['decisions_sha256']}`.",
            "",
            f"Signed exhaustion fallback (enumerated under EVERY short-band policy, "
            f"applied only under `fallback-addendum`): candidates by band "
            f"{fb['fallback_candidates_by_band']}, already in the primary pool "
            f"{fb['already_in_primary_by_band']}, NET NEW {fb['net_new_by_band']}. "
            f"{fb['note']}",
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
            FALLBACK_EMPTY_NOTE,
            "",
        ]
    for note in c.get("notes", []):
        lines += [note, ""]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# prepare-review
# ---------------------------------------------------------------------------


def cmd_prepare_review(_args: argparse.Namespace) -> int:
    """Stage 1 of the mandatory fingerprint route: generate flags, the coverage
    record, and a disposition template. Minting consumes the filled template, so
    a mint can never demand dispositions that were never generated."""
    # SAME derivation as `plan_commit`. If these two disagreed the candidate
    # universe digest would differ between review and mint, and every recorded
    # disposition would fail to validate against the mint.
    decisions = load_operator_decisions_if_present()
    retain_manifest = retain_training_manifest_matches(decisions)
    inputs = load_inputs()
    bands, _accounting, universe = build_pool_universe(inputs, retain_manifest)
    coverage, cand_vectors, train_vectors = fingerprint_coverage(inputs, bands)
    flags = build_review_flags(bands, cand_vectors, train_vectors)
    _write_json(COVERAGE_PATH, coverage)
    review = {
        "schema_version": 3,
        "candidate_universe_sha256": universe,
        "fingerprint_method": FINGERPRINT_METHOD,
        "review_cosine": FINGERPRINT_REVIEW_COSINE,
        "training_input_sha256": training_input_digest(),
        "training_input_digests": training_input_digests(),
        "partition_order": partition_order_label(retain_manifest),
        "coverage_sha256": sha256_bytes(_json_bytes(coverage)),
        "flags": flags,
    }
    _write_json(REVIEW_FLAGS_PATH, review)
    template = {
        "schema_version": 3,
        "candidate_universe_sha256": universe,
        "fingerprint_method": FINGERPRINT_METHOD,
        "training_input_sha256": training_input_digest(),
        "training_input_digests": training_input_digests(),
        "partition_order": partition_order_label(retain_manifest),
        "flags": [
            {
                "flag_id": f["flag_id"],
                "kind": f["kind"],
                "band": f["band"],
                # The keys are surfaced so a human CAN assign a shared
                # recording_group by hand; without them the operator had no key
                # material and the broken per-flag default was the likely path.
                "candidate_key": f["candidate_key"],
                "peer_key": f.get("peer_key"),
                # Mirrored so a confirmed training match round-trips with the
                # structured peer the must-drop list is built from.
                "training_key": f.get("training_key"),
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
        f"partition order: {partition_order_label(retain_manifest)}\n"
        f"coverage: candidates {coverage['candidates_covered']}/{coverage['candidates_total']} "
        f"{coverage['candidates_by_reason']}; training {coverage['training_covered']}/"
        f"{coverage['training_total']} {coverage['training_by_reason']}\n"
        f"flags: {REVIEW_FLAGS_PATH}\ntemplate: {DISPOSITIONS_TEMPLATE_PATH}\n"
        f"Record a disposition ({' or '.join(DISPOSITION_VALUES)}) for every flag and save "
        f"as {DISPOSITIONS_PATH.name}; minting is blocked until then."
    )
    flush_fingerprint_cache()
    if decisions is not None:
        # Surface a training-coverage block now rather than at mint time; the
        # files above are already written, so nothing is lost by halting here.
        assert_training_coverage(coverage, accepted_uncovered_training_rows(decisions))
    return 0


# ---------------------------------------------------------------------------
# Tracked ledger head
# ---------------------------------------------------------------------------


def write_ledger_head(commitment_sha: str, generation: str) -> dict:
    head, count = head_of(ledger_path(generation))
    active = latest_by_batch(read_events(ledger_path(generation)))
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
        "schema_version": 2,
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


# ---------------------------------------------------------------------------
# stage-batch
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class BatchPlan:
    band: str
    index: int
    start: int
    span: list[dict]
    order: list[str]
    order_seed: int
    resume: bool


def plan_batch(state: HarnessState, band: str, batch: int | None, size: int) -> BatchPlan:
    """Pure: decide which consecutive span becomes the next batch. Writes nothing."""
    if band not in BAND_NAMES:
        raise HarnessError(f"unknown band {band!r}; bands: {', '.join(BAND_NAMES)}")
    if size < 1:
        raise HarnessError(f"--size must be >= 1, got {size}")
    sequence = state.sequence(band)
    records = validate_batch_records(state.generation, band, state.sequence_row_ids(band))
    next_index = len(records)
    active = latest_by_batch(state.events)
    unanchored = [rec["batch"] for rec in records if (band, int(rec["batch"])) not in active]
    by_row_id = {e["rowId"]: e for e in sequence}

    if batch is not None and int(batch) == next_index - 1 and unanchored == [next_index - 1]:
        # Resume: re-stage the last recorded but not-yet-anchored batch
        # (record-then-stage means an interrupted copy leaves a record).
        rec = records[next_index - 1]
        return BatchPlan(
            band=band,
            index=next_index - 1,
            start=int(rec["start"]),
            span=[by_row_id[rid] for rid in rec["rowIds"]],
            order=list(rec["work_order"]),
            order_seed=int(rec["work_order_seed"]),
            resume=True,
        )
    if unanchored:
        raise HarnessError(
            f"batch(es) {unanchored} for {band} are staged but not anchored in the "
            "annotation ledger. Ingest or abandon them before staging another; several "
            "unanchored batches cannot accumulate behind illusory tamper evidence."
        )
    if batch is not None and int(batch) != next_index:
        raise HarnessError(
            f"batch out of sequence: next batch for {band} is {next_index}, "
            f"requested {batch} (pass the previous index to re-stage it)"
        )
    start = sum(int(rec["size"]) for rec in records)
    span = sequence[start : start + size]
    if not span:
        raise HarnessError(f"band {band} draw sequence exhausted at position {start}")
    band_seed = int(_require(_require(state.pools, "seeds", "candidate pools"), band, "seeds"))
    order_seed = (band_seed ^ (next_index * 0x9E3779B1)) & 0xFFFFFFFF
    return BatchPlan(
        band=band,
        index=next_index,
        start=start,
        span=span,
        order=work_order([e["rowId"] for e in span], order_seed),
        order_seed=order_seed,
        resume=False,
    )


def cmd_stage_batch(args: argparse.Namespace) -> int:
    state = load_state()
    require_valid_state(state, "before staging")
    plan = plan_batch(state, args.band, args.batch, int(args.size))
    gen = state.generation
    band_batches = batches_dir(gen) / plan.band
    band_batches.mkdir(parents=True, exist_ok=True)
    if not plan.resume:
        # Record BEFORE staging: an interrupted copy leaves a batch record
        # rather than orphan audio files.
        _write_json(
            band_batches / f"batch-{plan.index:03d}.json",
            {
                "band": plan.band,
                "batch": plan.index,
                "size": len(plan.span),
                "start": plan.start,
                "rowIds": [e["rowId"] for e in plan.span],
                "work_order_seed": plan.order_seed,
                "work_order": plan.order,
            },
        )
    stage = staging_dir(gen) / plan.band / f"batch-{plan.index:03d}"
    rows = stage_copies(plan.span, stage, state.pools.get("pool_audio_root"), plan.order)
    worklist = worklist_path_for(gen, plan.band, plan.index)
    write_worklist(worklist, rows)
    require_valid_state(load_state(), "after staging", require_audio=True)
    verb = "re-staged" if plan.resume else "staged"
    print(
        f"{verb} batch {plan.index} for {plan.band}: {len(plan.span)} rows -> {stage}\n"
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
    must appear exactly once and be well-formed, or NOTHING is applied.

    Shared verbatim by the primary ingest and the section-6 blind re-pass; the
    re-pass keys it by its own aliases, never by the original row ids.
    """
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


def _next_annotation_version(state: HarnessState, band: str, batch: int) -> int:
    versions = [
        int(ev.get("annotation_version", 0))
        for ev in state.events
        if str(ev.get("band")) == band and int(ev.get("batch", -1)) == batch
    ]
    return (max(versions) if versions else 0) + 1


def _batch_record(state: HarnessState, band: str, batch: int) -> dict:
    if band not in BAND_NAMES:
        raise HarnessError(f"unknown band {band!r}")
    records = validate_batch_records(state.generation, band, state.sequence_row_ids(band))
    if batch < 0 or batch >= len(records):
        raise HarnessError(
            f"batch {batch} for {band} has no validated record (records: {len(records)})"
        )
    return records[batch]


def _assert_transition(state: HarnessState, band: str, batch: int, nxt: str) -> str | None:
    current = latest_by_batch(state.events).get((band, batch))
    status = None if current is None else str(current.get("status"))
    allowed = EVENT_TRANSITIONS.get(status, frozenset())
    if nxt not in allowed:
        raise HarnessError(
            f"transition {status!r} -> {nxt!r} for {band}/batch-{batch:03d} is not allowed "
            f"(permitted: {sorted(allowed) or 'none - terminal state'})"
        )
    return status


def cmd_ingest(args: argparse.Namespace) -> int:
    batch = int(args.batch)
    state = load_state()
    require_valid_state(state, "before ingest")
    record = _batch_record(state, args.band, batch)
    gen = state.generation

    prior_status = latest_by_batch(state.events).get((args.band, batch))
    if prior_status is not None and not args.force:
        raise HarnessError(
            f"annotation record for {args.band}/batch-{batch:03d} is already anchored in "
            "the ledger; re-ingest requires --force (a replacement event and a NEW "
            "immutable record version are appended, and no prior record is overwritten)"
        )
    status = LEDGER_REPLACEMENT if prior_status is not None else LEDGER_COMPLETED
    _assert_transition(state, args.band, batch, status)

    # Validate the worklist BEFORE accepting annotations. Verifying only the
    # digest recorded AT ingest is too late: a worklist altered beforehand has
    # its altered digest anchored as the reference.
    worklist_failures = validate_worklist(
        gen, args.band, batch, record, state.by_row_id, require_audio=True
    )
    if worklist_failures:
        raise HarnessError(
            "refusing to accept annotations - the batch worklist does not validate:\n  "
            + "\n  ".join(worklist_failures)
        )

    annotations = parse_annotations_csv(Path(args.annotations), list(record["rowIds"]))
    version = _next_annotation_version(state, args.band, batch)
    record_path = annotations_dir(gen) / args.band / f"batch-{batch:03d}.v{version}.json"
    meta: dict[str, Any] = {"band": args.band, "batch": batch, "version": version}
    if prior_status is not None:
        meta["supersedes_sha256"] = str(prior_status.get("annotation_sha256"))
    _write_json_immutable(record_path, {"_meta": meta, "rows": annotations})

    keepers = sum(1 for rid in record["rowIds"] if keep_or_reject(annotations[rid], args.band)[0])
    append_event(
        ledger_path(gen),
        {
            "commitment_sha256": state.commitment_sha,
            "band": args.band,
            "batch": batch,
            "status": status,
            "recorded": date.today().isoformat(),
            "batch_record_sha256": sha256_file(
                batches_dir(gen) / args.band / f"batch-{batch:03d}.json"
            ),
            "work_order_sha256": sha256_file(worklist_path_for(gen, args.band, batch)),
            "annotation_version": version,
            "annotation_path": _rel(record_path, generation_root(gen)),
            "annotation_sha256": sha256_file(record_path),
            "counts": {"rows": len(annotations), "keepers": keepers},
        },
    )
    write_ledger_head(state.commitment_sha, gen)
    state = load_state()
    require_valid_state(state, "after ingest")
    membership = recompute_membership(state)
    _write_json(membership_path(gen), membership)
    m = membership[args.band]
    print(
        f"ingested batch {batch} for {args.band} as record version {version}: members "
        f"{len(m['members'])}/{state.n_band}, surplus {len(m['surplus'])}, rejects "
        f"{len(m['rejects'])}, annotated {m['annotated']}"
    )
    return 0


def cmd_abandon(args: argparse.Namespace) -> int:
    """Signed rule: an abandoned batch yields no members and its partial work is
    discarded from MEMBERSHIP. It is not discarded from disk: prior annotation
    records stay, immutable and still referenced by their own events. Round 1
    unlinked them under --force, destroying labels that cannot be regenerated."""
    batch = int(args.batch)
    state = load_state()
    require_valid_state(state, "before abandon")
    _batch_record(state, args.band, batch)
    gen = state.generation
    prior = latest_by_batch(state.events).get((args.band, batch))
    if prior is not None and prior.get("status") != LEDGER_ABANDONED and not args.force:
        raise HarnessError(
            f"batch {batch} for {args.band} already has an annotation record; abandoning "
            "removes it from MEMBERSHIP (the record itself is retained, immutable) - pass "
            "--force to confirm"
        )
    _assert_transition(state, args.band, batch, LEDGER_ABANDONED)
    append_event(
        ledger_path(gen),
        {
            "commitment_sha256": state.commitment_sha,
            "band": args.band,
            "batch": batch,
            "status": LEDGER_ABANDONED,
            "recorded": date.today().isoformat(),
            "batch_record_sha256": sha256_file(
                batches_dir(gen) / args.band / f"batch-{batch:03d}.json"
            ),
            "work_order_sha256": GENESIS_DIGEST,
            "annotation_version": None,
            "annotation_path": None,
            "annotation_sha256": None,
            "counts": {"rows": 0, "keepers": 0},
            "reason": str(args.reason),
        },
    )
    write_ledger_head(state.commitment_sha, gen)
    state = load_state()
    require_valid_state(state, "after abandon")
    _write_json(membership_path(gen), recompute_membership(state))
    print(
        f"abandoned batch {batch} for {args.band}: contributes no annotations and no "
        "members; any prior annotation record is retained and remains verifiable"
    )
    return 0


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def cmd_status(_args: argparse.Namespace) -> int:
    state = load_state()
    require_valid_state(state, "before reporting status")
    n_band = state.n_band
    membership = recompute_membership(state)
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


def recorded_partition_order(commitment: dict) -> tuple[str, bool]:
    """(recorded short-band policy, is the reversed route in force).

    Read off the COMMITMENT, not off today's decisions file: the partition order
    a corpus was minted under is immutable, and editing the decisions file
    afterwards must not silently re-interpret an existing mint.
    """
    policy = str((commitment.get("operator_decisions") or {}).get("short_band_allocation") or "")
    return policy, policy == SHORT_BAND_REPARTITION


def _safe_int(value: object, default: int = 0) -> int:
    """Never raises. A non-numeric count in a committed artifact is a data
    problem to REPORT, not a traceback escaping `cmd_signoff`."""
    if isinstance(value, bool):
        return default
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return default if not math.isfinite(value) else int(value)
    if isinstance(value, str):
        try:
            return int(value.strip())
        except ValueError:
            return default
    return default


def read_mint_obligations(
    commitment: dict, generation: str
) -> tuple[dict[str, list[dict]], list[str]]:
    """The mint-time partition-obligation universe, keyed by candidate key.

    Verified against the digest the commitment pinned, so the private sidecar
    cannot be edited to make an obligation disappear.
    """
    block = commitment.get("partition_obligation") or {}
    recorded = block.get("must_drop_sha256")
    path = must_drop_path(generation)
    if not recorded:
        return {}, []
    if not path.exists():
        return {}, [
            f"the mint-time partition-obligation record {path.name} is missing; the "
            "commitment pins its digest, so the must-drop list cannot be verified"
        ]
    doc = _read_json(path, "partition obligation record")
    actual = sha256_bytes(_json_bytes(doc))
    if actual != recorded:
        return {}, [
            f"{path.name} hashes to {actual}, the commitment pinned {recorded} - the "
            "mint-time partition-obligation record was edited"
        ]
    by_key: dict[str, list[dict]] = {}
    for row in doc.get("obligations", []):
        by_key.setdefault(str(row["candidate_key"]), []).append(row)
    return by_key, []


def read_closure_record(
    commitment: dict, generation: str
) -> tuple[dict | None, str | None, list[str]]:
    """The FR-59d closure record, if a later story has written one.

    Returns (record, digest, failures). Absent is NOT a failure: it is the
    ordinary state of a corpus whose training rebuild has not happened yet, and
    the refusal that follows is the point. A record that is present but does not
    bind THIS commitment, this mint-time obligation set, or a zero residual
    overlap IS a failure, because a closure claim that does not verify is worse
    than none.
    """
    path = partition_closure_path(generation)
    if not path.exists():
        return None, None, []
    doc = _read_json(path, "partition closure record")
    failures: list[str] = []
    try:
        _assert_keys(doc, _CLOSURE_RECORD_KEYS, "partition-closure")
    except PrivacyError as exc:
        return None, None, [f"partition closure record: {exc}"]
    if doc.get("certified") is not True:
        failures.append("the partition closure record does not assert certified")
    if _safe_int(doc.get("residual_overlap"), -1) != 0:
        failures.append(
            "the partition closure record does not record ZERO residual overlap against "
            "the rebuilt training corpus"
        )
    expected = (commitment.get("partition_obligation") or {}).get("must_drop_sha256")
    if expected and doc.get("must_drop_sha256") != expected:
        failures.append(
            "the partition closure record closes a different must-drop list than the one "
            "this commitment pinned"
        )
    return doc, sha256_file(path), failures


def partition_closure_state(
    commitment: dict, generation: str | None = None
) -> tuple[dict, list[str]]:
    """The FR-59a.2 closure block an attestation must carry, plus any failures.

    ONE function, consulted by `cmd_signoff` and by `validate_attestation` alike,
    so the two can never disagree about whether a corpus is closed.

    Three ways to be certified, and one way to stay open:

      * `no-obligation` - the corpus was not minted under the reversed route, so
        nothing was ever retained that the training corpus still holds.
      * `obligation-vacuous` - it WAS minted under the reversed route but the
        measured overlap is zero. There is nothing for the rebuild to drop, so
        refusing forever would be a deadlock with no work behind it.
      * `closure-record` - a later story ran the rebuild and recorded a verified
        closure record binding this commitment and a zero residual overlap.

    Otherwise the obligation is OPEN and signoff refuses. The forward path is a
    closure RECORD, deliberately not a mutation of the minted commitment: the
    commitment is immutable and its archived copies must stay verifiable, so
    "certified" could never be written into it without breaking them. That is
    what keeps the signed amendment's consequence 5 (rebuild and signoff must not
    deadlock) satisfiable.
    """
    block = commitment.get("partition_obligation") or {}
    policy, repartitioned = recorded_partition_order(commitment)
    count = _safe_int(block.get("must_drop_count"))
    open_by_policy = repartitioned or block.get("status") == OBLIGATION_STATUS_PROVISIONAL
    record_digest: str | None = None
    failures: list[str] = []
    if not open_by_policy:
        certified, basis = True, "no-obligation"
    elif count == 0:
        certified, basis = True, "obligation-vacuous"
    else:
        gen = generation or str(commitment.get("generation") or "")
        record, record_digest, failures = (
            read_closure_record(commitment, gen) if gen else (None, None, [])
        )
        certified = record is not None and not failures
        basis = "closure-record" if certified else "open"
        if not certified:
            record_digest = None
    return {
        "certified": certified,
        "basis": basis,
        "policy": str(block.get("policy") or policy or "unrecorded"),
        "must_drop_sha256": block.get("must_drop_sha256"),
        "must_drop_count": count,
        "closure_record_sha256": record_digest,
        "note": PARTITION_CLOSURE_NOTE,
    }, failures


def member_must_drop(
    state: HarnessState,
    member_rows: list[tuple[str, dict]],
    obligations_by_key: dict[str, list[dict]],
) -> dict:
    """The provisional must-drop list, derived from the MEMBER roster.

    Not from all candidates: dropping training rows for candidates that were
    rejected or ended up surplus would starve training for nothing (signed
    amendment, consequence 2). Regenerated against the annotation-ledger head
    because membership evolves during annotation.

    Carries NO wall-clock timestamp. Its digest is what the FR-59d closure record
    binds, so it must be a pure function of the state it describes; a
    `date.today()` field would churn the digest daily and defeat that.
    """
    head, _count = head_of(ledger_path(state.generation))
    rows: list[dict] = []
    for band, entry in member_rows:
        for obligation in obligations_by_key.get(candidate_key(entry), []):
            rows.append(
                {
                    "row_id": entry["rowId"],
                    "candidate_key": candidate_key(entry),
                    "band": band,
                    "routes": list(obligation["routes"]),
                    "training_key": obligation["training_key"],
                }
            )
    rows.sort(key=lambda row: (row["row_id"], row["training_key"]["key"]))
    return {
        "schema_version": 1,
        "story": "12.7",
        "basis": "members",
        "status": OBLIGATION_STATUS_PROVISIONAL,
        "commitment_sha256": state.commitment_sha,
        "annotation_ledger_head": head,
        "fingerprint_method": FINGERPRINT_METHOD,
        "dispositions_sha256": (
            (state.commitment.get("fingerprint_review") or {}).get("dispositions_sha256")
        ),
        "training_input_digests_at_mint": (
            (state.commitment.get("fingerprint_review") or {}).get("training_input_digests")
        ),
        "note": MUST_DROP_NOTE,
        "must_drop": rows,
    }


def member_overlap_keys(entry: dict, manifest_hashes: set[str]) -> set[str]:
    """Training-manifest rows this member demonstrably IS, checkable at audit time.

    A manifest `audioHash` is `corpus_common.file_sha256` over the raw bytes,
    which is exactly the `contentSha256` bound onto every candidate row, so the
    content check covers Tony and OA300 members as well as pool ones. Driving
    this off `entry["identity"]` alone (which is the audio hash ONLY for pool
    rows) silently skipped every Tony and OA300 member.

    A re-encode that shares no bytes remains invisible here by construction. That
    is what the mint-time fingerprint route is for, and its confirmed matches are
    already recorded as obligations; this check is the completeness half.
    """
    keys: set[str] = set()
    digest = str(entry.get("contentSha256") or "")
    if digest and digest in manifest_hashes:
        keys.add(f"{TRAINING_SOURCE_MANIFEST}:{digest}")
    if entry.get("source") == "pool" and str(entry.get("identity")) in manifest_hashes:
        keys.add(f"{TRAINING_SOURCE_MANIFEST}:{entry['identity']}")
    return keys


def run_audit() -> tuple[list[str], list[str], list[str]]:
    """The shared fail-closed audit. Returns (failures, warnings, report)."""
    warnings: list[str] = []
    report: list[str] = []

    state = load_state()
    failures = validate_state(state)
    gen = state.generation
    pools = state.pools

    # 1. FR-59a.1: membership inputs read only verified tempi + the draw
    # sequence. Allowlist every annotation record, candidate row, and worklist
    # header; an unexpected key fails, whatever it is called.
    for name in BAND_NAMES:
        ann_dir = annotations_dir(gen) / name
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

    # 2. FR-59a.2 residual overlap over EVERY candidate, member or not.
    inputs = load_inputs()
    try:
        membership = recompute_membership(state)
    except HarnessError as exc:
        # A detected annotation problem must be REPORTED as an audit failure,
        # not raised past the caller: emit-manifest and signoff decide on this
        # list, and an exception would skip the remaining checks.
        failures.append(f"membership cannot be recomputed: {exc}")
        membership = {name: {"members": [], "surplus": [], "rejects": {}} for name in BAND_NAMES}
    by_row_id = state.by_row_id
    member_rows = [
        (name, by_row_id[rid]) for name in BAND_NAMES for rid in membership[name]["members"]
    ]
    member_entries = [entry for _band, entry in member_rows]
    all_candidates = [e for name in BAND_NAMES for e in pools["bands"][name]]
    policy_name, repartitioned = recorded_partition_order(state.commitment)
    for entry in all_candidates:
        if (
            not repartitioned
            and entry["source"] == "pool"
            and entry["identity"] in inputs["manifest_hashes"]
        ):
            failures.append(f"residual manifest-hash overlap: candidate {entry['rowId']}")
        # UNCHANGED under every partition order: the amendment reverses the
        # training-manifest audioHash route and nothing else.
        if entry["source"] == "tony":
            if entry["identity"] in inputs["tony_split_ids"]:
                failures.append(f"residual tony-split overlap: candidate {entry['rowId']}")
            akey = cc.canonical_artist_key(entry.get("artist"))
            if akey and akey in inputs["training_artist_keys"]:
                failures.append(f"residual training-artist overlap: candidate {entry['rowId']}")

    # 2b. The mint-time OBLIGATION gate (signed amendment, consequence 1). This
    # is NOT proof that FR-59a.2 holds and is labelled so wherever it is
    # reported: it asserts every eval member that appears in a CURRENT training
    # manifest is named on the recorded must-drop list, so the rebuild can drop
    # it. Closure is a fresh audit against the REBUILT training corpus, which is
    # FR-59d work in a later story.
    if repartitioned:
        # Gated on the policy: a non-repartition corpus has no obligation record,
        # and reading one unconditionally made a deleted zero-content file fail
        # the audit permanently with no regeneration path.
        obligations_by_key, obligation_failures = read_mint_obligations(state.commitment, gen)
        failures.extend(obligation_failures)
        listing = member_must_drop(state, member_rows, obligations_by_key)
        listed: dict[str, set[str]] = {}
        for row in listing["must_drop"]:
            listed.setdefault(row["row_id"], set()).add(row["training_key"]["key"])
        # Driven off the RECORDED obligation set cross-checked against today's
        # manifests, over every member regardless of source.
        for entry in member_entries:
            missing = member_overlap_keys(entry, inputs["manifest_hashes"]) - listed.get(
                entry["rowId"], set()
            )
            if missing:
                failures.append(
                    f"PARTITION OBLIGATION GAP: member {entry['rowId']} ({entry['source']}) "
                    f"is {len(missing)} current training-manifest row(s) by audio content "
                    "but is not enumerated against them on the recorded must-drop list. "
                    "The rebuild would leave them in the training corpus and FR-59a.2 "
                    "could never close. Re-run `prepare-review` and re-mint against "
                    "today's training inputs."
                )
        listing_digest = sha256_bytes(_json_bytes(listing))
        closure, closure_failures = partition_closure_state(state.commitment, gen)
        failures.extend(closure_failures)
        if closure["basis"] == "closure-record":
            record, _digest, _f = read_closure_record(state.commitment, gen)
            recorded_members = (record or {}).get("member_must_drop_sha256")
            if recorded_members != listing_digest:
                failures.append(
                    "the partition closure record binds member must-drop list "
                    f"{recorded_members}, but today's member roster produces "
                    f"{listing_digest} - the closure was certified against a different "
                    "member set"
                )
        if not failures:
            # Never write state on a failing audit: membership may be empty only
            # because `recompute_membership` raised, and an empty listing
            # clobbering a correct one is indistinguishable from "no obligations".
            _write_json(must_drop_members_path(gen), listing)
        report.append(
            f"FR-59a.2 partition order: {policy_name}. OBLIGATION GATE, not proof the "
            f"partition holds: {len(listing['must_drop'])} must-drop obligation(s) over "
            f"{len(member_entries)} member(s), every member overlapping a current training "
            "manifest by audio content enumerated. A re-encode sharing no bytes is covered "
            "only by the mint-time fingerprint route. Row-level entries stay in the "
            f"gitignored sidecar; its digest is {listing_digest}. Closure requires a fresh "
            "audit against the REBUILT training corpus (FR-59d, a later story), which "
            f"signoff refuses until it exists; closure basis today: {closure['basis']}."
        )
    else:
        # A policy change or a re-mint must not leave a stale member listing
        # behind claiming obligations that no longer exist.
        stale = must_drop_members_path(gen)
        if stale.exists():
            stale.unlink()
        report.append(
            f"FR-59a.2 partition order: {policy_name or 'unrecorded'}. Pre-amendment order: "
            "residual-overlap asserted over all candidates for all three routes."
        )

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
            key = candidate_key(entry)
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

    # 3. Duplicate check among members. The recording-GROUP check is the one the
    # `audit-fails-on-cross-band-duplicate` policy promises: a confirmed
    # cross-band re-encode differs in identity AND in bytes by definition, so
    # identity, content digest and normalized title all miss it. The groups come
    # from the transitive components persisted at mint.
    policy = state.commitment.get("operator_decisions", {}).get("cross_band_duplicate_rule")
    seen_ids: dict[str, str] = {}
    seen_titles: dict[str, str] = {}
    seen_content: dict[str, str] = {}
    seen_groups: dict[str, str] = {}
    for entry in member_entries:
        ident = candidate_key(entry)
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
        group = str(entry.get("recordingGroup") or "")
        if group:
            if group in seen_groups:
                failures.append(
                    f"cross-band duplicate member RECORDING: {entry['rowId']} vs "
                    f"{seen_groups[group]} share confirmed same-recording group {group} "
                    f"(cross-band duplicate rule in force: {policy})"
                )
            seen_groups[group] = entry["rowId"]
        nk = cc.normalize_track_key(entry.get("title", ""))
        if nk:
            if nk in seen_titles:
                failures.append(
                    f"duplicate member title (normalized): {entry['rowId']} vs {seen_titles[nk]}"
                )
            seen_titles[nk] = entry["rowId"]
    report.append(
        f"cross-band duplicate rule in force: {policy}; "
        f"{len(seen_groups)} confirmed recording group(s) among members."
    )

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
        "audit clean: state validation (commitment chain, generation-scoped row files, "
        "event store, immutable annotation records, worklists), FR-59a.1 assertion, the "
        "FR-59a.2 route checks (all candidates, GiantSteps included), and duplicate checks "
        "all pass. What the FR-59a.2 result MEANS is stated on the partition-order line "
        "above: under the repartition order the training-manifest route is an obligation "
        "gate, and a clean run records that every overlapping member is enumerated for the "
        "rebuild, NOT that FR-59a.2 currently holds."
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
    state = load_state()
    n_band = state.n_band
    membership = recompute_membership(state)
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
    by_row_id = state.by_row_id

    entries = []
    sentinel_per_band = {name: 0 for name in BAND_NAMES}
    for name in BAND_NAMES:
        annotations = load_annotations(state, name)
        for rid in membership[name]["members"]:
            entry = by_row_id[rid]
            ann = annotations[rid]
            verified = float(ann["verified_bpm"])
            labels = member_legacy_labels(entry, index, state.pools.get("pool_audio_root"))
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
    _write_json(generation_root(state.generation) / "258-corpus.jams.json", manifest)
    print(
        f"manifest written: {generation_root(state.generation) / '258-corpus.jams.json'} "
        f"({len(entries)} tracks; sentinel per band {sentinel_per_band})"
    )
    return 0


# ---------------------------------------------------------------------------
# Section-6 10 percent blind re-pass (signed 2026-08-08; two-tier disagreement
# per the operator clarification of 2026-08-11).
#
# The re-pass MEASURES REPEATABILITY. It does not relabel: a disagreement is
# data, resolved only by a dated amendment. It never feeds `compute_membership`,
# never replaces a primary annotation, and never appends an ordinary batch
# event - it has its own record, validator, and state machine.
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class RepassPlan:
    version: int
    seed: int
    population: list[str]
    population_sha256: str
    sample: list[str]
    aliases: dict[str, str]
    order: list[str]
    sample_sha256: str
    primary_labels: dict[str, float | None]
    ledger_head: str


def plan_repass(state: HarnessState, version: int, membership: dict) -> RepassPlan:
    """Independent, domain-separated draw over a SEPARATE permutation.

    Not a continuation or reuse of any membership sequence: the 258-member
    roster is frozen, sorted canonically, shuffled with `Random(repass_seed)`,
    and truncated to the sample size without replacement. The seed is derived by
    domain-separated hashing of the commitment digest and the annotation-ledger
    head, so it is reproducible and cannot collide with a band seed.
    """
    population = sorted(rid for name in BAND_NAMES for rid in membership[name]["members"])
    if not population:
        raise HarnessError("re-pass sampling requires a complete corpus; the roster is empty")
    head, _count = head_of(ledger_path(state.generation))
    seed = int(
        hashlib.sha256(f"12.7-repass|{state.commitment_sha}|{head}|{version}".encode()).hexdigest()[
            :16
        ],
        16,
    )
    rng = random.Random(seed)
    shuffled = list(population)
    rng.shuffle(shuffled)
    size = max(1, math.ceil(REPASS_FRACTION * len(population)))
    sample = shuffled[:size]
    # Fresh aliases, independently randomized order. Reusing the original row
    # ids would forfeit the only within-annotator blinding available: the
    # annotator cannot forget prior exposure, so "blind" here means blinded to
    # the first-pass BPM and flags, to membership position, and to the row id.
    aliases: dict[str, str] = {}
    used: set[str] = set()
    for rid in sample:
        while True:
            alias = f"x{version}-{rng.getrandbits(48):012x}"
            if alias not in used:
                break
        used.add(alias)
        aliases[rid] = alias
    order = [aliases[rid] for rid in sample]
    rng.shuffle(order)

    primary: dict[str, float | None] = {}
    for name in BAND_NAMES:
        annotations = load_annotations(state, name)
        for rid in membership[name]["members"]:
            if rid in aliases:
                value = annotations.get(rid, {}).get("verified_bpm")
                primary[rid] = None if value is None else float(value)
    return RepassPlan(
        version=version,
        seed=seed,
        population=population,
        population_sha256=sha256_bytes(_json_bytes({"population": population})),
        sample=sample,
        aliases=aliases,
        order=order,
        sample_sha256=sha256_bytes(_json_bytes({"sample": sorted(sample)})),
        primary_labels=primary,
        ledger_head=head,
    )


def repass_record_path(generation: str, version: int) -> Path:
    return repass_dir(generation) / f"repass-sample.v{version}.json"


def repass_annotation_path(generation: str, version: int) -> Path:
    return repass_dir(generation) / f"repass-annotations.v{version}.json"


def repass_worklist_path(generation: str, version: int) -> Path:
    return repass_dir(generation) / f"repass-worklist.v{version}.csv"


def latest_repass(state: HarnessState) -> tuple[int, str | None, dict | None]:
    """(version, status, event) of the newest re-pass generation."""
    if not state.repass_events:
        return 0, None, None
    newest = max(state.repass_events, key=lambda ev: (int(ev.get("version", 0)), int(ev["index"])))
    version = int(newest.get("version", 0))
    status = str(newest.get("status"))
    return version, status, newest


def cmd_repass_sample(_args: argparse.Namespace) -> int:
    state = load_state()
    require_valid_state(state, "before re-pass sampling")
    failures, _w, _r = run_audit()
    if failures:
        print("re-pass sampling refused: the shared audit is not clean.", file=sys.stderr)
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1
    membership = recompute_membership(state)
    short = [n for n in BAND_NAMES if len(membership[n]["members"]) < state.n_band]
    if short:
        print(
            "re-pass sampling refused: the signed mitigation runs AFTER the corpus is "
            f"complete; bands below {state.n_band}: {short}",
            file=sys.stderr,
        )
        return 1

    version, status, event = latest_repass(state)
    if status == REPASS_SAMPLED:
        raise HarnessError(
            f"re-pass version {version} is already sampled and awaiting annotations; "
            "ingest it before drawing another sample."
        )
    if status == REPASS_INGESTED and event is not None:
        head, _count = head_of(ledger_path(state.generation))
        # Read the head off the ledger EVENT, not the annotation document. Only
        # the event carries `annotation_ledger_head` (`cmd_repass_ingest` writes
        # the document with schema_version/story/version/recorded/sample_sha256/
        # rows/summary and nothing else), so reading the document returned None
        # forever, `None == head` was never true, and this guard could not fire.
        # A completed blind re-pass was therefore re-rollable: the seed includes
        # the version, so each redraw samples a different 26 tracks, and signoff
        # binds the latest ingested version. That turns the one bound mitigation
        # for annotation repeatability into a number that can be re-rolled.
        prior_head = event.get("annotation_ledger_head")
        if not is_sha256_hex(prior_head):
            raise HarnessError(
                f"re-pass version {version} is ingested but its ledger event carries no "
                "usable `annotation_ledger_head`, so whether the primary annotation ledger "
                "has moved since the sample was drawn cannot be established. Refusing to "
                "draw another sample: an unverifiable redraw is what this guard exists to "
                "prevent."
            )
        if prior_head == head:
            raise HarnessError(
                f"re-pass version {version} is complete and the primary annotation ledger "
                "has not moved since it was drawn. A new sample is warranted only when a "
                "dated amendment changed a sampled primary label."
            )
    version += 1

    plan = plan_repass(state, version, membership)
    by_row_id = state.by_row_id
    span = [by_row_id[rid] for rid in plan.sample]
    stage = repass_dir(state.generation) / f"staging-v{version}"
    rows = stage_copies(
        span, stage, state.pools.get("pool_audio_root"), plan.order, alias=plan.aliases
    )
    write_worklist(repass_worklist_path(state.generation, version), rows)

    record = {
        "schema_version": 1,
        "story": "12.7",
        "version": version,
        "drawn": date.today().isoformat(),
        "protocol": "12-6-metrical-level-convention.md section 6 (10 percent blind re-pass)",
        "seed": plan.seed,
        "seed_derivation": "sha256('12.7-repass|<commitment>|<ledger head>|<version>')[:16]",
        "seed_algorithm": SEED_ALGORITHM,
        "fraction": REPASS_FRACTION,
        "population_size": len(plan.population),
        "population_sha256": plan.population_sha256,
        "sample_size": len(plan.sample),
        "sample_sha256": plan.sample_sha256,
        "commitment_sha256": state.commitment_sha,
        "annotation_ledger_head": plan.ledger_head,
        "aliases": plan.aliases,
        "presentation_order": plan.order,
        "primary_labels": plan.primary_labels,
    }
    # Written BEFORE any re-pass annotation exists, and immutable thereafter.
    _write_json_immutable(repass_record_path(state.generation, version), record)
    append_event(
        repass_ledger_path(state.generation),
        {
            "commitment_sha256": state.commitment_sha,
            "version": version,
            "status": REPASS_SAMPLED,
            "recorded": date.today().isoformat(),
            "record_path": _rel(
                repass_record_path(state.generation, version), generation_root(state.generation)
            ),
            "record_sha256": sha256_file(repass_record_path(state.generation, version)),
            "annotation_ledger_head": plan.ledger_head,
        },
    )
    require_valid_state(load_state(), "after re-pass sampling")
    print(
        f"re-pass v{version} sampled: {len(plan.sample)} of {len(plan.population)} members "
        f"({REPASS_FRACTION:.0%}), seed {plan.seed}\n"
        f"worklist: {repass_worklist_path(state.generation, version)} (fresh aliases, "
        "independently randomized order; stage a FRESH DAW project per the signed SOP)"
    )
    return 0


def summarize_repass(record: dict, annotations: dict[str, dict]) -> dict[str, Any]:
    """Two-tier disagreement plus the CONTINUOUS absolute differences.

    Thresholding without the underlying distribution discards information, so
    median, maximum, and every paired value are recorded (the paired values stay
    in the private record; only the summary statistics reach the attestation).
    """
    aliases: dict[str, str] = record["aliases"]
    primary: dict[str, Any] = record["primary_labels"]
    rows: list[dict[str, Any]] = []
    counts = dict.fromkeys((REPASS_AGREE, REPASS_FINE, REPASS_METRICAL, REPASS_NON_COMPARABLE), 0)
    crossed = 0
    diffs: list[float] = []
    for row_id, alias in sorted(aliases.items()):
        ann = annotations.get(alias, {})
        second = ann.get("verified_bpm")
        if ann.get("tempo_unstable") or ann.get("irresolvable") or ann.get("audio_defect"):
            second = None
        first = primary.get(row_id)
        first_value = None if first is None else float(first)
        second_value = None if second is None else float(second)
        verdict = classify_repass(first_value, second_value)
        counts[verdict] += 1
        row: dict[str, Any] = {"row_id": row_id, "alias": alias, "verdict": verdict}
        if (
            verdict != REPASS_NON_COMPARABLE
            and first_value is not None
            and second_value is not None
        ):
            diff = abs(second_value - first_value)
            diffs.append(diff)
            row["abs_diff_bpm"] = round(diff, 4)
            if band_of(first_value) != band_of(second_value):
                row["crossed_band"] = True
                crossed += 1
        rows.append(row)
    comparable = len(aliases) - counts[REPASS_NON_COMPARABLE]
    return {
        "schema_version": 1,
        "sample_size": len(aliases),
        "comparable": comparable,
        "counts": counts,
        "crossed_band": crossed,
        "metrical_level_disagreement_rate": (
            round(counts[REPASS_METRICAL] / comparable, 6) if comparable else None
        ),
        "fine_disagreement_rate": (
            round(counts[REPASS_FINE] / comparable, 6) if comparable else None
        ),
        "median_abs_diff_bpm": round(statistics.median(diffs), 4) if diffs else None,
        "max_abs_diff_bpm": round(max(diffs), 4) if diffs else None,
        "paired_abs_diffs_bpm": [round(d, 4) for d in diffs],
        "rows": rows,
    }


def cmd_repass_ingest(args: argparse.Namespace) -> int:
    state = load_state()
    require_valid_state(state, "before re-pass ingest")
    version, status, event = latest_repass(state)
    if status != REPASS_SAMPLED or event is None:
        raise HarnessError(
            "no re-pass sample is awaiting annotations "
            f"(latest version {version}, status {status!r}). Run `repass-sample` first."
        )
    gen = state.generation
    record = _read_json(generation_root(gen) / str(event["record_path"]), "re-pass record")
    order = list(record["presentation_order"])
    worklist = repass_worklist_path(gen, version)
    rows = read_worklist(worklist)
    if [alias for alias, _ in rows] != order:
        raise HarnessError(
            "refusing to accept re-pass annotations: the worklist aliases are not the "
            "recorded presentation order - it was edited, reordered, or re-pointed"
        )
    stage = (repass_dir(gen) / f"staging-v{version}").resolve()
    by_alias = {alias: rid for rid, alias in record["aliases"].items()}
    for alias, audio in rows:
        path = Path(audio)
        if not _under(path, stage):
            raise HarnessError(f"re-pass worklist row {alias} points outside the staging directory")
        if not path.exists():
            raise HarnessError(f"staged re-pass audio for {alias} is missing")
        committed = str(state.by_row_id[by_alias[alias]].get("contentSha256") or "")
        actual = sha256_file(path)
        if committed and actual != committed:
            raise HarnessError(
                f"staged re-pass audio for {alias} hashes to {actual}, the commitment "
                f"records {committed} - this alias was pointed at different audio"
            )

    annotations = parse_annotations_csv(Path(args.annotations), order)
    summary = summarize_repass(record, annotations)
    doc = {
        "schema_version": 1,
        "story": "12.7",
        "version": version,
        "recorded": date.today().isoformat(),
        "sample_sha256": record["sample_sha256"],
        "rows": annotations,
        "summary": summary,
    }
    path = repass_annotation_path(gen, version)
    _write_json_immutable(path, doc)
    append_event(
        repass_ledger_path(gen),
        {
            "commitment_sha256": state.commitment_sha,
            "version": version,
            "status": REPASS_INGESTED,
            "recorded": date.today().isoformat(),
            "record_path": _rel(path, generation_root(gen)),
            "record_sha256": sha256_file(path),
            "annotation_ledger_head": record["annotation_ledger_head"],
        },
    )
    require_valid_state(load_state(), "after re-pass ingest")
    print(
        f"re-pass v{version} ingested: {summary['counts']} over {summary['sample_size']} "
        f"sampled tracks; metrical-level rate {summary['metrical_level_disagreement_rate']}, "
        f"fine rate {summary['fine_disagreement_rate']}, median |diff| "
        f"{summary['median_abs_diff_bpm']} BPM, max {summary['max_abs_diff_bpm']} BPM. "
        "Recorded, not gated: a disagreement is data, resolved only by a dated amendment."
    )
    return 0


def repass_status_for_signoff(state: HarnessState) -> tuple[dict, dict, Path]:
    """The validated, ingested re-pass this signoff will bind, or a hard error."""
    version, status, event = latest_repass(state)
    if status is None:
        raise HarnessError(
            "SIGNOFF REFUSED: no blind re-pass exists. The 2026-08-08 signoff bound a "
            "10 percent blind re-pass as the mitigation for 'independence, not "
            "correctness' (12-6 section 6, lines 484-492): a corpus may not receive the "
            "training-enabling attestation without it. Run `repass-sample`, annotate the "
            "worklist blind under the same DAW SOP, then `repass-ingest`."
        )
    if status != REPASS_INGESTED or event is None:
        raise HarnessError(
            f"SIGNOFF REFUSED: blind re-pass v{version} is sampled but not annotated."
        )
    gen = state.generation
    annotation_doc = _read_json(
        generation_root(gen) / str(event["record_path"]), "re-pass annotations"
    )
    sample_event = next(
        ev
        for ev in state.repass_events
        if int(ev.get("version", 0)) == version and ev.get("status") == REPASS_SAMPLED
    )
    sample_path = generation_root(gen) / str(sample_event["record_path"])
    sample = _read_json(sample_path, "re-pass record")

    head, _count = head_of(ledger_path(gen))
    if sample.get("annotation_ledger_head") != head:
        # A dated amendment that changes a sampled primary label invalidates the
        # comparison; the summary must regenerate against the amended head.
        current: dict[str, Any] = {}
        for name in BAND_NAMES:
            annotations = load_annotations(state, name)
            for rid in sample["aliases"]:
                if rid in annotations:
                    current[rid] = annotations[rid].get("verified_bpm")
        changed = [
            rid for rid, value in sample["primary_labels"].items() if current.get(rid) != value
        ]
        if changed:
            raise HarnessError(
                f"SIGNOFF REFUSED: the primary annotation ledger moved since blind re-pass "
                f"v{version} was drawn AND {len(changed)} sampled primary label(s) changed, "
                "so the recorded comparison no longer describes the corpus. Draw a new "
                "sample with `repass-sample` and re-annotate; the prior record is retained."
            )
    return sample, annotation_doc, generation_root(gen) / str(event["record_path"])


# ---------------------------------------------------------------------------
# signoff (an audit-bound attestation, not a hand-editable marker)
# ---------------------------------------------------------------------------


def attestation_digest(doc: dict) -> str:
    body = {k: v for k, v in doc.items() if k != "attestation_sha256"}
    return sha256_bytes(_json_bytes(body))


def validate_attestation(
    attestation_path: Path,
    commitment_path: Path,
    ledger_head_path: Path,
    n_band: int,
    state_root: Path | None = None,
) -> list[str]:
    """Shared with `train.py`: the training gate validates THIS, not the
    human-editable REVIEWER_SIGNOFF marker text.

    The validator READS AND HASHES every referenced artifact. Comparing the
    attestation's ledger-head STRING against the tracked head JSON validated a
    self-consistent set of copied fields rather than the artifacts themselves:
    it never recomputed the actual ledger head, never verified the head
    artifact's commitment binding, and never hashed the re-pass record.
    """
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

    generation = None
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
        generation = commitment.get("generation")

    if not ledger_head_path.exists():
        failures.append("signoff attestation references a ledger head artifact that is absent")
    else:
        head_doc = json.loads(ledger_head_path.read_text(encoding="utf-8"))
        if doc.get("annotation_ledger_head") != head_doc.get("head_sha256"):
            failures.append(
                "signoff attestation ledger head does not match the tracked ledger head"
            )
        if head_doc.get("commitment_sha256") != doc.get("commitment_sha256"):
            failures.append(
                "the tracked ledger head is bound to a different commitment than the attestation"
            )
        # Recompute the head from the event store itself rather than trusting
        # the tracked copy of it.
        root = state_root if state_root is not None else EVAL_CORPUS_DIR
        if generation:
            actual_head, _count = head_of(
                root / "generations" / str(generation) / "annotation-ledger.jsonl"
            )
            if actual_head != head_doc.get("head_sha256"):
                failures.append(
                    f"the ACTUAL annotation-ledger head is {actual_head}, the tracked head "
                    f"artifact records {head_doc.get('head_sha256')} - the event store and "
                    "the committed head disagree"
                )

    repass = doc.get("repass") or {}
    root = state_root if state_root is not None else EVAL_CORPUS_DIR
    if not generation:
        failures.append(
            "the commitment records no generation, so the re-pass record is unlocatable"
        )
    else:
        matches = [
            p
            for p in sorted((root / "generations" / str(generation) / "repass").glob("*.json"))
            if sha256_file(p) == repass.get("record_sha256")
        ]
        if not matches:
            failures.append(
                "no re-pass annotation record hashes to the digest the attestation records; "
                "the section-6 blind re-pass cannot be verified"
            )
        else:
            record = json.loads(matches[0].read_text(encoding="utf-8"))
            summary = record.get("summary", {})
            if record.get("sample_sha256") != repass.get("sample_sha256"):
                failures.append("the re-pass record adjudicates a different sample")
            for key, field_name in (
                ("sample_size", "sample_size"),
                ("metrical_level_disagreement_rate", "metrical_level_disagreement_rate"),
                ("fine_disagreement_rate", "fine_disagreement_rate"),
            ):
                if summary.get(key) != repass.get(field_name):
                    failures.append(
                        f"the attestation's re-pass {field_name} does not match the record"
                    )

    # FR-59a.2 closure. An attestation without a certified closure field is not
    # evidence a model may train on: the partition is open until the FR-59d
    # rebuild lands and a fresh audit against it records zero residual overlap.
    #
    # Recomputed through `partition_closure_state`, the SAME function `cmd_signoff`
    # consults, so the writer and the validator cannot disagree. Comparing the
    # attestation's copied `status` string against the commitment's was a second,
    # weaker rule: a commitment recording the reversed policy with a
    # `not-applicable` status validated a certified attestation.
    closure = doc.get("partition_closure") or {}
    if not closure.get("certified"):
        failures.append(
            "signoff attestation records an UNCERTIFIED FR-59a.2 partition closure "
            f"(policy {closure.get('policy')!r}, {closure.get('must_drop_count')} must-drop "
            "obligation(s) open). The training corpus rebuild and its closure audit are "
            "FR-59d work in a later story."
        )
    elif commitment_path.exists():
        recorded = json.loads(commitment_path.read_text(encoding="utf-8"))
        root = state_root if state_root is not None else EVAL_CORPUS_DIR
        previous = EVAL_CORPUS_DIR
        try:
            globals()["EVAL_CORPUS_DIR"] = root
            actual, closure_failures = partition_closure_state(
                recorded, str(recorded.get("generation") or "")
            )
        finally:
            globals()["EVAL_CORPUS_DIR"] = previous
        if not actual["certified"]:
            failures.append(
                "signoff attestation claims a certified FR-59a.2 partition closure, but "
                f"the artifacts on disk do not support it (basis {actual['basis']}"
                + (f"; {'; '.join(closure_failures)}" if closure_failures else "")
                + ")"
            )
        elif closure.get("closure_record_sha256") != actual["closure_record_sha256"]:
            failures.append(
                "signoff attestation binds a different FR-59a.2 closure record than the one on disk"
            )

    if doc.get("audit_result") != "clean":
        failures.append(f"signoff attestation records audit_result {doc.get('audit_result')!r}")
    members = doc.get("members_per_band", {})
    short = [b for b in BAND_NAMES if int(members.get(b, 0)) < n_band]
    if short:
        failures.append(f"signoff attestation records bands below {n_band}: {short}")
    return failures


def cmd_signoff(_args: argparse.Namespace) -> int:
    state = load_state()
    n_band = state.n_band
    failures, _warnings, _report = run_audit()
    if failures:
        print("signoff refused: the shared audit is not clean.", file=sys.stderr)
        for f in failures:
            print(f"AUDIT FAIL: {f}", file=sys.stderr)
        return 1
    membership = recompute_membership(state)
    members_per_band = {name: len(membership[name]["members"]) for name in BAND_NAMES}
    short = [name for name in BAND_NAMES if members_per_band[name] < n_band]
    if short:
        print(f"signoff refused: bands below {n_band} verified members: {short}", file=sys.stderr)
        return 1

    # FR-59a.2 closure, fail-closed. Under the signed repartition order the eval
    # corpus legitimately holds rows the training corpus still contains, so the
    # partition does not hold YET; it closes when the rebuild drops them and a
    # fresh audit against the REBUILT corpus finds zero overlap. That rebuild
    # and that audit are FR-59d work in a later story, so nothing here can
    # certify closure and signoff must refuse rather than issue an attestation
    # `train.py` would accept.
    closure, closure_failures = partition_closure_state(state.commitment, state.generation)
    if not closure["certified"]:
        digest = closure["must_drop_sha256"]
        print(
            "SIGNOFF REFUSED: the FR-59a.2 partition closure is not certified. This corpus "
            f"was minted under the {closure['policy']!r} order, which draws eval candidates "
            "that the two non-Rekordbox training manifests still contain: "
            f"{closure['must_drop_count']} must-drop obligation(s) are recorded and OPEN "
            f"(must-drop digest {digest if digest else 'not recorded'}). The mint-time "
            "obligation gate has passed, which only says every overlapping member is "
            "enumerated for the rebuild. Closure needs the training rebuild plus a fresh "
            f"audit against the REBUILT corpus recording zero residual overlap in "
            f"{partition_closure_path(state.generation).name}; both are FR-59d work in a "
            "later story. No attestation was written, so the training gate stays closed."
            + (
                "\nThe closure record present on disk does NOT verify: "
                + "; ".join(closure_failures)
                if closure_failures
                else ""
            ),
            file=sys.stderr,
        )
        return 1

    sample, annotation_doc, record_path = repass_status_for_signoff(state)
    summary = annotation_doc["summary"]
    head, _count = head_of(ledger_path(state.generation))
    doc = {
        "schema_version": 2,
        "story": "12.7",
        "attested": date.today().isoformat(),
        "commitment_sha256": state.commitment_sha,
        "annotation_ledger_head": head,
        "audit_result": "clean",
        "members_per_band": members_per_band,
        "repass": {
            "record_sha256": sha256_file(record_path),
            "population_sha256": sample["population_sha256"],
            "sample_sha256": sample["sample_sha256"],
            "sample_size": summary["sample_size"],
            "population_size": sample["population_size"],
            "seed": sample["seed"],
            "metrical_level_disagreements": summary["counts"][REPASS_METRICAL],
            "fine_disagreements": summary["counts"][REPASS_FINE],
            "non_comparable": summary["counts"][REPASS_NON_COMPARABLE],
            "crossed_band": summary["crossed_band"],
            "metrical_level_disagreement_rate": summary["metrical_level_disagreement_rate"],
            "fine_disagreement_rate": summary["fine_disagreement_rate"],
            "median_abs_diff_bpm": summary["median_abs_diff_bpm"],
            "max_abs_diff_bpm": summary["max_abs_diff_bpm"],
            "note": (
                "Section-6 10 percent blind re-pass, recorded not gated. Two-tier per the "
                "operator clarification of 2026-08-11: a metrical-level disagreement is a "
                "second reading within 4 percent of 2x or 0.5x the first; a fine "
                "disagreement is a same-level difference above 0.5 BPM. No pass/fail "
                "threshold exists - the signed text records the rate, and a gate would be "
                "a new bound item requiring its own signature."
            ),
        },
        "partition_closure": closure,
    }
    doc["attestation_sha256"] = attestation_digest(doc)
    gate_committed(doc, assert_attestation_schema)
    _write_json(ATTESTATION_JSON, doc)
    print(
        f"signoff attestation written: {ATTESTATION_JSON} (commitment {state.commitment_sha}, "
        f"ledger head {head}, re-pass v{sample['version']} metrical-level rate "
        f"{summary['metrical_level_disagreement_rate']}, fine rate "
        f"{summary['fine_disagreement_rate']}). The training gate validates this "
        "attestation and every artifact it references, not the REVIEWER_SIGNOFF marker text."
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

    p_remint = sub.add_parser("remint", help="mint a successor to a superseded commitment")
    p_remint.add_argument("--seed", type=int, default=None, help="master seed for the successor")
    p_remint.set_defaults(func=cmd_remint)

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
        help="append a replacement event + a new immutable record version",
    )
    p_ingest.set_defaults(func=cmd_ingest)

    p_abandon = sub.add_parser("abandon", help="record a batch as abandoned (yields no members)")
    p_abandon.add_argument("--band", required=True)
    p_abandon.add_argument("--batch", type=int, required=True)
    p_abandon.add_argument("--reason", default="operator-abandoned")
    p_abandon.add_argument(
        "--force", action="store_true", help="abandon a batch that already carries annotations"
    )
    p_abandon.set_defaults(func=cmd_abandon)

    p_status = sub.add_parser("status", help="per-band progress + keeper-rate estimate")
    p_status.set_defaults(func=cmd_status)

    p_audit = sub.add_parser(
        "audit", help="fail-closed state / FR-59a.1 / residual-overlap / duplicate audit"
    )
    p_audit.set_defaults(func=cmd_audit)

    p_emit = sub.add_parser(
        "emit-manifest", help="emit the JAMS corpus manifest (refuses if incomplete or dirty)"
    )
    p_emit.set_defaults(func=cmd_emit_manifest)

    p_rs = sub.add_parser(
        "repass-sample", help="draw the section-6 10 percent blind re-pass sample"
    )
    p_rs.set_defaults(func=cmd_repass_sample)

    p_ri = sub.add_parser("repass-ingest", help="ingest the blind re-pass annotations")
    p_ri.add_argument("--annotations", required=True, help="operator-filled CSV, keyed by alias")
    p_ri.set_defaults(func=cmd_repass_ingest)

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
