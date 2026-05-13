#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Derive ground-truth BPM labels for the Tony tunes corpus from 5 noisy signals.

Implements the weighted-cluster-ensemble + disagreement-auditor approach
(Codex consultation thread 019e1f52-6baf-7ce1-a045-f7be658a7c53).

Five signals per track:
  1. Rekordbox `AverageBpm`             (Tony's saved DJ value — often half-time)
  2. `<TEMPO Bpm>` grid entries          (manually-anchored beat markers)
  3. Inter-`Inizio` spacing on grid      (independent BPM measurement)
  4. Playlist namesake prior             ("160 Grumble" -> ~165)
  5. BoomBoomBoomKit DSP                 (our library's own estimate)

Core idea: no single signal is truth. Every BPM observation is expanded into
octave-normalized variants {b/2, b, b*2} clipped to [60, 200], weighted by
source reliability and a half-time-suspect boost (raw < 100 -> factor=2.0 gets
+35%). Variants are clustered within ±2.5% bands; the winner is the cluster
with highest total weight. Output reports each source's relation to the winner
(`same | half | double | near | far`).

Inputs:
  --survey-json    output of scripts/tony-tunes-survey.py (XML + on-disk resolution)
  --dsp-json       output of tony-dsp-prepass Swift CLI (per-track DSP BPM)

Output: JSON with bpm_truth + per-signal disagreement per track, plus a
summary on stderr.

Usage:
  uv run scripts/tony-tunes-labels.py \
      --survey-json /tmp/tony-survey.json \
      --dsp-json    /tmp/tony-dsp-prepass.json \
      --output      /Users/.../tony-truth-labels.json
"""

import argparse
import collections
import json
import math
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Tuning constants
# ---------------------------------------------------------------------------

CANONICAL_MIN = 60.0
CANONICAL_MAX = 200.0
# Cluster radius: 4% balances precision against playlist-prior alignment.
# Tighter (2.5%) leaves "145 BPM track in 150 Fumble" with Rek/Grid in one
# cluster and the playlist prior in a separate one — playlist support fails to
# accrue. 4% pulls 130-vs-134, 140-vs-143, 145-vs-150 together while keeping
# half/double pairs cleanly separated (80 vs 160 = 100% apart). Larger (>=6%)
# starts merging tempos that should stay distinct (145 vs 155).
CLUSTER_PCT = 0.04

# Source weights (Codex Strategy 4 starting values).
WEIGHTS = {
    "grid_bpm": 3.0,         # explicit <TEMPO Bpm>
    "grid_spacing": 3.5,     # inter-Inizio derived
    "playlist_prior": 2.0,   # base playlist weight (multiplied by Gaussian closeness)
    "rekordbox_average": 1.5,
    "audio_metadata": 0.8,   # ID3 TBPM / MP4 tmpo (not yet wired)
    # DSP weight is dynamic: 1.0 + 3.0 * confidence (see add_dsp_signal).
}

# Multiplier applied to factor=2.0 variants when raw BPM < 100 — encodes the
# DnB half-time prior without hard-coding "always double".
HALF_TIME_BOOST = 1.35

# Multiplier applied to embedded-metadata signal when it equals AverageBpm —
# downweight as likely Rekordbox copy-back, not an independent signal.
METADATA_COPYBACK_PENALTY = 0.35

# Relation thresholds for the disagreement auditor.
SAME_PCT = 0.02
NEAR_PCT = 0.05

# Abstention thresholds.
MIN_TRUTH_CONFIDENCE = 0.55
MIN_RUNNER_UP_GAP = 0.20  # winner / total >= MIN_TRUTH_CONFIDENCE AND runner_up / winner < (1 - this)

# Playlist priors: (center_bpm, sigma_bpm). Sigma is roughly the half-width of
# the tempo band the playlist name implies; Gaussian decay scales the
# contribution. Playlists not listed here contribute no prior (e.g. "Ambient?",
# "Normie Town", "SMNL 1" — stylistic, not tempo-named).
PLAYLIST_PRIORS = {
    "130 Rumble": (130.0, 6.0),
    "140 Bzns": (140.0, 6.0),
    "150 Fumble": (150.0, 6.0),
    "160 Grumble": (165.0, 10.0),
    "160 Bouncey Bzns": (165.0, 10.0),
    # "Amen" = amen-break / jungle / breakcore. Tempos typically 160-180,
    # sometimes 140-170. Wide sigma.
    "Amen": (170.0, 15.0),
}


# ---------------------------------------------------------------------------
# Cluster bookkeeping
# ---------------------------------------------------------------------------


class TempoClusters:
    """Greedy clustering of octave-normalized tempo candidates.

    Candidates within `CLUSTER_PCT` of an existing cluster centroid join that
    cluster (weighted-average centroid update). Otherwise a new cluster is
    created. Order-sensitive but deterministic given consistent input order.
    """

    def __init__(self) -> None:
        # list of dicts: {centroid, total_weight, members: [signal_record, ...]}
        self.clusters: list[dict] = []

    def add(
        self,
        bpm: float,
        weight: float,
        source: str,
        raw_bpm: float,
        factor: float,
        detail: dict,
    ) -> None:
        if weight <= 0 or not _finite(bpm) or not _finite(weight):
            return
        member = {
            "source": source,
            "raw_bpm": raw_bpm,
            "factor": factor,
            "canonical_bpm": bpm,
            "weight": weight,
            "detail": detail,
        }
        for cluster in self.clusters:
            if _near_pct(bpm, cluster["centroid"], CLUSTER_PCT):
                total = cluster["total_weight"] + weight
                # Weighted-average centroid update.
                cluster["centroid"] = (
                    cluster["centroid"] * cluster["total_weight"] + bpm * weight
                ) / total
                cluster["total_weight"] = total
                cluster["members"].append(member)
                return
        self.clusters.append(
            {"centroid": bpm, "total_weight": weight, "members": [member]}
        )

    def winner_and_runner_up(self) -> tuple[dict | None, dict | None, float]:
        if not self.clusters:
            return None, None, 0.0
        sorted_clusters = sorted(
            self.clusters, key=lambda c: c["total_weight"], reverse=True
        )
        total = sum(c["total_weight"] for c in self.clusters)
        winner = sorted_clusters[0]
        runner_up = sorted_clusters[1] if len(sorted_clusters) > 1 else None
        return winner, runner_up, total


# ---------------------------------------------------------------------------
# Signal expansion
# ---------------------------------------------------------------------------


def octave_variants(bpm: float | None) -> list[tuple[float, float]]:
    """Return [(canonical_bpm, factor)] for canonical-band variants.

    Asymmetric expansion:
      * factor=1.0 always (the raw value, if in band)
      * factor=2.0 ONLY when raw < 100 (the half-time-suspect band — Tony saved
        DnB at 80 means the music is likely 160)
      * factor=0.5 ONLY when raw > 200 (out-of-canonical, double-time-suspect —
        rare, mostly defensive against weird Rekordbox values)

    Earlier draft generated all three variants unconditionally, which caused
    raw=150 to split mass equally across {75, 150}, ties the clusters, and
    forced abstention on the (very common!) case where every signal agrees
    on a straight-time tempo in [100, 200].
    """
    if bpm is None or not _finite(bpm) or bpm <= 0:
        return []
    out: list[tuple[float, float]] = []
    if CANONICAL_MIN <= bpm <= CANONICAL_MAX:
        out.append((bpm, 1.0))
    if bpm < 100.0:
        doubled = bpm * 2.0
        if CANONICAL_MIN <= doubled <= CANONICAL_MAX:
            out.append((doubled, 2.0))
    if bpm > 200.0:
        halved = bpm / 2.0
        if CANONICAL_MIN <= halved <= CANONICAL_MAX:
            out.append((halved, 0.5))
    return out


def add_bpm_signal(
    clusters: TempoClusters,
    source: str,
    raw_bpm: float | None,
    base_weight: float,
    detail: dict,
) -> None:
    """Expand a raw BPM into canonical variants and add weighted candidates."""
    if raw_bpm is None or raw_bpm <= 0:
        return
    for canon_bpm, factor in octave_variants(raw_bpm):
        weight = base_weight
        # Half-time prior: if Tony saved at <100, the doubled variant is the
        # likely truth for dance music. Boost factor=2.0 candidates.
        if raw_bpm < 100.0 and factor == 2.0:
            weight *= HALF_TIME_BOOST
        clusters.add(
            bpm=canon_bpm,
            weight=weight,
            source=source,
            raw_bpm=raw_bpm,
            factor=factor,
            detail={**detail, "octave_factor": factor},
        )


def add_playlist_priors(clusters: TempoClusters, playlists: list[str]) -> list[dict]:
    """Add one candidate per tempo-named playlist at its prior center.

    Returns the list of priors actually contributed (for the disagreement
    report). Playlists with no prior in PLAYLIST_PRIORS contribute nothing.

    Earlier draft discretized the Gaussian across many 1-BPM bins; that
    massively inflated total weight and collapsed winner-fraction confidence.
    Single-point prior + cluster radius (CLUSTER_PCT) provides the "close
    enough" matching semantics without polluting the denominator.
    """
    contributed: list[dict] = []
    for name in playlists:
        if name not in PLAYLIST_PRIORS:
            continue
        center, sigma = PLAYLIST_PRIORS[name]
        clusters.add(
            bpm=center,
            weight=WEIGHTS["playlist_prior"],
            source="playlist_prior",
            raw_bpm=center,
            factor=1.0,
            detail={"playlist": name, "center": center, "sigma": sigma},
        )
        contributed.append({"name": name, "center": center, "sigma": sigma})
    return contributed


def add_dsp_signal(
    clusters: TempoClusters,
    dsp_bpm: float | None,
    dsp_confidence: float | None,
    candidates: list[dict],
) -> None:
    """DSP weight scales with confidence. Top candidates also expand."""
    if dsp_bpm is None:
        return
    conf = dsp_confidence if dsp_confidence is not None else 0.5
    base_weight = 1.0 + 3.0 * max(0.0, min(1.0, conf))
    add_bpm_signal(
        clusters, "dsp", dsp_bpm, base_weight, {"confidence": conf, "rank": "winner"}
    )
    # Also add DSP's lower-ranked candidates at reduced weight — they hint at
    # the octave alternative the DSP saw but didn't pick.
    for i, c in enumerate(candidates[:3], start=1):
        if i == 1:
            continue  # already added as the winner
        add_bpm_signal(
            clusters,
            "dsp",
            c.get("bpm"),
            base_weight * 0.35,
            {"confidence": conf, "rank": f"candidate_{i}", "score": c.get("score")},
        )


def add_grid_signals(clusters: TempoClusters, tempo_count: int, first_tempo_bpm: float | None) -> None:
    """Add the explicit grid BPM (single-marker tracks only have first_tempo_bpm)."""
    # NOTE: inter-Inizio spacing requires multiple TEMPO entries with timestamps,
    # which the current survey JSON does not emit (only first_tempo_bpm).
    # When tony-tunes-survey.py is extended to dump full grid arrays, this
    # function should also compute median inter-marker spacing and add a
    # `grid_spacing` signal at WEIGHTS["grid_spacing"]. For now, single-grid
    # tracks contribute only via grid_bpm at WEIGHTS["grid_bpm"].
    if first_tempo_bpm is None or first_tempo_bpm <= 0:
        return
    weight = WEIGHTS["grid_bpm"]
    # Multi-grid tracks have a manually-adjusted beatgrid — trust them more.
    if tempo_count and tempo_count > 1:
        weight *= 1.5
    add_bpm_signal(
        clusters,
        "grid_bpm",
        first_tempo_bpm,
        weight,
        {"tempo_count": tempo_count or 1, "multi_grid": (tempo_count or 0) > 1},
    )


# ---------------------------------------------------------------------------
# Disagreement auditor (Strategy 6)
# ---------------------------------------------------------------------------


def relation(source_bpm: float | None, truth: float) -> str:
    """Classify how a single source bpm relates to the chosen truth."""
    if source_bpm is None or source_bpm <= 0 or truth <= 0:
        return "missing"
    if _near_pct(source_bpm, truth, SAME_PCT):
        return "same"
    if _near_pct(source_bpm * 2, truth, SAME_PCT):
        return "half"
    if _near_pct(source_bpm / 2, truth, SAME_PCT):
        return "double"
    canonical_source = _canonicalize(source_bpm)
    if _near_pct(canonical_source, truth, NEAR_PCT):
        return "near"
    return "far"


def build_disagreement_report(
    track: dict,
    dsp: dict | None,
    truth: float | None,
    contributed_playlists: list[dict],
) -> dict:
    report: dict = {}
    rek = track.get("average_bpm")
    grid = track.get("first_tempo_bpm")

    if truth is None:
        # No truth -> emit raw values without relation field.
        report["rekordbox_average"] = {"bpm": rek}
        report["grid_bpm"] = {"bpm": grid, "tempo_count": track.get("tempo_count")}
        if dsp:
            report["dsp"] = {"bpm": dsp.get("bpm"), "confidence": dsp.get("confidence")}
        report["playlist"] = {
            "names": track.get("playlists") or [],
            "priors_used": contributed_playlists,
        }
        return report

    report["rekordbox_average"] = {
        "bpm": rek,
        "relation": relation(rek, truth),
    }
    report["grid_bpm"] = {
        "bpm": grid,
        "tempo_count": track.get("tempo_count"),
        "relation": relation(grid, truth),
    }
    if dsp:
        report["dsp"] = {
            "bpm": dsp.get("bpm"),
            "confidence": dsp.get("confidence"),
            "relation": relation(dsp.get("bpm"), truth),
        }
    report["playlist"] = {
        "names": track.get("playlists") or [],
        "priors_used": contributed_playlists,
        # `relation` for playlists is nearest-prior-center vs truth.
        "relation": (
            relation(min(contributed_playlists, key=lambda p: abs(p["center"] - truth))["center"], truth)
            if contributed_playlists
            else "missing"
        ),
    }
    return report


# ---------------------------------------------------------------------------
# Per-track label
# ---------------------------------------------------------------------------


def label_one(track: dict, dsp: dict | None) -> dict:
    clusters = TempoClusters()

    # 1. Rekordbox AverageBpm
    add_bpm_signal(
        clusters,
        "rekordbox_average",
        track.get("average_bpm"),
        WEIGHTS["rekordbox_average"],
        {"raw": track.get("average_bpm")},
    )

    # 2-3. Grid BPM (explicit) — grid_spacing not wired yet (see add_grid_signals)
    add_grid_signals(clusters, track.get("tempo_count"), track.get("first_tempo_bpm"))

    # 4. Playlist priors
    contributed = add_playlist_priors(clusters, track.get("playlists") or [])

    # 5. DSP signal (only if available)
    if dsp:
        add_dsp_signal(
            clusters,
            dsp.get("bpm"),
            dsp.get("confidence"),
            dsp.get("candidates") or [],
        )

    winner, runner_up, total = clusters.winner_and_runner_up()
    qa_flags: list[str] = []
    truth: float | None = None
    truth_confidence = 0.0

    if winner is None or total <= 0:
        qa_flags.append("no_signals")
    else:
        # Confidence is "how much does winner beat runner-up", not "winner /
        # all clusters". For DnB the half-time and double-time clusters split
        # signal mass roughly evenly; a fraction-of-total metric mis-fires.
        # winner_weight / (winner_weight + runner_up_weight) maps:
        #   0.50 = tie, 0.55 = winner 22% bigger than runner-up (truth assigned),
        #   0.65 = winner ~86% bigger, 1.00 = no runner-up
        if runner_up is not None:
            truth_confidence = winner["total_weight"] / (
                winner["total_weight"] + runner_up["total_weight"]
            )
        else:
            truth_confidence = 1.0
        runner_ratio = (runner_up["total_weight"] / winner["total_weight"]) if runner_up else 0.0
        if truth_confidence < MIN_TRUTH_CONFIDENCE:
            qa_flags.append("low_confidence")
        if runner_ratio > (1.0 - MIN_RUNNER_UP_GAP):
            qa_flags.append("ambiguous_cluster")
        non_playlist_sources = {
            m["source"]
            for m in winner["members"]
            if m["source"] != "playlist_prior"
        }
        if len(non_playlist_sources) < 2:
            qa_flags.append("single_source_truth")
        if "low_confidence" not in qa_flags:
            truth = round(winner["centroid"], 3)

    signals = build_disagreement_report(track, dsp, truth, contributed)

    return {
        "track_id": track.get("track_id"),
        "artist": track.get("artist"),
        "name": track.get("name"),
        "album": track.get("album"),
        "local_path": track.get("local_path"),
        "bpm_truth": truth,
        "truth_confidence": round(truth_confidence, 3),
        "truth_cluster": _cluster_to_json(winner),
        "runner_up_cluster": _cluster_to_json(runner_up) if runner_up else None,
        "signals": signals,
        "qa_flags": qa_flags,
    }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _finite(x: float) -> bool:
    return x == x and x not in (float("inf"), float("-inf"))


def _near_pct(a: float, b: float, pct: float) -> bool:
    if b == 0 or not _finite(a) or not _finite(b):
        return False
    return abs(a - b) / b <= pct


def _canonicalize(bpm: float) -> float:
    """Bring bpm into [CANONICAL_MIN, CANONICAL_MAX] by repeated halving/doubling.

    Heuristic: <60 -> double, >200 -> halve. Used only for relation classification.
    """
    if bpm <= 0:
        return bpm
    out = bpm
    for _ in range(4):
        if out < CANONICAL_MIN:
            out *= 2
        elif out > CANONICAL_MAX:
            out /= 2
        else:
            break
    return out


def _cluster_to_json(cluster: dict | None) -> dict | None:
    if cluster is None:
        return None
    return {
        "centroid": round(cluster["centroid"], 3),
        "total_weight": round(cluster["total_weight"], 3),
        "member_count": len(cluster["members"]),
        "sources": sorted({m["source"] for m in cluster["members"]}),
    }


# ---------------------------------------------------------------------------
# IO
# ---------------------------------------------------------------------------


def load_dsp_index(path: Path | None) -> dict[str, dict]:
    """Return {track_id: dsp_record}; empty if path is None."""
    if path is None:
        return {}
    with open(path) as fh:
        doc = json.load(fh)
    return {t["track_id"]: t for t in doc.get("tracks", [])}


def load_survey(path: Path) -> list[dict]:
    with open(path) as fh:
        doc = json.load(fh)
    return doc.get("tracks", [])


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------


def emit_summary(labels: list[dict], out=sys.stderr) -> None:
    n = len(labels)
    truth_set = [lbl for lbl in labels if lbl["bpm_truth"] is not None]
    abstained = n - len(truth_set)
    flag_h = collections.Counter(
        f for lbl in labels for f in lbl["qa_flags"]
    )
    rel_h = collections.Counter(
        lbl["signals"].get("rekordbox_average", {}).get("relation", "missing")
        for lbl in labels
        if lbl["bpm_truth"] is not None
    )
    bpm_h = collections.Counter(
        f"{int((lbl['bpm_truth'] or 0) // 10) * 10}-{int((lbl['bpm_truth'] or 0) // 10) * 10 + 9}"
        for lbl in truth_set
    )

    print(f"# Tony tunes labels — {n} tracks", file=out)
    print(f"  bpm_truth assigned: {len(truth_set)}", file=out)
    print(f"  abstained:          {abstained}", file=out)
    print("\nQA flags (multi-count: a track can have several flags):", file=out)
    for f, c in flag_h.most_common():
        print(f"  {c:>5}  {f}", file=out)
    print("\nRekordbox AverageBpm relation to bpm_truth (truth-assigned tracks only):", file=out)
    for r, c in rel_h.most_common():
        print(f"  {c:>5}  {r}", file=out)
    print("\nbpm_truth 10-BPM histogram:", file=out)
    for k in sorted(bpm_h.keys(), key=lambda s: int(s.split("-", 1)[0])):
        print(f"  {bpm_h[k]:>5}  {k}", file=out)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Derive bpm_truth labels from 5 noisy signals via weighted-cluster "
            "ensemble + disagreement auditor."
        )
    )
    parser.add_argument("--survey-json", required=True, help="output of tony-tunes-survey.py")
    parser.add_argument(
        "--dsp-json",
        required=False,
        help="output of tony-dsp-prepass Swift CLI (optional; "
        "labeler runs DSP-free if absent)",
    )
    parser.add_argument("--output", required=True, help="path to write tony-truth-labels.json")
    parser.add_argument(
        "--include-unresolved",
        action="store_true",
        help="By default we only label tracks where resolve_status == 'ok'. "
        "Use this flag to label every XML track regardless of on-disk presence.",
    )
    args = parser.parse_args()

    survey_path = Path(args.survey_json)
    dsp_path = Path(args.dsp_json) if args.dsp_json else None
    out_path = Path(args.output)

    if not survey_path.exists():
        print(f"error: --survey-json not found: {survey_path}", file=sys.stderr)
        return 2

    tracks = load_survey(survey_path)
    if not args.include_unresolved:
        tracks = [t for t in tracks if t.get("resolve_status") == "ok"]
    print(f"# loaded {len(tracks)} tracks from {survey_path}", file=sys.stderr)

    dsp_index = load_dsp_index(dsp_path)
    if dsp_path:
        print(
            f"# loaded {len(dsp_index)} DSP records from {dsp_path}",
            file=sys.stderr,
        )

    labels = []
    for t in tracks:
        dsp = dsp_index.get(t.get("track_id"))
        labels.append(label_one(t, dsp))

    # Stable sort for diff-friendly output.
    labels.sort(key=lambda lbl: ((lbl["artist"] or ""), (lbl["album"] or ""), (lbl["name"] or "")))

    emit_summary(labels)

    output_doc = {
        "schema_version": 1,
        "weights": WEIGHTS,
        "tuning": {
            "canonical_min": CANONICAL_MIN,
            "canonical_max": CANONICAL_MAX,
            "cluster_pct": CLUSTER_PCT,
            "half_time_boost": HALF_TIME_BOOST,
            "metadata_copyback_penalty": METADATA_COPYBACK_PENALTY,
            "min_truth_confidence": MIN_TRUTH_CONFIDENCE,
            "min_runner_up_gap": MIN_RUNNER_UP_GAP,
        },
        "playlist_priors": {k: {"center": v[0], "sigma": v[1]} for k, v in PLAYLIST_PRIORS.items()},
        "sources": {
            "survey_json": str(survey_path),
            "dsp_json": str(dsp_path) if dsp_path else None,
        },
        "track_count": len(labels),
        "tracks": labels,
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as fh:
        json.dump(output_doc, fh, indent=2)
    print(f"# wrote {len(labels)} labels to {out_path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
