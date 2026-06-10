#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""Non-Rekordbox audio expansion survey + provenance-clean tiering (Story 7.2).

Develop-only. Surveys the audio files OUTSIDE Tony's Rekordbox `<COLLECTION>`,
runs a BPM-tag-blind DSP pass + an independent file-metadata BPM read, and tiers
each file as a semi-supervised pool for Story 7.3's KDD-B2 ablation.

Run it (the ml-training env provides corpus_common + mutagen):

    uv run --project _bmad-output/ml-training python scripts/non-rekordbox-survey.py \
        --xml /path/05092026.xml --audio-root /path/tony-tunes [--limit N]

WHAT IT DOES (the contract — see the story spec DDs):
- DD #1: the `non-rekordbox/` directory does NOT exist; the set is DERIVED as
  on-disk audio MINUS the Rekordbox `<COLLECTION>` BASENAMES. (Basename is the only
  available join — the XML `Location` attrs encode a foreign hostname, so paths
  cannot be resolved exactly; duplicate-basename groups are quarantined as
  `ambiguous_membership` so a shared basename never over-excludes a real file.)
  Using the XML for set MEMBERSHIP is partitioning, NOT per-file tiering evidence
  (FR-13/15).
- DD #9: the unmodified `tony-dsp-prepass` Swift CLI requires a non-optional
  track_id/name/artist and hard-filters resolve_status == "ok", so we SYNTHESIZE
  a survey shape with `track_id = audioHash` (the read-back join key) and feed
  only `analyzable` files (cloud_only / ambiguous_membership are partitioned out
  upstream so the CLI's "ok" filter cannot silently defeat the no-drop promise).
- DD #2: dspBPM/dspConfidence come from `tony-dsp-prepass --no-metadata`
  (MetadataPolicy.disabled => BPM-tag-blind); fileMetadataBPM is read INDEPENDENTLY
  via mutagen, so the agreement gate is not circular.
- DD #3/#4: `audioHash = corpus_common.file_sha256` (raw bytes, NOT the
  path-derived content_hash); sentinels are excluded by audioHash, never title.
- AC5: a pure typed `decide_tier(dsp_bpm, dsp_confidence, file_metadata_bpm,
  audio_hash)` is the provenance guard — forbidden columns are not in scope.

Downstream contract (AC9): Story 7.3's supervised-augmented loader reads
`non-rekordbox-secondary-supervised-manifest.json` (audioHash + relPath +
bpm_truth + labelConfidence); it uses relPath ONLY to fetch bytes, never as a
feature (its own FR-15 grep gate covers its loader code). The `unsupervisedPool`
subset is reserved for the masked-mel pretraining variant.
"""

from __future__ import annotations

import argparse
import collections
import json
import math
import os
import subprocess
import sys
import tempfile
import urllib.parse
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import TextIO

# mutagen (independent BPM-tag parser, DD #2). ty resolves these in the
# ml-training env; if a future mutagen drops its type info, add a scoped
# unresolved-import suppression here (AC10) — a typing diagnostic on this
# import is not a script bug.
from mutagen import File as MutagenFile
from mutagen.id3 import ID3
from mutagen.mp4 import MP4Tags

# Project-coupled: corpus_common lives in the ml-training dir. Insert it on the
# path before importing (mirrors scripts/audit-corpus-splits.py). `uv --project`
# provides the venv (mutagen, etc.); this insert provides the local module.
ML_TRAINING = Path(__file__).resolve().parent.parent / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

AUDIO_EXTS = {".mp3", ".wav", ".aif", ".aiff", ".flac", ".m4a", ".caf"}
# Mirror tony-tunes-labels.py CANONICAL_MIN/MAX (kept in sync; no import — the
# labeler script is hyphenated and not importable).
CANONICAL_MIN = 60.0
CANONICAL_MAX = 200.0
AGREEMENT_TOL = 0.03  # AC5 octave-normalized agreement window
REJECT_DSP_CONF_FLOOR = 0.40  # AC5 reject floor on the selected DSP result
SOLID_FLOOR = 0.65  # corpus_common tier floor; labels stay strictly below it
SECONDARY_LABEL_CONF_CAP = 0.64  # min(dspConfidence, cap) per DD #6
BPM_VALID_LO = 30.0
BPM_VALID_HI = 300.0

# FR-17 sentinel needles (mirror dataset.py DNB_TRIPLET_NEEDLES). Force-rejected
# by audioHash so held-out sentinels never enter the expansion pool.
SENTINEL_NEEDLES = ("charly", "faraday_bunker", "yin yang", "heft_anagram")

SWIFT_PACKAGE = ML_TRAINING / "swift_feature_extractor"
DIAGNOSTICS_MD = ML_TRAINING / "corpus-diagnostics-v1.md"
SENTINELS_12_JAMS = (
    ML_TRAINING.parent.parent
    / "Tests"
    / "BoomBoomBoomKitBenchmarkTests"
    / "Fixtures"
    / "12-dnb-sentinels-expanded.json"
)


# ---------------------------------------------------------------------------
# Small helpers mirrored from scripts/tony-tunes-survey.py (kept in sync — the
# survey script is hyphenated and cannot be imported; the two develop-only dirs
# have no package boundary, so a documented mirror is acceptable per 7.1 DD #10).
# ---------------------------------------------------------------------------


def build_basename_index(audio_root: Path) -> dict[str, list[Path]]:
    """Recursively bucket on-disk audio by basename (mirror)."""
    index: dict[str, list[Path]] = collections.defaultdict(list)
    for p in audio_root.rglob("*"):
        if p.is_file() and p.suffix.lower() in AUDIO_EXTS:
            index[p.name].append(p)
    return index


def basename_from_location(decoded: str) -> str:
    """Mirror of tony-tunes-survey._basename_from_location."""
    if not decoded:
        return ""
    return decoded.rsplit("/", 1)[-1]


def parse_collection_basenames(xml_path: Path) -> set[str]:
    """Parse <COLLECTION><TRACK Location=...> and return the basename set.

    The XML Location attrs encode a foreign hostname, so basename is the join key
    (DD #1). Only the COLLECTION is read — playlists are never consulted.
    """
    root = ET.parse(xml_path).getroot()
    collection = root.find("COLLECTION")
    if collection is None:
        raise SystemExit(f"error: no <COLLECTION> in {xml_path}")
    names: set[str] = set()
    for track in collection.findall("TRACK"):
        loc_raw = track.get("Location", "")
        if not loc_raw:
            continue
        decoded = urllib.parse.unquote(loc_raw.replace("file://localhost", ""))
        base = basename_from_location(decoded)
        if base:
            names.add(base)
    return names


def canonicalize(bpm: float) -> float:
    """Bring bpm into [CANONICAL_MIN, CANONICAL_MAX] (mirror labels._canonicalize)."""
    if bpm <= 0:
        return bpm
    out = bpm
    for _ in range(4):
        if out < CANONICAL_MIN:
            out *= 2
        elif out > CANONICAL_MAX:
            out /= 2
        else:
            break
    return out


# ---------------------------------------------------------------------------
# Independent file-metadata BPM (mutagen) — DD #2
# ---------------------------------------------------------------------------


def _parse_bpm(raw: object) -> float | None:
    """Parse a tag BPM; reject sentinel-zero, NaN, and out-of-range (labeler hygiene)."""
    if raw is None:
        return None
    try:
        val = float(str(raw).strip())
    except (TypeError, ValueError):
        return None
    if not math.isfinite(val) or not (BPM_VALID_LO <= val <= BPM_VALID_HI):
        return None
    return val


def _first(value: object) -> object:
    """Best-effort first element of a tag value (list-like) or the value itself.

    Tag containers return list-like values; a malformed tag may return a scalar.
    Guards the `vals[0]` indexing so an unexpected shape returns None, not a crash.
    """
    if value is None:
        return None
    if isinstance(value, (list, tuple)):
        return value[0] if value else None
    return value


def read_file_metadata_bpm(path: Path) -> float | None:
    """Read ID3v2 TBPM / MP4 tmpo / FLAC Vorbis BPM= ONLY (AC2). Never throws —
    any decode/format/tag-shape surprise returns None rather than aborting the run."""
    try:
        audio = MutagenFile(str(path))
        if audio is None or audio.tags is None:
            return None
        tags = audio.tags
        # ID3 (MP3, AIFF, WAV-with-ID3): TBPM text frame.
        if isinstance(tags, ID3):
            frames = tags.getall("TBPM")
            if frames and getattr(frames[0], "text", None):
                return _parse_bpm(str(_first(frames[0].text)))
            return None
        # MP4 / M4A: integer `tmpo` atom.
        if isinstance(tags, MP4Tags):
            return _parse_bpm(_first(tags.get("tmpo")))  # type: ignore[arg-type]
        # FLAC / Vorbis comment: mutagen lowercases keys, so `bpm` catches BPM=.
        return _parse_bpm(_first(tags.get("bpm")))  # type: ignore[union-attr,arg-type]
    except Exception:  # noqa: BLE001 — a malformed tag must not crash the survey
        return None


# ---------------------------------------------------------------------------
# Typed tier decision — the provenance guard (AC5/AC6/DD #5). This function
# receives ONLY the four clean signals; path/playlist/Rekordbox ids are not in
# scope and structurally cannot influence the tier.
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class TierResult:
    tier: str  # secondarySupervised | unsupervisedPool | reject
    bpm_truth: float | None
    label_confidence: float | None
    label_source: str | None
    agreement: bool
    agreement_delta_pct: float | None


def decide_tier(
    dsp_bpm: float | None,
    dsp_confidence: float | None,
    file_metadata_bpm: float | None,
    audio_hash: str,
) -> TierResult:
    """Pure tiering decision over the four provenance-clean signals (AC5).

    Finite-guarded: NaN/Inf BPM or confidence is treated as absent/zero so a
    degenerate DSP/tag value can never escape the reject floor or drive arithmetic.
    """
    _ = audio_hash  # identity only; never a tiering input
    has_meta = (
        file_metadata_bpm is not None and math.isfinite(file_metadata_bpm) and file_metadata_bpm > 0
    )
    has_dsp = dsp_bpm is not None and math.isfinite(dsp_bpm) and dsp_bpm > 0
    dsp_conf = (
        dsp_confidence if (dsp_confidence is not None and math.isfinite(dsp_confidence)) else 0.0
    )

    # reject: no parseable metadata AND the selected DSP result is weak.
    if not has_meta and (not has_dsp or dsp_conf <= REJECT_DSP_CONF_FLOOR):
        return TierResult("reject", None, None, None, False, None)

    # agreement requires both signals; ratio-family predicate (band-edge-safe).
    if has_meta and has_dsp:
        assert dsp_bpm is not None and file_metadata_bpm is not None
        deltas: list[float] = []
        for k in (0.5, 1.0, 2.0):
            cand = k * dsp_bpm
            denom = max(file_metadata_bpm, cand)
            if denom > 0:
                deltas.append(abs(file_metadata_bpm - cand) / denom)
        delta = min(deltas) if deltas else None
        if delta is not None and delta <= AGREEMENT_TOL:
            return TierResult(
                tier="secondarySupervised",
                bpm_truth=round(canonicalize(dsp_bpm), 3),
                label_confidence=round(min(dsp_conf, SECONDARY_LABEL_CONF_CAP), 4),
                label_source="dsp_metadata_agreement",
                agreement=True,
                agreement_delta_pct=round(delta, 5),
            )
        return TierResult(
            "unsupervisedPool",
            None,
            None,
            None,
            False,
            round(delta, 5) if delta is not None else None,
        )

    # exactly one signal present (and not a reject) -> label-free pool.
    return TierResult("unsupervisedPool", None, None, None, False, None)


# ---------------------------------------------------------------------------
# DSP via the Swift CLI (BPM-tag-blind) — DD #2/DD #9
# ---------------------------------------------------------------------------


def run_dsp_prepass(rows: list[dict], intensity: int, log: TextIO) -> dict[str, dict]:
    """Synthesize a SurveyTrack JSON keyed by audioHash, run tony-dsp-prepass
    --no-metadata, and return {audioHash: {bpm, confidence}}."""
    if not rows:
        return {}
    with tempfile.TemporaryDirectory() as td:
        survey_path = Path(td) / "synthetic-survey.json"
        out_path = Path(td) / "dsp-out.json"
        survey_path.write_text(json.dumps({"tracks": rows}), encoding="utf-8")
        cmd = [
            "swift",
            "run",
            "-c",
            "release",
            "--package-path",
            str(SWIFT_PACKAGE),
            "tony-dsp-prepass",
            "--no-metadata",
            "--intensity",
            str(intensity),
            "--survey-json",
            str(survey_path),
            "--output",
            str(out_path),
        ]
        print(f"  invoking: {' '.join(cmd[:6])} ... --no-metadata", file=log)
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(f"error: tony-dsp-prepass exited {exc.returncode}") from exc
        if not out_path.exists():
            raise SystemExit("error: tony-dsp-prepass produced no output file")
        data = json.loads(out_path.read_text(encoding="utf-8"))
    meta = data.get("metadata", {})
    if not meta.get("no_metadata"):
        raise SystemExit("error: DSP prepass did not run with --no-metadata (DD #2 broken)")
    by_hash: dict[str, dict] = {}
    for t in data.get("tracks", []):
        tid = t.get("track_id")
        if tid is not None:
            by_hash[tid] = {"bpm": t.get("bpm"), "confidence": t.get("confidence")}
    return by_hash


# ---------------------------------------------------------------------------
# Sentinel hashes (FR-17 / DD #4) — fail loud if a source is unreadable.
# ---------------------------------------------------------------------------


def precompute_sentinel_hashes(roots: list[Path], log: TextIO) -> dict[str, str]:
    """Locate each of the 4 sentinels under the search roots and hash it.

    Returns {audioHash: needle}. Fails loud if a needle resolves to zero NON-EMPTY
    files — a silently-empty (or 0-byte cloud-placeholder) sentinel set is
    unacceptable (AC7): a 0-byte file would hash empty bytes and never match a real
    pool file, silently defeating FR-17 exclusion.
    """
    # Walk each root ONCE (not per-needle), iterating the generator and keeping
    # only the audio files — never materializing the full tree per root/needle.
    audio_files: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        try:
            audio_files.extend(
                p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in AUDIO_EXTS
            )
        except OSError as exc:
            print(f"  warn: cannot fully walk {root} for sentinels: {exc}", file=log)

    hashes: dict[str, str] = {}
    for needle in SENTINEL_NEEDLES:
        found: list[Path] = []
        zero_byte = 0
        for p in audio_files:
            if needle not in p.name.lower():
                continue
            try:
                if p.stat().st_size == 0:
                    zero_byte += 1  # cloud placeholder -> would mis-hash empty bytes
                    continue
            except OSError:
                continue
            found.append(p)
        if not found:
            raise SystemExit(
                f"error: sentinel '{needle}' resolved to zero non-empty on-disk files under "
                f"{[str(r) for r in roots]} ({zero_byte} 0-byte placeholder(s) skipped) — "
                "cannot guarantee FR-17 exclusion (AC7); materialize the file(s) and re-run."
            )
        hashed_ok = 0
        for p in found:
            try:
                hashes[cc.file_sha256(p)] = needle
                hashed_ok += 1
            except OSError as exc:
                print(f"  warn: sentinel '{needle}' file unreadable: {p} ({exc})", file=log)
        if hashed_ok == 0:
            raise SystemExit(
                f"error: sentinel '{needle}' matched {len(found)} file(s) but NONE could be "
                "hashed (all unreadable) — cannot guarantee FR-17 exclusion (AC7)."
            )
        print(f"  sentinel '{needle}': {hashed_ok} file(s) hashed", file=log)
    return hashes


def load_expanded_sentinel_titles() -> list[tuple[str, str]]:
    """Load (track_id, lowercased title) for the 12 JAMS sentinels (AC7 cross-check).

    Report-only — used to scan the pool by title for defense-in-depth, NEVER as a
    tiering input. Returns [] if the fixture is absent.
    """
    if not SENTINELS_12_JAMS.exists():
        return []
    data = json.loads(SENTINELS_12_JAMS.read_text(encoding="utf-8"))
    out: list[tuple[str, str]] = []
    for entry in data.get("entries", []):
        fm = entry.get("file_metadata", {})
        tid = str(fm.get("identifiers", {}).get("track_id", ""))
        title = str(fm.get("title", "")).lower().strip()
        if title:
            out.append((tid, title))
    return out


def build_sentinel_review(
    analyzable_unique: list[Path],
    hash_for: dict[str, str],
    sentinel_hashes: dict[str, str],
    audio_root: Path,
) -> dict:
    """Report-only sentinel review (AC7). (a) Title near-copies of the 4 needles,
    flagging any NOT already excluded by audioHash (a re-encode the byte hash
    misses); (b) a cross-check of the 12-sentinel titles against the pool. NEITHER
    is a tiering input — both are manual-review aids that never touch decide_tier."""
    near_copies: list[dict] = []
    for p in analyzable_unique:
        name = p.name.lower()
        for needle in SENTINEL_NEEDLES:
            if needle in name:
                h = hash_for[str(p)]
                near_copies.append(
                    {
                        "relPath": str(p.relative_to(audio_root)),
                        "needle": needle,
                        "audioHash": h,
                        "excludedByHash": h in sentinel_hashes,
                    }
                )
                break
    # Only cross-check titles specific enough to be meaningful — a generic short
    # title ("Dream", "BOO") substring-matches half the corpus and drowns the aid.
    # Those 8 expanded sentinels are Rekordbox-collection IDs (structurally absent
    # from the non-Rekordbox pool) and are un-disambiguable by title alone, so
    # dropping their title check loses no real signal. The 4 distinctive originals
    # are caught by audioHash regardless.
    twelve = load_expanded_sentinel_titles()
    specific = [(tid, title) for tid, title in twelve if len(title) >= 10]
    twelve_matches: list[dict] = []
    for p in analyzable_unique:
        stem = p.name.lower().rsplit(".", 1)[0]
        for tid, title in specific:
            if title in stem:
                twelve_matches.append(
                    {"relPath": str(p.relative_to(audio_root)), "sentinelTrackId": tid}
                )
                break
    return {
        "fourNeedleNearCopies": near_copies,
        "twelveSetTitleMatches": twelve_matches,
        "twelveSetTitlesLoaded": len(twelve),
        "twelveSetTitlesCrossChecked": len(specific),
    }


# ---------------------------------------------------------------------------
# Reporting helpers
# ---------------------------------------------------------------------------


def _bpm_bin(bpm: float | None) -> str:
    if bpm is None or bpm <= 0:
        return "none"
    lo = int(bpm // 5) * 5
    return f"{lo}-{lo + 4}"


def _genre_proxy(rel_path: str) -> str:
    """Coarse top-level genre folder. Report-only (AC8) — NEVER a tiering input."""
    head = rel_path.split("/", 1)[0] if "/" in rel_path else "(root)"
    return head


def write_provenance_audit(out_path: Path, forbidden: list[str]) -> None:
    lines = [
        "# Non-Rekordbox provenance audit (Story 7.2, FR-13/FR-15)",
        "",
        "The tier decision is made by the pure typed function "
        "`decide_tier(dsp_bpm, dsp_confidence, file_metadata_bpm, audio_hash)` — the "
        "four arguments are the ONLY signals in scope. The following are forbidden as "
        "tiering evidence and do not appear in the tiering code path:",
        "",
    ]
    lines += [f"- `{col}`" for col in forbidden]
    lines += [
        "",
        "## Membership vs tiering evidence (DD #1)",
        "",
        "The Rekordbox `<COLLECTION>` is consulted ONLY to PARTITION the universe "
        "(in-collection vs non-Rekordbox) — set membership, not a per-file tiering "
        "signal. FR-13/FR-15 forbid Rekordbox-derived signals as tiering evidence "
        "(the tier decision), never as the boundary that scopes the expansion set.",
        "",
        "## Grep verification",
        "",
        "Run against the tiering module body AND every `decide_tier` call-site "
        "argument expression — expected zero hits:",
        "",
        "```",
        "rg -i 'playlist|path|rekordbox|artist|id3' scripts/non-rekordbox-survey.py \\",
        "    | rg -i 'decide_tier|def decide_tier|tier ='",
        "```",
        "",
        "The four `decide_tier` arguments at the single call site are sourced only "
        "from `{dspBPM, dspConfidence, fileMetadataBPM, audioHash}` (AC6).",
        "",
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_source_distribution(
    out_path: Path, rows: list[dict], skipped: dict[str, int], sentinel_review: dict
) -> None:
    tier_counts = collections.Counter(r["tier"] for r in rows)
    fmt_counts = collections.Counter(Path(r["path"]).suffix.lower().lstrip(".") for r in rows)
    genre_counts = collections.Counter(_genre_proxy(r["path"]) for r in rows)
    tempo_counts: collections.Counter[str] = collections.Counter(
        _bpm_bin(r.get("dspBPM")) for r in rows
    )
    secondary = tier_counts.get("secondarySupervised", 0)

    # Threshold sensitivity (DD #8) — honest analysis, NOT license to loosen.
    # A row "would agree at 0.04" only if it is NOT a reject (reject rows can never
    # be promoted) AND its delta clears 0.04. Force-rejected sentinels carry a
    # None delta (cleared at force-reject) so they cannot inflate this count.
    at_04 = sum(
        1
        for r in rows
        if r["tier"] != "reject"
        and r.get("agreementDeltaPct") is not None
        and r["agreementDeltaPct"] <= 0.04
    )
    # 0.40 reject-floor sweep: how many of the current rejects are there BECAUSE of
    # the DSP-confidence floor (no metadata AND a DSP estimate present but weak),
    # vs rejects with no usable signal at all.
    floor_rejects = sum(
        1
        for r in rows
        if r["tier"] == "reject"
        and r.get("fileMetadataBPM") is None
        and r.get("dspBPM") is not None
        and (r.get("dspConfidence") or 0.0) <= REJECT_DSP_CONF_FLOOR
    )

    lines = [
        "# Non-Rekordbox source distribution (Story 7.2, FR-13 / KDD-B4)",
        "",
        f"Analyzable files surveyed: **{len(rows)}**. "
        f"Skipped (reported, not analyzed): "
        f"cloud_only **{skipped.get('cloud_only', 0)}**, "
        f"ambiguous_membership **{skipped.get('ambiguous_membership', 0)}**, "
        f"duplicate_audio_hash **{skipped.get('duplicate_audio_hash', 0)}**, "
        f"unreadable **{skipped.get('unreadable', 0)}**.",
        "",
        "## (d) Tier counts",
        "",
        "| tier | count |",
        "|---|---|",
        f"| secondarySupervised | {tier_counts.get('secondarySupervised', 0)} |",
        f"| unsupervisedPool | {tier_counts.get('unsupervisedPool', 0)} |",
        f"| reject | {tier_counts.get('reject', 0)} |",
        "",
        "## (c) Source / format distribution",
        "",
        "| format | count |",
        "|---|---|",
    ]
    lines += [f"| {k or '(none)'} | {v} |" for k, v in sorted(fmt_counts.items())]
    lines += [
        "",
        "## (b) Tempo distribution (metadata-blind DSP BPM, 5-BPM bins)",
        "",
        "| bin | count |",
        "|---|---|",
    ]

    def _bin_key(item: tuple[str, int]) -> int:
        key = item[0]
        return -1 if key == "none" else int(key.split("-", 1)[0])

    lines += [f"| {k} | {v} |" for k, v in sorted(tempo_counts.items(), key=_bin_key)]
    lines += [
        "",
        "## (a) Genre proxy (file-path hint -> coarse bucket; REPORT-ONLY, never a tiering input)",
        "",
        "Purpose: let the reviewer judge whether the expansion BROADENS the domain or "
        "REINFORCES the DnB-heavy labeled corpus — a composition-balance judgment, not a "
        "per-file decision.",
        "",
        "| bucket | count |",
        "|---|---|",
    ]
    lines += [f"| {k} | {v} |" for k, v in sorted(genre_counts.items())]
    lines += [
        "",
        "## Yield, threshold sensitivity, and ablation risk (DD #8)",
        "",
        f"- secondarySupervised yield at the 0.03 tolerance: **{secondary}**.",
        "",
        "| sensitivity datapoint | value |",
        "|---|---|",
        f"| would-agree at 0.03 (= secondarySupervised) | {secondary} |",
        f"| would-agree at 0.04 (non-reject rows, delta <= 0.04) | {at_04} |",
        f"| rejects DUE TO the 0.40 DSP-confidence floor (no metadata + weak DSP) | {floor_rejects} |",
        "",
        "Reported as analysis ONLY — the 0.03 tolerance and 0.40 reject floor are NOT "
        "loosened to manufacture a larger supervised tier (DD #8).",
    ]
    if secondary < 50:
        lines.append(
            f"- **RISK to the KDD-B2 ablation:** the secondarySupervised tier is small "
            f"({secondary}). The supervised-augmented arm of Story 7.3 may be underpowered, "
            "making the comparison foregone rather than fair. This is a JOB outcome, named "
            "here for review — not a reason to relax thresholds."
        )
    # AC7 report-only sentinel review (near-copy aid + 12-set cross-check). These
    # are manual-review aids — NEITHER is a tiering input.
    near = sentinel_review.get("fourNeedleNearCopies", [])
    near_unflagged = [nc for nc in near if not nc.get("excludedByHash")]
    twelve = sentinel_review.get("twelveSetTitleMatches", [])
    lines += [
        "",
        "## Sentinel review (FR-17 / AC7 — REPORT-ONLY, never a tiering input)",
        "",
        f"- 4-needle title near-copies in the pool: **{len(near)}** "
        f"(already audioHash-excluded: {len(near) - len(near_unflagged)}; "
        f"**NOT hash-excluded (manual review — possible re-encode): {len(near_unflagged)}**).",
        f"- 12-sentinel-set title cross-check matches "
        f"({sentinel_review.get('twelveSetTitlesCrossChecked', 0)} of "
        f"{sentinel_review.get('twelveSetTitlesLoaded', 0)} titles specific enough to check): "
        f"**{len(twelve)}** (the 8 expanded sentinels are Rekordbox-collection IDs, "
        "structurally outside the pool; generic short titles are skipped to avoid noise).",
    ]
    if near_unflagged:
        lines.append("")
        lines.append("Title near-copies NOT excluded by audioHash (review by ear):")
        lines += [f"  - `{nc['relPath']}` (needle: {nc['needle']})" for nc in near_unflagged[:50]]
    lines += [
        "",
        "## Octave-correctness caveat (DD #6)",
        "",
        "A `secondarySupervised` label proves DSP<->tag *consistency*, NOT octave "
        "*correctness*: when DSP picks the wrong fundamental (Tony's half-tempo pattern, "
        "FR-12) and the tag agrees, `bpm_truth` enshrines the DSP octave error. Story 7.3's "
        "octave-aware loss (FR-16) is the trainer-side backstop. Agreement != correctness.",
        "",
    ]
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def link_into_diagnostics(report_rel: str) -> None:
    """Append a reference link to the source-distribution report into
    corpus-diagnostics-v1.md (AC8), idempotently."""
    if not DIAGNOSTICS_MD.exists():
        print(f"  warn: {DIAGNOSTICS_MD} not found — skipping reference link", file=sys.stderr)
        return
    text = DIAGNOSTICS_MD.read_text(encoding="utf-8")
    marker = "## Non-Rekordbox expansion (Story 7.2)"
    if marker in text:
        return
    block = (
        f"\n{marker}\n\n"
        f"The non-Rekordbox semi-supervised expansion pool (Story 7.2) is surveyed and "
        f"tiered separately; see [`{report_rel}`]({report_rel}) for the source-distribution "
        f"report (genre/tempo/format/tier counts + yield + octave-risk caveat).\n"
    )
    DIAGNOSTICS_MD.write_text(text.rstrip() + "\n" + block, encoding="utf-8")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Non-Rekordbox expansion survey (Story 7.2)")
    parser.add_argument(
        "--xml",
        default=os.environ.get("TONY_XML", "/Users/rterhaar/Dropbox/tony-tunes/05092026.xml"),
    )
    parser.add_argument(
        "--audio-root",
        default=os.environ.get("TONY_AUDIO_ROOT", "/Users/rterhaar/Dropbox/tony-tunes"),
    )
    parser.add_argument(
        "--oa300-root",
        default=os.environ.get("OA300_CORPUS_PATH", "/Users/rterhaar/Dropbox/OA300_OnsetAudio300"),
    )
    parser.add_argument("--out-dir", default=str(ML_TRAINING))
    parser.add_argument("--intensity", type=int, default=7)
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="cap the analyzable set fed to DSP (smoke testing; full run omits it)",
    )
    args = parser.parse_args(argv)
    log = sys.stderr

    xml_path = Path(args.xml)
    audio_root = Path(args.audio_root)
    out_dir = Path(args.out_dir)
    if not xml_path.exists():
        raise SystemExit(f"error: XML not found: {xml_path}")
    if not audio_root.exists():
        raise SystemExit(f"error: audio root not found: {audio_root}")

    # --- AC1: derive the set by basename subtraction (with ambiguous-basename
    # quarantine) + 3-way partition. Basename is the only join (foreign-host XML). ---
    print("[1/6] deriving non-Rekordbox set ...", file=log)
    index = build_basename_index(audio_root)
    collection_basenames = parse_collection_basenames(xml_path)
    print(
        f"  on-disk audio: {sum(len(v) for v in index.values())} files / "
        f"{len(index)} basenames; collection basenames: {len(collection_basenames)}",
        file=log,
    )

    analyzable: list[Path] = []
    skipped_cloud: list[Path] = []
    skipped_ambiguous: list[Path] = []
    total_candidates = 0
    for base, paths in index.items():
        in_collection = base in collection_basenames
        if len(paths) > 1:
            # Ambiguous membership: cannot cleanly attribute duplicates to
            # in-collection vs expansion -> quarantine the whole group (DD #1).
            skipped_ambiguous.extend(paths)
            total_candidates += len(paths)
            continue
        p = paths[0]
        total_candidates += 1
        if in_collection:
            continue  # belongs to the Rekordbox collection -> not expansion
        try:
            size = p.stat().st_size
        except OSError:
            size = -1
        if size == 0:
            skipped_cloud.append(p)  # 0-byte Dropbox/iCloud placeholder
        else:
            analyzable.append(p)

    # count-in == count-out: every UNIQUE-basename candidate is accounted for;
    # ambiguous groups counted by member. (In-collection singletons are removed.)
    in_collection_singletons = sum(
        1 for b, ps in index.items() if len(ps) == 1 and b in collection_basenames
    )
    accounted = (
        len(analyzable) + len(skipped_cloud) + len(skipped_ambiguous) + in_collection_singletons
    )
    if accounted != total_candidates:
        raise SystemExit(
            f"error: count-in != count-out ({accounted} != {total_candidates}) — "
            "partition is lossy (DD #9)."
        )
    print(
        f"  analyzable={len(analyzable)} cloud_only={len(skipped_cloud)} "
        f"ambiguous_membership={len(skipped_ambiguous)} "
        f"in_collection_singletons={in_collection_singletons}",
        file=log,
    )
    print(
        f"  ~4,700 reconciliation: analyzable={len(analyzable)} "
        "(note: 6407-1721=4686 is an UPPER bound on the subtrahend; resolution is "
        "lossy so the true expansion set is typically larger).",
        file=log,
    )

    analyzable.sort()
    if args.limit is not None:
        analyzable = analyzable[: args.limit]
        print(f"  --limit {args.limit}: DSP over {len(analyzable)} files", file=log)

    # --- AC3/AC4: audioHash first, dedup the join key, then synthesize rows. ---
    # audioHash is the read-back + manifest join key, so it MUST be unique: two
    # files with identical bytes under different basenames (common in a DJ
    # library) hash equal and would emit duplicate manifest rows sharing one
    # "pinned join key" — first-path-wins dedup keeps the key 1:1. file_sha256 is
    # wrapped: a file that vanished/became unreadable since indexing (Dropbox
    # eviction / TOCTOU) is reported and skipped, not crashed on.
    print("[2/6] hashing + dedup + synthesizing survey rows ...", file=log)
    hash_for: dict[str, str] = {}  # abs path -> audioHash (unique-only)
    seen_hash: dict[str, Path] = {}  # audioHash -> first path
    analyzable_unique: list[Path] = []
    duplicate_hash_paths: list[tuple[Path, Path]] = []  # (dropped dup, kept first)
    unreadable: list[Path] = []
    syn_rows: list[dict] = []
    for p in analyzable:
        try:
            h = cc.file_sha256(p)
        except OSError as exc:
            unreadable.append(p)
            print(f"  warn: unreadable since indexing, skipping: {p} ({exc})", file=log)
            continue
        if h in seen_hash:
            duplicate_hash_paths.append((p, seen_hash[h]))
            continue
        seen_hash[h] = p
        hash_for[str(p)] = h
        analyzable_unique.append(p)
        syn_rows.append(
            {
                "track_id": h,  # the read-back + manifest JOIN key (DD #9; unique)
                "name": "",
                "artist": "",
                "local_path": str(p),
                "resolve_status": "ok",  # only analyzable files get "ok"
            }
        )
    hashed_accounted = len(analyzable_unique) + len(duplicate_hash_paths) + len(unreadable)
    if hashed_accounted != len(analyzable):
        raise SystemExit(
            f"error: hash-phase count-in != count-out ({hashed_accounted} != {len(analyzable)})"
        )
    if duplicate_hash_paths or unreadable:
        print(
            f"  dedup: {len(duplicate_hash_paths)} identical-byte duplicate(s) dropped; "
            f"{len(unreadable)} unreadable skipped; {len(analyzable_unique)} unique",
            file=log,
        )

    # --- AC3/DD #2: BPM-tag-blind DSP via the Swift CLI. ---
    print("[3/6] running BPM-tag-blind DSP prepass ...", file=log)
    dsp_by_hash = run_dsp_prepass(syn_rows, args.intensity, log)
    # Read-back reconciliation (mirror the partition's no-drop discipline): warn
    # if any submitted track is absent from the DSP output join.
    missing_dsp = [r["track_id"] for r in syn_rows if r["track_id"] not in dsp_by_hash]
    if missing_dsp:
        # tony-dsp-prepass emits one result row per submitted "ok" track (errored
        # tracks included), so a read-back gap is an adapter-contract violation,
        # not normal data quality — fail loud (DD #9 count-in == count-out).
        raise SystemExit(
            f"error: {len(missing_dsp)} submitted track(s) absent from the DSP output — "
            "the tony-dsp-prepass adapter contract (one result row per submitted track) "
            "was violated (DD #9)."
        )

    # --- AC3/DD #2: INDEPENDENT file-metadata BPM via mutagen. ---
    print("[4/6] reading independent file-metadata BPM (mutagen) ...", file=log)
    # --- AC7/DD #4: sentinel hashes (fail loud). ---
    sentinel_hashes = precompute_sentinel_hashes([Path(args.oa300_root), audio_root], log)

    # --- AC5/AC6: tier every file via the typed guard; sentinel override. ---
    print("[5/6] tiering ...", file=log)
    rows: list[dict] = []
    for p in analyzable_unique:
        h = hash_for[str(p)]
        rel = str(p.relative_to(audio_root))
        dsp = dsp_by_hash.get(h, {})
        dsp_bpm = dsp.get("bpm")
        dsp_conf = dsp.get("confidence")
        meta_bpm = read_file_metadata_bpm(p)
        res = decide_tier(dsp_bpm, dsp_conf, meta_bpm, h)
        if h in sentinel_hashes:
            print(
                f"  WARNING: sentinel '{sentinel_hashes[h]}' present in pool ({rel}) "
                "-> force reject (FR-17)",
                file=log,
            )
            # Clear the agreement delta so a force-rejected sentinel cannot leak a
            # stale delta into the AC8 threshold-sensitivity recount (it can never
            # be promoted, so it must not count toward "would agree at 0.04").
            res = TierResult("reject", None, None, None, False, None)
        row = {
            "path": rel,
            "audioHash": h,
            "dspBPM": dsp_bpm,
            "dspConfidence": dsp_conf,
            "fileMetadataBPM": meta_bpm,
            "agreementAfterOctaveNormalization": res.agreement,
            "agreementDeltaPct": res.agreement_delta_pct,
            "tier": res.tier,
        }
        if res.tier == "secondarySupervised":
            row["bpm_truth"] = res.bpm_truth
            row["labelSource"] = res.label_source
            row["labelConfidence"] = res.label_confidence
        rows.append(row)

    # --- AC7: report-only sentinel review (near-copy aid + 12-set cross-check). ---
    sentinel_review = build_sentinel_review(
        analyzable_unique, hash_for, sentinel_hashes, audio_root
    )
    unflagged = [nc for nc in sentinel_review["fourNeedleNearCopies"] if not nc["excludedByHash"]]
    if unflagged or sentinel_review["twelveSetTitleMatches"]:
        print(
            f"  sentinel review: {len(unflagged)} title near-copy(ies) NOT hash-excluded; "
            f"{len(sentinel_review['twelveSetTitleMatches'])} 12-set title match(es) "
            "(report-only, manual review)",
            file=log,
        )

    # --- AC2/AC8/AC9: emit artifacts. ---
    print("[6/6] writing artifacts ...", file=log)

    def _rel(p: Path) -> str:
        return str(p.relative_to(audio_root))

    survey = {
        "schema_version": 1,
        "generated_with": "scripts/non-rekordbox-survey.py",
        "audio_root": str(audio_root),
        "xml_source": str(xml_path),
        "dsp_metadata_blind": True,
        "audioHash_derivation": "corpus_common.file_sha256 (raw audio bytes)",
        "analyzable_count": len(rows),
        "tracks": rows,
        "sentinelReview": sentinel_review,
        "skipped": {
            "cloud_only": [_rel(p) for p in skipped_cloud],
            "ambiguous_membership": [_rel(p) for p in skipped_ambiguous],
            "duplicate_audio_hash": [
                {"dropped": _rel(dup), "keptFirst": _rel(first)}
                for dup, first in duplicate_hash_paths
            ],
            "unreadable": [_rel(p) for p in unreadable],
        },
    }
    (out_dir / "non-rekordbox-survey.json").write_text(
        json.dumps(survey, indent=2, sort_keys=True, allow_nan=False), encoding="utf-8"
    )

    # AC9: loadable, FR-15-clean manifest for Story 7.3 (audioHash + relPath +
    # bpm_truth + labelConfidence; NO playlist/genre/rekordbox-id/dsp-candidate).
    manifest = {
        "schema_version": 1,
        "audioHash_derivation": "corpus_common.file_sha256 (raw audio bytes) — pinned join key",
        "note": (
            "Story 7.3 supervised-augmented loader: use relPath ONLY to fetch bytes "
            "(never as a feature); read bpm_truth as the label."
        ),
        "secondarySupervised": [
            {
                "audioHash": r["audioHash"],
                "relPath": r["path"],
                "bpm_truth": r["bpm_truth"],
                "labelConfidence": r["labelConfidence"],
            }
            for r in rows
            if r["tier"] == "secondarySupervised"
        ],
    }
    (out_dir / "non-rekordbox-secondary-supervised-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True, allow_nan=False), encoding="utf-8"
    )

    write_provenance_audit(
        out_dir / "non-rekordbox-provenance-audit.md",
        forbidden=[
            "path / relPath components",
            "parent directory names",
            "Rekordbox XML track IDs",
            "playlist membership",
            "DSP candidate scores",
            "artist embedding",
            "ID3 BPM as a model feature",
        ],
    )
    skipped_counts = {
        "cloud_only": len(skipped_cloud),
        "ambiguous_membership": len(skipped_ambiguous),
        "duplicate_audio_hash": len(duplicate_hash_paths),
        "unreadable": len(unreadable),
    }
    write_source_distribution(
        out_dir / "non-rekordbox-source-distribution.md",
        rows,
        skipped_counts,
        sentinel_review,
    )
    link_into_diagnostics("non-rekordbox-source-distribution.md")

    sec = sum(1 for r in rows if r["tier"] == "secondarySupervised")
    uns = sum(1 for r in rows if r["tier"] == "unsupervisedPool")
    rej = sum(1 for r in rows if r["tier"] == "reject")
    print(
        f"done. tiers: secondarySupervised={sec} unsupervisedPool={uns} reject={rej}; "
        f"manifest={sec} rows. artifacts in {out_dir}",
        file=log,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
