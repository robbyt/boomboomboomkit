---
title: 'Demo grid interaction and metadata chips'
type: 'bugfix'
created: '2026-07-12'
status: 'done'
baseline_commit: '5feca1a'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The beat-grid waveform always snaps click seeks, and its BPM-stage lock makes the blue extrapolated grid follow an inaccurate coarse BPM. Loudness and beat metadata are difficult to scan as free-form text rows.

**Approach:** Keep normal beat-snapped seeking, add Command-click for exact-time seeking, use the existing library grid-tempo refinement opt-in for the blue grid, and render both metadata groups as shared read-only chips.

## Boundaries & Constraints

**Always:** Keep the work demo-only; use `Options.refineBeatGridTempo` with `beatGridTempoLock == .off`; preserve headline BPM semantics; use SwiftUI modifier-key APIs; label every displayed value and preserve accessible label/value pairs.

**Ask First:** Halt if testing shows the supplied Lockbox WAV needs a new library fitting algorithm rather than the shipped refinement feature.

**Never:** Do not add a manual BPM control, change public library API, alter raw beat timestamps, or make metadata chips look or behave like toggles/buttons.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Beat snap | Plain waveform click | Seek to nearest valid raw detected beat | Invalid/empty beat list seeks raw click time; invalid geometry ignores tap |
| Exact seek | Command-click waveform | Seek to raw waveform time without snapping | Invalid geometry ignores tap |
| Refined grid | Refinement on / long constant-tempo input | Blue extrapolated grid uses refined tempo; headline BPM remains unchanged | Refinement abstention keeps the existing coarse grid safely |
| Metadata | Narrow analysis pane | Beat and loudness summaries stay a single horizontally scrollable chip row | Values retain existing unavailable formatting |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift` -- waveform gestures and beat metadata readout.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/LoudnessGraphView.swift` -- loudness metadata readout.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` -- grid refinement option control.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/BeatGridLogicTests.swift` -- pure seek behavior coverage.

## Tasks & Acceptance

**Execution:**
- [x] `BeatGridView.swift` -- track Command modifier state and pass a snap flag to pure seek derivation; expose normal and exact-seek help; replace vertical readout with shared metadata chips.
- [x] `LoudnessGraphView.swift` -- use the same chip row for integrated loudness, true peak, and loudness range.
- [x] `ContentView.swift` -- replace BPM-stage lock control with a refinement toggle and clear supporting copy.
- [x] `BeatGridLogicTests.swift` -- test snapped and unsnapped targets plus guards; add option-wiring coverage if a suitable demo test seam exists.

**Acceptance Criteria:**
- Given a valid grid, when the operator clicks the waveform, then playback seeks to the nearest raw beat; when Command-clicking, it seeks to the exact clicked time.
- Given a coarse BPM stage and a better onset-evidence grid fit, when refinement is enabled, then the blue grid can refine independently while the displayed headline BPM is unchanged.
- Given a beat or loudness result, when its readout is shown, then all metrics appear in one horizontal row of read-only labeled chips with accessible names and values.

## Spec Change Log

## Design Notes

The old `.bpmStage` control intentionally overrode the refined grid with the coarse BPM-stage value, so it is the wrong tool for visual drift correction. `refineBeatGridTempo` runs in the library where continuous onset evidence is available and is designed to preserve BPM-stage output. The chips reuse the prior demo’s compact bordered treatment, but omit the inline help controls that made the abandoned technique chips look interactive.

## Verification

**Commands:**
- `make fmt` -- expected: clean formatting.
- `make lint` -- expected: existing baseline warnings only.
- `make test` -- expected: all library tests pass.
- `make demo-lint` -- expected: pass.

**Manual checks:**
- Use the supplied Lockbox WAV to compare refinement off/on and confirm the blue grid improves without changing the hero BPM.
- Confirm normal-click versus Command-click seeking and inspect both chip rows at narrow width.

## Suggested Review Order

**Grid tempo behavior**

- The visible control now enables the library's onset-evidence refinement rather than stage locking.
  [`ContentView.swift:223`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L223)

- The demo explicitly prevents coarse BPM-stage locking from overwriting refinement.
  [`AnalysisViewModel.swift:439`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift#L439)

**Waveform interaction**

- Command state selects exact seeking while preserving ordinary beat snapping.
  [`BeatGridView.swift:103`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift#L103)

- Pure target derivation protects invalid geometry and arithmetic overflow.
  [`BeatGridView.swift:468`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift#L468)

**Metadata presentation**

- Shared chip chrome is deliberately read-only and exposes label/value accessibility semantics.
  [`AnalysisMetadataChip.swift:8`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisMetadataChip.swift#L8)

- Beat and loudness metrics use matching single-row horizontal chip layouts.
  [`BeatGridView.swift:320`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift#L320)

- Loudness values retain the true-peak caveat as both help and accessibility hint.
  [`LoudnessGraphView.swift:254`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/LoudnessGraphView.swift#L254)

**Regression coverage**

- Logic tests distinguish snapped, exact, and overflow-rejected seek targets.
  [`BeatGridLogicTests.swift:103`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/BeatGridLogicTests.swift#L103)
