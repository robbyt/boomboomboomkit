---
id: level6
title: Level 6: Two Regions
---
**What it does.** Runs the _optimal_ technique set on up to two disjoint 30-second rhythmic regions and combines their final BPMs with the default window-voting policy. Each region produces an independent, fully disambiguated tempo estimate. With _useRhythmicRegions_ disabled, level 6 instead uses the historical 30- and 60-second windows from one energy-transition anchor. Those historical windows can share samples; the default regions do not. The _ComputeBudget_ fractions remain reserved and uniform, so the second region is the actual increase in work from level 5. A short decoded clip may yield fewer than two regions.

**When to pick it.** Choose it for two independent views of a track at less cost than level 7. This is useful when a quiet introduction or an isolated transition is a poor anchor for tempo analysis. The selector samples the available decoded audio and prefers rhythmically repeatable sections; it does not produce a tempo map or report BPM changes within the file. It remains DSP-only unless an ML technique is supplied, and the beat-grid pass keeps its separate timing anchor.

**Tradeoff.** Two regions may disagree, in which case voting falls back to the strongest result and can return a wrong octave. A short clip may provide only one usable region, so no vote can correct its estimate. Two regions can also agree on the same incorrect tempo; agreement is evidence of consistency, not proof that the detected pulse is the annotated beat level. Inspect the trace evidence when that distinction matters.
