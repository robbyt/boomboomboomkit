//
//  WaveformAnalyzerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.4 (Epic 15, Phase 4) — regression tests for the public
//  waveform surface. Covers the mono in-memory path shipped in Phase 1
//  of the story: silence, pure tones per band, impulse peak preservation,
//  short-file bin arithmetic, and sample-rate invariance.
//
//  The streaming path (Story 15.4a) and the multi-channel policies
//  (Story 15.4b) are reserved; their ACs are covered in follow-ups. One
//  guard in this suite confirms the not-yet-implemented policies throw.
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

  // MARK: - Not-yet-implemented policies throw cleanly

  @Test func reservedChannelPoliciesThrow() {
    let decoded = Self.silentDecoded(seconds: 1)
    for policy: WaveformChannelPolicy in [
      .leftOnly, .rightOnly, .perChannel, .mixDownRespectingPhase,
    ] {
      var options = WaveformOptions()
      options.channelPolicy = policy
      #expect(throws: WaveformAnalyzerError.self) {
        _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
      }
    }
  }

  // MARK: - Cancellation at the start of the pass

  @Test func cancellationAtStartThrows() {
    let decoded = Self.silentDecoded(seconds: 1)
    var options = WaveformOptions()
    options.isCancelled = { true }
    #expect(throws: WaveformAnalyzerError.cancelled) {
      _ = try WaveformAnalyzer.analyze(decoded: decoded, options: options)
    }
  }
}
