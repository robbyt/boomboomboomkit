//
//  DownbeatAnalyzerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.5a tests for the conservative fixed-4/4 downbeat-phase estimator
//  (DownbeatAnalyzer) and its wiring through BeatGridAnalyzer / BPMAnalyzer /
//  AudioAnalysisService:
//    (a) kick-on-beat-1 → .detected at the planted phase + gridOrigin .downbeat
//    (b) flat four-on-the-floor → .noneDetected (no phase separation)
//    (c) < 3 bars → .noneDetected
//    (d) detectDownbeats == false → .notAttempted + BPM byte-identical
//    (d′) detectDownbeats == true, estimator abstains → BPM byte-identical
//    (f) backbeat-heavy → snare penalty never promotes a backbeat phase
//    (g) bass-drop → median aggregation rejects the one-bar spike (sum would not)
//    (h) anacrusis → the recurring downbeat wins over a single strong pickup
//    (i) one missing beat (< grid-integrity threshold) → resolves to planted phase
//    (i′) many missing beats (> threshold) → .noneDetected (grid-integrity abstain)
//    (j) sub-threshold timing jitter → still resolves the planted phase (AC3.3)
//    (k) non-zero winner phase → firstDownbeatBeatIndex maps to the right beat
//  plus the AC9 `BeatGrid.with(tempoAgreement:)` schemaVersion-forwarding check.
//
//  The estimator is tested DIRECTLY with fully-controlled synthetic per-band
//  onset envelopes (planted-phase independent ground truth) — the DP tracker is
//  not in the loop, so phase assertions are deterministic. Integration tests
//  (AC5/AC6/d/d′) exercise the real pipeline wiring.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("DownbeatAnalyzerTests")
struct DownbeatAnalyzerTests {

  // MARK: - Synthetic-fixture builder (independent ground truth)

  private static let periodFrames = 50
  private static let hopSize = 441
  private static let sampleRate = 44100.0
  /// 100 Hz onset rate, 50-frame period → 0.5 s/beat → 120 BPM.
  private static let estimatedTempo = 120.0

  /// Builds parallel `(beatFrames, beats, fullBand, subBands)` for `bars` bars of
  /// `beatsPerBar` beats spaced `periodFrames` apart. Each present beat plants its
  /// `heights(bar, phase)` peak into the low band (`subBands[0]`), snare-crack band
  /// (`subBands[2]`), and full band at the beat's frame. `present` may drop a beat
  /// (for the missing-beat tests); dropped beats leave their frame at zero and are
  /// absent from `beats`/`beatFrames`, but the remaining beats keep their absolute
  /// frame positions (so position-quantized phase folding still holds).
  private static func makeFixture(
    bars: Int,
    beatsPerBar: Int = 4,
    heights: (_ bar: Int, _ phase: Int) -> (low: Float, full: Float, crack: Float),
    present: (_ bar: Int, _ phase: Int) -> Bool = { _, _ in true },
    frameJitter: (_ beatIndex: Int) -> Int = { _ in 0 }
  ) -> (beatFrames: [Int], beats: [BeatTimestamp], fullBand: [Float], subBands: [[Float]]) {
    let totalBeats = bars * beatsPerBar
    let length = totalBeats * periodFrames + periodFrames
    var fullBand = [Float](repeating: 0, count: length)
    var low = [Float](repeating: 0, count: length)
    var crack = [Float](repeating: 0, count: length)
    var beatFrames: [Int] = []
    var beats: [BeatTimestamp] = []
    let hopSeconds = Double(hopSize) / sampleRate
    for bar in 0..<bars {
      for phase in 0..<beatsPerBar where present(bar, phase) {
        let beatIndex = bar * beatsPerBar + phase
        let f = beatIndex * periodFrames + frameJitter(beatIndex)
        let h = heights(bar, phase)
        fullBand[f] = h.full
        low[f] = h.low
        crack[f] = h.crack
        beatFrames.append(f)
        beats.append(
          BeatTimestamp(
            presentationTime: Double(f) * hopSeconds,
            confidence: 1.0,
            strength: min(1.0, max(0.0, h.full))))
      }
    }
    let zeros = [Float](repeating: 0, count: length)
    return (beatFrames, beats, fullBand, [low, zeros, crack, zeros])
  }

  /// Runs the estimator over a fixture with the test-standard period/tempo.
  private static func estimate(
    _ fx: (beatFrames: [Int], beats: [BeatTimestamp], fullBand: [Float], subBands: [[Float]])
  ) -> DownbeatAnalyzer.Outcome {
    DownbeatAnalyzer.estimate(
      beatFrames: fx.beatFrames,
      beats: fx.beats,
      fullBand: fx.fullBand,
      subBands: fx.subBands,
      periodFrames: Double(periodFrames),
      estimatedTempo: estimatedTempo)
  }

  // MARK: - AC8(a): kick emphasized on beat 1 → .detected at the planted phase

  @Test func detectsPlantedDownbeatPhase() {
    // Strong kick on phase 0 every bar; weak elsewhere; no snare.
    let fx = Self.makeFixture(bars: 8) { _, phase in
      (low: phase == 0 ? 1.0 : 0.3, full: 1.0, crack: 0)
    }
    guard case .detected(let estimate, let firstIdx) = Self.estimate(fx) else {
      Issue.record("expected .detected for a clean planted downbeat")
      return
    }
    #expect(estimate.phaseIndex == 0)
    #expect(estimate.meter == MeterEstimate(beatsPerBar: 4, source: .assumed))
    #expect(estimate.confidence >= 0.4)
    // First downbeat is the first beat (phase 0 of bar 0).
    #expect(firstIdx == 0)
    // Every detected downbeat is a phase-0 beat → 8 of them (one per bar).
    #expect(estimate.beats.count == 8)
  }

  // MARK: - AC8(b): flat four-on-the-floor → .noneDetected (no separation)

  @Test func flatFourOnTheFloorAbstains() {
    // Identical kick on every beat → all phases tie → margin gate fails.
    let fx = Self.makeFixture(bars: 8) { _, _ in (low: 1.0, full: 1.0, crack: 0) }
    guard case .noneDetected = Self.estimate(fx) else {
      Issue.record("flat four-on-the-floor must abstain (no phase separation)")
      return
    }
  }

  // MARK: - AC8(c): fewer than 3 bars → .noneDetected

  @Test func fewerThanThreeBarsAbstains() {
    let fx = Self.makeFixture(bars: 2) { _, phase in
      (low: phase == 0 ? 1.0 : 0.3, full: 1.0, crack: 0)
    }
    guard case .noneDetected = Self.estimate(fx) else {
      Issue.record("fewer than 3 bars must abstain (insufficient evidence)")
      return
    }
  }

  // MARK: - AC8(f): backbeat-heavy → snare penalty never promotes a backbeat phase

  @Test func backbeatPenaltyNeverPromotesSnarePhase() {
    // Kick strong on phase 0, snare-crack on the backbeat (phases 1 & 3). The
    // −0.25·snareCrack penalty must keep the true kick phase (0) the winner and
    // must NEVER select a snare phase (1 or 3).
    let fx = Self.makeFixture(bars: 8) { _, phase in
      let low: Float = phase == 0 ? 1.0 : 0.3
      let crack: Float = (phase == 1 || phase == 3) ? 1.0 : 0.0
      return (low: low, full: 1.0, crack: crack)
    }
    guard case .detected(let estimate, _) = Self.estimate(fx) else {
      Issue.record("kick-on-1 with backbeat snare should still detect phase 0")
      return
    }
    #expect(estimate.phaseIndex == 0)
    #expect(estimate.phaseIndex != 1)
    #expect(estimate.phaseIndex != 3)

    // Equal kick on every beat + snare backbeat: the penalty lowers phases 1 & 3,
    // leaving phases 0 & 2 tied → abstain (never a backbeat phase).
    let flatKickBackbeat = Self.makeFixture(bars: 8) { _, phase in
      let crack: Float = (phase == 1 || phase == 3) ? 1.0 : 0.0
      return (low: 1.0, full: 1.0, crack: crack)
    }
    guard case .noneDetected = Self.estimate(flatKickBackbeat) else {
      Issue.record("equal kick + backbeat must abstain, never pick a snare phase")
      return
    }
  }

  // MARK: - AC8(g): bass-drop → median aggregation rejects the one-bar spike

  @Test func bassDropRejectedByMedianAggregation() {
    // True downbeat: phase 0 (strong kick + full every bar). One bar's phase-2
    // beat carries a HUGE low+full transient (a bass drop on a non-downbeat).
    // With a raw SUM, phase 2's total would beat phase 0's (fooled); the MEDIAN
    // rejects the single outlier, so phase 0 still wins. The estimator must NOT
    // lock onto phase 2.
    let dropBar = 3
    let fx = Self.makeFixture(bars: 8) { bar, phase in
      if bar == dropBar && phase == 2 { return (low: 10.0, full: 10.0, crack: 0) }
      let strong = phase == 0
      return (low: strong ? 1.0 : 0.1, full: strong ? 1.0 : 0.3, crack: 0)
    }
    guard case .detected(let estimate, _) = Self.estimate(fx) else {
      Issue.record("bass-drop fixture should still detect the recurring phase-0 downbeat")
      return
    }
    #expect(estimate.phaseIndex == 0)
    #expect(estimate.phaseIndex != 2, "median must reject the one-bar bass-drop phase")
  }

  // MARK: - AC8(h): anacrusis → recurring downbeat wins over a single pickup

  @Test func anacrusisDoesNotFoolTheEstimator() {
    // beats[0] is a very strong PICKUP at phase 0; the recurring true downbeat is
    // phase 1 (every bar). The single pickup must not win — the recurring accent
    // (multi-bar support / median) does.
    let fx = Self.makeFixture(bars: 8) { bar, phase in
      let beatIndex = bar * 4 + phase
      if beatIndex == 0 { return (low: 2.0, full: 2.0, crack: 0) }  // pickup
      let recurringDownbeat = phase == 1
      return (low: recurringDownbeat ? 1.0 : 0.2, full: recurringDownbeat ? 1.0 : 0.3, crack: 0)
    }
    guard case .detected(let estimate, _) = Self.estimate(fx) else {
      Issue.record("anacrusis fixture should detect the recurring phase-1 downbeat")
      return
    }
    #expect(estimate.phaseIndex == 1, "the single pickup at phase 0 must not win")
  }

  // MARK: - AC8(i): one missing beat (< grid-integrity threshold) → planted phase

  @Test func oneMissingBeatResolvesToPlantedPhase() {
    // 15 bars (60 beats); drop ONE non-downbeat beat (bar 7, phase 2). That is one
    // off-grid interval out of 58 ≈ 1.7% < 20% → grid-integrity passes, and the
    // position-quantized folding resolves the planted phase-0 downbeat. Assert the
    // single correct outcome (no "OR").
    let fx = Self.makeFixture(
      bars: 15,
      heights: { _, phase in (low: phase == 0 ? 1.0 : 0.3, full: 1.0, crack: 0) },
      present: { bar, phase in !(bar == 7 && phase == 2) })
    guard case .detected(let estimate, _) = Self.estimate(fx) else {
      Issue.record("a single missing beat must not prevent detection")
      return
    }
    #expect(estimate.phaseIndex == 0)
  }

  // MARK: - AC8(i′): many missing beats (> threshold) → grid-integrity abstain

  @Test func manyMissingBeatsTripGridIntegrityAbstain() {
    // Drop every phase-2 beat across 15 bars: each bar then has a 1→3 gap (one
    // off-grid interval per bar). ~15 off-grid of ~44 intervals ≈ 34% > 20% → the
    // grid-integrity guard fires and the estimator abstains, regardless of accent.
    let fx = Self.makeFixture(
      bars: 15,
      heights: { _, phase in (low: phase == 0 ? 1.0 : 0.3, full: 1.0, crack: 0) },
      present: { _, phase in phase != 2 })
    guard case .noneDetected = Self.estimate(fx) else {
      Issue.record("a shredded grid (> 20% off-grid intervals) must abstain")
      return
    }
  }

  // MARK: - AC3.3(j): sub-threshold timing jitter still resolves the planted phase

  @Test func subThresholdJitterResolvesPlantedPhase() {
    // Wobble each beat's frame by a small deterministic offset (|≤ 5| frames = 10%
    // of the 50-frame period; adjacent intervals deviate < 25%, so grid-integrity
    // holds with 0 off-grid intervals). The position-quantized phase fold (AC3.3)
    // must still land on the planted phase-0 downbeat — it folds by quantized
    // POSITION, not raw array index, so a sub-threshold wobble rounds back to phase.
    let jitter = [0, 4, -3, 5, -4, 3, -5, 2]
    let fx = Self.makeFixture(
      bars: 8,
      heights: { _, phase in (low: phase == 0 ? 1.0 : 0.3, full: 1.0, crack: 0) },
      frameJitter: { beatIndex in jitter[beatIndex % jitter.count] })
    guard case .detected(let estimate, let firstIdx) = Self.estimate(fx) else {
      Issue.record("sub-threshold jitter must not prevent detection")
      return
    }
    #expect(estimate.phaseIndex == 0)
    #expect(firstIdx == 0)
  }

  // MARK: - AC3.4/AC5: a non-zero winner phase maps the first-downbeat index

  @Test func nonZeroWinnerPhaseMapsFirstDownbeatIndex() {
    // Strong recurring accent on phase 2 (no pickup, no backbeat) → winner phase 2,
    // first downbeat = the first phase-2 beat (beatIndex 2), downbeats = the 8
    // phase-2 beats. Exercises the firstIdx → downbeat-anchor mapping for a NON-zero
    // phase (most fixtures plant phase 0, so firstIdx == 0 is under-exercised).
    let fx = Self.makeFixture(bars: 8) { _, phase in
      (low: phase == 2 ? 1.0 : 0.3, full: 1.0, crack: 0)
    }
    guard case .detected(let estimate, let firstIdx) = Self.estimate(fx) else {
      Issue.record("a clean phase-2 accent should detect")
      return
    }
    #expect(estimate.phaseIndex == 2)
    #expect(firstIdx == 2)  // bar 0, phase 2
    #expect(estimate.beats.count == 8)  // one phase-2 beat per bar
    // The reported first downbeat is exactly the beat at firstIdx.
    #expect(estimate.beats.first?.presentationTime == fx.beats[firstIdx].presentationTime)
  }

  // MARK: - AC5 / AC6: end-to-end wiring through BeatGridAnalyzer.estimateBeatGrid

  @Test func estimateBeatGridPopulatesDownbeatAndRepointsAnchor() throws {
    // Clean full-band impulses every 50 frames (the DP recovers a beat per impulse)
    // with the low band emphasized on phase-0 frames (every 200). detectDownbeats
    // true → the grid carries .detected and gridOrigin.source == .downbeat, with
    // the first downbeat on a planted phase-0 frame (frame ≡ 0 mod 200).
    let bars = 8
    let beatsPerBar = 4
    let period = 50
    let length = bars * beatsPerBar * period + period
    var fullBand = [Float](repeating: 0, count: length)
    var low = [Float](repeating: 0, count: length)
    let zeros = [Float](repeating: 0, count: length)
    for beatIndex in 0..<(bars * beatsPerBar) {
      let f = beatIndex * period
      fullBand[f] = 1.0
      low[f] = (beatIndex % beatsPerBar == 0) ? 1.0 : 0.25
    }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: fullBand,
        onsetRate: 100.0,
        hopSize: 441,
        sampleRate: 44100.0,
        acf: fullBand,
        tempoBPM: 120.0,
        windowStartSample: 0,
        subBands: [low, zeros, zeros, zeros],
        detectDownbeats: true))

    guard case .detected(let estimate) = grid.downbeats else {
      Issue.record("expected .detected downbeats from the planted phase-0 grid")
      return
    }
    // gridOrigin is repointed to the first downbeat (AC5).
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.source == .downbeat)
    // An auto downbeat anchor is always coupled (non-nil beatIndex).
    let anchorIndex = try #require(anchor.beatIndex)
    #expect(anchor.presentationTime == grid.beats[anchorIndex].presentationTime)
    // Independent ground truth: the first downbeat sits on a planted phase-0 frame
    // (frame ≡ 0 mod 200 → presentationTime a multiple of 2.0 s within one hop).
    let firstDownbeatTime = try #require(estimate.beats.first).presentationTime
    let barSeconds = 60.0 / 120.0 * Double(beatsPerBar)  // 2.0 s
    let nearestBar = (firstDownbeatTime / barSeconds).rounded() * barSeconds
    #expect(abs(firstDownbeatTime - nearestBar) <= Double(441) / 44100.0)
  }

  @Test func abstainPreservesPhaseConsistencyAnchor() throws {
    // Flat impulses (equal low band every beat) → estimator abstains → downbeats
    // .noneDetected AND gridOrigin keeps its Story-8.5 phase-consistency source.
    let bars = 8
    let period = 50
    let length = bars * 4 * period + period
    var fullBand = [Float](repeating: 0, count: length)
    var low = [Float](repeating: 0, count: length)
    let zeros = [Float](repeating: 0, count: length)
    for beatIndex in 0..<(bars * 4) {
      let f = beatIndex * period
      fullBand[f] = 1.0
      low[f] = 1.0  // equal on every beat → no phase separation
    }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: fullBand, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: fullBand, tempoBPM: 120.0, windowStartSample: 0,
        subBands: [low, zeros, zeros, zeros], detectDownbeats: true))

    #expect(grid.downbeats == .noneDetected)
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.source != .downbeat)
  }

  // MARK: - AC8(d): detectDownbeats == false → .notAttempted + BPM byte-identical

  @Test func detectDownbeatsFalseLeavesNotAttemptedAndBPMByteIdentical() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    let baseline = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: .init()))

    var gridOnly = BPMAnalyzer.Options()
    gridOnly.computeBeatGrid = true
    gridOnly.detectDownbeats = false
    let result = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: gridOnly))

    #expect(result.beatGrid?.downbeats == .notAttempted)
    #expect(result.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(result.confidence.bitPattern == baseline.confidence.bitPattern)
  }

  // MARK: - AC8(d′): detectDownbeats == true (abstains) → BPM byte-identical

  /// THE test that actually locks AC6's forced-`computeSubBands` byte-identity:
  /// turning downbeats ON must not perturb the BPM result even on the path where
  /// sub-bands are now force-computed. A flat click abstains, so the comparison is
  /// purely about the forced sub-band pass not touching the BPM winner.
  @Test func detectDownbeatsTrueAbstainKeepsBPMByteIdentical() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    var gridNoDownbeat = BPMAnalyzer.Options()
    gridNoDownbeat.computeBeatGrid = true
    gridNoDownbeat.detectDownbeats = false
    let off = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: gridNoDownbeat))

    var gridDownbeat = BPMAnalyzer.Options()
    gridDownbeat.computeBeatGrid = true
    gridDownbeat.detectDownbeats = true
    let on = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: gridDownbeat))

    // A flat four-on-the-floor click abstains → .noneDetected (downbeats ran).
    #expect(on.beatGrid?.downbeats == .noneDetected)
    // BPM byte-identical despite the forced sub-band pass (AC6 / AC2).
    #expect(on.bpm.bitPattern == off.bpm.bitPattern)
    #expect(on.confidence.bitPattern == off.confidence.bitPattern)
    try #require(on.candidates.count == off.candidates.count)
    for i in 0..<on.candidates.count {
      #expect(on.candidates[i].bpm.bitPattern == off.candidates[i].bpm.bitPattern)
      #expect(on.candidates[i].score.bitPattern == off.candidates[i].score.bitPattern)
    }
  }

  // MARK: - AC2: the public service honors detectDownbeats end-to-end

  @Test func serviceAnalyzeBeatGridHonorsDetectDownbeats() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    // Default: downbeats not attempted.
    let plain = try #require(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded))
    #expect(plain.downbeats == .notAttempted)

    // Opt-in: downbeats ran (abstains on a flat click → .noneDetected, never
    // .notAttempted).
    var options = AudioAnalysisService.Options()
    options.detectDownbeats = true
    let withDownbeats = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: options))
    #expect(withDownbeats.downbeats != .notAttempted)
  }

  // MARK: - AC9: BeatGrid.with(tempoAgreement:) forwards schemaVersion (internal)

  @Test func withTempoAgreementPreservesSchemaVersion() {
    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow,
      schemaVersion: 7)
    #expect(grid.with(tempoAgreement: .agree).schemaVersion == 7)
  }
}
