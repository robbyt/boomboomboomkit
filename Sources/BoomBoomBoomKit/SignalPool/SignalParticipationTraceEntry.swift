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
