//
//  EnsembleCombiner.swift
//  BoomBoomBoomKit
//
//  Internal namespace housing the DSP+ML ensemble resolution logic.
//

import Foundation

/// Caseless-enum namespace for the post-pipeline DSP+ML ensemble combiner.
///
/// `EnsembleCombiner` is invoked by ``AudioAnalysisService/analyzeBPM(url:options:)``
/// AFTER ``MetadataCorroborator/apply(to:input:)`` returns and after
/// ``MLTechnique/evaluate(trace:)`` runs (or is short-circuited for
/// ``EnsemblePolicy/dspOnly``). It produces the final ``BPMResult`` whose
/// `bpm` and `confidence` flow into ``AudioAnalysisResult``.
///
/// Story 4.4 promoted this namespace from a same-file static helper in
/// ``AudioAnalysisService``. The promotion happened when the body grew past
/// trivial: switching on ``EnsemblePolicy`` plus the two-sentinel sanitization
/// rules from DD #4 made the function complex enough to deserve its own file
/// (parallel to ``MetadataCorroborator`` for the post-corroboration step).
///
/// ## Sanitization rules (two independent sentinels)
///
/// When the policy is ``EnsemblePolicy/mlOnly`` or ``EnsemblePolicy/highestConfidence``
/// AND `mlEvaluation != nil`, the combiner sanitizes the ML values:
///
/// - **bpm sentinel.** Non-finite `bpm` (NaN, ±∞) is treated as a sentinel-abstain:
///   the combiner falls back to ``BPMResult`` from `dspWinner` and emits an
///   ``EnsembleDecision`` with `mlAbstained: true`, `winner: .dsp`. Apple-platform
///   precedent: `FloatingPoint.minimum(_:_:)` returns the non-NaN operand on NaN
///   input. Finite-but-out-of-range `bpm` is silently clamped to `60.0...200.0`
///   (matching the DSP range-normalization in step 9 of the pipeline).
///
/// - **confidence sentinel** (independent of bpm sentinel). Non-finite
///   `confidence` collapses to `0.0` — this does NOT abstain on its own; the
///   bpm may still be valid. Under ``EnsemblePolicy/highestConfidence`` the
///   collapsed value loses any tie-break against DSP (since DSP confidence is
///   ≥ 0.0); under ``EnsemblePolicy/mlOnly`` the bpm propagates anyway.
///   Finite-but-out-of-range `confidence` is silently clamped to `0.0...1.0`.
///
/// The two sentinels are independent: `MLEvaluation(bpm: .nan, confidence: 0.5)`
/// abstains; `MLEvaluation(bpm: 128, confidence: .nan)` propagates as
/// `(bpm: 128, confidence: 0.0)`.
///
/// ## Tag-bias caveat (``EnsemblePolicy/highestConfidence``)
///
/// `dspWinner.confidence` may have been boosted by
/// ``MetadataPolicy`` corroboration to the 0.95 ceiling
/// (``MetadataPolicy/maxBoostedConfidence``) before reaching this combiner.
/// Comparing it raw against ML's confidence biases toward DSP on
/// tag-corroborated tracks. Story 4-4 surfaces this risk in DD #6 but does
/// NOT mitigate — revisit after Story 4-5 BNNS ablation per the re-open
/// trigger (DD #6 in the story spec).
///
/// ## EnsembleDecision attachment
///
/// When the combiner consumes a non-nil `mlEvaluation` (regardless of whether
/// ML wins), it attaches an ``EnsembleDecision`` to the returned
/// ``BPMResult/trace`` by copying `dspWinner.trace` to a local `var`,
/// mutating `ensembleDecision`, and constructing the result with the updated
/// trace. The ``AudioAnalysisService/analyzeBPM(url:options:)`` call site
/// does not perform this attachment — it would be impossible from there
/// because ``BPMResult/trace`` is `let`-bound.
///
/// **Population matrix (single rule).** `ensembleDecision != nil` iff
/// ``MLTechnique/evaluate(trace:)`` returned a non-nil ``MLEvaluation``.
/// The rule applies at the combiner output (`combined.trace`); the public
/// ``AudioAnalysisResult/trace`` is independently gated by
/// ``AudioAnalysisService/Options/enableTrace`` and is `nil` when
/// `enableTrace == false`, even if the combiner attached a decision
/// internally.
internal enum EnsembleCombiner {

  /// Combines the post-corroboration DSP winner with an optional ML
  /// evaluation under the supplied policy, producing the final ``BPMResult``.
  ///
  /// - Parameters:
  ///   - dspWinner: Post-corroboration DSP candidate. Its `trace`, when
  ///     non-nil, is copied (value-type) and may be augmented with
  ///     ``EnsembleDecision`` before being returned.
  ///   - mlEvaluation: The ML model's verdict, or `nil` when the model
  ///     abstained at the protocol level (or when ML did not run).
  ///   - policy: The selected ``EnsemblePolicy`` (sourced from
  ///     ``AudioAnalysisService/Options/ensemblePolicy``).
  /// - Returns: A new ``BPMResult`` reflecting the combined decision.
  static func combine(
    dspWinner: BPMResult,
    mlEvaluation: MLEvaluation?,
    policy: EnsemblePolicy
  ) -> BPMResult {
    switch policy {
    case .dspOnly:
      // HALT (b) guard: the .dspOnly branch must not consult `mlEvaluation`
      // for any purpose. Under the analyzeBPM short-circuit `mlEvaluation`
      // is nil; this branch is the second line of defense. No EnsembleDecision
      // is constructed (per the single rule: decision != nil iff evaluate
      // returned non-nil; here evaluate did not run).
      _ = mlEvaluation
      return dspWinner

    case .mlOnly:
      guard let ml = mlEvaluation else {
        // Protocol-level abstain — no decision attached.
        return dspWinner
      }
      // Non-finite bpm → sentinel abstain to DSP.
      guard ml.bpm.isFinite else {
        let decision = EnsembleDecision(
          policy: .mlOnly, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: nil, mlAbstained: true,
          selectedBPM: dspWinner.bpm)
        return attaching(decision: decision, to: dspWinner)
      }
      // Finite-bpm path: clamp range; sanitize confidence independently.
      let clampedBPM = clampBPM(ml.bpm)
      let mlConf = sanitizeConfidence(ml.confidence)
      let decision = EnsembleDecision(
        policy: .mlOnly, winner: .ml,
        dspConfidence: dspWinner.confidence,
        mlConfidence: mlConf, mlAbstained: false,
        selectedBPM: clampedBPM)
      return BPMResult(
        bpm: clampedBPM,
        confidence: mlConf,
        candidates: dspWinner.candidates,
        trace: traceWith(decision: decision, base: dspWinner.trace))

    case .highestConfidence:
      guard let ml = mlEvaluation else {
        return dspWinner
      }
      // Sentinel abstain on non-finite bpm — DSP wins.
      guard ml.bpm.isFinite else {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: nil, mlAbstained: true,
          selectedBPM: dspWinner.bpm)
        return attaching(decision: decision, to: dspWinner)
      }
      let clampedBPM = clampBPM(ml.bpm)
      let mlConf = sanitizeConfidence(ml.confidence)
      // Compare confidences. DSP wins ties (deterministic tiebreak).
      // Tag-bias caveat (DD #6): dspWinner.confidence may already be boosted
      // by MetadataCorroborator to the 0.95 ceiling — see type docs.
      if mlConf > dspWinner.confidence {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .ml,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: clampedBPM)
        return BPMResult(
          bpm: clampedBPM,
          confidence: mlConf,
          candidates: dspWinner.candidates,
          trace: traceWith(decision: decision, base: dspWinner.trace))
      } else if mlConf == dspWinner.confidence {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .tie,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: dspWinner.bpm)
        return attaching(decision: decision, to: dspWinner)
      } else {
        let decision = EnsembleDecision(
          policy: .highestConfidence, winner: .dsp,
          dspConfidence: dspWinner.confidence,
          mlConfidence: mlConf, mlAbstained: false,
          selectedBPM: dspWinner.bpm)
        return attaching(decision: decision, to: dspWinner)
      }
    }
  }

  // MARK: - Sanitization helpers

  /// Clamp a finite ML `bpm` to the DSP range-normalization window
  /// `60.0...200.0`. Caller has already verified `bpm.isFinite`; this helper
  /// is a pure clamp.
  private static func clampBPM(_ bpm: Double) -> Double {
    min(max(bpm, 60.0), 200.0)
  }

  /// Two-step confidence sanitization: non-finite collapses to `0.0`,
  /// finite-but-out-of-range clamps to `0.0...1.0`.
  private static func sanitizeConfidence(_ c: Double) -> Double {
    guard c.isFinite else { return 0.0 }
    return min(max(c, 0.0), 1.0)
  }

  // MARK: - Trace attachment

  /// Returns `dspWinner` with the supplied decision attached to its trace.
  /// `dspWinner.bpm`, `dspWinner.confidence`, and `dspWinner.candidates` are
  /// preserved unchanged — only the trace is modified.
  private static func attaching(
    decision: EnsembleDecision, to dspWinner: BPMResult
  ) -> BPMResult {
    BPMResult(
      bpm: dspWinner.bpm,
      confidence: dspWinner.confidence,
      candidates: dspWinner.candidates,
      trace: traceWith(decision: decision, base: dspWinner.trace))
  }

  /// Returns a copy of `base` with `ensembleDecision` set, or `nil` when
  /// `base` is `nil` (no trace was built — nothing to attach to).
  private static func traceWith(
    decision: EnsembleDecision, base: BPMDiagnosticTrace?
  ) -> BPMDiagnosticTrace? {
    guard var updated = base else { return nil }
    updated.ensembleDecision = decision
    return updated
  }
}
