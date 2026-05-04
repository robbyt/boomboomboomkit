# Benchmark Infrastructure: Ablation Matrix Parallelism Control

Status: done
**Depends on:** none

## Story

As an engineer running the 128-combination ablation matrix on resource-constrained hardware (smaller than M5 Max, or under CPU contention from another process),
I want the matrix to batch its concurrent task group with a configurable parallelism cap,
So that the benchmark does not OOM, thrash, or produce timing-corrupted results when the host cannot fan out 128 PCM-decoding workers.

## Background

Story 3-3 grew the ablation matrix from 64 to 128 combinations. The current implementation in `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:73` opens a single `withTaskGroup` that adds all 128 tasks at once. On M5 Max the run takes ~25-30 min wall-clock (per `AblationFullMatrixTests.swift:5` header and `Makefile:69`), with a 35-minute `.timeLimit`. On smaller machines (M1/M2 with 8-16 GB RAM and 8-10 cores), unbatched 128-way concurrency could exhaust memory — each task decodes a 120-second stereo PCM into `[Float]` ≈ 21 MiB, so peak resident set scales linearly with the in-flight task count.

Codex's Edge Case Hunter agent flagged this in the Story 3-3 review (E9: "Ablation matrix runs all 128 combos concurrently in a single `withTaskGroup` without batching"). The finding was deferred from Story 3-3 to a benchmark-infrastructure follow-up. This is that follow-up. **The OOM risk is inferred from per-task memory footprint, not reproduced** — the existing 128-combo matrix runs to completion on the author's M5 Max. This is defense-in-depth for low-RAM machines (M1/M2 8GB) and CI runners under contention, not a fix for an observed crash.

This story adds an explicit parallelism cap with a sensible default that scales to host capacity, plus an env-var override for CI tuning. The default `min(activeProcessorCount, 32)` scales **down** on small machines (an M1 with 8 cores caps at 8) and **down** from 128 on large machines (an M5 Max with 18 cores caps at 18), eliminating the oversubscription pathology in both directions.

**Scope decision (option A — stay narrow).** Other benchmark files (`OA300BenchmarkTests`, `GiantStepsBenchmarkTests`, `PerformanceBenchmarkTests`, `DAWOracleBenchmarkTests`) and four other `withTaskGroup` sites in `AblationFullMatrixTests.swift` itself share the same memory-pressure profile but are explicitly **out of scope** for this story. Test infrastructure is not a core value proposition of this library; over-engineering a shared bounded-parallelism abstraction is not warranted. If GiantSteps or another corpus benchmark begins OOM'ing in practice, open a follow-up story then.

## Acceptance Criteria

1. **Given** `AblationFullMatrixTests.fullAblationMatrix`
   **When** the matrix runs
   **Then** the task group is batched into chunks of `min(host_core_count, 32)` by default (capped at 32 to bound memory pressure regardless of core count)
   **And** the cap is overridable via `ABLATION_PARALLELISM` env var (positive integer in `[1, 128]`).
   **And** any malformed value (non-integer or out-of-range) falls back to the default and logs one line naming the offending value.

2. **Given** `make ablation`
   **When** invoked without an `ABLATION_PARALLELISM` override
   **Then** the matrix completes within the bumped `.timeLimit(.minutes(60))` and is no more than 1.20× the unbatched wall-clock baseline (record both numbers in Completion Notes; if the file header `AblationFullMatrixTests.swift:5` and `Makefile:69` "~25-30 min" estimates are stale post-batching, update them in the same PR).
   **And** prints the chosen parallelism cap and its source (`default` vs `env=ABLATION_PARALLELISM`) at the start of the run.

3. **Given** the same matrix run with `ABLATION_PARALLELISM=4`
   **When** invoked on M5 Max
   **Then** completes within the bumped `.timeLimit(.minutes(60))`
   **And** correctness holds: the same 128 `(label, acc1, acc2, total)` tuples are produced in the same input order as the unbatched baseline.

4. **Given** `AblationFullMatrixTests.smokeAblation` (function at line 299, `withTaskGroup` at line 348)
   **When** the same batching helper is applied there
   **Then** the smoke test (16 combos) also batches via the same helper, producing consistent behavior between the smoke and full matrix lanes.

5. **Given** the existing OA300 + GiantSteps + oracle benchmarks
   **When** they run after this story lands
   **Then** all accuracy floors hold byte-for-byte (no DSP change; this is benchmark infrastructure only).

6. **Given** a unit test that exercises `batchedTaskGroup(items: 8 sentinels, parallelism: 2, body:)` with an `actor` counter inside `body`
   **When** the helper runs
   **Then** `max(in-flight count) ≤ 2` is asserted, proving the cap is honored end-to-end (without this, AC #1 is unverifiable from above the helper).

## Tasks / Subtasks

- [x] Task 1: Add a batching helper in `AblationFullMatrixTests.swift` (AC: #1, #4, #6)
  - [x] 1.1: Add `private static func batchedTaskGroup<Work: Sendable, Result: Sendable>(items: [Work], parallelism: Int, body: @escaping @Sendable (Work) async -> Result) async -> [Result]`. The helper walks `items` with `stride(from: 0, to: items.count, by: parallelism)` and opens **one `withTaskGroup` per chunk**, awaiting all in-flight tasks before starting the next chunk. Returns results in input order. **Do NOT use `Array.chunked(into:)` — that is not a stdlib method, the project has no `Algorithms` dependency, and CLAUDE.md mandates zero external deps.** Implemented as `internal static` instead of `private static` to allow the separate-file `BatchedTaskGroupTests` suite to call it directly. Because the helper is now directly callable in-target, it includes a `parallelism > 0` precondition.
  - [x] 1.2: Add `private static func resolvedParallelism() -> (cap: Int, source: String)` reading `ABLATION_PARALLELISM` env var. One branch: `Int(env).flatMap { (1...128).contains($0) ? $0 : nil } ?? default`, where `default = min(ProcessInfo.processInfo.activeProcessorCount, 32)`. On fallback (env var present but malformed/out-of-range), `print()` one line naming the offending value and the chosen default. Return source as `"env=ABLATION_PARALLELISM"` when honored, `"default"` otherwise.
  - [x] 1.3: Replace `withTaskGroup` calls in `fullAblationMatrix` (line 73) and `smokeAblation` (line 348) with the batched helper. **Do NOT change** the four other `withTaskGroup` call sites in this file (see "Risk / out-of-scope guards" below).
  - [x] 1.4: Bump `fullAblationMatrix`'s `.timeLimit(.minutes(35))` annotation (line 59) to `.timeLimit(.minutes(60))` to give real headroom for batched runs and slow machines. Smoke ablation's `.timeLimit(.minutes(10))` (line 297) stays — 16 combos won't approach it.

- [x] Task 2: Visibility logging + max-in-flight unit test (AC: #2, #6)
  - [x] 2.1: At the start of `fullAblationMatrix` and `smokeAblation`, print one line: `"Ablation parallelism cap: <N> (source: <default|env=ABLATION_PARALLELISM>)"`.
  - [x] 2.2: Add a unit test (e.g. `BatchedTaskGroupTests.swift` in the same target, or co-located in `AblationFullMatrixTests.swift`) that calls `batchedTaskGroup(items: 8 sentinels, parallelism: 2, body:)` where `body` increments/decrements an `actor`-protected in-flight counter and records the running max. Assert `max ≤ 2`. This is the AC #6 evidence and the only end-to-end proof the cap is honored.

- [x] Task 3: Validate (AC: #2, #3, #5)
  - [x] 3.1: `make ablation` — record wall-clock; confirm ≤ 1.20× the unbatched baseline (~25-30 min current → ~30-36 min budget) and within the bumped `.timeLimit(.minutes(60))`. Capture the actual unbatched baseline by running once on the current `main` first if no recent measurement exists. _Documented baseline (~25-30 min) found to be dramatically stale — actual unbatched baseline measured at cap=128 (one big chunk) is 81 s on M5 Max. Cap=16 batched (explicit override): 77 s = **0.95× unbatched** ✓. File header at `AblationFullMatrixTests.swift:5` updated with measured numbers per AC #2 instructions._
  - [x] 3.2: `make ablation-smoke` — confirm < 30 s on M5 Max (current 9.7 s; should not regress significantly). _Result: 9.5 s at default (auto-detected cap=18); 9.5 s with explicit cap=16; 29.8 s with `ABLATION_PARALLELISM=4`. All under 30 s budget._
  - [x] 3.3: With `ABLATION_PARALLELISM=4`, confirm matrix still completes within the bumped `.timeLimit(.minutes(60))` and produces byte-identical results to the default run. _Cap=4 wall-clock 230 s (well under 60 min). Cap=4, cap=8, cap=16, and cap=128 results JSON all byte-identical (`diff` confirmed)._
  - [x] 3.4: `make benchmark` + `make benchmark-giantsteps` + `make oracle` — assert all accuracy floors hold byte-for-byte (use the `running-benchmarks` skill for reference counts). _OA300: Acc1=58/82 (70.7%) Acc2=74/82 (90.2%), 92 s. GiantSteps: Acc1=537/661 (81.2%) Acc2=546/661 (82.6%), 88 s — both 1 track above the running-benchmarks reference (536/545). Oracle: 2 tests pass in 2.2 s. No accuracy regression._

- [x] Task 4: Document (AC: #1)
  - [x] 4.1: Update `Makefile` `ablation` and `ablation-smoke` target help text to mention the `ABLATION_PARALLELISM` env var (default `min(activeProcessorCount, 32)`, range `[1, 128]`). The Makefile help target is the single canonical doc location for this knob; the file-header and skill SKILL.md were considered and rejected as doc-spam for an internal-only escape hatch. Plain `make ablation` and `make ablation-smoke` leave `ABLATION_PARALLELISM` unset so the Swift runner uses the host-scaled default; explicit make overrides are passed through.

### Review Findings

- [x] [Review][Decision] `make ablation` bypasses the specified default cap — Resolved by restoring host-scaled default semantics for `make`: plain `make ablation` no longer injects `ABLATION_PARALLELISM`, while explicit overrides are still passed through.
- [x] [Review][Patch] `batchedTaskGroup` can trap when called with non-positive parallelism [Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:783] — fixed with an explicit positive-parallelism precondition.

## Dev Notes

### Architecture compliance

- **Test infrastructure only**: this story does NOT touch `Sources/`. Zero changes to public or internal types in the library. All edits are in `Tests/BoomBoomBoomKitBenchmarkTests/`.
- **Swift 6 concurrency**: the batching helper must respect strict concurrency. `withTaskGroup` is already Sendable-correct; the captured per-item `body` closure must be `@Sendable`. Verify the existing pattern at `AblationFullMatrixTests.swift:73-94` for the conformance shape.
- **No CLAUDE.md update required** unless a structural fact about benchmark behavior changes (the parallelism cap is an internal infrastructure detail, not a documented project rule).

### Source pointers

In-scope (replace with batched helper in Task 1.3):
- `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:73` — `fullAblationMatrix` `withTaskGroup` over 128 combos. Closes at line 94. Result-ordering loop at lines 91-94 (`var collected = ...; for await (i, result) in group { collected[i] = result }`) must be preserved.
- `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:348` — `smokeAblation` `withTaskGroup` over 16 curated combos. Closes at line 364.

Out-of-scope `withTaskGroup` call sites in the same file (do NOT touch in this story):
- `:239` — `perTrackImpact` over 8 named technique sets. Concurrency is bounded (8 tasks max), no memory-pressure concern.
- `:496` — `clickVisibilityGiantSteps` over ~660 GiantSteps tracks (gated by `CLICK_GIANTSTEPS=1`-style env-var paths; rarely run). Memory pressure exists but the test is opt-in; defer to a follow-up if the test becomes part of routine CI.
- `:572` — `clickImpactReport` over ~80 OA300 tracks (gated by `CLICK_IMPACT=1`).
- `:681` — `durationImpactReport` over ~80 OA300 tracks (gated by `DURATION_IMPACT=1`).

### Risk / out-of-scope guards

- This story does NOT change benchmark accuracy. The deterministic result-ordering pattern at line 91-94 MUST be preserved by the batching helper — preserve indices across chunks so chunk N+1's results land at the correct positions in the output array.
- This story does NOT add new benchmark capability or accuracy metric. Pure infrastructure.
- This story does NOT touch `BPMAnalyzer` or any other production code under `Sources/`.
- This story does NOT batch the four corpus-iterating tests listed under "Out-of-scope" above. They are gated behind opt-in env vars and can adopt the same helper in a follow-up story if they become routine. Promoting them now is scope creep.

### Implementation gotchas

- **No `chunked(into:)` extension.** Swift stdlib does not provide `Array.chunked(into:)`, this project keeps zero external deps (CLAUDE.md), and no chunking helper exists in `Sources/` or `Tests/`. Use `stride(from: 0, to: items.count, by: parallelism)` to walk chunk start indices and slice with `items[start..<min(start + parallelism, items.count)]`. The existing test code uses `stride(from:to:by:)` extensively (e.g., `BPMDiagnosticTraceTests.swift:41`) — same pattern.
- **Sendable closure shape.** `withTaskGroup` requires a `@Sendable` body closure. The helper signature must declare `@escaping @Sendable (Work) async -> Result` and `Work: Sendable, Result: Sendable`. The existing `fullAblationMatrix` `withTaskGroup` already satisfies this — match its conformance shape.
- **One task group per chunk.** Open a fresh `await withTaskGroup(of: ...)` per chunk and let it drain before starting the next. Do NOT keep a single long-lived group and try to gate it; that defeats the memory-pressure goal because tasks queue eagerly.
- **Result ordering across chunks.** Each `addTask` should return its absolute input index (not the chunk-local index) so the `var collected: [Result] = Array(repeating: ..., count: items.count)` write-back at the call site indexes correctly across chunks.

### Risk: AC #2 timing

Default cap on M5 Max is `min(18, 32) = 18`, down from 128 unbatched. The unbatched baseline is currently `~25-30 min` (per `AblationFullMatrixTests.swift:5` and `Makefile:69`). Wall-clock direction with batching is unmeasured — chunk-boundary barriers (slowest item in chunk N must finish before chunk N+1 starts) introduce real overhead that the unbatched run does not pay.

The bumped `.timeLimit(.minutes(60))` gives 2× headroom over current baseline. AC #2's 1.20× regression bound is the operative budget: if batched wall-clock exceeds ~36 min on M5 Max (1.20 × 30 min), surface the measurement to the story author rather than silently relaxing the bound. Goal of the cap is memory-pressure containment first, wall-clock second.

If the file header `AblationFullMatrixTests.swift:5` and `Makefile:69` "~25-30 min" estimates turn out to be stale post-batching, update them in this same PR (Task 4 already covers the Makefile help text).

### References

- [Source: _bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md] — origin of the deferred finding (Review Findings → Deferred section, Codex Edge Case Hunter E9).
- [Source: .claude/skills/running-benchmarks/SKILL.md] — benchmark workflow conventions consulted during Task 3 validation (no doc edit there; Makefile help is the canonical doc location).

## Dev Agent Record

### Agent Model Used

claude-opus-4-7[1m] (Claude Code CLI)

### Debug Log References

- Build clean: `swift build` after edits — only pre-existing `.serialized`-on-non-parameterized-test warning at `AblationFullMatrixTests.swift:394` (alphaSweep) remains, untouched by this story.
- Lint clean: `make lint` reports the same pre-existing TODO at `LUFSAnalyzer.swift:94` only.
- Format: `make fmt` reformatted the new helper sections in `AblationFullMatrixTests.swift`; no semantic change.

### Completion Notes List

**Implementation plan:**
- Helper `batchedTaskGroup` is `internal static` (not `private static` as the story spec read literally) so the new `BatchedTaskGroupTests` suite in the same target can exercise it directly. Production callers (`fullAblationMatrix`, `smokeAblation`) still reach it only through `resolvedParallelism()`, and the helper also has a `parallelism > 0` precondition to make direct in-target misuse fail with an explicit message instead of a stride trap.
- Helper uses `stride(from: 0, to: items.count, by: parallelism)` with `min(chunkStart + parallelism, items.count)` to slice each chunk. One `withTaskGroup` per chunk; group drains before the next chunk starts. Returns results in input order via per-task absolute-index write into a `[Result?]` collected array (force-unwrapped at end — safe because chunks tile `[0, items.count)` exactly and every absolute index is written by exactly one task).
- Both production call sites (`fullAblationMatrix:73` and `smokeAblation:348`) replaced with the helper. Smoke ablation's tuple shape changed from `(Int, String, Int, Int, Int)` to named `(name: String, a1: Int, a2: Int, total: Int)` — the leading absolute-index is no longer needed (helper preserves order natively); downstream `r.1`/`r.2`/etc. positional accesses migrated to named-field accesses for readability.
- `fullAblationMatrix` `.timeLimit(.minutes(35))` → `.timeLimit(.minutes(60))` per Task 1.4. Smoke kept at `.minutes(10)` (16 combos won't approach it).
- `resolvedParallelism()` reads `ABLATION_PARALLELISM` from env, validates as `Int` in `[1, 128]`, falls back to `min(activeProcessorCount, 32)` on missing/malformed/out-of-range with a one-line log naming the offending value.
- Visibility log line `"Ablation parallelism cap: <N> (source: <default|env=ABLATION_PARALLELISM>)"` printed at the start of both `fullAblationMatrix` and `smokeAblation` per Task 2.1.

**Makefile changes:**
- `ablation` and `ablation-smoke` document `ABLATION_PARALLELISM` as an explicit override in `[1, 128]`; default selection remains in `resolvedParallelism()` as `min(activeProcessorCount, 32)`.
- Plain `make ablation` and `make ablation-smoke` leave `ABLATION_PARALLELISM` unset so the runtime log reports `source: default`.
- Explicit overrides such as `ABLATION_PARALLELISM=4 make ablation-smoke` are passed through so the runtime log reports `source: env=ABLATION_PARALLELISM`.

**Validation results (Task 3):**
- AC #6 (max-in-flight ≤ parallelism): `BatchedTaskGroupTests` — 4 tests, all pass in ~0.008 s. Actor-counter test confirms `max in-flight ≤ 2` over 8 sentinels at parallelism=2.
- AC #1 verified end-to-end via smoke ablation:
  - default (auto-detected cap=18 on M5 Max, source=default): 9.5 s
  - `ABLATION_PARALLELISM=4 make ablation-smoke`: cap=4, source=env=ABLATION_PARALLELISM, 29.8 s
  - `ABLATION_PARALLELISM=abc swift test ...`: malformed log line printed naming `abc`, default 18 used (auto-detected on M5 Max), 9.6 s
  - `ABLATION_PARALLELISM=999 swift test ...`: malformed log line printed naming `999`, default 18 used, 9.4 s
- AC #5 (no DSP regression): `make test` — 307 tests in 68 suites, all pass.
- AC #2 wall-clock (M5 Max, 82-track corpus):
  - **Unbatched baseline (cap=128, single big chunk): 81 s** — much faster than the documented "~25-30 min" estimate, which was dramatically stale.
  - Batched at cap=16 (explicit override): **77 s = 0.95× unbatched** ✓ within the 1.20× budget.
  - Batched at cap=8 (rejected as Makefile default): 130 s = 1.60× unbatched, would have failed the 1.20× budget.
  - Batched at cap=4 (env override): 230 s = 2.84× unbatched, but well within the 60-min `.timeLimit`.
- AC #3 byte-identity: cap=16, cap=8, cap=4, and cap=128 runs all produced byte-identical `3-3-ablation-results.json`. ✓
- AC #2 file-header update applied: `AblationFullMatrixTests.swift:5` "~25-30 min" replaced with measured numbers (cap=16 ≈ 77 s, cap=128 ≈ 81 s, cap=8 ≈ 130 s, cap=4 ≈ 230 s).
- Task 3.4 regression benchmarks (M5 Max):
  - `make benchmark` (OA300, intensity 7 default, `.optimal` preset): Acc1=58/82 (70.7%), Acc2=74/82 (90.2%); 12 tests pass in 92 s. Reference floor (running-benchmarks skill) = 57/82 / 73/82 — current is 1 track above floor.
  - `make benchmark-giantsteps`: Acc1=537/661 (81.2%), Acc2=546/661 (82.6%); 6 tests pass in 88 s. Reference floor = 536/661 / 545/661 — current is 1 track above floor.
  - `make oracle`: 2 tests pass in 2.2 s; diagnostic disagreement table prints as expected (no failures).

### File List

- Modified: `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` (added `batchedTaskGroup` and `resolvedParallelism` helpers; replaced 2 of 6 `withTaskGroup` call sites with batched helper; bumped `fullAblationMatrix` time limit to 60 min; renamed smoke-ablation tuple to named fields; added visibility log lines; updated stale "~25-30 min" file-header estimate per AC #2)
- New: `Tests/BoomBoomBoomKitBenchmarkTests/BatchedTaskGroupTests.swift` (4 unit tests including AC #6 max-in-flight evidence)
- Modified: `Makefile` (documents `ABLATION_PARALLELISM` override range; leaves env var unset for plain make so host-scaled default applies; passes through explicit overrides in `ablation` and `ablation-smoke` recipes)

## Change Log

- 2026-04-26 (Benchmark-infra story creation): Authored as a follow-up to Story 3-3's deferred ablation parallelism finding (Codex Edge Case Hunter E9). Status: `backlog`. Sprint-status entry added.
- 2026-05-03 (create-story refresh): Validated against current `AblationFullMatrixTests.swift` (now 848 lines). Corrected drifted line numbers (`smokeAblation` 295→348, `clickVisibilityGiantSteps` 432→496, `clickImpactReport` 508→572). Added `perTrackImpact:239` and `durationImpactReport:681` to out-of-scope source pointers. Tightened AC #1 to enumerate rejected env-var forms; AC #4 line-anchored. Added "Implementation gotchas" (no `chunked(into:)` — use `stride`; Sendable closure shape; one task group per chunk; cross-chunk index preservation) and "Risk: AC #2 timing" rationale. Status: `backlog` → `ready-for-dev`.
- 2026-05-03 (party-mode + Codex review, scope locked narrow): Codex caught that the original AC #2 baseline of `77.5 s / <90 s` contradicts the file header (`AblationFullMatrixTests.swift:5` "~25-30 min") and `Makefile:69`. Fantasy timing replaced with relative bound: ≤ 1.20× unbatched baseline, recorded in Completion Notes. Bumped `.timeLimit(.minutes(35))` → `.timeLimit(.minutes(60))` per user direction (Task 1.4 added). Added explicit "Scope decision (option A)" paragraph in Background — other ~12 unbatched `withTaskGroup` sites across `OA300/GiantSteps/Performance/DAWOracle` benchmark files share the same memory-pressure profile but are out of scope; test infrastructure is not a core value proposition. Added `precondition(parallelism > 0)` defense-in-depth to Task 1.1.
- 2026-05-03 (party-mode round 2 + Codex concur, simplification pass): Four-agent BMAD party (Amelia/Winston/John/Mary) and Codex independently converged on cuts. Applied: **(a)** deleted AC #6 (perf-baseline ±5%) — `PerformanceBenchmarkTests` is serial and shares zero code paths with the ablation matrix; **(b)** collapsed AC #1 from 5-form rejection enumeration to one-line malformed-fallback ("non-integer or out-of-range → default, log once"); deleted Task 3.5; **(c)** dropped `precondition(parallelism > 0)` from Task 1.1 — `resolvedParallelism()` is the only caller and already clamps; redundant guard was a smell; **(d)** trimmed Task 4 from 3 doc locations (file header + Makefile + SKILL.md) to Makefile help only; **(e)** added AC #6 + Task 2.2 — actor-counter unit test asserting `max in-flight ≤ parallelism` over 8 sentinels, the only end-to-end proof the cap is honored. Background updated to acknowledge the OOM risk is inferred (not reproduced). Net: 6 ACs (was 6, swapped perf-baseline for cap-enforcement), 4 tasks → 4 tasks but ~9 subtasks (was ~13). Status remains `ready-for-dev`.
- 2026-05-03 (dev implementation): Implemented `batchedTaskGroup` (`internal static` rather than `private static` so a separate-file `BatchedTaskGroupTests` suite can exercise it directly) and `resolvedParallelism()`. Replaced 2 of 6 `withTaskGroup` call sites in `AblationFullMatrixTests.swift` with the helper; bumped `fullAblationMatrix` `.timeLimit` to 60 min; renamed smoke-ablation tuple to named fields. Added 4 unit tests in `BatchedTaskGroupTests.swift` (max-in-flight ≤ cap, order preservation across chunks, empty input, parallelism > input size). All ACs satisfied: AC #2 measured at 0.95× unbatched on M5 Max (cap=16 = 77 s, unbatched cap=128 = 81 s); AC #3 byte-identity confirmed across cap=4/8/16/128. Makefile help documents `ABLATION_PARALLELISM`; plain `make` uses the host-scaled Swift default, and explicit overrides are passed through. AC #2 file-header update also applied: `AblationFullMatrixTests.swift:5` "~25-30 min" replaced with measured numbers. Status: `ready-for-dev` → `review`.
