# Epic 15 Context: Rekordbox-informed accuracy improvements

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

An investigation of rekordbox 7.2.19.0342 measured three gaps between that commercial reference and BoomBoomBoomKit's current output: a beat-grid anchor that lands roughly 40 to 50 ms early, reproducible on synthetic clicks regardless of content, sample rate, or ensemble policy; no typed waveform surface a consumer can draw against the library's own playback timeline; and a set of representation, framewise-observation, and matched-evaluation gaps that Epic 12 names but has not scoped. The investigation did not show that rekordbox is more accurate overall. This epic turns the measured differences into in-tree measurements, a single frame-time fix, additive data surfaces, and an evaluation harness that decides what, if anything, should change. The epic began as a charter with no PRD. The investigation research now lives in the sibling repository at `../rekordboxReader/docs/rekordbox-analysis/` (FINDINGS.md, AGENT_GUIDANCE.md, evidence/timing/), not in this repo.

## Stories

- Story 15.2: Reproduce the absolute grid-timing discrepancy in-tree with a recorded baseline
- Story 15.3: Define the frame-time convention and fix the early-anchor bias at one boundary
- Story 15.4: Independent waveform data types with per-bin timing and channel-aware stereo
- Story 15.5: Fixed-time ML input ablation harness
- Story 15.6: Internal framewise beat and downbeat observation path with a 4/4 structured decoder
- Story 15.7: Joint tempo and phase fit for the constant-tempo grid
- Story 15.8: Preserve hand-annotation reference downbeat and verified stable span
- Story 15.9: Matched evaluation harness vs rekordbox and DAW oracle

**Status.** Stories 15.2, 15.3, 15.4, 15.6 and 15.7 landed on develop on 2026-10-21 as PRs #198, #199 and #200 (squash merges 6992589, bf987e8, 57165b6). Story 15.8 is implemented on branch `rterhaar/15-8-dawproject-annotations`. The remaining phases are 15.5 and 15.9. Status lines inside individual story files may lag this record.

## Requirements & Constraints

- **No rekordbox parity claim before 15.9 completes.** No commit message, PR description, source comment, trace string, or report may say BoomBoomBoomKit meets, matches, approaches, or exceeds rekordbox until 15.9 reports paired held-out results with corpus, mode, metric, denominator, uncertainty, and limitations stated. After that, a claim covers only the metric family it was measured on.
- **Nothing ships to `main`.** No file this epic produces is added to `scripts/promote-to-main.py` or the `SHIPS_TO_MAIN` allowlist.
- **Derived grids are never independent evidence.** `SignalSource.beatGrid` and `SignalWeights.beatGrid` stay placeholders. A derived grid never votes into the BPM selection that fed it.
- **Bundled weights keep their input contract.** Runtime preprocessing of existing weights is never altered to improve a number. A variant that needs a new input contract loads weights trained for it or reports an abstention (`abstained-pending-retrain` in 15.9).
- **The signed Story 12-7 corpus is out of bounds.** No story writes under `_bmad-output/ml-training/eval-corpus/`, edits `pools_doc`, `draws_doc`, or `candidate_universe_sha256`, or changes corpus membership or the signed-corpus harness.
- **Existing floors are never weakened.** OA300, GiantSteps, beat-grid benchmark, and the Story 8.7 beat-grid F-measure floors hold across every story.
- **New measurement is env-gated and default-off.** `make test` keeps the same test count.
- **Measurement, change, and reference stay separate.** 15.2, 15.5 and 15.9 measure. 15.3, 15.4, 15.6 and 15.7 change code. 15.8 preserves reference data. Rekordbox is a system under test in 15.9, never the reference. Per-pair labels distinguish `system-vs-system` from `system-vs-reference`, so agreement with rekordbox on a track with no independent reference row is never read as correctness.

## Technical Decisions

- **Frame-time convention (15.3).** `BeatTimestamp.presentationTime` has a documented meaning in the public API doc, and the early-anchor correction is applied at exactly one boundary. There is no universal 40 or 50 ms shift, priming is not reintroduced, and the shapes of `BeatGrid` and `BeatTimestamp` do not change. Every later phase honors this convention.
- **Waveform surface (15.4).** Lives in `FeatureSubstrate/Waveform/` as Sendable value types: detail envelope, peak-preserving overview, and three-band energy. A sibling `DecodedStereoAudio` exists so an anti-phase mixdown does not cancel. Each output pins its schema and algorithm identity. Decode streams with bounded memory, cancellation, and progress. There is no RekordboxReader dependency and no PWV4 or packed-byte encoding.
- **Fixed-time ML input (15.5).** A develop-only harness. `MLFeatureFrames.currentFeatureSetVersion` stays `v2`, `BNNSTechnique.supportedFeatureSetVersion` does not change, and no shipped weight is swapped. Results are paired per-track diffs stratified by tempo band and error category, scored on at least GiantSteps and the Epic 12 internal corpus. Epic 12 Story 12.5 owns the variant choices.
- **Observation path and decoder (15.6).** An `internal` protocol returns timed per-frame beat and downbeat probabilities. A 4/4 bar-state decoder treats prediction, observation, and correction as separate decisions under a local evidence rule. The producer is a DSP stub, and a trained head is deferred. `MLTechnique.evaluate` is unchanged, and `BeatGridAnalyzer` falls back byte-identically when coverage is weak. Known limits are tracked as deferred-work W95, W98 and W99.
- **Joint fit (15.7).** `FittedTempoPhase` carries rate and phase anchor, trimmed against a median seed with an explicit kept fraction. It refines at the metrical level the BPM stage already chose and never changes octave to improve its own score. Validation is against independent references at absolute phase. The `minSupportScore` amplitude gate stays (W98).
- **Hand annotations (15.8).** Develop-only output at `${OA300_CORPUS_PATH}/daw-oracle-annotations.json`: reference downbeat time, verified BPM, declared metrical level, bar position, verified stable span, and uncertainty. No extrapolation across the track. `daw-oracle.json`, `daw-oracle-beats.json`, and the `scripts/dawproject-bpm.py` CLI stay unchanged. `scripts/ingest-dawproject-labels.py` remains the single writer of training labels. The file stays operator-local at the corpus path, like daw-oracle.json (resolved 2026-10-21).
- **Matched evaluation (15.9).** A `make matched-eval` target scores bit-identical input across four systems: BoomBoomBoomKit at `TechniqueSet.optimal`, each Epic 15 variant, one named and versioned rekordbox mode, and the DAW or 15.8 reference. It reports nine separate metric families (musical tempo level, strict tempo, fine BPM and rate error, absolute grid phase, beat P/R/F, downbeat phase, long-span drift, failures and abstentions, runtime and peak memory) as paired per-track diffs with bootstrap CIs, stratified by DJ style tag and tempo band. Quiet-section abstentions are reported separately as the 15.7 amplitude gate. Open questions: whether dynamic-tempo rekordbox is also a system row, and the strict-tempo tolerance (0.10, 0.05, or 0.02 BPM).

## Cross-Story Dependencies

- 15.2 is the pre-change baseline that 15.3 regresses against. 15.4 depends only on the 15.3 convention. 15.5 and 15.6 are independent of each other and both report into 15.9. 15.7 consumes the 15.6 observation stream. Writing 15.8 has no prerequisite, but 15.9 reads its records. 15.9 requires 15.3 and 15.6 and reads 15.4, 15.5, 15.7 and 15.8 when present.
- **Epic 12** is on the unmerged branch `rterhaar/epic-12`: PR #189 is open into develop, Stories 12.1 to 12.6 are on that branch, and 12.7 is in PR #197. Epic 12 Story 12.5's FR-58 ranking is the sole authority on promoting the input-representation lever that 15.5 measures. Fusing a derived tempo back into BPM selection, whether as a `beatGrid` vote or a multi-task tempo head, is Epic 12's decision, not 15.6's. Epic 12 may call `make matched-eval` without owning it. The PRD has not decided whether 15.5 is re-homed into Epic 12 Story 12.5.
- **Epic 13** (remaining DSP experiments) is orthogonal and is not touched here. **Epic 14** owns any retrain. An Epic 15 variant that needs new weights reports into that gate and does not decide the retrain itself.
