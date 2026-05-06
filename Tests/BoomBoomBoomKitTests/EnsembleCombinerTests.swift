//
//  EnsembleCombinerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4.3 unit tests for AudioAnalysisService.combine(dspWinner:mlEvaluation:).
//  See spec _bmad-output/implementation-artifacts/4-3-...md AC #3, #4, #5, #9.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Equality helper

/// Compare two `BPMResult`s for byte-identity per the Epic 4 Definition
/// (epics.md:766: `Double.bitPattern` equality on `bpm` and `confidence`,
/// element-wise on `candidates`). `BPMResult` is NOT `Equatable` because its
/// `candidates: [(bpm, score)]` is a labeled-tuple array — `Sendable`
/// structurally per SE-0302, but `Equatable`/`Hashable`/`Codable` synthesis
/// requires nominal types. This free helper centralizes the bit-pattern
/// comparison across all 4 unit tests in this file.
private func equalByBitPattern(_ a: BPMResult, _ b: BPMResult) -> Bool {
  guard a.bpm.bitPattern == b.bpm.bitPattern else { return false }
  guard a.confidence.bitPattern == b.confidence.bitPattern else { return false }
  guard a.candidates.count == b.candidates.count else { return false }
  for (lhs, rhs) in zip(a.candidates, b.candidates) {
    if lhs.bpm.bitPattern != rhs.bpm.bitPattern { return false }
    if lhs.score.bitPattern != rhs.score.bitPattern { return false }
  }
  return true
}

private func makeFixture(
  bpm: Double = 120.0,
  confidence: Double = 0.9,
  candidates: [(bpm: Double, score: Float)] = [(bpm: 120.0, score: 0.9), (bpm: 60.0, score: 0.4)]
) -> BPMResult {
  BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: nil)
}

// MARK: - Suite

@Suite("EnsembleCombiner — Story 4.3 default policy (DSP wins regardless)")
struct EnsembleCombinerTests {

  /// AC #3: when `mlEvaluation == nil`, combine returns the DSP winner unchanged.
  @Test("combine returns DSP winner when mlEvaluation is nil")
  func combineReturnsDSPWinnerWhenMLEvaluationNil() {
    let dsp = makeFixture()
    let result = AudioAnalysisService.combine(dspWinner: dsp, mlEvaluation: nil)
    #expect(equalByBitPattern(result, dsp))
  }

  /// DD #5: ML agrees with DSP — default policy still returns DSP winner unchanged.
  @Test("combine returns DSP winner when mlEvaluation agrees")
  func combineReturnsDSPWinnerWhenMLEvaluationAgrees() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 120.0, confidence: 0.85)
    let result = AudioAnalysisService.combine(dspWinner: dsp, mlEvaluation: ml)
    #expect(equalByBitPattern(result, dsp))
  }

  /// DD #5: ML disagrees with low confidence — default policy returns DSP winner.
  @Test("combine returns DSP winner when mlEvaluation disagrees with low confidence")
  func combineReturnsDSPWinnerWhenMLEvaluationDisagreesLowConf() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.4)
    let result = AudioAnalysisService.combine(dspWinner: dsp, mlEvaluation: ml)
    #expect(equalByBitPattern(result, dsp))
  }

  /// DD #5: ML disagrees with HIGH confidence — default policy STILL returns
  /// DSP winner (the canonical "DSP wins regardless" invariant; Story 4.4's
  /// `EnsemblePolicy` enum is what introduces ML-can-overrule cases).
  @Test("combine returns DSP winner when mlEvaluation disagrees with high confidence")
  func combineReturnsDSPWinnerWhenMLEvaluationDisagreesHighConf() {
    let dsp = makeFixture()
    let ml = MLEvaluation(bpm: 60.0, confidence: 0.95)
    let result = AudioAnalysisService.combine(dspWinner: dsp, mlEvaluation: ml)
    #expect(equalByBitPattern(result, dsp))
  }
}

// MARK: - Decision-Table Artifact Schema (AC #9)

/// Codable schema for the decision-table artifact rows. Replaces hand-built
/// JSON string interpolation (Story 4.3 review patch 2026-05-05): manual
/// interpolation was unsafe against quote/backslash in case names and would
/// emit `nan`/`inf` for non-finite Doubles (invalid JSON). Lifted to
/// file-private scope to keep nesting under SwiftLint's 1-level limit.
private struct DspBlock: Codable {
  let bpm: Double
  let conf: Double
}
private struct MlBlock: Codable {
  let bpm: Double
  let conf: Double
}
private struct EnsembleBlock: Codable {
  let bpm: Double
  let source: String
  let reason: String
}

/// Custom `Encodable` to force `"ml": null` emission for the abstain row
/// (default synthesized memberwise `encode(to:)` uses `encodeIfPresent`
/// which OMITS the key for nil Optionals — but AC #9's schema example
/// shows `"ml": null` and downstream Story 4.4 readers expect a uniform
/// schema across rows). Per Codex final pre-commit review 2026-05-05.
private struct DecisionTableRow: Encodable {
  let `case`: String
  let dsp: DspBlock
  let ml: MlBlock?
  let ensemble: EnsembleBlock

  private enum CodingKeys: String, CodingKey {
    case `case`, dsp, ml, ensemble
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.case, forKey: .case)
    try container.encode(self.dsp, forKey: .dsp)
    try container.encode(self.ml, forKey: .ml)  // emits null when nil
    try container.encode(self.ensemble, forKey: .ensemble)
  }
}

@Suite("EnsembleCombiner — Decision Table")
struct EnsembleCombinerDecisionTableTests {

  /// AC #9: emits `_bmad-output/implementation-artifacts/4-3-mock-ensemble-trace.json`
  /// proving combine wiring across 5 deterministic synthetic cases. Per Task 6.3,
  /// pattern (b) is used: combine called directly with synthetic BPMResult
  /// fixtures; pipeline-integration wiring is proven by the RecordingMock
  /// callsite test in `MLTechniqueSlotTests` (AC #4).
  @Test("decision table emits 4-3-mock-ensemble-trace.json")
  func decisionTableEmitsArtifact() throws {
    struct Case {
      let name: String
      let dsp: (bpm: Double, conf: Double)
      let ml: (bpm: Double, conf: Double)?
    }

    let cases: [Case] = [
      Case(
        name: "ml_abstains",
        dsp: (bpm: 120.0, conf: 0.9), ml: nil),
      Case(
        name: "ml_agrees",
        dsp: (bpm: 120.0, conf: 0.9), ml: (bpm: 120.0, conf: 0.85)),
      Case(
        name: "ml_disagrees_low_conf",
        dsp: (bpm: 120.0, conf: 0.9), ml: (bpm: 60.0, conf: 0.4)),
      Case(
        name: "ml_disagrees_high_conf",
        dsp: (bpm: 120.0, conf: 0.9), ml: (bpm: 60.0, conf: 0.95)),
      Case(
        name: "ml_disagrees_dsp_low_conf",
        dsp: (bpm: 120.0, conf: 0.4), ml: (bpm: 60.0, conf: 0.95)),
    ]

    // Schema types lifted to file-scope (DspBlock, MlBlock, EnsembleBlock,
    // DecisionTableRow) per SwiftLint nesting limit; see top of file.
    var rows: [DecisionTableRow] = []
    for c in cases {
      let dspResult = BPMResult(
        bpm: c.dsp.bpm, confidence: c.dsp.conf,
        candidates: [(bpm: c.dsp.bpm, score: Float(c.dsp.conf))],
        trace: nil)
      let mlEval = c.ml.map { MLEvaluation(bpm: $0.bpm, confidence: $0.conf) }
      let combined = AudioAnalysisService.combine(
        dspWinner: dspResult, mlEvaluation: mlEval)

      // Sanity: default policy preserves DSP. Asserted byte-by-byte so a
      // future combine-policy regression that flipped the decision table to
      // ML-wins would break this artifact-emission test BEFORE merge.
      #expect(combined.bpm.bitPattern == c.dsp.bpm.bitPattern)
      #expect(combined.confidence.bitPattern == c.dsp.conf.bitPattern)

      let reason = c.ml == nil ? "ml_abstains" : "default_dsp_policy_v0"
      rows.append(
        DecisionTableRow(
          case: c.name,
          dsp: DspBlock(bpm: c.dsp.bpm, conf: c.dsp.conf),
          ml: c.ml.map { MlBlock(bpm: $0.bpm, conf: $0.conf) },
          ensemble: EnsembleBlock(bpm: combined.bpm, source: "dsp", reason: reason)))
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let json = try encoder.encode(rows)

    // Write artifact (best-effort; if we can't locate the implementation-artifacts
    // dir we fall back to the OS temp dir and print the path so devs can copy).
    let target = artifactDestination()
    try json.write(to: target)
    print("4-3-mock-ensemble-trace.json -> \(target.path)")
  }

  /// Resolve the implementation-artifacts directory by walking up from the
  /// CWD. The test target's `Bundle.module` resources don't permit writing,
  /// so we use the project layout convention. Falls back to the OS temp dir
  /// if no `_bmad-output/implementation-artifacts` is found above CWD.
  private func artifactDestination() -> URL {
    let fileName = "4-3-mock-ensemble-trace.json"
    let cwd = FileManager.default.currentDirectoryPath
    var dir = URL(fileURLWithPath: cwd, isDirectory: true)
    for _ in 0..<8 {
      let candidate =
        dir
        .appendingPathComponent("_bmad-output", isDirectory: true)
        .appendingPathComponent("implementation-artifacts", isDirectory: true)
      var isDir: ObjCBool = false
      if FileManager.default.fileExists(
        atPath: candidate.path, isDirectory: &isDir), isDir.boolValue
      {
        return candidate.appendingPathComponent(fileName)
      }
      dir.deleteLastPathComponent()
    }
    return FileManager.default.temporaryDirectory
      .appendingPathComponent(fileName)
  }
}
