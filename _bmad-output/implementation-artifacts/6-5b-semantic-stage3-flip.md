---
baseline_commit: 4650bf0
---

# Story 6.5b: Semantic Stage-3 flip — pool-authoritative two-phase `BPMSelectionPolicy.select` + `apply`→pool-vote + atomic byte→semantic swap (Half B of KDD-A6 Stage 3)

Story ID: 6.5b
Story Key: 6-5b-semantic-stage3-flip
Epic: 6 — Unified-signal-pool ensemble (Tier-1 boundary collapse). The genuine semantic flip half of the 6.5 split; the corroboration boundary finally collapses into the pool.
Status: done

> **✅ PREREQUISITE CLEARED — Story 6.5a landed `4650bf0` on `rterhaar/epic-6` (PR #22, 2026-05-30).** The types 6.5b consumes (`BPMSelectionPolicy`, `SignalWeights`, `OctaveEquivalencePolicy`, `MLExecutionPolicy`, the 5-case `EnsemblePolicy` facade) are all present. `baseline_commit` updated to the landed squash `4650bf0`. This spec was RE-VALIDATED against that landed state on 2026-05-30 via `/bmad-create-story` (see Re-validation Findings + Change Log): line numbers reconciled, and the **KDD-A5 activation gap closed** (DD #14 / AC #11, per operator decision — 6.5b owns activating `.default` + `.weightedVoting`). If epic-6 advances past `4650bf0` before dev starts, re-run a line-number pass — only `AudioAnalysisService.swift` drifts materially; the `SignalPool/` files and the 4 tagged floor tests are stable.

**FRs covered:** FR-1, FR-6, FR-7. **KDDs implemented:** A3 (effectiveVote/weighting), A5 (`weightedVoting` consumer + `EnsembleWeightResolution` — activation gap closed by the 2026-05-30 re-validation per operator decision; see DD #14), A6 Stage 3 (the genuine semantic flip).

## Scope clarification (read first)

6.5b performs the **semantic Stage-3 flip** that 6.4b's B-cascade deferred: it makes `UnifiedSignalPool` authoritative, replaces the post-merge `apply` + `combineEnsemble` cross-signal boundary with a pool-based selection, and atomically swaps the byte-equality floor for semantic-equality. This is the **first intentional semantic change to selection since Epic 3** — it is guarded by **output-equivalence** (same winner/bpm/confidence outcomes as today's `merge`→`apply`→`combineEnsemble` chain), NOT byte-equality. The default-path accuracy floors (OA300 58/74, GiantSteps 537/546) must hold at zero delta.

6.5b ALSO **activates the two `EnsemblePolicy` cases 6.5a shipped inert** — `.default` (balanced ensemble) and `.weightedVoting(SignalWeights)` (KDD-A5 weighted consumer) — as net-new OPT-IN policies (DD #14, added by the 2026-05-30 re-validation per operator decision). These sit OUTSIDE the output-equivalence floor: `Options.ensemblePolicy` stays `.dspOnly`, so they change nothing on the default path; the floor governs only the three pre-6.5b live policies (`.dspOnly`/`.mlOnly`/`.highestConfidence`).

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

14. **DD #14 — KDD-A5 activation: `.default` + `.weightedVoting` go LIVE in 6.5b (operator decision, 2026-05-30 re-validation).** 6.5a shipped both `EnsemblePolicy` cases as byte-inert placeholders whose case docs + the `combineEnsemble` switch comment (`AudioAnalysisService.swift:587-591`) explicitly defer activation to 6.5b; architecture.md:432 maps the Demo "Default"/"ML augmented"/"Trust file tags" presets onto them, and architecture.md:742 + epics.md:45 assign **KDD-A5** (the `weightedVoting` consumer + `EnsembleWeightResolution`) to Story 6.5. The 6.5b spec as first authored omitted this (header listed only A3/A6, treated `EnsembleWeightResolution` as "(if added)"); the re-validation closes the gap. **Resolution:**
    - `.weightedVoting(weights)` resolves via Phase 2's pool-authoritative per-source weighted selection: `effectiveVote = signalConfidence × weights[source]` (KDD-A3) over the authoritative pool (the single Phase-1 DSP voice + ML + metadata + beat-grid). This is the FIRST live consumer of the case's `SignalWeights` payload.
    - `.default` resolves to the **balanced peer ensemble** — semantically identical to `.weightedVoting(.default)` (equal weights `dsp=ml=fileMetadata=beatGrid=1.0`), the "genuine default ensemble resolution" the case doc promises. (Dev confirms the exact pool tiebreak; the spec pins equal-weight.)
    - **Default-path byte-identity is UNAFFECTED:** `Options.ensemblePolicy` stays `.dspOnly` (`AudioAnalysisService.swift:198`), so the OA300/GiantSteps floors remain measured on `.dspOnly` → DSP-wins. `.default`/`.weightedVoting` are net-new OPT-IN policies NOT under the output-equivalence floor — DD #10's equivalence gate governs only `.dspOnly`/`.mlOnly`/`.highestConfidence` (the three live pre-6.5b policies).
    - **Split the landed switch arm:** 6.5a's `case .default, .dspOnly, .weightedVoting: return dspWinner` (L587-591) splits — `.dspOnly` keeps DSP-wins; `.default`/`.weightedVoting` route to live weighted resolution. Update those 3 "lands in 6.5b" doc/comment sites to describe shipped behavior.
    - **`EnsembleWeightResolution` typed-evidence** (architecture.md:742) is emitted on the trace when a weighted policy resolves; NaN-safe per 6.5a DD #3 (isFinite-first; drop `Hashable` or use bitPattern-`Equatable` if it carries `Double`). AC #10's "(if added)" is now firm.

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
10. **Trace audit clean:** 5-recipe `bpm-diagnostic-trace` zero pre+post; `EnsembleWeightResolution` typed-evidence (now firm per DD #14) + any `MLExecutionDecision` evidence NaN-safe per 6.5a DD #3.
11. **KDD-A5 activation (FR-7 peer-weighting, DD #14):** `.weightedVoting(weights)` performs live per-source weighted pool selection consuming the case's `SignalWeights`; `.default` resolves to the balanced (equal-weight) peer ensemble; both consume the authoritative pool; `EnsembleWeightResolution` emitted on resolution. `Options.ensemblePolicy` default stays `.dspOnly` (default-path byte-identity intact). The 3 "lands in 6.5b" sites in 6.5a's code (`combineEnsemble` L587-591, `EnsemblePolicy.default` doc, `.weightedVoting` doc) updated to shipped behavior. A `.weightedVoting(SignalWeights(dsp:1.0, ml:1.5, …))` fixture proves ML up-weighting changes the winner vs `.default`.

## Tasks / Subtasks

- [x] Task 1 — Pre-flight (AC: #9) — re-baselined on 6.5a's squash `4650bf0`; line numbers re-verified (Re-validation Findings); green baseline `459/100`; trace audit zero; the `apply` oracle is cross-checked by `MergeSemanticEqualityTests.expectMatchesOracle` (DD #3 de-risk — kept apply, cross-checked at scale=1.0).
- [x] Task 2 — `UnifiedSignalPool` authoritative data model (AC: #1, DD #11) — flipped to `{ dspWindows, metadataInput, candidateCount, mlParticipation, weight }`; built UNCONDITIONALLY in `runPreCorroborationPipeline` (authoritative, not nil on the default path); DSP `.present` entries carry the exact `WeightedSignal.score` read off the pool via the new `SignalParticipation.score` accessor.
- [x] Task 3 — Phase 1 retain + Phase 2 build `select` (AC: #1, #2, #6) — `BPMSelectionPolicy.select(from:weights:equivalence:votingPolicy:votingThreshold:)` runs Phase 1 (`merge`, verbatim) + Phase 2a (multiplicative corroboration scaled by `weights.fileMetadata`, DD #2); FR-6 pre-pass collapse (5-window→1-voice test); read-seam + `.score` accessor + 1.0 sentinel removed (DD #5).
- [x] Task 3b — KDD-A5 activation (AC: #11, DD #14) — split the `.default, .dspOnly, .weightedVoting` arm; `.weightedVoting(weights)` → live per-source weighted resolution (effectiveVote = conf×weights[source]), `.default` → balanced equal-weight; NaN-safe `EnsembleWeightResolution` evidence; `invokesMLInference` flipped true for both; 3 doc/comment sites updated; ML-up-weight winner-change fixture green. `Options.ensemblePolicy` default stays `.dspOnly`.
- [x] Task 4 — corroboration fold + W51 (AC: #3) — standalone `apply` invocation removed from the service (folded into `select` Phase 2a); arithmetic preserved (DR-2); intra-file-conflict → `.demoted(reason:)` pool votes (W51, construction-time-knowable case); skepticism demotion reflected in `MetadataBPMEvidence` (`dsp-disagreement`, post-corroboration).
- [x] Task 5 — Atomic swap (AC: #4) — deleted the 4 `.stage1Floor/.stage2Floor` tagged tests + `StageFloorTags.swift`; authored `MergeSemanticEqualityTests` (14 behaviors via `select` + oracle cross-check + winner-promotion + 6-3-D2 + FR-6 + ML-up-weight + metadataScale fixtures); `.tags(.stage1Floor/.stage2Floor)` grep → zero in `Tests/`.
- [x] Task 6 — Riders + SoT (AC: #7, #8) — W48 (`AbstainReason.mlEvalDeferred`) + 6-3-D1 Stage-neutral rename + 6-3-D2 (`AbstainReason.noCandidates`) + W56 (kept `WeightedSignal.source`, agreement by construction); updated the 4 project-context.md selection-boundary subsections (the §heading + 3 bullets + the :148 cascade + :179 don't-miss rules).
- [x] Task 7 — Verification gauntlet (AC: #9, #10, #11) — `make fmt`/`lint` clean (1 known LUFS TODO); `make test` **478/104 pass**; **OA300 58/82·74/82 ZERO DELTA**, **GiantSteps 537/661·546/661 ZERO DELTA** (+ the GiantSteps "matches pre-Story baseline EXACTLY" byte-identity tests pass); `make perf-benchmark` **+1.2%** (≤15%); trace audit 5-recipe zero; KDD-A5 fixtures green + `EnsembleWeightResolution` NaN-safe.

## Dev Notes

### Files to read before editing (UPDATE — verify against 6.5a's landed state)
- `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift` (was `CandidateMergeStrategy.swift`, renamed by 6.5a) — the 8-strategy `merge` body (`merge` :71, `mergeClustered` :306, `mergeByWindowVoting`+VotingPolicy dispatch :152-177 — verified stable at 4650bf0) becomes Phase 1 of `select`. PRESERVE all 8 cases' cluster/voting math + tiebreak + 2% tolerance + VotingPolicy dispatch byte-exact.
- `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` — `apply` (boost ×1.25 :183-188, reselection :210-225, confidence math :239-263) becomes Phase 2's multiplicative transform (DD #2); `signalParticipationEntries(for:weight:)` (:349-396) the vote source. PRESERVE the 14-behavior contract + constants.
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift` — `score: Float?` (:24) first reader; `fileMetadataStage1TraceOnlyDefault` (:41) removed.
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift` — add `.score` accessor (mirror `.confidence` :15-24); 4-state contract preserved.
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift` — `{ let entries: [SignalParticipationTraceEntry] }` becomes authoritative (DD #11).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — (line numbers reconciled to landed 4650bf0; 6.5a renumbered this file) `analyzeBPM` (:321, unchanged) rewires: `merge`(**:829**, was :825)→Phase 1 of `select`, `apply`(:362) removed, `combineEnsemble`(call :387, `switch` body :586+) folded into Phase 2; `buildStage2SignalPool`(def **:879**, was :875; call :845) gains the authoritative records + the `"stage1-eval-deferred"` literal (**:935**, was :931) → named constant (W48). **6.5a migrated 4 ML-gate sites from `!= .dspOnly` to `options.ensemblePolicy.invokesMLInference` (L333/511/790/932)** — that helper (true only for `.mlOnly`/`.highestConfidence`) is the canonical ML gate now; do NOT reintroduce `!= .dspOnly`. **Split the landed `case .default, .dspOnly, .weightedVoting: return dspWinner` arm (L587-591)** per DD #14. PRESERVE: `.dspOnly` DSP-wins behavior, ML-after-selection ordering, the `.disabled` output-identity path, the `Options.ensemblePolicy = .dspOnly` default (L198).
- Tests: `MetadataCorroborationTests.swift` (4 tagged tests + 14 `MetadataCorroboratorUnitTests`); `StageFloorTags.swift` (delete); `SignalPoolTests.swift:256`/:285.

### Previous Story Intelligence (6.5a + 6.4b)
1. 6.5a left `merge`/`apply` behavior byte-unchanged + the type surface complete (`BPMSelectionPolicy`, `SignalWeights`, etc.) — 6.5b lands the semantic change against that proven-inert base. The byte floor was green at end-of-6.5a; 6.5b is the commit that retires it (atomically, DD #3).
2. The cascade's two killer corrections (two-phase `select`, multiplicative-not-additive) are baked into DD #1/#2 — do NOT revert to the architecture-literal 3-arg `select` or additive votes.
3. NaN-safety (6.5a DD #3): any new Double-carrying Hashable typed-evidence must be NaN-guarded; isFinite-first clamp. `MLExecutionPolicy` dropped `Hashable` and hand-wrote a `bitPattern`-reflexive `==` — mirror that for `EnsembleWeightResolution` (DD #14).
4. Operator-owned closeout: `/bmad-code-review` (separate LLM / Codex arm) + GPG-signed commit → PR into `rterhaar/epic-6`.
5. 6.5a landed `4650bf0` (PR #22). `EnsemblePolicy` is now a **5-case facade** (`.default`, `.dspOnly`, `.mlOnly`, `.highestConfidence`, `.weightedVoting(SignalWeights)`); `.allPolicies` (5) replaced `.allCases`, `.stableKey` replaced `.rawValue`. `invokesMLInference` (true only for `.mlOnly`/`.highestConfidence`) is the canonical ML gate at 4 sites (L333/511/790/932) — do NOT reintroduce `!= .dspOnly`. `.default` + `.weightedVoting` ship INERT (DSP-wins) with docs deferring activation to 6.5b → DD #14 discharges that. Copilot never reviewed #22 (server-side error); it merged on the 5-agent `/bmad-code-review`.

### References
- [Source: 6-5-pressure-release.md] — the split + the two ratified corrections.
- [Source: 6-5a-byte-inert-type-taxonomy.md] — the type surface 6.5b consumes.
- [Source: architecture.md:335-345, 379, 1188-1202] — KDD-A6 Stage 3 + effectiveVote + post-collapse flow.
- [Source: architecture.md:428-432, 742] — KDD-A5: `EnsemblePolicy.weightedVoting(SignalWeights)` + Demo preset map + `EnsembleWeightResolution` (DD #14 activation source).
- [Source: epics.md:45] — "Story 6.5 — KDD-A1 … + KDD-A2/A3/A4/A4a/A5 derivations" (A5 assigned to Story 6.5; 6.5b owns it per DD #14).
- [Source: 6-4 spec Hand-off + deferred-work.md] — the deferred semantic flip + riders.
- [Source: 6-5 review cascade 2026-05-30] — see Review Findings.
- [Source: 6.5a landed `4650bf0` / PR #22] — the inert placeholders + 3 "lands in 6.5b" deferral comments DD #14 discharges; see Re-validation Findings.

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

## Re-validation Findings (2026-05-30, against landed `4650bf0`)

`/bmad-create-story` re-validation pass after 6.5a landed (PR #22). Verified every file/line/symbol this spec cites against the landed tree.

**Scope gap CLOSED (operator decision):** 6.5a shipped `.default` + `.weightedVoting(SignalWeights)` inert, with docs in 3 sites deferring activation to 6.5b; architecture.md:432/742 + epics.md:45 assign KDD-A5 to Story 6.5; the spec omitted it. Operator chose **"6.5b owns it"** → DD #14 + AC #11 + Task 3b added. `Options.ensemblePolicy` stays `.dspOnly`, so the output-equivalence floor is unaffected.

**Line-drift reconciled (only `AudioAnalysisService.swift` moved — 6.5a edited it):**
| Symbol | Spec (vs 011f927) | Landed 4650bf0 |
|---|---|---|
| `analyzeBPM` | :321 | :321 ✓ |
| `MetadataCorroborator.apply` call | :362 | :362 ✓ |
| `combineEnsemble` call | :387 | :387 ✓ |
| `BPMSelectionPolicy.merge` call | :825 | **:829** |
| `buildStage2SignalPool` def | :875 | **:879** (call :845) |
| `"stage1-eval-deferred"` literal | :931 | **:935** (guard :932) |

**Stable — verified unchanged (6.5a did NOT renumber these; `MetadataCorroborator` was relocated to `SignalPool/` back in 6.4, not 6.5a):**
- 4 `@Tag(.stage1Floor,.stage2Floor)` tests EXACTLY at `MetadataCorroborationTests.swift` :419/:461/:500/:531 ✓
- `MetadataCorroboratorUnitTests` = **14** behaviors (:168–:397) — confirms DD #4's "14 not 11" ✓
- `StageFloorTags.swift` present (`@Tag` :30/:31) — to delete ✓
- `SignalPoolTests.swift:256` existing `.score` test reader (DD #5) ✓
- `WeightedSignal.score` :24, `fileMetadataStage1TraceOnlyDefault` :41 ✓
- `SignalParticipation` 4-state + `.confidence` accessor :15 ✓
- `UnifiedSignalPool` `{ let entries: [SignalParticipationTraceEntry] }` :14-15 (still trace-only — DD #11's authoritative remodel is unbuilt, as expected) ✓
- `MetadataCorroborator` `apply` :71, boost :187, confidence math :240-253, `signalParticipationEntries` :349 ✓

**`baseline_commit` 011f927 → 4650bf0** (the landed 6.5a squash; dev-story preserves an existing frontmatter value, so it is pinned to the true pre-dev HEAD).

## Dev Agent Record

### Agent Model Used
claude-opus-4-8 (1M)

### Debug Log References

**2026-05-30 — Green baseline:** `swift test --filter BoomBoomBoomKitTests` = **459 tests / 100 suites pass** at `4650bf0` (Task 1 pre-flight). `swift build` clean.

**2026-05-30 — Design resolution DR-1 (DD #1 implementability gap, dev-discovered, NOT in the monolith cascade).** Reading the production path revealed DD #1's premise — "one pure `select` that folds `apply` + `combineEnsemble`" — is **not implementable as a single pure pass**. `evaluateMLIfActive` is interleaved between `apply` and `combineEnsemble`: it runs AFTER metadata corroboration, reads the *post-corroboration* trace, performs pre/post cancellation checks, and mutates the trace for the `MLDiagnosticSnapshot`. Moving ML eval earlier would change the trace ML sees → breaks the explicitly-preserved "ML-after-corroboration / no-accuracy-change" contract (output-equivalence floor DD #10).
- **Resolution:** `BPMSelectionPolicy.select(...)` runs **Phase 1** (`merge`, verbatim) + **Phase 2a** (pool-authoritative multiplicative metadata corroboration scaled by `weights.fileMetadata` per DD #2). The **Phase 2b** cross-signal ML fusion (former `combineEnsemble` + KDD-A5 `.weightedVoting`/`.default` resolution) stays a thin post-ML-eval step in `AudioAnalysisService`, consuming the same authoritative pool. This is the only output-equivalence-safe option (the alternative — dragging cancellation + trace-mutation into a value-type method — is architecturally unsound and risks the no-accuracy-change contract). Deviation from DD #1's literal "fold combineEnsemble into select" is intentional and flagged here for the Codex blind-hunter review.

**2026-05-30 — Design resolution DR-2 (DD #4 reuse-vs-reimplement, regression-risk call).** DD #4 calls for `apply` "REMOVED" and "re-expressed as `.present`/`.demoted` pool votes." A from-scratch reimplementation of the intricate corroboration arithmetic (match → score-boost → re-select → confidence boost/penalty/clamp → divide-by-zero guard → evidence) carries high silent-regression risk on the core path. **Resolution:** PRESERVE the arithmetic as the single corroboration core, thread the DD #2 `metadataScale` parameter through it (default `1.0` → byte-reproduces today; 41 call sites + tests unchanged), and have Phase 2a call it over the authoritative pool. The "re-express as pool votes" intent is honored at the **participation/evidence layer** (`.present` for corroborated, `.demoted(reason:)` for intra-file-conflict/skepticism) layered on the preserved math, NOT by a risky from-scratch rewrite. The standalone post-merge `apply(to:input:)` service invocation is removed (folded into `select`); the math survives renamed+scaled. Byte-precision verified: `metadataScale=1.0` reproduces the `×1.25` boost exactly and the `×0.85` penalty round-trips to exactly `0.85`. Flagged for Codex review; if the operator wants the literal from-scratch re-expression, that's a follow-up.

**Byte/semantic-precision note.** The DD #2 score-boost `1.0 + scale·(1.25−1.0)` = `1.25` exactly at `scale=1.0` (power-of-two delta) → winner selection byte-stable; the penalty `1.0 − scale·(1.0−0.85)` round-trips to exactly `0.85` at `scale=1.0`. Where any residual 1-ULP confidence delta exists, it is absorbed by the byte→semantic flip (DD #3, the floor is semantic per DD #10) and cannot move a 2%-tolerance Acc1/Acc2 bucket. Non-`weightedVoting`/`default` policies resolve `metadataScale = 1.0` (reproduce `apply`); `.weightedVoting(w)`/`.default` use `w.fileMetadata`.

### Completion Notes List

**Implemented + verified the genuine KDD-A6 Stage 3 semantic flip (2026-05-30).** All 11 ACs satisfied; output-equivalence PROVEN at zero delta on both corpora.

- **Two-phase `select` (AC #1, DR-1):** `BPMSelectionPolicy.select(from:)` = Phase 1 (`merge`, verbatim, the 41 test sites still drive `merge` directly) + Phase 2a (pool-authoritative corroboration). The cross-signal ML fusion (Phase 2b) stays a post-ML-eval service step per DR-1 (ML eval reads the post-corroboration trace — it cannot fold into a pure value-type method without breaking the no-accuracy-change ordering). `UnifiedSignalPool` is authoritative + unconditional; empty pool → `nil` (DD #7 / FR-8, no precondition-crash).
- **Multiplicative corroboration scaled by `metadataScale` (AC #2, DD #2):** byte-verified — `scaledBoost == 1.25` and `scaledPenalty == 0.85` bit-pattern-identical at `scale=1.0`. So every non-`weightedVoting`/`default` policy (incl. the default `.dspOnly` path) byte-reproduces the pre-6.5b corroboration. `fileMetadata=0` → metadata inert; `=2.0` → stronger boost (0.6→0.9).
- **DR-2 (reuse-vs-reimplement):** preserved the corroboration arithmetic as the single core, threaded `metadataScale` (default 1.0); the standalone `apply` service invocation is removed (folded into `select`); the "pool votes" intent is honored at the participation layer (`.present` corroborated / `.demoted` intra-file-conflict, W51). Flagged for the Codex review.
- **KDD-A5 (AC #11, DD #14):** `.default` + `.weightedVoting` are LIVE — `combineEnsemble` weighted resolution (`effectiveVote = confidence × weights[source]`), `EnsembleWeightResolution` NaN-safe typed evidence (no `Hashable`, mirroring `EnsembleDecision`), `invokesMLInference` flipped true for both. The 6.5a `placeholderPoliciesAreOperationInert` test was replaced by `weightedPoliciesInvokeMLWhenActivated`. `Options.ensemblePolicy` default stays `.dspOnly` → default-path byte-identity intact.
- **Read-seam (AC #5, DD #5):** `SignalParticipation.score` accessor added; DSP `.present` carries the exact `Float` off the pool; `WeightedSignal.fileMetadataStage1TraceOnlyDefault` sentinel removed; existing `SignalPoolTests:256` reader stays green.
- **Atomic floor swap (AC #4, DD #3):** 4 `.stage1Floor/.stage2Floor` tagged tests + `StageFloorTags.swift` deleted; `MergeSemanticEqualityTests.swift` authored (the 14 behaviors through `select` + `apply`-oracle cross-check + 6-3-D2 + FR-6 + ML-up-weight + metadataScale fixtures); zero `.tags(.stage1Floor` grep in `Tests/`.
- **Verification:** `make test` 478/104 pass; **OA300 58/82·74/82** + **GiantSteps 537/661·546/661** at ZERO delta (the GiantSteps "matches pre-Story baseline EXACTLY" byte-identity tests pass); perf +1.2% (≤15%); 5-recipe trace audit zero; fmt/lint clean (1 known LUFS TODO baseline).

**Pending user action (operator-owned closeout per project-context.md):** `/bmad-code-review` (separate-LLM + Codex blind-hunter arm) → GPG-signed commit (1Password signer) → PR into `rterhaar/epic-6` → Copilot triage.

### File List

**Sources (modified):**
- `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift` — added `select(from:)` (Phase 1+2a) + `participationEntries` + `PoolSelection`
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `analyzeBPM` rewired to `select` + Phase 2b; `runPreCorroborationPipeline` builds the authoritative pool (no merge); `combineEnsemble` KDD-A5 weighted resolution + `weights` param + `weightResolutionTrace`; `resolveWeights`; `buildStage2SignalPool` removed; `PreCorroborationOutput` (drop `result`, pool non-optional)
- `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` — `apply` threaded `metadataScale`; `signalParticipationEntries` W51 `.demoted` + sentinel inlined
- `Sources/BoomBoomBoomKit/SignalPool/UnifiedSignalPool.swift` — flipped to authoritative data model
- `Sources/BoomBoomBoomKit/SignalPool/SignalParticipation.swift` — added `.score` accessor (DD #5b)
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift` — removed `fileMetadataStage1TraceOnlyDefault` (DD #5c)
- `Sources/BoomBoomBoomKit/SignalPool/AbstainReason.swift` — `mlEvalDeferred` (W48/6-3-D1) + `noCandidates` (6-3-D2) constants
- `Sources/BoomBoomBoomKit/EnsemblePolicy.swift` — `invokesMLInference` true for `.default`/`.weightedVoting` (KDD-A5)
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — `ensembleWeightResolution` field
- `Sources/BoomBoomBoomKit/OctaveEquivalencePolicy.swift` — `static let default`

**Sources (new):**
- `Sources/BoomBoomBoomKit/EnsembleWeightResolution.swift` — KDD-A5 typed evidence

**Tests (modified):**
- `Tests/BoomBoomBoomKitTests/MetadataCorroborationTests.swift` — deleted the 4 tagged floor tests
- `Tests/BoomBoomBoomKitTests/EnsemblePolicyTests.swift` — replaced inertness test with the KDD-A5 activation test
- `Tests/BoomBoomBoomKitTests/SignalPoolTests.swift` — doc-comment de-reference of the retired `.stage2Floor`

**Tests (new):**
- `Tests/BoomBoomBoomKitTests/MergeSemanticEqualityTests.swift` — the semantic-equality regression backbone

**Tests (deleted):**
- `Tests/BoomBoomBoomKitTests/StageFloorTags.swift`

**Docs:**
- `_bmad-output/project-context.md` — selection-boundary supersession (DD #8)

## Code Review (AI) — 2026-05-30 (4 layers: Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex blind-hunter)

**Outcome: Changes applied; 2 design deviations flagged for operator sign-off.** Codex's blind hunt surfaced the strongest finding — a compounding HIGH-severity defect the local layers also circled.

**PATCHED (7 fixes applied + 4 regression tests; corpus re-verified zero-delta after):**
- **F1 (HIGH, Codex+Edge) — unbounded `fileMetadata` weight → negative confidence.** `scaledPenalty` zero-crosses at `metadataScale ≈ 6.67` (`.weightedVoting(SignalWeights(fileMetadata: 7))`) → negative confidence, unclamped. FIX: floored `scaledPenalty` at `max(0, …)`. Byte-inert at scale 1.0.
- **F2 (HIGH, Codex) — large weight → `+inf` boosted candidate scores.** FIX: capped the boosted-score product at `Float.greatestFiniteMagnitude`.
- **F3 (HIGH, Codex+Edge+Blind) — `combineEnsemble` sanitized ML but not DSP confidence** → the poisoned value from F1/F2 could win the weighted vote. FIX: `dspVote` now `sanitizeEnsembleConfidence(dspWinner.confidence) × weights.dsp` (symmetric).
- **F4 (MEDIUM, Blind) — sweep-harness test misreported `source` for weighted policies** (read `ensembleDecision`, nil for them). FIX: also read `ensembleWeightResolution`.
- **F5 (LOW-MED, Edge) — `metadataScale==0` still applied the 0.95 clamp** on a corroborated >0.95 winner. FIX: `metadataScale != 0` guard → scale 0 truly inert (DD #2 literal).
- **F10 (LOW, Blind) — test `combineEnsemble` calls dropped `weights:`.** FIX: pass `resolveWeights(policy)`.
- **F11 (LOW, Edge) — disabled-policy service-level assertion dropped** with the tagged tests. FIX: re-added `disabledPolicyEmptyEvidenceService` (semantic, non-byte).
- New tests: `largeScalePenaltyFloored`, `hugeScaleScoresStayFinite`, `nonFiniteDSPConfidenceSanitized`, `disabledPolicyEmptyEvidenceService`. `make test` → **482/105 pass**; OA300 58/82·74/82 + GiantSteps 537/661·546/661 ZERO DELTA, perf +0.4%.

**DECISION NEEDED (operator sign-off — Acceptance Auditor; both auditor-assessed "sound conservative interpretations"):**
- **DR-1 (DD #1) — ML fusion (Phase 2b) stays a service step, not folded into `select`.** Forced by the ML-after-corroboration ordering (ML reads the post-corroboration trace; folding it into a pure value-type method would break the no-accuracy-change floor). Auditor verdict: sound, floor-protecting, not a scope escape.
- **DR-2 (DD #4) — `apply` arithmetic kept as the corroboration core (threaded `metadataScale`), not deleted/reimplemented as additive pool votes.** DD #2 (multiplicative-not-additive) partially vindicates this — a literal "additive votes" re-expression would contradict DD #2. The standalone service `apply` invocation IS removed (folded into `select`); the "pool votes" intent is honored at the participation layer (`.present`/`.demoted`). Auditor's residual concern: `apply` is now both production core AND its own oracle (the MergeSemanticEqualityTests cross-check can't diverge since it's the same code) — arguably a stronger de-risk than reimplement-and-compare, but it does not satisfy DD #3/#4's literal "delete apply / re-express as votes."

**DEFERRED (documented/reserved, pre-1.0):** `equivalence` param accepted-but-reserved (octave behavior still governed by `MetadataPolicy`); `EnsembleWeightResolution` lacks an `mlAbstained` field to distinguish "no ML" from "ML non-finite abstain" (forensic-fidelity LOW).

**DISMISSED:** `.demoted`-for-conflict trace change (intentional W51, working as designed); "AC #9 numbers self-reported" (independently re-verified zero-delta by the dev run).

## Change Log

| Date | Change |
|---|---|
| 2026-05-30 | Story 6.5b authored via `/bmad-create-story 6-5b` as the semantic Half B of the 6.5 split (post the validation→party-mode→Codex cascade). Captures the cascade's two ratified corrections: (1) TWO-PHASE `select` with a widened signature (the 3-arg form is non-implementable — drops strategy/candidateCount/votingPolicy/votingThreshold); (2) MULTIPLICATIVE corroboration scaled by `SignalWeights.fileMetadata` (NOT additive votes — the winner-promotion would not survive additive re-expression). Plus FR-6 as a real AC, the grep-based floor-retirement verification, W61 Optional, the `apply`-as-oracle de-risk, and the 14-behavior contract. `development_status[6-5b-…]` `backlog → ready-for-dev` (GATED on 6.5a landing — see prerequisite banner). Pending: 6.5a lands → re-validate line numbers → `/bmad-dev-story 6-5b`. |
| 2026-05-30 | **Re-validated via `/bmad-create-story 6-5b` against landed `4650bf0` (post-6.5a, PR #22).** Prerequisite CLEARED; `baseline_commit` `011f927 → 4650bf0`. Reconciled line drift (only `AudioAnalysisService.swift` moved: `merge` :825→:829, `buildStage2SignalPool` :875→:879, `"stage1-eval-deferred"` :931→:935; `analyzeBPM`/`apply`/`combineEnsemble` + all `SignalPool/` files + the 4 tagged floor tests :419/:461/:500/:531 + 14 behaviors verified STABLE). **Closed the KDD-A5 activation gap** (operator decision "6.5b owns it"): 6.5a shipped `.default`/`.weightedVoting` inert with docs deferring activation to 6.5b, and architecture.md:432/742 + epics.md:45 assign A5 to Story 6.5 — added DD #14 + AC #11 + Task 3b (activate `.weightedVoting`-weighted pool selection + `.default` balanced ensemble + `EnsembleWeightResolution` evidence; split the landed switch arm; `Options.ensemblePolicy` stays `.dspOnly`). Updated the KDD line (added A5), Previous Story Intelligence (5-case facade, `invokesMLInference` gate), References. Stays `ready-for-dev`. Pending: `/bmad-dev-story 6-5b`. |
| 2026-05-30 | **CODE-REVIEWED → `review → done`.** 4-layer `/bmad-code-review` (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex blind-hunter). Codex caught a compounding HIGH bug (unbounded `fileMetadata` weight → negative/`+inf` confidence poisoning the weighted vote via asymmetric DSP/ML sanitization); 7 fixes applied + 4 regression tests (`scaledPenalty` floored, boosted-score `+inf` cap, symmetric `dspVote` sanitization, `metadataScale==0` inert guard, sweep-harness `ensembleWeightResolution` read, test `weights:` args, disabled-policy service test). Re-verified after fixes: `make test` 482/105 pass, OA300 58/82·74/82 + GiantSteps 537/661·546/661 ZERO DELTA, perf +0.4%. Operator RATIFIED the two design deviations (DR-1 ML-fusion-stays-service-step, DR-2 reuse-the-arithmetic-core) as sound. See Code Review (AI) section. Pending: signed commit → PR into `rterhaar/epic-6` → Copilot triage. |
| 2026-05-30 | **IMPLEMENTED via `/bmad-dev-story 6-5b` → `ready-for-dev → review`.** The genuine KDD-A6 Stage 3 semantic flip: pool-authoritative two-phase `BPMSelectionPolicy.select(from:)` (Phase 1 `merge` verbatim + Phase 2a multiplicative corroboration scaled by `metadataScale = SignalWeights.fileMetadata`, byte-verified `1.25`/`0.85` at scale 1.0); `UnifiedSignalPool` flipped to an authoritative unconditional data model; KDD-A5 `.default`/`.weightedVoting` activated (weighted resolution + NaN-safe `EnsembleWeightResolution` + `invokesMLInference` flip); read-seam (`SignalParticipation.score`, sentinel removed); atomic floor swap (4 tagged tests + `StageFloorTags.swift` deleted, `MergeSemanticEqualityTests` authored with the 14 behaviors + `apply`-oracle cross-check); riders (W48/6-3-D1/6-3-D2/W51/W56); project-context.md selection-boundary supersession (DD #8). Two dev-discovered design resolutions documented for review: **DR-1** (DD #1 not implementable as one pure pass — ML eval is interleaved; ML fusion stays a post-eval service step) and **DR-2** (DD #4 reuse-the-arithmetic-as-core vs from-scratch reimplement — chose reuse + `metadataScale`, lower regression risk). **Verified: `make test` 478/104 pass; OA300 58/82·74/82 + GiantSteps 537/661·546/661 ZERO DELTA; perf +1.2% (≤15%); trace audit 5-recipe zero; fmt/lint clean.** Pending: operator `/bmad-code-review` (+ Codex blind-hunter) → signed commit → PR. |
