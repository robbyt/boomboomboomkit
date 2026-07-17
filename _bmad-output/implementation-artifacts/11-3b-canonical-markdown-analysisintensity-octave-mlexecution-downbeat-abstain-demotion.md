# Story 11.3b: Author canonical Markdown for AnalysisIntensity + OctaveEquivalencePolicy + MLExecutionPolicy + DownbeatResult + AbstainReason + DemotionReason (25 files)

Status: done

<!-- bmad-dev-auto metadata -->
<!-- baseline_revision: create-story v1 (2026-07-16) -->
<!-- review_loop_iteration: 0 -->
<!-- finalized: 2026-07-16 — Codex spec review (thread 019f6d61) + party-mode; conformances confirmed compile-clean, 3 should-fixes folded (see Finalization Log) -->

> **Finalized 2026-07-16.** Codex confirmed all 5 conformances compile (no `import Foundation` needed for the non-Foundation files — the `docs`/`AttributedString` default resolves at the protocol declaration + unconstrained extension) and the ComputeBudget "reserved + uniform" framing is honest. Three should-fixes folded: (1) **AC-8 line numbers corrected** — stale `detected([BeatTimestamp])` is at `epics.md:981` (Story 8.1) + `:1667` (Story 11.3b), not the lines the draft named (`:1647` only lists filenames); (2) **DD-8 added** — reconcile the stale `ComputeBudget.swift:13/:57` comments that claim 6.5b wired proportional budgeting (it did not — `.budget` returns `.default`), else the honest level docs contradict shipped symbol docs; (3) **AC-4/6/7 hardened** — payload-invariant `documentationID` tested with ≥2 payloads, and the semantic gates (no-phantom-string, level7 footgun, budget-honesty) get targeted content checks + explicit manual-review sign-off. See Finalization Log.

> Sibling of Story 11.3a (done). The authoring CONTRACT, the scaffolder, `Resources/README.md`, and the structural-validator ALGORITHM are all established by 11.3a — this story reuses them verbatim and adds 25 files across 6 types + 5 conformances (AnalysisIntensity is already `DocumentedCase`-conformed from Story 11.2). Completing 11.3a + 11.3b brings the canonical corpus to exactly 49 files and unblocks Story 11.4.

## Story

As a **library author shipping per-case prose for the budget/policy and failure-mode types**,
I want **every case of `AnalysisIntensity` (10), `OctaveEquivalencePolicy` (3), `MLExecutionPolicy` (3), `DownbeatResult` (3), `AbstainReason` (4), and `DemotionReason` (2) to have a 200-400 word Markdown file with consistent structure, and the five not-yet-conformed enums to conform to `DocumentedCase`**,
so that **the budget-control + failure-mode documented family ships with authored prose, completing the 49-file canonical Markdown corpus and unblocking Story 11.4's drift-detection test across every `DocumentedCase` conformer.**

Additive and main-bound, like 11.3a: 25 resource files + 5 one-line-per-enum conformances. `Sources/` behavior byte-identical except the five enums gaining a protocol conformance; corpus floors untouched (no DSP path change).

## Key Design Decisions

**DD-1 — Reuse the 11.3a contract verbatim.** Front-matter (`id`/`title`/optional `payload`), three bold-lead paragraphs (`**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`), 200-400 words, ≤10 KB, inline `**bold**`/`_italic_` only (NO backticks — identifiers are italicized, per the 11.3a resolution), failure-mode sentence mandatory in Tradeoff. See the 11.3a spec's DD-3/DD-4/DD-9 for the full contract; this story does not restate it.

**DD-2 — Conformance: 1 already done, 1 String-raw, 4 associated-value.**
- `AnalysisIntensity` — ALREADY `DocumentedCase` (Story 11.2, `documentedKind = "AnalysisIntensity"`, free String-raw `documentationID`). No source edit; only author the 10 `.md` files into the reserved `Documentation/AnalysisIntensity/` directory.
- `OctaveEquivalencePolicy` — `String`-raw. Add `DocumentedCase` + `public static let documentedKind = "OctaveEquivalencePolicy"`. Free `documentationID`.
- `MLExecutionPolicy`, `DownbeatResult`, `AbstainReason`, `DemotionReason` — associated-value (or Equatable-only), so NOT `RawRepresentable`. Add `DocumentedCase` + `documentedKind` + a hand-written `public var documentationID: String` switching over cases (payload-ignoring). `MLExecutionPolicy` is `Equatable` not `Hashable` (NaN-safe `Double` payload) — `DocumentedCase: Sendable` only, so this is fine (it does not require `Hashable`, per the 11.1 note). None of these four import Foundation today and none needs to: the `docs` default lives on the unconstrained extension; the conformance only supplies `documentedKind` (String) + `documentationID` (String).

**DD-3 — `DownbeatResult.detected` payload is `DownbeatEstimate`, NOT `[BeatTimestamp]` (epic drift reconciliation).** The epics.md 11.3b ACs (lines ~1647, ~1667) say `detected([BeatTimestamp])`; the live source is `case detected(estimate: DownbeatEstimate)` (verified in `DownbeatResult.swift:46`). Author `DownbeatResult/detected.md` front-matter as `payload: DownbeatEstimate`, and reconcile the two epics.md lines to `DownbeatEstimate` (develop-only doc fix). The filename is `detected.md` (case identifier, no payload suffix).

**DD-4 — `*Reason.sourceSpecific(String)` docs describe the PATTERN, never a runtime string (Paige #2).** `AbstainReason/sourceSpecific.md` and `DemotionReason/sourceSpecific.md` document the escape-hatch pattern — "a source surfaced a reason that does not fit the typed cases" — NOT any concrete string value. The "When to pick it" paragraph explains when an `MLTechnique` / metadata source / DSP path SHOULD reach for the escape; the "Tradeoff" notes the loss of typed-pattern coverage at the pool layer. Phantom example strings (e.g. `"modelGateRejected"`) MUST NOT appear — they invite future drift. (The real named constants `AbstainReason.mlEvalDeferred` / `.noCandidates` are static-let helpers, not new cases; they may be mentioned as _existing_ examples of the pattern in the library itself, since they are shipped constants, not phantoms.) Front-matter `payload: String` for both.

**DD-5 — `AnalysisIntensity` level docs: honest ComputeBudget framing + the `.default` footgun on level7 (epic AC).** Each `levelN.md`:
- Documents the level's place on the ordinal scale (1 fastest … 10 maximum), what its `techniqueSet` / `windowSizes` / `progressiveThreshold` actually are (from `AnalysisIntensity.swift`), and that levels 1-7 are DSP-only while 8-10 are reserved for future ML and currently behave identically to level 7.
- **ComputeBudget honesty:** `AnalysisIntensity.budget` currently returns `ComputeBudget.default` (all three fractions `1.0`) for EVERY level — the per-source budget dial is a reserved, currently-uniform surface (Story 6.5a inert; proportional budgeting is future work). The level docs MUST NOT invent per-level `dspFraction`/`mlFraction`/`beatGridFraction` values; they state that per-level differentiation today comes from the technique/window/threshold triple, and the budget fractions are reserved and uniform. This satisfies the epic AC ("document the level's tradeoff against the 3 ComputeBudget fractions") truthfully rather than fabricating a gradient.
- **EnsemblePolicy coherence:** note which `EnsemblePolicy` configurations behave coherently at that intensity — at every level `.dspOnly` (the Options default) is coherent; ML-invoking policies (`.default` / `.mlOnly` / `.highestConfidence` / `.weightedVoting`) are coherent but ML-inert unless a technique is wired up, and are conceptually most meaningful at the ML-reserved levels 8-10.
- **`level7.md` footgun (epic AC):** because `level7` is aliased as `AnalysisIntensity.default`, note that `case .default:` in a `switch` matches `.level7` via expression-pattern `~=` (Hashable⇒Equatable) — it is NOT the `default:` label and does NOT establish switch exhaustivity (Story 11.2 DD-8, empirically settled). This is documented, not policed (the planned SwiftLint rule was retired in 11.2).

**DD-6 — Structural validator: a self-contained 11.3b suite mirroring 11.3a's DD-9.** Add `Tests/BoomBoomBoomKitTests/DocumentedCaseAuthoredDocsTests11_3b.swift` — a suite applying the SAME hardened validator (word-boundary failure lexicon, per-case payload presence/absence, wide banned-markup scan, CRLF tolerance, strict filename set, one-lead-occurrence + per-paragraph length, strip proof) to the 25 files + the 5-conformance `.docs`/`documentationID` assertions. Intentional near-duplication of 11.3a's validator (each story's test stays self-contained per the per-story-commit model); Story 11.4 unifies both into the authoritative cross-type validator. `AnalysisIntensity` `.docs` are asserted here too (they were only fallback-tested in 11.2; now they resolve to authored prose). Payload map for 11.3b: `MLExecutionPolicy/whenDSPConfidenceBelow → Double`, `DownbeatResult/detected → DownbeatEstimate`, `AbstainReason/sourceSpecific → String`, `DemotionReason/sourceSpecific → String`.

**DD-7 — No scaffolder / README / template changes.** Those shipped in 11.3a. This story only consumes them.

**DD-8 — Reconcile stale `ComputeBudget.swift` comments (main-bound accuracy fix). [FINALIZED]** `ComputeBudget.swift:13` and `:57` both claim "intensity-proportional budgeting is wired into the pool-authoritative selection in Story 6.5b." That never happened — `AnalysisIntensity.budget` returns `ComputeBudget.default` unconditionally and no production code reads any fraction (Codex confirmed). If the new `levelN.md` docs honestly say the budget is reserved + uniform while the shipped symbol comments say it was wired, they contradict. Amend both comments to state the surface remains reserved (proportional budgeting is future work, no production read consumes the fractions). Source-comment-only; no behavior change.

**DD-9 — Targeted semantic checks + manual-review gates for AC 6/7 (Codex should-fix).** The structural validator (DD-6) is generic and cannot prove semantic truth. Add cheap TARGETED checks where mechanical, and record explicit MANUAL-REVIEW sign-off for the rest:
- `level7.md` MUST mention the `.default` expression-pattern footgun — targeted check: body contains both "default" and one of {"expression pattern", "~=", "exhaustiv"}.
- Each `levelN.md` MUST carry the budget-honesty framing — targeted check: body contains "budget" and one of {"reserved", "uniform", "1.0"}.
- `AbstainReason/sourceSpecific.md` + `DemotionReason/sourceSpecific.md` MUST NOT contain a phantom quoted string value — targeted check: body contains no ASCII double-quote character (the sanctioned real constants `mlEvalDeferred`/`noCandidates` are referenced by name in italics, not as quoted string literals).
- The deeper semantic correctness (config triple accuracy per level, coherent-policy claims) is a MANUAL-REVIEW gate signed off in the code-review record — no generic test can prove it.

## Acceptance Criteria

1. **25 files exist, one per case.** `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md` exists across exactly 25 files: `AnalysisIntensity/` (10: level1…level10), `OctaveEquivalencePolicy/` (3: collapseToFundamental, octaveAwareWithPenalty, exactMatchOnly), `MLExecutionPolicy/` (3: never, always, whenDSPConfidenceBelow), `DownbeatResult/` (3: notAttempted, noneDetected, detected), `AbstainReason/` (4: policyDisabled, inputBelowMinimum, confidenceBelowFloor, sourceSpecific), `DemotionReason/` (2: implausibleForContext, sourceSpecific). Filenames match case identifiers 1:1 (no payload suffix). (DD-2, DD-3)

2. **Three-bold-lead body, failure-mode mandatory, ≤10 KB, 200-400 words, inline-only** — identical to 11.3a AC 2. (DD-1)

3. **Front-matter well-formed; payload only where a case carries one.** `id` == stem == a real case; human-readable `title`; `payload` present for exactly `MLExecutionPolicy/whenDSPConfidenceBelow` (`Double`), `DownbeatResult/detected` (`DownbeatEstimate`), `AbstainReason/sourceSpecific` (`String`), `DemotionReason/sourceSpecific` (`String`) — and absent everywhere else. (DD-2, DD-3, DD-4)

4. **Five enums conform to `DocumentedCase`.** `OctaveEquivalencePolicy` (String-raw: `DocumentedCase` + `public static let documentedKind`). `MLExecutionPolicy`, `DownbeatResult`, `AbstainReason`, `DemotionReason` (each: `DocumentedCase` + `public static let documentedKind` + hand-written `public var documentationID`). `AnalysisIntensity` is already conformed (no edit). Every witness explicitly `public`. Unit-test-locked: `documentationID` for every case equals its filename stem, AND — for the associated-value cases — is payload-invariant, proven with ≥2 distinct payloads (`whenDSPConfidenceBelow(0.1)` vs `(0.9)`; `sourceSpecific("a")` vs `("b")` on both reason enums; two distinct `detected(estimate:)` values). (DD-2)

5. **`.docs` returns authored prose (not fallback) for all 25 cases** — including the 10 `AnalysisIntensity` cases (previously fallback-only). Non-empty, ≠ fallback, and no front-matter token in the render (strip proof). (DD-1, DD-5)

6. **`sourceSpecific` docs describe the pattern, not a runtime string.** `AbstainReason/sourceSpecific.md` and `DemotionReason/sourceSpecific.md` contain no phantom example string as a concrete case value; they document the escape-hatch pattern per DD-4. (DD-4)

7. **`AnalysisIntensity` level docs are budget-honest + level7 footgun.** Each `levelN.md` documents the technique/window/threshold triple truthfully, states the ComputeBudget fractions are reserved and uniform (`ComputeBudget.default` at every level — no fabricated gradient), and cites coherent `EnsemblePolicy` configs. `level7.md` documents the `case .default:` expression-pattern footgun. (DD-5)

8. **epics.md reconciled.** The stale `.detected([BeatTimestamp])` references at `epics.md:981` (Story 8.1 AC) and `epics.md:1667` (Story 11.3b AC) are corrected to `.detected(estimate: DownbeatEstimate)` / `DownbeatEstimate` (develop-only; line 1089 already records the 8.5a enrichment that superseded them). (DD-3)

9. **Structural validator (11.3b suite) passes over all 25 files** — same hardened algorithm as 11.3a (word-boundary lexicon, per-case payload, wide banned-markup, CRLF, strict filename set), with the 11.3b payload map, PLUS the DD-9 targeted semantic checks (level7 footgun phrase, per-level budget-honesty phrase, sourceSpecific no-double-quote). A failure names both file and rule. The non-mechanical semantic claims (per-level config-triple accuracy, coherent-policy accuracy) are signed off as a manual-review gate in the code-review record. (DD-6, DD-9)

10. **49-file corpus total + gates green.** `find Sources/BoomBoomBoomKit/Resources/Documentation -type f -name "*.md" | grep -v '/_' | wc -l` returns **49** (24 from 11.3a + 25 here). `make build`, `make test` (BoomBoomBoomKitTests unit suites), `make fmt` clean, `make lint` 0-serious, `make demo-build` succeed. (all DDs)

## Tasks / Subtasks

- [x] **Task 1 — Conform the five enums.** (AC 4)
  - [x] `OctaveEquivalencePolicy.swift`: `DocumentedCase` + `public static let documentedKind = "OctaveEquivalencePolicy"`.
  - [x] `MLExecutionPolicy.swift`: `DocumentedCase` + `documentedKind` + `public var documentationID` (`never`/`always`/`whenDSPConfidenceBelow`).
  - [x] `DownbeatResult.swift`: `DocumentedCase` + `documentedKind` + `documentationID` (`notAttempted`/`noneDetected`/`detected`).
  - [x] `AbstainReason.swift`: `DocumentedCase` + `documentedKind` + `documentationID` (`policyDisabled`/`inputBelowMinimum`/`confidenceBelowFloor`/`sourceSpecific`).
  - [x] `DemotionReason.swift`: `DocumentedCase` + `documentedKind` + `documentationID` (`implausibleForContext`/`sourceSpecific`).
  - [x] `make build` compiles.
- [x] **Task 2 — Author 10 `AnalysisIntensity` level docs** (DD-5: budget-honest, techniqueSet/windowSizes/progressiveThreshold per level, EnsemblePolicy coherence, level7 footgun). (AC 1, 2, 3, 5, 7)
- [x] **Task 3 — Author 3 `OctaveEquivalencePolicy` docs** (note configurable-but-reserved: MetadataPolicy still governs octave behavior). (AC 1, 2, 3, 5)
- [x] **Task 4 — Author 3 `MLExecutionPolicy` docs** (`whenDSPConfidenceBelow.md` payload: Double; note declared-but-not-yet-Options-wired). (AC 1, 2, 3, 5)
- [x] **Task 5 — Author 3 `DownbeatResult` docs** (`detected.md` payload: DownbeatEstimate; tri-state notAttempted vs noneDetected vs detected). (AC 1, 2, 3, 5)
- [x] **Task 6 — Author 4 `AbstainReason` + 2 `DemotionReason` docs** (`sourceSpecific.md` × 2 = pattern-not-string, payload: String). (AC 1, 2, 3, 5, 6)
- [x] **Task 7 — Reconcile epics.md + ComputeBudget comments.** epics.md:981 + :1667 `detected([BeatTimestamp])` → `DownbeatEstimate` (AC 8). Also amend the stale `ComputeBudget.swift:13`/`:57` comments claiming 6.5b wired proportional budgeting → "reserved, no production read" (DD-8; source-comment-only).
- [x] **Task 8 — Structural validator suite** `DocumentedCaseAuthoredDocsTests11_3b.swift`: the hardened DD-6 validator over 25 files + `.docs`/`documentationID` for the 5 conformances + the payload-invariant ID tests (AC 4 ≥2 payloads) + the DD-9 targeted semantic checks (level7 footgun phrase, per-level budget-honesty phrase, sourceSpecific no-double-quote). (AC 4, 5, 9)
- [x] **Task 9 — Gates.** `make fmt`, `make build`, `make test`, `make lint`, `make demo-build`; confirm 49-count. (AC 10)

## Dev Notes

### Case rosters + payloads (verified against source)

| Type | documentedKind | cases (order) | conformance | payload files |
|---|---|---|---|---|
| AnalysisIntensity | AnalysisIntensity | level1…level10 | already (11.2) | none |
| OctaveEquivalencePolicy | OctaveEquivalencePolicy | collapseToFundamental, octaveAwareWithPenalty, exactMatchOnly | String-raw (add) | none |
| MLExecutionPolicy | MLExecutionPolicy | never, always, whenDSPConfidenceBelow | assoc-value (hand-write) | whenDSPConfidenceBelow → Double |
| DownbeatResult | DownbeatResult | notAttempted, noneDetected, detected | assoc-value (hand-write) | detected → DownbeatEstimate |
| AbstainReason | AbstainReason | policyDisabled, inputBelowMinimum, confidenceBelowFloor, sourceSpecific | assoc-value (hand-write) | sourceSpecific → String |
| DemotionReason | DemotionReason | implausibleForContext, sourceSpecific | assoc-value (hand-write) | sourceSpecific → String |

### Authoritative semantics (from source `///` comments)

- **AnalysisIntensity** (`AnalysisIntensity.swift`): level1 → `TechniqueSet(candidateCount: 1)` + `[15]` window + no progressive retry; level2 → `.baseline` + `[30]`; level3-5 → `.optimal` + `[30]` + no retry; level6 → `.optimal` + `[30,60]` + retry 0.40; level7-10 → `.optimal` + `[30,60,90]` + retry 0.40. Levels 8-10 == level7 DSP-wise (ML reserved). `.budget` = `ComputeBudget.default` (1.0/1.0/1.0) for all (ComputeBudget.swift:53-61).
- **OctaveEquivalencePolicy**: collapseToFundamental (x/2x/x·½ → fundamental), octaveAwareWithPenalty (`.default`; agree with a confidence penalty on the non-fundamental), exactMatchOnly (octave ≠ agreement). Configurable-but-reserved: 6.5b accepts the knob but MetadataPolicy still governs octave behavior.
- **MLExecutionPolicy**: never, always, whenDSPConfidenceBelow(Double) (`.default` = below 0.85). Declared-but-not-yet-Options-wired (forward surface). Threshold finiteness-guarded at consumption.
- **DownbeatResult**: tri-state — notAttempted (never ran), noneDetected (ran, honest negative), detected(estimate: DownbeatEstimate) (ran, produced NaN-free downbeats/meter/confidence/phase). The notAttempted-vs-noneDetected distinction is the point (FR-28).
- **AbstainReason** / **DemotionReason**: why a signal source declined (abstain) or was down-weighted (demote) in the unified pool. sourceSpecific(String) is the typed-escape hatch; the shipped named constants `AbstainReason.mlEvalDeferred` (ML runs post-selection) and `.noCandidates` (empty merged candidates) are real in-library examples of the pattern.

### Out of scope

- Story 11.4 validator (this suite is story-local); Story 11.5 DocC. No scaffolder/README/template change (11.3a shipped them). No behavioral wiring of the reserved policies (`OctaveEquivalencePolicy` / `MLExecutionPolicy` / `ComputeBudget`) — docs describe the current reserved state honestly.

## File List

_Final (dev-story close 2026-07-16):_
- NEW `Resources/Documentation/AnalysisIntensity/{level1…level10}.md` (10)
- NEW `Resources/Documentation/OctaveEquivalencePolicy/{collapseToFundamental,octaveAwareWithPenalty,exactMatchOnly}.md` (3)
- NEW `Resources/Documentation/MLExecutionPolicy/{never,always,whenDSPConfidenceBelow}.md` (3)
- NEW `Resources/Documentation/DownbeatResult/{notAttempted,noneDetected,detected}.md` (3)
- NEW `Resources/Documentation/AbstainReason/{policyDisabled,inputBelowMinimum,confidenceBelowFloor,sourceSpecific}.md` (4)
- NEW `Resources/Documentation/DemotionReason/{implausibleForContext,sourceSpecific}.md` (2)
- EDIT `OctaveEquivalencePolicy.swift`, `MLExecutionPolicy.swift`, `DownbeatResult.swift`, `SignalPool/AbstainReason.swift`, `SignalPool/DemotionReason.swift` (conformance)
- EDIT `_bmad-output/planning-artifacts/epics.md` (DownbeatResult payload reconciliation, lines 981 + 1667)
- EDIT `ComputeBudget.swift` (DD-8: reconcile the stale "wired in 6.5b" comments — source-comment-only)
- NEW `Tests/BoomBoomBoomKitTests/DocumentedCaseAuthoredDocsTests11B.swift` (renamed from `...11_3b` — SwiftLint `type_name` bans underscore)

## Dev Agent Record

### Completion Notes (2026-07-16)

- **All 9 tasks complete; all 10 ACs satisfied.** 25 docs + 5 conformances + epics/ComputeBudget reconcile + validator suite (23 tests).
- **Gates (macOS):** `make build` clean · `make test` **891 tests / 142 suites** (was 868/141; +23 from the 11.3b suite) · `make fmt` no churn · `make lint` **5 violations, 0 serious** (pre-existing Demo; py-lint clean) · `make demo-build` SUCCEEDED (run after the conformances; subsequent changes are doc-prose + source-comment only) · 49-file corpus confirmed.
- **Conformances compile with no `import Foundation`** added to the non-Foundation files (Codex-confirmed: the `docs`/`AttributedString` witness comes from the unconstrained extension).
- **Reused the hardened 11.3a validator** (`typealias Validator = DocumentedCaseAuthoredDocsTests`) so the two stories cannot drift on what "valid" means.

## Code Review (2026-07-16)

Three-layer adversarial review: a **Codex blind-hunter** (thread 019f6d74), an **Acceptance Auditor**, and an **Edge-Case + Factual-Accuracy Hunter** (the DD-9 manual-review gate for the level docs). Outcome: **clean-after-patches → done**. The auditor confirmed no false-completion (all 25 `.docs` genuinely iterated, validator runs all 25 files, payload-invariant tests present with ≥2 payloads). The reviewers verified the per-level DSP config tables, the budget-uniform framing, the 5 conformances, and the `detected`/`sourceSpecific` handling as correct. Patches applied for the real factual defects they surfaced:

- **BLOCKING (Codex) — fictional confidence-gated retry.** level6-10 docs described later windows running "only below confidence 0.40" and confident-wrong results "never triggering retries". Verified against `AudioAnalysisService.swift:1178`: the loop only checks `progressiveThreshold == nil` (levels 1-5 stop after one window); for 6-10 ALL configured windows always run and the `0.40` value is never compared to confidence. Rewrote level6 + level7 (mechanism + Tradeoff) and corrected level8-10 to describe multi-window-always-runs + merge, not a confidence gate.
- **Levels 8-10 "byte-identical to 7" → capped-to-effective-7.** Verified `computeEffectiveIntensity` caps 8-10 to level 7 without a wired `MLTechnique` and records a `degradationReason`, so the effective-intensity/degradation-reason fields differ from a true level-7 request. Reworded.
- **Levels 1-2 "no ML at this depth" → ML not intensity-gated** (invocation is governed by `mlTechnique` + `EnsemblePolicy`, independent of intensity).
- **Levels 3-5 "ML budget tiers" → "intensity-proportional compute budgeting"** (only 8-10 are ML-reserved; the budget reserve is source-general).
- **`always.md`** — "guarantees a model voice" → "guarantees the model is invoked (may still abstain with nil)".
- **`detected.md`** — "four-four unless evidence says otherwise" → "always assumes common time; does not measure meter" (the producer only ever emits `.assumed` 4/4).
- **`noneDetected.md`** — added the stale-cache provenance caveat (a decoded invalid `.detected` normalizes to `.noneDetected`).
- **Both demotion docs** — "reduces weight / softened influence" → "set aside from the decision while the diagnostic confidence is retained" (demotion is a flag, not a graduated weight reduction).
- **level3 superlative** tightened to the source's own "best single technique (+2 tracks)" wording.
- **Accepted-deferred:** the DD-9 targeted checks remain advisory proxies (budget/footgun/no-quote) — the three-reviewer factual pass IS the substantive manual gate; the associated-value roster hand-maintenance is backstopped by Story 11.4's cross-type drift switch.
- **Re-gated:** `make build` · `make test` **891/142** · `make fmt` no churn · `make lint` 5/0-serious.

Pending operator: 1Password-signed commit + push to `rterhaar/11-3` (append to PR #97 changelog).

## Finalization Log (2026-07-16)

Codex spec review (thread 019f6d61) + party-mode. Codex confirmed the spec is fundamentally sound: all 5 conformances compile (String-raw free `documentationID` for `OctaveEquivalencePolicy`; `DocumentedCase` requires only `Sendable` so `MLExecutionPolicy`'s Equatable-not-Hashable is fine; `DownbeatResult`/`AbstainReason`/`DemotionReason` conform WITHOUT `import Foundation` because the `docs`/`AttributedString` witness is supplied by the unconstrained extension where the protocol is declared). `payload: DownbeatEstimate` correct; ComputeBudget "reserved + uniform" honest. Three should-fixes folded:
- **FIN-1** — AC-8 line numbers corrected (`epics.md:981` + `:1667`; `:1647` only lists filenames).
- **FIN-2** — DD-8 added: reconcile `ComputeBudget.swift:13/:57` stale "wired in 6.5b" comments (never wired) so the honest level docs don't contradict shipped symbol docs.
- **FIN-3** — AC-4/6/7 hardened: payload-invariant `documentationID` tested with ≥2 payloads; targeted semantic checks (level7 footgun phrase, per-level budget-honesty phrase, sourceSpecific no-double-quote) + manual-review sign-off for the non-mechanical claims (config-triple accuracy, coherent-policy accuracy).
- xcode semantic-docs cross-check: the conformance-compiles question (no Foundation import needed) is verified empirically at `make build` rather than via an Apple-docs lookup — the relevant contract is our own protocol's extension resolution, which the build confirms.

## Change Log

- 2026-07-16 — create-story draft (bmad-dev-auto, back-to-back with 11.3a).
- 2026-07-16 — Finalized (Codex spec review + party-mode); 3 should-fixes folded; status → ready-for-dev. See Finalization Log.
- 2026-07-16 — Implemented (dev-story): 25 docs + 5 conformances + epics/ComputeBudget reconcile + validator suite. Code-review clean-after-patches (1 blocking factual defect — fictional confidence-gated retry in level6-10 — + several should-fix prose corrections) → done.
