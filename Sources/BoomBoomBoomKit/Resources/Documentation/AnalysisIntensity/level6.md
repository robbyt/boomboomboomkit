---
id: level6
title: Level 6: Progressive (two windows)
---
**What it does.** Runs the _optimal_ technique set over two windows (30 and 60 seconds) and merges their results. Level 6 is the first intensity to escape the single-window analysis of levels 1-5: the window list _windowSizes_ is the only thing that decides how many windows run, and levels 1-5 each list a single window where level 6 lists two. Both windows always run and are combined by the selection policy; there is no confidence gate and no early stop, so the 60-second window is analyzed no matter how the 30-second window scored. ComputeBudget fractions remain reserved and uniform (_budget_ is _ComputeBudget.default_) at every level, so level 6's advance over level 5 is the second window, not a budget change.

**When to pick it.** Choose it when accuracy matters more than the last few milliseconds and a track may not be uniform: the second, longer window gives the estimate a wider view than a single 30-second slice, and merging across windows can correct a reading the first window got wrong. It is a general-purpose choice below the full level 7. It is DSP-only; every _EnsemblePolicy_ is coherent (ML-inert without a wired technique) and _dspOnly_ is the natural pairing.

**Tradeoff.** Running two windows costs roughly twice the single-window compute, and merging does not by itself fix an octave error: if the octave-doubled tempo self-reports high confidence in both windows, the default maximum-confidence merge still selects the wrong value, because more windows agreeing on the same mistake does not make it right. Level 6 is also limited to a 60-second window, so a track whose representative groove only appears later still benefits from level 7's third 90-second window.
