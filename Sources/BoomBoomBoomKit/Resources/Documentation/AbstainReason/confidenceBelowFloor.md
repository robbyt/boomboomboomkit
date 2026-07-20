---
id: confidenceBelowFloor
title: Abstained: Confidence Below Floor
---
**What it does.** Records that a signal source produced a result but declined to contribute it because its own confidence fell below a floor: the source had an answer but did not rank it reliable enough to add to the pool. Among the typed abstain reasons it is neither a configuration toggle nor insufficient input, but a self-assessed judgment that the result sat below the confidence the source requires before it will vote. In the participation trace it marks a source that withheld a low-confidence opinion.

**When to pick it.** Read it in the diagnostic trace when a source that normally contributes stayed silent on a particular track. Treat it as a self-assessed abstain: the source declined to contribute a weak vote rather than lower the reliability of the pool, which is the intended behavior when a low-confidence vote would only add noise to the selection.

**Tradeoff.** A confidence floor trusts the source's own calibration, which is where it can fail: a source that under-reports confidence abstains on tracks where its answer was correct, so the pool loses a right vote to excess caution. A floor set too high silences useful contributions; set too low it admits the noise the abstain was meant to exclude. Because the reason is diagnostic, its failure surfaces as a missing voice rather than a wrong number, yet a systematically under-confident source can starve the pool on the hard tracks where its vote was needed.
