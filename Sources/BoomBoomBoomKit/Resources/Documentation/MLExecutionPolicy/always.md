---
id: always
title: Always Run ML
---
**What it does.** Invokes ML inference on every analysis, regardless of DSP confidence; the final BPM is then still resolved by the selected _EnsemblePolicy_. It is the always-on setting for the ML-execution dial — it guarantees the model is invoked on every track, even when DSP is already confident (the model may still abstain by returning nil, in which case there is no ML voice for the ensemble to weigh). Like its siblings it is a forward-declared, configurable-but-inert surface today: declared but not yet wired into the Options-driven override that will consume it.

**When to pick it.** Choose it when you want the model consulted on every track — to evaluate its standalone behavior across a whole corpus, or because you trust it to add value even where DSP is confident. It pairs with the ML-invoking _EnsemblePolicy_ cases (_mlOnly_, _highestConfidence_, _weightedVoting_, _default_): _always_ guarantees the model is invoked, and the ensemble policy decides how much its evaluation counts when it produces one.

**Tradeoff.** Running ML unconditionally pays the inference cost on every track, including the many where DSP was already correct and the model adds nothing — pure overhead. Worse, a systematically mis-calibrated model that always runs gets to influence every result under a fusing ensemble policy, so its bias contaminates tracks DSP would have gotten right. And because the policy is not yet Options-wired, selecting _always_ today does not actually force inference — a consumer expecting it to change present-day behavior finds it inert until the wiring lands.
