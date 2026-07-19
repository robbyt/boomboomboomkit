---
id: median
title: Cluster Median Score
---
**What it does.** Forms the same 2 percent BPM clusters as the other clustered strategies, then scores each cluster by the _median_ of its per-window scores rather than the mean. The middle value sets the rank, so a cluster's standing reflects its typical strength across windows and does not track how extreme any single window was. The highest-median cluster becomes the reported BPM, and the ranked list is returned up to the candidate cap.

**When to pick it.** Pick it when windows are uneven, with some clean and some corrupted by breakdowns, silence, or transient noise, and the merge should discount the unreliable ones. The median resists outliers where _average_ does not: a single unusually high or unusually low window score cannot move the rank, so a tempo that stays mid-strength across most windows holds its position. It fits files whose structure guarantees that at least a few windows are unreliable when there is no way to know in advance which ones.

**Tradeoff.** The median discards magnitude information, and with too few windows it barely differs from picking a middle value at random. With two windows the median equals their average; with three it is a single window's score, so a high-confidence reading is discarded in favor of the middle one. On short files that yield only one or two windows the promised outlier resistance never engages, and the result can underperform the simpler score-based strategies while appearing more rigorous than the window count justifies.
