---
id: thresholdGated
title: Threshold-Gated Majority
---
**What it does.** Behaves like _simpleMajority_, picking the largest cluster of at least two windows, with the same confidence-then-index tiebreaks, but adds a gate: the winning cluster's strongest single-window confidence must meet the configured _votingThreshold_ from the analysis options (range 0.0 to 1.0). If the best cluster falls below the threshold, the policy rejects the consensus and falls back to _maxConfidence_ across all windows. Out-of-range thresholds silently clamp and non-finite values fall back to a permissive 0.0. The threshold, not a case payload, carries the tuning value.

**When to pick it.** Use it in benchmark sweeps or production tuning when you want to accept window consensus only above a confidence threshold, rejecting agreement that is real but weak. At the default threshold of 0.0 it is identical to _simpleMajority_, so it changes nothing until you raise the threshold; raising it lets you discard low-confidence consensus without recompiling, which is what parameter sweeps over a corpus need.

**Tradeoff.** A threshold set too high rejects legitimate consensus and forces the policy back onto _maxConfidence_, reintroducing the over-confident-outlier failure the vote was meant to avoid, so a high threshold can make accuracy worse, not better, by discarding correct-but-modest agreement. Because the gate reads only the cluster's single strongest window rather than its collective confidence, a cluster of several moderately confident windows can fail the threshold even though their agreement is meaningful, making the policy blind to breadth in the situation where breadth is the relevant signal.
