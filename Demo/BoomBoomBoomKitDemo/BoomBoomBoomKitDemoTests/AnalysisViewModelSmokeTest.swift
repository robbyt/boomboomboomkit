import AppKit
import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKitDemo

@Suite("AnalysisViewModel smoke")
struct AnalysisViewModelSmokeTest {

  @Test("public-API wrapping produces non-nil BPM for known-musical fixture")
  @MainActor
  func wrapping() async throws {
    // AudioFixtures.url(for:extension:) returns non-optional URL and throws
    // if the fixture is missing — the throw itself is the missing-fixture
    // signal, no #require wrapping needed.
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.analyze(url: url)

    // analyze(url:) launches a Task; poll observed isAnalyzing flag.
    // bpm-120-click.wav at default intensity completes in ~1-2s on M5 Max;
    // 30s ceiling fails fast on pipeline regressions.
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "analyze(url:) did not complete within 30s")

    #expect(viewModel.detectedBPM != nil)
    #expect((viewModel.confidence ?? 0) > 0)
    #expect(viewModel.fileName == "bpm-120-click.wav")
    #expect(viewModel.selectedFileURL == url)
    #expect(viewModel.errorMessage == nil)
    #expect((viewModel.elapsedSeconds ?? 0) > 0)
    // Story 5-2 AC #9 — pendingCancellations / isCancelling reach empty
    // after the single in-flight task completes. The cleanup Task removes
    // the per-task UUID from both `inFlightTasks` and
    // `pendingCancellations`, so a successful analyze() leaves
    // `isCancelling == false` and the underlying set empty.
    #expect(viewModel.isCancelling == false)
    #expect(viewModel.pendingCancellations.isEmpty)
  }

  // MARK: - Drop Validator (Story 5-2 DD #11 / DD #13)

  @Test("validateDropPayload rejects empty payload")
  @MainActor
  func rejectsEmptyDrop() {
    let result = AnalysisViewModel.validateDropPayload([])
    #expect(result == .failure(.empty))
  }

  @Test("validateDropPayload rejects multi-file payload")
  @MainActor
  func rejectsMultiFileDrop() {
    let urls = [
      URL(fileURLWithPath: "/tmp/a.wav"),
      URL(fileURLWithPath: "/tmp/b.wav"),
    ]
    let result = AnalysisViewModel.validateDropPayload(urls)
    #expect(result == .failure(.multipleFiles))
  }

  // Codex H5 — `.m4b` and `.mp4` conform to `.mpeg4Audio` and would have
  // silently widened the supported set via `UTType.conforms(to:)`.
  // Extension-matching prevents that. The 5 negative cases below cover
  // the H5 widening risk PLUS three obviously-unrelated extensions.
  @Test(
    "validateDropPayload rejects unsupported extensions",
    arguments: ["txt", "ogg", "png", "m4b", "mp4"]
  )
  @MainActor
  func rejectsUnsupportedType(_ ext: String) {
    let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
    let result = AnalysisViewModel.validateDropPayload([url])
    #expect(result == .failure(.unsupportedType(extension: ext)))
  }

  @Test(
    "validateDropPayload accepts the 6 supported extensions",
    arguments: ["wav", "aiff", "mp3", "flac", "m4a", "caf"]
  )
  @MainActor
  func acceptsSupportedTypes(_ ext: String) throws {
    let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
    let result = AnalysisViewModel.validateDropPayload([url])
    guard case .success(let resolved) = result else {
      Issue.record("expected .success for .\(ext); got \(result)")
      return
    }
    #expect(resolved == url)
  }

  @Test("validateDropPayload uppercase extensions are accepted (case-insensitive)")
  @MainActor
  func acceptsUppercaseExtensions() throws {
    let url = URL(fileURLWithPath: "/tmp/sample.WAV")
    let result = AnalysisViewModel.validateDropPayload([url])
    guard case .success(let resolved) = result else {
      Issue.record("expected .success for uppercase .WAV; got \(result)")
      return
    }
    #expect(resolved == url)
  }

  // MARK: - handleDrop State Transitions (Story 5-2 DD #11)

  // Axiom A5 — paired-args via `zip(...)` per swift-testing.md:213-217.
  // Verifies that each failure path populates `errorMessage` with the
  // verbatim AC #2 string AND leaves `isAnalyzing == false` /
  // `detectedBPM == nil` (no DSP work runs for an invalid drop).
  @Test(
    "handleDrop populates errorMessage on validation failure",
    arguments: zip(
      [
        [],
        [URL(fileURLWithPath: "/tmp/a.wav"), URL(fileURLWithPath: "/tmp/b.wav")],
        [URL(fileURLWithPath: "/tmp/sample.txt")],
      ],
      [
        "No audio file detected in drop.",
        "Drop a single audio file (batch drop is not supported).",
        "Unsupported file type: txt. Supported: WAV, AIFF, MP3, FLAC, M4A, CAF.",
      ]
    )
  )
  @MainActor
  func handleDropStateTransitions(_ urls: [URL], _ expected: String) {
    let viewModel = AnalysisViewModel()
    #expect(viewModel.handleDrop(urls) == false)
    #expect(viewModel.errorMessage == expected)
    #expect(viewModel.isAnalyzing == false)
    #expect(viewModel.detectedBPM == nil)
  }

  // MARK: - generateConfigSnippet (Story 5-3 AC #3 / AC #10 / DD #7)

  // Intensity formatting per DD #7: rawValue 1/7/8/10 emit the named
  // constants `.fastest` / `.default` / `.thorough` / `.maximum`;
  // 2/3/4/5/6/9 emit `AnalysisIntensity(rawValue: N)`. Paired-args via
  // `zip(...)` per Axiom A5 / Story 5-2 precedent.
  @Test(
    "generateConfigSnippet emits named constants for 1/7/8/10, raw literal otherwise",
    arguments: zip(
      [1, 7, 8, 10, 2, 5, 9],
      [
        ".fastest",
        ".default",
        ".thorough",
        ".maximum",
        "AnalysisIntensity(rawValue: 2)",
        "AnalysisIntensity(rawValue: 5)",
        "AnalysisIntensity(rawValue: 9)",
      ]
    )
  )
  @MainActor
  func generateConfigSnippetIntensityFormatting(_ raw: Int, _ expectedLiteral: String) {
    let snippet = AnalysisViewModel.generateConfigSnippet(
      intensity: AnalysisIntensity(rawValue: raw),
      mergeStrategy: .maxConfidence
    )
    let expected = [
      "var opts = AudioAnalysisService.Options()",
      "opts.intensity = \(expectedLiteral)",
      "opts.mergeStrategy = .maxConfidence",
      "let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)",
    ].joined(separator: "\n")
    #expect(snippet == expected)
  }

  // Merge-strategy formatting per DD #7: always `.\(rawValue)` for all
  // 8 cases — rawValue strings match the case names verbatim.
  @Test(
    "generateConfigSnippet emits .rawValue for all 8 merge strategies",
    arguments: CandidateMergeStrategy.allCases
  )
  @MainActor
  func generateConfigSnippetMergeStrategyFormatting(_ strategy: CandidateMergeStrategy) {
    let snippet = AnalysisViewModel.generateConfigSnippet(
      intensity: .default,
      mergeStrategy: strategy
    )
    #expect(snippet.contains("opts.mergeStrategy = .\(strategy.rawValue)"))
  }

  // Snippet shape sanity per DD #7 + AC #10 Task 3.3: exactly 4 lines,
  // contains literal `yourURL`, contains `try AudioAnalysisService.
  // analyzeBPM`, no leading/trailing whitespace, last line shape.
  @Test("generateConfigSnippet shape: 4 lines, yourURL placeholder, no surrounding whitespace")
  @MainActor
  func generateConfigSnippetShape() {
    let snippet = AnalysisViewModel.generateConfigSnippet(
      intensity: .default,
      mergeStrategy: .maxConfidence
    )
    let lines = snippet.components(separatedBy: "\n")
    #expect(lines.count == 4)
    #expect(snippet.contains("yourURL"))
    #expect(snippet.contains("try AudioAnalysisService.analyzeBPM"))
    #expect(!snippet.hasPrefix(" "))
    #expect(!snippet.hasPrefix("\n"))
    #expect(!snippet.hasSuffix(" "))
    #expect(!snippet.hasSuffix("\n"))
    #expect(
      lines.last == "let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)"
    )
  }

  // MARK: - cancelInFlight (Story 5-3 AC #4 / DD #4 / DD #12)

  // No-op when idle — `inFlightTasks` is empty, the for-loop body
  // never runs, no observed-state mutation occurs.
  @Test("cancelInFlight no-op when idle")
  @MainActor
  func cancelInFlightIdle() {
    let viewModel = AnalysisViewModel()
    viewModel.cancelInFlight()
    #expect(viewModel.isAnalyzing == false)
    #expect(viewModel.pendingCancellations.isEmpty)
    #expect(viewModel.detectedBPM == nil)
  }

  // With an in-flight task: drop fixture, immediately cancel, poll for
  // completion. The cancel-during-prologue path runs synchronously on
  // MainActor BEFORE the Task body re-enters; the library's first
  // isCancelled poll at window boundary 0 fires. DD #12 Branch A: the
  // cancelled current task's `.failure(is CancellationError)` arm
  // resets isAnalyzing = false and leaves result fields untouched.
  @Test("cancelInFlight cancels in-flight task; result fields stay empty")
  @MainActor
  func cancelInFlightActive() async throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.analyze(url: url)
    viewModel.cancelInFlight()
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "cancelInFlight did not drain within 30s")
    // DD #12 Branch A: cancelled task does NOT mutate result fields.
    #expect(viewModel.detectedBPM == nil)
    // The cleanup Task drains pendingCancellations once the cancelled
    // task acknowledges; poll briefly for the set to empty.
    let drainDeadline = ContinuousClock.now.advanced(by: .seconds(5))
    while !viewModel.pendingCancellations.isEmpty && ContinuousClock.now < drainDeadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(viewModel.pendingCancellations.isEmpty)
  }

  // MARK: - Manual re-run uses current options (Story 5-3 AC #5 / Task 3.6)

  // Bare-API exercise — directly mutates `options.mergeStrategy` and
  // calls `analyze(url:)` again. Does NOT exercise the Picker.onChange
  // wiring; that's verified in the manual smoke (AC #11). Numeric
  // equality is NOT asserted — .dedup may produce slightly different
  // output than .maxConfidence.
  @Test("manual re-run with mutated options completes to a non-nil BPM")
  @MainActor
  func manualReRunUsesCurrentOptions() async throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.analyze(url: url)
    let initialDeadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < initialDeadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "initial analyze did not complete within 30s")
    try #require(viewModel.detectedBPM != nil, "expected non-nil BPM after initial analyze")
    try #require(
      viewModel.selectedFileURL != nil,
      "selectedFileURL should be retained after initial analyze"
    )
    // Mutate options bare-API (not via Picker).
    viewModel.options.mergeStrategy = .dedup
    viewModel.analyze(url: viewModel.selectedFileURL!)
    let rerunDeadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < rerunDeadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "re-run analyze did not complete within 30s")
    #expect(viewModel.detectedBPM != nil)
  }

  // MARK: - formatResultRow (Story 5-3 AC #7 / DD #15 / Task 3.7)

  // Happy path: all-finite inputs return .success with correctly-
  // formatted fields per Story 5-2 DD #10.
  @Test("formatResultRow returns .success for all-finite inputs")
  @MainActor
  func formatResultRowHappyPath() {
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: 120.0,
      confidence: 0.85,
      effectiveIntensity: .default,
      elapsedSeconds: 1.23
    )
    guard case .success(let row) = result else {
      Issue.record("expected .success for finite inputs; got \(result)")
      return
    }
    #expect(row.fileName == "test.wav")
    #expect(row.bpm == "120.0 BPM")
    #expect(row.confidence == "85%")
    #expect(row.intensity == "7")
    #expect(row.elapsed == "1.23s")
  }

  // NaN guard parameterized over bpm/confidence/elapsedSeconds slots.
  // Any NaN in a finite-required field returns .failure(.nonFinite).
  @Test(
    "formatResultRow rejects NaN in bpm/confidence/elapsedSeconds",
    arguments: 0..<3
  )
  @MainActor
  func formatResultRowNaNGuard(_ slot: Int) {
    let bpm: Double = (slot == 0) ? .nan : 120.0
    let confidence: Double = (slot == 1) ? .nan : 0.85
    let elapsed: Double = (slot == 2) ? .nan : 1.23
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: bpm,
      confidence: confidence,
      effectiveIntensity: .default,
      elapsedSeconds: elapsed
    )
    #expect(result == .failure(.nonFinite))
  }

  // Inf guard parameterized over (bpm/confidence/elapsed) x (±Inf).
  // 6 cases: slot 0/1 = bpm ±Inf, 2/3 = confidence ±Inf, 4/5 = elapsed
  // ±Inf. Same .failure(.nonFinite) for all.
  @Test(
    "formatResultRow rejects ±Inf in bpm/confidence/elapsedSeconds",
    arguments: 0..<6
  )
  @MainActor
  func formatResultRowInfGuard(_ slot: Int) {
    let isNeg = slot % 2 == 1
    let infValue: Double = isNeg ? -.infinity : .infinity
    let bpm: Double = (slot / 2 == 0) ? infValue : 120.0
    let confidence: Double = (slot / 2 == 1) ? infValue : 0.85
    let elapsed: Double = (slot / 2 == 2) ? infValue : 1.23
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: bpm,
      confidence: confidence,
      effectiveIntensity: .default,
      elapsedSeconds: elapsed
    )
    #expect(result == .failure(.nonFinite))
  }

  // Missing-fields: mixed nil/non-nil pattern (bpm non-nil + confidence
  // nil) returns .failure(.missingFields). Callers fall through to
  // their existing empty / errorMessage logic.
  @Test("formatResultRow rejects partial-state (bpm non-nil, confidence nil)")
  @MainActor
  func formatResultRowMissingFields() {
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: 120.0,
      confidence: nil,
      effectiveIntensity: .default,
      elapsedSeconds: 1.23
    )
    #expect(result == .failure(.missingFields))
  }

  // MARK: - formatResultRow range guards (P4 + P5, Story 5-3 code review 2026-05-20)

  // P5: bpm must be > 0. Library contract is "positive finite BPM"; a
  // zero or negative bpm passes isFinite but is physically nonsensical
  // and routes through .nonFinite to the same "Internal error" UI path
  // as NaN/Inf. Slot encodes the bpm value to test.
  //   0 -> bpm == 0
  //   1 -> bpm == -1
  @Test(
    "formatResultRow rejects non-positive bpm",
    arguments: [0, 1]
  )
  @MainActor
  func formatResultRowBPMRangeGuard(_ slot: Int) {
    let bpmValues: [Double] = [0.0, -1.0]
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: bpmValues[slot],
      confidence: 0.8,
      effectiveIntensity: .default,
      elapsedSeconds: 1.23
    )
    #expect(result == .failure(.nonFinite))
  }

  // P5: confidence must be in [0, 1]. Library contract is "[0, 1]
  // inclusive"; out-of-range silently rendered as "105%" / "-1%" pre-
  // patch. Slot encodes the confidence value:
  //   0 -> confidence == 1.5  (above range)
  //   1 -> confidence == -0.1 (below range)
  @Test(
    "formatResultRow rejects out-of-range confidence",
    arguments: [0, 1]
  )
  @MainActor
  func formatResultRowConfidenceRangeGuard(_ slot: Int) {
    let confidenceValues: [Double] = [1.5, -0.1]
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: 120.0,
      confidence: confidenceValues[slot],
      effectiveIntensity: .default,
      elapsedSeconds: 1.23
    )
    #expect(result == .failure(.nonFinite))
  }

  // P4: elapsedSeconds must be >= 0. Negative elapsed (clock skew,
  // monotonic-clock anomaly, library bug) rendered as "-0.50s" pre-
  // patch; now routes through .nonFinite.
  @Test("formatResultRow rejects negative elapsedSeconds")
  @MainActor
  func formatResultRowElapsedNegativeGuard() {
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: 120.0,
      confidence: 0.8,
      effectiveIntensity: .default,
      elapsedSeconds: -0.5
    )
    #expect(result == .failure(.nonFinite))
  }

  // P5 boundary values: confidence == 0.0 and confidence == 1.0 are
  // INCLUSIVE per the library contract; both should succeed.
  @Test(
    "formatResultRow accepts confidence boundary values 0.0 and 1.0",
    arguments: [0, 1]
  )
  @MainActor
  func formatResultRowConfidenceBoundaryAccepts(_ slot: Int) {
    let confidenceValues: [Double] = [0.0, 1.0]
    let result = AnalysisViewModel.formatResultRow(
      fileName: "test.wav",
      bpm: 120.0,
      confidence: confidenceValues[slot],
      effectiveIntensity: .default,
      elapsedSeconds: 1.23
    )
    if case .failure = result {
      Issue.record("Expected .success for confidence \(confidenceValues[slot]) but got \(result)")
    }
  }

  // MARK: - copyConfigToPasteboard errorMessage lifecycle (P1, Story 5-3 code review 2026-05-20)

  // P1: a stale "Could not copy to clipboard" banner from a prior
  // failed attempt must be cleared by the next successful copy.
  // Pre-patch the errorMessage persisted indefinitely until the next
  // successful analyze cleared it (DD #16 semantic).
  //
  // Pre-conditions for "success" cleanup: errorMessage must equal the
  // exact pasteboard-failure string. Other errorMessage sources (drop
  // rejection copy, sandbox-denied) are NOT cleared — they have
  // different lifecycles (DD #16 banner-clearing semantics apply on
  // analyze-success path).
  @Test("copyConfigToPasteboard clears stale pasteboard errorMessage on success")
  @MainActor
  func copyConfigToPasteboardClearsStaleError() {
    let viewModel = AnalysisViewModel()
    // Seed a stale pasteboard-failure banner as if a prior copy
    // returned false.
    viewModel.errorMessage = "Could not copy to clipboard"
    // Subsequent successful copy clears it.
    let didCopy = viewModel.copyConfigToPasteboard()
    // setString on in-process NSPasteboard.general is expected to
    // return true on developer machines; if the run environment has
    // restricted pasteboard access the test would correctly fail at
    // this expectation.
    #expect(didCopy == true)
    #expect(viewModel.errorMessage == nil)
  }

  // P1 negative case: a non-pasteboard errorMessage (e.g., from a
  // drop-validation rejection) must NOT be cleared by a successful
  // copy — different lifecycle, different clearing path.
  @Test("copyConfigToPasteboard preserves unrelated errorMessage on success")
  @MainActor
  func copyConfigToPasteboardPreservesUnrelatedError() {
    let viewModel = AnalysisViewModel()
    viewModel.errorMessage = "No audio file detected in drop."
    let didCopy = viewModel.copyConfigToPasteboard()
    #expect(didCopy == true)
    #expect(viewModel.errorMessage == "No audio file detected in drop.")
  }

  // MARK: - Pasteboard round-trip (Story 5-3 AC #10 / Task 3.8)

  // Env-gated because NSPasteboard.general is process-wide and writing
  // pollutes the developer's actual clipboard. Default cadence
  // (`make demo-test`) skips this test; dev opts in via
  // `BBBKIT_RUN_PASTEBOARD_TEST=1 make demo-test`. Restore is best-
  // effort (string-only — multi-type clipboard payloads like images
  // or file URL lists collapse).
  @Test(
    "copyConfigToPasteboard round-trip preserves snippet (env-gated)",
    .enabled(if: ProcessInfo.processInfo.environment["BBBKIT_RUN_PASTEBOARD_TEST"] == "1")
  )
  @MainActor
  func pasteboardRoundTrip() {
    let pasteboard = NSPasteboard.general
    let priorString = pasteboard.string(forType: .string)
    defer {
      pasteboard.clearContents()
      if let priorString {
        pasteboard.setString(priorString, forType: .string)
      }
    }
    let viewModel = AnalysisViewModel()
    viewModel.options.intensity = .fastest
    viewModel.options.mergeStrategy = .median
    #expect(viewModel.copyConfigToPasteboard() == true)
    let readBack = pasteboard.string(forType: .string)
    let expected = AnalysisViewModel.generateConfigSnippet(
      intensity: .fastest,
      mergeStrategy: .median
    )
    #expect(readBack == expected)
  }
}
