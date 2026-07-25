//
//  AudioAnalysisServiceTests.swift
//  BoomBoomBoomKitTests
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Real Audio Tests

@Suite("AudioAnalysisService — Real Audio")
struct AudioAnalysisServiceRealAudioTests {

  /// MP3 decode smoke test. GH-167 item 5 (#161) removed the old
  /// `bpm >= 40 && bpm <= 220` assertion: a 180-wide plausibility band on a
  /// tempo detector asserts essentially nothing, and real accuracy is now
  /// asserted against independently-established ground truth in
  /// `AccuracyFloorTests`, which runs in the same `make test` lane.
  ///
  /// This test is deliberately NOT tightened in place — its fixture `Meta_Man` is
  /// one of the four known octave failures (true 92, detected ~182), so a strict
  /// assertion here would duplicate a ratchet that already exists in the floor.
  /// What remains is what this test is actually for: the MP3 path decodes and
  /// returns a usable result.
  @Test("analyzeBPM with MP3 fixture returns non-nil result")
  func analyzeBPMWithMP3() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url),
      "Expected non-nil BPM result for real MP3")
    #expect(result.bpm.isFinite, "Expected a finite BPM, got \(result.bpm)")
    #expect(
      result.confidence > 0 && result.confidence <= 1.0,
      "Expected confidence in (0, 1], got \(result.confidence)")
  }

  @Test("analyzeBPM with short FLAC fixture returns nil (below 4s minimum)")
  func analyzeBPMWithShortFLAC() throws {
    let url = try AudioFixtures.url(for: "test-audio", extension: "flac")
    // test-audio.flac is ~1 second — below BPMAnalyzer's 4-second minimum
    let result = try? AudioAnalysisService.analyzeBPM(url: url)
    #expect(result == nil, "1-second FLAC should return nil (below minimum duration)")
  }

  @Test("analyzeBPM with short M4A fixture returns nil (below 4s minimum)")
  func analyzeBPMWithShortM4A() throws {
    let url = try AudioFixtures.url(for: "test-audio", extension: "m4a")
    // test-audio.m4a is ~1 second — below BPMAnalyzer's 4-second minimum
    let result = try? AudioAnalysisService.analyzeBPM(url: url)
    #expect(result == nil, "1-second M4A should return nil (below minimum duration)")
  }
}

// MARK: - Synthetic Audio Tests

@Suite("AudioAnalysisService — Synthetic Audio")
struct AudioAnalysisServiceSyntheticTests {

  @Test("analyzeBPM with known-BPM synthetic WAV returns accurate result")
  func analyzeSyntheticWAV() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("bpm-test-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    try createClickTrackWAV(bpm: 120, sampleRate: 44100, durationSeconds: 10, url: tempURL)

    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: tempURL),
      "Expected non-nil BPM result for synthetic 120 BPM WAV")
    #expect(
      result.bpm >= 118 && result.bpm <= 122,
      "Expected ~120 BPM, got \(result.bpm)")
    #expect(
      result.confidence > 0.3,
      "Expected reasonable confidence for clean click track, got \(result.confidence)")
  }
}

// MARK: - Edge Cases

@Suite("AudioAnalysisService — Edge Cases")
struct AudioAnalysisServiceEdgeCaseTests {

  @Test("analyzeBPM with very short audio returns nil")
  func shortAudioReturnsNil() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("bpm-short-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // 1 second of audio — below BPMAnalyzer's 4-second minimum
    try createClickTrackWAV(bpm: 120, sampleRate: 44100, durationSeconds: 1, url: tempURL)

    let result = try? AudioAnalysisService.analyzeBPM(url: tempURL)
    #expect(result == nil, "Short audio should return nil")
  }

  @Test("analyzeBPM with nonexistent file throws")
  func nonexistentFileThrows() {
    #expect(throws: (any Error).self) {
      try AudioAnalysisService.analyzeBPM(url: URL(fileURLWithPath: "/nonexistent/file.wav"))
    }
  }
}

// MARK: - LUFS Analysis Tests

@Suite("AudioAnalysisService — LUFS Analysis")
struct AudioAnalysisServiceLUFSTests {

  @Test("analyzeLUFS with MP3 fixture returns non-nil LUFSReport")
  func analyzeLUFSWithMP3() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let report = try #require(
      try AudioAnalysisService.analyzeLUFS(url: url),
      "Expected non-nil LUFSReport for real MP3")
    // LUFS values are typically negative, between -70 and 0
    #expect(
      report.integratedLUFS < 0 && report.integratedLUFS > -70,
      "Expected plausible LUFS value (-70 to 0), got \(report.integratedLUFS)")
    #expect(!report.momentaryLUFS.isEmpty)
    #expect(report.stepSeconds == 0.1)
  }

  @Test("analyzeLUFS with short FLAC fixture handles gracefully")
  func analyzeLUFSWithShortFLAC() throws {
    let url = try AudioFixtures.url(for: "test-audio", extension: "flac")
    // test-audio.flac is ~1 second — above LUFSAnalyzer's 400ms minimum,
    // so it may or may not return a result depending on content.
    // Key invariant: doesn't crash; if non-nil, the value is plausible and the
    // short-term series is empty (< 3s of input).
    // `try` (not `try?`): the fixture is a supported 44.1 kHz decode, so a
    // throw here is an infrastructure/decode regression that must fail loudly
    // rather than silently skip the assertions.
    let report = try AudioAnalysisService.analyzeLUFS(url: url)
    if let report {
      #expect(
        report.integratedLUFS < 0 && report.integratedLUFS > -70,
        "Expected plausible LUFS (-70 to 0), got \(report.integratedLUFS)")
      #expect(report.shortTermLUFS.isEmpty, "sub-3s input must yield an empty short-term series")
    }
  }

  @Test("analyzeLUFS result matches LUFSAnalyzer directly (same value)")
  func analyzeLUFSMatchesDirectCall() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    // maxSeconds pinned to 30 on BOTH paths (the service default is now
    // full-file per Story 8.1 DD #9).
    var options = LUFSOptions()
    options.maxSeconds = 30
    let report = try AudioAnalysisService.analyzeLUFS(url: url, options: options)

    // Direct call for comparison
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 30)
    let direct = LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: sampleRate))

    #expect(
      report?.integratedLUFS == direct?.integratedLoudness,
      "Service and direct call should return identical values")
    #expect(report?.momentaryLUFS == direct?.blockLoudnessValues)
  }
}

// MARK: - Intensity API Tests

@Suite("AudioAnalysisService — Intensity API")
struct AudioAnalysisServiceIntensityTests {

  @Test("analyzeBPM with intensity parameter returns result")
  func analyzeWithIntensity() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url,
        options: {
          var o = AudioAnalysisService.Options()
          o.intensity = .default
          return o
        }()),
      "Expected non-nil result with intensity API")
    #expect(result.bpm >= 40 && result.bpm <= 220)
    #expect(result.confidence > 0)
  }

  @Test("analyzeBPM with enableTrace true returns trace")
  func analyzeWithTrace() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url,
        options: {
          var o = AudioAnalysisService.Options()
          o.enableTrace = true
          return o
        }()))
    let trace = try #require(result.trace, "Trace should be non-nil when enableTrace is true")
    #expect(!trace.rawCandidates.isEmpty)
    #expect(trace.confidence > 0)
    #expect(trace.intensityUsed == .default)
  }

  @Test("analyzeBPM with enableTrace false returns nil trace")
  func analyzeWithoutTrace() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url))
    #expect(result.trace == nil)
  }

  @Test("analyzeBPM with fastest intensity returns result")
  func analyzeWithFastest() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url,
        options: {
          var o = AudioAnalysisService.Options()
          o.intensity = .fastest
          return o
        }()))
    #expect(result.bpm >= 40 && result.bpm <= 220)
  }
}

// MARK: - TechniqueSet Override (Story 3-3)

@Suite("AudioAnalysisService — TechniqueSet Override")
struct TechniqueSetOverrideTests {

  /// Baseline: when `techniqueSet == nil`, the pipeline derives the technique set
  /// from `intensity` (default `.optimal`), so `clickCorrelationDetail` is unpopulated.
  @Test("techniqueSet nil derives from intensity — clickCorrelationDetail is nil")
  func techniqueSetNilDerivesFromIntensity() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.enableTrace = true
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    let trace = try #require(result.trace)
    #expect(trace.clickCorrelationDetail == nil)
  }

  /// Override with `.clickAugmented` flows through to the BPM pipeline, activating
  /// click-track cross-correlation and populating `clickCorrelationDetail`.
  @Test("techniqueSet .clickAugmented activates click correlation in the pipeline")
  func techniqueSetClickAugmentedFlowsThrough() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.techniqueSet = .clickAugmented
    opts.enableTrace = true
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    let trace = try #require(result.trace)
    let detail = try #require(
      trace.clickCorrelationDetail,
      "Expected clickCorrelationDetail populated when techniqueSet = .clickAugmented")
    #expect(!detail.isEmpty)
  }

  /// Override beats intensity: a `TechniqueSet` with `candidateCount: 1` produces
  /// 1 raw candidate even though `intensity = .default` (intensity 7) would have
  /// resolved to `.optimal` (3 candidates).
  @Test("techniqueSet override candidateCount overrides intensity-derived count")
  func techniqueSetOverrideCandidateCount() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.techniqueSet = TechniqueSet(
      dspTechniques: [.subBandVoting, .fineGridRefinement], candidateCount: 1)
    opts.enableTrace = true
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    let trace = try #require(result.trace)
    #expect(trace.rawCandidates.count == 1)
    // Sanity: intensity is still .default, so progressive windows are still in play.
    #expect(trace.intensityUsed == .default)
  }
}

// MARK: - Cancellation Tests

@Suite("AudioAnalysisService -- Cancellation")
struct AudioAnalysisServiceCancellationTests {

  @Test("isCancelled before first window throws CancellationError")
  func cancelledBeforeFirstWindow() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.isCancelled = { true }
    #expect(throws: CancellationError.self) {
      try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    }
  }

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

  @Test("isCancelled never true completes normally")
  func neverCancelledCompletesNormally() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.isCancelled = { false }
    let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(result != nil)
  }

  @Test("Task cancellation throws CancellationError")
  func taskCancellation() async throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    // Use withThrowingTaskGroup + cancelAll to guarantee Task.isCancelled is true
    // before analyzeBPM's pre-PCM check. This is deterministic -- the injectable
    // closure tests above cover mid-analysis cancellation scenarios.
    do {
      try await withThrowingTaskGroup(of: AudioAnalysisResult?.self) { group in
        group.addTask {
          try AudioAnalysisService.analyzeBPM(url: url)
        }
        group.cancelAll()
        _ = try await group.next()
      }
      Issue.record("Expected CancellationError")
    } catch is CancellationError {
      // expected
    }
  }

  @Test("try? with cancellation returns nil")
  func cancelledWithTryOptional() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.isCancelled = { true }
    let result = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(result == nil)
  }
}

// MARK: - Progress Tests

@Suite("AudioAnalysisService -- Progress")
struct AudioAnalysisServiceProgressTests {

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

  @Test("intensity 1 (single window) reports progress (0/1)")
  func progressSingleWindow() throws {
    nonisolated(unsafe) var updates: [ProgressUpdate] = []
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .fastest
    opts.onProgress = { updates.append($0) }
    _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(updates.count == 1)
    #expect(updates[0].windowsCompleted == 0)
    #expect(updates[0].windowsTotal == 1)
  }

  @Test("no onProgress callback works identically to current behavior")
  func noProgressCallback() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try AudioAnalysisService.analyzeBPM(url: url)
    #expect(result != nil)
  }

  @Test("cancelled analysis never calls progress callback")
  func cancelledNeverCallsProgress() throws {
    nonisolated(unsafe) var progressCalled = false
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.isCancelled = { true }
    opts.onProgress = { _ in progressCalled = true }
    _ = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(!progressCalled)
  }

  /// W83 regression net: `windowSizes` is the ONLY thing that decides how many
  /// windows run. `onProgress` fires exactly once immediately before each window
  /// is attempted, so the callback count is the number of windows the loop
  /// entered. This test fails if any early-stop gate is reintroduced into the
  /// window loop (the per-level threshold gate deleted by W83 was such a break,
  /// inert only because levels 1-5 list a single window).
  @Test("every configured window runs at every intensity level")
  func everyConfiguredWindowRuns() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    for level in AnalysisIntensity.allCases {
      nonisolated(unsafe) var updates: [ProgressUpdate] = []
      var opts = AudioAnalysisService.Options()
      opts.intensity = level
      opts.onProgress = { updates.append($0) }
      let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
      // The fixture is analyzable, so no window is skipped for lack of audio.
      #expect(result != nil, "fixture unexpectedly unanalyzable at \(level)")
      let expected = level.windowSizes.count
      #expect(
        updates.count == expected,
        "\(level) attempted \(updates.count) windows, windowSizes.count is \(expected)")
      for (index, update) in updates.enumerated() {
        #expect(update.windowsCompleted == index, "out-of-order progress at \(level)")
        #expect(update.windowsTotal == expected, "wrong windowsTotal at \(level)")
      }
    }
  }
}

// MARK: - MLTechnique Slot (Story 3-3a / ADR-11; wired by Story 4.3)

@Suite("AudioAnalysisService — MLTechnique Slot")
struct MLTechniqueSlotTests {

  /// AC#2 (Story 3-3a): `Options` accepts a real `MLTechnique` conformance and
  /// round-trips it. Post-Story-4.3 the protocol no longer requires a `name`
  /// channel; round-trip is proven by non-nil identity alone.
  @Test("mlTechnique slot accepts conformance and round-trips")
  func mlTechniqueSlotAcceptsConformance() {
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = MockMLTechnique()
    #expect(opts.mlTechnique != nil)
  }

  /// AC#2: A fresh `Options()` defaults `mlTechnique` to nil per the implicit-nil rule.
  @Test("mlTechnique defaults to nil")
  func mlTechniqueDefaultsToNil() {
    let opts = AudioAnalysisService.Options()
    #expect(opts.mlTechnique == nil)
  }

  /// Post-Story-4.3 invariant (DD #5): the default ensemble policy is
  /// "DSP wins regardless." An injected `MLEvaluation` — even one carrying a
  /// sentinel BPM outside the public 60-200 output range — must NOT change
  /// the final BPM/confidence vs the baseline. Story 4.4 introduces the
  /// public `EnsemblePolicy` enum that switches the combiner; until then the
  /// ML path is wired-but-inert at the result layer.
  @Test("mlEvaluation does not change DSP result under default policy (Story 4.3 DD #5)")
  func mlEvaluationDoesNotChangeDSPResultUnderDefaultPolicy() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")

    var baseline = AudioAnalysisService.Options()
    baseline.intensity = .fastest  // single window — deterministic + fast
    let baselineResult = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: baseline))

    var withMock = AudioAnalysisService.Options()
    withMock.intensity = .fastest
    // 999 BPM is outside the public 60-200 output range. If a future change
    // accidentally promoted ML output to the ensemble result, this sentinel
    // would surface in `mockResult.bpm` and break the bitPattern equality.
    withMock.mlTechnique = MockMLTechnique(
      returning: MLEvaluation(bpm: 999.0, confidence: 1.0))
    let mockResult = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: withMock))

    #expect(baselineResult.bpm == mockResult.bpm)
    #expect(baselineResult.confidence == mockResult.confidence)
  }

  // Story 4-3's `evaluateIsInvokedWithNonNilTraceWhenEnableTraceFalse`
  // wiring proof was removed in Story 4-4: its premise ("ML always runs
  // when mlTechnique != nil") is exactly what the A1 short-circuit
  // deliberately broke under the default `.dspOnly` policy. The post-4-4
  // invariants are covered by `EnsemblePolicyTests`:
  //   - callCount==0 under `.dspOnly` (AC #14)
  //   - callCount==1 under `.mlOnly` / `.highestConfidence` (AC #14
  //     contrapositive)
  //   - trace.ensembleDecision population matrix (AC #13)
  //   - the inertness proofs against sentinel ML evaluations (AC #5)
  // Pre-1.0 / no-BC posture per project-context.md "Public API Discipline".
}

// MARK: - Duration Hint Tests (Story 3-4)

@Suite("AudioAnalysisService — Duration Hint")
struct AudioAnalysisServiceDurationHintTests {

  @Test("durationHint defaults to true on a fresh Options instance")
  func durationHintDefaultsToTrue() {
    let opts = AudioAnalysisService.Options()
    #expect(opts.durationHint == true)
  }

  @Test("durationHint=true populates trace.durationHintDetail with expected keys")
  func durationHintTrueProducesBoostedTrace() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("aas_duration_hint_on_240s.wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    try createClickTrackWAV(bpm: 128, sampleRate: 44100, durationSeconds: 240, url: tempURL)

    var opts = AudioAnalysisService.Options()
    opts.enableTrace = true
    opts.maxSeconds = 60  // 30s analysis window from a 240s file is plenty.

    let result = try #require(try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts))

    #expect(abs(result.bpm - 128.0) / 128.0 < 0.02)
    let detail = try #require(result.trace?.durationHintDetail)
    #expect(detail.fileDurationSeconds == 240.0)
    #expect(detail.barCandidates.contains(where: { $0.bars == 128 && $0.bpm == 128.0 }))
    // Typed `[Double]` membership replaces the prior CSV substring check; tighter than
    // the legacy "128.0" substring (which could match noise like "1280" or "128X").
    #expect(detail.boostedCandidates.contains(128.0))
  }

  @Test("durationHint=false leaves trace.durationHintDetail nil and still detects BPM")
  func durationHintFalseSkipsTrace() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("aas_duration_hint_off_240s.wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    try createClickTrackWAV(bpm: 128, sampleRate: 44100, durationSeconds: 240, url: tempURL)

    var opts = AudioAnalysisService.Options()
    opts.enableTrace = true
    opts.durationHint = false
    opts.maxSeconds = 60

    let result = try #require(try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts))

    #expect(abs(result.bpm - 128.0) / 128.0 < 0.02)
    #expect(result.trace?.durationHintDetail == nil)
  }
}

// MARK: - Voting Policy (Story 3-5)

@Suite("AudioAnalysisService — Voting Policy")
struct AudioAnalysisServiceVotingPolicyTests {

  // Task 6.2 — defaults
  @Test("Options() defaults: votingPolicy == .simpleMajority, votingThreshold == 0.0")
  func defaultsAreSimpleMajorityAndZero() {
    let opts = AudioAnalysisService.Options()
    #expect(opts.votingPolicy == .simpleMajority)
    #expect(opts.votingThreshold == 0.0)
  }

  // Task 6.3 — smoke (non-crashing on universal-fallback gate)
  @Test(
    "analyzeBPM with .windowVoting + .thresholdGated/threshold=1.0 still detects clean click track")
  func votingPolicyFlowsThroughOptionsToMergeLayer() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("aas_voting_smoke_\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try createClickTrackWAV(bpm: 128, sampleRate: 44100, durationSeconds: 240, url: tempURL)

    var opts = AudioAnalysisService.Options()
    opts.mergeStrategy = .windowVoting
    opts.votingPolicy = .thresholdGated
    opts.votingThreshold = 1.0  // forces universal fallback to maxConfidence

    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts))
    #expect(
      abs(result.bpm - 128.0) / 128.0 < 0.02,
      "Click track should detect 128 BPM, got \(result.bpm)")
  }

  // Task 6.4 — non-finite thresholds tolerated (silent normalization per DD#9)
  @Test("votingThreshold non-finite values are tolerated (no crash, valid result)")
  func votingThresholdNonFiniteIsTolerated() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("aas_voting_nonfinite_\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try createClickTrackWAV(bpm: 128, sampleRate: 44100, durationSeconds: 240, url: tempURL)

    var opts = AudioAnalysisService.Options()
    opts.mergeStrategy = .windowVoting
    opts.votingPolicy = .thresholdGated

    let pathological: [Double] = [.nan, .infinity, -.infinity, .signalingNaN]
    for threshold in pathological {
      opts.votingThreshold = threshold
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts),
        "non-finite threshold \(threshold) should not break analyzeBPM")
      #expect(
        abs(result.bpm - 128.0) / 128.0 < 0.02,
        "non-finite threshold \(threshold) should still detect 128 BPM, got \(result.bpm)")
    }
  }

  // Task 6.5 — divergent integration test (Strategy B: deterministic synthetic
  // seam). Proves Options.votingPolicy + Options.votingThreshold actually plumb
  // through analyzeBPM to the merge layer.
  //
  // Construction: 30s @ 100 BPM, then 60s @ 144 BPM (non-octave-related so the
  // pipeline's autocorrelation distinguishes them cleanly). Empirically the
  // 30s window locks to 100 BPM at conf ~0.95; the 60s and 90s windows lock to
  // ~142 BPM at conf ~0.92. The consensus cluster {window1, window2} has BPM
  // ~142, but the SINGLETON window 0 has the higher confidence (0.95 > 0.92).
  //
  // Therefore:
  //   - .simpleMajority returns the consensus pick (142 BPM @ 0.92).
  //   - .thresholdGated@0.99 forces universal fallback to maxConfidence over
  //     ALL windows → returns window 0 (100 BPM @ 0.95) since its confidence
  //     beats the consensus cluster's max.
  //
  // If the policy/threshold fields are silently ignored, both calls return the
  // SAME result and this test fails. The assertion checks (bpm, confidence)
  // both differ between the two policies — proves end-to-end plumbing.
  @Test("Options.votingPolicy actually changes analyzeBPM result (plumbing proof)")
  func votingPolicyOptionsFieldActuallyChangesResult() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("aas_voting_divergent_\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try createTwoSegmentClickTrackWAV(
      segment1: ClickSegment(bpm: 100, amplitude: 0.5, durationSeconds: 30),
      segment2: ClickSegment(bpm: 144, amplitude: 0.5, durationSeconds: 60),
      sampleRate: 44100, url: tempURL)

    var opts = AudioAnalysisService.Options()
    opts.mergeStrategy = .windowVoting

    opts.votingPolicy = .simpleMajority
    opts.votingThreshold = 0.0
    let simpleResult = try #require(
      try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts))

    opts.votingPolicy = .thresholdGated
    opts.votingThreshold = 0.99  // forces fallback (real confidences << 0.99)
    let gatedResult = try #require(
      try AudioAnalysisService.analyzeBPM(url: tempURL, options: opts))

    let bpmsDiffer = simpleResult.bpm != gatedResult.bpm
    let confidencesDiffer = simpleResult.confidence != gatedResult.confidence
    // At least one of (bpm, confidence) must differ to prove plumbing. Requiring
    // BOTH (`&&`) is over-strict: a future DSP tweak could shift confidences such
    // that the two policies coincidentally produce equal `confidence` while BPMs
    // still differ — that would still prove plumbing works, but the && would fail.
    // The concrete BPM sanity assertions below independently catch genuine
    // plumbing breakage, so the relaxed `||` does not reduce safety.
    #expect(
      bpmsDiffer || confidencesDiffer,
      """
      simpleMajority vs thresholdGated@0.99 produced indistinguishable results \
      (at least one of bpm/confidence must differ between policies). Either \
      Options.votingPolicy / Options.votingThreshold are silently ignored by \
      analyzeBPM (plumbing bug — AC #3 violation), or the seam audio failed to \
      produce divergent windows on this build. \
      simple=(\(simpleResult.bpm), \(simpleResult.confidence)) \
      gated=(\(gatedResult.bpm), \(gatedResult.confidence))
      """)

    // Concrete sanity: the consensus pick should be near 144 BPM (windows 1+2),
    // and the fallback pick should be near 100 BPM (window 0, highest conf).
    #expect(abs(simpleResult.bpm - 144.0) / 144.0 < 0.05)
    #expect(abs(gatedResult.bpm - 100.0) / 100.0 < 0.05)
  }
}

/// Single click-track segment for `createTwoSegmentClickTrackWAV`.
private struct ClickSegment {
  let bpm: Double
  let amplitude: Float
  let durationSeconds: Double
}

/// Creates a WAV file by concatenating two click-track segments at distinct
/// BPMs and amplitudes. Used by the Story 3-5 voting-policy integration test
/// (Task 6.5) to produce divergent per-window BPM estimates.
private func createTwoSegmentClickTrackWAV(
  segment1: ClickSegment, segment2: ClickSegment,
  sampleRate: Double, url: URL
) throws {
  let totalDuration = segment1.durationSeconds + segment2.durationSeconds
  let totalSamples = Int(sampleRate * totalDuration)
  let segment1Samples = Int(sampleRate * segment1.durationSeconds)
  var samples = [Float](repeating: 0, count: totalSamples)

  let samplesPerBeat1 = Int(sampleRate * 60.0 / segment1.bpm)
  for beatStart in stride(from: 0, to: segment1Samples, by: samplesPerBeat1) {
    let impulseEnd = min(beatStart + 64, segment1Samples)
    for i in beatStart..<impulseEnd {
      let decay = Float(exp(-Double(i - beatStart) / 10.0)) * segment1.amplitude
      samples[i] = decay
    }
  }

  let samplesPerBeat2 = Int(sampleRate * 60.0 / segment2.bpm)
  for beatStart in stride(from: 0, to: totalSamples - segment1Samples, by: samplesPerBeat2) {
    let absStart = segment1Samples + beatStart
    let impulseEnd = min(absStart + 64, totalSamples)
    for i in absStart..<impulseEnd {
      let decay = Float(exp(-Double(i - absStart) / 10.0)) * segment2.amplitude
      samples[i] = decay
    }
  }

  guard
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false)
  else {
    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad format"])
  }

  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  guard
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples))
  else {
    throw NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Buffer failed"])
  }

  buffer.frameLength = AVAudioFrameCount(totalSamples)
  samples.withUnsafeBufferPointer { srcPtr in
    guard let baseAddress = srcPtr.baseAddress else { return }
    buffer.floatChannelData![0].update(from: baseAddress, count: totalSamples)
  }

  try file.write(from: buffer)
}

/// Creates a minimal WAV file with a synthetic click track.
private func createClickTrackWAV(
  bpm: Double, sampleRate: Double, durationSeconds: Double, url: URL
) throws {
  let sampleCount = Int(sampleRate * durationSeconds)
  var samples = [Float](repeating: 0, count: sampleCount)
  let samplesPerBeat = Int(sampleRate * 60.0 / bpm)

  for beatStart in stride(from: 0, to: sampleCount, by: samplesPerBeat) {
    let impulseEnd = min(beatStart + 64, sampleCount)
    for i in beatStart..<impulseEnd {
      let decay = Float(exp(-Double(i - beatStart) / 10.0))
      samples[i] = decay
    }
  }

  guard
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false)
  else {
    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad format"])
  }

  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  guard
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))
  else {
    throw NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Buffer failed"])
  }

  buffer.frameLength = AVAudioFrameCount(sampleCount)
  samples.withUnsafeBufferPointer { srcPtr in
    guard let baseAddress = srcPtr.baseAddress else { return }
    buffer.floatChannelData![0].update(from: baseAddress, count: sampleCount)
  }

  try file.write(from: buffer)
}

// MARK: - Story 4.2: Effective Intensity Reporting

/// Story 4.2 ACs #2-#4: `AudioAnalysisResult.effectiveIntensity` reflects the
/// effective DSP-level depth and `degradationReason` carries an actionable
/// explanation when intensity 8-10 is requested without an `MLTechnique`.
/// Reuses ``BoomBoomBoomKitTestSupport/MockMLTechnique`` (Story 4.3 Task 5.2
/// promotion; DD #7).
@Suite("AudioAnalysisService — Effective Intensity")
struct EffectiveIntensityTests {

  /// AC #2: requests in 1-7 with `mlTechnique = nil` round-trip the requested
  /// intensity and emit no degradation reason.
  @Test("intensity 1-7 (no ML) reports requested, no reason")
  func intensity1ToDefaultReportsRequestedNoReason() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    // Equivalence-class sampling: lower boundary, representative middle, ceiling.
    for raw in [1, 4, 7] {
      var opts = AudioAnalysisService.Options()
      opts.intensity = try #require(AnalysisIntensity(level: raw))
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts))
      #expect(result.effectiveIntensity.level == raw)
      #expect(result.degradationReason == nil)
    }
  }

  /// AC #2: requests in 1-7 with a non-nil `mlTechnique` still report the
  /// requested intensity (intensity 1-7 never engages ML).
  @Test("intensity 1-7 with mock ML reports requested, no reason")
  func intensity1ToDefaultWithMockMLReportsRequestedNoReason() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.mlTechnique = MockMLTechnique()
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(result.effectiveIntensity == .default)
    #expect(result.degradationReason == nil)
  }

  /// AC #3: requests in 8-10 without `mlTechnique` cap at `.default` (7) and
  /// emit a non-nil degradation reason.
  @Test("intensity 8-10 (no ML) caps at 7 with reason")
  func intensity8To10NoMLCapsAt7WithReason() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    for raw in [8, 9, 10] {
      var opts = AudioAnalysisService.Options()
      opts.intensity = try #require(AnalysisIntensity(level: raw))
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts))
      #expect(result.effectiveIntensity == .default)
      #expect(result.degradationReason != nil)
    }
  }

  /// AC #3: degradation message exact-string format for level 9.
  /// Asserts the message uses the ordinal `level`, not the named-constant
  /// identifier.
  @Test("degradationReason exact-string for intensity 9")
  func degradationReasonExactStringForIntensity9() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .level9
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(
      result.degradationReason
        == "Requested intensity 9 requires BoomBoomBoomKitML package. "
        + "Running at intensity 7 (DSP-only).")
  }

  /// AC #3: degradation message exact-string format for `.maximum` (== 10).
  /// Asserts that `.maximum` interpolates as `10`, NOT as `"maximum"`.
  @Test("degradationReason exact-string for .maximum (10)")
  func degradationReasonExactStringForMaximum() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .maximum
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(
      result.degradationReason
        == "Requested intensity 10 requires BoomBoomBoomKitML package. "
        + "Running at intensity 7 (DSP-only).")
  }

  /// AC #4: requests in 8-10 with a non-nil `mlTechnique` round-trip the
  /// requested intensity and emit no degradation reason.
  @Test("intensity 8-10 with mock ML reports requested, no reason")
  func intensity8To10WithMockMLReportsRequestedNoReason() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    for raw in [8, 9, 10] {
      var opts = AudioAnalysisService.Options()
      opts.intensity = try #require(AnalysisIntensity(level: raw))
      opts.mlTechnique = MockMLTechnique()
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts))
      #expect(result.effectiveIntensity.level == raw)
      #expect(result.degradationReason == nil)
    }
  }
}

// MARK: - Story 4.2: Maximum Supported Intensity

/// Story 4.2 AC #6: `AudioAnalysisService.maximumSupportedIntensity(mlTechnique:)`
/// returns `.default` (7) when `nil`, `.maximum` (10) when non-nil.
@Suite("AudioAnalysisService — Maximum Supported Intensity")
struct MaximumSupportedIntensityTests {

  /// AC #6: `nil` mlTechnique returns the DSP-only ceiling (`.default` == 7).
  @Test("maximumSupportedIntensity(nil) returns .default")
  func maximumSupportedIntensityNilReturnsDefault() {
    #expect(
      AudioAnalysisService.maximumSupportedIntensity(mlTechnique: nil)
        == .default)
    // Pin the rawValue invariant — guards against silent drift if `.default`
    // is ever relocated. `dspOnlyMaxIntensity` (DD #3 single source of truth)
    // is private; this assertion verifies the contract via the public API.
    #expect(
      AudioAnalysisService.maximumSupportedIntensity(mlTechnique: nil).level == 7,
      "DSP-only ceiling must remain 7 — guards against silent drift if .default level is relocated"
    )
  }

  /// AC #6: a non-nil mlTechnique conformance returns `.maximum` (10).
  @Test("maximumSupportedIntensity(mock) returns .maximum")
  func maximumSupportedIntensityWithMockReturnsMaximum() {
    #expect(
      AudioAnalysisService.maximumSupportedIntensity(
        mlTechnique: MockMLTechnique())
        == .maximum)
    // Pin the rawValue invariant — guards against silent drift if `.maximum`
    // is ever relocated.
    #expect(
      AudioAnalysisService.maximumSupportedIntensity(
        mlTechnique: MockMLTechnique()
      ).level == 10,
      ".maximum ceiling must remain 10 — guards against silent drift if .maximum level is relocated"
    )
  }
}
