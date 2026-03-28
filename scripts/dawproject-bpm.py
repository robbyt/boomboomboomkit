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
import os
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile


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


def find_ground_truth_match(
    daw_filename: str, gt_entries: list[dict]
) -> dict | None:
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
    with open(gt_path) as f:
        gt_entries = json.load(f)

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
        print(json.dumps(oracle, indent=2))
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
