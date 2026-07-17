---
id: implausibleForContext
title: Demoted — Implausible for Context
---
**What it does.** Records that a signal source's contribution was down-weighted (not dropped) in the unified pool because its value was implausible given the surrounding context — a vote that, while present, sits far enough outside what the other evidence supports that the pool trusts it less. It is one of two typed demotion reasons, distinguishing a context-driven plausibility judgment from a source-specific one. Demotion records the signal as set aside from the winning decision while preserving its original confidence in the diagnostic trace — it is a flag, not a graduated weight reduction, so the pool keeps the value visible rather than deleting it.

**When to pick it.** You read it in the participation trace to understand why a source that did contribute was set aside from the winning decision. Treat it as excluded-for-the-decision but retained-for-the-record: the pool judged the value an outlier against the other signals and kept it out of the winning choice rather than letting it swing the result, while its confidence stays visible in the trace.

**Tradeoff.** Plausibility is judged against the rest of the pool, so the mechanism fails when the majority is wrong: a correct but unusual tempo — a genuinely fast or slow track that disagrees with misleading corroborating signals — gets demoted precisely because it is the outlier, and the pool converges more confidently on the wrong consensus. Demotion keeps the value in the trace rather than dropping it silently, but a correct source that is repeatedly set aside can still lose to a plausible-looking error, so the reason marks exactly the cases where an outlier deserved a closer look rather than exclusion.
