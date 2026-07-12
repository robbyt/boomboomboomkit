---
title: 'Full analysis library integration'
type: 'feature'
created: '2026-07-12'
status: 'done'
baseline_commit: '45c4e0d'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/8-1-lufs-public-api-and-lufsreport-promotion.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The demo proves loudness with a second URL decode and owns lifecycle decisions that larger library consumers also need. Valid LUFS is currently discarded when BPM has no result, and a loudness-only graph cannot load playback.

**Approach:** Add an additive, one-decode library API that returns independent BPM/grid and loudness outcomes while preserving URL-backed BPM metadata behavior. Make the demo consume that API and retain only presentation, playback, and view state.

## Boundaries & Constraints

**Always:** Preserve existing `analyze`, `analyzeBPM`, and `analyzeLUFS` APIs and URL semantics. The new aggregate exposes optional BPM/grid plus `Result<LUFSReport?, LUFSAnalysisError>`; shared decode/cancellation errors throw. Decode to the union of the two caps (full file if either cap is full), then apply each feature's own cap before analysis. Demo state pairs every visible result with its source URL and clears atomically on invalidation.

**Ask First:** Do not change LUFS measurement algorithms, public loudness value semantics, or the existing BPM/beat-grid APIs.

**Never:** Do not add SwiftUI/Charts types to `Sources/`; do not hide a successful feature because another feature returned nil or its feature-specific error; do not reintroduce docs popovers or unrelated Epic-10 UI work.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Full success | Readable supported-rate audio | One decode; populated BPM/grid and `.success(report)` loudness | N/A |
| Loudness only | BPM has no result; LUFS measures | `bpmAndBeatGrid == nil`; `.success(report)` loudness remains consumable | Demo retains no-BPM banner and shows graph |
| LUFS unsupported rate | BPM succeeds; LUFS cannot measure | BPM/grid retained; loudness is `.failure(.unsupportedSampleRate)` | No aggregate throw |
| Shared failure | Unreadable URL or either cancellation closure fires | No partial aggregate published | Throw existing reader/cancellation error |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` -- URL/decode orchestration and public analysis facade.
- `Sources/BoomBoomBoomKit/LUFSReport.swift` -- reusable loudness result, options, and typed failure.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` -- demo consumer and result lifecycle.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` -- result-paired playback source selection.
- `Tests/BoomBoomBoomKitTests/SharedDecodeTests.swift` and `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift` -- library and demo regression coverage.

## Tasks & Acceptance

**Execution:**
- [x] `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` -- added `FullAnalysisResult` and `analyzeFull(url:options:lufsOptions:)`; one union-cap decode preserves URL metadata and independent feature outcomes.
- [x] `README.md` -- documented the aggregate API, its independent-result/error contract, and its relationship to decoded-audio composition.
- [x] `Tests/BoomBoomBoomKitTests` -- locked one-decode behavior, result parity, URL metadata preservation, loudness-only success, and per-feature LUFS failure.
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` and `ContentView.swift` -- consume `analyzeFull`, atomically pair loudness with source/window, and load playback for either visible analysis result.
- [x] `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests` -- cover loudness-only lifecycle/playback source behavior and existing dual-result behavior.

**Acceptance Criteria:**
- Given a supported input, when full analysis runs, then the service decodes the URL once and matches existing URL BPM/grid and LUFS outputs under the supplied caps.
- Given independent feature outcomes, when BPM is absent or LUFS is unsupported, then the successful outcome is available without changing standalone API contracts.
- Given a visible loudness report without a grid, when the user seeks or starts playback, then the demo uses the matching analyzed file.
- Given reanalysis, cancellation, failure, or reset, when current results invalidate, then no prior loudness graph or playback source remains visible or loaded.

## Spec Change Log

## Design Notes

`FullAnalysisResult` is intentionally additive: `bpmAndBeatGrid` preserves the established `CombinedAnalysisResult` shape, while loudness is independent because loudness and rhythmic analyzability are not coupled. The aggregate URL path is responsible for shared decode so applications do not have to choose between decode efficiency and URL-backed metadata corroboration.

## Verification

**Commands:**
- `make fmt && make lint` -- expected: formatter and static checks pass.
- `make test` -- expected: library regression suite passes, including full-analysis coverage.
- `make demo-test` -- expected: demo integration tests pass.
- `make demo-lint` -- expected: confidence-label audit passes.

## Suggested Review Order

**Reusable full-analysis API**

- Defines the additive, independently consumable aggregate result contract.
  [`AudioAnalysisService.swift:115`](../../Sources/BoomBoomBoomKit/AudioAnalysisService.swift#L115)

- Shares one union-cap decode while preserving feature-specific behavior and cancellation.
  [`AudioAnalysisService.swift:1470`](../../Sources/BoomBoomBoomKit/AudioAnalysisService.swift#L1470)

**Demo consumption and playback**

- Retains loudness with its source, enabling a valid loudness-only presentation.
  [`AnalysisViewModel.swift:238`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L238)

- Consumes the library aggregate instead of coordinating separate URL analyses.
  [`AnalysisViewModel.swift:476`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L476)

- Loads playback from either result's paired source URL.
  [`ContentView.swift:130`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L130)

**Consumer guidance and regression coverage**

- Documents when to use the aggregate API and how partial outcomes behave.
  [`README.md:181`](../../README.md#L181)

- Proves decode sharing, metadata parity, and independent feature outcomes.
  [`SharedDecodeTests.swift:502`](../../Tests/BoomBoomBoomKitTests/SharedDecodeTests.swift#L502)

- Proves loudness-only state selects playback and clears atomically.
  [`AnalysisViewModelSmokeTest.swift:123`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift#L123)
