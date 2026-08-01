"""Derive the committed, FR-15-clean unsupervised-pretrain manifest (AC9 / DD #3).

Story 7.3. Develop-only v1 scaffolding. Stdlib-only (ty-eligible, ruff-clean).

Story 7.2 committed only the `secondarySupervised` manifest; the `unsupervisedPool`
rows live only in the gitignored `non-rekordbox-survey.json`. This builder reads
that (regenerable) survey, selects `tier == unsupervisedPool`, RENAMES the survey's
`path` key -> `relPath` (the survey field is `path`, already relative to
TONY_AUDIO_ROOT; the 7.2 manifest contract uses `relPath`), and DROPS every
forbidden column the survey rows carry (`dspBPM`/`dspConfidence`/`fileMetadataBPM`
are FR-15-forbidden — `signals.dsp` + ID3/container BPM). The output carries ONLY
`{audioHash, relPath}` — NO labels (masked-mel is self-supervised), NO forbidden
feature signals. The `audioHash = file_sha256` derivation is pinned in the header
(matching the 7.2 secondary manifest contract) so a future edit cannot silently
change the join key.

Run: `make ablation-unsupervised-manifest` (or
`uv run --project _bmad-output/ml-training python ablation/build_unsupervised_manifest.py`).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ML_TRAINING_DIR = Path(__file__).resolve().parents[1]
SURVEY = ML_TRAINING_DIR / "non-rekordbox-survey.json"
OUT = ML_TRAINING_DIR / "non-rekordbox-unsupervised-pretrain-manifest.json"

# The survey rows carry these; NONE may reach the manifest (FR-15).
FORBIDDEN_SURVEY_COLUMNS = ("dspBPM", "dspConfidence", "fileMetadataBPM", "tier")


def main() -> int:
    if not SURVEY.exists():
        print(
            f"ERROR: {SURVEY} not found (gitignored, regenerable). "
            f"Run `make non-rekordbox-survey` first.",
            file=sys.stderr,
        )
        return 1

    data = json.loads(SURVEY.read_text())
    rows = data["tracks"] if isinstance(data, dict) and "tracks" in data else data
    if not isinstance(rows, list):
        print(f"ERROR: {SURVEY} has no tracks list.", file=sys.stderr)
        return 1

    # A DJ mix is a continuous recording spanning many tempos, so it is invalid
    # even as label-free pretraining material: it teaches the model that tempo is
    # unstable within a file. Mirrors `corpus_common.is_continuous_mix`, inlined
    # because this builder is deliberately stdlib-only and import-free (it is the
    # one ablation script inside the py-lint ty scope). Operator directive
    # 2026-08-01; 238 such rows were in the previously committed manifest.
    mix_dir = re.compile(r"(^|/)mixes(/|$)", re.IGNORECASE)

    out_rows = []
    excluded_mixes = 0
    for r in rows:
        if r.get("tier") != "unsupervisedPool":
            continue
        if mix_dir.search(str(r.get("path") or "")):
            excluded_mixes += 1
            continue
        audio_hash = r.get("audioHash")
        rel_path = r.get("path")  # survey field is `path`; rename -> relPath (AC9)
        if not audio_hash or not rel_path:
            print(
                f"ERROR: unsupervisedPool row missing audioHash/path: {r.get('audioHash')}",
                file=sys.stderr,
            )
            return 1
        out_rows.append({"audioHash": audio_hash, "relPath": rel_path})

    # Defensive: assert no forbidden column survived into the output rows.
    for row in out_rows:
        leaked = [c for c in FORBIDDEN_SURVEY_COLUMNS if c in row]
        if leaked:
            print(f"ERROR: forbidden column(s) leaked into manifest: {leaked}", file=sys.stderr)
            return 1

    payload = {
        "schema_version": 1,
        "audioHash_derivation": "corpus_common.file_sha256 (raw audio bytes) — pinned join key",
        "note": (
            "Story 7.3 masked-mel pretraining corpus (label-free). Built from the "
            "tier==unsupervisedPool rows of non-rekordbox-survey.json by renaming `path`"
            "->`relPath` and dropping forbidden columns (dspBPM/dspConfidence/"
            "fileMetadataBPM). Use relPath ONLY to fetch bytes (never as a feature); "
            "NO labels (self-supervised)."
        ),
        "unsupervisedPool": out_rows,
    }
    OUT.write_text(json.dumps(payload, indent=2, sort_keys=True, allow_nan=False) + "\n")
    print(
        f"Wrote {OUT} ({len(out_rows)} unsupervisedPool rows, FR-15-clean: "
        f"audioHash + relPath; excluded {excluded_mixes} continuous-mix rows)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
