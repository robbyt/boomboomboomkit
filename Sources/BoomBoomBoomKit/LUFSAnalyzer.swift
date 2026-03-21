//
//  LUFSAnalyzer.swift
//  BoomBoomBoomKit
//
//  LUFS Loudness Analyzer (ITU-R BS.1770-5)
//

import Accelerate
import Foundation

/// Result of LUFS integrated loudness measurement.
struct LUFSResult: Sendable {
  /// Integrated loudness — the headline number (e.g., -14.2 LUFS)
  let integratedLoudness: Double

  /// Per-block momentary loudness values (400ms blocks, 100ms step).
  /// These are the L_j values BEFORE gating — retained as a zero-cost byproduct
  /// of the gating computation. Enables LUFS-over-time visualization without re-analysis.
  /// X-axis: index * blockStepSeconds gives time position.
  /// Y-axis: LUFS value for that block.
  let blockLoudnessValues: [Double]

  /// Time step between consecutive blocks in seconds (always 0.1).
  let blockStepSeconds: Double
}

/// Measures integrated loudness per ITU-R BS.1770-5.
///
/// Pure computation: `[Float] → LUFSResult?`. No shared state, no actors.
/// Only imports `Foundation` and `Accelerate` — no external dependencies.
struct LUFSAnalyzer {

  // MARK: - Constants

  /// Floor value for block loudness display (matches klangfreund histogram lower bound).
  private static let blockLoudnessFloor: Double = -100.0

  // MARK: - K-Weighting Coefficients

  /// K-weighting filter coefficients for supported sample rates.
  /// Format per section: [b0, b1, b2, a1, a2] (a0 = 1 normalized).
  /// Two sections: high-shelf (head acoustic) → high-pass (RLB weighting).
  private static let coefficients: [Int: [Double]] = [
    // 48000 Hz — from ITU-R BS.1770-5 specification directly
    48000: [
      // Stage 1: High-Shelf Filter
      1.53512485958697, -2.69169618940638, 1.19839281085285,
      -1.69065929318241, 0.73248077421585,
      // Stage 2: High-Pass Filter
      1.0, -2.0, 1.0,
      -1.99004745483398, 0.99007225036621
    ],
    // 44100 Hz — bilinear transform from 48kHz prototype
    44100: [
      // Stage 1: High-Shelf Filter
      1.530841230050348, -2.650979995154729, 1.169079079921587,
      -1.663655113256020, 0.712595428073225,
      // Stage 2: High-Pass Filter
      0.999560064542514, -1.999120129085029, 0.999560064542514,
      -1.989169673629796, 0.989199035787039
    ],
    // 96000 Hz — bilinear transform from 48kHz prototype
    96000: [
      // Stage 1: High-Shelf Filter
      1.537185173610400, -2.718780265928710, 1.218990510102450,
      -1.710656503758280, 0.747317008498040,
      // Stage 2: High-Pass Filter
      0.999780299723625, -1.999560599447250, 0.999780299723625,
      -1.994582958828822, 0.994588012554209
    ]
  ]

  // MARK: - Public API

  /// Measures integrated loudness per ITU-R BS.1770-5.
  ///
  /// Returns both the headline integrated loudness and per-block momentary
  /// loudness values (100ms step) for future time-series visualization.
  ///
  /// - Parameters:
  ///   - samples: Mono audio samples (from PCMBufferReader)
  ///   - sampleRate: Sample rate in Hz. Supported: 44100, 48000, 96000.
  /// - Returns: Integrated loudness + block time-series in LUFS,
  ///   or nil for silence/too-short audio/unsupported sample rate.
  static func measureLoudness(
    samples: [Float],
    sampleRate: Double
  ) -> LUFSResult? {
    // Task 6.1: Guard against empty samples
    guard !samples.isEmpty else { return nil }

    // Task 1.5: Guard against unsupported sample rates
    guard let filterCoeffs = coefficients[Int(sampleRate)] else {
      // TODO: bilinear transform derivation for arbitrary rates
      return nil
    }

    // Task 6.2: Guard against duration < 400ms (can't form a single block)
    let blockSize = Int(0.4 * sampleRate)
    guard samples.count >= blockSize else { return nil }

    // Task 1.6: Apply K-weighting filter using vDSP.Biquad (Double precision)
    let filtered = applyKWeighting(samples: samples, coefficients: filterCoeffs)

    // Task 2: Compute per-block mean-square values
    let stepSize = Int(0.1 * sampleRate)
    let blockResults = computeBlockMeanSquares(
      filtered: filtered, blockSize: blockSize, stepSize: stepSize)

    guard !blockResults.isEmpty else { return nil }

    // Task 3: Compute per-block loudness and apply absolute gating
    let blockLoudness = blockResults.map { meanSquare -> Double in
      guard meanSquare > 0 else { return -.infinity }
      return -0.691 + 10.0 * log10(meanSquare)
    }

    // Task 3.2: Absolute gate — discard blocks below -70 LUFS
    let absoluteThreshold: Double = -70.0
    let absoluteGatedIndices = blockLoudness.indices.filter { i in
      blockLoudness[i] > absoluteThreshold
    }

    // Task 6.3: All blocks gated → return nil
    guard !absoluteGatedIndices.isEmpty else { return nil }

    // Task 4: Relative gating
    let ungatedMeanSquare =
      absoluteGatedIndices.map { blockResults[$0] }.reduce(0, +)
      / Double(absoluteGatedIndices.count)

    // Task 6.4: Guard against log10(0)
    guard ungatedMeanSquare > 0 else { return nil }

    let ungatedLoudness = -0.691 + 10.0 * log10(ungatedMeanSquare)
    let relativeThreshold = ungatedLoudness - 10.0

    let relativeGatedIndices = absoluteGatedIndices.filter { i in
      blockLoudness[i] > relativeThreshold
    }

    // Task 6.3: All blocks gated after relative pass → return nil
    guard !relativeGatedIndices.isEmpty else { return nil }

    // Task 5: Compute final integrated loudness
    let finalMeanSquare =
      relativeGatedIndices.map { blockResults[$0] }.reduce(0, +)
      / Double(relativeGatedIndices.count)

    guard finalMeanSquare > 0 else { return nil }

    let integratedLoudness = -0.691 + 10.0 * log10(finalMeanSquare)

    // Task 5.4: Retain ALL per-block L_j values (pre-gating) for time-series
    // Replace -infinity with a floor value for display purposes
    let displayBlockLoudness = blockLoudness.map { value in
      value.isFinite ? value : blockLoudnessFloor
    }

    return LUFSResult(
      integratedLoudness: integratedLoudness,
      blockLoudnessValues: displayBlockLoudness,
      blockStepSeconds: 0.1
    )
  }

  // MARK: - K-Weighting Filter (Task 1)

  /// Applies K-weighting pre-filter (high-shelf + high-pass cascade) using vDSP.Biquad.
  /// Uses Double precision throughout — Float causes measurable errors due to poles near unit circle.
  private static func applyKWeighting(
    samples: [Float], coefficients: [Double]
  ) -> [Double] {
    // Convert Float → Double using vDSP (vectorized)
    var doubleSamples = [Double](repeating: 0, count: samples.count)
    vDSP_vspdp(samples, 1, &doubleSamples, 1, vDSP_Length(samples.count))

    // Create 2-section cascade: high-shelf → high-pass
    guard
      var filter = vDSP.Biquad(
        coefficients: coefficients,
        channelCount: 1,
        sectionCount: 2,
        ofType: Double.self
      )
    else {
      return []
    }

    // Apply filter in single pass (offline analysis, not real-time)
    return filter.apply(input: doubleSamples)
  }

  // MARK: - Block Mean-Square Computation (Task 2)

  /// Computes mean-square per 400ms block with 100ms step (75% overlap).
  private static func computeBlockMeanSquares(
    filtered: [Double], blockSize: Int, stepSize: Int
  ) -> [Double] {
    let totalSamples = filtered.count
    guard totalSamples >= blockSize else { return [] }

    let blockCount = (totalSamples - blockSize) / stepSize + 1
    var meanSquares = [Double](repeating: 0, count: blockCount)

    filtered.withUnsafeBufferPointer { bp in
      for i in 0..<blockCount {
        let blockStart = i * stepSize
        var ms: Double = 0
        vDSP_measqvD(bp.baseAddress! + blockStart, 1, &ms, vDSP_Length(blockSize))
        meanSquares[i] = ms
      }
    }

    return meanSquares
  }
}
