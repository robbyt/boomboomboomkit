---
title: 'Post-Disambiguation Window Voting Merge Strategy'
type: 'feature'
created: '2026-03-28'
status: 'done'
baseline_commit: 'eee261d'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** All 6 clustering merge strategies operate on raw `BPMResult.candidates` -- spectral peaks extracted *before* octave disambiguation. This discards per-window sub-band voting results, causing clustering strategies to score 59.8% Acc1 vs maxConfidence's 69.5%. The merge layer has no strategy that leverages the disambiguation each window already performed.

**Approach:** Add a `windowVoting` merge strategy that votes on each window's final `result.bpm` (post-disambiguation) instead of merging raw candidates. When 2+ windows agree within 2% tolerance, use the consensus BPM; otherwise fall back to the highest-confidence window.

## Boundaries & Constraints

**Always:**
- Preserve all 7 existing strategies unchanged -- this adds an 8th case
- Use the same 2% BPM tolerance already used by Acc1 and existing clustering
- `CaseIterable` must include the new case (ablation benchmark iterates all cases)
- Return the trace from the window that contributed the winning BPM

**Ask First:**
- Whether to make `windowVoting` the new default (currently `maxConfidence`)

**Never:**
- Do not modify `BPMAnalyzer` or the per-window disambiguation pipeline
- Do not change `BPMResult` structure
- Do not modify `AudioAnalysisService` flow (it already passes all window results to merge)

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Consensus (2/3 agree) | Windows: [120.0, 119.8, 60.0] | BPM=120.0 (or 119.8), confidence from agreeing windows | N/A |
| Unanimous (3/3 agree) | Windows: [170.0, 170.2, 169.8] | BPM from highest-confidence window in cluster | N/A |
| No consensus | Windows: [120.0, 80.0, 160.0] | Falls back to maxConfidence (highest confidence window) | N/A |
| Single window (intensity <6) | Windows: [120.0] | Passes through unchanged (same as maxConfidence) | N/A |
| Two windows, disagree | Windows: [85.0, 170.0] | Falls back to maxConfidence | N/A |
| Two windows, agree | Windows: [170.0, 170.5] | BPM from higher-confidence window | N/A |
| Empty input | Windows: [] | Returns nil | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` -- add `windowVoting` case and implementation
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` -- unit tests in existing `CandidateMergingTests` suite
- `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift` -- already iterates `allCases`, will auto-include

## Tasks & Acceptance

**Execution:**
- [x] `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` -- add `windowVoting` case to enum and implement `mergeByWindowVoting(_:)`. Group each window's `result.bpm` by 2% tolerance, pick the cluster with the most window support, break ties by best confidence. If no cluster has 2+ windows, delegate to `maxConfidence` fallback. Return winning window's candidates/trace/confidence.
- [x] `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` -- add tests: consensus picks majority, unanimous picks best confidence, no-consensus falls back, single-window passthrough, empty returns nil, tie-breaking by confidence.

**Acceptance Criteria:**
- Given intensity 7 with 3 windows where 2 agree within 2%, when merging with `windowVoting`, then the consensus BPM is selected regardless of individual confidence scores.
- Given 3 windows with no pair agreeing within 2%, when merging with `windowVoting`, then it returns the same result as `maxConfidence`.
- Given `CandidateMergeStrategy.allCases`, when counted, then it includes 8 cases.
- Given `make benchmark`, when comparing `windowVoting` vs `maxConfidence`, then `windowVoting` Acc1 >= `maxConfidence` Acc1 on OA300 corpus.

## Design Notes

The key insight: `maxConfidence` works well because it picks one window's fully-disambiguated result. But it ignores agreement across windows. `windowVoting` adds consensus detection on top: if windows agree, trust the consensus; if they don't, fall back to maxConfidence. This is strictly additive -- it can only help when windows agree on the right answer, and defers to the proven fallback otherwise.

Implementation detail: the voting operates on `result.bpm` (scalar) not `result.candidates` (array). The winning result's `candidates` and `trace` are returned unchanged, preserving diagnostic fidelity.

## Verification

**Commands:**
- `swift build --build-tests` -- expected: compiles clean
- `swift test --filter CandidateMergingTests` -- expected: all pass including new windowVoting tests
- `OA300_CORPUS_PATH=/Users/rterhaar/Dropbox/OA300_OnsetAudio300 swift test --filter benchmarkMergeStrategies` -- expected: windowVoting row appears, Acc1 visible

## Suggested Review Order

**Strategy implementation**

- New `windowVoting` case: groups windows by final BPM, picks consensus or falls back
  [`CandidateMergeStrategy.swift:120`](../../Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift#L120)

- Enum case declaration and doc comment
  [`CandidateMergeStrategy.swift:47`](../../Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift#L47)

- Switch dispatch wiring in `merge()`
  [`CandidateMergeStrategy.swift:90`](../../Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift#L90)

**Tests**

- Consensus test: 2/3 windows agree, overrides higher-confidence outlier
  [`BPMAnalyzerTests.swift:1008`](../../Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift#L1008)

- Fallback test: no consensus delegates to maxConfidence
  [`BPMAnalyzerTests.swift:1038`](../../Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift#L1038)

- allCases count updated from 7 to 8
  [`BPMAnalyzerTests.swift:822`](../../Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift#L822)

- candidateCount capping filter updated to exclude windowVoting
  [`BPMAnalyzerTests.swift:994`](../../Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift#L994)

**Peripherals**

- CLAUDE.md updated to document 8 strategies
  [`CLAUDE.md:28`](../../CLAUDE.md#L28)

- Benchmark test description updated to "all 8 strategies"
  [`OA300BenchmarkTests.swift:177`](../../Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift#L177)
