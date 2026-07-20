---
id: superFluxOnset
title: SuperFlux Onset Detection
---
**What it does.** Replaces the baseline spectral-flux onset reference (the previous frame's log-mel spectrum) with a frequency-neighborhood maximum across a small band of mel bins before differencing, following the SuperFlux method. The widened reference is designed to suppress vibrato and pitch-modulation false onsets on pitched instruments, so that only genuine note attacks register. It adds one extra windowed-maximum pass per frame at the onset stage, a few percent of that step's cost.

**When to pick it.** Consider it experimentally on pitched, melodic, or heavily vibrato'd material where the baseline onset detector is firing on pitch modulation rather than true attacks, the case the method was designed for. It ships available for consumer experimentation and can be layered onto _optimal_ explicitly. Enable it when you have such material and can benchmark it yourself, since its value is narrow and depends heavily on the onset characteristics of the corpus.

**Tradeoff.** On the library's own corpus this technique is a net negative and is deliberately shipped inert: it changes per-track output across the internal evaluation corpus yet resolves none of the targeted drum-and-bass triplet failures, regresses otherwise-correct control tracks, and lowered primary accuracy when added on top of _optimal_. It is therefore excluded from every production preset. The frequency-neighborhood maximum that suppresses vibrato also smears genuine closely-spaced onsets together, so on dense percussive material it can merge distinct attacks and weaken the transient detail the tempo estimator depends on.
