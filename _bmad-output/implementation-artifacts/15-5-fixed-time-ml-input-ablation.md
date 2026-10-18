# Story 15.5: Fixed-time ML input ablation harness (variant choices owned by Epic 12 Story 12.5)

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 5 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Build the develop-only ablation harness that scores an arbitrary fixed-time ML input variant against the legacy `BNNSTechnique` input and the recorded tempo-CNN reference, with paired per-track diffs stratified by DJ tempo band and error category. The variant selection for a lever-ranking read is Epic 12 Story 12.5's decision; Epic 15 ships the harness and runs one infrastructure-smoke parameterization to prove the end-to-end path works.

## Key Design Decisions

1. **The deliverable is the harness, not the lever read.** Epic 15 ships the measurement surface: fixture loader, Python-to-Swift parity extension, paired-diff reporter stratified by tempo band and error category, and the manifest that records every input-contract axis. The *variant chosen for a ranking read* (crop duration, aggregator function, strata) is Epic 12 Story 12.5's decision. The Epic-15 run on landing is tagged `infrastructure-smoke`, not a ranking input.
2. **Infrastructure-smoke parameterization on first run.** The first harness invocation runs an obvious baseline (8-second fixed crop, mean-of-softmax across crops, GiantSteps-only) so AC #1 and AC #2 prove the end-to-end path works on real audio. The run manifest records `run_kind: infrastructure-smoke`. A ranking-input run is a later invocation Epic 12 parameterizes.
3. **Fixed seconds per frame, fixed-duration crops, matched preprocessing.** Any variant the harness runs drops the resize-to-512 step at `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:537` in favor of fixed-duration crops with a fixed hop. Training and inference use byte-equivalent preprocessing, verified by the existing Swift-to-Python parity harness extended to the new input contract.
4. **Multi-crop inference with an explicitly named aggregator.** Inference evaluates multiple fixed-time crops across the track and aggregates class probabilities with one named function. The aggregator identity is recorded in the manifest and keyed by a code reference so a later report cannot be reinterpreted after the fact. Epic 12 Story 12.5 picks the aggregator for a lever-ranking read; the smoke run uses mean-of-softmax.
5. **Version every input-contract axis.** The variant records frontend sample rate, STFT window and padding convention, mel-band schema and ordering, normalization formula, crop duration in seconds, tensor shape, output class schema, model identity, and weights hash. Alias relationships like `BNNSTechnique.supportedFeatureSetVersion = MLFeatureFrames.currentFeatureSetVersion` (`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:211`) are kept pinned to `v2` for the legacy arm.
6. **Preserve the existing model path for comparison and rollback.** The legacy `BNNSTechnique` graph, `supportedFeatureSetVersion`, and resize-to-512 flow stay as the baseline arm in the report. Any fixed-time variant the harness runs lives behind a develop-only flag and separate weights file; a bad result rolls back by removing the flag and the file, not by editing shipped code.
7. **Reporting cuts by DJ tempo band and error category.** Paired per-track diffs are reported in slow (<100), mid (100 to 140) and fast (>140) tempo bands, with each miss labelled octave-halving, octave-doubling, non-octave greater-than-four-percent, or non-octave within four percent. The report cites recorded counts (GiantSteps rescore: v2 348 of 661 strict, tempo-CNN reference 545 of 661) as historical anchors, not as a current product claim.
8. **Epic 12 coordination (standing rule).** Story 12.5 (FR-58) owns the pipeline-differential ranking, picks which variants to run against which corpus for a ranking read, and gates any `featureSetVersion` bump or shipped-weights swap. Story 15.5 owns the harness and its outputs. Epic 14 (dormant until Gate 1 fires) owns bundling a weight trained under a 12.5-picked variant.
9. **No parity claim with rekordbox and no double-counting of learned evidence.** This phase precedes the Phase 9 matched evaluation, so the report compares only against the legacy `BNNSTechnique` input and the historical tempo-CNN rescore. `SignalSource.beatGrid` and `SignalWeights.beatGrid` remain placeholders; the variant's framewise observations are not routed back as a second vote for the DSP grid.

## Story

As a ML pipeline maintainer,
I want an ablation harness that scores an arbitrary fixed-time ML input variant against the legacy `BNNSTechnique` input and the recorded tempo-CNN reference, with paired per-track diffs stratified by tempo band and error category,
so that Epic 12 Story 12.5's FR-58 ranking has a measurement surface to rate the input-representation redesign against, while Epic 15 ships only the harness and one infrastructure-smoke run and does not pick the variant for a lever-ranking read.

## Acceptance Criteria

1. **Given** a fresh checkout of `develop` with the ablation harness landed
   **When** the harness is invoked with the fixed-time variant selected
   **Then** a manifest is written that records frontend sample rate, STFT window and padding convention, mel-band schema and ordering, normalization formula, crop duration in seconds, tensor shape, output class schema, model identity, weights hash, training seconds-per-frame, and inference seconds-per-frame, with the inference seconds-per-frame equal to the training seconds-per-frame.

2. **Given** the fixed-time variant and the legacy `BNNSTechnique` input arm
   **When** the extended Python-to-Swift parity harness runs over a declared fixture set
   **Then** the training-side preprocessed tensor is byte-equivalent to the Swift-side preprocessed tensor for the variant, and the legacy arm still matches the existing `BNNSTechnique.modelInputTensor(from:)` path at `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:564`.

3. **Given** at least GiantSteps and the Epic 12 internal corpus used by Story 12.5
   **When** both the fixed-time variant and the legacy input arm are scored on each corpus
   **Then** the harness emits paired per-track rows with Acc1 and Acc2 flags, DJ tempo band in (slow <100, mid 100 to 140, fast >140), and error category in (octave-halving, octave-doubling, non-octave greater-than-four-percent, non-octave within four percent), and totals are cross-checked against the recorded GiantSteps anchors v2 348 of 661 and tempo-CNN reference 545 of 661.

4. **Given** the multi-crop inference path
   **When** a track is scored with N crops
   **Then** the aggregator function name is recorded in the manifest and resolves to a single code symbol in the variant source, and the per-crop class-probability vectors used by the aggregator are retained in the run output for audit.

5. **Given** `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:211` and `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift:129`
   **When** the branch is diffed against `develop` at the end of the story
   **Then** `BNNSTechnique.supportedFeatureSetVersion` is unchanged, `MLFeatureFrames.currentFeatureSetVersion` is still `v2`, and no new weights file is loaded under the string `v2`.

6. **Given** the fixed-time report
   **When** it is written for Story 12.5 and Epic 12's FR-58 ranking input
   **Then** it states paired per-track deltas against legacy and against the tempo-CNN reference, labels each miss by band and error category, and contains no claim of parity or near-parity with rekordbox.

7. **Given** `scripts/promote-to-main.py` and the branch
   **When** the squash-merge to `develop` is prepared
   **Then** no file this story adds or modifies appears on the main-ships allowlist, and the Python training variant, extracted fixtures, and report live under `_bmad-output/ml-training/`.

8. **Given** `SignalSource.beatGrid` and `SignalWeights.beatGrid`
   **When** the variant produces framewise observations
   **Then** those observations are not plumbed into the DSP grid-fusion path and remain available only to the harness report, so the grid is not voted twice by the same evidence.

## Affected files

- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:211`
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:537`
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:564`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift:129`
- `_bmad-output/ml-training/scripts/`
- `_bmad-output/ml-training/parity_signals/`
- `_bmad-output/ml-training/fixtures/`
- `_bmad-output/implementation-artifacts/15-5-fixed-time-ml-input.md`
- `docs/rekordbox-analysis/AGENT_GUIDANCE.md`
- `docs/rekordbox-analysis/FINDINGS.md`

## Overlap with Epic 12

Direct overlap with Epic 12 corrected-ranking item 5 (Input-representation redesign) at `_bmad-output/planning-artifacts/epics.md:2391` and `:2413`, which Story 12.5's FR-58 ranking governs. Coordination: Epic 12 (Story 12.5) owns the pipeline-differential ranking and any retrain gate; Epic 15 Phase 5 owns the fixed-time harness and the specific experiment variant and feeds paired per-track diffs back to 12.5. Any `MLFeatureFrames.currentFeatureSetVersion` bump and any shipped-weights swap stay with Epic 12 / Epic 14; this story does neither.

## Open questions for the PRD

- Which aggregator does the first run commit to as the primary (mean of softmax, median of argmax, product of log-probs, trimmed mean), and which others are kept as secondary cuts in the same report.
- Which crop durations enter the shortlist (for example 6 s, 8 s, 12 s), and whether a single duration is trained first or several are trained in parallel.
- Which corpus does Story 12.5 freeze for FR-58 comparisons, so this story's paired diffs line up with the ranking table; the signed Story 12-7 corpus and its membership are off limits.
- Is the tempo-CNN 545-of-661 GiantSteps reference re-scored under the matched protocol in this story, or carried forward verbatim and reconciled in Phase 9.
- What is the develop-only invocation surface for the variant (CLI flag, environment variable, separate target) that keeps the shipped `BNNSTechnique` default behavior untouched.

## Explicit scope exclusions

- Do not alter runtime preprocessing of the existing shipped weights and claim better accuracy; retrain under the new contract or load weights trained for it.
- Do not bump `MLFeatureFrames.currentFeatureSetVersion` (`Sources/BoomBoomBoomKit/FeatureSubstrate/MLFeatureFrames.swift:129`) without an accompanying new weights file trained for that version.
- Do not change `BNNSTechnique.supportedFeatureSetVersion` (`Sources/BoomBoomBoomKitML/BNNSTechnique.swift:211`) as a side effect of this story.
- Do not touch Story 12-7 corpus membership or the signed corpus protocol.
- Do not route the variant's framewise observations into `SignalSource.beatGrid` or `SignalWeights.beatGrid`; they remain placeholders in this epic.
- Do not open a PR against `main` and do not add any file this story touches to `scripts/promote-to-main.py`.
- Do not claim parity, near-parity, or exceed-parity with rekordbox from this story; the matched evaluation that gates such a claim is Phase 9.
- Do not conflate the raw framewise observation stream with any final playable grid; this story reports model-input ablation results only.
- Do not promote the input-representation lever in Epic 12's FR-58 ranking as a side effect; that promotion belongs in Story 12.5.

