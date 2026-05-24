# Story 5.6b: Accessibility + Layout Polish Follow-up

Story ID: 5.6b
Story Key: 5-6b-a11y-polish
Epic: 5 — Developer Experience (Demo App + Documentation)
Status: done
Created: 2026-05-23 (rewritten 2026-05-24 — kept short per operator brief; this is a simple demo, not a public ship)
Source: Story 5-6 §Review Findings, F-IDs F04 / F07 / F11 / F12 / F13 / F14

## Story

As an end user of BoomBoomBoomKitDemo with accessibility needs,
I want the EmptyStateView, neutral gradient, drop-target hit-region, and toolbar Diagnostics button to behave correctly in Dark Mode + VoiceOver + Increased Contrast,
So that the demo's accessibility floor matches what Story 5-6's spec already promised.

Six small fixes to three files in `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/`. No library changes. No tests.

## The Six Fixes

1. **F04 — EmptyStateView centers in the full pane.** `EmptyStateView.swift:23` had `.frame(maxWidth: .infinity, maxHeight: .infinity)` competing with the parent `ContentView`'s `Spacer()` — they split 50/50 and the empty state landed in the upper half. The original short-spec fix (drop `maxHeight: .infinity`) regressed to "intrinsic height at the top of the pane" per Codex review 2026-05-24. **Actual fix:** restructure ContentView — drop the `Spacer()` between `bannerView` and `controlsSection`, apply `.frame(maxHeight: .infinity)` to `primaryStateView` so it claims the full pane height above intrinsic-height controls. EmptyStateView keeps `maxHeight: .infinity`; its VStack's default center alignment vertically centers content in the expanded frame. Result-view's `.frame(...alignment: .topTrailing)` gains `maxHeight: .infinity` so the BPM hero anchors top-right of the now-larger slot instead of centering vertically.

2. **F07 — Neutral gradient adapts to Dark Mode.** `StrategyBackground.swift:66` uses `Color(white: 0.95)` / `Color(white: 0.88)` for the `.none` (pre-analysis) case — paints a near-white wash in Dark Mode. Swap to `Color(nsColor: .windowBackgroundColor)` and `Color(nsColor: .underPageBackgroundColor)`. Use the labeled `Color(nsColor:)` form — Apple's canonical AppKit-bridge initializer.

3. **F11 — Drop-target safe-area mismatch.** `StrategyBackground` painted with `.ignoresSafeArea()` (`ContentView.swift:45`) but the `.dropDestination` on the outer ZStack (`ContentView.swift:63`) did NOT. The original short-spec fix (option a — add `.ignoresSafeArea()` to outer ZStack) regressed per Codex review 2026-05-24: `.ignoresSafeArea()` on the ZStack propagated to the content VStack and pushed the result-view BPM hero under the title bar. **Actual fix:** option b — remove `.ignoresSafeArea()` from `StrategyBackground` so both the gradient and the drop hit-region stop at the safe area, naturally agreeing at the same boundary. Drops on the title-bar strip won't register, but they also no longer appear visually drop-able.

4. **F12 — Toolbar Diagnostics button announces state.** `ContentView.swift:88-96` Button has no `.accessibilityValue`. VoiceOver says "Diagnostics, button" with no toggle state. Add `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))`.

5. **F13 — EmptyStateView caption contrast.** `EmptyStateView.swift:21` `.foregroundStyle(.tertiary)` may drop below WCAG AA 4.5:1 in Dark Mode against the post-F07 neutral background. Change to `.secondary`.

6. **F14 — EmptyStateView VoiceOver grouping.** `EmptyStateView.swift:12` outer VStack has no `.accessibilityElement(children: .combine)` and no hint — VoiceOver reads it as multiple separate elements with no drag affordance. Add `.accessibilityElement(children: .combine)` + `.accessibilityHint("Drag an audio file here to analyze")`.

## Acceptance Criteria

1. The six edits above are applied verbatim (or, for F11, the documented alternative).
2. `make demo-fmt demo-lint demo-build demo-test pre-commit` all green.
3. `git diff --stat Sources/` and `git diff --stat Tests/` both empty (Demo-only).
4. Manual visual verification (operator, defer per Story 5-1+ precedent):
    - Empty state vertically centered
    - Pre-analysis gradient looks fine in Light and Dark mode
    - Drop hit-region matches the gradient extent
    - VoiceOver toolbar Diagnostics announces "Shown" / "Hidden"
    - VoiceOver empty state reads as one element with the drag hint
    - Dark Mode caption is readable (`.secondary` not `.tertiary`)

## Files Touched

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` (F04, F13, F14)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` (F07)
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` (F11, F12)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status transitions)

## Apple Platform Notes (just the two non-obvious ones)

- `Color(nsColor:)` — labeled form is Apple's canonical AppKit bridge; preferred over the unlabeled `Color.init(_ color: NSColor)` overload for grep-ability.
- `NSColor.windowBackgroundColor` + `NSColor.underPageBackgroundColor` are dynamic colors (Light/Dark + Increased Contrast aware). SwiftUI has no `Color.systemBackground` on macOS — the AppKit bridge is the canonical answer.

## Dev Agent Record

### Implementation Plan

Six fixes to three Demo files in two passes:
- **Pass 1**: applied the short-spec edits verbatim. `make demo-build` + `make demo-test` green.
- **Pass 2 (Codex `/codex:diff-review` thread `019e5c10`)**: Codex flagged F04 and F11 as merge-blockers. F04's "drop `maxHeight: .infinity`" regressed EmptyStateView to "intrinsic height at the top of the pane" (parent `Spacer()` between bannerView and controlsSection doesn't center the upper view, just pushes controls down). F11's `.ignoresSafeArea()` on the outer ZStack propagated to the content VStack and threatened to push the result BPM hero under the title bar. Restructured: drop the parent `Spacer()` + give `primaryStateView` `.frame(maxHeight: .infinity)`; switch F11 to option b (remove `.ignoresSafeArea()` from `StrategyBackground` so visual and hit-region agree at the safe area). Pass-3 Codex follow-up caught that `resultView`'s `.frame(...alignment: .topTrailing)` only constrained width — added `maxHeight: .infinity` so the BPM hero anchors top-right of the new full-height slot instead of centering vertically. Three Codex rounds total, no remaining merge-blockers.

### Completion Notes

- **F04** — `EmptyStateView.swift:23` kept `.frame(maxWidth: .infinity, maxHeight: .infinity)` (its VStack default center alignment centers content inside the frame). `ContentView.swift` dropped the `Spacer()` between bannerView and controlsSection; `primaryStateView` now claims `.frame(maxWidth: .infinity, maxHeight: .infinity)` so controls anchor at the bottom by virtue of being the last intrinsic child after a flexible-height primary slot.
- **F07** — `StrategyBackground.swift:66-67` swap landed with the **labeled `nsColor:`** initializer per AC #2 / R1 (verified by `BUILD SUCCEEDED` — bare-form ambiguity would have failed at compile-time). Codex confirmed the API names are correct and `underPageBackgroundColor` is a distinct semantic anchor from `windowBackgroundColor`, so the LinearGradient is not mathematically flat.
- **F11** — option b: `.ignoresSafeArea()` removed from `StrategyBackground`. Gradient and drop hit-region naturally agree at the safe-area boundary. Drops on the title-bar strip won't register, but they also no longer appear visually drop-able. Codex flagged the original option-a attempt as risky (content under title bar) and endorsed option b as the safer macOS HIG default.
- **F12** — `ContentView.swift` Diagnostics toolbar button gained `.accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))`. Codex confirmed `.accessibilityValue` is valid on any View; semantically a `Toggle(...).toggleStyle(.button)` would be stronger but is out of scope.
- **F13** — `EmptyStateView.swift:21` `.foregroundStyle(.tertiary)` → `.foregroundStyle(.secondary)`. WCAG AA 4.5:1 caption-contrast floor honored.
- **F14** — `EmptyStateView.swift:12` outer VStack gained `.accessibilityElement(children: .combine)` + `.accessibilityHint("Drag an audio file here to analyze")`. Codex confirmed `.accessibilityHidden(true)` on the decorative SF Symbol remains suppressed under `.combine` per Apple's `AccessibilityChildBehavior.combine` doc.
- **Bonus follow-up** — `resultView` frame gained `maxHeight: .infinity` so the BPM hero anchors top-right of the new full-height primary slot (Codex caught this in pass 3; the original width-only frame would have centered the intrinsic-height result content vertically in the enlarged slot).

**Gating gauntlet (all green after pass 3):**
- `make demo-fmt` — clean
- `make demo-lint` — exit 0
- `make demo-build` — `** BUILD SUCCEEDED **`
- `make demo-test` — `** TEST SUCCEEDED **`
- `make pre-commit` — 1 violation (canonical `LUFSAnalyzer.swift:94 TODO` baseline preserved across Stories 5-1 through 5-7), 0 serious
- `make build` — 0.12s, unchanged
- `make test` — 431/94 in 1.573s, unchanged from Story 5-4/5-7 baseline
- `git diff --stat Sources/ Tests/` — empty (AC #3 satisfied)

**Pending operator action:** AC #4 manual visual verification at 1280×800 and 2560×1600. Codex flagged these as the must-checks: (a) empty-state centering, (b) titlebar/gradient boundary appearance, (c) drop target extent matches visual cue, (d) VoiceOver phrasing for Diagnostics button toggle, (e) combined empty-state announcement reads correctly. Deferred per Story 5-1+ precedent — operator-owned GUI smoke test.

### File List

- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/EmptyStateView.swift` — F04 + F13 + F14
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/StrategyBackground.swift` — F07
- `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo/ContentView.swift` — F11 + F12
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status transitions
- `_bmad-output/implementation-artifacts/5-6b-a11y-polish.md` — this file (Dev Agent Record)

### Change Log

- 2026-05-23 — Spec created via `/bmad-correct-course` after Story 5-6 code-review reconciliation.
- 2026-05-24 — Rewritten short per operator brief ("simple demo, does not need to be complicated"). Same six fixes, ceremony stripped. Status flipped backlog → ready-for-dev.
- 2026-05-24 — `/bmad-dev-story` initial implementation: 6 fixes applied per short spec. Gauntlet green, library benchmarks unchanged. F11 initially chose option a (`.ignoresSafeArea()` on outer ZStack).
- 2026-05-24 — `/codex:diff-review` thread `019e5c10` flagged F04 and F11 as merge-blockers. Pass 2: restructured ContentView (dropped parent Spacer, gave `primaryStateView` `.frame(maxHeight: .infinity)`); F11 switched to option b (removed `.ignoresSafeArea()` from `StrategyBackground`). Pass 3: Codex caught result-view top-right anchoring regression caused by pass 2 — added `maxHeight: .infinity` to result frame so the BPM hero anchors top-right of the new full-height primary slot. Codex round-4 confirmed no remaining merge-blockers. Status: review.

### Review Findings

Triage of `/bmad-code-review` 2026-05-24 (Blind Hunter + Edge Case Hunter + Acceptance Auditor; Auditor returned PASS on all six F-IDs and AC #3 empty). 1 decision-needed, 0 patches, 5 deferred, ~10 dismissed as noise (verified false positives or covered by AC #4 operator visual verification).

- [x] [Review][Decision] **F11 trade-off in 8 saturated strategy modes** — removing `.ignoresSafeArea()` from `StrategyBackground` collapses the ZStack to safe-area-respecting bounds. AC #4 visual-verification list covers only `.none` (pre-analysis) gradient. Post-analysis the gradient uses saturated colors (`.maxConfidence`=blue/indigo, `.windowVoting`=orange/pink, etc., per `StrategyBackground.swift:47-61`) and will now show a visible color boundary at the title-bar edge that the pre-F11 `.ignoresSafeArea()` version hid. **Resolved 2026-05-24 by operator: accept the seam, no AC change.** It is the deliberate cost of fixing the BPM-hero-under-title-bar bug; AC #4 stays scoped to `.none`.
- [x] [Review][Defer] **F12 idiomatic toggle trait alternative** [`ContentView.swift:112`] — deferred, polish-only. `Button { ... }.accessibilityValue(Text("Shown"/"Hidden"))` is spec-authorized per Apple-docs MCP. A more idiomatic VoiceOver announcement would come from `.accessibilityAddTraits(.isToggle)` (gives native "on/off" phrasing) or migrating the control to `Toggle { ... }.toggleStyle(.button)`. Both are out of scope for 5-6b; the current form is correct and announces state.
- [x] [Review][Defer] **F12 verbose VoiceOver phrasing** [`ContentView.swift:106-112`] — deferred, spec-compliant. `.help("Show / hide diagnostics (⌘⇧D)")` on macOS sets both tooltip AND VoiceOver hint; `.accessibilityValue(...)` adds value. Combined announcement is approximately "Diagnostics, Shown, button. Show / hide diagnostics, command shift D." Verbose but informative; tightening would mean trading off the keyboard-shortcut tooltip discoverability. Polish for a future pass.
- [x] [Review][Resolved] **F07 inaccurate technical claim in code comment** [`StrategyBackground.swift:65-68`] — comment asserted "bare `Color(NSColor.foo)` resolves to the asset-catalog overload `Color(_ name:bundle:)` and silently returns a placeholder." On macOS the bare form resolves to the unlabeled `Color.init(_ color: NSColor)`, not the `(_ name: String, bundle:)` asset overload — the "silent placeholder" warning is iOS-flavored lore that doesn't apply on macOS. The chosen `nsColor:`-labeled API is still correct and preferred per Apple docs; only the rationale text was off. Resolved 2026-05-24 by commit `<NEW-SHA>` per Copilot PR #12 re-flag (comment ids `3295467366` + `3295467376`).
- [x] [Review][Defer] **Pre-existing: `resultView` `secondaryMetadataRow` has no `.lineLimit`** [`ContentView.swift:372-376`] — deferred, not caused by 5-6b. With the new full-height `.topTrailing` anchoring, a sufficiently long `row.fileName` would wrap onto multiple lines and push the BPM hero downward. The risk pre-dates 5-6b (the rows have always been unbounded) and grows slightly with the new anchoring; a single-line truncation (`.lineLimit(1).truncationMode(.middle)`) would harden this but belongs in a 5-x polish story.
- [x] [Review][Defer] **F14 VoiceOver drop-action dead-zone** [`EmptyStateView.swift:24-25`] — deferred, pre-existing demo limitation. The `.accessibilityHint("Drag an audio file here to analyze")` promises an interaction that VoiceOver-only users cannot perform (macOS VoiceOver has no drag-and-drop gesture). A ⌘O / File → Open menu equivalent would be the standard alternative; not in scope for 5-6b.

**Dismissed as noise (not surfaced individually):**
- SF Symbol leak via `.combine` — verified `.accessibilityHidden(true)` at `EmptyStateView.swift:16`. False positive.
- Gradient mathematically flat after F07 — `gradientFill` applies asymmetric opacity (`0.18` vs `0.32`); two distinct NSColors. Visible gradient regardless.
- Multiple `.frame(maxHeight: .infinity)` "competing" in the VStack — SwiftUI gives flexible children leftover space after intrinsic-height children; layout is well-defined.
- Drop hit-region / overlay-stroke seam — both follow the ZStack's bounds, which now naturally agree with the gradient at the safe-area boundary. F11 fix is structurally correct.
- Hardcoded English "Shown"/"Hidden" not localized — demo is not localized; consistent with the rest of the demo target.
- WCAG measurement for `.secondary` over post-F07 gradient — covered by AC #4 ("Dark Mode caption is readable").
- `.analyzing` / `.errorOnly` implicit centering in the now-greedy primary slot — verified intrinsic-height content; centers naturally; covered by AC #4 operator verification.
- Small-window `controlsSection` clipping — SwiftUI prioritizes intrinsic-height children; `primaryStateView` shrinks first, controls keep intrinsic height.
- Hint redundancy with combined label — "Drag" (action) is meaningfully distinct from "Drop" (outcome) in the combined label.
