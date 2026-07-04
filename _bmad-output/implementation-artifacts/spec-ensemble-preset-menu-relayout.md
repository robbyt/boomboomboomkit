---
title: 'Ensemble preset: pop-up relayout under Merge strategy'
type: 'refactor'
created: '2026-07-03'
status: 'done'
baseline_commit: 5b6d6d80c36ea411228d480a85b91d5bd06432bf
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Ensemble preset control is a four-row radio group in its own `GroupBox("Ensemble")` above Parameters. It consumes a large block of vertical space at the top of the primary pane and reads as disconnected from the Merge strategy control it conceptually pairs with (both decide how signals combine).

**Approach:** Convert it to a compact pop-up menu matching the Merge strategy picker, relocate it into the Parameters `GroupBox` directly beneath Merge strategy, and render one description line below the pop-up that updates as the selection changes.

## Boundaries & Constraints

**Always:**
- Demo-only. `Demo/` stays on develop; `Sources/` and `Tests/` remain byte-untouched.
- Keep every `EnsemblePreset` data/logic member unchanged (`displayName`, `subtitle`, `policy`, `policyLiteral`, persistence). Reuse `subtitle` verbatim as the description source — single source of truth, so the verbatim test stays green.
- Preserve the picker's `.onChange`: persist then `triggerReanalyze()` (Story 9.1 DD5). Preserve the three honest-degradation captions (DD7) — move them with the control, don't delete.
- `make demo-lint` (FR-44 confidence-label + FR-43 no-diagnostic-leak audit) must pass.

**Ask First:**
- Changing any `subtitle` string, or adding a new prose property for the description — would touch the `verbatimNamesAndSubtitles` test and the Story 10.5 seam.
- Any change to the KDD-D1 preset→policy mapping or persistence keys.

**Never:**
- Do not add a "?" popover — that is the separately-planned Story 10.5 (Epic 10). This inline dynamic description supersedes 10.5's popover for THIS control only.
- Do not introduce `SignalPoolDiagnosticTable` into `ContentView` (FR-43); do not render a bare-numeric confidence value (FR-44).
- Do not change `EnsemblePolicy` mapping or the library.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Select a preset (file loaded) | Tap pop-up → pick e.g. "DSP only" | Pop-up shows `displayName`; description line below updates to that preset's `subtitle`; preference persists; run re-analyzes | N/A |
| Select a preset (no file) | Change preset before any drop | Persists + updates Copy Config; no re-analyze | N/A |
| ML augmented, no model | Preset `.mlAugmented`, `mlModelName == nil` | Description line + "No model loaded — ML signal is absent…" caption | N/A |
| ML augmented, model off | `.mlAugmented`, model loaded, `mlEnabled == false` | Description + "Model loaded but \"Use loaded model\" is off…" caption | N/A |
| DSP only, model on | `.dspOnly`, model loaded + enabled | Description + "DSP only ignores the loaded model…" caption | N/A |

</frozen-after-approval>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift` -- the control; convert `.radioGroup` → `.menu`, rows to `displayName`-only, add the dynamic description line, show the "Ensemble" label. Data members untouched.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` -- delete `ensembleSection` and its slot in the body `VStack`; insert `EnsemblePresetPicker` + its `.onChange` into `controlsSection` immediately after the Merge strategy `Picker`; move the three degradation captions there.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` -- `selectedEnsemblePreset` + `persistPreferredEnsemblePreset` (referenced, unchanged).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/EnsemblePresetPickerTests.swift` -- assert data + behavior only; no changes needed. Confirm still green.

## Tasks & Acceptance

**Execution:**
- [x] `EnsemblePresetPicker.swift` -- Replace the `.radioGroup` body: `Picker("Ensemble", …)` with `.pickerStyle(.menu)`, rows `Text(preset.displayName).tag(preset)`, remove `.labelsHidden()`; below it a `Text(selection.subtitle).font(.caption).foregroundStyle(.secondary)` description line. Update the stale `// REPLACED BY Story 10.5` comment to note the subtitle now renders as the inline dynamic description. -- delivers the pop-up + dynamic help text.
- [x] `ContentView.swift` -- Remove `ensembleSection` (var + body reference); place `EnsemblePresetPicker(selection:)` with its `persist + triggerReanalyze` `.onChange` directly after the Merge strategy `Picker` inside `controlsSection`; relocate the three honest-degradation captions beneath it. -- delivers the relocation under Merge strategy.

**Acceptance Criteria:**
- Given the app launches, then the primary pane shows no standalone `Ensemble` GroupBox above Parameters, and the Ensemble pop-up appears inside Parameters directly beneath "Merge strategy".
- Given the diagnostics inspector is closed, when the user changes the Ensemble preset, then the control still works and the run re-analyzes (FR-43 primary-view discipline).
- Given the demo test suite runs, then all `EnsemblePresetPickerTests` pass with zero changes to the test file.
- Given `make demo-lint` runs, then the FR-44/FR-43 audit passes.

## Design Notes

HIG cross-check (axiom-design/hig): the change trades the radio group (HIG-preferred for 2–5 exclusive options; shows all captions at once) for a pop-up. Justified by **Consistency** (two identical `.menu` pop-ups paired) and **Deference** (one dynamic caption instead of four always-on rows de-clutters the top of the pane). The discoverability the radio group gave up is mitigated by the always-visible dynamic description.

Reusing `subtitle` keeps a single source of truth and the `verbatimNamesAndSubtitles` test green; the strings are terse caption fragments, acceptable as secondary text. A fuller `helpText` property is a deferred option if richer prose is later wanted (Ask First).

New control body (target shape):

```swift
var body: some View {
  VStack(alignment: .leading, spacing: 4) {
    Picker("Ensemble", selection: $selection) {
      ForEach(EnsemblePreset.allCases, id: \.self) { preset in
        Text(preset.displayName).tag(preset)
      }
    }
    .pickerStyle(.menu)
    Text(selection.subtitle)          // updates with the selection
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}
```

Presentation-only (control style + placement + which text renders): no preset logic, persistence, or library behavior changes, so no new unit test is warranted — the existing 12 tests cover data/behavior; the visual result is confirmed by build + GUI smoke.

## Verification

**Commands:**
- `make demo-build` -- expected: BUILD SUCCEEDED
- `make demo-test` -- expected: all tests pass; `EnsemblePresetPickerTests` green with no test-file diff
- `make demo-lint` -- expected: `confidence-label-audit: PASS`, no DEVELOPMENT_TEAM leak
- `git diff --stat Sources/ Tests/` -- expected: empty (demo-only)

**Manual checks:**
- Launch the app: the Ensemble pop-up sits inside Parameters directly under "Merge strategy"; no standalone Ensemble GroupBox remains.
- Change the pop-up through all four presets: the description line updates each time.
- `ML augmented` with no model, and `DSP only` with a loaded+enabled model, each show the correct honest-degradation caption below the description.
- Narrow the window: the pop-up label, description, and captions stay legible and don't clip.

## Suggested Review Order

**Relocation & pairing (ContentView)**

- Core relayout: the ensemble picker now sits directly beneath Merge strategy, carrying its persist + re-analyze `.onChange` and the three degradation captions.
  [`ContentView.swift:309`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L309)

- The Merge strategy pop-up it now pairs with — the two "how signals combine" controls read together.
  [`ContentView.swift:287`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L287)

- The standalone `Ensemble` GroupBox is gone from the body stack.
  [`ContentView.swift:66`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift#L66)

**Control redesign (EnsemblePresetPicker)**

- Radio group → `.menu` pop-up; per-row `.accessibilityLabel` keeps VoiceOver descriptions (review patch).
  [`EnsemblePresetPicker.swift:100`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift#L100)

- Single description line bound to `selection.subtitle` — updates as the selection changes.
  [`EnsemblePresetPicker.swift:114`](../../Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift#L114)
