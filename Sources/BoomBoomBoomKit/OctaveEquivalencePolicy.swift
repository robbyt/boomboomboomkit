//
//  OctaveEquivalencePolicy.swift
//  BoomBoomBoomKit
//
//  Octave-equivalence policy for cross-signal BPM agreement.
//

import Foundation

/// Controls how octave relationships (half / double tempo) are treated when the
/// unified signal pool compares BPM votes from different signal families.
///
/// In Story 6.5a this ships as configurable-but-inert config: the type is public
/// and `CaseIterable`, but the pool-authoritative selection that consumes it
/// lands in Story 6.5b.
public enum OctaveEquivalencePolicy: String, CaseIterable, Sendable, Hashable {

  /// Treat `x`, `2x`, and `x/2` as the same tempo, collapsing octave-related
  /// votes onto the fundamental before selection.
  case collapseToFundamental

  /// Treat octave-related votes as agreeing, but apply a confidence penalty to
  /// the non-fundamental candidate.
  case octaveAwareWithPenalty

  /// Require an exact BPM match within tolerance; octave relationships do not
  /// count as agreement.
  case exactMatchOnly
}
