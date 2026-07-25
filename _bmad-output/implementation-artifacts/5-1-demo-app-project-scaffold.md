# Story 5.1: Demo App Project Scaffold

Story ID: 5.1
Story Key: 5-1-demo-app-project-scaffold
Epic: 5 — Developer Experience & Demo (FIRST story; opens the epic)
Status: done

## Story

As a developer evaluating BoomBoomBoomKit,
I want to clone the repo, open `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj` in Xcode, and have it build and launch without touching any other file,
So that I can start evaluating the library without reading source code or wiring up an Xcode project myself.

**Scope clarification (read first).** This story delivers a *scaffold only* — the minimum buildable shell that:

1. Exists at `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj`
2. References the parent `Package.swift` as a **local SPM dependency** (so library edits propagate without re-pinning)
3. Links `BoomBoomBoomKit` AND `BoomBoomBoomKitML` as products (both available; ML is link-only — no model is loaded at app startup)
4. Builds to a single SwiftUI macOS window with placeholder copy ("Drop an audio file" — drop wiring lands in Story 5-2)
5. Includes a `@MainActor @Observable` `AnalysisViewModel` that already wraps `AudioAnalysisService.analyzeBPM(url:options:)` using **only public API** (no `@testable import`, no internal type access), exercised by a single test-only entry point so the wrapping pattern is proven in this story rather than retrofitted later
6. Is buildable from CLI via a new `make demo-build` target

**What this story does NOT deliver** (each is a separate Epic 5 story):

- File drop UI + result display → Story 5-2 (`Core Analysis Flow`)
- Intensity slider, merge-strategy picker, "Copy Config" button → Story 5-3 (`Parameter Controls`)
- Diagnostic trace view + JSON export → Story 5-4 (`Diagnostic Trace Visualization and Export`)
- Public DocC + README quick-start + nil-return docs → Story 5-5 (`Public API Documentation and README`)

The dev agent's discipline: build the scaffold so any of the four follow-up stories can land as additive view code without revisiting project structure, build settings, or the view-model wiring contract.

## Key Design Decisions

The DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #5, #6, #11 are the most consequential** — they lock the Xcode project format, the local SPM dependency mechanic, the public-API-only wrapping contract, the build-system gating model, and the Epic 5 hygiene precedents (A2 + A3 from Epic 4 retro).

1. **Xcode project format: `objectVersion = 77` with `PBXFileSystemSynchronizedRootGroup` (Xcode 16+; current at Xcode 26).** The AmbientUI demo at `/Users/rterhaar/Dropbox/research/swift/AmbientUI/Demo/AmbientUIDemo/AmbientUIDemo.xcodeproj/project.pbxproj` is the verbatim reference template. The synchronized-root-group format eliminates per-file `PBXBuildFile` and `PBXFileReference` entries — Xcode tracks the contents of `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/` automatically. The dev agent writes Swift files into that directory and they appear in the project without `.pbxproj` edits. This is the property that makes a hand-crafted Xcode project an LLM-tractable artifact instead of a 1000-line manual lift. Other formats (older `objectVersion = 56` with explicit file references, XcodeGen YAML, Tuist Swift DSL) are explicitly rejected — see DD #2 anti-options.

2. **No project-generation tools. Hand-crafted `.pbxproj` only.** The dev agent writes `project.pbxproj` as plain text following the AmbientUI template line-by-line. Rejected alternatives: (a) `swift package generate-xcodeproj` was deprecated in Xcode 11+ and produces a different shape; (b) XcodeGen / Tuist add a third-party dev dependency that's anti-NFR12 (the library promises zero external deps; adding one *for the demo* contaminates the consumer story); (c) committing a raw Xcode-generated file from a developer's manual open-and-save risks `DEVELOPMENT_TEAM = S85RR68YT7` (RT's team ID) leaking onto `main`. Hand-crafted is the only path that's reproducible by the dev agent AND clean for public consumers.

3. **Local SPM dependency via `XCLocalSwiftPackageReference relativePath = ../../;`.** Matches the AmbientUI precedent verbatim (their relativePath is `../../../AmbientUI` because their package is one extra level up; ours is `../../` because `Package.swift` sits at the repo root). The path is interpreted relative to the `.xcodeproj` location, which is `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj`. Two levels up reaches the repo root. Each consumed library product also gets one `XCSwiftPackageProductDependency` entry — Story 5-1 declares TWO: `BoomBoomBoomKit` and `BoomBoomBoomKitML`. **`BoomBoomBoomKitTestSupport` is NOT linked** — it ships test fixtures and would be misleading in a consumer-facing demo (AC #3 zero-`@testable`-import discipline cousin).

4. **Why both `BoomBoomBoomKit` AND `BoomBoomBoomKitML` link in Story 5-1, despite the scaffold not loading a model.** Linking the ML target proves the project structure works for the ML-augmented flow that Stories 5-3 / 5-4 may surface (e.g., an ML toggle showing degradation reasons), and proves there's no SPM-resolution drift between `Package.swift` (which exports `.library(name: "BoomBoomBoomKitML")`) and the demo's product list. Adding the link later would risk re-opening the `.pbxproj` for a one-line edit — riskier than getting it right now. The ML target's `BNNSTechnique.bundledReferenceURL` is `nil` post-Story-4-6 Branch C; the demo can link the framework without crashing at startup (no eager model load happens unless consumer code instantiates `BNNSTechnique(modelURL:)` — see `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:105,262`). Story 5-1 imports neither product in app source; it just declares them as `packageProductDependencies` so the link succeeds. Consumer-visible behavior: `import BoomBoomBoomKitML` compiles inside the demo if a future story needs it, without re-touching the project file.

5. **`AnalysisViewModel` is `@MainActor @Observable` and exposes a public-API-only `analyze(url:)` entry point.** The view model is required for AC #5; it must already be wired in Story 5-1 even though no UI yet calls it. Architecture per `axiom-swiftui/skills/architecture.md` Part 1 (Apple Native Patterns): `@Observable` is the iOS 26+ pattern (replaces `ObservableObject`); the model is `@MainActor` because SwiftUI view bodies render on MainActor and the view-model owns observed state that views read synchronously (see `axiom-swiftui/skills/architecture.md:305`: "SwiftUI's `@Observable` and `ObservableObject` types must be `@MainActor`"). The wrapping contract:

   ```swift
   @MainActor
   @Observable
   final class AnalysisViewModel {
     // CAF UTI helper — Apple's public UTType catalog has no .caf constant
     // (verified 2026-05-18); named helper localizes the unavoidable
     // force-unwrap. Per DD #16-B/C.
     private static let cafUTType = UTType("com.apple.coreaudio-format")!
     // PP3 amendment 2026-05-19: TWO named helpers required, not one;
     // Apple's UTType catalog has no `.flac` constant (verified at build
     // time). DD #16 CAF named-helper pattern applied symmetrically.
     private static let flacUTType = UTType("org.xiph.flac")!

     // Whitelist matching PCMBufferReader's supported formats verbatim per
     // DD #16-B. NOT [.audio] parent — would accept OGG. Story 5-2's drop
     // handler reads this; Story 5-1 declares but does not yet use it.
     static let supportedAudioContentTypes: [UTType] = [
       .wav, .aiff, .mp3, flacUTType, .mpeg4Audio, cafUTType,
     ]

     // Observed state — populated post-analysis, drives UI in Story 5-2+.
     var fileName: String?                              // DD #16-D: display only
     var detectedBPM: Double?
     var confidence: Double?
     var effectiveIntensity: AnalysisIntensity?
     var elapsedSeconds: Double?
     var errorMessage: String?
     var isAnalyzing: Bool = false

     // Operational state — NOT for display, NOT for trace JSON export.
     // Story 5-3 reads this to re-run analysis on the same file when
     // intensity/merge-strategy changes. Story 5-4 MUST NOT export it
     // (sandbox-leaky / non-portable per DD #16-D + Codex 2026-05-18).
     private(set) var selectedFileURL: URL?

     // Latest-selection-wins cancellation per DD #16-E. Each analyze(url:)
     // call cancels the previous task before launching its own. Story 5-1
     // wires the mechanism even though no UI invokes a second analyze yet.
     private var analysisTask: Task<Void, Never>?

     // Single Options bag — Story 5-3 mutates this from sliders/pickers.
     // Default is the library default; Story 5-1 does not surface the field.
     var options: AudioAnalysisService.Options = .init()

     // Entry point — invoked by Story 5-2's drop handler.
     // Public API only: AudioAnalysisService.analyzeBPM is `static func`,
     // returns an Optional<AudioAnalysisResult>, can throw PCMBufferReaderError
     // or CancellationError.
     func analyze(url: URL) { ... }   // signature is sync — see Task 5.2
   }
   ```

   The analyze body off-loads to a background `Task.detached` so the file I/O + DSP pipeline does not block MainActor, then re-enters MainActor to mutate the observed properties. Pattern source: `axiom-swiftui/skills/architecture.md` State-as-Bridge + `axiom-concurrency` rules for detached work returning to MainActor.

   **Public-API-only verification (locked in AC #3).** The agent runs `rg '@testable import (BPMAnalyzer|BoomBoomBoomKit\b|BoomBoomBoomKitML|BoomBoomBoomKitTestSupport)' Demo/` after writing the source files; the recipe MUST return zero matches. (`@testable import BoomBoomBoomKitDemo` from the demo's own test target IS permitted — the no-`@testable` discipline applies to library targets only, not demo-target-internal tests. PP2 amendment 2026-05-19.) Additionally `rg -l 'BPMAnalyzer|LUFSAnalyzer|MelFilterbank|FileMetadataReader|MetadataCorroborator|EnsembleCombiner|\bBPMResult\b|\bLUFSResult\b' Demo/` — these are internal types; if the demo references any of them, the AC fails. Public types the view model is allowed to touch are the eight listed in CLAUDE.md Architecture → "Access control boundaries (post-Epic-4)" subsection plus the eight Epic 4 additions (`MLEvaluation`, `EnsembleDecision`, `MLDiagnosticSnapshot`, `MLFeatureFrames`, `MLDiagnosticTechnique`, `BNNSTechnique`, `MLTechniqueError`, `EnsemblePolicy`).

6. **`make demo-build` Makefile target — develop-only, fail-loud, no signing.** New target wraps `xcodebuild -project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj -scheme BoomBoomBoomKitDemo -destination 'platform=macOS' -configuration Debug CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build`. The `CODE_SIGNING_*` overrides bypass the developer-team signing requirement so the target runs in any clone without a configured signing identity (RT's `S85RR68YT7` team-ID must NEVER appear in `Demo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — see DD #7). The target lives alongside `make ml-pipeline`, `make perf-benchmark`, etc. in the develop-only Makefile (Makefile ships to main, but consumers should not run `make demo-build` — they open the project in Xcode and hit ⌘B). The Makefile target's job is gating in CI / dev workflows, not consumer onboarding.

7. **`DEVELOPMENT_TEAM` left empty; `CODE_SIGN_STYLE = Automatic`.** AmbientUI's template ships `DEVELOPMENT_TEAM = S85RR68YT7`. Public BoomBoomBoomKit demo MUST NOT — consumers cloning from `main` should NOT inherit RT's team ID. The dev agent writes `DEVELOPMENT_TEAM = "";` in both Debug + Release build configs; Xcode falls back to "no team selected" on first open, which the developer fills in via Xcode's signing UI. CLI builds (`make demo-build`) bypass entirely via DD #6's `CODE_SIGNING_ALLOWED=NO`. Open consumer question: does Xcode 26 require a team to *open* the project (vs. to run)? Answer per AmbientUI testing: no — projects open fine without a team; they only fail to *run* on hardware. This is acceptable for the demo (DJ tools, the primary consumers, run on the developer's own Mac with their own team).

8. **App sandbox + entitlements: `com.apple.security.app-sandbox = YES` + `com.apple.security.files.user-selected.read-only = YES`.** Apple's macOS distribution policy requires sandboxing for App-Store-shipped apps; even a developer-tool demo benefits from it because it forces the public-API surface to satisfy the same constraints a downstream consumer (Hilbert, MetaMan) faces. The user-selected-read-only entitlement is the minimum required for Story 5-2's file-open / file-drop flow; declaring it in Story 5-1 means Story 5-2 doesn't need to re-touch the entitlements file. Hardened runtime enabled (`ENABLE_HARDENED_RUNTIME = YES`) per AmbientUI precedent. **No other entitlements.** No microphone, no file-access-beyond-user-selection, no network. The demo reads files the user explicitly drops or opens; everything else is denied by the sandbox.

9. **MACOSX_DEPLOYMENT_TARGET = 15.0; SWIFT_VERSION = 6.0; macOS 15+ language mode.** Library's `Package.swift` declares `.macOS(.v15)`; the demo must match (not exceed). Swift 6 language mode aligns with the library's strict-concurrency posture; SwiftUI `@Observable` and `@MainActor` annotations require it. AmbientUI's demo uses `SWIFT_VERSION = 5.0` — that's a deliberate-but-different-project choice; our demo aligns with our library, not theirs. The dev agent verifies the demo compiles under Swift 6 strict mode (no `@unchecked Sendable`, no `nonisolated(unsafe)` — both are project-level escape hatches reserved for the three documented contexts in `Sources/`, none of which apply to demo code).

10. **`.gitignore` updates: `Demo/**/build/` + `Demo/**/*.xcuserstate`; `Demo/**/xcuserdata/` already covered by `xcuserdata/` global rule.** Pre-existing `.gitignore` covers `xcuserdata/`, `*.xcodeproj/` (wait — this is wrong; this would IGNORE the demo's xcodeproj). Re-check: the existing `.gitignore` line is `*.xcodeproj/` at line 6. **This rule must be NARROWED before the demo project is added**, otherwise `git add Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj` silently no-ops. The dev agent's first commit of this story removes the bare `*.xcodeproj/` line and replaces with `*.xcodeproj/xcuserdata/` (only ignore the per-user state, not the whole project). This is a precondition. The architecture.md spec at line 488 already explicitly lists `Demo/**/build/` and `Demo/**/*.xcuserstate` as the additions; the silently-broken `.xcodeproj/` rule is a Task 0 cleanup that the spec author noticed during pre-flight inspection.

11. **A2 + A3 from Epic 4 retrospective — Story 5-1 is the trigger story for both.** Per `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md`:

    - **A2: Story-file `[ ]` checkboxes are deprecated for review-finding tracking.** From Epic 5 forward, story specs may LIST review findings (in a Review Findings section, like Story 4-7's does), but the canonical resolution ledger is `deferred-work.md` only. Close-out commits MUST add a cross-reference entry in `deferred-work.md` for every applied patch AND every deferred item. **Story 5-1 close-out applies this rule.** Tasks/subtasks in this spec still use `[ ]` checkboxes — that's task tracking, not review-finding tracking, and remains the canonical mechanic.

    - **A3: `make test` wall-clock budget tracked across the epic.** The dev agent records the `make test` wall-clock baseline at Epic 5 start (i.e., at Story 5-1) in this story's Completion Notes, and at Epic 5 close-out the retrospective compares. Per-story increments are flagged if any story adds > 10% to the total. Story 5-1 adds zero `BoomBoomBoomKit` source changes and zero tests to the library's test target (the view-model wrapping is proven via a Demo-target test file, not a library test file — see DD #12), so its expected delta is 0. Recording the baseline gives subsequent Epic 5 stories a reference.

12. **The view-model wrapping is proven inside the demo target via a single `AnalysisViewModelSmokeTest` file**, NOT inside the library's test target. The library tests (`Sources/BoomBoomBoomKitTestSupport/` + `Tests/BoomBoomBoomKitTests/`) are the library's contract; the demo's view-model is a consumer of the library and gets demo-target tests. AmbientUI's precedent: their `AmbientUIDemoTests/` target contains demo-only tests (`DemoThemeSupportTests`). Our `BoomBoomBoomKitDemoTests/` target contains one Swift Testing test that exercises `AnalysisViewModel.analyze(url:)` against a bundled fixture (smallest WAV from `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` — accessed via the demo target's own copy or via a developer's manual fixture path; see DD #13). The test target is wired in the same `.pbxproj` (third native target after the app + UI tests) per AmbientUI's three-target layout, but UI tests are NOT scaffolded in Story 5-1 (deferred to Story 5-2 when there's actually UI to test). **Net: app target + unit test target only.**

13. **Demo-target test fixture strategy: link `BoomBoomBoomKitTestSupport` IN THE TEST TARGET ONLY.** The demo's *app* target links `BoomBoomBoomKit` + `BoomBoomBoomKitML` (per DD #4) and explicitly NOT `BoomBoomBoomKitTestSupport`. The demo's *test* target links `BoomBoomBoomKitTestSupport` so the smoke test can call `AudioFixtures.url(for: "120bpm", extension: "wav")` instead of re-bundling a WAV file inside the demo. This keeps the app binary clean of test fixtures (consumer-facing demo doesn't ship a test-only audio corpus) AND lets the smoke test borrow the library's existing fixture pipeline. AmbientUI doesn't do this because it has no analogous shared-fixtures target; our pattern is project-specific but architecturally clean.

14. **No `BoomBoomBoomKitDemoUITests` target in Story 5-1.** AmbientUI's `.pbxproj` declares three native targets (app + unit tests + UI tests); our scaffold declares two (app + unit tests). Story 5-2 may add a UI test target once there's UI to test (drop interaction, BPM display rendering). For Story 5-1, a UI test target would have no body and would slow `make demo-build` for no value. The dev agent omits it; if Story 5-2 wants it, that's that story's `.pbxproj` edit. **HALT-(c) fires if the dev agent over-builds the scaffold by including UI tests.**

15. **`Assets.xcassets` minimal: `AccentColor.colorset` + `AppIcon.appiconset` (placeholder, no icon image yet).** AmbientUI ships an `Assets.xcassets` with both. Our demo needs at least an empty `AppIcon.appiconset/Contents.json` so Xcode doesn't warn-on-build. Placeholder is acceptable — Story 5-5 (Public API Documentation and README) can decide whether to commission an app icon. Story 5-1 ships the assets bundle with no icon image; the AppIcon entry exists but is empty.

16. **Audio file exposure schema — VERY-simple positioning locked in Story 5-1 (ADR-5-1-A through E, five decisions all toward minimalism; reviewed by Codex consultation 2026-05-18 thread `019e39df-1225-77f0-ba38-186b0322068a` — A/B/C agreed, D modified to split exposed-vs-operational state, E added per Codex cross-cutting concern).**

    - **(A) App target ships zero audio files.** No `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Resources/` audio directory exists. The smoke test target borrows from `BoomBoomBoomKitTestSupport.AudioFixtures` per DD #13. Story 5-2 onwards: user supplies their own audio via drop/open. No "Try Sample" button, no bundled corpus. Journey 4 (Maren — power user with her own corpus per `_bmad-output/planning-artifacts/prd.md:164-182`) is the canonical consumer; bundled samples would be unused weight. Rejected alternatives: ship 2-3 sample WAVs in app bundle (+200-500KB binary, requires fixture-choice decision now); ship `Demo/.../Samples/` outside the bundle (git-tracked but unused source-of-truth ambiguity); synthesize a runtime click track for in-app demo (Codex: belongs in tests, not the app bundle).

    - **(B) Explicit `UTType` whitelist matches `PCMBufferReader` exactly: WAV, AIFF, MP3, FLAC, M4A, CAF.** Six entries. NOT `[.audio]` parent — accepting `.audio` would surface OGG (and any future audio UTI Apple ships) and produce confusing "could not read" errors downstream (OGG unsupported per project-context.md:163 / CLAUDE.md "OGG/Vorbis is NOT supported"). The whitelist is the contract Story 5-2's drop handler enforces; files outside it are rejected at the drop boundary, NOT at the analyzer boundary. Codex: "Keep the whitelist aligned to actual decoder support, not to Apple's taxonomy. That is the least surprising user experience."

    - **(C) Whitelist lives on `AnalysisViewModel` as `static let supportedAudioContentTypes: [UTType]`.** Demo-local. NOT promoted to a library `PCMBufferReader.supportedContentTypes` public surface — promotion would (a) add `UniformTypeIdentifiers` to the library's currently-zero-external-deps surface (a system framework so technically not an SPM dep, but it grows the library's framework import surface), (b) require a named story spec per Public API Discipline (project-context.md "internal→public promotion requires a named story spec"). Codex: "Promoting this into the library would add public API for a UI concern before there is a named story authorizing it." If demo-library drift becomes a real problem, a future story handles the promotion via the documented mechanic.

    - **(D) Two-property split — `fileName: String?` (exposed/displayed) + `selectedFileURL: URL?` (operational, private setter).** The view model exposes `fileName` for UI display ("Analyzed: track.wav") via `url.lastPathComponent` — zero extra I/O. It ALSO retains `private(set) var selectedFileURL: URL?` because:
       - **Story 5-3 needs the URL for re-run-on-settings-change** — when the user changes an intensity slider or merge-strategy picker, the demo re-runs analysis on the same file. Without retained URL state, the demo would force the user to re-drop the same file every parameter tweak — bad UX.
       - **Story 5-4 must NOT export the URL into trace JSON.** Codex: "Serializing `absoluteString` into trace JSON is misleading, non-portable, and leaks local filesystem shape in a sandboxed app." The trace JSON exporter (Story 5-4) reads `fileName` only, never `selectedFileURL`. This is a Story-5-4 forbidden pattern that Story 5-1 declares now to prevent the retrofit.
       - **`@testable import BoomBoomBoomKitDemo` deliberately widens `private(set)` access for the demo's own test target** (PP6 amendment 2026-05-19). Post-D2 patch, `AnalysisViewModel` is default-internal; the smoke test uses `@testable import` to read `viewModel.selectedFileURL`. `private(set)`'s read-only-external semantics still hold for any first-party consumer in production builds (none exist; the demo module has no library consumer); the `@testable` route opens the setter to demo-internal tests only. Story 5-4's trace exporter is in the app target (not the test target) and CANNOT use `@testable import`, so the "must NOT export the URL" forbid still binds at the production-code boundary.

       Other rich metadata (duration, sample rate, channels, format) remains OUT of scope — the library's `AudioAnalysisResult` doesn't surface it, and adding a second `AVAudioFile` read for cosmetic display would double file I/O.

    - **(E) Latest-selection-wins cancellation pre-positioned in Story 5-1 — cancel-ALL-prior pattern.** Per Codex: "Add 'latest selection wins' task cancellation early. Dragging file B while A is analyzing is the first demo race users will hit." The view model holds `private var inFlightTasks: Set<Task<Void, Never>>` — each call to `analyze(url:)` cancels EVERY in-flight prior task before launching a new one (D5 patch from 2026-05-19 code review pass 2: a single-handle `analysisTask?.cancel()` could only reach the most recent task, leaving N-2 earlier detached tasks each holding their OWN `cancelFlag` with no handle to flip them; the Set pattern cancels them all). Cancellation propagates to `AudioAnalysisService.analyzeBPM` via an override-`opts.isCancelled` closure backed by `Atomic<Bool>` (NOT the library's default `{ Task.isCancelled }` closure — the default cannot work because `Task.detached` does not inherit cancellation from its enclosing task; D1 patch from 2026-05-18 added the override). The outer `Task`'s `withTaskCancellationHandler.onCancel` flips the atomic (`.releasing` store); the detached child polls via `opts.isCancelled` (`.acquiring` load) at window boundaries per ADR-1. Story 5-2 inherits the race protection for free, including the cancel-all-prior cascade.

    **CAF UTType expression — named helper, not inline force-unwrap.** Per Codex: Apple's current `UTType` public catalog does NOT include `.caf` / `.coreAudioFormat` (verified via `axiom-apple-docs` if needed). Use a named helper at the type level:

    ```swift
    private static let cafUTType = UTType("com.apple.coreaudio-format")!
    // — OR equivalently —
    private static let cafUTType = UTType(filenameExtension: "caf", conformingTo: .audio)!
    ```

    The helper localizes the unavoidable force-unwrap and makes the exceptional case legible (one named call site instead of an inline `!` inside a six-element array literal).

    **Sandbox + drop interaction caveat for Story 5-2 (informational, not a Story 5-1 task).** Per Codex referencing Apple's "Accessing Files from the macOS App Sandbox" doc: the `com.apple.security.files.user-selected.read-only` entitlement (DD #8) is *necessary but not sufficient* for `.dropDestination(for: URL.self)`. Apple's documentation auto-starts security-scoped access for **open/save panels and items dragged to the app's Dock icon**, but does NOT make the same promise for arbitrary **window drops**. Story 5-2 MUST include a sandboxed acceptance test (`make demo-build-sandboxed` — the signing-enabled target added by D4 patch 2026-05-18; PP5 amendment 2026-05-19 corrected this reference from `make demo-build` which omits signing and therefore does NOT enforce sandbox attachment) plus a manual drop test in Xcode 26 with `xcrun simctl` or an actual file drag, verifying the URL is readable; if `startAccessingSecurityScopedResource()` is needed, the drop handler MUST balance with `stopAccessingSecurityScopedResource()` in `defer`. **Story 5-1 declares this caveat so Story 5-2's spec author cannot ship without addressing it.** Do NOT add `NSDocument` bookmark persistence yet — defer until a future story justifies cross-launch file reopen.

    **Explicitly OUT of scope (declined in Story 5-1, NOT deferred):**
    - Recent-files menu / `NSDocument` tracking
    - Security-scoped bookmark persistence across launches
    - Multi-file batch UI / drop-multiple
    - Bundled sample audio pack
    - File-metadata display beyond `fileName` (duration, format, sample rate, channels)
    - URL export in Story 5-4's trace JSON (DD #16-D forbids — referenced from Story 5-4's spec when it's written)

    These are NOT "deferred to a future story" — they are positively NOT coming, in service of the "VERY simple" demo posture. If a Hilbert / MetaMan consumer evaluation surfaces a specific need, a focused follow-up story re-opens.

## Acceptance Criteria

1. **Xcode project exists at the canonical path with local SPM dep + both library product links (FR34).**

   **Given** the file tree
   **When** scanned post-commit
   **Then** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` exists with `objectVersion = 77`
   **And** the `XCLocalSwiftPackageReference` section declares exactly one entry with `relativePath = ../../;` and a UUID-stable identifier
   **And** the `XCSwiftPackageProductDependency` section declares exactly two entries: `productName = BoomBoomBoomKit;` and `productName = BoomBoomBoomKitML;`
   **And** the app target's `packageProductDependencies` list references both
   **And** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/contents.xcworkspacedata` exists with the self-referencing `<FileRef location="self:">` body
   **And** the app target's `MACOSX_DEPLOYMENT_TARGET = 15.0;` (matching `Package.swift`'s `.macOS(.v15)`)
   **And** `SWIFT_VERSION = 6.0;`
   **And** `PRODUCT_BUNDLE_IDENTIFIER = com.robbyt.BoomBoomBoomKitDemo;`
   **And** `DEVELOPMENT_TEAM = "";` (empty string — see DD #7)
   **And** `ENABLE_APP_SANDBOX = YES;` + `ENABLE_HARDENED_RUNTIME = YES;`

2. **Build succeeds via `make demo-build` AND via Xcode UI on macOS 15+ (FR34, NFR15).**

   **Given** `make demo-build`
   **When** run from a clean checkout (`make clean` first)
   **Then** the command exits 0, producing `BoomBoomBoomKitDemo.app` in `DerivedData`
   **And** stderr is free of warnings beyond the canonical pre-existing `LUFSAnalyzer.swift:94` TODO baseline

   **Given** a developer opens `BoomBoomBoomKitDemo.xcodeproj` in Xcode 26
   **When** they hit ⌘B
   **Then** the build succeeds on macOS 15+ (and on Xcode 26 / macOS 26 host) without errors
   **And** the build runs under Swift 6 strict-concurrency language mode (`SWIFT_VERSION = 6.0;`) with no Sendable warnings

   **Given** `xcodebuild -project ... -list`
   **When** run from a fresh checkout
   **Then** the Schemes section lists `BoomBoomBoomKitDemo` (and the three package-target schemes auto-resolved by SPM: `BoomBoomBoomKit`, `BoomBoomBoomKitML`, `BoomBoomBoomKitTestSupport`); `BoomBoomBoomKitDemoTests` does NOT need to appear here — `xcodebuild test -scheme BoomBoomBoomKitDemoTests` auto-resolves to the target's auto-generated user scheme at invocation time, which is functionally adequate. (Amended 2026-05-18 via code review D3 — literal-MUST relaxation. PP4 amendment 2026-05-19: corrected count from "four" to "three" package-target schemes. If a future CI lane breaks on scheme discovery, the fix is to commit `Demo/.../xcshareddata/xcschemes/BoomBoomBoomKitDemoTests.xcscheme`.)

3. **Zero internal LIBRARY-type references; `@testable` is permitted on demo-internal test target only (FR34 architectural integrity, DD #5; amended 2026-05-18 via code review D2).**

   **Given** the demo source tree at `Demo/BoomBoomBoomKitDemo/`
   **When** scanned by `rg '@testable import (BPMAnalyzer|BoomBoomBoomKit\b|BoomBoomBoomKitML|BoomBoomBoomKitTestSupport)' Demo/`
   **Then** zero matches (the no-`@testable` discipline applies to LIBRARY targets only — `BoomBoomBoomKit`, `BoomBoomBoomKitML`, `BoomBoomBoomKitTestSupport`)

   **Given** `rg '@testable import BoomBoomBoomKitDemo' Demo/BoomBoomBoomKitDemoTests/`
   **When** run
   **Then** MAY match — `@testable import BoomBoomBoomKitDemo` is permitted because `BoomBoomBoomKitDemo` is the demo target's OWN module name (not a library target); using it lets the demo target remain default-internal (no public surface widening to satisfy a sibling test bundle). `ENABLE_TESTABILITY = YES` is set on the app target's Debug config for this to compile

   **Given** `rg -l 'BPMAnalyzer|LUFSAnalyzer|MelFilterbank|FileMetadataReader|MetadataCorroborator|EnsembleCombiner|\bBPMResult\b|\bLUFSResult\b' Demo/`
   **When** run
   **Then** zero matches (zero internal-type references — the eight types listed are the canonical internal-only types per CLAUDE.md "Access control boundaries")

   **Given** the demo's `AnalysisViewModel.swift`
   **When** inspected
   **Then** it imports `BoomBoomBoomKit` (always) and may import `BoomBoomBoomKitML` (optional, Story 5-1 includes the link but does NOT need to import in source); also imports `UniformTypeIdentifiers` for the `UTType` whitelist and `Synchronization` for the cancellation `Atomic<Bool>` (code review D1 patch)
   **And** it does NOT import `BoomBoomBoomKitTestSupport` (test target only)

4. **`.gitignore` correctly carves out `Demo/` artifacts without ignoring the project file itself (DD #10).**

   **Given** the pre-change `.gitignore` containing `*.xcodeproj/` at line 6
   **When** the story-1 cleanup runs
   **Then** that bare `*.xcodeproj/` rule is replaced with `*.xcodeproj/xcuserdata/` so the project bundle commits cleanly
   **And** new entries are added: `Demo/**/build/`, `Demo/**/*.xcuserstate`
   **And** `git check-ignore Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` reports the file is NOT ignored
   **And** `git check-ignore Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/xcuserdata/foo.xcuserstate` reports IGNORED
   **And** `git check-ignore Demo/BoomBoomBoomKitDemo/build/x.o` reports IGNORED

5. **`AnalysisViewModel` is `@MainActor @Observable`, wraps `AudioAnalysisService.analyzeBPM` via public API only, exposes the DD #16 audio-file schema (FR34, DD #5, DD #16).**

   **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift`
   **When** inspected
   **Then** the type is declared `@MainActor @Observable final class AnalysisViewModel`
   **And** it exposes the observed properties listed in DD #5: `fileName`, `detectedBPM`, `confidence`, `effectiveIntensity`, `elapsedSeconds`, `errorMessage`, `isAnalyzing`, `options`
   **And** it exposes `private(set) var selectedFileURL: URL?` per DD #16-D (operational, not displayed, not exported by Story 5-4)
   **And** it holds `private var inFlightTasks: Set<Task<Void, Never>>` per DD #16-E (latest-selection-wins cancellation, cancel-all-prior cascade; PP6 amendment 2026-05-19 updated from the original `analysisTask: Task<Void, Never>?` single-handle pattern)
   **And** it exposes `static let supportedAudioContentTypes: [UTType]` per DD #16-B/C with exactly 6 entries: `.wav`, `.aiff`, `.mp3`, `.mpeg4Audio`, and TWO named force-unwrap helpers — `cafUTType = UTType("com.apple.coreaudio-format")!` and `flacUTType = UTType("org.xiph.flac")!` (PP3 amendment 2026-05-19: spec originally listed `.flac` as a catalog constant; Apple's public `UTType` catalog has no such constant, so the DD #16 CAF named-helper pattern is applied symmetrically — NOT inline force-unwraps inside the array)
   **And** `func analyze(url: URL)` exists with the wrapping body — **NOTE: synchronous signature** (no `async`); the function launches an internal `Task` so the caller doesn't `await`
   **And** the body cancels EVERY task in `inFlightTasks` BEFORE launching the new task (DD #16-E latest-selection-wins cascade fix per PP6 amendment 2026-05-19)
   **And** the body sets `selectedFileURL = url` AND `fileName = url.lastPathComponent` synchronously before any async work
   **And** the body calls `AudioAnalysisService.analyzeBPM(url:options:)` exactly once, off-MainActor via `Task.detached`, and re-enters MainActor before mutating observed state
   **And** the body handles `is CancellationError` by returning WITHOUT overwriting state (a newer `analyze(url:)` call may have superseded — see DD #16-E semantics)
   **And** the body populates `errorMessage` on `PCMBufferReaderError` and other unexpected errors, never crashes
   **And** the body does NOT reference any internal type (verified by AC #3's rg recipe)

6. **`BoomBoomBoomKitDemoTests` target proves the wrapping contract via one smoke test (DD #12, DD #13).**

   **Given** `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift`
   **When** the test target builds and runs (`xcodebuild test -project ... -scheme BoomBoomBoomKitDemoTests`)
   **Then** the single test analyzes a bundled fixture (`bpm-120-click.wav` from `BoomBoomBoomKitTestSupport.AudioFixtures` per DD #13) via `AnalysisViewModel.analyze(url:)`, then awaits completion by polling `viewModel.isAnalyzing == false` (or via a continuation hook — see Task 7.1)
   **And** the test asserts: `detectedBPM != nil` (non-nil result on a known-musical fixture)
   **And** `confidence > 0`
   **And** `fileName == "bpm-120-click.wav"`
   **And** `errorMessage == nil`
   **And** the test does NOT assert a specific BPM value (the library's accuracy suite covers that; this is a wiring proof)

7. **`make demo-build` Makefile target is added; standard library gating still passes (DD #6).**

   **Given** the project's `Makefile`
   **When** inspected
   **Then** a new target `demo-build` exists wrapping the `xcodebuild` invocation per DD #6
   **And** the help comment follows the existing `##` convention so `make help` lists it
   **And** running `make demo-build` from a clean checkout succeeds (`make clean && make demo-build` exits 0)

   **Given** the library gating gauntlet
   **When** run on this branch
   **Then** `make fmt` clean
   **And** `make lint` reports only the canonical pre-existing `LUFSAnalyzer.swift:94` TODO violation
   **And** `make test` passes (library test count unchanged — Story 5-1 adds zero library tests; only demo-target tests are new)
   **And** `make build` (library Debug build) succeeds
   **And** `make build-release` (library Release build) succeeds

8. **Epic 5 hygiene: A2 + A3 from Epic 4 retro recorded (DD #11).**

   **Given** A2 (`deferred-work.md` is the canonical resolution ledger; story-file `[ ]` is task tracking only)
   **When** Story 5-1's close-out commit lands
   **Then** any review findings are recorded in `deferred-work.md` with cross-reference, NOT as `[ ]` checkboxes in this story's Review Findings section
   **And** the story's Completion Notes explicitly cite A2 as the precedent for this format

   **Given** A3 (`make test` wall-clock baseline recorded at Epic 5 start)
   **When** Story 5-1's Completion Notes are written
   **Then** they record the exact `make test` wall-clock seconds AT Epic 5 START, on the dev's reference hardware (M5 Max per Epic 4 retro convention)
   **And** they record the test count integer from `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l`
   **And** Epic 5 retrospective (when run after Story 5-5) compares against this baseline

## Tasks / Subtasks

- [x] **Task 0 — Pre-flight (AC #4 dependency)**
  - [x] 0.1: Confirm `make fmt && make lint && make test` clean on the branch head — record `make test` wall-clock + test count (`rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l`) as Epic 5 baseline for AC #8 A3
  - [x] 0.2: Edit `.gitignore`: replace bare `*.xcodeproj/` (line 6) with `*.xcodeproj/xcuserdata/`. Verify no other repo path was masked by the bare rule (`git status` should not surface a previously-ignored `.xcodeproj/` directory under `tools/` or `_bmad-output/`)
  - [x] 0.3: Append the two new `Demo/**/` rules to `.gitignore`: `Demo/**/build/` and `Demo/**/*.xcuserstate`
  - [x] 0.4: Commit hygiene as a standalone "Story 5-1: gitignore prep for Demo/ tree" commit so it can be reverted independently if step 2's `.pbxproj` write fails

- [x] **Task 1 — Demo directory tree (AC #1, AC #5)**
  - [x] 1.1: `mkdir -p Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo` for app sources
  - [x] 1.2: `mkdir -p Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests` for the smoke-test target
  - [x] 1.3: `mkdir -p Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AccentColor.colorset` + `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.appiconset` (placeholder per DD #15)
  - [x] 1.4: `mkdir -p Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/xcshareddata` (Xcode workspace dir)

- [x] **Task 2 — Hand-write the Xcode project file (AC #1, AC #2) — biggest single artifact**
  - [x] 2.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` using AmbientUI's `project.pbxproj` as the line-by-line template, replacing `AmbientUI*` → `BoomBoomBoomKit*` and the UUIDs to fresh 24-char hex strings (`uuidgen | tr -d '-' | cut -c1-24` × N). The file MUST satisfy:
    - `objectVersion = 77;` and `preferredProjectObjectVersion = 77;`
    - One `XCLocalSwiftPackageReference` with `relativePath = ../../;` (note trailing slash; AmbientUI uses no trailing slash — pick ONE consistent style; the spec selects `../../` without trailing slash to mirror AmbientUI exactly, but `relativePath = ../../;` works equivalently — see DD #3)
    - Two `XCSwiftPackageProductDependency` entries: one for `BoomBoomBoomKit`, one for `BoomBoomBoomKitML`
    - Three native targets: `BoomBoomBoomKitDemo` (app, productType `com.apple.product-type.application`) + `BoomBoomBoomKitDemoTests` (productType `com.apple.product-type.bundle.unit-test`). NO UI tests per DD #14
    - Use `PBXFileSystemSynchronizedRootGroup` for both targets — Xcode tracks file content automatically (DD #1)
    - Build configurations Debug + Release for both `PBXProject` and each `PBXNativeTarget`. Settings per DD #7, #8, #9
    - `DEVELOPMENT_TEAM = "";` in both Debug + Release of both targets (DD #7)
    - `ENABLE_APP_SANDBOX = YES;` + `ENABLE_HARDENED_RUNTIME = YES;` + `CODE_SIGN_ENTITLEMENTS = BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements;` for app target (DD #8)
    - `MACOSX_DEPLOYMENT_TARGET = 15.0;` (DD #9 — NOT 26.x; demo aligns with library's macOS 15 floor)
    - `SWIFT_VERSION = 6.0;` (DD #9 — strict-concurrency language mode)
    - Test target depends on app target via `PBXTargetDependency` + `PBXContainerItemProxy` (AmbientUI pattern verbatim)
    - Test target also has `XCSwiftPackageProductDependency` for `BoomBoomBoomKitTestSupport` (DD #13)
  - [x] 2.2: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/contents.xcworkspacedata` with verbatim AmbientUI body (5-line XML, see Apple Platform Notes section)
  - [x] 2.3: (Optional but recommended) Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/xcshareddata/IDEWorkspaceChecks.plist` with `IDEDidComputeMac32BitWarning = true` to suppress the first-open warning dialog under CLI usage
  - [x] 2.4: Validate by opening the project: `open Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj` in Xcode 26. The project navigator MUST show both products (`BoomBoomBoomKit`, `BoomBoomBoomKitML`) under "Package Dependencies"; the app target's "Frameworks, Libraries, and Embedded Content" MUST list both
  - [x] 2.5: Run `xcodebuild -project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj -list` from the repo root — MUST list schemes `BoomBoomBoomKitDemo` and `BoomBoomBoomKitDemoTests`. If schemes are missing, the dev agent needs to write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/xcshareddata/xcschemes/BoomBoomBoomKitDemo.xcscheme` + matching test-target scheme

- [x] **Task 3 — Entitlements file (AC #1, DD #8)**
  - [x] 3.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements` (plist XML) with two keys: `com.apple.security.app-sandbox = YES` and `com.apple.security.files.user-selected.read-only = YES`. No other entitlements (DD #8)

- [x] **Task 4 — App entry point + ContentView (AC #2, AC #5)**
  - [x] 4.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift`. Body: `@main struct BoomBoomBoomKitDemoApp: App { var body: some Scene { WindowGroup { ContentView() } } }` plus `.defaultSize(width: 640, height: 480)` and `.windowStyle(.titleBar)`. Imports `SwiftUI` only — does NOT import `BoomBoomBoomKit` or `BoomBoomBoomKitML` at the App entry level (those imports live in the view model + content view files, per separation-of-concerns)
  - [x] 4.2: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift`. Minimal body — a centered `VStack` with one `Text("Drop an audio file")` + one secondary `Text("File drop wiring lands in Story 5-2")` (the second line documents-by-display where the next slice goes). The view holds `@State private var viewModel = AnalysisViewModel()` so the wiring exists; the view does NOT yet call `viewModel.analyze(url:)` (that's Story 5-2). Imports `SwiftUI` only. The `AnalysisViewModel` type comes from the same module (the app target itself), so no library import is needed at this layer

- [x] **Task 5 — AnalysisViewModel (AC #5)**
  - [x] 5.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift` per the DD #5 + DD #16 contract. Imports: `import BoomBoomBoomKit` (always — the public API); `import Foundation` (URL); `import Observation` (the `@Observable` macro lives here in Swift 6.0+, though it's re-exported from SwiftUI); `import UniformTypeIdentifiers` (per DD #16-B/C, for the `UTType` whitelist + CAF helper). **Do NOT import `BoomBoomBoomKitML`** — the link exists at the project level (DD #4) but no source needs it yet; importing-without-using would surface a SwiftLint warning
  - [x] 5.2: Implement `analyze(url:)` body using the off-MainActor → MainActor return pattern PLUS latest-selection-wins cancellation per DD #16-E. The function is **synchronous from the caller's perspective** — it kicks off an internal `Task` so the UI doesn't `await`:

    ```swift
    func analyze(url: URL) {
      // DD #16-E: latest selection wins. Cancel any in-flight analysis
      // before launching a new one. Story 5-1 wires this even though no
      // UI yet triggers a second call; Story 5-2 inherits race protection.
      analysisTask?.cancel()

      // DD #16-D: split exposed/operational state.
      selectedFileURL = url                         // operational
      fileName = url.lastPathComponent              // display

      isAnalyzing = true
      errorMessage = nil
      detectedBPM = nil
      confidence = nil
      effectiveIntensity = nil
      elapsedSeconds = nil

      let opts = options                            // Sendable snapshot
      let started = ContinuousClock.now

      analysisTask = Task { [weak self] in
        let result: Result<AudioAnalysisResult?, Error>
        do {
          let value = try await Task.detached {
            try AudioAnalysisService.analyzeBPM(url: url, options: opts)
          }.value
          result = .success(value)
        } catch {
          result = .failure(error)
        }

        // Re-enter MainActor for state mutation. Check cancellation —
        // a newer analyze(url:) call may have superseded us.
        guard !Task.isCancelled, let self else { return }

        let elapsed = ContinuousClock.now - started
        let secs = Double(elapsed.components.seconds)
          + Double(elapsed.components.attoseconds) / 1e18

        switch result {
        case .success(let value?):
          self.detectedBPM = value.bpm
          self.confidence = value.confidence
          self.effectiveIntensity = value.effectiveIntensity
        case .success(nil):
          // nil = silence / too-short / non-musical; documented in Story 5-5
          self.errorMessage = "No BPM detected (silence, too-short audio, or non-musical content)"
        case .failure(is CancellationError):
          // Superseded by a newer analyze(url:); do not overwrite UI
          return
        case .failure(let error as PCMBufferReaderError):
          self.errorMessage = "Could not read audio file: \(error)"
        case .failure(let error):
          self.errorMessage = "Unexpected error: \(error)"
        }
        self.elapsedSeconds = secs
        self.isAnalyzing = false
      }
    }
    ```

    **Sendable correctness — read carefully:** `Task.detached` returns a value across an isolation boundary; the closure must capture only `Sendable` values. `URL` is `Sendable`; `AudioAnalysisService.Options` is `Sendable` (project-context.md line 26 confirms); `AudioAnalysisResult` is `Sendable` (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13`). The pattern above snapshots `options` into a local before `Task.detached` so the closure does not capture `self.options`. The outer `Task { [weak self] in ... }` is MainActor-isolated (inherits from the enclosing `@MainActor` view-model context); the inner `Task.detached` hops off-main for the synchronous DSP work, then the outer task resumes on MainActor to mutate observed state.

    **Cancellation semantics (DD #16-E):** `analysisTask?.cancel()` propagates two ways: (1) cancels the outer MainActor task so it stops before publishing stale state, and (2) the default `AudioAnalysisService.Options.isCancelled = { Task.isCancelled }` (project-context.md `AudioAnalysisService.swift:276`) observes the cancellation between window iterations per ADR-1 and throws `CancellationError` from the detached closure. The pattern handles both — if cancellation arrives mid-analyze, the `case .failure(is CancellationError)` arm fires and the function returns without overwriting state; if cancellation arrives post-analyze, the `Task.isCancelled` guard at MainActor re-entry short-circuits.

    **Test target visibility (for Task 7's smoke test):** the `private(set) var selectedFileURL` is read-only outside the type; that's fine — the smoke test only reads `fileName`, `detectedBPM`, `confidence`, `errorMessage`, `elapsedSeconds`. If a future test needs to assert `selectedFileURL`, the read-only setter still permits it
  - [x] 5.3: Verify the view model compiles under Swift 6 strict concurrency (no `@unchecked Sendable`, no `nonisolated(unsafe)`)

- [x] **Task 6 — Assets bundle (AC #2 build cleanliness)**
  - [x] 6.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/Contents.json` (top-level metadata, one line: `{"info":{"author":"xcode","version":1}}`)
  - [x] 6.2: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AccentColor.colorset/Contents.json` declaring the default system accent color
  - [x] 6.3: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.appiconset/Contents.json` declaring an empty icon set (no `filename` entries — Xcode produces a build warning but not an error; Story 5-5 may commission an icon)

- [x] **Task 7 — Smoke test target (AC #6, DD #12, DD #13)**
  - [x] 7.1: Write `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift`. Imports: `import Testing` + `import BoomBoomBoomKit` + `import BoomBoomBoomKitTestSupport`. Body:

    ```swift
    @Suite("AnalysisViewModel smoke")
    struct AnalysisViewModelSmokeTest {
      @Test("public-API wrapping produces non-nil BPM for known-musical fixture")
      @MainActor
      func wrapping() async throws {
        let url = try #require(
          AudioFixtures.url(for: "bpm-120-click", extension: "wav"),
          "fixture missing — see Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/"
        )
        let viewModel = AnalysisViewModel()
        viewModel.analyze(url: url)   // sync signature per DD #16-E; internal Task

        // Await completion. analyze() launches a Task; we poll via the
        // observed isAnalyzing flag. Cap polling at 30s to fail fast on
        // pipeline regressions; bpm-120-click.wav at default intensity
        // completes in ~1-2s on M5 Max.
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        while viewModel.isAnalyzing && ContinuousClock.now < deadline {
          try await Task.sleep(for: .milliseconds(50))
        }
        try #require(!viewModel.isAnalyzing, "analyze(url:) did not complete within 30s")

        #expect(viewModel.detectedBPM != nil)
        #expect((viewModel.confidence ?? 0) > 0)
        #expect(viewModel.fileName == "bpm-120-click.wav")
        #expect(viewModel.errorMessage == nil)
        #expect((viewModel.elapsedSeconds ?? 0) > 0)
      }
    }
    ```

    **Fixture name verified at spec authoring time:** `ls Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` confirms `bpm-120-click.wav` (and siblings at 85, 140, 170 BPM). Use `bpm-120-click.wav` — synthetic, deterministic. The contract is "smallest known-musical WAV that returns non-nil BPM," not the specific filename; if a future fixture-cleanup story renames, update the test body accordingly.

    **Polling rationale (vs. a continuation hook):** the view model's `analyze(url:)` is synchronous-launches-Task (DD #16-E), so the test cannot `await` it directly. Polling `isAnalyzing` is the simplest assertion-friendly pattern that doesn't require adding a test-only `await` hook to the production type. The 30s ceiling fails fast on regressions; the 50ms tick is cheap. If polling proves flaky in CI, a future story can add a `private` continuation hook accessed via `@testable import` — but Story 5-1's AC #3 forbids `@testable import`, so polling is the only path consistent with the public-API-only discipline
  - [x] 7.2: Confirm test runs via `xcodebuild test -project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj -scheme BoomBoomBoomKitDemoTests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO`

- [x] **Task 8 — `make demo-build` target (AC #7, DD #6)**
  - [x] 8.1: Append the new target to `Makefile`, following the `##` help-comment convention. Body per DD #6 — `xcodebuild ... CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build`
  - [x] 8.2: Optional sibling: `make demo-test` running the test target. Recommended for development cadence but not required by AC. If added, document in help

- [x] **Task 9 — AC #3 verification (DD #5)**
  - [x] 9.1: Run `rg '@testable import (BPMAnalyzer|BoomBoomBoomKit\b|BoomBoomBoomKitML|BoomBoomBoomKitTestSupport)' Demo/` — MUST return zero matches. (PP2 amendment 2026-05-19: narrowed from the bare `rg '@testable import' Demo/` recipe so the demo-target-internal `@testable import BoomBoomBoomKitDemo` is correctly permitted per AC #3.)
  - [x] 9.2: Run `rg -l 'BPMAnalyzer|LUFSAnalyzer|MelFilterbank|FileMetadataReader|MetadataCorroborator|EnsembleCombiner|\bBPMResult\b|\bLUFSResult\b' Demo/` — MUST return zero matches (the demo never references internal types)
  - [x] 9.3: Run `rg '^import ' Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/` — MUST show only `import SwiftUI`, `import Foundation`, `import Observation`, `import Synchronization`, `import UniformTypeIdentifiers`, `import BoomBoomBoomKit` (test target additionally imports `Testing`, `BoomBoomBoomKitTestSupport`, and `@testable import BoomBoomBoomKitDemo`)
  - [x] 9.4: Verify the recipes by inverting them — temporarily add `@testable import BoomBoomBoomKit` to a demo source file and confirm AC #3 fails; revert. Records the recipe as a non-trivial check (the spec author did not test the recipe at write time; the dev agent confirms before claiming AC #3 met)

- [x] **Task 10 — `.gitignore` verification (AC #4)**
  - [x] 10.1: Run `git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj` — MUST report NOT IGNORED (exit 1)
  - [x] 10.2: Run `git check-ignore -v Demo/BoomBoomBoomKitDemo/build/x.o` — MUST report IGNORED via the `Demo/**/build/` rule (exit 0)
  - [x] 10.3: Run `git check-ignore -v Demo/BoomBoomBoomKitDemo/foo.xcuserstate` — MUST report IGNORED via the `Demo/**/*.xcuserstate` rule
  - [x] 10.4: Run `git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/xcuserdata/foo.xcuserstatedata` — MUST report IGNORED via the global `xcuserdata/` rule (pre-existing)

- [x] **Task 11 — Gating gauntlet + Completion Notes (AC #7, AC #8)**
  - [x] 11.1: Run `make fmt && make lint` clean (only the LUFSAnalyzer:94 TODO baseline)
  - [x] 11.2: Run `make build && make build-release` — both succeed
  - [x] 11.3: Run `make test` — library tests pass, record wall-clock + count integer (A3 baseline per DD #11)
  - [x] 11.4: Run `make demo-build` — exits 0
  - [x] 11.5: Run `make benchmark` — Acc1 = 58/82, Acc2 = 74/82 (UNCHANGED — Story 5-1 touches zero library DSP code, this is a regression-protection sanity check)
  - [x] 11.6: Run `make benchmark-giantsteps` — Acc1 = 537/661, Acc2 = 546/661 (UNCHANGED)
  - [x] 11.7: Write Completion Notes recording all integers above, plus the A3 wall-clock baseline. (The Story 4-7 standalone `5-1-diff-scope-proof.txt` artifact requirement was demoted during dev close-out — for additive-only stories that touch zero `Sources/` and zero `Tests/`, the Completion Notes scope claim plus `git diff --stat` reproducibility on demand is sufficient. See Previous Story Intelligence for the convention change.)

- [x] **Task 12 — Status flip + sprint-status update**
  - [x] 12.1: Flip story Status `ready-for-dev` → `in-progress` → `review` (or `done` if code review is run inline) per project workflow
  - [x] 12.2: Update `_bmad-output/implementation-artifacts/sprint-status.yaml`: `5-1-demo-app-project-scaffold` `ready-for-dev` → `in-progress` → ... ; epic-5 `backlog` → `in-progress`. Update `last_updated:` line with a one-paragraph commit summary per Epic 4 retro convention
  - [ ] 12.3: Run `/bmad-code-review` (4-layer parallel review + Codex). Apply patches; defer to `deferred-work.md` per DD #11 A2 (no story-file `[ ]` checkboxes for review findings)
  - [ ] 12.4: Final commit with imperative-mood subject per project-context.md:131 — `Story 5-1: scaffold demo app + AnalysisViewModel public-API wrapper`

## Dev Notes

### Architecture references

- **Architecture spec — demo app boundary:** `_bmad-output/planning-artifacts/architecture.md:161-180` (Demo App Structure decision), `:484-488` (Demo app boundary), `:458-468` (Source tree placement). The reference precedent (`AmbientUI` demo) is at `/Users/rterhaar/Dropbox/research/swift/AmbientUI/Demo/AmbientUIDemo/`.
- **Public API surface the view model wraps:** `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:298,321,548,756` (the four public static funcs: `analyzeBPM(url:)`, `analyzeBPM(url:options:)`, `maximumSupportedIntensity(...)`, `analyzeLUFS(url:)`), plus `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` + `Sources/BoomBoomBoomKit/ProgressUpdate.swift` for the configuration types.
- **Internal types the demo MUST NOT reference (AC #3):** `BPMAnalyzer`, `LUFSAnalyzer`, `MelFilterbank`, `FileMetadataReader`, `MetadataCorroborator`, `EnsembleCombiner`, `BPMResult`, `LUFSResult` (8 types per CLAUDE.md "Access control boundaries (post-Epic-4)").
- **Test fixtures the smoke test borrows:** `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` — accessed via `AudioFixtures.url(for:extension:)`.
- **`.gitignore` cleanup precondition (DD #10):** the bare `*.xcodeproj/` rule at `/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit/.gitignore:6` silently ignores the demo project file if left in place. Narrow before touching `Demo/`.
- **`Package.swift` deployment target:** `.macOS(.v15)` — the demo's `MACOSX_DEPLOYMENT_TARGET` matches (15.0), not the AmbientUI demo's 26.2.

### Project Structure Notes

- Library target `BoomBoomBoomKit` ships to main — UNCHANGED in Story 5-1
- Test support target `BoomBoomBoomKitTestSupport` ships to main — UNCHANGED
- ML sibling `BoomBoomBoomKitML` ships to main — UNCHANGED
- Test target `BoomBoomBoomKitTests` — UNCHANGED (Story 5-1 adds zero library tests; the smoke test is in the demo's test target)
- Benchmark target `BoomBoomBoomKitBenchmarkTests` — UNCHANGED
- **New top-level directory `Demo/` ships on main** per architecture.md:484-488 + CLAUDE.md "Ships to main" table (which already lists `Demo/` implicitly via the "Sources + Tests + Makefile + README" pattern; Story 5-1 makes the directory exist). The `Demo/` tree contains zero develop-only artifacts: no `.claude/`, no `_bmad-output/`, no `scripts/`. It is a clean public-consumer artifact
- **The `Demo/` tree contains ZERO audio files** per DD #16-A. The app target's Resources phase covers only `Assets.xcassets`. The smoke test target accesses fixtures via `BoomBoomBoomKitTestSupport.AudioFixtures` (DD #13) without copying any audio into `Demo/`. Verify with `find Demo -type f \( -name '*.wav' -o -name '*.aiff' -o -name '*.mp3' -o -name '*.flac' -o -name '*.m4a' -o -name '*.caf' \)` — MUST return zero matches before close-out
- **`Makefile` gains one new target (`demo-build`)** ; the rest of the file is unchanged
- **`.gitignore` gains two new rules + one narrowed rule** (Task 0)
- No SPM manifest changes — `Package.swift` is unchanged (the demo references the *file* as a local SPM dep but the manifest doesn't change)
- No new external Swift package dependencies
- `_bmad-output/implementation-artifacts/5-1-*` files (the story spec; no diff-scope proof — pattern demoted, see Previous Story Intelligence) are develop-only

### Risk

- **R1 — Hand-crafted `.pbxproj` UUID collisions or referential errors.** The dev agent generates ~25 UUIDs (one per `PBXBuildFile`, `PBXNativeTarget`, `PBXContainerItemProxy`, `PBXFileReference`, `XCConfigurationList`, etc.). A typo or duplicated UUID causes Xcode to silently fail to open the project or render one target invisible. **Mitigation:** use `uuidgen | tr -d '-' | cut -c1-24` to generate fresh UUIDs, write each into a temporary mapping table, and reference from the table. The synchronized-root-group format (DD #1) sharply reduces the UUID count vs. classic per-file Xcode projects; AmbientUI's project has ~30 UUIDs across 610 lines, vs. ~150 for a pre-Xcode-16 same-shape project. After writing, verify by running `xcodebuild -project Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj -list` (Task 2.5) — exit-0 with the expected schemes means the file is syntactically + referentially valid
- **R2 — `Package.swift` relative path resolution from inside `Demo/BoomBoomBoomKitDemo/`.** Xcode resolves `relativePath = ../../;` relative to the `.xcodeproj` directory (`Demo/BoomBoomBoomKitDemo/`), so `../../` walks up to `BoomBoomBoomKit/` (repo root). Verified against the AmbientUI precedent (their `relativePath = ../../../AmbientUI;` walks `Demo/AmbientUIDemo/AmbientUIDemo.xcodeproj/` → `Demo/AmbientUIDemo/` → `Demo/` → `AmbientUI/` repo root). If the dev agent guesses wrong on the levels-up count, Xcode will surface "Package not found" when opening the project — re-check Task 2.5
- **R3 — Code signing breaks `make demo-build` on a fresh-clone CI machine.** Without `CODE_SIGNING_ALLOWED=NO`, `xcodebuild` requires a valid signing identity — non-portable. DD #6 documents the verbatim env-vars; Task 8.1 implements them. **Test:** the dev agent runs `make demo-build` on this Mac (RT's machine has the team configured) AND verifies the exit code does NOT depend on the team — by temporarily setting `DEVELOPMENT_TEAM = "INVALID";` in the demo's `.pbxproj` Debug config and re-running `make demo-build`. The build should still succeed with the signing-disabled env-vars
- **R4 — App sandbox + drop-onto-window interaction (Story 5-2 prep; informational for 5-1).** Per Codex 2026-05-18 consultation referencing Apple's "Accessing Files from the macOS App Sandbox" doc: the `com.apple.security.files.user-selected.read-only` entitlement (DD #8) is *necessary but not sufficient* for `.dropDestination(for: URL.self)`. Apple's documentation auto-starts security-scoped access for **open/save panels and items dragged to the app's Dock icon** but does NOT make the same promise for arbitrary **window drops**. Story 5-2 MUST verify drop-onto-window via a real sandboxed acceptance test using `make demo-build-sandboxed` (PP5 amendment 2026-05-19: `make demo-build` is the unsigned target which does NOT enforce sandbox attachment; `make demo-build-sandboxed` is the signing-enabled sibling added by D4 patch 2026-05-18); if URLs from window drops are not pre-bracketed, the drop handler MUST call `url.startAccessingSecurityScopedResource()` for the duration of analysis, balanced with `stopAccessingSecurityScopedResource()` in `defer`. Story 5-1 only sets up the entitlement and declares the caveat via DD #16's sandbox section.
- **R4b — Test target sandbox blocks `AudioFixtures` access at runtime.** Sandboxing also blocks access to `AudioFixtures` (which live inside the `BoomBoomBoomKitTestSupport` target's `.bundle`) at run-time UNLESS the bundle is correctly included in the demo's test target's Resources phase. The synchronized-root-group + SPM's `resources: [.copy("Resources/AudioFixtures")]` declaration in `Package.swift:21` SHOULD handle bundling automatically. **Verification:** Task 7.2 runs the smoke test under the sandboxed test target; if `AudioFixtures.url(for:)` returns nil, the bundling is wrong. **Fallback if R4b fires:** explicitly add the fixture path to the test target's `PBXFileSystemSynchronizedRootGroup` exception list — but try the default path first
- **R5 — `BoomBoomBoomKitML.framework` linking pulls in unwanted Accelerate symbols / increases app bundle size for no Story-5-1 user value.** Mitigation: DD #4 documents the deliberate choice. Bundle size delta on a Debug build is acceptable (BNNS lives inside Accelerate which is system-shared); no extra payload. The link is "structural readiness" for future stories, not a feature
- **R6 — Swift 6 strict-concurrency catches `AnalysisViewModel.analyze(url:)` capture-list defect at build time.** The view model snapshots `options` to a local before `Task.detached` (Task 5.2). If the dev agent forgets this and writes `Task.detached { try AudioAnalysisService.analyzeBPM(url: url, options: self.options) }`, Swift 6 surfaces "capture of 'self' with non-Sendable type 'AnalysisViewModel'". **Mitigation:** Task 5.2 spec body shows the snapshot pattern verbatim; the dev agent's job is to copy it not interpret it
- **R7 — Xcode 26's default project-creation flow produces a different `objectVersion`.** If a developer creates a fresh Xcode-26 project via the New Project wizard, the format may be `objectVersion = 70` or `77` depending on Xcode point release. AmbientUI's project is `objectVersion = 77` (confirmed). The dev agent uses 77 verbatim from the template; future Xcode major versions may bump this, at which point a follow-up story refreshes the template

### Apple Platform / Swift / SwiftUI / SPM Notes

All claims below validated against the AmbientUI demo (`/Users/rterhaar/Dropbox/research/swift/AmbientUI/Demo/AmbientUIDemo/`), the `axiom-swiftui` skill, the `axiom-concurrency` skill, and CLAUDE.md project-context.

#### Xcode project format — verbatim AmbientUI template excerpts

The dev agent uses the AmbientUI `project.pbxproj` as a line-by-line template. Critical sections to mirror:

**`XCLocalSwiftPackageReference`** (AmbientUI lines 595-602, our project's `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj`):

```
/* Begin XCLocalSwiftPackageReference section */
		<UUID> /* XCLocalSwiftPackageReference "../../" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = ../../;
		};
/* End XCLocalSwiftPackageReference section */
```

**`XCSwiftPackageProductDependency`** (two entries — one per library product):

```
/* Begin XCSwiftPackageProductDependency section */
		<UUID-A> /* BoomBoomBoomKit */ = {
			isa = XCSwiftPackageProductDependency;
			package = <UUID-of-XCLocalSwiftPackageReference> /* XCLocalSwiftPackageReference "../../" */;
			productName = BoomBoomBoomKit;
		};
		<UUID-B> /* BoomBoomBoomKitML */ = {
			isa = XCSwiftPackageProductDependency;
			package = <UUID-of-XCLocalSwiftPackageReference> /* XCLocalSwiftPackageReference "../../" */;
			productName = BoomBoomBoomKitML;
		};
/* End XCSwiftPackageProductDependency section */
```

**Workspace file** (`project.xcworkspace/contents.xcworkspacedata`, verbatim AmbientUI):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
```

**App target `packageProductDependencies` block** (inside the `PBXNativeTarget` section):

```
packageProductDependencies = (
    <UUID-A> /* BoomBoomBoomKit */,
    <UUID-B> /* BoomBoomBoomKitML */,
);
```

**Entitlements file** (`Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

#### SwiftUI architecture — Apple Native Patterns (`axiom-swiftui/skills/architecture.md`)

- **`@Observable` over `ObservableObject`**: per `axiom-swiftui/skills/architecture.md:65-67` + iOS 17+ adoption guidance, `@Observable` is the modern (and required-for-Swift-6) pattern. `final class` because `@Observable` macro generates synthesized stored properties on a class (value types can't observe).
- **`@MainActor` on the view model**: per `axiom-swiftui/skills/architecture.md:305`, "SwiftUI's `@Observable` and `ObservableObject` types must be `@MainActor`". Synchronous read from view bodies; mutation from async paths must hop to MainActor.
- **`@State` ownership of view model in the View**: per `axiom-swiftui/skills/architecture.md:626-634`, "@Observable in View body owned by View → @State; passed in from parent → don't @State it (use plain property or @Bindable)". Story 5-1's ContentView owns the lifecycle → `@State private var viewModel = AnalysisViewModel()`.
- **No `@StateObject`, no `@ObservedObject`** in the demo — those are pre-iOS-17 patterns, deprecated in favor of `@State` + `@Observable`.

#### Swift 6 concurrency (`axiom-concurrency`)

- **`Task.detached { try ... }.value`** is the cleanest off-MainActor hop pattern. The closure body runs detached from the calling actor; the `.value` await re-enters the calling actor (MainActor here). Per CLAUDE.md project-context.md's `nonisolated(unsafe)` discipline — Story 5-1's view model uses NONE of the three documented `nonisolated(unsafe)` escape hatches.
- **`AudioAnalysisResult: Sendable`** — confirmed at `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13`. The detached closure returns a `Sendable` value across the boundary cleanly.
- **`AudioAnalysisService.Options: Sendable`** — confirmed at `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:83`. The snapshot pattern in Task 5.2's analyze body (local `let opts = options` before `Task.detached`) avoids capturing `self`, which would force `AnalysisViewModel: Sendable` (it's `@MainActor`-isolated, not `Sendable`).
- **`URL: Sendable`** — Apple SDK type, no special handling needed.
- **`PCMBufferReaderError`** — confirmed at `Sources/BoomBoomBoomKit/PCMBufferReader.swift`; `Sendable` via enum-of-cases.

#### Swift Testing (`axiom-testing`)

- **`@Suite` + `@Test` + `#expect` + `#require`** — Swift Testing per CLAUDE.md project-context.md:94. Not XCTest.
- **`@MainActor` on the test function** because it calls `viewModel.analyze(url:)` which is `@MainActor`-isolated and reads `viewModel.detectedBPM` which is also MainActor-isolated. Without the annotation, Swift 6 surfaces "actor-isolated property 'detectedBPM' can not be referenced from a non-isolated context".

### Previous Story Intelligence

Story 4-7 (immediately prior, close-out 2026-05-17):

- **Test count band discipline (HALT-(d) precedent)** — Story 4-7 used a band `[432, 438]` for HALT-(d). Story 5-1 adds ZERO library tests; the test count stays at 433 (433 @Test( declarations per Story 4-7 close-out — actually verified by Task 0.1). No HALT-(d) for Story 5-1
- **Diff-scope proof artifact pattern — DEMOTED during Story 5-1 close-out.** Story 4-7 produced `_bmad-output/implementation-artifacts/4-7-diff-scope-proof.txt` and Story 5-1's spec author inherited the precedent in Task 11.7. During dev close-out the artifact was created but then deleted on review: for additive-only stories that touch zero `Sources/` and zero `Tests/` (Story 5-1's exact shape), the Completion Notes scope claim plus `git diff --stat` reproducibility on demand is sufficient — the standalone `.txt` adds duplication without earning its keep. Future spec authors should include a diff-scope-proof artifact ONLY when the story touches `Sources/` or `Tests/` and a reviewer might reasonably want a frozen receipt of the scope. Story 5-1's scope claim (zero `Sources/` changes, zero `Tests/` changes; additions confined to `Demo/`, `.gitignore`, `.swiftlint.yml`, `Makefile`, `_bmad-output/implementation-artifacts/5-1-*`) is recorded in Completion Notes and verifiable via `git diff --stat c555823^..HEAD`.
- **`/bmad-code-review` cadence** — Story 4-7 ran 4-layer parallel review (Claude Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex Blind Hunter) and applied 12 patches. Story 5-1 expects fewer findings — the surface area is tiny (Xcode project + one view-model file + one test file) and the contract is mostly "verify the file shapes match the templates." Still, the review IS run per project precedent. Per DD #11 A2: findings flow into `deferred-work.md`, not into this story's `[ ]` checkbox list

Epic 4 retro (close-out 2026-05-17, `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md`):

- **Epic 5 does NOT need a re-planning session** — the 5 stories (5-1 through 5-5) remain valid as written in `_bmad-output/planning-artifacts/epics.md:1256-1370`. Story 5-1 honors the epic-as-written exactly
- **T2 — CLAUDE.md Key Types final-pass sweep for Epic 4 additions** — flagged in the retro as a precondition to Story 5-5 (Public API Documentation), NOT to Story 5-1. The retro flagged "can be Story 5-1's first commit, OR a standalone pre-Story-5-1 commit." This spec authorizes EITHER. The dev agent's call: fold into Story 5-1 only if doing so doesn't bloat scope; otherwise leave for Story 5-5 to own. Recommended: leave for Story 5-5 — Story 5-1 has enough surface area in the Xcode project alone
- **A2 (deferred-work.md as canonical) + A3 (wall-clock baseline)** — Story 5-1 IS the trigger story. See DD #11

### References

- `_bmad-output/planning-artifacts/epics.md:1256-1284` — Story 5.1 acceptance criteria (as written)
- `_bmad-output/planning-artifacts/epics.md:237-242` — Epic 5 preamble (sequencing, dependencies)
- `_bmad-output/planning-artifacts/architecture.md:161-180` — Demo App Structure decision (AmbientUI pattern reference)
- `_bmad-output/planning-artifacts/architecture.md:484-488` — Demo app boundary (public-API-only, ships on main)
- `_bmad-output/planning-artifacts/architecture.md:458-468` — Source tree placement under `Demo/`
- `_bmad-output/planning-artifacts/prd.md:164-182` — Journey 4 (Power User — Algorithm Evaluation via Demo App) — the consumer story the scaffold ultimately serves
- `_bmad-output/planning-artifacts/prd.md:560-569` — FR34-FR41 (Demo Application functional requirements)
- `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md:141-153` — Epic 5 preparation findings + critical path
- `_bmad-output/implementation-artifacts/epic-4-retro-2026-05-17.md:100-108` — A2 + A3 action items (trigger: first Epic 5 story landing)
- `_bmad-output/implementation-artifacts/4-7-spectral-flux-onset-dsp-variant.md` — most recent prior story (PSI source: gating gauntlet pattern, diff-scope proof, code-review cadence)
- `_bmad-output/project-context.md` — all project-level rules. Notably: "Public API Discipline (pre-1.0)" subsection (Story 5-1 honors the discipline by adding ZERO public types to the library), `nonisolated(unsafe)` discipline (Story 5-1 uses NONE), framework-specific rules (none touched), testing rules (Swift Testing for the smoke test, `@MainActor` annotation pattern)
- `/Users/rterhaar/Dropbox/research/swift/AmbientUI/Demo/AmbientUIDemo/` — reference template for the entire Xcode project shape (objectVersion 77, synchronized root groups, local SPM dependency, two-target layout). Local file path; NOT a network resource — the dev agent reads `AmbientUIDemo.xcodeproj/project.pbxproj` directly to crib the precise line patterns
- `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` — Xcode-bundled documentation for SwiftUI App / Scene / WindowGroup patterns (if Apple-docs validation is needed for the App entry shape)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-58` — `AudioAnalysisResult` + `AudioAnalysisService` public surface
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:283-302` — `Options` init + `analyzeBPM(url:)` default entry
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:321-324` — `analyzeBPM(url:options:)` parameterized entry
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — `AnalysisIntensity` public surface
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift:105` — `bundledReferenceURL = nil` post-Story-4-6 Branch C (confirms link-only is safe)
- `axiom-swiftui/skills/architecture.md:57-100` — Apple Native Patterns (iOS 26+) — `@Observable` over `ObservableObject`, State-as-Bridge
- `axiom-swiftui/skills/architecture.md:305-340` — `@MainActor @Observable` pattern + actor / observable bridging
- `axiom-swiftui/skills/architecture.md:626-634` — property wrapper decision (`@State` for owned, plain property for parent-passed)
- `axiom-swift/skills/transferable-ref.md:638-653` — `loadTransferable` async + MainActor return pattern (not used in 5-1, referenced for 5-2's drop handler that this scaffold enables)
- `MEMORY.md` — user preferences. Notable: no emojis in Makefiles / echo / code artifacts (`feedback_no_emojis.md`); no business jargon in commits (`feedback_no_business_jargon_in_commits.md`); BC is NOT a goal pre-1.0 (`feedback_no_bc_goal_prerelease.md`)
- **Codex consultation 2026-05-18 thread `019e39df-1225-77f0-ba38-186b0322068a`** — plan-review of the four (now five) audio-file ADRs in DD #16. Verdict: A/B/C agreed verbatim; D modified to split exposed/operational state (`fileName: String?` exposed for display, `private(set) var selectedFileURL: URL?` operational for re-run); E added as cross-cutting concern (latest-selection-wins cancellation pre-positioned in Story 5-1). Sandbox / drop-onto-window caveat surfaced for Story 5-2 spec author. Apple docs: `https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox` (security-scoped resource semantics) + `https://developer.apple.com/documentation/UniformTypeIdentifiers/UTType-swift.struct` (UTType catalog, no `.caf` constant as of 2026-05-18)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.7 (`claude-opus-4-7`) via Claude Code.

### Debug Log References

None — clean execution. Two build-time discoveries surfaced and were
resolved inline (see Completion Notes "Build-time discoveries").

### Completion Notes List

**AC #8 / DD #11 A3 — `make test` baseline at Epic 5 START (M5 Max):**

- Cold-cache (first run, SPM resolves + builds + tests): 6.84s real, 40.71s
  user, 7.83s sys.
- Warm-cache (final close-out run): 2.01s real, 21.38s user, 0.34s sys.
- Tests passed: 431 runs in 94 suites (some `.disabled(if:)` skipped).
- `rg '@Test\(' Tests/BoomBoomBoomKitTests | wc -l` = **433** at Epic 5 start.
- Epic 5 close-out (after Story 5-5) compares against these numbers per A3.

**AC #7 — library gating gauntlet (all green):**

| Target | Result |
|---|---|
| `make fmt` | clean |
| `make lint` | 1 violation = `Sources/BoomBoomBoomKit/LUFSAnalyzer.swift:94` TODO baseline only |
| `make build` (Debug) | 0.35s real, exit 0 |
| `make build-release` | 7.16s real, exit 0 |
| `make test` | 2.01s real, 431/431 pass |
| `make demo-build` | 2.18s cold / 1.79s warm, exit 0 |
| `make demo-test` | 3.95s real (test runtime 0.052s), exit 0, smoke test passes |

**AC #7 — accuracy regression sanity (Story 5-1 touches zero library DSP):**

- `make benchmark` (OA300, intensity 7 default): **Acc1=58/82, Acc2=74/82**
  — matches spec baseline EXACTLY.
- `make benchmark-giantsteps`: genre-stratified **Overall Acc1=81.2%
  (537/661), Acc2=82.6% (546/661)** — matches spec baseline EXACTLY. (The
  bundled MIREX-tolerance test in the same suite reports 556/562 = 84.1%
  / 85.0%; that's a separate metric the spec didn't pin, but is also
  stable across this story.)

**AC #4 — `.gitignore` discipline (all four spec recipes + two bonuses):**

```
git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj            → NOT IGNORED
git check-ignore -v Demo/BoomBoomBoomKitDemo/build/x.o                                                → .gitignore:19 Demo/**/build/   (IGNORED)
git check-ignore -v Demo/BoomBoomBoomKitDemo/foo.xcuserstate                                          → .gitignore:20 Demo/**/*.xcuserstate (IGNORED)
git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/xcuserdata/foo.xcuserstatedata → .gitignore:9 xcuserdata/ (IGNORED, pre-existing global)
git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/contents.xcworkspacedata → NOT IGNORED
git check-ignore -v Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/xcuserdata/foo.xcuserstatedata → IGNORED via xcuserdata/
```

The bare `*.xcodeproj/` rule (formerly `.gitignore:7`) AND a discovered
parallel `*.xcworkspace/` rule (formerly `.gitignore:8`) were BOTH
narrowed to `*/xcuserdata/`. The spec's Task 0.2 only called out the
`.xcodeproj/` rule, but the `.xcworkspace/` rule would silently ignore
the `project.xcworkspace/` directory nested inside `.xcodeproj/` and
therefore mask `contents.xcworkspacedata`. Same defect class, same fix
shape — applied symmetrically.

**AC #3 — public-API-only discipline (zero `@testable`, zero internal-type refs):**

```
rg '@testable import' Demo/                                                                          → 0 matches
rg -l 'BPMAnalyzer|LUFSAnalyzer|MelFilterbank|FileMetadataReader|MetadataCorroborator|EnsembleCombiner|\bBPMResult\b|\bLUFSResult\b' Demo/  → 0 matches
```

Recipe inversion (Task 9.4): a temporary `@testable import` planted in a
demo source file IS detected by recipe 1, confirming the recipe is
non-trivial. Reverted before close-out.

Imports per AC #3.3:

```
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift:        import SwiftUI
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift: import SwiftUI
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift:  import BoomBoomBoomKit / Foundation / Observation / UniformTypeIdentifiers
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift: import BoomBoomBoomKit / BoomBoomBoomKitDemo / BoomBoomBoomKitTestSupport / Testing
```

The test target imports `BoomBoomBoomKitDemo` (the host module) to see
the public `AnalysisViewModel` surface without `@testable`. The app
target does NOT import `BoomBoomBoomKitML` — the project-level link is
structural (DD #4) but no source needs it yet.

**Build-time discoveries (delta from spec):**

1. **`UTType.flac` does not exist in Apple's public catalog**, contrary
   to the literal `.flac` constant referenced in DD #16-B and AC #5.
   The compiler rejected the construction. Applied the same DD #16
   pattern used for `.caf`: added a named `flacUTType` helper
   (`UTType("org.xiph.flac")!`) symmetric to `cafUTType`. The whitelist
   still has exactly 6 entries; the two non-catalog UTIs are localized
   in helpers. Verified at build time 2026-05-18 (not catalog-time);
   the spec author's pre-flight Codex check covered `.caf` but missed
   `.flac`.

2. **`AnalysisViewModel` and its observed surface marked `public`**
   (instead of default-internal) so the demo test target can `import
   BoomBoomBoomKitDemo` and exercise the wrapping contract without
   `@testable import` (forbidden by AC #3). The init is also `public`
   so the smoke test can construct an instance. The spec assumed
   default-internal access would work for the test target — but a
   non-test-host SwiftUI app target's internals are NOT visible to its
   test bundle without either `@testable` or explicit `public`. Marking
   them `public` only widens visibility from the test bundle's
   perspective; there is no library consumer of the demo's module. The
   `private(set)` operational `selectedFileURL` is now `public
   private(set)` (read-only externally, settable internally — DD #16-D
   semantics preserved). The internal-only `analysisTask` (DD #16-E
   plumbing) remains `private`.

3. **`AudioFixtures.url(for:extension:)` returns non-optional `URL`
   and throws** (signature: `static func url(for:extension:) throws ->
   URL`), so the spec's `try #require(AudioFixtures.url(...), msg)`
   wrapping was incorrect — `#require` expects an Optional. Replaced
   with a direct `try` call; the throw IS the missing-fixture signal.

4. **Pre-flight swiftlint config gap (Task 0 hygiene addition)**:
   `make lint` initially reported 157 violations (2 serious) — all from
   `tools/coreml-convert/.venv/`, `_bmad-output/ml-training/.venv/`, and
   the nested `_bmad-output/ml-training/swift_feature_extractor/.build/`
   trees (transitively-installed coremltools Swift sample code, not
   BoomBoomBoomKit code). Added three exclusion paths to
   `.swiftlint.yml`. Post-fix: 1 violation = the canonical
   `LUFSAnalyzer.swift:94` TODO baseline. Folded into the Task 0
   `gitignore prep` commit — symmetric "pre-flight hygiene gating
   cleanup" character.

**Diff-scope claim** (per Task 11.7; standalone `.txt` artifact
demoted during close-out — see Previous Story Intelligence):

`git diff --stat` against the hygiene commit (`c555823^..HEAD`) shows
13 files changed, 814 insertions, 2 deletions. Confirmed: zero paths
under `Sources/`, zero paths under `Tests/`. Additions confined to
`Demo/`, `.gitignore`, `.swiftlint.yml`, `Makefile`,
`_bmad-output/implementation-artifacts/5-1-*`. Library byte-untouched
(verified by the unchanged OA300 + GiantSteps accuracy counts above).

**DD #16-A audio-file discipline:**
`find Demo -type f \( -name '*.wav' -o -name '*.aiff' -o -name '*.mp3'
-o -name '*.flac' -o -name '*.m4a' -o -name '*.caf' \)` returns zero
matches. The Demo/ tree contains 10 files: 1 project.pbxproj, 1
workspace data, 4 Swift sources (App, ContentView, AnalysisViewModel,
SmokeTest), 1 entitlements plist, 3 asset JSON files. No bundled audio.

**Epic 5 hygiene (DD #11 A2):**
Review findings (none surfaced inline during dev; `/bmad-code-review`
deferred to Task 12.3 separate-LLM run per project convention) flow to
`_bmad-output/implementation-artifacts/deferred-work.md` with
cross-references, NOT as `[ ]` checkboxes in this story's Review
Findings section. A2 trigger satisfied.

**Pending close-out steps (gated):**

- Task 12.3 (`/bmad-code-review`) runs on user-driven cadence with a
  different LLM than this dev session per project precedent.
- Task 12.4 (final commit) is gated on 1Password GPG signer availability
  — the standalone Task 0.4 "gitignore prep" commit and the main
  close-out commit both attempted during the session failed with
  `1Password: failed to fill whole buffer`. The diff is fully prepared
  in the working tree; commits will land once 1Password is unlocked.
  The diff structure preserves the "standalone-revertable" property
  Task 0.4 requires (gitignore + swiftlint hygiene as one commit,
  Demo/+Makefile scaffold as another, story spec + sprint-status as the
  close-out commit).

### File List

Final set as of 2026-05-19 pass-2 close-out (`git diff --stat c120bc2`: 16 files changed, +1789 / −5):

```
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.pbxproj                                (new, 511 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj/project.xcworkspace/contents.xcworkspacedata   (new, 7 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoApp.swift                             (new, 12 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift                                        (new, 17 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/AnalysisViewModel.swift                                  (new, 158 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.entitlements                         (new, 10 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/Contents.json                            (new, 6 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AccentColor.colorset/Contents.json       (new, 11 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/Assets.xcassets/AppIcon.appiconset/Contents.json         (new, 58 lines)
Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemoTests/AnalysisViewModelSmokeTest.swift                    (new, 36 lines)
.gitignore                                                                                            (modified: bare `*.xcodeproj/` and `*.xcworkspace/` rules narrowed to `*/xcuserdata/`; 2 new `Demo/**/` rules)
.swiftlint.yml                                                                                        (modified: 3 new exclusion paths for transitively-installed .venv + nested .build Swift sample code)
Makefile                                                                                              (modified: + `demo-build`, `demo-test`, and `demo-build-sandboxed` targets; first two pass CODE_SIGNING_ALLOWED=NO, the third signs with the developer's identity for sandbox-bug repro)
_bmad-output/implementation-artifacts/5-1-demo-app-project-scaffold.md                                (new, story spec — Dev Agent Record + Review Findings populated by this session)
_bmad-output/implementation-artifacts/sprint-status.yaml                                              (modified: 5-1 status flip + last_updated)
_bmad-output/implementation-artifacts/deferred-work.md                                                (modified: new heading `## Deferred from: code review of 5-1-demo-app-project-scaffold (2026-05-18)` with W1–W11 entries; pass-2 (2026-05-19) added W12–W18 + amended W1, W11 in place)
```

Optional artifacts the spec listed but the dev agent did NOT add:

- `IDEWorkspaceChecks.plist` — not required; Xcode auto-generates on first
  open and CLI builds don't surface the warning.
- Shared `.xcscheme` files — not added. `xcodebuild -list` lists the four
  package-graph schemes (`BoomBoomBoomKit`, `BoomBoomBoomKitDemo`,
  `BoomBoomBoomKitML`, `BoomBoomBoomKitTestSupport`) plus the demo app
  scheme, but NOT `BoomBoomBoomKitDemoTests`. `xcodebuild test -scheme
  BoomBoomBoomKitDemoTests` still works because xcodebuild auto-resolves
  to the user-scheme at invocation time (verified — `make demo-test`
  passes in 0.054s). AC #2 was amended (PP4 patch, 2026-05-19) to make
  this literal-MUST relaxation explicit; if a future CI lane breaks on
  scheme discovery, commit
  `Demo/.../xcshareddata/xcschemes/BoomBoomBoomKitDemoTests.xcscheme`.

No `Sources/` or `Tests/` (library) modifications.

### Review Findings

`/bmad-code-review` (2026-05-18, 3-layer parallel: Blind Hunter / Edge Case Hunter / Acceptance Auditor). Per DD #11 A2: detailed findings live in `_bmad-output/implementation-artifacts/deferred-work.md` under heading `## Deferred from: code review of 5-1-demo-app-project-scaffold (2026-05-18)`. Inventory only here.

**Pass 1 resolution summary (2026-05-18):** 4 decisions resolved, 5 patches applied, 11 deferred (W1–W11 in `deferred-work.md`), 11 dismissed. Post-patch gauntlet: `make fmt` clean; `make lint` baseline; `make build` 0.12s; `make test` 431/431; `make demo-build` BUILD SUCCEEDED; `make demo-test` TEST SUCCEEDED 0.052s.

**Pass 2 (2026-05-19):** Second adversarial pass on the post-pass-1 state. 54 raw findings → 1 decision-needed + 7 patches + 7 deferred (W12–W18) + 39 dismissed. **Decision D5 resolved:** cancellation cascade leak fixed by replacing single-handle `analysisTask` with `inFlightTasks: Set<Task<Void, Never>>` so every prior task is cancelled on each new `analyze(url:)` call. **Patches PP1–PP7 applied:** PP1 changed atomic ordering from `.relaxed` to `.acquiring` (load) / `.releasing` (store) for cross-task happens-before; PP2–PP7 fixed spec doc-drift in DD #5 verification recipe, Task 9.1/9.3 recipes, AC #5 `.flac` → `flacUTType`, AC #2 scheme count, DD #16 sandbox caveat reference to `make demo-build-sandboxed`, DD #16-E narrative (now reflects atomic override + cancel-all-prior), DD #16-D `@testable` widening note, W1/W11 line drift in `deferred-work.md`. Post-pass-2 gating gauntlet rerun: `make demo-build` BUILD SUCCEEDED; `make demo-test` TEST SUCCEEDED 0.053s.

**Decisions resolved** (4):

- **D1 — `Task.detached` cancellation hand-off does not propagate `Task.isCancelled` into the DSP pipeline** [`AnalysisViewModel.swift:78-83`] — outer `analysisTask` cancellation correctly suppresses stale state writes via the `guard !Task.isCancelled` at line 89, but the in-flight `Task.detached { try AudioAnalysisService.analyzeBPM(...) }` is an unstructured detached task that does NOT inherit cancellation. The library's default `Options.isCancelled = { Task.isCancelled }` runs in the detached task's context and reads false; the DSP pipeline runs to completion on stale URL. DD #16-E latest-selection-wins is half-implemented (state-write-correctness yes; cooperative-cancellation no). Unreachable in 5-1 (no second-analyze trigger), reachable in 5-2+. **Resolution: Patch now (option A).** Applied via `Atomic<Bool>` + `withTaskCancellationHandler` — outer task's cancellation handler flips an atomic flag that the library polls at window boundaries.
- **D2 — `AnalysisViewModel` and observed surface widened to `public` to satisfy `import BoomBoomBoomKitDemo` from the test target without `@testable`** [`AnalysisViewModel.swift:8,15,28,33-39,45,54,60`] — pragmatic resolution to AC #3's no-`@testable` rule; widens the demo target's public surface. Documented in Completion Notes #2 but not in any AC text. **Resolution: Switch to @testable import.** Reverted to default-internal access on `AnalysisViewModel` and observed surface; test target uses `@testable import BoomBoomBoomKitDemo`; added `ENABLE_TESTABILITY = YES` to app target Debug config; AC #3 amended to permit `@testable` for demo-target-internal tests (the no-`@testable` discipline applies to library targets only).
- **D3 — `BoomBoomBoomKitDemoTests` is NOT listed as a discoverable scheme by `xcodebuild -project ... -list`** — listed schemes are `BoomBoomBoomKit`, `BoomBoomBoomKitDemo`, `BoomBoomBoomKitML`, `BoomBoomBoomKitTestSupport`. Task 2.5 spec text says this MUST list `BoomBoomBoomKitDemoTests`. `make demo-test` works in practice (verified — test passes 0.052s), so the dev's mitigation (auto-generation) is functionally adequate. Spec MUST is not strictly satisfied. **Resolution: Accept.** AC #2 amended with explicit literal-MUST relaxation; if a future CI lane breaks on scheme discovery, the fix is to commit `Demo/.../xcshareddata/xcschemes/BoomBoomBoomKitDemoTests.xcscheme` then.
- **D4 — `make demo-build` does not exercise sandboxed launch** [`Makefile:34-43`] — `CODE_SIGNING_ALLOWED=NO` produces an unsigned `.app`; sandboxd refuses to attach entitlements to unsigned binaries. Means `make demo-build` cannot catch sandbox bugs; Story 5-2's drop-handler sandbox interaction is unverified by this Makefile target. **Resolution: Add make demo-build-sandboxed.** New Makefile target that does NOT pass `CODE_SIGNING_ALLOWED=NO`; requires a configured signing identity; usable for sandbox bug repro. Default `make demo-build` remains fresh-clone-portable.

**Patches applied** (5):

- **P1 — Smoke test does not assert `selectedFileURL` was set after `analyze(url:)`** [`AnalysisViewModelSmokeTest.swift:28-32`] — AC #5 / DD #16-D explicitly require the operational `selectedFileURL` be populated alongside `fileName`. A future refactor that drops the assignment would pass the smoke test silently. **Applied:** added `#expect(viewModel.selectedFileURL == url)`.
- **P2** (from D1) — Cancellation hand-off via `Atomic<Bool>` + `withTaskCancellationHandler`; library cooperatively cancels at window boundaries. `@Sendable` annotations on the captured closures escape the project's default-MainActor isolation so `opts` crosses cleanly into the detached task.
- **P3** (from D2) — Switched to `@testable import BoomBoomBoomKitDemo`; dropped `public` modifiers from `AnalysisViewModel` and its observed surface; set `ENABLE_TESTABILITY = YES` on app target Debug config; amended AC #3 to permit `@testable` for demo-internal tests.
- **P4** (from D3) — Amended AC #2 with explicit literal-MUST relaxation paragraph about scheme auto-generation being functionally adequate.
- **P5** (from D4) — Added `make demo-build-sandboxed` Makefile target.

**Pass 2 detailed inventory (2026-05-19, post-pass-1 review):**

Decision resolved (1):

- **D5 — Cascade cancellation leak** [`AnalysisViewModel.swift:81-86, 88-114` post-patch] — D1's single-handle `analysisTask?.cancel()` could only reach the most recent task. Rapid `analyze(url:)` calls N times: each created a FRESH `Atomic<Bool>` and FRESH `opts` snapshot; nothing retained a handle to the N-2 earlier `cancelFlag` instances, so those detached pipelines ran to completion in parallel. Plus a race window where a prior task's success path could write state attributed to the new URL. Unreachable in 5-1 (single-shot smoke test); reachable in Story 5-2+ with rapid-drop UI. **Resolution: Patch now — cancel-all-prior.** Replaced `private var analysisTask: Task<Void, Never>?` with `private var inFlightTasks: Set<Task<Void, Never>>`; `analyze(url:)` iterates the set and cancels each prior task; a fire-and-forget cleanup `Task { _ = await task.value; self?.inFlightTasks.remove(task) }` removes entries on completion.

Patches applied (7):

- **PP1 — `Atomic<Bool>` memory ordering hardened** [`AnalysisViewModel.swift:91, 103`] — load ordering changed from `.relaxed` to `.acquiring`; store ordering changed from `.relaxed` to `.releasing`. Establishes happens-before across the outer-Task `onCancel` writer and the detached-task `opts.isCancelled` polling reader on weakly-ordered hardware.
- **PP2 — DD #5 / Task 9.1 / Task 9.3 verification recipes** — DD #5's bare `rg '@testable import|^@testable' Demo/` (line 96), Task 9.1's bare `rg '@testable import' Demo/` (line 442), and Task 9.3's import enumeration (line 444) were not updated symmetrically with pass-1's AC #3 amendment that permits `@testable import BoomBoomBoomKitDemo`. Live tree returned two matches; DD #5 said zero. All three recipes narrowed to library-targets-only.
- **PP3 — AC #5 `.flac` literal → `flacUTType` helper text** [`AnalysisViewModel.swift:22`] — AC #5 (line 230) and DD #16 code sample (line 58) still listed `.flac` as a catalog constant; Apple's `UTType` catalog has no such constant (verified at build time). Updated both to reference the `flacUTType = UTType("org.xiph.flac")!` named helper applied symmetrically with the existing `cafUTType` pattern. Closes W8 inline.
- **PP4 — AC #2 scheme count "four" → "three"** [spec line 196] — pass-1 P4 amendment paragraph listed three package-target schemes but called them "four"; off-by-one cosmetic.
- **PP5 — DD #16 sandbox caveat + R4 risk reference `make demo-build-sandboxed`** [spec lines 152, 503] — both narratives still pointed at `make demo-build` (unsandboxed) as Story 5-2's sandbox-verification target. Updated to `make demo-build-sandboxed` (the signing-enabled sibling added by D4 patch). Future Story 5-2 spec author can now connect the dots.
- **PP6 — DD #16-E narrative + DD #16-D `@testable` widening note** [spec lines 134-140] — DD #16-E originally claimed cancellation propagation via the library's default `Options.isCancelled = { Task.isCancelled }` closure; the D1 patch overrides that default with an `Atomic<Bool>` closure (because `Task.detached` does not inherit cancellation), and the D5 patch replaced `analysisTask?` with `inFlightTasks: Set`. Both changes folded into DD #16-E narrative. DD #16-D now documents that `@testable import BoomBoomBoomKitDemo` deliberately widens `private(set)` access for the demo's own test target only; production consumers still see read-only `selectedFileURL`.
- **PP7 — W1 / W11 line-number drift** [`deferred-work.md`] — W1 referenced `AnalysisViewModel.swift:89` and `:104-105`; D1 patch shifted those positions. W11 referenced `Makefile:34-55`; D4 patch added `demo-build-sandboxed` at `:57-65` (same xcodebuild-preflight gap, not covered by the original range). Both entries amended in place: W1 omits line numbers (the two early-return paths are unique within `analyze(url:)`); W11 extended to cover all three Makefile targets and the new `DEVELOPMENT_TEAM` env-pass-through gap.

**Pass 2 detailed inventory addendum (2026-05-19, PR #3 Copilot review):**

GitHub Copilot left 4 review comments on PR #3 (commit `7bca095`). Triaged with Codex consultation (threads `019e4257` for Swift API/deinit safety; `019e425a` for plan review). Two false positives (`ContinuousClock.now` is valid Swift since 5.7; verified by passing build), two valid:

- **PP8 — `AnalysisViewModel.deinit` cancellation backstop + `@ObservationIgnored` on `inFlightTasks`** [`AnalysisViewModel.swift`] — Copilot finding 3268834200 valid concern. Added `deinit { for task in inFlightTasks { task.cancel() } }` so detached DSP work is cancelled when the view model deallocates (preempts Story 5-2+ multi-window/sheet retrofit). Marked `inFlightTasks` `@ObservationIgnored` since it is operational state, never read by a view — observation tracking on it would be pure noise. Codex thread `019e4257` validated the plain non-isolated deinit pattern: `Task<Void, Never>` is `Sendable` and `Task.cancel()` is nonisolated, so iteration from `deinit` on a `@MainActor` class crosses no isolation boundary requiring `isolated deinit` (SE-0371). Filed as W19 in `deferred-work.md`.
- **PP9 — `make demo-build-sandboxed` threads `DEVELOPMENT_TEAM`** [`Makefile:57-66`] — Copilot finding 3268834240 valid; W14 closure. Added `DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) \` to the xcodebuild invocation so the help comment's env-var claim becomes true: `DEVELOPMENT_TEAM=ABC1234DEF make demo-build-sandboxed` now produces a correctly-signed build. Help comment updated to document the invocation pattern. W14 marked CLOSED in `deferred-work.md`.

**Deferred** (18 total — see `deferred-work.md` for detail):

Pass 1 (W1–W11):

- W1 — `isAnalyzing` early-return paths leave the flag stuck-true (unreachable in 5-1; bug in Story 5-2+ when UI cancel surfaces; reachability sharpened by pass-2 W12).
- W2 — `options` is mutable `var`; Story 5-3 picker mutation creates UI/run-config divergence during in-flight analysis.
- W3 — `CFBundleDocumentTypes` not declared; Story 5-2 "open with Finder" needs it.
- W4 — `MACOSX_DEPLOYMENT_TARGET` inherited project-level on app target, explicit on test target; asymmetric but functionally correct.
- W5 — NaN/Inf propagation from `AudioAnalysisResult` into `detectedBPM` / `confidence` — library responsibility, not demo.
- W6 — `BoomBoomBoomKitML` linked but never imported in source; possible "unused dependency" warning.
- W7 — `.swiftlint.yml` exclusion paths folded into Task 0 hygiene commit beyond literal Task 0 scope.
- W8 — Spec text said `.flac` UTType constant; addressed inline by PP3 amendment (no longer truly deferred — kept in ledger for traceability).
- W9 — No CI/pre-commit lint for `S85RR68YT7` team-ID leak; bare `.xcodeproj/` guardrail removed per Task 0.2 increased the attack surface. Promoted to urgent by pass-2 W16.
- W10 — `Demo/**/build/` gitignore pattern uses globstar `**`; works on modern git.
- W11 — `make demo-build` / `demo-test` / `demo-build-sandboxed` lack pre-flight check for `xcodebuild` + `DEVELOPER_DIR` + `DEVELOPMENT_TEAM` env pass-through.

Pass 2 (W12–W18):

- W12 — Stuck-`isAnalyzing` reachability broadens once SwiftUI parent-task cancellation propagates (window close, scene-phase transitions) — not just self-supersession. Sharpens W1's reachability profile.
- W13 — Test target's transitive linkage to `BoomBoomBoomKit` via implicit SPM/Xcode auto-resolve is fragile; future Xcode tightening may break.
- W14 — `make demo-build-sandboxed` lacks `DEVELOPMENT_TEAM=` env pass-through; cryptic errors on no/multiple signing identities. Merged with W11 in deferred-work.md.
- W15 — `elapsedSeconds` measures Task creation→completion wall-clock including scheduling latency, not pure DSP wall-clock.
- W16 — Promote W9 team-ID-leak guardrail to immediate pre-commit hook BEFORE Story 5-2 lands (Story 5-2 plausibly edits pbxproj in Xcode and Xcode auto-populates `DEVELOPMENT_TEAM`).
- W17 — Cancel-polling cadence is window-boundary-only at intensity 7+ (multi-second perceived latency); Story 5-2 cancel UX needs "Cancelling..." copy.
- W18 — `ENABLE_TESTABILITY = YES` on Debug only; project `defaultConfigurationName = Release` is a trap for any non-default test invocation.

**Dismissed** (pass 1: 11; pass 2: 39; not recorded):

Pass 1 (11): elapsedSeconds rounding (formula is correct); `@State + @Observable` (correct pattern); `Task.isCancelled` reads "wrong" task (Blind Hunter misread — outer task IS the right reference); AccentColor.colorset empty (universal-idiom placeholder is correct); AppIcon "no filename" warnings (CN AC #2 reports zero warnings empirically); UTType force-unwrap crash risk (well-known UTIs on macOS 15+); YAML single-line scalar style for sprint-status (cosmetic); options mutation race during in-flight (covered by W2); smoke test 20Hz busy-wait (fine for a 30s ceiling); test target links only TestSupport (works via TEST_HOST + transitive dep); spec Task 9.3 rg recipe omits `UniformTypeIdentifiers` (spec recipe gap, trivial post-merge).

Pass 2 (39 — highlights): `Atomic` noncopyable capture speculation (build passed; speculative); smoke test fast-path race against polling (works in practice); demo-build-sandboxed Release variant out of scope; empty `Sources` build phase + synchronized-group sweep + macOS 15 `Synchronization` requirement (all already pinned by `objectVersion=77` + `MACOSX_DEPLOYMENT_TARGET=15.0`); `analysisTask` not nilled (now obsoleted by D5's Set pattern); `.failure(is CancellationError)` arm is defensive code (cooperative cancellation contract returns nil/value, doesn't throw); `let optsForDetached` rebind (works as documented); DerivedData lock + hardened-runtime nits (cosmetic / out of scope); plus 30+ subtle Story-5-2-only lifecycle edges already covered by W12 + W17.
