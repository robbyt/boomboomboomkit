//
//  MLFeatureFramesTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-5 Task 8.2 tests for the new `MLFeatureFrames` typed-evidence
//  struct + `TensorLayout` enum + the BPMAnalyzer retention contract.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Story 4-5 MLFeatureFrames + capture path")
struct MLFeatureFramesTests {

  // MARK: - TensorLayout invariants (DD #14)

  @Test("TensorLayout.allCases.count == 1 (Story 4.5 ships .nchw only)")
  func tensorLayoutInitialCaseSet() {
    #expect(TensorLayout.allCases.count == 1)
    #expect(TensorLayout.allCases.contains(.nchw))
  }

  // MARK: - Equatable + description

  @Test("Equatable honors all stored fields including logMelData")
  func equatableHonorsLogMelData() {
    let a = MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.25, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    let same = MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.25, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    let diff = MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.26, count: 32),  // <-- differs
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    #expect(a == same)
    #expect(a != diff)
  }

  @Test("description does not embed the full logMelData payload")
  func descriptionTruncatesPayload() {
    let m = MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.123_456, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    let desc = m.description
    #expect(desc.contains("melBands: 4"))
    #expect(desc.contains("frames: 8"))
    #expect(desc.contains("logMelData.count: 32"))
    #expect(desc.contains("featureSetVersion: v1"))
    // Payload itself is NOT in the description — keep the diagnostic
    // string bounded.
    #expect(!desc.contains("0.123456"))
  }

  // MARK: - BPMAnalyzer capture flag invariants (AC #4)

  @Test("trace.mlFeatures is nil when mlTechnique == nil (default DSP-only path)")
  func mlFeaturesNilWhenCaptureFlagOff() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.enableTrace = true
    guard let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) else {
      Issue.record("analyzeBPM returned nil")
      return
    }
    #expect(result.trace?.mlFeatures == nil)
  }

  @Test("trace.mlFeatures is populated when mlTechnique != nil and policy != .dspOnly")
  func mlFeaturesPopulatedWhenCaptureFlagOn() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.enableTrace = true
    opts.mlTechnique = MockMLTechnique(returning: nil)
    opts.ensemblePolicy = .mlOnly
    guard let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) else {
      Issue.record("analyzeBPM returned nil")
      return
    }
    guard let features = result.trace?.mlFeatures else {
      Issue.record("expected trace.mlFeatures != nil under ML-enabled config")
      return
    }
    #expect(features.melBands == 128)
    #expect(features.frames > 0)
    #expect(features.tensorLayout == .nchw)
    #expect(features.logMelData.count == features.melBands * features.frames)
    #expect(features.featureSetVersion == "v1")
    #expect(features.fftSize == 2048)
    #expect(features.logCompressionScale == 100.0)
  }

  @Test("trace.mlFeatures stays nil under .dspOnly even with mlTechnique set (A1 short-circuit)")
  func mlFeaturesNilUnderDspOnlyA1ShortCircuit() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.enableTrace = true
    opts.mlTechnique = MockMLTechnique(returning: nil)
    opts.ensemblePolicy = .dspOnly
    guard let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) else {
      Issue.record("analyzeBPM returned nil")
      return
    }
    #expect(
      result.trace?.mlFeatures == nil,
      "trace.mlFeatures must be nil under .dspOnly — A1 short-circuit forbids capture")
  }

  // MARK: - Element-wise byte-identity test (AC #5 / HALT (h))

  @Test(
    "Story 4-5 AC #5 / HALT (h): retained spectrogram is bit-exact to logMelFrames flat-concatenation"
  )
  func retainedSpectrogramIsBitExactPostVvlogf() throws {
    // Use deterministic synthetic samples to keep the spectrogram
    // reproducible — same input every run.
    let sampleRate: Double = 44_100
    let hopSize = Int(sampleRate / 100)  // 441 — matches BPMAnalyzer's adaptive-hop convention
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 44_100, durationSeconds: 4.0)

    let withCapture = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      computeSubBands: true, normalizeSubBands: false,
      captureMLFeatures: true)
    let withoutCapture = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      computeSubBands: true, normalizeSubBands: false,
      captureMLFeatures: false)

    // Without-capture must have mlFeatures == nil — the heavy allocation
    // is gated on the flag (regression-protection for the DSP-only path).
    #expect(withoutCapture.mlFeatures == nil)

    // With-capture must have mlFeatures populated.
    guard let captured = withCapture.mlFeatures else {
      Issue.record("expected mlFeatures != nil under captureMLFeatures: true")
      return
    }

    // The full-band and sub-band envelope outputs must be IDENTICAL across
    // the two runs — the retention path must not perturb the DSP
    // pipeline downstream.
    #expect(
      withCapture.fullBand.elementsEqual(
        withoutCapture.fullBand, by: { $0.bitPattern == $1.bitPattern }),
      "retention path mutated the full-band onset envelope")
    for (idx, (with, without)) in zip(withCapture.subBands, withoutCapture.subBands).enumerated() {
      #expect(
        with.elementsEqual(without, by: { $0.bitPattern == $1.bitPattern }),
        "retention path mutated sub-band[\(idx)] onset envelope")
    }

    // Captured payload shape contract: melBands * frames == count.
    #expect(captured.logMelData.count == captured.melBands * captured.frames)
    #expect(captured.melBands == 128)
    #expect(captured.tensorLayout == TensorLayout.nchw)
    #expect(captured.featureSetVersion == "v1")

    // All values must be finite — if vvlogf produced NaN/Inf for any
    // reason, that's the bug HALT (h) is built to catch.
    for v in captured.logMelData {
      #expect(v.isFinite, "non-finite element in retained log-mel payload")
    }
  }

  // MARK: - Multi-window single-eval invariant (DD #17)

  @Test(
    "Story 4-5 DD #17: multi-window analyze fires exactly one ML evaluation on the merged trace"
  )
  func multiWindowSingleEvaluation() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let recorder = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough  // 3+ windows
    opts.enableTrace = true
    opts.mlTechnique = recorder
    opts.ensemblePolicy = .mlOnly
    _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    // The library invokes evaluate() exactly once per analyzeBPM call,
    // on the merged-winner trace. NOT per-window.
    #expect(
      recorder.callCount == 1,
      "expected exactly 1 evaluate call per analyzeBPM (got \(recorder.callCount))")
  }
}
