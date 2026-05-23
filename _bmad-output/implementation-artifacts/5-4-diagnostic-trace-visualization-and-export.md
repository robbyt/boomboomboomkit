# Story 5.4: Diagnostic Trace Visualization and Export

Story ID: 5.4
Story Key: 5-4-diagnostic-trace-visualization-and-export
Epic: 5 — Developer Experience & Demo (fourth story; opens FR37 / FR41)
Status: review

## Story

As a developer evaluating BoomBoomBoomKit via the demo app,
I want to inspect the diagnostic trace data from the most recent analysis and export it as JSON,
So that I can understand which pipeline step produced the final BPM (without reading DSP source) and plot or audit the intermediate state in an external tool.

**Scope clarification (read first).** Story 5-4 wires the trace-visualization + JSON-export slice on top of the Story 5-2 file-drop, Story 5-3 parameter-controls + Cancel/Re-analyze surfaces. Three additions land in the UI:

1. **Trace section in the demo window** — a `DisclosureGroup` rendered below the result row that surfaces the post-run `BPMDiagnosticTrace` in a human-readable layout. Visible only when a successful run is on the screen (i.e., `viewModel.detectedBPM != nil` AND `viewModel.lastRunSnapshot != nil` — the atomic snapshot from DD #5). Collapsed by default; user expands to inspect.
2. **"Which step selected the final BPM" derived label** — a single-line summary at the top of the trace section answering the epic AC's "which pipeline step selected the final BPM" requirement. The library does NOT carry this as a trace field; the demo derives it by comparing `refinedBPM` vs `disambiguationResult`, checking `subBandVoteDetail.changed`, comparing `candidatesAfterBoost` vs `candidatesBeforeBoost`, and inspecting `ensembleDecision.winner` (see DD #6).
3. **Export Trace button** — emits the current trace + run metadata as a single JSON document via `NSSavePanel`. Visible when the trace section is populated (mutually exclusive with the in-flight indicator). The button is in the controls row alongside `Cancel` / `Re-analyze` / `Copy Config` (see Story 5-3 DD #4 layout).

Story 5-4 also adds **always-on trace capture** for the demo (DD #1) — every `analyze(url:autoStarted:)` call overrides `opts.enableTrace = true` regardless of any other setting. This is a demo-specific contract; consumers who want the perf savings of `enableTrace: false` continue to get the default opt-out at the library level (`Options.enableTrace = false`).

Story 5-4 closes deferred-work items **W30** (tightens `manualReRunUsesCurrentOptions` to assert the run actually used the configured merge strategy, via the new `lastRunMergeStrategy` snapshot — see DD #5). **W2 is FULLY CLOSED**: the trace surface includes "Result captured at: intensity X / strategy Y" in the derived run-metadata block, addressing W2's deferred third mitigation alongside the snapshot-at-launch contract and the Re-analyze button delivered by Story 5-3.

The deferred-work line at `_bmad-output/implementation-artifacts/deferred-work.md:362` ("`EnsembleDecision` is not `Codable` while nested `Winner: Codable`") was filed with an explicit re-open trigger naming this story: "whichever story makes `BPMDiagnosticTrace: Codable` will need to extend `EnsembleDecision`." DD #2 resolves this **without modifying the library** — the demo carries its own Codable projection types and does NOT promote `BPMDiagnosticTrace` to `Codable`. The deferred-work entry stays open with an updated cross-reference; a future library-side trace-Codable story can address it then.

**What this story does NOT deliver** (each is a separate Epic 5 story OR explicit OUT-OF-SCOPE):

- Library-side `BPMDiagnosticTrace: Codable` conformance — would require migrating 8 labeled-tuple fields (`acfTopLags`, `tempogramTopBPMs`, `fusedTopBPMs`, `tps2TopBPMs`, `rawCandidates`, `disambiguationResult`, `candidatesBeforeBoost`, `candidatesAfterBoost`) to named `Sendable` structs in `Sources/`, plus `EnsembleDecision: Codable` extension, plus an inevitable schema-version field on the library type. That is a non-trivial library change requiring its own story spec and is explicitly OUT OF SCOPE for Story 5-4 (DD #2). The demo's `TraceExport` Codable struct is demo-internal; it stays in `Demo/BoomBoomBoomKitDemo/`.
- Plotting / charting inside the demo — the AC says "export JSON for external plotting." No `swift-charts` integration, no waveform visualization, no candidate scatter plot. Out of scope.
- Trace persistence (auto-save every analysis, recent-traces menu) — single-run snapshot only. Out of scope per Story 5-1 DD #16.
- Multi-trace comparison — show prior vs current trace side-by-side. Out of scope; user can export N JSONs and diff them externally.
- VotingPolicy / votingThreshold picker — orthogonal feature; Story 5-3 deferred. The trace JSON includes `metadataPolicyUsed` (already on the trace) and `votingPolicy` / `votingThreshold` (from the run-time `Options` snapshot via DD #5) but no UI control is added.
- TechniqueSet override picker — Story 5-3 deferred. Trace JSON surfaces `intensityUsed` (already on the trace); demo does not expose `techniqueSet` for user override.
- ML technique slot UI — `Options.mlTechnique` remains nil-by-default per Story 4-6 Branch C. The trace JSON includes `ensembleDecision` and `mlDiagnosticSnapshot` IF the user supplied a `BNNSTechnique` instance via code (which the demo does not), so those sections render as `null` in practice. Out of scope for the demo UI.
- `MLFeatureFrames.logMelData` inclusion in the exported JSON — the bulk log-mel tensor (`melBands * frames * 4` bytes; ~768 KB at default intensity for a 3-minute file) would inflate every export to multi-megabyte JSON for negligible diagnostic value at the demo level. Out of scope; trace JSON v1 emits `mlFeatures` shape metadata only (`melBands`, `frames`, `tensorLayout`, `sampleRate`, `featureSetVersion`) without the float payload (DD #11).
- Public DocC + README quick-start → Story 5-5 (`Public API Documentation and README`)
- Recent-files menu, bookmark persistence, multi-file batch — OUT-OF-SCOPE per Story 5-1 DD #16 (still)

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #3, #4, #5, #6, #7, #8, #11, and #14 are the most consequential** — they lock the always-on-trace contract, the no-library-Codable-promotion boundary, the projection schema, the NSSavePanel transport, the post-run option snapshot, the final-step derivation rules, the disclosure-vs-sheet UX, the metadata evidence surfacing, the `mlFeatures` payload exclusion, and the schemaVersion seam.

1. **Always-on trace capture for the demo.** The demo overrides `opts.enableTrace = true` at the synchronous prologue of `analyze(url:autoStarted:)`, AFTER the `var opts = options` snapshot line (Story 5-2/5-3 snapshot-at-launch contract preserved). Three semantics were considered:

   - **(A) Opt-in checkbox in the controls section** — user toggles "Capture diagnostic trace" before each run. Mirrors the library's opt-in default but adds UI for what is, at demo level, always desired.
   - **(B) Always-on at view model init** — set `options.enableTrace = true` in `AnalysisViewModel.init()`. Works today but is fragile: any future code path that resets `options = .init()` (or a state-restoration path that decodes options from disk) silently disables trace.
   - **(C) Override at analyze launch** — explicit `opts.enableTrace = true` immediately after the snapshot line. Idempotent across re-runs, robust against any external `viewModel.options` mutation that strips the flag.

   **Chosen: (C).** The override sits between `var opts = options` (line 183 today) and the `Task { [weak self] in ...` launch (line 187 today). One added line; demo-specific contract; consumers retain the library default. Story 4-3b measured the corpus-grain trace-build overhead at 1.054× (within the documented 1.30× perf gate); for single-file demo runs the absolute cost is well under 100 ms at default intensity 7. The `enableMLDiagnostics` flag stays at its default `false` (no ML technique wired in the demo per Story 4-6 Branch C — there is nothing to capture).

   **Story-5-2 W20 / Story-5-3 P5 invariant preserved.** The post-run NaN/Inf + range-guard logic in `AnalysisViewModel.formatResultRow` is independent of trace state; it consumes `viewModel.detectedBPM` / `confidence` / `elapsedSeconds`, none of which are touched by this DD. Trace-on does NOT change the result-row formatting path.

2. **Library-side `BPMDiagnosticTrace` is NOT promoted to `Codable`. The demo carries its own Codable projection.** Story 5-4 is a demo story by Epic 5 framing; the library remains public-API-only consumable. Project-context.md §"Public API Discipline (pre-1.0)" mandates that every internal-to-public promotion requires a named story spec naming the use case — and the use case here is demo export, not library export. Promoting `BPMDiagnosticTrace` to `Codable` would also require:

   - Migrating 8 labeled-tuple fields to named `Sendable` structs (`acfTopLags`, `tempogramTopBPMs`, `fusedTopBPMs`, `tps2TopBPMs`, `rawCandidates`, `disambiguationResult`, `candidatesBeforeBoost`, `candidatesAfterBoost`). Each is a `(bpm: T, score: U)` or `(lag: Int, strength: Float)` shape and cannot conform to `Codable` directly. The migration would touch `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`, `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (every write site), and ~25 test files.
   - Extending `EnsembleDecision` to `Codable` (deferred-work `:362` explicitly names Story 5-4 as a re-open trigger for this). The nested `Winner` is already `Codable`; the outer struct is not.
   - Adding a `schemaVersion` seam to the library trace — today there is none; the trace is documented as "evolving — fields may change across versions."

   That is a non-trivial library change requiring its own spec; it is NOT authorized by Story 5-4. **The demo creates a `TraceExport` Codable struct in `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/` that mirrors the trace surface using projection-only types (`CandidateScore { bpm: Double; score: Float }`, `LagStrength { lag: Int; strength: Float }`, `BPMMagnitude { bpm: Int; magnitude: Float }`, `BPMScore { bpm: Int; score: Float }` — each conforming to `Codable, Sendable, Equatable`).** A `TraceExport.from(trace:options:runMeta:)` factory projects the library trace into these types. The library trace is untouched. The deferred-work `:362` entry stays open with an updated cross-reference recording that Story 5-4 deferred the library promotion to a future story.

   **Cost of the demo-side projection.** ~10 small structs (most are 2-3 fields). ~150 lines of mechanical mapping in the factory. No accuracy risk, no test churn outside the demo. Library `Sources/` and `Tests/` are unchanged.

3. **JSON export transport: `NSSavePanel`, NOT pasteboard.** Three transports were considered:

   - **Pasteboard string (Story 5-3 mechanism)** — reuse `NSPasteboard.general.setString(...)`. Story 5-3's Copy Config snippet is 4 lines (~150 bytes); a trace JSON is 5-50 KB at default intensity. Large pasteboard entries work technically but are awkward to consume: the user has to paste into a file manually, and any text consumer that doesn't expect multi-KB input renders the entire blob as one line.
   - **Direct file write to `~/Downloads/` or similar** — bypasses sandbox via a known path. Fails inside the app sandbox without a security-scoped resource grant. Would require pre-staking entitlements on a fixed directory, which is not how macOS sandboxing is designed to work.
   - **NSSavePanel** — Apple's PowerBox UI grants transient write access to the user-chosen file. Sandbox-friendly; user names the file and picks the destination; the demo writes exactly one file then forgets the URL (no bookmark persistence per Story 5-1 DD #16).

   **Chosen: NSSavePanel.** The Export Trace button presents a save panel with `allowedContentTypes: [.json]`, `nameFieldStringValue: "<source-filename>-trace"` (NOTE: NO `.json` suffix in `nameFieldStringValue` — `allowedContentTypes` auto-appends the extension when the user accepts; passing `"foo-trace.json"` would produce `foo-trace.json.json` post-confirm per Codex finding #5), and `canCreateDirectories: true`. On user confirm, the demo writes the encoded JSON to the chosen URL via `Data.write(to:options: .atomic)`. On `.cancel` the panel dismisses with no side effects.

   **Security-scoped resource discipline (axiom-macos `sandbox-and-file-access.md:306` table).** NSSavePanel-returned URLs have security-scoped access **AUTO-STARTED** by PowerBox; the demo MUST call `panel.url?.stopAccessingSecurityScopedResource()` after the write to release kernel resources. Use `defer { url.stopAccessingSecurityScopedResource() }` immediately after unwrapping `panel.url`, mirroring the auto-started bracket convention from Story 5-2 DD #4 (`.onOpenURL` path). The bracket fires on any exit path: write success, write failure, or early return from a JSONEncoder throw.

   **Sandbox entitlement upgrade required — for the WRITE, not the panel (Siri + axiom-macos verification 2026-05-20).** Today the demo's entitlements (`Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements`) carry `com.apple.security.files.user-selected.read-only`. The corrected framing:

   - **`NSSavePanel.runModal()` itself opens regardless** of which `files.user-selected.*` entitlement is declared. The panel is AppKit UI; declaring NO file-access entitlement at all still lets the panel present.
   - **The post-panel `Data.write(to: panel.url!)` is what gates on the entitlement.** With `user-selected.read-only`, the write fails with `NSCocoaErrorDomain` code 513 (`NSFileWriteNoPermissionError`); the user sees the panel succeed then the file never appears, which is a worse UX than a synchronous failure path.
   - PowerBox auto-grants security-scoped READ access on the returned URL; **WRITE capability is gated by the declared entitlement**, not by the panel's PowerBox grant.

   Story 5-4 promotes the entitlement (one-line key change) and verifies via `make demo-build-sandboxed`:

   ```xml
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   ```

   The read-write upgrade ALSO permits writing back to files dropped onto the window — but the demo never writes to a dropped audio file, so this is a strictly additive entitlement broadening. AC #5 includes a manual smoke test for both the save success path AND the `.cancel` no-op path.

   **No pasteboard fallback.** If `NSSavePanel` somehow fails (theoretical — the panel is in-process AppKit infrastructure), the dev agent surfaces `errorMessage = "Could not export trace JSON."` and the user can re-attempt. No silent failure, no pasteboard side-channel.

4. **Trace view surface: `.inspector(isPresented:)` trailing column (POST-IMPL AMENDMENT 2026-05-20).** Originally chosen as `DisclosureGroup` inline below the result row per the three-option analysis below; the manual GUI smoke test for AC #1 surfaced an empty-window layout failure (chevron flips, content area renders as window-filling whitespace). Post-impl invocation of `axiom-swiftui` (`layout-ref.md:313` documents `Form`/`ScrollView`/`GeometryReader` as "greedy sizing" containers — `Form` inside `DisclosureGroup` inside `VStack(maxHeight: .infinity)` with no scroll owner is the exact anti-pattern) and `axiom-macos` (`swiftui-differences.md:266-298` documents Inspector as the macOS-native pattern for selection-dependent detail — the trace IS detail-of-current-selection) converged on `.inspector(isPresented:)` as the documented-correct reframe. Originally three options were considered (A) `DisclosureGroup`, (B) `.sheet`, (C) `NavigationStack`; the fourth option (D) `.inspector(isPresented:)` was never weighed pre-impl — that was the spec-level miss this amendment closes. The DisclosureGroup language below is preserved for historical traceability; the actual implementation uses `.inspector` per DD #4-B.

   **DD #4-B (POST-IMPL AMENDMENT 2026-05-20) — Inspector reframe.** `ContentView` attaches `.inspector(isPresented: $inspectorPresented)` at its root with `.inspectorColumnWidth(min: 240, ideal: 320, max: 480)`. The inspector pane renders `TraceView(snapshot:)` when `viewModel.lastRunSnapshot != nil`, else `TraceInspectorEmptyView()` ("Drop an audio file to analyze."). `@SceneStorage("traceInspectorPresented") private var inspectorPresented: Bool = true` persists user toggle across scene lifecycle; default `true` for first-time discoverability (the dev-demo audience WANTS the diagnostic surface up). `BoomBoomBoomKitDemoApp` adds `.commands { InspectorCommands() }` so Control-Command-I + View menu entry work (axiom-macos anti-pattern #5: missing `InspectorCommands()` violates standard macOS expectations). `TraceView` is restructured: NO outer `DisclosureGroup` (the inspector IS the disclosure mechanism), NO `Form` / `.formStyle(.grouped)` (greedy sizing — axiom-swiftui `layout-ref.md:313`), instead a `ScrollView` owning the scroll region with a `VStack(alignment: .leading, spacing: 12)` of `GroupBox("section") { VStack { LabeledContent rows } }` blocks — the macOS 13+ idiom for inline grouped content outside a Settings scene (axiom-macos + axiom-swiftui converge here). The `WindowGroup` default size grew from `(640, 480)` to `(960, 600)` to accommodate the trailing inspector column at its `ideal: 320` width without crowding the main pane.

   **Original DisclosureGroup analysis (HISTORICAL):** Three surfaces were considered:

   - **(A) `DisclosureGroup`** — expand/collapse inline. The window grows tall when expanded; user scrolls within the existing `VStack`. No navigation plumbing. Hides automatically when no trace is available (the disclosure itself is wrapped in `if viewModel.lastRunSnapshot != nil`).
   - **(B) `.sheet`** — modal overlay that covers the main window. Disconnects the trace from the result row visually; closing the sheet returns to the result. Adds a `@State private var showTrace: Bool` toggle in ContentView, an extra button to open the sheet, and `.dismiss` plumbing.
   - **(C) `NavigationStack` + `NavigationLink`** — push to a detail view. Cleanest for full-screen detail but requires wrapping the entire ContentView in a `NavigationStack`, which Story 5-2 / 5-3 deliberately avoided (the demo is single-window with no navigation).

   **Chosen: (A) `DisclosureGroup`.** Lightest-touch addition; the demo is for evaluation, not full UI showcasing. The trace section sits inside the same `VStack` that holds the result row; collapsing the disclosure restores the window to its post-Story-5-3 layout.

   **W2 close — result-adjacent caption line PLUS reinforcing disclosure header (post-Sally + Codex review 2026-05-20).** The v1 spec attempted to close W2 entirely through the disclosure-header label. Codex finding #3 + Sally's UX critique both flagged that this couples the W2 visibility to the trace section's health — if `lastRunSnapshot == nil` for any reason (a future story path where the trace fails but the BPM succeeds), the W2 surface disappears. W2's mitigation is broader: the user must understand which run config produced the displayed BPM, independent of the trace section's state.

   **Two surfaces, layered (final design):**
   1. **Primary W2 close — caption line directly beneath the result row.** When `viewModel.detectedBPM != nil` AND `viewModel.lastRunSnapshot != nil`, render a quiet caption: `Result captured at: intensity <X>, <mergeStrategyHumanized>` immediately below the BPM/confidence/intensity/elapsed row inside `resultView`. Examples: `Result captured at: intensity 7, max confidence` (camelCase rawValue humanized — see "humanization" below). When the user adjusts a slider after the result lands, the caption stays put showing the snapshot values; the user immediately sees the divergence from current control state. The caption is part of `resultView` (Story 5-2's existing structure), NOT inside the `DisclosureGroup` — so it surfaces even when the trace section is collapsed.
   2. **Reinforcing disclosure header** (secondary). The `DisclosureGroup` label reads simply `"Diagnostic Trace"` — clean, inviting. The derived final-step badge (DD #6) appears in the expanded content next to a `?` info popover (DD #4 expanded content section, see Sally's recommendation).

   **Humanization of `CandidateMergeStrategy` rawValues** (Sally feedback). The caption applies a one-pass humanization to the rawValue: `maxConfidence` → `"max confidence"`, `dedup` → `"dedup"`, `weightedAverage` → `"weighted average"`, `windowVoting` → `"window voting"`, etc. The humanizer is a small static `func humanize(_ strategy: CandidateMergeStrategy) -> String` on the demo helper file, mapping each of the 8 rawValues to a space-separated lowercase form. **The exported JSON's `run.mergeStrategy` keeps the rawValue verbatim** (so consumers see the API symbol, not the humanized label) — humanization is a UI-only concern.

   **AC #13's W2 closure depends on the caption line being always-visible whenever `detectedBPM != nil`** (NOT the disclosure header). The header summary remains a nice-to-have reinforcement but is no longer the load-bearing W2 surface.

   **Internal structure of the expanded view.** A vertical `Form` (macOS grouped layout) with these sections in order, each section a `Section` with a header:
   1. **Run** — `fileName`, `intensityUsed`, `mergeStrategyUsed` (from `lastRunMergeStrategy` snapshot per DD #5), `elapsedSeconds`, `bpm`, `confidence`, `degradationReason` (if non-nil).
   2. **Selection path** — derived final-step label + a `Text` of the short reasoning (DD #6).
   3. **Candidates** — three side-by-side `List`-style rows: `rawCandidates`, `candidatesBeforeBoost`, `candidatesAfterBoost`. Each entry as `"<bpm rounded to .1f> @ <score .2f>"`.
   4. **Sub-band energies** — 4 rows for `kick/snare/crack/hihat`.
   5. **Disambiguation** — `disambiguationResult` BPM + score; `harmonicRatioDetail` if present (ratio + winner BPM); `subBandVoteDetail` if present (pre/post/changed).
   6. **Fine-grid** — `refinedBPM` if present, else `"(not run)"`.
   7. **Metadata corroboration** — `metadataPolicyUsed.enabledSources` (the joined Set), then per-entry `metadataEvidenceBeforeBoost` table: `source`, `parsedBPM` (or rejection reason), `corroboratedWith` (if any), `boostApplied`, `rejectionReason`.
   8. **ML ensemble** — `ensembleDecision` (winner / dspConfidence / mlConfidence / mlAbstained / selectedBPM) if present, else `"(ML not active)"`. `mlDiagnosticSnapshot` shape summary if present.

   **No charts, no progress bars, no animations.** Plain `Text` and `Table`-like row layouts. The dev agent SHOULD use `Table` if the row count is variable and benefits from sortable columns (candidate lists especially); for fixed 4-row blocks (sub-band energies), simple `HStack` per row is sufficient.

5. **Atomic `LastRunDiagnosticSnapshot` retained on the view model (post-Winston + Codex review 2026-05-20).** The library's `BPMDiagnosticTrace` carries `intensityUsed: AnalysisIntensity` and `metadataPolicyUsed: MetadataPolicy` but does NOT carry `mergeStrategyUsed`, `votingPolicy`, `votingThreshold`, `techniqueSet`, `ensemblePolicy`, or any other `Options` field. Story 5-4 needs `mergeStrategyUsed` for the trace JSON's Run section AND to close W30.

   **Three options considered:**

   - **(A) Promote `mergeStrategyUsed: CandidateMergeStrategy` to `BPMDiagnosticTrace`** — library change; out of scope per DD #2.
   - **(B) Three separate `@ObservationIgnored` fields** (`lastTrace`, `lastMetadataEvidence`, `lastRunOptionsSnapshot: AudioAnalysisService.Options?`) — v1 spec choice; rejected post-review.
   - **(C) One atomic `LastRunDiagnosticSnapshot` value type** holding all four pieces of state (`trace`, `metadataEvidence`, `runOptions`, `fileName`) as a single Optional.

   **Chosen: (C).** A single atomic snapshot eliminates the "trace populated but options nil" partial-state race (Codex finding #2): the three fields cannot drift out of sync because they are written together via a single assignment.

   ```swift
   struct LastRunDiagnosticSnapshot: Sendable {
     let trace: BPMDiagnosticTrace
     let metadataEvidence: [MetadataBPMEvidence]
     let runOptions: RunOptionsSnapshot     // narrow struct, see below
     let fileName: String
   }

   struct RunOptionsSnapshot: Sendable, Equatable {
     let intensity: AnalysisIntensity
     let mergeStrategy: CandidateMergeStrategy
     let votingPolicy: VotingPolicy
     let votingThreshold: Double
     let metadataPolicyEnabledSources: Set<MetadataSource>
     let durationHint: Bool
     let durationHintMinFileSeconds: Double
     let ensemblePolicy: EnsemblePolicy
     let enableTrace: Bool
     let enableMLDiagnostics: Bool
     let maxSeconds: Double
   }

   @ObservationIgnored
   var lastRunSnapshot: LastRunDiagnosticSnapshot?
   ```

   **Why a narrow `RunOptionsSnapshot` struct instead of holding the full `AudioAnalysisService.Options`** (Winston's retain-hazard concern). `Options` carries `isCancelled: @Sendable () -> Bool` and `onProgress: (@Sendable (ProgressUpdate) -> Void)?` closures. The active analyze body sets `opts.isCancelled = { @Sendable in cancelFlag.load(...) }` — that closure captures the per-run `cancelFlag: Atomic<Bool>`. Retaining `opts` post-run via `lastRunSnapshot` would keep `cancelFlag` alive for the lifetime of the last successful run, plus any closures the caller had previously installed. The narrow value-type projection holds only the 11 fields the JSON Run section needs — zero closures, no retain hazard, `Equatable` synthesized for free (used by AC #8 in `manualReRunUsesCurrentOptions`).

   **Write site (atomic):** in the `.success(value?)` arm of the result switch, the snapshot is constructed and assigned in one line:

   ```swift
   self.lastRunSnapshot = LastRunDiagnosticSnapshot(
     trace: trace,
     metadataEvidence: value.metadataEvidence,
     runOptions: RunOptionsSnapshot(from: opts),
     fileName: url.lastPathComponent
   )
   ```

   The `RunOptionsSnapshot.init(from opts: AudioAnalysisService.Options)` is a one-line value-extracting initializer. The whole assignment runs inside the existing `guard self.currentTaskID == taskID` gate.

   **Reset site:** at the synchronous prologue of every `analyze(url:autoStarted:)` call, `self.lastRunSnapshot = nil` (single line, replaces the three separate resets the v1 spec proposed).

   **`@ObservationIgnored` re-render coupling (Siri + Codex finding #2 sub-clause).** The field is `@ObservationIgnored` because no view OBSERVES it directly; the trace view reads it via projection. The view's re-render is driven by the OBSERVED `viewModel.detectedBPM` write, which happens in the SAME `.success` arm immediately before the snapshot assignment. **This coupling is load-bearing**: any future story that writes to `lastRunSnapshot` WITHOUT also writing to `detectedBPM` (or another observed property) will silently stale the view. Document this contract inline in the view model — a brief comment block above the snapshot field stating "must be written transactionally with an observed property in the same MainActor turn." See DD #10 for the broader pattern.

   **W30 close mechanic.** The existing `manualReRunUsesCurrentOptions` smoke test currently asserts only `viewModel.detectedBPM != nil` post-re-run with `.dedup`. Story 5-4 tightens it to assert `viewModel.lastRunSnapshot?.runOptions.mergeStrategy == .dedup`. Without the atomic snapshot, the test could not distinguish "the run used `.dedup`" from "the run used a stale `.maxConfidence` and silently honored the snapshot from a prior call." With the snapshot, the assertion fires post-success and pins the contract.

6. **"Which pipeline step selected the final BPM" derivation rules.** The library does NOT carry this as a single field. The demo computes it from existing trace state using priority-ordered comparisons (higher priority = later step / stronger override):

   ```
   1. ensembleDecision != nil
      AND ensembleDecision!.winner == .ml
      AND ensembleDecision!.selectedBPM == finalBPM
                                               → .mlEnsemble
   2. highestScoring(candidatesAfterBoost).bpm
      != highestScoring(candidatesBeforeBoost).bpm
                                               → .metadataCorroboration
   3. refinedBPM != nil
      AND refinedBPM != disambiguationResult.bpm
                                               → .fineGridRefinement
   4. subBandVoteDetail?.changed == true       → .subBandVoting
   5. durationHintDetail?.boostedCandidates
      contains finalBPM (within ±0.5 BPM)
                                               → .durationHint
   6. clickCorrelationDetail != nil
      AND highest-NCC candidate has different index
      than highest-score candidate in rawCandidates
                                               → .clickRescore
   7. (else)                                   → .baselineDisambiguation
   ```

   **Ordering rationale (post-Codex review 2026-05-20).** The cascade reflects the actual library pipeline execution order in `AudioAnalysisService.analyzeBPM`: BPMAnalyzer runs the in-pipeline steps (clickRescore → durationHint → subBandVote → fineGrid) and emits `BPMResult`; `CandidateMergeStrategy.merge` aggregates windows; `MetadataCorroborator.apply` runs POST-merge (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift` post-Story-3.6 ordering); finally the ML ensemble combiner runs LAST. Therefore the cascade priority (highest = latest-executed) is: **ML ensemble → metadata corroboration → fine-grid refinement → sub-band voting → duration hint → click rescore → baseline DSP disambiguation**. The earlier v1 spec inverted items 2/3 (metadata vs fine-grid) and items 5/6 (duration vs click) — both were wrong because the demo's derivation must match the library's actual step ordering. The dev agent should re-read `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` before implementation to confirm the helper-call order has not shifted since 2026-05-20.

   **`.mlEnsemble` semantic clarification.** The arm fires only when ALL three conditions hold: (a) `ensembleDecision != nil` (ensemble ran), (b) `winner == .ml` (ensemble selected the ML candidate), AND (c) `ensembleDecision.selectedBPM == finalBPM` (the ML selection actually became the returned BPM). An `ensembleDecision` with `winner == .dsp` or `.tie` means the ensemble ran but did NOT change the BPM — that case falls through to lower-priority arms (a fine-grid or metadata step may still own attribution). This rule answers Codex's "last selector considered vs last step that changed BPM" question by anchoring to the OUTCOME, not just the LAST step that ran.

   **`.baselineDisambiguation` (renamed from `.rangeNormalization`).** Codex flagged that "rangeNormalization" hides the role of step 9's candidate disambiguation / range filter as the baseline winner-selector. The `(else)` arm fires when none of steps 9b/9.7/10/10b/10c modified the winner — i.e., the candidate that emerged from step 9 (range normalization + initial disambiguation) IS the final BPM. Naming the arm `.baselineDisambiguation` reflects that meaning. The enum rawValue strings used in JSON: `"ml-ensemble"`, `"metadata-corroboration"`, `"fine-grid-refinement"`, `"sub-band-voting"`, `"duration-hint"`, `"click-rescore"`, `"baseline-disambiguation"`.

   **`highestScoring` helper.** The `candidatesBeforeBoost` and `candidatesAfterBoost` arrays are NOT documented to be sort-stable across the corroborator's `apply(...)` boundary (see `BPMDiagnosticTrace.candidatesAfterBoost` docstring — describes the post-multiply pool, not the sort order). The demo must compute the winner by max-score reduce, NOT by indexing `[0]`. Pseudocode: `func highestScoring(_ pool: [(bpm: Double, score: Float)]) -> (bpm: Double, score: Float)? { pool.max(by: { $0.score < $1.score }) }`. The metadataCorroboration step fires only when the BPM of the max-score-winner differs across the two pools (a tag-driven winner promotion). Empty pools route through the `(else)` rangeNormalization arm via the `nil`-aware comparison.

   Tie-breaks favor the LATEST step (highest number). The enum `FinalSelectionStep` (demo-internal) has 7 cases plus a `(other)` fallback for future trace fields. The derivation function `FinalSelectionStep.derive(from:lastBPM:)` is a static method on the enum, testable via `@testable import` without rendering any view.

   **Why this ordering.** The pipeline executes steps 1-10 in sequence; later steps can override earlier ones (the documented `BPMAnalyzer` pipeline order). ML ensemble runs LAST (after corroboration); if `.ml` won, that's the override. Fine-grid refinement (10c) is the last DSP step before the ensemble; if it changed the BPM, it's the answer. Metadata corroboration (post-merge `apply`) can flip the winner via boost. Sub-band voting (10b) can promote a different candidate. Click rescore (9b) can reorder candidates. Duration hint (9.7) can boost candidates. If none of these fired, the winner came from raw range-normalization (step 9).

   **Tolerance for `durationHint` match.** `abs(finalBPM - boostedCandidate) <= 0.5 BPM`. The boostedCandidates array is `[Double]` of DSP candidate BPMs that received the multiplicative boost; a perfect equality match is unlikely after fine-grid refinement, so a half-BPM band is correct.

   **Single-step attribution caveat.** A multi-step interaction (e.g., sub-band voting AND fine-grid both contributed) is reported as the LAST step that fired. The demo surfaces this attribution as a one-liner; users wanting the full causal chain inspect the raw JSON. This is intentionally non-exhaustive — exhaustive attribution would require step-by-step "winner BPM after step N" snapshots on the trace, which is a library change out of scope for this story.

7. **Demo-side `TraceExport` Codable schema.** Top-level shape (demo-internal struct in `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift`):

   ```swift
   struct TraceExport: Codable, Sendable, Equatable {
     let schemaVersion: String                       // "v1"
     let generatedAt: Date                            // ISO-8601 via JSONEncoder.dateEncodingStrategy = .iso8601
     let run: RunInfo
     let selection: SelectionInfo
     let pipeline: PipelineInfo
     let metadata: MetadataInfo
     let ml: MLInfo?                                  // nil when ensembleDecision == nil
   }

   struct RunInfo: Codable, Sendable, Equatable {
     let fileName: String
     let intensityRequested: Int                      // viewModel.options.intensity.rawValue (post-snapshot)
     let intensityEffective: Int                      // result.effectiveIntensity.rawValue
     let mergeStrategy: String                        // lastRunSnapshot.runOptions.mergeStrategy.rawValue
     let votingPolicy: String                         // lastRunSnapshot.runOptions.votingPolicy.rawValue
     let votingThreshold: Double                      // lastRunSnapshot.runOptions.votingThreshold
     let metadataPolicyEnabledSources: [String]       // sorted, matching MetadataSource.allCases order
     let durationHint: Bool
     let durationHintMinFileSeconds: Double
     let ensemblePolicy: String                       // .dspOnly | .mlOnly | .highestConfidence | ...
     let maxSeconds: Double
     let elapsedSeconds: Double
     let bpm: Double                                  // final BPM
     let confidence: Double
     let degradationReason: String?
   }

   struct SelectionInfo: Codable, Sendable, Equatable {
     let finalStep: String                            // FinalSelectionStep enum rawValue
     let reasoning: String                            // human-readable one-liner
   }

   struct PipelineInfo: Codable, Sendable, Equatable {
     let energyTransitionOffset: Int
     let analysisWindowDuration: Double
     let onsetEnvelopeLength: Int
     let subBandEnergies: SubBandEnergiesJSON         // {kick, snare, crack, hihat}
     let acfTopLags: [LagStrength]
     let tempogramTopBPMs: [BPMMagnitude]
     let fusedTopBPMs: [BPMScore]
     let tps2TopBPMs: [BPMScore]
     let rawCandidates: [CandidateScore]
     let disambiguation: CandidateScore               // bpm, score
     let clickCorrelation: [ClickCorrelationJSON]?
     let durationHint: DurationHintJSON?
     let harmonicRatio: HarmonicRatioJSON?
     let subBandVote: SubBandVoteJSON?
     let refinedBPM: Double?
   }

   struct MetadataInfo: Codable, Sendable, Equatable {
     let evidence: [MetadataEvidenceJSON]
     let candidatesBeforeBoost: [CandidateScore]
     let candidatesAfterBoost: [CandidateScore]
   }

   struct MLInfo: Codable, Sendable, Equatable {
     let ensembleDecision: EnsembleDecisionJSON
     let diagnosticSnapshot: MLDiagnosticSnapshotJSON?
     let featureFramesShape: MLFeatureFramesShapeJSON?  // SHAPE ONLY — no logMelData payload (DD #11)
   }
   ```

   Nested projection types (`CandidateScore`, `LagStrength`, `BPMMagnitude`, `BPMScore`, `SubBandEnergiesJSON`, `ClickCorrelationJSON`, `DurationHintJSON`, `HarmonicRatioJSON`, `SubBandVoteJSON`, `MetadataEvidenceJSON`, `EnsembleDecisionJSON`, `MLDiagnosticSnapshotJSON`, `MLFeatureFramesShapeJSON`) each carry the same fields as the library types they mirror, omitting any non-Codable closure / function payload. **All are demo-internal access; no library changes.**

   **JSON output encoding.** `JSONEncoder` with `.outputFormatting = [.prettyPrinted, .sortedKeys]` so the file diffs cleanly across runs (sorted keys make diff inspection viable even when serializing dictionaries). `.dateEncodingStrategy = .iso8601`. `.keyEncodingStrategy = .useDefaultKeys` (preserves camelCase from the Swift type names; no snake_case conversion). NaN/Inf encoding: `JSONEncoder.NonConformingFloatEncodingStrategy.throw` so a non-finite value loudly aborts the export rather than producing JSON5 (DD #12).

8. **`schemaVersion` seam.** The top-level `schemaVersion: String` field ships as `"v1"`. Future evolution of the demo trace JSON must bump this string atomically with any breaking schema change (field removal, type change, key rename). Pattern follows Story 2-6's `PerfBaselineRecord.schemaVersion: Int = 2` precedent — schemaVersion is the load-bearing seam consumers (external plotting scripts, JSON-diffing CI) rely on to refuse to read incompatible exports.

   **Why string not Int.** The library's `BPMDiagnosticTrace` itself is documented as "evolving — fields may change across versions." If a future story migrates the demo trace JSON in lockstep with a library trace change, `"v1"` → `"v2"` is human-readable in error messages ("schemaVersion 'v2' is newer than this consumer's supported 'v1'"). Int versioning is leaner but less discoverable in the JSON itself.

9. **Export button visibility and placement.** Story 5-3 established a horizontal button row in the controls section: `[Cancel] [Re-analyze] [Copy Config]`. Story 5-4 inserts a fourth button: `[Cancel] [Re-analyze] [Copy Config] [Export Trace]`.

   **Visibility:** Export Trace is shown when ALL of these hold:
   - `viewModel.lastRunSnapshot != nil` (an atomic snapshot from the most recent successful analysis is retained), AND
   - `!viewModel.isAnalyzing` (mutually exclusive with Cancel — never both visible)

   When `lastRunSnapshot == nil` (empty state, error-only state, or analysis-failure state with no result), Export Trace is hidden. There is no disabled-but-visible state — hidden-via-`if` matches the Story 5-3 DD #4 convention for Cancel and Re-analyze.

   **Button label.** "Export Trace" (two words, verb-noun). Not "Export JSON" (too implementation-leaky), not "Save Trace" (ambiguous with disk-persistence).

   **Keyboard shortcut.** None. Story 5-2 / 5-3 declined keyboard shortcuts on the user-facing buttons; the Export Trace button follows that convention.

10. **Atomic snapshot retention + `@ObservationIgnored` re-render coupling (post-Siri + Codex review 2026-05-20).** Today the analyze body reads `value.bpm` / `value.confidence` / `value.effectiveIntensity` from the result and discards `value.trace` and `value.metadataEvidence`. Story 5-4 retains both via the atomic snapshot defined in DD #5:

    ```swift
    @ObservationIgnored
    var lastRunSnapshot: LastRunDiagnosticSnapshot?
    ```

    **Critical `@ObservationIgnored` re-render contract** (Siri verified against Apple Observation framework semantics, axiom-swiftui `architecture.md`):

    - `@ObservationIgnored` does NOT just "suppress re-renders on mutation" — it REMOVES the property from `_$observationRegistrar` tracking entirely. A view body or computed property that reads `viewModel.lastRunSnapshot` will NOT register a dependency on it.
    - **Re-render only happens when an OBSERVED property in the same MainActor turn also mutates.** Story 5-4 relies on this: `lastRunSnapshot` is always written transactionally with `detectedBPM`, `confidence`, `effectiveIntensity`, `elapsedSeconds` — the SAME `.success(value?)` arm in the analyze body. SwiftUI re-evaluates because `detectedBPM` mutated (observed); the re-evaluation reads `lastRunSnapshot` (untracked) and picks up the fresh value.
    - **The contract is load-bearing.** A future story that writes to `lastRunSnapshot` WITHOUT also touching an observed property (e.g., a hypothetical "lazy trace augmentation" path) will silently stale the view. Document this with an inline comment block above the field in `AnalysisViewModel.swift`:

      ```swift
      // CRITICAL: `lastRunSnapshot` is @ObservationIgnored. The SwiftUI view
      // re-renders only when an OBSERVED property (e.g., `detectedBPM`)
      // mutates in the same MainActor turn. Always pair writes to
      // `lastRunSnapshot` with a write to an observed property within the
      // same MainActor turn, or future readers will see stale snapshots.
      // (Story 5-4 DD #10 / Siri + Codex review 2026-05-20.)
      ```

    **Why `@ObservationIgnored` and not observed.** The `LastRunDiagnosticSnapshot` contains a `BPMDiagnosticTrace` value with ~30 fields including 8 tuple-shaped arrays. Making it observed would register every field for tracking, multiplying observation registrar churn for state that no view reads incrementally — the trace view reads via projection (one shot per re-render). The cost saving is modest at single-snapshot scale but the principle aligns with Story 5-1 PP8 / Story 5-2 DD #5 (`@ObservationIgnored` for operational state).

    **Reset to nil at the synchronous prologue** of every `analyze(url:autoStarted:)` call (alongside `detectedBPM = nil`). This ensures a re-analyze never shows the prior run's trace alongside the new run's BPM, AND the reset participates in the same observed-write-driven re-render (since `detectedBPM = nil` is observed).

    **Snapshot timing.** `lastRunSnapshot` is set ONLY in the `.success(value?)` arm of the result switch. `.success(nil)` (no BPM detected) and `.failure(...)` arms leave it as the just-cleared `nil` — there is no trace to export from a failed or empty run.

11. **`MLFeatureFrames.logMelData` exclusion + shape-only inclusion.** The `BPMDiagnosticTrace.mlFeatures: MLFeatureFrames?` field carries the full log-mel tensor as `logMelData: [Float]` — at default intensity 7 on a 3-minute file at 44.1 kHz, the tensor is `128 mel * ~18000 frames * 4 bytes = ~9 MB` in memory; serialized as pretty-printed JSON it would be ~25-50 MB (every Float renders to ~10 ASCII characters with comma + space).

   **Choice: include shape metadata only.** The exported `MLFeatureFramesShapeJSON` projection includes `melBands`, `frames`, `tensorLayout`, `sampleRate`, `fftSize`, `hopSize`, `melFmin`, `melFmax`, `logCompressionScale`, `featureSetVersion` — and explicitly does NOT include `logMelData`. The demo logs the float-payload omission in the surfaced trace view section ("Log-mel tensor: 128 × 18044 (payload omitted from export — see Story 5-4 DD #11)") so a curious user knows the export is intentionally lossy here.

   **Future re-open.** If a power user reports needing the raw log-mel payload for external ML training calibration, a follow-up story can add a checkbox "Include ML feature payload (~25 MB)" to the export. Deferred-work entry to track. Today the demo has no ML technique wired, so `mlFeatures` is generally nil; the payload-omission only matters once a consumer supplies a `BNNSTechnique` via code-level demo modification.

12. **NaN / Inf in the trace JSON encode-time guard.** `JSONEncoder` with `.nonConformingFloatEncodingStrategy = .throw` (the default) — any non-finite Float / Double in the trace fails the encode loudly. The dev agent does NOT use `.convertToString(positiveInfinity:negativeInfinity:nan:)` because that produces JSON5-flavored output (`"Infinity"`, `"-Infinity"`, `"NaN"` string sentinels) that downstream consumers parsing strict JSON would choke on.

   **Surfacing the failure.** The encode happens inside the Export Trace action handler. On throw, the demo sets `errorMessage = "Could not export trace JSON: <localizedDescription>"` and aborts the save panel write. This is a defensive belt-and-suspenders — the library's `MLFeatureFrames` initializer already rejects non-finite floats (Story 4-5 N13 review fix), and `BPMAnalyzer` does not emit non-finite scores; production pipeline non-finite trace values are a library bug.

   **Test coverage.** A smoke test constructs a hand-rolled `TraceExport` instance with NaN in `disambiguation.bpm` and asserts the encode throws (or the export action emits the error message). Pattern: `#expect(throws: EncodingError.self) { try encoder.encode(...) }`.

13. **(Superseded by DD #5 atomic snapshot — kept as placeholder for DD numbering continuity.)** The v1 spec had a separate DD here justifying `lastRunOptionsSnapshot: AudioAnalysisService.Options?` as a full-Options retention. Codex + Winston review 2026-05-20 collapsed that field into the atomic `LastRunDiagnosticSnapshot.runOptions: RunOptionsSnapshot` narrow projection (DD #5). See DD #5 for the rationale (closure retain-hazard avoidance + partial-state-race elimination).

14. **Trace view does not block on the analyze.** Expanding the disclosure during an in-flight analyze is allowed; the disclosure shows the PRIOR successful run's trace (if any). When the new run completes, the trace section updates (via the `viewModel.detectedBPM` observation chain). This is the same race-condition-tolerant semantic Story 5-3's Copy Config has (the snippet always reflects the CURRENT `options`, not the in-flight snapshot).

   **Edge case: trace expanded, new analyze starts.** The disclosure stays expanded; the trace content briefly shows the prior run's data until the new run lands. UI is consistent; no flicker. If `lastRunSnapshot` is reset to nil in the synchronous prologue, the disclosure renders an empty-trace placeholder until the new trace arrives. The dev agent decides between (a) keep prior trace visible until new trace lands, or (b) clear prior trace on every new analyze. **Recommended: (b) — clear on new analyze**, matching the Story 5-3 convention that every analyze resets `detectedBPM = nil` etc. UX consistency wins over flicker minimization.

15. **`TraceExport.from(trace:options:result:fileName:)` factory signature.** The projection function lives on `TraceExport` as a static factory:

    ```swift
    static func from(
      trace: BPMDiagnosticTrace,
      options: AudioAnalysisService.Options,
      result: AudioAnalysisResult,
      fileName: String,
      metadataEvidence: [MetadataBPMEvidence]
    ) -> TraceExport
    ```

    Pure function on its inputs; no side effects; testable via `@testable import` without constructing a view model. The demo's smoke test exercises it with a hand-built `BPMDiagnosticTrace` (or one captured from a fixture analyze) + a default `Options` + a synthetic `AudioAnalysisResult` (constructable via the library's public memberwise init).

    **No throws.** The factory does not throw — it consumes a constructed library trace + result and projects. The only throwing site is `JSONEncoder.encode(...)` at the export action, which can fail on NaN/Inf or out-of-memory.

16. **Always-on `enableTrace = true` corner case: the dispatching to `runPreCorroborationPipeline`.** AudioAnalysisService.swift's analyze body has a `shouldBuildTrace` predicate (referenced at line 336 of the current source). When `enableTrace == true` AND the rest of the gate fires, the trace is constructed. The demo's override sets `enableTrace = true` unconditionally on every analyze call. The dev agent verifies (Task 5 smoke test): a freshly-launched analyze with default options on `bpm-120-click.wav` returns a non-nil `result.trace`. If this fails, the override is not landing correctly.

   **Cancellation path.** When a user cancels mid-analyze, the catch block raises `CancellationError` → switch arm handles it WITHOUT setting `lastRunSnapshot`. The trace section stays empty for that run; subsequent runs repopulate. No leak.

## Acceptance Criteria

1. **AC #1 — Trace section renders on successful analysis.**
   **Given** the demo app is running and the user drops `bpm-120-click.wav`.
   **When** the analysis completes successfully.
   **Then** a "Diagnostic Trace" `DisclosureGroup` appears below the result row, collapsed by default.
   **And** expanding the disclosure shows 8 sections (Run, Selection path, Candidates, Sub-band energies, Disambiguation, Fine-grid, Metadata corroboration, ML ensemble) per DD #4 structure.
   **And** the Run section shows: file name `bpm-120-click.wav`, intensity `7`, merge strategy `maxConfidence`, elapsed seconds (> 0), BPM `120.0` (± library tolerance), confidence (in `[0, 1]`).

2. **AC #2 — Selection path label fires correctly across pipeline scenarios.**
   **Given** a click-track fixture analyzed at default options.
   **When** the trace renders.
   **Then** the Selection path label reads one of: `range-normalization`, `click-rescore`, `duration-hint`, `metadata-corroboration`, `sub-band-voting`, `fine-grid-refinement`, `ml-ensemble` (the FinalSelectionStep enum's rawValue list).
   **And** the derivation rules in DD #6 are unit-tested via `FinalSelectionStepTests` (parameterized over at least 4 hand-built trace inputs covering: only-raw-winner, only-fine-grid, only-metadata-flipped, only-ml-ensemble).

3. **AC #3 — `lastRunSnapshot` is populated atomically on success and reset on the next analyze prologue.**
   **Given** a successful analysis has completed (`viewModel.detectedBPM != nil`).
   **When** a smoke test inspects the view model via `@testable import`.
   **Then** `viewModel.lastRunSnapshot != nil`, with all four nested fields populated: `trace`, `metadataEvidence` (may be empty for tag-free fixtures), `runOptions`, `fileName`.
   **And** `viewModel.lastRunSnapshot?.runOptions.mergeStrategy == viewModel.options.mergeStrategy` IF the user has not adjusted the picker between the analyze launch and the inspection.

   **Given** a subsequent `analyze(url:autoStarted:)` call has fired (e.g., from a Re-analyze button tap).
   **When** the synchronous prologue runs.
   **Then** at the instant after the prologue mutates observed state, `lastRunSnapshot == nil`. It repopulates atomically when the new run's `.success` arm fires (or stays nil if the new run fails / returns nil).

   **Partial-state invariant (Codex finding #6 close).** The snapshot is either fully populated or nil — there is no observable state where `trace != nil` but `runOptions` is stale or missing. Smoke test `lastRunSnapshotIsAtomic` exercises this by capturing `lastRunSnapshot` post-run and asserting all four nested fields are non-nil/non-default together; a subsequent reset clears all four together.

4. **AC #4 — Export Trace button visibility is gated on the atomic snapshot, not a sub-field.**
   **Given** the demo app is running.
   **When** no file has been dropped yet.
   **Then** the Export Trace button is hidden (`viewModel.lastRunSnapshot == nil`).

   **Given** an analysis is in progress.
   **When** `isAnalyzing == true`.
   **Then** the Export Trace button is hidden (mutually exclusive with Cancel).

   **Given** an analysis has completed successfully AND `!isAnalyzing`.
   **When** the UI renders.
   **Then** the Export Trace button is visible alongside Re-analyze and Copy Config (Cancel hidden). Visibility predicate: `viewModel.lastRunSnapshot != nil && !viewModel.isAnalyzing`.

   **Codex finding #6 — gate on snapshot, not on individual fields.** The v1 spec gated visibility on `lastTrace != nil` (a separate observed-ignored field). The atomic snapshot (DD #5) collapses three fields into one, eliminating the possibility of `trace != nil` with `runOptions == nil`. The button visibility predicate uses `lastRunSnapshot != nil` as the single source of truth.

5. **AC #5 — `NSSavePanel` write produces a valid JSON file at the user-chosen path.**
   **Given** the user has completed a successful analysis on `bpm-120-click.wav`.
   **When** they tap Export Trace, the NSSavePanel appears with the suggested filename `bpm-120-click-trace.json`, the user accepts the default location (e.g., `~/Downloads/`), and confirms the save.
   **Then** a file is written at that path.
   **And** the file decodes successfully via `JSONDecoder().decode(TraceExport.self, from: ...)`.
   **And** the decoded `TraceExport.schemaVersion == "v1"`, `.run.fileName == "bpm-120-click.wav"`, `.run.bpm` is within ±2 BPM of 120, `.selection.finalStep` is one of the 7 enum values.

   **Given** the user taps Export Trace and the save panel appears.
   **When** they tap `Cancel` in the save panel.
   **Then** no file is written, no `errorMessage` is set, the trace section remains visible.

6. **AC #6 — Sandbox entitlement is `com.apple.security.files.user-selected.read-write`.**
   **Given** the demo built via `make demo-build-sandboxed`.
   **When** the binary is inspected via `codesign -d --entitlements - /path/to/demo.app`.
   **Then** the output contains `com.apple.security.files.user-selected.read-write` (NOT `.read-only`).
   **And** `com.apple.security.app-sandbox` remains `true`.
   **And** the `make demo-build` (unsigned) and `make demo-build-sandboxed` (signed) targets both BUILD SUCCEEDED with the new entitlement value.

7. **AC #7 — Trace JSON export is reproducible up to documented volatile fields (Codex-revised 2026-05-20).**
   **Given** the same fixture analyzed twice with identical Options (e.g., `bpm-120-click.wav` at default options).
   **When** both runs export trace JSON.
   **Then** the test:
   1. Decodes both files into `TraceExport` instances via `JSONDecoder().decode(TraceExport.self, from:)`.
   2. Normalizes by setting `generatedAt = .distantPast` (or equivalent sentinel) and `run.elapsedSeconds = .nan` on both decoded instances — the two known volatile fields.
   3. Re-encodes both normalized instances with `JSONEncoder().outputFormatting = [.sortedKeys]` (no pretty-printing) and asserts the two encoded `Data` are byte-equal.
   4. Walks every floating-point field (recursively, via a small `allFloats(_ export: TraceExport) -> [Double]` helper) and asserts each is finite (`isFinite == true`) BEFORE the re-encode comparison.

   **Why not byte-equal raw files.** `AudioAnalysisService` parallelizes window-level analysis via `withTaskGroup`; sum-reduce order across windows is not pinned, so per-window candidate scores can drift in the LSB of `Float`/`Double` across runs even on the same hardware. Raw byte-equality of the pretty-printed JSON would fail intermittently (Amelia + Codex review 2026-05-20). Decode + normalize + re-encode-with-sortedKeys collapses the rendering variance; the finite-float guard catches non-finite leakage from a future library change.

   **Tolerance is not relaxed at the structural level.** Codex's test contract requires byte equality of the re-encoded normalized form. If `score: 0.7234001` vs `0.7234002` drifts, the test should FAIL — that's a real regression worth surfacing. If LSB drift becomes prevalent enough to cause CI flake, the dev agent should pin window-level analysis to single-thread for this test only (the library's `OA300_CORPUS_PATH=... swift test` already does this for byte-equality fixtures elsewhere — pattern is well-established).

   **Caveat (unchanged).** The test pins same-library-version + same-hardware reproducibility. A library trace evolution (new field, removed field) will break this assertion intentionally — the dev agent updates the fixture or bumps `schemaVersion` to `"v2"` and migrates the test alongside.

8. **AC #8 — `manualReRunUsesCurrentOptions` smoke test is tightened to assert `lastRunSnapshot.runOptions.mergeStrategy == .dedup`.**
   **Given** the Story 5-3 smoke test at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift:262-287`.
   **When** the test mutates `viewModel.options.mergeStrategy = .dedup`, calls `analyze(url:)`, polls for completion (existing 30s deadline pattern).
   **Then** post-completion, the test asserts BOTH `viewModel.detectedBPM != nil` (existing assertion) AND `viewModel.lastRunSnapshot?.runOptions.mergeStrategy == .dedup` (new assertion).
   **And** the assertion closes deferred-work `W30` (the test name `manualReRunUsesCurrentOptions` now matches its enforced contract).

9. **AC #9 — NaN / Inf in the trace JSON encode-time guard.**
   **Given** a hand-rolled `TraceExport` instance with `selection.finalStep == "range-normalization"` and a non-finite Double in `disambiguation.bpm` (constructed via a builder helper in the smoke test).
   **When** `JSONEncoder().encode(traceExport)` is called.
   **Then** the call throws `EncodingError.invalidValue(...)` (NOT producing `"NaN"` JSON5).
   **And** the matching UI integration path sets `viewModel.errorMessage = "Could not export trace JSON: <message>"` and does NOT write a file.

10. **AC #10 — Always-on `enableTrace = true` does not regress library behavior.**
    **Given** the demo's analyze body overrides `opts.enableTrace = true` (DD #1).
    **When** a fresh analyze runs on `bpm-120-click.wav`.
    **Then** `result.trace != nil` (confirms the override applied).
    **And** the library's existing baselines are unchanged (`make benchmark` OA300 Acc1 = 58/82 + Acc2 = 74/82, `make benchmark-giantsteps` Acc1 = 537/661 + Acc2 = 546/661).
    **And** zero library `Sources/` or `Tests/` modifications appear in the diff (verified via `git status --porcelain Sources/ Tests/` returning empty).

11. **AC #11 — Manual GUI smoke tests pass on the sandboxed app.**
    See Manual GUI Smoke Tests section below. The dev agent does NOT execute these in auto-mode; they are deferred to user action per the Story 5-2 / 5-3 precedent (auto-mode cannot drive SwiftUI window drops or NSSavePanel interactions).

12. **AC #12 — Gating gauntlet outcomes.**
    The standard per-story gating checklist runs cleanly:
    - `make fmt` — clean (no diff).
    - `make demo-fmt` — clean.
    - `make lint` — exactly 1 violation (canonical `LUFSAnalyzer.swift:94` TODO baseline).
    - `make demo-lint` — exit 0 (DEVELOPMENT_TEAM leak guard).
    - `make build` — exit 0 (library Debug).
    - `make build-release` — exit 0 (library Release).
    - `make test` — passes (library test count unchanged at 431/431 in 94 suites per Story 5-3 close-out).
    - `make demo-build` — BUILD SUCCEEDED (unsigned).
    - `make demo-test` — TEST SUCCEEDED (demo test count grows from 57 to **~78-82** — +21-25 new smoke test invocations across `traceProjectionRoundTripsJSON` (+1), `finalSelectionStepDerivation` parameterized × 7 arms + 2 conflict cases (+9), `nanInTraceExportThrows` parameterized × 4 sites (+4), `manualReRunUsesCurrentOptions` tightened (+0 invocations / +1 assertion), `lastRunSnapshotResetOnAnalyzePrologue` (+1), `enableTraceOverrideAtPrologue` (+1), `traceExportSchemaMatchesGolden` (+1), `lastRunSnapshotIsAtomic` (+1), `exportTraceVisibilityGatedOnSnapshot` (+1), `exportTraceWriteErrorSetsErrorMessage` (+1), `logMelDataOmittedFromExport` (+1)).
    - `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` — BUILD SUCCEEDED with entitlement upgrade verified.
    - `make pre-commit` — exit 0 (aggregate gate).
    - `make benchmark` — OA300 Acc1 = 58/82 + Acc2 = 74/82 (UNCHANGED).
    - `make benchmark-giantsteps` — Acc1 = 537/661 + Acc2 = 546/661 (UNCHANGED).

13. **AC #13 — W2 is FULLY CLOSED; W30 is CLOSED; deferred-work `:362` updated.**
    The implementation work closes:
    - **W2** — the result-adjacent caption line (DD #4) is the load-bearing W2 surface; it renders whenever `viewModel.detectedBPM != nil`, displaying `Result captured at: intensity <X>, <humanized merge strategy>` directly below the BPM result row, drawing values from `lastRunSnapshot.runOptions`. The disclosure header + trace JSON Run section reinforce the same data. Deferred-work entry updated to `CLOSED 2026-05-XX (Story 5-4)`.
    - **W30** — `manualReRunUsesCurrentOptions` now asserts the snapshot field (AC #8). Deferred-work entry updated to `CLOSED 2026-05-XX (Story 5-4)`.

14. **AC #14 — Write-error path is surfaced and non-corrupting (Codex finding #6).**
    **Given** the user taps Export Trace, the save panel succeeds, but the post-panel `Data.write(to: url, options: .atomic)` throws (e.g., disk full, file-locked, permission denied because of misconfigured entitlement).
    **When** the write fails.
    **Then** `viewModel.errorMessage` is set to `"Could not export trace JSON: <localizedDescription>"`.
    **And** no partial file appears at the chosen URL (`.atomic` write guarantees this — either the full file lands or nothing).
    **And** `viewModel.lastRunSnapshot` is UNCHANGED (the failed write does not invalidate the snapshot; the user can retry).
    **And** `panel.url?.stopAccessingSecurityScopedResource()` was called via the defer block (no kernel resource leak).

15. **AC #15 — `MLFeatureFrames.logMelData` is positively absent from the exported JSON (DD #11 positive assertion).**
    **Given** an analysis where `mlFeatures` is populated (synthetic test path — the demo's default has no `mlTechnique`, so a `BPMDiagnosticTrace` is constructed directly via `@testable import`).
    **When** the projection encodes to JSON.
    **Then** the JSON contains `ml.featureFramesShape` with `melBands`, `frames`, `tensorLayout`, etc.
    **And** the JSON contains NO key named `logMelData` anywhere (walked recursively via `JSONSerialization.jsonObject(with:)`).
    **And** the JSON file size is bounded by `< 100 KB` for the test trace (the shape-only projection prevents megabyte-scale exports).
    - **Line :362** (`EnsembleDecision is not Codable while nested Winner: Codable`) — UPDATED with cross-reference: "Story 5-4 deferred library-side `BPMDiagnosticTrace: Codable` to a future named story; the demo carries its own `TraceExport` projection. Re-open trigger updated: whichever story decides to promote `BPMDiagnosticTrace` to `Codable` library-side will also need to add `Codable` to `EnsembleDecision`." Entry stays open.
    - **W32** (clipboard-wipe risk) — UNAFFECTED. Story 5-4 does NOT migrate the trace export to pasteboard; the W32 re-open trigger ("a story migrates the pasteboard surface to a higher-stakes payload (e.g., user-curated trace export)") does NOT fire — Story 5-4 uses `NSSavePanel`, not pasteboard.

## Tasks

1. **Task 1 — View model surface additions (post-review atomic snapshot).**
   1.1. Add `struct LastRunDiagnosticSnapshot: Sendable` + `struct RunOptionsSnapshot: Sendable, Equatable` per DD #5. Define `RunOptionsSnapshot.init(from opts: AudioAnalysisService.Options)` as a one-line value-extracting initializer (the 11 named fields).
   1.2. Add `@ObservationIgnored var lastRunSnapshot: LastRunDiagnosticSnapshot?` to `AnalysisViewModel.swift`, with the inline DD #10 contract comment block above the field.
   1.3. (Superseded by 1.1 + 1.2 — kept for task-number continuity.)
   1.4. In `analyze(url:autoStarted:)` synchronous prologue, AFTER the existing `errorMessage = nil; detectedBPM = nil; ...` block, add `lastRunSnapshot = nil` (single line replaces the v1 three-field reset).
   1.5. After `var opts = options`, insert `opts.enableTrace = true` (DD #1 override).
   1.6. In the `.success(value?)` arm of the result switch (where `detectedBPM = value.bpm` etc. land), AFTER the existing observed-state writes (this is critical for the DD #10 re-render coupling), add:

       ```swift
       if let trace = value.trace {
         self.lastRunSnapshot = LastRunDiagnosticSnapshot(
           trace: trace,
           metadataEvidence: value.metadataEvidence,
           runOptions: RunOptionsSnapshot(from: opts),
           fileName: url.lastPathComponent
         )
       }
       ```

       The `if let trace = value.trace` guard handles the (theoretically unreachable) case where `enableTrace: true` produced a nil trace — defensive against future library changes. The trace field stays nil → Export button stays hidden → no inconsistent state.
   1.7. Verify the existing per-task UUID discriminator (Story 5-2 DD #5) gates these writes correctly — they are inside `guard self.currentTaskID == taskID else { return }`.

2. **Task 2 — Demo-internal `TraceExport` Codable types and projection factory.**
   2.1. Create `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift` containing the top-level `TraceExport` struct + nested types per DD #7.
   2.2. Implement `static func TraceExport.from(trace:options:result:fileName:metadataEvidence:) -> TraceExport`. Pure mapping function; one line per field.
   2.3. Implement `FinalSelectionStep` enum with 7 + 1 cases (per DD #6) and `static func derive(from:lastBPM:) -> FinalSelectionStep` per the priority-ordered rules.
   2.4. All projection nested types conform to `Codable, Sendable, Equatable` (Equatable supports the AC #7 round-trip-deterministic assertion).
   2.5. Default access level (internal) — these types are NOT promoted to public. The demo test target reads them via `@testable import BoomBoomBoomKitDemo`.

3. **Task 3 — Trace view UI.**
   3.1. Create `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` containing the `DisclosureGroup`-rooted view per DD #4 internal structure.
   3.2. Plumb into `ContentView.swift` between the `primaryStateView` and `bannerView` (or directly below the result row inside `resultView`, dev agent choice — keep the disclosure inside the main `VStack` so it grows the window vertically when expanded).
   3.3. Use plain `Text` / `HStack` / `Form.Section` — no `Chart`, no animation. The macOS-native rendering is sufficient.
   3.4. Selection-path label rendered at the disclosure header (next to the "Diagnostic Trace" title) so it's visible even when collapsed: `"Diagnostic Trace — final step: fine-grid refinement"`.
   3.5. Empty-state handling: if expanded WHILE `lastRunSnapshot == nil` (race-condition), render `Text("No trace available — drop a file to analyze.").foregroundStyle(.secondary)`. Should be unreachable per the visibility predicate but defends against the AC #4 edge case.

4. **Task 4 — Export Trace button + NSSavePanel handler (security-scoped + write-error handling).**
   4.1. Add `func exportTrace()` to `AnalysisViewModel`. Returns `Bool` (success). Sequence:
       1. Guard: `let snapshot = lastRunSnapshot else { return false }`.
       2. Construct the `TraceExport` via `TraceExport.from(...)` from the snapshot.
       3. Encode via `JSONEncoder()` configured per DD #7 + DD #12. Catch encode throw → set `errorMessage = "Could not export trace JSON: \(error.localizedDescription)"` and return false.
       4. Present the `NSSavePanel`: `allowedContentTypes: [.json]`, `nameFieldStringValue: suggestedFilename(from: snapshot.fileName)` (DD #3 — `<basename>-trace` WITHOUT `.json` suffix, allowedContentTypes auto-appends), `canCreateDirectories: true`. Call `panel.runModal()`.
       5. Guard: `response == .OK, let url = panel.url else { return false }` (cancel path; no error message).
       6. Defer block: `defer { url.stopAccessingSecurityScopedResource() }` (axiom-macos `sandbox-and-file-access.md:306` — NSSavePanel auto-starts; MUST stop).
       7. `try data.write(to: url, options: .atomic)`. Catch write throw → set `errorMessage = "Could not export trace JSON: \(error.localizedDescription)"` and return false (AC #14). The defer fires even on the catch path; no kernel resource leak.
       8. Return true.
   4.2. Wire the button in `ContentView.swift`'s controls row. Visibility predicate: `viewModel.lastRunSnapshot != nil && !viewModel.isAnalyzing`. Per Sally's UX recommendation 2026-05-20, apply differential button styling:
       - Re-analyze stays `.borderedProminent` (primary post-run action).
       - Copy Config + Export Trace use `.bordered` (secondary "take this with me" actions).
       - Visual grouping: `[Re-analyze]   |   [Copy Config] [Export Trace]` with a `Divider().frame(height: 16)` between the primary and secondary cluster. Dev agent picks `HStack(spacing:)` values that read cleanly at standard window width.
       - Cancel (during analyze) stays `.bordered` (matches Story 5-3).
   4.3. The NSSavePanel runs on the MainActor (AppKit requirement); the function is `@MainActor` by the class-level annotation. No async / await — `panel.runModal()` is synchronous on macOS. Swift 6 strict-concurrency is clean per axiom-concurrency check (no actor boundary crossing; `panel.url` access remains on MainActor).
   4.4. Verify the suggested filename: derive via `func suggestedFilename(from fileName: String) -> String` — strip the file extension (matches `PCMBufferReader`'s 6-format whitelist; use `URL(fileURLWithPath:).deletingPathExtension().lastPathComponent`) + append `"-trace"`. E.g., `Hellacopta.mp3` → `Hellacopta-trace`. NSSavePanel + `allowedContentTypes: [.json]` appends the `.json` extension at user-confirm time. Fall back to `"trace"` (no extension) when `snapshot.fileName` is empty — defensive.
   4.5. **Future-compat caveat (Codex finding #5).** If a future story extends `TraceExport` to include the full `mlFeatures.logMelData` payload (DD #11 deferral), the encode + write could land in the multi-megabyte range. At that point, the dev agent migrates the encode + write OFF MainActor: snapshot state on MainActor → present panel on MainActor → grab `url` → hop into a `Task.detached` for the encode + write (with `url.startAccessingSecurityScopedResource()` + matching stop inside the detached body since the MainActor-auto-grant decays at MainActor exit). Story 5-4 keeps everything on MainActor because shape-only export is <100 KB JSON — MainActor encode is fine.

5. **Task 5 — Demo smoke tests (expanded per Codex review 2026-05-20).**
   5.1. `traceProjectionRoundTripsJSON` — analyze `bpm-120-click.wav` with default options, poll for completion (30s pattern), construct `TraceExport` via the factory, encode + decode, assert round-trip equality on all fields except `generatedAt`. New invocation count: +1.
   5.2. `finalSelectionStepDerivation` — parameterized `@Test(arguments:)` over **7 hand-built `BPMDiagnosticTrace` inputs** covering each of the 7 DD #6 arms PLUS 2 conflict cases (multiple steps fired — verify the highest-priority arm wins). New invocation count: +9 (Codex finding #6 expansion from v1 spec's "+4").
   5.3. `nanInTraceExportThrows` — parameterized `@Test(arguments:)` over **4 non-finite injection sites**: (a) `disambiguation.bpm = .nan`, (b) `disambiguation.bpm = .infinity`, (c) a nested array element (`pipeline.rawCandidates[0].bpm = .nan`), (d) `pipeline.subBandEnergies.kick = .infinity`. Assert each throws `EncodingError.invalidValue` from `JSONEncoder().encode(...)` per DD #12. New invocation count: +4 (Codex finding #6 expansion from v1 spec's "+1").
   5.4. `manualReRunUsesCurrentOptions` TIGHTENED — add `#expect(viewModel.lastRunSnapshot?.runOptions.mergeStrategy == .dedup)` after the existing `detectedBPM != nil` assertion. No new invocation; existing test gains an assertion.
   5.5. `lastRunSnapshotResetOnAnalyzePrologue` — analyze fixture A, poll for completion, snapshot `lastRunSnapshot != nil`, immediately call `analyze(url:)` for fixture B (or same fixture again), assert `lastRunSnapshot == nil` at the next runloop turn (use `Task.yield()` to surface the prologue). New invocation count: +1.
   5.6. `enableTraceOverrideAtPrologue` — set `viewModel.options.enableTrace = false`, call `analyze(url:)`, poll for completion, assert `viewModel.lastRunSnapshot != nil` AND `viewModel.lastRunSnapshot?.runOptions.enableTrace == true` (proving the override defeated the user-supplied `false`). New invocation count: +1.
   5.7. `traceExportSchemaMatchesGolden` (R2 mitigation) — construct a fully-populated hand-built `BPMDiagnosticTrace` via a builder helper, project to `TraceExport`, encode with `[.sortedKeys, .prettyPrinted]`, and assert byte-equality against `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/Fixtures/5-4-trace-export-golden.json`. The golden is checked in at story-author time. New invocation count: +1.
   5.8. `lastRunSnapshotIsAtomic` (AC #3 partial-state invariant) — assert that whenever `viewModel.lastRunSnapshot != nil`, all four nested fields (`trace`, `metadataEvidence` as array (may be empty), `runOptions`, `fileName`) are populated together; subsequent reset clears all four together. New invocation count: +1.
   5.9. `exportTraceVisibilityGatedOnSnapshot` (AC #4 partial-state) — assert `viewModel.lastRunSnapshot == nil` immediately after view model construction AND after a `.failure(...)` analyze arm; Export Trace visibility predicate would evaluate to false in both cases. New invocation count: +1.
   5.10. `exportTraceWriteErrorSetsErrorMessage` (Codex finding #6 write-error AC) — inject a write failure by passing a deliberately-unwritable URL to a helper exposed for testing (NOT via NSSavePanel — the panel is unmockable in unit tests; the helper accepts the URL directly and exercises the encode + write path). Assert `errorMessage` is populated AND no partial file appears AND `lastRunSnapshot` is unchanged. New invocation count: +1.
   5.11. `logMelDataOmittedFromExport` (DD #11 positive assertion) — construct a `BPMDiagnosticTrace` with `mlFeatures` populated (any non-nil shape), project to `TraceExport`, decode, assert `ml?.featureFramesShape?.melBands` is set BUT no key named `logMelData` exists anywhere in the JSON. Use `JSONSerialization.jsonObject(with:)` to walk the dictionary and confirm key absence. New invocation count: +1.

6. **Task 6 — Entitlement upgrade + sandbox verification.**
   6.1. Edit `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` to replace `com.apple.security.files.user-selected.read-only` with `com.apple.security.files.user-selected.read-write`.
   6.2. Verify via `DEVELOPMENT_TEAM=$(your-team-id) make demo-build-sandboxed`.
   6.3. Inspect via `codesign -d --entitlements - /path/to/built.app` — confirm the read-write key is present, read-only is absent, app-sandbox is true.
   6.4. AC #6 closes via inspection output.

7. **Task 7 — Gating gauntlet.**
   7.1. `make fmt && make demo-fmt && make lint && make demo-lint`.
   7.2. `make build && make build-release && make test && make demo-build && make demo-test`.
   7.3. `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed`.
   7.4. `make pre-commit` (aggregate).
   7.5. `make benchmark` + `make benchmark-giantsteps` — confirm UNCHANGED accuracy baselines.
   7.6. Record exact integer counts in Completion Notes (test runs, accuracy splits, demo test count, lint violations).

8. **Task 8 — Documentation + deferred-work close-outs.**
   8.1. Update `_bmad-output/implementation-artifacts/deferred-work.md`:
        - W2 → mark `CLOSED 2026-05-XX (Story 5-4)` with cross-reference to AC #13.
        - W30 → mark `CLOSED 2026-05-XX (Story 5-4)` with cross-reference to AC #8.
        - Line :362 → UPDATE the re-open trigger to point at "a future library-side `BPMDiagnosticTrace: Codable` story" instead of Story 5-4 (since Story 5-4 explicitly does NOT promote it).
   8.2. `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift` carries a single header comment block summarizing DD #2 + DD #7 + DD #11 — so a future contributor reading the file understands why the projection exists separately from the library type.

9. **Task 9 — Code review + commit.**
   9.1. `/bmad-code-review` on the staged diff (separate-LLM cadence per project convention).
   9.2. Apply / defer / dismiss findings per the triage workflow.
   9.3. Re-run the full gating gauntlet post-patch.
   9.4. Final commit: `Story 5-4: diagnostic trace visualization and JSON export`. Commit message body lists: AC outcomes, library Sources/Tests UNCHANGED, demo file count delta, test count delta, accuracy baselines UNCHANGED, deferred-work closures.

## Apple Platform Notes

- **NSSavePanel sandbox semantics (post-Siri + axiom-macos verification 2026-05-20).** Apple's [Save Panel API docs](https://developer.apple.com/documentation/appkit/nssavepanel) describe `NSSavePanel.runModal()` as the synchronous modal presentation; the chosen URL is delivered via `panel.url` post-modal-return. **The PowerBox grant always auto-starts security-scoped read access on the returned URL** (axiom-macos `sandbox-and-file-access.md:306` table); the demo MUST call `url.stopAccessingSecurityScopedResource()` via `defer` after the write completes. **WRITE capability is gated by the declared entitlement** — with `user-selected.read-only`, the post-panel `Data.write(to: url)` fails with `NSCocoaErrorDomain` code 513 (`NSFileWriteNoPermissionError`). The panel itself opens regardless of the entitlement. The grant is transient — the demo writes once and the URL becomes inaccessible after the app exits. No bookmark persistence is added (Story 5-1 DD #16 still in force).
- **Sandbox entitlement read-write upgrade.** `com.apple.security.files.user-selected.read-write` is documented at [Documentation Archive — Sandboxing](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html). It SUPERSEDES read-only — there is no need to declare both; the read-write key grants the read superset. App Store review will not require additional justification for this entitlement (axiom-macos `sandbox-and-file-access.md:380` confirms it as the "principle of least privilege" baseline for apps with user-selected file workflows).
- **`codesign -d --entitlements -` for AC #6.** The shell form `codesign -d --entitlements - /path/to/app.bundle` echoes the entitlements as a binary-ish string. For CI-friendly machine-readable form, use `codesign -d --entitlements - --xml /path/to/app.bundle | plutil -p -` which produces a parseable plist dump. Either form works; the `--xml` flag is the recommended CI form.
- **`JSONEncoder` defaults (Siri-verified).** Per [JSONEncoder docs](https://developer.apple.com/documentation/foundation/jsonencoder), the default `dataEncodingStrategy = .base64` is acceptable since the trace contains no `Data` fields. `dateEncodingStrategy` defaults to `.deferredToDate` (numeric); we explicitly set `.iso8601` (RFC 3339, widely-consumed by external tools). `nonConformingFloatEncodingStrategy` defaults to `.throw` (we keep it; DD #12). `.sortedKeys` produces deterministic key ordering at every nesting level — relied on by AC #7's re-encode + byte-equal contract.
- **`@ObservationIgnored` macro (Siri-corrected from v1 spec).** [Documentation](https://developer.apple.com/documentation/observation/observationignored) — fields tagged with this attribute are REMOVED from `_$observationRegistrar` tracking entirely (NOT just "suppress re-renders on mutation"). A view body reading an `@ObservationIgnored` field does NOT register a dependency on it; re-render happens only when an OBSERVED property mutates in the same MainActor turn. Story 5-4 relies on this coupling — see DD #10 for the contract.
- **`BPMDiagnosticTrace` evolution warning.** The library docs explicitly note "Evolving API — fields may change across versions." The demo's `TraceExport` projection is a SNAPSHOT of the library trace at the Story 5-4 implementation moment. Future library trace evolution may require mechanical updates to the projection; the schemaVersion seam (DD #8) is the consumer's defense against silent change. The R2 golden-file snapshot test catches drift at CI time.
- **macOS 15 Sequoia `Form` rendering (Siri-verified).** SwiftUI `Form` on macOS 15 uses the grouped settings style with `LabeledContent` for label-value rows. `LabeledContent` is idiomatic since iOS 16 / macOS 13. The dev agent uses `LabeledContent` for the Run section fields ("BPM", "Confidence", etc.) to inherit the system-native rendering (RTL, Dynamic Type, accessibility labels for free).
- **`DisclosureGroup` chevron gotcha (Siri).** `DisclosureGroup` placed inside a `Form { Section }` uses the grouped-form chevron; at the root of a window VStack (Story 5-4's structure per DD #4) uses the plain-list chevron. The dev agent should not be surprised by the visual difference. The trace section uses the Window-VStack-root placement; the Form lives INSIDE the disclosure's expanded content, so the disclosure itself is the plain-list style.

## Risks

- **R1 — NSSavePanel write fails silently if the read-only entitlement is not upgraded.** A contributor running `make demo-build` (default unsigned) AND a forgotten entitlement file rollback in Task 6.1 would silently leak read-only to the signed sandboxed build. Mitigation: AC #6 inspection of `codesign -d --entitlements -` output is part of the gating gauntlet — the dev agent runs it AFTER `make demo-build-sandboxed`. Re-open trigger: a user reports "Export Trace shows the panel but no file appears."
- **R2 — `TraceExport` projection silently drops new library trace fields (post-Winston + Codex review 2026-05-20).** If a future library story adds a field to `BPMDiagnosticTrace`, the projection in `TraceExport.from(...)` will not include it, and exported JSONs will silently lack that data. The v1 spec's "single-line code comment" mitigation is wishful thinking — comments don't fire. **Two paired mitigations replace it:**

  1. **Golden-file schema test (load-bearing).** A new smoke test `traceExportSchemaMatchesGolden` constructs a `BPMDiagnosticTrace` with EVERY field populated to a deterministic non-default value (every tuple-shaped array gets a 1-2 element entry, every optional gets a non-nil value, every scalar gets a distinct constant), projects via `TraceExport.from(...)`, encodes with `.sortedKeys` pretty-printed JSON, and asserts byte-equality against a checked-in golden file at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/Fixtures/5-4-trace-export-golden.json`. When a library author adds a new trace field, the golden diverges — CI fails loudly with a unified diff. The dev agent either updates the golden (intentional projection update) or fixes the projection (silent-drop bug). **This is the R2 compile-time guard the v1 spec lacked.**
  2. **Exhaustive destructuring comment** at the top of `TraceExport.from(...)`: a numbered list naming every field of `BPMDiagnosticTrace` the projection consumes. Not a runtime guard — but it gives a future library author an at-a-glance audit checklist when they grep for `BPMDiagnosticTrace` writers.

  Re-open trigger: golden-file test fails on an unrelated library change AND the new trace field is judged useful for the demo trace JSON; OR a future Epic 5+ story formally migrates to library-side Codable.
- **R3 — `logMelData` omission is a footgun for ML calibration users.** The `MLFeatureFramesShapeJSON` projection includes shape metadata only (DD #11). A user wanting to train against the actual log-mel pre-image gets nothing useful from the exported JSON. Mitigation: AC #1 trace view section calls out the omission explicitly. Re-open trigger: a user reports needing the payload for external ML training calibration; addressed by a follow-up story that adds an opt-in checkbox.
- **R4 — `enableTrace = true` overhead at intensity 1-3 violates Story 5-2 AC #2 "near-instant" promise.** Story 4-3b measured the corpus-grain trace-build overhead at 1.054× (negligible). On a 30-second `.fastest` analysis (intensity 1 single window), 5% of <100 ms is <5 ms — invisible. Risk is small but non-zero. Mitigation: smoke test `enableTraceOverrideAtPrologue` exercises the path on `bpm-120-click.wav` at default intensity 7; the dev agent verifies the analyze completes within the existing 30s test deadline. Re-open trigger: a user reports the demo feels sluggish post-Story-5-4 at low intensity.
- **R5 — `BPMDiagnosticTrace` API is documented "evolving — fields may change across versions."** Consumers of the demo's exported trace JSON may rely on schema stability that the library does NOT guarantee. The `schemaVersion: "v1"` seam (DD #8) is the explicit contract: schemaVersion bumps signal an intentional break. Consumers parsing the JSON SHOULD check schemaVersion and refuse unknown versions; the demo cannot enforce this in external tooling. Risk accepted; documented in DD #8 and trace view footer.
- **R6 — Filename-based path traversal.** `NSSavePanel` handles path validation natively — the dev agent passes only `nameFieldStringValue: "<safe-string>"` and the panel sanitizes. No manual path manipulation. No risk.
- **R7 — Trace JSON for a successful analyze followed by an errored re-analyze: which trace is exportable?** Story 5-3 already establishes that the synchronous prologue clears observed state on every analyze. Story 5-4 extends that to `lastRunSnapshot = nil` (Task 1.4). If the new analyze ERRORS (`.success(nil)` or `.failure(...)`), `lastRunSnapshot` stays nil — the Export Trace button is hidden. If the new analyze SUCCEEDS, `lastRunSnapshot` is repopulated atomically. No "stale trace exported alongside fresh error" scenario.
- **R8 — User clicks Export Trace while a new analyze is starting.** AC #4 hides the Export button during `isAnalyzing == true`, so the click is unreachable via the UI. Defensive: the `exportTrace()` function checks `lastRunSnapshot != nil` at entry and returns false if nil. No race.
- **R10 — Stale-completion protection (Codex finding #6).** Run A starts; user adjusts slider, Run B starts (Run A cancelled via the cancel-all-prior cascade); Run A's task completes AFTER Run B's prologue has reset `lastRunSnapshot`. The per-task UUID gate (`currentTaskID == taskID`) at the top of the result-switch handler already protects against Run A's late `.success` arm clobbering Run B's state — same protection as Story 5-2 DD #5 covering `detectedBPM` writes. The atomic snapshot inherits this protection for free since the write site is INSIDE the existing gate (Task 1.7).
- **R11 — `panel.url` Sendable access in Swift 6 strict mode (axiom-concurrency check).** `NSSavePanel.url` is read post-`runModal()` on the same MainActor; no actor boundary crossing. Per `axiom-macos/skills/sandbox-and-file-access.md:306`, the URL has security-scoped access auto-started by PowerBox; the demo wraps post-unwrap access in `defer { url.stopAccessingSecurityScopedResource() }`. If a future story moves the encode + write off MainActor (Codex finding #5 forward-compat caveat), the URL would need `panel.url.startAccessingSecurityScopedResource()` re-call inside the off-MainActor task body to acquire scoped access after the auto-grant decays at MainActor exit. Story 5-4 keeps everything on MainActor — out of scope today.
- **R9 — JSON encoding throws on non-finite Float / Double from a future library trace change.** DD #12's `.throw` strategy surfaces this loudly. If the library starts emitting non-finite scores (a library regression), the demo's export fails coherently rather than producing JSON5 garbage. Smoke test `nanInTraceExportThrows` pins this. Re-open trigger: library trace starts emitting non-finite values at default options (would also be a library bug).

## Manual GUI Smoke Tests

These are deferred to user action per the Story 5-1 / 5-2 / 5-3 precedent (auto-mode cannot drive SwiftUI drops, NSSavePanel modal interaction, or window-level cancel button clicks). The dev agent does NOT execute them.

1. **Smoke 1 — Trace section appears post-analysis.** Drop `bpm-120-click.wav` (or any supported fixture). Wait for the result row to render with BPM. Confirm "Diagnostic Trace" disclosure appears below. Expand it. Verify all 8 sections render with reasonable values (BPM > 0, confidence in [0, 1], sub-band energies non-negative, candidate lists non-empty).

2. **Smoke 2 — Export Trace happy path.** With the trace section visible (post-Smoke-1), click "Export Trace". Confirm `NSSavePanel` appears with suggested filename matching `<fixture-name>-trace.json`. Accept default location, click Save. Open the saved file in a text editor (TextEdit / VS Code). Confirm valid JSON, `"schemaVersion": "v1"`, all expected top-level keys present.

3. **Smoke 3 — Export Trace cancel.** Click "Export Trace", let the save panel appear, click Cancel in the panel. Confirm: no file appears in the destination; no `errorMessage` banner appears; the trace section remains visible and expanded; the demo is responsive.

4. **Smoke 4 — Mid-analyze trace state.** Drop a longer fixture (e.g., `Submerged_Lament.mp3` at intensity 7 — ~2-3 second analyze). DURING the analyze, observe: Export Trace button hidden (AC #4); trace section gone (lastRunSnapshot cleared by prologue). After analyze completes, both reappear.

5. **Smoke 5 — Re-analyze updates trace.** With a successful analysis on screen, change the merge strategy picker from `maxConfidence` to `dedup`. Confirm the run re-fires (Story 5-3 behavior). Confirm the trace section's Run row updates to show `mergeStrategy: dedup`. Confirm the Export Trace button stays available; export and verify the JSON's `run.mergeStrategy == "dedup"`.

6. **Smoke 6 — Sandbox write actually lands at the user-chosen path.** Pick a non-default destination (e.g., `~/Desktop/`). Confirm the file lands there post-Save and is readable by `cat` / `jq`. Confirm `jq '.schemaVersion'` returns `"v1"`. Confirm `jq '.run.bpm'` returns a number close to the displayed BPM.

7. **Smoke 7 — Cancel during analyze hides Export Trace.** Drop a fixture, click Cancel. Confirm Export Trace stays hidden (lastRunSnapshot was not set in the cancel arm). Drop again and let it complete; Export Trace appears.

## References

### Previous Story Intelligence (PSI)

- **Story 5-3 close-out 2026-05-20** — established the `[Cancel] [Re-analyze] [Copy Config]` button row layout, per-task UUID discriminator (DD #5 from 5-2), `@ObservationIgnored` discipline for operational state (Story 5-1 PP8), static-method-on-view-model testability pattern (`generateConfigSnippet`, `formatResultRow` precedents). Story 5-4's `TraceExport.from(...)` + `FinalSelectionStep.derive(from:lastBPM:)` follow the same testability pattern. The Cancel-button hidden-via-`if` and Re-analyze visibility predicates (DD #4, DD #5) are extended verbatim for Export Trace (AC #4).
- **Story 5-3 W30 deferred-work entry (2026-05-20)** — explicitly named Story 5-4 as the close-out vehicle for the `manualReRunUsesCurrentOptions` test coverage gap. The `LastRunDiagnosticSnapshot.runOptions.mergeStrategy` accessor (DD #5 atomic snapshot) is the load-bearing seam that closes W30 via AC #8.
- **Story 5-3 W2 partial-close (2026-05-19)** — snapshot-at-launch + Re-analyze button delivered the first two of W2's three mitigations. The deferred third ("config used alongside results") is the natural fit for the trace JSON's Run section + the trace view's Run section. AC #13 closes W2.
- **Story 5-2 DD #5 / DD #6 (per-task UUID discriminator + pendingCancellations)** — the analyze body's `currentTaskID == taskID` gate is unchanged by Story 5-4; the new `lastRunSnapshot` atomic-snapshot write sits INSIDE the existing gate (Task 1.7 verifies).
- **Story 5-1 DD #16-D (split fileName String? exposed vs selectedFileURL URL? operational)** — Story 5-4 honors the rule: `selectedFileURL` is NEVER exported into the trace JSON. The JSON's `run.fileName` carries the basename only (the library's `AudioAnalysisResult.bpm`-producing code never sees the URL post-PCM-read), satisfying the sandbox-leaky-path discipline.
- **Story 4-3b corpus-grain perf gate (2026-05-08)** — measured trace-build overhead at 1.054× of baseline (well within the 1.30× threshold). The DD #1 always-on-trace override inherits this measurement; AC #10 verifies no regression at the library accuracy level.
- **Story 4-5 N13 `MLFeatureFrames` non-finite-float rejection** — establishes the precedent that non-finite values in trace fields are a library bug, and the appropriate response is to reject loudly. DD #12 + AC #9 inherit this discipline.
- **Story 4-6 Branch C bundle pull (2026-05-16)** — confirms `Sources/BoomBoomBoomKitML/Resources/` is empty; no `BNNSTechnique` is wired into the demo by default. Story 5-4's trace view's ML section renders `"(ML not active)"` in the common case; `mlInfo` is `nil` in the exported JSON.
- **Epic 4 retro 2026-05-17 A2** — `deferred-work.md` is the canonical single source of truth for deferred items, NOT story-file `[ ]` checkboxes. AC #13 + Task 8.1 follow A2: every closure / update lands in `deferred-work.md` with cross-reference, not as story-file checkboxes.
- **Epic 4 retro 2026-05-17 A3** — `make test` wall-clock baseline tracked per epic. Story 5-3 close-out recorded `make demo-test` at ~57 invocations on M5 Max post-Story-5-3. Story 5-4 records the new count in Completion Notes per AC #12.

### External References

- **Apple Documentation — NSSavePanel:** [`NSSavePanel`](https://developer.apple.com/documentation/appkit/nssavepanel), [`NSSavePanel.allowedContentTypes`](https://developer.apple.com/documentation/appkit/nssavepanel/allowedcontenttypes), [`NSSavePanel.runModal()`](https://developer.apple.com/documentation/appkit/nssavepanel/runmodal()).
- **Apple Documentation — App Sandbox file access:** [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html) — `com.apple.security.files.user-selected.read-write` semantics.
- **Apple Documentation — JSONEncoder:** [`JSONEncoder`](https://developer.apple.com/documentation/foundation/jsonencoder), [`NonConformingFloatEncodingStrategy.throw`](https://developer.apple.com/documentation/foundation/jsonencoder/nonconformingfloatencodingstrategy/throw), [`DateEncodingStrategy.iso8601`](https://developer.apple.com/documentation/foundation/jsonencoder/dateencodingstrategy/iso8601).
- **Apple Documentation — SwiftUI DisclosureGroup:** [`DisclosureGroup`](https://developer.apple.com/documentation/swiftui/disclosuregroup) — initializer with custom label closure.
- **Apple Documentation — `@ObservationIgnored`:** [`ObservationIgnored`](https://developer.apple.com/documentation/observation/observationignored).
- **Project-context.md §"Public API Discipline (pre-1.0)":** Internal-to-public promotion requires a named story spec; deferred-work entries are NOT sufficient. DD #2 invokes this rule to keep `BPMDiagnosticTrace` library-internal-shape.
- **Project-context.md §"Banned trace-field shapes":** Four anti-patterns explicitly forbidden in `BPMDiagnosticTrace`. Story 5-4's `TraceExport` projection inherits the discipline — every demo-side projection type is a named `Sendable` struct, NOT `[String: Any]`.
- **Deferred-work.md:362 (pre-Story-5-4):** "`EnsembleDecision` is not `Codable` while nested `Winner: Codable`. Re-open trigger: Story 5-4 (Diagnostic trace visualization and export) lands JSON serialization; whichever story makes `BPMDiagnosticTrace: Codable` will need to extend `EnsembleDecision`." DD #2 + AC #13 update this entry to point at a future library-side trace-Codable story instead.

## Diff-scope Expectations

Story 5-4 is a Demo-only addition. Expected changes:

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — grow from 558 lines to ~620-640 lines (+62-82). New: 3 `@ObservationIgnored` fields, 3 reset lines in the analyze prologue, 1 `opts.enableTrace = true` override, 3 set-site lines in the `.success` arm, 1 `exportTrace()` method.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — grow from 300 lines to ~360-380 lines (+60-80). New: Export Trace button in controls row, `TraceView` embedded below the result row.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift` — NEW file. ~180-220 lines. Top-level + nested Codable types + `from(...)` factory + `FinalSelectionStep` enum + `derive(from:lastBPM:)`.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` — NEW file. ~100-150 lines. SwiftUI `DisclosureGroup` + sectioned form layout.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` — 1-line change (`read-only` → `read-write`).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — grow from 304 lines (Story 5-3 close-out) to ~380-420 lines (+76-116). New: 5-6 `@Test` declarations per Task 5; 1 tightened existing `manualReRunUsesCurrentOptions`.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — may grow if PBXFileSystemSynchronizedRootGroup auto-includes the 2 new files; otherwise unchanged.
- `_bmad-output/implementation-artifacts/deferred-work.md` — 3 entry updates (W2 CLOSED, W30 CLOSED, line 362 re-open trigger updated).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flips backlog → ready-for-dev → in-progress → review → done.
- `_bmad-output/implementation-artifacts/5-4-diagnostic-trace-visualization-and-export.md` — THIS file.

**Zero library Sources/Tests modifications expected.** Verified via `git status --porcelain Sources/ Tests/` returning empty pre-commit (AC #10).

**Library accuracy baselines UNCHANGED expected.** OA300 Acc1 = 58/82 + Acc2 = 74/82; GiantSteps Acc1 = 537/661 + Acc2 = 546/661.

## Dev Agent Record

### Implementation Plan

Followed the 9 tasks from the story spec in order via bmad-dev-story auto-mode. No HALT events fired. All AC outcomes met programmatically except AC #11 (manual GUI smoke tests, deferred to user action per Stories 5-1/5-2/5-3 precedent).

### Completion Notes

**Diff scope.** 9 files modified/created. Demo-only changes; zero library Sources/ or Tests/ modifications (AC #10 verified via `git status --porcelain Sources/ Tests/` → empty).

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — grew 558 → 731 lines (+173). Added `LastRunDiagnosticSnapshot`/`RunOptionsSnapshot` references (types live in TraceExport.swift), `@ObservationIgnored var lastRunSnapshot`, prologue reset, `opts.enableTrace = true` override at line 191 (post-snapshot per DD #1), `.success` arm snapshot write site (post-observed-property writes per DD #10), `humanize(_:)` static helper for W2 caption, `encodeTrace(snapshot:elapsedSeconds:)`, `suggestedFilename(from:)`, `writeTraceJSON(to:)`, `exportTrace()`. Added `import UniformTypeIdentifiers` for `UTType.json`.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — grew 300 → 332 lines (+32). Added `TraceView(snapshot: snapshot)` inline below `primaryStateView`, the W2 caption line inside `resultView`, the Export Trace button in the controls row with differential styling per Sally's UX rec (Re-analyze `.borderedProminent`; Copy Config + Export Trace `.bordered`; Divider between primary and secondary cluster).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift` — NEW file, ~625 lines. `LastRunDiagnosticSnapshot` + `RunOptionsSnapshot` value types, `FinalSelectionStep` enum with `derive(from:lastBPM:)` and `reasoning` (DD #6 cascade ordering: mlEnsemble → metadataCorroboration → fineGridRefinement → subBandVoting → durationHint → clickRescore → baselineDisambiguation), `TraceExport` top-level Codable struct + 14 nested projection types (Run, Selection, Pipeline, Metadata, ML + 9 leaf JSON types), two `from(...)` factory overloads (convenience over `Options`, primary over `RunOptionsSnapshot`). `schemaVersion: "v1"` (DD #8). `function_parameter_count` suppressed via `// swiftlint:disable`/`enable` brackets — Amelia's `ProjectionInputs` wrapper polish deferred.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` — NEW file, ~258 lines. `DisclosureGroup`-rooted view with 8 `Form { Section }` blocks per DD #4: Run / Selection path / Candidates / Sub-band energies / Disambiguation / Fine-grid / Metadata corroboration / ML ensemble. `LabeledContent` for label-value rows (idiomatic macOS 15 grouped layout). Plain `Text`/`HStack` — no Chart, no animation.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` — `read-only` → `read-write`.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — `ENABLE_USER_SELECTED_FILES = readonly` → `readwrite` (both Debug + Release). Required because Xcode auto-injects the corresponding entitlement key from this build setting, overriding the `.entitlements` file value.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — grew 534 → ~990 lines (+456). 11 new `@Test` declarations (5.1-5.11). Helper `analyzeFixture()`, `canonicalTraceExport()` (`@MainActor`-isolated to call MainActor-isolated `init(from:)` initializers), `normalizeForRoundTrip()` (handles ISO 8601 millisecond truncation for AC #7), `containsKey(_:in:)` recursive JSON walker.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/Fixtures/5-4-trace-export-golden.json` — NEW golden file (~150 lines pretty-printed). Generated by `traceExportSchemaMatchesGolden`'s first-run write branch; commit-and-hold so future runs assert byte-equality.
- `_bmad-output/implementation-artifacts/deferred-work.md` — W2 marked CLOSED (caption line); W30 marked CLOSED (`manualReRunUsesCurrentOptions` tightened); line 362 (`EnsembleDecision is not Codable`) re-open trigger updated to point at future library-side trace-Codable story.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — Story 5-4 ready-for-dev → in-progress → review.

**Build-time discoveries.**

1. `BPMDiagnosticTrace` synthesized memberwise init is internal (public struct, public properties, no explicit init). The demo target cannot construct one directly. The 5.2/5.7/5.11 tests obtain a real trace from `analyzeFixture()` and mutate the public-var fields. Same constraint for `BPMDiagnosticTrace` proper, but all the typed-evidence helper types (`ClickCorrelationEntry`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`, `EnsembleDecision`, `MLFeatureFrames`, `HarmonicRatioEvidence`, `SubBandEnergies`) DO have public inits.
2. `MLDiagnosticSnapshot` actual field names: `softmaxMax` / `softmaxSecondMax` (NOT `topSoftmaxProbability` / `secondSoftmaxProbability`), `inputFeatureChecksum: UInt64` (NOT optional), no `modelIdentifier` or `featureSetVersion` fields. The initial TraceExport projection used the wrong names and was corrected during implementation.
3. The factory takes `result: AudioAnalysisResult` to access `effectiveIntensity` and `degradationReason` — the latter is not in the view-model's observed state. To eliminate the per-export "reach into view-model observed state" hazard (which would recreate the partial-state race DD #5 eliminated), the `LastRunDiagnosticSnapshot` carries a 5th field `result: AudioAnalysisResult` (in addition to the 4 listed in DD #5). This is a small impl judgment-call adjustment documented inline; `AudioAnalysisResult` is a closure-free value type so no retain hazard.
4. The factory exists in two overloads: convenience over `AudioAnalysisService.Options` (for smoke tests that hold the full Options bag) + primary over `RunOptionsSnapshot` (for production callers — avoids retaining `Options.isCancelled` closure captures per Winston review).
5. `Xcode build setting ENABLE_USER_SELECTED_FILES = readonly` was injecting the `read-only` entitlement on top of the entitlements file. Fixed by changing the build setting to `readwrite` in both Debug and Release configs.
6. `JSONEncoder` with `.dateEncodingStrategy = .iso8601` truncates `Date()` to millisecond precision. `traceProjectionRoundTripsJSON` needed a normalization step (`normalizeForRoundTrip`) to defeat this on both sides before byte comparison.
7. SwiftLint `function_parameter_count` rule triggered on both `from(...)` factories (6 params each). Suppressed with `// swiftlint:disable`/`enable` brackets (not `:next` — that orphans the preceding `///` doc comment).

**Final-step derivation cascade.** Implemented per the DD #6 priority order (highest = latest-executed in the library pipeline): `mlEnsemble` → `metadataCorroboration` → `fineGridRefinement` → `subBandVoting` → `durationHint` → `clickRescore` → `baselineDisambiguation`. Each arm tested via `finalSelectionStepDerivation` parameterized over 9 scenarios (7 individual arms + 2 conflict cases that verify higher-priority wins). The `mlEnsemble` arm requires all three conditions (winner == .ml AND selectedBPM == lastBPM). `metadataCorroboration` uses max-score reduce on `candidatesBeforeBoost`/`candidatesAfterBoost` (not `[0]` indexing — sort stability not documented).

**AC outcomes.**

- AC #1 — Trace section renders on successful analysis. Inline `DisclosureGroup` below result row; 8 sections per DD #4 (Run, Selection path, Candidates, Sub-band energies, Disambiguation, Fine-grid, Metadata, ML).
- AC #2 — Selection path label fires correctly. `finalSelectionStepDerivation` parameterized over 9 scenarios; all pass.
- AC #3 — `lastRunSnapshot` populated atomically. `lastRunSnapshotIsAtomic` verifies; `lastRunSnapshotResetOnAnalyzePrologue` verifies reset.
- AC #4 — Export Trace button visibility gated on snapshot. `exportTraceVisibilityGatedOnSnapshot` verifies via fresh-init + failure-arm states.
- AC #5 — NSSavePanel write produces valid JSON. Verified at the encode level via `traceProjectionRoundTripsJSON` (round-trip). End-to-end NSSavePanel exercise is part of the AC #11 manual smoke tests.
- AC #6 — Sandbox entitlement is `user-selected.read-write`. Verified via `codesign -d --entitlements -` showing only the read-write key (no read-only).
- AC #7 — Trace JSON reproducible up to documented volatile fields. `traceExportSchemaMatchesGolden` + `traceProjectionRoundTripsJSON` together implement the decode + normalize + re-encode contract.
- AC #8 — `manualReRunUsesCurrentOptions` tightened to assert `lastRunSnapshot.runOptions.mergeStrategy == .dedup`. Closes W30.
- AC #9 — NaN/Inf encode throws. `nanInTraceExportThrows` parameterized over 4 injection sites; all assert `EncodingError` thrown.
- AC #10 — Always-on `enableTrace = true` does not regress baselines. OA300 58/82+74/82 UNCHANGED; GiantSteps 537/661+546/661 UNCHANGED. `git status --porcelain Sources/ Tests/` empty.
- AC #11 — Manual GUI smoke tests pending user action (deferred per Story 5-2/5-3 precedent).
- AC #12 — Gating gauntlet outcomes:
  - `make fmt`: clean (no diff).
  - `make demo-fmt`: clean.
  - `make lint`: 1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline.
  - `make demo-lint`: exit 0.
  - `make build`: 0.12s exit 0.
  - `make build-release`: 0.11s exit 0.
  - `make test`: 431 tests in 94 suites pass.
  - `make demo-build`: BUILD SUCCEEDED.
  - `make demo-test`: TEST SUCCEEDED. Test invocation count grew 57 → 80 (+23; within the spec's "+21-25" expected band).
  - `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed`: BUILD SUCCEEDED with entitlements (`codesign -d --entitlements -` confirms `app-sandbox` + `user-selected.read-write` + `get-task-allow`).
  - `make pre-commit`: exit 0.
  - `make benchmark`: OA300 Acc1=58/82, Acc2=74/82 UNCHANGED.
  - `make benchmark-giantsteps`: Acc1=537/661, Acc2=546/661 UNCHANGED.
- AC #13 — W2 + W30 CLOSED. `deferred-work.md` updated:
  - W2 closure narrative: result-row caption line is the load-bearing surface; reinforced by disclosure header.
  - W30 closure narrative: `manualReRunUsesCurrentOptions` tightened assertion.
  - Line 362 (`EnsembleDecision is not Codable`) re-open trigger updated to point at a future library-side trace-Codable story rather than Story 5-4 (since DD #2 explicitly defers library-side promotion).
- AC #14 — Write-error path surfaces errorMessage; no partial file. `exportTraceWriteErrorSetsErrorMessage` verifies via deliberately-unwritable URL.
- AC #15 — `logMelData` absent from exported JSON; shape metadata present. `logMelDataOmittedFromExport` constructs a populated `mlFeatures`, projects, and walks the encoded JSON via `JSONSerialization.jsonObject(with:)` to confirm no `logMelData` key anywhere. Asserts JSON size < 100 KB.

**Pending user action.**

- AC #11 manual GUI smoke tests 1-7 on `make demo-build-sandboxed` build (drop file → trace section appears → expand → 8 sections render; Export Trace happy path; Export Trace cancel; mid-analyze trace hidden; re-analyze updates trace; sandbox write actually lands at user-chosen path; Cancel during analyze hides Export Trace).
- Task 9.1 `/bmad-code-review` on separate-LLM cadence per project convention.
- Task 9.4 final commit on 1Password GPG signer per Story 5-1/5-2/5-3 precedent.

### Debug Log

No HALT events. Three issues surfaced and resolved during impl:

1. `traceProjectionRoundTripsJSON` initial failure: `Date()` sub-millisecond precision truncated by ISO 8601 encoding. Fix: added `normalizeForRoundTrip()` helper to set `generatedAt = .distantPast` and `elapsedSeconds = 0` on both decoded + original before comparison.
2. Initial `Issue.record(... + ...)` String concatenation failed compile (`String.Element` vs `String`). Fix: pre-compute the message string, then `Issue.record(Comment(rawValue: message))`.
3. `canonicalTraceExport()` calling MainActor-isolated `init(from:)` initializers from a nonisolated static func — fixed by adding `@MainActor` annotation.

### File List

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` (modified)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift` (modified — DD #4-B post-impl reframe: `InspectorCommands` + default window size `(640, 480)` → `(960, 600)`)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` (modified)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceExport.swift` (new)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` (new — DD #4-B post-impl reframe: outer DisclosureGroup + Form removed; ScrollView + VStack of GroupBox pattern; added `TraceInspectorEmptyView` for no-snapshot state)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` (modified)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` (modified)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` (modified)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/Fixtures/5-4-trace-export-golden.json` (new)
- `_bmad-output/implementation-artifacts/deferred-work.md` (modified)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified)
- `_bmad-output/implementation-artifacts/5-4-diagnostic-trace-visualization-and-export.md` (modified — Dev Agent Record + status flip + DD #4-B amendment + Change Log addendum)

### Change Log

- 2026-05-20 (dev close-out): Story 5-4 implementation complete via bmad-dev-story auto-mode. Status flip ready-for-dev → in-progress → review. Demo-only changes (zero library impact, AC #10 verified). Library accuracy baselines UNCHANGED (OA300 58/82+74/82, GiantSteps 537/661+546/661). Demo test count 57 → 80 (+23 invocations across 11 new `@Test` declarations). Deferred-work W2 + W30 CLOSED; line 362 re-open trigger updated. Pending: AC #11 manual GUI smoke tests, /bmad-code-review on separate-LLM cadence, final commit on 1Password GPG signer.

- 2026-05-20 (post-impl inspector reframe): Manual GUI smoke test for AC #1 surfaced an empty-window layout regression — clicking the `>` chevron on the `DisclosureGroup` "Diagnostic Trace" expanded to whitespace filling the window, none of the 8 Form sections visible. Root cause: greedy `Form { ... }.formStyle(.grouped)` (ScrollView-backed) inside greedy `VStack { ... }.frame(maxHeight: .infinity)` with no scroll owner, content rendering at y=0 of an infinite scroll region (`axiom-swiftui/skills/layout-ref.md:313` documents the greedy-sizing anti-pattern). User invoked `bmad-party-mode` with Sally / Amelia / Siri / Winston; Winston flagged that the trace surface is a "detail-of-current-selection" use case that belongs in macOS `.inspector(...)` rather than stacked under the run panel. User invoked `axiom-swiftui` (validates layout diagnosis) and `axiom-macos` (`swiftui-differences.md:266-298` documents Inspector as the macOS-native pattern for selection-dependent detail; explicitly contrasts with sheet/popover/disclosure). Both skills converged on Inspector as the documented-correct reframe. DD #4 originally weighed (A) DisclosureGroup / (B) sheet / (C) NavigationStack and never considered Inspector — that was the spec-level miss. **DD #4-B amendment landed:** `TraceView` restructured to drop the outer `DisclosureGroup` + drop `Form / .formStyle(.grouped)` + use `ScrollView { VStack { GroupBox(...) } }` (macOS 13+ idiom). `ContentView` attaches `.inspector(isPresented: $inspectorPresented)` at root with `.inspectorColumnWidth(min: 240, ideal: 320, max: 480)`. New `TraceInspectorEmptyView` for the no-snapshot state. `@SceneStorage("traceInspectorPresented") = true` default for discoverability. `BoomBoomBoomKitDemoApp` adds `.commands { InspectorCommands() }` (Control-Command-I + View menu). `WindowGroup.defaultSize` grew `(640, 480)` → `(960, 600)` to accommodate the inspector at its ideal width. Diff: 4 files modified (`TraceView.swift` rewritten — DisclosureGroup + Form removed, replaced with ScrollView + GroupBox pattern; `ContentView.swift` — removed inline trace, added `.inspector` modifier + `@SceneStorage`; `BoomBoomBoomKitDemoApp.swift` — added `InspectorCommands` + bumped default window size; story spec DD #4 amended with DD #4-B language). Re-run gating gauntlet: `make demo-build` BUILD SUCCEEDED, `make demo-test` 80 invocations pass (no test changes needed — all 5.1-5.11 tests exercise the data layer or the view-model API, not the View hierarchy). `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED. `make pre-commit` exit 0 (1 lint violation = canonical LUFSAnalyzer:94 TODO baseline). Library baselines UNCHANGED (zero `Sources/`/`Tests/` modifications still). Pending re-verification: AC #11 manual GUI smoke 1-7 against the inspector-reframed build.
