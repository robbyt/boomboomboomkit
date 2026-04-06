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

  @Test("analyzeBPM with MP3 fixture returns non-nil result")
  func analyzeBPMWithMP3() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url),
      "Expected non-nil BPM result for real MP3")
    #expect(
      result.bpm >= 40 && result.bpm <= 220,
      "Expected musically plausible BPM (40-220), got \(result.bpm)")
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

  @Test("analyzeLUFS with MP3 fixture returns non-nil Double")
  func analyzeLUFSWithMP3() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let result = try #require(
      try AudioAnalysisService.analyzeLUFS(url: url),
      "Expected non-nil LUFS result for real MP3")
    // LUFS values are typically negative, between -70 and 0
    #expect(
      result < 0 && result > -70,
      "Expected plausible LUFS value (-70 to 0), got \(result)")
  }

  @Test("analyzeLUFS with short FLAC fixture handles gracefully")
  func analyzeLUFSWithShortFLAC() throws {
    let url = try AudioFixtures.url(for: "test-audio", extension: "flac")
    // test-audio.flac is ~1 second — above LUFSAnalyzer's 400ms minimum,
    // so it may or may not return a result depending on content.
    // Key invariant: doesn't crash, and if non-nil, value is plausible.
    let result = try? AudioAnalysisService.analyzeLUFS(url: url)
    if let lufs = result {
      #expect(lufs < 0 && lufs > -70, "Expected plausible LUFS (-70 to 0), got \(lufs)")
    }
  }

  @Test("analyzeLUFS result matches LUFSAnalyzer directly (same value)")
  func analyzeLUFSMatchesDirectCall() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let serviceResult = try AudioAnalysisService.analyzeLUFS(url: url)

    // Direct call for comparison
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 30)
    let directResult = LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: sampleRate)?
      .integratedLoudness

    #expect(serviceResult == directResult, "Service and direct call should return identical values")
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
        try await group.next()
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
