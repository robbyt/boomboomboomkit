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

/// Build gate-threshold ``BNNSTechnique/Options`` compactly. GH-141 moved
/// the thresholds off the initializer into an `Options` value; these
/// suites set them constantly, so a two-argument helper keeps the tests
/// about behaviour instead of about struct assembly.
@available(macOS 15.0, *)
private func gateOptions(
  confidence: Double, margin: Double
) -> BNNSTechnique.Options {
  var o = BNNSTechnique.Options()
  o.confidenceThreshold = confidence
  o.marginThreshold = margin
  return o
}

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
  /// GH-167 item 6 (#124): the population matrix used to be enforced by
  /// `precondition`s inside the public initializer, which meant a
  /// consumer's own conformer crashed the host app for disagreeing with
  /// `BNNSTechnique`'s control flow. The matrix is now documentation of
  /// what THIS producer emits, so it is asserted against this producer —
  /// which is the only place the claim was ever true.
  ///
  /// Drives the real fixture across three reachable outcomes and checks
  /// that each carries exactly the evidence its stage should. The
  /// remaining outcomes (`graphFailed`, the two decode rejections) are
  /// not reachable with a valid graph and valid features.
  @Test(
    "BNNSTechnique emits snapshots matching its documented matrix",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func producerEmissionMatrix() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      // Valid, supported-version features with enough frames to clear the
      // DD #9 short-clip guard, mildly varied so per-band stddev > 0.
      let mb = 128
      let frames = 256
      var data = [Float](repeating: 0, count: mb * frames)
      for i in 0..<data.count {
        data[i] = Float(i % 13) / 13.0 + Float(i % 17) / 20.0
      }
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = try MLFeatureFrames(
        melBands: mb, frames: frames, tensorLayout: .nchw, logMelData: data,
        sampleRate: 44100.0, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16000.0, logCompressionScale: 100.0,
        featureSetVersion: MLFeatureFrames.currentFeatureSetVersion)

      // Gate rejection: carries decode evidence AND names the gate.
      let gated = try BNNSTechnique(modelURL: url)
      let gatedResult = gated.evaluateWithDiagnostic(trace: trace)
      let gatedSnap = try #require(gatedResult.snapshot)
      #expect(gatedResult.evaluation == nil)
      #expect(gatedSnap.failureStage == .confidenceGateRejected)
      #expect(gatedSnap.gateFired != nil, "a gate rejection must name its gate")
      #expect(gatedSnap.decode != nil, "a gate rejection must carry what it rejected")

      // Win: carries decode evidence, no stage, no gate.
      let open = try BNNSTechnique(
        modelURL: url,
        options: gateOptions(confidence: 0.0, margin: 0.0))
      let openResult = open.evaluateWithDiagnostic(trace: trace)
      let openSnap = try #require(openResult.snapshot)
      #expect(openResult.evaluation != nil)
      #expect(openSnap.failureStage == nil)
      #expect(openSnap.gateFired == nil)
      #expect(openSnap.decode != nil)

      // Both agree on the checksum: the same features were seen.
      #expect(gatedSnap.inputFeatureChecksum == openSnap.inputFeatureChecksum)

      // Pre-featurize: no snapshot at all, because there is nothing to
      // checksum. This is what makes the two removed enum cases
      // unrepresentable rather than merely discouraged.
      let bare = BPMDiagnosticTrace()
      let bareResult = open.evaluateWithDiagnostic(trace: bare)
      #expect(bareResult.evaluation == nil)
      #expect(bareResult.snapshot == nil)
    }
  }

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
        featureSetVersion: "v2")
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
        featureSetVersion: "v2")
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
        logCompressionScale: 100.0, featureSetVersion: "v2")
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
