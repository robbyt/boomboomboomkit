---
id: expandedCandidates
title: Expanded Candidate Extraction
---
**What it does.** Extracts five tempo candidates from the periodicity spectrum instead of the usual three, and correspondingly raises the candidate count carried through the rest of the pipeline. It gives octave disambiguation and the merge strategies a wider field of hypotheses to choose from, on the theory that the correct tempo is more likely to appear somewhere in a longer list. The extra work is only two additional peak selections, so the cost is negligible.

**When to pick it.** Pick it when the true tempo is being missed at the extraction step, when it sits barely outside the top three peaks and never gets a chance to compete in disambiguation or voting. It can help on spectrally complex material where several plausible periodicities coexist and the correct one is present but not dominant. It is most defensible when paired with a merge strategy that can exploit the extra alternates rather than only the winner.

**Tradeoff.** On the OA300 corpus adding candidates _reduces_ accuracy by three tracks, because the extra hypotheses are usually harmonically related distractors (half, double, and triplet relatives of the true tempo) that give octave disambiguation more ways to go wrong rather than more chances to be right. A longer candidate list dilutes the signal with confusable neighbors, so the disambiguation logic that was choosing correctly among three plausible tempos now mis-selects among five. It is excluded from every production preset for this reason.
