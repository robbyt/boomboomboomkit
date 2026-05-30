---
baseline_commit: 011f927
---

# Story 6.5b: Semantic Stage-3 flip — pool-authoritative two-phase `BPMSelectionPolicy.select` + `apply`→pool-vote + atomic byte→semantic swap (Half B of KDD-A6 Stage 3)

Story ID: 6.5b
Story Key: 6-5b-semantic-stage3-flip
Epic: 6 — Unified-signal-pool ensemble (Tier-1 boundary collapse). The genuine semantic flip half of the 6.5 split; the corroboration boundary finally collapses into the pool.
Status: ready-for-dev

> **⛔ PREREQUISITE — gated on Story 6.5a.** 6.5b references types 6.5a creates (`BPMSelectionPolicy`, `SignalWeights`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`). Do NOT start `/bmad-dev-story 6-5b` until 6.5a has landed on `rterhaar/epic-6`. **The real baseline is 6.5a's squash commit** (unknown at authoring; `011f927` in the frontmatter is the floor). Re-validate this spec's line numbers against 6.5a's landed state before dev — 6.5a renames + promotes files, so paths/lines shift.

**FRs covered:** FR-1, FR-6, FR-7. **KDDs implemented:** A3 (effectiveVote/weighting), A6 Stage 3 (the genuine semantic flip).

## Scope clarification (read first)

6.5b performs the **semantic Stage-3 flip** that 6.4b's B-cascade deferred: it makes `UnifiedSignalPool` authoritative, replaces the post-merge `apply` + `combineEnsemble` cross-signal boundary with a pool-based selection, and atomically swaps the byte-equality floor for semantic-equality. This is the **first intentional semantic change to selection since Epic 3** — it is guarded by **output-equivalence** (same winner/bpm/confidence outcomes as today's `merge`→`apply`→`combineEnsemble` chain), NOT byte-equality. The default-path accuracy floors (OA300 58/74, GiantSteps 537/546) must hold at zero delta.

This spec is **post-cascade**: the 9-reviewer validation→party-mode→Codex pass on the 6.5 monolith ratified two corrections that reshape Half B (DD #1, DD #2 below). It does NOT re-open them.

## Key Design Decisions

1. **DD #1 — TWO-PHASE `select`, widened signature (Codex tie-break ratification).** The architecture-literal `select(from:pool:weights:equivalence:)` 3-arg form is **non-implementable** — it drops the `strategy`/`candidateCount`/`votingPolicy`/`votingThreshold` state the 8 cross-window strategies require, so it cannot reproduce `merge`. **Resolution:** one pool-consuming entry point that runs two phases:
   - **Phase 1 — cross-WINDOW aggregation (retained, byte-preserved).** The existing 8-strategy `merge` body (clustered/voting math) collapses the per-window DSP candidates → one merged DSP `BPMResult`, IDENTICAL to today's output. Keep this code verbatim (rename only).
   - **Phase 2 — cross-SIGNAL fusion.** Fold that single DSP voice with ML / metadata / beat-grid voters (the former `apply` + `combineEnsemble`, re-expressed).
   - **Signature** (instance method on `BPMSelectionPolicy`, defaults so the 41 call sites migrate cleanly): `func select(from pool: UnifiedSignalPool, candidateCount: Int, weights: SignalWeights = .default, equivalence: OctaveEquivalencePolicy = .default, votingPolicy: VotingPolicy = .simpleMajority, votingThreshold: Double = 0.0) -> BPMResult?`. The raw per-window DSP candidates NEVER independently outvote ML/metadata — that is FR-6 (DD #6). (party-mode Winston/Amelia/Mary/John + Codex unanimous on the two-phase shape; consistency-lens dissented toward single-pass but conceded FR-6/output-equivalence need the pre-pass.)

2. **DD #2 — MULTIPLICATIVE corroboration, NOT additive votes (the root semantic hazard, Codex fix).** Re-expressing `apply`'s ×1.25 multiplicative boost-and-reselect as additive `effectiveVote = signalConfidence × signalWeights[source]` is **not algebraically equivalent** — the winner-promotion (128@0.5 ×1.25 = 0.625 > 140@0.5) is not guaranteed to survive, making output-equivalence (DD #10) unprovable. **Resolution:** keep the multiplicative transform verbatim inside Phase 2; `SignalWeights.fileMetadata` SCALES the boost strength, it does NOT replace the transform with additive vote mass. Exact arithmetic (per DSP candidate, over the merged candidate set):
   ```
   let metadataScale = weights.fileMetadata
   if metadataScale == 0 { adjusted = original }                                   // metadata disabled → no boost/penalty/reselection (the .disabled identity)
   else if candidateMatchesAcceptedMetadata {
     let boost = 1.0 + metadataScale * (corroborationBoost - 1.0)                   // corroborationBoost = 1.25
     adjusted = min(original * boost, maxBoostedConfidence)                         // maxBoostedConfidence = 0.95
   } else if skepticismPenaltyApplies {
     let penalty = 1.0 - metadataScale * (1.0 - skepticismPenalty)                  // skepticismPenalty = 0.85
     adjusted = original * penalty
   } else { adjusted = original }
   ```
   Winner is re-selected from the adjusted pool (tiebreak: higher-original-score → lower-window-index). With `fileMetadata = 1.0` (default) the 140-vs-128 promotion is EXACTLY preserved (128 → 0.625 wins); with `fileMetadata = 0` metadata is inert. `effectiveVote = signalConfidence × signalWeights[source]` (KDD-A3) governs the dsp/ml/beat-grid weighting in Phase 2, but the metadata winner-promotion is the multiplicative transform above — these are distinct mechanisms (the architecture's "additive peer voter" framing for metadata is superseded here).

3. **DD #3 — atomic byte→semantic swap, one commit, no red interval (KDD-A6 / architecture.md:343).** In the SAME commit as the Phase-1/2 flip: delete the **4 `@Tag(.stage1Floor,.stage2Floor)` tests** (`MetadataCorroborationTests.swift` `@Test` L419/461/500/531) + **`StageFloorTags.swift`** (NOT a phantom `MergeByteEqualityTests.swift` — that never existed, 6-4 DD #1); introduce **`MergeSemanticEqualityTests.swift`** reproducing the **14** `MetadataCorroboratorUnitTests` behaviors as pool-vote assertions (not 11 — the parent spec under-counted). **De-risk (Codex):** keep `apply` temporarily as a TEST-ONLY oracle that `MergeSemanticEqualityTests` cross-checks the new pool path against, then delete `apply` in the same commit once green. **Verification (validate-testing fix):** `swift test --filter-tag` is NOT a real SwiftPM flag — verify the floor retirement by a source grep that `.tags(.stage1Floor` / `.tags(.stage2Floor` returns zero in `Tests/` and `StageFloorTags.swift` is gone, NOT by a `--filter-tag` run.

4. **DD #4 — corroboration-boundary preservation (FR-7 + W51).** The 14 `MetadataCorroboratorUnitTests` behaviors are the semantic contract `MergeSemanticEqualityTests` must reproduce at the value level: `emptyPassThrough`, `sameTempoCorroboration` (→0.75), `octaveCorroboration` (.half/.double), `winnerPromotion` (140@0.5 vs 128@0.5 → 128), `intraFileConflict`, `threeTagPartialAgreement`, `unanimousConsensus`, `unanimousDisagreesPenalty` (→0.595), `singleUncorroboratedIgnored`, `divideByZeroGuard` (boostApplied 1.0), `confidenceClamp` (0.95), `tripletGateOff`/`tripletGateOn`, `parseRejectionPassthrough`. Constants pinned: `corroborationBoost 1.25`, `skepticismPenalty 0.85`, `maxBoostedConfidence 0.95`, `corroborationTolerance 0.03`, octave 1.92-2.08, triplet 1.45-1.55/2.85-3.15. `apply` is REMOVED (the 6.3 DD #1 obligation discharged); intra-file-conflict + skepticism → `.demoted(reason:)` pool votes (W51); corroborated → `.present`. Reuse `MetadataCorroborator.signalParticipationEntries(for:weight:)`.

5. **DD #5 — read-seam wiring (the three deferred seams).** (a) `WeightedSignal.score: Float?` gets its FIRST production reader — Phase 2 reads the exact Float fusion score off the pool, NO `Double→Float` reconstruction (1 existing TEST reader at `SignalPoolTests.swift:256` must stay green). (b) Add `SignalParticipation.score` accessor mirroring `.confidence`, surfacing `WeightedSignal.score` for `.present`/`.demoted`, nil for `.absent`/`.abstained`. (c) REMOVE `fileMetadataStage1TraceOnlyDefault` (`WeightedSignal.swift:41`) — metadata presence is now `SignalWeights.fileMetadata`-weighted, not the 1.0 sentinel.

6. **DD #6 — FR-6 per-source-family normalization (the absent FR, now an AC).** "Normalize per source family, not per signal row; multi-window DSP must not swamp single-instance ML/metadata." The two-phase design (DD #1) STRUCTURALLY satisfies this: Phase 1 collapses N DSP windows → ONE dsp voice BEFORE Phase 2's cross-signal fusion, so DSP cannot outvote single ML/metadata by window count. **AC #6 makes this testable:** a fixture with M DSP windows agreeing on BPM X and one ML/metadata vote for Y must not let DSP win by sheer window count beyond what one weighted DSP voice earns. (party-mode Mary/John: leaving FR-6 unrepresented while DD #1 was open was the requirements hole; the pre-pass resolves it.)

7. **DD #7 — W61 empty-pool → Optional `nil`, NOT precondition-crash (library safety).** `select` returns `BPMResult?`; empty pool → `guard !pool.entries.isEmpty else { return nil }`. Do NOT `precondition`-crash a library on an empty pool (party-mode Winston/validate-swift). FR-8 (empty→nil) satisfied via the Optional.

8. **DD #8 — merge-frozen-rule supersession (now the flip actually happens).** project-context.md states the freeze 4× (§Post-Pipeline Corroboration Boundary :89-91; cascade-review :148; Critical Don't-Miss :179). 6.5b breaks it (pool-param flip + `apply`-boundary removal), sanctioned by architecture.md:343 "Pre-1.0 break authorized." **Update/retire those 4 subsections IN THIS COMMIT** so the SoT matches shipped code; the :148 cascade-review obligation is satisfied by the 78-ref/41-site count + the flip being the architecture.

9. **DD #9 — riders batched.** W48 (`"stage1-eval-deferred"` → named constant on `AbstainReason`), 6-3-D1 (Stage-neutral rename of the constant + literal — the byte→semantic swap un-pins verbatim preservation), W56 (drop `WeightedSignal.source` OR add agreement `precondition` now that `SignalWeights` lands), 6-3-D2 (no-candidates `.dsp .abstained(.sourceSpecific("no-candidates"))` + all-tags-rejected `.fileMetadata .absent` fixtures against `MergeSemanticEqualityTests`). W61 is DD #7.

10. **DD #10 — output-equivalence is the floor; no-rollback risk is mitigated by the oracle + the pre-pass.** DD #4-equivalence (same winner/bpm/confidence as the old chain) is the acceptance gate, asserted by `MergeSemanticEqualityTests` (value-level) + the OA300/GiantSteps CI floors at zero delta. The party-mode no-rollback concern is mitigated by (a) the retained Phase-1 math (byte-preserved → the delta is ONLY the cross-signal re-expression), and (b) the `apply` test-oracle (DD #3) catching divergence before `apply` is deleted. If the floors regress during dev, the documented fallback is to keep `apply` live and gate the pool path behind a flag for a follow-up — surface to operator, do NOT silently relax the floor.

11. **DD #11 — `UnifiedSignalPool` becomes a real data model, not a trace shape (Codex).** Today it is `internal struct { let entries: [SignalParticipationTraceEntry] }` (trace-only, nil on the default path). Authoritative selection needs structured per-window DSP records (carrying the exact `WeightedSignal.score` Float) + the ML + metadata voters — NOT richer trace entries. Decide whether the pool gains a typed `dspWindows: [...]` field or `select` takes the window set alongside the pool. `SignalParticipationTraceEntry` stays frozen-shape (6.4 DD #11) for the trace; the authoritative pool is a distinct concern.

12. **DD #12 — concurrency-inert.** `select` is a method on the value-type `BPMSelectionPolicy`; pool/weights/equivalence are `Sendable` value types; no actor isolation/async added.

13. **DD #13 — this spec is post-cascade.** The validation→party-mode→Codex tie-break already ran on the 6.5 monolith (2026-05-30); DD #1/#2 are its ratified resolutions. A lighter re-validation against 6.5a's landed state is the only pre-dev gate remaining (the prerequisite banner).

## Acceptance Criteria

1. **Two-phase `select` (FR-1, DD #1):** `BPMSelectionPolicy.select(from:candidateCount:weights:equivalence:votingPolicy:votingThreshold:) -> BPMResult?` replaces the cross-signal `merge`+`apply`+`combineEnsemble` chain; Phase 1 = the byte-preserved 8-strategy cross-window aggregation, Phase 2 = cross-signal fusion. The 41 former `.merge(` call sites migrate. `UnifiedSignalPool` authoritative (not nil on the default path); empty → `nil` (DD #7).
2. **Multiplicative corroboration (DD #2):** Phase 2 uses the multiplicative boost/penalty/reselection scaled by `SignalWeights.fileMetadata` per DD #2's arithmetic; `winnerPromotion` exactly preserved at `fileMetadata=1.0`; inert at `fileMetadata=0`.
3. **`apply` removed (FR-7, DD #4):** `MetadataCorroborator.apply` deleted (after serving as the test oracle); boost/penalty/reselection re-expressed; intra-file-conflict/skepticism → `.demoted` (W51); the 14 behaviors + constants preserved at value level; 1 prod + 15 test sites migrated.
4. **Atomic byte→semantic swap (DD #3):** 4 tagged tests + `StageFloorTags.swift` deleted; `MergeSemanticEqualityTests.swift` introduced (same commit); `.tags(.stage1Floor`/`.stage2Floor` grep → zero in `Tests/`.
5. **Read-seam (DD #5):** `WeightedSignal.score` first production reader; `SignalParticipation.score` accessor added; `fileMetadataStage1TraceOnlyDefault` removed; `SignalPoolTests.swift:256` stays green.
6. **FR-6 per-source-family normalization (DD #6):** a multi-window-DSP-vs-single-ML/metadata fixture proves DSP doesn't win by window count beyond one weighted DSP voice.
7. **Riders (DD #9):** W48 named constant, 6-3-D1 Stage-neutral rename, W56, 6-3-D2 fixtures.
8. **SoT supersession (DD #8):** the 4 project-context.md merge-frozen subsections updated/retired in-commit.
9. **Accuracy/perf floors at zero delta (DD #10):** OA300 `acc1 ≥ 57` ∧ `acc2 ≥ 73`, GiantSteps `≥537`/`≥546`; 58/74 + 537/546 held; perf ≤15%. `MergeSemanticEqualityTests` proves value-level output-equivalence to the pre-flip chain.
10. **Trace audit clean:** 5-recipe `bpm-diagnostic-trace` zero pre+post; `MLExecutionDecision`/`EnsembleWeightResolution` typed-evidence (if added) NaN-safe per 6.5a DD #3.

## Tasks / Subtasks

- [ ] Task 1 — Pre-flight (AC: #9) — re-baseline on 6.5a's squash; re-verify line numbers (6.5a shifted them); green baseline; trace audit zero; capture the 14-behavior `apply` outputs as the oracle fixture.
- [ ] Task 2 — `UnifiedSignalPool` authoritative data model (AC: #1, DD #11) — structured per-window DSP records carrying `WeightedSignal.score`; pool non-nil on default path.
- [ ] Task 3 — Phase 1 retain + Phase 2 build `select` (AC: #1, #2, #6) — keep the 8-strategy aggregation verbatim; build the multiplicative cross-signal fusion (DD #2); FR-6 pre-pass collapse; wire read-seam + `.score` accessor + remove the 1.0 sentinel.
- [ ] Task 4 — `apply` removal + W51 (AC: #3) — re-express as `.present`/`.demoted` votes; migrate 1 prod + 15 test sites; keep `apply` as oracle until Task 5 green.
- [ ] Task 5 — Atomic swap (AC: #4) — SAME COMMIT as Tasks 3/4: delete 4 tagged tests + `StageFloorTags.swift`; author `MergeSemanticEqualityTests` (14 behaviors + winner-promotion + 6-3-D2 fixtures + FR-6 fixture); delete `apply` once green.
- [ ] Task 6 — Riders + SoT (AC: #7, #8) — W48/6-3-D1/W56; update the 4 project-context.md merge-frozen subsections.
- [ ] Task 7 — Verification gauntlet (AC: #9, #10) — `make fmt`/`lint`/`test`; OA300/GiantSteps zero-delta (the equivalence proof); `make perf-benchmark`; trace audit; diff-scope manifest (phase-1-retained / phase-2-new / apply-removal / test-swap / riders).

## Dev Notes

### Files to read before editing (UPDATE — verify against 6.5a's landed state)
- `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift` (was `CandidateMergeStrategy.swift`, renamed by 6.5a) — the 8-strategy `merge` body becomes Phase 1 of `select`. PRESERVE all 8 cases' cluster/voting math + tiebreak + 2% tolerance + VotingPolicy dispatch byte-exact.
- `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` — `apply` (boost ×1.25 :183-188, reselection :210-225, confidence math :239-263) becomes Phase 2's multiplicative transform (DD #2); `signalParticipationEntries(for:weight:)` (:349-396) the vote source. PRESERVE the 14-behavior contract + constants.
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift` — `score: Float?` (:24) first reader; `fileMetadataStage1TraceOnlyDefault` (:41) removed.
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift` — add `.score` accessor (mirror `.confidence` :15-24); 4-state contract preserved.
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift` — `{ let entries: [SignalParticipationTraceEntry] }` becomes authoritative (DD #11).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `analyzeBPM` (:321-406) rewires: `merge`(:825)→Phase 1 of `select`, `apply`(:362) removed, `combineEnsemble`(:387) folded into Phase 2; `buildStage2SignalPool`(:875) gains the authoritative records + the `"stage1-eval-deferred"` literal (:931) → named constant (W48). PRESERVE: `.dspOnly` short-circuit, ML-after-selection ordering, the `.disabled` output-identity path.
- Tests: `MetadataCorroborationTests.swift` (4 tagged tests + 14 `MetadataCorroboratorUnitTests`); `StageFloorTags.swift` (delete); `SignalPoolTests.swift:256`/:285.

### Previous Story Intelligence (6.5a + 6.4b)
1. 6.5a left `merge`/`apply` behavior byte-unchanged + the type surface complete (`BPMSelectionPolicy`, `SignalWeights`, etc.) — 6.5b lands the semantic change against that proven-inert base. The byte floor was green at end-of-6.5a; 6.5b is the commit that retires it (atomically, DD #3).
2. The cascade's two killer corrections (two-phase `select`, multiplicative-not-additive) are baked into DD #1/#2 — do NOT revert to the architecture-literal 3-arg `select` or additive votes.
3. NaN-safety (6.5a DD #3): any new Double-carrying Hashable typed-evidence must be NaN-guarded; isFinite-first clamp.
4. Operator-owned closeout: `/bmad-code-review` (separate LLM / Codex arm) + GPG-signed commit → PR into `rterhaar/epic-6`.

### References
- [Source: 6-5-pressure-release.md] — the split + the two ratified corrections.
- [Source: 6-5a-byte-inert-type-taxonomy.md] — the type surface 6.5b consumes.
- [Source: architecture.md:335-345, 379, 1188-1202] — KDD-A6 Stage 3 + effectiveVote + post-collapse flow.
- [Source: 6-4 spec Hand-off + deferred-work.md] — the deferred semantic flip + riders.
- [Source: 6-5 review cascade 2026-05-30] — see Review Findings.

## Review Findings

From the validation→party-mode→Codex cascade (9 reviewers) on the 6.5 monolith; the Half-B-relevant findings are RESOLVED in the DDs above:
- **Two-phase `select` (Codex, must-fix → DD #1):** the 3-arg signature drops required state; widened + two-phase.
- **Multiplicative ≠ additive (Codex root-hazard → DD #2):** keep the transform, scale by `SignalWeights.fileMetadata`.
- **FR-6 absent (Mary/John → DD #6):** now an AC; the pre-pass satisfies it.
- **`--filter-tag` invalid (validate-testing → DD #3):** grep-based verification.
- **W61 precondition-crash (Winston/validate-swift → DD #7):** Optional `nil`.
- **`apply`-as-oracle (Codex, should-fix → DD #3):** de-risk the swap.
- **14 not 11 behaviors (validate-testing/consistency → DD #4):** corrected.
- **UnifiedSignalPool too thin (Codex → DD #11):** real data model, not trace shape.

## Dev Agent Record

### Agent Model Used
claude-opus-4-8 (1M)

### Debug Log References

### Completion Notes List

### File List

## Change Log

| Date | Change |
|---|---|
| 2026-05-30 | Story 6.5b authored via `/bmad-create-story 6-5b` as the semantic Half B of the 6.5 split (post the validation→party-mode→Codex cascade). Captures the cascade's two ratified corrections: (1) TWO-PHASE `select` with a widened signature (the 3-arg form is non-implementable — drops strategy/candidateCount/votingPolicy/votingThreshold); (2) MULTIPLICATIVE corroboration scaled by `SignalWeights.fileMetadata` (NOT additive votes — the winner-promotion would not survive additive re-expression). Plus FR-6 as a real AC, the grep-based floor-retirement verification, W61 Optional, the `apply`-as-oracle de-risk, and the 14-behavior contract. `development_status[6-5b-…]` `backlog → ready-for-dev` (GATED on 6.5a landing — see prerequisite banner). Pending: 6.5a lands → re-validate line numbers → `/bmad-dev-story 6-5b`. |
