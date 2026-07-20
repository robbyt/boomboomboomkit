---
id: fineGridRefinement
title: Fine-Grid Tempo Refinement
---
**What it does.** Refines the winning BPM candidate with a short fine-grid DFT, narrowing the estimate from an integer tempo to fractional precision on roughly a half-BPM grid. It runs a targeted transform around the selected candidate (typically one to three of them) after the coarse tempo has been chosen, sharpening the final number without re-running the whole pipeline. It is a core part of the baseline pipeline and the _optimal_ preset.

**When to pick it.** Keep it enabled whenever sub-integer accuracy matters, which is almost always: DJ software, beat-grid alignment, and any consumer comparing against a reference tempo need the fractional precision this stage provides. It is part of the baseline because without it the library reports only whole-number BPMs, which are frequently off by the fraction that separates a passing match from a miss under a tight tolerance. There is little reason to disable it in production.

**Tradeoff.** Refinement sharpens whatever candidate won the coarse selection, so it cannot fix an upstream mistake: if octave disambiguation handed it a half-tempo winner, fine-grid refinement returns a precise version of the wrong tempo, and the added precision can make a wrong answer look more authoritative than it is. It also assumes the true tempo is stable near the coarse estimate; on tracks with real tempo drift the single refined value is a false-precision summary of a moving target, reporting fractional certainty the material does not support.
