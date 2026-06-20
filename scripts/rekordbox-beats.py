#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Build a multi-track JAMS beat oracle from a Rekordbox XML export.

Develop-only (Story 8.7). Replaces the originally-planned `dawproject-beats.py`:
the operator redirected the beat oracle source from the OA300 `.dawproject` to
Tony's Rekordbox-gridded corpus (story DD-13). Rekordbox `<TEMPO Inizio Bpm
Metro Battito>` markers carry an authoritative beat grid AND the bar-phase
(`Battito`, 1..4 — `1` is the downbeat), so this is a strictly stronger oracle
than warp-marker interpolation could give: per-beat positions for F-measure
(`mir_eval.beat.f_measure`) AND downbeat phase for the Story-8.5a downbeat
validation, with no `value = null` fallback.

Beat-grid model (per track, markers sorted by Inizio):
  For each marker m_i, segment [m_i.Inizio, m_{i+1}.Inizio) (last extends to
  TotalTime) carries beats at  m_i.Inizio + k*(60/m_i.Bpm)  with the bar-phase
  advancing from m_i.Battito (1->2->3->4->1). Intermediate segments stop half a
  period before the next marker (the next marker supplies that boundary beat, so
  closely-spaced hand-adjusted markers de-duplicate cleanly). The first marker
  back-fills toward t >= 0. All Tony grids are 4/4 (verified).

Output: the multi-track JAMS corpus wrapper `{ "corpus": ..., "entries": [...] }`
(DD-9) where each `entries` element is a standalone-valid JAMS object with one
`beat`-namespace annotation. Beat-time field path is `entries[].annotations[].data[].time`
— the byte-for-byte Swift<->Python parity surface (the Swift JAMSDecoder and
eval-beatgrid.py must agree on it).

Hard-fails (does NOT warn-and-emit) if a gridded, on-disk-resolved track yields
no beats — a partial oracle must not silently feed a survivorship-favorable
F-measure floor (DD-10 / DD-17).

Usage:
  uv run scripts/rekordbox-beats.py <rekordbox.xml> --audio-root <dir> > beats.jams.json
  uv run scripts/rekordbox-beats.py <rekordbox.xml> --audio-root <dir> --limit 50
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import math
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path

AUDIO_EXTS = {".mp3", ".wav", ".aif", ".aiff", ".flac", ".m4a", ".caf"}
CORPUS_TAG = "tony-rekordbox-beats-v1"
DATA_SOURCE = "Rekordbox beat grid (TEMPO markers)"

# Operator-curated disambiguation for known basename collisions — different audio files
# that happen to share a filename. The Rekordbox XML `Location` attrs encode a foreign
# machine layout (`/Users/echtoo-mbp/.../Computer Music/...`) reorganized differently from
# this audio root, so neither full nor relative Location matching resolves them; basename
# is the only robust join, and these few basenames map to >1 distinct on-disk file. Rather
# than edit the XML, the importer carries the operator's verified picks (2026-06-19):
#   - Ron Mercy - Junkin Da Trunk.mp3 -> the Bass Music master (the newest copy)
#   - Todd Bucher - Proem/Onyx.wav    -> the newest copy (Seminal Catalog/SMNL002)
# Each value is a path substring that must select EXACTLY ONE candidate; any other
# content-ambiguous collision (or an override that fails to select exactly one) still
# hard-fails loudly.
COLLISION_OVERRIDES = {
    "Ron Mercy - Junkin Da Trunk.mp3": "/Bass Music/",
    "Todd Bucher - Proem.wav": "/Seminal Catalog/SMNL002/",
    "Todd Bucher - Onyx.wav": "/Seminal Catalog/SMNL002/",
}


# ---------------------------------------------------------------------------
# Rekordbox XML parsing
# ---------------------------------------------------------------------------


def _maybe_float(v: str | None) -> float | None:
    if v is None or v == "":
        return None
    try:
        f = float(v)
    except ValueError:
        return None
    # Reject non-finite values: `float("nan")`/`float("inf")` parse cleanly, but a non-finite
    # Bpm yields period 0 (the 200k-iteration loop guard) and a non-finite Inizio yields NaN
    # beat times. Returning None routes them to the loud malformed-marker / missing-TotalTime
    # hard-fail paths instead.
    return f if math.isfinite(f) else None


def _maybe_int(v: str | None) -> int | None:
    if v is None or v == "":
        return None
    try:
        return int(v)
    except ValueError:
        return None


def _decode_location(loc: str) -> str:
    """Decode a Rekordbox `file://localhost/...` URL into a filesystem path."""
    if not loc:
        return ""
    if loc.startswith("file://localhost"):
        loc = loc[len("file://localhost") :]
    elif loc.startswith("file://"):
        loc = loc[len("file://") :]
    return urllib.parse.unquote(loc)


def parse_tracks(xml_root: ET.Element) -> list[dict]:
    """Return one record per <TRACK> carrying its ordered TEMPO markers."""
    collection = xml_root.find("COLLECTION")
    if collection is None:
        return []

    records: list[dict] = []
    for t in collection.findall("TRACK"):
        location = _decode_location(t.get("Location", ""))
        basename = location.rsplit("/", 1)[-1] if location else ""
        markers: list[dict] = []
        # Malformed TEMPO markers are RECORDED (not silently dropped): a resolved, gridded
        # track carrying any of these hard-fails in main() rather than feeding a quietly
        # wrong grid (operator principle: no quiet fixes/guesses). Unresolved or gridless
        # tracks never reach that gate, so a bad marker on an off-disk track is harmless.
        marker_errors: list[str] = []
        for te in t.findall("TEMPO"):
            inizio = _maybe_float(te.get("Inizio"))
            bpm = _maybe_float(te.get("Bpm"))
            battito = _maybe_int(te.get("Battito"))
            metro = te.get("Metro", "")
            if inizio is None or bpm is None or bpm <= 0 or battito is None:
                marker_errors.append(
                    f"unparseable marker (Inizio={te.get('Inizio')!r} "
                    f"Bpm={te.get('Bpm')!r} Battito={te.get('Battito')!r})"
                )
                continue
            if battito not in (1, 2, 3, 4):
                marker_errors.append(f"Battito out of 1..4: {battito}")
                continue
            if metro and metro != "4/4":
                marker_errors.append(f"unsupported Metro (expect 4/4 or empty): {metro!r}")
                continue
            markers.append({"inizio": inizio, "bpm": bpm, "battito": battito, "metro": metro})
        markers.sort(key=lambda m: m["inizio"])
        records.append(
            {
                "track_id": t.get("TrackID", ""),
                "name": t.get("Name", ""),
                "artist": t.get("Artist", ""),
                "total_time": _maybe_float(t.get("TotalTime")),
                "basename": basename,
                "markers": markers,
                "marker_errors": marker_errors,
            }
        )
    return records


# ---------------------------------------------------------------------------
# On-disk audio resolution (basename match, recursive)
# ---------------------------------------------------------------------------


def build_basename_index(audio_root: Path) -> dict[str, list[Path]]:
    index: dict[str, list[Path]] = collections.defaultdict(list)
    for p in audio_root.rglob("*"):
        if p.is_file() and p.suffix.lower() in AUDIO_EXTS:
            index[p.name].append(p)
    # Sort each basename's candidate list so resolve_path()'s first-match is DETERMINISTIC
    # across machines/filesystems. `rglob` traversal order is filesystem-dependent, and
    # on-disk basename collisions exist in this corpus, so an unsorted list would let the
    # chosen audio (hence the oracle population + the calibrated floors) vary by machine.
    for paths in index.values():
        paths.sort()
    return index


def _nonempty(p: Path) -> bool:
    try:
        return p.stat().st_size > 0
    except OSError:
        return False


def sha256_file(path: Path, cache: dict[Path, str]) -> str:
    """SHA-256 of a file's bytes, memoized by Path (one collision file can recur across
    duplicate XML rows). An unreadable candidate (deleted between indexing and hashing,
    permission/IO error) yields a UNIQUE sentinel digest so it never collapses as a
    byte-identical duplicate and instead forces the ambiguous hard-fail — a structured
    refusal rather than a mid-run traceback."""
    cached = cache.get(path)
    if cached is not None:
        return cached
    try:
        h = hashlib.sha256()
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                h.update(chunk)
        digest = h.hexdigest()
    except OSError:
        digest = f"<unreadable:{path}>"
    cache[path] = digest
    return digest


def resolve_path(
    basename: str, index: dict[str, list[Path]], hash_cache: dict[Path, str]
) -> tuple[str | None, list[Path]]:
    """Resolve a basename to its on-disk path, skipping 0-byte cloud-only stubs.

    Returns ``(path, ambiguous)``. On a basename collision (>1 non-empty candidate) the
    candidates are SHA-256'd: byte-identical duplicates collapse to the first
    (deterministic, and PROVABLY the same audio — not a guess); genuinely different
    content returns ``(None, candidates)`` so main() hard-fails rather than silently
    attaching the grid to whichever file sorts first (operator principle: no guesses).
    """
    if not basename:
        return None, []
    candidates = [p for p in index.get(basename, []) if _nonempty(p)]
    if not candidates:
        return None, []
    if len(candidates) == 1:
        return str(candidates[0]), []
    digests = {sha256_file(p, hash_cache) for p in candidates}
    if len(digests) == 1:
        return str(candidates[0]), []  # byte-identical duplicates: safe deterministic pick
    # Genuinely different content. Consult the operator-curated override before refusing:
    # the substring must select EXACTLY ONE candidate, else fall through to a loud hard-fail.
    override = COLLISION_OVERRIDES.get(basename)
    if override is not None:
        selected = [p for p in candidates if override in str(p)]
        if len(selected) == 1:
            print(
                f"# collision-override: {basename} -> {selected[0]} (operator-curated)",
                file=sys.stderr,
            )
            return str(selected[0]), []
    return None, candidates  # genuinely different content: ambiguous -> hard-fail in main


# ---------------------------------------------------------------------------
# Beat-grid extrapolation from TEMPO markers
# ---------------------------------------------------------------------------


def beats_from_markers(markers: list[dict], total_time: float | None) -> list[tuple[float, int]]:
    """Expand ordered TEMPO markers into (time_seconds, bar_phase) beats.

    `bar_phase` is the Rekordbox `Battito` (1..4; 1 = downbeat). Segment i runs to
    the next marker (last to `total_time`); intermediate segments stop half a
    period early so the next marker supplies the boundary beat. The first marker
    back-fills toward t >= 0.
    """
    if not markers:
        return []
    beats: list[tuple[float, int]] = []
    n = len(markers)

    # Forward expansion, segment by segment.
    for i, m in enumerate(markers):
        period = 60.0 / m["bpm"]
        start = m["inizio"]
        if i + 1 < n:
            end = markers[i + 1]["inizio"]
            cutoff = end - period * 0.5  # next marker owns the boundary beat
        else:
            end = total_time if (total_time is not None and total_time > start) else start
            cutoff = end  # last segment extends to track end
        phase = m["battito"]
        k = 0
        while True:
            t = start + k * period
            # Always emit k==0 (the marker's OWN beat — every <TEMPO Inizio> is a real beat);
            # the cutoff only suppresses extra beats before the next marker owns the boundary.
            if k > 0 and t >= cutoff - 1e-9:
                break
            if t < 0:
                k += 1
                phase = phase % 4 + 1
                continue
            beats.append((t, phase))
            k += 1
            phase = phase % 4 + 1
            # Guard against a pathological non-terminating loop.
            if k > 200_000:
                break

    # Back-fill before the first marker toward t >= 0.
    first = markers[0]
    period0 = 60.0 / first["bpm"]
    phase = first["battito"]
    k = 1
    while True:
        t = first["inizio"] - k * period0
        if t < 0:
            break
        phase_back = (first["battito"] - 1 - k) % 4 + 1
        beats.append((t, phase_back))
        k += 1
        if k > 200_000:
            break

    beats.sort(key=lambda b: b[0])
    # De-duplicate beats closer than a small epsilon (boundary artifacts).
    deduped: list[tuple[float, int]] = []
    for t, p in beats:
        if deduped and abs(t - deduped[-1][0]) < 1e-3:
            continue
        deduped.append((t, p))
    return deduped


# ---------------------------------------------------------------------------
# JAMS emission
# ---------------------------------------------------------------------------


def git_user() -> tuple[str, str]:
    def _cfg(key: str) -> str:
        try:
            return subprocess.run(
                ["git", "config", key], capture_output=True, text=True, check=False
            ).stdout.strip()
        except OSError:
            return ""

    return _cfg("user.name"), _cfg("user.email")


def jams_entry(
    record: dict, local_path: str, beats: list[tuple[float, int]], curator: tuple[str, str]
) -> dict:
    name, email = curator
    data = [
        {"time": round(t, 6), "duration": 0.0, "value": phase, "confidence": 1.0}
        for t, phase in beats
    ]
    # A single TEMPO marker == a constant-tempo Rekordbox grid; >=2 markers means the
    # operator hand-adjusted a variable grid. The constant subset is the only material
    # our constant-tempo tracker documents support for, so the gated acceptance metrics
    # (F-measure / FR-29 drift / downbeat) scope to it (story DD-19).
    constant_tempo = len(record["markers"]) == 1
    # JAMS 0.4 requires file_metadata.duration (a number) and jams_version. Fall back to
    # the last beat time when the Rekordbox <TRACK> carries no TotalTime, so the entry is
    # never emitted with a null duration.
    duration = record["total_time"]
    if duration is None:
        duration = beats[-1][0] if beats else 0.0
    return {
        "file_metadata": {
            "title": record["name"],
            "artist": record["artist"],
            "duration": duration,
            "jams_version": "0.4.0",
            "identifiers": {
                "basename": record["basename"],
                "local_path": local_path,
                "track_id": record["track_id"],
            },
        },
        "annotations": [
            {
                "namespace": "beat",
                "data": data,
                "annotation_metadata": {
                    "curator": {"name": name, "email": email},
                    "data_source": DATA_SOURCE,
                },
            }
        ],
        # constant_tempo lives in the JAMS top-level `sandbox`, NOT in file_metadata: the
        # real `jams` library builds a typed FileMetadata and rejects unknown keys there,
        # but accepts arbitrary `sandbox` attributes (story DD-19 develop-only field).
        "sandbox": {"constant_tempo": constant_tempo},
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("xml_path", help="Path to the Rekordbox XML export")
    p.add_argument("--audio-root", required=True, help="Root dir to recursively basename-match")
    p.add_argument("--limit", type=int, default=0, help="Cap the number of tracks (smoke test)")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    xml_path = Path(args.xml_path)
    if not xml_path.exists():
        print(f"error: XML not found: {xml_path}", file=sys.stderr)
        return 2
    audio_root = Path(args.audio_root).expanduser().resolve()
    if not audio_root.is_dir():
        print(f"error: --audio-root not a directory: {audio_root}", file=sys.stderr)
        return 2

    print(f"# indexing audio root {audio_root} (recursive) ...", file=sys.stderr)
    index = build_basename_index(audio_root)
    print(f"# indexed {sum(len(v) for v in index.values())} files", file=sys.stderr)

    records = parse_tracks(ET.parse(xml_path).getroot())
    curator = git_user()

    entries: list[dict] = []
    skipped_no_grid = 0
    skipped_unresolved = 0
    collapsed_dup_path = 0
    failed: list[str] = []  # gridded + resolved but yielded zero beats
    ambiguous: list[tuple[str, list[Path]]] = []  # basename collision, DIFFERENT content (D1)
    invalid_duration: list[tuple[str, float | None, float]] = []  # missing/short TotalTime (P1)
    invalid_marker: list[tuple[str, list[str]]] = []  # malformed TEMPO markers (P4)
    seen_paths: set[str] = set()
    hash_cache: dict[Path, str] = {}

    for rec in records:
        # Genuinely gridless tracks (no markers AND none malformed) are simply not in the
        # DJ's beat grid — skip quietly. A track WITH malformed markers is handled below,
        # but only once we know it resolves on disk (an off-disk bad marker is harmless).
        if not rec["markers"] and not rec["marker_errors"]:
            skipped_no_grid += 1
            continue
        local_path, amb = resolve_path(rec["basename"], index, hash_cache)
        if amb:
            ambiguous.append((rec["basename"], amb))
            continue
        if local_path is None:
            skipped_unresolved += 1
            continue
        # Resolved + gridded: any malformed marker now hard-fails (operator principle —
        # no quiet fixes) rather than feeding a partial/mislabeled grid.
        if rec["marker_errors"]:
            invalid_marker.append((rec["basename"], rec["marker_errors"]))
            continue
        # One oracle entry per PHYSICAL audio file. Two Rekordbox tracks can share a
        # basename (different TrackIDs -> same on-disk file); the benchmark analyzes
        # each file once, so a duplicate path would break DD-17 coverage-parity. Keep
        # the first (deterministic XML order); `track_id` stays the unique join key.
        if local_path in seen_paths:
            collapsed_dup_path += 1
            continue
        seen_paths.add(local_path)
        # A genuinely MISSING TotalTime leaves the forward grid unbounded past the last
        # marker (a single-marker track then collapses to [0, inizio]); the back-fill still
        # yields >=1 beat, so the zero-beat gate below would NOT catch it. Refuse rather than
        # guess a span. A PRESENT TotalTime that merely sits a few tenths below the last
        # marker (whole-second rounding vs a marker placed at the very end) is benign — the
        # marker IS the track end and the markers already define the full grid — so only a
        # `None` TotalTime hard-fails.
        max_inizio = max(m["inizio"] for m in rec["markers"])
        if rec["total_time"] is None:
            invalid_duration.append((rec["basename"], rec["total_time"], max_inizio))
            continue
        beats = beats_from_markers(rec["markers"], rec["total_time"])
        if not beats:
            # A gridded, on-disk-resolved track that yields no beats is a generator
            # bug or corrupt grid — hard-fail rather than feed a partial oracle.
            failed.append(rec["basename"])
            continue
        entries.append(jams_entry(rec, local_path, beats, curator))
        if args.limit and len(entries) >= args.limit:
            break

    # Any refusal bucket is FATAL: a partial/mislabeled oracle silently biases the
    # F-measure floor (DD-10/DD-17; operator principle — no quiet fixes/guesses).
    if ambiguous or invalid_duration or invalid_marker or failed:
        print(
            "error: oracle generation refused — unresolved data-integrity issues:", file=sys.stderr
        )
        if ambiguous:
            print(
                f"  {len(ambiguous)} basename collision(s) with DIFFERENT content "
                f"(ambiguous — cannot tell which file the grid belongs to):",
                file=sys.stderr,
            )
            for b, paths in ambiguous[:20]:
                print(f"    - {b}", file=sys.stderr)
                for pth in paths:
                    print(f"        {pth}", file=sys.stderr)
        if invalid_duration:
            print(
                f"  {len(invalid_duration)} track(s) with MISSING TotalTime "
                f"(unbounded forward grid — a single-marker track would truncate to [0, inizio]):",
                file=sys.stderr,
            )
            for b, tt, mi in invalid_duration[:20]:
                print(f"    - {b} (TotalTime={tt}, last marker inizio={mi:.3f})", file=sys.stderr)
        if invalid_marker:
            print(
                f"  {len(invalid_marker)} track(s) with malformed TEMPO markers:", file=sys.stderr
            )
            for b, errs in invalid_marker[:20]:
                print(f"    - {b}: {'; '.join(errs)}", file=sys.stderr)
        if failed:
            print(
                f"  {len(failed)} gridded+resolved track(s) produced zero beats:", file=sys.stderr
            )
            for b in failed[:20]:
                print(f"    - {b}", file=sys.stderr)
        return 1

    corpus = {
        "corpus": CORPUS_TAG,
        "xml_source": str(xml_path),
        "audio_root": str(audio_root),
        "track_count": len(entries),
        "entries": entries,
    }
    json.dump(corpus, sys.stdout, indent=2, ensure_ascii=False)
    print()

    total_beats = sum(len(e["annotations"][0]["data"]) for e in entries)
    print(
        f"# emitted {len(entries)} tracks, {total_beats} beats "
        f"({skipped_no_grid} no-grid, {skipped_unresolved} unresolved, "
        f"{collapsed_dup_path} duplicate-path collapsed, skipped)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
