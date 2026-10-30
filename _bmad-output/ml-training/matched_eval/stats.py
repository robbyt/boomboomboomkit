"""Paired statistics and strata for the Story 15.9 evaluation.

For one pairing (A, B) and one metric, the paired signed differences are
`value(A) - value(B)` over the tracks where both have a value. The summary holds
n, the median and mean difference, a bootstrap 95 % interval of the median
(BOOTSTRAP_RESAMPLES resamples of the tracks with replacement, percentile
interval, seeded from BOOTSTRAP_SEED and the summary's key so the result does
not depend on the order summaries are computed in), the two-sided paired
Wilcoxon signed-rank p-value (scipy, zero differences dropped), and whether the
interval excludes zero. A summary with n < UNDERPOWERED_BELOW is underpowered.
"""

from __future__ import annotations

import math
import warnings
import zlib
from typing import Any

import numpy as np

BOOTSTRAP_RESAMPLES = 10_000
BOOTSTRAP_SEED = 20_261_030
INTERVAL_PERCENTILES = (2.5, 97.5)
UNDERPOWERED_BELOW = 10
_CHUNK = 1_000

TEMPO_BANDS = (
    ("60-89", 60.0, 90.0),
    ("90-109", 90.0, 110.0),
    ("110-129", 110.0, 130.0),
    ("130-149", 130.0, 150.0),
    ("150-179", 150.0, 180.0),
    ("180-210", 180.0, 210.0),
)
OUTSIDE_BANDS = "outside-60-210"


def tempo_band(reference_bpm: float) -> str:
    """The band holding the reference BPM; 210 itself belongs to the top band."""
    for name, lo, hi in TEMPO_BANDS:
        if lo <= reference_bpm < hi:
            return name
    if reference_bpm == TEMPO_BANDS[-1][2]:
        return TEMPO_BANDS[-1][0]
    return OUTSIDE_BANDS


def strata_of(reference_bpm: float, style: str) -> list[str]:
    return ["overall", f"band:{tempo_band(reference_bpm)}", f"style:{style}"]


def _rng(key: str) -> np.random.Generator:
    return np.random.default_rng([BOOTSTRAP_SEED, zlib.crc32(key.encode("utf-8"))])


def bootstrap_median_interval(diffs: np.ndarray, key: str) -> tuple[float, float]:
    """Percentile 95 % interval of the median of `diffs` (paired resampling of tracks)."""
    n = diffs.size
    if n == 0:
        raise ValueError("no differences")
    if np.all(diffs == diffs[0]):
        v = float(diffs[0])
        return v, v
    rng = _rng(key)
    medians = np.empty(BOOTSTRAP_RESAMPLES)
    for start in range(0, BOOTSTRAP_RESAMPLES, _CHUNK):
        stop = min(start + _CHUNK, BOOTSTRAP_RESAMPLES)
        idx = rng.integers(0, n, size=(stop - start, n))
        medians[start:stop] = np.median(diffs[idx], axis=1)
    lo, hi = np.percentile(medians, INTERVAL_PERCENTILES)
    return float(lo), float(hi)


def wilcoxon_p(diffs: np.ndarray) -> tuple[float, str]:
    """Two-sided paired Wilcoxon signed-rank p-value and a note on how it was had."""
    nonzero = diffs[diffs != 0]
    if nonzero.size == 0:
        return 1.0, "all-differences-zero"
    from scipy.stats import wilcoxon

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        result = wilcoxon(nonzero)
    p = float(getattr(result, "pvalue"))
    if math.isnan(p):
        return 1.0, "wilcoxon-undefined"
    return p, "scipy.stats.wilcoxon, zero differences dropped"


def paired_summary(diffs: list[float], key: str) -> dict[str, Any]:
    d = np.asarray(diffs, dtype=np.float64)
    n = int(d.size)
    if n == 0:
        return {"n": 0, "underpowered": True}
    lo, hi = bootstrap_median_interval(d, key)
    p, p_note = wilcoxon_p(d)
    return {
        "n": n,
        "median": float(np.median(d)),
        "mean": float(np.mean(d)),
        "interval95": [lo, hi],
        "wilcoxon_p": p,
        "wilcoxon_note": p_note,
        "interval_excludes_zero": bool(lo > 0 or hi < 0),
        "n_positive": int(np.sum(d > 0)),
        "n_negative": int(np.sum(d < 0)),
        "n_zero": int(np.sum(d == 0)),
        "underpowered": n < UNDERPOWERED_BELOW,
    }
