//
//  BNNSTechniqueTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-5 Task 8.1: tests for `BNNSTechnique` covering init / featurize /
//  abstain / cancellation / RAII deinit / concurrency exposure / raw-API
//  guards. All new tests live in this NEW file per AC #10 — no edits to
//  existing test files.
//
//  Tests that require the bundled `giantsteps_v1.mlmodelc` artifact use
//  `@Test(.disabled(if: bundledModelMissing, "..."))` for genuine
//  Swift-Testing skip (post-Story-4-5 review pass M12 — replaces the prior
//  `Issue.record + return` pattern, which Codex flagged as a doc-vs-behavior
//  mismatch: `Issue.record` records a failure, it doesn't skip).
//
//  Locally the bundled model is committed (Story 4-4b shipped it under
//  `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc`). The skip
//  predicate fires only on pathological checkouts where the artifact is
//  removed or corrupted; that's a developer-machine state and shouldn't
//  fail the test suite.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

/// `.disabled(if:)` predicate for tests that require the bundled
/// `giantsteps_v1.mlmodelc`. Evaluated when Swift Testing collects traits;
/// the macOS-15 gate uses an inline `if #available` because
/// `BNNSTechnique.bundledReferenceURL` is itself macOS-15-only.
private func bundledModelMissing() -> Bool {
  if #available(macOS 15.0, *) {
    return BNNSTechnique.bundledReferenceURL == nil
  }
  return true
}

@Suite("Story 4-5 BNNSTechnique")
struct BNNSTechniqueTests {

  // MARK: - Init failure paths

  @Test("init throws .modelResourceMissing for a non-existent URL")
  func initThrowsForMissingURL() {
    if #available(macOS 15.0, *) {
      let missing = URL(fileURLWithPath: "/tmp/definitely-not-a-real.mlmodelc")
      do {
        _ = try BNNSTechnique(modelURL: missing)
        Issue.record("expected throw, got success")
      } catch let MLTechniqueError.modelResourceMissing(url) {
        #expect(url.path() == missing.path())
      } catch {
        Issue.record("expected .modelResourceMissing, got \(error)")
      }
    }
  }

  @Test("try? init returns nil for a non-existent URL")
  func tryOptionalInitReturnsNilForMissingURL() {
    if #available(macOS 15.0, *) {
      let missing = URL(fileURLWithPath: "/tmp/definitely-not-a-real.mlmodelc")
      let instance = try? BNNSTechnique(modelURL: missing)
      #expect(instance == nil)
    }
  }

  // MARK: - Successful init + evaluate path (requires bundled model)

  @Test(
    "init() loads the bundled giantsteps_v1.mlmodelc when available",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func initSucceedsForBundledModel() throws {
    if #available(macOS 15.0, *) {
      let t = try #require(try? BNNSTechnique())
      _ = t
    }
  }

  @Test(
    "evaluate(trace:) returns nil when mlFeatures is absent (HALT (g))",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func evaluateReturnsNilWhenFeaturesAbsent() throws {
    if #available(macOS 15.0, *) {
      // Disabled via `.disabled(if: bundledModelMissing())` trait;
      // unwrap is `try #require` semantics here (the predicate gate
      // already filtered out missing-artifact runs).
      let t = try #require(try? BNNSTechnique())
      let trace = BPMDiagnosticTrace()
      #expect(trace.mlFeatures == nil)
      let result = t.evaluate(trace: trace)
      #expect(result == nil)
    }
  }

  @Test(
    "evaluate(trace:) abstains on feature-set version mismatch",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func evaluateAbstainsOnVersionMismatch() throws {
    if #available(macOS 15.0, *) {
      // Disabled via `.disabled(if: bundledModelMissing())` trait;
      // unwrap is `try #require` semantics here (the predicate gate
      // already filtered out missing-artifact runs).
      let t = try #require(try? BNNSTechnique())
      let features = try MLFeatureFrames(
        melBands: 128, frames: 64, tensorLayout: .nchw,
        logMelData: [Float](repeating: 0.5, count: 128 * 64),
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v999-FROM-THE-FUTURE"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      #expect(result == nil, "expected abstain on version mismatch")
    }
  }

  @Test(
    "evaluate(trace:) abstains on degenerate short clips (< 32 frames)",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func evaluateAbstainsOnShortClip() throws {
    if #available(macOS 15.0, *) {
      // Disabled via `.disabled(if: bundledModelMissing())` trait;
      // unwrap is `try #require` semantics here (the predicate gate
      // already filtered out missing-artifact runs).
      let t = try #require(try? BNNSTechnique())
      let features = try MLFeatureFrames(
        melBands: 128, frames: 16, tensorLayout: .nchw,
        logMelData: [Float](repeating: 0.5, count: 128 * 16),
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      #expect(result == nil, "expected abstain on frames < 32 short clip")
    }
  }

  @Test(
    "evaluate(trace:) produces a finite BPM in [60, 200] on synthetic input",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func evaluateProducesPlausibleBPM() throws {
    if #available(macOS 15.0, *) {
      // Disabled via `.disabled(if: bundledModelMissing())` trait;
      // unwrap is `try #require` semantics here (the predicate gate
      // already filtered out missing-artifact runs).
      let t = try #require(try? BNNSTechnique())
      // 256 source frames keeps all code paths active (non-trivial input,
      // post-z-score is non-zero, resamples cleanly to W=512).
      let frames = 256
      let mb = 128
      var data = [Float](repeating: 0, count: mb * frames)
      for i in 0..<data.count {
        // Mildly varied input so per-band stddev > 0 and z-score normalizes
        // to a non-zero post-normalize row (the model gets a real signal).
        data[i] = Float((i % 13)) / 13.0 + Float(i % 17) / 20.0
      }
      let features = try MLFeatureFrames(
        melBands: mb, frames: frames, tensorLayout: .nchw, logMelData: data,
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      // Result may legitimately be nil on synthetic input (the two-gate
      // abstain may fire); if non-nil, every emitted field must be sane.
      if let result {
        #expect(result.bpm.isFinite)
        #expect(result.bpm >= 60.0 && result.bpm <= 200.0)
        #expect(result.confidence >= 0.0 && result.confidence <= 1.0)
        #expect(result.modelIdentifier == "bnns_tempo_v1")
      }
    }
  }

  // MARK: - Cancellation cooperation (AC #9)

  @Test("Story 4-5 AC #9: cancellation on the active-ML path throws CancellationError")
  func cancellationWithValidMLConfigThrows() throws {
    // Spec-canonical ML-only cancellation checkpoint: when policy != .dspOnly,
    // an mlTechnique is wired up, and a trace is built, an in-flight
    // cancellation is observed at `evaluateMLIfActive` and throws BEFORE
    // `ml.evaluate(trace:)` is invoked.
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = mock
    opts.ensemblePolicy = .mlOnly
    opts.intensity = .default
    opts.isCancelled = { true }

    #expect(throws: CancellationError.self) {
      try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    }
    #expect(
      mock.callCount == 0,
      "RecordingMockMLTechnique.callCount must be 0 — helper checks cancellation BEFORE evaluate")
  }

  @Test(".dspOnly preserves the Story 4-4 AC #14 invariant under cancellation")
  func cancellationUnderDspOnlyDoesNotInvokeML() throws {
    // Story 4-5 spec-canonical ML-only cancellation checkpoint (post-review-pass
    // C2 fix): `.dspOnly + cancelled` returns nil from `evaluateMLIfActive`
    // SILENTLY — no throw originates from the helper. `analyzeBPM` may still
    // throw `CancellationError` from upstream pipeline checkpoints (before PCM
    // read, between windows). What this test pins is the AC #14 invariant: the
    // ML mock is NEVER invoked under .dspOnly regardless of cancellation state.
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let mock = RecordingMockMLTechnique(returning: nil)
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = mock
    opts.ensemblePolicy = .dspOnly
    opts.intensity = .fastest
    opts.isCancelled = { true }
    _ = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
    #expect(
      mock.callCount == 0,
      "RecordingMockMLTechnique.callCount must remain 0 under .dspOnly")
  }

  @Test(
    "Cancellation with no mlTechnique surfaces only as CancellationError (no helper-originated bespoke error)"
  )
  func cancellationWithNoMLTechniqueRaisesOnlyCancellationError() throws {
    // Story 4-5 spec-canonical: when `mlTechnique == nil` the helper's first
    // guard short-circuits and returns nil silently. We CANNOT directly
    // probe the private `evaluateMLIfActive` helper's return value through
    // the public API — the observable contract is narrower than the
    // helper's internal contract. This test pins what the public surface
    // actually exposes: under `mlTechnique == nil + .mlOnly + cancelled`,
    // any thrown error MUST be a `CancellationError` (originating from
    // upstream pipeline checkpoints), NOT a bespoke error type that would
    // indicate the helper itself misrouted (codex 019e28bb 'narrow the
    // test name and comment to what it can observe').
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    var opts = AudioAnalysisService.Options()
    opts.mlTechnique = nil
    opts.ensemblePolicy = .mlOnly  // policy says use ML, but no technique present
    opts.intensity = .default
    opts.isCancelled = { true }
    do {
      _ = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
    } catch is CancellationError {
      // Expected — upstream checkpoint fired
    } catch {
      Issue.record("expected CancellationError, got \(error)")
    }
  }

  // MARK: - Raw-API guard greps (AC #1)

  @Test(
    "AC #1: zero matches of deprecated BNNSFilter* / BNNSGraph Swift overlay in BoomBoomBoomKitML")
  func rawAPIGuards() {
    let mlSourceDir =
      URL(fileURLWithPath: #file)
      .deletingLastPathComponent()  // Tests/BoomBoomBoomKitTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()  // repo root
      .appendingPathComponent("Sources/BoomBoomBoomKitML")

    var allFiles: [URL] = []
    if let enumerator = FileManager.default.enumerator(
      at: mlSourceDir, includingPropertiesForKeys: nil)
    {
      while let next = enumerator.nextObject() as? URL {
        if next.pathExtension == "swift" {
          allFiles.append(next)
        }
      }
    }
    var bannedHits: [String] = []
    let banned = [
      "BNNSFilterCreate", "BNNSFilterApply", "BNNSGraph.Builder",
      "BNNSGraph.Context", "BNNSGraph.makeContext",
    ]
    // Exclude lines that are inside comments. The v1 filter only excluded
    // single-line `//` / `///` prefixes; review fix N11 tracks `/* ... */`
    // block-comment depth so banned names embedded in a multi-line
    // doc-comment don't trip the guard.
    //
    // Known limitations (codex 019e28bb — left as-is because they don't
    // match any realistic failure mode in this codebase):
    //   1. A line of the shape `*/ realCode()` is fully skipped even
    //      though `realCode()` is outside the block. Mitigation: project
    //      style puts `*/` on its own line; if a maintainer puts code
    //      after `*/` and that code calls a banned API, code review
    //      catches it.
    //   2. A line of the shape `code(); /* ... banned ... */ moreCode();`
    //      is fully scanned (depth returns to 0 within the line), so a
    //      banned name in the comment span CAN trip a false positive.
    //      Mitigation: workspace has no such pattern today; tighten with
    //      a column-level scanner if a maintainer ever needs to mention
    //      a banned API name inline.
    //   3. String literals containing banned names are NOT excluded.
    //      Calling a banned API via `dlsym` + a literal is wildly outside
    //      this guard's failure mode.
    for url in allFiles {
      guard let body = try? String(contentsOf: url, encoding: .utf8) else { continue }
      var blockCommentDepth = 0
      for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
        let lineStr = String(line)
        // Track block-comment depth across lines. Counting unbalanced
        // `/*` and `*/` occurrences within the line is approximate (a
        // string literal containing `/*` would mis-count) but matches
        // Swift's usual style: doc-blocks are at column 0+, not embedded.
        let openCount = countOccurrences(of: "/*", in: lineStr)
        let closeCount = countOccurrences(of: "*/", in: lineStr)
        let startedInsideBlock = blockCommentDepth > 0
        blockCommentDepth += openCount - closeCount
        if blockCommentDepth < 0 { blockCommentDepth = 0 }
        // If the line started OR ended inside a block comment, skip it.
        if startedInsideBlock || blockCommentDepth > 0 { continue }
        let trimmed = lineStr.drop(while: { $0.isWhitespace })
        if trimmed.hasPrefix("//") { continue }
        for pattern in banned where lineStr.contains(pattern) {
          bannedHits.append("\(url.lastPathComponent): \(pattern)")
        }
      }
    }
    #expect(bannedHits.isEmpty, "banned API matches: \(bannedHits)")
  }

  private func countOccurrences(of needle: String, in haystack: String) -> Int {
    var count = 0
    var searchRange = haystack.startIndex..<haystack.endIndex
    while let r = haystack.range(of: needle, range: searchRange) {
      count += 1
      searchRange = r.upperBound..<haystack.endIndex
    }
    return count
  }

  // MARK: - Concurrency exposure (axiom-concurrency #5)

  @Test(
    "concurrent evaluate calls produce stable output (no shared state)",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  func concurrentEvaluateIsContextLocal() async throws {
    if #available(macOS 15.0, *) {
      let t = try #require(try? BNNSTechnique())
      let frames = 128
      var data = [Float](repeating: 0, count: 128 * frames)
      for i in 0..<data.count {
        data[i] = Float(i % 13) / 13.0 + Float(i % 19) / 25.0
      }
      let features = try MLFeatureFrames(
        melBands: 128, frames: frames, tensorLayout: .nchw, logMelData: data,
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: "v1"
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let bound = trace

      let bpms = await withTaskGroup(of: Double?.self) { group -> [Double?] in
        for _ in 0..<16 {
          group.addTask { t.evaluate(trace: bound)?.bpm }
        }
        var out: [Double?] = []
        for await item in group { out.append(item) }
        return out
      }
      let nonNil = bpms.compactMap { $0 }
      if !nonNil.isEmpty {
        #expect(
          Set(nonNil.map { $0.bitPattern }).count == 1,
          "concurrent evaluate produced inconsistent BPM values: \(nonNil)")
      }
    }
  }

  // MARK: - Byte-identity sentinel (AC #5)

  @Test("Story 4-5 AC #5: DSP-only path stays byte-identical when BNNSTechnique is loaded")
  func dspOnlyByteIdenticalWithBNNSAvailable() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")

    // Baseline: mlTechnique == nil (default).
    var baselineOpts = AudioAnalysisService.Options()
    baselineOpts.intensity = .default
    guard let baseline = try AudioAnalysisService.analyzeBPM(url: url, options: baselineOpts) else {
      Issue.record("baseline analyzeBPM returned nil")
      return
    }

    // BNNS loaded but .dspOnly — under Story 4-4 A1 short-circuit the
    // helper returns nil before reaching evaluate, captureMLFeatures
    // stays false, and per-track BPM must be byte-equal to baseline.
    var withBNNSOpts = AudioAnalysisService.Options()
    withBNNSOpts.intensity = .default
    withBNNSOpts.ensemblePolicy = .dspOnly
    if #available(macOS 15.0, *) {
      withBNNSOpts.mlTechnique = try? BNNSTechnique()
    }
    guard let withBNNS = try AudioAnalysisService.analyzeBPM(url: url, options: withBNNSOpts) else {
      Issue.record("BNNS-loaded analyzeBPM returned nil")
      return
    }

    // `.bitPattern` byte-level equality rather than `==`. Two BPMs are
    // byte-identical iff every bit matches — strict regression-protection.
    // NaN handling: NaN payloads with different bit patterns compare
    // unequal here (asymmetric vs `==` semantics, which always returns
    // false for NaN); if the DSP path ever silently emits a NaN BPM,
    // this test fires even when both sides "look like NaN" but differ in
    // payload. That's the intended pin (review-pass m10).
    #expect(
      baseline.bpm.bitPattern == withBNNS.bpm.bitPattern,
      "BPM bit-pattern must match between baseline and BNNS-loaded .dspOnly paths")
    #expect(
      baseline.confidence.bitPattern == withBNNS.confidence.bitPattern,
      "confidence bit-pattern must match between baseline and BNNS-loaded .dspOnly paths")
  }

  // MARK: - decodeLogits hardening (Unit 1)

  @Test("decodeLogits rejects non-finite logits (NaN/+Inf/-Inf)")
  @available(macOS 15.0, *)
  func decodeLogits_rejectsNonFiniteLogits() {
    var logitsWithNaN = [Float](repeating: 0.0, count: 256)
    logitsWithNaN[42] = .nan
    #expect(
      BNNSTechnique.decodeLogits(logitsWithNaN) == nil,
      "NaN logit must produce abstain (decodeLogits returns nil)")

    var logitsWithPosInf = [Float](repeating: 0.0, count: 256)
    logitsWithPosInf[100] = .infinity
    #expect(
      BNNSTechnique.decodeLogits(logitsWithPosInf) == nil,
      "+Inf logit must produce abstain")

    var logitsWithNegInf = [Float](repeating: 0.0, count: 256)
    logitsWithNegInf[200] = -.infinity
    #expect(
      BNNSTechnique.decodeLogits(logitsWithNegInf) == nil,
      "-Inf logit must produce abstain")
  }

  @Test("decodeLogits abstains when argmax maps outside [60, 200] BPM range")
  @available(macOS 15.0, *)
  func decodeLogits_abstainsOnOutOfRangeBPM() {
    // bin 0 → BPM 30 (below floor) → abstain
    var logitsBelow = [Float](repeating: -10.0, count: 256)
    logitsBelow[0] = 100.0
    #expect(
      BNNSTechnique.decodeLogits(logitsBelow) == nil,
      "argmax at bin 0 → BPM 30 must produce abstain (below 60 BPM floor)")

    // bin 200 → BPM 230 (above ceiling) → abstain
    var logitsAbove = [Float](repeating: -10.0, count: 256)
    logitsAbove[200] = 100.0
    #expect(
      BNNSTechnique.decodeLogits(logitsAbove) == nil,
      "argmax at bin 200 → BPM 230 must produce abstain (above 200 BPM ceiling)")

    // bin 90 → BPM 120 (in range) → success
    var logitsIn = [Float](repeating: -10.0, count: 256)
    logitsIn[90] = 100.0
    let decoded = BNNSTechnique.decodeLogits(logitsIn)
    #expect(decoded != nil, "in-range argmax must decode")
    #expect(decoded?.bpm == 120.0, "bin 90 → BPM 120 (30 + 90 = 120)")
  }

  // MARK: - Custom model URL (Unit 6 / M10)

  @Test(
    "HALT (i): init throws .invalidTensorContract on a renamed-output fixture")
  @available(macOS 15.0, *)
  func initThrowsOnMismatchedTensorNames() throws {
    // C1 / 4-5-HALT-(i): the fixture at
    // `Tests/BoomBoomBoomKitTests/Fixtures/RenamedTensors.mlmodelc/` is a
    // legitimate compiled `.mlmodelc` produced by
    // `_bmad-output/ml-training/scripts/build-renamed-tensor-fixture.py`
    // whose output tensor is named `var_42` instead of the contract-required
    // `output`. `validateContract` SHOULD reject this at init via
    // `MLTechniqueError.invalidTensorContract(missing: "output")`. If the
    // init silently accepts the fixture, the runtime invariant from DD #20
    // is broken — the renamed tensor would reach `evaluate(trace:)` with
    // mis-bound argument positions and produce garbage at inference time.
    //
    // The fixture's output name is `var_42` — verified by
    // `grep "name" RenamedTensors.mlmodelc/metadata.json` at build time.
    let resourceURL = try #require(Bundle.module.resourceURL)
    let fixtureURL =
      resourceURL
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("RenamedTensors.mlmodelc")
    try #require(FileManager.default.fileExists(atPath: fixtureURL.path))

    do {
      _ = try BNNSTechnique(modelURL: fixtureURL)
      Issue.record(
        "expected MLTechniqueError.invalidTensorContract, got successful construction"
      )
    } catch let MLTechniqueError.invalidTensorContract(missing) {
      // Accept the canonical message AND its bin-count variant — any
      // `invalidTensorContract` proves `validateContract` rejected the
      // fixture, which is the HALT (i) gate.
      #expect(missing.contains("output") || missing.contains("input"))
    } catch let error as MLTechniqueError {
      Issue.record(
        "expected .invalidTensorContract, got \(error)"
      )
    } catch {
      Issue.record(
        "expected MLTechniqueError.invalidTensorContract, got non-MLTechniqueError: \(error)"
      )
    }
  }

  @Test("init(modelURL:) accepts a custom URL pointing to a valid .mlmodelc (construction-only)")
  @available(macOS 15.0, *)
  func initAcceptsCustomModelURL_constructionOnly() throws {
    // Review fix N12: renamed from `initAcceptsCustomModelURL` to make the
    // construction-only scope explicit. The fixture is a verbatim copy of
    // the bundled `giantsteps_v1.mlmodelc` at
    // `Tests/BoomBoomBoomKitTests/Fixtures/CustomBundled.mlmodelc/` —
    // proves the consumer-override path (`Options.mlTechnique =
    // try? BNNSTechnique(modelURL: myURL)`) WORKS AT CONSTRUCTION TIME. It
    // does NOT exercise the inference pipeline; that's covered by the
    // bundled-model tests above and the corpus-grain impact report.
    //
    // `.mlmodelc` is a directory, not a file, so we can't use
    // `Bundle.module.url(forResource:withExtension:)` (it looks for
    // files). Build the URL via `Bundle.module.resourceURL` directly.
    let resourceURL = try #require(Bundle.module.resourceURL)
    let fixtureURL =
      resourceURL
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("CustomBundled.mlmodelc")
    try #require(FileManager.default.fileExists(atPath: fixtureURL.path))
    let technique = try BNNSTechnique(modelURL: fixtureURL)
    // Sanity: construction succeeded. The proof is type-checked: `try`
    // would have thrown if validateContract / argument-position lookup /
    // graph-compile had failed.
    _ = technique
  }
}

// MARK: - DD #15 strict deinit witness
//
// Post-Story-4-5 review pass: AC #10 was amended retroactively to permit
// the `Package.swift` modification that adds `BoomBoomBoomKitML` to the
// test target's deps (review fix DN1). The strict DD #15 deinit witness
// uses `@testable import BoomBoomBoomKitML` to reach the internal
// `BNNSGraphHandle` reference type, weak-references it inside an
// `autoreleasepool`, and verifies the weak ref reads nil after the last
// strong reference drops — the canonical Swift ARC pattern. The previous
// observational test (`bnnsTechniqueLifecycleCycles`) had inverted
// assertion semantics (all-fail soft-skipped; partial-fail asserted) and
// is replaced by this strict witness (review fix M14).

@Suite("Story 4-5 BNNSTechnique deinit witness", .serialized)
struct BNNSTechniqueDeinitWitnessTests {

  @Test(
    "BNNSGraphHandle deinit fires when last BNNSTechnique reference drops",
    .disabled(if: bundledModelMissing(), "bundled giantsteps_v1.mlmodelc missing"))
  @available(macOS 15.0, *)
  func storageDeinitFreesGraphHandleStorage() throws {
    // `weak var` reads nil iff ARC ran the last release on the wrapped
    // object, which fires `deinit`, which calls `free(graph.data)`.
    // `autoreleasepool` is required under Swift Testing's
    // parallel-by-default execution to drain autorelease entries that
    // would otherwise keep the handle alive past the `do` block;
    // `.serialized` on the suite prevents concurrent runs from racing.
    //
    // Review fix M6: replaced the `try?` + `Issue.record` skip pattern with
    // `.disabled(if: bundledModelMissing())` on the trait. The previous
    // pattern reported a failure when the bundled model was absent — and
    // ALSO passed VACUOUSLY because `weakHandle` stayed nil throughout, so
    // `#expect(weakHandle == nil)` succeeded on the false-positive path.
    // The `try BNNSTechnique()` form below is now safe because the trait
    // gate ensures we only reach it when the model is present.
    // Review fix M6 (codex 019e28bb): use `try BNNSTechnique()` so a real
    // failure surfaces with its diagnostic, not as a silent `try?` nil. The
    // outer test fn is `throws`; the `.disabled(if:)` trait already gates
    // out the missing-bundle path, so any throw here is a genuine compile/
    // contract failure worth surfacing.
    weak var weakHandle: BNNSGraphHandle?
    try autoreleasepool {
      let t = try BNNSTechnique()
      weakHandle = t.__handleForTesting
      #expect(weakHandle != nil, "sanity: handle exists during scope")
      // `t` falls out of scope at the closure end; ARC drops the last
      // strong ref inside the autoreleasepool; `deinit` fires.
    }
    // If `weakHandle == nil` post-pool, deinit ran. If non-nil, the
    // handle is leaking — that's the bug DD #15 was created to catch.
    #expect(
      weakHandle == nil,
      "BNNSGraphHandle should be deallocated after BNNSTechnique drops")
  }
}
