---
id: windowVoting
title: Post-Disambiguation Window Vote
---
**What it does.** Votes on each region's _final, disambiguated_ BPM rather than on raw candidates. This is the default merge strategy with rhythmic-region selection and _VotingPolicy.simpleMajority_. After each region runs the full pipeline, the strategy clusters the finished answers with a 2 percent tolerance. If two or more regions agree, it returns the consensus tempo; otherwise it falls back to _maxConfidence_. Other voting policies are available explicitly.

**When to pick it.** Choose it when each window is individually competent at picking a tempo and you want their finished verdicts reconciled, rather than re-litigating raw candidates that predate disambiguation. It is the consensus strategy closest to the pipeline's final decisions: a window's vote is its actual output, so agreement means the pipeline reached the same conclusion independently more than once. It suits longer files that yield several windows and _VotingPolicy.thresholdGated_ when you want to reject low-confidence consensus.

**Tradeoff.** Voting on post-disambiguation answers means a disambiguation mistake is carried into the vote: if the octave logic pulls two windows to the same wrong tempo, _windowVoting_ confidently ratifies that shared error instead of exposing the raw candidates that might have revealed the fundamental. And with only one window, or with every window disagreeing, it silently degrades to _maxConfidence_ and inherits that strategy's over-confident-outlier failure, so on short or noisy files it offers no consensus benefit at all despite the added machinery.
