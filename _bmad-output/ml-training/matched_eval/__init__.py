"""Story 15.9: evaluation harness (develop-only).

Scores the shipped pipeline, the Epic 15 variants, the commercial DJ analyzer
(named `commercial-analyzer` everywhere in this package) and an independent
reference on the same audio. Nine metric families are kept separate per
(track, system); every pair of systems gets paired signed differences with a
bootstrap 95 % interval of the median and a paired Wilcoxon p-value, overall
and per tempo band and style tag.

Modules:
  corpora  corpus manifests, references, the OA300 duplicate rule, hash checks
  metrics  the nine metric families for one (track, system)
  stats    bootstrap interval, Wilcoxon, strata
  report   per-track rows, pairings, the wording guard, the tracked aggregate
  run      the CLI `make matched-eval` drives

Run from `_bmad-output/ml-training/`:
  uv run python -m matched_eval.run all ...
Nothing here ships to main.
"""

from __future__ import annotations

import os
import sys

# The 15.5 package and the sibling training modules import each other by bare
# name; put the ml-training and ablation directories on sys.path once, here.
_ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for _p in (os.path.join(_ML_TRAINING_DIR, "ablation"), _ML_TRAINING_DIR):
    if _p not in sys.path:
        sys.path.insert(0, _p)
