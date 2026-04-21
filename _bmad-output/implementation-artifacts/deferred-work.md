# Deferred Work

## Non-Octave BPM Disambiguation (3:2, 3:1 ratios)

**Deferred from:** Phase 3 batch planning (2026-03-26)
**Reason:** Split from multi-window candidate merging to keep specs single-goal

Add 3:2 and 3:1 ratio detection to `resolveOctaveAmbiguity` in `BPMAnalyzer.swift`. Currently only handles 2:1 octave pairs (ratio 1.92-2.08). Need to add:
- 3:2 ratio check (1.45-1.55 tolerance)
- 3:1 ratio check (2.85-3.15 tolerance)

Two known failing Prodigy tracks at triplet/2-3 time lock serve as validation targets. Sub-band voting mechanism already exists and can be reused for these ratios.

**Files:** `BPMAnalyzer.swift` (resolveOctaveAmbiguity, confirmWithSubBandPeaks)
**Validation:** Two Prodigy tracks + full OA300 benchmark regression check

## Confidence Semantics for Merge Strategies

**Deferred from:** Multi-window candidate merging code review (2026-03-26)
**Reason:** Design decision, not a bug -- revisit after ablation data

Currently all merge strategies report `max(confidence)` across all windows. For clustered strategies, the winning BPM may come from a low-confidence window while a high-confidence window contributed a different candidate. Consider per-cluster confidence (max confidence among windows contributing to the winning cluster) after ablation shows which strategy works best.

**Files:** `CandidateMergeStrategy.swift`

## Post-Disambiguation Merge Strategies

**Deferred from:** Merge strategy ablation (2026-03-27)
**Reason:** Ablation showed all clustering strategies hurt Acc1 vs maxConfidence

The 6 clustering-based merge strategies (dedup, quorum, average, median, weightedAverage, union) all perform worse than `maxConfidence` (59.8% vs 69.5% Acc1). Root cause: they merge raw candidates from `BPMResult.candidates` which are pre-disambiguation values. Each window's `BPMResult.bpm` has already been through sub-band voting and octave disambiguation, but the `.candidates` array contains the raw top-N peaks before that step.

To make merge strategies useful, they would need to operate on the *final disambiguated BPM* from each window rather than the raw candidates. This would mean:
1. Collect `(bpm: result.bpm, confidence: result.confidence)` from each window (post-disambiguation)
2. Cluster/vote on those final values
3. Return the winner

This is a fundamentally different approach from the current candidate-level merging.

**Files:** `CandidateMergeStrategy.swift`, `AudioAnalysisService.swift`
**Validation:** OA300 benchmark, targeting Acc1 > 69.5%

## Deferred from: code review of 1-1-internal-buffer-reuse-in-bpm-pipeline (2026-04-03)

- **F4: Unnecessary Array copy from PipelineBuffers.windowed** — Both `computeFourierTempogram` and `refineCandidates` copy `pb.windowed` into a new `[Float]` via `Array(UnsafeBufferPointer(...))`. The `vDSP_dotpr` calls could use the pointer directly, avoiding the heap allocation. Optimization for a future performance pass.
- **F5: Integer underflow in reserveCapacity** — `(samples.count - fftSize) / hopSize + 1` yields negative intermediate when `samples.count < fftSize`. No crash (reserveCapacity treats negative as 0), but intent unclear. Pre-existing.
- **F6: Windowed onset truncation** — Windowing always uses only the first `windowLength` elements of the onset envelope. Pre-existing behavior, not caused by buffer reuse changes.

## Deferred from: code review of 2-1-giantsteps-tempo-dataset-integration (2026-04-06)

- **Failure table expected field** — When a track is an Acc2-hit against `tempo2` only, the failure record stores `expected: track.bpm` rather than the matched `tempo2`. Cosmetic -- does not affect accuracy counts, only the failure table display.
- **isAcc2Match divergence** — GiantSteps `isAcc2Match` now includes {1,2,1/2,3,1/3} factors (MIREX-compliant) while OA300 and DAWOracle still use {1,2,1/2} only. Story 2-2 scope.
- **isAcc1Match division by zero** — `abs(detected - expected) / expected` divides by zero when `expected == 0`. Pre-existing across all 3 benchmark files. Current data excludes 0-BPM tracks, so not triggered.
- **Duplicated acc1/acc2 logic** — `runBenchmark` and `benchmarkByGenre` implement the same dual-tempo matching independently. Pre-existing pattern.

## Deferred from: code review of 2-2-dual-tolerance-accuracy-reporting (2026-04-13)

- **Division by zero in `isAcc1Match` when `expected == 0`** — All 3 benchmark files divide by `expected` with no guard. `classifyError` is the only caller that checks `expected > 0`. Spec notes as "Forward Hazard: Epic 2.4 Ground-Truth Validation." Pre-existing (also noted in Story 2-1 review).
- **Negative or zero tolerance not guarded** — No validation that `tolerance > 0` in `isAcc1Match`/`isAcc2Match`. Zero tolerance requires exact float equality; negative always returns false. No current call site passes bad values.
- **`benchmarkByGenre` calls `runBenchmark` but discards meaningful use of returned metrics** — Runs full corpus then recomputes genre-level stats from separate `runBenchmarkDetailed` run. Pre-existing pattern.

## Deferred from: code review of 2-3-performance-benchmark-infrastructure (2026-04-17)

- **Baseline file grows unbounded** — `BaselineStore.append` rewrites the full JSON array on every run. No rotation, pruning, or size cap. Daily CI runs produce multi-MB files within a year. `PerformanceBenchmarkTests.swift:206-218`.
- **Baseline path edge cases** — `PERF_BASELINE_DIR` is passed through `URL(fileURLWithPath:)` with no `~` expansion; `$(CURDIR)/_bmad-output/perf-baselines` in the Makefile may not match the committed repo path when benchmarks run from a `git worktree`. Environmental. `PerformanceBenchmarkTests.swift:582-584`, `Makefile:12`.
- **Fingerprint filename collisions** — Whitespace-differing chip brand strings (`"Apple M5 Max"` vs `"Apple  M5 Max"`) collapse to the same sanitized name; consecutive `_` are not collapsed; only major OS version is encoded so macOS 26.0/26.1/26.5 share one history file. `PerformanceBenchmarkTests.swift:182-192, 220-230`.
- **Hardware edge cases** — `physicalMemoryGiB` integer-truncates to 0 on sub-1-GiB systems; no cap on chip-string length (PATH_MAX on pathological VMs); non-ASCII/emoji chip names pass the Unicode-aware `isLetter`/`isNumber` sanitizer. Won't hit on macOS 15+ Mac hardware. `PerformanceBenchmarkTests.swift:117-119, 182-192`.
- **Virtualization edges** — `ContinuousClock` is documented monotonic but `Duration.components.seconds` can individually be negative; no `max(0, …)` guard. Paused/resumed VMs could surface this. `PerformanceBenchmarkTests.swift:417-420`.
- **Single-track corpus** — If only one track is available, it is labeled warmup, `okDurations` is empty, accuracy is computed but silently discarded, no baseline written. Dev-tooling edge. `PerformanceBenchmarkTests.swift:285-311`.
- **`recordedAt` second-precision + `Date()` non-monotonic** — ISO8601 output omits fractional seconds; two runs in the same second share a timestamp. `records.last` is positional, not chronological, so NTP-induced clock skew can make "last" not be "most recent wall-clock". `PerformanceBenchmarkTests.swift:543-547`.
- **Filesystem error reporting cluster** — Read-only baseline dir, existing-file-at-dir-path, and `.atomic` writes on Dropbox-synced volumes all get caught by `do { try append } catch { print("Warning:") }` and the test passes. Consider `Issue.record` so CI surfaces these. `PerformanceBenchmarkTests.swift:207-218, 609-613`.
- **`isAcc1Match` tolerance is asymmetric** — `abs(detected - expected) / expected` means a match at `detected = 2×expected` and a match at `expected = 2×detected` use different denominators. Matches OA300/DAWOracle suites intentionally; design choice. `PerformanceBenchmarkTests.swift:62-64`.
- **Diagnostic output via `print`** — Hardware header, per-track table, aggregate footer, and Δ line all go to stdout; Swift Testing captures stdout only via raw logs. `Issue.record` or test attachments would preserve output durably. `PerformanceBenchmarkTests.swift:329-395`.
- **`swift test --filter` is substring-match** — A future suite named `PerformanceBenchmarkTestsFoo` would be picked up by `make perf-benchmark`. Theoretical. `Makefile:16`.
- **Two committed records at same `gitSHA: "a97bad2"`** — Both initial records were generated locally at the same commit 53s apart; a future policy decision (CI-only producer vs local-canonical) determines whether this is an issue. `Apple_M5_Max-26.json:655,695`.
- **`GIT_SHA=unknown` silently degrades** — When run outside a git checkout, delta line prints `(SHA unknown, …)`. Working as designed per AC #4 + Dev Notes, but useless for comparing old records. `Makefile:14-15`, `PerformanceBenchmarkTests.swift:548`.
- **`sysctlbyname` post-call size race / byte truncation** — Size returned from second call isn't used to trim the buffer before decoding; theoretical race between size-probe and size-read. `PerformanceBenchmarkTests.swift:71-79`.
- **`FileManager.fileExists` passes unreadable files** — Files with mode 000 or SIP-protected paths pass the filter; `analyzeBPM` throws inside `try?`; track silently becomes `.failed` with no diagnostic. Printing the failing filename + error string would close the loop. `PerformanceBenchmarkTests.swift:269-272, 482-484`.
- **`accuracy.total` and `wallClock.trackCount` reuse the same integer with different semantics** — Only a concern if the out-of-scope accuracy snapshot feature (see decision-needed on story) is kept. Cosmetic. `PerformanceBenchmarkTests.swift:368, 381-395`.
- **All-tracks-failed soft-fail** — If every track throws, no baseline is written but the test reports success with `Acc1=0/N`. Consider a smoke gate like `#expect(oa300Acc1 > 0)`. `PerformanceBenchmarkTests.swift:437-454`.
- **OS version with no digits → fingerprint `-0.json`** — Won't hit on real macOS but superseded by the patch that switches to `ProcessInfo.processInfo.operatingSystemVersion.majorVersion`. `PerformanceBenchmarkTests.swift:220-230`.
- **Debug-mode committed baselines** — Permitted by AC #7 and documented as "Forward Hazard: Release-Mode Numbers" in the story Dev Notes. A future story should decide whether to ship `-c release` in the Makefile target or a separate `make perf-benchmark-release` pair. `Apple_M5_Max-26.json:647,687`, `Makefile:16`.

## Deferred from: code review of 2-3-performance-benchmark-infrastructure (2026-04-18)

**Reason:** Real findings from the third-pass code review; either pre-existing (not caused by Story 2-3 diff) or cosmetic/theoretical enough to defer to a later hygiene story.

- **`loadRecordsRejectsNonV2` unit test uses synthetic-v1 JSON** — The crafted JSON includes `hardware{}`/`wallClock{}`/`accuracy{}` keys a realistic v1 record would not have. Real historical v1 records fall through the generic `.malformed` path, not the `schemaVersion` guard. Guard itself is correct; only test coverage is misleading. `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1262-1280`.
- **Malformed-file recovery relies on implicit cross-function state** — After renaming a corrupt file and setting `previousRecord = nil`, the code falls through to `BaselineStore.append`, which internally re-calls `loadRecords` against the (now-missing) renamed file. Works today; any future edit to `append`'s preamble silently breaks recovery. `PerformanceBenchmarkTests.swift:+1157-1171`.
- **`BaselineStoreUnitTests.tmpFile()` defer-cleanup inconsistency** — `loadRecordsMissingFile` never writes, so no leak today, but the pattern differs from every other test in the suite (which `defer`s cleanup). A future write-adding edit silently leaks tmp files across CI runs. `PerformanceBenchmarkTests.swift:+1240-1245`.
- **Makefile `perf-benchmark` `trap` tiny-window leak** — Retired. Story 2-6 removed the staging/trap flow entirely; this item is no longer applicable.

## Deferred from: code review of 2-4-oa300-corpus-expansion-with-genre-diversity (2026-04-18)

**Reason:** Findings from the code review that are either pre-existing, environmental, or cosmetic enough to defer to follow-up hygiene rather than gate Story 2-4 from moving to `done`.

- **Test runs `JSONDecoder().decode()` twice in `throwsWhenGenreMissing`** — Belt-and-suspenders: the `#expect(throws: DecodingError.self)` block plus a second `do/catch` to extract the `keyNotFound` key both decode the same JSON. Could consolidate once Swift Testing supports typed associated-value matching. Cosmetic. `Tests/BoomBoomBoomKitTests/CorpusTracksDecodingTests.swift:56-69`.
- **`convert-rekordbox-export.py` CLI has no `args.output` hardening** — No parent-dir validation; `-o -` creates a literal file named `-` instead of routing to stdout; trailing-slash path surfaces `IsADirectoryError` as a bare traceback. Pre-existing style; script is not meant to be re-run per Task 3.6. `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py:278-281`.
- **No `encoding="utf-8"` on `open(args.output, "w")` or `sys.stdout`** — Under `LANG=C`/`LC_ALL=POSIX`, `json.dump(..., ensure_ascii=False)` can raise `UnicodeEncodeError` mid-output because the fixture contains non-ASCII (`Xiûa`, smart apostrophes). Environmental; macOS default locale is UTF-8. `Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py:278, 283-284`.
- **Duplicate `.wav` / `.mp3` pairs in OA300 fixture count twice in per-genre accuracy** — E.g., `5. Darkgray Heart_Beating Heart Of The Summer Sun (robbyt Remix)` has both `.wav` and `.mp3` variants as separate rows. Pre-existing corpus data-quality issue, not introduced by this story but now doubled in Story 2-5's per-genre buckets. `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`.
- **Completion Notes' "145/145 unit tests green" and GiantSteps `Acc1=81.1%, Acc2=82.5%` are unverifiable from the diff** — Trust-but-verify via `make test` and `make benchmark-giantsteps` before flipping status to `done`. Verification-only, not a code change. `_bmad-output/implementation-artifacts/2-4-oa300-corpus-expansion-with-genre-diversity.md:282-284`. (Note: `make test` re-run during review returned 149/149 green — claim upheld. GiantSteps re-run not repeated but unchanged code path.)
- **`--merge-from <json>` flag for `convert-rekordbox-export.py`** (Gemini refinement #1) — Preserve `genre` on re-run by reading the existing ground-truth JSON, extracting per-filename genre tags, and re-applying them to the newly generated rows. Currently the script warns loudly that re-running destroys genre; this would close the footgun. Spec explicitly lists the extension as out-of-scope (line 254-255); pick up if the script ever needs to re-run.
- **`Genre` wrapper struct with `RawRepresentable` / `ExpressibleByStringLiteral`** (Gemini refinement #4) — Replace `OA300Track.genre: String` with a typed wrapper exposing `static let drumAndBass: Genre = "drum-and-bass"` for common labels while staying string-compatible (preserves AC #2's "no library change required to add a genre"). Drift-guard test (`fixtureGenresAreWithinAllowedTaxonomy`) already catches typos in practice. Revisit once Story 2-5's reporter makes the ergonomic benefit (autocomplete, compile-time checks on common buckets) concrete.

## Deferred from: Story 2-5 genre-stratified accuracy reporting (2026-04-19)

**Reason:** Forward hazards noted during Story 2-5 implementation that are explicitly out-of-scope for this story but should be picked up later.

- **`BoomBoomBoomKitTestSupport` organization review** — Post-2-5, TestSupport holds 5 public helper files: `AccuracyMatchers`, `CorpusTracks`, `AudioFixtures`, `TestSignalGenerators`, and `GenreAccuracyReporter`. Five is the threshold where a table-of-contents or subdirectory split starts to pay off; at 7+ a README explaining the public-surface contract becomes table stakes. Revisit organization (subdirectories, README, public-API/SemVer contract) when the count exceeds 7. `Sources/BoomBoomBoomKitTestSupport/`.

## Deferred from: code review of 2-5-genre-stratified-accuracy-reporting (2026-04-19)

**Reason:** Review findings that are real but either blocked on a post-commit action or reflect coverage gaps the original AC set did not require.

- **AC #8 commit-SHA backfill in `.claude/skills/running-benchmarks/SKILL.md`** — Story spec literal requires the SHA to be recorded in Completion Notes "after the story commits". Story 2-5 was reviewed pre-commit, so the current doc references Story 2-5 by name instead. Post-commit, edit the skill doc's "Genre-stratified output" subsection to pin the expected stratification to the actual commit SHA. `.claude/skills/running-benchmarks/SKILL.md`.
- **`GenreAccuracyReporterTests.swift` coverage expansion** — AC #6's 8 cases do not exercise (a) ≥3-element tie-break to strict-weak-ordering the comparator, (b) `overallAcc1Percent == 0.0` and `== 100.0` boundaries of the `format(...)` precondition, (c) long (>20 char) or non-ASCII genre names that would expose silent truncation by `padding(toLength: 20, …)`. Pick up when a future corpus refresh introduces genres that cross these boundaries. `Tests/BoomBoomBoomKitTests/GenreAccuracyReporterTests.swift`.

## Deferred from: code review of 2-6-perf-baselines-file-per-run-redesign (2026-04-19)

**Reason:** Latent risks that cannot trigger with current ISO8601 formatter (UTC-only) or cosmetic/stability trade-offs acknowledged in the story dev notes.

- **`compactRecordedAt` non-UTC offset risk** — Stripping `-` and `:` from `recordedAt` would leave a `+` in the filename if the timestamp ever had a numeric timezone offset (e.g. `+05:30`). Cannot trigger today: formatter is hardcoded `secondsFromGMT: 0`. If the formatter is ever changed, validate that `compactRecordedAt` produces a filesystem-safe string. `PerformanceBenchmarkTests.swift` — `write` function.
- **`recordedAt` string sort breaks for non-UTC records** — `records.sorted { $0.recordedAt < $1.recordedAt }` is correct iff all timestamps are UTC ISO-8601 extended form. Same root cause as above; hypothetical future risk only. `PerformanceBenchmarkTests.swift` — `readHistory` return sort.
- **jq "Noise floor" median uses floor-index for even N** — `.[length/2|floor]` returns the lower-middle element rather than the average of two middle elements. Pre-existing methodology choice; not introduced by this story. `.claude/skills/running-benchmarks/SKILL.md` — "Noise floor" recipe.
- **Same-second `recordedAt` sort: `history.last` nondeterministic for rapid runs** — Two writes within the same UTC second produce identical `recordedAt` strings; Swift's stable sort preserves filesystem-enumeration order for equal keys, which is not meaningful. Cosmetic: the delta line reports a slightly off comparison. Spec explicitly uses read-before-write as the load-bearing correctness invariant, not sub-second ordering. `PerformanceBenchmarkTests.swift` — `readHistory` return sort.
- **Temp `.json.tmp` file lives in Dropbox-synced directory** — The old staging design kept temp files outside Dropbox. New design places the `.tmp` sibling directly in `_bmad-output/perf-baselines/`. Sub-millisecond lifetime on APFS means the risk of Dropbox racing with the rename is very low; `readHistory` ignores `.tmp` files; dev notes acknowledge this trade-off. Monitor if Dropbox conflict copies appear in the future. `PerformanceBenchmarkTests.swift` — `write` function.
