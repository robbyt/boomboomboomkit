//
//  AccuracyForensicsTests.swift
//  BoomBoomBoomKitTests
//
//  Pure value-type unit tests for the Phase 0 forensic model (no corpus / no audio).
//  Locks the candidate-recall score-margin semantics (signed, against the SELECTED
//  winner not `candidates[0]`), deterministic detail ordering, the tempo error-type
//  classifier (octave vs triplet kept separate), and dual-truth (GiantSteps `tempo2`)
//  recall. Runs under `make test`.
//

import BoomBoomBoomKitTestSupport
import Testing

@Suite("AccuracyForensics")
struct AccuracyForensicsUnitTests {

  private static let tol = AccuracyForensics.tolerance

  private static func input(
    id: String, expected: Double, alternate: Double? = nil, detected: Double?,
    candidates: [(bpm: Double, score: Float)] = [], isMetronomic: Bool = false
  ) -> ForensicInput {
    ForensicInput(
      id: id, genre: "g", expectedBPM: expected, alternateBPM: alternate, detectedBPM: detected,
      confidence: 0.8, candidates: candidates, isMetronomicTruth: isMetronomic)
  }

  // MARK: - Fix 1: scoreMargin vs the SELECTED winner

  /// The true tempo is the top-scored (rank-1) candidate, but the pipeline SELECTED a
  /// lower-scored candidate (disambiguation override). The margin must be the SIGNED
  /// difference winnerScore − oracleScore (negative here), NOT 0.
  @Test func scoreMarginIsSignedAgainstSelectedWinner() {
    let recall = AccuracyForensics.candidateRecall(
      candidates: [(120.0, 0.9), (124.0, 0.7)], truths: [120.0], detectedBPM: 124.0)
    #expect(recall.bestRank == 1)
    #expect(recall.matchedFactor == "1x")
    let margin = recall.scoreMargin
    #expect(margin != nil)
    #expect(abs((margin ?? 0) - (0.7 - 0.9)) < 1e-5)  // ≈ −0.2 (winner scored LOWER than truth)
  }

  /// When the selected BPM corresponds to no candidate within tolerance, the margin is
  /// `nil` (never a `candidates[0]` fallback) — but recall still reports the rank.
  @Test func scoreMarginNilWhenWinnerOffList() {
    let recall = AccuracyForensics.candidateRecall(
      candidates: [(120.0, 0.9), (124.0, 0.7)], truths: [120.0], detectedBPM: 180.0)
    #expect(recall.bestRank == 1)
    #expect(recall.scoreMargin == nil)
  }

  /// Several candidates fall within 2% of the detected BPM → winnerScore is the CLOSEST by
  /// BPM (0.6), not the highest score (0.9). Oracle is a separate low-rank candidate (60).
  @Test func scoreMarginPicksClosestNotHighestScore() {
    let recall = AccuracyForensics.candidateRecall(
      candidates: [(60.0, 0.95), (120.4, 0.6), (119.0, 0.9)], truths: [60.0], detectedBPM: 120.0)
    #expect(recall.bestRank == 1)  // 60 matches truth 60 at 1x
    #expect(abs((recall.scoreMargin ?? 0) - (0.6 - 0.95)) < 1e-5)  // closest 120.4 → 0.6, not 119.0 → 0.9
  }

  // MARK: - Fix 2: deterministic detail ordering

  @Test func detailsAreSortedDeterministicallyById() {
    let a = Self.input(id: "c", expected: 120, detected: 120)
    let b = Self.input(id: "a", expected: 128, detected: 128)
    let c = Self.input(id: "b", expected: 100, detected: 100)
    let r1 = AccuracyForensics.buildReport(corpus: "t", tracks: [a, b, c])
    let r2 = AccuracyForensics.buildReport(corpus: "t", tracks: [c, a, b])
    #expect(r1.details.map(\.id) == ["a", "b", "c"])
    #expect(r1.details.map(\.id) == r2.details.map(\.id))
  }

  // MARK: - Error-type classifier (octave STRICTLY separate from triplet)

  @Test func classifierSeparatesOctaveFromTriplet() {
    let tol = Self.tol
    #expect(classifyTempoError(120, 120, tolerance: tol) == .exact)
    #expect(classifyTempoError(240, 120, tolerance: tol) == .double)
    #expect(classifyTempoError(60, 120, tolerance: tol) == .half)
    #expect(classifyTempoError(360, 120, tolerance: tol) == .triple)
    #expect(classifyTempoError(40, 120, tolerance: tol) == .third)
    #expect(classifyTempoError(180, 120, tolerance: tol) == .threeHalf)  // 1.5× — NOT double/other
    #expect(classifyTempoError(80, 120, tolerance: tol) == .twoThird)
    #expect(classifyTempoError(100, 120, tolerance: tol) == .other)
  }

  // MARK: - Dual-truth (GiantSteps tempo2) recall + accuracy

  /// A candidate (and detection) matching ONLY the alternate annotation counts as
  /// recalled / Acc1-correct, mirroring the canonical `mirexHit`.
  @Test func dualTruthHonorsAlternate() {
    // 128 and 90 are not harmonic relatives, so a 90 match is unambiguously the alternate.
    let recall = AccuracyForensics.candidateRecall(
      candidates: [(90.0, 0.8)], truths: [128.0, 90.0], detectedBPM: 90.0)
    #expect(recall.bestRank == 1)
    #expect(recall.matchedFactor == "1x")
    #expect(recall.matchedTruth == "alternate")

    let report = AccuracyForensics.buildReport(
      corpus: "t",
      tracks: [Self.input(id: "x", expected: 128, alternate: 90, detected: 90)])
    #expect(report.acc1 == 1)
    #expect(report.details.first?.errorCategory == "exact")
  }

  /// When the alternate is an OCTAVE of the primary (tempo2 = 2× primary), a candidate equal
  /// to the alternate must report `matchedFactor == "1x"` / `matchedTruth == "alternate"`,
  /// NOT the primary's `"2x"` — exact matches across all truths beat a harmonic of another.
  @Test func exactAlternateBeatsPrimaryHarmonic() {
    let recall = AccuracyForensics.candidateRecall(
      candidates: [(200.0, 0.7)], truths: [100.0, 200.0], detectedBPM: 200.0)
    #expect(recall.bestRank == 1)
    #expect(recall.matchedFactor == "1x")
    #expect(recall.matchedTruth == "alternate")
  }

  // MARK: - Label policy: hits do not swamp the failure histogram

  /// Acc1 hits (including a metronomic-truth hit) are `acc1-hit`, kept OUT of the per-failure
  /// labels; only misses populate `metronomic-label` / `perceptual-label-suspect` / `ambiguous`.
  @Test func labelHistogramSeparatesHitsFromFailures() {
    let report = AccuracyForensics.buildReport(
      corpus: "t",
      tracks: [
        Self.input(id: "hit1", expected: 120, detected: 120),  // plain Acc1 hit
        Self.input(id: "hit2", expected: 90, detected: 90, isMetronomic: true),  // metronomic hit
        Self.input(id: "miss-oct", expected: 120, detected: 240),  // double → perceptual-suspect
        Self.input(id: "miss-other", expected: 120, detected: 100),  // other → ambiguous
      ])
    #expect(report.acc1 == 2)
    #expect(report.labelPolicyHistogram["acc1-hit"] == 2)  // both hits, incl. the metronomic one
    #expect(report.labelPolicyHistogram["metronomic-label"] == nil)  // no metronomic MISS here
    #expect(report.labelPolicyHistogram["perceptual-label-suspect"] == 1)
    #expect(report.labelPolicyHistogram["ambiguous"] == 1)
  }
}
