---
id: acfSharpening
title: Autocorrelation Peak Sharpening
---
**What it does.** Squares the autocorrelation function element-wise before peak selection, which sharpens the periodicity peaks so the dominant tempo separates from its neighbors. It is a single vector pass over a few thousand values and changes only how pronounced the ACF peaks are, not the underlying onset detection. It produces the largest measured accuracy gain of any single DSP technique in the library: on the OA300 corpus it recovers two additional tracks, and it is part of the _optimal_ preset that drives the default intensity mapping.

**When to pick it.** Enable it in almost any configuration: its cost is negligible and its measured benefit is the best of any single technique, so it belongs in nearly every preset. Pick it specifically when ambiguous tempos are producing broad, flat ACF peaks that peak selection cannot separate, since the squaring pulls the true period ahead of its harmonics. It composes with sub-band voting and fine-grid refinement, which is the _optimal_ combination.

**Tradeoff.** Sharpening amplifies whatever peak is already strongest, so when the strongest ACF peak is the wrong one (a dominant half-tempo or double-tempo lobe) squaring makes that error more confident rather than less, widening the gap between the distractor and the true fundamental it should have lost to. It offers no help on tracks whose problem is a missing or weak true-tempo peak rather than a poorly separated one; there is nothing to sharpen if the correct period never rose above the noise, so the technique does nothing useful on the hardest cases.
