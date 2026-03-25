---
title: 'Phase 1 — Intensity API, Diagnostic Trace & Accuracy Quick Wins'
slug: 'phase-1-intensity-trace-accuracy'
created: '2026-03-23'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: [Swift 6.0, Accelerate/vDSP, AVFoundation, Swift Testing]
files_to_modify: [AnalysisIntensity.swift (new), BPMDiagnosticTrace.swift (new), BPMAnalyzer.swift, AudioAnalysisService.swift, BPMAnalyzerTests.swift, AudioAnalysisServiceTests.swift, OA300BenchmarkTests.swift (new), oa300-ground-truth.json (new), Makefile, CLAUDE.md]
code_patterns: [stateless static methods, vDSP bulk operations, Sendable structs, internal types with public facade]
test_patterns: [Swift Testing '@Suite/@Test/#expect/#require', synthetic click tracks, real audio fixtures, ±2 BPM tolerance]
---

# Tech-Spec: Phase 1 — Intensity API, Diagnostic Trace & Accuracy Quick Wins

**Created:** 2026-03-23

## Overview

### Problem Statement

11/30 OA300 Acc1 failures have the correct BPM absent from the top 3 candidates — the disambiguation layer cannot fix what it never sees. No way to diagnose where in the pipeline the signal is lost. No caller control over analysis thoroughness. No benchmark infrastructure in this repo.

### Solution

`AnalysisIntensity` (1-10) controls pipeline depth. `BPMDiagnosticTrace` captures per-step intermediate state. Four DSP quick wins slot into intensity levels. OA300 benchmark with Rekordbox ground truth validates accuracy.

### Scope

**In Scope:**
- `AnalysisIntensity` struct (1-10), named constants (`.fastest`, `.default`, `.thorough`, `.maximum`)
- Intensity levels 1-7 (DSP-only); 8-10 reserved for Phase 2 ML (return same properties as 7)
- New `analyzeBPM(url:intensity:enableTrace:)` overload; old `strategy` overload deprecated at public API level
- `BPMDiagnosticTrace` public struct (evolving API)
- #24 expand candidates 3→5 (intensity 5+), #38 sub-band normalization (3+), #39 ACF sharpening (3+), #60 adaptive thresholding (4+)
- Tier 1 regression tests (always run) + Tier 2 OA300 benchmark (env-gated via `OA300_CORPUS_PATH`)
- OA300 ground truth converted from UTF-16 TSV to JSON
- `make benchmark` Makefile target
- Update TODO.md, brainstorming session, and CLAUDE.md

**Out of Scope:** Intensity 8-10 / ML, ratio-aware disambiguation, combined BPM+LUFS API, dual sync/async, beat tracking, hardware capability detection, new fixtures, duration hint (#35), `maxSeconds` optimization for low intensity levels

## Architecture Decisions

### ADR-1: `AnalysisIntensity` — Struct Wrapping Int
Follows `UILayoutPriority` pattern. Clamped 1-10, open for extension. Conforms to `Sendable`, `Hashable`, `Comparable`, `ExpressibleByIntegerLiteral` (all inits clamp, never trap). Levels 8-10 return identical computed properties to level 7 until Phase 2.

### ADR-2: Computed Properties Drive Pipeline
Pipeline queries `intensity.useAdaptiveThreshold` etc., never raw level numbers. All gating logic lives in `AnalysisIntensity.swift`.

**Properties:** `candidateCount` (1/3/5), `windowSizes` ([15], [30], [30,60,90]), `useSubBandVoting` (3+), `useACFSharpening` (3+), `useSubBandNormalization` (3+), `useAdaptiveThreshold` (4+), `useFineGridRefinement` (5+), `progressiveThreshold` (nil or 0.40)

### ADR-3: Deprecated Overload for Backward Compat
New `analyzeBPM(url:maxSeconds:intensity:enableTrace:)`. Old `analyzeBPM(url:maxSeconds:strategy:)` marked `@available(*, deprecated)`, maps to intensity 7 internally. **Note:** `strategy` parameter is dead code in internal `BPMAnalyzer.estimateBPM()` (never read) — remove from internal signature entirely. Deprecation only applies at public `AudioAnalysisService` level. `.beatPhase` was never implemented; mapping to intensity 7 is a no-op behavior change.

### ADR-4: Trace via `enableTrace: Bool = false`
When true, `AudioAnalysisResult.trace: BPMDiagnosticTrace?` is populated. When false, nil — zero cost. Follows URLSession metrics pattern. **Trace accumulation:** single `var trace: BPMDiagnosticTrace?` local variable in `estimateBPM()`, populated imperatively after each pipeline step. No builder pattern needed — the function is already sequential.

### ADR-5: `.default` = Intensity 7 With All DSP Improvements
Pre-1.0 library, one consumer. Default gets better over time. Results may differ from pre-intensity versions.

## Algorithm Decisions

### #39 ACF Sharpening — Element-wise square (`vDSP_vsq`)
Monotonic, preserves ranking. Cube rejected (too aggressive, flips negatives). 1 vDSP call. Applied after ACF, before fusion. Full-band only (sub-band ACFs unsquared for voting). Note: ACF returns `let` — reassign to `var` before in-place `vDSP_vsq`. Negative ACF values become small positives — harmless in practice because they never form local maxima (peak extraction requires value > both neighbors).

### #60 Adaptive Thresholding — Running mean subtraction
`vDSP_vswsum` (500ms window / 50 samples at 100Hz onset rate) → divide → subtract → half-wave rectify. ~4 vDSP calls. Applied to full-band onset envelope only; sub-bands stay raw for voting. **Applied before ACF sharpening** (threshold first, sharpen second — compound effect is additive).

**`vDSP_vswsum` output alignment:** Output length is `N - windowSize + 1`. To realign with the original N-length envelope: allocate an N-length running mean buffer, fill indices `windowSize/2 ..< windowSize/2 + outputLength` with the `vDSP_vswsum` result divided by window size, fill the first `windowSize/2` and last `windowSize/2` indices with the global mean. Then subtract this buffer from the original envelope and half-wave rectify.

### #38 Sub-Band Normalization — Max normalization per band
`vDSP_maxv` + `vDSP_vsdiv` per band (8 calls, 2×4). Guards divide-by-zero (skip silent bands). Applied inside `computeMelOnsetEnvelopeWithSubBands()` before full-band sum. Gated by `normalizeSubBands: Bool` parameter.

### #24 Expand Candidates — 3→5
Change `count: 3` → `count: intensity.candidateCount`. Near-zero cost increase. Hypothesis — trace data will reveal true failure distribution. Can only help, never hurt.

## Intensity Level Mapping

| Intensity | Window | Candidates | Norm | Sharp | Thresh | Disambiguation | Fine Grid | Progressive |
|-----------|--------|-----------|------|-------|--------|----------------|-----------|-------------|
| 1 | 15s | 1 | - | - | - | Range normalize only | - | - |
| 2 | 30s | 3 | - | - | - | Range normalize only | - | - |
| 3 | 30s | 3 | #38 | #39 | - | Sub-band voting | - | - |
| 4 | 30s | 3 | Y | Y | #60 | Sub-band voting | - | - |
| 5 | 30s | 5 | Y | Y | Y | Sub-band voting | Y | - |
| 6 | 30s→60s | 5 | Y | Y | Y | Sub-band voting | Y | <0.40 |
| 7 | 30→60→90s | 5 | Y | Y | Y | Sub-band voting | Y | <0.40 |

**Window column = the windows `AudioAnalysisService` iterates over.** `BPMAnalyzer.estimateBPM()` still accepts `analysisWindowSeconds` as a parameter — the progressive loop in `AudioAnalysisService` passes each window size from `intensity.windowSizes` per iteration.

Level boundaries are implementation details — the API contract is ordinal (higher never decreases accuracy). Quick wins cost <20μs combined; gating exists for diagnostic comparison at levels 1-2, not performance. Intensity 1 still reads `maxSeconds` (120s) from disk — PCM read optimization is out of scope for Phase 1.

## OA300 Benchmark

**Corpus:** `/Users/rterhaar/Dropbox/OA300_OnsetAudio300` (~78 tracks, DnB-heavy, WAV/MP3/FLAC/M4A/AIFF)
**Ground truth:** Rekordbox BPMs → `oa300-ground-truth.json` (committed)
**Metrics:** Acc1 = ±2% exact, Acc2 = octave-correct ±2%
**Env-gated:** `OA300_CORPUS_PATH` — skips gracefully when unset
**Multi-intensity:** Runs at 1, 3, 5, 7. Per-corpus Acc1 monotonicity is asserted. Per-track regressions are printed as warnings (not failures — a track can legitimately shift between levels).

## Implementation Plan

### Tasks

- [ ] **Task 1: Convert OA300 ground truth to JSON**
  - File: `Tests/BoomBoomBoomKitTests/Fixtures/oa300-ground-truth.json` (new)
  - Action: Parse UTF-16 TSV, extract filename/BPM/subdir per track (including `R Tunes/`, `T Tunes/`, `Bad BPM/`). Filenames were verified against disk during spec creation — convert as-is. Runtime filename validation happens in the test suite (tracks not found on disk are skipped with a warning). Place in test target's `Fixtures/` directory (already has `.copy("Fixtures")` resource rule in Package.swift — no Package.swift changes needed).

- [ ] **Task 2: Create `AnalysisIntensity` struct**
  - File: `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` (new)
  - Action: `public struct` wrapping clamped `Int`. Static constants, computed properties per ADR-2. `ExpressibleByIntegerLiteral` must use same clamping path as `init(rawValue:)`. Levels 8-10 return identical properties to level 7.

- [ ] **Task 3: Create `BPMDiagnosticTrace` struct**
  - File: `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (new)
  - Action: `public struct BPMDiagnosticTrace: Sendable` with explicitly typed fields (all value types for Sendable safety):
    - `energyTransitionOffset: Int`
    - `analysisWindowDuration: Double`
    - `onsetEnvelopeLength: Int`
    - `subBandEnergies: [String: Float]` (keys: "kick", "snare", "crack", "hihat")
    - `acfTopLags: [(lag: Int, strength: Float)]`
    - `tempogramTopBPMs: [(bpm: Int, magnitude: Float)]`
    - `fusedTopBPMs: [(bpm: Int, score: Float)]`
    - `tps2TopBPMs: [(bpm: Int, score: Float)]`
    - `rawCandidates: [(bpm: Double, score: Float)]`
    - `disambiguationResult: (bpm: Double, score: Float)`
    - `subBandVoteDetail: [String: String]?` (nil when sub-band voting didn't run)
    - `refinedBPM: Double?` (nil when fine-grid didn't run)
    - `confidence: Double`
    - `intensityUsed: AnalysisIntensity`
  - Notes: All fields use `Int`, `Double`, `Float`, `String`, or tuples thereof — all `Sendable`. Use `var` fields internally, frozen on return from `estimateBPM()`. `tps2TopBPMs` = top BPMs after TPS2 harmonic enhancement (Step 7). If the Swift 6 compiler rejects tuple-typed properties on a public `Sendable` struct, replace tuples with small named structs (e.g., `struct BPMScore: Sendable { let bpm: Double; let score: Float }`). The existing public `AudioAnalysisResult.candidates` uses the same tuple pattern successfully, so this is likely a non-issue.

- [ ] **Task 4a: Add intensity parameter and gate pipeline stages**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action: Add `intensity: AnalysisIntensity = .default` parameter to `estimateBPM()`. **Remove `strategy` parameter** (it's dead code — never read inside the function). Gate stages via intensity properties:
    - `intensity.candidateCount` for `extractTopCandidates` count
    - `if intensity.useSubBandVoting` for Steps 10/10b — when false, set `subBandACFs = []` (empty array) so guards in both `resolveOctaveAmbiguity` and `confirmWithSubBandPeaks` trigger correctly
    - `if intensity.useFineGridRefinement` for Step 10c (currently runs unconditionally — add guard)
    - Skip sub-band computation at intensity 1-2: add `computeSubBands: Bool = true` parameter to `computeMelOnsetEnvelopeWithSubBands()`. When false, skip the sub-band envelope accumulation loop and return empty sub-band arrays in `OnsetEnvelopes`. Call site: `computeSubBands: intensity.useSubBandVoting`. At intensity 1-2, "Range normalize only" disambiguation means sub-band voting is skipped — range normalization is inherent in `extractTopCandidates`, no separate code path needed.
  - Notes: **Keep `analysisWindowSeconds` parameter** — `AudioAnalysisService` drives the progressive loop. `strategy` removal is internal-only (not public API), so no deprecation needed.

- [ ] **Task 4b: Add trace accumulation**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action: Add `enableTrace: Bool = false` parameter to `estimateBPM()`. Add `trace: BPMDiagnosticTrace?` to `BPMResult`. When `enableTrace` is true, declare `var trace = BPMDiagnosticTrace(...)` at top of function and populate fields imperatively after each pipeline step completes:
    - After Step 1: `trace.energyTransitionOffset = dropOffset`
    - After Step 3: `trace.onsetEnvelopeLength = onsetEnvelope.count`, `trace.subBandEnergies = ...`
    - After Step 4: `trace.acfTopLags = ...` (extract top 5 peaks from ACF)
    - After Step 5: `trace.tempogramTopBPMs = ...`
    - After Step 6: `trace.fusedTopBPMs = ...`
    - After Step 7: `trace.tps2TopBPMs = ...`
    - After Step 8-9: `trace.rawCandidates = candidates`
    - After Step 10: `trace.disambiguationResult = winner`, `trace.subBandVoteDetail = ...`
    - After Step 10c: `trace.refinedBPM = winner.bpm`
    - After Step 11: `trace.confidence = confidence`, `trace.intensityUsed = intensity`
  - Notes: No builder pattern. Simple imperative accumulation in a sequential function.

- [ ] **Task 5: Implement per-sub-band normalization (#38)**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action: Add `normalizeSubBands: Bool = false` to `computeMelOnsetEnvelopeWithSubBands()`. When true, normalize each band to [0,1] before full-band sum. Call site: `normalizeSubBands: intensity.useSubBandNormalization`. Also update the convenience wrapper `computeMelOnsetEnvelope()` to forward the parameter (or document it intentionally always passes `false`).

- [ ] **Task 6: Implement adaptive thresholding (#60)**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action: Add `adaptiveThreshold(envelope:onsetRate:)`. Implementation:
    1. `let windowSize = Int(0.5 * onsetRate)` (500ms)
    2. Allocate N-length `runningMean` buffer, fill with global mean (`vDSP_meanv`)
    3. Compute `vDSP_vswsum` on envelope → output length is `N - windowSize + 1`
    4. Divide output by `Float(windowSize)` → running mean values
    5. Copy into `runningMean` buffer at offset `windowSize / 2` (center-aligned)
    6. Subtract `runningMean` from envelope → `vDSP_vsub`
    7. Half-wave rectify → `vDSP_vthres` with threshold 0
  - Insertion point in `estimateBPM()` — after Step 3, before Step 4:
    ```
    var onsetEnvelope = onsetResult.fullBand  // change existing let to var
    if intensity.useAdaptiveThreshold {
        onsetEnvelope = adaptiveThreshold(envelope: onsetEnvelope, onsetRate: onsetRate)
    }
    // Steps 4, 4b, 5... use thresholded onsetEnvelope for ACF
    // Sub-band envelopes (onsetResult.subBands) remain unthresholded for voting
    ```

- [ ] **Task 7: Implement ACF peak sharpening (#39)**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action: After `var acf = computeAutocorrelation(onsetEnvelope)`, apply `vDSP_vsq` in-place when `intensity.useACFSharpening`. Full-band ACF only.

- [ ] **Task 8: Update `AudioAnalysisService` public API**
  - File: `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`
  - Action: Add `trace: BPMDiagnosticTrace?` to `AudioAnalysisResult`. Update the existing construction site (`AudioAnalysisResult(bpm:confidence:candidates:)`) to pass `trace: nil` (or `trace: result.trace` when enableTrace is true). New overload iterates `intensity.windowSizes` for progressive analysis, uses `intensity.progressiveThreshold`. Passes `intensity` and `enableTrace` to `BPMAnalyzer.estimateBPM()`. Deprecated overload maps strategy → intensity 7 and passes `trace: nil`. `BPMDisambiguationStrategy` enum kept in `BPMAnalyzer.swift` for source compat.

- [ ] **Task 9: Update existing tests**
  - File: `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift`, `AudioAnalysisServiceTests.swift`
  - Action: Migrate to new API. Add tests: `AnalysisIntensity` (clamping, conformances, properties at each level including 8-10), intensity 1/3/7 on click tracks, `enableTrace: true/false`, regression guard (±2 BPM at .default).

- [ ] **Task 10: Create OA300 benchmark test suite**
  - File: `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift` (new)
  - Action: Env-gated. Load JSON ground truth from test bundle. `benchmarkDefaultIntensity()` — Acc1/Acc2 report. `benchmarkMultiIntensity()` — per-corpus monotonicity assertion, per-track warnings. `benchmarkBadBPMSubset()` — trace-enabled, per-track summary.

- [ ] **Task 11: Add `make benchmark` target**
  - File: `Makefile`
  - Action: `benchmark` target running `swift test --filter OA300BenchmarkTests` with `OA300_CORPUS_PATH`. No default path — require env var. Usage: `OA300_CORPUS_PATH=/path/to/corpus make benchmark` (Makefile inherits caller's environment). Document this in the help target output.

- [ ] **Task 12: Update docs**
  - File: `TODO.md`, `_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md`, `CLAUDE.md`
  - Action: Add status notes to TODO.md items (partially addressed, not "completed"). Annotate brainstorming ideas #24/#38/#39/#47/#60 with implementation dates and spec cross-reference. Update CLAUDE.md: add `AnalysisIntensity` and `BPMDiagnosticTrace` to Key Types, update public API table, note `BPMDisambiguationStrategy` deprecation.

### Acceptance Criteria

- [ ] **AC 1:** `analyzeBPM(url:intensity:.default)` returns non-nil for valid audio, BPM 40-250, confidence 0-1.
- [ ] **AC 2:** Old `analyzeBPM(url:strategy:)` emits deprecation warning, uses intensity 7 internally.
- [ ] **AC 3:** `AnalysisIntensity(rawValue: 0)` clamps to 1; `AnalysisIntensity(rawValue: 15)` clamps to 10. Integer literal `let x: AnalysisIntensity = 42` also clamps.
- [ ] **AC 4:** Intensity 1 on 120 BPM click track returns result within ±4 BPM (relaxed — minimal pipeline).
- [ ] **AC 5:** Intensity 7 on 120 BPM click track returns ±2 BPM, confidence > 0.5.
- [ ] **AC 6:** `enableTrace: true` → `result.trace` non-nil with `rawCandidates`, `confidence`, `intensityUsed`.
- [ ] **AC 7:** `enableTrace: false` → `result.trace` is nil.
- [ ] **AC 8:** OA300 benchmark at intensity 7 — all tracks produce results, Acc1/Acc2 printed.
- [ ] **AC 9:** OA300 multi-intensity — per-corpus Acc1 monotonically non-decreasing (assertion). Per-track regressions printed as warnings.
- [ ] **AC 10:** `OA300_CORPUS_PATH` unset → benchmark tests skip gracefully.
- [ ] **AC 11:** `make benchmark` with valid `OA300_CORPUS_PATH` executes and prints report.
- [ ] **AC 12:** Intensity 3+ on 5 bundled click tracks — all within ±2 BPM (no quick-win regressions).

## Additional Context

### Dependencies
No external deps. Task order: 1 (JSON) parallel with 2-3 (types). 4a→4b (wiring). 5-7 (quick wins) need 4a. 8 (API) needs 2-7. 9 (tests) needs 8. 10 (benchmark) needs 1+8. 12 (docs) is last.

### Notes

**Risks:** Quick wins compound (threshold + sharpen) — could over-suppress weak correct peaks. AC 9 catches this. If monotonicity fails, compare adjacent intensity levels to isolate which DSP stage caused the regression (run corpus at each level independently). `vDSP_vswsum` edge padding is approximate — monitor on short windows.

**Limitations:** Intensity 8-10 placeholder (same as 7). `BPMDisambiguationStrategy` deprecated not removed. OA300 is DnB-heavy. Bundled MP3 fixtures lack ground-truth BPMs. Intensity 1 does not optimize PCM read time (`maxSeconds` still 120s).

**Phase 2:** ML tiebreaker (BNNS/CoreML), ratio-aware disambiguation, duration hint, combined API, `BPMEstimator` protocol, `maxSeconds` optimization for low intensity.
