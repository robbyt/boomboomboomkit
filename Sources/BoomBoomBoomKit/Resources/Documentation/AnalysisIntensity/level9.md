---
id: level9
title: Level 9 — Reserved for ML
---
**What it does.** Uses the identical full progressive DSP configuration as levels 7 and 8 — the _optimal_ technique set over 30, 60, and 90-second windows with a 0.40 retry threshold — and is the middle of the ML-reserved band 8-10. There is no distinct behavior at level 9 today: no ML augmentation is wired into the intensity mapping, and the ComputeBudget fractions are reserved and uniform (_budget_ is _ComputeBudget.default_). Level 9 exists to give the scale room for a future intermediate ML tier between _thorough_ and _maximum_.

**When to pick it.** Pick it when you want to express an intent slightly stronger than level 8 but short of the maximum, understanding that today all three of levels 8, 9, and 10 collapse to level 7's DSP behavior. As at level 8, the ML-invoking _EnsemblePolicy_ cases are the ones meant to matter here, but they stay inert until an _MLTechnique_ is supplied; without one, _dspOnly_ and the DSP path govern the result.

**Tradeoff.** Level 9's granularity is entirely notional today: it produces the same DSP tempo and candidates as levels 7, 8, and 10 — all capped to effective level 7 without a wired technique — so choosing it over its neighbors changes no tempo, only the intensity-reporting metadata, and a consumer expecting a distinct accuracy point is misled by the number. Like the whole reserved band, it inherits level 7's DSP failure modes unchanged — an octave error that survives the multi-window merge persists because no ML voice is active to override it in the default configuration.
