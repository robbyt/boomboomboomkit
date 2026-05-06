//
//  BPMDiagnosticTraceTests.swift
//  BoomBoomBoomKitTests
//
//  Story 3-3b: trace-key namespacing.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Helpers

/// Build a synthetic onset envelope with unit impulses at the given frame indices.
private func makeImpulseEnvelope(length: Int, impulseFrames: [Int]) -> [Float] {
  var env = [Float](repeating: 0, count: length)
  for f in impulseFrames where f >= 0 && f < length {
    env[f] = 1.0
  }
  return env
}

@Suite("BPMDiagnosticTrace — Story 3-3b trace key namespacing")
struct BPMDiagnosticTraceTests {

  // MARK: - AC #2: Collision regression

  /// Two candidates whose BPMs both round to `"61.0"` under `String(format: "%.1f", bpm)`
  /// — the legacy `[String: Float]` keyed by `%.1f` BPM would have collapsed them into a
  /// single dictionary entry with no warning. The typed `[ClickCorrelationEntry]` shape
  /// preserves both as distinct entries with full `Double` precision.
  @Test("two candidates that round to the same %.1f label remain distinct entries")
  func clickRescoreCollisionScenarioPreservesDistinctEntries() throws {
    let onsetRate: Double = 100.0
    // Envelope length must be > the longer 60.95 BPM kernel (period ≈ 98.4 frames × 8
    // clicks ≈ 690 frames). 2000 frames gives ample headroom for the rescore search.
    let env = makeImpulseEnvelope(
      length: 2000,
      impulseFrames: stride(from: 0, to: 2000, by: 50).map { $0 })

    // Both BPMs round to "61.0" via String(format: "%.1f", bpm).
    let candidates: [(bpm: Double, score: Float)] = [(61.04, 0.5), (60.95, 0.5)]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()

    _ = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: 0.3,
      trace: &trace)

    let entries = try #require(trace?.clickCorrelationDetail)

    // Both candidates are present as separate entries — no collision collapse.
    #expect(entries.count == 2)

    // Exact Double equality — no %.1f rounding loss.
    let entry61_04 = try #require(entries.first(where: { $0.candidateIndex == 0 }))
    let entry60_95 = try #require(entries.first(where: { $0.candidateIndex == 1 }))
    #expect(entry61_04.bpm == 61.04)
    #expect(entry60_95.bpm == 60.95)
  }

  // MARK: - AC #3: Stable iteration order

  /// `clickRescore` emits one entry per candidate, in input order, with `candidateIndex`
  /// matching the input array index. This guarantees `entries.map(\.candidateIndex)`
  /// is `[0, 1, 2, …]` with no gaps for downstream UI consumers.
  @Test("entries preserve input-order candidateIndex with no gaps")
  func clickCorrelationEntriesPreserveCandidateIndexOrder() throws {
    let onsetRate: Double = 100.0
    let env = makeImpulseEnvelope(
      length: 2000,
      impulseFrames: stride(from: 0, to: 2000, by: 50).map { $0 })

    // 5 candidates in deliberately non-monotonic BPM order.
    let candidates: [(bpm: Double, score: Float)] = [
      (120, 1.0), (60, 0.8), (100, 0.6), (150, 0.4), (90, 0.2),
    ]
    var trace: BPMDiagnosticTrace? = BPMDiagnosticTrace()

    _ = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: env,
      onsetRate: onsetRate,
      alpha: 0.3,
      trace: &trace)

    let entries = try #require(trace?.clickCorrelationDetail)
    #expect(entries.map(\.candidateIndex) == Array(0..<entries.count))
    #expect(entries.count == 5)

    // Each entry carries the original BPM at the matching index.
    for (idx, cand) in candidates.enumerated() {
      #expect(entries[idx].bpm == cand.bpm)
    }
  }

  // MARK: - AC #7: CustomStringConvertible smoke test

  /// Each of the four (five, with `BarCandidate`) public typed evidence structs gets
  /// the `print(...)` / LLDB-friendly `description` affordance the legacy dictionaries
  /// provided by virtue of being `[String: …]`.
  @Test("CustomStringConvertible covers every typed evidence struct")
  func customStringConvertibleForAllFourTypes() {
    let click = ClickCorrelationEntry(candidateIndex: 0, bpm: 120.5, normalizedClickScore: 0.78)
    let clickStr = String(describing: click)
    #expect(clickStr.contains("0"))
    #expect(clickStr.contains("120.5"))
    #expect(clickStr.contains("0.78"))

    let harmonic = HarmonicRatioEvidence(
      ratio: "2:1", fastBPM: 160.0, slowBPM: 80.0, winnerBPM: 160.0)
    let harmonicStr = String(describing: harmonic)
    #expect(harmonicStr.contains("2:1"))
    #expect(harmonicStr.contains("160.0"))
    #expect(harmonicStr.contains("80.0"))

    let subBand = SubBandVoteEvidence(preVoteBPM: 90.0, postVoteBPM: 180.0, changed: true)
    let subBandStr = String(describing: subBand)
    #expect(subBandStr.contains("90.0"))
    #expect(subBandStr.contains("180.0"))
    #expect(subBandStr.contains("true"))

    let bar = BarCandidate(bars: 128, bpm: 128.0)
    let barStr = String(describing: bar)
    #expect(barStr.contains("128"))

    let duration = DurationHintEvidence(
      fileDurationSeconds: 240.0,
      barCandidates: [bar],
      boostedCandidates: [128.0])
    let durationStr = String(describing: duration)
    #expect(durationStr.contains("240.0"))
    #expect(durationStr.contains("128"))
  }
}

// MARK: - Story 4-3b: SubBandEnergies typed migration

/// Story 4-3b Task 2.8 — verifies the `SubBandEnergies` shape and the
/// `.zero` semantic preservation (the migrated field must observe the same
/// "no entry / zero energy" equivalence the old `[String: Float] = [:]`
/// shape provided).
@Suite("SubBandEnergies — Story 4-3b typed migration")
struct SubBandEnergiesTests {

  /// `.zero` is the default-initialization sentinel: all four sub-band fields
  /// equal `0`. Same observable state as the pre-Story-4-3b empty dict.
  @Test("zero constant has all four fields at 0")
  func zeroHasAllFieldsAtZero() {
    let z = SubBandEnergies.zero
    #expect(z.kick == 0)
    #expect(z.snare == 0)
    #expect(z.crack == 0)
    #expect(z.hihat == 0)
  }

  /// Memberwise init round-trips field values exactly (no precision loss).
  @Test("init round-trip preserves field values")
  func initRoundTrip() {
    let e = SubBandEnergies(kick: 0.25, snare: 0.5, crack: 0.125, hihat: 1.0)
    #expect(e.kick == 0.25)
    #expect(e.snare == 0.5)
    #expect(e.crack == 0.125)
    #expect(e.hihat == 1.0)
  }

  /// Description matches the Story 3-3b shape (e.g., `ClickCorrelationEntry`)
  /// — `"SubBandEnergies(kick: <f>, snare: <f>, crack: <f>, hihat: <f>)"`.
  @Test("description includes all four labelled fields")
  func descriptionShape() {
    let e = SubBandEnergies(kick: 0.1, snare: 0.2, crack: 0.3, hihat: 0.4)
    let d = String(describing: e)
    #expect(d.contains("SubBandEnergies"))
    #expect(d.contains("kick:"))
    #expect(d.contains("snare:"))
    #expect(d.contains("crack:"))
    #expect(d.contains("hihat:"))
  }

  /// `Equatable` conformance is required so the `BPMAnalyzerTests`
  /// `traceAtIntensity1` reader can use `== .zero` (Story 4-3b Task 2.5).
  /// Synthesis is free for all-`Float` storage.
  @Test("Equatable: zero == zero, nonzero != zero")
  func equatableConformance() {
    #expect(SubBandEnergies.zero == SubBandEnergies.zero)
    #expect(SubBandEnergies(kick: 0.5, snare: 0, crack: 0, hihat: 0) != .zero)
    #expect(
      SubBandEnergies(kick: 0.1, snare: 0.2, crack: 0.3, hihat: 0.4)
        == SubBandEnergies(kick: 0.1, snare: 0.2, crack: 0.3, hihat: 0.4))
  }
}
