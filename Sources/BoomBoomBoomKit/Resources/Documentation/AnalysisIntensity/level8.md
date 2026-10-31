---
id: level8
title: Level 8: Reserved for ML
---
**What it does.** Uses level 7's DSP path: up to three disjoint 30-second rhythmic regions by default, with final-BPM voting. It is reserved for ML integration (aliased _thorough_); without an ML technique, its effective intensity falls back to level 7 and records a degradation reason. The historical 30-, 60-, and 90-second windows remain available with _useRhythmicRegions_ disabled. _ComputeBudget_ fractions remain reserved and uniform, so merely requesting level 8 does not buy additional DSP time or a fourth region. The default continues to report one tempo rather than tracking changes through the file.

**When to pick it.** Choose it when you want to signal intent to use the deepest analysis, including future ML tiers, and are comfortable that today it equals level 7's DSP-only behavior. It is the natural level at which the ML-invoking _EnsemblePolicy_ cases (_default_, _mlOnly_, _highestConfidence_, _weightedVoting_) are conceptually meant to operate, though they stay inert unless you wire an _MLTechnique_, at which point they fuse an ML result with the DSP result. If you only want the strongest built-in DSP configuration, level 7 expresses that directly.

**Tradeoff.** Without an ML technique, level 8 reports a degradation reason and gives the same DSP result as level 7. Region agreement can still be wrong when several sections repeat a misleading half-time or double-time pulse. Raising intensity does not correct that error on its own, and a short decoded clip may not contain three independent regions. Consumers that need to know whether ML actually ran should inspect effective intensity and the degradation reason rather than treating the requested level as proof of additional analysis.
