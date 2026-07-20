---
id: octaveAwareWithPenalty
title: Octave-Aware with Penalty
---
**What it does.** Treats octave-related votes as agreeing (a signal calling the double or half of another is counted as corroboration) but applies a confidence penalty to the non-fundamental candidate, so the fundamental is preferred without discarding the octave evidence entirely. It is the default octave-equivalence policy and mirrors the library's existing corroboration behavior, where octave-related tags corroborate under _MetadataPolicy_. It is the middle stance between collapsing octaves outright and refusing them as agreement.

**When to pick it.** Use it, or leave it as the default, when octave relationships are informative but the true fundamental should still win: the octave vote counts, but it does not override a direct match. It is the general-purpose choice for tempo estimation where half and double confusions are common but the distinction should not be erased. It is currently a reserved setting: the selection signature accepts it, but octave behavior is governed by _MetadataPolicy_, so the three policies are not yet distinct in practice.

**Tradeoff.** The confidence penalty is a fixed heuristic, so it can misfire in both directions: too small a penalty lets a spurious octave vote drag the result off the true tempo, while too large a penalty discards genuine octave corroboration that would have confirmed the fundamental. On a track whose true tempo is the higher octave, penalizing the non-fundamental biases toward the wrong, lower value. Because the policy is reserved today, this behavior is latent, and the shipped octave handling still flows through _MetadataPolicy_ rather than this setting.
