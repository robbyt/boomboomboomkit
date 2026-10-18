//
//  MetricalLevelSelector.swift
//  BoomBoomBoomKit
//
//  Story 15.6: pick the metrical level (quarter / half / double) with the
//  highest on-beat minus off-beat contrast across the coverage window.
//
//  Keeps octave decisions SEPARATE from BPM selection: a caller supplies a
//  tempo the BPM stage has already resolved, and the selector only decides
//  whether to track at that level, at its half, or at its double. The
//  derived grid never votes back into ``BPMAnalyzer``; `SignalSource.beatGrid`
//  and `SignalWeights.beatGrid` stay placeholders (DD #5).
//

import Foundation

/// Outcome of running ``MetricalLevelSelector/select(observations:tempoBPM:)``.
internal struct MetricalLevelSelection: Sendable, Hashable {

  /// The chosen candidate.
  let chosen: CandidateBeatSequence

  /// The runner-up candidate (useful for diagnostic / abstain decisions).
  /// When half and double both fail to decode, only the seed level is left
  /// and this collapses to the same candidate as ``chosen``, so a
  /// chosen-minus-runner-up margin reads 0 rather than signalling a clear
  /// win.
  let runnerUp: CandidateBeatSequence

  /// ``CandidateBeatSequence/contrastScore`` for each level the decoder
  /// returned a candidate for, keyed by level.
  let scoreByLevel: [MetricalLevel: Float]
}

/// Metrical-level selector.
internal enum MetricalLevelSelector {

  /// Runs the structured decoder at `tempoBPM` and at its half and double,
  /// returns the level with the highest
  /// ``CandidateBeatSequence/contrastScore``.
  ///
  /// Contrast rather than mean on-beat support is the ranking score because
  /// on-beat support alone does not separate octaves: a half-tempo grid
  /// lands on real beats just as well as the true grid does. Off-beat
  /// support is what penalizes it, since the skipped beat falls in its
  /// off-window. A tie is resolved toward ``MetricalLevel/quarter`` (the
  /// originally supplied tempo), then half, then double.
  ///
  /// Selection requires a seed-level (``MetricalLevel/quarter``) candidate
  /// as the comparison baseline, so a finer or coarser level cannot win by
  /// elimination: the result is `nil` whenever the seed level does not
  /// decode. By design this rejects a decodable half or double candidate
  /// when only that level fits the coverage (for example a 190-frame clip at
  /// 100 fps seeded at 60 BPM with one peak at frame 120, where double
  /// decodes and quarter does not). A caller that wants a result there must
  /// seed at the finer tempo.
  static func select(
    observations: FramewiseObservations,
    tempoBPM: Double
  ) -> MetricalLevelSelection? {
    var byLevel: [MetricalLevel: CandidateBeatSequence] = [:]
    for level in MetricalLevel.allCases {
      if let candidate = BarStateDecoder.decode(
        observations: observations, tempoBPM: tempoBPM, level: level)
      {
        byLevel[level] = candidate
      }
    }
    guard let quarter = byLevel[.quarter] else { return nil }

    // Rank by contrast. Prefer `.quarter` on ties so a borderline decision
    // does not flip octave on noise.
    let order: [MetricalLevel] = [.quarter, .half, .double]
    let ranked = order.compactMap { level -> (MetricalLevel, CandidateBeatSequence)? in
      guard let candidate = byLevel[level] else { return nil }
      return (level, candidate)
    }
    .sorted { lhs, rhs in
      if lhs.1.contrastScore == rhs.1.contrastScore {
        // Preserve input order on ties, so `.quarter` wins.
        return order.firstIndex(of: lhs.0)! < order.firstIndex(of: rhs.0)!
      }
      return lhs.1.contrastScore > rhs.1.contrastScore
    }

    let chosen = ranked.first?.1 ?? quarter
    let runnerUp = ranked.count >= 2 ? ranked[1].1 : chosen
    var scoreByLevel: [MetricalLevel: Float] = [:]
    for (level, candidate) in byLevel {
      scoreByLevel[level] = candidate.contrastScore
    }
    return MetricalLevelSelection(
      chosen: chosen, runnerUp: runnerUp, scoreByLevel: scoreByLevel)
  }
}
