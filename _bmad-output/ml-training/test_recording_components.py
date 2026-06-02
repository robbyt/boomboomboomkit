"""Regression tests for dataset._recording_components (Story 7.1 split grouping).

Guards the title-union anchor bug found in PR #24 review: when a normalized-title
group's first track (corpus order) is an empty-artist copy, the named same-title
copy must STILL union into the same component (so same-recording variants cannot
cross train/val/leaveArtistOut). Run:

    uv run --project _bmad-output/ml-training pytest \\
        _bmad-output/ml-training/test_recording_components.py
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

import dataset  # noqa: E402  (sibling module on the inserted path)


def _track(track_id: str, artist: str, name: str) -> dict:
    return {"track_id": track_id, "artist": artist, "name": name}


def _component_of(comps: dict, track_id: str) -> frozenset:
    for members in comps.values():
        ids = {str(t["track_id"]) for t in members}
        if track_id in ids:
            return frozenset(ids)
    raise AssertionError(f"{track_id} not in any component")


def test_empty_artist_first_still_unions_to_named_same_title():
    # group[0] is the empty-artist copy; the named copy must merge in (the bug:
    # an empty anchor left the named copy in a separate component).
    tracks = [
        _track("t1", "", "Artist A - Losing U"),  # empty artist, title-in-name
        _track("t2", "Artist A", "Artist A - Losing U"),  # named, same normalized title
    ]
    comps = dataset._recording_components(tracks)
    assert _component_of(comps, "t1") == _component_of(comps, "t2")
    assert len(comps) == 1


def test_named_first_empty_second_also_merges():
    tracks = [
        _track("t2", "Artist A", "Artist A - Losing U"),
        _track("t1", "", "Artist A - Losing U"),
    ]
    comps = dataset._recording_components(tracks)
    assert _component_of(comps, "t1") == _component_of(comps, "t2")


def test_different_named_artists_same_generic_title_not_merged():
    # The over-merge guard: two unrelated named artists sharing a generic title
    # must stay in SEPARATE components (no named<->named title union).
    tracks = [
        _track("x", "Artist X", "Intro"),
        _track("y", "Artist Y", "Intro"),
    ]
    comps = dataset._recording_components(tracks)
    assert _component_of(comps, "x") != _component_of(comps, "y")
    assert len(comps) == 2


def test_all_empty_same_title_collapse_together():
    tracks = [
        _track("e1", "", "Band B - Track"),
        _track("e2", "", "Band B - Track"),
    ]
    comps = dataset._recording_components(tracks)
    assert _component_of(comps, "e1") == _component_of(comps, "e2")
    assert len(comps) == 1
