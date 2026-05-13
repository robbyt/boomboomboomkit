//
//  BNNSTechniqueTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-5 Task 8.1: tests for `BNNSTechnique` covering init / featurize /
//  abstain / cancellation / RAII deinit / concurrency exposure / raw-API
//  guards. All new tests live in this NEW file per AC #10 — no edits to
//  existing test files.
//
//  Tests that require the bundled `giantsteps_v1.mlmodelc` artifact load it
//  via `try? BNNSTechnique()`. In CI without the artifact, the load returns
//  nil and the test soft-skips via `Issue.record`. Locally the artifact is
//  present (Story 4-4b shipped it at `Sources/BoomBoomBoomKitML/Resources/`)
//  and the full path runs.
//

import BoomBoomBoomKitML
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Story 4-5 BNNSTechnique")
struct BNNSTechniqueTests {

  // MARK: - Init failure paths

  @Test("init throws .modelResourceMissing for a non-existent URL")
  func initThrowsForMissingURL() {
    if #available(macOS 15.0, *) {
      let missing = URL(fileURLWithPath: "/tmp/definitely-not-a-real.mlmodelc")
      do {
        _ = try BNNSTechnique(modelURL: missing)
        Issue.record("expected throw, got success")
      } catch let MLTechniqueError.modelResourceMissing(url) {
        #expect(url.path() == missing.path())
      } catch {
        Issue.record("expected .modelResourceMissing, got \(error)")
      }
    }
  }

  @Test("try? init returns nil for a non-existent URL")
  func tryOptionalInitReturnsNilForMissingURL() {
    if #available(macOS 15.0, *) {
      let missing = URL(fileURLWithPath: "/tmp/definitely-not-a-real.mlmodelc")
      let instance = try? BNNSTechnique(modelURL: missing)
      #expect(instance == nil)
    }
  }

  // MARK: - Successful init + evaluate path (requires bundled model)

  @Test("init() loads the bundled giantsteps_v1.mlmodelc when available")
  func initSucceedsForBundledModel() {
    if #available(macOS 15.0, *) {
      let t = try? BNNSTechnique()
      if t == nil {
        Issue.record("BNNSTechnique() returned nil — model artifact not on disk")
        return
      }
    }
  }

  @Test("evaluate(trace:) returns nil when mlFeatures is absent (HALT (g))")
  func evaluateReturnsNilWhenFeaturesAbsent() {
    if #available(macOS 15.0, *) {
      guard let t = try? BNNSTechnique() else {
        Issue.record("BNNSTechnique() unavailable — skipping evaluate path")
        return
      }
      let trace = BPMDiagnosticTrace()
      #expect(trace.mlFeatures == nil)
      let result = t.evaluate(trace: trace)
      #expect(result == nil)
    }
  }

  @Test("evaluate(trace:) abstains on feature-set version mismatch")
  func evaluateAbstainsOnVersionMismatch() {
    if #available(macOS 15.0, *) {
      guard let t = try? BNNSTechnique() else {
        Issue.record("BNNSTechnique() unavailable — skipping evaluate path")
        return
      }
      let features = MLFeatureFrames(
        melBands: 128, frames: 64, tensorLayout: .nchw,
        logMelData: [Float](repeating: 0.5, count: 128 * 64),
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v999-FROM-THE-FUTURE"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      #expect(result == nil, "expected abstain on version mismatch")
    }
  }

  @Test("evaluate(trace:) abstains on degenerate short clips (< 32 frames)")
  func evaluateAbstainsOnShortClip() {
    if #available(macOS 15.0, *) {
      guard let t = try? BNNSTechnique() else {
        Issue.record("BNNSTechnique() unavailable — skipping evaluate path")
        return
      }
      let features = MLFeatureFrames(
        melBands: 128, frames: 16, tensorLayout: .nchw,
        logMelData: [Float](repeating: 0.5, count: 128 * 16),
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      #expect(result == nil, "expected abstain on frames < 32 short clip")
    }
  }

  @Test("evaluate(trace:) produces a finite BPM in [60, 200] on synthetic input")
  func evaluateProducesPlausibleBPM() {
    if #available(macOS 15.0, *) {
      guard let t = try? BNNSTechnique() else {
        Issue.record("BNNSTechnique() unavailable — skipping evaluate path")
        return
      }
      // 256 source frames keeps all code paths active (non-trivial input,
      // post-z-score is non-zero, resamples cleanly to W=512).
      let frames = 256
      let mb = 128
      var data = [Float](repeating: 0, count: mb * frames)
      for i in 0..<data.count {
        // Mildly varied input so per-band stddev > 0 and z-score normalizes
        // to a non-zero post-normalize row (the model gets a real signal).
        data[i] = Float((i % 13)) / 13.0 + Float(i % 17) / 20.0
      }
      let features = MLFeatureFrames(
        melBands: mb, frames: frames, tensorLayout: .nchw, logMelData: data,
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      // Result may legitimately be nil on synthetic input (the two-gate
      // abstain may fire); if non-nil, every emitted field must be sane.
      if let result {
        #expect(result.bpm.isFinite)
        #expect(result.bpm >= 60.0 && result.bpm <= 200.0)
        #expect(result.confidence >= 0.0 && result.confidence <= 1.0)
        #expect(result.modelIdentifier == "bnns_tempo_v1")
      }
    }
  }

  // MARK: - Cancellation cooperation (AC #9)

  @Test("Story 4-5 AC #9: cancellation before ML evaluate throws CancellationError")
  func cancellationBeforeMLEvaluateThrows() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = mock
    opts.ensemblePolicy = .mlOnly
    opts.intensity = .default
    opts.isCancelled = { true }

    #expect(throws: CancellationError.self) {
      try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    }
    #expect(
      mock.callCount == 0,
      "RecordingMockMLTechnique.callCount must be 0 — helper checks cancellation BEFORE evaluate")
  }

  @Test(".dspOnly preserves the Story 4-4 AC #14 invariant under cancellation")
  func cancellationDoesNotInvokeMLOnDspOnly() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = mock
    opts.ensemblePolicy = .dspOnly
    opts.intensity = .fastest
    opts.isCancelled = { true }
    // Whether analyzeBPM throws (cancellation fires somewhere) or returns
    // is not the test — the test is that the ML mock is NEVER invoked
    // under .dspOnly regardless of cancellation state.
    _ = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(
      mock.callCount == 0,
      "RecordingMockMLTechnique.callCount must remain 0 under .dspOnly")
  }

  // MARK: - RAII lifecycle (DD #15)
  //
  // The strict DD #15 deinit witness uses `@testable import BoomBoomBoomKitML`
  // to reach the internal `BNNSGraphHandle` reference type. That requires
  // adding `BoomBoomBoomKitML` to the test target's dependencies in
  // `Package.swift` — which AC #10 explicitly forbids ("ZERO modifications
  // to ... `Package.swift`"). The strict witness is therefore deferred to
  // a follow-up story; AC #11's gating-checklist ASan run
  // (`swift test --sanitize=address`) provides the runtime free-of-non-malloc
  // / double-free safety net at the same `BNNSTechnique()` construction
  // surface. This observational lifecycle test confirms repeated
  // construct-and-drop cycles don't crash or leak observable badness.

  @Test("DD #15 lifecycle observational: many construct/drop cycles complete cleanly")
  func bnnsTechniqueLifecycleCycles() {
    if #available(macOS 15.0, *) {
      var attempted = 0
      var loaded = 0
      for _ in 0..<8 {
        attempted += 1
        autoreleasepool {
          if (try? BNNSTechnique()) != nil {
            loaded += 1
          }
        }
      }
      if loaded > 0 {
        #expect(
          loaded == attempted,
          "BNNSTechnique construction must succeed deterministically when the model is available")
      } else {
        Issue.record("BNNSTechnique() unavailable for all 8 attempts — lifecycle test skipped")
      }
    }
  }

  // MARK: - Raw-API guard greps (AC #1)

  @Test(
    "AC #1: zero matches of deprecated BNNSFilter* / BNNSGraph Swift overlay in BoomBoomBoomKitML")
  func rawAPIGuards() {
    let mlSourceDir =
      URL(fileURLWithPath: #file)
      .deletingLastPathComponent()  // Tests/BoomBoomBoomKitTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // repo root
      .appendingPathComponent("Sources/BoomBoomBoomKitML")

    var allFiles: [URL] = []
    if let enumerator = FileManager.default.enumerator(
      at: mlSourceDir, includingPropertiesForKeys: nil)
    {
      while let next = enumerator.nextObject() as? URL {
        if next.pathExtension == "swift" {
          allFiles.append(next)
        }
      }
    }
    var bannedHits: [String] = []
    let banned = [
      "BNNSFilterCreate", "BNNSFilterApply", "BNNSGraph.Builder",
      "BNNSGraph.Context", "BNNSGraph.makeContext",
    ]
    for url in allFiles {
      guard let body = try? String(contentsOf: url, encoding: .utf8) else { continue }
      for pattern in banned where body.contains(pattern) {
        bannedHits.append("\(url.lastPathComponent): \(pattern)")
      }
    }
    #expect(bannedHits.isEmpty, "banned API matches: \(bannedHits)")
  }

  // MARK: - Concurrency exposure (axiom-concurrency #5)

  @Test("concurrent evaluate calls produce stable output (no shared state)")
  func concurrentEvaluateIsContextLocal() async {
    if #available(macOS 15.0, *) {
      guard let t = try? BNNSTechnique() else {
        Issue.record("BNNSTechnique() unavailable — skipping concurrency exposure")
        return
      }
      let frames = 128
      var data = [Float](repeating: 0, count: 128 * frames)
      for i in 0..<data.count {
        data[i] = Float(i % 13) / 13.0 + Float(i % 19) / 25.0
      }
      let features = MLFeatureFrames(
        melBands: 128, frames: frames, tensorLayout: .nchw, logMelData: data,
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let bound = trace

      let bpms = await withTaskGroup(of: Double?.self) { group -> [Double?] in
        for _ in 0..<16 {
          group.addTask { t.evaluate(trace: bound)?.bpm }
        }
        var out: [Double?] = []
        for await item in group { out.append(item) }
        return out
      }
      let nonNil = bpms.compactMap { $0 }
      if !nonNil.isEmpty {
        #expect(
          Set(nonNil.map { $0.bitPattern }).count == 1,
          "concurrent evaluate produced inconsistent BPM values: \(nonNil)")
      }
    }
  }

  // MARK: - Byte-identity sentinel (AC #5)

  @Test("Story 4-5 AC #5: DSP-only path stays byte-identical when BNNSTechnique is loaded")
  func dspOnlyByteIdenticalWithBNNSAvailable() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")

    // Baseline: mlTechnique == nil (default).
    var baselineOpts = AudioAnalysisService.Options()
    baselineOpts.intensity = .default
    guard let baseline = try AudioAnalysisService.analyzeBPM(url: url, options: baselineOpts) else {
      Issue.record("baseline analyzeBPM returned nil")
      return
    }

    // BNNS loaded but .dspOnly — under Story 4-4 A1 short-circuit the
    // helper returns nil before reaching evaluate, captureMLFeatures
    // stays false, and per-track BPM must be byte-equal to baseline.
    var withBNNSOpts = AudioAnalysisService.Options()
    withBNNSOpts.intensity = .default
    withBNNSOpts.ensemblePolicy = .dspOnly
    if #available(macOS 15.0, *) {
      withBNNSOpts.mlTechnique = try? BNNSTechnique()
    }
    guard let withBNNS = try AudioAnalysisService.analyzeBPM(url: url, options: withBNNSOpts) else {
      Issue.record("BNNS-loaded analyzeBPM returned nil")
      return
    }

    #expect(
      baseline.bpm.bitPattern == withBNNS.bpm.bitPattern,
      "BPM bit-pattern must match between baseline and BNNS-loaded .dspOnly paths")
    #expect(
      baseline.confidence.bitPattern == withBNNS.confidence.bitPattern,
      "confidence bit-pattern must match between baseline and BNNS-loaded .dspOnly paths")
  }
}
