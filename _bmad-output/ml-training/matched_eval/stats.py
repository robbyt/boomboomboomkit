"""Paired statistics and strata for the Story 15.9 evaluation.

For one pairing (A, B) and one metric, the paired signed differences are
`value(A) - value(B)` over the tracks where both have a value; n is that paired
count everywhere, including the underpowered mark (n < UNDERPOWERED_BELOW).

Continuous metrics: the median difference, a bootstrap 95 % interval of the
median, and the two-sided paired Wilcoxon signed-rank p-value (scipy, zero
differences dropped).

Yes/no metrics (differences in {-1, 0, 1}): the mean difference, a bootstrap 95 %
interval of the mean, and the exact McNemar p-value from the two discordant
counts (the Story 15.5 implementation).

Bootstrap: BOOTSTRAP_RESAMPLES resamples of the tracks with replacement,
percentile interval, seeded from BOOTSTRAP_SEED and the summary's key so the
result does not depend on the order summaries are computed in.

Every p-value also gets a Benjamini-Hochberg q-value over all tests in its corpus
(`benjamini_hochberg`), applied by the report once every test is known.
"""

from __future__ import annotations

import math
import warnings
import zlib
from typing import Any, Callable

import numpy as np

import matched_eval  # noqa: F401  (sys.path setup)

BOOTSTRAP_RESAMPLES = 10_000
BOOTSTRAP_SEED = 20_261_030
INTERVAL_PERCENTILES = (2.5, 97.5)
UNDERPOWERED_BELOW = 10
DIRECTION_Q_BELOW = 0.05
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


def bootstrap_interval(
    diffs: np.ndarray, key: str, statistic: Callable[..., np.ndarray] = np.median
) -> tuple[float, float]:
    """Percentile 95 % interval of `statistic` over paired resamples of `diffs`."""
    n = diffs.size
    if n == 0:
        raise ValueError("no differences")
    if np.all(diffs == diffs[0]):
        v = float(diffs[0])
        return v, v
    rng = _rng(key)
    stats = np.empty(BOOTSTRAP_RESAMPLES)
    for start in range(0, BOOTSTRAP_RESAMPLES, _CHUNK):
        stop = min(start + _CHUNK, BOOTSTRAP_RESAMPLES)
        idx = rng.integers(0, n, size=(stop - start, n))
        stats[start:stop] = statistic(diffs[idx], axis=1)
    lo, hi = np.percentile(stats, INTERVAL_PERCENTILES)
    return float(lo), float(hi)


def bootstrap_median_interval(diffs: np.ndarray, key: str) -> tuple[float, float]:
    return bootstrap_interval(diffs, key, np.median)


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


def mcnemar_p(a_only: int, b_only: int) -> float:
    from fixed_time.report import mcnemar_exact_p

    return float(mcnemar_exact_p(a_only, b_only))


def paired_summary(diffs: list[float], key: str, *, yes_no: bool = False) -> dict[str, Any]:
    d = np.asarray(diffs, dtype=np.float64)
    n = int(d.size)
    if n == 0:
        return {"n": 0, "underpowered": True}
    n_pos = int(np.sum(d > 0))
    n_neg = int(np.sum(d < 0))
    if yes_no:
        statistic = "mean"
        lo, hi = bootstrap_interval(d, key, np.mean)
        p = mcnemar_p(n_pos, n_neg)
        p_note = "exact McNemar from the discordant counts"
    else:
        statistic = "median"
        lo, hi = bootstrap_interval(d, key, np.median)
        p, p_note = wilcoxon_p(d)
    return {
        "n": n,
        "statistic": statistic,
        "estimate": float(np.mean(d) if yes_no else np.median(d)),
        "median": float(np.median(d)),
        "mean": float(np.mean(d)),
        "interval95": [lo, hi],
        "p_value": p,
        "p_note": p_note,
        "interval_excludes_zero": bool(lo > 0 or hi < 0),
        "n_positive": n_pos,
        "n_negative": n_neg,
        "n_zero": int(np.sum(d == 0)),
        "underpowered": n < UNDERPOWERED_BELOW,
    }


def benjamini_hochberg(pvalues: list[float]) -> list[float]:
    """Benjamini-Hochberg adjusted p-values (q-values), in input order."""
    m = len(pvalues)
    if m == 0:
        return []
    order = sorted(range(m), key=lambda i: pvalues[i])
    q = [0.0] * m
    running = 1.0
    for rank in range(m, 0, -1):
        i = order[rank - 1]
        running = min(running, pvalues[i] * m / rank)
        q[i] = min(1.0, running)
    return q


def direction_allowed(s: dict[str, Any]) -> bool:
    """A direction needs paired n >= 10, an interval excluding zero and q < 0.05."""
    return (
        s.get("n", 0) >= UNDERPOWERED_BELOW
        and bool(s.get("interval_excludes_zero"))
        and s.get("q_value", 1.0) < DIRECTION_Q_BELOW
    )
