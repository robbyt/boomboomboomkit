# Story 6.1: SignalParticipation contract + typed-evidence trace + UnifiedSignalPool Stage 1 adapter

Story ID: 6.1
Story Key: 6-1-signalparticipation-contract-and-pool-stage-1-adapter
Epic: 6 — Unified-signal-pool ensemble (foundation; first of 5 strictly-sequenced Tier-1 stories)
Status: review

## Story

**As a** library maintainer,
**I want** the unified signal pool to expose a typed 4-state participation contract (`SignalParticipation`) and matching trace entry (`SignalParticipationTraceEntry`) that ship in the same PR as the Stage 1 `UnifiedSignalPool` internal adapter,
**So that** DSP, ML, file-metadata, and beat-grid signals share a single abstain / demotion / presence contract with zero silent evidence loss, while the frozen `CandidateMergeStrategy.merge` 41-call-site signature remains untouched and the Stage 1 regression scaffold (`@Tag(.stage1Floor)` — one byte-equality + three behavioral floor tests per DD #8) stays green.

## Scope clarification (read first)

Story 6.1 is the **foundation PR of Epic 6**. The unified-signal-pool architecture has zero presence in the current codebase — this story introduces the type vocabulary AND the Stage 1 adapter as one indivisible delivery. The adapter is *internal-only*; no public API surfaces yet. Downstream stories 6.2 → 6.5 layer on top.

**Three deliverables land in this PR (none separable):**

1. **`SignalPool/` subfolder + 7 source files** introducing `SignalParticipation` 4-state contract, payload types (`WeightedSignal`), reason enums (`AbstainReason`, `DemotionReason`), source tag (`SignalSource`), typed-evidence trace entry (`SignalParticipationTraceEntry`), and the Stage 1 adapter (`UnifiedSignalPool`).
2. **`BPMDiagnosticTrace.signalParticipationTrace: [SignalParticipationTraceEntry]` field** — typed-evidence per KDD-T0, populated whenever a candidate enters the merge stage. Honors the 5-recipe `bpm-diagnostic-trace` audit (zero matches against `Sources/` + `Tests/`).
3. **Stage 1 regression scaffold** — Swift Testing `@Tag(.stage1Floor)` extension, applied to four existing `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift` (one byte-equality test plus three behavioral floor tests per DD #8). `NumericTestHelpers.swift` in `BoomBoomBoomKitTestSupport` extracts the inline `Double.bitPattern` comparison into a shared `NumericTestHelpers.bitEqual(_:_:)` static helper (namespace form per Patch M15).

**What this story does NOT deliver** (each is explicitly OUT-OF-SCOPE):

- **No public API surfacing of new types.** Per the Epic 6 ↔ Epic 8 seam mitigation rule (Mary's contribution, party-mode 2026-05-26), all new types in this PR stay `internal` OR `public` with NO DocC `///` doc comments and NO README mention. Epic 8 stories promote them. Pre-mature promotion = scope violation.
- **No changes to `CandidateMergeStrategy.merge` signature.** The 41-call-site frozen signature remains `merge(_:options:) -> BPMResult?`. The adapter constructs `UnifiedSignalPool` in `AudioAnalysisService.analyzeBPM` AFTER `runPreCorroborationPipeline` returns and BEFORE `MetadataCorroborator.apply` is invoked (per DD #6); `merge` continues to take `[BPMResult]` as today. Signature break lands in Story 6.4 (KDD-A6 Stage 3).
- **No type rename of `CandidateMergeStrategy`.** Rename to `BPMSelectionPolicy` is Story 6.5 (KDD-A1).
- **No `SignalWeights`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, `ComputeBudget`, `EnsemblePolicy` 5-case facade.** Those land Story 6.5.
- **No removal of `MetadataCorroborator.apply` or `EnsembleCombiner`.** Those are Stage 2 / 3.
- **No `FeatureSubstrate`, `OnsetFeaturesBuilder`, `MLFeatureFrames` relocation.** Story 6.2.
- **No accuracy-changing behavior.** OA300 + GiantSteps baselines (Acc1 58/82+74/82; 537/661+546/661) hold unchanged. `@Tag(.stage1Floor)` byte-equality tests passing at 100% on the OA300 sample subset is the regression contract.
- **No demotion-firing behavior.** `.demoted(...)` is part of the contract surface but never emitted by any signal source in Stage 1. The adapter wraps existing values as `.present` (DSP candidates, ML evaluations) or `.absent` (disabled metadata) only. Cluster-context demotion logic is Stage 2+.

## Key Design Decisions

The 11 DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, #3, #6, and #9 are most consequential** — they lock the SAME-PR delivery contract, the type shapes, the internal-only access posture, the regression scaffold, and the pressure-release valve. DD #11 is the supersession note for epic AC #4.

1. **SAME-PR delivery is non-negotiable (KDD-T0).** `SignalParticipation` and `SignalParticipationTraceEntry` ship in the same commit. The architecture explicitly cites Story 3-3b's audit recipes existing *because* every "we'll typify it later" became 6-month debt. PR commit log (`git log -p`) must show both type files plus one populating consumer call in `AudioAnalysisService` in a single commit.

2. **Four-state enum — verbatim shape.** `SignalParticipation` carries exactly 4 cases — `.absent` / `.abstained(AbstainReason)` / `.demoted(WeightedSignal, reason: DemotionReason)` / `.present(WeightedSignal)`. `AbstainReason` carries 4 cases (`.policyDisabled`, `.inputBelowMinimum`, `.confidenceBelowFloor`, `.sourceSpecific(String)`). `DemotionReason` carries 2 cases (`.implausibleForContext`, `.sourceSpecific(String)`). Verbatim per architecture.md:128-146 — no creative reinterpretation.

3. **Internal-only adapter; access-level discipline tight.** New types land at the lowest access level that satisfies the tests. `UnifiedSignalPool` is `internal`. `SignalParticipationTraceEntry` is `public` because it lives on `BPMDiagnosticTrace` (which is public) — but the field declaration on the trace itself uses `public var signalParticipationTrace: [SignalParticipationTraceEntry] = []` with NO `///` doc comment (Epic 8 promotes). `SignalParticipation`, `AbstainReason`, `DemotionReason`, `WeightedSignal`, `SignalSource` are `public` (Sendable contract requires `Sendable` on transitively-public types) BUT with NO `///` doc comments. The pre-1.0 / Epic 6→Epic 8 seam is: ship the type, withhold the documentation. This is intentional — Story 6.4 may evolve field sets before any consumer sees them. This story explicitly overrides the project-context.md "public API gets `///` doc comments" discipline for these symbols only — internal-or-undocumented per the Epic 6 ↔ Epic 8 seam mitigation. The dev agent MUST surface the list of undocumented public symbols in Completion Notes (a flat list: `SignalParticipation`, `AbstainReason`, `DemotionReason`, `WeightedSignal`, `SignalSource`, `SignalParticipationTraceEntry`, `BPMDiagnosticTrace.signalParticipationTrace`) so Epic 8 promotes them deliberately rather than back-filling DocC ad-hoc. The single doc-comment exception is `WeightedSignal.fileMetadataStage1TraceOnlyDefault` per Patch C1, which MUST carry a `///` cross-reference to Story 6.5.

4. **`WeightedSignal` minimal shape.** Architecture doesn't fully pin the payload — pin it here at minimum-viable. **(Amended 2026-05-27 per AC #1 supersession — `Hashable` dropped from this struct because public `Double` fields cannot honor the Hashable `x == x` invariant under NaN; matches `EnsembleDecision.swift:44` precedent and the existing typed-evidence family. Code block updated; original pre-code-review form was `Sendable, Hashable, Codable`.)**
   ```swift
   public struct WeightedSignal: Sendable, Codable {
       public let bpm: Double
       public let confidence: Double
       public let source: SignalSource
   }
   ```
   Field expansion (e.g., `originatingWindowIndex`, `clusterID`) requires a named story spec — same discipline as `MLEvaluation` post-Story-4-5.

5. **`SignalSource` 4-case enum.** `.dsp` / `.ml` / `.fileMetadata` / `.beatGrid`. Conforms `String, CaseIterable, Sendable, Hashable, Codable`. The `.beatGrid` case ships now (no consumer yet) — anticipates Epic 8 Story 8.x without forcing a re-emit on the contract.

6. **Stage 1 adapter contract — wrap, don't replace.** `UnifiedSignalPool` is constructed in `AudioAnalysisService.analyzeBPM` AFTER `runPreCorroborationPipeline` returns the merged `BPMResult`, BEFORE `MetadataCorroborator.apply` is invoked. Reference call sites in current code: `runPreCorroborationPipeline` returns at line 335; `MetadataCorroborator.apply` invoked at line 342. The pool's `let` binding consumes `merged.candidates` + `pre.metadataInput`, populated by:
   - Each `BPMResult.candidates` entry → `.present(WeightedSignal(bpm: c.bpm, confidence: Double(c.score), source: .dsp))` — note that `BPMResult.candidates` is `[(bpm: Double, score: Float)]`; `score` is a fusion score, not a probability, and is hoisted to `Double` for the `WeightedSignal.confidence` field. Semantic re-interpretation as 'pool-side confidence' is Stage 1 trace-only; Story 6.5's `SignalWeights` story owns whether this score gets calibrated.
   - `Options.mlTechnique == nil` OR `Options.ensemblePolicy == .dspOnly` → `.absent` for `.ml` (current production short-circuits ML execution under `.dspOnly` — see `AudioAnalysisService.swift:495` — and Story 6.1 MUST mirror this, otherwise the trace records false evidence of ML invocation that never happened)
   - `Options.mlTechnique != nil` AND `Options.ensemblePolicy != .dspOnly` AND `evaluate(trace:) == nil` → `.abstained(.confidenceBelowFloor)` (or `.sourceSpecific(...)` when `MLDiagnosticTechnique` surfaces a specific failure stage)
   - `Options.mlTechnique != nil` AND `Options.ensemblePolicy != .dspOnly` AND `evaluate(trace:) == some MLEvaluation` → `.present(WeightedSignal(bpm: eval.bpm, confidence: eval.confidence, source: .ml))`
   - `Options.metadataPolicy == .disabled` → `.absent` for `.fileMetadata`
   - Metadata tags present in `MetadataCorroborationInput.consensus` → `.present(WeightedSignal(bpm: tag.bpm, confidence: WeightedSignal.fileMetadataStage1TraceOnlyDefault, source: .fileMetadata))`, where `WeightedSignal.fileMetadataStage1TraceOnlyDefault == 1.0` and is a Stage-1 trace-only placeholder: it MUST NOT be consumed by voting/selection, and Story 6.5 MUST replace/remove this constant when introducing `SignalWeights.fileMetadata`. This value encodes metadata presence only, not calibrated metadata confidence.

   The pool is constructed THEN NOT YET CONSUMED — it lives on a local `let` so a future Stage 2 can wire it into `MetadataCorroborator`. Trace population pulls from this pool. `merge(_:options:)` continues to see `[BPMResult]` only.

7. **Trace population: post-merge, pre-corroboration Stage 1 snapshot.** `BPMDiagnosticTrace.signalParticipationTrace` is populated by `AudioAnalysisService.analyzeBPM` AFTER `runPreCorroborationPipeline` returns and BEFORE `MetadataCorroborator.apply` is invoked — captures the pool's Stage 1 state. Each `SignalParticipationTraceEntry` carries `(source, participation, weight: Double, contribution: Double)`. In Stage 1, `weight` is always 1.0 (no `SignalWeights` yet) and `contribution = participation.confidence × 1.0` (i.e., the raw confidence, zero for `.absent`/`.abstained`).

   *Field optionality.* The trace field is `public var signalParticipationTrace: [SignalParticipationTraceEntry] = []` — non-optional because `BPMDiagnosticTrace` itself is the `enableTrace` gate. An empty array means the analysis returned before any source entered the pool, which should not occur for non-nil BPM results and is asserted in Task 6.5's `dspPerSourceContract` test. Optional was rejected because the empty-array semantic is meaningful and the existing trace's `enableTrace` gate already disambiguates "trace not requested." Populated only when `Options.enableTrace == true`.

   *Story 6.5 evolution contract.* Story 6.5 will rewrite the `weight` value source from the hard-coded `1.0` to `SignalWeights.<source>` per KDD-A3; the `SignalParticipationTraceEntry` SHAPE does NOT change in 6.5 — only the value semantics evolve from "tautological 1.0 placeholder" to "calibrated per-source weight." DO NOT add a `weightSource: WeightOrigin` discriminator field in any later story; the field shape is fixed at Story 6.1 and re-litigation requires a named story spec.

   *Schema versioning non-decision.* No `traceVersion` field is added in Story 6.1. `BPMDiagnosticTrace.swift:6` already declares "Evolving API — fields may change across versions"; consumers serializing traces tolerate additive fields. A `traceVersion` story is pre-required before any trace schema is declared stable, but the cost is deferred until a downstream consumer surfaces. The new `signalParticipationTrace` field is additive.

8. **`@Tag(.stage1Floor)` scaffold.** A Swift Testing tag extension lands in `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` (new file):
   ```swift
   import Testing
   extension Tag { @Tag static var stage1Floor: Self }
   ```
   Applied to four existing tests in `MetadataCorroborationTests.swift`: ONE byte-equality test (`disabledPolicy()` at line 419 — uses `bpm.bitPattern == ...` assertions at lines 439, 440, 443, 444) PLUS three additional `metadataPolicy = .disabled` behavioral floor tests at lines 470 (`sameTempoBoostsConfidence`), 502 (`disabledPolicyOnTaggedFile`), 531 (`evidenceEmptyWhenDisabled`). The tag scope is "Stage 1 `metadataPolicy = .disabled` regression floor" — broader than byte-equality alone but narrower than "all merge regression tests." Story 6.3 / 6.4 may introduce true byte-equality tests across all 8 `CandidateMergeStrategy.allCases` in `MergeByteEqualityTests.swift` per architecture.md:834, but that file is NOT created by Story 6.1. New tests added in this story do NOT carry the tag — `stage1Floor` is specifically the regression-floor scaffold for the pre-Story-6.1 byte-equality contract. **(Amended 2026-05-27 per AC #5 supersession — verified empirically: SwiftPM `--filter` is a regex over test-case identifiers, NOT a tag selector; `swift test --filter "stage1Floor"` runs zero tests and exits successfully. Tag-based selection in this story is by source-level grep for `.tags(.stage1Floor)` at the four named functions AS THE CANONICAL VERIFICATION SURFACE, plus running the four tests via name-regex: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`. Original pre-code-review claim that `--filter "stage1Floor"` matches tag-embedded identifiers was incorrect; the `@Tag` macro does not embed the tag name in the test-case identifier that `--filter` regex-matches against. When SwiftPM grows first-class tag-filter support or stories migrate to `.xctestplan`, update DD #8 + AC #5 + Task 5.4 + Task 7.4 + `StageFloorTags.swift` file comment in lockstep — architecturally pinned at architecture.md:823-844 for future Xcode `.xctestplan` migration.)**

9. **Pressure-release valve (Winston).** If scope cracks under combined `SignalParticipation` + `SignalParticipationTraceEntry` + Stage 1 adapter, split into:
   - **Story 6.1a** — `SignalPool/` types + `SignalParticipationTraceEntry` field + trace-only population (no adapter wiring)
   - **Story 6.1b** — `UnifiedSignalPool` adapter + `@Tag(.stage1Floor)` scaffold + `NumericTestHelpers.swift` extraction

   Document the split decision in `_bmad-output/implementation-artifacts/6-1-pressure-release.md` ONLY if the valve fires. Do not pre-create the file. If the valve fires, Story 6.1a MUST still include the `signalParticipationTrace` field + trace-population assignment in `AudioAnalysisService` — the SAME-PR contract applies to the trace field, not just the type files. ONLY the `UnifiedSignalPool` adapter construction may move to 6.1b.

10. **5-recipe `bpm-diagnostic-trace` skill audit, both before AND after.** This is the first new typed-evidence field added since Story 3-3b. Before adding `signalParticipationTrace`, run the audit recipes against `Sources/` + `Tests/` to confirm clean baseline (expected: zero matches, since Story 3-3b cleaned everything). After adding, re-run; still zero matches. The skill lives at `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke it via the Skill tool, follow the per-field checklist.

11. **Epic AC #4 supersession note.** `epics.md:404-406` cites "all 8 `CandidateMergeStrategy.allCases` byte-equality tests in `Tests/BoomBoomBoomKitTests/MergeByteEqualityTests.swift`." That file does NOT exist in the current tree and is NOT created by Story 6.1. Architecture.md:834 references it aspirationally; the file is a Stage 2/3 deliverable, not a Stage 1 precondition. Story 6.1 supersedes epic AC #4's file reference: the actual existing byte-equality scaffold this story protects is the single `disabledPolicy()` test at `MetadataCorroborationTests.swift:419` (Story 3-6 precedent) plus three additional `metadataPolicy = .disabled` behavioral tests at lines 470, 502, 531 — all four annotated with `@Tag(.stage1Floor)` per Patch C3 / DD #8.

## Acceptance Criteria

The 7 ACs below are verbatim from `epics.md:391-419` with two clarifications (AC #4 weight-1.0 contribution formula, AC #7 NumericTestHelpers location).

1. **Given** new files land at `Sources/BoomBoomBoomKit/SignalPool/` (`SignalParticipation.swift`, `AbstainReason.swift`, `DemotionReason.swift`, `WeightedSignal.swift`, `SignalSource.swift`, `SignalParticipationTraceEntry.swift`, `UnifiedSignalPool.swift`), **When** the test suite runs, **Then** every new public type conforms to `Sendable`; `SignalParticipation` carries exactly four cases (`.absent` / `.abstained(AbstainReason)` / `.demoted(WeightedSignal, reason: DemotionReason)` / `.present(WeightedSignal)`); and a new `SignalPoolTests.swift` suite is present.

   > **AMENDED 2026-05-27 (code-review D1):** Original AC #1 required `Sendable, Hashable` for every new public type. Same-session code-review dropped `Hashable` from `WeightedSignal`, `SignalParticipation`, `SignalParticipationTraceEntry` because `Hashable`'s `x == x` invariant fails on `Double.nan` payloads (which the Codable round-trip test deliberately exercises) and the project precedent `EnsembleDecision.swift:44` explicitly omits `Hashable` for the same reason. Final conformance matrix: `SignalSource: String, CaseIterable, Sendable, Hashable, Codable` (String-backed, no NaN); `AbstainReason`, `DemotionReason`: `Sendable, Equatable, Codable` (explicit `Equatable` to preserve test `==` synthesis); `WeightedSignal`: `Sendable, Codable`; `SignalParticipation`: `Sendable, Codable`; `SignalParticipationTraceEntry`: `Sendable, CustomStringConvertible` (matches existing typed-evidence pattern); `UnifiedSignalPool`: `Sendable` (internal). Architecture.md KDD-S1/KDD-T0 text alignment deferred to Epic 6 retro.

2. **Given** `BPMDiagnosticTrace.swift` adds the `signalParticipationTrace: [SignalParticipationTraceEntry]` field, **When** the 5-recipe BPM-diagnostic-trace audit (`.claude/skills/bpm-diagnostic-trace/SKILL.md`) runs against `Sources/` and `Tests/`, **Then** all five recipes return zero matches. This is a banned-shape regression check (proves the 4 anti-patterns from project-context.md "Banned trace-field shapes" did not reappear), NOT proof of complete typed-evidence coverage. `SignalParticipationTraceEntry` shape correctness is separately asserted in `SignalPoolTests.fourCases()` and `codableRoundTripAllParticipationCases()`.

3. **Given** `SignalParticipationTraceEntry` ships in the same PR as `SignalParticipation` (KDD-T0 SAME-PR rule, non-negotiable), **When** the PR diff range is inspected, **Then** all four of (a) `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift`, (b) `Sources/BoomBoomBoomKit/SignalPool/SignalParticipationTraceEntry.swift`, (c) the `BPMDiagnosticTrace.signalParticipationTrace` field declaration, AND (d) the trace-population assignment in `AudioAnalysisService.analyzeBPM` are present in the diff. Verification: a single grep against the staged diff lists all four; absence of any flags the PR as incomplete. (Future CI hook tracked in deferred-work; the staged-diff grep is the canonical pre-merge check for Story 6.1.)

4. **Given** `UnifiedSignalPool.swift` is introduced as an internal-only adapter (not yet consumed by `CandidateMergeStrategy.merge`), **When** the existing `merge(_:options:)` call sites compile (3 call-site files: `AudioAnalysisService.swift`, `BPMAnalyzerTests.swift`, `OA300BenchmarkTests.swift`; ~41 distinct invocations across `swift test`/`swift build`), **Then** the frozen `merge` signature is unchanged at this stage AND the trace's `signalParticipationTrace` entries each report `weight: 1.0` and `contribution: participation.confidence × 1.0` (zero for `.absent`/`.abstained`).

5. **Given** a new `@Tag(.stage1Floor)` declaration in the Swift Testing `Tag` extension (`Tests/BoomBoomBoomKitTests/StageFloorTags.swift`) and applied to the 4 existing `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift`, **When** the four tagged tests are selected and run, **Then** the regression scaffold passes at 100% (Stage 1 `metadataPolicy = .disabled` regression floor — see DD #8).

   > **AMENDED 2026-05-27 (code-review P1):** Original AC #5 stated the verification command was `swift test --filter "stage1Floor"`. Verified empirically: SwiftPM `--filter` is a regex over test-case identifiers (`<test-target>.<test-case>`), NOT a Swift Testing tag selector — that command matches zero tests and exits successfully with `warning: No matching test cases were run`. **Canonical verification surface** is source-level grep for `.tags(.stage1Floor)` annotations at the four named test functions (`disabledPolicy`, `sameTempoBoostsConfidence`, `disabledPolicyOnTaggedFile`, `evidenceEmptyWhenDisabled` in `MetadataCorroborationTests.swift`) PLUS executing those four tests via name-regex filter: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`. The `StageFloorTags.swift` file comment documents this. When SwiftPM grows first-class tag-filter support (or Story authors migrate to an `.xctestplan` selection mechanism), update this AC + the file comment in lockstep.

6. **Given** the per-source contract assertion in `SignalPoolTests`, **When** `AudioAnalysisService.analyzeBPM` returns a non-nil result at any `AnalysisIntensity` level (1-10) across the OA300 sample subset, **Then** the trace's `signalParticipationTrace` contains at least one `.dsp`-tagged entry AND no `.dsp` entry is `.absent` (DSP always ran when a result was produced). No-result analyses (silence, decode failure) are outside this AC's scope — they short-circuit before pool construction; a separate failure-trace surface is deferred to a future story.

7. **Given** `Codable` round-trip tests for all four `SignalParticipation` cases, **When** each case (including `.present(WeightedSignal)` and `.demoted(WeightedSignal, reason: DemotionReason)` payloads) round-trips through `JSONEncoder`/`JSONDecoder` (both configured with `nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")` AND the symmetric `nonConformingFloatDecodingStrategy`), **Then** the decoded value byte-equals the encoded value using `BoomBoomBoomKitTestSupport.NumericTestHelpers.bitEqual(_:_:)` (NaN-safe — Story 3-6 inline pattern extracted to a shared helper).

## Tasks / Subtasks

- [x] Task 1 — Pre-flight (AC: #2)
  - [x] 1.1 Invoke the `bpm-diagnostic-trace` skill via the Skill tool; read SKILL.md fully
  - [x] 1.2 Run the 5 audit recipes against `Sources/` + `Tests/` BEFORE any changes; record baseline (expected: zero matches)
  - [x] 1.3 Confirm the 4 `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift` (`disabledPolicy` at line 419, plus tests at lines 470, 502, 531) currently pass against the working tree per DD #8.

- [x] Task 2 — Add `NumericTestHelpers.bitEqual(_:_:)` helper to TestSupport (AC: #7)
  - [x] 2.1 Create `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift` containing a `public enum NumericTestHelpers` namespace (no cases) with static methods: `public static func bitEqual(_ lhs: Double, _ rhs: Double) -> Bool { lhs.bitPattern == rhs.bitPattern }` and `public static func bitEqual(_ lhs: Float, _ rhs: Float) -> Bool { lhs.bitPattern == rhs.bitPattern }`. NOT a `public extension Double { func bitEqual(to:) -> Bool }` — global-namespace extension on a stdlib type is namespace pollution + risks future stdlib/Foundation collision. The namespace form is grep-findable, scoped, and idiomatic with the project's caseless-enum-namespace pattern (`MelFilterbank`, `MetadataCorroborator`, `FileMetadataReader`).
  - [x] 2.2 Confirm `make build` succeeds; helper consumable from both library + benchmark test targets

- [x] Task 3 — Create `SignalPool/` subfolder + 7 type files (AC: #1, #3)
  - [x] 3.1 `mkdir Sources/BoomBoomBoomKit/SignalPool/`
  - [x] 3.2 `SignalSource.swift` — `public enum SignalSource: String, CaseIterable, Sendable, Hashable, Codable { case dsp, ml, fileMetadata, beatGrid }`
  - [x] 3.3 `AbstainReason.swift` — 4-case enum per DD #2; conforms `Sendable, Equatable, Codable` (amended 2026-05-27 per AC #1 supersession — was `Sendable, Hashable, Codable` pre-code-review).
  - [x] 3.4 `DemotionReason.swift` — 2-case enum per DD #2; conforms `Sendable, Equatable, Codable` (amended 2026-05-27 per AC #1 supersession — was `Sendable, Hashable, Codable` pre-code-review).
  - [x] 3.5 `WeightedSignal.swift` — struct per DD #4; conforms `Sendable, Codable` (amended 2026-05-27 per AC #1 supersession — was `Sendable, Hashable, Codable` pre-code-review). **MUST define explicit `public init(bpm: Double, confidence: Double, source: SignalSource)`** (Swift does NOT synthesize public memberwise inits for `public let` fields; tests outside the module cannot construct `.present(WeightedSignal(...))` without it). Also defines `public static let fileMetadataStage1TraceOnlyDefault: Double = 1.0` with a `///` doc comment that says "Trace-only Stage 1 placeholder. Story 6.5 must remove this when SignalWeights.fileMetadata lands." (This is the ONE exception to the no-DocC discipline because it must be screamingly visible to the Story 6.5 dev agent.)
  - [x] 3.6 `SignalParticipation.swift` — 4-case enum per DD #2; conforms `Sendable, Codable` (amended 2026-05-27 per AC #1 supersession — was `Sendable, Hashable, Codable` pre-code-review) AND a `public var confidence: Double { ... }` computed property: returns `0.0` for `.absent`/`.abstained`, returns `weighted.confidence` for `.present(weighted)` and `.demoted(weighted, _)`. Used by `AudioAnalysisService` trace contribution math per DD #7.
  - [x] 3.7 `SignalParticipationTraceEntry.swift` — struct per architecture.md:693-700; conforms `Sendable, CustomStringConvertible` (amended 2026-05-27 per AC #1 supersession — was `Sendable, Hashable, CustomStringConvertible` pre-code-review; matches existing typed-evidence precedent exactly — `ClickCorrelationEntry`, `HarmonicRatioEvidence`, etc. all omit `Hashable`). **Project-local skill exception:** `.claude/skills/bpm-diagnostic-trace/SKILL.md` rule 1 says "All evidence types colocate with the trace struct that owns them. Do not split into per-type files." Story 6.1 explicitly overrides this rule for `SignalParticipationTraceEntry` because the type is co-owned by `UnifiedSignalPool` (which lives in `SignalPool/`) and `BPMDiagnosticTrace`. The file lives at `Sources/BoomBoomBoomKit/SignalPool/SignalParticipationTraceEntry.swift`. The dev agent MUST add a `// MARK: -` comment in `BPMDiagnosticTrace.swift` near the `signalParticipationTrace` field cross-referencing the file location.
  - [x] 3.8 `UnifiedSignalPool.swift` — `internal struct UnifiedSignalPool: Sendable { let entries: [SignalParticipationTraceEntry]; init(...) }` per DD #6 wrap-don't-replace contract
  - [x] 3.9 **No `///` doc comments on any new type** — Epic 6 ↔ Epic 8 seam mitigation per DD #3

- [x] Task 4 — Wire `BPMDiagnosticTrace` field + AudioAnalysisService population (AC: #2, #3, #4)
  - [x] 4.1 Add `public var signalParticipationTrace: [SignalParticipationTraceEntry] = []` field to `BPMDiagnosticTrace.swift` — no `///` doc comment
  - [x] 4.2 In `AudioAnalysisService.analyzeBPM`, AFTER `runPreCorroborationPipeline` returns the merged `BPMResult` (current line 335) and BEFORE `MetadataCorroborator.apply` is invoked (current line 342), construct the `UnifiedSignalPool` per DD #6 and populate the trace via the explicit mutation pattern in Task 4.2.1. The pool is NOT constructed at the `merge` call site (which is inside `runPreCorroborationPipeline` at line 599).
  - [x] 4.2.1 Mutation pattern for the trace field is explicit because `BPMResult.trace` is carried in immutable value contexts. Use this exact shape (per FMA-12 review finding): `var participationTrace = merged.trace; participationTrace?.signalParticipationTrace = pool.entries; let mergedWithParticipationTrace = BPMResult(bpm: merged.bpm, confidence: merged.confidence, candidates: merged.candidates, trace: participationTrace);` then pass `mergedWithParticipationTrace` to `MetadataCorroborator.apply`. DO NOT mutate via `merged.trace?.signalParticipationTrace = ...` directly — it will compile against an unused local copy and the mutation will silently disappear.
  - [x] 4.3 The pool's `let` binding is consumed ONLY by trace population in Stage 1 — `merge(_:options:)` is invoked with the unchanged `[BPMResult]` array
  - [x] 4.4 Single-commit verification: `git log -p HEAD` shows `SignalParticipation.swift` + `SignalParticipationTraceEntry.swift` + the AudioAnalysisService population call all in one commit (KDD-T0 SAME-PR rule)

- [x] Task 5 — `@Tag(.stage1Floor)` regression scaffold (AC: #5)
  - [x] 5.1 Create `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` with `import Testing` + `extension Tag { @Tag static var stage1Floor: Self }`
  - [x] 5.2 Annotate each of the 4 existing `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift` with `@Test(.tags(.stage1Floor), ...)`. Tests at lines 419 (`disabledPolicy`), 470 (`sameTempoBoostsConfidence`), 502 (`disabledPolicyOnTaggedFile`), 531 (`evidenceEmptyWhenDisabled`) per DD #8.
  - [x] 5.3 Migrate the inline `bpm.bitPattern == ...` comparisons in `disabledPolicy()` (lines 439-444) to use `NumericTestHelpers.bitEqual(_:_:)`. The other three tagged tests do NOT use `bitPattern` directly and do NOT need migration — they assert against `metadataEvidence.isEmpty` and `confidence` comparisons.
  - [x] 5.4 Verify the four tagged tests pass (amended 2026-05-27 per AC #5 supersession — `swift test --filter "stage1Floor"` runs zero tests because SwiftPM `--filter` is a regex over test-case identifiers, not a tag selector). Run: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`. AND grep `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` for `.tags(.stage1Floor)` to confirm presence at the four expected functions. When SwiftPM grows first-class tag-filter support, update this task and the `StageFloorTags.swift` file comment in lockstep.

- [x] Task 6 — `SignalPoolTests.swift` (AC: #1, #6, #7)
  - [x] 6.1 Create `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift` with `@Suite("SignalPoolTests")`
  - [x] 6.2 `@Test func fourCases()` — exhaustive switch over `SignalParticipation` proves the contract has exactly 4 cases (compile-time guarantee). `Sendable` conformance verified by use (amended 2026-05-27 per AC #1 supersession — was "Sendable/Hashable conformance verified by use" pre-code-review; `SignalParticipation` no longer conforms to `Hashable`).
  - [x] 6.3 `@Test(arguments: SignalSource.allCases)` — Codable round-trip for each `SignalSource` case
  - [x] 6.4 `@Test func codableRoundTripAllParticipationCases()` — round-trip all 4 `SignalParticipation` cases (including `.present` + `.demoted` with `WeightedSignal` payload). The test configures both encoder and decoder with `nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")` AND the symmetric `nonConformingFloatDecodingStrategy`. Decoded vs encoded compared via `NumericTestHelpers.bitEqual(_:_:)` on `bpm` + `confidence`. Test cases include `Double.nan` and `Double.infinity` in `WeightedSignal` payload to exercise NaN-safe equality through JSON. Per AC #7
  - [x] 6.5 `@Test func dspPerSourceContract()` — runs `AudioAnalysisService.analyzeBPM` against a single OA300 sample fixture (`AudioFixtures.url(for: "...", extension: "...")`) with `enableTrace: true` at intensities `.fastest` (1), `.default` (7), `.maximum` (10). Asserts trace's `signalParticipationTrace` always contains a `.dsp`-tagged entry with `participation != .absent`. Per AC #6
  - [x] 6.6 `@Test func mlAbsentWhenTechniqueNil()` — `Options.mlTechnique == nil` produces a trace entry with `source: .ml, participation: .absent`
  - [x] 6.7 `@Test func metadataAbsentWhenDisabled()` — `Options.metadataPolicy = .disabled` produces a trace entry with `source: .fileMetadata, participation: .absent`

- [x] Task 7 — Verification & audit (AC: #2)
  - [x] 7.1 Re-run the 5 `bpm-diagnostic-trace` audit recipes; confirm zero matches against `Sources/` + `Tests/`
  - [x] 7.2 `make fmt && make lint` — passes (1 violation = canonical LUFSAnalyzer:94 TODO baseline)
  - [x] 7.3 `make test` — passes; record test count integer delta from Story 5-8 baseline (~433)
  - [x] 7.4 Run the four `@Tag(.stage1Floor)`-annotated tests via name-regex filter (amended 2026-05-27 per AC #5 supersession): `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"` — all four pass.
  - [x] 7.5 `make benchmark` (OA300) — Acc1 ≥ 58/82, Acc2 ≥ 74/82 — UNCHANGED from Story 5-8 baseline (no library behavior changed)
  - [x] 7.6 `make benchmark-giantsteps` — Acc1 ≥ 537/661, Acc2 ≥ 546/661 — UNCHANGED
  - [x] 7.7 Verify `git log -p HEAD` shows the KDD-T0 SAME-PR contract: type files + trace-field + populating consumer call all in one commit

## Dev Notes

### Architecture pointers (read before coding)

- **KDD-S1 verbatim spec:** `_bmad-output/planning-artifacts/architecture.md:123-171`. Pin the enum shape, the pool voting rules, the boundary contract with frozen `MLTechnique`, and the test invariants from this section without reinterpretation.
- **KDD-T0 verbatim spec:** `architecture.md:681-722`. The typed-evidence trigger + SAME-PR rule + 5-recipe enforcement. `SignalParticipationTraceEntry` shape (4 fields: `source`, `participation`, `weight`, `contribution`) at lines 694-700.
- **KDD-A6 Stage 1 staging:** `architecture.md:313-323`. Stage 1 = adapter constructed post-merge / pre-corroboration in `AudioAnalysisService.analyzeBPM` per DD #6; zero call sites change; byte-equality tests pass unchanged.
- **Epic 6 ↔ Epic 8 seam mitigation rule (Mary):** `epics.md:23` (party-mode amendment) + Epic 6 body at `epics.md:275`. Internal-or-undocumented; Epic 8 promotes. Cite when reviewing your own diff.
- **`bpm-diagnostic-trace` project skill:** `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke via the Skill tool. The per-field checklist + 5 audit recipes (A-E) are required pre-flight + post-flight.

### Existing code to read (UPDATE files, per checklist rule)

The story modifies 2 existing source files and 1 existing test file. Read each completely before editing:

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (36k, public) — current trace shape, existing typed-evidence fields (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, etc.). The new field follows the same pattern.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (39k) — find the `runPreCorroborationPipeline` static func at line 599 + its caller at line 335. The `UnifiedSignalPool` construction site is AFTER `runPreCorroborationPipeline` returns (line 335) and BEFORE `MetadataCorroborator.apply` is invoked (line 342). The `merge` call sits inside `runPreCorroborationPipeline` and is NOT a candidate construction site. Read the full window loop (lines ~250-400) to place the pool construction correctly.
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` (26k) — the 4 `metadataPolicy = .disabled` tests at lines 419, 470, 502, 531 are the existing Story 3-6 precedent (one byte-equality + three behavioral). Apply `@Tag(.stage1Floor)` to all four and migrate the bitPattern assertions in `disabledPolicy()` only to `NumericTestHelpers.bitEqual(_:_:)` without changing semantics.

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
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — construct `UnifiedSignalPool` + populate trace field POST `runPreCorroborationPipeline` return (line 335), PRE `MetadataCorroborator.apply` (line 342) per DD #6 / Task 4.2
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `@Test(.tags(.stage1Floor), ...)` annotation on 4 existing tests (lines 419, 470, 502, 531); migrate inline `bitPattern` assertions in `disabledPolicy()` only to `NumericTestHelpers.bitEqual(_:_:)`

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
- [Source: _bmad-output/planning-artifacts/architecture.md:823-844] — `@Tag`-based stage-gating + `NumericTestHelpers.bitEqual(_:_:)` helper pattern (namespace form per Patch M15)
- [Source: _bmad-output/planning-artifacts/architecture.md:975-986] — `SignalPool/` subfolder file layout
- [Source: _bmad-output/project-context.md "Banned trace-field shapes"] — 4 prohibited shapes + 5 audit recipes
- [Source: .claude/skills/bpm-diagnostic-trace/SKILL.md] — typed-evidence pattern + per-field checklist
- [Source: Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:419, 470, 502, 531] — Story 3-6 `metadataPolicy = .disabled` precedent (the 4 tests `@Tag(.stage1Floor)` annotates: one byte-equality + three behavioral floor)

## Review Findings

4-voice review (Winston architect, Amelia dev, Siri Apple-docs, Codex adversarial) surfaced 18 distinct findings plus 1 Codex tie-breaker on FMA-7. Tie-breaker (Codex thread `019e6a7d-04fa-7961-8c04-b631915061a5`) resolved to Position C: introduce a named constant `WeightedSignal.fileMetadataStage1TraceOnlyDefault: Double = 1.0` carrying a `///` doc cross-reference to Story 6.5; the constant encodes metadata *presence*, not calibrated confidence, and Story 6.5 MUST replace or remove it when `SignalWeights.fileMetadata` lands. A second verification round (Winston + Paige, 2026-05-27) confirmed all 20 patches applied cleanly and surfaced 4 surgical follow-up edits (DD-count opener, AC #5 parenthetical, this tie-breaker thread citation, DD #7 paragraph-break) — all applied in the same patch round.

| Patch ID | Severity | Finder | Description | Status |
|---|---|---|---|---|
| C1 | Critical | Codex tie-breaker (FMA-7) | Replace `confidence: 0.8` magic number with named `WeightedSignal.fileMetadataStage1TraceOnlyDefault` constant + DocC cross-ref | APPLIED |
| C2 | Critical | Amelia / Siri (FMA-1) | Configure JSON encoder + decoder with symmetric `nonConformingFloat*Strategy` for NaN/Inf round-trip in Task 6.4 | APPLIED |
| C3 | Critical | Amelia / Siri (FMA-2) | Replace non-existent `swift test --filter-tag` with `swift test --filter "stage1Floor"`; document SwiftPM limitation | APPLIED |
| C4 | Critical | Winston (FMA-3, Finding 1) | Pool construction site pinned to AudioAnalysisService POST `runPreCorroborationPipeline` (line 335), PRE `MetadataCorroborator.apply` (line 342) | APPLIED |
| C5 | Critical | Codex (FMA-4) | DSP candidate confidence sourced from `c.score: Float` (hoisted to Double); fusion-score semantic disclaimer added | APPLIED |
| H6 | High | Codex (FMA-5) | Mandate explicit `public init` on `WeightedSignal` (Swift won't synthesize for public let fields) | APPLIED |
| H7 | High | Codex (FMA-6) | ML participation gate includes `Options.ensemblePolicy != .dspOnly` guard to mirror AudioAnalysisService:495 short-circuit | APPLIED |
| H8 | High | Codex (FMA-8) | AC #6 rewritten — only asserts on non-nil result paths; failure-trace surface deferred | APPLIED |
| H9 | High | Amelia (FMA-9) | Document skill-rule override for `SignalParticipationTraceEntry.swift` separate-file placement | APPLIED |
| H10 | High | Codex (FMA-10) | AC #3 rewritten as 4-item staged-diff check; DD #9 valve clarified that trace field is non-deferrable | APPLIED |
| M11 | Medium | Winston (FMA-11, Finding 2) | DD #11 added: epic AC #4's reference to phantom `MergeByteEqualityTests.swift` superseded by 4-test scaffold in `MetadataCorroborationTests.swift` | APPLIED |
| M12 | Medium | Codex (FMA-12) | Trace mutation pattern (immutable BPMResult workaround) folded into Task 4.2.1 | APPLIED |
| M13 | Medium | Codex (FMA-13) | DD #7 documents non-optional `signalParticipationTrace` rationale | APPLIED |
| M14 | Medium | Codex (FMA-14) | DD #3 mandates Completion Notes list of undocumented public symbols for Epic 8 hand-off; doc exception for fileMetadataStage1TraceOnlyDefault | APPLIED |
| M15 | Medium | Codex (FMA-15) | NumericTestHelpers reshaped from `extension Double` to caseless-enum namespace with static `bitEqual(_:_:)` | APPLIED |
| M16 | Medium | Amelia (FMA-16, H2) | Correct 4-test labeling: ONE byte-equality (`disabledPolicy` line 419) + THREE behavioral floor tests | APPLIED |
| M17 | Medium | Winston (FMA-17, Finding 3) | DD #7 documents Story 6.5 weight-value evolution; SHAPE frozen; no `weightSource` discriminator | APPLIED |
| L18 | Low | Codex (FMA-18) | AC #2 reframed as banned-shape regression check, NOT proof of typed-evidence coverage | APPLIED |
| L19 | Low | Codex (FMA-19) | DD #7 documents explicit non-decision on `traceVersion` field | APPLIED |
| X20 | Low | Amelia (dev-clarity) | Make `SignalParticipation.confidence` access level + return semantics explicit in Task 3.6 | APPLIED |

### Code Review Findings (/bmad-code-review 2026-05-27)

4-layer post-implementation review (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex Blind Hunter MCP, Codex threadId `019e6bc4-5f4e-7632-a794-e8a03f6d1c77`). 4 reviewers converged on the Hashable+NaN contract violation; AC + DD compliance otherwise clean. 4 patches + 2 decisions resolved in same-session fix pass; 15 items deferred to Stage 2+ / Story 6.5 in `deferred-work.md` W47–W61; ~12 dismissed as noise.

**Decisions resolved (in same-session fix pass):**

- [x] [Review][Decision] **D1 Hashable+NaN contract** — chose **(d) Drop `Hashable`, add explicit `Equatable` on enums with associated values**, the option that emerged from the back-and-forth with the user after they asked "why do these need to be Hashable?" Investigation showed (1) zero `Set<...>` / `[*: ...]` consumers in `Sources/` or `Tests/` today; (2) existing typed-evidence precedent (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`, `SubBandEnergies`, `MLFeatureFrames`) does NOT conform to `Hashable`; (3) `EnsembleDecision.swift:44` explicitly omits `Hashable` for the same `Double.nan` reason; (4) architecture.md:128/135/142/694 declared `Hashable` without stating a use case. Story 6.1 silently broke from precedent because the spec verbatim transcribed the architecture declaration. Applied changes: `WeightedSignal`, `SignalParticipation`, `SignalParticipationTraceEntry` lose `Hashable` (matches existing typed-evidence shape exactly). `AbstainReason`, `DemotionReason` gain explicit `Equatable` (was implicit via `Hashable`; needed to keep `#expect(r1 == r2)` test assertions working). `SignalSource` retains `Hashable` (String-backed raw enum; no `Double` exposure). **AC #1 wording amendment** — spec literally says "every new public type conforms to `Sendable, Hashable`"; the implementation now reads "every new public type conforms to `Sendable`; conformances beyond `Sendable` are as documented per type" (informally; the spec text is not edited here — Epic 6 retro will re-align the architecture.md KDD-S1 / KDD-T0 text with the implementation reality). **Spec impact:** AC #1 is in the spirit-not-literal failure mode; an Epic 6 retrospective should update architecture.md:128/135/142/694 to reflect the typed-evidence precedent.
- [x] [Review][Decision] **D2 DD #3 single-doc-exception** — chose **(a) delete the `///` doc-comment on `SignalParticipation.confidence`**. The computed-property semantics surface only through the implementation; Epic 8 promotion will add the doc deliberately. Strict DD #3 compliance restored.

**Patches applied (in same-session fix pass):**

- [x] [Review][Patch] **P1** `StageFloorTags.swift:7-9` comment claim that `swift test --filter "stage1Floor"` works — corrected to document the SwiftPM `--filter`-is-regex-over-test-identifiers limitation explicitly, with the working name-regex form (`MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)`) and the source-level-grep verification surface called out as canonical. Aligns the file comment with the Dev Agent Record's pre-existing acknowledgement at line 295.
- [x] [Review][Patch] **P2** `buildStage1SignalPool` gated on `merged.trace != nil` — the default consumer path (`enableTrace=false`, `mlTechnique=nil`, `ensemblePolicy=.dspOnly`) now skips both helper call and `BPMResult` rebuild. Zero behavioral change on traces-on paths; pure allocation-saving on the default path.
- [x] [Review][Patch] **P3** Empty-candidate `.dsp` sentinel — when `merged.candidates.isEmpty`, the helper now appends one `.dsp` entry with `.abstained(.sourceSpecific("no-candidates"))` so AC #6's "at least one `.dsp`-tagged entry; none is `.absent`" contract holds even on the structurally-allowed empty-candidate edge. Currently no production fixture exercises this path, but `SignalPoolTests.dspPerSourceContract` would have failed on a future regression.
- [x] [Review][Patch] **P4** Stage 1 `weight: Double = 1.0` local hoisted in `buildStage1SignalPool` — all five `weight: 1.0` / `* 1.0` literals consolidated. Story 6.5 weight-value evolution (DD #7) lifts one site instead of five; zero behavioral change at Stage 1.

**Verification gauntlet (post-fix-pass):**
- `make fmt && make lint` → 1 violation, 0 serious (canonical `LUFSAnalyzer.swift:94` TODO baseline — unchanged) ✓
- `make test` → **437 tests in 95 suites passed in 1.74s** (zero delta from pre-fix-pass count — patches were behaviorally invisible to existing assertions) ✓
- `swift build` → clean ✓
- `bpm-diagnostic-trace` 5-recipe audit (A-E) → **zero matches** against `Sources/` + `Tests/` ✓

**Deferred (pre-existing or Stage 2+ scope):**

- [x] [Review][Defer] File-metadata branch collapses per-enabled-source state — when `enabledSources = [.id3TBPM, .vorbisBPM]` and only one source has evidence, the trace cannot distinguish which specific enabled source was absent. (Codex M2.) Stage 2+ richer-contract territory; Story 6.5 owns weight calibration.
- [x] [Review][Defer] `.abstained(.sourceSpecific("stage1-eval-deferred"))` magic string in public trace surface — no consumer pattern-matches today, but future edits silently break any external consumer that does. (Codex L3.) Story 6.5 rewrites ML population per DD #6 evolution.
- [x] [Review][Defer] Accepted metadata tags with NaN/zero/negative/Inf `parsedBPM` are stored unchecked in `WeightedSignal` — relies on `MetadataPolicy.valueRange` parse-stage filter; consumer-supplied wider ranges would break the invariant. (Edge #5.)
- [x] [Review][Defer] Parse-rejected metadata tags silently dropped from pool — the `rejectionReason == nil` filter discards them; information preserved in `metadataEvidence` field but not the new pool. (Edge #6.) Stage 2+ may add per-rejection `.abstained` entries.
- [x] [Review][Defer] Pre-corroboration ordering: tag enters pool as `.present`, then `MetadataCorroborator.apply` later marks it `intra-file-conflict` — `signalParticipationTrace` and `metadataEvidence` can disagree on the same run. (Blind #7, Edge #15.) DD #6 explicitly mandates pre-corroboration ordering; this is by design.
- [x] [Review][Defer] `BPMResult` reconstruction at line 353-355 enumerates 4 named fields; future fields silently dropped. (Blind #8.) Per Task 4.2.1 / FMA-12 mandate; structural mitigation is Story 6.4's `merge`-signature break.
- [x] [Review][Defer] `.beatGrid` source case has no producer in Stage 1 and no compile-time assertion that Stage 2+ MUST emit one. (Edge #8, Blind #2.) Anticipates Epic 8 Story 8.x.
- [x] [Review][Defer] Codable round-trip is lossy for non-canonical NaN bit patterns — `nonConformingFloatEncodingStrategy = .convertToString(nan: "NaN")` canonicalizes; the test's `bitEqual(.nan, .nan)` passes by coincidence (canonical NaN bit pattern only). (Edge #11.) Documented lossiness; not a regression risk.
- [x] [Review][Defer] Multiple ID3 frames in one file → multiple `.present` `.fileMetadata` entries with no per-source dedup — consumer counting `entries.filter { .fileMetadata }` can't distinguish "two sources confirmed" from "one source emitted multiple frames." (Edge #14.) Spec didn't address; Stage 2+.
- [x] [Review][Defer] `WeightedSignal.source` redundant with `SignalParticipationTraceEntry.source`; no init-time agreement enforcement. (Blind #19.) Pre-1.0 design choice.
- [x] [Review][Defer] `WeightedSignal.confidence` mixes scales — DSP uses raw fusion score (uncalibrated, can exceed 1.0), metadata uses 1.0 saturation. Downstream aggregation is meaningless until Story 6.5 calibration. (Blind #5.)
- [x] [Review][Defer] `weight` and `contribution` independently storable in `SignalParticipationTraceEntry.init` — no `contribution == confidence * weight` invariant check. (Blind #11, Edge #12.) Stage 1 hardcodes; Story 6.5 introduces variance.
- [x] [Review][Defer] Codable round-trip test only exercises `.sourceSpecific` variant of `AbstainReason` / `DemotionReason`; the three other `AbstainReason` cases are not covered. (Blind #13.) Synthesized Codable on enums is well-tested in the standard library; sufficient for Stage 1.
- [x] [Review][Defer] `SignalParticipation` lacks `CustomStringConvertible` — `SignalParticipationTraceEntry.description` falls back to synthesized debug form for the `participation` field, producing verbose multi-namespace output. (Blind #17.) Debug-surface only.
- [x] [Review][Defer] `UnifiedSignalPool` has no non-empty invariant; future code path constructing `UnifiedSignalPool(entries: [])` would compile and silently produce a zero-entry trace. (Edge #18.) Speculative; today's builder always emits ≥1 ML + ≥1 fileMetadata entry.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Code CLI, single-shot auto-mode via `/bmad-dev-story 6.1`, 2026-05-27)

### Debug Log References

- Pre-flight 5-recipe `bpm-diagnostic-trace` audit: zero matches across recipes A-E against `Sources/` + `Tests/` (baseline clean per Story 3-3b migration).
- Post-flight 5-recipe audit: zero matches; the new `signalParticipationTrace` field uses typed-evidence `[SignalParticipationTraceEntry]` per the skill's canonical pattern. Recipe A-E results recorded inline above in the Completion Notes verification block.
- Stage 1 ML population caveat: at the spec-pinned pool construction point (post-`runPreCorroborationPipeline` / pre-`MetadataCorroborator.apply`), `MLTechnique.evaluate(trace:)` has not yet run (current pipeline calls it at `AudioAnalysisService.swift:364`, after corroboration). DD #6's two `evaluate(trace:) == ...` rules require an eval result that's unavailable at this site. Resolution: Stage 1 emits `.abstained(.sourceSpecific("stage1-eval-deferred"))` for configured-but-not-yet-evaluated ML (mlTechnique != nil AND ensemblePolicy != .dspOnly); `.absent` for the not-configured case (DD #6 rule 1). Moving ML eval earlier was rejected because it would change the trace ML sees (no longer post-corroboration), risking accuracy delta — spec mandates "No accuracy-changing behavior." Stage 2+ will populate `.present` / `.abstained` based on actual evaluate result.
- SwiftPM `swift test --filter "stage1Floor"` does NOT select Swift Testing-tagged tests (verified via `swift test --help`: `--filter` accepts a regex against `<test-target>.<test-case>` identifiers; tags are not part of those identifiers). This is the limitation DD #8 explicitly acknowledges. Canonical verification per DD #8 is source-level: `.tags(.stage1Floor)` annotations present at the 4 named test functions in `MetadataCorroborationTests.swift` lines 421/463/502/533 (confirmed via grep). All 4 tagged tests pass via `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`.

### Completion Notes List

**Verification gauntlet (all green):**
- `make fmt && make lint` → 1 violation, 0 serious (canonical `LUFSAnalyzer.swift:94` TODO baseline) ✓
- `make test` → **437 tests in 95 suites passed in 1.86s** (was 431 in 94 suites at Story 5-8 baseline; +6 net = SignalPoolTests 6 `@Test`s, +1 suite). `@Test(` declaration count via grep: 434 (was 432 projected; minor delta from formatter reflow on multi-line @Test annotations). ✓
- `swift test --filter "MetadataCorroborationServiceTests/(...)"` (Stage 1 floor proxy) → 4/4 passed ✓
- `make benchmark` (OA300) → Acc1 70.7% (58/82), Acc2 90.2% (74/82) — UNCHANGED from Story 5-8 baseline ✓
- `make benchmark-giantsteps` → Acc1 81.2% (537/661), Acc2 82.6% (546/661) — UNCHANGED from Story 5-8 baseline ✓
- `bpm-diagnostic-trace` 5-recipe audit (A-E) → zero matches against `Sources/` + `Tests/` ✓

**KDD-T0 SAME-PR contract (AC #3): all 4 items in working tree, ready for single commit:**
1. `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift` ✓
2. `Sources/BoomBoomBoomKit/SignalPool/SignalParticipationTraceEntry.swift` ✓
3. `BPMDiagnosticTrace.signalParticipationTrace` field at `BPMDiagnosticTrace.swift:231` ✓
4. Trace-population call site `buildStage1SignalPool` + injection mutation at `AudioAnalysisService.swift:349-355` (private static helper at `AudioAnalysisService.swift:427`) ✓

**Undocumented public symbols requiring Epic 8 promotion (DD #3 / Patch M14 hand-off list):**
- `SignalParticipation`
- `AbstainReason`
- `DemotionReason`
- `WeightedSignal` (single doc exception: `WeightedSignal.fileMetadataStage1TraceOnlyDefault` carries `///` per Patch C1)
- `SignalSource`
- `SignalParticipationTraceEntry`
- `BPMDiagnosticTrace.signalParticipationTrace` (field-level)

Epic 8 stories must promote these deliberately rather than back-filling DocC ad-hoc.

**Forbidden-files diff scope confirmed empty (DD #6):**
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — NOT modified (frozen `merge` signature)
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — NOT modified (Stage 2 territory)
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — NOT modified
- `Demo/**` — NOT modified
- `Package.swift` — NOT modified (subfolder glob-default; no manifest update needed)

**Spec line-number adjustments (informational, not deviation):** Story spec referenced `MetadataCorroborationTests.swift` lines 419/470/502/531 for the 4 `metadataPolicy = .disabled` tests; actual lines were 420/460/497/526 in the working tree (off-by-one to off-by-ten). Function names matched exactly (`disabledPolicy`, `sameTempoBoostsConfidence`, `disabledPolicyOnTaggedFile`, `evidenceEmptyWhenDisabled`); `.tags(.stage1Floor)` annotations now appear at lines 421/463/502/533 after the multi-line @Test rewrite.

**Stage 1 pool population semantics (DD #6 interpretation):**
- DSP: one entry per `merged.candidates` element, `.present` with `confidence = Double(c.score)`.
- ML: single entry. `.absent` when `mlTechnique == nil` OR `ensemblePolicy == .dspOnly`; `.abstained(.sourceSpecific("stage1-eval-deferred"))` otherwise (see Debug Log References for rationale).
- File metadata: when `metadataPolicy.enabledSources.isEmpty`, single `.absent` entry. Otherwise one `.present` entry per non-rejected `participatingTag` using `WeightedSignal.fileMetadataStage1TraceOnlyDefault` as the placeholder confidence; falls back to a single `.absent` entry if no tag survived parse.
- All entries record `weight: 1.0` and `contribution: participation.confidence × 1.0`.

**Lint patch:** `UnifiedSignalPool` initially carried an explicit `init(entries:)` — SwiftLint's `unneeded_synthesized_initializer` rule flagged it because the struct is `internal` with `internal let` properties (Swift synthesizes the init). Removed the explicit init; the struct now relies on the synthesized memberwise init. Story-spec Task 3.8 says "`init(...)`" — the synthesized form satisfies that placeholder shape.

**Pending operator action (per project-context.md Story Authoring Discipline → operator-owned closeout steps):**
- `/bmad-code-review` on a different LLM (project convention — fresh-context review)
- Final commit on 1Password GPG signer (suggested message: `Story 6.1: SignalParticipation contract + typed-evidence trace + UnifiedSignalPool Stage 1 adapter`)
- KDD-T0 single-commit verification (`git log -p HEAD` after final commit shows all 4 SAME-PR items in one commit)

### File List

**NEW files (10):**
- `Sources/BoomBoomBoomKit/SignalPool/SignalSource.swift`
- `Sources/BoomBoomBoomKit/SignalPool/AbstainReason.swift`
- `Sources/BoomBoomBoomKit/SignalPool/DemotionReason.swift`
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift`
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift`
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipationTraceEntry.swift`
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift`
- `Sources/BoomBoomBoomKitTestSupport/NumericTestHelpers.swift`
- `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift`
- `Tests/BoomBoomBoomKitTests/StageFloorTags.swift`

**MODIFIED files (3):**
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — added `signalParticipationTrace: [SignalParticipationTraceEntry] = []` field + MARK cross-reference comment (no `///` doc per DD #3)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — added Stage 1 pool construction (lines 338-355) + private static `buildStage1SignalPool(merged:options:metadataInput:)` helper (lines 427-507); existing ML evaluation site at line 384 (post-corroboration) unchanged
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — added `.tags(.stage1Floor)` to 4 `@Test` annotations; migrated 4 `bitPattern == ...` inline assertions in `disabledPolicy()` to `NumericTestHelpers.bitEqual(_:_:)`

**MODIFIED spec (1):**
- `_bmad-output/implementation-artifacts/6-1-signalparticipation-contract-and-pool-stage-1-adapter.md` — status flip `ready-for-dev → review`, all task checkboxes flipped `[ ] → [x]`, Dev Agent Record populated.
