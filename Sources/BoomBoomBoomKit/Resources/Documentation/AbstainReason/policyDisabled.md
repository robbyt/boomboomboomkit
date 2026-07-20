---
id: policyDisabled
title: Abstained: Policy Disabled
---
**What it does.** Records that a signal source declined to participate in the unified pool because its governing policy was turned off: a source disabled by configuration before any input from the track was examined. It is one of the typed reasons a signal family abstains, distinguishing a deliberate configuration choice from a data-driven decline. In the pool's participation trace it marks the source as absent by design, not by failure.

**When to pick it.** Read rather than set it: it appears in the diagnostic participation trace when you inspect why a source contributed nothing. Treat it as switched off on purpose: the source was not consulted because policy excluded it, so its absence carries no signal about the audio itself, only about the configuration in effect.

**Tradeoff.** The reason is only as honest as the code that emits it: if a source abstains for a data reason but reports _policyDisabled_, a consumer reading the trace draws the wrong conclusion about why the pool lacked that voice, mistaking a real decline for a configuration toggle. Because the reason is diagnostic and does not itself change selection, its failure mode is interpretive: a mislabeled abstain corrupts a reader's understanding of the run without altering the BPM result, which makes such a mislabel easy to miss.
