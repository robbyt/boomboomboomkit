---
id: sourceSpecific
title: Demoted: Source-Specific Reason
payload: String
---
**What it does.** Carries a free-form, source-defined reason a signal family's contribution was demoted when the typed reason does not fit. It is the fallback case on the demotion enum, mirroring the same pattern on the abstain enum: a string payload lets a source name a set-aside condition the closed typed set does not anticipate, so the pool's participation trace can record why a voice was excluded from the winning decision (its diagnostic confidence retained) without forcing every reason into the type.

**When to pick it.** Pick it when a source has a specific, legitimate reason to demote its own contribution that the typed case (_implausibleForContext_) does not describe, a set-aside condition internal to that source. Prefer the typed case whenever it applies; the fallback case is for the novel reason, and the string should be treated as a stable identifier rather than a free-text explanation.

**Tradeoff.** The free string trades structured, matchable reasons for flexibility, and the cost appears at the pool layer: a source-specific demotion cannot be aggregated or compared the way a typed reason can, so relying on it turns the participation trace into unstructured text that is harder to reason about. It also invites drift: different spellings for the same condition, or a reason changing between releases, so a recurring source-specific demotion is a signal that a new typed case is warranted rather than a permanent string.
