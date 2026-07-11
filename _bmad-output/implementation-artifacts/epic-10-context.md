# Epic 10 Context: Demo integration — beat-grid, LUFS, model selection, per-case docs popovers

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Wire the deeper Epic 8 public surface (`BeatGrid`, `BeatTimestamp`, `DownbeatResult`, `LUFSReport`, `ModelRegistry`) and Epic 11's docs accessor into the develop-only `Demo/BoomBoomBoomBPM/` Xcode app so a consumer can evaluate the library's full analysis output — beat-grid timeline, loudness readout, ML model selection, and per-strategy help — without rebuilding or inspecting JSON. This is the demo's "prove the deeper API surface" epic (Epic 9 already proved the ensemble). It matters because the demo is how consumers discover beat-grid, LUFS, and model-selection APIs; graceful degradation (FR-42) lets it ship before Epic 11's docs bundle closes.

## Stories

- Story 10.1: BookmarkPersistence — security-scoped bookmarks across launches
- Story 10.2: ModelPickerView — registry-backed model selection
- Story 10.3: BeatGridTimelineView — Canvas-based timeline + text readout
- Story 10.4: LUFSReadoutView — primary integrated LUFS + secondary breakdown
- Story 10.5: HelpButton + strategy popovers wired to Epic 11 docs

## Requirements & Constraints

- **Model selection (FR-37):** The picker sources entries from `ModelRegistry` (bundled + known-public references + user-added) and offers "Add model from disk…" via file picker. Selection drives the resolved model URL onto subsequent `analyzeBPM(url:options:)` runs. The primary view's grandfathered "Load Model…" button relocates into the picker sheet (restores FR-43 "primary stays primary").
- **User-added persistence (FR-38):** Only user-added models persist — bundled and known-public entries are stateless and re-resolve every launch. Store a security-scoped bookmark (`URL.bookmarkData(options: .withSecurityScope, …)`) in `UserDefaults`, keyed by a stable UUID. On launch, resolve all; refresh-and-re-persist stale bookmarks; drop unresolvable entries with a labeled diagnostic — never re-prompt the user mid-launch. No Keychain, no filesystem sidecar, no JSON wrapper.
- **Entitlements:** The demo `.entitlements` must carry all three true: `com.apple.security.app-sandbox`, `com.apple.security.files.user-selected.read-write` (shipped app-level superset — do NOT downgrade; the model bookmark itself is read-only via `.securityScopeAllowOnlyReadAccess`), and `com.apple.security.files.bookmarks.app-scope` (the commonly-forgotten one — load-bearing for cross-launch resolution).
- **Beat-grid view (FR-39):** Timeline + text readout only — waveform rendering is explicitly out of scope. No `AVAudioFile` waveform sampling, FFT-on-display, or pixel-per-sample loops. Text readout shows four labeled fields (estimated tempo, beat count, downbeat status, grid confidence). When a `BeatGrid` exists but no `DownbeatResult`, draw beat ticks only and show `Downbeat status: not-detected` — never silently render zero-confidence downbeats.
- **LUFS view (FR-40):** Integrated loudness is the primary number (with the literal `LUFS` unit label, typography ≥2× the secondary panel); true-peak (`dBTP`) and LRA (`LU`) are secondary. LUFS occupies a subordinate region so BPM stays the dominant visual element. `nil` fields render a labeled fallback (`True peak: unavailable`), never `0.0` or a hidden row.
- **Confidence-label discipline (FR-44):** Every confidence-like number carries a label naming what it is — no bare numerics anywhere in the demo. Enforced by `demo-lint` / `confidence-label-audit.sh`.
- **Graceful degradation (FR-42):** Strategy popovers must degrade cleanly when Epic 11's docs are absent — fallback to a one-line description + repo docs `Link`, never a broken `Bundle.module` lookup, empty popover, crash, or hidden button.

## Technical Decisions

- **Timeline rendering:** SwiftUI `Canvas` (KDD-D2) — not `Path`-in-`ZStack`, not Metal, not `UIView`/`NSView` bridging. Scrubber tracks current time at 60Hz via `TimelineView(.animation)`, NOT `Timer`-driven `@State` mutation. If beat density degrades performance, downsample visible ticks at the view layer — do not switch to Metal.
- **Bookmark persistence:** `UserDefaults` (KDD-D3), mirroring the Story 5-6 `MergeStrategyPersistence` precedent, sized for ~1–20 user-added models. Follow the demo UserDefaults hydration convention: `object(forKey:) == nil` for genuine-absence detection (not `string(forKey:)`), persist stable identifiers, self-heal poison values.
- **Popover:** SwiftUI `.popover()` anchored to a `questionmark.circle` SF Symbol button (KDD-D4) — native tap-outside / Escape dismissal, no custom overlay/sheet/tooltip/dismissal logic. Popover body renders `BoomBoomBoomKitDocs.attributedString(for:id:)` keyed by a string `docID`.
- **Epic 11 decoupling (zero compile-time dependency):** `HelpButton` is generic over a **demo-local** descriptor protocol (e.g. `DemoDocumentedCase` exposing `var docID: String` + `var shortDescription: String`) — distinct from Epic 11's library `DocumentedCase`. The bridge is the string `docID`, NOT a shared type; a future dev must not make a library enum conform to the demo protocol. `shortDescription` is demo-authored so the FR-42 fallback needs nothing from Epic 11.
- **Demo target isolation:** The demo builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so mark pure derivation/value types `nonisolated`; the library does not carry this default.
- **Build/signing:** Sandbox entitlements only attach under signed builds — reproduce bookmark/entitlement behavior with `make demo-build-sandboxed`, not `make demo-build` (which bypasses signing).

## Cross-Story Dependencies

- **Within epic:** Story order equals build order (`10.1 → 10.2 → 10.3 → 10.4 → 10.5`). The only intra-epic dependency is 10.2 (ModelPickerView) consuming 10.1 (BookmarkPersistence).
- **On Epic 8:** 10.2 needs `ModelRegistry`; 10.3 needs `BeatGrid`/`BeatTimestamp`/`DownbeatResult`; 10.4 needs `LUFSReport`. If `ModelRegistry` lands late, 10.2 ships a stub registry exposing only the file-picker path and reopens the AC when Epic 8 closes.
- **On Epic 11:** 10.5 references `BoomBoomBoomKitDocs.attributedString(for:id:)` by string `docID` only — wired at the call site when Story 11.1 lands. FR-42 fallback keeps 10.5 shippable before Epic 11 closes.
