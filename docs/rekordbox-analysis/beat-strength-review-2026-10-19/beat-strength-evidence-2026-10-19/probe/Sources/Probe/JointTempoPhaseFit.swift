//
//  JointTempoPhaseFit.swift
//  BoomBoomBoomKit
//
//  Story 15.7 (Epic 15, Phase 7) — joint tempo and phase fit over a
//  ``FramewiseObservations`` stream.
//
//  Consumes the Phase 6 observation stream and the decoder's candidate
//  beat sequence, and emits a ``FittedTempoPhase`` value carrying BOTH a
//  refined tempo and a phase anchor. Pre-15.7, ``BeatGridAnalyzer``'s
//  optional comb refinement returned only a refined tempo; grid origin was
//  selected from earlier integer-frame observations.
//
//  Mechanics:
//
//  1. Each integer-frame beat is refined to a sub-frame position by
//     parabolic peak interpolation on the beat-probability stream.
//  2. The fit is seeded from the candidate's tempo and the median of
//     `t_i - gridIndex_i * period`, so a minority of off-grid beats cannot
//     pull the seed.
//  3. Beats whose residual against the current line exceeds
//     `trimThresholdFactor * period` are dropped (hard trimming), and tempo
//     and phase are re-fit by least squares of beat time against grid
//     index. Up to three passes. The kept fraction is recorded on the
//     result so a review can see how much was set aside.
//  4. The fit abstains (returns nil) on too few kept beats, too low a kept
//     fraction or support, or a refit tempo that leaves the candidate's
//     tempo by more than `maxTempoDeviationFraction`.
//
//  Interpolation refines where a peak lies inside its own frame. It cannot
//  remove a timing offset every beat shares: on single-impulse clicks the
//  DSP stub's phase anchor sits about one hop early (measured -10.7 ms at
//  120 BPM and -11.4 ms at 128 BPM, 44.1 kHz, hop 441), and that offset
//  survives the fit.
//
//  Public API is unchanged: this type is `internal`, the derived grid
//  does NOT vote in BPM selection, and `SignalSource.beatGrid` /
//  `SignalWeights.beatGrid` remain placeholders (DD #5 of Story 15.7).
//

import Foundation

/// Jointly-fitted tempo and phase from a ``FramewiseObservations`` stream.
///
/// Carries both the refined tempo and the sub-frame phase anchor, with
/// trimming provenance so a reviewer can see what the fit set aside.
internal struct FittedTempoPhase: Sendable, Hashable {

  /// Refined tempo in BPM.
  let tempoBPM: Double

  /// Decoded-PCM time, in seconds, of grid index 0 (the decoder's first
  /// emitted beat) on the fitted line. The full playable grid is
  /// extrapolated as `phaseAnchorSeconds + k * 60 / tempoBPM` for
  /// `k = 0, 1, 2, ...`.
  let phaseAnchorSeconds: Double

  /// Fraction of the decoder's candidate beats that survived trimming
  /// (`keptCount / totalCandidateCount`). A low value here is a signal
  /// that the input is noisier or more syncopated than the fit's
  /// constant-tempo assumption.
  let keptFraction: Double

  /// Mean beat probability across the kept beats. Reports how strongly
  /// the fit was supported by the observation stream after trimming.
  let supportScore: Float

  /// Metrical level the fit tracked at (quarter / half / double of the
  /// seed tempo). Carried through from the candidate, so a consumer can
  /// tell which octave was fit.
  let metricalLevel: MetricalLevel

  /// Opaque identifier for the decoder + fit algorithm.
  let modelIdentifier: String

  /// Opaque identifier for the observation frontend that fed the fit.
  let frontendIdentifier: String

  /// Coverage window the fit was computed over, in seconds.
  let coverageWindowSeconds: Double
}

/// Joint tempo + phase fit entry point.
internal enum JointTempoPhaseFit {

  /// Current algorithm identifier for the fit.
  static let modelIdentifier = "joint-tempo-phase.v1.sub-frame-trimmed"

  /// Trim threshold as a fraction of the beat period. A beat whose
  /// residual against the current line exceeds
  /// `trimThresholdFactor * periodSeconds` is dropped before the refit.
  static let trimThresholdFactor: Double = 0.15

  /// Minimum fraction of candidate beats that must survive trimming.
  static let minKeptFraction: Double = 0.5

  /// Minimum number of beats that must survive trimming. Fewer points do
  /// not constrain a two-parameter line well enough to report a tempo.
  static let minKeptBeats = 8

  /// Maximum relative distance between the refit tempo and the
  /// candidate's tempo. The fit refines rate at the level it was given; a
  /// result outside this band is treated as a failed fit, not a new tempo.
  static let maxTempoDeviationFraction: Double = 0.05

  /// Minimum mean beat probability across the kept beats.
  static let minSupportScore: Float = 0.1

  /// Maximum number of trim-and-refit passes.
  static let maxTrimPasses = 3

  /// Runs the fit on the selector's chosen candidate.
  static func fit(
    observations: FramewiseObservations,
    selection: MetricalLevelSelection
  ) -> FittedTempoPhase? {
    fit(observations: observations, candidate: selection.chosen)
  }

  /// Runs the fit on one candidate beat sequence.
  ///
  /// - Parameters:
  ///   - observations: ``FramewiseObservations`` from a Phase-6 producer;
  ///     used for sub-frame refinement of each beat time.
  ///   - candidate: The decoder's beats. Their `gridIndex` values are the
  ///     regression's x-coordinates and `candidate.tempoBPM` seeds the
  ///     period.
  /// - Returns: A ``FittedTempoPhase``, or `nil` when fewer than
  ///   ``minKeptBeats`` beats survive, the kept fraction is below
  ///   ``minKeptFraction``, the mean kept support is below
  ///   ``minSupportScore``, the regression is degenerate, or the refit
  ///   tempo leaves `candidate.tempoBPM` by more than
  ///   ``maxTempoDeviationFraction``.
  static func fit(
    observations: FramewiseObservations,
    candidate: CandidateBeatSequence
  ) -> FittedTempoPhase? {
    let beats = candidate.beats
    guard beats.count >= minKeptBeats, candidate.tempoBPM.isFinite, candidate.tempoBPM > 0
    else { return nil }
    let seedPeriod = 60.0 / candidate.tempoBPM

    // Step 1: sub-frame refinement of each integer-frame beat time.
    let times = beats.map { refineBeatTime(aroundTime: $0.time, observations: observations) }
    let gridIndices = beats.map { Double($0.gridIndex) }

    // Step 2: robust seed. The candidate's tempo fixes the period; the
    // median offset fixes the phase, so off-grid beats in the minority do
    // not move it.
    let offsets = zip(times, gridIndices).map { $0 - $1 * seedPeriod }.sorted()
    var line = (period: seedPeriod, phase: median(ofSorted: offsets))

    // Step 3: trim against the current line, refit on the kept beats.
    let trimThreshold = trimThresholdFactor * seedPeriod
    var kept: [Int] = []
    for _ in 0..<maxTrimPasses {
      let trimmed = beats.indices.filter { i in
        abs(times[i] - (line.phase + gridIndices[i] * line.period)) <= trimThreshold
      }
      guard trimmed.count >= minKeptBeats,
        let refit = linearRegression(
          x: trimmed.map { gridIndices[$0] }, y: trimmed.map { times[$0] })
      else { return nil }
      let converged = trimmed == kept
      kept = trimmed
      line = refit
      if converged { break }
    }

    // Step 4: abstain checks.
    let keptFraction = Double(kept.count) / Double(beats.count)
    guard keptFraction >= minKeptFraction else { return nil }
    let support = kept.reduce(Float(0)) { $0 + beats[$1].beatSupport } / Float(kept.count)
    guard support >= minSupportScore else { return nil }
    let tempoBPM = 60.0 / line.period
    guard abs(tempoBPM / candidate.tempoBPM - 1.0) <= maxTempoDeviationFraction else {
      return nil
    }

    return FittedTempoPhase(
      tempoBPM: tempoBPM,
      phaseAnchorSeconds: line.phase,
      keptFraction: keptFraction,
      supportScore: support,
      metricalLevel: candidate.metricalLevel,
      modelIdentifier: Self.modelIdentifier,
      frontendIdentifier: observations.frontendIdentifier,
      coverageWindowSeconds: observations.coverageWindowSeconds
    )
  }

  // MARK: - Sub-frame peak interpolation

  /// Parabolic peak interpolation. For envelope frames `(f - 1, a)`,
  /// `(f, b)`, `(f + 1, c)` the interpolated peak offset in frames is
  /// `0.5 * (a - c) / (a - 2b + c)`. Clamped to `[-0.5, 0.5]` so a
  /// numerically ill-conditioned triple does not throw the beat out of
  /// its hop. Applied only when `b` is a local maximum (`b >= a`, `b >= c`,
  /// and `a - 2b + c < 0`); any other triple returns `aroundTime` unchanged.
  internal static func refineBeatTime(
    aroundTime: Double,
    observations: FramewiseObservations
  ) -> Double {
    // Invert `timeForFrame` to the nearest integer frame. For a decoder
    // beat the inverse is exact; a sub-frame time from a future producer
    // also resolves to its nearest frame. A non-finite time is returned
    // unchanged rather than converted to an integer.
    let fractionalFrame =
      (aroundTime - observations.firstFrameOriginSeconds) * observations.frameRate
    guard fractionalFrame.isFinite else { return aroundTime }
    let usableFrames = min(
      observations.frameCount,
      Int((observations.coverageWindowSeconds * observations.frameRate).rounded(.down)))
    guard fractionalFrame > 0, fractionalFrame + 1 < Double(usableFrames) else {
      // Edge frame (or outside the coverage window): no interpolation.
      return aroundTime
    }
    let f = Int(fractionalFrame.rounded())
    guard f > 0, f + 1 < usableFrames else { return aroundTime }
    let a = Double(observations.beatProbabilities[f - 1])
    let b = Double(observations.beatProbabilities[f])
    let c = Double(observations.beatProbabilities[f + 1])
    let denominator = a - 2.0 * b + c
    // Interpolate only at a local maximum (the centre at or above both
    // neighbours, with negative curvature); a monotonic or flat triple is
    // returned unchanged.
    guard b >= a, b >= c, denominator < 0 else { return aroundTime }
    var offsetFrames = 0.5 * (a - c) / denominator
    if offsetFrames < -0.5 { offsetFrames = -0.5 }
    if offsetFrames > 0.5 { offsetFrames = 0.5 }
    return observations.timeForFrame(f) + offsetFrames / observations.frameRate
  }

  // MARK: - Helpers

  /// Median of an already-sorted, non-empty array.
  private static func median(ofSorted values: [Double]) -> Double {
    let mid = values.count / 2
    return values.count % 2 == 1 ? values[mid] : (values[mid - 1] + values[mid]) / 2
  }

  /// Least-squares line `y = phase + x * period`. Returns `nil` for fewer
  /// than two points, identical x values, or a non-positive or non-finite
  /// period; it never substitutes a default tempo.
  internal static func linearRegression(
    x: [Double], y: [Double]
  ) -> (period: Double, phase: Double)? {
    let count = min(x.count, y.count)
    guard count >= 2 else { return nil }
    let n = Double(count)
    let meanX = x.prefix(count).reduce(0, +) / n
    let meanY = y.prefix(count).reduce(0, +) / n
    var numerator = 0.0
    var denominator = 0.0
    for i in 0..<count {
      numerator += (x[i] - meanX) * (y[i] - meanY)
      denominator += (x[i] - meanX) * (x[i] - meanX)
    }
    guard denominator > 0 else { return nil }
    let period = numerator / denominator
    guard period.isFinite, period > 0 else { return nil }
    return (period, meanY - meanX * period)
  }
}
