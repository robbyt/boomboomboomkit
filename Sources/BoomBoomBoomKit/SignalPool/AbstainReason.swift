//
//  AbstainReason.swift
//  BoomBoomBoomKit
//
//  Reason a signal source declined to participate in the unified pool.
//

public enum AbstainReason: Sendable, Equatable, Codable, DocumentedCase {
  case policyDisabled
  case inputBelowMinimum
  case confidenceBelowFloor
  case sourceSpecific(String)

  // MARK: - DocumentedCase

  /// The documentation catalog subdirectory for this type.
  public static let documentedKind = "AbstainReason"

  /// Per-case documentation filename stem — hand-written (associated-value enum);
  /// payload-ignoring so every `sourceSpecific` string resolves the single
  /// `sourceSpecific.md`.
  public var documentationID: String {
    switch self {
    case .policyDisabled: return "policyDisabled"
    case .inputBelowMinimum: return "inputBelowMinimum"
    case .confidenceBelowFloor: return "confidenceBelowFloor"
    case .sourceSpecific: return "sourceSpecific"
    }
  }
}

extension AbstainReason {
  /// W48 (Story 6.5b): the `.ml` source's pool-construction abstain reason. ML
  /// inference runs POST-selection (preserving the no-accuracy-change ordering),
  /// so at pool-construction time the ML entry is
  /// `.abstained(.sourceSpecific(AbstainReason.mlEvalDeferred))`. Named constant
  /// replacing the bare `"stage1-eval-deferred"` literal (Stage-neutral rename
  /// per 6-3-D1 — the byte→semantic swap un-pins the verbatim-preservation that
  /// kept the old Stage-1 wording).
  public static let mlEvalDeferred = "ml-eval-deferred"

  /// 6-3-D2 (Story 6.5b): emitted for the `.dsp` source when the merged result
  /// carried zero candidates (structurally permitted by `BPMResult.init`), so
  /// the per-source contract still records a `.dsp`-tagged entry.
  public static let noCandidates = "no-candidates"
}
