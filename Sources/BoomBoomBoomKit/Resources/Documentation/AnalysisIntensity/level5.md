---
id: level5
title: Level 5 — Optimal (single window)
---
**What it does.** Resolves to the same DSP configuration as levels 3 and 4: the _optimal_ technique set (ACF sharpening plus sub-band octave voting plus fine-grid refinement, three candidates) over a single 30-second window, with no progressive retry. Level 5 is the top of the identical-DSP band 3-5 and the last level before progressive multi-window analysis begins at level 6. As everywhere on the scale, the ComputeBudget fractions are reserved and uniform (_budget_ is _ComputeBudget.default_), so level 5 differs from its band-mates only in the number, not the behavior.

**When to pick it.** Choose it when you want the strongest single-window DSP accuracy and want to signal the highest intent within the no-retry band. It is functionally identical to levels 3 and 4 today. It is DSP-only, so every _EnsemblePolicy_ is coherent (ML-inert unless a technique is wired up) with _dspOnly_ the default. If a track's tempo may drift across its length, step up to level 6, where progressive analysis with a second 60-second window begins.

**Tradeoff.** Level 5 shares the band's core limitation: one 30-second window with no progressive retry cannot rescue an unrepresentative slice, so a track whose analyzed section differs from its main groove yields a confident wrong answer. And because it is byte-identical to levels 3 and 4, a consumer who raises intensity from 3 to 5 expecting an accuracy gain gets none — the granularity is reserved for future intensity-proportional budgeting, so within this band a higher number is a statement of intent, not a better result.
