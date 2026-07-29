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

> **2026-07-26 (GH-166): the caveat below was right and the measurement is now in.**
> The 401 oracle ceiling was never approachable by a posterior decode -- #141 measured
> every threshold as net negative. See the STATUS CORRECTION under "The plan" below.
> The Acc2 = 401 figure itself remains a correct octave-tolerant re-score of the E0 run;
> what is false is treating the gap to 348 as recoverable HEADROOM.

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

  > **CORRECTION 2026-07-26 (GH-166 / #146): the "hard cross-entropy" premise in the
  > bullet above is FALSE for the authoritative v2 path.**
  > `ablation/octave_aware_loss.py:42,77` sets `OCTAVE_FACTORS = (2.0, 0.5)` and
  > `octave_mass = 0.15`, and `train.py` v2 mode routes through it
  > (`train_v2.run_v2` -> `ablation_train.finetune`); only the legacy v1 supervised
  > path uses plain `F.cross_entropy`. So the loss DID give octave partial credit.
  >
  > **Where that mass lands is tempo-dependent, and the naive reading is wrong.**
  > `octave_partner_bins` (`:56-71`) DROPS any partner whose BPM falls outside
  > [30, 285] before splitting (DD #2, to avoid a clamp-to-boundary smear). So the
  > 0.15 splits ~0.075 / ~0.075 onto {2T, T/2} only for roughly **60 <= T <= 142**.
  > Above ~142 BPM the 2T partner is out of range and the FULL 0.15 goes to the
  > HALF -- i.e. in the DnB band (174 BPM) the loss rewards the *fundamental*, not
  > the doubling. Below ~60 the reverse holds. The "loss rewards the 2x mode"
  > shorthand is therefore true for the 100-142 band and FALSE for the fast band;
  > do not carry it as a blanket claim.
  >
  > Provenance caveat: `model_metadata.json` for the v2 runs records no loss fields
  > and no `octave_mass`, so "all three retrains used 0.15" is INFERRED from the
  > `--octave-mass` default, not read off run artifacts. That gap is itself worth
  > fixing before the next retrain.
  >
  > What IS unambiguously absent is ordinal structure: a 1-bin miss and a 100-bin
  > miss are penalized identically.
- **Deployment reality: octave decode is free on-device; MoE is not.** Genre-MoE = a
  new genre classifier (router-error failure mode) + N BNNSGraph loads + re-bundling
  weights (reverses Story 4-6 Branch C) + likely a CoreML/ANE migration off the
  CPU-only BNNS path. MoE is a research-corpus win that is expensive exactly at the
  deployment boundary. (Siri)

## The plan (evidence-ordered, cheapest-first; MoE is the last resort)

> **STATUS CORRECTION 2026-07-26 (GH-166, `spec-gh-166-epic12-lever-sequencing.md`).**
> **E1 below was implemented, measured, and removed. It does not work.** Measured over
> all 661 GiantSteps tracks against `giantsteps_v2_seed_42` (#141, PRs #177/#179;
> `_bmad-output/implementation-artifacts/141-octave-fold-impact.json`): **every threshold
> from 0.0 to 1.0 is net negative on Acc1**, best -2, reached by folding almost nothing.
> At threshold 0.0 the rule fires on **604 of 661 tracks**: 38 helpful (exactly the
> sub-100 recoveries predicted below -- the mechanism works), 346 harmful, and 220
> accuracy-neutral, netting **-308**. No threshold separates helpful from harmful:
> helpful folds (n=38) median mass ratio 0.199 (range 0.037-0.745), harmful folds
> (n=346) median 0.192 (range 0.014-1.700) -- the helpful range sits ENTIRELY INSIDE
> the harmful range, so no single cut on this statistic can isolate the good folds.
> The model is *confidently* wrong on
> exactly the tracks needing a fold, so the information the rule needs is **absent from
> the posterior** -- which is what the Codex caveat above meant by "cannot be replayed
> offline". The "Expected: 348 -> ~401" line below is therefore **measured false**; 401
> was an oracle ceiling, never an achievable target.
>
> The same conclusion was reached independently on the DSP side: four demote-to-fundamental
> variants of `resolveOctaveAmbiguity` were measured on 2026-06-28 and all reverted (OA300
> Acc1 58 -> 40 / 39 / 54 / 56). **Both cheap octave levers are now measured and failed.**
> Any surviving octave lever must source its evidence from OUTSIDE the signal that produced
> the candidate. The corrected ranking lives in the Epic 12 charter (`epics.md`); this
> document is retained as the E0 diagnostic record, which stands unchanged.

**E1 — octave-aware decode, NO retrain (free, this is the immediate win).** [SUPERSEDED -- see the status correction above]
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

**E4 — only if E2-E3 plateau** (was "E1-E3"; E1 is removed, see the 2026-07-26 status
correction above, so it can never plateau)**:** widen the model before routing it; a tempo-range
ensemble (octave arbiter over the existing model) before a genre-MoE. Genre-MoE is
last and triggers the CoreML/ANE + re-bundling release decision (CLAUDE.md level).

## Open research item (verify the ruler)
Check whether GiantSteps' OWN sub-120 annotations are octave-clean. If the benchmark
labels are themselves octave-ambiguous, part of the 348/661 ceiling is the ruler,
not the model (Mary). Pull Schreiber & Müller + Bock before E2/E3.
