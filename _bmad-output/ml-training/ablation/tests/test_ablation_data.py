"""Tony split-join (AC8) + unsupervised-manifest builder (AC9) assertions.

Integration tests against the develop-local corpus; SKIP when the corpus is
absent (gitignored). No audio decode — these exercise the metadata join only.
"""

from __future__ import annotations

import json
import os
import sys

import pytest

_ABLATION = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_ML = os.path.dirname(_ABLATION)
sys.path.insert(0, _ML)
sys.path.insert(0, _ABLATION)

import ablation_locator as loc  # noqa: E402

_CORPUS_AVAILABLE = loc.CORPUS_SPLITS.exists() and (loc.cc.TONY_TRUTH_LABELS).exists()
pytestmark = pytest.mark.skipif(not _CORPUS_AVAILABLE, reason="Tony corpus develop-local/absent")


# Post-ingest counts (190 hand-labeled tracks added to the Strong tier, Epic 7):
# train 820 -> 890 -> 959, val 92 -> 101 -> 108, leaveArtistOut 104 -> 115 -> 139.
@pytest.mark.parametrize("which,expected", [("train", 959), ("val", 108), ("leaveArtistOut", 139)])
def test_split_counts_reconcile(which, expected):
    records = loc.build_labeled_records(which)
    assert len(records) == expected


def test_leave_artist_out_ids_are_dict_accessor():
    # AC8 — tony.leaveArtistOut is a dict; ids at .heldOutTrackIds (not a flat list).
    splits = loc._load_corpus_splits()
    assert isinstance(splits["tony"]["leaveArtistOut"], dict)
    assert isinstance(splits["tony"]["train"], list)
    ids = loc._split_ids(splits, "leaveArtistOut")
    assert len(ids) == 139


def test_join_is_string_keyed():
    recs = loc.build_labeled_records("val")
    assert all(isinstance(r.track_id, str) for r in recs)
    assert all(r.bpm > 0 for r in recs)


def test_records_carry_only_path_and_bpm():
    # AC7 data-boundary: a LabeledRecord exposes audio_path (locator) + bpm (label)
    # + track_id (bookkeeping) — never signals/artist/album/playlist.
    r = loc.build_labeled_records("val")[0]
    fields = set(r.__dataclass_fields__.keys())
    assert fields == {"track_id", "audio_path", "bpm"}


def test_random_split_cardinality_and_determinism():
    # DD #6 run B — cardinality matched to run A (820/104), deterministic, disjoint.
    t1, h1, sha1 = loc.build_random_split_records()
    t2, h2, sha2 = loc.build_random_split_records()
    assert len(h1) == 104
    assert len(t1) == 820
    assert sha1 == sha2 and len(sha1) == 64
    train_ids = {r.track_id for r in t1}
    held_ids = {r.track_id for r in h1}
    assert not (train_ids & held_ids)  # disjoint


def test_unsupervised_manifest_is_fr15_clean():
    # AC9 — the committed manifest carries ONLY {audioHash, relPath}.
    if not loc.UNSUPERVISED_MANIFEST.exists():
        pytest.skip("unsupervised manifest not built yet (run make ablation-unsupervised-manifest)")
    data = json.loads(loc.UNSUPERVISED_MANIFEST.read_text())
    rows = data["unsupervisedPool"]
    assert rows, "manifest is empty"
    forbidden = {"dspBPM", "dspConfidence", "fileMetadataBPM", "tier", "path", "bpm_truth"}
    for row in rows:
        assert set(row.keys()) == {"audioHash", "relPath"}
        assert not (forbidden & set(row.keys()))
