"""Tests for the Story 12.7 eval-corpus construction harness (develop-only).

Pure-logic coverage of the signed section-2 protocol rules: half-open banding
at every edge, tag-less + FR-59a.2 exclusion accounting, draw determinism,
first-43-cumulative membership (surplus + duplicate tie-break by sequence
position), DSP-free keep/reject with out-of-band tempo retention, the
two-directional octave-sentinel windows, the privacy gate, and commitment
digest mismatch detection. Every write goes into pytest `tmp_path`.

Run: `make scripts-tests`.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
_SRC = REPO_ROOT / "scripts" / "build-eval-corpus.py"


def _load():
    spec = importlib.util.spec_from_file_location("build_eval_corpus", _SRC)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


bec = _load()


# --- banding ----------------------------------------------------------------


@pytest.mark.parametrize(
    ("bpm", "expected"),
    [
        (99.99, "sub-100"),
        (100.0, "100-120"),
        (119.99, "100-120"),
        (120.0, "120-140"),
        (139.99, "120-140"),
        (140.0, "140-160"),
        (159.99, "140-160"),
        (160.0, "160-175"),
        (174.99, "160-175"),
        (175.0, "175-plus"),
        (500.0, "175-plus"),
        (0.0, None),
        (-3.0, None),
        (None, None),
        (float("nan"), None),
        (float("inf"), None),
    ],
)
def test_band_edges_half_open(bpm, expected):
    assert bec.band_of(bpm) == expected


# --- candidate construction + exclusions ------------------------------------


def _pool_row(h, bpm, path="x"):
    return {"audioHash": h, "fileMetadataBPM": bpm, "path": f"{path}.mp3"}


def _tony_row(tid, bpm, artist="", name="t", local="/a/b.wav"):
    return {
        "track_id": tid,
        "average_bpm": bpm,
        "artist": artist,
        "name": name,
        "local_path": local,
    }


def test_tagless_rows_excluded_and_counted():
    bands, acc = bec.build_candidates(
        [_pool_row("h1", None), _pool_row("h2", 105.0)],
        [_tony_row("t1", 0)],
        [{"filename": "f", "bpm": None, "title": "f"}],
        set(),
        set(),
        set(),
    )
    assert acc["tagless"] == {"pool": 1, "tony": 1, "oa300": 1}
    assert len(bands["100-120"]) == 1


def test_fr59a2_exclusion_accounting():
    bands, acc = bec.build_candidates(
        [_pool_row("trainhash", 105.0), _pool_row("clean", 105.0)],
        [
            _tony_row("split-id", 105.0),
            _tony_row("t2", 105.0, artist="Dillinja"),
            _tony_row("t3", 105.0, artist="Fresh"),
            _tony_row("t4", 105.0, local=None),
        ],
        [],
        {"trainhash"},
        {"split-id"},
        {bec.cc.canonical_artist_key("Dillinja")},
    )
    e = acc["exclusions"]["100-120"]
    assert e == {"manifest-hash": 1, "tony-split": 1, "artist": 1, "audio-unresolved": 1}
    assert {r["identity"] for r in bands["100-120"]} == {"clean", "t3"}


# --- draw determinism -------------------------------------------------------


def test_draw_sequence_deterministic():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(20)]
    a = bec.draw_sequence(1, rows, seed=12345)
    b = bec.draw_sequence(1, rows, seed=12345)
    c = bec.draw_sequence(1, rows, seed=54321)
    assert [r["rowId"] for r in a] == [r["rowId"] for r in b]
    assert [r["identity"] for r in a] == [r["identity"] for r in b]
    assert [r["identity"] for r in a] != [r["identity"] for r in c]
    assert all(r["rowId"].startswith("e1-") for r in a)
    assert a[7]["rowId"].split("-")[1] == "0007"


# --- keep/reject ------------------------------------------------------------


def test_keep_reject_criteria():
    keep, reason = bec.keep_or_reject({"verified_bpm": 165.0}, "160-175")
    assert keep and reason is None
    keep, reason = bec.keep_or_reject({"verified_bpm": 175.0}, "160-175")
    assert not keep and reason == "out-of-band"
    keep, reason = bec.keep_or_reject({"verified_bpm": 165.0, "tempo_unstable": True}, "160-175")
    assert not keep and reason == "tempo-unstable"
    keep, reason = bec.keep_or_reject({"verified_bpm": 165.0, "irresolvable": True}, "160-175")
    assert not keep and reason == "metrically-irresolvable"
    keep, reason = bec.keep_or_reject({}, "160-175")
    assert not keep and reason == "no-verified-tempo"


def test_out_of_band_reject_retains_verified_tempo():
    seq = bec.draw_sequence(0, [{"source": "pool", "identity": "h0"}], seed=1)
    rid = seq[0]["rowId"]
    m = bec.compute_membership(seq, {rid: {"verified_bpm": 150.25}}, "sub-100")
    assert m["members"] == []
    assert m["rejects"][rid] == {"reason": "out-of-band", "verified_bpm": 150.25}


# --- membership: first-43-cumulative, surplus, duplicate tie-break ----------


def test_first_43_cumulative_membership_and_surplus():
    rows = [{"source": "pool", "identity": f"h{i:03d}"} for i in range(60)]
    seq = bec.draw_sequence(2, rows, seed=7)
    # Annotate in a scrambled work order across two "batches"; every row keeps
    # except every fifth row in sequence order, which rejects tempo-unstable.
    annotations = {}
    for i, entry in enumerate(reversed(seq)):
        pos = entry["sequencePosition"]
        if pos % 5 == 0:
            annotations[entry["rowId"]] = {"tempo_unstable": True}
        else:
            annotations[entry["rowId"]] = {"verified_bpm": 125.0}
        del i
    m = bec.compute_membership(seq, annotations, "120-140")
    expected_keepers = [e["rowId"] for e in seq if e["sequencePosition"] % 5 != 0]
    assert m["members"] == expected_keepers[:43]
    assert m["surplus"] == expected_keepers[43:]
    # Membership is independent of annotation work order and batch boundaries:
    # annotating only a prefix yields a prefix of the same membership.
    partial = {e["rowId"]: annotations[e["rowId"]] for e in seq[:30]}
    m2 = bec.compute_membership(seq, partial, "120-140")
    assert m2["members"] == [r for r in expected_keepers if r in partial][:43]
    assert m["members"][: len(m2["members"])] == m2["members"]


def test_duplicate_tie_break_earlier_sequence_position_kept():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(4)]
    seq = bec.draw_sequence(3, rows, seed=9)
    first, second = seq[0]["rowId"], seq[2]["rowId"]
    annotations = {
        e["rowId"]: {
            "verified_bpm": 145.0,
            "duplicate_of": "grp" if e["rowId"] in (first, second) else "",
        }
        for e in seq
    }
    m = bec.compute_membership(seq, annotations, "140-160")
    assert first in m["members"]
    assert m["rejects"][second]["reason"] == "duplicate"


def test_keep_or_reject_non_numeric_stored_bpm_is_harness_error():
    with pytest.raises(bec.HarnessError, match="non-numeric"):
        bec.keep_or_reject({"verified_bpm": "fast"}, "160-175")


def test_duplicate_rejected_when_earlier_row_carries_the_tag():
    # The EARLIER row points at the later one; the later keeper is rejected
    # regardless of which side carries the tag.
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(3)]
    seq = bec.draw_sequence(5, rows, seed=11)
    first, later = seq[0]["rowId"], seq[2]["rowId"]
    annotations = {
        first: {"verified_bpm": 145.0, "duplicate_of": later},
        seq[1]["rowId"]: {"verified_bpm": 145.0},
        later: {"verified_bpm": 145.0},
    }
    m = bec.compute_membership(seq, annotations, "140-160")
    assert first in m["members"]
    assert m["rejects"][later]["reason"] == "duplicate"


def test_duplicate_rejected_when_tag_names_earlier_row_id():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(3)]
    seq = bec.draw_sequence(6, rows, seed=13)
    first, later = seq[0]["rowId"], seq[2]["rowId"]
    annotations = {
        first: {"verified_bpm": 145.0},
        later: {"verified_bpm": 145.0, "duplicate_of": first},
    }
    m = bec.compute_membership(seq, annotations, "140-160")
    assert first in m["members"]
    assert m["rejects"][later]["reason"] == "duplicate"


def test_duplicate_registration_includes_rejected_rows():
    # The earlier tagged row is itself rejected for another reason; its dup
    # registration must still knock out the later keeper.
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(2)]
    seq = bec.draw_sequence(7, rows, seed=17)
    first, later = seq[0]["rowId"], seq[1]["rowId"]
    annotations = {
        first: {"tempo_unstable": True, "duplicate_of": "grp"},
        later: {"verified_bpm": 145.0, "duplicate_of": "grp"},
    }
    m = bec.compute_membership(seq, annotations, "140-160")
    assert m["members"] == []
    assert m["rejects"][first]["reason"] == "tempo-unstable"
    assert m["rejects"][later]["reason"] == "duplicate"


def test_duplicate_same_identity_rejected():
    rows = [
        {"source": "pool", "identity": "same"},
        {"source": "pool", "identity": "same"},
    ]
    seq = bec.draw_sequence(4, rows, seed=2)
    annotations = {e["rowId"]: {"verified_bpm": 170.0} for e in seq}
    m = bec.compute_membership(seq, annotations, "160-175")
    assert len(m["members"]) == 1
    assert list(m["rejects"].values())[0]["reason"] == "duplicate"


# --- sentinel rule ----------------------------------------------------------


@pytest.mark.parametrize(
    ("verified", "legacy", "expected"),
    [
        (160.0, [80.0], True),  # 160 in, 80 in
        (174.99, [87.49], True),
        (175.0, [80.0], False),  # 175 out of the full window
        (160.0, [87.5], False),  # 87.5 out of the half window
        (160.0, [79.99], False),
        (159.99, [80.0], False),  # verified below the full window
        (80.0, [160.0], True),  # reverse direction
        (87.49, [174.99], True),
        (87.5, [160.0], False),
        (80.0, [175.0], False),
        (80.0, [159.99], False),
        (120.0, [60.0], False),
        (165.0, [], False),
    ],
)
def test_octave_sentinel_two_directional_boundaries(verified, legacy, expected):
    assert bec.is_octave_sentinel(verified, legacy) is expected


# --- privacy gate -----------------------------------------------------------


def _clean_commitment():
    return {
        "bands": {"sub-100": {"candidates": 12, "seed": 123456}},
        "pool_file_sha256": "a" * 64,
        "draw_file_sha256": "b" * 64,
        "note": "counts and seeds only",
    }


def test_privacy_gate_accepts_clean_commitment():
    bec.privacy_gate(_clean_commitment())


def test_privacy_gate_rejects_smuggled_path():
    doc = _clean_commitment()
    doc["oops"] = "Users/rterhaar/secret"
    with pytest.raises(bec.PrivacyError):
        bec.privacy_gate(doc)


def test_privacy_gate_rejects_audio_filename():
    doc = _clean_commitment()
    doc["oops"] = "some track.mp3"
    with pytest.raises(bec.PrivacyError):
        bec.privacy_gate(doc)


def test_privacy_gate_rejects_stray_hash():
    doc = _clean_commitment()
    doc["oops"] = "c" * 64
    with pytest.raises(bec.PrivacyError):
        bec.privacy_gate(doc)


def test_privacy_gate_rejects_malformed_digest():
    doc = _clean_commitment()
    doc["pool_file_sha256"] = "not-a-digest"
    with pytest.raises(bec.PrivacyError):
        bec.privacy_gate(doc)


def test_privacy_gate_rejects_path_root_at_any_length():
    doc = _clean_commitment()
    doc["oops"] = (
        "a long prose sentence well beyond the sixty character label limit that "
        "still mentions Users/rterhaar and therefore must be rejected"
    )
    with pytest.raises(bec.PrivacyError, match="path root"):
        bec.privacy_gate(doc)


def test_privacy_gate_allows_long_prose_with_bare_slash():
    doc = _clean_commitment()
    doc["note"] = (
        "a long prose sentence well beyond the sixty character limit with a "
        "harmless either/or slash construction that stays permitted"
    )
    bec.privacy_gate(doc)


def test_privacy_gate_rejects_mid_string_audio_extension():
    doc = _clean_commitment()
    doc["oops"] = "backup copy named track.mp3.bak was kept"
    with pytest.raises(bec.PrivacyError, match="audio extension"):
        bec.privacy_gate(doc)


# --- commitment digest mismatch ---------------------------------------------


def _digest_fixture(tmp_path):
    pools = tmp_path / "candidate-pools.json"
    pools.write_text(json.dumps({"bands": {}}), encoding="utf-8")
    draws = tmp_path / "draw-sequences.json"
    draws.write_text(json.dumps({"bands": {}, "x": 1}), encoding="utf-8")
    commitment = tmp_path / "commitment.json"
    commitment.write_text(
        json.dumps(
            {
                "pool_file_sha256": bec.sha256_file(pools),
                "draw_file_sha256": bec.sha256_file(draws),
            }
        ),
        encoding="utf-8",
    )
    return pools, draws, commitment


def test_commitment_digest_mismatch_detected(tmp_path):
    pools, draws, commitment = _digest_fixture(tmp_path)
    assert bec.verify_committed_digest(pools, draws, commitment)["pool_file_sha256"]
    pools.write_text(json.dumps({"bands": {"tampered": []}}), encoding="utf-8")
    with pytest.raises(bec.HarnessError, match="digest mismatch"):
        bec.verify_committed_digest(pools, draws, commitment)


def test_commitment_verifies_both_digests_and_missing_file(tmp_path):
    pools, draws, commitment = _digest_fixture(tmp_path)
    draws.write_text(json.dumps({"tampered": True}), encoding="utf-8")
    with pytest.raises(bec.HarnessError, match="draw_file_sha256"):
        bec.verify_committed_digest(pools, draws, commitment)
    draws.unlink()
    with pytest.raises(bec.HarnessError, match="missing"):
        bec.verify_committed_digest(pools, draws, commitment)
    # A commitment missing a recorded digest is schema drift, not KeyError.
    commitment.write_text(json.dumps({"pool_file_sha256": bec.sha256_file(pools)}))
    with pytest.raises(bec.HarnessError, match="draw_file_sha256"):
        bec.verify_committed_digest(pools, draws, commitment)


# --- annotation CSV validation ----------------------------------------------

CSV_HEADER = "row_id,verified_bpm,tempo_unstable,irresolvable,ambiguous,audio_defect,duplicate_of"


def _write_csv(tmp_path, lines, header=CSV_HEADER):
    p = tmp_path / "annotations.csv"
    p.write_text("\n".join([header, *lines]) + "\n", encoding="utf-8")
    return p


def test_annotation_csv_happy_path(tmp_path):
    p = _write_csv(tmp_path, ["r1,165.005,0,0,1,0,", "r2,,1,0,0,0,"])
    parsed = bec.parse_annotations_csv(p, ["r1", "r2"])
    assert parsed["r1"]["verified_bpm"] == 165.0  # two-decimal record
    assert parsed["r1"]["ambiguous"] is True
    assert parsed["r2"]["tempo_unstable"] is True


def test_annotation_csv_rejects_unknown_column(tmp_path):
    p = _write_csv(tmp_path, ["r1,165,0,0,0,0,,0.9"], header=CSV_HEADER + ",dsp_confidence")
    with pytest.raises(bec.HarnessError, match="unknown columns.*dsp_confidence"):
        bec.parse_annotations_csv(p, ["r1"])


def test_annotation_csv_rejects_missing_column(tmp_path):
    header = CSV_HEADER.replace(",duplicate_of", "")
    p = _write_csv(tmp_path, ["r1,165,0,0,0,0"], header=header)
    with pytest.raises(bec.HarnessError, match="missing columns.*duplicate_of"):
        bec.parse_annotations_csv(p, ["r1"])


def test_annotation_csv_rejects_non_finite_bpm(tmp_path):
    p = _write_csv(tmp_path, ["r1,inf,0,0,0,0,"])
    with pytest.raises(bec.HarnessError, match="non-finite"):
        bec.parse_annotations_csv(p, ["r1"])
    p = _write_csv(tmp_path, ["r1,nan,0,0,0,0,"])
    with pytest.raises(bec.HarnessError, match="non-finite"):
        bec.parse_annotations_csv(p, ["r1"])
