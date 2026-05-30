//
//  EnsemblePolicy.swift
//  BoomBoomBoomKit
//
//  Resolution policy for the DSP+ML ensemble combiner.
//

import Foundation

/// Resolution policy controlling how the post-pipeline DSP candidate and an
/// optional ``MLEvaluation`` are combined into the final ``AudioAnalysisResult``.
///
/// `EnsemblePolicy` is consulted by ``AudioAnalysisService/combineEnsemble(dspWinner:mlEvaluation:policy:)``
/// at the post-corroboration stage of the analysis pipeline. The selected
/// policy is configured through ``AudioAnalysisService/Options/ensemblePolicy``,
/// per ADR-11's Options-first public configuration rule. It is NOT a
/// ``DSPTechnique`` (no DSP changes; no expansion of the 256-combo ablation
/// matrix) and NOT a ``BPMSelectionPolicy`` case (still 8 cases). The
/// policy is orthogonal to ``AnalysisIntensity`` — a `.dspOnly` policy is
/// valid at every intensity level, with or without an ``MLTechnique``
/// conformance.
///
/// The default policy ``dspOnly`` produces byte-identical output to Story
/// 4-3's "DSP wins regardless" behavior (`Double.bitPattern` equality on
/// `bpm` / `confidence`, element-wise on `candidates`) — that is the
/// non-regression contract Story 4-4 ships with. ``mlOnly`` and
/// ``highestConfidence`` are opt-in: callers who load an ML model AND want
/// it to influence the final BPM must explicitly set
/// ``AudioAnalysisService/Options/ensemblePolicy`` to one of those cases.
///
/// ## Discussion
///
/// **Tie-breaking.** Under ``highestConfidence``, when DSP and ML self-report
/// the same `confidence`, DSP wins (deterministic). The combiner records the
/// outcome as ``EnsembleDecision/Winner/tie``. There is no random
/// tiebreaker — repeated calls with the same inputs return the same result.
///
/// **Abstention.** ``MLTechnique/evaluate(trace:)`` may return `nil` to
/// abstain (the protocol-level abstain path); in that case the combiner
/// returns the DSP winner unchanged regardless of policy. Independently,
/// the ensemble combiner sanitizes any ``MLEvaluation`` it consumes — non-finite
/// `bpm` (NaN, ±∞) is treated as a sentinel-NaN abstain (combiner falls back
/// to DSP). The Apple-platform precedent for "abstain on NaN" is
/// `FloatingPoint.minimum(_:_:)`, which states *"If one of x or y is NaN,
/// the other is returned."* See ``AudioAnalysisService/combineEnsemble(dspWinner:mlEvaluation:policy:)`` for the full sanitization
/// rules.
///
/// **Byte-identity invariant under `.dspOnly`.** When the selected policy is
/// ``dspOnly``, ``MLTechnique/evaluate(trace:)`` is NOT invoked even if
/// ``AudioAnalysisService/Options/mlTechnique`` is non-nil (operation-inert
/// AND output-inert short-circuit at the call site in
/// ``AudioAnalysisService/analyzeBPM(url:options:)``). The returned
/// ``AudioAnalysisResult`` therefore matches the no-ML pipeline byte-for-byte,
/// and the trace's ML branch is `nil`. This contract is test-locked by
/// `EnsemblePolicyTests::dspOnlyDoesNotInvokeMLTechnique` (Story 4-4 AC #14).
///
/// **Pre-1.0 / no-BC framing.** The case set is intentionally minimal in the
/// initial Story 4-4 release. Stories 4.5 (BNNS) and 4.6 (CoreML) may
/// surface empirical evidence (e.g., ML calibration behavior) that motivates
/// adding cases or flipping the default. Pre-1.0 framing per
/// `_bmad-output/project-context.md` "Public API Discipline (pre-1.0)" means
/// breaking changes (new cases, default flip, threshold-bearing cases via a
/// parallel scalar field on ``AudioAnalysisService/Options``) are explicitly
/// allowed and expected. Downstream consumers should NOT assume the case
/// list is 1.0-stable.
public enum EnsemblePolicy: Sendable, Hashable {

  /// The library's default ensemble resolution. Story 6.5a ships this as a
  /// byte-inert placeholder that resolves to ``dspOnly`` behavior (the DSP
  /// winner carries unchanged; no ML inference); the genuine default-policy
  /// resolution lands in Story 6.5b. NOTE:
  /// ``AudioAnalysisService/Options/ensemblePolicy`` still defaults to
  /// ``dspOnly`` (not this case) to preserve byte-identity.
  case `default`

  /// DSP-only resolution. The DSP winner carries unchanged;
  /// ``MLTechnique/evaluate(trace:)`` is NOT invoked when this policy is
  /// selected (operation-inert AND output-inert per the Story 4-4 short-circuit
  /// at the call site; AC #14 contract). Produces byte-identical output to
  /// Story 4-3's default-DSP-wins behavior under `mlTechnique == nil`.
  case dspOnly

  /// When `mlEvaluation != nil`, returns ML's `bpm` (clamped to `60.0...200.0`;
  /// non-finite abstains to DSP) and `confidence` (clamped to `0.0...1.0`;
  /// non-finite collapses to `0.0`); preserves `dspWinner.candidates`.
  /// **Invariant break:** under this policy, the returned `result.bpm` may
  /// NOT be present in `result.candidates` (which only contains DSP
  /// candidates). Downstream consumers must handle this case. When
  /// `mlEvaluation == nil`, DSP carries unchanged.
  case mlOnly

  /// Picks the candidate with the higher `confidence` when `mlEvaluation != nil`;
  /// ties break to DSP. **Tag-bias caveat:** ``MetadataPolicy`` corroboration
  /// may have boosted `dspWinner.confidence` to the 0.95 ceiling
  /// (``MetadataPolicy/maxBoostedConfidence``) before this comparison,
  /// biasing toward DSP on tag-corroborated tracks (Story 4-4 DD #6;
  /// revisit after Story 4-5 BNNS ablation per the re-open trigger). When
  /// `mlEvaluation == nil`, DSP wins unconditionally.
  case highestConfidence

  /// Per-source weighted voting over the unified signal pool, parameterized by
  /// ``SignalWeights``. Story 6.5a ships this as a byte-inert placeholder
  /// (resolves to ``dspOnly`` behavior; no ML inference); the pool-authoritative
  /// weighted selection that consumes the ``SignalWeights`` lands in Story 6.5b.
  case weightedVoting(SignalWeights)

  /// Whether this policy causes ``MLTechnique/evaluate(trace:)`` to be invoked.
  /// True only for ``mlOnly`` and ``highestConfidence``; ``default``,
  /// ``dspOnly``, and ``weightedVoting(_:)`` are operation-inert (no ML) in the
  /// current release. Replaces the former `policy != .dspOnly` call-site check,
  /// which would have wrongly invoked ML for the new placeholder cases.
  public var invokesMLInference: Bool {
    switch self {
    case .mlOnly, .highestConfidence: return true
    case .default, .dspOnly, .weightedVoting: return false
    }
  }

  /// A stable string key for this policy, for JSON artifacts and trace labels.
  /// Replaces the former `String` raw value (dropped when ``weightedVoting(_:)``
  /// gained an associated value, which makes `RawRepresentable` unsynthesizable).
  /// The key ignores the ``weightedVoting(_:)`` payload.
  public var stableKey: String {
    switch self {
    case .default: return "default"
    case .dspOnly: return "dspOnly"
    case .mlOnly: return "mlOnly"
    case .highestConfidence: return "highestConfidence"
    case .weightedVoting: return "weightedVoting"
    }
  }

  /// A canonical, ordered list of the policy cases — the hand-written stand-in
  /// for `CaseIterable.allCases`, which cannot be synthesized for an enum with
  /// an associated-value case. ``weightedVoting(_:)`` is represented with
  /// ``SignalWeights/default``. Consumed by the benchmark policy sweeps for
  /// stable, reproducible row order.
  public static let allPolicies: [EnsemblePolicy] = [
    .default, .dspOnly, .mlOnly, .highestConfidence, .weightedVoting(.default),
  ]
}
