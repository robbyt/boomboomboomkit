---
baseline_commit: 8907fe1
---

# Story 6.4: KDD-A6 Stage 3 — atomic byte→semantic equality flip (the "6.4b" atomic flip)

Story ID: 6.4
Story Key: 6-4-kdd-a6-stage-3-atomic-byte-to-semantic-equality-flip
Epic: 6 — Unified-signal-pool ensemble (Tier-1 boundary collapse). The atomic flip the prep story 6.4a set up.
Status: ready-for-dev

**FRs covered:** FR-10, FR-11 ONLY. (Operator-signed reallocation 2026-05-29 — FR-1/FR-2/FR-6/FR-7 moved to Story 6.5; see DD #2/#11.)

> Baseline note: `baseline_commit: 8907fe1` is a late status-flip commit ("Story 6-1: flip status to done") layered ON TOP of 6.4a (`d739779`) + 6.3 (`a9acd4f`); the `WeightedSignal.score` carrier and the Stage-2 pool ARE present at this SHA despite the 6-1-flavored subject.

## Story

**As a** library maintainer,
**I want** the post-merge corroboration/ensemble path collapsed — `MetadataCorroborator.apply(to:input:)` and `EnsembleCombiner` removed, `apply`'s EXACT arithmetic relocated into the `SignalPool/`-housed corroborator namespace (still reading `merged.candidates` directly) — landing as one auditable, **provably zero-delta** commit with the single byte-equality floor test swapped to a semantic-equality assertion **in the same commit**,
**So that** the corroboration-boundary debt is retired with a clean bisect boundary, and Story 6.5's pool-authoritative selection lands against a runtime path whose refactor is already proven inert.

## Scope clarification (read first — reshaped by a 5-lens validation + 6-voice party-mode + Codex tie-break)

This is **6.4b**, the atomic flip 6.4a (`WeightedSignal.score: Float?`, PR #20 / `d739779`) set up. Two adversarial rounds (5-lens validation, then a 6-voice party-mode with a Codex tie-break, 2026-05-29) materially narrowed the scope. The honest, ratified deliverable:

**What this story delivers (ONE atomic commit, no intermediate red):**

1. **Remove `MetadataCorroborator.apply(to:input:)`** as a standalone post-merge function (NAMED AC #3 per 6.3 DD #1/R3). Relocate its **EXACT** arithmetic — boost ×1.25, skepticism ×0.85, 0.95 clamp, the 3-level winner re-selection tiebreak (boosted score → original score → lower index), all 5 branches, the `metadataEvidence` emission — into the `git-mv`'d `SignalPool/` corroborator namespace. **Byte-semantics preserved; a relocation + rename, NOT a new "pool-voting algorithm."** The relocated arithmetic **continues to read `merged.candidates` directly** (the `WeightedSignal.score` read-seam is deferred — DD #2).
2. **Remove `EnsembleCombiner`** (`AudioAnalysisService.swift:393`). It reads NO candidate score (only `dspWinner.confidence`/`.bpm`), so this is control-flow inlining orthogonal to any score read. To preserve its unit-level coverage, expose a private `@testable`-reachable ensemble-selection seam in the service (DD #4). Selection still runs AFTER `evaluateMLIfActive` against the live `MLEvaluation?`.
3. **`git mv Sources/BoomBoomBoomKit/MetadataCorroborator.swift → Sources/BoomBoomBoomKit/SignalPool/`** — clean rename, no concurrent content rewrite in the same staged hunk (so `git log --follow` resolves).
4. **Atomic test swap** — convert the SINGLE `bitEqual` block in `disabledPolicy` to exact semantic `==`; drop `.stage1Floor/.stage2Floor` tags from all 4 tagged tests; **delete the now-dead `StageFloorTags.swift`**; **migrate the 14 direct-`apply` unit funcs (16 call sites) + the 27 direct `EnsembleCombiner.combine` call sites across 3 suites** to the relocated/seam entry points — all in the same commit.

**DEFERRED to Story 6.5 (KDD-A1) — operator-signed-off 2026-05-29 (DD #2):** the `merge`-consumes-pool / `BPMSelectionPolicy.select(from: pool)` restructuring; making the pool unconditional/authoritative; the `WeightedSignal.score` **read-seam** (folded forward per the Codex tie-break — see below); the `SignalParticipation.score` accessor (no reader in 6.4b); the `CandidateMergeStrategy → BPMSelectionPolicy` rename; `SignalWeights`; FR-1/FR-2/FR-6/FR-7.

### Non-goals stated plainly (Winston)
After 6.4b the `UnifiedSignalPool` remains **trace-only, post-merge, and nil on the default path**; winner-selection is still `merge` + the relocated corroboration arithmetic reading `merged.candidates`; `merge`'s `[BPMResult]` signature is unchanged. **This story changes zero observable consumer behavior — its entire job is a provably-inert removal so 6.5's accuracy movement is unambiguously attributable to the new selection algorithm.** Pool-authority is 6.5.

> **Codex tie-break (read-seam):** Winston wanted the `WeightedSignal.score` read-seam kept in 6.4b as prep; John wanted it folded into 6.5. **Codex ruled FOLD-TO-6.5**: because the pool is nil on the default path, keeping the seam here creates a *split read path* (pool-read trace-on / `merged.candidates` trace-off) that muddies the zero-delta bisect boundary. So 6.4b touches no read path at all.

## Key Design Decisions

1. **DD #1 — factual-corrections supersession of the epic AC text** (genuine phantoms; verified against live source):

   | Epic/arch cites | Reality |
   |---|---|
   | delete `MergeByteEqualityTests.swift` | **PHANTOM** — never existed. Byte floor = 4 tests tagged `.stage1Floor,.stage2Floor` in `MetadataCorroborationTests.swift` (funcs `disabledPolicy`/`sameTempoBoostsConfidence`/`disabledPolicyOnTaggedFile`/`evidenceEmptyWhenDisabled`; `@Test` at L419/461/500/531, `.tags` at L421/463/502/533). **Only `disabledPolicy` (L441-446) contains `bitEqual` byte assertions — the other 3 are already semantic (`>=` / `.isEmpty`).** |
   | "flip from `[BPMResult.Candidate]` array" | **PHANTOM TYPE** — it's `[(bpm: Double, score: Float)]` (`BPMAnalyzer.swift:18`). |
   | "`merge` operates directly on the pool" / `EnsembleCombiner` is the score consumer | `EnsembleCombiner` reads **no** candidate score (only `dspWinner.confidence`/`.bpm`); the ONLY `result.candidates` score consumer is `apply` (`MetadataCorroborator.swift:99,174,177,208,209`). |
   | `swift test --filter-tag stage1Floor` | **NO SUCH FLAG** (`StageFloorTags.swift:18-24`). Verify via source grep `.tags(.stage1Floor` + name-regex. |
   | "merged to **develop**" | Integration branch is `rterhaar/epic-6`. |

2. **DD #2 — SCOPE DEFERRAL (operator-signed-off 2026-05-29; NOT a phantom correction like DD #1).** `merge` runs ACROSS windows at `AudioAnalysisService.swift:708`; the pool is built POST-merge at :724 (`buildStage2SignalPool:758`) and is `nil` on the default path (`enableTrace=false && mlTechnique=nil`). The architecture's literal "flip `merge`'s parameter type to `UnifiedSignalPool`" (architecture.md:341-343) + its `BPMSelectionPolicy.select(from: pool)` end-state (architecture.md:1199) is non-mechanical here and belongs to KDD-A1 / Story 6.5. **Per operator sign-off, the following all defer to 6.5:** the merge-flip, pool-authority, the `WeightedSignal.score` read-seam (Codex tie-break: a split read path would muddy the bisect boundary), the `SignalParticipation.score` accessor, and FR-1/FR-2/FR-6/FR-7 (reallocated in `epics.md`). 6.4b keeps `merge` frozen (`[BPMResult]`, 1 production call site, :708) and the relocated arithmetic reading `merged.candidates` — so 6.4b touches no read path and is maximally byte-inert.

3. **DD #3 — `apply` removal = exact-arithmetic relocation, not a pool-voting algorithm.** Relocate `apply` (`MetadataCorroborator.swift:62-322`) into the `SignalPool/` corroborator namespace, preserving bit-for-bit: boost ×1.25 (`MetadataPolicy.swift:157`), penalty ×0.85 (:159), 0.95 clamp (:158), the 3-level tiebreak (:201-216), the 5 branches, single-window-path corroboration (intensities 1-5; the Codex C1 reason it lives outside `merge`), and the `[MetadataBPMEvidence]` emission. Output flows through the **returned `BPMResult` + `metadataEvidence`** (the consumer surface), NOT the frozen `SignalParticipationTraceEntry`. The relocated arithmetic reads `merged.candidates` directly (no read-seam, DD #2). **Migrate the 14 direct-`apply` unit funcs / 16 call sites** (`MetadataCorroborationTests.swift:175,189,209,227,243,267,286,306,324,340,347,361,376,392,407 — one func calls twice`) in the same commit.

4. **DD #4 — `EnsembleCombiner` removal: 27 sites / 3 suites; retain coverage via a private testable seam.** Inline its `.dspOnly`/`.mlOnly`/`.highestConfidence` branches into the service. The migration surface is large and was undercounted in v2: **`EnsembleCombinerTests.swift` has 25 direct `combine` sites across 3 suites** (`EnsembleCombinerTests`, `EnsembleCombinerPolicyMatrixTests`, `EnsembleCombinerSanitizationTests`) + **`EnsemblePolicyTests.swift:360` AND `:415`** (v2 missed :415). Because "inline into `analyzeBPM`" leaves no call target, **expose a private `static func` ensemble-selection seam in the service that the migrated suites drive via `@testable import`** — preserving the 3×4 policy/outcome matrix + sentinel coverage rather than deleting it. **Preserve:** the `.dspOnly` byte-identity-under-non-nil-`mlTechnique` lock (`EnsemblePolicyTests.swift:78`); `.mlOnly`/`.highestConfidence` substitution run AFTER `evaluateMLIfActive` against the live `MLEvaluation?` (NOT the pool's `.abstained("stage1-eval-deferred")` entry); `clampBPM` 60-200; `sanitizeConfidence`; the `EnsembleDecision` population matrix.

5. **DD #5 — the byte→semantic swap touches exactly ONE byte test.** Convert `disabledPolicy`'s `bitEqual` block (`MetadataCorroborationTests.swift:441-446`) to **exact `==`** (NOT within-tolerance) on `bpm`/`confidence`/per-candidate `(bpm,score)` vs `runPreCorroborationPipeline(.disabled).result` — exact, to retain the confidence/score-drift detection byte-identity gave (the NaN/`-0.0` strictness `bitEqual` adds over `==` is provably unreachable on the disabled pass-through path — no NaN sentinels there). Drop `.stage1Floor/.stage2Floor` tags from all 4 tagged tests and **delete the now-dead `StageFloorTags.swift`** (Siri). New `MergeSemanticEqualityTests.swift` holds the 8-strategy equivalence (AC #2) — oracle = **golden expected `(bpm,confidence)` per strategy captured at Task 1.2 pre-flight on a clean `8907fe1` checkout BEFORE any edit, pasted literally** (you cannot compare against the `merge→apply→combine` chain — it's being deleted).

6. **DD #6 — `git mv MetadataCorroborator.swift → SignalPool/`** as a clean rename (no content rewrite in the same staged hunk, so `git log --follow` resolves reliably). `SignalPoolTests.swift:285` calls `signalParticipationEntries(for:weight:)` directly — it must still compile/pass after the move.

7. **DD #7 — KEEP-ATOMIC; the rationale is the ZERO-DELTA BISECT BOUNDARY, not "atomicity" (a commit property, preserved either way — John/Codex).** A provably-inert "the `apply`/`EnsembleCombiner` removal changed nothing" commit is exactly what lets 6.5's accuracy movement be attributed unambiguously to the new selection algorithm. Honest blast radius: 4 production edits + **14 `apply` unit-test funcs + 27 `EnsembleCombiner.combine` sites (3 suites)** migrated + 1 byte→`==` conversion + 4 tag drops + `StageFloorTags.swift` deletion + 2 fixtures + git mv. The atomic boundary is FORCED (can't leave tests asserting against a deleted `apply`/`combine`), so it's correct — but to keep a ~20-file commit reviewable, **Task 7 requires a diff-scope manifest** classifying every hunk as: (a) byte-inert relocation/rename, (b) test migration, (c) genuinely-new logic (the W51 demotion relocation, `BPMResult.with(trace:)`). Reviewer audits (c) closely.

8. **DD #8 — W51 conflict-demotion relocation is its own named AC + test (the one non-inert hunk).** (Reframed per Codex F2 / Winston.) `signalParticipationEntries` ignores `input.conflictDetected` (`MetadataCorroborator.swift:356`); the decision-phase `intra-file-conflict` demotion lives ONLY in `apply:104-128`. Removing `apply` deletes it. **Name the relocation target concretely:** the relocated corroborator static entry owns conflict-detection + the intra-file-conflict demotion, producing the same `(BPMResult, [MetadataBPMEvidence])` with the `intra-file-conflict` rejection reason; assert it on a constructed `MetadataCorroborationInput(conflictDetected: true)`. **Keep W51 OPEN** unless the demotion is concretely relocated + asserted — do not claim collapse.

9. **DD #9 — W52: a forwarding helper applied at ALL rebuild sites.** Add a value-type `BPMResult.with(trace:)` (+ `bpm:`/`confidence:` overrides for the ML-winner case) and route every field-enumerating rebuild through it (`AudioAnalysisService.swift:354-356`, :388-392, + the inlined ensemble branches). Closing W52 while leaving sibling rebuilds is a partial close.

10. **DD #10 — close 6-3-D1; dispose W48 + W61.** (a) **6-3-D1**: rename Stage-1 tokens neutral now the floor is retired — `"stage1-eval-deferred"` (`AudioAnalysisService.swift:814`) + the `fileMetadataStage1TraceOnlyDefault` *name* (keep the constant + its 6.5 `///` cross-ref). **W48: lift `"stage1-eval-deferred"` to a named constant in THIS commit** (the Stage-neutral rename alone does not close W48's public-trace-string concern). (b) **W61**: confirm the pool still always emits ≥1 `.dsp` + ≥1 `.ml` entry, or add `precondition(!entries.isEmpty)` (FR-8: empty pool → nil).

11. **DD #11 — FR reallocation (operator-signed) + floor reconciliation + 6.5 hand-off.** FRs reallocated in `epics.md` 2026-05-29: 6.4 = FR-10/FR-11; FR-1/FR-2/FR-6/FR-7 → 6.5. **AC #13 test-locks FR-7-non-delivery** (`metadataEvidence` byte-equal to the Task 1.2 baseline) so 6.4b can't be silently marked FR-7-complete. The deferred read-seam + `SignalParticipation.score` accessor + the conflict-demotion-as-`.demoted`-vote land in 6.5 with FR-7 — carried in the 6.5 hand-off note. **Floor doc drift (flag, do not fix here):** the CI gate is `OA300BenchmarkTests.swift:104/108` `acc1 ≥ 57` / `acc2 ≥ 73` and `GiantStepsBenchmarkTests.swift:82/86` `≥537/≥546`; the 58/74 figures are the current *measurement* (held at zero delta). `project-context.md:164` overstates the asserted OA300 floor (conflates 58/74 with 57/73) — surface to operator for a separate doc fix. Preserve the Story 6.5 weight two-site seam (`buildStage2SignalPool` local + `signalParticipationEntries(for:weight:)` arg) at their post-`git mv` locations; keep `SignalParticipationTraceEntry` shape frozen.

12. **DD #12 — concurrency-inert.** All touched types are `Sendable` value/caseless-enum namespaces; `analyzeBPM` is a `static` method on a stateless struct (no actor isolation, no async); benchmark fan-out gives each task its own pool value. No `@unchecked Sendable`, no annotation needed.

13. **DD #13 — scope ratified.** DD #14's strategic question ("is 6.4b well-formed?") was resolved by the party-mode panel (Winston/John keep-separate) + Codex tie-break (well-formed as-is) + operator sign-off 2026-05-29: keep 6.4b separate as the zero-delta corroboration-collapse checkpoint; defer pool-authority + read-seam to 6.5.

## Acceptance Criteria

1. **Atomic single commit.** ONE commit (verifiable in `git log -p`, no intermediate red) contains: `apply` removal + arithmetic relocation, `EnsembleCombiner` removal/inline + testable seam, `git mv → SignalPool/`, the `disabledPolicy` byte→exact-`==` conversion + 4 tag drops + `StageFloorTags.swift` deletion, the 14 `apply` + 27 `EnsembleCombiner` test-site migrations, the 2 new fixtures, and the W51 relocation. A **diff-scope manifest** (DD #7) accompanies the PR.

2. **8-strategy semantic equivalence (golden).** `MergeSemanticEqualityTests.swift` asserts, for each of the 8 `CandidateMergeStrategy.allCases` driven through `AudioAnalysisService`/`runPreCorroborationPipeline` on a ≥2-window fixture, winner BPM+confidence equals the Task 1.2 golden values; OA300 holds 58/82 + 74/82 and GiantSteps 537/661 + 546/661 (zero semantic delta).

3. **`apply(to:input:)` removed (named).** `apply` no longer exists; its exact arithmetic lives in the relocated `SignalPool/` namespace producing identical winner BPM+confidence; the `metadataEvidence` contract + integration tests pass; the 14 direct-`apply` unit funcs (16 sites) are migrated.

4. **`EnsembleCombiner` removed.** The type + call site (`:393`) are gone, branches inlined behind a private testable seam; the 27 `combine` sites across 3 suites + `EnsemblePolicyTests.swift:360/:415` are migrated (coverage retained); `EnsemblePolicyTests::dspOnlyDoesNotInvokeMLTechnique` stays green; `.mlOnly`/`.highestConfidence` run against the live `MLEvaluation?`; sentinels + `EnsembleDecision` matrix preserved.

5. **Accuracy floors.** OA300 `acc1 ≥ 57` AND `acc2 ≥ 73`; GiantSteps `acc1 ≥ 537` AND `acc2 ≥ 546`; current-measurement 58/74 + 537/546 held.

6. **Perf budget.** `make perf-benchmark`: OA300 wall-clock regression ≤ 15% vs the pre-Stage-3 baseline.

7. **Byte→semantic swap verified.** `disabledPolicy`'s `bitEqual` block → exact `==`; all 4 floor tags dropped; `StageFloorTags.swift` deleted; verification = `grep -rn '.tags(.stage1Floor' Tests/` → zero + the documented name-regex (NOT `--filter-tag`).

8. **`git mv` preserves history.** `git log --follow Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` shows pre-move history.

9. **W51 conflict-demotion relocated + asserted.** The intra-file-conflict demotion is relocated to the named corroborator entry and asserted on a constructed `conflictDetected: true` input; W51 closed (or explicitly kept-open with rationale + 6.5 hand-off).

10. **6-3-D2 fixtures.** A no-candidates unit fixture (constructed empty-`candidates` `BPMResult`, `enableTrace=true` → single `.dsp .abstained(.sourceSpecific("no-candidates"))`) and an all-tags-rejected metadata fixture (`.fileMetadata .absent`), both against `signalParticipationTrace`.

11. **Trace audit clean + FR-9.** 5-recipe `bpm-diagnostic-trace` audit zero pre+post; legacy `ensembleDecision` removal (FR-9) reflected without a banned dict shape.

12. **Stage-neutral rename (6-3-D1) + W48.** `"stage1-eval-deferred"` lifted to a named constant; the `fileMetadataStage1TraceOnlyDefault` *name* renamed Stage-neutral (constant + 6.5 `///` cross-ref preserved).

13. **FR-7-non-delivery test-locked.** A test asserts `metadataEvidence` is byte-equal to the Task 1.2 baseline (the corroboration arithmetic is RELOCATED, not converted to a peer voter); 6.4b's `FRs covered` = FR-10/FR-11 only.

## Tasks / Subtasks

- [ ] Task 1 — Pre-flight (AC: #2, #5, #11, #13) — BLOCKING golden capture
  - [ ] 1.1 `bpm-diagnostic-trace` 5-recipe audit before changes (expect zero).
  - [ ] 1.2 Green baseline on `8907fe1`; **capture golden per-strategy `(bpm,confidence)` for all 8 `CandidateMergeStrategy.allCases` (≥2-window fixture) + the disabled-policy pass-through `(bpm,confidence,per-candidate score)` + the `metadataEvidence` baseline** — paste literally into the new tests. Record `make benchmark`/`-giantsteps`/`perf-benchmark` numbers.
  - [ ] 1.3 Read every UPDATE file end-to-end (Dev Notes), incl. the 14 `apply` unit tests, the 3 `EnsembleCombiner` suites (27 sites), `EnsemblePolicyTests.swift:360/:415`, `SignalPoolTests.swift:285`.
- [ ] Task 2 — Remove `apply`, relocate arithmetic + W51 (AC: #1, #3, #9) [DD #3, #8]
  - [ ] 2.1 Relocate boost/penalty/clamp/tiebreak/5-branches/evidence into the `SignalPool/` namespace, reading `merged.candidates`; preserve byte-semantics + single-window path.
  - [ ] 2.2 Relocate conflict-detection + intra-file-conflict demotion (W51); delete `apply`.
  - [ ] 2.3 Migrate the 14 direct-`apply` unit funcs (16 sites).
- [ ] Task 3 — Remove `EnsembleCombiner` (AC: #4) [DD #4]
  - [ ] 3.1 Inline the 3 `EnsemblePolicy` branches behind a private `static` testable seam (selection post-`evaluateMLIfActive`); delete the type + call site :393.
  - [ ] 3.2 Migrate the 27 `combine` sites (3 suites) + `EnsemblePolicyTests.swift:360/:415`; verify `.dspOnly` lock + sentinels + `EnsembleDecision` matrix.
- [ ] Task 4 — `git mv` + rebuild + rename cleanup (AC: #8, #12) [DD #6, #9, #10]
  - [ ] 4.1 `git mv MetadataCorroborator.swift → SignalPool/` (clean rename); update stale type doc blocks + dead `///` cross-refs to removed types.
  - [ ] 4.2 Add `BPMResult.with(trace:)`; route ALL rebuild sites through it (W52).
  - [ ] 4.3 Lift `"stage1-eval-deferred"` to a named constant (W48) + Stage-neutral rename of `fileMetadataStage1TraceOnlyDefault` + W61 empty-pool check.
- [ ] Task 5 — Atomic test swap + fixtures (AC: #1, #7, #10, #13) [DD #5]
  - [ ] 5.1 Convert `disabledPolicy`'s `bitEqual` → exact `==`; drop tags from all 4; delete `StageFloorTags.swift`.
  - [ ] 5.2 Add `MergeSemanticEqualityTests.swift` (golden 8-strategy) + the 2 6-3-D2 fixtures + the FR-7-non-delivery `metadataEvidence` byte-equality test.
- [ ] Task 6 — Verification gauntlet (AC: #2, #5, #6, #7, #11)
  - [ ] 6.1 `make fmt && make lint` (canonical `LUFSAnalyzer.swift:94` TODO only).
  - [ ] 6.2 `make test` — **state the expected post-swap inventory** (removed/rewritten/added; NOT ~445); `make benchmark`/`-giantsteps` (floors); `make perf-benchmark` (≤15%).
  - [ ] 6.3 5-recipe audit post; `grep '.tags(.stage1Floor' Tests/` → zero; `git log --follow` history check.
- [ ] Task 7 — Reviewability gate (AC: #1) [DD #7]
  - [ ] 7.1 Produce the diff-scope manifest (inert-relocation / test-migration / new-logic).

## Dev Notes

### Files to read before editing (UPDATE — verified ground truth)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `analyzeBPM` (:321-412); trace gate (:331-333); `if let pool` (:350-359); `apply` call (:364); `EnsembleCombiner.combine` call (:393); `runPreCorroborationPipeline` (:629-729, `merge` :708, pool build :724); `buildStage2SignalPool` (:758-830; gate :763; `score:` write :784; no-candidates sentinel :797-799; ML entry :814; metadata entries :825-827).
- `Sources/BoomBoomBoomKit/MetadataCorroborator.swift` — `apply` (:62-322; reads `result.candidates` :99,174,177,208,209; boost :174-179; tiebreak :201-216; conflict :104-128); `signalParticipationEntries` (:340-387; ignores `conflictDetected`); stale type doc block (:36-61). `git mv` target.
- `Sources/BoomBoomBoomKit/EnsembleCombiner.swift` — `combine` (:88-176); reads only `dspWinner.confidence`/`.bpm`. Removal target.
- `Sources/BoomBoomBoomKit/CandidateMergeStrategy.swift:71-77` — frozen `merge` (READ-ONLY).
- `Sources/BoomBoomBoomKit/MetadataPolicy.swift:157-159` — 1.25 / 0.95 / 0.85.
- `Sources/BoomBoomBoomKit/SignalPool/{WeightedSignal.swift (score :24, fileMetadataStage1TraceOnlyDefault :41), SignalParticipation.swift (.confidence :15 — accessor deferred to 6.5), UnifiedSignalPool.swift (internal :14), SignalParticipationTraceEntry.swift (frozen)}`.
- Tests: `MetadataCorroborationTests.swift` (4 tagged tests funcs L419/461/500/531, only `disabledPolicy` byte :441-446; the 14 direct-`apply` unit funcs L165-414). `EnsembleCombinerTests.swift` (25 `combine` sites / 3 suites). `EnsemblePolicyTests.swift:78,360,415`. `SignalPoolTests.swift:102-103,285`. `StageFloorTags.swift` (delete). `OA300BenchmarkTests.swift:104,108`, `GiantStepsBenchmarkTests.swift:82,86`.

### Previous Story Intelligence (Story 6.4a, PR #20 / `d739779`)
1. `WeightedSignal.score: Float?` (`:24`) stays strictly-dead through 6.4b too (its reader — the read-seam — was folded to 6.5). The carrier remains the firewall against the lossy `Double→Float` reconstruction (6.3 DD #2) for when 6.5 reads it.
2. Byte-inert migrations held accuracy at zero delta across 6.1-6.4a; the pipeline is bit-deterministic (serial == parallel, 661 GiantSteps tracks). Any delta here = real regression — and the whole point of 6.4b is to prove there is none.
3. `make test` baseline 445/96 — the test migrations mean the post-swap count will NOT be ~445; state the explicit inventory.
4. Operator-owned closeout: `/bmad-code-review` on a different LLM (or Codex arm) + GPG-signed commit on the 1Password signer; own PR into `rterhaar/epic-6`. No concurrency surface (DD #12).

### Hand-off to Story 6.5 (carries the deferred work)
The `WeightedSignal.score` read-seam, the `SignalParticipation.score` accessor, the pool-authoritative `BPMSelectionPolicy.select(from: pool)`, making the pool unconditional, and re-expressing the relocated corroboration arithmetic as `.demoted`/`.present` pool votes (the genuine FR-7 delivery + the W51 demotion-as-vote) all land in 6.5 alongside the rename + `SignalWeights`. 6.4b leaves the relocated arithmetic reading `merged.candidates` so 6.5's read-flip is a localized change against a proven-inert baseline.

## References
- [Source: epics.md:500-534] — Story 6.4 epic ACs (FRs reallocated to 10/11 + 6.5 on 2026-05-29; literal text superseded by DD #1/#2).
- [Source: architecture.md:335-345, 997-1008, 1188-1202] — KDD-A6 staging, SignalPool/ layout, post-collapse flow (`select(from: pool)` is 6.5).
- [Source: 6-4a spec DD #8/#9; 6-3 spec DD #1/#2/#6/#7] — carrier hand-off; apply-removal-named-AC, coupled-changes warning, weight seam, git mv deferral.
- [Source: deferred-work.md] — 6-3-D1, 6-3-D2, W48, W51, W52, W61.

## Dev Agent Record

### Implementation Plan

### Debug Log

### Completion Notes

### File List

## Change Log

| Date | Change |
|---|---|
| 2026-05-29 | Story 6.4 (6.4b) created via `bmad-create-story` on a 5-agent parallel analysis workflow + factual-claims verification (v1). |
| 2026-05-29 | v1 → v2: 5-lens pre-party-mode validation (axiom:ask-routed skills + axiom-concurrency/testing + apple-docs MCP + Codex adversarial). Scope reframed: DD #2 (merge-flip + select(from:pool) deferred to 6.5), DD #3 (exact-arithmetic relocation), DD #4 (EnsembleCombiner reads no score), DD #5 (only 1 of 4 tagged tests is a byte test), DD #9 (W51 does NOT auto-collapse); the direct-`apply` + EnsembleCombiner test migrations surfaced; floor reconciliation (57/73 gate vs 58/74 measurement). |
| 2026-05-29 | v2 → v3: 6-voice party-mode (Winston/Amelia/Mary/John/Siri) + Codex external + tie-break. Codex tie-break FOLDED the `WeightedSignal.score` read-seam + `SignalParticipation.score` accessor to 6.5 (split-read-path would muddy the bisect boundary) — 6.4b now touches no read path. Amelia+Codex corrected the EnsembleCombiner migration count to **27 sites / 3 suites** (+ `EnsemblePolicyTests.swift:415`, missed in v2) → DD #4 retains coverage via a private testable seam. `apply` count corrected to 14 funcs / 16 sites. **Operator sign-off (2026-05-29):** ratified the scope deferral + reallocated FR-1/FR-2/FR-6/FR-7 from Story 6.4 to 6.5 in `epics.md`; 6.4 = FR-10/FR-11 only (DD #2/#11). DD #7 rationale reframed to the zero-delta bisect boundary (not "atomicity"); added the diff-scope manifest gate (Task 7), the W51 named AC #9, the FR-7-non-delivery test-lock (AC #13), `StageFloorTags.swift` deletion, W48 named-constant lift, exact-`==` (not tolerance) rationale, BLOCKING golden capture (Task 1.2). Status `ready-for-dev`. Pending: operator-owned `/bmad-code-review` (separate LLM) + GPG-signed commit on the 1Password signer → PR into `rterhaar/epic-6` → Copilot triage → dev-story. |
