---
id: subBandVoting
title: Sub-Band Octave Voting
---
**What it does.** Computes separate autocorrelations for distinct frequency sub-bands (kick, snare, crack, and hi-hat regions) and has them vote on half-versus-double tempo, resolving octave ambiguity by cross-band agreement. Different drums pulse at different metrical levels, so pooling their independent periodicity votes recovers the true beat where a single full-spectrum ACF would lock onto a harmonic. It is a core baseline technique and part of the _optimal_ preset, central to the library's octave resolution.

**When to pick it.** Keep it enabled in essentially every configuration: octave errors, reporting half or double the true tempo, are the dominant failure mode for tempo estimation, and sub-band voting is the library's primary defense against them. It is most effective on drum-driven genres where kick and hat patterns disagree about the pulse in a way that pins down the correct level. As part of the baseline and _optimal_ presets it is a default, not an opt-in.

**Tradeoff.** The voting assumes the sub-bands carry separable drum voices, and it fails when they do not: on material without a conventional kick/snare/hat structure, or where one sound spans several bands, the per-band ACFs can agree on the wrong level and cast a confident but incorrect octave vote. Because the technique adds four extra autocorrelation computations plus sub-band onset extraction, it is also the more expensive baseline stage, and on sparse or ambiguous rhythms it can entrench an octave error that a full-spectrum reading would have left visibly uncertain.
