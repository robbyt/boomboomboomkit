"""Lazy-dataset decode-failure handling (Story 7.3 cycle-3 / Codex 2026-06-02).

Locks the fix that converted recursive skip-and-shift to a BOUNDED loop: an
all-undecodable corpus must raise the clear `RuntimeError` (check TONY_AUDIO_ROOT)
rather than blowing Python's recursion limit with a `RecursionError`. Corpus-free
(uses bogus paths), so it runs anywhere.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

_ABLATION = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_ML = os.path.dirname(_ABLATION)
sys.path.insert(0, _ML)
sys.path.insert(0, _ABLATION)

import ablation_locator as loc  # noqa: E402


def test_labeled_all_decode_fail_raises_runtimeerror_not_recursion():
    # Far more bogus records than Python's recursion limit would tolerate if this
    # were still recursive (~1000); the bounded loop probes n and loud-fails.
    n = 1500
    records = [
        loc.LabeledRecord(track_id=str(i), audio_path=Path(f"/nonexistent/{i}.mp3"), bpm=120.0)
        for i in range(n)
    ]
    dset = loc.LabeledTonyDataset(
        records, fixture=None, augment=False, seed=42, weighting_profile="uniform"
    )
    with pytest.raises(RuntimeError, match="failed to decode"):
        dset[0]


def test_unlabeled_all_decode_fail_raises_runtimeerror_not_recursion():
    n = 1500
    paths = [Path(f"/nonexistent/{i}.mp3") for i in range(n)]
    dset = loc.UnlabeledPretrainDataset(paths, fixture=None, seed=42, weighting_profile="uniform")
    with pytest.raises(RuntimeError, match="failed to decode"):
        dset[0]
