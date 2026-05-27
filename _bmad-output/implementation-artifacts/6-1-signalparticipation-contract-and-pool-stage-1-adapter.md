# Story 6.1: SignalParticipation contract + typed-evidence trace + UnifiedSignalPool Stage 1 adapter

Story ID: 6.1
Story Key: 6-1-signalparticipation-contract-and-pool-stage-1-adapter
Epic: 6 — Unified-signal-pool ensemble (foundation; first of 5 strictly-sequenced Tier-1 stories)
Status: ready-for-dev

## Story

**As a** library maintainer,
**I want** the unified signal pool to expose a typed 4-state participation contract (`SignalParticipation`) and matching trace entry (`SignalParticipationTraceEntry`) that ship in the same PR as the Stage 1 `UnifiedSignalPool` internal adapter,
**So that** DSP, ML, file-metadata, and beat-grid signals share a single abstain / demotion / presence contract with zero silent evidence loss, while the frozen `CandidateMergeStrategy.merge` 41-call-site signature remains untouched and the byte-equality regression scaffold (`@Tag(.stage1Floor)`) stays green.

## Scope clarification (read first)

Story 6.1 is the **foundation PR of Epic 6**. The unified-signal-pool architecture has zero presence in the current codebase — this story introduces the type vocabulary AND the Stage 1 adapter as one indivisible delivery. The adapter is *internal-only*; no public API surfaces yet. Downstream stories 6.2 → 6.5 layer on top.

**Three deliverables land in this PR (none separable):**

1. **`SignalPool/` subfolder + 7 source files** introducing `SignalParticipation` 4-state contract, payload types (`WeightedSignal`), reason enums (`AbstainReason`, `DemotionReason`), source tag (`SignalSource`), typed-evidence trace entry (`SignalParticipationTraceEntry`), and the Stage 1 adapter (`UnifiedSignalPool`).
2. **`BPMDiagnosticTrace.signalParticipationTrace: [SignalParticipationTraceEntry]` field** — typed-evidence per KDD-T0, populated whenever a candidate enters the merge stage. Honors the 5-recipe `bpm-diagnostic-trace` audit (zero matches against `Sources/` + `Tests/`).
3. **Stage 1 regression scaffold** — Swift Testing `@Tag(.stage1Floor)` extension, applied to the existing Story 3-6 byte-equality opt-out tests in `MetadataCorroborationTests.swift` (the only existing byte-equality regression tests). `NumericTestHelpers.swift` in `BoomBoomBoomKitTestSupport` extracts the existing inline `Double.bitPattern` comparison into a shared `Double.bitEqual(to:)` helper.

**What this story does NOT deliver** (each is explicitly OUT-OF-SCOPE):

- **No public API surfacing of new types.** Per the Epic 6 ↔ Epic 8 seam mitigation rule (Mary's contribution, party-mode 2026-05-26), all new types in this PR stay `internal` OR `public` with NO DocC `///` doc comments and NO README mention. Epic 8 stories promote them. Pre-mature promotion = scope violation.
- **No changes to `CandidateMergeStrategy.merge` signature.** The 41-call-site frozen signature remains `merge(_:options:) -> BPMResult?`. The adapter constructs `UnifiedSignalPool` at the `MetadataCorroborator.apply` entry point only; `merge` continues to take `[BPMResult]` as today. Signature break lands in Story 6.4 (KDD-A6 Stage 3).
- **No type rename of `CandidateMergeStrategy`.** Rename to `BPMSelectionPolicy` is Story 6.5 (KDD-A1).
- **No `SignalWeights`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `ComputeBudget`, `EnsemblePolicy` 5-case facade.** Those land Story 6.5.
- **No removal of `MetadataCorroborator.apply` or `EnsembleCombiner`.** Those are Stage 2 / 3.
- **No `FeatureSubstrate`, `OnsetFeaturesBuilder`, `MLFeatureFrames` relocation.** Story 6.2.
- **No accuracy-changing behavior.** OA300 + GiantSteps baselines (Acc1 58/82+74/82; 537/661+546/661) hold unchanged. `@Tag(.stage1Floor)` byte-equality tests passing at 100% on the OA300 sample subset is the regression contract.
- **No demotion-firing behavior.** `.demoted(...)` is part of the contract surface but never emitted by any signal source in Stage 1. The adapter wraps existing values as `.present` (DSP candidates, ML evaluations) or `.absent` (disabled metadata) only. Cluster-context demotion logic is Stage 2+.

## Key Design Decisions

The 10 DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #3, #6, and #9 are most consequential** — they lock the SAME-PR delivery contract, the type shapes, the internal-only access posture, the regression scaffold, and the pressure-release valve.

1. **SAME-PR delivery is non-negotiable (KDD-T0).** `SignalParticipation` and `SignalParticipationTraceEntry` ship in the same commit. The architecture explicitly cites Story 3-3b's audit recipes existing *because* every "we'll typify it later" became 6-month debt. PR commit log (`git log -p`) must show both type files plus one populating consumer call in `AudioAnalysisService` in a single commit.

2. **Four-state enum — verbatim shape.** `SignalParticipation` carries exactly 4 cases — `.absent` / `.abstained(AbstainReason)` / `.demoted(WeightedSignal, reason: DemotionReason)` / `.present(WeightedSignal)`. `AbstainReason` carries 4 cases (`.policyDisabled`, `.inputBelowMinimum`, `.confidenceBelowFloor`, `.sourceSpecific(String)`). `DemotionReason` carries 2 cases (`.implausibleForContext`, `.sourceSpecific(String)`). Verbatim per architecture.md:128-146 — no creative reinterpretation.

3. **Internal-only adapter; access-level discipline tight.** New types land at the lowest access level that satisfies the tests. `UnifiedSignalPool` is `internal`. `SignalParticipationTraceEntry` is `public` because it lives on `BPMDiagnosticTrace` (which is public) — but the field declaration on the trace itself uses `public var signalParticipationTrace: [SignalParticipationTraceEntry] = []` with NO `///` doc comment (Epic 8 promotes). `SignalParticipation`, `AbstainReason`, `DemotionReason`, `WeightedSignal`, `SignalSource` are `public` (Sendable contract requires `Sendable` on transitively-public types) BUT with NO `///` doc comments. The pre-1.0 / Epic 6→Epic 8 seam is: ship the type, withhold the documentation. This is intentional — Story 6.4 may evolve field sets before any consumer sees them.

4. **`WeightedSignal` minimal shape.** Architecture doesn't fully pin the payload — pin it here at minimum-viable:
   ```swift
   public struct WeightedSignal: Sendable, Hashable, Codable {
       public let bpm: Double
       public let confidence: Double
       public let source: SignalSource
   }
   ```
   Field expansion (e.g., `originatingWindowIndex`, `clusterID`) requires a named story spec — same discipline as `MLEvaluation` post-Story-4-5.

5. **`SignalSource` 4-case enum.** `.dsp` / `.ml` / `.fileMetadata` / `.beatGrid`. Conforms `String, CaseIterable, Sendable, Hashable, Codable`. The `.beatGrid` case ships now (no consumer yet) — anticipates Epic 8 Story 8.x without forcing a re-emit on the contract.

6. **Stage 1 adapter contract — wrap, don't replace.** `UnifiedSignalPool` is constructed at `MetadataCorroborator.apply(to:input:)` entry point, populated by:
   - Each `BPMResult.candidates` entry → `.present(WeightedSignal(bpm: c.bpm, confidence: c.confidence, source: .dsp))`
   - `Options.mlTechnique == nil` → `.absent` for `.ml`
   - `Options.mlTechnique != nil` AND `evaluate(trace:) == nil` → `.abstained(.confidenceBelowFloor)` (or `.sourceSpecific(...)` if `MLDiagnosticTechnique` snapshot surfaces a specific failure stage)
   - `Options.mlTechnique != nil` AND `evaluate(trace:) == some MLEvaluation` → `.present(WeightedSignal(bpm: eval.bpm, confidence: eval.confidence, source: .ml))`
   - `Options.metadataPolicy == .disabled` → `.absent` for `.fileMetadata`
   - Metadata tags present in `MetadataCorroborationInput.consensus` → `.present(WeightedSignal(bpm: tag.bpm, confidence: 0.8, source: .fileMetadata))` (0.8 reflects post-Story-3-6 boost ceiling; ML/DSP-derived value is the candidate's own confidence)

   The pool is constructed THEN NOT YET CONSUMED — it lives on a local `let` so a future Stage 2 can wire it into `MetadataCorroborator`. Trace population pulls from this pool. `merge(_:options:)` continues to see `[BPMResult]` only.

7. **Trace population: pre-merge snapshot.** `BPMDiagnosticTrace.signalParticipationTrace` is populated by `AudioAnalysisService.analyzeBPM` BEFORE `CandidateMergeStrategy.merge` is invoked — captures the pool's pre-merge state. Each `SignalParticipationTraceEntry` carries `(source, participation, weight: Double, contribution: Double)`. In Stage 1, `weight` is always 1.0 (no `SignalWeights` yet) and `contribution = participation.confidence × 1.0` (i.e., the raw confidence, zero for `.absent`/`.abstained`). Populated only when `Options.enableTrace == true`; nil-safe `trace?.signalParticipationTrace = ...` pattern.

8. **`@Tag(.stage1Floor)` scaffold.** A Swift Testing tag extension lands in `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` (new file):
   ```swift
   import Testing
   extension Tag { @Tag static var stage1Floor: Self }
   ```
   The 4 existing byte-equality `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift` (lines 425, 470, 502, 531) receive the `@Test(.tags(.stage1Floor), ...)` annotation. New tests added in this story do NOT carry the tag — `stage1Floor` is specifically the regression-floor scaffold for the pre-Story-6.1 byte-equality contract.

9. **Pressure-release valve (Winston).** If scope cracks under combined `SignalParticipation` + `SignalParticipationTraceEntry` + Stage 1 adapter, split into:
   - **Story 6.1a** — `SignalPool/` types + `SignalParticipationTraceEntry` field + trace-only population (no adapter wiring)
   - **Story 6.1b** — `UnifiedSignalPool` adapter + `@Tag(.stage1Floor)` scaffold + `NumericTestHelpers.swift` extraction

   Document the split decision in `_bmad-output/implementation-artifacts/6-1-pressure-release.md` ONLY if the valve fires. Do not pre-create the file.

10. **5-recipe `bpm-diagnostic-trace` skill audit, both before AND after.** This is the first new typed-evidence field added since Story 3-3b. Before adding `signalParticipationTrace`, run the audit recipes against `Sources/` + `Tests/` to confirm clean baseline (expected: zero matches, since Story 3-3b cleaned everything). After adding, re-run; still zero matches. The skill lives at `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke it via the Skill tool, follow the per-field checklist.

## Acceptance Criteria

The 7 ACs below are verbatim from `epics.md:391-419` with two clarifications (AC #4 weight-1.0 contribution formula, AC #7 NumericTestHelpers location).

1. **Given** new files land at `Sources/BoomBoomBoomKit/SignalPool/` (`SignalParticipation.swift`, `AbstainReason.swift`, `DemotionReason.swift`, `WeightedSignal.swift`, `SignalSource.swift`, `SignalParticipationTraceEntry.swift`, `UnifiedSignalPool.swift`), **When** the test suite runs, **Then** every new public type conforms to `Sendable, Hashable`; `SignalParticipation` carries exactly four cases (`.absent` / `.abstained(AbstainReason)` / `.demoted(WeightedSignal, reason: DemotionReason)` / `.present(WeightedSignal)`); and a new `SignalPoolTests.swift` suite is present.

2. **Given** `BPMDiagnosticTrace.swift` adds the `signalParticipationTrace: [SignalParticipationTraceEntry]` field, **When** the 5-recipe BPM-diagnostic-trace audit (`.claude/skills/bpm-diagnostic-trace/SKILL.md`) runs against `Sources/` and `Tests/`, **Then** all five recipes return zero matches (KDD-T0 typed-evidence trigger satisfied).

3. **Given** `SignalParticipationTraceEntry` ships in the same PR as `SignalParticipation` (KDD-T0 SAME-PR rule, non-negotiable), **When** the PR commit list is reviewed, **Then** both type files plus a populating consumer call in `AudioAnalysisService` are present in the same commit (verified via `git log -p`).

4. **Given** `UnifiedSignalPool.swift` is introduced as an internal-only adapter (not yet consumed by `CandidateMergeStrategy.merge`), **When** the existing `merge(_:options:)` call sites compile (3 call-site files: `AudioAnalysisService.swift`, `BPMAnalyzerTests.swift`, `OA300BenchmarkTests.swift`; ~41 distinct invocations across `swift test`/`swift build`), **Then** the frozen `merge` signature is unchanged at this stage AND the trace's `signalParticipationTrace` entries each report `weight: 1.0` and `contribution: participation.confidence × 1.0` (zero for `.absent`/`.abstained`).

5. **Given** a new `@Tag(.stage1Floor)` declaration in the Swift Testing `Tag` extension (`Tests/BoomBoomBoomKitTests/StageFloorTags.swift`) and applied to the 4 existing `metadataPolicy = .disabled` byte-equality tests in `MetadataCorroborationTests.swift`, **When** `swift test --filter-tag stage1Floor` runs, **Then** the byte-equality regression scaffold passes at 100% (Stage 1 floor referenced by Story 6.3).

6. **Given** the per-source contract assertion in `SignalPoolTests`, **When** DSP analysis runs at any `AnalysisIntensity` level (1-10) across the OA300 sample subset, **Then** `SignalSource.dsp` produces ≥ 1 of `{.present, .abstained, .demoted}` per analysis — never `.absent`.

7. **Given** `Codable` round-trip tests for all four `SignalParticipation` cases, **When** each case (including `.present(WeightedSignal)` and `.demoted(WeightedSignal, reason: DemotionReason)` payloads) round-trips through `JSONEncoder`/`JSONDecoder`, **Then** the decoded value byte-equals the encoded value using `BoomBoomBoomKitTestSupport.NumericTestHelpers.Double.bitEqual(to:)` (NaN-safe — Story 3-6 inline pattern extracted to a shared helper).

## Tasks / Subtasks

- [ ] Task 1 — Pre-flight (AC: #2)
  - [ ] 1.1 Invoke the `bpm-diagnostic-trace` skill via the Skill tool; read SKILL.md fully
  - [ ] 1.2 Run the 5 audit recipes against `Sources/` + `Tests/` BEFORE any changes; record baseline (expected: zero matches)
  - [ ] 1.3 Confirm the 4 `metadataPolicy = .disabled` byte-equality tests in `MetadataCorroborationTests.swift` (lines 425, 470, 502, 531) currently pass against the working tree

- [ ] Task 2 — Add `Double.bitEqual(to:)` helper to TestSupport (AC: #7)
  - [ ] 2.1 Create `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift` containing `public extension Double { func bitEqual(to other: Double) -> Bool { self.bitPattern == other.bitPattern } }`
  - [ ] 2.2 Confirm `make build` succeeds; helper consumable from both library + benchmark test targets

- [ ] Task 3 — Create `SignalPool/` subfolder + 7 type files (AC: #1, #3)
  - [ ] 3.1 `mkdir Sources/BoomBoomBoomKit/SignalPool/`
  - [ ] 3.2 `SignalSource.swift` — `public enum SignalSource: String, CaseIterable, Sendable, Hashable, Codable { case dsp, ml, fileMetadata, beatGrid }`
  - [ ] 3.3 `AbstainReason.swift` — 4-case enum per DD #2; conforms `Sendable, Hashable, Codable`
  - [ ] 3.4 `DemotionReason.swift` — 2-case enum per DD #2; conforms `Sendable, Hashable, Codable`
  - [ ] 3.5 `WeightedSignal.swift` — struct per DD #4; conforms `Sendable, Hashable, Codable`
  - [ ] 3.6 `SignalParticipation.swift` — 4-case enum per DD #2; conforms `Sendable, Hashable, Codable`. Computed property `confidence: Double` returns `0.0` for `.absent`/`.abstained`, `weighted.confidence` for `.present`/`.demoted` (used by trace contribution math per DD #7)
  - [ ] 3.7 `SignalParticipationTraceEntry.swift` — struct per architecture.md:693-700; conforms `Sendable, Hashable, CustomStringConvertible`
  - [ ] 3.8 `UnifiedSignalPool.swift` — `internal struct UnifiedSignalPool: Sendable { let entries: [SignalParticipationTraceEntry]; init(...) }` per DD #6 wrap-don't-replace contract
  - [ ] 3.9 **No `///` doc comments on any new type** — Epic 6 ↔ Epic 8 seam mitigation per DD #3

- [ ] Task 4 — Wire `BPMDiagnosticTrace` field + AudioAnalysisService population (AC: #2, #3, #4)
  - [ ] 4.1 Add `public var signalParticipationTrace: [SignalParticipationTraceEntry] = []` field to `BPMDiagnosticTrace.swift` — no `///` doc comment
  - [ ] 4.2 In `AudioAnalysisService.analyzeBPM`, BEFORE the call site to `CandidateMergeStrategy.merge`, construct the `UnifiedSignalPool` per DD #6 and populate `trace?.signalParticipationTrace` with one entry per source. Trace assignment is nil-safe (`trace?.signalParticipationTrace = ...` pattern)
  - [ ] 4.3 The pool's `let` binding is consumed ONLY by trace population in Stage 1 — `merge(_:options:)` is invoked with the unchanged `[BPMResult]` array
  - [ ] 4.4 Single-commit verification: `git log -p HEAD` shows `SignalParticipation.swift` + `SignalParticipationTraceEntry.swift` + the AudioAnalysisService population call all in one commit (KDD-T0 SAME-PR rule)

- [ ] Task 5 — `@Tag(.stage1Floor)` regression scaffold (AC: #5)
  - [ ] 5.1 Create `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` with `import Testing` + `extension Tag { @Tag static var stage1Floor: Self }`
  - [ ] 5.2 Annotate each of the 4 existing `metadataPolicy = .disabled` byte-equality tests in `MetadataCorroborationTests.swift` with `@Test(.tags(.stage1Floor), ...)`. Tests at approximately lines 425, 470, 502, 531
  - [ ] 5.3 Migrate the inline `bpm.bitPattern == ...` comparisons in those 4 tests to use `Double.bitEqual(to:)` (Task 2 deliverable) — keeps semantics identical, removes duplicated logic
  - [ ] 5.4 Verify `swift test --filter-tag stage1Floor` selects exactly 4 tests and they all pass

- [ ] Task 6 — `SignalPoolTests.swift` (AC: #1, #6, #7)
  - [ ] 6.1 Create `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift` with `@Suite("SignalPoolTests")`
  - [ ] 6.2 `@Test func fourCases()` — exhaustive switch over `SignalParticipation` proves the contract has exactly 4 cases (compile-time guarantee). Sendable/Hashable conformance verified by use
  - [ ] 6.3 `@Test(arguments: SignalSource.allCases)` — Codable round-trip for each `SignalSource` case
  - [ ] 6.4 `@Test func codableRoundTripAllParticipationCases()` — round-trip all 4 `SignalParticipation` cases (including `.present` + `.demoted` with `WeightedSignal` payload). Decoded vs encoded compared via `Double.bitEqual(to:)` on `bpm` + `confidence`. Includes `Double.nan` and `Double.infinity` in `WeightedSignal` payload to exercise NaN-safe equality. Per AC #7
  - [ ] 6.5 `@Test func dspPerSourceContract()` — runs `AudioAnalysisService.analyzeBPM` against a single OA300 sample fixture (`AudioFixtures.url(for: "...", extension: "...")`) with `enableTrace: true` at intensities `.fastest` (1), `.default` (7), `.maximum` (10). Asserts trace's `signalParticipationTrace` always contains a `.dsp`-tagged entry with `participation != .absent`. Per AC #6
  - [ ] 6.6 `@Test func mlAbsentWhenTechniqueNil()` — `Options.mlTechnique == nil` produces a trace entry with `source: .ml, participation: .absent`
  - [ ] 6.7 `@Test func metadataAbsentWhenDisabled()` — `Options.metadataPolicy = .disabled` produces a trace entry with `source: .fileMetadata, participation: .absent`

- [ ] Task 7 — Verification & audit (AC: #2)
  - [ ] 7.1 Re-run the 5 `bpm-diagnostic-trace` audit recipes; confirm zero matches against `Sources/` + `Tests/`
  - [ ] 7.2 `make fmt && make lint` — passes (1 violation = canonical LUFSAnalyzer:94 TODO baseline)
  - [ ] 7.3 `make test` — passes; record test count integer delta from Story 5-8 baseline (~433)
  - [ ] 7.4 `swift test --filter-tag stage1Floor` — selects exactly 4 tests; all pass
  - [ ] 7.5 `make benchmark` (OA300) — Acc1 ≥ 58/82, Acc2 ≥ 74/82 — UNCHANGED from Story 5-8 baseline (no library behavior changed)
  - [ ] 7.6 `make benchmark-giantsteps` — Acc1 ≥ 537/661, Acc2 ≥ 546/661 — UNCHANGED
  - [ ] 7.7 Verify `git log -p HEAD` shows the KDD-T0 SAME-PR contract: type files + trace-field + populating consumer call all in one commit

## Dev Notes

### Architecture pointers (read before coding)

- **KDD-S1 verbatim spec:** `_bmad-output/planning-artifacts/architecture.md:123-171`. Pin the enum shape, the pool voting rules, the boundary contract with frozen `MLTechnique`, and the test invariants from this section without reinterpretation.
- **KDD-T0 verbatim spec:** `architecture.md:681-722`. The typed-evidence trigger + SAME-PR rule + 5-recipe enforcement. `SignalParticipationTraceEntry` shape (4 fields: `source`, `participation`, `weight`, `contribution`) at lines 694-700.
- **KDD-A6 Stage 1 staging:** `architecture.md:313-323`. Stage 1 = adapter at `MetadataCorroborator.apply` entry point; zero call sites change; byte-equality tests pass unchanged.
- **Epic 6 ↔ Epic 8 seam mitigation rule (Mary):** `epics.md:23` (party-mode amendment) + Epic 6 body at `epics.md:275`. Internal-or-undocumented; Epic 8 promotes. Cite when reviewing your own diff.
- **`bpm-diagnostic-trace` project skill:** `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke via the Skill tool. The per-field checklist + 5 audit recipes (A-E) are required pre-flight + post-flight.

### Existing code to read (UPDATE files, per checklist rule)

The story modifies 2 existing source files and 1 existing test file. Read each completely before editing:

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (36k, public) — current trace shape, existing typed-evidence fields (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, etc.). The new field follows the same pattern.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (39k) — find the `runPreCorroborationPipeline` static func at line 599 + its caller at line 335. The `UnifiedSignalPool` construction site is BEFORE `MetadataCorroborator.apply` and BEFORE `merge`. Read the full window loop (lines ~250-400) to place the pool construction correctly.
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` (26k) — the 4 byte-equality tests at lines 425, 470, 502, 531 are the existing Story 3-6 precedent. Apply `@Tag(.stage1Floor)` and migrate to `Double.bitEqual(to:)` without changing their assertions.

### File list (what this story creates / updates)

**NEW files (8):**
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift`
- `Sources/BoomBoomBoomKit/SignalPool/AbstainReason.swift`
- `Sources/BoomBoomBoomKit/SignalPool/DemotionReason.swift`
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift`
- `Sources/BoomBoomBoomKit/SignalPool/SignalSource.swift`
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipationTraceEntry.swift`
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift`
- `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift`

**NEW tests (2):**
- `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift`
- `Tests/BoomBoomBoomKitTests/StageFloorTags.swift`

**UPDATED files (3):**
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — add `signalParticipationTrace: [SignalParticipationTraceEntry]` field
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — construct `UnifiedSignalPool` + populate trace field before merge call
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `@Test(.tags(.stage1Floor), ...)` annotation on 4 existing tests; migrate inline `bitPattern` to `Double.bitEqual(to:)`

**FORBIDDEN files (verify diff scope post-implementation):**
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — NO changes (signature frozen per Stage 1)
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — NO changes (Stage 2 territory)
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — NO changes
- `Demo/**` — NO changes (Epic 9 territory)
- `Package.swift` — NO changes (subfolder creation is glob-default for SwiftPM; no manifest update needed)

### Testing standards

- Swift Testing only (`@Suite`, `@Test`, `#expect`, `#require`) — never XCTest. Per `_bmad-output/project-context.md` Testing Rules.
- `@Test(arguments:)` parameterization for `SignalSource.allCases` Codable round-trip. Per project precedent (`OA300BenchmarkTests`, `AblationFullMatrixTests`).
- Test fixtures via `BoomBoomBoomKitTestSupport.AudioFixtures.url(for:extension:)`. Synthetic click tracks not needed for this story (no DSP changes).
- Cancellation/progress not exercised (this story doesn't touch them).
- The `dspPerSourceContract` test at Task 6.5 is the only end-to-end test — runs against ONE small OA300 fixture (not the full corpus) to keep `make test` fast.

### Pre-1.0 framing reminder

Per `_bmad-output/project-context.md` Public API Discipline: ship the contract, withhold the documentation. The new types are AC-named additions, not internal→public discovered-in-diff promotions. Epic 8 stories will promote them properly. No `///` doc comments in this PR is correct, not an oversight.

### Project Structure Notes

- The new `Sources/BoomBoomBoomKit/SignalPool/` subfolder is the architecture-pinned home for unified-pool types (architecture.md:249 — "subdir when ≥5 cohesive files"). SwiftLint and `swift format` glob `Sources/` by default — no `.swiftlint.yml` change.
- File naming follows project convention: PascalCase matching the primary type (`SignalParticipation.swift` contains `enum SignalParticipation`).
- 6-line header on every new file per CLAUDE.md convention.

### Previous Story Intelligence (Story 5-8 close-out 2026-05-25)

Most recent close-out was Story 5-8 (demo rename + App Store submission readiness). Library Sources/ + Tests/ were byte-untouched across the entire Epic 5 (zero accuracy delta — OA300 58/82+74/82, GiantSteps 537/661+546/661 verbatim from Epic 4). Test count baseline at Epic 5 close-out: **~433 `@Test(` declarations** across `BoomBoomBoomKitTests` in 94 suites; `make test` wall-clock 1.83s warm. Story 6.1 expected delta: **+1 test file (`SignalPoolTests.swift` with ~6 `@Test`s)** + **`StageFloorTags.swift` test-support file** (no `@Test`) — projected new total ~439 declarations. Record exact integer count in Completion Notes.

The Story 5-8 close-out also confirmed: (a) `1Password GPG signer` is the final commit requirement (operator action); (b) the operator-owned-closeout-step ceremony from `_bmad-output/project-context.md` Story Authoring Discipline applies — `/bmad-code-review` runs on a different LLM after dev close-out; (c) sprint-status.yaml flips happen by the dev agent.

### 5-layer review cadence (applies to Story 6.1)

Story 6.1 introduces new public API (`SignalParticipation`, payload types, trace field) AND modifies a DSP-adjacent integration point (`AudioAnalysisService` pre-merge wiring). Per project-context.md Story Authoring Discipline, the 5-layer review cadence applies:

1. **Failure Mode Analysis** — pre-PR single-pass against this spec
2. **Self-Consistency review** — 3 parallel Codex agents (Blind Hunter + Edge Case Hunter + Acceptance Auditor) on the post-FMA spec
3. **Code review** on the staged diff (project's `/bmad-code-review` skill)
4. **Codex MCP `codex:consult`** cross-validation (warranted given foundation-story status)
5. **GitHub Copilot inline review** at PR open, triaged into patches/defers/dismissals

Findings persisted to `deferred-work.md` per the canonical-SoT pattern (Epic 4 retro A2).

### References

- [Source: _bmad-output/planning-artifacts/epics.md:384-422] — Story 6.1 user-story prologue + 7 ACs verbatim
- [Source: _bmad-output/planning-artifacts/architecture.md:123-171] — KDD-S1 `SignalParticipation` 4-state contract
- [Source: _bmad-output/planning-artifacts/architecture.md:313-323] — KDD-A6 Stage 1 staging
- [Source: _bmad-output/planning-artifacts/architecture.md:681-722] — KDD-T0 typed-evidence trace + SAME-PR rule
- [Source: _bmad-output/planning-artifacts/architecture.md:823-844] — `@Tag`-based stage-gating + `Double.bitEqual(to:)` helper pattern
- [Source: _bmad-output/planning-artifacts/architecture.md:975-986] — `SignalPool/` subfolder file layout
- [Source: _bmad-output/project-context.md "Banned trace-field shapes"] — 4 prohibited shapes + 5 audit recipes
- [Source: .claude/skills/bpm-diagnostic-trace/SKILL.md] — typed-evidence pattern + per-field checklist
- [Source: Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:425, 470, 502, 531] — Story 3-6 byte-equality opt-out precedent (the 4 tests `@Tag(.stage1Floor)` annotates)

## Dev Agent Record

### Agent Model Used

_To be populated by the dev agent._

### Debug Log References

_To be populated by the dev agent._

### Completion Notes List

_To be populated by the dev agent._

### File List

_To be populated by the dev agent._
