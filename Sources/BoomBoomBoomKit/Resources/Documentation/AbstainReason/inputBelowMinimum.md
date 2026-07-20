---
id: inputBelowMinimum
title: Abstained: Input Below Minimum
---
**What it does.** Records that a signal source declined to participate because its input did not meet a minimum requirement: too little audio, too few candidates, or some other threshold the source needs before it can contribute. It is a data-driven abstain, distinct from being switched off by policy: the source could act but the input was insufficient. In the participation trace it marks a case of insufficient input rather than a configuration choice.

**When to pick it.** Read it in the diagnostic trace when a source contributed nothing and you want to know whether the cause was configuration or data. Treat it as a source that attempted to qualify and could not, which helps when debugging why a short clip or a sparse track produced a thinner pool than a full-length file would.

**Tradeoff.** The minimum is a fixed threshold, so it can abstain on borderline inputs that held usable signal: a slightly-too-short window discarded whole when a lower bar would have admitted it, costing the pool a voice it could have used. A threshold set too low instead lets under-supported sources contribute noise. Because the reason is diagnostic only, its own failure mode is interpretive: a consumer who reads _inputBelowMinimum_ as bad audio rather than below this source's bar draws the wrong conclusion about a track that was only shorter than the source required.
