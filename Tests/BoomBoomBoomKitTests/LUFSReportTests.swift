//
//  LUFSReportTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.1 — LUFSReport type contract (AC1), fixture matrix (AC4), and
//  the analyzeLUFS nil-vs-throw error contract (AC9).
//

import AVFoundation
import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitTestSupport

// MARK: - Helpers

/// Writes a mono Float32 WAV to a temp path for error-contract tests.
private func writeTempWAV(samples: [Float], sampleRate: Double) throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("lufs-8-1-\(UUID().uuidString).wav")
  let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  let buffer = AVAudioPCMBuffer(
    pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
  buffer.frameLength = AVAudioFrameCount(samples.count)
  samples.withUnsafeBufferPointer { bp in
    buffer.floatChannelData![0].update(from: bp.baseAddress!, count: samples.count)
  }
  try file.write(from: buffer)
  return url
}

private func quietSine(sampleRate: Double, durationSeconds: Double) -> [Float] {
  let count = Int(sampleRate * durationSeconds)
  return (0..<count).map { i in
    0.1 * sin(Float(2.0 * .pi * 997.0 * Double(i) / sampleRate))
  }
}

// MARK: - AC1: LUFSReport type contract

@Suite("LUFSReport — Type Contract")
struct LUFSReportTypeTests {

  private func makeReport(
    integrated: Double = -14.0,
    truePeak: Double = -1.0,
    lra: Double? = 5.0,
    lraLow: Double = -18.0,
    lraHigh: Double = -13.0,
    momentary: [Double] = [-30.0, -10.0, -20.0],
    shortTerm: [Double] = [-15.0, -12.0],
    step: Double = 0.1
  ) -> LUFSReport {
    LUFSReport(
      integratedLUFS: integrated,
      maxTruePeakDBTP: truePeak,
      loudnessRangeLU: lra,
      lraLowLUFS: lraLow,
      lraHighLUFS: lraHigh,
      momentaryLUFS: momentary,
      shortTermLUFS: shortTerm,
      stepSeconds: step)
  }

  @Test("init clamps NaN to the -100.0 sentinel in every loudness scalar field")
  func nanClampScalars() {
    let report = makeReport(
      integrated: .nan, truePeak: .nan, lra: .nan, lraLow: .nan, lraHigh: .nan,
      step: .nan)
    #expect(report.integratedLUFS == -100.0)
    #expect(report.maxTruePeakDBTP == -100.0)
    #expect(report.loudnessRangeLU == -100.0)
    #expect(report.lraLowLUFS == -100.0)
    #expect(report.lraHighLUFS == -100.0)
    // stepSeconds is a time grid, not a loudness — garbage falls back to 0.1.
    #expect(report.stepSeconds == 0.1)
  }

  @Test("init clamps ±Inf to the -100.0 sentinel in every loudness scalar field")
  func infClampScalars() {
    let report = makeReport(
      integrated: .infinity, truePeak: -.infinity, lra: .infinity,
      lraLow: -.infinity, lraHigh: .infinity, step: .infinity)
    #expect(report.integratedLUFS == -100.0)
    #expect(report.maxTruePeakDBTP == -100.0)
    #expect(report.loudnessRangeLU == -100.0)
    #expect(report.lraLowLUFS == -100.0)
    #expect(report.lraHighLUFS == -100.0)
    // stepSeconds is a time grid, not a loudness — garbage falls back to 0.1.
    #expect(report.stepSeconds == 0.1)
  }

  @Test("non-positive or non-finite stepSeconds falls back to the 0.1 grid")
  func stepSecondsGarbageFallback() {
    for bad in [0.0, -1.0, Double.nan, .infinity, -.infinity] {
      #expect(makeReport(step: bad).stepSeconds == 0.1, "stepSeconds \(bad) must fall back")
    }
    // Valid values pass through untouched.
    #expect(makeReport(step: 0.2).stepSeconds == 0.2)
    // The collision the fallback prevents: a zero step would stamp every
    // sample with time 0.0, collapsing LoudnessSample.id.
    let report = makeReport(momentary: [-1.0, -2.0, -3.0], shortTerm: [], step: 0.0)
    #expect(Set(report.samples.map(\.id)).count == 3)
  }

  @Test("init clamps non-finite series elements, element-wise")
  func nonFiniteSeriesClamp() {
    let report = makeReport(
      momentary: [-14.0, .nan, -.infinity], shortTerm: [.infinity, -12.0])
    #expect(report.momentaryLUFS == [-14.0, -100.0, -100.0])
    #expect(report.shortTermLUFS == [-100.0, -12.0])
  }

  @Test("nil loudnessRangeLU is preserved as nil (not clamped)")
  func nilLRAPreserved() {
    let report = makeReport(lra: nil)
    #expect(report.loudnessRangeLU == nil)
  }

  @Test("computed extremes over the series")
  func computedExtremes() {
    let report = makeReport(momentary: [-30.0, -10.0, -20.0], shortTerm: [-15.0, -12.0])
    #expect(report.maxMomentaryLUFS == -10.0)
    #expect(report.minMomentaryLUFS == -30.0)
    #expect(report.maxShortTermLUFS == -12.0)
  }

  @Test("computed extremes are nil on empty series")
  func extremesNilOnEmpty() {
    let report = makeReport(momentary: [], shortTerm: [])
    #expect(report.maxMomentaryLUFS == nil)
    #expect(report.minMomentaryLUFS == nil)
    #expect(report.maxShortTermLUFS == nil)
  }

  @Test("samples adapter flattens both series with grid times and series tags")
  func samplesAdapter() {
    let report = makeReport(momentary: [-30.0, -10.0], shortTerm: [-20.0])
    let samples = report.samples
    #expect(samples.count == 3)
    let momentary = samples.filter { $0.series == .momentary }
    let shortTerm = samples.filter { $0.series == .shortTerm }
    #expect(momentary.map(\.time) == [0.0, 0.1])
    #expect(momentary.map(\.lufs) == [-30.0, -10.0])
    #expect(shortTerm.map(\.time) == [0.0])
    #expect(shortTerm.map(\.lufs) == [-20.0])
    // Identity is unique across series even at the same time.
    #expect(Set(samples.map(\.id)).count == 3)
  }

  @Test("Equatable: identical reports compare equal, different do not")
  func equatable() {
    #expect(makeReport() == makeReport())
    #expect(makeReport(integrated: -15.0) != makeReport())
  }

  @Test("description carries the headline scalars")
  func descriptionFormat() {
    let report = makeReport()
    #expect(report.description.contains("LUFS"))
    #expect(report.description.contains("dBTP"))
    #expect(report.description.contains("LU"))
    // nil LRA renders as n/a
    #expect(makeReport(lra: nil).description.contains("n/a"))
  }

  @Test("LoudnessSeries is a closed 2-case set")
  func loudnessSeriesCaseCount() {
    #expect(LoudnessSeries.allCases.count == 2)
  }

  @Test(
    "LoudnessSample init sanitizes non-finite time/lufs so Hashable stays reflexive",
    arguments: [Double.nan, .signalingNaN, .infinity, -.infinity])
  func loudnessSampleNonFiniteSanitized(bad: Double) {
    // Non-finite in EITHER field: the sanitized value must keep the synthesized
    // Equatable/Hashable over Double reflexive and Set membership consistent.
    let badTime = LoudnessSample(time: bad, lufs: -14.0, series: .momentary)
    #expect(badTime.time.isFinite, "non-finite time \(bad) must become finite")
    #expect(badTime.time == 0.0, "non-finite time \(bad) must normalize to 0.0")

    let badLufs = LoudnessSample(time: 1.5, lufs: bad, series: .shortTerm)
    #expect(
      badLufs.lufs == LUFSReport.sentinelFloor,
      "non-finite lufs \(bad) must become the sentinel")

    for sample in [badTime, badLufs] {
      #expect(sample == sample, "sanitized sample must be reflexive for \(bad)")
      var set: Set<LoudnessSample> = [sample]
      #expect(set.contains(sample), "sanitized sample must be Set-locatable for \(bad)")
      #expect(!set.insert(sample).inserted, "duplicate insert must be a no-op for \(bad)")
    }
  }

  @Test("LoudnessSample canonicalizes -0.0 time so equal values share one id and one Set slot")
  func loudnessSampleSignedZeroId() {
    let negZero = LoudnessSample(time: -0.0, lufs: -14.0, series: .momentary)
    let posZero = LoudnessSample(time: 0.0, lufs: -14.0, series: .momentary)
    // Direct proof of canonicalization, not only via id.
    #expect(negZero.time.sign == .plus)
    #expect(negZero == posZero)
    #expect(negZero.id == posZero.id)
    #expect(Set([negZero, posZero]).count == 1)
  }

  @Test("LoudnessSample preserves valid finite payloads (finite sub-sentinel lufs is not floored)")
  func loudnessSampleFinitePreserved() {
    let sample = LoudnessSample(time: 1.5, lufs: -14.0, series: .momentary)
    #expect(sample.time == 1.5)
    #expect(sample.lufs == -14.0)
    // The init replaces only NON-finite lufs; a finite value below the sentinel
    // is preserved (same contract as LUFSReport).
    let deep = LoudnessSample(time: 2.0, lufs: -150.0, series: .shortTerm)
    #expect(deep.lufs == -150.0)
  }

  @Test("analyzer block-loudness floor is the same value as the report sentinel (issue #68)")
  func analyzerFloorMatchesReportSentinel() {
    // Single source of truth: LUFSAnalyzer.blockLoudnessFloor is now an alias
    // for LUFSReport.sentinelFloor. This locks the coupling so a future edit to
    // one floor cannot silently diverge from the other. The value must stay
    // -100.0 (byte-identity invariant).
    #expect(LUFSReport.sentinelFloor == LUFSAnalyzer.blockLoudnessFloor)
    #expect(LUFSReport.sentinelFloor == -100.0)
  }
}

// MARK: - AC4: fixture matrix

@Suite("analyzeLUFS — Fixture Matrix")
struct LUFSFixtureMatrixTests {

  private func analyze(name: String, ext: String) throws -> LUFSReport? {
    let url = try AudioFixtures.url(for: name, extension: ext)
    return try AudioAnalysisService.analyzeLUFS(url: url)
  }

  @Test(
    "every container format returns a non-nil report with finite integrated and non-empty momentary",
    arguments: [
      ("test-bwf", "wav"),
      ("sample-with-cover", "aiff"),
      ("sample-with-cover", "mp3"),
      ("sample-with-cover", "flac"),
      ("sample-with-cover", "m4a"),
      ("test-bwf", "caf"),
    ])
  func fixtureMatrix(name: String, ext: String) throws {
    let report = try #require(
      try analyze(name: name, ext: ext),
      "Expected non-nil LUFSReport for \(name).\(ext)")
    #expect(report.integratedLUFS.isFinite)
    #expect(!report.momentaryLUFS.isEmpty)
    #expect(report.stepSeconds == 0.1)
  }

  @Test("WAV and CAF transcodes of the same audio measure identically")
  func wavCafParity() throws {
    let wav = try #require(try analyze(name: "test-bwf", ext: "wav"))
    let caf = try #require(try analyze(name: "test-bwf", ext: "caf"))
    // Same Int16 LPCM payload in two containers — decode is lossless.
    #expect(abs(wav.integratedLUFS - caf.integratedLUFS) <= 0.01)
    #expect(wav.momentaryLUFS.count == caf.momentaryLUFS.count)
  }
}

// MARK: - AC9: nil-vs-throw error contract

@Suite("analyzeLUFS — Error Contract")
struct LUFSErrorContractTests {

  @Test("unsupported sample rate throws LUFSAnalysisError with the rate and supported list")
  func unsupportedRateThrows() throws {
    // sample.wav is a real 8 kHz fixture — readable by PCMBufferReader, but
    // outside the K-weighting coefficient table.
    let url = try AudioFixtures.url(for: "sample", extension: "wav")
    do {
      _ = try AudioAnalysisService.analyzeLUFS(url: url)
      Issue.record("Expected LUFSAnalysisError.unsupportedSampleRate")
    } catch let LUFSAnalysisError.unsupportedSampleRate(sampleRate, supported) {
      #expect(sampleRate == 8000)
      #expect(supported == [44100, 48000, 96000])
    }
  }

  @Test("unreadable file still throws PCMBufferReaderError")
  func unreadableFileThrows() {
    let url = URL(fileURLWithPath: "/nonexistent/lufs-8-1.wav")
    #expect(throws: PCMBufferReaderError.self) {
      try AudioAnalysisService.analyzeLUFS(url: url)
    }
  }

  @Test("all-silence input measures to nil (not a throw, not a number)")
  func silenceReturnsNil() throws {
    let url = try writeTempWAV(
      samples: [Float](repeating: 0, count: Int(44100 * 2)), sampleRate: 44100)
    defer { try? FileManager.default.removeItem(at: url) }
    let report = try AudioAnalysisService.analyzeLUFS(url: url)
    #expect(report == nil)
  }

  @Test("sub-400ms input measures to nil (not a throw, not a number)")
  func shortInputReturnsNil() throws {
    let url = try writeTempWAV(
      samples: quietSine(sampleRate: 44100, durationSeconds: 0.2), sampleRate: 44100)
    defer { try? FileManager.default.removeItem(at: url) }
    let report = try AudioAnalysisService.analyzeLUFS(url: url)
    #expect(report == nil)
  }

  @Test(
    "garbage maxSeconds values are sanitized to full-file analysis (no trap, no throw)",
    arguments: [Double.nan, .infinity, -.infinity, 0.0, -5.0, 1.0e15])
  func garbageMaxSecondsSanitized(value: Double) throws {
    // Unsanitized, NaN/Inf/huge values trap in the reader's
    // Int64(sampleRate * maxSeconds) conversion (a fatalError, not a throw).
    let url = try writeTempWAV(
      samples: quietSine(sampleRate: 44100, durationSeconds: 1.0), sampleRate: 44100)
    defer { try? FileManager.default.removeItem(at: url) }
    let baseline = try #require(try AudioAnalysisService.analyzeLUFS(url: url))
    var options = LUFSOptions()
    options.maxSeconds = value
    let report = try #require(
      try AudioAnalysisService.analyzeLUFS(url: url, options: options))
    #expect(report == baseline)
  }

  // MARK: - decoded: overload (parity with the url path, issue #59)

  @Test(
    "decoded overload: unsupported rate throws (parity with the url path)",
    arguments: [22050.0, 8000.0] as [Double])
  func decodedUnsupportedRateThrows(rate: Double) {
    // Two distinct unsupported rates prove the guard is rate-table-driven, not
    // hardcoded. The decoded: overload's throw path is otherwise untested — the
    // url: path is locked by unsupportedRateThrows, this is its sibling.
    let samples = quietSine(sampleRate: rate, durationSeconds: 2.0)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: rate)
    #expect(throws: LUFSAnalysisError.self) {
      try AudioAnalysisService.analyzeLUFS(decoded: decoded)
    }
    do {
      _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
      Issue.record("Expected LUFSAnalysisError.unsupportedSampleRate")
    } catch let LUFSAnalysisError.unsupportedSampleRate(sampleRate, supported) {
      #expect(sampleRate == rate)
      #expect(supported == [44100, 48000, 96000])
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test(
    "decoded overload: every supported rate succeeds",
    arguments: [44100.0, 48000.0, 96000.0] as [Double])
  func decodedSupportedRatesSucceed(rate: Double) throws {
    let samples = quietSine(sampleRate: rate, durationSeconds: 5.0)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: rate)
    let report = try #require(try AudioAnalysisService.analyzeLUFS(decoded: decoded))
    #expect(report.integratedLUFS.isFinite)
  }
}
