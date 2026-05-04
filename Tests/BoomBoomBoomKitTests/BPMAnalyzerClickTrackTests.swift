//
//  BPMAnalyzerClickTrackTests.swift
//  BoomBoomBoomKitTests
//
//  Story 3-3: click-track cross-correlation rescoring.
//  Direct tests on the internal `clickRescore` and `synthesizeClickPattern` helpers
//  via @testable import (matches the subBandVote test access pattern).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Helpers

/// Build a synthetic onset envelope at `onsetRate` (default 100 Hz) with unit impulses
/// at the given frame indices. Used by the rescoring gauntlet (3a, 3b, 3c, 3d).
private func makeImpulseEnvelope(length: Int, impulseFrames: [Int]) -> [Float] {
  var env = [Float](repeating: 0, count: length)
  for f in impulseFrames where f >= 0 && f < length {
    env[f] = 1.0
  }
  return env
}

/// Box-Muller transform driven by SplitMix64 — produces deterministic Gaussian noise
/// with mean 0 and unit variance. Used by 3b for reproducible noisy envelopes.
private func gaussianNoise(count: Int, seed: UInt64, amplitude: Float) -> [Float] {
  var rng = SplitMix64(seed: seed)
  var noise = [Float](repeating: 0, count: count)
  var i = 0
  while i < count {
    // Two uniform-(0, 1] doubles from successive SplitMix64 outputs.
    let u1 = max(Double(rng.next()) / Double(UInt64.max), 1e-12)
    let u2 = Double(rng.next()) / Double(UInt64.max)
    let r = (-2.0 * log(u1)).squareRoot()
    let theta = 2.0 * .pi * u2
    let z0 = Float(r * cos(theta)) * amplitude
    let z1 = Float(r * sin(theta)) * amplitude
    noise[i] = z0
    if i + 1 < count {
      noise[i + 1] = z1
    }
    i += 2
  }
  return noise
}

/// Add two equal-length envelopes element-wise.
private func addEnvelopes(_ a: [Float], _ b: [Float]) -> [Float] {
  precondition(a.count == b.count)
  var out = [Float](repeating: 0, count: a.count)
  for i in 0..<a.count { out[i] = a[i] + b[i] }
  return out
}

/// Locate a candidate's score in the rescored array (BPMs are returned as-is from input).
private func score(of bpm: Double, in candidates: [(bpm: Double, score: Float)]) -> Float? {
  candidates.first(where: { $0.bpm == bpm })?.score
}

// MARK: - Click-Pattern Synthesis (Task 2.5)

@Suite("BPMAnalyzer — synthesizeClickPattern")
struct SynthesizeClickPatternTests {

  /// Off-by-one regression: the kernel array must be sized so every synthesized index is in bounds.
  /// Concrete witness for `bpm = 61, onsetRate = 100` (per Task 2.5 / DD#8):
  /// `period = 60·100/61 = 98.36...`, so the original `Int(period * (clickCount-1)) + 1`
  /// formula yielded `Int(688.52) + 1 = 689`, but the rounded last index is
  /// `Int(688.52.rounded()) = 689` — equal to length, out-of-bounds. The fixed
  /// implementation computes indices first, then sizes the array as `indices.last! + 1`.
  @Test(
    "kernel-length off-by-one prevention",
    arguments: [61.0, 63.0, 67.0, 89.0, 120.0, 126.0, 200.0])
  func kernelLengthOffByOne(bpm: Double) {
    let onsetRate: Double = 100.0
    let pattern = BPMAnalyzer.synthesizeClickPattern(
      bpm: bpm, onsetRate: onsetRate, clickCount: 8)
    #expect(!pattern.isEmpty, "Pattern should be non-empty for bpm=\(bpm)")

    // Locate the last non-zero index.
    var lastIdx = -1
    for i in 0..<pattern.count where pattern[i] != 0 { lastIdx = i }
    #expect(lastIdx >= 0, "Pattern should have at least one non-zero index")
    #expect(
      pattern.count == lastIdx + 1,
      "pattern.count must equal lastNonZeroIndex + 1 (got count=\(pattern.count), lastIdx=\(lastIdx) for bpm=\(bpm))"
    )
  }

  @Test("guards: invalid bpm / onsetRate / clickCount return empty")
  func invalidArgsReturnEmpty() {
    let onsetRate: Double = 100.0
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: 0, onsetRate: onsetRate).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: -1, onsetRate: onsetRate).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: .nan, onsetRate: onsetRate).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: .infinity, onsetRate: onsetRate).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: 120, onsetRate: 0).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: 120, onsetRate: -100).isEmpty)
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: 120, onsetRate: 100, clickCount: 3).isEmpty)
    // BPM > 6000 at 100 Hz onset rate gives period < 1.0 → alias.
    #expect(BPMAnalyzer.synthesizeClickPattern(bpm: 7000, onsetRate: 100).isEmpty)
  }

  @Test("clickCount unit impulses are placed at 60·onsetRate/bpm spacing")
  func unitImpulsesPlacedCorrectly() {
    let pattern = BPMAnalyzer.synthesizeClickPattern(
      bpm: 120, onsetRate: 100, clickCount: 8)
    // 120 BPM at 100 Hz onset rate: period = 50 frames.
    // Indices: 0, 50, 100, 150, 200, 250, 300, 350.
    #expect(pattern.count == 351)
    let nonZeros = (0..<pattern.count).filter { pattern[$0] != 0 }
    #expect(nonZeros == [0, 50, 100, 150, 200, 250, 300, 350])
    for idx in nonZeros { #expect(pattern[idx] == 1.0) }
  }
}

// MARK: - Rescoring Gauntlet (Task 2.4 — AC #3 four-test gauntlet)

@Suite("BPMAnalyzer — clickRescore (AC #3 gauntlet)")
struct ClickRescoreTests {

  // 10s envelope at 100 Hz onset rate = 1000 frames.
  private let envLength = 1000
  private let onsetRate: Double = 100.0
  // Story 3-3 review Decision A: AC #3 gauntlet runs at BOTH α=0.3 (math-illustrative
  // bound) AND α=0.7 (production default finalized in Task 3.3). Each test parameterizes
  // over the two values with α-specific bounds. See `expectedRatio3a(forAlpha:)` for the
  // 3a-specific math; 3b/3c/3d hold direction-only for both α.
  private let alpha: Float = 0.3  // Default for non-parameterized helper tests.

  /// 3a expected ratio for `score(120) / score(60)` on the clean 120-BPM impulse
  /// envelope. NCC for 120-vs-120 is 1.0; NCC for 60-vs-120 is ~0.73 (60-BPM kernel
  /// hits every other beat). Post-blend ratio = (α + 0.27·(1-α)) / 1.0... etc.
  /// At α=0.3: 1.0 / (0.3 + 0.7·0.73) = 1.0 / 0.811 ≈ 1.233 → assert ≥ 1.2 (3% slack).
  /// At α=0.7: 1.0 / (0.7 + 0.3·0.73) = 1.0 / 0.919 ≈ 1.088 → assert ≥ 1.085 (0.3% slack).
  private static func expectedRatio3a(forAlpha alpha: Float) -> Float {
    alpha == 0.3 ? 1.2 : 1.085
  }

  /// 3a (clean synthetic 120 BPM): impulses at frames 0, 50, 100, ..., 950.
  /// Candidates [(120,1), (60,1), (180,1)]. Run at both α=0.3 and α=0.7.
  /// Assertion: score(120) >= expectedRatio3a(α) × score(60) AND score(120) > score(180).
  @Test(
    "3a — clean 120 BPM envelope, 120 outranks 60 (α-specific ratio) and beats 180",
    arguments: [Float(0.3), Float(0.7)])
  func gauntlet_3a_clean120(alpha: Float) {
    let env = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 50).map { $0 })
    let candidates: [(bpm: Double, score: Float)] =
      [(120, 1.0), (60, 1.0), (180, 1.0)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)

    let s120 = score(of: 120, in: rescored) ?? 0
    let s60 = score(of: 60, in: rescored) ?? 0
    let s180 = score(of: 180, in: rescored) ?? 0
    let expectedRatio = Self.expectedRatio3a(forAlpha: alpha)
    #expect(
      s120 >= expectedRatio * s60,
      "At α=\(alpha): expected score(120)=\(s120) >= \(expectedRatio) × score(60)=\(s60)")
    #expect(s120 > s180, "At α=\(alpha): expected score(120)=\(s120) > score(180)=\(s180)")
  }

  /// 3b (noisy synthetic 120 BPM): same 120 impulse envelope + Gaussian noise (amplitude 0.25).
  /// Margin tightens but ranking holds: score(120) > score(60). Direction-only assertion
  /// works for both α=0.3 and α=0.7.
  @Test(
    "3b — noisy 120 BPM envelope, 120 still beats 60 (both α)",
    arguments: [Float(0.3), Float(0.7)])
  func gauntlet_3b_noisy120(alpha: Float) {
    let clean = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 50).map { $0 })
    let noise = gaussianNoise(count: envLength, seed: 0xB00D_F00D, amplitude: 0.25)
    let env = addEnvelopes(clean, noise)
    let candidates: [(bpm: Double, score: Float)] = [(120, 1.0), (60, 1.0), (180, 1.0)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)

    let s120 = score(of: 120, in: rescored) ?? 0
    let s60 = score(of: 60, in: rescored) ?? 0
    #expect(s120 > s60, "At α=\(alpha): expected score(120)=\(s120) > score(60)=\(s60) under noise")
  }

  /// 3c (anti-test on 60 BPM input): impulses every 100 frames.
  /// Candidates [(60,1), (120,1), (90,1)]. Assert score(60) > score(120). Symmetry-trap
  /// test holds for both α: if it fails, the metric is measuring energy, not alignment.
  @Test(
    "3c — 60 BPM envelope, 60 outranks 120 (symmetry trap, both α)",
    arguments: [Float(0.3), Float(0.7)])
  func gauntlet_3c_anti60(alpha: Float) {
    let env = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 100).map { $0 })
    let candidates: [(bpm: Double, score: Float)] = [(60, 1.0), (120, 1.0), (90, 1.0)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)

    let s60 = score(of: 60, in: rescored) ?? 0
    let s120 = score(of: 120, in: rescored) ?? 0
    #expect(
      s60 > s120,
      "At α=\(alpha): expected score(60)=\(s60) > score(120)=\(s120) on 60-BPM env")
  }

  /// 3d (alpha-blend test): same 120 BPM envelope as 3a but candidates `[(120, 0.5), (60, 1.0)]`.
  /// Tests that the upstream-score advantage (2x for 60 BPM) is NOT flipped by the click
  /// blend at either default α. Math:
  ///   At α=0.3: LHS = 0.5 · 1.0 = 0.5; RHS = 1.0 · (0.3 + 0.7·0.73) = 0.811 → 60 wins.
  ///   At α=0.7: LHS = 0.5 · 1.0 = 0.5; RHS = 1.0 · (0.7 + 0.3·0.73) = 0.919 → 60 wins.
  /// Both α preserve the corroborative-not-authoritative design intent (DD#4).
  @Test(
    "3d — alpha-blend cannot flip a 2x upstream-score advantage (both α)",
    arguments: [Float(0.3), Float(0.7)])
  func gauntlet_3d_alphaBlend(alpha: Float) {
    let env = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 50).map { $0 })
    let candidates: [(bpm: Double, score: Float)] = [(120, 0.5), (60, 1.0)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)

    let s120 = score(of: 120, in: rescored) ?? 0
    let s60 = score(of: 60, in: rescored) ?? 0
    #expect(
      s60 > s120,
      "At α=\(alpha), upstream 1.0 should beat upstream 0.5 even with perfect 120 alignment. score(60)=\(s60), score(120)=\(s120)"
    )
  }

  /// Sort contract: rescored output is sorted descending by post-rescore score with
  /// stable index tiebreaker on original input order.
  @Test("rescored output is sorted descending by score with stable index tiebreaker")
  func sortedDescending() {
    let env = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 50).map { $0 })
    let candidates: [(bpm: Double, score: Float)] = [(60, 0.8), (120, 0.9), (180, 0.85)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)
    for i in 1..<rescored.count {
      #expect(
        rescored[i - 1].score >= rescored[i].score,
        "Rescored array must be sorted descending by score")
    }
  }

  /// Stable-index tiebreaker contract (Story 3-3 review patch P10): when two candidates
  /// produce identical post-rescore scores, sort order MUST follow original input
  /// (offset) order. Construct a tie by feeding two candidates whose post-rescore
  /// scores collide — same upstream score, identical NCC against a flat envelope
  /// (zero-energy guard makes both NCCs zero, blend reduces to oldScore × alpha).
  @Test("stable index tiebreaker preserves input order when scores tie")
  func stableTiebreakerOnTie() {
    // Flat (all-zero) envelope: every candidate's NCC is zero (zero-energy guard
    // skips every lag). Post-rescore score = oldScore × alpha for all candidates.
    // With identical oldScore, post-rescore scores tie exactly.
    let flatEnv = [Float](repeating: 0, count: envLength)
    let candidates: [(bpm: Double, score: Float)] = [
      (110, 0.5),  // offset 0
      (120, 0.5),  // offset 1
      (130, 0.5),  // offset 2
    ]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: flatEnv,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)
    // All post-rescore scores must be equal (zero NCC × any alpha = oldScore × alpha).
    let firstScore = rescored.first?.score ?? -1
    for r in rescored {
      #expect(r.score == firstScore, "Expected all scores tied; got \(rescored.map(\.score))")
    }
    // Tiebreaker must preserve original (offset) order: 110, 120, 130.
    #expect(rescored.map(\.bpm) == [110, 120, 130], "Tiebreaker must preserve input order")
  }

  /// DD#13b uniform-skip: when ANY candidate's kernel doesn't fit the envelope, return all
  /// candidates unchanged.
  @Test("uniform skip when envelope shorter than any candidate's kernel")
  func uniformSkipShortEnvelope() {
    // 100-frame envelope: a 60 BPM × 8-click kernel is ~700 frames → doesn't fit.
    let env = [Float](repeating: 1.0, count: 100)
    let candidates: [(bpm: Double, score: Float)] = [(120, 0.9), (60, 0.5)]
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: 100.0,
      alpha: 0.3,
      trace: &trace)

    #expect(rescored.count == candidates.count)
    // Returned in original order with original scores.
    for (orig, out) in zip(candidates, rescored) {
      #expect(orig.bpm == out.bpm)
      #expect(orig.score == out.score)
    }
  }

  /// Trace population: when trace is non-nil, clickCorrelationDetail is set with
  /// one ``ClickCorrelationEntry`` per candidate, in input order.
  @Test("trace.clickCorrelationDetail is populated when trace is non-nil")
  func tracePopulatesDetail() throws {
    let env = makeImpulseEnvelope(
      length: envLength, impulseFrames: stride(from: 0, to: envLength, by: 50).map { $0 })
    let candidates: [(bpm: Double, score: Float)] = [(120, 1.0), (60, 1.0)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()
    _ = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: alpha,
      trace: &trace)

    let detail = try #require(trace?.clickCorrelationDetail)
    #expect(detail.contains(where: { $0.bpm == 120.0 }))
    #expect(detail.contains(where: { $0.bpm == 60.0 }))
    // bestNCC is in [0, 1] by Cauchy–Schwarz.
    if let entry120 = detail.first(where: { $0.bpm == 120.0 }) {
      let n120 = entry120.normalizedClickScore
      #expect(n120 >= 0 && n120 <= 1.0001)  // 1.0001 to accept tiny FP slack.
    }
  }
}

// MARK: - Pipeline Integration Smoke Test (Task 2.6)

@Suite("BPMAnalyzer — clickTrackCorrelation full-pipeline smoke")
struct ClickRescorePipelineTests {

  @Test("full pipeline at .optimal+click on 120 BPM click track converges to ~120")
  func pipelineOnSyntheticClickTrack() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 15)
    let techniqueSet = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let result = try #require(
      BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: 44100,
        options: .init(techniqueSet: techniqueSet)))
    #expect(
      result.bpm >= 117.6 && result.bpm <= 122.4,
      "Expected ~120 BPM (within 2%), got \(result.bpm)")
  }

  @Test("trace.clickCorrelationDetail is populated when technique active")
  func traceDetailPopulatedInPipeline() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 15)
    let techniqueSet = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let result = try #require(
      BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: 44100,
        options: .init(techniqueSet: techniqueSet, enableTrace: true)))
    let trace = try #require(result.trace)
    let detail = try #require(trace.clickCorrelationDetail)
    #expect(!detail.isEmpty)
  }

  @Test("trace.clickCorrelationDetail is nil when technique inactive")
  func traceDetailNilWhenInactive() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 15)
    let result = try #require(
      BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: 44100,
        options: .init(techniqueSet: .optimal, enableTrace: true)))
    let trace = try #require(result.trace)
    #expect(trace.clickCorrelationDetail == nil)
  }
}
