//
//  EnsembleWeightResolution.swift
//  BoomBoomBoomKit
//
//  Typed-evidence record of a pool-authoritative weighted ensemble resolution
//  (KDD-A5). Emitted on `BPMDiagnosticTrace.ensembleWeightResolution` when the
//  selected `EnsemblePolicy` is `.default` or `.weightedVoting(_:)` and the
//  cross-signal fusion ran.
//

/// Forensic record of a per-source weighted ensemble resolution.
///
/// Emitted by ``AudioAnalysisService`` on
/// ``BPMDiagnosticTrace/ensembleWeightResolution`` when an
/// ``EnsemblePolicy/weightedVoting(_:)`` or ``EnsemblePolicy/default`` policy
/// resolves the final BPM by comparing per-source weighted votes
/// (`effectiveVote = signalConfidence × weights[source]`, KDD-A3). The DSP voice
/// is the single Phase-1-aggregated, Phase-2a-corroborated candidate; the ML
/// voice is present only when a technique ran (``EnsemblePolicy/invokesMLInference``).
///
/// ## NaN safety
/// This type carries unsanitized `Double` votes/BPMs and therefore does NOT
/// conform to `Hashable` (an unguarded `Double.nan` breaks `x == x`
/// reflexivity). It is a one-way value carrier on the trace, never a `Set` /
/// `Dictionary` key — mirroring ``EnsembleDecision`` (Story 6.1 / 6.5a DD #3
/// NaN-Hashable rule).
public struct EnsembleWeightResolution: Sendable, CustomStringConvertible {

  /// Which signal family won the weighted comparison.
  public enum Winner: String, Sendable, Hashable, Codable {
    case dsp
    case ml
    case tie
  }

  /// The policy that drove this resolution (``EnsemblePolicy/stableKey``):
  /// `"default"` or `"weightedVoting"`.
  public let policyKey: String

  /// The per-source weights consulted (the ``EnsemblePolicy/weightedVoting(_:)``
  /// payload, or ``SignalWeights/default`` for ``EnsemblePolicy/default``).
  public let weights: SignalWeights

  /// DSP effective vote: `dspConfidence × weights.dsp`.
  public let dspEffectiveVote: Double

  /// ML effective vote: `mlConfidence × weights.ml`; `nil` when no ML voice
  /// participated (`mlEvaluation == nil`).
  public let mlEffectiveVote: Double?

  /// The winning signal family. `.dsp` on ties (deterministic tiebreak).
  public let winner: Winner

  /// The BPM the resolution selected.
  public let selectedBPM: Double

  public init(
    policyKey: String,
    weights: SignalWeights,
    dspEffectiveVote: Double,
    mlEffectiveVote: Double?,
    winner: Winner,
    selectedBPM: Double
  ) {
    self.policyKey = policyKey
    self.weights = weights
    self.dspEffectiveVote = dspEffectiveVote
    self.mlEffectiveVote = mlEffectiveVote
    self.winner = winner
    self.selectedBPM = selectedBPM
  }

  public var description: String {
    let ml = mlEffectiveVote.map { String($0) } ?? "nil"
    return
      "EnsembleWeightResolution(policy: \(policyKey), winner: \(winner.rawValue), "
      + "dspVote: \(dspEffectiveVote), mlVote: \(ml), selectedBPM: \(selectedBPM))"
  }
}
