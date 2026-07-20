---
id: level3
title: Level 3: Optimal (single window)
---
**What it does.** Runs the _optimal_ technique set (ACF sharpening plus sub-band octave voting plus fine-grid refinement, three candidates) over a single 30-second window, with no progressive retry. Adding ACF sharpening to the baseline is the largest observed single-technique gain in the library's internal ablation, so level 3 is the entry point to the strongest measured DSP configuration. Levels 3, 4, and 5 currently resolve to this identical DSP setup; the finer granularity is a reserved control for future intensity-proportional compute budgeting, since the ComputeBudget fractions are uniform (_budget_ is _ComputeBudget.default_) at every level today.

**When to pick it.** Choose it when you want the best single-window DSP accuracy without paying for multi-window progressive analysis: it balances speed and correctness for well-structured tracks. It is DSP-only; every _EnsemblePolicy_ is coherent but ML-inert unless a technique is wired up, and _dspOnly_ is the default pairing. Prefer level 6 or 7 when a track's tempo may shift across its duration.

**Tradeoff.** The single 30-second window is the weakness: with no progressive retry, level 3 cannot recover from a slice that happens to be unrepresentative (an intro, a breakdown, or a section at a different tempo), and it accepts a low-confidence answer rather than re-analyzing with longer windows. Because levels 3-5 are identical today, choosing 4 or 5 over 3 adds no accuracy; the higher numbers are a statement of intent, not a guarantee of a better result, until the ML tiers are wired.
