//
//  EnsembleDecision.swift
//  BoomBoomBoomKit
//
//  Typed-evidence record of how the DSP+ML ensemble combiner resolved
//  a single ``analyzeBPM`` call.
//

import Foundation

/// Diagnostic record of how ``AudioAnalysisService/combineEnsemble(dspWinner:mlEvaluation:policy:)``
/// reconciled the post-corroboration DSP candidate with an ``MLEvaluation``.
///
/// `EnsembleDecision` is attached to ``BPMDiagnosticTrace/ensembleDecision``
/// when the combiner consumed a non-nil ``MLEvaluation`` (i.e.,
/// ``MLTechnique/evaluate(trace:)`` returned non-nil). Otherwise the field
/// stays `nil` — including under ``EnsemblePolicy/dspOnly`` (where
/// `evaluate` is short-circuited at the call site) and under any policy
/// when the model abstained at the protocol level by returning `nil`.
///
/// Because the trace's existing post-pipeline fields (`confidence`,
/// `disambiguationResult`) are DSP-derived, an ML-driven win
/// (`winner == .ml`) means `result.bpm` no longer matches those DSP fields.
/// `EnsembleDecision` is the single record that makes the trace
/// internally consistent: a future debugger UI (Epic 5) can render
/// "ML promoted DSP's `disambiguationResult.bpm = X` to `Y` under
/// `.highestConfidence`" without contradicting the rest of the trace.
///
/// Per project-context.md "Banned trace-field shapes", this is a named
/// `Sendable` struct with no `[String: Any]` fields and a `Codable`
/// `Winner` enum for JSON serialization.
///
/// **Trace gating.** The single-rule above describes attachment at the
/// internal ensemble combiner output (`combined.trace`). The public
/// ``AudioAnalysisResult/trace`` field is independently gated by
/// ``AudioAnalysisService/Options/enableTrace``: when `enableTrace == false`
/// the public `result.trace` is `nil` regardless of whether the combiner
/// attached a decision internally. Consumers querying
/// `result.trace?.ensembleDecision` therefore see `nil` whenever
/// `enableTrace == false`, which is correct but means the "decision iff
/// `evaluate` returned non-nil" rule is observable only when the trace is
/// surfaced.
///
/// `Hashable` is intentionally NOT conformed: `selectedBPM` and
/// `dspConfidence` carry unsanitized DSP values, so a `Double.nan` landing
/// in either would break the `a == b ⇒ a.hashValue == b.hashValue`
/// invariant. The type has no internal use as a `Set`/`Dictionary` key.
public struct EnsembleDecision: Sendable {

  /// Which side the policy selected for the final BPM/confidence.
  public enum Winner: String, Sendable, Hashable, Codable {
    /// DSP carried unchanged (also covers the `winner == .dsp, mlAbstained == true`
    /// case where ML voted but produced a non-finite bpm sentinel).
    case dsp
    /// ML's bpm/confidence (post-sanitization) was selected as the result.
    case ml
    /// Confidences tied under ``EnsemblePolicy/highestConfidence``; DSP
    /// won the deterministic tiebreak.
    case tie
  }

  /// The policy in effect at the time of the decision.
  public let policy: EnsemblePolicy

  /// Which side the policy selected for the final BPM/confidence.
  public let winner: Winner

  /// `dspWinner.confidence` at the time of the decision (post-corroboration,
  /// pre-clamp by the combiner — the combiner does NOT modify DSP values).
  public let dspConfidence: Double

  /// ML's self-reported confidence after the combiner's sanitization step,
  /// or `nil` only when the bpm-sentinel abstain path fired (`mlAbstained ==
  /// true`).
  ///
  /// When non-`nil`, the value is in `[0.0, 1.0]`:
  /// - finite-but-out-of-range input is silently clamped to `0.0...1.0`;
  /// - non-finite input (NaN, ±∞) is collapsed to `0.0` (NOT `nil`) — the
  ///   bpm may still be valid, so the combiner records the collapsed value
  ///   and lets the policy decide whether ML wins.
  ///
  /// This means `mlConfidence == 0.0` is observable when ML supplied a
  /// non-finite confidence with a finite bpm, while `mlConfidence == nil`
  /// implies ML abstained on the bpm sentinel and the combiner fell back to
  /// DSP.
  public let mlConfidence: Double?

  /// `true` when the combiner's sanitization triggered the bpm-sentinel
  /// abstain (non-finite ML bpm). The combiner falls back to DSP in this
  /// case and `winner` is set to `.dsp`. The decision IS produced (rather
  /// than omitted) so the consumer can distinguish a sentinel-abstain from
  /// a protocol-level abstain (`evaluate` returned `nil` → no decision is
  /// attached at all).
  public let mlAbstained: Bool

  /// The bpm written to the returned ``BPMResult`` and surfaced as
  /// ``AudioAnalysisResult/bpm``. Equal to `dspWinner.bpm` when
  /// `winner ∈ {.dsp, .tie}` or `mlAbstained == true`; equal to ML's
  /// sanitized `bpm` (clamped to `60.0...200.0`) when `winner == .ml`.
  public let selectedBPM: Double

  /// Creates a diagnostic record of an ensemble combiner decision.
  ///
  /// - Parameters:
  ///   - policy: The ``EnsemblePolicy`` in effect when the decision was made.
  ///   - winner: Which side (``Winner/dsp`` / ``Winner/ml`` / ``Winner/tie``) the policy selected.
  ///   - dspConfidence: The DSP winner's confidence (post-corroboration, pre-clamp).
  ///   - mlConfidence: ML's sanitized confidence (`nil` only on the sentinel-NaN
  ///     abstain path where ``mlAbstained`` is `true`).
  ///   - mlAbstained: `true` when the combiner's sanitization step triggered the
  ///     bpm-sentinel abstain path; `winner` is forced to ``Winner/dsp`` in that case.
  ///   - selectedBPM: The BPM that was written to ``BPMResult`` and surfaced as
  ///     ``AudioAnalysisResult/bpm``.
  public init(
    policy: EnsemblePolicy,
    winner: Winner,
    dspConfidence: Double,
    mlConfidence: Double?,
    mlAbstained: Bool,
    selectedBPM: Double
  ) {
    self.policy = policy
    self.winner = winner
    self.dspConfidence = dspConfidence
    self.mlConfidence = mlConfidence
    self.mlAbstained = mlAbstained
    self.selectedBPM = selectedBPM
  }
}
