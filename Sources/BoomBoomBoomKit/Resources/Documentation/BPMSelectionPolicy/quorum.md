---
id: quorum
title: Window-Quorum Voting
---
**What it does.** Groups all candidates into 2 percent BPM clusters, then ranks those clusters primarily by how many distinct windows contributed to each one, breaking ties by the best score inside the cluster. The tempo that the most windows independently landed on wins, regardless of whether any single window scored it highest. It turns the merge from a score contest into a headcount: breadth of agreement across windows is the primary signal, and raw peak strength is only the tiebreaker.

**When to pick it.** Choose it when you have several windows and you trust consensus over peak loudness: the case where a track's true tempo shows up modestly but repeatedly across windows while a distractor spikes strongly in only one. It addresses _maxConfidence_'s over-confident-outlier failure, and it is most reliable on longer files where progressive analysis yields three or more windows to vote. The more windows available, the more reliable the quorum signal becomes.

**Tradeoff.** Quorum needs genuine breadth to work, and it fails when windows are few or systematically biased. With only two windows a tie is common and the strategy degenerates toward score-based selection. Worse, if a consistent artifact (a strong half-tempo pulse present in every window) makes the whole corpus agree on the wrong tempo, quorum will confidently elect that shared error, because unanimous agreement on a distractor outscores a correct tempo that only one window recovered. It trusts the crowd, so a correlated bias fools the whole crowd at once.
