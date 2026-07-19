---
id: level4
title: Level 4: Optimal (single window)
---
**What it does.** Resolves to the same DSP configuration as levels 3 and 5: the _optimal_ technique set (ACF sharpening plus sub-band octave voting plus fine-grid refinement, three candidates) over a single 30-second window with no progressive retry. Level 4 sits in the middle of the identical-DSP band 3-5. The per-source ComputeBudget fractions are reserved and uniform (_budget_ is _ComputeBudget.default_, all 1.0), so level 4 is not a throttled or enriched variant of its neighbors: it is byte-for-byte the same DSP path, with the numeric granularity held in reserve for future intensity-proportional compute budgeting.

**When to pick it.** Pick it when you want the empirically best single-window DSP accuracy and prefer a mid-band value to signal a default intent. Functionally it is interchangeable with levels 3 and 5 today. It is DSP-only, so any _EnsemblePolicy_ is coherent (ML-inert without a wired technique) and _dspOnly_ is the natural pairing. Move up to level 6 or 7 when the track may change tempo and you want progressive multi-window analysis.

**Tradeoff.** Because levels 3, 4, and 5 are identical, selecting level 4 over level 3 adds nothing measurable: a consumer expecting monotonically increasing accuracy within this band is misled by the number, which is the current state rather than a defect. And like the whole band, level 4's single 30-second window with no retry fails on structurally varied tracks: an unrepresentative slice yields a confident but wrong tempo that a progressive level would have caught by re-analyzing with longer windows.
