//
//  EnsembleCombinerTests.swift
//  BoomBoomBoomKitTests
//
//  Unit tests for AudioAnalysisService.combineEnsemble(dspWinner:ml:policy:).
//  Story 4.3 shipped the original 4 tests against AudioAnalysisService.combine
//  (default DSP-wins). Story 4.4 promoted the helper to EnsembleCombiner, added
//  the 3-case EnsemblePolicy switch, the two-sentinel sanitization, and the
//  EnsembleDecision attachment to BPMResult.trace. GH-167 item 3 replaced the
//  `MLEvaluation?` seam input with the three-state `MLSeamOutcome`, swapped the
//  boundary clamp for an octave fold, made non-finite confidence an abstain on
//  the decision-recording policies, and attached decisions on every invoked
//  outcome (including the model's nil abstain).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Equality helper

/// Compare two `BPMResult`s for byte-identity per the Epic 4 Definition
/// (epics.md:766: `Double.bitPattern` equality on `bpm` and `confidence`,
/// element-wise on `candidates`). `BPMResult` is NOT `Equatable` because its
/// `candidates: [(bpm, score)]` is a labeled-tuple array — `Sendable`
/// structurally per SE-0302, but `Equatable`/`Hashable`/`Codable` synthesis
/// requires nominal types. This free helper centralizes the bit-pattern
/// comparison across the unit tests in this file.
private func equalByBitPattern(_ a: BPMResult, _ b: BPMResult) -> Bool {
  guard a.bpm.bitPattern == b.bpm.bitPattern else { return false }
  guard a.confidence.bitPattern == b.confidence.bitPattern else { return false }
  guard a.candidates.count == b.candidates.count else { return false }
  for (lhs, rhs) in zip(a.candidates, b.candidates) {
    if lhs.bpm.bitPattern != rhs.bpm.bitPattern { return false }
    if lhs.score.bitPattern != rhs.score.bitPattern { return false }
  }
  return true
}

private func makeFixture(
  bpm: Double = 120.0,
  confidence: Double = 0.9,
  candidates: [(bpm: Double, score: Float)] = [(bpm: 120.0, score: 0.9), (bpm: 60.0, score: 0.4)],
  trace: BPMDiagnosticTrace? = nil
) -> BPMResult {
  BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: trace)
}

// MARK: - Suite

@Suite("EnsembleCombiner — .dspOnly default policy (Story 4.3 carried forward)")
struct EnsembleCombinerTests {

  /// AC #3 (Story 4.3): when ML was never invoked, combine returns the DSP
  /// winner unchanged. Post-Story-4.4 the explicit policy is `.dspOnly`;
  /// `.notInvoked` is what production passes here (the short-circuit fires
  /// before `evaluate`).
  @Test("combine returns DSP winner when ML was not invoked")
  func combineReturnsDSPWinnerWhenMLNotInvoked() {
    let dsp = makeFixture()
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .notInvoked, policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }

  /// ML agrees with DSP — `.dspOnly` discards the ML evaluation and returns
  /// DSP unchanged. No ``EnsembleDecision`` is attached. An `.evaluated`
  /// outcome under `.dspOnly` is a DEFENSIVE seam combination (production's
  /// short-circuit always passes `.notInvoked` here) — kept to lock the
  /// HALT-(b) guard against any input.
  @Test("combine returns DSP winner when mlEvaluation agrees under .dspOnly")
  func combineReturnsDSPWinnerWhenMLEvaluationAgrees() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.85)
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }

  /// ML disagrees with low confidence — `.dspOnly` discards ML; DSP wins.
  @Test("combine returns DSP winner when mlEvaluation disagrees with low confidence under .dspOnly")
  func combineReturnsDSPWinnerWhenMLEvaluationDisagreesLowConf() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }

  /// ML disagrees with HIGH confidence — `.dspOnly` STILL returns DSP winner
  /// (the canonical "DSP wins regardless" invariant under `.dspOnly`).
  @Test(
    "combine returns DSP winner when mlEvaluation disagrees with high confidence under .dspOnly")
  func combineReturnsDSPWinnerWhenMLEvaluationDisagreesHighConf() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }
}

// MARK: - Story 4.4: 3-policies × 4-outcomes matrix (AC #8)

/// Story 4.4 AC #8: 12 `@Test`s covering each cell of the 3 × 4 matrix.
/// Each policy is exercised against four DSP/ML outcome shapes:
///   - `MLAbstained` — `evaluate` ran and returned nil (the model's abstain)
///   - `MLAgreesHighConf` — `ml.bpm == dsp.bpm`, `ml.conf > dsp.conf`
///   - `MLDisagreesLowConf` — `ml.bpm != dsp.bpm`, `ml.conf < dsp.conf`
///   - `MLDisagreesHighConf` — `ml.bpm != dsp.bpm`, `ml.conf > dsp.conf`
///
/// Expected outcomes per DD #2 + GH-167 item 3:
///   - `.dspOnly` always returns DSP unchanged with no decision attached.
///   - `.mlOnly` returns ML when a usable evaluation exists; DSP with a
///     `.modelAbstained` decision on the nil abstain.
///   - `.highestConfidence` picks the higher confidence; ties go to DSP;
///     the nil abstain records `.modelAbstained`.
@Suite("EnsembleCombiner — 3 × 4 policy/outcome matrix (Story 4.4 AC #8)")
struct EnsembleCombinerPolicyMatrixTests {

  // ----- .dspOnly row -----

  @Test("dspOnly + ml not invoked → DSP wins, no decision")
  func dspOnly_mlNotInvoked() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .notInvoked, policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml agrees high conf → DSP wins, no decision")
  func dspOnly_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7)
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml disagrees low conf → DSP wins, no decision")
  func dspOnly_mlDisagreesLowConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml disagrees high conf → DSP wins, no decision")
  func dspOnly_mlDisagreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7)
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  // ----- .mlOnly row -----

  /// GH-167 item 3 (#149): the model's nil abstain now leaves a decision
  /// record — previously this path returned bare DSP with nothing attached,
  /// indistinguishable from an ML answer without diagnostics.
  @Test("mlOnly + model abstained (nil) → DSP wins, decision .dsp + .modelAbstained")
  func mlOnly_modelAbstained() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .abstained, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .modelAbstained)
    #expect(d?.mlAbstained == true)
    #expect(d?.mlConfidence == nil)
    #expect(d?.selectedBPM == 120.0)
  }

  @Test("mlOnly + ml agrees high conf → ML wins, decision attached")
  func mlOnly_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.policy == .mlOnly)
    #expect(d?.winner == .ml)
    #expect(d?.mlAbstained == false)
    #expect(d?.selectedBPM == 120.0)
    // 6.4b review: lock candidate-forwarding through `.with` on the ML-win path —
    // candidates must survive byte-identical from the DSP winner (the seam only
    // overrides bpm/confidence/trace, never candidates).
    #expect(r.candidates.count == dsp.candidates.count)
    for (lhs, rhs) in zip(r.candidates, dsp.candidates) {
      #expect(lhs.bpm.bitPattern == rhs.bpm.bitPattern)
      #expect(lhs.score.bitPattern == rhs.score.bitPattern)
    }
  }

  @Test("mlOnly + ml disagrees low conf → ML wins (policy ignores DSP), decision attached")
  func mlOnly_mlDisagreesLowConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.4.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .ml)
    #expect(d?.selectedBPM == 60.0)
  }

  @Test("mlOnly + ml disagrees high conf → ML wins, decision attached")
  func mlOnly_mlDisagreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .ml)
  }

  // ----- .highestConfidence row -----

  @Test("highestConfidence + model abstained (nil) → DSP wins, decision .dsp + .modelAbstained")
  func highestConfidence_modelAbstained() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .abstained, policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.policy == .highestConfidence)
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .modelAbstained)
    #expect(d?.mlConfidence == nil)
    #expect(d?.selectedBPM == 120.0)
  }

  @Test("highestConfidence + ml agrees with higher conf → ML wins, decision .ml")
  func highestConfidence_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }

  @Test("highestConfidence + ml disagrees with LOWER conf → DSP wins, decision .dsp")
  func highestConfidence_mlDisagreesLowConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .dsp)
  }

  @Test("highestConfidence + ml disagrees with HIGHER conf → ML wins, decision .ml")
  func highestConfidence_mlDisagreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }
}

// MARK: - Story 4.4 AC #7 + GH-167 item 3: sentinel sanitization

/// Non-finite ML `bpm` abstains to DSP (`.nonFiniteBPM`); a finite
/// out-of-range `bpm` is octave-FOLDED into `60.0...200.0` (GH-167 item 3 —
/// was a boundary clamp). Non-finite `confidence` abstains too on the
/// decision-recording policies (`.nonFiniteConfidence`); finite
/// out-of-range confidence clamps to `0.0...1.0`. The bpm sentinel is
/// checked first. Apple-platform precedent for "abstain on NaN" is
/// `FloatingPoint.minimum(_:_:)` which returns the non-NaN operand on NaN
/// input.
@Suite("EnsembleCombiner — sanitization (AC #7 + GH-167 item 3)")
struct EnsembleCombinerSanitizationTests {

  @Test("mlOnly + bpm=NaN → DSP wins (abstain), decision .dsp + .nonFiniteBPM")
  func mlOnly_bpmNaN_abstains() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: .nan, confidence: 0.5)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .nonFiniteBPM)
    #expect(d?.mlAbstained == true)
    #expect(d?.mlConfidence == nil)
  }

  @Test("mlOnly + bpm=+Inf → DSP wins (abstain)")
  func mlOnly_bpmPositiveInfinity_abstains() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: .infinity, confidence: 0.5)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.abstainKind == .nonFiniteBPM)
  }

  @Test("mlOnly + bpm=999 → octave-folded to 124.875 (999/8); mlAbstained=false")
  func mlOnly_bpmOutOfRangeHigh_folds() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 999.0, confidence: 0.8)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 124.875.bitPattern)
    #expect(r.confidence.bitPattern == 0.8.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.mlAbstained == false)
    #expect(d?.selectedBPM == 124.875)
  }

  @Test("mlOnly + bpm=30 → octave-folded to 60.0 (exact double); mlAbstained=false")
  func mlOnly_bpmOutOfRangeLow_folds() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 30.0, confidence: 0.8)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.mlAbstained == false)
  }

  /// GH-167 item 3 (#126b): non-finite confidence is an ABSTAIN under the
  /// decision-recording policies — previously it collapsed to 0.0 and ML
  /// still won unconditionally under `.mlOnly` (winner .ml, confidence 0.0).
  /// Parameterized over all three non-finite values: the abstain kind is
  /// named NON-finite, not NaN.
  @Test(
    "mlOnly + finite bpm + non-finite confidence → DSP wins (abstain), .nonFiniteConfidence",
    arguments: [Double.nan, .infinity, -.infinity])
  func mlOnly_nonFiniteConfidence_abstains(conf: Double) {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 128.0, confidence: conf)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .nonFiniteConfidence)
    #expect(d?.mlAbstained == true)
    #expect(d?.mlConfidence == nil)
  }

  /// Same abstain under `.highestConfidence`: a collapsed-to-0 vote would
  /// lose the compare anyway, but the record would then claim ML
  /// participated normally with confidence 0 — the abstain keeps it honest.
  @Test(
    "highestConfidence + finite bpm + non-finite confidence → DSP wins (abstain)",
    arguments: [Double.nan, .infinity, -.infinity])
  func highestConfidence_nonFiniteConfidence_abstains(conf: Double) {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 128.0, confidence: conf)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .nonFiniteConfidence)
    #expect(d?.mlConfidence == nil)
  }

  /// The case that MOTIVATES extending the abstain to `.highestConfidence`:
  /// against a ZERO DSP confidence, the pre-fix collapse-to-0.0 compared
  /// equal and recorded a `.tie` — a record claiming ML participated
  /// normally and drew. Now it records the abstain. The returned
  /// bpm/confidence are the same either way (DSP carries on both paths);
  /// the RECORD is what changes, which is the whole point of the fix.
  @Test("highestConfidence + NaN ML confidence + zero DSP confidence → abstain, NOT .tie")
  func highestConfidence_nonFiniteConfidence_zeroDSP_abstainsNotTie() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.0, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 128.0, confidence: .nan)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.0.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.winner != .tie)
    #expect(d?.abstainKind == .nonFiniteConfidence)
    #expect(d?.mlConfidence == nil)
  }

  /// Sentinel precedence: bpm is checked BEFORE confidence, so an
  /// evaluation with BOTH fields non-finite records `.nonFiniteBPM`.
  @Test("mlOnly + bpm=NaN + confidence=NaN → .nonFiniteBPM (bpm checked first)")
  func mlOnly_bothSentinels_bpmWinsPrecedence() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: .nan, confidence: .nan)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.abstainKind == .nonFiniteBPM)
  }

  @Test("highestConfidence + confidence=2.0 → clamped to 1.0; ML wins (1.0 > 0.9)")
  func highestConfidence_confidenceClampHigh() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 2.0)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 1.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }

  /// AC #7 explicit case: non-finite negative bpm sentinel.
  /// Symmetric with `mlOnly_bpmPositiveInfinity_abstains` — the combiner
  /// must abstain on either ±∞ (and on NaN, covered separately).
  @Test("mlOnly + bpm=-Infinity → DSP wins (abstain)")
  func mlOnly_bpmNegativeInfinity_abstains() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: -.infinity, confidence: 0.5)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.abstainKind == .nonFiniteBPM)
    #expect(d?.mlConfidence == nil)
  }

  /// AC #7 explicit case: finite-but-out-of-range negative confidence.
  /// Symmetric with `highestConfidence_confidenceClampHigh` — the combiner
  /// clamps to `0.0` (a FINITE out-of-range value is meaningfully ordered,
  /// unlike the non-finite sentinels, so it still participates). Under
  /// `.highestConfidence` the clamped-to-zero ML loses against any DSP
  /// confidence > 0.0, so DSP wins; the decision records
  /// `mlAbstained == false` with a non-nil `mlConfidence` — the computed
  /// `mlAbstained` lock for the contested-decision shape.
  @Test("highestConfidence + confidence=-1.0 → clamped to 0.0; DSP wins (0.9 > 0.0)")
  func highestConfidence_confidenceClampLow() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: -1.0)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.mlAbstained == false)
    #expect(d?.abstainKind == nil)
    #expect(d?.mlConfidence == 0.0)
  }
}

// MARK: - GH-167 item 3 (#126a): octave-fold boundaries

/// The fold delegates to `BPMAnalyzer.rangeNormalize`: doubling/halving by
/// factors of 2 into `60.0...200.0`. Boundary behavior is deliberately
/// discontinuous (`200` stays; `200.nextUp` halves to ~100) — these tests
/// lock it consciously rather than leaving it to be discovered later.
/// Every division/multiplication by 2 is exact in binary floating point, so
/// the expectations are exact bit patterns.
@Suite("EnsembleCombiner — octave-fold boundaries (GH-167 item 3)")
struct EnsembleCombinerFoldBoundaryTests {

  @Test("mlOnly + bpm=240 → folded to 120 (one halving), recorded in selectedBPM")
  func fold_240_to_120() {
    let dsp = makeFixture(bpm: 100.0, confidence: 0.5, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 240.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.selectedBPM == 120.0)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }

  @Test("mlOnly + bpm=45 → folded UP to 90 (one doubling), not clamped to 60")
  func fold_45_to_90() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.5, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 45.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .mlOnly)
    #expect(r.bpm.bitPattern == 90.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.selectedBPM == 90.0)
  }

  @Test("boundary: 200 stays 200; 200.nextUp halves; 60.nextDown doubles")
  func fold_boundaryDiscontinuities() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.5, trace: BPMDiagnosticTrace())

    let atCeiling = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(MLEvaluation(bpm: 200.0, confidence: 0.9)),
      policy: .mlOnly)
    #expect(atCeiling.bpm.bitPattern == 200.0.bitPattern)

    let justAbove = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(MLEvaluation(bpm: 200.0.nextUp, confidence: 0.9)),
      policy: .mlOnly)
    #expect(justAbove.bpm.bitPattern == (200.0.nextUp / 2.0).bitPattern)

    let justBelow = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(MLEvaluation(bpm: 60.0.nextDown, confidence: 0.9)),
      policy: .mlOnly)
    #expect(justBelow.bpm.bitPattern == (60.0.nextDown * 2.0).bitPattern)
  }

  /// Finite non-positive input returns `rangeNormalize`'s 60.0 floor — the
  /// same value the old boundary clamp produced, explicitly ACCEPTED as
  /// unchanged behavior in the GH-167 item-3 spec (not silently inherited).
  @Test("non-positive bpm → 60.0 floor (byte-identical to the old clamp)", arguments: [0.0, -5.0])
  func fold_nonPositive_floors(bpm: Double) {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.5, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(MLEvaluation(bpm: bpm, confidence: 0.9)),
      policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }

  /// A positive subnormal passes `rangeNormalize`'s `> 0` guard and is
  /// doubled into range: `Double.leastNonzeroMagnitude` is 2^-1074, so
  /// repeated doubling lands on the first power of two ≥ 60, which is 64.
  @Test("subnormal bpm → doubled into range (lands at 64, finite)")
  func fold_subnormal_doublesIntoRange() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.5, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp,
      ml: .evaluated(MLEvaluation(bpm: .leastNonzeroMagnitude, confidence: 0.9)),
      policy: .mlOnly)
    #expect(r.bpm.isFinite)
    #expect(r.bpm >= 60.0 && r.bpm < 120.0)
    #expect(r.bpm.bitPattern == 64.0.bitPattern)
  }

  /// The third fold call site: `.highestConfidence`'s ML-win branch. Same
  /// helper, but covered explicitly so a future divergence between the
  /// three branches cannot land silently.
  @Test("highestConfidence + ML wins with bpm=240 → folded 120 in result AND decision")
  func fold_underHighestConfidence_whenMLWins() {
    let dsp = makeFixture(bpm: 100.0, confidence: 0.3, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 240.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .ml)
    #expect(d?.selectedBPM == 120.0)
  }

  @Test("weightedVoting + ML wins with bpm=240 → folded 120 in result AND resolution")
  func fold_underWeightedVoting_whenMLWins() {
    let dsp = makeFixture(bpm: 100.0, confidence: 0.3, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 240.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .weightedVoting(.default))
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    let res = r.trace?.ensembleWeightResolution
    #expect(res?.winner == .ml)
    #expect(res?.selectedBPM == 120.0)
  }
}

// MARK: - GH-167 item 3 (#149): invocation-outcome records

@Suite("EnsembleCombiner — invocation-outcome records (GH-167 item 3)")
struct EnsembleCombinerInvocationRecordTests {

  /// `.notInvoked` attaches nothing under any policy — the record exists
  /// only for outcomes where `evaluate(trace:)` actually ran.
  @Test(
    "notInvoked → no decision record",
    arguments: [EnsemblePolicy.dspOnly, .mlOnly, .highestConfidence])
  func notInvoked_leavesNoRecord(policy: EnsemblePolicy) {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .notInvoked, policy: policy)
    #expect(r.trace?.ensembleDecision == nil)
    #expect(equalByBitPattern(r, dsp))
  }

  /// With no trace on the DSP winner there is nothing to attach the record
  /// to: the abstain still falls back to DSP correctly, and the absence of
  /// a decision is the trace-gating behavior, not a policy difference.
  @Test("abstained + nil trace → DSP unchanged, no record (nothing to attach to)")
  func abstained_withNilTrace_noAttachment() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: nil)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .abstained, policy: .mlOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace == nil)
  }
}

// MARK: - GH-167 item 3: weighted-policy zero-vote participation (locked)

/// The Story 4.4 collapse-to-0.0 rule is deliberately KEPT for the weighted
/// policies (task-brief mandate): a non-finite ML confidence becomes a ZERO
/// VOTE that still participates — `mlEffectiveVote == 0` (not nil), and it
/// can tie a zero DSP vote. This is "zero-vote participation", not
/// abstention; the record-level distinction is ledgered as an
/// `EnsembleWeightResolution` enrichment deferral.
@Suite("EnsembleCombiner — weighted zero-vote participation (GH-167 item 3 locks)")
struct EnsembleCombinerWeightedZeroVoteTests {

  /// Both weighted policies are covered explicitly: they share an
  /// implementation branch today, but `.weightedVoting` carries an
  /// associated value and could regress independently in a refactor, and
  /// the frozen requirement names both.
  static let weightedPolicies: [EnsemblePolicy] = [.default, .weightedVoting(.default)]

  @Test(
    "weighted policies + non-finite ML confidence → zero vote loses, mlEffectiveVote == 0 (not nil)",
    arguments: weightedPolicies, [Double.nan, .infinity, -.infinity])
  func weighted_nonFiniteConfidence_zeroVoteLoses(policy: EnsemblePolicy, conf: Double) {
    let dsp = makeFixture(bpm: 128.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 174.0, confidence: conf)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: policy)
    #expect(r.bpm.bitPattern == 128.0.bitPattern)
    let res = r.trace?.ensembleWeightResolution
    #expect(res?.winner == .dsp)
    #expect(res?.mlEffectiveVote == 0.0)
  }

  /// The observable difference between zero-vote participation and a true
  /// abstain: against a zero DSP vote, the zero ML vote TIES (winner
  /// `.tie`, DSP tiebreak carries the bpm) where an abstain would record
  /// `.dsp` with `mlEffectiveVote == nil`.
  @Test(
    "weighted policies + NaN ML confidence + zero DSP confidence → .tie with mlEffectiveVote == 0",
    arguments: weightedPolicies)
  func weighted_nanConfidence_tiesZeroDSPVote(policy: EnsemblePolicy) {
    let dsp = makeFixture(bpm: 128.0, confidence: 0.0, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 174.0, confidence: .nan)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: policy)
    #expect(r.bpm.bitPattern == 128.0.bitPattern)
    let res = r.trace?.ensembleWeightResolution
    #expect(res?.winner == .tie)
    #expect(res?.mlEffectiveVote == 0.0)
  }

  /// Contrast row: the SAME zero-DSP-vote fixture with a true no-ML-voice
  /// outcome records `.dsp` with `mlEffectiveVote == nil` — the shape a
  /// consumer must check to distinguish the two.
  @Test(
    "weighted policies + abstained + zero DSP confidence → .dsp with mlEffectiveVote == nil",
    arguments: weightedPolicies)
  func weighted_abstained_recordsNilVote(policy: EnsemblePolicy) {
    let dsp = makeFixture(bpm: 128.0, confidence: 0.0, trace: BPMDiagnosticTrace())
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .abstained, policy: policy)
    #expect(r.bpm.bitPattern == 128.0.bitPattern)
    let res = r.trace?.ensembleWeightResolution
    #expect(res?.winner == .dsp)
    #expect(res?.mlEffectiveVote == nil)
  }
}
