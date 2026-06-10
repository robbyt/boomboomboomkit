#!/usr/bin/env python3
"""Ingest hand-labeled BPMs from a Bitwig/DAWproject into the Tony corpus.

Epic 7 data-augmentation (develop-only). The v2 training failed the bundle gates
because the Tony corpus is drum&bass-only (almost nothing below 120 BPM, the band
the GiantSteps gate concentrates in). The operator hand-labeled diverse tracks by
warping them to the grid in a .dawproject; this script parses those warp BPMs
(reusing scripts/dawproject-bpm.py) and appends them to tony-truth-labels.json as
maximally-trusted Strong-tier records.

Hand-labeled records: truth_confidence 1.0 (-> Strong tier), a single
`manual_hand_label` source cluster, all noisy signals `missing`, qa_flags empty.

Idempotent: existing manual_hand_label records are stripped and re-derived on
every run. track_id is STABLE across re-runs — an existing record keeps its id
(matched by audio basename), and only genuinely-new basenames get fresh ids
allocated above the current max. This means re-running with the SAME .dawproject
is a no-op, and ADDING tracks never renumbers the existing ones (so the ids that
corpus_splits.json already references keep pointing at the same audio).

CAVEAT: adding/removing tracks still changes the trainable set, so you MUST
re-run `make ml-splits` + `make corpus-diagnostics` + `make audit-corpus-splits`
after any ingest that changes the record set — the splits are not auto-updated
here. A clean-slate run (no prior manual records) allocates ids contiguously from
--id-base in sorted-basename order.

Run: uv run scripts/ingest-dawproject-labels.py
  [--dawproject PATH] [--samples DIR] [--labels PATH] [--id-base 900000001]
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DAWPROJECT_PARSER = REPO_ROOT / "scripts" / "dawproject-bpm.py"
DEFAULT_DAWPROJECT = Path(
    "/Users/rterhaar/Dropbox/tony-tunes/other-bpms/other-bpms/other-bpms.dawproject"
)
DEFAULT_SAMPLES = Path("/Users/rterhaar/Dropbox/tony-tunes/other-bpms/other-bpms/samples")
DEFAULT_LABELS = (
    REPO_ROOT / "_bmad-output" / "ml-training" / "tony-corpus" / "tony-truth-labels.json"
)
HAND_LABEL_SOURCE = "manual_hand_label"
# Round to a clean whole number when the warp BPM is within this of an integer
# (modern dance music is whole-number BPM); keep the precise value otherwise
# (older / genuinely-fractional tracks).
INTEGER_SNAP_TOL = 0.3


def parse_dawproject(dawproject: Path) -> list[dict]:
    """Parse the .dawproject via the existing dawproject-bpm.py --json path."""
    out = subprocess.run(
        ["uv", "run", "python", str(DAWPROJECT_PARSER), str(dawproject), "--json"],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)


def _clean_bpm(bpm: float) -> float:
    snapped = round(bpm)
    return float(snapped) if abs(bpm - snapped) <= INTEGER_SNAP_TOL else round(float(bpm), 2)


def _missing_signals() -> dict:
    return {
        "rekordbox_average": {"bpm": None, "relation": "missing"},
        "grid_bpm": {"bpm": None, "tempo_count": 0, "relation": "missing"},
        "dsp": {"bpm": None, "confidence": None, "relation": "missing"},
        "playlist": {"names": [], "priors_used": [], "relation": "missing"},
    }


def build_records(
    clips: list[dict],
    samples: Path,
    id_base: int,
    existing_id_by_base: dict[str, str] | None = None,
) -> list[dict]:
    # Dedup by audio basename (a clip can appear more than once), deterministic order.
    by_base: dict[str, dict] = {}
    for clip in clips:
        base = os.path.basename(clip.get("file", ""))
        if not base:
            continue
        by_base.setdefault(base, clip)  # first wins

    # Stable id allocation: reuse an existing record's id for a known basename;
    # allocate new ids strictly above the current max so adding tracks never
    # renumbers the ones corpus_splits.json already references.
    existing_id_by_base = existing_id_by_base or {}
    used_ids = {int(v) for v in existing_id_by_base.values()}
    next_id = max([id_base - 1, *used_ids]) + 1

    records: list[dict] = []
    missing: list[str] = []
    for base in sorted(by_base):
        clip = by_base[base]
        path = samples / base
        if not path.exists():
            missing.append(base)
            continue
        bpm = clip.get("bpm")
        if bpm is None or bpm <= 0:
            missing.append(f"{base} (no bpm)")
            continue
        if base in existing_id_by_base:
            track_id = existing_id_by_base[base]
        else:
            track_id = str(next_id)
            next_id += 1
        clean = _clean_bpm(float(bpm))
        records.append(
            {
                "track_id": track_id,
                "artist": "",
                "name": clip.get("track") or Path(base).stem,
                "album": "",
                "local_path": str(path),
                "bpm_truth": clean,
                "truth_confidence": 1.0,
                "truth_cluster": {
                    "centroid": clean,
                    "total_weight": 1.0,
                    "member_count": 1,
                    "sources": [HAND_LABEL_SOURCE],
                },
                "runner_up_cluster": None,
                "signals": _missing_signals(),
                "qa_flags": [],
            }
        )
    if missing:
        print(f"WARN: {len(missing)} clip(s) skipped (no audio / no bpm):", file=sys.stderr)
        for m in missing[:10]:
            print(f"  - {m}", file=sys.stderr)
    return records


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--dawproject", type=Path, default=DEFAULT_DAWPROJECT)
    p.add_argument("--samples", type=Path, default=DEFAULT_SAMPLES)
    p.add_argument("--labels", type=Path, default=DEFAULT_LABELS)
    p.add_argument("--id-base", type=int, default=900000001)
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    clips = parse_dawproject(args.dawproject)

    data = json.loads(args.labels.read_text())
    tracks = data["tracks"]
    # Idempotent: drop any prior hand-label records, then append the fresh set.
    # Carry the prior manual ids forward by basename so re-runs don't renumber.
    prior_manual = [
        t for t in tracks if HAND_LABEL_SOURCE in (t.get("truth_cluster") or {}).get("sources", [])
    ]
    existing_id_by_base = {
        os.path.basename(t.get("local_path", "")): t["track_id"]
        for t in prior_manual
        if t.get("local_path")
    }
    new_records = build_records(clips, args.samples, args.id_base, existing_id_by_base)
    if not new_records:
        raise SystemExit("No ingestable hand-labeled records produced — check paths.")

    kept = [
        t
        for t in tracks
        if HAND_LABEL_SOURCE not in (t.get("truth_cluster") or {}).get("sources", [])
    ]
    dropped = len(prior_manual)
    merged = kept + new_records
    # Fail loudly rather than write a corpus with colliding ids (would silently
    # break the corpus_splits.json id->audio mapping).
    ids = [t["track_id"] for t in merged]
    if len(ids) != len(set(ids)):
        dupes = sorted({i for i in ids if ids.count(i) > 1})
        raise SystemExit(f"Refusing to write — duplicate track_id(s): {dupes}")
    data["tracks"] = merged
    data["track_count"] = len(merged)
    # Atomic write (temp + os.replace) so an interrupted run can't truncate the
    # canonical labels file.
    tmp = args.labels.with_suffix(args.labels.suffix + f".tmp{os.getpid()}")
    tmp.write_text(json.dumps(data, indent=2) + "\n")
    os.replace(tmp, args.labels)

    # Tempo-band summary so the operator sees the coverage that was added.
    bands = {"<100": 0, "100-120": 0, "120-140": 0, "140-160": 0, "160-175": 0, "175+": 0}
    for r in new_records:
        b = r["bpm_truth"]
        key = (
            "<100"
            if b < 100
            else "100-120"
            if b < 120
            else "120-140"
            if b < 140
            else "140-160"
            if b < 160
            else "160-175"
            if b < 175
            else "175+"
        )
        bands[key] += 1
    print(
        f"ingest: dropped {dropped} prior hand-labels, added {len(new_records)} -> "
        f"track_count {data['track_count']}"
    )
    print("added by band: " + "  ".join(f"{k}={v}" for k, v in bands.items()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
