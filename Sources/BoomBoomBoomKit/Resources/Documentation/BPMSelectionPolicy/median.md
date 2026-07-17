---
id: median
title: Cluster Median Score
---
**What it does.** Forms the same 2 percent BPM clusters as the other clustered strategies, but scores each cluster by the _median_ of its per-window scores rather than the mean. The middle value wins, so a cluster's ranking reflects its typical strength across windows and ignores how extreme any single window happened to be. The highest-median cluster becomes the reported BPM, with the ranked list returned up to the candidate cap.

**When to pick it.** Pick it when your windows are uneven — some clean, some corrupted by breakdowns, silence, or transient noise — and you want the merge to shrug off the bad ones. The median is the outlier-resistant sibling of _average_: a single wildly high or wildly low window score cannot move the ranking, so a tempo that is consistently mid-strength across most windows holds its position. It is the strongest choice when file structure guarantees that at least a few windows are unreliable and you cannot know in advance which.

**Tradeoff.** Median throws away magnitude information, and with too few windows it barely differs from picking a middle value at random. With two windows the median is just their average; with three it is a single window's score, so a genuinely informative high-confidence reading is discarded in favor of the middle one. On short files that yield only one or two windows the outlier resistance it promises never engages, and it can underperform the simpler score-based strategies while appearing more principled than it actually is.
