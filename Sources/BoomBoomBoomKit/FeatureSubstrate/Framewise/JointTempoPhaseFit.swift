//
//  JointTempoPhaseFit.swift
//  BoomBoomBoomKit
//
//  Story 15.7 (Epic 15, Phase 7): joint tempo and phase fit over a
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
//     pull the seed. When fewer than `minKeptBeats` beats lie within the
//     trim threshold of that seed, a robust line over all beats seeds the
//     fit instead, provided its tempo is within `maxTempoDeviationFraction`
//     of the candidate's. That line's rate is the median of the pairwise
//     slopes and its phase the median offset against that rate, so a
//     minority of off-grid beats moves neither its rate nor its phase.
//  3. Beats whose residual against the current line exceeds
//     `trimThresholdFactor * period` are dropped (hard trimming), and tempo
//     and phase are re-fit by least squares of beat time against grid
//     index. Up to three passes. The kept fraction is recorded on the
//     result so a review can see how much was set aside.
//  4. The kept set is checked once more against the returned line. If the
//     third pass still changed it, the final line was never trimmed
//     against, and the fit abstains rather than report a line whose own
//     kept beats may sit outside the threshold.
//  5. The fit abstains (returns nil) on too few kept beats, too low a kept
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

  /// Opaque identifier for the fit algorithm
  /// (``JointTempoPhaseFit/modelIdentifier``). Identifies the fitter only;
  /// the decoder that produced the candidate is ``decoderIdentifier``.
  let modelIdentifier: String

  /// Opaque identifier for the decoder that produced the candidate beat
  /// sequence the fit consumed, carried through from
  /// ``CandidateBeatSequence/decoderIdentifier``.
  let decoderIdentifier: String

  /// Opaque identifier for the observation frontend that fed the fit.
  let frontendIdentifier: String

  /// Opaque identifier of the producer of the observation stream the fit
  /// consumed, carried from ``FramewiseObservations/modelIdentifier``.
  /// Distinct from ``frontendIdentifier``, so two producers sharing one
  /// frontend stay distinguishable in a saved result.
  let observationModelIdentifier: String

  /// Coverage window the fit was computed over, in seconds.
  let coverageWindowSeconds: Double
}

/// Joint tempo + phase fit entry point.
internal enum JointTempoPhaseFit {

  /// Current algorithm identifier for the fit.
  static let modelIdentifier = "joint-tempo-phase.v4.robust-fallback-seed.final-validated"

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
  ///
  /// This is an amplitude gate on span-normalized support: the DSP stub
  /// divides its onset envelope by the span maximum, so the gate rejects a
  /// beat train whose beats average under 10 percent of the loudest onset,
  /// however cleanly ``BarStateDecoder`` tracked it. That is a known limit:
  /// a quiet intro or breakdown under one loud transient is decoded and
  /// then abstains here.
  ///
  /// The gate also incidentally rejects some false fits on sparse noise.
  /// On 20 seeded streams of 0.04 transients at 10 percent density with
  /// one 1.0 frame (`fitFalseAcceptanceOnSparseNoiseIsBounded`), the fit
  /// accepted 13 of 20 with this gate, both before and after the final-line
  /// validation. Without the gate it accepted 20 of 20 before that
  /// validation and 19 of 20 after, so the gate rejected 7 and 6 false fits
  /// respectively. Every false fit it lets through is at the half level near
  /// 60 BPM, on 12 beats whose mean support is 0.12 to 0.13 because the one
  /// 1.0 frame is among them. The gate is kept for the rejections it makes,
  /// not because amplitude is evidence of a beat.
  ///
  /// Replacing it with an evidence-quality or temporal-consistency criterion
  /// is a follow-up (deferred-work W98), measured against the seeded-noise
  /// ceiling. The decoder's per-beat `prominence` and `correctedClock`
  /// fields are not yet consumed by the fit.
  static let minSupportScore: Float = 0.1

  /// Maximum number of trim-and-refit passes.
  static let maxTrimPasses = 3

  /// Maximum number of points the fallback seed's pairwise-slope median is
  /// taken over. See ``robustLine(x:y:)``.
  static let robustSeedSampleCount = 256

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
  ///   ``minSupportScore``, the regression is degenerate, the refit
  ///   tempo leaves `candidate.tempoBPM` by more than
  ///   ``maxTempoDeviationFraction``, or the trim did not converge: the
  ///   beats within the trim threshold of the returned line are not exactly
  ///   the beats that line was fitted on. A candidate with no observed
  ///   beats (``CandidateBeatSequence/Evidence/none``) is rejected by the
  ///   ``minKeptBeats`` guard.
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
    let trimThreshold = trimThresholdFactor * seedPeriod

    // Fallback seed. The candidate's tempo is the caller's seed, not a rate
    // measured from these beats. When the beat spacing is off it by more
    // than roughly `2 * trimThresholdFactor / minKeptBeats` (about 3.75
    // percent), the median-phase line keeps fewer than `minKeptBeats` beats
    // and the first pass would abstain, although a refit up to
    // `maxTempoDeviationFraction` (5 percent) is in contract. Only in that
    // case a robust line over all beats seeds the fit: its rate is the
    // median of the pairwise slopes and its phase the median offset against
    // that rate, so a minority of off-grid beats moves neither.
    let seedKeptCount = beats.indices.count { i in
      abs(times[i] - (line.phase + gridIndices[i] * line.period)) <= trimThreshold
    }
    if seedKeptCount < minKeptBeats,
      let robust = robustLine(x: gridIndices, y: times),
      abs(seedPeriod / robust.period - 1.0) <= maxTempoDeviationFraction
    {
      line = robust
    }

    // Step 3: trim against the current line, refit on the kept beats.
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

    // Step 4: final-line validation. A converged loop satisfies this
    // exactly: the same kept set reproduces the same regression, so it
    // keeps the same beats. When the last pass still changed the set, the
    // returned line was never trimmed against; if its own threshold now
    // selects a different set, the trim did not converge and the fit
    // abstains.
    let finalKept = beats.indices.filter { i in
      abs(times[i] - (line.phase + gridIndices[i] * line.period)) <= trimThreshold
    }
    guard finalKept == kept else { return nil }

    // Step 5: abstain checks.
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
      decoderIdentifier: candidate.decoderIdentifier,
      frontendIdentifier: observations.frontendIdentifier,
      observationModelIdentifier: observations.modelIdentifier,
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
    let usableFrames = observations.usableFrameCount
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

  /// Robust line `y = phase + x * period` for the fallback seed.
  ///
  /// The period is the Theil-Sen slope: the median of
  /// `(y[j] - y[i]) / (x[j] - x[i])` over index pairs `i < j` with
  /// `x[j] > x[i]`. The phase is the median of `y[i] - x[i] * period` over
  /// all points. A minority of off-grid points moves neither.
  ///
  /// Resource bound: above ``robustSeedSampleCount`` points, the slope is
  /// taken over that many points spaced evenly by position across the
  /// array. A uniform subsample keeps the outlier fraction, so robustness
  /// is unchanged. It caps the pair count at 32,640 for any track length,
  /// which matters because the coverage window has no duration cap. The
  /// phase median still uses every point.
  ///
  /// Returns `nil` for fewer than two distinct x values or a non-positive
  /// or non-finite period.
  private static func robustLine(
    x: [Double], y: [Double]
  ) -> (period: Double, phase: Double)? {
    let count = min(x.count, y.count)
    var sample: [Int] = []
    if count > robustSeedSampleCount {
      let last = robustSeedSampleCount - 1
      for k in 0..<robustSeedSampleCount {
        let index = k * (count - 1) / last
        if sample.last != index { sample.append(index) }
      }
    } else {
      sample = Array(0..<count)
    }
    var slopes: [Double] = []
    for (position, i) in sample.enumerated() {
      for j in sample[(position + 1)...] where x[j] > x[i] {
        slopes.append((y[j] - y[i]) / (x[j] - x[i]))
      }
    }
    guard !slopes.isEmpty else { return nil }
    let period = median(ofSorted: slopes.sorted())
    guard period.isFinite, period > 0 else { return nil }
    let offsets = (0..<count).map { y[$0] - x[$0] * period }.sorted()
    return (period, median(ofSorted: offsets))
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
