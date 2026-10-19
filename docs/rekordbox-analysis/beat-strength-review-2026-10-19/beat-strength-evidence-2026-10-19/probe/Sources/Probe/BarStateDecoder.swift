//
//  BarStateDecoder.swift
//  BoomBoomBoomKit
//
//  Story 15.6 — structured 4/4 decoder.
//
//  Takes ``FramewiseObservations`` and a candidate tempo, emits a
//  ``CandidateBeatSequence`` whose beats sit on peaks in the observation
//  stream at inter-beat intervals of `60 / tempoBPM` seconds. Each beat
//  carries the index of the grid position it was found at, so gaps (silence,
//  dropped kicks) stay visible to later stages. Downbeats are annotated on
//  one of the four bar phases (4/4 assumption): the phase with the largest
//  summed downbeat probability.
//
//  Simplified relative to the published Böck ISMIR 2016 bar-state HMM
//  (that model uses Viterbi over a bar-position state space). This story
//  ships a windowed peak-pick that re-anchors on every beat it finds, which
//  is sufficient to wire the end-to-end path and measure whether the
//  stub-plus-decoder path is a decision-worthy baseline per DD #0. A full
//  HMM lands in a follow-up when a trained observation head arrives.
//

import Foundation

/// A beat sequence produced by ``BarStateDecoder``, carrying per-beat
/// time, grid position, observation support, and a downbeat flag.
internal struct CandidateBeatSequence: Sendable, Hashable {

  /// One beat in the sequence.
  struct Beat: Sendable, Hashable {
    /// Decoded-PCM time, in seconds.
    let time: Double
    /// Index of the predicted grid position this beat was found at,
    /// counted from the first emitted beat (index 0). Positions where the
    /// decoder found no beat are skipped, so a gap in the input shows up as
    /// a jump in this index rather than as a shifted sequence.
    let gridIndex: Int
    /// Beat probability at the beat's frame, `[0, 1]`.
    let beatSupport: Float
    /// Downbeat probability at the beat's frame, `[0, 1]`.
    let downbeatSupport: Float
    /// Whether this beat is marked as a bar start: its `gridIndex % 4` is
    /// the bar phase with the largest summed downbeat support. Ties go to
    /// phase 0, so a producer with no bar-level evidence (for example the
    /// DSP stub's flat `0.5 * beat` downbeat channel) yields a phase that
    /// carries no information.
    let isDownbeat: Bool
  }

  /// The beats, in strictly increasing time order.
  let beats: [Beat]

  /// Tempo the decoder was asked to track, in BPM.
  let tempoBPM: Double

  /// Metrical level this candidate represents (quarter, half, or double of
  /// the originally supplied tempo). Preserved so
  /// ``MetricalLevelSelector`` can report its decision.
  let metricalLevel: MetricalLevel

  /// Mean beat probability across the emitted beats.
  let meanBeatSupport: Float

  /// On-beat minus off-beat contrast, averaged over every predicted grid
  /// position (including positions where no beat was emitted). The scalar
  /// ``MetricalLevelSelector`` ranks candidates by. See
  /// ``BarStateDecoder/decode(observations:tempoBPM:level:)`` for the
  /// window definitions.
  let contrastScore: Float

  /// Number of grid positions the decoder predicted, whether or not a beat
  /// was emitted at each. The denominator of ``contrastScore``.
  let predictedPositionCount: Int
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

  /// Decodes a candidate beat sequence from the observation stream.
  ///
  /// With period `P` in frames at the effective tempo, each predicted
  /// position `p` has two non-overlapping windows:
  ///
  /// - on-window `[p - P/4, p + P/4)`: its maximum beat probability is the
  ///   on-beat support, and its argmax is the emitted beat. The start is
  ///   clipped at frame 0;
  /// - off-window: its maximum is the off-beat support. When the on-window
  ///   yields a beat at frame `f`, the off-window is `[f + P/4, f + 3P/4)`,
  ///   anchored on the picked frame so it never overlaps the next on-window
  ///   `[f + 3P/4, f + 5P/4)`. When the on-window is empty it is
  ///   `[p + P/4, p + 3P/4)`.
  ///
  /// A frame `f` is admissible when its anchored off-window fits inside the
  /// usable span: `f + 3P/4 <= usableFrames`.
  ///
  /// The first beat is the argmax of beat probability over admissible frames,
  /// searched one period at a time from frame 0 and taken from the first
  /// period whose maximum is nonzero. The last search window may be a partial
  /// period, and a stronger peak past the last admissible frame is never
  /// chosen. That seed frame is used directly as the first beat: its on-beat
  /// support is its own probability and its off-window is anchored on it,
  /// with no on-window re-search at position 0, so a stronger inadmissible
  /// neighbour cannot displace it.
  ///
  /// After a beat is emitted the next prediction is `argmax + P` (re-anchored
  /// on the picked frame, so fractional periods cannot accumulate drift);
  /// after a position whose on-window maximum is zero, no beat is emitted and
  /// the next prediction is `p + P`. Decoding stops at the first position
  /// whose windows do not fit inside the usable span: a prediction with
  /// `p + 3P/4 > usableFrames`, or a picked frame whose anchored off-window
  /// would run past it. Such a position is neither scored nor emitted, so
  /// every predicted position is scored on complete windows.
  ///
  /// - Parameters:
  ///   - observations: ``FramewiseObservations`` from the producer.
  ///   - tempoBPM: Tempo to track at. The caller is responsible for
  ///     having resolved this (typically from ``BPMAnalyzer``).
  ///   - level: Metrical level relative to `tempoBPM`.
  /// - Returns: A ``CandidateBeatSequence``, or `nil` for a non-positive
  ///   effective tempo, a period shorter than four frames, input shorter
  ///   than one period, or no nonzero beat probability at an admissible
  ///   frame.
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

    let coverageFrames = Int(
      (observations.coverageWindowSeconds * observations.frameRate).rounded(.down))
    let usableFrames = min(observations.frameCount, max(0, coverageFrames))
    guard Double(usableFrames) >= periodFrames else { return nil }

    let probabilities = observations.beatProbabilities

    // Max and argmax over integer frames in `[lower, upper)` clipped to the
    // usable span. Ties keep the earliest frame; an all-zero window returns
    // a zero maximum.
    func windowMax(from lower: Double, to upper: Double) -> (value: Float, frame: Int) {
      let start = max(0, Int(lower.rounded(.up)))
      let end = min(usableFrames, Int(upper.rounded(.up)))
      var best: Float = 0
      var bestFrame = start
      if start < end {
        for i in start..<end where probabilities[i] > best {
          best = probabilities[i]
          bestFrame = i
        }
      }
      return (best, bestFrame)
    }

    let quarterPeriod = periodFrames / 4.0
    // Admissible frames are the integers `f` with
    // `f + 3 * quarterPeriod <= usableFrames`, ending at
    // `floor(lastAdmissible)` inclusive.
    let lastAdmissible = Double(usableFrames) - 3.0 * quarterPeriod
    let seedEndExclusive = lastAdmissible.rounded(.down) + 1

    // First beat: the argmax of the first period with any support, over
    // admissible frames only. The last window may be a partial period.
    var seedStart = 0.0
    var firstFrame: Int?
    while seedStart < seedEndExclusive {
      let seed = windowMax(
        from: seedStart, to: min(seedStart + periodFrames, seedEndExclusive))
      if seed.value > 0 {
        firstFrame = seed.frame
        break
      }
      seedStart += periodFrames
    }
    guard let firstFrame else { return nil }

    // Position 0 is the seed frame itself, with its off-window anchored on
    // it. It is admissible by construction, so that off-window fits.
    let firstOffWindow = windowMax(
      from: Double(firstFrame) + quarterPeriod, to: Double(firstFrame) + 3.0 * quarterPeriod)
    var contrastSum: Float = probabilities[firstFrame] - firstOffWindow.value
    var positionCount = 1
    var found: [(frame: Int, gridIndex: Int)] = [(firstFrame, 0)]
    var prediction = Double(firstFrame) + periodFrames
    var gridIndex = 1

    // Every later predicted position needs its full on and off windows
    // inside the usable span.
    while prediction + 3.0 * quarterPeriod <= Double(usableFrames) {
      let onWindow = windowMax(from: prediction - quarterPeriod, to: prediction + quarterPeriod)
      // Anchor the off-window on the picked frame when there is one, so it
      // stays disjoint from the next on-window after re-anchoring.
      let offAnchor = onWindow.value > 0 ? Double(onWindow.frame) : prediction
      // A pick late in its on-window can push the anchored off-window past
      // the usable span. Stop before scoring or emitting it, so no position
      // is scored on a clipped off-window.
      if offAnchor + 3.0 * quarterPeriod > Double(usableFrames) { break }
      let offWindow = windowMax(
        from: offAnchor + quarterPeriod, to: offAnchor + 3.0 * quarterPeriod)
      contrastSum += onWindow.value - offWindow.value
      positionCount += 1
      if onWindow.value > 0 {
        found.append((onWindow.frame, gridIndex))
        prediction = Double(onWindow.frame) + periodFrames
      } else {
        prediction += periodFrames
      }
      gridIndex += 1
    }

    // Downbeat phase: the bar position (gridIndex mod 4) whose beats carry
    // the largest summed downbeat probability. Ties keep the lowest phase.
    var phaseSupport = [Float](repeating: 0, count: beatsPerBar)
    for entry in found {
      phaseSupport[entry.gridIndex % beatsPerBar] +=
        observations.downbeatProbabilities[entry.frame]
    }
    var downbeatPhase = 0
    for phase in 1..<beatsPerBar where phaseSupport[phase] > phaseSupport[downbeatPhase] {
      downbeatPhase = phase
    }

    var supportSum: Float = 0
    let beats = found.map { entry -> CandidateBeatSequence.Beat in
      let support = probabilities[entry.frame]
      supportSum += support
      return CandidateBeatSequence.Beat(
        time: observations.timeForFrame(entry.frame),
        gridIndex: entry.gridIndex,
        beatSupport: support,
        downbeatSupport: observations.downbeatProbabilities[entry.frame],
        isDownbeat: entry.gridIndex % beatsPerBar == downbeatPhase
      )
    }

    return CandidateBeatSequence(
      beats: beats,
      tempoBPM: effectiveTempoBPM,
      metricalLevel: level,
      meanBeatSupport: supportSum / Float(beats.count),
      contrastScore: contrastSum / Float(positionCount),
      predictedPositionCount: positionCount
    )
  }
}
