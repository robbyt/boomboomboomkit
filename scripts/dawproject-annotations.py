#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Extract supplementary downbeat and verified-span annotations from a .dawproject.

Usage:
  uv run scripts/dawproject-annotations.py --dawproject <file.dawproject> \\
      --match <oa300-ground-truth.json> --out <daw-oracle-annotations.json> [--check]

Annotation convention (Story 15.8). In the clip audio editor the operator snaps a
beat marker to a bar line on a verified downbeat at bar 2 or later, and a second
one at least 8 bars further on. Bitwig saves each beat marker as a `Warp` point
whose `time` is in clip beats and whose `contentTime` is in original-audio
seconds. A warp within 0.02 beats of a bar line, at bar 2 or later under the same
tolerance, IS the downbeat declaration by convention; the file carries no
separate downbeat flag. The track Comment field may carry
`level=<quarter|half|double>; unc=<low|medium|high>; free text`.

Each record covers only the span between the first and last bar-line warp. No
beat outside that span is written or implied. Clips without the convention are
omitted, one stderr line each (`skip <audio basename>: <reason>`), and the exit
code stays 0. Exit 2 means the inputs or the output path are unusable. With
`--check` nothing is written: exit 0 when `--out` already holds the regenerated
bytes, exit 1 otherwise.

The output stays operator-local next to `daw-oracle.json`; it is never committed.
"""

from __future__ import annotations

import argparse
import contextlib
import importlib.util
import json
import math
import os
import sys
import tempfile
import types
import xml.etree.ElementTree as ET
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

# Loading dawproject-bpm.py by path would otherwise drop a .pyc into scripts/__pycache__.
sys.dont_write_bytecode = True

ANNOTATION_VERSION = "15.8.v1"
SOURCE = "bitwig-warp-bar-line-pair"
DATA_SOURCE = "DAW manual placement, bar-line warp markers"

BEATS_PER_BAR = 4
BAR_TOLERANCE_BEATS = 0.02
MIN_SPAN_BARS = 8
END_OF_FILE_MARGIN_SEC = 1e-6

METRICAL_LEVELS = ("quarter", "half", "double")
UNCERTAINTY_LEVELS = ("low", "medium", "high")
DEFAULT_LEVEL = "unspecified"
DEFAULT_UNCERTAINTY_LEVEL = "medium"
NOTE_NO_COMMENT = "derived from bar-line warp pair; no operator comment"
NOTE_NO_FREE_TEXT = "derived from bar-line warp pair"

SKIP_NO_ANCHOR = "no-declared-downbeat-anchor"
SKIP_SHORT_SPAN = "verified-span-shorter-than-8-bars"
SKIP_UNVERIFIED_WARP = "unverified-warp-inside-span"
SKIP_NOT_MONOTONIC = "warps-not-monotonic"
SKIP_UNMATCHED = "unmatched-ground-truth"
SKIP_DUPLICATE = "duplicate-ground-truth-match"
SKIP_INVALID_COMMENT = "invalid-comment-token"
SKIP_TIME_SIGNATURE = "time-signature-not-4-4"


class InputError(Exception):
    """An unusable input or output path. main() reports it on one line and exits 2."""


def _load_bpm_module() -> types.ModuleType:
    """Load the sibling `dawproject-bpm.py` for its ground-truth matching helpers."""
    path = Path(__file__).resolve().with_name("dawproject-bpm.py")
    spec = importlib.util.spec_from_file_location("dawproject_bpm", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load a module spec from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


bpm_module = _load_bpm_module()


@dataclass(frozen=True)
class WarpPoint:
    time: float  # clip beats
    content_time: float  # original-audio seconds


@dataclass(frozen=True)
class ClipInput:
    audio_path: str  # `File@path` as written, e.g. "audio/x.wav"
    audio_duration_raw: str
    warps_raw: tuple[tuple[str, str], ...]  # (time, contentTime) strings in document order
    beat_timeline: bool  # Warps timeUnit is beats and contentTimeUnit is seconds
    comment: str

    @property
    def basename(self) -> str:
        return os.path.basename(self.audio_path)


@dataclass(frozen=True)
class Comment:
    level: str
    uncertainty_level: str
    note: str


# --- reading ------------------------------------------------------------------


def _required(el: ET.Element, attr: str) -> str:
    value = el.get(attr)
    if value is None:
        raise InputError(f"project.xml: <{el.tag}> is missing required attribute '{attr}'")
    return value


def read_project(dawproject_path: str) -> ET.Element:
    """Open the .dawproject zip and parse its project.xml."""
    path = Path(dawproject_path)
    if not path.is_file():
        raise InputError(f"--dawproject {dawproject_path}: no such file")
    try:
        with zipfile.ZipFile(path, "r") as zf:
            try:
                data = zf.read("project.xml")
            except KeyError:
                raise InputError(
                    f"--dawproject {dawproject_path}: zip has no project.xml"
                ) from None
    except zipfile.BadZipFile:
        raise InputError(f"--dawproject {dawproject_path}: not a zip archive") from None
    except OSError as exc:
        raise InputError(f"--dawproject {dawproject_path}: {exc.strerror or exc}") from None
    try:
        return ET.fromstring(data)
    except ET.ParseError as exc:
        raise InputError(
            f"--dawproject {dawproject_path}: project.xml parse error: {exc}"
        ) from None


def read_application(root: ET.Element) -> dict:
    app = root.find("Application")
    if app is None:
        raise InputError("project.xml: missing required element <Application>")
    return {"name": _required(app, "name"), "version": _required(app, "version")}


def is_four_four(root: ET.Element) -> bool:
    """True iff the project declares a fixed 4/4 meter with no meter automation."""
    if root.find(".//TimeSignatureAutomation") is not None:
        return False
    sig = root.find("Transport/TimeSignature")
    if sig is None:
        return False
    numerator = _required(sig, "numerator")
    denominator = _required(sig, "denominator")
    try:
        return float(numerator) == 4 and float(denominator) == 4
    except ValueError:
        return False


def collect_clips(root: ET.Element) -> list[ClipInput]:
    """Every arrangement clip with audio, in document order.

    Mirrors the traversal in `dawproject-bpm.py` (`Arrangement//Lanes[@track]`, then
    every `Warps` below it) so both scripts see the same clips.
    """
    comments = {t.get("id"): t.get("comment", "") for t in root.iter("Track") if t.get("id")}
    clips: list[ClipInput] = []
    for lanes in root.findall(".//Arrangement//Lanes[@track]"):
        comment = comments.get(lanes.get("track"), "") or ""
        for warps in lanes.iter("Warps"):
            audio = warps.find("Audio")
            if audio is None:
                continue
            file_el = audio.find("File")
            if file_el is None:
                raise InputError("project.xml: <Audio> is missing required element <File>")
            # A unit attribute may be inherited from an enclosing timeline, so only an
            # explicit non-beat or non-second unit rules the clip out.
            beat_timeline = warps.get("timeUnit", "beats") == "beats" and (
                warps.get("contentTimeUnit", "seconds") == "seconds"
            )
            clips.append(
                ClipInput(
                    audio_path=_required(file_el, "path"),
                    audio_duration_raw=_required(audio, "duration"),
                    warps_raw=tuple(
                        (_required(w, "time"), _required(w, "contentTime"))
                        for w in warps.findall("Warp")
                    ),
                    beat_timeline=beat_timeline,
                    comment=comment,
                )
            )
    return clips


def load_ground_truth(match_path: str) -> list[dict]:
    """Flat OA300 rows via `dawproject-bpm.py`, validated for matching."""
    try:
        rows = bpm_module._load_oa300_rows(match_path)
    except OSError as exc:
        raise InputError(f"--match {match_path}: {exc.strerror or exc}") from None
    except (ValueError, KeyError, TypeError, AttributeError) as exc:
        raise InputError(f"--match {match_path}: invalid ground truth: {exc}") from None
    for row in rows:
        if not isinstance(row.get("filename"), str) or not row["filename"]:
            raise InputError(f"--match {match_path}: an entry has no identifiers.basename")
    return rows


# --- rules --------------------------------------------------------------------


def clean_warps(clip: ClipInput) -> tuple[list[WarpPoint], float] | None:
    """Sorted, finite, strictly increasing warps and a positive duration, or None."""
    try:
        duration = float(clip.audio_duration_raw)
        points = [WarpPoint(float(t), float(c)) for t, c in clip.warps_raw]
    except ValueError:
        return None
    if not math.isfinite(duration) or duration <= 0:
        return None
    if not all(math.isfinite(p.time) and math.isfinite(p.content_time) for p in points):
        return None
    points.sort(key=lambda p: p.time)
    for prev, cur in zip(points, points[1:]):
        if cur.time <= prev.time or cur.content_time <= prev.content_time:
            return None
    return points, duration


def bar_index(warp: WarpPoint) -> int:
    """0-based clip-local bar index of a bar-line warp."""
    return round(warp.time / BEATS_PER_BAR)


def is_anchor(warp: WarpPoint, duration: float) -> bool:
    """A bar-line warp at bar 2 or later under the same tolerance, strictly inside the file."""
    bars = warp.time / BEATS_PER_BAR
    on_bar_line = abs(bars - round(bars)) * BEATS_PER_BAR <= BAR_TOLERANCE_BEATS
    inside = 0 < warp.content_time < duration - END_OF_FILE_MARGIN_SEC
    return on_bar_line and bar_index(warp) >= 1 and inside


def parse_comment(raw: str) -> Comment | None:
    """Track comment tokens; None when a `level` or `unc` value is not recognized."""
    if not raw.strip():
        return Comment(DEFAULT_LEVEL, DEFAULT_UNCERTAINTY_LEVEL, NOTE_NO_COMMENT)
    level: str | None = None
    unc: str | None = None
    note_parts: list[str] = []
    for token in raw.split(";"):
        token = token.strip()
        if not token:
            continue
        key, sep, value = token.partition("=")
        key = key.strip().lower()
        value = value.strip().lower()
        if sep and key == "level":
            if value not in METRICAL_LEVELS or level is not None:
                return None
            level = value
        elif sep and key == "unc":
            if value not in UNCERTAINTY_LEVELS or unc is not None:
                return None
            unc = value
        else:
            note_parts.append(token)
    return Comment(
        level or DEFAULT_LEVEL,
        unc or DEFAULT_UNCERTAINTY_LEVEL,
        "; ".join(note_parts) if note_parts else NOTE_NO_FREE_TEXT,
    )


@dataclass(frozen=True)
class SpanAnnotation:
    duration: float
    anchors: list[WarpPoint]  # A1 .. A2 inclusive, all eligible
    verified_bpm: float
    comment: Comment


def annotate_clip(clip: ClipInput) -> SpanAnnotation | str:
    """The verified span of one clip, or the skip reason."""
    cleaned = clean_warps(clip)
    if cleaned is None:
        return SKIP_NOT_MONOTONIC
    points, duration = cleaned
    eligible = [i for i, p in enumerate(points) if clip.beat_timeline and is_anchor(p, duration)]
    if len(eligible) < 2:
        return SKIP_NO_ANCHOR
    first, last = eligible[0], eligible[-1]
    a1, a2 = points[first], points[last]
    if bar_index(a2) - bar_index(a1) < MIN_SPAN_BARS:
        return SKIP_SHORT_SPAN
    if any(i not in eligible for i in range(first + 1, last)):
        return SKIP_UNVERIFIED_WARP
    comment = parse_comment(clip.comment)
    if comment is None:
        return SKIP_INVALID_COMMENT
    bpm = (a2.time - a1.time) / (a2.content_time - a1.content_time) * 60.0
    return SpanAnnotation(duration, points[first : last + 1], bpm, comment)


# --- output -------------------------------------------------------------------


def _beat_position(anchor: WarpPoint) -> dict:
    return {
        "time": anchor.content_time,
        "duration": 0.0,
        "value": {
            "position": 1,
            "measure": bar_index(anchor) + 1,
            "num_beats": BEATS_PER_BAR,
            "beat_units": 4,
        },
        "confidence": 1.0,
    }


def build_entry(gt_row: dict, span: SpanAnnotation, application: dict, curator: dict) -> dict:
    a1, a2 = span.anchors[0], span.anchors[-1]
    start, end = a1.content_time, a2.content_time
    checks = [
        {
            "time_sec": a.content_time,
            "bar_position": bar_index(a) + 1,
            "residual_ms": (
                a.content_time - (start + (a.time - a1.time) * 60.0 / span.verified_bpm)
            )
            * 1000.0,
        }
        for a in span.anchors[1:-1]
    ]
    # identifiers exactly as `_daw_oracle_to_jams` builds them, so a consumer joins on basename.
    basename = gt_row["filename"]
    subdir = gt_row.get("subdir")
    local_path = f"{subdir}/{basename}" if subdir else basename
    metadata = {"curator": curator, "data_source": DATA_SOURCE}
    return {
        "file_metadata": {
            "duration": span.duration,
            "jams_version": "0.4.0",
            "identifiers": {"basename": basename, "local_path": local_path, "track_id": basename},
        },
        "annotations": [
            {
                "namespace": "tempo",
                "data": [
                    {
                        "time": start,
                        "duration": end - start,
                        "value": span.verified_bpm,
                        "confidence": 1.0,
                    }
                ],
                "annotation_metadata": metadata,
            },
            {
                "namespace": "beat_position",
                "data": [_beat_position(a) for a in span.anchors],
                "annotation_metadata": metadata,
            },
        ],
        "sandbox": {
            "reference_downbeat_time_sec": start,
            "verified_bpm": span.verified_bpm,
            "declared_metrical_level": span.comment.level,
            "bar_position": bar_index(a1) + 1,
            "verified_span_start_sec": start,
            "verified_span_end_sec": end,
            "distant_alignment_checks": checks,
            "uncertainty": {"level": span.comment.uncertainty_level, "note": span.comment.note},
            "annotation_version": ANNOTATION_VERSION,
            "source": SOURCE,
            "dawproject_application": application,
        },
    }


def generate(dawproject_path: str, match_path: str) -> tuple[dict, list[str]]:
    """The annotations document and the stderr skip lines, in clip document order."""
    root = read_project(dawproject_path)
    application = read_application(root)
    clips = collect_clips(root)
    gt_rows = load_ground_truth(match_path)
    four_four = is_four_four(root)
    curator = bpm_module._curator()

    entries: list[dict] = []
    skips: list[str] = []
    reserved: set[str] = set()
    for clip in clips:
        reason: str | None = None
        gt_row = None
        if not four_four:
            reason = SKIP_TIME_SIGNATURE
        else:
            gt_row = bpm_module.find_ground_truth_match(
                bpm_module.strip_audio_prefix(clip.audio_path), gt_rows
            )
            if gt_row is None:
                reason = SKIP_UNMATCHED
            elif gt_row["filename"] in reserved:
                reason = SKIP_DUPLICATE
            else:
                # The first clip matched to a filename reserves it, even if it is skipped below.
                reserved.add(gt_row["filename"])
        if reason is None and gt_row is not None:
            result = annotate_clip(clip)
            if isinstance(result, str):
                reason = result
            else:
                entries.append(build_entry(gt_row, result, application, curator))
        if reason is not None:
            skips.append(f"skip {clip.basename}: {reason}")

    entries.sort(key=lambda e: e["file_metadata"]["identifiers"]["basename"])
    return {"entries": entries}, skips


def _round_floats(value: object) -> object:
    if isinstance(value, float):
        return round(value, 6) + 0.0  # + 0.0 folds -0.0 into 0.0
    if isinstance(value, dict):
        return {k: _round_floats(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_round_floats(v) for v in value]
    return value


def render(document: dict) -> bytes:
    text = json.dumps(_round_floats(document), sort_keys=True, indent=2, ensure_ascii=False)
    return (text + "\n").encode("utf-8")


def write_atomic(out_path: str, data: bytes) -> None:
    """Write via a temp file in the target directory and `os.replace` it into place."""
    target = Path(out_path)
    tmp_name: str | None = None
    try:
        fd, tmp_name = tempfile.mkstemp(dir=target.parent, prefix=f".{target.name}.", suffix=".tmp")
        with os.fdopen(fd, "wb") as fh:
            fh.write(data)
            fh.flush()
            os.fsync(fh.fileno())
        umask = os.umask(0)
        os.umask(umask)
        os.chmod(tmp_name, 0o666 & ~umask)
        os.replace(tmp_name, target)
        tmp_name = None
    except OSError as exc:
        raise InputError(f"--out {out_path}: cannot write: {exc.strerror or exc}") from None
    finally:
        if tmp_name is not None:
            with contextlib.suppress(OSError):
                os.unlink(tmp_name)


def check_summary(out_path: str, expected: bytes) -> str | None:
    """None when `out_path` already holds `expected`, else a one-line reason."""
    try:
        existing = Path(out_path).read_bytes()
    except FileNotFoundError:
        return f"check: {out_path} is missing"
    except OSError as exc:
        return f"check: {out_path} is unreadable: {exc.strerror or exc}"
    if existing == expected:
        return None
    try:
        old_entries = json.loads(existing)["entries"]
        new_entries = json.loads(expected)["entries"]
    except (ValueError, KeyError, TypeError):
        return f"check: {out_path} is not an annotations document"
    for old, new in zip(old_entries, new_entries):
        if old != new:
            return f"check: {out_path} differs at entry {_entry_basename(new)}"
    if len(old_entries) != len(new_entries):
        longer = old_entries if len(old_entries) > len(new_entries) else new_entries
        extra = longer[min(len(old_entries), len(new_entries))]
        return f"check: {out_path} differs at entry {_entry_basename(extra)}"
    return f"check: {out_path} differs in formatting only"


def _entry_basename(entry: Any) -> str:
    node: Any = entry
    for key in ("file_metadata", "identifiers", "basename"):
        if not isinstance(node, dict) or key not in node:
            return "<unnamed entry>"
        node = node[key]
    return str(node)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument("--dawproject", required=True, help="Path to the .dawproject file")
    parser.add_argument(
        "--match", required=True, metavar="GROUND_TRUTH_JSON", help="OA300 JAMS ground truth"
    )
    parser.add_argument("--out", required=True, help="Output path for daw-oracle-annotations.json")
    parser.add_argument(
        "--check", action="store_true", help="Compare against --out without writing"
    )
    args = parser.parse_args(argv)

    try:
        document, skips = generate(args.dawproject, args.match)
        for line in skips:
            print(line, file=sys.stderr)
        data = render(document)
        if args.check:
            summary = check_summary(args.out, data)
            if summary is not None:
                print(summary, file=sys.stderr)
                return 1
            return 0
        write_atomic(args.out, data)
    except InputError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
