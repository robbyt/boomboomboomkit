//
//  EnsembleCombinerTests.swift
//  BoomBoomBoomKitTests
//
//  Unit tests for AudioAnalysisService.combineEnsemble(dspWinner:mlEvaluation:policy:).
//  Story 4.3 shipped the original 4 tests against AudioAnalysisService.combine
//  (default DSP-wins). Story 4.4 promoted the helper to EnsembleCombiner, added
//  the 3-case EnsemblePolicy switch, the two-sentinel sanitization, and the
//  EnsembleDecision attachment to BPMResult.trace. The original 4 tests now
//  exercise the post-Story-4.4 .dspOnly case (semantically equivalent).
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
/// comparison across all 4 unit tests in this file.
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

  /// AC #3 (Story 4.3): when `mlEvaluation == nil`, combine returns the DSP
  /// winner unchanged. Post-Story-4.4 the explicit policy is `.dspOnly`.
  @Test("combine returns DSP winner when mlEvaluation is nil")
  func combineReturnsDSPWinnerWhenMLEvaluationNil() {
    let dsp = makeFixture()
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: nil, policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }

  /// ML agrees with DSP — `.dspOnly` discards the ML evaluation and returns
  /// DSP unchanged. No ``EnsembleDecision`` is attached because under the
  /// production short-circuit `evaluate` would not have been invoked.
  @Test("combine returns DSP winner when mlEvaluation agrees under .dspOnly")
  func combineReturnsDSPWinnerWhenMLEvaluationAgrees() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.85)
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }

  /// ML disagrees with low confidence — `.dspOnly` discards ML; DSP wins.
  @Test("combine returns DSP winner when mlEvaluation disagrees with low confidence under .dspOnly")
  func combineReturnsDSPWinnerWhenMLEvaluationDisagreesLowConf() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let result = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
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
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
    #expect(equalByBitPattern(result, dsp))
    #expect(result.trace?.ensembleDecision == nil)
  }
}

// MARK: - Story 4.4: 3-policies × 4-outcomes matrix (AC #8)

/// Story 4.4 AC #8: 12 `@Test`s covering each cell of the 3 × 4 matrix.
/// Each policy is exercised against four DSP/ML outcome shapes:
///   - `MLNil` — `mlEvaluation == nil` (protocol-level abstain)
///   - `MLAgreesHighConf` — `ml.bpm == dsp.bpm`, `ml.conf > dsp.conf`
///   - `MLDisagreesLowConf` — `ml.bpm != dsp.bpm`, `ml.conf < dsp.conf`
///   - `MLDisagreesHighConf` — `ml.bpm != dsp.bpm`, `ml.conf > dsp.conf`
///
/// Expected outcomes per DD #2:
///   - `.dspOnly` always returns DSP unchanged with no decision attached.
///   - `.mlOnly` returns ML when `ml != nil`; DSP when `ml == nil`.
///   - `.highestConfidence` picks the higher confidence; ties go to DSP.
@Suite("EnsembleCombiner — 3 × 4 policy/outcome matrix (Story 4.4 AC #8)")
struct EnsembleCombinerPolicyMatrixTests {

  // ----- .dspOnly row -----

  @Test("dspOnly + ml=nil → DSP wins, no decision")
  func dspOnly_mlNil() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: nil, policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml agrees high conf → DSP wins, no decision")
  func dspOnly_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7)
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml disagrees low conf → DSP wins, no decision")
  func dspOnly_mlDisagreesLowConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("dspOnly + ml disagrees high conf → DSP wins, no decision")
  func dspOnly_mlDisagreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7)
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .dspOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  // ----- .mlOnly row -----

  @Test("mlOnly + ml=nil → DSP wins (no model verdict), no decision")
  func mlOnly_mlNil() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: nil, policy: .mlOnly)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("mlOnly + ml agrees high conf → ML wins, decision attached")
  func mlOnly_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
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
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
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
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .ml)
  }

  // ----- .highestConfidence row -----

  @Test("highestConfidence + ml=nil → DSP wins, no decision")
  func highestConfidence_mlNil() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: nil, policy: .highestConfidence)
    #expect(equalByBitPattern(r, dsp))
    #expect(r.trace?.ensembleDecision == nil)
  }

  @Test("highestConfidence + ml agrees with higher conf → ML wins, decision .ml")
  func highestConfidence_mlAgreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }

  @Test("highestConfidence + ml disagrees with LOWER conf → DSP wins, decision .dsp")
  func highestConfidence_mlDisagreesLowConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .dsp)
  }

  @Test("highestConfidence + ml disagrees with HIGHER conf → ML wins, decision .ml")
  func highestConfidence_mlDisagreesHighConf() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.7, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.95.bitPattern)
    #expect(r.trace?.ensembleDecision?.winner == .ml)
  }
}

// MARK: - Story 4.4 AC #7: two-sentinel sanitization

/// AC #7: non-finite ML `bpm` triggers an abstain to DSP (with `mlAbstained: true`);
/// finite-but-out-of-range `bpm` clamps to `60.0...200.0`. Confidence sentinel
/// is independent: non-finite collapses to `0.0` (NOT abstain); out-of-range
/// clamps to `0.0...1.0`. Apple-platform precedent for "abstain on NaN" is
/// `FloatingPoint.minimum(_:_:)` which returns the non-NaN operand on NaN input.
@Suite("EnsembleCombiner — sanitization (AC #7)")
struct EnsembleCombinerSanitizationTests {

  @Test("mlOnly + bpm=NaN → DSP wins (abstain), decision .dsp + mlAbstained=true")
  func mlOnly_bpmNaN_abstains() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: .nan, confidence: 0.5)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.mlAbstained == true)
    #expect(d?.mlConfidence == nil)
  }

  @Test("mlOnly + bpm=+Inf → DSP wins (abstain)")
  func mlOnly_bpmPositiveInfinity_abstains() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: .infinity, confidence: 0.5)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.mlAbstained == true)
  }

  @Test("mlOnly + bpm=999 → clamped to 200.0; mlAbstained=false")
  func mlOnly_bpmOutOfRangeHigh_clamps() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 999.0, confidence: 0.8)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 200.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.8.bitPattern)
    #expect(r.trace?.ensembleDecision?.mlAbstained == false)
  }

  @Test("mlOnly + bpm=30 → clamped to 60.0; mlAbstained=false")
  func mlOnly_bpmOutOfRangeLow_clamps() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 30.0, confidence: 0.8)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 60.0.bitPattern)
    #expect(r.trace?.ensembleDecision?.mlAbstained == false)
  }

  @Test("mlOnly + finite bpm + confidence=NaN → bpm propagates, conf collapses to 0.0")
  func mlOnly_confidenceNaN_collapses() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 128.0, confidence: .nan)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 128.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.0.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .ml)
    #expect(d?.mlAbstained == false)
    #expect(d?.mlConfidence == 0.0)
  }

  @Test("highestConfidence + confidence=2.0 → clamped to 1.0; ML wins (1.0 > 0.9)")
  func highestConfidence_confidenceClampHigh() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: 2.0)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .highestConfidence)
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
      dspWinner: dsp, mlEvaluation: ml, policy: .mlOnly)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.mlAbstained == true)
    #expect(d?.mlConfidence == nil)
  }

  /// AC #7 explicit case: finite-but-out-of-range negative confidence.
  /// Symmetric with `highestConfidence_confidenceClampHigh` — the combiner
  /// clamps to `0.0` (not abstain). Under `.highestConfidence` the
  /// clamped-to-zero ML loses against any DSP confidence > 0.0, so DSP
  /// wins; the decision records `mlAbstained == false` because the bpm
  /// itself is finite.
  @Test("highestConfidence + confidence=-1.0 → clamped to 0.0; DSP wins (0.9 > 0.0)")
  func highestConfidence_confidenceClampLow() {
    let dsp = makeFixture(bpm: 120.0, confidence: 0.9, trace: BPMDiagnosticTrace())
    let ml = MLEvaluation(bpm: 60.0, confidence: -1.0)
    let r = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, mlEvaluation: ml, policy: .highestConfidence)
    #expect(r.bpm.bitPattern == 120.0.bitPattern)
    #expect(r.confidence.bitPattern == 0.9.bitPattern)
    let d = r.trace?.ensembleDecision
    #expect(d?.winner == .dsp)
    #expect(d?.mlAbstained == false)
    #expect(d?.mlConfidence == 0.0)
  }
}
