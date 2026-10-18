//
//  WaveformAnalyzer.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — public analyzer that produces the three independent
//  waveform outputs for a decoded mono audio buffer.
//
//  Phase 1 of Story 15.4 ships the mono / in-memory path. Streaming decode
//  (Story 15.4a) and multi-channel input (Story 15.4b) are follow-ups; their
//  options are added when they work, not reserved ahead of time.
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

  /// Number of bins processed between cancellation checks and progress
  /// reports inside each per-bin pass.
  internal static let progressChunkBins = 256

  // MARK: - Public API

  /// Analyzes a decoded mono buffer and returns the three waveform outputs.
  ///
  /// - Parameters:
  ///   - decoded: Mono PCM samples (``FeatureSubstrate/DecodedAudio``).
  ///   - options: ``WaveformOptions``. Default cadence 150 cps,
  ///     250 / 4000 Hz band crossovers.
  /// - Returns: The three outputs sharing the same bin grid.
  /// - Throws: ``WaveformAnalyzerError/columnsPerSecondOutOfRange(columnsPerSecond:sampleRate:)``
  ///   when ``WaveformOptions/columnsPerSecond`` is not between 1 and the
  ///   sample rate;
  ///   ``WaveformAnalyzerError/midHighCutoffOutOfRange(midHighCutoffHz:nyquistHz:)``
  ///   when ``WaveformOptions/midHighCutoffHz`` is not finite, not positive,
  ///   or at or above `sampleRate / 2` (the default 4000 Hz crossover throws
  ///   at 8 kHz);
  ///   ``WaveformAnalyzerError/lowMidCutoffOutOfRange(lowMidCutoffHz:midHighCutoffHz:)``
  ///   when ``WaveformOptions/lowMidCutoffHz`` is not finite, not positive,
  ///   or not below the mid / high crossover;
  ///   ``WaveformAnalyzerError/cancelled`` when ``WaveformOptions/isCancelled``
  ///   returns `true` at any check (before the pass, before each filter
  ///   pass, and before each 256-bin chunk). A cancelled run returns no
  ///   partial result.
  public static func analyze(
    decoded: FeatureSubstrate.DecodedAudio,
    options: WaveformOptions = .init()
  ) throws -> WaveformAnalysisResult {
    let samples = decoded.samples
    let sampleRate = decoded.sampleRate
    try validate(options: options, sampleRate: sampleRate)
    if options.isCancelled() { throw WaveformAnalyzerError.cancelled }

    options.onProgress?(0.0)

    let frameCount = samples.count
    let coveredSampleRange = 0..<frameCount

    // Rational-integer bin boundaries so a short tail is sized correctly.
    let binStartSamples = computeBinStartSamples(
      frameCount: frameCount,
      sampleRate: sampleRate,
      columnsPerSecond: options.columnsPerSecond
    )
    let binCount = binStartSamples.count

    // Progress is measured in bins processed: one detail / overview pass
    // plus three per-band RMS passes over the same bin grid.
    var progress = PassProgress(
      totalUnits: 4 * binCount,
      isCancelled: options.isCancelled,
      onProgress: options.onProgress
    )

    var magnitudes = [Float](repeating: 0, count: binCount)
    var signedMins = [Float](repeating: 0, count: binCount)
    var signedMaxes = [Float](repeating: 0, count: binCount)
    try computeDetailAndOverview(
      samples: samples,
      frameCount: frameCount,
      binStartSamples: binStartSamples,
      magnitudes: &magnitudes,
      signedMins: &signedMins,
      signedMaxes: &signedMaxes,
      progress: &progress
    )

    // Band-split energy. Biquad filters produce band-limited copies of the
    // input; per-bin energy is RMS over the bin's sample range.
    let (lowBand, midBand, highBand) = try computeThreeBandEnergy(
      samples: samples,
      sampleRate: sampleRate,
      lowMidCutoffHz: options.lowMidCutoffHz,
      midHighCutoffHz: options.midHighCutoffHz,
      binStartSamples: binStartSamples,
      frameCount: frameCount,
      progress: &progress
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

    // An empty input has no chunks, so the per-chunk reports never reach 1.0.
    if binCount == 0 { options.onProgress?(1.0) }
    return WaveformAnalysisResult(detail: detail, overview: overview, energy: energy)
  }

  // MARK: - Option validation

  /// Rejects options the analyzer cannot honor at `sampleRate`. Checked in
  /// this order: cadence, mid / high crossover, low / mid crossover.
  internal static func validate(options: WaveformOptions, sampleRate: Double) throws {
    // Compared as `Double`: `Int(sampleRate)` would trap for a finite rate
    // above `Int.max`.
    guard options.columnsPerSecond >= 1, Double(options.columnsPerSecond) <= sampleRate else {
      throw WaveformAnalyzerError.columnsPerSecondOutOfRange(
        columnsPerSecond: options.columnsPerSecond, sampleRate: sampleRate)
    }
    let nyquistHz = sampleRate / 2
    guard
      options.midHighCutoffHz.isFinite,
      options.midHighCutoffHz > 0,
      options.midHighCutoffHz < nyquistHz
    else {
      throw WaveformAnalyzerError.midHighCutoffOutOfRange(
        midHighCutoffHz: options.midHighCutoffHz, nyquistHz: nyquistHz)
    }
    guard
      options.lowMidCutoffHz.isFinite,
      options.lowMidCutoffHz > 0,
      options.lowMidCutoffHz < options.midHighCutoffHz
    else {
      throw WaveformAnalyzerError.lowMidCutoffOutOfRange(
        lowMidCutoffHz: options.lowMidCutoffHz, midHighCutoffHz: options.midHighCutoffHz)
    }
  }

  // MARK: - Bin boundaries (integer math)

  /// Returns one `Int` per bin: the first sample index in that bin. Last
  /// value is `< frameCount`; last bin covers through `frameCount - 1`.
  /// Uses rational integer math so repeated floating-point `+= 1/cps` drift
  /// is impossible.
  ///
  /// The bin count is capped at `frameCount` so every bin holds at least one
  /// sample and the result stays strictly increasing even when
  /// `columnsPerSecond` exceeds `sampleRate` (``analyze(decoded:options:)``
  /// rejects that cadence before reaching here; the cap keeps this helper
  /// safe on its own).
  internal static func computeBinStartSamples(
    frameCount: Int,
    sampleRate: Double,
    columnsPerSecond: Int
  ) -> [Int] {
    // Expected bin count: ceil(frameCount * columnsPerSecond / sampleRate).
    // Using Double once for the computation keeps the formula explicit; the
    // integer sample positions below are exact and monotonic by construction.
    guard frameCount > 0, columnsPerSecond > 0 else { return [] }
    let cps = Double(columnsPerSecond)
    let uncappedBinCount = max(1, Int((Double(frameCount) * cps / sampleRate).rounded(.up)))
    let binCount = min(frameCount, uncappedBinCount)
    var bins = [Int](repeating: 0, count: binCount)
    for i in 0..<binCount {
      // start = floor(i * sampleRate / cps)
      let position = Double(i) * sampleRate / cps
      bins[i] = min(frameCount - 1, Int(position.rounded(.down)))
    }
    // Enforce strict monotonicity when cps exceeds sampleRate (floor repeats).
    // With binCount <= frameCount the nudged value never passes frameCount - 1.
    for i in 1..<binCount where bins[i] <= bins[i - 1] {
      bins[i] = bins[i - 1] + 1
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
    signedMaxes: inout [Float],
    progress: inout PassProgress
  ) throws {
    let binCount = binStartSamples.count
    guard binCount > 0 else { return }
    try samples.withUnsafeBufferPointer { buf in
      let base = buf.baseAddress!
      for chunkStart in stride(from: 0, to: binCount, by: progressChunkBins) {
        try progress.checkCancellation()
        let chunkEnd = min(binCount, chunkStart + progressChunkBins)
        for i in chunkStart..<chunkEnd {
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
        progress.report(completed: chunkEnd - chunkStart)
      }
    }
  }

  private static func computeThreeBandEnergy(
    samples: [Float],
    sampleRate: Double,
    lowMidCutoffHz: Double,
    midHighCutoffHz: Double,
    binStartSamples: [Int],
    frameCount: Int,
    progress: inout PassProgress
  ) throws -> (low: [Float], mid: [Float], high: [Float]) {
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

    // Each filter pass runs over the whole buffer, so cancellation is
    // checked before each one as well as per chunk inside the RMS passes.
    try progress.checkCancellation()
    let lowBandSignal = lowPassCoefficients.apply(to: samples)
    try computeRMSPerBin(
      signal: lowBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &lowBand, progress: &progress)

    // Mid band = high-pass @ lowMid, then low-pass @ midHigh.
    try progress.checkCancellation()
    let midPreHigh = highPassLowMid.apply(to: samples)
    try progress.checkCancellation()
    let midBandSignal = lowPassMidHigh.apply(to: midPreHigh)
    try computeRMSPerBin(
      signal: midBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &midBand, progress: &progress)

    try progress.checkCancellation()
    let highBandSignal = highPassMidHigh.apply(to: samples)
    try computeRMSPerBin(
      signal: highBandSignal, frameCount: frameCount, binStartSamples: binStartSamples,
      output: &highBand, progress: &progress)

    return (lowBand, midBand, highBand)
  }

  private static func computeRMSPerBin(
    signal: [Float],
    frameCount: Int,
    binStartSamples: [Int],
    output: inout [Float],
    progress: inout PassProgress
  ) throws {
    let binCount = binStartSamples.count
    try signal.withUnsafeBufferPointer { buf in
      let base = buf.baseAddress!
      for chunkStart in stride(from: 0, to: binCount, by: progressChunkBins) {
        try progress.checkCancellation()
        let chunkEnd = min(binCount, chunkStart + progressChunkBins)
        for i in chunkStart..<chunkEnd {
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
        progress.report(completed: chunkEnd - chunkStart)
      }
    }
  }
}

// MARK: - Progress and cancellation

/// Tracks bins processed across the analyzer's per-bin passes, consults the
/// caller's cancellation closure, and reports a monotonic `[0, 1]` fraction.
private struct PassProgress {
  let totalUnits: Int
  let isCancelled: @Sendable () -> Bool
  let onProgress: (@Sendable (Double) -> Void)?
  private(set) var completedUnits = 0

  init(
    totalUnits: Int,
    isCancelled: @escaping @Sendable () -> Bool,
    onProgress: (@Sendable (Double) -> Void)?
  ) {
    self.totalUnits = totalUnits
    self.isCancelled = isCancelled
    self.onProgress = onProgress
  }

  func checkCancellation() throws {
    if isCancelled() { throw WaveformAnalyzerError.cancelled }
  }

  mutating func report(completed units: Int) {
    completedUnits = min(totalUnits, completedUnits + units)
    guard totalUnits > 0 else { return }
    onProgress?(Double(completedUnits) / Double(totalUnits))
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
///
/// The payloads carry the rejected `Double` values, so an error built from a
/// NaN input never equals itself; tests on non-finite inputs must match on
/// the case, not compare whole values.
public enum WaveformAnalyzerError: Error, Sendable, Equatable {
  /// ``WaveformOptions/isCancelled`` returned `true`.
  case cancelled
  /// ``WaveformOptions/columnsPerSecond`` is not between 1 and the sample rate.
  case columnsPerSecondOutOfRange(columnsPerSecond: Int, sampleRate: Double)
  /// ``WaveformOptions/midHighCutoffHz`` is not finite, not positive, or at
  /// or above the Nyquist frequency (`sampleRate / 2`) of the input.
  case midHighCutoffOutOfRange(midHighCutoffHz: Double, nyquistHz: Double)
  /// ``WaveformOptions/lowMidCutoffHz`` is not finite, not positive, or not
  /// below ``WaveformOptions/midHighCutoffHz``.
  case lowMidCutoffOutOfRange(lowMidCutoffHz: Double, midHighCutoffHz: Double)
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
