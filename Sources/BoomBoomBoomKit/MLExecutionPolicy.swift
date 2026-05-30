//
//  MLExecutionPolicy.swift
//  BoomBoomBoomKit
//
//  Policy controlling when ML inference runs relative to DSP confidence.
//

import Foundation

/// Controls when the ML model is invoked relative to DSP confidence (FR-11a).
///
/// In Story 6.5a this ships as configurable-but-inert config; the intensity ↔
/// policy override behavior it governs lands in Story 6.5b.
///
/// ## Conformance
/// `Hashable` is intentionally NOT adopted: the `.whenDSPConfidenceBelow(Double)`
/// payload can be non-finite, which would break `Hashable` reflexivity
/// (`Double.nan != Double.nan`). The project's converged rule drops `Hashable`
/// from types carrying unsanitized `Double` payloads (``EnsembleDecision``, the
/// Story 6.1 `SignalParticipation` family). `Equatable` is sufficient for the
/// configuration use case; the threshold is finiteness-guarded where it is
/// consumed (Story 6.5b).
public enum MLExecutionPolicy: Sendable, Equatable {

  /// Never run ML inference.
  case never

  /// Always run ML inference (the final BPM is still subject to ``EnsemblePolicy``).
  case always

  /// Run ML only when the DSP confidence is below the given threshold. The
  /// payload is finiteness-guarded at consumption (Story 6.5b).
  case whenDSPConfidenceBelow(Double)

  /// Default: run ML only when DSP confidence is below `0.85`.
  public static let `default` = MLExecutionPolicy.whenDSPConfidenceBelow(0.85)

  /// Hand-written `Equatable` so reflexivity (`x == x`) holds even for a
  /// non-finite threshold. The synthesized `==` would compare the `Double`
  /// payload with `==`, making `.whenDSPConfidenceBelow(.nan)` non-reflexive
  /// (`NaN != NaN`). Comparing the payload by `bitPattern` restores reflexivity
  /// for every value — the project's NaN-safety discipline applied to
  /// `Equatable`, mirroring why `Hashable` is dropped above.
  public static func == (lhs: MLExecutionPolicy, rhs: MLExecutionPolicy) -> Bool {
    switch (lhs, rhs) {
    case (.never, .never), (.always, .always):
      return true
    case (.whenDSPConfidenceBelow(let a), .whenDSPConfidenceBelow(let b)):
      return a.bitPattern == b.bitPattern
    default:
      return false
    }
  }
}
