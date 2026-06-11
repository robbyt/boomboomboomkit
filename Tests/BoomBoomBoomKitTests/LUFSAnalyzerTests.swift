//
//  LUFSAnalyzerTests.swift
//  BoomBoomBoomKitTests
//

import Accelerate
import BoomBoomBoomKitTestSupport
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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples3k, sampleRate: 48000)))
    let result100 = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples100, sampleRate: 48000)))

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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples30, sampleRate: 48000)))
    let result997 = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples997, sampleRate: 48000)))

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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))

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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))

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
    let result = LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000))
    #expect(result == nil, "Silence should return nil, not a numeric LUFS value")
  }

  @Test("very short signal (< 400ms) returns nil")
  func shortSignalReturnsNil() {
    // 200ms of audio — cannot form a single 400ms block
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 0.2, targetLUFS: -14.0)
    let result = LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000))
    #expect(result == nil, "Short signal (< 400ms) should return nil")
  }

  @Test("empty samples returns nil")
  func emptyReturnsNil() {
    let result = LUFSAnalyzer.measureLoudness(decoded: .synthetic([], sampleRate: 48000))
    #expect(result == nil, "Empty samples should return nil")
  }

  @Test("unsupported sample rate returns nil")
  func unsupportedSampleRateReturnsNil() {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 22050, durationSeconds: 5.0, targetLUFS: -14.0)
    let result = LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 22050))
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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(mixed, sampleRate: 48000)))

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
        LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: rate)),
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
    let result = LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 44100))
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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: sampleRate)))

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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))

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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: sampleRate)))

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

// MARK: - Short-Term Series (Story 8.1, AC5)

/// Converts a display-domain LUFS value back to mean-square energy.
private func energyFromLUFS(_ lufs: Double) -> Double {
  pow(10.0, (lufs + 0.691) / 10.0)
}

@Suite("LUFSAnalyzer — Short-Term Series")
struct LUFSShortTermTests {

  @Test("short-term window count: cells − 29 on the 100ms grid")
  func shortTermCount() throws {
    // 10s @ 48k → 100 cells → 71 short-term windows.
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 10.0, targetLUFS: -20.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    #expect(result.shortTermLoudnessValues.count == 71)
  }

  @Test("input shorter than 3s yields empty short-term series, non-empty momentary")
  func shortInputEmptyShortTerm() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 2.0, targetLUFS: -14.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    #expect(result.shortTermLoudnessValues.isEmpty)
    #expect(!result.blockLoudnessValues.isEmpty)
  }

  @Test("constant signal: short-term matches momentary plateau")
  func constantSignalPlateau() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 10.0, targetLUFS: -14.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    // Compare stable interior values (skip filter settle).
    let momentary = result.blockLoudnessValues[40]
    let shortTerm = result.shortTermLoudnessValues[40]
    #expect(abs(momentary - shortTerm) <= 0.05)
  }

  @Test(
    "AC5: level-step short-term matches the EXACT 3.0s rectangle; a 3.3s triangular approximation fails"
  )
  func exactRectangleAtLevelStep() throws {
    // 5s at -30 LUFS + 5s at -10 LUFS @ 48k. The step lands exactly on a
    // 100ms cell boundary (cell 50).
    let quiet = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -30.0)
    let loud = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 5.0, targetLUFS: -10.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(quiet + loud, sampleRate: 48000)))

    let st = result.shortTermLoudnessValues
    #expect(st.count == 71)

    // Self-calibrated plateau energies (no dependence on absolute calibration).
    let plateau1 = Array(st[10...15]).reduce(0, +) / 6.0  // fully in region 1
    let plateau2 = Array(st[60...65]).reduce(0, +) / 6.0  // fully in region 2
    let c1 = energyFromLUFS(plateau1)
    let c2 = energyFromLUFS(plateau2)

    // Window i=38 covers cells 38..67: 12 cells region 1, 18 cells region 2.
    // Exact rectangle expectation: energy-domain mix, log applied last.
    let expected = -0.691 + 10.0 * log10((12.0 * c1 + 18.0 * c2) / 30.0)
    let measured = st[38]
    #expect(
      abs(measured - expected) <= 0.05,
      "short-term at step crossing must match exact-rectangle mix: measured \(measured), expected \(expected)"
    )

    // The would-fail alternative (DD #4): averaging 30 overlapping 400ms block
    // mean-squares = a 3.3s triangular window. Computed from the actual block
    // series — it deviates from the exact-rectangle expectation, proving this
    // test discriminates.
    let blockMS = result.blockLoudnessValues[38..<68].map(energyFromLUFS)
    let triangular = -0.691 + 10.0 * log10(blockMS.reduce(0, +) / 30.0)
    #expect(
      abs(triangular - expected) > 0.1,
      "discriminator: triangular approximation (\(triangular)) should NOT match the rectangle expectation (\(expected))"
    )
  }
}

// MARK: - Loudness Range (Story 8.1, AC7)

@Suite("LUFSAnalyzer — Loudness Range")
struct LUFSLoudnessRangeTests {

  @Test("gated program under 60s yields nil LRA with sentinel band edges")
  func under60SecondsNil() throws {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 30.0, targetLUFS: -14.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    #expect(result.loudnessRange == nil)
    #expect(result.lraLow == -100.0)
    #expect(result.lraHigh == -100.0)
    #expect(!result.shortTermLoudnessValues.isEmpty)
  }

  @Test("exactly 60.0s of fully-gated programme yields non-nil LRA (boundary)")
  func exactlySixtySecondsBoundary() throws {
    // 60.0s @ 48k → 571 short-term windows spanning (571−1)·0.1 + 3.0 = 60.0s
    // of programme exactly. A guard that counts windows as 0.1s each (57.1s)
    // would wrongly return nil here — this test locks the coverage semantics.
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 60.0, targetLUFS: -14.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    let lra = try #require(
      result.loudnessRange, "60.0s fully-gated programme must yield non-nil LRA")
    #expect(
      lra >= 0.0 && lra <= 0.5,
      "constant-level signal must measure near-zero LRA, got \(lra)")
  }

  @Test("AC7: two-level 70s signal yields LRA ≈ 20 LU (P95 − P10) with matching band edges")
  func twoLevelSeventySeconds() throws {
    // 35s at -30 LUFS + 35s at -10 LUFS @ 48k. Both levels survive the
    // Tech 3342 gates (relative gate ≈ -32.6 LUFS).
    let quiet = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 35.0, targetLUFS: -30.0)
    let loud = generateSineWave(
      frequencyHz: 997, sampleRate: 48000, durationSeconds: 35.0, targetLUFS: -10.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(quiet + loud, sampleRate: 48000)))

    let lra = try #require(result.loudnessRange, "70s gated program must yield non-nil LRA")
    #expect(abs(lra - 20.0) <= 0.5, "expected LRA ≈ 20 LU, got \(lra)")
    // Band edges are the percentiles themselves.
    #expect(result.lraHigh - result.lraLow == lra)
    // Edges sit on the two plateaus (self-calibrated, generous tolerance for
    // K-weighting offset at 997 Hz).
    let st = result.shortTermLoudnessValues
    let plateauLow = Array(st[100...150]).reduce(0, +) / 51.0
    let plateauHigh = Array(st[400...450]).reduce(0, +) / 51.0
    #expect(abs(result.lraLow - plateauLow) <= 0.5)
    #expect(abs(result.lraHigh - plateauHigh) <= 0.5)
  }
}

// MARK: - Reference-Signal Tolerances (Story 8.1, DD #12)

@Suite("LUFSAnalyzer — Reference Tolerances")
struct LUFSReferenceToleranceTests {

  private func integrated(
    sampleRate: Double, targetLUFS: Double
  ) throws -> Double {
    let samples = generateSineWave(
      frequencyHz: 997, sampleRate: sampleRate, durationSeconds: 10.0,
      targetLUFS: targetLUFS)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: sampleRate)))
    return result.integratedLoudness
  }

  @Test("48 kHz: 997 Hz calibrated sine within ±0.1 LU (measured delta +0.00002)")
  func reference48k() throws {
    #expect(abs(try integrated(sampleRate: 48000, targetLUFS: -23.0) - (-23.0)) <= 0.1)
    #expect(abs(try integrated(sampleRate: 48000, targetLUFS: -14.0) - (-14.0)) <= 0.1)
  }

  @Test("44.1 kHz: bilinear-derived coefficients hold ±0.1 LU (measured delta −0.001)")
  func reference441k() throws {
    #expect(abs(try integrated(sampleRate: 44100, targetLUFS: -23.0) - (-23.0)) <= 0.1)
    #expect(abs(try integrated(sampleRate: 44100, targetLUFS: -14.0) - (-14.0)) <= 0.1)
  }

  @Test(
    "96 kHz: pre-existing −0.477 LU coefficient offset, locked at ±0.1 around the MEASURED value")
  func reference96k() throws {
    // The bundled 96k high-shelf bilinear coefficients have a pre-existing
    // gain deficit at 997 Hz (+0.214 dB vs the 48k prototype's +0.691 dB →
    // −0.477 LU systematic offset; verified analytically against the biquad
    // response, present in the pre-Story-8.1 analyzer). Coefficients are
    // FROZEN by the byte-identity contract (AC6) — per the DD #12
    // measure-and-record rule, the tolerance is pinned around the measured
    // offset, not silently widened around the nominal target. Coefficient
    // correction is a deferred-work item (requires a byte-identity
    // re-baseline story).
    let offset = -0.4767
    #expect(abs(try integrated(sampleRate: 96000, targetLUFS: -23.0) - (-23.0 + offset)) <= 0.1)
    #expect(abs(try integrated(sampleRate: 96000, targetLUFS: -14.0) - (-14.0 + offset)) <= 0.1)
  }
}

// MARK: - True Peak (Story 8.1, AC8)

/// Inter-sample-peak sine: f = sampleRate/4 with π/4 phase puts every sample
/// at ±A/√2 while the continuous waveform reaches A between samples — the
/// classic +3 dB ISP construction.
private func interSamplePeakSine(
  sampleRate: Double, amplitude: Float, durationSeconds: Double
) -> [Float] {
  let count = Int(sampleRate * durationSeconds)
  return (0..<count).map { i in
    amplitude * sin(Float.pi / 2 * Float(i) + Float.pi / 4)
  }
}

/// Direct-form interpolation oracle: y[4n+p] = Σ_k h_p[k]·x[n−k] using the
/// PUBLISHED (non-reversed) ITU-R BS.1770-5 Annex 2 taps, accumulated in
/// Double. Locks tap ordering, edge padding, and chunk-seam handling of the
/// production path.
private func truePeakOracle4x(_ samples: [Float]) -> Double {
  let phases: [[Double]] = [
    [
      0.0017089843750, 0.0109863281250, -0.0196533203125, 0.0332031250000,
      -0.0594482421875, 0.1373291015625, 0.9721679687500, -0.1022949218750,
      0.0476074218750, -0.0266113281250, 0.0148925781250, -0.0083007812500,
    ],
    [
      -0.0291748046875, 0.0292968750000, -0.0517578125000, 0.0891113281250,
      -0.1665039062500, 0.4650878906250, 0.7797851562500, -0.2003173828125,
      0.1015625000000, -0.0582275390625, 0.0330810546875, -0.0189208984375,
    ],
    [
      -0.0189208984375, 0.0330810546875, -0.0582275390625, 0.1015625000000,
      -0.2003173828125, 0.7797851562500, 0.4650878906250, -0.1665039062500,
      0.0891113281250, -0.0517578125000, 0.0292968750000, -0.0291748046875,
    ],
    [
      -0.0083007812500, 0.0148925781250, -0.0266113281250, 0.0476074218750,
      -0.1022949218750, 0.9721679687500, 0.1373291015625, -0.0594482421875,
      0.0332031250000, -0.0196533203125, 0.0109863281250, 0.0017089843750,
    ],
  ]
  var maxAbs = samples.map { Double(abs($0)) }.max() ?? 0
  for n in 0..<(samples.count + 11) {
    for phase in phases {
      var acc = 0.0
      for k in 0..<12 {
        let idx = n - k
        if idx >= 0 && idx < samples.count {
          acc += phase[k] * Double(samples[idx])
        }
      }
      maxAbs = max(maxAbs, abs(acc))
    }
  }
  return 20.0 * log10(maxAbs)
}

@Suite("LUFSAnalyzer — True Peak")
struct LUFSTruePeakTests {

  @Test("ISP sine oracle @ 44.1k: true peak −6.02 dBTP from −9.03 dB samples (4×)")
  func ispOracle441k() {
    let samples = interSamplePeakSine(sampleRate: 44100, amplitude: 0.5, durationSeconds: 2.0)
    let measured = LUFSAnalyzer.measureTruePeak(samples: samples, sampleRate: 44100)
    let expected = 20.0 * log10(0.5)  // −6.0206 dBTP
    #expect(abs(measured - expected) <= 0.3, "got \(measured), expected \(expected) ±0.3")
  }

  @Test("ISP sine oracle @ 48k: true peak −6.02 dBTP from −9.03 dB samples (4×)")
  func ispOracle48k() {
    let samples = interSamplePeakSine(sampleRate: 48000, amplitude: 0.5, durationSeconds: 2.0)
    let measured = LUFSAnalyzer.measureTruePeak(samples: samples, sampleRate: 48000)
    let expected = 20.0 * log10(0.5)
    #expect(abs(measured - expected) <= 0.3, "got \(measured), expected \(expected) ±0.3")
  }

  @Test("ISP sine oracle @ 96k: 2× midpoint design recovers the inter-sample peak")
  func ispOracle96k() {
    let samples = interSamplePeakSine(sampleRate: 96000, amplitude: 0.5, durationSeconds: 2.0)
    let measured = LUFSAnalyzer.measureTruePeak(samples: samples, sampleRate: 96000)
    let expected = 20.0 * log10(0.5)
    #expect(abs(measured - expected) <= 0.3, "got \(measured), expected \(expected) ±0.3")
  }

  @Test(
    "raw sample max folds into the result (unit impulse → 0 dBTP, not the −0.25 dB filtered value)")
  func rawMaxFold() {
    var samples = [Float](repeating: 0, count: 48000)
    samples[24000] = 1.0
    let measured = LUFSAnalyzer.measureTruePeak(samples: samples, sampleRate: 48000)
    // Without the raw-max fold this would read 20·log10(0.97216) ≈ −0.245.
    #expect(abs(measured - 0.0) <= 0.01, "got \(measured), expected 0.0 dBTP")
  }

  @Test(
    "AC8: asymmetric transients (incl. one straddling the 65536 chunk seam) match the direct-convolution oracle"
  )
  func asymmetricTransientMatchesOracle() {
    // Asymmetric bursts — convolution-vs-correlation and padding errors are
    // invisible on symmetric signals.
    var samples = [Float](repeating: 0, count: 70000)
    let burst: [Float] = [0.05, 0.61, -0.37, 0.22, -0.11, 0.03]
    for (i, v) in burst.enumerated() {
      samples[1000 + i] = v
      samples[65534 + i] = v  // straddles the chunk boundary
      samples[69997 + min(i, 2)] = v * 0.5  // tail-edge coverage
    }
    let measured = LUFSAnalyzer.measureTruePeak(samples: samples, sampleRate: 48000)
    let expected = truePeakOracle4x(samples)
    #expect(
      abs(measured - expected) <= 0.01,
      "production path \(measured) dBTP must match direct-form oracle \(expected) dBTP")
  }

  @Test("true peak surfaces on LUFSResult")
  func truePeakOnResult() throws {
    let samples = interSamplePeakSine(sampleRate: 48000, amplitude: 0.5, durationSeconds: 2.0)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(samples, sampleRate: 48000)))
    #expect(abs(result.maxTruePeakDBTP - 20.0 * log10(0.5)) <= 0.3)
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
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(cleanSamples, sampleRate: sampleRate)))
    let dcResult = try #require(
      LUFSAnalyzer.measureLoudness(decoded: .synthetic(dcSamples, sampleRate: sampleRate)))

    let diff = abs(cleanResult.integratedLoudness - dcResult.integratedLoudness)
    #expect(
      diff <= 0.5,
      "DC offset should be filtered by high-pass. Clean: \(cleanResult.integratedLoudness), DC: \(dcResult.integratedLoudness), diff: \(diff) LU"
    )
  }
}
