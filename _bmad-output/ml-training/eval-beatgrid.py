#!/usr/bin/env python3
"""Beat-grid F-measure sidecar for the Story-8.7 acceptance benchmark (develop-only).

Reads the JAMS reference oracle (Rekordbox-derived, `scripts/rekordbox-beats.py`)
and the Swift-emitted estimated JAMS, joins by `identifiers.track_id`, and computes
`mir_eval.beat.f_measure` (+-70 ms) per track. Emits per-track + aggregate means to
the `--out` JSON, which the Swift floor test (`BeatGridFloorTests`) then gates on.

Two F-measures per track (story DD-15):
  - raw:    f_measure(ref, est) at the grids as detected.
  - octave: the tempo-octave-tolerant max over {est, est/2 (both phases), est*2}.
            ~77% of the corpus is Rekordbox-tagged at half-time (80 BPM ~= 160 DnB)
            while the tracker tracks the full tempo, so the raw number is dominated
            by a 2x density mismatch. The octave-normalized number is the DJ-sync
            relevant one (consistent with the BPM Acc2 octave tolerance and
            TempoAgreement.octaveEquivalent); it is the gated metric.

Orchestration: invoked by `make benchmark-beatgrid` as a second step AFTER the
Swift emit pass (DD-12 — never Process-invoked from inside the Swift test).

Usage:
  uv run python eval-beatgrid.py --reference <oracle.jams.json> \
      --estimated <estimated.jams.json> --out <accuracy.json>
"""

from __future__ import annotations

import argparse
import json
import sys

import mir_eval
import numpy as np

TOLERANCE_S = 0.07  # +-70 ms (mir_eval f_measure_threshold)


def load_corpus(path: str) -> dict[str, dict]:
    """Map track_id -> {basename, constant_tempo, beats(sorted np.ndarray)} from JAMS."""
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
            beats = [obs["time"] for obs in ann.get("data", []) if obs.get("time") is not None]
            break
        out[track_id] = {
            "basename": ids.get("basename", ""),
            "constant_tempo": bool(meta.get("constant_tempo", True)),
            "beats": np.array(sorted(beats), dtype=float),
        }
    return out


def _downsample(beats: np.ndarray, phase: int) -> np.ndarray:
    """Every-other beat starting at `phase` (0 or 1) — the half-tempo grid."""
    if beats.size == 0:
        return beats
    return beats[phase::2]


def _upsample(beats: np.ndarray) -> np.ndarray:
    """Insert midpoints between consecutive beats — the double-tempo grid."""
    if beats.size < 2:
        return beats
    mids = (beats[:-1] + beats[1:]) / 2.0
    return np.sort(np.concatenate([beats, mids]))


def f_measure_octave(ref: np.ndarray, est: np.ndarray) -> tuple[float, float]:
    """Return (raw_f, octave_tolerant_f).

    `mir_eval.beat.trim_beats` drops the first 5 s (standard); we let mir_eval do
    its own trimming inside f_measure. The octave-tolerant score is the max over the
    estimate's tempo octaves so a correct-but-half/double grid is not penalized.
    """
    if ref.size == 0 or est.size == 0:
        return 0.0, 0.0
    raw = mir_eval.beat.f_measure(ref, est, f_measure_threshold=TOLERANCE_S)
    candidates = [
        raw,
        mir_eval.beat.f_measure(ref, _downsample(est, 0), f_measure_threshold=TOLERANCE_S),
        mir_eval.beat.f_measure(ref, _downsample(est, 1), f_measure_threshold=TOLERANCE_S),
        mir_eval.beat.f_measure(ref, _upsample(est), f_measure_threshold=TOLERANCE_S),
    ]
    return float(raw), float(max(candidates))


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--reference", required=True, help="JAMS oracle (rekordbox-beats.jams.json)")
    p.add_argument("--estimated", required=True, help="Swift-emitted estimated JAMS")
    p.add_argument("--out", required=True, help="Output accuracy JSON")
    args = p.parse_args(argv if argv is not None else sys.argv[1:])

    ref = load_corpus(args.reference)
    est = load_corpus(args.estimated)

    # Coverage-parity (DD-10): every estimated track must map to an oracle row.
    missing_ref = sorted(set(est) - set(ref))
    if missing_ref:
        print(
            f"error: {len(missing_ref)} estimated track_id(s) have no oracle row "
            f"(coverage-parity, DD-10): {missing_ref[:10]}",
            file=sys.stderr,
        )
        return 1

    # Reverse coverage (Codex review): oracle constant-tempo rows missing from the
    # estimated artifact. This is NOT hard-failed — a track's audio can be legitimately
    # unavailable at benchmark time (the Swift coverage-parity assertion, which knows the
    # analyzable denominator, is the real gate and halts `make benchmark-beatgrid` before
    # this sidecar runs). But a TRUNCATED estimated file would silently score only the
    # survivors and inflate the mean, so surface the gap loudly + record the counts.
    ref_constant = {tid for tid, r in ref.items() if r["constant_tempo"]}
    missing_constant = sorted(ref_constant - set(est))
    if missing_constant:
        frac = len(set(est) & ref_constant) / max(1, len(ref_constant))
        print(
            f"warning: {len(missing_constant)} of {len(ref_constant)} constant-tempo oracle "
            f"rows are absent from the estimated artifact (est covers {frac:.1%}); "
            f"verify this is unavailable-audio, not a truncated estimated JAMS.",
            file=sys.stderr,
        )

    per_track = []
    octs_constant: list[float] = []  # gated subset (constant-tempo, DD-19)
    octs_all: list[float] = []
    raws_all: list[float] = []
    for track_id, est_rec in sorted(est.items()):
        ref_rec = ref[track_id]
        raw_f, oct_f = f_measure_octave(ref_rec["beats"], est_rec["beats"])
        raws_all.append(raw_f)
        octs_all.append(oct_f)
        if ref_rec["constant_tempo"]:
            octs_constant.append(oct_f)
        per_track.append(
            {
                "track_id": track_id,
                "basename": est_rec["basename"],
                "constant_tempo": ref_rec["constant_tempo"],
                "n_ref_beats": int(ref_rec["beats"].size),
                "n_est_beats": int(est_rec["beats"].size),
                "f_measure_raw": round(raw_f, 4),
                "f_measure_octave": round(oct_f, 4),
            }
        )

    def mean(xs: list[float]) -> float:
        return round(float(np.mean(xs)), 4) if xs else 0.0

    result = {
        "n_tracks": len(per_track),
        "n_tracks_constant": len(octs_constant),
        # Reverse-coverage visibility (Codex review): the oracle's constant-tempo
        # denominator and how many of those rows the estimated artifact actually covered.
        "n_ref_constant": len(ref_constant),
        "n_missing_constant": len(missing_constant),
        "tolerance_ms": int(TOLERANCE_S * 1000),
        "gated_metric": "mean_f_measure_octave_constant",
        # The GATED metric: octave-normalized mean over the constant-tempo subset (the
        # tracker's documented domain — DD-19).
        "mean_f_measure_octave_constant": mean(octs_constant),
        # Reported (diagnostic): full-corpus octave + raw means.
        "mean_f_measure_octave_all": mean(octs_all),
        "mean_f_measure_raw_all": mean(raws_all),
        "per_track": per_track,
    }
    with open(args.out, "w") as fh:
        json.dump(result, fh, indent=2)
        fh.write("\n")

    print(
        f"beat-grid F-measure over {result['n_tracks']} tracks "
        f"({result['n_tracks_constant']} constant-tempo): "
        f"GATED octave-normalized constant mean={result['mean_f_measure_octave_constant']:.4f}; "
        f"reported all-octave={result['mean_f_measure_octave_all']:.4f}, "
        f"all-raw={result['mean_f_measure_raw_all']:.4f} "
        f"(+-{result['tolerance_ms']} ms) -> {args.out}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
