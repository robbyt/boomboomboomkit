//
//  WaveformAnalyzer.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — public analyzer that produces the three independent
//  waveform outputs for a decoded mono audio buffer.
//
//  Phase 1 of Story 15.4 ships the mono / in-memory path. Streaming decode
//  (Story 15.4a) and multi-channel policies (Story 15.4b) are reserved
//  follow-ups; a caller invoking those cases today receives a thrown
//  `WaveformAnalyzerError`.
//

import Accelerate
import Foundation

/// Public entry point for waveform analysis.
///
/// Produces three parallel outputs that share a bin grid:
/// ``WaveformDetailEnvelope``, ``WaveformPeakOverview``, and
/// ``WaveformEnergyChannels``. All three use integer-sample bin boundaries
/// at the requested columns-per-second cadence.
public enum WaveformAnalyzer {

  // MARK: - Public API

  /// Analyzes a decoded mono buffer and returns the three waveform outputs.
  ///
  /// - Parameters:
  ///   - decoded: Mono PCM samples (``FeatureSubstrate/DecodedAudio``).
  ///   - options: ``WaveformOptions``. Default cadence 150 cps,
  ///     ``WaveformChannelPolicy/mono``, 250 / 4000 Hz band crossovers.
  /// - Returns: The three outputs sharing the same bin grid.
  /// - Throws: ``WaveformAnalyzerError/cancelled`` when
  ///   ``WaveformOptions/isCancelled`` returns `true` before the pass starts;
  ///   ``WaveformAnalyzerError/channelPolicyNotImplemented`` for any policy
  ///   other than ``WaveformChannelPolicy/mono`` (reserved API).
  public static func analyze(
    decoded: FeatureSubstrate.DecodedAudio,
    options: WaveformOptions = .init()
  ) throws -> WaveformAnalysisResult {
    if options.isCancelled() { throw WaveformAnalyzerError.cancelled }
    guard options.channelPolicy.isImplemented else {
      throw WaveformAnalyzerError.channelPolicyNotImplemented(options.channelPolicy)
    }

    options.onProgress?(0.0)

    let samples = decoded.samples
    let sampleRate = decoded.sampleRate
    let frameCount = samples.count
    let coveredSampleRange = 0..<frameCount

    // Rational-integer bin boundaries so a short tail is sized correctly.
    let binStartSamples = computeBinStartSamples(
      frameCount: frameCount,
      sampleRate: sampleRate,
      columnsPerSecond: options.columnsPerSecond
    )
    let binCount = binStartSamples.count

    // Shared iteration: compute each output's per-bin reduction in one pass
    // over the sample buffer. The three loops are independent per bin, so
    // we expose each via its own helper to keep the top-level readable.
    var magnitudes = [Float](repeating: 0, count: binCount)
    var signedMins = [Float](repeating: 0, count: binCount)
    var signedMaxes = [Float](repeating: 0, count: binCount)
    computeDetailAndOverview(
      samples: samples,
      frameCount: frameCount,
      binStartSamples: binStartSamples,
      magnitudes: &magnitudes,
      signedMins: &signedMins,
      signedMaxes: &signedMaxes
    )

    // Band-split energy. Three biquad filters produce band-limited copies
    // of the input; per-bin energy is RMS over the bin's sample range.
    let (lowBand, midBand, highBand) = computeThreeBandEnergy(
      samples: samples,
      sampleRate: sampleRate,
      lowMidCutoffHz: options.lowMidCutoffHz,
      midHighCutoffHz: options.midHighCutoffHz,
      binStartSamples: binStartSamples,
      frameCount: frameCount
    )

    let detail = WaveformDetailEnvelope(
      sampleRate: sampleRate,
      columnsPerSecond: options.columnsPerSecond,
      coveredSampleRange: coveredSampleRange,
      binStartSamples: binStartSamples,
      magnitudes: magnitudes
    )
    let overview = WaveformPeakOverview(
      sampleRate: sampleRate,
      columnsPerSecond: options.columnsPerSecond,
      coveredSampleRange: coveredSampleRange,
      binStartSamples: binStartSamples,
      signedMins: signedMins,
      signedMaxes: signedMaxes
    )
    let energy = WaveformEnergyChannels(
      sampleRate: sampleRate,
      columnsPerSecond: options.columnsPerSecond,
      lowMidCutoffHz: options.lowMidCutoffHz,
      midHighCutoffHz: options.midHighCutoffHz,
      coveredSampleRange: coveredSampleRange,
      binStartSamples: binStartSamples,
      lowBand: lowBand,
      midBand: midBand,
      highBand: highBand
    )

    options.onProgress?(1.0)
    return WaveformAnalysisResult(detail: detail, overview: overview, energy: energy)
  }

  // MARK: - Bin boundaries (integer math)

  /// Returns one `Int` per bin: the first sample index in that bin. Last
  /// value is `< frameCount`; last bin covers through `frameCount - 1`.
  /// Uses rational integer math so repeated floating-point `+= 1/cps` drift
  /// is impossible.
  internal static func computeBinStartSamples(
    frameCount: Int,
    sampleRate: Double,
    columnsPerSecond: Int
  ) -> [Int] {
    // Expected bin count: ceil(frameCount * columnsPerSecond / sampleRate).
    // Using Double once for the computation keeps the formula explicit; the
    // integer sample positions below are exact and monotonic by construction.
    let cps = Double(columnsPerSecond)
    guard frameCount > 0 else { return [] }
    let binCount = max(1, Int((Double(frameCount) * cps / sampleRate).rounded(.up)))
    var bins = [Int](repeating: 0, count: binCount)
    for i in 0..<binCount {
      // start = floor(i * sampleRate / cps)
      let position = Double(i) * sampleRate / cps
      bins[i] = min(frameCount - 1, Int(position.rounded(.down)))
    }
    // Ensure strict monotonicity: if a repeat occurs at very high cps vs
    // sampleRate, nudge forward by one sample.
    for i in 1..<binCount where bins[i] <= bins[i - 1] {
      bins[i] = min(frameCount - 1, bins[i - 1] + 1)
    }
    return bins
  }

  // MARK: - Per-bin reductions

  private static func computeDetailAndOverview(
    samples: [Float],
    frameCount: Int,
    binStartSamples: [Int],
    magnitudes: inout [Float],
    signedMins: inout [Float],
    signedMaxes: inout [Float]
  ) {
    let binCount = binStartSamples.count
    guard binCount > 0 else { return }
    samples.withUnsafeBufferPointer { buf in
      let base = buf.baseAddress!
      for i in 0..<binCount {
        let start = binStartSamples[i]
        let end = i + 1 < binCount ? binStartSamples[i + 1] : frameCount
        let count = end - start
        guard count > 0 else {
          magnitudes[i] = 0
          signedMins[i] = 0
          signedMaxes[i] = 0
          continue
        }
        var minValue: Float = 0
        var maxValue: Float = 0
        vDSP_minv(base + start, 1, &minValue, vDSP_Length(count))
        vDSP_maxv(base + start, 1, &maxValue, vDSP_Length(count))
        var absMax: Float = 0
        vDSP_maxmgv(base + start, 1, &absMax, vDSP_Length(count))
        signedMins[i] = minValue
        signedMaxes[i] = maxValue
        magnitudes[i] = absMax
      }
    }
  }

  private static func computeThreeBandEnergy(
    samples: [Float],
    sampleRate: Double,
    lowMidCutoffHz: Double,
    midHighCutoffHz: Double,
    binStartSamples: [Int],
    frameCount: Int
  ) -> (low: [Float], mid: [Float], high: [Float]) {
    let binCount = binStartSamples.count
    var lowBand = [Float](repeating: 0, count: binCount)
    var midBand = [Float](repeating: 0, count: binCount)
    var highBand = [Float](repeating: 0, count: binCount)
    guard binCount > 0 else { return (lowBand, midBand, highBand) }

    // Second-order Butterworth-ish biquads in Double for stability. The
    // crossovers are the band boundaries; each band is a cascade (one
    // low-pass + one high-pass for the band-pass mid band).
    let lowPassCoefficients = BiquadCoefficients.lowPass(
      cutoffHz: lowMidCutoffHz, sampleRate: sampleRate)
    let highPassLowMid = BiquadCoefficients.highPass(
      cutoffHz: lowMidCutoffHz, sampleRate: sampleRate)
    let lowPassMidHigh = BiquadCoefficients.lowPass(
      cutoffHz: midHighCutoffHz, sampleRate: sampleRate)
    let highPassMidHigh = BiquadCoefficients.highPass(
      cutoffHz: midHighCutoffHz, sampleRate: sampleRate)

    let lowBandSignal = lowPassCoefficients.apply(to: samples)
    // Mid band = high-pass @ lowMid, then low-pass @ midHigh.
    let midPreHigh = highPassLowMid.apply(to: samples)
    let midBandSignal = lowPassMidHigh.apply(to: midPreHigh)
    let highBandSignal = highPassMidHigh.apply(to: samples)

    computeRMSPerBin(
      signal: lowBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &lowBand)
    computeRMSPerBin(
      signal: midBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &midBand)
    computeRMSPerBin(
      signal: highBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &highBand)

    return (lowBand, midBand, highBand)
  }

  private static func computeRMSPerBin(
    signal: [Float],
    frameCount: Int,
    binStartSamples: [Int],
    output: inout [Float]
  ) {
    let binCount = binStartSamples.count
    signal.withUnsafeBufferPointer { buf in
      let base = buf.baseAddress!
      for i in 0..<binCount {
        let start = binStartSamples[i]
        let end = i + 1 < binCount ? binStartSamples[i + 1] : frameCount
        let count = end - start
        guard count > 0 else {
          output[i] = 0
          continue
        }
        var rms: Float = 0
        vDSP_rmsqv(base + start, 1, &rms, vDSP_Length(count))
        output[i] = rms
      }
    }
  }
}

// MARK: - Result

/// Combined output of ``WaveformAnalyzer/analyze(decoded:options:)``.
public struct WaveformAnalysisResult: Sendable, Hashable, Codable {
  public let detail: WaveformDetailEnvelope
  public let overview: WaveformPeakOverview
  public let energy: WaveformEnergyChannels

  public init(
    detail: WaveformDetailEnvelope,
    overview: WaveformPeakOverview,
    energy: WaveformEnergyChannels
  ) {
    self.detail = detail
    self.overview = overview
    self.energy = energy
  }
}

// MARK: - Errors

/// Errors emitted by ``WaveformAnalyzer``.
public enum WaveformAnalyzerError: Error, Sendable, Equatable {
  /// ``WaveformOptions/isCancelled`` returned `true`.
  case cancelled
  /// The caller requested a ``WaveformChannelPolicy`` that is reserved for a
  /// follow-up story (Story 15.4b). Only ``WaveformChannelPolicy/mono`` is
  /// implemented in Phase 1 of Story 15.4.
  case channelPolicyNotImplemented(WaveformChannelPolicy)
}

// MARK: - Biquad helper (second-order IIR, Double precision)

/// Direct-form-II transposed biquad coefficients. Double precision keeps the
/// poles stable near the low crossover (same reason ``LUFSAnalyzer`` uses
/// `vDSP.Biquad` in Double).
private struct BiquadCoefficients {
  let b0: Double
  let b1: Double
  let b2: Double
  let a1: Double
  let a2: Double

  /// Second-order Butterworth low-pass via bilinear transform.
  static func lowPass(cutoffHz: Double, sampleRate: Double) -> BiquadCoefficients {
    let omega = 2.0 * .pi * cutoffHz / sampleRate
    let cosOmega = cos(omega)
    let sinOmega = sin(omega)
    let qInv = sqrt(2.0)  // Butterworth Q = 1 / sqrt(2) → qInv = sqrt(2)
    let alpha = sinOmega / 2.0 * qInv
    let a0 = 1.0 + alpha
    let b0 = ((1.0 - cosOmega) / 2.0) / a0
    let b1 = (1.0 - cosOmega) / a0
    let b2 = ((1.0 - cosOmega) / 2.0) / a0
    let a1 = (-2.0 * cosOmega) / a0
    let a2 = (1.0 - alpha) / a0
    return BiquadCoefficients(b0: b0, b1: b1, b2: b2, a1: a1, a2: a2)
  }

  /// Second-order Butterworth high-pass via bilinear transform.
  static func highPass(cutoffHz: Double, sampleRate: Double) -> BiquadCoefficients {
    let omega = 2.0 * .pi * cutoffHz / sampleRate
    let cosOmega = cos(omega)
    let sinOmega = sin(omega)
    let qInv = sqrt(2.0)
    let alpha = sinOmega / 2.0 * qInv
    let a0 = 1.0 + alpha
    let b0 = ((1.0 + cosOmega) / 2.0) / a0
    let b1 = -(1.0 + cosOmega) / a0
    let b2 = ((1.0 + cosOmega) / 2.0) / a0
    let a1 = (-2.0 * cosOmega) / a0
    let a2 = (1.0 - alpha) / a0
    return BiquadCoefficients(b0: b0, b1: b1, b2: b2, a1: a1, a2: a2)
  }

  /// Applies the filter sample-by-sample in Double, returning Float output.
  func apply(to samples: [Float]) -> [Float] {
    var output = [Float](repeating: 0, count: samples.count)
    var x1 = 0.0
    var x2 = 0.0
    var y1 = 0.0
    var y2 = 0.0
    for i in 0..<samples.count {
      let x0 = Double(samples[i])
      let y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
      output[i] = Float(y0)
      x2 = x1
      x1 = x0
      y2 = y1
      y1 = y0
    }
    return output
  }
}
