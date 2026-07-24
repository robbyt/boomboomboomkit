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
//  in the `.serialized` `BNNSTechniqueInferenceTests` suite below: the
//  fixture is the rejected v1 graph, so it abstains at the production
//  gate-1 softmax floor; a non-nil `MLEvaluation` is only reachable with
//  the gate thresholds overridden, and both facts are now locked.
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
      // nil result is independent of the threshold-override seam — safe to run
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

  // Concurrency + transpose real-inference tests moved to the `.serialized`
  // `BNNSTechniqueInferenceTests` suite below (GH-167 item 4 / #156): they read
  // the confidence-gate thresholds, so they need the threshold-override seam to
  // reach a non-nil result (the fixture is the rejected v1 graph and abstains at
  // production thresholds) and must not race the global override.

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
// `MLEvaluation` is only reachable with the confidence gates overridden. Both
// facts are locked below.
//
// `.serialized`: every test here reads or mutates the process-global
// `BNNSTechnique.thresholdOverride` Mutex, so they must not run concurrently
// with each other. No other suite asserts a threshold-dependent `evaluate`
// outcome, so cross-suite parallelism is safe.
@Suite("BNNSTechnique real inference (GH-167 item 4)", .serialized)
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
  /// confidence gates are overridden to 0.0/0.0 because the fixture is the
  /// rejected model and abstains at production thresholds; the point of this
  /// test is that the featurize → infer → decode chain itself works.
  @Test("evaluate yields a non-nil in-range MLEvaluation (gates overridden)")
  @available(macOS 15.0, *)
  func realInferenceYieldsInRangeEvaluation() throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(modelURL: url)
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures()

    BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
    defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }

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
    // softmax below the 0.50 floor.
    let decoded = try #require(snap.decodedBPM, "inference should have decoded a BPM")
    #expect(decoded >= 60.0 && decoded <= 200.0)
    let softmax = try #require(snap.softmaxMax)
    #expect(softmax.isFinite && softmax >= 0.0 && softmax < 0.50)
  }

  /// Relocated from `BNNSTechniqueTests` and de-vacuumed (GH-167 item 4 / #156):
  /// concurrent `evaluate` calls share no mutable state. With the gates zeroed
  /// every call returns a non-nil BPM, so the "all identical" assertion is no
  /// longer skipped when the input abstains.
  @Test("concurrent evaluate is context-local (gates overridden)")
  @available(macOS 15.0, *)
  func concurrentEvaluateIsContextLocal() async throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(modelURL: url)
    var trace = BPMDiagnosticTrace()
    trace.mlFeatures = try Self.syntheticFeatures(frames: 128)
    let bound = trace

    BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
    defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }

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
  @Test("frameMajorLogMel transpose matches nchw (gates overridden)")
  @available(macOS 15.0, *)
  func evaluateAcceptsFrameMajorLogMelLayout() throws {
    let url = try #require(fixtureURL())
    let t = try BNNSTechnique(modelURL: url)
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

    BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
    defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }

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
