# Story 2.2: Dual Tolerance Accuracy Reporting

Status: done

## Story

As a library author,
I want accuracy reported at both 2% (library standard) and 4% (MIREX-compatible) tolerance across all benchmark suites,
so that I can compare results with published MIR literature, track precision at both thresholds, and unify the Acc2 octave/triplet definition across OA300, GiantSteps, and DAWOracle.

## Acceptance Criteria

1. **Given** `OA300BenchmarkTests`,
   **When** built and run,
   **Then** two new test methods exist:
   - `benchmarkAcc1Strict()` — reports Acc1/Acc2 at 2% tolerance
   - `benchmarkAcc1MIREX()` — reports Acc1/Acc2 at 4% tolerance

   **And** each method is individually filterable via `swift test --filter OA300BenchmarkTests/benchmarkAcc1Strict` and `swift test --filter OA300BenchmarkTests/benchmarkAcc1MIREX`.
   **And** within each method, `analyzeBPM` is called exactly once per track (one call site in the aggregation loop), with both Acc1 and Acc2 computed from that single `BPMResult`. No per-metric re-analysis, no cross-method caching.

2. **Given** `GiantStepsBenchmarkTests`,
   **When** built and run,
   **Then** two new test methods exist with the same names and tolerance values (`benchmarkAcc1Strict` 2%, `benchmarkAcc1MIREX` 4%) following the same one-analysis-per-track pattern.
   **And** dual-tempo Acc1 matching from Story 2-1 is preserved (a track is correct if detected matches `bpm` OR `tempo2` within the active tolerance).

3. **Given** the local `isAcc1Match` helper in each benchmark file,
   **When** updated,
   **Then** it accepts a `tolerance: Double` parameter (no default) so callers must pass `0.02` or `0.04` explicitly. No hard-coded `0.02` literal remains in match logic outside the test method that selects the threshold.

4. **Given** the local `isAcc2Match` helpers in `OA300BenchmarkTests.swift` and `DAWOracleBenchmarkTests.swift`,
   **When** updated for MIREX compliance,
   **Then** they check factors `{1, 2, 1/2, 3, 1/3}` (add `isAcc1Match(detected * 3, expected, tolerance:)` and `isAcc1Match(detected / 3, expected, tolerance:)`), matching the GiantSteps version landed in Story 2-1.
   **And** they accept the same `tolerance: Double` parameter and forward it to `isAcc1Match`.
   **And** GiantSteps `isAcc2Match` is unchanged in factor set (already MIREX-compliant from Story 2-1) and only gains the `tolerance` parameter.

5. **Given** the existing `benchmarkDefaultIntensity()`, `benchmarkMultiIntensity()`, `benchmarkMergeStrategies()`, `benchmarkBadBPMSubset()` tests in OA300, the existing GiantSteps tests, and the DAWOracle tests,
   **When** the `tolerance` parameter is added to the helpers,
   **Then** all existing call sites are updated to pass `0.02` so the tolerance contract is unchanged.
   **And** Acc1 numbers on all suites are bit-identical to pre-story values (tolerance logic is unchanged at 2%).
   **And** Acc2 numbers on OA300 and DAWOracle may increase (never decrease) because `{3, 1/3}` factors are newly added — this is the intended fix to the Story 2-1 deferred finding. GiantSteps Acc2 is unchanged (already had the factors).

6. **Given** the GiantSteps `benchmarkByGenre()` test,
   **When** the helpers gain the `tolerance` parameter,
   **Then** the genre-stratified breakdown still runs at 2% tolerance and remains unchanged.

7. **Standard gating (all stories in Epics 1-4):**
   - `make fmt` + `make lint` pass before and after implementation.
   - `make test` — all 153+ tests pass.
   - `make benchmark` — OA300 Acc1 at 2%: the integer correct count must equal the pre-story count (tolerance logic is unchanged at 2%; `69.5%` is the reference percentage but the invariant is on the integer count, not the rounded percentage). OA300 Acc2 at 2% must be `>= 89.0%` (strictly additive change from `{3, 1/3}` — any drop is a bug, not a tolerance-band flutter). Record post-change Acc2 and both 4% MIREX numbers as the new Completion Notes baseline; future regressions are measured against the new baseline, not the pre-story `89.0%`.
   - `make benchmark-giantsteps` — GiantSteps Acc1 at 2%: integer correct count equals pre-story count (`81.1%` reference). Acc2 at 2%: integer correct count equals pre-story count (`82.5%` reference — GiantSteps factor set is unchanged, Story 2-1 already landed MIREX factors there). Record the new 4% MIREX numbers as baselines.
   - `make oracle` — DAW oracle three-way comparison still runs without errors.
   - `make ablation` — full technique matrix completes without crashes.

## Tasks / Subtasks

**Execution order: Task 0 → 1 → 2 → 3 → 4 → 5. Each task is one file unless noted. Task 5 is final validation.**

- [x] **Task 0: Capture pre-story baseline integer counts** (AC: #7)
  - [x] 0.1 Before touching any code, run `make benchmark` on the current HEAD (Story 2-1 completion, commit `eefdb1f`). Record the **integer correct counts** for OA300 in Completion Notes as "Pre-story baseline": e.g., `OA300 Acc1: 209/300, Acc2: 267/300`. The rounded percentages (`69.5% / 89.0%`) are for human reading only — the integer counts are the regression invariants in Task 5.3.
  - [x] 0.2 Run `make benchmark-giantsteps` and record the GiantSteps integer counts the same way: e.g., `GiantSteps Acc1: 536/661, Acc2: 545/661` (reference percentages: `81.1% / 82.5%`).
  - [x] 0.3 Run `make oracle` and record the DAWOracle Acc2 integer count (Acc1 is unchanged at 2%, Acc2 will shift upward post-story and Task 5.5 needs the pre-value to confirm the shift is additive, not regressive).
  - [x] 0.4 These numbers go in the Completion Notes section of this file before any source edits. If they aren't captured at Task 0 they cannot be reconstructed after Task 1 changes the helpers.

- [x] **Task 1: Parameterize match helpers in `OA300BenchmarkTests.swift`** (AC: #3, #4, #5)
  - [x] 1.1 Change `isAcc1Match(_:_:)` signature to `isAcc1Match(_ detected: Double, _ expected: Double, tolerance: Double) -> Bool`. Body: `abs(detected - expected) / expected <= tolerance`.
  - [x] 1.2 Change `isAcc2Match(_:_:)` signature to `isAcc2Match(_ detected: Double, _ expected: Double, tolerance: Double) -> Bool`. Body checks factors `{1, 2, 1/2, 3, 1/3}` — i.e. add `|| isAcc1Match(detected * 3, expected, tolerance: tolerance) || isAcc1Match(detected / 3, expected, tolerance: tolerance)` to the existing check, and forward `tolerance` to all five `isAcc1Match` calls.
  - [x] 1.3 Update every call site inside `OA300BenchmarkTests` to pass `tolerance: 0.02`. Sites to fix (verified by reading the file): `benchmarkDefaultIntensity` table delta print (line ~87), `benchmarkBadBPMSubset` (line ~157), `benchmarkMergeStrategies` Acc1/Acc2 evaluation (lines ~238-241), `runBenchmark` aggregation loop (lines ~302-305).

- [x] **Task 2: Add OA300 dual-tolerance test methods** (AC: #1)
  - [x] 2.1 Refactor `runBenchmark(intensity:mergeStrategy:)` to accept `tolerance: Double` and forward it to the `isAcc1Match` / `isAcc2Match` calls in the aggregation loop. Default parameter is **not** allowed — every caller must pass it explicitly so future code reviewers cannot miss the dependency. After the refactor, grep the file for `analyzeBPM` and confirm exactly one call site remains in `runBenchmark` (the pre-existing one inside the `withTaskGroup`) — AC #1 requires one `analyzeBPM` per track per invocation.
  - [x] 2.2 Update existing callers (`benchmarkDefaultIntensity`, `benchmarkMultiIntensity`) to pass `tolerance: 0.02`. These tests retain their existing behavior at 2%.
  - [x] 2.3 Add `@Test("benchmark Acc1 strict (2% tolerance)") func benchmarkAcc1Strict() async throws` that calls `runBenchmark(intensity: .default, tolerance: 0.02)` and prints `=== OA300 Benchmark — Acc1 Strict (2% tolerance) ===` followed by Acc1 / Acc2 lines and the failure table (mirror the format of `benchmarkDefaultIntensity`). The tolerance must appear in the print header — a reader of raw test output must be able to tell the strict and MIREX runs apart without cross-referencing the method name.
  - [x] 2.4 Add `@Test("benchmark Acc1 MIREX (4% tolerance)") func benchmarkAcc1MIREX() async throws` that calls `runBenchmark(intensity: .default, tolerance: 0.04)` and prints `=== OA300 Benchmark — Acc1 MIREX (4% tolerance) ===` with the same fields. Audio is read once per track by `analyzeBPM` inside the helper — there is no per-track caching across the two `@Test` methods, and none is required by the AC. Do **not** add a `tolerance` field to `AccuracyMetrics` — keep it at the print layer.
  - [x] 2.4a **Optional diagnostic enhancement:** Consider printing a second table in `benchmarkAcc1MIREX` showing tracks that are Acc1-correct at 4% but not at 2% — these are the "MIREX-recovered" tracks and are the diagnostically most interesting output of the method. Skip this if it complicates the refactor; it can land in a follow-up story.
  - [x] 2.5 Do **not** delete `benchmarkDefaultIntensity()`. Rationale: it remains the canonical entry point for `make benchmark` and preserves its existing richer failure-table format. `benchmarkAcc1Strict` is the named-tolerance counterpart — they are intentionally redundant so that a reader can run `swift test --filter benchmarkAcc1Strict` without needing to know which method is the "default" one. If wall-clock duplication becomes a concern in a future story, collapse them then. Do not collapse them here — that is a scope decision for a different story.

- [x] **Task 3: Apply the same pattern to `GiantStepsBenchmarkTests.swift`** (AC: #2, #3, #5, #6)
  - [x] 3.1 Parameterize `isAcc1Match` and `isAcc2Match` exactly as in Task 1 (the GiantSteps `isAcc2Match` already has the `* 3` / `/ 3` factors from Story 2-1 — just thread `tolerance` through).
  - [x] 3.2 Update every call site in `GiantStepsBenchmarkTests` to pass `tolerance: 0.02`. Sites: `benchmarkDefaultIntensity` failure table delta (line ~89), `benchmarkByGenre` acc1/acc2 hits (lines ~113-118), `runBenchmark` aggregation loop (lines ~197-202).
  - [x] 3.3 Refactor `runBenchmark(intensity:mergeStrategy:)` to accept `tolerance: Double` and forward it through the dual-tempo `acc1Hit` / `acc2Hit` expressions. Update existing callers to pass `tolerance: 0.02`.
  - [x] 3.4 Add `benchmarkAcc1Strict()` and `benchmarkAcc1MIREX()` test methods mirroring Task 2.3-2.4. Print headers should say `GiantSteps` instead of `OA300` and include the explicit tolerance label, e.g. `=== GiantSteps Tempo Benchmark — Acc1 MIREX (4% tolerance) ===`.
  - [x] 3.5 `benchmarkByGenre` is unchanged in user-visible behavior — it still uses 2% — so just thread the parameter through.

- [x] **Task 4: Apply the MIREX Acc2 fix to `DAWOracleBenchmarkTests.swift`** (AC: #4, #5)
  - [x] 4.1 Parameterize `isAcc1Match(_:_:)` to take `tolerance: Double` (lines ~56-58).
  - [x] 4.2 Parameterize `isAcc2Match(_:_:)` to take `tolerance: Double` AND add the missing `* 3` / `/ 3` factors (lines ~60-64). After this story, all three benchmark files have identical Acc2 logic.
  - [x] 4.3 `classifyError` (lines ~43-54) hard-codes `0.04` ratio tolerances and a `0.02` Acc1 check — leave its internal numbers alone, but update the `isAcc1Match(detected, expected)` call (line ~45) to pass `tolerance: 0.02` so the file compiles.
  - [x] 4.4 Update **every** other `isAcc1Match` / `isAcc2Match` call site in DAWOracleBenchmarkTests.swift to pass `tolerance: 0.02`. Use `swift build` after the edit to surface any missed call sites (compiler will flag missing arguments).
  - [x] 4.5 No new `@Test` methods are added to DAWOracle in this story. DAWOracle is a diagnostic three-way comparison, not a benchmark target — the ACs (#1, #2) only mandate dual-tolerance methods for OA300 and GiantSteps. Dual-tolerance `@Test` methods for DAWOracle are out of scope and should not be added here.

- [x] **Task 5: Validation** (AC: #7)
  - [x] 5.1 `make fmt` then `make lint` — must be clean (1 pre-existing TODO warning is acceptable, same as Story 2-1).
  - [x] 5.2 `make test` — all existing tests pass (153+).
  - [x] 5.3 `make benchmark` — record OA300 numbers at both tolerances. Acc1 at 2%: the **integer correct count** must equal the pre-story count (not the rounded `69.5%` percentage — floating-point percentage formatting can mask a one-track delta). Acc2 at 2% must be `>= 89.0%`; because the `{3, 1/3}` factor addition is strictly additive, Acc2 **cannot** drop. If it drops at all, stop and investigate — a drop means a different bug, not a tolerance-band flutter. Record the post-change Acc2 and the 4% MIREX numbers in Completion Notes as the new regression baseline.
  - [x] 5.4 `make benchmark-giantsteps` — record GiantSteps numbers at both tolerances. Acc1 at 2% must be `>= 81.1%`, Acc2 at 2% must be `>= 82.5%` (Story 2-1 baseline).
  - [x] 5.5 `make oracle` — runs without errors. DAWOracle Acc2 will increase (never decrease) because `{3, 1/3}` factors were added; this is strictly additive and the expected fix to the Story 2-1 cross-file divergence. Record the post-change DAWOracle Acc2 in Completion Notes. A drop is a bug.
  - [x] 5.6 `make ablation` — full 64-combination matrix completes without crashes. Acc2 numbers per combination will shift upward (strictly additive) due to the `{3, 1/3}` factor addition — this is expected and not a regression. **Do not re-evaluate the `.optimal` technique preset based on this output in this story.** Preset re-evaluation is Epic 3 scope. The ablation run here is a crash-smoke-test only.
  - [x] 5.7 Run `swift test --filter OA300BenchmarkTests/benchmarkAcc1Strict` and `swift test --filter OA300BenchmarkTests/benchmarkAcc1MIREX` independently to prove individual filterability (AC #1). Confirm the filtered run executes only the selected method — scan the test output and verify no other `@Test` method names appear in the run log. If Swift Testing is running unrelated methods despite the filter, the filterability claim fails and the story is not done.
  - [x] 5.8 Run `swift test --filter GiantStepsBenchmarkTests/benchmarkAcc1Strict` and `swift test --filter GiantStepsBenchmarkTests/benchmarkAcc1MIREX` independently (AC #2).

## Dev Notes

### What Already Exists (Do NOT Recreate)

- `OA300BenchmarkTests.swift` (323 lines) — modify in place. Has `benchmarkDefaultIntensity`, `benchmarkMultiIntensity`, `benchmarkBadBPMSubset`, `benchmarkMergeStrategies`, `runBenchmark` helper.
- `GiantStepsBenchmarkTests.swift` (256 lines) — modify in place. Already has dual-tempo Acc1 + MIREX-compliant `isAcc2Match` from Story 2-1. Has `benchmarkDefaultIntensity`, `benchmarkByGenre`, `runBenchmark`, `runBenchmarkDetailed`.
- `DAWOracleBenchmarkTests.swift` — modify `isAcc1Match` / `isAcc2Match` only. Do not add benchmark methods.
- `Tests/BoomBoomBoomKitTests/Fixtures/oa300-ground-truth.json` — no schema changes.
- `giantsteps-tempo-ground-truth.json` (lives in corpus dir, not repo) — no schema changes.

### Why "Dual Tolerance" Means Two `@Test` Methods, Not One That Iterates

ADR-10 wording is: *"`benchmarkAcc1Strict()` (2%) and `benchmarkAcc1MIREX()` (4%) as independent, individually filterable tests."* The user's intent is that you can do `swift test --filter benchmarkAcc1MIREX` and get just the 4% number. A single iterating method would fail that requirement.

The AC phrase *"share pre-computed analysis results (audio read once, iterate over thresholds)"* refers to the `benchmarkMergeStrategies` style **within** a method — i.e. each track is analyzed exactly once per `@Test` invocation (not once per metric). It does **not** mean the two `@Test` methods cache results for each other (that would require process-level state, which Swift Testing structs do not support cleanly).

If you find yourself trying to write a `@MainActor static var cache` or use `nonisolated(unsafe)` to share between methods — stop. That is not what the AC asks for. Two methods, each calling the same helper, is the design.

### Why `tolerance` Has No Default Parameter

Story 2-1 left a latent bug where the OA300 / DAWOracle Acc2 was inconsistent with GiantSteps. That is exactly the kind of thing a default parameter masks. By making `tolerance` an explicit required argument, every future call site has to think about which tolerance applies. The compiler will reject any forgotten call site.

**Trade-off acknowledgement:** This is a one-time migration cost (10+ call site edits across 3 files) paid for long-term clarity in *this* test infrastructure. It is not a universal best practice — defaults are fine in code paths where semantic drift is unlikely. The specific motivation here is the Story 2-1 cross-file divergence, where a default would have let the divergence persist silently. Do not generalize this pattern to other helpers without the same motivating history.

### Acc2 Numerical Movement on OA300 and DAWOracle

OA300's and DAWOracle's current `isAcc2Match` only check `{1, 2, 1/2}`. After this story they will also check `{3, 1/3}`. That can only **add** matches, never remove them, so Acc2 on both suites is strictly `>= pre-story value`. GiantSteps is already MIREX-compliant from Story 2-1 — its Acc2 numbers are bit-identical pre/post.

DAWOracle is a diagnostic suite and its printed Acc2 numbers will shift upward — this is the intended closure of the Story 2-1 cross-file divergence finding. Record the new OA300 and DAWOracle Acc2 values in Completion Notes as the new regression baseline for future stories.

If any Acc2 drops at all, stop — the factor addition is strictly additive, so a drop indicates an unrelated bug, not tolerance-band noise.

### Pre-Read Audio Pattern (For Reference, Not Required Here)

`benchmarkMergeStrategies` (OA300, lines 181-253) reads audio once via `PCMBufferReader.readMonoSamples` and iterates strategies. You do **not** need this pattern for dual tolerance — the existing `runBenchmark` helper already calls `analyzeBPM` once per track per invocation, and that is sufficient for "audio read once per method" semantics. Do not refactor `runBenchmark` to use the `readMonoSamples` + manual `BPMAnalyzer.estimateBPM` loop unless a future story explicitly demands it.

### Architecture Compliance

- **ADR-10:** Dual tolerance as separate test methods. This story is the implementation.
- **No library source changes** in this story — test infrastructure only. Do not touch `Sources/BoomBoomBoomKit/`.
- **No new public API.** `AudioAnalysisService.Options` is not modified.
- **No new fixtures.** Ground truth files are unchanged.
- **No `make` target changes.** `make benchmark` and `make benchmark-giantsteps` continue to run their full suites; users who want a specific tolerance use `swift test --filter` directly.

### Project Structure Notes

- Files modified (3): `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift`, `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift`, `Tests/BoomBoomBoomKitTests/DAWOracleBenchmarkTests.swift`.
- Files created: 0.
- Net new `@Test` methods: 4 (2 in OA300, 2 in GiantSteps).

### Do Not Unify: `classifyError`'s `0.04` ≠ MIREX Acc1 `0.04`

DAWOracle's `classifyError` helper (lines ~43-54) hard-codes `0.04` as a **ratio categorization band** used to decide whether an error is "octave-like", "triplet-like", or "other". After this story, `benchmarkAcc1MIREX` uses `0.04` as the **MIREX Acc1 tolerance**. These are the same number for completely different purposes. A future reader who thinks "we should DRY these up" will break diagnostic classification. Do not unify. Leave `classifyError`'s internal `0.04` alone — Task 4.3 explicitly preserves it.

### Forward Reference: `make baseline-record` for Story 2-3

Baselines in this story are captured manually in Completion Notes (Task 0). That works for one story but does not scale — Story 2-4 (corpus expansion) will shift every baseline and re-recording by hand is error-prone. Story 2-3 (performance benchmark infrastructure) should consider adding a `make baseline-record` target that captures Acc1/Acc2 integer counts into a committed JSON file so baselines are machine-readable and diffable across PRs. Out of scope here; just a pointer for whoever picks up Story 2-3.

### Forward Hazard: Epic 2.4 Ground-Truth Validation

Pre-existing issue across all three benchmark files: `isAcc1Match(detected, expected)` divides by `expected`, which crashes if `expected == 0`. Current corpora are Rekordbox- or crowdsource-derived and have no `bpm: 0` tracks, so this is theoretical today. Epic 2.4 ("OA300 corpus expansion with genre diversity") will add new sources — validate at ground-truth load time that every track has `bpm > 0` before trusting corpus data. Out of scope for this story, but the risk grows with every corpus addition.

### Previous Story Intelligence (Story 2-1)

- **Force-unwrap was a review finding.** Use `track.tempo2.map { ... } ?? false` for optional dual-tempo checks (already in place in GiantSteps — preserve it when threading `tolerance` through).
- **`isAcc2Match` divergence between files was explicitly deferred to this story.** Story 2-1 review finding: *"`isAcc2Match` diverges between GiantSteps and OA300/DAWOracle — deferred, explicitly Story 2-2 scope."* This story closes that finding.
- **`isAcc1Match` division by zero when `expected == 0`** is a known pre-existing issue across all 3 files. **Out of scope for this story** — do not fix it here unless it crashes the new test methods. If you decide to fix it, file it as a separate review finding.
- **Standard gating checklist** (fmt, lint, test, benchmark, benchmark-giantsteps, oracle, ablation) is the contract for "done" in this epic.

### Epic 1 Retro Inputs (carry-over)

- **Tighten task scoping** — every task in this story has a verified line number from the actual file, and Task 4.4 explicitly uses the compiler to verify completeness instead of trusting eyeballs.
- **Tests are the primary quality signal.** Every AC has a `swift test --filter` command in Task 5 that proves it.
- **Multi-model review optional.** This is not a pointer-heavy story; default review is fine.

### References

- [Source: _bmad-output/planning-artifacts/epics.md, Story 2.2 section (lines 358-378)]
- [Source: _bmad-output/planning-artifacts/architecture.md, ADR-10 (lines 249-250), Test infrastructure pattern (lines 380-386)]
- [Source: _bmad-output/implementation-artifacts/2-1-giantsteps-tempo-dataset-integration.md, deferred review findings + dual-tempo Acc1 logic]
- [Source: Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift, lines 37-47 — reference implementation of MIREX-compliant `isAcc2Match` from Story 2-1]
- [Source: Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift, lines 181-253 — `benchmarkMergeStrategies` is the pattern referenced by ADR-10's "iterate over thresholds" phrase]
- [Source: MIREX 2021 Audio Tempo Estimation wiki — Acc2 factors `{1, 2, 1/2, 3, 1/3}`]
- [Source: mir_eval `tempo.py` — 4% relative tolerance reference]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

### Completion Notes List

- **Pre-story baselines (commit eefdb1f, before any source edits):**
  - OA300 Acc1: 57/82 (69.5%), Acc2: 73/82 (89.0%)
  - GiantSteps Acc1: 536/661 (81.1%), Acc2: 545/661 (82.5%)
  - DAWOracle Acc1: 57/82 (69.5%), Acc2: 73/82 (89.0%)
- **Post-story results (new regression baselines):**
  - OA300 Acc1 Strict (2%): 57/82 (69.5%), Acc2: 73/82 (89.0%) -- integer counts match pre-story
  - OA300 Acc1 MIREX (4%): 57/82 (69.5%), Acc2: 73/82 (89.0%)
  - GiantSteps Acc1 Strict (2%): 536/661 (81.1%), Acc2: 545/661 (82.5%) -- integer counts match pre-story
  - GiantSteps Acc1 MIREX (4%): 556/661 (84.1%), Acc2: 562/661 (85.0%)
  - DAWOracle Acc1: 57/82 (69.5%), Acc2: 73/82 (89.0%) -- unchanged (no new triplet matches in corpus)
  - Ablation: all 64 combinations passed, no crashes

### File List

- `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift` (modified) — parameterized tolerance, added {3,1/3} Acc2 factors, added benchmarkAcc1Strict/benchmarkAcc1MIREX
- `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift` (modified) — parameterized tolerance, added benchmarkAcc1Strict/benchmarkAcc1MIREX
- `Tests/BoomBoomBoomKitTests/DAWOracleBenchmarkTests.swift` (modified) — parameterized tolerance, added {3,1/3} Acc2 factors

### Review Findings

- [x] [Review][Defer] Division by zero in `isAcc1Match` when `expected == 0` [all 3 benchmark files] -- deferred, pre-existing. Spec notes as "Forward Hazard: Epic 2.4 Ground-Truth Validation." All `isAcc1Match` calls divide by `expected` with no guard; `classifyError` is the only caller that checks `expected > 0`.
- [x] [Review][Defer] Negative or zero tolerance not guarded [all 3 benchmark files] -- deferred, pre-existing. No validation that `tolerance > 0`. No current call site passes bad values. Not introduced by this diff.
- [x] [Review][Defer] `benchmarkByGenre` calls `runBenchmark` but discards meaningful use of returned metrics [GiantStepsBenchmarkTests.swift] -- deferred, pre-existing. Runs full corpus then recomputes genre-level stats from separate detailed run.

### Change Log

- Parameterized `isAcc1Match` and `isAcc2Match` across all 3 benchmark files with explicit `tolerance: Double` parameter (no default). Closes Story 2-1 cross-file Acc2 divergence finding. (Date: 2026-04-13)
- Added `{3, 1/3}` MIREX-compliant Acc2 factors to OA300 and DAWOracle (GiantSteps already had them from Story 2-1). All 3 files now have identical Acc2 factor sets.
- Added 4 new `@Test` methods: `benchmarkAcc1Strict` (2%) and `benchmarkAcc1MIREX` (4%) in both OA300 and GiantSteps, each individually filterable via `swift test --filter`.
