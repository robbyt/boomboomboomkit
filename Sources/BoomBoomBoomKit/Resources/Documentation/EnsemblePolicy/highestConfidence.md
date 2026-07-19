---
id: highestConfidence
title: Higher-Confidence Voice
---
**What it does.** Compares the DSP and ML self-reported confidences and returns whichever is higher, breaking ties deterministically toward DSP. When the model abstains with a nil evaluation, DSP wins unconditionally. There is no random element: identical inputs always yield the same winner, and the outcome is recorded in the trace as a DSP win, an ML win, or a tie. It arbitrates between the two voices with no weighting and no pooling, taking only the more confident source.

**When to pick it.** Use it when both voices report confidence on a comparable, trustworthy scale and you want the more certain one to decide each track. It is a lightweight ensemble that needs no weight tuning, suitable when you want ML to influence results but only when it is more confident than DSP, a conservative way to add a model without letting it dominate. It sits between _dspOnly_ and _mlOnly_: ML can win, but only by being more certain.

**Tradeoff.** Raw confidence comparison is only fair if the two sources are calibrated alike, and they usually are not. Metadata corroboration can push DSP confidence to the 0.95 ceiling before the comparison even happens, biasing the outcome toward DSP on any tag-corroborated track regardless of which voice is correct. Symmetrically, an over-confident model wins on tracks where it is wrong. Because the policy never inspects _why_ a voice is confident, a systematic calibration gap between DSP and ML quietly decides a whole class of tracks in one direction.
