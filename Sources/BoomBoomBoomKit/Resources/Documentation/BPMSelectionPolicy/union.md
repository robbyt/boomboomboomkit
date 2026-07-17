---
id: union
title: Unmerged Candidate Union
---
**What it does.** Pools every candidate from every window without any clustering or deduplication, sorts the entire flat list by raw score, and caps it at the configured candidate count. The single highest-scoring candidate anywhere across all windows becomes the reported BPM, and the trace is taken from whichever window produced that winner. It is the most literal merge: no near-matches are combined, no votes are counted, the strongest raw peak simply wins.

**When to pick it.** Reach for it when you want maximum candidate diversity for downstream inspection — every window's alternates survive into the ranked list instead of being folded into clusters — or when you are debugging and want to see exactly which raw peaks the pipeline produced before any consensus logic reshapes them. It is also the honest choice when clustering tolerances are actively harmful for your material, for instance when genuinely distinct nearby tempos must not be merged together.

**Tradeoff.** Refusing to cluster means the same true tempo, split across windows into slightly different readings, competes against itself and dilutes its own standing, while a lone loud distractor faces no such penalty. This is the strategy most exposed to a single over-confident octave error: the loudest raw peak wins outright with zero corroboration required, so a half-tempo spike in one noisy window beats a fundamental that three windows agreed on. Without deduplication the returned candidate list is also frequently cluttered with near-identical entries, wasting the candidate budget on repeats.
