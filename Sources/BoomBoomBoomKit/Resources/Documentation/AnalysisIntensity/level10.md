---
id: level10
title: Level 10 — Maximum (reserved for ML)
---
**What it does.** Uses the same full progressive DSP configuration as levels 7 through 9 — the _optimal_ technique set over three windows (30, 60, and 90 seconds); it attempts all three and merges the successful results — and is the top of the scale (aliased _maximum_), reserved for the deepest future ML integration including a possible ML quorum. Today it behaves exactly like level 7: no ML is wired into the intensity mapping, and the ComputeBudget fractions are reserved and uniform (_budget_ is _ComputeBudget.default_) as at every level. Level 10 marks the ceiling of intended thoroughness, not a distinct present-day pipeline.

**When to pick it.** Choose it when you want to request the most thorough analysis the library will ever offer and are content that today it equals level 7's DSP-only behavior. It is the level at which a fully wired ML ensemble — the _default_, _mlOnly_, _highestConfidence_, or _weightedVoting_ policies with an actual _MLTechnique_ — is most conceptually at home; without a technique those policies stay inert and _dspOnly_ governs.

**Tradeoff.** Level 10 makes the strongest promise and, today, keeps only level 7's: it produces the same DSP result as the rest of the reserved band — capped to effective level 7 without a wired technique, with a degradation reason recorded — so a consumer who selects _maximum_ expecting a decisive accuracy gain over level 7 is disappointed, since the extra thoroughness is entirely reserved until ML lands. It inherits level 7's DSP failure modes verbatim, so on octave-ambiguous material it can still report half or double the true tempo, because the maximum label buys no additional disambiguation in the current DSP-only build.
