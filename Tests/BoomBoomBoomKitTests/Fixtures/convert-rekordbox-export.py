#!/usr/bin/env python3
"""
Convert a Rekordbox UTF-16 TSV export to oa300-ground-truth.json.

Usage:
    uv run convert-rekordbox-export.py <corpus_dir>                 # JSON to stdout
    uv run convert-rekordbox-export.py <corpus_dir> -o <path>       # JSON to file

Example (writes the canonical fixture location):
    uv run Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py \\
        "$OA300_CORPUS_PATH" \\
        -o Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json

Reads the Rekordbox TSV export (`.txt`) from the corpus directory, matches
track titles to audio files on disk, and emits a JAMS 0.4 `tempo` corpus
(Story 8.8b — one entry per track: bpm in a `tempo` observation, title/filename in
`file_metadata`, subdir/genre in the per-entry `sandbox`; no `genre` from the TSV —
see warning below). With `-o/--output`, writes to that path; otherwise writes to
stdout. Informational logs go to stderr.

Supported audio formats: .wav, .mp3, .flac, .m4a, .aiff

WARNING — this script does NOT preserve the `genre` column.
    Rekordbox TSV has no genre field, so a naive re-run against an existing
    `oa300-ground-truth.json` will overwrite and destroy any genre tags that
    live in the fixture. After Story 2-4 landed, genre is a required
    (non-optional) field on `OA300Track` — re-running this script without
    merging genres back in will break the benchmark suites.

    Safe options:
    (a) Edit `oa300-ground-truth.json` by hand for small changes.
    (b) Extend this script to read/merge a genre side-file (future work).
    Either way, `ALLOWED_GENRES` below is the canonical (extensible) list.
"""

# Canonical genre taxonomy for OA300 (and cross-corpus reports with GiantSteps).
# Seeded by Story 2-4: 23 GiantSteps labels + OA300 extensions (`footwork`, `half-time-dnb`).
# EXTENSIBLE: to add a genre, append it below, then tag the relevant rows in
# `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`, and log the
# addition in the Change Log of the story proposing the new label.
ALLOWED_GENRES = [
    "breaks",
    "chill-out",
    "deep-house",
    "dj-tools",
    "drum-and-bass",
    "dubstep",
    "electro-house",
    "electronica",
    "footwork",
    "funk-r-and-b",
    "glitch-hop",
    "half-time-dnb",
    "hard-dance",
    "hardcore-hard-techno",
    "hip-hop",
    "house",
    "indie-dance-nu-disco",
    "minimal",
    "pop-rock",
    "progressive-house",
    "psy-trance",
    "reggae-dub",
    "tech-house",
    "techno",
    "trance",
]

import argparse
import json
import os
import subprocess
import sys
from collections import Counter, defaultdict


def _curator():
    def cfg(key, fallback):
        try:
            out = subprocess.run(
                ["git", "config", key], capture_output=True, text=True, check=True
            )
        except (OSError, subprocess.CalledProcessError):
            return fallback
        return out.stdout.strip() or fallback

    return {
        "name": cfg("user.name", "Robert Terhaar"),
        "email": cfg("user.email", "robbyt@gmail.com"),
    }


def to_jams(rows, curator):
    """Convert flat {filename, bpm, subdir, title, genre?} rows to a JAMS tempo corpus.

    Mirrors `_bmad-output/ml-training/migrate-to-jams.py`. genre rides the per-entry
    sandbox when present; the Rekordbox TSV has no genre, so a fresh conversion omits it
    and the result must be re-tagged before it loads through `OA300Track` (see WARNING above).
    """
    entries = []
    for row in rows:
        basename = row["filename"]
        subdir = row.get("subdir")
        local_path = f"{subdir}/{basename}" if subdir else basename
        sandbox = {}
        if subdir is not None:
            sandbox["subdir"] = subdir
        if row.get("genre") is not None:
            sandbox["genre"] = row["genre"]
        entry = {
            "file_metadata": {
                "title": row["title"],
                "duration": 0,
                "jams_version": "0.4.0",
                "identifiers": {
                    "basename": basename,
                    "local_path": local_path,
                    "track_id": row["title"],
                },
            },
            "annotations": [
                {
                    "namespace": "tempo",
                    "data": [
                        {
                            "time": 0.0,
                            "duration": 0.0,
                            "value": float(row["bpm"]),
                            "confidence": 1.0,
                        }
                    ],
                    "annotation_metadata": {
                        "curator": curator,
                        "data_source": "OA300 hand-labeled ground truth",
                    },
                }
            ],
        }
        if sandbox:
            entry["sandbox"] = sandbox
        entries.append(entry)
    return {"entries": entries}


def parse_rekordbox_tsv(tsv_path: str) -> list[dict]:
    """Parse a Rekordbox UTF-16 TSV export file."""
    with open(tsv_path, "rb") as f:
        raw = f.read()

    text = raw.decode("utf-16")
    lines = text.strip().split("\n")

    if len(lines) < 2:
        print(
            f"Error: TSV file has only {len(lines)} lines (expected header + data)",
            file=sys.stderr,
        )
        sys.exit(1)

    header = [h.strip() for h in lines[0].split("\t")]
    print(f"Header columns: {header}", file=sys.stderr)

    # Find column indices
    try:
        title_idx = header.index("Track Title")
        bpm_idx = header.index("BPM")
    except ValueError as e:
        print(f"Error: Required column not found: {e}", file=sys.stderr)
        print(f"Available columns: {header}", file=sys.stderr)
        sys.exit(1)

    entries = []
    for i, line in enumerate(lines[1:], start=2):
        fields = line.split("\t")
        if len(fields) <= max(title_idx, bpm_idx):
            print(
                f"  Warning: Line {i} has only {len(fields)} fields, skipping",
                file=sys.stderr,
            )
            continue
        title = fields[title_idx].strip()
        bpm_str = fields[bpm_idx].strip()
        if not bpm_str:
            print(f"  Warning: Line {i} '{title}' has no BPM, skipping", file=sys.stderr)
            continue
        try:
            bpm = float(bpm_str)
        except ValueError:
            print(
                f"  Warning: Line {i} '{title}' has invalid BPM '{bpm_str}', skipping",
                file=sys.stderr,
            )
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
    parser = argparse.ArgumentParser(
        description="Convert a Rekordbox UTF-16 TSV export to oa300-ground-truth.json.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Writes JSON to stdout by default. Use -o/--output to write to a file.\n"
            "NOTE: this script does not emit a `genre` column — see the module "
            "docstring's warning block before re-running against a tagged fixture."
        ),
    )
    parser.add_argument(
        "corpus_dir",
        help="Path to the OA300 corpus directory containing the Rekordbox .txt export.",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output path for the JSON (default: stdout).",
    )
    args = parser.parse_args()

    corpus_dir = args.corpus_dir

    if not os.path.isdir(corpus_dir):
        print(f"Error: '{corpus_dir}' is not a directory", file=sys.stderr)
        sys.exit(1)

    # Find the TSV file
    tsv_candidates = [f for f in os.listdir(corpus_dir) if f.endswith(".txt")]
    if not tsv_candidates:
        print(f"Error: No .txt files found in '{corpus_dir}'", file=sys.stderr)
        sys.exit(1)

    if len(tsv_candidates) > 1:
        print(f"Multiple .txt files found: {tsv_candidates}", file=sys.stderr)
        print(f"Using: {tsv_candidates[0]}", file=sys.stderr)

    tsv_path = os.path.join(corpus_dir, tsv_candidates[0])
    print(f"Parsing: {tsv_path}", file=sys.stderr)

    entries = parse_rekordbox_tsv(tsv_path)
    print(f"Parsed {len(entries)} entries from TSV", file=sys.stderr)

    audio_files = scan_audio_files(corpus_dir)
    print(f"Found {len(audio_files)} audio files on disk", file=sys.stderr)

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

    # Report to stderr so stdout can carry only JSON in the default-stdout mode.
    print(f"\nMatched: {len(deduped)}/{len(entries)}", file=sys.stderr)

    if unmatched:
        print(f"\nUnmatched ({len(unmatched)}):", file=sys.stderr)
        for t in unmatched:
            print(f"  - {t}", file=sys.stderr)

    # Stats
    by_subdir = defaultdict(int)
    for r in deduped:
        by_subdir[r["subdir"] or "root"] += 1
    print("\nBy subdirectory:", file=sys.stderr)
    for sd, count in sorted(by_subdir.items()):
        print(f"  {sd}: {count}", file=sys.stderr)

    bpms = [r["bpm"] for r in deduped]
    if bpms:
        print(f"\nBPM range: {min(bpms)} - {max(bpms)}", file=sys.stderr)
        print(f"Unique BPMs: {len(set(bpms))}", file=sys.stderr)

    # Write output as a JAMS tempo corpus (Story 8.8b) — stdout by default, -o to a file.
    jams = to_jams(deduped, _curator())
    if args.output:
        with open(args.output, "w") as f:
            json.dump(jams, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"\nWrote {len(deduped)} entries to {args.output}", file=sys.stderr)
    else:
        json.dump(jams, sys.stdout, indent=2, ensure_ascii=False)
        sys.stdout.write("\n")


if __name__ == "__main__":
    main()
