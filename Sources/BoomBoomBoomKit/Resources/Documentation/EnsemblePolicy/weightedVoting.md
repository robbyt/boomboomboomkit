---
id: weightedVoting
title: Per-Source Weighted Vote
payload: SignalWeights
---
**What it does.** Resolves the DSP and ML voices by effective vote (each source's confidence multiplied by its per-source weight from the associated _SignalWeights_) and returns the higher, with DSP winning ties. The same weights structure also scales the strength of Phase-2a metadata corroboration through its _fileMetadata_ weight, so one configuration governs both cross-signal fusion and how strongly file tags influence the result. It invokes the ML technique when one is attached and emits a weight-resolution record to the trace. The associated _SignalWeights_ is the single source of the weights; the resolution never reads them from anywhere else.

**When to pick it.** Choose it when equal peer weighting is not what your corpus wants and you need to tilt the ensemble: trusting DSP more than a still-maturing model, or damping metadata corroboration on a library with unreliable tags. It is the tunable generalization of the _default_ policy, so pass custom _SignalWeights_ to express exactly how much each signal should count. Use it when you have measured per-source reliability and want the fusion to reflect it rather than assuming parity.

**Tradeoff.** Weights are easy to misconfigure: a poorly chosen set silently biases every decision, and because the effect is multiplicative with confidence it compounds a mis-calibrated source rather than correcting it. Over-weighting an optimistic ML model makes it override correct DSP on exactly the tracks where it is confidently wrong. Tuning weights to one corpus also risks overfitting, so a configuration that lifts accuracy on your validation set can regress on unseen material, and the single-number-per-source model cannot capture that a source is reliable for some genres but not others.
