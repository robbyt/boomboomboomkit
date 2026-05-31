//
//  SignalParticipationTraceEntry.swift
//  BoomBoomBoomKit
//
//  Typed-evidence trace entry recording per-source unified-pool state.
//  Story 6.1 project-local skill exception: this evidence type lives in
//  SignalPool/ rather than colocated with BPMDiagnosticTrace because it is
//  co-owned by UnifiedSignalPool. See `BPMDiagnosticTrace.swift` for the
//  cross-reference MARK.
//

public struct SignalParticipationTraceEntry: Sendable, CustomStringConvertible {
  public let source: SignalSource
  public let participation: SignalParticipation
  public let weight: Double
  public let contribution: Double

  public init(
    source: SignalSource,
    participation: SignalParticipation,
    weight: Double,
    contribution: Double
  ) {
    // W56 (Blind #19 / Copilot PR #17): the entry's `source` is canonical, but a
    // `.present` / `.demoted` participation embeds a `WeightedSignal` that also
    // carries a `source` (kept for Codable provenance in the serialized trace).
    // Enforce agreement at construction so a semantically nonsensical entry — a
    // `.dsp` entry wrapping a `.ml` signal — is unconstructible rather than
    // silently stored. `.absent` / `.abstained` carry no signal, so there is
    // nothing to check.
    switch participation {
    case .present(let signal), .demoted(let signal, _):
      precondition(
        signal.source == source,
        "SignalParticipationTraceEntry.source (\(source.rawValue)) must match the "
          + "embedded WeightedSignal.source (\(signal.source.rawValue))")
    case .absent, .abstained:
      break
    }
    self.source = source
    self.participation = participation
    self.weight = weight
    self.contribution = contribution
  }

  public var description: String {
    "SignalParticipationTraceEntry(source: \(source.rawValue), "
      + "participation: \(participation), weight: \(weight), "
      + "contribution: \(contribution))"
  }
}
