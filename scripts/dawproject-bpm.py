#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Extract per-clip BPM from a .dawproject file.

Usage:
  uv run scripts/dawproject-bpm.py <file.dawproject>              # table output
  uv run scripts/dawproject-bpm.py <file.dawproject> --json       # raw JSON
  uv run scripts/dawproject-bpm.py <file.dawproject> --match GT   # oracle JSON matched to ground truth
"""

import argparse
import json
import math
import os
import subprocess
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from typing import TypeGuard


def _is_json_number(x: object) -> TypeGuard[float]:
    """True iff `x` is a real (non-`bool`) finite JSON number. Mirrors the same guard in
    `_bmad-output/ml-training/migrate-to-jams.py` (a different uv project this script cannot
    import): `bool` is an `int` subclass and `json` parses `NaN`/`Infinity` into floats."""
    return not isinstance(x, bool) and isinstance(x, (int, float)) and math.isfinite(x)


# --- JAMS interop (Story 8.8b) -------------------------------------------------
# The OA300 ground truth this script reads (--match) is a JAMS `tempo` corpus, and the
# daw oracle it writes is migrated to JAMS too. These inline helpers mirror
# `_bmad-output/ml-training/migrate-to-jams.py` (which this script cannot import — a
# different uv project); the emitted shape is what that migrator validates as already-JAMS.


def _load_oa300_rows(path: str) -> list[dict]:
    """Read a JAMS oa300 corpus back into flat {filename, bpm, subdir, title} rows."""
    with open(path) as f:
        doc = json.load(f)
    if not isinstance(doc, dict) or "entries" not in doc:
        raise ValueError(f"{path} is not a JAMS corpus (expected a top-level 'entries' list)")
    rows = []
    for entry in doc["entries"]:
        file_metadata = entry.get("file_metadata", {})
        identifiers = file_metadata.get("identifiers", {})
        sandbox = entry.get("sandbox", {})
        bpm = None
        for ann in entry.get("annotations", []):
            if ann.get("namespace") == "tempo":
                data = ann.get("data") or []
                if data:
                    bpm = data[0].get("value")
                break
        # Fail loudly with a sourced message rather than letting a None/non-numeric BPM reach
        # classify_disagreement downstream as an obscure TypeError.
        if not _is_json_number(bpm):
            raise ValueError(
                f"{path}: JAMS entry {identifiers.get('basename')!r} has no finite numeric tempo value"
            )
        rows.append(
            {
                "filename": identifiers.get("basename"),
                "bpm": float(bpm),
                "subdir": sandbox.get("subdir"),
                "title": file_metadata.get("title"),
            }
        )
    return rows


def _git_config(key: str, fallback: str) -> str:
    try:
        out = subprocess.run(["git", "config", key], capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return fallback
    return out.stdout.strip() or fallback


def _curator() -> dict:
    return {
        "name": _git_config("user.name", "Robert Terhaar"),
        "email": _git_config("user.email", "robbyt@gmail.com"),
    }


def _daw_oracle_to_jams(oracle: list[dict], curator: dict) -> dict:
    """Convert the flat daw-oracle rows to a JAMS `tempo` corpus (canonical value = daw_bpm)."""
    entries = []
    for row in oracle:
        basename = row["filename"]
        subdir = row.get("subdir")
        local_path = f"{subdir}/{basename}" if subdir else basename
        sandbox: dict = {}
        if subdir is not None:
            sandbox["subdir"] = subdir
        sandbox["rekordbox_bpm"] = float(row["rekordbox_bpm"])
        # Preserve the source type (it is already a real bool from match_to_ground_truth);
        # do NOT bool()-coerce, which would flip a stray string to True. The migrator's daw
        # validator enforces a real bool on the resulting file.
        sandbox["rekordbox_disagrees"] = row["rekordbox_disagrees"]
        sandbox["disagreement_type"] = row.get("disagreement_type")
        entries.append(
            {
                "file_metadata": {
                    "duration": 0,
                    "jams_version": "0.4.0",
                    "identifiers": {
                        "basename": basename,
                        "local_path": local_path,
                        "track_id": basename,
                    },
                },
                "annotations": [
                    {
                        "namespace": "tempo",
                        "data": [
                            {
                                "time": 0.0,
                                "duration": 0.0,
                                "value": float(row["daw_bpm"]),
                                "confidence": 1.0,
                            }
                        ],
                        "annotation_metadata": {
                            "curator": curator,
                            "data_source": "DAW manual placement",
                        },
                    }
                ],
                "sandbox": sandbox,
            }
        )
    return {"entries": entries}


def extract_clip_bpms(dawproject_path: str) -> tuple[list[dict], float | None]:
    """Read a .dawproject ZIP and derive per-clip BPM from warp markers."""
    with zipfile.ZipFile(dawproject_path, "r") as zf:
        with zf.open("project.xml") as f:
            tree = ET.parse(f)

    root = tree.getroot()

    tempo_el = root.find(".//Tempo")
    project_tempo = float(tempo_el.get("value")) if tempo_el is not None else None

    tracks = {}
    for track in root.iter("Track"):
        tid = track.get("id")
        name = track.get("name", "")
        if tid and name:
            tracks[tid] = name

    clips = []
    for lanes in root.findall(".//Arrangement//Lanes[@track]"):
        track_id = lanes.get("track")
        track_name = tracks.get(track_id, track_id)

        for warps in lanes.iter("Warps"):
            audio = warps.find("Audio")
            if audio is None:
                continue

            audio_file = ""
            file_el = audio.find("File")
            if file_el is not None:
                audio_file = file_el.get("path", "")

            warp_points = warps.findall("Warp")
            if len(warp_points) < 2:
                continue

            last = warp_points[-1]
            total_beats = float(last.get("time"))
            total_seconds = float(last.get("contentTime"))

            if total_seconds <= 0:
                continue

            bpm = total_beats / total_seconds * 60.0

            clips.append(
                {
                    "track": track_name,
                    "bpm": round(bpm, 2),
                    "beats": round(total_beats, 2),
                    "seconds": round(total_seconds, 2),
                    "file": audio_file,
                }
            )

    return clips, project_tempo


def strip_audio_prefix(path: str) -> str:
    """Strip leading 'audio/' from dawproject file paths."""
    if path.startswith("audio/"):
        return path[6:]
    return path


def stem(filename: str) -> str:
    """Return filename without extension."""
    return os.path.splitext(filename)[0]


def normalize(s: str) -> str:
    """Normalize Unicode to NFC for consistent comparison."""
    return unicodedata.normalize("NFC", s)


def find_ground_truth_match(daw_filename: str, gt_entries: list[dict]) -> dict | None:
    """Match a dawproject filename to a ground truth entry."""
    daw_norm = normalize(daw_filename)

    # 1. Exact filename match (Unicode-normalized)
    for entry in gt_entries:
        if normalize(entry["filename"]) == daw_norm:
            return entry

    # 2. Stem containment (handles truncated or prefixed names)
    daw_stem = stem(daw_norm).lower()
    daw_ext = os.path.splitext(daw_norm)[1].lower()
    for entry in gt_entries:
        gt_stem = stem(normalize(entry["filename"])).lower()
        gt_ext = os.path.splitext(entry["filename"])[1].lower()
        if daw_ext == gt_ext and (daw_stem in gt_stem or gt_stem in daw_stem):
            return entry

    # 3. Cross-extension stem containment (e.g., .wav vs .mp3)
    for entry in gt_entries:
        gt_stem = stem(normalize(entry["filename"])).lower()
        if daw_stem in gt_stem or gt_stem in daw_stem:
            return entry

    return None


def classify_disagreement(daw_bpm: float, rkbx_bpm: float) -> str | None:
    """Classify the ratio between DAW and Rekordbox BPMs."""
    if rkbx_bpm <= 0:
        return None
    ratio = daw_bpm / rkbx_bpm
    # Check octave: ratio ~2.0 or ~0.5
    if abs(ratio - 2.0) / 2.0 <= 0.02 or abs(ratio - 0.5) / 0.5 <= 0.02:
        return "octave"
    # Check triplet: ratio ~1.5 or ~0.667
    if abs(ratio - 1.5) / 1.5 <= 0.02 or abs(ratio - 2.0 / 3.0) / (2.0 / 3.0) <= 0.02:
        return "triplet"
    if abs(ratio - 1.0) / 1.0 <= 0.02:
        return None  # They agree
    return "other"


def match_to_ground_truth(clips: list[dict], gt_path: str) -> list[dict]:
    """Match dawproject clips to ground truth and produce oracle entries."""
    # OA300 ground truth is a JAMS tempo corpus post-Story-8.8b; read it back to flat rows.
    gt_entries = _load_oa300_rows(gt_path)

    oracle = []
    unmatched = []

    seen_filenames = set()

    for clip in clips:
        daw_filename = strip_audio_prefix(clip["file"])
        gt_entry = find_ground_truth_match(daw_filename, gt_entries)

        if gt_entry is None:
            unmatched.append(daw_filename)
            continue

        # Deduplicate (track 5 has both .wav and .mp3)
        if gt_entry["filename"] in seen_filenames:
            continue
        seen_filenames.add(gt_entry["filename"])

        rkbx_bpm = gt_entry["bpm"]
        daw_bpm = clip["bpm"]
        disagree_type = classify_disagreement(daw_bpm, rkbx_bpm)
        disagrees = disagree_type is not None

        oracle.append(
            {
                "filename": gt_entry["filename"],
                "daw_bpm": daw_bpm,
                "rekordbox_bpm": rkbx_bpm,
                "subdir": gt_entry.get("subdir"),
                "rekordbox_disagrees": disagrees,
                "disagreement_type": disagree_type,
            }
        )

    if unmatched:
        print(f"Warning: {len(unmatched)} clips not matched to ground truth:", file=sys.stderr)
        for name in unmatched:
            print(f"  - {name}", file=sys.stderr)

    return oracle


def main():
    parser = argparse.ArgumentParser(description="Extract per-clip BPM from .dawproject files")
    parser.add_argument("dawproject", help="Path to .dawproject file")
    parser.add_argument("--json", action="store_true", help="Output raw clip data as JSON")
    parser.add_argument(
        "--match",
        metavar="GROUND_TRUTH_JSON",
        help="Match clips to ground truth and output oracle JSON",
    )
    args = parser.parse_args()

    clips, project_tempo = extract_clip_bpms(args.dawproject)

    if args.match:
        oracle = match_to_ground_truth(clips, args.match)
        # Emit the daw oracle as a JAMS tempo corpus (Story 8.8b AC 3) so a regenerate is a
        # no-op against the migrated file.
        print(json.dumps(_daw_oracle_to_jams(oracle, _curator()), indent=2, ensure_ascii=False))
        return

    if args.json:
        print(json.dumps(clips, indent=2))
        return

    # Default: table output
    if project_tempo is not None:
        print(f"Project tempo: {project_tempo} BPM")
    print()

    print(f"{'Track':<55} {'BPM':>8}  {'File'}")
    print("-" * 100)
    for c in clips:
        print(f"{c['track']:<55} {c['bpm']:>8.1f}  {c['file']}")


if __name__ == "__main__":
    main()
