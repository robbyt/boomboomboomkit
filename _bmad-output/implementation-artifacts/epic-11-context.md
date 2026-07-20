# Epic 11 Context: Per-Case Selection-Strategy Docs — Authoring Reference for Stories 11.3a / 11.3b

> Reusable planning-context compiled 2026-07-16 to support authoring Stories 11.3a and 11.3b.
> Sourced from `epics.md` (Epic 11 section + Story 11.1/11.2/11.3a/11.3b ACs), `architecture.md`
> (KDD-E1…E8), the two predecessor implementation artifacts (11.1, 11.2), and a direct grep of the
> live `Sources/BoomBoomBoomKit/` enum declarations. Case names and counts below are verified
> against source, not just the epic prose.

---

## 1. Epic goal + deliverable summary

**Epic 11 — Per-case selection-strategy docs (formerly PRD Epic E; renumbered after the Epic 9 split).**

Every public mode case across nine enums carries authored prose reachable as a typed property
`case.docs: AttributedString`, so Xcode autocomplete surfaces per-case guidance with no string
lookups, no network calls, and no runtime crashes.

The full epic deliverable is a **7-story** build:

- **`DocumentedCase` protocol** (`public protocol DocumentedCase: Sendable`) — one protocol, capped pre-1.0 (KDD-E1).
- **`BoomBoomBoomKitDocs` accessor** — `public enum` namespace, `Mutex<[CacheKey: AttributedString]>`-backed cache with double-checked locking + file I/O outside the lock; a **total function** (non-optional, non-throwing, informative non-empty fallback on any miss). Strips YAML front-matter before markdown parse.
- **The 49-file canonical Markdown docs catalog** at `Sources/BoomBoomBoomKit/Resources/Documentation/<Type>/<case>.md`, shipped in the SPM resource bundle via `.copy` (NOT `.process` — amended by Story 11.1, see KDD-E6 supersession).
- **`DocumentationValidatorTests.swift` + FR-50 drift detection** — Swift Testing suite enforcing per-rule + per-file authoring constraints and failing CI when a `DocumentedCase` ships without a matching `.md`.
- **DocC parallel surface** — `BoomBoomBoomKit.docc/` with a one-way `make docc-transclude` generator (`Cases/` build artifact, `.gitignore`'d) + narrative `Articles/`.

**The catalog count is 49 files** (corrected from "~46" per Paige's 2026-05-26 audit — the original miscount dropped `AbstainReason/` (4) and `DemotionReason/` (2) as separate directories). 24 authored in Story 11.3a + 25 in Story 11.3b = 49.

**FRs covered by Epic 11:** FR-45, FR-46, FR-47, FR-49, FR-50, FR-52.

---

## 2. Story roster with status

| Story | Scope | Status |
|---|---|---|
| **11.1** | `DocumentedCase` protocol + `BoomBoomBoomKitDocs` accessor + `Mutex` cache + `.copy` SPM wiring + front-matter stripping | **done** (853 tests green; landed on `rterhaar/epic-11`) |
| **11.2** | `AnalysisIntensity` struct→enum reshape (10-level `String` enum) + `DocumentedCase` conformance + `ComputeBudget` carry-forward; reserves `Documentation/AnalysisIntensity/.gitkeep` | **done** (855 tests green) |
| **11.3a** | Author 24 canonical `.md` files: `BPMSelectionPolicy` (8) + `VotingPolicy` (3) + `EnsemblePolicy` (5) + `DSPTechnique` (8); conform those 4 enums to `DocumentedCase`; ship `_template.md` + `make new-case` scaffolder | **backlog — THIS work** |
| **11.3b** | Author 25 canonical `.md` files: `AnalysisIntensity` (10) + `OctaveEquivalencePolicy` (3) + `MLExecutionPolicy` (3) + `DownbeatResult` (3) + `AbstainReason` (4) + `DemotionReason` (2); conform the not-yet-conformed enums | **backlog — THIS work** |
| **11.4** | `DocumentationValidatorTests.swift` + FR-50 drift detection. Hard dep: 11.3a AND 11.3b both merged to develop first | remaining |
| **11.5** | DocC catalog + `make docc-transclude` generator + `Articles/` | remaining |
| **11.6** | Demo strategy popovers wired to the authored docs (FR-42 — deferred from the reverted Story 10.5). Demo-only | remaining |

---

## 3. Story 11.3a exact scope — 24 files, 4 enums

All four enums are `String`-raw `CaseIterable` enums, so each gets `documentationID` **free** from the
constrained `RawRepresentable where RawValue == String` extension. **None of the four currently conforms
to `DocumentedCase` — 11.3a must add the conformance** (add `DocumentedCase` to the inheritance list +
`static let documentedKind = "<Type>"`; `documentationID` and `docs` are inherited). Filename = case
identifier + `.md`, one file per case.

**`BPMSelectionPolicy` (8 cases)** — `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift:19` — NOT yet DocumentedCase:
`maxConfidence`, `dedup`, `quorum`, `average`, `median`, `weightedAverage`, `union`, `windowVoting`

**`VotingPolicy` (3 cases)** — `Sources/BoomBoomBoomKit/VotingPolicy.swift:23` — NOT yet DocumentedCase:
`simpleMajority`, `confidenceWeighted`, `thresholdGated`

**`EnsemblePolicy` (5 cases)** — `Sources/BoomBoomBoomKit/EnsemblePolicy.swift:66` — NOT yet DocumentedCase.
This enum is `Sendable, Hashable` but **NOT `String`/`CaseIterable`** because `.weightedVoting` carries an
associated value — so it must provide `documentationID` via a hand-written `switch` (mirror the existing
`stableKey` switch at `EnsemblePolicy.swift:139`). Cases (note `default` is a backticked keyword case):
`` `default` ``, `dspOnly`, `mlOnly`, `highestConfidence`, `weightedVoting(SignalWeights)`
— file `weightedVoting.md` carries `payload: SignalWeights` in front-matter; filename has NO payload suffix.

**`DSPTechnique` (8 cases)** — `Sources/BoomBoomBoomKit/DSPTechnique.swift:19` — NOT yet DocumentedCase:
`acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`,
`subBandVoting`, `clickTrackCorrelation`, `superFluxOnset`

11.3a also ships `Resources/Documentation/_template.md` (the `{{TYPE}}`/`{{CASE}}` scaffolder template) and
the `make new-case TYPE=… CASE=…` Makefile target (reads `_template.md`, refuses to overwrite, does NOT
validate against Swift source — fail-late through 11.4's validator). Also ships/points to
`Sources/BoomBoomBoomKit/Resources/README.md` documenting the no-tables/no-code restriction and pointing to
`BoomBoomBoomKit.docc/Articles/SelectionStrategies.md` as the home for richer treatments.

---

## 4. Story 11.3b exact scope — 25 files, 6 enums

**`AnalysisIntensity` (10 cases)** — `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — **ALREADY conformed
to `DocumentedCase` in Story 11.2** (`documentedKind = "AnalysisIntensity"`; String-raw so `documentationID
== rawValue`). Directory `Documentation/AnalysisIntensity/.gitkeep` already reserved. 11.3b only authors prose.
Files: `level1.md` … `level10.md` (raw values `"level1"…"level10"`). `level7` is aliased `.default`,
`level1 = .fastest`, `level8 = .thorough`, `level10 = .maximum`. Each level file documents the tradeoff
against the 3 `ComputeBudget` fractions (`dspFraction`/`mlFraction`/`beatGridFraction`) and which
`EnsemblePolicy` configs behave coherently at that intensity.

**`OctaveEquivalencePolicy` (3 cases)** — `Sources/BoomBoomBoomKit/OctaveEquivalencePolicy.swift:16` — NOT yet
DocumentedCase (String-raw, `documentationID` free):
`collapseToFundamental`, `octaveAwareWithPenalty`, `exactMatchOnly`

**`MLExecutionPolicy` (3 cases)** — `Sources/BoomBoomBoomKit/MLExecutionPolicy.swift:23` — NOT yet
DocumentedCase. `Sendable, Equatable` (deliberately NOT `Hashable` — NaN-bearing `Double` payload; this is
exactly why 11.1 dropped `Hashable` from the `DocumentedCase` bound). Associated-value enum → hand-written
`documentationID` switch:
`never`, `always`, `whenDSPConfidenceBelow(Double)` — file `whenDSPConfidenceBelow.md`, `payload: Double`.

**`DownbeatResult` (3 cases)** — `Sources/BoomBoomBoomKit/DownbeatResult.swift:34` — NOT yet DocumentedCase.
`Sendable, Hashable, Codable, CustomStringConvertible`; associated-value enum → hand-written
`documentationID`. Cases: `notAttempted`, `noneDetected`, `detected(estimate: DownbeatEstimate)`.
Files: `notAttempted.md`, `noneDetected.md`, `detected.md`.
> DISCREPANCY TO RESOLVE IN AUTHORING: the 11.3b AC lists the payload for `detected` as `[BeatTimestamp]`,
> but the live source case is `detected(estimate: DownbeatEstimate)`. Author the front-matter `payload:`
> against the real source type (`DownbeatEstimate`), and flag the epic-text drift.

**`AbstainReason` (4 cases)** — `Sources/BoomBoomBoomKit/SignalPool/AbstainReason.swift:8` — NOT yet
DocumentedCase. `Sendable, Equatable, Codable`; associated-value enum → hand-written `documentationID`:
`policyDisabled`, `inputBelowMinimum`, `confidenceBelowFloor`, `sourceSpecific(String)`
— file `sourceSpecific.md`, `payload: String`. Document the *pattern* (escape hatch), NOT any concrete
runtime string; phantom strings like `"modelGateRejected"` MUST NOT appear.

**`DemotionReason` (2 cases)** — `Sources/BoomBoomBoomKit/SignalPool/DemotionReason.swift:8` — NOT yet
DocumentedCase. `Sendable, Equatable, Codable`; associated-value enum → hand-written `documentationID`:
`implausibleForContext`, `sourceSpecific(String)` — file `sourceSpecific.md`, `payload: String`.

> The two `sourceSpecific.md` files live in SEPARATE directories (`AbstainReason/` vs `DemotionReason/`) —
> this same-basename collision is the exact reason Story 11.1 switched SPM from `.process` to `.copy`
> (`.process` flattens and collides them).

**Corpus close-out check (11.3b AC):** after 11.3a + 11.3b,
`find Sources/BoomBoomBoomKit/Resources/Documentation -type f -name "*.md" | grep -v '^.*/_' | wc -l`
must return **49** (the leading-underscore exclusion drops `_template.md` and the `_Fixture/` sentinels).

---

## 5. The doc-authoring contract, verbatim (KDD-E7 + KDD-E8)

### 5a. Front-matter (KDD-E7) — mandatory YAML block, verbatim from architecture.md

> **KDD-E7 — Front-matter YAML schema. Decision:** Minimal 2-field schema with optional payload tag (Paige's trim).
> ```yaml
> ---
> id: maxConfidence                     # case name (required)
> title: Highest-confidence selection   # human-readable (required)
> payload: Double                       # optional — present for associated-value cases (e.g., MLExecutionPolicy.whenDSPConfidenceBelow)
> ---
> ```
> **Trimmed from earlier draft:**
> - `kind` field — derivable from parent directory (`Resources/Documentation/<Type>/<case>.md`). Redundant.
> - `version: 1` field — YAGNI until the schema actually breaks. Reintroduce only when a breaking schema change requires per-file versioning.
>
> **Filenames match the Swift case identifier 1:1 — no associated-value suffix.** `whenDSPConfidenceBelow.md`, not `whenDSPConfidenceBelow_threshold.md`. Authors document the *pattern* the case represents, not the specific payload value. The `payload:` front-matter field carries the type-level hint for cases that have one.

Required fields: **`id:`** (must equal the Swift case identifier AND the filename stem) and **`title:`**
(human-readable phrase). **`payload:`** is optional, present only for associated-value cases. The
`---`-delimited block is tooling/validator input — the accessor STRIPS it before rendering (Story 11.1
`strippingFrontMatter(_:)`), so it never appears in `.docs` prose.

### 5b. Prose style + limits (KDD-E8), verbatim from architecture.md authoring style guide

> **Authoring style guide:**
> - 10 KB per-file ceiling (codified in step-03)
> - 200-400 words per case (Paige #2)
> - Three bold-lead paragraphs structure: `**What it does.**` / `**When to pick it.**` / `**Tradeoff.**`
> - No tables, no fenced code blocks, no images, no DocC `<doc:...>` symbol links, no heading hierarchy
> - Comparison matrices live in DocC catalog articles, NOT per-case runtime docs (per-case docs are local explanations, not survey articles)

And the epics.md Story 11.3a/11.3b AC language, verbatim:

> **When** any case file is read, **Then** the body contains exactly three paragraphs led by
> `**What it does.**`, `**When to pick it.**`, and `**Tradeoff.**` in that order; total prose length
> between 200 and 400 words; file size at most 10 KB. **The "Tradeoff" paragraph MUST include at least one
> concrete failure-mode sentence** (Paige #3, Option A) — e.g., `Tradeoff. Picks the loudest candidate —
> fails on DnB tracks where octave-doubled candidates self-report higher confidence than the fundamental.`

**Banned elements** (KDD-E8, validator-enforced in 11.4): fenced code blocks (```` ``` ````), tables
(`| col | col |`), images (`![alt](url)`), DocC symbol links (`<doc:SomeSymbol>` and backtick-style symbol
links that render as literal text), heading hierarchy (no H1/H2/H3 — nothing beyond `AttributedString`
tolerance). Inline `**bold**` and `_italic_` ONLY. The render constraint is hard: files parse through
`AttributedString(markdown: …, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))`, and
that inline-only mode is *why* the block-element bans exist — it is the render path's constraint, not a
style preference.

**Numbers to hold:** three bold-lead paragraphs in the fixed order What/When/Tradeoff; the Tradeoff
paragraph carries ≥1 concrete failure-mode sentence; 200–400 words per case; 10 KB per-file ceiling.

---

## 6. Where doc files live + the `<kind>` directory name per enum

Tree: `Sources/BoomBoomBoomKit/Resources/Documentation/<kind>/<id>.md`

`<kind>` = the enum's `documentedKind` static value = the enum type name; `<id>` = the case identifier
(= `documentationID` = filename stem). The whole `Resources/Documentation/` tree is wired into the bundle
via `resources: [.copy("Resources/Documentation")]` (already in `Package.swift` from 11.1) — adding new
`<kind>/` subdirectories needs NO `Package.swift` change. Accessor resolves via
`Bundle.module.url(forResource: id, withExtension: "md", subdirectory: "Documentation/\(kind)")`.

Currently existing under `Resources/Documentation/`: `_Fixture/` (11.1 sentinels) and `AnalysisIntensity/`
(11.2 `.gitkeep`, no prose). All other `<kind>/` directories are created by 11.3a/11.3b.

`documentedKind` directory name per enum: `BPMSelectionPolicy`, `VotingPolicy`, `EnsemblePolicy`,
`DSPTechnique`, `AnalysisIntensity`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `DownbeatResult`,
`AbstainReason`, `DemotionReason` (each equals its Swift type name).

---

## 7. FR + KDD IDs cited by Epic 11 / Stories 11.3a / 11.3b

**Functional Requirements (Epic 11):**
- **FR-45** — Per-case help via typed property access (`case.docs: AttributedString`); Xcode autocomplete, no string lookups.
- **FR-46** — Help renders offline; docs ship in the SPM resource bundle, no network. (Cited by 11.3a/11.3b.)
- **FR-47** — Help explains what AND why; each case carries prose covering what the option does AND why to choose it. (Cited by 11.3a/11.3b.)
- **FR-49** — Informative non-optional, non-throwing fallback when docs missing; never empty, never crash. (Delivered by 11.1's accessor.)
- **FR-50** — New documented cases cannot ship without docs; drift detection via exhaustive `switch` over `CaseIterable` at test time. (11.3b's authored corpus makes the surface drift-detection-ready; enforced in 11.4.)
- **FR-52** — Documentation bundles with the library binary; no runtime/CDN/dynamic loading. (Cited by 11.3a/11.3b.)

**KDDs (architecture.md, Epic E):**
- **KDD-E1** — Protocol family cap: one protocol (`DocumentedCase`) pre-1.0; metadata lives in YAML front-matter, not sibling protocols.
- **KDD-E2** — Protocol shape: per-instance `var docs: AttributedString` computed property; default impl reads `Bundle.module`.
- **KDD-E3** — `documentationID` derivation: raw-value default for `RawRepresentable where RawValue == String`; explicit `switch` for associated-value enums.
- **KDD-E4** — `AnalysisIntensity` reshape to a 10-level enum with static-let aliases (delivered by 11.2; the `case .default:` SwiftLint-rule premise was empirically DISPROVEN and the rule RETIRED).
- **KDD-E5** — Cache primitive: `Mutex<[CacheKey: AttributedString]>` + double-checked locking, I/O outside the lock (delivered by 11.1).
- **KDD-E6** — SPM resource rule: originally `.process`; **AMENDED to `.copy` by Story 11.1** (preserves the `Documentation/<Type>/` subdir structure and avoids the `sourceSpecific.md` collision). Carry `.copy` forward.
- **KDD-E7** — Front-matter YAML schema (the `id:`/`title:`/optional `payload:` block) + filename-matches-Swift-identifier 1:1 rule. **Primary contract for 11.3a/11.3b.**
- **KDD-E8** — DocC + runtime Markdown as parallel surfaces, one-way transclude; carries the authoring style guide (three bold-leads, 200-400 words, 10 KB, banned elements). **Primary contract for 11.3a/11.3b.**

---

## 8. Predecessor continuity — the DocumentedCase mechanism (from 11.1)

**Protocol shape as shipped (11.1, `Sources/BoomBoomBoomKit/DocumentedCase.swift`):**
```
public protocol DocumentedCase: Sendable {          // NOTE: Hashable DROPPED in 11.1 review pass 1
    static var documentedKind: String { get }
    var documentationID: String { get }
    var docs: AttributedString { get }
}
```
`Hashable` was removed from the bound (was `Sendable, Hashable` in the epic) — the cache keys on an internal
`(kind, id)` `CacheKey`, never on `Self`, and `Hashable` would have excluded `MLExecutionPolicy`'s
checked-in `Sendable, Equatable` (deliberately non-`Hashable`, NaN-bearing `Double`). This matters directly
for 11.3b: `MLExecutionPolicy`, `AbstainReason`, `DemotionReason`, `DownbeatResult` all conform without
needing `Hashable` on the protocol.

**Two separate extensions (deliberately split — a refactor merging them would silently strip `docs` from
associated-value conformers):**
1. UNCONSTRAINED extension on `DocumentedCase` → default `docs` = `BoomBoomBoomKitDocs.attributedString(for: Self.documentedKind, id: documentationID)`.
2. CONSTRAINED extension `where Self: RawRepresentable, Self.RawValue == String` → `documentationID { rawValue }`.

**How each conformer derives `documentationID`:**
- **String-raw enums** (`BPMSelectionPolicy`, `VotingPolicy`, `DSPTechnique`, `AnalysisIntensity`,
  `OctaveEquivalencePolicy`) get `documentationID` FREE (= `rawValue`). Only need `+ DocumentedCase` on the
  inheritance list and `static let documentedKind`.
- **Associated-value enums** (`EnsemblePolicy`, `MLExecutionPolicy`, `DownbeatResult`, `AbstainReason`,
  `DemotionReason`) block raw-value synthesis, so they hand-write `var documentationID: String { switch self … }`
  returning the case identifier (no payload suffix). Precedent for the switch shape: `EnsemblePolicy.stableKey`
  at `EnsemblePolicy.swift:139`.

**Accessor front-matter-stripping behavior (11.1, `BoomBoomBoomKitDocs.swift`):** the accessor reads raw
text (`String(contentsOf:encoding:)`), strips a leading `---`…`---` block via `strippingFrontMatter(_:)`,
THEN parses `AttributedString(markdown: …, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))`.
An unterminated/absent front-matter block leaves text untouched (that's a 11.4-validator concern; the
accessor stays total). A parse that succeeds but is blank (zero-length OR all-whitespace) is treated as a
MISS → fallback. Malformed `kind`/`id` (empty, contains `/` or `..`) → straight to fallback. Fallback string:
`"Documentation unavailable for <kind>.<id>."` (never empty, never nil, never throws — FR-49). The cache is
`Mutex`-guarded with I/O outside the lock and double-checked insertion; the fallback is negative-cached.

**Consequence for authoring:** because `.docs` is total, a case with no `.md` yet silently returns the
fallback — so 11.3a/11.3b authoring correctness is NOT proven by a green build; it is proven by 11.4's
drift-detection validator (which asserts every case resolves to a NON-fallback value). Author carefully and
run the file-count + a manual `.docs` spot-check.

---

## 9. Per-enum authoring table (name / documentedKind dir / cases in order / already-conformed?)

| Enum | `documentedKind` dir | Cases (source order) | Files | Already `DocumentedCase`? |
|---|---|---|---|---|
| **BPMSelectionPolicy** | `BPMSelectionPolicy/` | `maxConfidence`, `dedup`, `quorum`, `average`, `median`, `weightedAverage`, `union`, `windowVoting` | 8 | **No** — conform in 11.3a (String-raw, free ID) |
| **VotingPolicy** | `VotingPolicy/` | `simpleMajority`, `confidenceWeighted`, `thresholdGated` | 3 | **No** — conform in 11.3a (String-raw, free ID) |
| **EnsemblePolicy** | `EnsemblePolicy/` | `` `default` ``, `dspOnly`, `mlOnly`, `highestConfidence`, `weightedVoting(SignalWeights)` | 5 | **No** — conform in 11.3a (assoc-value → manual `documentationID` switch; `weightedVoting.md` has `payload: SignalWeights`) |
| **DSPTechnique** | `DSPTechnique/` | `acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`, `subBandVoting`, `clickTrackCorrelation`, `superFluxOnset` | 8 | **No** — conform in 11.3a (String-raw, free ID) |
| **AnalysisIntensity** | `AnalysisIntensity/` | `level1`, `level2`, `level3`, `level4`, `level5`, `level6`, `level7`, `level8`, `level9`, `level10` | 10 | **YES** — conformed in 11.2 (String-raw); 11.3b authors prose only. Dir `.gitkeep` already exists |
| **OctaveEquivalencePolicy** | `OctaveEquivalencePolicy/` | `collapseToFundamental`, `octaveAwareWithPenalty`, `exactMatchOnly` | 3 | **No** — conform in 11.3b (String-raw, free ID) |
| **MLExecutionPolicy** | `MLExecutionPolicy/` | `never`, `always`, `whenDSPConfidenceBelow(Double)` | 3 | **No** — conform in 11.3b (assoc-value → manual switch; `whenDSPConfidenceBelow.md` has `payload: Double`; enum is non-`Hashable`) |
| **DownbeatResult** | `DownbeatResult/` | `notAttempted`, `noneDetected`, `detected(estimate: DownbeatEstimate)` | 3 | **No** — conform in 11.3b (assoc-value → manual switch; `detected.md` payload = `DownbeatEstimate` per source, NOT `[BeatTimestamp]` as the epic AC says) |
| **AbstainReason** | `AbstainReason/` | `policyDisabled`, `inputBelowMinimum`, `confidenceBelowFloor`, `sourceSpecific(String)` | 4 | **No** — conform in 11.3b (assoc-value → manual switch; `sourceSpecific.md` has `payload: String`, document the pattern not a value) |
| **DemotionReason** | `DemotionReason/` | `implausibleForContext`, `sourceSpecific(String)` | 2 | **No** — conform in 11.3b (assoc-value → manual switch; `sourceSpecific.md` has `payload: String`) |

**Totals:** 11.3a = 8+3+5+8 = **24 files** across 4 enums. 11.3b = 10+3+3+3+4+2 = **25 files** across 6 enums.
Combined = **49 files** (the `grep -v '/_'` count excludes `_template.md` + `_Fixture/`).
