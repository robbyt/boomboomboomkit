---
title: 'Demo parameter help popovers driven by library per-case docs'
type: 'feature'
created: '2026-07-19'
status: 'done'
review_loop_iteration: 0
baseline_commit: 8803c8ff032c9f741ac80271db5334a5bc35ddf0
context:
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** In the BoomBoomBoomBPM demo, only the Merge strategy control shows a per-value help popover sourced from the library's authored per-case docs. The Intensity slider (`AnalysisIntensity`, 10 authored `levelN.md` docs) has no help affordance at all, and the Ensemble control has only a one-line subtitle. The library docs are the single source of truth, but the demo surfaces them for one enum-backed control out of three.

**Approach:** Extend the existing `HelpButton` + `DemoDocumentedCase` + `BoomBoomBoomKitDocs` mechanism (already used by Merge strategy) to the other two enum-backed controls. Add thin demo adapters, `IntensityDoc` and `EnsembleDoc`, that carry only the library `(kind, id)` doc keys, so popover content comes from the library markdown and changes with the selection. No doc prose is authored in the demo; it stays a thin lens onto the library docs.

## Boundaries & Constraints

**Always:**
- Doc content resolves from the library via `BoomBoomBoomKitDocs.attributedString(for:id:)` using library-derived keys (`Type.documentedKind`, `case.documentationID`). The demo adapters must never hardcode doc prose or a literal doc id string.
- Mirror the shipped Merge-strategy pattern exactly: a `nonisolated struct … : DemoDocumentedCase` adapter plus a header-row `HelpButton(case:)` beside the control label. Adapters are `nonisolated` so off-actor logic tests reach them.
- The library types are NEVER conformed to `DemoDocumentedCase` (KDD-E1); wrap them in demo adapters.
- Keep every existing dynamic caption/subtitle line as-is (Intensity label, Ensemble subtitle) — the popover is additive, not a replacement.
- No library (`Sources/`) or `Tests/` changes: `AnalysisIntensity` already conforms to `DocumentedCase` and all 10 `levelN.md` docs ship. This is demo-only.

**Ask First:**
- Any change to the `EnsemblePreset` case set, rawValues, `displayName`, `subtitle`, or `policy` mapping (all test-locked and UserDefaults-persisted). This spec does not change them.
- Fully realigning the demo Ensemble presets to be 1:1 with library `EnsemblePolicy` cases (dropping the curated `mlAugmented`/`trustFileTags` weightings). Deferred as a separate goal (see Design Notes); do not attempt here.

**Never:**
- No changes to numeric/bool controls (analyze-seconds, refine-grid-tempo, use-loaded-model) — they keep their current static `.help()` tooltips; per-value doc popovers do not apply to a `Double`/`Bool`.
- No new markdown docs, no edits to `Sources/BoomBoomBoomKit/Resources/Documentation/`.
- No re-layout of unrelated controls; no change to re-analyze/debounce behavior.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Intensity help changes per level | Slider at level 3, then dragged to level 7 | `?` popover shows `AnalysisIntensity/level3.md` prose, then `level7.md` prose | N/A |
| Ensemble help changes per preset | Preset = DSP only, then Default | `?` popover shows `EnsemblePolicy/dspOnly.md`, then `default.md` | N/A |
| Ensemble weightedVoting collapse | Preset = ML augmented, then Trust file tags | Both show `EnsemblePolicy/weightedVoting.md`; the per-preset subtitle line still differs and disambiguates | N/A |
| Missing/renamed doc id | Adapter yields a `(kind, id)` with no resource | Accessor returns its own "Documentation unavailable for <kind>.<id>." string; no crash | Accessor-owned fallback |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift` -- `DemoDocumentedCase` protocol + generic `HelpButton`; the reused mechanism (no change needed).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift` -- `MergeStrategyDoc` adapter; the exact pattern to mirror. New adapters land here or in a sibling file.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` -- `controlsSection` (~336): Intensity block (343-356) needs a header row with the `?`; Ensemble embed (436).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift` -- `EnsemblePreset` (case→`documentationID` mapping lives here); picker adds the `?` beside the "Ensemble" label.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/HelpButtonLogicTests.swift` -- adapter logic-test precedent to mirror.

## Tasks & Acceptance

**Execution:**
- [x] `StrategyDocs.swift` -- added `nonisolated struct IntensityDoc: DemoDocumentedCase` wrapping `AnalysisIntensity` (`kind = AnalysisIntensity.documentedKind`, `id = intensity.documentationID`, `controlName = "Intensity"`, `displayName` = "Level N" + named-alias suffix, `shortDescription` = "Analysis intensity level N of 10.").
- [x] `StrategyDocs.swift` -- added `nonisolated struct EnsembleDoc: DemoDocumentedCase` wrapping `EnsemblePreset` (`kind = EnsemblePolicy.documentedKind`; `id = preset.policy.documentationID` — library-derived, no hardcoded map; `controlName = "Ensemble"`, `displayName = preset.displayName`, `shortDescription = preset.subtitle`).
- [x] `EnsemblePresetPicker.swift` -- marked `EnsemblePreset` `nonisolated` (enabling change: its pure derivations must be off-actor for the `nonisolated` `EnsembleDoc`; no case/value/mapping change — locks still pass). Isolation-only, outside Ask-First.
- [x] `ContentView.swift` -- wrapped the Intensity label in a header `HStack { Text; HelpButton(case: IntensityDoc(...)); Spacer() }` above the slider; slider unchanged.
- [x] `EnsemblePresetPicker.swift` -- added the `?` header row via `HelpButton(case: EnsembleDoc(selection))` with an a11y-hidden "Ensemble" `Text` + `.labelsHidden()` Picker; kept the subtitle caption.
- [x] `HelpButton.swift` -- added `#Preview("Intensity help")` and `#Preview("Ensemble help")` mirroring the Merge-strategy preview (pin-layout-before-dev).
- [x] `HelpButtonLogicTests.swift` -- added off-actor logic tests: `IntensityDoc`/`EnsembleDoc` yield the correct `(kind, id)` (all 10 levels; all 4 presets incl. the two weightedVoting → "weightedVoting") and resolve to authored (non-fallback) docs.

**Acceptance Criteria:**
- Given the Intensity slider, when the level changes, then the `?` popover heading and prose change to that level's authored doc.
- Given the Ensemble picker, when the preset changes, then the `?` popover shows the mapped `EnsemblePolicy` doc; ML augmented and Trust file tags share the `weightedVoting` doc while their subtitle lines still differ.
- Given a control with a `?`, when VoiceOver focuses it, then it announces "Help for <control>: <case>" (per `HelpButton`'s label), matching Merge strategy.
- Given `make demo-lint` and `make demo-test`, when run, then both pass and no doc prose is duplicated into the demo (adapters carry only keys).

## Design Notes

**Ensemble collapse (honest limitation, in scope):** `mlAugmented` and `trustFileTags` are both `EnsemblePolicy.weightedVoting` with different `SignalWeights`, so both map to the single authored `weightedVoting.md`. The popover therefore cannot distinguish them; the existing per-preset `subtitle` line ("adds the trained classifier" vs "prefer ID3/MP4/Vorbis tempo tags") remains and carries that distinction. This is acceptable: the popover surfaces the real policy semantics, the subtitle surfaces the demo's weighting choice.

**Deferred (separate goal, do NOT do here):** Fully matching the demo Ensemble control to library `EnsemblePolicy` cases (1:1 presets) would mean dropping the curated `weightedVoting` presets or exposing raw `SignalWeights`, breaking `EnsemblePresetPickerTests` locks and persisted rawValues. Tracked in deferred-work.

**Layout (pin before dev, per CLAUDE.md Epic-10 rule):** Intensity gets the identical header-row treatment as Merge strategy (label + `?` + `Spacer` above the slider); Ensemble gets the `?` inline on the "Ensemble" label row above the subtitle. Add a `#Preview` mirroring the existing `HelpButton` preview so layout is validated pre-implementation.

## Verification

**Commands:**
- `make demo-fmt` -- expected: formats clean, no diff churn beyond intended files.
- `make demo-build` -- expected: BUILD SUCCEEDED.
- `make demo-lint` -- expected: pass (DEVELOPMENT_TEAM guard + FR-44 confidence-label / FR-43 no-diagnostic-leak audit).
- `make demo-test` -- expected: all tests pass, including the new `IntensityDoc`/`EnsembleDoc` logic tests and the unchanged `EnsemblePresetPickerTests` locks.

**Manual checks (operator GUI smoke — gates `done`, per CLAUDE.md demo-UI discipline; not covered by build/lint/test):**
- Drag the Intensity slider across levels; the `?` popover content changes per level and matches the on-screen level.
- Change the Ensemble preset across all four; the `?` popover changes; ML augmented and Trust file tags show the same weightedVoting doc with differing subtitles.
- VoiceOver: both new `?` buttons announce a control-qualified label; no duplicate announcement of the control name.
- Window resize / short window: the added header rows do not break the Parameters GroupBox layout.

## Suggested Review Order

**Design intent (the reused mechanism)**

- Entry point: the shipped adapter pattern the two new ones mirror (nonisolated struct, library-derived doc keys).
  [`StrategyDocs.swift:14`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift#L14)

**New adapters**

- Intensity adapter: `id` = library `documentationID` (`level<N>`); heading + shared alias suffix.
  [`StrategyDocs.swift:50`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift#L50)

- The library-derived alias suffix, shared with the slider label to prevent drift (review patch).
  [`StrategyDocs.swift:78`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift#L78)

- Ensemble adapter: `id` = resolved policy's `documentationID`; the two weightedVoting presets share one doc by design.
  [`StrategyDocs.swift:99`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift#L99)

**Enabling isolation change**

- `EnsemblePreset` marked `nonisolated` so the nonisolated adapter reads its pure derivations; no value change.
  [`EnsemblePresetPicker.swift:20`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift#L20)

**UI wiring**

- Intensity header row: label + `?` above the slider, mirroring Merge strategy.
  [`ContentView.swift:345`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L345)

- Ensemble header row: a11y-hidden label + `?` + labels-hidden Picker; subtitle retained.
  [`EnsemblePresetPicker.swift:112`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift#L112)

- Slider label now shares the alias suffix (review patch: de-duplicated).
  [`ContentView.swift:237`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L237)

**Peripherals (previews + tests)**

- Layout-pin previews for both popovers (Intensity preview slider rounds, per review patch).
  [`HelpButton.swift:158`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift#L158)

- Adapter logic tests: id drift pins for all 10 levels + 4 presets, and non-fallback doc resolution.
  [`HelpButtonLogicTests.swift:86`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/HelpButtonLogicTests.swift#L86)
