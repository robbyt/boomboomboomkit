//
//  GenreAccuracyReporterTests.swift
//  BoomBoomBoomKitTests
//
//  Unit tests for the shared genre-stratified accuracy reporter.
//  No corpus env var required — runs under plain `make test`.
//

import BoomBoomBoomKitTestSupport
import Testing

@Suite("GenreAccuracyReporter")
struct GenreAccuracyReporterTests {

  @Test("bucket accessors handle zero total")
  func bucketAccessorsHandleZeroTotal() {
    let b = GenreBucket(genre: "test-genre", total: 0, acc1Correct: 0, acc2Correct: 0)
    #expect(b.acc1Percent == 0)
    #expect(b.acc2Percent == 0)
    #expect(b.isInsufficient == true)
  }

  @Test("isInsufficient boundary at and below five tracks")
  func isInsufficientAtAndBelowFiveTracks() {
    let four = GenreBucket(genre: "g", total: 4, acc1Correct: 0, acc2Correct: 0)
    let five = GenreBucket(genre: "g", total: 5, acc1Correct: 0, acc2Correct: 0)
    #expect(four.isInsufficient == true)
    #expect(five.isInsufficient == false)
  }

  @Test("format sorts buckets by count descending")
  func formatSortsBucketsByCountDescending() {
    let buckets = [
      GenreBucket(genre: "alpha", total: 10, acc1Correct: 7, acc2Correct: 9),
      GenreBucket(genre: "beta", total: 20, acc1Correct: 14, acc2Correct: 18),
      GenreBucket(genre: "gamma", total: 5, acc1Correct: 3, acc2Correct: 4),
    ]
    let out = GenreAccuracyReporter.format(
      corpusLabel: "Test", intensity: 7, buckets: buckets,
      overallAcc1Percent: 60.0, overallAcc2Percent: 90.0)
    let betaIdx = out.range(of: "beta")!.lowerBound
    let alphaIdx = out.range(of: "alpha")!.lowerBound
    let gammaIdx = out.range(of: "gamma")!.lowerBound
    #expect(betaIdx < alphaIdx)
    #expect(alphaIdx < gammaIdx)
  }

  @Test("format stable tie-break on genre ASCII")
  func formatStableTieBreakOnGenreAscii() {
    let buckets = [
      GenreBucket(genre: "zeta", total: 10, acc1Correct: 5, acc2Correct: 8),
      GenreBucket(genre: "alpha", total: 10, acc1Correct: 5, acc2Correct: 8),
    ]
    let out = GenreAccuracyReporter.format(
      corpusLabel: "Test", intensity: 7, buckets: buckets,
      overallAcc1Percent: 50.0, overallAcc2Percent: 80.0)
    let alphaIdx = out.range(of: "alpha")!.lowerBound
    let zetaIdx = out.range(of: "zeta")!.lowerBound
    #expect(alphaIdx < zetaIdx)
  }

  @Test("format renders insufficient rows")
  func formatRendersInsufficientRows() {
    let buckets = [
      GenreBucket(genre: "tiny", total: 2, acc1Correct: 0, acc2Correct: 0)
    ]
    let out = GenreAccuracyReporter.format(
      corpusLabel: "Test", intensity: 7, buckets: buckets,
      overallAcc1Percent: 80.0, overallAcc2Percent: 90.0)
    #expect(out.contains("insufficient"))
    #expect(!out.contains("** LOW **"))
  }

  @Test("isSignificantlyLower is absolute percentage points")
  func isSignificantlyLowerIsAbsolutePercentagePoints() {
    #expect(
      GenreAccuracyReporter.isSignificantlyLower(
        bucketAcc1Percent: 69.9, overallAcc1Percent: 80.0) == true)
    #expect(
      GenreAccuracyReporter.isSignificantlyLower(
        bucketAcc1Percent: 70.1, overallAcc1Percent: 80.0) == false)
    // Boundary: exactly 10pp below → true (>= operator)
    #expect(
      GenreAccuracyReporter.isSignificantlyLower(
        bucketAcc1Percent: 70.0, overallAcc1Percent: 80.0) == true)
  }

  @Test("format marks low buckets only when sample size is sufficient")
  func formatMarksLowBucketsOnlyWhenSampleSizeIsSufficient() {
    // Bucket A: 20 tracks, 10 correct = 50% (30pp below aggregate 80%) — should flag
    // Bucket B: 3 tracks, 0 correct = would be 0% but tiny → insufficient, no LOW marker
    let buckets = [
      GenreBucket(genre: "big-bad", total: 20, acc1Correct: 10, acc2Correct: 15),
      GenreBucket(genre: "tiny-bad", total: 3, acc1Correct: 0, acc2Correct: 0),
    ]
    let out = GenreAccuracyReporter.format(
      corpusLabel: "Test", intensity: 7, buckets: buckets,
      overallAcc1Percent: 80.0, overallAcc2Percent: 90.0)

    // big-bad row should have ** LOW ** marker
    let bigLine = out.split(separator: "\n").first { $0.contains("big-bad") }
    #expect(bigLine != nil)
    #expect(bigLine!.contains("** LOW **"))

    // tiny-bad row should contain "insufficient" and NOT "** LOW **"
    let tinyLine = out.split(separator: "\n").first { $0.contains("tiny-bad") }
    #expect(tinyLine != nil)
    #expect(tinyLine!.contains("insufficient"))
    #expect(!tinyLine!.contains("** LOW **"))
  }

  @Test("format empty buckets produces header and overall only")
  func formatEmptyBucketsProducesHeaderAndOverallOnly() {
    let out = GenreAccuracyReporter.format(
      corpusLabel: "Test", intensity: 7, buckets: [],
      overallAcc1Percent: 0.0, overallAcc2Percent: 0.0)
    #expect(out.contains("=== Test Genre-Stratified Accuracy"))
    #expect(out.contains("Overall: Acc1=0.0%, Acc2=0.0%"))
    // No data rows: no "insufficient" and no "** LOW **"
    #expect(!out.contains("insufficient"))
    #expect(!out.contains("** LOW **"))
  }
}
