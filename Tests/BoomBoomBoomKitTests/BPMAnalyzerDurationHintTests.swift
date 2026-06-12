//
//  BPMAnalyzerDurationHintTests.swift
//  BoomBoomBoomKitTests
//
//  Story 3-4: Duration-Derived BPM Hint helper tests.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Helper Unit Tests (AC #6, #7)

@Suite("DurationHint — Helper")
struct DurationHintHelperTests {

  // AC #6a: All candidates exactly match a bar count → all get boosted.
  @Test("boosts all matching candidates by exactly 1.1x at 240s")
  func durationHintBoostsAllMatchingCandidates() {
    let candidates: [(bpm: Double, score: Float)] = [
      (128.0, 1.0), (64.0, 1.0), (96.0, 1.0),
    ]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, trace: &trace)

    #expect(result.count == 3)
    // Tiebreaker on original index when scores are equal — preserves input order.
    #expect(result[0].bpm == 128.0)
    #expect(abs(result[0].score - 1.1) < 1e-6)
    #expect(result[1].bpm == 64.0)
    #expect(abs(result[1].score - 1.1) < 1e-6)
    #expect(result[2].bpm == 96.0)
    #expect(abs(result[2].score - 1.1) < 1e-6)

    let detail = try? #require(trace?.durationHintDetail)
    #expect(detail?.fileDurationSeconds == 240.0)
    let boosted = detail?.boostedCandidates ?? []
    #expect(boosted.contains(128.0))
    #expect(boosted.contains(64.0))
    #expect(boosted.contains(96.0))
  }

  // AC #6b: No candidate within 2% of any in-range bar BPM → no boost.
  @Test("no boost when no candidate matches any bar BPM at 240s")
  func durationHintNoBoostWhenNoMatch() {
    let candidates: [(bpm: Double, score: Float)] = [
      (100.0, 1.0), (110.0, 1.0),
    ]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, trace: &trace)

    #expect(result.count == 2)
    #expect(abs(result[0].score - 1.0) < 1e-6)
    #expect(abs(result[1].score - 1.0) < 1e-6)
    #expect(trace?.durationHintDetail?.boostedCandidates.isEmpty == true)
  }

  // AC #6c: Selective boost cannot flip a wide score gap (corroborative-not-authoritative).
  @Test("boost preserves order when score gap is wide (2x) at 240s")
  func durationHintPreservesOrderWhenScoreGapWide() {
    let candidates: [(bpm: Double, score: Float)] = [
      (140.0, 1.0), (128.0, 0.5),
    ]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, trace: &trace)

    // 140 has no in-range bar match. 128 matches 128 bars → 0.55.
    // Order stays [140 (1.0), 128 (0.55)].
    #expect(result.count == 2)
    #expect(result[0].bpm == 140.0)
    #expect(abs(result[0].score - 1.0) < 1e-6)
    #expect(result[1].bpm == 128.0)
    #expect(abs(result[1].score - 0.55) < 1e-6)
  }

  // AC #6d: Boost flips a near-tie (the case where the hint changes the disambiguation pick).
  @Test("boost flips order on near-tie at 240s")
  func durationHintFlipsOrderWhenNearTie() {
    let candidates: [(bpm: Double, score: Float)] = [
      (140.0, 1.0), (128.0, 0.95),
    ]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, trace: &trace)

    // 128 boosted to 0.95 * 1.1 = 1.045 → leapfrogs 140 (1.0).
    #expect(result.count == 2)
    #expect(result[0].bpm == 128.0)
    #expect(abs(result[0].score - 1.045) < 1e-6)
    #expect(result[1].bpm == 140.0)
    #expect(abs(result[1].score - 1.0) < 1e-6)
  }

  // AC #7: applyDurationHintBarCounts behavior across duration regimes.
  // Pass minFileSeconds: 0 so this test exercises the bar-count math itself rather
  // than the threshold gate (which Task 7 added later, default 180s — see
  // `durationHintRespectsThreshold` for the threshold-specific test).
  @Test(
    "bar-count list is correct for various durations",
    arguments: [
      (240.0, [(64, 64.0), (96, 96.0), (128, 128.0), (192, 192.0)]),
      (60.0, [(32, 128.0)]),
      (5.0, [(Int, Double)]()),
    ]
  )
  func durationHintBarCountsForVariousDurations(
    durationSeconds: Double, expected: [(Int, Double)]
  ) {
    let actual = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: durationSeconds, minFileSeconds: 0)
    #expect(actual.count == expected.count)
    for (got, exp) in zip(actual, expected) {
      #expect(got.bars == exp.0)
      #expect(abs(got.bpm - exp.1) < 1e-6)
    }
  }

  // Task 7: threshold gate — durations below `minFileSeconds` produce no bar candidates
  // regardless of the bar-count math. Default 180s skips clips/loops.
  @Test("threshold gate suppresses hint below minFileSeconds")
  func durationHintRespectsThreshold() {
    // Default threshold is 180s. A 60s file is below it.
    let belowDefault = BPMAnalyzer.applyDurationHintBarCounts(durationSeconds: 60.0)
    #expect(belowDefault.isEmpty)

    // A 240s file is above the default threshold and produces normal bar candidates.
    let aboveDefault = BPMAnalyzer.applyDurationHintBarCounts(durationSeconds: 240.0)
    #expect(aboveDefault.count == 4)

    // Custom threshold: 60s file with minFileSeconds=30 → produces candidates.
    let customLow = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: 60.0, minFileSeconds: 30.0)
    #expect(customLow.count == 1)
    #expect(customLow.first?.bars == 32)

    // Custom threshold: 240s file with minFileSeconds=300 → empty (above 240).
    let customHigh = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: 240.0, minFileSeconds: 300.0)
    #expect(customHigh.isEmpty)
  }

  // Task 7: when threshold suppresses bar candidates, applyDurationHint still records
  // a populated trace ("ran but produced nothing") to distinguish from feature-off.
  @Test("threshold suppression populates trace with empty bar/boost lists")
  func durationHintThresholdSuppressionWritesTrace() {
    let candidates: [(bpm: Double, score: Float)] = [(128.0, 1.0)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates,
      fileDurationSeconds: 60.0,  // below default 180
      trace: &trace)

    #expect(result.count == 1)
    #expect(abs(result[0].score - 1.0) < 1e-6)
    let detail = trace?.durationHintDetail
    #expect(detail?.fileDurationSeconds == 60.0)
    #expect(detail?.barCandidates.isEmpty == true)
    #expect(detail?.boostedCandidates.isEmpty == true)
  }

  // AC #3c: helper called with non-empty fileDurationSeconds but bar candidates filter to empty —
  // returns inputs unchanged AND populates all three trace keys with empty strings on the last two.
  // `minFileSeconds: 0` (code-review Patch #8) bypasses Task 7's threshold so the empty
  // bar list comes from the 60..200 BPM range filter (the path AC #3c documents), not
  // from threshold suppression.
  @Test("graceful no-op when all bar candidates filter out (5s clip)")
  func durationHintGracefulNoOpWhenAllBarsFilterOut() {
    let candidates: [(bpm: Double, score: Float)] = [(128.0, 1.0), (64.0, 0.5)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 5.0, minFileSeconds: 0, trace: &trace)

    // Inputs unchanged.
    #expect(result.count == 2)
    #expect(abs(result[0].score - 1.0) < 1e-6)
    #expect(abs(result[1].score - 0.5) < 1e-6)

    let detail = trace?.durationHintDetail
    #expect(detail?.fileDurationSeconds == 5.0)
    #expect(detail?.barCandidates.isEmpty == true)
    #expect(detail?.boostedCandidates.isEmpty == true)
  }

  // MARK: - Code-Review Patch Coverage (Story 3-4)

  // Patch #1: when no candidate matches any bar-count BPM, the helper must return the
  // input array verbatim (not re-sorted by score). Use deliberately unsorted input to
  // make the regression observable.
  @Test("no-match path preserves input order (Patch #1)")
  func durationHintNoMatchPreservesInputOrder() {
    let candidates: [(bpm: Double, score: Float)] = [(100.0, 0.1), (110.0, 0.9)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, minFileSeconds: 0, trace: &trace)

    #expect(result.count == 2)
    #expect(result[0].bpm == 100.0)
    #expect(abs(result[0].score - 0.1) < 1e-6)
    #expect(result[1].bpm == 110.0)
    #expect(abs(result[1].score - 0.9) < 1e-6)

    let detail = trace?.durationHintDetail
    #expect(detail?.boostedCandidates.isEmpty == true)
  }

  // Patch #2: NaN candidate scores would otherwise short-circuit `<` comparisons and
  // bypass the offset tiebreaker, breaking determinism. With the patched comparator,
  // finite scores rank first and the offset tiebreaker resolves non-finite ties.
  @Test("NaN candidate score ranks below finite scores deterministically (Patch #2)")
  func durationHintHandlesNaNCandidateScore() {
    let candidates: [(bpm: Double, score: Float)] = [(128.0, .nan), (140.0, 1.0)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()

    let r1 = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, minFileSeconds: 0, trace: &trace)
    let r2 = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, minFileSeconds: 0, trace: &trace)

    // Finite (140 BPM) ranks first; NaN-score (128 BPM) ranks last.
    #expect(r1.count == 2)
    #expect(r1[0].bpm == 140.0)
    #expect(r1[1].bpm == 128.0)
    // Determinism: identical inputs produce identical orderings.
    #expect(r1[0].bpm == r2[0].bpm)
    #expect(r1[1].bpm == r2[1].bpm)
  }

  // Patch #2: +Inf candidate scores must not break the comparator either. After the
  // boost (cand.score * 1.1) +Inf stays +Inf — the comparator must still resolve it
  // against another +Inf via the offset tiebreaker.
  @Test("infinite candidate score does not break sort tiebreaker (Patch #2)")
  func durationHintHandlesInfiniteCandidateScore() {
    let candidates: [(bpm: Double, score: Float)] = [(128.0, .infinity), (128.0, 1.0)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: 240.0, minFileSeconds: 0, trace: &trace)

    #expect(result.count == 2)
    // +Inf ranks first; offset 1 (the finite boosted 1.0 -> 1.1) ranks second.
    #expect(result[0].score.isInfinite)
    #expect(result[0].bpm == 128.0)
    #expect(abs(result[1].score - 1.1) < 1e-6)
  }

  // Patch #3 + #6: an infinite duration should produce no bar candidates (helper's
  // own finite guard) and consequently take the no-op path that preserves input
  // order (Patch #1). Pairs three patches in one observable test.
  @Test("infinite fileDurationSeconds yields no boost and preserves order (Patches #1, #3, #6)")
  func durationHintHandlesInfiniteFileDuration() {
    let candidates: [(bpm: Double, score: Float)] = [(100.0, 0.2), (140.0, 0.8)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    let result = BPMAnalyzer.applyDurationHint(
      candidates: candidates, fileDurationSeconds: .infinity, minFileSeconds: 0, trace: &trace)

    #expect(result.count == 2)
    #expect(result[0].bpm == 100.0)
    #expect(result[1].bpm == 140.0)

    // Trace still populated (helper ran), but with no bar candidates and no boosts.
    let detail = trace?.durationHintDetail
    #expect(detail?.barCandidates.isEmpty == true)
    #expect(detail?.boostedCandidates.isEmpty == true)
  }

  // Patch #6: NaN threshold falls back to the documented 180s default. At D=300s
  // (above default) the hint runs; at D=60s (below default) it suppresses.
  @Test("NaN minFileSeconds falls back to default 180s threshold (Patch #6)")
  func durationHintNaNThresholdFallsBackToDefault() {
    let above = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: 300.0, minFileSeconds: .nan)
    #expect(above.isEmpty == false)

    let below = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: 60.0, minFileSeconds: .nan)
    #expect(below.isEmpty)
  }

  // Patch #6: negative threshold clamps to 0 (caller intent: "no minimum"). At D=60s
  // the hint runs and produces the in-range bar candidate `[(32, 128.0)]`.
  @Test("negative minFileSeconds clamps to 0 (Patch #6)")
  func durationHintNegativeThresholdClampsToZero() {
    let result = BPMAnalyzer.applyDurationHintBarCounts(
      durationSeconds: 60.0, minFileSeconds: -10.0)
    #expect(result.count == 1)
    #expect(result[0].bars == 32)
    #expect(abs(result[0].bpm - 128.0) < 1e-6)
  }
}

// MARK: - Integration Smoke Tests (Task 3.4)

@Suite("DurationHint — BPMAnalyzer Integration")
struct DurationHintIntegrationTests {

  @Test("BPMAnalyzer.estimateBPM with fileDurationSeconds boosts the matching candidate")
  func bpmAnalyzerWithDurationHintBoostsCorrectCandidate() throws {
    let sampleRate: Double = 44100
    let bpm: Double = 128
    let durationSeconds: Double = 240
    let samples = generateClickTrack(
      bpm: bpm, sampleRate: sampleRate, durationSeconds: durationSeconds)

    var opts = BPMAnalyzer.Options()
    opts.fileDurationSeconds = durationSeconds
    opts.enableTrace = true
    opts.analysisWindowSeconds = 30  // Cap analysis window — file is 240s.

    let result = try #require(
      BPMAnalyzer.estimateBPM(decoded: .synthetic(samples, sampleRate: sampleRate), options: opts))

    // Sanity: detected BPM within 2% of 128.
    #expect(abs(result.bpm - bpm) / bpm < 0.02)

    let detail = try #require(result.trace?.durationHintDetail)
    #expect(detail.fileDurationSeconds == 240.0)
    #expect(detail.barCandidates.contains(where: { $0.bars == 128 && $0.bpm == 128.0 }))
    // Typed `[Double]` membership — exact 128.0 (no precision loss vs. CSV substring).
    #expect(
      detail.boostedCandidates.contains(128.0),
      "expected boostedCandidates to contain 128.0, got: \(detail.boostedCandidates)")
  }

  @Test("BPMAnalyzer.estimateBPM with nil fileDurationSeconds leaves trace.durationHintDetail nil")
  func bpmAnalyzerWithoutDurationHintLeavesTraceNil() throws {
    let sampleRate: Double = 44100
    let samples = generateClickTrack(
      bpm: 128, sampleRate: sampleRate, durationSeconds: 240)

    var opts = BPMAnalyzer.Options()
    opts.enableTrace = true
    opts.analysisWindowSeconds = 30
    // fileDurationSeconds left nil.

    let result = try #require(
      BPMAnalyzer.estimateBPM(decoded: .synthetic(samples, sampleRate: sampleRate), options: opts))

    #expect(result.trace?.durationHintDetail == nil)
  }
}
