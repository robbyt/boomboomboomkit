#!/usr/bin/env python3
"""
Rebuild `non-rekordbox-unsupervised-pretrain-manifest.json` (develop-only).

Story 7.2 committed only the `secondarySupervised` manifest; the
`unsupervisedPool` rows live only in the gitignored `non-rekordbox-survey.json`.

Emission logic lives in `corpus_manifests`, NOT here. An earlier version inlined
the continuous-mix predicate with three hand-mirrored constants (regex, threshold,
exemption), justified by a "stdlib-only, outside the import graph" claim that was
false: `ablation_common.py` and `scripts/audit-corpus-splits.py` both import
`corpus_common` this way, and the latter is in the py-lint ty enumeration too.
The mirror was also asymmetric -- the audit asserts the absence of mixes but never
the presence of non-mixes, so a tightened copy here would over-exclude silently.

Run: `make ablation-unsupervised-manifest`
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Running this file by path does not put its grandparent on sys.path.
ML_TRAINING_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_manifests as cm  # noqa: E402  (runtime sys.path insert above)


def main() -> int:
    paths = cm.default_paths(ML_TRAINING_DIR)
    if not paths["survey"].exists():
        print(
            f"ERROR: {paths['survey'].name} not found. Run `make non-rekordbox-survey` first.",
            file=sys.stderr,
        )
        return 2
    raw = paths["survey"].read_bytes()
    survey = json.loads(raw.decode("utf-8"))
    try:
        durations, sidecar_sha = cm.load_durations(paths["durations"])
        payload, dropped = cm.emit_unsupervised(
            survey["tracks"], durations, cm.sha256_bytes(raw), sidecar_sha
        )
    except cm.ManifestError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 3
    paths["unsupervised"].write_text(cm.serialize(payload) + "\n", encoding="utf-8")
    print(
        f"Wrote {paths['unsupervised']} — tiered "
        f"{payload['derivation']['tieredRowCount']} unsupervisedPool rows, "
        f"training-eligible {len(payload['unsupervisedPool'])} "
        f"({dropped} continuous mixes excluded)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
