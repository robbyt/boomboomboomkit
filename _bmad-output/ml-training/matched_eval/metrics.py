"""The nine metric families of the Story 15.9 evaluation, for one (track, system).

Families, never collapsed into one number:
  1 tempo_level     level class of the system tempo against the reference:
                    same, half, double, two-thirds, three-halves or other, each
                    within LEVEL_TOLERANCE relative to that multiple.
  2 strict_tempo    |system - reference| <= tol BPM for every tol in STRICT_TOLERANCES.
  3 fine_error      system - reference in BPM and in parts per thousand.
  4 grid_phase      signed time from the reference downbeat to the nearest grid beat.
  5 beat_prf        beat precision, recall and F against the annotated beats in the
                    verified span (mir_eval `match_events`, BEAT_WINDOW_S).
  6 downbeat_phase  whether a system downbeat lies within BEAT_WINDOW_S of the
                    reference downbeat.
  7 drift           grid time minus reference time accumulated over the verified span.
  8 failure         failed or abstained, with the reason.
  9 runtime_memory  runtime (s) and peak resident memory above the pre-pass baseline.

Families 4 to 7 need a Story 15.8 hand annotation and report `no-reference`
without one. A system that emits no grid reports `no-data` for them. A
system that abstained or failed reports that status in families 1 to 7 and is
counted in family 8.

A grid is a tempo and an anchor time; its beats are `anchor + k * 60 / tempo` for
every integer k, before and after the anchor.
"""

from __future__ import annotations

import math
from typing import Any

import numpy as np

LEVEL_TOLERANCE = 0.04
LEVEL_CLASSES = (
    ("same", 1.0),
    ("half", 0.5),
    ("double", 2.0),
    ("two-thirds", 2.0 / 3.0),
    ("three-halves", 1.5),
)
STRICT_TOLERANCES = (0.10, 0.05, 0.02)
# Float slack so a difference of exactly a tolerance (128.05 - 128.00) counts as within it.
STRICT_EPSILON = 1e-9
BEAT_WINDOW_S = 0.07
BEATS_PER_BAR = 4

FAMILIES = (
    "tempo_level",
    "strict_tempo",
    "fine_error",
    "grid_phase",
    "beat_prf",
    "downbeat_phase",
    "drift",
    "failure",
    "runtime_memory",
)
GRID_FAMILIES = ("grid_phase", "beat_prf", "downbeat_phase", "drift")

# Row and family statuses.
OK = "ok"
ABSTAINED = "abstained"
FAILED = "failed"
NOT_RUN = "not-run"
REFERENCE = "reference"
NO_REFERENCE = "no-reference"
NO_DATA = "no-data"
NOT_COMPARABLE = "not-comparable"
NOT_APPLICABLE = "not-applicable"
LEVEL_MISMATCH = "level-mismatch"


def strict_key(tol: float) -> str:
    return f"{tol:.2f}"


# ---------------------------------------------------------------------------
# Tempo families
# ---------------------------------------------------------------------------


def tempo_level_class(system_bpm: float, reference_bpm: float) -> str:
    ratio = system_bpm / reference_bpm
    for name, factor in LEVEL_CLASSES:
        if abs(ratio / factor - 1.0) <= LEVEL_TOLERANCE:
            return name
    return "other"


def strict_correct(system_bpm: float, reference_bpm: float, tol: float) -> bool:
    return abs(system_bpm - reference_bpm) <= tol + STRICT_EPSILON


def fine_error(system_bpm: float, reference_bpm: float) -> tuple[float, float]:
    err = system_bpm - reference_bpm
    return err, 1000.0 * err / reference_bpm


# ---------------------------------------------------------------------------
# Grid families
# ---------------------------------------------------------------------------


def grid_beats(tempo_bpm: float, anchor_s: float, start_s: float, end_s: float) -> np.ndarray:
    """Every grid beat in [start_s, end_s]."""
    period = 60.0 / tempo_bpm
    k_lo = math.ceil((start_s - anchor_s) / period)
    k_hi = math.floor((end_s - anchor_s) / period)
    if k_hi < k_lo:
        return np.empty(0)
    return anchor_s + np.arange(k_lo, k_hi + 1) * period


def reference_beats(annotation: dict[str, Any]) -> np.ndarray:
    """Annotated beats in the verified span: four per bar, spaced evenly between
    each pair of consecutive annotated bar lines."""
    lines = sorted((float(t), float(m)) for t, m in annotation["barLines"])
    if len(lines) < 2:
        return np.empty(0)
    beats: list[float] = []
    for (t0, m0), (t1, m1) in zip(lines, lines[1:]):
        count = int(round((m1 - m0) * BEATS_PER_BAR))
        if count <= 0:
            continue
        step = (t1 - t0) / count
        beats.extend(t0 + j * step for j in range(count))
    beats.append(lines[-1][0])
    return np.asarray(beats)


def nearest_beat_error(tempo_bpm: float, anchor_s: float, t: float) -> float:
    """Signed seconds from `t` to the nearest grid beat (positive: grid late)."""
    period = 60.0 / tempo_bpm
    k = round((t - anchor_s) / period)
    return anchor_s + k * period - t


def beat_prf(ref: np.ndarray, est: np.ndarray, window: float = BEAT_WINDOW_S) -> dict[str, float]:
    import mir_eval

    if ref.size == 0 or est.size == 0:
        return {"precision": 0.0, "recall": 0.0, "f_measure": 0.0}
    matched = len(mir_eval.util.match_events(ref, est, window))
    precision = matched / est.size
    recall = matched / ref.size
    f = 0.0 if matched == 0 else 2 * precision * recall / (precision + recall)
    return {"precision": precision, "recall": recall, "f_measure": f}


def span_region(t: float, start: float | None, end: float | None) -> str:
    """Where `t` lies against the system's analysed span (Story 15.10)."""
    if start is None or end is None:
        return "unknown"
    if t < start:
        return "before-analysed-span"
    if t >= end:
        return "after-analysed-span"
    return "inside-analysed-span"


def grid_families(grid: dict[str, Any] | None, annotation: dict[str, Any] | None) -> dict:
    """Families 4 to 7 for one system grid against one hand annotation."""
    if annotation is None:
        return {f: {"status": NO_REFERENCE} for f in GRID_FAMILIES}
    if grid is None or grid.get("tempoBPM") is None or grid.get("anchorSeconds") is None:
        return {f: {"status": NO_DATA} for f in GRID_FAMILIES}
    tempo = float(grid["tempoBPM"])
    anchor = float(grid["anchorSeconds"])
    start = annotation["spanStartSeconds"]
    end = annotation["spanEndSeconds"]
    downbeat = annotation["referenceDownbeatSeconds"]
    span_start = grid.get("analysisSpanStartSeconds")
    span_end = grid.get("analysisSpanEndSeconds")

    phase = nearest_beat_error(tempo, anchor, downbeat)
    out: dict[str, Any] = {
        "grid_phase": {
            "status": OK,
            "phase_error_s": phase,
            "region": span_region(downbeat, span_start, span_end),
        }
    }
    ref = reference_beats(annotation)
    est = grid_beats(tempo, anchor, start - BEAT_WINDOW_S, end + BEAT_WINDOW_S)
    out["beat_prf"] = {"status": OK, **beat_prf(ref, est)}

    db = grid.get("downbeat") or {}
    if db.get("anchorSeconds") is None:
        out["downbeat_phase"] = {"status": NO_DATA, "systemDownbeat": db.get("status")}
    else:
        bar = BEATS_PER_BAR * 60.0 / tempo
        db_anchor = float(db["anchorSeconds"])
        k = round((downbeat - db_anchor) / bar)
        err = db_anchor + k * bar - downbeat
        out["downbeat_phase"] = {
            "status": OK,
            "downbeat_correct": abs(err) <= BEAT_WINDOW_S,
            "downbeat_error_s": err,
        }

    level = tempo_level_class(tempo, annotation["verifiedBPM"])
    if level != "same":
        out["drift"] = {"status": LEVEL_MISMATCH, "gridLevel": level}
    else:
        lines = annotation["barLines"]
        bars = (lines[-1][1] - lines[0][1]) if len(lines) >= 2 else 0.0
        beats = bars * BEATS_PER_BAR
        out["drift"] = {
            "status": OK,
            "drift_s": beats * 60.0 / tempo - (end - start),
            "span_s": end - start,
        }
    return out


# ---------------------------------------------------------------------------
# One (track, system)
# ---------------------------------------------------------------------------


def evaluate(
    system: dict[str, Any],
    reference_bpm: float,
    annotation: dict[str, Any] | None,
    *,
    runtime_comparable: bool,
) -> dict[str, Any]:
    """All nine families for one system record.

    `system` carries `status` (ok / abstained / failed / not-run), `reason`,
    `tempoBPM`, `grid` (or None), and for Swift systems `runtimeSeconds` and
    `peakMemoryAboveBaselineBytes`."""
    status = system["status"]
    fam: dict[str, Any] = {}
    if status == NOT_RUN:
        for f in FAMILIES:
            fam[f] = {"status": NOT_RUN}
        if annotation is None:
            fam.update({f: {"status": NO_REFERENCE} for f in GRID_FAMILIES})
        return fam

    if status == OK and system.get("tempoBPM") is not None:
        bpm = float(system["tempoBPM"])
        fam["tempo_level"] = {"status": OK, "class": tempo_level_class(bpm, reference_bpm)}
        fam["strict_tempo"] = {
            "status": OK,
            **{strict_key(t): strict_correct(bpm, reference_bpm, t) for t in STRICT_TOLERANCES},
        }
        err, ppt = fine_error(bpm, reference_bpm)
        fam["fine_error"] = {"status": OK, "error_bpm": err, "error_ppt": ppt}
        if system.get("gridFamilies") == NO_DATA:
            # A tempo-only system: no grid to score, and without a hand annotation
            # there is nothing to score it against either.
            missing = NO_REFERENCE if annotation is None else NO_DATA
            fam.update({f: {"status": missing} for f in GRID_FAMILIES})
        else:
            fam.update(grid_families(system.get("grid"), annotation))
    else:
        inner = status if status in (ABSTAINED, FAILED) else NO_DATA
        for f in ("tempo_level", "strict_tempo", "fine_error"):
            fam[f] = {"status": inner}
        for f in GRID_FAMILIES:
            fam[f] = {"status": NO_REFERENCE if annotation is None else inner}

    fam["failure"] = {
        "status": OK,
        "failed_or_abstained": status in (ABSTAINED, FAILED),
        "outcome": status,
        "reason": system.get("reason"),
    }
    if not runtime_comparable:
        fam["runtime_memory"] = {"status": system.get("runtimeStatus", NOT_COMPARABLE)}
    else:
        fam["runtime_memory"] = {
            "status": OK,
            "runtime_s": float(system["runtimeSeconds"]),
            "peak_memory_bytes": int(system["peakMemoryAboveBaselineBytes"]),
        }
    return fam


def reference_families(annotation: dict[str, Any] | None) -> dict[str, Any]:
    """The reference scored against itself: the zero point of every vs-reference
    pairing. Grid families exist only where a hand annotation does."""
    fam: dict[str, Any] = {
        "tempo_level": {"status": OK, "class": "same"},
        "strict_tempo": {"status": OK, **{strict_key(t): True for t in STRICT_TOLERANCES}},
        "fine_error": {"status": OK, "error_bpm": 0.0, "error_ppt": 0.0},
        "failure": {"status": NOT_APPLICABLE},
        "runtime_memory": {"status": NOT_APPLICABLE},
    }
    if annotation is None:
        fam.update({f: {"status": NO_REFERENCE} for f in GRID_FAMILIES})
    else:
        fam.update(
            {
                "grid_phase": {"status": OK, "phase_error_s": 0.0, "region": "reference"},
                "beat_prf": {"status": OK, "precision": 1.0, "recall": 1.0, "f_measure": 1.0},
                "downbeat_phase": {"status": OK, "downbeat_correct": True, "downbeat_error_s": 0.0},
                "drift": {"status": OK, "drift_s": 0.0, "span_s": None},
            }
        )
    return fam


# ---------------------------------------------------------------------------
# Per-metric values for pairing
# ---------------------------------------------------------------------------


def _ok(fam: dict[str, Any], name: str) -> dict[str, Any] | None:
    f = fam.get(name, {})
    return f if f.get("status") == OK else None


def _flag(v: Any) -> float | None:
    return None if v is None else (1.0 if v else 0.0)


def _metric_tempo_level(fam):
    f = _ok(fam, "tempo_level")
    return None if f is None else (1.0 if f["class"] == "same" else 0.0)


def _metric_strict(tol):
    def get(fam):
        f = _ok(fam, "strict_tempo")
        return None if f is None else _flag(f[strict_key(tol)])

    return get


def _metric_field(family: str, field: str, absolute: bool = False):
    def get(fam):
        f = _ok(fam, family)
        if f is None or f.get(field) is None:
            return None
        v = float(f[field])
        return abs(v) if absolute else v

    return get


def _metric_bool(family: str, field: str):
    def get(fam):
        f = _ok(fam, family)
        return None if f is None else _flag(f.get(field))

    return get


# (family, metric, extractor). Every pairing is computed for every metric that
# has values on both sides; a track missing either side is left out of that one.
METRICS: tuple[tuple[str, str, Any], ...] = (
    ("tempo_level", "level_same", _metric_tempo_level),
    *(("strict_tempo", f"strict_{strict_key(t)}", _metric_strict(t)) for t in STRICT_TOLERANCES),
    ("fine_error", "error_bpm", _metric_field("fine_error", "error_bpm")),
    ("fine_error", "abs_error_bpm", _metric_field("fine_error", "error_bpm", absolute=True)),
    ("fine_error", "error_ppt", _metric_field("fine_error", "error_ppt")),
    ("fine_error", "abs_error_ppt", _metric_field("fine_error", "error_ppt", absolute=True)),
    ("grid_phase", "phase_error_s", _metric_field("grid_phase", "phase_error_s")),
    (
        "grid_phase",
        "abs_phase_error_s",
        _metric_field("grid_phase", "phase_error_s", absolute=True),
    ),
    ("beat_prf", "precision", _metric_field("beat_prf", "precision")),
    ("beat_prf", "recall", _metric_field("beat_prf", "recall")),
    ("beat_prf", "f_measure", _metric_field("beat_prf", "f_measure")),
    ("downbeat_phase", "downbeat_correct", _metric_bool("downbeat_phase", "downbeat_correct")),
    ("drift", "drift_s", _metric_field("drift", "drift_s")),
    ("drift", "abs_drift_s", _metric_field("drift", "drift_s", absolute=True)),
    ("failure", "failed_or_abstained", _metric_bool("failure", "failed_or_abstained")),
    ("runtime_memory", "runtime_s", _metric_field("runtime_memory", "runtime_s")),
    (
        "runtime_memory",
        "peak_memory_bytes",
        _metric_field("runtime_memory", "peak_memory_bytes"),
    ),
)
