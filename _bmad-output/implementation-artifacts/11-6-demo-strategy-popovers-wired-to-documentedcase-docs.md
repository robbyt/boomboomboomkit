---
title: 'Demo strategy popover wired to DocumentedCase docs'
type: 'feature'
created: '2026-07-17'
baseline_revision: 6525c66db478ac712073de576865dad98caf09d5
final_revision: 4db222de3f90e8ae6eebcdaa72d6f5115ca4461a
status: 'review'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - '{project-root}/_bmad-output/implementation-artifacts/fr42-demo-popover-design-note.md'
  - '{project-root}/_bmad-output/implementation-artifacts/10-5-helpbutton-and-strategy-popovers-wired-to-epic-11-docs.md'
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** Story 11.5 shipped the full per-case documentation catalog (`BoomBoomBoomKitDocs.attributedString(for:id:)` + 49 authored Markdown files), but the demo still surfaces only terse one-line captions — the rich "what + why + failure-mode" prose (FR-42) is unreachable from the running app. Story 10.5 built a docs-popover mechanism, then reverted it because no authored prose existed yet to justify a popover over the inline subtitle.

**Approach:** Reintroduce a demo-owned `HelpButton` + a `DemoDocumentedCase` adapter, wired to the **Merge strategy** control only — the one control where the authored `BPMSelectionPolicy` prose materially exceeds its inline caption and maps 1:1 to a shipped doc. Because `BoomBoomBoomKitDocs` now ships, the adapter calls the accessor **directly** (no injected-resolver seam). Demo-only; `Sources/` and `Tests/` stay byte-identical.

## Boundaries & Constraints

**Always:**
- Demo-only. `git diff <base> -- Sources/ Tests/` MUST be empty (AC-locked).
- Never conform a library enum (`BPMSelectionPolicy`) to the demo protocol — wrap it in a demo-owned adapter (KDD-E1). The library `BPMSelectionPolicy` already conforms to the library `DocumentedCase`; the demo bridges by value, never by shared type.
- Pure derivations (`nonisolated`) so off-actor Swift Testing logic tests reach them under the demo's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. `HelpButton` (a `View`), its `@State`, and `body` stay MainActor-isolated.
- The accessor is total (non-optional, owns its `"Documentation unavailable for <kind>.<id>."` fallback). It is the single authoritative degraded state — do NOT build a competing demo fallback.
- Keep the existing inline `strategyDescription` caption (additive "?", no regression).
- Authored-string discipline (FR-44 `confidence-label-audit.sh`): popover copy is string literals, not banned-token interpolations.

**Block If:**
- The operator's review rejects the seam collapse (DD1) and requires the literal epic-AC `@Entry docsResolver` seam: revert to the seam design (preserved as the documented alternative in Design Notes) — do not invent a third architecture unattended.
- Any `BPMSelectionPolicy` case fails to resolve to authored (non-fallback) content in the demo test target (would mean a docID/bundle wiring bug, not a doc gap) — HALT and surface, do not paper over with the fallback.

**Never:**
- Do NOT wire a "?" to the Ensemble preset control (DD2) — its demo-side 4-preset enum is not 1:1 with `EnsemblePolicy`, and its inline subtitle intentionally supersedes a popover (EnsemblePresetPicker.swift:36-39). Authoring `EnsemblePreset/`-namespace docs is a separate story.
- Do NOT touch `BeatGridHelpButton` / `LoudnessHelpButton` or their pane switch — different concern (legend explainers), out of scope.
- Do NOT add or distort any control just to host a popover; do NOT add a mutable DSP-technique control (the reverted-10.5 readout stays retired).
- Do NOT add persistence (no UserDefaults) — the popover is derivation-only.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Authored doc resolves | `MergeStrategyDoc(.maxConfidence).docs` | `AttributedString` of the authored 3-paragraph prose (contains "What it does"), NOT the fallback sentinel | n/a |
| Every case wired | each `BPMSelectionPolicy.allCases` | `kind == "BPMSelectionPolicy"`, `id == rawValue`, non-empty `shortDescription` + `displayName`, all `id`s unique, all resolve non-fallback | assertion failure in test |
| Repo-docs URL | `HelpButtonDocs.repoDocURL(kind:id:)` | valid `URL` ending `/BPMSelectionPolicy/<id>.md`, each segment percent-encoded via `appending(component:)` | never force-unwrap; total fallback URL if construction fails |
| Adversarial id segment | `id` containing a space or `/` | that segment percent-encoded (`%20`, `%2F`), structural `/` preserved, non-nil `URL` | no crash, no trap |

</intent-contract>

## Code Map

- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift` — NEW. `DemoDocumentedCase` protocol (`kind`/`id`/`shortDescription`/`displayName` + computed `docs`), `HelpButton<T: DemoDocumentedCase>` view (mirrors `BeatGridHelpButton` chrome), pure `HelpButtonDocs.repoDocURL(kind:id:)`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift` — NEW. `MergeStrategyDoc` demo-owned adapter over `BPMSelectionPolicy` (all 8 cases).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — MOD. Merge-strategy header row (`HStack { Text("Merge strategy"); HelpButton(...); Spacer() }`) above the `.labelsHidden()` Picker (:393). Inline caption (:410) unchanged.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — MOD. Mark the pure `strategyDescription(_:)` (and `humanize(_:)` if reused for `displayName`) `nonisolated` so the nonisolated adapter shares the single-source switch instead of duplicating copy.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/HelpButtonLogicTests.swift` — NEW. Pure Swift Testing logic + real-resolution integration tests.
- `Sources/BoomBoomBoomKit/BoomBoomBoomKitDocs.swift` — REFERENCE (unchanged). `attributedString(for:id:)` total accessor at :68; fallback sentinel `"Documentation unavailable for <kind>.<id>."`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/BeatGridView.swift:528` — REFERENCE. `BeatGridHelpButton` chrome to mirror.

## Tasks & Acceptance

**Execution:**
- [x] `HelpButton.swift` — NEW. Declare `nonisolated protocol DemoDocumentedCase { var kind: String; var id: String; var shortDescription: String; var displayName: String }` with a default computed `var docs: AttributedString { BoomBoomBoomKitDocs.attributedString(for: kind, id: id) }`. Declare `struct HelpButton<T: DemoDocumentedCase>: View` taking `case:` (store as `documentedCase`), owning `@State private var isPresented`, rendering `questionmark.circle` (`.borderless`, `.controlSize(.small)`, `.help(shortDescription)`, `.accessibilityLabel("Help for Merge strategy: \(displayName)")`), opening `.popover(isPresented:arrowEdge:.bottom)`. Popover body: a bold `Text(displayName)` heading (front-matter title is stripped, so the case must be named in-view) + `ScrollView { Text(documentedCase.docs) }` + an always-present secondary `Link("View source documentation on GitHub", …)`, in `.padding().frame(width: 360)` with a bounded max height (~320). Add `enum HelpButtonDocs { nonisolated static func repoDocURL(kind: String, id: String) -> URL }` building `base.appending(component: kind).appending(component: "\(id).md")` (per-segment encoding), returning the base `Documentation/` URL as a total non-optional fallback.
- [x] `StrategyDocs.swift` — NEW. `nonisolated struct MergeStrategyDoc: DemoDocumentedCase` wrapping `BPMSelectionPolicy`: `kind = "BPMSelectionPolicy"`, `id = policy.rawValue`, `shortDescription = AnalysisViewModel.strategyDescription(policy)`, `displayName = AnalysisViewModel.humanize(policy)` (capitalized). Exhaustive over all 8 cases via the enum's `CaseIterable`/rawValue — do NOT conform `BPMSelectionPolicy`.
- [x] `AnalysisViewModel.swift` — MOD. Mark `strategyDescription(_:)` (and `humanize(_:)` if reused) `nonisolated` (both are pure switches; verify no MainActor state) so the adapter reuses the single-source copy off-actor.
- [x] `ContentView.swift` — MOD. Replace the `Picker("Merge strategy", …)` label with an `HStack { Text("Merge strategy"); HelpButton(case: MergeStrategyDoc(viewModel.options.mergeStrategy)); Spacer() }` header row above the now-`.labelsHidden()` Picker (:393). Keep the `strategyDescription` caption (:410). Exactly one accessible "Merge strategy" label survives. Do not touch the Ensemble control, legends, or app root.
- [x] `HelpButtonLogicTests.swift` — NEW. Pure `nonisolated` Swift Testing (no UI, no audio): (a) for every `BPMSelectionPolicy.allCases`, assert exact `kind`/`id`, non-empty `shortDescription`+`displayName`, all `id`s unique; (b) assert each case's `docs` resolves to authored content — NOT the `"Documentation unavailable"` fallback sentinel AND contains an expected marker (`"What it does"`); (c) `repoDocURL` valid for all 8, structural `/` preserved, ends `<id>.md`; adversarial `id` with space/`/` → percent-encoded, non-nil, no crash.

**Acceptance Criteria:**
- Given the demo builds, when `make demo-build` runs, then BUILD SUCCEEDED with no reference to any unshipped symbol (the accessor is real, called directly).
- Given a user opens the Merge strategy "?", when the popover renders, then it shows the selected strategy's `displayName` heading + the authored multi-paragraph prose (scrollable, width-bounded) + a GitHub source link — never an empty popover, crash, or `Bundle.module` console error.
- Given the Ensemble control, when the demo renders, then it carries NO `HelpButton` (scope-locked; only the Merge strategy control does).
- Given the story is complete, when `git diff <base> -- Sources/ Tests/` runs, then it is empty (library byte-identical).
- Given the demo-UI discipline, when the story finishes the auto pipeline, then it lands in `review` (NOT `done`) with a "Pending operator action" note — operator GUI smoke (click "?", read prose, dismiss on outside-tap/Escape, no console error) + separate-LLM `/bmad-code-review` + 1Password-signed commit gate `done`.

## Design Notes

**DD1 — the injected-resolver seam is collapsed to a direct accessor call (diverges from the literal epic 11.6 AC).** The epic AC (`epics.md:1765`) says to "reintroduce the `@Entry docsResolver` seam and override it once at the app root." That seam existed in Story 10.5 solely because Epic 10 could not name the unshipped `BoomBoomBoomKitDocs` symbol without a compile error (design note, para "Epic 10/demo must not reference an unshipped Epic 11 symbol"). **That symbol now ships (11.1/11.5).** With the compile-sequencing problem gone, the seam's remaining justification collapses: the production resolver can no longer return `nil`, so the optional-`DocsResolver` fallback branch and the two-state `content(for:resolver:)` FSM would test a state the shipped app cannot reach, and an environment override adds a second config path + a new failure mode (forgetting the root override). Codex (gpt-5.6-sol, thread `019f729f`, adversarial) recommended collapsing it; the direct call from a demo-owned adapter is simpler, honest, and still satisfies KDD-E1. Testability moves to the real boundary — asserting every adapter `(kind,id)` resolves to authored non-fallback content. **Alternative preserved (revert lever, see Block If):** the full `@Entry docsResolver` seam + FSM per the reverted-10.5 spec, if the operator prefers matching the literal AC.

**DD2 — merge-strategy only; ensemble stays on its inline subtitle.** `BPMSelectionPolicy` (8 cases) maps 1:1 to shipped docs and the authored prose massively exceeds the one-line `strategyDescription`. The Ensemble control is a demo-side 4-preset enum (`default`/`dspOnly`/`mlAugmented`/`trustFileTags`); `mlAugmented` and `trustFileTags` both map to `.weightedVoting(...)` with *different* `SignalWeights`, so a per-case docID bridge would collapse them to one `weightedVoting.md` and imply a documentation precision that does not exist. Its inline subtitle was intentionally designed to supersede a popover. Confirmed by Codex as the decisive, evidence-based call.

**DD3 — popover heading + bounded body.** `BoomBoomBoomKitDocs` strips the YAML front-matter (including `title:`) before returning the body, so the prose has no in-band title. The popover shows the `displayName` heading so the user has confirmation of which case is explained. The ~250-word body renders in a `ScrollView` inside `.frame(width: 360)` with a bounded max height so a long doc cannot produce an unusably tall popover.

**DD4 — repo-docs link built per-segment.** `repoDocURL` uses `URL.appending(component:)` for `kind` then `"\(id).md"` (encodes an in-segment `/`→`%2F`), NOT `appending(path:)` on a joined string (which under-encodes) and NOT hand-rolled `.urlPathAllowed`. Base = `https://github.com/robbyt/BoomBoomBoomKit/blob/main/Sources/BoomBoomBoomKit/Resources/Documentation/`. The link is an always-present secondary action, never conditioned on an impossible `nil`. Label honest ("View source documentation on GitHub").

**Layout (pinned pre-dev per demo-UI discipline).** Parameters GroupBox, Merge strategy region:
```
Merge strategy   (?)                 <- HStack header: Text + HelpButton + Spacer
[ Max confidence ▾ ]                 <- .labelsHidden() menu Picker (unchanged behavior)
Uses the highest-confidence window…  <- existing inline caption (unchanged)
```
Popover (arrowEdge .bottom, width 360, scrollable): **Max confidence** (bold heading) / authored What-When-Tradeoff prose / "View source documentation on GitHub". A `#Preview` renders this before the GUI smoke.

## Verification

**Commands:**
- `make demo-fmt` — expected: clean.
- `make demo-build` — expected: BUILD SUCCEEDED (Swift 6 strict concurrency; `nonisolated` fixes only).
- `make demo-test` — expected: TEST SUCCEEDED; new `HelpButtonLogicTests` runs (via the Xcode synchronized group; add to `BoomBoomBoomBPM.xctestplan` only if not auto-picked-up).
- `make demo-lint` — expected: PASS (`DEVELOPMENT_TEAM` guard + `confidence-label-audit: PASS`).
- `git diff <base> -- Sources/ Tests/` — expected: empty (AC8 byte-identity).
- `grep -rn "HelpButton" Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/EnsemblePresetPicker.swift` — expected: no match (ensemble scope lock).

**Manual checks (operator GUI smoke — gates `done`, cannot be driven programmatically):**
- Click the Merge strategy "?": popover opens showing the selected strategy's heading + authored prose + GitHub link; scrolls if long; dismisses on outside-tap / Escape; zero `Bundle.module` console errors; changing the Picker updates which doc the "?" shows.
- Confirm no "?" appears on the Ensemble control; legends unchanged.

## Review Triage Log

### 2026-07-17 — Review pass (Blind Hunter + Edge Case Hunter + Codex blind-hunter)
- intent_gap: 0
- bad_spec: 0
- patch: 6: (high 0, medium 0, low 6)
- defer: 0
- reject: 8: (high 0, medium 0, low 8)
- addressed_findings:
  - `[low]` `[patch]` `HelpButton<T>` hardcoded "Merge strategy" in its `accessibilityLabel` (latent mislabel for any future conformer) — genericized to `"Help for \(displayName)"` + added `.accessibilityHint(shortDescription)` so VoiceOver gets the full one-liner sighted users get via `.help`.
  - `[low]` `[patch]` `.labelsHidden()` keeps the Picker's a11y label, so the sibling visible `Text` double-announced "Merge strategy" — marked the decorative `Text` `.accessibilityHidden(true)`; corrected the false "exactly one accessible label" comment.
  - `[low]` `[patch]` adapter hardcoded `kind`/`id` strings — sourced from the library's own `BPMSelectionPolicy.documentedKind` + `policy.documentationID` so the demo docID cannot drift from the accessor's resource path.
  - `[low]` `[patch]` `displayName` capitalization was untested — added exact assertions (`maxConfidence` → "Max confidence", `windowVoting` → "Window voting").
  - `[low]` `[patch]` resolution test coupled to library prose (`contains("What it does")`) — replaced with a length assertion (`count > 120`; fallback sentinel is ~55 chars) so a library rewording can't break the demo suite, keeping the negative sentinel check.
  - `[low]` `[patch]` `repoDocURL`'s `URL(string:)` fallback branch was undocumented dead code — added `#expect(URL(string: base) != nil)` to lock it as unreachable-by-construction.
- rejected (not this story's problem / unreachable / by-design): degenerate `kind`/`id` URL guard (closed enum + now library-sourced keys → unreachable); `/blob/main/` link 404 for a develop-only case (accepted DD4 degradation, harmless 404); synchronous cached `Bundle.module` read on the MainActor (by-design — the accessor is built for it); no popover/UI unit coverage (demo-UI operator GUI-smoke boundary, spec-stated); `#Preview` layout duplication (acceptable preview stub); test base-URL literal duplication (standard exact-URL assertion; sibling test is suffix-only); per-body adapter allocation (harmless value type); popover re-render on mid-open strategy mutation (unreachable — Picker is behind the popover — and benign if it occurred).

### 2026-07-17 — Codex diff-review pass (commit 7f786c4, gpt-5.6-sol)
- No merge-blockers. 3 nits; 2 patched, 1 rejected.
- addressed_findings:
  - `[low]` `[patch]` VoiceOver label lacked the control name ("Help for Max confidence" alone) — added a `controlName` requirement to `DemoDocumentedCase` (adapter supplies "Merge strategy", so the generic view still hardcodes nothing) → label now "Help for Merge strategy: Max confidence"; test asserts `controlName`.
  - `[low]` `[patch]` popover heading lacked the `.isHeader` accessibility trait — added `.accessibilityAddTraits(.isHeader)` so VoiceOver heading navigation reaches it.
- rejected: no UI/accessibility unit test (demo-UI operator GUI-smoke boundary — same by-design coverage split as the first pass).

## Auto Run Result

**Summary.** Reintroduced the demo FR-42 "?" docs-popover (reverted from Story 10.5), wired to the **Merge strategy** control only, rendering the now-shipped authored `BPMSelectionPolicy` per-case prose. Because `BoomBoomBoomKitDocs.attributedString(for:id:)` now ships, the adapter calls it **directly** — the reverted-10.5 `@Entry docsResolver` seam is collapsed away (DD1, Codex-endorsed). Demo-only; `Sources/` + `Tests/` byte-identical.

**Files changed.**
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/HelpButton.swift` (NEW) — `nonisolated protocol DemoDocumentedCase` (+ default `docs` calling the accessor directly), `HelpButton<T>` view (heading + scrollable prose + GitHub source link; generic a11y label + hint), `nonisolated enum HelpButtonDocs.repoDocURL`, `#Preview`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/StrategyDocs.swift` (NEW) — `MergeStrategyDoc` adapter (library-sourced `documentedKind`/`documentationID`; capitalized `displayName`; no library-enum conformance).
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` (MOD) — `strategyDescription`/`humanize` marked `nonisolated`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` (MOD) — merge-strategy header row (`Text` a11y-hidden) + `.labelsHidden()` Picker; inline caption kept.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/HelpButtonLogicTests.swift` (NEW) — 4 pure logic + real-resolution tests.

**Findings breakdown.** 6 patches applied (all low: 3 accessibility/label, 1 single-source, 2 test-robustness); 8 rejected (unreachable / by-design / pre-existing); 0 deferred; 0 intent_gap; 0 bad_spec (no loopback).

**Verification.** `make demo-fmt` clean · MCP `BuildProject` (windowtab3) BUILD SUCCEEDED (×2, pre- and post-patch) · `make demo-test` TEST SUCCEEDED (4 `HelpButtonLogicTests` pass) · `make demo-lint` PASS (`confidence-label-audit: PASS`) · `git diff 6525c66 -- Sources/ Tests/` empty · ensemble scope-lock grep no-match · layout pinned via a rendered `#Preview`.

**Divergence from epic AC (flagged for operator).** The epic 11.6 AC (a stub) mandates the `@Entry docsResolver` seam; DD1 collapses it to a direct accessor call now that the symbol ships. The full seam design is preserved as the documented revert lever (Boundaries → Block If) if the operator prefers matching the literal AC.

**Pending operator action (gates project `done` — NOT done by the auto run).** Per the demo-UI discipline (CLAUDE.md "Demo app conventions" + project-context operator-owned closeout): (1) **operator GUI smoke** — launch the demo, click the Merge strategy "?", confirm the popover shows the strategy heading + authored prose + GitHub link, scrolls if long, dismisses on outside-tap/Escape, updates with the Picker, zero `Bundle.module` console errors, and no "?" on the Ensemble control; (2) separate-LLM `/bmad-code-review`; (3) operator opens the PR into `rterhaar/epic-11`. The dev-auto commit is signed; sprint-status is left at `review` (not `done`) until GUI smoke passes.

**Residual risks.** Low. VoiceOver behavior (label/hint, hidden decorative text) is a standard SwiftUI idiom, verified by build+test but confirmable only in the running app (part of the GUI smoke). The GitHub source link 404s for any case not yet squash-merged to `main` — accepted graceful degradation (DD4).

## Code Review Findings — close-out (2026-07-18)

Separate-LLM `/bmad-code-review` (operator-requested) over the shipped demo surface (`6525c66..ec96f9c`, PR #102), 4 adversarial layers: Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex blind-hunter (`019f73f0`, gpt-5.6-sol/medium). **Verdict: clean on the demo code.** Codex found no defects; Blind Hunter and Edge Case Hunter found no correctness/isolation/URL/KDD-E1 defect (they independently confirmed the GitHub base path matches the real resource dir, zero docID drift since `MergeStrategyDoc.kind`/`.id` derive from `BPMSelectionPolicy.documentedKind`/`.documentationID`, `nonisolated` markings sound, and `appending(component:)` correctly `%20`/`%2F`-encodes); the Acceptance Auditor verified all ACs (incl. the ensemble scope-lock grep and the `Sources/`/`Tests/` byte-identity). Triage: 0 decision-needed, 0 code patches, 1 defer, 5 dismiss.

- [x] **[Review][Defer] Open help popover live-swaps its content on a PROGRAMMATIC `mergeStrategy` change** [`HelpButton.swift:80-104`] — deferred as **W91**. Latent, no current trigger (`mergeStrategy` only changes via the user-driven Picker today); the `ContentView` comment already warns a future preset/Copy-Config feature could mutate it. Benign-to-confusing UX, no crash.
- Dismissed (5): documented-dead `repoDocURL` `URL(filePath:)` fallback (the test asserts it dead-by-construction); synchronous doc read on first popover open (cached thereafter; a ~200-400-word bundled file behind a tap — negligible); `.help` + `.accessibilityHint` both carrying `shortDescription` (minor VoiceOver double-voice — an intentional belt-and-suspenders from the authoring review); per-render `strategyDescription` recompute (trivial pure switch); the resolution test using `count > 120` + negative-sentinel instead of the `"What it does"` marker (deliberate, reviewed decoupling from library wording — Review Triage Log #5).

**Runtime-verification items folded into the operator GUI smoke** (these are live-VoiceOver checks, not code-patchable defects — the code is correct if `.labelsHidden()` behaves as the standard idiom expects): (a) the Merge-strategy Picker's VoiceOver name now relies on `.labelsHidden()` retaining the control title (the visible "Merge strategy" `Text` is `.accessibilityHidden(true)`) — confirm VoiceOver announces the control, not just "pop-up button"; (b) the "?" help element sits above the Picker, so a top-to-bottom VoiceOver swipe reaches the help ("Help for Merge strategy: Max confidence") before the control itself — confirm this reads acceptably.

**Status stays `review` (NOT flipped to `done`).** Per the CLAUDE.md demo-UI discipline, a demo-UI story is never `done` on lint/test/code-review alone — the operator GUI smoke gates `done`. The code review is clean; the one remaining gate is the operator GUI smoke (item (1) in "Pending operator action" above; the separate-LLM review is now complete and the PR already landed as #102/`ec96f9c`). On a passing GUI smoke, flip `11-6 → done`.
