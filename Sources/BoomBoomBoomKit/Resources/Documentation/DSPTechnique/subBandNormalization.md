---
id: subBandNormalization
title: Per-Sub-Band Onset Normalization
---
**What it does.** Normalizes each mel sub-band's onset envelope by its own maximum before the bands are summed into the combined envelope, so no single loud frequency band dominates the rhythmic signal. Kick, snare, and higher bands each contribute on a comparable scale rather than in proportion to raw energy. It is a handful of cheap vector operations per band and reshapes the balance of the onset envelope without changing which frames contain onsets.

**When to pick it.** Use it when one frequency band is masking rhythmically important onsets in others, such as a loud kick covering snare and hat patterns, so that the combined envelope reflects the full rhythmic picture rather than only the loudest drum. It is part of the _dnbOptimized_ preset, where balancing sub-bands helps on bass-heavy material, and it is a reasonable addition whenever spectral balance rather than transient timing is the limiting factor.

**Tradeoff.** On the internal evaluation corpus the technique is neutral, changing no track's outcome relative to baseline, so it adds computation without a measured accuracy gain on the library's primary material, and enabling it is a bet that a given corpus differs from the tuning set. Normalization can also amplify noise in quiet bands: a sub-band with no real rhythmic content but a small spurious peak gets scaled up to full weight, letting incidental high-frequency hiss contribute to the onset envelope as if it were a genuine, evenly-matched drum voice.
