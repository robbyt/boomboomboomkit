//
//  MLDiagnosticSnapshotTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 Task 10 + AC #1: shape rules, CaseIterable witnesses,
//  equality, and description bounding for the public typed-evidence
//  snapshot introduced by Story 4-6.
//

import BoomBoomBoomKit
import Foundation
import Testing

@Suite("MLDiagnosticSnapshot (Story 4-6 AC #1)")
struct MLDiagnosticSnapshotTests {

  /// AC #1: win path requires all decode fields populated, failureStage
  /// nil, gateFired nil. Confirms the init's preconditions for the
  /// happy path.
  @Test("initShapeRulesWinPath")
  func initShapeRulesWinPath() throws {
    let snapshot = MLDiagnosticSnapshot(
      decodedBPM: 128.0,
      softmaxMax: 0.72,
      softmaxSecondMax: 0.18,
      inputFeatureChecksum: 0xDEAD_BEEF,
      failureStage: nil,
      gateFired: nil)
    #expect(snapshot.failureStage == nil)
    #expect(snapshot.decodedBPM == 128.0)
    #expect(snapshot.softmaxMax == 0.72)
    #expect(snapshot.softmaxSecondMax == 0.18)
    #expect(snapshot.inputFeatureChecksum == 0xDEAD_BEEF)
    #expect(snapshot.gateFired == nil)
  }

  /// AC #1 / DD #2: per-decode-stage snapshot shape. `featurizeRejected`
  /// has only inputFeatureChecksum populated (decode fields all nil);
  /// `graphFailed` is identical in shape. `decodeRejected` may have
  /// decode fields nil (non-finite logits) or populated (out-of-range
  /// argmax) — covered by the second case below.
  @Test("initShapeRulesPreDecodeAbstain")
  func initShapeRulesPreDecodeAbstain() throws {
    for stage in [
      MLDiagnosticSnapshot.FailureStage.featurizeRejected,
      MLDiagnosticSnapshot.FailureStage.graphFailed,
    ] {
      let snapshot = MLDiagnosticSnapshot(
        decodedBPM: nil,
        softmaxMax: nil,
        softmaxSecondMax: nil,
        inputFeatureChecksum: 0x42,
        failureStage: stage,
        gateFired: nil)
      #expect(snapshot.failureStage == stage)
      #expect(snapshot.decodedBPM == nil)
      #expect(snapshot.softmaxMax == nil)
      #expect(snapshot.softmaxSecondMax == nil)
      #expect(snapshot.gateFired == nil)
    }
  }

  /// AC #1: confidenceGateRejected requires all decode fields populated
  /// AND non-nil gateFired.
  @Test("initShapeRulesPostDecodeAbstain")
  func initShapeRulesPostDecodeAbstain() throws {
    let snapshot = MLDiagnosticSnapshot(
      decodedBPM: 113.0,
      softmaxMax: 0.42,
      softmaxSecondMax: 0.40,
      inputFeatureChecksum: 0x01,
      failureStage: .confidenceGateRejected,
      gateFired: .gate1Softmax)
    #expect(snapshot.failureStage == .confidenceGateRejected)
    #expect(snapshot.gateFired == .gate1Softmax)
    #expect(snapshot.decodedBPM == 113.0)
  }

  /// AC #1: FailureStage.allCases.count == 6 (architecture invariant
  /// per DD #2; `inferenceFailed` split into `graphFailed` + `decodeRejected`).
  @Test("FailureStage allCases count == 6")
  func failureStageAllCasesCount() throws {
    #expect(MLDiagnosticSnapshot.FailureStage.allCases.count == 6)
    let expected: Set<String> = [
      "featuresAbsent",
      "featureVersionMismatch",
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

  /// AC #1: equatable + hashable conformance (auto-derived). Two
  /// snapshots with identical field values are equal and hash to the
  /// same value; a difference in any field breaks equality. The
  /// description is bounded under 200 chars and includes the stage
  /// label + decoded BPM.
  @Test("equatableHashableDescription")
  func equatableHashableDescription() throws {
    let a = MLDiagnosticSnapshot(
      decodedBPM: 128.0, softmaxMax: 0.72, softmaxSecondMax: 0.18,
      inputFeatureChecksum: 0x42, failureStage: nil, gateFired: nil)
    let b = MLDiagnosticSnapshot(
      decodedBPM: 128.0, softmaxMax: 0.72, softmaxSecondMax: 0.18,
      inputFeatureChecksum: 0x42, failureStage: nil, gateFired: nil)
    let c = MLDiagnosticSnapshot(
      decodedBPM: 129.0, softmaxMax: 0.72, softmaxSecondMax: 0.18,
      inputFeatureChecksum: 0x42, failureStage: nil, gateFired: nil)
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
    #expect(a != c)
    // Description includes the stage label and is bounded.
    #expect(a.description.contains("win"))
    #expect(a.description.contains("128"))
    #expect(a.description.count < 200)
    // Abstain-path description includes the stage rawValue.
    let abstain = MLDiagnosticSnapshot(
      decodedBPM: nil, softmaxMax: nil, softmaxSecondMax: nil,
      inputFeatureChecksum: 0x42, failureStage: .featurizeRejected,
      gateFired: nil)
    #expect(abstain.description.contains("featurizeRejected"))
    #expect(abstain.description.count < 200)
  }
}
