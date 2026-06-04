"""Shared pytest path setup for the ablation test suite (Story 7.4 DD #14).

ONE place does the `sys.path.insert` so `import corpus_common` /
`import marginal_failure_categorize` / `import ablation_*` resolve. conftest.py
is auto-loaded by pytest before collecting any test module in this directory, so
new test files do NOT need their own insert (the pre-7.4 files keep theirs —
harmless / idempotent).
"""

from __future__ import annotations

import os
import sys

_TESTS = os.path.dirname(os.path.abspath(__file__))
_ABLATION = os.path.dirname(_TESTS)
_ML = os.path.dirname(_ABLATION)

for _p in (_ML, _ABLATION):
    if _p not in sys.path:
        sys.path.insert(0, _p)
