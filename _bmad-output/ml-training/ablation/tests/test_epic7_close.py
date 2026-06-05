"""Story 7.7 — adversarial fixture tests for the Epic-7 close-out harness.

stdlib + numpy only; no corpus, no model, no Swift. Each test fails for the
RIGHT reason (Amelia/Codex): the holdout-gap boundary + fail-closed, the
stratified-sampler determinism + style fallback, the calibration
inconclusive/abstain discipline, the FR-24 tolerance gate + runner-up-absent,
the freeze literals, the post-bundle reopen signal.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

import calibration_verification as cal
import epic7_freeze as freeze
import fr24_net_benefit as fr24
import holdout_gap as hg
import post_bundle_watchlist as pbw

# sample-giantsteps-holdout.py has hyphens -> load by path.
_SAMPLER_PATH = Path(__file__).resolve().parents[4] / "scripts" / "sample-giantsteps-holdout.py"
_spec = importlib.util.spec_from_file_location("sample_giantsteps_holdout", _SAMPLER_PATH)
assert _spec and _spec.loader
sgh = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sgh)


def _gs_row(tid: str, truth: float, pred: float | None, *, corpus: str = "giantsteps") -> dict:
    return {
        "trackId": tid,
        "groundTruthBPM": truth,
        "fr18ModelBPM": pred,
        "softmaxMax": None if pred is None else 0.6,
        "mlAbstained": pred is None,
        "dspCandidatesTop3": [truth / 2.0],
        "corpus": corpus,
    }


# --- Task 1: stratified holdout sampler ------------------------------------


def _synth_tracks(n: int, with_style: bool = False) -> list[dict]:
    out = []
    for i in range(n):
        t = {"trackId": f"t{i:04d}", "bpm": 60.0 + (i % 140)}
        if with_style:
            t["genre"] = ["house", "techno", "dnb", "trance"][i % 4]
        out.append(t)
    return out


def test_select_holdout_is_deterministic_and_exact_n():
    tracks = _synth_tracks(400)
    a, _ = sgh.select_holdout(tracks, seed=7700, n=150)
    b, _ = sgh.select_holdout(tracks, seed=7700, n=150)
    assert len(a) == 150
    assert [t["trackId"] for t in a] == [t["trackId"] for t in b]  # determinism


def test_select_holdout_different_seed_differs():
    tracks = _synth_tracks(400)
    a, _ = sgh.select_holdout(tracks, seed=7700, n=150)
    c, _ = sgh.select_holdout(tracks, seed=99, n=150)
    assert [t["trackId"] for t in a] != [t["trackId"] for t in c]


def test_select_holdout_style_absent_falls_back_to_tempo_only():
    _, basis = sgh.select_holdout(_synth_tracks(400, with_style=False), seed=7700)
    assert basis["mode"] == "tempo-only" and basis["styleKey"] is None


def test_select_holdout_style_present_uses_15_strata():
    _, basis = sgh.select_holdout(_synth_tracks(400, with_style=True), seed=7700)
    assert basis["mode"] == "style+tempo" and basis["styleKey"] == "genre"


def test_select_holdout_too_small_corpus_fails_closed():
    with pytest.raises(sgh.HoldoutSampleError):
        sgh.select_holdout(_synth_tracks(100), seed=7700, n=150)


def test_manifest_digest_is_stable_and_order_independent():
    e1 = [{"trackId": "b", "sha256": "22"}, {"trackId": "a", "sha256": "11"}]
    e2 = [{"trackId": "a", "sha256": "11"}, {"trackId": "b", "sha256": "22"}]
    assert sgh.manifest_digest(e1) == sgh.manifest_digest(e2)


# --- Task 2: holdout-gap tripwire ------------------------------------------


def _rows_pct(prefix: str, n: int, correct: int) -> list[dict]:
    rows = []
    for i in range(n):
        hit = i < correct
        rows.append(_gs_row(f"{prefix}{i}", 128.0, 128.0 if hit else 60.0))
    return rows


def test_gap_below_tripwire_closes():
    g = hg.compute_gap(_rows_pct("it", 100, 80), _rows_pct("ho", 100, 73))  # 80 vs 73 = 7pp
    assert g["gapPP"] == 7.0 and g["blocks"] is False


def test_gap_at_tripwire_blocks():
    g = hg.compute_gap(_rows_pct("it", 100, 80), _rows_pct("ho", 100, 72))  # 80 vs 72 = 8pp
    assert g["gapPP"] == 8.0 and g["blocks"] is True


def test_partition_removes_exactly_holdout():
    gs = [_gs_row(f"t{i}", 128.0, 128.0) for i in range(10)]
    iterated, holdout = hg.partition(gs, {"t0", "t1"})
    assert len(iterated) == 8 and len(holdout) == 2


def test_partition_missing_holdout_id_fails_closed():
    gs = [_gs_row(f"t{i}", 128.0, 128.0) for i in range(10)]
    with pytest.raises(hg.HoldoutGapError):
        hg.partition(gs, {"t0", "t999"})  # t999 absent -> would silently use full set


def test_partition_duplicate_trackid_fails_closed():
    # A duplicate trackId in the dumps would inflate the holdout subset (code-review).
    gs = [_gs_row(f"t{i}", 128.0, 128.0) for i in range(10)] + [_gs_row("t0", 128.0, 128.0)]
    with pytest.raises(hg.HoldoutGapError):
        hg.partition(gs, {"t0", "t1"})


# --- Task 3: calibration ---------------------------------------------------


def _cal_rows(n: int, *, abstained: bool = False) -> list[dict]:
    rows = []
    for i in range(n):
        rows.append(
            {
                "trackId": f"c{i}",
                "groundTruthBPM": 160.0,
                "fr18ModelBPM": None if abstained else 160.0,
                "softmaxMax": None if abstained else 0.7,
                "mlAbstained": abstained,
                "dspCandidatesTop3": [80.0],  # truth 160 is 2x -> in half/double subset
            }
        )
    return rows


def test_calibration_small_subset_is_inconclusive_not_false_pass():
    report = cal.build_calibration_report(_cal_rows(50))  # N=50 < 100
    assert report["eceHalfDouble"]["state"] == "inconclusive"
    assert report["calibrationPasses"] is False  # inconclusive != pass
    assert report["blocksOnFailOrInconclusive"] is True


def test_calibration_abstain_with_stale_bpm_raises():
    bad = _cal_rows(1)[0]
    bad["mlAbstained"] = True  # invariant violation: abstain True but bpm finite
    with pytest.raises(cal.CalibrationSchemaError):
        cal.validate_and_filter([bad])


def test_calibration_proper_abstain_is_excluded():
    rows = _cal_rows(3) + _cal_rows(2, abstained=True)
    kept = cal.validate_and_filter(rows)
    assert len(kept) == 3 and all(not r["mlAbstained"] for r in kept)


def test_calibration_report_runs_without_matplotlib():
    # build_calibration_report must NOT import matplotlib (AC4 no-PNG path).
    report = cal.build_calibration_report(_cal_rows(120))
    assert "softmaxSharpness" in report and report["eceHalfDouble"]["v2_N"] == 120


# --- Task 4: FR-24 net-benefit gate ----------------------------------------


_CORPUS_N = {"oa300": 82, "giantsteps": 661, "sentinel": 12}


def _arm(acc1: int, ece: float | None, tail: float) -> dict:
    # Per-corpus full denominators so every corpus clears the MIN_DENOMINATOR guard.
    return {c: {"acc1": acc1, "n": _CORPUS_N[c], "ece": ece, "tailP95": tail} for c in fr24.CORPORA}


def test_net_benefit_passes_when_ssl_within_tolerance():
    g = fr24.net_benefit_gate(_arm(60, 0.08, 3.0), _arm(60, 0.08, 3.0))
    assert g["netBenefitProven"] is True


def test_net_benefit_fails_on_acc1_regression():
    g = fr24.net_benefit_gate(_arm(57, 0.08, 3.0), _arm(60, 0.08, 3.0))  # -3 tracks > tol 2
    assert g["netBenefitProven"] is False


def test_net_benefit_fails_on_ece_regression():
    g = fr24.net_benefit_gate(_arm(60, 0.11, 3.0), _arm(60, 0.08, 3.0))  # +0.03 > tol 0.02
    assert g["netBenefitProven"] is False


def test_net_benefit_fails_on_tail_regression():
    g = fr24.net_benefit_gate(_arm(60, 0.08, 3.7), _arm(60, 0.08, 3.0))  # +0.7 > tol 0.5
    assert g["netBenefitProven"] is False


def test_net_benefit_ece_inconclusive_does_not_fail():
    g = fr24.net_benefit_gate(_arm(60, None, 3.0), _arm(60, None, 3.0))
    assert g["netBenefitProven"] is True
    assert g["perCorpus"]["oa300"]["eceNote"].startswith("inconclusive")


def test_fr24_runnerup_absent_is_inconclusive(tmp_path):
    (tmp_path / fr24.WINNER_ARM).mkdir()  # winner present, runner-up dir absent
    report = fr24.evaluate(tmp_path)
    assert report["state"] == "inconclusive"
    assert report["netBenefitProven"] is False and report["requiresOperatorAck"] is True


def test_net_benefit_below_denominator_corpus_not_compared():
    # code-review (Codex): a tiny/partial corpus must NOT count as comparable.
    tiny = {c: {"acc1": 4, "n": 5, "ece": None, "tailP95": 3.0} for c in fr24.CORPORA}
    g = fr24.net_benefit_gate(tiny, tiny)
    assert g["comparedCorpora"] == 1  # only sentinel (min_n=1) clears; oa300/giantsteps don't
    assert "oa300" in g["belowDenominator"] and "giantsteps" in g["belowDenominator"]


def test_net_benefit_sentinel_only_cannot_carry_verdict():
    # Copilot PR #31: sentinel-only (oa300/giantsteps below denominator) must NOT
    # decide net-benefit on n<=12 evidence — requires >=1 FIXED corpus.
    arm = {
        "oa300": {"acc1": 4, "n": 5, "ece": None, "tailP95": 3.0},  # below 82
        "giantsteps": {"acc1": 4, "n": 5, "ece": None, "tailP95": 3.0},  # below 661
        "sentinel": {"acc1": 12, "n": 12, "ece": None, "tailP95": 1.0},  # full 12
    }
    g = fr24.net_benefit_gate(arm, arm)
    assert g["comparedCorpora"] == 1  # only sentinel cleared its (min=1) denominator
    assert g["fixedCorporaCompared"] == 0
    assert g["netBenefitProven"] is False  # sentinel alone cannot prove it


def test_net_benefit_empty_corpora_is_not_proven():
    # code-review BLOCKER: zero comparable corpora must NOT silently prove benefit.
    g = fr24.net_benefit_gate({}, {})
    assert g["comparedCorpora"] == 0 and g["netBenefitProven"] is False
    # disjoint corpora (winner has oa300, runner-up has giantsteps) -> nothing compared
    g2 = fr24.net_benefit_gate(
        {"oa300": {"acc1": 60, "n": 82, "ece": None, "tailP95": 3.0}},
        {"giantsteps": {"acc1": 500, "n": 661, "ece": None, "tailP95": 5.0}},
    )
    assert g2["netBenefitProven"] is False


# --- Task 5: FR-20 freeze --------------------------------------------------


def test_freeze_stamps_decision_and_tag():
    out = freeze.freeze_metadata({"architecture": "TempoCNN"}, "bundle")
    assert out["epic7CloseDecision"] == "bundle" and out["gitTag"] == "epic-7-close"


def test_freeze_rejects_non_kdd_b5_literal():
    with pytest.raises(ValueError):
        freeze.freeze_metadata({}, "bundled")  # epic prose literal, not 7.6's enum


# --- Task 6: post-bundle watchlist -----------------------------------------


def test_post_bundle_matches_expected_octave_family_error():
    wl = {
        "9001": {
            "verificationPredicate": "octave_family_error",
            "expectedFailureMode": "off-by-octave",
            "tonyLabel": 128.0,
            "dspBPM": 64.0,
            "rekordboxBPM": 128.0,
            "gridBPM": None,
        }
    }
    by_seed = {42: [{"trackId": "9001", "corpus": "marginal", "fr18ModelBPM": 64.0}]}
    report = pbw.annotate(wl, by_seed)
    row = report["watchlist"][0]
    assert row["matchesExpected"] is True  # model lands an octave off -> expected


def test_post_bundle_expected_failure_mode_from_modes_map():
    # code-review: _load_watchlist strips expectedFailureMode; it must come from
    # the raw-file modes map, not the predicate-only watchlist entry.
    wl = {"9003": {"verificationPredicate": "none", "tonyLabel": 120.0}}  # no expectedFailureMode
    by_seed = {42: [{"trackId": "9003", "corpus": "marginal", "fr18ModelBPM": 120.0}]}
    report = pbw.annotate(wl, by_seed, expected_modes={"9003": "off-by-octave"})
    assert report["watchlist"][0]["expectedFailureMode"] == "off-by-octave"


def test_post_bundle_flags_74d1_reopen_signal():
    wl = {
        "9002": {
            "verificationPredicate": "model_corrects_metadata",
            "tonyLabel": 174.0,
            "dspBPM": 87.0,
            "rekordboxBPM": None,
            "gridBPM": None,  # no metadata present -> ID3 (unwired) might have helped
        }
    }
    by_seed = {42: [{"trackId": "9002", "corpus": "marginal", "fr18ModelBPM": 87.0}]}
    report = pbw.annotate(wl, by_seed)
    assert report["reopen74D1SignalCount"] == 1
    assert report["watchlist"][0]["reopen74D1Signal"] is True
