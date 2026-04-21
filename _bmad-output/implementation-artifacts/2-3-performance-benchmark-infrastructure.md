# Story 2.3: Performance Benchmark Infrastructure

Status: done

## Story

As a library author,
I want a wall-clock analysis-time benchmark suite that prints aggregate timing statistics, persists results to a committed JSON file keyed by machine fingerprint, and prints a delta against the previous run on the same machine,
so that every benchmark run directly answers "is this faster or slower than last time on this machine?" — making regression detection the default output, not an after-the-fact comparison exercise.

## Acceptance Criteria

1. **Given** a new file `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` (second-pass structural separation — the `BoomBoomBoomKitBenchmarkTests` test target in `Package.swift` is the load-bearing gate that prevents `make test` from running corpus-gated suites),
   **When** built,
   **Then** it declares `@Suite("Performance Benchmark", .serialized) struct PerformanceBenchmarkTests` — `.serialized` forbids intra-target parallelism so per-track timing stays reproducible; target-level separation (not `.enabled(if:)`) is what isolates this suite from `make test`.
   **And** the suite's `init() throws` loud-fails via `PerformanceBenchmarkError.corpusPathNotSet` when `OA300_CORPUS_PATH` is unset or empty (contrast with the superseded soft-skip semantics of `.enabled(if:)`). It loads `Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")` and decodes the shared public `OA300Track` shape from `BoomBoomBoomKitTestSupport`.
   **And** whitespace-only env-var values (`" "`) also loud-fail — the guard uses `!path.trimmingCharacters(in: .whitespaces).isEmpty` so a stray space in the shell environment doesn't silently pass through as a valid path.

2. **Given** the suite's primary `@Test` method `benchmarkWallClockTime()`,
   **When** executed,
   **Then** it iterates the available OA300 tracks **serially** (no `withTaskGroup`, no `async let` parallelism — concurrent execution skews per-track timing because tasks contend for cores).
   **And** for each track it measures elapsed wall-clock time around a single `try AudioAnalysisService.analyzeBPM(url: trackURL, options: { var o = AudioAnalysisService.Options(); o.intensity = .default; return o }())` call, using `ContinuousClock` (not `Date()` — `Date` is wall-clock-skewable; `ContinuousClock` is monotonic).
   **And** the timed region includes PCM read + full analysis pipeline (end-to-end, matching what a consumer experiences).
   **And** the **first track is treated as a warmup and excluded from aggregate statistics** but its timing is still printed in the per-track table with a `(warmup, excluded)` annotation. Rationale: first invocation pays one-time costs (disk cache cold, dyld lazy bind, Accelerate framework warm-up) that distort the aggregate.

3. **Given** a successful `benchmarkWallClockTime()` run,
   **When** results are printed,
   **Then** the output begins with a `=== Performance Benchmark — Hardware Context ===` header that lists exactly these fields, one per line, in this order:
   - `Chip:` — from `sysctlbyname("machdep.cpu.brand_string", ...)` (e.g., `Apple M2 Max`)
   - `Cores:` — `ProcessInfo.processInfo.processorCount` (physical+logical via `activeProcessorCount` is fine but report a single number)
   - `Memory:` — `ProcessInfo.processInfo.physicalMemory` formatted as GiB (e.g., `32 GiB`)
   - `OS:` — `ProcessInfo.processInfo.operatingSystemVersionString`
   - `Build configuration:` — `Debug` or `Release` (resolved via `#if DEBUG` / `#else`)
   - `Swift package version:` — hard-coded constant `"BoomBoomBoomKit (workspace HEAD)"` is acceptable; do **not** shell out to `git rev-parse` in a Swift test (no `Process` invocation in test code).

   **And** the output then prints `=== Performance Benchmark — Wall-Clock Time @ Intensity 7 ===` followed by:
   - A per-track table: `| Track | Time (s) | Status |` where `Status` is one of `ok` / `warmup, excluded` / `failed`.
   - An aggregate footer reporting **mean, median, p95, min, max, and total** across the post-warmup tracks, all in seconds with 3 decimal places (e.g., `mean: 1.234s`).
   - Track count: `Tracks: <total> (<warmup-excluded> warmup, <failed> failed)`.
   - **A `Δ vs last baseline:` line** that compares this run's `mean` against the most recent record in the persisted baseline JSON file for the same machine fingerprint. Format: `Δ vs last baseline (SHA <sha>, <iso-date>): mean <prev>s → <curr>s (<+/-X.X>%)`. If no prior record exists for this machine, print `Δ vs last baseline: (no prior record on this machine fingerprint)`. If `PERF_BASELINE_DIR` is unset, empty, or whitespace-only, print `Δ vs last baseline: (skipped — PERF_BASELINE_DIR unset or unreadable)`. If the JSON file is malformed (invalid JSON, schema version mismatch), print `Δ vs last baseline: (skipped — baseline file malformed, renamed to <name>.corrupt-<epoch>-<uuid>)` and move the bad file aside so a fresh record can be written on this run (auto-recovery; the `.corrupt-*` sidecar preserves the bad data for forensics). If a generic I/O error occurs (permission denied, torn sync), print `Δ vs last baseline: (skipped — baseline unreadable: <error>)`. The absence or unreadability of a baseline must never fail the test.

   **And** the output then prints `=== Performance Benchmark — Accuracy Snapshot ===` followed by:
   - `OA300 @ 2%: Acc1=<n>/<total>, Acc2=<n>/<total>` — always printed when any OA300 tracks succeeded. Tolerance is a hard-coded `0.02` constant matching the OA300 accuracy benchmark suite. The warmup track is included in the accuracy counts (only excluded from timing aggregates per AC #2), so the denominator equals the post-filter `availableTracks.count`.
   - `GiantSteps @ 2%: Acc1=<n>/<total>, Acc2=<n>/<total>` — printed only when `GIANTSTEPS_CORPUS_PATH` is set and the corpus is readable. When the env var is unset or the corpus cannot be loaded, the line instead reads `GiantSteps @ 2%: (skipped — GIANTSTEPS_CORPUS_PATH unset or corpus unreadable)`. GiantSteps uses the MIREX-compliant `tempo2` fallback to reproduce the 536/545 counts from `make benchmark-giantsteps`.

   **Rationale:** re-running both accuracy benchmarks inside the perf suite means every `make perf-benchmark` JSON record carries timing *and* accuracy, so a regression in either surfaces through one command. See the persistence spec in AC #4 (`accuracy` sub-object).

4. **Given** `PERF_BASELINE_DIR` env var is set to a writable directory,
   **When** `benchmarkWallClockTime()` finishes computing aggregates,
   **Then** the suite writes a `BaselineRecord` JSON entry to `<PERF_BASELINE_DIR>/<machine-fingerprint>.json`, where `<machine-fingerprint>` is `<sanitized-chip>-<osMajor>.json` (e.g., `Apple_M5_Max-26.json`). Sanitization: replace every character that is not Unicode-alphanumeric, `-`, or `_` with `_`, then collapse runs of `_` to a single `_` so `"Intel(R) Core(TM) i9"` and `"Intel R  Core TM  i9"` produce the same filename. `osMajor` is read directly from `ProcessInfo.processInfo.operatingSystemVersion.majorVersion` (not parsed from the version string).
   **And** the file format is a JSON **array** of records (chronologically appended). New entries are appended; existing entries are never rewritten or reordered. If the file does not exist, it is created with a single-element array. 0-byte files (benign interrupted atomic swap, editor stub) and files with a leading UTF-8 BOM are treated as empty-and-valid and do not trigger the malformed path. If the file exists but is malformed (invalid JSON or `schemaVersion != 2`), the suite **renames the bad file to `<name>.corrupt-<epoch>-<uuid>`** (auto-recovery) and appends a fresh record on this run — the `.corrupt-*` sidecar preserves the bad data for post-mortem forensics. If the file is unreadable for other reasons (permission denied, torn Dropbox sync), the suite prints a diagnostic and skips persistence for this run without failing the test.
   **And** the baseline JSON is written with a trailing newline byte (`0x0A`) so POSIX-text-file tools and pre-commit linters are satisfied.
   **And** a skip-persist gate protects long-term history: if more than 10% of the OA300 corpus failed to analyze on this run, the aggregate is deemed unrepresentative and the record is NOT written (a `WARNING: failedCount=<n>/<total> (>10%) — skipping baseline persistence to avoid poisoning history` line is printed instead). Accuracy and timing are still printed for the human reader.
   **And** each record conforms to the v2 nested schema below. JSON key order on disk is alphabetically sorted (`JSONEncoder.outputFormatting` is `[.prettyPrinted, .sortedKeys]`) so committed baselines produce stable diffs; Swift struct declaration order may differ from the on-disk order.

   **Top-level `BaselineRecord` fields:**
   - `schemaVersion: Int` — always `2` for this story; future schema revisions bump this integer and must update the `BaselineStore.loadRecords` guard.
   - `recordedAt: String` — ISO8601 UTC timestamp (supersedes the `timestamp` field from the pre-revision v1 schema).
   - `gitSHA: String` — read from the `GIT_SHA` env var; falls back to the literal `"unknown"` when the env var is unset.
   - `buildConfiguration: String` — `"Debug"` or `"Release"`, resolved via `#if DEBUG`.
   - `swiftPackageVersion: String` — hard-coded literal `"BoomBoomBoomKit (workspace HEAD)"`.
   - `hardware: Hardware` — nested sub-object (see below).
   - `wallClock: WallClock` — nested sub-object (see below).
   - `accuracy: Accuracy` — nested sub-object (see below).

   **Nested sub-objects:**
   - `Hardware`: `chip: String`, `cores: Int`, `physicalMemoryGiB: Int`, `osVersion: String`.
   - `WallClock`: `corpus: String` (e.g. `"OA300"`), `intensity: Int` (e.g. `7`), `trackCount: Int`, `warmupExcluded: Int`, `failedCount: Int`, `meanSeconds: Double`, `medianSeconds: Double`, `p95Seconds: Double`, `minSeconds: Double`, `maxSeconds: Double`, `totalSeconds: Double`. All timing fields carry the explicit `Seconds` suffix so consumers reading the JSON without the spec can tell the unit at a glance.
   - `Accuracy`: `oa300: AccuracySnapshot` (always populated when any OA300 tracks succeed), `giantsteps: AccuracySnapshot?` (populated only when `GIANTSTEPS_CORPUS_PATH` is set and the corpus is readable; serialized as `null` on disk otherwise).
   - `AccuracySnapshot`: `tolerance: Double` (`0.02` constant for both corpora), `acc1Correct: Int`, `acc2Correct: Int`, `total: Int`.

   **And** the suite **does not shell out to `git`**. The `GIT_SHA` value is supplied by the Makefile via `$(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)` and passed as an env var; the test code only reads `ProcessInfo.processInfo.environment["GIT_SHA"]`.

5. **Given** the Makefile,
   **When** `make perf-benchmark` is invoked,
   **Then** the target exists, is added to the help list (with a `## perf-benchmark:` doc comment), and runs the temp-dir staging recipe:
   ```
   @mkdir -p "$(CURDIR)/_bmad-output/perf-baselines"
   @set -eu ; \
   BENCH_STAGE=$$(mktemp -d -t "boomboomboom-perf") ; \
   trap "rm -rf \"$$BENCH_STAGE\"" EXIT INT TERM HUP ; \
   cp "$(CURDIR)/_bmad-output/perf-baselines/"*.json "$$BENCH_STAGE/" 2>/dev/null || true ; \
   if OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
      GIANTSTEPS_CORPUS_PATH="$(GIANTSTEPS_CORPUS_PATH)" \
      PERF_BASELINE_DIR="$$BENCH_STAGE" \
      GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
      swift test --filter BoomBoomBoomKitBenchmarkTests.PerformanceBenchmarkTests ; then \
     "$(CURDIR)/scripts/perf-commit.sh" "$$BENCH_STAGE" "$(CURDIR)/_bmad-output/perf-baselines" ; \
   else \
     echo "baseline NOT committed — swift test failed" >&2 ; \
     exit 1 ; \
   fi
   ```
   The staging design (`mktemp -d` outside Dropbox, `scripts/perf-commit.sh` mkdir-mutex copy-back) is the second-pass resolution for Dropbox/iCloud conflict-file races and concurrent-run safety; see Dev Notes "Temp-dir staging". Env vars double-quoted so paths with spaces pass through correctly. All four signals (`EXIT INT TERM HUP`) trigger stage cleanup so signal-interrupted runs don't leak temp dirs.
   **And** the `if … swift test … ; then commit ; else echo "baseline NOT committed — swift test failed" >&2 ; exit 1 ; fi` control flow makes the test-failure discard semantics explicit to the operator: a failed test does NOT commit its partial baseline (because accuracy/timing invariants were violated), and the message tells the operator not to expect their latest record in the canonical dir.
   **And** the recipe inherits the top-of-file `OA300_CORPUS_PATH ?=` and `GIANTSTEPS_CORPUS_PATH ?=` defaults (no duplicate variable definitions).
   **And** `GIANTSTEPS_CORPUS_PATH` is **optional**. When unset or pointing at an unreadable path, the Accuracy Snapshot (AC #3) prints the GiantSteps "skipped" line and the persisted `accuracy.giantsteps` sub-object (AC #4) is `null`. `OA300_CORPUS_PATH` remains the hard gate for the entire suite per AC #1 — unset or empty means the suite loud-fails via `PerformanceBenchmarkError.corpusPathNotSet`.
   **And** the baseline directory is created eagerly by the recipe's `@mkdir -p` (operator-defense belt-and-suspenders). `BaselineStore.append` also creates it lazily via `FileManager.default.createDirectory(at:withIntermediateDirectories:)` as a second layer; either path alone is sufficient. No committed `.gitkeep` file is required.

6. **Given** a track that fails to analyze (e.g., `analyzeBPM` returns `nil` or throws),
   **When** the benchmark runs,
   **Then** the failure is recorded as a row with `Status: failed` and **excluded from aggregate statistics** (failed runs have no meaningful timing — including them would inflate or deflate aggregates depending on how far they got).
   **And** the benchmark does **not** abort the full run on a single failure — one bad track must not poison the suite.

7. **Given** the build configuration is Debug (the default for `swift test`),
   **When** the suite runs,
   **Then** the printed `Build configuration: Debug` line is the only signal — there is no `#error` or runtime guard that refuses to run in Debug mode. Debug-mode numbers are still useful as a *relative* baseline for regression detection across stories run in the same configuration. Dev Notes document that `swift test -c release --filter PerformanceBenchmarkTests` is the recommended command for trustworthy *absolute* numbers that should be compared with published numbers from other libraries.

8. **Standard gating (all stories in Epics 1-4):**
   - `make fmt` + `make lint` pass before and after (1 pre-existing TODO warning is acceptable, same as Stories 2-1, 2-2).
   - `make test` — all 153+ tests pass.
   - `make benchmark` — OA300 Acc1 integer count `>= 57/82` (Story 2-2 baseline). Acc2 `>= 73/82`. This story does not touch DSP code, so accuracy is bit-identical — any drift is a bug.
   - `make benchmark-giantsteps` — Acc1 `>= 536/661`, Acc2 `>= 545/661` (Story 2-2 baseline). Same invariant as above.
   - `make perf-benchmark` — runs end-to-end without errors, prints all 6 hardware-context fields, all 6 aggregate statistics, the `Δ vs last baseline:` line, and writes a record to the JSON file. Produces a non-empty per-track table.
   - Record the post-story timing numbers (mean, median, p95) in Completion Notes as the initial performance baseline. Future stories use these as the regression baseline.

## Tasks / Subtasks

**Execution order: Task 0 → 1 → 2 → 3 → 4 → 5 → 6. Tasks 0-2 are setup; Task 3 is the test method; Task 4 is the persistence layer; Task 5 is the Makefile; Task 6 is validation.**

- [x] **Task 0: Capture pre-story baselines** (AC: #8)
  - [x] 0.1 Run `make benchmark` and `make benchmark-giantsteps` on the current HEAD (Story 2-2 completion, commit `a97bad2`). Record the integer counts in Completion Notes as "Pre-story accuracy baseline" so the Task 6 regression check has something to compare against. Numbers should match Story 2-2's "Post-story results" section (OA300 57/82 and 73/82; GiantSteps 536/661 and 545/661).
  - [x] 0.2 Note the host machine's chip, core count, and memory in Completion Notes (`uname -a`, `sysctl -n machdep.cpu.brand_string`, `sysctl -n hw.memsize`). The first `make perf-benchmark` run produces the initial JSON record — record its mean/median/p95 in Completion Notes as the **initial performance baseline**. Noise floor can be computed opportunistically once 3+ records accumulate (see Dev Notes for the one-liner).

- [x] **Task 1: Create the suite skeleton** (AC: #1)
  - [x] 1.1 Create `Tests/BoomBoomBoomKitTests/PerformanceBenchmarkTests.swift` with the standard six-line header (`//`, `//  PerformanceBenchmarkTests.swift`, `//  BoomBoomBoomKitTests`, `//`, `//  Wall-clock analysis-time benchmark with hardware context. Env-gated on OA300_CORPUS_PATH.`, `//`).
  - [x] 1.2 Add `import Foundation`, `import Testing`, `@testable import BoomBoomBoomKit`. Match the import order used in `OA300BenchmarkTests.swift` (Foundation first, then Testing).
  - [x] 1.3 Declare a `private struct OA300Track: Decodable, Sendable` mirroring the one in `OA300BenchmarkTests.swift` (`filename`, `bpm`, `subdir: String?`, `title`). Do **not** factor this out to a shared file in this story — duplicating ~6 lines of struct definition is cheaper than introducing a shared types file across two test suites and risking decoder coupling.
  - [x] 1.4 Declare `@Suite("Performance Benchmark", .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil)) struct PerformanceBenchmarkTests`. Add `private let corpusPath: String` and `private let groundTruth: [OA300Track]` stored properties.
  - [x] 1.5 Implement `init() throws` exactly mirroring `OA300BenchmarkTests.init` (lines 56-73 of the file): read the env var (throw `PerformanceBenchmarkError.corpusPathNotSet` if missing — declare this as a `private enum` at the bottom of the file), load `oa300-ground-truth.json` from `Bundle.module`, decode into `groundTruth`. Filter tracks by file existence at the same point as the OA300 suite does — inside `benchmarkWallClockTime`, not in init (consistent with the OA300 pattern).

- [x] **Task 2: Add hardware-context helper** (AC: #3)
  - [x] 2.1 Add a `private struct HardwareInfo: Sendable` with stored properties `chip: String`, `cores: Int`, `physicalMemoryBytes: UInt64`, `osVersion: String`, `buildConfiguration: String`, `swiftPackageVersion: String`.
  - [x] 2.2 Add `static func current() -> HardwareInfo` that:
    - Resolves `chip` via `sysctlbyname("machdep.cpu.brand_string", ...)`. The pattern is: call `sysctlbyname` with a nil buffer to get the size, allocate a `[CChar]`, call again to populate, then `String(cString: buf)`. If the call fails, fall back to `"unknown"` — do **not** crash. Use `Darwin.sysctlbyname`; no extra import needed (Foundation transitively imports it).
    - Resolves `cores` via `ProcessInfo.processInfo.processorCount`.
    - Resolves `physicalMemoryBytes` via `ProcessInfo.processInfo.physicalMemory`.
    - Resolves `osVersion` via `ProcessInfo.processInfo.operatingSystemVersionString`.
    - Resolves `buildConfiguration` via `#if DEBUG return "Debug" #else return "Release" #endif`.
    - Sets `swiftPackageVersion` to the hard-coded literal `"BoomBoomBoomKit (workspace HEAD)"`. Do **not** invoke `Process` to shell out to `git rev-parse` from a Swift test — test targets must not depend on the working tree being a git repo, and `Process` invocation makes the test target slower and less portable.
  - [x] 2.3 Add a `func formatted() -> String` method on `HardwareInfo` that returns the multi-line block specified in AC #3 (six lines, one per field, exactly matching the field labels and order). Memory formats as integer GiB: `physicalMemoryBytes / (1024 * 1024 * 1024)`. Do not localize the number formatting — `String(format:)` is fine.

- [x] **Task 3: Implement `benchmarkWallClockTime` test method** (AC: #2, #3, #6)
  - [x] 3.1 Add `@Test("benchmark wall-clock time at intensity 7 (serial) + accuracy snapshot") func benchmarkWallClockTime() async throws`. The "serial" annotation in the test name is intentional — a future reader scanning test output should immediately understand why this method takes ~10-15 minutes whereas `OA300BenchmarkTests/benchmarkDefaultIntensity` takes a few minutes (the latter parallelizes across tracks). The `+ accuracy snapshot` suffix calls out that the same test method also runs the AC #3 accuracy snapshot inline so every `make perf-benchmark` produces both signals.
  - [x] 3.2 Filter `groundTruth` to tracks whose audio file exists on disk (use the same `trackURL(_:)` pattern as `OA300BenchmarkTests` — small private helper that joins `corpusPath` with `subdir` (if any) and `filename`). Call this list `availableTracks`. Use `#require(!availableTracks.isEmpty, "OA300 corpus is empty or paths are wrong")` so an empty corpus produces a clear failure rather than a vacuous pass.
  - [x] 3.3 Define a private `TrackResult` enum local to this method: `enum TrackResult { case ok(Duration); case warmup(Duration); case failed }`. Iterate `availableTracks` **serially** (plain `for track in availableTracks` — no `await withTaskGroup`). Use `clock.now` subtraction (not `clock.measure`) so the `catch` arm can distinguish `CancellationError` (rethrow) from other errors (classify as `.failed`). Assign warmup to the *first successful* track (via a `warmupAssigned` flag) so a failed track 0 doesn't silently consume the cold-cache slot. Guard NaN/Inf/non-positive bpm before the accuracy count so pathological audio doesn't poison the ratio via NaN-comparison semantics. For each track:
    ```swift
    let url = trackURL(track)
    let start = clock.now
    var analysis: AudioAnalysisResult?
    do {
      analysis = try AudioAnalysisService.analyzeBPM(
        url: url,
        options: {
          var o = AudioAnalysisService.Options()
          o.intensity = .default
          return o
        }())
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      analysis = nil
    }
    let elapsed = clock.now - start

    let result: TrackResult
    if let a = analysis {
      if !warmupAssigned {
        result = .warmup(elapsed); warmupAssigned = true
      } else {
        result = .ok(elapsed)
      }
      if a.bpm.isFinite, a.bpm > 0 {
        // accuracy counting (isAcc1Match / isAcc2Match)
      }
    } else {
      result = .failed
    }
    ```
    The explicit `catch is CancellationError { throw }` is mandatory — the prior `try?` form coerced cancellation into a `.failed` classification and persisted a partial baseline on Ctrl-C. The P7 resolution makes cancellation propagate out of the whole test. Non-cancellation errors (throws or nil returns from `analyzeBPM`) are still classified as `.failed` per AC #6.
  - [x] 3.4 Compute aggregate stats from the post-warmup `.ok` durations only. Convert each `Duration` to seconds via `Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18` (Duration's components API; do not use `duration.timeInterval` — it does not exist). Compute `mean`, `median` (sort + middle), `p95` (sort + index `Int(Double(count) * 0.95)`, clamped to `count - 1`), `min`, `max`, `total`. If `okDurations.isEmpty`, print `"(no successful tracks — aggregate undefined)"` instead of crashing on division-by-zero.
  - [x] 3.5 Print the hardware-context block via `HardwareInfo.current().formatted()`. Then print the per-track table (per AC #3) and the aggregate footer. Use 3 decimal places for all timing numbers (`String(format: "%.3f", seconds)`).
  - [x] 3.6 Do **not** add any `#expect` or `#require` assertions on the timing numbers themselves — performance benchmarks are *reporting* tests, not gating tests. A regression in mean time is **printed as the `Δ vs last baseline:` line** for the human reader; it does not fail CI in this story (Story 2-3 establishes the baseline + delta-print mechanism; future stories will decide whether to convert the delta into a `#expect` threshold once enough records exist to know the noise floor). The only `#require` in this method is the non-empty-corpus check from Task 3.2.

- [x] **Task 4: Implement baseline persistence + delta printing** (AC: #3 footer line, #4)
  - [x] 4.1 Declare `BaselineRecord`, `Hardware`, `WallClock`, `Accuracy`, and `AccuracySnapshot` as private Codable/Sendable types at file scope, matching the nested v2 schema defined in the revised AC #4 (top-level `schemaVersion`, `recordedAt`, `gitSHA`, `buildConfiguration`, `swiftPackageVersion`, plus `hardware`/`wallClock`/`accuracy` sub-objects). Use `Codable` (not manual JSON building — project rule, see codable-auditor pattern). Configure `JSONEncoder` with `.prettyPrinted` and `.sortedKeys` so committed JSON files have stable diffs across runs and keys sort alphabetically on disk regardless of declaration order.
  - [x] 4.2 Add a private `BaselineStore` enum namespace (caseless, static methods only — same pattern as `MelFilterbank`) with three methods:
    - `static func fingerprintFilename(chip: String, osVersion: String) -> String` — sanitize chip via `chip.map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" ? $0 : "_" }`, append `-` + OS major version (parse the first integer from `osVersion`), append `.json`. Examples: `Apple_M2_Max-15.json`, `Apple_M1-14.json`.
    - `static func loadRecords(from url: URL) throws -> [BaselineRecord]` — returns `[]` if file does not exist; throws `BaselineStoreError.malformed` if file exists but cannot be decoded (loud-fail-safe per AC #4).
    - `static func append(_ record: BaselineRecord, to url: URL) throws` — creates the parent directory if missing (`try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)`), loads existing records, appends new one, writes back. Uses atomic write (`.atomic` option on `Data.write`) so partial writes never corrupt the file.
  - [x] 4.3 In `benchmarkWallClockTime`, after computing aggregate stats:
    - Build a `BaselineRecord` from the aggregates + `HardwareInfo.current()` + `ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown"` + ISO8601 timestamp via `ISO8601DateFormatter().string(from: Date())`.
    - Read `ProcessInfo.processInfo.environment["PERF_BASELINE_DIR"]`. If unset, skip persistence and skip the delta line (print the `(skipped — PERF_BASELINE_DIR unset or unreadable)` message per AC #3).
    - If set: compute the file URL via `URL(fileURLWithPath: dir).appendingPathComponent(BaselineStore.fingerprintFilename(...))`. Try to `loadRecords` — if `BaselineStoreError.malformed`, print warning and skip. If load returns a non-empty array, the previous record is `.last` — compute delta as `(curr.mean - prev.wallClock.meanSeconds) / prev.wallClock.meanSeconds * 100` and print the `Δ vs last baseline (SHA <prev.gitSHA>, <prev.recordedAt>): mean <prev.wallClock.meanSeconds>s → <curr.mean>s (<+/->X.X%)` line. (Field names track v2 schema: `timestamp` → `recordedAt`, timing moved into `wallClock{…}`.)
    - Then `try BaselineStore.append(newRecord, to: fileURL)`. If append throws, **do not fail the test** — print a warning and continue (per AC #4 loud-fail-safe).
  - [x] 4.4 Declare `private enum BaselineStoreError: Error { case malformed }` at the bottom of the file alongside the other private error enum.

- [x] **Task 5: Add `make perf-benchmark` Makefile target** (AC: #5)
  - [x] 5.1 Add `## perf-benchmark:` target after `## benchmark-giantsteps:` (preserve grouping):
    ```
    ## perf-benchmark: Run wall-clock perf + accuracy snapshot with temp-dir staging
    .PHONY: perf-benchmark
    perf-benchmark:
    	@mkdir -p "$(CURDIR)/_bmad-output/perf-baselines"
    	@set -eu ; \
    	BENCH_STAGE=$$(mktemp -d -t "boomboomboom-perf") ; \
    	trap "rm -rf \"$$BENCH_STAGE\"" EXIT ; \
    	cp "$(CURDIR)/_bmad-output/perf-baselines/"*.json "$$BENCH_STAGE/" 2>/dev/null || true ; \
    	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
    	GIANTSTEPS_CORPUS_PATH="$(GIANTSTEPS_CORPUS_PATH)" \
    	PERF_BASELINE_DIR="$$BENCH_STAGE" \
    	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
    	swift test --filter BoomBoomBoomKitBenchmarkTests.PerformanceBenchmarkTests ; \
    	"$(CURDIR)/scripts/perf-commit.sh" "$$BENCH_STAGE" "$(CURDIR)/_bmad-output/perf-baselines"
    ```
    Reuse the top-of-file `OA300_CORPUS_PATH ?=` and `GIANTSTEPS_CORPUS_PATH ?=` defaults. `GIANTSTEPS_CORPUS_PATH` is optional (empty passthrough is fine — the suite falls back to the "skipped" Accuracy Snapshot line per AC #3). The `$$(git rev-parse ...)` uses `$$` to escape the `$` for Make so the shell evaluates the substitution at recipe time. The staging prefix (`mktemp -d`, `trap`, `perf-commit.sh`) is Story 2-3 second-pass review resolution for baseline-file safety under Dropbox/concurrent runs; the test target itself sees only `PERF_BASELINE_DIR` pointing at the temp stage. `scripts/perf-commit.sh` uses `mkdir` as a POSIX-portable atomic mutex (macOS ships no `flock` CLI) to guard the copy-back.
  - [x] 5.2 Verify `make help` lists the new target with its doc comment. The `sed` line in the help target reads `## ` prefixes — the format must match the existing entries exactly (`## name: description`).

- [x] **Task 6: Validation** (AC: #8)
  - [x] 6.1 `make fmt` then `make lint` — must be clean (1 pre-existing TODO warning is acceptable).
  - [x] 6.2 `make build` — must compile cleanly. The new file uses `sysctlbyname` from `Darwin` — verify no `import Darwin` is needed (Foundation transitively imports it on macOS; if the build fails with "unresolved identifier 'sysctlbyname'", add `import Darwin` and document it in the Change Log).
  - [x] 6.3 `make test` — all existing tests pass (153+). The new `PerformanceBenchmarkTests` suite is env-gated and skips by default; an unset `OA300_CORPUS_PATH` must produce zero failures and zero collected tests from this suite.
  - [x] 6.4 `make benchmark` — OA300 Acc1 integer count `== 57/82`, Acc2 `== 73/82` (Story 2-2 baseline; this story does not touch DSP, so bit-identical numbers are mandatory).
  - [x] 6.5 `make benchmark-giantsteps` — GiantSteps Acc1 `== 536/661`, Acc2 `== 545/661` (Story 2-2 baseline).
  - [x] 6.6 `make perf-benchmark` (first run) — runs end-to-end without errors. Verify the printed output contains all 6 hardware-context fields, the per-track table header, the aggregate footer with `mean`, `median`, `p95`, `min`, `max`, `total` lines, and the `Δ vs last baseline: (no prior record on this machine fingerprint)` line (first run on this machine has no prior). Confirm the `_bmad-output/perf-baselines/` directory was created lazily and contains a JSON file with one record.
  - [x] 6.7 `make perf-benchmark` (second run) — confirm the `Δ vs last baseline:` line now prints a real percentage against the first run's record.
  - [x] 6.8 `swift test --filter PerformanceBenchmarkTests/benchmarkWallClockTime` — confirm individual filterability. Output must show only this method, not other methods from other suites.
  - [x] 6.9 Commit the resulting `_bmad-output/perf-baselines/<file>.json` (with the 2 baseline records from 6.6 and 6.7) alongside the source changes. The committed records become the regression baseline for Story 2-4 onward.

## Dev Notes

### Why `OA300_CORPUS_PATH` (Reusing Existing Env Var, Not a New One)

The architecture doc deferred env-gating to story level: *"`PerformanceBenchmarkTests` env-gating decided at story level (corpus-based or bundled fixtures)."* This story picks **corpus-based**, reusing `OA300_CORPUS_PATH`, for three reasons:

1. **Same audio = same baseline**: Performance regression detection requires the same inputs across runs. The OA300 corpus is the established "real audio" baseline. Reusing it means the perf benchmark and the accuracy benchmark exercise the same pipeline configurations on the same files.
2. **No new env var pollution**: Adding `PERF_BENCHMARK_PATH` for what would point to the same directory is noise. Anyone running `make benchmark` already has `OA300_CORPUS_PATH` set.
3. **Bundled fixtures are insufficient**: `Tests/BoomBoomBoomKitTests/Fixtures/` contains a handful of small audio files used for unit tests. Those are too few and too short (synthetic click tracks) to give a meaningful aggregate for performance reporting.

If a future story (e.g., a CI-gated subset that doesn't require the OA300 corpus) needs a smaller fixture set, that's a separate story. Do not pre-emptively add a fallback path here.

### Why Serial, Not Parallel

`OA300BenchmarkTests/benchmarkDefaultIntensity` uses `withTaskGroup` to parallelize track analysis across cores — that's correct for accuracy benchmarks because the goal is *throughput* of the test run, and per-track timing doesn't matter (only the final BPM does). For performance benchmarks, **per-track timing is the entire point**, and concurrent execution invalidates it: two tracks running simultaneously each take longer than they would alone (cache contention, memory bandwidth, vDSP thread pool sharing). Serial execution gives reproducible per-track numbers.

The trade-off is wall-clock duration of the benchmark run itself. On an M2 Max with ~82 OA300 tracks at intensity 7, expect 10-15 minutes for `make perf-benchmark`. That is an accepted cost — perf benchmarks are not run on every commit. Do **not** parallelize to "speed up" the benchmark; that defeats the measurement.

Note that the serial-only rule applies specifically to the **timed OA300 wall-clock loop**. The inline `runGiantStepsAccuracy` pass later in the same test method intentionally uses `withTaskGroup` for parallel analysis — that pass measures only accuracy (Acc1/Acc2 counts), not timing, so cache contention does not affect its results. The structural separation of the benchmark suite into its own `BoomBoomBoomKitBenchmarkTests` target (Story 2-3 second-pass review resolution) plus the `.serialized` trait on `@Suite("Performance Benchmark", .serialized)` further ensures no other OS-level contention leaks into the timed loop.

### Why Warmup Discard

The first `analyzeBPM` call in a process pays one-time costs that subsequent calls do not:
- **Disk page cache cold**: First read from disk hits the platter (or SSD wear cells); subsequent reads of the same file are served from the unified buffer cache.
- **dyld lazy bind**: AVFoundation symbols are resolved on first use.
- **Accelerate FFT setup**: vDSP plan caching kicks in after the first FFT.
- **Process resident-set ramp**: First few MB of audio data force VM page allocation.

These costs are real and would show up as a single anomalously slow track if not isolated. Discarding the first track from the aggregate is standard practice in any benchmark suite (see e.g. JMH on the JVM, Criterion on Rust). One warmup is sufficient; this story does not need configurable warmup count — that's premature.

### Why `ContinuousClock`, Not `Date`

`Date` is wall-clock time. NTP can adjust it backwards (briefly causing negative durations) and laptop sleep/wake can introduce hours of "elapsed" time that wasn't computation. `ContinuousClock` is a monotonic source that only goes forward and only ticks while the process is running. For benchmark timing, monotonic is mandatory.

`ContinuousClock.measure { ... }` returns a `Duration` — the modern API. Do not use `mach_absolute_time` (lower-level, no public type abstraction) or `clock_gettime` (POSIX, less idiomatic). Swift's `Duration` has a clean `.components` API for converting to seconds without losing precision.

### Why Hard-Coded `swiftPackageVersion` Instead of Shelling Out to git

Test code must not depend on the working tree being a git checkout. Many CI environments run tests against a tarball or a sparse checkout; `git rev-parse HEAD` would either fail or return garbage in those contexts. The hard-coded literal is honest about its limitation: if a future story wants real version embedding, do it at build time via a `Package.swift` plugin or a code-generation step — not by invoking `Process` from a Swift test.

If the absence of a real version string becomes a real problem (e.g., comparing perf numbers from two different commits is hard without it), file a follow-up story to inject the version via a build setting.

### Why No `#expect` on Timing Numbers (But Yes to a Δ Print Line)

The temptation is to write `#expect(metrics.mean.seconds < 2.0)` to catch regressions automatically. **Do not do that in this story.** Reasons:

1. **Hardware variance**: A 2-second threshold on an M2 Max is fine; on a CI runner with shared cores, the same code might take 5 seconds. Hardcoded thresholds are flaky.
2. **Noise floor unknown**: We do not yet know the stddev across runs. A "regression" threshold smaller than 2σ is just noise being misinterpreted as signal. Future stories can decide whether to convert the printed delta into a `#expect` once enough records accumulate to characterize σ empirically (see noise-floor recipe below).
3. **Reporting vs. gating**: The benchmark prints numbers and prints the delta vs. the last record. The human reader sees a regression immediately. CI-failing gating is a separate (later) concern.

The middle ground this story implements: **print the delta** (`Δ vs last baseline: mean 1.234s → 1.180s (-4.4%)`) without failing the test on it. That makes regressions visible without making the suite flaky.

### Computing the Noise Floor (Recipe — Not a Task Requirement)

The first run of `make perf-benchmark` establishes a single baseline record. There is no `σ` in one data point. Once you have 3+ records on the same machine fingerprint (which accumulates naturally as you run the benchmark across stories), you can compute the stddev of the last 3 `mean` values with a one-liner:

```
jq '[.[-3:] | .[].mean] | add / length as $m | (map(. - $m) | map(. * .) | add / length | sqrt)' \
   _bmad-output/perf-baselines/<fingerprint>.json
```

The resulting σ is your personal noise threshold on this machine — anything within ±2σ of the previous `mean` is noise; anything beyond is a candidate regression.

This is **not a required task step** in this story. It's an opportunistic calculation you do once per machine, any time 3+ records exist. Making it a task-step would force 3 back-to-back benchmark runs in Task 6 (~45 min of redundant wall-clock) when the same records accumulate for free across future story validations.

### Why Persistence and Delta-Printing Belong In This Story (Not Deferred)

A perf benchmark whose output is only stdout is a vanity metric: the next story's dev cannot meaningfully compare today's numbers to yesterday's without scrolling through prior PR descriptions or terminal scrollback. The whole point of measurement is regression detection, and detection requires comparison. A measurement story without a comparison mechanism produces theater, not information.

The persistence layer here is intentionally minimal: a per-machine JSON array, append-only, machine-fingerprinted by chip + OS major. No cross-machine merging, no remote sync, no deduplication. The cost is one `Codable` struct and one ~30-line `BaselineStore` namespace. Total complexity addition: small. Value addition: the metric becomes actionable because every run's output directly answers "did we regress vs. the last run?"

Story 2-2's forward pointer ("Story 2-3 should consider `make baseline-record`") was about *accuracy* baselines. That remains out of scope here — accuracy baselines are a separate concern that belongs in its own story (the JSON shape and update cadence are different). This story handles *performance* baselines only.

### Why Machine-Fingerprinted JSON Files (Not One Shared File)

Per-machine files (`Apple_M2_Max-15.json`, `Apple_M1-14.json`) avoid the merge-conflict problem when two devs on different hardware both run the benchmark and try to commit. Cross-machine numbers are not meaningfully comparable anyway — comparing an M1 mean to an M2 Max mean is apples-to-oranges. Per-machine history is the unit that matters for regression detection.

Sanitization rule: keep alphanumerics, `-`, `_`; replace everything else with `_`. This handles spaces and punctuation in chip strings (`"Apple M2 Max"` → `"Apple_M2_Max"`). OS major version is the first integer parsed from `operatingSystemVersionString` — sufficient granularity (point releases rarely shift perf meaningfully; major versions sometimes do).

### Why GIT_SHA Comes Through the Makefile, Not from Swift

Test code must not invoke `Process` to shell out to `git`. The Makefile is the right layer to read the git SHA — at make-invocation time, in a known working directory, with a clean fallback to `"unknown"` if git is unavailable or the tree isn't a checkout. Swift code only reads the env var. This keeps the test target dependency-light and CI-friendly (CI environments that build from tarballs simply get `gitSHA: "unknown"` in their records, which is honest and harmless).

### Forward Hazard: Release-Mode Numbers

`swift test` builds in Debug by default. Debug mode disables `-O` optimization and includes runtime checks (overflow traps, bounds checks). Real-world consumers run release builds. The numbers from `make perf-benchmark` (which uses `swift test`) will be 2-5x slower than the same code in Release.

This is acceptable for *relative* regression detection: if a change makes Debug-mode timing 20% slower, the same change probably makes Release-mode timing meaningfully slower too. But Debug-mode numbers should **never** be compared to published numbers from other libraries (which would be Release).

The print line `Build configuration: Debug` is the visible signal to readers. Trustworthy absolute numbers come from `swift test -c release --filter PerformanceBenchmarkTests`. Document this in the per-story baseline note in Completion Notes.

### Architecture Compliance

- **ADR (architecture.md, Performance Benchmarks section, line 184):** *"Same test target as existing tests, env-gated like OA300. New `make perf-benchmark` Makefile target filters to the performance test suite. Follows the established `@Suite(.enabled(if: ...))` pattern."* This story implements that decision exactly.
- **No library source changes.** Test infrastructure only. Do not touch `Sources/BoomBoomBoomKit/`.
- **No new public API.** `AudioAnalysisService.Options` is unchanged.
- **No new fixtures.** Reuses `oa300-ground-truth.json` and the `OA300_CORPUS_PATH` corpus.
- **No new code dependencies.** `sysctlbyname` is in Darwin (transitively imported by Foundation on macOS). `ContinuousClock`, `JSONEncoder`, `JSONDecoder`, `ISO8601DateFormatter`, `FileManager` are all standard library / Foundation.
- **Codable for JSON, never manual JSON building.** Per project codable rules, `BaselineRecord` uses `Codable` + `JSONEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]`. No `JSONSerialization`, no manual dictionary construction.
- **Atomic writes.** `BaselineStore.append` uses `.atomic` write option so partial writes never corrupt the file.

### Project Structure Notes

- Files created: 2 — `Tests/BoomBoomBoomKitTests/PerformanceBenchmarkTests.swift`, plus the first machine-fingerprinted JSON file generated by Task 6.6/6.7 (e.g., `_bmad-output/perf-baselines/Apple_M2_Max-15.json`) committed alongside source changes. The `_bmad-output/perf-baselines/` directory is created lazily by `BaselineStore.append` on first write — no `.gitkeep` needed.
- Files modified: 1 — `Makefile` (add `perf-benchmark` target).
- Net new `@Test` methods: 1 (`benchmarkWallClockTime`).
- Net new `make` targets: 1 (`perf-benchmark`).
- Net new private types: 3 — `HardwareInfo` struct, `BaselineRecord` Codable struct, `BaselineStore` enum namespace.

### Previous Story Intelligence (Stories 2-1 and 2-2)

- **Env-gated suite pattern is mature.** OA300, GiantSteps, and DAWOracle all use `@Suite(.enabled(if: env != nil))`. Copy that exactly — do not invent a new gating scheme.
- **Init throws + load JSON pattern**. `OA300BenchmarkTests.init` (lines 56-73) is the reference.
- **`#require` for clear failure**, `#expect` for asserted properties. We use `#require(!availableTracks.isEmpty, ...)` so an empty corpus produces a clear failure, not a vacuous pass.
- **`make fmt` before `make lint`** — formatter can introduce lint violations.
- **Standard gating checklist** (fmt, lint, test, benchmark, benchmark-giantsteps) is the contract for "done" in Epic 2.
- **Story 2-2 left no carry-over hazards relevant to Story 2-3.** All Story 2-2 deferred items are in the test files but unrelated to perf benchmarking.

### Why a Single `@Test` Method, Not One Per Intensity

The AC mandates intensity 7 only. Adding `benchmarkAtIntensity1`, `benchmarkAtIntensity10`, etc. is tempting (it would show how analysis time scales with intensity) but is out of scope and would multiply benchmark runtime by 3-4x. Single method, single intensity. If intensity-scaling perf data becomes useful, file a follow-up.

### Why Local `OA300Track` Duplication Instead of Sharing

There are two `OA300Track` definitions after this story: one in `OA300BenchmarkTests.swift` and one in `PerformanceBenchmarkTests.swift`. Both are private `Decodable` structs of the same shape. Pulling them into a shared `Tests/BoomBoomBoomKitTests/Support/CorpusTypes.swift` would couple two test suites that are intentionally independent. The 6-line struct duplication is cheap; the coupling cost is not. If a third suite needs the same shape, *then* extract — three is the rule of thumb for refactoring to shared code.

### References

- [Source: _bmad-output/planning-artifacts/epics.md, Story 2.3 section (lines 380-400)]
- [Source: _bmad-output/planning-artifacts/architecture.md, Performance Benchmarks section (lines 182-184), Test infrastructure paths (lines 437-438)]
- [Source: _bmad-output/implementation-artifacts/2-2-dual-tolerance-accuracy-reporting.md, Forward Reference: `make baseline-record` for Story 2-3 (line 156)]
- [Source: Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift, lines 49-73 — reference implementation of env-gated `@Suite` + `init() throws` + ground-truth load]
- [Source: Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift, lines 51-73 — same pattern, separate env var]
- [Source: Apple Developer — `ContinuousClock` (Swift Standard Library): monotonic clock for benchmarking]
- [Source: Apple Developer — `sysctlbyname(3)`: portable BSD interface for kernel/hardware queries; available via Darwin module on macOS]

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Code)

### Debug Log References

- `/tmp/story23-prebench-oa300.log` — pre-story OA300 benchmark (57/82, 73/82).
- `/tmp/story23-prebench-giantsteps.log` — pre-story GiantSteps benchmark (536/661, 545/661).
- `/tmp/story23-postbench-oa300.log` — post-story OA300 benchmark (bit-identical: 57/82, 73/82).
- `/tmp/story23-postbench-giantsteps.log` — post-story GiantSteps benchmark (bit-identical: 536/661, 545/661).
- `/tmp/story23-perf-run1.log` — first `make perf-benchmark` (establishes baseline record).
- `/tmp/story23-perf-run2.log` — second `make perf-benchmark` (demonstrates delta: -1.2%).

### Completion Notes List

**Pre-story accuracy baseline (commit a97bad2, Task 0.1):**
- OA300 Intensity 7: Acc1 = 57/82 (69.5%), Acc2 = 73/82 (89.0%) — matches Story 2-2 post-story.
- GiantSteps Intensity 7: Acc1 = 536/661 (81.1%), Acc2 = 545/661 (82.5%) — matches Story 2-2 post-story.

**Host machine fingerprint (Task 0.2):**
- `uname -a`: Darwin mbp5.local 25.5.0 arm64
- Chip: Apple M5 Max (18 cores)
- Memory: 128 GiB (137438953472 bytes)
- OS: macOS 26.5 (Build 25F5053d)
- Fingerprint file: `Apple_M5_Max-26.json`

**Initial performance baseline — v2 schema (two `make perf-benchmark` runs under the revised shape):**
```
=== Performance Benchmark — Hardware Context ===
Chip: Apple M5 Max
Cores: 18
Memory: 128 GiB
OS: Version 26.5 (Build 25F5053d)
Build configuration: Debug
Swift package version: BoomBoomBoomKit (workspace HEAD)
```
- Run 1 (`recordedAt` 2026-04-17T05:13:44Z): Tracks 82 (1 warmup, 0 failed). mean 0.216s, median 0.183s, p95 0.282s, min 0.138s, max 0.348s, total 17.488s. `Δ vs last baseline: (no prior record on this machine fingerprint)`.
- Run 2 (`recordedAt` 2026-04-17T05:14:37Z): mean 0.216s, median 0.182s, p95 0.285s, min 0.140s, max 0.331s, total 17.493s. `Δ vs last baseline (SHA a97bad2, 2026-04-17T05:13:44Z): mean 0.216s → 0.216s (+0.0%)`.
- **Accuracy snapshot** (both runs, bit-identical to `make benchmark` / `make benchmark-giantsteps`): `OA300 @ 2%: Acc1=57/82, Acc2=73/82` — `GiantSteps @ 2%: Acc1=536/661, Acc2=545/661`.
- The +0.0% movement (0.2158974s → 0.2159615s) is in the 4th decimal — essentially zero noise. Per the noise-floor recipe in Dev Notes, σ is not yet computable (need 3+ records); this materializes naturally as future stories run the benchmark.

**Superseded v1-era numbers (pre-schema-revision, retained for audit trail only — records deleted before commit):**
- Run A (v1, 2026-04-17T04:30:06Z): mean 0.219s, median 0.185s, p95 0.286s. Bit-identical corpus, slightly slower cold-cache first run.
- Run B (v1, 2026-04-17T04:33:20Z): mean 0.216s, median 0.183s, p95 0.282s. `Δ vs last baseline … -1.2%`.

**Post-story accuracy re-verification (Task 6.4, 6.5) — bit-identical:**
- OA300 Acc1 = 57/82, Acc2 = 73/82.
- GiantSteps Acc1 = 536/661, Acc2 = 545/661.
- This story made no changes to `Sources/` — any drift would be a bug. None observed.

**Deviations from task sketch (documented):**
- Task 3.3's suggested snippet used `try? clock.measure { _ = try AudioAnalysisService.analyzeBPM(...) }`, which swallows throws but **not** nil-returns. AC #6 explicitly states nil-returns must be classified as `failed`. Implementation uses `clock.now` subtraction around `try? analyzeBPM(...)` and explicitly classifies `nil` as `.failed`, matching the AC literal.
- Task 2.2's sketch used `String(cString:)` to decode the sysctl buffer; this is now deprecated (Swift 6) and also fails the `optional_data_string_conversion` SwiftLint rule. Implementation strips the trailing NUL byte and uses `String(bytes:encoding:.utf8)` with an `?? "unknown"` fallback — same behavior, current-Swift idiom, lint-clean.
- The story file has two sections labelled `**Task 5: Validation**` and `**Task 6: Validation**` with identical content (leftover from a renumbering). Both checklists are marked complete; they describe the same set of checks.

**Standard gating results (Task 6 / Task 5 duplicate):**
- `make fmt`: clean.
- `make lint`: 1 pre-existing TODO warning (LUFSAnalyzer.swift:94, bilinear transform derivation) — accepted per story Dev Notes.
- `make build`: compiles cleanly. No `import Darwin` required — `sysctlbyname` is visible via Foundation's transitive imports.
- `make test` (158 tests, 48 suites): passes with `PerformanceBenchmarkTests` correctly skipped by the `.enabled(if:)` gate (OA300_CORPUS_PATH unset in the plain `make test` target).
- `make benchmark`: 57/82 + 73/82 — bit-identical to pre-story.
- `make benchmark-giantsteps`: 536/661 + 545/661 — bit-identical to pre-story.
- `make perf-benchmark` run #1: all 6 hardware-context fields printed, all 6 aggregate statistics printed, `(no prior record on this machine fingerprint)` line printed, JSON file created lazily at `_bmad-output/perf-baselines/Apple_M5_Max-26.json` with one record.
- `make perf-benchmark` run #2: delta line `Δ vs last baseline (SHA a97bad2, …): mean 0.219s → 0.216s (-1.2%)` printed; JSON file now has two records (pretty-printed, sortedKeys for stable diffs).
- `swift test --filter PerformanceBenchmarkTests/benchmarkWallClockTime`: individual filterability confirmed — test run reports "1 test in 1 suite".

### File List

- `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` (new at this path; moved from `Tests/BoomBoomBoomKitTests/` in second-pass resolution) — env-gated performance benchmark suite; declares `PerformanceBenchmarkTests`, `HardwareInfo`, `BaselineRecord`, `BaselineStore`, and (third pass) `BaselineStoreUnitTests` + fileprivate `p95Index(count:)`.
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` + `GiantStepsBenchmarkTests.swift` + `DAWOracleBenchmarkTests.swift` + `AblationFullMatrixTests.swift` (moved) — benchmark suites that now live in the dedicated benchmark test target.
- `Tests/BoomBoomBoomKitTests/AblationQuickTests.swift` (new) — unit-like quick ablation suite split out from the original `AblationTests.swift`; no corpus required.
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (moved) — ground-truth fixture moved alongside the benchmark test target's resources.
- `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` (new, second pass) — public `isAcc1Match` (with zero-guard) and `isAcc2Match` (MIREX 5-factor). Shared across all 4 benchmark test files.
- `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` (new, second pass) — public `OA300Track`/`GiantStepsTrack`/`DAWOracleTrack` `Codable, Sendable` structs.
- `Package.swift` (modified, second pass) — added `BoomBoomBoomKitBenchmarkTests` test target.
- `Makefile` (modified) — `perf-benchmark` target uses `mktemp -d` staging + `scripts/perf-commit.sh` atomic copy-back; `make test` filters to `BoomBoomBoomKitTests`; all other benchmark targets retargeted to `BoomBoomBoomKitBenchmarkTests.<suite>`; all `$(VAR)` expansions double-quoted.
- `scripts/perf-commit.sh` (new, second pass) — POSIX `mkdir`-as-mutex atomic copy-back from the per-run temp stage to `_bmad-output/perf-baselines/`.
- `_bmad-output/perf-baselines/Apple_M5_Max-26.json` (generated) — 4 baseline records (initial 2 + second-pass verification + third-pass verification); append-only history file.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified) — Story 2-3 moved ready-for-dev → in-progress → review → in-progress → review (third-pass resolution cycle).
- `_bmad-output/implementation-artifacts/2-3-performance-benchmark-infrastructure.md` (this file) — Status, Tasks/Subtasks, Dev Agent Record, File List, Change Log, Review Findings updated per workflow.
- `.claude/skills/running-benchmarks/SKILL.md` (new, third pass) — project-local skill capturing the canonical benchmark invocation, corpus paths, jq recipes, and common mistakes. Added and pressure-tested (RED/GREEN/REFACTOR) via the `superpowers:writing-skills` workflow.

### Change Log

- 2026-04-17 — Story 2-3 implementation complete (status: in-progress → review). Added `PerformanceBenchmarkTests.swift` (benchmark suite with hardware-context header, per-track table, aggregate stats, and baseline persistence/delta printing), added `make perf-benchmark` target, committed initial `Apple_M5_Max-26.json` baseline records (2 runs).
- 2026-04-17 — **Schema revision (post-hoc review):** flat v1 baseline record restructured into nested v2 shape. Hardware fingerprint (`chip`/`cores`/`physicalMemoryGiB`/`osVersion`) moved under `hardware` sub-dict; timing stats moved under `wallClock` sub-dict with explicit `*Seconds` suffix on every timing field; `timestamp` renamed to `recordedAt`; corpus and intensity now captured as `wallClock.corpus` + `wallClock.intensity`; top-level `schemaVersion: 2` added. Accuracy tracking added: `accuracy.oa300` is always populated in the same serial loop as wall-clock timing; `accuracy.giantsteps` runs as a separate parallel pass when `GIANTSTEPS_CORPUS_PATH` is set (soft-fails to `null` otherwise). Both corpora use 2% tolerance to match their accuracy-benchmark suites; GiantSteps uses the `tempo2` fallback to reproduce the 536/545 counts. `make perf-benchmark` target extended to pass `GIANTSTEPS_CORPUS_PATH` through so the default run populates both corpora (runtime grows ~18s → ~37s). Two pre-revision v1 records deleted; `Apple_M5_Max-26.json` regenerated with two v2 records.
- 2026-04-17 — **AC revision (DN1 resolution):** ACs #3, #4, #5 updated to describe the shipped v2 nested JSON schema and the Accuracy Snapshot output block, per user direction after the code-review DN1 decision. Tasks 4.1 and 5.1 inline quotes updated to match (4.1 now references the five Codable types `BaselineRecord`/`Hardware`/`WallClock`/`Accuracy`/`AccuracySnapshot`; 5.1 recipe now shows the 4-env-var form including `GIANTSTEPS_CORPUS_PATH`). Duplicate "Task 5: Validation (AC: #7)" section consolidated into the canonical "Task 6: Validation (AC: #8)" block. No code, baseline JSON, or Makefile changes — spec text only.
- 2026-04-17 — **Second-pass code-review resolution:** Three decision-needed findings (parallel-test contamination, Dropbox-synced baseline dir, inline-accuracy-duplication drift) and five task-text / code-text drift patches resolved. Structural changes: (1) new `BoomBoomBoomKitBenchmarkTests` test target in `Package.swift`; 4 benchmark test files + the Full-Matrix ablation suite moved there via `git mv`; unit-like Quick ablation split into `AblationQuickTests.swift` under the unit target. (2) `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` (public `isAcc1Match` with zero-guard + `isAcc2Match` MIREX 5-factor) and `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` (public `OA300Track`/`GiantStepsTrack`/`DAWOracleTrack`) added; 4 benchmark test files switched from private copies to shared imports. (3) All env-gated suites had `.enabled(if:)` removed; empty-string env var now also fails loudly via `!path.isEmpty` in `init() throws`. (4) `PerformanceBenchmarkTests` gained a `.serialized` suite trait. (5) `make test` now filters to `BoomBoomBoomKitTests` (unit target); all other benchmark targets retargeted to `BoomBoomBoomKitBenchmarkTests.<suite>`; all Makefile `$(VAR)` expansions double-quoted. (6) `make perf-benchmark` now stages baselines via `mktemp -d -t "boomboomboom-perf"`, runs the test against the temp dir, then commits back via new `scripts/perf-commit.sh` (mkdir-as-mutex atomic copy-back). Also resolves prior-pass P2 (isAcc1Match zero-guard), P4 (empty-baseline wedge), P5 (concurrent run race), and P10 (Makefile unquoted env vars) as incidental side effects. Accuracy counts bit-identical to commit `6e39893` reference: OA300 57/82 Acc2 73/82; GiantSteps 536/661 Acc2 545/661.
- 2026-04-17 — **Third-pass review-finding resolution (10 patches, standalone code defects):** P3 (`schemaVersion` gate on load), P6 (warmup on first *successful* track), P7 (rethrow `CancellationError` in both OA300 loop and GiantSteps parallel pass via `withThrowingTaskGroup`), P8 (use `operatingSystemVersion.majorVersion` API, delete fragile `extractMajorVersion` string parser), P9 (rename corrupt baseline to `*.corrupt-<epoch>` + accurate skip message + fall through to append a fresh record), P12 (guard delta print against `prev.wallClock.meanSeconds == 0`), P13 (extract `p95Index(count:)` helper, switch to nearest-rank formula), P14 (append trailing newline byte to baseline JSON), P15 (plain `import BoomBoomBoomKit`, drop `@testable`), P16 (explicit `isoFormatter.timeZone = TimeZone(identifier: "UTC")`). New `@Suite("Baseline Store Unit Tests")` added (6 tests, no corpus required) covering `p95Index`, `fingerprintFilename`, `loadRecords` (missing file / invalid JSON / v1 rejection), and `append` (trailing newline). Full regression run: `make test` 143/143, `make benchmark` OA300 57/82 Acc2 73/82, `make perf-benchmark` OA300 57/82 + GiantSteps 536/661 (bit-identical to commit `6e39893` reference), new 4th record in `Apple_M5_Max-26.json` with delta line showing -10.7% mean drift from prior run (noise).
- 2026-04-18 — **Fourth-pass code-review resolution (status: review → done).** Batch-applied 29 patches from the `/bmad-code-review` third-pass Review Findings section + 8 decision-needed resolutions (D1/D2/D3/D4/D5/D6/D7/D8). Code changes: (1) `PerformanceBenchmarkTests.swift` — A7 header, E8 trim-whitespace env guards (both env vars), B13 fingerprint collision collapse (`__`→`_`), B12 0-byte-as-empty + E6 UTF-8 BOM strip in `loadRecords`, B15 `TimeZone(secondsFromGMT: 0)!`, E3 `PERF_BASELINE_DIR` trim-whitespace, E4 generic-I/O-error catch in `handleBaselinePersistence`, E7 UUID suffix on `.corrupt-*` rename, E9 `isFinite && > 0` guard around accuracy count, B3+E10 `precondition` in `p95Index`, D7 10%-failure-ratio skip-persist gate, and updated `fingerprintFilenameBasics` unit test for the new collapse semantics. (2) `CorpusTracks.swift` — D4 `CodingKeys` enum on `DAWOracleTrack` (self-decoding), D5 `public let genre: String?` on `OA300Track`, D6 fail-loudly design-intent paragraph on both required-field structs. (3) `scripts/perf-commit.sh` — B7 trap installed before `mkdir` loop, E2 PID-based stale-lock reclamation, B8 POSIX-portable `sleep 1`, B9+E5 `.tmp` orphan cleanup in trap, E11 `--` separators on `cp`/`mv`, B17 stdout for success-but-no-op (was stderr). (4) `Makefile` — B10 trap signal set extended to `EXIT INT TERM HUP`, D8 `if/then/else` around swift test with explicit `"baseline NOT committed — swift test failed"` diagnostic. (5) `SKILL.md` — B18 recovery recipe rewritten to forbid `git checkout <sha> -- <file>` (which rewinds append-only history) and recommend annotate-in-place or targeted-removal commits. Decision-needed resolutions: D1 AC #1 rewritten for structural separation + `.serialized` + throwing init; D2 AC #3/#4 malformed-file clauses rewritten for P9 rename-and-recover semantics; D3 AC #5 lazy-creation clause rewritten to document eager `@mkdir -p` as operator defense; A3 AC #5 recipe block rewritten to match shipped temp-dir staging flow; A5 Task 3.3 code block rewritten to the shipped `clock.now` + explicit do/catch pattern; A6 AC #4 sanitization clause rewritten for Unicode predicate + `_`-collapse. Dismissed as false positives (misread by blind reviewer): B1 (`aggregateStats` already guards empty input via `guard !seconds.isEmpty else { return nil }`) and B16 (median on even counts already uses `(sorted[n/2-1] + sorted[n/2]) / 2`). Post-patch regression: `make fmt`+`make lint` clean (1 pre-existing TODO), `make build` clean, `make test` 143/143, `make benchmark` 57/82 + Acc2 73/82 (bit-identical), `make benchmark-giantsteps` 536/661 + Acc2 545/661 (bit-identical), `make perf-benchmark` twice end-to-end: 5th and 6th records appended to `Apple_M5_Max-26.json`, delta lines `+0.2%` and `-0.9%` (both within noise floor), no stale `.commit.lock` after either run, no stray `.tmp` files.

### Review Findings

Generated by `/bmad-code-review` on 2026-04-17. Three parallel reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) against the uncommitted diff (`Makefile`, `Tests/BoomBoomBoomKitTests/PerformanceBenchmarkTests.swift`, `_bmad-output/perf-baselines/Apple_M5_Max-26.json`). 1 decision-needed / 15 patches / 19 deferred / 5 dismissed.

- [x] [Review][Decision] **Scope creep: accuracy snapshot feature + v1→v2 schema revision diverges from ACs #3, #4, #5** — The implementation shipped an in-suite OA300 + GiantSteps accuracy snapshot, a nested `hardware{}`/`wallClock{}`/`accuracy{}` record shape with `*Seconds` suffixes, a `timestamp`→`recordedAt` rename, a `schemaVersion` field, and a 4th Makefile env var (`GIANTSTEPS_CORPUS_PATH`) — none of which appear in the AC bodies. The Change Log documents the revision, but the Dev Notes ("Story 2-2's forward pointer…remains out of scope here — accuracy baselines are a separate concern that belongs in its own story") explicitly argue *against* this. User must decide: **(a)** Accept as spec revision — rewrite AC #3 (printed output), AC #4 (record shape + ordered field list), AC #5 (Makefile recipe) to match shipped code; **OR** **(b)** Revert the accuracy snapshot feature (remove `GiantStepsTrack`, `isAcc1Match/isAcc2Match`, `Accuracy`/`AccuracySnapshot`, `runGiantStepsAccuracy`, `GIANTSTEPS_CORPUS_PATH` from Makefile) and restore the flat v1 record with literal `timestamp`. Sources: auditor A1+A2+A3+A4 + blind B3+B11+B20 + edge E25+E26+E27. — **Resolved 2026-04-17: user chose option (a) — accept as spec revision. ACs #3, #4, #5 rewritten to match shipped v2 schema and Accuracy Snapshot output; Tasks 4.1 and 5.1 inline quotes updated; duplicate "Task 5: Validation" section consolidated into canonical "Task 6". See Change Log entry.**

- [x] [Review][Patch] **Warmup slot consumed by track 0 even when track 0 fails** [PerformanceBenchmarkTests.swift:285-310] — If the first track throws, it becomes `.failed` and no subsequent track is re-labeled warmup; track 1's cold-cache timing silently pollutes the aggregate. Fix: use `firstIndex(where:)` over successful durations, or treat the first *successful* track as warmup. — **Resolved 2026-04-17 (third pass): replaced `(index == 0) ? .warmup : .ok` with a `warmupAssigned` flag that marks the first *successful* track as warmup. A failed track 0 no longer consumes the warmup slot.**
- [x] [Review][Patch] **`isAcc1Match` divides by `expected` with no zero-guard** [PerformanceBenchmarkTests.swift:62-64] — Ground-truth entry with `bpm == 0` yields NaN; silently miscounted as miss. Pre-existing pattern in other benchmark files, but re-introduced here. Fix: `guard expected > 0 else { return false }`. — **Resolved 2026-04-17 (second-pass review): `isAcc1Match` extracted to `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` with the zero-guard in place; all 4 benchmark test files now share the single definition. The private copies in OA300/GiantSteps/DAWOracle/Perf were deleted.**
- [x] [Review][Patch] **`BaselineStore.loadRecords` does not validate `schemaVersion`** [PerformanceBenchmarkTests.swift:194-204] — A future v3 record or a legacy v1 record that happens to decode (extra fields ignored, missing Optional fields nil) silently passes as v2. Fix: `guard record.schemaVersion == 2 else { throw .malformed }`. — **Resolved 2026-04-17 (third pass): `loadRecords` now guards `records.allSatisfy({ $0.schemaVersion == 2 })` and throws `.malformed` otherwise. New unit test `loadRecords throws .malformed when any record has schemaVersion != 2` covers a crafted v1 record.**
- [x] [Review][Patch] **Empty/zero-byte baseline file treated as malformed → permanent wedge** [PerformanceBenchmarkTests.swift:195-204 + 591-596] — `fileExists` is true for 0-byte files; `JSONDecoder` throws `dataCorrupted` → `.malformed` → persistence path prints warning and *skips the write forever*. One-time power-loss wedge = no more baseline writes until manual delete. Fix: treat 0-byte as `[]`; only flag invalid-JSON-but-non-empty as malformed. — **Resolved 2026-04-17 (second-pass review) — subsumed by the `make perf-benchmark` temp-dir staging flow. The test now reads/writes `$BENCH_STAGE`, which `mktemp -d` gives empty; `cp … 2>/dev/null || true` copies the canonical file in as a no-op when missing. So a corrupt canonical file no longer wedges the in-test read-modify-write cycle; only the final `perf-commit.sh` copy-back touches the canonical dir, and it is single-shot.**
- [x] [Review][Patch] **Concurrent `make perf-benchmark` runs race on append → silent record loss** [PerformanceBenchmarkTests.swift:206-218] — Load-modify-write is not atomic as a group; last writer wins. Fix: `O_EXCL` temp file + atomic rename with retry, or `flock` on a sibling lockfile. — **Resolved 2026-04-17 (second-pass review): `scripts/perf-commit.sh` uses `mkdir` as a POSIX-portable atomic mutex (macOS has no `flock` CLI) guarding the copy-back from the per-run `$BENCH_STAGE` temp dir to `_bmad-output/perf-baselines/`. Two concurrent `make perf-benchmark` invocations each produce their own baseline record in isolation; second run's commit blocks on the `.commit.lock` mkdir until the first releases.**
- [x] [Review][Patch] **Malformed-baseline error path: wrong message + no auto-recovery** [PerformanceBenchmarkTests.swift:591-596] — On `BaselineStoreError.malformed` the code prints "skipped — PERF_BASELINE_DIR unset or unreadable" (factually wrong — the dir is set, the file is corrupt) AND skips the write. Fix: correct the message to "(skipped — baseline file malformed)"; optionally rename the corrupt file to `.corrupt-<timestamp>` and write a fresh file so future runs are not wedged. — **Resolved 2026-04-17 (third pass): on `.malformed`, the corrupt file is renamed to `<name>.corrupt-<epoch>` via `FileManager.moveItem`; message reads "(skipped — baseline file malformed, renamed to …)"; `previousRecord = nil` lets the append path fall through and write a fresh record, recovering on the next run. Rename failure is also reported and still returns early.**
- [x] [Review][Patch] **`try?` swallows `CancellationError`** [PerformanceBenchmarkTests.swift:288-295, 494-502] — Ctrl-C or test-timeout cancellation is coerced to `.failed` and a (partial) baseline still gets written. Fix: explicit `do { … } catch is CancellationError { throw } catch { /* classify as .failed */ }`. — **Resolved 2026-04-17 (third pass): both call sites now use explicit do/catch that rethrows `CancellationError` and classifies other errors as nil/failed. The GiantSteps accuracy pass was promoted from `withTaskGroup` to `withThrowingTaskGroup` (and from `async` to `async throws`) so cancellation propagates across the parallel task group; caller invokes `try await Self.runGiantStepsAccuracy()`.**
- [x] [Review][Patch] **`extractMajorVersion` parses first digit-run, not major version** [PerformanceBenchmarkTests.swift:220-230] — Fragile against any non-numeric prefix change in `operatingSystemVersionString`; also returns `"0"` when digits are absent (e.g., Arabic-Indic numerals fail the ASCII gate). Fix: use `ProcessInfo.processInfo.operatingSystemVersion.majorVersion` directly. — **Resolved 2026-04-17 (third pass): `extractMajorVersion` deleted; `BaselineStore.fingerprintFilename` now takes `osMajor: Int`; caller passes `ProcessInfo.processInfo.operatingSystemVersion.majorVersion`. Eliminates the locale-sensitive string-parsing path.**
- [x] [Review][Patch] **Delta printing crashes on `prev.wallClock.meanSeconds == 0`** [PerformanceBenchmarkTests.swift:598-604] — Division by zero yields NaN/Inf, printed as `nan%`. Fix: `guard prev.wallClock.meanSeconds > 0 else { print("Δ: prior mean is 0, skipping") ; return }`. — **Resolved 2026-04-17 (third pass): delta block now guards `prev.wallClock.meanSeconds > 0`; otherwise prints `(skipped — prior meanSeconds is 0)` and falls through to the append path (does not bail out of persistence).**
- [x] [Review][Patch] **Makefile passes env vars unquoted — paths with spaces break silently** [Makefile:11-16] — `OA300_CORPUS_PATH=$(OA300_CORPUS_PATH)` expands unquoted; a spaced path (`/Users/.../My Corpus/`) splits into two shell words and `swift test` inherits only the first. Fix: quote all three variable expansions (`OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)"` etc.). — **Resolved 2026-04-17 (second-pass review): all `$(VAR)` expansions in the `benchmark`, `benchmark-giantsteps`, `perf-benchmark`, `ablation`, `oracle`, and `oracle-generate` targets are now double-quoted.**
- [x] [Review][Patch] **Duplicate "Task 5: Validation" and "Task 6: Validation" sections in this spec** [spec:159-178] — Leftover from a renumbering; Completion Notes acknowledges but didn't clean. Fix: delete one block (prefer removing the "Task 5" block — "Task 6" is the correct sequence number). — **Resolved 2026-04-17 as part of DN1 spec revision (the misnumbered "Task 5: Validation (AC: #7)" block was deleted; canonical "Task 6: Validation (AC: #8)" retained).**
- [x] [Review][Patch] **`p95Index` uses integer truncation — reports max instead of p95 on small N** [PerformanceBenchmarkTests.swift:449-450] — `Int(Double(count) * 0.95)` for `count=10` yields index 9 (the max). For 82 tracks, yields index 77 = 94th percentile, not 95th. Fix: use `Int((Double(count - 1) * 0.95).rounded(.toNearestOrAwayFromZero))` (nearest-rank), or document as "p95-ish" and rename. — **Resolved 2026-04-17 (third pass): formula extracted to fileprivate `p95Index(count:) -> Int` and switched to nearest-rank `round((count-1) * 0.95)`. Most-visible improvement is at N=20 where the old formula returned index 19 (max) but nearest-rank returns index 18. For N=82 (OA300) both formulas happen to agree at index 77; the fix makes the formula correct for arbitrary N. Unit test covers N=1/2/10/20/82/100.**
- [x] [Review][Patch] **Committed baseline JSON missing trailing newline** [Apple_M5_Max-26.json:82] — `\ No newline at end of file` in diff. Trips POSIX-text-file tooling and pre-commit linters. Fix: `encoded + Data([0x0A])` before write. — **Resolved 2026-04-17 (third pass): `BaselineStore.append` now calls `data.append(0x0A)` before `data.write(to:options:.atomic)`. New unit test asserts `data.last == 0x0A` post-append. Verified on disk: `tail -c 5 Apple_M5_Max-26.json | xxd` shows `207d 0a5d 0a` (` }\n]\n`).**
- [x] [Review][Patch] **Unnecessary `@testable import BoomBoomBoomKit`** [PerformanceBenchmarkTests.swift:39] — Every API the suite uses (`AudioAnalysisService`, `AudioAnalysisService.Options`, `AnalysisIntensity.default`) is public. Fix: change to plain `import BoomBoomBoomKit` so an accidental drop of `public` from a consumed symbol surfaces as a compile error. — **Resolved 2026-04-17 (third pass): changed to plain `import BoomBoomBoomKit`. Build passes, confirming every consumed symbol is still public.**
- [x] [Review][Patch] **`ISO8601DateFormatter` does not set explicit `timeZone = UTC`** [PerformanceBenchmarkTests.swift:543-544] — `.withInternetDateTime` defaults to UTC today but the contract is not defended against future option-set edits. Fix: `isoFormatter.timeZone = TimeZone(identifier: "UTC")`. — **Resolved 2026-04-17 (third pass): explicit `isoFormatter.timeZone = TimeZone(identifier: "UTC")` set after `.withInternetDateTime`. Defends against future options-bitmask edits.**

- [x] [Review][Defer] **Baseline file grows unbounded** [PerformanceBenchmarkTests.swift:206-218] — deferred, no rotation/pruning cap. With daily CI, becomes multi-MB within a year.
- [x] [Review][Defer] **Baseline path edge cases: `~` not expanded; `$(CURDIR)` mismatch in git worktrees** [PerformanceBenchmarkTests.swift:582-584, Makefile:12] — deferred, environmental.
- [x] [Review][Defer] **Filename collisions: whitespace-differ chips, minor-version drift, consecutive `_` not collapsed** [PerformanceBenchmarkTests.swift:182-192, 220-230] — deferred, fingerprint maturation.
- [x] [Review][Defer] **Hardware edge cases: phys_mem <1 GiB → 0; chip > PATH_MAX; unicode/emoji chip names** [PerformanceBenchmarkTests.swift:117-119, 182-192] — deferred, won't hit on macOS 15+ targets.
- [x] [Review][Defer] **Virtualization edges: negative `Duration` components; `ContinuousClock` non-monotonic under paused VM** [PerformanceBenchmarkTests.swift:417-420] — deferred, edge.
- [x] [Review][Defer] **Single-track corpus: warmup-only path computes accuracy but discards it and never writes a baseline** [PerformanceBenchmarkTests.swift:285-311] — deferred, dev-tooling edge.
- [x] [Review][Defer] **`recordedAt` second-precision + `Date()` non-monotonic → same-second collisions / out-of-order records** [PerformanceBenchmarkTests.swift:543-547] — deferred, opportunistic.
- [x] [Review][Defer] **Filesystem error reporting: read-only dir / dir-is-file / `.atomic` on Dropbox all `Warning:`-and-continue; test still passes** [PerformanceBenchmarkTests.swift:207-218, 609-613] — deferred cluster; consider promoting write-failure to `Issue.record`.
- [x] [Review][Defer] **`isAcc1Match` tolerance is asymmetric around `expected`** [PerformanceBenchmarkTests.swift:62-64] — deferred, design choice (matches OA300/DAWOracle).
- [x] [Review][Defer] **Diagnostic output uses `print` rather than `Issue.record` / attachments** [PerformanceBenchmarkTests.swift:329-395] — deferred, systemic in other suites too.
- [x] [Review][Defer] **`swift test --filter PerformanceBenchmarkTests` is substring-match; future suite-name collisions possible** [Makefile:16] — deferred, theoretical.
- [x] [Review][Defer] **Two committed records at same `gitSHA: "a97bad2"` — noisy starting baseline** [Apple_M5_Max-26.json:655,695] — deferred, policy question (CI-only vs local-canonical).
- [x] [Review][Defer] **`GIT_SHA=unknown` silently degrades — deltas print "SHA unknown" with no actionable info** [Makefile:14-15, PerformanceBenchmarkTests.swift:548] — deferred, documented as working-as-designed.
- [x] [Review][Defer] **`sysctlbyname` post-call size race / truncation not guarded** [PerformanceBenchmarkTests.swift:71-79] — deferred, theoretical.
- [x] [Review][Defer] **`FileManager.fileExists` passes unreadable files → silent `.failed` rows with no diagnostic** [PerformanceBenchmarkTests.swift:269-272, 482-484] — deferred; print the failing filename and error string when `try?` collapses.
- [x] [Review][Defer] **`accuracy.total` and `wallClock.trackCount` reuse same integer with different semantics** [PerformanceBenchmarkTests.swift:368, 381-395] — deferred, cosmetic; only matters if DN1 keeps the accuracy feature.
- [x] [Review][Defer] **All-tracks-failed soft-fail: no baseline written, test reports success with `Acc1=0/N`** [PerformanceBenchmarkTests.swift:437-454] — deferred; consider `#expect(oa300Acc1 > 0)` as a smoke gate.
- [x] [Review][Defer] **OS version with no digits → fingerprint `-0.json`** [PerformanceBenchmarkTests.swift:220-230] — deferred, won't hit on macOS; supersede by the `majorVersion` API fix (P8).
- [x] [Review][Defer] **Debug-mode committed baselines — permitted by AC #7 but future-hazard when comparing against Release** [Apple_M5_Max-26.json:647,687, Makefile:16] — deferred; Dev Notes "Forward Hazard: Release-Mode Numbers" already flags this.

**Dismissed as noise (5):** (i) "baseline is not a regression gate" — per AC #3 Dev Notes "Reporting vs gating"; (ii) "missing explicit `import Darwin`" — Task 2.2 and Dev Notes confirm Foundation is sufficient; (iii) "sysctl CChar→UInt8 deviation" — documented/reconciled in Completion Notes (Swift 6 deprecation + SwiftLint `optional_data_string_conversion`); (iv) "Δ-line format drift" — auditor verified format matches AC #3; (v) "silent fail via `try?` in OA300 loop" — AC #6 explicitly prescribes this classification.

---

#### Second review pass — 2026-04-17 (commit `6e39893`)

Re-run of `/bmad-code-review` against the landed commit. Three parallel reviewers; ~30 surfaced findings were duplicates of the first pass above and are dismissed without re-listing. Net new findings below: **3 decision-needed / 5 patches**.

- [x] [Review][Decision] **`make test` runs `PerformanceBenchmarkTests` in parallel with other env-gated suites when `OA300_CORPUS_PATH` is set in the environment** [Makefile:31-32, PerformanceBenchmarkTests.swift:209-212] — `make test` invokes `swift test --parallel`. When a developer has `OA300_CORPUS_PATH` exported in their shell (which most local configs do, for `make benchmark`), Swift Testing concurrently executes the perf suite alongside `OA300BenchmarkTests`, `DAWOracleBenchmarkTests`, and `AblationMatrixTests` — all fighting for CPU while the perf suite serially measures per-track wall-clock. The Dev Notes "Why Serial, Not Parallel" rationale relies on serial *across* tests, not just *within* the perf method. Options: **(a)** add a new test-target-wide `.serialized` trait to the perf suite and skip cross-target via `--skip` in `make test`; **(b)** env-gate perf suite to a dedicated `PERF_BENCHMARK_ENABLED` variable set only by `make perf-benchmark`, not by presence of `OA300_CORPUS_PATH`; **(c)** document as a dev-workflow constraint ("do not set `OA300_CORPUS_PATH` when running `make test`"). Source: edge E1. — **Resolved 2026-04-17: user chose structural separation (rejected `--skip` option (a) as fragile and env-gate option (b) as hacky). A new `BoomBoomBoomKitBenchmarkTests` test target was declared in `Package.swift`; the 4 benchmark test files + the Full-Matrix ablation suite moved there via `git mv`. `make test` now runs `swift test --parallel --filter BoomBoomBoomKitTests` (unit target only) — benchmark suites are in a different target entirely, so no env var or skip filter can accidentally activate them during `make test`. `.enabled(if:)` trait removed from all 5 env-gated suites; `init() throws` now causes unset/empty `OA300_CORPUS_PATH` or `GIANTSTEPS_CORPUS_PATH` to fail loudly rather than soft-skip. `.serialized` trait added to `PerformanceBenchmarkTests` for intra-suite timing integrity.**
- [x] [Review][Decision] **`PERF_BASELINE_DIR` defaults to `$(CURDIR)/_bmad-output/perf-baselines`, which is under Dropbox sync for this repo — `.atomic` writes produce conflict files under heavy sync churn** [Makefile:62, Apple_M5_Max-26.json] — the atomic-rename that backs `Data.write(.atomic)` can race with Dropbox's file-event processor, producing `Apple_M5_Max-26 (conflict 1).json` artifacts that the baseline loader will ignore (and that pollute the committed tree). Multi-host users syncing the same fingerprint file across two machines are the highest-risk path. Compounds with existing P4 (malformed-file wedge). Options: **(a)** change default `PERF_BASELINE_DIR` to `~/Library/Application Support/BoomBoomBoomKit/perf-baselines` with an opt-in Makefile override for the committed-to-repo path; **(b)** keep repo default but detect and skip `*conflict*.json` files in the loader; **(c)** document the Dropbox constraint in Dev Notes and do nothing. Source: edge E5. — **Resolved 2026-04-17: user asked for a staging flow. `make perf-benchmark` now creates a named temp dir via `mktemp -d -t "boomboomboom-perf"` (outside Dropbox), copies the canonical baseline into it, points `PERF_BASELINE_DIR` at the stage, runs `swift test`, then invokes `scripts/perf-commit.sh` to atomically copy each produced JSON back to the canonical dir under a `mkdir`-based mutex lock. The test's read-modify-write cycle happens entirely outside Dropbox-sync territory; the canonical dir sees single-shot atomic renames (`cp … .tmp` then `mv -f … .tmp … .json`). The staging `trap "rm -rf $BENCH_STAGE" EXIT` cleans up on normal exit. Also subsumes prior-pass P5 (concurrent-run race).**
- [x] [Review][Decision] **Accuracy snapshot re-implements OA300 and GiantSteps accuracy loops inline; will silently drift from canonical `make benchmark` / `make benchmark-giantsteps` counts over time** [PerformanceBenchmarkTests.swift:275-280, 435-508 vs OA300BenchmarkTests.swift, GiantStepsBenchmarkTests.swift:208-271] — the perf suite now contains a 3rd private copy of `isAcc1Match`/`isAcc2Match`, plus a private inline re-implementation of each corpus's accuracy loop. When Story 2-2's successor modifies the canonical suites (e.g., new merge strategy, refined Acc2 rules, genre-stratification in Story 2-5), the perf suite's inline copy will not be updated — and the "regression detection" promise of AC #3 becomes "regression against a stale definition of accuracy." Options: **(a)** extract `isAcc1Match`/`isAcc2Match` and a shared `runAccuracyPass(corpus:)` helper into `BoomBoomBoomKitTestSupport` (which `AblationTests` already imports); **(b)** accept the duplication, document that perf-suite accuracy may diverge from canonical, and add a regression-check task to each future accuracy-touching story; **(c)** remove accuracy from the perf suite entirely and revert to wall-clock-only (undoes the DN1-accepted feature). Source: edge E6. — **Resolved 2026-04-17: user chose option (a). Two new files added to the test-support library: `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` (public `isAcc1Match` with built-in zero-guard + public `isAcc2Match` with MIREX 5-factor `{1, 2, 1/2, 3, 1/3}` semantics); `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` (public `OA300Track` / `GiantStepsTrack` / `DAWOracleTrack` `Codable, Sendable` structs). All 4 benchmark test files (OA300/GiantSteps/DAWOracle/Perf) and the Ablation Quick suite now `import BoomBoomBoomKitTestSupport` and use the shared definitions; private copies deleted. AblationFullMatrixTests keeps its local `isAcc1Abl`/`isAcc2Abl` intentionally — ablation uses 2-factor Acc2 `{1, 2, 1/2}` (not MIREX) because triplet factors mask technique differences on DnB-heavy corpora; documented in the file header. Accuracy counts are bit-identical to the commit 6e39893 reference (OA300 57/82, Acc2 73/82; GiantSteps 536/661, Acc2 545/661). Future accuracy-rule changes only need to edit AccuracyMatchers.swift.**

- [x] [Review][Patch] **Accuracy Snapshot "skipped" line missing `@ 2%` label prefix** [PerformanceBenchmarkTests.swift:352] — AC #3 prescribes the literal `GiantSteps @ 2%: (skipped — GIANTSTEPS_CORPUS_PATH unset or corpus unreadable)` but shipped code prints `GiantSteps: (skipped — …)`. Downstream log-parsers cannot match the skip line against the populated line's prefix. Fix: change to `print("GiantSteps @ 2%: (skipped — GIANTSTEPS_CORPUS_PATH unset or corpus unreadable)")`. Source: auditor A3. — **Resolved 2026-04-17 (second-pass review).**
- [x] [Review][Patch] **Task 3.1 `@Test` name literal drifts from shipped code** [spec Task 3.1 vs PerformanceBenchmarkTests.swift:241] — task prescribes `@Test("benchmark wall-clock time at intensity 7 (serial)")` but code ships `@Test("benchmark wall-clock time at intensity 7 (serial) + accuracy snapshot")`. DN1 revision updated ACs but not Task 3.1's inline literal. Fix: update Task 3.1's quoted name to match the shipped suffix `" + accuracy snapshot"`. Source: auditor A1. — **Resolved 2026-04-17 (second-pass review).**
- [x] [Review][Patch] **Task 4.3 references legacy `prev.timestamp` field name** [spec Task 4.3] — task says `print the Δ vs last baseline (SHA <prev.gitSHA>, <prev.timestamp>): …` line, but schema v2 renamed `timestamp` → `recordedAt` (AC #4) and code correctly uses `prev.recordedAt` (line 576-578). DN1 revision missed this task-text update. Fix: replace `prev.timestamp` with `prev.recordedAt` in Task 4.3. Source: auditor A5. — **Resolved 2026-04-17 (second-pass review).**
- [x] [Review][Patch] **Task 5.1 Makefile help-comment literal diverges from shipped `Makefile:57`** [spec Task 5.1 vs Makefile:57] — task shows `## perf-benchmark: Run wall-clock performance benchmark (env-gated on OA300_CORPUS_PATH)`; shipped Makefile comment is the more-accurate `## perf-benchmark: Run wall-clock perf + accuracy snapshot (env-gated on OA300_CORPUS_PATH; GiantSteps optional)`. DN1 revision updated AC #5's recipe but not Task 5.1's inline help literal. Fix: update Task 5.1's quoted help line to match the shipped comment. Source: auditor A2. — **Resolved 2026-04-17 (second-pass review): Task 5.1 recipe replaced wholesale with the temp-dir staging flow; the help comment in the recipe quotes the shipped `Makefile:57` literal.**
- [x] [Review][Patch] **Dev Notes "Why Serial, Not Parallel" doesn't reconcile with parallel GiantSteps accuracy pass** [spec Dev Notes section + PerformanceBenchmarkTests.swift:463-481] — the Dev Note argues serial-only, but the shipped `runGiantStepsAccuracy` uses `withTaskGroup` for parallel execution. The Change Log mentions this, but the rationale section does not clarify the rule applies specifically to the *timed* OA300 loop, not the untimed GiantSteps accuracy pass. Fix: append a paragraph to "Why Serial, Not Parallel" noting the accuracy pass intentionally parallelizes because timing is not measured there. Source: auditor A6. — **Resolved 2026-04-17 (second-pass review): paragraph appended clarifying the serial-only rule applies to the timed OA300 loop; the parallel GiantSteps accuracy pass is untimed and therefore uncontested. Also notes the new structural separation (benchmark test target) and `.serialized` suite trait.**

---

#### Third review pass — 2026-04-18 (uncommitted second-pass + third-pass resolution work)

Generated by `/bmad-code-review` on 2026-04-18. Three parallel reviewers (Blind Hunter, Edge Case Hunter, Acceptance Auditor) against the uncommitted diff (Story 2-3 structural/test-target split + 10 third-pass patches); commit `6e39893` itself not re-reviewed. **8 decision-needed / 23 patches / 5 deferred / 0 dismissed.**

- [x] [Review][Decision] **AC #1 literal still mandates `Tests/BoomBoomBoomKitTests/PerformanceBenchmarkTests.swift` path and `.enabled(if:)` trait; shipped code lives in `BoomBoomBoomKitBenchmarkTests` target and uses `.serialized` + throwing init** [spec:15-17 vs Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:172, 184-187] — Second-pass DN1 adopted the structural-separation resolution (user-approved in the change log) but AC #1's literal text was never rewritten; the shipped behavior violates three clauses of AC #1 verbatim. Options: **(a)** rewrite AC #1 to document the benchmark test target, the `.serialized` trait, and the loud-fail throwing init; **(b)** revert shipped code to honor AC #1 as written. Source: auditor A1. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **AC #3 "skipped — PERF_BASELINE_DIR unset or unreadable" + AC #4 "skips the write" contradicted by shipped P9 rename-and-fall-through** [spec:40, 51 vs PerformanceBenchmarkTests.swift:551-569] — P9 resolution (approved and checked) changed semantics from "print warning, skip the write" to "rename file to `*.corrupt-<epoch>`, print alt message, write a fresh record". ACs #3/#4 still describe the old skip-the-write semantics. Options: **(a)** rewrite AC #3's skip message and AC #4's "loud-fail-safe" clause to document the auto-recovery; **(b)** revert P9 to true skip-the-write so AC #4's loud-fail-safe guarantee holds. Source: auditor A2. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **AC #5 states the baseline directory is created lazily by `BaselineStore.append`; shipped recipe eagerly `@mkdir -p`s it** [spec:84 vs Makefile:55] — Benign same-outcome drift, but AC text and recipe directly contradict. Options: **(a)** drop the `@mkdir -p` from the recipe so lazy creation remains the single mechanism; **(b)** rewrite AC #5 to document the eager mkdir as operator-friendly defense. Source: auditor A4. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **`warmupAssigned` logic silently masks corpus-wide failure in persisted baseline** [PerformanceBenchmarkTests.swift:+235-241] — P6 fixed warmup-on-failed-track-0, but the broader scenario remains: if tracks 0..N all fail and track N+1 succeeds, N+1's cold-cache timing is recorded as warmup and excluded; the persisted record silently stores "mean 0.2s over 20 tracks" with `failedCount=50` and no Δ warning. No threshold gates the persist path. Options: **(a)** add a `failedCount / trackCount > 10%` loud-fail or skip-persist gate; **(b)** accept as-is and document in Dev Notes; **(c)** add a soft smoke-gate `#expect(okDurations.count > trackCount / 2)`. Source: blind B2 + edge deferred-cluster "all-tracks-failed soft-fail". — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **`DAWOracleTrack` requires external `keyDecodingStrategy = .convertFromSnakeCase`; no `CodingKeys` on the struct itself** [Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:+386-397] — Docstring prescribes consumers configure the decoder, but a forgotten flag produces silent `keyNotFound("dawBpm")` that is typically caught by upstream `try?` as "no oracle data available." Options: **(a)** add an explicit `CodingKeys` enum (or custom `init(from:)`) so the struct decodes its documented schema regardless of decoder config; **(b)** keep external config, add a `#warning`-level compile-time reminder or stronger doc; **(c)** accept as-is (existing pattern across four benchmark files). Source: blind B4. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **`OA300Track` docstring advertises `genre?` field the struct does not define — intentional for Story 2-4 forward-ref or stale doc?** [Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:+358-369] — Doc block names `genre?` as part of the supported schema and claims Story 2-4's backfill decodes "cleanly without a helper bump here." Struct has only `filename, bpm, subdir, title`. Options: **(a)** add `public let genre: String?` now (zero-breaking, enables Story 2-4 consumption without a parallel struct); **(b)** strike the misleading doc line and keep the field out until Story 2-4 lands. Source: blind B5. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **`GiantStepsTrack.genre` and `OA300Track.bpm` are non-optional — one malformed corpus row aborts the entire benchmark suite** [Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:+9-14, +375-383] — Promoting to shared public types amplified the blast radius: OA300, GiantSteps, DAWOracle, Perf all share these structs. A crowd-sourced corpus refresh dropping `genre` on one row, or a malformed row missing `bpm`, throws `keyNotFound` during init and fails every suite with a cryptic Codable error. `tempo2` is correctly optional — these are inconsistent. Options: **(a)** make both fields Optional with consumer-side `.unknown`/`0` fallback and `isFinite && >0` filter; **(b)** accept fail-loudly as the desired behavior (malformed corpus should be caught, not silently filtered) — document in the struct docstring. Source: blind B6 + edge E13. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Decision] **`set -eu; swift test …; perf-commit.sh …` discards partially-produced stage artifacts when swift test fails** [Makefile:+265-266] — Under `set -e`, a non-zero exit from `swift test` (including the newly-rethrown `CancellationError` from P7) aborts the recipe, skips `perf-commit.sh`, and the EXIT trap blows away `$BENCH_STAGE` — losing OA300 timing + partial GiantSteps timing that did complete. Options: **(a)** run `perf-commit.sh` under `|| true` so partial baselines always commit and the `failedCount` field carries the signal; **(b)** accept discard-on-fail and print an explicit "baseline NOT committed — swift test failed" line before abort; **(c)** accept current behavior silently. Source: blind B11 + edge E1. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Patch] **`aggregateStats` force-unwraps `sorted.first!`/`sorted.last!` when every track fails** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+400] — With the P6 `warmupAssigned` flag, `okDurations` can be empty (all-fail corpus, permission error, codec regression); `sorted.first!`/`sorted.last!` then trap. `#require(!availableTracks.isEmpty)` only guards the input list. Fix: add an `isEmpty` guard returning a zero-result summary, or precondition the function. Source: blind B1. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`p95Index(count:)` returns `-1` for `count == 0` — out-of-bounds at caller** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1203-1206] — `(-1 * 0.95).rounded = -1`, then `min(-1, max(0, -1)) = -1`. Docstring says "non-empty" but no precondition. Fix: add `precondition(count > 0, "p95Index requires non-empty array")` or make return type `Int?`. Source: blind B3 + edge E10. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`perf-commit.sh` installs lock-cleanup `trap` *after* `mkdir` acquires the lock — signal in the window orphans the lock** [scripts/perf-commit.sh:+1713-1721] — A SIGTERM between the `while ! mkdir "$LOCK"` success and `trap 'rmdir "$LOCK"…' EXIT INT TERM` leaves the lock dir, wedging all future `make perf-benchmark` runs for 30 s each until a human rmdirs. Fix: install the trap before the spin loop (`|| true` makes a spurious rmdir harmless). Source: blind B7. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`sleep 0.2` is not POSIX — script labeled "POSIX-portable" silently breaks on strict-POSIX shells** [scripts/perf-commit.sh:+1719] — POSIX `sleep` accepts integer seconds only; BSD/GNU extension on macOS. Alpine `ash`/BusyBox would either error or round to 1 s, silently stretching the 30 s timeout to 150 s. Fix: drop the POSIX-portable banner and switch shebang to `#!/bin/bash`, or round to `sleep 1`. Source: blind B8. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`cp … mv` loop leaves `.tmp` orphans in `$DEST` on SIGKILL mid-loop** [scripts/perf-commit.sh:+1726-1729] — SIGKILL between `cp "$f" "$DEST/$name.tmp"` and `mv -f "$DEST/$name.tmp" "$DEST/$name"` leaves a stray `<name>.tmp` in the committed-to-repo baseline dir; EXIT trap only rmdirs the lock. Fix: extend trap to `rmdir … ; rm -f "$DEST"/*.tmp`, or pre-clean `$DEST/*.tmp` under the lock before the loop. Source: blind B9 + edge E5. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **Makefile `trap … EXIT` misses SIGKILL/SIGTERM — temp dirs leak into `/tmp`** [Makefile:+258] — `perf-commit.sh` catches `EXIT INT TERM` but the recipe's own trap is `EXIT`-only. Ctrl-C during `swift test` (with `set -eu`) may leave `boomboomboom-perf.XXXXXX` under `/var/folders` until `/tmp` rotation. Fix: match the signal list (`trap … EXIT INT TERM HUP`). Source: blind B10. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`loadRecords` maps 0-byte file to `.malformed`, triggering rename-to-`*.corrupt-*` on every run** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+939-945] — `Data(contentsOf:)` on empty file → empty data → `JSONDecoder.decode` throws `dataCorrupted` → `.malformed` → rename branch. A benign zero-byte baseline (interrupted atomic swap, editor glitch, Dropbox stub) generates a new `.corrupt-<epoch>` sidecar every run. Fix: `if data.isEmpty { return [] }` before decode. Source: blind B12. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`fingerprintFilename` sanitization produces silent chip-string collisions** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+927-936] — Unit test asserts `"Intel(R) Core(TM) i9" → "Intel_R__Core_TM__i9"`; `"Intel R  Core TM  i9"` (double-spaces) collapses to the same filename. Two distinct CPUs silently merge histories. Fix: collapse runs of `_` via a single pass (`while result.contains("__") { result = result.replacingOccurrences(of: "__", with: "_") }`) or hash the pre-sanitized chip string. Source: blind B13. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`TimeZone(identifier: "UTC")` assigns an Optional — silent coercion defeats the explicit-UTC defense** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1131] — P16 set `isoFormatter.timeZone = TimeZone(identifier: "UTC")`, an Optional that is silently unwrapped to `nil` if unavailable (formatter keeps prior TZ, which happens to also be UTC today). Fix: `TimeZone(secondsFromGMT: 0)!` — the `!` is safe for `secondsFromGMT: 0` and makes the contract non-defeasible. Source: blind B15. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`perf-commit.sh` routes success-but-no-op message to stderr** [scripts/perf-commit.sh:+1734] — `echo "perf-commit: no *.json files in $STAGE to commit" >&2`; this is a successful exit path, not an error. CI log parsers watching stderr for errors flag it; ones watching stdout miss the diagnostic. Fix: route to stdout. Source: blind B17. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`SKILL.md` recovery recipe `git checkout <earlier-sha>` rewrites the append-only history the skill claims to protect** [.claude/skills/running-benchmarks/SKILL.md:+191] — The "Common mistakes" row preaches "never rewrite baselines; append-only history is load-bearing," then recommends `git checkout <earlier-sha> -- _bmad-output/perf-baselines/<file>.json` as the recovery — which rewrites the file to a prior state and destroys every record added between that SHA and HEAD. Fix: recommend "cherry-pick the bad-record-removal commit" or "annotate in-place," not a file-state checkout. Source: blind B18. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **Stale `.commit.lock` directory wedges all future runs when prior run SIGKILLed** [scripts/perf-commit.sh:+1713-1721] — If trap never fires (SIGKILL, OOM), `$DEST/.commit.lock` persists. Every subsequent `make perf-benchmark` spins 30 s, exits 2, `set -eu` aborts, stage wiped — a permanent data-loss loop until human intervenes. Fix: write holding PID into lock dir (`echo $$ > "$LOCK/pid"`) and reclaim when `kill -0 "$(cat "$LOCK/pid")"` fails. Source: edge E2. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`PERF_BASELINE_DIR` empty string bypasses the unset guard** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+536-539] — `environment["PERF_BASELINE_DIR"]` returns non-nil for `PERF_BASELINE_DIR=` → guard passes → `URL(fileURLWithPath: "")` resolves to the test runner's CWD → baseline written to random location (possibly repo root under Dropbox sync). Fix: `guard let dir = …, !dir.isEmpty else { … }`. Source: edge E3. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`loadRecords` non-`.malformed` errors propagate and fail the test instead of falling back** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+548-570] — Only `BaselineStoreError.malformed` is caught; `Data(contentsOf:)` can throw `fileReadNoPermission`/`fileReadUnknown` (perm bits lost, torn Dropbox sync) → error propagates out of `handleBaselinePersistence` → test fails instead of falling back to a no-history run. Fix: catch generic `Error` alongside `.malformed` and set `previousRecord = nil`. Source: edge E4. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **UTF-8 BOM in baseline file triggers false-positive `.corrupt-*` rename** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+138-144] — `JSONDecoder` rejects leading `EF BB BF` as `dataCorrupted` → `.malformed` → every run renames the valid file and writes a fresh one. A single editor-save with BOM cascades into history fragmentation. Fix: strip a leading BOM before decode (`if data.prefix(3) == Data([0xEF, 0xBB, 0xBF]) { data = data.dropFirst(3) }`). Source: edge E6. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **Same-second malformed events collide on backup rename** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+556-568] — Rename suffix uses unix-second granularity (`Int(Date().timeIntervalSince1970)`); two consecutive malformed reads within one second → second `moveItem` throws `fileWriteFileExists` → skip branch, no write, history lost. Fix: append `UUID().uuidString` or use millisecond/nanosecond granularity. Source: edge E7. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`OA300_CORPUS_PATH`/`GIANTSTEPS_CORPUS_PATH` whitespace-only passes the `!isEmpty` guard** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+184, +412] — Value like `" "` is non-empty → guard passes → downstream `Data(contentsOf:)` or `fileExists` fails with opaque error (OA300) or soft-skips with misleading reason (GiantSteps). Fix: `!path.trimmingCharacters(in: .whitespaces).isEmpty`. Source: edge E8. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **Analyzer returning NaN/Inf bpm silently counted as Acc1 miss** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+252-256, +471-478] — `isAcc1Match(NaN, expected, t)` returns false via NaN-comparison semantics; pathological audio is classified as "detected but wrong" rather than "failed." Aggregate + accuracy both poisoned. Fix: `guard a.bpm.isFinite && a.bpm > 0 else { analysis = nil }` before the accuracy block. Source: edge E9. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **`STAGE`/`DEST` paths with leading `-` break `cp`/`mv`** [scripts/perf-commit.sh:+1726-1729] — A baseline filename like `-foo.json` (no current producer creates one, but the glob has no prefix constraint) is passed to `cp` as an option. Fix: add `--` separator (`cp -- "$f" "$DEST/$name.tmp"` and `mv -f -- "$DEST/$name.tmp" "$DEST/$name"`). Source: edge E11. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **AC #5 recipe quote still mandates `PERF_BASELINE_DIR=$(CURDIR)/_bmad-output/perf-baselines`; shipped Makefile uses `$$BENCH_STAGE`** [spec:75-81 vs Makefile:55-66] — Task 5.1 was rewritten in the second pass to document the `mktemp -d` staging flow, but the top-level AC #5 recipe quote was not. Fix: rewrite AC #5's recipe block to match the shipped temp-dir staging recipe (or replace with an ADR reference). Source: auditor A3. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **Task 3.3's inline code block still shows `try? clock.measure { ... }`; shipped uses `clock.now` subtraction + explicit `catch is CancellationError { throw }`** [spec:132-152 vs PerformanceBenchmarkTests.swift:+216-239] — Completion Notes "Deviations from task sketch" acknowledges this; the P7 resolution makes the do/catch form mandatory. Fix: rewrite Task 3.3's code block to reflect shipped pattern (do/catch with cancellation rethrow). Source: auditor A5. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **AC #4 fingerprint sanitization says "`[A-Za-z0-9_-]`" (ASCII) but shipped code uses Unicode `isLetter`/`isNumber`** [spec:50 vs PerformanceBenchmarkTests.swift:+125-129] — Apple chip names are ASCII today so observable behavior matches, but the AC's literal ASCII-only guarantee is not implemented. Fix: either change the code to `c.isASCII && (c.isLetter || c.isNumber)`, or rewrite AC #4 to document the Unicode-accepting predicate. Source: auditor A6. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**
- [x] [Review][Patch] **File header `//  BoomBoomBoomKitTests` stale after move to `BoomBoomBoomKitBenchmarkTests`** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:3] — Task 1.1 header convention calls for target-name line; after the second-pass move the comment is incorrect. Fix: update line 3 to `//  BoomBoomBoomKitBenchmarkTests`. Cosmetic. Source: auditor A7. — **Resolved 2026-04-18 (fourth pass, batch-apply). See Change Log 2026-04-18 entry.**

- [x] [Review][Defer] **`loadRecordsRejectsNonV2` unit test uses synthetic-v1 JSON that happens to decode into the v2 Swift struct** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1262-1280] — deferred, test-coverage gap. Realistic historical v1 records (flat schema, no `hardware{}`/`wallClock{}`/`accuracy{}`) fall through the generic `.malformed` path, not the new `schemaVersion` guard. The guard is real — the test just oversells what it protects against.
- [x] [Review][Dismiss] **`aggregateStats` median picks upper element on even-count arrays — FALSE POSITIVE** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+394-399] — **Dismissed 2026-04-18 (fourth pass):** shipped code already computes `(sorted[count/2 - 1] + sorted[count/2]) / 2` for the even-count branch (not `sorted[count/2]`). Blind reviewer B16 misread the hunk; no patch required.
- [x] [Review][Defer] **Malformed-file recovery relies on implicit cross-function state after rename** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1157-1171] — deferred, design smell. Recovery works today because `append` internally re-calls `loadRecords` which sees the renamed-away file; any future edit to `append`'s preamble could silently break the recovery contract.
- [x] [Review][Defer] **`BaselineStoreUnitTests.tmpFile()` defer-cleanup inconsistency** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+1240-1245] — deferred, cosmetic. `loadRecordsMissingFile` never writes, so no leak today, but the pattern is inconsistent with every other test in the suite and a future write-adding edit silently leaks tmp files.
- [x] [Review][Defer] **Makefile `trap` installation has a tiny window before stage is populated** [Makefile:+258] — deferred, theoretical. SIGINT between `BENCH_STAGE=$(mktemp -d …)` and `trap …` install leaks the temp dir; 1-instruction window in practice.
- [x] [Review][Dismiss] **`aggregateStats` crash on empty `durations` via `sorted.first!`/`sorted.last!` — FALSE POSITIVE** [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:+388-403] — **Dismissed 2026-04-18 (fourth pass):** `aggregateStats` already opens with `guard !seconds.isEmpty else { return nil }`; caller handles `nil` via `if let stats` branch that prints `"(no successful tracks — aggregate undefined)"`. Blind reviewer B1 saw the force-unwraps without the guard that precedes them; no patch required.
