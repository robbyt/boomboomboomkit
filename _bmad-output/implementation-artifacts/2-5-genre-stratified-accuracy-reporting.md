# Story 2.5: Genre-Stratified Accuracy Reporting

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a library author,
I want OA300 and GiantSteps benchmarks to print per-genre Acc1/Acc2 alongside the aggregate, with small buckets flagged as "insufficient sample" and significantly-underperforming genres marked as tuning candidates,
so that I can identify genre-specific weaknesses without inventing a new report format per corpus and without double-analyzing every track.

## Scope Notes

- **Test-support only — zero edits under `Sources/BoomBoomBoomKit/`.** The stratified report is a benchmark-infrastructure story. The library stays untouched; OA300 Acc1/Acc2 aggregate counts must not change.
- **OA300 is primary, GiantSteps is secondary refactor.** The epic AC targets `OA300BenchmarkTests` explicitly (see `epics.md:449-458`); GiantSteps already has a crude `benchmarkByGenre` test that double-analyzes every track and ignores both ACs from this story. Unifying both suites on a shared reporter is in-scope so the two corpora produce comparable output and so the redundant analysis pass in GiantSteps is removed as a side effect.
- **Thresholds are story-level policy constants, not runtime knobs.** `minSampleSize = 5` (from epic AC #1) and `significantRegressionPercentagePoints = 10.0` (absolute delta against aggregate Acc1; chosen as the smallest round value that clears `n≈10` per-bucket noise — see Dev Notes). Both are `public static let` on the reporter type so a future story that wants a different policy has a single edit site, but changing them is an explicit decision, not a per-invocation parameter.
- **Duplicate `.wav`/`.mp3` fixture rows remain out of scope.** Story 2-4's review flagged that some OA300 filenames (e.g., `5. Darkgray Heart_Beating Heart Of The Summer Sun (robbyt Remix)`) appear as separate `.wav` and `.mp3` rows — each will count twice in the genre bucket. This is a pre-existing corpus data-quality issue (`deferred-work.md:100`), not introduced by stratification. Flagging it in the report would be scope creep; de-duplicating the fixture is a separate data-quality story. Completion Notes should call out any genre-count that appears ~2× larger than Story 2-4's histogram (67/10/2/1/1/1) as a data-quality follow-up signal — not a bug in this story.
- **`BoomBoomBoomKitTestSupport` public symbols are consumer-observable but not SemVer-stable.** The target is a regular `.target` (not `.testTarget`), so every `public` symbol this story ships becomes part of the package's compiled surface for downstream packages. The package has no SemVer contract yet; rename-compatibility is best-effort, and breaking changes land in story-level commits with no deprecation window. Pick `GenreBucket` / `GenreAccuracyReporter` names that you are willing to live with — the cost of renaming them later is non-zero.

## Acceptance Criteria

1. **Given** a new shared reporter file `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift`,
   **When** this story lands,
   **Then** it declares a `public enum GenreAccuracyReporter` (caseless namespace, same pattern as `MelFilterbank`) and a `public struct GenreBucket: Sendable` with stored fields `genre: String`, `total: Int`, `acc1Correct: Int`, `acc2Correct: Int` and computed accessors `acc1Percent: Double`, `acc2Percent: Double` (both returning `0` for `total == 0`) and `isInsufficient: Bool` (true when `total < GenreAccuracyReporter.minSampleSize`).
   **And** the namespace exposes `public static let minSampleSize: Int = 5` and `public static let significantRegressionPercentagePoints: Double = 10.0` as the two policy constants described in the Scope Notes.
   **And** the namespace exposes a `public static func format(corpusLabel:buckets:overallAcc1Percent:overallAcc2Percent:) -> String` that returns the full multi-line report (no `print` side effect — the caller prints the returned string). `buckets` is `[GenreBucket]`.
   **And** the namespace exposes `public static func isSignificantlyLower(bucketAcc1Percent:overallAcc1Percent:) -> Bool` returning `overallAcc1Percent - bucketAcc1Percent >= significantRegressionPercentagePoints` (absolute percentage-point delta; bucket below aggregate by the threshold or more → true). This is the test hook for AC #6.
   **And** all types/functions are `Sendable`-safe (value semantics, no captured state) and documented with `///` comments. `BoomBoomBoomKitTestSupport` remains a regular `.target` with no additional dependencies — no new imports beyond `Foundation`.
   **And** the `///` doc comment on `significantRegressionPercentagePoints` carries a one-sentence pointer to this story's Dev Notes rationale (so a future dev reading the constant in source sees the `why` without archaeology through `_bmad-output/`). Example: `/// Absolute percentage-point delta threshold for flagging a bucket as significantly underperforming. See story 2-5 Dev Notes for rationale (interpretability, noise robustness, round-number discoverability).`
   **And** `GenreBucket`'s initializer precondition-asserts `total >= 0 && acc1Correct >= 0 && acc2Correct >= 0 && acc1Correct <= total && acc2Correct <= total` (programmer-error guards via `precondition(...)` — catches caller bugs at test time, matches Story 2-4's loud-fail bar).
   **And** `format(...)` precondition-asserts `overallAcc1Percent` and `overallAcc2Percent` are finite and in `0...100` (`!percent.isNaN && !percent.isInfinite && (0...100).contains(percent)`). `NaN` / negative / >100 inputs are caller bugs, not runtime data.

2. **Given** the `format(corpusLabel:buckets:overallAcc1Percent:overallAcc2Percent:)` output,
   **When** called with any non-empty `buckets` array,
   **Then** the returned string has exactly these sections in order, terminated by a single trailing newline:
   - A header line: `=== <corpusLabel> Genre-Stratified Accuracy (Intensity 7) ===`
   - A column header: `Genre<padded-to-20>  Acc1   Acc2  Count  Status`
   - A horizontal rule of `-` characters matching the column-header width
   - One row per bucket, **sorted via an explicit two-key comparator** (NOT a post-hoc stable-sort — Swift's `sort(by:)` / `sorted(by:)` are not guaranteed stable): `sorted { $0.total > $1.total || ($0.total == $1.total && $0.genre < $1.genre) }`. Largest buckets first; ties broken by lexicographic ASCII on `genre`. For buckets with `total >= minSampleSize`, format is `<genre padded to 20>  <Acc1 cell>  <Acc2 cell>  <count cell>  <status>` where (a) the Acc1 and Acc2 cells are each `String(format: "%5.1f%%", percent)` (6 chars: right-aligned, always `" 0.0%"` to `"100.0%"`), (b) the count cell is `String(format: "%3d", total)` (3 chars right-aligned), (c) `<status>` is `** LOW **` when `isSignificantlyLower` is true against `overallAcc1Percent`, otherwise the empty string. Every rendered line has no trailing whitespace — strip each line's right edge before joining with `\n`.
   - For `isInsufficient` buckets (`total < 5`), the numeric Acc1/Acc2 cells are replaced by the literal string `insufficient` **left-justified in a 14-character field** (6 Acc1 + 2 separator + 6 Acc2 = 14; i.e., `"insufficient  "` with two trailing spaces before the count cell). The `<status>` column is the empty string — insufficient rows never participate in `** LOW **` flagging.
   - A trailing summary line: `Overall: Acc1=<XX.X>%, Acc2=<XX.X>%` followed by a newline. The `XX.X` here is `String(format: "%.1f", percent)` — variable-width, not padded (it's the final line; no column to align).
   **And** the `total == 0` edge case (empty `buckets` input) is handled by returning just the header + column header + rule + Overall line (no data rows). No crash, no "division by zero" footgun — `GenreBucket.acc1Percent` already guards `total > 0`.

3. **Given** `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift`,
   **When** this story lands,
   **Then** a new `@Test("genre-stratified accuracy")` method `benchmarkByGenre()` is added (alongside the existing `benchmarkDefaultIntensity`, `benchmarkAcc1Strict`, etc.) that runs a single `runBenchmark(intensity: .default, tolerance: 0.02)` pass, builds a `[GenreBucket]` by grouping the per-track outcomes on `track.genre`, and prints `GenreAccuracyReporter.format(corpusLabel: "OA300", buckets: buckets, overallAcc1Percent: metrics.acc1, overallAcc2Percent: metrics.acc2)` to stdout.
   **And** the method does NOT run any second `runBenchmarkDetailed` pass — it uses only the per-track results already computed by `runBenchmark`. This requires changing `runBenchmark` to additionally surface per-track outcomes (see AC #4). The analysis is performed exactly once per invocation of the stratified test.
   **And** the 5-bucket-below-threshold reality (`techno: 2`, `half-time-dnb: 1`, `tech-house: 1`, `footwork: 1`) renders as four `insufficient` rows; the two above-threshold buckets (`drum-and-bass: 67`, `breaks: 10`) render as percentage rows.
   **And** the aggregate `Acc1=69.5%` / `Acc2=89.0%` on the footer matches `make benchmark` output for the default-intensity test (no regression — stratification is pure reporting; the per-track results are the same ones `benchmarkDefaultIntensity` already computes).

4. **Given** the existing `runBenchmark(intensity:mergeStrategy:tolerance:)` private helper in `OA300BenchmarkTests.swift:283-343`,
   **When** this story lands,
   **Then** its return type changes from `AccuracyMetrics` to a tuple `(metrics: AccuracyMetrics, perTrack: [(track: OA300Track, detected: Double?)])` (or an equivalent named struct if the tuple feels clumsy at call sites — pick the shape that reads cleanly). The four existing callers (`benchmarkDefaultIntensity`, `benchmarkAcc1Strict`, `benchmarkAcc1MIREX`, `benchmarkMultiIntensity`) are updated to destructure and discard the `perTrack` array; the new `benchmarkByGenre` is the only consumer.
   **And** no track is analyzed twice in the stratified path — `perTrack` is populated inside the same `withTaskGroup` that populates `trackBPMs`.
   **And** the three existing tests' output is byte-identical to pre-story output (the print blocks did not depend on `perTrack` shape).

5. **Given** `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift`,
   **When** this story lands,
   **Then** the existing `benchmarkByGenre` test (lines 131-176 at HEAD) is rewritten to use `GenreAccuracyReporter.format(...)` instead of its bespoke print block, AND the double-analysis bug is fixed: the current implementation calls both `runBenchmark(...)` AND `runBenchmarkDetailed(...)`, analyzing every one of the 661 tracks twice. Post-story, there is a single analysis pass, same refactor pattern as AC #4.
   **And** the GiantSteps stratified test continues to use MIREX Acc1 semantics (with `tempo2` fallback via `track.tempo2.map { isAcc1Match(...) }`) — this is GiantSteps-specific and lives inside `runBenchmark`, not in the reporter. The shared reporter only formats `[GenreBucket]`; it does not compute matches.
   **And** `runBenchmarkDetailed` is deleted from the file in the same edit — post-refactor it has zero callers.
   **And** per-story commit, a re-run of `make benchmark-giantsteps` produces the same aggregate `Acc1=81.1%, Acc2=82.5%` and the same set of per-genre counts (now rendered via the shared reporter format; percentages are unchanged because the match logic is unchanged).

6. **Given** a new unit test file `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift`,
   **When** this story lands,
   **Then** it adds Swift Testing cases that cover the reporter's behavior with no corpus dependency (runnable via plain `make test`, no `OA300_CORPUS_PATH` needed):
   - `bucketAccessorsHandleZeroTotal` — a `GenreBucket(total: 0, ...)` returns `acc1Percent == 0`, `acc2Percent == 0`, and `isInsufficient == true`.
   - `isInsufficientAtAndBelowFiveTracks` — `total = 4` and `total = 5` are tested: 4 is `insufficient`, 5 is **not** (boundary is `total < 5`, matching `minSampleSize = 5`).
   - `formatSortsBucketsByCountDescending` — given three buckets with totals 10, 20, 5 (distinct genres), the formatted output lists them in order 20, 10, 5.
   - `formatStableTieBreakOnGenreAscii` — given two buckets with the same `total`, the one with the lexicographically-smaller `genre` appears first.
   - `formatRendersInsufficientRows` — a bucket with `total = 2` renders with the literal `insufficient` string, NOT a percentage, and never gets the `** LOW **` marker even when its `acc1Correct = 0`.
   - `isSignificantlyLowerIsAbsolutePercentagePoints` — aggregate `80.0%`, bucket `69.9%` → returns `true`; aggregate `80.0%`, bucket `70.1%` → returns `false` (boundary is `>=`, matching the operator in `isSignificantlyLower`).
   - `formatMarksLowBucketsOnlyWhenSampleSizeIsSufficient` — aggregate `80.0%`, bucket with `total = 20, acc1Correct = 10` (50%, 30pp below) renders `** LOW **`; bucket with `total = 3, acc1Correct = 0` (would be 0%, 80pp below, but tiny) renders `insufficient` and NO `** LOW **` marker.
   - `formatEmptyBucketsProducesHeaderAndOverallOnly` — `buckets: []` returns the header + column header + rule + Overall line, no data rows, no crash.
   **And** all cases are standalone (no fixture loading, no audio analysis) so `make test` continues to run `<1s` as specified in the running-benchmarks SKILL.md reference table.

7. **Given** `make benchmark` (OA300), `make benchmark-giantsteps`, `make test`, `make oracle`, `make ablation`, and `make perf-benchmark`,
   **When** run after this story lands,
   **Then** all six pass with no aggregate Acc1/Acc2 regression. Expected numbers (from `running-benchmarks` SKILL.md reference table; story 2-4 Completion Notes confirms these were holding at commit `e58e60a`):
   - OA300 @ 2%: Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%)
   - GiantSteps @ 2%: Acc1 = 536/661 (81.1%), Acc2 = 545/661 (82.5%)
   - `make test`: unit-test count increases by exactly the number of new cases in `GenreAccuracyReporterTests.swift` (8 cases per AC #6). `make oracle` pre-existing DAWOracle failure (documented in story 2-4 Debug Log) remains unresolved and is NOT gated on by this story.
   **And** `make fmt` + `make lint` run clean on the new reporter file, new unit test file, and the two modified benchmark suites. Any lint-disable pragma is a red flag — fix the underlying code unless it conflicts with swift format's output.

8. **Given** `.claude/skills/running-benchmarks/SKILL.md`,
   **When** this story lands,
   **Then** a new sub-section "Genre-stratified output" is added under the "Make targets — pick the right one" table (or at the logical place per current skill structure), describing:
   - The new `@Test("genre-stratified accuracy")` methods now exist on both `OA300BenchmarkTests` and `GiantStepsBenchmarkTests`, printing one table to stdout per corpus.
   - The `insufficient` marker means `total < 5`, the `** LOW **` marker means bucket Acc1 is ≥10pp below the aggregate. Both thresholds live in `GenreAccuracyReporter.swift`.
   - The expected OA300 stratification at commit SHA (record the SHA in Completion Notes after the story commits): two above-threshold rows (`drum-and-bass` and `breaks`), four `insufficient` rows.
   - A jq-style note is NOT needed (the output is stdout-only; no JSON baseline is touched). If a future story persists stratified stats to JSON, that is where jq recipes go.

9. **Given** the Completion Notes section,
   **When** this story is moved to `review`,
   **Then** it includes:
   - Verbatim the stratified output printed by `make benchmark` for OA300 after the story lands (pasted between triple-backticks). Readers should be able to see exactly which rows flagged `** LOW **` and which flagged `insufficient` at the story's HEAD.
   - Verbatim the stratified output printed by `make benchmark-giantsteps` for GiantSteps (same treatment; confirms the shared reporter renders both corpora consistently).
   - The `make benchmark` aggregate Acc1/Acc2 counts (must match AC #7).
   - The `make benchmark-giantsteps` aggregate Acc1/Acc2 counts (must match AC #7).
   - Confirmation that `runBenchmarkDetailed` is removed from `GiantStepsBenchmarkTests.swift` and that every track is analyzed at most once per test invocation.
   - A one-line note of what the `** LOW **` flag fired on (if any) — this is the first actionable datum for Epic 3 technique tuning.
   - Confirmation that `Sources/BoomBoomBoomKit/` is unchanged in this story's diff (`git diff --stat main -- Sources/BoomBoomBoomKit/` shows zero files).
   - Confirmation that the stratified outputs pasted above are from the **final** `make benchmark` / `make benchmark-giantsteps` runs — i.e., no code was edited after those captures. Re-run if any file changed after the capture.
   - Explicit unit-test count delta: `make test` before this story = 149/149; after = 157/157 (or whatever the final count lands at — the 8 new cases in `GenreAccuracyReporterTests.swift` plus any consolidation via `@Test(arguments:)`). Recorded as `<before>/<before> → <after>/<after>, all green`.
   - Confirmation that `///` doc comments exist on all six public symbols: `GenreBucket`, `GenreAccuracyReporter`, `minSampleSize`, `significantRegressionPercentagePoints`, `format`, `isSignificantlyLower`. The `significantRegressionPercentagePoints` doc comment in particular must carry the Dev Notes pointer required by AC #1.

## Tasks / Subtasks

**Execution order:** Task 0 → 1 + 2 (parallel in *development*, but **must commit together** — the `runBenchmark` signature reshape in each file leaves the package un-buildable mid-reshape, so neither Task 1's nor Task 2's diff can land without the other) → 4 → 3 → 5. Task 0 (the reporter) is the gate: both benchmark-suite refactors depend on it existing. Task 3 (skill doc) moved to run *after* Task 4 because AC #8's "expected OA300 stratification" and AC #9's verbatim paste both need the actual stdout from Task 4.3 / 4.4 — writing Task 3 first produces a skill doc with placeholders that Task 5 then has to backfill.

- [x] **Task 0: Ship the shared reporter + unit tests** (AC: #1, #2, #6)
  - [x] 0.1 Create `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift`. Contents:
    - `public struct GenreBucket: Sendable` with fields per AC #1 and computed accessors.
    - `public enum GenreAccuracyReporter` namespace with `minSampleSize`, `significantRegressionPercentagePoints`, `isSignificantlyLower`, and `format` per AC #1 and AC #2.
    - Doc comments on every public member explaining contract + defaults. Reference the policy rationale in Dev Notes below rather than repeating it in the doc comment.
  - [x] 0.2 Run `swift build` — expect clean. `BoomBoomBoomKitTestSupport` grows one file; no new imports beyond `Foundation`; no product/target edits needed in `Package.swift`.
  - [x] 0.3 Create `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` with the 8 cases listed in AC #6. Imports: `import Testing`, `import BoomBoomBoomKitTestSupport`. No `@testable import BoomBoomBoomKit` — the reporter is public in TestSupport and is the only type the tests need. For `bucketAccessorsHandleZeroTotal`, pass a concrete non-empty genre string (e.g., `"test-genre"`) to avoid colliding with any future blank-genre guard on `GenreBucket` — the test is about the `total == 0` math, not the genre field. Optional polish: Siri notes 3-5 of the 8 cases (the boundary and sort-order ones) are natural `@Test(arguments:)` candidates per WWDC24-10179; dev may consolidate if it reads cleaner, keeping the 8 logical assertions intact.
  - [x] 0.4 Run `make test` (no corpus env var required). All new cases pass; existing unit tests (149/149 green at HEAD post-2-4) stay green; total count becomes 157/157.

- [x] **Task 1: OA300 stratified test + `runBenchmark` reshape** (AC: #3, #4)
  - [x] 1.1 In `OA300BenchmarkTests.swift:283-343`, change `runBenchmark` return type from `AccuracyMetrics` to `(metrics: AccuracyMetrics, perTrack: [(track: OA300Track, detected: Double?)])`. Populated `perTrack` in the post-task-group aggregation loop — no second analysis pass.
  - [x] 1.1a Added `Sendable` conformance to `private struct AccuracyMetrics` defensively (matches the GiantSteps declaration).
  - [x] 1.2 Updated the four existing callers (`benchmarkDefaultIntensity`, `benchmarkAcc1Strict`, `benchmarkAcc1MIREX`, `benchmarkMultiIntensity`) to destructure via `let (metrics, _) = try await runBenchmark(...)`. No behavior change at these sites.
  - [x] 1.3 Added `@Test("genre-stratified accuracy") func benchmarkByGenre()` that calls `runBenchmark` once, groups `perTrack` by `track.genre` with Acc1/Acc2 tally, builds `[GenreBucket]`, and prints `GenreAccuracyReporter.format(corpusLabel: "OA300", ...)`.
  - [x] 1.4 `make benchmark` prints stratified table with the expected shape (2 percentage rows + 4 `insufficient` rows). Aggregate unchanged: Acc1=57/82 (69.5%), Acc2=73/82 (89.0%). `** LOW **` did NOT fire on OA300 — `breaks` at 60.0% is 9.5pp below the 69.5% aggregate, just under the 10pp threshold.

- [x] **Task 2: GiantSteps refactor** (AC: #5)
  - [x] 2.1 Applied the same `runBenchmark` return-type reshape to `GiantStepsBenchmarkTests.swift`, including `perTrack: [(track: GiantStepsTrack, detected: Double?)]`.
  - [x] 2.2 Rewrote `benchmarkByGenre` to drop the bespoke print block and the second `runBenchmarkDetailed` call. Match logic is a verbatim copy of `runBenchmark`'s MIREX Acc1/Acc2-with-`tempo2`-fallback — keeping per-track tuple shape identical to OA300.
  - [x] 2.3 Deleted `runBenchmarkDetailed` — zero callers after Task 2.2.
  - [x] 2.4 Updated the three other callers to destructure `(metrics, _)`. Aggregate output format unchanged.
  - [x] 2.5 `make benchmark-giantsteps` confirms aggregate Acc1=536/661 (81.1%), Acc2=545/661 (82.5%). Per-genre counts match pre-story breakdown. Stratified output captured for Completion Notes.

- [x] **Task 3: Skill documentation** (AC: #8)
  - [x] 3.1 Edited `.claude/skills/running-benchmarks/SKILL.md` with a "Genre-stratified output" section placed before "perf-benchmark JSON schema (v2)". Two paragraphs, terse. Also corrected the stale `143/143` reference count to `157/157` in the Make targets table.
  - [x] 3.2 Story SHA backfill: skill doc references "Story 2-5" by name rather than SHA (the SHA would require a follow-up commit and this story is a pure additions/reporting change — the doc points at the story file via its canonical name, which is stable).

- [x] **Task 4: Validation sweep** (AC: #7)
  - [x] 4.1 `make fmt` ran clean; `make lint` reports only the pre-existing `LUFSAnalyzer.swift:94` TODO (1 violation, 0 serious).
  - [x] 4.2 `make test` — 157/157 green (149 pre-story + 8 new cases).
  - [x] 4.3 `make benchmark` — Acc1 57/82, Acc2 73/82. Stratified output captured.
  - [x] 4.4 `make benchmark-giantsteps` — Acc1 536/661, Acc2 545/661. Stratified output captured.
  - [x] 4.5 `make ablation` — passed unchanged.
  - [x] 4.6 `make perf-benchmark` — passed unchanged; appended a record to `Apple_M5_Max-26.json`. Mean 0.216s (+1.7% vs prior baseline, within run-to-run variance).
  - [x] 4.7 `make oracle` — pre-existing `DecodingError.keyNotFound: daw_bpm` failure, unchanged. Not gated by this story.

- [x] **Task 5: Completion Notes + status flip** (AC: #9)
  - [x] 5.1 Verbatim stratified outputs from Tasks 1.4 and 2.5 pasted below between triple-backticks.
  - [x] 5.2 Aggregate Acc1/Acc2 counts recorded.
  - [x] 5.3 GiantSteps `** LOW **` genres noted as forward-signal for Epic 3 DSP tuning.
  - [x] 5.4 `git diff --stat e58e60a -- Sources/BoomBoomBoomKit/` shows zero files changed (pre-story SHA, since branch `rterhaar/epic-2` has prior-story library edits against `main`).
  - [x] 5.5 `make test` count recorded: `149/149 → 157/157 green`. All six public symbols have `///` doc comments.
  - [x] 5.6 TestSupport-growth line-item appended to `_bmad-output/implementation-artifacts/deferred-work.md`.
  - [x] 5.7 Status flipped to `review` in story file and sprint-status.yaml; `last_updated` bumped to 2026-04-19.

### Review Findings

Adversarial review run 2026-04-19 (Blind Hunter + Edge Case Hunter + Acceptance Auditor, parallel layers; 20 dismissed as noise/false-positive/unreachable).

**Decision needed (resolved 2026-04-19):**
- [x] [Review][Decision] Genre-cell width silently truncating → **Widened `genreCell` to 100 chars** (`columnHeader` + `renderRow`) and added `precondition(genre.count <= 100)` on `GenreBucket.init`. Belt-and-suspenders: 5× headroom over the current GiantSteps 20-char max plus a loud-fail guard if anything ever exceeds it.
- [x] [Review][Decision] `format(...)` hard-coded `(Intensity 7)` → **Added required `intensity: Int` parameter** to `format(...)`. Both benchmark callers pass `AnalysisIntensity.default.rawValue` (7), all eight `GenreAccuracyReporterTests` cases updated. Section header now interpolates the parameter.
- [x] [Review][Decision] GiantSteps MIREX match-logic duplication → **Extracted `private func mirexHit(track:detected:tolerance:) -> (acc1: Bool, acc2: Bool)`** alongside `runBenchmark`. Both `runBenchmark` and `benchmarkByGenre` call it; post-refactor aggregate Acc1/Acc2 is byte-equivalent (Acc1 = 536/661, Acc2 = 545/661 — confirmed via `make benchmark-giantsteps`).

**Patch (applied 2026-04-19):**
- [x] [Review][Patch] Added `precondition(acc1Correct <= acc2Correct, "acc1Correct must be <= acc2Correct (MIREX Acc2 supersets Acc1)")` on `GenreBucket.init`.
- [x] [Review][Patch] `SKILL.md` Make-targets reference-output cells for `make benchmark` and `make benchmark-giantsteps` now call out the per-corpus stratified stdout table alongside the aggregate Acc1/Acc2 line.

**Gemini review nitpicks folded in:**
- [x] [Review][Patch][Gemini] `countCell` widened `%3d` → `%4d` (headroom for ≥1000-track buckets; current corpora max ~139).
- [x] [Review][Patch][Gemini] Column-header alignment fixed: header string updated to `"    Acc1    Acc2  Count  Status"` and `countCell` widened `%4d` → `%5d` so header words right-align with their data columns.

**Deferred:**
- [x] [Review][Defer] AC #8 commit-SHA backfill in SKILL.md — spec literal says "record the SHA in Completion Notes after the story commits"; story is pre-commit, so the SHA substitution belongs in a post-commit follow-up edit. Task 3.2 acknowledged this tradeoff.
- [x] [Review][Defer] `GenreAccuracyReporterTests.swift` coverage expansion — no cases for ≥3-element tie-break, `overallAcc1Percent == 0.0` / `== 100.0` boundaries, or long / non-ASCII genre names. AC #6 did not require these; they are natural next-story polish.

## Dev Notes

### Why extract a shared reporter instead of duplicating the print block

Two corpora × two "per-genre report" implementations = four places a policy change (threshold, sort order, status markers) would need to edit, and the current single-implementation (GiantSteps only) already has drift potential:

- GiantSteps' `benchmarkByGenre` today prints a genre table with no `minSampleSize` threshold — it happily reports `breaks: 100% (1/1)` as a real datum, which the epic AC explicitly rejects.
- GiantSteps' `benchmarkByGenre` today also prints a "significantly lower" highlight nowhere — the epic AC requires it.
- GiantSteps' `benchmarkByGenre` today double-analyzes every track (see lines 133-134 calling both `runBenchmark` AND `runBenchmarkDetailed`).

All three of those are already wrong on GiantSteps; landing a second wrong-in-the-same-way implementation for OA300 would double the debt. The shared reporter forces both corpora onto the same rails.

### Why `minSampleSize = 5`

Directly quoted from epic AC (`epics.md:454`): "genres with fewer than 5 tracks are noted as 'insufficient sample' rather than reported as percentages." This is a spec value, not a design decision open for revision inside this story. Change-the-threshold stories would revisit in a later planning cycle if OA300 or GiantSteps grow (unlikely for OA300 — Story 2-4 explicitly ended corpus expansion).

### Why `significantRegressionPercentagePoints = 10.0` (absolute, not relative)

The epic AC says "significantly lower" without a number. Absolute percentage points (not percent-of-aggregate, not z-score) is the right shape because:

1. **Interpretable without aggregate context.** A reader who sees "`drum-and-bass: 65% acc1`" and "`breaks: 40% acc1`" does not need to compute a ratio to know `breaks` is underperforming. The delta is self-evident in percentage points.
2. **Robust to small buckets.** Relative thresholds (e.g., "below 80% of aggregate") over-flag near-zero aggregates and under-flag near-100% aggregates. Absolute deltas behave consistently across the full 0-100% range.
3. **Resilient to sample-size noise at the lower end.** For `n = 10` (breaks bucket at OA300 post-2-4), a single track flip moves the percentage by 10pp. Setting the threshold at 10pp means we flag only when the bucket is ≥1 full track worse than the aggregate would predict — a meaningful signal, not noise. For the larger `drum-and-bass: 67` bucket, 10pp = ~7 tracks, well above the sampling stddev.
4. **Round-number discoverability.** Future readers of the source will immediately grok "10 points" as a hand-picked threshold meant to be revisited; a number like `7.3` or `0.85` would leave them hunting for an origin story.

### Why OA300's four tiny buckets are *intentionally* flagged `insufficient`

Story 2-4 made an explicit taxonomy choice to seed `footwork` and `half-time-dnb` as OA300-only genre extensions (sanctioned extensions per AC #2 of that story), knowing those buckets would be single-track. That is a corpus-honesty signal, not a measurement signal: those buckets exist in the taxonomy because the *tracks* are rhythmically distinct, not because there is a statistically meaningful per-genre accuracy number to report. The `insufficient` marker is the honest output — not a bug to paper over by retagging them as `drum-and-bass` or `breaks`.

Story 2.5's value for OA300 is therefore concentrated on the two larger buckets — `drum-and-bass: 67` and `breaks: 10`. Any accuracy gap between those two is the first-useful signal this story produces for Epic 3 technique tuning.

### Data expectations at story start (2026-04-18, commit `e58e60a`)

Per Story 2-4 Completion Notes (`2-4-oa300-corpus-expansion-with-genre-diversity.md:279, 280`):

- OA300 genre histogram: `drum-and-bass: 67, breaks: 10, techno: 2, tech-house: 1, footwork: 1, half-time-dnb: 1` (82 total).
- OA300 aggregate Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%) at intensity 7, `maxConfidence` merge, `.optimal` preset.
- GiantSteps aggregate Acc1 = 536/661 (81.1%), Acc2 = 545/661 (82.5%).

Story 2-5 does not change any analysis code path. If Task 4.3 or 4.4 returns different aggregate numbers, investigate before declaring the story done — stratification is pure reporting and must be a no-op on counts.

### Why `runBenchmark` returning both `metrics` and `perTrack`

The current OA300 `runBenchmark` computes per-track results in its task group then throws the per-track array away, returning only the aggregated `AccuracyMetrics`. The stratified test needs both. The alternatives:

1. **Second full analysis pass** (what GiantSteps does today): Double the wall time. Rejected per AC #3.
2. **Extract per-track from `metrics.failures`**: `failures` only contains non-Acc1-matches, missing the `.drum-and-bass` tracks that passed — wrong shape.
3. **Return a tuple `(metrics, perTrack)`**: Minimal diff, matches the tuple-return idiom already used for `TrackAudio` in `benchmarkMergeStrategies`, no new types. Chosen.
4. **New `BenchmarkResult` struct**: Better ergonomics if more fields are added later. Overkill for two fields today; revisit when a third callsite needs shared shape.

The tuple approach keeps the edit local: the four existing callers each gain one `, _ =` destructure and otherwise stay identical.

### Why GiantSteps refactor is in-scope (despite being "secondary")

The GiantSteps stratified test today is partially-incorrect (missing both epic ACs) and performs a redundant full-corpus analysis pass. Fixing that in this story means:

- Story 2-5 ships a single consistent report format across both corpora. A future reader (human or LLM dev) reading the stratified output for either OA300 or GiantSteps sees the same columns, same markers, same sort order.
- The `runBenchmarkDetailed` helper is deleted from the codebase — no cruft remaining.
- Wall time for `make benchmark-giantsteps` drops by approximately half (the stratified test is the worst offender for GiantSteps' 2-minute-ish runtime).

Splitting this into a follow-up story would be ceremony without benefit; the refactor touches two lines of acceptance criteria and one file other than OA300.

### Forward hazards (read before opening an editor)

Two quiet failure modes that will not surface in a green `make test` but will bite at review time:

- **Sort stability.** AC #2 mandates a descending-by-`total` sort with `genre` ASCII tie-break. Swift's `sort(by:)` and `sorted(by:)` are **not guaranteed stable** (documented at https://developer.apple.com/documentation/swift/array/sort(by:) — "When sorted, the elements of this collection are rearranged in a stable order" is specifically NOT promised; the docs are explicit about this). Using a post-hoc single-key sort (`sorted { $0.total > $1.total }`) will leave ties in undefined order — the test order will drift between compiler versions, Swift toolchain updates, or even between runs on different architectures. Use the explicit two-key comparator mandated by AC #2: `sorted { $0.total > $1.total || ($0.total == $1.total && $0.genre < $1.genre) }`. Do not rely on input-order preservation or a supposedly-stable single-key sort.

- **Column formatting width.** AC #2's `"XX.X%"` is a semantic template, not a format spec. `String(format: "%.1f%%", 9.9)` produces `"9.9%"` (4 chars). Use `String(format: "%5.1f%%", ...)` for consistent right-alignment across the `0.0%`-to-`100.0%` range (5 digits + `%` = 6 chars; `"  9.9%"`, `" 69.5%"`, `"100.0%"`). Same principle for the count cell: `String(format: "%3d", total)` right-aligns `  1`, ` 10`, `661`. The `insufficient` literal for tiny buckets is left-justified in a 14-character field (the combined Acc1-cell + 2-space-separator + Acc2-cell width).

- **`benchmarkByGenre` freshness.** If Task 4.3 / 4.4 prints output, then dev edits something, the pasted Completion Notes output is stale. AC #9 now requires that pasted output be from the final post-edit run. The test execution is cheap — re-run if anything changed.

### TestSupport growth — deferred work flag (not in story scope)

After this story, `Sources/BoomBoomBoomKitTestSupport/` holds 5 public helper files: `AccuracyMatchers`, `CorpusTracks`, `AudioFixtures`, `TestSignalGenerators`, + the new `GenreAccuracyReporter`. Five is the threshold where a table-of-contents or subdirectory split starts to pay off; at 7+ a README explaining the public-surface contract becomes table stakes. **This story does not re-organize TestSupport** — but a line-item should be added to `_bmad-output/implementation-artifacts/deferred-work.md` along the lines of *"`BoomBoomBoomKitTestSupport` reaches 5 public helpers after Story 2-5; revisit organization (subdirectories, README, public-API/SemVer contract) when count exceeds 7."* Adding that deferred-work entry is a Task 5 side effect, not a separate task.

### File placement (canonical)

- Shared reporter: `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift` (alongside `AccuracyMatchers.swift`, `CorpusTracks.swift`, `AudioFixtures.swift`, `TestSignalGenerators.swift`). Rationale: this is test-infrastructure shared by consuming packages (Story 2.4 Dev Notes confirm `BoomBoomBoomKitTestSupport` is the right home for shared fixtures and helpers).
- Unit tests for the reporter: `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift` (the non-benchmark unit test target — no corpus env var required).
- Consumer tests: `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` and `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` (both in the benchmark target — env-gated as usual).
- Skill doc: `.claude/skills/running-benchmarks/SKILL.md` (already the reference for benchmark operations).

### Project Structure Notes

- Files touched: one new Swift file (reporter), one new Swift test file (reporter unit tests), two modified Swift test files (OA300 + GiantSteps benchmark suites), one modified skill doc, this story file, sprint-status.yaml. No Makefile edits. Zero `Sources/BoomBoomBoomKit/` edits.
- **ADR-9 preserved: shared formatter, NOT shared suite.** The shared reporter is a pure `[GenreBucket] → String` function. Each suite keeps its own env-var gate, its own ground-truth loader, its own `@Suite` declaration, its own match logic (GiantSteps uses MIREX Acc1/Acc2 with `tempo2` fallback; OA300 uses the simpler two-arg match). The reporter does not compute matches and does not know which corpus it is rendering — `corpusLabel` is just a string in the header. This is the *good* kind of coupling (formatter reuse), not the *bad* kind (suite fusion). ADR-10 (dual-tolerance as separate test methods) is similarly untouched — no existing method merges or splits.
- No PRD impact beyond the direct FR tie: FR33 ("Genre-stratified accuracy reporting is available once the corpus has sufficient genre diversity") — delivered by this story. The "sufficient genre diversity" half comes from GiantSteps' 23-label corpus (Story 2.1) combined with OA300's post-2-4 multi-label fixture.
- No perf-baseline regression expected. `PerformanceBenchmarkTests` does not touch genre and does not use the shared reporter.
- `ALLOWED_GENRES` in `convert-rekordbox-export.py` (Story 2-4's canonical-list location) is NOT edited by this story. The reporter operates on whatever genre strings are on the fixture — no re-validation against `ALLOWED_GENRES` here. That validation is Story 2-4's `fixtureGenresAreWithinAllowedTaxonomy` unit test in `CorpusTracksDecodingTests.swift` and stays there.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5] (the spec — AC text reproduced above)
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4] (upstream contract — delivers non-optional `genre` on `OA300Track` and the taxonomy)
- [Source: _bmad-output/planning-artifacts/prd.md#FR33] (genre-stratified reporting FR)
- [Source: _bmad-output/planning-artifacts/architecture.md#ADR-9] (GiantSteps as separate suite — informs why both suites keep their own stratified test)
- [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:20-48] (shared `OA300Track` with non-optional `genre: String`; the contract this story reads)
- [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:59-67] (shared `GiantStepsTrack` with non-optional `genre: String`)
- [Source: Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift] (`isAcc1Match`/`isAcc2Match` — the matchers the stratified tests call; MIREX 5-factor Acc2)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift:283-343] (current `runBenchmark` shape — reshaped by Task 1.1)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift:131-176] (current `benchmarkByGenre` — rewritten by Task 2.2)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift:251-280] (current `runBenchmarkDetailed` — deleted by Task 2.3)
- [Source: _bmad-output/implementation-artifacts/2-4-oa300-corpus-expansion-with-genre-diversity.md] (genre taxonomy + fixture history; final histogram at line 279)
- [Source: _bmad-output/implementation-artifacts/deferred-work.md:100] (duplicate `.wav`/`.mp3` rows — explicitly out of scope for this story)
- [Source: .claude/skills/running-benchmarks/SKILL.md] (reference counts + make-target table — updated by Task 3.1)
- [Source: _bmad-output/project-context.md#Options-struct-pattern] (Options-struct rule — not directly applicable here since the reporter has no Options, but pattern followed for future-proofing)

### Previous-story intelligence

Story 2-4 (`2-4-oa300-corpus-expansion-with-genre-diversity.md`) landed the genre contract this story consumes. Key carry-forward items:

- `OA300Track.genre` is now non-optional `String` with a decoder that throws on blank/whitespace values. Story 2-5 reads this field without any nil handling.
- The genre taxonomy is **extensible**, not frozen. Story 2-4 explicitly did not add runtime validation against `ALLOWED_GENRES` in Swift, so the reporter must handle arbitrary genre strings without guarding. If a future corpus refresh introduces a new label, the stratified report picks it up for free (as a new row), flagged `insufficient` if `n < 5`, `** LOW **` if accuracy warrants.
- Story 2-4 Completion Notes record the histogram snapshot used throughout this story's AC text (67/10/2/1/1/1 across `drum-and-bass/breaks/techno/tech-house/footwork/half-time-dnb`). Any drift from that by the time this story executes is a fixture corruption signal — investigate rather than adjust the AC numbers.
- Story 2-4 also shipped the `CorpusTracksDecodingTests` file with a `fixtureGenresAreWithinAllowedTaxonomy` test that reads the real OA300 fixture. Story 2-5 does NOT need to re-run that validation; the invariant is already under test.

Story 2-3 (`2-3-performance-benchmark-infrastructure.md`) established the `PerformanceBenchmarkTests` suite which also consumes `OA300Track` via the shared decoder. Story 2-5's changes are pure additions to `OA300BenchmarkTests` and `GiantStepsBenchmarkTests`; the Performance suite is untouched.

Story 2-1 (`2-1-giantsteps-tempo-dataset-integration.md`) introduced `GiantStepsBenchmarkTests` with the existing `benchmarkByGenre` test. That test's double-analysis-pass bug was noted in that story's deferred-findings block ("duplicated acc1/acc2 logic" — see `deferred-work.md:54, 60`). Story 2-5 fixes the duplication; do not re-log the finding, as it is closed by Task 2.

Story 2-6 (`2-6-perf-baselines-file-per-run-redesign.md`, `ready-for-dev` as of 2026-04-18) is orthogonal to this story. The two can ship in either order. If 2-6 lands first, `make perf-benchmark` writes per-run JSON files; if 2-5 lands first, it appends to the legacy array file. Either behavior is acceptable because Story 2-5 does not edit `PerformanceBenchmarkTests` at all.

### Git intelligence (recent commits on `rterhaar/epic-2`)

- `e58e60a` Story 2-4: OA300 genre labeling (GiantSteps-aligned)
- `d224cb7` Story 2-3: Fourth-pass review resolution (review → done)
- `6e39893` Story 2-3: Performance benchmark infrastructure with delta-vs-last-baseline reporting
- `a97bad2` Story 2-2: Dual-tolerance accuracy reporting and MIREX-compliant Acc2 unification
- `eefdb1f` Story 2-1: GiantSteps dual-tempo integration and MIREX-compliant Acc2

Commit message for this story should follow the existing pattern: `Story 2-5: Genre-stratified accuracy reporting`. Single commit unless the skill-doc SHA backfill (Task 3.2) requires two.

### Out of scope

- Library (`Sources/BoomBoomBoomKit/`) edits. Public API surface is unchanged by this story.
- De-duplicating `.wav`/`.mp3` fixture rows (`deferred-work.md:100`). Separate data-quality story.
- Persisting stratified stats to JSON. If a future story wants programmatic access (e.g., for a dashboard or CI regression gate), extend the `PerformanceBenchmarkTests` baseline schema — don't duplicate it here.
- Changing the thresholds (`minSampleSize`, `significantRegressionPercentagePoints`). Either constant is editable in one spot; edits are a design decision for a follow-up.
- Fixing the pre-existing `make oracle` DAWOracle `DecodingError.keyNotFound: daw_bpm` failure (documented in Story 2-4 Debug Log, `2-4-oa300-corpus-expansion-with-genre-diversity.md:269`). Separate story.
- Adding a `@Generable` / Foundation Models / ML interpretation of the stratified output. Epic 4 territory.
- Any change to intensity mapping, merge strategy behavior, or DSP technique code paths.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (story context engine)

### Debug Log References

- **Party-mode review applied 2026-04-19.** Four BMAD agents (Amelia/dev, Winston/architect, Siri/Apple-docs, Bob/SM) reviewed the draft and converged on 12 high-confidence edits. Applied inline:
  1. Fixed GiantSteps `runBenchmark` line range (`283-343` → `186-249`) — file is only 286 lines; the prior range was a drafting error (Amelia).
  2. Re-worded Task 1.1 to "post-task-group aggregation loop" (Amelia).
  3. Added Task 1.1a to make OA300 `AccuracyMetrics` `Sendable` if Swift 6 flags the new tuple return (Amelia).
  4. Made `insufficient` padding width explicit as 14 chars and spelled out `%5.1f%%` / `%3d` format specs (Amelia, Bob).
  5. Added sort-stability Forward Hazard with explicit two-key comparator (Bob).
  6. Added Task 1/2 "must commit together" constraint and re-ordered execution to `0 → 1+2 → 4 → 3 → 5` (Bob, Amelia).
  7. Restructured Task 2 to keep `perTrack` inner-tuple shape identical across corpora with MIREX-match logic repeated verbatim inside `benchmarkByGenre` (drift risk contained to one file).
  8. Added `///` doc-comment pointer requirement on `significantRegressionPercentagePoints` (Winston).
  9. Expanded "No ADR impact" note with ADR-9 preservation reasoning (Winston).
  10. Added TestSupport SemVer-disclaimer Scope Note + TestSupport-growth deferred-work entry (Winston).
  11. Added AC #9 freshness requirement + unit-test count delta + doc-comment checklist (Bob).
  12. Added `GenreBucket` + `format()` precondition asserts to match Story 2-4's loud-fail bar (Bob).
- Non-blocking optional polish left to dev-time judgment: tuple→named-struct (Winston + Siri soft-prefer struct; AC #4 already provides escape hatch), parameterized tests via `@Test(arguments:)` (Siri cites WWDC24-10179 as canonical pattern), `FormatStyle` with `Locale(identifier: "en_US_POSIX")` (Siri; story's `String(format:)` is conservatively POSIX).

### Completion Notes List

**Landed:** 2026-04-19 on branch `rterhaar/epic-2` (pre-commit).

**OA300 stratified output** (`make benchmark`, refreshed post-Gemini-review 2026-04-19 — 100-char genre width, `%5d` count cell, right-aligned column headers, `intensity: 7` interpolated):

```
=== OA300 Genre-Stratified Accuracy (Intensity 7) ===
Genre                                                                                                     Acc1    Acc2  Count  Status
-------------------------------------------------------------------------------------------------------------------------------------
drum-and-bass                                                                                             70.1%   89.6%    67
breaks                                                                                                    60.0%   90.0%    10
techno                                                                                                  insufficient        2
footwork                                                                                                insufficient        1
half-time-dnb                                                                                           insufficient        1
tech-house                                                                                              insufficient        1
Overall: Acc1=69.5%, Acc2=89.0%
```

**GiantSteps stratified output** (`make benchmark-giantsteps`, refreshed post-Gemini-review 2026-04-19):

```
=== GiantSteps Genre-Stratified Accuracy (Intensity 7) ===
Genre                                                                                                     Acc1    Acc2  Count  Status
-------------------------------------------------------------------------------------------------------------------------------------
drum-and-bass                                                                                             92.8%   94.2%   139
dubstep                                                                                                   76.3%   78.9%    76
trance                                                                                                    73.0%   74.3%    74
techno                                                                                                    83.6%   83.6%    61
electronica                                                                                               76.9%   76.9%    52
psy-trance                                                                                                91.2%   91.2%    34
breaks                                                                                                    80.8%   80.8%    26
deep-house                                                                                              100.0%  100.0%    24
house                                                                                                     52.2%   56.5%    23  ** LOW **
electro-house                                                                                             68.2%   68.2%    22  ** LOW **
tech-house                                                                                                86.4%   95.5%    22
progressive-house                                                                                         57.9%   57.9%    19  ** LOW **
glitch-hop                                                                                                76.5%   76.5%    17
chill-out                                                                                                 93.3%   93.3%    15
hardcore-hard-techno                                                                                      92.9%   92.9%    14
indie-dance-nu-disco                                                                                      81.8%   81.8%    11
dj-tools                                                                                                  12.5%   25.0%     8  ** LOW **
hard-dance                                                                                              100.0%  100.0%     8
minimal                                                                                                   87.5%   87.5%     8
pop-rock                                                                                                insufficient        3
hip-hop                                                                                                 insufficient        2
reggae-dub                                                                                              insufficient        2
funk-r-and-b                                                                                            insufficient        1
Overall: Acc1=81.1%, Acc2=82.5%
```

**Post-review changes (2026-04-19):** `GenreAccuracyReporter.format(intensity:)` now takes a required `intensity: Int`; `GenreBucket.init` asserts `acc1Correct <= acc2Correct` and `genre.count <= 100`; genre cell widened 20 → 100 chars, count cell widened `%3d` → `%5d` with right-aligned column headers; GiantSteps `mirexHit` helper extracted and shared between `runBenchmark` and `benchmarkByGenre`. Aggregate Acc1/Acc2 byte-equivalent on both corpora (OA300 69.5%/89.0%, GiantSteps 81.1%/82.5%).

**Aggregate Acc1/Acc2 counts (match AC #7):**

- OA300 @ 2%: Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%) — unchanged vs pre-story.
- GiantSteps @ 2%: Acc1 = 536/661 (81.1%), Acc2 = 545/661 (82.5%) — unchanged vs pre-story.

**`** LOW **` flags (forward-signal for Epic 3):**

- OA300: none fired. (`breaks` at 60.0% is 9.5pp below aggregate 69.5% — just under the 10pp threshold.)
- GiantSteps: four fired — `house` (52.2%, 28.9pp below), `electro-house` (68.2%, 12.9pp below), `progressive-house` (57.9%, 23.2pp below), `dj-tools` (12.5%, 68.6pp below). The cluster around `house`/`electro-house`/`progressive-house` is the first actionable pattern — a shared weakness on four-on-the-floor-but-not-quite-techno genres. `dj-tools` (8 tracks, atypical content) is a separate outlier.

**Analysis-pass confirmation:**

- `runBenchmarkDetailed` removed from `GiantStepsBenchmarkTests.swift` — zero callers remain.
- Every track is analyzed at most once per test invocation in both suites (grep confirms the single `withTaskGroup` call per `runBenchmark` invocation).

**Library invariant (AC #9):**

- `git diff --stat e58e60a -- Sources/BoomBoomBoomKit/` returns empty — zero library-file changes in this story's diff. (Used `e58e60a` as base because branch `rterhaar/epic-2` has prior-story library edits against `main`; Story 2-5 isolated.)

**Test count (AC #9):**

- `make test`: `149/149 → 157/157 all green`.
- The 8 new cases in `GenreAccuracyReporterTests.swift` cover AC #6's 8 enumerated scenarios (boundaries, sort order, tie-break, insufficient rendering, LOW gating, empty buckets).

**Doc-comment checklist (AC #9):**

- `GenreBucket` — ✅
- `GenreAccuracyReporter` (namespace) — ✅
- `minSampleSize` — ✅
- `significantRegressionPercentagePoints` — ✅ with Dev Notes pointer per AC #1 (`"See story 2-5 Dev Notes for rationale (interpretability, noise robustness, round-number discoverability)."`)
- `format(corpusLabel:buckets:overallAcc1Percent:overallAcc2Percent:)` — ✅
- `isSignificantlyLower(bucketAcc1Percent:overallAcc1Percent:)` — ✅

**Freshness (AC #9):** Both stratified outputs pasted above were captured from the final post-edit `make benchmark` / `make benchmark-giantsteps` runs. No file was modified after capture.

### File List

**New:**
- `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift`
- `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift`

**Modified:**
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` (runBenchmark reshape + benchmarkByGenre test + `Sendable` on AccuracyMetrics)
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` (runBenchmark reshape + benchmarkByGenre rewrite + runBenchmarkDetailed deletion)
- `.claude/skills/running-benchmarks/SKILL.md` (Genre-stratified output section + 143→157 count fix)
- `_bmad-output/implementation-artifacts/2-5-genre-stratified-accuracy-reporting.md` (status, tasks, completion notes, file list)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (2-5 → review; last_updated)
- `_bmad-output/implementation-artifacts/deferred-work.md` (TestSupport-growth entry)
- `_bmad-output/perf-baselines/Apple_M5_Max-26.json` (appended by `make perf-benchmark`)

**Zero files changed under `Sources/BoomBoomBoomKit/`.**

## Change Log

- 2026-04-19 — Story 2-5 implementation complete; status flipped `ready-for-dev` → `review`. Shared `GenreAccuracyReporter` added to TestSupport; OA300 + GiantSteps benchmark suites unified on the shared reporter; `runBenchmarkDetailed` deleted (double-analysis bug fixed); 8 new unit cases green; aggregates unchanged (OA300 69.5%/89.0%, GiantSteps 81.1%/82.5%).
- 2026-04-19 — Gemini final review passed; column-header alignment nitpick applied (`countCell` `%4d` → `%5d`, header spacing updated for right-aligned columns). Status flipped `review` → `done`.
