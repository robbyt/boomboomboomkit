//
//  BarStateDecoder.swift
//  BoomBoomBoomKit
//
//  Story 15.6, structured 4/4 decoder.
//
//  Takes ``FramewiseObservations`` and a candidate tempo, emits a
//  ``CandidateBeatSequence`` whose beats are observed peaks in the beat
//  channel, judged against a floating-point prediction clock that advances
//  by one period of `60 / tempoBPM` seconds per grid position. A predicted
//  grid position, an observed beat, and a phase correction are three
//  separate decisions: the clock advances whether or not a beat is
//  observed, a peak is observed only when it stands out from its local
//  background, and only an observation close to the prediction moves the
//  clock. Each beat carries the index of the grid position it was observed
//  at, so gaps (silence, dropped kicks) stay visible to later stages.
//
//  Downbeats are annotated on one of the four bar phases (4/4 assumption):
//  the phase whose beats carry the highest MEAN downbeat probability. The
//  mean removes the bias toward phases with more surviving beats and
//  nothing more. On the DSP stub the downbeat channel is a flat
//  `0.5 * beat`, which carries no bar information, so the chosen phase
//  there follows beat amplitude, not bar structure.
//
//  Simplified relative to the published Böck ISMIR 2016 bar-state HMM
//  (that model uses Viterbi over a bar-position state space). This story
//  ships a windowed peak-pick with a local evidence rule and a bounded
//  phase correction, which is sufficient to wire the end-to-end path and
//  measure whether the stub-plus-decoder path is a decision-worthy
//  baseline per DD #0. A full HMM lands in a follow-up when a trained
//  observation head arrives.
//

import Foundation

/// A beat sequence produced by ``BarStateDecoder``, carrying per-beat
/// time, grid position, observation support, and a downbeat flag.
internal struct CandidateBeatSequence: Sendable, Hashable {

  /// Whether the decoder observed any beat.
  enum Evidence: Sendable, Hashable {
    /// At least one beat passed the evidence rule; ``beats`` is non-empty
    /// and the grid phase was acquired from the first observed beat.
    case observed
    /// No frame in the usable span passed the evidence rule; ``beats`` is
    /// empty and the predicted positions are counted from frame 0, a
    /// bookkeeping phase that is not an acquired musical phase.
    case none
  }

  /// One beat in the sequence.
  struct Beat: Sendable, Hashable {
    /// Decoded-PCM time, in seconds.
    let time: Double
    /// Index of the predicted grid position this beat was observed at,
    /// counted from the first emitted beat (index 0). Positions where the
    /// decoder observed no beat are skipped, so a gap in the input shows
    /// up as a jump in this index rather than as a shifted sequence.
    let gridIndex: Int
    /// Beat probability at the beat's frame, `[0, 1]`. The raw value, not
    /// the prominence.
    let beatSupport: Float
    /// Downbeat probability at the beat's frame, `[0, 1]`.
    let downbeatSupport: Float
    /// Evidence for this observation: beat probability above the local
    /// background median, in probability units. It is evidence, not a
    /// probability, and is at least
    /// ``BarStateDecoder/prominenceMultiplier`` times the local
    /// effective scale for every emitted beat.
    let prominence: Float
    /// Whether this observation moved the prediction clock. True for the
    /// seed beat, for an observation inside the correction tier, and for
    /// both beats of a confirmed reacquisition. False for an outer-tier
    /// observation the clock coasted past.
    let correctedClock: Bool
    /// Whether `gridIndex % 4` is the chosen bar phase: the phase with the
    /// highest mean downbeat support over its beats, ties to the lowest
    /// populated phase. The mean removes sample-count bias only: one strong
    /// beat can outweigh many moderate ones. The DSP stub's downbeat
    /// channel is a flat `0.5 * beat`, so there this flag follows beat
    /// amplitude and carries no bar information; good beat tracking on the
    /// stub is no evidence of downbeat detection. See
    /// ``CandidateBeatSequence/downbeatPhaseUnique``.
    let isDownbeat: Bool
  }

  /// The beats, in strictly increasing time order. Empty exactly when
  /// ``evidence`` is ``Evidence/none``.
  let beats: [Beat]

  /// Tempo the decoder was asked to track, in BPM.
  let tempoBPM: Double

  /// Metrical level this candidate represents (quarter, half, or double of
  /// the originally supplied tempo). Preserved so
  /// ``MetricalLevelSelector`` can report its decision.
  let metricalLevel: MetricalLevel

  /// Mean beat probability across the emitted beats, or 0 when no beat
  /// was observed.
  let meanBeatSupport: Float

  /// On-beat minus off-beat contrast, averaged over every predicted grid
  /// position (including positions where no beat was emitted). Signed.
  /// The scalar ``MetricalLevelSelector`` ranks candidates by. See
  /// ``BarStateDecoder/decode(observations:tempoBPM:level:)`` for the
  /// window definitions.
  let contrastScore: Float

  /// Number of grid positions the decoder predicted, whether or not a beat
  /// was emitted at each. The denominator of ``contrastScore``.
  let predictedPositionCount: Int

  /// Whether any beat passed the evidence rule.
  let evidence: Evidence

  /// Whether the chosen downbeat phase has a strictly higher mean downbeat
  /// support than every other populated phase. A unique-winner flag only:
  /// it says nothing about independent bar evidence. On the stub's
  /// `0.5 * beat` downbeat channel it is true whenever beat amplitudes
  /// differ by phase. False when no beat was observed.
  let downbeatPhaseUnique: Bool

  /// Number of confirmed provisional reacquisitions (an outer-tier
  /// observation after a prediction-only position, confirmed by an
  /// observation one period later). See
  /// ``BarStateDecoder/decode(observations:tempoBPM:level:)``.
  let reacquisitionCount: Int

  /// Identifier of the decoder rule set that produced this candidate,
  /// ``BarStateDecoder/decoderIdentifier``.
  let decoderIdentifier: String
}

/// Metrical-level the decoder is tracking at. Named relative to the
/// originally-supplied tempo so a consumer can tell which octave was
/// chosen without re-reading the input.
internal enum MetricalLevel: String, Sendable, Hashable, CaseIterable {
  /// Beats at the input tempo (default).
  case quarter
  /// Beats every two input-tempo periods (half tempo).
  case half
  /// Beats every half of an input-tempo period (double tempo).
  case double

  /// Factor to apply to the input tempo to get this level's effective tempo.
  var factor: Double {
    switch self {
    case .quarter: return 1.0
    case .half: return 0.5
    case .double: return 2.0
    }
  }
}

/// The structured 4/4 decoder.
internal enum BarStateDecoder {

  /// Number of bar phases under the 4/4 assumption.
  static let beatsPerBar = 4

  /// Identifier of this rule set, recorded on every
  /// ``CandidateBeatSequence/decoderIdentifier``.
  static let decoderIdentifier = "bar-state-decoder.v2.local-evidence"

  /// Half-width of the correction tier as a fraction of the period. An
  /// observation within this distance of the prediction moves the clock.
  /// Initial value; a later tuning story owns it.
  static let maxPhaseCorrectionFraction = 0.15

  /// Fraction of a correction-tier residual applied to the clock. 1.0
  /// re-anchors the clock on the observed frame. Initial value; a later
  /// tuning story owns it.
  static let phaseCorrectionGain = 1.0

  /// Tolerance, as a fraction of the period, within which the observation
  /// one period after a provisional reacquisition must land to confirm it.
  /// Initial value; a later tuning story owns it.
  static let reacquisitionConfirmFraction = 0.05

  /// Extent of the local background window on each side of a prediction,
  /// in periods. Initial value; a later tuning story owns it.
  static let backgroundWindowPeriods = 4.0

  /// Floor on the background scale (raw median absolute deviation), in
  /// probability units, so a flat background does not turn a negligible
  /// perturbation into evidence. Initial value; a later tuning story owns
  /// it.
  static let minEffectiveScale: Float = 0.01

  /// Prominence an observation needs, in multiples of the effective
  /// background scale. Initial value; a later tuning story owns it.
  static let prominenceMultiplier: Float = 3

  /// Decodes a candidate beat sequence from the observation stream.
  ///
  /// With period `P` in frames at the effective tempo and `Q = P/4`, every
  /// predicted position `p` takes three decisions, in this order.
  ///
  /// 1. Prediction. `p` is a floating-point clock in frames. It advances by
  ///    `P` at every position and `gridIndex` increments at every position,
  ///    whether or not a beat is observed. The decoder never changes the
  ///    rate; the fitter estimates it.
  /// 2. Observation. The on-window is `[p - Q, p + Q)` (its start clipped
  ///    at frame 0). Inside it, the correction tier is
  ///    `[p - cP, p + cP)` with `c =` ``maxPhaseCorrectionFraction``. The
  ///    tier's argmax (ties: the frame nearest `p`, then the earlier frame)
  ///    is the observed beat if it passes the evidence rule. Otherwise the
  ///    argmax of the rest of the on-window, by the same tie rule, is the
  ///    observed beat if it passes. A genuine beat at `p` therefore wins
  ///    over a stronger distractor at `p + 0.2P`, while a lone off-centre
  ///    onset is still observed. If nothing passes, the position is
  ///    prediction-only: no beat, and the clock coasts.
  /// 3. Correction. A correction-tier observation at frame `f` moves the
  ///    clock: the next prediction is `p + g(f - p) + P`, with
  ///    `g =` ``phaseCorrectionGain`` (1.0, so `f + P`). An outer-tier
  ///    observation is emitted (the fitter judges it against its global
  ///    line) but the clock coasts: the next prediction is `p + P`.
  ///
  /// Evidence rule. The background is the beat probabilities within
  /// ``backgroundWindowPeriods`` periods on each side of `p`, excluding the
  /// on-window and clipped to the usable span. With `background` their
  /// median and `scale` their raw (unscaled) median absolute deviation,
  /// `effectiveScale` is the larger of `scale` and ``minEffectiveScale``
  /// (0.01) and `prominence = value - background`. A frame passes when
  /// `prominence >= m * effectiveScale` with `m =`
  /// ``prominenceMultiplier`` (3); the comparison is inclusive. A constant
  /// stream has prominence 0 everywhere. Stated limit: the DSP stub
  /// normalizes by the span maximum and the minimum passing prominence is
  /// 0.03, so a beat train quieter than 3 percent of the loudest onset in
  /// the span is not observed. An evidence scale independent of span
  /// normalization is a follow-up.
  ///
  /// Seed acquisition uses the same rule. The admissible frames (`f` with
  /// `f + 3Q <= usableFrames`, so the anchored off-window fits) are walked
  /// one period at a time from frame 0; the last window may be a partial
  /// period. The first window whose argmax (ties: earliest) passes, with
  /// its background centred on that frame, supplies the seed. A quiet
  /// leading floor therefore cannot choose a false initial phase, and a
  /// stronger peak past the last admissible frame is never chosen. The seed
  /// frame is the first beat (position 0): its on-beat support is its own
  /// probability and its off-window is anchored on it, with no on-window
  /// re-search, so a stronger inadmissible neighbour cannot displace it.
  /// The seed reports `correctedClock == true`.
  ///
  /// Provisional reacquisition. When the previous position was
  /// prediction-only (a coasted outer-tier observation does not count) and
  /// the current observation `f` is outer-tier, the decoder tentatively
  /// re-anchors on `f` and evaluates the next position at the provisional
  /// prediction `f + P`. The reacquisition is confirmed only when that
  /// position yields an observation within ``reacquisitionConfirmFraction``
  /// of a period of the provisional prediction; then both beats report
  /// `correctedClock == true` and ``CandidateBeatSequence/reacquisitionCount``
  /// increments. Otherwise the provisional evaluation is discarded, the
  /// next position is evaluated under the coasted clock `p + P`, and `f`
  /// stays emitted as an ordinary outer-tier beat. If coverage ends before
  /// the confirming position exists, `f` is finalized the same way. Stated
  /// limit: a stub-era heuristic with one position of lookahead. A second
  /// transient one period after the first confirms a wrong reacquisition,
  /// and a gap long enough for the clock error to exceed a quarter period
  /// can displace grid indices by one, which reacquisition does not repair.
  ///
  /// Scoring. Every scored position adds the full on-window maximum minus
  /// the off-window maximum to the contrast sum, whichever tier supplied
  /// the observation and whether or not one passed. The off-window is
  /// `[a + Q, a + 3Q)`, anchored on the committed clock decision `a`: the
  /// observed frame for a correction-tier observation or a confirmed
  /// reacquisition, `p` otherwise, never a discarded peak. It is therefore
  /// disjoint from the next on-window. A rolled-back position is scored
  /// once, under the coasted clock. Decoding stops at the first position
  /// whose windows do not fit inside the usable span: a prediction with
  /// `p + 3Q > usableFrames`, or a committed anchor whose off-window would
  /// run past it. Such a position is neither scored nor emitted.
  ///
  /// No evidence versus inadmissible evidence. When no admissible seed
  /// window passes, the whole usable span is scanned. If no frame passes
  /// the evidence rule (a positive constant, a subthreshold ramp), the
  /// result is a no-evidence candidate: no beats, positions counted from
  /// frame 0 at the candidate period (a bookkeeping phase, not an acquired
  /// musical phase), and the signed contrast over those positions, so it
  /// can serve as the selector's quarter-level baseline. If some frame
  /// passes but none in an admissible seed window, the result is `nil`.
  ///
  /// - Parameters:
  ///   - observations: ``FramewiseObservations`` from the producer.
  ///   - tempoBPM: Tempo to track at. The caller is responsible for
  ///     having resolved this (typically from ``BPMAnalyzer``).
  ///   - level: Metrical level relative to `tempoBPM`.
  /// - Returns: `nil` for a non-positive or non-finite effective tempo, a
  ///   period shorter than four frames, a usable span shorter than one
  ///   period, an all-zero usable span, or evidence that exists only past
  ///   the last admissible seed frame. Otherwise a
  ///   ``CandidateBeatSequence`` with ``CandidateBeatSequence/Evidence/observed``
  ///   evidence, or a no-evidence candidate with
  ///   ``CandidateBeatSequence/Evidence/none``, empty beats,
  ///   `meanBeatSupport == 0`, `downbeatPhaseUnique == false`, and
  ///   `reacquisitionCount == 0`.
  static func decode(
    observations: FramewiseObservations,
    tempoBPM: Double,
    level: MetricalLevel
  ) -> CandidateBeatSequence? {
    let effectiveTempoBPM = tempoBPM * level.factor
    guard effectiveTempoBPM.isFinite, effectiveTempoBPM > 0 else { return nil }
    let periodFrames = 60.0 / effectiveTempoBPM * observations.frameRate
    // A quarter-period window must span at least one frame.
    guard periodFrames >= 4 else { return nil }

    let usableFrames = observations.usableFrameCount
    guard Double(usableFrames) >= periodFrames else { return nil }

    let probabilities = observations.beatProbabilities
    let usable = probabilities[0..<usableFrames]
    guard usable.contains(where: { $0 > 0 }) else { return nil }

    let context = DecodeContext(
      probabilities: probabilities, usableFrames: usableFrames, periodFrames: periodFrames)

    guard let seed = context.acquireSeed() else {
      // No admissible seed window passes. Evidence elsewhere in the span
      // is inadmissible evidence (nil); no evidence at all yields the
      // selector's no-evidence baseline.
      if context.anyFramePasses(minimum: usable.min() ?? 0) { return nil }
      return context.noEvidenceCandidate(tempoBPM: effectiveTempoBPM, level: level)
    }
    return context.track(
      from: seed, observations: observations, tempoBPM: effectiveTempoBPM, level: level)
  }
}

// MARK: - Decoding internals

/// One observed beat before conversion to ``CandidateBeatSequence/Beat``.
private struct EmittedBeat {
  let frame: Int
  let gridIndex: Int
  let prominence: Float
  let correctedClock: Bool
}

/// A passing observation at one predicted position.
private struct PositionObservation {
  let frame: Int
  let inCorrectionTier: Bool
  let prominence: Float
}

/// The observation decision at one predicted position.
private struct PositionEvaluation {
  /// Full on-window maximum, the on-beat term of the contrast.
  let onMax: Float
  let observation: PositionObservation?
}

/// Per-call state shared by the decoding steps.
private struct DecodeContext {
  let probabilities: [Float]
  let usableFrames: Int
  let periodFrames: Double
  let quarterPeriod: Double

  init(probabilities: [Float], usableFrames: Int, periodFrames: Double) {
    self.probabilities = probabilities
    self.usableFrames = usableFrames
    self.periodFrames = periodFrames
    self.quarterPeriod = periodFrames / 4.0
  }

  /// Integer frames in `[lower, upper)` clipped to the usable span.
  func frames(from lower: Double, to upper: Double) -> Range<Int> {
    let start = min(usableFrames, max(0, Int(lower.rounded(.up))))
    let end = min(usableFrames, max(start, Int(upper.rounded(.up))))
    return start..<end
  }

  /// Maximum over `[lower, upper)` clipped to the usable span; 0 when empty.
  func windowMax(from lower: Double, to upper: Double) -> Float {
    var best: Float = 0
    for i in frames(from: lower, to: upper) where probabilities[i] > best {
      best = probabilities[i]
    }
    return best
  }

  /// Argmax over `ranges` (visited in increasing frame order). Ties go to
  /// the frame nearest `center` when one is given, then to the earlier
  /// frame. `nil` when every range is empty.
  func argmax(_ ranges: [Range<Int>], nearestTo center: Double?) -> Int? {
    var bestFrame: Int?
    for range in ranges {
      for i in range {
        guard let current = bestFrame else {
          bestFrame = i
          continue
        }
        let value = probabilities[i]
        let bestValue = probabilities[current]
        if value > bestValue {
          bestFrame = i
        } else if value == bestValue, let center,
          abs(Double(i) - center) < abs(Double(current) - center)
        {
          bestFrame = i
        }
      }
    }
    return bestFrame
  }

  /// Median and raw median absolute deviation of the background around
  /// `center`: frames within ``BarStateDecoder/backgroundWindowPeriods``
  /// periods on each side, excluding the on-window `[center - Q,
  /// center + Q)`, clipped to the usable span.
  func background(around center: Double) -> (median: Float, scale: Float) {
    let reach = BarStateDecoder.backgroundWindowPeriods * periodFrames
    let outer = frames(from: center - reach, to: center + reach)
    let excluded = frames(from: center - quarterPeriod, to: center + quarterPeriod)
    var values: [Float] = []
    values.reserveCapacity(outer.count)
    for i in outer where !excluded.contains(i) {
      values.append(probabilities[i])
    }
    guard !values.isEmpty else { return (0, 0) }
    let median = Self.median(of: &values)
    var deviations = values.map { abs($0 - median) }
    return (median, Self.median(of: &deviations))
  }

  /// Median of a non-empty array (mean of the two middle values for an
  /// even count). Sorts `values` in place.
  static func median(of values: inout [Float]) -> Float {
    values.sort()
    let mid = values.count / 2
    if values.count % 2 == 1 { return values[mid] }
    return (values[mid - 1] + values[mid]) / 2
  }

  /// Prominence of `frame` above the background around `center`, and
  /// whether it passes the evidence rule.
  func evidence(
    at frame: Int, background: (median: Float, scale: Float)
  ) -> (passes: Bool, prominence: Float) {
    let effectiveScale = max(background.scale, BarStateDecoder.minEffectiveScale)
    let prominence = probabilities[frame] - background.median
    return (prominence >= BarStateDecoder.prominenceMultiplier * effectiveScale, prominence)
  }

  /// The seed frame and its prominence: the argmax of the first admissible
  /// period-long window whose argmax passes the evidence rule.
  func acquireSeed() -> (frame: Int, prominence: Float)? {
    // Admissible frames are the integers `f` with
    // `f + 3 * quarterPeriod <= usableFrames`, ending at
    // `floor(lastAdmissible)` inclusive.
    let lastAdmissible = Double(usableFrames) - 3.0 * quarterPeriod
    let seedEndExclusive = lastAdmissible.rounded(.down) + 1
    var seedStart = 0.0
    while seedStart < seedEndExclusive {
      let window = frames(from: seedStart, to: min(seedStart + periodFrames, seedEndExclusive))
      if let frame = argmax([window], nearestTo: nil) {
        let check = evidence(at: frame, background: background(around: Double(frame)))
        if check.passes { return (frame, check.prominence) }
      }
      seedStart += periodFrames
    }
    return nil
  }

  /// Whether any usable frame passes the evidence rule. A frame whose
  /// value is less than the minimum passing prominence above the span
  /// minimum cannot pass (the background median is at least that
  /// minimum), so it is skipped without computing its background.
  func anyFramePasses(minimum: Float) -> Bool {
    let floor = BarStateDecoder.prominenceMultiplier * BarStateDecoder.minEffectiveScale
    for frame in 0..<usableFrames where probabilities[frame] - minimum >= floor {
      if evidence(at: frame, background: background(around: Double(frame))).passes {
        return true
      }
    }
    return false
  }

  /// Off-window maximum anchored on `anchor`, or `nil` when the off-window
  /// `[anchor + Q, anchor + 3Q)` would run past the usable span.
  func offMax(anchoredOn anchor: Double) -> Float? {
    guard anchor + 3.0 * quarterPeriod <= Double(usableFrames) else { return nil }
    return windowMax(from: anchor + quarterPeriod, to: anchor + 3.0 * quarterPeriod)
  }

  /// The observation decision at prediction `p`, or `nil` when
  /// `p + 3Q > usableFrames`.
  func evaluate(at prediction: Double) -> PositionEvaluation? {
    guard prediction + 3.0 * quarterPeriod <= Double(usableFrames) else { return nil }
    let onWindow = frames(from: prediction - quarterPeriod, to: prediction + quarterPeriod)
    let correctionHalfWidth = BarStateDecoder.maxPhaseCorrectionFraction * periodFrames
    let correctionTier = frames(
      from: prediction - correctionHalfWidth, to: prediction + correctionHalfWidth)
    var onMax: Float = 0
    for i in onWindow where probabilities[i] > onMax { onMax = probabilities[i] }

    let localBackground = background(around: prediction)
    if let frame = argmax([correctionTier], nearestTo: prediction) {
      let check = evidence(at: frame, background: localBackground)
      if check.passes {
        return PositionEvaluation(
          onMax: onMax,
          observation: PositionObservation(
            frame: frame, inCorrectionTier: true, prominence: check.prominence))
      }
    }
    let outerTier = [
      onWindow.lowerBound..<max(onWindow.lowerBound, correctionTier.lowerBound),
      min(correctionTier.upperBound, onWindow.upperBound)..<onWindow.upperBound,
    ]
    if let frame = argmax(outerTier, nearestTo: prediction) {
      let check = evidence(at: frame, background: localBackground)
      if check.passes {
        return PositionEvaluation(
          onMax: onMax,
          observation: PositionObservation(
            frame: frame, inCorrectionTier: false, prominence: check.prominence))
      }
    }
    return PositionEvaluation(onMax: onMax, observation: nil)
  }

  /// The next prediction after a correction from `prediction` to `frame`.
  func corrected(_ prediction: Double, to frame: Int) -> Double {
    prediction + BarStateDecoder.phaseCorrectionGain * (Double(frame) - prediction) + periodFrames
  }

  /// Tracks the grid from the seed and assembles the candidate.
  func track(
    from seed: (frame: Int, prominence: Float),
    observations: FramewiseObservations,
    tempoBPM: Double,
    level: MetricalLevel
  ) -> CandidateBeatSequence {
    // Position 0 is the seed frame itself, with its off-window anchored on
    // it. It is admissible by construction, so that off-window fits.
    let seedOff = offMax(anchoredOn: Double(seed.frame)) ?? 0
    var contrastSum: Float = probabilities[seed.frame] - seedOff
    var positionCount = 1
    var emitted = [
      EmittedBeat(
        frame: seed.frame, gridIndex: 0, prominence: seed.prominence, correctedClock: true)
    ]
    var prediction = Double(seed.frame) + periodFrames
    var gridIndex = 1
    var previousWasPredictionOnly = false
    var reacquisitionCount = 0

    while let current = evaluate(at: prediction) {
      let p = prediction
      guard let observation = current.observation else {
        // Prediction-only: no beat, the clock coasts, off-window on `p`.
        // `evaluate` checked `p + 3Q <= usableFrames`, so it fits.
        contrastSum += current.onMax - (offMax(anchoredOn: p) ?? 0)
        positionCount += 1
        prediction = p + periodFrames
        gridIndex += 1
        previousWasPredictionOnly = true
        continue
      }

      if observation.inCorrectionTier {
        // Correction: the off-window anchors on the observed frame. Stop
        // before a position whose anchored off-window would be clipped.
        guard let off = offMax(anchoredOn: Double(observation.frame)) else { break }
        contrastSum += current.onMax - off
        positionCount += 1
        emitted.append(
          EmittedBeat(
            frame: observation.frame, gridIndex: gridIndex,
            prominence: observation.prominence, correctedClock: true))
        prediction = corrected(p, to: observation.frame)
        gridIndex += 1
        previousWasPredictionOnly = false
        continue
      }

      if previousWasPredictionOnly,
        let confirmed = confirmReacquisition(at: p, observation: observation)
      {
        contrastSum += current.onMax - confirmed.provisionalOff
        contrastSum += confirmed.next.onMax - confirmed.nextOff
        positionCount += 2
        emitted.append(
          EmittedBeat(
            frame: observation.frame, gridIndex: gridIndex,
            prominence: observation.prominence, correctedClock: true))
        emitted.append(
          EmittedBeat(
            frame: confirmed.nextObservation.frame, gridIndex: gridIndex + 1,
            prominence: confirmed.nextObservation.prominence, correctedClock: true))
        reacquisitionCount += 1
        prediction = corrected(confirmed.provisionalPrediction, to: confirmed.nextObservation.frame)
        gridIndex += 2
        previousWasPredictionOnly = false
        continue
      }

      // Ordinary outer-tier observation: emitted, the clock coasts, and the
      // off-window stays on `p` (which `evaluate` checked fits).
      contrastSum += current.onMax - (offMax(anchoredOn: p) ?? 0)
      positionCount += 1
      emitted.append(
        EmittedBeat(
          frame: observation.frame, gridIndex: gridIndex,
          prominence: observation.prominence, correctedClock: false))
      prediction = p + periodFrames
      gridIndex += 1
      previousWasPredictionOnly = false
    }

    return assemble(
      emitted: emitted, observations: observations, tempoBPM: tempoBPM, level: level,
      contrastScore: contrastSum / Float(positionCount), positionCount: positionCount,
      reacquisitionCount: reacquisitionCount)
  }

  /// A confirmed provisional reacquisition: the provisional position's
  /// off-window term and the confirming position's evaluation.
  private struct Reacquisition {
    let provisionalOff: Float
    let provisionalPrediction: Double
    let next: PositionEvaluation
    let nextObservation: PositionObservation
    let nextOff: Float
  }

  /// Tentatively re-anchors on an outer-tier `observation` at prediction
  /// `p` and evaluates the next position under that provisional clock.
  /// Returns the confirmed reacquisition, or `nil` when the next position
  /// does not exist inside the usable span, yields no observation, yields
  /// one farther than ``BarStateDecoder/reacquisitionConfirmFraction`` of a
  /// period from the provisional prediction, or yields one whose anchored
  /// off-window would be clipped.
  private func confirmReacquisition(
    at p: Double, observation: PositionObservation
  ) -> Reacquisition? {
    guard let provisionalOff = offMax(anchoredOn: Double(observation.frame)) else {
      return nil
    }
    let provisional = corrected(p, to: observation.frame)
    guard let next = evaluate(at: provisional), let nextObservation = next.observation else {
      return nil
    }
    let tolerance = BarStateDecoder.reacquisitionConfirmFraction * periodFrames
    guard abs(Double(nextObservation.frame) - provisional) <= tolerance,
      let nextOff = offMax(anchoredOn: Double(nextObservation.frame))
    else { return nil }
    return Reacquisition(
      provisionalOff: provisionalOff, provisionalPrediction: provisional, next: next,
      nextObservation: nextObservation, nextOff: nextOff)
  }

  /// The no-evidence candidate: no beats, positions from frame 0 at the
  /// candidate period, signed contrast over those positions.
  func noEvidenceCandidate(tempoBPM: Double, level: MetricalLevel) -> CandidateBeatSequence {
    var contrastSum: Float = 0
    var positionCount = 0
    var prediction = 0.0
    while prediction + 3.0 * quarterPeriod <= Double(usableFrames) {
      let onMax = windowMax(from: prediction - quarterPeriod, to: prediction + quarterPeriod)
      let offMax = windowMax(
        from: prediction + quarterPeriod, to: prediction + 3.0 * quarterPeriod)
      contrastSum += onMax - offMax
      positionCount += 1
      prediction += periodFrames
    }
    // `usableFrames >= periodFrames > 3Q`, so position 0 always fits.
    return CandidateBeatSequence(
      beats: [],
      tempoBPM: tempoBPM,
      metricalLevel: level,
      meanBeatSupport: 0,
      contrastScore: contrastSum / Float(max(1, positionCount)),
      predictedPositionCount: positionCount,
      evidence: .none,
      downbeatPhaseUnique: false,
      reacquisitionCount: 0,
      decoderIdentifier: BarStateDecoder.decoderIdentifier
    )
  }

  /// Converts emitted beats into the candidate, choosing the downbeat
  /// phase by mean downbeat support.
  func assemble(  // swiftlint:disable:this function_parameter_count
    emitted: [EmittedBeat],
    observations: FramewiseObservations,
    tempoBPM: Double,
    level: MetricalLevel,
    contrastScore: Float,
    positionCount: Int,
    reacquisitionCount: Int
  ) -> CandidateBeatSequence {
    let beatsPerBar = BarStateDecoder.beatsPerBar
    // Downbeat phase: the bar position (gridIndex mod 4) whose beats carry
    // the highest mean downbeat probability. Ties keep the lowest populated
    // phase.
    var phaseSupport = [Double](repeating: 0, count: beatsPerBar)
    var phaseCount = [Int](repeating: 0, count: beatsPerBar)
    for entry in emitted {
      let phase = entry.gridIndex % beatsPerBar
      phaseSupport[phase] += Double(observations.downbeatProbabilities[entry.frame])
      phaseCount[phase] += 1
    }
    let populated = (0..<beatsPerBar).filter { phaseCount[$0] > 0 }
    let means = phaseSupport.indices.map {
      phaseCount[$0] > 0 ? phaseSupport[$0] / Double(phaseCount[$0]) : 0
    }
    var downbeatPhase = populated.first ?? 0
    for phase in populated where means[phase] > means[downbeatPhase] {
      downbeatPhase = phase
    }
    let downbeatPhaseUnique =
      !populated.isEmpty
      && populated.allSatisfy { $0 == downbeatPhase || means[$0] < means[downbeatPhase] }

    var supportSum: Float = 0
    let beats = emitted.map { entry -> CandidateBeatSequence.Beat in
      let support = probabilities[entry.frame]
      supportSum += support
      return CandidateBeatSequence.Beat(
        time: observations.timeForFrame(entry.frame),
        gridIndex: entry.gridIndex,
        beatSupport: support,
        downbeatSupport: observations.downbeatProbabilities[entry.frame],
        prominence: entry.prominence,
        correctedClock: entry.correctedClock,
        isDownbeat: entry.gridIndex % beatsPerBar == downbeatPhase
      )
    }

    return CandidateBeatSequence(
      beats: beats,
      tempoBPM: tempoBPM,
      metricalLevel: level,
      meanBeatSupport: supportSum / Float(beats.count),
      contrastScore: contrastScore,
      predictedPositionCount: positionCount,
      evidence: .observed,
      downbeatPhaseUnique: downbeatPhaseUnique,
      reacquisitionCount: reacquisitionCount,
      decoderIdentifier: BarStateDecoder.decoderIdentifier
    )
  }
}
