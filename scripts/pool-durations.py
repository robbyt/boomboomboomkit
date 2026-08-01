#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""
Emit `pool-durations.json` — track durations for the non-Rekordbox pool
(develop-only).

Why a sidecar rather than a survey field: `non-rekordbox-survey.py` decodes the
whole pool and takes hours; duration is a container-header read and takes
seconds. Regenerating the survey to add one cheap field would be absurd, so the
durations live beside it and join on the survey's `path`.

The output carries corpus-relative paths, which the committed pretrain manifest
already does, so this is no new exposure. It never leaves develop.

Duration is what separates a DJ mix from a track when the directory name does
not: measured 2026-08-01 over 4,753 pool files, `Mixes/` rows have a median of
27.2 min against 5.4 for everything else, and real tracks reach only 8.4 min at
p99. See `corpus_common.is_continuous_mix`.

Run: `make pool-durations`
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from mutagen import File as MutagenFile

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
SURVEY = ML_TRAINING_DIR / "non-rekordbox-survey.json"
OUT = ML_TRAINING_DIR / "pool-durations.json"


def main() -> int:
    if not SURVEY.exists():
        print(
            f"ERROR: {SURVEY} not found (gitignored, develop-only). "
            "Run `make non-rekordbox-survey` first.",
            file=sys.stderr,
        )
        return 2
    data = json.loads(SURVEY.read_text())
    root = Path(data["audio_root"])

    rows, missing, unreadable = [], 0, 0
    for track in data["tracks"]:
        rel = track.get("path")
        if not rel:
            continue
        full = root / rel
        if not full.exists():
            missing += 1
            continue
        try:
            info = getattr(MutagenFile(str(full)), "info", None)
            seconds = getattr(info, "length", None)
        except Exception:  # noqa: BLE001 - any decoder complaint means unusable
            seconds = None
        if not isinstance(seconds, (int, float)) or seconds <= 0:
            unreadable += 1
            continue
        rows.append({"relPath": rel, "seconds": round(float(seconds), 2)})

    rows.sort(key=lambda r: r["relPath"])
    payload = {
        "schema_version": 1,
        "note": (
            "Container-header durations for the non-Rekordbox pool, joined to "
            "non-rekordbox-survey.json on `path`. Used only to identify "
            "continuous DJ mixes; never a training feature."
        ),
        "count": len(rows),
        "unreadable": unreadable,
        "missing": missing,
        "rows": rows,
    }
    OUT.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    print(f"Wrote {OUT} ({len(rows)} rows; {unreadable} unreadable, {missing} missing)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
