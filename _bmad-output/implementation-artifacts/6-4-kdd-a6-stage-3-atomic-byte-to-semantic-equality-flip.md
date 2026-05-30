---
baseline_commit: 8907fe1
---

# Story 6.4: KDD-A6 Stage 3 (Part 1) — `EnsembleCombiner` removal + `MetadataCorroborator` relocation (byte-inert; the semantic flip consolidates into 6.5)

Story ID: 6.4
Story Key: 6-4-kdd-a6-stage-3-atomic-byte-to-semantic-equality-flip
Epic: 6 — Unified-signal-pool ensemble (Tier-1 boundary collapse). The byte-inert post-merge-boundary cleanup that 6.4a's carrier set up.
Status: done

**FRs covered:** FR-10, FR-11 ONLY. (Operator-signed reallocation 2026-05-29 — FR-1/FR-2/FR-6/FR-7 moved to Story 6.5; see DD #2/#11.)

> Baseline note: `baseline_commit: 8907fe1` is a late status-flip commit ("Story 6-1: flip status to done") layered ON TOP of 6.4a (`d739779`) + 6.3 (`a9acd4f`); the `WeightedSignal.score` carrier and the Stage-2 pool ARE present at this SHA. The spec commit `f794dc2` (this story's doc) added no Sources/Tests changes, so `8907fe1` is the correct code baseline for the implementation diff.

## Story

**As a** library maintainer,
**I want** the standalone `EnsembleCombiner` arbiter removed (its branches inlined into the service behind a testable seam) and `MetadataCorroborator.swift` relocated into `SignalPool/`, landing as one **provably byte-inert** commit under the still-green byte-equality floor,
**So that** the post-merge boundary is one stage simpler and the corroborator sits in its final home — teeing up Story 6.5's pool-authoritative selection (the genuine merge-flip + `apply`→pool-vote + byte→semantic swap) against a refactor already proven inert.

## Scope clarification (read first — narrowed by validation → party-mode → Codex tie-break → operator B-decision → Codex cross-check)

This story went through two adversarial rounds + an operator scope decision. The **final, ratified, coherent scope** of 6.4b is the byte-inert subset of KDD-A6 Stage 3. The genuine *semantic* Stage-3 flip consolidates into Story 6.5 (rationale below + DD #2).

**What this story delivers (ONE provably byte-inert commit):**

1. **Remove `EnsembleCombiner`** (`AudioAnalysisService.swift:393`, type at `EnsembleCombiner.swift:74`). Inline its three `EnsemblePolicy` branches into the service behind a **private `static` testable seam** (so the `EnsembleCombiner`/`EnsemblePolicy` unit suites migrate to it and keep coverage). It reads NO candidate score, so this is pure control-flow inlining. **Byte-identical on every path** (esp. the default/disabled path where `mlEvaluation == nil` → `combine` returns `dspWinner` unchanged).
2. **`git mv Sources/BoomBoomBoomKit/MetadataCorroborator.swift → Sources/BoomBoomBoomKit/SignalPool/`** — clean rename (no content rewrite in the same staged hunk, so `git log --follow` resolves). `apply(to:input:)` is **kept as-is** and marked in its doc comment as a **temporary legacy post-merge adapter retained until Story 6.5** (Codex cross-check condition).
3. **Cleanups:** `BPMResult.with(trace:)` forwarding helper applied at the (now-inlined) ensemble rebuild sites (W52); lift `"stage1-eval-deferred"` to a named constant (W48) + Stage-neutral rename of the `fileMetadataStage1TraceOnlyDefault` *name* (6-3-D1, keep constant + 6.5 cross-ref); confirm the pool always emits ≥1 `.dsp` + ≥1 `.ml` entry or add `precondition` (W61).
4. **6-3-D2 fixtures** — a no-candidates `.dsp .abstained(.sourceSpecific("no-candidates"))` fixture + an all-tags-rejected `.fileMetadata .absent` fixture (trace-on, against `signalParticipationTrace`).
5. **The byte-equality floor STAYS GREEN.** The 4 `@Tag(.stage1Floor, .stage2Floor)` tests in `MetadataCorroborationTests.swift` are UNCHANGED — they guard that the `EnsembleCombiner` inline + the `git mv` are byte-inert. `StageFloorTags.swift` is NOT deleted.

**DEFERRED to Story 6.5 (KDD-A1) — operator-signed-off 2026-05-29 + Codex-endorsed:** the `merge`-consumes-pool / `BPMSelectionPolicy.select(from: pool)` restructuring; making the pool authoritative; the **`apply(to:input:)` removal + its boost(×1.25)/penalty(×0.85)/winner-reselection → pool-vote re-expression** (the genuine FR-7); the **byte→semantic test swap + `MergeSemanticEqualityTests.swift`** (it pairs with the merge-flip per architecture.md:343's "same commit" rule — you do NOT retire byte-equality before the semantic change arrives); the `WeightedSignal.score` **read-seam**; the `SignalParticipation.score` accessor; the W51 conflict-demotion-as-vote; FR-1/FR-2/FR-6/FR-7.

> **Why the whole semantic flip moved to 6.5 (the B cascade):** the operator chose to defer the `apply` rename (option B) because, under the byte-preserve constraint, "remove apply" was only a no-op rename forcing a 14-test migration; `apply`'s real removal is its re-expression as a pool vote, which is 6.5. Once the merge-flip (already 6.5 per DD #2) AND `apply`-removal are both 6.5, the byte→semantic test swap MUST go with them (architecture.md:343 pairs the swap with the merge-flip in the same commit; retiring the byte floor earlier would open the exact red interval KDD-A6 forbids). So 6.4b is the byte-inert prep; 6.5 is the atomic semantic flip. Codex endorsed B + this consolidation (thread `019e7679...`).

## Key Design Decisions

1. **DD #1 — factual-corrections supersession of the epic AC text** (genuine phantoms; verified against live source):

   | Epic/arch cites | Reality |
   |---|---|
   | delete `MergeByteEqualityTests.swift` | **PHANTOM** — never existed. Byte floor = 4 tests tagged `.stage1Floor,.stage2Floor` in `MetadataCorroborationTests.swift` (funcs `disabledPolicy`/`sameTempoBoostsConfidence`/`disabledPolicyOnTaggedFile`/`evidenceEmptyWhenDisabled`; `@Test` at L419/461/500/531, `.tags` at L421/463/502/533). **Only `disabledPolicy` (L441-446) has `bitEqual` byte assertions.** This story does NOT touch these tests (they stay green). |
   | "flip from `[BPMResult.Candidate]` array" / "`merge` operates directly on the pool" | `merge(windowResults: [BPMResult], …)` (`CandidateMergeStrategy.swift:71-77`); `EnsembleCombiner` reads NO candidate score (only `dspWinner.confidence`/`.bpm`). The merge-flip + pool consumption are 6.5. |
   | "merged to **develop**" | Integration branch is `rterhaar/epic-6`. |

2. **DD #2 — the entire semantic Stage-3 flip is DEFERRED to Story 6.5 (operator-signed 2026-05-29; Codex-endorsed).** `merge` runs pre-pool, across windows (`AudioAnalysisService.swift:708`); the pool is built post-merge (`buildStage2SignalPool:758`) and is `nil` on the default path. The architecture's `merge`-consumes-pool / `select(from: pool)` end-state (architecture.md:341-343, 1199) is KDD-A1 / Story 6.5. **Deferred to 6.5:** the merge-flip, pool-authority, `apply` removal + its boost/penalty/reselection → pool-vote re-expression, the byte→semantic test swap + `MergeSemanticEqualityTests`, the `WeightedSignal.score` read-seam, the `SignalParticipation.score` accessor, W51, FR-1/2/6/7. 6.4b keeps `merge` and `apply` byte-unchanged; it touches no read path; it is maximally byte-inert.

3. **DD #3 — `apply(to:input:)` is RELOCATED, not removed (B + Codex cross-check).** `apply` (`MetadataCorroborator.swift:62-322`) moves with its file into `SignalPool/` via `git mv`, byte-unchanged in body, signature, name, and its 1 production call site (`AudioAnalysisService.swift:364`) + 14 unit-test call sites. Its doc comment is updated to mark it a **temporary legacy post-merge adapter retained until Story 6.5**, where it is replaced by the pool-vote re-expression. **6.4b does NOT satisfy the 6.3 DD #1 `apply`-removal obligation — it defers that named deletion to 6.5** (Codex: "deletion without semantic replacement is only churn"). This is the one operator-signed AC the story consciously defers; recorded in the Change Log.

4. **DD #4 — `EnsembleCombiner` removal is the genuine structural change.** Inline `combine`'s `.dspOnly`/`.mlOnly`/`.highestConfidence` branches + the `clampBPM`/`sanitizeConfidence`/`attaching`/`traceWith` helpers into a private `static func` seam in `AudioAnalysisService` (e.g. `combineEnsemble(dspWinner:mlEvaluation:policy:)`), delete `EnsembleCombiner.swift`, update the call site (:393). **Migrate the `EnsembleCombiner`/`EnsemblePolicy` unit suites to the seam via `@testable import`** — recount precisely at implementation time (Codex flagged ~34 `@Test` funcs across `EnsembleCombinerTests.swift` + `EnsemblePolicyTests.swift`; v2's "27 direct `combine` sites" was call-sites not funcs — reconcile both numbers in the Dev Agent Record). **Preserve byte-for-byte:** `.dspOnly` returns `dspWinner` (the `EnsemblePolicyTests::dspOnlyDoesNotInvokeMLTechnique` lock at `:78`); `mlEvaluation == nil` → `dspWinner` unchanged (the disabled/default byte-floor path); the two sentinels (`clampBPM` 60-200, `sanitizeConfidence` non-finite→0/clamp 0-1); the `EnsembleDecision` population matrix (decision != nil iff `evaluate` returned non-nil); ML runs AFTER corroboration. The `EnsembleCombiner` type doc's behavioral spec is the relocation contract.

5. **DD #5 — the byte-equality floor STAYS (no swap this story).** Because the merge-flip + `apply`-removal both defer to 6.5 (DD #2/#3), the `EnsembleCombiner` inline + `git mv` are byte-inert, so the 4 `.stage1Floor/.stage2Floor` tests in `MetadataCorroborationTests.swift` must PASS UNCHANGED (they are the regression backbone proving inertness — same role as 6.4a). The byte→semantic swap + `MergeSemanticEqualityTests.swift` land in 6.5 with the merge-flip (architecture.md:343 "same commit"). `StageFloorTags.swift` is NOT deleted. **Do not weaken `disabledPolicy`'s `bitEqual` to `==` this story.**

6. **DD #6 — `git mv MetadataCorroborator.swift → SignalPool/`** as a clean rename (no content rewrite in the same staged hunk → `git log --follow` resolves). `SignalPoolTests.swift:285` calls `signalParticipationEntries(for:weight:)` directly — it must still compile/pass after the move. SPM globs `Sources/BoomBoomBoomKit/**`, so no `Package.swift` edit.

7. **DD #7 — KEEP-ATOMIC; rationale = the zero-delta bisect boundary.** A provably-inert "removing `EnsembleCombiner` + relocating `MetadataCorroborator` changed nothing" commit lets Story 6.5's accuracy movement be attributed unambiguously to the new selection algorithm. Honest blast radius (now smaller than v3): 2 source removals/edits (`EnsembleCombiner` inline + `git mv`) + `BPMResult.with(trace:)` + W48/W61 + the `EnsembleCombiner`/`EnsemblePolicy` test migration to the seam + 2 fixtures. No `apply` test migration, no byte-test swap. **Task 7 still requires a diff-scope manifest** (inert-relocation / test-migration / new-logic) for reviewability.

8. **DD #8 — W51 defers to 6.5.** `apply` (with its intra-file-conflict demotion at `:104-128`) is byte-unchanged and travels with the `git mv`, so the W51 "demotion has no home" concern does NOT arise this story. W51's real resolution (conflict-demotion as a pool `.demoted` vote) lands in 6.5 with the `apply`→vote re-expression. Keep W51 OPEN; carry it in the 6.5 hand-off.

9. **DD #9 — W52: a forwarding helper at the inlined-ensemble rebuild sites.** Add a value-type `BPMResult.with(trace:)` (+ `bpm:`/`confidence:` overrides for the ML-winner case) and route the field-enumerating rebuilds in the inlined ensemble logic (formerly `EnsembleCombiner.swift:125-129/155-159/202-206`) + `AudioAnalysisService.swift:354-356/388-392` through it. Closes W52.

10. **DD #10 — close 6-3-D1; dispose W48 + W61.** (a) **6-3-D1**: rename `"stage1-eval-deferred"` (`AudioAnalysisService.swift:814`) to a named constant (also closing **W48**'s public-trace-string concern) + Stage-neutral rename of the `fileMetadataStage1TraceOnlyDefault` *name* (keep the constant + its 6.5 `///` cross-ref). (b) **W61**: confirm the pool always emits ≥1 `.dsp` + ≥1 `.ml` entry, or add `precondition(!entries.isEmpty)` (FR-8: empty pool → nil).

11. **DD #11 — FR reallocation (operator-signed) + floor reconciliation.** FRs reallocated in `epics.md` 2026-05-29: 6.4 = FR-10/FR-11; FR-1/FR-2/FR-6/FR-7 → 6.5. **Floor doc drift (flag, not fix):** the CI gate is `OA300BenchmarkTests.swift:104/108` `acc1 ≥ 57` / `acc2 ≥ 73` and `GiantStepsBenchmarkTests.swift:82/86` `≥537/≥546`; 58/74 is the current *measurement* (held at zero delta). `project-context.md:164` overstates the asserted OA300 floor — surface to operator separately. Preserve the Story 6.5 weight two-site seam (`buildStage2SignalPool` local + `signalParticipationEntries(for:weight:)` arg) at their post-`git mv` locations; keep `SignalParticipationTraceEntry` shape frozen.

12. **DD #12 — concurrency-inert.** All touched types are `Sendable` value/caseless-enum namespaces; `analyzeBPM` is a `static` method on a stateless struct; the inlined seam introduces no actor isolation/async. No annotation needed.

13. **DD #13 — scope ratified.** Keep 6.4b separate as the zero-delta byte-inert checkpoint (Winston/John panel + Codex tie-break + operator sign-off 2026-05-29); option B + Codex cross-check (thread `019e7679...`) consolidated the entire semantic Stage-3 flip into 6.5.

## Acceptance Criteria

1. **Atomic single byte-inert commit.** ONE commit (verifiable in `git log -p`, no intermediate red) contains: the `EnsembleCombiner` removal + inline-seam, the `EnsembleCombiner`/`EnsemblePolicy` test migration, the `git mv → SignalPool/` + `apply` legacy-adapter doc, and `BPMResult.with(trace:)` (W52). A **diff-scope manifest** (DD #7) accompanies it. _(6.4b review reconciliation 2026-05-30: the original "the W48/W61/6-3-D1 cleanups, and the 2 fixtures" clause is **superseded — those are DEFERRED to Story 6.5**. They were never owned by 6.4b in the authoritative `deferred-work.md`; only W52 lands here.)_

2. **Byte floor stays GREEN (regression backbone).** The 4 `@Tag(.stage1Floor, .stage2Floor)` tests in `MetadataCorroborationTests.swift` pass UNCHANGED — proving the `EnsembleCombiner` inline + `git mv` are byte-inert. `disabledPolicy`'s `bitEqual` assertions are not weakened.

3. **`apply(to:input:)` relocated, NOT removed.** `apply` is byte-unchanged (body/signature/name/call sites), now in `SignalPool/MetadataCorroborator.swift`, doc-marked a temporary legacy adapter retained until 6.5. The 6.3 DD #1 removal obligation is consciously deferred to 6.5 (Change Log records this).

4. **`EnsembleCombiner` removed.** The type + call site (`:393`) are gone; branches inlined behind a private testable seam; the `EnsembleCombiner`/`EnsemblePolicy` unit suites are migrated to the seam (coverage retained); `EnsemblePolicyTests::dspOnlyDoesNotInvokeMLTechnique` stays green; the two sentinels + `EnsembleDecision` matrix + ML-after-corroboration ordering preserved.

5. **Accuracy floors.** OA300 `acc1 ≥ 57` AND `acc2 ≥ 73`; GiantSteps `acc1 ≥ 537` AND `acc2 ≥ 546`; current-measurement 58/74 + 537/546 held (zero delta — byte-inert).

6. **Perf budget.** `make perf-benchmark`: OA300 wall-clock regression ≤ 15% vs the pre-Stage-3 baseline.

7. **`git mv` preserves history.** `git log --follow Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` shows pre-move history.

8. **W52 only — W48/W61/6-3-D1 DEFERRED to 6.5** _(6.4b review reconciliation 2026-05-30)_. `BPMResult.with(trace:)` routes all the inlined-ensemble + service rebuild sites (W52 — **delivered**). W48 (`"stage1-eval-deferred"` → named constant), 6-3-D1 (`fileMetadataStage1TraceOnlyDefault` Stage-neutral rename), and W61 (empty-pool `precondition`) are **deferred to Story 6.5** — the `deferred-work.md` re-open trigger for each resolves to 6.5 (W48→pool-population rewrite; 6-3-D1→byte→semantic swap; W61→new pool-construction sites), none of which land in the byte-inert 6.4b.

9. **6-3-D2 fixtures — DEFERRED to 6.5** _(6.4b review reconciliation 2026-05-30)_. Per `deferred-work.md`, the no-candidates `.dsp` sentinel lives behind the private `buildStage2SignalPool` (not test-reachable without the 6.5 pool work) and the two fixtures' natural home is 6.5's byte→semantic swap. Original requirement (now 6.5): a no-candidates unit fixture (empty-`candidates` `BPMResult`, `enableTrace=true` → single `.dsp .abstained(.sourceSpecific("no-candidates"))`) and an all-tags-rejected metadata fixture (`.fileMetadata .absent`), both against `signalParticipationTrace`.

10. **Trace audit clean.** 5-recipe `bpm-diagnostic-trace` audit zero pre+post (no new trace field this story; W48 named-constant lift must not introduce a banned shape).

## Tasks / Subtasks

- [x] Task 1 — Pre-flight (AC: #2, #5, #10)
  - [x] 1.1 `bpm-diagnostic-trace` audit before changes — zero banned-shape matches (no new trace field this story).
  - [x] 1.2 Green baseline on `8907fe1`: `make build` clean (0.58s), `make test` 445/96. Corpus baselines recorded (OA300 58/74, GiantSteps 537/546, perf mean 0.211s @ `2ba3cc3`).
  - [x] 1.3 Read UPDATE files end-to-end. EnsembleCombiner test surface recounted: 25 `@Test` / 25 `combine` sites in `EnsembleCombinerTests.swift` (3 suites) + 2 sites in `EnsemblePolicyTests.swift` (:360, :415).
- [x] Task 2 — Remove `EnsembleCombiner`, inline behind a testable seam (AC: #1, #4) [DD #4, #9]
  - [x] 2.1 Added `internal static func combineEnsemble(dspWinner:mlEvaluation:policy:)` + private `clampEnsembleBPM`/`sanitizeEnsembleConfidence`/`ensembleTrace` helpers to `AudioAnalysisService`, byte-identical to `EnsembleCombiner.combine`; routed the trace-only + ML-winner rebuilds through `BPMResult.with(...)` (W52). (Seam is `internal`, not `private` — `@testable` reach requires `internal`.)
  - [x] 2.2 Updated the call site (:393 → `Self.combineEnsemble`); `git rm` `EnsembleCombiner.swift`.
  - [x] 2.3 Migrated all 27 `combine` sites (`EnsembleCombinerTests` ×25 + `EnsemblePolicyTests` ×2) to the seam; `.dspOnly` lock + sentinels + `EnsembleDecision` matrix all green (445/96).
- [x] Task 3 — `git mv` + legacy-adapter doc + doc-refs (AC: #3, #7) [DD #3, #6]
  - [x] 3.1 `git mv MetadataCorroborator.swift → SignalPool/` (clean rename, git shows `R`); legacy-adapter `- Important:` doc note added on `apply`; 10 stale `EnsembleCombiner` `///` cross-refs across 5 files repointed to the seam / reworded.
  - [x] 3.2 `BPMResult.with(...)` forwarding helper added + applied at all rebuild sites (W52).
- [x] Task 4 — Verification gauntlet (AC: #2, #5, #6, #10)
  - [x] 4.1 `make fmt` clean; `make lint` 1 violation / 0 serious (canonical `LUFSAnalyzer.swift:94`).
  - [x] 4.2 `make test` 445/96 (net 0 — call-site migration only); 4 `.stage1Floor/.stage2Floor` byte-floor tests GREEN. OA300 58/82 + 74/82; GiantSteps 537/661 + 546/661 (zero delta, floors ≥57/≥73 + ≥537/≥546 held). `make perf-benchmark` mean 0.175s vs 0.211s = −16.7% (well within ≤15% regression budget).
  - [x] 4.3 Post-change trace audit zero new banned shapes; `git mv` recorded as rename (AC #7 `--follow` resolves post-commit).
- [x] Task 5 — Reviewability gate (AC: #1) [DD #7]
  - [x] 5.1 Diff-scope manifest in Completion Notes.

### Deferred to Story 6.5 (the consolidated semantic Stage-3 flip)
The following v4 items were deferred during implementation because each is coupled to the byte→semantic swap / pool-authority work whose home is 6.5 (surfaced to the operator):
- **6-3-D1 (Stage-neutral token rename) + W48 (magic-string→named-constant lift):** 6-3-D1's own re-open trigger is "the byte→semantic swap un-pins the verbatim-preservation constraint" — that swap is 6.5; renaming `"stage1-eval-deferred"` while the byte floor is still green is coupled to it.
- **W61 (empty-pool invariant):** its trigger is "a refactor that creates new pool construction sites" — 6.4b touches no pool construction; 6.5 does.
- **6-3-D2 fixtures:** the no-candidates `.dsp` sentinel lives behind the `private buildStage2SignalPool` (not test-reachable without the 6.5 pool work); its natural home is 6.5's `MergeSemanticEqualityTests`.

## Dev Notes

### Files to read before editing (UPDATE — verified ground truth)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `analyzeBPM` (:321-412): `apply` call (:364), `EnsembleCombiner.combine` call (:393), the rebuild sites (:354-356, :388-392); `buildStage2SignalPool` (:758-830; ML entry / `"stage1-eval-deferred"` at :814; W61 pool construction).
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — `combine` (:88-176) + helpers; the type doc is the byte-exact relocation contract. Removal target.
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — `apply` (:62-322, KEPT byte-unchanged, doc-marked legacy); `signalParticipationEntries` (:340-387). `git mv` target.
- `Sources/BoomBoomBoomKit/SignalPool/WeightedSignal.swift` (`fileMetadataStage1TraceOnlyDefault` :41 — rename name only, keep constant + 6.5 `///`).
- Tests: `EnsembleCombinerTests.swift` (~25 `@Test`), `EnsemblePolicyTests.swift` (`:78` dspOnly lock; ~9 `@Test`) — migrate to the seam. `MetadataCorroborationTests.swift` (4 byte-floor tests L419/461/500/531 — UNCHANGED, must stay green). `SignalPoolTests.swift:285` (signalParticipationEntries caller). `OA300BenchmarkTests.swift:104,108`, `GiantStepsBenchmarkTests.swift:82,86`.

### Previous Story Intelligence (Story 6.4a, PR #20 / `d739779`)
1. `WeightedSignal.score: Float?` stays strictly-dead through 6.4b (its reader is 6.5). Carrier intact.
2. Byte-inert migrations held accuracy at zero delta across 6.1-6.4a; pipeline is bit-deterministic. Any delta here = real regression — the whole point of 6.4b is proving the `EnsembleCombiner` removal + relocation introduce none, under the green byte floor (the 6.4a pattern).
3. `make test` baseline 445/96; the `EnsembleCombiner` test migration re-points call sites (count net ~0 if migrated, fewer if any redundant suite is dropped) + 2 fixtures. State the exact inventory in Completion Notes.
4. Operator-owned closeout: `/bmad-code-review` on a different LLM (or Codex arm) + GPG-signed commit on the 1Password signer; own PR into `rterhaar/epic-6`. No concurrency surface (DD #12).

### Hand-off to Story 6.5 (the consolidated semantic Stage-3 flip)
6.5 owns: the `merge`-consumes-pool / `BPMSelectionPolicy.select(from: pool)` restructuring + rename + `SignalWeights`; the `apply(to:input:)` removal + boost/penalty/winner-reselection → `.present`/`.demoted` pool-vote re-expression (FR-7, with W51's conflict-demotion-as-`.demoted`); the **byte→semantic test swap + `MergeSemanticEqualityTests.swift`** (paired with the merge-flip, same commit); the `WeightedSignal.score` read-seam + the `SignalParticipation.score` accessor; FR-1/2/6/7. 6.4b leaves `merge`/`apply` byte-unchanged so 6.5's changes land against a proven-inert baseline.

## References
- [Source: epics.md:500-534] — Story 6.4 epic ACs (FRs reallocated to 10/11 + 6.5 on 2026-05-29; literal text superseded by DD #1/#2).
- [Source: architecture.md:335-345, 997-1008, 1188-1202] — KDD-A6 staging (Stage 3 swap pairs with the merge-flip), SignalPool/ layout, post-collapse flow (`select(from: pool)` is 6.5).
- [Source: 6-4a spec DD #8/#9; 6-3 spec DD #1/#2/#6/#7] — carrier hand-off; apply-removal obligation (deferred here to 6.5 per DD #3), git mv deferral.
- [Source: deferred-work.md] — 6-3-D1, 6-3-D2, W48, W51 (→6.5), W52, W61.

## Dev Agent Record

### Agent Model Used
claude-opus-4-8 (1M)

### Implementation Plan
Single execution, spec-task order. Pre-flight (green baseline + read all UPDATE files) → inline `EnsembleCombiner.combine` into `AudioAnalysisService.combineEnsemble` byte-identical + `BPMResult.with(...)` forwarding helper (W52) → delete `EnsembleCombiner.swift` + migrate 27 `combine` test sites → `git mv MetadataCorroborator.swift → SignalPool/` + legacy-adapter doc + doc-ref repointing → verification gauntlet. Deferred the 4 cleanup items (6-3-D1/W48/W61/6-3-D2) to 6.5 on the coupling rationale above (operator-surfaced).

### Debug Log
- After `git mv`, SourceKit emitted 10 stale "Cannot find 'MetadataCorroborator' in scope" diagnostics — confirmed STALE background-index artifacts (same as 6.4a): authoritative `swift build` (1.28s) + `swift test` (445/96) both compile/pass against the rebuilt module.
- Perf came in −16.7% vs the `2ba3cc3` baseline (0.211s → 0.175s) — timing noise on a byte-inert change, not a real speedup; comfortably inside the ≤15% regression budget.
- Seam access: spec said "private testable seam" — corrected to `internal` (`@testable import` reaches `internal`, not `private`). The sanitization helpers stay `private`.

### Completion Notes
**Deliverable (byte-inert):** removed the standalone `EnsembleCombiner` type — its `combine` + sanitization/attach logic inlined verbatim into `AudioAnalysisService.combineEnsemble(dspWinner:mlEvaluation:policy:)` (testable seam) — and `git mv`'d `MetadataCorroborator.swift` into `SignalPool/` (`apply` byte-unchanged, doc-marked a temporary legacy adapter retained until 6.5). Added the `BPMResult.with(...)` value-type forwarding helper (W52) and routed every post-merge rebuild site through it. `merge` + `apply` byte-unchanged.

**Verification (all green):**
- `make build` clean; `make test` 445/96 (net 0 — the 27 `combine` test sites migrated to the seam, no count change).
- 4 `@Tag(.stage1Floor,.stage2Floor)` byte-floor tests GREEN (the inertness oracle).
- OA300 default (intensity 7): **Acc1 58/82, Acc2 74/82** — zero delta (floors ≥57/≥73 held).
- GiantSteps default: **Acc1 537/661, Acc2 546/661** — zero delta (floors ≥537/≥546 held); windowVoting + durationHint "matches baseline EXACTLY" guards green.
- `make perf-benchmark`: mean 0.175s (−16.7% vs `2ba3cc3`), accuracy snapshot 58/74 + 537/546.
- `make fmt` clean; `make lint` 1 violation / 0 serious (canonical `LUFSAnalyzer.swift:94`).
- Trace audit: no new banned shapes (no new trace field this story).

**Diff-scope manifest (DD #7 / AC #1):**
- *byte-inert relocation/inline:* `AudioAnalysisService.swift` (combineEnsemble seam + 2 rebuilds via `with` + `BPMResult.with` extension), `EnsembleCombiner.swift` (deleted), `MetadataCorroborator.swift → SignalPool/` (git mv).
- *doc-only:* 10 `EnsembleCombiner` `///` cross-refs repointed (`EnsemblePolicy`, `EnsembleDecision`, `BPMDiagnosticTrace`, `MLTechnique`, `AudioAnalysisService`) + the `apply` legacy-adapter note.
- *test migration:* `EnsembleCombinerTests.swift` (25 sites), `EnsemblePolicyTests.swift` (2 sites) → `AudioAnalysisService.combineEnsemble`.
- *genuinely-new logic:* none (the `with(...)` helper is a pure forwarding wrapper; all behavior byte-identical).

**Deferred to 6.5:** 6-3-D1, W48, W61, 6-3-D2 (rationale in the Deferred subsection above) — plus the already-deferred merge-flip, apply→vote, byte→semantic swap, read-seam, `SignalParticipation.score` accessor, W51.

**Pending operator action:** `/bmad-code-review` on a different LLM (or Codex arm), then GPG-signed commit on the 1Password signer (suggested: `Story 6-4: KDD-A6 Stage 3 (Part 1) — remove EnsembleCombiner; relocate MetadataCorroborator to SignalPool/`), then PR `rterhaar/6-4b` into `rterhaar/epic-6` → Copilot triage. AC #7 `git log --follow` resolves once committed.

### File List
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — modified (inlined `combineEnsemble` seam + helpers; call-site :393; 2 rebuilds via `with`; `BPMResult.with(...)` extension; 2 doc-refs).
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — DELETED.
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` → `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` — `git mv` (rename) + legacy-adapter doc note on `apply`.
- `Sources/BoomBoomBoomKit/EnsemblePolicy.swift` — modified (3 doc-refs).
- `Sources/BoomBoomBoomKit/EnsembleDecision.swift` — modified (2 doc-refs).
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — modified (1 doc-ref).
- `Sources/BoomBoomBoomKit/MLTechnique.swift` — modified (2 doc-refs).
- `Tests/BoomBoomBoomKitTests/EnsembleCombinerTests.swift` — modified (25 `combine` sites → seam).
- `Tests/BoomBoomBoomKitTests/EnsemblePolicyTests.swift` — modified (2 `combine` sites → seam).
- `_bmad-output/implementation-artifacts/6-4-...md` — this story file.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — status tracking.
- `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260530T022648Z--f794dc2--c66ded8c.json` — perf-benchmark run record.

**Review-pass additions (2026-05-30 `/bmad-code-review`):**
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — patch C: ported DD#6 tag-bias caveat into the `combineEnsemble` doc-comment (`///` only, byte-inert).
- `Tests/BoomBoomBoomKitTests/EnsembleCombinerTests.swift` — patch E: `candidates` bit-pattern `#expect` added to `mlOnly_mlAgreesHighConf` (assertion within an existing test; 445/96 count unchanged).
- `Tests/BoomBoomBoomKitBenchmarkTests/MLPolicySweepTests.swift` — patch D: stale `EnsembleCombiner` comment references reworded (NEW to the changeset).
- `Tests/BoomBoomBoomKitTests/EnsemblePolicyTests.swift` — patch D: stale `EnsembleCombiner` doc-comment reworded.
- `_bmad-output/implementation-artifacts/deferred-work.md` — logged 6-4b-D1 + re-pointed 6-3-D1/6-3-D2 triggers to 6.5.
- `_bmad-output/planning-artifacts/epics.md` — Story 6.4 `Then` clause reconciled to the byte-inert scope.

## Change Log

| Date | Change |
|---|---|
| 2026-05-29 | Story 6.4 (6.4b) created via `bmad-create-story` on a 5-agent parallel analysis workflow (v1) → 5-lens validation (v2) → 6-voice party-mode + Codex tie-break (v3). |
| 2026-05-29 | v3 → v4 (correct-course, operator-authorized): at dev-start, reading the code showed AC #3 "remove `apply`" reduces to a no-op rename under the byte-preserve constraint (its real removal is the pool-vote re-expression = 6.5). Operator chose option B (defer the `apply` rename to 6.5); **Codex cross-check endorsed B** (thread `019e7679...`) with two conditions, applied: (i) the spec states 6.4b does NOT satisfy the 6.3 DD #1 `apply`-removal obligation — deferred to 6.5; (ii) `apply` is doc-marked a temporary legacy adapter. **Forced cascade:** since the merge-flip (DD #2) AND `apply`-removal both defer to 6.5, the byte→semantic test swap defers with them (architecture.md:343 pairs the swap with the merge-flip — retiring the byte floor earlier opens the red interval KDD-A6 forbids). 6.4b is therefore re-scoped to the **byte-inert subset**: `EnsembleCombiner` removal (inline behind a testable seam) + `MetadataCorroborator` `git mv` into `SignalPool/` + W48/W52/W61 + 6-3-D2 fixtures, with the byte floor STAYING GREEN. The full semantic Stage-3 flip (merge-flip + apply→vote + byte→semantic swap + read-seam + accessor + W51) consolidates into Story 6.5. Status `ready-for-dev → in-progress`. |
| 2026-05-29 | Dev-story implementation (`/bmad-dev-story`, single execution, no HALT). Removed `EnsembleCombiner` (inlined `combine` → `AudioAnalysisService.combineEnsemble` testable seam, byte-identical; deleted the file; migrated 27 `combine` test sites). `git mv MetadataCorroborator.swift → SignalPool/` (rename) + `apply` doc-marked temporary legacy adapter. Added `BPMResult.with(...)` forwarding helper (W52) at all rebuild sites. Repointed 10 stale `EnsembleCombiner` doc cross-refs across 5 files. `make test` 445/96 (net 0); 4 byte-floor tests GREEN; OA300 58/82+74/82 and GiantSteps 537/661+546/661 zero delta; perf −16.7% (≤15% budget); fmt clean, lint 1/0 (canonical LUFSAnalyzer:94); trace audit no new banned shapes. **Deferred to 6.5 (coupling rationale): 6-3-D1, W48, W61, 6-3-D2.** Status `in-progress → review`. Pending: operator `/bmad-code-review` (separate LLM) + GPG-signed commit on the 1Password signer → PR into `rterhaar/epic-6`. |
| 2026-05-30 | `/bmad-code-review` five-layer pass (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex-backed Blind Hunter + dedicated byte-inertness verifier). Byte-inertness UNANIMOUS PASS, independently re-verified (clean build + 33/33 migrated tests; byte-floor tests untouched-green). One decision (spec ACs over-claimed scope vs the authoritative `deferred-work.md`) RESOLVED by operator: reconciled ACs #1/#8/#9 + the epics.md `Then` clause to the delivered byte-inert scope, re-pointed 6-3-D1/6-3-D2 ledger triggers to 6.5 — no `Sources/` change. 3 patch findings + 1 defer logged in Review Findings below. |

## Review Findings

`/bmad-code-review` five-layer pass (Blind Hunter + Edge Case Hunter + Acceptance Auditor + Codex-backed Blind Hunter + dedicated byte-inertness verifier) over the staged 6.4b source/test diff against baseline `8907fe1` (2026-05-29).

**Byte-inertness: UNANIMOUS PASS, independently re-verified.** All five layers concur the change is behavior-preserving. The verifier reproduced a clean build + 33/33 migrated tests and closed Codex's only (procedural) caveat with direct evidence: `combineEnsemble` reproduces the deleted `EnsembleCombiner.combine` statement-for-statement on every branch (clamp `60...200`, two independent NaN/Inf sentinels, clamp/sanitize ordering, `EnsembleDecision` population matrix, DSP-wins-ties); `BPMResult.with(...)` forwards all four `BPMResult` fields (the old `attaching()` and explicit rebuilds map onto it exactly); `apply`'s body is byte-unchanged (rename 96%, +9 doc-only / −0); the 4 `.stage1Floor/.stage2Floor` byte-floor tests + `StageFloorTags.swift` are untouched. ~13 byte-inert confirmation findings + 4 non-actionable nits (latent `with` optional-nil footgun, `ensembleTrace` nil-base no-op, DD#6 wording tension, Codex elided-hunks caveat) dismissed.

### Decision needed

- [x] [Review][Decision] _(RESOLVED 2026-05-30 — operator chose "reconcile text now": ACs #1/#8/#9 annotated DEFERRED-to-6.5, epics.md `Then` clause aligned to byte-inert scope, `deferred-work.md` 6-3-D1/6-3-D2 re-open triggers re-pointed to 6.5. No `Sources/` change.)_ **Spec ACs over-claim scope vs the authoritative `deferred-work.md` + delivered code.** ACs #1/#8(partial)/#9 + all Tasks marked `[x]` + epics.md `Then` clause ("`merge` operates directly on the pool") enumerate W48 / W61 / 6-3-D1 / 6-3-D2 / pool-authority as 6.4b deliverables, but the byte-inert delivery (correctly) ships none of them and `deferred-work.md` already scopes each to a trigger that resolves to 6.5 (W48→"pool-population rewrite"; W61→"new construction sites"; 6-3-D1/6-3-D2→"byte→semantic swap", which the B-cascade moved to 6.5). W52 IS done and IS ledger-consistent. Per the project rule "deferred-work.md is the authoritative SoT, NOT story-file checkboxes", the **code is correct and the deferrals are ledger-consistent** — only the spec text drifted. Reconcile before sign-off (see review summary for options).

### Patch

- [x] [Review][Patch] _(APPLIED 2026-05-30)_ Port the DD#6 tag-bias caveat (under `.highestConfidence`, `dspWinner.confidence` may have been metadata-boosted to the 0.95 ceiling, biasing ties toward DSP) — present in the deleted `EnsembleCombiner` type doc, dropped from the inlined seam doc-comment [Sources/BoomBoomBoomKit/AudioAnalysisService.swift `combineEnsemble` doc-comment]
- [x] [Review][Patch] _(APPLIED 2026-05-30)_ Add a `candidates` bit-pattern `#expect` to the ML-win test `mlOnly_mlAgreesHighConf` so candidate-forwarding through `.with` is test-locked [Tests/BoomBoomBoomKitTests/EnsembleCombinerTests.swift:170-191]
- [x] [Review][Patch] _(APPLIED 2026-05-30)_ Clean stale `EnsembleCombiner` references in untouched test comments [Tests/BoomBoomBoomKitBenchmarkTests/MLPolicySweepTests.swift:346,375; Tests/BoomBoomBoomKitTests/EnsemblePolicyTests.swift:402]

### Deferred

- [x] [Review][Defer] `project-context.md:164` OA300 floor (≥58/74) overstates the asserted CI gate (≥57/73 at `OA300BenchmarkTests.swift:104/108`) [_bmad-output/project-context.md:164] — deferred, pre-existing (DD#11 explicitly "flag, not fix"; not introduced by this diff; live numbers exceed both the real and the overstated floor).
