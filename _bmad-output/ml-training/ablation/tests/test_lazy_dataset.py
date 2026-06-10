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

import numpy as np
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


# --- strict-mode eval contract (Copilot PR #26): no skip-and-shift on the eval/report
# path, so val/LAO accuracy can never be silently skewed by a double-counted track. -----


def test_strict_decode_failure_raises_not_substitutes(monkeypatch):
    # Everything fails to decode; strict must loud-fail on the FIRST (requested) idx
    # with a "strict eval" message — never probe other indices, never substitute.
    monkeypatch.setattr(loc, "_load_pcm", lambda _p: None)
    records = [loc.LabeledRecord(track_id="t0", audio_path=Path("/nonexistent/0.mp3"), bpm=120.0)]
    dset = loc.LabeledTonyDataset(
        records, fixture=None, augment=False, seed=42, weighting_profile="uniform", strict=True
    )
    with pytest.raises(RuntimeError, match="strict eval"):
        dset[0]


def test_strict_vs_nonstrict_on_mixed_records(monkeypatch):
    # idx 0 is undecodable, idx 1 decodes fine. This is the exact regression Copilot
    # flagged: non-strict shifts dset[0] onto record 1 (double-counting it), while strict
    # must raise. Mock both _load_pcm and feats.transform so no real audio/fixture is needed.
    def fake_load(path):
        return None if path.name == "0.mp3" else np.zeros(16000, dtype=np.float32)

    monkeypatch.setattr(loc, "_load_pcm", fake_load)
    monkeypatch.setattr(
        loc.feats,
        "transform",
        lambda audio, sr, bpm, fixture, *, augment, rng, weighting_profile: ("FEATS", bpm),
    )
    records = [
        loc.LabeledRecord(track_id="t0", audio_path=Path("/nonexistent/0.mp3"), bpm=120.0),
        loc.LabeledRecord(track_id="t1", audio_path=Path("/nonexistent/1.mp3"), bpm=140.0),
    ]

    nonstrict = loc.LabeledTonyDataset(
        records, fixture=None, augment=False, seed=42, weighting_profile="uniform"
    )
    # dset[0] silently shifts to record 1 (bpm 140) — the substitution Copilot warned about.
    assert nonstrict[0] == ("FEATS", 140.0)

    strict = loc.LabeledTonyDataset(
        records, fixture=None, augment=False, seed=42, weighting_profile="uniform", strict=True
    )
    with pytest.raises(RuntimeError, match="strict eval"):
        strict[0]
