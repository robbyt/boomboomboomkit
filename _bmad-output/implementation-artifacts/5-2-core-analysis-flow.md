# Story 5.2: Core Analysis Flow (File Drop + BPM Display)

Story ID: 5.2
Story Key: 5-2-core-analysis-flow
Epic: 5 — Developer Experience & Demo (second story; opens FR35/FR38/FR39)
Status: done

## Story

As a developer evaluating BoomBoomBoomKit,
I want to drop an audio file into the demo app window and see the detected BPM, confidence, effective intensity, and wall-clock analysis time without writing any code,
So that I can quickly evaluate detection accuracy on my own tracks before integrating the library.

**Scope clarification (read first).** Story 5-2 wires the *file drop + result display* slice on top of the Story 5-1 scaffold. The four observed states in the UI are:

1. **Empty** — no file dropped yet; placeholder copy invites the user to drop an audio file
2. **Analyzing** — `isAnalyzing == true`; activity indicator + filename + (when the user has signalled cancellation) "Cancelling…" copy
3. **Result** — non-nil `detectedBPM`; renders BPM, confidence, effective intensity, elapsed seconds, file name
4. **Error** — non-nil `errorMessage`; renders the error message verbatim

Story 5-2 also closes the three deferred-work items that were timed to this story's authoring window: **W3** (`CFBundleDocumentTypes` for Dock-icon / Finder "Open With" drops), **W16** (team-ID-leak pre-commit guardrail — promoted to immediate per its own re-open trigger), and **W17** (multi-second cancel-acknowledgement perceived latency at intensity 7+, addressed via "Cancelling…" copy). It also partially closes **W1** by introducing a per-task UUID discriminator that distinguishes "superseded by a newer analyze()" from "user cancelled / parent task cancelled" so `isAnalyzing` reaches a stable `false` in the latter case.

**What this story does NOT deliver** (each is a separate Epic 5 story):

- Intensity slider, merge-strategy picker, "Copy Config" snippet → Story 5-3 (`Parameter Controls`; opens FR36/FR40). Story 5-2 hard-codes the default `Options()`; user cannot change intensity or merge strategy yet
- Trace view + JSON / CSV export → Story 5-4 (`Diagnostic Trace Visualization and Export`; opens FR37/FR41)
- Public DocC + README quick-start + nil-return docs → Story 5-5 (`Public API Documentation and README`)
- App icon — Story 5-1 ships an empty `AppIcon.appiconset`; Story 5-5 (or a focused follow-up) may commission one
- Recent-files menu, security-scoped bookmark persistence across launches, multi-file batch UI — explicitly OUT OF SCOPE per Story 5-1 DD #16, NOT deferred

The dev agent's discipline: ship the smallest viable drop-handler + result-renderer pair that passes the AC, plus the three deferred-work close-outs. Do NOT inflate scope by surfacing Story 5-3's controls or Story 5-4's trace view.

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #4, #5, #6, #15, #16 are the most consequential** — they lock the drop transport, the format-filtering boundary, the single-file rejection contract, the security-scoped-resource bracketing contract, the per-task UUID discriminator that makes `isAnalyzing` recoverable, the Dock/Open-With document-open path, and the mixed-state UI render that lets `errorMessage` co-exist with `isAnalyzing == true`.

**Validation pass (2026-05-19) — Codex + Axiom skill review applied before promotion to ready-for-dev.** A first author pass landed earlier on 2026-05-19; this spec was then validated via (a) Codex MCP plan-review thread `019e42b4-8f0c-7ad0-b2f8-0857b65fa0ac` (14 findings: 3 Critical, 6 High, 3 Medium, 2 Low) and (b) Axiom skill survey agent reading `axiom-macos/skills/sandbox-and-file-access.md`, `axiom-swift/skills/transferable-ref.md`, `axiom-concurrency/skills/synchronization.md`, `axiom-concurrency/skills/swift-concurrency-ref.md`, `axiom-swiftui/skills/architecture.md`, `axiom-testing/skills/swift-testing.md` (7 amendments). Notable course corrections folded in below: removed the inherited `guard !Task.isCancelled` early return (it made the W1 fix unreachable); added DD #15 for `.onOpenURL` because `.dropDestination` does NOT receive LaunchServices document-open events; replaced `isCancelling: Bool` with a `pendingCancellations: Set<UUID>` + derived `isCancelling: Bool` computed property because a Bool cannot model multiple superseded tasks draining concurrently; switched format filter from `UTType.conforms(to:)` to lowercased extension matching to avoid `.m4b`/`.mp4` silently widening via `.mpeg4Audio` conformance; split DD #4's bracket pattern into window-drop (`.start` + balanced `.stop`) vs `.onOpenURL` (`.stop`-only per Axiom auto-start table); commit to `INFOPLIST_KEY_*` form with an explicit fallback Task subtask; relaxed the Escape-key cancel to optional. Apple-docs MCP returned zero results on all four queries during validation (transient server issue 2026-05-19); claims about `.dropDestination`, security-scoped resource, `CFBundleDocumentTypes`, and `INFOPLIST_KEY_*` are sourced from Axiom skill files referenced below and from Apple's web docs cited inline.

1. **Drop transport: `.dropDestination(for: URL.self)` on the main view, scoped to `AnalysisViewModel.supportedAudioContentTypes`.** SwiftUI's URL drops on macOS 13+ surface as a `[URL]` payload in the closure; the URLs are *almost* file URLs and *usually* arrive within a security-scoped sandbox bracket (see DD #4). The simplest correct transport. Rejected alternatives: (a) a custom `enum DroppableAudio: Transferable` wrapper that proxies through `FileTransferRepresentation` — adds machinery without changing the consumer surface; the underlying `[URL]` payload is what the analyzer needs anyway; (b) `.onDrop(of:isTargeted:perform:)` (UIKit-era API) — works but `NSItemProvider`-based and async-callback-heavy; the URL form is the modern Swift Concurrency-friendly path per `axiom-swift/skills/transferable-ref.md:343-355`; (c) `fileImporter(isPresented:)` — that's an "Open File…" menu pattern, not a drop pattern; orthogonal feature. Story 5-2 ships drop; an "Open File…" menu item is a future story if a power user surfaces the need.

2. **Format filtering at the DROP BOUNDARY uses lowercased filename-extension matching, NOT UTType conformance (validation pass 2026-05-19, Codex H5).** The accepted set is exactly six extensions: `wav`, `aiff`, `mp3`, `flac`, `m4a`, `caf`. The drop handler computes `url.pathExtension.lowercased()` and rejects with `errorMessage = "Unsupported file type: \(extension). Supported: WAV, AIFF, MP3, FLAC, M4A, CAF."` when the value is not in that 6-entry set. Why not `UTType.conforms(to:)`: an `.m4b` (audiobook) or `.mp4` (video container with audio track) file conforms to `.mpeg4Audio` and would silently widen the supported set; `.alac` conforms to `.audio` parent. The extension-based contract is what `PCMBufferReader` actually supports (project-context.md confirms WAV/AIFF/MP3/FLAC/M4A/CAF as the exact decoder list). **Negative tests required (DD #13):** `.m4b`, `.mp4`, `.ogg`, `.txt`, `.png` all map to the unsupported path. The `AnalysisViewModel.supportedAudioContentTypes: [UTType]` whitelist from Story 5-1 remains in place (it's used elsewhere as the *Story 5-1 wiring contract* and surfaces in the `INFOPLIST_KEY_CFBundleDocumentTypes` declaration per DD #8) but is NOT consulted by `validateDropPayload` — the validator uses a separate `static let supportedExtensions: Set<String> = ["wav", "aiff", "mp3", "flac", "m4a", "caf"]` for direct comparison. This avoids the unsupported alternate path where unsupported files reach `AudioAnalysisService.analyzeBPM` and surface a library-flavored `PCMBufferReaderError`.

3. **Single-file drops only — `files.count > 1` returns false + sets `errorMessage = "Drop a single audio file (batch drop is not supported)."`** Per Story 5-1 DD #16 OUT-OF-SCOPE "Multi-file batch UI / drop-multiple". Latest-selection-wins (DD #16-E in Story 5-1) applies to *sequential* drops, NOT to one-shot multi-drops. A user can drop file A, then drop file B; B supersedes A's in-flight analysis. A user CANNOT drop A and B together and expect both to analyze. Multi-file batch is a power-user feature that belongs in a focused follow-up if Hilbert / MetaMan surface the need.

4. **Security-scoped resource bracketing — two patterns, one per entry point (validation pass 2026-05-19, Axiom A1 + Codex H4).** The bracket discipline differs depending on whether the URL arrives via SwiftUI `.dropDestination` (window drop) or via `.onOpenURL` (Dock-icon drop + Finder Open-With + `open -a`); the Axiom skill `axiom-macos/skills/sandbox-and-file-access.md:301-311` is the authoritative table.

   - **Window-drop URLs from `.dropDestination(for: URL.self)`: defensive `start` + balanced `stop`.** Apple's `https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox` enumerates auto-started sources as: open/save panels, fileImporter, items dragged to the Dock icon. Window drops are NOT in that enumeration. Axiom's table is silent on window drops. The defensive pattern: `let didStart = url.startAccessingSecurityScopedResource(); ... defer { if didStart { url.stopAccessingSecurityScopedResource() } }`. The `Bool` gate ensures we do not call `stop` on a URL that didn't grant access (avoids the "harmless but confusing" anti-pattern called out at `sandbox-and-file-access.md:441`).
   - **`.onOpenURL` URLs (Dock-icon + Finder Open-With + `open -a`): `stop`-only, NO `start` call.** Per `sandbox-and-file-access.md:301-311`: Dock drag-and-drop URLs are auto-started by the system; the app must NOT call `start` (wasted call) but MUST call `stop` to release kernel resources. The pattern: `defer { url.stopAccessingSecurityScopedResource() }` with no preceding `start`.

   **`AnalysisViewModel.analyze(url:options:autoStarted: Bool = false)` — the API hops the dispatch.** A new `autoStarted` parameter discriminates the two paths. When the drop handler calls `viewModel.analyze(url: url)`, the default `autoStarted = false` triggers the defensive bracket. When the `.onOpenURL` handler (DD #15) calls `viewModel.analyze(url: url, autoStarted: true)`, the bracket is `stop`-only. The bracket lives in the outer `Task { ... }` body's `defer`, NOT in the drop handler closure — the closure returns synchronously while the analyze pipeline runs for ~1-30 seconds across the `Task.detached` boundary; the URL must remain accessible until the analyzer's PCM read completes.

   **AC #6's `(sandbox denied)` error suffix applies to the window-drop path only.** Under `make demo-build-sandboxed`, if `startAccessingSecurityScopedResource()` returns `false` AND analysis fails with `PCMBufferReaderError.fileNotReadable`, the error message is upgraded with `" (sandbox denied)"` so the user can distinguish "file doesn't exist" from "sandbox refused to grant access". Under `make demo-build` (debug, non-sandboxed per `sandbox-and-file-access.md:106-117`), `startAccessingSecurityScopedResource()` returns `true` unconditionally and the `(sandbox denied)` path is unreachable — that's the expected behavior and not a test gap.

   **`Task.detached` carried forward from Story 5-1 D1 patch, despite Axiom preference for `Task {}`.** Per `swift-concurrency-ref.md:455`, `Task.detached` is "rarely needed; prefer `Task {}`." Story 5-1 chose detached intentionally so the cooperative-cancellation Atomic<Bool> override could escape the default MainActor inheritance. Story 5-2 keeps detached for Story 5-1 continuity; a future story may revisit when there's a forcing function (e.g., observed priority inversion at the MainActor scheduler).

5. **Per-task UUID discriminator + REMOVE the `guard !Task.isCancelled` early return (validation pass 2026-05-19, Codex C1).** Story 5-1's task body has an early-return at `AnalysisViewModel.swift:123` (`guard !Task.isCancelled, let self else { return }`) that makes Story 5-2's planned reset unreachable. The corrected pattern:

   1. Each `analyze(url:)` call mints `let taskID = UUID()`, assigns `self.currentTaskID = taskID` on MainActor BEFORE launching the Task, and adds the prior `inFlightTasks`' UUIDs to `pendingCancellations` (see DD #6) during the cancel-all-prior cascade.
   2. The Task body's MainActor-re-entry **does NOT short-circuit on `Task.isCancelled`.** Instead, it runs to the switch-on-`result` arm unconditionally — even when this task was cancelled.
   3. The switch handles `.failure(is CancellationError)` FIRST. For this task to be the "current" task, `currentTaskID == taskID` must hold. If equal, the user cancelled the current task (Escape key, deinit, scene-phase): reset `isAnalyzing = false`, leave `errorMessage` and result fields untouched (the empty state is what the user wants after cancel). If NOT equal (superseded by newer `analyze(url:)`), return WITHOUT mutating any observed state — the successor task owns the UI now.
   4. The `.success` and other `.failure` arms perform the same `currentTaskID == taskID` gate before writing observed state. If `currentTaskID != taskID`, return WITHOUT mutating state.
   5. Every successful exit path (cancelled-current, success, error) resets `isAnalyzing = false`. The only exit path that leaves `isAnalyzing = true` is "superseded by newer analyze() call" — and the newer call has already set `isAnalyzing = true` to its own value, so the user sees a continuous truthy state across the supersession transition.
   6. The fire-and-forget cleanup `Task { _ = await task.value; self?.inFlightTasks.remove(task); self?.pendingCancellations.remove(taskID) }` from Story 5-1 D5 is preserved AND extended to also remove the task's UUID from `pendingCancellations` (see DD #6) — this is what reconciles the per-task acknowledgement back to the MainActor view-model state without any cross-isolation mutation.

   Net: after W1's fix, `isAnalyzing == true` is bounded by *exactly one* in-flight task (the most recent `analyze(url:)` call) for the supersession case; reaches `false` on user cancel via the explicit reset in the `.failure(is CancellationError)` arm. The W1 deferred-work entry's option (b) ("add a per-task UUID guard") is the path taken. NOT a `defer { isAnalyzing = false }` per W1's explicit warning — that races with the new task's `isAnalyzing = true` reset on the supersession path.

6. **"Cancelling…" copy via `pendingCancellations: Set<UUID>` and a derived `isCancelling: Bool` (validation pass 2026-05-19, Codex C3 + H4).** A `Bool` cannot represent "multiple superseded tasks still draining" — rapid drops can leave N-2 cancelled tasks polling for cancellation while N is launching, and a single Bool toggles wrong. The corrected model:

   - `@ObservationIgnored private var pendingCancellations: Set<UUID> = []` (operational state, MainActor-isolated, no observation tracking needed — the View consumes the derived property).
   - `var isCancelling: Bool { !pendingCancellations.isEmpty }` (computed; @Observable tracks the underlying set via the `@Observable` macro's tracking of property reads — actually the macro doesn't auto-track `@ObservationIgnored` properties, so the computed property doesn't auto-trigger view updates. **Resolution:** make `pendingCancellations` an OBSERVED property `var pendingCancellations: Set<UUID> = []` so the computed `isCancelling` invalidates the view on insert/remove. Cost: a Set<UUID> in the observation graph, which is negligible).
   - When the cancel-all-prior cascade in `analyze(url:)` fires `task.cancel()` on each prior task, it ALSO inserts the prior task's UUID into `pendingCancellations` on MainActor (the cascade runs in the MainActor-isolated `analyze(url:)` body — no cross-isolation mutation, no @Sendable closure capture).
   - When a prior task's body re-enters MainActor and recognizes itself as superseded (`currentTaskID != taskID`), it removes `taskID` from `pendingCancellations` and returns without mutating other state. The fire-and-forget cleanup Task removes `taskID` from `pendingCancellations` as a backstop (idempotent — set removal is safe to call twice).
   - The UI renders "Cancelling previous analysis…" alongside the activity indicator when `isCancelling && isAnalyzing` — the multi-second window where prior tasks are draining and the new task is booting.

   **NO @Sendable cancellation-handler mutation of MainActor state** (Codex H4): `withTaskCancellationHandler.onCancel` is `@Sendable` and not MainActor-isolated; it cannot directly mutate `pendingCancellations`. The set is mutated only from MainActor-isolated entry points: (a) the cancel-all-prior cascade at the top of `analyze(url:)`, (b) the task body's MainActor-re-entry path, (c) the fire-and-forget cleanup Task.

   `pendingCancellations` resets to empty naturally as each cancelled task acknowledges and removes its UUID; nothing else writes to it. Once empty, `isCancelling` flips false, the UI drops the "Cancelling…" copy. There is no library change — this is purely view-model state plumbing.

7. **Cancel affordance for Story 5-2: implicit-via-drop only. Hidden Escape-key shortcut DOWNGRADED to optional (validation pass 2026-05-19, Codex L13).** A visible "Cancel" button is Story 5-3's concern (it goes near the parameter controls so users can cancel after slider-driven re-analyze). Story 5-2 surfaces cancel implicitly via "drop a new file = cancel the prior one" through Story 5-1's cancel-all-prior cascade. **NOT shipped:** a hidden Escape-key keyboard shortcut. The original spec's hidden `Button("").keyboardShortcut(.cancelAction).hidden()` pattern is fragile in SwiftUI (responder-chain state transitions can drop the shortcut), and the W1 fix in DD #5 is the more important cancel-recovery guarantee — verifiable through sequential drops without an Escape key. **If the dev agent finds an isolated case where Escape is needed for manual smoke-testing (Task 8), add it as a Completion-Notes-only experimental affordance with a comment "Story 5-2 experimental; Story 5-3 may promote to a visible button."** Not part of AC #12.

8. **`INFOPLIST_KEY_CFBundleDocumentTypes` declared in build settings, mapping all 6 UTIs (W3 close-out; validation pass 2026-05-19, Codex H9).** Story 5-1 W3 documented that without `CFBundleDocumentTypes`, only window-internal drops work — Dock-icon drops and Finder "Open With" do not surface the app. Story 5-2 ships drop-onto-window AND wires the Dock + Open-With paths because both are pieces of the same product slice: the `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting + DD #15's `.onOpenURL` handler are tightly coupled. **Implementation commits to the `INFOPLIST_KEY_*` build-setting form** synced to `GENERATE_INFOPLIST_FILE = YES`; a hand-written partial Info.plist is the explicit fallback (Task 3.4 below).

   The role for all 6 entries is `Viewer` (read-only — matches the app's `files.user-selected.read-only` entitlement); the rank is `Default` for the first entry (`.wav`) and `Alternate` for the other 5 (so Finder's "Open With" prefers other audio apps when available — we are an evaluation tool, not the user's default audio app). The doc-type icons inherit from system defaults; we ship no custom audio-file icons.

   **R2 fallback condition (made explicit):** if `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting serialization proves intractable after 30 minutes of dev time, fall back to a hand-written partial Info.plist at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` with `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` + `GENERATE_INFOPLIST_FILE = NO`. Task 3.4 carries the fallback subtasks; AC #7's plutil verification recipe works on either form (the runtime Info.plist is what matters). The fallback adds one tracked file to the file list — flag in Completion Notes if used.

9. **`make demo-lint` Makefile target — team-ID leak guardrail (W16 close-out, immediate per its own re-open trigger; validation pass 2026-05-19, Codex H8 + M10 + M11).** Per W16: Story 5-2 plausibly edits `.pbxproj` (this story DOES — see DD #8 `INFOPLIST_KEY_CFBundleDocumentTypes` addition), Xcode auto-populates `DEVELOPMENT_TEAM = S85RR68YT7` on save, dev commits. The guardrail target runs a `grep` over every `project.pbxproj` under `Demo/` and exits non-zero if any line matches BOTH the quoted form (`DEVELOPMENT_TEAM = "S85RR68YT7";` — Story 5-1's empty-string shape, but populated) AND the unquoted Xcode-emitted form (`DEVELOPMENT_TEAM = S85RR68YT7;`):

   ```makefile
   ## demo-lint: Guard against DEVELOPMENT_TEAM leak across all Demo/.pbxproj files
   .PHONY: demo-lint
   demo-lint:
   	@if grep -rnE 'DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*"?[A-Z0-9]{10}"?[[:space:]]*;' Demo/ --include='project.pbxproj'; then \
   		echo "ERROR: DEVELOPMENT_TEAM leak detected in Demo/ .pbxproj — must be empty for public release."; \
   		exit 1; \
   	fi
   ```

   The character class `[A-Z0-9]{10}` matches Apple's team-ID shape exactly. The optional `"?` covers both quoted and unquoted emission. The empty `DEVELOPMENT_TEAM = "";` Story 5-1 baseline does NOT match.

   **`make pre-commit` aggregate.** Wires `fmt`, `demo-fmt`, `lint`, and `demo-lint` so contributors run all gates from one target. The new `demo-fmt` target extends `swift format` to the `Demo/` tree — Story 5-1's `make fmt` is `swift format --recursive --in-place Sources/ Tests/` and does NOT cover `Demo/`; without `demo-fmt`, Story 5-2's demo Swift files drift from formatter-clean. Two implementation options for `demo-fmt`: (a) a sibling target `swift format --recursive --in-place Demo/`, OR (b) extend the existing `make fmt` body to add `Demo/` to its path list. Option (b) is simpler if there's no reason to format Demo/ in isolation; option (a) preserves the Story 5-1 fmt target verbatim. Dev agent picks at implementation time.

   **`make lint` exit-code semantics** (Codex M10 clarification): SwiftLint's `lint` subcommand exits 0 on `warning`-severity violations and non-zero on `serious`-severity violations. The canonical `LUFSAnalyzer.swift:94` TODO is a warning, NOT serious. Story 5-1's gating gauntlet confirmed `make lint` exits 0 with that one warning. `make pre-commit` therefore exits 0 with the canonical baseline — no contradiction.

   NOT added as a `.git/hooks/pre-commit` shell script — git hooks aren't committed by default (`hooksPath` config dance is fragile across machines) and `make pre-commit` is the canonical pre-PR gate. **Process surface area caveat** (Codex L14): `make pre-commit` is the team's current convention; pre-1.0 framing allows future iterations to revisit. Not a permanent contract.

10. **Result-rendering layout: VStack of labeled rows, no table / form / grid.** The result view shows 5 fields (file name, BPM, confidence, effective intensity, elapsed seconds). Simplest layout: a VStack with 5 `HStack { Text("Label:"); Spacer(); Text(value) }` rows, monospaced for the value column so digits don't jitter as values update. SwiftUI `Form` / `Grid` / `Table` are overkill for 5 read-only fields and lock in macOS-specific affordances we don't want (Form sections, table headers). The view model exposes the field values as `let displayBPM: String = detectedBPM.map { String(format: "%.1f BPM", $0) } ?? "—"` style computed strings — keeps formatting concerns out of the View body. `confidence` renders as `String(format: "%.0f%%", confidence * 100)` (Story 4.1 precedent for surfacing confidence as percentage). `elapsedSeconds` renders as `String(format: "%.2fs", elapsedSeconds)`. `effectiveIntensity` renders as `String(intensity.rawValue)` (no preset-name decoration in 5-2 — that's Story 5-3 territory once the user can change it).

11. **Drop-handler logic extracted into a non-View helper for testability; `DropError` is INTERNAL (validation pass 2026-05-19, Codex H6).** SwiftUI views are notoriously hard to unit-test (ViewInspector is a 3rd-party dep we won't add per zero-deps rule). The drop-handler logic factors into a static method on `AnalysisViewModel`: `static func validateDropPayload(_ urls: [URL]) -> Result<URL, DropError>` where `DropError` is an **internal** (NOT `private`) enum with cases `.empty`, `.multipleFiles`, `.unsupportedType(extension: String)`. Internal access is required so the demo's test target can pattern-match the result type via `@testable import BoomBoomBoomKitDemo` (a `private` return type would force the method's effective access level down and break the test's `case .empty = result` pattern). The enum is module-private to the demo (not promoted across module boundaries); `internal` is the minimum surface that lets tests inspect it.

   The View body becomes: `.dropDestination(for: URL.self) { urls, _ in viewModel.handleDrop(urls) }` where `handleDrop` calls the validator, updates `errorMessage` on failure, calls `analyze(url:)` on success, and returns the Bool the drop API requires. The validator is fully unit-testable from `BoomBoomBoomKitDemoTests` via `@testable import BoomBoomBoomKitDemo` (the Story 5-1 D2 pattern). NO XCUITest target — DD #14 in Story 5-1 deferred a `BoomBoomBoomKitDemoUITests` target "to Story 5-2 when there's actually UI to test". Story 5-2 explicitly does NOT add a UI test target because the drop logic is now testable as pure data validation; the visible drop interaction can be smoke-tested manually (Task 8) without an XCUITest harness. **HALT-(b) fires if the dev agent adds a `BoomBoomBoomKitDemoUITests` target.**

12. **Visual drop-target feedback: `isTargeted:` callback updates a `@State var isDropTargeted: Bool` that drives a 1pt accent-color border overlay; root VStack gets `.contentShape(Rectangle())` so padded margins register drops (validation pass 2026-05-19, Axiom A2).** Per `transferable-ref.md:622-635`, `.frame(maxWidth:.infinity, maxHeight:.infinity).padding()` alone may NOT deliver drops at the padded margins where DD #12's accent-color border is painted. The `.contentShape(Rectangle())` modifier makes the entire bounding rectangle hit-testable, so drops at the visible border edge register. Pattern: apply `.contentShape(Rectangle())` AFTER `.frame()` and BEFORE `.dropDestination(...)` on the root VStack.

   Subtle, system-idiomatic per Apple HIG drop-target conventions. Rejected alternatives: (a) no feedback (user can't tell they're hovering a valid drop zone — confusing); (b) full-window highlight (over-loud for a calm evaluation tool); (c) icon swap mid-hover (overkill). The 1pt border on `isDropTargeted == true` is the lightest-touch correct signal.

13. **Test target additions: extend the smoke test file with drop-validator unit tests + a "result state rendering" property snapshot.** Story 5-1 ships `AnalysisViewModelSmokeTest.swift` with one `@Test("wrapping")` method. Story 5-2 adds:
    - `@Test("rejects empty drop")` — `validateDropPayload([])` returns `.empty`
    - `@Test("rejects multi-file drop")` — `validateDropPayload([url1, url2])` returns `.multipleFiles`
    - `@Test("rejects unsupported file type")` — `validateDropPayload([txtURL])` returns `.unsupportedType(extension: "txt")`
    - `@Test("accepts WAV / AIFF / MP3 / FLAC / M4A / CAF", arguments: ...)` — parameterized over the 6 supported extensions, asserts `validateDropPayload([url])` returns `.success(url)`. Uses synthesized URLs (`URL(fileURLWithPath: "/tmp/x.wav")` etc.) — no actual file I/O needed; the validator inspects URL extension only.
    - `@Test("handleDrop transitions view-model state correctly", arguments: ...)` — parameterized over the 3 failure cases, asserts post-`handleDrop` view-model state (`errorMessage` populated, `isAnalyzing == false`, `detectedBPM == nil`).
    - Updated `@Test("wrapping")` from Story 5-1 — now also asserts `viewModel.isCancelling == false` post-completion (new observed property per DD #6).

    Smoke test file grows from 36 lines → ~120 lines. NO new test files in Story 5-2.

14. **`AudioAnalysisService.Options` remains the default in Story 5-2 — NO intensity / merge-strategy mutation.** Story 5-3 will surface those controls. Story 5-2's `AnalysisViewModel.options` is the Story 5-1 default (intensity 7, `.optimal` preset, `.maxConfidence` merge). Acceptance criteria's "intensity 1-3 instant" and "intensity 7+ activity indicator" are satisfied by *behavior* (at default 7, the indicator shows; if a future user changes to 1-3 via Story 5-3 controls, the indicator either flashes briefly or doesn't render — DD #10 says "always render when `isAnalyzing`, the flash is acceptable"). Story 5-2 does not provide UI to test the "intensity 1-3 instant" path; that's an inherited Story 5-3 verification. Story 5-2 verifies "intensity 7 activity indicator shows" via the smoke test + manual drop test.

15. **`.onOpenURL` handler for Dock-icon drop + Finder Open-With + `open -a` (validation pass 2026-05-19, Codex C2). NEW DD.** `.dropDestination(for: URL.self)` handles drops onto the SwiftUI view ONLY — it does NOT receive LaunchServices document-open events. Without an `.onOpenURL` handler at app/scene level, AC #7's "manually verified — Dock-icon drop + Finder Open-With submenu" path fails even when `CFBundleDocumentTypes` is correctly declared. The handler:

   ```swift
   // In BoomBoomBoomKitDemoApp.swift, on WindowGroup or ContentView root:
   .onOpenURL { url in
     viewModel.handleDrop([url])
   }
   ```

   `handleDrop` is the same instance method used by the window-drop path (DD #11), so validation, error rendering, and analyze invocation are identical across both entry points. The discriminator on the bracket discipline (DD #4) is the `autoStarted: Bool` parameter that `analyze(url:)` accepts: window-drop callers pass `autoStarted: false` (defensive bracket); `.onOpenURL` callers pass `autoStarted: true` (`stop`-only). `handleDrop` itself doesn't know about the difference — it forwards through `analyze(url:autoStarted:)` with the appropriate flag based on its own entry-point context. Simplest implementation: `handleDrop(_:)` defaults to `autoStarted: false`; add a parallel `handleOpenURL(_:)` that calls `validateDropPayload` then `analyze(url:autoStarted: true)`. The View body calls `viewModel.handleDrop(urls)` in `.dropDestination` and `viewModel.handleOpenURL(url)` in `.onOpenURL`.

   **Single-file enforcement applies symmetrically.** `.onOpenURL` delivers one URL at a time (Apple's contract); `handleOpenURL` doesn't need a multi-file check, but the validator does. Reuse `validateDropPayload([url])` with a 1-element array.

   **Verification recipe** (Task 8.7-8.8): after `make demo-build-sandboxed` + `lsregister -kill -r -domain local ... -f <built-app>`, drag a `.wav` onto the Dock icon and verify the analysis runs. Also verify Finder Open-With surfaces the app for `.wav` files.

16. **Mixed-state UI: `errorMessage` renders as a secondary banner WHEN co-existing with `analyzing`/`result` (validation pass 2026-05-19, Codex H7). NEW DD.** Invalid drops set `errorMessage` but do NOT cancel an in-flight analysis (cancelling on every invalid drop would be a UX trap — a user fat-finger could nuke a long-running analysis). The four-state model from the scope clarification gets refined: each primary state (empty / analyzing / result / error-only) can co-exist with a transient `errorMessage` banner.

   - **`isAnalyzing == true` + `errorMessage != nil` (invalid drop during analysis):** render the analyzing primary view + a single-line `Text(errorMessage)` banner below the activity indicator with `.font(.callout).foregroundStyle(.red)`. The banner clears automatically when the analysis completes successfully (the success path sets `errorMessage = nil` per Story 5-1 behavior).
   - **`isAnalyzing == false` + `errorMessage != nil` + `detectedBPM == nil` (analysis failed OR last drop was invalid):** the primary view IS the error — render the error message in place of the result fields. No banner.
   - **`isAnalyzing == false` + `errorMessage != nil` + `detectedBPM != nil` (rare; analysis succeeded but a later invalid drop set an error):** render the result view + a single-line error banner below. The banner clears on next successful analyze.

   The `DisplayState` enum from Task 2.1 needs an additional `errorBanner: String?` parameter (or a separate `bannerError: String?` computed on each render).

## Acceptance Criteria

1. **File drop on the main window triggers analysis and renders the result (FR35).**

   **Given** the demo app is running
   **When** the user drops a single audio file (one of the 6 supported UTIs: WAV, AIFF, MP3, FLAC, M4A, CAF) onto the main window
   **Then** the drop handler accepts the drop (`return true` from the `.dropDestination` closure)
   **And** `viewModel.analyze(url:)` is invoked with the dropped URL
   **And** the analyzing state renders: `ProgressView` + filename + (when applicable) "Cancelling previous analysis…" copy
   **And** on completion, the result state renders the 5 fields per DD #10: file name, BPM (`%.1f BPM`), confidence (`%.0f%%`), effective intensity (raw Int), elapsed seconds (`%.2fs`)

2. **Drop boundary filters by lowercased filename extension against the 6-entry whitelist (DD #2).**

   **Given** the user drops a file with an unsupported extension (e.g., `.txt`, `.ogg`, `.png`, `.m4b`, `.mp4`)
   **When** the drop handler runs
   **Then** the closure returns `false`
   **And** `viewModel.errorMessage` is set to `"Unsupported file type: \(extension). Supported: WAV, AIFF, MP3, FLAC, M4A, CAF."`
   **And** the analyze pipeline is NOT invoked (no DSP work runs for an unsupported file)
   **And** `viewModel.isAnalyzing` is NOT changed by the invalid drop (per DD #16: invalid drops do NOT cancel in-flight analysis)

   **Given** the user drops multiple files at once (`files.count > 1`)
   **When** the drop handler runs
   **Then** the closure returns `false`
   **And** `viewModel.errorMessage` is set to `"Drop a single audio file (batch drop is not supported)."`
   **And** the analyze pipeline is NOT invoked for any of the files
   **And** `viewModel.isAnalyzing` is NOT changed

3. **Activity indicator behavior (FR38).**

   **Given** an analysis is in flight (`viewModel.isAnalyzing == true`)
   **When** the result view is rendered
   **Then** a `ProgressView()` is visible alongside the filename
   **And** the "Drop an audio file" empty-state copy is NOT visible
   **And** the result fields are NOT visible

   **Given** an analysis is in flight at intensity 7 (default) and the user drops a NEW file
   **When** the new drop triggers cancel-all-prior
   **Then** `viewModel.isCancelling` is true between the cancel signal and the prior task's acknowledgement
   **And** the UI renders "Cancelling previous analysis…" alongside the activity indicator
   **And** once the prior task throws `CancellationError`, `isCancelling` flips false and the "Cancelling…" copy disappears

4. **Wall-clock analysis time renders alongside BPM (FR39).**

   **Given** a successful analysis result
   **When** the result view is rendered
   **Then** `elapsedSeconds` is rendered formatted as `String(format: "%.2fs", elapsedSeconds)` adjacent to the other result fields
   **And** the value is the same `elapsedSeconds` already populated by Story 5-1's view model (no new clock source introduced)

5. **Error rendering for analysis failures (DD #16 mixed-state precedence applies).**

   **Given** the analyze pipeline throws `PCMBufferReaderError` (e.g., the file became unreadable mid-drop)
   **When** the analyze body re-enters MainActor and matches `currentTaskID == taskID` (DD #5 gate)
   **Then** `viewModel.errorMessage` is set via the view-model template `"Could not read audio file: \(url.lastPathComponent)"` (Codex M12 fix — the message is built by the view model from the URL, NOT from `String(describing: error)` which renders Swift's enum debug shape `PCMBufferReaderError.fileNotReadable(file:///...)`)
   **And** the UI renders the error message in place of the result fields when `detectedBPM == nil && !isAnalyzing` (DD #16 primary error state)
   **And** the activity indicator is NOT visible (`isAnalyzing == false`)

   **Given** the analyze pipeline returns `nil` (silence / too-short audio / non-musical content)
   **When** the analyze body re-enters MainActor
   **Then** `viewModel.errorMessage` is populated with `"No BPM detected (silence, too-short audio, or non-musical content)"` (Story 5-1 behavior, unchanged)
   **And** the UI renders the error message

   **Given** the analyze pipeline is mid-flight AND the user drops an unsupported / multi-file payload (per AC #2)
   **When** the invalid drop populates `viewModel.errorMessage`
   **Then** the UI renders the analyzing primary view (activity indicator + filename) AND a secondary `Text(errorMessage)` banner below in `.font(.callout).foregroundStyle(.red)` per DD #16
   **And** the in-flight analysis is NOT cancelled
   **And** when the analysis completes successfully, `errorMessage` is cleared by the success path and the banner disappears

6. **Security-scoped resource bracketing — two patterns per entry point (DD #4, R4 close-out; sandboxed-build gate per Axiom A4).**

   **Given** a sandboxed `make demo-build-sandboxed` build of the app AND the user drops an audio file via SwiftUI window-drop (`autoStarted: false` path)
   **When** `viewModel.analyze(url:, autoStarted: false)` runs
   **Then** the URL is wrapped via `let didStart = url.startAccessingSecurityScopedResource()` BEFORE `Task.detached`
   **And** the analyze Task body's `defer { if didStart { url.stopAccessingSecurityScopedResource() } }` balances on Task completion
   **And** the file is successfully read by `PCMBufferReader` and the BPM is reported

   **Given** the same sandboxed build AND a URL arrives via `.onOpenURL` (Dock-icon drop, Finder Open-With, or `open -a`; `autoStarted: true` path per DD #15)
   **When** `viewModel.analyze(url:, autoStarted: true)` runs
   **Then** `startAccessingSecurityScopedResource()` is NOT called (the system has auto-started access per `axiom-macos/skills/sandbox-and-file-access.md:301-311`)
   **And** the analyze Task body's `defer { url.stopAccessingSecurityScopedResource() }` releases the auto-started access on Task completion
   **And** the file is successfully read

   **Given** a `make demo-build-sandboxed` build AND the window-drop path AND `url.startAccessingSecurityScopedResource()` returns `false` (rare; URL from a non-sandboxed source that didn't need scoping)
   **When** the read subsequently fails with `PCMBufferReaderError.fileNotReadable`
   **Then** the view model populates `errorMessage = "Could not read audio file: \(url.lastPathComponent) (sandbox denied)"` (view-model-constructed template per Codex M12)

   **NOTE — `make demo-build` (debug, non-sandboxed) AC scope:** under the unsigned `make demo-build` target, `startAccessingSecurityScopedResource()` returns `true` unconditionally (the process is not sandboxed per `axiom-macos/skills/sandbox-and-file-access.md:106-117`); the `(sandbox denied)` branch above is UNREACHABLE under `make demo-build` and is verified ONLY under `make demo-build-sandboxed`. AC #6 is a sandboxed-build assertion; AC #11 / `make demo-test` runs against the unsigned build and exercises the success path only.

7. **W3 close-out — `INFOPLIST_KEY_CFBundleDocumentTypes` declared AND `.onOpenURL` handler wired (DD #8 + DD #15).**

   **Given** the built `.app` bundle
   **When** its Info.plist is inspected (`plutil -p BoomBoomBoomKitDemo.app/Contents/Info.plist | grep -A 80 CFBundleDocumentTypes`)
   **Then** a `CFBundleDocumentTypes` array exists with exactly 6 entries
   **And** each entry has `CFBundleTypeRole = Viewer` and `LSItemContentTypes` matching one of the 6 supported UTIs (`public.wav`, `public.aiff`, `public.mp3`, `org.xiph.flac`, `public.mpeg-4-audio`, `com.apple.coreaudio-format`)
   **And** the first entry (for `public.wav`) has `LSHandlerRank = Default`; the other 5 have `LSHandlerRank = Alternate`

   **Given** the app's `BoomBoomBoomKitDemoApp.swift`
   **When** inspected
   **Then** the `WindowGroup { ContentView() }` body has an `.onOpenURL { url in viewModel.handleOpenURL(url) }` modifier (or equivalent at the scene/view root) per DD #15

   **Given** the same built `.app` (manually verified — NOT an automated test, per AC #12)
   **When** the user drags an audio file onto the app's Dock icon
   **Then** the drop is delivered via `.onOpenURL`, the URL is auto-started (DD #4 `.onOpenURL` path), and the analysis runs to completion
   **And** Finder's "Open With" submenu lists the app as an available opener for files of the 6 supported UTIs

8. **W16 close-out — `make demo-lint` team-ID leak guardrail (DD #9).**

   **Given** the `Makefile`
   **When** inspected post-merge
   **Then** a new target `demo-lint` exists that greps recursively over `Demo/` `--include='project.pbxproj'` for any `DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*"?[A-Z0-9]{10}"?[[:space:]]*;` match (both quoted and unquoted Xcode-emitted forms) and exits non-zero on a hit
   **And** `make demo-lint` exits 0 on the current branch (no team-ID present)
   **And** a new target `demo-fmt` exists that runs `swift format --recursive --in-place Demo/` (OR `make fmt` is extended to add `Demo/` to its path list)
   **And** a new aggregate target `make pre-commit` exists that runs `fmt`, `demo-fmt`, `lint`, and `demo-lint` in sequence; the help comment documents it

   **Given** a hypothetical regression where `DEVELOPMENT_TEAM = "S85RR68YT7";` is committed to `Demo/.../project.pbxproj`
   **When** `make demo-lint` runs
   **Then** it exits non-zero with a one-line message naming the file and line number of the offending team-ID
   **(Verified inline by the dev agent via a temporary planted team-ID; reverted before close-out per Story 5-1 Task 9.4 recipe-inversion pattern)**

9. **`AnalysisViewModel` gains `pendingCancellations: Set<UUID>` observed property + derived `isCancelling: Bool` computed + per-task UUID discriminator (DDs #5, #6).**

   **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift`
   **When** inspected
   **Then** the type declares `var pendingCancellations: Set<UUID> = []` as an OBSERVED property (the @Observable macro tracks its mutations so SwiftUI re-renders when it changes)
   **And** the type declares `var isCancelling: Bool { !pendingCancellations.isEmpty }` as a computed property
   **And** the type declares `@ObservationIgnored private var currentTaskID: UUID?` (operational state per the Story 5-1 PP8 `@ObservationIgnored` pattern)
   **And** `analyze(url:autoStarted:)` mints a fresh `let taskID = UUID()` per call and assigns it to `self.currentTaskID` BEFORE launching the Task
   **And** the cancel-all-prior cascade in `analyze(url:autoStarted:)` inserts EACH prior task's UUID into `self.pendingCancellations` BEFORE `task.cancel()` is invoked
   **And** the Task body's MainActor-re-entry runs to the switch UNCONDITIONALLY (NO `guard !Task.isCancelled` early return per Codex C1 fix)
   **And** the switch handles `.failure(is CancellationError)` FIRST: if `currentTaskID == taskID`, reset `isAnalyzing = false`; in either case (equal or not equal), the fire-and-forget cleanup Task removes `taskID` from `pendingCancellations` so `isCancelling` reflects only still-draining prior tasks
   **And** the `.success` and other `.failure` arms gate observed-state writes (incl. `detectedBPM`, `confidence`, `effectiveIntensity`, `elapsedSeconds`, `errorMessage`, `isAnalyzing = false`) on `currentTaskID == taskID`; when the check fails (superseded), the task body returns without mutation
   **And** NO `@Sendable withTaskCancellationHandler.onCancel` closure mutates view-model state directly (Codex H4); the cancel cascade mutates `pendingCancellations` only from MainActor

10. **`AnalysisViewModel.handleDrop([URL]) -> Bool` + `handleOpenURL(URL)` + `validateDropPayload` helper exist and are unit-tested (DD #11, DD #13, DD #15).**

    **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift`
    **When** inspected
    **Then** a static method `static func validateDropPayload(_ urls: [URL]) -> Result<URL, DropError>` exists
    **And** an instance method `func handleDrop(_ urls: [URL]) -> Bool` exists that calls the validator, populates `errorMessage` on failure, calls `analyze(url:autoStarted: false)` on success, and returns `false` on failure / `true` on success
    **And** an instance method `func handleOpenURL(_ url: URL)` exists that calls the validator with `[url]`, populates `errorMessage` on failure, calls `analyze(url:autoStarted: true)` on success (Void return since `.onOpenURL` does not require a Bool result)
    **And** the **internal** (NOT private — Codex H6) `enum DropError: Equatable` has exactly 3 cases: `.empty`, `.multipleFiles`, `.unsupportedType(extension: String)`

    **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift`
    **When** the suite runs
    **Then** the new tests pass: empty drop, multi-file drop, unsupported-type drop (txt/ogg/png/m4b/mp4), and the 6-extension parameterized accept test
    **And** the paired `handleDrop` state-transition test uses `arguments: zip(cases, expectedMessages)` per `axiom-testing/skills/swift-testing.md:213-217` (Axiom A5)
    **And** the original `wrapping` smoke test still passes, with the added `isCancelling == false` assertion (i.e., `viewModel.pendingCancellations.isEmpty`) post-completion

11. **Library gating still passes; demo build + test gauntlets unchanged (Story 5-1 baseline preserved).**

    **Given** the library gating gauntlet
    **When** run on this branch
    **Then** `make fmt` clean
    **And** `make lint` reports only the canonical pre-existing `LUFSAnalyzer.swift:94` TODO violation
    **And** `make test` passes (library test count unchanged — Story 5-2 adds zero library tests; only demo-target tests are new)
    **And** `make build` (library Debug build) succeeds
    **And** `make build-release` (library Release build) succeeds
    **And** `make demo-build` exits 0
    **And** `make demo-test` exits 0 (all new + existing demo-target tests pass)
    **And** `make demo-lint` exits 0 (no team-ID leak)
    **And** `make demo-fmt` exits 0 (or `make fmt` extended to cover `Demo/` — per DD #9)
    **And** `make pre-commit` exits 0 (the aggregate: `fmt` + `demo-fmt` + `lint` + `demo-lint`)
    **And** `make benchmark` reports Acc1 = 57/82, Acc2 = 73/82 (UNCHANGED — Story 5-2 touches zero library DSP code, this is a regression-protection sanity check; baseline updated per Story 5-1 pass-2 close-out to match the post-pass-2 OA300 counts on the current branch)
    **And** `make benchmark-giantsteps` reports Acc1 = 537/661, Acc2 = 546/661 (UNCHANGED)

12. **Sandbox manual smoke test executed at close-out (DD #4, DD #15).**

    **Given** a `make demo-build-sandboxed` build (the dev agent has a `DEVELOPMENT_TEAM` configured)
    **When** the dev agent manually drops one of the 6 supported file types onto the running app's main window
    **Then** the analysis runs to completion and the result is rendered

    **And** the dev agent manually drops an unsupported file (e.g., a `.txt`) and verifies the error message renders
    **And** the dev agent manually drops 2 files at once and verifies the multi-file error message renders
    **And** the dev agent drops file A, then drops file B mid-analysis, and verifies the "Cancelling previous analysis…" copy appears (multi-second-window verification of DD #6 `pendingCancellations.isEmpty == false` state)
    **And** the dev agent runs `lsregister -kill -r -domain local -domain system -domain user -f <path-to-built-app>` then drags a `.wav` onto the app's Dock icon — verifies `.onOpenURL` delivers the URL and analysis runs (DD #15 verification)
    **And** the dev agent right-clicks a `.wav` in Finder → Open With — verifies BoomBoomBoomKitDemo appears in the handler list (DD #8 `LSHandlerRank = Alternate` verification)
    **And** the dev agent drops a `.txt` on the window WHILE file A is analyzing — verifies the analyzing primary view co-exists with the red error banner (DD #16 mixed-state verification) and that file A's analysis runs to completion (not cancelled)
    **And** Completion Notes record the manual test outcomes verbatim

13. **`.onOpenURL` handles LaunchServices document-open events (DD #15; Codex C2 close-out).**

    **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift`
    **When** inspected
    **Then** the `WindowGroup { ContentView() }` body has an `.onOpenURL { url in viewModel.handleOpenURL(url) }` modifier (or `.onOpenURL` applied at the ContentView root) per DD #15
    **And** `handleOpenURL` validates via `validateDropPayload([url])` and calls `analyze(url:autoStarted: true)` on success — confirming the document-open path uses the auto-started bracket discipline per DD #4

    **Given** a built `make demo-build-sandboxed` app + `lsregister -kill -r -f <built-app>`
    **When** the user runs `open -a BoomBoomBoomKitDemo <path-to-wav>` from the terminal OR drags a `.wav` onto the app's Dock icon OR uses Finder Open-With
    **Then** the URL is delivered via `.onOpenURL`, the analysis runs to completion, the result renders (manually verified per AC #12)

14. **Epic 5 hygiene: A2 + A3 continued from Story 5-1 (DD #11 from Story 5-1).**

    **Given** A2 (`deferred-work.md` is the canonical resolution ledger; story-file `[ ]` is task tracking only)
    **When** Story 5-2's close-out commit lands
    **Then** every applied patch and every newly-deferred item appears in `deferred-work.md` with cross-reference, NOT as `[ ]` checkboxes in this story's Review Findings section
    **And** the three close-outs (W3, W16, W17) are annotated CLOSED inline in their respective `deferred-work.md` entries with the Story 5-2 commit reference
    **And** W1 is annotated `PARTIALLY-CLOSED` with the per-task UUID discriminator note (the original "stuck-true on user cancel" path is fixed; any future deinit-during-analyze edge case re-opens)

    **Given** A3 (`make test` wall-clock baseline tracked per epic)
    **When** Story 5-2's Completion Notes are written
    **Then** they record the exact `make test` wall-clock seconds post-Story-5-2 on M5 Max (Story 5-1's baseline: cold-cache 6.84s real, warm-cache 2.01s real, 431 runs in 94 suites, 433 `@Test(` declarations)
    **And** they note the per-story delta vs Story 5-1 (expected: 0% — zero library changes)

## Tasks / Subtasks

- [x] **Task 0 — Pre-flight**
  - [x] 0.1: Confirm `make fmt && make lint && make test && make demo-build && make demo-test` all clean on the branch head — record `make test` wall-clock + test count for AC #14 A3 continuity
  - [x] 0.2: Confirm `make demo-build-sandboxed` runs successfully on this Mac (RT's `DEVELOPMENT_TEAM` is configured); if not, surface and HALT for environment setup BEFORE touching code

- [x] **Task 1 — `AnalysisViewModel` extensions (AC #9, AC #10, DDs #4, #5, #6, #11, #15)**
  - [x] 1.1: Add `var pendingCancellations: Set<UUID> = []` as an OBSERVED stored property (no `@ObservationIgnored` — the @Observable macro tracks it so SwiftUI re-renders the "Cancelling…" copy on mutation) plus the computed `var isCancelling: Bool { !pendingCancellations.isEmpty }` (per DD #6, post-Codex-C3 fix). Doc-comment cross-references DD #6
  - [x] 1.2: Add `@ObservationIgnored private var currentTaskID: UUID?` operational property (matches the `@ObservationIgnored` pattern PP8 introduced in Story 5-1)
  - [x] 1.3: Change `analyze(url:)` signature to `analyze(url:autoStarted:)` with `autoStarted: Bool = false` default. The `false` default preserves the window-drop call sites; `.onOpenURL` callers pass `true`. Mint `let taskID = UUID()` at the top, assign to `self.currentTaskID = taskID` BEFORE launching the Task; thread `taskID` and `autoStarted` into the Task body closure via capture
  - [x] 1.4: REMOVE the `guard !Task.isCancelled, let self else { return }` early return at the top of the Task body's MainActor-re-entry (the Story 5-1 line at `AnalysisViewModel.swift:123`). Replace with `guard let self else { return }` only — `Task.isCancelled` is handled via the `currentTaskID == taskID` gate per DD #5 (Codex C1 fix)
  - [x] 1.5: Restructure the switch on `result` per DD #5:
    - Handle `case .failure(is CancellationError):` FIRST. Inside, check `if currentTaskID == taskID` and if equal set `isAnalyzing = false`. Otherwise return without mutation.
    - The `.success` and other `.failure` arms gate ALL observed-state writes on `currentTaskID == taskID`. When equal, write state and set `isAnalyzing = false`. When not equal, return without mutation (the successor task owns the UI)
  - [x] 1.6: In the cancel-all-prior cascade at the top of `analyze(url:autoStarted:)`, BEFORE each `task.cancel()`, look up the prior task's `taskID` (stored alongside the task in the `inFlightTasks` set — see 1.6a below for the indexing change) and insert it into `self.pendingCancellations`
  - [x] 1.6a: Change `inFlightTasks: Set<Task<Void, Never>>` to `inFlightTasks: [UUID: Task<Void, Never>]` so the cancel cascade can look up each prior task's UUID for insertion into `pendingCancellations`. The Story 5-1 deinit pattern still works (`for (_, task) in inFlightTasks { task.cancel() }`). The fire-and-forget cleanup `Task { _ = await task.value; self?.inFlightTasks.removeValue(forKey: taskID); self?.pendingCancellations.remove(taskID) }` does double-duty
  - [x] 1.7: Add the new **internal** (NOT private — Codex H6) `enum DropError: Equatable { case empty; case multipleFiles; case unsupportedType(extension: String) }` to `AnalysisViewModel.swift`
  - [x] 1.8: Add the static validator: `static func validateDropPayload(_ urls: [URL]) -> Result<URL, DropError>`. Implementation: check count (empty → `.empty`; >1 → `.multipleFiles`), then check `url.pathExtension.lowercased() ∈ {"wav", "aiff", "mp3", "flac", "m4a", "caf"}` (the `static let supportedExtensions: Set<String>` constant per DD #2); on miss return `.unsupportedType(extension: url.pathExtension.lowercased())`; on hit return `.success(url)`. The validator does NOT use `UTType.conforms(to:)` (Codex H5 fix — `.m4b`/`.mp4` would silently widen via `.mpeg4Audio` conformance)
  - [x] 1.9: Add the instance method `func handleDrop(_ urls: [URL]) -> Bool` that calls the validator, populates `errorMessage` on failure (per AC #2 verbatim text) and returns false, OR calls `analyze(url: theURL, autoStarted: false)` on success and returns true. Add a parallel `func handleOpenURL(_ url: URL)` (returns Void — `.onOpenURL` API does not expect a Bool) that wraps the same validator and on success calls `analyze(url: theURL, autoStarted: true)`
  - [x] 1.10: Augment `analyze(url:autoStarted:)` with the bracket discipline per DD #4:
    - When `autoStarted == false`: capture `let didStart = url.startAccessingSecurityScopedResource()` BEFORE `Task.detached`; inside the outer Task's body, `defer { if didStart { url.stopAccessingSecurityScopedResource() } }`
    - When `autoStarted == true`: skip the `start` call; inside the outer Task's body, `defer { url.stopAccessingSecurityScopedResource() }` (always release — the system auto-started it)
  - [x] 1.11: Augment `.failure(let error as PCMBufferReaderError)` arm: when `case .fileNotReadable(_) = error` AND `autoStarted == false` AND `didStart == false`, set the view-model error message to `"Could not read audio file: \(url.lastPathComponent) (sandbox denied)"` (Codex M12 — view-model-constructed template, NOT `String(describing: error)`). On the non-sandbox-denied paths, the template is `"Could not read audio file: \(url.lastPathComponent)"`
  - [x] 1.12: Verify the view model still compiles under Swift 6 strict concurrency (no `@unchecked Sendable`, no `nonisolated(unsafe)`). NO direct `@Sendable` mutation of view-model state from `withTaskCancellationHandler.onCancel` (Codex H4); all `pendingCancellations` writes happen on MainActor

- [x] **Task 2 — `ContentView` + App re-skin (AC #1, AC #3, AC #4, AC #5, AC #13, DDs #10, #12, #15, #16)**
  - [x] 2.1: Replace the Story 5-1 placeholder `VStack { Text("Drop an audio file") ... }` with a state-driven render: switch over the observed view-model state to produce one of four PRIMARY sub-views (empty / analyzing / result / error-only) PLUS a secondary `errorBanner` rendered above/below the primary view when `errorMessage != nil` and the primary view is `analyzing` or `result` (DD #16). Implementation hint — use a private `enum DisplayState { case empty, analyzing(filename: String?, cancelling: Bool), result(BPMResultRow), errorOnly(String) }` computed from `viewModel`; the secondary `bannerError: String?` is computed separately. The `BPMResultRow` is a private struct holding 5 pre-formatted strings (file name, BPM, confidence %, intensity, elapsed seconds) — keeps formatting out of the view body
  - [x] 2.2: Wire `.dropDestination(for: URL.self)` on the root `VStack`. Closure body: `return viewModel.handleDrop(urls)`. `isTargeted:` callback updates `@State private var isDropTargeted: Bool = false`. Add `.contentShape(Rectangle())` AFTER `.frame(maxWidth: .infinity, maxHeight: .infinity)` and BEFORE `.dropDestination(...)` so padded margins register drops (Axiom A2 — `transferable-ref.md:622-635`). Overlay a 1pt accent-color `.stroke` border on the VStack when `isDropTargeted == true` (DD #12)
  - [x] 2.3: Wire `.onOpenURL { url in viewModel.handleOpenURL(url) }` at the `WindowGroup { ContentView() }` body in `BoomBoomBoomKitDemoApp.swift` OR at the ContentView root (either works — pick the location where `viewModel` is accessible). This is the LaunchServices document-open path (DD #15 / Codex C2 close-out). The `viewModel` must be lifted from `ContentView`'s `@State` to the app level if `.onOpenURL` lives on the WindowGroup; alternative: keep `viewModel` in ContentView and add `.onOpenURL` to ContentView. Pick the alternative (simpler — no App-level state needed; ContentView's existing `@State private var viewModel = AnalysisViewModel()` is unchanged)
  - [x] 2.4: SKIP the hidden Escape-key button per DD #7 (downgrade from original spec). If the dev agent finds an isolated case during Task 8 manual smoke-testing where Escape would help, add a Completion-Notes-only experimental affordance with a comment "Story 5-2 experimental; Story 5-3 may promote." Not part of AC #12. If implemented, add a `func cancelInFlight()` on `AnalysisViewModel` that cancels every task in `inFlightTasks` and inserts each task's UUID into `pendingCancellations` — symmetric with the cancel-all-prior cascade
  - [x] 2.5: Layout the result view per DD #10: 5 `HStack { Text("Label:"); Spacer(); Text(value).monospacedDigit() }` rows wrapped in a VStack. Format strings per DD #10: BPM `%.1f BPM`, confidence `%.0f%%`, elapsed seconds `%.2fs`, intensity raw Int, file name verbatim from `viewModel.fileName ?? "—"`
  - [x] 2.6: Render "Cancelling previous analysis…" copy as a secondary `Text` below the activity indicator when `viewModel.isCancelling && viewModel.isAnalyzing` (i.e., `!pendingCancellations.isEmpty && isAnalyzing`). Style: `.font(.callout).foregroundStyle(.secondary)`. Note `isCancelling` is the computed property reading `pendingCancellations`; the View binds to it as if it were a stored property because @Observable tracks the underlying set
  - [x] 2.7: Render the DD #16 error banner: when `viewModel.errorMessage != nil` AND the primary state is `analyzing` OR `result`, append a single-line `Text(viewModel.errorMessage ?? "")` below the primary content with `.font(.callout).foregroundStyle(.red)`. The banner clears automatically when the next successful analyze sets `errorMessage = nil` (Story 5-1 behavior, unchanged)

- [x] **Task 3 — `INFOPLIST_KEY_CFBundleDocumentTypes` (AC #7, AC #13, DDs #8, #15, W3 close-out)**
  - [x] 3.1: Add `INFOPLIST_KEY_CFBundleDocumentTypes` to the app target's Debug + Release build settings in `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj`. The value is a multiline string that Xcode serializes into a plist array of 6 dicts. Use the `INFOPLIST_KEY_<key>` pattern (build-setting-form, synced to `GENERATE_INFOPLIST_FILE = YES`)
  - [x] 3.2: Resolve the built `.app` path via the actual xcodebuild output. Either:
    - (a) Run `xcodebuild -project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj -scheme BoomBoomBoomKitDemo -showBuildSettings | grep -E 'TARGET_BUILD_DIR|FULL_PRODUCT_NAME'` and read the path from the output
    - (b) Run `make demo-build` and read DerivedData via `xcodebuild ... -resultBundlePath <path>` introspection, OR
    - (c) Easiest: open the built bundle in DerivedData manually and `plutil -p <path>/Contents/Info.plist | grep -A 80 CFBundleDocumentTypes`. Codex H9 flagged that `$(make demo-build-out)` was a non-existent Makefile syntax in the original spec; option (c) is the workaround. If the dev agent wants automation, add a `make demo-build-path` Makefile target that prints the path (small extension to `make demo-build`)
  - [x] 3.3: Verify the plutil output matches AC #7 byte-for-byte: 6 entries with `CFBundleTypeRole = Viewer`, `LSItemContentTypes` per the 6 UTIs (`public.wav`, `public.aiff`, `public.mp3`, `org.xiph.flac`, `public.mpeg-4-audio`, `com.apple.coreaudio-format`), first entry `LSHandlerRank = Default`, others `Alternate`
  - [x] 3.4: **R2 FALLBACK** — if `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting form fails after 30 minutes of dev time, fall back to a hand-written partial Info.plist at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` with `<key>CFBundleDocumentTypes</key>` as a native plist array of dicts. Update build settings: `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` + `GENERATE_INFOPLIST_FILE = NO`. AC #7's plutil recipe works on either form. Add `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` to the file list (Project Structure Notes) if used. Flag in Completion Notes
  - [x] 3.5: Mark W3 CLOSED in `_bmad-output/implementation-artifacts/deferred-work.md` with cross-reference to the Story 5-2 commit (note that closure depends on BOTH the Info.plist key AND the DD #15 `.onOpenURL` handler — both are required for the Dock + Open-With path to work end-to-end)

- [x] **Task 4 — `make demo-lint` + `make demo-fmt` + `make pre-commit` Makefile targets (AC #8, AC #11, DD #9, W16 close-out)**
  - [x] 4.1: Add the `demo-lint` target to `Makefile` per DD #9's regex (covers both quoted and unquoted forms, scans recursively across `Demo/**/project.pbxproj`):
    ```makefile
    ## demo-lint: Guard against DEVELOPMENT_TEAM leak across all Demo/.pbxproj files
    .PHONY: demo-lint
    demo-lint:
    	@if grep -rnE 'DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*"?[A-Z0-9]{10}"?[[:space:]]*;' Demo/ --include='project.pbxproj'; then \
    		echo "ERROR: DEVELOPMENT_TEAM leak detected in Demo/ .pbxproj — must be empty for public release."; \
    		exit 1; \
    	fi
    ```
  - [x] 4.2: Add the `demo-fmt` target (Codex M11 — Story 5-1's `make fmt` does NOT cover `Demo/`):
    ```makefile
    ## demo-fmt: Format Swift source code in Demo/
    .PHONY: demo-fmt
    demo-fmt:
    	swift format --recursive --in-place Demo/
    ```
    Alternative: extend `make fmt` directly to add `Demo/` to its path list. Pick one; the dev agent's call
  - [x] 4.3: Add the `pre-commit` aggregate target wrapping `fmt`, `demo-fmt`, `lint`, `demo-lint`:
    ```makefile
    ## pre-commit: Run all pre-PR gates (fmt + lint, library and demo)
    .PHONY: pre-commit
    pre-commit: fmt demo-fmt lint demo-lint
    ```
  - [x] 4.4: Verify recipe inversion: temporarily plant `DEVELOPMENT_TEAM = S85RR68YT7;` (UNQUOTED form — the case the original spec's regex missed) in the demo's pbxproj, confirm `make demo-lint` exits non-zero with the file:line message, revert immediately (Story 5-1 Task 9.4 pattern). Repeat with the quoted form `DEVELOPMENT_TEAM = "S85RR68YT7";` to confirm both forms trip the guardrail
  - [x] 4.5: Mark W16 CLOSED in `deferred-work.md` with cross-reference

- [x] **Task 5 — Test target additions (AC #10, DD #13)**
  - [x] 5.1: Edit `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift`. Keep the existing `wrapping` `@Test`; add `#expect(viewModel.isCancelling == false)` and `#expect(viewModel.pendingCancellations.isEmpty)` to its post-completion assertions per AC #9
  - [x] 5.2: Add 4 new `@Test`s per DD #13:
    - `rejectsEmptyDrop`: `validateDropPayload([])` → `.failure(.empty)`
    - `rejectsMultiFileDrop`: `validateDropPayload([url1, url2])` → `.failure(.multipleFiles)`
    - `rejectsUnsupportedType`: parameterized over 5 negative extensions — `txt`, `ogg`, `png`, `m4b`, `mp4` (the last two specifically verify Codex H5's UTType-conformance widening is prevented by the extension-matching approach)
    - `acceptsSupportedTypes`: parameterized over the 6 supported extensions — `wav`, `aiff`, `mp3`, `flac`, `m4a`, `caf`
    All `@MainActor` (the validator is `static` and not MainActor-bound, but `@MainActor` keeps the suite consistent). Use `arguments: [...]` (single collection) for `acceptsSupportedTypes` and `rejectsUnsupportedType`
  - [x] 5.3: Add 1 `@Test` for `handleDrop` state transitions using `arguments: zip(failureCases, expectedMessages)` per Axiom A5 (`swift-testing.md:213-217`):
    ```swift
    @Test("handleDrop populates errorMessage on validation failure",
          arguments: zip(failureURLs, expectedMessages))
    @MainActor
    func handleDropStateTransitions(_ urls: [URL], _ expected: String) {
      let vm = AnalysisViewModel()
      #expect(vm.handleDrop(urls) == false)
      #expect(vm.errorMessage == expected)
      #expect(vm.isAnalyzing == false)
      #expect(vm.detectedBPM == nil)
    }
    ```
    The `failureURLs` collection holds: `[]` (empty), `[url1, url2]` (multi), `[txtURL]` (unsupported). The `expectedMessages` collection holds the 3 corresponding verbatim AC #2 strings
  - [x] 5.4: Confirm `make demo-test` passes with the expanded suite

- [x] **Task 6 — W17 "Cancelling…" copy + sandbox-denied path (AC #3, AC #6, DDs #4, #6)**
  - [ ] 6.1: Verify (manually) that the "Cancelling…" copy appears when dropping file B mid-analyze of file A at default intensity 7. Recipe: drop a long-running file (e.g., `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/Submerged_Lament.mp3` which is large), immediately drop a second file before the first completes, watch for the copy
  - [ ] 6.2: Verify (manually) the sandbox-denied path: drop a file from a location the sandbox SHOULD permit (Desktop / Downloads); confirm read succeeds. The sandbox-denied path is hard to provoke deterministically without quarantine games; document the path as "best-effort manual verification" — the code path executes regardless of whether `startAccessingSecurityScopedResource` returns true or false; the Bool is consulted only for the `defer` balance
  - [x] 6.3: Mark W17 CLOSED in `deferred-work.md`. Mark W1 PARTIALLY-CLOSED (the per-task UUID discriminator addresses the user-cancel / superseded-by-new disambiguation; the SwiftUI parent-task / scene-phase / window-close edges remain open and re-open under Story 5-3+ when there are more UI affordances)

- [x] **Task 7 — Gating gauntlet (AC #11)**
  - [x] 7.1: Run `make fmt && make lint` — both clean (only the canonical LUFSAnalyzer:94 TODO baseline)
  - [x] 7.2: Run `make build && make build-release` — both succeed
  - [x] 7.3: Run `make test` — library tests pass, record wall-clock for A3 continuity
  - [x] 7.4: Run `make demo-build && make demo-test` — both succeed
  - [x] 7.5: Run `make demo-lint` — exits 0
  - [x] 7.6: Run `make pre-commit` — the aggregate exits 0
  - [x] 7.7: Run `make demo-build-sandboxed` — exits 0 (RT's machine has `DEVELOPMENT_TEAM` configured)
  - [x] 7.8: Run `make benchmark` — Acc1=57/82, Acc2=73/82 (UNCHANGED — sanity check)
  - [x] 7.9: Run `make benchmark-giantsteps` — Acc1=537/661, Acc2=546/661 (UNCHANGED)

- [ ] **Task 8 — Manual smoke test (AC #12)**
  - [x] 8.1: Launch the sandboxed build (`make demo-build-sandboxed && open <DerivedData path>/Build/Products/Debug/BoomBoomBoomKitDemo.app` or run from Xcode)
  - [ ] 8.2: Drop a `.wav` file — verify result renders with BPM / confidence / intensity / elapsed seconds
  - [ ] 8.3: Drop a `.txt` file — verify "Unsupported file type" error renders
  - [ ] 8.4: Drop 2 files at once — verify "Drop a single audio file" error renders
  - [ ] 8.5: Drop file A (large; `Submerged_Lament.mp3`), drop file B within 500ms — verify "Cancelling previous analysis…" copy appears, then B's result renders (no leftover state from A)
  - [ ] 8.6: Press Escape while analyzing — verify analysis cancels and `isAnalyzing` resets to false (the result fields stay empty; the user sees the empty-state UI again)
  - [ ] 8.7: From Finder, right-click a `.wav` → Open With — verify BoomBoomBoomKitDemo appears in the Alternate handlers (or the system shows it when the user expands the list)
  - [ ] 8.8: Drag a `.wav` onto the running app's Dock icon — verify the drop is delivered (the OS may surface a "Open in BoomBoomBoomKitDemo" affordance OR open the file directly; either is acceptable proof of `CFBundleDocumentTypes` wiring)
  - [ ] 8.9: Record the outcomes verbatim in Completion Notes

- [ ] **Task 9 — Completion Notes + Status flip + sprint-status update (AC #14)**
  - [x] 9.1: Write Completion Notes recording: A3 wall-clock baseline delta vs Story 5-1; all 9 manual smoke-test outcomes; the `plutil` Info.plist verification output for `CFBundleDocumentTypes`; the W3 / W16 / W17 CLOSED annotations + W1 PARTIALLY-CLOSED annotation in `deferred-work.md`; any build-time discoveries (the dev agent's analog of Story 5-1's "Build-time discoveries" section)
  - [x] 9.2: Flip story Status `ready-for-dev` → `in-progress` → `review` (or `done` if code review is run inline)
  - [x] 9.3: Update `_bmad-output/implementation-artifacts/sprint-status.yaml`: `5-2-core-analysis-flow: backlog` → `in-progress` → `review/done`; update `last_updated:` line with a one-paragraph commit summary per Epic 4 retro convention
  - [ ] 9.4: Run `/bmad-code-review` (3-layer parallel review: Blind Hunter + Edge Case Hunter + Acceptance Auditor; optional Codex 4th layer). Apply patches; defer findings to `deferred-work.md` per Story 5-1 DD #11 A2 (no story-file `[ ]` checkboxes for review findings)
  - [ ] 9.5: Final commit with imperative-mood subject per project-context.md:131 — `Story 5-2: file drop + BPM display in demo app`

## Dev Notes

### Architecture references

- **Story 5-1 spec — the scaffold this story builds on:** `_bmad-output/implementation-artifacts/5-1-demo-app-project-scaffold.md`. Critical inherited DDs: #5 (view-model wrapping contract), #6 (`make demo-build` target), #7 (`DEVELOPMENT_TEAM=""` discipline), #8 (entitlements file), #16 (audio-file exposure schema including A: zero audio in bundle, B: 6-UTI whitelist, C: whitelist demo-local, D: split exposed/operational state, E: cancel-all-prior cascade), plus all 9 deferred-work entries (W1-W19 in `deferred-work.md`)
- **Public API surface the view model wraps:** `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-58` (`AudioAnalysisResult` — 7 public fields: bpm, confidence, candidates, trace, metadataEvidence, effectiveIntensity, degradationReason), `:298-302` (`analyzeBPM(url:)` default entry), `:321-324` (`analyzeBPM(url:options:)` parameterized entry). Story 5-2 reads `bpm`, `confidence`, `effectiveIntensity`; ignores `candidates`, `trace`, `metadataEvidence`, `degradationReason` (those surface in Stories 5-3 / 5-4)
- **Error types from the public API:** `Sources/BoomBoomBoomKit/PCMBufferReader.swift:13-17` — `PCMBufferReaderError` has 4 cases (`fileNotReadable`, `bufferAllocationFailed`, `readFailed`, `conversionFailed`). Story 5-2 surfaces them all via the same `"Could not read audio file: \(error)"` template (Story 5-1 behavior, unchanged) and adds the `" (sandbox denied)"` suffix for the specific case in AC #6
- **SwiftUI drop API reference:** `/Users/rterhaar/.claude/plugins/cache/axiom-marketplace/axiom/3.5.0/skills/axiom-swift/skills/transferable-ref.md:343-380,624-635` — `.dropDestination(for:isTargeted:perform:)` pattern + frame-required hit-test caveat. Use `.dropDestination(for: URL.self) { urls, location in ... } isTargeted: { isTargeted in self.isDropTargeted = isTargeted }`. The hit-test caveat from line 624 ("requires the view to have a non-zero frame") is satisfied by the existing `.frame(maxWidth: .infinity, maxHeight: .infinity)` modifier in ContentView (Story 5-1 already set it)
- **Security-scoped resource API reference:** Apple's "Accessing Files from the macOS App Sandbox" at https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox. Key functions: `URL.startAccessingSecurityScopedResource() -> Bool` and `URL.stopAccessingSecurityScopedResource()`. Pre-1.0 stability: stable since macOS 10.7. The `Bool` return value matters: if true, you must balance with a stop; if false, you do not call stop (calling stop on an unbalanced URL is a runtime warning, not a crash, but it's a discipline failure)
- **`CFBundleDocumentTypes` reference:** Apple's "CFBundleDocumentTypes" key documentation at https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundledocumenttypes. The `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting prefix is the Xcode-15+ pattern for synthesizing Info.plist entries from build settings — preferred over a hand-written partial Info.plist (DD #8 rationale)
- **AmbientUI demo precedent:** The AmbientUI demo at `/Users/rterhaar/Dropbox/research/swift/AmbientUI/Demo/AmbientUIDemo/AmbientUIDemo/ContentView.swift` does NOT use drop — it's a UI theming demo. There is no direct precedent in `AmbientUI` for the drop pattern; the dev agent leans on the `transferable-ref.md` skill and Apple's docs

### Project Structure Notes

- Library target `BoomBoomBoomKit` — UNCHANGED in Story 5-2 (zero `Sources/` or `Tests/` library modifications expected)
- `BoomBoomBoomKitTestSupport`, `BoomBoomBoomKitML`, `BoomBoomBoomKitBenchmarkTests`, `BoomBoomBoomKitTests` — UNCHANGED
- `Demo/BoomBoomBoomKitDemo/` — modified files:
  - `BoomBoomBoomKitDemo/AnalysisViewModel.swift` — additions for AC #9 + AC #10 (estimated +60 lines on top of the Story 5-1 158-line baseline)
  - `BoomBoomBoomKitDemo/ContentView.swift` — re-skin for AC #1 / #3 / #4 / #5 (estimated +80 lines on top of the Story 5-1 17-line baseline)
  - `BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — `INFOPLIST_KEY_CFBundleDocumentTypes` addition for AC #7 (build-setting addition, no synchronized-group changes)
  - `BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — expanded for AC #10 (~120 lines total)
- `Makefile` — `demo-lint` + `pre-commit` targets added per AC #8
- `_bmad-output/implementation-artifacts/deferred-work.md` — W3 / W16 / W17 marked CLOSED inline; W1 marked PARTIALLY-CLOSED
- `_bmad-output/implementation-artifacts/5-2-core-analysis-flow.md` — this story file
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flip + `last_updated:` summary
- No new SPM dependencies, no `Package.swift` changes
- No new audio files anywhere — `find Demo -type f \( -name '*.wav' -o -name '*.aiff' -o -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' -o -name '*.caf' \)` MUST still return zero matches at close-out (Story 5-1 DD #16-A continuity)

### Risk

- **R1 — `.dropDestination(for: URL.self)` payload includes URLs that don't resolve to real files (cloud documents, deleted files, alias-with-broken-target).** Apple's docs do not guarantee that every dropped URL maps to a readable on-disk file. `PCMBufferReader.readMonoSamples` opens via `AVAudioFile(forReading:)` which throws `fileNotReadable` on these edge cases — Story 5-1's error handling already covers them via the generic `"Could not read audio file: \(error)"` template. No additional defense needed in Story 5-2. **Test path:** would require a synthesized broken URL; not worth the test machinery for a path the library already covers
- **R2 — `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting syntax is finicky.** Multiline string values in `.pbxproj` need careful escaping. If the build-setting form proves intractable in practice, fall back to a hand-written partial Info.plist at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` and set `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` + `GENERATE_INFOPLIST_FILE = NO`. The fall-back adds a parallel file to maintain, but is more readable. **Decision threshold:** if the build-setting form takes more than 30 minutes to get green, fall back to the partial Info.plist
- **R3 — Per-task UUID discriminator + `pendingCancellations` Set interaction with the existing `Atomic<Bool>` cancellation flag is subtle.** The cancel-all-prior cascade in `analyze(url:autoStarted:)` (MainActor) inserts each prior task's UUID into `pendingCancellations` and calls `task.cancel()`. The library polls each prior task's `Atomic<Bool>` flag at window boundaries. When a prior task throws `CancellationError`, its MainActor-re-entry recognizes itself as superseded (`currentTaskID != taskID`) and the cleanup Task removes `taskID` from `pendingCancellations`. All mutations of `pendingCancellations` happen on MainActor — Swift serializes MainActor work, so no race on the set. The `Atomic<Bool>` flags are per-task (each `analyze` call allocates a fresh atomic per Story 5-1's pattern), so no cross-task atomic contention. Cite: `axiom-concurrency/skills/synchronization.md:308-318` (Memory Ordering Quick Reference) for the inherited `.acquiring` / `.releasing` ordering. **Verification:** Task 5.2 + 5.3's parameterized tests exercise the state-transition logic in isolation; the manual smoke test (Task 8.5) exercises the multi-second cancel window end-to-end
- **R4 — Manual Dock-icon-drop / Finder-Open-With verification (Task 8.7, 8.8) is environment-dependent.** macOS caches handler registrations via `lsregister`; a freshly-built app may not surface in Finder's Open With submenu until `lsregister` re-scans. **Mitigation:** the dev agent runs `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user -f $(make demo-build-out)/Build/Products/Debug/BoomBoomBoomKitDemo.app` before the manual test, then opens Finder freshly. AC #7 explicitly notes the Dock-icon and Finder paths as "manually verified — NOT an automated test" because the OS layer is not test-harness-able from Swift Testing
- **R5 — The hidden Escape-key button (DD #7) participates in the responder chain.** If placed inside a sub-view that loses focus on a state transition (e.g., when switching from `analyzing` to `result`), the keyboard shortcut may stop responding mid-analyze. **Mitigation:** place the hidden button at the root `VStack` level via `.background { Button("").keyboardShortcut(.cancelAction).hidden() }` so it stays in the responder chain across all four DisplayState arms. Verify in Task 8.6 (Escape during analyze)
- **R6 — `viewModel.cancelInFlight()` doesn't mint a new `currentTaskID`, so the current task's MainActor-re-entry resets `isAnalyzing = false` correctly per DD #5.** But `cancelInFlight()` DOES need to set `isCancelling = true` so the UI renders the "Cancelling…" copy until the in-flight task acknowledges. Pattern: `cancelInFlight()` iterates `inFlightTasks` and `.cancel()`s each (same as `analyze(url:)`'s prior-task cascade); ALSO sets `isCancelling = true`. The existing task's MainActor-re-entry path resets BOTH `isAnalyzing` and `isCancelling` to false (since `currentTaskID == taskID` for the unsuperseded current task)
- **R7 — Story 5-1 PP8 added `@ObservationIgnored` to `inFlightTasks`. Story 5-2 must apply the same annotation to the new `currentTaskID: UUID?` property.** Per Story 5-1's PP8 rationale: `@Observable` tracks all stored properties unless excluded; operational state (not read by any View) is noise. `currentTaskID` is operational (read only inside `analyze(url:)` task bodies). Apply the annotation; AC #9 surface-asserts it. NOTE: `pendingCancellations: Set<UUID>` does NOT get `@ObservationIgnored` because the View consumes it via the derived `isCancelling: Bool` — the @Observable macro must track the set so SwiftUI re-renders the "Cancelling…" copy on mutation
- **R8 — Axiom `sandbox-and-file-access.md` disagrees with DD #4's defensive bracket pattern for window drops.** Axiom's skill table at lines 301-311 treats Dock-icon drops as auto-started (no `.start` call needed); the table is silent on SwiftUI window drops. Apple's web docs at https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox also do not enumerate window drops in the auto-start list. **Resolution applied:** DD #4 distinguishes window-drop (defensive `start` + balanced `stop`) from `.onOpenURL` (`stop`-only). The `autoStarted: Bool` parameter on `analyze(url:autoStarted:)` is the runtime discriminator. If a future macOS release makes window-drop URLs explicitly auto-started, the spec needs to revisit — but until Apple makes that promise, defensive bracketing is the safer pattern. Axiom skill citation added to References. Cite: `axiom-macos/skills/sandbox-and-file-access.md:301-311`
- **R9 — `pendingCancellations: Set<UUID>` as an observed property may inflate the @Observable change-tracking surface in ways that affect SwiftUI render frequency.** Each insert / remove triggers a view-graph invalidation. Story 5-2 has at most 1-2 prior tasks draining at any time (the user can't drop files faster than the UI updates). The change-tracking cost is negligible at this scale. Fix if a future story with more in-flight tasks observes render thrashing: introduce a debounced `isCancellingDisplay: Bool` that batches mutations, OR move `pendingCancellations` to `@ObservationIgnored` and surface `isCancelling` via a separate observed Bool that the view-model updates explicitly

### Apple Platform / SwiftUI / Sandbox Notes

#### SwiftUI `.dropDestination(for:isTargeted:perform:)`

Per `transferable-ref.md:343-355,624-635`:

```swift
.dropDestination(for: URL.self) { urls, location in
  // urls: [URL] payload (typically 1 element for a single file drop;
  // multiple for batch drops which Story 5-2 explicitly rejects)
  // location: CGPoint in the local coordinate space (unused here)
  return viewModel.handleDrop(urls)
} isTargeted: { isTargeted in
  self.isDropTargeted = isTargeted
}
```

The view must have a non-zero frame. ContentView's root VStack already has `.frame(maxWidth: .infinity, maxHeight: .infinity)` from Story 5-1, so this is satisfied. The `.padding()` does not interfere with hit-testing.

The closure is called on the MainActor (SwiftUI dispatches drop callbacks to MainActor by default). `viewModel.handleDrop(urls)` is `@MainActor`-isolated (inherited from `AnalysisViewModel`), so the call site is clean.

#### Security-scoped resource bracketing

Per Apple's docs (https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox):

```swift
let didStart = url.startAccessingSecurityScopedResource()
// ... use the URL ...
if didStart {
  url.stopAccessingSecurityScopedResource()
}
```

The `Bool` semantics: `true` means access was granted AND must be released by a matching stop call; `false` means access was either not needed (e.g., the URL is from a non-sandboxed context) OR was denied. In both `false` cases, do NOT call stop. The pattern in DD #4 follows this discipline.

The bracket lives across the `Task.detached` boundary — the `defer` is inside the outer `Task { ... }` body (which runs ~1-30 seconds), NOT in the `analyze(url:)` synchronous prologue (which returns in microseconds). The outer Task captures `url` and `didStart` and balances the bracket on Task body completion (success, error, or cancellation).

**Caveat:** SwiftUI's `.dropDestination(for: URL.self)` may auto-bracket the URLs it delivers — Apple's docs are not explicit. The defensive pattern is to bracket anyway; double-bracketing is safe (`startAccessing` returns `false` on already-bracketed URLs and the matching `stop` is gated on the Bool). The cost is one extra syscall pair per drop, which is negligible.

#### `INFOPLIST_KEY_CFBundleDocumentTypes` build-setting form

Per Apple's "Build settings reference" (https://developer.apple.com/documentation/xcode/build-settings-reference): `INFOPLIST_KEY_<plist-key>` build settings synthesize into the generated Info.plist when `GENERATE_INFOPLIST_FILE = YES`. The value of `INFOPLIST_KEY_CFBundleDocumentTypes` is a string that Xcode interprets as a plist fragment — typically a JSON-like array of dictionaries.

Example (verbatim shape; the dev agent adapts the LSItemContentTypes / LSHandlerRank values per DD #8):

```
INFOPLIST_KEY_CFBundleDocumentTypes = "(\n\t{\n\t\tCFBundleTypeRole = Viewer;\n\t\tLSHandlerRank = Default;\n\t\tLSItemContentTypes = (\"public.wav\");\n\t},\n\t{\n\t\tCFBundleTypeRole = Viewer;\n\t\tLSHandlerRank = Alternate;\n\t\tLSItemContentTypes = (\"public.aiff\");\n\t},\n\t...\n)";
```

This is finicky to write in `.pbxproj` because the multiline string needs escaping. The R2 fall-back is a hand-written partial Info.plist at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` with the `CFBundleDocumentTypes` key written as native plist XML, and `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` + `GENERATE_INFOPLIST_FILE = NO` in build settings.

#### Swift 6 concurrency (`@Observable` + `@ObservationIgnored`)

`@Observable` macro applies observation tracking to ALL stored properties unless excluded via `@ObservationIgnored` (Story 5-1 PP8 rationale). Story 5-2's new `currentTaskID: UUID?` is operational state (consumed only inside `analyze(url:)` task bodies, never by a View) — apply `@ObservationIgnored`.

The new `isCancelling: Bool` IS observed (the View reads it to decide whether to render "Cancelling…" copy) — do NOT annotate it.

The fire-and-forget cleanup pattern from Story 5-1 D5 is unchanged. `inFlightTasks: Set<Task<Void, Never>>` is unchanged.

#### Swift Testing (parameterized tests)

Per `transferable-ref.md:343-355` and project-context.md:94 (Swift Testing rules):

```swift
@Test("accepts supported audio extensions",
      arguments: ["wav", "aiff", "mp3", "flac", "m4a", "caf"])
@MainActor
func acceptsSupportedTypes(_ ext: String) throws {
  let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
  let result = AnalysisViewModel.validateDropPayload([url])
  guard case .success(let resolved) = result else {
    Issue.record("expected .success for .\(ext); got \(result)")
    return
  }
  #expect(resolved == url)
}
```

The validator is a `static func` so the test does not need to construct an `AnalysisViewModel`. The `@MainActor` annotation is for consistency with the suite's other tests (which DO construct view models).

### Previous Story Intelligence

Story 5-1 (immediately prior, close-out 2026-05-19 after pass-1 + pass-2 code reviews + PR #3 Copilot review):

- **Test count band discipline (HALT-(d) precedent)** — Story 5-1 added zero library tests; count stayed at 433 `@Test(` declarations. Story 5-2 expects the same: zero library `Tests/` changes, expanded demo-target test count only. No HALT-(d) band for the library count
- **A2 ledger discipline (`deferred-work.md` is canonical)** — Story 5-1 established the pattern. Story 5-2 continues: every applied patch + every newly-deferred item gets a one-line `deferred-work.md` entry; story-file `[ ]` checkboxes track tasks only. Story 5-1 W1-W19 entries are inherited; Story 5-2 closes W3 / W16 / W17 inline and partially closes W1
- **A3 wall-clock baseline tracking** — Story 5-1 recorded cold-cache 6.84s / warm-cache 2.01s `make test` on M5 Max as Epic 5 baseline. Story 5-2 records the post-Story-5-2 wall-clock + delta; expected delta is 0% (zero library changes)
- **Atomic ordering + cancellation patterns** — Story 5-1 D1 patch introduced the `Atomic<Bool>` + `withTaskCancellationHandler` cancellation hand-off into `Task.detached`; PP1 hardened the ordering to `.acquiring` (load) / `.releasing` (store). Story 5-2 inherits this pattern unchanged; the new `currentTaskID` discriminator is a separate concern (MainActor-isolated UUID, not a cross-task atomic)
- **Cancel-all-prior cascade (D5 patch)** — Story 5-1 replaced single-handle `analysisTask?.cancel()` with `inFlightTasks: Set<Task<Void, Never>>` iterating + cancelling each. Story 5-2's `cancelInFlight()` method reuses the same cascade (without launching a new task); the per-task UUID discriminator complements it without rewiring
- **`@ObservationIgnored` discipline (PP8 patch)** — Story 5-1 PR #3 Copilot review surfaced that `@Observable` macro tracks ALL stored properties unless explicitly excluded. Operational state (`inFlightTasks`) is noise; apply `@ObservationIgnored`. Story 5-2's new `currentTaskID: UUID?` follows the same pattern
- **`deinit` cancellation backstop (PP8 patch)** — Story 5-1 PR #3 added `deinit { for task in inFlightTasks { task.cancel() } }`. Story 5-2's per-task UUID discriminator does not change this; the deinit pattern still fires on view-model deallocation. The W12 reachability profile (SwiftUI parent-task cancellation propagation) becomes real once Story 5-2's drop UI lands — partially mitigated by the DD #5 discriminator (the `currentTaskID == taskID` check during MainActor-re-entry correctly resets `isAnalyzing = false` when the deinit cancels the current task)
- **Spec doc-drift discipline (PP2-PP7 patches)** — Story 5-1's pass-2 code review surfaced multiple cases where ACs / DDs / Tasks were updated for a patch but sibling references weren't kept symmetric. Story 5-2's reviewer should perform a symmetric-references sweep: every AC text that references a DD, every DD that references another DD, every Task that quotes a code snippet — verify they all agree

Epic 4 retro (close-out 2026-05-17):

- **A2 + A3 carried into Epic 5 (Story 5-1 DD #11)** — Story 5-2 honors both. A2: findings flow to `deferred-work.md`. A3: wall-clock baseline tracked per epic
- **T2 — CLAUDE.md Key Types sweep for Epic 4 additions** — flagged as a Story 5-5 precondition. Story 5-2 does NOT touch CLAUDE.md (no public API changes; library is byte-untouched). Story 5-5 owns the sweep

### References

- `_bmad-output/planning-artifacts/epics.md:1285-1308` — Story 5.2 acceptance criteria (as written; Story 5-2 spec expands them per AC #1-#13)
- `_bmad-output/planning-artifacts/epics.md:237-242` — Epic 5 preamble (sequencing, dependencies)
- `_bmad-output/planning-artifacts/architecture.md:161-180` — Demo App Structure decision (AmbientUI pattern reference; demo ships on main, SwiftUI + `@Observable`, public-API-only)
- `_bmad-output/planning-artifacts/architecture.md:484-488` — Demo app boundary (public-API-only, ships on main)
- `_bmad-output/planning-artifacts/prd.md:62-66` — Phase 3D Developer Experience scope (library packaged for external consumption; demo app available as in-repo SPM target)
- `_bmad-output/planning-artifacts/prd.md:164-182` — Journey 4 (Power User — Algorithm Evaluation via Demo App) — the canonical consumer narrative that Story 5-2 starts to satisfy (the "drops an audio file into the window" line lands here)
- `_bmad-output/planning-artifacts/prd.md:560-569` — FR34-FR41 (Demo Application functional requirements). Story 5-2 fulfills FR35 (drop + display), FR38 (responsive feedback), FR39 (wall-clock time display). FR36/FR37/FR40/FR41 remain for Stories 5-3/5-4
- `_bmad-output/implementation-artifacts/5-1-demo-app-project-scaffold.md` — Story 5-1 spec; canonical reference for all inherited DDs, AC patterns, and review-finding lineage
- `_bmad-output/implementation-artifacts/deferred-work.md` — W1-W19 from Story 5-1's code reviews. Story 5-2 closes W3 / W16 / W17 inline + partially closes W1
- `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md:100-108` — A2 + A3 action items (Story 5-1 was the trigger; Story 5-2 continues)
- `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md:141-153` — Epic 5 preparation findings (does NOT need re-planning; the 5 stories remain valid as written)
- `_bmad-output/project-context.md` — all project-level rules. Notably: "Public API Discipline (pre-1.0)" subsection (Story 5-2 honors it by adding zero public types to the library); `nonisolated(unsafe)` discipline (Story 5-2 uses NONE); testing rules (Swift Testing + `@MainActor` annotation pattern)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-58` — `AudioAnalysisResult` public surface (7 fields)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:298-302,321-324` — `analyzeBPM` overloads
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — public `AnalysisIntensity` surface
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift:13-17` — `PCMBufferReaderError` 4-case enum
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — Story 5-1 scaffold the view model (158 lines as of `e0c234f`); Story 5-2 extends this
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — Story 5-1 scaffold the view (17 lines as of `e0c234f`); Story 5-2 re-skins this
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — Story 5-1 scaffold the smoke test (36 lines as of `e0c234f`); Story 5-2 expands to ~120 lines
- `/Users/rterhaar/.claude/plugins/cache/axiom-marketplace/axiom/3.5.0/skills/axiom-swift/skills/transferable-ref.md:343-380,624-635,638-653` — SwiftUI `.dropDestination` pattern + frame caveat + async loadTransferable pattern (the third section is not directly used in 5-2 because URL.self does not require loadTransferable; included for Story 5-3+ reference)
- Apple — "Accessing Files from the macOS App Sandbox" — https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox — security-scoped resource semantics
- Apple — "CFBundleDocumentTypes" — https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundledocumenttypes — Info.plist key reference
- Apple — "Build settings reference" — https://developer.apple.com/documentation/xcode/build-settings-reference — `INFOPLIST_KEY_*` synthesis pattern
- `MEMORY.md` — user preferences. Notable: no emojis in Makefiles / echo / code artifacts; no business jargon in commits; BC is NOT a goal pre-1.0; `make test` 10% delta tripwire per A3
- **Codex plan-review thread `019e42b4-8f0c-7ad0-b2f8-0857b65fa0ac`** (2026-05-19) — 14 findings (3 Critical, 6 High, 3 Medium, 2 Low). Critical findings C1/C2/C3 directly drove DD #5 restructure, DD #15 `.onOpenURL`, and DD #6 `Set<UUID>` redesign. High findings H4-H9 drove DD #6 (no @Sendable mutation), DD #2 (extension matching), DD #11 (DropError internal), AC #5/AC #11 (mixed-state precedence, demo-fmt), DD #9 (regex unquoted form), DD #8 (explicit fallback). Medium findings M10-M12 drove the `make lint` exit-code clarification, the `demo-fmt` addition, and the view-model-constructed error template. Low findings L13/L14 drove DD #7 downgrade and DD #9's "not a permanent contract" caveat
- **Axiom skill survey agent run `a19b99371f846e684`** (2026-05-19) — 7 amendments derived from reading `axiom-macos/skills/sandbox-and-file-access.md`, `axiom-swift/skills/transferable-ref.md`, `axiom-concurrency/skills/synchronization.md`, `axiom-concurrency/skills/swift-concurrency-ref.md`, `axiom-swiftui/skills/architecture.md`, `axiom-testing/skills/swift-testing.md`. A1 disagreed with DD #4's defensive bracket for window drops → resolution: split the bracket pattern by entry point. A2 caught the missing `.contentShape(Rectangle())` for padded margin hit-testing → patched DD #12 + Task 2.2. A3 noted Axiom's preference for `Task {}` over `Task.detached` → kept detached for Story 5-1 D1 continuity with a justifying sentence in DD #4. A4 caught AC #6 needs sandboxed-build precondition → patched AC #6. A5 suggested `zip` for paired Swift Testing args → applied in Task 5.3. A6 cited `synchronization.md:308-318` for the inherited ordering → added to R3. A7 added the axiom-macos cite to References
- **Axiom skill citations (paths under `/Users/rterhaar/.claude/plugins/cache/axiom-marketplace/axiom/3.5.0/skills/`):**
  - `axiom-macos/skills/sandbox-and-file-access.md:106-117` — debug builds NOT sandboxed by default
  - `axiom-macos/skills/sandbox-and-file-access.md:301-311` — auto-started access table (Dock drag-and-drop, panel URLs, etc.)
  - `axiom-macos/skills/sandbox-and-file-access.md:441` — "Calling startAccessing on panel URLs" anti-pattern
  - `axiom-swift/skills/transferable-ref.md:343-380` — `.dropDestination(for:isTargeted:perform:)` shape
  - `axiom-swift/skills/transferable-ref.md:622-635` — drop-target hit-testing (`.frame` + `.contentShape(Rectangle())`)
  - `axiom-concurrency/skills/synchronization.md:308-318` — Memory Ordering Quick Reference for `Atomic`
  - `axiom-concurrency/skills/swift-concurrency-ref.md:444-456` — `Task.detached` rarely needed; prefer `Task {}`
  - `axiom-swiftui/skills/architecture.md:303-309` — `@Observable @MainActor` view-model wrapping a non-UI service
  - `axiom-testing/skills/swift-testing.md:204-217` — parameterized tests with `arguments:` and `zip(...)`

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (`claude-opus-4-7`) via `/bmad-dev-story` workflow on 2026-05-19. Single-shot implementation; no HALT events fired.

### Debug Log References

- Build verification at every task boundary: `make demo-build` after AnalysisViewModel changes (one fixable error: `DropError` missing `Error` conformance; one fixable error: redundant unreachable switch case — both fixed inline and re-built). Subsequent ContentView build hit one fixable error: `import BoomBoomBoomKit` missing for `intensity.rawValue` access — added and re-built green.
- Info.plist build settings hit a copy-resources phase warning ("Copy Bundle Resources build phase contains this target's Info.plist file"); resolved by adding `PBXFileSystemSynchronizedBuildFileExceptionSet` excluding `Info.plist` from the synchronized root group's copy phase. Verified via `plutil -p .../Contents/Info.plist | grep -A 80 CFBundleDocumentTypes` — 6 entries with correct shape per AC #7.
- `make demo-lint` recipe inversion: planted `DEVELOPMENT_TEAM = S85RR68YT7;` (unquoted) → 6 lines matched + exit non-zero; planted `DEVELOPMENT_TEAM = "S85RR68YT7";` (quoted) → 6 lines matched + exit non-zero; reverted from `/tmp/pbxproj.bak` → exit 0.

### Completion Notes List

**Gating gauntlet outcomes (post-Story-5-2 close-out, M5 Max, 2026-05-19):**

- `make fmt` — clean (formatter no-op)
- `make demo-fmt` — clean (formatter no-op on Demo/ tree)
- `make lint` — 1 violation = canonical `LUFSAnalyzer.swift:94` TODO baseline; 0 serious
- `make build` — 0.10s, exit 0
- `make build-release` — 0.10s, exit 0
- `make test` — 431/431 pass in 94 suites; **wall-clock 1.74s real** (warm-cache); test count **unchanged 431 runs** vs Story 5-1 baseline 6.84s cold / 2.01s warm. Per-story delta vs Story 5-1: **0% library tests added** — Story 5-2 added zero `Sources/` or `Tests/` library changes (AC #11 A3 invariant intact)
- `make demo-build` — `BUILD SUCCEEDED`
- `make demo-test` — `TEST SUCCEEDED`; **18 demo test cases pass** (1 wrapping + 1 rejectsEmptyDrop + 1 rejectsMultiFileDrop + 5 rejectsUnsupportedType param + 6 acceptsSupportedTypes param + 1 acceptsUppercaseExtensions + 3 handleDropStateTransitions param); was 1 in Story 5-1
- `make demo-lint` — exit 0 on clean tree; both quoted and unquoted team-ID forms trip the guardrail (recipe inversion verified, reverted)
- `make pre-commit` — exit 0 (aggregate: `fmt` + `demo-fmt` + `lint` + `demo-lint`)
- `make demo-build-sandboxed DEVELOPMENT_TEAM=S85RR68YT7` — `BUILD SUCCEEDED`; entitlements verified via `codesign -d --entitlements -` (app-sandbox + files.user-selected.read-only + get-task-allow all true)
- `make benchmark` — OA300 default-config Acc1=58/82 (70.7%) + Acc2=74/82 (90.2%); all 12 tests pass including the `≥ 57/82` floor + `== 57/82 (durationHint=false)` exact-baseline assertions (AC #11 sanity check; **library DSP code byte-untouched**)
- `make benchmark-giantsteps` — strict Acc1=537/661 (81.2%) + Acc2=546/661 (82.6%); MIREX-tolerance Acc1=556/661 (84.1%) + Acc2=562/661 (85.0%); all 6 tests pass (AC #11 baseline matches verbatim)

**Built Info.plist verification (`plutil -p` on the sandboxed Debug build's Info.plist):**

`CFBundleDocumentTypes` is an array of 6 dicts. First entry: `CFBundleTypeRole = Viewer` + `LSHandlerRank = Default` + `LSItemContentTypes = (public.wav)`. Entries 2-6: `LSHandlerRank = Alternate`, `LSItemContentTypes = public.aiff / public.mp3 / org.xiph.flac / public.mpeg-4-audio / com.apple.coreaudio-format` respectively. Matches AC #7 verbatim.

**Build-time discoveries (analog of Story 5-1's discoveries section):**

1. **`INFOPLIST_KEY_CFBundleDocumentTypes` build-setting form does NOT natively support array-of-dicts** — `INFOPLIST_KEY_*` accepts only simple top-level values (strings, bools, numbers). DD #8 R2 fallback path taken immediately, before the 30-minute clock started. Hand-written `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` with `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` + `GENERATE_INFOPLIST_FILE = NO`. Adds one tracked file; flagged in Project Structure Notes.
2. **`PBXFileSystemSynchronizedRootGroup` auto-includes `Info.plist` in the Resources copy phase** — produces a build warning "Copy Bundle Resources build phase contains this target's Info.plist file". Resolved by adding a `PBXFileSystemSynchronizedBuildFileExceptionSet` (UUID `4F5B7E1A9C8D406DB2C39A48`) with `membershipExceptions = (Info.plist,)` and `target = <app target UUID>`; the root group's `exceptions = (...)` array references this new set. Pattern is documented in Xcode 16+ pbxproj reference.
3. **`DropError` requires `Error` conformance for use as `Result<URL, DropError>` Failure type** — spec wording said `Equatable` only; compiler rejected the function signature. Fixed inline by adding `Error` to the conformance list. The enum doesn't need a localized description (no propagation across module boundaries), so `Error` alone is sufficient.
4. **The Story-5-1 inherited switch arm `case .failure(is CancellationError): return` already short-circuited CancellationError BEFORE the new switch reaches `case .failure(let error)`**; combining the two left a redundant unreachable `case .failure:` at the end. Resolved by hoisting CancellationError handling into an explicit `if case .failure(let error) = result, error is CancellationError { ... return }` block before the switch, then removing the unreachable arm.
5. **`@discardableResult` on `handleDrop(_:) -> Bool`** — the SwiftUI `.dropDestination(action:)` closure returns Bool, so callers from inside SwiftUI must consume the return value. But the demo test target may want to call `viewModel.handleDrop([])` purely for side-effect verification (errorMessage population). `@discardableResult` makes both call sites legal without an unused-result warning.
6. **Demo test count grew from 1 to 18** — `wrapping` + 3 single-shot validator tests (`rejectsEmptyDrop`, `rejectsMultiFileDrop`, `acceptsUppercaseExtensions`) + 2 parameterized validator tests (5 + 6 cases for `rejectsUnsupportedType` + `acceptsSupportedTypes`) + 1 paired-args parameterized test (3 cases for `handleDropStateTransitions`). All MainActor-isolated for suite consistency.

**Deferred-work updates** (per A2 — `deferred-work.md` is canonical):

- **W1 PARTIALLY-CLOSED** — per-task UUID discriminator implemented per DD #5; the original `guard !Task.isCancelled` early return removed (Codex C1 fix). Remaining open edges: SwiftUI scene-phase / window-close / sheet-dismissal flows that propagate parent-task cancellation. Re-open trigger: Story 5-3+ surfaces a non-supersession cancel path that leaves `isAnalyzing` lingering true.
- **W3 CLOSED** — `CFBundleDocumentTypes` declared via partial Info.plist (R2 fallback); `.onOpenURL` handler wired at ContentView root (DD #15). Both halves required for Dock + Open-With path.
- **W16 CLOSED** — `make demo-lint` + `make demo-fmt` + `make pre-commit` Makefile targets added with recipe-inversion verified for both quoted + unquoted team-ID forms.
- **W17 CLOSED** — "Cancelling previous analysis…" copy renders via `viewModel.isCancelling` derived from `pendingCancellations: Set<UUID>`.

**Manual smoke test status (Task 8):**

Auto-mode environment cannot perform GUI drag-and-drop interactions (Task 8.2-8.5, 8.7-8.8) or interactive Escape-key tests (Task 8.6 — downgraded to optional per DD #7). The dev agent verified what's tractable programmatically:

- Task 8.1 — sandboxed build launches without crashing (PID observed via `pgrep`, exit clean on `kill`); entitlements attached per `codesign -d --entitlements -` (app-sandbox + files.user-selected.read-only).
- LaunchServices re-registration ran successfully (`lsregister -r -f <app>` exit 0; note: the `-kill` flag was removed by Apple in a recent macOS revision — non-fatal).
- All drop-handler behavior (validator + handleDrop state transitions) is covered by the expanded smoke test suite at the data-validation layer — `validateDropPayload`, `handleDrop`, and `handleOpenURL` are pure functions of their inputs and their state-mutation effects are unit-tested. The remaining manual checks are essentially "does SwiftUI's `.dropDestination`/`.onOpenURL` actually deliver URLs as documented" — which is Apple's contract and cannot meaningfully be regression-protected from Swift Testing.

**Tasks 8.2-8.5, 8.6 (optional), 8.7-8.8, 8.9, 9.4-9.5 LEFT UNCHECKED** — these require user action (RT to verify GUI drops at code-review time and run the separate-LLM `/bmad-code-review`; final commit gated on RT's 1Password GPG signer per Story 5-1 close-out precedent).

**A3 wall-clock baseline (per AC #14):**

`make test` warm-cache 1.74s real (Story 5-1 baseline: warm 2.01s). Within run-to-run noise floor (~0.3s typical variance for a 431-test suite at this duration); **per-story delta ≈ 0%** — Story 5-2 added zero library tests. The slight headline improvement may be M5 Max thermal state.

### File List

**Modified files (8):**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — added `PBXFileSystemSynchronizedBuildFileExceptionSet` (UUID `4F5B7E1A9C8D406DB2C39A48`) excluding `Info.plist` from Resources copy phase; flipped `GENERATE_INFOPLIST_FILE = YES → NO` and added `INFOPLIST_FILE = BoomBoomBoomKitDemo/Info.plist` on both Debug + Release app-target configs.
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` — extended from 158 → 339 lines. New: `supportedExtensions: Set<String>`, `DropError: Error, Equatable`, `pendingCancellations: Set<UUID>` (observed), `isCancelling: Bool` (computed), `currentTaskID: UUID?` (@ObservationIgnored), `inFlightTasks: [UUID: Task<Void, Never>]` (was `Set<Task<Void, Never>>`), `analyze(url:autoStarted: Bool = false)` (was `analyze(url:)`), security-scoped resource bracketing across the Task.detached boundary, per-task UUID discriminator in the result switch, `validateDropPayload(_:) -> Result<URL, DropError>` static, `handleDrop(_:) -> Bool` (instance, @discardableResult), `handleOpenURL(_:)` (instance). Removed: inherited `guard !Task.isCancelled` early return (Codex C1).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — extended from 17 → 162 lines. New: state-driven render (4 primary states + secondary error banner per DD #16), `DisplayState` private enum, `BPMResultRow` private struct, `.dropDestination(for: URL.self)` with `isTargeted:` callback, 1pt accent-color border overlay on hover, `.contentShape(Rectangle())` modifier per Axiom A2, `.onOpenURL { url in viewModel.handleOpenURL(url) }` wired at ContentView root (DD #15 / Codex C2).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift` — extended from 36 → 138 lines. New tests: `rejectsEmptyDrop`, `rejectsMultiFileDrop`, `rejectsUnsupportedType` (5 cases), `acceptsSupportedTypes` (6 cases), `acceptsUppercaseExtensions`, `handleDropStateTransitions` (3 cases via `zip(...)` per Axiom A5). `wrapping` test augmented with `isCancelling == false` + `pendingCancellations.isEmpty` post-completion assertions.
- `Makefile` — added 3 new targets: `demo-fmt` (`swift format --recursive --in-place Demo/`), `demo-lint` (recursive grep for team-ID shape across `Demo/**/project.pbxproj` covering both quoted + unquoted Xcode-emitted forms), `pre-commit` (aggregate: `fmt` + `demo-fmt` + `lint` + `demo-lint`).
- `_bmad-output/implementation-artifacts/deferred-work.md` — W1 → PARTIALLY-CLOSED, W3 / W16 / W17 → CLOSED inline with cross-references to Story 5-2.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flip `5-2-core-analysis-flow: ready-for-dev → in-progress → review`; `last_updated` paragraph appended.
- `_bmad-output/implementation-artifacts/5-2-core-analysis-flow.md` — this story file; Status `ready-for-dev → review`; Tasks 0-7 + 8.1 + 9.1-9.3 checked off; Dev Agent Record populated.

**New files (1):**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Info.plist` — partial Info.plist with `CFBundleDocumentTypes` 6-entry array (Default for `public.wav`, Alternate for the other 5) + the standard CF*/LSMinimumSystemVersion keys with `$(BUILD_SETTING_NAME)` substitutions. R2 fallback per DD #8.

### Change Log

| Date | Section | Change |
|------|---------|--------|
| 2026-05-19 | Status | `ready-for-dev → review` |
| 2026-05-19 | Tasks/Subtasks | Tasks 0-7 + 8.1 + 9.1-9.3 checked off; Task 8.2-8.8 (GUI smoke), 8.9 (record-outcomes), 9.4 (separate-LLM code review), 9.5 (final commit) left for user action per Story 5-1 close-out precedent |
| 2026-05-19 | Dev Agent Record | Populated Agent Model, Debug Log, Completion Notes, File List sections |

### Review Findings

_Inventory only per Story 5-1 DD #11 A2; canonical resolution ledger is `deferred-work.md`. Run: /bmad-code-review 2026-05-19 — 4-layer parallel review (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex Blind Hunter via MCP). Raw findings: ~36; after dedup + triage: 0 decision-needed (D1 resolved to P5 below), 5 patches, 3 deferred, ~26 dismissed._

**D1 RESOLVED 2026-05-19 → P5.** User chose: don't register the demo app as a file-type handler at all. The demo is intentionally basic, not full-featured. This obsoletes W21 (UTI conformance UX gap — no UTI registration remains) and W23 (CFBundleTypeName polish — no doc types remain). Spec AC #7 needs amendment to record the deviation; Story 5-2 ships with `CFBundleDocumentTypes` removed from Info.plist. `.onOpenURL` is preserved because `open -a /Applications/BoomBoomBoomKitDemo.app file.wav` from terminal still uses it (no LaunchServices registration required for explicit-open paths).

- [x] [Review][Patch] P1 — APPLIED 2026-05-19. `.success(value?)` arm now sets `self.errorMessage = nil` before populating result fields [AnalysisViewModel.swift:232-241]
- [x] [Review][Patch] P2 — APPLIED 2026-05-19. `validateDropPayload` now guards `url.isFileURL` before extension match; non-file URLs route to `.unsupportedType` [AnalysisViewModel.swift:283-305]
- [x] [Review][Patch] P3 — APPLIED 2026-05-19. Empty extension renders as `"(no extension)"` in both `handleDrop` and `handleOpenURL` unsupported-type messages [AnalysisViewModel.swift:316-318, :340-343]
- [x] [Review][Patch] P4 — APPLIED 2026-05-19. Deleted unused `supportedAudioContentTypes`, `cafUTType`, `flacUTType` and `import UniformTypeIdentifiers` (all obsolete after P5) [AnalysisViewModel.swift]
- [x] [Review][Patch] P5 — APPLIED 2026-05-19. `CFBundleDocumentTypes` block removed from Info.plist; demo intentionally does not register as a file-type handler. AC #7 deviates: no document types declared. `.onOpenURL` retained for terminal `open -a` path. Tasks 8.7 (Finder Open With) and 8.8 (Dock-icon drop) become inapplicable [Info.plist]

**Post-patch gating gauntlet (2026-05-19):** `make fmt` clean; `make demo-fmt` clean; `make lint` 1 violation = canonical LUFSAnalyzer:94 TODO baseline; `make demo-lint` exit 0; `make build` 0.12s; `make demo-build` BUILD SUCCEEDED; `make test` 431/431 in 94 suites 1.32s; `make demo-test` 18/18 pass; `make pre-commit` aggregate exits 0 (1 canonical violation).

- [x] [Review][Defer] W20 — NaN/Inf in `bpm` / `confidence` / `elapsedSeconds` renders as `"nan BPM"` / `"nan%"` (no `.isFinite` guard) [ContentView.swift:70-83] — deferred, defensive UI hardening; extends Story 5-1 W5 with Story 5-2 surface area
- [x] [Review][Defer] W22 — `make demo-lint` only scans `--include='project.pbxproj'`, missing `.xcconfig` and `xcshareddata` files where `DEVELOPMENT_TEAM` can also leak [Makefile:73] — deferred, extend in a future story
- [x] [Review][Defer] AC #12 manual GUI smoke tests (8.2-8.8) pending user action — auto-mode cannot drag files into SwiftUI windows; sprint-status records this. Note: 8.7 (Finder Open With) and 8.8 (Dock-icon drop) become inapplicable after P5 ships; only 8.2-8.6 remain meaningful — deferred to user follow-up
