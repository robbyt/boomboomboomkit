//
//  BNNSTechniqueDiagnosticTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 Task 10 + AC #3: parameterized coverage of diagnostic stages
//  via `MLDiagnosticTechnique.evaluateWithDiagnostic(trace:)`.
//
//  PR #2 round 2 (N5/N6): construction now goes through the committed
//  `Fixtures/CustomBundled.mlmodelc` fixture (a runnable graph captured
//  from the historical giantsteps_v1 checkpoint, retained in
//  `Tests/BoomBoomBoomKitTests/Fixtures/` after Story 4-6 Branch C pulled
//  the bundle from `Sources/`). The previous gate on
//  `BNNSTechnique.bundledReferenceURL == nil` skipped this entire suite
//  under Branch C builds, hiding the diagnostic-path coverage that
//  doesn't actually need a trained model — it only needs a successfully-
//  constructed `BNNSTechnique`. The fixture validates the graph contract
//  (256 BPM bins, "input"/"output" tensor names) at init time; it does
//  NOT validate trained-model semantics (decode/gate/win value
//  assertions remain a future follow-up if/when a higher-quality model
//  returns to the main-bound path).
//

import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

/// Resolves the bundled-with-tests `CustomBundled.mlmodelc` fixture URL.
/// `.mlmodelc` is a directory, not a file, so `Bundle.module.url(for…)`
/// (which targets files) can't be used; the canonical pattern is the one
/// established by `BNNSTechniqueTests.swift` — build from
/// `Bundle.module.resourceURL`. Returns nil if the resourceURL itself is
/// missing (off-build-system access path); under normal `swift test` /
/// `make test` invocations this is never nil.
@available(macOS 15.0, *)
private func fixtureURL() -> URL? {
  guard let resourceURL = Bundle.module.resourceURL else { return nil }
  let url =
    resourceURL
    .appendingPathComponent("Fixtures")
    .appendingPathComponent("CustomBundled.mlmodelc")
  return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

/// Suite-level `.disabled(if:)` predicate. Returns `true` only when the
/// committed fixture is unreachable — under `swift test` / `make test`
/// it never fires and the suite runs.
@available(macOS 15.0, *)
private func fixtureMissing() -> Bool {
  fixtureURL() == nil
}

@Suite(
  "BNNSTechnique diagnostic paths (Story 4-6 AC #3 / PR #2 N5)",
  .disabled(if: { if #available(macOS 15.0, *) { fixtureMissing() } else { true } }())
)
struct BNNSTechniqueDiagnosticTests {

  /// Story 4-6 Task 4.5 mapping case 1+2: pre-featurize abstain paths
  /// return `(nil, nil)` from `evaluateWithDiagnostic` — no snapshot
  /// constructed because no feature payload was checksummed.
  @Test(
    "preFeaturizeAbstain returns (nil, nil)",
    arguments: PreFeaturizeAbstainCase.allCases)
  func preFeaturizeAbstain(_ caseArg: PreFeaturizeAbstainCase) throws {
    if #available(macOS 15.0, *) {
      // Suite-level `.disabled(if:)` guards the no-fixture path;
      // `try #require` treats a still-failing init as a real bug rather
      // than an Issue.record-as-skip anti-pattern (Story 4-6 P4).
      let url = try #require(fixtureURL())
      let bnns = try BNNSTechnique(modelURL: url)
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = caseArg.makeFeatures()
      let result = bnns.evaluateWithDiagnostic(trace: trace)
      #expect(result.evaluation == nil)
      #expect(result.snapshot == nil)
    }
  }

  /// Story 4-6 Task 4.5 mapping case 3: featurize rejects the input
  /// (frame count < 32 — DD #9 short-clip guard). Snapshot has only
  /// `inputFeatureChecksum` populated; decode fields nil.
  @Test("featurizeRejected populates snapshot with checksum only")
  func featurizeRejected() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let bnns = try BNNSTechnique(modelURL: url)
      var trace = BPMDiagnosticTrace()
      // 16 frames < 32 frame DD #9 guard → featurize returns nil.
      trace.mlFeatures = try MLFeatureFrames(
        melBands: 128,
        frames: 16,
        tensorLayout: .frameMajorLogMel,
        logMelData: [Float](repeating: 0.1, count: 128 * 16),
        sampleRate: 44100.0,
        fftSize: 2048,
        hopSize: 441,
        melFmin: 30.0,
        melFmax: 16000.0,
        logCompressionScale: 100.0,
        featureSetVersion: "v1")
      let result = bnns.evaluateWithDiagnostic(trace: trace)
      #expect(result.evaluation == nil)
      let snapshot = try #require(result.snapshot)
      #expect(snapshot.failureStage == .featurizeRejected)
      #expect(snapshot.decodedBPM == nil)
      #expect(snapshot.softmaxMax == nil)
      #expect(snapshot.softmaxSecondMax == nil)
      #expect(snapshot.gateFired == nil)
      // The checksum should be deterministic over the input bytes.
      let expectedChecksum = BNNSTechnique.computeInputFeatureChecksum(
        [Float](repeating: 0.1, count: 128 * 16))
      #expect(snapshot.inputFeatureChecksum == expectedChecksum)
    }
  }

  /// AC #2: trace attachment via the capability protocol path. When ML
  /// is active AND the conformer adopts ``MLDiagnosticTechnique`` AND
  /// `enableTrace == true`, the service writes the returned snapshot
  /// to `trace.mlDiagnosticSnapshot`. The trace propagates back to
  /// the caller via `AudioAnalysisResult.trace`.
  ///
  /// Runs against the committed `CustomBundled.mlmodelc` fixture; the
  /// `snapshot != nil` assertion only requires featurize to have run
  /// (post-featurize paths always construct a snapshot), so the
  /// fixture's logits don't matter for this test's contract — only
  /// that `BNNSTechnique(modelURL:)` constructs successfully and the
  /// graph reaches inference. Which `failureStage` lands is a function
  /// of the fixture's logits and is intentionally not asserted here.
  @Test("traceAttachmentInvariants — snapshot lands when ML active + enableTrace true")
  func traceAttachmentInvariants() throws {
    if #available(macOS 15.0, *) {
      var trace = BPMDiagnosticTrace()
      // 48 frames passes the DD #9 short-clip guard.
      trace.mlFeatures = try MLFeatureFrames(
        melBands: 128,
        frames: 48,
        tensorLayout: .frameMajorLogMel,
        logMelData: stride(from: 0, to: 128 * 48, by: 1).map {
          Float($0).truncatingRemainder(dividingBy: 1.0)
        },
        sampleRate: 44100.0,
        fftSize: 2048,
        hopSize: 441,
        melFmin: 30.0,
        melFmax: 16000.0,
        logCompressionScale: 100.0,
        featureSetVersion: "v1")
      let url = try #require(fixtureURL())
      let bnns = try BNNSTechnique(modelURL: url)
      let result = bnns.evaluateWithDiagnostic(trace: trace)
      // Snapshot must be non-nil because featurize ran (post-featurize
      // paths always construct a snapshot).
      #expect(result.snapshot != nil)
    }
  }

  /// AC #5: ``MLTechnique/evaluate(trace:)`` thin wrapper must discard
  /// the snapshot and return only the evaluation. Identical behavior
  /// to ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)``'s
  /// evaluation slot.
  @Test("evaluate(trace:) discards snapshot and matches evaluateWithDiagnostic")
  func evaluateMatchesDiagnostic() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let bnns = try BNNSTechnique(modelURL: url)
      // Use a featurize-rejected case for determinism.
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = try MLFeatureFrames(
        melBands: 128, frames: 16, tensorLayout: .frameMajorLogMel,
        logMelData: [Float](repeating: 0.5, count: 128 * 16),
        sampleRate: 44100.0, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16000.0,
        logCompressionScale: 100.0, featureSetVersion: "v1")
      let evaluation = bnns.evaluate(trace: trace)
      let diagnostic = bnns.evaluateWithDiagnostic(trace: trace)
      #expect(evaluation == nil)
      #expect(diagnostic.evaluation == nil)
    }
  }
}

/// Parameterization arguments for the pre-featurize abstain test.
enum PreFeaturizeAbstainCase: CaseIterable {
  case featuresAbsent
  case featureVersionMismatch

  func makeFeatures() -> MLFeatureFrames? {
    switch self {
    case .featuresAbsent:
      return nil
    case .featureVersionMismatch:
      return try? MLFeatureFrames(
        melBands: 128,
        frames: 48,
        tensorLayout: .frameMajorLogMel,
        logMelData: [Float](repeating: 0.5, count: 128 * 48),
        sampleRate: 44100.0,
        fftSize: 2048,
        hopSize: 441,
        melFmin: 30.0,
        melFmax: 16000.0,
        logCompressionScale: 100.0,
        featureSetVersion: "v99")  // Wrong version — triggers featureVersionMismatch path.
    }
  }
}
