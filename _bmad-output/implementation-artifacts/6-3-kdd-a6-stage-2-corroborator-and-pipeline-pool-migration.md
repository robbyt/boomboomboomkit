---
baseline_commit: 89b6ff5c1426b02f374071919c643cdf0208e7c7
---

# Story 6.3: KDD-A6 Stage 2 — migrate MetadataCorroborator + runPreCorroborationPipeline to consume the unified pool

Story ID: 6.3
Story Key: 6-3-kdd-a6-stage-2-corroborator-and-pipeline-pool-migration
Epic: 6 — Unified-signal-pool ensemble (Tier-1 boundary collapse, third of 5 strictly-sequenced stories)
Status: done

## Story

**As a** library maintainer,
**I want** `runPreCorroborationPipeline` to build and emit the `UnifiedSignalPool` as the threaded data shape, and `MetadataCorroborator` to own production of the file-metadata `SignalParticipation` entries via an internal helper,
**So that** the unified pool moves from a post-hoc trace artifact (bolted on in `AudioAnalysisService.analyzeBPM` by `buildStage1SignalPool`) into the pipeline itself — advancing KDD-A6 toward the Stage 3 carrier flip — while the frozen `CandidateMergeStrategy.merge` 41-call-site signature stays untouched, `EnsembleCombiner` is untouched, and the byte-equality regression scaffold (now carrying BOTH `@Tag(.stage1Floor)` AND `@Tag(.stage2Floor)`) stays green at the Stage 1 measurement.

## Scope clarification (read first)

Story 6.3 is the **Stage 2 boundary-migration PR of Epic 6** (Tier-1 root #3 per architecture.md:282, S1 → S2 → A6 → A1 sequence). It is intentionally narrow and **behaviorally inert** — its entire job is to relocate where the unified pool is produced and to give `MetadataCorroborator` ownership of metadata participation, WITHOUT changing any output byte.

**This story delivers a DATA-SHAPE migration only.** The substantive consumer (metadata as a true peer voter inside `merge`) fires in Story 6.4, not here. Per the epic's own FR-7 coverage note: "FR-7 (data-shape migration; substantive consumer fires in Story 6.4)."

**Three deliverables in this PR (none separable):**

1. **`runPreCorroborationPipeline` builds and emits the `UnifiedSignalPool`** — `PreCorroborationOutput` gains a `pool: UnifiedSignalPool?` field; the pool is constructed at the end of the pipeline (post-merge), gated on `enableTrace`. `analyzeBPM` consumes `pre.pool` instead of calling `buildStage1SignalPool` post-hoc.
2. **`MetadataCorroborator` owns metadata `SignalParticipation` production** — the file-metadata branch of the former `buildStage1SignalPool` is extracted into an internal `MetadataCorroborator` helper that emits the metadata `SignalParticipationTraceEntry` values for each parsed tag. This honors epic AC #1's "MetadataCorroborator emits SignalParticipation values for each parsed metadata tag via an internal helper" — WITHOUT removing `apply(to:input:)` (see DD #1 supersession).
3. **`@Tag(.stage2Floor)` regression scaffold** — added to `StageFloorTags.swift` and applied to the SAME four `metadataPolicy = .disabled` tests already carrying `@Tag(.stage1Floor)`. Stage 2 floor = Stage 1 measurement.

**What this story does NOT deliver** (each is explicitly OUT-OF-SCOPE):

- **No removal of `MetadataCorroborator.apply(to:input:)`.** Its signature `apply(to: BPMResult, input: MetadataCorroborationInput) -> (BPMResult, [MetadataBPMEvidence])` is UNCHANGED. Epic AC #1's "no more apply(to:input:) method" is **superseded** per DD #1 — removal lands Story 6.4 alongside the carrier flip. (Codex consult thread `019e709a-21b3-7551-91b6-9ee89b92f2ba` + project-lead directive 2026-05-28.)
- **No change to `CandidateMergeStrategy.merge` signature.** Frozen at `merge(windowResults:candidateCount:strategy:votingPolicy:votingThreshold:) -> BPMResult?`. The carrier-type flip is Story 6.4 (KDD-A6 Stage 3).
- **No `UnifiedSignalPool` enrichment with a Float candidate-score payload.** The pool stays trace-shaped (`entries: [SignalParticipationTraceEntry]`). The corroborator's boost/re-select math continues to read `BPMResult.candidates: [(bpm: Double, score: Float)]` directly. Enriching the pool to carry the operative Float score is Story 6.4's job — doing it here introduces a `Float → Double → Float` round-trip during the one stage where `Double.bitPattern` byte-identity is mandatory (DD #2).
- **No removal of `EnsembleCombiner`.** Removal is Story 6.4 (epic 6.4 AC). The `EnsembleCombiner.combine` call at `AudioAnalysisService.swift:399` is untouched.
- **No `MetadataCorroborator.swift` file relocation.** Architecture.md:1008 marks it "MOVED + UPDATED" into `SignalPool/`; the move is deferred to Story 6.4 where the type is substantively rewritten (avoids moving the file twice). Epic AC #1's "relocated OR updated in place" explicitly authorizes update-in-place (DD #7).
- **No new `BPMDiagnosticTrace` field.** `signalParticipationTrace` already exists (Story 6.1). KDD-T0 SAME-PR trigger does NOT fire. The 5-recipe `bpm-diagnostic-trace` audit applies inertly (DD #8).
- **No accuracy-changing behavior.** OA300 + GiantSteps baselines (Acc1 58/82+74/82; 537/661+546/661) hold unchanged. The byte-equality floor at Stage 1 measurement is the regression contract.
- **No new public API.** `PreCorroborationOutput`, the new `MetadataCorroborator` helper, and all touched surfaces are `internal`. Mary's Epic 6 → Epic 8 seam-mitigation rule is satisfied trivially (nothing public lands).

## Key Design Decisions

The 9 DDs below are the binding choices the dev agent inherits BEFORE Task 1 begins. **DDs #1, #2, and #3 are most consequential** — they lock the supersession of the epic-literal ACs, the Float byte-equality firewall, and the genuine (non-no-op) Stage-2 deliverable shape.

1. **Stage 2 depth: Option A (architecture-literal). Epic AC #1/#4 "no more apply(to:input:)" is SUPERSEDED.** The epic and architecture disagreed on how deep Stage 2 cuts. Architecture **KDD-A6 Stage 2** (the "Staging" item 2 under the `#### KDD-A6 — Post-merge corroboration boundary` heading; cited by heading, NOT line number, because DD #9 flags architecture.md line drift): "Migrate `MetadataCorroborator`'s body + `runPreCorroborationPipeline` to consume pool. `MetadataCorroborator.apply(to:input:)` **signature unchanged** at this stage. Byte-equality tests still pass." Epic 6.3 AC #1 (epics.md:472): "**no more `apply(to:input:)` method**." Resolved toward the architecture per Codex consult (thread `019e709a-21b3-7551-91b6-9ee89b92f2ba`, 2026-05-28) and project-lead directive ("not worth being overly strict about scope; adjust scope to match reality"). Binding supersession text:

   > Story 6.3 follows KDD-A6 Stage 2 architecture over epic AC #1/AC #4 where they conflict. `MetadataCorroborator.apply(to:input:)` remains present until Stage 3 because byte-identical output still depends on legacy `BPMResult.candidates` Float scores and the frozen merge API. The pool is threaded and populated as the staged data shape, but it does not become the sole authoritative carrier for merge/candidate score math until Story 6.4.

   This matches the 6.1 DD #11 / 6.2 DD #1 precedent of correcting an over-reaching epic AC via a documented supersession. The Epic 6 retro reconciles architecture.md ↔ epic ↔ implementation text.

   **Downstream obligation (party-mode review — Mary):** the deferred `apply(to:input:)` removal is NOT currently a named AC in Story 6.4's epic ACs (epics.md:506-534, which contract the `merge` flip, byte→semantic test swap, and `EnsembleCombiner` removal but only *imply* apply-removal via "merge operates directly on the pool — no intermediate arbiter"). When Story 6.4 is spec-created, the apply-removal MUST be promoted to an explicit 6.4 AC or it becomes the deliverable nobody contracted. Surface this in the 6.3 close-out hand-off.

2. **Float-score byte-equality firewall — pool stays trace-shaped this story.** `UnifiedSignalPool` is NOT enriched with a Float candidate payload in 6.3. Story 6.1 already reinterpreted DSP `score: Float` as `WeightedSignal.confidence: Double(score)` (a one-way widening). The corroborator's boost/re-select math is defined over the raw `Float` scores; the floor test (`disabledPolicy`) asserts `Double.bitPattern` equality on `bpm`/`confidence` AND exact per-candidate `score: Float`. Making the pool the authoritative carrier in 6.3 would force a `Double.confidence → Float.score` reconstruction across the exact boundary where byte-identity is mandatory — a lossy/ambiguous bridge. The corroborator continues to operate on `BPMResult.candidates` directly. Story 6.4 enriches the pool with an explicit `Float` score field (or a candidate-specific payload) BEFORE the carrier flip, so semantic parity replaces byte parity in the same commit (Codex finding (2)).

   **Story 6.4 load warning (party-mode review — Winston):** the deferrals from this story stack onto Story 6.4, which now carries SIX coupled changes: (1) `merge` carrier-type flip across call sites, (2) `apply(to:input:)` removal + body rewrite, (3) the `git mv` of `MetadataCorroborator.swift` into `SignalPool/` (DD #7), (4) this `UnifiedSignalPool` Float-score enrichment, (5) `EnsembleCombiner` removal, (6) the byte→semantic test swap. Architecture calls Stage 3 "a single mechanical PR" — it will not be mechanical with these deferrals. When Story 6.4 is spec-created, evaluate whether it needs its own pressure-release split. This debt is created here; flag it at 6.3 close-out so it is not discovered mid-6.4.

3. **Genuine Stage-2 deliverable shape (not a no-op).** Three concrete migrations, all byte-inert:
   - **(a) Pool production moves into the pipeline.** Add `let pool: UnifiedSignalPool?` to `PreCorroborationOutput`. Build the pool at the end of `runPreCorroborationPipeline` (after `merge` returns), **gated on `merged?.trace != nil`** — the exact observable gate today's `buildStage1SignalPool` skip uses (AudioAnalysisService.swift:355), NOT `enableTrace`. (Codex Q1, party-mode review: `enableTrace` is the upstream *intent* flag; `merged.trace != nil` is the concrete byte-preservation guard. They are equivalent on every executable path today, but keying on `enableTrace` weakens a concrete guard to an intent flag — if a future merge/fallback returns a non-nil result with a nil trace, the `enableTrace` gate would build a pool where today none is built.) This satisfies epic AC #4 "the pipeline emits `UnifiedSignalPool`."
   - **(b) `MetadataCorroborator` owns metadata participation (function relocation, NOT authority transfer).** Extract the file-metadata branch of `buildStage1SignalPool` (AudioAnalysisService.swift:493-532) into an internal `MetadataCorroborator` helper — e.g. `static func signalParticipationEntries(for input: MetadataCorroborationInput, weight: Double) -> [SignalParticipationTraceEntry]` (the empty-source guard reads `input.policy.enabledSources` via `MetadataCorroborationInput.policy`, MetadataCorroborator.swift:33 — verbatim-liftable). The DSP + ML branches stay in the pipeline-side pool builder (they are not metadata's concern). This satisfies epic AC #1 "MetadataCorroborator emits SignalParticipation values for each parsed metadata tag via an internal helper" — minus the `apply` removal (DD #1). **Scope honesty (party-mode review — Winston):** this is a relocation of a pure function, NOT a transfer of corroboration authority. `apply(to:input:)` still owns the boost/re-select math and reads `BPMResult.candidates` directly; the helper produces trace-shaped side-evidence the corroborator does not yet consume. The authority transfer is Stage 3 (Story 6.4). Do NOT over-engineer the helper to feel substantive — it is a verbatim lift.
   - **(c) `analyzeBPM` consumes `pre.pool`.** The post-hoc `buildStage1SignalPool(...)` call in `analyzeBPM` (AudioAnalysisService.swift:356-357) is removed; `analyzeBPM` reads `pre.pool` and assigns `trace.signalParticipationTrace = pool.entries` via the existing FMA-12 explicit-`BPMResult`-rebuild pattern (DD #6).

4. **`merge` signature frozen; `EnsembleCombiner` untouched.** Exact frozen signature: `merge(windowResults: [BPMResult], candidateCount: Int, strategy: CandidateMergeStrategy, votingPolicy: VotingPolicy = .simpleMajority, votingThreshold: Double = 0.0) -> BPMResult?` (`CandidateMergeStrategy.swift:71-77`). `grep -n "func merge(" Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` MUST return the identical parameter list post-implementation. `EnsembleCombiner.combine(...)` at `AudioAnalysisService.swift:399` is read-only this story; removal is Story 6.4.

5. **`@Tag(.stage2Floor)` scaffold — same four tests, both tags.** Add `@Tag static var stage2Floor: Self` to `Tests/BoomBoomBoomKitTests/StageFloorTags.swift`. Apply `.tags(.stage1Floor, .stage2Floor)` to the four existing `metadataPolicy = .disabled` tests in `MetadataCorroborationTests.swift` — `disabledPolicy` (line 421-422), `sameTempoBoostsConfidence` (463-464), `disabledPolicyOnTaggedFile` (502-503), `evidenceEmptyWhenDisabled` (533-534) — all in `struct MetadataCorroborationServiceTests`. Both tags coexist on each test. **SwiftPM `--filter` caveat (inherited from Story 6.1 DD #8, verified):** `swift test --filter` is a regex over `<test-target>.<test-case>` identifiers, NOT a Swift Testing tag selector — `swift test --filter "stage2Floor"` matches zero tests. Canonical verification surface is source-level grep for `.tags(...stage2Floor)` at the four functions PLUS running them via name-regex: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`. Update the `StageFloorTags.swift` file comment to document the second tag. Stage 2 floor = Stage 1 measurement (architecture.md:345).

6. **Pool-construction relocation must preserve `signalParticipationTrace` byte-content.** Moving construction from `analyzeBPM`'s `buildStage1SignalPool` into `runPreCorroborationPipeline` MUST produce byte-identical `signalParticipationTrace` entries. Inputs are identical (`merged` result + `options` + `metadataInput`), so the entry list is identical. `SignalPoolTests.dspPerSourceContract`, `mlAbsentWhenTechniqueNil`, `metadataAbsentWhenDisabled` assert on these entries and MUST still pass unchanged — they are the ONLY tests that build a pool (the `.stage2Floor` tests all run `enableTrace == false` and never construct one), so they are promoted to an explicit verification AC + Task (AC #9 / Task 6.11). The gate is preserved by keying on `merged?.trace != nil` (DD #3a / Codex Q1), matching today's skip exactly. **Entry-concatenation order is the real byte-equality risk** (Winston): the pipeline-side builder must concatenate DSP entries (incl. the empty-candidate `.dsp` sentinel, AudioAnalysisService.swift:468-477) → ML entry → file-metadata entries (from the `MetadataCorroborator` helper) in that exact order. During development, add a temporary full-array `signalParticipationTrace` equality assertion against a pre-refactor snapshot even if it doesn't ship. The ML entry stays `.abstained(.sourceSpecific("stage1-eval-deferred"))` / `.absent` exactly as today — its value depends only on `options.mlTechnique` / `options.ensemblePolicy` (both in scope pre-merge) and `evaluateMLIfActive` still runs post-corroboration, so Stage-1 ML pool semantics are invariant under the move (Codex Q3). **`weight = 1.0` now spans two sites** (Winston): the DSP/ML inline branches hoist a `let weight: Double = 1.0` in the pipeline AND the metadata helper takes `weight: 1.0` as an argument — so Story 6.5's weight-value evolution (DD #7 of Story 6.1) now lifts two literals, not one. Note this in Completion Notes for the Story 6.5 dev agent.

7. **`MetadataCorroborator.swift` updated in place — no relocation.** Per Q2 resolution: epic AC #1 says "relocated OR updated in place"; architecture.md:1008 says "MOVED + UPDATED into `SignalPool/`." Defer the `git mv` to Story 6.4, where `MetadataCorroborator` is substantively rewritten (the body migration is large there). Moving it now then again in 6.4 doubles the review churn for an inert change. The new internal helper is added to the existing file at `Sources/BoomBoomBoomKit/MetadataCorroborator.swift`.

8. **No new `BPMDiagnosticTrace` field; 5-recipe audit applies inertly.** `signalParticipationTrace` already shipped in Story 6.1. No KDD-T0 SAME-PR trigger fires. Run the 5 `bpm-diagnostic-trace` audit recipes (A-E) pre- AND post-implementation per the project skill; both return zero trace-relevant matches (the two benign `String(format: "%.1f", r.bpm)` benchmark-report matches noted in Story 6.2 are formatting, not banned-shape trace writes — same inert baseline). `PreCorroborationOutput` is `Sendable`; the added `pool: UnifiedSignalPool?` field carries the typed-evidence array, not a banned dictionary shape.

9. **Pending mid-Epic-6 architecture amendment is a coordination note, not a blocker.** Story 6.2 Dev Notes scheduled a standalone `architecture.md` amendment commit (6 KDD-S1/S2 divergences) + deferred-work W72 (AC-text tightening) "between Story 6.2 close-out and Story 6.3 spec-create." As of this spec's authoring (branch `rterhaar/6-3`), that commit has NOT landed (no amendment commit in `git log`). Story 6.3 cites architecture.md by its CURRENT line numbers and does NOT depend on the amendment. If the operator lands the amendment first and line numbers shift, re-verify the References section. The operator MAY bundle W72 with that amendment; it is not a Story 6.3 deliverable.

## Acceptance Criteria

The 9 ACs below are adapted from `epics.md:470-498` with DD #1's supersession applied to AC #1 and AC #4; AC #9 was added by the party-mode review (Codex Q5) to guard the trace-enabled relocation path that the byte-equality floor does not exercise.

1. **MetadataCorroborator owns metadata participation via an internal helper; `apply(to:input:)` survives.** **Given** `MetadataCorroborator` gains an internal helper that emits `SignalParticipationTraceEntry` values for each parsed metadata tag (the file-metadata branch extracted from `buildStage1SignalPool`), **When** the test suite runs, **Then** the helper produces the metadata pool entries AND `MetadataCorroborator.apply(to:input:)` retains its exact signature `apply(to result: BPMResult, input: MetadataCorroborationInput) -> (BPMResult, [MetadataBPMEvidence])`. Epic AC #1's "no more apply(to:input:) method" is superseded per DD #1 — removal lands Story 6.4.

2. **Frozen `merge` signature unchanged.** **Given** the frozen `CandidateMergeStrategy.merge` signature, **When** the call sites compile, **Then** `grep -n "func merge(" Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` plus the four parameter lines return the identical list as post-Story-6.2 land (`windowResults:candidateCount:strategy:votingPolicy:votingThreshold:`). Zero signature changes.

3. **`@Tag(.stage2Floor)` passes at the Stage 1 measurement.** **Given** `@Tag(.stage2Floor)` is added to `StageFloorTags.swift` and applied (alongside `@Tag(.stage1Floor)`) to the four `metadataPolicy = .disabled` tests, **When** the four tagged tests are run via name-regex (per DD #5 SwiftPM caveat), **Then** all four pass at 100%. Stage 2 floor = Stage 1 measurement.

4. **`runPreCorroborationPipeline` emits the pool; `analyzeBPM` consumes it.** **Given** `runPreCorroborationPipeline`'s internal data shape changes, **When** code review inspects the change, **Then** `PreCorroborationOutput` carries a `pool: UnifiedSignalPool?` field built inside the pipeline (post-merge, **gated on `merged?.trace != nil`** — NOT `enableTrace`, per DD #3a / Codex Q1); `analyzeBPM` consumes `pre.pool` (non-nil pool implies non-nil `merged.trace`) and no longer calls `buildStage1SignalPool` post-hoc; and `MetadataCorroborator` produces the metadata participation entries via its own helper rather than the service computing them inline. The pool remains trace-shaped (`entries: [SignalParticipationTraceEntry]`) — NOT the authoritative candidate-score carrier (DD #2).

5. **`metadataPolicy = .disabled` byte-equality opt-out test holds at Stage 2.** **Given** the Story 3-6 byte-equality opt-out test (`disabledPolicy`), **When** it runs at Stage 2, **Then** output is byte-identical to the pre-Story-3-6 baseline (NaN-safe via `NumericTestHelpers.bitEqual`). The test's `analyzeBPM`-vs-`runPreCorroborationPipeline` comparison surface (`.result.bpm`/`.confidence`/per-candidate `bpm`/`score`) is unaffected by the added `pool` field (the pool lives in the trace, not in the byte-compared `result`).

6. **Seam-mitigation rule satisfied (trivially).** **Given** Mary's Epic 6 → Epic 8 seam rule, **When** any new surface lands in `AudioAnalysisService.swift` or `MetadataCorroborator.swift`, **Then** it stays `internal` or unannotated. This story adds NO new public API: `PreCorroborationOutput`, its `pool` field, and the `MetadataCorroborator` helper are all `internal`.

7. **OA300 + GiantSteps accuracy floors UNCHANGED.** **Given** `make benchmark` + `make benchmark-giantsteps`, **When** both complete, **Then** OA300 Acc1 = 58/82, Acc2 = 74/82; GiantSteps Acc1 = 537/661, Acc2 = 546/661 — zero delta from Story 6.2 close-out. If any number changes, HALT and surface to the operator (a byte-inert migration cannot move accuracy).

8. **5-recipe `bpm-diagnostic-trace` audit returns zero matches pre- and post-implementation.** **Given** no new `BPMDiagnosticTrace` field is introduced (DD #8), **When** the 5 audit recipes (A-E) run against `Sources/` + `Tests/` both before and after, **Then** both runs return zero trace-relevant matches (the inert baseline from Story 6.2 holds).

9. **Trace-enabled pool relocation preserves `signalParticipationTrace` content.** **Given** `options.enableTrace = true` (the path that actually builds a pool — the four `.stage2Floor` tests all run `enableTrace == false` and never construct one, so they do NOT guard this), **When** the existing `SignalPoolTests.dspPerSourceContract`, `mlAbsentWhenTechniqueNil`, and `metadataAbsentWhenDisabled` run, **Then** `result.trace.signalParticipationTrace` remains content-identical to the pre-relocation contract: DSP entries first (incl. the empty-candidate `.dsp` sentinel), then the single ML entry, then file-metadata entries — with unchanged `participation`, `weight` (1.0), and `contribution` semantics. (Party-mode review — Codex Q5: the byte-equality floor does not exercise the relocation; these three are the trace-path guards.)

## Tasks / Subtasks

- [x] Task 1 — Pre-flight (AC: #5, #7, #8)
  - [x] 1.1 Invoke the `bpm-diagnostic-trace` skill via the Skill tool; read `SKILL.md` fully
  - [x] 1.2 Run the 5 audit recipes against `Sources/` + `Tests/` BEFORE any changes; record baseline (expected: zero trace-relevant matches)
  - [x] 1.3 Confirm `make build` + `make test` pass against current `develop` (Story 6.2 close-out baseline: 443 tests / 96 suites)
  - [x] 1.4 Confirm the four `metadataPolicy = .disabled` tests pass: `swift test --filter "MetadataCorroborationServiceTests/(disabledPolicy|sameTempoBoostsConfidence|disabledPolicyOnTaggedFile|evidenceEmptyWhenDisabled)"`
  - [x] 1.5 Check whether the pending mid-Epic-6 `architecture.md` amendment commit (DD #9) has landed; if so, re-verify the References section line numbers before coding

- [x] Task 2 — `@Tag(.stage2Floor)` scaffold (AC: #3)
  - [x] 2.1 Add `@Tag static var stage2Floor: Self` to `Tests/BoomBoomBoomKitTests/StageFloorTags.swift`; update the file comment to document the second tag + the SwiftPM `--filter` regex caveat (per DD #5)
  - [x] 2.2 Change the four tests' annotations from `.tags(.stage1Floor)` to `.tags(.stage1Floor, .stage2Floor)` in `MetadataCorroborationTests.swift` (functions `disabledPolicy`, `sameTempoBoostsConfidence`, `disabledPolicyOnTaggedFile`, `evidenceEmptyWhenDisabled`)
  - [x] 2.3 Verify via name-regex filter (DD #5) that all four pass; grep `.tags(.stage1Floor, .stage2Floor)` confirms presence at the four functions

- [x] Task 3 — Extract metadata participation into a `MetadataCorroborator` helper (AC: #1)
  - [x] 3.1 Read `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` fully + `AudioAnalysisService.buildStage1SignalPool` (lines 437-535) before editing
  - [x] 3.2 Add `static func signalParticipationEntries(for input: MetadataCorroborationInput, weight: Double) -> [SignalParticipationTraceEntry]` to `MetadataCorroborator` (internal; brief `///` describing the Stage-2 ownership move). Lifted the file-metadata branch logic VERBATIM from `buildStage1SignalPool`: empty-`enabledSources` → single `.absent`; enabled-but-no-accepted-tag → single `.absent`; else one `.present(WeightedSignal(bpm: tag.parsedBPM, confidence: WeightedSignal.fileMetadataStage1TraceOnlyDefault, source: .fileMetadata))` per accepted tag. Entry math identical: `weight` passed in, `contribution = participation.confidence * weight`.
  - [x] 3.3 `apply(to:input:)` signature and body are UNCHANGED (DD #1). Boost/re-select logic untouched.

- [x] Task 4 — `runPreCorroborationPipeline` builds + emits the pool (AC: #4)
  - [x] 4.1 Add `let pool: UnifiedSignalPool?` to `PreCorroborationOutput` (internal struct, `Sendable`)
  - [x] 4.2 At the end of `runPreCorroborationPipeline` (after `merge` returns `merged`), build the pool when **`merged?.trace != nil`** (the exact observable gate today's `buildStage1SignalPool` skip uses — DD #3a / Codex Q1; NOT `enableTrace`); otherwise `pool = nil`. Extracted into a private `buildStage2SignalPool(merged:options:metadataInput:) -> UnifiedSignalPool?` helper for readability (the gate + DSP/ML inline + metadata via the corroborator helper). DSP + ML entries built inline (verbatim from the former `buildStage1SignalPool`, including the empty-candidate `.dsp` sentinel); file-metadata entries from `MetadataCorroborator.signalParticipationEntries(for: metadataInput, weight: 1.0)` (Task 3). Concatenated into `UnifiedSignalPool(entries:)`. The `weight: Double = 1.0` local is hoisted AND passed as the helper's `weight:` arg (DD #6 / R7 — two sites for Story 6.5).
  - [x] 4.3 Return `PreCorroborationOutput(result: merged, metadataInput: metadataInput, pool: pool)`
  - [x] 4.4 Entry order + content byte-identical to the former `buildStage1SignalPool` output (DSP entries first, then ML, then file-metadata) — proven by `SignalPoolTests.dspPerSourceContract`/`mlAbsentWhenTechniqueNil`/`metadataAbsentWhenDisabled` passing unchanged (Task 6.11)

- [x] Task 5 — `analyzeBPM` consumes `pre.pool` (AC: #4, #5)
  - [x] 5.1 Removed the post-hoc `buildStage1SignalPool(...)` call + the `merged.trace != nil` block; replaced with `if let pool = pre.pool { ... }` (`if let` binding, not force-unwrap — R8/Amelia), rebuilding `mergedWithParticipationTrace` via the FMA-12 explicit-`BPMResult`-rebuild pattern assigning `participationTrace?.signalParticipationTrace = pool.entries`; else `mergedWithParticipationTrace = merged`. Non-nil `pre.pool` implies non-nil `merged.trace` (DD #3a gate).
  - [x] 5.2 Deleted the now-unused private `buildStage1SignalPool` helper (DSP/ML logic moved to `buildStage2SignalPool`; metadata logic moved to the corroborator helper). Confirmed zero live callers (`grep -n buildStage1SignalPool Sources/ Tests/` returns only doc/comment prose).
  - [x] 5.3 `MetadataCorroborator.apply` call site is UNCHANGED; `EnsembleCombiner.combine` call (line 393) is UNCHANGED
  - [x] 5.4 `disabledPolicy` byte-equality test passes (the added `pool` field does not alter `PreCorroborationOutput.result`)

- [x] Task 6 — Verification & audit (AC: #2, #3, #5, #6, #7, #8, #9)
  - [x] 6.1 `make fmt && make lint` — passes (1 violation, 0 serious = canonical `LUFSAnalyzer.swift:94` TODO baseline)
  - [x] 6.2 `make build` — clean (0.57s)
  - [x] 6.3 `make test` — 443 tests / 96 suites passed; delta +0 from Story 6.2 baseline (tag annotations only)
  - [x] 6.4 Four `@Tag(.stage1Floor, .stage2Floor)` tests run via name-regex (DD #5) — all four pass
  - [x] 6.5 `make benchmark` (OA300) — Acc1 = 58/82, Acc2 = 74/82 — UNCHANGED. Zero delta.
  - [x] 6.6 `make benchmark-giantsteps` — Acc1 = 537/661, Acc2 = 546/661 — UNCHANGED. Zero delta.
  - [x] 6.7 Re-ran the 5 `bpm-diagnostic-trace` audit recipes (A-E); zero trace-relevant matches against `Sources/` + `Tests/`
  - [x] 6.8 `grep -n "func merge(" Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — parameter list unchanged (`windowResults:candidateCount:strategy:votingPolicy:votingThreshold:`) (AC #2)
  - [x] 6.9 `grep -rn "EnsembleCombiner" Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `combine` call site unchanged (AC #6 / scope guard)
  - [x] 6.10 `MetadataCorroborator.apply(to:input:)` signature unchanged (`apply(to result: BPMResult, input: MetadataCorroborationInput) -> (BPMResult, [MetadataBPMEvidence])`)
  - [x] 6.11 **Trace-path relocation guard (AC #9 / Codex Q5):** `swift test --filter "SignalPoolTests/(dspPerSourceContract|mlAbsentWhenTechniqueNil|metadataAbsentWhenDisabled)"` — all three pass unchanged, confirming the pool-build relocation preserves `signalParticipationTrace` content.

## Dev Notes

### Architecture pointers (read before coding)

- **KDD-A6 Stage 2 verbatim:** `_bmad-output/planning-artifacts/architecture.md:335-345`. The 3-stage staging + "stage N floor = stage N-1 measurement; no week-long red intervals." DD #1 follows the Stage 2 text over the epic AC where they conflict.
- **KDD-S1 pool voting rules + boundary contract:** `architecture.md:160-189`. The four-state contract, the `MLTechnique.evaluate` frozen boundary, the migration shape. Note: the ML `.present`/`.abstained` promotion happens in a LATER story — Stage 2 keeps the Story 6.1 `stage1-eval-deferred` abstain semantics (DD #6).
- **`@Tag` stage-gating + NaN-safe `bitEqual`:** `architecture.md:823-866`. Pattern #11. The Story 6.1 DD #8 SwiftPM `--filter` caveat is the operative reality (tags are not `--filter`-selectable).
- **Mary's seam-mitigation rule:** `epics.md:23` + Epic 6 body `epics.md:275`. Trivially satisfied — no public API lands.
- **`bpm-diagnostic-trace` project skill:** `.claude/skills/bpm-diagnostic-trace/SKILL.md` — invoke via the Skill tool; 5 audit recipes (A-E) required pre + post.

### Existing code to read (UPDATE files, per checklist rule)

The story modifies **2 existing source files** and **1 existing test file**. Read each completely before editing:

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (912 lines) — the load-bearing file. Read: `analyzeBPM` body (lines 321-418), `buildStage1SignalPool` (437-535, being dismantled), `PreCorroborationOutput` (710-713), `runPreCorroborationPipeline` (744-831). The pool build moves from `buildStage1SignalPool` (post-hoc in `analyzeBPM`) into `runPreCorroborationPipeline` (Task 4); `analyzeBPM` consumes `pre.pool` (Task 5). Preserve the FMA-12 explicit-`BPMResult`-rebuild pattern (the trace field is on a `let`).
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` (393 lines) — caseless-enum namespace. `apply(to:input:)` (62-322) is UNCHANGED. Add ONE internal helper (Task 3.2). Do NOT relocate the file (DD #7).
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — the four `.stage1Floor` tests in `struct MetadataCorroborationServiceTests` (lines 417+) at 421-422 / 463-464 / 502-503 / 533-534. Add `.stage2Floor` to each (Task 2.2). The `disabledPolicy` test reads `runPreCorroborationPipeline(...).result` (line 439) — the added `pool` field does not affect it.

**Read-only references (do NOT edit):**

- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift` — `internal struct UnifiedSignalPool: Sendable { let entries: [SignalParticipationTraceEntry] }`. Shape UNCHANGED this story (DD #2).
- `Sources/BoomBoomBoomKit/SignalPool/{SignalParticipation,SignalParticipationTraceEntry,WeightedSignal,SignalSource,AbstainReason,DemotionReason}.swift` — the contract types from Story 6.1. UNCHANGED.
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:71-77` — frozen `merge` signature.
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — removal is Story 6.4.
- `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift` — `dspPerSourceContract` / `mlAbsentWhenTechniqueNil` / `metadataAbsentWhenDisabled` assert on `result.trace.signalParticipationTrace`; they MUST still pass (pool content byte-identical per DD #6).

### File list (what this story creates / updates)

**NEW files:** none.

**UPDATED files (3):**
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `PreCorroborationOutput` gains `pool: UnifiedSignalPool?`; `runPreCorroborationPipeline` builds + returns the pool (DSP/ML entries inline, metadata entries from `MetadataCorroborator`); `analyzeBPM` consumes `pre.pool`; `buildStage1SignalPool` deleted
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — add internal `signalParticipationEntries(for:weight:)` helper; `apply(to:input:)` unchanged
- `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` — add `@Tag static var stage2Floor`; update file comment

**UPDATED tests (1):**
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `.tags(.stage1Floor, .stage2Floor)` on the four `metadataPolicy = .disabled` tests

**FORBIDDEN files (verify diff scope post-implementation):**
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift` — NO changes (signature frozen)
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — NO changes (Story 6.4 removes it)
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift` — NO changes (DD #2 — no Float-payload enrichment)
- `Package.swift`, `Demo/**` — NO changes

### Testing standards

- Swift Testing only (`@Suite`, `@Test`, `#expect`, `#require`) — never XCTest. Per project-context.md.
- `NumericTestHelpers.bitEqual(_:_:)` from `BoomBoomBoomKitTestSupport` for any NaN-bearing Float/Double comparison.
- No new test file this story — only `@Tag` annotations + verification that existing suites pass. Expected `@Test` count delta: 0.
- The byte-equality floor is the regression backbone — `disabledPolicy` proves the disabled path is byte-identical; the other three `.stage2Floor` tests are behavioral floor.

### Pre-1.0 framing reminder

Per project-context.md "Pre-1.0 release posture": this is a scope-adjusted Stage 2. The epic-literal "remove apply" ambition is deferred to 6.4 not because of backwards-compatibility (none is promised) but because byte-identity at the Float-score boundary makes the carrier flip safer as one atomic Stage 3 change. The supersession (DD #1) is a reality-adjustment, not a BC concession.

### Previous Story Intelligence (Story 6.2 close-out 2026-05-28)

Story 6.2 commit `89b6ff5` landed (FeatureSubstrate namespace + MLFeatureFrames relocation). PSI items inherited by Story 6.3:

1. **Byte-inert migrations hold accuracy at zero delta.** Story 6.2 confirmed OA300 58/82+74/82 and GiantSteps 537/661+546/661 are unchanged across a pure structural move. Story 6.3 is the same shape — any accuracy delta means a wiring bug, HALT.
2. **`make test` baseline is 443 tests / 96 suites** (Story 6.2 ended at 443 after `decodedAudioInitInvariants` deletion). Story 6.3 expected delta: 0 (tag annotations only).
3. **Supersession-DD precedent is established.** Story 6.2 DD #1 corrected epic AC #2's factually-wrong source-location claim; Story 6.1 DD #11 superseded a phantom-file reference. Story 6.3 DD #1 follows the same pattern for a design-depth conflict (resolved via Codex consult, not a factual error).
4. **Pending mid-Epic-6 architecture amendment** (Story 6.2 Dev Notes + deferred-work W72) was scheduled between 6.2 close and 6.3 spec-create and is NOT yet landed. DD #9 treats it as a coordination note. If the operator runs it, bundle W72.
5. **`bpm-diagnostic-trace` 5-recipe audit applies inertly** — Story 6.2 confirmed "zero trace-relevant matches" (two benign benchmark-report `%.1f` formatting matches are not banned-shape writes). Same baseline for 6.3 (no new trace field).
6. **Operator-owned closeout discipline** — `/bmad-code-review` on a different LLM (or via Codex MCP arm), final commit on 1Password GPG signer. Surface pending operator actions in Completion Notes.

### 5-layer review cadence (applies to Story 6.3)

Story 6.3 modifies a load-bearing integration file (`AudioAnalysisService.analyzeBPM` + `runPreCorroborationPipeline`) and a corroboration namespace, even though it adds no public API. Per project-context.md Story Authoring Discipline:

1. **Failure Mode Analysis** — pre-PR single-pass against this spec (focus: does the pool-construction relocation preserve `signalParticipationTrace` byte-content?)
2. **Self-Consistency review** — 3 parallel Codex agents (Blind Hunter + Edge Case Hunter + Acceptance Auditor)
3. **Code review** on the staged diff (`/bmad-code-review`)
4. **Codex MCP `codex:consult`** — already engaged for the DD #1 decision (thread `019e709a-21b3-7551-91b6-9ee89b92f2ba`); re-engage on the staged diff if the byte-equality floor surfaces surprises
5. **GitHub Copilot inline review** at PR open

Findings persisted to `deferred-work.md` per the canonical-SoT pattern.

### References

- [Source: _bmad-output/planning-artifacts/epics.md:464-498] — Story 6.3 user-story + 6 ACs (AC #1/#4 superseded per DD #1)
- [Source: _bmad-output/planning-artifacts/architecture.md:335-345] — KDD-A6 3-stage staging; Stage 2 "apply signature unchanged" (DD #1 authority)
- [Source: _bmad-output/planning-artifacts/architecture.md:160-189] — KDD-S1 pool voting rules + frozen `MLTechnique` boundary
- [Source: _bmad-output/planning-artifacts/architecture.md:823-866] — `@Tag` stage-gating Pattern #11 + NaN-safe `bitEqual`
- [Source: _bmad-output/implementation-artifacts/6-1-signalparticipation-contract-and-pool-stage-1-adapter.md] — Stage 1 pool + `@Tag(.stage1Floor)` + DD #8 SwiftPM `--filter` caveat; buildStage1SignalPool semantics
- [Source: _bmad-output/implementation-artifacts/6-2-featuresubstrate-namespace-and-mlfeatureframes-relocation.md] — PSI; supersession-DD precedent; pending architecture-amendment note
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:321-418, 437-535, 710-831] — analyzeBPM, buildStage1SignalPool, PreCorroborationOutput, runPreCorroborationPipeline
- [Source: Sources/BoomBoomBoomKit/MetadataCorroborator.swift:29-322] — MetadataCorroborationInput + apply(to:input:)
- [Source: Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:71-77] — frozen merge signature
- [Source: Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift:417-545] — MetadataCorroborationServiceTests + the four .stage1Floor tests
- [Source: Tests/BoomBoomBoomKitTests/StageFloorTags.swift] — @Tag scaffold
- [Source: Codex consult thread 019e709a-21b3-7551-91b6-9ee89b92f2ba] — DD #1 Option A recommendation + Float-score hazard analysis
- [Source: Codex spec-review thread 019e70a6-93ba-7d30-ae25-33ddaf290e59] — party-mode adversarial spec review (Q1 gate-predicate defect + Q5 missing trace-path verification)

## Review Findings

Pre-implementation party-mode review (2026-05-28) — 4 BMAD voices (Winston architect, Amelia dev, Mary analyst, Siri Apple-docs) as independent subagents + Codex adversarial spec-review + `axiom:ask`→`axiom-testing` skill validation + apple-docs-grounded Swift Testing check. The spec was validated as IMPLEMENTABLE (Amelia: no build/test breaker; all inputs reachable at the new site) and DEFENSIBLE (Mary: supersession well-evidenced; FR-7 pre-partitioned). 2 concrete defects + 6 refinements applied pre-dev:

| ID | Severity | Finder(s) | Finding | Status |
|---|---|---|---|---|
| R1 | High | Codex Q1 + Winston + Amelia H2 | Pool-build gate keyed on `enableTrace` diverges from today's concrete `merged.trace != nil` gate (inert today, but weakens a concrete guard to an intent flag; self-contradicts Task 5.1's `pre.pool != nil` consumption). Re-key Task 4.2 + DD #3a + DD #6 + AC #4 on `merged?.trace != nil`. | APPLIED |
| R2 | High | Codex Q5 | The four `.stage2Floor` tests all run `enableTrace == false` and never build a pool — the byte-equality floor does NOT exercise the relocation. The only pool-building trace-asserting tests (`SignalPoolTests.dspPerSourceContract`/`mlAbsentWhenTechniqueNil`/`metadataAbsentWhenDisabled`) were Dev-Notes-only. Promoted to AC #9 + Task 6.11. | APPLIED |
| R3 | Med | Mary | DD #1 defers `apply(to:input:)` removal to 6.4, but 6.4's epic ACs (epics.md:506-534) never name it — only imply it. Added downstream-obligation note to DD #1: 6.4 spec-create MUST promote apply-removal to a named AC. | APPLIED |
| R4 | Med | Winston | DD #3(b) over-framed the metadata-helper extraction as "genuine deliverable" — it is a function relocation, NOT an authority transfer (that's Stage 3). Added scope-honesty note + "do not over-engineer the helper." | APPLIED |
| R5 | Med | Winston | Story 6.4 now silently carries 6 coupled changes; architecture still calls Stage 3 "a single mechanical PR." Added load-warning to DD #2 — evaluate a 6.4 pressure-release split at 6.4 spec-create. | APPLIED |
| R6 | Low | Winston | DD #1 cited architecture by volatile `:342` line; DD #9 flags line drift. Re-anchored DD #1 authority to the heading "KDD-A6 Stage 2." | APPLIED |
| R7 | Low | Winston | `weight = 1.0` Story-6.5 evolution seam now spans two sites (pipeline local + helper arg). Noted in DD #6 + Task 4.2 for the 6.5 dev agent. | APPLIED |
| R8 | Low | Amelia | Prefer `if let pool = pre.pool` over `pre.pool!` force-unwrap in Task 5.1. | APPLIED |

Cleared (no defect): Codex Q2 (disabledPolicy floor holds — pool nil at `enableTrace:false`, sibling field doesn't perturb byte-compared `.result`), Q3 (ML entry `.abstained`/`.absent` invariant under the move — options-derived, available pre-merge), Q4 (task ordering compile-break-free; one `buildStage1SignalPool` caller; `[SignalParticipationTraceEntry]` return Sendable/visibility-safe). Siri: no Apple/Swift defects — `.tags(.stage1Floor, .stage2Floor)` correct modern API, `Sendable` field addition needs no special handling, `Float→Double→Float` firewall reasoning sound. `axiom-testing` skill corroborated: tag filtering is a Test-Navigator (Xcode) feature; `swift test --filter` is identifier-regex only — no first-class CLI run-by-tag — confirming DD #5's caveat.

### Code Review Findings — staged diff (2026-05-28)

`/bmad-code-review` four-layer pass over the uncommitted source/test diff (4 code files, ~371 lines): Blind Hunter (`bmad-review-adversarial-general`, diff-only) + Edge Case Hunter (`bmad-review-edge-case-hunter`, project read) + Acceptance Auditor (spec + context) + a Codex-backed blind hunter (`codex:consult` diff review). **Result: clean.** Edge Case Hunter and Codex both independently proved byte-inertness on every reachable path (`merged == nil`, `merged != nil && trace == nil`, empty candidates, ML absent/abstained, metadata empty-sources/no-accepted-tags, DSP→ML→metadata ordering). Acceptance Auditor confirmed all 9 ACs satisfied and both "verbatim lift" claims accurate. 0 decision-needed, 0 patch, 2 defer, ~11 dismissed as noise (Blind-Hunter context-free false positives: gate `merged?.trace` "divergence" — proven equivalent via single return path + value-type `BPMResult`; `input.policy == options.metadataPolicy` — verified at every `buildMetadataInput` return path; `BPMResult` rebuild field-preservation — unchanged from baseline; `Sendable` obligation — satisfied since Story 6.1).

- [x] [Review][Defer] Stage-1 naming tokens inside Stage-2 code [AudioAnalysisService.swift:807, MetadataCorroborator.swift:373] — deferred to Story 6.4. `"stage1-eval-deferred"` and `WeightedSignal.fileMetadataStage1TraceOnlyDefault` now emit from `buildStage2SignalPool`/`signalParticipationEntries`; correct per DD #6 (renaming breaks the byte-identity contract this story rests on), cleanup belongs to the 6.4 carrier flip.
- [x] [Review][Defer] Empty-candidate `.dsp` sentinel + no-accepted-tags `.absent` metadata edges lack a dedicated executing assertion [AudioAnalysisService.swift:793, MetadataCorroborator.swift:332] — deferred, pre-existing. Both branches are verbatim-lift-inert and partially covered by `SignalPoolTests`; no fixture exercises the policy-enabled-but-all-tags-rejected path nor the non-nil-result-no-candidates sentinel. Inherited from Story 6.1; add fixtures alongside the 6.4 semantic-test swap.

## Dev Agent Record

### Agent Model Used

claude-opus-4-8[1m] (Opus 4.8, 1M context) via `/bmad-dev-story`.

### Debug Log References

- Baseline pre-flight: 5-recipe `bpm-diagnostic-trace` audit zero matches; `make build` clean; `make test` 443 tests / 96 suites; four `metadataPolicy = .disabled` tests pass. Baseline commit `89b6ff5`.
- DD #9 check: the pending mid-Epic-6 `architecture.md` amendment commit (`3dd515f` "Epic 6 architecture amendment") exists on `rterhaar/6-2` but is NOT an ancestor of the current branch `rterhaar/6-3` (`git merge-base --is-ancestor 3dd515f HEAD` → false). Architecture.md is in its pre-amendment state on this branch; the spec's line numbers hold, no re-verification needed.
- No HALT events. No accuracy delta (a byte-inert migration cannot move accuracy — confirmed).

### Completion Notes List

Stage 2 (KDD-A6) data-shape migration landed in a single execution — behaviorally inert, zero output-byte change.

**What changed (3 source/test files + 1 test scaffold):**
1. **`runPreCorroborationPipeline` now builds + emits the `UnifiedSignalPool`.** `PreCorroborationOutput` gained `let pool: UnifiedSignalPool?`. The pool is built post-merge by a new private `buildStage2SignalPool(merged:options:metadataInput:) -> UnifiedSignalPool?`, gated on **`merged?.trace != nil`** (DD #3a / R1 — the exact observable gate the former post-hoc `buildStage1SignalPool` skip used; NOT `enableTrace`). DSP + ML entries built inline (verbatim, incl. the empty-candidate `.dsp` sentinel); file-metadata entries delegated to the new corroborator helper.
2. **`MetadataCorroborator` owns metadata participation.** New internal `static func signalParticipationEntries(for:weight:)` — a verbatim lift of the former `buildStage1SignalPool` file-metadata branch (DD #3b — function relocation, NOT authority transfer; `apply(to:input:)` still owns the boost/re-select math and reads `BPMResult.candidates` directly).
3. **`analyzeBPM` consumes `pre.pool`** via `if let pool = pre.pool` (R8 — no force-unwrap), rebuilding the trace via the FMA-12 explicit-`BPMResult`-rebuild pattern. The post-hoc `buildStage1SignalPool` helper is deleted (zero live callers).
4. **`@Tag(.stage2Floor)` scaffold** added to `StageFloorTags.swift` (file comment updated to document both tags + SwiftPM `--filter` caveat) and applied alongside `@Tag(.stage1Floor)` on the four `metadataPolicy = .disabled` tests.

**Verification (all 9 ACs satisfied):** `make test` 443/96 (delta +0); four floor tests pass; OA300 Acc1 58/82 + Acc2 74/82 UNCHANGED; GiantSteps Acc1 537/661 + Acc2 546/661 UNCHANGED; 5 audit recipes zero matches pre + post; `merge`/`apply` signatures + `EnsembleCombiner.combine` call site all unchanged; trace-path relocation guard (`SignalPoolTests` ×3) passes — proving `signalParticipationTrace` content is byte-identical after the build moved from `analyzeBPM` into `runPreCorroborationPipeline`.

**Hand-offs / debt created here (surface at close-out):**
- **Story 6.4 apply-removal (DD #1, R3):** `MetadataCorroborator.apply(to:input:)` survives this story per the supersession. Its removal is NOT currently a named AC in Story 6.4's epic ACs (epics.md:506-534, which only *imply* it via "merge operates directly on the pool — no intermediate arbiter"). **When Story 6.4 is spec-created, the apply-removal MUST be promoted to an explicit 6.4 AC** or it becomes the deliverable nobody contracted.
- **Story 6.4 load (DD #2, R5):** Story 6.4 now carries SIX coupled changes — (1) `merge` carrier-type flip, (2) `apply` removal + body rewrite, (3) `git mv MetadataCorroborator.swift` into `SignalPool/` (DD #7), (4) `UnifiedSignalPool` Float-score enrichment, (5) `EnsembleCombiner` removal, (6) byte→semantic test swap. Architecture calls Stage 3 "a single mechanical PR"; it will not be mechanical with these deferrals. **Evaluate a 6.4 pressure-release split at 6.4 spec-create.**
- **Story 6.5 weight seam (DD #6, R7):** the Stage `weight: Double = 1.0` literal now spans TWO sites — the local in `buildStage2SignalPool` AND the `weight:` argument passed to `MetadataCorroborator.signalParticipationEntries`. Story 6.5's weight-value evolution must lift both.

**Pending operator action (per project-context.md operator-owned-closeout discipline):**
- `/bmad-code-review` on a different LLM than this dev session (project convention) — or via the Codex MCP arm.
- Final commit on the 1Password GPG signer. Suggested message: `Story 6-3: KDD-A6 Stage 2 — pipeline builds UnifiedSignalPool + MetadataCorroborator owns metadata participation`.
- Optional: bundle the still-pending mid-Epic-6 `architecture.md` amendment commit (DD #9) — not a Story 6.3 deliverable.

### File List

**UPDATED (Sources, 2):**
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `PreCorroborationOutput.pool: UnifiedSignalPool?`; new private `buildStage2SignalPool` (post-merge, gated on `merged?.trace != nil`); `runPreCorroborationPipeline` returns the pool; `analyzeBPM` consumes `pre.pool`; former `buildStage1SignalPool` deleted
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — new internal `signalParticipationEntries(for:weight:)` helper; `apply(to:input:)` unchanged

**UPDATED (Tests, 2):**
- `Tests/BoomBoomBoomKitTests/StageFloorTags.swift` — added `@Tag static var stage2Floor`; file comment documents both tags + the SwiftPM `--filter` caveat
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — `.tags(.stage1Floor, .stage2Floor)` on the four `metadataPolicy = .disabled` tests

**UPDATED (artifacts, 2):**
- `_bmad-output/implementation-artifacts/6-3-kdd-a6-stage-2-corroborator-and-pipeline-pool-migration.md` — this story file (frontmatter `baseline_commit`, task checkboxes, Dev Agent Record, Change Log, Status)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status flip + last_updated

## Change Log

| Date | Change |
|---|---|
| 2026-05-28 | Story 6.3 implemented (KDD-A6 Stage 2). `runPreCorroborationPipeline` builds + emits the `UnifiedSignalPool` (new `PreCorroborationOutput.pool`, gated on `merged?.trace != nil`); `MetadataCorroborator` owns metadata `SignalParticipation` production via new `signalParticipationEntries(for:weight:)` helper; `analyzeBPM` consumes `pre.pool`; former `buildStage1SignalPool` deleted; `@Tag(.stage2Floor)` scaffold added + applied to the four `metadataPolicy = .disabled` tests. Frozen `merge`/`apply` signatures + `EnsembleCombiner` untouched. All 9 ACs satisfied; 443/96 tests (delta +0); OA300 58/82+74/82 and GiantSteps 537/661+546/661 unchanged. Status `ready-for-dev → in-progress → review`. |
