//
//  DemotionReason.swift
//  BoomBoomBoomKit
//
//  Reason a signal source's contribution was demoted in the unified pool.
//

public enum DemotionReason: Sendable, Equatable, Codable, DocumentedCase {
  case implausibleForContext
  case sourceSpecific(String)

  // MARK: - DocumentedCase

  /// The documentation catalog subdirectory for this type.
  public static let documentedKind = "DemotionReason"

  /// Per-case documentation filename stem — hand-written (associated-value enum);
  /// payload-ignoring so every `sourceSpecific` string resolves the single
  /// `sourceSpecific.md`.
  public var documentationID: String {
    switch self {
    case .implausibleForContext: return "implausibleForContext"
    case .sourceSpecific: return "sourceSpecific"
    }
  }
}
