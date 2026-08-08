# Story 12.5: Pipeline differential and cause ranking (FR-57 / FR-58)

Date: 2026-08-08. Analysis only; no code, no re-scoring, no new corpus runs.
Gap instrument: FR-18 strict Acc1 at 4% relative tolerance, no tempo2 fallback,
abstain counts as wrong, 661 GiantSteps rows, revised crowd-sourced annotations
(the 12.4 alignment record). Other protocols appear only as labelled context.

Verdict inherited unchanged from Story 12.4: `gap-attributable-to-our-model`.
Reference 545/661 (82.4%) versus our v2 348/661 (52.6%), a 197-track gap on
identical rows, annotations, and tolerance.

## 1. Per-axis table (ours versus reference)

"Reference" is the Schreiber and Mueller ISMIR 2018 single-step tempo CNN as
run by the 12.4 harness. Every reference training-side fact below traces to the
primary text (citation ledger, section 6). Our-side facts trace to repository
source or measured artifacts.

| Axis | Ours (v2 maskedMelPretrain seed_42) | Reference (2018 CNN) |
|---|---|---|
| Input representation | 44100 Hz mono, FFT 2048, 128 mel bands 30-16000 Hz, whole analysis segment resampled per band to a fixed [1,1,128,512] tensor, per-band z-score (`dataset.py:65-70`, the `SAMPLE_RATE`/`N_FFT`/`N_MELS`/`F_MIN`/`F_MAX`/`TARGET_FRAMES` feature-pipeline constants, and `feature_substrate_v2.py`) | 11025 Hz mono, 1024-sample half-overlapping windows (21.5 Hz frame rate), 40 mel bands 20-5000 Hz, values rescaled to [0,1] per sub-spectrogram (2018 paper, Sections 3.1, 3.3) |
| Window policy | One tensor per track; time axis resampled to 512 frames regardless of segment duration, so frames per second varies per track | Fixed 256-frame (11.9 s) windows at constant frame rate; many windows per track via sliding window, hop 128 (2018 paper, Sections 3.1, 3.4) |
| Bin schema | 256 integer-BPM classes, 30-285 (`dataset.py:59-62`, the `BPM_BIN_MIN`/`BPM_BIN_MAX`/`BPM_BIN_COUNT` constants, and `tools/coreml-convert/reference_arch.py:37-39`) | 256 integer-BPM classes, 30-285 (2018 paper, Section 3.2) |
| Loss | Categorical CE with label smoothing 0.05 plus octave_mass 0.15 split onto in-range partners {2T, T/2} (`ablation/octave_aware_loss.py:42,77`, the `OCTAVE_FACTORS` constant and the `octave_mass` default; PRD 4.3) | Categorical cross-entropy on one-hot targets; no smearing, no octave mass (2018 paper, Section 3.3; PRD 4.3) |
| Augmentation | On-PCM: tempo stretch +-4% (resample-based, pitch co-shifts), gain +-6 dB, pink noise SNR 30-50 dB; one window per track per epoch (`dataset.py:941-996`, `augment_pcm`) | Mel-domain scale-and-crop: time-axis scale factor in {0.8, 0.84, ..., 1.16, 1.2} (spline interpolation, label adjusted), then crop to 256 frames at a random offset, per epoch (2018 paper, Section 3.3, Figure 4) |
| Corpus composition | Tony private corpus v2 splits, DnB-dominant (Tony columns of the PRD 5.3 band table: 160-175 BPM holds 786 tracks against 26 at 100-120, a 30:1 skew; pooled across corpora 980 against 62, but the pool includes the 661-row GiantSteps evaluation set) | Union of LMD Tempo (3,611), MTG Tempo (1,159), EBall (3,826) = 8,596 tracks, 44-216 BPM, multi-genre, mean 121.32, sigma 30.52 (2018 paper, Sections 2.1-2.4, Figure 1) |
| Decode | Single-window argmax, bpm = 30 + argmax; runtime abstains outside 60.0...200.0, so 115 of 256 bins are decode-dead (`BNNSTechnique.swift:885` `bpm = bpmBinOffset + Double(maxIdx)` and `:890` the `60.0...200.0` abstain guard; charter item 2 / #147) | Sliding window hop 128, class-wise averaged softmax activations over the whole track, then argmax; full 30-285 range decodable (2018 paper, Section 3.4) |
| Evaluation protocol | FR-18 strict Acc1 at 4%, 661 rows, revised annotations | Identical by construction: the 12.4 harness scored the reference on the same rows, annotation source, and tolerance |

## 2. Error-structure recomputation (both models, exact)

Recomputed 2026-08-08 with `evaluate_fr18.py` semantics exactly: Acc1 hit =
|pred - truth| / truth <= 0.04; octave-recoverable miss = pred, 2*pred, or
pred/2 within the same tolerance of truth (`evaluate_fr18.octave_match`,
factors 2.0 and 0.5 only, no factor 3). Denominator 661 in all rows.

| Model | Strict hits | Strict misses | Octave-recoverable misses | Residual mis-pulsed |
|---|---|---|---|---|
| Ours (fr18-predictions-191/seed_42) | 348 | 313 | 53 | 260 |
| Reference (tempocnn-baseline) | 545 | 116 | 100 | 16 |

- The 12.4 report's approximations (116/100 reference, "roughly 53" of 313
  ours) are confirmed exactly: 100/116 and 53/313. No divergence.
- **Input-file divergence found and recorded.** The spec's Code Map names
  `fr18-predictions/maskedMelPretrain/seed_42/predictions.json` as "our 348/661
  per-track predictions". That dump scores **330/661** (misses 331, octave-
  recoverable 53, mis-pulsed 278) under the same arithmetic; it is the older
  FR-18 dump. The dump that reproduces the pre-registered 348/661 is
  `fr18-predictions-191/seed_42/predictions.json` (identified by its manifest:
  `giantsteps_v2_seed_42`, checkpoint SHA-256 `09a58dea...`, gitSha
  `be91867-dirty`; the manifests carry no timestamps, so the dumps are
  identified by manifest provenance, not dates), whose giantsteps slice scores
  348/313/53/260 exactly. The 330 figure matches the "+90 rebal" ladder rung in
  `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md`; the -191
  dump is the "+190 rebal" model the
  348 figure was registered against. This artifact uses the -191 dump as the
  our-side row throughout. Both dumps agree the octave-recoverable count is 53.
- Direction detail: of our 53 octave-recoverable misses, 38 predict high
  (the E0 sub-100 doubling cluster); of the reference's 100, only 17 predict
  high, 83 predict half-tempo. The two models fail octave placement in
  opposite directions, consistent with opposite corpus priors.
- Zero GiantSteps ground truths lie outside our 60-200 abstain range, and the
  -191 GiantSteps slice contains zero abstains, so the abstain guard forfeited
  no rows in this run and the decode-dead-bin issue cannot directly forfeit
  any row on this corpus.

Reproduction (no script committed; the recipe is the artifact): filter OUR
dump's rows to `corpus == "giantsteps"` (661 of its 1243 rows; prediction in
`fr18ModelBPM`); take ALL 661 rows under the reference dump's `tracks` key
(they carry no `corpus` field, the dump is all-GiantSteps; prediction in
`modelBPM`). Score prediction versus `groundTruthBPM` with
`evaluate_fr18.acc1_correct` (4% relative tolerance), then apply
`evaluate_fr18.octave_match` (factors 2.0 and 0.5, same tolerance) to the
misses.

**The load-bearing arithmetic.** A perfect truth-aware octave fix on our model
caps at 348 + 53 = 401/661, still 144 tracks short of the reference's 545. The
reference's own residual after the same oracle fix is 16. Octave handling
therefore cannot be the primary cause of the 197-track gap; 260 of our 313
misses are genuinely mis-pulsed, a failure class the reference has almost
eliminated (16). Any credible cause ranking must explain mis-pulsing, not
octave placement. (Consistent with the measured #141 result: the posterior
octave-fold decode was net negative at every threshold, and the 401 ceiling was
never approachable.)

## 3. Axis verdicts

Labels: exactly one of `suspect` / `neutral` / `ruled out` per axis.

### 3.1 Input representation: suspect

Ours resamples the whole analysis segment to a fixed 512-frame tensor, so the
frames-per-second of the input varies with segment duration and the absolute
tempo scale is not preserved in the time axis. The reference keeps a constant
21.5 Hz frame rate, which it states "suffices to represent tempi up to 646 BPM"
(2018 paper, Section 3.1); tempo maps to a fixed periodicity in frames.
Evidence: the 2026-06-09 roundtable names the fixed [1,1,128,512] input the
prime suspect for the genuine (mis-pulsed) errors, via tempo-scale invariance
and corpus-prior leakage, with the naive frame-rate reading explicitly
corrected (`octave-bias-finding-and-plan.md`, Root-cause consensus). The
measured error structure fits: 260/313 of our misses are mis-pulsed (section
2), the failure class the charter says only a representation change plausibly
touches, including the 100-120 band (n=35, Acc1 = Acc2 = 1/35 in E0) that no
octave rule reaches. The mel parameters themselves (128 vs 40 bands, 30-16000
vs 20-5000 Hz) are differences but carry no evidence in either direction;
sub-fact contribution unknown.

### 3.2 Window policy: suspect

Ours presents one tensor per track and gets one vote. The reference scores a
track by averaging class-wise softmax over many 11.9 s windows (hop 128,
Section 3.4), which both fixes the input duration seen at train time equal to
inference time and averages away local noise, no-beat passages, and tempo
drift. Coupled to 3.1 (a constant-frame-rate representation is what makes
fixed-length windows possible), but distinct: even with our representation,
single-crop inference has no aggregation. Evidence is structural (primary text
versus `BNNSTechnique.featurize` single-tensor path) rather than measured; no
repository experiment has isolated aggregation, which is why the raw-audio
evaluation path enabler prices this test. Expected direction is positive but
magnitude unknown.

### 3.3 Bin schema: neutral

Identical by construction on both sides: 256 integer bins, 30-285 BPM
(`dataset.py:59-62` `BPM_BIN_MIN`/`BPM_BIN_MAX` and `reference_arch.py:37-39` versus 2018 paper, Section
3.2 -- our schema copies theirs). The schema itself cannot separate the
systems. The related defect (115 of 256 bins decode-dead under the runtime
60-200 abstain, charter item 2 / #147) is a decode-side interaction and is
assessed under 3.7; its capacity-waste and softmax-dilution effects on training
are real but unmeasured, and they are our-side pathologies of the abstain
guard, not of the shared schema.

### 3.4 Loss: suspect

The reference uses categorical cross-entropy on one-hot targets (2018 paper,
Section 3.3: "As loss function we use categorical cross-entropy"; PRD 4.3
confirms no Gaussian smearing). Ours has never been one-hot: label smoothing
0.05 plus octave_mass 0.15 split onto in-range octave partners, with the
tempo-dependent mass placement defect recorded in
`octave-bias-finding-and-plan.md` (above ~142 BPM the full 0.15 lands on the
half-tempo partner; below ~60 the reverse). So the axis differs, and ours is
the unprecedented side: PRD 4.3 records that no published tempo system places
octave-partner mass in the training target (a PRD-inherited negative existence
claim, not a primary-text-traced fact). What neither loss has is ordinal
structure (a 1-bin miss and a 100-bin miss cost the same), so the loss
difference cannot by itself explain why the reference is nearly free of
mis-pulsing while we are not; its expected contribution is real but secondary.
Provenance caveat carried forward: v2 `model_metadata.json` records no loss
fields, so "all three retrains used 0.15" is inferred from the `--octave-mass`
default, not read off run artifacts.

### 3.5 Augmentation: suspect

The reference's scale-and-crop is tempo-native and wide: time-axis scale factor
drawn from {0.8, 0.84, 0.88, ..., 1.16, 1.2} (eleven steps, +-20%) applied in
the mel domain with spline interpolation and label adjustment, then a random
256-frame crop offset, explicitly to "counter the tempo class imbalance and, at
the same time, augment the dataset" (2018 paper, Section 3.3, Figure 4). Ours
stretches +-4% on PCM (resample-based, pitch co-shifts) plus gain and pink
noise (`dataset.py:941-996`, `augment_pcm`). A +-20% stretch remaps a 170 BPM track across
136-204 BPM and materially rebalances tempo classes; +-4% moves it 163-177 and
cannot. The reference's crop offset also multiplies effective samples per
track; our fixed-tensor path has no crop dimension to randomize. This axis
compounds with corpus composition (3.6): their augmentation exists to fix class
imbalance, ours is too narrow to fix ours.

### 3.6 Corpus composition: suspect

The reference trains on 8,596 tracks spanning three multi-genre datasets, tempi
44-216 BPM, deliberately built "to create a general purpose system that does
not suffer from strong genre-bias" (2018 paper, Section 2), and the paper
itself attributes its GiantSteps strength to training-set correspondence: the
high GiantSteps result "can be explained through our training dataset. They
clearly correspond to EBall and MTG Tempo" (Section 4.1). Ours trains on the
DnB-dominant Tony corpus: the Tony columns of the PRD 5.3 band table hold 786
tracks at 160-175 BPM against 26 at 100-120, a 30:1 skew starker than the
pooled table's 980 against 62 (16:1), because the pool folds in the 661-row
GiantSteps evaluation set (153 at 160-175, 35 at 100-120); excluding
GiantSteps rows per FR-69c (the contamination boundary), the 100-120 pool
falls to 27 (PRD 5.3), so the evaluation corpus itself supplies over half of
that pooled band and the trainable skew is worse than the pooled figure
suggests. Measured corroboration that
this is structural, not volume: the calibration ladder (296 -> 330 -> 348)
shows hand-label additions trading bands against each other at fixed capacity
(`octave-bias-finding-and-plan.md`), and the opposite octave-miss directions in
section 2 (ours doubles slow tracks up toward the DnB band; the reference
halves fast tracks down toward its 121-mean prior) are exactly what opposite
corpus priors predict. Note the reference's own training set is also
imbalanced (more than 30% of Train in [120,130), Section 2.4) and it still
scores 545, so corpus composition operates jointly with augmentation breadth
(3.5) and representation (3.1), not alone.

### 3.7 Decode: neutral

The decode paths differ (single-window argmax with a 60-200 abstain guard
versus class-averaged sliding-window argmax over 30-285), but the measured
evidence bounds this axis: (a) zero GiantSteps truths fall outside 60-200,
and the -191 GiantSteps slice contains zero abstains, so the abstain guard
forfeited no row in this run; (b) the #141 experiment measured
every posterior octave-fold decode threshold as net negative (best -2), which
rules out that family of threshold-based posterior octave-fold rules;
non-threshold and calibration-aware decoders remain untried, and the charter
frames #141 as an experiment, not a guaranteed fix; (c) the
octave-recoverability ceiling (+53 to 401) leaves 144 tracks that no decode
can reach. The window-averaging half of the reference's decode is assessed as
window policy (3.2), where the aggregation happens before argmax; what remains
on this axis, argmax mechanics and the abstain range, cannot move the gap
materially on this corpus. Sub-fact unknown: the softmax-dilution effect of
115 dead bins on our Gate-1 abstain rate is unmeasured (needs full-posterior
dumps).

### 3.8 Evaluation protocol: ruled out

Ruled out by construction (12.4). Both models were scored on identical rows,
identical annotation source (revised crowd-sourced v2, SHA-256 `3dc6f375...`),
and identical FR-18-strict tolerance, and the harness reproduced the published
figure to the exact track count (545/661 = 82.45%, rounds to the published
82.5; only the count is comparable, since no per-track predictions from the
published run exist). The 12.4 report additionally bounds
protocol confusion: at 2% versus 4% the reference moves one track (544 vs
545), and on the DSP path's own instrument the reference still leads 642 to
537. The ruler is sound.

## 4. FR-58 ranking of suspected causes

Ordered by expected contribution weighed against cost to test. Five axes are
suspect; input representation and window policy are ranked separately but
should be tested together where the enabler allows, since a windowed
evaluation path exercises both. Cost pricing reuses the charter's Enablers
list (raw-audio evaluation path, full-posterior dumps); no new infrastructure
is invented here.

### Rank 1: Corpus composition (with augmentation breadth as its cheap first probe)

- Expected-contribution basis: measured plus primary text. The 260-track
  mis-pulsed residual (section 2) is the gap's mass; the reference's own paper
  attributes its GiantSteps score to training-set correspondence (Section 4.1)
  and its design goal to genre-bias avoidance (Section 2); our calibration
  ladder measured the fixed-capacity band trade that a skewed corpus forces;
  and the opposite octave-miss directions are corpus-prior signatures. This is
  the only suspect with measured our-side evidence AND a primary-text
  reference-side mechanism.
- Cost to test: high for the full fix (the F3 purpose-built corpus, Stories
  12.6-12.9, is already funded inside Epic 12; the retrain against it is Epic
  14). Cheap partial probe: a retrain with reference-style wide tempo
  augmentation (rank 2) approximates rebalancing without new labels. Ranks 1
  and 2 are therefore not independent tests: rank 2 is rank 1's probe, the
  axes compound (3.5), and a rank-2 result partially discharges rank 1.
- Charter mapping: no direct charter item; the charter's nine levers are
  model-side and corpus work lives in F3. This is the largest ordering
  disagreement with the charter (see section 4.6).

### Rank 2: Augmentation (scale-and-crop breadth)

- Expected-contribution basis: primary text. The reference states scale-and-
  crop exists to counter tempo class imbalance (Section 3.3); the factor-set
  arithmetic (+-20% in eleven steps versus our +-4%) is a fivefold difference
  in tempo-space coverage, directly aimed at the imbalance that rank 1
  identifies. No our-side measurement isolates it; confidence is
  moderate-by-mechanism, unknown-by-magnitude. Not independent of rank 1:
  this is rank 1's cheap probe, and its result partially discharges rank 1.
- Cost to test: lowest of any retrain-shaped lever. Pure training-pipeline
  change (`dataset.py` augmentation), no contract change, no substrate bump,
  no new labels; scored on the existing FR-18 harness.
- Charter mapping: charter item 1 carries "sub-100 augmentation/oversampling"
  as a clause of training-target repair; this ranking promotes the
  augmentation clause above the target-shape clause.

### Rank 3: Input representation (constant frame rate)

- Expected-contribution basis: measured error structure (260/313 mis-pulsed;
  the 100-120 band at Acc1 = Acc2 = 1/35 that only representation plausibly
  reaches) plus the roundtable's corrected scale-invariance/prior mechanism.
  Highest ceiling of any lever: it addresses the failure class the octave
  arithmetic proves is the gap's bulk. Ranked below 1 and 2 only on cost.
- Cost to test: highest. Substrate v3 (featureSetVersion bump, Swift/Python
  FNV parity harness re-run, `BNNSTechnique.featurize` rework), then a
  retrain; the charter notes it may warrant its own sub-epic. The charter's
  still-binding invariant applies (epics.md, GH-166 note): no retrain starts
  against a substrate the Swift runtime cannot reproduce byte-for-byte, and
  the CoreMLTechnique backend (charter item 4, an enabler) must run
  end-to-end before any backbone fine-tune.
- Charter mapping: charter item 5, verbatim (tempo-invariant hop or
  log-lag/tempogram input).

### Rank 4: Window policy (multi-window aggregation at inference)

- Expected-contribution basis: primary text only (Section 3.4's class-averaged
  sliding window); no repository measurement isolates aggregation, so
  expected contribution is unknown-but-plausibly-positive. Kept separate from
  rank 3 because a pure inference-time test needs no retrain if the current
  model can be fed fixed-duration crops.
- Cost to test: medium. Requires the raw-audio evaluation path enabler (the
  frozen `MLTechnique.evaluate(trace:)` transport locks conformers to the
  single v2 tensor) or a Python-side harness slice; full-posterior dumps make
  the averaging testable offline.
- Charter mapping: no numbered item; priced by the charter's "raw-audio access
  on the evaluation path" and "full-posterior diagnostic dumps" enablers.

### Rank 5: Loss (target shape)

- Expected-contribution basis: primary text (reference one-hot CE, Section
  3.3; PRD 4.3's published evidence that ordinal structure helps in general)
  plus the recorded tempo-dependent octave-mass defect. Ranked last among
  suspects because the reference wins WITH the plainest possible loss, so loss
  sophistication cannot be what separates the systems; the live question is
  only whether our nonstandard octave-mass target actively hurts. FR-63's
  ablation note applies: there is no one-hot baseline to compare against, so
  the test must construct one.
- Cost to test: low. Training-pipeline change only, no contract change; fold
  into whichever retrain runs first (the charter already recommends pairing
  with the bin-schema #147 cleanup in the next featureSetVersion bump).
- Charter mapping: charter item 1's target-repair clause (Gaussian/ordinal
  targets, asymmetric octave treatment) and the #146 correction.

### 4.6 Where this ranking disagrees with the charter's corrected lever ranking

The charter (epics.md, "Corrected lever ranking") orders: 1 training-target
repair, 2 bin-range alignment, 3 DSP selection/prior levers, 4 CoreMLTechnique
backend, 5 input representation, 6 pretrained backbone, 7 octave arbiter, 8
Core AI, 9 genre MoE. Disagreements, item by item:

- Charter item 1 (training-target repair) splits: its augmentation clause
  rises to FR-58 rank 2, its target-shape clause falls to rank 5. The octave
  arithmetic is the reason: targets shape octave behaviour, and octave
  behaviour caps at +53 of a 197-track gap.
- Charter item 2 (bin-range alignment) does not rank: the bin schema is
  neutral (identical on both sides) and the decode-dead-bin effect is bounded
  by zero out-of-range truths. It remains worthwhile hygiene to fold into the
  next featureSetVersion bump, but it is not a gap cause.
- Charter item 3 (DSP selection/prior levers) does not rank: it addresses the
  DSP path, not the model gap this differential explains. Unaffected by this
  artifact.
- Charter items 4/6/8/9 (backend, backbone, Core AI, MoE) do not rank:
  capacity is not a suspect axis. The reference reaches 545 with 2.9M
  parameters and our own AST measurement (40.9% at 87M) corroborates AS-2.
- Charter item 5 (input representation) rises to FR-58 rank 3 and, on
  expected contribution alone, is first; only its cost holds it below the
  corpus and augmentation probes.
- Charter item 7 (octave arbiter from outside the posterior) does not rank as
  a gap cause: outside-evidence octave arbitration is still the only surviving
  octave lever, but the octave class is 53 tracks of a 197-track gap.
- Corpus composition, FR-58 rank 1, appears nowhere in the charter's nine
  items. The charter ranked model-side levers; the differential says the
  largest cause sits in the training data. This is the headline disagreement.

## 5. Epic 14 input (ranked causes outside Epic 12 scope)

Every action on a ranked cause is out of Epic 12 scope; Epic 12 is measurement
and corpus construction. Filed in `deferred-work.md` under "Deferred from:
Story 12.5 (2026-08-08)":

1. Retrain against the F3 purpose-built corpus (rank 1's action half; the
   corpus construction itself is Epic 12 Stories 12.6-12.9).
2. Reference-style wide scale-and-crop augmentation retrain (rank 2).
3. Substrate v3 constant-frame-rate representation and retrain (rank 3).
4. Multi-window aggregated inference, gated on the raw-audio evaluation path
   and full-posterior dump enablers (rank 4).
5. One-hot / ordinal-target loss ablation (rank 5, FR-63/FR-64 territory).

## 6. Provenance

Input artifacts (SHA-256 where file-hashed):

- `_bmad-output/ml-training/fr18-predictions-191/seed_42/predictions.json`
  `ca3a1f6c7b7ae5f71a55e8b0c1be1791cc4ca57f3eeed60caab30aa44a28abc9`
  (our-side row: 348/313/53/260; manifest gitSha `be91867-dirty`, checkpoint
  `giantsteps_v2_seed_42`)
- `_bmad-output/ml-training/fr18-predictions/maskedMelPretrain/seed_42/predictions.json`
  `a3887a1eb14ea2075dcbf7b811f58e019043f71d36e33ae19a177c7ece534e68`
  (older dump, 330/331/53/278; recorded for the divergence note in section 2)
- `_bmad-output/ml-training/tempocnn-baseline/predictions.json`
  `61f74b7e16dbb64545aa7471186a57f9243208d87d185563214b992e5a616b79`
  (reference row: 545/116/100/16; embeds ground-truth SHA-256 `3dc6f375...`)
- `_bmad-output/implementation-artifacts/12-4-tempocnn-baseline-report.md`
  (baseline revision 4184c72),
  `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md`,
  `12-1-tempo-range-impact-report.json` context, PRD
  `prd-BoomBoomBoomKit-2026-07-26/prd.md` sections 4.3, 4.4, 5.2, 5.3, and
  `epics.md` Story 12.5 ACs plus the charter ranking. Branch baseline 12699f4.

Citation ledger (every reference-side figure to primary text; 12.4 format):

| Claim | Source |
|---|---|
| Input: 11025 Hz, 1024-sample half-overlapping windows, 21.5 Hz frame rate "suffices to represent tempi up to 646 BPM", 40 mel bands 20-5000 Hz, 256 frames = 11.9 s, values rescaled to [0,1] | 2018 paper (Schreiber and Mueller, "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network", ISMIR 2018), Sections 3.1 and 3.3 |
| 256 tempo classes, integer BPM 30-285; 2,921,042 parameters; classification chosen over regression for multimodal ambiguity and stability | 2018 paper, Section 3.2 |
| Loss: categorical cross-entropy, softmax output, one-hot targets (no smearing) | 2018 paper, Section 3.3 ("As loss function we use categorical cross-entropy"); PRD 4.3 traced correction |
| Augmentation: scale-and-crop per epoch, time-axis scale factor in {0.8, 0.84, 0.88, ..., 1.16, 1.2}, spline interpolation, ground-truth label adjusted, crop to 256 frames at random offset, rescale [0,1] after, skipped during validation | 2018 paper, Section 3.3 and Figure 4 |
| Augmentation purpose: "To counter the tempo class imbalance and, at the same time, augment the dataset" | 2018 paper, Section 3.3 |
| Training corpus: LMD Tempo (3,611) + MTG Tempo (1,159) + EBall (3,826) = 8,596 tracks, 44-216 BPM, mean 121.32, sigma 30.52, >30% in [120,130); multi-genre by design ("does not suffer from strong genre-bias"); Train "completely independent from the test datasets" | 2018 paper, Sections 2, 2.1-2.4, Figure 1 |
| Training: 90/10 train/validation, Adam lr 0.001, early stopping on validation Accuracy0, patience 20 epochs | 2018 paper, Section 3.3 |
| Global decode: sliding window, hop 128 frames (5.96 s), class-wise averaged activations, argmax | 2018 paper, Section 3.4 |
| GiantSteps strength attributed to training-set correspondence ("can be explained through our training dataset. They clearly correspond to EBall and MTG Tempo") | 2018 paper, Section 4.1 |
| Acc1 82.5 on revised 661-row annotations (the aligned published figure) | 2019 paper (arXiv:1903.10839, SMC 2019), Table 4a "Literature" row, via the 12.4 alignment record |

Sub-facts marked unknown (not ledger rows, since they cite nothing):
the contribution of the mel-parameter deltas (bands, fmin/fmax) inside axis
3.1; the softmax-dilution magnitude of the 115 dead bins inside axis 3.7; and
the magnitude of window-policy aggregation inside 3.2. None could be traced
or measured; each is labelled unknown in its axis rather than estimated.

The 2018 paper was retrieved 2026-08-08 from the ISMIR 2018 proceedings
(ismir2018.ircam.fr, paper 141) and read directly; quotes above are verbatim
from that text. The AGPL reference-implementation repository is not cited here
beyond the 12.4 provenance record.
