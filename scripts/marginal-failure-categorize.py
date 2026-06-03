#!/usr/bin/env python3
"""
Story 7.4 — Marginal-tier failure-categorization CLI (develop-only).

Thin wrapper: re-derives the 241 Marginal-tier tracks via
`corpus_common.tier_for`, categorizes each (use-a), and writes two artifacts:

  - `marginal-failure-categorization.json` — 241 records (use-a, AC1),
  - `marginal-watchlist.json`              — 241 typed rows (use-c, AC4/AC7).

All logic lives in the importable sibling module
`_bmad-output/ml-training/marginal_failure_categorize.py` (a hyphenated path is
not importable; the module is its underscore twin — DD #3 / DD #14). This CLI
only resolves the corpus, calls the builders, and writes deterministically.

Run: `make marginal-failure-categorize`
 (or `uv run --project _bmad-output/ml-training python scripts/marginal-failure-categorize.py`).
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402  (runtime sys.path insert above)
import marginal_failure_categorize as mfc  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    tracks, _prov = cc.load_tony_corpus()

    cat_payload = mfc.build_categorization_payload(tracks)
    watch_payload = mfc.build_watchlist_payload(tracks)

    mfc.write_json_artifact(cat_payload, mfc.CATEGORIZATION_JSON)
    mfc.write_json_artifact(watch_payload, mfc.WATCHLIST_JSON)

    counts = mfc.category_counts(cat_payload["records"])
    print(f"Wrote {mfc.CATEGORIZATION_JSON.name} + {mfc.WATCHLIST_JSON.name}")
    print(f"  marginal tracks: {cat_payload['marginalTierCount']}")
    print(f"  per-category: {dict(counts)}")
    print(f"  harmonic-ratio candidates (AC9): {mfc.harmonic_candidate_count(tracks)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
