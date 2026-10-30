"""Story 15.5: fixed-time ML input ablation harness (develop-only).

The tempo model normally reads each analysis window resized to 512 columns, so
its seconds per column changes from track to track. This package trains and
scores one variant that reads fixed 1200-frame (12 s) crops at the native
0.01 s per frame instead, using only each song's most rhythmic crops (ranked by
the library's DSP rhythm score), and writes paired per-track rows against the
legacy model and the tempo-CNN reference. Nothing here ships, and nothing here changes the
legacy input contract (`featureSetVersion` stays "v2" for the legacy arm).

Run the entry points as modules from `_bmad-output/ml-training/`:
  uv run python -m fixed_time.train_fixed_time --preflight
  uv run python -m fixed_time.plan
  uv run python -m fixed_time.train_fixed_time
  uv run python -m fixed_time.score
  uv run python -m fixed_time.report
"""

from __future__ import annotations

import os
import sys

# The sibling training modules import each other by bare name (`import dataset`,
# `import ablation_common`). Put both directories on sys.path once, here, so the
# entry points and spawned DataLoader workers resolve them the same way.
_ML_TRAINING_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for _p in (os.path.join(_ML_TRAINING_DIR, "ablation"), _ML_TRAINING_DIR):
    if _p not in sys.path:
        sys.path.insert(0, _p)
