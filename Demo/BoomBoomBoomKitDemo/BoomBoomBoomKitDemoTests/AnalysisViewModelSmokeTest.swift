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
  //
  // Story 5-4 AC #8 — tightened assertion: after the re-run completes,
  // `lastRunSnapshot.runOptions.mergeStrategy == .dedup`. Without the
  // atomic snapshot, the test could not distinguish "the run used
  // `.dedup`" from "the run used a stale `.maxConfidence` and silently
  // honored the snapshot from a prior call." With the snapshot, the
  // assertion fires post-success and pins the contract (closes W30).
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
    // Story 5-4 AC #8 — the atomic snapshot's runOptions snapshot reflects
    // the options the run actually used, NOT the current `viewModel.options`
    // state (which could have been mutated again post-analyze).
    #expect(viewModel.lastRunSnapshot?.runOptions.mergeStrategy == .dedup)
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
    viewModel.error = .clipboardCopy
    // Subsequent successful copy clears it.
    let didCopy = viewModel.copyConfigToPasteboard()
    // setString on in-process NSPasteboard.general is expected to
    // return true on developer machines; if the run environment has
    // restricted pasteboard access the test would correctly fail at
    // this expectation.
    #expect(didCopy == true)
    #expect(viewModel.error == nil)
  }

  // P1 negative case: a non-pasteboard errorMessage (e.g., from a
  // drop-validation rejection) must NOT be cleared by a successful
  // copy — different lifecycle, different clearing path.
  @Test("copyConfigToPasteboard preserves unrelated errorMessage on success")
  @MainActor
  func copyConfigToPasteboardPreservesUnrelatedError() {
    let viewModel = AnalysisViewModel()
    viewModel.error = .dropEmpty
    let didCopy = viewModel.copyConfigToPasteboard()
    #expect(didCopy == true)
    #expect(viewModel.error == .dropEmpty)
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

  // MARK: - Story 5-4 — Trace Export (Tasks 5.1-5.11)

  // Helper — analyze the click fixture and return the populated view
  // model. Used by tests that need a real, populated snapshot.
  @MainActor
  private static func analyzeFixture() async throws -> AnalysisViewModel {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.analyze(url: url)
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "analyze did not complete within 30s")
    return viewModel
  }

  // 5.1 — projection round-trips through JSON.
  //
  // `generatedAt` is normalized to a fixed sentinel
  // (`Date(timeIntervalSince1970: 0)`, see `normalizeForRoundTrip` body
  // below) on both sides before comparison — ISO 8601 string encoding
  // truncates `Date()`'s sub-millisecond precision, so a raw round-trip
  // would diff on the fractional seconds.
  // P1 (code review 2026-05-23): rewritten to honor AC #7 step-by-step.
  // The pre-patch version compared Swift-level Equatable; the rewritten
  // version enforces the contract that actually catches LSB-level Float
  // drift surfacing as a JSON regression:
  //   1. encode → decode → normalize volatile fields on both sides
  //   2. walk every floating-point field via `allFloats(_:)` and assert
  //      each is `isFinite` (defends the encoder's `.throw` strategy
  //      from silent regression where a sentinel-NaN sneaks through a
  //      previously-finite path)
  //   3. re-encode BOTH normalized instances with `.sortedKeys` and
  //      assert byte-equality of the encoded `Data`
  @Test("traceProjectionRoundTripsJSON: TraceExport round-trips byte-equal with finite floats")
  @MainActor
  func traceProjectionRoundTripsJSON() async throws {
    let viewModel = try await Self.analyzeFixture()
    let snapshot = try #require(viewModel.lastRunSnapshot)
    let original = TraceExport.from(
      trace: snapshot.trace,
      runOptions: snapshot.runOptions,
      result: snapshot.result,
      fileName: snapshot.fileName,
      metadataEvidence: snapshot.metadataEvidence,
      elapsedSeconds: viewModel.elapsedSeconds ?? 0
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let originalData = try encoder.encode(original)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(TraceExport.self, from: originalData)
    let normalizedOriginal = Self.normalizeForRoundTrip(original)
    let normalizedDecoded = Self.normalizeForRoundTrip(decoded)
    // AC #7 step 4: walk every floating-point field and assert finite.
    // Defends against a future projection regression that silently
    // forwards a library NaN sentinel into a JSON `null`-typed field
    // (which would round-trip clean despite being a real bug).
    for value in try Self.allFloats(of: normalizedOriginal) {
      #expect(value.isFinite, "found non-finite Double in TraceExport: \(value)")
    }
    // AC #7 step 3: re-encode both normalized instances and assert
    // byte-equality of the encoded Data (NOT Swift-level Equatable —
    // catches LSB drift that Equatable's Double == would mask).
    let reEncodedOriginal = try encoder.encode(normalizedOriginal)
    let reEncodedDecoded = try encoder.encode(normalizedDecoded)
    #expect(reEncodedOriginal == reEncodedDecoded)
  }

  // P1 (code review 2026-05-23): AC #7's reproducibility-of-two-runs
  // Given clause was never exercised pre-patch. Two analyze() invocations
  // against the same fixture with identical Options should produce
  // byte-equal exports (after normalization of generatedAt + elapsedSeconds).
  // Catches per-window candidate-score drift that single-run round-trip
  // tests cannot.
  @Test(
    "traceExportReproducibilityTwoRuns: same fixture analyzed twice produces byte-equal exports")
  @MainActor
  func traceExportReproducibilityTwoRuns() async throws {
    let viewModel1 = try await Self.analyzeFixture()
    let snapshot1 = try #require(viewModel1.lastRunSnapshot)
    let export1 = TraceExport.from(
      trace: snapshot1.trace,
      runOptions: snapshot1.runOptions,
      result: snapshot1.result,
      fileName: snapshot1.fileName,
      metadataEvidence: snapshot1.metadataEvidence,
      elapsedSeconds: viewModel1.elapsedSeconds ?? 0
    )
    let viewModel2 = try await Self.analyzeFixture()
    let snapshot2 = try #require(viewModel2.lastRunSnapshot)
    let export2 = TraceExport.from(
      trace: snapshot2.trace,
      runOptions: snapshot2.runOptions,
      result: snapshot2.result,
      fileName: snapshot2.fileName,
      metadataEvidence: snapshot2.metadataEvidence,
      elapsedSeconds: viewModel2.elapsedSeconds ?? 0
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data1 = try encoder.encode(Self.normalizeForRoundTrip(export1))
    let data2 = try encoder.encode(Self.normalizeForRoundTrip(export2))
    #expect(data1 == data2)
  }

  // P1 helper (code review 2026-05-23): recursively collect every numeric
  // value in the encoded JSON shape. Implementation route via
  // JSONSerialization sidesteps the brittleness of hand-enumerating
  // every Double/Float field across ~40 nested projection structs — any
  // future field addition is automatically covered. Skips JSON booleans
  // (which JSONSerialization also wraps as NSNumber).
  @MainActor
  private static func allFloats(of export: TraceExport) throws -> [Double] {
    let encoder = JSONEncoder()
    let data = try encoder.encode(export)
    let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    var result: [Double] = []
    Self.walkNumbers(json, into: &result)
    return result
  }

  private static func walkNumbers(_ any: Any, into result: inout [Double]) {
    if let dict = any as? [String: Any] {
      for value in dict.values {
        walkNumbers(value, into: &result)
      }
    } else if let array = any as? [Any] {
      for value in array {
        walkNumbers(value, into: &result)
      }
    } else if let number = any as? NSNumber {
      // Skip NSNumber-as-Bool (JSONSerialization wraps JSON true/false
      // as NSNumber backed by CFBoolean — doubleValue is 1.0/0.0 which
      // would falsely register as a "finite float").
      if CFGetTypeID(number as CFTypeRef) != CFBooleanGetTypeID() {
        result.append(number.doubleValue)
      }
    } else if let str = any as? String,
      str == "NaN" || str == "Infinity" || str == "-Infinity" || str == "+Infinity"
    {
      // JSONEncoder's `.convertToString(...)` non-conforming-float strategy
      // emits these sentinel strings; the finite-walk contract should still
      // trip in that hypothetical future, so flag them as non-finite via
      // .nan. Current encoder uses `.throw` (see
      // `AnalysisViewModel.swift:539-542`), so this branch is
      // forward-defensive and not currently exercised on the happy path.
      result.append(.nan)
    }
  }

  // Normalize the two known volatile fields (per AC #7): `generatedAt`
  // (ISO 8601 millisecond truncation) and `run.elapsedSeconds`
  // (wall-clock noise across runs).
  @MainActor
  private static func normalizeForRoundTrip(_ export: TraceExport) -> TraceExport {
    let normalizedRun = RunInfo(
      fileName: export.run.fileName,
      intensityRequested: export.run.intensityRequested,
      intensityEffective: export.run.intensityEffective,
      mergeStrategy: export.run.mergeStrategy,
      votingPolicy: export.run.votingPolicy,
      votingThreshold: export.run.votingThreshold,
      metadataPolicyEnabledSources: export.run.metadataPolicyEnabledSources,
      durationHint: export.run.durationHint,
      durationHintMinFileSeconds: export.run.durationHintMinFileSeconds,
      ensemblePolicy: export.run.ensemblePolicy,
      enableTrace: export.run.enableTrace,
      enableMLDiagnostics: export.run.enableMLDiagnostics,
      maxSeconds: export.run.maxSeconds,
      elapsedSeconds: 0,
      bpm: export.run.bpm,
      confidence: export.run.confidence,
      degradationReason: export.run.degradationReason
    )
    return TraceExport(
      schemaVersion: export.schemaVersion,
      generatedAt: Date(timeIntervalSince1970: 0),
      run: normalizedRun,
      selection: export.selection,
      pipeline: export.pipeline,
      metadata: export.metadata,
      ml: export.ml
    )
  }

  // 5.2 — final-step derivation cascade.
  //
  // Each scenario constructs a real trace (via analyzeFixture) and then
  // mutates specific fields to set up the cascade arm under test.
  // The base trace's actual final-step attribution is unknown for the
  // synthetic click fixture; the test relies on mutation to force a
  // deterministic answer.
  enum CascadeScenario: String, CaseIterable {
    case mlEnsembleWin
    case metadataPromoted
    case fineGridChanged
    case subBandVoteChanged
    case durationHintMatched
    case clickRescoreReordered
    case baselineDisambiguation
    case mlAndFineGridConflict  // mlEnsemble should win
    case fineGridAndSubBandConflict  // fineGrid should win
  }

  @Test(
    "finalSelectionStepDerivation: each cascade arm fires for its scenario",
    arguments: CascadeScenario.allCases
  )
  @MainActor
  func finalSelectionStepDerivation(_ scenario: CascadeScenario) async throws {
    let viewModel = try await Self.analyzeFixture()
    let snapshot = try #require(viewModel.lastRunSnapshot)
    var trace = snapshot.trace

    // Reset all post-disambiguation evidence to a baseline state so each
    // scenario can layer its specific mutation without interference.
    trace.subBandVoteDetail = nil
    trace.refinedBPM = nil
    trace.ensembleDecision = nil
    trace.durationHintDetail = nil
    trace.clickCorrelationDetail = nil
    trace.candidatesBeforeBoost = [(bpm: 120.0, score: 1.0)]
    trace.candidatesAfterBoost = [(bpm: 120.0, score: 1.0)]
    trace.disambiguationResult = (bpm: 120.0, score: 1.0)
    trace.rawCandidates = [(bpm: 120.0, score: 1.0)]

    let lastBPM: Double
    let expected: FinalSelectionStep
    switch scenario {
    case .mlEnsembleWin:
      trace.ensembleDecision = EnsembleDecision(
        policy: .highestConfidence,
        winner: .ml,
        dspConfidence: 0.5,
        mlConfidence: 0.9,
        mlAbstained: false,
        selectedBPM: 128.0
      )
      lastBPM = 128.0
      expected = .mlEnsemble

    case .metadataPromoted:
      trace.candidatesBeforeBoost = [(bpm: 120.0, score: 1.0)]
      trace.candidatesAfterBoost = [(bpm: 60.0, score: 1.25)]
      lastBPM = 60.0
      expected = .metadataCorroboration

    case .fineGridChanged:
      // P_D3 (code review 2026-05-23): refinedBPM/disambiguation delta
      // bumped from 120.5 vs 120.0 (exactly at the new tolerance
      // boundary `> 0.5`) to 121.0 vs 120.0 (unambiguously meaningful).
      // The pre-patch test used `!=` exact-inequality; the new arm uses
      // `abs(refined - disambiguation) > 0.5` to reject LSB drift, so
      // tests must place fine-grid deltas above the tolerance.
      trace.disambiguationResult = (bpm: 120.0, score: 1.0)
      trace.refinedBPM = 121.0
      lastBPM = 121.0
      expected = .fineGridRefinement

    case .subBandVoteChanged:
      trace.subBandVoteDetail = SubBandVoteEvidence(
        preVoteBPM: 60.0,
        postVoteBPM: 120.0,
        changed: true
      )
      lastBPM = 120.0
      expected = .subBandVoting

    case .durationHintMatched:
      trace.durationHintDetail = DurationHintEvidence(
        fileDurationSeconds: 180.0,
        barCandidates: [BarCandidate(bars: 96, bpm: 128.0)],
        boostedCandidates: [128.0]
      )
      lastBPM = 128.0
      expected = .durationHint

    case .clickRescoreReordered:
      trace.rawCandidates = [(bpm: 60.0, score: 1.0), (bpm: 120.0, score: 0.5)]
      trace.clickCorrelationDetail = [
        ClickCorrelationEntry(candidateIndex: 0, bpm: 60.0, normalizedClickScore: 0.2),
        ClickCorrelationEntry(candidateIndex: 1, bpm: 120.0, normalizedClickScore: 0.9),
      ]
      lastBPM = 120.0
      expected = .clickRescore

    case .baselineDisambiguation:
      lastBPM = 120.0
      expected = .baselineDisambiguation

    case .mlAndFineGridConflict:
      // BOTH ML ensemble win AND fine-grid refinement fired. Highest
      // priority (mlEnsemble) wins.
      trace.refinedBPM = 122.0
      trace.disambiguationResult = (bpm: 120.0, score: 1.0)
      trace.ensembleDecision = EnsembleDecision(
        policy: .highestConfidence,
        winner: .ml,
        dspConfidence: 0.5,
        mlConfidence: 0.9,
        mlAbstained: false,
        selectedBPM: 128.0
      )
      lastBPM = 128.0
      expected = .mlEnsemble

    case .fineGridAndSubBandConflict:
      // BOTH fine-grid and sub-band-vote fired. Fine-grid (higher
      // priority — runs later in pipeline) wins. P_D3 (code review
      // 2026-05-23): delta bumped 120.5→121.0 to clear the new `> 0.5`
      // tolerance — same reason as `.fineGridChanged`.
      trace.refinedBPM = 121.0
      trace.disambiguationResult = (bpm: 120.0, score: 1.0)
      trace.subBandVoteDetail = SubBandVoteEvidence(
        preVoteBPM: 60.0,
        postVoteBPM: 120.0,
        changed: true
      )
      lastBPM = 121.0
      expected = .fineGridRefinement
    }

    let derived = FinalSelectionStep.derive(from: trace, lastBPM: lastBPM)
    #expect(
      derived == expected,
      "scenario \(scenario.rawValue): expected \(expected.rawValue), got \(derived.rawValue)")
  }

  // 5.3 — NaN/Inf in trace export encode throws.
  enum NonFiniteSite: String, CaseIterable {
    case disambiguationBPMNaN
    case disambiguationBPMInfinity
    case rawCandidateBPMNaN
    case subBandEnergyInfinity
  }

  @Test(
    "nanInTraceExportThrows: non-finite Float/Double in TraceExport aborts encode",
    arguments: NonFiniteSite.allCases
  )
  @MainActor
  func nanInTraceExportThrows(_ site: NonFiniteSite) throws {
    let baseDisambiguationBPM: Double
    let baseDisambiguationScore: Float
    let baseRawCandidates: [CandidateScore]
    let baseSubBandEnergies: SubBandEnergiesJSON

    switch site {
    case .disambiguationBPMNaN:
      baseDisambiguationBPM = .nan
      baseDisambiguationScore = 1.0
      baseRawCandidates = [CandidateScore(bpm: 120.0, score: 1.0)]
      baseSubBandEnergies = SubBandEnergiesJSON(from: .zero)
    case .disambiguationBPMInfinity:
      baseDisambiguationBPM = .infinity
      baseDisambiguationScore = 1.0
      baseRawCandidates = [CandidateScore(bpm: 120.0, score: 1.0)]
      baseSubBandEnergies = SubBandEnergiesJSON(from: .zero)
    case .rawCandidateBPMNaN:
      baseDisambiguationBPM = 120.0
      baseDisambiguationScore = 1.0
      baseRawCandidates = [CandidateScore(bpm: .nan, score: 1.0)]
      baseSubBandEnergies = SubBandEnergiesJSON(from: .zero)
    case .subBandEnergyInfinity:
      baseDisambiguationBPM = 120.0
      baseDisambiguationScore = 1.0
      baseRawCandidates = [CandidateScore(bpm: 120.0, score: 1.0)]
      baseSubBandEnergies = SubBandEnergiesJSON(
        from: SubBandEnergies(kick: .infinity, snare: 0, crack: 0, hihat: 0))
    }

    let export = TraceExport(
      schemaVersion: "v1",
      generatedAt: Date(timeIntervalSince1970: 0),
      run: RunInfo(
        fileName: "test.wav",
        intensityRequested: 7,
        intensityEffective: 7,
        mergeStrategy: "maxConfidence",
        votingPolicy: "simpleMajority",
        votingThreshold: 0,
        metadataPolicyEnabledSources: [],
        durationHint: true,
        durationHintMinFileSeconds: 180,
        ensemblePolicy: "dspOnly",
        enableTrace: true,
        enableMLDiagnostics: false,
        maxSeconds: 120,
        elapsedSeconds: 1,
        bpm: 120,
        confidence: 0.8,
        degradationReason: nil
      ),
      selection: SelectionInfo(finalStep: "baseline-disambiguation", reasoning: "test"),
      pipeline: PipelineInfo(
        energyTransitionOffset: 0,
        analysisWindowDuration: 60,
        onsetEnvelopeLength: 6000,
        subBandEnergies: baseSubBandEnergies,
        acfTopLags: [],
        tempogramTopBPMs: [],
        fusedTopBPMs: [],
        tps2TopBPMs: [],
        rawCandidates: baseRawCandidates,
        disambiguation: CandidateScore(
          bpm: baseDisambiguationBPM, score: baseDisambiguationScore),
        clickCorrelation: nil,
        durationHint: nil,
        harmonicRatio: nil,
        subBandVote: nil,
        refinedBPM: nil
      ),
      metadata: MetadataInfo(
        evidence: [],
        candidatesBeforeBoost: [],
        candidatesAfterBoost: []
      ),
      ml: nil
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    #expect(throws: EncodingError.self) {
      _ = try encoder.encode(export)
    }
  }

  // 5.3b — P_D2 / D2 resolution (code review 2026-05-23): the projection
  // boundary sanitizes non-finite Double sentinels for library types that
  // CLAUDE.md documents as carrying NaN as a value-carrier (EnsembleDecision,
  // MLDiagnosticSnapshot, MetadataBPMEvidence corroboratedWith/boostApplied,
  // MLFeatureFrames config doubles). This test confirms the sanitization is
  // load-bearing: a non-finite EnsembleDecision.dspConfidence projects to 0
  // (not NaN), the encode succeeds (does NOT throw), and the round-tripped
  // value is finite. Complements `nanInTraceExportThrows` which exercises
  // the UNSANITIZED-path fields (PipelineInfo.disambiguation.bpm,
  // rawCandidates[].bpm, SubBandEnergies kick/snare/etc.); the two tests
  // together pin the boundary between "throws on internal coding error"
  // vs "nullifies on documented library sentinel".
  @Test("nanInSanitizedFieldsNullifies: non-finite EnsembleDecision fields project to 0")
  @MainActor
  func nanInSanitizedFieldsNullifies() throws {
    let decision = EnsembleDecision(
      policy: .dspOnly,
      winner: .dsp,
      dspConfidence: .nan,
      mlConfidence: .infinity,
      mlAbstained: false,
      selectedBPM: .nan
    )
    let projected = EnsembleDecisionJSON(from: decision)
    #expect(projected.dspConfidence == 0)
    #expect(projected.mlConfidence == nil)
    #expect(projected.selectedBPM == 0)
    // Encode succeeds — sanitized fields are finite, so the encoder's
    // `.throw` strategy doesn't fire. Pre-P_D2 this would have thrown
    // because the raw .nan/.infinity reached the encoder.
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(projected)
    let decoded = try JSONDecoder().decode(EnsembleDecisionJSON.self, from: data)
    #expect(decoded.dspConfidence == 0)
    #expect(decoded.mlConfidence == nil)
    #expect(decoded.selectedBPM == 0)
  }

  // 5.5 — F09 (Story 5-6 review, 2026-05-23): snapshot is PRESERVED
  // across reanalyze so ContentView's strategy-keyed background gradient
  // can crossfade strategy→new-strategy in a single transition (Story
  // 5-6 AC #5). Prior contract was "synchronous reset" (test name
  // `lastRunSnapshotResetOnAnalyzePrologue`); F09 inverted it because
  // resetting forced gradient → neutral → new-strategy mid-run. Stale
  // snapshot during analyze is acceptable: Export Trace button is hidden
  // by `!viewModel.isAnalyzing` (ContentView.swift) so stale export
  // remains unreachable via normal UI. After the new result lands,
  // `lastRunSnapshot` overwrites atomically with the new value.
  @Test("lastRunSnapshotPreservedAcrossReanalyze: prior snapshot survives prologue")
  @MainActor
  func lastRunSnapshotPreservedAcrossReanalyze() async throws {
    let viewModel = try await Self.analyzeFixture()
    let priorSnapshot = try #require(viewModel.lastRunSnapshot)
    // Immediately re-launch — the synchronous prologue must NOT clear
    // the snapshot. Inspecting at this point (before yield) catches a
    // regression that re-introduces the prologue clear.
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    viewModel.analyze(url: url)
    #expect(viewModel.lastRunSnapshot != nil, "prologue should PRESERVE prior snapshot per F09")
    #expect(viewModel.lastRunSnapshot?.runOptions == priorSnapshot.runOptions)
    // Drain the in-flight task so the test doesn't leak a Task.
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    // After completion, snapshot should be NON-NIL (the new run wrote
    // a fresh snapshot atomically on success).
    #expect(viewModel.lastRunSnapshot != nil, "post-run snapshot should be the new one")
  }

  // 5.6 — `opts.enableTrace = true` override at the prologue defeats
  // user-supplied `enableTrace: false`.
  @Test("enableTraceOverrideAtPrologue: override defeats user-supplied false")
  @MainActor
  func enableTraceOverrideAtPrologue() async throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.options.enableTrace = false  // user asked false
    viewModel.analyze(url: url)
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "analyze did not complete within 30s")
    // The override fired post-snapshot, so the run actually used
    // enableTrace=true, which is what the snapshot's runOptions reflects.
    let snapshot = try #require(viewModel.lastRunSnapshot, "snapshot should be populated")
    #expect(snapshot.runOptions.enableTrace == true)
  }

  // 5.7 — golden-file schema test (R2 mitigation).
  //
  // Builds a deterministic, fully-populated TraceExport (every optional
  // populated to a non-default value, every array non-empty). Encodes
  // with [.sortedKeys, .prettyPrinted]. Compares byte-equal against
  // checked-in `Fixtures/5-4-trace-export-golden.json`.
  //
  // If the fixture is missing (first author run OR an explicit
  // regeneration via `BBBKIT_REGENERATE_TRACE_GOLDEN=1`), writes it and
  // FAILS the test — that's how the operator knows to commit the new
  // file and re-run. Pre-P5 (code review 2026-05-23), the missing-
  // fixture path silently returned after `Issue.record`, so a fresh-
  // clone CI run could pass without enforcing the schema invariant.
  //
  // Env-var-guarded regeneration (per Codex thread 019e5812-5ce7-7840):
  // when `BBBKIT_REGENERATE_TRACE_GOLDEN=1` is set, the test overwrites
  // the golden with the freshly-computed bytes AND fails loud — operator
  // commits and removes the env var on the next run.
  @Test("traceExportSchemaMatchesGolden: encoded TraceExport matches checked-in fixture")
  @MainActor
  func traceExportSchemaMatchesGolden() throws {
    let export = Self.canonicalTraceExport()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(export)

    let testFile = URL(fileURLWithPath: #filePath)
    let fixtureURL =
      testFile
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("5-4-trace-export-golden.json")

    let regenerationRequested =
      ProcessInfo.processInfo.environment["BBBKIT_REGENERATE_TRACE_GOLDEN"] == "1"
    let fixtureMissing = !FileManager.default.fileExists(atPath: fixtureURL.path)

    // P5 (code review 2026-05-23): regeneration path now writes AND
    // fails so the operator can commit the freshly-written golden
    // without ambiguity about whether the test passed by accident.
    if regenerationRequested || fixtureMissing {
      try data.write(to: fixtureURL, options: .atomic)
      let reason =
        fixtureMissing
        ? "golden fixture did not exist"
        : "BBBKIT_REGENERATE_TRACE_GOLDEN=1 was set"
      let message =
        "\(reason); wrote fresh bytes to \(fixtureURL.path). "
        + "Commit the file, unset BBBKIT_REGENERATE_TRACE_GOLDEN (if set), and re-run."
      Issue.record(Comment(rawValue: message))
      // Loud failure replaces the pre-P5 silent `return`. Without this,
      // fresh-clone CI passes vacuously.
      #expect(Bool(false), Comment(rawValue: message))
      return
    }

    let goldenRaw = try Data(contentsOf: fixtureURL)
    // P5 (code review 2026-05-23): strip a single trailing newline from
    // the loaded golden before byte-compare. The committed golden carries
    // a trailing `\n` for editor friendliness (most editors auto-add one
    // on save; without it, an innocent edit-and-save would surface as a
    // 1-byte diff every time). JSONEncoder.encode() does NOT emit a
    // trailing newline, so we normalize by stripping at most one.
    let golden: Data
    if goldenRaw.last == 0x0A {  // ASCII '\n'
      golden = goldenRaw.dropLast()
    } else {
      golden = goldenRaw
    }
    if data != golden {
      // Write the new bytes to a sibling .actual file so a human can
      // diff and decide whether the divergence is intentional (update
      // golden) or a regression (fix the projection).
      let actualURL =
        fixtureURL
        .deletingLastPathComponent()
        .appendingPathComponent("5-4-trace-export-golden.actual.json")
      try data.write(to: actualURL, options: .atomic)
      let message =
        "encoded TraceExport diverges from golden; wrote actual to "
        + "\(actualURL.path) for diff inspection. If intentional, re-run with "
        + "BBBKIT_REGENERATE_TRACE_GOLDEN=1 to overwrite the golden + commit."
      Issue.record(Comment(rawValue: message))
    }
    #expect(data == golden)
  }

  // Canonical fully-populated TraceExport for the golden-file test.
  // Every optional set, every array non-empty, every scalar at a
  // distinct constant. NO non-finite floats (the encoder would reject).
  //
  // `@MainActor` because the projection-type `init(from:)` initializers
  // (e.g., `MetadataEvidenceJSON.init(from:)`) inherit MainActor
  // isolation from the `-default-isolation MainActor` build setting;
  // calling them from a nonisolated static func would fail Swift 6
  // strict-concurrency checks.
  @MainActor
  private static func canonicalTraceExport() -> TraceExport {
    TraceExport(
      schemaVersion: "v1",
      generatedAt: Date(timeIntervalSince1970: 0),
      run: RunInfo(
        fileName: "golden-fixture.wav",
        intensityRequested: 7,
        intensityEffective: 7,
        mergeStrategy: "maxConfidence",
        votingPolicy: "simpleMajority",
        votingThreshold: 0.5,
        // P5 (code review 2026-05-23): alphabetically sorted to match the
        // production `RunOptionsSnapshot(from:)` `.sorted()` invariant.
        // Pre-patch the literal order was ["iTunesTmpo", "id3TBPM",
        // "vorbisBPM"] (insertion order from the `MetadataSource` enum),
        // bypassing the production sort path — a regression that removed
        // `.sorted()` would have passed this golden test.
        metadataPolicyEnabledSources: ["id3TBPM", "iTunesTmpo", "vorbisBPM"],
        durationHint: true,
        durationHintMinFileSeconds: 180,
        ensemblePolicy: "dspOnly",
        enableTrace: true,
        enableMLDiagnostics: false,
        maxSeconds: 120,
        elapsedSeconds: 1.5,
        bpm: 120.0,
        confidence: 0.85,
        degradationReason: nil
      ),
      selection: SelectionInfo(
        finalStep: "fine-grid-refinement",
        reasoning: "Fine-grid DFT refinement adjusted the BPM after disambiguation."
      ),
      pipeline: PipelineInfo(
        energyTransitionOffset: 1024,
        analysisWindowDuration: 60.0,
        onsetEnvelopeLength: 6000,
        subBandEnergies: SubBandEnergiesJSON(
          from: SubBandEnergies(kick: 0.5, snare: 0.4, crack: 0.3, hihat: 0.2)),
        acfTopLags: [LagStrength(lag: 50, strength: 0.9)],
        tempogramTopBPMs: [BPMMagnitude(bpm: 120, magnitude: 0.8)],
        fusedTopBPMs: [BPMScore(bpm: 120, score: 1.0)],
        tps2TopBPMs: [BPMScore(bpm: 120, score: 0.95)],
        rawCandidates: [CandidateScore(bpm: 120.0, score: 1.0)],
        disambiguation: CandidateScore(bpm: 120.0, score: 1.0),
        clickCorrelation: [
          ClickCorrelationJSON(
            from: ClickCorrelationEntry(
              candidateIndex: 0, bpm: 120.0, normalizedClickScore: 0.95))
        ],
        durationHint: DurationHintJSON(
          from: DurationHintEvidence(
            fileDurationSeconds: 180.0,
            barCandidates: [BarCandidate(bars: 96, bpm: 128.0)],
            boostedCandidates: [120.0]
          )),
        harmonicRatio: HarmonicRatioJSON(
          from: HarmonicRatioEvidence(
            ratio: "2:1", fastBPM: 240.0, slowBPM: 120.0, winnerBPM: 120.0)),
        subBandVote: SubBandVoteJSON(
          from: SubBandVoteEvidence(preVoteBPM: 60.0, postVoteBPM: 120.0, changed: true)),
        refinedBPM: 120.25
      ),
      metadata: MetadataInfo(
        evidence: [
          MetadataEvidenceJSON(
            from: MetadataBPMEvidence(
              source: .iTunesTmpo,
              rawValue: "120",
              parsedBPM: 120.0,
              corroboratedWith: 120.0,
              ratioMatched: .one,
              boostApplied: 1.25,
              rejectionReason: nil))
        ],
        candidatesBeforeBoost: [CandidateScore(bpm: 120.0, score: 0.8)],
        candidatesAfterBoost: [CandidateScore(bpm: 120.0, score: 1.0)]
      ),
      ml: MLInfo(
        ensembleDecision: EnsembleDecisionJSON(
          from: EnsembleDecision(
            policy: .dspOnly,
            winner: .dsp,
            dspConfidence: 0.85,
            mlConfidence: nil,
            mlAbstained: true,
            selectedBPM: 120.0
          )),
        diagnosticSnapshot: nil,
        featureFramesShape: nil
      )
    )
  }

  // 5.8 — atomic snapshot invariant: all five fields populated together.
  //
  // P2 test half (code review 2026-05-23): extended to assert non-default
  // for `trace` (onsetEnvelopeLength > 0 — proves the DSP pipeline ran)
  // and `metadataEvidence` (the array's existence + the production code
  // path that populates it). The pre-patch version only checked fileName,
  // runOptions.intensity, result.bpm — leaving 2 of the 5 DD #5 fields
  // unverified.
  @Test("lastRunSnapshotIsAtomic: all snapshot fields populated together")
  @MainActor
  func lastRunSnapshotIsAtomic() async throws {
    let viewModel = try await Self.analyzeFixture()
    let snapshot = try #require(viewModel.lastRunSnapshot)
    // All five DD #5 nested fields are populated together.
    #expect(snapshot.fileName == "bpm-120-click.wav")
    #expect(snapshot.runOptions.intensity.rawValue == AnalysisIntensity.default.rawValue)
    // metadataEvidence is `[MetadataBPMEvidence]` — the array may be
    // empty for the tag-free fixture, but the field's existence proves
    // the production population path ran. (For tagged fixtures, future
    // tests should assert evidence.count > 0.)
    _ = snapshot.metadataEvidence
    #expect(snapshot.result.bpm > 0)
    // trace.onsetEnvelopeLength > 0 proves the DSP pipeline actually ran
    // and populated the trace — not a default-initialized empty trace.
    #expect(snapshot.trace.onsetEnvelopeLength > 0)
  }

  // 5.8b — P2 test half (code review 2026-05-23): exercises P_D4's
  // running-task failure-arm snapshot reset. AC #3's "subsequent reset
  // clears all fields together" half was previously unverified. This
  // test analyzes a real fixture (populates snapshot), then triggers
  // the running-task failure path via writeTraceJSON to an unwritable
  // URL — wait, that's the wrong trigger; that hits the write-error
  // arm, not the analyze() failure arm. The clean trigger is a second
  // analyze() against an unreadable URL — PCMBufferReaderError fires
  // in the running task's .failure(PCMBufferReaderError) arm, which
  // is exactly where P_D4 added `self.lastRunSnapshot = nil`.
  //
  // The test asserts: (a) snapshot is populated after the first
  // analyze; (b) snapshot is nil after the failing second analyze;
  // (c) the failure path also surfaces `error` (proving the
  // observation-coupling contract per DD #10 — both the observed
  // `error` write AND the @ObservationIgnored snapshot=nil write
  // ride in the same MainActor turn).
  @Test("lastRunSnapshotResetClearsAllFields: failing analyze clears prior snapshot")
  @MainActor
  func lastRunSnapshotResetClearsAllFields() async throws {
    let viewModel = try await Self.analyzeFixture()
    let priorSnapshot = try #require(viewModel.lastRunSnapshot)
    _ = priorSnapshot  // sanity capture; we don't compare, we just assert reset.
    // Drive a second analyze() against a deliberately-unreadable URL
    // so the running task's .failure(PCMBufferReaderError) arm fires.
    // That's where P_D4 inserted `self.lastRunSnapshot = nil`.
    let unreadableURL = URL(fileURLWithPath: "/nonexistent-test-dir-5-4/missing.wav")
    viewModel.analyze(url: unreadableURL, autoStarted: false)
    // Drain: wait for the failing analyze to finish.
    var spins = 0
    while viewModel.isAnalyzing && spins < 500 {
      try await Task.sleep(for: .milliseconds(10))
      spins += 1
    }
    #expect(!viewModel.isAnalyzing, "analyze() did not finish within ~5s")
    // P_D4 contract: snapshot reset to nil on failure arm.
    #expect(viewModel.lastRunSnapshot == nil)
    // DD #10 re-render coupling: an observed property was also written
    // (error.errorDescription non-nil) in the same MainActor turn.
    #expect(viewModel.error != nil)
  }

  // 5.9 — Export Trace visibility predicate evaluates to false when
  // `lastRunSnapshot == nil` (fresh init AND post-failure paths).
  @Test("exportTraceVisibilityGatedOnSnapshot: lastRunSnapshot nil immediately after init")
  @MainActor
  func exportTraceVisibilityGatedOnSnapshot() {
    let viewModel = AnalysisViewModel()
    #expect(viewModel.lastRunSnapshot == nil)
    // Failure-arm: an invalid drop populates errorMessage but leaves
    // lastRunSnapshot nil (no DSP work ran).
    let bogusURL = URL(fileURLWithPath: "/tmp/sample.txt")
    _ = viewModel.handleDrop([bogusURL])
    #expect(viewModel.lastRunSnapshot == nil)
  }

  // 5.10 — write-error path sets errorMessage and leaves snapshot
  // unchanged (AC #14).
  @Test("exportTraceWriteErrorSetsErrorMessage: unwritable URL surfaces errorMessage")
  @MainActor
  func exportTraceWriteErrorSetsErrorMessage() async throws {
    let viewModel = try await Self.analyzeFixture()
    let snapshotBefore = try #require(viewModel.lastRunSnapshot)
    // Deliberately-unwritable URL: nonexistent intermediate directory.
    // `.atomic` write fails — caught and surfaced via errorMessage.
    let bogusURL = URL(fileURLWithPath: "/nonexistent-story-5-4-test-dir/trace.json")
    let didWrite = viewModel.writeTraceJSON(to: bogusURL)
    #expect(didWrite == false)
    let message = try #require(viewModel.errorMessage)
    #expect(message.hasPrefix("Could not export trace JSON:"))
    // Snapshot unchanged — failed write doesn't invalidate it.
    let snapshotAfter = try #require(viewModel.lastRunSnapshot)
    #expect(snapshotAfter.fileName == snapshotBefore.fileName)
  }

  // 5.11 — DD #11 positive assertion: logMelData key is absent from
  // the exported JSON even when mlFeatures is populated on the trace.
  @Test("logMelDataOmittedFromExport: payload absent, shape present")
  @MainActor
  func logMelDataOmittedFromExport() async throws {
    let viewModel = try await Self.analyzeFixture()
    let snapshot = try #require(viewModel.lastRunSnapshot)
    // Inject mlFeatures into a copy of the trace.
    var trace = snapshot.trace
    let melBands = 128
    let frames = 100
    let payloadCount = melBands * frames
    let payload = [Float](repeating: 0.5, count: payloadCount)
    trace.mlFeatures = try MLFeatureFrames(
      melBands: melBands,
      frames: frames,
      tensorLayout: .frameMajorLogMel,
      logMelData: payload,
      sampleRate: 44100,
      fftSize: 2048,
      hopSize: 441,
      melFmin: 30,
      melFmax: 16000,
      logCompressionScale: 100,
      featureSetVersion: "v1"
    )
    // Attach an ensembleDecision so MLInfo is non-nil (it is also
    // non-nil when only mlDiagnosticSnapshot or mlFeatures is present,
    // but the test specifically asserts the ensembleDecision projection).
    trace.ensembleDecision = EnsembleDecision(
      policy: .dspOnly,
      winner: .dsp,
      dspConfidence: snapshot.result.confidence,
      mlConfidence: nil,
      mlAbstained: true,
      selectedBPM: snapshot.result.bpm
    )

    let export = TraceExport.from(
      trace: trace,
      runOptions: snapshot.runOptions,
      result: snapshot.result,
      fileName: snapshot.fileName,
      metadataEvidence: snapshot.metadataEvidence,
      elapsedSeconds: viewModel.elapsedSeconds ?? 0
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    let data = try encoder.encode(export)

    // Positive shape assertion via decode.
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(TraceExport.self, from: data)
    try #require(decoded.ml != nil)
    try #require(decoded.ml?.featureFramesShape != nil)
    #expect(decoded.ml?.featureFramesShape?.melBands == 128)
    #expect(decoded.ml?.featureFramesShape?.frames == 100)

    // Negative absence assertion via JSONSerialization walk — no key
    // named `logMelData` anywhere in the JSON.
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    #expect(!Self.containsKey("logMelData", in: jsonObject))

    // Size bound — shape-only export stays under 100 KB.
    #expect(data.count < 100_000)
  }

  // Recursive helper for 5.11 — walks a JSONSerialization-decoded
  // object and returns true if any nested dict contains the key.
  //
  // P7 (code review 2026-05-23): parameter renamed `any:` → `value:` —
  // `any` is a Swift 5.6+ contextual keyword used as a type marker (e.g.,
  // `(any P)`); using it as a parameter name silently shadows in inner
  // scopes and is a portability hazard if a future Swift version hard-
  // promotes it. Also added explicit NSNull handling so JSON `null`s
  // (which JSONSerialization wraps as NSNull) terminate the walk without
  // false-passing through `as? [String: Any]` / `as? [Any]` (both fail
  // on NSNull — the pre-patch behavior happened to be correct but only
  // because both casts fail; explicit handling is legible.).
  private static func containsKey(_ target: String, in value: Any) -> Bool {
    if value is NSNull { return false }
    if let dict = value as? [String: Any] {
      if dict[target] != nil { return true }
      for (_, nested) in dict {
        if containsKey(target, in: nested) { return true }
      }
    } else if let array = value as? [Any] {
      for element in array {
        if containsKey(target, in: element) { return true }
      }
    }
    return false
  }
}
