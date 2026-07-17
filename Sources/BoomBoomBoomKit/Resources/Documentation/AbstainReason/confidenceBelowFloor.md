---
id: confidenceBelowFloor
title: Abstained — Confidence Below Floor
---
**What it does.** Records that a signal source produced a result but declined to contribute it because its own confidence fell below a floor — the source had an answer but did not trust it enough to add to the pool. It is the most nuanced of the typed abstain reasons: not a configuration toggle and not insufficient input, but a self-assessed "I am not sure enough to vote". In the participation trace it marks a source that withheld a low-confidence opinion.

**When to pick it.** You read it in the diagnostic trace when a source that normally contributes stayed silent on a particular track. Treat it as an honest self-abstain — the source preferred to say nothing over voting weakly, which is usually the safe behavior when a shaky vote would only add noise to the selection.

**Tradeoff.** A confidence floor trusts the source's own calibration, which is exactly where it can fail: a source that under-reports confidence abstains on tracks where its answer was actually correct, so the pool loses a right vote to excessive caution. A floor set too high silences useful contributions; too low admits the noise the abstain was meant to exclude. Because the reason is diagnostic, its failure surfaces as a missing voice rather than a wrong number — but a systematically under-confident source can quietly starve the pool on precisely the hard tracks where its vote was needed.
