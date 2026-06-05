"""Story 7.6 — unit/fixture tests for the FR-18 evaluator's pure computation.

stdlib + numpy only; no corpus, no model, no Swift. These exercise the gate
math, the >=2-of-3 + dispersion aggregation, the KDD-B5 decision (bundle /
byow / unstable / calibration-block), the calibration helpers, the watchlist
predicate evaluation, and the rerun-log governance parser — the AC12 (ii)
fixture test that smokes the bundle branch the v1 negative-control cannot reach.
"""

from __future__ import annotations

import json

import build_fr18_input as bfi
import evaluate_fr18 as ev


# --- real-file key resolution (code-review BLOCKER regression guard) --------


def test_load_watchlist_real_file_keys_off_watchlist():
    # The real marginal-watchlist.json's first list-valued key is `_consumedBy`
    # (["7.5","7.6"]); the loader MUST key off "watchlist" or it crashes / loads
    # the wrong rows. This guards the code-review BLOCKER.
    wl = ev._load_watchlist()
    assert wl is not None
    assert len(wl) == 241
    sample = next(iter(wl.values()))
    assert "verificationPredicate" in sample


def test_tony_index_real_file_keys_off_tracks():
    idx = bfi._tony_index()
    assert len(idx) > 100  # tony-truth-labels.json has ~1344 rows
    sample = next(iter(idx.values()))
    assert "track_id" in sample and "bpm_truth" in sample


def test_resolvers_fail_closed_on_empty_corpus_path():
    # Copilot #4/#5: an empty corpus-path env var must NOT probe the CWD for a
    # stray fixture filename — it returns [] (fails safe; the downstream
    # denominator guard then marks the gate inconclusive -> byow).
    assert bfi.resolve_oa300("") == []
    assert bfi.resolve_giantsteps("") == []


# --- accuracy + octave -----------------------------------------------------


def test_acc1_abstain_counts_incorrect():
    assert ev.acc1_correct(120.0, 120.0) is True
    assert ev.acc1_correct(None, 120.0) is False  # abstain => incorrect (DD #12)
    assert ev.acc1_correct(float("nan"), 120.0) is False
    assert ev.acc1_correct(60.0, 120.0) is False  # octave off is NOT an Acc1 hit


def test_octave_match():
    assert ev.octave_match(60.0, 120.0) is True  # half
    assert ev.octave_match(240.0, 120.0) is True  # double
    assert ev.octave_match(120.0, 120.0) is True
    assert ev.octave_match(90.0, 120.0) is False
    assert ev.octave_match(None, 120.0) is False


def test_wilson_n12_is_all_or_nothing():
    # Mary AC13: 12/12 -> ~0.76 (passes 0.75); 11/12 -> ~0.65 (fails).
    assert ev.wilson_lower_bound(12, 12) >= ev.GATE_A_WILSON_FLOOR
    assert ev.wilson_lower_bound(11, 12) < ev.GATE_A_WILSON_FLOOR
    assert ev.wilson_lower_bound(0, 0) == 0.0


# --- calibration -----------------------------------------------------------


def test_half_double_subset():
    assert ev.in_half_double_subset(160.0, [80.0, 100.0]) is True  # 160 is 2x 80
    assert ev.in_half_double_subset(80.0, [160.0]) is True  # 80 is 1/2 of 160
    assert ev.in_half_double_subset(120.0, [121.0, 119.0]) is False


def test_ece_inconclusive_below_min_n():
    rows = [
        {
            "fr18ModelBPM": 160.0,
            "softmaxMax": 0.9,
            "groundTruthBPM": 160.0,
            "dspCandidatesTop3": [80.0],
        }
        for _ in range(20)  # < ECE_MIN_SUBSET_N
    ]
    out = ev.compute_ece_half_double(rows)
    assert out["state"] == "inconclusive"
    assert out["ece"] is None
    assert out["n"] == 20


def test_ece_pass_when_well_calibrated():
    # 120 well-calibrated rows: confident (0.99) AND correct -> ECE ~ 0.01.
    rows = [
        {
            "fr18ModelBPM": 160.0,
            "softmaxMax": 0.99,
            "groundTruthBPM": 160.0,
            "dspCandidatesTop3": [80.0],
        }
        for _ in range(120)
    ]
    out = ev.compute_ece_half_double(rows)
    assert out["state"] == "pass"
    assert out["ece"] < ev.GATE_D_ECE_FLOOR


def test_bimodality_detects_125_175():
    clustered = [125.0] * 40 + [175.0] * 40 + [140.0] * 20
    out = ev.bimodality_125_175(clustered)
    assert out["reappears"] is True
    assert out["fraction"] > ev.BIMODAL_FRACTION_BOUND
    spread = ev.bimodality_125_175([90.0 + i for i in range(100)])
    assert spread["reappears"] is False


# --- per-seed gates + aggregation ------------------------------------------


def _perfect_seed(seed: int) -> ev.SeedGateResult:
    return ev.SeedGateResult(
        seed=seed,
        oa300_acc1=82,
        oa300_total=82,
        giantsteps_acc1=600,
        giantsteps_total=661,
        sentinels_correct=12,
        sentinels_total=12,
        wilson_lb=ev.wilson_lower_bound(12, 12),
        ece={"state": "pass", "ece": 0.01, "n": 200},
        tail_p95={"giantSteps": 2.0, "oa300": 1.0, "sentinels": 0.5},
        softmax_max_p95=0.8,
        bimodality={"reappears": False, "fraction": 0.05},
        ml_abstain_rate={"oa300": 0.0, "giantsteps": 0.0, "sentinels": 0.0},
    )


def test_aggregate_all_pass_bundles():
    agg = ev.aggregate_seeds([_perfect_seed(s) for s in ev.SEEDS])
    assert ev.kdd_b5_decision(agg) == "bundle"
    assert all(g["passed"] for g in agg.values())


def test_dispersion_tripwire_routes_to_byow():
    seeds = [_perfect_seed(s) for s in ev.SEEDS]
    seeds[0].giantsteps_acc1 = 540  # spread 600-540 = 60 > DISPERSION_BOUND_TRACKS
    agg = ev.aggregate_seeds(seeds)
    assert agg["c_giantsteps"]["state"] == "unstable"
    assert ev.kdd_b5_decision(agg) == "byow"


def test_two_of_three_vote_fails_one_gate():
    seeds = [_perfect_seed(s) for s in ev.SEEDS]
    # Two seeds fail OA300 (<=55) -> gate b fails the 2/3 vote.
    seeds[0].oa300_acc1 = 50
    seeds[1].oa300_acc1 = 52
    agg = ev.aggregate_seeds(seeds)
    assert agg["b_oa300"]["passed"] is False
    assert ev.kdd_b5_decision(agg) == "byow"


def test_ece_inconclusive_blocks_bundle():
    seeds = [_perfect_seed(s) for s in ev.SEEDS]
    seeds[0].ece = {"state": "inconclusive", "ece": None, "n": 20}
    agg = ev.aggregate_seeds(seeds)
    assert agg["d_ece"]["state"] == "inconclusive"
    assert ev.kdd_b5_decision(agg) == "byow"


def test_short_oa300_denominator_is_inconclusive():
    # Codex BLOCKER: 56/56 perfect OA300 must NOT pass the ">55/82" gate.
    seeds = [_perfect_seed(s) for s in ev.SEEDS]
    for s in seeds:
        s.oa300_acc1 = 56
        s.oa300_total = 56  # below EXPECTED_OA300 (82)
    agg = ev.aggregate_seeds(seeds)
    assert agg["b_oa300"]["state"] == "inconclusive"
    assert ev.kdd_b5_decision(agg) == "byow"


def test_short_giantsteps_denominator_is_inconclusive():
    seeds = [_perfect_seed(s) for s in ev.SEEDS]
    for s in seeds:
        s.giantsteps_acc1 = 540
        s.giantsteps_total = 540  # below EXPECTED_GIANTSTEPS (661)
    agg = ev.aggregate_seeds(seeds)
    assert agg["c_giantsteps"]["state"] == "inconclusive"
    assert ev.kdd_b5_decision(agg) == "byow"


# --- end-to-end build_report (bundle + calibration-block) ------------------


def _perfect_rows(seed: int) -> list[dict]:
    rows: list[dict] = []
    for i in range(82):
        rows.append(_row("oa300", 100.0 + i % 40, octave_cand=True))
    for i in range(661):
        rows.append(_row("giantsteps", 90.0 + i % 60, octave_cand=True))
    for i in range(12):
        rows.append(_row("sentinel", 170.0, octave_cand=True))
    for r in rows:
        r["_seed"] = seed
    return rows


def _row(corpus: str, truth: float, octave_cand: bool) -> dict:
    return {
        "corpus": corpus,
        "groundTruthBPM": truth,
        "fr18ModelBPM": truth,  # perfect prediction
        "softmaxMax": 0.99,
        "mlAbstained": False,
        "dspCandidatesTop3": [truth * 2.0] if octave_cand else [truth],
    }


def test_build_report_bundles_on_three_perfect_seeds():
    by_seed = {s: _perfect_rows(s) for s in ev.SEEDS}
    report = ev.build_report(by_seed)
    assert report["decision"] == "bundle"
    assert report["calibrationBlock"] is False
    assert sorted(report["seeds"]) == list(ev.SEEDS)


def test_build_report_calibration_block_forces_byow():
    by_seed = {}
    for s in ev.SEEDS:
        rows = _perfect_rows(s)
        # Force a 125/175 bimodal cluster across predictions.
        for i, r in enumerate(rows):
            r["fr18ModelBPM"] = 125.0 if i % 2 == 0 else 175.0
        by_seed[s] = rows
    report = ev.build_report(by_seed)
    assert report["calibrationBlock"] is True
    assert report["decision"] == "byow"


# --- watchlist predicate ---------------------------------------------------


def test_watchlist_predicates():
    # octave_family_error: model an octave off the true label.
    assert (
        ev.watchlist_matches_expected("octave_family_error", 80.0, 160.0, None, None, None) is True
    )
    # model_corrects_dsp: model right, dsp wrong.
    assert (
        ev.watchlist_matches_expected("model_corrects_dsp", 160.0, 160.0, 107.0, None, None) is True
    )
    # none / abstain -> None.
    assert ev.watchlist_matches_expected("none", 160.0, 160.0, None, None, None) is None
    assert (
        ev.watchlist_matches_expected("octave_family_error", None, 160.0, None, None, None) is None
    )


# --- rerun-log governance --------------------------------------------------


def test_rerun_log_family_count_and_signoff():
    log = "\n".join(
        [
            ev.RERUN_LOG_HEADER,
            ev.RERUN_LOG_SEP,
            "| t1 | abc | giantsteps_v2 | run1 | pass | pass | pass | pass | pass | byow |",
            "| t2 | def | giantsteps_v2 | run2 | pass | pass | pass | pass | pass | byow |",
            "| t3 | ghi | giantsteps_v1 | smoke | fail | fail | fail | fail | fail | byow |",
        ]
    )
    assert ev.count_family_runs(log, "giantsteps_v2") == 2  # v1 smoke excluded
    assert ev.count_family_runs(log, "giantsteps_v1") == 1
    assert ev.signoff_present(log, "giantsteps_v2") is False
    log2 = log + "\nSIGNOFF: giantsteps_v2 (Winston 2026-06-04)\n"
    assert ev.signoff_present(log2, "giantsteps_v2") is True


# --- prediction-dir consumption (DD #13 manifest contract) -----------------


def _write_seed_dir(root, seed: int, sha: str, rows: list[dict]) -> None:
    d = root / f"seed_{seed}"
    d.mkdir(parents=True)
    (d / "predictions.json").write_text(json.dumps(rows))
    (d / "manifest.json").write_text(
        json.dumps(
            {
                "seed": seed,
                "checkpointSha256": sha,
                "expectedTrackCount": len(rows),
                "actualTrackCount": len(rows),
                "unresolvedTracks": [],
            }
        )
    )


def test_consume_predictions_rejects_duplicate_sha(tmp_path):
    _write_seed_dir(tmp_path, 42, "deadbeef", [_row("oa300", 120.0, True)])
    _write_seed_dir(tmp_path, 43, "deadbeef", [_row("oa300", 120.0, True)])
    try:
        ev.consume_predictions(tmp_path)
        raised = False
    except ValueError:
        raised = True
    assert raised, "duplicate checkpoint sha across seeds must raise"


def test_consume_predictions_reads_seed_dirs(tmp_path):
    _write_seed_dir(tmp_path, 42, "aaa", [_row("oa300", 120.0, True)])
    _write_seed_dir(tmp_path, 43, "bbb", [_row("oa300", 120.0, True)])
    by_seed = ev.consume_predictions(tmp_path)
    assert sorted(by_seed) == [42, 43]
