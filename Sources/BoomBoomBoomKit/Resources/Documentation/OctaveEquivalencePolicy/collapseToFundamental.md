---
id: collapseToFundamental
title: Collapse to Fundamental
---
**What it does.** Treats a tempo, its double, and its half as the same value, folding octave-related votes onto the single fundamental before the unified signal pool selects a winner. Where two signal families disagree only by an octave (one calling 87 BPM, another 174), this policy merges them into agreement on the fundamental rather than treating them as rivals. It is the most aggressive of the three octave-equivalence stances: octave relationships are not treated as distinctions.

**When to pick it.** Choose it when octave is not meaningful for the use case, such as a tag or search index that only needs a tempo class, or a corpus where over-merging is preferable to letting half and double splits fragment agreement. It maximizes cross-signal consensus by refusing to let an octave difference block agreement. This policy is currently a reserved, configurable-but-inert setting: the selection signature accepts it, but octave behavior is still governed by _MetadataPolicy_, so choosing it does not yet change results.

**Tradeoff.** Collapsing octaves discards a real distinction many consumers need: a DJ syncing decks cares whether a track is 87 or 174 BPM, and this policy erases that, so it is wrong for any beat-accurate application. By folding double and half onto the fundamental it can also pick the wrong octave as the fundamental when the true tempo genuinely is the higher one, silently halving a fast track's reported tempo. Because it is reserved today that behavior is latent rather than active, and it remains the stance most prone to merging tempos that should have stayed distinct.
