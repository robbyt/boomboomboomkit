---
id: dspOnly
title: DSP-Only Resolution
---
**What it does.** Returns the DSP winner unchanged and never consults the ML technique. When this policy is selected the ML evaluation is short-circuited at the call site: it is both operation-inert (no inference runs) and output-inert (no ML value enters the result), even if an _MLTechnique_ is attached to the options. The returned analysis is byte-identical to the pure DSP pipeline, and the trace's ML branch stays nil. This is the library's default for _Options.ensemblePolicy_, preserving the historical DSP-wins behavior exactly.

**When to pick it.** Use it whenever you want deterministic DSP results with zero ML involvement: as the safe default, as a performance choice that skips inference entirely, or as the control arm when measuring what an ML technique adds. It is the only policy guaranteed not to run the model, so it is also the right choice when an ML technique is present in the options for other reasons but you want it dormant for this analysis.

**Tradeoff.** Ignoring ML means you forgo whatever accuracy a model could contribute: on genres or edge cases where DSP is weak and a trained model would recover the tempo, _dspOnly_ ships the DSP mistake with no second opinion. The byte-identity guarantee is a feature for reproducibility but a ceiling on quality: this policy can never be more accurate than DSP alone, so tracks the DSP pipeline mis-pulses (octave errors, triplet-feel confusions) stay wrong exactly as they were, and the attached model that might have caught them is left unused.
