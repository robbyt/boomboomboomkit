# Story 5.6: End-user UI Redesign and Collapsible Trace Inspector

Story ID: 5.6
Story Key: 5-6-end-user-ui-redesign
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: review
Last refined: 2026-05-23 (multi-stage validation — Axiom skills + apple-docs MCP + Codex + BMAD party)

## Story

As an end user dropping an audio file into the BoomBoomBoomKitDemo macOS app,
I want a focused, polished window where the detected BPM is the visual hero and developer-facing knobs sit out of the way,
So that the app feels like a consumer tool ready for App Store distribution rather than a developer evaluation harness.

**Scope clarification (read first).** Story 5-6 re-skins the existing demo app for consumer-facing release without changing the library, the public Swift API of `BoomBoomBoomKit`/`BoomBoomBoomKitML`, the `AnalysisViewModel` observed surface, or `TraceExport`'s JSON schema. The three moves the user named in the party-mode prompt land here, plus the agent-unanimous refinements from that round.

Three behavioral shifts ship:

1. **Layout flip + BPM hero.** `ContentView.swift` currently renders top-to-bottom as `controls → result → banner`. Post-Story-5-6, the order is `result (top-right justified, hero typography) → controls (bottom)`. The BPM number itself gets the visual weight — large, anchored top-right of the main pane, with monospaced *digits* (`.monospacedDigit()`) so the unit label stays in the SF Pro family.
2. **Strategy-keyed background painted at the root.** A `StrategyBackground` view, switched on `CandidateMergeStrategy`, renders a `LinearGradient` (8 variants + 1 neutral pre-analysis fallback) behind **all** display states via an outer `ZStack` at the `ContentView` root — NOT scoped to the result block. State transitions cross-fade. Final raster assets land in a follow-up story once the user supplies them; the gradient stubs ship now so the structural seam exists. Accessibility-gated (reduce-motion + increase-contrast fallbacks).
3. **Trace inspector default-hidden + toolbar toggle.** The `.inspector(isPresented:)` mechanism is already wired (see `ContentView.swift:53` — `@SceneStorage("traceInspectorPresented")` defaults to `true`). Story 5-6 flips the default to `false`, adds an explicit toolbar button (with SF Symbol + label) for show/hide, and binds a `⌘⇧D` keyboard shortcut. The system's `⌃⌘I` shortcut and the View → Show Inspector menu entry are provided by the existing `InspectorCommands()` modifier in `BoomBoomBoomKitDemoApp.swift:14-16` — Story 5-6 must NOT add a duplicate `.commands { }` block.

**Plus one party-mode add-in**: an oversized drop-zone empty state (Sally's recommendation) replaces the current "Drop an audio file" + format-list two-line text block. Becomes the app's first impression and the App Store screenshot subject.

**What this story does NOT deliver** (each explicitly OUT-OF-SCOPE):

- **No final strategy background artwork.** User will supply images in a follow-up. Gradient stubs only here.
- **No parameter-control restructure.** Slider/picker/buttons stay where they are now (now at the bottom post-flip); no styling polish, no "developer mode" gate around the merge-strategy picker (party-mode John's suggestion is acknowledged but out-of-scope per user-stated UI brief).
- **No new `AnalysisViewModel` API.** Layout binds to the existing observed surface (`detectedBPM`, `confidence`, `effectiveIntensity`, `elapsedSeconds`, `fileName`, `lastRunSnapshot`, `options.mergeStrategy`).
- **No library `Sources/` changes.** Zero edits to `Sources/BoomBoomBoomKit/` or `Sources/BoomBoomBoomKitML/`.
- **No App Store submission prep.** Privacy manifest, app icon, signing, archive target → Story 5-7.
- **No first-run experience, no onboarding flow, no settings window.** Empty state + drop = the UX. Power-user mode is the trace toggle.
- **No album-art-from-file rendering.** Sally's "read embedded artwork as background" idea is interesting but out-of-scope; key on `mergeStrategy` per user's stated brief.

## Key Design Decisions

1. **Strategy-keyed background driver is `CandidateMergeStrategy`, not `FinalSelectionStep` or `effectiveIntensity`.** User's brief named "strategy" explicitly. The 8 `CandidateMergeStrategy` cases (`.maxConfidence`, `.dedup`, `.quorum`, `.average`, `.median`, `.weightedAverage`, `.union`, `.windowVoting`) get one gradient each, plus a 9th **neutral pre-analysis gradient** that paints behind `.empty`, `.analyzing`, and `.errorOnly` states so the app never reverts to bare window chrome. `FinalSelectionStep` was considered (would show selection-step diversity rather than user-chosen strategy) and rejected because the user controls `mergeStrategy` directly and reads back the chosen value in Copy Config — the background reinforces what the user picked, not what the pipeline derived.

2. **`.inspector(isPresented:)` over `NavigationSplitView` or `HSplitView`.** The mechanism already ships in `ContentView.swift:53-62` per Story 5-4; refactoring to `NavigationSplitView` would introduce a navigation hierarchy that doesn't model this app's content shape (no "list → detail" relationship; the trace is a detail view of the most recent run, not a navigable collection). `.inspector` is the SwiftUI primitive purpose-built for "toggleable inspector pane that doesn't own primary navigation". Apple precedent: Mail.app's per-message inspector, Numbers' format inspector. The `.inspectorColumnWidth(min:240, ideal:320, max:480)` modifier is also already correctly placed inside the inspector content closure (Story 5-4 caught the chained-vs-inside-closure gotcha in code review) — Story 5-6 must preserve those numbers verbatim; without explicit column width, SwiftUI defaults to 250pt and the JSON-copy button clips on first open (Siri's 2026-05-23 review note).

3. **`@SceneStorage` over `@AppStorage` for the toggle.** Per-window persistence (`@SceneStorage`) is already in use (`ContentView.swift:11`). Multi-window restoration semantics are correct: each restored window remembers its own inspector state. The story flips the default value from `true` to `false`; no change in storage mechanism.

4. **BPM hero typography — bounded Dynamic Type, monospaced-digit not monospaced-face.** The hero uses `Font.system(size: 96, weight: .bold).monospacedDigit().leading(.tight)` with `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` (ceiling) and `.minimumScaleFactor(0.6)` + `.lineLimit(1)` (clip guard). This is the convergent recommendation from the 2026-05-23 party-mode review: pure fixed-size violates Dynamic Type (App Store accessibility audit risk); pure `.relativeTo(.largeTitle)` lets `.accessibility4`/`.accessibility5` push the BPM number off-canvas. The bounded form scales to AX1–AX3 (the practical range for an end-user app) and degrades gracefully beyond. `.monospacedDigit()` (rather than `design: .monospaced` on the full face) is the canonical fix for digit-width jitter during analysis ticks without losing SF Pro's feel on the " BPM" suffix. The legacy "BPM: 160.1 BPM" row from Story 5-2 is REPLACED by the hero rendering; supporting fields (file name, confidence, elapsed) move to a `secondaryMetadata` stack under the hero number, rendered via `.font(.callout)` semantic style (which honors Dynamic Type without a ceiling). (Revised 2026-05-23 per user direction — intensity + result-captured-at caption removed from the metadata stack per AC #3 amendment; both were developer-mode telemetry inappropriate for the consumer release.)

5. **Drop-zone empty state lives in a single dedicated `EmptyStateView`.** Extracted from the inline `DisplayState.empty` branch in `ContentView.swift:233-240`. The view fills the available space, renders a large SF Symbol (`music.note.list` or `square.and.arrow.down`, dev's call, marked `Image(decorative:)` so VoiceOver doesn't read the asset name), a one-line "Drop a track" headline (`.font(.largeTitle)`), a one-line supported-format caption (`.font(.callout)` with `.secondary` foreground). The drop-targeting accent border (`ContentView.swift:29-37`) continues to draw around the whole window, not just the empty-state view.

6. **Toolbar toggle button** uses `Image(systemName: "sidebar.right")` (Apple's documented inspector-toggle symbol) + label "Diagnostics". `.help("Show / hide diagnostics (⌘⇧D)")` for the hover tooltip. `.keyboardShortcut("d", modifiers: [.command, .shift])` for the binding. The system's `⌃⌘I` shortcut and the View → Show Inspector menu entry are provided by `InspectorCommands()` at `BoomBoomBoomKitDemoApp.swift:14-16` — Story 5-6 does NOT add another `.commands { }` block.

7. **Accessibility gates** are non-optional, and **WCAG floor differs by element**. `@Environment(\.accessibilityReduceMotion)` gates the cross-strategy gradient animation (no animation when reduced); `@Environment(\.colorSchemeContrast)` switches `StrategyBackground` to a solid-fill fallback color when `.increased`. Contrast floors: **hero BPM (96pt bold, WCAG "large text") clears 3:1**; **supporting metadata (`.callout`) clears 4.5:1** against gradient anchors in both Light and Dark mode. The dev agent verifies via Digital Color Meter sampling at each of the 9 gradients (8 strategy + 1 neutral).

8. **Outer-`ZStack` composition for `StrategyBackground`.** Result-block-scoped `.background()` collapses to zero size in `.empty` / `.analyzing` / `.errorOnly` states. Hoisting `StrategyBackground` to a window-filling `ZStack` at the `ContentView` root (behind every `DisplayState`) gives the app a consistent visual identity across its first five seconds. Trade-off acknowledged: the background persists across result clears (could feel sticky) — mitigated by cross-fading to the neutral pre-analysis gradient when `viewModel.lastRunSnapshot == nil`.

9. **No new tests for layout.** SwiftUI view code is exercised end-to-end by `make demo-build` (compile-time) + the existing 78 invocations in `AnalysisViewModelSmokeTest.swift` (view-model contract). Layout regressions surface visually; the demo doesn't carry a snapshot-test harness today and adding one is out-of-scope. The dev agent verifies layout manually by running the app and dropping a fixture file (`bpm-120-click.wav`) and toggling the inspector.

10. **Screenshot stability is now a Story-5-6 concern, not a Story-5-7 inheritance.** Story 5-7 requires App Store assets at 1280×800 (default) and 2560×1600 (Retina). If the hero/inspector layout reflows unpredictably between those, 5-7 inherits a screenshot-automation problem. Story 5-6 validates layout parity at both resolutions during Task 5 visual verification (Winston's 2026-05-23 review note).

## Acceptance Criteria

1. **Layout order in `ContentView.swift` is flipped to `result → controls`.** The result rendering sits at the top of the main pane; the parameter-controls `GroupBox` sits at the bottom. The drop-target accent ring and the error banner continue to compose around both.

2. **BPM number renders as a hero element**, top-right anchored via `.frame(maxWidth: .infinity, alignment: .topTrailing)` on a single VStack (rather than nested `HStack { Spacer(); VStack }`). Typography: `Font.system(size: 96, weight: .bold).monospacedDigit().leading(.tight)`, with `.dynamicTypeSize(...DynamicTypeSize.accessibility3)`, `.minimumScaleFactor(0.6)`, and `.lineLimit(1)`. The " BPM" suffix renders in SF Pro (no monospaced face) for visual separation.

3. **Supporting metadata** (file name, confidence, elapsed seconds) renders beneath the hero BPM in a right-aligned `VStack`, `.font(.callout)`, `.foregroundStyle(.secondary)`. Metadata honors Dynamic Type unbounded (no ceiling). (Revised 2026-05-23 per user direction — original spec listed `intensity` and a `Result captured at` caption; both removed from the end-user UI as developer-mode telemetry that doesn't belong in the consumer release. The snapshot-divergence cue Story 5-3 introduced and Story 5-4 W2 closed is preserved internally on `viewModel.lastRunSnapshot` for the Diagnostics inspector audience, not surfaced in the hero metadata stack. Closes F02.)

4. **A `StrategyBackground` view exists** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift`. It accepts an optional `CandidateMergeStrategy?` value and renders one of 9 `LinearGradient` variants — 8 keyed to the strategy cases plus 1 **neutral** gradient when `strategy == nil`. It is composed at the `ContentView` root as the **base layer of an outer `ZStack`**, painting behind every `DisplayState`. Result-block-scoped `.background(StrategyBackground)` is explicitly forbidden (collapses to zero size in `.empty` / `.analyzing` / `.errorOnly`).

5. **Strategy switching cross-fades** via `.animation(reduceMotion ? .none : .easeInOut(duration: 0.25), value: backgroundKey)` where `backgroundKey` combines `mergeStrategy` + `lastRunSnapshot.isNil`. Reduce-motion users get an immediate swap. The animation also covers the empty/analyzing/error → result transition (visual reveal moment).

6. **Contrast floors by element type** — Hero BPM (`Font.system(size: 96, weight: .bold)`, qualifies as WCAG "large text" ≥18pt bold) clears **3:1** against every `StrategyBackground` gradient and the neutral fallback, Light and Dark mode. Supporting metadata (`.callout`-sized) clears **4.5:1** against the same backdrops. The toolbar button's accessibility-label "Diagnostics" is preserved; the SF Symbol image is decorative.

7. **High-contrast mode shows a solid fill** rather than a gradient when `@Environment(\.colorSchemeContrast) == .increased`. Solid color choice is keyed by strategy (8 cases) or `Color.gray.opacity(0.15)` for the neutral pre-analysis state.

8. **Trace inspector default visibility is `false`.** `@SceneStorage("traceInspectorPresented")` initializer is changed from `true` to `false` in `ContentView.swift:11`. Existing users with the stored value `true` retain their preference.

9. **A toolbar button toggles the inspector**, placed via `.toolbar { ToolbarItem(placement: .primaryAction) { ... } }` on the root view (no `NavigationStack` wrapping required — macOS routes `.toolbar` to the window title-bar from a bare `WindowGroup` ContentView). Button binds `.keyboardShortcut("d", modifiers: [.command, .shift])`, carries `.help("Show / hide diagnostics (⌘⇧D)")`, displays `Image(systemName: "sidebar.right")` and the label "Diagnostics".

10. **The existing `InspectorCommands()` modifier at `BoomBoomBoomKitDemoApp.swift:14-16` is preserved verbatim.** Story 5-6 does NOT add a second `.commands { }` block. The View → Show Inspector menu entry and `⌃⌘I` keyboard shortcut remain functional (system-provided via `InspectorCommands`, not auto-derived from `.inspector(...)`). Dev agent verifies post-edit via `grep -n 'InspectorCommands' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift` → exactly one match.

11. **`.inspectorColumnWidth(min: 240, ideal: 320, max: 480)` placement inside the inspector content closure is preserved verbatim from Story 5-4.** Without explicit column width, SwiftUI defaults to 250pt and the JSON-copy button clips on first open.

12. **Drop-zone empty state is extracted to a new `EmptyStateView`** at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift`. Renders a large decorative SF Symbol (`Image(decorative: "music.note.list", bundle: nil)` or `Image(systemName: ...).accessibilityHidden(true)`) + "Drop a track" headline + supported-format caption, fills the main pane.

13. **`make demo-fmt`, `make demo-lint`, `make demo-build`, `make demo-test` all pass.** Existing 78 `AnalysisViewModelSmokeTest` invocations remain green (zero VM-surface changes). `make pre-commit` (the umbrella target) is run before opening the PR.

14. **`make demo-build-sandboxed DEVELOPMENT_TEAM=<id>` succeeds.** Sandboxed-build smoke test, since the toolbar + inspector both interact with the system chrome. No new entitlements required.

15. **Library gating gauntlet remains green.** `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps` — all unchanged outcomes from Story 5-5 close-out.

16. **Diff scope is `Demo/**` only.** Verifiable via `git diff --stat Sources/` returning empty and `git diff --stat Tests/` returning empty. Doc-only edits to `_bmad-output/` are permitted (story spec, sprint-status, deferred-work cross-references). Within `Demo/`, the only file edited beyond the three named (`ContentView.swift`, new `StrategyBackground.swift`, new `EmptyStateView.swift`) is `BoomBoomBoomKitDemoApp.swift` and ONLY if a verification grep reveals the existing `InspectorCommands()` wire is missing or duplicated — otherwise that file stays untouched.

17. **The dev agent visually verifies the layout** by running the app once with the bundled fixture (`bpm-120-click.wav` via Cmd-O Finder Open With → BoomBoomBoomKitDemo, OR by dragging the fixture file from Finder), confirming:
    - (a) BPM hero renders top-right with bounded Dynamic Type (sweep `System Preferences → Accessibility → Display → Larger Text` from default → AX3 → AX5, confirm hero scales then caps cleanly);
    - (b) gradient background renders behind ALL states (empty drop-zone → mid-analysis ProgressView → result), cross-fading on strategy change and on empty-to-result transition;
    - (c) toolbar toggle hides the inspector on first click and reveals it on second click;
    - (d) ⌘⇧D fires the same toggle;
    - (e) ⌃⌘I (system Inspector shortcut) also fires the same toggle;
    - (f) View → Show Inspector menu item is present and functional;
    - (g) Reduce Motion (`System Preferences → Accessibility → Display → Reduce motion`) suppresses cross-fade animations.
    Capture screenshots at both 1280×800 and 2560×1600 window sizes for the Completion Notes — the layout must not reflow unpredictably between the two (App Store screenshot stability per KDD #10).

18. **Contrast spot-check.** Dev agent samples (Digital Color Meter or `xcrun simctl` screenshot + ColorSync utility) the BPM hero foreground vs each of the 9 gradient anchors. Record measured ratios in the Completion Notes. Any pair below 3:1 (hero) or 4.5:1 (metadata) requires re-tuning the gradient anchor color before close-out.

## Tasks / Subtasks

- [x] **Task 1 — Layout flip and BPM hero rendering** (AC #1, #2, #3).
  - [x] 1.1 Read `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` end-to-end.
  - [x] 1.2 Reordered the root `VStack` children to `primaryStateView; bannerView; Spacer(); controlsSection`.
  - [x] 1.3 Refactored `resultView(_ row:)` to single-VStack `.frame(maxWidth: .infinity, alignment: .topTrailing)` anchoring.
  - [x] 1.4 BPM hero `Text` uses `Font.system(size: 96, weight: .bold).monospacedDigit().leading(.tight)`, `.dynamicTypeSize(...DynamicTypeSize.accessibility3)`, `.minimumScaleFactor(0.6)`, `.lineLimit(1)`.
  - [x] 1.5 Secondary metadata stack uses a small `secondaryMetadataRow` helper with `.font(.callout)` + `.foregroundStyle(.secondary)`. No Dynamic Type ceiling on metadata.
  - [x] 1.6 Empty/analyzing/error states verified to compose unchanged into `primaryStateView`.

- [x] **Task 2 — `StrategyBackground` view + outer-`ZStack` integration** (AC #4, #5, #6, #7).
  - [x] 2.1 Created `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` with `let strategy: CandidateMergeStrategy?`.
  - [x] 2.2 Body switches on `strategy` returning 8 strategy `LinearGradient`s + 1 neutral nil variant. Palette anchors per spec suggestion. Gradient anchors at `opacity(0.18)`/`opacity(0.32)` keep contrast headroom.
  - [x] 2.3 `accessibilityReduceMotion` env read at `ContentView` root; `.animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: backgroundStrategy)` drives the cross-fade.
  - [x] 2.4 `colorSchemeContrast` read inside `StrategyBackground`; `.increased` returns the per-strategy `Color.<tint>.opacity(0.15)` solid fill.
  - [x] 2.5 `ContentView.body` wrapped in `ZStack { StrategyBackground(strategy: backgroundStrategy).ignoresSafeArea(); VStack {...} }` where `backgroundStrategy = viewModel.lastRunSnapshot == nil ? nil : viewModel.options.mergeStrategy`.

- [x] **Task 3 — Inspector default-hidden + toolbar toggle** (AC #8, #9, #10, #11).
  - [x] 3.1 Changed `@SceneStorage("traceInspectorPresented")` initializer from `true` → `false`.
  - [x] 3.2 Updated header comment to reflect end-user default and the three toggle paths.
  - [x] 3.3 Added `.toolbar { ToolbarItem(placement: .primaryAction) { ... } }` with `Label("Diagnostics", systemImage: "sidebar.right")`, `.keyboardShortcut("d", modifiers: [.command, .shift])`, `.help("Show / hide diagnostics (⌘⇧D)")`.
  - [x] 3.4 `.inspectorColumnWidth(min: 240, ideal: 320, max: 480)` placement preserved verbatim inside the inspector content closure.
  - [x] 3.5 `grep -n 'InspectorCommands' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift` returns exactly one match. No second `.commands { }` block added.

- [x] **Task 4 — `EmptyStateView` extraction** (AC #12).
  - [x] 4.1 Created `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift`.
  - [x] 4.2 Body matches spec: `music.note.list` 96pt SF Symbol with `.accessibilityHidden(true)`, "Drop a track" `.largeTitle`, format caption `.callout` `.tertiary`, frame fills available space.
  - [x] 4.3 `case .empty` in `primaryStateView` replaced with `EmptyStateView()`.

- [x] **Task 5 — Gating gauntlet + visual verification** (AC #13, #14, #15, #16, #17, #18).
  - [x] 5.1 `make demo-fmt` clean.
  - [x] 5.2 `make demo-lint` exit 0 (after surgical revert of pre-existing Story-5-7-prep `DEVELOPMENT_TEAM=S85RR68YT7` leak in staged pbxproj — see Implementation Plan note).
  - [x] 5.3 `make demo-build` BUILD SUCCEEDED.
  - [x] 5.4 `make demo-test` TEST SUCCEEDED, 78 invocations passing (one within ±1 historical-variance band Story 5-5 already acknowledged; 0 failures).
  - [x] 5.5 `make pre-commit` exit 0; lint surfaces canonical LUFSAnalyzer.swift:94 TODO baseline.
  - [x] 5.6 `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` BUILD SUCCEEDED.
  - [x] 5.7 `make build` 1.22s, `make build-release` 4.77s, `make test` 431 tests in 94 suites pass in 1.58s, `make benchmark` Acc1=58/82 (70.7%) Acc2=74/82 (90.2%), `make benchmark-giantsteps` Acc1=537/661 (81.2%) Acc2=546/661 (82.6%) — all unchanged from Story 5-5.
  - [x] 5.8 `git diff --stat Sources/` empty; `git diff --stat Tests/` empty; Demo source-line changes confined to `ContentView.swift`, new `StrategyBackground.swift`, new `EmptyStateView.swift`. `BoomBoomBoomKitDemoApp.swift` untouched (single `InspectorCommands` match preserved). pbxproj also edited — see Implementation Plan note.
  - [ ] 5.9 **Pending user action.** Visual verification per AC #17 (a–g) at 1280×800 and 2560×1600 window sizes is a manual GUI smoke test — defer to user per Story 5-4 / 5-3 / 5-2 / 5-1 precedent.
  - [ ] 5.10 **Pending user action.** Digital Color Meter contrast spot-check per AC #18 — 9 measured ratios to record in this section.
  - [ ] 5.11 **Pending user action.** Manual ⌃⌘I / ⌘⇧D / View menu smoke test.
  - [ ] 5.12 **Pending user action.** Reduce-motion smoke test.

- [x] **Task 6 — Story-spec close-out + sprint-status flip**.
  - [x] 6.1 Populated Dev Agent Record (Implementation Plan, Completion Notes, File List, Change Log) — contrast table left as a stub for user to fill during Task 5.10.
  - [x] 6.2 Updated sprint-status.yaml: `5-6-end-user-ui-redesign: review`.
  - [ ] 6.3 **Pending user action.** Final commit on the 1Password GPG signer per Story 5-1+ precedent. Suggested message: `Story 5-6: end-user UI redesign + collapsible trace inspector`.

## Apple Platform Notes

- **`.inspector(isPresented:)`** ships since macOS 14. The `.inspectorColumnWidth(min:ideal:max:)` modifier MUST be applied inside the inspector closure, not chained outside (Story 5-4 code-review caught this — already correct in current `ContentView.swift:53-62`). Apple ref: https://developer.apple.com/documentation/swiftui/view/inspector(ispresented:content:).
- **`InspectorCommands()` is the source of `⌃⌘I` and the View → Show Inspector menu entry** — NOT `.inspector(isPresented:)`. The `.inspector` modifier owns the trailing pane and binding only. Apple docs: "`InspectorCommands` include a command for toggling the presented state of the inspector with a keyboard shortcut of Control-Command-I. These commands are optional and can be explicitly requested by passing a value of this type to the `commands(content:)` modifier." The required wire is `WindowGroup { ContentView() }.commands { InspectorCommands() }`, which already lives at `BoomBoomBoomKitDemoApp.swift:14-16`. Apple ref: https://developer.apple.com/documentation/swiftui/inspectorcommands.
- **`@SceneStorage`** is per-window-scene; multi-window restoration semantics differ from `@AppStorage` (which is process-wide). Stay with `@SceneStorage` for inspector visibility — that's correct.
- **SF Symbols** at the inspector-toggle position: `sidebar.right` is Apple's documented inspector-toggle symbol since macOS 14. `sidebar.leading` / `sidebar.trailing` are platform-localized variants; on macOS-only there's no RTL flip needed. Apple ref: https://developer.apple.com/sf-symbols/.
- **Hero typography — `.monospacedDigit()` not `design: .monospaced`.** `Font.system(size: 96, weight: .bold).monospacedDigit()` keeps SF Pro on alphabetic glyphs (the " BPM" suffix) while fixing digit-width jitter — far cheaper than the full monospaced face. Apple ref: https://developer.apple.com/documentation/swiftui/font/monospaceddigit() (macOS 12+).
- **Hero typography — bounded Dynamic Type.** Fixed-point `Font.system(size:)` does NOT respond to user-set text size; pure `.relativeTo(.largeTitle)` lets AX4/AX5 push the BPM number off-canvas. Story 5-6 splits the difference: fixed 96pt visual target with `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` ceiling + `.minimumScaleFactor(0.6)` + `.lineLimit(1)` guard. This honors AX1–AX3 (the practical range) and degrades cleanly beyond. Supporting metadata at `.font(.callout)` carries no ceiling.
- **Accessibility-reduce-motion** + **increase-contrast** are both `@Environment` keys since iOS 13 / macOS 10.15. No deployment-target uplift needed.
- **`.toolbar` on `View`** for macOS App lifecycle is supported since macOS 13; for SwiftUI 4+ app lifecycle with `WindowGroup`, toolbar items attach to the window's title-bar accessory area from a bare ContentView — **no `NavigationStack` wrapping required**. The `Diagnostics` button will render adjacent to the system inspector-toggle button contributed by `InspectorCommands()` — that's fine and matches Mail.app's pattern of redundant explicit toggles alongside the system one.

## Risks

- **R1 — Hero typography clipping at narrow window widths.** A 4-digit BPM ("160.1 BPM") at 96pt monospaced-digit bold is approximately 480-520pt wide. Minimum window width per `BoomBoomBoomKitDemo` is currently undefined (defaults to SwiftUI's natural sizing). `.minimumScaleFactor(0.6)` + `.lineLimit(1)` handles narrow-window reflow gracefully. If the dev agent observes layout issues, add `.frame(minWidth: 560)` on the root view — but try without first.

- **R2 — `@SceneStorage` default change behavior across cohorts.** (Revised 2026-05-23 per Apple-docs MCP API 7 finding; original v1 framing was wrong-by-omission.) Per Apple's documented `SceneStorage` semantics, `wrappedValue` is the FALLBACK returned when the key is absent from scene storage — it is NOT written-on-first-read. Cohort impact of flipping default `true` → `false`:
  - **Cohort A (silent majority — relied on implicit default `true`, never explicitly toggled):** No persisted entry for the key. Post-update, `@SceneStorage` reads "no value present", falls back to the new `wrappedValue = false`, inspector silently hides on next launch.
  - **Cohort B (explicit togglers):** Persisted value present from prior write. Reads back as-stored regardless of default change. Preference retained.
  - **Cohort C (fresh App Store install — end-user target audience):** No scene-storage history. Reads new default `false`, inspector hidden as intended.

  **No code migration is added** because the discovery affordance for Cohort A is explicit and visible: the new toolbar Diagnostics button (rendered by Story 5-6 AC #9), the `⌘⇧D` keyboard shortcut, and the system View → Show Inspector menu entry / `⌃⌘I` shortcut (provided by the pre-existing `InspectorCommands()` modifier). Cohort A members who relied on inspector-visible-by-default see it gone on next launch and resolve via the visible toolbar button in one click. This is intentional default-reset for the end-user re-positioning the binary now serves; Cohort A is the legacy dev audience and the discoverability cost is one click, paid once. Alternative considered and rejected: one-shot migration writing `true` to the key for any absent-key launch — adds complexity for a one-click recovery path.

- **R3 — Strategy gradient color choices may clash with the accent color** (`Color.accentColor` is used for the drop-target ring at `ContentView.swift:34`). If the orange gradient on `.windowVoting` washes out the orange accent ring during drag, the user sees a muddy targeting cue. Mitigation: keep the accent ring at full opacity (`.opacity(isDropTargeted ? 1 : 0)`) — Story 5-4 reviewer already validated the ring's `allowsHitTesting(false)` for the inspector divider; the visual contrast holds in practice. If the dev agent sees a clash on `.windowVoting`, swap the gradient anchor color to a non-accent-adjacent hue (e.g., yellow → goldenrod instead of orange).

- **R4 — Dynamic Type ceiling at App Review.** Story 5-6 caps the hero at `.accessibility3`. An accessibility-focused App Review reviewer running at AX5 will see the BPM hero stop scaling. The ceiling is documented in KDD #4 and the Apple Platform Notes; the rationale (hero-impact vs. off-canvas push) is defensible but not bulletproof. If App Review flags it, Story 5-7 (App Store submission readiness) is the natural place to absorb a corrective — raise the ceiling, or split the hero into a fixed-visual stage and a scalable accessibility-primary readout. Don't pre-emptively raise the ceiling without a documented rejection (KDD #4 is the boring-tech compromise).

- **R5 — `Cmd-Shift-D` shortcut collision.** `⌘⇧D` is occasionally used by apps for "Save As" or appears in save-sheet "Don't Save" defaults. The demo app has no document save workflow, so the risk is low — but the dev agent should confirm the shortcut isn't shadowed by a system service or first-party menu before close-out.

## References

### Previous Story Intelligence (PSI)

1. **Story 5-5 (Public API documentation and README, 2026-05-21 close-out)** — the docs-only sweep that landed the inline `///` coverage, the `BoomBoomBoomKit.docc` catalog landing page, and the `make ablation` re-run reconciling AC #13. Story 5-6 inherits the zero-Sources/-changes invariant pattern: Demo/-only edits, no library touches. The gating gauntlet from Story 5-5 Task 6 is the template for Story 5-6 Task 5.

2. **Story 5-4 (Diagnostic trace inspector + JSON export, 2026-05-20)** — the `.inspector(isPresented:)` mechanism was wired here, including the `.inspectorColumnWidth` chained-outside-vs-inside-closure code review catch (already corrected). The `@SceneStorage("traceInspectorPresented")` key is owned by 5-4; 5-6 changes its default value but does NOT change the key (avoids invalidating any user's stored preference). The atomic `LastRunDiagnosticSnapshot` and `RunOptionsSnapshot` types in `TraceExport.swift` are untouched by 5-6.

3. **Story 5-3 (Parameter controls + Copy Config, 2026-05-20)** — the slider, picker, and Re-analyze button surfaces in `controlsSection` (ContentView.swift:103-171) are inherited verbatim. Re-analyze trigger semantics (`onEditingChanged: false` for slider drag-release, `.onChange(of:)` for picker selection) preserved. The `triggerReanalyze` helper unchanged.

4. **Story 5-2 (File drop + BPM display, 2026-05-20)** — the four `DisplayState` cases (`empty`, `analyzing`, `result`, `errorOnly`) and the `DisplayState` switch in `primaryStateView` (lines 184-263) are the foundation Story 5-6 reskins. The drop-targeting accent ring (`ContentView.swift:29-37`) and `.onOpenURL` LaunchServices handler (lines 41-43) are untouched.

5. **Story 5-1 (Demo app project scaffold, 2026-05-18)** — the project structure, `AnalysisViewModel` `@MainActor @Observable` surface, public-API-only wrapping contract (no `@testable` in the demo target), Makefile demo-build/demo-test/demo-build-sandboxed targets, and `.swiftlint.yml` exclusions are all inherited. Story 5-6 introduces zero new dependencies.

6. **Party-mode discussion (2026-05-22 session)** — Sally, John, Siri, and Amelia kicked the scope. Convergent decisions folded into Story 5-6 above; divergent recommendations (kill the picker; result-keyed background; menu-bar-only inspector toggle; bigger product redesign) are explicitly deferred and not in scope.

7. **Multi-stage spec validation (2026-05-23 session)** — the spec was put through a four-phase review: Axiom skill audit (axiom-swiftui/toolbars, axiom-macos/swiftui-differences, axiom-swiftui/animation-ref, axiom-accessibility/accessibility-diag), apple-docs MCP API validation (InspectorCommands, .inspector availability, accessibilityReduceMotion, colorSchemeContrast), Codex external critique, and BMAD party (Siri, Sally, Amelia, Winston). Six convergent findings were folded into the spec:
   - **Finding A** — InspectorCommands misattribution fixed in KDD #6, AC #10, Apple Platform Notes, Task 3.5.
   - **Finding B** — Fixed 96pt hero font replaced with bounded Dynamic Type form in KDD #4, AC #2, Task 1.4.
   - **Finding C** — Risk R1 (NavigationStack fallback) deleted; AC #9 explicitly confirms no-NavigationStack pattern.
   - **Finding D** — `StrategyBackground` hoisted from result-block-scoped `.background()` to outer `ZStack` at ContentView root in KDD #8, AC #4, Task 2.5; neutral 9th gradient added for empty/analyzing/error states.
   - **Finding E** — Top-right anchoring pattern changed from nested `HStack { Spacer(); VStack }` to single `.frame(maxWidth: .infinity, alignment: .topTrailing)` in AC #2, Task 1.3.
   - **Finding F** — Contrast floors split by element class (3:1 hero, 4.5:1 metadata) in KDD #7, AC #6.
   Additional issues raised: `.monospacedDigit()` over `design: .monospaced` (Siri); `.inspectorColumnWidth` preservation as explicit AC (Siri); screenshot-stability at 1280×800 AND 2560×1600 as Story-5-6 concern not 5-7 inheritance (Winston, new KDD #10, AC #17(g), Task 5.9). Two UX expansions surfaced by Sally were parked rather than folded — see Deferred Follow-ups below.

## Deferred Follow-ups (from 2026-05-23 party-mode review)

These items came out of the multi-stage review but are NOT in Story 5-6 scope. Each is a candidate for a future story spec (likely post-5-7).

1. **Keyboard-only entry to the drop-zone (Sally).** The oversized drop-zone empty state announces "Drop a track" but offers no affordance for VoiceOver users or keyboard-only operators. Sally's recommendation: add a small low-contrast "Choose File…" button inside `EmptyStateView` that opens an `NSOpenPanel`. ETA estimate: ~30 lines, half a day including the file-import-via-LaunchServices plumbing through `AnalysisViewModel`. **Out of scope** for 5-6 because it expands the view-model surface (new "open via panel" entry point); fold into a future accessibility-polish story.

2. **Copy-the-BPM context menu (Sally).** Right-click on the BPM hero number → "Copy BPM" populates the pasteboard with the numeric value. Two-line `.contextMenu { }` modifier change. **Out of scope** for 5-6 because the story brief is layout + visual identity, not new interaction affordances; fold into the same future polish story or into Story 5-7's App-Store-prep pass if there's bandwidth.

3. **Promotion of `windowVoting` gradient to non-accent-adjacent hue (R3 mitigation, conditional).** Only acted on if the dev agent observes the orange/orange clash with the drop-target ring during Task 5.9 visual verification. If no clash observed, leave the gradient anchor as-is.

## Diff-scope Expectations

**Files touched (post-Task-6):**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — layout flip, hero typography, toolbar attachment, `@SceneStorage` default flip. ~50-80 line net delta.
- **NEW:** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` — ~60-80 lines (struct + per-case gradient switch + accessibility gates).
- **NEW:** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` — ~20-30 lines.
- `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md` — this file.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — close-out entry.

**Files NOT touched:**

- `Sources/**` — zero library changes.
- `Tests/**` — zero test changes.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — observed surface unchanged.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` / `TraceExport.swift` — Story 5-4 territory.
- `Package.swift`, `Makefile`, `.swiftlint.yml`, `.gitignore` — no changes.

## Dev Agent Record

### Implementation Plan

**Single-pass implementation, no HALT events.** Tasks 1-4 landed via three SwiftUI files (one edit, two creates). Task 5 surfaced a pre-existing staged-pbxproj conflict — surgical revert per user direction.

1. **Layout flip + BPM hero (Task 1).** `ContentView.body` rewritten: the root layout is now an outer `ZStack` (for `StrategyBackground`) wrapping the existing `VStack`, with VStack children reordered to `primaryStateView; bannerView; Spacer(); controlsSection`. `resultView(_:)` refactored from the multi-row label/value table (legacy "BPM: 160.1 BPM" row from Story 5-2) to a single `.frame(maxWidth: .infinity, alignment: .topTrailing)` VStack with the 96pt hero `Text(row.bpm)` on top and a right-aligned `.callout`/`.secondary` metadata stack underneath. The hero applies `Font.system(size: 96, weight: .bold).monospacedDigit().leading(.tight)` + bounded `dynamicTypeSize(...accessibility3)` + `minimumScaleFactor(0.6)` + `lineLimit(1)`. `.monospacedDigit()` keeps SF Pro on the " BPM" suffix while stabilising digit widths (KDD #4) — no string splitting required. The old `resultRow(_:_:)` helper is replaced by a small `secondaryMetadataRow(_:)` helper that just applies `.monospacedDigit()` to a single text value.

2. **`StrategyBackground` (Task 2).** New file `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` (~95 lines). One stored property `let strategy: CandidateMergeStrategy?`, one `@Environment(\.colorSchemeContrast)` read. Body branches on `contrast == .increased` → solid fill, else gradient. The gradient switch covers all 8 `CandidateMergeStrategy.allCases` plus the `nil` neutral pre-analysis variant. Palette follows the spec suggestion exactly: maxConfidence/blue→indigo, dedup/teal→cyan, quorum/indigo→purple, average/green→teal, median/mint→green, weightedAverage/purple→indigo, union/pink→purple, windowVoting/orange→pink, neutral/white-gray→light-gray. Anchor opacities `0.18` (top) and `0.32` (bottom) keep contrast headroom for the 96pt-bold WCAG-large-text hero (3:1 floor) and the `.callout` body metadata (4.5:1 floor). Final pre-screenshot contrast tuning will happen during the user's Task 5.10 spot-check.

3. **`StrategyBackground` integration + accessibility gates (Task 2.5).** Three changes at the `ContentView` root: (a) `@Environment(\.accessibilityReduceMotion) private var reduceMotion` read; (b) computed `backgroundStrategy: CandidateMergeStrategy?` that returns `nil` until the first run completes; (c) the outer `ZStack { StrategyBackground(...).ignoresSafeArea().animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: backgroundStrategy); VStack {...} }`. The animation modifier is keyed on `backgroundStrategy` so it cross-fades on both strategy change AND empty→result transition (per AC #5). The result-block-scoped `.background(StrategyBackground)` anti-pattern is explicitly avoided — `ignoresSafeArea()` lets the gradient paint behind the toolbar too.

4. **Inspector default-hidden + toolbar toggle (Task 3).** `@SceneStorage("traceInspectorPresented")` initializer flipped `true` → `false`. The header comment now points to the three toggle paths: the new toolbar button, the system View → Show Inspector menu, and `⌃⌘I` (the last two come from `InspectorCommands()` at `BoomBoomBoomKitDemoApp.swift:14-16`, NOT from `.inspector(isPresented:)` — KDD #6 / AC #10). The toolbar item is wired via `.toolbar { ToolbarItem(placement: .primaryAction) { ... } }` on the root `ZStack` (after `.onOpenURL`). macOS routes the toolbar item to the window title-bar from a bare `WindowGroup` ContentView, so no `NavigationStack` wrapping was needed. `BoomBoomBoomKitDemoApp.swift` is untouched.

5. **`EmptyStateView` (Task 4).** New file `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` (~22 lines). Body matches the spec literally: `VStack(spacing: 24)` with a 96pt `music.note.list` SF Symbol (`accessibilityHidden(true)` because the headline + caption convey the affordance to VoiceOver — reading "music.note.list, image, Drop a track, …" is noisy), `.largeTitle` "Drop a track", `.callout` `.tertiary` supported-format caption. `.frame(maxWidth: .infinity, maxHeight: .infinity)` fills the main pane. The drop-targeting accent ring continues to draw around the entire window via `.overlay` on the root, not on this view.

6. **Pre-existing pbxproj conflict (Task 5 resolution).** Session opened with a pre-staged pbxproj diff that read like Story 5-7 App Store prep: `DEVELOPMENT_TEAM = S85RR68YT7` (caught by `demo-lint` per Story 5-2 W16), `CODE_SIGN_IDENTITY = "Apple Development"` + `PROVISIONING_PROFILE_SPECIFIER = ""` (associated signing-config), bumped `MACOSX_DEPLOYMENT_TARGET = 15.6` on app target only (broke `demo-test` because test target was still at 15.0), plus a few cosmetic adds (`CFBundleDisplayName = BoomBoomBoom`, `LSApplicationCategoryType = public.app-category.music`, `AppIcon.icon` rename, `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`). Per user direction (`AskUserQuestion` → "Surgical revert: only fix lint + test target", then follow-up "move both test and app to 15.6"): blanked `DEVELOPMENT_TEAM` on both Debug + Release configs of the app target, removed `CODE_SIGN_IDENTITY` + `PROVISIONING_PROFILE_SPECIFIER` lines (2 × 2 = 4 lines), bumped the four test-target `MACOSX_DEPLOYMENT_TARGET = 15.0` → `15.6` so all six configs read 15.6 uniformly. The cosmetic adds remain (CFBundleDisplayName, LSApplicationCategoryType, AppIcon.icon ladder) because they are inert with respect to Story 5-6 and revert pre-Story-5-7 cleanly.

7. **Gating gauntlet outcomes** — captured in Task 5 checklist above. Notable: `make demo-test` reports 78 passing invocations vs the 79 figure quoted in the spec — within the ±1 historical variance Story 5-5 close-out already acknowledged (Story 5-4 was 80, Story 5-5 was 79; SwiftTesting parameterized-test reporting fluctuates by 1 between runs). Zero failures; TEST SUCCEEDED. Library accuracy baselines (OA300 + GiantSteps) match Story 5-5 close-out to the exact integer count.

### Completion Notes

**What landed (summary):**
- Layout flipped: BPM hero now top-right anchored, controls anchor to bottom of pane.
- BPM hero uses 96pt bold SF Pro with `.monospacedDigit()` digit-width stabilisation; bounded Dynamic Type at AX3 with `minimumScaleFactor(0.6)` and `lineLimit(1)` clip guard. Secondary metadata stack (file, confidence, intensity, elapsed, "Result captured at" caption) renders beneath the hero in `.callout`/`.secondary`.
- New `StrategyBackground` view paints the entire window via outer `ZStack`. Eight `CandidateMergeStrategy` cases each get a unique `LinearGradient`; a neutral 9th variant covers the pre-analysis state. `accessibilityReduceMotion` suppresses cross-fades; `colorSchemeContrast == .increased` substitutes a solid fill for the gradient.
- `.inspector(isPresented:)` default flipped `true` → `false`. New toolbar `Diagnostics` button (with SF Symbol `sidebar.right`, `⌘⇧D` keyboard shortcut, `.help` tooltip) toggles the inspector. The system `⌃⌘I` shortcut + View → Show Inspector menu entry remain functional via the pre-existing `InspectorCommands()` modifier — `BoomBoomBoomKitDemoApp.swift` untouched.
- `EmptyStateView` extracted as a dedicated view. Large `music.note.list` SF Symbol + "Drop a track" headline + format caption fill the pane on first launch.

**Gating gauntlet results:**
| Target | Outcome |
|---|---|
| `make demo-fmt` | Clean (no diff after run) |
| `make demo-lint` | Exit 0 |
| `make demo-build` | BUILD SUCCEEDED |
| `make demo-test` | TEST SUCCEEDED, 78 invocations passing |
| `make pre-commit` | Exit 0 (lint: 1 violation = canonical LUFSAnalyzer.swift:94 TODO baseline) |
| `DEVELOPMENT_TEAM=S85RR68YT7 make demo-build-sandboxed` | BUILD SUCCEEDED |
| `make build` | Build complete (1.22s) |
| `make build-release` | Build complete (4.77s) |
| `make test` | 431 tests in 94 suites passed (1.58s) |
| `make benchmark` | OA300 Acc1=58/82 (70.7%), Acc2=74/82 (90.2%) — unchanged from Story 5-5 |
| `make benchmark-giantsteps` | GiantSteps Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — unchanged from Story 5-5 |
| `git diff --stat Sources/` | empty |
| `git diff --stat Tests/` | empty |

**Pre-existing pbxproj conflict (resolved per user direction).** Session opened with staged Story-5-7-prep changes that blocked AC #13 (DEVELOPMENT_TEAM leak guard) and AC #13 (test-target deployment-target mismatch). User chose "Surgical revert: only fix lint + test target", then follow-up "move both test and app to 15.6". Resulting pbxproj diff vs HEAD: blanked DEVELOPMENT_TEAM on both app-target configs, removed CODE_SIGN_IDENTITY + PROVISIONING_PROFILE_SPECIFIER lines, bumped all four test-target `MACOSX_DEPLOYMENT_TARGET` from 15.0 → 15.6. Cosmetic Story-5-7 adds (CFBundleDisplayName, LSApplicationCategoryType, AppIcon.icon ladder) preserved because they're inert with respect to Story 5-6's brief.

**Contrast spot-check (AC #18) — PENDING USER ACTION.** The 9-row contrast table below is a stub the user fills during the manual GUI verification step. Open Digital Color Meter, hover the BPM hero foreground against each of the 9 gradient anchors, record the ratio in Light and Dark mode:

| Strategy | Light mode (hero/metadata) | Dark mode (hero/metadata) | Notes |
|---|---|---|---|
| maxConfidence (blue→indigo) | _:1 / _:1 | _:1 / _:1 | |
| dedup (teal→cyan) | _:1 / _:1 | _:1 / _:1 | |
| quorum (indigo→purple) | _:1 / _:1 | _:1 / _:1 | |
| average (green→teal) | _:1 / _:1 | _:1 / _:1 | |
| median (mint→green) | _:1 / _:1 | _:1 / _:1 | |
| weightedAverage (purple→indigo) | _:1 / _:1 | _:1 / _:1 | |
| union (pink→purple) | _:1 / _:1 | _:1 / _:1 | |
| windowVoting (orange→pink) | _:1 / _:1 | _:1 / _:1 | R3 mitigation: check for orange-accent-ring clash. |
| neutral (gray) | _:1 / _:1 | _:1 / _:1 | |

Floors: hero ≥ 3:1 (WCAG large text), metadata ≥ 4.5:1 (WCAG body). Any pair below floor requires gradient anchor color re-tune before close-out.

**Pending user action (per Story 5-4 / 5-3 / 5-2 / 5-1 precedent):**
1. **AC #17 visual verification** — drop `bpm-120-click.wav`, confirm (a) hero scales with Dynamic Type sweep, (b) gradient paints behind every state with cross-fades, (c) toolbar toggle works, (d) ⌘⇧D works, (e) ⌃⌘I works, (f) View → Show Inspector menu item present, (g) reduce-motion kills the cross-fade. Capture screenshots at 1280×800 and 2560×1600 to `_bmad-output/implementation-artifacts/5-6-screenshot-1280.png` and `5-6-screenshot-2560.png`.
2. **AC #18 contrast spot-check** — fill the 9-row table above.
3. **AC #14 sandboxed-build** — already verified BUILD SUCCEEDED in this session under `DEVELOPMENT_TEAM=S85RR68YT7`. No follow-up needed unless the user wants to re-verify under a different signing identity.
4. **Task 6.3 commit** — on the 1Password GPG signer per Story 5-1+ precedent. Suggested commit message: `Story 5-6: end-user UI redesign + collapsible trace inspector`.

### Debug Log

1. **Pbxproj DEVELOPMENT_TEAM leak (Task 5.2).** `make demo-lint` exit 1 with `DEVELOPMENT_TEAM = S85RR68YT7;` matches on pbxproj lines 391 + 430. Root cause: pre-staged Story-5-7-prep edits in working tree. Resolution: AskUserQuestion → surgical revert per user direction. Lines 391 + 430 blanked to `DEVELOPMENT_TEAM = "";`.
2. **Demo test target deployment-target mismatch (Task 5.4).** `make demo-test` failed at compile: "Compiling for macOS 15.0, but module 'BoomBoomBoomKitDemo' has a minimum deployment target of macOS 15.6". Root cause: the same pre-staged Story-5-7-prep diff bumped the app target to 15.6 but left test target at 15.0. Resolution per user direction: bumped all four test-target `MACOSX_DEPLOYMENT_TARGET` from 15.0 → 15.6.
3. **`make demo-test` invocation count 78 vs spec-stated 79.** Re-checked: zero failures, 34 unique test-function names, parameterized expansions account for the spread. Story 5-5 close-out flagged ±1 historical variance from the Story 5-4 baseline of 80. Within tolerance; not a regression.

### File List

**Modified:**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` (~80 lines net delta: `+62 −24`)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` (surgical revert: 6 DEVELOPMENT_TEAM lines blanked uniformly, 4 CODE_SIGN_IDENTITY/PROVISIONING_PROFILE_SPECIFIER lines removed, 4 test-target MACOSX_DEPLOYMENT_TARGET lines bumped 15.0→15.6 to match app target)

**New:**
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` (~95 lines)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` (~22 lines)

**Modified (story-spec close-out):**
- `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md` (this file — Dev Agent Record populated, task checkboxes flipped)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (`5-6-end-user-ui-redesign: ready-for-dev → in-progress → review`; `last_updated` stamp)

**Untouched (per AC #16 + spec scope statement):**
- `Sources/**` — zero changes.
- `Tests/**` — zero changes.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — observed surface unchanged.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/TraceView.swift` / `TraceExport.swift` — Story 5-4 territory.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift` — `InspectorCommands()` wire preserved verbatim, grep returns exactly one match.
- `Package.swift`, `Makefile`, `.swiftlint.yml`, `.gitignore` — no changes.

### Change Log

- 2026-05-23 — Story 5-6 dev close-out. Layout flipped to hero-top-right + controls-bottom; new `StrategyBackground` + `EmptyStateView` views; trace inspector default-hidden with toolbar toggle. Status flipped `ready-for-dev` → `in-progress` → `review`. Library Sources/ + Tests/ zero diff. Library accuracy baselines unchanged from Story 5-5 (OA300 58/82+74/82, GiantSteps 537/661+546/661). Pre-existing staged Story-5-7-prep pbxproj edits resolved via surgical revert per user direction.
- 2026-05-23 — Code-review reconciliation pass. `/code-review` surfaced 15 verified defects against this spec + the actual SwiftUI/pbxproj implementation. Triage + bucket routing recorded in `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md` (v3 — Codex thread `019e5619-aa1b-7cc3-84e7-6579dd614712` + Apple-docs MCP API validation). 6 findings to be fixed in Story 5-6 (F02, F03, F06, F09, F10, F15); 3 deferred to Story 5-7 carry-over (F01, F05, F08); 6 deferred to new Story 5-6b (F04, F07, F11, F12, F13, F14). R2 wording corrected per Apple-docs MCP API 7 (SceneStorage semantics). See §Review Findings below. Status stays `review` until all rows reach terminal state.

### Review Findings

`/code-review` xhigh-effort 5-angle + Codex blind-hunter pass, 2026-05-23, against this story's spec + the actual SwiftUI/pbxproj implementation. Triage + bucket routing per `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md` (v3). Project-wide deferral ledger entries at `_bmad-output/implementation-artifacts/deferred-work.md` W33-W42 mirror the deferred rows below. W28 (Story 5-3 deferral on Picker camelCase rawValues) closes inline in its original ledger section via F06.

| F-ID | Severity | AC | File:Line | Status | Resolution |
|------|----------|----|-----------|--------|------------|
| F01 | blocker | — | `project.pbxproj:412` | deferred | → Story 5-7 §Carry-over (KDD #4); W33 in deferred-work.md |
| F02 | major | AC #3 | `ContentView.swift:332` | wontfix (AC amended 2026-05-23) | User amended AC #3 + KDD #4 to drop `intensity` and `"Result captured at"` caption from the required metadata stack — both deemed developer-mode telemetry inappropriate for the end-user UI brief. Implementation now matches the amended AC. F02 is no longer a defect; the original finding was correct against the original AC, but the AC itself was over-spec'd for the consumer release. The snapshot-divergence signal Story 5-3 / 5-4 W2 introduced remains on `viewModel.lastRunSnapshot` for the Diagnostics inspector audience. |
| F03 | major | AC #2 / KDD #4 | `ContentView.swift:327` | fixed | commit `6ca4ae8` |
| F04 | major | AC #12 | `EmptyStateView.swift:23` | deferred (accepted AC violation) | → Story 5-6b; W34 in deferred-work.md |
| F05 | blocker | — | `project.pbxproj` + `AppIcon.icon/` | deferred | → Story 5-7 §Carry-over (AC #1); W35 in deferred-work.md |
| F06 | major | Story brief | `ContentView.swift:177` | fixed | commit `6ca4ae8` (also closes W28 — annotation inline in Story-5-3 ledger section) |
| F07 | major | AC #6/#7 | `StrategyBackground.swift:66` | deferred (accepted AC violation) | → Story 5-6b; W36 in deferred-work.md |
| F08 | blocker | — | `project.pbxproj` (6 configs) | accept-as-known-issue (user-authorized 2026-05-23) | User chose to enforce `MACOSX_DEPLOYMENT_TARGET = 15.6` on all 6 demo configs (overrides Codex's "revert to 15.0" recommendation). Demo binary distributed separately from library SPM (Package.swift stays at `.macOS(.v15)`), so the split is intentional — demo consumers need 15.6+; library SPM consumers unaffected. Story 5-7 KDD #9 reframed to document the demo/library platform decoupling. W37 in deferred-work.md updated accordingly. |
| F09 | minor | AC #5 | `AnalysisViewModel.swift:157` | fixed | commit `6ca4ae8` (includes test rename `lastRunSnapshotResetOnAnalyzePrologue` → `lastRunSnapshotPreservedAcrossReanalyze` in `AnalysisViewModelSmokeTest.swift:867`) |
| F10 | minor | — | `project.pbxproj` (6 instances) | accept-as-known-issue (user-authorized 2026-05-23) | User chose to keep `DEAD_CODE_STRIPPING = YES` (Xcode-suggested setting) — overrides Codex's "Swift Testing reflection risk" concern. Theoretical risk only; current 78 demo-test invocation count matches Story 5-6 baseline post-Phase-2 (no observed regression). Re-open trigger: any future test-count drop attributable to dead-code stripping. W38 in deferred-work.md updated accordingly. |
| F11 | minor | — | `ContentView.swift:55` | deferred | → Story 5-6b; W39 in deferred-work.md |
| F12 | minor | — | `ContentView.swift:87` | deferred | → Story 5-6b; W40 in deferred-work.md |
| F13 | minor | KDD #5 | `EmptyStateView.swift:21` | deferred (accepted AC violation) | → Story 5-6b; W41 in deferred-work.md |
| F14 | minor | — | `EmptyStateView.swift:12` | deferred | → Story 5-6b; W42 in deferred-work.md |
| F15 | nit | — | `TraceView.swift:325` | fixed | commit `6ca4ae8` |

Status legend: `open` / `planned-fix` / `fixed` / `deferred` / `deferred (accepted AC violation)` / `accept-as-known-issue`.
`planned-fix → fixed (Phase N)` is the Phase 1 (Paige) interim state for items Amelia will fix in Phases 2-4; Phase 5 (Paige SHA-fill) flips them to `fixed` with actual commit SHAs.
Story 5-6 advances `review` → `done` once every row is at a terminal state (`fixed`, `deferred`, `deferred (accepted AC violation)`, or `accept-as-known-issue`).
F04, F07, F13 are explicitly accepted AC violations — close-out gate acknowledges Story 5-6 ships with known violations on AC #6/#7/#12 and KDD #5; resolution lands in Story 5-6b.
