//
//  DownbeatStrategyContainmentTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.11 AC #2: the DownbeatStrategy selector is byte-identical at the default
//  AND contained — switching strategy moves ONLY downbeats + gridOrigin, never the
//  BPM / confidence / candidates / grid tempo (the Epic-12 octave/tempo boundary).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("DownbeatStrategyContainmentTests")
struct DownbeatStrategyContainmentTests {

  private func gridOptions(
    detectDownbeats: Bool, strategy: DownbeatStrategy
  ) -> BPMAnalyzer.Options {
    var opts = BPMAnalyzer.Options()
    opts.computeBeatGrid = true
    opts.detectDownbeats = detectDownbeats
    opts.downbeatStrategy = strategy
    return opts
  }

  private func assertBPMFieldsIdentical(
    _ a: BPMResult, _ b: BPMResult, _ label: String
  ) throws {
    #expect(a.bpm.bitPattern == b.bpm.bitPattern, "\(label): bpm")
    #expect(a.confidence.bitPattern == b.confidence.bitPattern, "\(label): confidence")
    try #require(a.candidates.count == b.candidates.count, "\(label): candidate count")
    for i in 0..<a.candidates.count {
      #expect(
        a.candidates[i].bpm.bitPattern == b.candidates[i].bpm.bitPattern, "\(label): cand \(i) bpm")
      #expect(
        a.candidates[i].score.bitPattern == b.candidates[i].score.bitPattern,
        "\(label): cand \(i) score")
    }
  }

  // MARK: - AC2(a): default-off → strategy has zero effect

  @Test func detectDownbeatsOffMakesStrategyInert() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    let metrical = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .metricalAccent)))
    let drop = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .structuralDrop)))
    let combined = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .combined)))

    // Gate off → downbeats not attempted regardless of strategy, full grid identical.
    #expect(metrical.beatGrid?.downbeats == .notAttempted)
    #expect(drop.beatGrid?.downbeats == .notAttempted)
    #expect(combined.beatGrid?.downbeats == .notAttempted)
    try assertBPMFieldsIdentical(metrical, drop, "off metrical vs drop")
    try assertBPMFieldsIdentical(metrical, combined, "off metrical vs combined")
    #expect(
      metrical.beatGrid?.estimatedTempo.bitPattern == drop.beatGrid?.estimatedTempo.bitPattern)
    #expect(metrical.beatGrid?.gridOrigin == drop.beatGrid?.gridOrigin)
    #expect(metrical.beatGrid?.gridOrigin == combined.beatGrid?.gridOrigin)
  }

  // MARK: - AC2(b): .metricalAccent reproduces the 8.5a path (vs independent refs)

  @Test func metricalAccentEstimatorDoesNotPerturbBPMVsEstimatorOff() throws {
    // AC #2(b), part 1 — BPM non-perturbation. The .metricalAccent estimator (which
    // runs the 8.5a algorithm) must not touch the BPM result. Asserted against the
    // estimator-OFF path (detectDownbeats == false) — an INDEPENDENT code path that
    // runs no downbeat estimator at all, NOT a second .metricalAccent dispatch
    // (which would be near-circular).
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    let off = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .metricalAccent)))
    let on = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: true, strategy: .metricalAccent)))

    // Independent ground truth: a flat 120-BPM click has no phase separation, so the
    // 8.5a estimator abstains (.noneDetected); estimator-off stays .notAttempted.
    #expect(off.beatGrid?.downbeats == .notAttempted)
    #expect(on.beatGrid?.downbeats == .noneDetected)

    // The 8.5a estimator must not perturb bpm/confidence/candidates/tempo (ON vs OFF).
    try assertBPMFieldsIdentical(off, on, "estimator off vs metricalAccent on")
    #expect(
      off.beatGrid?.estimatedTempo.bitPattern == on.beatGrid?.estimatedTempo.bitPattern)
  }

  @Test func metricalAccentReproducesEightFiveAFiringAgainstPlantedGroundTruth() throws {
    // AC #2(b), part 2 — firing reproduction. The .metricalAccent strategy must
    // reproduce the 8.5a estimator's FIRING behavior, asserted against INDEPENDENT
    // planted ground truth (the planted phase-0 downbeat), not a self-comparison.
    // Onset impulses @ 120 BPM with the low band emphasized on phase-0 frames → the
    // 8.5a metrical-accent estimator detects phase 0.
    let bars = 8
    let beatsPerBar = 4
    let period = 50
    let length = bars * beatsPerBar * period + period
    var onset = [Float](repeating: 0, count: length)
    var low = [Float](repeating: 0, count: length)
    let zeros = [Float](repeating: 0, count: length)
    for beatIndex in 0..<(bars * beatsPerBar) {
      let f = beatIndex * period
      onset[f] = 1.0
      low[f] = (beatIndex % beatsPerBar == 0) ? 1.0 : 0.25
    }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: onset, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: onset, tempoBPM: 120.0, windowStartSample: 0,
        subBands: [low, zeros, zeros, zeros],
        detectDownbeats: true, downbeatStrategy: .metricalAccent))

    guard case .detected(let estimate) = grid.downbeats else {
      Issue.record(
        "metricalAccent must reproduce the 8.5a phase-0 detection on the planted fixture")
      return
    }
    #expect(estimate.phaseIndex == 0)  // independent planted ground truth
    #expect(grid.gridOrigin?.source == .downbeat)
  }

  // MARK: - AC2(c): strategy-switch containment (the Epic-12 octave/tempo boundary)

  @Test func switchingStrategyPerturbsOnlyDownbeatsAndAnchor() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    let metrical = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: true, strategy: .metricalAccent)))
    let drop = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: true, strategy: .structuralDrop)))
    let combined = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: true, strategy: .combined)))

    // bpm / confidence / candidates / grid tempo are bit-identical across strategies
    // (the estimator never re-picks the tempo or its octave — AC #5).
    try assertBPMFieldsIdentical(metrical, drop, "metrical vs drop")
    try assertBPMFieldsIdentical(metrical, combined, "metrical vs combined")
    #expect(
      metrical.beatGrid?.estimatedTempo.bitPattern == drop.beatGrid?.estimatedTempo.bitPattern,
      "grid tempo unchanged by strategy")
    #expect(
      metrical.beatGrid?.estimatedTempo.bitPattern == combined.beatGrid?.estimatedTempo.bitPattern,
      "grid tempo unchanged by strategy")
  }

  // MARK: - AC2(a): committed pre-story snapshot lock (always-run regression backbone)

  /// AC #2(a) — an ALWAYS-RUN committed bit-pattern snapshot of the default-path
  /// (`detectDownbeats == false`, `.metricalAccent`) `BeatGrid` graph + bpm fields, so a
  /// future uniform drift from the pre-story output is caught in `make test` — not only by
  /// the operator-run, env-gated OA300/GiantSteps byte-identity benchmarks.
  ///
  /// Re-captured for Story 8.12: the digest moved because ``BeatGrid/schemaVersion`` bumped
  /// 1 → 2 (the `BeatGridAnchor.beatIndex: Int?` persisted-contract change, DD #5). The
  /// default-path grid is OTHERWISE byte-identical to the pre-story baseline (commit
  /// 0a8c18a): with `detectDownbeats == false` the downbeat branch is never entered
  /// (`downbeats == .notAttempted`); the auto anchor keeps a non-nil `beatIndex` that
  /// encodes identically to the pre-`Int?` form — so the ONLY serialized delta is the
  /// version stamp. The second assertion proves exactly that (re-stamping to v1 reproduces
  /// the pre-story digest). Corroborated by the OA300 58/82·74/82 + GiantSteps
  /// 537/661·546/661 baseline match.
  @Test func defaultPathBeatGridMatchesPreStorySnapshot() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let result = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .metricalAccent)))
    let grid = try #require(result.beatGrid)

    // Committed pre-story snapshot (captured at 0a8c18a, + the deliberate 8-12 schemaVersion 1→2
    // bump). Replaces the former single SHA-256-over-float-bits digest, which was not portable: the
    // `Float` Accelerate/vDSP BPM path is not bit-reproducible across CPU/toolchain (~1e-5 BPM /
    // ~1e-9 confidence), so the digest passed on the author's Mac but failed on CI. Here the
    // host-independent STRUCTURE (counts, enums, ordering, schema, anchor index/source) is pinned
    // EXACTLY, and the Float-derived NUMERICS are compared within a tight tolerance that catches real
    // drift while surviving cross-toolchain noise. Per-beat confidence/strength are deliberately NOT
    // pinned (the most host-sensitive, least meaningful fields); every beat's presentationTime IS,
    // since that is the actual playable grid.
    let bpmTol = 1e-4
    let confTolD = 1e-6
    let confTolF: Float = 1e-4
    let timeTol = 1e-6

    // BPMResult scalars + candidates.
    #expect(NumericTestHelpers.approxEqual(result.bpm, 120.00007596407346, tol: bpmTol))
    #expect(NumericTestHelpers.approxEqual(result.confidence, 0.9238235544912974, tol: confTolD))
    let expectedCandidates: [(bpm: Double, score: Float)] = [
      (120.0, 1.0000058), (114.0, 0.003_117_62), (127.0, 0.001_594_748_1),
    ]
    try #require(result.candidates.count == expectedCandidates.count, "candidate count drifted")
    for (i, exp) in expectedCandidates.enumerated() {
      #expect(
        NumericTestHelpers.approxEqual(result.candidates[i].bpm, exp.bpm, tol: bpmTol),
        "candidate \(i) bpm drift: \(result.candidates[i].bpm) vs \(exp.bpm)")
      // Loose Float tolerance on score: catches a ranking-evidence reshuffle that leaves bpm stable.
      #expect(
        NumericTestHelpers.approxEqual(result.candidates[i].score, exp.score, tol: confTolF),
        "candidate \(i) score drift: \(result.candidates[i].score) vs \(exp.score)")
    }

    // Grid structure — host-independent, pinned exactly.
    #expect(grid.schemaVersion == 2)
    #expect(grid.downbeats == .notAttempted)
    #expect(grid.tempoAgreement == .notCompared)
    #expect(grid.coverage == .analysisWindow)
    #expect(grid.beats.count == 20)
    for i in 1..<grid.beats.count {
      #expect(
        grid.beats[i].presentationTime > grid.beats[i - 1].presentationTime,
        "beats not strictly increasing at \(i)")
    }

    // Grid numerics — tolerance.
    #expect(NumericTestHelpers.approxEqual(grid.estimatedTempo, 120.00007596407346, tol: bpmTol))
    #expect(NumericTestHelpers.approxEqual(grid.confidence, 0.8909683, tol: confTolF))

    // gridOrigin: exact structure (coupled auto anchor) + tolerance numerics.
    let origin = try #require(grid.gridOrigin)
    #expect(origin.beatIndex == 12)
    #expect(origin.source == .medianConsistentBeat)
    #expect(NumericTestHelpers.approxEqual(origin.presentationTime, 5.95, tol: timeTol))
    #expect(NumericTestHelpers.approxEqual(origin.confidence, 1.0, tol: confTolF))
    #expect(NumericTestHelpers.approxEqual(origin.strength, 1.0, tol: confTolF))

    // Every beat's presentationTime vs the committed array — this is the actual grid (strong drift
    // detection). Contingency: if a runner ever shows beat SELECTION differs (a time off by ≥ one
    // hop ≈ 11ms, or a count change), that is host-sensitive beat tracking, not float noise — widen
    // to count + monotonicity + endpoints and record it; expected stable for clean click fixtures.
    let expectedBeatTimes: [Double] = [
      0.0, 0.48, 0.96, 1.45, 1.95, 2.45, 2.95, 3.45, 3.95, 4.45,
      4.95, 5.45, 5.95, 6.45, 6.95, 7.45, 7.95, 8.45, 8.95, 9.45,
    ]
    try #require(grid.beats.count == expectedBeatTimes.count)
    for (i, expT) in expectedBeatTimes.enumerated() {
      #expect(
        NumericTestHelpers.approxEqual(grid.beats[i].presentationTime, expT, tol: timeTol),
        "beat \(i) presentationTime drift: \(grid.beats[i].presentationTime) vs \(expT)")
    }

    // Idempotence guard (NOT a history check — that role is the snapshot assertions above). Re-stamp
    // the v2 grid down to v1 and back to v2 through the memberwise init; `BeatGrid` is `Equatable`,
    // so `restamped == grid` proves the schemaVersion stamp is the ONLY field the 3-rule `gridOrigin`
    // memberwise init differs on (the version flip perturbs no other field — the init is idempotent
    // on an already-valid grid).
    let downgraded = BeatGrid(
      beats: grid.beats, downbeats: grid.downbeats, estimatedTempo: grid.estimatedTempo,
      confidence: grid.confidence, tempoAgreement: grid.tempoAgreement,
      gridOrigin: grid.gridOrigin, coverage: grid.coverage, schemaVersion: 1)
    #expect(downgraded.schemaVersion == 1)
    let restamped = BeatGrid(
      beats: downgraded.beats, downbeats: downgraded.downbeats,
      estimatedTempo: downgraded.estimatedTempo, confidence: downgraded.confidence,
      tempoAgreement: downgraded.tempoAgreement, gridOrigin: downgraded.gridOrigin,
      coverage: downgraded.coverage, schemaVersion: 2)
    #expect(restamped == grid, "memberwise init perturbed a non-version field")
  }
}
