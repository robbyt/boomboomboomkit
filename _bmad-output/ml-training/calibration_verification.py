"""FR-25 calibration verification (Story 7.7 AC3 / AC4 / Task 3).

Develop-only. Consumes the v2 checkpoint's per-track runtime predictions (the
Story-7.6 ``seed_*/`` dumps for the FR-24-promoted arm — "final model" = the v2
checkpoint, IDENTICAL under bundle vs byow because both run the same ``.mlOnly``
BNNS path, so calibration is downstream of, not an input to, the decision —
DD #14) and renders ``calibration-verification.md`` with the v2 metrics side by
side against the prior-bundle anchors.

Reuse-not-reinvent (DD #13): ECE / bimodality / reliability bins / the
``PRIOR_*`` anchors are IMPORTED from ``evaluate_fr18.py``. This module is a thin
renderer + the matplotlib reliability PNG.

This file is INTENTIONALLY excluded from the ``ty`` set (Makefile py-lint) —
matplotlib has no type stubs (torch-exclusion precedent). It is imported lazily
so the JSON-bins path runs in a matplotlib-absent environment (AC4); only the
PNG render requires matplotlib.

Binds to ``fr18ModelBPM`` (DD #9); abstain rows are explicitly excluded
(``not mlAbstained``) AFTER validating the producer invariant — ``compute_ece_
half_double`` itself does NOT read ``mlAbstained`` (Codex/Amelia).
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import evaluate_fr18 as ev

HERE = Path(__file__).resolve().parent
ECE_FLOOR = ev.GATE_D_ECE_FLOOR  # 0.10 (FR-18 gate d)
# PRIOR_ECE_HALF_DOUBLE = 0.5 is a worst-case SENTINEL from the 4-6 investigation
# (evaluate_fr18.py:55), NOT a measured prior with an N — "v2 < 0.5" is a floor
# check against the theoretical-ish max, not a measured improvement (Mary).
PRIOR_ECE_IS_SENTINEL = True


class CalibrationSchemaError(RuntimeError):
    """Raised when a row violates the producer invariant mlAbstained == (bpm is None)."""


def validate_and_filter(rows: list[dict]) -> list[dict]:
    """Validate ``mlAbstained == (fr18ModelBPM is None)`` per row, then drop
    abstains (DD #9). A stale-finite-BPM-with-abstain row would otherwise slip
    into the ECE subset because ``compute_ece_half_double`` ignores mlAbstained."""
    kept: list[dict] = []
    for r in rows:
        abstained = bool(r.get("mlAbstained"))
        has_bpm = r.get("fr18ModelBPM") is not None
        if abstained == has_bpm:
            raise CalibrationSchemaError(
                f"track {r.get('trackId')}: mlAbstained={abstained} but "
                f"fr18ModelBPM is {'present' if has_bpm else 'None'} "
                "(invariant mlAbstained == (fr18ModelBPM is None) violated)"
            )
        if not abstained:
            kept.append(r)
    return kept


def build_calibration_report(rows: list[dict]) -> dict:
    """Pure (no matplotlib). v2 metrics + side-by-side anchors + subset Ns."""
    kept = validate_and_filter(rows)
    softmaxes = [
        r["softmaxMax"]
        for r in kept
        if r.get("softmaxMax") is not None and math.isfinite(r["softmaxMax"])
    ]
    p95 = ev.percentile(softmaxes, 0.95)
    ece = ev.compute_ece_half_double(kept)
    bimod = ev.bimodality_125_175([r["fr18ModelBPM"] for r in kept])

    # inconclusive (N<100) is NOT a pass — it blocks (fail-safe to byow).
    ece_passes = ece["state"] == "pass"
    return {
        "calibrationFloor": ECE_FLOOR,
        "nonAbstainRows": len(kept),
        "softmaxSharpness": {
            "v2_p95": round(p95, 4),
            "prior_p95": ev.PRIOR_SOFTMAX_MAX_P95,
            "note": "confidence SHARPNESS diagnostic, NOT a calibration gate (Mary)",
        },
        "eceHalfDouble": {
            "v2": None if ece["ece"] is None else round(ece["ece"], 4),
            "v2_N": ece["n"],
            "state": ece["state"],
            "prior": ev.PRIOR_ECE_HALF_DOUBLE,
            "prior_is_sentinel": PRIOR_ECE_IS_SENTINEL,
            "passes": ece_passes,
            "bins": ece["bins"],
        },
        "bimodality_125_175": {
            "v2_fraction": round(bimod["fraction"], 4),
            "v2_N": bimod["n"],
            "reappears": bimod["reappears"],
            "test": bimod.get("test"),
            "prior_anchors": list(ev.BIMODAL_ANCHORS),
        },
        # FR-25 gate: calibration PASSES only if ECE passes (inconclusive/fail block).
        "calibrationPasses": ece_passes,
        "blocksOnFailOrInconclusive": not ece_passes,
    }


def render_reliability_png(bins: list[dict], path: Path) -> None:
    """Reliability diagram (lazy matplotlib import — AC4). Raises a named error
    if matplotlib is required but unavailable."""
    try:
        import matplotlib  # noqa: PLC0415

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt  # noqa: PLC0415
    except ImportError as exc:  # pragma: no cover - env-dependent
        raise RuntimeError(
            "matplotlib is required for the reliability PNG (develop-only dep); "
            "the JSON bins were still emitted"
        ) from exc
    confs = [b["meanConf"] for b in bins]
    accs = [b["acc"] for b in bins]
    fig, ax = plt.subplots(figsize=(4, 4))
    ax.plot([0, 1], [0, 1], "--", color="gray", label="perfect")
    ax.plot(confs, accs, "o-", label="v2")
    ax.set_xlabel("mean softmax_max (confidence)")
    ax.set_ylabel("accuracy")
    ax.set_title("Reliability — ECE_half_double subset (v2)")
    ax.legend()
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def write_markdown(report: dict, path: Path, smoke: bool) -> None:
    ece = report["eceHalfDouble"]
    sm = report["softmaxSharpness"]
    bm = report["bimodality_125_175"]
    v2_ece = "inconclusive" if ece["v2"] is None else f"{ece['v2']} (N={ece['v2_N']})"
    prior_ece = f"{ece['prior']}" + (" (sentinel)" if ece["prior_is_sentinel"] else "")
    lines = [
        "# FR-25 calibration verification (Story 7.7)"
        + (" — SMOKE (negative control)" if smoke else ""),
        "",
        f"- calibration floor: ECE_half_double < {report['calibrationFloor']} (FR-18 gate d)",
        f"- outcome: **{'PASS' if report['calibrationPasses'] else 'BLOCK (fail/inconclusive -> byow)'}**",
        "",
        "| metric | v2 | prior anchor |",
        "|---|---|---|",
        f"| softmax_max_p95 (sharpness, not a gate) | {sm['v2_p95']} | {sm['prior_p95']} |",
        f"| ECE_half_double | {v2_ece} | {prior_ece} |",
        f"| 125/175 reappears | {bm['reappears']} (frac {bm['v2_fraction']}, N={bm['v2_N']}) | anchors {bm['prior_anchors']} |",
        "",
        f"Non-abstain rows: {report['nonAbstainRows']}. "
        "`inconclusive` (subset N<100) is NOT a pass — it blocks (fail-safe to byow). "
        "The prior ECE 0.5 is a worst-case sentinel from the 4-6 investigation "
        "(`evaluate_fr18.py`), NOT a measured prior — 'v2 < 0.5' is a floor check.",
    ]
    if smoke:
        lines.append("")
        lines.append(
            "Block label: `negativeControlPriorBundle` (v1/synthetic; real v2 operator-owned)."
        )
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description="FR-25 calibration verification (Story 7.7)")
    ap.add_argument("--runtime-predictions", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, default=HERE)
    ap.add_argument("--smoke", action="store_true", help="label as negative-control")
    ap.add_argument("--no-png", action="store_true", help="skip the matplotlib PNG")
    ns = ap.parse_args()

    by_seed = ev.consume_predictions(ns.runtime_predictions)
    rows = [r for rows in by_seed.values() for r in rows]
    report = build_calibration_report(rows)
    (ns.out_dir / "calibration-verification.json").write_text(
        json.dumps(report, indent=2, allow_nan=False)
    )
    # Reliability bins always emitted (survives a matplotlib-absent env — AC4).
    (ns.out_dir / "calibration-reliability-v2-bins.json").write_text(
        json.dumps(report["eceHalfDouble"]["bins"], indent=2, allow_nan=False)
    )
    if not ns.no_png and report["eceHalfDouble"]["bins"]:
        render_reliability_png(
            report["eceHalfDouble"]["bins"], ns.out_dir / "calibration-reliability-v2.png"
        )
    write_markdown(report, ns.out_dir / "calibration-verification.md", smoke=ns.smoke)
    print(
        f"calibration: ECE state={report['eceHalfDouble']['state']} passes={report['calibrationPasses']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
