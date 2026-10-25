#!/usr/bin/env python3
"""Freeze the private Story 12.9 paired gate cohort from signed 12.7 evidence.

The signed 12.7 JAMS supplies member labels. The DAW is consulted only for
additional blinded e1-e5 rows; it never replaces a signed member label.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
HARNESS_PATH = ROOT / "scripts" / "build-eval-corpus.py"
DEFAULT_OUT = ROOT / "_bmad-output/ml-training/eval-corpus/bundle-gate"
E_ROW = re.compile(r"^e[1-5]-[0-9a-f]+$")


def harness():
    spec = importlib.util.spec_from_file_location("eval_corpus_harness", HARNESS_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load 12.7 harness")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def canonical_digest(doc: dict) -> str:
    payload = json.dumps(doc, sort_keys=True, separators=(",", ":"), allow_nan=False)
    return hashlib.sha256(payload.encode()).hexdigest()


def valid_bpm(value: object) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError("verified tempo is not numeric")
    bpm = float(value)
    if not math.isfinite(bpm) or bpm <= 0:
        raise ValueError("verified tempo must be finite and positive")
    return bpm


def verify_daw_audio(
    archive: zipfile.ZipFile,
    references: dict[str, set[str]],
    rid: str,
    source: Path,
    digest: str,
) -> None:
    """A DAW tempo applies only to the committed audio for that opaque ID."""
    expected = f"audio/{rid}{source.suffix}"
    if references.get(rid) != {expected} or PurePosixPath(expected).stem != rid:
        raise ValueError(f"DAW audio reference differs from committed source for {rid}")
    try:
        with archive.open(expected) as audio:
            hasher = hashlib.sha256()
            for chunk in iter(lambda: audio.read(1024 * 1024), b""):
                hasher.update(chunk)
    except KeyError as exc:
        raise ValueError(f"DAW audio missing for {rid}") from exc
    if hasher.hexdigest() != digest:
        raise ValueError(f"DAW audio differs from committed source for {rid}")


def validated_state(module):
    """Use 12.7's full commitment/pool/draw/ledger audit before reading rows."""
    commitment, commitment_sha = module.require_active_commitment()
    generation = str(commitment["generation"])
    pools = json.loads(module.pools_path(generation).read_text())
    events = module.read_events(module.ledger_path(generation))
    state = module.HarnessState(commitment, commitment_sha, generation, pools, events)
    module.require_valid_state(state, "before freezing the 12.9 cohort")
    return state


def make_cohort(
    module,
    state,
    membership: dict,
    signed: dict,
    tracks: dict,
    archive: zipfile.ZipFile,
    references: dict[str, set[str]],
) -> dict:
    """Pure selection except for verifying each source audio's committed hash."""
    members = {rid for band in module.BAND_NAMES for rid in membership[band]["members"]}
    signed_rows = {}
    for row in signed["entries"]:
        signed_rows[row["file_metadata"]["identifiers"]["row_id"]] = row
    if len(signed_rows) != len(signed["entries"]) or set(signed_rows) != members:
        raise ValueError("signed JAMS and 12.7 membership disagree")
    by_id = state.by_row_id
    if not members <= by_id.keys():
        raise ValueError("signed member absent from committed candidate pool")
    annotations = {
        rid: ann
        for band in module.BAND_NAMES
        for rid, ann in module.load_annotations(state, band).items()
    }
    selected: list[dict] = []
    excluded: Counter[str] = Counter()
    seen_hash: dict[str, str] = {}
    for rid in sorted(members | {name for name in tracks if E_ROW.fullmatch(name)}):
        member = rid in members
        if rid not in by_id:
            raise ValueError(f"DAW e row {rid} absent from committed draw")
        entry = by_id[rid]
        if not member:
            track = tracks[rid]
            ann = annotations.get(rid)
            if ann is None:
                raise ValueError(f"DAW e row {rid} lacks a blinded annotation record")
            if track.problem or track.bpm is None:
                excluded["unresolved-daw-tempo"] += 1
                continue
            unsound_flags = ("audio_defect", "tempo_unstable", "irresolvable")
            if any(ann.get(flag) for flag in unsound_flags):
                excluded["unsound-annotation"] += 1
                continue
            if ann.get("duplicate_of"):
                excluded["declared-duplicate"] += 1
                continue
            bpm = valid_bpm(ann.get("verified_bpm"))
            if abs(bpm - track.bpm) > 0.01:
                raise ValueError(f"DAW and annotation disagree for {rid}")
        else:
            row = signed_rows[rid]
            bpm = valid_bpm(row["annotations"][0]["data"][0]["value"])
            annotation_bpm = valid_bpm(annotations[rid]["verified_bpm"])
            if abs(bpm - annotation_bpm) > 0.01:
                raise ValueError(f"signed JAMS and annotation disagree for {rid}")
        verified_band = module.band_of(bpm)
        if verified_band is None:
            raise ValueError(f"unbandable tempo for {rid}")
        path = module._resolve_audio(entry, state.pools.get("pool_audio_root"))
        if not path.is_file():
            raise ValueError(f"source audio missing for {rid}: {path}")
        actual_hash = module.sha256_file(path)
        committed_hash = entry.get("contentSha256")
        if not committed_hash or actual_hash != committed_hash:
            raise ValueError(f"audio hash missing or changed for {rid}")
        if not member:
            verify_daw_audio(archive, references, rid, path, actual_hash)
        if actual_hash in seen_hash:
            first = seen_hash[actual_hash]
            raise ValueError(f"unresolved duplicate audio: {first} and {rid}")
        seen_hash[actual_hash] = rid
        selected.append(
            {
                "trackId": rid,
                "audioPath": str(path.resolve()),
                "audioSha256": actual_hash,
                "groundTruthBPM": bpm,
                "source": entry["source"],
                "sourceBand": next(
                    b for b in module.BAND_NAMES if rid in state.sequence_row_ids(b)
                ),
                "verifiedBand": verified_band,
                "category": "locked-12.7-member" if member else "blinded-e-extra",
            }
        )
    if sum(r["category"] == "locked-12.7-member" for r in selected) != len(members):
        raise ValueError("signed member count changed")
    if not selected:
        raise ValueError("empty gate cohort")
    return {"tracks": selected, "exclusions": dict(sorted(excluded.items()))}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dawproject", required=True, type=Path)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    module = harness()
    state = validated_state(module)
    generation = state.generation
    gen_dir = module.generation_root(generation)
    commitment_sha = state.commitment_sha
    membership_path = module.membership_path(generation)
    signed_path = gen_dir / "258-corpus.jams.json"
    membership = json.loads(membership_path.read_text())
    signed = json.loads(signed_path.read_text())
    if module.recompute_membership(state) != membership:
        raise ValueError("12.7 membership is stale relative to the annotation ledger")
    clips = module.read_dawproject_clips(args.dawproject)
    tracks = module.project_tracks(clips)
    references: dict[str, set[str]] = {}
    for clip in clips:
        name = str(clip.get("track") or "")
        audio_file = str(clip.get("file") or "")
        references.setdefault(name, set()).add(audio_file)
    with zipfile.ZipFile(args.dawproject) as archive:
        result = make_cohort(
            module,
            state,
            membership,
            signed,
            tracks,
            archive,
            references,
        )
    rows = result["tracks"]
    bands = Counter(r["verifiedBand"] for r in rows)
    categories = Counter(r["category"] for r in rows)
    source = {
        "generation": generation,
        "commitmentSha256": commitment_sha,
        "membershipSha256": module.sha256_file(membership_path),
        "signedJamsSha256": module.sha256_file(signed_path),
        "dawprojectSha256": module.sha256_file(args.dawproject),
        "annotationLedgerSha256": module.sha256_file(module.ledger_path(generation)),
    }
    doc = {
        "schemaVersion": 1,
        "policy": "12.9-provisional-blinded-e1-e5-v1",
        "source": source,
        "count": len(rows),
        "categories": dict(sorted(categories.items())),
        "verifiedBands": {band: bands[band] for band in module.BAND_NAMES},
        "exclusions": result["exclusions"],
        "tracks": rows,
    }
    doc["cohortSha256"] = canonical_digest(doc)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    target = args.out_dir / f"cohort-{generation}.json"
    encoded = json.dumps(doc, indent=2, sort_keys=True, allow_nan=False) + "\n"
    if target.exists() and target.read_text() != encoded:
        raise ValueError(f"frozen cohort already exists with different bytes: {target}")
    if not target.exists():
        target.write_text(encoded)
    print(
        json.dumps(
            {
                "path": str(target),
                "count": len(rows),
                "bands": doc["verifiedBands"],
                "categories": doc["categories"],
                "digest": doc["cohortSha256"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, KeyError) as exc:
        print(f"bundle gate cohort refused: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
