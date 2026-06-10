# v2 model: why it fails, what E0 proved, and the plan to fix it

Develop-only audit artifact (Epic 7 follow-on). Consolidates the three-retrain
calibration ladder, the decisive E0 per-band Acc1-vs-Acc2 diagnostic, and the
evidence-ordered remediation plan from the 2026-06-09 roundtable.

## The honest status
The v2 model is NOT ship-quality. Both bundle gates fail and three retrains
proved the failure is structural, not a labeling-volume problem. "BYOW" was a
euphemism for "the model doesn't work yet." It stays unbundled because it is not
good enough, not as a design choice.

## Calibration ladder (Acc1 = |pred-truth|/truth <= 0.04, .mlOnly, seed 42)
| corpus     | baseline       | +90 rebal      | +190 rebal     | gate         |
|------------|----------------|----------------|----------------|--------------|
| OA300      | 50/82 (61.0%)  | 48/82 (58.5%)  | 43/82 (52.4%)  | >55/82  FAIL |
| GiantSteps | 296/661 (44.8%)| 330/661 (49.9%)| 348/661 (52.6%)| >=537   FAIL |

Adding hand-labels improves the FED band (120-140: 113->145->177) but regresses
neighbors (140-160 -16) and drags OA300 BELOW baseline. Fixed-capacity band trade.

## E0 — the decisive diagnostic (zero compute, re-score of +190 predictions)
GiantSteps per band, Acc1 (exact) vs Acc2 (octave-tolerant), + octave direction:

| band     | n   | Acc1        | Acc2        | pred = 2x truth | reading                     |
|----------|-----|-------------|-------------|-----------------|-----------------------------|
| <100     | 60  | 1/60  (2%)  | 39/60 (65%) | **38**          | clean OCTAVE-DOUBLING        |
| 100-120  | 35  | 1/35  (3%)  | 1/35  (3%)  | 0               | **GENUINELY wrong** (mis-pulsed) |
| 120-140  | 309 | 177/309(57%)| 180/309(58%)| 0               | mostly correct               |
| 140-160  | 88  | 40/88 (45%) | 47/88 (53%) | 0               | a few octave errors          |
| 160-175  | 153 | 129/153(84%)| 133/153(87%)| 0               | strong                       |
| 175+     | 16  | 0/16  (0%)  | 1/16  (6%)  | 0               | tiny band                    |
| TOTAL    | 661 | 348 (53%)   | 401 (61%)   |                 |                              |

### Two diseases were hiding under "sub-120 is dead"
1. **<100 BPM = clean octave-doubling.** 38/60 predict EXACTLY 2x truth. The pulse
   IS found; the perceptual octave is wrong. Acc2 jumps 2% -> 65%. A DECODE-only
   fix (no retrain) recovers most of these.
2. **100-120 BPM = genuinely wrong.** Acc2 == Acc1 == 1/35. Neither half nor double
   lands. Octave-folding does nothing. This band is mis-pulsed and needs the
   representation / training fix, not decode.

### The ceiling, precisely
- Perfect octave decode caps at **Acc2 = 401/661 (61%)** — i.e. up to **+53 tracks of
  octave-confusion HEADROOM** over 348. CAVEAT (Codex review 2026-06-09): 401 is an
  *oracle* ceiling (truth-aware octave equivalence). It is NOT a guaranteed decode
  recovery — and it cannot be replayed offline from the current dumps, which carry
  only decoded BPM + `softmaxMax`, not the full 256-bin posterior. Actual no-retrain
  recovery must be MEASURED with full-posterior dumps + DSP arbitration, and gated on
  per-band NET impact (a "prefer fundamental" rule can damage the correct 120-175 bands).
- The gate is 537 (81%). So **+136 beyond octave-perfect is genuine error** that
  decode cannot touch. That residual is the representation/training problem.

## Root-cause consensus (roundtable, 2026-06-09)
- **Fixed [1,1,128,512] input is the prime suspect for the genuine errors** — but for
  tempo-scale invariance + corpus-prior leakage, NOT a frame-rate "smear." CORRECTION
  (Codex review 2026-06-09): the naive frame-rate argument is backwards. At ~5.7 fps a
  60-BPM track gets ~5.7 frames/beat while a 174-BPM track gets ~2 — so *fast* tempo is
  nearer temporal Nyquist, not slow. The slow-tempo failure is the model learning the
  DnB-dominant metrical level as a prior (the representation is sharp where the corpus
  lives), not the resample destroying slow periodicity. Original (Winston) framing
  retained for the record but superseded by this correction.
- **The octave bias is a DnB-prior + loss-shape problem.** 256-bin hard cross-entropy
  gives no partial credit for octave errors and no reason to prefer the fundamental;
  a fast-music corpus teaches "when in doubt, fast." Well-documented in MIR
  (Schreiber & Müller TempoCNN papers; Bock RNN+comb-filter; Acc1/Acc2 convention
  exists BECAUSE octave confusion is endemic). (Mary)
- **Deployment reality: octave decode is free on-device; MoE is not.** Genre-MoE = a
  new genre classifier (router-error failure mode) + N BNNSGraph loads + re-bundling
  weights (reverses Story 4-6 Branch C) + likely a CoreML/ANE migration off the
  CPU-only BNNS path. MoE is a research-corpus win that is expensive exactly at the
  deployment boundary. (Siri)

## The plan (evidence-ordered, cheapest-first; MoE is the last resort)
**E1 — octave-aware decode, NO retrain (free, this is the immediate win).**
Replace `bpm = 30 + argmax` with an octave-folded posterior decode (redistribute
2x/half-bin mass, prefer the fundamental when energy supports it). Lives in
`BNNSTechnique.decode(_:)` + Python mirror; lock with a frozen-softmax fixture test
(`BNNSTechniqueTests`). Re-measure. Expected: 348 -> ~401 GiantSteps, fixes the
"calls a 70-BPM track 140" embarrassment. Also wire `OctaveEquivalencePolicy` /
DSP `resolveOctaveAmbiguity` evidence as the octave arbiter (DSP already finds the
period robustly; let ML/DSP fuse via the existing SignalPool, currently idle at
`.dspOnly`).

**E2 — representation fix (the genuine-error residual + 100-120 band).**
Stop resampling time to a fixed frame count. Either tempo-invariant hop (fixed
seconds/frame, pad/crop) or a log-lag autocorrelation / tempogram input where 60
and 120 BPM are equidistant bins. Bump `featureSetVersion`; the Swift runtime
substrate MUST move in lockstep with Python training (FNV parity tripwire is
non-negotiable). Retrain the same CNN. This is the high-value redesign the operator's
"redesign what segments we scan" instinct was pointing at — NOT MoE.

**E3 — octave-aware training target + tempo-class rebalance.**
Soft/Gaussian-blurred target around the true bin (adjacent tempi share gradient);
explicit octave-aware loss penalizing 2x/0.5x less than random; oversample sub-120
so it isn't a rounding error in the loss. Stack on E2.

**E4 — only if E1-E3 plateau:** widen the model before routing it; a tempo-range
ensemble (octave arbiter over the existing model) before a genre-MoE. Genre-MoE is
last and triggers the CoreML/ANE + re-bundling release decision (CLAUDE.md level).

## Open research item (verify the ruler)
Check whether GiantSteps' OWN sub-120 annotations are octave-clean. If the benchmark
labels are themselves octave-ambiguous, part of the 348/661 ceiling is the ruler,
not the model (Mary). Pull Schreiber & Müller + Bock before E2/E3.
