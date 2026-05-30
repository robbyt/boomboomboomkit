//
//  EnsemblePolicyTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4.4 service-integration tests for `EnsemblePolicy`. Owns the
//  synthetic-fixture proofs (Task 5.5), the AC #14 short-circuit contract
//  (`RecordingMockMLTechnique.callCount`), the AC #13 trace-population
//  9-cell matrix (Task 6.5), the AC #10 / Task 6.1 decision-table artifact
//  generator, and the deterministic-harness sanity test (Task 6.5).
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - WAV writer helper (synthetic click track for service-grain tests)

private func writeClickTrackWAV(
  bpm: Double, sampleRate: Double, durationSeconds: Double, url: URL
) throws {
  let samples = generateClickTrack(
    bpm: bpm, sampleRate: sampleRate, durationSeconds: durationSeconds)
  guard
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false)
  else {
    throw NSError(
      domain: "EnsemblePolicyTests", code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Bad format"])
  }
  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  guard
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
  else {
    throw NSError(
      domain: "EnsemblePolicyTests", code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Buffer failed"])
  }
  buffer.frameLength = AVAudioFrameCount(samples.count)
  samples.withUnsafeBufferPointer { srcPtr in
    guard let base = srcPtr.baseAddress else { return }
    buffer.floatChannelData![0].update(from: base, count: samples.count)
  }
  try file.write(from: buffer)
}

private func makeSyntheticClickTrack() throws -> URL {
  // Per-call UUID-named temp file: Swift Testing runs suites in parallel by
  // default, so a shared `ensemble_policy_120bpm_15s.wav` would race two
  // suites in the `fileExists` → `AVAudioFile(forWriting:)` window. The
  // 15s click-track write is fast enough that per-call generation has
  // negligible cost relative to the analyzeBPM call that follows.
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("ensemble_policy_120bpm_15s_\(UUID().uuidString).wav")
  try writeClickTrackWAV(
    bpm: 120, sampleRate: 44100, durationSeconds: 15, url: url)
  return url
}

// MARK: - AC #14: short-circuit contract

@Suite("EnsemblePolicy — A1 short-circuit contract (Story 4.4 AC #14)")
struct EnsemblePolicyShortCircuitTests {

  /// AC #14: when `Options.ensemblePolicy = .dspOnly` AND
  /// `Options.mlTechnique = RecordingMockMLTechnique()`,
  /// `RecordingMockMLTechnique.callCount == 0` after `analyzeBPM` returns.
  /// This is the test-locked invariant that makes the A1 short-circuit a
  /// durable contract rather than prose.
  @Test("dspOnly + RecordingMock → callCount == 0 (ML inference does not run)")
  func dspOnlyDoesNotInvokeMLTechnique() throws {
    let url = try makeSyntheticClickTrack()
    let mock = RecordingMockMLTechnique()
    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .dspOnly
    opts.mlTechnique = mock

    _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(mock.callCount == 0)
  }

  /// AC #14: enabling the trace explicitly must NOT bypass the short-circuit.
  /// The user-facing trace and the ML-feeding trace are conceptually distinct
  /// concerns; under `.dspOnly` the ML branch is not invoked regardless.
  @Test("dspOnly + RecordingMock + enableTrace → callCount == 0 (trace flag does not bypass)")
  func dspOnlyDoesNotInvokeMLTechniqueWithEnableTrace() throws {
    let url = try makeSyntheticClickTrack()
    let mock = RecordingMockMLTechnique()
    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .dspOnly
    opts.mlTechnique = mock
    opts.enableTrace = true

    _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(mock.callCount == 0)
  }

  /// Story 6.5a: the new placeholder policies `.default` and `.weightedVoting`
  /// are fully operation-inert (no ML), matching the `invokesMLInference`
  /// contract — even with a non-nil `mlTechnique` AND `enableTrace`, ML inference
  /// does not run and no ML log-mel feature frames are captured into the trace.
  /// Locks the Story 6.5a fix that migrated the `captureMLFeatures` +
  /// Stage-2-pool predicates from `!= .dspOnly` to `invokesMLInference` (so the
  /// placeholder cases behave exactly like `.dspOnly` for all ML side effects).
  @Test("placeholder policies (.default / .weightedVoting) are operation-inert")
  func placeholderPoliciesAreOperationInert() throws {
    for policy: EnsemblePolicy in [.default, .weightedVoting(.default)] {
      let url = try makeSyntheticClickTrack()
      let mock = RecordingMockMLTechnique()
      var opts = AudioAnalysisService.Options()
      opts.ensemblePolicy = policy
      opts.mlTechnique = mock
      opts.enableTrace = true

      let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
      #expect(mock.callCount == 0, "ML must not run under \(policy.stableKey)")
      #expect(
        result?.trace?.mlFeatures == nil,
        "no ML feature capture under \(policy.stableKey)")
    }
  }

  /// AC #14 contrapositive: under `.mlOnly` the short-circuit must NOT fire.
  /// `RecordingMockMLTechnique.callCount == 1` proves `evaluate(trace:)` ran
  /// for the single window analysis. `capturedCandidatesAfterBoostCount > 0`
  /// adds a meaningful witness that the trace passed to `evaluate` was
  /// actually populated (rather than default-initialized) — without this
  /// the test cannot distinguish "evaluate called with empty trace" from
  /// "evaluate called with a real trace".
  @Test("mlOnly + RecordingMock → callCount == 1 (short-circuit fires only on .dspOnly)")
  func mlOnlyInvokesMLTechniqueOnce() throws {
    let url = try makeSyntheticClickTrack()
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .mlOnly
    opts.mlTechnique = mock
    opts.intensity = .fastest

    _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(mock.callCount == 1)
    #expect(
      (mock.capturedCandidatesAfterBoostCount ?? 0) > 0,
      "trace passed to evaluate must be populated, not default-initialized")
  }

  /// Negative trace-existence proof: under `.dspOnly` with `enableTrace=false`
  /// AND `mlTechnique != nil`, the internal `shouldBuildTrace` formula
  /// (`enableTrace || (mlTechnique != nil && policy != .dspOnly)`) collapses
  /// to `false` because the second clause is gated on `policy != .dspOnly`.
  /// No trace is built, ML.evaluate is not invoked, and `result.trace == nil`.
  /// Without this dedicated test the 9-cell matrix's `enableTrace=true`-only
  /// coverage cannot distinguish "trace built and decision == nil" from
  /// "trace not built at all".
  @Test("dspOnly + enableTrace=false + mlTechnique != nil → result.trace == nil")
  func dspOnlyNoTraceWhenEnableTraceFalse() throws {
    let url = try makeSyntheticClickTrack()
    let mock = RecordingMockMLTechnique()
    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .dspOnly
    opts.mlTechnique = mock
    opts.enableTrace = false

    let r = try #require(
      try? AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(r.trace == nil)
    #expect(mock.callCount == 0)
  }

  // AC #14 contrapositive for `.highestConfidence` is omitted: the spec
  // requires "policy ∈ {.mlOnly, .highestConfidence} → callCount == 1" via
  // any one of the two non-`.dspOnly` cases. The `mlOnlyInvokesMLTechniqueOnce`
  // test above proves the short-circuit fires ONLY on `.dspOnly`. The
  // `EnsemblePolicyTracePopulationTests` 9-cell matrix exercises
  // `.highestConfidence` end-to-end and would surface a regression in the
  // short-circuit gating.
}

// MARK: - AC #5: .dspOnly is inert with respect to ML output

@Suite("EnsemblePolicy — .dspOnly inertness (Story 4.4 AC #5)")
struct EnsemblePolicyDspOnlyInertnessTests {

  /// AC #5: setting `mlTechnique` to a sentinel-injecting mock under
  /// `.dspOnly` must produce byte-identical output to the no-ML path.
  /// Tested with two sentinel shapes: out-of-range bpm (999) and non-finite
  /// bpm (NaN). Either would visibly change `result.bpm` if the policy
  /// silently consulted ML.
  @Test("dspOnly + MockMLTechnique(bpm: 999) → bpm bitPattern matches no-ML baseline")
  func dspOnlyByteIdenticalUnderOutOfRangeSentinel() throws {
    let url = try makeSyntheticClickTrack()

    let baseline = try #require(
      try? AudioAnalysisService.analyzeBPM(url: url, options: AudioAnalysisService.Options()))

    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .dspOnly
    opts.mlTechnique = MockMLTechnique(
      returning: MLEvaluation(bpm: 999.0, confidence: 1.0))
    let result = try #require(
      try? AudioAnalysisService.analyzeBPM(url: url, options: opts))

    #expect(result.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(result.confidence.bitPattern == baseline.confidence.bitPattern)
    #expect(result.candidates.count == baseline.candidates.count)
    for (lhs, rhs) in zip(result.candidates, baseline.candidates) {
      #expect(lhs.bpm.bitPattern == rhs.bpm.bitPattern)
      #expect(lhs.score.bitPattern == rhs.score.bitPattern)
    }
  }

  @Test("dspOnly + MockMLTechnique(bpm: NaN) → bpm bitPattern matches no-ML baseline")
  func dspOnlyByteIdenticalUnderNaNSentinel() throws {
    let url = try makeSyntheticClickTrack()

    let baseline = try #require(
      try? AudioAnalysisService.analyzeBPM(url: url, options: AudioAnalysisService.Options()))

    var opts = AudioAnalysisService.Options()
    opts.ensemblePolicy = .dspOnly
    opts.mlTechnique = MockMLTechnique(
      returning: MLEvaluation(bpm: .nan, confidence: 1.0))
    let result = try #require(
      try? AudioAnalysisService.analyzeBPM(url: url, options: opts))

    #expect(result.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(result.confidence.bitPattern == baseline.confidence.bitPattern)
  }
}

// MARK: - AC #13: trace.ensembleDecision population matrix (Task 6.5)

@Suite("EnsemblePolicy — trace.ensembleDecision population (AC #13, Task 6.5)")
struct EnsemblePolicyTracePopulationTests {

  /// AC #13: validates the 9-cell matrix `3 policies × {nil mlTechnique,
  /// evaluate returned nil, evaluate returned non-nil}`. Single rule:
  /// `ensembleDecision != nil` iff `MLTechnique.evaluate(trace:)` returned
  /// a non-nil `MLEvaluation`. Plus the `selectedBPM == result.bpm`
  /// invariant for every non-nil decision.
  @Test("9-cell trace.ensembleDecision matrix")
  func traceEnsembleDecisionPopulated() throws {
    let url = try makeSyntheticClickTrack()
    let policies: [EnsemblePolicy] = [.dspOnly, .mlOnly, .highestConfidence]

    for policy in policies {
      // Cell A: nil mlTechnique → decision == nil regardless of policy.
      do {
        var opts = AudioAnalysisService.Options()
        opts.ensemblePolicy = policy
        opts.mlTechnique = nil
        opts.enableTrace = true
        opts.intensity = .fastest
        let r = try #require(
          try? AudioAnalysisService.analyzeBPM(url: url, options: opts))
        #expect(
          r.trace?.ensembleDecision == nil,
          "policy=\(policy), mlTechnique=nil should produce nil decision")
      }

      // Cell B: mlTechnique present, evaluate returns nil → decision == nil.
      do {
        var opts = AudioAnalysisService.Options()
        opts.ensemblePolicy = policy
        opts.mlTechnique = MockMLTechnique()  // abstain
        opts.enableTrace = true
        opts.intensity = .fastest
        let r = try #require(
          try? AudioAnalysisService.analyzeBPM(url: url, options: opts))
        #expect(
          r.trace?.ensembleDecision == nil,
          "policy=\(policy), evaluate=nil should produce nil decision")
      }

      // Cell C: mlTechnique present, evaluate returns non-nil →
      //         under .dspOnly: evaluate is short-circuited, decision == nil.
      //         under .mlOnly / .highestConfidence: decision != nil.
      do {
        var opts = AudioAnalysisService.Options()
        opts.ensemblePolicy = policy
        opts.mlTechnique = MockMLTechnique(
          returning: MLEvaluation(bpm: 128.0, confidence: 0.92))
        opts.enableTrace = true
        opts.intensity = .fastest
        let r = try #require(
          try? AudioAnalysisService.analyzeBPM(url: url, options: opts))

        if policy == .dspOnly {
          #expect(
            r.trace?.ensembleDecision == nil,
            ".dspOnly short-circuits evaluate; decision must be nil")
        } else {
          let d = try #require(r.trace?.ensembleDecision)
          #expect(d.policy == policy)
          #expect(
            d.selectedBPM.bitPattern == r.bpm.bitPattern,
            "selectedBPM must equal result.bpm under \(policy)")
        }
      }
    }
  }
}

// MARK: - AC #10 + Task 6.1: 4-4 decision-table artifact

private struct DspBlock44: Codable {
  let bpm: Double
  let conf: Double
}
private struct MlBlock44: Codable {
  let bpm: Double
  let conf: Double
}
private struct EnsembleBlock44: Codable {
  let bpm: Double
  let source: String
  let reason: String
}

private struct DecisionTableRow44: Encodable {
  let policy: String
  let `case`: String
  let dsp: DspBlock44
  let ml: MlBlock44?
  let ensemble: EnsembleBlock44

  private enum CodingKeys: String, CodingKey {
    case policy, `case`, dsp, ml, ensemble
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.policy, forKey: .policy)
    try container.encode(self.case, forKey: .case)
    try container.encode(self.dsp, forKey: .dsp)
    try container.encode(self.ml, forKey: .ml)  // emits null when nil
    try container.encode(self.ensemble, forKey: .ensemble)
  }
}

@Suite("EnsemblePolicy — 4-4 decision-table artifact (AC #10, Task 6.1)")
struct EnsemblePolicyDecisionTableTests {

  /// Task 6.1: emit `_bmad-output/implementation-artifacts/4-4-ensemble-policy-decision-table.json`
  /// covering 5 policies × 4 outcome cases (20 rows; Story 6.5a grew the
  /// `EnsemblePolicy` facade from 3 to 5 cases). JSON is byte-stable
  /// (`.prettyPrinted` + `.sortedKeys`); the test runs on every `make test`
  /// so the artifact is always reproducible.
  @Test("decisionTableArtifactWritesValidJSON — 20 rows, .prettyPrinted + .sortedKeys")
  func decisionTableArtifactWritesValidJSON() throws {
    struct Outcome {
      let name: String
      let dsp: (bpm: Double, conf: Double)
      let ml: (bpm: Double, conf: Double)?
    }

    let outcomes: [Outcome] = [
      Outcome(name: "ml_nil", dsp: (bpm: 120.0, conf: 0.9), ml: nil),
      Outcome(
        name: "ml_agrees_high_conf",
        dsp: (bpm: 120.0, conf: 0.7), ml: (bpm: 120.0, conf: 0.95)),
      Outcome(
        name: "ml_disagrees_low_conf",
        dsp: (bpm: 120.0, conf: 0.9), ml: (bpm: 60.0, conf: 0.4)),
      Outcome(
        name: "ml_disagrees_high_conf",
        dsp: (bpm: 120.0, conf: 0.7), ml: (bpm: 60.0, conf: 0.95)),
    ]

    var rows: [DecisionTableRow44] = []
    for policy in EnsemblePolicy.allPolicies {
      for outcome in outcomes {
        let dspResult = BPMResult(
          bpm: outcome.dsp.bpm, confidence: outcome.dsp.conf,
          candidates: [(bpm: outcome.dsp.bpm, score: Float(outcome.dsp.conf))],
          trace: BPMDiagnosticTrace())
        let mlEval = outcome.ml.map {
          MLEvaluation(bpm: $0.bpm, confidence: $0.conf)
        }
        let combined = AudioAnalysisService.combineEnsemble(
          dspWinner: dspResult, mlEvaluation: mlEval, policy: policy)

        let decision = combined.trace?.ensembleDecision
        let source: String = {
          guard let d = decision else { return "dsp" }
          switch d.winner {
          case .dsp, .tie: return "dsp"
          case .ml: return "ml"
          }
        }()
        let reason: String = {
          if outcome.ml == nil { return "protocol_abstain" }
          if decision == nil {
            // All operation-inert policies (.dspOnly, .default, .weightedVoting)
            // short-circuit before ML and attach no decision; label them by key
            // so the artifact distinguishes a policy short-circuit from a genuine
            // ML abstain.
            return !policy.invokesMLInference
              ? "policy_\(policy.stableKey)_short_circuit" : "no_decision"
          }
          return "policy_\(policy.stableKey)_\(decision!.winner.rawValue)"
        }()

        rows.append(
          DecisionTableRow44(
            policy: policy.stableKey,
            case: outcome.name,
            dsp: DspBlock44(bpm: outcome.dsp.bpm, conf: outcome.dsp.conf),
            ml: outcome.ml.map { MlBlock44(bpm: $0.bpm, conf: $0.conf) },
            ensemble: EnsembleBlock44(
              bpm: combined.bpm, source: source, reason: reason)))
      }
    }

    #expect(rows.count == 20, "expected 5 policies × 4 outcomes = 20 rows")

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let json = try encoder.encode(rows)

    let target = artifactDestination()
    try json.write(to: target)
    print("4-4-ensemble-policy-decision-table.json -> \(target.path)")
  }

  /// Task 6.5: the ensemble policy sweep is deterministic — two consecutive
  /// invocations against the same inputs produce byte-identical JSON
  /// output. Tiny synthetic fixture set (no corpus needed) so this runs on
  /// every `make test`.
  @Test("policySweepHarnessIsDeterministic — two runs produce byte-identical JSON")
  func policySweepHarnessIsDeterministic() throws {
    func runOnce() throws -> Data {
      let dsp = BPMResult(
        bpm: 120.0, confidence: 0.7,
        candidates: [(bpm: 120.0, score: 0.7)],
        trace: BPMDiagnosticTrace())
      var rows: [DecisionTableRow44] = []
      for policy in EnsemblePolicy.allPolicies {
        let combined = AudioAnalysisService.combineEnsemble(
          dspWinner: dsp,
          mlEvaluation: MLEvaluation(bpm: 128.0, confidence: 0.92),
          policy: policy)
        let source: String =
          combined.trace?.ensembleDecision?.winner.rawValue
          ?? "dsp"
        rows.append(
          DecisionTableRow44(
            policy: policy.stableKey, case: "fixture",
            dsp: DspBlock44(bpm: 120.0, conf: 0.7),
            ml: MlBlock44(bpm: 128.0, conf: 0.92),
            ensemble: EnsembleBlock44(
              bpm: combined.bpm, source: source, reason: "fixture")))
      }
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      return try encoder.encode(rows)
    }

    let first = try runOnce()
    let second = try runOnce()
    #expect(first == second, "deterministic harness must produce byte-identical output")
  }

  /// Resolve the implementation-artifacts directory by walking up from the
  /// CWD. Falls back to `$TMPDIR` when the project layout is not detected.
  private func artifactDestination() -> URL {
    let fileName = "4-4-ensemble-policy-decision-table.json"
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
