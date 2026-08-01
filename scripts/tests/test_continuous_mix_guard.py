"""Tests for the continuous-mix corpus guard (develop-only).

An assertion that has never failed is not known to work. The audit check these
cover shipped with three holes -- a missing manifest read as success, a missing
duration sidecar as a warning, and a missing collection key as an empty clean
manifest -- so every failure path here exists because the un-tested version got
it wrong.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
ML_TRAINING_DIR = REPO_ROOT / "_bmad-output" / "ml-training"
sys.path.insert(0, str(ML_TRAINING_DIR))

import corpus_common as cc  # noqa: E402


def _load_audit():
    """The audit is a hyphenated script, so it needs loading by path."""
    path = REPO_ROOT / "scripts" / "audit-corpus-splits.py"
    spec = importlib.util.spec_from_file_location("audit_corpus_splits", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


audit = _load_audit()


def _check(tmp_path: Path, payload, durations, key="unsupervisedPool", write=True):
    res = audit.AuditResult()
    manifest = tmp_path / "manifest.json"
    if write:
        manifest.write_text(json.dumps(payload))
    audit._check_manifest_mixes(manifest, key, durations, res)
    return res


CLEAN = (
    {"unsupervisedPool": [{"relPath": "a/track.mp3", "audioHash": "h1"}]},
    {"a/track.mp3": 300.0},
)


def test_clean_manifest_passes(tmp_path):
    res = _check(tmp_path, *CLEAN)
    assert not res.failures


@pytest.mark.parametrize(
    "name,payload,durations,write",
    [
        (
            "directory rule",
            {"unsupervisedPool": [{"relPath": "Drum and Bass/Mixes/x.mp3", "audioHash": "h"}]},
            {"Drum and Bass/Mixes/x.mp3": 300.0},
            True,
        ),
        (
            "duration rule, filed outside Mixes/",
            {"unsupervisedPool": [{"relPath": "a/essential-mix.mp3", "audioHash": "h"}]},
            {"a/essential-mix.mp3": 3600.0},
            True,
        ),
        ("missing manifest", {}, {}, False),
        ("missing collection key", {"wrongKey": []}, {}, True),
        ("row with no relPath", {"unsupervisedPool": [{"audioHash": "h"}]}, {}, True),
        (
            "duplicate relPath",
            {
                "unsupervisedPool": [
                    {"relPath": "a.mp3", "audioHash": "h1"},
                    {"relPath": "a.mp3", "audioHash": "h2"},
                ]
            },
            {"a.mp3": 300.0},
            True,
        ),
        (
            "path with no duration entry",
            {"unsupervisedPool": [{"relPath": "a.mp3", "audioHash": "h"}]},
            {},
            True,
        ),
    ],
)
def test_guard_fails_closed(tmp_path, name, payload, durations, write):
    res = _check(tmp_path, payload, durations, write=write)
    assert res.failures, f"{name} should fail the audit but did not"


@pytest.mark.parametrize(
    "path,seconds,expected",
    [
        ("Drum and Bass/Mixes/a.mp3", 300.0, True),  # directory, short
        ("Mixes/a.mp3", None, True),  # directory, duration unknown
        ("a/mixes/b.mp3", 300.0, True),  # case-insensitive
        ("a/long-set.mp3", 3600.0, True),  # duration only
        ("Drum and Bass/Remixes/x.mp3", 300.0, False),  # must not match Remixes
        ("a/mixed/b.mp3", 300.0, False),  # must not match a substring
        ("a/b.mp3", cc.CONTINUOUS_MIX_MIN_SECONDS, False),  # exactly at threshold
        ("a/b.mp3", cc.CONTINUOUS_MIX_MIN_SECONDS + 1, True),  # one second over
        ("Drum and Bass/Goldie - Timeless.wav", 1260.0, False),  # named exemption
        ("Drum and Bass/GOLDIE - TIMELESS.mp3", 1260.0, False),  # exemption is case-blind
        (None, 3600.0, False),
        ("", 3600.0, False),
    ],
)
def test_predicate(path, seconds, expected):
    assert cc.is_continuous_mix(path, seconds) is expected


def test_emitter_and_audit_share_one_predicate():
    """The builder used to inline a copy with three hand-mirrored constants."""
    import corpus_manifests as cm

    builder = (ML_TRAINING_DIR / "ablation" / "build_unsupervised_manifest.py").read_text()
    assert "corpus_manifests" in builder, "builder must delegate, not re-implement"
    for leaked in ("mixes(/|$)", "15 * 60", "goldie"):
        assert leaked not in builder.lower(), f"builder still mirrors {leaked!r}"
    assert cm.MIX_POLICY_VERSION
