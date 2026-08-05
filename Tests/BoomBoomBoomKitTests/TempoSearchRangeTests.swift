//
//  TempoSearchRangeTests.swift
//  BoomBoomBoomKitTests
//
//  Story 12.1 (FR-53) — the two consumer-specifiable tempo pairs: normalization
//  (AC #4, #5), default-path byte-identity (AC #3), and the ensemble octave-fold
//  seam (AC #6).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Window-edge tolerance

/// How far outside a supplied ``PerceptualTempoWindow`` a reported tempo may sit.
///
/// The window is not a hard output clamp. Step 10c (fine-grid refinement) runs AFTER
/// the octave fold and re-fits the winner against a continuous grid bounded by the
/// SCAN range, so a winner sitting on a window edge can be reported slightly outside
/// it, in either direction.
///
/// `0.5` is a MEASURED bound, not a structural one, and the distinction matters. The
/// structural bound is step 10c's `winner +/- 4.0` BPM refinement scan half-width
/// (`BPMAnalyzer.refineCandidates`), so nothing narrower than 4 BPM is guaranteed by
/// construction. What is measured, over the bundled fixtures across twelve windows on
/// 2026-08-02, is far tighter: the largest excursion was 0.304 BPM (`bpm-120-click`
/// reported as 60.304 against a `30...60` window), with 120.00008 against `60...120`
/// and 84.861 against `85...170` next. 0.5 leaves roughly 60% headroom over the worst
/// measured case while still failing loudly if the refit ever moves a winner by a
/// materially larger amount.
///
/// If an assertion using this constant starts failing, RE-MEASURE and restate the
/// bound here; do not widen it blindly, because the whole point of a measured bound is
/// that it detects a change in the refit's behaviour.
enum PerceptualWindowEdge {
  static let toleranceBPM = 0.5
}

// MARK: - Byte-identity helper

/// Byte-identity per the project convention: `Double.bitPattern` on `bpm` and
/// `confidence`, element-wise on `candidates`. Not `==` — `==` would treat `-0.0`
/// and `0.0` as equal and would silently pass a NaN mismatch as a non-match rather
/// than a failure.
private func expectByteIdentical(
  _ actual: AudioAnalysisResult, _ expected: AudioAnalysisResult,
  _ label: String, sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(
    actual.bpm.bitPattern == expected.bpm.bitPattern,
    Comment(rawValue: "\(label): bpm \(actual.bpm) != \(expected.bpm)"),
    sourceLocation: sourceLocation)
  #expect(
    actual.confidence.bitPattern == expected.confidence.bitPattern,
    Comment(rawValue: "\(label): confidence \(actual.confidence) != \(expected.confidence)"),
    sourceLocation: sourceLocation)
  #expect(
    actual.candidates.count == expected.candidates.count,
    Comment(rawValue: "\(label): candidate count"), sourceLocation: sourceLocation)
  for (index, pair) in zip(actual.candidates, expected.candidates).enumerated() {
    #expect(
      pair.0.bpm.bitPattern == pair.1.bpm.bitPattern,
      Comment(rawValue: "\(label): candidate[\(index)].bpm"), sourceLocation: sourceLocation)
    #expect(
      pair.0.score.bitPattern == pair.1.score.bitPattern,
      Comment(rawValue: "\(label): candidate[\(index)].score"), sourceLocation: sourceLocation)
  }
}

// MARK: - Normalization (AC #4, #5)

@Suite("Story 12.1 — TempoScanRange normalization")
struct TempoScanRangeNormalizationTests {

  /// The defaults ARE the pre-story `private static let minBPM` / `maxBPM`. Pinning
  /// them is what makes every byte-identity claim in this story checkable: if these
  /// drift, the pipeline moved even though no consumer changed anything.
  @Test("default is the pre-story 40...250 constant pair")
  func defaultMatchesPreStoryConstants() {
    #expect(TempoScanRange.default.minBPM.bitPattern == (40.0 as Double).bitPattern)
    #expect(TempoScanRange.default.maxBPM.bitPattern == (250.0 as Double).bitPattern)
    #expect(AudioAnalysisService.Options().tempoScanRange == .default)
  }

  /// A well-formed in-envelope range survives untouched — normalization must not
  /// perturb valid input.
  @Test("in-envelope range is preserved verbatim")
  func validRangePreserved() {
    let range = TempoScanRange(minBPM: 90, maxBPM: 180)
    #expect(range.minBPM == 90)
    #expect(range.maxBPM == 180)
  }

  @Test("bounds clamp into the 30...300 envelope")
  func clampsToEnvelope() {
    let low = TempoScanRange(minBPM: 1, maxBPM: 10_000)
    #expect(low.minBPM == 30)
    #expect(low.maxBPM == 300)

    let high = TempoScanRange(minBPM: 5_000, maxBPM: 9_000)
    #expect(high.minBPM == 300 - TempoScanRange.minimumSpanBPM)  // 297
    #expect(high.maxBPM == 300)
  }

  /// The integer candidate grid rounds INWARD, so no generated candidate can sit
  /// outside the range the consumer stated. Truncating both bounds put grid slots
  /// below `minBPM`, which the final `Double` range guard then rejected.
  @Test(
    "the integer grid never escapes the stated range",
    arguments: [
      (40.0, 250.0), (40.7, 249.3), (120.5, 240.0), (30.0, 300.0), (119.5, 240.5),
      (100.001, 103.001), (99.999, 102.999),
    ])
  func integerGridStaysInsideStatedRange(minBPM: Double, maxBPM: Double) {
    let range = TempoScanRange(minBPM: minBPM, maxBPM: maxBPM)
    #expect(Double(range.integerLowerBound) >= range.minBPM)
    #expect(Double(range.integerUpperBound) <= range.maxBPM)
    // And the minimum-span guarantee survives the rounding: three grid slots.
    #expect(range.integerUpperBound - range.integerLowerBound + 1 >= 3)
  }

  /// The default pair is integral, so inward rounding is a no-op there — this is what
  /// keeps the byte-identity claim true after the rounding change.
  @Test("the default range's integer grid is unmoved by the rounding")
  func defaultGridIsUnchanged() {
    #expect(TempoScanRange.default.integerLowerBound == 40)
    #expect(TempoScanRange.default.integerUpperBound == 250)
  }

  /// AC #4: an inverted or degenerate range normalizes; it never throws and never
  /// produces a grid the peak scan cannot index.
  @Test(
    "min >= max widens to the minimum span",
    arguments: [
      (200.0, 100.0), (120.0, 120.0), (120.0, 119.0),
    ])
  func invertedRangeWidens(minBPM: Double, maxBPM: Double) {
    let range = TempoScanRange(minBPM: minBPM, maxBPM: maxBPM)
    #expect(range.minBPM < range.maxBPM)
    #expect(range.maxBPM - range.minBPM >= TempoScanRange.minimumSpanBPM)
    // Inward rounding must still leave at least three grid slots.
    #expect(range.integerUpperBound - range.integerLowerBound + 1 >= 3)
  }

  /// Non-finite input falls back to the per-field default. Checked field-by-field so
  /// a fallback that silently reset BOTH fields would fail.
  @Test(
    "non-finite bounds fall back to the field default",
    arguments: [Double.nan, .infinity, -.infinity, .signalingNaN])
  func nonFiniteFallsBack(sentinel: Double) {
    let badMin = TempoScanRange(minBPM: sentinel, maxBPM: 180)
    #expect(badMin.minBPM == TempoScanRange.defaultMinBPM)
    #expect(badMin.maxBPM == 180)

    let badMax = TempoScanRange(minBPM: 90, maxBPM: sentinel)
    #expect(badMax.minBPM == 90)
    #expect(badMax.maxBPM == TempoScanRange.defaultMaxBPM)

    let bothBad = TempoScanRange(minBPM: sentinel, maxBPM: sentinel)
    #expect(bothBad == .default)
  }

  /// `Hashable` is safe only because NaN cannot survive the initializer — the
  /// `SignalWeights` precedent. This asserts the premise rather than the conclusion.
  @Test("no constructible value carries a non-finite bound")
  func boundsAreAlwaysFinite() {
    for candidate in [Double.nan, .infinity, -.infinity, -5, 0, 1e308] {
      let range = TempoScanRange(minBPM: candidate, maxBPM: candidate)
      #expect(range.minBPM.isFinite)
      #expect(range.maxBPM.isFinite)
    }
  }
}

@Suite("Story 12.1 — PerceptualTempoWindow normalization")
struct PerceptualTempoWindowNormalizationTests {

  @Test("default is the pre-story 60...200 constant pair")
  func defaultMatchesPreStoryConstants() {
    #expect(PerceptualTempoWindow.default.minBPM.bitPattern == (60.0 as Double).bitPattern)
    #expect(PerceptualTempoWindow.default.maxBPM.bitPattern == (200.0 as Double).bitPattern)
    #expect(AudioAnalysisService.Options().perceptualWindow == .default)
  }

  @Test("an at-least-one-octave in-envelope window is preserved verbatim")
  func validWindowPreserved() {
    let window = PerceptualTempoWindow(minBPM: 100, maxBPM: 200)
    #expect(window.minBPM == 100)
    #expect(window.maxBPM == 200)
  }

  @Test("bounds clamp into the 30...300 envelope")
  func clampsToEnvelope() {
    let window = PerceptualTempoWindow(minBPM: 1, maxBPM: 10_000)
    #expect(window.minBPM == 30)
    #expect(window.maxBPM == 300)
    // minBPM cannot exceed half the ceiling, or no octave would fit above it.
    #expect(PerceptualTempoWindow(minBPM: 280, maxBPM: 290).minBPM == 150)
  }

  /// A requested reporting floor above 150 is LOWERED, not honoured — the consumer's
  /// stated minimum is silently moved. That is a real asymmetry with `TempoScanRange`
  /// (whose minimum is honoured to 297) and it is documented on the property rather
  /// than left for a consumer to discover, so it is pinned here too.
  @Test(
    "a requested minimum above 150 is lowered to 150",
    arguments: [
      (160.0, 300.0), (200.0, 300.0), (151.0, 302.0), (299.0, 300.0),
    ])
  func minimumAboveHalfCeilingIsLowered(minBPM: Double, maxBPM: Double) {
    let window = PerceptualTempoWindow(minBPM: minBPM, maxBPM: maxBPM)
    #expect(window.minBPM == 150, "requested \(minBPM) must be lowered to 150")
    #expect(window.minBPM < minBPM, "the request was NOT honoured")
    #expect(window.maxBPM == 300)
    // The lowering exists so the octave invariant survives; check it did its job.
    #expect(window.maxBPM >= 2 * window.minBPM)
  }

  /// The boundary itself: 150 is honoured verbatim, 150.0001 is not.
  @Test("150 is the largest honoured minimum")
  func honouredMinimumBoundary() {
    #expect(PerceptualTempoWindow(minBPM: 150, maxBPM: 300).minBPM == 150)
    #expect(PerceptualTempoWindow(minBPM: 149, maxBPM: 300).minBPM == 149)
    #expect(PerceptualTempoWindow(minBPM: 150.0001, maxBPM: 300).minBPM == 150)
  }

  /// AC #5, the concrete case named in the story: `min 100, max 150` is narrower than
  /// one octave. Left alone, `rangeNormalize(160)` would double nothing, then halve
  /// 160 to 80 — BELOW the stated minimum, silently. The window widens instead.
  @Test("sub-octave window widens so the fold cannot return below the minimum")
  func subOctaveWindowWidens() {
    let window = PerceptualTempoWindow(minBPM: 100, maxBPM: 150)
    #expect(window.minBPM == 100)
    #expect(window.maxBPM == 200, "max must be raised to 2 * min")
    #expect(window.maxBPM >= 2 * window.minBPM)

    let folded = BPMAnalyzer.rangeNormalize(160, window: window)
    #expect(
      folded >= window.minBPM,
      Comment(rawValue: "DD3: fold returned \(folded), below the effective minimum"))
    #expect(folded <= window.maxBPM)
    #expect(folded == 160, "160 already sits inside the widened window")
  }

  /// The invariant must hold for EVERY constructible window, not just the named case.
  @Test(
    "maxBPM >= 2 * minBPM for arbitrary input",
    arguments: [
      (100.0, 150.0), (200.0, 100.0), (120.0, 120.0), (90.0, 91.0),
      (30.0, 30.0), (280.0, 285.0), (150.0, 10.0),
    ])
  func octaveInvariantAlwaysHolds(minBPM: Double, maxBPM: Double) {
    let window = PerceptualTempoWindow(minBPM: minBPM, maxBPM: maxBPM)
    #expect(window.maxBPM >= 2 * window.minBPM)
    // And the fold genuinely lands inside for a spread of inputs.
    for input in [1.0, 45.0, 70.0, 160.0, 320.0, 999.0] {
      let folded = BPMAnalyzer.rangeNormalize(input, window: window)
      #expect(folded >= window.minBPM && folded <= window.maxBPM)
    }
  }

  @Test(
    "non-finite bounds fall back to the field default",
    arguments: [Double.nan, .infinity, -.infinity, .signalingNaN])
  func nonFiniteFallsBack(sentinel: Double) {
    let badMin = PerceptualTempoWindow(minBPM: sentinel, maxBPM: 240)
    #expect(badMin.minBPM == PerceptualTempoWindow.defaultMinBPM)
    #expect(badMin.maxBPM == 240)

    let badMax = PerceptualTempoWindow(minBPM: 80, maxBPM: sentinel)
    #expect(badMax.minBPM == 80)
    #expect(badMax.maxBPM == 200)

    #expect(PerceptualTempoWindow(minBPM: sentinel, maxBPM: sentinel) == .default)
  }

  /// The non-finite guard in `rangeNormalize` returns the window floor, not the
  /// hardcoded 60 it returned before the window became a parameter.
  @Test("non-finite and non-positive input folds to the window floor")
  func degenerateInputReturnsWindowFloor() {
    let window = PerceptualTempoWindow(minBPM: 100, maxBPM: 200)
    for input in [0.0, -1.0, Double.nan, .infinity] {
      #expect(BPMAnalyzer.rangeNormalize(input, window: window) == 100)
    }
  }
}

// MARK: - Default-path byte-identity (AC #3)

@Suite("Story 12.1 — default tempo bounds are byte-identical to the pre-story pipeline")
struct TempoRangeByteIdentityTests {

  /// Fixtures spanning synthetic and real material, slow and fast. Real music is
  /// included deliberately: a synthetic click track exercises far less of the
  /// candidate list than a mastered track does.
  private static let fixtures: [(name: String, ext: String)] = [
    ("bpm-120-click", "wav"),
    ("bpm-170-click", "wav"),
    ("Meta_Man", "mp3"),
    ("Submerged_Lament", "mp3"),
    ("Quantum_Cascade", "mp3"),
  ]

  /// AC #3: the opt-out proof. Default `Options` — where the two new fields are never
  /// touched — must produce the same bytes as `Options` carrying the pre-story
  /// constants written out longhand. Any divergence means the new plumbing perturbed
  /// the pipeline rather than merely parameterizing it.
  @Test("explicit pre-story bounds reproduce default Options byte-for-byte", arguments: fixtures)
  func explicitDefaultsAreByteIdentical(fixture: (name: String, ext: String)) throws {
    let url = try AudioFixtures.url(for: fixture.name, extension: fixture.ext)

    let baseline = try #require(try AudioAnalysisService.analyzeBPM(url: url))

    var explicit = AudioAnalysisService.Options()
    explicit.tempoScanRange = TempoScanRange(minBPM: 40, maxBPM: 250)
    explicit.perceptualWindow = PerceptualTempoWindow(minBPM: 60, maxBPM: 200)
    let restated = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: explicit))

    expectByteIdentical(restated, baseline, "\(fixture.name).\(fixture.ext)")
  }

  /// The same contract one level down, at the analyzer seam that actually consumes
  /// the bounds — so a future service-layer refactor cannot mask a `BPMAnalyzer`
  /// regression behind an unchanged facade.
  @Test("BPMAnalyzer default options reproduce explicit pre-story bounds", arguments: fixtures)
  func analyzerDefaultsAreByteIdentical(fixture: (name: String, ext: String)) throws {
    let url = try AudioFixtures.url(for: fixture.name, extension: fixture.ext)
    let decoded = try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 120)

    let baseline = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: .init()))

    var explicit = BPMAnalyzer.Options()
    explicit.tempoScanRange = TempoScanRange(minBPM: 40, maxBPM: 250)
    explicit.perceptualWindow = PerceptualTempoWindow(minBPM: 60, maxBPM: 200)
    let restated = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: explicit))

    #expect(restated.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(restated.confidence.bitPattern == baseline.confidence.bitPattern)
    try #require(restated.candidates.count == baseline.candidates.count)
    for (lhs, rhs) in zip(restated.candidates, baseline.candidates) {
      #expect(lhs.bpm.bitPattern == rhs.bpm.bitPattern)
      #expect(lhs.score.bitPattern == rhs.score.bitPattern)
    }
  }

  /// The byte-identity tests above are only meaningful if the lever is capable of
  /// moving output at all. Without this, a field wired to nothing would pass every
  /// assertion in this suite.
  ///
  /// Targets `bpm-170-click` deliberately, NOT one of the `AccuracyFloorTests` octave
  /// fixtures. `Meta_Man` was the obvious candidate — its default path reports 182 for
  /// a 92 BPM track — but that 2x is an outstanding defect with a live `withKnownIssue`
  /// ratchet built to announce its fix. Coupling this test to it means the day the fix
  /// lands, a suite that has nothing to do with the octave bug fails: 92 sits inside
  /// `60...120`, so the moved window would stop changing the value and
  /// `baseline.bpm != moved.bpm` would break too. `bpm-170-click` is synthetic and
  /// correct at 170.5, and 170.5 folds to 85.26 under a `60...120` window no matter
  /// what any future octave fix does.
  @Test("a moved perceptual window does change output")
  func leverIsNotInert() throws {
    let url = try AudioFixtures.url(for: "bpm-170-click", extension: "wav")
    let baseline = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    #expect(
      baseline.bpm > 120,
      "fixture premise: a 170 BPM click reports above 120 under the default window")

    var halfTime = AudioAnalysisService.Options()
    halfTime.perceptualWindow = PerceptualTempoWindow(minBPM: 60, maxBPM: 120)
    let moved = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: halfTime))

    let edge = PerceptualWindowEdge.toleranceBPM
    #expect(
      moved.bpm >= 60 - edge, "every reported tempo must sit inside the supplied window")
    #expect(moved.bpm <= 120 + edge)
    #expect(baseline.bpm != moved.bpm)
    // Directional, not merely different: the fold must have HALVED the tempo. A
    // future change that perturbed the value without folding it would pass the
    // inequality above but not this.
    #expect(abs(moved.bpm * 2 - baseline.bpm) <= 1.0)
  }

  /// End-to-end proof of the inward rounding. A fractional scan minimum used to
  /// truncate to the integer BELOW it, so the grid generated candidates the final
  /// `Double` range guard then rejected: `120.5...240` over a 120 BPM click returned
  /// `nil` while `121...240` returned 121. Rounding inward makes the grid a subset of
  /// the stated range, so the fractional case now behaves like the integral one.
  @Test("a fractional scan range still produces a result")
  func fractionalScanRangeIsUsable() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")

    var fractional = AudioAnalysisService.Options()
    fractional.tempoScanRange = TempoScanRange(minBPM: 120.5, maxBPM: 240)
    let fromFractional = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: fractional),
      "a 120.5...240 scan range must not annihilate the result")
    #expect(fromFractional.bpm >= 120.5, "no candidate may sit below the stated minimum")
    #expect(fromFractional.bpm <= 240)

    // It agrees with the integral range whose grid it shares (121...240).
    var integral = AudioAnalysisService.Options()
    integral.tempoScanRange = TempoScanRange(minBPM: 121, maxBPM: 240)
    let fromIntegral = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: integral))
    #expect(fromFractional.bpm.bitPattern == fromIntegral.bpm.bitPattern)

    // The other end: a fractional maximum rounds DOWN, so 40...119.4 shares the
    // 40...119 grid and cannot report above 119.4.
    var fractionalMax = AudioAnalysisService.Options()
    fractionalMax.tempoScanRange = TempoScanRange(minBPM: 40, maxBPM: 119.4)
    let capped = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: fractionalMax))
    #expect(capped.bpm <= 119.4, "no candidate may sit above the stated maximum")
    #expect(capped.bpm >= 40)
  }

  /// Narrowing the SCAN range is a different lever from narrowing the perceptual
  /// window, and the distinction is the whole point of DD1: the scan range bounds
  /// candidate generation, so a winner outside it is rejected outright.
  @Test("a scan range that excludes every folded tempo yields no result")
  func scanRangeDisjointFromWindowReturnsNil() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = AudioAnalysisService.Options()
    options.tempoScanRange = TempoScanRange(minBPM: 30, maxBPM: 50)
    options.perceptualWindow = PerceptualTempoWindow(minBPM: 100, maxBPM: 200)
    #expect(try AudioAnalysisService.analyzeBPM(url: url, options: options) == nil)
  }

  /// The cross-interaction a consumer is most likely to hit, pinned so it stays
  /// documented rather than surprising: moving ONLY `perceptualWindow`, with the scan
  /// range left at its default, can annihilate individual tracks. A `30...60` window
  /// folds `Submerged_Lament` to roughly 35, which the default `40...250` scan range's
  /// final guard rejects. Widening the scan range to cover the window recovers it.
  ///
  /// This is why the cross-interaction warning lives on `PerceptualTempoWindow` and on
  /// `Options.perceptualWindow`, not only on `TempoScanRange` — the perceptual lever
  /// is the one a genre-constrained consumer reaches for.
  @Test("moving only the perceptual window can return nil, and widening the scan fixes it")
  func perceptualWindowAloneCanAnnihilateATrack() throws {
    let url = try AudioFixtures.url(for: "Submerged_Lament", extension: "mp3")

    var windowOnly = AudioAnalysisService.Options()
    windowOnly.metadataPolicy = .disabled
    windowOnly.perceptualWindow = PerceptualTempoWindow(minBPM: 30, maxBPM: 60)
    #expect(
      try AudioAnalysisService.analyzeBPM(url: url, options: windowOnly) == nil,
      "a fold below the default 40 BPM scan floor is rejected by the final range guard")

    var bothMoved = windowOnly
    bothMoved.tempoScanRange = TempoScanRange(minBPM: 30, maxBPM: 250)
    let recovered = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: bothMoved),
      "widening the scan range to cover the window must recover the track")
    let edge = PerceptualWindowEdge.toleranceBPM
    #expect(recovered.bpm >= 30 - edge)
    #expect(recovered.bpm <= 60 + edge)
  }
}

// MARK: - Ensemble octave-fold seam (AC #6, DD2)

@Suite("Story 12.1 — perceptual window is the ensemble octave-fold authority")
struct TempoWindowEnsembleSeamTests {

  private static func dspWinner(bpm: Double = 120.0, confidence: Double = 0.5) -> BPMResult {
    BPMResult(
      bpm: bpm, confidence: confidence,
      candidates: [(bpm: bpm, score: 0.9)], trace: BPMDiagnosticTrace())
  }

  /// DD2: `rangeNormalize` is not private to the DSP spine — `foldEnsembleBPM`
  /// delegates to it for ML winners under `.mlOnly`. A 92 BPM ML winner is INSIDE the
  /// default window and is reported verbatim; under a DnB window it folds to 184.
  @Test(".mlOnly folds the ML winner through the supplied window")
  func mlOnlyFoldUsesWindow() {
    let dsp = Self.dspWinner()
    let ml = AudioAnalysisService.MLSeamOutcome.evaluated(
      MLEvaluation(bpm: 92.0, confidence: 0.9))

    let byDefault = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .mlOnly)
    #expect(byDefault.bpm == 92.0)
    #expect(byDefault.trace?.ensembleDecision?.selectedBPM == 92.0)

    let dnb = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .mlOnly,
      perceptualWindow: PerceptualTempoWindow(minBPM: 100, maxBPM: 200))
    #expect(dnb.bpm == 184.0, "92 must double into a 100...200 window")
    #expect(dnb.trace?.ensembleDecision?.selectedBPM == 184.0)
    #expect(dnb.trace?.ensembleDecision?.winner == .ml)
  }

  /// The same seam under `.highestConfidence`, where the ML side must first win the
  /// confidence comparison before its BPM is folded.
  @Test(".highestConfidence folds the ML winner through the supplied window")
  func highestConfidenceFoldUsesWindow() {
    let dsp = Self.dspWinner(confidence: 0.2)
    let ml = AudioAnalysisService.MLSeamOutcome.evaluated(
      MLEvaluation(bpm: 240.0, confidence: 0.95))

    let byDefault = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .highestConfidence)
    #expect(byDefault.bpm == 120.0, "240 halves into 60...200")

    let slow = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .highestConfidence,
      perceptualWindow: PerceptualTempoWindow(minBPM: 30, maxBPM: 70))
    #expect(slow.bpm == 60.0, "240 halves twice into 30...70")
    #expect(slow.trace?.ensembleDecision?.winner == .ml)
  }

  /// `.dspOnly` (the default policy) never consults the ML outcome, so moving the
  /// window cannot perturb it — the byte-identity contract on the default path holds
  /// at the ensemble seam too.
  @Test(".dspOnly output is window-invariant")
  func dspOnlyIsWindowInvariant() {
    let dsp = Self.dspWinner()
    let ml = AudioAnalysisService.MLSeamOutcome.evaluated(
      MLEvaluation(bpm: 92.0, confidence: 0.99))

    let byDefault = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .dspOnly)
    let moved = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: ml, policy: .dspOnly,
      perceptualWindow: PerceptualTempoWindow(minBPM: 100, maxBPM: 200))
    #expect(byDefault.bpm.bitPattern == moved.bpm.bitPattern)
    #expect(byDefault.confidence.bitPattern == moved.confidence.bitPattern)
  }
}
