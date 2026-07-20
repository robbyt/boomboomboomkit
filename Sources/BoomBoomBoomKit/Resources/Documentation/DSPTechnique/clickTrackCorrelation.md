---
id: clickTrackCorrelation
title: Click-Track Cross-Correlation
---
**What it does.** Cross-correlates a synthetic click pattern at each candidate BPM against the onset envelope and rescores the candidates by how well a metronome at that tempo aligns with the actual onsets. The rescoring runs between candidate extraction and octave disambiguation, so candidates whose implied grid genuinely lands on the track's transients are preferred. It is a cheap sparse beat-search per candidate and is the technique that distinguishes the _clickAugmented_ preset from _optimal_.

**When to pick it.** Pick it when rhythmic-alignment evidence should break ties that raw periodicity scores leave ambiguous, on material where several tempos are periodically plausible but only one lines up with the downbeats. Enable it through the _clickAugmented_ preset when you want that alignment check layered on top of the optimal pipeline. It suits consumers who care specifically about grid alignment rather than bare tempo.

**Tradeoff.** On the internal evaluation corpus the _clickAugmented_ preset only _ties_ _optimal_ on primary accuracy while showing a marginal gain on the looser tolerance, so the alignment rescoring did not clear the margin needed to justify changing the default; its benefit is slight and corpus-dependent. It can also mislead on tracks with swung or syncopated timing, where a rigid synthetic click aligns better with a spurious straight-grid tempo than with the genuine but non-uniform pulse, promoting a metrically wrong candidate because it is more regular than the truth.
