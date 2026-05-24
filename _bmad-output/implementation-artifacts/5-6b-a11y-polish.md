# Story 5.6b: Accessibility + Layout Polish Follow-up

Story ID: 5.6b
Story Key: 5-6b-a11y-polish
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: backlog
Created: 2026-05-23 (via `/bmad-correct-course` after Story 5-6 code-review reconciliation)
Source: `_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md` (v3); Story 5-6 §Review Findings

## Story

As an end user of BoomBoomBoomKitDemo with accessibility needs (Dark Mode, VoiceOver, increased contrast, larger text),
I want the empty-state layout, neutral-gradient color, drop-target hit-region, toolbar toggle state announcement, caption contrast, and VoiceOver element grouping to honor the existing Story 5-6 acceptance criteria and platform conventions,
So that the App-Store-bound demo passes WCAG floors, App Review accessibility checks, and macOS HIG accessibility expectations without requiring re-review of Story 5-6's stated design decisions.

**Scope clarification (read first).** Story 5-6b is a narrow polish follow-up to Story 5-6's end-user UI redesign. It closes 6 of the 15 F-IDs surfaced by Story 5-6's `/code-review` reconciliation pass (the other 9 either fixed in Story 5-6 itself or deferred to Story 5-7 carry-over). Three of the 6 are explicit accepted-AC-violation deferrals from Story 5-6 close-out: F04 violates AC #12, F07 violates AC #6/#7, F13 violates KDD #5. The remaining 3 are narrow defects (F11 safe-area mismatch, F12 toolbar VoiceOver toggle state, F14 EmptyStateView accessibility grouping).

Six fixes ship:

1. **F04 — EmptyStateView upper-half layout fix** (Story 5-6 AC #12 violation). `EmptyStateView.swift:23` currently declares `.frame(maxWidth: .infinity, maxHeight: .infinity)`. The parent `ContentView.swift:44-48` VStack also contains `Spacer()` with equal layout priority. SwiftUI splits available vertical space 50/50, leaving EmptyStateView occupying only the upper half. AC #12 promised "fills the main pane" — the App Store screenshot subject ships visually broken until this fix lands.

2. **F07 — Neutral gradient Dark Mode break** (Story 5-6 AC #6/#7 violation). `StrategyBackground.swift:66` uses `Color(white: 0.95)` / `Color(white: 0.88)` static colors for the `.none` case. Every other strategy case uses dynamic semantic anchors (`.blue`, `.teal`, etc.). In Dark Mode the neutral case paints a near-white wash. AC #6 demands 4.5:1 metadata contrast in both Light and Dark mode; AC #7 demands solid-fill substitution when `colorSchemeContrast == .increased` (current `Color.<tint>.opacity(0.15)` is not actually solid). Apple-docs MCP correction (Story 5-6 v3): the original v1 fix proposal used `Color(NSColor.windowBackgroundColor)` which is the WRONG initializer spelling — it resolves to the asset-catalog overload `Color(_ name: String, bundle:)` and silently returns a placeholder. Use the labeled `Color(nsColor: .windowBackgroundColor)` form. Also: same color for both LinearGradient anchors = flat fill, not a gradient. Pair `.windowBackgroundColor` with `.underPageBackgroundColor` for a visible-but-subtle neutral gradient.

3. **F11 — Drop target safe-area mismatch.** `ContentView.swift:55` applies `.contentShape(Rectangle())` + `.dropDestination(for: URL.self)` to the outer ZStack which has no `.ignoresSafeArea()`. The child `StrategyBackground` DOES have `.ignoresSafeArea()`, so the gradient paints behind the title-bar safe area but drops on that strip silently fall through to the window chrome. Two fix options: (a) move `.ignoresSafeArea()` to the outer ZStack so visual + hit-test extents agree, or (b) stop the gradient at the safe area so the visual cue doesn't lie. Decide based on visual verification.

4. **F12 — Toolbar Diagnostics Button missing VoiceOver toggle-state announcement.** `ContentView.swift:87` Button has no `.accessibilityValue`. VoiceOver always announces "Diagnostics, button" regardless of whether the inspector is currently shown or hidden. AT users cannot determine state without invoking the button. Fix per Apple-docs MCP: `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))` — wrap in `Text(...)` because the currently-indexed Apple doc surface for `.accessibilityValue(_:)` only documents the `Text` overload (the `String` overload exists in the SDK and compiles, but `Text` matches the documented form for forward-compat).

5. **F13 — EmptyStateView caption contrast** (Story 5-6 KDD #5 violation). `EmptyStateView.swift:21` uses `.foregroundStyle(.tertiary)` for the supported-format caption. Story 5-6 KDD #5 explicitly specs `.secondary` — `.tertiary` is lower contrast and may drop below WCAG AA 4.5:1 floor on the (post-F07-fix) neutral background in Dark Mode. One-character fix.

6. **F14 — EmptyStateView VoiceOver element grouping.** `EmptyStateView.swift:12` outer VStack has no `.accessibilityElement(children: .combine)` and no `.accessibilityHint`. VoiceOver announces "Drop a track" + "Supported: WAV, AIFF, MP3, FLAC, M4A, CAF" as two separate elements, with no explanation of the drag-from-Finder or File→Open affordance. Fix per Apple-docs MCP: `.accessibilityElement(children: .combine)` to merge into one announcement, plus `.accessibilityHint("Drag an audio file here to analyze")`. "Drag" verb (not "Drop") matches macOS HIG + AppKit drop-target VoiceOver vocabulary (Finder, Mail attachments, etc.).

**What this story does NOT deliver** (explicitly OUT-OF-SCOPE):

- **No F10 (DEAD_CODE_STRIPPING removal).** F10 was promoted from this story's original scope to Story 5-6 Bucket 1 per Codex v3 review (preserving then reverting was pointless churn). Already closed in Story 5-6 Phase 2.
- **No new toolbar buttons or new view-model surface.** The VoiceOver fix (F12) reads existing `inspectorPresented` state; the EmptyStateView fixes (F04, F13, F14) are layout/style/accessibility-modifier additions to an existing view.
- **No new strategy gradient artwork or palette tuning.** F07 swaps the `.none` case to dynamic colors; the other 8 strategy cases remain as Story 5-6 shipped them.
- **No library Sources/Tests changes.** Demo/-only, matching Story 5-6's invariant.
- **No App Store submission prep.** Privacy manifest, app icon, archive target — all Story 5-7.
- **No new keyboard shortcuts, no new menu items, no new commands.** The existing toolbar Diagnostics button + ⌘⇧D + system View → Show Inspector + ⌃⌘I coverage from Story 5-6 is preserved verbatim.

## Key Design Decisions

1. **F04 fix is a single-line subtraction, not a layout restructure.** Drop `.frame(maxHeight: .infinity)` from EmptyStateView's outer VStack; the parent `Spacer()` in `ContentView.swift:44-48` will own vertical extent and naturally center EmptyStateView in the available pane. `maxWidth: .infinity` stays — horizontal centering is still desired. No changes to ContentView. Verified mechanism: SwiftUI gives Spacer all remaining vertical space when its sibling is intrinsic-height; EmptyStateView's intrinsic height (96pt symbol + 24pt + largeTitle + 24pt + callout ≈ 220pt) becomes the natural size.

2. **F07 fix uses `Color(nsColor: .windowBackgroundColor)` paired with `Color(nsColor: .underPageBackgroundColor)`.** Apple-docs MCP validated (Story 5-6 sprint-change-proposal v3): the labeled `nsColor:` initializer (macOS 12+) is the correct bridge from AppKit dynamic colors to SwiftUI Color. The bare `Color(NSColor.windowBackgroundColor)` form resolves to `Color(_ name: String, bundle:)` and silently falls back to a placeholder. The two-color pairing produces a visible-but-subtle gradient that adapts to Light/Dark mode and increased-contrast settings. Same color for both anchors would render as a flat fill. SwiftUI does not ship `Color.systemBackground` on macOS (UIKit-only); the AppKit bridge IS the right answer.

3. **F11 fix decision deferred to visual verification.** Two valid approaches: (a) move `.ignoresSafeArea()` from the StrategyBackground child to the outer ZStack so drops on the title-bar gradient strip register; (b) remove `.ignoresSafeArea()` from StrategyBackground so the gradient stops at the safe area and matches the actual drop hit-region. Visual judgment call — gradient-behind-titlebar may be a feature (more immersive) or a bug (visual cue lies about drop target). Dev agent picks during implementation based on which reads better in screenshots.

4. **F12 fix uses `.accessibilityValue(Text(...))` not `.accessibilityValue(_:String)`.** Apple-docs MCP (Story 5-6 v3): current Apple-indexed doc surface for `.accessibilityValue(_:)` only documents the `Text` overload. The `String`/`LocalizedStringResource` overload exists in the SDK and compiles today (mirrors `accessibilityLabel` / `accessibilityHint`), but wrapping in `Text(...)` matches the documented form for forward-compat. Identical at runtime; doc-canonical at compile-site.

5. **F14 hint text uses "Drag" verb, not "Drop".** Apple-docs MCP (Story 5-6 v3): macOS HIG and AppKit drop-target VoiceOver vocabulary (Finder, Mail attachments) consistently use "Drag" as the gesture verb. "Drop" is the consequence. The hint reads: `"Drag an audio file here to analyze"`. Story 5-6 EmptyStateView headline ("Drop a track") was not changed because the headline is shorter user-facing copy, not a hint; the hint announces the gesture.

6. **No new tests for any of the 6 fixes.** All 6 are layout / styling / accessibility-modifier additions. Story 5-6's existing 78 demo test invocations exercise the view-model contract, not view binding. SwiftUI snapshot testing is out of scope (no snapshot harness in the project). Dev agent verifies manually by running the app, dropping `bpm-120-click.wav`, and walking through VoiceOver + Larger Text + Dark Mode + Increased Contrast accessibility settings per the visual verification AC below.

## Acceptance Criteria

1. **F04 fix landed.** `EmptyStateView.swift:23` `.frame(maxWidth: .infinity, maxHeight: .infinity)` → `.frame(maxWidth: .infinity)`. Visual verification: drop no file; the EmptyStateView (96pt music.note.list + "Drop a track" largeTitle + caption) renders vertically centered in the main pane area (not jammed to the top half). Controls remain anchored at the bottom via the parent VStack's `Spacer()`. AC #12 of Story 5-6 is now satisfied.

2. **F07 fix landed.** `StrategyBackground.swift:66-67` `Color(white: 0.95)` / `Color(white: 0.88)` → `Color(nsColor: .windowBackgroundColor)` and `Color(nsColor: .underPageBackgroundColor)` respectively. The `nsColor:` argument label is REQUIRED — bare `Color(NSColor.windowBackgroundColor)` would silently resolve to the asset-catalog overload. The two-color pairing produces a visible neutral gradient that adapts to Light/Dark mode. AC #6/#7 of Story 5-6 are now satisfied.

3. **F11 fix landed.** Either `.ignoresSafeArea()` is added to the outer ZStack in `ContentView.swift:55` so drop-target hit-region matches the gradient extent, OR `.ignoresSafeArea()` is removed from `StrategyBackground` so the gradient stops at the safe area. Decision recorded in Completion Notes with rationale (which option reads better in screenshots).

4. **F12 fix landed.** Diagnostics toolbar Button gains `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))`. VoiceOver announces "Diagnostics, button, Shown" or "Diagnostics, button, Hidden" depending on current state.

5. **F13 fix landed.** `EmptyStateView.swift:21` `.foregroundStyle(.tertiary)` → `.foregroundStyle(.secondary)`. KDD #5 of Story 5-6 is now satisfied. Caption contrast clears WCAG AA 4.5:1 floor in both Light and Dark mode against the post-F07-fix neutral background.

6. **F14 fix landed.** `EmptyStateView.swift:12` outer VStack gains `.accessibilityElement(children: .combine)` + `.accessibilityHint("Drag an audio file here to analyze")`. VoiceOver announces the empty state as one combined element with a drop-affordance hint (announced after 2s focus pause per macOS VoiceOver default).

7. **`make demo-fmt demo-lint demo-build demo-test pre-commit` all green.** Test invocation count unchanged from Story 5-6 Phase 4 baseline (no new tests added).

8. **Library gating gauntlet remains green.** `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps` — outcomes unchanged from Story 5-6 close-out baseline (OA300 Acc1=58/82+74/82, GiantSteps 537/661+546/661, library test count 431/94).

9. **Diff scope is `Demo/**` only.** `git diff --stat Sources/` empty; `git diff --stat Tests/` empty. Within `Demo/`, only `ContentView.swift` (F11 + F12), `StrategyBackground.swift` (F07), and `EmptyStateView.swift` (F04 + F13 + F14) are edited. No pbxproj edits.

10. **Visual verification at 1280×800 and 2560×1600 window sizes** per Story 5-6 KDD #10 screenshot-stability discipline. Run the app, drop `bpm-120-click.wav`, walk through:
    - (a) Empty state renders centered, not upper-half (F04)
    - (b) Drop a file — gradient cross-fade works; the strategy gradient now renders correctly on next drop in BOTH Light and Dark mode (F07 — neutral pre-analysis gradient adapts to appearance)
    - (c) Try to drop onto the title-bar gradient strip — drop registers (F11 option a) OR the gradient stops at the safe area (F11 option b); record which option was chosen
    - (d) VoiceOver enabled — focus the toolbar Diagnostics button, hear "Diagnostics, button, Shown" or "Hidden" matching current inspector state (F12)
    - (e) VoiceOver enabled — focus the empty-state pane, hear one combined element with hint "Drag an audio file here to analyze" (F14)
    - (f) Switch to Dark Mode + sample EmptyStateView caption contrast via Digital Color Meter against the F07-fixed neutral background — must clear 4.5:1 (F13)

11. **Story 5-6 §Review Findings table updated.** F04, F07, F11, F12, F13, F14 rows flip from `deferred` / `deferred (accepted AC violation)` → `fixed (Story 5-6b)` with commit SHA from this story. The corresponding `_bmad-output/implementation-artifacts/deferred-work.md` entries W34, W36, W39-W42 flip to CLOSED inline annotations matching the project's existing ledger pattern.

## Tasks / Subtasks

- [ ] **Task 1 — F04 EmptyStateView layout fix** (AC #1).
  - [ ] 1.1 Edit `EmptyStateView.swift:23`: drop `maxHeight: .infinity`.
  - [ ] 1.2 Visual verify: empty state vertically centered, controls at bottom.

- [ ] **Task 2 — F07 StrategyBackground Dark Mode fix** (AC #2).
  - [ ] 2.1 Edit `StrategyBackground.swift:66-67`: `Color(white: 0.95)` → `Color(nsColor: .windowBackgroundColor)`; `Color(white: 0.88)` → `Color(nsColor: .underPageBackgroundColor)`.
  - [ ] 2.2 Visual verify in Light AND Dark mode: neutral gradient adapts; metadata clears 4.5:1.
  - [ ] 2.3 Verify NO compile error from initializer-overload ambiguity (the `nsColor:` argument label is required).

- [ ] **Task 3 — F11 drop-target safe-area decision + fix** (AC #3).
  - [ ] 3.1 Decide option (a) move `.ignoresSafeArea()` to ZStack OR option (b) remove from StrategyBackground.
  - [ ] 3.2 Implement chosen option.
  - [ ] 3.3 Record rationale in Completion Notes.

- [ ] **Task 4 — F12 toolbar VoiceOver toggle state** (AC #4).
  - [ ] 4.1 Add `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))` to Diagnostics Button at `ContentView.swift:87`.
  - [ ] 4.2 Visual verify with VoiceOver enabled.

- [ ] **Task 5 — F13 EmptyStateView caption contrast fix** (AC #5).
  - [ ] 5.1 Edit `EmptyStateView.swift:21`: `.tertiary` → `.secondary`.
  - [ ] 5.2 Digital Color Meter spot-check in Dark Mode against F07-fixed neutral background.

- [ ] **Task 6 — F14 EmptyStateView accessibility-element combine + hint** (AC #6).
  - [ ] 6.1 Add `.accessibilityElement(children: .combine)` to outer VStack at `EmptyStateView.swift:12`.
  - [ ] 6.2 Add `.accessibilityHint("Drag an audio file here to analyze")` to same VStack.
  - [ ] 6.3 Visual verify with VoiceOver enabled.

- [ ] **Task 7 — Gating gauntlet + spec close-out** (AC #7, #8, #9, #10).
  - [ ] 7.1 `make demo-fmt`, `make demo-lint`, `make demo-build`, `make demo-test`, `make pre-commit` — all green.
  - [ ] 7.2 `make build`, `make build-release`, `make test`, `make benchmark`, `make benchmark-giantsteps` — outcomes match Story 5-6 close-out.
  - [ ] 7.3 `git diff --stat Sources/` empty; `git diff --stat Tests/` empty.
  - [ ] 7.4 AC #10 visual verification (a-f) at 1280×800 and 2560×1600 — defer to user per Story 5-1+ precedent.

- [ ] **Task 8 — Update Story 5-6 §Review Findings + deferred-work.md** (AC #11).
  - [ ] 8.1 Story 5-6 §Review Findings table: flip F04/F07/F11/F12/F13/F14 rows from `deferred` → `fixed (Story 5-6b)` with commit SHA.
  - [ ] 8.2 `deferred-work.md` entries W34/W36/W39-W42: append CLOSED annotation inline per existing ledger pattern.
  - [ ] 8.3 Update sprint-status.yaml: `5-6b-a11y-polish: backlog → in-progress → review → done`.
  - [ ] 8.4 IF all of Story 5-6's 15 F-IDs now at terminal state: flip 5-6 status `review → done`.

- [ ] **Task 9 — Final commit on 1Password GPG signer** per Story 5-1+ precedent.
  - [ ] 9.1 Suggested message: `Story 5-6b: accessibility + layout polish — close F04/F07/F11/F12/F13/F14 from Story 5-6 review`.

## Apple Platform Notes

- **`Color(nsColor:)` initializer is available macOS 12+.** The labeled-argument form is REQUIRED; bare `Color(NSColor.foo)` resolves to `Color(_ name: String, bundle:)` (asset-catalog overload) and silently returns a placeholder. Apple ref: https://developer.apple.com/documentation/swiftui/color/init(nscolor:).
- **`NSColor.windowBackgroundColor` + `NSColor.underPageBackgroundColor` are dynamic colors** that adapt to Light/Dark mode and Increased Contrast settings. SwiftUI does not ship a `Color.systemBackground` on macOS (UIKit-only) — the AppKit bridge IS the canonical approach. Apple ref: https://developer.apple.com/documentation/appkit/nscolor/windowbackgroundcolor.
- **`.accessibilityValue(_:)`** currently indexed Apple doc surface documents only the `Text` overload (macOS 11+). The `String` overload exists in the SDK and compiles, but wrap in `Text(...)` for forward-compat alignment with the documented form. Apple ref: https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:).
- **`.accessibilityElement(children: .combine)`** merges child accessibility elements into one announcement (macOS 10.15+). `AccessibilityChildBehavior` is a struct with static-let properties `.ignore` / `.combine` / `.contain`. Apple's own doc example for `.combine` is literally a VStack of Image + Text + Button — matches EmptyStateView exactly. Apple ref: https://developer.apple.com/documentation/swiftui/accessibilitychildbehavior/combine.
- **`.accessibilityHint(_:)`** (macOS 13+) announces after a 2s focus pause on macOS as on iOS. macOS HIG + AppKit drop-target VoiceOver vocabulary uses "Drag" as the gesture verb. Apple ref: https://developer.apple.com/documentation/swiftui/view/accessibilityhint(_:).

## Risks

- **R1 — `nsColor:` argument-label mistake.** The single biggest implementation risk per Apple-docs MCP (Story 5-6 v3 finding). If the dev agent writes `Color(NSColor.windowBackgroundColor)` without the `nsColor:` label, the result silently resolves to the asset-catalog overload and renders a placeholder color (typically magenta or transparent depending on debug build) — F07 fix appears to land but doesn't. Mitigation: explicit AC #2 test step verifies "NO compile error from initializer-overload ambiguity" by reading the implementation back during code review and confirming both anchors use the labeled form.

- **R2 — F11 visual judgment.** The two safe-area options (gradient extends behind title bar with drop hit-region matching, vs gradient stops at safe area) are both defensible. Wrong choice ages poorly. Mitigation: dev agent screenshots both options before deciding, records rationale in Completion Notes.

- **R3 — EmptyStateView reflow after `maxHeight: .infinity` removal.** Dropping the height constraint may cause subtle vertical position drift between EmptyStateView and DisplayState transitions (e.g., empty → analyzing → result). Mitigation: visual verification per AC #10(a) catches this; if observed, restore some explicit vertical-centering modifier on the parent VStack rather than re-introducing the conflict.

## References

### Previous Story Intelligence (PSI)

1. **Story 5-6 (end-user UI redesign + collapsible trace inspector, 2026-05-23)** — the story that introduced EmptyStateView, StrategyBackground, the toolbar Diagnostics button, and the @SceneStorage default flip. Story 5-6's §Review Findings table is the source of the 6 F-IDs this story closes. Read Story 5-6 spec end-to-end before starting Story 5-6b.

2. **Sprint Change Proposal v3** (`_bmad-output/planning-artifacts/sprint-change-proposal-2026-05-23.md`) — the bridge document that triaged Story 5-6's code-review findings into Bucket 1 (fix in 5-6), Bucket 2 (defer to 5-7), and Bucket 3 (this story). Codex thread `019e5619-aa1b-7cc3-84e7-6579dd614712`. Apple-docs MCP validation is embedded in §4.3 / §4.4 (W36, W40, W42 entries).

3. **Deferred-work ledger** (`_bmad-output/implementation-artifacts/deferred-work.md`) — W34 (F04), W36 (F07), W39 (F11), W40 (F12), W41 (F13), W42 (F14). Each entry has the fix sketch + Apple-docs MCP corrections folded in.

4. **Story 5-3 (Parameter controls + Copy Config, 2026-05-20)** — establishes the `humanize(_:)` helper precedent that Story 5-6 F06 leveraged for the Picker fix; not directly used by this story but cited in case future a11y polish needs more user-facing string normalization.

## Diff-scope Expectations

**Files touched:**

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` — F04, F13, F14 (~5 line net delta).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` — F07 (~2 line net delta).
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — F11, F12 (~3 line net delta depending on F11 option chosen).
- `_bmad-output/implementation-artifacts/5-6-end-user-ui-redesign.md` — §Review Findings table SHA fill.
- `_bmad-output/implementation-artifacts/deferred-work.md` — W34/W36/W39-W42 CLOSED annotations.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status transitions.
- `_bmad-output/implementation-artifacts/5-6b-a11y-polish.md` — this file (Dev Agent Record populated at close-out).

**Files NOT touched:**

- `Sources/**` — zero library changes.
- `Tests/**` — zero library test changes.
- `Demo/.../AnalysisViewModel.swift` — view-model surface unchanged.
- `Demo/.../TraceView.swift` / `TraceExport.swift` — Story 5-4 territory.
- `Demo/.../BoomBoomBoomKitDemoApp.swift` — `InspectorCommands()` wire preserved.
- `Demo/.../project.pbxproj` — no build-setting changes (F10 was promoted to Story 5-6, not this story).
- `Package.swift`, `Makefile`, `.swiftlint.yml`, `.gitignore` — no changes.

## Dev Agent Record

### Implementation Plan

(filled by dev agent)

### Completion Notes

(filled by dev agent)

### Debug Log

(filled by dev agent)

### File List

(filled by dev agent)

### Change Log

- 2026-05-23 — Story 5-6b spec created via `/bmad-correct-course` Phase 1 (Paige) following Story 5-6 code-review reconciliation per Sprint Change Proposal v3. Status: backlog. Scope: 6 fixes (F04, F07, F11, F12, F13, F14) — three accepted AC violations from Story 5-6 close-out (F04→AC #12, F07→AC #6/#7, F13→KDD #5) plus three narrow defects (F11, F12, F14). Apple-docs MCP validation embedded in KDD #2/#4/#5 + AC #2/#4/#6. F10 (DEAD_CODE_STRIPPING) NOT in scope — promoted to Story 5-6 Bucket 1 per Codex v3 review.
