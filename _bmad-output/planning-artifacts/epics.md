---
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
completedAt: '2026-03-31'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/architecture.md'
  - '_bmad-output/planning-artifacts/phase3-roadmap.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md'
  - '_bmad-output/implementation-artifacts/deferred-work.md'
  - '_bmad-output/implementation-artifacts/tech-spec-phase-1-intensity-trace-accuracy.md'
  - '_bmad-output/implementation-artifacts/tech-spec-phase-2-technique-protocol-ablation.md'
  - '_bmad-output/implementation-artifacts/spec-multi-window-candidate-merging.md'
  - '_bmad-output/implementation-artifacts/spec-post-disambiguation-voting.md'
---

# BoomBoomBoomKit - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for BoomBoomBoomKit Phase 3, decomposing the requirements from the PRD, Architecture, and supporting planning artifacts into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Consumer can analyze an audio file for BPM by providing a URL and receiving a result with BPM value, confidence score, and list of candidate BPMs with scores
FR2: Consumer can specify an analysis intensity level (1-10) to control the trade-off between speed and accuracy
FR3: Consumer can specify a merge strategy to control how candidates from multiple analysis windows are combined
FR4: Consumer can enable a diagnostic trace to inspect per-step pipeline intermediate state for a given analysis
FR5: Consumer can evaluate analysis accuracy against established MIR evaluation standards (dual-tolerance reporting)
FR6: Consumer can receive the effective intensity level used when the requested intensity was unavailable (ML degradation)
FR7: Consumer can receive an actionable explanation when intensity degradation occurs
FR8: Consumer can analyze an audio file with no configuration beyond a URL and receive an accurate result using sensible defaults
FR9: Consumer can analyze an audio file for integrated loudness (LUFS) conforming to ITU-R BS.1770-5
FR10: Consumer can read audio files into mono PCM samples at the file's native sample rate
FR11: Consumer can cancel an in-flight BPM analysis cooperatively -- the analysis exits between pipeline stages without blocking
FR12: Consumer can receive progress updates during analysis for both sync and async usage patterns
FR13: Analysis results for completed work are preserved when cancellation occurs mid-batch
FR14: A cancelled analysis returns nil -- no partial BPM results are produced
FR15: Consumer can optionally add the BoomBoomBoomKitML package to enable ML-augmented detection at intensity 8-10
FR16: ML-augmented analysis runs DSP and ML in ensemble -- ML never runs alone
FR17: The library degrades gracefully to the highest supported DSP intensity when the ML package is not present
FR18: Consumer can query the maximum supported intensity level based on available packages (7 without ML, 10 with ML)
FR19: Consumer can inspect available DSP techniques and technique set presets
FR20: Consumer can compose custom technique sets for specialized use cases
FR21: Library author can add new DSP techniques that are gated by the existing technique set architecture
FR22: Consumer can read audio files in WAV, AIFF, MP3, M4A (AAC/ALAC), FLAC, and CAF formats
FR23: Consumer can read a partial segment of an audio file (e.g., first 30 seconds)
FR24: Consumer can downsample audio to a target sample rate at read time
FR25: Library returns nil (not an error) for audio that is too short, silent, or at an unsupported sample rate for LUFS
FR26: Library returns a clear error for file I/O failures (file not found, unsupported format)
FR27: Library author can run accuracy benchmarks against the OA300 corpus (make benchmark)
FR28: Library author can run the full ablation matrix (make ablation) to validate technique combinations
FR29: Library author can run performance benchmarks (make perf-benchmark) to measure wall-clock analysis time
FR30: Library author can run three-way DAW oracle comparison (make oracle)
FR31: Library author can benchmark against the GiantSteps Tempo dataset (664 tracks, MIREX-compatible)
FR32: Accuracy is reported at both 2% tolerance (library standard) and 4% tolerance (MIREX-compatible)
FR33: Genre-stratified accuracy reporting is available once the corpus has sufficient genre diversity
FR34: Developer can build and run a demo macOS app from the same repository as the library
FR35: Developer can drop an audio file into the demo app and see the detected BPM, confidence, and effective intensity
FR36: Developer can adjust intensity level and merge strategy in the demo app and see results update
FR37: Developer can view diagnostic trace data (candidates, sub-band energies, disambiguation steps) in the demo app
FR38: Demo app provides responsive feedback at all intensity levels (immediate at low intensity, activity indicator at high intensity)
FR39: Demo app displays wall-clock analysis time alongside detected BPM
FR40: Demo app generates a copy-pasteable Swift configuration snippet reflecting the current parameter settings
FR41: Demo app can export diagnostic trace data in a machine-readable format (JSON or CSV) for external plotting
FR42: Consumer can find quick-start code samples in the README
FR43: Consumer can find documentation of nil-return conditions (when and why analysis returns nil)
FR44: Consumer can find guidance on batch workflow patterns (cancellation, progress, task orchestration)
FR45: All public API types and methods have inline /// documentation

### NonFunctional Requirements

NFR1: Analysis at intensity 1-3 should feel instantaneous for interactive use cases
NFR2: Analysis at intensity 7 should complete fast enough for batch library import without perceived delays
NFR3: Analysis at intensity 8-10 (ML) may take longer but should complete within reasonable time for batch workflows
NFR4: Performance benchmarks report wall-clock time alongside hardware context (chip, memory) for reproducibility
NFR5: Pipeline memory usage should not grow linearly with track duration -- scratch buffers are reused
NFR6: Downsampling and buffer reuse optimizations must not degrade accuracy (validated by ablation)
NFR7: Acc1 on the OA300 corpus must never decrease phase-over-phase (regression gate)
NFR8: ML-augmented detection (intensity 8+) must be strictly >= DSP-only accuracy on every corpus run
NFR9: Fine-grid precision errors on DAW oracle tracks should be resolved (sub-BPM accuracy)
NFR10: LUFS measurement conforms to ITU-R BS.1770-5 with Double-precision K-weighting
NFR11: Accuracy results are reported at both 2% (library standard) and 4% (MIREX-compatible) tolerance
NFR12: BoomBoomBoomKit (intensity 1-7) adds zero framework dependencies beyond Foundation, Accelerate, and AVFoundation
NFR13: BoomBoomBoomKitML adds only CoreML as an additional framework dependency
NFR14: Swift 6.0 strict concurrency compliance -- no data races, all public types Sendable
NFR15: macOS 15+ deployment target
NFR16: All bulk numeric operations on audio buffers use Accelerate/vDSP -- no manual loops over sample data
NFR17: All new code passes make fmt + make lint before merging
NFR18: All new DSP techniques are added to the ablation matrix
NFR19: Existing test suite never regresses
NFR20: IIR filter coefficients (K-weighting biquads) remain Double precision

### Additional Requirements

From Architecture:
- ADR-1: Cancellation between windows only -- AudioAnalysisService checks Task.isCancelled between window iterations, BPMAnalyzer stays stateless
- ADR-2: Progress via @Sendable callback closure -- ProgressUpdate struct with windowsCompleted/windowsTotal
- ADR-3: Internal buffer management -- withUnsafeTemporaryAllocation for small buffers, TempogramBuffers-pattern for large buffers
- ADR-4: Eager ML model loading at conformance init (throws) -- CoreMLTechnique()/BNNSTechnique() loads model in initializer
- ADR-5: Configurable ML ensemble voting policy -- conservative default: DSP wins unless ML confidence high AND DSP confidence low
- ADR-6: Always populate trace when ML technique present -- trace built internally for MLTechnique.evaluate() input
- ADR-7: Harmonic ratio detection inside step 10 -- extends resolveOctaveAmbiguity with 3:2 and 3:1 ratio checks
- ADR-8: Click-track cross-correlation as new DSPTechnique case -- ablation matrix grows to 2^7=128
- ADR-9: GiantSteps as separate test suite with GIANTSTEPS_CORPUS_PATH env var
- ADR-10: Dual tolerance as separate test methods (benchmarkAcc1Strict 2%, benchmarkAcc1MIREX 4%)
- Implementation sequence: ADR-3 -> ADR-1+2 -> ADR-9+10 -> ADR-7 -> ADR-8 -> ADR-4+5+6
- effectiveIntensity field to be added to AudioAnalysisResult for ML degradation reporting
- Mock MLTechnique conformance in test target for deterministic ensemble voting tests
- Demo app as separate Xcode project in Demo/ following AmbientUI pattern, ships on main
- Per-story gating: make fmt, make lint, make test, make benchmark, make ablation before and after each story

From Deferred Work:
- Non-octave BPM disambiguation (3:2, 3:1 ratios) in resolveOctaveAmbiguity -- two known failing Prodigy tracks as validation
- Confidence semantics for merge strategies -- revisit per-cluster confidence after ablation data
- Post-disambiguation merge strategies -- clustering strategies hurt Acc1 because they merge pre-disambiguation candidates

From Phase 3 Roadmap:
- Buffer pool (pre-allocate scratch arrays) -- 24 scratch buffer allocations in BPMAnalyzer
- FFT plan reuse -- create vDSP.FFT plan once, reuse across frames
- Harmonic ratio detection -- check 3:2 or 2:3 ratios, prefer 80-160 BPM comfort zone
- Confidence-weighted window voting -- use confidence-weighted vote instead of simple majority
- Segmented analysis (4 segments, median) -- analyze 4 non-overlapping segments for tempo-varying content
- Click-track cross-correlation -- synthetic click vs onset envelope cross-correlation
- Duration-derived BPM hint -- auto-read duration, compute plausible BPMs from bar counts
- Octave classifier (CoreML or BNNS) -- train on BPMDiagnosticTrace features, output {half, keep, double}
- Fine-grid precision gap -- investigate parabolic interpolation bias, finer grid, snap-to-nearest

From Brainstorming Session (65 ideas, key unimplemented):
- #4: Ratio-aware disambiguation (3:2, 4:3, 3:1) -- extends resolveOctaveAmbiguity
- #5: Early-exit fast path -- skip remaining windows if confidence > 0.85
- #35: Duration-derived BPM as weak prior from file metadata
- #62: Click-track cross-correlation at candidate BPMs
- #59: Harmonic/percussive source separation for onset detection
- #2/#65: Schreiber-style CNN or octave classifier (BNNS/CoreML)
- #54: BoomBoomBoomKitML package split
- #64: Unified signal matrix for disambiguation

### UX Design Requirements

N/A -- BoomBoomBoomKit is a DSP library with no UI. The demo app (FR34-41) is an evaluation tool, not a UX-designed product.

### FR Coverage Map

| FR | Epic | Status | Notes |
|----|------|--------|-------|
| FR1 | -- | Existing | Improved by Epic 3 (more accurate results) |
| FR2 | -- | Existing | Improved by Epic 3 (better outcomes at existing intensity levels) |
| FR3 | -- | Existing | No Phase 3 changes |
| FR4 | -- | Existing | No Phase 3 changes |
| FR5 | Epic 2 | New | Dual tolerance reporting (2% and 4%) |
| FR6 | Epic 4 | New | Effective intensity reporting for ML degradation |
| FR7 | Epic 4 | New | Actionable explanation for intensity degradation |
| FR8 | -- | Existing | Improved by Epic 3 (better defaults) |
| FR9 | -- | Existing | No Phase 3 changes |
| FR10 | -- | Existing | No Phase 3 changes |
| FR11 | Epic 1 | New | Cooperative cancellation between pipeline stages |
| FR12 | Epic 1 | New | Progress updates via @Sendable callback |
| FR13 | Epic 1 | New | Completed results preserved on cancellation |
| FR14 | Epic 1 | New | Cancelled analysis returns nil |
| FR15 | Epic 4 | New | BoomBoomBoomKitML optional package |
| FR16 | Epic 4 | New | DSP + ML ensemble (ML never alone) |
| FR17 | Epic 4 | New | Graceful degradation to DSP-only |
| FR18 | Epic 4 | New | Query maximum supported intensity |
| FR19 | -- | Existing | Technique inspection |
| FR20 | -- | Existing | Custom technique sets |
| FR21 | Epic 3 | New | New DSP techniques via technique set architecture |
| FR22 | -- | Existing | Audio format support |
| FR23 | -- | Existing | Partial segment reads |
| FR24 | -- | Deferred | Downsampling -- post-baseline experiment |
| FR25 | -- | Existing | Nil return for short/silent/unsupported |
| FR26 | -- | Existing | Clear errors for file I/O failures |
| FR27 | -- | Existing | OA300 benchmark (make benchmark) |
| FR28 | -- | Existing | Ablation matrix (make ablation) |
| FR29 | Epic 2 | New | Performance benchmarks (make perf-benchmark) |
| FR30 | -- | Existing | DAW oracle comparison (make oracle) |
| FR31 | Epic 2 | New | GiantSteps Tempo dataset integration (664 tracks) |
| FR32 | Epic 2 | New | Dual tolerance reporting (2% and 4%) |
| FR33 | Epic 2 | New | Genre-stratified accuracy reporting |
| FR34 | Epic 5 | New | Demo macOS app buildable from repo |
| FR35 | Epic 5 | New | File drop with BPM/confidence/intensity display |
| FR36 | Epic 5 | New | Adjustable intensity and merge strategy |
| FR37 | Epic 5 | New | Diagnostic trace visualization |
| FR38 | Epic 5 | New | Responsive feedback at all intensity levels |
| FR39 | Epic 5 | New | Wall-clock analysis time display |
| FR40 | Epic 5 | New | Copy-pasteable Swift config snippet |
| FR41 | Epic 5 | New | Export trace data (JSON/CSV) |
| FR42 | Epic 5 | New | Quick-start code samples in README |
| FR43 | Epic 5 | New | Nil-return condition documentation |
| FR44 | Epic 5 | New | Batch workflow pattern guidance |
| FR45 | Epic 5 | New | Inline /// documentation on all public API |

**Standard acceptance criteria (all stories in Epics 1-4):**
- `make fmt` + `make lint` pass before and after implementation
- `make test` -- all existing tests pass
- `make benchmark` -- no Acc1/Acc2 regressions on OA300
- `make ablation` -- full technique matrix completes without crashes
- Update inline `///` doc comments for any modified public API
- Update CLAUDE.md if public types or key behaviors change

## Epic List

### Epic 1: Pipeline Performance & Cooperative Analysis
Consumers get faster BPM analysis through internal buffer optimization, can cancel in-flight analysis cooperatively, and receive progress updates for responsive batch workflows.
**FRs covered:** FR11, FR12, FR13, FR14
**ADRs:** ADR-1 (cancellation between windows), ADR-2 (progress via @Sendable callback), ADR-3 (internal buffer reuse)
**Phase:** 3A
**Dependencies:** None (standalone)

### Epic 2: Measurement & Validation Infrastructure
Library author can validate accuracy against diverse corpora with standardized MIR metrics, enabling confident accuracy claims and regression detection across genres.
**FRs covered:** FR5, FR29, FR31, FR32, FR33
**ADRs:** ADR-9 (GiantSteps as separate test suite), ADR-10 (dual tolerance as separate test methods)
**Phase:** 3A
**Dependencies:** None (standalone). Enables confident validation for Epics 3 and 4.

### Epic 3: DSP Accuracy Improvement
Library delivers more accurate BPM detection, fixing octave errors (2:1), triplet errors (3:2, 3:1), and fine-grid precision errors -- measurable improvement validated by ablation and corpus benchmarks.
**FRs covered:** FR21 (new techniques). Improves: FR1, FR2, FR8
**ADRs:** ADR-7 (harmonic ratio detection in step 10), ADR-8 (click-track cross-correlation as new DSPTechnique)
**Phase:** 3B
**Dependencies:** Benefits from Epic 2 (measurement infra validates accuracy claims). Each technique is an independent ablation-validated story.
**Notes:** Open-ended scope -- done when promising techniques are exhausted. Also includes: duration-derived BPM hint, fine-grid precision fix, confidence-weighted voting. Deferred work (3:2/3:1 ratios) lands here.

### Epic 4: ML-Augmented Detection
Consumers can optionally add ML-augmented detection at intensity 8-10, getting better accuracy with zero impact on the core DSP-only library. Graceful degradation with actionable provenance.
**FRs covered:** FR6, FR7, FR15, FR16, FR17, FR18
**ADRs:** ADR-4 (eager model loading at init), ADR-5 (configurable ensemble voting), ADR-6 (trace populated for ML input)
**Phase:** 3C
**Dependencies:** Epic 3 establishes the best DSP baseline before ML augments it. ML is strictly additive (NFR8).
**Notes:** BoomBoomBoomKitML as separate SPM product. BNNS first (zero new deps), CoreML second (Neural Engine). Mock MLTechnique in test target for deterministic ensemble tests.

### Epic 5: Developer Experience & Demo
External developers can evaluate and adopt BoomBoomBoomKit through a visual demo app, clear documentation, quick-start guides, and batch workflow guidance.
**FRs covered:** FR34, FR35, FR36, FR37, FR38, FR39, FR40, FR41, FR42, FR43, FR44, FR45
**Phase:** 3D
**Dependencies:** Can start once API surface stabilizes (late Epic 4). Demo app is a public-API-only consumer.
**Notes:** Demo app as separate Xcode project in Demo/ (AmbientUI pattern), ships on main. SwiftUI + @Observable. Epic 5 is final polish -- inline /// doc updates happen per-story in Epics 1-4.

---

## Epic 1: Pipeline Performance & Cooperative Analysis

Consumers get faster BPM analysis through internal buffer optimization, can cancel in-flight analysis cooperatively, and receive progress updates for responsive batch workflows.

### Story 1.1: Internal Buffer Reuse in BPM Pipeline

As a library author,
I want scratch buffer allocations in BPMAnalyzer to be reused rather than allocated per-step,
So that analysis uses less memory and completes faster without changing results.

**Acceptance Criteria:**

**Given** an audio file analyzed at intensity 7
**When** `BPMAnalyzer.estimateBPM()` executes the 10-step pipeline
**Then** compile-time-bounded buffers (FFT scratch, mel band arrays, candidate arrays) use `withUnsafeTemporaryAllocation` instead of fresh Array allocations
**And** input-dependent buffers (onset envelope, mel spectrogram frames) use a `PipelineBuffers`-pattern struct with `allocate()`/`deallocate()`
**And** every `.allocate()` has a corresponding `.deallocate()` in a `defer` block
**And** no buffer references are held beyond `estimateBPM()` scope

**Given** `make test`
**When** all existing tests run
**Then** all pass with no changes needed

**Given** `make benchmark`
**When** OA300 corpus runs
**Then** no Acc1/Acc2 regression (buffer reuse must not change results)

**Note:** Formal wall-clock measurement lands in Story 2.3 (PerformanceBenchmarkTests). Informal before/after timing during development is sufficient for this story.

### Story 1.2: Cooperative Cancellation and Progress Reporting

As an app developer building a batch library import,
I want to cancel an in-flight BPM analysis cooperatively and receive progress updates per-window,
So that my app's UI remains responsive and users can stop a long scan without blocking.

**Acceptance Criteria:**

**Given** an analysis running at intensity 7 (3 windows)
**When** the parent `Task` is cancelled between window iterations
**Then** the analysis returns `nil` without blocking
**And** results from previously completed windows are not returned (no partial results)

**Given** the cancellation implementation in `AudioAnalysisService`
**When** coded
**Then** it uses an injectable `isCancelled: () -> Bool` closure parameter (defaulting to `{ Task.isCancelled }`)
**And** tests can inject a deterministic closure to test cancellation without timing-dependent flakiness

**Given** an analysis running at intensity 7 with an `onProgress` callback
**When** each window analysis begins
**Then** the callback receives a `ProgressUpdate` with `windowsCompleted` and `windowsTotal`
**And** the callback is called with (0, 3), (1, 3), (2, 3) for a 3-window analysis

**Given** the `onProgress` closure
**When** declared in the API
**Then** it uses `@Sendable` annotation: `onProgress: (@Sendable (ProgressUpdate) -> Void)? = nil`
**And** `ProgressUpdate` is a new public struct conforming to `Sendable` with `windowsCompleted: Int` and `windowsTotal: Int`

**Given** no `onProgress` callback is provided (default `nil`)
**When** analysis runs
**Then** behavior is identical to current (no progress overhead)

**Given** intensity 1-5 (single window)
**When** analysis runs with cancellation and progress
**Then** cancellation still checks before the single window, progress reports (0, 1)

**Given** a cancellation test
**When** a `Task` is created, analysis starts, and `task.cancel()` is called after a short delay
**Then** `await task.value` returns `nil`

**Given** `isCancelled` returns true before the first window begins
**When** analysis runs
**Then** it returns `nil` immediately
**And** the progress callback is never called

**Files:** `AudioAnalysisService.swift` (window loop + new parameters), `ProgressUpdate.swift` (new public struct), `AudioAnalysisServiceTests.swift` (cancellation + progress tests)

---

## Epic 2: Measurement & Validation Infrastructure

Library author can validate accuracy against diverse corpora with standardized MIR metrics, enabling confident accuracy claims and regression detection across genres.

**References:** [MIREX Audio Tempo Estimation](https://www.music-ir.org/mirex/wiki/2019:Audio_Tempo_Estimation), [mir_eval tempo.py](https://github.com/mir-evaluation/mir_eval/blob/main/mir_eval/tempo.py) (4% tolerance reference), [GiantSteps Tempo Dataset](https://github.com/GiantSteps/giantsteps-tempo-dataset) (Knees et al., ISMIR 2015), "Music Tempo Estimation: Are We Done Yet?" ([TISMIR](https://transactions.ismir.net/articles/10.5334/tismir.43))

### Story 2.1: GiantSteps Tempo Dataset Integration

As a library author,
I want to benchmark BoomBoomBoomKit against the GiantSteps Tempo dataset (664 EDM tracks with crowd-corrected annotations),
So that I have a genre-diverse, MIREX-compatible validation corpus alongside OA300.

**Acceptance Criteria:**

**Given** the GiantSteps ground truth annotations
**When** converted to the project's JSON fixture format
**Then** `Tests/BoomBoomBoomKitTests/Fixtures/giantsteps-ground-truth.json` is created with track filename and annotated BPM per entry

**Given** a new test suite `GiantStepsBenchmarkTests`
**When** `GIANTSTEPS_CORPUS_PATH` env var is set
**Then** the suite runs and reports Acc1/Acc2 for the corpus
**And** the suite is skipped gracefully when the env var is unset

**Given** the Makefile
**When** `make giantsteps` is invoked
**Then** it runs `swift test --filter GiantStepsBenchmarkTests` with the env var

**Given** the GiantSteps test suite
**When** analysis results are computed
**Then** audio is pre-read once and shared across tolerance methods (follow `benchmarkMergeStrategies` pattern)

**Given** GiantSteps tracks with two annotated tempos (tempo1 and tempo2)
**When** Acc1 is evaluated
**Then** a track is counted as correct if the detected BPM matches either tempo1 or tempo2 within tolerance

### Story 2.2: Dual Tolerance Accuracy Reporting

As a library author,
I want accuracy reported at both 2% (library standard) and 4% (MIREX-compatible) tolerance,
So that I can compare results with published MIR literature and track precision at both thresholds.

**Acceptance Criteria:**

**Given** `OA300BenchmarkTests`
**When** benchmarks run
**Then** two separate test methods exist: `benchmarkAcc1Strict()` (2%) and `benchmarkAcc1MIREX()` (4%)
**And** both methods share pre-computed analysis results (audio read once, iterate over thresholds)
**And** each method is individually filterable via `swift test --filter`

**Given** `GiantStepsBenchmarkTests`
**When** benchmarks run
**Then** dual tolerance methods are also present following the same pattern

**Given** Acc2 reporting
**When** computed
**Then** Acc2 allows factors of 2, 3, 1/2, 1/3 per MIREX convention (octave and triplet errors)

### Story 2.3: Performance Benchmark Infrastructure

As a library author,
I want wall-clock analysis time benchmarks with hardware context reporting,
So that I can measure performance improvements and detect regressions across pipeline changes.

**Acceptance Criteria:**

**Given** a new test suite `PerformanceBenchmarkTests`
**When** executed
**Then** it measures wall-clock analysis time per track at intensity 7
**And** reports hardware context (chip model, memory) alongside timing results
**And** follows the `@Suite(.enabled(if: ...))` env-gating pattern

**Given** the Makefile
**When** `make perf-benchmark` is invoked
**Then** it runs the performance benchmark suite with appropriate env var

**Given** performance results
**When** reported
**Then** per-track timing and aggregate statistics (mean, median, p95) are printed

### Story 2.4: OA300 Corpus Expansion with Genre Diversity

As a library author,
I want to expand the OA300 corpus with tracks from underrepresented genres (house, hip-hop, pop, rock, ambient),
So that accuracy claims are credible beyond the current DnB-heavy corpus.

**Acceptance Criteria:**

**Given** the expanded corpus
**When** counted by genre
**Then** at least 20 new tracks are added covering 4+ genres beyond the current DnB/breakbeat/footwork cluster

**Given** new tracks added to the corpus
**When** ground truth is established
**Then** each track has a verified BPM (DAW-verified preferred, Rekordbox as fallback)
**And** `oa300-ground-truth.json` is updated with the new entries including genre tags

**Given** genre tags in ground truth
**When** `FR33` (genre-stratified reporting) is implemented
**Then** the data structure supports per-genre Acc1/Acc2 breakdown

**Note:** This is a non-code story -- the work is manual (selecting tracks, verifying BPMs, updating JSON). No library code changes.

### Story 2.5: Genre-Stratified Accuracy Reporting

As a library author,
I want accuracy reported per-genre once the corpus has sufficient diversity,
So that I can identify genre-specific weaknesses and tune technique presets accordingly.

**Acceptance Criteria:**

**Given** `OA300BenchmarkTests` with genre-tagged ground truth
**When** benchmarks run
**Then** Acc1/Acc2 are reported per-genre in addition to aggregate
**And** genres with fewer than 5 tracks are noted as "insufficient sample" rather than reported as percentages

**Given** genre-stratified results
**When** a genre shows significantly lower Acc1 than aggregate
**Then** the report highlights it as a candidate for technique tuning

---

## Epic 3: DSP Accuracy Improvement

Library delivers more accurate BPM detection, fixing octave errors (2:1), triplet errors (3:2, 3:1), and fine-grid precision errors -- measurable improvement validated by ablation and corpus benchmarks.

**References:** Ellis (2007) "Beat Tracking by Dynamic Programming" (TPS2 enhancement), Grosche & Muller (2011) "Extracting Predominant Local Pulse Information" (tempogram), O'Shaughnessy (1987) (mel scale). Deferred work: `_bmad-output/implementation-artifacts/deferred-work.md` (3:2/3:1 ratio detection).

### Story 3.1: Harmonic Ratio Detection (3:2 and 3:1 Disambiguation)

As a library author,
I want the disambiguation step to detect non-octave ratios (3:2 and 3:1) between candidates,
So that triplet errors on DnB and jazz tracks are resolved (e.g., 107.5 vs 171 BPM).

**Acceptance Criteria:**

**Given** two BPM candidates with a ratio in the 3:2 range (1.45-1.55 tolerance)
**When** `resolveOctaveAmbiguity` runs in step 10
**Then** the candidates are recognized as a triplet pair and sub-band voting is applied to resolve them
**And** the candidate in the 80-160 BPM comfort zone is preferred when sub-band evidence is ambiguous

**Given** two BPM candidates with a ratio in the 3:1 range (2.85-3.15 tolerance)
**When** `resolveOctaveAmbiguity` runs
**Then** the candidates are recognized as a 3:1 pair and resolved using sub-band voting

**Given** the existing 2:1 octave disambiguation
**When** harmonic ratio detection is added
**Then** the existing behavior is unchanged for octave pairs (ratio 1.92-2.08)

**Given** the two known failing Prodigy tracks at triplet/2-3 time lock
**When** analyzed at intensity 7
**Then** both tracks resolve to the correct BPM (validated against DAW oracle)

**Given** `make ablation`
**When** the full technique matrix runs
**Then** all combinations complete without crashes and Acc1 does not regress

**Note:** This does NOT add a new `DSPTechnique` case. The harmonic ratio check extends existing `resolveOctaveAmbiguity` logic and activates whenever `subBandVoting` is in the technique set. Files: `BPMAnalyzer.swift` (resolveOctaveAmbiguity, confirmWithSubBandPeaks).

### Story 3.2: Fine-Grid Precision Fix

As a library author,
I want sub-BPM precision errors resolved,
So that tracks like Icicle (126.0 BPM detected as 125.9) are within tolerance of their true BPM.

**Acceptance Criteria:**

**Given** a unit test with a synthetic signal at exactly 126.0 BPM
**When** analyzed with fine-grid refinement at intensity 7
**Then** the detected BPM is 126.0 (not 125.9 or 126.1)

**Given** a fix is applied (finer grid, snap-to-nearest, or interpolation correction)
**When** DAW oracle tracks are analyzed
**Then** the Icicle track (126.0 BPM) resolves within 2% Acc1 tolerance
**And** no other DAW oracle tracks regress

**Given** `make oracle`
**When** three-way comparison runs
**Then** fine-grid precision errors on the DAW oracle set are reduced or eliminated

### Story 3.3: Click-Track Cross-Correlation

As a library author,
I want a click-track cross-correlation technique that validates BPM candidates against the onset envelope,
So that candidates with the best rhythmic alignment are preferred during disambiguation.

**Acceptance Criteria:**

**Given** a new `DSPTechnique` case `clickTrackCorrelation`
**When** added to the enum
**Then** `CaseIterable` automatically includes it and `TechniqueSet.allDSPCombinations()` generates 2^7=128 combinations

**Given** the technique is active for a set of BPM candidates
**When** each candidate is evaluated
**Then** a synthetic click track at that BPM is generated and cross-correlated with the onset envelope via the appropriate vDSP function (e.g., `vDSP_conv` with reversed kernel, or sliding `vDSP_dotpr`)
**And** the candidate with the highest cross-correlation magnitude is boosted

**Given** a unit test with a synthetic 120 BPM click track
**When** the technique runs with candidates [120.0, 60.0, 180.0]
**Then** 120.0 BPM has the highest cross-correlation score

**Given** `make ablation`
**When** the full 128-combination matrix runs
**Then** all combinations complete without crashes
**And** the technique is added to at least one `TechniqueSet` preset (or documented why excluded)

**Given** the `AnalysisIntensity.techniqueSet` mapping
**When** reviewed
**Then** `clickTrackCorrelation` is mapped to appropriate intensity levels based on ablation results

**Reference:** Brainstorm #62 -- click-track cross-correlation. Reuses `generateClickTrack` from test support. Single `vDSP_conv` call per candidate.

### Story 3.4: Duration-Derived BPM Hint

As a library author,
I want to use file duration as a weak prior for BPM disambiguation,
So that structurally plausible BPMs from common bar counts provide an additional zero-cost signal.

**Acceptance Criteria:**

**Given** an audio file with known duration
**When** duration is read from AVFoundation metadata
**Then** candidate BPMs are computed from common bar counts (32, 64, 96, 128, 192, 256) using `BPM = (Bars * 4 * 60) / DurationSeconds`

**Given** duration-derived candidates
**When** one matches a DSP candidate within 2% tolerance
**Then** the DSP candidate's confidence is boosted by a small weight (~0.1x)

**Given** a track with no readable duration metadata
**When** duration hint runs
**Then** no boost is applied (graceful no-op)

**Note:** Duration hint is applied during step 10 disambiguation (inside or adjacent to `resolveOctaveAmbiguity`), NOT as a new `DSPTechnique` case. It modifies candidate confidence scores before the final BPM selection. Files: `BPMAnalyzer.swift`.

**Given** `make benchmark`
**When** OA300 corpus runs
**Then** Acc1 does not regress (duration hint should only help or be neutral)

**Reference:** Brainstorm #35 -- Splice.com technique. Zero PCM cost. Particularly effective for electronic music with predictable bar structure.

### Story 3.5: Configurable Window Voting Policy

As a library author,
I want the window voting resolution policy to be configurable at runtime,
So that I can compile once and sweep through different voting strategies during benchmark runs without rebuilding.

**Acceptance Criteria:**

**Given** a new `VotingPolicy` public enum with cases like `.simpleMajority`, `.confidenceWeighted`, `.thresholdGated` and a separate `votingThreshold: Double` parameter where applicable
**When** passed as a parameter to `analyzeBPM()` or configured on the merge strategy
**Then** the window voting logic uses the specified policy at runtime
**And** `VotingPolicy` conforms to `CaseIterable`, `Sendable`, `Hashable` (no associated values -- threshold is a separate parameter)

**Given** a benchmark run
**When** iterating over voting policies
**Then** each policy produces Acc1/Acc2 results from the same pre-read audio (no re-read, no recompilation)
**And** results are printed per-policy for comparison (following the `benchmarkMergeStrategies` pattern)

**Given** the default configuration
**When** no voting policy is specified
**Then** the current behavior is preserved (backward compatible)

**Given** `make benchmark`
**When** comparing voting policies
**Then** the best-performing policy's Acc1 >= current `windowVoting` Acc1

---

## Epic 4: ML-Augmented Detection

Consumers can optionally add ML-augmented detection at intensity 8-10, getting better accuracy with zero impact on the core DSP-only library. Graceful degradation with actionable provenance.

**References:** Schreiber & Muller (2018) "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network" ([PDF](https://archives.ismir.net/ismir2018/paper/000068.pdf), [Code](https://github.com/hendriks73/tempo-cnn)). Apple: [BNNS](https://developer.apple.com/documentation/accelerate/bnns) (Accelerate), [BNNSGraph](https://developer.apple.com/documentation/accelerate/bnns/graph) (macOS 15+), [MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)), [MLShapedArray](https://developer.apple.com/documentation/coreml/mlshapedarray), [Bundle.module for SPM resources](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package). WWDC 2024-10159 "Bring your ML models to Apple silicon", WWDC 2022-10027 "Optimize your Core ML usage".

### Story 4.1: BoomBoomBoomKitML Package Structure

As a library author,
I want the `BoomBoomBoomKitML` SPM target created with the correct package structure,
So that consumers can optionally add ML-augmented detection without impacting the core library.

**Acceptance Criteria:**

**Given** `Package.swift`
**When** updated
**Then** a new library product `BoomBoomBoomKitML` exists with target `BoomBoomBoomKitML` depending on `BoomBoomBoomKit`
**And** the target has `resources: [.copy("Resources")]` for the model bundle

**Given** `Sources/BoomBoomBoomKitML/`
**When** created
**Then** it contains placeholder files for `BNNSTechnique.swift` and `CoreMLTechnique.swift`
**And** a `Resources/` directory exists for future `.mlmodelc` files

**Given** `BoomBoomBoomKit` core library
**When** built independently
**Then** it has zero imports of or references to `BoomBoomBoomKitML`
**And** `swift build` succeeds for both targets

**Given** a consumer's `Package.swift`
**When** they add only `BoomBoomBoomKit`
**Then** no CoreML dependency is pulled in
**When** they add `BoomBoomBoomKitML`
**Then** CoreML is available via `import CoreML` in the ML target only

### Story 4.2: Effective Intensity and Graceful ML Degradation

As an app developer,
I want to know when ML-augmented analysis degraded to DSP-only and why,
So that I can decide whether to add the ML package or adjust my configuration.

**Acceptance Criteria:**

**Given** `AudioAnalysisResult`
**When** a new `effectiveIntensity: AnalysisIntensity` field is added
**Then** it reports the actual intensity used for analysis

**Given** intensity 9 requested with `mlTechnique: nil`
**When** analysis runs
**Then** `effectiveIntensity` is 7 (capped at DSP-only max)
**And** a new `degradationReason: String?` field on `AudioAnalysisResult` contains an actionable explanation (e.g., "Requested intensity 9 requires BoomBoomBoomKitML package. Running at intensity 7 (DSP-only).")
**And** `degradationReason` is nil when no degradation occurred

**Given** intensity 9 requested with a valid `mlTechnique`
**When** analysis runs
**Then** `effectiveIntensity` is 9

**Given** intensity 5 requested (DSP-only range)
**When** analysis runs with or without `mlTechnique`
**Then** `effectiveIntensity` equals the requested intensity (no degradation)

**Given** a new `public func maximumSupportedIntensity(mlTechnique: (any MLTechnique)?) -> AnalysisIntensity`
**When** called with `nil`
**Then** returns 7
**When** called with a valid `MLTechnique`
**Then** returns 10

### Story 4.3: ML Technique Parameter Injection and Trace Population

As a library author,
I want `analyzeBPM` to accept an optional `MLTechnique` conformance via parameter injection,
So that the ML path integrates cleanly without the core library knowing about specific ML implementations.

**Acceptance Criteria:**

**Given** `AudioAnalysisService.analyzeBPM()`
**When** a new parameter `mlTechnique: (any MLTechnique)? = nil` is added
**Then** the default behavior (nil) is identical to current DSP-only analysis

**Given** `mlTechnique` is non-nil
**When** analysis runs
**Then** `BPMDiagnosticTrace` is built internally regardless of the `enableTrace` flag (ML needs it as input)
**And** the trace is only returned to the consumer when `enableTrace` is true

**Given** `mlTechnique` is non-nil and the pipeline completes
**When** the DSP result and trace are available
**Then** `MLTechnique.evaluate(candidates:trace:)` is called with the DSP candidates and trace
**And** the ML result is combined with the DSP result via the ensemble resolution policy

**Given** `MLTechnique.evaluate()` returns nil
**When** ensemble resolution runs
**Then** the DSP result carries unchanged (ML abstains)

### Story 4.4: Configurable ML Ensemble Voting Policy

As a library author,
I want the DSP+ML ensemble resolution policy to be configurable at runtime,
So that I can compile once and sweep through resolution strategies during benchmark runs.

**Acceptance Criteria:**

**Given** a new `EnsemblePolicy` public enum with cases like `.dspAlways`, `.mlWhenConfident(threshold: Double)`, `.highestConfidence`, `.quorum`
**When** passed as a parameter to `analyzeBPM()` or associated with the `mlTechnique`
**Then** the ensemble resolution uses the specified policy at runtime
**And** `EnsemblePolicy` conforms to `CaseIterable`, `Sendable`, `Hashable`

**Given** the conservative default policy
**When** no policy is specified
**Then** DSP wins unless ML confidence is high AND DSP confidence is low

**Given** a benchmark run with ML enabled
**When** iterating over ensemble policies
**Then** each policy produces Acc1/Acc2 from the same pre-read audio (compile once, sweep policies)
**And** results are printed per-policy for comparison

**Given** `EnsemblePolicy`
**When** designed
**Then** it follows the same pattern as `CandidateMergeStrategy`: public enum, `CaseIterable` (no associated values -- thresholds as separate parameters), `Sendable`, `Hashable`, runtime-configurable, benchmark-sweepable

**Given** `make ablation` with ML enabled
**When** the full matrix runs
**Then** ML + DSP accuracy is strictly >= DSP-only accuracy for the default policy (NFR8)

### Story 4.5: BNNS MLTechnique Conformance (Proof of Concept)

As a library author,
I want a BNNS-based `MLTechnique` conformance as the first real implementation,
So that the ML integration architecture is validated with zero new framework dependencies.

**Acceptance Criteria:**

**Given** `BNNSTechnique` in `Sources/BoomBoomBoomKitML/`
**When** initialized
**Then** it loads a trained model from `Bundle.module` resources
**And** the initializer is `throws` (model load can fail)
**And** `try? BNNSTechnique()` returns nil if the model resource is missing

**Given** a `BNNSTechnique` instance and a `BPMDiagnosticTrace`
**When** `evaluate(candidates:trace:)` is called
**Then** it returns an optional `(bpm: Double, confidence: Double)` based on model inference
**And** the model input is derived from trace features (sub-band energies, ACF shape, periodicity peaks)

**Given** BNNS lives inside Accelerate
**When** `BoomBoomBoomKitML` imports BNNS
**Then** no new framework dependency is added beyond what the core library already uses

**Given** a mock `MLTechnique` conformance in the test target
**When** ensemble voting tests run
**Then** deterministic test cases cover: ML agrees with DSP, ML disagrees with low confidence (DSP wins), ML disagrees with high confidence (ML wins), ML returns nil (DSP carries)

**Reference:** [BNNS](https://developer.apple.com/documentation/accelerate/bnns), [BNNSGraph](https://developer.apple.com/documentation/accelerate/bnns/graph) (macOS 15+). Schreiber CNN architecture is shallow enough for BNNS inference.

**Note:** ML model training is out of scope for Phase 3. This story validates the `MLTechnique` protocol architecture and DSP+ML ensemble plumbing using either a placeholder model or a minimal trained model. Production model quality is a separate concern. The mock `MLTechnique` in the test target provides deterministic testing independent of model quality.

### Story 4.6: CoreML MLTechnique Conformance (Production)

As a library author,
I want a CoreML-based `MLTechnique` conformance for Neural Engine acceleration,
So that ML inference at intensity 8-10 is fast enough for batch workflows on Apple Silicon.

**Acceptance Criteria:**

**Given** `CoreMLTechnique` in `Sources/BoomBoomBoomKitML/`
**When** initialized
**Then** it loads a `.mlmodelc` from `Bundle.module` via `MLModel.init(contentsOf:configuration:)` (throws)
**And** `try? CoreMLTechnique()` returns nil if the model resource is missing

**Given** a `CoreMLTechnique` instance
**When** `evaluate(candidates:trace:)` is called
**Then** it performs inference using CoreML (CPU, GPU, or Neural Engine as decided by the system)
**And** the input/output contract matches `BNNSTechnique` (same trace features, same return type)
**And** model input is provided via `MLShapedArray<Float>` (preferred over `MLMultiArray` for type safety)

**Given** `BoomBoomBoomKitML` with CoreML
**When** the ML target is built
**Then** only `CoreML` is added as a framework dependency (to the ML target only)

**Given** both `BNNSTechnique` and `CoreMLTechnique` exist
**When** a consumer passes either to `analyzeBPM(mlTechnique:)`
**Then** the API is identical -- consumer doesn't care which implementation runs

**Reference:** [MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)), [MLShapedArray](https://developer.apple.com/documentation/coreml/mlshapedarray), [Bundle.module](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package). WWDC 2024-10159, WWDC 2022-10027.

---

## Epic 5: Developer Experience & Demo

External developers can evaluate and adopt BoomBoomBoomKit through a visual demo app, clear documentation, quick-start guides, and batch workflow guidance.

### Story 5.1: Demo App Project Scaffold

As a developer evaluating BoomBoomBoomKit,
I want to clone the repo, open the demo project, and build it immediately,
So that I can start evaluating the library without reading source code.

**Acceptance Criteria:**

**Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj`
**When** created as a separate Xcode project
**Then** it references `../../Package.swift` as a local SPM dependency
**And** imports `BoomBoomBoomKit` (and optionally `BoomBoomBoomKitML`) via the local package

**Given** the demo app project
**When** opened in Xcode and built
**Then** it compiles and runs without errors on macOS 15+

**Given** the demo app
**When** inspected for internal type access
**Then** zero `@testable import` statements exist -- public API only

**Given** `.gitignore`
**When** updated
**Then** `Demo/**/build/` and `Demo/**/*.xcuserstate` are excluded

**Given** the demo app uses SwiftUI + `@Observable`
**When** the view model is created
**Then** `AnalysisViewModel` wraps `AudioAnalysisService` calls using only the public API

### Story 5.2: Core Analysis Flow (File Drop + BPM Display)

As a developer evaluating BoomBoomBoomKit,
I want to drop an audio file into the demo app and see the detected BPM, confidence, and effective intensity,
So that I can quickly evaluate detection accuracy on my own tracks.

**Acceptance Criteria:**

**Given** the demo app is running
**When** a user drops an audio file (WAV, MP3, FLAC, M4A, AIFF, CAF) onto the window
**Then** the app analyzes the file at the current intensity setting
**And** displays the detected BPM, confidence score, and effective intensity used

**Given** analysis at intensity 1-3
**When** result returns
**Then** the result appears near-instantly (no visible delay)

**Given** analysis at intensity 7+
**When** analysis is in progress
**Then** an activity indicator is shown until the result is ready

**Given** the analysis result
**When** displayed
**Then** wall-clock analysis time is shown alongside the BPM

### Story 5.3: Parameter Controls (Intensity + Merge Strategy)

As a developer evaluating BoomBoomBoomKit,
I want to adjust intensity level and merge strategy in the demo app and see results update,
So that I can compare configurations without writing code.

**Acceptance Criteria:**

**Given** the demo app
**When** an intensity slider (1-10) is adjusted
**Then** re-analysis runs with the new intensity and results update

**Given** the demo app
**When** a merge strategy dropdown is changed
**Then** re-analysis runs with the selected strategy and results update

**Given** the current parameter configuration
**When** a "Copy Config" button is tapped
**Then** a Swift code snippet is copied to the clipboard reflecting the exact parameters

### Story 5.4: Diagnostic Trace Visualization and Export

As a developer evaluating BoomBoomBoomKit,
I want to view diagnostic trace data in the demo app and export it,
So that I can understand how the pipeline arrived at a result without reading DSP code.

**Acceptance Criteria:**

**Given** analysis with `enableTrace: true`
**When** the trace view is shown
**Then** it displays: candidate list with scores, sub-band energies, disambiguation result, and which pipeline step selected the final BPM

**Given** the trace data
**When** an "Export" button is tapped
**Then** the trace is exported as JSON (machine-readable) for external plotting and analysis

### Story 5.5: Public API Documentation and README

As an app developer discovering BoomBoomBoomKit,
I want clear quick-start docs, nil-return documentation, and batch workflow guidance,
So that I can integrate the library confidently without DSP knowledge.

**Acceptance Criteria:**

**Given** `README.md`
**When** updated
**Then** it contains a quick-start code sample (3 lines to get a BPM from a file)
**And** documents all supported audio formats (removing any OGG reference)
**And** describes the intensity scale (1-10) with brief guidance on when to use each range

**Given** nil-return conditions
**When** documented
**Then** README explains when and why `analyzeBPM` returns nil: silence, too-short audio, unsupported sample rate (LUFS), cancelled analysis

**Given** batch workflow patterns
**When** documented
**Then** README includes guidance on: wrapping calls in a task queue, using progress callbacks, cancellation via Task, and preserving completed results

**Given** all public API types and methods
**When** reviewed
**Then** every public declaration has inline `///` documentation with `- Parameters:` and `- Returns:` where applicable

---

## References

### Academic Papers

- Schreiber, H. & Muller, M. (2018). "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network." ISMIR. [PDF](https://archives.ismir.net/ismir2018/paper/000068.pdf) / [Code](https://github.com/hendriks73/tempo-cnn)
- Davies, M. & Bock, S. (2019). "Temporal convolutional networks for musical audio beat tracking." EUSIPCO
- BEAST (2024). "Online Joint Beat and Downbeat Tracking Based on Streaming Transformer." ICASSP
- Hydari et al. (2021). "BeatNet: CRNN and Particle Filtering for Online Joint Beat, Downbeat and Meter Tracking." ISMIR
- Ellis, D.P.W. (2007). "Beat Tracking by Dynamic Programming." JNMR 36(1)
- Grosche, P. & Muller, M. (2011). "Extracting Predominant Local Pulse Information from Music Recordings." IEEE TASLP 19(6)
- Knees, P. et al. (2015). "Two Data Sets for Tempo Estimation and Key Detection." ISMIR. [PDF](https://archives.ismir.net/ismir2015/paper/000246.pdf)
- O'Shaughnessy, D. (1987). "Speech Communication: Human and Machine." Hz-to-mel conversion
- "Music Tempo Estimation: Are We Done Yet?" [TISMIR](https://transactions.ismir.net/articles/10.5334/tismir.43)

### Apple Frameworks & Documentation

- [BNNS (Accelerate)](https://developer.apple.com/documentation/accelerate/bnns) -- zero-dep ML inference
- [BNNSGraph (macOS 15+)](https://developer.apple.com/documentation/accelerate/bnns/graph) -- graph-based inference API
- [MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)) -- throws initializer
- [MLShapedArray](https://developer.apple.com/documentation/coreml/mlshapedarray) -- type-safe CoreML input
- [Bundling Resources with SPM](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package) -- Bundle.module
- WWDC 2024-10159: "Bring your ML and AI models to Apple silicon"
- WWDC 2022-10027: "Optimize your Core ML usage"
- ITU-R BS.1770-5 -- K-weighting standard for LUFS measurement

### Evaluation & Datasets

- [MIREX Audio Tempo Estimation](https://www.music-ir.org/mirex/wiki/2019:Audio_Tempo_Estimation)
- [mir_eval tempo.py](https://github.com/mir-evaluation/mir_eval/blob/main/mir_eval/tempo.py) -- 4% tolerance reference
- [GiantSteps Tempo Dataset](https://github.com/GiantSteps/giantsteps-tempo-dataset) -- 664 EDM tracks

### Competitive Libraries

- [spfk-tempo](https://github.com/ryanfrancesconi/spfk-tempo) -- Swift + Accelerate (closest competitor)
- [madmom](https://github.com/CPJKU/madmom) -- TCN-based (accuracy benchmark)
- [tempnetic](https://github.com/csteinmetz1/tempnetic) -- MobileNetV2 tempo
- [aubio](https://github.com/aubio/aubio), [essentia](https://github.com/MTG/essentia), [librosa](https://github.com/librosa/librosa)
- [Mixxx](https://github.com/mixxxdj/mixxx) -- Queen Mary vamp plugins
