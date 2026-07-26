//
//  MLDiagnosticSnapshotTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 Task 10 + AC #1: shape rules, CaseIterable witnesses,
//  equality, and description bounding for the public typed-evidence
//  snapshot introduced by Story 4-6.
//
//  GH-167 item 6 (#124): the shape rules are no longer runtime rules.
//  Each outcome carries exactly the evidence its path produces, so the
//  combinations the old init trapped on are now rejected by the type
//  checker and cannot be written here at all. What remains testable is
//  that the flat projections read the payloads back correctly — those
//  projections are the compatibility surface every existing reader
//  (the Demo, the FR-18 harness) goes through.
//

import BoomBoomBoomKit
import Foundation
import Testing

@Suite("MLDiagnosticSnapshot (Story 4-6 AC #1)")
struct MLDiagnosticSnapshotTests {

  /// Win path: decode evidence projects through, no failure stage, no
  /// gate.
  @Test("win outcome projects decode evidence, no stage, no gate")
  func winOutcomeProjections() throws {
    let snapshot = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0xDEAD_BEEF,
      outcome: .win(.init(bpm: 128.0, softmaxMax: 0.72, softmaxSecondMax: 0.18)))
    #expect(snapshot.failureStage == nil)
    #expect(snapshot.decodedBPM == 128.0)
    #expect(snapshot.softmaxMax == 0.72)
    #expect(snapshot.softmaxSecondMax == 0.18)
    #expect(snapshot.inputFeatureChecksum == 0xDEAD_BEEF)
    #expect(snapshot.gateFired == nil)
  }

  /// Pre-decode abstains carry a checksum and nothing else: no logit
  /// vector was produced, so there is no decode to report.
  @Test("pre-decode abstains project no decode evidence")
  func preDecodeAbstainProjections() throws {
    let cases: [(MLDiagnosticSnapshot.Outcome, MLDiagnosticSnapshot.FailureStage)] = [
      (.featurizeRejected, .featurizeRejected),
      (.graphFailed, .graphFailed),
      (.decodeRejectedNonFinite, .decodeRejected),
    ]
    for (outcome, expectedStage) in cases {
      let snapshot = MLDiagnosticSnapshot(inputFeatureChecksum: 0x42, outcome: outcome)
      #expect(snapshot.failureStage == expectedStage)
      #expect(snapshot.decode == nil)
      #expect(snapshot.decodedBPM == nil)
      #expect(snapshot.softmaxMax == nil)
      #expect(snapshot.softmaxSecondMax == nil)
      #expect(snapshot.gateFired == nil)
    }
  }

  /// A gate rejection carries the decode it rejected plus which gate
  /// rejected it. Both are non-optional in the payload, so a gate
  /// rejection without evidence is unrepresentable.
  @Test("gate rejection projects decode evidence and the firing gate")
  func gateRejectionProjections() throws {
    let snapshot = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x01,
      outcome: .confidenceGateRejected(
        .init(bpm: 113.0, softmaxMax: 0.42, softmaxSecondMax: 0.40),
        gate: .gate1Softmax))
    #expect(snapshot.failureStage == .confidenceGateRejected)
    #expect(snapshot.gateFired == .gate1Softmax)
    #expect(snapshot.decodedBPM == 113.0)
  }

  /// Both decode rejections report the same stage but differ in the
  /// evidence they can carry — the out-of-range case preserves the raw
  /// tempo the model produced, the non-finite case has none to preserve.
  @Test("both decode rejections share a stage but not their evidence")
  func decodeRejectionVariants() throws {
    let nonFinite = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x02, outcome: .decodeRejectedNonFinite)
    let outOfRange = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x02,
      outcome: .decodeRejectedOutOfRange(
        .init(bpm: 215.0, softmaxMax: 0.42, softmaxSecondMax: 0.18)))
    #expect(nonFinite.failureStage == .decodeRejected)
    #expect(outOfRange.failureStage == .decodeRejected)
    #expect(nonFinite.decodedBPM == nil)
    // Reports what the model said, not what the library would accept.
    #expect(outOfRange.decodedBPM == 215.0)
    #expect(nonFinite != outOfRange)
  }

  /// GH-167 item 6 (#124): the taxonomy covers exactly the stages a
  /// snapshot can represent. `featuresAbsent` and `featureVersionMismatch`
  /// were removed — `inputFeatureChecksum` is non-optional and those
  /// paths have no features to checksum, so they were public cases no
  /// snapshot could legally carry.
  @Test("FailureStage allCases count == 4")
  func failureStageAllCasesCount() throws {
    #expect(MLDiagnosticSnapshot.FailureStage.allCases.count == 4)
    let expected: Set<String> = [
      "featurizeRejected",
      "graphFailed",
      "decodeRejected",
      "confidenceGateRejected",
    ]
    let actual = Set(
      MLDiagnosticSnapshot.FailureStage.allCases.map { $0.rawValue })
    #expect(actual == expected)
  }

  /// AC #1: Gate.allCases.count == 2 (two-gate abstain per DD #10).
  @Test("Gate allCases count == 2")
  func gateAllCasesCount() throws {
    #expect(MLDiagnosticSnapshot.Gate.allCases.count == 2)
    let expected: Set<String> = ["gate1Softmax", "gate2Margin"]
    let actual = Set(MLDiagnosticSnapshot.Gate.allCases.map { $0.rawValue })
    #expect(actual == expected)
  }

  /// AC #1: equatable + hashable conformance (auto-derived, and still
  /// synthesized across the payload-carrying `Outcome`). The description
  /// format is unchanged by the restructure — it is built from the flat
  /// projections.
  @Test("equatableHashableDescription")
  func equatableHashableDescription() throws {
    let a = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x42,
      outcome: .win(.init(bpm: 128.0, softmaxMax: 0.72, softmaxSecondMax: 0.18)))
    let b = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x42,
      outcome: .win(.init(bpm: 128.0, softmaxMax: 0.72, softmaxSecondMax: 0.18)))
    let c = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x42,
      outcome: .win(.init(bpm: 129.0, softmaxMax: 0.72, softmaxSecondMax: 0.18)))
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
    #expect(a != c)
    // Description includes the stage label and is bounded.
    #expect(a.description.contains("win"))
    #expect(a.description.contains("128"))
    #expect(a.description.count < 200)
    // Abstain-path description includes the stage rawValue.
    let abstain = MLDiagnosticSnapshot(
      inputFeatureChecksum: 0x42, outcome: .featurizeRejected)
    #expect(abstain.description.contains("featurizeRejected"))
    #expect(abstain.description.count < 200)
  }
}
