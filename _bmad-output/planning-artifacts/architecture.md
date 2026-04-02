---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
status: 'complete'
completedAt: '2026-03-31'
inputDocuments:
  - '_bmad-output/planning-artifacts/prd.md'
  - '_bmad-output/planning-artifacts/phase3-roadmap.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md'
  - '_bmad-output/implementation-artifacts/deferred-work.md'
  - '_bmad-output/implementation-artifacts/tech-spec-phase-1-intensity-trace-accuracy.md'
  - '_bmad-output/implementation-artifacts/tech-spec-phase-2-technique-protocol-ablation.md'
  - '_bmad-output/implementation-artifacts/spec-multi-window-candidate-merging.md'
  - '_bmad-output/implementation-artifacts/spec-post-disambiguation-voting.md'
  - 'CLAUDE.md'
workflowType: 'architecture'
project_name: 'BoomBoomBoomKit'
user_name: 'robbyt'
date: '2026-03-30'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements (45 FRs across 9 categories):**

| Category | FRs | Architectural Impact |
|----------|-----|---------------------|
| BPM Analysis | FR1-FR8 | Core pipeline, intensity scale, merge strategy, diagnostic trace -- all exist. Phase 3 adds graceful ML degradation (FR6-7) |
| LUFS Measurement | FR9-FR10 | Stable. No Phase 3 changes |
| Cancellation & Progress | FR11-FR14 | New: cooperative cancellation between pipeline stages, progress primitive. Touches `AudioAnalysisService` and `BPMAnalyzer` |
| ML-Augmented Detection | FR15-FR18 | New: `BoomBoomBoomKitML` package, `MLTechnique` conformance, ensemble voting, graceful degradation |
| Configuration & Technique | FR19-FR21 | Exists. Phase 3 adds new technique cases |
| Audio File Handling | FR22-FR26 | Exists. Downsampling deferred to post-baseline experiment |
| Measurement & Validation | FR27-FR33 | Partially exists. Phase 3 adds perf benchmarks, GiantSteps, dual tolerance, genre-stratified reporting |
| Demo App | FR34-FR41 | New: macOS SwiftUI app as in-repo SPM target |
| Documentation | FR42-FR45 | Non-architectural |

**Non-Functional Requirements (20 NFRs):**

- **Performance (NFR1-6):** Latency tiers by intensity level, memory bounded by buffer reuse, optimizations must not degrade accuracy (validated by ablation)
- **Accuracy (NFR7-11):** Regression gate (Acc1 never decreases), ML strictly additive, fine-grid precision, Double-precision K-weighting, dual tolerance
- **Compatibility (NFR12-16):** Zero deps for core, CoreML only for ML package, Swift 6 strict concurrency, macOS 15+, vDSP mandatory
- **Code Quality (NFR17-20):** fmt+lint gating, ablation matrix for all techniques, existing tests never regress, Double precision for IIR

**Scale & Complexity:**

- Primary domain: Audio DSP library (Swift/SPM)
- Complexity level: Medium
- Estimated architectural components: 5 (core pipeline, ML package, demo app, benchmark infrastructure, cancellation/progress)

### Technical Constraints & Dependencies

| Constraint | Impact | Non-Negotiable? |
|-----------|--------|:--------------:|
| Zero external dependencies (core) | All DSP via Accelerate, all I/O via AVFoundation, ML via BNNS (Accelerate) or CoreML | Yes |
| Swift 6.0 strict concurrency | All public types Sendable, no data races | Yes |
| Value types only (structs/enums) | No classes, no reference semantics, stateless analyzers | Yes |
| vDSP for bulk numeric operations | No manual loops over sample arrays | Yes |
| Double precision for IIR filters | K-weighting biquads, any new recursive DSP | Yes |
| macOS 15+ deployment target | No legacy platform concerns | Yes |
| Ablation gating | Every technique change validated by 2^N matrix | Yes |
| Branch model (develop/main) | AI tooling stays on develop, library-only on main | Yes |

### Cross-Cutting Concerns Identified

1. **Cancellation propagation:** Injectable `() -> Bool` closure (defaulting to `{ Task.isCancelled }`) checked between window iterations in `AudioAnalysisService`. BPMAnalyzer remains stateless -- no state, no cancellation awareness. Injectable closure enables deterministic testing without timing-dependent flakiness
2. **Downsampling is deferred:** Not part of initial Phase 3A. Accuracy work in 3B establishes the baseline at native sample rate first. Downsampling explored later as a `DSPTechnique` case with ablation validation. When explored, read-time downsampling via `PCMBufferReader.targetSampleRate` is preferred over post-read. LUFS path must never be downsampled (K-weighting coefficients are sample-rate-specific). `AVAudioConverter` quality setting must be documented
3. **ML/DSP interface boundary:** Parameter injection (`mlTechnique: (any MLTechnique)? = nil` on `analyzeBPM`) -- not runtime discovery or registration. Value-type constraint rules out stored registration. Graceful degradation: no parameter = DSP only, effective intensity capped at 7. `MLTechnique` receives `BPMDiagnosticTrace` (Float32), not raw audio. Trace must be populated internally when ML technique is present
4. **Package split:** `BoomBoomBoomKitML` depends on `BoomBoomBoomKit`. The core library must not import or reference the ML package. The ML package provides `MLTechnique` conformances that consumers pass via parameter injection
5. **Buffer pool without retained state:** `withUnsafeTemporaryAllocation` for small buffers (<16KB). `TempogramBuffers`-pattern struct (allocate/deallocate) for large buffers. No state retained between analysis calls -- caller creates, passes in, caller cleans up
6. **Demo app as strict public-API consumer:** Imports only `BoomBoomBoomKit` (and optionally `BoomBoomBoomKitML`). Zero `@testable import`, zero internal type access. If the demo needs something the public API can't provide, that's a signal to expand the API, not backdoor the demo

### Phase 3A Scope Refinement

Based on collaborative analysis, Phase 3A performance work is scoped to:
- Buffer reuse (24 scratch allocations in BPMAnalyzer)
- FFT plan reuse (create once, reuse across mel-spectrogram frames)
- Cooperative cancellation via injectable closure
- Progress reporting primitive
- Performance benchmark infrastructure (`make perf-benchmark`)
- GiantSteps Tempo dataset integration (664 tracks)

**Explicitly deferred from 3A:** Downsampling (lands as a post-baseline experiment after 3B accuracy work establishes native-rate baselines)

## Technology Foundation (Established)

### Primary Technology Domain

Native Swift library (SPM package) -- brownfield project with established stack. No starter template evaluation needed.

### Established Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Language & Runtime | Swift 6.0, strict concurrency, macOS 15+ | All public types Sendable |
| DSP Framework | Accelerate/vDSP | Mandatory for bulk numeric operations |
| Audio I/O | AVFoundation | `@preconcurrency import` for Swift 6 compat |
| Testing | Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`) | Not XCTest |
| Code Quality | SwiftLint + swift format | `make fmt` before `make lint` |
| Distribution | Swift Package Manager | Single `Package.swift` |
| Architecture Pattern | Stateless value types with static methods | Public facade over internal analyzers |

### Phase 3 Technology Additions

#### ML Package Structure

**Decision:** Same `Package.swift`, separate product -- not a separate repository.

```swift
// Consumer adds one or both:
.product(name: "BoomBoomBoomKit", package: "BoomBoomBoomKit"),
.product(name: "BoomBoomBoomKitML", package: "BoomBoomBoomKit"), // optional
```

**Package.swift additions (Phase 3C):**

```swift
products: [
    .library(name: "BoomBoomBoomKit", targets: ["BoomBoomBoomKit"]),
    .library(name: "BoomBoomBoomKitML", targets: ["BoomBoomBoomKitML"]),
],
targets: [
    // ... existing targets ...
    .target(
        name: "BoomBoomBoomKitML",
        dependencies: ["BoomBoomBoomKit"],
        resources: [.copy("Resources")]
    ),
]
```

**Source layout:**

```
Sources/
  BoomBoomBoomKit/           # existing (no changes)
  BoomBoomBoomKitML/         # new (Phase 3C)
    BNNSTechnique.swift      # BNNS conformance (first, proof-of-concept)
    CoreMLTechnique.swift    # CoreML conformance (second, production)
    Resources/
      tempo_classifier.mlmodelc
  BoomBoomBoomKitTestSupport/  # existing
```

**Rationale:** Inter-target dependency within one package -- no version skew, no circular dependency. CoreML and BNNS are system frameworks (no SPM dependency declaration needed, just `import CoreML` in source). Core library never imports the ML target.

#### ML Framework Sequencing

**Decision:** BNNS first (proof-of-concept), CoreML second (production).

- **BNNS** lives inside Accelerate -- zero new framework dependencies. Validates the `MLTechnique` protocol and DSP+ML ensemble architecture. CPU-only inference
- **CoreML** enables Neural Engine acceleration (~10x throughput for supported ops). Production path. Adds CoreML framework dependency (to ML target only)
- Both conformances live in `BoomBoomBoomKitML`. Consumer passes `(any MLTechnique)` -- doesn't care which implementation runs

#### Demo App Structure

**Decision:** Separate Xcode project in `Demo/`, following the AmbientUI pattern. Ships on `main` as part of the open-source distribution.

```
Demo/
  BoomBoomBoomKitDemo/
    BoomBoomBoomKitDemo.xcodeproj   # references ../../Package.swift as local dep
    BoomBoomBoomKitDemo/
      BoomBoomBoomKitDemoApp.swift
      ContentView.swift
      AnalysisViewModel.swift
      Assets.xcassets/
```

- SwiftUI + `@Observable` view model
- Imports `BoomBoomBoomKit` (and optionally `BoomBoomBoomKitML`) via local package reference
- Public API only -- zero `@testable import`, zero internal type access
- Developers clone, open xcodeproj, build and run
- Add `Demo/**/build/` and `Demo/**/*.xcuserstate` to `.gitignore`

#### Performance Benchmarks

**Decision:** Same test target as existing tests, env-gated like OA300. New `make perf-benchmark` Makefile target filters to the performance test suite. Follows the established `@Suite(.enabled(if: ...))` pattern.

## Core Architectural Decisions

### Decision Summary

| ID | Decision | Choice | Phase |
|----|----------|--------|-------|
| ADR-1 | Cancellation granularity | Between windows only | 3A |
| ADR-2 | Progress reporting | `@Sendable` callback closure | 3A |
| ADR-3 | Buffer reuse | Internal to `BPMAnalyzer` | 3A |
| ADR-4 | ML model loading | Eager at conformance init | 3C |
| ADR-5 | ML ensemble voting | Configurable policy | 3C |
| ADR-6 | Trace population for ML | Always populate when ML present | 3C |
| ADR-7 | Harmonic ratio detection | Inside step 10 disambiguation | 3B |
| ADR-8 | Click-track cross-correlation | New `DSPTechnique` case | 3B |
| ADR-9 | GiantSteps integration | Separate test suite | 3A |
| ADR-10 | Dual tolerance reporting | Separate test methods | 3A |

### Pipeline Architecture

**ADR-1: Cancellation between windows only.**
`AudioAnalysisService` checks `Task.isCancelled` between window iterations in the progressive retry loop. `BPMAnalyzer` remains completely stateless -- no cancellation parameter, no closure threading through internal static methods. Per-window pipeline execution is sub-second, making this granularity sufficient. Cancelled analysis returns `nil`.

**ADR-2: Progress via `@Sendable` callback closure.**
```swift
onProgress: (@Sendable (ProgressUpdate) -> Void)? = nil
```
`ProgressUpdate` contains window progress (completed/total). Per-track granularity, not per-pipeline-stage. The `@Sendable` annotation is required under Swift 6 strict concurrency because the closure may be passed from a `@MainActor`-isolated context (e.g., updating a progress bar) into a non-isolated static method. Validated against Apple's Swift concurrency documentation.

ADR-1 and ADR-2 should land as a single story since both modify the window iteration loop in `AudioAnalysisService`.

**ADR-3: Internal buffer management in `BPMAnalyzer`.**
`withUnsafeTemporaryAllocation` for small buffers (<16KB). `TempogramBuffers`-pattern struct (allocate/deallocate with defer) for large buffers. No API change, no caller involvement. All allocation/deallocation happens within `estimateBPM()` scope. Note: `withUnsafeTemporaryAllocation` may use heap for larger sizes (platform-dependent threshold) -- measure actual improvement rather than assuming stack allocation.

### ML Integration Architecture

**ADR-4: Eager model loading at conformance init.**
`CoreMLTechnique()` / `BNNSTechnique()` loads the model from `Bundle.module` in its initializer. Consumer creates the conformance once, passes it to `analyzeBPM` calls. Initializer must be `throws` because `MLModel.init(contentsOf:configuration:)` throws (validated against Apple CoreML docs). Graceful degradation pattern:
```swift
let ml = try? CoreMLTechnique()  // nil if model resource missing
service.analyzeBPM(url: url, mlTechnique: ml)  // DSP-only if nil
```

**ADR-5: Configurable ML ensemble voting policy.**
Resolution strategy is part of the `MLTechnique` protocol or a parameter on `analyzeBPM`. Conservative default: DSP wins unless ML confidence is high AND DSP confidence is low. Tunable after ablation data reveals actual ML behavior. The "ML is additive" constraint (NFR8) is validated by ablation, not enforced by a hardcoded rule.

**Testing requirement:** A mock `MLTechnique` conformance in the test target enables deterministic ensemble voting tests without a real model. Test cases: ML agrees with DSP, ML disagrees with low confidence (DSP wins), ML disagrees with high confidence (ML wins), ML returns nil (DSP carries).

**ADR-6: Always populate trace when ML technique is present.**
Pipeline builds `BPMDiagnosticTrace` internally regardless of `enableTrace` flag when `mlTechnique` is non-nil (ML needs it as input via `MLTechnique.evaluate(candidates:trace:)`). Trace is only returned to the consumer when `enableTrace` is true. Zero cost when no `mlTechnique` is passed. Note: this introduces trace allocation overhead on every ML-augmented call -- small arrays (top 5 entries each), documented as a known cost of ML integration.

### DSP Technique Integration

**ADR-7: Harmonic ratio detection inside step 10.**
Extends `resolveOctaveAmbiguity` with non-octave ratio checks (3:2 tolerance 1.45-1.55, 3:1 tolerance 2.85-3.15) alongside the existing 2:1 check. Follows the deferred-work.md spec. Sub-band voting mechanism is reused for these ratios. Validated by two known failing Prodigy tracks at triplet/2-3 time lock.

**ADR-8: Click-track cross-correlation as new `DSPTechnique` case.**
Full ablation coverage. Matrix grows from 2^6=64 to 2^7=128 combinations. Ablation runtime may increase to 25-30 min (each combination now includes an optional `vDSP_conv` per candidate). Consistent with all other techniques -- gated by `TechniqueSet`, enumerable via `allDSPCombinations()`, validated by ablation before shipping. `CaseIterable` on `DSPTechnique` automatically includes the new case.

### Measurement Infrastructure

**ADR-9: GiantSteps as separate test suite.**
`GiantStepsBenchmarkTests` with its own env var (`GIANTSTEPS_CORPUS_PATH`) and `make giantsteps` Makefile target. Different corpus purpose: OA300 is the tuning corpus, GiantSteps is the validation corpus. Ground truth format differs (crowd-annotated, possibly multi-tempo per track).

**ADR-10: Dual tolerance as separate test methods.**
`benchmarkAcc1Strict()` (2%) and `benchmarkAcc1MIREX()` (4%) as independent, individually filterable tests. Both share the same pre-computed analysis results (follow the `benchmarkMergeStrategies` pattern: pre-read audio once, iterate over tolerance thresholds). Avoids running the full corpus twice.

### Implementation Sequence

1. **ADR-3** (buffer reuse) -- internal refactor, no API change, immediate perf improvement
2. **ADR-1 + ADR-2** (cancellation + progress) -- single story, API addition to `AudioAnalysisService`
3. **ADR-9 + ADR-10** (measurement infra) -- test infrastructure, enables validation of subsequent work
4. **ADR-7** (harmonic ratio) -- extends existing disambiguation, validates against known failing tracks
5. **ADR-8** (click-track cross-correlation) -- new `DSPTechnique`, ablation matrix expansion
6. **ADR-4 + ADR-5 + ADR-6** (ML integration) -- Phase 3C, depends on all DSP work landing first

### Cross-Decision Dependencies

- ADR-6 (trace for ML) depends on ADR-4 (model loading) -- trace populated only when `mlTechnique` is non-nil
- ADR-5 (ensemble voting) benefits from ADR-8 (click-track) landing first -- 128-combo ablation data informs the conservative default
- ADR-8 (new DSPTechnique) should be validated against ADR-9 (GiantSteps) for genre-diverse validation
- ADR-10 (dual tolerance) should report for both ADR-9 corpora (OA300 and GiantSteps)

## Implementation Patterns & Consistency Rules

### Existing Rules (Reference)

All 52 implementation rules in `_bmad-output/project-context.md` remain in effect (language rules, framework rules, testing rules, code quality, workflow). This section documents **Phase 3-specific patterns** where AI agents could make inconsistent choices.

### New DSP Technique Checklist

When adding a new `DSPTechnique` case:

1. Add the case to `DSPTechnique` enum -- `CaseIterable` automatically includes it
2. Add gating in `BPMAnalyzer.estimateBPM()` via `techniques.contains(.newCase)`:
   - **If the technique modifies an existing helper function's behavior:** add a `Bool` parameter to that function gated by the technique (e.g., `normalizeSubBands: Bool` on `computeMelOnsetEnvelopeWithSubBands()`)
   - **If the technique is a standalone transform between pipeline steps:** apply inline after the relevant step (e.g., `vDSP_vsq` after ACF computation)
3. **Write a unit test for the technique with synthetic input** that validates the transform does what it claims -- before integrating into the pipeline
4. Add to at least one `TechniqueSet` preset (or document why it's excluded from all)
5. Update `AnalysisIntensity.techniqueSet` mapping if the technique should activate at certain levels
6. Run full ablation matrix (`make ablation`) -- all 2^N combinations must complete without crashes
7. Update CLAUDE.md with the new technique name and pipeline step placement

**Anti-pattern:** Adding a DSP improvement that is always-on and not gated by `TechniqueSet`. Every accuracy-affecting change must be ablation-testable.

### Cancellation & Progress Pattern

```
// Pseudocode for AudioAnalysisService.analyzeBPM():
for windowSize in intensity.windowSizes {
    if Task.isCancelled { return nil }
    onProgress?(ProgressUpdate(windowsCompleted: completed, windowsTotal: total))
    let result = BPMAnalyzer.estimateBPM(...)
    // collect result...
}
```

**`ProgressUpdate` struct (to be added):**

```swift
public struct ProgressUpdate: Sendable {
    public let windowsCompleted: Int
    public let windowsTotal: Int
}
```

**Rules:**
- Cancellation check BEFORE each window, not after
- Progress callback BEFORE each window analysis (consumer sees 0/3, 1/3, 2/3)
- `enableTrace` forced to `true` internally when `mlTechnique` is non-nil (ADR-6)
- Cancelled analysis returns `nil`, not a partial result
- `@Sendable` annotation required on the progress closure

**Cancellation test pattern:**

```swift
@Test func cancelledAnalysisReturnsNil() async {
    let task = Task {
        await service.analyzeBPM(url: longTrackURL, intensity: .default)
    }
    try? await Task.sleep(for: .milliseconds(50))
    task.cancel()
    let result = await task.value
    #expect(result == nil)
}
```

### ML Technique Integration Pattern

**Consumer usage:**

```swift
let ml = try? CoreMLTechnique()  // nil if model resource missing
let result = await service.analyzeBPM(
    url: url,
    intensity: .thorough,
    mlTechnique: ml
)
```

**`effectiveIntensity` (to be added to `AudioAnalysisResult`):** New field reporting the actual intensity used. When `mlTechnique` is nil and requested intensity is 8+, `effectiveIntensity` shows 7 (capped at DSP-only max).

**Rules:**
- `MLTechnique` conformance initializer is `throws` (model load can fail)
- Consumer passes `nil` for DSP-only (default behavior)
- `AudioAnalysisService` caps effective intensity at 7 when `mlTechnique` is nil
- ML ensemble resolution runs AFTER DSP pipeline completes -- ML receives trace, not raw audio
- Mock `MLTechnique` conformance in test target for ensemble voting tests (returns predetermined BPM/confidence)

### Buffer Management Pattern

**Size rule:**
- **Compile-time-bounded buffers** (FFT scratch, mel band arrays, candidate arrays -- size known from pipeline constants): use `withUnsafeTemporaryAllocation`
- **Input-dependent buffers** (onset envelope, mel spectrogram frames -- size depends on audio length): use `TempogramBuffers`-pattern struct with `allocate()` factory and `deallocate()` method

```swift
// Compile-time-bounded:
withUnsafeTemporaryAllocation(of: Float.self, capacity: fftSize) { buffer in
    vDSP_vmul(...)
}

// Input-dependent:
let buffers = PipelineBuffers.allocate(onsetLength: N, melBands: 40)
defer { buffers.deallocate() }
```

**Rules:**
- Every `.allocate()` has a corresponding `.deallocate()` in a `defer` block
- Never hold buffer references beyond `estimateBPM()` scope
- Use `vDSP_Length(count)` for all count parameters (not bare Int)

### Test Pattern for New Corpora

When adding a new benchmark corpus:

1. Create a separate test suite file: `<CorpusName>BenchmarkTests.swift`
2. Env-gate with `@Suite(.enabled(if: ProcessInfo.processInfo.environment["<CORPUS>_PATH"] != nil))`
3. Add a `make <corpus-name>` target to Makefile
4. Include both `benchmarkAcc1Strict()` (2%) and `benchmarkAcc1MIREX()` (4%) methods
5. Share analysis results between tolerance methods -- pre-read audio once, iterate over thresholds
6. Ground truth lives in `Tests/BoomBoomBoomKitTests/Fixtures/`

### Enforcement

- `make fmt && make lint` before every commit (existing)
- `make test` -- all tests pass (existing)
- `make benchmark` -- no Acc1 regressions (existing)
- `make ablation` -- full matrix completes, no crashes (existing, matrix size grows with new techniques)
- Validate `@Sendable` on any closure parameter that crosses isolation boundaries (new)

## Project Structure & Boundaries

### Current Directory Structure (with Phase 3 additions)

```
BoomBoomBoomKit/
  Package.swift                              # +BoomBoomBoomKitML target (Phase 3C)
  .swiftlint.yml
  LICENSE
  README.md
  CLAUDE.md
  Makefile                                   # +make perf-benchmark, make giantsteps
  Sources/
    BoomBoomBoomKit/                         # Core library (public)
      AudioAnalysisService.swift             # +cancellation, progress, mlTechnique param
                                             #  AudioAnalysisResult lives here (+effectiveIntensity)
      AnalysisIntensity.swift
      BPMAnalyzer.swift                      # +new DSPTechnique gating, buffer reuse
      BPMDiagnosticTrace.swift
      BPMResult.swift
      CandidateMergeStrategy.swift
      DSPTechnique.swift                     # +clickTrackCorrelation case
                                             #  MLTechnique protocol also lives here (line 173)
      LUFSAnalyzer.swift
      MelFilterbank.swift
      PCMBufferReader.swift
      ProgressUpdate.swift                   # NEW (Phase 3A)
    BoomBoomBoomKitML/                       # NEW (Phase 3C)
      BNNSTechnique.swift
      CoreMLTechnique.swift
      Resources/
        tempo_classifier.mlmodelc
    BoomBoomBoomKitTestSupport/              # Shared fixtures (existing)
      AudioFixtures.swift
      TestSignalGenerators.swift
      Resources/AudioFixtures/
  Tests/
    BoomBoomBoomKitTests/
      BPMAnalyzerTests.swift                 # +technique unit tests
      AudioAnalysisServiceTests.swift        # +cancellation, progress, ML ensemble voting tests
      AblationTests.swift                    # matrix grows to 2^7
      OA300BenchmarkTests.swift              # +dual tolerance methods
      GiantStepsBenchmarkTests.swift         # NEW (Phase 3A)
      PerformanceBenchmarkTests.swift        # NEW (Phase 3A)
      DAWOracleBenchmarkTests.swift
      Fixtures/
        oa300-ground-truth.json
        giantsteps-ground-truth.json         # NEW (Phase 3A)
  Demo/                                      # NEW (Phase 3D), ships on main
    BoomBoomBoomKitDemo/
      BoomBoomBoomKitDemo.xcodeproj
      BoomBoomBoomKitDemo/
        BoomBoomBoomKitDemoApp.swift
        ContentView.swift
        AnalysisViewModel.swift
        Assets.xcassets/
  scripts/
    dawproject-bpm.py
```

### Architectural Boundaries

**Public API boundary** (`Sources/BoomBoomBoomKit/`):
- `AudioAnalysisService` -- sole public entry point for analysis
- Public types: `AudioAnalysisResult`, `AnalysisIntensity`, `CandidateMergeStrategy`, `DSPTechnique`, `TechniqueSet`, `MLTechnique`, `BPMDiagnosticTrace`, `ProgressUpdate`
- `PCMBufferReader`, `PCMBufferReaderError` -- public file I/O
- Everything else is `internal` -- agents must not promote types without explicit design decision

**ML package boundary** (`Sources/BoomBoomBoomKitML/`):
- Depends on `BoomBoomBoomKit` (one-way dependency)
- Core library NEVER imports ML package
- Exports `MLTechnique` conformances (`BNNSTechnique`, `CoreMLTechnique`)
- Consumer passes conformance via parameter injection

**Demo app boundary** (`Demo/`):
- Separate Xcode project, references parent `Package.swift` as local dependency
- Imports only public API -- zero `@testable import`, zero internal type access
- Ships on `main` with the library (follows AmbientUI pattern)
- Add `Demo/**/build/` and `Demo/**/*.xcuserstate` to `.gitignore`

**Test boundary** (`Tests/`):
- All tests use Swift Testing (`@Suite`, `@Test`, `#expect`, `#require`)
- Benchmark suites are env-gated (`OA300_CORPUS_PATH`, `GIANTSTEPS_CORPUS_PATH`)
- `PerformanceBenchmarkTests` env-gating decided at story level (corpus-based or bundled fixtures)
- Test support target (`BoomBoomBoomKitTestSupport`) provides shared fixtures
- Mock `MLTechnique` conformance lives in test target, not in ML package

### FR-to-Structure Mapping

| FR Category | Primary File(s) | Notes |
|------------|-----------------|-------|
| BPM Analysis (FR1-8) | `AudioAnalysisService.swift`, `BPMAnalyzer.swift` | Existing + Phase 3 modifications |
| LUFS (FR9-10) | `LUFSAnalyzer.swift` | No Phase 3 changes |
| Cancellation (FR11-14) | `AudioAnalysisService.swift` | Window loop modification |
| ML Detection (FR15-18) | `BoomBoomBoomKitML/*.swift`, `AudioAnalysisService.swift` | New target + param injection |
| Configuration (FR19-21) | `DSPTechnique.swift`, `AnalysisIntensity.swift` | New case + mapping update |
| Audio I/O (FR22-26) | `PCMBufferReader.swift` | No Phase 3 changes (downsampling deferred) |
| Measurement (FR27-33) | `*BenchmarkTests.swift`, `Makefile` | New suites + targets |
| Demo App (FR34-41) | `Demo/BoomBoomBoomKitDemo/` | New Xcode project |
| Documentation (FR42-45) | `README.md`, inline `///` comments | Non-structural |

### Data Flow

```
Audio File (disk)
  → PCMBufferReader (mono [Float] + sampleRate)
    → AudioAnalysisService (window loop, cancellation, progress)
        ├── BPMAnalyzer.estimateBPM() per window (10-step pipeline)
        │     → BPMResult + BPMDiagnosticTrace (if ML present or enableTrace)
        │   → CandidateMergeStrategy.merge() across windows
        │   → IF mlTechnique != nil:
        │       → MLTechnique.evaluate(candidates:trace:)
        │       → ensemble resolution (configurable policy)
        │   → AudioAnalysisResult.bpm
        │
        └── LUFSAnalyzer.analyze() (parallel path)
              → LUFSResult
              → AudioAnalysisResult.lufs
```

## Architecture Validation Results

### Validation Summary

- **Coherence:** All 10 ADRs work together without conflicts
- **Coverage:** All 45 FRs and 20 NFRs are architecturally supported
- **Readiness:** Patterns are specific enough for AI agents to implement consistently

### Requirements Coverage

| FR Range | Status | Notes |
|----------|--------|-------|
| FR1-FR8 (BPM) | Covered | Existing + ADR-5 (ML ensemble), ADR-7/8 (new techniques) |
| FR9-FR10 (LUFS) | Covered | No changes needed |
| FR11-FR14 (Cancel/Progress) | Covered | ADR-1, ADR-2 |
| FR15-FR18 (ML) | Covered | ADR-4, ADR-5, ADR-6 + package structure |
| FR19-FR21 (Config) | Covered | ADR-8 adds new technique case |
| FR22-FR26 (Audio I/O) | Covered | Downsampling deferred (documented) |
| FR27-FR33 (Measurement) | Covered | ADR-9, ADR-10 + perf benchmarks |
| FR34-FR41 (Demo App) | Covered | Demo app structure defined |
| FR42-FR45 (Docs) | Covered | Non-architectural, story-level |

| NFR Range | Status | Notes |
|-----------|--------|-------|
| NFR1-6 (Performance) | Covered | ADR-3 (buffers), perf benchmarks, downsampling deferred |
| NFR7-11 (Accuracy) | Covered | ADR-7/8 (techniques), ADR-5 (ML additive), ADR-10 (dual tolerance) |
| NFR12-16 (Compatibility) | Covered | Zero-dep maintained, CoreML isolated to ML package |
| NFR17-20 (Code Quality) | Covered | Enforcement section, ablation gating |

### Architecture Completeness Checklist

- [x] Project context analyzed (52 existing rules + Phase 3 additions)
- [x] Technology stack specified (established + Phase 3: ML package, demo app)
- [x] 10 core architectural decisions documented with rationale
- [x] Implementation patterns defined (7 pattern categories)
- [x] Complete directory structure with Phase 3 additions
- [x] Architectural boundaries defined (4 boundaries)
- [x] FR-to-structure mapping complete
- [x] Data flow documented (BPM + LUFS parallel paths, conditional ML)
- [x] Cross-decision dependencies mapped
- [x] Implementation sequence ordered
- [x] Enforcement rules documented

### Deferred to Story Specs

- `effectiveIntensity` field type on `AudioAnalysisResult`
- ML ensemble voting configuration surface (Phase 3C)
- `PerformanceBenchmarkTests` env-gating decision
- Demo app feature scope per phase

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High -- brownfield project with established patterns; Phase 3 is additive

**Key Strengths:**
- Every decision validated against existing codebase and Apple documentation
- Collaborative review at each step caught real issues (buffer thresholds, @Sendable, AudioAnalysisResult file location, data flow branches, MLModel throws init)
- Clear separation: core library (zero deps) vs ML package (CoreML) vs demo app (public API only)
- All 45 FRs and 20 NFRs mapped to architectural support

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all ADRs exactly as documented
- Reference `_bmad-output/project-context.md` for the 52 base rules
- Reference this architecture doc for Phase 3-specific decisions and patterns
- When in doubt, prefer the more restrictive option (per project-context.md)
- Validate DSP changes against OA300 corpus (`make benchmark`)

**First Implementation Priority (Phase 3A):**
1. ADR-3 -- buffer reuse (internal refactor, no API change)
2. ADR-1 + ADR-2 -- cancellation + progress (single story, API addition)
3. ADR-9 + ADR-10 -- measurement infrastructure (GiantSteps suite, dual tolerance)
