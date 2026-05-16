//
//  MLDiagnosticSnapshotPathCoverageTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 AC #3 + code review P14: parameterized coverage of all 7
//  paths (6 failure stages + win) end-to-end through
//  `AudioAnalysisService.evaluateMLIfActive`. Model-independent — uses
//  a synthetic `MLDiagnosticTechnique` mock so the suite runs on every
//  build regardless of bundled-model state (Branch C absent-bundle
//  builds exercise these same code paths).
//
//  `BNNSTechniqueDiagnosticTests` covers a subset of these stages
//  against the real `BNNSTechnique` (when a bundle is available); this
//  file covers the FULL 7-path matrix without depending on a bundled
//  model — proving the trace-attachment wiring works regardless of
//  which conformer produced the snapshot.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("ML diagnostic snapshot trace-attachment path coverage (Story 4-6 AC #3 + P14)")
struct MLDiagnosticSnapshotPathCoverageTests {

  /// Synthetic `MLDiagnosticTechnique` returning canned `(evaluation,
  /// snapshot)` pairs per parameterized case.
  private struct CannedMLDiagnosticTechnique: MLDiagnosticTechnique {
    let evaluation: MLEvaluation?
    let snapshot: MLDiagnosticSnapshot?

    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { evaluation }
    func evaluateWithDiagnostic(
      trace: BPMDiagnosticTrace
    ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
      (evaluation, snapshot)
    }
  }

  /// Parameter-bundle for the 9-case path matrix. The 7 paths AC #3
  /// names map to 9 distinct snapshot shapes once the
  /// `confidenceGateRejected × {gate1Softmax, gate2Margin}` sub-cases
  /// are expanded, plus the win path.
  struct PathCase: Sendable, CustomStringConvertible {
    let label: String
    let evaluation: MLEvaluation?
    let snapshot: MLDiagnosticSnapshot?
    let expectedFailureStage: MLDiagnosticSnapshot.FailureStage?
    let expectedGate: MLDiagnosticSnapshot.Gate?
    var description: String { label }
  }

  /// All 9 parameterized cases. The pre-featurize abstains return
  /// `(nil, nil)` from the conformer (per the protocol's tuple
  /// invariant) so the trace's `mlDiagnosticSnapshot` stays nil; for
  /// every other case the snapshot must round-trip onto the trace
  /// unchanged.
  static let allPathCases: [PathCase] = {
    // Stage 1+2: pre-featurize abstains return (nil, nil). The
    // service propagates the nil snapshot to the trace.
    let preFeaturizeCases: [PathCase] = [
      PathCase(
        label: "featuresAbsent (pre-featurize abstain, conformer returns (nil, nil))",
        evaluation: nil,
        snapshot: nil,
        expectedFailureStage: nil,
        expectedGate: nil),
      PathCase(
        label: "featureVersionMismatch (pre-featurize abstain, conformer returns (nil, nil))",
        evaluation: nil,
        snapshot: nil,
        expectedFailureStage: nil,
        expectedGate: nil),
    ]
    // Stage 3-6 + win: snapshots constructed per the population matrix.
    let postFeaturizeCases: [PathCase] = [
      PathCase(
        label: "featurizeRejected",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: 0x1111_1111_1111_1111,
          failureStage: .featurizeRejected,
          gateFired: nil),
        expectedFailureStage: .featurizeRejected,
        expectedGate: nil),
      PathCase(
        label: "graphFailed",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: 0x2222_2222_2222_2222,
          failureStage: .graphFailed,
          gateFired: nil),
        expectedFailureStage: .graphFailed,
        expectedGate: nil),
      PathCase(
        label: "decodeRejected (non-finite logits, decode fields nil)",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: 0x3333_3333_3333_3333,
          failureStage: .decodeRejected,
          gateFired: nil),
        expectedFailureStage: .decodeRejected,
        expectedGate: nil),
      PathCase(
        label: "decodeRejected (out-of-range argmax, raw BPM carried)",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: 215.0,  // out-of-range — exceeds 200 upper bound
          softmaxMax: 0.42,
          softmaxSecondMax: 0.18,
          inputFeatureChecksum: 0x4444_4444_4444_4444,
          failureStage: .decodeRejected,
          gateFired: nil),
        expectedFailureStage: .decodeRejected,
        expectedGate: nil),
      PathCase(
        label: "confidenceGateRejected × gate1Softmax (softmax-max below threshold)",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: 128.0,
          softmaxMax: 0.30,
          softmaxSecondMax: 0.05,
          inputFeatureChecksum: 0x5555_5555_5555_5555,
          failureStage: .confidenceGateRejected,
          gateFired: .gate1Softmax),
        expectedFailureStage: .confidenceGateRejected,
        expectedGate: .gate1Softmax),
      PathCase(
        label: "confidenceGateRejected × gate2Margin (margin below threshold)",
        evaluation: nil,
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: 128.0,
          softmaxMax: 0.55,
          softmaxSecondMax: 0.50,
          inputFeatureChecksum: 0x6666_6666_6666_6666,
          failureStage: .confidenceGateRejected,
          gateFired: .gate2Margin),
        expectedFailureStage: .confidenceGateRejected,
        expectedGate: .gate2Margin),
      PathCase(
        label: "win (failureStage nil, all decode fields populated)",
        evaluation: MLEvaluation(
          bpm: 128.0, confidence: 0.85, modelIdentifier: "mock"),
        snapshot: MLDiagnosticSnapshot(
          decodedBPM: 128.0,
          softmaxMax: 0.85,
          softmaxSecondMax: 0.08,
          inputFeatureChecksum: 0x7777_7777_7777_7777,
          failureStage: nil,
          gateFired: nil),
        expectedFailureStage: nil,
        expectedGate: nil),
    ]
    return preFeaturizeCases + postFeaturizeCases
  }()

  /// AC #3 last clause: parameterized unit test locks the
  /// trace-attachment contract for all 7 paths.
  ///
  /// Each case constructs a `(evaluation, snapshot)` pair, runs the
  /// service against a fixture that DSP can resolve, and asserts the
  /// snapshot round-trips onto `trace.mlDiagnosticSnapshot`. For
  /// pre-featurize cases (conformer returns nil snapshot), the trace
  /// field must be nil. For every other case, the trace field must
  /// equal the input snapshot.
  @Test("path coverage — 9 cases × trace-attachment round-trip", arguments: allPathCases)
  func tracePropagatesSnapshotForPath(_ pathCase: PathCase) throws {
    let fixtureURL = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let mock = CannedMLDiagnosticTechnique(
      evaluation: pathCase.evaluation, snapshot: pathCase.snapshot)

    var opts = AudioAnalysisService.Options()
    opts.intensity = .thorough  // engages ML path at intensity 8
    opts.ensemblePolicy = .mlOnly
    opts.enableTrace = true
    opts.enableMLDiagnostics = true
    opts.mlTechnique = mock

    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: fixtureURL, options: opts),
      "DSP should resolve bpm-120-click — \(pathCase.label)")
    let trace = try #require(
      result.trace,
      "Trace should be returned with enableTrace=true — \(pathCase.label)")

    if let expected = pathCase.snapshot {
      let attached = try #require(
        trace.mlDiagnosticSnapshot,
        "Expected snapshot to round-trip onto trace — \(pathCase.label)")
      #expect(attached == expected)
      #expect(attached.failureStage == pathCase.expectedFailureStage)
      #expect(attached.gateFired == pathCase.expectedGate)
    } else {
      let preFeaturizeMsg =
        "Pre-featurize abstain conformers return nil "
        + "snapshot — trace field must stay nil for \(pathCase.label)"
      #expect(
        trace.mlDiagnosticSnapshot == nil,
        Comment(rawValue: preFeaturizeMsg))
    }
  }
}
