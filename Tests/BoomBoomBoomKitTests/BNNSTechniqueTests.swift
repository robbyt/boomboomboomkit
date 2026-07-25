//
//  BNNSTechniqueTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-5 Task 8.1: tests for `BNNSTechnique` covering init / featurize /
//  abstain / cancellation / RAII deinit / concurrency exposure / raw-API
//  guards. All new tests live in this NEW file per AC #10 — no edits to
//  existing test files.
//
//  GH-167 item 4 (#156): these tests formerly gated on
//  `bundledModelMissing()`, a predicate that reads
//  `BNNSTechnique.bundledReferenceURL` — a `nil` literal since Story 4-6
//  pulled the bundled model. The predicate was therefore permanently
//  true and 8 `@Test`s never ran. They now construct `BNNSTechnique`
//  from the committed `Fixtures/CustomBundled.mlmodelc` (the same
//  runnable graph `BNNSTechniqueDiagnosticTests` already exercises on
//  every `make test`), gated only on `fixtureMissing()` — which is false
//  under normal `swift test`. The real-inference happy path is asserted
//  in the `BNNSTechniqueInferenceTests` suite below: the
//  fixture is the rejected v1 graph, so it abstains at the production
//  gate-1 softmax floor; a non-nil `MLEvaluation` is only reachable with
//  the gate thresholds lowered at construction, and both facts are locked.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

/// Resolves the committed `CustomBundled.mlmodelc` fixture URL — a runnable
/// graph captured from the historical giantsteps_v1 checkpoint, retained in
/// `Tests/BoomBoomBoomKitTests/Fixtures/` after Story 4-6 Branch C pulled the
/// bundle from `Sources/`. `.mlmodelc` is a directory, so `Bundle.module.url(for…)`
/// (which targets files) can't be used; build from `Bundle.module.resourceURL`,
/// the convention `BNNSTechniqueDiagnosticTests` established. Returns nil only
/// when the resourceURL itself is unreachable (off-build-system path); under
/// `swift test` / `make test` it is never nil.
@available(macOS 15.0, *)
private func fixtureURL() -> URL? {
  guard let resourceURL = Bundle.module.resourceURL else { return nil }
  let url =
    resourceURL
    .appendingPathComponent("Fixtures")
    .appendingPathComponent("CustomBundled.mlmodelc")
  return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

/// `.disabled(if:)` predicate — true only when the committed fixture is
/// unreachable. Under normal `swift test` / `make test` it never fires and the
/// tests run. Replaces the permanently-true `bundledModelMissing()` (GH-167
/// item 4 / #156).
private func fixtureMissing() -> Bool {
  if #available(macOS 15.0, *) { return fixtureURL() == nil }
  return true
}

@Suite("Story 4-5 BNNSTechnique")
struct BNNSTechniqueTests {

  // MARK: - Abstain-threshold configuration (GH-167 item 6 / #144)

  @Test(
    "thresholds default to the shipped values",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func thresholdsDefaultToShippedValues() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let t = try BNNSTechnique(modelURL: url)
      #expect(t.confidenceThreshold == BNNSTechnique.defaultConfidenceThreshold)
      #expect(t.marginThreshold == BNNSTechnique.defaultMarginThreshold)
      #expect(BNNSTechnique.defaultConfidenceThreshold == 0.50)
      #expect(BNNSTechnique.defaultMarginThreshold == 0.10)
    }
  }

  @Test(
    "consumer-supplied thresholds are stored verbatim",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func consumerThresholdsStoredVerbatim() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let t = try BNNSTechnique(
        modelURL: url, confidenceThreshold: 0.2, marginThreshold: 0.05)
      #expect(t.confidenceThreshold == 0.2)
      #expect(t.marginThreshold == 0.05)
    }
  }

  /// A finite out-of-range threshold carries usable intent, so it
  /// saturates rather than failing. The gates compare with `<`, so a
  /// clamped 0.0 rejects nothing and a clamped 1.0 rejects everything
  /// short of a perfect 1.0 score.
  @Test(
    "out-of-range thresholds clamp to [0, 1] rather than throwing",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func outOfRangeThresholdsClamp() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let high = try BNNSTechnique(
        modelURL: url, confidenceThreshold: 1.5, marginThreshold: 42.0)
      #expect(high.confidenceThreshold == 1.0)
      #expect(high.marginThreshold == 1.0)
      let low = try BNNSTechnique(
        modelURL: url, confidenceThreshold: -0.2, marginThreshold: -99.0)
      #expect(low.confidenceThreshold == 0.0)
      #expect(low.marginThreshold == 0.0)
    }
  }

  /// NaN/Inf has no sensible interpretation as a probability floor, so
  /// it is a caller bug and surfaces as one instead of being silently
  /// replaced. Distinct from `.modelLoadFailed`: the model is fine.
  @Test(
    "non-finite thresholds throw .invalidThreshold",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func nonFiniteThresholdsThrow() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let bad: [(Double, Double)] = [
        (.nan, 0.1), (0.5, .nan),
        (.infinity, 0.1), (0.5, -.infinity),
      ]
      for (conf, margin) in bad {
        do {
          _ = try BNNSTechnique(
            modelURL: url, confidenceThreshold: conf, marginThreshold: margin)
          Issue.record("expected a throw for (\(conf), \(margin))")
        } catch let MLTechniqueError.invalidThreshold(reason) {
          #expect(!reason.isEmpty)
        } catch {
          Issue.record("expected .invalidThreshold for (\(conf), \(margin)), got \(error)")
        }
      }
    }
  }

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

  // MARK: - Successful init + evaluate path (committed CustomBundled fixture)
  //
  // GH-167 item 4 (#156): these construct `BNNSTechnique(modelURL:)` from the
  // committed fixture. The no-arg `BNNSTechnique()` construction is NOT retested
  // here — its default argument is the `nil` `bundledReferenceURL`, so it throws
  // by design; the construction contract is covered by
  // `initAcceptsCustomModelURL_constructionOnly` below.

  @Test(
    "evaluate(trace:) returns nil when mlFeatures is absent (HALT (g))",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func evaluateReturnsNilWhenFeaturesAbsent() throws {
    if #available(macOS 15.0, *) {
      let url = try #require(fixtureURL())
      let t = try BNNSTechnique(modelURL: url)
      let trace = BPMDiagnosticTrace()
      #expect(trace.mlFeatures == nil)
      let result = t.evaluate(trace: trace)
      #expect(result == nil)
    }
  }

  @Test(
    "evaluate(trace:) abstains on feature-set version mismatch",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func evaluateAbstainsOnVersionMismatch() throws {
    if #available(macOS 15.0, *) {
      // Abstain fires on the version-check BEFORE the confidence gate, so the
      // nil result is independent of the configured thresholds — safe to run
      // in this parallel suite (unlike the inference tests below).
      let url = try #require(fixtureURL())
      let t = try BNNSTechnique(modelURL: url)
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
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  func evaluateAbstainsOnShortClip() throws {
    if #available(macOS 15.0, *) {
      // Frame-count abstain also fires before the confidence gate — nil is
      // threshold-independent, so this stays in the parallel suite.
      let url = try #require(fixtureURL())
      let t = try BNNSTechnique(modelURL: url)
      let features = try MLFeatureFrames(
        melBands: 128, frames: 16, tensorLayout: .nchw,
        logMelData: [Float](repeating: 0.5, count: 128 * 16),
        sampleRate: 44_100, fftSize: 2048, hopSize: 441,
        melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
        featureSetVersion: MLFeatureFrames.currentFeatureSetVersion
      )
      var trace = BPMDiagnosticTrace()
      trace.mlFeatures = features
      let result = t.evaluate(trace: trace)
      #expect(result == nil, "expected abstain on frames < 32 short clip")
    }
  }

  // MARK: - Cancellation cooperation (AC #9)

  @Test("Story 4-5 AC #9: cancellation on the active-ML path throws CancellationError")
  func cancellationBeforeMLEvaluateThrows() throws {
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

  // Concurrency + transpose real-inference tests moved to the
  // `BNNSTechniqueInferenceTests` suite below (GH-167 item 4 / #156): they need
  // a non-nil result, and the fixture is the rejected v1 graph which abstains
  // at production thresholds, so they construct their technique with the gates
  // open.

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
    // the historical `giantsteps_v1.mlmodelc` (Story 4-4b training output;
    // bundle pulled from main in Story 4-6 Branch C) committed to
    // `Tests/.../Fixtures/` so the construction path stays exercised
    // independently of whether a runtime model bundle exists. The fixture
    // path is at
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
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  @available(macOS 15.0, *)
  func storageDeinitFreesGraphHandleStorage() throws {
    // `weak var` reads nil iff ARC ran the last release on the wrapped
    // object, which fires `deinit`, which calls `free(graph.data)`.
    // `autoreleasepool` is required under Swift Testing's
    // parallel-by-default execution to drain autorelease entries that
    // would otherwise keep the handle alive past the `do` block;
    // `.serialized` on the suite prevents concurrent runs from racing.
    //
    // GH-167 item 4 (#156): constructs from the committed CustomBundled fixture
    // via `BNNSTechnique(modelURL:)` (was the no-arg `BNNSTechnique()`, which now
    // throws on the nil default). The `.disabled(if: fixtureMissing())` trait
    // gates out the no-fixture path, so any throw here is a genuine compile/
    // contract failure worth surfacing — not a silent `try?` nil.
    let url = try #require(fixtureURL())
    weak var weakHandle: BNNSGraphHandle?
    try autoreleasepool {
      let t = try BNNSTechnique(modelURL: url)
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

// MARK: - Real-inference assertions (GH-167 item 4 / #156)
//
// These are the coverage #156 was filed for: the featurize → BNNSGraph infer →
// decode chain of the only shipping `MLTechnique` conformance had ZERO live
// assertions. The committed `CustomBundled.mlmodelc` fixture is the historical
// (rejected) giantsteps_v1 graph, so on synthetic input it decodes a concrete
// in-range tempo (~169 BPM) but its softmax_max (~0.07) is far below the shipped
// gate-1 floor of 0.50 — production `evaluate` therefore abstains. A non-nil
// `MLEvaluation` is only reachable with the confidence gates lowered. Both
// facts are locked below.
//
// GH-167 item 6 (#144): thresholds are per-instance constructor arguments, so
// a test that wants the gates open builds its own technique with them open.
// The former process-global `thresholdOverride` Mutex is gone, and with it the
// cross-suite race this comment used to have to reason about — that safety
// rested on invocation topology (`make test` filtering to the unit target and
// never co-invoking the benchmark target) rather than on anything enforced.
// No shared mutable state remains here, so `.serialized` is no longer required
// for threshold isolation.
// MARK: - Graph storage zone gate (GH-167 item 6 / #150)
//
// `BNNSGraphHandle.deinit` used to call `free(graph.data)` unconditionally,
// justified by a single allocator probe run on one machine on 2026-05-13
// against a model that no longer ships. Apple publishes no ownership contract
// for `bnns_graph_t.data` and the SDK still has no graph destructor, so the
// zone is now checked at runtime on every release.
//
// These tests exercise the helper directly rather than through deinit: the
// refusal branch cannot be reached with a real compiled graph (that is the
// point — it only fires if the platform changes), so it is driven with
// pointers whose provenance is known.
@Suite("BNNSGraphHandle storage release zone gate (GH-167 item 6)")
struct BNNSGraphStorageReleaseTests {

  @Test("frees a default-zone allocation")
  @available(macOS 15.0, *)
  func freesDefaultZoneAllocation() {
    // `malloc` puts this in the default zone, the same place the probe
    // found `graph.data`. Releasing it here is the production path; if
    // the guard wrongly refused, this allocation would leak instead.
    let p = malloc(1024)
    #expect(p != nil)
    #expect(malloc_zone_from_ptr(p) == malloc_default_zone())
    // Assert the decision, not just the absence of a crash: a guard that
    // wrongly refused would leak silently and still "pass" otherwise.
    #expect(BNNSTechnique.releaseGraphData(p), "default-zone storage must be freed")
  }

  @Test("refuses a pointer malloc does not own, and does not crash")
  @available(macOS 15.0, *)
  func refusesForeignPointer() {
    // A stack address belongs to no malloc zone, so `malloc_zone_from_ptr`
    // returns NULL. Passing it to `free` would be undefined behaviour —
    // the guard must decline. Reaching the next line at all is the
    // assertion: an unguarded `free` here aborts the process.
    var onTheStack: UInt64 = 0xDEAD_BEEF
    withUnsafeMutableBytes(of: &onTheStack) { raw in
      let p = raw.baseAddress
      #expect(malloc_zone_from_ptr(p) == nil, "sanity: stack memory is unowned by malloc")
      #expect(
        !BNNSTechnique.releaseGraphData(p),
        "storage malloc does not own must not be freed")
    }
    #expect(onTheStack == 0xDEAD_BEEF, "the guard must not have touched the storage")
  }

  /// The policy is "default zone only", not merely "some zone". Without
  /// this case, weakening the guard to `zone != nil` — dropping the
  /// default-zone comparison entirely — passes every other test here,
  /// because the only refusal case would be a pointer no zone owns.
  @Test("refuses an allocation owned by a non-default zone")
  @available(macOS 15.0, *)
  func refusesNonDefaultZoneAllocation() throws {
    let custom = try #require(malloc_create_zone(0, 0), "could not create a test zone")
    defer { malloc_destroy_zone(custom) }
    let p = try #require(malloc_zone_malloc(custom, 1024))
    // Genuinely malloc-owned, genuinely not the default zone — the exact
    // state the guard exists to detect.
    #expect(malloc_zone_from_ptr(p) != nil, "sanity: the zone owns this pointer")
    #expect(malloc_zone_from_ptr(p) != malloc_default_zone(), "sanity: not the default zone")
    #expect(
      !BNNSTechnique.releaseGraphData(p),
      "storage owned by another zone must not be freed with free()")
    // Still ours to release through the owning zone, which proves the
    // allocation survived the guard intact.
    malloc_zone_free(custom, p)
  }

  @Test("nil pointer is a no-op")
  @available(macOS 15.0, *)
  func nilPointerIsNoOp() {
    #expect(!BNNSTechnique.releaseGraphData(nil))
  }
}

@Suite("BNNSTechnique real inference (GH-167 item 4)")
struct BNNSTechniqueInferenceTests {

  @available(macOS 15.0, *)
  private static func syntheticFeatures(frames: Int = 256) throws -> MLFeatureFrames {
    let mb = 128
    var data = [Float](repeating: 0, count: mb * frames)
    for i in 0..<data.count {
      // Mildly varied so per-band stddev > 0 and z-score normalizes to a
      // non-zero row — the graph receives a real signal.
      data[i] = Float(i % 13) / 13.0 + Float(i % 17) / 20.0
    }
    return try MLFeatureFrames(
      melBands: mb, frames: frames, tensorLayout: .nchw, logMelData: data,
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: MLFeatureFrames.currentFeatureSetVersion)
  }

  /// GH-167 item 4 (#156): real BNNSGraph inference through `evaluate(trace:)`
  /// yields a non-nil `MLEvaluation` with finite, in-contract-range fields. The
  /// confidence gates are constructed at 0.0/0.0 because the fixture is the
  /// rejected model and abstains at production thresholds; the point of this
  /// test is that the featurize → infer → decode chain itself works.
  @Test("evaluate yields a non-nil in-range MLEvaluation (gates open)")
  @available(macOS 15.0, *)
  func realInferenceYieldsInRangeEvaluation() throws {
    let url = try #require(fixtureURL())
    // Gates open at construction: this asserts the inference chain
    // produces a usable tempo, not that the fixture clears the floor.
    let t = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 0.0)
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures()

    let result = try #require(
      t.evaluate(trace: trace),
      "real inference must produce a non-nil MLEvaluation with the gates zeroed")
    #expect(result.bpm.isFinite)
    #expect(result.bpm >= 60.0 && result.bpm <= 200.0)
    #expect(result.confidence.isFinite)
    #expect(result.confidence >= 0.0 && result.confidence <= 1.0)
    // Identifier is the fixture basename (`CustomBundled`), NOT the historical
    // `bnns_tempo_v1` the removed bundle carried.
    #expect(result.modelIdentifier == "CustomBundled")
  }

  /// GH-167 item 6 (#144): the gates are read off the instance, so two
  /// differently-configured techniques disagree about the SAME input in
  /// the SAME process. That is the behaviour #144 asks for, and it is
  /// exactly what a process-global threshold cannot express.
  @Test(
    "two instances with different thresholds disagree on the same input",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  @available(macOS 15.0, *)
  func perInstanceThresholdsAreIndependent() throws {
    let url = try #require(fixtureURL())
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures()
    let open = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 0.0)
    let shut = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 1.0, marginThreshold: 0.0)
    // Both alive simultaneously: neither can be observing the other's
    // configuration.
    #expect(open.evaluate(trace: trace) != nil, "open gates must admit the decode")
    #expect(shut.evaluate(trace: trace) == nil, "a 1.0 softmax floor must abstain")
    #expect(open.evaluate(trace: trace) != nil, "still open after the shut instance ran")
  }

  /// Gate 2 (margin) needs its own coverage: the fixture fails gate 1 at
  /// production thresholds, so every other test here reaches a verdict
  /// without gate 2 ever deciding anything. With gate 1 open, gate 2 is
  /// the only thing separating these two instances — so replacing its
  /// threshold with a literal would fail here and nowhere else.
  @Test(
    "marginThreshold alone decides the outcome when gate 1 is open",
    .disabled(if: fixtureMissing(), "CustomBundled.mlmodelc fixture missing"))
  @available(macOS 15.0, *)
  func marginThresholdGatesIndependently() throws {
    let url = try #require(fixtureURL())
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures()

    let marginOpen = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 0.0)
    let marginShut = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 1.0)

    #expect(marginOpen.evaluate(trace: trace) != nil, "a 0.0 margin floor must admit")

    let (evaluation, snapshot) = marginShut.evaluateWithDiagnostic(trace: trace)
    #expect(evaluation == nil, "a 1.0 margin floor must abstain")
    let snap = try #require(snapshot)
    // Gate 2 specifically — not gate 1, which is wide open here.
    #expect(snap.gateFired == .gate2Margin)
    #expect(snap.failureStage == .confidenceGateRejected)
  }

  /// GH-167 item 4 (#156): the complement. At PRODUCTION thresholds the same
  /// input abstains, and the diagnostic snapshot proves inference actually ran
  /// (a concrete decoded BPM + finite softmax) and that gate 1 is what rejected
  /// it — not featurization failing silently upstream.
  @Test("production thresholds abstain at gate 1, with inference proven to run")
  @available(macOS 15.0, *)
  func productionThresholdsAbstainAtGate1() throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(modelURL: url)
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures()

    let (evaluation, snapshot) = t.evaluateWithDiagnostic(trace: trace)
    #expect(evaluation == nil, "fixture must abstain at the production gate-1 floor")

    let snap = try #require(snapshot, "an abstain past featurize must still emit a snapshot")
    #expect(snap.failureStage == .confidenceGateRejected)
    #expect(snap.gateFired == .gate1Softmax)
    // Inference RAN: decode produced a concrete in-range tempo and a finite
    // softmax below the production gate-1 floor. Reference the production
    // constant, not a literal 0.50, so this stays aligned if it ever moves.
    let decoded = try #require(snap.decodedBPM, "inference should have decoded a BPM")
    #expect(decoded >= 60.0 && decoded <= 200.0)
    let softmax = try #require(snap.softmaxMax)
    #expect(softmax.isFinite && softmax >= 0.0 && softmax < t.confidenceThreshold)
  }

  /// Relocated from `BNNSTechniqueTests` and de-vacuumed (GH-167 item 4 / #156):
  /// concurrent `evaluate` calls share no mutable state. With the gates zeroed
  /// every call returns a non-nil BPM, so the "all identical" assertion is no
  /// longer skipped when the input abstains.
  @Test("concurrent evaluate is context-local (gates open)")
  @available(macOS 15.0, *)
  func concurrentEvaluateIsContextLocal() async throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 0.0)
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures(frames: 128)
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
    #expect(nonNil.count == 16, "every concurrent evaluate must produce a BPM with gates zeroed")
    #expect(
      Set(nonNil.map { $0.bitPattern }).count == 1,
      "concurrent evaluate produced inconsistent BPM values: \(nonNil)")
  }

  /// Relocated from `BNNSTechniqueTests` and de-vacuumed (GH-167 item 4 / #156):
  /// `.frameMajorLogMel` (the production layout) and an equivalent hand-transposed
  /// `.nchw` payload must decode identically, proving the `vDSP_mtrans` transpose
  /// in `featurize`. With the gates zeroed both sides produce non-nil results, so
  /// "both abstained" can no longer stand in for a real match.
  @Test("frameMajorLogMel transpose matches nchw (gates open)")
  @available(macOS 15.0, *)
  func evaluateAcceptsFrameMajorLogMelLayout() throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(
      modelURL: url, confidenceThreshold: 0.0, marginThreshold: 0.0)
    let frames = 128
    let mb = 128
    var nchwData = [Float](repeating: 0, count: mb * frames)
    for i in 0..<nchwData.count {
      nchwData[i] = Float(i % 13) / 13.0 + Float(i % 19) / 25.0
    }
    var frameMajorData = [Float](repeating: 0, count: mb * frames)
    for mel in 0..<mb {
      for frame in 0..<frames {
        frameMajorData[frame * mb + mel] = nchwData[mel * frames + frame]
      }
    }
    let version = MLFeatureFrames.currentFeatureSetVersion
    let nchwFeatures = try MLFeatureFrames(
      melBands: mb, frames: frames, tensorLayout: .nchw, logMelData: nchwData,
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: version)
    let frameFeatures = try MLFeatureFrames(
      melBands: mb, frames: frames, tensorLayout: .frameMajorLogMel,
      logMelData: frameMajorData,
      sampleRate: 44_100, fftSize: 2048, hopSize: 441,
      melFmin: 30.0, melFmax: 16_000.0, logCompressionScale: 100.0,
      featureSetVersion: version)
    var nchwTrace = BPMDiagnosticTrace()
    nchwTrace.mlFeatures = nchwFeatures
    var frameTrace = BPMDiagnosticTrace()
    frameTrace.mlFeatures = frameFeatures

    let n = try #require(t.evaluate(trace: nchwTrace), "nchw must decode with gates zeroed")
    let f = try #require(
      t.evaluate(trace: frameTrace), "frameMajorLogMel must decode with gates zeroed")
    // A mismatch is direct evidence that vDSP_mtrans produced different bytes
    // than the by-hand transpose.
    #expect(n.bpm == f.bpm, ".frameMajorLogMel and .nchw must decode to identical BPM")
    #expect(
      n.confidence == f.confidence,
      ".frameMajorLogMel and .nchw must decode to identical confidence")
  }
}
