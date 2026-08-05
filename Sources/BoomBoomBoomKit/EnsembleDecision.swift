//
//  EnsembleDecision.swift
//  BoomBoomBoomKit
//
//  Typed-evidence record of how the DSP+ML ensemble combiner resolved
//  a single ``analyzeBPM`` call.
//

import Foundation

/// Diagnostic record of how ``AudioAnalysisService/combineEnsemble(dspWinner:ml:policy:perceptualWindow:)``
/// reconciled the post-corroboration DSP candidate with the ML technique's
/// invocation outcome.
///
/// `EnsembleDecision` is attached to ``BPMDiagnosticTrace/ensembleDecision``
/// under ``EnsemblePolicy/mlOnly`` and ``EnsemblePolicy/highestConfidence``
/// whenever the ML technique was actually invoked — including when the model
/// abstained by returning `nil` (``AbstainKind/modelAbstained``) or emitted a
/// non-finite sentinel that the combiner rejected
/// (``AbstainKind/nonFiniteBPM`` / ``AbstainKind/nonFiniteConfidence``).
/// The field stays `nil` when ML was never invoked: under
/// ``EnsemblePolicy/dspOnly`` (short-circuited at the call site), when
/// ``AudioAnalysisService/Options/mlTechnique`` is `nil`, or when no trace
/// was built. The weighted policies (``EnsemblePolicy/default`` /
/// ``EnsemblePolicy/weightedVoting(_:)``) record their resolution on
/// ``BPMDiagnosticTrace/ensembleWeightResolution`` instead.
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
/// `Sendable` struct with no `[String: Any]` fields and `Codable`
/// `Winner` / `AbstainKind` enums for JSON serialization.
///
/// **Trace gating.** The rule above describes attachment at the internal
/// ensemble combiner output (`combined.trace`): when a trace exists,
/// `.mlOnly`/`.highestConfidence` record every ML invocation outcome (win,
/// tie, or any abstain kind); a not-invoked outcome attaches nothing. The
/// public ``AudioAnalysisResult/trace`` field is independently gated by
/// ``AudioAnalysisService/Options/enableTrace``: when `enableTrace == false`
/// the public `result.trace` is `nil` regardless of whether the combiner
/// attached a decision internally, so the record is observable only when
/// the trace is surfaced.
///
/// `Hashable` is intentionally NOT conformed: `selectedBPM` and
/// `dspConfidence` carry unsanitized DSP values, so a `Double.nan` landing
/// in either would break the `a == b ⇒ a.hashValue == b.hashValue`
/// invariant. The type has no internal use as a `Set`/`Dictionary` key.
public struct EnsembleDecision: Sendable {

  /// Which side the policy selected for the final BPM/confidence.
  public enum Winner: String, Sendable, Hashable, Codable {
    /// DSP carried unchanged (also covers every abstain case — see
    /// ``EnsembleDecision/abstainKind``).
    case dsp
    /// ML's bpm/confidence (post-sanitization) was selected as the result.
    case ml
    /// Confidences tied under ``EnsemblePolicy/highestConfidence``; DSP
    /// won the deterministic tiebreak.
    case tie
  }

  /// Why the ML side did not produce a usable evaluation, when it didn't.
  ///
  /// Non-`nil` exactly when the decision records an abstain
  /// (``EnsembleDecision/mlAbstained`` is derived from this field). The
  /// kinds are domain outcomes, not Swift representations:
  public enum AbstainKind: String, Sendable, Hashable, Codable {
    /// ``MLTechnique/evaluate(trace:)`` ran and returned `nil` — the
    /// model's documented voluntary abstain path.
    case modelAbstained
    /// The evaluation carried a non-finite `bpm` (NaN, ±∞); the combiner
    /// rejected it as a sentinel. Checked BEFORE the confidence sentinel,
    /// so an evaluation with both fields non-finite records this kind.
    case nonFiniteBPM
    /// The evaluation carried a finite `bpm` but a non-finite
    /// `confidence`; under the decision-recording policies the combiner
    /// treats the evaluation as unusable rather than collapsing the
    /// confidence to `0.0` (GH-167 item 3 re-litigation of the Story 4.4
    /// two-sentinel rule — see `spec-gh-167-item3-ensemble-seam.md`).
    case nonFiniteConfidence
  }

  /// The policy in effect at the time of the decision. Only
  /// ``EnsemblePolicy/mlOnly`` and ``EnsemblePolicy/highestConfidence``
  /// produce decisions (enforced by the initializer).
  public let policy: EnsemblePolicy

  /// Which side the policy selected for the final BPM/confidence.
  public let winner: Winner

  /// `dspWinner.confidence` at the time of the decision (post-corroboration,
  /// pre-clamp by the combiner — the combiner does NOT modify DSP values).
  public let dspConfidence: Double

  /// ML's self-reported confidence after the combiner's sanitization step,
  /// or `nil` exactly when the decision records an abstain
  /// (`abstainKind != nil` — any kind, enforced by the initializer).
  ///
  /// When non-`nil`, the value is in `[0.0, 1.0]`: finite-but-out-of-range
  /// input is silently clamped. Non-finite confidence no longer collapses
  /// to `0.0` on the decision-recording policies — it abstains with
  /// ``AbstainKind/nonFiniteConfidence`` (the weighted policies, which
  /// record ``EnsembleWeightResolution`` instead, keep the collapse-to-zero
  /// vote).
  public let mlConfidence: Double?

  /// The abstain discriminator: `nil` for a contested decision (ML voted),
  /// non-`nil` when the ML side produced no usable evaluation. See
  /// ``AbstainKind`` for the three kinds. `winner` is forced to
  /// ``Winner/dsp`` whenever this is non-`nil`.
  public let abstainKind: AbstainKind?

  /// `true` when the ML side abstained for any reason. Derived from
  /// ``abstainKind`` (`abstainKind != nil`) — the stored field was replaced
  /// by the discriminator in GH-167 item 3 so contradictory states
  /// (`winner == .ml` with `mlAbstained == true`) are unrepresentable.
  public var mlAbstained: Bool { abstainKind != nil }

  /// The bpm written to the returned ``BPMResult`` and surfaced as
  /// ``AudioAnalysisResult/bpm``. Equal to `dspWinner.bpm` when
  /// `winner ∈ {.dsp, .tie}` (including every abstain); equal to ML's
  /// octave-folded `bpm` when `winner == .ml` — a finite out-of-range
  /// estimate is folded by factors of 2 into `60.0...200.0` (240 → 120),
  /// never clamped to a fabricated boundary tempo.
  public let selectedBPM: Double

  /// Creates a diagnostic record of an ensemble combiner decision.
  ///
  /// Enforces the population matrix with preconditions:
  /// - `policy` must be ``EnsemblePolicy/mlOnly`` or
  ///   ``EnsemblePolicy/highestConfidence`` (the only decision-producing
  ///   policies — the weighted policies emit ``EnsembleWeightResolution``).
  /// - `mlConfidence == nil` iff `abstainKind != nil` (an abstain carries
  ///   no sanitized confidence; a contested decision always does).
  /// - `abstainKind != nil` forces `winner == .dsp`.
  /// - Under `.mlOnly` a contested decision (`abstainKind == nil`) forces
  ///   `winner == .ml`: the policy either adopts the model's answer or
  ///   abstains, so `.dsp`/`.tie` with a usable evaluation is not a state
  ///   the combiner can produce.
  /// - `winner == .tie` is valid only under `.highestConfidence`
  ///   (implied by the rule above, asserted separately for clarity).
  ///
  /// - Parameters:
  ///   - policy: The ``EnsemblePolicy`` in effect when the decision was made.
  ///   - winner: Which side (``Winner/dsp`` / ``Winner/ml`` / ``Winner/tie``) the policy selected.
  ///   - dspConfidence: The DSP winner's confidence (post-corroboration, pre-clamp).
  ///   - mlConfidence: ML's sanitized confidence (`nil` exactly on abstain).
  ///   - abstainKind: The abstain discriminator (`nil` for a contested decision).
  ///   - selectedBPM: The BPM that was written to ``BPMResult`` and surfaced as
  ///     ``AudioAnalysisResult/bpm``.
  public init(
    policy: EnsemblePolicy,
    winner: Winner,
    dspConfidence: Double,
    mlConfidence: Double?,
    abstainKind: AbstainKind?,
    selectedBPM: Double
  ) {
    precondition(
      policy == .mlOnly || policy == .highestConfidence,
      "EnsembleDecision is produced only under .mlOnly/.highestConfidence")
    precondition(
      (mlConfidence == nil) == (abstainKind != nil),
      "mlConfidence must be nil exactly when abstainKind is non-nil")
    precondition(
      abstainKind == nil || winner == .dsp,
      "an abstain forces winner == .dsp")
    precondition(
      policy != .mlOnly || abstainKind != nil || winner == .ml,
      ".mlOnly either adopts the model's answer (winner == .ml) or abstains")
    precondition(
      winner != .tie || policy == .highestConfidence,
      ".tie is valid only under .highestConfidence")
    self.policy = policy
    self.winner = winner
    self.dspConfidence = dspConfidence
    self.mlConfidence = mlConfidence
    self.abstainKind = abstainKind
    self.selectedBPM = selectedBPM
  }
}
