"""
Shared corpus helpers for Story 7.1 (corpus diagnostics + label-tier policy +
split-contamination audit). Develop-only — NOT shipped to main.

This is the single source of truth for:
  - the label-tier banding (exact half-open intervals on `truth_confidence`),
  - the canonical artist key (leave-artist-out grouping, DD #4),
  - the cross-corpus / cross-naming `normalize_track_key` (DD #10),
  - corpus loading + provenance hashing (AC9),
  - the Tony<->external-eval overlap detector (AC5),
  - the librosa peak-landmark audio fingerprint fallback (DD #3).

Stdlib-only at import time. numpy / librosa are imported lazily inside the
fingerprint helpers so the diagnostics + audit entry points do not drag in
torch / librosa unless audio fingerprinting is actually requested.

`normalize_track_key` here is KEPT IN SYNC with `dataset._normalize_track_key`
(DD #10 — the two develop-only dirs have no package boundary, so a documented
copy is the agreed contract). If you change one, change both, or factor them
into a single import.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
TONY_CORPUS_DIR = ML_TRAINING_DIR / "tony-corpus"
TONY_TRUTH_LABELS = TONY_CORPUS_DIR / "tony-truth-labels.json"
TONY_LABELER_SCRIPT = REPO_ROOT / "scripts" / "tony-tunes-labels.py"

# In-repo external-eval ground truth (ships to main; always present).
OA300_GT_PATH = (
    REPO_ROOT / "Tests" / "BoomBoomBoomKitBenchmarkTests" / "Fixtures" / "oa300-ground-truth.json"
)
# GiantSteps GT lives under the corpus dir (env-resolved, optional in-env).
GIANTSTEPS_GT_FILENAME = "giantsteps-tempo-ground-truth.json"

FINGERPRINT_CACHE = ML_TRAINING_DIR / "tony-corpus" / "fingerprint-cache.npz"


def _is_finite(x) -> bool:
    try:
        return math.isfinite(float(x))
    except (TypeError, ValueError):
        return False


# ---------------------------------------------------------------------------
# Tempo ratio geometry (Story 7.4 Task 0 / DD #2) — single source of the
# canonical larger/smaller ratio + the octave/harmonic tolerances.
#
# Promoted out of `corpus_diagnostics._canonical_ratio` so the categorization
# module, the diagnostics generator, and any future consumer share ONE ratio
# helper (the `tier_for` single-source discipline applied to ratio math).
# `corpus_diagnostics` imports `canonical_ratio` from here; do not re-define it.
# ---------------------------------------------------------------------------

# Relative tolerances on the canonical centroid ratio (Story 7.4 DD #2).
# OCTAVE: a 2:1 ratio is "octave" within OCTAVE_RATIO_TOL of 2.0 (scaled by 2.0
# so the absolute window is OCTAVE_RATIO_TOL*2.0 = 0.10 BPM-ratio units).
# HARMONIC: 3:2 or 3:1 within HARMONIC_RATIO_TOL of 1.5 / 3.0 respectively.
OCTAVE_RATIO_TOL = 0.05
HARMONIC_RATIO_TOL = 0.03


def canonical_ratio(a: float, b: float) -> float:
    """Larger / smaller, guarding zero/negative.

    Direction-symmetric: `canonical_ratio(170, 85) == canonical_ratio(85, 170)`,
    so a 0.5x runner-up needs no separate `double` branch (DD #2). Returns 0.0
    when either input is non-positive (the caller treats 0.0 as "no ratio").
    """
    if a <= 0 or b <= 0:
        return 0.0
    hi, lo = (a, b) if a >= b else (b, a)
    return hi / lo


# ---------------------------------------------------------------------------
# Label-tier banding (AC2 / DD #1) — EXACT half-open intervals on truth_confidence.
# Boundary records (exactly 0.65 / 0.80) land in the HIGHER tier (M2).
# `bpm_truth == null` abstentions are Reject regardless of confidence.
# ---------------------------------------------------------------------------

STRONG_MIN = 0.80
SOLID_MIN = 0.65
MARGINAL_MIN = 0.55

TIERS = ("Strong", "Solid", "Marginal", "Reject")
TRAINABLE_TIERS = ("Strong", "Solid")

# Snapshot the policy snapshot reconciles against (FR-14 "currently"; AC10).
# Epic 7 data-augmentation: hand-labeled Strong-tier tracks (diverse tempos,
# mostly 120-140 BPM) folded in to fill the GiantSteps-gate coverage gap. The
# intended Strong count grew 333 -> 423 (+90 batch) -> 523 (+190 batch, 100 net
# new 120-140-weighted tracks). Bumped in lockstep with the intentional
# expansion (an UNINTENDED label change would still trip the drift block).
PRD_TIER_SNAPSHOT = {"Strong": 523, "Solid": 745, "Marginal": 241, "Reject": 25}


def tier_for(truth_confidence: float | None, bpm_truth: float | None) -> str:
    """Band one track into a tier using exact half-open intervals.

    Strong   [0.80, inf)
    Solid    [0.65, 0.80)
    Marginal [0.55, 0.65)
    Reject   [0.00, 0.55)  PLUS every bpm_truth == null abstention.
    """
    if bpm_truth is None:
        return "Reject"
    if truth_confidence is None:
        return "Reject"
    c = float(truth_confidence)
    if c >= STRONG_MIN:
        return "Strong"
    if c >= SOLID_MIN:
        return "Solid"
    if c >= MARGINAL_MIN:
        return "Marginal"
    return "Reject"


def is_trainable(track: dict) -> bool:
    return tier_for(track.get("truth_confidence"), track.get("bpm_truth")) in TRAINABLE_TIERS


# ---------------------------------------------------------------------------
# Canonical artist key (AC6 / DD #4)
# ---------------------------------------------------------------------------

# Collaboration / feature separators, ordered so multi-char tokens match first.
_COLLAB_SPLIT = re.compile(
    r"\s*(?:&|/|\+|,| feat\.?| ft\.?| featuring | with | and | x | vs\.?| versus )\s*",
    re.IGNORECASE,
)
# Light alias/typo merges with documented residue. Keys are canonical-lowercased
# primary keys AFTER collab-splitting; values are the merge target. Best-effort
# only — deeper alias resolution is out of scope (residue documented in the
# audit output's `artistKeyResidue`).
_ARTIST_ALIASES = {
    "origin unknwon": "origin unknown",
}


def canonical_artist_key(artist: str | None) -> str:
    """Return a canonical artist key for leave-artist-out grouping.

    Splits collaboration strings to the PRIMARY (first) artist, lowercases,
    strips punctuation/whitespace, applies a best-effort alias merge. Returns
    "" for empty/whitespace artists — callers MUST exclude empty keys from the
    held-out slice AND the disjointness assertion (DD #4), never treat "" as a
    real artist.
    """
    if not artist:
        return ""
    primary = _COLLAB_SPLIT.split(artist.strip(), maxsplit=1)[0]
    key = primary.strip().lower()
    # Collapse internal punctuation to spaces, squash whitespace.
    key = re.sub(r"[^a-z0-9]+", " ", key).strip()
    key = re.sub(r"\s+", " ", key)
    return _ARTIST_ALIASES.get(key, key)


# ---------------------------------------------------------------------------
# Cross-naming track-key normalizer (DD #10)
#
# KEPT IN SYNC with `dataset._normalize_track_key`. Identical logic; if you
# change one, change both. The audit imports THIS copy; dataset.py keeps its
# own copy so its existing OA300<->GiantSteps leak check is unperturbed.
# ---------------------------------------------------------------------------


def normalize_track_key(s: str) -> str:
    """Normalize a filename or title for cross-corpus comparison.

    Strips: directory components, leading numbering ("4. "), bracketed/paren
    suffixes (artist/version tags), extension, whitespace; then lowercases.
    """
    name = os.path.basename(s)
    name = os.path.splitext(name)[0]
    name = re.sub(r"^\d+\s*[\.\-]\s*", "", name)
    name = re.sub(r"\s*[\[\(].*$", "", name)
    name = re.sub(r"\s+", " ", name).strip().lower()
    return name


# ---------------------------------------------------------------------------
# Provenance (AC9)
# ---------------------------------------------------------------------------


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


@dataclass
class CorpusProvenance:
    labels_path: str
    labels_sha256: str
    labeler_script_path: str
    labeler_script_sha256: str
    track_count: int


def load_tony_corpus(labels_path: Path = TONY_TRUTH_LABELS) -> tuple[list[dict], CorpusProvenance]:
    """Load tony-truth-labels.json and pin its provenance (AC9).

    Raises loudly (no silent fallback) if the develop-local corpus is absent.
    """
    if not labels_path.exists():
        raise FileNotFoundError(
            f"Tony corpus labels not found at {labels_path}. This corpus is "
            f"develop-local/gitignored; regenerate with `make tony-corpus`."
        )
    payload = json.loads(labels_path.read_text())
    tracks = payload.get("tracks")
    if not isinstance(tracks, list) or not tracks:
        raise ValueError(f"{labels_path} has no 'tracks' list — refusing to proceed.")
    # Loud-fail on corruption that would otherwise silently shrink/misband the
    # corpus: missing/duplicate track_ids (a dict keyed by them would collapse
    # records) and non-finite truth_confidence (would silently band as Reject).
    ids = [t.get("track_id") for t in tracks]
    if any(i is None for i in ids):
        raise ValueError(
            f"{labels_path}: {sum(i is None for i in ids)} track(s) missing a track_id."
        )
    str_ids = [str(i) for i in ids]
    if len(set(str_ids)) != len(str_ids):
        raise ValueError(
            f"{labels_path}: duplicate track_id(s) — refusing to proceed "
            f"(records would silently collapse)."
        )
    bad_conf = [
        str(t.get("track_id"))
        for t in tracks
        if t.get("truth_confidence") is not None and not _is_finite(t.get("truth_confidence"))
    ]
    if bad_conf:
        raise ValueError(
            f"{labels_path}: {len(bad_conf)} track(s) with non-finite "
            f"truth_confidence (label-pipeline corruption): {bad_conf[:5]}"
        )
    labeler_hash = file_sha256(TONY_LABELER_SCRIPT) if TONY_LABELER_SCRIPT.exists() else "absent"
    prov = CorpusProvenance(
        labels_path=str(labels_path),
        labels_sha256=file_sha256(labels_path),
        labeler_script_path=str(TONY_LABELER_SCRIPT),
        labeler_script_sha256=labeler_hash,
        track_count=len(tracks),
    )
    return tracks, prov


def tier_histogram(tracks: list[dict]) -> dict[str, int]:
    hist = {t: 0 for t in TIERS}
    for tr in tracks:
        hist[tier_for(tr.get("truth_confidence"), tr.get("bpm_truth"))] += 1
    return hist


# ---------------------------------------------------------------------------
# Cross-corpus overlap (AC5) — metadata-precise primary pass.
# ---------------------------------------------------------------------------


@dataclass
class ExternalIndex:
    """Normalized-title -> list of (corpus, original_title) for external eval."""

    by_norm: dict[str, list[tuple[str, str]]] = field(default_factory=dict)
    corpora_checked: list[str] = field(default_factory=list)

    def add(self, corpus: str, title: str) -> None:
        nk = normalize_track_key(title)
        if not nk:
            return
        self.by_norm.setdefault(nk, []).append((corpus, title))


def resolve_giantsteps_gt_path() -> Path | None:
    """Resolve the GiantSteps GT path from GIANTSTEPS_CORPUS_PATH (no hardcoded
    fallback, matching dataset.get_corpus_paths). Returns None when the env var
    is unset or the file is absent — the caller records GiantSteps as skipped
    rather than silently passing.
    """
    root = os.environ.get("GIANTSTEPS_CORPUS_PATH")
    if not root:
        return None
    p = Path(root).expanduser() / GIANTSTEPS_GT_FILENAME
    return p if p.exists() else None


def build_external_index(
    oa300_gt_path: Path = OA300_GT_PATH,
    giantsteps_gt_path: Path | None = None,
) -> ExternalIndex:
    """Index external-eval titles for the Tony overlap audit.

    OA300 GT is in-repo (always available). GiantSteps GT is corpus-resolved
    (optional in-env); when absent the audit records that GiantSteps coverage
    was skipped rather than silently passing.
    """
    idx = ExternalIndex()
    oa = json.loads(oa300_gt_path.read_text())
    if not isinstance(oa, list):
        raise ValueError(f"{oa300_gt_path} is not a JSON list of track records.")
    for t in oa:
        idx.add("oa300", t.get("title") or t.get("filename", ""))
    idx.corpora_checked.append("oa300")
    if giantsteps_gt_path and giantsteps_gt_path.exists():
        gs = json.loads(giantsteps_gt_path.read_text())
        if not isinstance(gs, list):
            raise ValueError(f"{giantsteps_gt_path} is not a JSON list of track records.")
        for t in gs:
            # GiantSteps filenames are numeric IDs (e.g. 1030011.LOFI.mp3) — a
            # title overlap with Tony's human-named DnB is structurally
            # near-impossible, but we still index defensively.
            idx.add("giantsteps", t.get("filename", ""))
        idx.corpora_checked.append("giantsteps")
    return idx


@dataclass
class CrossCorpusMatch:
    track_id: str
    tony_name: str
    normalized_key: str
    external_corpus: str
    external_title: str


def find_cross_corpus_matches(
    tracks: list[dict], external: ExternalIndex
) -> list[CrossCorpusMatch]:
    """Return Tony tracks whose normalized title collides with an external-eval
    title. Conservative by design (AC5): a normalized-title hit is treated as a
    same-recording leak and excluded, even for generic titles — excluding a
    false-positive from TRAINING is harmless; admitting a true leak inflates the
    FR-18 promotion gate.
    """
    matches: list[CrossCorpusMatch] = []
    for tr in tracks:
        nk = normalize_track_key(tr.get("name", ""))
        if not nk:
            continue
        hits = external.by_norm.get(nk)
        if not hits:
            continue
        # A normalized key can map to BOTH corpora; record every corpus it hit
        # (not just hits[0]) so the report doesn't understate the collision.
        corpora = sorted({c for c, _ in hits})
        corpus, title = hits[0]
        matches.append(
            CrossCorpusMatch(
                track_id=str(tr.get("track_id")),
                tony_name=tr.get("name", ""),
                normalized_key=nk,
                external_corpus="+".join(corpora),
                external_title=title,
            )
        )
    return matches


# ---------------------------------------------------------------------------
# Audio fingerprint (DD #3) — librosa timbral fallback.
#
# Chromaprint/AcoustID (pyacoustid + fpcalc) is the preferred method but is not
# installable in every dev env; this is the PRE-AUTHORIZED fallback (no HALT).
#
# Method: per-track RAW feature = MFCC(20) mean + MFCC(20) std + chroma_cqt(12)
# mean = 52-d timbral signature. Timbre is preserved across re-encodes /
# remasters / mild tempo-stretch, so same-recording variants score high; the
# MFCC std + mean give discrimination that a pooled-chroma-only signature lacks
# (an earlier chroma+onset-mean signature was DEGENERATE — dense electronic
# audio collapsed to ~uniform vectors scoring cosine 1.0 between unrelated
# tracks). Vectors are STANDARDIZED per-dimension across the cohort at compare
# time (see audit) before cosine, so no single MFCC band dominates.
#
# BLIND SPOT (documented per DD #3): this is still a coarse statistical
# signature — two different tracks with very similar instrumentation/tempo can
# score high, and a heavy remix can score low. It is a DEFENSIVE second pass
# that FLAGS pairs for human review; it is NEVER the sole auto-exclusion signal
# and does NOT gate the audit exit code (the metadata layer does that).
# ---------------------------------------------------------------------------

FINGERPRINT_METHOD = "librosa-mfcc-chroma-timbral-v2"
FINGERPRINT_DIM = 52  # 20 mfcc-mean + 20 mfcc-std + 12 chroma-mean
_FP_SR = 22050
_FP_DURATION = 60.0  # seconds analyzed (mid-track skip handled by offset)


def compute_fingerprint(audio_path: str) -> "np.ndarray | None":
    """Return a RAW float32 fingerprint vector (FINGERPRINT_DIM,) or None if the
    audio cannot be decoded. NOT unit-normed — the audit standardizes per
    dimension across the cohort before cosine. Lazy-imports numpy/librosa.
    """
    import numpy as np

    try:
        import librosa
    except ImportError:
        return None
    try:
        y, sr = librosa.load(audio_path, sr=_FP_SR, mono=True, duration=_FP_DURATION, offset=10.0)
    except Exception:
        return None
    if y is None or y.size < _FP_SR:  # < 1s decoded — unusable
        return None
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=20)  # (20, T)
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)  # (12, T)
    vec = np.concatenate([mfcc.mean(axis=1), mfcc.std(axis=1), chroma.mean(axis=1)]).astype(
        np.float32
    )
    if not np.all(np.isfinite(vec)):
        return None
    return vec


def content_hash(audio_path: str) -> str:
    """Stable cache key: sha1 of (size, mtime-rounded, path) — cheap, avoids
    re-hashing multi-MB audio while still invalidating on file change.
    """
    try:
        st = os.stat(audio_path)
        seed = f"{audio_path}|{st.st_size}|{int(st.st_mtime)}"
    except OSError:
        seed = audio_path
    return hashlib.sha1(seed.encode()).hexdigest()
