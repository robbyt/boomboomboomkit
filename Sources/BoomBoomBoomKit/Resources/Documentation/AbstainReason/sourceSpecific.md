---
id: sourceSpecific
title: Abstained — Source-Specific Reason
payload: String
---
**What it does.** Carries a free-form, source-defined reason a signal family abstained when none of the typed cases fit. It is the escape hatch on the abstain enum: a string payload lets a source name a decline condition the closed set of typed reasons does not anticipate, keeping the pool's participation trace expressive without forcing every possible reason into the type. The library itself uses this pattern for two shipped named constants — the ML source's post-selection deferral and the DSP source's empty-candidate case — which are stable, named reasons rather than ad-hoc text.

**When to pick it.** A source reaches for it when it has a genuine, specific reason to abstain that the typed cases — _policyDisabled_, _inputBelowMinimum_, _confidenceBelowFloor_ — do not capture, a condition unique to that source's internals. Prefer a typed case whenever one applies; the escape hatch is for the honestly novel reason, and a source that uses it should treat the string as a stable identifier, not a sentence.

**Tradeoff.** The free string trades typed coverage for flexibility, and the cost lands at the pool layer: a source-specific reason cannot be matched, counted, or reasoned about the way a typed case can, so heavy reliance on it erodes the diagnostic value of the whole participation trace into unstructured text. It also invites drift — two sources inventing different spellings for the same condition, or a reason changing between releases — which is why a new recurring reason belongs as a typed case, not a permanent string.
