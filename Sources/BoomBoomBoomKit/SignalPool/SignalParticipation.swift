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
}
