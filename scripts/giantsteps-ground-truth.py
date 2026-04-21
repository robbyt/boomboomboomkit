#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Regenerate GiantSteps Tempo ground truth JSON from JAMS annotations.

Parses annotations_v2/jams/*.jams for dual-tempo entries and
annotations/genre/*.genre for genre labels.

Usage:
  uv run scripts/giantsteps-ground-truth.py <giantsteps_dataset_dir>
"""

import argparse
import json
import sys
from pathlib import Path


def parse_jams_file(jams_path: Path) -> list[dict]:
    """Extract tempo entries from a JAMS file, sorted by confidence descending."""
    with open(jams_path) as f:
        jams = json.load(f)

    annotations = jams.get("annotations", [])
    if not annotations:
        return []

    # Find the tempo annotation block
    tempo_ann = None
    for ann in annotations:
        if ann.get("namespace") == "tempo":
            tempo_ann = ann
            break
    if tempo_ann is None:
        return []

    data = tempo_ann.get("data", [])
    entries = []
    for d in data:
        value = d.get("value")
        confidence = d.get("confidence", 0.0)
        if value is not None and value > 0:
            entries.append({"value": float(value), "confidence": float(confidence)})

    # Sort by confidence descending
    entries.sort(key=lambda e: e["confidence"], reverse=True)
    return entries


def load_genre(genre_dir: Path, track_id: str) -> str:
    """Read genre from a .genre file, return empty string if missing."""
    genre_file = genre_dir / f"{track_id}.LOFI.genre"
    if genre_file.exists():
        return genre_file.read_text().strip()
    return ""


def main():
    parser = argparse.ArgumentParser(
        description="Generate GiantSteps ground truth JSON with dual-tempo annotations."
    )
    parser.add_argument(
        "dataset_dir",
        help="Path to giantsteps-tempo-dataset root directory",
    )
    args = parser.parse_args()

    dataset = Path(args.dataset_dir)
    jams_dir = dataset / "annotations_v2" / "jams"
    genre_dir = dataset / "annotations" / "genre"

    if not jams_dir.exists():
        print(f"Error: JAMS directory not found: {jams_dir}", file=sys.stderr)
        sys.exit(1)

    tracks = []
    skipped = 0

    for jams_file in sorted(jams_dir.glob("*.jams")):
        track_id = jams_file.stem.replace(".LOFI", "")
        tempos = parse_jams_file(jams_file)

        # Exclude tracks with 0 tempo annotations
        if not tempos:
            skipped += 1
            continue

        bpm = tempos[0]["value"]  # highest confidence
        tempo2 = tempos[1]["value"] if len(tempos) >= 2 else None
        genre = load_genre(genre_dir, track_id)

        entry = {
            "filename": f"{track_id}.LOFI.mp3",
            "bpm": bpm,
            "tempo2": tempo2,
            "track_id": track_id,
            "genre": genre,
        }
        tracks.append(entry)

    # Sort by track_id for stable diffs
    tracks.sort(key=lambda t: t["track_id"])

    print(
        f"Generated {len(tracks)} entries, skipped {skipped} (0 annotations)",
        file=sys.stderr,
    )

    dual = sum(1 for t in tracks if t["tempo2"] is not None)
    single = sum(1 for t in tracks if t["tempo2"] is None)
    print(f"Dual-tempo: {dual}, Single-tempo: {single}", file=sys.stderr)

    json.dump(tracks, sys.stdout, indent=2)
    print()  # trailing newline


if __name__ == "__main__":
    main()
