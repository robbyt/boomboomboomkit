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

  @Test("TensorLayout.allCases.count == 2 (Story 4.5 review pass added .frameMajorLogMel)")
  func tensorLayoutInitialCaseSet() {
    #expect(TensorLayout.allCases.count == 2)
    #expect(TensorLayout.allCases.contains(.nchw))
    #expect(TensorLayout.allCases.contains(.frameMajorLogMel))
  }

  // MARK: - Equatable + description

  @Test("Equatable honors all stored fields including logMelData")
  func equatableHonorsLogMelData() throws {
    let a = try MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.25, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    let same = try MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.25, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    let diff = try MLFeatureFrames(
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
  func descriptionTruncatesPayload() throws {
    let m = try MLFeatureFrames(
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

  // MARK: - Throwing init invariants (Unit 2 / DN4)

  @Test("init throws .invalidFeatureShape when melBands <= 0")
  func initThrowsOnZeroMelBands() {
    #expect(throws: MLTechniqueError.self) {
      _ = try MLFeatureFrames(
        melBands: 0, frames: 8, tensorLayout: .frameMajorLogMel,
        logMelData: [], sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1")
    }
  }

  @Test("init throws .invalidFeatureShape when frames <= 0")
  func initThrowsOnZeroFrames() {
    #expect(throws: MLTechniqueError.self) {
      _ = try MLFeatureFrames(
        melBands: 4, frames: 0, tensorLayout: .frameMajorLogMel,
        logMelData: [], sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1")
    }
  }

  @Test("init throws .invalidFeatureShape when logMelData.count != melBands * frames")
  func initThrowsOnCountMismatch() {
    #expect(throws: MLTechniqueError.self) {
      _ = try MLFeatureFrames(
        melBands: 4, frames: 8, tensorLayout: .frameMajorLogMel,
        logMelData: [Float](repeating: 0.0, count: 31),  // 4*8 = 32, not 31
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1")
    }
  }

  @Test("init throws .invalidFeatureShape when total payload exceeds size cap")
  func initThrowsOnOversizedPayload() {
    // Story 4-5 review pass N5: exercise the size-cap branch without
    // allocating 8.96M floats. The internal `_withTestingMaximumLogMelDataCount`
    // helper temporarily lowers the cap so we can construct a small but
    // over-cap payload, then restores the production cap on scope exit.
    MLFeatureFrames._withTestingMaximumLogMelDataCount(100) {
      #expect(throws: MLTechniqueError.self) {
        _ = try MLFeatureFrames(
          melBands: 4, frames: 30, tensorLayout: .frameMajorLogMel,
          // 4 * 30 = 120 > 100 (test cap)
          logMelData: [Float](repeating: 0.0, count: 120),
          sampleRate: 44_100, fftSize: 2048, hopSize: 441,
          melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
          featureSetVersion: "v1")
      }
    }
    // Production cap restored — sanity-check by constructing a payload that
    // exceeds the test cap but stays under the production cap.
    let smallButOverTestCap = try? MLFeatureFrames(
      melBands: 4, frames: 30, tensorLayout: .frameMajorLogMel,
      logMelData: [Float](repeating: 0.0, count: 120),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1")
    #expect(
      smallButOverTestCap != nil,
      "production cap should be restored after _withTestingMaximumLogMelDataCount exits")
  }

  @Test("init accepts .frameMajorLogMel and .nchw layouts")
  func initAcceptsBothLayouts() throws {
    let fm = try MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .frameMajorLogMel,
      logMelData: [Float](repeating: 0.0, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1")
    let nchw = try MLFeatureFrames(
      melBands: 4, frames: 8, tensorLayout: .nchw,
      logMelData: [Float](repeating: 0.0, count: 32),
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: "v1")
    #expect(fm.tensorLayout == .frameMajorLogMel)
    #expect(nchw.tensorLayout == .nchw)
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
    // Producer emits `.frameMajorLogMel` (post-Story-4-5 review fix DN3).
    // The `.nchw` tag is reserved for future producers (e.g., a CoreML
    // conformance) whose retention path emits mel-major bytes.
    #expect(features.tensorLayout == .frameMajorLogMel)
    #expect(features.logMelData.count == features.melBands * features.frames)
    #expect(features.featureSetVersion == "v1")
    #expect(features.fftSize == 2048)
    #expect(features.logCompressionScale == 100.0)
  }

  @Test(
    "AC #14: trace.mlFeatures is populated when mlTechnique != nil + .mlOnly + enableTrace == false"
  )
  func mlFeaturesPopulatedWithAutoTraceWhenEnableTraceOff() throws {
    // Post-Story-4-5 review pass M5: the `enableTrace` knob does NOT gate
    // ML feature capture — `analyzeBPM` auto-enables trace when
    // `mlTechnique != nil && policy != .dspOnly`. This test pins that
    // invariant by USING A RECORDING MOCK to capture the trace the helper
    // actually passed in (the v1 of this test only asserted `result.trace
    // == nil` which is true for any cause; the v2 directly observes the
    // mock's view).
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.intensity = .default
    opts.enableTrace = false  // <-- the load-bearing config
    opts.mlTechnique = mock
    opts.ensemblePolicy = .mlOnly
    guard let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) else {
      Issue.record("analyzeBPM returned nil")
      return
    }
    // Public-API contract: `result.trace == nil` because `enableTrace ==
    // false` — consumers don't see the auto-built trace.
    #expect(result.trace == nil)
    // The load-bearing invariant: the mock saw an auto-built trace, AND
    // that trace had mlFeatures populated. This is the auto-trace pipeline
    // proof; a regression that disabled auto-trace would land mock.callCount
    // == 0 (helper short-circuit) or mock.lastTrace?.mlFeatures == nil
    // (capture flag not propagated). Both failure modes are now testable.
    #expect(mock.callCount == 1, "ML should be invoked exactly once for the merged-window trace")
    let trace = try #require(
      mock.lastTrace, "RecordingMock.lastTrace must be set after evaluate(trace:)")
    let features = try #require(
      trace.mlFeatures, "auto-trace pipeline must populate mlFeatures under .mlOnly")
    #expect(features.melBands == 128)
    #expect(features.frames > 0)
    #expect(features.logMelData.count == features.melBands * features.frames)
    #expect(features.featureSetVersion == "v1")
    #expect(features.tensorLayout == .frameMajorLogMel)
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

    // Story 4-5 review pass M2: capture the post-`vvlogf` per-frame log-mel
    // matrix via the test-only `onPostVvlogf` closure. The closure deep-copies
    // each row via `frames.map { Array($0) }` so the captured value is
    // INDEPENDENT of the array the retention block subsequently reads — any
    // future mutation between the closure and the retention path would diverge
    // the bitPattern comparison below.
    var postVvlogfCapture: [[Float]] = []
    let withCapture = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      computeSubBands: true, normalizeSubBands: false,
      captureMLFeatures: true,
      onPostVvlogf: { frames in
        postVvlogfCapture = frames.map { Array($0) }
      })
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
    #expect(captured.tensorLayout == TensorLayout.frameMajorLogMel)
    #expect(captured.featureSetVersion == "v1")

    // All values must be finite — if vvlogf produced NaN/Inf for any
    // reason, that's the bug HALT (h) is built to catch.
    for v in captured.logMelData {
      #expect(v.isFinite, "non-finite element in retained log-mel payload")
    }

    // Story 4-5 review pass M2 (HALT (h) literal): element-wise bitPattern
    // equality between the independently-captured post-`vvlogf` matrix
    // and the retained `mlFeatures.logMelData`. The capture is a deep
    // copy of `logMelFrames` taken AT the point in the DSP loop where
    // `vvlogf` has just written; the retention path then reads
    // `logMelFrames` and concatenates it. If any code between the
    // closure and the retention path mutates the frames, the
    // bit-patterns diverge here.
    #expect(
      !postVvlogfCapture.isEmpty,
      "onPostVvlogf must have been invoked when captureMLFeatures: true")
    let flatPostVvlogf = postVvlogfCapture.flatMap { $0 }
    #expect(
      captured.logMelData.count == flatPostVvlogf.count,
      "retained payload count diverges from post-vvlogf flat count")
    #expect(
      captured.logMelData.elementsEqual(flatPostVvlogf, by: { $0.bitPattern == $1.bitPattern }),
      "retained logMelData diverges from independent post-vvlogf deep-copy element-wise")
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
