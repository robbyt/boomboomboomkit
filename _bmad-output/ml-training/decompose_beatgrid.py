#!/usr/bin/env python3
"""Story 8-9 decomposition + oracle line-fit audit spike (develop-only).

Re-aggregates the existing Story-8.7 per-track output to (a) AUDIT the Rekordbox
oracle itself — fit each oracle's beats to a single constant-tempo line and report
the residual, so tracks whose oracle is piecewise / hand-warped / coarsely
quantized can be separated from genuinely-constant-tempo tracks (AC #7), and (b)
DECOMPOSE the F-measure failures by bucket (AC #8): an F histogram, the
raw-vs-octave F gap, the correlation between low F and a warped oracle, and an
isolation of the worst tracks with shared-trait tabulation.

This names which failure bucket (tempo-drift / anchor-phase / octave-half-time /
mis-specified-oracle) the Story-8.9 refit can actually reach BEFORE any "we fixed
drift" claim. It gates the CLAIM, not the code — running it needs the Story-8.7
artifacts + the (develop-only) Rekordbox oracle, so it is operator-run.

Why the oracle's own line-fit residual is the drift floor: the Story-8.9 grid is a
single constant-tempo line by construction, and the FR-29 metric compares it to
the oracle. If the ORACLE deviates from a constant-tempo line by more than the
+-70 ms match tolerance, no constant-tempo grid can match it within tolerance —
the measured "drift" is the audio's own tempo variation, not a code defect. The
drift gate (AC #6) therefore applies only to oracle-validated constant-tempo
tracks; this audit quantifies how many of the 910 `constant_tempo`-flagged tracks
actually pass that line test.

Usage:
  uv run python decompose_beatgrid.py \
      --accuracy ../implementation-artifacts/8-7-beat-grid-accuracy.json \
      --reference tony-corpus/rekordbox-beats.jams.json \
      --out ../implementation-artifacts/8-9-decomposition.md
"""

from __future__ import annotations

import argparse
import json

import numpy as np

TOLERANCE_S = 0.07  # +-70 ms, the F-measure match window the oracle must clear.


def fit_constant_line(beats: np.ndarray) -> tuple[float, float, float]:
    """Fit ``t ~= phase + m*period`` with ordinals from the median IBI.

    Returns ``(period, residual_rms, residual_p95)`` in seconds, or ``(0, inf,
    inf)`` for a degenerate (< 3-beat) input. The ordinal ``m_i = round((t_i -
    t_0)/median_ibi)`` mirrors the Swift refit, so a dropped/doubled oracle beat
    shifts one ordinal rather than bending the slope.
    """
    if beats.size < 3:
        return 0.0, float("inf"), float("inf")
    t = np.sort(beats.astype(float))
    ibis = np.diff(t)
    med = float(np.median(ibis))
    if med <= 0:
        return 0.0, float("inf"), float("inf")
    m = np.round((t - t[0]) / med)
    if m.max() - m.min() < 2:
        return 0.0, float("inf"), float("inf")
    # Unweighted LS (the oracle has no per-beat confidence): slope = cov/var.
    mbar = m.mean()
    tbar = t.mean()
    denom = float(((m - mbar) ** 2).sum())
    if denom <= 0:
        return 0.0, float("inf"), float("inf")
    slope = float(((m - mbar) * (t - tbar)).sum() / denom)
    intercept = tbar - slope * mbar
    resid = np.abs(t - (intercept + slope * m))
    rms = float(np.sqrt((resid**2).mean()))
    p95 = float(np.percentile(resid, 95))
    return slope, rms, p95


def load_oracle(path: str) -> dict[str, dict]:
    """Map track_id -> {beats, constant_tempo, duration} from the oracle JAMS."""
    with open(path) as fh:
        doc = json.load(fh)
    out: dict[str, dict] = {}
    for entry in doc.get("entries", []):
        meta = entry.get("file_metadata", {})
        ids = meta.get("identifiers", {}) or {}
        track_id = ids.get("track_id")
        if not track_id:
            continue
        beats: list[float] = []
        for ann in entry.get("annotations", []):
            if ann.get("namespace") != "beat":
                continue
            beats = [o["time"] for o in ann.get("data", []) if o.get("time") is not None]
            break
        sandbox = entry.get("sandbox", {}) or {}
        ct = sandbox.get("constant_tempo", meta.get("constant_tempo"))
        out[track_id] = {
            "beats": np.asarray(beats, dtype=float),
            "constant_tempo": True if ct is None else bool(ct),
            "duration": meta.get("duration"),
        }
    return out


def corr_or_nan(a: np.ndarray, b: np.ndarray) -> float:
    """Pearson correlation, or ``nan`` if either input has zero variance.

    ``np.corrcoef`` returns ``nan`` + a RuntimeWarning on a constant vector
    (identical F-measures, clipped oracle P95s, or durations); guard so a
    degenerate re-run reports an honest ``nan`` rather than a noisy warning.
    """
    return float(np.corrcoef(a, b)[0, 1]) if a.std() > 0 and b.std() > 0 else float("nan")


def histogram(values: list[float], edges: list[float]) -> list[tuple[str, int]]:
    """Bucket ``values`` into ``[edges[i], edges[i+1])`` ranges with labels."""
    out: list[tuple[str, int]] = []
    arr = np.asarray(values, dtype=float)
    for i in range(len(edges) - 1):
        lo, hi = edges[i], edges[i + 1]
        n = int(((arr >= lo) & (arr < hi)).sum())
        out.append((f"[{lo:g}, {hi:g})", n))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Story 8-9 decomposition + oracle audit")
    ap.add_argument("--accuracy", required=True, help="8-7-beat-grid-accuracy.json")
    ap.add_argument("--reference", required=True, help="Rekordbox oracle JAMS")
    ap.add_argument("--out", required=True, help="output Markdown report")
    args = ap.parse_args()

    with open(args.accuracy) as fh:
        acc = json.load(fh)
    per_track = {row["track_id"]: row for row in acc.get("per_track", [])}
    oracle = load_oracle(args.reference)

    rows = []
    for track_id, ora in oracle.items():
        acc_row = per_track.get(track_id)
        if acc_row is None:
            continue
        _, rms, p95 = fit_constant_line(ora["beats"])
        rows.append(
            {
                "track_id": track_id,
                "basename": acc_row.get("basename") or track_id,
                "constant_tempo": ora["constant_tempo"],
                "duration": ora["duration"] or 0.0,
                "n_ref_beats": acc_row.get("n_ref_beats", 0),
                "f_raw": acc_row.get("f_measure_raw", 0.0),
                "f_octave": acc_row.get("f_measure_octave", 0.0),
                "oracle_rms": rms,
                "oracle_p95": p95,
            }
        )

    if not rows:
        print("error: no tracks joined between --accuracy and --reference; check the paths.")
        return 1

    constant = [r for r in rows if r["constant_tempo"]]
    # Oracle-validated constant: flagged constant AND its own line-fit P95 clears the
    # +-70 ms match window (a constant-tempo grid can in principle match it).
    validated = [r for r in constant if r["oracle_p95"] <= TOLERANCE_S]
    warped = [r for r in constant if r["oracle_p95"] > TOLERANCE_S]

    lines: list[str] = []
    lines.append("# Story 8-9 — beat-grid decomposition + oracle line-fit audit\n")
    lines.append(
        f"Tracks joined (oracle ∩ accuracy): **{len(rows)}** "
        f"(constant-flagged **{len(constant)}**).\n"
    )

    lines.append("## Oracle line-fit audit (AC #7)\n")
    lines.append(
        "Each oracle's beats fit to a single constant-tempo line; the residual P95 is the "
        "irreducible drift floor a constant-tempo grid faces against that oracle.\n"
    )
    lines.append(
        f"- Oracle-validated constant-tempo (P95 ≤ {int(TOLERANCE_S * 1000)} ms): "
        f"**{len(validated)} / {len(constant)}** "
        f"({100 * len(validated) / max(1, len(constant)):.1f}%).\n"
    )
    lines.append(
        f"- Warped / piecewise / coarse (P95 > {int(TOLERANCE_S * 1000)} ms): "
        f"**{len(warped)}** — these inflate measured drift and are mis-specified for the "
        f"constant-tempo drift gate.\n"
    )
    if constant:
        p95s = [r["oracle_p95"] * 1000 for r in constant if np.isfinite(r["oracle_p95"])]
        if p95s:
            lines.append(
                f"- Oracle residual P95 over constant-flagged (ms): "
                f"median {np.median(p95s):.1f}, P90 {np.percentile(p95s, 90):.1f}, "
                f"P95 {np.percentile(p95s, 95):.1f}, max {np.max(p95s):.1f}.\n"
            )
        else:
            lines.append("- Oracle residual P95 over constant-flagged: (no finite residuals).\n")
        lines.append("\n  Oracle residual-P95 histogram (ms):\n")
        for label, n in histogram(p95s, [0, 10, 25, 50, 70, 100, 250, 1000, 1e9]):
            lines.append(f"  - {label}: {n}")
        lines.append("")

    lines.append("## F-measure decomposition (AC #8)\n")
    f_oct_all = [r["f_octave"] for r in rows]
    f_oct_val = [r["f_octave"] for r in validated]
    lines.append(
        f"- Mean octave F: all **{np.mean(f_oct_all):.3f}**, "
        f"oracle-validated-constant **{np.mean(f_oct_val) if f_oct_val else 0:.3f}** "
        f"(the subset the drift gate actually applies to).\n"
    )
    gaps = [r["f_octave"] - r["f_raw"] for r in rows]
    lines.append(
        f"- Octave normalization lift (F_octave − F_raw): mean **{np.mean(gaps):.3f}**, "
        f"median **{np.median(gaps):.3f}** — the half/double-time density mismatch the "
        f"octave-tolerant score recovers (NOT a phase/drift problem the refit reaches).\n"
    )
    lines.append("\n  Octave-F histogram (all tracks):\n")
    for label, n in histogram(f_oct_all, [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9, 1.0001]):
        lines.append(f"  - {label}: {n}")
    lines.append("")

    # Correlation: does low F track a warped oracle (mis-spec) vs. a real grid error?
    if len(rows) >= 3:
        fo = np.asarray([r["f_octave"] for r in rows])
        orr = np.asarray([min(r["oracle_p95"], 5.0) for r in rows])  # clip inf for corr
        dur = np.asarray([r["duration"] for r in rows])
        c_fr = corr_or_nan(fo, orr)
        c_or = corr_or_nan(orr, dur)
        lines.append(
            f"- corr(octave-F, oracle-residual-P95) = **{c_fr:+.3f}** "
            f"(negative ⇒ low F is driven by a warped oracle, not a fixable grid error).\n"
        )
        lines.append(
            f"- corr(oracle-residual-P95, duration) = **{c_or:+.3f}** "
            f"(positive ⇒ longer tracks drift more in the oracle itself).\n"
        )

    lines.append(
        "## Worst 50 tracks by octave-F (shared-trait isolation, AC #8) — "
        "aggregate over 50, lowest-F 25 listed\n"
    )
    worst = sorted(rows, key=lambda r: r["f_octave"])[:50]
    n_warped = sum(1 for r in worst if r["oracle_p95"] > TOLERANCE_S)
    n_variable = sum(1 for r in worst if not r["constant_tempo"])
    lines.append(
        f"- of the 50 worst: **{n_warped}** have a warped oracle (P95 > "
        f"{int(TOLERANCE_S * 1000)} ms), **{n_variable}** are flagged variable-tempo — "
        f"i.e. {n_warped + n_variable} of 50 worst are oracle/material issues, not grid drift.\n"
    )
    lines.append("\n  | basename | octave-F | const | n_ref | oracle-P95 ms |")
    lines.append("  |---|---|---|---|---|")
    for r in worst[:25]:
        lines.append(
            f"  | {r['basename'][:40]} | {r['f_octave']:.3f} | "
            f"{'Y' if r['constant_tempo'] else 'N'} | {r['n_ref_beats']} | "
            f"{min(r['oracle_p95'], 9.999) * 1000:.0f} |"
        )
    lines.append("")

    report = "\n".join(lines) + "\n"
    with open(args.out, "w") as fh:
        fh.write(report)
    print(report)
    print(f"=== wrote decomposition report -> {args.out} ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
