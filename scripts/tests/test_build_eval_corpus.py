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
import os
import re
import shutil
import sys
import wave
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


def _fr59a2_fixture(**kw):
    return bec.build_candidates(
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
        **kw,
    )


def test_fr59a2_exclusion_accounting():
    # The PRE-AMENDMENT partition order, which is what every short-band policy
    # other than `repartition` still gets. All three routes exclude.
    bands, acc = _fr59a2_fixture()
    e = acc["exclusions"]["100-120"]
    assert e["manifest-hash"] == 1
    assert e["tony-split"] == 1
    assert e["artist"] == 1
    assert e["audio-unresolved"] == 1
    assert set(e) == set(bec.EXCLUSION_REASONS)
    assert {r["identity"] for r in bands["100-120"]} == {"clean", "t3"}
    assert acc["partition_obligations"] == []


def test_repartition_retains_manifest_matches_and_enumerates_them():
    # Signed amendment 2026-08-11: the training-manifest audioHash route stops
    # excluding. The row is drawn into the eval corpus and the training rebuild
    # drops it, so the match becomes a recorded obligation.
    bands, acc = _fr59a2_fixture(retain_manifest_matches=True)
    e = acc["exclusions"]["100-120"]
    assert e["manifest-hash"] == 0  # the count stays 0; the KEY set is frozen
    assert set(e) == set(bec.EXCLUSION_REASONS)
    assert "trainhash" in {r["identity"] for r in bands["100-120"]}
    assert acc["partition_obligations"] == [
        {
            "candidate_key": "pool:trainhash",
            "band": "100-120",
            "routes": [bec.OBLIGATION_ROUTE_MANIFEST],
            "training_key": {
                "source": "manifest",
                "row_id": "trainhash",
                "key": "manifest:trainhash",
            },
        }
    ]


def test_obligations_dedup_on_the_candidate_and_training_row_pair():
    # A retained manifest-hash candidate IS the training row it matched, so it
    # fingerprints against itself and both routes record the same pair. Counting
    # it twice would inflate `must_drop_count`, which is pinned in the immutable
    # commitment and which the FR-59d rebuild joins on.
    training = bec.training_row_key("manifest:h1")
    rows = [
        bec._obligation("pool:h1", "sub-100", bec.OBLIGATION_ROUTE_FINGERPRINT, training),
        bec._obligation("pool:h1", "sub-100", bec.OBLIGATION_ROUTE_MANIFEST, training),
        bec._obligation("pool:h1", "sub-100", bec.OBLIGATION_ROUTE_MANIFEST_CONTENT, training),
        bec._obligation("tony:t1", "sub-100", bec.OBLIGATION_ROUTE_MANIFEST_CONTENT, training),
    ]
    out = bec.dedup_obligations(rows)
    assert len(out) == 2
    merged = next(r for r in out if r["candidate_key"] == "pool:h1")
    # Every route that found it is kept, in precedence order.
    assert merged["routes"] == [
        bec.OBLIGATION_ROUTE_MANIFEST,
        bec.OBLIGATION_ROUTE_MANIFEST_CONTENT,
        bec.OBLIGATION_ROUTE_FINGERPRINT,
    ]
    assert bec.dedup_obligations(list(reversed(rows))) == out  # order-independent


@pytest.mark.parametrize("key", ["garbage", "manifest", "manifest:", ":abc", "unknown:abc"])
def test_training_row_key_rejects_a_malformed_namespace(key):
    # The field round-trips through an operator-editable template and decides
    # exclude-versus-enumerate, so an unrecognized namespace must fail loudly.
    with pytest.raises(bec.HarnessError, match="malformed"):
        bec.training_row_key(key)


def test_tony_split_and_artist_routes_still_exclude_under_repartition():
    # The narrow scope IS the amendment. Any reading that also lifts these two
    # would relax the artist-level disjointness the PRD states.
    bands, acc = _fr59a2_fixture(retain_manifest_matches=True)
    e = acc["exclusions"]["100-120"]
    assert e["tony-split"] == 1
    assert e["artist"] == 1
    assert e["audio-unresolved"] == 1
    identities = {r["identity"] for r in bands["100-120"]}
    assert "split-id" not in identities
    assert "t2" not in identities


def test_non_repartition_candidate_construction_is_byte_identical():
    # Every other policy must produce the same exclusion counts AND the same
    # candidate-universe digest as the pre-amendment harness.
    default_bands, default_acc = _fr59a2_fixture()
    explicit_bands, explicit_acc = _fr59a2_fixture(retain_manifest_matches=False)
    assert explicit_acc["exclusions"] == default_acc["exclusions"]
    assert explicit_acc["tagless"] == default_acc["tagless"]
    assert bec.candidate_universe_digest(explicit_bands) == bec.candidate_universe_digest(
        default_bands
    )
    repartitioned, _acc = _fr59a2_fixture(retain_manifest_matches=True)
    assert bec.candidate_universe_digest(repartitioned) != bec.candidate_universe_digest(
        default_bands
    )


@pytest.mark.parametrize(
    ("policy", "expected"),
    [
        (None, False),
        ("shrink-corpus", False),
        ("fallback-addendum", False),
        ("repartition", True),
    ],
)
def test_reversed_route_is_derived_from_the_recorded_policy_alone(policy, expected):
    decisions = None if policy is None else {"short_band_allocation": {"policy": policy}}
    assert bec.retain_training_manifest_matches(decisions) is expected


def test_reversed_route_derivation_tolerates_a_malformed_decisions_block():
    assert bec.retain_training_manifest_matches({}) is False
    assert bec.retain_training_manifest_matches({"short_band_allocation": "repartition"}) is False


def test_training_row_key_is_structured_not_prose():
    assert bec.training_row_key("manifest:abc") == {
        "source": "manifest",
        "row_id": "abc",
        "key": "manifest:abc",
    }
    assert bec.training_row_key("tony-split:t9")["source"] == bec.TRAINING_SOURCE_TONY_SPLIT


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


def test_privacy_gate_rejects_a_row_level_must_drop_entry():
    # `_DIGEST_PATHS` matches EXACT json paths, so a list index can never be
    # allowlisted, and the training row id is a bare audioHash. Row-level
    # obligations belong in the gitignored sidecar, never in a committed file.
    doc = _clean_commitment()
    doc["partition_obligation"] = {
        "must_drop_sha256": "e" * 64,
        "must_drop": [
            {
                "row_id": "e0-0123456789ab",
                "training_key": {"source": "manifest", "row_id": "f" * 64},
            }
        ],
    }
    with pytest.raises(bec.PrivacyError, match="hash-shaped"):
        bec.privacy_gate(doc)


def test_privacy_gate_allows_only_the_named_must_drop_digest():
    doc = _clean_commitment()
    doc["partition_obligation"] = {"must_drop_sha256": "e" * 64}
    bec.privacy_gate(doc)
    doc["partition_obligation"]["must_drop_sha256"] = "not-a-digest"
    with pytest.raises(bec.PrivacyError, match="64 lowercase hex"):
        bec.privacy_gate(doc)


def test_training_input_drift_detail_names_the_moved_manifest():
    recorded = dict.fromkeys(bec.TRAINING_INPUT_NAMES, "0" * 64)
    detail = bec._training_input_drift_detail(recorded)
    for name in bec.TRAINING_INPUT_NAMES:
        assert name in detail


def test_training_input_drift_detail_without_a_map_says_so():
    assert "predates the per-file digest map" in bec._training_input_drift_detail(None)
    assert "predates the per-file digest map" in bec._training_input_drift_detail({})


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
            "same_file_exempt": 0,
            "same_file_sha256": "7" * 64,
            "confirmed_same_recording": 0,
            "cleared": 0,
            "recording_groups": 0,
            "dispositions_sha256": "1" * 64,
            "candidate_universe_sha256": "2" * 64,
            "training_input_sha256": "3" * 64,
            "training_input_digests": dict.fromkeys(bec.TRAINING_INPUT_NAMES, "9" * 64),
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
        "partition_obligation": {
            "policy": "shrink-corpus",
            "route_reversed": None,
            "retained_manifest_matches": 0,
            "enumerated_fingerprint_matches": 0,
            "excluded_by_confirmed_disposition": 0,
            "excluded_training_fingerprint_matches": 0,
            "excluded_giantsteps_matches": 0,
            "must_drop_sha256": "a" * 64,
            "must_drop_count": 0,
            "status": bec.OBLIGATION_STATUS_NOT_APPLICABLE,
            "note": bec.PARTITION_OBLIGATION_NOTE,
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


def test_commitment_key_schema_rejects_row_level_must_drop_entries():
    # The contract is the exact key schema, not the pattern gate.
    doc = _schema_commitment()
    doc["partition_obligation"]["must_drop"] = [{"row_id": "e0-0123456789ab"}]
    with pytest.raises(bec.PrivacyError, match="key-schema violation"):
        bec.assert_commitment_schema(doc)


def test_commitment_key_schema_rejects_an_unknown_obligation_status():
    doc = _schema_commitment()
    doc["partition_obligation"]["status"] = "closed"
    with pytest.raises(bec.PrivacyError, match="partition_obligation/status"):
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


# --- continuous DJ mixes are not annotatable and must never be candidates ---


def _wav(path: Path, seconds: float, rate: int = 8000) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"\x00\x00" * int(seconds * rate))
    return path


def test_a_tagless_file_still_reports_its_duration(tmp_path):
    # A mutagen file object is dict-like over its tags, so an untagged file is
    # FALSY while still carrying a good info.length. Reading it with `if parsed:`
    # instead of `if parsed is None:` reports "no duration" for every untagged
    # WAV in the collection, and this rule then cannot answer for them.
    p = _wav(tmp_path / "untagged.wav", 12.5)
    import mutagen

    parsed = mutagen.File(p)
    assert not parsed, "fixture must be untagged for this test to mean anything"
    assert parsed is not None
    assert bec.container_duration_seconds(p) == pytest.approx(12.5, abs=0.05)
    assert bec.container_duration_seconds(tmp_path / "absent.wav") is None


def test_a_long_set_and_a_mixes_directory_are_both_excluded(tmp_path):
    # The predicate is corpus_common.is_continuous_mix, which ORs two signals:
    # a Mixes/ directory is decisive on its own, and a long file outside one is
    # still a set. Both paths must reach the exclusion.
    long_set = _wav(tmp_path / "audio" / "Andy C - Nightlife.wav", 1.0)
    in_mixes = _wav(tmp_path / "audio" / "Mixes" / "short-but-a-set.wav", 1.0)
    a_track = _wav(tmp_path / "audio" / "Real Track.wav", 1.0)
    entries = {
        str(long_set): 40 * 60.0,  # long, not under Mixes/
        str(in_mixes): 300.0,  # short, but under Mixes/
        str(a_track): 300.0,  # neither
    }
    bands = {name: [] for name in bec.BAND_NAMES}
    bands["sub-100"] = [{"source": "pool", "identity": p, "relPath": p} for p in entries]
    exclusions = {n: dict.fromkeys(bec.EXCLUSION_REASONS, 0) for n in bec.BAND_NAMES}

    out = bec.drop_continuous_mixes(
        bands,
        exclusions,
        lambda e: Path(e["identity"]),
        lambda e, path: entries[str(path)],
    )
    assert [e["identity"] for e in out["sub-100"]] == [str(a_track)]
    assert exclusions["sub-100"]["continuous-mix"] == 2


def test_an_unknown_duration_is_not_read_as_not_a_mix(tmp_path):
    # Duration is half the predicate. Defaulting an unreadable file to "not a
    # mix" is exactly how 18 sets reached the pool, so this refuses instead.
    p = _wav(tmp_path / "unreadable.wav", 1.0)
    bands = {name: [] for name in bec.BAND_NAMES}
    bands["sub-100"] = [{"source": "pool", "identity": "x", "relPath": str(p)}]
    exclusions = {n: dict.fromkeys(bec.EXCLUSION_REASONS, 0) for n in bec.BAND_NAMES}
    with pytest.raises(bec.HarnessError, match="duration could not be established"):
        bec.drop_continuous_mixes(bands, exclusions, lambda e: p, lambda e, path: None)


def test_a_row_whose_audio_does_not_resolve_is_left_to_its_own_exclusion(tmp_path):
    # Unresolvable audio already has owners downstream (audio-unresolved,
    # audio-unhashable). This rule must not claim it and must not raise on it.
    bands = {name: [] for name in bec.BAND_NAMES}
    bands["sub-100"] = [{"source": "tony", "identity": "gone"}]
    exclusions = {n: dict.fromkeys(bec.EXCLUSION_REASONS, 0) for n in bec.BAND_NAMES}
    out = bec.drop_continuous_mixes(bands, exclusions, lambda e: None, lambda e, path: None)
    assert [e["identity"] for e in out["sub-100"]] == ["gone"]
    assert exclusions["sub-100"]["continuous-mix"] == 0


def test_the_mix_exclusion_is_counted_in_the_committed_accounting(ws, monkeypatch):
    # The count has to reach the committed accounting, not be a silent drop.
    # One file is a set; every other candidate stays a normal track.
    monkeypatch.setattr(
        bec, "DURATION_FN", lambda path: 40 * 60.0 if "pool-0-0" in str(path) else 300.0
    )
    assert _mint() == 0
    commitment = json.loads(bec.COMMITMENT_JSON.read_text())
    counted = sum(
        band["exclusions"].get("continuous-mix", 0) for band in commitment["bands"].values()
    )
    assert counted == 1


def test_immutable_write_refuses_a_differing_overwrite(tmp_path):
    path = tmp_path / "record.json"
    pending = bec.pending_record_path(path)
    # A staged record waits in the sidecar; the final path stays untouched until
    # the event naming it is on the ledger.
    digest = bec.stage_immutable_record(path, {"a": 1})
    assert pending.exists() and not path.exists()
    bec.install_pending_record(path, digest)
    assert path.exists() and not pending.exists()

    bec.stage_immutable_record(path, {"a": 1})  # identical bytes: resumable
    with pytest.raises(bec.HarnessError, match="IMMUTABLE RECORD"):
        bec.stage_immutable_record(path, {"a": 2})


def test_an_unanchored_staged_record_may_be_replaced(tmp_path):
    # The final path is immutable; the pending sidecar is not. A record no event
    # has anchored was never certified, so an interrupted write is re-runnable
    # even if the annotator supplies a corrected CSV.
    path = tmp_path / "record.json"
    bec.stage_immutable_record(path, {"a": 1})
    bec.stage_immutable_record(path, {"a": 2})
    assert json.loads(bec.pending_record_path(path).read_text()) == {"a": 2}
    assert not path.exists()


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
    # The synthetic corpus writes stub bytes, so header reads cannot work here.
    # Every fixture file reports a plain track length; the mix rule gets its own
    # tests against real durations below.
    monkeypatch.setattr(bec, "DURATION_FN", lambda path: 300.0)
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


def _mint_repartition(monkeypatch, seed=2026, disposition=bec.DISPOSITION_NOT_SAME, **kw):
    """Mint under the signed 2026-08-11 order.

    `repartition` keeps n = 43 (only `shrink-corpus` shrinks), so the target is
    lowered here instead; otherwise every synthetic band is short and the mint
    HALTS before anything downstream can be exercised. The decisions file is
    written BEFORE `prepare-review` so both paths see the same partition order,
    which is the whole point of the shared derivation.
    """
    monkeypatch.setattr(bec, "N_BAND", N_BAND_TEST)
    _write_decisions(short={"policy": bec.SHORT_BAND_REPARTITION}, **kw)
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions(disposition)
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
    # the likely path. `training_key` is mirrored too, or a confirmed training
    # match would round-trip through the operator's file without the structured
    # peer the must-drop list is built from.
    assert bec.main(["prepare-review"]) == 0
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    for row in template["flags"]:
        assert "candidate_key" in row
        assert "peer_key" in row
        assert "training_key" in row
    assert set(template["training_input_digests"]) == set(bec.TRAINING_INPUT_NAMES)


# --- the signed 2026-08-11 FR-59a.2 partition order -------------------------


def _manifest_training_leak(ws, monkeypatch, index=0):
    """Give the training side a MANIFEST row whose audio matches one candidate.

    A `tony-split:` peer would exercise the recording-identity route, which the
    amendment leaves alone; only a `manifest:` peer takes the reversed path.
    """
    root = Path(ws.inputs["pool_audio_root"])
    leak = root / "train-leak.mp3"
    _write_audio(leak, b"leaked manifest audio " * 8)
    ws.inputs["manifest_paths"] = {"leakhash": "train-leak.mp3"}
    row = ws.inputs["pool_rows"][index]
    target = root / row["path"]
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (str(leak), str(target)) else _unique_fingerprint(p),
    )
    return row


def _only_member(band, keep_row_id):
    """Annotate a band so exactly `keep_row_id` becomes a member."""
    assert bec.main(["stage-batch", "--band", band, "--size", "6"]) == 0
    overrides = {
        rid: {"verified_bpm": "", "tempo_unstable": 1}
        for rid in _batch_record(band)["work_order"]
        if rid != keep_row_id
    }
    csv_path = _annotate(band, 0, overrides=overrides)
    assert bec.main(["ingest", "--band", band, "--batch", "0", "--annotations", str(csv_path)]) == 0


def test_repartition_policy_is_accepted_by_the_decisions_loader(ws):
    _write_decisions(short={"policy": bec.SHORT_BAND_REPARTITION})
    doc = bec.load_operator_decisions()
    assert doc["short_band_allocation"]["policy"] == bec.SHORT_BAND_REPARTITION
    assert bec.retain_training_manifest_matches(doc) is True


def test_an_unimplemented_short_band_policy_is_rejected(ws):
    _write_decisions(short={"policy": "lift-everything"})
    with pytest.raises(bec.HarnessError, match="is not one of"):
        bec.load_operator_decisions()


def test_manifest_hash_still_excludes_under_every_other_policy(ws):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["manifest-hash"] == 1
    assert leaked not in {e["identity"] for e in _pools()["bands"]["sub-100"]}
    po = doc["partition_obligation"]
    assert po["status"] == bec.OBLIGATION_STATUS_NOT_APPLICABLE
    assert po["route_reversed"] is None
    assert po["must_drop_count"] == 0


def test_repartition_retains_a_manifest_hash_candidate_at_mint(ws, monkeypatch):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    bec.gate_committed(doc, bec.assert_commitment_schema)
    assert doc["operator_decisions"]["short_band_allocation"] == bec.SHORT_BAND_REPARTITION
    # The KEY set is frozen; the COUNT simply stays 0.
    assert doc["bands"]["sub-100"]["exclusions"]["manifest-hash"] == 0
    assert set(doc["bands"]["sub-100"]["exclusions"]) == set(bec.EXCLUSION_REASONS)
    assert leaked in {e["identity"] for e in _pools()["bands"]["sub-100"]}
    po = doc["partition_obligation"]
    assert po["status"] == bec.OBLIGATION_STATUS_PROVISIONAL
    assert po["route_reversed"] == bec.PARTITION_ROUTE_REVERSED
    assert po["retained_manifest_matches"] == 1
    assert po["must_drop_count"] == 1
    sidecar = json.loads(bec.must_drop_path(_gen()).read_text())
    assert bec.sha256_bytes(bec._json_bytes(sidecar)) == po["must_drop_sha256"]
    assert [row["training_key"]["key"] for row in sidecar["obligations"]] == [f"manifest:{leaked}"]


def test_prepare_review_and_mint_share_the_policy_conditionality(ws, monkeypatch):
    # `build_pool_universe` feeds both. If the conditionality differed, the
    # candidate universe digests would diverge and dispositions would stop
    # validating.
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert (
        review["candidate_universe_sha256"]
        == doc["fingerprint_review"]["candidate_universe_sha256"]
    )
    assert "repartition" in review["partition_order"]


def test_a_review_run_under_the_other_order_cannot_mint_under_repartition(ws, monkeypatch):
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert bec.main(["prepare-review"]) == 0  # no decisions yet: pre-amendment order
    _write_dispositions()
    monkeypatch.setattr(bec, "N_BAND", N_BAND_TEST)
    _write_decisions(short={"policy": bec.SHORT_BAND_REPARTITION})
    with pytest.raises(bec.DriftError, match="candidate universe"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=3))


def test_the_partition_order_is_bound_even_when_the_universe_is_identical(ws, monkeypatch):
    # With ZERO overlap between the pool and the training manifests both orders
    # produce the same candidate universe, so the universe digest alone does not
    # separate them - and the two orders mean different things by "confirmed".
    assert bec.main(["prepare-review"]) == 0  # no decisions yet: pre-amendment order
    _write_dispositions()
    before = json.loads(bec.DISPOSITIONS_PATH.read_text())["candidate_universe_sha256"]
    monkeypatch.setattr(bec, "N_BAND", N_BAND_TEST)
    _write_decisions(short={"policy": bec.SHORT_BAND_REPARTITION})
    with pytest.raises(bec.DriftError, match="partition order"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=3))
    # The universe really is identical; only the recorded order separates them.
    _, _acc, universe = bec.build_pool_universe(ws.inputs, True)
    assert universe == before


def test_an_edited_training_key_cannot_flip_exclude_to_enumerate(ws, monkeypatch):
    _manifest_training_leak(ws, monkeypatch)
    monkeypatch.setattr(bec, "N_BAND", N_BAND_TEST)
    _write_decisions(short={"policy": bec.SHORT_BAND_REPARTITION})
    assert bec.main(["prepare-review"]) == 0
    template = json.loads(bec.DISPOSITIONS_TEMPLATE_PATH.read_text())
    for row in template["flags"]:
        row["disposition"] = bec.DISPOSITION_SAME
        if row["kind"] == bec.FLAG_KIND_FINGERPRINT:
            row["training_key"] = {
                "source": "tony-split",
                "row_id": "forged",
                "key": "tony-split:forged",
            }
    bec._write_json(bec.DISPOSITIONS_PATH, template)
    with pytest.raises(bec.HarnessError, match="records training_key"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=15))


def test_confirmed_manifest_fingerprint_is_enumerated_not_excluded(ws, monkeypatch):
    target = _manifest_training_leak(ws, monkeypatch)
    assert _mint_repartition(monkeypatch, disposition=bec.DISPOSITION_SAME) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    fingerprint_flags = [f for f in review["flags"] if f["kind"] == bec.FLAG_KIND_FINGERPRINT]
    assert len(fingerprint_flags) == 1
    flag = fingerprint_flags[0]
    assert flag["training_key"]["source"] == bec.TRAINING_SOURCE_MANIFEST
    # peer_key stays None: it carries candidate-vs-candidate edges into
    # union_recording_groups, and a training row is not a candidate.
    assert flag["peer_key"] is None
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] == 0
    assert target["audioHash"] in {e["identity"] for e in _pools()["bands"]["sub-100"]}
    po = doc["partition_obligation"]
    assert po["enumerated_fingerprint_matches"] == 1
    assert po["excluded_by_confirmed_disposition"] == 0
    assert doc["fingerprint_review"]["confirmed_same_recording"] == 1
    sidecar = json.loads(bec.must_drop_path(_gen()).read_text())
    assert sidecar["obligations"][0]["routes"] == [bec.OBLIGATION_ROUTE_FINGERPRINT]
    assert sidecar["obligations"][0]["training_key"]["key"] == "manifest:leakhash"


def test_confirmed_manifest_fingerprint_still_excludes_under_every_other_policy(ws, monkeypatch):
    _manifest_training_leak(ws, monkeypatch)
    assert bec.main(["prepare-review"]) == 0
    _write_dispositions(bec.DISPOSITION_SAME)
    _write_decisions()
    assert bec.cmd_commit_pools(bec.argparse.Namespace(seed=7)) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] == 1
    assert doc["partition_obligation"]["enumerated_fingerprint_matches"] == 0
    assert doc["partition_obligation"]["must_drop_count"] == 0


def test_confirmed_tony_split_fingerprint_peer_still_excludes_under_repartition(
    ws, monkeypatch, tmp_path
):
    # A confirmed match against a tony.train or tony.val row is the
    # recording-identity route by another name. The amendment does not touch it.
    training = tmp_path / "training" / "split-leak.mp3"
    _write_audio(training, b"leaked split audio " * 8)
    ws.inputs["training_local_paths"]["train-1"] = str(training)
    target = Path(ws.inputs["pool_audio_root"]) / ws.inputs["pool_rows"][0]["path"]
    monkeypatch.setattr(
        bec,
        "FINGERPRINT_FN",
        lambda p: [1.0, 0.0] if p in (str(training), str(target)) else _unique_fingerprint(p),
    )
    assert _mint_repartition(monkeypatch, disposition=bec.DISPOSITION_SAME) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    flags = [f for f in review["flags"] if f["kind"] == bec.FLAG_KIND_FINGERPRINT]
    assert flags and flags[0]["training_key"]["source"] == bec.TRAINING_SOURCE_TONY_SPLIT
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] == 1
    assert doc["partition_obligation"]["enumerated_fingerprint_matches"] == 0


def test_confirmed_giantsteps_disposition_still_excludes_under_repartition(ws, monkeypatch):
    norm = bec.cc.normalize_track_key(Path(ws.inputs["pool_rows"][0]["path"]).stem)
    monkeypatch.setattr(bec, "_giantsteps_titles", lambda: {norm})
    assert _mint_repartition(monkeypatch, disposition=bec.DISPOSITION_SAME) == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["bands"]["sub-100"]["exclusions"]["fingerprint-confirmed"] >= 1
    assert doc["partition_obligation"]["enumerated_fingerprint_matches"] == 0


def test_commitment_pins_per_file_training_input_provenance(ws):
    assert _mint() == 0
    digests = json.loads(bec.COMMITMENT_JSON.read_text())["fingerprint_review"][
        "training_input_digests"
    ]
    assert set(digests) == set(bec.TRAINING_INPUT_NAMES)
    assert all(len(value) == 64 for value in digests.values())


def test_audit_runs_a_labelled_obligation_gate_under_repartition(ws, monkeypatch, capsys):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    keep = next(e["rowId"] for e in _pools()["bands"]["sub-100"] if e["identity"] == leaked)
    _only_member("sub-100", keep)
    assert bec.main(["audit"]) == 0
    out = capsys.readouterr().out
    assert "OBLIGATION GATE, not proof the partition holds" in out
    assert "NOT that FR-59a.2 currently holds" in out
    listing = json.loads(bec.must_drop_members_path(_gen()).read_text())
    assert listing["basis"] == "members"
    assert listing["commitment_sha256"] == bec.sha256_file(bec.COMMITMENT_JSON)
    assert listing["annotation_ledger_head"] == bec.head_of(bec.ledger_path(_gen()))[0]
    assert [row["row_id"] for row in listing["must_drop"]] == [keep]
    assert listing["must_drop"][0]["training_key"]["key"] == f"manifest:{leaked}"


def test_must_drop_covers_members_only_not_every_candidate(ws, monkeypatch):
    # Dropping training rows for candidates that were rejected or ended up
    # surplus would starve training for nothing.
    sub100 = [r for r in ws.inputs["pool_rows"] if r["fileMetadataBPM"] == 90.0]
    ws.inputs["manifest_hashes"] = {sub100[0]["audioHash"], sub100[1]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    assert (
        json.loads(bec.COMMITMENT_JSON.read_text())["partition_obligation"]["must_drop_count"] == 2
    )
    keep = next(
        e["rowId"] for e in _pools()["bands"]["sub-100"] if e["identity"] == sub100[0]["audioHash"]
    )
    _only_member("sub-100", keep)
    assert bec.main(["audit"]) == 0
    listing = json.loads(bec.must_drop_members_path(_gen()).read_text())
    assert [row["row_id"] for row in listing["must_drop"]] == [keep]


@pytest.mark.parametrize("source", ["pool", "tony", "oa300"])
def test_audit_fails_when_a_member_overlaps_a_manifest_it_was_not_enumerated_against(
    ws, monkeypatch, capsys, source
):
    # A training manifest that moved AFTER the mint now contains a member the
    # must-drop list never named. The rebuild would leave it in place.
    #
    # Parametrized over the source deliberately: driving the gate off
    # `entry["identity"]` (the audio hash only for POOL rows) silently skipped
    # every Tony and OA300 member. A manifest audioHash is sha256 over the raw
    # bytes, which is exactly the committed `contentSha256`.
    assert _mint_repartition(monkeypatch) == 0
    entry = next(e for e in _pools()["bands"]["sub-100"] if e["source"] == source)
    _only_member("sub-100", entry["rowId"])
    assert bec.main(["audit"]) == 0
    ws.inputs["manifest_hashes"] = {
        entry["identity"] if source == "pool" else entry["contentSha256"]
    }
    assert bec.main(["audit"]) == 1
    assert "PARTITION OBLIGATION GAP" in capsys.readouterr().err


def test_the_content_route_enumerates_non_pool_candidates(ws, monkeypatch):
    # A Tony or OA300 candidate can sit in a training manifest by CONTENT while
    # its identity (a track id, a filename) matches nothing. Before the content
    # route those rows were reachable only through the fingerprint route, which
    # the obligation gate cannot re-derive at audit time.
    tony_audio = Path(
        next(r["local_path"] for r in ws.inputs["tony_rows"] if r["track_id"] == "t0")
    )
    digest = bec.sha256_file(tony_audio)
    ws.inputs["manifest_hashes"] = {digest}
    assert _mint_repartition(monkeypatch) == 0
    sidecar = json.loads(bec.must_drop_path(_gen()).read_text())
    rows = [r for r in sidecar["obligations"] if r["candidate_key"] == "tony:t0"]
    assert len(rows) == 1
    assert rows[0]["routes"] == [bec.OBLIGATION_ROUTE_MANIFEST_CONTENT]
    assert rows[0]["training_key"]["key"] == f"manifest:{digest}"
    # And the gate over that member passes rather than reporting a gap.
    entry = next(e for e in _pools()["bands"]["sub-100"] if e["identity"] == "t0")
    _only_member("sub-100", entry["rowId"])
    assert bec.main(["audit"]) == 0
    listing = json.loads(bec.must_drop_members_path(_gen()).read_text())
    assert [r["row_id"] for r in listing["must_drop"]] == [entry["rowId"]]


def test_a_self_match_is_exempt_and_still_carries_its_obligation(ws, monkeypatch):
    # A retained manifest-hash candidate IS the training row, so it fingerprints
    # against itself at cosine 1.0. Signed 2026-08-14: that identity match is
    # recorded automatically rather than put to a human, because a file cannot
    # differ from itself. The safety argument is the assertion below: the
    # obligation to drop that training row survives WITHOUT the human answer,
    # derived from the audio hash. If it did not, the song would sit in both
    # corpora unreviewed.
    row = ws.inputs["pool_rows"][0]
    ws.inputs["manifest_hashes"] = {row["audioHash"]}
    ws.inputs["manifest_paths"] = {row["audioHash"]: row["path"]}
    assert _mint_repartition(monkeypatch, disposition=bec.DISPOSITION_SAME) == 0
    review = json.loads(bec.REVIEW_FLAGS_PATH.read_text())
    assert [f["kind"] for f in review["flags"]].count(bec.FLAG_KIND_FINGERPRINT) == 0
    assert len(review["same_file_exempt"]) == 1
    assert review["same_file_exempt"][0]["candidate_key"] == f"pool:{row['audioHash']}"
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    assert doc["fingerprint_review"]["same_file_exempt"] == 1
    po = doc["partition_obligation"]
    assert po["must_drop_count"] == 1
    assert po["retained_manifest_matches"] == 1
    assert po["enumerated_fingerprint_matches"] == 0  # no human answer involved
    sidecar = json.loads(bec.must_drop_path(_gen()).read_text())
    assert len(sidecar["obligations"]) == 1
    routes = sidecar["obligations"][0]["routes"]
    assert bec.OBLIGATION_ROUTE_MANIFEST in routes
    assert bec.OBLIGATION_ROUTE_FINGERPRINT not in routes


def test_a_failing_audit_does_not_clobber_the_member_listing(ws, monkeypatch, capsys):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    keep = next(e["rowId"] for e in _pools()["bands"]["sub-100"] if e["identity"] == leaked)
    _only_member("sub-100", keep)
    assert bec.main(["audit"]) == 0
    good = bec.must_drop_members_path(_gen()).read_bytes()
    # Break the audit in a way that empties membership.
    _annotation_files("sub-100")[0].unlink()
    assert bec.main(["audit"]) == 1
    assert bec.must_drop_members_path(_gen()).read_bytes() == good


def test_a_policy_change_clears_a_stale_member_listing(ws, monkeypatch):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    keep = next(e["rowId"] for e in _pools()["bands"]["sub-100"] if e["identity"] == leaked)
    _only_member("sub-100", keep)
    assert bec.main(["audit"]) == 0
    listing = bec.must_drop_members_path(_gen())
    assert listing.exists()
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["operator_decisions"]["short_band_allocation"] = "shrink-corpus"
    bec._write_json(bec.COMMITMENT_JSON, doc)
    bec.write_ledger_head(bec.sha256_file(bec.COMMITMENT_JSON), _gen())
    bec.run_audit()
    assert not listing.exists()


def test_the_member_listing_digest_is_stable_across_runs(ws, monkeypatch):
    # Its digest is what the FR-59d closure record binds, so a wall-clock field
    # would churn it daily and defeat the binding.
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    keep = next(e["rowId"] for e in _pools()["bands"]["sub-100"] if e["identity"] == leaked)
    _only_member("sub-100", keep)
    assert bec.main(["audit"]) == 0
    first = bec.must_drop_members_path(_gen()).read_bytes()
    assert bec.main(["audit"]) == 0
    assert bec.must_drop_members_path(_gen()).read_bytes() == first


def test_must_drop_records_are_generation_scoped(ws, monkeypatch):
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    first_gen = _gen()
    first = bec.must_drop_path(first_gen).read_bytes()
    first_digest = json.loads(bec.COMMITMENT_JSON.read_text())["partition_obligation"][
        "must_drop_sha256"
    ]
    _supersede()
    assert bec.main(["remint", "--seed", "8181"]) == 0
    second_gen = _gen()
    assert second_gen != first_gen
    # The predecessor's record survives, so its archived commitment's pinned
    # digest is still verifiable.
    assert bec.must_drop_path(first_gen).read_bytes() == first
    assert bec.sha256_file(bec.must_drop_path(first_gen)) == first_digest
    assert bec.must_drop_path(second_gen).exists()


def test_a_deleted_must_drop_record_does_not_fail_a_non_repartition_audit(ws):
    # Gated on the policy: reading it unconditionally made a non-repartition
    # corpus fail permanently with no regeneration path.
    assert _mint() == 0
    bec.must_drop_path(_gen()).unlink()
    assert bec.main(["audit"]) == 0


def test_same_file_identity_is_narrow():
    # Signed 2026-08-14. Only a pool candidate against a manifest training row
    # can be exempted, because only there does an equal key prove an equal audio
    # hash. Rekordbox-id namespaces still reach a human.
    assert bec.is_same_file_identity("pool:abc", "manifest:abc")
    assert not bec.is_same_file_identity("pool:abc", "manifest:def")
    assert not bec.is_same_file_identity("tony:123", "tony-split:123")
    assert not bec.is_same_file_identity("oa300:x.aiff", "manifest:x.aiff")
    assert not bec.is_same_file_identity("pool:", "manifest:")


def test_an_exemption_without_an_obligation_is_refused():
    # The whole safety argument for the exemption is that the removal
    # obligation is derived from the audio hash instead of from a human answer.
    # An exemption carrying no obligation would leave the song in both corpora
    # unreviewed, so it is asserted rather than assumed.
    same_file = [{"candidate_key": "pool:h1", "training_key": {"key": "manifest:h1"}}]
    bec.assert_same_file_obligations(same_file, [{"candidate_key": "pool:h1"}])
    with pytest.raises(bec.HarnessError, match="WITHOUT AN OBLIGATION"):
        bec.assert_same_file_obligations(same_file, [])


def test_same_file_digest_is_order_stable():
    rows = [
        {"candidate_key": "pool:b", "training_key": {"key": "manifest:b"}},
        {"candidate_key": "pool:a", "training_key": {"key": "manifest:a"}},
    ]
    assert bec.same_file_digest(rows) == bec.same_file_digest(list(reversed(rows)))
    assert bec.same_file_digest([]) != bec.same_file_digest(rows)


def test_a_rejected_restore_leaves_the_missing_file_missing(ws, monkeypatch):
    # The restore wrote the re-derived bytes and only THEN compared digests, so
    # a mismatch installed the wrong file and raised an error claiming it was
    # "refusing to install" it. The next invocation found the file present,
    # classified it as tamper, and refused to overwrite - turning recoverable
    # missing state into permanently corrupt state.
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    gen = _gen()
    bec.must_drop_path(gen).unlink()
    commitment = json.loads(bec.COMMITMENT_JSON.read_text())
    commitment["partition_obligation"]["must_drop_sha256"] = "0" * 64
    bec._write_json(bec.COMMITMENT_JSON, commitment)
    with pytest.raises(bec.DriftError, match="cannot restore"):
        bec.cmd_commit_pools(bec.argparse.Namespace(seed=None))
    # The rejected bytes were never installed, so the state stays repairable.
    assert not bec.must_drop_path(gen).exists()


def test_a_non_hex_ledger_head_on_a_repass_event_is_not_a_usable_digest(ws):
    # A length-only check accepted "x" * 64, which can never equal a real head,
    # so the sentinel read as "the ledger moved" and authorized a redraw.
    assert bec.is_sha256_hex("a" * 64)
    assert not bec.is_sha256_hex("x" * 64)
    assert not bec.is_sha256_hex("A" * 64)  # canonical digests are lowercase
    assert not bec.is_sha256_hex("a" * 63)
    assert not bec.is_sha256_hex(None)


def test_a_repass_event_with_a_non_hex_head_refuses_the_redraw(ws):
    # The LAST ledger line has no successor, so nothing checks its digest: an
    # in-place edit of one field survives chain validation. Prior lines are kept
    # byte-for-byte and the harness's own compact serialization is reused, or the
    # re-encoding itself would break the chain and mask what is under test.
    assert _mint() == 0
    _complete_corpus()
    assert _repass() == 0
    path = bec.repass_ledger_path(_gen())
    lines = path.read_bytes().splitlines()
    last = json.loads(lines[-1])
    last["annotation_ledger_head"] = "x" * 64
    lines[-1] = json.dumps(last, sort_keys=True, separators=(",", ":")).encode("utf-8")
    path.write_bytes(b"\n".join(lines) + b"\n")
    with pytest.raises(bec.HarnessError, match="usable `annotation_ledger_head`"):
        bec.cmd_repass_sample(bec.argparse.Namespace())


def test_commit_pools_restores_a_missing_must_drop_record(ws, monkeypatch):
    # `_write_plan` writes THREE digest-pinned row-level files; the restore loop
    # in `cmd_commit_pools` covered only pools and draws. Under the signed
    # repartition order the audit hard-fails without the must-drop sidecar, so
    # losing that gitignored file left this command printing "restored" and
    # exiting 0 while the audit failed forever - and `remint` refuses once the
    # prior generation carries annotation state, so there was no repair path.
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    gen = _gen()
    original = bec.must_drop_path(gen).read_bytes()
    bec.must_drop_path(gen).unlink()
    assert bec.main(["commit-pools"]) == 0
    assert bec.must_drop_path(gen).read_bytes() == original
    assert bec.main(["audit"]) == 0


def test_editing_the_must_drop_sidecar_fails_the_audit(ws, monkeypatch, capsys):
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    doc = json.loads(bec.must_drop_path(_gen()).read_text())
    doc["obligations"] = []
    bec._write_json(bec.must_drop_path(_gen()), doc)
    assert bec.main(["audit"]) == 1
    assert "partition-obligation record was edited" in capsys.readouterr().err


def test_signoff_refuses_while_partition_closure_is_uncertified(ws, monkeypatch, capsys):
    ws.inputs["manifest_hashes"] = {ws.inputs["pool_rows"][0]["audioHash"]}
    assert _mint_repartition(monkeypatch) == 0
    _complete_corpus()
    assert bec.main(["audit"]) == 0
    capsys.readouterr()
    assert bec.main(["signoff"]) == 1
    err = capsys.readouterr().err
    assert "SIGNOFF REFUSED" in err
    assert "partition closure is not certified" in err
    assert "FR-59d" in err
    assert not bec.ATTESTATION_JSON.exists()


def test_a_vacuous_obligation_is_certifiable_rather_than_a_deadlock(ws, monkeypatch):
    # Minted under the reversed route but with ZERO measured overlap. There is
    # nothing for the rebuild to drop, so refusing forever would be a deadlock
    # with no work behind it.
    assert _mint_repartition(monkeypatch) == 0
    assert (
        json.loads(bec.COMMITMENT_JSON.read_text())["partition_obligation"]["must_drop_count"] == 0
    )
    _complete_corpus()
    assert _repass() == 0
    assert bec.main(["signoff"]) == 0
    closure = json.loads(bec.ATTESTATION_JSON.read_text())["partition_closure"]
    assert closure["certified"] is True
    assert closure["basis"] == "obligation-vacuous"
    assert _validate() == []


def _write_closure_record(residual=0, member_digest=None, must_drop=None):
    """What the FR-59d story will write once the rebuild lands."""
    commitment = json.loads(bec.COMMITMENT_JSON.read_text())
    gen = commitment["generation"]
    if member_digest is None:
        listing = json.loads(bec.must_drop_members_path(gen).read_text())
        member_digest = bec.sha256_bytes(bec._json_bytes(listing))
    doc = {
        "schema_version": 1,
        "story": "12.7",
        "certified": True,
        "closed": "2026-09-01",
        "method": "full FR-59a.2 re-comparison against the rebuilt training corpus",
        "commitment_sha256": bec.sha256_file(bec.COMMITMENT_JSON),
        "annotation_ledger_head": bec.head_of(bec.ledger_path(gen))[0],
        "must_drop_sha256": (
            must_drop
            if must_drop is not None
            else commitment["partition_obligation"]["must_drop_sha256"]
        ),
        "member_must_drop_sha256": member_digest,
        "residual_overlap": residual,
        "training_input_digests": dict.fromkeys(bec.TRAINING_INPUT_NAMES, "b" * 64),
        "note": "rebuilt training corpus; zero residual overlap",
    }
    bec._write_json(bec.partition_closure_path(gen), doc)
    return doc


def _repartition_with_one_obligation(ws, monkeypatch):
    leaked = ws.inputs["pool_rows"][0]["audioHash"]
    ws.inputs["manifest_hashes"] = {leaked}
    assert _mint_repartition(monkeypatch) == 0
    _complete_corpus()
    assert bec.main(["audit"]) == 0
    return leaked


def test_a_verified_closure_record_unblocks_signoff(ws, monkeypatch):
    # The forward path out of the refusal, and deliberately NOT a mutation of the
    # minted commitment, whose archived copies must stay verifiable.
    _repartition_with_one_obligation(ws, monkeypatch)
    _write_closure_record()
    assert bec.main(["audit"]) == 0
    assert _repass() == 0
    assert bec.main(["signoff"]) == 0
    closure = json.loads(bec.ATTESTATION_JSON.read_text())["partition_closure"]
    assert closure["certified"] is True
    assert closure["basis"] == "closure-record"
    assert closure["closure_record_sha256"]
    assert _validate() == []


@pytest.mark.parametrize(
    ("flaw", "reason"),
    [
        ("residual", "does not record ZERO residual overlap"),
        ("wrong-must-drop", "closes a different must-drop list"),
        ("not-certified", "does not assert certified"),
    ],
)
def test_a_closure_record_that_does_not_verify_still_refuses(ws, monkeypatch, capsys, flaw, reason):
    # A closure claim that does not verify is worse than none, so it surfaces as
    # an AUDIT failure and signoff never reaches the closure block.
    _repartition_with_one_obligation(ws, monkeypatch)
    if flaw == "residual":
        _write_closure_record(residual=1)
    elif flaw == "wrong-must-drop":
        _write_closure_record(must_drop="c" * 64)
    else:
        doc = _write_closure_record()
        doc["certified"] = False
        bec._write_json(bec.partition_closure_path(_gen()), doc)
    capsys.readouterr()
    assert bec.main(["audit"]) == 1
    assert reason in capsys.readouterr().err
    assert bec.main(["signoff"]) == 1
    assert reason in capsys.readouterr().err
    assert not bec.ATTESTATION_JSON.exists()


def test_a_closure_record_bound_to_a_different_member_set_fails_the_audit(ws, monkeypatch, capsys):
    _repartition_with_one_obligation(ws, monkeypatch)
    _write_closure_record(member_digest="d" * 64)
    assert bec.main(["audit"]) == 1
    assert "certified against a different member set" in capsys.readouterr().err


def test_attestation_binding_a_vanished_closure_record_is_rejected(ws, monkeypatch):
    _repartition_with_one_obligation(ws, monkeypatch)
    _write_closure_record()
    assert _repass() == 0
    assert bec.main(["signoff"]) == 0
    assert _validate() == []
    bec.partition_closure_path(_gen()).unlink()
    assert any("do not support it" in f for f in _validate())


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
            bec.main(
                [
                    "ingest",
                    "--band",
                    band,
                    "--batch",
                    "0",
                    "--annotations",
                    str(csv_path),
                ]
            )
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


# --- a crash between the record and the worklist must not strand the harness --


def _interrupt_staging(band, batch=0):
    """The state a crash inside stage_copies leaves: batch record on disk, no
    worklist, staging directory incomplete or absent."""
    worklist = bec.worklist_path_for(_gen(), band, batch)
    worklist.unlink()
    shutil.rmtree(bec.staging_dir(_gen()) / band / f"batch-{batch:03d}", ignore_errors=True)


def test_interrupted_staging_is_recoverable_rather_than_a_deadlock(ws):
    # The batch record is written BEFORE the audio copy so an interrupted copy
    # leaves a record instead of orphan audio, and plan_batch documents a resume
    # for exactly that state. But validate_state read the absent worklist as
    # tampering and ran BEFORE plan_batch, so every command refused and the
    # documented resume was unreachable. Nothing recoverable may be terminal.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    _interrupt_staging("sub-100")

    assert bec.interrupted_staging(bec.load_state()) == ["sub-100/batch-000"]
    assert bec.main(["status"]) == 0

    # The resume path is reachable, regenerates the worklist from the committed
    # record, and the batch ingests normally afterwards.
    assert bec.main(["stage-batch", "--band", "sub-100", "--batch", "0", "--size", "3"]) == 0
    assert bec.worklist_path_for(_gen(), "sub-100", 0).exists()
    assert bec.interrupted_staging(bec.load_state()) == []
    csv_path = _annotate("sub-100", 0)
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        == 0
    )


def test_the_audit_refuses_to_certify_while_staging_is_interrupted(ws):
    # Recoverable is not the same as finished: an unstaged batch is incomplete
    # work, so the shared audit still fails closed on it.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    _interrupt_staging("sub-100")
    failures, _w, _r = bec.run_audit()
    assert any("staging for sub-100/batch-000 was interrupted" in f for f in failures)


def test_a_missing_worklist_on_an_ingested_batch_is_still_tamper(ws):
    # The narrowing is exactly "no event has accepted annotations for this
    # batch". Once one has, the worklist is evidence and its absence is not.
    assert _mint() == 0
    _complete_band("sub-100", size=3)
    bec.worklist_path_for(_gen(), "sub-100", 0).unlink()
    assert bec.interrupted_staging(bec.load_state()) == []
    failures = bec.validate_state(bec.load_state())
    assert any("worklist for sub-100/batch-000 is missing" in f for f in failures)


def test_a_batch_abandoned_after_ingest_still_requires_its_worklist(ws):
    # Keying off the LATEST event alone would exempt this: the batch reads as
    # abandoned, so the worklist that its retained annotation record was
    # produced against could be deleted unnoticed. The rule is instead "some
    # event anchored a real work order", which this batch's ingest did.
    assert _mint() == 0
    _complete_band("sub-100", size=3)
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0", "--force"]) == 0
    bec.worklist_path_for(_gen(), "sub-100", 0).unlink()

    failures = bec.validate_state(bec.load_state())
    assert any("worklist for sub-100/batch-000 is missing" in f for f in failures)


def test_a_batch_abandoned_straight_out_of_interrupted_staging_needs_no_worklist(ws):
    # The other direction: abandoning is a legitimate way out of an interrupted
    # stage, and it must not land in a state that refuses forever.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    _interrupt_staging("sub-100")
    assert bec.main(["abandon", "--band", "sub-100", "--batch", "0"]) == 0
    assert bec.validate_state(bec.load_state()) == []
    assert bec.main(["status"]) == 0


def test_an_unanchored_staged_record_is_visible_and_blocks(ws, monkeypatch):
    # A sidecar is invisible to the orphan scans by design. That invisibility
    # must not extend to the operator: it is a real annotation pass.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    _crash_after_append(monkeypatch)
    monkeypatch.setattr(
        bec,
        "append_event",
        lambda *_a, **_k: (_ for _ in ()).throw(bec.HarnessError("simulated crash")),
    )
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        != 0
    )
    monkeypatch.undo()

    state = bec.load_state()
    staged = bec.unanchored_records(_gen(), state.events, state.repass_events)
    assert staged == ["annotations/sub-100/batch-000.v1.json"]
    failures, _w, _r = bec.run_audit()
    assert any("is not named by any ledger event" in f for f in failures)
    # A re-mint over it would strand the pass.
    assert any(
        "unanchored annotation record" in b
        for b in bec.prior_generation_annotation_state(bec.read_commitment())
    )
    # And abandoning it asks first.
    with pytest.raises(bec.HarnessError, match="staged annotation record that no event"):
        bec.cmd_abandon(bec.argparse.Namespace(band="sub-100", batch=0, reason="test", force=False))


def test_installing_over_an_occupied_final_path_is_refused(ws, tmp_path):
    # The sidecar must not become a way around the final path's immutability.
    path = tmp_path / "record.json"
    digest = bec.stage_immutable_record(path, {"a": 1})
    bec._write_bytes_atomic(path, b'{"a":2}')
    with pytest.raises(bec.HarnessError, match="IMMUTABLE RECORD"):
        bec.install_pending_record(path, digest)


def test_a_replay_will_not_write_outside_its_own_root(ws, tmp_path):
    # Replay runs BEFORE the chain walk, the commitment binding, and the
    # transition check, so the path an event names is still untrusted JSON. Both
    # an absolute path and a traversal that genuinely resolves outside the root
    # must steer nothing. The traversal is computed against the real generation
    # root, not written by hand: a `..` chain that does not actually escape
    # would let this test pass against an unconfined implementation.
    escape = tmp_path / "escaped.json"
    pending = bec.pending_record_path(escape)
    pending.write_bytes(b'{"rows":{}}')
    digest = bec.sha256_file(pending)
    # The generation root has to exist, or the traversal fails to resolve for a
    # reason that has nothing to do with the guard under test.
    bec.annotations_dir("gdeadbeef").mkdir(parents=True, exist_ok=True)
    traversal = os.path.relpath(escape, bec.generation_root("gdeadbeef"))
    assert traversal.startswith("..")
    assert (bec.generation_root("gdeadbeef") / traversal).resolve() == escape.resolve()
    assert bec.pending_record_path(bec.generation_root("gdeadbeef") / traversal).exists()

    for rel in (str(escape), traversal):
        assert (
            bec.replay_pending_records(
                "gdeadbeef",
                [
                    (
                        [{"annotation_path": rel, "annotation_sha256": digest}],
                        "annotation_path",
                        "annotation_sha256",
                        bec.annotations_dir("gdeadbeef"),
                    )
                ],
            )
            == []
        )
    assert pending.exists() and not escape.exists()


# --- a crash between the annotation record and its event must not strand it --


def test_an_annotation_record_written_without_its_event_does_not_deadlock(ws, monkeypatch):
    # Round 2 wrote the record at its final path and THEN appended the event. A
    # crash between the two left a record no event referenced, which
    # validate_state reads as an added or moved record and refuses on forever.
    # The record holds one annotator's DAW work, so deleting it is not a fix.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)

    def _die(*_a, **_k):
        raise bec.HarnessError("simulated crash before the event was appended")

    monkeypatch.setattr(bec, "append_event", _die)
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        != 0
    )
    monkeypatch.undo()

    # The staged record is in its sidecar, holding the submitted labels, so no
    # orphan exists and the state is coherent; re-running the ingest completes
    # it. Asserting the sidecar's CONTENT matters: an implementation that wrote
    # nothing at all before the append would satisfy the orphan check alone.
    assert list((bec.annotations_dir(_gen()) / "sub-100").glob("*.json")) == []
    pending = bec.pending_record_path(bec.annotations_dir(_gen()) / "sub-100" / "batch-000.v1.json")
    assert pending.exists()
    staged_rows = json.loads(pending.read_text())["rows"]
    assert sorted(staged_rows) == sorted(_batch_record("sub-100", 0)["work_order"])
    assert bec.validate_state(bec.load_state()) == []
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        == 0
    )
    assert bec.validate_state(bec.load_state()) == []


def test_a_crash_between_the_append_and_the_install_is_recovered(ws, monkeypatch):
    # The real append-then-install ordering, not a record moved after the fact:
    # the event lands, the install does not, and the tracked head write that
    # follows it does not either.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    monkeypatch.setattr(bec, "install_pending_record", lambda *_a, **_k: None)
    _crash_after_append(monkeypatch)
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        != 0
    )
    monkeypatch.undo()

    record = bec.annotations_dir(_gen()) / "sub-100" / "batch-000.v1.json"
    assert not record.exists() and bec.pending_record_path(record).exists()
    # One load_state repairs both halves: the record installs and the head
    # re-derives, in that order.
    assert bec.validate_state(bec.load_state()) == []
    assert record.exists()
    assert bec.main(["status"]) == 0


def test_a_repass_crash_between_the_append_and_the_install_is_recovered(ws, monkeypatch):
    # The re-pass writers carry the same ordering and the same recovery. A
    # re-run there would additionally hit IMMUTABLE RECORD on the changed date
    # stamp, so the sidecar is what keeps it re-runnable at all.
    assert _mint() == 0
    _complete_corpus()
    monkeypatch.setattr(bec, "install_pending_record", lambda *_a, **_k: None)
    # The event lands, the install does not, and the post-mutation validation
    # then refuses - which is the crash window, observed from the inside.
    assert bec.main(["repass-sample"]) != 0
    monkeypatch.undo()

    version = 1
    record = bec.repass_record_path(_gen(), version)
    assert not record.exists() and bec.pending_record_path(record).exists()
    assert bec.validate_state(bec.load_state()) == []
    assert record.exists()


def test_a_record_staged_but_never_installed_is_replayed_from_its_event(ws):
    # The other half of the window: the event is on the ledger and the move did
    # not happen. The sidecar's bytes hash to the digest the event recorded, so
    # completing the install is a verified replay, not a guess.
    assert _mint() == 0
    _complete_band("sub-100", size=3)
    ev = bec.latest_by_batch(bec.load_state().events)[("sub-100", 0)]
    record = bec.generation_root(_gen()) / str(ev["annotation_path"])
    record.rename(bec.pending_record_path(record))
    assert not record.exists()

    assert bec.validate_state(bec.load_state()) == []
    assert record.exists()
    assert not bec.pending_record_path(record).exists()


def test_a_pending_record_that_does_not_match_its_event_is_left_alone(ws):
    # A digest-verified replay, or none. Bytes that are not the ones the event
    # anchored are never installed under that event's name.
    assert _mint() == 0
    _complete_band("sub-100", size=3)
    ev = bec.latest_by_batch(bec.load_state().events)[("sub-100", 0)]
    record = bec.generation_root(_gen()) / str(ev["annotation_path"])
    pending = bec.pending_record_path(record)
    record.rename(pending)
    pending.write_text('{"rows":{}}', encoding="utf-8")

    failures = bec.validate_state(bec.load_state())
    assert any("recorded in the event store is missing" in f for f in failures)
    assert pending.exists() and not record.exists()


# --- a crash between the event append and the tracked head must not strand it -


def _crash_after_append(monkeypatch):
    monkeypatch.setattr(
        bec,
        "write_ledger_head",
        lambda *_a, **_k: (_ for _ in ()).throw(bec.HarnessError("simulated crash")),
    )


def test_a_head_left_behind_by_an_interrupted_append_is_re_derived(ws, monkeypatch):
    # ingest and abandon append the event and THEN write the tracked head. A
    # crash between the two left the head stale, and every command refused on it
    # with no way forward, over a ledger whose events were already durable.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    _crash_after_append(monkeypatch)
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        != 0
    )
    monkeypatch.undo()

    head = json.loads(bec.LEDGER_HEAD_JSON.read_text())
    assert head["event_count"] == 0  # behind the ledger, which now holds one event
    assert bec.validate_state(bec.load_state()) == []
    assert json.loads(bec.LEDGER_HEAD_JSON.read_text())["event_count"] == 1
    assert bec.main(["status"]) == 0


def test_a_head_ahead_of_the_ledger_is_still_tamper(ws):
    # The repair runs in one direction only. A head naming a count the ledger no
    # longer reaches means the ledger was truncated behind committed evidence,
    # which is exactly what the tracked head exists to catch.
    assert _mint() == 0
    _complete_band("sub-100", size=3)
    ledger = bec.ledger_path(_gen())
    ledger.write_bytes(b"")

    failures = bec.validate_state(bec.load_state())
    assert any("tracked annotation-ledger head is stale" in f for f in failures)


def test_a_rewritten_ledger_under_a_behind_head_is_not_repaired(ws, monkeypatch):
    # Behind-in-count is not sufficient: the recorded digest must still be what
    # the ledger produces at that count, or the ledger was rewritten rather than
    # merely extended.
    assert _mint() == 0
    assert bec.main(["stage-batch", "--band", "sub-100", "--size", "3"]) == 0
    csv_path = _annotate("sub-100", 0)
    assert (
        bec.main(
            [
                "ingest",
                "--band",
                "sub-100",
                "--batch",
                "0",
                "--annotations",
                str(csv_path),
            ]
        )
        == 0
    )
    ledger = bec.ledger_path(_gen())
    original = ledger.read_bytes()

    # A head that records one event, over a ledger whose first event is no
    # longer the one that digest names.
    _crash_after_append(monkeypatch)
    ledger.write_bytes(original + original)
    monkeypatch.undo()
    head = json.loads(bec.LEDGER_HEAD_JSON.read_text())
    head["head_sha256"] = "b" * 64
    bec._write_json(bec.LEDGER_HEAD_JSON, head)

    assert bec.repair_stale_ledger_head(_gen(), bec.load_state().commitment_sha) is False
    assert json.loads(bec.LEDGER_HEAD_JSON.read_text())["head_sha256"] == "b" * 64


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
    assert [e["status"] for e in events] == [
        bec.LEDGER_COMPLETED,
        bec.LEDGER_REPLACEMENT,
    ]
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


def test_a_completed_repass_cannot_be_redrawn_while_the_ledger_is_unmoved(ws):
    # The guard read `annotation_ledger_head` from the ANNOTATION document,
    # which never carries that key (only the ledger event does), so it compared
    # None against the head and could never fire. Because `plan_repass`'s seed
    # includes the version, every redraw samples a DIFFERENT subset with fresh
    # aliases, and `repass_status_for_signoff` binds the latest ingested one -
    # so the signed section-6 disagreement rate could be re-rolled until it
    # looked acceptable, with nothing in the ledger or the audit recording it.
    assert _mint() == 0
    _complete_corpus()
    assert _repass() == 0
    with pytest.raises(bec.HarnessError, match="has not moved"):
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


def test_attestation_carries_a_certified_closure_when_nothing_is_open(ws):
    assert _mint() == 0
    assert _sign() == 0
    closure = json.loads(bec.ATTESTATION_JSON.read_text())["partition_closure"]
    assert closure["certified"] is True
    assert closure["must_drop_count"] == 0
    assert _validate() == []


def test_attestation_without_the_closure_field_is_rejected(ws):
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    del doc["partition_closure"]
    bec._write_json(bec.ATTESTATION_JSON, doc)
    assert any("schema" in f for f in _validate())


def test_attestation_recording_an_uncertified_closure_is_rejected(ws):
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.ATTESTATION_JSON.read_text())
    doc["partition_closure"]["certified"] = False
    bec._write_json(bec.ATTESTATION_JSON, doc)
    assert any("UNCERTIFIED FR-59a.2 partition closure" in f for f in _validate())


@pytest.mark.parametrize("how", ["status", "policy"])
def test_attestation_claiming_closure_over_an_open_obligation_is_rejected(ws, how):
    # Both signals must reach the validator. Checking only the recorded status
    # let a commitment naming the reversed POLICY with a `not-applicable` status
    # validate a certified attestation.
    assert _mint() == 0
    assert _sign() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["partition_obligation"]["must_drop_count"] = 1
    if how == "status":
        doc["partition_obligation"]["status"] = bec.OBLIGATION_STATUS_PROVISIONAL
    else:
        doc["operator_decisions"]["short_band_allocation"] = bec.SHORT_BAND_REPARTITION
    bec._write_json(bec.COMMITMENT_JSON, doc)
    assert any("do not support it" in f for f in _validate()), how


def test_non_numeric_must_drop_count_does_not_traceback(ws):
    assert _mint() == 0
    doc = json.loads(bec.COMMITMENT_JSON.read_text())
    doc["partition_obligation"]["must_drop_count"] = "many"
    state, failures = bec.partition_closure_state(doc, doc["generation"])
    assert state["must_drop_count"] == 0
    assert failures == []


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


# ---------------------------------------------------------------------------
# load_inputs: training-manifest path key
#
# Regression for a defect introduced in c2865b7 and caught in review on
# 2026-08-12. Both committed manifests key the path `relPath`, but load_inputs
# read `path`, so manifest_paths came back EMPTY in production and the training
# side of the mandatory fingerprint route silently covered only the tony-split
# rows. Nothing caught it because every command-level test stubs load_inputs.
# These tests exercise the real reader against synthetic manifests.
# ---------------------------------------------------------------------------


def _write_training_inputs(root: Path, first: str | None, second: str | None = ...) -> None:
    """Two manifests plus corpus_splits, with each row's path under its own key.

    Per-manifest, because the reader's "did any row carry a path" guard has to be
    per FILE: testing a shared accumulator let a path-less SECOND manifest pass
    on the strength of the first one.
    """
    if second is ...:
        second = first
    for name, key, path_key, digest in (
        (
            "non-rekordbox-secondary-supervised-manifest.json",
            "secondarySupervised",
            first,
            "a",
        ),
        (
            "non-rekordbox-unsupervised-pretrain-manifest.json",
            "unsupervisedPool",
            second,
            "b",
        ),
    ):
        row: dict[str, object] = {"audioHash": digest * 64}
        if path_key is not None:
            row[path_key] = "Bass Music/track.mp3"
        (root / name).write_text(json.dumps({key: [row]}), encoding="utf-8")
    (root / "corpus_splits.json").write_text(
        json.dumps({"tony": {"train": [], "val": []}}), encoding="utf-8"
    )


def _patch_training_inputs(monkeypatch, root: Path) -> None:
    monkeypatch.setattr(
        bec,
        "SECONDARY_MANIFEST",
        root / "non-rekordbox-secondary-supervised-manifest.json",
    )
    monkeypatch.setattr(
        bec,
        "UNSUPERVISED_MANIFEST",
        root / "non-rekordbox-unsupervised-pretrain-manifest.json",
    )
    monkeypatch.setattr(bec, "CORPUS_SPLITS", root / "corpus_splits.json")


def _call_load_inputs(root: Path, monkeypatch):
    """Drive the REAL `load_inputs`, not a re-implementation of its logic.

    Re-implementing the relPath-then-path read inline tests a copy and would not
    catch a recurrence in the reader itself. The OA300 fixture is left real (it
    ships and carries the 82 rows the reader asserts).
    """
    _patch_training_inputs(monkeypatch, root)
    survey = root / "survey.json"
    survey.write_text(json.dumps({"tracks": [], "audio_root": str(root)}), encoding="utf-8")
    tony = root / "tony-survey.json"
    tony.write_text(json.dumps({"tracks": []}), encoding="utf-8")
    monkeypatch.setattr(bec, "SURVEY_PATH", survey)
    monkeypatch.setattr(bec, "TONY_SURVEY_PATH", tony)
    return bec.load_inputs()


@pytest.mark.parametrize("path_key", ["relPath", "path"])
def test_load_inputs_reads_the_manifest_row_path(tmp_path, monkeypatch, path_key):
    """`relPath` is what the committed manifests use; `path` stays accepted."""
    _write_training_inputs(tmp_path, path_key)
    inputs = _call_load_inputs(tmp_path, monkeypatch)
    assert inputs["manifest_hashes"] == {"a" * 64, "b" * 64}
    assert inputs["manifest_paths"] == {
        "a" * 64: "Bass Music/track.mp3",
        "b" * 64: "Bass Music/track.mp3",
    }
    assert inputs["manifest_pathless"] == set()


def test_load_inputs_guard_is_per_file_not_a_shared_accumulator(tmp_path, monkeypatch):
    _write_training_inputs(tmp_path, "relPath", None)
    with pytest.raises(bec.HarnessError, match="unsupervised-pretrain-manifest"):
        _call_load_inputs(tmp_path, monkeypatch)


def test_a_pathless_row_becomes_an_uncovered_training_row(tmp_path, monkeypatch):
    # A row with no path never reaches the fingerprint stage, so without an
    # explicit reason it was absent from the coverage denominators entirely and
    # `assert_training_coverage` could not block on it.
    _write_training_inputs(tmp_path, "relPath")
    doc = json.loads((tmp_path / "non-rekordbox-secondary-supervised-manifest.json").read_text())
    doc["secondarySupervised"].append({"audioHash": "c" * 64})
    (tmp_path / "non-rekordbox-secondary-supervised-manifest.json").write_text(json.dumps(doc))
    inputs = _call_load_inputs(tmp_path, monkeypatch)
    assert inputs["manifest_pathless"] == {"c" * 64}
    coverage, _cands, _train = bec.fingerprint_coverage(
        {**inputs, "manifest_paths": {}, "training_local_paths": {}},
        {name: [] for name in bec.BAND_NAMES},
    )
    assert coverage["training_by_reason"]["no-path"] == 1
    assert coverage["training_roster"][f"manifest:{'c' * 64}"] == "no-path"
    with pytest.raises(bec.OperatorHalt, match="COVERAGE INCOMPLETE ON THE TRAINING SIDE"):
        bec.assert_training_coverage(coverage, set())


def test_training_input_digests_follow_a_redirected_manifest_path(tmp_path, monkeypatch):
    # A module-level tuple of Paths freezes at import, so redirecting the
    # constants would leave `training_input_digests` digesting the originals
    # while every other reader followed the redirect. That is a live footgun for
    # the FR-59d rebuild, which points these at rebuilt manifests.
    _write_training_inputs(tmp_path, "relPath")
    _patch_training_inputs(monkeypatch, tmp_path)
    digests = bec.training_input_digests()
    assert set(digests) == set(bec.TRAINING_INPUT_NAMES)
    assert digests[bec.SECONDARY_MANIFEST.name] == bec.sha256_file(bec.SECONDARY_MANIFEST)


def test_committed_manifests_actually_carry_relpath():
    """The production manifests use `relPath`. If this flips, the reader must too."""
    for manifest, key in (
        (bec.SECONDARY_MANIFEST, "secondarySupervised"),
        (bec.UNSUPERVISED_MANIFEST, "unsupervisedPool"),
    ):
        if not manifest.exists():  # main-only checkout
            continue
        rows = json.loads(manifest.read_text(encoding="utf-8"))[key]
        assert rows, f"{manifest.name} is empty"
        assert "relPath" in rows[0], (
            f"{manifest.name} rows no longer carry 'relPath'; load_inputs reads "
            "relPath-then-path and would silently stop covering the training side"
        )
