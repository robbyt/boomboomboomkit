---
id: exactMatchOnly
title: Exact Match Only
---
**What it does.** Requires an exact BPM match within tolerance for two signal families to count as agreeing; octave relationships — half or double — do not qualify. A signal calling 174 BPM and another calling 87 are treated as genuine disagreement, not corroboration. It is the strictest octave-equivalence stance: only signals that already agree on the same octave reinforce each other.

**When to pick it.** Choose it when octave precision is paramount and you would rather see two signals disagree than paper over a real half or double difference — for instance when downstream logic must not confuse a track's fundamental with its double. It is the honest choice when you distrust octave folding and want cross-signal agreement to mean same-octave agreement. Like its siblings it is a reserved knob today: the selection signature accepts it, but the shipped octave behavior is governed by _MetadataPolicy_, so selecting it does not yet change results.

**Tradeoff.** Refusing octave corroboration throws away useful evidence: when two signals genuinely agree on the beat but land on different octaves — a common, benign outcome — this policy scores them as conflicting and can fail to reach a confident consensus that octave-aware handling would have found. On octave-ambiguous material it therefore tends to produce lower-confidence or fragmented results rather than a wrong one, trading missed agreement for strictness. Because it is reserved today, that strictness is latent — the active octave handling still corroborates octaves through _MetadataPolicy_.
