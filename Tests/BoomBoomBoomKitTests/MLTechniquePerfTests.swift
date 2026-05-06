//
//  MLTechniquePerfTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4.3 wiring/plumbing coverage for the mock-on-abstaining ML path.
//  Per Codex finalization (party-mode 2026-05-05) of the AC #7 second-gate
//  HALT discussion: the per-call ratio enforcement moved to the benchmark
//  suite (`Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift`,
//  env-gated on OA300_CORPUS_PATH, hard-fail at 1.30x recorded baseline).
//  This file retains correctness/plumbing coverage only — it asserts that
//  both paths return non-nil results and that the analyzer does not crash
//  on the mock-injected hot path. The aggregate wall-clock measurement is
//  printed for visibility but NOT asserted here; the corpus-grain
//  benchmark (which has stable iteration counts and matches the venue
//  designed for performance data) owns that gate.
//
//  Story 4-3b owns the trace-build cost investigation that will tighten
//  the threshold from 1.30x against measured floor data.
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("MLTechnique Perf — wiring/plumbing")
struct MLTechniquePerfTests {

  /// AC #7 wiring proof at unit-test scale: both paths return non-nil
  /// results on a 30s synthetic click track at intensity .fastest, and the
  /// aggregate ratio is printed for visibility. The hard ratio assertion
  /// lives in `PerformanceBenchmarkTests.swift` against the OA300 corpus
  /// (Codex 2026-05-05 finalization).
  ///
  /// This @Test runs on every `make test`. It catches:
  /// - Crashes on the mock-injected path.
  /// - Plumbing breaks where `MLTechnique.evaluate` is no longer invoked
  ///   (the print would show a 1.0x ratio if the mock path were dead).
  /// - Compile-time drift in the `MockMLTechnique(returning:)` API.
  @Test("mlTechnique=nil and mock(returning:nil) both return non-nil results; ratio printed")
  func wiringPlumbingPaths() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("ml_technique_perf_30s.wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try writeClickTrackWAV(
      bpm: 120, sampleRate: 44100, durationSeconds: 30, url: tempURL)

    var baselineOpts = AudioAnalysisService.Options()
    baselineOpts.intensity = .fastest
    baselineOpts.mlTechnique = nil

    var withMockOpts = AudioAnalysisService.Options()
    withMockOpts.intensity = .fastest
    withMockOpts.mlTechnique = MockMLTechnique(returning: nil)

    let warmupIterations = 2
    let measuredIterations = 6

    // Warmup interleaved so neither path has cold-cache disadvantage.
    for _ in 0..<warmupIterations {
      _ = try AudioAnalysisService.analyzeBPM(url: tempURL, options: baselineOpts)
      _ = try AudioAnalysisService.analyzeBPM(url: tempURL, options: withMockOpts)
    }

    let baselineElapsed = ContinuousClock().measure {
      for _ in 0..<measuredIterations {
        _ = try? AudioAnalysisService.analyzeBPM(url: tempURL, options: baselineOpts)
      }
    }
    let withMockElapsed = ContinuousClock().measure {
      for _ in 0..<measuredIterations {
        _ = try? AudioAnalysisService.analyzeBPM(url: tempURL, options: withMockOpts)
      }
    }

    let baselineSeconds = secondsOf(baselineElapsed)
    let withMockSeconds = secondsOf(withMockElapsed)
    let ratio = withMockSeconds / baselineSeconds
    print(
      "MLTechniquePerf — baselineTotal=\(baselineSeconds)s mockTotal=\(withMockSeconds)s ratio=\(ratio) iterations=\(measuredIterations) (visibility only; corpus-grain gate at PerformanceBenchmarkTests)"
    )

    // Plumbing correctness: both paths must produce a non-nil result. If
    // either path returns nil on a clean 30s click track, that's a real
    // regression even at unit-test scale.
    let baselineResult = try AudioAnalysisService.analyzeBPM(
      url: tempURL, options: baselineOpts)
    let mockResult = try AudioAnalysisService.analyzeBPM(
      url: tempURL, options: withMockOpts)
    #expect(
      baselineResult != nil, "baseline analyzeBPM should return a result on a clean click track")
    #expect(
      mockResult != nil, "mock-injected analyzeBPM should return a result on a clean click track")
  }
}

private func secondsOf(_ duration: Duration) -> Double {
  let comps = duration.components
  return Double(comps.seconds) + Double(comps.attoseconds) / 1.0e18
}

private func writeClickTrackWAV(
  bpm: Double, sampleRate: Double, durationSeconds: Double, url: URL
) throws {
  let samples = generateClickTrack(
    bpm: bpm, sampleRate: sampleRate, durationSeconds: durationSeconds)
  guard
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false)
  else {
    throw NSError(
      domain: "MLTechniquePerfTests", code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Bad format"])
  }
  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  guard
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
  else {
    throw NSError(
      domain: "MLTechniquePerfTests", code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Buffer failed"])
  }
  buffer.frameLength = AVAudioFrameCount(samples.count)
  samples.withUnsafeBufferPointer { srcPtr in
    guard let base = srcPtr.baseAddress else { return }
    buffer.floatChannelData![0].update(from: base, count: samples.count)
  }
  try file.write(from: buffer)
}
