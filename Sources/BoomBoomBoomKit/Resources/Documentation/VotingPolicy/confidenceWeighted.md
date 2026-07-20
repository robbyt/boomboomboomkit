---
id: confidenceWeighted
title: Confidence-Weighted Cluster
---
**What it does.** Scores every window cluster, singletons included, by the sum of its windows' confidences, and elects the highest total. Ties break toward the cluster with the strongest single window, then toward the lowest original window index. If the winner is a singleton, its summed confidence is one window's, so it carries no consensus benefit, and the policy falls back to _maxConfidence_ over all windows; otherwise it returns the highest-confidence window in the winning cluster. The _votingThreshold_ option is ignored.

**When to pick it.** Choose it when a smaller group of high-confidence windows should outvote a larger group of low-confidence ones, the case _simpleMajority_ cannot express, because it counts window membership before it weighs confidence. It suits corpora where confidence is well-calibrated and discriminating, letting two high-confidence windows outweigh three low-confidence ones. It rewards confidence pooled across a cluster rather than membership count.

**Tradeoff.** Summed confidence is only as trustworthy as the confidence calibration, and it fails when the pipeline is systematically over-confident about a wrong tempo: an octave-doubled cluster with two high-confidence windows beats a correct three-window cluster of modest confidence, turning mis-calibration directly into a mis-pick. The singleton-fallback guard keeps one high-confidence window from being treated as consensus, but it also means the policy adds nothing over _maxConfidence_ whenever the highest-scoring cluster is a lone window: the resolution defers to the highest-confidence window, so on tracks where no two windows agree it inherits _maxConfidence_'s over-confident-outlier failure rather than improving on it.
