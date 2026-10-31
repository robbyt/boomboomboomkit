---
title: 'Make rhythmic-region consensus the default BPM path'
type: 'feature'
created: '2026-10-27'
status: 'done'
route: 'dispatch'
review_loop_iteration: 1
baseline_commit: 'cd422b1d39fea6b106addf8a8771c9fc232e0a5a'
context:
  - '_bmad-output/implementation-artifacts/epic-13-context.md'
  - '_bmad-output/implementation-artifacts/spec-epic-13-rhythmic-window-quorum.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The new rhythmic-region BPM path improves the measured corpora, but callers still get the weaker first-transition path unless they set two options. Backward compatibility of default results is not a goal.

**Approach:** Make rhythmic-region selection with simple-majority window voting the default. Keep the old path explicitly selectable. Ship the hand-annotated DAWProject comparison and use it with OA300 and GiantSteps to explain the promotion.

## Boundaries & Constraints

**Always:** Set both `useRhythmicRegions = true` and `mergeStrategy = .windowVoting` in `Options()`, with `.simpleMajority` voting. Preserve explicit caller overrides and the separate beat-grid anchor. Keep historical A/B controls explicit in impact tests so a new default cannot silently rewrite the baseline. Report per-track gains and losses, including the four DAW audio files with conflicting annotations.

**Never:** Add a tempo-change map, tune on the signed Story 12.7 holdout, change selector geometry, or treat the DAWProject training collection as an independent holdout.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Normal BPM call | `Options()` and a full track | Rhythmic regions plus final-BPM majority voting | Existing best-result fallback when no pair agrees |
| Explicit legacy path | `useRhythmicRegions = false`, `mergeStrategy = .maxConfidence` | Pre-promotion result and trace | Existing behavior |
| DAW label conflict | One audio file with distinct warp BPM labels | Excluded from accuracy denominator and listed in report | No arbitrary label chosen |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `Options` currently defaults to `useRhythmicRegions = false` and `.maxConfidence`; both must change for the tested C configuration.
- `Tests/BoomBoomBoomKitTests/RhythmicRegionIntegrationTests.swift` — old-path signature test relies on `Options()`; make legacy settings explicit and add a true-default assertion.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift`, `SharedDecodeTests.swift`, `AccuracyFloorTests.swift` — pin tests of the old window sequence to explicit legacy options; remove the stale known failure for the now-correct x-ray fixture; test cancellation between default-selected regions.
- `Tests/BoomBoomBoomKitBenchmarkTests/RhythmicRegionImpactTests.swift` — A/B controls currently inherit defaults; pin their old settings before promotion.
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift`, `GiantStepsBenchmarkTests.swift`, `DAWOracleBenchmarkTests.swift` — separate historical exact-baseline controls from current-default corpus measurements.
- `Tests/BoomBoomBoomKitBenchmarkTests/RhythmicRegionDAWProjectTests.swift` — env-gated Release comparison of A/C/D, using labels from `scripts/dawproject-bpm.py` and embedded archive audio. Keep per-file results.
- `README.md`, `CLAUDE.md` — revise default and opt-out guidance.
- `_bmad-output/implementation-artifacts/13-rhythmic-region-dawproject-impact-report.json` — measured 283 consistent unique files: Acc1 A 224, C 236, D 238; Acc2 A 238, C 249, D 254. C gained 25 and lost 13 Acc1 cases against A. Four conflicting files excluded. C trails D by 2 Acc1 and 5 Acc2 here; OA300 C and D tie at 60/82 Acc1, while GiantSteps C leads D 573 to 564 Acc1. C remains the best-supported rhythmic default, not a claim that rhythm scoring alone caused the improvement.

## Tasks & Acceptance

**Execution:**
- [x] `AudioAnalysisService.swift` — make C the default pairing and document explicit overrides.
- [x] `RhythmicRegionIntegrationTests.swift`, `RhythmicRegionImpactTests.swift` — test default configuration, preserve old-path golden check, pin historical controls.
- [x] `RhythmicRegionDAWProjectTests.swift`, DAW impact report — make the supplementary comparison reproducible and retain all per-track outcomes.
- [x] `README.md`, `CLAUDE.md` — explain the new default, fallback, and tradeoff plainly.
- [x] Verify Release tests, OA300 and GiantSteps floors, and documentation; changes are on `rterhaar/13-default-rhythm`, rebased from the merged PRs onto current `develop`.

**Acceptance Criteria:**
- Given an unconfigured `Options()`, when BPM analysis runs, then it selects rhythmic regions and votes on their final BPMs with simple majority.
- Given explicit legacy options, when the golden fixture runs, then BPM, confidence, candidates, and trace remain at their recorded legacy values.
- Given the four conflicting DAW annotations, when the report is regenerated, then none contributes to the 283-file denominator.
- Given the full measured corpora, when benchmark gates run, then OA300 and GiantSteps do not regress below the measured C counts and no nil result appears.

## Implementation Notes

- PRs #209 and #210 landed as squash commits `f919ea1a36a6d3787018b00f56c3d9ff0a02fd1a` and `24746ddc0232c0414746face5b19c6f158587295`. The attempted rebase replayed their original commits and conflicted; it was aborted, and the default-promotion stash applied cleanly on new branch `rterhaar/13-default-rhythm` from `develop`. The recorded `baseline_commit` is the original pre-merge stack head and remains unchanged for provenance.
- `make test` passed 1,224 tests with three pre-existing known accuracy issues. `make benchmark` passed with default strict Acc1/Acc2 at 60/82 and 76/82; `make benchmark-giantsteps` passed with 573/661 and 579/661. Both retained explicit historical controls and asserted complete denominators without nil analyses. `make oracle` passed before the review tightening; its code was unchanged afterward. The DAW Release report rerun reproduced 283 consistent files, four conflicts, A/C/D Acc1 of 224/236/238, no nil analyses, and C-versus-D gains/losses of 9/11. `make fmt`, `make lint`, `make docc-validate`, and `git diff --check` passed; SwiftLint prints one pre-existing nesting warning in `PerformanceBenchmarkTests.swift`.

## Spec Change Log

## Review Triage Log

Three independent internal reviewers checked the promotion diff. Their overlapping findings were resolved as follows:

| Finding | Decision | Evidence / resolution |
|---|---|---|
| Default OA300 and GiantSteps gates still allowed the old floors | Fixed | The strict default tests now enforce C counts, the full denominators, and no nil analyses. |
| Benchmark helpers forced the promoted settings instead of reading `Options()` | Fixed | Optional overrides now leave production defaults untouched; historical controls pass explicit legacy values. |
| DAW label grouping accepted zero or negative BPM | Fixed | Such labels are excluded, with a focused selection test. |
| DAW report could be overwritten by a partial run | Fixed | All arms, counts, and expected results are required before the atomic write. |
| DAW report lacked C-versus-D per-track flips | Fixed | Added gain and loss lists to the regenerated report. |
| Public trace, merge-policy, intensity, and README text described the former default | Fixed | Docs now distinguish rhythmic-region defaults from explicit legacy windows and the separate beat-grid anchor. |
| DAW report lacks a full source-archive digest | Deferred | The report records every analyzed file, source script, labels, and outputs. The local archive is an operator-provided training collection, not a signed holdout; hashing all embedded audio solely for this supplementary report adds substantial I/O without changing the comparison. Reopen if the report becomes a release gate or is shared as an independently reproducible benchmark. |

## Verification

**Commands:**
- `make fmt`, `make lint`, `make test`, `git diff --check` — source and focused tests clean.
- `make benchmark`, `make benchmark-giantsteps` — full default-path corpus gates pass.
- `make oracle` — DAW oracle benchmark passes.
- `swift test -c release --filter RhythmicRegionDAWProjectTests` with the DAW env paths — paired A/C/D report reproduces the 283-file counts.
