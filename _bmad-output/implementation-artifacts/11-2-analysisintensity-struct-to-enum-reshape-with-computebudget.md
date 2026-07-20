# Story 11.2: AnalysisIntensity struct-to-enum reshape with ComputeBudget bundling

Status: done

<!-- bmad-dev-auto metadata -->
<!-- baseline_revision: create-story v1 (2026-07-16) -->
<!-- baseline_commit: 9a9fa73efa2b36c231df589c7bf2e3ceeb60b72c -->
<!-- review_loop_iteration: 0 -->
<!-- finalized: 2026-07-16 — Codex review + xcode-mcp empirical DD-8 check + party-mode ratification folded in (see Finalization Log at end) -->

> **Finalized 2026-07-16** via Codex review + an empirical `swift` compile (DD-8) + party-mode. Three ratified changes vs the create-story draft: (1) **DD-8 SwiftLint rule DROPPED** — `case .default:` empirically compiles and matches `.level7` via `~=`, so KDD-E4's footgun premise is false, and a blanket regex would false-positive `EnsemblePolicy.default`; (2) **DD-3 keeps `Comparable`** (authorized addition — intensity is a documented ordinal scale); (3) **DD-2 call sites clamp to `1...10` before `init?(level:)`** (no silent level-7 substitution). Plus Codex should-fixes: full-repo `.rawValue` audit, canonical `.level<n>` codegen, order-locking tests. See Finalization Log.

## Story

As a **library consumer choosing analysis intensity**,
I want **`AnalysisIntensity` to be a finite `String`-backed enum with documented per-level cases**,
so that **I can exhaustively `switch` on intensity levels, Xcode autocomplete surfaces per-level guidance, and out-of-range intensities become unrepresentable**.

This is a **pre-1.0 breaking change** (NFR-4 authorized): `AnalysisIntensity` changes from a `struct` wrapping `Int rawValue` to a `10-case String enum`. It removes `init(rawValue: Int)`, `rawValue: Int`, `Comparable`, and `ExpressibleByIntegerLiteral`. The reshape must preserve **every per-level behavior byte-for-byte** (technique set, window sizes, progressive threshold) — the corpus accuracy floors are the regression net.

## Key Design Decisions

> The DD block is the surface the pre-implementation Codex review and party-mode finalize walk first. DD-8 is the crux and is deliberately left with an empirical gate (xcode MCP) rather than a hard-coded answer.

**DD-1 — Numeric ordinal accessor `var level: Int` (ADD).** After the reshape, `rawValue` is the `String` `"level7"`, not `7`. Every numeric consumer of the old `Int` rawValue (the DSP-cap comparison + log message in `AudioAnalysisService`, the `Int` fields in `TraceExport`, the Demo slider/label) migrates to a new `public var level: Int` computed by `switch self`. Rationale: preserves the ordinal-number view the struct's `rawValue: Int` provided; single source for the 1...10 number; keeps `rawValue` free to be the doc-filename stem (`"level7"` → `level7.md`).

**DD-2 — Int→case construction bridge `init?(level: Int)` (ADD, failable). [FINALIZED]** The old `init(rawValue: Int)` clamped `1...10`; the enum removes it. Two runtime *constructor* sites build an intensity from a dynamic `Int` (the Demo slider, the develop-only CLI `tony-dsp-prepass`); the Demo codegen is a *source-generation* site, not a runtime constructor (it emits Swift text — see DD-1a). Add `public init?(level: Int)` returning `nil` outside `1...10`. **Ratified migration (party-mode):** each call site **clamps its `Int` to `1...10` before** calling `init?(level:)`, so `nil` is structurally unreachable — a `?? .default` fallback is retained only as a dead-but-lint-clean belt. This closes the Codex trap where `AnalysisIntensity(level: 0 or 11) ?? .default` would *silently* substitute level 7 for an out-of-range UI/CLI regression. The Demo slider (bound `1.0...10.0`) and CLI (already clamps its parsed arg) both pre-bound their input; the added clamp makes the invariant explicit at the boundary. **Alternative considered + rejected:** a clamping `init(clampingLevel:)` — the failable init is the honest public shape (nil-on-invalid); clamping belongs at the caller, not baked into the type.

**DD-1a — Demo codegen emits canonical `.level<n>` (ADD). [FINALIZED]** `AnalysisViewModel`'s code-generation path currently emits `AnalysisIntensity(rawValue: N)` (and aliases for 1/7/8/10). Post-reshape it emits the canonical case literal `.level\(n)` for **all ten** levels (one uniform shape, not a mix of aliases + constructors). Smoke-test fixtures update to match.

**DD-3 — KEEP `Comparable` (authorized addition beyond KDD-E4's minimal list). [FINALIZED]** KDD-E4 lists `String, CaseIterable, Sendable, Hashable` as a *minimum*, not a prohibition. `AnalysisIntensity` is a documented **ordinal** scale ("higher numbers never decrease accuracy"), so `Comparable` is semantically correct and honest against the docs. Add `Comparable` via `public static func < (lhs, rhs) -> Bool { lhs.level < rhs.level }`. The one production comparison (`AudioAnalysisService.swift:673`, DSP-cap gate) then reads `requested <= dspOnlyMaxIntensity` directly; the three ordering test lines keep `<`/`>=` unchanged. Party-mode authorized this as an addition beyond the KDD-E4 list (recorded in the Finalization Log); the CLAUDE.md `Hashable`-invariant roster gains `AnalysisIntensity` under the enum form (it was already `Hashable` as a struct).

**DD-4 — Drop `ExpressibleByIntegerLiteral`.** `let x: AnalysisIntensity = 7` no longer compiles; not in KDD-E4's conformance list. The only two literal sites tested out-of-range clamping (see DD-5) and are obsolete. Any legitimate literal use migrates to `.levelN` / the named alias.

**DD-5 — Out-of-range/clamp tests become obsolete (a correctness win).** The enum makes out-of-range intensities unrepresentable. Delete the `BPMAnalyzerTests` clamp assertions (`rawValue: 0 / -5 / 15 / 100`, `= 42`, `= 0`) and replace with an `allCases.count == 10` invariant + a `level` round-trip test (`init?(level:)` ↔ `.level`).

**DD-6 — Computed properties rewrite `switch rawValue` → `switch self`, values BYTE-IDENTICAL.** `techniqueSet` / `windowSizes` / `progressiveThreshold` keep the exact same output per level: `level1 → TechniqueSet(candidateCount: 1)`; `level2 → .baseline`; `level3…level10 → .optimal`; `windowSizes` `level1 → [15]`, `level2…level5 → [30]`, `level6 → [30, 60]`, `level7…level10 → [30, 60, 90]`; `progressiveThreshold` `nil` for `level1…level5`, `0.40` for `level6…level10`. This is the **critical correctness anchor** — the reshape must not change any per-level behavior. The **proof** is a direct per-level value-equality test over all ten levels' three properties; the four unconditional corpus floors are the **regression net** (they permit output changes above threshold, so they are not a byte-identity proof — the value table is). Also add a focused test that levels 8–10 resolve identically to level 7 (`.optimal` / `[30,60,90]` / `0.40`, no ML).

**DD-7 — `DocumentedCase` conformance + reserve the directory ONLY (no prose).** Add `DocumentedCase` with `static let documentedKind = "AnalysisIntensity"`. Because it is `String`-raw, `documentationID` comes free from the constrained extension (`= rawValue = "level7"`). Create `Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/.gitkeep` to reserve the directory; the ten `.md` files are authored in **Story 11.3b**, not here. Ship a conformance smoke test asserting `.docs` returns a non-empty fallback for every case (real prose is out of scope).

**DD-8 — DROP the custom SwiftLint rule `analysis_intensity_default_case`. [FINALIZED — empirically settled]** KDD-E4's premise is **false**, confirmed by a direct `swift` compile (2026-07-16): given a `String` enum with `static let \`default\` = .level7`, `switch value { case .default: … }` **compiles and matches `.level7`** via expression-pattern `~=` (works because `Hashable` implies `Equatable`) — it is *not* parsed as the bare `default:` label. Two facts follow:
- **The footgun does not exist**, so the rule has no justification. (One real nuance to document, not police: an expression pattern does **not** establish enum exhaustivity — a switch containing only `case .default:` still needs the other cases or a real `default:` — and `case .default:` must precede any real `default:` block.)
- **A blanket `case .default:` regex would false-positive on `EnsemblePolicy.default`** — a genuine enum case where `case .default:` is correct and already used in-tree (`EnsemblePolicy.swift`, `AudioAnalysisService.swift`, demo, tests). Regex can't see the switched type, and path-exclusion can't separate the two types (both switched in overlapping files).

**Resolution:** do **not** add the rule, `custom_rules:`, or the `LintFixtures/` fixtures. Amend the upstream docs (KDD-E4, epics AC, architecture footgun table, the "SwiftLint custom rule (new)" line) with a supersession note recording the corrected claim. `make lint` stays green with no new rule. This *removes* scope from the epics AC (the SwiftLint-rule acceptance criterion is retired).

**DD-9 — ComputeBudget "bundling" is a carry-forward, not new wiring (reality check).** `ComputeBudget` and `AnalysisIntensity.budget` already shipped inert in Story 6.5a (`Sources/BoomBoomBoomKit/ComputeBudget.swift:53-61`, every level → `ComputeBudget.default`). The epics AC framing ("the budget semantic migration ships in the same PR") is already satisfied by the existing extension: it uses `.default` (not `rawValue`), so it compiles unchanged post-reshape. Story 11.2 **preserves** the extension and verifies it still resolves; it does **not** add proportional budgeting (that remains 6.5b/future scope). The epics "pressure-release valve" (if ComputeBudget slips, ship reshape alone) is therefore moot — the budget surface is already present.

## Acceptance Criteria

1. **Enum redeclaration.** `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` declares `public enum AnalysisIntensity: String, CaseIterable, Sendable, Hashable, Comparable, DocumentedCase` with cases `level1` through `level10` (raw values `"level1"…"level10"`), `static let documentedKind = "AnalysisIntensity"`, and `public static func < (lhs, rhs) -> Bool { lhs.level < rhs.level }`. Unit-test-locked: `AnalysisIntensity.allCases.count == 10` AND `AnalysisIntensity.allCases.map(\.level) == Array(1...10)` (order lock) AND `allCases.map(\.documentationID) == allCases.map(\.rawValue)` (== `"level1"…"level10"`, so 11.3b filenames can't drift). (DD-1, DD-3, DD-7)

2. **Named-constant aliases source-compatible.** An extension declares `public static let fastest: AnalysisIntensity = .level1`, `public static let default: AnalysisIntensity = .level7`, `public static let thorough: AnalysisIntensity = .level8`, `public static let maximum: AnalysisIntensity = .level10`. Every existing `.fastest`/`.default`/`.thorough`/`.maximum` call site compiles unchanged. (DD-2 aliases)

3. **Ordinal accessor + Int bridge.** `public var level: Int` returns `1…10` per case; `public init?(level: Int)` returns the matching case for `1…10` and `nil` otherwise; `AnalysisIntensity(level: n)?.level == n` for all `n in 1...10` and `AnalysisIntensity(level: n) == nil` for `n ∉ 1...10`. (DD-1, DD-2)

4. **Per-level behavior byte-identical.** `techniqueSet`, `windowSizes`, `progressiveThreshold` return exactly the pre-reshape value for every level (per the DD-6 table). A value-equality test asserts each of the 10 levels' three properties against the documented expected values, and the four corpus floors (`make benchmark` OA300 Acc1 ≥ 57/82 + Acc2 ≥ 73/82; `make benchmark-giantsteps` Acc1 ≥ 537/661 + Acc2 ≥ 546/661) hold. (DD-6)

5. **All call sites compile and behave — verified by a full-repo `.rawValue` audit, NOT by a green build.** Because the enum's `rawValue` is `String`, every `"\(intensity.rawValue)"` still *compiles* while silently changing `7` → `"level7"`; a build-green gate proves nothing. The dev agent audits every `AnalysisIntensity`-related `.rawValue` across `Sources/`, `Tests/`, `Demo/`, and `_bmad-output/ml-training/swift_feature_extractor/`, classifying each as intentionally-the-doc-string or migrate-to-`.level`. Known numeric readers to migrate (from the Explore sweep + Codex): `AudioAnalysisService:673` cap → `requested <= dspOnlyMaxIntensity` (via `Comparable`), `:688-689` log → `.level`; `SignalPoolTests` `.rawValue` interpolations (~198/203); `AnalysisViewModel.formatResultRow` `effectiveIntensity.rawValue` → `.level`; `TraceView`/`TraceExport` Int fields → `.level`; `AudioAnalysisServiceTests` `init(rawValue:)` constructions + `effectiveIntensity.rawValue` assertions; benchmark reporters passing `.rawValue` into `Int` params. Runtime constructors migrate to clamp-then-`init?(level:) ?? .default` (DD-2); Demo codegen emits `.level\(n)` (DD-1a). `make build`, `make test`, `make demo-build`, and `swift run` in the feature-extractor package all succeed. (DD-1, DD-1a, DD-2, DD-3, DD-4)

6. **DocumentedCase directory reserved.** `Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/.gitkeep` exists; no `levelN.md` prose is authored (that is Story 11.3b). A smoke test asserts `AnalysisIntensity.level7.docs` (and every case's `.docs`) is non-empty (fallback). (DD-7)

7. **No SwiftLint rule (dropped) + upstream docs amended.** Per DD-8 (empirically settled), the `analysis_intensity_default_case` rule is NOT added — no `custom_rules:`, no `LintFixtures/`. Instead, KDD-E4, the epics AC, the architecture footgun table (line ~878), and the "SwiftLint custom rule (new)" line (architecture ~909; epics ~181) receive a supersession note correcting the false premise (`.default` is a valid expression pattern that does not establish exhaustivity). `make lint` stays green. (DD-8)

8. **ComputeBudget preserved.** `AnalysisIntensity.budget` resolves to `ComputeBudget.default` for **every** case — the budget test iterates `AnalysisIntensity.allCases` (not just `.fastest`/`.maximum`). `Sources/BoomBoomBoomKit/ComputeBudget.swift` requires no edit (verify, don't assume). (DD-9)

9. **Value-equality proof.** A test asserts each of the ten levels' `techniqueSet` / `windowSizes` / `progressiveThreshold` against the DD-6 table, plus a focused levels-8–10-equal-level-7 test. This is the byte-behavior proof; corpus floors are the regression net. (DD-6)

## Tasks / Subtasks

- [x] **Task 1 — DD-8 empirical gate (DONE during finalization).** (AC: #7) A `swift` compile confirmed `case .default:` on a `String` enum with a `static let \`default\`` **compiles and matches `.level7` via `~=`** — no mis-parse. Verdict: DROP the rule (see DD-8). No further action for dev; do not add a lint rule.
- [x] **Task 2 — Reshape the type.** (AC: #1, #2, #3)
  - [x] Rewrite `AnalysisIntensity.swift`: `enum … : String, CaseIterable, Sendable, Hashable, Comparable, DocumentedCase`, `level1…level10`, `documentedKind`, the four static-let aliases, `var level: Int`, `init?(level: Int)`, `static func < { $0.level < $1.level }`. Remove `ExpressibleByIntegerLiteral`, `init(rawValue:)`, `rawValue: Int`.
  - [x] Rewrite `techniqueSet` / `windowSizes` / `progressiveThreshold` as `switch self` preserving the DD-6 table exactly.
- [x] **Task 3 — Full-repo `.rawValue` audit + library call sites.** (AC: #4, #5)
  - [x] `rg '\.rawValue'` scoped to `AnalysisIntensity` values across Sources/Tests/Demo/feature-extractor; classify each (doc-string vs migrate-to-`.level`). A green build is NOT sufficient — String `rawValue` silently changes numeric interpolations.
  - [x] `AudioAnalysisService.swift:673` cap → `requested <= dspOnlyMaxIntensity` (Comparable); `:688-689` log → `.level`.
  - [x] `BPMDiagnosticTrace.swift` / `TraceExport.swift` Int fields → `.level`.
  - [x] Verify `ComputeBudget.swift` extension still compiles (no edit expected).
- [x] **Task 4 — Migrate Demo + develop-only call sites.** (AC: #5)
  - [x] `Demo/.../ContentView.swift` slider: clamp `Int(newValue.rounded())` to `1...10` then `init?(level:) ?? .default`; get uses `.level`; label switch on `self`/`.level`. `AnalysisViewModel.swift` codegen emits `.level\(n)` for all 10 + `formatResultRow` uses `.level`; `TraceView.swift` display → `.level`; `AnalysisViewModelSmokeTest.swift` fixtures.
  - [x] `_bmad-output/ml-training/swift_feature_extractor/Sources/tony-dsp-prepass/main.swift:201`: clamp then `init?(level:) ?? .default`.
- [x] **Task 5 — Tests.** (AC: #1, #3, #6, #9)
  - [x] Delete obsolete clamp/literal tests. Add: `allCases.count == 10`, `allCases.map(\.level) == Array(1...10)`, all four aliases (`.fastest==.level1` … `.maximum==.level10`), `documentationID == rawValue`, `init?(level:)` round-trip (valid 1…10 + nil for 0/11), per-level value-equality (DD-6 table), levels-8–10-equal-7, DocumentedCase `.docs` non-empty smoke, `budget` over `allCases`.
  - [x] Keep the `Comparable` ordering test lines (`<`/`>=`) — they compile unchanged.
- [x] **Task 6 — DocumentedCase directory reservation.** (AC: #6)
  - [x] Create `Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/.gitkeep`. NO prose (11.3b). NO SwiftLint rule (DD-8 dropped it).
- [x] **Task 7 — Amend upstream docs (develop-only).** (AC: #7)
  - [x] Supersession note on KDD-E4 (architecture ~592-611), the architecture footgun table row (~878) + "SwiftLint custom rule (new)" (~909), and epics.md Story 11.2 AC + invariants line (~181): correct the `case .default:` premise; retire the SwiftLint-rule AC. Update the CLAUDE.md/project-context `AnalysisIntensity` roster prose (struct → enum) at close-out.
- [x] **Task 8 — Gating.** `make fmt` → `make lint` → `make test` → `make demo-build` → `swift run` (feature-extractor) → `make benchmark` + `make benchmark-giantsteps`. Record exact integer counts in Completion Notes.

## Dev Notes

### Call-site blast radius (verified by Explore sweep, 2026-07-16)

**17 Swift files** touch `AnalysisIntensity` with real code (not doc-comment mentions):
- **Sources (5):** `AnalysisIntensity.swift` (rewrite), `ComputeBudget.swift` (verify-only), `BPMAnalyzer.swift` (`.techniqueSet` consumer — no change), `AudioAnalysisService.swift` (`.rawValue`→`.level` at 673/688-689; consumers of `.windowSizes`/`.progressiveThreshold`/`.techniqueSet` unchanged), `BPMDiagnosticTrace.swift` (`.default` alias — unchanged; `effectiveIntensity` surfaced).
- **Tests (7):** `BPMAnalyzerTests.swift` (biggest — clamp/literal/Comparable/property assertions), `AudioAnalysisServiceTests.swift`, `SignalPoolTests.swift`, `EnsembleConfigTypesTests.swift` (budget test now iterates `allCases` — code-review patch), `OA300BenchmarkTests.swift`, `BNNSImpactTests.swift`, `GiantStepsBenchmarkTests.swift` (`.rawValue`→`.level` into `Int` reporter params).
- **Demo (5):** `ContentView.swift`, `AnalysisViewModel.swift`, `TraceView.swift`, `TraceExport.swift`, `AnalysisViewModelSmokeTest.swift`.
- **ML-training (1):** `swift_feature_extractor/Sources/tony-dsp-prepass/main.swift`.

**Named constants `.fastest`/`.default`/`.thorough`/`.maximum` survive unchanged** via the static-let aliases — but any trailing `.rawValue` on them breaks and must become `.level`.

### DD-6 value table (must be preserved exactly)

| level | techniqueSet | windowSizes | progressiveThreshold |
|---|---|---|---|
| level1 | `TechniqueSet(candidateCount: 1)` | `[15]` | `nil` |
| level2 | `.baseline` | `[30]` | `nil` |
| level3–5 | `.optimal` | `[30]` | `nil` |
| level6 | `.optimal` | `[30, 60]` | `0.40` |
| level7–10 | `.optimal` | `[30, 60, 90]` | `0.40` |

(`level7` = `.default`. `level8` = `.thorough`, `level10` = `.maximum`; levels 8-10 currently behave identically to level7 — reserved for future ML.)

### Constraints from project-context / CLAUDE.md

- All new/changed public types stay `Sendable`; the enum is trivially `Sendable`.
- `String`-raw + `CaseIterable` invariants are unit-test-locked (`AnalysisIntensity.allCases.count == 10` joins the count-assertion family).
- Header format (six-line), `// MARK:` sections, `///` doc comments with the ordinal/level semantics.
- Demo target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the migrated reads are pure value reads (no isolation concern).
- **Note the CLAUDE.md/project-context roster drift:** they describe `AnalysisIntensity` as a struct (1-10). Update the roster prose as part of close-out is a DOC task, but do NOT let the stale prose drive the code — the code follows KDD-E4.

### Byte-identity / regression posture

The reshape is a pure representation change; per-level behavior is invariant. The four corpus floors are the unconditional regression net. Additionally ship a direct value-equality test over all 10 levels (DD-6 table) so a mis-transcribed `switch self` fails at unit-test time, not corpus time.

## Previous Story Intelligence (Story 11.1)

- Commits `3c6996b` (protocol + accessor + Mutex cache) + `9a9fa73` (front-matter stripping). 853/853 tests, 140 suites green.
- `DocumentedCase` is `Sendable`-only (NOT `Hashable`). String-raw conformers get `documentationID` free from the constrained extension — so `AnalysisIntensity` (String-raw) needs only `documentedKind` + the enum declaration to conform; `docs` and `documentationID` are inherited.
- SPM wiring already done in 11.1: `Package.swift` has `resources: [.copy("Resources/Documentation")]`; `_Fixture` sentinels live under `Resources/Documentation/_Fixture/`. Adding an `AnalysisIntensity/` sibling directory needs no `Package.swift` change (the whole tree is `.copy`d).
- `.docs` is a total function — a case with no `.md` yet returns an informative non-empty fallback. Reserving the directory (empty) is sufficient for 11.2; prose lands in 11.3b.
- 11.1 landed on `rterhaar/epic-11`; 11.2 is on branch `rterhaar/11-2-analysisintensity-enum-reshape` off it, merging back to `rterhaar/epic-11` (umbrella PR #97 into develop, kept draft until epic close).

## References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 11.2] — ACs, FR-45, KDD-E4, pressure-release valve.
- [Source: _bmad-output/planning-artifacts/architecture.md#KDD-E4] (lines 592-611) — enum shape + alias declarations + the `case .default:` footgun claim (DD-8 tests this empirically).
- [Source: _bmad-output/planning-artifacts/architecture.md#KDD-A4a] (lines 398-416) — `ComputeBudget` carrier (already shipped 6.5a — DD-9).
- [Source: Sources/BoomBoomBoomKit/AnalysisIntensity.swift] — current struct (rewrite target).
- [Source: Sources/BoomBoomBoomKit/ComputeBudget.swift:53-61] — existing `AnalysisIntensity.budget` extension (verify-only).
- [Source: Sources/BoomBoomBoomKit/DocumentedCase.swift] — conformance contract (String-raw path).

## Finalization Log

**2026-07-16 — create-story → Codex review → xcode-mcp empirical check → party-mode finalize.** Three-layer pre-implementation review (per project-context "5-layer review cadence"):
- **Codex review (`codex:consult`)** walked the 9-DD block against the live source. Two [blocking]: (1) KDD-E4's `case .default:` footgun premise is false; (2) the SwiftLint rule would false-positive `EnsemblePolicy.default`. Several [should-fix]: `?? .default` silent-substitution trap, dropping `Comparable` unjustified, missed `.rawValue` call sites (`SignalPoolTests`, `formatResultRow`, `AudioAnalysisServiceTests`), codegen contract underspecified, order-lock/alias/documentationID test gaps, "byte-identical" overstated, budget test should iterate `allCases`.
- **xcode-mcp cross-check.** `DocumentationSearch` (Swift Equatable/expression-pattern semantics) + a direct `swift` compile of a `String` enum with `static let \`default\` = .level7`: `switch { case .default: … }` printed `MATCHED-default-alias(level7)` — empirically proving `case .default:` matches via `~=` and does NOT mis-parse. (A `RunCodeSnippet` attempt against the operator's open `2manyDJs` app compiled the snippet but crashed that host app on launch — unrelated to the snippet; the `swift` compile is authoritative.)
- **party-mode ratification.** DROP the SwiftLint rule (DD-8); KEEP `Comparable` as an authorized addition beyond KDD-E4's minimal conformance list (DD-3); clamp-before-`init?(level:)` at call sites so `?? .default` never silently fires (DD-2); fold all should-fixes (full-repo `.rawValue` audit, canonical `.level<n>` codegen, order/alias/documentationID/budget tests, softened byte-identity wording).

## Dev Agent Record

### Agent Model Used

claude-opus-4-8[1m] (dev-auto pipeline: create-story → Codex review → xcode-mcp → party-mode → dev-story).

### Debug Log References

- DD-8 empirical: `swift` compile of a `String` enum with `static let \`default\` = .level7` → `case .default:` prints `MATCHED-default-alias(level7)` (matches via `~=`; does not mis-parse).
- Two compile-error iterations during migration, both silent-String-`rawValue` sites the audit surfaced (not the compiler): `AudioAnalysisServiceTests` `maximumSupportedIntensity(...).rawValue == 7/10` (function-call form) — fixed to `.level`.

### Completion Notes List

Shipped the `AnalysisIntensity` struct → 10-case `String` enum reshape, behavior-preserving:

- **Type (`AnalysisIntensity.swift`):** `enum … : String, CaseIterable, Sendable, Hashable, Comparable, DocumentedCase`, cases `level1`…`level10`; `documentedKind = "AnalysisIntensity"`; static-let aliases `.fastest/.default/.thorough/.maximum`; `var level: Int` ordinal accessor; failable `init?(level:)`; `static func <` on `.level`. Removed `init(rawValue: Int)`, `rawValue: Int`, `ExpressibleByIntegerLiteral`. The three computed properties rewritten `switch rawValue` → `switch self`, values unchanged.
- **DD-8 (empirically settled):** NO custom SwiftLint rule — `case .default:` matches `.level7` via `~=`; the premise was false and a blanket regex would false-positive `EnsemblePolicy.default`. Upstream `architecture.md` (KDD-E4 + footgun table + enforcement line) and `epics.md` (Story 11.2 AC + invariants line) carry supersession notes.
- **DD-2:** call sites (Demo slider, ML CLI) clamp `Int` to `1...10` before `init?(level:)` so no silent `.default` substitution. **DD-3:** kept `Comparable` (authorized addition). **DD-1a:** Demo codegen emits canonical `.level<n>` for all ten.
- **Full-repo `.rawValue` audit** (a green build is insufficient — String `rawValue` silently changes `7` → `"level7"`): migrated 19 numeric-reader sites across Sources/Tests/Demo/feature-extractor. Two function-call-form sites (`maximumSupportedIntensity(...).rawValue`) were caught only by the audit + the compiler, not the first grep.
- **DD-9:** `ComputeBudget.swift` unchanged; `AnalysisIntensity.budget` resolves `.default` for every case (budget test now iterates `allCases`).
- **Directory reserved:** `Resources/Documentation/AnalysisIntensity/.gitkeep` (prose is 11.3b). `.docs` returns non-empty fallback for every case (smoke test).

**Gating (all green):** `make build` clean; `make test` **855 tests / 140 suites** (was 853 at 11.1 baseline; net +2 after removing 3 obsolete clamp/literal tests and adding order-lock/round-trip/alias/documentationID/value-table/8-10-cap/docs-smoke tests); `make demo-build` BUILD SUCCEEDED; `make demo-test` TEST SUCCEEDED (incl. all 7 `.level<n>` codegen fixtures); `make fmt` + `make lint` **0 serious** (5 pre-existing Demo warnings, none in changed files); `make benchmark` OA300 floors held (Acc1 ≥ 57/82, Acc2 ≥ 73/82); `make benchmark-giantsteps` **Acc1 537/661, Acc2 546/661** (floors met) with the byte-exact pre-Story-3-4/3-5 baseline tests passing — confirms behavior preservation.

**Out of scope / pre-existing:** the develop-only `dump-model-input` CLI has a `FeatureSubstrate.PrimingInfo(codec: .wav)` compile error present byte-identically on baseline `9a9fa73` — unrelated to this story (a prior FeatureSubstrate drift). The `AnalysisIntensity` consumer target `tony-dsp-prepass` builds clean.

**Pending user action (operator-owned):** (1) separate-LLM `/bmad-code-review` on this story (review → done); (2) 1Password-signed commit; (3) the CLAUDE.md/project-context roster prose still describes `AnalysisIntensity` as a struct — a doc-only close-out edit (flagged in Task 7, not blocking).

### File List

**Sources (main-bound):**
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift` — struct → enum reshape (rewrite).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — DSP-cap comparison via `Comparable`; degradation message via `.level`.
- `Sources/BoomBoomBoomKit/Resources/Documentation/AnalysisIntensity/.gitkeep` — NEW (directory reservation).

**Tests (main-bound):**
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` — rewrote the `AnalysisIntensity` suite (order-lock, round-trip, aliases, documentationID, value-table, 8-10-cap, docs-smoke); migrated `intensity:`/`init` sites.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — `init?(level:)` + `.level` migrations (incl. `maximumSupportedIntensity`).
- `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift` — `.level` in diagnostic interpolations.
- `Tests/BoomBoomBoomKitTests/EnsembleConfigTypesTests.swift` — budget test iterates `AnalysisIntensity.allCases` (code-review patch, AC #8).
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift`, `GiantStepsBenchmarkTests.swift`, `BNNSImpactTests.swift` — `.level` / `init?(level:)`.

**Demo (develop-only):**
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/ContentView.swift` — slider `Double`-domain clamp then `init?(level:)` (code-review hardening), label `.level`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/AnalysisViewModel.swift` — codegen `.level<n>`, result-row `.level`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM/TraceView.swift`, `TraceExport.swift` — `.level`.
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPMTests/AnalysisViewModelSmokeTest.swift` — codegen fixtures → `.level<n>`; `.level`/`==` migrations.

**Develop-only tooling:**
- `_bmad-output/ml-training/swift_feature_extractor/Sources/tony-dsp-prepass/main.swift` — clamp-then-`init?(level:)`.
- `_bmad-output/planning-artifacts/architecture.md`, `epics.md` — KDD-E4 / AC supersession notes (DD-8 rule retired).
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status transitions.

### Code Review (2026-07-16, `bmad-code-review`)

Four parallel adversarial reviewers on the 771-line working-tree diff: Blind Hunter + Edge Case Hunter + Acceptance Auditor (subagents) + a **Codex blind-hunter** (`codex:consult`). Three of the four found **no correctness defect** and independently confirmed the per-level value table (`techniqueSet`/`windowSizes`/`progressiveThreshold`) is byte-preserved and every numeric `.rawValue` reader was migrated. Triage:
- **[medium → PATCHED]** Acceptance Auditor: AC #8 / DD-9 budget test did NOT iterate `allCases` — `EnsembleConfigTypesTests.swift` still had the two-case 6.5a form while the Completion Notes claimed otherwise. Fixed: the budget test now iterates `AnalysisIntensity.allCases`; the completion claim is now accurate.
- **[low → PATCHED]** Edge Case Hunter: the Demo slider setter converted `Int(newValue.rounded())` before clamping, so a finite out-of-`Int`-range `Double` would trap the conversion, and the comment overclaimed the `isFinite` guard. Unreachable (slider bound 1.0–10.0) but fixed defensively: clamp in the `Double` domain before `Int(_:)`, honest comment.
- **[dismiss]** Blind Hunter: clamping moved to call sites (by design — DD-2 ratified) and hardcoded `1,10` clamp bounds (nit; not worth a new public range API pre-1.0).

Post-patch re-gate: `make test` 855/140 green (incl. the patched budget test), `make demo-build` BUILD SUCCEEDED.

### Change Log

- 2026-07-16 — Code review (4 reviewers incl. Codex blind-hunter): 2 patches (budget-test-over-allCases AC #8; Demo slider Double-domain clamp), 2 dismissed; re-gated green.
- 2026-07-16 — Story 11.2 implemented: `AnalysisIntensity` struct → 10-case `String` enum (`Comparable`, `DocumentedCase`, `level`, `init?(level:)`); behavior byte-preserved (corpus floors + byte-exact baseline tests green); custom SwiftLint rule dropped (DD-8 empirically disproved); 855 tests / 140 suites green. Status → review.
