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
public enum OctaveEquivalencePolicy: String, CaseIterable, Sendable, Hashable, DocumentedCase {

  /// The documentation catalog subdirectory for this type.
  public static let documentedKind = "OctaveEquivalencePolicy"

  /// Treat `x`, `2x`, and `x/2` as the same tempo, collapsing octave-related
  /// votes onto the fundamental before selection.
  case collapseToFundamental

  /// Treat octave-related votes as agreeing, but apply a confidence penalty to
  /// the non-fundamental candidate.
  case octaveAwareWithPenalty

  /// Require an exact BPM match within tolerance; octave relationships do not
  /// count as agreement.
  case exactMatchOnly

  /// The default octave-equivalence policy consumed by
  /// ``BPMSelectionPolicy/select(from:weights:equivalence:votingPolicy:votingThreshold:)``.
  /// ``octaveAwareWithPenalty`` mirrors the pre-6.5b corroboration behavior
  /// (octave-related tags corroborate, governed by
  /// ``MetadataPolicy/allowOctaveCorroboration``). Story 6.5b accepts this knob
  /// in the selection signature but does not yet branch on it — the octave-ratio
  /// behavior remains governed by ``MetadataPolicy``; activating the three
  /// distinct policies is a reserved follow-up.
  public static let `default` = OctaveEquivalencePolicy.octaveAwareWithPenalty
}
