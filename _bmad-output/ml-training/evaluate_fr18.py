"""FR-18 promotion-gate evaluator + KDD-B5 bundle-vs-BYOW decision (Story 7.6).

Develop-only. This is a pure ORCHESTRATOR/AGGREGATOR: per-track model
predictions are produced by the Swift production runtime path
(``FR18EvaluationHarnessTests`` → ``BNNSTechnique(modelURL:)`` →
``AudioAnalysisService.analyzeBPM`` with ``ensemblePolicy = .mlOnly``), NOT by a
Python torch/coremltools call (Story 7.6 DD #2). This module consumes the
Swift dump and computes the five FR-18 gates, the multi-seed aggregation
(>=2-of-3 + dispersion tripwire), the FR-25 calibration block, and the KDD-B5
decision.

Story 7.6 DD #12 (blocker fix): every accuracy/calibration gate reads
``fr18ModelBPM`` (= ``MLDiagnosticSnapshot.decodedBPM``), NEVER
``runtimeResultBPM`` (= ``result.bpm``), which is DSP-contaminated on abstain
under ``.mlOnly``. An abstained track (no usable model prediction) counts as
model-INCORRECT for accuracy gates and is excluded from the calibration subset.

The pure-computation functions (gates, aggregation, calibration, bimodality,
watchlist, FR-23) are module-level and importable so ``tests/`` can exercise
them without a corpus or a model (Story 7.6 AC12 (ii) fixture test).
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
import subprocess
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal

import numpy as np

# ---------------------------------------------------------------------------
# Constants (sourced; see Story 7.6 spec + architecture.md FR-18 gates)
# ---------------------------------------------------------------------------

ACC1_TOL = 0.04  # S&M 2018 Acc1: |pred - truth| / truth <= 0.04
OCTAVE_RATIO_TOL = 0.05  # mirror corpus_common (2:1 within 0.05 of 2.0)

# FR-18 gate thresholds (architecture.md FR-18 promotion gates).
GATE_B_OA300_MIN = 55  # strictly > 55/82 (DD #5 — distinct from the 57/82 DSP floor)
GATE_C_GIANTSTEPS_MIN = 537  # >= 537/661
GATE_D_ECE_FLOOR = 0.10  # ECE_half_double < 0.10
GATE_A_WILSON_FLOOR = 0.75  # Wilson 95% LB >= 0.75
TAIL_P95_GIANTSTEPS = 8.0
TAIL_P95_OA300 = 5.0
TAIL_P95_SENTINELS = 3.0

# FR-25 prior-bundle calibration anchor (MODEL_CARD.md + 4-6 investigation).
PRIOR_SOFTMAX_MAX_P95 = 0.294
PRIOR_ECE_HALF_DOUBLE = 0.5
BIMODAL_ANCHORS = (125.0, 175.0)
BIMODAL_ANCHOR_TOL_BPM = 3.0
BIMODAL_FRACTION_BOUND = 0.30  # > this fraction clustered at 125/175 => fail

# Calibration robustness (Story 7.6 AC8 / Mary).
ECE_MIN_SUBSET_N = 100  # below this, gate (d) is "inconclusive" (-> byow)

# Seed-dispersion tripwire (Story 7.6 AC7 / DD #14). Per-gate Acc1 spread
# (max - min across seeds, in tracks) over this bound => gate "unstable" -> byow.
DISPERSION_BOUND_TRACKS = 10
DISPERSION_BOUND_SENTINELS = 2  # n=12 sentinel gate is near-binary; tighter bound
EXPECTED_SENTINELS = 12  # gate (a) ideal; k<12 resolved => gate (a) inconclusive (AC13)

# Expected corpus denominators. The gates are "> 55/82" and ">= 537/661" — a
# SHORT denominator (e.g. 56 perfect OA300 rows passing ">55") would measure a
# different population, so a below-expected total => gate "inconclusive" -> byow
# (Codex diff-review BLOCKER). OA300 is a fixed 82-track fixture; GiantSteps is
# the 661-track ground-truth corpus.
EXPECTED_OA300 = 82
EXPECTED_GIANTSTEPS = 661

SEEDS = (42, 43, 44)
HARNESS_VERSION = 1

Decision = Literal["bundle", "byow"]
GateState = Literal["pass", "fail", "inconclusive", "unstable"]


# ---------------------------------------------------------------------------
# Pure computation: accuracy + octave
# ---------------------------------------------------------------------------


def acc1_correct(pred: float | None, truth: float) -> bool:
    """Acc1 hit on the MODEL prediction. ``None`` (abstain) => incorrect (DD #12)."""
    if pred is None or not math.isfinite(pred) or pred <= 0:
        return False
    if not math.isfinite(truth) or truth <= 0:
        return False
    return abs(pred - truth) / truth <= ACC1_TOL


def octave_match(pred: float | None, truth: float) -> bool:
    """Octave-tolerant Acc1: pred, 2*pred, or pred/2 within ACC1_TOL of truth."""
    if pred is None or not math.isfinite(pred) or pred <= 0:
        return False
    if not math.isfinite(truth) or truth <= 0:
        return False
    for candidate in (pred, 2.0 * pred, pred / 2.0):
        if abs(candidate - truth) / truth <= ACC1_TOL:
            return True
    return False


def count_acc1(rows: list[dict]) -> int:
    """Count Acc1 hits over per-track rows (each has fr18ModelBPM + groundTruthBPM)."""
    return sum(1 for r in rows if acc1_correct(r.get("fr18ModelBPM"), r["groundTruthBPM"]))


def count_acc1_octave(rows: list[dict]) -> int:
    return sum(1 for r in rows if octave_match(r.get("fr18ModelBPM"), r["groundTruthBPM"]))


def wilson_lower_bound(k: int, n: int, z: float = 1.96) -> float:
    """Wilson score interval lower bound for k successes in n trials (95% at z=1.96).

    At n=12 this is effectively all-or-nothing: 12/12 -> ~0.76, 11/12 -> ~0.65
    (Story 7.6 AC13 / Mary). Returns 0.0 for n == 0.
    """
    if n == 0:
        return 0.0
    phat = k / n
    denom = 1.0 + z * z / n
    center = phat + z * z / (2 * n)
    margin = z * math.sqrt((phat * (1 - phat) + z * z / (4 * n)) / n)
    return max(0.0, (center - margin) / denom)


# ---------------------------------------------------------------------------
# Pure computation: calibration (ECE_half_double, softmax_max_p95, bimodality)
# ---------------------------------------------------------------------------


def in_half_double_subset(
    truth: float, candidates: list[float], tol: float = OCTAVE_RATIO_TOL
) -> bool:
    """True if ``truth`` is half/double of any DSP candidate (top-3), within tol.

    Subset definition for ECE_half_double (architecture.md gate (d)): a track
    counts when its true BPM is an octave (2:1 or 1:2) of a DSP candidate.
    """
    for cand in candidates:
        if cand <= 0 or truth <= 0:
            continue
        ratio = max(truth, cand) / min(truth, cand)
        if abs(ratio - 2.0) <= 2.0 * tol:
            return True
    return False


def compute_ece_half_double(rows: list[dict]) -> dict:
    """ECE over the half/double-of-DSP-candidate subset (Story 7.6 AC8 / DD #8).

    Count-adaptive equal-frequency binning (bins = min(10, N // 10)); reports
    ``inconclusive`` when N < ECE_MIN_SUBSET_N (fail-safe to byow). Confidence =
    softmaxMax (top-label calibration); rows = finite decodedBPM + softmaxMax.
    """
    subset = [
        r
        for r in rows
        if r.get("fr18ModelBPM") is not None
        and r.get("softmaxMax") is not None
        and math.isfinite(r["fr18ModelBPM"])
        and math.isfinite(r["softmaxMax"])
        and in_half_double_subset(r["groundTruthBPM"], list(r.get("dspCandidatesTop3", [])))
    ]
    n = len(subset)
    if n < ECE_MIN_SUBSET_N:
        return {
            "ece": None,
            "state": "inconclusive",
            "n": n,
            "reason": f"subset N={n} < {ECE_MIN_SUBSET_N}",
            "bins": [],
        }

    confs = np.array([r["softmaxMax"] for r in subset], dtype=float)
    correct = np.array(
        [1.0 if acc1_correct(r["fr18ModelBPM"], r["groundTruthBPM"]) else 0.0 for r in subset]
    )
    order = np.argsort(confs)
    confs, correct = confs[order], correct[order]
    n_bins = min(10, n // 10)
    edges = np.array_split(np.arange(n), n_bins)
    ece = 0.0
    bins: list[dict] = []
    for idx in edges:
        if len(idx) == 0:
            continue
        bin_conf = float(confs[idx].mean())
        bin_acc = float(correct[idx].mean())
        weight = len(idx) / n
        ece += weight * abs(bin_conf - bin_acc)
        bins.append({"count": int(len(idx)), "meanConf": bin_conf, "acc": bin_acc})
    state: GateState = "pass" if ece < GATE_D_ECE_FLOOR else "fail"
    return {"ece": ece, "state": state, "n": n, "bins": bins}


def percentile(values: list[float], p: float) -> float:
    if not values:
        return 0.0
    return float(np.percentile(np.array(values, dtype=float), p * 100.0))


def bimodality_125_175(preds: list[float], tol: float = BIMODAL_ANCHOR_TOL_BPM) -> dict:
    """Direct test of the named 125/175 failure (Story 7.6 DD #15 / Mary).

    Default test = fraction of predictions within +/-tol of 125 OR 175. Sarle's
    bimodality coefficient is reported as a secondary descriptor only.
    """
    finite = [p for p in preds if p is not None and math.isfinite(p) and p > 0]
    n = len(finite)
    if n == 0:
        return {"fraction": 0.0, "reappears": False, "n": 0, "sarleBC": None}
    clustered = sum(1 for p in finite if any(abs(p - anchor) <= tol for anchor in BIMODAL_ANCHORS))
    fraction = clustered / n
    arr = np.array(finite, dtype=float)
    sarle = _sarle_bimodality_coefficient(arr)
    return {
        "fraction": fraction,
        "reappears": fraction > BIMODAL_FRACTION_BOUND,
        "n": n,
        "sarleBC": sarle,
        "test": "direct-anchor-clustering",
    }


def _sarle_bimodality_coefficient(arr: np.ndarray) -> float | None:
    """Sarle's BC = (skew^2 + 1) / kurtosis. Secondary descriptor only."""
    if arr.size < 4:
        return None
    mean = float(arr.mean())
    std = float(arr.std())
    if std == 0.0:
        return None
    z = (arr - mean) / std
    skew = float((z**3).mean())
    kurt = float((z**4).mean())  # non-excess
    if kurt == 0.0:
        return None
    return (skew * skew + 1.0) / kurt


# ---------------------------------------------------------------------------
# Pure computation: per-seed gates + multi-seed aggregation
# ---------------------------------------------------------------------------


@dataclass
class SeedGateResult:
    seed: int
    oa300_acc1: int
    oa300_total: int
    giantsteps_acc1: int
    giantsteps_total: int
    sentinels_correct: int
    sentinels_total: int
    wilson_lb: float
    ece: dict
    tail_p95: dict
    softmax_max_p95: float
    bimodality: dict
    ml_abstain_rate: dict


def evaluate_seed(rows: list[dict]) -> SeedGateResult:
    """Compute one seed's gate inputs from its per-track rows."""
    by_corpus: dict[str, list[dict]] = {}
    for r in rows:
        by_corpus.setdefault(r["corpus"], []).append(r)

    oa = by_corpus.get("oa300", [])
    gs = by_corpus.get("giantsteps", [])
    sent = by_corpus.get("sentinel", [])

    def tail_p95(group: list[dict]) -> float:
        # Abstained tracks count as a FULL-SCALE miss against the tail gate (a
        # model that abstains on its worst tracks must not get a clean tail —
        # consistent with DD #12 abstain=incorrect). Un-scorable ground truth
        # (non-finite / <=0) is skipped.
        errs: list[float] = []
        for r in group:
            truth = r["groundTruthBPM"]
            if not math.isfinite(truth) or truth <= 0:
                continue
            bpm = r.get("fr18ModelBPM")
            if bpm is not None and math.isfinite(bpm):
                errs.append(abs(bpm - truth))
            else:
                errs.append(truth)  # abstain => ~100% error, lands in the tail
        return percentile(errs, 0.95)

    def abstain_rate(group: list[dict]) -> float:
        if not group:
            return 0.0
        return sum(1 for r in group if r.get("mlAbstained")) / len(group)

    sent_correct = count_acc1(sent)
    return SeedGateResult(
        seed=int(rows[0].get("_seed", 0)) if rows else 0,
        oa300_acc1=count_acc1(oa),
        oa300_total=len(oa),
        giantsteps_acc1=count_acc1(gs),
        giantsteps_total=len(gs),
        sentinels_correct=sent_correct,
        sentinels_total=len(sent),
        wilson_lb=wilson_lower_bound(sent_correct, len(sent)),
        ece=compute_ece_half_double(oa + gs + sent),
        tail_p95={
            "giantSteps": tail_p95(gs),
            "oa300": tail_p95(oa),
            "sentinels": tail_p95(sent),
        },
        softmax_max_p95=percentile(
            [
                r["softmaxMax"]
                for r in (oa + gs + sent)
                if r.get("softmaxMax") is not None and math.isfinite(r["softmaxMax"])
            ],
            0.95,
        ),
        bimodality=bimodality_125_175(
            [r["fr18ModelBPM"] for r in (oa + gs + sent) if r.get("fr18ModelBPM") is not None]
        ),
        ml_abstain_rate={
            "oa300": abstain_rate(oa),
            "giantsteps": abstain_rate(gs),
            "sentinels": abstain_rate(sent),
        },
    )


def _seed_gate_pass(seed: SeedGateResult) -> dict[str, bool]:
    """Per-gate pass/fail for ONE seed (a-e)."""
    ece_pass = seed.ece.get("state") == "pass"
    # Per-seed gate (a) passes on the RESOLVED sentinel count (Wilson over k);
    # a k<12 resolution is escalated to "inconclusive" at the aggregate level
    # (AC13), not silently passed here.
    return {
        "a_sentinels": seed.sentinels_total >= 1 and seed.wilson_lb >= GATE_A_WILSON_FLOOR,
        "b_oa300": seed.oa300_acc1 > GATE_B_OA300_MIN,
        "c_giantsteps": seed.giantsteps_acc1 >= GATE_C_GIANTSTEPS_MIN,
        "d_ece": ece_pass,
        "e_tail": (
            seed.tail_p95["giantSteps"] < TAIL_P95_GIANTSTEPS
            and seed.tail_p95["oa300"] < TAIL_P95_OA300
            and seed.tail_p95["sentinels"] < TAIL_P95_SENTINELS
        ),
    }


def aggregate_seeds(seeds: list[SeedGateResult]) -> dict:
    """>=2-of-3 vote + dispersion tripwire (Story 7.6 AC7 / DD #14)."""
    per_seed = {s.seed: _seed_gate_pass(s) for s in seeds}
    gate_keys = ["a_sentinels", "b_oa300", "c_giantsteps", "d_ece", "e_tail"]
    # Per-gate dispersion (max-min across seeds) on the Acc1-bearing integer gates
    # — over the bound => "unstable" -> byow (DD #14). Sentinels get a tighter
    # bound (the n=12 gate is near-binary).
    dispersion_for_gate: dict[str, tuple[dict[int, int], int]] = {
        "a_sentinels": ({s.seed: s.sentinels_correct for s in seeds}, DISPERSION_BOUND_SENTINELS),
        "b_oa300": ({s.seed: s.oa300_acc1 for s in seeds}, DISPERSION_BOUND_TRACKS),
        "c_giantsteps": ({s.seed: s.giantsteps_acc1 for s in seeds}, DISPERSION_BOUND_TRACKS),
    }
    aggregated: dict[str, dict] = {}
    for gk in gate_keys:
        votes = [per_seed[s.seed][gk] for s in seeds]
        passed = sum(votes) >= 2
        state: GateState = "pass" if passed else "fail"
        entry: dict = {"votes": votes, "passed": passed, "state": state}
        if gk in dispersion_for_gate:
            vals_map, bound = dispersion_for_gate[gk]
            vals = list(vals_map.values())
            spread = max(vals) - min(vals)
            entry.update(
                {
                    "min": min(vals),
                    "max": max(vals),
                    "median": statistics.median(vals),
                    "spread": spread,
                }
            )
            if spread > bound:
                entry["state"] = "unstable"
                entry["passed"] = False
        # gate (a) inconclusive: any seed resolved fewer than the 12 expected
        # sentinels (AC13) -> cannot pass (fail-safe to byow).
        if gk == "a_sentinels" and any(0 < s.sentinels_total < EXPECTED_SENTINELS for s in seeds):
            entry["state"] = "inconclusive"
            entry["passed"] = False
        # gate (b)/(c) denominator guard: any corpus total != the expected
        # denominator (short OR over-count from stale/duplicate rows) means the
        # ">N/D" gate measures a different population -> inconclusive -> byow
        # (Codex diff-review). Surface the mismatch.
        if gk == "b_oa300" and any(s.oa300_total != EXPECTED_OA300 for s in seeds):
            entry["state"] = "inconclusive"
            entry["passed"] = False
            entry["denominatorMismatch"] = {s.seed: s.oa300_total for s in seeds}
        if gk == "c_giantsteps" and any(s.giantsteps_total != EXPECTED_GIANTSTEPS for s in seeds):
            entry["state"] = "inconclusive"
            entry["passed"] = False
            entry["denominatorMismatch"] = {s.seed: s.giantsteps_total for s in seeds}
        # gate (d) inconclusive propagation: if any seed is inconclusive, the
        # aggregate cannot pass (fail-safe to byow).
        if gk == "d_ece" and any(s.ece.get("state") == "inconclusive" for s in seeds):
            entry["state"] = "inconclusive"
            entry["passed"] = False
        aggregated[gk] = entry
    return aggregated


def kdd_b5_decision(aggregated: dict) -> Decision:
    """Bundle iff ALL 5 gates passed (any fail/inconclusive/unstable -> byow)."""
    return "bundle" if all(g["passed"] for g in aggregated.values()) else "byow"


# ---------------------------------------------------------------------------
# Pure computation: marginal watchlist + FR-23 octave normalization
# ---------------------------------------------------------------------------


def watchlist_matches_expected(
    predicate: str,
    model_bpm: float | None,
    tony_label: float,
    dsp_bpm: float | None,
    rekordbox_bpm: float | None,
    grid_bpm: float | None,
) -> bool | None:
    """Evaluate a Story-7.4 verificationPredicate against the v2 model prediction.

    Closed enum {octave_family_error, model_corrects_dsp, model_corrects_metadata,
    harmonic_ratio_error, none}. Returns None when undecidable (e.g. abstain).
    """
    if predicate == "none":
        return None
    if model_bpm is None or not math.isfinite(model_bpm) or model_bpm <= 0:
        return None
    if predicate == "octave_family_error":
        # Expected failure: model lands an octave off the true label.
        return octave_match(model_bpm, tony_label) and not acc1_correct(model_bpm, tony_label)
    if predicate == "harmonic_ratio_error":
        if tony_label <= 0:
            return None
        ratio = max(model_bpm, tony_label) / min(model_bpm, tony_label)
        return abs(ratio - 1.5) <= 0.03 or abs(ratio - 3.0) <= 0.03
    if predicate == "model_corrects_dsp":
        if dsp_bpm is None:
            return None
        return acc1_correct(model_bpm, tony_label) and not acc1_correct(dsp_bpm, tony_label)
    if predicate == "model_corrects_metadata":
        meta = rekordbox_bpm if rekordbox_bpm is not None else grid_bpm
        if meta is None:
            return None
        return acc1_correct(model_bpm, tony_label) and not acc1_correct(meta, tony_label)
    return None


# ---------------------------------------------------------------------------
# Rerun-log governance (Story 7.6 AC9 / AC10) — machine-parseable grammar
# ---------------------------------------------------------------------------

RERUN_LOG_HEADER = (
    "| timestamp | gitSha | checkpointFamilyId | checkpointShas | whatChanged | "
    "gate_a | gate_b | gate_c | gate_d | gate_e | decision |"
)
RERUN_LOG_SEP = "|---|---|---|---|---|---|---|---|---|---|---|"


def count_family_runs(log_text: str, family_id: str) -> int:
    """Count committed rerun-log rows for a v2 checkpoint family (v1 smoke excluded)."""
    count = 0
    for line in log_text.splitlines():
        if not line.startswith("|") or line.startswith("| timestamp") or set(line) <= set("|-"):
            continue
        cols = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cols) >= 3 and cols[2] == family_id:
            count += 1
    return count


def _line_token_after(line: str, prefix: str) -> str | None:
    """Return the exact next whitespace-delimited token after ``prefix:`` on a
    line, or None. Exact-token (not substring) so ``SIGNOFF: giantsteps_v2`` does
    NOT match a ``giantsteps_v22`` family."""
    marker = f"{prefix}:"
    idx = line.find(marker)
    if idx < 0:
        return None
    rest = line[idx + len(marker) :].strip()
    return rest.split()[0] if rest else None


def signoff_present(log_text: str, family_id: str) -> bool:
    """True if a ``SIGNOFF: <family_id>`` line is present (AC10 run 4+ gate)."""
    return any(_line_token_after(line, "SIGNOFF") == family_id for line in log_text.splitlines())


def bugfix_exception_present(log_text: str, family_id: str) -> bool:
    """True if an ``EXCEPTION:bugfix-not-tuning <family> <issue>`` line is present
    AND carries an issue token (AC10). A bugfix re-run is allowed past the N=3
    tripwire but is flagged for review (see ``main``)."""
    for line in log_text.splitlines():
        if "EXCEPTION:bugfix-not-tuning" not in line:
            continue
        rest = line.split("EXCEPTION:bugfix-not-tuning", 1)[1].split()
        # require <family> + a non-empty issue token
        if len(rest) >= 2 and rest[0] == family_id:
            return True
    return False


# ---------------------------------------------------------------------------
# Driver + corpus resolution (operator-run path; not exercised by the fixture test)
# ---------------------------------------------------------------------------

HERE = Path(__file__).resolve().parent


@dataclass
class Args:
    runtime_predictions: Path | None = None
    out_dir: Path = field(default_factory=lambda: HERE)
    allow_partial_seeds: bool = False
    smoke: bool = False
    what_changed: str = "initial run"
    family_id: str = "giantsteps_v2"


def _load_seed_dir(seed_dir: Path) -> tuple[dict, list[dict]]:
    manifest = json.loads((seed_dir / "manifest.json").read_text())
    rows = json.loads((seed_dir / "predictions.json").read_text())
    actual = manifest["actualTrackCount"]
    expected = manifest["expectedTrackCount"]
    if actual + len(manifest.get("unresolvedTracks", [])) != expected:
        raise ValueError(
            f"{seed_dir}: count mismatch actual={actual} "
            f"unresolved={len(manifest.get('unresolvedTracks', []))} expected={expected}"
        )
    for r in rows:
        r["_seed"] = manifest["seed"]
    return manifest, rows


def consume_predictions(pred_root: Path) -> dict[int, list[dict]]:
    """Glob seed_*/ dirs, validate, reject duplicate seeds (DD #13)."""
    by_seed: dict[int, list[dict]] = {}
    seen_sha: dict[int, str] = {}
    for seed_dir in sorted(pred_root.glob("seed_*")):
        if not (seed_dir / "manifest.json").exists():
            continue
        manifest, rows = _load_seed_dir(seed_dir)
        seed = manifest["seed"]
        if seed in by_seed:
            raise ValueError(f"duplicate seed {seed} across prediction dirs")
        sha = manifest.get("checkpointSha256", "")
        if sha in seen_sha.values():
            raise ValueError(f"two seed dirs share checkpoint sha {sha}")
        seen_sha[seed] = sha
        by_seed[seed] = rows
    return by_seed


def leave_artist_out_block(by_seed: dict[int, list[dict]]) -> dict:
    """AC4: Acc1 / Acc1-normalized / delta on tony_lao vs tony_val (median across seeds)."""
    lao_a1, lao_n1, val_a1 = [], [], []
    for _seed, rows in sorted(by_seed.items()):
        lao = [r for r in rows if r.get("corpus") == "tony_lao"]
        val = [r for r in rows if r.get("corpus") == "tony_val"]
        if not lao or not val:
            continue
        lao_a1.append(count_acc1(lao))
        lao_n1.append(count_acc1_octave(lao))
        val_a1.append(count_acc1(val))
    if not lao_a1:
        return {"present": False}
    acc1 = int(statistics.median(lao_a1))
    return {
        "present": True,
        "acc1": acc1,
        "acc1Normalized": int(statistics.median(lao_n1)),
        "delta": acc1 - int(statistics.median(val_a1)),
    }


def marginal_watchlist_block(
    by_seed: dict[int, list[dict]], watchlist: dict[str, dict] | None
) -> dict:
    """AC5: per-track matchesExpected over the 241 Marginal watchlist tracks.

    Uses the median seed's prediction per track against the Story-7.4
    verificationPredicate enum. Returns ``{present: False}`` when no marginal
    rows are in the predictions (e.g. the OA300/GS/sentinel-only dev smoke).
    """
    if not watchlist:
        return {"present": False}
    # Median model BPM per track across seeds.
    per_track: dict[str, list[float]] = {}
    for _seed, rows in sorted(by_seed.items()):
        for r in rows:
            if r.get("corpus") != "marginal":
                continue
            bpm = r.get("fr18ModelBPM")
            if bpm is not None and math.isfinite(bpm):
                per_track.setdefault(r["trackId"], []).append(bpm)
    if not per_track:
        return {"present": False}
    results = []
    matched = 0
    for track_id, bpms in sorted(per_track.items()):
        wl = watchlist.get(track_id)
        if wl is None:
            continue
        model_bpm = statistics.median(bpms)
        m = watchlist_matches_expected(
            wl.get("verificationPredicate", "none"),
            model_bpm,
            wl.get("tonyLabel", 0.0),
            wl.get("dspBPM"),
            wl.get("rekordboxBPM"),
            wl.get("gridBPM"),
        )
        if m is True:
            matched += 1
        results.append(
            {
                "track_id": track_id,
                "modelBPM": model_bpm,
                "verificationPredicate": wl.get("verificationPredicate"),
                "matchesExpected": m,
            }
        )
    return {
        "present": True,
        "evaluated": len(results),
        "matchedExpected": matched,
        "tracks": results,
    }


def build_report(
    by_seed: dict[int, list[dict]],
    watchlist: dict[str, dict] | None = None,
    checkpoint_shas: dict[int, str] | None = None,
) -> dict:
    """Assemble the full fr-18-evaluation payload from per-seed predictions."""
    seed_results = []
    for seed, rows in sorted(by_seed.items()):
        sr = evaluate_seed(rows)
        sr.seed = seed
        seed_results.append(sr)
    aggregated = aggregate_seeds(seed_results)
    decision = kdd_b5_decision(aggregated)
    # FR-25 (AC8): a 125/175 bimodality reappearance blocks bundling regardless
    # of the 5 Acc1/ECE gates ("calibration failure blocks bundling").
    bimodal_reappears = any(s.bimodality.get("reappears") for s in seed_results)
    calibration_block = bool(bimodal_reappears)
    if calibration_block:
        decision = "byow"
    v2_ece_vals = [
        s.ece["ece"]
        for s in seed_results
        if isinstance(s.ece.get("ece"), (int, float)) and s.ece.get("ece") is not None
    ]
    return {
        "decision": decision,
        "calibrationBlock": calibration_block,
        "checkpointShas": checkpoint_shas or {},
        "leaveArtistOut": leave_artist_out_block(by_seed),
        "marginalWatchlistResults": marginal_watchlist_block(by_seed, watchlist),
        "seeds": [s.seed for s in seed_results],
        "perSeed": [
            {
                "seed": s.seed,
                "oa300Acc1": s.oa300_acc1,
                "oa300Total": s.oa300_total,
                "giantStepsAcc1": s.giantsteps_acc1,
                "giantStepsTotal": s.giantsteps_total,
                "sentinelsCorrect": s.sentinels_correct,
                "sentinelsExpanded": s.sentinels_total,
                "dnbWilson95LowerBound": s.wilson_lb,
                "eceHalfDouble": s.ece,
                "tailErrorP95": s.tail_p95,
                "softmaxMaxP95": s.softmax_max_p95,
                "bimodality": s.bimodality,
                "mlAbstainRate": s.ml_abstain_rate,
            }
            for s in seed_results
        ],
        "aggregatedGates": aggregated,
        "fr25Anchor": {
            "priorSoftmaxMaxP95": PRIOR_SOFTMAX_MAX_P95,
            "priorEceHalfDouble": PRIOR_ECE_HALF_DOUBLE,
            "v2SoftmaxMaxP95Median": statistics.median([s.softmax_max_p95 for s in seed_results])
            if seed_results
            else None,
            "v2EceHalfDoubleMedian": statistics.median(v2_ece_vals) if v2_ece_vals else None,
            "bimodalReappearsAnySeed": any(s.bimodality.get("reappears") for s in seed_results),
        },
    }


def write_markdown(report: dict, path: Path, smoke: bool) -> None:
    lines = [
        f"decision: {report['decision']}" + (" (smoke; v2 pending)" if smoke else ""),
        "",
        "# FR-18 promotion-gate evaluation (Story 7.6)",
        "",
        f"Seeds evaluated: {report['seeds']}",
        "",
        "## Aggregated gates (>=2-of-3 + dispersion tripwire)",
        "",
        "| gate | state | passed | detail |",
        "|---|---|---|---|",
    ]
    for gk, g in report["aggregatedGates"].items():
        detail = f"votes={g['votes']}" + (f" spread={g.get('spread')}" if "spread" in g else "")
        lines.append(f"| {gk} | {g['state']} | {g['passed']} | {detail} |")
    lines += [
        "",
        "## FR-25 calibration anchor (side-by-side)",
        "",
        f"- softmax_max_p95: v2={report['fr25Anchor']['v2SoftmaxMaxP95Median']} "
        f"vs prior={PRIOR_SOFTMAX_MAX_P95}",
        f"- ECE_half_double: v2={report['fr25Anchor']['v2EceHalfDoubleMedian']} "
        f"vs prior≈{PRIOR_ECE_HALF_DOUBLE}",
        f"- 125/175 bimodal reappears: {report['fr25Anchor']['bimodalReappearsAnySeed']}",
    ]
    if smoke:
        lines += [
            "",
            "## OPERATOR REMAINDER (v2 pending — Story 7.5 training run + KDD-B4 signoff)",
            "",
            "- [ ] Run the 3-seed evaluation: "
            "`make fr18-produce` per seed (BNNS_MODEL_URL=giantsteps_v2_seed_{42,43,44}.mlmodel), then `make fr18-evaluate` once",
            "- [ ] Finalize the `decision:` line above from the real 3-seed aggregate",
            "- [ ] Backfill `marginal-watchlist-stability.json` `seeds[]` (Story 7.5)",
        ]
    path.write_text("\n".join(lines) + "\n")


def append_rerun_row(
    log_path: Path, report: dict, family_id: str, what_changed: str, git_sha: str
) -> None:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if not log_path.exists():
        log_path.write_text(
            "# Story 7.6 — FR-18 re-run governance log\n\n"
            "Committed (NOT .gitignore'd). One row per `evaluate_fr18.py` invocation.\n"
            "N=3 tripwire: run 4+ for the same v2 checkpointFamilyId requires a "
            "`SIGNOFF: <familyId>` line (a `EXCEPTION:bugfix-not-tuning <issue>` line "
            "cites a bugfix). The v1 smoke is a separate family, excluded from the count.\n\n"
            + RERUN_LOG_HEADER
            + "\n"
            + RERUN_LOG_SEP
            + "\n"
        )
    g = report["aggregatedGates"]

    def st(k: str) -> str:
        return g[k]["state"]

    shas = report.get("checkpointShas", {}) or {}
    shas_cell = ",".join(f"{s}:{shas[s]}" for s in sorted(shas)) if shas else "n/a"
    row = (
        f"| {ts} | {git_sha} | {family_id} | {shas_cell} | {what_changed} | "
        f"{st('a_sentinels')} | {st('b_oa300')} | {st('c_giantsteps')} | "
        f"{st('d_ece')} | {st('e_tail')} | {report['decision']} |\n"
    )
    with log_path.open("a") as fh:
        fh.write(row)


def write_fr23(by_seed: dict[int, list[dict]], path: Path) -> None:
    """FR-23 octave-policy consistency report (Story 7.6 AC3 / DD #1).

    Raw vs octave-normalized Acc1 are COMPUTED (median across seeds per corpus).
    The policy-equivalence is a DOCUMENTATION assertion, not a machine gate: the
    runtime does not branch on OctaveEquivalencePolicy (6.5b), so octave behavior
    is governed by MetadataPolicy + BPMAnalyzer.resolveOctaveAmbiguity.
    """
    corpora = ["oa300", "giantsteps", "sentinel"]
    rows_by_corpus: dict[str, list[tuple[int, int, int]]] = {c: [] for c in corpora}
    for _seed, rows in sorted(by_seed.items()):
        by_c: dict[str, list[dict]] = {}
        for r in rows:
            by_c.setdefault(r["corpus"], []).append(r)
        for c in corpora:
            grp = by_c.get(c, [])
            rows_by_corpus[c].append((count_acc1(grp), count_acc1_octave(grp), len(grp)))

    lines = [
        "# FR-23 octave-policy consistency (Story 7.6)",
        "",
        "## Policy equivalence (DOCUMENTATION assertion, not a machine gate — DD #1)",
        "",
        "- **Runtime octave handling:** `MetadataPolicy`-governed octave "
        "corroboration + the `BPMAnalyzer.resolveOctaveAmbiguity` DSP step. "
        "`OctaveEquivalencePolicy.default == .octaveAwareWithPenalty` is the "
        "*declared* policy but is configurable-but-reserved (inert) as of "
        "Story 6.5b — the runtime does not branch on the enum.",
        "- **Training-loss octave policy:** Story 7.3 `ablation/octave_aware_loss.py` "
        "(octave-aware).",
        "- **Assertion:** the two are documented-equivalent on policy INTENT "
        "(both octave-aware). This is human-authored; no data input makes it fail "
        "automatically.",
        "",
        "## Raw vs octave-normalized Acc1 (computed, median across seeds)",
        "",
        "| corpus | raw Acc1 (median) | octave-normalized Acc1 (median) | total |",
        "|---|---|---|---|",
    ]
    for c in corpora:
        triples = rows_by_corpus[c]
        if not triples:
            continue
        raw_med = statistics.median([t[0] for t in triples])
        oct_med = statistics.median([t[1] for t in triples])
        total = triples[0][2]
        lines.append(f"| {c} | {raw_med} | {oct_med} | {total} |")
    path.write_text("\n".join(lines) + "\n")


def _load_watchlist() -> dict[str, dict] | None:
    """Load marginal-watchlist.json keyed by track_id (Story 7.4 output)."""
    path = HERE / "marginal-watchlist.json"
    if not path.exists():
        return None
    raw = json.loads(path.read_text())
    # Key explicitly off "watchlist" — the real file's first list-valued key is
    # `_consumedBy` (["7.5","7.6"]), NOT the records, so a `next(isinstance list)`
    # heuristic silently grabs the wrong list and crashes (code-review BLOCKER).
    if isinstance(raw, list):
        rows = raw
    elif isinstance(raw, dict) and isinstance(raw.get("watchlist"), list):
        rows = raw["watchlist"]
    else:
        rows = []
    out: dict[str, dict] = {}
    for r in rows:
        out[str(r["track_id"])] = {
            "verificationPredicate": r.get("verificationPredicate", "none"),
            "tonyLabel": r.get("tonyLabel", 0.0),
            "dspBPM": r.get("dspBPM"),
            "rekordboxBPM": r.get("rekordboxBPM"),
            "gridBPM": r.get("gridBPM"),
        }
    return out


def collect_checkpoint_shas(pred_root: Path) -> dict[int, str]:
    """Map seed -> checkpointSha256 from each seed dir's manifest (AC9c)."""
    out: dict[int, str] = {}
    for seed_dir in sorted(pred_root.glob("seed_*")):
        mpath = seed_dir / "manifest.json"
        if not mpath.exists():
            continue
        m = json.loads(mpath.read_text())
        out[int(m["seed"])] = str(m.get("checkpointSha256", "unavailable"))
    return out


def _sanitize(obj: object) -> object:
    """Recursively replace non-finite floats with None so the JSON is strict-valid
    (no bare NaN/Infinity tokens)."""
    if isinstance(obj, float):
        return obj if math.isfinite(obj) else None
    if isinstance(obj, dict):
        return {k: _sanitize(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_sanitize(v) for v in obj]
    return obj


def _git_sha() -> str:
    try:
        sha = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        dirty = subprocess.run(
            ["git", "status", "--porcelain"], capture_output=True, text=True, check=True
        ).stdout.strip()
        return f"{sha}-dirty" if dirty else sha
    except Exception:
        return "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description="FR-18 promotion-gate evaluator (Story 7.6)")
    parser.add_argument(
        "--runtime-predictions",
        type=Path,
        required=True,
        help="Directory containing seed_*/{manifest,predictions}.json (Swift dump)",
    )
    parser.add_argument("--out-dir", type=Path, default=HERE)
    parser.add_argument("--allow-partial-seeds", action="store_true")
    parser.add_argument("--smoke", action="store_true", help="negative-control / v1 smoke mode")
    parser.add_argument("--what-changed", type=str, default="initial run")
    parser.add_argument("--family-id", type=str, default="giantsteps_v2")
    ns = parser.parse_args()

    by_seed = consume_predictions(ns.runtime_predictions)
    if not by_seed:
        raise SystemExit("FR18CheckpointMissing: no seed_*/ prediction dirs found")
    if not ns.smoke and not ns.allow_partial_seeds and set(by_seed) != set(SEEDS):
        raise SystemExit(
            f"FR18SeedFamily: authoritative run requires exactly seeds {sorted(SEEDS)}, "
            f"got {sorted(by_seed)}; pass --allow-partial-seeds for a partial/exploratory run"
        )

    watchlist = _load_watchlist()
    checkpoint_shas = collect_checkpoint_shas(ns.runtime_predictions)
    report = build_report(by_seed, watchlist=watchlist, checkpoint_shas=checkpoint_shas)

    # N=3 governance precondition (run 4+ requires signoff) — v2 families only.
    log_path = HERE.parent / "implementation-artifacts" / "7-6-fr18-rerun-log.md"
    if not ns.smoke and log_path.exists():
        log_text = log_path.read_text()
        prior_runs = count_family_runs(log_text, ns.family_id)
        if prior_runs >= 3 and not signoff_present(log_text, ns.family_id):
            if bugfix_exception_present(log_text, ns.family_id):
                print(
                    f"WARNING: run {prior_runs + 1} for {ns.family_id} proceeds under "
                    "EXCEPTION:bugfix-not-tuning — flagged for review."
                )
            else:
                raise SystemExit(
                    f"FR18RerunSignoffRequired: {prior_runs} prior runs for family "
                    f"{ns.family_id}; add a 'SIGNOFF: {ns.family_id}' line (or an "
                    f"'EXCEPTION:bugfix-not-tuning {ns.family_id} <issue>' line) before "
                    f"run {prior_runs + 1}"
                )

    ns.out_dir.mkdir(parents=True, exist_ok=True)
    (ns.out_dir / "fr-18-evaluation.json").write_text(
        json.dumps(_sanitize(report), indent=2, sort_keys=True, allow_nan=False) + "\n"
    )
    write_markdown(report, ns.out_dir / "fr-18-evaluation.md", ns.smoke)
    write_fr23(by_seed, ns.out_dir / "fr-23-octave-consistency.md")
    append_rerun_row(log_path, report, ns.family_id, ns.what_changed, _git_sha())

    print(f"FR-18 decision: {report['decision']} (seeds {report['seeds']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
