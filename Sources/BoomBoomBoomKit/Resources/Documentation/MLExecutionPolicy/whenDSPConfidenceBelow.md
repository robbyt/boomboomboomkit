---
id: whenDSPConfidenceBelow
title: Run ML When DSP Is Unsure
payload: Double
---
**What it does.** Runs ML inference only when the DSP confidence falls below the associated threshold, skipping the model when DSP is already confident. The threshold is the case's payload, a _Double_; the default policy is this case at 0.85, so ML runs only on tracks DSP is less than 85 percent sure about. It is the adaptive middle setting of the ML-execution dial, spending inference where it is most likely to help. The threshold is finiteness-guarded where it is consumed, and the policy is a forward-declared, configurable-but-inert surface today.

**When to pick it.** Choose it when you want the accuracy benefit of a model without paying inference cost on every track, the cost-aware default that reserves ML for the ambiguous cases where DSP is uncertain. Tune the threshold to trade coverage against cost: a higher threshold runs ML more often, a lower one reserves it for only the least-confident tracks.

**Tradeoff.** The policy trusts DSP confidence as a proxy for when ML is needed, which fails exactly when DSP is confidently wrong: an octave error that self-reports high confidence sits above the threshold, so ML is never consulted on the track it could have corrected. A poorly-chosen threshold also mis-allocates inference: too low and the model rarely runs, too high and the cost savings vanish. Because the policy is not yet Options-wired, the threshold has no present-day effect; selecting it today is inert until the wiring lands.
