"""Tests for the Story 12.7 eval-corpus construction harness (develop-only).

Two layers.

PURE LOGIC: the signed section-2 protocol rules - half-open banding at every
edge, tag-less + FR-59a.2 exclusion accounting, draw determinism,
first-43-cumulative membership (surplus + duplicate tie-break by sequence
position), DSP-free keep/reject with out-of-band tempo retention, the
two-directional octave-sentinel windows, the privacy gate and the commitment
key schema, and commitment digest mismatch detection.

COMMAND LEVEL: the real subcommands driven against a synthetic corpus, which
two spec ACs require ("run on synthetic annotations in tests", "Given a complete
corpus (test fixture)") and which nothing exercised before. Every write goes
into pytest `tmp_path`; the fingerprint function is injected so no test decodes
audio.

Run: `make scripts-tests`.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import re
from dataclasses import dataclass
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
_ORIGINAL_PATHS = (bec.EVAL_CORPUS_DIR, bec.ARTIFACTS_DIR)


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
    assert e["manifest-hash"] == 1
    assert e["tony-split"] == 1
    assert e["artist"] == 1
    assert e["audio-unresolved"] == 1
    assert set(e) == set(bec.EXCLUSION_REASONS)
    assert {r["identity"] for r in bands["100-120"]} == {"clean", "t3"}


def test_candidate_universe_digest_is_content_derived():
    a, _ = bec.build_candidates([_pool_row("h1", 105.0)], [], [], set(), set(), set())
    b, _ = bec.build_candidates([_pool_row("h1", 105.0)], [], [], set(), set(), set())
    c, _ = bec.build_candidates([_pool_row("h2", 105.0)], [], [], set(), set(), set())
    assert bec.candidate_universe_digest(a) == bec.candidate_universe_digest(b)
    assert bec.candidate_universe_digest(a) != bec.candidate_universe_digest(c)


# --- content binding + cross-band dedup (findings 3 and 12) -----------------


def test_bind_content_hashes_drops_unhashable_rows():
    bands = {name: [] for name in bec.BAND_NAMES}
    bands["100-120"] = [
        {"source": "pool", "identity": "ok"},
        {"source": "pool", "identity": "gone"},
    ]
    exclusions = bec._empty_exclusions()
    bound = bec.bind_content_hashes(
        bands,
        exclusions,
        lambda e: Path("/x") if e["identity"] == "ok" else None,
        lambda p: "d" * 64,
    )
    assert [r["identity"] for r in bound["100-120"]] == ["ok"]
    assert bound["100-120"][0]["contentSha256"] == "d" * 64
    assert exclusions["100-120"]["audio-unhashable"] == 1


def test_cross_band_dedup_keeps_the_priority_band():
    bands = {name: [] for name in bec.BAND_NAMES}
    bands["sub-100"] = [{"source": "pool", "identity": "half", "contentSha256": "a" * 64}]
    bands["160-175"] = [{"source": "pool", "identity": "full", "contentSha256": "a" * 64}]
    exclusions = bec._empty_exclusions()
    priority = ["160-175", "sub-100", "100-120", "120-140", "140-160", "175-plus"]
    out = bec.dedup_across_bands(bands, exclusions, priority, {})
    assert [r["identity"] for r in out["160-175"]] == ["full"]
    assert out["sub-100"] == []
    assert exclusions["sub-100"]["cross-band-duplicate"] == 1


def test_cross_band_dedup_rejects_a_non_permutation():
    with pytest.raises(bec.HarnessError, match="permutation"):
        bec.dedup_across_bands(
            {n: [] for n in bec.BAND_NAMES}, bec._empty_exclusions(), ["sub-100"], {}
        )


# --- draw determinism + position-independent row IDs (finding 16) -----------


def test_draw_sequence_deterministic():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(20)]
    a = bec.draw_sequence(1, rows, seed=12345)
    b = bec.draw_sequence(1, rows, seed=12345)
    c = bec.draw_sequence(1, rows, seed=54321)
    assert [r["rowId"] for r in a] == [r["rowId"] for r in b]
    assert [r["identity"] for r in a] == [r["identity"] for r in b]
    assert [r["identity"] for r in a] != [r["identity"] for r in c]
    assert all(r["rowId"].startswith("e1-") for r in a)
    assert len({r["rowId"] for r in a}) == len(a)


def test_row_ids_do_not_encode_draw_position():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(30)]
    seq = bec.draw_sequence(2, rows, seed=99)
    suffixes = [r["rowId"].split("-", 1)[1] for r in seq]
    # A position-encoding ID sorts into draw order; a random one does not.
    assert suffixes != sorted(suffixes)
    for entry in seq:
        assert re.fullmatch(r"e2-[0-9a-f]{12}", entry["rowId"])
        # The retired format embedded the zero-padded draw position.
        assert f"{entry['sequencePosition']:04d}" not in entry["rowId"]


def test_work_order_is_a_seeded_permutation():
    ids = [f"r{i:02d}" for i in range(20)]
    a = bec.work_order(ids, 7)
    b = bec.work_order(ids, 7)
    c = bec.work_order(ids, 8)
    assert a == b
    assert sorted(a) == sorted(ids)
    assert a != ids
    assert a != c


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
    for entry in reversed(seq):
        pos = entry["sequencePosition"]
        if pos % 5 == 0:
            annotations[entry["rowId"]] = {"tempo_unstable": True}
        else:
            annotations[entry["rowId"]] = {"verified_bpm": 125.0}
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


def test_duplicate_rejected_when_earlier_kept_row_carries_the_tag():
    # The EARLIER kept row points at the later one; the later keeper is rejected
    # regardless of which side carries the tag (bidirectional half of patch 17,
    # which survives the finding-11 narrowing).
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


def test_defect_rejected_row_does_not_suppress_a_clean_copy():
    # Finding 11: the signed criterion is "not a duplicate of a track already
    # KEPT". An earlier audio-defect rejection is a property of that FILE, so it
    # must not knock out a later clean copy of the same recording - the short
    # bands cannot afford that.
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(2)]
    seq = bec.draw_sequence(7, rows, seed=17)
    first, later = seq[0]["rowId"], seq[1]["rowId"]
    annotations = {
        first: {"audio_defect": True, "duplicate_of": "grp"},
        later: {"verified_bpm": 145.0, "duplicate_of": "grp"},
    }
    m = bec.compute_membership(seq, annotations, "140-160")
    assert m["members"] == [later]
    assert m["rejects"][first]["reason"] == "audio-defect"
    assert later not in m["rejects"]


def test_surplus_keeper_still_suppresses_a_later_duplicate():
    # The suppressing row need not be one of the final n; an eventual surplus
    # keeper registers too.
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(4)]
    seq = bec.draw_sequence(8, rows, seed=19)
    ids = [e["rowId"] for e in seq]
    annotations = {rid: {"verified_bpm": 145.0} for rid in ids}
    annotations[ids[1]]["duplicate_of"] = "grp"
    annotations[ids[3]]["duplicate_of"] = "grp"
    m = bec.compute_membership(seq, annotations, "140-160", n_band=1)
    assert m["members"] == [ids[0]]
    assert ids[1] in m["surplus"]
    assert m["rejects"][ids[3]]["reason"] == "duplicate"


def test_duplicate_same_identity_rejected():
    rows = [
        {"source": "pool", "identity": "same"},
        {"source": "pool", "identity": "same"},
    ]
    seq = bec.draw_sequence(4, rows, seed=2)
    annotations = {e["rowId"]: {"verified_bpm": 170.0} for e in seq}
    m = bec.compute_membership(seq, annotations, "160-175")
    assert len(m["members"]) == 1
    assert next(iter(m["rejects"].values()))["reason"] == "duplicate"


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


def test_default_fingerprint_memoizes_and_degrades(tmp_path, monkeypatch):
    calls = []

    def fake_compute(path):
        calls.append(path)
        return [1.0, 2.0] if path.endswith("good.mp3") else None

    monkeypatch.setattr(bec.cc, "compute_fingerprint", fake_compute)
    monkeypatch.setattr(bec, "_FP_MEMO", {})
    monkeypatch.setattr(bec, "_FP_DISK_CACHE", {})
    good = tmp_path / "good.mp3"
    good.write_bytes(b"x")
    bad = tmp_path / "bad.mp3"
    bad.write_bytes(b"x")
    assert bec._default_fingerprint(str(good)) == [1.0, 2.0]
    assert bec._default_fingerprint(str(good)) == [1.0, 2.0]
    assert bec._default_fingerprint(str(bad)) is None
    assert bec._default_fingerprint(str(bad)) is None
    assert calls == [str(good), str(bad)]  # each path decoded at most once


def test_cohort_standardization_undoes_a_common_offset():
    # The degeneracy corpus_common records: vectors dominated by a shared
    # offset all score near 1.0 raw. Standardizing across the cohort separates
    # them, which is what the audit precedent does before cosine.
    raw = [[100.0, 100.0, 1.0], [100.0, 100.0, 2.0], [100.0, 100.0, -3.0]]
    assert bec.cosine(raw[0], raw[2]) > 0.9
    stats = bec.cohort_stats(raw)
    z = [bec.standardize(v, stats) for v in raw]
    assert bec.cosine(z[0], z[2]) < 0.0


def test_cohort_standardization_skips_a_group_too_small_to_estimate_scale():
    raw = [[1.0, 0.0], [1.0, 0.0]]
    stats = bec.cohort_stats(raw)
    assert 2 not in stats  # centring a 2-member group would zero it out
    assert bec.standardize(raw[0], stats) == raw[0]


def test_cosine_helper():
    assert bec.cosine([1.0, 0.0], [1.0, 0.0]) == pytest.approx(1.0)
    assert bec.cosine([1.0, 0.0], [0.0, 1.0]) == pytest.approx(0.0)
    assert bec.cosine([0.0, 0.0], [1.0, 1.0]) == 0.0
    assert bec.cosine([1.0], [1.0, 2.0]) == 0.0


# --- privacy gate + commitment key schema -----------------------------------


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


def _schema_commitment():
    return {
        "schema_version": 2,
        "story": "12.7",
        "status": "active",
        "generated": "2026-08-10",
        "protocol": bec.PROTOCOL_POINTER,
        "run_command": "make eval-corpus-pools",
        "seed_algorithm": bec.SEED_ALGORITHM,
        "master_seed": 1,
        "n_band_target": 43,
        "bands": {
            name: {
                "candidates": 43,
                "seed": 2,
                "exclusions": dict.fromkeys(bec.EXCLUSION_REASONS, 0),
            }
            for name in bec.BAND_NAMES
        },
        "tagless_by_source": {"pool": 0, "tony": 0, "oa300": 0},
        "artist_exclusion_limitation": "note",
        "fingerprint_review": {
            "method": bec.FINGERPRINT_METHOD,
            "flags": 0,
            "confirmed_same_recording": 0,
            "cleared": 0,
            "dispositions_sha256": "1" * 64,
            "candidate_universe_sha256": "2" * 64,
            "training_input_sha256": "3" * 64,
        },
        "operator_decisions": {
            "decisions_sha256": "4" * 64,
            "decided": "2026-08-10",
            "short_band_allocation": "shrink-corpus",
            "cross_band_duplicate_rule": "audit-fails-on-cross-band-duplicate",
        },
        "pool_file_sha256": "5" * 64,
        "draw_file_sha256": "6" * 64,
        "short_bands": [],
        "notes": [],
    }


def test_commitment_key_schema_accepts_the_generated_shape():
    bec.gate_committed(_schema_commitment(), bec.assert_commitment_schema)


def test_commitment_key_schema_rejects_an_extra_key():
    doc = _schema_commitment()
    doc["track_title"] = "a harmless looking title"
    with pytest.raises(bec.PrivacyError, match="key-schema violation"):
        bec.assert_commitment_schema(doc)


def test_commitment_key_schema_rejects_a_missing_block():
    doc = _schema_commitment()
    del doc["fingerprint_review"]
    with pytest.raises(bec.PrivacyError, match="key-schema violation"):
        bec.assert_commitment_schema(doc)


def test_commitment_key_schema_rejects_an_unknown_status():
    doc = _schema_commitment()
    doc["status"] = "provisional"
    with pytest.raises(bec.PrivacyError, match="status"):
        bec.assert_commitment_schema(doc)


def test_committed_commitment_artifact_passes_its_own_gate():
    doc = json.loads(_ORIGINAL_PATHS[1].joinpath("12-7-candidate-commitment.json").read_text())
    assert doc["status"] == bec.STATUS_SUPERSEDED
    bec.gate_committed(doc, bec.assert_commitment_schema)


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


# ===========================================================================
# COMMAND LEVEL (finding 17): the real subcommands over a synthetic corpus.
# ===========================================================================

BAND_BPM = {
    "sub-100": 90.0,
    "100-120": 110.0,
    "120-140": 130.0,
    "140-160": 150.0,
    "160-175": 165.0,
    "175-plus": 180.0,
}
N_BAND_TEST = 2


@dataclass
class Workspace:
    root: Path
    state: Path
    artifacts: Path
    inputs: dict


def _write_audio(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


def _build_inputs(root: Path) -> dict:
    audio_root = root / "pool-audio"
    tony_root = root / "tony-audio"
    oa_root = root / "oa300"
    pool_rows: list[dict] = []
    tony_rows: list[dict] = []
    for bi, (_band, bpm) in enumerate(BAND_BPM.items()):
        for i in range(3):
            rel = f"pool-{bi}-{i}.mp3"
            _write_audio(audio_root / rel, f"pool audio {bi} {i} ".encode() * 8)
            pool_rows.append({"audioHash": f"ph-{bi}-{i}", "fileMetadataBPM": bpm, "path": rel})
        name = f"tony-{bi}"
        tpath = tony_root / f"{name}.wav"
        _write_audio(tpath, f"tony audio {bi} ".encode() * 8)
        tony_rows.append(
            {
                "track_id": f"t{bi}",
                "average_bpm": bpm,
                "artist": f"Artist {bi}",
                "name": name,
                "local_path": str(tpath),
                "basename": f"{name}.wav",
            }
        )
    _write_audio(oa_root / "corpus" / "oa-0.mp3", b"oa audio zero " * 8)
    oa300_rows = [{"filename": "oa-0.mp3", "bpm": 85.0, "title": "oa-zero", "subdir": None}]
    return {
        "pool_rows": pool_rows,
        "pool_audio_root": str(audio_root),
        "tony_rows": tony_rows,
        "oa300_rows": oa300_rows,
        "manifest_hashes": set(),
        "manifest_paths": {},
        "tony_split_ids": set(),
        "training_artist_keys": set(),
        "training_local_paths": {},
        "_oa300_root": str(oa_root),
    }


def _unique_fingerprint(path: str) -> list[float]:
    """A near-orthogonal 32-dim +/-1 signature per path.

    Not all-positive: an earlier all-positive stub scored cosine 0.97 between
    unrelated paths, which is the same degeneracy `corpus_common` records for
    raw timbral vectors and the reason the harness standardizes across the
    cohort before comparing.
    """
    digest = hashlib.sha256(path.encode()).digest()
    return [1.0 if (digest[i // 8] >> (i % 8)) & 1 else -1.0 for i in range(32)]


@pytest.fixture
def ws(tmp_path, monkeypatch):
    state = tmp_path / "eval-corpus"
    artifacts = tmp_path / "artifacts"
    state.mkdir()
    artifacts.mkdir()
    bec.configure_paths(state, artifacts)
    inputs = _build_inputs(tmp_path)
    monkeypatch.setenv("OA300_CORPUS_PATH", inputs["_oa300_root"])
    monkeypatch.setattr(bec, "load_inputs", lambda: inputs)
    monkeypatch.setattr(bec, "training_input_digest", lambda: "7" * 64)
    monkeypatch.setattr(bec, "_giantsteps_titles", lambda: set())
    monkeypatch.setattr(bec.cc, "resolve_giantsteps_gt_path", lambda: Path(__file__))
    monkeypatch.setattr(bec, "FINGERPRINT_FN", _unique_fingerprint)
    try:
        yield Workspace(root=tmp_path, state=state, artifacts=artifacts, inputs=inputs)
    finally:
        bec.configure_paths(*_ORIGINAL_PATHS)


def _write_decisions(cross="audit-fails-on-cross-band-duplicate", **extra):
    doc = {
        "schema_version": 1,
        "decided": "2026-08-10",
        "short_band_allocation": {"policy": "shrink-corpus", "n_band": N_BAND_TEST},
        "cross_band_duplicate_rule": {"policy": cross, **extra},
    }
    bec._write_json(bec.DECISIONS_PATH, doc)


def _write_dispositions(disposition=bec.DISPOSITION_NOT_SAME):
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    for row in template["flags"]:
        row["disposition"] = disposition
    bec._write_json(bec.DISPOSITIONS_PATH, template)


def _mint(seed=4242):
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions()
    _write_decisions()
    return bec.main(["commit-pools", "--seed", str(seed)])


def _annotate(band, batch, overrides=None):
    record = json.loads((bec.BATCHES_DIR / band / f"batch-{batch:03d}.json").read_text())
    path = bec.EVAL_CORPUS_DIR / f"ann-{band}-{batch}.csv"
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(CSV_HEADER.split(","))
        for rid in record["work_order"]:
            row = {
                "row_id": rid,
                "verified_bpm": BAND_BPM[band],
                "tempo_unstable": 0,
                "irresolvable": 0,
                "ambiguous": 0,
                "audio_defect": 0,
                "duplicate_of": "",
            }
            row.update((overrides or {}).get(rid, {}))
            writer.writerow([row[c] for c in CSV_HEADER.split(",")])
    return path


def _complete_band(band, size=6):
    assert bec.main(["stage-batch", "--band", band, "--size", str(size)]) == 0
    csv_path = _annotate(band, 0)
    assert bec.main(["ingest", "--band", band, "--batch", "0", "--annotations", str(csv_path)]) == 0


def _complete_corpus():
    for band in bec.BAND_NAMES:
        _complete_band(band)


# --- commit-pools + the two gates -------------------------------------------


def test_commit_pools_mints_an_active_commitment(ws):
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["status"] == bec.STATUS_ACTIVE
    assert doc["n_band_target"] == N_BAND_TEST
    assert doc["operator_decisions"]["short_band_allocation"] == "shrink-corpus"
    bec.gate_committed(doc, bec.assert_commitment_schema)
    assert bec.POOLS_PATH.exists() and bec.DRAWS_PATH.exists()
    assert bec.LEDGER_HEAD_JSON.exists()
    pools = json.loads(bec.POOLS_PATH.read_text())
    for name in bec.BAND_NAMES:
        for entry in pools["bands"][name]:
            assert len(entry["contentSha256"]) == 64  # finding 3: content-bound


def test_commit_pools_refuses_without_dispositions(ws):
    assert bec.main(["prepare-review"]) == 0
    _write_decisions()
    with pytest.raises(bec.OperatorHalt, match="MISSING FINGERPRINT DISPOSITIONS"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))


def test_commit_pools_refuses_without_operator_decisions(ws):
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions()
    with pytest.raises(bec.OperatorHalt) as exc:
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))
    assert "short-band allocation" in str(exc.value)
    assert "cross-band duplicate rule" in str(exc.value)


def test_commit_pools_refuses_unadjudicated_flags(ws):
    assert bec.main(["prepare-review"]) == 0
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    template["flags"].append({"flag_id": "deadbeef", "disposition": None})
    bec._write_json(bec.DISPOSITIONS_PATH, template)
    _write_decisions()
    with pytest.raises(bec.OperatorHalt, match="UNRESOLVED FINGERPRINT DISPOSITION"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))


def test_dispositions_bound_to_the_candidate_universe(ws):
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions()
    _write_decisions()
    doc = json.loads(bec.DISPOSITIONS_PATH.read_text())
    doc["candidate_universe_sha256"] = "0" * 64
    bec._write_json(bec.DISPOSITIONS_PATH, doc)
    with pytest.raises(bec.DriftError, match="candidate universe"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))


def test_prepare_review_flags_a_training_fingerprint_match(ws, monkeypatch, tmp_path):
    training = tmp_path / "training" / "leak.mp3"
    _write_audio(training, b"leaked audio " * 8)
    ws.inputs["training_local_paths"] = {"train-1": str(training)}
    target = Path(ws.inputs["pool_audio_root"]) / ws.inputs["pool_rows"][0]["path"]
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (str(training), str(target)) else _unique_fingerprint(p),
    )
    assert bec.main(["prepare-review"]) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    kinds = {f["kind"] for f in review["flags"]}
    assert bec.FLAG_KIND_FINGERPRINT in kinds
    # Confirming the flag excludes the candidate before commitment.
    _write_dispositions(bec.DISPOSITION_SAME)
    _write_decisions()
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=5)) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["fingerprint_review"]["confirmed_same_recording"] >= 1
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] >= 1


def test_cross_band_recording_flags_feed_the_dedup_policy(ws, monkeypatch):
    # A half-tempo and a full-tempo encode of one recording land in two bands by
    # construction; different bytes, so only a fingerprint pair sees it. The flag
    # excludes nothing on its own - it supplies the recording group that
    # `pre-commitment-recording-dedup` collapses on.
    root = Path(ws.inputs["pool_audio_root"])
    half = str(
        root / next(r["path"] for r in ws.inputs["pool_rows"] if r["fileMetadataBPM"] == 90.0)
    )
    full = str(
        root / next(r["path"] for r in ws.inputs["pool_rows"] if r["fileMetadataBPM"] == 165.0)
    )
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (half, full) else _unique_fingerprint(p),
    )
    assert bec.main(["prepare-review"]) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    cross = [f for f in review["flags"] if f["kind"] == bec.FLAG_KIND_CROSS_BAND]
    assert len(cross) == 1
    assert cross[0]["peer_key"]
    _write_dispositions(bec.DISPOSITION_SAME)
    _write_decisions(
        cross="pre-commitment-recording-dedup",
        band_priority=["160-175", *[b for b in bec.BAND_NAMES if b != "160-175"]],
    )
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=11)) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["cross-band-duplicate"] == 1
    assert doc["bands"]["160-175"]["exclusions"]["cross-band-duplicate"] == 0


def test_input_drift_on_an_existing_commitment_fails(ws):
    assert _mint() == 0
    # Edit a source AUDIO file. The candidate universe (source + identity +
    # band) is unchanged, so the disposition binding still matches; only
    # re-deriving the pool document from today's inputs catches this. Before the
    # rework this run printed "commitment verified".
    src = Path(ws.inputs["pool_audio_root"]) / ws.inputs["pool_rows"][0]["path"]
    src.write_bytes(b"a different master " * 9)
    with pytest.raises(bec.DriftError, match="INPUT DRIFT"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=None))


def test_a_new_candidate_row_invalidates_the_dispositions(ws):
    assert _mint() == 0
    ws.inputs["pool_rows"].append(
        {
            "audioHash": "new-row",
            "fileMetadataBPM": 150.0,
            "path": ws.inputs["pool_rows"][0]["path"],
        }
    )
    with pytest.raises(bec.DriftError, match="candidate universe"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=None))


def test_unchanged_inputs_verify(ws):
    assert _mint() == 0
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=None)) == 0


def test_tampered_row_level_pool_file_fails(ws):
    assert _mint() == 0
    bec.POOLS_PATH.write_text(json.dumps({"bands": {}}), encoding="utf-8")
    with pytest.raises(bec.DriftError, match="tampered"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=None))


# --- superseded enforcement -------------------------------------------------


def _supersede():
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["status"] = bec.STATUS_SUPERSEDED
    bec._write_json(bec.COMMITMENT_JSON, doc)


def test_commit_pools_halts_on_a_superseded_commitment(ws, capsys):
    assert _mint() == 0
    _supersede()
    bec.DISPOSITIONS_PATH.unlink()
    bec.DECISIONS_PATH.unlink()
    assert bec.main(["commit-pools"]) == 4
    err = capsys.readouterr().err
    assert "COMMITMENT SUPERSEDED" in err
    assert "MISSING fingerprint dispositions" in err
    assert "MISSING operator decisions" in err
    assert "short-band allocation" in err
    assert "cross-band duplicate rule" in err


def test_every_consumer_refuses_a_superseded_commitment(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    _supersede()
    csv_path = bec.EVAL_CORPUS_DIR / "ann-sub-100-0.csv"
    invocations = [
        ["stage-batch", "--band", "sub-100"],
        ["ingest", "--band", "sub-100", "--batch", "0", "--annotations", str(csv_path)],
        ["abandon", "--band", "sub-100", "--batch", "0"],
        ["status"],
        ["audit"],
        ["emit-manifest"],
        ["signoff"],
    ]
    for argv in invocations:
        capsys.readouterr()
        assert bec.main(argv) != 0, argv
        assert "NO ACTIVE COMMITMENT" in capsys.readouterr().err, argv


def test_audit_without_any_commitment_fails(ws, capsys):
    assert bec.main(["audit"]) == 1
    assert "NO ACTIVE COMMITMENT" in capsys.readouterr().err


# --- staging: content verification + batch validation -----------------------


def test_stage_batch_writes_a_blinded_randomized_worklist(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "6"]) == 0
    record = json.loads((bec.BATCHES_DIR / "sub-100" / "batch-000.json").read_text())
    assert record["work_order"] != record["rowIds"]
    with open(bec.BATCHES_DIR / "sub-100" / "batch-000-worklist.csv", encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    assert rows[0] == ["row_id", "audio"]
    assert [r[0] for r in rows[1:]] == record["work_order"]
    for _rid, audio in rows[1:]:
        assert Path(audio).exists()


def test_stage_batch_hard_fails_on_equal_size_substitution(ws):
    assert _mint() == 0
    pools = json.loads(bec.POOLS_PATH.read_text())
    entry = next(e for e in pools["bands"]["sub-100"] if e["source"] == "pool")
    src = Path(ws.inputs["pool_audio_root"]) / entry["relPath"]
    original = src.read_bytes()
    src.write_bytes(b"X" * len(original))  # same size, different content
    with pytest.raises(bec.HarnessError, match="CONTENT MISMATCH"):
        bec.cmd_stage_batch(bec.argparse.Namespace(band="sub-100", batch=None, size=6))


def test_tampered_batch_record_rejected_by_every_consumer(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    record_path = bec.BATCHES_DIR / "sub-100" / "batch-000.json"
    record = json.loads(record_path.read_text())
    record["rowIds"] = list(reversed(record["rowIds"]))
    bec._write_json(record_path, record)
    with pytest.raises(bec.HarnessError, match="not the committed draw-sequence slice"):
        bec.validate_batch_records(
            "sub-100",
            [e["rowId"] for e in json.loads(bec.POOLS_PATH.read_text())["bands"]["sub-100"]],
        )
    for argv in (
        ["stage-batch", "--band", "sub-100"],
        ["status"],
        ["audit"],
        ["emit-manifest"],
    ):
        capsys.readouterr()
        assert bec.main(argv) != 0, argv


def test_batch_record_start_tamper_rejected(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    record_path = bec.BATCHES_DIR / "sub-100" / "batch-000.json"
    record = json.loads(record_path.read_text())
    record["start"] = 2
    bec._write_json(record_path, record)
    with pytest.raises(bec.HarnessError, match="cumulative consecutive-span start"):
        bec.validate_batch_records(
            "sub-100",
            [e["rowId"] for e in json.loads(bec.POOLS_PATH.read_text())["bands"]["sub-100"]],
        )


def test_stage_batch_refuses_a_second_unanchored_batch(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    with pytest.raises(bec.HarnessError, match="not anchored in the annotation ledger"):
        bec.cmd_stage_batch(bec.argparse.Namespace(band="sub-100", batch=None, size=3))


# --- ingest + the annotation ledger -----------------------------------------


def test_ingest_computes_first_n_membership(ws):
    assert _mint() == 0
    _complete_band("sub-100")
    pools = json.loads(bec.POOLS_PATH.read_text())
    membership = bec._recompute_membership(pools, N_BAND_TEST)
    sequence = [e["rowId"] for e in pools["bands"]["sub-100"]]
    assert membership["sub-100"]["members"] == sequence[:N_BAND_TEST]
    assert len(membership["sub-100"]["surplus"]) >= 1
    head = json.loads(bec.LEDGER_HEAD_JSON.read_text())
    assert head["event_count"] == 1
    bec.gate_committed(head, bec.assert_ledger_head_schema)


def test_edited_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    ann_path = bec.ANNOTATIONS_DIR / "sub-100" / "batch-000.json"
    doc = json.loads(ann_path.read_text())
    first = next(iter(doc["rows"]))
    doc["rows"][first]["verified_bpm"] = 99.0
    bec._write_json(ann_path, doc)
    assert bec.main(["audit"]) == 1
    assert "does not match its ledger digest" in capsys.readouterr().err


def test_deleted_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    (bec.ANNOTATIONS_DIR / "sub-100" / "batch-000.json").unlink()
    assert bec.main(["audit"]) == 1
    assert "recorded in the ledger is missing" in capsys.readouterr().err


def test_added_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    src = bec.ANNOTATIONS_DIR / "sub-100" / "batch-000.json"
    dest = bec.ANNOTATIONS_DIR / "100-120" / "batch-000.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(src.read_bytes())
    assert bec.main(["audit"]) == 1
    assert "not referenced by any active ledger event" in capsys.readouterr().err


def test_stale_ledger_head_blocks_staging(ws):
    assert _mint() == 0
    _complete_band("sub-100")
    head = json.loads(bec.LEDGER_HEAD_JSON.read_text())
    head["head_sha256"] = "0" * 64
    bec._write_json(bec.LEDGER_HEAD_JSON, head)
    with pytest.raises(bec.HarnessError, match="stale"):
        bec.cmd_stage_batch(bec.argparse.Namespace(band="sub-100", batch=None, size=1))


def test_ledger_chain_break_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    lines = bec.LEDGER_PATH.read_bytes().splitlines()
    event = json.loads(lines[0])
    event["counts"]["keepers"] = 0
    bec.LEDGER_PATH.write_bytes(
        json.dumps(event, sort_keys=True, separators=(",", ":")).encode() + b"\n"
    )
    assert bec.main(["audit"]) == 1
    assert "stale" in capsys.readouterr().err


def test_re_ingest_requires_force_and_appends_a_replacement(ws):
    assert _mint() == 0
    _complete_band("sub-100")
    csv_path = bec.EVAL_CORPUS_DIR / "ann-sub-100-0.csv"
    with pytest.raises(bec.HarnessError, match="already anchored"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=False)
        )
    assert (
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=True)
        )
        == 0
    )
    events = bec.ledger_events()
    assert [e["status"] for e in events] == [bec.LEDGER_COMPLETED, bec.LEDGER_REPLACEMENT]
    assert bec.main(["audit"]) == 0


def test_abandoned_batch_contributes_nothing(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0"]) == 0
    pools = json.loads(bec.POOLS_PATH.read_text())
    membership = bec._recompute_membership(pools, N_BAND_TEST)
    assert membership["sub-100"]["members"] == []
    assert membership["sub-100"]["annotated"] == 0
    assert bec.main(["audit"]) == 0
    # The abandoned span is consumed; the next batch starts after it.
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    record = json.loads((bec.BATCHES_DIR / "sub-100" / "batch-001.json").read_text())
    assert record["start"] == 3


def test_abandoned_batch_cannot_be_ingested(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0", "--force"]) == 0
    with pytest.raises(bec.HarnessError, match="ABANDONED"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=False)
        )


# --- audit ------------------------------------------------------------------


def test_audit_clean_on_a_fresh_commitment(ws):
    assert _mint() == 0
    assert bec.main(["audit"]) == 0


def test_missing_giantsteps_ground_truth_fails_the_audit(ws, monkeypatch, capsys):
    assert _mint() == 0
    monkeypatch.setattr(bec.cc, "resolve_giantsteps_gt_path", lambda: None)
    assert bec.main(["audit"]) == 1
    err = capsys.readouterr().err
    assert "GiantSteps GT not resolved" in err
    assert "Fails closed" in err


def test_giantsteps_title_collision_blocks_until_adjudicated(ws, monkeypatch, capsys):
    assert _mint() == 0
    pools = json.loads(bec.POOLS_PATH.read_text())
    entry = pools["bands"]["sub-100"][0]
    norm = bec.cc.normalize_track_key(entry["title"])
    monkeypatch.setattr(bec, "_giantsteps_titles", lambda: {norm})
    assert bec.main(["audit"]) == 1
    assert "UNRESOLVED review flag" in capsys.readouterr().err
    # Adjudicating it as a different recording clears certification.
    key = f"{entry['source']}:{entry['identity']}"
    doc = json.loads(bec.DISPOSITIONS_PATH.read_text())
    doc["flags"].append(
        {
            "flag_id": bec.flag_id(bec.FLAG_KIND_GIANTSTEPS, key, norm),
            "disposition": bec.DISPOSITION_NOT_SAME,
        }
    )
    bec._write_json(bec.DISPOSITIONS_PATH, doc)
    assert bec.main(["audit"]) == 0


def test_audit_covers_all_candidates_not_only_members(ws, capsys):
    # No member exists yet; a residual training overlap must still fail.
    assert _mint() == 0
    pools = json.loads(bec.POOLS_PATH.read_text())
    leaked = next(e for e in pools["bands"]["sub-100"] if e["source"] == "pool")
    ws.inputs["manifest_hashes"] = {leaked["identity"]}
    assert bec.main(["audit"]) == 1
    assert "residual manifest-hash overlap" in capsys.readouterr().err


def test_audit_fails_on_a_dsp_field_in_an_annotation_record(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    ann_path = bec.ANNOTATIONS_DIR / "sub-100" / "batch-000.json"
    doc = json.loads(ann_path.read_text())
    first = next(iter(doc["rows"]))
    doc["rows"][first]["dsp_bpm"] = 172.0
    bec._write_json(ann_path, doc)
    assert bec.main(["audit"]) == 1
    assert "FR-59a.1: unexpected field 'dsp_bpm'" in capsys.readouterr().err


# --- emit-manifest + signoff ------------------------------------------------


def test_emit_manifest_refuses_an_incomplete_corpus(ws, capsys):
    assert _mint() == 0
    assert bec.main(["emit-manifest"]) == 1
    assert "corpus incomplete" in capsys.readouterr().out


def test_emit_manifest_on_a_complete_corpus(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["emit-manifest"]) == 0
    manifest = json.loads(bec.MANIFEST_PATH.read_text())
    assert manifest["annotation_version"] == bec.ANNOTATION_VERSION_TAG
    assert manifest["degeneracy_note_175_plus"] == bec.DEGENERACY_NOTE_175
    assert len(manifest["entries"]) == N_BAND_TEST * len(bec.BAND_NAMES)
    assert set(manifest["sentinel_per_band"]) == set(bec.BAND_NAMES)


def test_emit_manifest_refused_on_a_dirty_audit(ws, monkeypatch, capsys):
    assert _mint() == 0
    _complete_corpus()
    monkeypatch.setattr(bec.cc, "resolve_giantsteps_gt_path", lambda: None)
    assert bec.main(["emit-manifest"]) == 1
    assert "the shared audit is not clean" in capsys.readouterr().err


def test_sentinel_join_resolves_a_reencode_by_fingerprint(ws, monkeypatch):
    # The 160-175 member and the OA300 85 BPM row share no basename and no
    # audioHash; only the fingerprint join can see them as one recording.
    assert _mint() == 0
    pools = json.loads(bec.POOLS_PATH.read_text())
    target = next(e for e in pools["bands"]["160-175"] if e["source"] == "pool")
    target_path = str(Path(ws.inputs["pool_audio_root"]) / target["relPath"])
    oa_path = str(Path(ws.inputs["_oa300_root"]) / "corpus" / "oa-0.mp3")
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (target_path, oa_path) else _unique_fingerprint(p),
    )
    _complete_corpus()
    assert bec.main(["emit-manifest"]) == 0
    manifest = json.loads(bec.MANIFEST_PATH.read_text())
    tagged = [
        e
        for e in manifest["entries"]
        if e["file_metadata"]["identifiers"]["row_id"] == target["rowId"]
    ]
    assert tagged and tagged[0]["sandbox"].get("sentinel") == "octave-sentinel"
    assert manifest["sentinel_per_band"]["160-175"] >= 1


def test_signoff_writes_an_audit_bound_attestation(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["signoff"]) == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    bec.gate_committed(doc, bec.assert_attestation_schema)
    assert doc["commitment_sha256"] == bec.sha256_file(bec.COMMITMENT_JSON)
    assert doc["annotation_ledger_head"] == bec.ledger_head()[0]
    assert (
        bec.validate_attestation(
            bec.ATTESTATION_JSON, bec.COMMITMENT_JSON, bec.LEDGER_HEAD_JSON, N_BAND_TEST
        )
        == []
    )


def test_signoff_refused_on_a_dirty_audit(ws, monkeypatch, capsys):
    assert _mint() == 0
    _complete_corpus()
    monkeypatch.setattr(bec.cc, "resolve_giantsteps_gt_path", lambda: None)
    assert bec.main(["signoff"]) == 1
    assert "the shared audit is not clean" in capsys.readouterr().err


def test_signoff_refused_before_the_corpus_completes(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    assert bec.main(["signoff"]) == 1
    assert "below" in capsys.readouterr().err


def test_hand_edited_attestation_is_rejected(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["signoff"]) == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    doc["members_per_band"]["sub-100"] = 99
    bec._write_json(bec.ATTESTATION_JSON, doc)
    failures = bec.validate_attestation(
        bec.ATTESTATION_JSON, bec.COMMITMENT_JSON, bec.LEDGER_HEAD_JSON, N_BAND_TEST
    )
    assert any("digest does not match" in f for f in failures)


def test_attestation_rejected_when_the_commitment_moves(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["signoff"]) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["status"] = bec.STATUS_SUPERSEDED
    bec._write_json(bec.COMMITMENT_JSON, doc)
    failures = bec.validate_attestation(
        bec.ATTESTATION_JSON, bec.COMMITMENT_JSON, bec.LEDGER_HEAD_JSON, N_BAND_TEST
    )
    assert any("not active" in f for f in failures)
    assert any("different commitment" in f for f in failures)


def test_attestation_absent_is_a_failure(ws):
    failures = bec.validate_attestation(
        bec.ATTESTATION_JSON, bec.COMMITMENT_JSON, bec.LEDGER_HEAD_JSON, N_BAND_TEST
    )
    assert failures and "absent" in failures[0]


# --- status -----------------------------------------------------------------


def test_status_reports_progress(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    assert bec.main(["status"]) == 0
    out = capsys.readouterr().out
    assert "sub-100" in out
    assert f"/{N_BAND_TEST}" in out
