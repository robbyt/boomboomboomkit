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
| FR46 | Epic 3 | New | File-embedded BPM metadata (iTunes `tmpo`, ID3 `TBPM`, Vorbis `BPM`) as corroboration signal — default-on, `.disabled` opt-out, direct container parsing |

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
**ADRs:** ADR-4 (eager model loading at init), ADR-5 (configurable ensemble voting), ADR-6 (trace populated for ML input), ADR-11 (Options-first public configuration — Story 3-3a)
**Phase:** 3C
**Dependencies:** Epic 3 establishes the best DSP baseline before ML augments it. ML is strictly additive (NFR8).
**Notes:** 7 stories total (4.1-4.7). BoomBoomBoomKitML as separate SPM product. Story 4.7 (spectral-flux DSP variant) addresses upstream onset-envelope weakness — recommended sequence: 4.7 → 4.5. BNNSGraph for BNNS (classic per-layer API deprecated, confirmed apple-docs 2026-05-04); CoreML conditional on 4.5 outcome (three branches). Mock MLTechnique in `BoomBoomBoomKitTestSupport` for deterministic ensemble tests. Pre-1.0 / no-BC framing throughout: minimum public types, defer enum cases, evolve freely. Planning session 2026-05-04 + Codex consultation thread `019df0ea-9b91-7173-866c-7f8e8efdc94e`.

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

### Story 2.4: OA300 Genre Labeling (Shrunken Scope)

As a library author,
I want every OA300 ground-truth entry to carry a non-optional `genre` label (sourced from the subdir for 74 tracks and from explicit per-track tags for 8 "Bad BPM" tracks, using the GiantSteps taxonomy plus an OA300-only `footwork` extension),
So that Story 2.5 (Genre-Stratified Accuracy Reporting) can bucket OA300 results per-genre without further schema work, and cross-corpus reports (OA300 + GiantSteps) share a vocabulary.

**Scope Notes:**
- **No corpus expansion.** Original ≥20-new-track scope cut — GiantSteps (661 electronic-genre-labeled tracks) already provides cross-genre diversity.
- **No manual listening.** All 82 entries tagged via deterministic subdir heuristic + 8 user-supplied Bad BPM tags.
- **Backwards-compat is not a goal.** `OA300Track.genre` flips from `String?` to `String`; malformed rows fail loudly at decode.

**Acceptance Criteria:**

**Given** the ground-truth fixture
**When** this story lands
**Then** all 82 entries carry a non-empty `genre: String` field appended at the end of each JSON object

**Given** the genre taxonomy
**When** defined
**Then** it is the 23 GiantSteps labels (`drum-and-bass, breaks, techno, tech-house, house, deep-house, electro-house, progressive-house, dubstep, trance, psy-trance, electronica, glitch-hop, chill-out, hardcore-hard-techno, indie-dance-nu-disco, hard-dance, dj-tools, minimal, pop-rock, reggae-dub, hip-hop, funk-r-and-b`) plus one OA300-only extension: `footwork` — 24 labels total

**Given** the 82 existing entries
**When** genre is assigned
**Then** subdir heuristic applies to 74 (T Tunes/null → `drum-and-bass`; R Tunes → `breaks`) and 8 Bad BPM tracks get explicit per-track tags (`03 TVR` → tech-house; `Icicle - Condense`, `Nautical Divine - Makara` → techno; `Echtoo - The Mummy` → footwork; rest → breaks)
**And** final distribution: `drum-and-bass=69, breaks=9, techno=2, tech-house=1, footwork=1`

**Given** the shared `OA300Track` struct
**When** this story lands
**Then** `genre: String?` flips to `genre: String` (non-optional) at `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:18`

**Given** `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py`
**When** this story lands
**Then** the hardcoded output path is removed, replaced with stdout-by-default + `--output PATH` flag, `ALLOWED_GENRES` is added as a module constant, and a "do not re-run" warning block is added to the docstring

**Given** `make benchmark`, `make oracle`, `make ablation`, `make perf-benchmark`, `make benchmark-giantsteps`
**When** run after this story lands
**Then** all five pass with no Acc1/Acc2 regression (Acc1 = 57/82 baseline)

**Note:** Replaces the original Story 2.4 (corpus expansion + genre backfill). Scope shrunk 2026-04-18 after validation uncovered that (a) file paths in the original story were wrong (test target reorganized after epic draft), (b) `OA300Track` is shared public not per-suite private, (c) `genre: String?` already existed, (d) GiantSteps already delivers cross-genre electronic diversity. Labeling half kept, expansion half cut.

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

### Story 2.6: Perf-Baselines File-Per-Run Redesign

As a library author,
I want each `make perf-benchmark` run to write an immutable per-run JSON file instead of appending to a single shared array file,
so that concurrent/repeated runs can't race or corrupt baselines, merge conflicts on a shared history file disappear, and regression comparisons become a trivial glob-and-sort at read time.

**Acceptance Criteria:**

**Given** the current append-only `Apple_M5_Max-26.json` array
**When** this story lands
**Then** `PerformanceBenchmarkTests.swift` is redesigned so each run writes one new single-object JSON file to `_bmad-output/perf-baselines/` via atomic temp-then-rename, and the read-modify-write `append(_:to:)` helper is removed

**Given** a per-run write
**When** the filename is constructed
**Then** it follows the template `{fingerprint}--{buildConfiguration}--{recordedAt-compact}--{gitSHA}--{shortUUID}.json` (double-hyphen separators, UTC ISO-8601 basic form, 8-char UUID suffix for collision-free construction)

**Given** the reader inside the Swift suite
**When** it computes `Δ vs last baseline:`
**Then** it globs the baseline dir, filters to the current `{fingerprint}--{buildConfiguration}--` prefix, decodes each, sorts by the JSON `recordedAt` field, and compares against the most recent record that is not the just-written one; temp files, dotfiles, and a single malformed file are warn+skipped without aborting the test

**Given** the legacy staging/mutex flow
**When** this story lands
**Then** `scripts/perf-commit.sh` is deleted outright (not archived), the `Makefile` `perf-benchmark` target runs `swift test` directly against `_bmad-output/perf-baselines/` with no tempdir, and no other file in the repo references the retired script

**Given** the existing `Apple_M5_Max-26.json` with 6 records
**When** migration runs
**Then** a one-shot `scripts/migrate-perf-baselines.py` emits 6 per-run files using each record's existing `recordedAt` + `gitSHA` + chip + osMajor, then the source array file and the migration script are both deleted in the same commit

**Given** `.claude/skills/running-benchmarks/SKILL.md`
**When** this story lands
**Then** it is rewritten to reflect the new design: the "never rewrite" invariant is replaced with per-run-file immutability, staging/mutex discussion is removed, `jq` recipes are rewritten for globbed multi-file input (`jq -s`), and a "Common mistakes" row is added for the concurrent-run CPU-contention timing caveat

**Note:** Replaces the Story 2.3 append-only+mutex+staging design. Codex-reviewed; atomic temp-then-rename is mandatory (not optional) — plain writes are not atomic at JSON-document level. User directive: delete retired scripts, do not archive.

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

### Story 3.6: BPM Metadata Corroboration Signal

As a DJ-tool developer consuming BoomBoomBoomKit,
I want embedded file-tag BPM metadata (iTunes `tmpo`, ID3 `TBPM`, Vorbis `BPM`) to corroborate the DSP estimate when present and trustworthy,
So that well-tagged library files converge faster and more accurately without sacrificing the library's DSP-first honesty on mistagged or untagged audio.

**Acceptance Criteria:**

**Given** a consumer importing `BoomBoomBoomKit`
**When** they inspect the public API
**Then** `MetadataPolicy` exists as a public `Sendable, Hashable` struct in `Sources/BoomBoomBoomKit/MetadataPolicy.swift`
**And** `MetadataSource` exists as a public `String, CaseIterable, Sendable, Hashable` enum with exactly `.iTunesTmpo`, `.id3TBPM`, `.vorbisBPM`
**And** `MetadataPolicy` exposes at least `.default` and `.disabled` named presets
**And** `MetadataPolicy.default.valueRange == 30.0...300.0`

**Given** `AudioAnalysisService.Options`
**When** a consumer creates a default `Options` instance
**Then** `options.metadataPolicy == .default` (metadata corroboration is ON by default)
**And** setting `options.metadataPolicy = .disabled` disables all metadata I/O and merge-stage boosting

**Given** `AudioAnalysisResult`
**When** `analyzeBPM` returns
**Then** the result exposes a public `metadataEvidence: [MetadataBPMEvidence]` array
**And** each element carries `source`, `rawValue`, `parsedBPM`, `corroboratedWith`, `ratioMatched`, `boostApplied`, `rejectionReason`

**Given** an M4A file containing a valid `moov/udta/meta/ilst/tmpo` atom (e.g., OA300 fixture `03 TVR.m4a` in the "Bad BPM" subfolder)
**When** `FileMetadataReader` reads the file
**Then** the `tmpo` int16 is parsed via direct container parsing (not `AVAsset.commonMetadata`)
**And** `source == .iTunesTmpo`
**And** `tmpo == 0` is treated as absent

**Given** an MP3 file with ID3v2 `TBPM` frames
**When** `FileMetadataReader` reads the file
**Then** the ID3v2 header is parsed directly and the `TBPM` text frame is located
**And** two or more `TBPM` frames with conflicting parsed values are treated as an intra-file conflict

**Given** a FLAC file with a Vorbis comment `BPM=` entry (case-insensitive key)
**When** `FileMetadataReader` reads the file
**Then** the Vorbis comment block is parsed directly from FLAC metadata blocks
**And** `source == .vorbisBPM`

**Given** parsed raw tag strings under `MetadataPolicy.default`
**When** hygiene rules apply
**Then** whitespace/BOM is stripped; locale decimal comma accepted (`"128,5"` → `128.5`); range midpoint accepted (`"120-125"` → `122.5`); non-numeric rejected with `rejectionReason`; values outside `valueRange` rejected with `rejectionReason == "out-of-range"`

**Given** two or more enabled sources present in a file that agree within ±0.5 BPM absolute
**When** consensus is computed
**Then** the tags are treated as "unanimous consensus"
**And** the consensus value is the arithmetic mean

**Given** two or more enabled sources where at least one pair disagrees by more than ±0.5 BPM
**When** consensus is computed
**Then** ALL tags are rejected for decision purposes (no boost)
**And** each is recorded in `metadataEvidence` with `rejectionReason == "intra-file-conflict"`

**Given** a tag (single source or unanimous) with parsed BPM `T`
**When** a DSP candidate `C` satisfies `|C - T| / T <= 0.03`
**Then** the tag is corroborated at same-tempo
**And** `ratioMatched == nil`, `corroboratedWith == C`

**Given** a tag with parsed BPM `T` that does not match any DSP candidate at same-tempo
**When** existing `resolveOctaveAmbiguity` (2:1) or Story 3.1 (3:2, 3:1) resolves `T` and some DSP candidate to the same underlying tempo
**Then** the tag is corroborated at ratio
**And** `ratioMatched` is populated with the matched `HarmonicRatio`
**And** triplet (3:2) corroboration is gated OFF until Story 3.1 ships

**Given** a corroborated tag (single-source or unanimous, same-tempo or ratio-matched)
**When** `CandidateMergeStrategy.merge` runs across windows
**Then** the corresponding candidate's confidence is multiplied by `1.25` and clamped to `0.95` (never reaches `1.0`)
**And** `boostApplied` records the multiplier
**And** the boost is applied inside `merge` (cross-window), NOT solely inside BPMAnalyzer step 10

**Given** a unanimous-consensus tag set that does NOT corroborate any DSP candidate
**When** `analyzeBPM` returns
**Then** the DSP-chosen BPM is returned (tag value does NOT override DSP)
**And** the winning candidate's confidence is multiplied by `0.85` (skepticism penalty)
**And** each evidence entry carries `rejectionReason == "dsp-disagreement"`

**Given** `options.intensity = .fastest`
**When** `analyzeBPM` runs on a tagged file
**Then** `FileMetadataReader` is still invoked and evidence is populated
**And** metadata reading is NOT gated by `AnalysisIntensity` or `DSPTechnique`

**Given** `metadataPolicy = .disabled`
**When** `analyzeBPM` runs
**Then** `FileMetadataReader` is NOT invoked (no file I/O for metadata)
**And** `result.metadataEvidence.isEmpty == true`
**And** returned BPM, confidence, and candidate set are byte-identical to the pre-Story-3.6 pipeline (regression guard on OA300/GiantSteps)

**Given** the `DSPTechnique` enum and `TechniqueSet` API
**When** this story lands
**Then** `DSPTechnique.allCases.count == 6` (unchanged)
**And** `TechniqueSet.allDSPCombinations().count == 64` (2^6 regression guard)
**And** no new case is added to `DSPTechnique` for metadata

**Given** `enableTrace: true` and a file producing metadata evidence
**When** `analyzeBPM` returns
**Then** `BPMDiagnosticTrace` includes per-source raw strings, parsed values, consensus outcome, corroboration outcome, and applied boost/penalty

**Given** the OA300 benchmark run under `make benchmark`
**When** Story 3.6 lands with default policy ON
**Then** Acc1 does not regress below the pre-story baseline; Acc2 does not regress below the pre-story baseline
**And** the benchmark report includes a "tagged-subset" breakdown: count of OA300 tracks where metadata was found, corroborated the DSP winner, was rejected intra-file, or disagreed with DSP

**Given** the OA300 fixture `03 TVR.m4a`
**When** the test suite runs with `metadataPolicy = .default`
**Then** an explicit test asserts the `tmpo` atom is read and `MetadataBPMEvidence` is emitted with `source == .iTunesTmpo`

**Note:** Metadata is deliberately NOT a `DSPTechnique` — it is a file-level corroboration signal orthogonal to DSP. Lives in `AudioAnalysisService` wiring, standalone `FileMetadataReader`, and a boost hook inside `CandidateMergeStrategy.merge` (not in BPMAnalyzer step 10). The confidence boost is intentionally multiplicative (`1.25×` clamped at `0.95`) and cannot reach `1.0` because third-party taggers may share failure modes with our DSP (correlated false positives). Ratio corroboration reuses existing `resolveOctaveAmbiguity` (2:1) plus Story 3.1's `HarmonicRatio` path (3:2, 3:1) — no new ratio math in this story. Direct container parsing (not `AVAsset.commonMetadata`) avoids AVFoundation deprecation risk and Vorbis unreliability. No stable public API yet — breaking changes to `Options` and `AudioAnalysisResult` acceptable.

**Files:** `MetadataPolicy.swift` (new), `FileMetadataReader.swift` (new, ~150 LOC across MP4/ID3/Vorbis parsers), `AudioAnalysisService.swift` (wire read-once before window loop), `CandidateMergeStrategy.swift` (boost hook), `BPMDiagnosticTrace.swift` (trace fields). Tests: `FileMetadataReaderTests.swift`, `MetadataCorroborationTests.swift`. Benchmark: `OA300BenchmarkTests.swift` (tagged-subset breakdown).

**Reference:** ISO/IEC 14496-12 (`moov/udta/meta/ilst/tmpo`). ID3v2.4 §4.2 text frames (`TBPM`). Xiph.org Vorbis comment spec. Depends on Story 3.1 (`HarmonicRatio`) for triplet corroboration.

---

## Epic 4: ML-Augmented Detection

Consumers can optionally add ML-augmented detection at intensity 8-10, getting better accuracy with zero impact on the core DSP-only library. Graceful degradation with actionable provenance.

**Planning decisions (2026-05-04):** Acceptance gates split by story type — 4.3/4.5/4.6 require numeric Acc1/Acc2 delta gates; 4.1/4.2/4.4 require hard non-regression gates with snapshot artifacts (NOT a delta-or-inertness escape hatch). New Story 4.7 (spectral-flux onset DSP variant) addresses the upstream onset-envelope weakness on heavily-mastered DnB material — recommended sequencing is 4.7 → 4.5 so BNNS feature design knows the post-spectral-flux baseline. Story 4.6 acceptance is conditional on Story 4.5 outcome (three branches written into 4.6 spec). Pre-1.0 / no-BC framing applied throughout: minimum public types now, add fields per-story; `EnsemblePolicy` enum cases deferred to Story 4.4 author after 4.5 ablation. Codex consultation: thread `019df0ea-9b91-7173-866c-7f8e8efdc94e`.

**Definitions used in Epic 4 acceptance criteria:**

- **Asserted floors** — the `#expect`-locked corpus accuracy floors in the benchmark test suite: OA300 Acc1 ≥ 57/82, OA300 Acc2 ≥ 73/82 (`Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:105,109,130,134`); GiantSteps Acc1 ≥ 537/661, GiantSteps Acc2 ≥ 546/661 (`Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift`). These fire on every CI invocation regardless of preset/policy membership.
- **Current snapshot** (as of 2026-05-04 / Epic 3 close-out) — observed live accuracy with all default features enabled: OA300 Acc1=58/82 (70.7%), Acc2=74/82 (90.2%); GiantSteps Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). The snapshot is what the asserted floors guard regression FROM; it is NOT itself an asserted floor. Snapshots are re-captured at each story's first dev commit and at story merge time; the ratio between snapshot-and-floor is the headroom we have for Epic 4 work.
- **Byte-identical** — `Double.bitPattern` equality on `bpm` and `confidence`, element-wise on `candidates`. Established by Story 3-6 paired-test pattern (`AudioAnalysisService.runPreCorroborationPipeline` shared between production and the disabled-policy bitPattern test; project-context.md "Byte-equality opt-out tests" rule). Does NOT include wall-clock, timestamp-bearing artifacts, or log-ordering.
- **Non-regression gate** — for stories 4.1/4.2/4.4: (a) all asserted floors hold AND (b) per-track BPM JSON output is byte-identical to the pre-story baseline snapshot, captured to `_bmad-output/implementation-artifacts/{story}-regression-snapshot.json` BEFORE the story's first dev commit and verified at PR time. The snapshot Acc1/Acc2 numbers are informational; the byte-equality is the test-enforceable assertion.
- **Numeric delta gate** — for stories 4.3/4.5/4.6/4.7: (a) all asserted floors hold AND (b) the story-specific Acc1/Acc2 delta target (named in the story's AC) is met OR Completion Notes document inertness with the impact-report JSON as evidence (see story for which path is permitted).
- **New Makefile targets** — Stories 4.1, 4.4, 4.5, 4.6, 4.7 each introduce a new Makefile target (`compile-model`, `ml-policy-sweep`, `bnns-impact-report`, `coreml-impact-report`, `spectral-flux-impact-report` respectively). All `*-impact-report` targets MUST follow the existing pattern in `Makefile:98-114` (`click-impact-report`, `duration-impact-report`): env-gated on `OA300_CORPUS_PATH` plus a feature-specific env flag (e.g. `BNNS_IMPACT=1`), output directory env override (e.g. `BNNS_IMPACT_OUT_DIR`), invokes `swift test --filter <BenchmarkSuite>`. The Makefile additions are part of each story's first-commit deliverable, not deferred.

**References:** Schreiber & Muller (2018) "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network" ([PDF](https://archives.ismir.net/ismir2018/paper/000068.pdf), [Code](https://github.com/hendriks73/tempo-cnn)). Apple: [BNNS library overview](https://developer.apple.com/documentation/accelerate/bnns-library) — classic `BNNS.*Layer` / `BNNSFilterCreateLayer*` API surface is deprecated (`classic-bnns-api` collection); use [BNNSGraph](https://developer.apple.com/documentation/accelerate/bnnsgraph) reading `.mlmodelc` instead. [MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)), [MLShapedArray](https://developer.apple.com/documentation/coreml/mlshapedarray), [Bundle.module for SPM resources](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package). WWDC 2024-10159 "Bring your ML models to Apple silicon" (Core ML Tools converter — applies to training/conversion that produces the `.mlmodelc`, NOT to the runtime Swift code that loads it). WWDC 2022-10027 "Optimize your Core ML usage" (still accurate but predates `MLShapedArray`-preferred patterns). Music-IR onset-detection literature: Bello et al. "A Tutorial on Onset Detection in Music Signals" (referenced by Story 4.7 spectral-flux variant).

### Story 4.1: BoomBoomBoomKitML Package Structure

As a library author,
I want the `BoomBoomBoomKitML` SPM target created with the correct package structure,
So that consumers can optionally add ML-augmented detection without impacting the core library.

**Acceptance Criteria:**

**Given** `Package.swift`
**When** updated
**Then** a new library product `BoomBoomBoomKitML` exists with target `BoomBoomBoomKitML` depending on `BoomBoomBoomKit`
**And** the target has `resources: [.copy("Resources")]` for the model bundle (`.copy`, NOT `.process`, because `.mlmodelc` is a directory that must be preserved as a tree)

**Given** `Sources/BoomBoomBoomKitML/`
**When** created
**Then** it contains placeholder files for `BNNSTechnique.swift` and `CoreMLTechnique.swift`
**And** a `Resources/` directory exists for `.mlmodelc` files

**Given** `BoomBoomBoomKit` core library
**When** built independently
**Then** it has zero imports of or references to `BoomBoomBoomKitML`
**And** `swift build` succeeds for both targets

**Given** a consumer's `Package.swift`
**When** they add only `BoomBoomBoomKit`
**Then** no CoreML dependency is pulled in
**When** they add `BoomBoomBoomKitML`
**Then** CoreML is available via `import CoreML` in the ML target only

**Given** the `Makefile`
**When** the `compile-model` target is invoked
**Then** `xcrun coremlc compile <input>.mlmodel <output_dir>` produces a `.mlmodelc` directory under `Sources/BoomBoomBoomKitML/Resources/`
**And** the source `.mlmodel` artifact lives outside the runtime target (e.g. in `_bmad-output/ml-models/` or a sibling tooling directory) for reproducibility — the runtime target ships only the compiled `.mlmodelc`

**Given** `BoomBoomBoomKitML` ships its own `Bundle.module` (distinct from `BoomBoomBoomKit`'s)
**When** loaded from `BNNSTechnique` or `CoreMLTechnique`
**Then** the load path uses that target's `Bundle.module`, NEVER `BoomBoomBoomKit`'s

**Non-regression gate (A1, applies to Story 4.1):**

**Given** Story 4.1 ships only package scaffolding
**When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
**Then** the non-regression gate per Epic 4 Definitions holds — i.e. asserted floors hold (OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82, GiantSteps Acc1 ≥ 537/661, Acc2 ≥ 546/661) AND per-track BPM JSON output is byte-identical to the pre-Story-4.1 snapshot captured at `_bmad-output/implementation-artifacts/4-1-regression-snapshot.json`
**And** the snapshot is captured BEFORE the Story 4.1 first dev commit and verified at PR time (current snapshot reference: OA300 Acc1=58/82, Acc2=74/82, GiantSteps Acc1=537/661, Acc2=546/661)
**And** Completion Notes link to BOTH the regression snapshot AND the package-boundary proof `_bmad-output/implementation-artifacts/4-1-package-boundary-proof.txt` (output of `swift package show-dependencies --format json | jq` confirming no CoreML in `BoomBoomBoomKit` dependency tree)

**Note:** This story scaffolds the package boundary. It is structurally inert by design — no DSP behavior changes. The non-regression gate IS the success criterion, NOT an "inertness escape hatch" (Epic 4 planning session decision 2026-05-04). Story 4.1 promotion is NOT blocked on the DnB triplet ground-truth verification (which gates 4.3/4.5/4.6 promotion only — see Story 4.5).

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

**Non-regression gate (A1, applies to Story 4.2):**

**Given** Story 4.2 ships result-field plumbing only (`effectiveIntensity`, `degradationReason`, `maximumSupportedIntensity`)
**When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
**Then** the non-regression gate per Epic 4 Definitions holds — asserted floors hold AND per-track BPM JSON output is byte-identical to the pre-Story-4.2 snapshot at `_bmad-output/implementation-artifacts/4-2-regression-snapshot.json`
**And** the snapshot is captured BEFORE the Story 4.2 first dev commit and verified at PR time
**And** Completion Notes link to the snapshot artifact

**Note:** A reporting-surface story cannot move accuracy. If 4.2 changes a single track outcome, something is wrong (Epic 4 planning session decision 2026-05-04).

### Story 4.3: ML Technique Slot Wiring + Tuple→Struct Migration

As a library author,
I want `analyzeBPM` to honour the `mlTechnique` field already reserved on `AudioAnalysisService.Options`, with `MLTechnique` migrated from labeled-tuple signatures to named `Sendable` structs,
So that the ML path integrates cleanly without the core library knowing about specific ML implementations, without growing the `analyzeBPM` parameter list (ADR-11), and without compiler-invisible Sendable holes.

**Acceptance Criteria:**

**Given** the current `MLTechnique` protocol at `Sources/BoomBoomBoomKit/DSPTechnique.swift:197-200` uses labeled tuples that bypass `Sendable` (deferred-work entry from Story 3-3a code review)
**When** Story 4.3 ships
**Then** `MLTechnique` is replaced with named `Sendable` structs:
```swift
public struct MLEvaluation: Sendable {
    public let bpm: Double
    public let confidence: Double
}
public protocol MLTechnique: Sendable {
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?
}
```
**And** the protocol input is `BPMDiagnosticTrace` only — DSP candidates are already in the trace via `BarCandidate`; no separate `candidates: [(bpm, score)]` parameter
**And** the return is `Optional<MLEvaluation>` where `nil` means "model declines to evaluate, defer to DSP"
**And** `MLEvaluation` carries ONLY `bpm` + `confidence` for now — fields like `modelIdentifier`, `alternateCandidates`, `featureSetVersion`, `featureSummary` are added per-story when a downstream story actually consumes them (pre-1.0 / no-BC framing — Epic 4 planning session decision 2026-05-04)

**Given** `AudioAnalysisService.analyzeBPM(url:options:)` and the `mlTechnique` field already reserved on `AudioAnalysisService.Options` by Story 3-3a
**When** the evaluation path is wired against `options.mlTechnique` (per ADR-11 — no new method parameter)
**Then** the default behavior (`options.mlTechnique == nil`) is byte-identical to current DSP-only analysis

**Given** `options.mlTechnique` is non-nil
**When** analysis runs
**Then** `BPMDiagnosticTrace` is built internally regardless of the `enableTrace` flag (ML needs it as input)
**And** the trace is only returned to the consumer when `enableTrace` is true

**Given** a new internal caseless-enum namespace `EnsembleCombiner` in `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` (parallel to `MetadataCorroborator`)
**When** the pipeline completes both DSP and ML evaluation
**Then** `EnsembleCombiner.combine(dspWinner:mlEvaluation:...)` resolves the final BPM
**And** ML runs AFTER `MetadataCorroborator.apply` — pipeline ordering is `merge → MetadataCorroborator.apply → MLTechnique.evaluate → EnsembleCombiner.combine → AudioAnalysisResult`
**And** Story 4.3 ships ONLY the smallest internal default-DSP path needed to make `EnsembleCombiner.combine` compile and behave (e.g. an internal flag, a private function dispatch, or a single-case internal enum) — Story 4.3 does NOT introduce the public `EnsemblePolicy` type or any of its cases; that lands in Story 4.4 with case names chosen by 4.4 author based on 4.5 ablation evidence (per Story 4.4 deferral decision)

**Given** `MLTechnique.evaluate()` returns nil
**When** `EnsembleCombiner.combine` runs
**Then** the DSP result carries unchanged (ML abstains, no behavior change)

**Numeric delta gate (A1, applies to Story 4.3 default-disabled path):**

**Given** Story 4.3 ships with default `options.mlTechnique == nil`
**When** `make benchmark` and `make benchmark-giantsteps` run pre-merge with no `mlTechnique` set
**Then** the non-regression gate per Epic 4 Definitions holds — asserted floors hold AND per-track BPM JSON output is byte-identical to the pre-Story-4.3 snapshot at `_bmad-output/implementation-artifacts/4-3-regression-snapshot.json` (the default-disabled path is non-regression — no escape hatch)
**And** the snapshot is captured BEFORE the Story 4.3 first dev commit and verified at PR time
**And** Completion Notes link to the snapshot artifact

**Perf-non-regression gate (A1 addendum, applies to Story 4.3 mock-on-but-abstaining path):**

**Given** Story 4.3 builds `BPMDiagnosticTrace` unconditionally when `options.mlTechnique != nil` (ML needs trace as input — see AC above)
**When** the mock `MLTechnique` returns nil (ML-on-but-abstaining hot path)
**Then** `make perf-benchmark` wall-clock regresses ≤ 10% vs the pre-Story-4.3 baseline at the same intensity
**And** Completion Notes link to the perf-baseline JSON record showing the delta

**Mock and decision-table deliverables:**

**Given** a mock `MLTechnique` conformance in `Sources/BoomBoomBoomKitTestSupport/` (per project-context.md SPM-targets rule: shared fixtures + helpers belong in TestSupport so consuming packages can use them)
**And** the `BoomBoomBoomKitTestSupport` target in `Package.swift:16-20` is updated to depend on `BoomBoomBoomKit` (currently has no `dependencies:` line — required for the mock to `import BoomBoomBoomKit` and conform to `MLTechnique`)
**When** the mock returns `MLEvaluation(bpm: 160.0, confidence: 1.0)` (or other deterministic injected values)
**When** unit tests run with the mock injected on a hand-picked set of ~5 synthetic cases
**Then** `_bmad-output/implementation-artifacts/4-3-mock-ensemble-trace.json` is produced with deterministic decisions, e.g.:
```json
{
  "case": "dsp_high_conf_ml_disagrees",
  "dsp": {"bpm": 120, "conf": 0.9},
  "ml":  {"bpm": 60,  "conf": 0.7},
  "ensemble": {"bpm": 120, "source": "dsp", "reason": "dsp_confidence_dominates"}
}
```
**And** the deterministic test-derived artifact validates the ensemble-combine logic without requiring a real model

**Note:** ADR-11 (Options-first public configuration) governs. The `mlTechnique` slot was reserved on `AudioAnalysisService.Options` by Story 3-3a (with a passing test asserting inertness until this story lands). Pre-1.0 / no-BC framing per "Public API Discipline (pre-1.0)" subsection in `_bmad-output/project-context.md`: minimum struct shape now, evolve freely as later stories surface concrete needs. Sequencing: Story 4.2 (which lands the mock if scoped that way) may gate Story 4.3 — to be confirmed when 4.3 author drafts.

### Story 4.4: Configurable ML Ensemble Voting Policy

As a library author,
I want the DSP+ML ensemble resolution policy to be configurable at runtime,
So that I can compile once and sweep through resolution strategies during benchmark runs.

**Acceptance Criteria:**

**Given** the `EnsemblePolicy` public enum
**When** Story 4.4 ships
**Then** the enum case list is determined by the Story 4.4 author based on what Story 4.5 BNNS ablation actually reveals about ML confidence behavior — NOT pre-locked from this Epic 4 spec (pre-1.0 / no-BC framing — Epic 4 planning session decision 2026-05-04; original spec proposals `.dspAlways`, `.mlWhenConfident(threshold:)`, `.highestConfidence`, `.quorum` are illustrative starting points only)

**Given** the locked design invariants (regardless of which cases land)
**When** Story 4.4 specs the type
**Then** `EnsemblePolicy` follows ADR-11 (lives on `AudioAnalysisService.Options`, NOT as a method parameter on `analyzeBPM`)
**And** conforms to `Sendable, Hashable` (and `CaseIterable` if associated values permit; otherwise document why)
**And** has a deterministic default value
**And** the default value produces byte-identical-to-DSP-only output when `options.mlTechnique == nil` AND when no real `MLTechnique` is available
**And** there is an explicit no-ML / DSP-only path (the default value satisfies this until Story 4.5/4.6 land a real model)
**And** corpus non-regression holds with the default policy per Epic 4 Definitions (asserted floors AND byte-identical to pre-Story-4.4 snapshot — see the Story 4.4 non-regression gate below for the operational expression)

**Given** a benchmark sweep with a real `MLTechnique` enabled (post Story 4.5)
**When** iterating over `EnsemblePolicy` cases
**Then** each policy produces Acc1/Acc2 from the same pre-read audio (compile once, sweep policies — pattern from Story 3-5 `benchmarkVotingPolicies`)
**And** results are printed per-policy for comparison
**And** Completion Notes document the empirical default-value pick

**Given** a new `make ml-policy-sweep` target (or equivalent benchmark sweep entry point)
**When** run with a real `MLTechnique` injected
**Then** the per-policy results inform the Story 4.4 default-value choice

**Given** `make ablation` with ML enabled (post Story 4.5)
**When** the full matrix runs
**Then** ML + DSP accuracy is strictly ≥ DSP-only accuracy for the default policy (NFR8)

**Non-regression gate (A1, applies to Story 4.4):**

**Given** Story 4.4 ships the policy enum + default value, but no real `MLTechnique` exists yet (Story 4.5 has not landed)
**When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
**Then** the non-regression gate per Epic 4 Definitions holds — asserted floors hold AND per-track BPM JSON output is byte-identical to the pre-Story-4.4 snapshot at `_bmad-output/implementation-artifacts/4-4-regression-snapshot.json`
**And** `Options.ensemblePolicy` default produces `result.bpm == dspResult.bpm` with `Double.bitPattern` equality regardless of `mlTechnique` value (this is the operational definition of "structurally inert")
**And** the snapshot is captured BEFORE the Story 4.4 first dev commit and verified at PR time
**And** Completion Notes link to the snapshot artifact

**Note:** Pre-locking the enum case list (`.dspAlways`, `.mlWhenConfident`, `.highestConfidence`, `.quorum` were the original Epic 4 spec proposals) was DROPPED at the Epic 4 planning session (2026-05-04). Codex consultation (thread `019df0ea-9b91-7173-866c-7f8e8efdc94e`) recommended deferral: "policy cases should follow observed BNNS/CoreML confidence behavior, not precede it." Story 4.4 author proposes cases based on Story 4.5 BNNS ablation evidence.

### Story 4.5: BNNS MLTechnique Conformance (Proof of Concept)

As a library author,
I want a BNNSGraph-based `MLTechnique` conformance reading the same `.mlmodelc` artifact that Story 4.6 will consume,
So that the ML integration architecture is validated with zero new framework dependencies (BNNS lives inside Accelerate) and Story 4.6 inherits a symmetric load path.

**Acceptance Criteria:**

**Given** `BNNSTechnique` in `Sources/BoomBoomBoomKitML/`
**When** initialized
**Then** it loads a precompiled model via `BNNSGraphCompileFromFile` from `Bundle.module.url(forResource: "model", withExtension: "mlmodelc")`
**And** the initializer is `throws` (model load can fail)
**And** `try? BNNSTechnique()` returns nil if the model resource is missing
**And** the same `.mlmodelc` artifact is consumable by `MLModel.init(contentsOf:)` in Story 4.6 (symmetric load path; one bundling pattern per Epic 4)

**Given** Apple's classic `BNNS.*Layer` / `BNNSFilterCreateLayer*` API surface is deprecated (the `classic-bnns-api` collection on Apple's BNNS landing page)
**When** Story 4.5 chooses the BNNS API surface
**Then** it uses `BNNSGraph.Builder` / `bnns_graph_t` / `BNNSGraphCompileFromFile` only — NEVER the deprecated direct-layer API (no `BNNSFilterCreateLayerConvolution`, etc.)

**Given** a `BNNSTechnique` instance and a `BPMDiagnosticTrace`
**When** `evaluate(trace:)` is called (per Story 4.3 protocol shape: `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`)
**Then** it returns `MLEvaluation?` based on model inference
**And** the model input is derived from trace features that are robust to clipped/limited material — at minimum log-mel-spectrogram with per-sub-band z-score normalization across the time axis (NOT raw onset-envelope peaks alone — the upstream weakness identified by Epic 3 retro footnote)
**And** the dev verifies during DD-block authoring whether log-compression of the mel-spectrogram is currently applied in `MelFilterbank` or downstream in `BPMAnalyzer.computeMelSpectrogram`; if not log-compressed today, Story 4.5 adds the log step with a paired byte-equality opt-out test
**And** the model input tensor shape and stride layout are declared explicitly in code AND documented in Completion Notes (e.g. NCHW row-major with N=1, C=1, H=mel_bands, W=time_frames) — Story 4.6 inherits this exact layout to keep `MLShapedArray<Float>` strides matching

**Pre-promotion ground-truth verification gate (applies to Stories 4.3 / 4.5 / 4.6):**

**Given** Stories 4.3 / 4.5 / 4.6 cannot move from `backlog` to `ready-for-dev` until the 4 DnB triplet ground-truth bookkeeping is complete (Story 4.1 promotion is NOT blocked — it is inert scaffolding; Codex consultation 2026-05-04)
**When** the user runs the pre-promotion check
**Then** an artifact `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` exists with schema:
```json
{
  "schema_version": 1,
  "targets": [
    {
      "track_id": "<oa300_filename_stem>",
      "ground_truth_bpm": 160.0,
      "source": "dawproject|daw_oracle",
      "current_predicted_bpm": <number>,
      "current_abs_error": <number>
    }
  ],
  "regression_threshold": {
    "min_resolved": 2,
    "tolerance_bpm": 0.5,
    "min_oa300_acc1": 58,
    "min_giantsteps_acc1": 537
  }
}
```
**And** all 4 `track_id` values resolve to existing files in `OA300_CORPUS_PATH` (Charly @ 160, Faraday_Bunker @ 170, Yin Yang Audio @ 170 DAW, HEFT_Anagram 6 @ 170 DAW)
**And** all 4 entries have a non-null `source` proving DAW oracle / dawproject ground truth exists; if any are missing, regenerate via `make oracle-generate` BEFORE Story 4.3 promotion
**And** the `current_predicted_bpm` and `current_abs_error` values are populated by running the current default pipeline against each track at gate-creation time AND re-frozen as the named-track baseline that Story 4.5's T2 non-regression assertion compares against (NOT a re-run at PR time — re-run risks per-track non-determinism via NTP-style drift in benchmark wall-clock, even though per-track BPM is deterministic)
**And** the JSON example values shown above (`<oa300_filename_stem>`, `<number>`) are placeholders; the populated artifact uses literal strings and numbers (e.g. `"track_id": "charly_xx"`, `"ground_truth_bpm": 160.0`, `"current_predicted_bpm": 106.2`)

**T2 — Numeric delta gate (A1, applies to Story 4.5):**

**Given** Story 4.5 BNNS is enabled at intensity 8+ via `options.mlTechnique = try BNNSTechnique()` AND `options.intensity = .thorough` (or higher)
**When** `make bnns-impact-report` runs against the 4 DnB triplet targets
**Then** ≥ 2 of the 4 named tracks must be detected within ±0.5 BPM strict Acc1 of their named ground-truth value
**And** NO track in the named set may regress in absolute BPM error vs the Story 3-1 / 3-6 baseline (cannot trade Charly+HEFT wins for breaking Faraday_Bunker — corpus floors are a per-track invariant on the named set)
**And** asserted floors hold per Epic 4 Definitions (≥57/82 OA300 Acc1, ≥73/82 OA300 Acc2, ≥537/661 GiantSteps Acc1, ≥546/661 GiantSteps Acc2) AND the BNNS-on path does NOT regress vs the current snapshot (OA300 Acc1=58, Acc2=74, GiantSteps Acc1=537, Acc2=546) — i.e. BNNS may improve named-track resolution but cannot trade Charly+HEFT wins for breaking Faraday_Bunker AND cannot regress overall corpus from snapshot
**And** Acc1 must NOT regress below 58/82 with the BNNS-on path active at default intensity (the BNNS-on path may not be worse than DSP-only at the default config it ships under)

**HALT trigger (per Epic 4 retro action item T2):**

**Given** Story 4.5 BNNS resolves < 2 of 4 named DnB triplets
**When** Story 4.5 close-out is being authored
**Then** Completion Notes MUST document per-track failure modes with the impact-report JSON as evidence
**AND** Story 4.6 enters Branch C (paused, converted to research/training-data spike — see Story 4.6 spec)

**Mock and impact-report deliverables:**

**Given** the mock `MLTechnique` conformance in `Sources/BoomBoomBoomKitTestSupport/` (added in Story 4.3)
**When** ensemble voting tests run
**Then** deterministic test cases cover: ML agrees with DSP, ML disagrees with low confidence (DSP wins), ML disagrees with high confidence (ML wins), ML returns nil (DSP carries) — independent of model quality

**Given** a new `make bnns-impact-report` target
**When** run with `OA300_CORPUS_PATH` set
**Then** `_bmad-output/implementation-artifacts/4-5-bnns-impact-report.json` is produced with schema:
```json
{
  "track": "<id>",
  "dsp_winner": <bpm>,
  "ml_winner": <bpm>,
  "ensemble_winner": <bpm>,
  "ml_confidence": <0..1>,
  "ground_truth": <bpm>,
  "dsp_correct": <bool>,
  "ml_correct": <bool>,
  "ensemble_correct": <bool>,
  "named_dnb_track": <bool>,
  "latency_ms": <number>
}
```
**And** the report explicitly calls out the 4 named DnB triplet outcomes
**And** if BNNS resolves <2 of 4, completion notes document per-track failure modes with this JSON as evidence (HALT trigger above)

**Reference:** [BNNS library overview](https://developer.apple.com/documentation/accelerate/bnns-library) — `classic-bnns-api` deprecation confirmed via apple-docs MCP 2026-05-04. [BNNSGraph](https://developer.apple.com/documentation/accelerate/bnnsgraph) is the documented current path. Schreiber & Muller (2018) shallow CNN architecture (log-mel-spectrogram → multi-filter conv → temporal pooling → dense → softmax over BPM bins). Music-IR onset-detection literature for clipped-material handling: Bello et al. tutorial on onset detection.

**Notes:**
- `EnsembleCombiner` lives in core (`Sources/BoomBoomBoomKit/`, Story 4.3); `BoomBoomBoomKitML` only conforms to `MLTechnique` and returns `MLEvaluation?`. Story 4.5 NEVER calls `EnsembleCombiner` directly.
- This story depends on Story 4.1 having used `.copy("Resources")` in `Package.swift` — `.mlmodelc` is a directory tree; `.process` would flatten/destroy it. If 4.1 is later "fixed" to `.process`, both 4.5 and 4.6 silently break at runtime, not build time.
- ML model training is out of scope for Phase 3. This story validates the `MLTechnique` protocol architecture and DSP+ML ensemble plumbing using either a placeholder model or a minimal trained model. Production model quality is a separate concern. The mock `MLTechnique` provides deterministic testing.
- Onset-envelope footnote design constraint: BNNS feature extraction must tolerate clipped/limited DnB material. Favor sub-band normalized energy distributions over raw peakiness (Epic 3 retro 2026-05-03 footnote, reinforced 2026-05-04 planning session).
- Sequencing recommendation: land Story 4.7 (spectral-flux DSP variant) BEFORE Story 4.5 so BNNS feature design knows the post-spectral-flux baseline.
- Codex consultation thread: `019df0ea-9b91-7173-866c-7f8e8efdc94e`.

### Story 4.6: CoreML MLTechnique Conformance (Production)

As a library author,
I want a CoreML-based `MLTechnique` conformance for Neural Engine acceleration,
So that ML inference at intensity 8-10 is fast enough for batch workflows on Apple Silicon.

**Conditional acceptance based on Story 4.5 outcome (Epic 4 planning session decision 2026-05-04):**

**Branch A — Story 4.5 BNNS resolved 3 or 4 of 4 named DnB triplet failures:**
**Given** Branch A (covers both 3/4 and 4/4 cases — see Branch A' note below)
**When** Story 4.6 specs CoreML acceptance
**Then** the gate is "match or beat BNNS on the 4 named DnB triplets (within ±0.5 BPM strict Acc1) AND asserted floors hold per Epic 4 Definitions AND CoreML-on path does NOT regress vs the post-4.5 snapshot"
**And** Story 4.6 proceeds as planned with the implementation ACs below

**Branch A' (refinement, applies if 4.5 resolved all 4/4) —** the "match or beat" gate is trivially satisfied if BNNS hit 4/4. Add a stiffer requirement: CoreML must demonstrate a Neural-Engine wall-clock speedup of ≥2x over BNNS on the same 4 tracks (`make coreml-impact-report` `latency_ms` field), OR ≥2 additional Acc1 tracks anywhere on OA300/GiantSteps. Without one of these, Story 4.6 has no measurable value-add over 4.5 and the dev must HALT and surface to PM.

**Branch B — Story 4.5 BNNS resolved exactly 2 of 4:**
**Given** Branch B
**When** Story 4.6 specs CoreML acceptance
**Then** the gate is "resolve ≥ 3 of 4 named DnB triplets within ±0.5 BPM strict Acc1 OR demonstrate ≥ 2 net additional Acc1 tracks across the union of OA300 and GiantSteps (delta vs the post-4.5 snapshot, measured per `make coreml-impact-report` summed across both corpora; baseline commit SHA recorded in Completion Notes)"
**And** asserted floors hold per Epic 4 Definitions AND CoreML-on path does NOT regress vs the post-4.5 snapshot
**And** Story 4.6 proceeds with this stiffer gate

**Branch C — Story 4.5 BNNS resolved < 2 of 4:**
**Given** Branch C
**When** Story 4.5 close-out documents the failure
**Then** Story 4.6 is moved BACK TO `backlog` in `sprint-status.yaml` (NOT a new "paused" state — using existing terminology) with a `gated_on: research-spike-X.Y` annotation and a research-spike story spec re-write required before re-promotion
**And** the new research-spike story (e.g. 4.5b) investigates whether richer model architecture, alternative feature engineering, or different training-data scale changes the picture before committing to a CoreML production path
**And** the spike outcome determines whether Story 4.6 proceeds (with re-spec'd ACs reflecting spike findings), gets re-spec'd against a different model architecture, or is dropped from Epic 4 (Epic 4 close-out at that point)

**Authorized 2026-05-14: Story 4-6 occupies the diagnostic-spike role originally scoped for a separate 4-6b spike. If Branch C fires, the bundle moves to develop-only `_bmad-output/ml-models/`; no follow-up story is spawned unless impact evidence justifies it. The slot's acceptance criteria are re-cast from "CoreML conformance" to "diagnostic instrumentation + bundle decision" per the Story 4-6 spec at `_bmad-output/implementation-artifacts/4-6-ml-accuracy-investigation-and-bundle-decision.md`.**

**Note on branch flexibility:** These are story-promotion rules, not implementation commitments. If Story 4.5 finds that the labels or features are wrong (rather than the model being inadequate), the branch decision should allow re-scoping rather than forcing CoreML theater (Codex consultation 2026-05-04).

**Sequence enforcement (applies to Branches A/A'/B):** Story 4.6 cannot be promoted from `backlog` to `ready-for-dev` until Story 4.5 reaches `done` AND the Story 4.5 close-out commit explicitly names which Branch fired (in Completion Notes). This is a manual gate enforced by the SM at story-creation time — `sprint-status.yaml` does not currently support `depends_on` semantics; track as a process discipline until that schema lands.

**Implementation Acceptance Criteria (apply when Branch A or B proceeds):**

**Given** `CoreMLTechnique` in `Sources/BoomBoomBoomKitML/`
**When** initialized
**Then** it loads a `.mlmodelc` from `Bundle.module` via `MLModel.init(contentsOf:configuration:)` (throws)
**And** `try? CoreMLTechnique()` returns nil if the model resource is missing
**And** the `.mlmodelc` artifact is the SAME one Story 4.5 consumes (one bundling pattern per Epic 4 — symmetric load path)

**Given** a `CoreMLTechnique` instance
**When** `evaluate(trace:)` is called (per Story 4.3 protocol shape: `func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?`)
**Then** it performs inference via CoreML
**And** `MLModelConfiguration.computeUnits = .cpuAndNeuralEngine` is the default (NOT `.all` — `.all` lets the system pick GPU, which adds dispatch latency for small inputs); a `.cpuOnly` fallback is acceptable for diagnostic builds
**And** model input is provided via `MLShapedArray<Float>` (preferred over `MLMultiArray` — `MLShapedArray` is `Sendable` and value-typed; `MLMultiArray` is a reference type and triggers Swift 6 strict-concurrency warnings without `@unchecked`)
**And** `MLShapedArray<Float>` strides match the BNNS NCHW tensor layout from Story 4.5 (row-major shape declared explicitly at construction)
**And** the input/output contract matches `BNNSTechnique` — same trace features, same `MLEvaluation?` return

**Given** `BoomBoomBoomKitML` with CoreML
**When** the ML target is built
**Then** only `CoreML` is added as a framework dependency (to the ML target only — `BoomBoomBoomKit` core stays CoreML-free)

**Given** both `BNNSTechnique` and `CoreMLTechnique` exist
**When** a consumer passes either to `options.mlTechnique`
**Then** the API is identical — consumer doesn't care which implementation runs (per Story 4.3 protocol uniformity)

**Numeric delta gate (A1, applies to Story 4.6 Branch A or B):**

**Given** Story 4.6 CoreML enabled at intensity 8+
**When** `make benchmark` runs with the CoreML path active
**Then** Acc1 satisfies the branch-specific gate above (Branch A: parity-or-better with BNNS on the 4 named triplets; Branch B: stiffer)
**And** the per-track impact report attributes per-track changes to CoreML vs BNNS evaluation
**And** asserted floors hold per Epic 4 Definitions AND the CoreML-on path does NOT regress vs the current snapshot (Story 4.5 BNNS post-merge snapshot serves as the new baseline once 4.5 lands)

**Impact-report deliverables:**

**Given** a new `make coreml-impact-report` target
**When** run with `OA300_CORPUS_PATH` set
**Then** `_bmad-output/implementation-artifacts/4-6-coreml-impact-report.json` is produced
**And** the schema is identical to Story 4.5's `4-5-bnns-impact-report.json` plus three additional fields: `model_load_latency_ms`, `peak_memory_mb`, and a `bnns_vs_coreml_diff` section listing tracks where BNNS and CoreML disagree (validates the contract held)

**Reference:** [MLModel.init(contentsOf:configuration:)](https://developer.apple.com/documentation/coreml/mlmodel/init(contentsof:configuration:)), [MLShapedArray](https://developer.apple.com/documentation/coreml/mlshapedarray), [Bundle.module](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package). WWDC 2024-10159 (Core ML Tools converter — applies to the training/conversion side that produces the `.mlmodelc`, NOT to the runtime Swift code that loads it). WWDC 2022-10027 (still accurate but predates `MLShapedArray`-preferred patterns).

**Notes:**
- `EnsembleCombiner` lives in core (`Sources/BoomBoomBoomKit/`, Story 4.3); `BoomBoomBoomKitML` only conforms to `MLTechnique` and returns `MLEvaluation?`. Story 4.6 NEVER calls `EnsembleCombiner` directly.
- This story depends on Story 4.1 having used `.copy("Resources")` in `Package.swift` AND on Story 4.5 having declared the explicit tensor shape and stride layout (NCHW row-major). Story 4.6 inherits both.
- `BoomBoomBoomKitML` ships its own `Bundle.module` (distinct from `BoomBoomBoomKit`'s); `CoreMLTechnique` must use that target's `Bundle.module` per Story 4.1 AC.

### Story 4.7: Spectral-Flux Onset Detection DSP Variant

As a library author,
I want a `DSPTechnique.spectralFluxOnset` variant that operates on frame-to-frame magnitude differences (half-wave rectified) rather than energy-based onset detection,
So that the upstream onset-envelope weakness on heavily-mastered DnB material is addressed BEFORE BNNS feature engineering has to compensate.

**Sequencing recommendation:** This story should land BEFORE Story 4.5 so BNNS feature design knows the post-spectral-flux baseline. Without this story, BNNS is doing double duty — solving both feature-quality AND tempo-classification — and the upstream weakness stays unfixed for non-ML paths (Epic 4 planning session decision 2026-05-04).

**Acceptance Criteria:**

**Given** the existing 7-case `DSPTechnique` enum at `Sources/BoomBoomBoomKit/DSPTechnique.swift`
**When** Story 4.7 ships
**Then** a new case `.spectralFluxOnset` is appended LAST in case order (8 cases total — do not insert before existing cases; preserves stable-identifier convention)
**And** ALL of the following invariant assertions and doc strings are updated in lockstep — partial updates fail `make test` or leave silent doc drift:
  1. `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:574-576` — `#expect(DSPTechnique.allCases.count == 7)` → `== 8`, plus the test name string
  2. `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:579-581` — `#expect(TechniqueSet.allDSPCombinations().count == 128)` → `== 256` (`2^7` → `2^8` in the test name string)
  3. `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift:19-22` — `combos.count == 128` → `== 256`, plus the `@Test` name string
  4. `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift:25-27` — `DSPTechnique.allCases.count == 7` → `== 8`, plus the `@Test` name string
  5. `Sources/BoomBoomBoomKit/DSPTechnique.swift:162` — doc comment "Generates all 2^7 = 128 DSP technique combinations (power set)" → "2^8 = 256"
  6. `CLAUDE.md` — "DSPTechnique — Public enum (7 cases)" → "(8 cases)"; "`allDSPCombinations()` generates 2^7=128 combos" → "2^8=256 combos"
  7. `_bmad-output/project-context.md:41` — `DSPTechnique.allCases.count == 7`, `TechniqueSet.allDSPCombinations().count == 128 (2^7)` → 8/256/2^8
  8. `_bmad-output/project-context.md:88` — same invariants in Post-Pipeline Corroboration Boundary section
  9. `_bmad-output/project-context.md:101` — "all 2^7=128 DSP technique combinations" → "2^8=256"
  10. `_bmad-output/project-context.md:160` — same invariants in Critical Don't-Miss Rules section
**And** the ablation matrix continues to pass under the new combo count (`make ablation` doubles wall-clock; track in perf baseline)

**Given** the spectral-flux variant in `BPMAnalyzer` step 3 onset detection
**When** `.spectralFluxOnset ∈ techniqueSet`
**Then** onset detection uses spectral flux: per-frame magnitude difference (half-wave rectified, `max(0, |X[t]| - |X[t-1]|)`) summed across mel bands
**And** the existing energy-based onset detection is the default when `.spectralFluxOnset ∉ techniqueSet`
**And** the variant operates on the SAME mel-spectrogram (`melSpectrogram` trace field) — no second STFT, no extra audio pass, no new pipeline step number

**Given** `Options.techniqueSet` does NOT contain `.spectralFluxOnset`
**When** `make benchmark` runs
**Then** the non-regression gate per Epic 4 Definitions holds — asserted floors hold AND per-track BPM JSON output is byte-identical to the pre-Story-4.7 snapshot at `_bmad-output/implementation-artifacts/4-7-variant-disabled-snapshot.json` (byte-equality opt-out test required per project-context.md "Byte-equality opt-out tests" rule)

**Numeric delta gate (A1, applies to Story 4.7):**

**Given** `Options.techniqueSet` contains `.spectralFluxOnset` (variant enabled)
**When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
**Then** asserted floors hold per Epic 4 Definitions (≥57/82 OA300 Acc1, ≥73/82 OA300 Acc2, ≥537/661 GiantSteps Acc1, ≥546/661 GiantSteps Acc2) AND the variant-on path does NOT regress vs current snapshot (OA300 Acc1=58, Acc2=74; GiantSteps Acc1=537, Acc2=546)
**And** if variant-on moves the named DnB tracks but regresses corpus floor or snapshot, the dev MUST HALT and surface to PM — do not silently relax either gate (HALT discipline per project-context.md "Story Authoring Discipline")
**And** the variant must improve performance on the 4 named DnB triplet tracks (Charly @ 160, Faraday_Bunker @ 170, Yin Yang Audio @ 170 DAW, HEFT_Anagram 6 @ 170 DAW) — at least one named track must move from incorrect-detection to within ±2% Acc1 of ground truth (i.e. `make spectral-flux-impact-report` must show ≥1 named track improvement)
**OR** Completion Notes document per-track inertness with the impact-report JSON as evidence AND propose closing the story without adding the case to any preset (`.optimal`, `.dnbOptimized`, etc.) — the variant becomes available but inert by default; Epic 4 planning session 2026-05-04 explicitly authorizes closing the story this way if the brutal corpus gate is not cleared

**Given** the variant is shipped inert-by-default (the OR branch above)
**When** updating `make ablation-smoke` (curated 16-combo lane in `Makefile:51-65`)
**Then** the smoke lane MUST NOT include `.spectralFluxOnset` in any of its 16 combos by default — preserving everyday smoke wall-clock at the same cadence as before
**And** only the full 256-combo `make ablation` pays the 2× cost; CI smoke runs are unaffected

**Impact-report deliverables:**

**Given** a new `make spectral-flux-impact-report` target
**When** run with `OA300_CORPUS_PATH` set
**Then** `_bmad-output/implementation-artifacts/4-7-spectral-flux-impact-report.json` is produced with schema:
```json
{
  "track": "<id>",
  "baseline_bpm": <bpm>,
  "with_variant_bpm": <bpm>,
  "ground_truth": <bpm>,
  "baseline_correct": <bool>,
  "variant_correct": <bool>,
  "named_dnb_track": <bool>
}
```
**And** the report calls out the 4 named DnB triplet tracks explicitly

**Notes:**
- Onset-envelope quality on heavily-mastered material is the upstream weakness identified by Epic 3 retrospective (2026-05-03). Energy-based onset detection collapses on brick-walled masters because the limiter has equalized exactly the dynamic range it keys off. Spectral flux survives because it captures spectral content change rather than amplitude change.
- Codex consultation (2026-05-04, thread `019df0ea-9b91-7173-866c-7f8e8efdc94e`) recommended adding this story with brutal corpus-benchmark gating: "if it does not move the target failures or improve ML features, close it without adding default complexity." The numeric gate above implements that recommendation.
- Music-IR literature reference: Bello et al. "A Tutorial on Onset Detection in Music Signals."

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

### Story 5.6: End-user UI Redesign and Collapsible Trace Inspector

(Created post-initial-epic-planning via `/bmad-create-story` 2026-05-22.)

As an end user dropping an audio file into the BoomBoomBoomKitDemo macOS app,
I want a focused, polished window where the detected BPM is the visual hero and developer-facing knobs sit out of the way,
So that the app feels like a consumer tool ready for App Store distribution rather than a developer evaluation harness.

See `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md` for full spec, acceptance criteria, and §Review Findings table (15 F-IDs from 2026-05-23 code-review reconciliation).

### Story 5.6b: Accessibility + Layout Polish Follow-up

(Created 2026-05-23 to capture deferred findings from Story 5-6 code review.)

Captures 6 SHOULD-FIX / accepted-AC-violation defects deferred from Story 5-6 review pass (F04, F07, F11, F12, F13, F14 — F10 was promoted to Bucket 1 in Story 5-6). Scope summary: F04 (AC #12 — EmptyStateView upper-half layout regression), F07 (AC #6/#7 — neutral gradient Dark Mode break + correct Color initializer spelling), F11 (drop-target safe-area mismatch), F12 (toolbar Button VoiceOver toggle state), F13 (KDD #5 — EmptyStateView caption .tertiary→.secondary), F14 (EmptyStateView accessibility-element combine + hint).

See `_bmad-output/implementation-artifacts/5-6b-a11y-polish.md` for full spec, and `_bmad-output/implementation-artifacts/deferred-work.md` entries W34/W36/W39/W40/W41/W42 for the ledger snapshot. Estimated: ~25 LOC across 2 Swift files.

### Story 5.7: App Store Submission Readiness Scaffold

(Created post-initial-epic-planning via `/bmad-create-story` 2026-05-22.)

As the maintainer preparing the BoomBoomBoomKitDemo app for free macOS App Store distribution,
I want the in-repo prerequisites for a signed, App-Review-acceptable archive build to be in place — app icon, privacy manifest, signing-aware archive workflow, and a recorded category decision —
So that the App Store Connect submission flow has zero in-tree blockers and the actual upload becomes a packaging-and-portal task rather than a project-restructure task.

See `_bmad-output/implementation-artifacts/5-7-app-store-submission-readiness.md` for full spec, acceptance criteria, KDD #9 (Package.swift ↔ MACOSX_DEPLOYMENT_TARGET lockstep), AC #12 (deployment target stays at 15.0), and §Carry-over from Story 5-6 appendix (F01, F05, F08).

### Story 5.8: Demo Rename & App Store Submission

(Created 2026-05-24 via `/bmad-party-mode` rename-scoping discussion — pairs the deferred rename (W33 re-open) with the deferred App Store Connect submission cycle from Story 5-7's OUT-OF-SCOPE.)

As the maintainer about to make the first App Store Connect upload under the demo's permanent identity,
I want the demo renamed from `BoomBoomBoomKitDemo` to its final consumer-facing identity (`BoomBoomBoom` or alternative) AND the App Store Connect submission cycle completed in the same story,
So that the bundle ID committed to App Store Connect on first upload is the one the demo will ship under for life (Apple treats bundle IDs as immutable post-first-upload per Siri's 2026-05-24 platform-doc citation), and no later rename story is required.

See `_bmad-output/implementation-artifacts/5-8-demo-rename-and-app-store-submission.md` for full spec. Supersedes Story 5-7 KDD #4 + #5; closes W33 in `deferred-work.md`.

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
