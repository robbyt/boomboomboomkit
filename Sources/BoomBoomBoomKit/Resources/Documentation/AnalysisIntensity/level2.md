---
id: level2
title: Level 2: Baseline
---
**What it does.** Runs the _baseline_ technique set (sub-band octave voting plus fine-grid refinement, three candidates) over a single 30-second window, still the only window in the list. It is one step up from the minimal level 1: it adds the octave-disambiguation voting and fractional-BPM refinement the fastest level omits, at modestly higher cost. As at every level, the ComputeBudget fractions are reserved and uniform (_budget_ is _ComputeBudget.default_, all 1.0); the difference from level 1 is the larger technique set and the longer window.

**When to pick it.** Choose it when you need octave resolution and sub-integer precision but still care about speed: it fits quick analysis that must get the beat level right. The intensity mapping is DSP-only here, with _dspOnly_ the natural pairing; ML fusion is not gated by intensity, so a wired _MLTechnique_ and an ML-invoking _EnsemblePolicy_ can still participate at this level. It is the cheapest level that runs the octave-voting the library relies on to avoid half and double errors.

**Tradeoff.** One 30-second window means a low-confidence result is accepted as-is: level 2 analyzes no longer window, so a track whose 30-second slice is rhythmically ambiguous produces an unreliable answer that a multi-window level would also have viewed over 60 or 90 seconds. It also lacks the ACF-sharpening of the _optimal_ preset, so on tracks with broad, poorly-separated periodicity peaks it can mis-rank the true tempo against a close harmonic. Its accuracy is measurably below the level 3-and-up _optimal_ band.
