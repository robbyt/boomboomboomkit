---
id: weightedAverage
title: Confidence-Weighted Cluster Mean
---
**What it does.** Clusters candidates by 2 percent BPM tolerance like the other clustered strategies, then scores each cluster by a confidence-weighted mean of its per-window scores: each contributing window's score is weighted by that window's overall confidence before averaging. High-confidence windows pull the cluster score toward their reading; low-confidence windows contribute little. The highest-weighted-mean cluster is reported, blending _how strong_ a tempo looked with _how much the library trusted the window that saw it_.

**When to pick it.** Use it when window confidence is a meaningful, well-calibrated signal in your corpus and you want it to shape the blend rather than act only as a final tiebreak. It is the most information-rich of the averaging strategies: where _average_ treats every window equally and _quorum_ counts heads, _weightedAverage_ lets a genuinely trustworthy window carry proportionally more of the decision while still pooling evidence across all of them.

**Tradeoff.** Its quality depends entirely on the confidence calibration, and mis-calibrated confidence quietly corrupts the whole blend. If the pipeline systematically over-reports confidence on a spurious tempo (as it can on octave-doubled drum-and-bass pulses) that inflated weight compounds the error instead of averaging it out, producing a confident wrong answer that the unweighted _average_ would have diluted. When a cluster's total weight is zero the score collapses to zero and the cluster effectively drops out, so a run of degenerate low-confidence windows can silently discard a real tempo.
