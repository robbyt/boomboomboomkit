"""Story 7.4 — Marginal-tier failure-categorization tests (AC8/AC9/AC10/AC11).

Two classes of test:
  - CORPUS-FREE (always run): hand-built fixture tracks exercise the precedence
    rule, the mapping totality, the proximity math (injected synthetic vectors),
    byte-identity, the FR-15 grep, and the DD #4 signoff loud-fail.
  - CORPUS-GATED (skip when the develop-local corpus is absent): the live 241
    envelope + per-category sanity-band regression + reject-marginal pass.

No audio decode anywhere; the proximity test MUST NOT touch fingerprint-cache.npz
or on-disk audio (DD #5).
"""

from __future__ import annotations

import importlib.util
import json

import numpy as np
import pytest

import corpus_common as cc
import corpus_diagnostics as cd
import marginal_failure_categorize as mfc

_CORPUS_AVAILABLE = cc.TONY_TRUTH_LABELS.exists()
corpus_only = pytest.mark.skipif(
    _CORPUS_AVAILABLE is False, reason="Tony corpus develop-local/absent"
)

# AC9 per-category sanity bands (directional; the live 241 must land inside).
SANITY_BANDS = {
    "dspFailure": (10, 60),
    "metadataConflict": (0, 15),
    "halfDoubleOctave": (150, 241),
    "harmonicAmbiguity": (0, 30),
    "unresolved": (0, 15),
}


# ---------------------------------------------------------------------------
# Fixture builders (corpus-free)
# ---------------------------------------------------------------------------


def mk_track(
    tid,
    *,
    conf=0.60,
    truth=170.0,
    truth_c=170.0,
    runner_c=None,
    dsp_rel,
    rk_rel,
    grid_rel,
    dsp_conf=0.70,
    playlist_rel="missing",
):
    """A synthetic Marginal track (conf in [0.55,0.65)) with the minimal shape
    `categorize()` / `categorization_records()` read.
    """
    track = {
        "track_id": str(tid),
        "truth_confidence": conf,
        "bpm_truth": truth,
        "truth_cluster": {"centroid": truth_c},
        "signals": {
            "dsp": {"bpm": 128.0, "confidence": dsp_conf, "relation": dsp_rel},
            "rekordbox_average": {"bpm": 85.0, "relation": rk_rel},
            "grid_bpm": {"bpm": 85.0, "relation": grid_rel},
            "playlist": {"relation": playlist_rel},
        },
    }
    if runner_c is not None:
        track["runner_up_cluster"] = {"centroid": runner_c}
    return track


def _category_fixtures():
    """One labeled fixture per expected category + the edge cases (AC8c)."""
    return {
        # dspFailure: audio outlier, both metadata agree with truth.
        "dspFailure": mk_track(
            "f_dsp", dsp_rel="far", rk_rel="same", grid_rel="same", runner_c=150.0
        ),
        # metadataConflict: a metadata source is a non-octave outlier; DSP supports truth.
        "metadataConflict": mk_track(
            "f_meta", dsp_rel="same", rk_rel="far", grid_rel="same", runner_c=150.0
        ),
        # halfDoubleOctave, 2x runner-up.
        "halfDoubleOctave_2x": mk_track(
            "f_oct2", dsp_rel="far", rk_rel="half", grid_rel="half", truth_c=170.0, runner_c=85.0
        ),
        # halfDoubleOctave, 0.5x runner-up (direction symmetry — no `double` branch).
        "halfDoubleOctave_half": mk_track(
            "f_oct_half",
            dsp_rel="far",
            rk_rel="half",
            grid_rel="half",
            truth=85.0,
            truth_c=85.0,
            runner_c=170.0,
        ),
        # harmonicAmbiguity: 3:2 cluster ratio, no earlier rule fires.
        "harmonicAmbiguity": mk_track(
            "f_harm",
            dsp_rel="near",
            rk_rel="near",
            grid_rel="near",
            truth_c=170.0,
            runner_c=170.0 / 1.5,
        ),
        # unresolved: non-octave/non-harmonic runner-up, no relation rule.
        "unresolved": mk_track(
            "f_unres", dsp_rel="near", rk_rel="near", grid_rel="near", truth_c=170.0, runner_c=150.0
        ),
        # null runner-up: must not crash, falls through to unresolved.
        "nullRunnerUp": mk_track(
            "f_null", dsp_rel="far", rk_rel="half", grid_rel="half", runner_c=None
        ),
        # precedence collision: rule-1 (dspFailure) conditions AND is_harmonic
        # geometry both hold -> rule 1 wins (the over-reach guard; this is the
        # mechanism that pre-empts 3 of the 11 harmonic-ratio candidates).
        "precedenceRule1Wins": mk_track(
            "f_prec",
            dsp_rel="far",
            rk_rel="same",
            grid_rel="same",
            truth_c=170.0,
            runner_c=170.0 / 1.5,
        ),
        # rule-2 vs rule-3 overlap (code-review 7-4 / Codex thread 019e8f9f): an
        # OCTAVE-geometry track with dsp=same + one metadata source far + the other
        # half. Without the `not is_octave` guard on rule 2 this matched BOTH rule 2
        # and rule 3 and first-match-wins returned metadataConflict; the guard now
        # correctly routes it to halfDoubleOctave (an octave error, not a stale tag).
        "octaveBeatsMetadataConflict": mk_track(
            "f_oct_meta",
            dsp_rel="same",
            rk_rel="far",
            grid_rel="half",
            truth_c=170.0,
            runner_c=85.0,
        ),
    }


# ---------------------------------------------------------------------------
# (c) per-category + edge-case categorize() fixtures
# ---------------------------------------------------------------------------


def test_categorize_per_category_fixtures():
    fx = _category_fixtures()
    assert mfc.categorize(fx["dspFailure"]) == "dspFailure"
    assert mfc.categorize(fx["metadataConflict"]) == "metadataConflict"
    assert mfc.categorize(fx["halfDoubleOctave_2x"]) == "halfDoubleOctave"
    assert mfc.categorize(fx["halfDoubleOctave_half"]) == "halfDoubleOctave"
    assert mfc.categorize(fx["harmonicAmbiguity"]) == "harmonicAmbiguity"
    assert mfc.categorize(fx["unresolved"]) == "unresolved"


def test_null_runner_up_does_not_crash_and_falls_through():
    fx = _category_fixtures()
    assert mfc.categorize(fx["nullRunnerUp"]) == "unresolved"


def test_precedence_rule1_wins_over_harmonic_geometry():
    # rule-1 (dspFailure) pre-empts rule-4 (harmonicAmbiguity) when both hold.
    fx = _category_fixtures()
    assert mfc.categorize(fx["precedenceRule1Wins"]) == "dspFailure"


def test_octave_geometry_beats_metadata_conflict():
    # code-review 7-4 (Codex 019e8f9f): an octave-geometry track with dsp=same and a
    # far/half metadata pair is a halfDoubleOctave, NOT a metadataConflict — the
    # `not is_octave` guard on rule 2 makes rule 3 win. (Was metadataConflict pre-guard.)
    fx = _category_fixtures()
    assert mfc.categorize(fx["octaveBeatsMetadataConflict"]) == "halfDoubleOctave"


def test_octave_direction_symmetry():
    # 2x and 0.5x both classify halfDoubleOctave (canonical_ratio is symmetric).
    fx = _category_fixtures()
    assert mfc.categorize(fx["halfDoubleOctave_2x"]) == mfc.categorize(fx["halfDoubleOctave_half"])


# ---------------------------------------------------------------------------
# Shared ratio-predicate helpers (P3 single-source seam, code-review 7-4)
# ---------------------------------------------------------------------------


def test_cluster_ratio_degenerate_inputs_return_zero():
    # Missing / non-numeric / NaN / zero / negative centroids -> 0.0 (no ratio),
    # never a crash or NaN. This is the seam corpus_diagnostics now shares.
    base = {"runner_up_cluster": {"centroid": 85.0}}
    assert mfc.cluster_ratio({"truth_cluster": {"centroid": 170.0}}) == 0.0  # runner absent
    assert mfc.cluster_ratio({**base, "truth_cluster": {"centroid": "abc"}}) == 0.0
    assert mfc.cluster_ratio({**base, "truth_cluster": {"centroid": float("nan")}}) == 0.0
    assert mfc.cluster_ratio({**base, "truth_cluster": {"centroid": 0.0}}) == 0.0
    assert mfc.cluster_ratio({**base, "truth_cluster": {"centroid": -170.0}}) == 0.0
    # a real 2:1 pair still resolves.
    assert mfc.cluster_ratio({**base, "truth_cluster": {"centroid": 170.0}}) == 2.0


def test_octave_and_harmonic_ratio_tolerance_boundaries():
    assert mfc.is_octave_ratio(2.0) is True
    assert mfc.is_octave_ratio(1.95) is True  # within OCTAVE_RATIO_TOL*2.0 = 0.10
    assert mfc.is_octave_ratio(2.2) is False  # outside
    assert mfc.is_octave_ratio(0.0) is False  # no ratio
    assert mfc.is_harmonic_ratio(1.5) is True
    assert mfc.is_harmonic_ratio(3.0) is True
    assert mfc.is_harmonic_ratio(1.6) is False
    assert mfc.is_harmonic_ratio(2.0) is False  # an octave is not harmonic


def test_geometry_block_survives_malformed_centroid():
    # P3 hardening: a non-numeric centroid must not crash the geometry block
    # (the categorizer already coerced via _centroid; the diagnostics path now
    # shares that predicate). The track is treated as non-octave.
    bad = mk_track("f_badcentroid", dsp_rel="same", rk_rel="same", grid_rel="same", runner_c=85.0)
    bad["truth_cluster"] = {"centroid": "not-a-number"}
    geo = cd.marginal_tier_disagreement_geometry([bad])
    assert geo["marginalTierCount"] == 1
    # the malformed-centroid track contributes 0 octave tracks (non-octave).
    assert geo["perCategory"]["unresolved"]["halfDoubleRate"] == 0.0


# ---------------------------------------------------------------------------
# (b) determinism pins + mapping totality + envelope on fixtures
# ---------------------------------------------------------------------------


def test_expected_failure_mode_is_total_and_closed():
    for cat in mfc.CATEGORIES:
        label, predicate = mfc.expected_failure_mode(cat)
        assert label, f"{cat} has empty expectedFailureMode"
        assert predicate in mfc.VERIFICATION_PREDICATES
    # unresolved names the absence visibly.
    assert mfc.expected_failure_mode("unresolved") == ("no-a-priori-expectation", "none")
    # closed enum — an out-of-set category raises, never returns a null.
    with pytest.raises(KeyError):
        mfc.expected_failure_mode("notACategory")


def test_categories_declared_order_is_precedence_order():
    assert mfc.CATEGORIES == (
        "dspFailure",
        "metadataConflict",
        "halfDoubleOctave",
        "harmonicAmbiguity",
        "unresolved",
    )


def test_records_sorted_by_track_id_and_floats_rounded():
    tracks = list(_category_fixtures().values())
    recs = mfc.categorization_records(tracks)
    ids = [r["track_id"] for r in recs]
    assert ids == sorted(ids)
    for r in recs:
        for k in ("tonyLabel", "dspBPM", "rekordboxBPM", "gridBPM"):
            v = r[k]
            if v is not None:
                assert isinstance(v, float) and round(v, 6) == v
        assert r["idTagBPM"] is None and r["durationDerivedBPM"] is None


def test_category_counts_iterate_declared_order():
    tracks = list(_category_fixtures().values())
    counts = mfc.category_counts(mfc.categorization_records(tracks))
    assert tuple(counts.keys()) == mfc.CATEGORIES


def test_watchlist_row_schema_locked():
    tracks = list(_category_fixtures().values())
    payload = mfc.build_watchlist_payload(tracks)
    for row in payload["watchlist"]:
        assert set(row.keys()) == set(mfc.WATCHLIST_ROW_KEYS)
        assert row["expectedFailureMode"]  # non-null
        assert row["verificationPredicate"] in mfc.VERIFICATION_PREDICATES
        # v2Prediction reserved typed stub, null at 7.4 close (DD #13).
        v2 = row["v2Prediction"]
        assert set(v2.keys()) == {
            "status",
            "seeds",
            "varianceBpm",
            "octaveNormalizedAgreement",
            "matchesExpected",
        }
        assert v2["seeds"] == [] and v2["matchesExpected"] is None
    assert payload["_consumedBy"] == ["7.5", "7.6"]


# ---------------------------------------------------------------------------
# (a) byte-identity (corpus-free, on fixtures)
# ---------------------------------------------------------------------------


def test_byte_identity_categorization_and_watchlist(tmp_path):
    tracks = list(_category_fixtures().values())
    for builder in (mfc.build_categorization_payload, mfc.build_watchlist_payload):
        a = tmp_path / "a.json"
        b = tmp_path / "b.json"
        mfc.write_json_artifact(builder(tracks), a)
        mfc.write_json_artifact(builder(tracks), b)
        assert a.read_bytes() == b.read_bytes()


def test_byte_identity_geometry_block():
    tracks = list(_category_fixtures().values())
    g1 = cd.marginal_tier_disagreement_geometry(tracks)
    g2 = cd.marginal_tier_disagreement_geometry(tracks)
    assert json.dumps(g1, indent=2) == json.dumps(g2, indent=2)


# ---------------------------------------------------------------------------
# Proximity math — injected synthetic vectors ONLY (DD #5; corpus-free)
# ---------------------------------------------------------------------------


def test_nearest_strong_is_exhaustive_argmin_with_id_tiebreak():
    # 3 marginal, 2 strong. s_a and s_b are IDENTICAL -> every marginal is
    # equidistant; the tie must break to the lowest Strong track_id ("s_a").
    marg = {
        "m1": np.array([1.0, 0.0, 0.0, 0.5]),
        "m2": np.array([0.0, 1.0, 0.0, 0.5]),
        "m3": np.array([0.0, 0.0, 1.0, 0.5]),
    }
    strong = {
        "s_b": np.array([0.3, 0.3, 0.3, 0.9]),
        "s_a": np.array([0.3, 0.3, 0.3, 0.9]),
    }
    out = mfc.nearest_strong_distances(marg, strong)
    assert set(out.keys()) == {"m1", "m2", "m3"}
    for _mid, (sid, dist) in out.items():
        assert sid == "s_a"  # lowest id on the tie
        assert isinstance(dist, float) and round(dist, 6) == dist
    # deterministic across calls
    assert mfc.nearest_strong_distances(marg, strong) == out


def test_nearest_strong_empty_sides_return_empty():
    assert mfc.nearest_strong_distances({}, {"s": np.array([1.0, 2.0])}) == {}
    assert mfc.nearest_strong_distances({"m": np.array([1.0, 2.0])}, {}) == {}


# ---------------------------------------------------------------------------
# DD #4 — signoff loud-fail (corpus-free: refusal happens before build)
# ---------------------------------------------------------------------------


def test_generator_refuses_to_overwrite_signed(monkeypatch, tmp_path, capsys):
    signed = tmp_path / "corpus-diagnostics-v1.md"
    signed.write_text("# diag\n\n`REVIEWER_SIGNOFF: signed`\n")
    monkeypatch.setattr(cd, "OUT_MD", signed)
    assert cd._existing_signoff_state() == "signed"
    rc = cd.main([])  # no --force
    assert rc == 2
    assert "REFUSING to overwrite a SIGNED" in capsys.readouterr().err


def test_existing_signoff_state_reads_pending(monkeypatch, tmp_path):
    pending = tmp_path / "corpus-diagnostics-v1.md"
    pending.write_text("# diag\n\n`REVIEWER_SIGNOFF: pending`\n")
    monkeypatch.setattr(cd, "OUT_MD", pending)
    assert cd._existing_signoff_state() == "pending"


def test_existing_signoff_state_ambiguous_fails_closed(monkeypatch, tmp_path):
    # code-review 7-4: ANY marker count != 1 maps to "signed" so main() refuses to
    # overwrite — a 2+-marker file is an ambiguous state the guard must not clobber.
    md = tmp_path / "corpus-diagnostics-v1.md"
    monkeypatch.setattr(cd, "OUT_MD", md)
    # (a) two markers, one signed -> signed (fail closed).
    md.write_text("`REVIEWER_SIGNOFF: pending`\n\n`REVIEWER_SIGNOFF: signed`\n")
    assert cd._existing_signoff_state() == "signed"
    # (b) two pending markers -> still signed (ambiguity, not "safe to overwrite").
    md.write_text("`REVIEWER_SIGNOFF: pending`\n\n`REVIEWER_SIGNOFF: pending`\n")
    assert cd._existing_signoff_state() == "signed"
    # main() must then refuse without --force.
    assert cd.main([]) == 2


# ---------------------------------------------------------------------------
# AC10 / AC5 — FR-15 leakage guard + reject-marginal (corpus-free)
# ---------------------------------------------------------------------------


def _load_audit_module():
    path = cc.REPO_ROOT / "scripts" / "audit-corpus-splits.py"
    spec = importlib.util.spec_from_file_location("audit_corpus_splits", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def test_no_training_path_reads_marginal_artifacts():
    # AC10 / DD #12 — no feature-transform/training path imports or reads the
    # diagnostic artifacts (or the categorization module).
    forbidden = (
        "marginal-failure-categorization.json",
        "marginal-watchlist.json",
        "marginal_failure_categorize",
        "marginal-failure-categorize",
    )
    targets = [
        cc.ML_TRAINING_DIR / "dataset.py",
        cc.ML_TRAINING_DIR / "train.py",
        cc.ML_TRAINING_DIR / "ablation" / "ablation_features.py",
        cc.ML_TRAINING_DIR / "ablation" / "train_supervised_augmented.py",
        cc.ML_TRAINING_DIR / "ablation" / "train_masked_mel_pretrain.py",
        cc.ML_TRAINING_DIR / "ablation" / "build_unsupervised_manifest.py",
    ]
    checked = 0
    for f in targets:
        if not f.exists():
            continue
        checked += 1
        text = f.read_text()
        for token in forbidden:
            assert token not in text, f"FR-15: {f.name} references {token!r}"
    assert checked >= 3, "expected at least the core feature/training paths present"


def test_reject_marginal_check_logic():
    audit = _load_audit_module()
    tracks = list(_category_fixtures().values())  # all Marginal (conf in band)

    # clean: flag true, no marginal id in any split.
    res = audit.AuditResult()
    audit.check_marginal_exclusion(
        {
            "marginalTierExclusion": True,
            "train": [],
            "val": [],
            "leaveArtistOut": {"heldOutTrackIds": []},
        },
        tracks,
        res,
    )
    assert not res.failures

    # missing flag -> failure.
    res = audit.AuditResult()
    audit.check_marginal_exclusion(
        {"train": [], "val": [], "leaveArtistOut": {"heldOutTrackIds": []}}, tracks, res
    )
    assert res.failures

    # leaked marginal id -> failure.
    leaked_id = tracks[0]["track_id"]
    res = audit.AuditResult()
    audit.check_marginal_exclusion(
        {
            "marginalTierExclusion": True,
            "train": [leaked_id],
            "val": [],
            "leaveArtistOut": {"heldOutTrackIds": []},
        },
        tracks,
        res,
    )
    assert res.failures


# ---------------------------------------------------------------------------
# CORPUS-GATED — live 241 envelope + sanity-band regression + reject-marginal
# ---------------------------------------------------------------------------


@corpus_only
def test_live_envelope_241_and_closed_set():
    tracks, _ = cc.load_tony_corpus()
    recs = mfc.categorization_records(tracks)
    assert len(recs) == 241
    assert all(r["failureCategory"] in mfc.CATEGORIES for r in recs)
    wl = mfc.build_watchlist_payload(tracks)["watchlist"]
    assert len(wl) == 241
    assert all(r["expectedFailureMode"] for r in wl)
    assert all(r["verificationPredicate"] in mfc.VERIFICATION_PREDICATES for r in wl)


@corpus_only
def test_live_per_category_within_sanity_bands():
    tracks, _ = cc.load_tony_corpus()
    counts = mfc.category_counts(mfc.categorization_records(tracks))
    assert sum(counts.values()) == 241
    for cat, (lo, hi) in SANITY_BANDS.items():
        assert lo <= counts[cat] <= hi, f"{cat}={counts[cat]} outside [{lo},{hi}]"
    # halfDoubleOctave is the dominant category.
    assert counts["halfDoubleOctave"] == max(counts.values())


@corpus_only
def test_live_harmonic_candidate_count_measured():
    # AC9 — the precedence-independent 3:2/3:1 count is measured (>= the count
    # that survives precedence into harmonicAmbiguity).
    tracks, _ = cc.load_tony_corpus()
    candidates = mfc.harmonic_candidate_count(tracks)
    landed = mfc.category_counts(mfc.categorization_records(tracks))["harmonicAmbiguity"]
    assert candidates >= landed


@corpus_only
def test_live_geometry_proximity_coverage_gated_null():
    # DD #5 — on the dev-agent run (split-built cache) proximity is null+status.
    tracks, _ = cc.load_tony_corpus()
    geo = cd.marginal_tier_disagreement_geometry(tracks)
    assert geo["marginalTierCount"] == 241
    if not geo["proximity"]["coverageMet"]:
        for cat in mfc.CATEGORIES:
            pc = geo["perCategory"][cat]
            assert pc["meanNearestStrongDistance"] is None
            assert pc["proximityStatus"] == "insufficientCoverage"
