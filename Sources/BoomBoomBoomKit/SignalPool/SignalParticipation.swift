//
//  SignalParticipation.swift
//  BoomBoomBoomKit
//
//  Four-state contract describing how a signal source participated in the
//  unified pool for a single analysis run.
//

public enum SignalParticipation: Sendable, Codable {
  case absent
  case abstained(AbstainReason)
  case demoted(WeightedSignal, reason: DemotionReason)
  case present(WeightedSignal)

  public var confidence: Double {
    switch self {
    case .absent, .abstained:
      return 0.0
    case .present(let signal):
      return signal.confidence
    case .demoted(let signal, _):
      return signal.confidence
    }
  }

  /// The exact operative `Float` candidate-fusion score carried by `.present` /
  /// `.demoted` signals; `nil` for `.absent` / `.abstained` (no signal) and for
  /// signals that never carried a fusion score (e.g. file-metadata presence).
  /// Story 6.5b DD #5(b): mirrors ``confidence`` so the pool-authoritative
  /// `BPMSelectionPolicy.select` Phase 2 can read the exact `Float` off the pool
  /// — no lossy `Double → Float` reconstruction.
  public var score: Float? {
    switch self {
    case .absent, .abstained:
      return nil
    case .present(let signal), .demoted(let signal, _):
      return signal.score
    }
  }
}
