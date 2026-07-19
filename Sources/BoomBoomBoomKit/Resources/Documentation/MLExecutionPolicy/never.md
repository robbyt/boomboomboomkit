---
id: never
title: Never Run ML
---
**What it does.** Suppresses ML inference entirely: the model is never invoked regardless of DSP confidence. It is the hard-off setting for the ML-execution dial, the decision of _when_ to run a model, distinct from _EnsemblePolicy_'s decision of how to combine the DSP and ML voices once both exist. With _never_ there is no ML voice to combine. This policy is a forward-declared, configurable-but-inert surface today: it is declared but not yet wired into the Options-driven intensity override that will consume it.

**When to pick it.** Choose it when you want a guaranteed DSP-only run for reproducibility, latency, or as a control arm, the same intent as _EnsemblePolicy.dspOnly_ but expressed on the execution axis. It is the correct setting when a model is present in the configuration for other reasons but you want it dormant, or when you are measuring the DSP baseline without any inference cost.

**Tradeoff.** Never running ML forgoes any accuracy a model could add: on genres or edge cases where DSP is weak and a trained model would recover the tempo, _never_ ships the DSP mistake with no second opinion. Because this policy is not yet Options-wired, selecting it today is a statement of intent rather than an active gate. The current pipeline's ML execution is governed elsewhere, so a consumer expecting _never_ to change present-day behavior will find it inert until the wiring lands.
