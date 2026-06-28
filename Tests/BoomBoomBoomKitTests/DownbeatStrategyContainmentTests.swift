//
//  DownbeatStrategyContainmentTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.11 AC #2: the DownbeatStrategy selector is byte-identical at the default
//  AND contained — switching strategy moves ONLY downbeats + gridOrigin, never the
//  BPM / confidence / candidates / grid tempo (the Epic-12 octave/tempo boundary).
//

import BoomBoomBoomKitTestSupport
import CryptoKit
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
  /// the operator-run, env-gated OA300/GiantSteps byte-identity benchmarks. The expected
  /// digest was captured from the Story-8.11 default path, which is byte-identical to the
  /// pre-story baseline (commit 0a8c18a) BY CONSTRUCTION: with `detectDownbeats == false`
  /// the downbeat branch is never entered (`downbeats == .notAttempted`) and
  /// `structuralDropContour` returns `nil`, so the new enum + helper add zero operations.
  /// Corroborated by the OA300 58/82·74/82 + GiantSteps 537/661·546/661 baseline match.
  @Test func defaultPathBeatGridMatchesPreStorySnapshot() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let result = try #require(
      BPMAnalyzer.estimateBPM(
        decoded: decoded, options: gridOptions(detectDownbeats: false, strategy: .metricalAccent)))
    let grid = try #require(result.beatGrid)

    // Canonical full-graph encoding: the BeatGrid as sorted-key JSON (Double → shortest
    // round-trip decimal, deterministic + platform-independent) plus the bpm/confidence/
    // candidate bit patterns. One SHA-256 over the lot = the committed pre-story digest.
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let gridHex = SHA256.hash(data: try encoder.encode(grid))
      .map { String(format: "%02x", $0) }.joined()
    var canonical = "bpm=\(result.bpm.bitPattern);conf=\(result.confidence.bitPattern)"
    for c in result.candidates { canonical += ";cand=\(c.bpm.bitPattern),\(c.score.bitPattern)" }
    canonical += ";grid=\(gridHex)"
    let digest = SHA256.hash(data: Data(canonical.utf8))
      .map { String(format: "%02x", $0) }.joined()

    let expected = "5019b4fa0dccb5dfd8a52ce98eef2b16bac62b80bde02109f61bb0a09a239c9b"
    if digest != expected { print("[snapshot] defaultPathBeatGrid digest = \(digest)") }
    #expect(
      digest == expected,
      "default-path BeatGrid drifted from the pre-story snapshot (baseline 0a8c18a); update `expected` only if the change is intentional (AC #2(a))."
    )
  }
}
