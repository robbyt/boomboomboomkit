---
id: average
title: Cluster Mean Score
---
**What it does.** Builds 2 percent BPM clusters from all windows' candidates and scores each cluster by the arithmetic mean of the per-window scores inside it, then ranks clusters by that mean. A tempo that appears across several windows with moderate, steady scores can therefore beat a tempo that spikes once and is weak elsewhere. The reported BPM is the representative of the highest-mean cluster; the full ranked cluster list is returned up to the candidate cap.

**When to pick it.** Use it when consistency of strength should matter more than a single peak. A tempo that scores moderately but steadily across windows is often more reliable than one that scores high once and is absent otherwise. It is a middle ground between _dedup_, which takes the maximum, and _quorum_, which is a headcount: the score magnitude still counts, but it is smoothed across every contributing window rather than reduced to the single best reading.

**Tradeoff.** Averaging is sensitive to outlier windows in both directions. One window that scores a cluster low drags the mean down and can sink a genuinely correct tempo below a mediocre-but-uniform distractor; conversely a single inflated score can lift a weak cluster into the lead. On files with one bad window (a stretch of near-silence, a breakdown, or a tempo change) the mean is a poor summary and the wrong cluster wins. When outlier robustness matters, _median_ computes the same clusters but resists exactly this failure.
