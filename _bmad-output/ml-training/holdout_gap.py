"""GiantSteps holdout-gap evaluator (Story 7.7 AC6 / Task 2).

Develop-only. Reads Story-7.6's existing ``seed_*/`` per-track GiantSteps
prediction dumps (it does NOT re-run 7.6 — DD #6), joins on ``trackId``, removes
the sealed n=150 holdout (``giantsteps-holdout-v2.json``) to compute
``Acc1_iterated`` (over 661 - 150 = 511) vs ``Acc1_holdout`` (over 150), and the
gap in PERCENTAGE-POINTS with per-subset Wilson lower bounds.

Honest framing (Mary / DD #6): this is a within-corpus stability check, NOT a
sealed-pre-iteration leak detector — the 150 tracks were inside the same 661
corpus 7.6 tuned against, so a small gap is necessary-but-not-sufficient. At
n=150 the difference-SE is ~4.2pp, so ``gap >= 8pp`` (~1.9 sigma) is an
INFORMATIONAL review tripwire, not a significance test (do NOT downgrade to pass
— AC11). NOT comparable to 7.6 gate-(c)'s 537/661 counts.

Binds to ``fr18ModelBPM`` (DD #9). Uses the LEAF counters ``count_acc1`` /
``count_acc1_octave`` directly — NOT ``aggregate_seeds`` (whose
``EXPECTED_GIANTSTEPS = 661`` guard would reject the 511 split — DD #6 / Winston).
"""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

import evaluate_fr18 as ev

HERE = Path(__file__).resolve().parent
GAP_TRIPWIRE_PP = 8.0  # >= this (percentage-points) blocks Story 7.7 close (AC6/AC11)
EXPECTED_HOLDOUT = 150  # sealed holdout size; 661-150 = 511 iterated (DD #6)


class HoldoutGapError(RuntimeError):
    """Raised when 7.6 dumps are absent or a holdout track is missing from them."""


def partition(gs_rows: list[dict], holdout_ids: set[str]) -> tuple[list[dict], list[dict]]:
    """Split GS rows into (iterated, holdout) by trackId membership.

    Fails closed (DD #6): every holdout id MUST be present in the dumps — a
    missing id would silently make ``iterated`` the full 661, defeating the gap.
    """
    by_id = {str(r["trackId"]): r for r in gs_rows}
    # Duplicate-anywhere guard (Codex): a duplicate trackId (holdout OR iterated)
    # biases its subset's denominator — reject before partitioning.
    if len(by_id) != len(gs_rows):
        raise HoldoutGapError(
            f"duplicate trackId in the GS dumps ({len(gs_rows)} rows, {len(by_id)} unique)"
        )
    missing = [h for h in holdout_ids if h not in by_id]
    if missing:
        raise HoldoutGapError(
            f"{len(missing)} holdout track(s) absent from the GS dumps "
            f"(cannot compute over 511; first missing: {missing[0]})"
        )
    iterated = [r for r in gs_rows if str(r["trackId"]) not in holdout_ids]
    holdout = [r for r in gs_rows if str(r["trackId"]) in holdout_ids]
    return iterated, holdout


def _acc1_pct(rows: list[dict]) -> float:
    return 100.0 * ev.count_acc1(rows) / len(rows) if rows else 0.0


def compute_gap(iterated: list[dict], holdout: list[dict]) -> dict:
    """Per-subset Acc1 (count + pct + Wilson LB) + the signed gap in pp.

    gap = Acc1_iterated_pct - Acc1_holdout_pct (positive => holdout WORSE =>
    iteration-leak concern). ``blocks`` fires at gap >= GAP_TRIPWIRE_PP.
    """
    it_k, ho_k = ev.count_acc1(iterated), ev.count_acc1(holdout)
    it_n, ho_n = len(iterated), len(holdout)
    it_pct, ho_pct = _acc1_pct(iterated), _acc1_pct(holdout)
    gap = it_pct - ho_pct
    return {
        "iterated": {
            "acc1": it_k,
            "acc1Octave": ev.count_acc1_octave(iterated),
            "n": it_n,
            "pct": round(it_pct, 2),
            "wilsonLB": round(ev.wilson_lower_bound(it_k, it_n), 4),
        },
        "holdout": {
            "acc1": ho_k,
            "acc1Octave": ev.count_acc1_octave(holdout),
            "n": ho_n,
            "pct": round(ho_pct, 2),
            "wilsonLB": round(ev.wilson_lower_bound(ho_k, ho_n), 4),
        },
        "gapPP": round(gap, 2),
        "blocks": gap >= GAP_TRIPWIRE_PP,
        "tripwirePP": GAP_TRIPWIRE_PP,
        "note": "informational ~1.9sigma tripwire at n=150 (DD #6), not a significance test",
    }


def _load_holdout_ids(jams_path: Path) -> set[str]:
    if not jams_path.exists():
        raise HoldoutGapError(
            f"holdout file not found at {jams_path} (run sample-giantsteps-holdout.py)"
        )
    jams = json.loads(jams_path.read_text())
    ids = {str(a["file_metadata"]["identifiers"]["track_id"]) for a in jams.get("annotations", [])}
    if not ids:
        raise HoldoutGapError(f"no track ids in {jams_path}")
    # The holdout is sealed at exactly n=150; a truncated/altered file must fail
    # closed rather than silently shrink the holdout subset (Codex).
    if len(ids) != EXPECTED_HOLDOUT:
        raise HoldoutGapError(
            f"holdout file has {len(ids)} ids, expected sealed n={EXPECTED_HOLDOUT}"
        )
    return ids


def evaluate(pred_root: Path, holdout_ids: set[str]) -> dict:
    """Per-seed gap over the GS subset of each ``seed_*/`` dump + median."""
    by_seed = ev.consume_predictions(pred_root)
    if not by_seed:
        raise HoldoutGapError(f"no seed_*/ prediction dumps under {pred_root}")
    per_seed: dict[int, dict] = {}
    for seed, rows in sorted(by_seed.items()):
        gs = [r for r in rows if r.get("corpus") == "giantsteps"]
        if not gs:
            raise HoldoutGapError(f"seed {seed}: no GiantSteps rows in dump")
        iterated, holdout = partition(gs, holdout_ids)
        per_seed[seed] = compute_gap(iterated, holdout)
    gaps = [s["gapPP"] for s in per_seed.values()]
    median_gap = statistics.median(gaps)
    return {
        "perSeed": per_seed,
        "medianGapPP": round(median_gap, 2),
        "minGapPP": round(min(gaps), 2),
        "maxGapPP": round(max(gaps), 2),
        "blocks": any(s["blocks"] for s in per_seed.values()),
        "tripwirePP": GAP_TRIPWIRE_PP,
    }


def write_markdown(report: dict, path: Path) -> None:
    lines = [
        "# GiantSteps holdout-gap (Story 7.7 AC6)",
        "",
        f"- median gap: **{report['medianGapPP']} pp** (min {report['minGapPP']} / max {report['maxGapPP']})",
        f"- tripwire: gap >= {report['tripwirePP']} pp blocks close ("
        "informational ~1.9sigma at n=150, NOT a significance test — DD #6)",
        f"- outcome: **{'BLOCK — review iteration-leak' if report['blocks'] else 'close normally'}**",
        "",
        "| seed | iterated Acc1 | holdout Acc1 | gap (pp) | blocks |",
        "|---|---|---|---|---|",
    ]
    for seed, s in sorted(report["perSeed"].items()):
        it, ho = s["iterated"], s["holdout"]
        lines.append(
            f"| {seed} | {it['acc1']}/{it['n']} ({it['pct']}%) | "
            f"{ho['acc1']}/{ho['n']} ({ho['pct']}%) | {s['gapPP']} | {s['blocks']} |"
        )
    lines.append("")
    lines.append(
        "Within-corpus stability check, NOT a sealed-pre-iteration leak detector "
        "(the 150 were inside the same 661 corpus 7.6 tuned against). A small gap "
        "is necessary-but-not-sufficient evidence against iteration-leak."
    )
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description="GiantSteps holdout-gap evaluator (Story 7.7)")
    ap.add_argument("--runtime-predictions", type=Path, required=True)
    ap.add_argument("--holdout", type=Path, default=HERE / "giantsteps-holdout-v2.json")
    ap.add_argument("--out-dir", type=Path, default=HERE)
    ns = ap.parse_args()

    holdout_ids = _load_holdout_ids(ns.holdout)
    report = evaluate(ns.runtime_predictions, holdout_ids)
    (ns.out_dir / "giantsteps-holdout-gap.json").write_text(
        json.dumps(report, indent=2, allow_nan=False)
    )
    write_markdown(report, ns.out_dir / "giantsteps-holdout-gap.md")
    print(
        f"holdout-gap: median {report['medianGapPP']}pp -> "
        f"{'BLOCK' if report['blocks'] else 'close'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
