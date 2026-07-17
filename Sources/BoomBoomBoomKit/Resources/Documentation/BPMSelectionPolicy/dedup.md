---
id: dedup
title: Deduplicated Candidate Pool
---
**What it does.** Collects every candidate from every window into one pool, then collapses near-duplicates — any two BPMs within 2 percent of each other are treated as the same tempo — keeping the highest score in each cluster and re-ranking the survivors by score. The output is a clean, de-noised candidate list capped at the configured candidate count, with the top-scoring cluster becoming the reported BPM. It is the gentlest of the clustering strategies: it merges obvious repeats but otherwise lets raw score decide.

**When to pick it.** Use it when several windows keep surfacing the same handful of tempos with slight numerical jitter and you want that jitter folded away without changing which tempo wins. It is a good first step up from _maxConfidence_ when the candidate lists are noisy but broadly consistent, and it preserves the full ranked list — not just the winner — so downstream consumers can inspect alternates. Because scoring stays score-based rather than vote-based, it keeps behavior close to the single-window baseline while removing duplicate clutter.

**Tradeoff.** Deduplication rewards the single loudest occurrence of a tempo, not how many windows agree on it, so it inherits _maxConfidence_'s core weakness: one window that scores an octave-doubled tempo very highly still wins even when more windows quietly favor the fundamental. The 2 percent clustering tolerance can also mis-merge two genuinely distinct tempos that happen to sit close together — a 174 and a 177 BPM reading collapse into one cluster and the loser's evidence vanishes. On tracks with real tempo drift this silent merge produces a confident answer that represents neither section well.
