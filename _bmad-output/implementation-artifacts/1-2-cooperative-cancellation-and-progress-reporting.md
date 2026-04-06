# Story 1.2: Cooperative Cancellation and Progress Reporting

Status: done

## Story

As an app developer building a batch library import,
I want to cancel an in-flight BPM analysis cooperatively and receive progress updates per-window,
so that my app's UI remains responsive and users can stop a long scan without blocking.

## Acceptance Criteria

1. **Given** an analysis running at intensity 7 (3 windows),
   **When** the parent `Task` is canceled between window iterations,
   **Then** the analysis throws `CancellationError` without blocking,
   **And** results from previously completed windows are not returned (no partial results).
   **Note:** `CancellationError` is thrown from `AudioAnalysisService` (the public facade), not from `BPMAnalyzer` (which remains nil-return only). Callers using `try?` get `nil` for cancellation -- backward compatible with simple usage.

2. **Given** the cancellation implementation in `AudioAnalysisService`,
   **When** coded,
   **Then** it uses an injectable `isCancelled: () -> Bool` closure parameter (defaulting to `{ Task.isCancelled }`),
   **And** tests can inject a deterministic closure to test cancellation without timing-dependent flakiness.

3. **Given** an analysis running at intensity 7 with an `onProgress` callback,
   **When** each window analysis begins,
   **Then** the callback receives a `ProgressUpdate` with `windowsCompleted` and `windowsTotal`,
   **And** the callback is called with (0, 3), (1, 3), (2, 3) for a 3-window analysis.

4. **Given** the `onProgress` closure,
   **When** declared in the API,
   **Then** it uses `@Sendable` annotation: `onProgress: (@Sendable (ProgressUpdate) -> Void)? = nil`,
   **And** `ProgressUpdate` is a new public struct conforming to `Sendable` with `windowsCompleted: Int` and `windowsTotal: Int`.

5. **Given** no `onProgress` callback is provided (default `nil`),
   **When** analysis runs,
   **Then** behavior is identical to current (no progress overhead).

6. **Given** intensity 1-5 (single window),
   **When** analysis runs with cancellation and progress,
   **Then** cancellation still checks before the single window, progress reports (0, 1).

7. **Given** `isCancelled` returns true before the first window begins,
   **When** analysis runs,
   **Then** it throws `CancellationError` before the PCM read (no audio file I/O),
   **And** the progress callback is never called.

8. **Given** a cancellation test,
   **When** a `Task` is created, analysis starts, and `task.cancel()` is called after a short delay,
   **Then** `await task.value` throws `CancellationError` (or `nil` via `try?`).

9. **Standard gating (all stories in Epics 1-4):**
   - `make fmt` + `make lint` pass before and after implementation
   - `make test` -- all existing tests pass (142+ tests)
   - `make benchmark` -- no Acc1/Acc2 regressions on OA300
   - `make ablation` -- full technique matrix completes without crashes
   - Update inline `///` doc comments for any modified public API
   - Update CLAUDE.md if public types or key behaviors change

## Tasks / Subtasks

**Execution order: Task 1 -> 2 -> 3 -> 4 -> 5 -> 6. Task 2 depends on ProgressUpdate from Task 1. Task 3 depends on the API changes from Task 2. Task 4 uses the API from Task 2. Task 5 and 6 are final validation.**

- [x] Task 1: Create `ProgressUpdate` public struct (AC: #4)
  - [x] 1.1 Create `Sources/BoomBoomBoomKit/ProgressUpdate.swift` with `public struct ProgressUpdate: Sendable` containing `windowsCompleted: Int` and `windowsTotal: Int`
  - [x] 1.2 Add standard six-line file header
  - [x] 1.3 Add `///` doc comments on the struct and both properties

- [x] Task 2: Add cancellation and progress parameters to `AudioAnalysisService` (AC: #1, #2, #3, #4, #5, #6, #7)
  - [x] 2.1 Add `isCancelled` and `onProgress` properties to `Options` struct with property-level defaults:

    ```swift
    public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }
    public var onProgress: (@Sendable (ProgressUpdate) -> Void)?
    ```

  - [x] 2.2 Refactor `Options` to use `public init() {}` pattern -- remove the memberwise init with duplicated default parameter values. Defaults live on properties only (single source of truth). Consumer customizes via mutation:

    ```swift
    // Before (duplicated defaults in init params -- remove this):
    public init(
        maxSeconds: Double = 120,
        intensity: AnalysisIntensity = .default, ...
    ) { ... }

    // After (empty init, property defaults are the only source of truth):
    public init() {}
    ```

  - [x] 2.2a Migrate existing `Options` call sites in tests and benchmarks to the mutation pattern:

    ```swift
    // Before:
    options: .init(intensity: .fastest)
    // After:
    options: { var o = Options(); o.intensity = .fastest; return o }()
    // Or (preferred for readability):
    var opts = AudioAnalysisService.Options()
    opts.intensity = .fastest
    ```

    **Affected files (AudioAnalysisService.Options only -- do NOT migrate BPMAnalyzer.Options call sites):**
    - `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (lines 152, 163, 182)
    - `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift` (lines 149, 218, 271)
    - `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift` (lines 166, 215)
    - `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` line 73 (`options: .init()`) -- already compatible, no change needed
  - [x] 2.3 Add early cancellation check BEFORE the PCM read: `if options.isCancelled() { throw CancellationError() }` -- avoids ~10MB file I/O on pre-cancelled calls
  - [x] 2.4 Modify the window loop in `analyzeBPM(url:options:)`:
    - Check `options.isCancelled()` BEFORE each window iteration -- if true, `throw CancellationError()`
    - Call `options.onProgress?(ProgressUpdate(windowsCompleted: completed, windowsTotal: total))` BEFORE each window analysis
    - Track `completed` counter, increment after each window
  - [x] 2.5 Ensure the zero-argument `analyzeBPM(url:)` convenience passes through unchanged (it already delegates to `analyzeBPM(url:options:)`)
  - [x] 2.6 Update `///` doc comments on both `analyzeBPM` overloads:
    - `analyzeBPM(url:options:)`: document cancellation (`CancellationError`) and progress behavior
    - `analyzeBPM(url:)`: add note that cancellation is supported via `Task.isCancelled` (inherited from default Options)
  - [x] 2.7 Update CLAUDE.md to document `ProgressUpdate` as a new public type

- [x] Task 3: Write cancellation tests (AC: #1, #2, #7, #8)
  - [x] 3.1 Add a new `@Suite("AudioAnalysisService -- Cancellation")` in `AudioAnalysisServiceTests.swift`
  - [x] 3.2 Test: `isCancelled` returns true before first window -> throws CancellationError

    ```swift
    @Test("isCancelled before first window throws CancellationError")
    func cancelledBeforeFirstWindow() throws {
      let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
      var opts = AudioAnalysisService.Options()
      opts.isCancelled = { true }
      #expect(throws: CancellationError.self) {
        try AudioAnalysisService.analyzeBPM(url: url, options: opts)
      }
    }
    ```

  - [x] 3.3 Test: `isCancelled` returns true after first window completes -> throws CancellationError (no partial results)

    ```swift
    @Test("isCancelled after first window throws CancellationError")
    func cancelledAfterFirstWindow() throws {
      // nonisolated(unsafe) required: @Sendable closure captures mutable var,
      // but analyzeBPM calls it synchronously (no actual concurrency).
      // Same pattern as PCMBufferReader.downsample (project-context.md).
      nonisolated(unsafe) var callCount = 0
      let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
      var opts = AudioAnalysisService.Options()
      opts.intensity = .default  // 3 windows, ensures loop iterates
      opts.isCancelled = {
        callCount += 1
        return callCount > 2  // call 1=pre-PCM, 2=pre-window-1, 3=pre-window-2 (cancel here)
      }
      #expect(throws: CancellationError.self) {
        try AudioAnalysisService.analyzeBPM(url: url, options: opts)
      }
    }
    ```

    **Call sequence:** (1) pre-PCM check, (2) pre-window-1 check, window-1 executes, (3) pre-window-2 check -> cancels. `callCount > 2` ensures window 1 actually completes before cancellation.

    **Swift 6 note:** All test closures passed to `isCancelled` or `onProgress` that capture mutable state need `nonisolated(unsafe)` on the captured variable. This is safe because `analyzeBPM` is synchronous -- the closure is called on the same thread, never concurrently. This matches the project's established pattern in `PCMBufferReader`.

  - [x] 3.4 Test: `isCancelled` never returns true -> analysis completes normally (no throw)
  - [x] 3.5 Test: Task-based cancellation throws CancellationError (async test with `withThrowingTaskGroup` + `cancelAll()`)

    ```swift
    @Test("Task cancellation throws CancellationError")
    func taskCancellation() async throws {
      let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
      let task = Task {
        try AudioAnalysisService.analyzeBPM(url: url)  // default options, Task.isCancelled auto-wired
      }
      // 200ms delay: must exceed PCM read time so cancellation flag is set
      // before the window loop checks it. This is a smoke test -- the
      // injectable closure tests (3.2-3.4) are the deterministic ground truth.
      try await Task.sleep(for: .milliseconds(200))
      task.cancel()
      do {
        _ = try await task.value
        Issue.record("Expected CancellationError")
      } catch is CancellationError {
        // expected
      }
    }
    ```

  - [x] 3.6 Test: `try?` with cancellation returns nil (backward compatibility for simple callers)

    ```swift
    @Test("try? with cancellation returns nil")
    func cancelledWithTryOptional() throws {
      let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
      var opts = AudioAnalysisService.Options()
      opts.isCancelled = { true }
      let result = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
      #expect(result == nil)
    }
    ```

- [x] Task 4: Write progress tests (AC: #3, #5, #6)
  - [x] 4.1 Add a new `@Suite("AudioAnalysisService -- Progress")` in `AudioAnalysisServiceTests.swift`
  - [x] 4.2 Test: intensity 7 reports progress (0/3), (1/3), (2/3)

    ```swift
    @Test("default intensity reports progress for each window")
    func progressDefaultIntensity() throws {
      nonisolated(unsafe) var updates: [ProgressUpdate] = []
      let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
      let expectedWindows = AnalysisIntensity.default.windowSizes.count
      var opts = AudioAnalysisService.Options()
      opts.onProgress = { updates.append($0) }
      _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
      #expect(updates.count == expectedWindows)
      for (i, update) in updates.enumerated() {
        #expect(update.windowsCompleted == i)
        #expect(update.windowsTotal == expectedWindows)
      }
    }
    ```

  - [x] 4.3 Test: intensity 1 (single window) reports progress (0/1)
  - [x] 4.4 Test: no onProgress callback -> analysis works identically to current behavior
  - [x] 4.5 Test: cancelled analysis never calls progress callback (AC: #7)

- [x] Task 5: Validate `@Sendable` and Swift 6 compliance (AC: #4)
  - [x] 5.1 Verify `@Sendable` annotation on `onProgress` closure compiles under strict concurrency
  - [x] 5.2 Verify `isCancelled` closure IS `@Sendable` (required because `Options` conforms to `Sendable` -- all stored closures must be `@Sendable`)
  - [x] 5.3 Run `make build` to confirm no concurrency warnings

- [x] Task 6: Validation (AC: #9)
  - [x] 6.1 `make fmt && make lint` -- pass
  - [x] 6.2 `make test` -- all existing + new tests pass (153 tests, 47 suites)
  - [x] 6.3 `make benchmark` -- Acc1=69.5%, Acc2=89.0% (unchanged)
  - [x] 6.4 `make benchmark-giantsteps` -- Acc1=70.0%, Acc2=79.1% (unchanged)
  - [x] 6.5 `make ablation` -- all 64 combinations complete, no crashes

## Dev Notes

### Architecture Compliance

**ADR-1 (Cancellation between windows only):** `AudioAnalysisService` checks cancellation between window iterations in the progressive retry loop. `BPMAnalyzer` remains completely stateless -- no cancellation parameter, no closure threading through internal static methods. Per-window pipeline execution is sub-second, making this granularity sufficient. Cancelled analysis throws `CancellationError`.

**ADR-2 (Progress via @Sendable callback):** `ProgressUpdate` struct with `windowsCompleted`/`windowsTotal`. Per-track granularity, not per-pipeline-stage. `@Sendable` required because the closure may be passed from a `@MainActor`-isolated context (e.g., updating a progress bar) into a non-isolated static method.

ADR-1 and ADR-2 land as a single story since both modify the same window iteration loop in `AudioAnalysisService.analyzeBPM(url:options:)`.

### Key Design Decisions

**Injectable `isCancelled` closure (not just `Task.isCancelled`):** The closure parameter enables deterministic testing without timing-dependent flakiness. Default value `{ Task.isCancelled }` means consumers get automatic structured concurrency support. Tests inject `{ true }` or counter-based closures for precise control.

**Both closures MUST be `@Sendable`:** `Options` conforms to `Sendable`, so all stored closures must be `@Sendable`. This is a structural requirement of Swift 6 strict concurrency -- even though `analyzeBPM` calls the closures synchronously, the `Sendable` conformance on the containing struct enforces it. Test closures that capture mutable state need `nonisolated(unsafe)` on the captured variable (safe because the call is synchronous -- same pattern as `PCMBufferReader.downsample`).

**Progress callback BEFORE window analysis (not after):** Consumer sees (0/3), (1/3), (2/3) -- the update fires before work starts, so the UI shows "starting window N". There is no (N/N) "done" callback -- completion is implicit in the returned result. This is intentional: the function return itself signals completion. This matches the architecture spec. **Progress tracks windows attempted, not windows that produced results** -- if a window returns nil (silence/too-short), `completed` still increments so the progress bar advances.

**No partial results:** When cancellation occurs, the analysis throws `CancellationError`. Previously completed window results are discarded. This matches FR14's intent (no partial BPM results). Consumers who want partial-result semantics should manage windows themselves.

**`CancellationError` instead of `nil`:** `analyzeBPM` already `throws` (for `PCMBufferReaderError`), so throwing `CancellationError` doesn't change the function signature. This makes cancellation unambiguous -- `nil` return means "no BPM detected" (silence/too-short), `CancellationError` means "user cancelled." Callers using `try?` still get `nil` for both (backward compatible). The "analyzers never throw" rule (project-context.md) applies to `BPMAnalyzer`/`LUFSAnalyzer` (internal), not to `AudioAnalysisService` (public facade). FR14 says "returns nil" but its intent is "no partial results" -- `CancellationError` honors that intent with better semantics.

**Consumer guidance for custom `isCancelled`:** The default `{ Task.isCancelled }` works automatically with structured concurrency. Consumers who provide a custom closure must ensure their cancellation flag is thread-safe -- Swift closures capture variables by reference, but `@Sendable` requires the captured state to be safe for concurrent access. Recommended pattern: use an `Atomic<Bool>` or check `Task.isCancelled` (the default). Do NOT use a bare `var cancelled = false` -- Swift 6 will reject the mutable capture in a `@Sendable` closure.

### Current Window Loop (AudioAnalysisService.swift:95-114)

```swift
for windowSeconds in options.intensity.windowSizes {
    guard
        let bpmResult = BPMAnalyzer.estimateBPM(
            samples: samples, sampleRate: sampleRate,
            options: .init(
                analysisWindowSeconds: windowSeconds,
                intensity: options.intensity,
                enableTrace: options.enableTrace)
        )
    else {
        continue
    }
    windowResults.append(bpmResult)
    if options.intensity.progressiveThreshold == nil {
        break
    }
}
```

**Modified method pseudocode:**

```swift
// Early cancellation check -- avoid ~10MB PCM read on pre-cancelled calls
if options.isCancelled() { throw CancellationError() }

let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(...)

let windowSizes = options.intensity.windowSizes
let total = windowSizes.count
var completed = 0

for windowSeconds in windowSizes {
    if options.isCancelled() { throw CancellationError() }
    options.onProgress?(ProgressUpdate(windowsCompleted: completed, windowsTotal: total))

    guard
        let bpmResult = BPMAnalyzer.estimateBPM(
            samples: samples, sampleRate: sampleRate,
            options: .init(
                analysisWindowSeconds: windowSeconds,
                intensity: options.intensity,
                enableTrace: options.enableTrace)
        )
    else {
        completed += 1
        continue
    }
    windowResults.append(bpmResult)
    completed += 1
    if options.intensity.progressiveThreshold == nil {
        break
    }
}
```

### Options Init Pattern: `public init() {}`

**Rule:** Defaults live on properties only. The explicit init is empty. No memberwise init with duplicated default parameter values.

```swift
public struct Options: Sendable {
    public var maxSeconds: Double = 120
    public var intensity: AnalysisIntensity = .default
    public var mergeStrategy: CandidateMergeStrategy = .maxConfidence
    public var enableTrace: Bool = false
    public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }
    public var onProgress: (@Sendable (ProgressUpdate) -> Void)?

    public init() {}
}
```

**Why:** The current `Options` has every default stated twice (property default + init parameter default). If they diverge, behavior silently changes. Single source of truth eliminates this class of bug.

**Consumer usage:**
```swift
// Simple (all defaults):
let result = try AudioAnalysisService.analyzeBPM(url: url)

// Customized:
var opts = AudioAnalysisService.Options()
opts.intensity = .fastest
opts.isCancelled = { myAtomicFlag.load(ordering: .relaxed) }
let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
```

**Migration:** This removes the existing memberwise init. All call sites using `.init(intensity: .fastest)` must switch to the mutation pattern. Search `Tests/` and `Sources/` for `Options(` to find all sites.

### Sendable Constraint on Options

`AudioAnalysisService.Options` is `Sendable`. All stored closures must be `@Sendable`. Both `isCancelled: @Sendable () -> Bool` and `onProgress: (@Sendable (ProgressUpdate) -> Void)?` must use `@Sendable`.

**`Task.isCancelled` as default:** `Task.isCancelled` is a static property that returns `Bool`, and `{ Task.isCancelled }` is a closure literal that captures nothing and is inherently `@Sendable`.

### Files to Modify/Create

1. **CREATE:** `Sources/BoomBoomBoomKit/ProgressUpdate.swift` -- new public struct
2. **MODIFY:** `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` -- `Options` struct + window loop
3. **MODIFY:** `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` -- new test suites
4. **MODIFY:** `CLAUDE.md` -- add ProgressUpdate to public types list

### What NOT to Do

- Do NOT add cancellation parameters to `BPMAnalyzer` -- it remains stateless with no cancellation awareness (ADR-1)
- Do NOT add per-pipeline-stage progress -- progress is per-window only (ADR-2)
- Do NOT return partial results on cancellation -- throw `CancellationError` (FR14 intent: no partial BPM results)
- Do NOT throw `CancellationError` from `BPMAnalyzer` or `LUFSAnalyzer` -- the "analyzers never throw" rule still applies to internal types. Only `AudioAnalysisService` (the public facade) throws for cancellation
- Do NOT add a batch queue or task runner -- the library provides primitives, consumer manages orchestration
- Do NOT add `effectiveIntensity` to `AudioAnalysisResult` -- that's an Epic 4 concern (ML degradation)
- Do NOT change `BPMAnalyzer.estimateBPM()` signature
- Do NOT change any DSP math or technique gating logic
- Do NOT touch buffer management code (Story 1-1 scope)
- Do NOT add confidence-based early exit logic -- `progressiveThreshold` is computed but not consumed in the current loop; it is reserved for future use
- Do NOT split `Options` into separate structs (e.g., separating closures from data) -- all fields have defaults and belong together. Revisit only if Epic 4 ML hooks push the field count significantly higher
- Do NOT check cancellation mid-window -- cancellation is checked between windows only, never during a `BPMAnalyzer.estimateBPM()` call (ADR-1). Per-window execution is sub-second

### Previous Story Intelligence (Story 1-1)

**Learnings:**

- `PipelineBuffers` stays `internal` (not `private`) because `computeFourierTempogram` is test-accessible -- if you need to reference `PipelineBuffers` from tests, it's already accessible
- Standard gating works: `make fmt` before `make lint`, run test/benchmark/ablation after each structural change
- SwiftLint catches orphaned doc comments -- avoid placing `//` comments between `///` doc comment blocks and their target declarations
- The `Options` struct pattern is established for both `AudioAnalysisService.Options` and `BPMAnalyzer.Options` -- follow the same pattern for new parameters (defaulted fields, memberwise init with defaults)

**Benchmark baselines (must not regress):**

- OA300: Acc1=69.5% (57/82), Acc2=89.0% (73/82), wall-clock 1m53s
- GiantSteps: Acc1=70.0% (465/664), Acc2=79.1% (525/664), wall-clock 1m10s

**Code patterns established:**

- Six-line file headers
- `// MARK: -` section dividers
- `@Suite("Name")` with descriptive names
- `#require` for preconditions, `#expect` for assertions
- Synthetic click tracks via `createClickTrackWAV` in test files

### Testing Strategy

**New tests required (estimated 8-10 tests):**

- Cancellation: 4 tests (before first window, after first window, never cancelled, Task-based async)
- Progress: 4 tests (3-window sequence, single window, no callback, cancelled never calls progress)

**Test fixture:** Use `Meta_Man.mp3` (existing real audio fixture) for all tests. Synthetic click tracks are not needed -- this story tests the service layer, not DSP accuracy.

**Async test for Task cancellation:** Use `Task { ... }` + `task.cancel()` + `await task.value`. The 200ms delay before cancellation must exceed the PCM read time so the flag is set before the window loop checks -- the injectable closure tests are the deterministic ground truth. The async test is a smoke test for real-world structured concurrency behavior.

**Per-task checkpoint:** Run `make test` after Tasks 2, 3, and 4. Run `make benchmark` after Task 4 (final structural change). Run full validation (Task 6) after Task 5.

### Project Structure Notes

- `ProgressUpdate.swift` is a new file in `Sources/BoomBoomBoomKit/` -- ships with the library (goes to `main`)
- No new SPM targets or dependencies
- No new Makefile targets
- CLAUDE.md public types list gains `ProgressUpdate`

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#ADR-1] Cancellation between windows only
- [Source: _bmad-output/planning-artifacts/architecture.md#ADR-2] Progress via @Sendable callback closure
- [Source: _bmad-output/planning-artifacts/architecture.md#Cancellation-Progress-Pattern] Cancellation & progress implementation pattern
- [Source: _bmad-output/planning-artifacts/epics.md#Story-1.2] Full acceptance criteria and file hints
- [Source: _bmad-output/planning-artifacts/prd.md#FR11-FR14] Cancellation and progress functional requirements
- [Source: _bmad-output/project-context.md#Rule-Language] Options struct pattern, Sendable requirements
- [Source: _bmad-output/implementation-artifacts/1-1-internal-buffer-reuse-in-bpm-pipeline.md] Previous story learnings and benchmark baselines

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Task cancellation async test: story spec used `Task` + `task.cancel()` with 200ms delay, but analysis completes in ~250ms making it racy. Changed to `withThrowingTaskGroup` + `cancelAll()` for deterministic behavior. The injectable closure tests (3.2-3.4) remain the primary deterministic ground truth.

### Completion Notes List

- Created `ProgressUpdate` public struct with `Sendable` conformance, doc comments
- Refactored `AudioAnalysisService.Options` from memberwise init to `public init() {}` pattern (single source of truth for defaults)
- Added `isCancelled: @Sendable () -> Bool` and `onProgress: (@Sendable (ProgressUpdate) -> Void)?` to Options
- Added early cancellation check before PCM read, per-window cancellation check and progress reporting in window loop
- Migrated 7 `AudioAnalysisService.Options` call sites across 3 test files to mutation pattern
- Added 5 cancellation tests and 4 progress tests (9 new tests total, 153 tests now passing)
- Updated CLAUDE.md with ProgressUpdate in public types list and AudioAnalysisService description
- All doc comments updated on both `analyzeBPM` overloads

### File List

- `Sources/BoomBoomBoomKit/ProgressUpdate.swift` (NEW)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (MODIFIED)
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (MODIFIED)
- `Tests/BoomBoomBoomKitTests/OA300BenchmarkTests.swift` (MODIFIED)
- `Tests/BoomBoomBoomKitTests/GiantStepsBenchmarkTests.swift` (MODIFIED)
- `CLAUDE.md` (MODIFIED)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (MODIFIED)
- `_bmad-output/implementation-artifacts/1-2-cooperative-cancellation-and-progress-reporting.md` (MODIFIED)

## Benchmark Results (Epic 1 Tracking)

Carry forward from Story 1-1. Update after implementation.

### OA300 Corpus (82 tracks, Rekordbox ground truth)

| Story | Acc1 | Acc2 | Wall-clock (82 tracks) | Notes |
|-------|------|------|----------------------|-------|
| 1-1 post-review | 69.5% (57/82) | 89.0% (73/82) | 1m53s (user 219s, sys 3s) | Buffer reuse, no accuracy change |
| 1-2 | 69.5% (57/82) | 89.0% (73/82) | 1m54s | Cancellation + progress, no accuracy change |

### GiantSteps Tempo Dataset (664 EDM tracks, crowdsourced ground truth v2)

| Story | Acc1 | Acc2 | Wall-clock (664 tracks) | Notes |
|-------|------|------|------------------------|-------|
| 1-1 post-review | 70.0% (465/664) | 79.1% (525/664) | 1m10s (user 1130s, sys 12s) | Buffer reuse baseline |
| 1-2 | 70.0% (465/664) | 79.1% (525/664) | 1m05s | Cancellation + progress, no accuracy change |

### Review Findings

Code review (2026-04-05): 3-layer adversarial review (Blind Hunter, Edge Case Hunter, Acceptance Auditor). All 10 Blind Hunter findings dismissed as noise/false positives. Edge Case Hunter: 0 unhandled paths. Acceptance Auditor: all 9 ACs satisfied, 0 violations. Clean review.

## Change Log

- 2026-04-05: Code review complete. 3-layer adversarial review passed clean (0 patch, 0 decision-needed, 0 deferred, 10 dismissed). Status: done.
- 2026-04-05: Implementation complete. Created ProgressUpdate struct, added isCancelled/onProgress to Options, refactored Options to public init() {} pattern, migrated 7 call sites, added 9 tests (5 cancellation + 4 progress). All 153 tests pass. OA300 Acc1=69.5%/Acc2=89.0%, GiantSteps Acc1=70.0%/Acc2=79.1%, ablation 64/64 -- all unchanged.
- 2026-04-05: Party mode review (Apple docs + Axiom validation). Fixed: Task 3.3 callCount bug (>1 -> >2), explicit call site list in Task 2.2a, doc comment coverage for both analyzeBPM overloads, 50ms -> 200ms async test delay, documented no (N/N) completion callback.
- 2026-04-04: Story created by BMad create-story workflow. Ready for dev.
