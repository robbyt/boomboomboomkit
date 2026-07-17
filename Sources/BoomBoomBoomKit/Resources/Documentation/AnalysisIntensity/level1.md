---
id: level1
title: Level 1 — Fastest
---
**What it does.** Runs the leanest possible pipeline: a single tempo candidate, one 15-second analysis window, and none of the progressive-retry machinery of the higher levels. It is the bottom of the ten-step ordinal scale (aliased _fastest_), targeting roughly 50 milliseconds per track. The per-source ComputeBudget fractions are reserved and uniform — _budget_ returns the full _ComputeBudget.default_ (1.0 for DSP, ML, and beat-grid) at every level — so what distinguishes level 1 is its technique set, its short window, and its lack of retry, not a throttled budget.

**When to pick it.** Reach for it when latency dominates and approximate is good enough: live metering, a first-pass estimate you will refine later, or bulk triage over a large library where a rough tempo suffices. The intensity mapping itself adds no ML (levels 1-7 map to DSP-only technique sets; 8-10 reserve ML), so _dspOnly_ is the natural pairing — though ML fusion is not gated by intensity and can still participate at any level by wiring an _MLTechnique_ and an ML-invoking _EnsemblePolicy_.

**Tradeoff.** A single 15-second window and one candidate make level 1 fragile: if the opening 15 seconds are an intro, a breakdown, or ambient texture, the estimate reflects that section rather than the track's main groove, and no second window or retry exists to catch the error. With only one candidate extracted, octave-ambiguous material frequently reports half or double the true tempo and the pipeline never revisits that decision. It is the level most likely to be confidently wrong on structurally varied tracks — treat its output as a hint, not an answer.
