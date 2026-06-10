"""Post-bundle regression watchlist v2 (Story 7.7 AC8 / Task 6).

Develop-only. Annotates each of the 241 Story-7.4 ``marginal-watchlist.json``
tracks with the FINAL selected model's actual ``fr18ModelBPM`` prediction +
whether it matched ``expectedFailureMode`` / ``verificationPredicate`` (reuse
7.6's closed-enum ``watchlist_matches_expected`` — DD #13). 7.4 fills the
v2Prediction stub schema; 7.5 fills ``seeds[]``; 7.6 fills ``matchesExpected``;
this is the FINAL-model annotation against the bundled/BYOW selection.

7-4-D1 watch-only: a row whose v2 prediction fails in a way an ID3 tag would
have predicted is flagged as a reopen SIGNAL — ID3 reading is NOT wired here
(FR-15 boundary). Binds to ``fr18ModelBPM`` (DD #9).
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from pathlib import Path

import evaluate_fr18 as ev

HERE = Path(__file__).resolve().parent


def _median_model_bpm(track_id: str, by_seed: dict[int, list[dict]]) -> float | None:
    """Median FINITE fr18ModelBPM for a watchlist track across seeds (None if all abstain).

    Filters non-finite (defensive — the producer already sanitizes NaN/Inf to
    None, but a malformed dump must not poison the median or the JSON, code-review).
    """
    vals: list[float] = []
    for rows in by_seed.values():
        for r in rows:
            if str(r.get("trackId")) == track_id and r.get("corpus") == "marginal":
                bpm = r.get("fr18ModelBPM")
                if bpm is not None and math.isfinite(float(bpm)):
                    vals.append(float(bpm))
    if not vals:
        return None
    return statistics.median(vals)


def _load_expected_failure_modes() -> dict[str, str]:
    """track_id -> expectedFailureMode from the RAW marginal-watchlist.json.

    ``evaluate_fr18._load_watchlist`` strips ``expectedFailureMode`` (it only
    carries the predicate-evaluation fields), so read the raw file for the
    annotation column (code-review — otherwise the column is always null)."""
    path = HERE / "marginal-watchlist.json"
    if not path.exists():
        return {}
    raw = json.loads(path.read_text())
    rows = (
        raw["watchlist"]
        if isinstance(raw, dict) and isinstance(raw.get("watchlist"), list)
        else raw
    )
    return {
        str(r["track_id"]): r.get("expectedFailureMode")
        for r in rows
        if r.get("expectedFailureMode")
    }


def annotate(
    watchlist: dict[str, dict],
    by_seed: dict[int, list[dict]],
    expected_modes: dict[str, str] | None = None,
) -> dict:
    """Per-track final-model annotation + matchesExpected + 7-4-D1 reopen flags."""
    expected_modes = expected_modes or {}
    rows_out: list[dict] = []
    reopen_signals = 0
    for track_id, wl in watchlist.items():
        model_bpm = _median_model_bpm(str(track_id), by_seed)
        predicate = wl.get("verificationPredicate", "none")
        expected_mode = expected_modes.get(str(track_id)) or wl.get("expectedFailureMode")
        matches = ev.watchlist_matches_expected(
            predicate,
            model_bpm,
            float(wl["tonyLabel"]) if wl.get("tonyLabel") is not None else 0.0,
            wl.get("dspBPM"),
            wl.get("rekordboxBPM"),
            wl.get("gridBPM"),
        )
        # 7-4-D1 reopen signal: a `model_corrects_metadata` predicate left
        # UNDECIDABLE (matches is None) because no rekordbox/grid tag was
        # present — an ID3 tag (unwired, FR-15 boundary) would have supplied it.
        reopen = bool(
            predicate == "model_corrects_metadata"
            and matches is None
            and wl.get("rekordboxBPM") is None
            and wl.get("gridBPM") is None
        )
        if reopen:
            reopen_signals += 1
        rows_out.append(
            {
                "track_id": str(track_id),
                "expectedFailureMode": expected_mode,
                "verificationPredicate": predicate,
                "v2ModelBPM": model_bpm,
                "matchesExpected": matches,
                "reopen74D1Signal": reopen,
            }
        )
    return {
        "_story": "7.7 post-bundle regression watchlist v2",
        "_note": "final-model annotation; 7-4-D1 reopen signals flagged, ID3 NOT wired (FR-15)",
        "trackCount": len(rows_out),
        "reopen74D1SignalCount": reopen_signals,
        "watchlist": rows_out,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Post-bundle regression watchlist v2 (Story 7.7)")
    ap.add_argument("--runtime-predictions", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=HERE / "post-bundle-regression-watchlist-v2.json")
    ns = ap.parse_args()

    watchlist = ev._load_watchlist()
    if not watchlist:
        raise FileNotFoundError("marginal-watchlist.json not found / empty (Story 7.4 output)")
    by_seed = ev.consume_predictions(ns.runtime_predictions)
    # Fail closed (Codex): an empty/wrong prediction root would annotate every
    # track v2ModelBPM=None and "succeed" with worthless evidence.
    if not any(r.get("corpus") == "marginal" for rows in by_seed.values() for r in rows):
        raise RuntimeError(
            f"no marginal-corpus predictions under {ns.runtime_predictions} "
            "(cannot annotate the post-bundle watchlist; fail closed)"
        )
    report = annotate(watchlist, by_seed, expected_modes=_load_expected_failure_modes())
    ns.out.write_text(json.dumps(report, indent=2, allow_nan=False))
    print(
        f"post-bundle-watchlist: {report['trackCount']} tracks, "
        f"{report['reopen74D1SignalCount']} 7-4-D1 reopen signal(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
