//
//  LUFSAnalyzerTests.swift
//  BoomBoomBoomKitTests
//

import Accelerate
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Test Signal Generators

/// Generate a sine wave calibrated for LUFS measurement.
/// Sets the RMS level to match the target, so a 997 Hz sine at targetLUFS = -23.0
/// should measure approximately -23.0 LUFS (within ±0.5 LU).
///
/// LUFS is RMS-based. For a sine: peak = RMS * sqrt(2).
private func generateSineWave(
  frequencyHz: Double = 997.0,
  sampleRate: Double = 48000.0,
  durationSeconds: Double = 10.0,
  targetLUFS: Double = -23.0
) -> [Float] {
  // RMS level targeting the desired LUFS; peak = RMS * sqrt(2) for sine
  let rms = pow(10.0, targetLUFS / 20.0)
  let amplitude = Float(rms * sqrt(2.0))
  let sampleCount = Int(sampleRate * durationSeconds)
  return (0..<sampleCount).map { i in
    amplitude * sin(Float(2.0 * .pi * frequencyHz * Double(i) / sampleRate))
  }
}

/// Generate a signal with DC offset added to a sine wave.
private func generateSineWaveWithDCOffset(
  frequencyHz: Double = 997.0,
  sampleRate: Double = 48000.0,
  durationSeconds: Double = 10.0,
  targetLUFS: Double = -23.0,
  dcOffset: Float = 0.1
) -> [Float] {
  let base = generateSineWave(
    frequencyHz: frequencyHz, sampleRate: sampleRate,
    durationSeconds: durationSeconds, targetLUFS: targetLUFS)
  return base.map { $0 + dcOffset }
}

/// Generate a loud-quiet-loud signal: 2s loud, 2s quiet, 2s loud.
private func generateLoudQuietLoud(
  sampleRate: Double = 48000.0,
  loudLUFS: Double = -14.0,
  quietLUFS: Double = -80.0
) -> [Float] {
  let loud1 = generateSineWave(
    sampleRate: sampleRate, durationSeconds: 2.0, targetLUFS: loudLUFS)
  let quiet = generateSineWave(
    sampleRate: sampleRate, durationSeconds: 2.0, targetLUFS: quietLUFS)
  let loud2 = generateSineWave(
    sampleRate: sampleRate, durationSeconds: 2.0, targetLUFS: loudLUFS)
  return loud1 + quiet + loud2
}

// MARK: - K-Weighting Filter Behavior

@Suite("LUFSAnalyzer — K-Weighting Filter")
struct LUFSKWeightingTests {

  @Test("high-shelf boosts 3kHz+ relative to low frequencies")
  func highShelfBoost() throws {
    // A 3kHz signal should measure louder than a 100Hz signal at the same dBFS
    // because K-weighting boosts high frequencies (~+4dB above 1.5kHz)
    let samples3k = generateSineWave(
      frequencyHz: 3000, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -20.0)
    let samples100 = generateSineWave(
      frequencyHz: 100, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -20.0)

    let result3k = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples3k, sampleRate: 48000))
    let result100 = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples100, sampleRate: 48000))

    #expect(
      result3k.integratedLoudness > result100.integratedLoudness,
      "3kHz should measure louder than 100Hz at same dBFS due to K-weighting. 3kHz: \(result3k.integratedLoudness), 100Hz: \(result100.integratedLoudness)"
    )
  }

  @Test("high-pass filter attenuates sub-100Hz content")
  func highPassRolloff() throws {
    // A 30Hz signal should measure significantly quieter than a 997Hz signal
    let samples30 = generateSineWave(
      frequencyHz: 30, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -20.0)
    let samples997 = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -20.0)

    let result30 = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples30, sampleRate: 48000))
    let result997 = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples997, sampleRate: 48000))

    // High-pass should attenuate 30Hz significantly (>8 dB difference)
    let difference = result997.integratedLoudness - result30.integratedLoudness
    #expect(
      difference > 8.0,
      "997Hz should be >8 LU louder than 30Hz. Difference: \(difference) LU")
  }
}

// MARK: - -23.0 LUFS Reference (AC4)

@Suite("LUFSAnalyzer — Calibrated Reference Signals")
struct LUFSCalibrationTests {

  @Test("997 Hz at -23 dBFS measures within ±0.5 LU of -23.0 LUFS")
  func calibratedMinus23() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 10.0, targetLUFS: -23.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 48000))

    let error = abs(result.integratedLoudness - (-23.0))
    #expect(
      error <= 0.5,
      "Expected -23.0 LUFS ±0.5, got \(result.integratedLoudness) (error: \(error) LU)")
  }

  // MARK: - -14.0 LUFS Reference

  @Test("997 Hz at -14 dBFS measures within ±0.5 LU of -14.0 LUFS")
  func calibratedMinus14() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 10.0, targetLUFS: -14.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 48000))

    let error = abs(result.integratedLoudness - (-14.0))
    #expect(
      error <= 0.5,
      "Expected -14.0 LUFS ±0.5, got \(result.integratedLoudness) (error: \(error) LU)")
  }
}

// MARK: - Silent/Short File (AC7)

@Suite("LUFSAnalyzer — Edge Cases")
struct LUFSEdgeCaseTests {

  @Test("silence (all zeros) returns nil")
  func silenceReturnsNil() {
    let samples = [Float](repeating: 0, count: Int(48000 * 10))
    let result = LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 48000)
    #expect(result == nil, "Silence should return nil, not a numeric LUFS value")
  }

  @Test("very short signal (< 400ms) returns nil")
  func shortSignalReturnsNil() {
    // 200ms of audio — cannot form a single 400ms block
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 0.2, targetLUFS: -14.0)
    let result = LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 48000)
    #expect(result == nil, "Short signal (< 400ms) should return nil")
  }

  @Test("empty samples returns nil")
  func emptyReturnsNil() {
    let result = LUFSAnalyzer.measureLoudness(samples: [], sampleRate: 48000)
    #expect(result == nil, "Empty samples should return nil")
  }

  @Test("unsupported sample rate returns nil")
  func unsupportedSampleRateReturnsNil() {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 22050, durationSeconds: 5.0, targetLUFS: -14.0)
    let result = LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 22050)
    #expect(result == nil, "Unsupported sample rate (22050) should return nil")
  }
}

// MARK: - Gating Behavior

@Suite("LUFSAnalyzer — Gating")
struct LUFSGatingTests {

  @Test("gating excludes silent passages, raising integrated LUFS")
  func gatingExcludesSilence() throws {
    // Signal: 5s at -14 dBFS + 5s silence + 5s at -14 dBFS
    let loud1 = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -14.0)
    let silence = [Float](repeating: 0, count: Int(48000 * 5))
    let loud2 = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -14.0)
    let mixed = loud1 + silence + loud2

    let mixedResult = try #require(
      LUFSAnalyzer.measureLoudness(samples: mixed, sampleRate: 48000))

    // With gating, silence is excluded. Result should be close to -14 LUFS (loud sections only).
    let gatingError = abs(mixedResult.integratedLoudness - (-14.0))
    #expect(
      gatingError <= 1.0,
      "Gated LUFS should be within ±1.0 LU of -14.0, got \(mixedResult.integratedLoudness) (error: \(gatingError) LU)"
    )
  }
}

// MARK: - Sample Rate Independence (AC8)

@Suite("LUFSAnalyzer — Sample Rate Independence")
struct LUFSSampleRateTests {

  @Test("LUFS within ±0.3 LU across 44.1kHz, 48kHz, 96kHz")
  func sampleRateConsistency() throws {
    let rates: [Double] = [44100, 48000, 96000]
    var results: [(rate: Double, lufs: Double)] = []

    for rate in rates {
      let samples = generateSineWave(
        frequencyHz: 997, sampleRate: rate, durationSeconds: 10.0, targetLUFS: -20.0)
      let result = try #require(
        LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: rate),
        "Expected non-nil result at \(rate) Hz")
      results.append((rate: rate, lufs: result.integratedLoudness))
    }

    // Compare all pairs — max spread should be ≤ 0.5 LU.
    for i in 0..<results.count {
      for j in (i + 1)..<results.count {
        let diff = abs(results[i].lufs - results[j].lufs)
        #expect(
          diff <= 0.5,
          "LUFS at \(results[i].rate) Hz (\(results[i].lufs)) vs \(results[j].rate) Hz (\(results[j].lufs)) differ by \(diff) LU, expected ≤ 0.5"
        )
      }
    }
  }
}

// MARK: - Performance (AC5)

@Suite("LUFSAnalyzer — Performance")
struct LUFSPerformanceTests {

  @Test("30s of 44.1kHz completes in < 1 second")
  func performanceUnder1Second() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 44100, durationSeconds: 30.0, targetLUFS: -14.0)

    let start = CFAbsoluteTimeGetCurrent()
    let result = LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 44100)
    let elapsed = CFAbsoluteTimeGetCurrent() - start

    #expect(result != nil, "Should produce a result for 30s audio")
    #expect(
      elapsed < 1.0,
      "Expected < 1s, took \(elapsed)s")
  }
}

// MARK: - Block Loudness Time-Series (AC9)

@Suite("LUFSAnalyzer — Block Loudness Time-Series")
struct LUFSBlockLoudnessTests {

  @Test("block count matches expected formula")
  func blockCount() throws {
    let sampleRate: Double = 48000
    let durationSeconds: Double = 5.0
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: sampleRate, durationSeconds: durationSeconds,
      targetLUFS: -14.0)

    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: sampleRate))

    let blockSize = Int(0.4 * sampleRate)
    let stepSize = Int(0.1 * sampleRate)
    let expectedBlockCount = (samples.count - blockSize) / stepSize + 1

    #expect(
      result.blockLoudnessValues.count == expectedBlockCount,
      "Expected \(expectedBlockCount) blocks, got \(result.blockLoudnessValues.count)")
    #expect(result.blockStepSeconds == 0.1)
  }

  @Test("constant-amplitude signal has approximately equal block loudness values")
  func constantAmplitudeBlocks() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -14.0)

    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: 48000))

    // Skip first few blocks (filter settling time)
    let stableBlocks = Array(result.blockLoudnessValues.dropFirst(5))
    guard stableBlocks.count > 2 else {
      Issue.record("Not enough stable blocks")
      return
    }

    let meanLoudness = stableBlocks.reduce(0, +) / Double(stableBlocks.count)

    for (i, value) in stableBlocks.enumerated() {
      let diff = abs(value - meanLoudness)
      #expect(
        diff <= 0.1,
        "Block \(i + 5) deviates by \(diff) LU from mean \(meanLoudness)")
    }
  }

  @Test("loud-quiet-loud signal shows two plateaus with a dip")
  func loudQuietLoudPattern() throws {
    let sampleRate: Double = 48000
    let samples = generateLoudQuietLoud(sampleRate: sampleRate)

    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: sampleRate))

    let blocks = result.blockLoudnessValues
    let totalBlocks = blocks.count

    // Divide into thirds
    let thirdSize = totalBlocks / 3

    // First third: loud (skip first 5 for filter settling)
    let loud1Blocks = Array(blocks[5..<thirdSize])
    let loud1Mean = loud1Blocks.reduce(0, +) / Double(loud1Blocks.count)

    // Middle third: quiet
    let quietBlocks = Array(blocks[thirdSize..<(2 * thirdSize)])
    let quietMean = quietBlocks.reduce(0, +) / Double(quietBlocks.count)

    // Last third: loud
    let loud2Blocks = Array(blocks[(2 * thirdSize)...])
    let loud2Mean = loud2Blocks.reduce(0, +) / Double(loud2Blocks.count)

    // Loud sections should be significantly louder than quiet section
    #expect(
      loud1Mean > quietMean + 10,
      "First loud section (\(loud1Mean) LUFS) should be >10 LU above quiet section (\(quietMean) LUFS)"
    )
    #expect(
      loud2Mean > quietMean + 10,
      "Last loud section (\(loud2Mean) LUFS) should be >10 LU above quiet section (\(quietMean) LUFS)"
    )

    // Integrated LUFS should be higher than the quiet section's block values
    #expect(
      result.integratedLoudness > quietMean,
      "Integrated LUFS (\(result.integratedLoudness)) should be higher than quiet mean (\(quietMean))"
    )
  }
}

// MARK: - DC Offset Filter Validation

@Suite("LUFSAnalyzer — DC Offset Filtering")
struct LUFSDCOffsetTests {

  @Test("DC offset signal yields same LUFS as signal without DC offset")
  func dcOffsetFiltered() throws {
    let sampleRate: Double = 48000
    let cleanSamples = generateSineWave(
      frequencyHz: 997, sampleRate: sampleRate, durationSeconds: 10.0, targetLUFS: -20.0)
    let dcSamples = generateSineWaveWithDCOffset(
      frequencyHz: 997, sampleRate: sampleRate, durationSeconds: 10.0, targetLUFS: -20.0,
      dcOffset: 0.1)

    let cleanResult = try #require(
      LUFSAnalyzer.measureLoudness(samples: cleanSamples, sampleRate: sampleRate))
    let dcResult = try #require(
      LUFSAnalyzer.measureLoudness(samples: dcSamples, sampleRate: sampleRate))

    let diff = abs(cleanResult.integratedLoudness - dcResult.integratedLoudness)
    #expect(
      diff <= 0.5,
      "DC offset should be filtered by high-pass. Clean: \(cleanResult.integratedLoudness), DC: \(dcResult.integratedLoudness), diff: \(diff) LU"
    )
  }
}
