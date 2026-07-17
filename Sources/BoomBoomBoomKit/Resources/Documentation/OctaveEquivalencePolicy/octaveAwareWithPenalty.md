---
id: octaveAwareWithPenalty
title: Octave-Aware with Penalty
---
**What it does.** Treats octave-related votes as agreeing — a signal calling the double or half of another is counted as corroboration — but applies a confidence penalty to the non-fundamental candidate, so the fundamental is preferred without discarding the octave evidence entirely. It is the default octave-equivalence policy and mirrors the library's existing corroboration behavior, where octave-related tags corroborate under _MetadataPolicy_. It is the balanced middle stance between collapsing octaves outright and refusing them as agreement.

**When to pick it.** Use it — or leave it as the default — when octave relationships are informative but you still want the true fundamental to win: the octave vote counts, but it does not override a direct match. It is the right general-purpose choice for tempo estimation where half and double confusions are common but you do not want to erase the distinction. It is currently a reserved knob: the selection signature accepts it, but octave behavior is governed by _MetadataPolicy_, so the three policies are not yet distinct in practice.

**Tradeoff.** The confidence penalty is a fixed heuristic, so it can misfire in both directions: too small a penalty lets a spurious octave vote drag the result off the true tempo, while too large a penalty discards genuine octave corroboration that would have confirmed the fundamental. On a track whose true tempo really is the higher octave, penalizing the non-fundamental biases toward the wrong, lower value. And because the policy is reserved today, this nuanced behavior is latent — the shipped octave handling still flows through _MetadataPolicy_ rather than this knob.
