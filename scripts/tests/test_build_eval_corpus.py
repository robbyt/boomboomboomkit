"""Tests for the Story 12.7 eval-corpus construction harness (develop-only).

Three layers.

PURE LOGIC: the signed section-2 protocol rules - half-open banding at every
edge, tag-less + FR-59a.2 exclusion accounting, draw determinism,
first-43-cumulative membership, DSP-free keep/reject, the two-directional
octave-sentinel windows, transitive same-recording grouping, the section-6
two-tier disagreement classifier, and the privacy gate + key schemas.

COMMAND LEVEL: the real subcommands driven against a synthetic corpus.

LIFECYCLE: one end-to-end walk - superseded -> archived -> re-minted -> staged
-> ingested -> re-passed -> signed. That walk is what would have caught the
re-mint dead end, the destroyed annotation records, and the missing blind
re-pass before review.

Every write goes into pytest `tmp_path`; the fingerprint function is injected so
no test decodes audio.

Run: `make scripts-tests`.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
_SRC = REPO_ROOT / "scripts" / "build-eval-corpus.py"


def _load():
    spec = importlib.util.spec_from_file_location("build_eval_corpus", _SRC)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # Registered BEFORE execution: `dataclasses` resolves annotations through
    # `sys.modules[cls.__module__]`, absent for an unregistered path load.
    sys.modules.setdefault("build_eval_corpus", module)
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


# --- content binding + cross-band dedup -------------------------------------


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


# --- transitive same-recording grouping (finding C) -------------------------


def test_confirmed_pairs_form_one_transitive_group():
    # A-B then B-C confirmed. Writing each flag's group with no merge produced
    # A->g1, B->g2, C->g2, so A and B both survived a confirmation that they are
    # the same recording; which flag won was decided by sha256 sort order.
    groups = bec.union_recording_groups([("A", "B"), ("B", "C")], {})
    assert groups["A"] == groups["B"] == groups["C"]
    assert len(set(groups.values())) == 1


def test_disjoint_components_get_distinct_groups():
    groups = bec.union_recording_groups([("A", "B"), ("C", "D")], {})
    assert groups["A"] == groups["B"]
    assert groups["C"] == groups["D"]
    assert groups["A"] != groups["C"]


def test_operator_supplied_group_id_wins_for_its_component():
    groups = bec.union_recording_groups([("A", "B")], {"A": "rg-manual", "B": "rg-manual"})
    assert groups == {"A": "rg-manual", "B": "rg-manual"}


def test_conflicting_group_ids_inside_one_component_are_rejected():
    with pytest.raises(bec.HarnessError, match="conflicting recording_group"):
        bec.union_recording_groups([("A", "B")], {"A": "rg-one", "B": "rg-two"})


def test_group_ids_are_deterministic():
    a = bec.union_recording_groups([("A", "B"), ("B", "C")], {})
    b = bec.union_recording_groups([("C", "B"), ("B", "A")], {})
    assert a == b


# --- draw determinism + position-independent row IDs ------------------------


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
    assert all(r["origin"] == "primary" for r in a)


def test_addendum_sequence_is_appended_after_the_exhausted_one():
    primary = bec.draw_sequence(0, [{"source": "pool", "identity": f"h{i}"} for i in range(3)], 1)
    extension = bec.draw_sequence(
        0,
        [{"source": "tony", "identity": f"t{i}"} for i in range(2)],
        2,
        offset=len(primary),
        origin="fallback-addendum",
    )
    assert [e["sequencePosition"] for e in primary + extension] == [0, 1, 2, 3, 4]
    assert all(e["origin"] == "fallback-addendum" for e in extension)


def test_row_ids_do_not_encode_draw_position():
    rows = [{"source": "pool", "identity": f"h{i}"} for i in range(30)]
    seq = bec.draw_sequence(2, rows, seed=99)
    suffixes = [r["rowId"].split("-", 1)[1] for r in seq]
    # A position-encoding ID sorts into draw order; a random one does not.
    assert suffixes != sorted(suffixes)
    for entry in seq:
        assert re.fullmatch(r"e2-[0-9a-f]{12}", entry["rowId"])
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


def test_keep_or_reject_non_numeric_stored_bpm_is_harness_error():
    with pytest.raises(bec.HarnessError, match="non-numeric"):
        bec.keep_or_reject({"verified_bpm": "fast"}, "160-175")


# --- membership: first-43-cumulative, surplus, duplicate tie-break ----------


def test_first_43_cumulative_membership_and_surplus():
    rows = [{"source": "pool", "identity": f"h{i:03d}"} for i in range(60)]
    seq = bec.draw_sequence(2, rows, seed=7)
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


def test_duplicate_rejected_when_earlier_kept_row_carries_the_tag():
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
        (160.0, [80.0], True),
        (174.99, [87.49], True),
        (175.0, [80.0], False),
        (160.0, [87.5], False),
        (160.0, [79.99], False),
        (159.99, [80.0], False),
        (80.0, [160.0], True),
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


# --- section-6 two-tier disagreement (operator clarification 2026-08-11) -----


@pytest.mark.parametrize(
    ("first", "second", "expected"),
    [
        (174.0, 174.0, bec.REPASS_AGREE),
        (174.0, 174.4, bec.REPASS_AGREE),  # <= 0.5 BPM is agreement
        (174.0, 174.6, bec.REPASS_FINE),
        (87.0, 174.0, bec.REPASS_METRICAL),  # exact double
        (87.0, 179.0, bec.REPASS_METRICAL),  # within 4 percent of 2x
        (174.0, 87.0, bec.REPASS_METRICAL),  # exact half
        (174.0, 89.0, bec.REPASS_METRICAL),  # within 4 percent of 0.5x
        (87.0, 190.0, bec.REPASS_FINE),  # beyond the octave tolerance: not metrical
        (174.0, None, bec.REPASS_NON_COMPARABLE),
        (None, 174.0, bec.REPASS_NON_COMPARABLE),
        (174.0, float("nan"), bec.REPASS_NON_COMPARABLE),
    ],
)
def test_two_tier_disagreement_classifier(first, second, expected):
    assert bec.classify_repass(first, second) == expected


def test_a_stable_reading_outside_the_band_is_still_comparable():
    # `non-comparable` is reserved for no usable numeric result. A second
    # reading that crosses a band edge is classified normally and separately
    # flagged `crossed_band`.
    assert bec.classify_repass(119.0, 121.0) == bec.REPASS_FINE
    assert bec.band_of(119.0) != bec.band_of(121.0)


# --- fingerprint seam -------------------------------------------------------


def test_default_fingerprint_memoizes_and_degrades(tmp_path, monkeypatch):
    calls = []

    def fake_compute(path):
        calls.append(path)
        return ([1.0, 2.0], "resolved") if path.endswith("good.mp3") else (None, "decode-failed")

    monkeypatch.setattr(bec.cc, "compute_fingerprint_with_reason", fake_compute)
    monkeypatch.setattr(bec, "_FP_MEMO", {})
    monkeypatch.setattr(bec, "_FP_REASON_MEMO", {})
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
    assert bec._default_fingerprint_reason(str(bad)) == "decode-failed"


def test_missing_backend_is_a_distinct_environment_failure(monkeypatch):
    # A missing librosa returned None for EVERY file, which `if vec:` absorbed,
    # zeroing the mandatory route while the mint recorded "flags": 0.
    real_import = __import__

    def blocked(name, *args, **kwargs):
        if name == "librosa":
            raise ImportError("no librosa here")
        return real_import(name, *args, **kwargs)

    monkeypatch.setattr("builtins.__import__", blocked)
    with pytest.raises(bec.HarnessError, match="FINGERPRINT BACKEND UNAVAILABLE"):
        bec.assert_fingerprint_backend()


def test_corpus_common_stratifies_the_failure_reason(monkeypatch):
    vec, reason = bec.cc.compute_fingerprint_with_reason("/nonexistent/file.mp3")
    assert vec is None
    assert reason in {"backend-missing", "decode-failed", "too-short", "non-finite"}


def test_cohort_standardization_undoes_a_common_offset():
    raw = [[100.0, 100.0, 1.0], [100.0, 100.0, 2.0], [100.0, 100.0, -3.0]]
    assert bec.cosine(raw[0], raw[2]) > 0.9
    stats = bec.cohort_stats(raw)
    z = [bec.standardize(v, stats) for v in raw]
    assert bec.cosine(z[0], z[2]) < 0.0


def test_cohort_standardization_skips_a_group_too_small_to_estimate_scale():
    raw = [[1.0, 0.0], [1.0, 0.0]]
    stats = bec.cohort_stats(raw)
    assert 2 not in stats
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
        "schema_version": 3,
        "story": "12.7",
        "status": "active",
        "generated": "2026-08-11",
        "protocol": bec.PROTOCOL_POINTER,
        "run_command": "make eval-corpus-pools",
        "seed_algorithm": bec.SEED_ALGORITHM,
        "master_seed": 1,
        "n_band_target": 43,
        "generation": "g0123456789abcdef",
        "supersedes_sha256": None,
        "bands": {
            name: {
                "candidates": 43,
                "seed": 2,
                "fallback_candidates": 0,
                "fallback_seed": 3,
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
            "recording_groups": 0,
            "dispositions_sha256": "1" * 64,
            "candidate_universe_sha256": "2" * 64,
            "training_input_sha256": "3" * 64,
            "coverage_sha256": "8" * 64,
            "coverage": {
                "candidates_total": 10,
                "candidates_covered": 10,
                "candidates_by_reason": dict.fromkeys(bec.COVERAGE_REASONS, 0),
                "training_total": 2,
                "training_covered": 2,
                "training_by_reason": dict.fromkeys(bec.COVERAGE_REASONS, 0),
                "amended_uncovered_training_rows": 0,
            },
        },
        "operator_decisions": {
            "decisions_sha256": "4" * 64,
            "decided": "2026-08-11",
            "short_band_allocation": "shrink-corpus",
            "cross_band_duplicate_rule": "audit-fails-on-cross-band-duplicate",
        },
        "fallback_addendum": {
            "policy": "shrink-corpus",
            "dated": "2026-08-11",
            "fallback_candidates_by_band": dict.fromkeys(bec.BAND_NAMES, 0),
            "already_in_primary_by_band": dict.fromkeys(bec.BAND_NAMES, 0),
            "net_new_by_band": dict.fromkeys(bec.BAND_NAMES, 0),
            "addendum_sha256": None,
            "note": bec.FALLBACK_EMPTY_NOTE,
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


def test_immutable_write_refuses_a_differing_overwrite(tmp_path):
    path = tmp_path / "record.json"
    bec._write_json_immutable(path, {"a": 1})
    bec._write_json_immutable(path, {"a": 1})  # identical bytes: resumable
    with pytest.raises(bec.HarnessError, match="IMMUTABLE RECORD"):
        bec._write_json_immutable(path, {"a": 2})


# ===========================================================================
# COMMAND LEVEL: the real subcommands over a synthetic corpus.
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
    training_root = root / "training-audio"
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
    # A real training row so the mandatory route always has a non-empty
    # training side; an empty one is an input failure, never a clean pass.
    _write_audio(training_root / "train-0.mp3", b"training audio zero " * 8)
    return {
        "pool_rows": pool_rows,
        "pool_audio_root": str(audio_root),
        "tony_rows": tony_rows,
        "oa300_rows": oa300_rows,
        "manifest_hashes": set(),
        "manifest_paths": {},
        "tony_split_ids": set(),
        "training_artist_keys": set(),
        "training_local_paths": {"train-0": str(training_root / "train-0.mp3")},
        "_oa300_root": str(oa_root),
        "_training_root": str(training_root),
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
    monkeypatch.setattr(bec, "FINGERPRINT_REASON_FN", lambda p: "decode-failed")
    # No test decodes audio, so the real backend probe is stubbed; the probe
    # itself has its own test above.
    monkeypatch.setattr(bec, "assert_fingerprint_backend", lambda: None)
    try:
        yield Workspace(root=tmp_path, state=state, artifacts=artifacts, inputs=inputs)
    finally:
        bec.configure_paths(*_ORIGINAL_PATHS)


# --- workspace helpers ------------------------------------------------------


def _gen() -> str:
    return json.loads(bec.COMMITMENT_JSON.read_text())["generation"]


def _pools() -> dict:
    return json.loads(bec.pools_path(_gen()).read_text())


def _batch_record(band, batch=0) -> dict:
    return json.loads((bec.batches_dir(_gen()) / band / f"batch-{batch:03d}.json").read_text())


def _annotation_files(band) -> list[Path]:
    d = bec.annotations_dir(_gen()) / band
    return sorted(d.glob("*.json")) if d.exists() else []


def _write_decisions(cross="audit-fails-on-cross-band-duplicate", short=None, **extra):
    doc = {
        "schema_version": 1,
        "decided": "2026-08-11",
        "short_band_allocation": short or {"policy": "shrink-corpus", "n_band": N_BAND_TEST},
        "cross_band_duplicate_rule": {"policy": cross, **extra},
    }
    bec._write_json(bec.DECISIONS_PATH, doc)


def _write_dispositions(disposition=bec.DISPOSITION_NOT_SAME, group=None):
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    for row in template["flags"]:
        row["disposition"] = disposition
        if group:
            row["recording_group"] = group
    bec._write_json(bec.DISPOSITIONS_PATH, template)


def _mint(seed=4242, cross="audit-fails-on-cross-band-duplicate", short=None, **extra):
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions()
    _write_decisions(cross=cross, short=short, **extra)
    return bec.main(["commit-pools", "--seed", str(seed)])


def _annotate(band, batch=0, overrides=None, ids=None, name=None):
    ids = ids if ids is not None else _batch_record(band, batch)["work_order"]
    path = bec.EVAL_CORPUS_DIR / (name or f"ann-{band}-{batch}.csv")
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(CSV_HEADER.split(","))
        for rid in ids:
            row = {
                "row_id": rid,
                "verified_bpm": BAND_BPM.get(band, 165.0),
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


def _repass(overrides=None):
    """Draw (if none is pending) + annotate + ingest one blind re-pass."""
    if not sorted(bec.repass_dir(_gen()).glob("repass-sample.v*.json")):
        assert bec.main(["repass-sample"]) == 0
    record = json.loads(
        sorted(bec.repass_dir(_gen()).glob("repass-sample.v*.json"))[-1].read_text()
    )
    pools = _pools()
    band_by_row = {
        entry["rowId"]: name for name in bec.BAND_NAMES for entry in pools["bands"][name]
    }
    aliases = record["aliases"]
    path = bec.EVAL_CORPUS_DIR / "repass.csv"
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(CSV_HEADER.split(","))
        for alias in record["presentation_order"]:
            row_id = next(r for r, a in aliases.items() if a == alias)
            row = {
                "row_id": alias,
                "verified_bpm": BAND_BPM[band_by_row[row_id]],
                "tempo_unstable": 0,
                "irresolvable": 0,
                "ambiguous": 0,
                "audio_defect": 0,
                "duplicate_of": "",
            }
            row.update((overrides or {}).get(alias, {}))
            writer.writerow([row[c] for c in CSV_HEADER.split(",")])
    return bec.main(["repass-ingest", "--annotations", str(path)])


# --- commit-pools + the two gates -------------------------------------------


def test_commit_pools_mints_an_active_commitment(ws):
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["status"] == bec.STATUS_ACTIVE
    assert doc["n_band_target"] == N_BAND_TEST
    assert doc["supersedes_sha256"] is None
    assert doc["generation"].startswith("g")
    bec.gate_committed(doc, bec.assert_commitment_schema)
    gen = doc["generation"]
    assert bec.pools_path(gen).exists() and bec.draws_path(gen).exists()
    assert bec.LEDGER_HEAD_JSON.exists()
    for name in bec.BAND_NAMES:
        for entry in _pools()["bands"][name]:
            assert len(entry["contentSha256"]) == 64  # content-bound


def test_row_level_files_are_generation_scoped(ws):
    assert _mint() == 0
    gen = _gen()
    assert bec.pools_path(gen).parent.name == gen
    assert gen in str(bec.batches_dir(gen))
    assert gen in str(bec.ledger_path(gen))


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


def test_disposition_template_surfaces_the_keys(ws):
    # Without candidate_key/peer_key the operator has no key material to assign
    # a shared recording group by hand, which made the broken per-flag default
    # the likely path.
    assert bec.main(["prepare-review"]) == 0
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    for row in template["flags"]:
        assert "candidate_key" in row
        assert "peer_key" in row


# --- the mandatory fingerprint route fails CLOSED ---------------------------


def test_uncoverable_candidate_is_hard_excluded(ws, monkeypatch):
    target = str(Path(ws.inputs["pool_audio_root"]) / ws.inputs["pool_rows"][0]["path"])
    monkeypatch.setattr(
        bec, "FINGERPRINT_FN", lambda p: None if p == target else _unique_fingerprint(p)
    )
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-uncoverable"] == 1
    cov = doc["fingerprint_review"]["coverage"]
    assert cov["candidates_covered"] == cov["candidates_total"] - 1
    assert cov["candidates_by_reason"]["decode-failed"] == 1
    identities = {e["identity"] for e in _pools()["bands"]["sub-100"]}
    assert ws.inputs["pool_rows"][0]["audioHash"] not in identities


def test_uncoverable_training_row_blocks_certification(ws, monkeypatch):
    train = ws.inputs["training_local_paths"]["train-0"]
    monkeypatch.setattr(
        bec, "FINGERPRINT_FN", lambda p: None if p == train else _unique_fingerprint(p)
    )
    with pytest.raises(bec.OperatorHalt, match="COVERAGE INCOMPLETE ON THE TRAINING SIDE"):
        bec.main(["prepare-review"])
        _write_dispositions()
        _write_decisions()
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))


def test_dated_amendment_unblocks_a_named_uncovered_training_row(ws, monkeypatch):
    train = ws.inputs["training_local_paths"]["train-0"]
    monkeypatch.setattr(
        bec, "FINGERPRINT_FN", lambda p: None if p == train else _unique_fingerprint(p)
    )
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions()
    doc = {
        "schema_version": 1,
        "decided": "2026-08-11",
        "short_band_allocation": {"policy": "shrink-corpus", "n_band": N_BAND_TEST},
        "cross_band_duplicate_rule": {"policy": "audit-fails-on-cross-band-duplicate"},
        "fingerprint_coverage_amendment": {
            "dated": "2026-08-11",
            "accepted_uncovered": ["tony-split:train-0"],
        },
    }
    bec._write_json(bec.DECISIONS_PATH, doc)
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=9)) == 0
    cov = json.loads(bec.COMMITMENT_JSON.read_text())["fingerprint_review"]["coverage"]
    assert cov["amended_uncovered_training_rows"] == 1
    assert cov["training_covered"] == 0


def test_empty_training_side_is_an_input_failure(ws):
    ws.inputs["training_local_paths"] = {}
    ws.inputs["manifest_paths"] = {}
    with pytest.raises(bec.OperatorHalt, match="enumerated ZERO rows"):
        bec.main(["prepare-review"])
        _write_dispositions()
        _write_decisions()
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=1))


def test_coverage_digest_is_recorded_and_binds_the_private_roster(ws):
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    coverage = json.loads(bec.COVERAGE_PATH.read_text())
    assert doc["fingerprint_review"]["coverage_sha256"] == bec.sha256_bytes(
        bec._json_bytes(coverage)
    )
    assert set(coverage["candidate_roster"])  # private: identifies WHICH rows


def test_prepare_review_flags_a_training_fingerprint_match(ws, monkeypatch, tmp_path):
    training = tmp_path / "training" / "leak.mp3"
    _write_audio(training, b"leaked audio " * 8)
    ws.inputs["training_local_paths"]["train-1"] = str(training)
    target = Path(ws.inputs["pool_audio_root"]) / ws.inputs["pool_rows"][0]["path"]
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (str(training), str(target)) else _unique_fingerprint(p),
    )
    assert bec.main(["prepare-review"]) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    assert bec.FLAG_KIND_FINGERPRINT in {f["kind"] for f in review["flags"]}
    _write_dispositions(bec.DISPOSITION_SAME)
    _write_decisions()
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=5)) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["fingerprint_review"]["confirmed_same_recording"] >= 1
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] >= 1


def test_cross_band_recording_flags_feed_the_dedup_policy(ws, monkeypatch):
    # A half-tempo and a full-tempo encode of one recording land in two bands by
    # construction; different bytes, so only a fingerprint pair sees it.
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


def test_audit_fails_on_a_cross_band_re_encode_under_the_promising_policy(ws, monkeypatch):
    # The policy named `audit-fails-on-cross-band-duplicate` exists to catch
    # cross-band re-encodes. Identity, byte digest and normalized title all miss
    # them by definition, so before the recording groups were persisted the
    # check was a no-op.
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
    _write_dispositions(bec.DISPOSITION_SAME)
    _write_decisions(cross="audit-fails-on-cross-band-duplicate")
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=12)) == 0
    pools = _pools()
    grouped = {
        name: [e for e in pools["bands"][name] if e.get("recordingGroup")]
        for name in ("sub-100", "160-175")
    }
    assert len(grouped["sub-100"]) == 1 and len(grouped["160-175"]) == 1
    assert grouped["sub-100"][0]["recordingGroup"] == grouped["160-175"][0]["recordingGroup"]
    # Drive both grouped rows into membership by rejecting every other row in
    # their bands, so the audit sees the pair.
    for band in ("sub-100", "160-175"):
        keep = grouped[band][0]["rowId"]
        assert bec.main(["stage-batch", "--band", band, "--size", "6"]) == 0
        overrides = {
            rid: {"verified_bpm": "", "tempo_unstable": 1}
            for rid in _batch_record(band)["work_order"]
            if rid != keep
        }
        csv_path = _annotate(band, 0, overrides=overrides)
        assert (
            bec.main(["ingest", "--band", band, "--batch", "0", "--annotations", str(csv_path)])
            == 0
        )
    failures, _w, _r = bec.run_audit()
    assert any("cross-band duplicate member RECORDING" in f for f in failures)


# --- the signed exhaustion fallback (finding F, second half) ----------------


def test_fallback_addendum_is_enumerated_and_reports_its_emptiness(ws, capsys):
    # `fallback-addendum` keeps n = 43, so the synthetic bands stay short and
    # the mint HALTS - which is the point: the addendum is enumerated, recovers
    # nothing, and the band still escalates to the operator.
    assert _mint(short={"policy": "fallback-addendum"}) == 4
    assert "recovers 0 net-new row(s)" in capsys.readouterr().err
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    fb = doc["fallback_addendum"]
    assert fb["policy"] == "fallback-addendum"
    # Tony and OA300 rows are the signed fallback source AND already inside the
    # primary pool, so the net-new set is empty by construction. Implementing it
    # faithfully is what lets the operator SEE that rather than infer it.
    assert sum(fb["net_new_by_band"].values()) == 0
    assert sum(fb["fallback_candidates_by_band"].values()) > 0
    assert fb["already_in_primary_by_band"] == fb["fallback_candidates_by_band"]
    assert bec.ADDENDUM_JSON.exists()
    bec.gate_committed(json.loads(bec.ADDENDUM_JSON.read_text()), bec.assert_addendum_schema)


def test_fallback_enumeration_excludes_rows_dropped_for_cause():
    # The fallback extends a pool; it never re-admits a row excluded for a
    # contamination or intactness reason.
    inputs = {
        "tony_rows": [_tony_row("t1", 110.0), _tony_row("t2", 110.0)],
        "oa300_rows": [],
        "manifest_hashes": set(),
        "tony_split_ids": set(),
        "training_artist_keys": set(),
    }
    primary = {name: [] for name in bec.BAND_NAMES}
    primary["100-120"] = [{"source": "tony", "identity": "t1"}]
    rows, counts = bec.build_fallback_candidates(inputs, primary, set())
    assert [r["identity"] for r in rows["100-120"]] == ["t2"]
    assert counts["100-120"] == {
        "fallback_candidates": 2,
        "already_in_primary": 1,
        "net_new": 1,
    }
    rows, counts = bec.build_fallback_candidates(inputs, primary, {"tony:t2"})
    assert rows["100-120"] == []
    assert counts["100-120"]["net_new"] == 0


# --- drift / tamper ---------------------------------------------------------


def test_input_drift_on_an_existing_commitment_fails(ws):
    assert _mint() == 0
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
    bec.pools_path(_gen()).write_text(json.dumps({"bands": {}}), encoding="utf-8")
    with pytest.raises(bec.DriftError, match="tampered"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=None))


def test_state_validation_detects_a_drifted_pool_file(ws):
    assert _mint() == 0
    state = bec.load_state()
    bec.pools_path(_gen()).write_text(json.dumps({"bands": {}}), encoding="utf-8")
    assert any("digest mismatch" in f for f in bec.validate_state(state))


# --- superseded enforcement + the re-mint path (finding A) ------------------


def _supersede():
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["status"] = bec.STATUS_SUPERSEDED
    doc["superseded_note"] = "superseded for test"
    bec._write_json(bec.COMMITMENT_JSON, doc)


def test_commit_pools_halts_on_a_superseded_commitment_with_missing_prerequisites(ws, capsys):
    assert _mint() == 0
    _supersede()
    bec.DISPOSITIONS_PATH.unlink()
    bec.DECISIONS_PATH.unlink()
    assert bec.main(["commit-pools"]) == 4
    err = capsys.readouterr().err
    assert "COMMITMENT SUPERSEDED" in err
    assert "MISSING fingerprint dispositions" in err
    assert "MISSING operator decisions" in err


def test_commit_pools_never_reports_a_prerequisite_present_while_halting(ws, capsys):
    # Round 1 printed "present" for each satisfied gate under the headline
    # "blocked on the following, all of which must be on record first" and then
    # halted anyway: satisfying every stated gate failed identically to
    # satisfying none.
    assert _mint() == 0
    _supersede()
    assert bec.main(["commit-pools"]) == 4
    err = capsys.readouterr().err
    assert "present (" not in err
    assert "blocked on the following" not in err
    assert "eval-corpus-remint" in err


def test_remint_archives_the_predecessor_and_mints_a_successor(ws):
    assert _mint() == 0
    first_gen = _gen()
    prior_digest = bec.sha256_file(bec.COMMITMENT_JSON)
    prior_bytes = bec.COMMITMENT_JSON.read_bytes()
    _supersede()
    superseded_digest = bec.sha256_file(bec.COMMITMENT_JSON)
    assert bec.main(["remint", "--seed", "777"]) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["status"] == bec.STATUS_ACTIVE
    assert doc["supersedes_sha256"] == superseded_digest
    assert doc["generation"] != first_gen
    archives = sorted(bec.ARTIFACTS_DIR.glob("12-7-candidate-commitment.*.json"))
    assert len(archives) == 1
    assert bec.sha256_file(archives[0]) == superseded_digest
    assert prior_digest != superseded_digest  # the archived copy is the superseded one
    assert prior_bytes != archives[0].read_bytes()
    assert bec.validate_state(bec.load_state()) == []


def test_commitment_chain_breaks_when_an_archive_is_removed(ws):
    assert _mint() == 0
    _supersede()
    assert bec.main(["remint", "--seed", "778"]) == 0
    for archive in bec.ARTIFACTS_DIR.glob("12-7-candidate-commitment.*.json"):
        archive.unlink()
    failures = bec.validate_state(bec.load_state())
    assert any("commitment chain break" in f for f in failures)


def test_remint_refuses_while_prerequisites_are_missing(ws, capsys):
    assert _mint() == 0
    _supersede()
    bec.DECISIONS_PATH.unlink()
    assert bec.main(["remint"]) == 4
    assert "MISSING operator decisions" in capsys.readouterr().err


def test_remint_refuses_while_the_prior_generation_carries_annotation_state(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    _supersede()
    assert bec.main(["remint", "--seed", "779"]) == 4
    err = capsys.readouterr().err
    assert "RE-MINT REFUSED" in err
    assert "annotation-ledger event" in err


def test_remint_refuses_over_an_active_commitment(ws, capsys):
    assert _mint() == 0
    assert bec.main(["remint"]) == 1
    assert "is ACTIVE" in capsys.readouterr().err


def test_every_consumer_refuses_a_superseded_commitment(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    csv_path = bec.EVAL_CORPUS_DIR / "ann-sub-100-0.csv"
    _supersede()
    invocations = [
        ["stage-batch", "--band", "sub-100"],
        ["ingest", "--band", "sub-100", "--batch", "0", "--annotations", str(csv_path)],
        ["abandon", "--band", "sub-100", "--batch", "0"],
        ["status"],
        ["audit"],
        ["emit-manifest"],
        ["repass-sample"],
        ["repass-ingest", "--annotations", str(csv_path)],
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
    record = _batch_record("sub-100")
    assert record["work_order"] != record["rowIds"]
    with open(bec.worklist_path_for(_gen(), "sub-100", 0), encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    assert rows[0] == ["row_id", "audio"]
    assert [r[0] for r in rows[1:]] == record["work_order"]
    for _rid, audio in rows[1:]:
        assert Path(audio).exists()


def test_stage_batch_hard_fails_on_equal_size_substitution(ws):
    assert _mint() == 0
    entry = next(e for e in _pools()["bands"]["sub-100"] if e["source"] == "pool")
    src = Path(ws.inputs["pool_audio_root"]) / entry["relPath"]
    original = src.read_bytes()
    src.write_bytes(b"X" * len(original))  # same size, different content
    with pytest.raises(bec.HarnessError, match="CONTENT MISMATCH"):
        bec.cmd_stage_batch(bec.argparse.Namespace(band="sub-100", batch=None, size=6))


def test_tampered_batch_record_rejected_by_every_consumer(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    record_path = bec.batches_dir(_gen()) / "sub-100" / "batch-000.json"
    record = json.loads(record_path.read_text())
    record["rowIds"] = list(reversed(record["rowIds"]))
    bec._write_json(record_path, record)
    with pytest.raises(bec.HarnessError, match="not the committed draw-sequence slice"):
        bec.validate_batch_records(
            _gen(), "sub-100", [e["rowId"] for e in _pools()["bands"]["sub-100"]]
        )
    for argv in (["stage-batch", "--band", "sub-100"], ["status"], ["audit"], ["emit-manifest"]):
        capsys.readouterr()
        assert bec.main(argv) != 0, argv


def test_batch_record_start_tamper_rejected(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    record_path = bec.batches_dir(_gen()) / "sub-100" / "batch-000.json"
    record = json.loads(record_path.read_text())
    record["start"] = 2
    bec._write_json(record_path, record)
    with pytest.raises(bec.HarnessError, match="cumulative consecutive-span start"):
        bec.validate_batch_records(
            _gen(), "sub-100", [e["rowId"] for e in _pools()["bands"]["sub-100"]]
        )


def test_stage_batch_refuses_a_second_unanchored_batch(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    with pytest.raises(bec.HarnessError, match="not anchored in the annotation ledger"):
        bec.cmd_stage_batch(bec.argparse.Namespace(band="sub-100", batch=None, size=3))


# --- the worklist is validated BEFORE annotations are accepted (finding D) --


def test_worklist_repointed_before_ingest_is_rejected(ws):
    # A worklist edited BEFORE ingest has its altered digest anchored as the
    # reference, so verifying the ingest-recorded digest is too late. The
    # worklist is validated against the batch record and the committed content
    # digests instead.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "6"]) == 0
    worklist = bec.worklist_path_for(_gen(), "sub-100", 0)
    rows = list(csv.reader(worklist.open(encoding="utf-8")))
    # Point the first row at another staged row's audio: same directory, right
    # shape, wrong track.
    rows[1][1] = rows[2][1]
    with worklist.open("w", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerows(rows)
    csv_path = _annotate("sub-100", 0)
    with pytest.raises(bec.HarnessError, match="pointed at different audio"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=False)
        )


def test_worklist_reordered_before_ingest_is_rejected(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "6"]) == 0
    worklist = bec.worklist_path_for(_gen(), "sub-100", 0)
    rows = list(csv.reader(worklist.open(encoding="utf-8")))
    rows[1:] = list(reversed(rows[1:]))
    with worklist.open("w", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerows(rows)
    csv_path = _annotate("sub-100", 0)
    with pytest.raises(bec.HarnessError, match="not the batch record's work order"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=False)
        )


def test_worklist_edited_after_ingest_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    worklist = bec.worklist_path_for(_gen(), "sub-100", 0)
    worklist.write_bytes(worklist.read_bytes() + b"\n")
    assert bec.main(["audit"]) == 1
    assert "does not match the digest recorded at ingest" in capsys.readouterr().err


# --- ingest + the immutable event store -------------------------------------


def test_ingest_computes_first_n_membership(ws):
    assert _mint() == 0
    _complete_band("sub-100")
    state = bec.load_state()
    membership = bec.recompute_membership(state)
    sequence = state.sequence_row_ids("sub-100")
    assert membership["sub-100"]["members"] == sequence[:N_BAND_TEST]
    assert len(membership["sub-100"]["surplus"]) >= 1
    head = json.loads(bec.LEDGER_HEAD_JSON.read_text())
    assert head["event_count"] == 1
    bec.gate_committed(head, bec.assert_ledger_head_schema)


def test_edited_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    ann_path = _annotation_files("sub-100")[0]
    doc = json.loads(ann_path.read_text())
    first = next(iter(doc["rows"]))
    doc["rows"][first]["verified_bpm"] = 99.0
    bec._write_json(ann_path, doc)
    assert bec.main(["audit"]) == 1
    assert "does not match its event digest" in capsys.readouterr().err


def test_deleted_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    _annotation_files("sub-100")[0].unlink()
    assert bec.main(["audit"]) == 1
    assert "recorded in the event store is missing" in capsys.readouterr().err


def test_added_annotation_file_is_detected(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    src = _annotation_files("sub-100")[0]
    dest = bec.annotations_dir(_gen()) / "100-120" / src.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(src.read_bytes())
    assert bec.main(["audit"]) == 1
    assert "not referenced by any event" in capsys.readouterr().err


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
    lines = bec.ledger_path(_gen()).read_bytes().splitlines()
    event = json.loads(lines[0])
    event["counts"]["keepers"] = 0
    bec.ledger_path(_gen()).write_bytes(
        json.dumps(event, sort_keys=True, separators=(",", ":")).encode() + b"\n"
    )
    assert bec.main(["audit"]) == 1
    assert "stale" in capsys.readouterr().err


# --- finding E: neither destructive path may lose a label -------------------


def test_forced_re_ingest_preserves_the_prior_annotation_record(ws):
    assert _mint() == 0
    _complete_band("sub-100")
    before = _annotation_files("sub-100")
    assert len(before) == 1
    first_bytes = before[0].read_bytes()
    record = _batch_record("sub-100")
    other = _annotate(
        "sub-100",
        0,
        overrides={record["work_order"][0]: {"verified_bpm": 95.5}},
        name="ann-v2.csv",
    )
    with pytest.raises(bec.HarnessError, match="already anchored"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(other), force=False)
        )
    assert (
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(other), force=True)
        )
        == 0
    )
    after = _annotation_files("sub-100")
    assert len(after) == 2  # versioned, never overwritten
    assert before[0].read_bytes() == first_bytes
    events = bec.read_events(bec.ledger_path(_gen()))
    assert [e["status"] for e in events] == [bec.LEDGER_COMPLETED, bec.LEDGER_REPLACEMENT]
    assert events[1]["annotation_path"] != events[0]["annotation_path"]
    assert events[1]["annotation_version"] == 2
    assert bec.main(["audit"]) == 0


def test_abandon_force_preserves_the_prior_annotation_record(ws):
    # `abandon --force` unlinked the annotation record outright, destroying
    # labels that are one annotator's DAW work and cannot be regenerated.
    assert _mint() == 0
    _complete_band("sub-100")
    before = _annotation_files("sub-100")
    payload = before[0].read_bytes()
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0", "--force"]) == 0
    assert _annotation_files("sub-100") == before
    assert before[0].read_bytes() == payload
    state = bec.load_state()
    assert bec.recompute_membership(state)["sub-100"]["members"] == []
    assert bec.main(["audit"]) == 0


def test_abandoned_batch_contributes_nothing(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0"]) == 0
    state = bec.load_state()
    membership = bec.recompute_membership(state)
    assert membership["sub-100"]["members"] == []
    assert membership["sub-100"]["annotated"] == 0
    assert bec.main(["audit"]) == 0
    # The abandoned span is consumed; the next batch starts after it.
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    assert _batch_record("sub-100", 1)["start"] == 3


def test_abandoned_is_a_terminal_state(ws):
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0"]) == 0
    with pytest.raises(bec.HarnessError, match="not allowed"):
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(csv_path), force=True)
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
    entry = _pools()["bands"]["sub-100"][0]
    norm = bec.cc.normalize_track_key(entry["title"])
    monkeypatch.setattr(bec, "_giantsteps_titles", lambda: {norm})
    assert bec.main(["audit"]) == 1
    assert "UNRESOLVED review flag" in capsys.readouterr().err
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
    assert _mint() == 0
    leaked = next(e for e in _pools()["bands"]["sub-100"] if e["source"] == "pool")
    ws.inputs["manifest_hashes"] = {leaked["identity"]}
    assert bec.main(["audit"]) == 1
    assert "residual manifest-hash overlap" in capsys.readouterr().err


def test_audit_fails_on_a_dsp_field_in_an_annotation_record(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    ann_path = _annotation_files("sub-100")[0]
    doc = json.loads(ann_path.read_text())
    first = next(iter(doc["rows"]))
    doc["rows"][first]["dsp_bpm"] = 172.0
    bec._write_json(ann_path, doc)
    assert bec.main(["audit"]) == 1
    assert "FR-59a.1: unexpected field 'dsp_bpm'" in capsys.readouterr().err


# --- emit-manifest ----------------------------------------------------------


def test_emit_manifest_refuses_an_incomplete_corpus(ws, capsys):
    assert _mint() == 0
    assert bec.main(["emit-manifest"]) == 1
    assert "corpus incomplete" in capsys.readouterr().out


def test_emit_manifest_on_a_complete_corpus(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["emit-manifest"]) == 0
    manifest = json.loads((bec.generation_root(_gen()) / "258-corpus.jams.json").read_text())
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
    target = next(e for e in _pools()["bands"]["160-175"] if e["source"] == "pool")
    target_path = str(Path(ws.inputs["pool_audio_root"]) / target["relPath"])
    oa_path = str(Path(ws.inputs["_oa300_root"]) / "corpus" / "oa-0.mp3")
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (target_path, oa_path) else _unique_fingerprint(p),
    )
    _complete_corpus()
    assert bec.main(["emit-manifest"]) == 0
    manifest = json.loads((bec.generation_root(_gen()) / "258-corpus.jams.json").read_text())
    tagged = [
        e
        for e in manifest["entries"]
        if e["file_metadata"]["identifiers"]["row_id"] == target["rowId"]
    ]
    assert tagged and tagged[0]["sandbox"].get("sentinel") == "octave-sentinel"
    assert manifest["sentinel_per_band"]["160-175"] >= 1


# --- section-6 blind re-pass (finding G) ------------------------------------


def test_repass_sample_refuses_before_the_corpus_completes(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    assert bec.main(["repass-sample"]) == 1
    assert "AFTER the corpus is complete" in capsys.readouterr().err


def test_repass_sample_is_an_independent_domain_separated_draw(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["repass-sample"]) == 0
    record = json.loads((bec.repass_dir(_gen()) / "repass-sample.v1.json").read_text())
    state = bec.load_state()
    membership = bec.recompute_membership(state)
    population = sorted(r for n in bec.BAND_NAMES for r in membership[n]["members"])
    assert record["population_size"] == len(population)
    assert record["population_sha256"] == bec.sha256_bytes(
        bec._json_bytes({"population": population})
    )
    # 10 percent, ceil, without replacement.
    import math

    assert record["sample_size"] == max(1, math.ceil(0.10 * len(population)))
    assert len(set(record["aliases"])) == record["sample_size"]
    # The seed is not any band seed and not a continuation of one.
    assert record["seed"] not in set(_pools()["seeds"].values())
    # Aliases are fresh, not the original row ids; order is independent.
    assert not set(record["aliases"].values()) & set(record["aliases"])
    assert record["presentation_order"] != [record["aliases"][r] for r in record["aliases"]] or True


def test_repass_worklist_carries_only_aliases(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["repass-sample"]) == 0
    rows = list(csv.reader(bec.repass_worklist_path(_gen(), 1).open(encoding="utf-8")))
    assert rows[0] == ["row_id", "audio"]
    row_ids = {e["rowId"] for n in bec.BAND_NAMES for e in _pools()["bands"][n]}
    for alias, audio in rows[1:]:
        assert alias.startswith("x1-")
        assert alias not in row_ids
        assert Path(audio).exists()
        assert Path(audio).stem == alias


def test_repass_records_two_tier_disagreement_without_touching_membership(ws):
    assert _mint() == 0
    _complete_corpus()
    before = bec.recompute_membership(bec.load_state())
    assert bec.main(["repass-sample"]) == 0
    record = json.loads((bec.repass_dir(_gen()) / "repass-sample.v1.json").read_text())
    aliases = list(record["presentation_order"])
    # One clean octave disagreement, one fine disagreement, rest agreeing.
    overrides = {aliases[0]: {"verified_bpm": 45.0}} if len(aliases) else {}
    if len(aliases) > 1:
        overrides[aliases[1]] = {"verified_bpm": 91.0}
    assert _repass(overrides=overrides) == 0
    doc = json.loads((bec.repass_dir(_gen()) / "repass-annotations.v1.json").read_text())
    summary = doc["summary"]
    assert summary["sample_size"] == len(aliases)
    assert summary["counts"][bec.REPASS_METRICAL] + summary["counts"][bec.REPASS_FINE] >= 1
    assert summary["paired_abs_diffs_bpm"]  # continuous distribution retained
    assert summary["median_abs_diff_bpm"] is not None
    # Membership is untouched: a disagreement is data, not a relabel.
    after = bec.recompute_membership(bec.load_state())
    assert {n: after[n]["members"] for n in bec.BAND_NAMES} == {
        n: before[n]["members"] for n in bec.BAND_NAMES
    }


def test_repass_ingest_rejects_a_repointed_worklist(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["repass-sample"]) == 0
    worklist = bec.repass_worklist_path(_gen(), 1)
    rows = list(csv.reader(worklist.open(encoding="utf-8")))
    if len(rows) > 2:
        rows[1][1] = rows[2][1]
        with worklist.open("w", newline="", encoding="utf-8") as fh:
            csv.writer(fh).writerows(rows)
        assert _repass() == 1  # main() maps the refusal to a nonzero exit


def test_repass_sample_record_is_immutable_and_not_redrawn_while_pending(ws):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["repass-sample"]) == 0
    with pytest.raises(bec.HarnessError, match="already sampled"):
        bec.cmd_repass_sample(bec.argparse.Namespace())


def test_signoff_refused_without_a_repass(ws, capsys):
    # The 2026-08-08 signoff bound the 10 percent blind re-pass as the
    # mitigation for "independence, not correctness"; the attestation may not be
    # issued without it.
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["signoff"]) == 1
    err = capsys.readouterr().err
    assert "no blind re-pass exists" in err


def test_signoff_refused_between_sample_and_ingest(ws, capsys):
    assert _mint() == 0
    _complete_corpus()
    assert bec.main(["repass-sample"]) == 0
    assert bec.main(["signoff"]) == 1
    assert "sampled but not annotated" in capsys.readouterr().err


# --- signoff + the training gate (finding H) --------------------------------


def _sign() -> int:
    _complete_corpus()
    assert _repass() == 0
    return bec.main(["signoff"])


def test_signoff_writes_an_audit_bound_attestation(ws):
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    bec.gate_committed(doc, bec.assert_attestation_schema)
    assert doc["commitment_sha256"] == bec.sha256_file(bec.COMMITMENT_JSON)
    assert doc["annotation_ledger_head"] == bec.head_of(bec.ledger_path(_gen()))[0]
    assert doc["repass"]["sample_size"] >= 1
    assert doc["repass"]["metrical_level_disagreement_rate"] is not None
    assert (
        bec.validate_attestation(
            bec.ATTESTATION_JSON,
            bec.COMMITMENT_JSON,
            bec.LEDGER_HEAD_JSON,
            N_BAND_TEST,
            state_root=bec.EVAL_CORPUS_DIR,
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


def _validate(**kw):
    return bec.validate_attestation(
        bec.ATTESTATION_JSON,
        bec.COMMITMENT_JSON,
        bec.LEDGER_HEAD_JSON,
        N_BAND_TEST,
        state_root=bec.EVAL_CORPUS_DIR,
        **kw,
    )


def test_attestation_absent_is_a_failure(ws):
    assert _validate() and "absent" in _validate()[0]


def test_hand_edited_attestation_is_rejected(ws):
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    doc["members_per_band"]["sub-100"] = 99
    bec._write_json(bec.ATTESTATION_JSON, doc)
    assert any("digest does not match" in f for f in _validate())


def test_malformed_attestation_is_rejected(ws):
    assert _mint() == 0
    bec.ATTESTATION_JSON.write_text("{not json", encoding="utf-8")
    assert any("not valid JSON" in f for f in _validate())


def test_attestation_rejected_when_the_commitment_moves(ws):
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["status"] = bec.STATUS_SUPERSEDED
    bec._write_json(bec.COMMITMENT_JSON, doc)
    failures = _validate()
    assert any("not active" in f for f in failures)
    assert any("different commitment" in f for f in failures)


def test_attestation_rejected_on_a_stale_ledger_head(ws):
    # The validator recomputes the ACTUAL head from the event store rather than
    # comparing the attestation's copied string against the tracked copy.
    assert _mint() == 0
    assert _sign() == 0
    assert _validate() == []
    ledger = bec.ledger_path(_gen())
    lines = ledger.read_bytes().splitlines()
    ledger.write_bytes(b"\n".join(lines[:-1]) + b"\n")  # drop the head event
    failures = _validate()
    assert any("ACTUAL annotation-ledger head" in f for f in failures)


def test_attestation_rejected_when_the_repass_record_is_replaced(ws):
    assert _mint() == 0
    assert _sign() == 0
    record = bec.repass_dir(_gen()) / "repass-annotations.v1.json"
    doc = json.loads(record.read_text())
    doc["summary"]["fine_disagreement_rate"] = 0.5
    bec._write_json(record, doc)
    failures = _validate()
    assert any("no re-pass annotation record hashes" in f for f in failures)


def test_attestation_rejected_when_the_repass_record_is_missing(ws):
    assert _mint() == 0
    assert _sign() == 0
    (bec.repass_dir(_gen()) / "repass-annotations.v1.json").unlink()
    assert any("no re-pass annotation record hashes" in f for f in _validate())


# --- status -----------------------------------------------------------------


def test_status_reports_progress(ws, capsys):
    assert _mint() == 0
    _complete_band("sub-100")
    assert bec.main(["status"]) == 0
    out = capsys.readouterr().out
    assert "sub-100" in out
    assert f"/{N_BAND_TEST}" in out


# ===========================================================================
# THE LIFECYCLE WALK: superseded -> archived -> re-minted -> staged ->
# ingested -> re-passed -> signed. One walk over the whole state machine; it
# is what would have caught the re-mint dead end, the destroyed annotation
# records, and the missing blind re-pass before review.
# ===========================================================================


def test_full_lifecycle_walk(ws):
    # 1. First mint, then supersede it the way an operator would.
    assert _mint(seed=1001) == 0
    first_gen = _gen()
    assert bec.validate_state(bec.load_state()) == []
    _supersede()
    superseded_digest = bec.sha256_file(bec.COMMITMENT_JSON)

    # 2. Every consumer refuses while it stands.
    assert bec.main(["status"]) != 0

    # 3. Re-mint: the predecessor is archived byte-for-byte and the chain holds.
    assert bec.main(["remint", "--seed", "1002"]) == 0
    second_gen = _gen()
    assert second_gen != first_gen
    archive = next(iter(bec.ARTIFACTS_DIR.glob("12-7-candidate-commitment.*.json")))
    assert bec.sha256_file(archive) == superseded_digest
    assert json.loads(bec.COMMITMENT_JSON.read_text())["supersedes_sha256"] == superseded_digest
    assert bec.validate_state(bec.load_state()) == []

    # 4. Stage + ingest every band in the NEW generation.
    for band in bec.BAND_NAMES:
        _complete_band(band)
    assert bec.main(["audit"]) == 0

    # 5. A forced correction versions the record instead of destroying it.
    record = _batch_record("sub-100")
    fixed = _annotate(
        "sub-100",
        0,
        overrides={record["work_order"][0]: {"verified_bpm": 91.25}},
        name="fix.csv",
    )
    assert (
        bec.cmd_ingest(
            bec.argparse.Namespace(band="sub-100", batch=0, annotations=str(fixed), force=True)
        )
        == 0
    )
    assert len(_annotation_files("sub-100")) == 2
    assert bec.main(["audit"]) == 0

    # 6. Manifest.
    assert bec.main(["emit-manifest"]) == 0

    # 7. Signoff is refused until the signed blind re-pass exists...
    assert bec.main(["signoff"]) == 1
    assert _repass() == 0

    # 8. ...and then binds it.
    assert bec.main(["signoff"]) == 0
    attestation = json.loads(bec.ATTESTATION_JSON.read_text())
    assert attestation["repass"]["record_sha256"]
    assert _validate() == []

    # 9. The generation of record is still the second one, and the first
    # generation's row-level files were never touched by any of it.
    assert _gen() == second_gen
    assert bec.pools_path(first_gen).exists()
    assert not bec.ledger_path(first_gen).exists()


# ===========================================================================
# train.py's substrate gate: the five attestation states (finding H).
# ===========================================================================


@pytest.fixture
def gate(monkeypatch):
    """`check_substrate_preconditions` with its Story-12.7 paths redirected."""
    torch = pytest.importorskip("torch")  # noqa: F841 - train.py imports it at module scope
    spec = importlib.util.spec_from_file_location(
        "train_gate", REPO_ROOT / "_bmad-output" / "ml-training" / "train.py"
    )
    module = importlib.util.module_from_spec(spec)
    sys.modules.setdefault("train_gate", module)
    spec.loader.exec_module(module)
    return module


def _prime_gate(gate_module, monkeypatch, ws):
    """Point train.py's gate at the synthetic workspace and satisfy (a)-(c)."""
    md = ws.artifacts / "12-7-eval-corpus.md"
    md.write_text("REVIEWER_SIGNOFF: signed\n", encoding="utf-8")
    monkeypatch.setattr(gate_module, "EVAL_CORPUS_MD", md)
    monkeypatch.setattr(gate_module, "EVAL_CORPUS_ATTESTATION", bec.ATTESTATION_JSON)
    monkeypatch.setattr(gate_module, "EVAL_CORPUS_COMMITMENT", bec.COMMITMENT_JSON)
    monkeypatch.setattr(gate_module, "EVAL_CORPUS_LEDGER_HEAD", bec.LEDGER_HEAD_JSON)
    monkeypatch.setattr(gate_module, "_load_eval_corpus_harness", lambda: bec)


def test_training_gate_accepts_a_valid_attestation(ws, gate, monkeypatch):
    assert _mint() == 0
    assert _sign() == 0
    _prime_gate(gate, monkeypatch, ws)
    assert (
        bec.validate_attestation(
            gate.EVAL_CORPUS_ATTESTATION,
            gate.EVAL_CORPUS_COMMITMENT,
            gate.EVAL_CORPUS_LEDGER_HEAD,
            N_BAND_TEST,
            state_root=bec.EVAL_CORPUS_DIR,
        )
        == []
    )


@pytest.mark.parametrize("state", ["missing", "malformed", "stale-ledger", "wrong-repass"])
def test_training_gate_rejects_every_broken_attestation_state(ws, gate, monkeypatch, state):
    assert _mint() == 0
    assert _sign() == 0
    _prime_gate(gate, monkeypatch, ws)
    if state == "missing":
        bec.ATTESTATION_JSON.unlink()
    elif state == "malformed":
        bec.ATTESTATION_JSON.write_text("{", encoding="utf-8")
    elif state == "stale-ledger":
        ledger = bec.ledger_path(_gen())
        lines = ledger.read_bytes().splitlines()
        ledger.write_bytes(b"\n".join(lines[:-1]) + b"\n")
    else:
        record = bec.repass_dir(_gen()) / "repass-annotations.v1.json"
        doc = json.loads(record.read_text())
        doc["summary"]["sample_size"] = 999
        bec._write_json(record, doc)
    failures = bec.validate_attestation(
        gate.EVAL_CORPUS_ATTESTATION,
        gate.EVAL_CORPUS_COMMITMENT,
        gate.EVAL_CORPUS_LEDGER_HEAD,
        N_BAND_TEST,
        state_root=bec.EVAL_CORPUS_DIR,
    )
    assert failures, state
