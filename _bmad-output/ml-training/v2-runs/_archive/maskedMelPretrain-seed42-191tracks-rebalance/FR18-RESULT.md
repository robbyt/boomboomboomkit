# FR-18 calibration: 190 hand-labels + tempo-band rebalance (seed 42)

Model: maskedMelPretrain seed 42, featureSetVersion v2, tempoBandRebalanced=true,
trained on the 190-hand-label-augmented corpus (Strong tier 333 -> 523; 100 net-new
tracks over the +90 batch, ~119 of the 190 concentrated in 120-140 BPM).
Best val_acc1 0.648 (down from the +90 run's 0.703 — tony.val itself grew/diversified
108 vs 101; val_acc1 is NOT the bundle gate).

## Gate totals (Acc1 = |pred-truth|/truth <= 0.04, .mlOnly) — the LADDER
| corpus     | baseline       | +90 rebal      | +190 rebal     | gate         |
|------------|----------------|----------------|----------------|--------------|
| OA300      | 50/82 (61.0%)  | 48/82 (58.5%)  | 43/82 (52.4%)  | >55/82  FAIL |
| GiantSteps | 296/661 (44.8%)| 330/661 (49.9%)| 348/661 (52.6%)| >=537   FAIL |

GiantSteps moved +18 (330->348); OA300 moved -5 (48->43, now BELOW baseline too).

## GiantSteps per-band Acc1 — the cannibalization
| band     | +90 rebal      | +190 rebal     | delta | note                          |
|----------|----------------|----------------|-------|-------------------------------|
| <100     | 1/60  (1.7%)   | 1/60  (1.7%)   | 0     | DEAD — octave bias, not data  |
| 100-120  | 1/35  (2.9%)   | 1/35  (2.9%)   | 0     | DEAD — octave bias, not data  |
| 120-140  | 145/309 (46.9%)| 177/309 (57.3%)| +32   | the fed band: monotonic gain  |
| 140-160  | 56/88  (63.6%) | 40/88  (45.5%) | -16   | REGRESSED (prior pulled down) |
| 160-175  | 125/153 (81.7%)| 129/153 (84.3%)| +4    |                               |
| 175+     | 2/16  (12.5%)  | 0/16  (0.0%)   | -2    | REGRESSED                     |

## Verdict: diminishing, cannibalizing returns + a hard structural ceiling
1. The 120-140 band keeps responding cleanly to data+rebalance: 113 -> 145 -> 177
   (36.6% -> 46.9% -> 57.3%) across baseline/+90/+190. The lever WORKS in its band.
2. BUT it now costs the neighbors: piling 120-140 data + rebalance pulls the model's
   tempo prior DOWNWARD, regressing 140-160 (-16) and 175+ (-2), and dragging OA300
   below baseline (50 -> 43). We are robbing the fast bands to pay 120-140.
3. sub-120 (<100 + 100-120, 95 GiantSteps tracks ~14%) is STILL 2/95 — flat across all
   three runs. Confirmed: an octave-doubling bias the model has, NOT a data-absence
   problem. 190 diverse labels (36 of them <100) did not move it one track.
4. Ceiling math: even at 120-140=100% + 160-175 held + 140-160 best-case, GiantSteps
   tops out ~500/661 WITHOUT cracking sub-120. 537 is unreachable by 120-140 labeling
   alone — sub-120 (the octave bias) is the binding constraint.

Both bundle gates still FAIL (GiantSteps +189 short; OA300 now 12 short and trending
the wrong way). Stays BYOW. More 120-140 data alone will not pass the gate.
