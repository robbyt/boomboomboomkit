//
//  BNNSTechnique.swift
//  BoomBoomBoomKit
//
//  Story 4-5: BNNSGraph-backed `MLTechnique` conformance. Shape A-prime
//  (public struct + private `final class BNNSGraphHandle` for RAII per
//  DD #15). The compiled `bnns_graph_t` is loaded once at init via the
//  raw C API on macOS 15 (Swift overlay `BNNSGraph.Context` is locked out
//  by the macOS 26 floor per DD #7); per-call `bnns_graph_context_t` is
//  created and destroyed inside `evaluate(trace:)` so concurrent
//  fan-out from `withTaskGroup` at intensity ≥ `.thorough` does not
//  serialize through a single context.
//
//  Pre-1.0 / no-BC: `init()` is replaced with `init(modelURL:) throws` per
//  Story 4.5 spec (DD #5 + DD #19). The placeholder shipped in Story 4.1
//  is fully replaced here.
//

import Accelerate
import BoomBoomBoomKit
import Darwin
import Foundation
import Synchronization
import os.log

// MARK: - BNNSTechnique

/// Default `MLTechnique` implementation backed by Apple's BNNSGraph
/// CPU-only inference path. **No bundled model ships** as of Story 4-6
/// (Branch C close-out, 2026-05-16) — the previously-bundled
/// `giantsteps_v1.mlmodelc` was removed because it abstained on 100% of
/// OA300 audio at production thresholds. See `MODEL_CARD.md` for the
/// full Status section + threshold-sweep evidence. Consumers using ML
/// today MUST pass a `.mlmodelc` URL explicitly via `init(modelURL:)` —
/// see `tools/coreml-convert/README.md` for the bring-your-own-model
/// (BYOW) flow, or implement a fully custom `MLTechnique` conformance.
///
/// ## Lifecycle (Shape A-prime, DD #15)
///
/// `BNNSTechnique` is a public `struct` for symmetry with the rest of
/// BoomBoomBoomKit's value-type-only public surface. The compiled
/// `bnns_graph_t` is held by a private `final class BNNSGraphHandle`
/// reference; ARC keeps the graph alive across struct copies, and
/// `BNNSGraphHandle.deinit` calls `free(graph.data)` when the last
/// reference drops (Task 1.5b empirical evidence shows the graph data
/// is allocated from the default malloc zone, so `free` is the correct
/// destructor primitive — see `4-5-allocator-probe.log`).
///
/// ## Concurrency
///
/// The type is `@unchecked Sendable`. Per-call `bnns_graph_context_t`
/// objects are constructed inside `evaluate(trace:)` and destroyed via
/// `defer`, so concurrent invocations do not contend on shared mutable
/// state. The struct is therefore safe to assign to
/// `AudioAnalysisService.Options.mlTechnique` and call from any actor
/// or task.
///
/// ## Inference path (DD #7, DD #10)
///
/// 1. `evaluate(trace:)` reads `trace.mlFeatures` (an `MLFeatureFrames`
///    populated upstream by `BPMAnalyzer` when both
///    `Options.mlTechnique != nil` and `Options.ensemblePolicy != .dspOnly`).
///    Returns `nil` immediately if features are missing or carry a
///    feature-set version this implementation was not trained against.
/// 2. `featurize(_:)` transposes the source frame-major spectrogram
///    into mel-major, z-score-normalizes each mel band across the time
///    axis, then resamples to a fixed `W=512` frames via
///    `vDSP.linearInterpolate(elementsOf:using:)`.
/// 3. `inferTempoCNN(_:)` runs the compiled BNNSGraph against the
///    `[1, 1, 128, 512]` NCHW input. The bundled model emits LOGITS
///    (per the Task 1.5d probe — see `4-5-allocator-probe.log`), so the
///    raw output is normalized via a host-side softmax with
///    subtract-max-for-stability (`vForce.exp` + `vDSP.sum` +
///    `vDSP_vsdiv`) before reading argmax + 2nd-max probabilities.
/// 4. Two-gate abstain per DD #10: `softmax_max >= 0.50` AND
///    `(softmax_max - softmax_secondMax) >= 0.10`. Failing either gate
///    returns `nil` (the documented abstain path).
///
/// ## See also
///
/// - WWDC 2024 #10211 "Support real-time ML inference on the CPU" —
///   `BNNSGraphContextExecute` synchronous-by-design.
/// - `tools/coreml-convert/README.md` — consumer onboarding flow for
///   converting custom PyTorch / Core ML weights against the bundled
///   tensor contract.
@available(macOS 15.0, *)
public struct BNNSTechnique: MLTechnique, @unchecked Sendable {

  /// Default URL for a library-bundled reference model. **Always `nil`
  /// in the current ship.** Story 4-6 (Branch C close-out, 2026-05-16)
  /// removed the previously-bundled `giantsteps_v1.mlmodelc` from the
  /// main-shipping path because it abstained on 100% of OA300 audio at
  /// production thresholds (see `MODEL_CARD.md` for the full status +
  /// the threshold-sweep evidence). The training pipeline at
  /// `_bmad-output/ml-training/` remains operational; the
  /// `BNNSTechnique` infrastructure (load, featurize, inference,
  /// two-gate, diagnostic capability) is unchanged and ready to consume
  /// a higher-quality model when one is trained.
  ///
  /// Reserved as a `nil` literal so the `init(modelURL:)` default-arg
  /// signature stays stable across a future story that re-bundles a
  /// model. Consumers wanting to use ML today MUST pass a `modelURL:`
  /// explicitly — see ``init(modelURL:)`` + `tools/coreml-convert/README.md`
  /// for the bring-your-own-model (BYOW) flow.
  public static let bundledReferenceURL: URL? = nil

  /// Gate 1 abstain threshold — DD #10. Softmax-max must be `≥ 0.50` for
  /// `evaluate(trace:)` to return non-nil. `0.50` is calibrated for the
  /// lossy 96 kbps GiantSteps training distribution; consumers retraining
  /// on a HiFi corpus should sweep this threshold against a held-out set
  /// (deferred-work entry).
  ///
  /// Story 4-6 Task 7: the Story 4-6 threshold-sweep harness can
  /// temporarily override this value via the
  /// ``thresholdOverride`` test seam below. Production reads come through
  /// ``effectiveConfidenceThreshold`` which honors the override.
  internal static let confidenceThreshold: Double = 0.50

  /// Gate 2 abstain threshold — DD #10. The margin between softmax-max
  /// and softmax-second-max must be `≥ 0.10`. Catches Epic 4's motivating
  /// adjacent-bin half-tempo / triplet confusion that softmax-max alone
  /// misses.
  ///
  /// Story 4-6 Task 7: overridable via ``thresholdOverride`` (read through
  /// ``effectiveMarginThreshold``).
  internal static let marginConfidenceThreshold: Double = 0.10

  /// Story 4-6 Task 7 threshold-sweep testing seam. INTERNAL access only —
  /// settable via `@testable import BoomBoomBoomKitML` from the
  /// impact-report harness; consumer-facing public API is unchanged.
  /// Mutex-wrapped per Siri's Apple-platform audit: parallel-test safety,
  /// no `nonisolated(unsafe)` permanent escape hatch.
  ///
  /// Production behavior: ``confidenceThreshold`` / ``marginConfidenceThreshold``
  /// constants remain the source of truth; this override only fires when
  /// set by a test harness. The override is global — concurrent tests in
  /// the same process see the same value. Tests sweeping the override
  /// MUST run under `.serialized` or reset the override in `defer { ... }`.
  internal static let thresholdOverride =
    Mutex<(confidence: Double, margin: Double)?>(nil)

  /// Production read for the Gate 1 threshold. Returns
  /// ``confidenceThreshold`` unless ``thresholdOverride`` has been set.
  ///
  /// Convenience accessor — calls ``effectiveThresholds`` and returns
  /// just the confidence value. Per-call sites that need BOTH gates
  /// (e.g., ``evaluateInternal(trace:)``) MUST use ``effectiveThresholds``
  /// directly so the two values are observed from the same atomic
  /// snapshot of the override; otherwise a concurrent test that resets
  /// the override between the two reads will see mixed-state thresholds
  /// (Story 4-6 code review P13).
  internal static var effectiveConfidenceThreshold: Double {
    effectiveThresholds.confidence
  }

  /// Production read for the Gate 2 threshold. Convenience accessor —
  /// see ``effectiveConfidenceThreshold`` for the atomicity caveat.
  internal static var effectiveMarginThreshold: Double {
    effectiveThresholds.margin
  }

  /// Single atomic read of BOTH gate thresholds. Story 4-6 code review
  /// P13: a single `withLock` returns a `(confidence, margin)` tuple so
  /// the two gate decisions in ``evaluateInternal(trace:)`` cannot
  /// observe mixed-state thresholds when a concurrent test mutates the
  /// override between reads.
  internal static var effectiveThresholds: (confidence: Double, margin: Double) {
    thresholdOverride.withLock { override in
      if let o = override {
        return (o.confidence, o.margin)
      }
      return (confidenceThreshold, marginConfidenceThreshold)
    }
  }

  /// Number of mel bands the bundled model expects on input. Surfaced as
  /// a constant for parity with `BPMAnalyzer.melBands == 128` and for the
  /// degenerate-input guard in `featurize(_:)`.
  private static let expectedMelBands = 128

  /// Time-axis width of the model's input tensor (post-resample).
  private static let targetWidth = 512

  /// Number of output bins emitted by the model. Verified at init time
  /// against the actual graph metadata via `validateContract`.
  private static let expectedBinCount = 256

  /// BPM offset for the bin-center decode (DD #18): `bpm = 30 + argmax`.
  private static let bpmBinOffset: Double = 30.0

  /// Feature-set version this `BNNSTechnique` build's `featurize` contract
  /// targets. Story 7.5 bumps it to `"v2"` (the substrate-locked feature
  /// contract the multi-seed `giantsteps_v2_seed_*` models train against);
  /// it references the single source of truth `MLFeatureFrames.currentFeatureSetVersion`
  /// so the runtime emission and the model expectation can never silently
  /// diverge. `MLFeatureFrames` payloads with a different version cause
  /// `evaluate(trace:)` to abstain — preventing silent feature-distribution
  /// drift. BYOW consumers targeting the same architecture inherit the same
  /// featurize contract.
  ///
  /// `internal` (Story 4-6 close-out P3): the BNNSImpactTests harness's
  /// pre-featurize bucket-classification logic must reference this
  /// constant rather than hardcoding the string literal — otherwise
  /// a future version bump silently drifts the report's bucketing from
  /// the evaluator's actual abstain criterion.
  internal static let supportedFeatureSetVersion = MLFeatureFrames.currentFeatureSetVersion

  /// Compiled graph + workspace ownership. Final class so its `deinit`
  /// runs when the last `BNNSTechnique` reference drops.
  private let handle: BNNSGraphHandle

  /// Argument index for the graph's input tensor, resolved by NAME at
  /// init via `BNNSGraphGetArgumentPosition` per DD #16. Hard-coded
  /// positions are forbidden because a re-converted model with renamed
  /// arguments would silently swap input/output.
  private let srcIndex: Int

  /// Argument index for the graph's output tensor.
  private let dstIndex: Int

  /// Total argument count reported by `BNNSGraphGetArgumentCount` at init.
  /// Used to size the per-call argument array in `inferTempoCNN` so a
  /// graph with auxiliary arguments doesn't cause OOB writes when
  /// `srcIndex` / `dstIndex` exceed 1 (review fix C1).
  private let argumentCount: Int

  /// Identifier surfaced on every win-path ``MLEvaluation``. Derived
  /// from the `modelURL.deletingPathExtension().lastPathComponent` at
  /// init time so BYOW consumers see their own model name in the
  /// ensemble decision (Story 4-6 code review P6 — previously hardcoded
  /// to `"bnns_tempo_v1"` which lied about every consumer-supplied
  /// model). Defaults to `"bnns"` if the URL is malformed, but the
  /// `init(modelURL:)` fileExists guard makes that branch unreachable
  /// in practice.
  ///
  /// `internal` (not `private`) so the BNNSImpactTests harness can
  /// surface the same identifier as the report's top-level
  /// `model_identifier` field — otherwise the report would lie when
  /// emitting from a BYOW build.
  internal let modelIdentifier: String

  /// Test-only seam exposing the handle reference for the deinit witness
  /// test (`BNNSTechniqueDeinitWitnessTests`, Task 8). Reachable only via
  /// `@testable import BoomBoomBoomKitML`. Not intended for production.
  internal var __handleForTesting: BNNSGraphHandle { handle }

  /// Loads and compiles the model at `modelURL`. The default-arg
  /// (`Self.bundledReferenceURL`) is **always `nil` in the current ship**
  /// — Story 4-6 (Branch C close-out) removed the previously-bundled
  /// `giantsteps_v1.mlmodelc` from the main-shipping path. Calling the
  /// no-arg form `BNNSTechnique()` therefore throws
  /// `MLTechniqueError.modelResourceMissing` against a sentinel URL.
  /// Throws also when the URL is unreadable, the compile fails, the
  /// tensor contract doesn't match the library's expectations, or the
  /// bin count differs from 256.
  ///
  /// Consumer apps wanting graceful degradation should use `try?` and
  /// pass an explicit `modelURL:`:
  /// ```
  /// let url = Bundle.main.url(forResource: "your_model", withExtension: "mlmodelc")!
  /// var opts = AudioAnalysisService.Options()
  /// opts.mlTechnique = try? BNNSTechnique(modelURL: url)
  /// ```
  public init(modelURL: URL? = Self.bundledReferenceURL) throws {
    guard let modelURL else {
      throw MLTechniqueError.modelResourceMissing(
        URL(fileURLWithPath: "<no bundled model in this build; pass modelURL: explicitly>"))
    }
    guard FileManager.default.fileExists(atPath: modelURL.path()) else {
      throw MLTechniqueError.modelResourceMissing(modelURL)
    }

    let compileOptions = BNNSGraphCompileOptionsMakeDefault()
    defer { BNNSGraphCompileOptionsDestroy(compileOptions) }

    let graph: bnns_graph_t = modelURL.path().withCString { cpath in
      BNNSGraphCompileFromFile(cpath, nil, compileOptions)
    }
    guard graph.data != nil, graph.size != 0 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message: "BNNSGraphCompileFromFile returned empty graph for \(modelURL.path())"))
    }

    // Validate input/output tensor names, output bin count, input rank
    // and shape, and graph-argument-count BEFORE caching anything on the
    // struct. `validateContract` returns the resolved argument positions
    // and total argument count so we don't re-query the graph after init
    // (avoids drift between validation and caching — review fix C4) and
    // so `inferTempoCNN` can size the per-call argument array correctly
    // when the graph has auxiliary arguments (review fix C1).
    //
    // Free graph data on any failure so the lifecycle contract holds
    // even on the throw path.
    let validation: (src: Int, dst: Int, argumentCount: Int)
    do {
      validation = try Self.validateContract(graph: graph)
    } catch {
      if let data = graph.data { free(data) }
      throw error
    }

    self.handle = BNNSGraphHandle(graph: graph)
    self.srcIndex = validation.src
    self.dstIndex = validation.dst
    self.argumentCount = validation.argumentCount
    // Derive identifier from the URL's basename (e.g.,
    // `giantsteps_v1.mlmodelc` → `giantsteps_v1`). Fallback to `"bnns"`
    // if the URL is malformed — the fileExists guard above makes that
    // unreachable in practice but the fallback keeps the field non-nil.
    let basename = modelURL.deletingPathExtension().lastPathComponent
    self.modelIdentifier = basename.isEmpty ? "bnns" : basename
  }

  // MARK: - MLTechnique

  /// Story 4-6: thin wrapper around ``evaluateInternal(trace:)``. The
  /// protocol-public ``MLTechnique/evaluate(trace:)`` discards the
  /// diagnostic snapshot — consumers wanting it adopt
  /// ``MLDiagnosticTechnique`` (which this type also conforms to; see
  /// the trailing extension) and call ``evaluateWithDiagnostic(trace:)``.
  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    evaluateInternal(trace: trace).evaluation
  }

  /// Story 4-6 internal helper. Shared by both the protocol-public
  /// ``evaluate(trace:)`` (which discards the snapshot) and the
  /// ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)`` capability
  /// path (which returns both). Mapping per Story 4-6 Task 4.5:
  ///
  /// - `trace.mlFeatures == nil` → `(nil, nil)` (pre-featurize abstain;
  ///   no checksum possible). The defensive `logNilFeaturesOnce` from
  ///   Story 4-5 (HALT (g) inheritance) still fires here.
  /// - `featureSetVersion != "v2"` → `(nil, nil)` (pre-featurize
  ///   abstain; no checksum on a version mismatch since the feature
  ///   pipeline itself is suspect).
  /// - `featurize` returned nil → `(nil, snapshot)` with
  ///   `failureStage = .featurizeRejected`; `inputFeatureChecksum` is
  ///   computed over the source `MLFeatureFrames.logMelData` (the data
  ///   featurize received), per Task 4.7.
  /// - `inferLogits` returned nil → `(nil, snapshot)` with
  ///   `failureStage = .graphFailed`; `inputFeatureChecksum` is computed
  ///   over the post-featurize input tensor.
  /// - `decodeLogitsWithDiagnostic` returned `.nonFiniteLogits` →
  ///   `(nil, snapshot)` with `failureStage = .decodeRejected` and all
  ///   decode fields nil.
  /// - `decodeLogitsWithDiagnostic` returned `.outOfRangeArgmax` →
  ///   `(nil, snapshot)` with `failureStage = .decodeRejected` and
  ///   decode fields populated (the raw out-of-range BPM is reported —
  ///   the snapshot says what the model said, not what the library
  ///   accepted).
  /// - Gate 1 fail (`confidence < Self.confidenceThreshold`) →
  ///   `(nil, snapshot)` with `failureStage = .confidenceGateRejected`
  ///   and `gateFired = .gate1Softmax`.
  /// - Gate 2 fail (`margin < Self.marginConfidenceThreshold`) →
  ///   `(nil, snapshot)` with `failureStage = .confidenceGateRejected`
  ///   and `gateFired = .gate2Margin`.
  /// - Win → `(MLEvaluation, snapshot)` with `failureStage = nil`.
  private func evaluateInternal(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
    guard let features = trace.mlFeatures else {
      logNilFeaturesOnce()
      return (nil, nil)
    }
    guard features.featureSetVersion == Self.supportedFeatureSetVersion else {
      return (nil, nil)
    }
    guard let inputTensor = featurize(features) else {
      // featurize received features but rejected them (frame count <
      // 32, mel-band mismatch, or layout case unhandled). Checksum
      // over the source payload is still meaningful — it characterizes
      // the features Swift produced, which is what DD #6 cross-checks
      // against Python.
      let cksum = Self.computeInputFeatureChecksum(features.logMelData)
      return (
        nil,
        MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: cksum,
          failureStage: .featurizeRejected,
          gateFired: nil)
      )
    }
    // From here on the post-featurize tensor is the canonical input —
    // checksum over the resampled `[Float]` of length 65536 per
    // Task 4.7. This is the byte stream Python's parity harness can
    // reproduce by replicating Swift's featurize.
    let cksum = Self.computeInputFeatureChecksum(inputTensor)
    guard let logits = inferLogits(inputTensor) else {
      return (
        nil,
        MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: cksum,
          failureStage: .graphFailed,
          gateFired: nil)
      )
    }
    switch Self.decodeLogitsWithDiagnostic(logits) {
    case .nonFiniteLogits:
      return (
        nil,
        MLDiagnosticSnapshot(
          decodedBPM: nil,
          softmaxMax: nil,
          softmaxSecondMax: nil,
          inputFeatureChecksum: cksum,
          failureStage: .decodeRejected,
          gateFired: nil)
      )
    case .outOfRangeArgmax(let bpm, let confidence, let secondMax):
      return (
        nil,
        MLDiagnosticSnapshot(
          decodedBPM: bpm,
          softmaxMax: confidence,
          softmaxSecondMax: secondMax,
          inputFeatureChecksum: cksum,
          failureStage: .decodeRejected,
          gateFired: nil)
      )
    case .success(let bpm, let confidence, let secondMax):
      // Two-gate abstain (DD #10). Each gate populates a snapshot
      // reflecting the path that fired — the threshold-sweep harness
      // reads `gateFired` to distinguish gate-1 (low max) from gate-2
      // (low margin) on the same configuration. Story 4-6 Task 7:
      // thresholds read through the `effectiveThresholds` atomic
      // accessor so the `thresholdOverride` Mutex seam is observed
      // consistently across both gates in a single evaluation — code
      // review P13 closed the two-read race where a test resetting the
      // override between gates could yield mixed-state thresholds.
      let thresholds = Self.effectiveThresholds
      if confidence < thresholds.confidence {
        return (
          nil,
          MLDiagnosticSnapshot(
            decodedBPM: bpm,
            softmaxMax: confidence,
            softmaxSecondMax: secondMax,
            inputFeatureChecksum: cksum,
            failureStage: .confidenceGateRejected,
            gateFired: .gate1Softmax)
        )
      }
      let margin = confidence - secondMax
      if margin < thresholds.margin {
        return (
          nil,
          MLDiagnosticSnapshot(
            decodedBPM: bpm,
            softmaxMax: confidence,
            softmaxSecondMax: secondMax,
            inputFeatureChecksum: cksum,
            failureStage: .confidenceGateRejected,
            gateFired: .gate2Margin)
        )
      }
      // Win path. `confidence` is clamped defensively per Story 4-4
      // DD #4 — softmax-max in principle is in [0, 1] but
      // `vDSP_vsdiv` precision can produce values fractionally
      // outside the range. The snapshot reports the raw decoded
      // value (un-clamped) so threshold sweeps can observe the true
      // softmax distribution; `MLEvaluation` carries the clamped
      // value for public-API stability.
      let clampedConfidence = min(max(confidence, 0.0), 1.0)
      return (
        MLEvaluation(
          bpm: bpm, confidence: clampedConfidence,
          modelIdentifier: modelIdentifier),
        MLDiagnosticSnapshot(
          decodedBPM: bpm,
          softmaxMax: confidence,
          softmaxSecondMax: secondMax,
          inputFeatureChecksum: cksum,
          failureStage: nil,
          gateFired: nil)
      )
    }
  }

  // MARK: - inputFeatureChecksum (DD #6 cheap-first featurize-drift detector)

  /// FNV-1a 64-bit hash over the byte representation of a `[Float]`
  /// buffer. Story 4-6 Task 4.7. Used by ``MLDiagnosticSnapshot/inputFeatureChecksum``.
  ///
  /// FNV-1a is chosen for portability: the Python reference pipeline at
  /// `_bmad-output/ml-training/` can produce a bit-identical hash by
  /// iterating the same byte sequence with the same constants. The
  /// per-byte iteration is slow on paper (~1.3 ms for a 262 KB buffer)
  /// but dwarfed by BNNS inference (~250 ms per call).
  ///
  /// Determinism: the FNV-1a constants (offset basis + prime) are
  /// universal; there is no seed to randomize. The same `[Float]`
  /// bytes always produce the same `UInt64` across runs and machines.
  internal static func computeInputFeatureChecksum(_ buffer: [Float]) -> UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    let prime: UInt64 = 0x0000_0100_0000_01B3
    buffer.withUnsafeBufferPointer { fbuf in
      guard let base = fbuf.baseAddress else { return }
      let rawBuf = UnsafeRawBufferPointer(
        start: base, count: fbuf.count * MemoryLayout<Float>.size)
      for byte in rawBuf {
        hash ^= UInt64(byte)
        hash &*= prime
      }
    }
    return hash
  }

  // MARK: - featurize

  /// Instance entry point used by `evaluateInternal` — delegates to the
  /// pure ``modelInputTensor(from:)`` seam so the transpose/z-score/resample
  /// logic has exactly ONE implementation shared between the runtime path
  /// and the develop-only `dump-model-input` CLI / parity harness
  /// (Story 7.5 DD #15 — train/runtime feature identity).
  private func featurize(_ features: MLFeatureFrames) -> [Float]? {
    Self.modelInputTensor(from: features)
  }

  /// Produces the exact `[1, 1, 128, 512]` NCHW row-major model-input tensor
  /// that `evaluate(trace:)` feeds the BNNSGraph, from a log-mel
  /// ``MLFeatureFrames`` payload: transposes the payload into mel-major
  /// `[melBands, frames]` (Step 1, when needed), z-score-normalizes each
  /// mel band across time (Step 2), and resamples each band to `W=512`
  /// frames (Step 3). Returns the flat `Float` buffer or `nil` if the input
  /// is degenerate (too few frames, wrong mel-band count, or an unrecognized
  /// ``TensorLayout``).
  ///
  /// **Pure** — depends only on the input payload + the static feature
  /// constants, never on the loaded graph — so it can be called WITHOUT a
  /// constructed model. This is the parity seam (Story 7.5 DD #15): the
  /// Python training feature pipeline is verified byte-for-byte against this
  /// at the model-input-tensor boundary, guaranteeing the model trains on
  /// the same tensor it infers on (FR-21).
  ///
  /// Step 1's behavior depends on ``MLFeatureFrames/tensorLayout``:
  /// - ``TensorLayout/frameMajorLogMel`` (current ``BPMAnalyzer``
  ///   producer): transpose `[frame * M + mel]` → `[mel * F + frame]`.
  /// - ``TensorLayout/nchw``: already mel-major; copy through as-is.
  ///
  /// `@_spi(FeatureParity)` — NOT part of the stable public API (review
  /// Amelia #3 + the Epic 6↔8 seam rule: new touchpoints stay out of the
  /// public surface). The develop-only `dump-model-input` CLI reaches it via
  /// `@_spi(FeatureParity) import BoomBoomBoomKitML`; a future story promotes
  /// it with a named contract if a consumer genuinely needs raw tensor access.
  @_spi(FeatureParity)
  public static func modelInputTensor(from features: MLFeatureFrames) -> [Float]? {
    // DD #9 short-clip guard fires BEFORE the resize step. Sub-32-frame
    // sources upsample by > 16× per row and produce features outside the
    // model's training distribution.
    guard features.frames >= 32 else { return nil }
    guard features.melBands == Self.expectedMelBands else { return nil }

    let M = features.melBands
    let F = features.frames
    let W = Self.targetWidth

    // Step 1: produce mel-major contiguous rows. The shape depends on
    // the incoming `tensorLayout` — frame-major needs transpose,
    // mel-major copies through. `switch`-with-default-fallthrough
    // surfaces unhandled layouts at compile time, not via a silent
    // mis-interpretation at execute time.
    var melMajor = [Float](repeating: 0, count: M * F)
    switch features.tensorLayout {
    case .frameMajorLogMel:
      // vDSP_mtrans transposes the [F, M] frame-major source into the
      // [M, F] mel-major destination in one call — replaces the manual
      // nested loop that violated the project's "no manual loops over
      // signal data" rule (review fix Chunk 2 C2).
      features.logMelData.withUnsafeBufferPointer { src in
        melMajor.withUnsafeMutableBufferPointer { dst in
          guard let srcBase = src.baseAddress, let dstBase = dst.baseAddress else { return }
          vDSP_mtrans(srcBase, 1, dstBase, 1, vDSP_Length(M), vDSP_Length(F))
        }
      }
    case .nchw:
      // Already mel-major: `[mel * F + frame]`. Single-shot copy.
      features.logMelData.withUnsafeBufferPointer { src in
        melMajor.withUnsafeMutableBufferPointer { dst in
          guard let srcBase = src.baseAddress, let dstBase = dst.baseAddress else { return }
          dstBase.update(from: srcBase, count: M * F)
        }
      }
    }

    // Step 2: per-band z-score normalization across the time axis. The
    // raw C `vDSP_normalize` returns mean + stddev via pointer outputs
    // AND writes the normalized values in place — single-pass.
    melMajor.withUnsafeMutableBufferPointer { buf in
      guard let base = buf.baseAddress else { return }
      var mean: Float = 0
      var stddev: Float = 0
      for mel in 0..<M {
        let row = base + mel * F
        vDSP_normalize(row, 1, row, 1, &mean, &stddev, vDSP_Length(F))
        // Constant-row guard — division by zero stddev would emit NaN/Inf
        // which the BNNSGraph forward pass would propagate. Zero out the
        // row instead (a flat input bias-canceled by the first conv-bias
        // gives a stable, training-distribution-consistent output).
        if stddev == 0 || !stddev.isFinite {
          vDSP_vclr(row, 1, vDSP_Length(F))
        }
      }
    }

    // Step 3: temporal resample per mel band to W frames. Build the
    // control vector via vDSP_vramp — fractional source indices spanning
    // [0, F-1] in exactly W evenly-spaced steps (review fix Chunk 2 C4
    // — replaces a manual for-loop that violated the project's vDSP
    // rule; matches the Story 3-2 phase-ramp precedent in
    // tempogramMagnitude / computeFourierTempogram). The last control
    // entry is clamped in two steps — `min` to F-1, then one ULP down —
    // so `floor <= F-2` and vDSP_vlint's unconditional `A[floor(B[i])+1]`
    // read stays in-bounds for every reachable F (>= 32 per the
    // short-clip guard above; GH-140: the prior single-step
    // `.nextDown` under-clamped whenever vDSP_vramp's float32 rounding
    // overshot F-1 — reachable for both upsampling and downsampling F —
    // so vDSP_vlint read `A[F]`: cross-band contamination of the last
    // output column for mel bands 0-126, and a one-float heap over-read
    // for band 127). Interior entries need no clamp: entry W-2 sits a
    // full step (F-1)/511 below F-1, so flooring to F-1 there would need
    // a relative rounding error above 1/511 — many orders beyond
    // float32's ~6e-8. The two-step form mirrors the Python training
    // pipeline's clamp (`min(control[W-1], F-1)` then `nextafter` toward
    // -inf) for last-column parity; do NOT "simplify" to an unconditional
    // `Float(F - 1).nextDown`, which would diverge from the computed
    // control value on the majority undershoot case and reopen the gap.
    var controlVector = [Float](repeating: 0, count: W)
    var rampStart: Float = 0
    var rampStep = Float(F - 1) / Float(W - 1)
    vDSP_vramp(&rampStart, &rampStep, &controlVector, 1, vDSP_Length(W))
    controlVector[W - 1] = min(controlVector[W - 1], Float(F - 1)).nextDown
    // Debug tripwire (GH-140): a 1-ULP regression of the clamp above is
    // value-invisible (frac == 0 erases the contaminant in the output),
    // and Address Sanitizer cannot observe the over-read either — it
    // executes inside uninstrumented Accelerate code. This assert is the
    // biting guard for that class; it compiles out of release builds.
    assert(
      controlVector[W - 1] < Float(F - 1),
      "GH-140 resample clamp invariant violated: last control entry "
        + "\(controlVector[W - 1]) >= F-1 (\(F - 1)); vDSP_vlint would read A[F]")

    // Per-mel-band linear interpolation via vDSP_vlint directly. The
    // prior implementation built a fresh `Array(melMajor[range])` plus a
    // fresh `vDSP.linearInterpolate(...)` result array on every mel band,
    // allocating 2·M = 256 transient arrays per evaluate call. vDSP_vlint
    // operates on the underlying buffer base pointer with no intermediate
    // allocations. The outer `for mel in 0..<M` is a control-flow loop
    // wrapping a vDSP call — explicitly permitted by the project rule
    // (review fix Chunk 2 Codex C1 subset).
    var resampled = [Float](repeating: 0, count: M * W)
    melMajor.withUnsafeBufferPointer { srcBuf in
      resampled.withUnsafeMutableBufferPointer { dstBuf in
        controlVector.withUnsafeBufferPointer { ctrlBuf in
          guard
            let srcBase = srcBuf.baseAddress,
            let dstBase = dstBuf.baseAddress,
            let ctrlBase = ctrlBuf.baseAddress
          else { return }
          for mel in 0..<M {
            vDSP_vlint(
              srcBase + mel * F, ctrlBase, 1,
              dstBase + mel * W, 1,
              vDSP_Length(W), vDSP_Length(F))
          }
        }
      }
    }
    return resampled
  }

  // MARK: - inferLogits

  /// Per-call BNNSGraph inference. Builds a new `bnns_graph_context_t`,
  /// runs `BNNSGraphContextExecute`, and returns the raw logit `[Float]`
  /// (length ``expectedBinCount``) — or nil if any BNNS API call fails.
  ///
  /// Story 4-6 split from the original `inferTempoCNN` which folded the
  /// host-side softmax + decode into the same function. The split lets
  /// ``evaluateInternal(trace:)`` distinguish
  /// ``MLDiagnosticSnapshot/FailureStage/graphFailed`` (this function
  /// returns nil) from
  /// ``MLDiagnosticSnapshot/FailureStage/decodeRejected``
  /// (``decodeLogitsWithDiagnostic(_:)`` reports the decode-time
  /// outcome). Per Codex finding #2, those were folded into a single
  /// `inferenceFailed` case in the pre-review story spec; the split is
  /// the load-bearing remediation.
  private func inferLogits(
    _ inputTensor: [Float]
  ) -> [Float]? {
    let context = BNNSGraphContextMake(handle.graph)
    defer { BNNSGraphContextDestroy(context) }
    guard context.data != nil, context.size != 0 else { return nil }
    let setArgStatus = BNNSGraphContextSetArgumentType(
      context, BNNSGraphArgumentTypeTensor)
    guard setArgStatus == 0 else { return nil }

    // `BNNSGraphContextGetWorkspaceSize` returns `size_t`, which the
    // Clang importer currently maps to Swift `Int` (signed). The framework's
    // failure sentinel is `SIZE_T_MAX`, which bit-reinterprets to `-1` in
    // signed `Int`, so `>= 0` catches it. (Verified against bnns_graph.h:738-755
    // on macOS 15 SDK and codex-019e23e6 thread.)
    //
    // Post-review-pass C3 fix: the explicit `: Int` annotation forces a compile
    // error if a future SDK changes the import to `UInt` — the `>= 0` guard
    // would otherwise silently no-op. Upper bound `< Int.max - pageSize`
    // defends against absurd values that pass `>= 0` (review fix C3).
    let workspaceSize: Int = BNNSGraphContextGetWorkspaceSize(context, nil)
    guard workspaceSize >= 0 else { return nil }
    var workspace: UnsafeMutableRawPointer?
    if workspaceSize > 0 {
      // `sysconf` can return -1 on error; `UnsafeMutableRawPointer.allocate`
      // traps on non-positive alignment. Fall back to the canonical
      // macOS page size (16 KiB on Apple Silicon, 4 KiB on Intel — the
      // 4 KiB minimum is a safe over-aligned floor for either).
      let rawPageSize = Int(sysconf(Int32(_SC_PAGESIZE)))
      let pageSize = rawPageSize > 0 ? rawPageSize : 4096
      // Sanity bound against absurdly large workspace sizes that passed
      // `>= 0` (review fix C3). 1 GiB is several orders of magnitude beyond
      // any plausible tempo-CNN workspace; if BNNS ever needs more, the
      // floor moves with the model architecture, not silently.
      guard workspaceSize < (1 << 30) else { return nil }
      workspace = UnsafeMutableRawPointer.allocate(
        byteCount: workspaceSize, alignment: pageSize)
    }
    defer { workspace?.deallocate() }

    var inputTensorDesc = BNNSTensor()
    let inMeta = "input".withCString {
      BNNSGraphContextGetTensor(context, nil, $0, true, &inputTensorDesc)
    }
    var outputTensorDesc = BNNSTensor()
    let outMeta = "output".withCString {
      BNNSGraphContextGetTensor(context, nil, $0, true, &outputTensorDesc)
    }
    guard inMeta == 0, outMeta == 0 else { return nil }

    var input = inputTensor
    var output = [Float](repeating: 0, count: Self.expectedBinCount)

    let execStatus: Int32 = input.withUnsafeMutableBytes { inBuf in
      output.withUnsafeMutableBytes { outBuf in
        inputTensorDesc.data = inBuf.baseAddress
        inputTensorDesc.data_size_in_bytes = inBuf.count
        outputTensorDesc.data = outBuf.baseAddress
        outputTensorDesc.data_size_in_bytes = outBuf.count
        return withUnsafeMutablePointer(to: &inputTensorDesc) { inPtr in
          withUnsafeMutablePointer(to: &outputTensorDesc) { outPtr in
            // Size the args array by the graph's reported argument
            // count, not the hard-coded `count: 2`. A graph with
            // auxiliary arguments would otherwise OOB on `args[srcIndex]`
            // (review fix C1). srcIndex/dstIndex < argumentCount was
            // already validated in `validateContract`.
            var args = [bnns_graph_argument_t](
              repeating: bnns_graph_argument_t(), count: argumentCount)
            args[srcIndex].tensor = inPtr
            args[srcIndex].data_ptr_size = inBuf.count
            args[dstIndex].tensor = outPtr
            args[dstIndex].data_ptr_size = outBuf.count
            return args.withUnsafeMutableBufferPointer { argsPtr in
              BNNSGraphContextExecute(
                context, nil, argsPtr.count, argsPtr.baseAddress!,
                workspaceSize,
                workspace?.assumingMemoryBound(to: CChar.self))
            }
          }
        }
      }
    }
    // C2 residual: null out the descriptor `data` pointers after the
    // closure so a future maintainer can't accidentally reuse them
    // outside the `withUnsafeMutableBytes` lifetime (review fix C2).
    inputTensorDesc.data = nil
    inputTensorDesc.data_size_in_bytes = 0
    outputTensorDesc.data = nil
    outputTensorDesc.data_size_in_bytes = 0
    guard execStatus == 0 else { return nil }

    return output
  }

  // MARK: - Host-side softmax + top-2 decode

  /// Applies a host-side softmax to the model's raw logit output
  /// (subtract-max-for-numerical-stability + exp + normalize) and
  /// returns the top-2 probabilities + argmax-derived BPM. Per Task 1.5d
  /// the bundled model emits logits, NOT softmax probabilities; this is
  /// the load-bearing host-side step that converts logits → probabilities
  /// before the two-gate abstain check.
  ///
  /// Ties: if the top two bins have equal probability (e.g., model is
  /// split between two adjacent BPM bins on a half-tempo confusion), the
  /// argmax-by-first-index tie-break is documented but produces
  /// margin == 0 — `evaluate(trace:)`'s Gate 2 then abstains. This is the
  /// intended path for ambiguous predictions.
  ///
  /// Returns nil for any non-finite logit input (NaN propagates through
  /// `vDSP_maxv` with unspecified ordering — abstaining is safer than
  /// emitting garbage), and nil for argmax that maps to a BPM outside
  /// `60.0...200.0` (out-of-distribution prediction — abstain rather
  /// than silently clamp to the boundary).
  internal static func decodeLogits(
    _ logits: [Float]
  ) -> (bpm: Double, confidence: Double, secondMax: Double)? {
    switch decodeLogitsWithDiagnostic(logits) {
    case .success(let bpm, let confidence, let secondMax):
      return (bpm, confidence, secondMax)
    case .nonFiniteLogits, .outOfRangeArgmax:
      return nil
    }
  }

  /// Story 4-6 diagnostic decode. Returns the same evidence the existing
  /// ``decodeLogits(_:)`` produces, but discriminates between the three
  /// outcomes — successful decode, non-finite logits, or out-of-range
  /// argmax — instead of folding the two failure modes into `nil`.
  /// ``evaluateInternal(trace:)`` reads this discriminator to populate
  /// the ``MLDiagnosticSnapshot/FailureStage/decodeRejected`` snapshot
  /// with the correct decode field values (nil for non-finite, raw
  /// out-of-range values for out-of-range argmax).
  ///
  /// Per DD #2 doc-comment on ``MLDiagnosticSnapshot/decodedBPM``: the
  /// snapshot reports what the model said, not what the library
  /// accepted. So the ``outOfRangeArgmax`` case carries the raw decoded
  /// BPM (below 60 or above 200) — the consumer of the snapshot sees the
  /// model's actual prediction even though the library abstains.
  internal static func decodeLogitsWithDiagnostic(
    _ logits: [Float]
  ) -> BNNSDecodeOutcome {
    guard !logits.isEmpty else { return .nonFiniteLogits }
    // Reject non-finite logits up front: NaN through `vDSP_maxv` is
    // unspecified, +Inf produces NaN after subtract-max, -Inf produces
    // sum == 0 which the post-exp guard catches — but explicit
    // rejection here is faster and more diagnosable (review fix M26).
    guard logits.allSatisfy({ $0.isFinite }) else { return .nonFiniteLogits }
    var shifted = logits
    var maxLogit: Float = 0
    vDSP_maxv(shifted, 1, &maxLogit, vDSP_Length(shifted.count))
    var negMax = -maxLogit
    vDSP_vsadd(shifted, 1, &negMax, &shifted, 1, vDSP_Length(shifted.count))

    var expanded = [Float](repeating: 0, count: shifted.count)
    vForce.exp(shifted, result: &expanded)

    var sum: Float = 0
    vDSP_sve(expanded, 1, &sum, vDSP_Length(expanded.count))
    guard sum > 0, sum.isFinite else { return .nonFiniteLogits }

    var probs = [Float](repeating: 0, count: expanded.count)
    var divisor = sum
    vDSP_vsdiv(expanded, 1, &divisor, &probs, 1, vDSP_Length(expanded.count))

    var maxIdx = 0
    var maxVal: Float = -.infinity
    var secondMaxVal: Float = -.infinity
    for (i, v) in probs.enumerated() {
      if v > maxVal {
        secondMaxVal = maxVal
        maxVal = v
        maxIdx = i
      } else if v > secondMaxVal {
        secondMaxVal = v
      }
    }
    // Replace -.infinity with 0 if the array had only one finite value.
    let secondMax = secondMaxVal.isFinite ? secondMaxVal : 0
    let confidence = maxVal.isFinite ? maxVal : 0
    let bpm = bpmBinOffset + Double(maxIdx)
    // Out-of-range argmax — Story 4-6 reports the raw value so the
    // diagnostic snapshot can carry it. The legacy ``decodeLogits(_:)``
    // wrapper above still treats this as abstain (`nil`) for any caller
    // that doesn't want the rich diagnostic.
    if !(60.0...200.0).contains(bpm) {
      return .outOfRangeArgmax(
        bpm: bpm, confidence: Double(confidence),
        secondMax: Double(secondMax))
    }
    return .success(
      bpm: bpm, confidence: Double(confidence),
      secondMax: Double(secondMax))
  }

  // MARK: - validateContract

  /// Asserts the compiled graph exposes argument names `"input"` /
  /// `"output"`, distinct positions, input rank 4 with shape
  /// `[1, 1, expectedMelBands, targetWidth]` and `data_type == .float`,
  /// and output rank `1...BNNS_MAX_TENSOR_DIMENSION` with total element
  /// count `== expectedBinCount` and `data_type == .float`. Returns the
  /// resolved `(src, dst, argumentCount)` tuple so `init(modelURL:)` does
  /// not re-resolve positions (review fix C4 — single source of truth).
  ///
  /// Throws `MLTechniqueError.invalidTensorContract` on missing or
  /// duplicate argument names, wrong input shape/dtype, or output rank
  /// outside `1...BNNS_MAX_TENSOR_DIMENSION`. Throws
  /// `MLTechniqueError.binCountMismatch` when output total-element-count
  /// or dtype is wrong.
  ///
  /// Error precedence (stable contract): missing names → duplicate
  /// positions → input shape/dtype → output rank → output element
  /// count → output dtype. Tests asserting specific error cases should
  /// rely on this ordering.
  private static func validateContract(
    graph: bnns_graph_t
  ) throws -> (src: Int, dst: Int, argumentCount: Int) {
    let inputIdx = "input".withCString {
      BNNSGraphGetArgumentPosition(graph, nil, $0)
    }
    guard inputIdx >= 0 else {
      throw MLTechniqueError.invalidTensorContract(missing: "input")
    }
    let outputIdx = "output".withCString {
      BNNSGraphGetArgumentPosition(graph, nil, $0)
    }
    guard outputIdx >= 0 else {
      throw MLTechniqueError.invalidTensorContract(missing: "output")
    }
    // Reject same-position mapping for input/output — would cause the
    // output descriptor to overwrite the input slot at execute time
    // (review fix: Codex new gap).
    guard inputIdx != outputIdx else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "distinct input/output positions")
    }
    // Argument count is `size_t` in C — the Clang importer currently maps it
    // to Swift `Int` (signed); the failure sentinel `SIZE_T_MAX` bit-reinterprets
    // to `-1`, so `>= 0` catches it. The explicit `: Int` annotation forces a
    // compile error if a future SDK changes the import to `UInt` — the `>= 0`
    // guard would otherwise silently no-op (review fix C3). The upper-bound
    // sanity check defends against absurd values that pass `>= 0` (the BNNS
    // graphs in this project have ≤ 4 named arguments; 1024 is a wildly
    // permissive ceiling).
    let argCount: Int = BNNSGraphGetArgumentCount(graph, nil)
    guard argCount >= 0 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message: "BNNSGraphGetArgumentCount returned SIZE_T_MAX during validateContract"))
    }
    guard argCount < 1024 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message: "BNNSGraphGetArgumentCount returned implausible value \(argCount)"))
    }
    guard inputIdx < argCount, outputIdx < argCount else {
      throw MLTechniqueError.invalidTensorContract(
        missing:
          "argument positions out of range (input=\(inputIdx), output=\(outputIdx), count=\(argCount))"
      )
    }

    // Tensor metadata probing requires a temporary context.
    let probeContext = BNNSGraphContextMake(graph)
    defer { BNNSGraphContextDestroy(probeContext) }
    guard probeContext.data != nil else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message: "BNNSGraphContextMake returned empty context during validateContract"))
    }

    // Verify INPUT contract: rank 4, shape [1, 1, melBands, frames],
    // dtype Float. A graph emitting rank-2 or int8 input would silently
    // misinterpret bytes at execute time (review fix: M3 / Codex new gap).
    var inputTensor = BNNSTensor()
    let inMeta = "input".withCString {
      BNNSGraphContextGetTensor(probeContext, nil, $0, true, &inputTensor)
    }
    guard inMeta == 0 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message:
            "BNNSGraphContextGetTensor(input) failed during validateContract (status \(inMeta))"))
    }
    let maxRank = Int(BNNS_MAX_TENSOR_DIMENSION)
    let inputRank = Int(inputTensor.rank)
    guard (1...maxRank).contains(inputRank) else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "input.rank in 1...\(maxRank) (got \(inputRank))")
    }
    // Read the input shape into a Swift array using a fixed-size
    // BNNS_MAX_TENSOR_DIMENSION rebind — guarded above so we never
    // over-read the tuple (review fix: C3' / E3).
    //
    // `BNNSTensor.shape` is imported as a fixed-size C tuple. Each element is
    // documented as `size_t` in `bnns_types.h`; we rebind to `Int` on the
    // assumption that the Clang importer maps `size_t` to signed `Int` (same
    // assumption the workspace/argCount guards above depend on). The rank
    // guard ensures we only read the first `inputRank` elements, never
    // overrunning the tuple. If a future SDK changes the element type, the
    // rebind silently returns wrong bytes — there is no language-level catch.
    // The shape-vs-expectedInputShape comparison below catches most cases of
    // drift (the bytes won't look like [1, 1, 128, 512]); the assertion below
    // catches the rest with a debug-only sanity bound (review fix C3).
    let inputShape: [Int] = withUnsafePointer(to: &inputTensor.shape) { tuplePtr in
      tuplePtr.withMemoryRebound(to: Int.self, capacity: maxRank) { dims in
        Array(UnsafeBufferPointer(start: dims, count: inputRank))
      }
    }
    assert(
      inputShape.allSatisfy { $0 > 0 && $0 <= 1 << 30 },
      "BNNSTensor.shape element out of plausible range (got \(inputShape)) — possible import-type drift; review C3 guards in BNNSTechnique"
    )
    let expectedInputShape: [Int] = [1, 1, expectedMelBands, targetWidth]
    guard inputShape == expectedInputShape else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "input.shape \(expectedInputShape) (got \(inputShape))")
    }
    guard inputTensor.data_type == BNNSDataType.float else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "input.data_type Float (got raw=\(inputTensor.data_type.rawValue))")
    }

    // Verify OUTPUT contract: rank 1...8, total element count ==
    // expectedBinCount, dtype Float.
    var outputTensor = BNNSTensor()
    let outMeta = "output".withCString {
      BNNSGraphContextGetTensor(probeContext, nil, $0, true, &outputTensor)
    }
    guard outMeta == 0 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message:
            "BNNSGraphContextGetTensor(output) failed during validateContract (status \(outMeta))"))
    }
    let outputRank = Int(outputTensor.rank)
    guard (1...maxRank).contains(outputRank) else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "output.rank in 1...\(maxRank) (got \(outputRank))")
    }
    let outputShape: [Int] = withUnsafePointer(to: &outputTensor.shape) { tuplePtr in
      tuplePtr.withMemoryRebound(to: Int.self, capacity: maxRank) { dims in
        Array(UnsafeBufferPointer(start: dims, count: outputRank))
      }
    }
    assert(
      outputShape.allSatisfy { $0 > 0 && $0 <= 1 << 30 },
      "BNNSTensor.shape element out of plausible range (got \(outputShape)) — possible import-type drift; review C3 guards in BNNSTechnique"
    )
    // Total element count must match expectedBinCount — checking the
    // last dim alone would accept [4, 64] reinterpreted as 256 floats
    // (review fix: M4 / Codex new gap). Use overflow-reporting product.
    var totalElements = 1
    for dim in outputShape {
      guard dim > 0 else {
        throw MLTechniqueError.invalidTensorContract(
          missing: "output.shape positive dims (got \(outputShape))")
      }
      let (product, overflow) = totalElements.multipliedReportingOverflow(by: dim)
      guard !overflow else {
        throw MLTechniqueError.invalidTensorContract(
          missing: "output.shape element count Int-overflow (got \(outputShape))")
      }
      totalElements = product
    }
    guard totalElements == expectedBinCount else {
      throw MLTechniqueError.binCountMismatch(
        expected: expectedBinCount, actual: totalElements)
    }
    guard outputTensor.data_type == BNNSDataType.float else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "output.data_type Float (got raw=\(outputTensor.data_type.rawValue))")
    }

    return (src: inputIdx, dst: outputIdx, argumentCount: argCount)
  }

  // MARK: - HALT (g) defensive log

  /// `OSLog` channel for the nil-features diagnostic. Per-class is the
  /// right scope for the logger handle itself — `OSLog` is internally a
  /// COW-style reference to a kernel-side log object, so a single
  /// per-class instance is the canonical Apple pattern.
  private static let nilFeaturesLogger = OSLog(
    subsystem: "BoomBoomBoomKitML", category: "BNNSTechnique")

  /// One-shot `os_log` emission for the nil-features path. Indicates the
  /// `captureMLFeatures` flag is not propagating end-to-end from
  /// `AudioAnalysisService.runPreCorroborationPipeline` →
  /// `BPMAnalyzer.estimateBPM` → `BPMDiagnosticTrace.mlFeatures`.
  ///
  /// The latch fires at most once per `BNNSTechnique` instance lifetime
  /// (NOT per-process — review fix DN9). The latch lives on
  /// ``BNNSGraphHandle``, so it survives struct copies but resets when
  /// the last reference drops + a fresh technique is constructed. This
  /// gives long-running multi-tenant apps the diagnostic signal on every
  /// instance, not just the first one.
  private func logNilFeaturesOnce() {
    guard handle.nilFeaturesLatch.tryAcquire() else { return }
    // `.error` (not `.fault`): a missing mlFeatures payload is a
    // configuration mismatch the consumer can recover from — the
    // technique abstains, the DSP path still produces a result. `.fault`
    // is reserved for unrecoverable process-level corruption (review
    // fix Chunk 2 finding #6 / Codex 4-5-chunk2).
    os_log(
      .error, log: Self.nilFeaturesLogger,
      "BNNSTechnique.evaluate(trace:) called with nil mlFeatures — capture flag may not be propagating"
    )
  }
}

// MARK: - BNNSGraphHandle (RAII storage)

/// Final class wrapper around `bnns_graph_t` whose `deinit` frees the
/// graph's malloc'd data. Internal-only so `@testable import` from
/// `BNNSTechniqueDeinitWitnessTests` (Task 8 / DD #15) can hold a weak
/// reference and verify deinit fires when the last `BNNSTechnique`
/// reference drops.
@available(macOS 15.0, *)
internal final class BNNSGraphHandle: @unchecked Sendable {

  /// The compiled graph. Immutable post-compile per Apple's contract;
  /// safe to share across threads when wrapped by per-call contexts.
  let graph: bnns_graph_t

  /// Per-instance one-shot latch for the HALT (g) nil-features
  /// diagnostic (review fix DN9). Lives on the handle so it survives
  /// struct copies of `BNNSTechnique` but resets when the last
  /// reference drops + a fresh technique is constructed.
  let nilFeaturesLatch = OneShotLatch()

  init(graph: bnns_graph_t) {
    self.graph = graph
  }

  deinit {
    // Task 1.5b verified `graph.data` is from the default malloc zone for
    // the BoomBoomBoomKit `BNNSGraphCompileFromFile(path, nil, default)`
    // path — `free` is the correct destructor primitive. See
    // `_bmad-output/implementation-artifacts/4-5-allocator-probe.log`.
    //
    // FUTURE: when Apple documents a `BNNSGraphDestroy` (or equivalent)
    // primitive on a future macOS SDK, prefer that over raw `free()` —
    // it may release additional internal structures the framework
    // allocates separately. Today the probe evidence is the only signal.
    if let data = graph.data { free(data) }
  }
}

// MARK: - Helpers

/// Lightweight one-shot latch backed by an `NSLock`. Used by the
/// `logNilFeaturesOnce` HALT (g) defensive path. `internal` (not
/// `private`) so it can be stored on `BNNSGraphHandle` per review fix
/// DN9 (per-instance latch).
internal final class OneShotLatch: @unchecked Sendable {
  private var fired = false
  private let lock = NSLock()
  func tryAcquire() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    if fired { return false }
    fired = true
    return true
  }
}

/// Minimal error wrapper for BNNS compile / context failures that don't
/// surface a richer underlying type. Carries the failure message so the
/// MLTechniqueError.modelLoadFailed path stays structured.
private struct BNNSCompileFailure: Error, LocalizedError {
  let message: String
  var errorDescription: String? { message }
}

// MARK: - BNNSDecodeOutcome (Story 4-6 diagnostic decode)

/// Discriminated decode outcome surfaced by
/// ``BNNSTechnique/decodeLogitsWithDiagnostic(_:)``. Internal because the
/// type is purely a wiring helper between ``BNNSTechnique/evaluateInternal(trace:)``
/// and the host-side softmax — consumers see the equivalent information
/// via ``MLDiagnosticSnapshot/failureStage`` (`.decodeRejected`) plus the
/// decoded numeric fields.
@available(macOS 15.0, *)
internal enum BNNSDecodeOutcome: Sendable {
  /// Argmax mapped to a BPM in the library's `60.0...200.0` range.
  case success(bpm: Double, confidence: Double, secondMax: Double)
  /// Logits contained non-finite values (NaN / Inf) OR the post-softmax
  /// sum was non-positive / non-finite — no argmax was meaningfully
  /// computable.
  case nonFiniteLogits
  /// Argmax mapped to a BPM outside `60.0...200.0`. The raw decoded
  /// values are carried so the diagnostic snapshot can report what the
  /// model said.
  case outOfRangeArgmax(bpm: Double, confidence: Double, secondMax: Double)
}

// MARK: - BNNSTechnique: MLDiagnosticTechnique (Story 4-6 capability protocol)

/// Story 4-6 adds the ``MLDiagnosticTechnique`` capability protocol to
/// ``BNNSTechnique``. The bundled conformance enables
/// ``AudioAnalysisService``'s runtime narrowing in
/// `evaluateMLIfActive` to route the call through
/// ``evaluateWithDiagnostic(trace:)`` and attach the returned snapshot
/// to ``BPMDiagnosticTrace/mlDiagnosticSnapshot``.
///
/// The protocol-public method forwards to ``BNNSTechnique/evaluateInternal(trace:)``
/// — the same helper the legacy ``BNNSTechnique/evaluate(trace:)``
/// uses. Inference and decode logic are shared; the two-tuple return is
/// the only consumer-visible difference between the two entry points.
@available(macOS 15.0, *)
extension BNNSTechnique: MLDiagnosticTechnique {

  public func evaluateWithDiagnostic(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
    evaluateInternal(trace: trace)
  }
}
