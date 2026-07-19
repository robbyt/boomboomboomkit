---
id: adaptiveThreshold
title: Onset Running-Mean Subtraction
---
**What it does.** Subtracts a running mean from the onset envelope over a roughly 500-millisecond window, removing slow energy trends so that only genuine transient onsets survive into the periodicity analysis. It is a single convolution pass that acts as a high-pass filter on the onset-strength signal, flattening gradual swells and leaving sharp attacks. The intent is to stop sustained energy from masquerading as rhythmic content before autocorrelation ever sees it.

**When to pick it.** Enable it on material with heavy sustained energy (pads, drones, thick sustained bass) where slow amplitude trends would otherwise inflate the onset envelope and blur the beat. It shares its design rationale with _dnbOptimized_ and can help on genres outside the tuning corpus where transient separation is the bottleneck. Use it when non-transient energy is contaminating onset detection.

**Tradeoff.** On the OA300 corpus this technique measurably _hurts_, costing two tracks, because aggressive trend removal also strips low-frequency rhythmic energy that carries the beat on drum-and-bass material: the running-mean subtraction cannot tell a sustained bassline that is on the grid from a sustained pad that is not. It is therefore excluded from the default _optimal_ preset and should be enabled only after benchmarking a specific corpus, since on the library's primary material it removes signal the tempo estimator needs rather than the noise it was meant to suppress.
