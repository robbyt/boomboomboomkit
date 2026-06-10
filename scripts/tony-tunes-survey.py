#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Survey a Rekordbox XML export against an on-disk audio tree.

Diagnostic-only. Does NOT commit to a ground-truth schema or label policy
(half-time vs canonical tempo is unresolved — see Tony corpus discussion).

What it does:
- Parses every <TRACK> in the XML (TrackID, Name, Artist, Album, Kind, BitRate,
  SampleRate, AverageBpm, TotalTime, Location, TEMPO count, Tonality)
- Indexes every playlist <NODE> and maps TrackID -> [playlist names]
- For each XML track, resolves the embedded `file://` Location against an
  on-disk audio root by **basename match**, recursively scanning the root.
  XML paths reference Tony's hostname (`/Users/echtoo-mbp/...`); basename
  is the most reliable join.
- Emits per-track JSON to stdout AND a summary report to stderr covering:
    * Kind / BitRate / SampleRate histograms
    * AverageBpm histogram with a half-time annotation (<100 BPM bucket)
    * Multi-TEMPO bookkeeping (manually-adjusted beatgrid count)
    * Playlist coverage histogram
    * Path-resolve success rate + duplicate-basename collisions
    * Tracks with zero or absurd BPM (data hygiene)

Usage:
  uv run scripts/tony-tunes-survey.py <rekordbox.xml> --audio-root <dir> > survey.json
  uv run scripts/tony-tunes-survey.py <rekordbox.xml> --audio-root <dir> --summary-only
  uv run scripts/tony-tunes-survey.py <rekordbox.xml> --audio-root <dir> \
      --write-missing <dir>/missing-tracks.txt

Exit codes:
  0  parsed successfully (warnings still go to stderr)
  2  XML or audio-root path missing / unreadable
"""

import argparse
import collections
import json
import sys
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path


# ---------------------------------------------------------------------------
# XML parsing
# ---------------------------------------------------------------------------


def parse_tracks(xml_root: ET.Element) -> list[dict]:
    """Return one dict per <TRACK> in COLLECTION.

    Numeric fields are coerced (bpm to float, bitrate/samplerate/total_time to
    int) with a None fallback when the attribute is missing or malformed.
    """
    collection = xml_root.find("COLLECTION")
    if collection is None:
        return []

    tracks = []
    for t in collection.findall("TRACK"):
        location_raw = t.get("Location", "")
        location_decoded = _decode_location(location_raw)

        tempo_elems = t.findall("TEMPO")
        record = {
            "track_id": t.get("TrackID", ""),
            "name": t.get("Name", ""),
            "artist": t.get("Artist", ""),
            "album": t.get("Album", ""),
            "kind": t.get("Kind", ""),
            "bit_rate": _maybe_int(t.get("BitRate")),
            "sample_rate": _maybe_int(t.get("SampleRate")),
            "average_bpm": _maybe_float(t.get("AverageBpm")),
            "total_time": _maybe_int(t.get("TotalTime")),
            "tonality": t.get("Tonality", ""),
            "genre": t.get("Genre", ""),
            "year": _maybe_int(t.get("Year")),
            "rating": _maybe_int(t.get("Rating")),
            "play_count": _maybe_int(t.get("PlayCount")),
            "location_xml": location_raw,
            "location_decoded": location_decoded,
            "basename": _basename_from_location(location_decoded),
            "tempo_count": len(tempo_elems),
            "first_tempo_bpm": _maybe_float(tempo_elems[0].get("Bpm")) if tempo_elems else None,
            "first_tempo_inizio": _maybe_float(tempo_elems[0].get("Inizio"))
            if tempo_elems
            else None,
        }
        tracks.append(record)
    return tracks


def parse_playlists(xml_root: ET.Element) -> dict[str, list[str]]:
    """Return {track_id: [playlist_name, ...]} from the PLAYLISTS section.

    Only Type="1" (track-list) playlists are followed; folder nodes are skipped.
    """
    out: dict[str, list[str]] = collections.defaultdict(list)
    playlists_root = xml_root.find("PLAYLISTS")
    if playlists_root is None:
        return out

    for node in playlists_root.iter("NODE"):
        # Type=1 means playlist (vs. Type=0 folder).
        if node.get("Type") != "1":
            continue
        name = node.get("Name", "")
        for tr in node.findall("TRACK"):
            tid = tr.get("Key", "")
            if tid:
                out[tid].append(name)
    return out


def _maybe_int(v):
    if v is None or v == "":
        return None
    try:
        return int(v)
    except ValueError:
        return None


def _maybe_float(v):
    if v is None or v == "":
        return None
    try:
        return float(v)
    except ValueError:
        return None


def _decode_location(loc: str) -> str:
    """Decode a Rekordbox `file://localhost/...` URL into a filesystem path.

    Returns the empty string for empty input. Non-`file://` URLs (rare) pass
    through unchanged.
    """
    if not loc:
        return ""
    if loc.startswith("file://localhost"):
        loc = loc[len("file://localhost") :]
    elif loc.startswith("file://"):
        loc = loc[len("file://") :]
    return urllib.parse.unquote(loc)


def _basename_from_location(decoded: str) -> str:
    if not decoded:
        return ""
    return decoded.rsplit("/", 1)[-1]


# ---------------------------------------------------------------------------
# On-disk path resolution (basename-match, recursive)
# ---------------------------------------------------------------------------


def build_basename_index(audio_root: Path) -> dict[str, list[Path]]:
    """Recursively walk audio_root and bucket files by basename.

    Multiple files can share a basename across genre subdirs (e.g. duplicates
    in Tony's library) — keep the list and surface collisions in the report.
    """
    index: dict[str, list[Path]] = collections.defaultdict(list)
    exts = {".mp3", ".wav", ".aif", ".aiff", ".flac", ".m4a", ".caf"}
    for p in audio_root.rglob("*"):
        if not p.is_file():
            continue
        if p.suffix.lower() not in exts:
            continue
        index[p.name].append(p)
    return index


def resolve_one(record: dict, index: dict[str, list[Path]]) -> tuple[str | None, str]:
    """Resolve a single track's local path.

    Returns (local_path_or_None, status):
      status in {"ok", "cloud_only", "ambiguous", "missing", "no_location"}.
    `cloud_only` means the file exists but is 0 bytes — typically a Dropbox /
    iCloud Drive placeholder that hasn't been materialized locally. These
    files cannot be analyzed and need to be downloaded first
    (Dropbox: right-click -> "Make Available Offline" on the parent dir).
    `ambiguous` returns the first match for reporting but flags the duplicate
    set in the summary.
    """
    basename = record.get("basename") or ""
    if not basename:
        return None, "no_location"
    matches = index.get(basename, [])
    if not matches:
        return None, "missing"
    chosen = matches[0]
    try:
        size = chosen.stat().st_size
    except OSError:
        size = -1
    if size == 0:
        return str(chosen), "cloud_only"
    if len(matches) > 1:
        return str(chosen), "ambiguous"
    return str(chosen), "ok"


# ---------------------------------------------------------------------------
# Summary helpers
# ---------------------------------------------------------------------------


def _bpm_bucket(bpm: float | None) -> str:
    if bpm is None:
        return "missing"
    if bpm <= 0:
        return "zero"
    return f"{int(bpm // 10) * 10}-{int(bpm // 10) * 10 + 9}"


def _half_time_flag(bpm: float | None) -> bool:
    """True for tracks Rekordbox likely tagged at half-time (DJ convention).

    Heuristic: 60-99 BPM in a corpus of dance music is almost always a
    half-time tag for a 120-198 BPM track. NOT applied to records; this is
    diagnostic-only so we can have an informed discussion before committing
    to a label-normalization policy.
    """
    return bpm is not None and 60.0 <= bpm < 100.0


def emit_summary(
    tracks: list[dict],
    playlist_index: dict[str, list[str]],
    resolution: dict[str, str],
    duplicates: dict[str, list[str]],
    out=sys.stderr,
) -> None:
    n = len(tracks)
    print(f"# Tony tunes survey — {n} TRACK entries", file=out)
    print(file=out)

    # --- Kind / BitRate / SampleRate ---
    kind_h = collections.Counter(t["kind"] or "(empty)" for t in tracks)
    print("Kind:", file=out)
    for k, c in kind_h.most_common():
        print(f"  {c:>5}  {k}", file=out)

    bitrate_h = collections.Counter(t["bit_rate"] for t in tracks)
    print("\nBitRate:", file=out)
    for k, c in sorted(bitrate_h.items(), key=lambda kv: -kv[1]):
        print(f"  {c:>5}  {k}", file=out)

    sr_h = collections.Counter(t["sample_rate"] for t in tracks)
    print("\nSampleRate:", file=out)
    for k, c in sorted(sr_h.items(), key=lambda kv: -kv[1]):
        print(f"  {c:>5}  {k}", file=out)

    # --- BPM ---
    bpm_buckets = collections.Counter(_bpm_bucket(t["average_bpm"]) for t in tracks)
    print("\nAverageBpm buckets (10-BPM bins):", file=out)
    for k in sorted(bpm_buckets.keys(), key=_bucket_sort_key):
        flag = (
            " (half-time-suspect)"
            if k != "missing" and k != "zero" and _bucket_is_halftime(k)
            else ""
        )
        print(f"  {bpm_buckets[k]:>5}  {k}{flag}", file=out)
    print(
        f"\n  half-time-suspect tracks (60 <= BPM < 100): "
        f"{sum(1 for t in tracks if _half_time_flag(t['average_bpm']))}/{n}",
        file=out,
    )

    # --- TEMPO grid ---
    multi_tempo = sum(1 for t in tracks if (t["tempo_count"] or 0) > 1)
    no_tempo = sum(1 for t in tracks if (t["tempo_count"] or 0) == 0)
    print(
        f"\nTEMPO entries: {multi_tempo} multi-grid (>=2 entries, manually adjusted), "
        f"{no_tempo} with zero <TEMPO> elements",
        file=out,
    )

    # --- Playlist coverage ---
    playlist_track_counts: dict[str, int] = collections.Counter()
    for tid, names in playlist_index.items():
        for n_ in names:
            playlist_track_counts[n_] += 1
    in_any_playlist = sum(1 for t in tracks if t["track_id"] in playlist_index)
    print(
        f"\nPlaylist coverage: {in_any_playlist}/{n} tracks appear in >=1 playlist",
        file=out,
    )
    print("Playlist sizes (Type=1 playlists only):", file=out)
    for name, c in playlist_track_counts.most_common():
        print(f"  {c:>5}  {name}", file=out)

    # --- Path resolution ---
    status_h = collections.Counter(resolution.values())
    print("\nPath resolution against --audio-root:", file=out)
    for status, c in sorted(status_h.items(), key=lambda kv: -kv[1]):
        print(f"  {c:>5}  {status}", file=out)
    if duplicates:
        print(
            f"\n  basename collisions ({len(duplicates)} basenames with >1 file): showing first 10",
            file=out,
        )
        for i, (bn, paths) in enumerate(duplicates.items()):
            if i >= 10:
                break
            print(f"    [{bn}]", file=out)
            for p in paths:
                print(f"      {p}", file=out)

    # --- Tonality ---
    keyed = sum(1 for t in tracks if t["tonality"])
    print(f"\nTonality tags present: {keyed}/{n}", file=out)


def _bucket_sort_key(k: str):
    if k == "missing":
        return (2, 0)
    if k == "zero":
        return (1, 0)
    return (0, int(k.split("-", 1)[0]))


def _bucket_is_halftime(bucket: str) -> bool:
    try:
        low = int(bucket.split("-", 1)[0])
    except ValueError:
        return False
    return 60 <= low < 100


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Survey a Rekordbox XML export against an on-disk audio tree."
    )
    parser.add_argument("xml_path", help="Path to Rekordbox XML export")
    parser.add_argument(
        "--audio-root",
        required=False,
        help="Root directory to recursively scan for audio files (basename match)",
    )
    parser.add_argument(
        "--summary-only",
        action="store_true",
        help="Suppress per-track JSON on stdout; emit summary on stderr only",
    )
    parser.add_argument(
        "--missing-only",
        action="store_true",
        help="In the JSON output, include only tracks that failed to resolve",
    )
    parser.add_argument(
        "--write-missing",
        metavar="PATH",
        help="Also write a plain-text list of unresolved tracks (artist, title, "
        "XML Location) to PATH, one per line",
    )
    args = parser.parse_args()

    xml_path = Path(args.xml_path)
    if not xml_path.exists():
        print(f"error: XML not found: {xml_path}", file=sys.stderr)
        return 2

    tree = ET.parse(xml_path)
    xml_root = tree.getroot()

    tracks = parse_tracks(xml_root)
    playlist_index = parse_playlists(xml_root)

    # Annotate playlist membership on each track.
    for t in tracks:
        t["playlists"] = playlist_index.get(t["track_id"], [])

    resolution: dict[str, str] = {}
    duplicates: dict[str, list[str]] = {}

    if args.audio_root:
        audio_root = Path(args.audio_root).expanduser().resolve()
        if not audio_root.is_dir():
            print(f"error: --audio-root not a directory: {audio_root}", file=sys.stderr)
            return 2
        print(f"# indexing audio root: {audio_root} (recursive) ...", file=sys.stderr)
        index = build_basename_index(audio_root)
        # Identify true on-disk collisions for the summary.
        duplicates = {bn: [str(p) for p in paths] for bn, paths in index.items() if len(paths) > 1}
        print(
            f"# indexed {sum(len(v) for v in index.values())} audio files "
            f"under {len(index)} unique basenames",
            file=sys.stderr,
        )

        for t in tracks:
            local_path, status = resolve_one(t, index)
            t["local_path"] = local_path
            t["resolve_status"] = status
            resolution[t["track_id"]] = status
    else:
        for t in tracks:
            t["local_path"] = None
            t["resolve_status"] = "skipped"
            resolution[t["track_id"]] = "skipped"

    # Stable sort for diff-friendly output.
    tracks.sort(key=lambda t: (t["artist"], t["album"], t["name"], t["track_id"]))

    emit_summary(tracks, playlist_index, resolution, duplicates)

    if args.write_missing:
        missing_path = Path(args.write_missing).expanduser()
        # Include both genuinely-missing tracks AND Dropbox cloud-only stubs —
        # both are "user needs to do something to make this analyzable" cases.
        missing_tracks = [t for t in tracks if t["resolve_status"] in ("missing", "cloud_only")]
        with open(missing_path, "w") as fh:
            fh.write(f"# Tony tunes — {len(missing_tracks)} XML tracks with no on-disk match\n")
            fh.write(f"# XML source:  {xml_path}\n")
            if args.audio_root:
                fh.write(f"# Audio root:  {Path(args.audio_root).resolve()}\n")
            fh.write("# Each row: <artist> | <title> | <album> | <XML location decoded>\n")
            fh.write("#\n")
            for t in sorted(missing_tracks, key=lambda r: (r["artist"], r["album"], r["name"])):
                fh.write(f"{t['artist']} | {t['name']} | {t['album']} | {t['location_decoded']}\n")
        print(
            f"# wrote {len(missing_tracks)} missing-track entries to {missing_path}",
            file=sys.stderr,
        )

    if not args.summary_only:
        out_tracks = tracks
        if args.missing_only:
            out_tracks = [t for t in tracks if t["resolve_status"] not in ("ok", "ambiguous")]
        json.dump(
            {
                "schema_version": 1,
                "xml_source": str(xml_path),
                "audio_root": str(Path(args.audio_root).resolve()) if args.audio_root else None,
                "track_count": len(tracks),
                "tracks": out_tracks,
            },
            sys.stdout,
            indent=2,
        )
        print()  # trailing newline

    return 0


if __name__ == "__main__":
    sys.exit(main())
