//
//  WaveformAnalyzerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.4 (Epic 15, Phase 4): regression tests for the public
//  waveform surface. Covers the mono in-memory path shipped in Phase 1
//  of the story: silence, pure tones per band, impulse peak preservation,
//  short-file bin arithmetic, and sample-rate invariance.
//
//  The streaming path (Story 15.4a) and multi-channel input (Story 15.4b)
//  are follow-ups with their own ACs. This suite also covers option
//  validation, per-chunk cancellation, and per-chunk progress reporting.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("WaveformAnalyzer (Story 15.4)")
struct WaveformAnalyzerTests {

  // MARK: - Helpers

  private static func silentDecoded(seconds: Double, sampleRate: Double = 44_100)
    -> FeatureSubstrate.DecodedAudio
  {
    let count = Int(seconds * sampleRate)
    return FeatureSubstrate.DecodedAudio(
      samples: [Float](repeating: 0, count: count),
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
  }

  private static func sineDecoded(
    frequency: Double,
    amplitude: Float = 0.5,
    seconds: Double,
    sampleRate: Double = 44_100
  ) -> FeatureSubstrate.DecodedAudio {
    let count = Int(seconds * sampleRate)
    var samples = [Float](repeating: 0, count: count)
    for i in 0..<count {
      let phase = 2.0 * .pi * frequency * Double(i) / sampleRate
      samples[i] = amplitude * Float(sin(phase))
    }
    return FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
  }

  // MARK: - AC #1: silence

  @Test func silentInputProducesSilenceFloorOutputs() throws {
    let result = try WaveformAnalyzer.analyze(decoded: Self.silentDecoded(seconds: 10))
    #expect(result.detail.magnitudes.allSatisfy { $0.isFinite && $0 == 0 })
    #expect(result.overview.signedMins.allSatisfy { $0.isFinite && $0 == 0 })
    #expect(result.overview.signedMaxes.allSatisfy { $0.isFinite && $0 == 0 })
    #expect(result.energy.lowBand.allSatisfy { $0.isFinite && $0 < 1e-6 })
    #expect(result.energy.midBand.allSatisfy { $0.isFinite && $0 < 1e-6 })
    #expect(result.energy.highBand.allSatisfy { $0.isFinite && $0 < 1e-6 })
  }

  // MARK: - AC #2: band energy winners by tone frequency

  @Test func pureSineAtLowFrequencyWinsLowBand() throws {
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.sineDecoded(frequency: 60, seconds: 5))
    // Skip the first bin and the last bin: biquad settling + partial-tail
    // samples skew the first/last bin's RMS. The interior tells the story.
    let interior = Array(1..<(result.energy.lowBand.count - 1))
    let lowMean =
      interior.map { Double(result.energy.lowBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let midMean =
      interior.map { Double(result.energy.midBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let highMean =
      interior.map { Double(result.energy.highBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    #expect(lowMean > 2 * midMean, "60 Hz tone: low \(lowMean) vs mid \(midMean)")
    #expect(lowMean > 10 * highMean, "60 Hz tone: low \(lowMean) vs high \(highMean)")
  }

  @Test func pureSineAtMidFrequencyWinsMidBand() throws {
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.sineDecoded(frequency: 1_000, seconds: 5))
    let interior = Array(1..<(result.energy.lowBand.count - 1))
    let lowMean =
      interior.map { Double(result.energy.lowBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let midMean =
      interior.map { Double(result.energy.midBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let highMean =
      interior.map { Double(result.energy.highBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    #expect(midMean > 2 * lowMean, "1 kHz tone: mid \(midMean) vs low \(lowMean)")
    #expect(midMean > 2 * highMean, "1 kHz tone: mid \(midMean) vs high \(highMean)")
  }

  @Test func pureSineAtHighFrequencyWinsHighBand() throws {
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.sineDecoded(frequency: 10_000, seconds: 5))
    let interior = Array(1..<(result.energy.lowBand.count - 1))
    let lowMean =
      interior.map { Double(result.energy.lowBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let midMean =
      interior.map { Double(result.energy.midBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    let highMean =
      interior.map { Double(result.energy.highBand[$0]) }.reduce(0, +)
      / Double(interior.count)
    #expect(highMean > 2 * midMean, "10 kHz tone: high \(highMean) vs mid \(midMean)")
    #expect(highMean > 10 * lowMean, "10 kHz tone: high \(highMean) vs low \(lowMean)")
  }

  // MARK: - AC #4: short-file bin arithmetic

  @Test func shortFileFinalBinSizedCorrectly() throws {
    // 97 ms at 44.1 kHz -> 4277 samples. At 150 cps -> ceil(4277*150/44100)
    // = ceil(14.55) = 15 bins.
    let sampleRate: Double = 44_100
    let frameCount = Int(0.097 * sampleRate)
    let samples = [Float](repeating: 0.5, count: frameCount)
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let result = try WaveformAnalyzer.analyze(decoded: decoded)
    let expected = Int((Double(frameCount) * 150.0 / sampleRate).rounded(.up))
    #expect(result.detail.magnitudes.count == expected, "bin count")
    // Strict monotonicity.
    for i in 1..<result.detail.binStartSamples.count {
      #expect(
        result.detail.binStartSamples[i] > result.detail.binStartSamples[i - 1],
        "binStartSamples not strictly monotonic at index \(i)"
      )
    }
    #expect(result.detail.binStartSamples.last! < frameCount)
    #expect(result.detail.coveredSampleRange == 0..<frameCount)
  }

  // MARK: - AC #7: impulse peak preservation

  @Test func singleImpulseIsRetainedInOverview() throws {
    // 2 s of silence at 44.1 kHz with a single +1.0 impulse at t = 1.0 s.
    let sampleRate: Double = 44_100
    let frameCount = Int(2.0 * sampleRate)
    var samples = [Float](repeating: 0, count: frameCount)
    let impulseSample = frameCount / 2
    samples[impulseSample] = 1.0
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let result = try WaveformAnalyzer.analyze(decoded: decoded)

    // Find the bin containing the impulse.
    let binWithImpulse = result.detail.binStartSamples.firstIndex { start in
      let idx = result.detail.binStartSamples.firstIndex(of: start)!
      let end =
        idx + 1 < result.detail.binStartSamples.count
        ? result.detail.binStartSamples[idx + 1] : frameCount
      return start <= impulseSample && impulseSample < end
    }
    let bin = try #require(binWithImpulse, "no bin covers the impulse sample")

    // Detail envelope: peak of abs over that bin's range equals the impulse amplitude.
    #expect(abs(result.detail.magnitudes[bin] - 1.0) < 1e-6)
    // Overview: signed max in that bin equals the impulse amplitude.
    #expect(abs(result.overview.signedMaxes[bin] - 1.0) < 1e-6)
    // The impulse's bin's start is within one bin's worth of samples of the impulse.
    let binWidthSamples = Int(sampleRate / Double(result.detail.columnsPerSecond))
    let distance = abs(result.detail.binStartSamples[bin] - impulseSample)
    #expect(distance <= binWidthSamples, "bin start \(distance) samples from impulse")
  }

  // MARK: - AC #8: sample-rate invariance for a mid-band tone

  @Test func midBandWinnerConsistentAcrossSampleRates() throws {
    for sampleRate: Double in [44_100.0, 48_000.0, 96_000.0] {
      let result = try WaveformAnalyzer.analyze(
        decoded: Self.sineDecoded(frequency: 1_000, seconds: 3, sampleRate: sampleRate))
      let interior = Array(1..<(result.energy.lowBand.count - 1))
      let lowMean =
        interior.map { Double(result.energy.lowBand[$0]) }.reduce(0, +)
        / Double(interior.count)
      let midMean =
        interior.map { Double(result.energy.midBand[$0]) }.reduce(0, +)
        / Double(interior.count)
      let highMean =
        interior.map { Double(result.energy.highBand[$0]) }.reduce(0, +)
        / Double(interior.count)
      #expect(
        midMean > lowMean && midMean > highMean,
        "sr=\(sampleRate): mid \(midMean) is not the winner (low \(lowMean), high \(highMean))"
      )
      // The overview must retain the sine's ±0.5 peak at every rate.
      let maxOverview = result.overview.signedMaxes.max()!
      #expect(abs(maxOverview - 0.5) < 1e-3, "sr=\(sampleRate) peak drifted to \(maxOverview)")
    }
  }

  // MARK: - Option validation

  @Test func defaultCrossoverThrowsAtEightKilohertz() {
    // Default midHighCutoffHz is 4000 Hz, which equals Nyquist at 8 kHz.
    let decoded = Self.silentDecoded(seconds: 1, sampleRate: 8_000)
    #expect(
      throws: WaveformAnalyzerError.midHighCutoffOutOfRange(
        midHighCutoffHz: 4_000, nyquistHz: 4_000)
    ) {
      _ = try WaveformAnalyzer.analyze(decoded: decoded)
    }
  }

  @Test func crossoverBelowNyquistAnalyzesEightKilohertz() throws {
    var options = WaveformOptions()
    options.midHighCutoffHz = 3_000
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.sineDecoded(frequency: 1_000, seconds: 2, sampleRate: 8_000),
      options: options)
    #expect(result.energy.midHighCutoffHz == 3_000)
    #expect(result.detail.magnitudes.count == 300)
  }

  @Test func lowMidCutoffOutOfRangeThrows() {
    let decoded = Self.silentDecoded(seconds: 1)
    for lowMid: Double in [0, -10, 4_000, 5_000] {
      var options = WaveformOptions()
      options.lowMidCutoffHz = lowMid
      #expect(
        throws: WaveformAnalyzerError.lowMidCutoffOutOfRange(
          lowMidCutoffHz: lowMid, midHighCutoffHz: 4_000),
        "lowMidCutoffHz \(lowMid)"
      ) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
      }
    }
  }

  @Test func nonPositiveMidHighCutoffThrowsMidHighError() {
    // A zero or negative mid / high crossover is the mid / high guard's
    // error, not the low / mid one.
    let decoded = Self.silentDecoded(seconds: 1)
    for midHigh: Double in [0, -100] {
      var options = WaveformOptions()
      options.midHighCutoffHz = midHigh
      #expect(
        throws: WaveformAnalyzerError.midHighCutoffOutOfRange(
          midHighCutoffHz: midHigh, nyquistHz: 22_050),
        "midHighCutoffHz \(midHigh)"
      ) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
      }
    }
  }

  @Test func nonFiniteCutoffsThrowTheirOwnCase() {
    // NaN payloads never compare equal, so match on the case.
    let decoded = Self.silentDecoded(seconds: 1)
    for value in [Double.nan, .infinity, -.infinity] {
      var lowMid = WaveformOptions()
      lowMid.lowMidCutoffHz = value
      #expect(throws: WaveformAnalyzerError.self) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: lowMid)
      }
      do {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: lowMid)
        Issue.record("lowMidCutoffHz \(value) did not throw")
      } catch WaveformAnalyzerError.lowMidCutoffOutOfRange {
      } catch {
        Issue.record("lowMidCutoffHz \(value) threw \(error)")
      }

      var midHigh = WaveformOptions()
      midHigh.midHighCutoffHz = value
      #expect(throws: WaveformAnalyzerError.self) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: midHigh)
      }
      do {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: midHigh)
        Issue.record("midHighCutoffHz \(value) did not throw")
      } catch WaveformAnalyzerError.midHighCutoffOutOfRange {
      } catch {
        Issue.record("midHighCutoffHz \(value) threw \(error)")
      }
    }
  }

  @Test func columnsPerSecondOutOfRangeThrows() {
    let decoded = Self.silentDecoded(seconds: 1, sampleRate: 8_000)
    for cps in [0, -1, 8_001, 16_000] {
      var options = WaveformOptions()
      options.columnsPerSecond = cps
      #expect(
        throws: WaveformAnalyzerError.columnsPerSecondOutOfRange(
          columnsPerSecond: cps, sampleRate: 8_000),
        "columnsPerSecond \(cps)"
      ) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
      }
    }
  }

  /// The cadence bound is compared as `Double`, so a finite sample rate above
  /// `Int.max` validates instead of trapping in `Int(sampleRate)`, and a
  /// cadence above a small rate still throws.
  @Test func validateDoesNotTrapOnHugeSampleRate() throws {
    try WaveformAnalyzer.validate(options: .init(), sampleRate: 1e300)

    var options = WaveformOptions()
    options.columnsPerSecond = 150
    #expect(
      throws: WaveformAnalyzerError.columnsPerSecondOutOfRange(
        columnsPerSecond: 150, sampleRate: 100)
    ) {
      try WaveformAnalyzer.validate(options: options, sampleRate: 100)
    }
  }

  @Test func columnsPerSecondAtSampleRateIsAccepted() throws {
    var options = WaveformOptions()
    options.columnsPerSecond = 8_000
    options.midHighCutoffHz = 3_000
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.silentDecoded(seconds: 0.1, sampleRate: 8_000), options: options)
    #expect(result.detail.binStartSamples == Array(0..<800))
  }

  // MARK: - Bin boundaries above one column per sample

  @Test func binStartSamplesCapAtFrameCountAndStayStrictlyIncreasing() {
    // cps twice the sample rate would ask for 2 * frameCount bins; the
    // helper caps the count at frameCount so every bin holds one sample.
    let frameCount = 1_000
    let bins = WaveformAnalyzer.computeBinStartSamples(
      frameCount: frameCount, sampleRate: 8_000, columnsPerSecond: 16_000)
    #expect(bins.count == frameCount)
    #expect(bins == Array(0..<frameCount))
    for i in 1..<bins.count {
      #expect(bins[i] > bins[i - 1], "not strictly increasing at \(i)")
    }
  }

  @Test func binStartSamplesEmptyForZeroColumnsPerSecond() {
    #expect(
      WaveformAnalyzer.computeBinStartSamples(
        frameCount: 1_000, sampleRate: 8_000, columnsPerSecond: 0
      ).isEmpty)
  }

  // MARK: - Cancellation

  @Test func cancellationAtStartThrows() {
    let decoded = Self.silentDecoded(seconds: 1)
    var options = WaveformOptions()
    options.isCancelled = { true }
    #expect(throws: WaveformAnalyzerError.cancelled) {
      _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
    }
  }

  @Test func cancellationMidPassThrowsAndStopsProgress() {
    // 20 s at 150 cps -> 3000 bins -> 12 chunks per pass. Flip cancellation
    // on after a handful of checks so it lands inside the first pass.
    let decoded = Self.silentDecoded(seconds: 20)
    let calls = LockedCounter()
    let reports = LockedRecorder()
    let cancelAfter = 5
    var options = WaveformOptions()
    options.isCancelled = { calls.increment() > cancelAfter }
    options.onProgress = { reports.append($0) }
    #expect(throws: WaveformAnalyzerError.cancelled) {
      _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
    }
    // The flip was observed, and checking stopped at that call.
    #expect(calls.value == cancelAfter + 1)
    let values = reports.values
    #expect(!values.isEmpty)
    #expect(values.last! < 1.0, "a cancelled run must not report completion")
    // 1 start report + one per completed chunk before the cancelling check.
    #expect(values.count == cancelAfter)
  }

  @Test func cancellationBetweenFilterPassesThrows() {
    // Cancel at the check that precedes the first filter pass: 1 start
    // check + 12 detail chunks, so the 14th call is the pre-filter check.
    let decoded = Self.silentDecoded(seconds: 20)
    let calls = LockedCounter()
    var options = WaveformOptions()
    options.isCancelled = { calls.increment() >= 14 }
    #expect(throws: WaveformAnalyzerError.cancelled) {
      _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
    }
    #expect(calls.value == 14)
  }

  // MARK: - Progress

  @Test func progressIsMonotonicPerChunkAndEndsAtOne() throws {
    let decoded = Self.silentDecoded(seconds: 20)
    let reports = LockedRecorder()
    var options = WaveformOptions()
    options.onProgress = { reports.append($0) }
    let result = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
    let binCount = result.detail.magnitudes.count
    let chunksPerPass =
      (binCount + WaveformAnalyzer.progressChunkBins - 1) / WaveformAnalyzer.progressChunkBins
    let values = reports.values
    #expect(values.first == 0.0)
    #expect(values.last == 1.0)
    #expect(values.count == 1 + 4 * chunksPerPass)
    for i in 1..<values.count {
      #expect(values[i] >= values[i - 1], "progress decreased at report \(i)")
    }
    #expect(values.allSatisfy { (0.0...1.0).contains($0) })
  }

  @Test func emptyInputReportsStartAndCompletionOnly() throws {
    let reports = LockedRecorder()
    var options = WaveformOptions()
    options.onProgress = { reports.append($0) }
    let result = try WaveformAnalyzer.analyze(
      decoded: Self.silentDecoded(seconds: 0), options: options)
    #expect(result.detail.binStartSamples.isEmpty)
    #expect(result.detail.magnitudes.isEmpty)
    #expect(result.overview.signedMins.isEmpty)
    #expect(result.overview.signedMaxes.isEmpty)
    #expect(result.energy.lowBand.isEmpty)
    #expect(result.energy.midBand.isEmpty)
    #expect(result.energy.highBand.isEmpty)
    #expect(reports.values == [0.0, 1.0])
  }
}

// MARK: - Thread-safe test recorders

private final class LockedCounter: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0

  /// Increments and returns the new count.
  func increment() -> Int {
    lock.lock()
    defer { lock.unlock() }
    count += 1
    return count
  }

  var value: Int {
    lock.lock()
    defer { lock.unlock() }
    return count
  }
}

private final class LockedRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var recorded: [Double] = []

  func append(_ value: Double) {
    lock.lock()
    defer { lock.unlock() }
    recorded.append(value)
  }

  var values: [Double] {
    lock.lock()
    defer { lock.unlock() }
    return recorded
  }
}
