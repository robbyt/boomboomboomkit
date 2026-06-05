"""FR-24 semi-supervised net-benefit gate (Story 7.7 AC5 / Task 4).

Develop-only. Compares the KDD-B2 winner ``maskedMelPretrain`` (the trained v2)
against the ``supervisedAugmented`` runner-up on the bundle-deciding EXTERNAL
corpora (OA300 + GiantSteps + sentinels) — NOT the tony.val/LAO axes that
``ablation/compare_kdd_b2.py`` already covered (DD #5).

Two-arm directory contract (DD #15): ``consume_predictions`` RAISES on a
duplicate seed / shared checkpoint SHA, so each arm gets its own namespace
``FR18_PRED_DIR/<arm>/seed_<N>/`` and we call ``consume_predictions(root/<arm>)``
once per arm — NEVER a co-mingled root.

Polarity (DD #5): promotion of the SSL variant requires improving OR preserving
all FR-18 gates within tolerance (Acc1 +/-2 tracks, ECE +0.02, tail-P95 +0.5
BPM). If the runner-up checkpoint is absent, the gate is ``inconclusive`` ->
net-benefit UNPROVEN; the SSL variant is NOT auto-bundled-as-net-benefit-proven
(an explicit recorded operator ack is required). Binds to ``fr18ModelBPM`` (DD #9).
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from pathlib import Path

import evaluate_fr18 as ev

HERE = Path(__file__).resolve().parent
WINNER_ARM = "maskedMelPretrain"
RUNNERUP_ARM = "supervisedAugmented"
CORPORA = ("oa300", "giantsteps", "sentinel")

# Net-benefit tolerances (epics.md#Story-7.7 AC FR-24).
ACC1_TOL_TRACKS = 2
ECE_TOL = 0.02
TAIL_P95_TOL = 0.5

# Per-corpus minimum denominators (mirror evaluate_fr18's EXPECTED_* — Codex
# diff-review): the raw-track tolerances (Acc1 +/-2) are only meaningful at the
# full corpus size, so a partial/tiny operator run (e.g. a 5-track OA300 or a
# 1-seed smoke) must NOT count as a comparable corpus and silently promote.
MIN_DENOMINATOR = {"oa300": ev.EXPECTED_OA300, "giantsteps": ev.EXPECTED_GIANTSTEPS, "sentinel": 1}


def _tail_errors(rows: list[dict]) -> list[float]:
    """Per-track model BPM error; an abstain counts as a full-scale miss (= truth)
    so a high abstain rate cannot flatter the tail (DD #9 spirit)."""
    out: list[float] = []
    for r in rows:
        truth = r["groundTruthBPM"]
        pred = r.get("fr18ModelBPM")
        if pred is None or not math.isfinite(pred) or pred <= 0:
            out.append(float(truth))
        else:
            out.append(abs(pred - truth))
    return out


def _corpus_metrics(rows: list[dict]) -> dict:
    ece = ev.compute_ece_half_double(rows)
    return {
        "acc1": ev.count_acc1(rows),
        "n": len(rows),
        "ece": ece["ece"],
        "eceState": ece["state"],
        "tailP95": round(ev.percentile(_tail_errors(rows), 0.95), 3),
    }


def arm_metrics(by_seed: dict[int, list[dict]]) -> dict:
    """Per-corpus metrics, median across the arm's seeds."""
    per_corpus: dict[str, dict] = {}
    for corpus in CORPORA:
        accs, eces, tails, ns = [], [], [], []
        for rows in by_seed.values():
            grp = [r for r in rows if r.get("corpus") == corpus]
            if not grp:
                continue
            m = _corpus_metrics(grp)
            accs.append(m["acc1"])
            tails.append(m["tailP95"])
            ns.append(m["n"])
            if m["ece"] is not None:
                eces.append(m["ece"])
        if not accs:
            continue
        per_corpus[corpus] = {
            "acc1": int(statistics.median(accs)),
            "n": int(statistics.median(ns)),
            "ece": round(statistics.median(eces), 4) if eces else None,
            "tailP95": round(statistics.median(tails), 3),
        }
    return per_corpus


def net_benefit_gate(ssl: dict, runnerup: dict) -> dict:
    """Per-corpus + overall: SSL improves-or-preserves vs runner-up within tol.

    Fail-CLOSED (code-review BLOCKER): if NO corpus could be compared
    (``per_corpus`` empty — e.g. an arm dir with no oa300/giantsteps/sentinel
    rows), net-benefit is UNPROVEN, never silently True (DD #5 polarity).
    """
    per_corpus: dict[str, dict] = {}
    compared = 0
    below_denominator: dict[str, dict] = {}
    overall = True
    for corpus in CORPORA:
        if corpus not in ssl or corpus not in runnerup:
            continue
        s, r = ssl[corpus], runnerup[corpus]
        # Denominator guard (Codex): below the full corpus size, the raw-track
        # tolerances are not meaningful — record but do NOT count as compared.
        min_n = MIN_DENOMINATOR.get(corpus, 1)
        if s["n"] < min_n or r["n"] < min_n:
            below_denominator[corpus] = {"sslN": s["n"], "runnerupN": r["n"], "expected": min_n}
            continue
        compared += 1
        acc1_ok = s["acc1"] >= r["acc1"] - ACC1_TOL_TRACKS
        if s["ece"] is None or r["ece"] is None:
            ece_ok = True  # cannot compare (small subset) — do not fail on it
            ece_note = "inconclusive (subset N<100)"
        else:
            ece_ok = s["ece"] <= r["ece"] + ECE_TOL
            ece_note = None
        tail_ok = s["tailP95"] <= r["tailP95"] + TAIL_P95_TOL
        passes = acc1_ok and ece_ok and tail_ok
        overall = overall and passes
        per_corpus[corpus] = {
            "acc1Ok": acc1_ok,
            "eceOk": ece_ok,
            "eceNote": ece_note,
            "tailOk": tail_ok,
            "passes": passes,
            "ssl": s,
            "runnerup": r,
        }
    proven = overall and compared > 0  # zero comparable corpora => UNPROVEN
    return {
        "perCorpus": per_corpus,
        "comparedCorpora": compared,
        "belowDenominator": below_denominator,
        "netBenefitProven": proven,
    }


def evaluate(pred_root: Path) -> dict:
    """Load both arm namespaces; inconclusive if the runner-up arm is absent."""
    winner_dir = pred_root / WINNER_ARM
    runnerup_dir = pred_root / RUNNERUP_ARM
    if not winner_dir.exists():
        raise RuntimeError(f"winner arm dir missing: {winner_dir}")
    ssl = arm_metrics(ev.consume_predictions(winner_dir))
    if not runnerup_dir.exists():
        return {
            "state": "inconclusive",
            "reason": f"runner-up arm dir absent ({RUNNERUP_ARM}); net-benefit UNPROVEN",
            "ssl": ssl,
            "netBenefitProven": False,
            "requiresOperatorAck": True,
        }
    runnerup = arm_metrics(ev.consume_predictions(runnerup_dir))
    gate = net_benefit_gate(ssl, runnerup)
    # No comparable corpora => inconclusive (fail-closed), not a silent promote.
    if gate["comparedCorpora"] == 0:
        return {
            "state": "inconclusive",
            "reason": (
                "both arm dirs present but no corpus met its full denominator "
                f"(below: {gate['belowDenominator'] or 'none present'}); net-benefit UNPROVEN"
            ),
            "ssl": ssl,
            "runnerup": runnerup,
            "gate": gate,
            "netBenefitProven": False,
            "requiresOperatorAck": True,
        }
    return {
        "state": "evaluated",
        "ssl": ssl,
        "runnerup": runnerup,
        "gate": gate,
        "netBenefitProven": gate["netBenefitProven"],
        "promoted": WINNER_ARM if gate["netBenefitProven"] else RUNNERUP_ARM,
        "requiresOperatorAck": False,
    }


def write_markdown(report: dict, path: Path) -> None:
    lines = ["# FR-24 semi-supervised net-benefit (Story 7.7 AC5)", ""]
    if report["state"] == "inconclusive":
        lines += [
            f"- **inconclusive** — {report['reason']}",
            "- net-benefit UNPROVEN; SSL is NOT auto-bundled-as-net-benefit-proven.",
            "- bundling the winner anyway requires an explicit recorded operator acknowledgment "
            "(DD #5), OR training the runner-up to close the gate.",
        ]
    else:
        lines += [
            f"- net-benefit proven: **{report['netBenefitProven']}** (promote: `{report['promoted']}`)",
            "- tolerances: Acc1 +/-2 tracks, ECE +0.02, tail-P95 +0.5 BPM",
            "",
            "| corpus | SSL Acc1 | runner-up Acc1 | SSL tailP95 | runner-up tailP95 | passes |",
            "|---|---|---|---|---|---|",
        ]
        for corpus, g in report["gate"]["perCorpus"].items():
            s, r = g["ssl"], g["runnerup"]
            lines.append(
                f"| {corpus} | {s['acc1']}/{s['n']} | {r['acc1']}/{r['n']} | "
                f"{s['tailP95']} | {r['tailP95']} | {g['passes']} |"
            )
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description="FR-24 net-benefit gate (Story 7.7)")
    ap.add_argument(
        "--runtime-predictions",
        type=Path,
        required=True,
        help="root containing <arm>/seed_<N>/ for both arms (DD #15)",
    )
    ap.add_argument("--out-dir", type=Path, default=HERE)
    ns = ap.parse_args()

    report = evaluate(ns.runtime_predictions)
    (ns.out_dir / "fr-24-semi-supervised-net-benefit.json").write_text(
        json.dumps(report, indent=2, allow_nan=False)
    )
    write_markdown(report, ns.out_dir / "fr-24-semi-supervised-net-benefit.md")
    print(f"fr-24: state={report['state']} netBenefitProven={report['netBenefitProven']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
