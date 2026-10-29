# Epic 15 Context: Rekordbox-informed accuracy improvements

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

An investigation of one rekordbox release measured where that commercial reference differs from BoomBoomBoomKit's output: a beat-grid anchor landing about 40 to 50 ms early on synthetic clicks regardless of content, sample rate, or ensemble policy; no typed waveform data a consumer can draw against the library's own playback timeline; and representation, framewise-observation, and matched-evaluation gaps that Epic 12 names but had not scoped. It did not show rekordbox is more accurate overall. This epic turns those differences into in-tree measurements, one frame-time fix, additive data surfaces, and an evaluation harness that decides what, if anything, should change. The epic is a charter: no PRD or architecture section covers it, so the epics file and the per-story spec files are the only planning sources. The investigation evidence lives in the sibling rekordboxReader repository, not in this repo.

## Stories

- Story 15.2: Reproduce the absolute grid-timing discrepancy in-tree with a recorded baseline
- Story 15.3: Define the frame-time convention and fix the early-anchor bias at one boundary
- Story 15.4: Independent waveform data types with per-bin timing and channel-aware stereo
- Story 15.5: Fixed-time ML input ablation harness
- Story 15.6: Internal framewise beat and downbeat observation path with a 4/4 decoder
- Story 15.7: Joint tempo and phase fit for the constant-tempo grid
- Story 15.8: Preserve hand-annotation reference downbeat and verified stable span
- Story 15.9: Matched evaluation harness vs rekordbox and DAW oracle
- Story 15.10: Beat-grid analyzed span and shared constant-grid queries
- Story 15.11: Three-band waveform levels reader and cache file format (tracked in sprint status, not the epics file)
- Story 15.12: Remove `WaveformAnalyzer` (tracked in sprint status, not the epics file)

15.5 and 15.9 are backlog. 15.4 landed its first phase only, and 15.12 removed it; 15.11 replaced it. The rest have landed on develop; status lines inside some story files lag this.

## Requirements & Constraints

- **No parity claim before 15.9 completes.** No commit message, PR text, source comment, trace string, or report may say the library meets, matches, approaches, or exceeds rekordbox until 15.9 reports paired held-out results with corpus, mode, metric, denominator, uncertainty, and limitations. Afterwards a claim covers only the metric family measured.
- **No new entries in the promotion allowlist.** No story adds a path to `scripts/promote-to-main.py` or `SHIPS_TO_MAIN`.
- **A derived grid never votes.** `SignalSource.beatGrid` and `SignalWeights.beatGrid` stay placeholders; a grid derived from a BPM never counts as evidence for that BPM.
- **Bundled weights keep their input contract.** Runtime preprocessing of existing weights is never changed to improve a number; a variant needing a new input loads weights trained for it or abstains.
- **The signed Story 12-7 corpus is off limits.** No writes under `_bmad-output/ml-training/eval-corpus/`, no edits to `pools_doc`, `draws_doc`, `candidate_universe_sha256`, corpus membership, or that harness.
- **Floors never weaken.** OA300, GiantSteps, beat-grid benchmark, and the Story 8.7 beat-grid F-measure floors hold across every story.
- **New measurement is env-gated and default-off.** `make test` keeps its test count.
- **Measurement, change, and reference stay separate.** 15.2, 15.5, 15.9 measure; 15.3, 15.4, 15.6, 15.7 change code; 15.8 preserves reference data. Rekordbox is a system under test, never the reference. Per-pair labels distinguish `system-vs-system` from `system-vs-reference`, so agreement or disagreement with rekordbox on a track with no independent reference row is never read as correctness.

## Technical Decisions

- **Frame-time convention (15.3).** `BeatTimestamp.presentationTime` has a documented public meaning and the early-anchor correction is applied at exactly one boundary. No universal 40 or 50 ms shift, no reintroduced priming, no change to the shape of `BeatGrid` or `BeatTimestamp`. Every later story honors this convention.
- **Waveform surface (15.4).** Sendable value types under `FeatureSubstrate/Waveform/`: detail envelope, peak-preserving overview, three-band energy, plus a sibling stereo decode so an anti-phase mixdown does not cancel. Each output pins schema and algorithm identity. Streaming decode with bounded memory and cancellation. No RekordboxReader dependency, no packed-byte vendor encoding, no SwiftUI consumer. Removed in Story 15.12 and replaced by the three-band levels reader (15.11).
- **Three-band levels and their file format (15.11).** A streaming reader plus a versioned binary encoding of its result; the encoding owns every rule for whether stored bytes are still usable. The library itself writes nothing to disk; the consuming app owns any cache folder, eviction, and UI.
- **Fixed-time ML input (15.5).** Develop-only. `MLFeatureFrames.currentFeatureSetVersion` stays `v2`, `BNNSTechnique.supportedFeatureSetVersion` is unchanged, no shipped weight is swapped. Paired per-track diffs stratified by tempo band and error category, on at least GiantSteps and the Epic 12 internal corpus.
- **Observation path (15.6).** An `internal` protocol returns timed per-frame beat and downbeat probabilities; a 4/4 bar-state decoder keeps prediction, observation, and correction as separate decisions. DSP stub producer only; `MLTechnique.evaluate` unchanged; `BeatGridAnalyzer` falls back byte-identically on weak coverage.
- **Joint fit (15.7).** Fits rate and phase together, trimmed against a median seed with an explicit kept fraction, at the metrical level the BPM stage already chose; it never changes octave to raise its own score. The amplitude gate on support score stays.
- **Hand annotations (15.8).** Develop-only, operator-local file next to the DAW oracle: reference downbeat, verified BPM, metrical level, bar position, verified stable span, uncertainty. No extrapolation across the track; existing oracle files and the BPM extractor CLI are unchanged; the existing ingest script stays the single writer of training labels.
- **Analyzed span (15.10).** Additive public surface only, no DSP or timing change. Lets 15.9 separate measured from extrapolated grid error.
- **Matched evaluation (15.9).** One make target scores bit-identical input across the library at `TechniqueSet.optimal`, each Epic 15 variant, one named and versioned rekordbox mode, and the DAW or 15.8 reference. Nine separate metric families, paired per-track diffs with bootstrap intervals, stratified by DJ style and tempo band; a variant without trained weights reports `abstained-pending-retrain`. Open: whether rekordbox dynamic-tempo is a system row, and the strict-tempo tolerance (0.10, 0.05, or 0.02 BPM).

## Cross-Story Dependencies

- 15.2 is the baseline 15.3 regresses against. 15.4 depends only on the 15.3 convention. 15.5 and 15.6 are independent and both report into 15.9. 15.7 consumes the 15.6 observation stream. 15.9 needs 15.3 and 15.6 and reads 15.5, 15.7, 15.8, and 15.10 output when present.
- 15.12 removed the 15.4 `WaveformAnalyzer` on 2026-10-28 after a check found no consumer, without waiting for the downstream app to move to the 15.11 reader.
- **Epic 12** owns promotion of the input-representation lever 15.5 measures and any decision to fuse a derived tempo back into BPM selection. It may call the 15.9 harness without owning it. Whether 15.5 or 15.6 is re-homed into Epic 12 is undecided.
- **Epic 13** DSP experiments are orthogonal. **Epic 14** owns any retrain; an Epic 15 variant needing new weights reports into that gate.
