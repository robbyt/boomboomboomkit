# FR-42 demo docs-popover — design note (deferred from Story 10.5 to Epic 11)

**Status:** design knowledge, no code. Story 10.5 built this mechanism, found it had **no non-redundant home in the demo before Epic 11's authored docs exist**, and was **reverted to baseline** (2026-07-12, operator + Codex `gpt-5.6-sol` thread `019f543c`). Wire it in an **Epic 11 demo-integration story**, when rich per-case prose exists to justify a popover. FR-42 (epics.md:107) moves with it.

## Why it was deferred (the sequencing lesson)

Story 10.5 tried to add "?" docs-popovers to the demo *ahead of* the Epic 11 docs bundle they render. Every candidate call site failed a real-use test:

- **Ensemble preset** — already has an always-visible inline subtitle (Story 9.1); a code comment in `EnsemblePresetPicker.swift` declares that inline description supersedes a popover. Non-goal.
- **Merge strategy** — has an always-visible inline subtitle (`AnalysisViewModel.strategyDescription`); a popover fallback showed the **same sentence** → pure redundancy until Epic 11 ships richer prose.
- **DSP techniques** — no user-facing control exists (only intensity→`TechniqueSet`); a read-only chip readout was tried and **removed** because the chips read as interactive toggles.
- **Graph legends** — `BeatGridHelpButton` / `LoudnessHelpButton` already provide `.popover()` "?" affordances (pane-switched) for a **different** concern (explaining graph layers).

Net: the demo already explains options three ways (legend popovers, inline subtitles, hover tooltips). A generic docs-popover adds value **only** once Epic 11 provides multi-paragraph authored prose that materially exceeds the inline one-liner. Shipping the mechanism unused validates nothing and risks an integration contract Epic 11 must reshape.

## The pattern to reuse when Epic 11 wires it

- **Epic 10/demo must not reference an unshipped Epic 11 symbol.** A literal `BoomBoomBoomKitDocs.attributedString(...)` call fails at **compile** time if the symbol doesn't exist — you cannot defer that to runtime. So resolution goes through an **injected resolver**, not a direct call.
- **Injected resolver seam:** a demo-local `typealias DocsResolver = @Sendable (String) -> AttributedString?`, supplied via a SwiftUI `@Entry var docsResolver` environment value defaulting to an **absent** resolver (`{ _ in nil }`). Epic 11 overrides it **once** at the app root with a resolver that calls the real accessor. Nil → FR-42 fallback.
- **The real accessor is two-arg + non-optional:** `BoomBoomBoomKitDocs.attributedString(for kind: String, id: String) -> AttributedString` (`architecture.md:624`). The demo carries a single `docID` string `"<kind>/<id>"`; the Epic 11 resolver **splits on the first `/`** into `(kind, id)`. Because the accessor is non-optional (owns its own informative fallback), the demo's shortDescription+Link fallback is the **Epic-10-only** affordance — not dead code, by design.
- **Demo-owned adapters, never library conformance:** wrap each library enum in a demo `struct` (e.g. `MergeStrategyDoc`) conforming to a demo-local `DemoDocumentedCase { var docID; var shortDescription }`. A `switch` over a `CaseIterable` library enum is compiler-mandatory exhaustive — that guards doc coverage. **Never** make a library enum conform to the demo protocol (KDD-E1 / epics.md:1501).
- **Generic `HelpButton<T: DemoDocumentedCase>`:** `questionmark.circle`, `.borderless`/`.controlSize(.small)`, `.help(shortDescription)`, `.popover(arrowEdge:.bottom)`. Reads `@Environment(\.docsResolver)`; no resolver parameter (tests drive a pure `content(for:resolver:)` helper).
- **Fallback URL:** build with `URL.appending(component:)` per segment (encodes an in-segment `/`→`%2F`), not `appending(path:)` and not hand-rolled `.urlPathAllowed`. Label the `Link` honestly ("View docs on GitHub" — it may 404 until the file ships).
- **Under Swift 6 + the demo's `MainActor` default isolation:** mark the pure helpers/adapters `nonisolated` (namespace `nonisolated enum`, adapter `nonisolated struct`) so off-actor logic tests reach them; the `HelpPopoverContent` result enum must be `nonisolated` for its synthesized `Equatable`.

## UX rules for the Epic 11 wiring decision

- **Keep inline one-line captions visible** for immediate orientation; a popover must **add depth**, not relocate the same sentence behind a click.
- **Wire a "?" only where rich prose materially exceeds the inline caption** — decide per control *when the content exists* (merge strategy? ensemble? maybe neither). The content makes the call concrete.
- **Never add or distort a control just to host a popover.**
- **Legend popovers (`BeatGridHelpButton`/`LoudnessHelpButton`) stay separate** specialized UI — do not fold them into the generic mechanism.

_Full reverted implementation + the 3-layer code review (which passed clean before the revert) are in the git history under Story 10.5's branch; the story spec `10-5-…md` is retained as the audit record._
