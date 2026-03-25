#!/usr/bin/env python3
"""
Convert a Rekordbox UTF-16 TSV export to oa300-ground-truth.json.

Usage:
    python3 convert-rekordbox-export.py /path/to/OA300_OnsetAudio300

Reads OA300_OnsetAudio300.txt (Rekordbox export) from the corpus directory,
matches track titles to audio files on disk, and writes oa300-ground-truth.json
to the same directory as this script.

Supported audio formats: .wav, .mp3, .flac, .m4a, .aiff
"""

import json
import os
import sys
from collections import Counter, defaultdict


def parse_rekordbox_tsv(tsv_path: str) -> list[dict]:
    """Parse a Rekordbox UTF-16 TSV export file."""
    with open(tsv_path, "rb") as f:
        raw = f.read()

    text = raw.decode("utf-16")
    lines = text.strip().split("\n")

    if len(lines) < 2:
        print(f"Error: TSV file has only {len(lines)} lines (expected header + data)")
        sys.exit(1)

    header = [h.strip() for h in lines[0].split("\t")]
    print(f"Header columns: {header}")

    # Find column indices
    try:
        title_idx = header.index("Track Title")
        bpm_idx = header.index("BPM")
    except ValueError as e:
        print(f"Error: Required column not found: {e}")
        print(f"Available columns: {header}")
        sys.exit(1)

    entries = []
    for i, line in enumerate(lines[1:], start=2):
        fields = line.split("\t")
        if len(fields) <= max(title_idx, bpm_idx):
            print(f"  Warning: Line {i} has only {len(fields)} fields, skipping")
            continue
        title = fields[title_idx].strip()
        bpm_str = fields[bpm_idx].strip()
        if not bpm_str:
            print(f"  Warning: Line {i} '{title}' has no BPM, skipping")
            continue
        try:
            bpm = float(bpm_str)
        except ValueError:
            print(f"  Warning: Line {i} '{title}' has invalid BPM '{bpm_str}', skipping")
            continue
        entries.append({"title": title, "bpm": bpm})

    return entries


def scan_audio_files(corpus_dir: str) -> list[dict]:
    """Recursively find all audio files in the corpus directory."""
    audio_extensions = {".wav", ".mp3", ".flac", ".m4a", ".aiff"}
    files = []
    for dirpath, _, filenames in os.walk(corpus_dir):
        for fn in filenames:
            ext = os.path.splitext(fn)[1].lower()
            if ext in audio_extensions:
                rel_dir = os.path.relpath(dirpath, corpus_dir)
                subdir = None if rel_dir == "." else rel_dir
                stem = os.path.splitext(fn)[0]
                files.append({"filename": fn, "subdir": subdir, "stem": stem})
    return files


def match_title_to_file(title: str, files: list[dict]) -> dict | None:
    """Match a track title to an audio file using multiple strategies."""
    # Strategy 1: exact stem match
    for f in files:
        if title == f["stem"]:
            return f

    # Strategy 2: title is contained in stem
    for f in files:
        if title in f["stem"]:
            return f

    # Strategy 3: stem contains title
    for f in files:
        if f["stem"] in title:
            return f

    # Strategy 4: case-insensitive word overlap (words > 3 chars)
    title_words = set(
        w for w in title.lower().replace("(", "").replace(")", "").split() if len(w) > 3
    )
    if title_words:
        for f in files:
            stem_lower = f["stem"].lower()
            hits = sum(1 for w in title_words if w in stem_lower)
            if hits >= 2:
                return f

    return None


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} /path/to/corpus_directory")
        print(f"  The directory must contain a Rekordbox TSV export file.")
        sys.exit(1)

    corpus_dir = sys.argv[1]

    if not os.path.isdir(corpus_dir):
        print(f"Error: '{corpus_dir}' is not a directory")
        sys.exit(1)

    # Find the TSV file
    tsv_candidates = [f for f in os.listdir(corpus_dir) if f.endswith(".txt")]
    if not tsv_candidates:
        print(f"Error: No .txt files found in '{corpus_dir}'")
        sys.exit(1)

    if len(tsv_candidates) > 1:
        print(f"Multiple .txt files found: {tsv_candidates}")
        print(f"Using: {tsv_candidates[0]}")

    tsv_path = os.path.join(corpus_dir, tsv_candidates[0])
    print(f"Parsing: {tsv_path}")

    entries = parse_rekordbox_tsv(tsv_path)
    print(f"Parsed {len(entries)} entries from TSV")

    audio_files = scan_audio_files(corpus_dir)
    print(f"Found {len(audio_files)} audio files on disk")

    # Match entries to files
    result = []
    unmatched = []
    used_files = set()

    for entry in entries:
        title = entry["title"]
        bpm = entry["bpm"]

        available = [f for f in audio_files if f["filename"] not in used_files]
        found = match_title_to_file(title, available)

        if found:
            used_files.add(found["filename"])
            result.append(
                {
                    "filename": found["filename"],
                    "bpm": bpm,
                    "subdir": found["subdir"],
                    "title": title,
                }
            )
        else:
            unmatched.append(title)

    # Deduplicate by (filename, subdir)
    seen = set()
    deduped = []
    for entry in result:
        key = (entry["filename"], entry.get("subdir"))
        if key not in seen:
            seen.add(key)
            deduped.append(entry)

    # Report
    print(f"\nMatched: {len(deduped)}/{len(entries)}")

    if unmatched:
        print(f"\nUnmatched ({len(unmatched)}):")
        for t in unmatched:
            print(f"  - {t}")

    # Stats
    by_subdir = defaultdict(int)
    for r in deduped:
        by_subdir[r["subdir"] or "root"] += 1
    print("\nBy subdirectory:")
    for sd, count in sorted(by_subdir.items()):
        print(f"  {sd}: {count}")

    bpms = [r["bpm"] for r in deduped]
    if bpms:
        print(f"\nBPM range: {min(bpms)} - {max(bpms)}")
        print(f"Unique BPMs: {len(set(bpms))}")

    # Write output
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, "oa300-ground-truth.json")
    with open(output_path, "w") as f:
        json.dump(deduped, f, indent=2, ensure_ascii=False)

    print(f"\nWrote {len(deduped)} entries to {output_path}")


if __name__ == "__main__":
    main()
