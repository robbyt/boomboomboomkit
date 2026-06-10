# FR-18 calibration: 90 hand-labels + tempo-band rebalance (seed 42)

Model: maskedMelPretrain seed 42, featureSetVersion v2, tempoBandRebalanced=true,
trained on the 90-hand-label-augmented corpus (val_acc1 best 0.703).
Compared against the pre-augmentation baseline (/tmp/fr18-baseline-seed42, 296/661).

## Gate totals (Acc1 = |pred-truth|/truth <= 0.04, .mlOnly)
| corpus     | baseline      | new (90+rebal) | delta | gate         |
|------------|---------------|----------------|-------|--------------|
| OA300      | 50/82 (61.0%) | 48/82 (58.5%)  | -2    | >55/82  FAIL |
| GiantSteps | 296/661 (44.8%)| 330/661 (49.9%)| +34   | >=537   FAIL |

## GiantSteps per-band Acc1
| band     | baseline       | new            | delta | labels added |
|----------|----------------|----------------|-------|--------------|
| <100     | 1/60  (1.7%)   | 1/60  (1.7%)   | 0     | +18 (no move)|
| 100-120  | 1/35  (2.9%)   | 1/35  (2.9%)   | 0     | +8  (no move)|
| 120-140  | 113/309 (36.6%)| 145/309 (46.9%)| +32   | +22 (works!) |
| 140-160  | 55/88 (62.5%)  | 56/88 (63.6%)  | +1    | +7           |
| 160-175  | 125/153 (81.7%)| 125/153 (81.7%)| 0     | +1 (saturated)|
| 175+     | 1/16  (6.2%)   | 2/16  (12.5%)  | +1    | +1           |

## Key diagnostic: sub-120 is an OCTAVE problem, not data-absence
Sub-120 GiantSteps (n=95): mean truth 94 BPM, mean PRED 156 (baseline) -> 147 (new).
The DnB-trained model predicts ~1.6x the true tempo on slow tracks. ~40% land at
exactly 2x truth (doubled 33 -> 39). 26 new sub-120 labels barely moved Acc1
(still 2/95 exact) — they only nudged the octave count. The 120-140 band responds
to data+rebalance; the sub-120 bands are octave-biased and move slowly.

## Verdict
Still fails both bundle gates by a wide margin (+34 GiantSteps, need +207 more;
OA300 down 2, within single-seed noise). Calibration confirms: (a) data+rebalance
WORKS in the band it's fed (120-140: +32 from +22 labels), (b) the sub-120 dead
zone is an octave-doubling bias that data alone moves slowly. Stays BYOW.
