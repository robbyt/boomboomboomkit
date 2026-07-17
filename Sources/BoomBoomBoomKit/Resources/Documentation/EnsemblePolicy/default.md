---
id: default
title: Balanced Peer Ensemble
---
**What it does.** Resolves the DSP and ML voices as equal peers: it is the balanced-weighting ensemble, equivalent to _weightedVoting_ with default _SignalWeights_. The metadata-corroborated DSP result and the ML evaluation, when a technique is wired up, are each scored as confidence times weight, and the higher effective vote wins, with DSP taking ties. It invokes the ML technique when one is present and emits an ensemble-weight-resolution record to the trace. With no ML technique attached it degrades to the DSP winner unchanged.

**When to pick it.** Choose it when you have wired up an _MLTechnique_ and want it to participate on equal footing with DSP rather than dominating or merely tie-breaking — the general-purpose choice for a genuine two-signal ensemble. It is the policy to select when you trust neither source categorically and want calibrated confidence to arbitrate case by case. Note that _Options.ensemblePolicy_ still defaults to _dspOnly_, not this case, so you must set it explicitly; the name reflects its role as the recommended _ensemble_ default once ML is in play, not the library's out-of-box setting.

**Tradeoff.** Equal weighting assumes both voices are comparably calibrated, and it fails when they are not: if the ML model reports confidence on a different scale than DSP, the raw confidence-times-weight comparison can systematically favor whichever source is more optimistic, letting a mis-calibrated model override correct DSP on tracks where it should have deferred. Because DSP wins ties and metadata corroboration may already have pushed DSP confidence to its ceiling, a genuinely better ML answer of equal confidence is silently discarded.
