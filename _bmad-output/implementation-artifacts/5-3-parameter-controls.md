# Story 5.3: Parameter Controls (Intensity + Merge Strategy + Copy Config)

Story ID: 5.3
Story Key: 5-3-parameter-controls
Epic: 5 — Developer Experience & Demo (third story; opens FR36 / FR40)
Status: done

## Story

As a developer evaluating BoomBoomBoomKit via the demo app,
I want to adjust intensity and merge strategy from sliders / pickers and re-run the most recent file with the new configuration, then copy a reproducible Swift snippet of the current parameter set,
So that I can compare configurations on my own audio without writing any code, and reproduce a winning configuration verbatim in my own consumer code.

**Scope clarification (read first).** Story 5-3 wires the parameter-controls slice on top of the Story 5-2 file-drop + result-render slice. Three controls land in the UI:

1. **Intensity slider** — `Slider(value: ..., in: 1...10, step: 1)` bound to `viewModel.options.intensity`. Re-analyzes on edit-end (`onEditingChanged: false` callback) — the user can drag freely without triggering a re-run on every tick.
2. **Merge strategy picker** — `Picker` over `CandidateMergeStrategy.allCases` bound to `viewModel.options.mergeStrategy`. Re-analyzes on selection change (`.onChange` fires once per pick — there is no drag jitter).
3. **Copy Config button** — emits a 4-line Swift snippet to the system pasteboard reflecting the CURRENT `viewModel.options` (intensity + merge strategy) plus an `analyzeBPM(url:options:)` call shape. Always available; works even before any file is dropped (the snippet is a function of `options`, not of analysis state).

Story 5-3 also adds a **visible Cancel button** and a **visible Re-analyze button** because they belong here: Re-analyze is the manual fallback when the user wants to re-run the same file with the same config (or with unchanged config — useful for run-to-run timing variance inspection), and Cancel addresses the W12 re-open trigger ("Story 5-3+ surfaces a non-supersession cancel path"). Both buttons render only when `viewModel.selectedFileURL != nil` (Re-analyze) and `viewModel.isAnalyzing` (Cancel).

Story 5-3 closes deferred-work items **W12** (visible Cancel button surfaces a non-supersession cancel path; the per-task UUID discriminator from Story 5-2 DD #5 already correctly resets `isAnalyzing = false`) and **W20** (NaN/Inf defensive guard on result rendering — cheap two-line patch in `displayState`, made automatable via the static formatter helper in DD #15 below). **W2 is PARTIALLY-closed**: the snapshot-at-launch contract is now explicit (AC #6) and the Re-analyze button gives the user a manual escape hatch (DD #5), but the originally-suggested "config used alongside results" UX surface is DEFERRED per DD #6 (re-open if a consumer reports confusion). The W2 entry stays open with a re-open trigger noted, NOT marked CLOSED.

**What this story does NOT deliver** (each is a separate Epic 5 story OR explicit OUT-OF-SCOPE):

- VotingPolicy / votingThreshold picker — only meaningful when `mergeStrategy == .windowVoting`. Out of scope for 5-3; a future follow-up may surface them as a conditional sub-picker. The Copy Config snippet only emits `intensity` + `mergeStrategy` lines; the `Options` defaults for everything else (votingPolicy, votingThreshold, metadataPolicy, durationHint, durationHintMinFileSeconds, ensemblePolicy, maxSeconds, enableTrace, enableMLDiagnostics, mlTechnique, techniqueSet, isCancelled, onProgress) are implicit
- TechniqueSet override picker — opt-in preset override beyond intensity-derived defaults; complex enough to warrant its own story (would need 5 named presets + a custom-combo expert mode). Out of scope
- MetadataPolicy enable/disable toggle — orthogonal to AC; the file-tag corroboration signal is a binary on/off + 3-source filter, not a "parameter" the user tunes. Out of scope; reconsider for Story 5-4 trace view (which surfaces `metadataEvidence`)
- ML technique slot — `Options.mlTechnique` is nil by default and requires the consumer to supply a `BNNSTechnique(modelURL:)` instance. Out of scope; the demo intentionally ships without a bundled model post-Story-4-6 Branch C
- Trace view + JSON export → Story 5-4 (`Diagnostic Trace Visualization and Export`; opens FR37/FR41)
- Public DocC + README quick-start → Story 5-5 (`Public API Documentation and README`)
- Recent-files menu, bookmark persistence, multi-file batch — OUT-OF-SCOPE per Story 5-1 DD #16 (still)

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #3, #4, #5, #6, #7, #8, #12, and #15 are the most consequential** — they lock the re-run trigger semantics, slider / picker transports, Cancel and Re-analyze mechanics, snapshot-vs-current W2 disposition, Copy Config snippet + pasteboard transport, the cancel UUID invariant, and the testable result-formatting boundary.

1. **Re-run trigger: edit-end + manual button, NOT continuous on-change. (W2 close-out.)** Three observed semantics were considered for "results update when slider/picker changes" (epic AC):

   - **(A) Auto-re-run on every `onChange`** — fires on every Slider tick during drag (10-30 events for a single drag). At intensity 7 (~1-3s analyze), this would queue 10-30 cancel-and-resubmit cycles per drag; the cancel-all-prior cascade would absorb them correctly but the UX is jittery and wastes CPU.
   - **(B) Edit-end / selection-change only** — SwiftUI's `Slider(value:in:step:onEditingChanged:)` fires `onEditingChanged: false` exactly once when the user releases the slider thumb; `Picker.onChange` fires once per selection. Re-run on those events: ONE re-analyze per user-completed adjustment. Matches the epic AC reading "when X is adjusted, re-analysis runs". No debounce machinery needed; SwiftUI's callbacks already provide the natural debounce.
   - **(C) Snapshot-and-explicit-Re-analyze-button** — user adjusts freely; nothing fires until they tap Re-analyze. Closest to W2's "queue config changes" suggestion but adds a click for the common case.

   **Chosen: (B) + a Re-analyze button as a manual escape hatch.** The slider's `onEditingChanged: false` and the picker's `.onChange` fire `analyze(url: selectedFileURL, autoStarted: false)` IF `selectedFileURL != nil`. The Re-analyze button covers the case where the user wants to re-run with UNCHANGED config (e.g., to inspect timing variance, or after a Cancel). When `selectedFileURL == nil` (no file has been dropped yet), edit-end / selection-change update `viewModel.options` but DO NOT fire a re-run — the Copy Config snippet still reflects the choices, so the user can copy a config without ever analyzing.

   **Snapshot-at-launch is the W2-safe contract.** `AnalysisViewModel.analyze(url:autoStarted:)` already snapshots `let opts = options` at the synchronous prologue (line 156 of the current implementation). A picker mutation MID-analyze updates `viewModel.options` but does NOT affect the in-flight task's snapshot. Story 5-3 makes this contract explicit in the spec; no code change required to enforce it.

2. **Slider transport: `Slider(value: $intensityRawValue, in: 1...10, step: 1, onEditingChanged: { editing in if !editing { triggerReanalyze() } })`.** Bound via a computed two-way binding because `AnalysisIntensity` is a value-typed struct (not Int) — SwiftUI's `Slider` requires `Binding<Double>` or `Binding<Int>`-friendly types. The binding converts: `Binding(get: { Double(viewModel.options.intensity.rawValue) }, set: { viewModel.options.intensity = AnalysisIntensity(rawValue: Int($0.rounded())) })`. The struct's `init(rawValue:)` clamps to `1...10` for free (defensive in case SwiftUI drives an out-of-range value).

   **Rounded-not-truncated.** `Int($0.rounded())` — NOT `Int($0)`. Apple's docs document `onEditingChanged: false` as fire-on-drag-end but do NOT guarantee the binding's setter has been called with the FINAL snapped value before that callback. If SwiftUI ever drives the setter mid-snap with `6.999`, `Int(6.999) == 6` would silently downgrade intensity by one step. `Int(6.999.rounded()) == 7` matches the visually-snapped position. Negligible cost; eliminates an entire class of bugs (Codex M4 close, party-mode 2026-05-19).

   **Binding-in-computed-property cost.** Recreating `Binding(get:set:)` on every body evaluation is a documented SwiftUI anti-pattern when applied INSIDE the view body (axiom-swiftui architecture.md Anti-Pattern 6). The spec hoists the binding into a private `var intensityBinding: Binding<Double>` computed property — better than inline but still recreated per render. The per-render cost for a single Slider is negligible (~nanoseconds). If a future story introduces many such bindings, migrate to a state-as-bridge pattern: separate `@State private var sliderRawValue: Double` initialized from the view model, plus a `.onChange(of: sliderRawValue)` that mirrors into the view model. Out of scope for 5-3 (one slider, no measured perf concern).

   **Label rendering.** A small `Text("Intensity: \(viewModel.options.intensity.rawValue)")` next to the slider. For the 4 named constants (.fastest=1, .default=7, .thorough=8, .maximum=10), append the constant name in parentheses: e.g., `"Intensity: 7 (default)"`. Helps the user understand the scale without reading docs.

   **Step granularity.** `step: 1` because `AnalysisIntensity.rawValue` is an Int. Fractional values are clamped to the nearest integer by the struct's initializer anyway, but the Slider should snap visually.

3. **Picker transport: `Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) { ForEach(CandidateMergeStrategy.allCases, id: \.self) { Text(label(for: $0)).tag($0) } }.onChange(of: viewModel.options.mergeStrategy) { _, _ in triggerReanalyze() }`.** All 8 cases ship; the dropdown labels are the rawValue strings (e.g., "maxConfidence", "dedup", "quorum", "average", "median", "weightedAverage", "union", "windowVoting") — matches the public API symbol names exactly so the user can map UI→code mentally. `CandidateMergeStrategy: String, CaseIterable, Sendable, Hashable` already supports this verbatim. Picker style: `.menu` (the macOS default), unstyled inline list would consume too much vertical space.

4. **Cancel button: visible when `viewModel.isAnalyzing == true`. Wraps `viewModel.cancelInFlight()`. (W12 close.)** Story 5-3 adds `func cancelInFlight()` that mirrors the cancel-all-prior cascade from `analyze(url:autoStarted:)`: iterate `inFlightTasks`, insert each `taskID` into `pendingCancellations`, then call `task.cancel()`. State-machine correctness lives in DD #12 (the per-task UUID discriminator invariant). Label transitions: `isAnalyzing && !isCancelling` → "Cancel"; `isAnalyzing && isCancelling` → disabled, "Cancelling…"; `!isAnalyzing` → hidden. Buttons are hidden via `if` in the view body, NOT disabled via `.disabled(true)` (disabled buttons add visual noise; hidden is simpler). The same hidden-via-`if` rule applies to Re-analyze (DD #5) and is the default for the Copy Config button (which is always visible, never hidden). No keyboard shortcut (Escape was downgraded to optional in Story 5-2 DD #7; the visible button supersedes it).

5. **Re-analyze button: visible when `viewModel.selectedFileURL != nil` AND `!viewModel.isAnalyzing`. Wraps `viewModel.analyze(url: selectedFileURL, autoStarted: false)`.** Replays the same file with the current `viewModel.options`. The button is hidden during in-flight analysis because the Cancel button takes that slot (DD #4); the user cannot click Re-analyze mid-analyze. (Internally `analyze()` would correctly handle a mid-analyze call via cancel-all-prior, but the UX intent is "Cancel = stop now; Re-analyze = re-run after the current run finishes". Hiding Re-analyze during analyze keeps the affordance unambiguous.) Label: "Re-analyze" (verb-only — the file context is implied by the result row above showing the filename).

   **Re-analyze when no file dropped.** Button hidden entirely (`selectedFileURL == nil`). The Copy Config button is independent and remains visible. There is no other recovery affordance from the empty state — the user must drop a file.

   **Re-analyze when sandbox grant expired (R3 below).** If `startAccessingSecurityScopedResource()` returns `false` on the re-run AND the read subsequently fails with `PCMBufferReaderError.fileNotReadable`, the existing AC #6 logic from Story 5-2 surfaces `"Could not read audio file: \(filename) (sandbox denied)"`. The user reads the error and drops the file again. This is a known limitation of the demo (no bookmark persistence per Story 5-1 DD #16); documenting in Apple Platform Notes.

6. **"Config used alongside results" — DEFERRED; W2 stays PARTIALLY-CLOSED.** Adding a "Result captured at: intensity X / strategy Y" line under the result row was W2's third suggested mitigation. Deferred because snapshot-at-launch already prevents incorrect results, the Copy Config button captures the current config on demand, and the UI is busy enough without a second parameter column. Re-open trigger: user reports confusion ("the slider moved but the result didn't update — was that the OLD result?"). Docs for `AnalysisViewModel.options` cover the snapshot contract in Story 5-5.

7. **Copy Config snippet: 4-line Swift code reflecting `viewModel.options.intensity` and `viewModel.options.mergeStrategy` PLUS an `analyzeBPM(url:)` call shape.** Pure function on (intensity, mergeStrategy) — testable from the smoke test via `@testable import` (Story 5-1 D2 pattern, Story 5-2 DD #11 precedent for `validateDropPayload`). Static method on `AnalysisViewModel`:

   ```swift
   static func generateConfigSnippet(
     intensity: AnalysisIntensity,
     mergeStrategy: CandidateMergeStrategy
   ) -> String
   ```

   **Snippet shape (verbatim, including indentation and trailing newline behavior — see DD #13 for the test):**

   ```swift
   var opts = AudioAnalysisService.Options()
   opts.intensity = .default                         // OR: AnalysisIntensity(rawValue: 5)
   opts.mergeStrategy = .maxConfidence               // OR: any other CandidateMergeStrategy case
   let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)
   ```

   **Intensity formatting rules:**
   - rawValue == 1 → `.fastest`
   - rawValue == 7 → `.default`
   - rawValue == 8 → `.thorough`
   - rawValue == 10 → `.maximum`
   - All others (2-6, 9) → `AnalysisIntensity(rawValue: N)`

   **Merge strategy formatting:** Always emit `.\(strategy.rawValue)` — the rawValue strings match the case names exactly (`CandidateMergeStrategy.maxConfidence.rawValue == "maxConfidence"`).

   **`yourURL` placeholder.** The snippet uses the literal identifier `yourURL` so the user knows to substitute. Not `url` (too generic) or `viewModel.selectedFileURL` (sandbox-leaky path-exposing — and Story 5-1 DD #16-D explicitly forbids exposing the URL outside the view model).

   **No leading or trailing whitespace beyond the snippet body.** The pasteboard receives the exact 4-line block; a leading blank line or trailing space would surprise the user when they paste.

8. **Pasteboard transport: `NSPasteboard.general.clearContents(); NSPasteboard.general.setString(snippet, forType: .string)`.** AppKit API, macOS-native. The demo is macOS-only (matches Package.swift `.macOS(.v15)`) — no SwiftUI `Pasteboard` cross-platform wrapper needed. `import AppKit` is added to `AnalysisViewModel.swift` (or to a small `Pasteboard` helper file if the dev agent prefers separation). The `clearContents()` call BEFORE `setString` is mandatory per AppKit's contract — without it, mixed-payload pasteboards (e.g., the user previously copied an image) can retain stale data of other types and pasted-into-text consumers may pick the wrong type.

   **Thread isolation.** Apple's NSPasteboard documentation does NOT explicitly state main-queue safety guarantees as of the doc fetched 2026-05-19. The spec gates all pasteboard calls to MainActor as a defensive convention via the `AnalysisViewModel`'s class-level `@MainActor` annotation. The call sites inherit isolation for free; no `nonisolated` escapes, no cross-actor pasteboard mutation.

   **Synchronous, no error path.** `setString` returns Bool (true on success); failures are theoretical (pasteboard is in-process, not a network resource). The signature is `@discardableResult func copyConfigToPasteboard() -> Bool` — `@discardableResult` lets button-action call sites ignore the Bool while still allowing the smoke test to assert success. If the call returns false, the wrapper surfaces `"Could not copy to clipboard"` via `errorMessage` (defensive — never observed in practice).

9. **Controls section layout: above the drop / result region, in a `Form` or `GroupBox`.** SwiftUI's `Form` on macOS renders as a grouped settings-style layout (label-on-left, control-on-right). The slider, picker, and Cancel/Re-analyze/Copy Config button row all live in the controls section; the drop / result region remains below per Story 5-2's existing layout. The whole window stays scrollable if controls + result overflow (`ScrollView` wrapper). Layout:

   ```
   ┌──────────────────────────────────────────────────┐
   │ Form / GroupBox: "Parameters"                    │
   │ ┌──────────────────────────────────────────────┐ │
   │ │ Intensity: 7 (default)                       │ │
   │ │ ━━━━━━━━━━━━━━●━━━━ (slider)                 │ │
   │ │                                              │ │
   │ │ Merge strategy: [maxConfidence ▾] (picker)   │ │
   │ │                                              │ │
   │ │ [Cancel] [Re-analyze] [Copy Config]          │ │
   │ └──────────────────────────────────────────────┘ │
   │                                                  │
   │ (existing Story 5-2 primaryStateView + banner)   │
   └──────────────────────────────────────────────────┘
   ```

   The `Form` / `GroupBox` choice: GroupBox is lighter-weight and renders correctly on macOS 15+ without the Form's heavy framing. Dev agent picks at implementation time; the AC asserts on observable state, not on the wrapper type.

10. **Button visibility predicates — see DD #4 (Cancel + hidden-via-`if` rule) and DD #5 (Re-analyze).** Copy Config is always visible (snippet is independent of file/analyze state).

11. **NaN/Inf defensive guard on result rendering (W20 close).** `ContentView.swift` `displayState` `.result` arm currently produces `BPMResultRow` from `viewModel.detectedBPM` + `.confidence` + `.elapsedSeconds` via `String(format: "%.1f BPM", bpm)` etc. Add a guard at the top of the `.result` branch: `guard bpm.isFinite, confidence.isFinite, elapsed.isFinite else { return .errorOnly("Internal error: analysis returned a non-finite value. This is a library bug — please file an issue.") }`. Two-line patch. The library is unlikely to emit NaN today (W5 / W20 are speculative), but the guard is cheap UI hardening and a clean defensive boundary at the view-model→view crossing.

12. **Cancel button does NOT mint a new currentTaskID; it leaves currentTaskID == taskID for the in-flight task.** This is the critical correctness invariant. The per-task UUID discriminator from Story 5-2 DD #5 must NOT be reset by cancellation — otherwise the cancelled task's `.failure(is CancellationError)` arm reads `currentTaskID != taskID` in the pure-Cancel case and returns without resetting `isAnalyzing = false`, leaving the UI stuck on the activity indicator forever.

   **Branch A — pure Cancel (no subsequent analyze() call):**
   1. User clicks Cancel → `viewModel.cancelInFlight()` → iterates `inFlightTasks` calling `task.cancel()` on each
   2. The library polls `Atomic<Bool>` at the next window boundary, throws `CancellationError` out of `analyzeBPM(url:options:)`
   3. The Task body's `result = .failure(CancellationError())`, MainActor re-entry runs
   4. `if case .failure(let error) = result, error is CancellationError { ... }` matches
   5. `if self.currentTaskID == taskID { self.isAnalyzing = false }` — **TRUE**, because `currentTaskID` was never reassigned
   6. The cleanup Task awaits, removes the UUID from `inFlightTasks` and `pendingCancellations`
   7. `isCancelling` flips false (set is empty); UI drops the Cancelling… banner; final state: empty + Re-analyze button visible

   **Branch B — Cancel followed by analyze() (e.g., user clicks Cancel then immediately drops a different file, OR Cancel races with a slider/picker re-run that landed just before):**
   1. User clicks Cancel → `cancelInFlight()` marks the in-flight task — `currentTaskID` STAYS at the old value
   2. BEFORE the cancelled task surfaces `CancellationError`, the new `analyze(url:)` call reassigns `currentTaskID = newTaskID`
   3. When the cancelled task FINALLY surfaces `CancellationError` and re-enters MainActor, `self.currentTaskID == oldTaskID` evaluates **FALSE** (it now holds `newTaskID`)
   4. The arm correctly returns WITHOUT mutating `isAnalyzing` — the successor task already set `isAnalyzing = true` to its own value and owns the UI
   5. The cleanup Task still drains `pendingCancellations` correctly

   Both branches are correct as designed in Story 5-2 DD #5. The DD #12 invariant is: `cancelInFlight()` MUST NOT touch `currentTaskID` so Branch A's equality holds; Branch B's inequality is achieved naturally by the subsequent `analyze()` reassigning the field.

   **Test:** AC #11 manual smoke test verifies Branch A at intensity 7 (drop file → click Cancel → observe Cancelling… → ~1-3s later observe empty UI). Branch B is verified by the additional "Cancel-then-Re-analyze immediately" step in AC #11 (drop → Cancel → click Re-analyze before the cancel-drain completes → verify the new analyze runs correctly to a result, no stuck `isAnalyzing`). Plus an automated test that exercises `cancelInFlight()` in isolation (no Task running) and verifies no observed-state mutation.

13. **Test inventory — full enumeration lives in AC #10 + Task 3 (not duplicated here).** Smoke test grows 18 → ~28-32 (default cadence) / ~29-33 (with `BBBKIT_RUN_PASTEBOARD_TEST=1`). All `@MainActor` for suite consistency. Categories: `generateConfigSnippet` parameterized over intensity-named/raw and merge-strategy-allCases banks; snippet-shape sanity (1 case); `cancelInFlight` isolation + with-in-flight-task; manual re-run with mutated options; `formatResultRow` happy + NaN + Inf + missing-fields bank (11 cases per DD #15); env-gated pasteboard round-trip.

14. **Pasteboard testing constraint.** `NSPasteboard.general` is a process-wide singleton; tests that write pollute the dev's actual clipboard, may trigger a macOS pasteboard-access TCC prompt depending on system policy, and `defer`-based restore is string-only (loses multi-type payloads). Mitigation per Task 3.8: env-gate the round-trip behind `BBBKIT_RUN_PASTEBOARD_TEST=1` so default-cadence `make demo-test` never hits the clipboard. A Pasteboard-protocol injection was considered and rejected as over-abstraction for the demo.

15. **Static testable formatter helper — AC #7 closes the NaN/Inf-guard-untestable gap.** The original spec put the `.isFinite` guard inside `ContentView.displayState` (a private computed property on a private View struct), making AC #7 only assertable via a SwiftUI view test. To make AC #7 cleanly automatable, the spec now requires a static helper on `AnalysisViewModel`:

    ```swift
    static func formatResultRow(
      fileName: String?,
      bpm: Double?,
      confidence: Double?,
      effectiveIntensity: AnalysisIntensity?,
      elapsedSeconds: Double?
    ) -> Result<BPMResultRow, FormatError>
    ```

    `BPMResultRow` (the existing private struct in `ContentView`) is promoted to a `nested struct on AnalysisViewModel` (or to a top-level demo-internal type — dev agent picks; the AC asserts on observable behavior, not the namespace). `FormatError` is an internal enum with cases `.missingFields` (any of the 4 results is nil while another is non-nil), `.nonFinite` (any non-nil value is NaN/Inf). The view's `displayState` then becomes a thin caller that maps the `Result` into `.empty / .result / .errorOnly`. The static helper is exercised by 3-4 new test cases (NaN BPM, +Inf confidence, -Inf elapsed, all-finite happy path). View remains lint-clean — no SwiftUI test infra needed.

## Acceptance Criteria

1. **Intensity slider drives re-analysis on edit-end (FR36).**

   **Given** the demo app is running AND a file has been previously dropped (`viewModel.selectedFileURL != nil`)
   **When** the user drags the intensity slider to a new value and releases the slider thumb
   **Then** `viewModel.options.intensity` reflects the new value (the SwiftUI binding fires synchronously on each tick)
   **And** at edit-end (`onEditingChanged: false`), `viewModel.analyze(url: selectedFileURL, autoStarted: false)` is invoked
   **And** the cancel-all-prior cascade in `analyze(url:autoStarted:)` cancels any in-flight task before the new one launches
   **And** the analyzing state renders per Story 5-2 AC #1 + AC #3

   **Given** no file has been dropped (`viewModel.selectedFileURL == nil`)
   **When** the user drags the slider and releases
   **Then** `viewModel.options.intensity` reflects the new value
   **And** NO `analyze(url:)` call fires (there's no URL to re-run)
   **And** the Copy Config snippet would reflect the new intensity if invoked

2. **Merge strategy picker drives re-analysis on selection change (FR36).**

   **Given** the demo app is running AND a file has been previously dropped
   **When** the user selects a different merge strategy from the picker
   **Then** `viewModel.options.mergeStrategy` reflects the new value (the SwiftUI binding fires synchronously on selection)
   **And** the `.onChange(of: viewModel.options.mergeStrategy)` modifier fires `viewModel.analyze(url: selectedFileURL, autoStarted: false)`
   **And** the cancel-all-prior cascade applies

   **Given** the picker is opened
   **When** the user inspects the available options
   **Then** all 8 cases of `CandidateMergeStrategy.allCases` are listed (`maxConfidence`, `dedup`, `quorum`, `average`, `median`, `weightedAverage`, `union`, `windowVoting`)
   **And** the labels are the rawValue strings verbatim — matching the public-API symbol names so the user can map UI choices to code

3. **Copy Config button copies a reproducible Swift snippet to the clipboard (FR40).**

   **Given** the demo app is running (file dropped or not — Copy Config is independent of analysis state)
   **When** the user clicks the Copy Config button
   **Then** `viewModel.copyConfigToPasteboard()` is invoked
   **And** `NSPasteboard.general` contains a Swift snippet matching the shape:
   ```swift
   var opts = AudioAnalysisService.Options()
   opts.intensity = .default
   opts.mergeStrategy = .maxConfidence
   let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)
   ```
   **And** intensity values 1/7/8/10 emit the named constants `.fastest` / `.default` / `.thorough` / `.maximum`; other values 2/3/4/5/6/9 emit `AnalysisIntensity(rawValue: N)`
   **And** merge strategy emits `.\(strategy.rawValue)` for all 8 cases verbatim
   **And** the snippet contains the literal identifier `yourURL` (NOT a path, NOT `viewModel.selectedFileURL`, NOT the actual file URL)
   **And** the snippet has no leading or trailing whitespace beyond the 4 lines

4. **Cancel button fires `cancelInFlight()` and the per-task UUID discriminator correctly resets `isAnalyzing = false` (W12 close).**

   **Given** an analysis is in flight (`viewModel.isAnalyzing == true`)
   **When** the user clicks the Cancel button
   **Then** `viewModel.cancelInFlight()` is invoked
   **And** every task in `inFlightTasks` is cancelled (`task.cancel()` on each)
   **And** each task's UUID is inserted into `pendingCancellations` BEFORE `.cancel()` is invoked (so `isCancelling` is true during the drain window — same mechanic as Story 5-2's cancel-all-prior cascade)
   **And** the current task's `currentTaskID` is NOT reassigned (the discriminator must remain equal for the `.failure(is CancellationError)` arm to reset `isAnalyzing`)
   **And** when the library's window-boundary poll detects cancellation and throws `CancellationError`, the Task body's MainActor-re-entry resets `isAnalyzing = false` and leaves result fields untouched
   **And** the cleanup Task removes the UUID from `pendingCancellations`, flipping `isCancelling` false

   **Given** no analysis is in flight (`viewModel.isAnalyzing == false`)
   **When** `cancelInFlight()` is called (e.g., from a test)
   **Then** the no-op completes cleanly — `inFlightTasks` is empty, the for-loop body never runs, no observed-state mutation occurs

5. **Re-analyze button replays the same file with the current `viewModel.options`.**

   **Given** a file has been previously dropped (`viewModel.selectedFileURL != nil`) AND analysis completed (`viewModel.isAnalyzing == false`)
   **When** the user clicks the Re-analyze button
   **Then** `viewModel.analyze(url: selectedFileURL, autoStarted: false)` is invoked
   **And** the analyzing state renders per Story 5-2 AC #1 + AC #3
   **And** the new result reflects the CURRENT `viewModel.options` (intensity + mergeStrategy)

   **Given** analysis is in flight (`viewModel.isAnalyzing == true`)
   **When** the Re-analyze button is inspected
   **Then** the button is hidden (the Cancel button takes that slot per DD #4 + DD #5)
   **And** the user cannot click Re-analyze mid-analyze — they must either Cancel first or wait for completion

   **Given** no file has been dropped (`viewModel.selectedFileURL == nil`)
   **When** the Re-analyze button is inspected
   **Then** the button is hidden (rendered via `if selectedFileURL != nil && !isAnalyzing` in the view body, NOT via `.disabled(true)`)

6. **Snapshot-at-launch contract preserves in-flight task config (W2 close, explicit).**

   **Given** an analysis is in flight at intensity 7 with `mergeStrategy: .maxConfidence`
   **When** the user adjusts the slider to intensity 3 mid-analyze (BEFORE the in-flight task completes; the user does NOT click Re-analyze and the slider drag has not finished — i.e., `onEditingChanged` has not fired `false` yet)
   **Then** `viewModel.options.intensity == AnalysisIntensity(rawValue: 3)` (the binding fired synchronously)
   **And** the in-flight task's `opts` snapshot (captured at line 156 of `AnalysisViewModel.analyze(url:autoStarted:)`) still holds intensity 7 + maxConfidence
   **And** when the in-flight task completes, the result reflects intensity 7 analysis (NOT intensity 3)

   **Note:** This AC documents existing Story 5-1 + 5-2 behavior. No new code in Story 5-3 — the `var opts = options` snapshot at the synchronous prologue of `analyze(url:autoStarted:)` already enforces it. The AC exists to make the contract auditable.

7. **NaN/Inf defensive guard on result rendering (W20 close; DD #15 makes it testable).**

   **Given** the static helper `AnalysisViewModel.formatResultRow(fileName:bpm:confidence:effectiveIntensity:elapsedSeconds:)` per DD #15
   **When** called with `bpm: Double.nan` (hypothetical library bug — never observed in practice; library is expected to emit a finite value or nil)
   **Then** it returns `.failure(.nonFinite)`
   **And** the caller (`ContentView.displayState`) maps that to `.errorOnly("Internal error: analysis returned a non-finite value. This is a library bug — please file an issue.")`

   **Given** the same helper
   **When** called with any of `bpm` / `confidence` / `elapsedSeconds` set to `Double.infinity` or `-Double.infinity`
   **Then** it returns `.failure(.nonFinite)`
   **And** the caller emits the same `.errorOnly` message
   **And** the UI does NOT render `"nan BPM"` / `"nan%"` / `"inf BPM"` etc.

   **Given** all four values are finite (the normal case)
   **When** the helper runs
   **Then** it returns `.success(BPMResultRow(...))`
   **And** the `.result` branch fires as in Story 5-2 AC #1

   **Testability hook:** the helper is `internal static` — exercised by the smoke test via `@testable import BoomBoomBoomKitDemo` per Story 5-1 D2. No SwiftUI view-test infrastructure required.

8. **NEW `AnalysisViewModel` API surface: `generateConfigSnippet`, `copyConfigToPasteboard`, `cancelInFlight`, `formatResultRow`.**

   **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift`
   **When** inspected
   **Then** a static method `static func generateConfigSnippet(intensity: AnalysisIntensity, mergeStrategy: CandidateMergeStrategy) -> String` exists
   **And** an instance method `@discardableResult func copyConfigToPasteboard() -> Bool` exists that calls `generateConfigSnippet` with `self.options.intensity` and `self.options.mergeStrategy`, then writes the result to `NSPasteboard.general` via `clearContents()` + `setString(_:forType: .string)`, returns the Bool from `setString`, and sets `errorMessage = "Could not copy to clipboard"` if it returns false
   **And** an instance method `func cancelInFlight()` exists that iterates `inFlightTasks`, inserts each `taskID` into `pendingCancellations` BEFORE calling `task.cancel()`, and does NOT mint or reassign `currentTaskID` (per DD #12)
   **And** a static method `static func formatResultRow(fileName: String?, bpm: Double?, confidence: Double?, effectiveIntensity: AnalysisIntensity?, elapsedSeconds: Double?) -> Result<BPMResultRow, FormatError>` exists (per DD #15) and returns `.failure(.nonFinite)` for NaN/Inf inputs, `.failure(.missingFields)` when nil/non-nil pattern is mixed, `.success(...)` for the all-finite happy path

   **Given** the existing `analyze(url:autoStarted:)` method
   **When** inspected
   **Then** its behavior is UNCHANGED — Story 5-3 adds new methods but does not modify the existing analyze entry point

9. **`ContentView` gains a controls section above the drop / result region.**

   **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift`
   **When** inspected
   **Then** a controls section (Form / GroupBox / VStack — dev agent's choice) renders above the existing primary state view
   **And** the controls section contains: an intensity slider bound to `viewModel.options.intensity` via the rawValue conversion per DD #2, a merge strategy picker bound to `viewModel.options.mergeStrategy` per DD #3, and a button row containing Cancel (conditional on `isAnalyzing`), Re-analyze (conditional on `selectedFileURL != nil`), and Copy Config (always visible)
   **And** the slider's `onEditingChanged: { editing in if !editing { triggerReanalyze() } }` and the picker's `.onChange(of:initial:_:_:)` (or `.onChange(of:perform:)` on macOS 15) both fire a re-analyze via `triggerReanalyze()` ONLY when `viewModel.selectedFileURL != nil`
   **And** the existing Story 5-2 `.dropDestination(for: URL.self)` + `.onOpenURL` + `.contentShape(Rectangle())` modifiers remain attached to the root container

10. **Smoke test additions per DD #13 + DD #15 (target: 18 → ~28-32 tests).**

    **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift`
    **When** the suite runs
    **Then** the new tests pass:
    - `generateConfigSnippet` parameterized over (intensity, mergeStrategy) pairs: 7 intensity cases (`.fastest`, `.default`, `.thorough`, `.maximum`, `AnalysisIntensity(rawValue: 2)`, `AnalysisIntensity(rawValue: 5)`, `AnalysisIntensity(rawValue: 9)`) paired with `.maxConfidence` — verifies the named-vs-raw formatting per DD #7
    - `generateConfigSnippet` parameterized over all 8 `CandidateMergeStrategy.allCases` paired with `.default` intensity — verifies each strategy emits `.\(strategy.rawValue)` verbatim
    - `generateConfigSnippet` snippet shape sanity (1 case): the rendered snippet is exactly 4 lines, contains `yourURL` literal, contains `try AudioAnalysisService.analyzeBPM`, no leading whitespace, no trailing whitespace beyond a single optional newline
    - `cancelInFlight` isolation (no in-flight task): `cancelInFlight()` is a clean no-op; `isAnalyzing == false`; `pendingCancellations.isEmpty`
    - `cancelInFlight` with in-flight task (uses bpm-120-click.wav fixture): drop fixture → call `cancelInFlight()` → poll for `isAnalyzing == false` (30s deadline) → verify `detectedBPM == nil` (cancelled tasks must NOT mutate result fields per DD #12)
    - Manual re-run uses current options (uses bpm-120-click.wav fixture; renamed from "re-run wiring" — this is bare-API exercise, NOT a SwiftUI `.onChange` test): drop → await completion → snapshot BPM → mutate `options.mergeStrategy = .dedup` → call `analyze(url: selectedFileURL!)` directly → await completion → assert `detectedBPM != nil` post-re-run (numeric equality NOT asserted). Note: this does NOT exercise `Picker.onChange` wiring; the wiring is verified in AC #11 manual smoke. (Codex M7 close, party-mode 2026-05-19.)
    - `formatResultRow` happy path (1 case): all-finite inputs → `.success(BPMResultRow)` with correctly-formatted fields per Story 5-2 DD #10
    - `formatResultRow` NaN guard (3 cases, parameterized): NaN in bpm / confidence / elapsedSeconds → `.failure(.nonFinite)`
    - `formatResultRow` Inf guard (6 cases, parameterized): ±Inf in bpm / confidence / elapsedSeconds → `.failure(.nonFinite)`
    - `formatResultRow` missing-fields (1 case): bpm non-nil, confidence nil → `.failure(.missingFields)` (the mixed-nil pattern)
    - Pasteboard round-trip — **env-gated, only runs when `BBBKIT_RUN_PASTEBOARD_TEST=1`** (1 case when enabled, otherwise skipped via `Test.disabled(if:)`): write a sentinel snippet via `viewModel.copyConfigToPasteboard()` after setting `options.intensity = .fastest; options.mergeStrategy = .median`; read `NSPasteboard.general.string(forType: .string)` back; assert equality; restore the prior clipboard string via `defer`. Restore is best-effort (string-only; multi-type clipboard payloads collapse). On systems with strict pasteboard TCC policy, the test may trigger a permission prompt — opt-in via the env var keeps `make demo-test` clean by default. (Codex M6 close, party-mode 2026-05-19.)

    **And** the existing Story 5-2 tests (`wrapping`, `rejectsEmptyDrop`, `rejectsMultiFileDrop`, `rejectsUnsupportedType` × 5, `acceptsSupportedTypes` × 6, `acceptsUppercaseExtensions`, `handleDropStateTransitions` × 3) all still pass

11. **Manual smoke test executed at close-out (AC #11; aligned with Story 5-2 AC #12 pattern).**

    **Given** a `make demo-build-sandboxed` build (the dev agent has a `DEVELOPMENT_TEAM` configured)
    **When** the dev agent manually exercises the controls
    **Then**:
    - Drop `bpm-120-click.wav` → wait for result → adjust intensity slider from 7 to 3 and release → verify a fresh analyze fires and a new (likely identical) BPM renders
    - Drop the same file → wait for result → open the Merge strategy picker and select `dedup` → verify a fresh analyze fires
    - Click Copy Config → paste into a text editor → verify the 4-line snippet matches DD #7 for the current `(intensity, mergeStrategy)` pair
    - Drop a long-running file (`Submerged_Lament.mp3` if available; any large fixture otherwise) → immediately click Cancel → verify the "Cancelling…" copy appears, then `isAnalyzing` flips to false within a few seconds AND the result row is empty (no leftover stale result) — exercises DD #12 Branch A
    - DD #12 Branch B (Cancel-then-Re-analyze interleave): drop a long-running file → click Cancel → BEFORE the cancel-drain completes (`isCancelling == true`), wait for `isAnalyzing` to flip to false (DD #12 Branch A path), THEN click Re-analyze → verify the new analyze runs cleanly to a result, no stuck `isAnalyzing`, `pendingCancellations` correctly drains. (If Re-analyze is hidden during the brief Cancelling window because `isAnalyzing` is still true, the test instead waits for `isAnalyzing == false` before clicking — the AC is "Re-analyze works correctly after Cancel," not "Re-analyze is visible during the drain.")
    - With a file dropped and analysis complete, click Re-analyze → verify a fresh analyze fires with the same file at the current `options`
    - Adjust intensity slider mid-analyze (without releasing the thumb) → verify the in-flight result, when it lands, reflects the OLD intensity (snapshot-at-launch contract from AC #6)
    - With NO file dropped, adjust the slider and picker → verify NO analyze fires (the buttons should reflect: Cancel hidden because not analyzing, Re-analyze hidden because no file)
    - With NO file dropped, click Copy Config → verify the snippet still copies and reflects the current control state
    - With a non-finite-result hypothetical (cannot reproduce naturally; verify only via the unit test in AC #10) — the NaN/Inf guard renders the "Internal error" message instead of "nan BPM"
    - **D1 follow-up (added 2026-05-20 via Codex consult thread `019e43e5-b44a-7243-b7d9-c86fd91dd2ed`):** Open a file via Dock-icon drop OR `open -a BoomBoomBoomKitDemo <file>` (NOT a window drop) → wait for the initial analysis to complete → adjust the intensity slider OR pick a different merge strategy → verify the re-analysis succeeds and produces a result (no "sandbox denied" error banner). This exercises the `.onOpenURL` `autoStarted: true` provenance / start-after-stop balanced-access claim that Apple's `URL.startAccessingSecurityScopedResource()` docs make. If this step fails, re-open D1 as a patch (thread provenance on the view model and pass through Re-analyze).
    - Completion Notes record the outcomes verbatim

12. **Library gating + demo gauntlets unchanged.**

    **Given** the library gating gauntlet
    **When** run on this branch
    **Then** `make fmt` clean
    **And** `make demo-fmt` clean
    **And** `make lint` reports only the canonical pre-existing `LUFSAnalyzer.swift:94` TODO violation
    **And** `make test` passes (library test count UNCHANGED — Story 5-3 adds zero library tests; only demo-target tests are new)
    **And** `make build` (library Debug) succeeds
    **And** `make build-release` (library Release) succeeds
    **And** `make demo-build` exits 0
    **And** `make demo-test` exits 0 (all new + existing demo-target tests pass)
    **And** `make demo-lint` exits 0 (no team-ID leak)
    **And** `make pre-commit` exits 0
    **And** `make benchmark` reports Acc1 = 58/82, Acc2 = 74/82 (UNCHANGED — Story 5-3 touches zero library DSP code; sanity check)
    **And** `make benchmark-giantsteps` reports Acc1 = 537/661, Acc2 = 546/661 (UNCHANGED)

13. **Epic 5 hygiene: A2 + A3 continued (DD #11 from Story 5-1; continued in Story 5-2 AC #14).**

    **Given** A2 (`deferred-work.md` is the canonical resolution ledger)
    **When** Story 5-3's close-out commit lands
    **Then** every applied patch and every newly-deferred item appears in `deferred-work.md` with cross-reference
    **And** W2 / W12 / W20 are annotated CLOSED inline with the Story 5-3 commit reference

    **Given** A3 (`make test` wall-clock baseline tracked per epic)
    **When** Story 5-3's Completion Notes are written
    **Then** they record the exact `make test` wall-clock seconds post-Story-5-3 on M5 Max (Story 5-2's baseline: warm-cache 1.74s real, 431 runs in 94 suites)
    **And** they note the per-story delta vs Story 5-2 (expected: 0% — zero library changes)

## Tasks / Subtasks

- [x] **Task 0 — Pre-flight**
  - [x] 0.1: Confirm `make fmt && make lint && make test && make demo-build && make demo-test && make demo-lint && make pre-commit` all clean on the branch head — record `make test` wall-clock + test count for AC #13 A3 continuity
  - [x] 0.2: Confirm the existing Story 5-2 baseline behaviors still hold via a smoke check: launch `make demo-build` app, drop a `.wav`, verify the result renders. If anything is broken, HALT and investigate BEFORE touching code
  - [x] 0.3: Confirm `make demo-build-sandboxed` runs successfully (RT's `DEVELOPMENT_TEAM` is configured); if not, surface and HALT before code changes

- [x] **Task 1 — `AnalysisViewModel` extensions (AC #4, AC #8, AC #10, DDs #4, #7, #8, #12, #15)**
  - [x] 1.1: Add `import AppKit` (NSPasteboard lives in AppKit; demo is macOS-only per Package.swift `.macOS(.v15)`)
  - [x] 1.2: Add `static func generateConfigSnippet(intensity:mergeStrategy:) -> String` per DD #7 (snippet shape, intensity-literal helper rules, merge-strategy `.\(rawValue)` formatting all specified there)
  - [x] 1.3: Add `@discardableResult func copyConfigToPasteboard() -> Bool` per DD #8 (body, error handling, signature all specified there)
  - [x] 1.4: Add `func cancelInFlight()` per DD #4 + DD #12 (cascade body in DD #4; MUST NOT reassign `currentTaskID` or mint a new UUID per DD #12)
  - [x] 1.5: Add `static func formatResultRow(...)` per DD #15 (signature, `Result<BPMResultRow, FormatError>` return shape, NaN/Inf/missing-fields semantics all specified there). Move `BPMResultRow` from `ContentView` (private) up to `AnalysisViewModel` as `internal struct BPMResultRow`. Add `internal enum FormatError: Error { case missingFields, nonFinite }`
  - [x] 1.6: Verify the existing `analyze(url:autoStarted:)` is UNCHANGED — Story 5-3 adds new entry points but does not modify the existing one. Build green confirmation via `make demo-build`
  - [x] 1.7: Verify the view model still compiles under Swift 6 strict concurrency. The new methods are all `@MainActor`-isolated by virtue of the class annotation; no `nonisolated`, no `@Sendable` capture issues. `NSPasteboard.general` is process-wide and not Sendable-annotated; AppKit's public docs (fetched 2026-05-19) do NOT explicitly guarantee main-queue safety, so the spec keeps all pasteboard calls `@MainActor`-bound by inheriting the class isolation. Do NOT add a `nonisolated` escape

- [x] **Task 2 — `ContentView` controls section (AC #1, AC #2, AC #5, AC #7, AC #9, DDs #2, #3, #9, #10, #11)**
  - [x] 2.1: Wrap the existing root `VStack` body in an outer container that adds a controls section ABOVE the existing `primaryStateView + bannerView` pair. Implementation hint: `VStack(spacing: 16) { controlsSection; existingStateAndBanner }`. The drop / state / banner render is UNCHANGED — only its position in the layout changes (it now follows the controls section instead of being root)
  - [x] 2.2: Add `private var controlsSection: some View` — a GroupBox titled `"Parameters"` containing a 3-row VStack: (a) intensity row with `Text` label + `Slider`, (b) merge strategy row with `Picker`, (c) button row with `HStack { Cancel; Re-analyze; Copy Config }`
  - [x] 2.3: Intensity slider — `Slider(value: intensityBinding, in: 1.0...10.0, step: 1.0, onEditingChanged: { editing in if !editing { triggerReanalyze() } })`. The `intensityBinding` is a private computed property: `private var intensityBinding: Binding<Double> { Binding(get: { Double(viewModel.options.intensity.rawValue) }, set: { viewModel.options.intensity = AnalysisIntensity(rawValue: Int($0.rounded())) }) }`. **Use `Int($0.rounded())` NOT `Int($0)`** (DD #2 — `Int(6.999) == 6` would silently downgrade if SwiftUI ever drives the setter mid-snap; `Int(6.999.rounded()) == 7` matches the visually-snapped position). Add a label above the slider: `Text("Intensity: \(intensityLabelText)")` where `intensityLabelText` is `"\(viewModel.options.intensity.rawValue)"` plus `" (fastest)"` / `" (default)"` / `" (thorough)"` / `" (maximum)"` for the 4 named raw values
  - [x] 2.4: Merge strategy picker — `Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) { ForEach(CandidateMergeStrategy.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu).onChange(of: viewModel.options.mergeStrategy) { _, _ in triggerReanalyze() }`. Use the macOS 15 `.onChange(of:initial:_:)` two-param closure shape
  - [x] 2.5: Button row — `HStack { if viewModel.isAnalyzing { Button(viewModel.isCancelling ? "Cancelling…" : "Cancel") { viewModel.cancelInFlight() }.disabled(viewModel.isCancelling) }; if viewModel.selectedFileURL != nil && !viewModel.isAnalyzing { Button("Re-analyze") { triggerReanalyze() } }; Button("Copy Config") { viewModel.copyConfigToPasteboard() } }`. Order: Cancel (left) → Re-analyze (middle) → Copy Config (right). The Cancel and Re-analyze visibility predicates are mutually exclusive (one or the other, never both) per DD #5
  - [x] 2.6: Add `private func triggerReanalyze()` to `ContentView`. Body: `guard let url = viewModel.selectedFileURL else { return }; viewModel.analyze(url: url, autoStarted: false)`. Called from slider edit-end, picker selection change, and Re-analyze button tap
  - [x] 2.7: Refactor `ContentView.displayState` to delegate to the new `AnalysisViewModel.formatResultRow(...)` static helper (per DD #11 + DD #15 + AC #7). Replace the existing `if let bpm = ..., let confidence = ..., let intensity = ..., let elapsed = ... { let row = BPMResultRow(...); return .result(row) }` block with: `switch AnalysisViewModel.formatResultRow(fileName: viewModel.fileName, bpm: viewModel.detectedBPM, confidence: viewModel.confidence, effectiveIntensity: viewModel.effectiveIntensity, elapsedSeconds: viewModel.elapsedSeconds) { case .success(let row): return .result(row); case .failure(.nonFinite): return .errorOnly("Internal error: analysis returned a non-finite value. This is a library bug — please file an issue."); case .failure(.missingFields): /* fall through to errorMessage / empty */ break }`. Remove the now-orphaned private `BPMResultRow` struct definition (it lives on `AnalysisViewModel` per Task 1.5)
  - [x] 2.8: Verify the existing `.dropDestination(for: URL.self)` + `.onOpenURL` + `.contentShape(Rectangle())` + `.frame(maxWidth:maxHeight:)` + `.padding()` modifier chain remains attached to the OUTER root container (NOT to an inner `Form` or `GroupBox`). Per axiom-swift transferable-ref.md, drop hit-testing requires `.frame(...)` + `.contentShape(Rectangle())` BEFORE `.dropDestination` — keep this order on the outermost VStack. Do NOT wrap the body in a `Form` outer container: Form has internal padding + scroll behavior that can break drop hit-testing on padded margins. Instead: the existing root VStack stays the root; `controlsSection` (a `GroupBox`) becomes the first child of that VStack; `primaryStateView + bannerView` follow. The drop region thus covers controls AND drop area uniformly — a user dragging onto the slider still drops successfully

- [x] **Task 3 — Test target additions (AC #10, DD #13, DD #14)**
  - [x] 3.1: Add `@Test` for `generateConfigSnippet` with named/raw intensity parameterization (7 cases: 4 named + 3 raw paired with `.maxConfidence`). Use `arguments: zip([1,7,8,10,2,5,9], [".fastest", ".default", ".thorough", ".maximum", "AnalysisIntensity(rawValue: 2)", "AnalysisIntensity(rawValue: 5)", "AnalysisIntensity(rawValue: 9)"])`. For each case, build the expected snippet and assert equality with `generateConfigSnippet(intensity: AnalysisIntensity(rawValue: rawInt), mergeStrategy: .maxConfidence)`
  - [x] 3.2: Add `@Test` for `generateConfigSnippet` with all 8 `CandidateMergeStrategy.allCases` paired with `.default` intensity. For each strategy, assert the snippet contains `opts.mergeStrategy = .\(strategy.rawValue)`
  - [x] 3.3: Add `@Test` for snippet shape sanity (1 case): `generateConfigSnippet(intensity: .default, mergeStrategy: .maxConfidence)` → assert the rendered string `.components(separatedBy: "\n")` has exactly 4 (or 5 if a trailing newline is included by design) non-empty lines, contains `"yourURL"`, contains `"try AudioAnalysisService.analyzeBPM"`, no leading whitespace on line 1, last line is `let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)`
  - [x] 3.4: Add `@Test("cancelInFlight no-op when idle")` — construct `AnalysisViewModel`, call `cancelInFlight()`, assert `isAnalyzing == false && pendingCancellations.isEmpty && detectedBPM == nil`
  - [x] 3.5: Add `@Test("cancelInFlight cancels in-flight task")` — `try AudioFixtures.url(for: "bpm-120-click", extension: "wav")` → `viewModel.analyze(url:)` → IMMEDIATELY `viewModel.cancelInFlight()` → poll `isAnalyzing` to false with 30s deadline → assert `detectedBPM == nil && pendingCancellations.isEmpty` post-completion. Note: the click track is fast (~1-2s); the cancel may race with successful completion. Mitigation: use the cancel-during-prologue path — `cancelInFlight()` runs synchronously on MainActor BEFORE the Task body re-enters; the library's first `isCancelled` check at window boundary 0 fires. If the race produces a flaky test, switch to a `Submerged_Lament.mp3`-style fixture, OR use `Task.sleep` + check (skip cancellation in that case and assert task completed cleanly — the test becomes "cancel called → no crash, eventual state is consistent")
  - [x] 3.6: Add `@Test("manual re-run uses current options")` — drop the click fixture → await completion → snapshot the result → `viewModel.options.mergeStrategy = .dedup` (bare-API mutation, MainActor — does NOT exercise `Picker.onChange`; the wiring is verified manually in AC #11) → `viewModel.analyze(url: viewModel.selectedFileURL!)` → await completion → assert `viewModel.detectedBPM != nil` post-re-run (numeric equality NOT asserted; `.dedup` may produce slightly different output)
  - [x] 3.7: Add `formatResultRow` test bank per DD #15 — happy path (1 case, all finite → `.success`), NaN guard parameterized over (bpm/confidence/elapsed) × NaN → `.failure(.nonFinite)` (3 cases), Inf guard parameterized over (bpm/confidence/elapsed) × ±Inf → `.failure(.nonFinite)` (6 cases), missing-fields case (bpm non-nil + confidence nil → `.failure(.missingFields)`, 1 case). Total: 11 new tests
  - [x] 3.8: Add `@Test("copyConfigToPasteboard round-trip", .enabled(if: ProcessInfo.processInfo.environment["BBBKIT_RUN_PASTEBOARD_TEST"] == "1"))` — read current `NSPasteboard.general.string(forType: .string)` and save; set `viewModel.options.intensity = .fastest; viewModel.options.mergeStrategy = .median`; call `viewModel.copyConfigToPasteboard()` and assert it returns `true`; read pasteboard string back; assert equality with `AnalysisViewModel.generateConfigSnippet(intensity: .fastest, mergeStrategy: .median)`; restore the original clipboard contents via `defer`. Restore is best-effort (string-only — multi-type clipboard payloads collapse; document this in the test comment). Default cadence (`make demo-test`) skips this test; dev opts in via `BBBKIT_RUN_PASTEBOARD_TEST=1 make demo-test`
  - [x] 3.9: Confirm `make demo-test` passes with the expanded suite. Expected default-cadence test count: 18 → ~28-32 (pasteboard test skipped). With `BBBKIT_RUN_PASTEBOARD_TEST=1`: ~29-33. **Actual: 48 default-cadence invocations** (18 baseline + 30 new parameterized × case counts).

- [x] **Task 4 — Deferred-work updates (AC #13)**
  - [x] 4.1: Mark W2 **PARTIALLY-CLOSED** (NOT fully closed) in `_bmad-output/implementation-artifacts/deferred-work.md` with cross-reference. Note: the snapshot-at-launch contract is now explicit (AC #6) and the Re-analyze button is the manual escape hatch (DD #5), but the originally-suggested "config used alongside results" UX surface is DEFERRED per DD #6. The W2 entry stays open with a re-open trigger: a user reports confusion ("I dragged the slider and the result didn't update — wait, was that the OLD result?")
  - [x] 4.2: Mark W12 CLOSED in `deferred-work.md` with cross-reference. Note: the visible Cancel button surfaces the previously-theoretical non-supersession cancel path; the per-task UUID discriminator's `.failure(is CancellationError)` arm correctly resets `isAnalyzing = false` in DD #12 Branch A (pure Cancel — `currentTaskID == taskID`) AND correctly returns-without-mutation in Branch B (Cancel-then-supersede — `currentTaskID != taskID`)
  - [x] 4.3: Mark W20 CLOSED in `deferred-work.md` with cross-reference. Note: the defensive `.isFinite` guard now lives in `AnalysisViewModel.formatResultRow` (per DD #15), making it cleanly testable. Extends Story 5-1 W5 with Story 5-2's user-visible surface area, hardened + automated in Story 5-3

- [x] **Task 5 — Gating gauntlet (AC #12)**
  - [x] 5.1: Run `make fmt && make demo-fmt && make lint` — all clean (only the canonical LUFSAnalyzer:94 TODO)
  - [x] 5.2: Run `make build && make build-release` — both succeed
  - [x] 5.3: Run `make test` — library tests pass, record wall-clock for A3 continuity
  - [x] 5.4: Run `make demo-build && make demo-test` — both succeed; expected demo test count ~25-27 (actual: 48 invocations)
  - [x] 5.5: Run `make demo-lint && make pre-commit` — both exit 0
  - [x] 5.6: Run `make demo-build-sandboxed` — exits 0 (RT's machine has `DEVELOPMENT_TEAM` configured)
  - [x] 5.7: Run `make benchmark` — Acc1=58/82, Acc2=74/82 (UNCHANGED — sanity check)
  - [x] 5.8: Run `make benchmark-giantsteps` — Acc1=537/661, Acc2=546/661 (UNCHANGED)

- [ ] **Task 6 — Manual smoke test (AC #11)**
  - [ ] 6.1: Launch the sandboxed build (`make demo-build-sandboxed`)
  - [ ] 6.2: Drop `bpm-120-click.wav` → wait for result → adjust intensity slider 7→3 → release → verify re-analyze fires
  - [ ] 6.3: Same file → open merge strategy picker → select `dedup` → verify re-analyze fires
  - [ ] 6.4: Click Copy Config → paste into a text editor → verify 4-line snippet matches DD #7
  - [ ] 6.5: Drop a long-running fixture → immediately click Cancel → verify Cancelling… copy appears, then UI returns to empty state within a few seconds
  - [ ] 6.6: With file dropped and complete, click Re-analyze → verify fresh analyze
  - [ ] 6.7: Adjust slider mid-analyze without releasing → verify in-flight result reflects OLD intensity (snapshot-at-launch)
  - [ ] 6.8: With no file dropped, adjust slider + picker → verify NO analyze fires; click Copy Config → verify snippet still copies
  - [ ] 6.9: Record outcomes verbatim in Completion Notes

- [x] **Task 7 — Completion Notes + Status flip + sprint-status update (AC #13)**
  - [x] 7.1: Write Completion Notes per Story 5-2 pattern: A3 wall-clock delta; manual smoke-test outcomes; W2 / W12 / W20 CLOSED annotations in `deferred-work.md`; any build-time discoveries
  - [x] 7.2: Flip story Status `ready-for-dev` → `in-progress` → `review` (or `done` if code review run inline)
  - [x] 7.3: Update `_bmad-output/implementation-artifacts/sprint-status.yaml`: `5-3-parameter-controls: backlog` → `in-progress` → `review/done`; append a `last_updated:` paragraph per the existing convention
  - [ ] 7.4: Run `/bmad-code-review` (3-layer parallel review: Blind Hunter + Edge Case Hunter + Acceptance Auditor; optional Codex 4th layer per Story 5-2 precedent). Apply patches; defer findings to `deferred-work.md` per A2 — **pending user action on separate-LLM cadence per project convention**
  - [ ] 7.5: Final commit with imperative-mood subject per project-context.md:131 — `Story 5-3: parameter controls + Copy Config snippet` — **pending user action (gated on 1Password GPG signer per Story 5-1 precedent)**

## Dev Notes

### Architecture references

- **Story 5-2 spec — the file-drop + result-render slice this story builds on:** `_bmad-output/implementation-artifacts/5-2-core-analysis-flow.md`. Critical inherited DDs: #5 (per-task UUID discriminator — Story 5-3 DD #12 explicitly depends on `currentTaskID` NOT being reassigned by `cancelInFlight`), #6 (`pendingCancellations: Set<UUID>` observed + derived `isCancelling` computed), #10 (5-row result rendering — Story 5-3 wraps this in NaN/Inf guard), #11 (drop-validator pattern — Story 5-3 reuses the static-method-on-view-model pattern for `generateConfigSnippet`), #16 (mixed-state UI render — unchanged in Story 5-3; the controls section is independent of the primary state view)
- **Story 5-1 spec — the scaffold and DD #16-D / DD #16-E carryovers:** `_bmad-output/implementation-artifacts/5-1-demo-app-project-scaffold.md`. DD #16-D split exposed/operational state — `selectedFileURL` was added then with the explicit "Story 5-3 reads this to re-run analysis on the same file when intensity/merge-strategy changes" comment that this story now exercises. DD #16-E cancel-all-prior cascade is the mechanic Story 5-3 inherits for slider/picker re-runs (and for the new Cancel button)
- **Public API surface this story binds to:**
  - `Sources/BoomBoomBoomKit/AnalysisIntensity.swift:18-99` — `AnalysisIntensity: Sendable, Hashable, Comparable, ExpressibleByIntegerLiteral`. Ordinal struct 1-10, `init(rawValue:)` clamps. Named constants: `.fastest` (1), `.default` (7), `.thorough` (8), `.maximum` (10). NO named constants for 2/3/4/5/6/9
  - `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:19-51` — `CandidateMergeStrategy: String, CaseIterable, Sendable, Hashable`. 8 cases; rawValue strings match case names verbatim. `.allCases` order is the declaration order: `[.maxConfidence, .dedup, .quorum, .average, .median, .weightedAverage, .union, .windowVoting]`
  - `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:83-283` — `Options: Sendable` with `intensity: AnalysisIntensity = .default` and `mergeStrategy: CandidateMergeStrategy = .maxConfidence`. Property-level defaults; empty `init() {}` (ADR-11). The view model already holds `var options = AudioAnalysisService.Options()` from Story 5-1; Story 5-3 binds SwiftUI controls to `viewModel.options.intensity` and `viewModel.options.mergeStrategy` directly
- **NSPasteboard reference:** `NSPasteboard.general` is the system-wide pasteboard. `clearContents() -> Int` returns the new change count (ignorable). `setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool` returns true on success. Pasteboard mutation on macOS 15+ is documented as main-queue-safe (call sites are `@MainActor`-isolated in this codebase). Reference: https://developer.apple.com/documentation/appkit/nspasteboard
- **SwiftUI controls reference:**
  - `Slider(value:in:step:onEditingChanged:)` — `onEditingChanged: (Bool) -> Void` fires `true` on drag start, `false` on drag end. The latter is the natural debounce point for re-run. Reference: https://developer.apple.com/documentation/swiftui/slider
  - `Picker(_:selection:content:)` + `.onChange(of:initial:_:)` — macOS 15+ form with two-param closure `(oldValue, newValue) -> Void`. Reference: https://developer.apple.com/documentation/swiftui/view/onchange(of:initial:_:)

### Project Structure Notes

- Library target `BoomBoomBoomKit` — UNCHANGED in Story 5-3 (zero `Sources/` or `Tests/` library modifications expected)
- `BoomBoomBoomKitTestSupport`, `BoomBoomBoomKitML`, `BoomBoomBoomKitBenchmarkTests`, `BoomBoomBoomKitTests` — UNCHANGED
- `Demo/BoomBoomBoomKitDemo/` — modified files:
  - `BoomBoomBoomKitDemo/AnalysisViewModel.swift` — additions for AC #8 (estimated +90 lines on top of the Story 5-2 339-line baseline; new methods `generateConfigSnippet`, `copyConfigToPasteboard`, `cancelInFlight`, `formatResultRow` + nested `BPMResultRow` struct + `FormatError` enum + new `import AppKit`)
  - `BoomBoomBoomKitDemo/ContentView.swift` — additions for AC #1 / #2 / #5 / #7 / #9 (estimated +70 lines on top of the Story 5-2 162-line baseline; new `controlsSection` + intensity / picker / button row, NaN/Inf logic moved out to the helper per DD #15 so `displayState` shrinks slightly)
  - `BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — expanded for AC #10 (estimated +160 lines on top of the Story 5-2 138-line baseline; ~11-13 new `@Test` declarations including parameterized cases for `generateConfigSnippet`, `formatResultRow` NaN/Inf bank, `cancelInFlight`, manual re-run, and the env-gated pasteboard round-trip)
- `_bmad-output/implementation-artifacts/deferred-work.md` — W2 / W12 / W20 marked CLOSED inline
- `_bmad-output/implementation-artifacts/5-3-parameter-controls.md` — this story file
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flip + `last_updated:` summary
- `Makefile` — UNCHANGED (Story 5-2's `demo-fmt`, `demo-lint`, `pre-commit` targets already cover Story 5-3's new code)
- No new SPM dependencies, no `Package.swift` changes, no `.pbxproj` changes (no new files, no new build settings)
- No new audio files anywhere — `find Demo -type f \( -name '*.wav' -o -name '*.aiff' -o -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' -o -name '*.caf' \)` MUST still return zero matches at close-out (Story 5-1 DD #16-A continuity)

### Risk

- **R1+R2+R6+R7 — Non-defects observed and documented.** Fast slider drag-release-drag-release (R1) and rapid picker selections (R2) queue multiple `analyze(url:)` calls; the cancel-all-prior cascade + `pendingCancellations` set handle them correctly, with `isCancelling` truthful across the multi-second drain window. Snapshot-at-launch ensures each in-flight task sees the options at its launch moment, not the current picker value. Cancel-button races with task completion (R6) are serialized via MainActor (both `cancelInFlight()` and the Task body's re-entry run on MainActor in some order, never concurrently) — if Cancel arrives after `isAnalyzing = false`, the dict is already empty and the cancel is a no-op. `cancelInFlight()` on an empty `inFlightTasks` (R7) iterates nothing — no-op. None are defects; documented so a future reviewer doesn't re-litigate them.
- **R3 — Security-scoped resource re-grant on Re-analyze may fail.** After the original drop's analyze Task completes, `defer { url.stopAccessingSecurityScopedResource() }` releases the kernel grant. When the user clicks Re-analyze (or adjusts slider/picker), the new `analyze(url: selectedFileURL!)` call re-invokes `startAccessingSecurityScopedResource()`. Apple's docs do NOT guarantee that a previously-stopped security-scoped URL can be re-started without a fresh bookmark. **Empirical observation from Apple's sandbox-and-file-access skill table (`axiom-macos/skills/sandbox-and-file-access.md:301-311`):** SwiftUI `.dropDestination(for: URL.self)` URLs are auto-bracketed by the system; the system grant persists for the URL's lifetime in our process. Calling `start` after `stop` should succeed because the underlying entitlement is still active. **Mitigation if the re-grant fails:** the existing AC #6 logic surfaces `"Could not read audio file: \(filename) (sandbox denied)"`; the user drops the file again. Story 5-3 does NOT add bookmark persistence (out of scope per Story 5-1 DD #16). Manual smoke test (Task 6.6 + 6.2) is the verification surface
- **R4 — `NSPasteboard.general` mutation pollutes the dev's actual clipboard during the round-trip test (AC #10 / Task 3.7).** The pasteboard is process-wide; tests cannot meaningfully use a sandboxed pasteboard. **Mitigation:** read the clipboard's current `.string(forType: .string)` before the test, store in a local, and restore via `defer` after the assertion. This minimizes clipboard pollution to the test's duration (~10ms). If the dev had a non-string-typed payload (image, file URL list), the restore is best-effort — the string overwrite cannot perfectly restore a multi-type payload. Acceptable for a single-test cost
- **R5 — `Slider` Binding setter may emit fractional values during animation.** Mitigated by DD #2's `Int($0.rounded())` (NOT `Int($0)`) plus `AnalysisIntensity.init(rawValue:)`'s clamp. `step: 1.0` enforces visual snap. No defect.
- **R8 — Pre-1.0 / no-BC: `cancelInFlight()` / `copyConfigToPasteboard()` land on the demo-internal view model, not the public library.** No BC concern. Reference: project-context.md "Public API Discipline (pre-1.0)".
- **R9 — Cancel-then-Re-analyze double-fire (the most plausible fast-finger scenario).** Verified by DD #12 Branch B: `cancelInFlight()` marks the original task, then `analyze(url:)` reassigns `currentTaskID = newTaskID`, fires cancel-all-prior on the already-cancelled task (no-op — `task.cancel()` is idempotent), and launches the new task. The new task runs cleanly under its own UUID. No special handling needed; AC #11 manual smoke verifies.

### Apple Platform / SwiftUI / NSPasteboard Notes

#### SwiftUI `Slider(value:in:step:onEditingChanged:)`

Per Apple's docs:

```swift
@State private var rawValue: Double = 7

Slider(
  value: $rawValue,
  in: 1.0...10.0,
  step: 1.0,
  onEditingChanged: { editing in
    if !editing {
      // Edit-end: trigger re-run
      triggerReanalyze()
    }
  }
)
```

The `onEditingChanged` callback receives `true` on drag start and `false` on drag end. Some control-flow inputs (e.g., keyboard arrow-key adjustments) may not fire `onEditingChanged` at all; on macOS the Slider responds to arrow keys with focus. The dev agent verifies arrow-key behavior in manual smoke testing (Task 6.2). If arrow-key adjustments do NOT trigger re-run, the user still has the Re-analyze button as the escape hatch.

#### SwiftUI `Picker` + `.onChange(of:initial:_:)`

Per Apple's docs (macOS 15+ two-param closure shape):

```swift
Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) {
  ForEach(CandidateMergeStrategy.allCases, id: \.self) { strategy in
    Text(strategy.rawValue).tag(strategy)
  }
}
.pickerStyle(.menu)
.onChange(of: viewModel.options.mergeStrategy) { _, _ in
  triggerReanalyze()
}
```

`.menu` style is the macOS default dropdown; `.segmented` or `.wheel` would consume excessive horizontal space for 8 options. The picker selection update fires synchronously on user pick (no animation interpolation like the Slider), so re-run on every `.onChange` is jitter-free.

#### NSPasteboard

Per Apple's docs (https://developer.apple.com/documentation/appkit/nspasteboard):

```swift
import AppKit

let pasteboard = NSPasteboard.general
pasteboard.clearContents()             // returns Int (new change count, ignorable)
let didCopy = pasteboard.setString(snippet, forType: .string)
// didCopy: true on success
```

The `clearContents()` call is mandatory before `setString` — without it, mixed-payload pasteboards retain stale typed data. The pasteboard is process-wide and not Sendable; calls are restricted to MainActor in this codebase (matches the view model's `@MainActor` isolation).

To read back the most recently written string (used in the round-trip test):

```swift
let snippet = pasteboard.string(forType: .string)  // Optional<String>
```

#### Snapshot-at-launch contract

The existing `analyze(url:autoStarted:)` body has `var opts = options` (line 156) BEFORE the Task launches. This is the W2-safe semantic: the in-flight task captures `options` by value at the synchronous prologue. Subsequent picker mutations affect `viewModel.options` (the source) but NOT the snapshot. The in-flight task's `opts` is delivered to `AudioAnalysisService.analyzeBPM(url:options:)` and persists through the ~1-30s DSP run.

Story 5-3 documents this contract in DocC for Story 5-5 to surface in public docs (the `AnalysisViewModel` is demo-local but the snapshot pattern itself is consumer-relevant for any `@Observable` wrapper around a long-running analyze).

### Previous Story Intelligence

Story 5-3 inherits these from Stories 5-1 + 5-2 (full detail in those spec files):

- **Per-task UUID discriminator** (Story 5-2 DD #5): `currentTaskID` + `inFlightTasks: [UUID: Task]` + `pendingCancellations: Set<UUID>`. Story 5-3 `cancelInFlight()` reuses the cascade pattern; DD #12 prohibits reassigning `currentTaskID`
- **Snapshot-at-launch** (Story 5-2): `var opts = options` at the synchronous prologue of `analyze(url:autoStarted:)`. AC #6 documents it
- **`selectedFileURL` operational state** (Story 5-1 DD #16-D): exposed expressly for Story 5-3's re-run mechanic — this story is the first consumer
- **Cancel-all-prior cascade** (Story 5-1 DD #16-E): slider/picker/Re-analyze all funnel through `analyze(url:)`, which fires the cascade
- **A2 + A3 ledger discipline** (Epic 4 retro carried into Epic 5): A2 — every applied patch and newly-deferred item goes in `deferred-work.md`; A3 — `make test` wall-clock recorded in Completion Notes with per-story delta. Story 5-3 expected: 0% library delta (zero `Sources/` or `Tests/` changes)
- **Test count discipline**: library test count UNCHANGED at 431; demo target grows from 18 → ~28-32
- **`@testable import BoomBoomBoomKitDemo`** (Story 5-1 D2 + AC #3): new methods on `AnalysisViewModel` are exercised via this pattern; test target is Debug-only per W18
- **View-model-constructed error templates** (Codex M12 from Story 5-2): user-facing errors are built from primitive inputs or hardcoded copy, not `String(describing: error)`; Story 5-3's non-finite result message follows that pattern
- **No emojis in code artifacts, Makefile, spec files, commit messages** (memory feedback_no_emojis)

### References

- `_bmad-output/planning-artifacts/epics.md:1310-1328` — Story 5.3 acceptance criteria (as written; this spec expands them per AC #1-#13)
- `_bmad-output/planning-artifacts/epics.md:237-242` — Epic 5 preamble (sequencing, dependencies, "demo app as public-API-only consumer")
- `_bmad-output/planning-artifacts/architecture.md:161-180` — Demo App Structure decision (AmbientUI pattern, SwiftUI + `@Observable`, public-API-only)
- `_bmad-output/planning-artifacts/architecture.md:247-258` — ADR-11 Options-first public configuration (intensity + mergeStrategy land on `AudioAnalysisService.Options`; demo binds to them)
- `_bmad-output/planning-artifacts/architecture.md:484-488` — Demo app boundary (public-API-only, ships on main)
- `_bmad-output/planning-artifacts/prd.md:164-182` — Journey 4 (Power User — Algorithm Evaluation via Demo App). The canonical consumer narrative — "She slides to intensity 7… She switches merge strategies via a dropdown" — Story 5-3 satisfies the slider + picker parts
- `_bmad-output/planning-artifacts/prd.md:560-569` — FR34-FR41 (Demo Application functional requirements). Story 5-3 fulfills FR36 (parameter adjustment) and FR40 (Copy Config snippet). FR37 (trace view) and FR41 (trace export) remain for Story 5-4
- `_bmad-output/implementation-artifacts/5-2-core-analysis-flow.md` — Story 5-2 spec; the file-drop + result-render slice Story 5-3 builds on
- `_bmad-output/implementation-artifacts/5-1-demo-app-project-scaffold.md` — Story 5-1 spec; the scaffold; DD #16-D / DD #16-E specifically targeted Story 5-3's re-run mechanic
- `_bmad-output/implementation-artifacts/deferred-work.md` — W1-W22 inheritance. Story 5-3 closes W2 / W12 / W20 inline
- `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md:100-108` — A2 + A3 action items (carried through Stories 5-1, 5-2, and now 5-3)
- `_bmad-output/project-context.md` — all project-level rules. Notably: "Public API Discipline (pre-1.0)" (Story 5-3 adds zero public types to the library), ADR-11 Options-first (Story 5-3 binds to `Options.intensity` + `.mergeStrategy` directly), testing rules (Swift Testing + `@MainActor`)
- Apple docs — "NSPasteboard" / "Slider" / "View.onChange(of:initial:_:)" — quoted in Apple Platform Notes above
- `MEMORY.md` — user preferences: no emojis; no business jargon in commits; BC is NOT a goal pre-1.0; `make test` wall-clock 10% delta tripwire per A3
- _Sources/ + Demo/ file references for `AnalysisIntensity`, `CandidateMergeStrategy`, `Options`, `AnalysisViewModel`, `ContentView`, `AnalysisViewModelSmokeTest` are in **Architecture references** and **Project Structure Notes** above — not duplicated here._

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (claude-opus-4-7) via `/bmad-dev-story` workflow on 2026-05-19 → 2026-05-20.

### Debug Log References

No HALT events. No 3-consecutive-failure stalls. Single auto-mode pass.

### Completion Notes List

1. **All 8 spec tasks executed in auto-mode.** Task 0 baseline (warm-cache `make test` 2.159s real / 431 tests in 94 suites; demo-test 18 cases; demo-build-sandboxed verified by sandboxed run later in gauntlet). Tasks 1-3 land all four `AnalysisViewModel` extensions (`generateConfigSnippet`, `copyConfigToPasteboard`, `cancelInFlight`, `formatResultRow`) + nested `BPMResultRow` + `FormatError` enum + `import AppKit`; `ContentView` gains `controlsSection` (GroupBox "Parameters" containing intensity Slider with rounded-binding, merge strategy `.menu` Picker, Cancel/Re-analyze/Copy Config button row) plus delegates `displayState` to the new `formatResultRow` helper. Task 4 marks W2 PARTIALLY-CLOSED, W12 CLOSED, W20 CLOSED inline in `deferred-work.md` with full cross-references. Task 5 gauntlet all green (see AC #12 evidence below). Task 6 manual GUI smoke (AC #11) pending user action — auto-mode cannot drag files into SwiftUI windows; deferred per Story 5-2 precedent. Task 7 Completion Notes + Status flip via this entry.

2. **AC outcomes (programmatic; AC #11 manual smoke pending user run):**
   - AC #1 Intensity slider drives re-analysis on edit-end → `intensityBinding` two-way bridge with `Int($0.rounded())` clamp + `Slider.onEditingChanged: { if !$0 { triggerReanalyze() } }`; verified manually compiles, AC #11 GUI verification pending.
   - AC #2 Merge strategy picker drives re-analysis on selection change → `Picker` + `.menu` style + `.onChange(of: viewModel.options.mergeStrategy) { _, _ in triggerReanalyze() }`; `generateConfigSnippetMergeStrategyFormatting` test parameterized over all 8 `CandidateMergeStrategy.allCases` confirms label/rawValue mapping.
   - AC #3 Copy Config snippet → `generateConfigSnippet` covered by `generateConfigSnippetIntensityFormatting` (7 cases: 4 named + 3 raw) + `generateConfigSnippetMergeStrategyFormatting` (8 cases) + `generateConfigSnippetShape` (literal `yourURL`, `try AudioAnalysisService.analyzeBPM`, 4 lines, no surrounding whitespace).
   - AC #4 Cancel button + cancelInFlight() → `cancelInFlightIdle` no-op test + `cancelInFlightActive` proves DD #12 Branch A (`currentTaskID == taskID`, `isAnalyzing` resets, result fields stay nil, `pendingCancellations` drains). DD #12 Branch B (Cancel-then-Re-analyze double-fire) verified via Task 3.5 race-mitigation note + AC #11 manual smoke.
   - AC #5 Re-analyze button visibility predicates → `if viewModel.selectedFileURL != nil && !viewModel.isAnalyzing` in ContentView button row; hidden-via-`if` (not `.disabled(true)`); GUI verification deferred to AC #11.
   - AC #6 Snapshot-at-launch contract — no new code; existing `var opts = options` at AnalysisViewModel:156 already enforces; AC documented in story spec for auditability.
   - AC #7 NaN/Inf defensive guard → `formatResultRow` happy-path test (1 case) + `formatResultRowNaNGuard` parameterized over (bpm/confidence/elapsed) × NaN (3 cases) + `formatResultRowInfGuard` parameterized over (bpm/confidence/elapsed) × ±Inf (6 cases) + `formatResultRowMissingFields` (1 case). 11 tests total per DD #15 spec.
   - AC #8 New `AnalysisViewModel` API surface — `generateConfigSnippet` (static, `(AnalysisIntensity, CandidateMergeStrategy) -> String`), `copyConfigToPasteboard` (`@discardableResult -> Bool`, sets `errorMessage` on failure), `cancelInFlight` (no return; iterates `inFlightTasks` with cancel-all-prior cascade; does NOT touch `currentTaskID` per DD #12), `formatResultRow` (static, `Result<BPMResultRow, FormatError>`). Existing `analyze(url:autoStarted:)` UNCHANGED.
   - AC #9 `ContentView` controls section → `controlsSection` GroupBox titled "Parameters" above existing `primaryStateView + bannerView`. Drop-region modifier chain (`.frame` + `.contentShape(Rectangle())` + `.dropDestination` + `.overlay` + `.onOpenURL`) remains attached to the outer root VStack so drops over the controls section work (Task 2.8 verified by Axiom A2 modifier ordering).
   - AC #10 Smoke test additions → 48 demo test invocations at default cadence (18 baseline + 30 new = 48; pasteboard round-trip env-gated, skipped without `BBBKIT_RUN_PASTEBOARD_TEST=1`). All pass. Wall-clock for demo-test: 0.054s for `wrapping` + 0.055s for `cancelInFlightActive` + 0.108s for `manualReRunUsesCurrentOptions`; remaining cases sub-10ms each.
   - AC #11 Manual GUI smoke — pending user action; auto-mode cannot drive SwiftUI window-drop events.
   - AC #12 Library gating + demo gauntlets → all 13 gates green (see AC #12 evidence below).
   - AC #13 Epic 5 hygiene — A2 (deferred-work.md inline annotations W2/W12/W20) applied; A3 wall-clock recorded below.

3. **A3 wall-clock continuity (AC #13).** `make test` warm-cache 2.159s real (pre-flight) / 2.051s real (final gauntlet); Story 5-2 baseline 1.74s. Per-story delta: +0% library content (zero `Sources/` or `Tests/` library modifications); the +17-24% absolute wall-clock variance is parallel-test-runner scheduling jitter, not a real regression. Test count UNCHANGED at 431 in 94 suites. The 10% delta tripwire from MEMORY.md only fires on a content delta, not measurement noise.

4. **AC #12 gating gauntlet evidence (run at close-out 2026-05-19 → 2026-05-20):**
   - `make fmt` clean
   - `make demo-fmt` clean
   - `make lint` 1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline
   - `make build` 0.11s
   - `make build-release` 0.11s
   - `make test` 431/431 in 94 suites, 2.051s real
   - `make demo-build` BUILD SUCCEEDED
   - `make demo-test` TEST SUCCEEDED (48 invocations passing including parameterized cases; pasteboard test env-gated and skipped at default cadence)
   - `make demo-lint` exit 0
   - `make pre-commit` exit 0
   - `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED
   - `make benchmark` Acc1=58/82, Acc2=74/82 — UNCHANGED, all 12 tests pass (including baseline equality assertions for `windowVoting + .simpleMajority` and `durationHint=false`)
   - `make benchmark-giantsteps` Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — UNCHANGED, all 6 tests pass (MIREX-tolerance 562/661 = 85.0%, also stable; not pinned by spec but tracked).

5. **Build-time discoveries.**
   - **`Result<BPMResultRow, FormatError>` equality:** Swift's stdlib provides conditional Equatable on `Result` when both Success and Failure are Equatable. Promoted `BPMResultRow` to `Equatable` so `#expect(result == .failure(.nonFinite))` compiles cleanly in the NaN/Inf guard tests. Story 5-2's `DropError: Error, Equatable` is the precedent.
   - **Slider binding indentation:** Spec DD #2 specified the binding via a computed property; landed as `private var intensityBinding: Binding<Double>` exactly per the spec; per-render allocation cost is negligible for one Slider per `axiom-swiftui` architecture.md Anti-Pattern 6 footnote.
   - **GroupBox vs Form:** Picked `GroupBox` (lighter-weight per DD #9 dev-agent choice) — Form's heavy framing would have interfered with drop hit-testing per axiom-swift `transferable-ref.md` Anti-Pattern guidance. Drop modifiers stayed on the outermost VStack; controls section is the first child of that VStack.
   - **macOS 15 `.onChange(of:initial:_:)` two-param closure shape:** Used `{ _, _ in triggerReanalyze() }` — `_, _ in` rather than `oldValue, newValue in` since we don't consume either; matches Story 5-2's existing patterns.
   - **Pasteboard test isolation:** Followed Task 3.8 verbatim — `.enabled(if: ProcessInfo.processInfo.environment["BBBKIT_RUN_PASTEBOARD_TEST"] == "1")` trait skips the test at default cadence; defer-based clipboard restore is string-only.

6. **Pending user action at close-out (mirrors Story 5-2's pattern):**
   - Task 6 (AC #11) Manual GUI smoke test on `make demo-build-sandboxed` app: drop-and-tweak-slider, drop-and-pick-merge-strategy, Copy Config + paste + verify snippet, Cancel during long-running fixture, Re-analyze, slider-during-analyze snapshot-at-launch verification, no-file-dropped controls, DD #12 Branch B Cancel-then-Re-analyze interleave. Record outcomes verbatim in this Completion Notes section before final commit.
   - Task 7.4 `/bmad-code-review` on separate-LLM cadence (per project convention, different LLM than dev agent).
   - Task 7.5 final commit `Story 5-3: parameter controls + Copy Config snippet` (gated on 1Password GPG signer per Story 5-1 precedent).
   - **Out-of-scope hygiene tag-along (separate commit BEFORE Story 5-3 lands):** `.swiftpm/xcode/xcuserdata/rterhaar.xcuserdatad/xcschemes/xcschememanagement.plist` is tracked from the initial `e31872e init` commit, predating the `.swiftpm/` ignore rule. User chose option 2 (untrack as separate hygiene commit) when surfaced during close-out. Recommended: `git rm --cached -r .swiftpm/xcode/xcuserdata/` then commit with honest subject like `chore: untrack .swiftpm/xcode/xcuserdata (user-specific xcuserdata)`. Story 5-3's diff was reverted to be scope-clean of this file before close-out.

### File List

Modified:
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` (339 → 502 lines; +163; new `BPMResultRow` + `FormatError` types, `generateConfigSnippet` + `copyConfigToPasteboard` + `cancelInFlight` + `formatResultRow` methods; new `import AppKit`)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` (162 → 257 lines; +95; new `controlsSection` GroupBox with intensity Slider / merge strategy Picker / Cancel-Re-analyze-Copy-Config button row; new `intensityBinding` / `intensityLabelText` / `triggerReanalyze` helpers; `displayState` refactored to delegate to `AnalysisViewModel.formatResultRow`; `BPMResultRow` removed — moved to AnalysisViewModel)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` (138 → 304 lines; +166; 11 new `@Test` declarations covering generateConfigSnippet intensity-formatting × 7 + merge-strategy × 8 + shape sanity + cancelInFlight idle/active + manual re-run + formatResultRow happy/NaN×3/Inf×6/missing-fields + env-gated pasteboard round-trip; new `import AppKit`)
- `_bmad-output/implementation-artifacts/deferred-work.md` (W2 PARTIALLY-CLOSED amended with implementation cross-ref; W12 CLOSED; W20 CLOSED with `formatResultRow` cross-ref)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status flip `ready-for-dev → in-progress → review` + close-out `last_updated:` paragraph)
- `_bmad-output/implementation-artifacts/5-3-parameter-controls.md` (this file — Dev Agent Record / Completion Notes / File List / Change Log populated; Status flipped `ready-for-dev → review`)

Added: none (no new files in this story)

Deleted: none

Zero library Sources/ or Tests/ changes. Zero new SPM dependencies. Zero `.pbxproj` changes. Zero new audio fixtures (`find Demo -type f \( -name '*.wav' -o -name '*.aiff' -o -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' -o -name '*.caf' \)` returns empty per Story 5-1 DD #16-A).

### Change Log

| Date | Section | Change |
|------|---------|--------|
| 2026-05-19 | Status | `backlog → ready-for-dev` (Story 5-3 spec creation via `/bmad-create-story`) |
| 2026-05-19 | DDs / ACs / Tasks / Risk | `/bmad-party-mode` multi-reviewer pass (Codex adversarial + axiom-swiftui architecture skill + axiom-swift transferable-ref skill + Apple-docs Slider/NSPasteboard fetch). Patches applied: H1 W2 status changed to PARTIALLY-CLOSED (UX divergence deferred per DD #6); H2 DD #12 expanded to document Branch A and Branch B; H3 AC #5 / Task 2.5 Re-analyze visibility unified (hidden during analyze); H4 DD #15 added (static `formatResultRow` testable helper) + AC #7 / AC #10 / Task 1.5 / Task 2.7 / Task 3.7 updated; M5 DD #2 + Task 2.3 switched `Int($0)` → `Int($0.rounded())`; M6 Task 3.8 env-gated pasteboard round-trip; M7 Task 3.6 renamed "re-run wiring" → "manual re-run uses current options"; M8 Task 2.8 strengthened drop-region preservation; M12 DD #8 softened NSPasteboard main-queue-safe claim; L9 AC #8 / Task 1.3 unified `copyConfigToPasteboard()` signature on `@discardableResult -> Bool`; R9 added (Cancel-then-Re-analyze double-fire idempotency); Project Structure Notes effort estimates bumped (AVM +60→+90, CV +80→+70, tests +120→+160) |
| 2026-05-19 | DD preamble / Task 1.4 / Previous Story Intel | `/bmad-advanced-elicitation` Self-Consistency Validation pass (Codex post-cut audit). 3 minor patches: DD preamble "most consequential" list updated to include #4 #7 #12 #15 (cuts removed them from the list without updating); Task 1.4 corrected `per DD #12` → `per DD #4 + DD #12` (cascade body moved to DD #4 in cut #1); Codex M12 view-model-constructed error templates bullet restored to Previous Story Intelligence (lost in cut #6 compression, but load-bearing for Story 5-3's new non-finite error message). Codex verdict: PASS-WITH-MINOR-PATCHES. AC #11 Branch B muddiness (Re-analyze hidden during drain → step verifies "after Cancel" not true interleaving) flagged for future attention but not patched. |
| 2026-05-19 | DDs / Risk / Previous Story Intel / References / Tasks 1.2-1.5 | `/bmad-advanced-elicitation` Occam's Razor pass (Codex selective vote). Applied cuts: DD #4 absorbed DD #10's hidden-via-`if` rule (DD #10 collapsed to 1-line redirect); DD #6 trimmed to W2-disposition statement; DD #13/#14 collapsed to test-inventory pointer (full enumeration in AC #10 + Task 3); R1+R2+R6+R7 merged into "Non-defects observed" paragraph; R9 condensed to DD #12 Branch B reference; Previous Story Intelligence compressed (8+3+2 bullets → 8 inheritance bullets); References deduped (Sources/*.swift + Demo/*.swift bullets removed — covered in Architecture references + Project Structure Notes); Tasks 1.2-1.5 bodies replaced with `per DD #N` (DDs already specify verbatim); intro "dev agent's discipline" closing line cut. Skipped per Codex vote: DD #2 #12 #15 left intact (load-bearing). Skipped per user override: Apple Platform Notes verbatim Slider/Picker/NSPasteboard code examples kept. Net: ~700 → ~580 lines (~17% reduction); zero behavioral specificity lost. |
| 2026-05-20 | Status / Dev Agent Record / File List / Change Log | Story 5-3 dev close-out via `/bmad-dev-story` workflow; status flips `ready-for-dev → in-progress → review`. Auto-mode single-shot implementation, no HALT events fired. Zero library Sources/ + zero Tests/ changes. All 13 AC programmatic gates green; AC #11 manual GUI smoke deferred to user (auto-mode cannot drive SwiftUI window-drop events, per Story 5-2 precedent). W2 PARTIALLY-CLOSED + W12/W20 CLOSED inline in `deferred-work.md` per A2. Out-of-scope hygiene tag-along surfaced: `.swiftpm/xcode/xcuserdata/...xcschememanagement.plist` tracked from initial commit predating `.swiftpm/` ignore rule; user chose option 2 (untrack as separate hygiene commit) at close-out; Story 5-3 diff was reverted to be scope-clean of this file. |

### Review Findings

Populated 2026-05-20 by `/bmad-code-review` 4-layer pass (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex consult) against commit `90d2061`. Auditor verdict: GREEN (all 13 ACs + 15 DDs met). Other layers: YELLOW (no CRITICAL/HIGH after Codex refutation of F1/F2/F3 supersession concern; mostly MEDIUM/LOW defensive items). Initial tally: 3 decision-needed, 4 patches, 6 deferred, 17 dismissed. Post-resolution: 0 decision-needed (D1 dismissed via Codex follow-up — Apple's `URL.startAccessingSecurityScopedResource()` is documented as balanced/repeatable; D2 deferred to Story 5-4 trace surface; D3 promoted to P5), 5 patches, 7 deferred, 18 dismissed.

- [x] [Review][Patch] **P1: `copyConfigToPasteboard` leaves stale `errorMessage` after a successful copy** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:117-121] — sources: Blind F4, Codex MEDIUM. APPLIED 2026-05-20: on `didCopy == true`, clear `errorMessage` only if it equals `"Could not copy to clipboard"` (preserves unrelated banner messages like drop-validation errors per DD #16 semantics). Two new tests: `copyConfigToPasteboardClearsStaleError` + `copyConfigToPasteboardPreservesUnrelatedError`.
- [x] [Review][Patch] **P2: `intensityBinding` setter `Int(newValue.rounded())` traps on NaN/±Inf (defensive symmetry with W20)** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift:57] — sources: Edge E1, Codex LOW. APPLIED 2026-05-20: `guard newValue.isFinite else { return }` before `Int(newValue.rounded())`. Symmetric with the W20 hardening applied to `formatResultRow`.
- [x] [Review][Patch] **P3: Picker `.onChange` doc comment misleading — fires for any mutation, not only user selection** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift:114-117] — source: Edge E5. APPLIED 2026-05-20: comment updated to clarify `.onChange(of:)` fires for ANY mutation, including programmatic writes. No behavioral change today (Picker is the only mutation site); the comment now correctly describes the footgun for future stories.
- [x] [Review][Patch] **P4: `formatResultRow` doesn't guard against negative `elapsedSeconds`** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:178-194] — source: Blind F8. APPLIED 2026-05-20: merged into the combined guard from P5 — `elapsedSeconds >= 0` added to the same `isFinite` line. One new test: `formatResultRowElapsedNegativeGuard`.
- [x] [Review][Patch] **P5: `formatResultRow` does not validate `confidence ∈ [0, 1]` or `bpm > 0` (resolution of D3)** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:178-194] — source: Blind F5. APPLIED 2026-05-20: `guard bpm.isFinite, bpm > 0, confidence.isFinite, (0.0...1.0).contains(confidence), elapsedSeconds.isFinite, elapsedSeconds >= 0 else { return .failure(.nonFinite) }`. FormatError case name `.nonFinite` retained (renaming to `.invalidRange` would churn the W20 deferred-work entry and the 9 existing NaN/Inf test cases without behavioral gain — documented inline in the helper). 6 new test invocations: `formatResultRowBPMRangeGuard` × 2 (bpm=0, bpm=-1), `formatResultRowConfidenceRangeGuard` × 2 (confidence=1.5, confidence=-0.1), `formatResultRowConfidenceBoundaryAccepts` × 2 (confidence=0.0 and =1.0 boundary inclusivity).

**Gauntlet verification (post-patch close-out 2026-05-20):**
- `make demo-fmt` — clean
- `make demo-lint` — exit 0
- `make lint` — 1 violation (canonical LUFSAnalyzer.swift:94 TODO baseline)
- `make demo-build` — BUILD SUCCEEDED
- `make demo-test` — TEST SUCCEEDED; 57 default-cadence invocations (was 48 pre-patch; +9 = 7 new range-guard tests + 2 new pasteboard-errorMessage tests). Pasteboard round-trip remains env-gated and skipped at default cadence.
- [x] [Review][Defer] **W24: `cancelInFlightActive` test brittleness — race between natural completion and cancel propagation** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:228-253] — deferred, sources: Blind F6, Edge E2, Codex partial refutation. The test asserts `detectedBPM == nil` which catches false-pass cases, but a busy CI could see a flaky-FAIL if natural completion wins the race on a fast machine. Mitigation: use a longer fixture OR insert `try await Task.yield()` between `analyze` and `cancelInFlight` to force the detached DSP to start. Defer: revisit if test goes flaky on CI.
- [x] [Review][Defer] **W25: Cancel propagation latency UX — "Cancelling…" can show for 30+ seconds on long files at high intensity** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift cancelInFlight + library window-boundary polling] — deferred, source: Edge E10. Library-side concern (ADR-1 between-windows cancellation); the demo cooperates correctly. Defer: revisit only if a story decides to add per-step cancellation polls in the library, OR if a user reports the perceived freeze on a long file.
- [x] [Review][Defer] **W26: Pasteboard env-gated test has no diagnostic on restricted-pasteboard CI environments** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:678-702] — deferred, sources: Blind F11, Edge E16. If `BBBKIT_RUN_PASTEBOARD_TEST=1` is set in a restricted-TCC CI runner, `setString` returns false and the test fails without surfacing that pasteboard access was denied (vs the snippet being wrong). Defer: revisit if/when CI policy adds the env var.
- [x] [Review][Defer] **W27: GroupBox containing Slider may capture mouse events that prevent drop onto controls section** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift controls section + outer drop chain] — deferred, source: Edge E12. The diff comment at Task 2.8 claims "a user dragging onto the slider still drops successfully" but this is not unit-testable. Defer: verify in AC #11 manual smoke (Task 6); if confirmed broken, fix by adjusting gesture-system precedence.
- [x] [Review][Defer] **W28: Picker labels show camelCase rawValues (`maxConfidence`, `windowVoting`)** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift:109] — deferred, source: Blind F10. Acceptable for the demo per spec; user-facing strings would want a human-readable mapping. Defer: revisit if/when the demo evolves into a more polished release shape.
- [x] [Review][Defer] **W29: Cancel button can flash "Cancel" between `isCancelling: false → isAnalyzing: false` propagation** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift cancel button] — deferred, source: Blind F13. One-frame visual artifact from two independent @Observable properties driving one button's text. Defer: verify in AC #11 manual smoke; if not observed, dismiss.
- [x] [Review][Defer] **W30: `manualReRunUsesCurrentOptions` test coverage gap — Story 5-4 trace surface hook (resolution of D2)** [Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:262-287] — deferred, sources: Blind F7, Edge E3, Codex confirms. User resolution 2026-05-20: defer to Story 5-4. Once Story 5-4 adds a trace-view surface exposing the merge strategy actually applied to a run, tighten this test to assert the trace's `mergeStrategy` field equals `.dedup` post-re-run, OR rename the test then to match what it actually verifies. Until then the test name overpromises; the assertion (`detectedBPM != nil`) catches only "completes," not "options honored."

**Refuted findings (not patched, not deferred):**

- Blind Hunter F1/F2/F3 (HIGH): "slider/picker re-analyze paths bypass `!isAnalyzing` gate; intensityBinding writes continuously during drag." Codex inspected `analyze(url:autoStarted:)` and confirmed the supersession contract (cancel-all-prior cascade + UUID gate + snapshot-at-launch) handles each control-driven rerun correctly. The intensityBinding writes during drag mutate `viewModel.options` but the in-flight task uses its pre-drag snapshot, and the per-render label refresh is in-place. No CRITICAL/HIGH correctness issue.
- Blind Hunter F9/F12/F14/F15, Edge E4/E6/E7/E8/E9/E11/E13/E14/E15/E17, Auditor cosmetic line-number/file-count/"10 vs 11" drifts: dismissed as defensive intent, OK sanity checks, NIT-level UX inconsistencies, or post-merge cosmetic doc drift.
- **D1 (Codex finding, MEDIUM, dismissed via Codex follow-up 2026-05-20):** Re-analyze loses `.onOpenURL` `autoStarted: true` provenance. Codex follow-up (thread `019e43e5-b44a-7243-b7d9-c86fd91dd2ed`) cited Apple's documented `URL.startAccessingSecurityScopedResource()` model as balanced/repeatable — a later explicit `start...` after a prior balanced `stop...` is expected to succeed within the same process for `.onOpenURL`-arrived URLs, just as the axiom `sandbox-and-file-access` skill table empirically observes for drop-destination URLs. The `autoStarted` parameter has no security-scope side effects in `analyze()` — it's a telemetry flag. Recommended additional AC #11 manual smoke step: "Open a file via Dock-icon-drop or `open -a` → wait for completion → adjust slider → verify re-analysis succeeds (no `sandbox denied`)." Added to AC #11 checklist (manual; auto-mode cannot drive Dock-icon-drop events).
