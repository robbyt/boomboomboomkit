#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""
Emit `pool-durations.json` — track durations for the non-Rekordbox pool
(develop-only).

Why a sidecar rather than a survey field: `non-rekordbox-survey.py` decodes the
whole pool and takes hours; duration is a container-header read and takes
seconds. It stamps `sourceSurveySha256` so a consumer can refuse a sidecar built
from a different survey snapshot than the manifests it feeds.

**Disclosure, stated plainly.** This commits 4,753 corpus-relative paths, of
which several hundred appear in no other tracked artifact. Corpus-relative paths
are an accepted disclosure in this repository -- two training manifests already
carry thousands of them. That acceptance is a decision, not a claim that
filenames are harmless. What keeps the survey itself uncommittable is broader: a
complete collection inventory plus absolute filesystem roots, per-file BPM
signals, audio hashes, and skipped/sentinel-review records.

Duration is what separates a DJ mix from a track when the directory name does
not: measured 2026-08-01 over 4,753 pool files, `Mixes/` rows have a median of
27.2 min against 5.4 for everything else, and real tracks reach only 8.4 at p99.
See `corpus_common.is_continuous_mix`.

Run: `make pool-durations`  (then `make repair-mix-manifests` -- order matters,
the manifests record this file's SHA).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_manifests as cm  # noqa: E402  (runtime sys.path insert above)


def main() -> int:
    paths = cm.default_paths(ML_TRAINING_DIR)
    survey_path = paths["survey"]
    if not survey_path.exists():
        print(
            f"ERROR: {survey_path.name} not found (gitignored, develop-only). "
            "Run `make non-rekordbox-survey` first.",
            file=sys.stderr,
        )
        return 2
    raw = survey_path.read_bytes()
    survey = json.loads(raw.decode("utf-8"))
    rows, unreadable, missing = cm.build_duration_rows(survey, Path(survey["audio_root"]))
    payload = cm.durations_payload(rows, unreadable, missing, cm.sha256_bytes(raw))
    paths["durations"].write_text(cm.serialize(payload) + "\n", encoding="utf-8")
    print(
        f"Wrote {paths['durations']} ({len(rows)} rows; {unreadable} unreadable, {missing} missing)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
