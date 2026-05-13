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
import os.log

// MARK: - BNNSTechnique

/// Default `MLTechnique` implementation backed by Apple's BNNSGraph
/// CPU-only inference path. The library ships a bundled reference model
/// at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/`,
/// trained by Story 4-4b against the GiantSteps tempo corpus. Consumers
/// who want to use their own weights can pass a custom URL via
/// `init(modelURL:)` (BYOW path) or implement a fully custom
/// `MLTechnique` conformance from scratch.
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

  /// Default URL for the library's bundled reference model. `Optional`
  /// (not force-unwrapped) so the resource-missing case can throw
  /// `MLTechniqueError.modelResourceMissing` cleanly at init time
  /// rather than crashing at module load.
  public static let bundledReferenceURL: URL? =
    Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")

  /// Gate 1 abstain threshold — DD #10. Softmax-max must be `≥ 0.50` for
  /// `evaluate(trace:)` to return non-nil. `0.50` is calibrated for the
  /// lossy 96 kbps GiantSteps training distribution; consumers retraining
  /// on a HiFi corpus should sweep this threshold against a held-out set
  /// (deferred-work entry).
  private static let confidenceThreshold: Double = 0.50

  /// Gate 2 abstain threshold — DD #10. The margin between softmax-max
  /// and softmax-second-max must be `≥ 0.10`. Catches Epic 4's motivating
  /// adjacent-bin half-tempo / triplet confusion that softmax-max alone
  /// misses.
  private static let marginConfidenceThreshold: Double = 0.10

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

  /// Feature-set version the bundled `giantsteps_v1.mlmodelc` was
  /// trained against. `MLFeatureFrames` payloads with a different
  /// version (e.g., post-Story-4.7) cause `evaluate(trace:)` to abstain
  /// — preventing silent feature-distribution drift.
  private static let supportedFeatureSetVersion = "v1"

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

  /// Test-only seam exposing the handle reference for the deinit witness
  /// test (`BNNSTechniqueDeinitWitnessTests`, Task 8). Reachable only via
  /// `@testable import BoomBoomBoomKitML`. Not intended for production.
  internal var __handleForTesting: BNNSGraphHandle { handle }

  /// Loads and compiles the model at `modelURL`. Default is the library's
  /// bundled reference at `Bundle.module/giantsteps_v1.mlmodelc`. Throws
  /// when the URL is unreadable, the compile fails, the tensor contract
  /// doesn't match the library's expectations, or the bin count differs
  /// from 256.
  ///
  /// Consumer apps wanting graceful degradation should use `try?`:
  /// ```
  /// var opts = AudioAnalysisService.Options()
  /// opts.mlTechnique = try? BNNSTechnique()
  /// ```
  public init(modelURL: URL? = Self.bundledReferenceURL) throws {
    guard let modelURL else {
      throw MLTechniqueError.modelResourceMissing(
        URL(fileURLWithPath: "<bundled giantsteps_v1.mlmodelc — missing>"))
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

    // Validate input/output tensor names + output bin count BEFORE
    // caching anything on the struct. Free graph data on any failure so
    // the lifecycle contract holds even on the throw path.
    do {
      try Self.validateContract(graph: graph)
    } catch {
      if let data = graph.data { free(data) }
      throw error
    }

    let src = "input".withCString {
      BNNSGraphGetArgumentPosition(graph, nil, $0)
    }
    let dst = "output".withCString {
      BNNSGraphGetArgumentPosition(graph, nil, $0)
    }
    guard src >= 0, dst >= 0 else {
      if let data = graph.data { free(data) }
      throw MLTechniqueError.invalidTensorContract(
        missing: src < 0 ? "input" : "output")
    }

    self.handle = BNNSGraphHandle(graph: graph)
    self.srcIndex = src
    self.dstIndex = dst
  }

  // MARK: - MLTechnique

  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    guard let features = trace.mlFeatures else {
      Self.logNilFeaturesOnce()
      return nil
    }
    guard features.featureSetVersion == Self.supportedFeatureSetVersion else {
      return nil
    }
    guard let inputTensor = featurize(features) else { return nil }
    guard let decoded = inferTempoCNN(inputTensor) else { return nil }
    // Two-gate abstain (DD #10).
    guard decoded.confidence >= Self.confidenceThreshold else { return nil }
    let margin = decoded.confidence - decoded.secondMax
    guard margin >= Self.marginConfidenceThreshold else { return nil }

    let bpm = min(max(decoded.bpm, 60.0), 200.0)
    let confidence = min(max(decoded.confidence, 0.0), 1.0)
    return MLEvaluation(
      bpm: bpm, confidence: confidence, modelIdentifier: "bnns_tempo_v1")
  }

  // MARK: - featurize

  /// Transposes the trace's frame-major log-mel payload into mel-major
  /// `[melBands, frames]`, z-score-normalizes each mel band across time,
  /// and resamples each band to `W=512` frames. Returns a flat
  /// `[1, 1, 128, 512]` NCHW row-major Float buffer or `nil` if the
  /// input is degenerate (too few frames, wrong mel band count).
  private func featurize(_ features: MLFeatureFrames) -> [Float]? {
    // DD #9 short-clip guard fires BEFORE the resize step. Sub-32-frame
    // sources upsample by > 16× per row and produce features outside the
    // model's training distribution.
    guard features.frames >= 32 else { return nil }
    guard features.melBands == Self.expectedMelBands else { return nil }

    let M = features.melBands
    let F = features.frames
    let W = Self.targetWidth

    // Step 1: transpose frame-major → mel-major contiguous rows.
    // Source: features.logMelData[frame * M + mel]
    // Dest:   melMajor[mel * F + frame]
    var melMajor = [Float](repeating: 0, count: M * F)
    features.logMelData.withUnsafeBufferPointer { src in
      melMajor.withUnsafeMutableBufferPointer { dst in
        guard let srcBase = src.baseAddress, let dstBase = dst.baseAddress else { return }
        for mel in 0..<M {
          var srcIdx = mel
          let dstRowStart = mel * F
          for frame in 0..<F {
            dstBase[dstRowStart + frame] = srcBase[srcIdx]
            srcIdx += M
          }
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

    // Step 3: temporal resample per mel band to W frames.
    // Build the control vector once: fractional source indices spanning
    // [0, F-1] in exactly W evenly-spaced steps.
    var controlVector = [Float](repeating: 0, count: W)
    let scale = Float(F - 1) / Float(W - 1)
    for w in 0..<W {
      controlVector[w] = Float(w) * scale
    }

    var resampled = [Float](repeating: 0, count: M * W)
    for mel in 0..<M {
      let sourceSlice = Array(melMajor[(mel * F)..<((mel + 1) * F)])
      let rowOut = vDSP.linearInterpolate(
        elementsOf: sourceSlice, using: controlVector)
      // Memcpy the row into the resampled buffer.
      rowOut.withUnsafeBufferPointer { src in
        resampled.withUnsafeMutableBufferPointer { dst in
          guard let s = src.baseAddress, let d = dst.baseAddress else { return }
          d.advanced(by: mel * W).update(from: s, count: W)
        }
      }
    }
    return resampled
  }

  // MARK: - inferTempoCNN

  /// Per-call BNNSGraph inference. Builds a new `bnns_graph_context_t`,
  /// runs `BNNSGraphContextExecute`, applies a host-side softmax to the
  /// raw logits, and returns `(bpm, softmax_max, softmax_second_max)` —
  /// or nil if any BNNS call fails or the softmax produces non-finite
  /// values.
  private func inferTempoCNN(
    _ inputTensor: [Float]
  ) -> (bpm: Double, confidence: Double, secondMax: Double)? {
    let context = BNNSGraphContextMake(handle.graph)
    defer { BNNSGraphContextDestroy(context) }
    guard context.data != nil, context.size != 0 else { return nil }
    let setArgStatus = BNNSGraphContextSetArgumentType(
      context, BNNSGraphArgumentTypeTensor)
    guard setArgStatus == 0 else { return nil }

    let workspaceSize = BNNSGraphContextGetWorkspaceSize(context, nil)
    guard workspaceSize >= 0 else { return nil }
    var workspace: UnsafeMutableRawPointer?
    if workspaceSize > 0 {
      let pageSize = Int(sysconf(Int32(_SC_PAGESIZE)))
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
            var args = [bnns_graph_argument_t](
              repeating: bnns_graph_argument_t(), count: 2)
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
    guard execStatus == 0 else { return nil }

    return Self.decodeLogits(output)
  }

  // MARK: - Host-side softmax + top-2 decode

  /// Applies a host-side softmax to the model's raw logit output
  /// (subtract-max-for-numerical-stability + exp + normalize) and
  /// returns the top-2 probabilities + argmax-derived BPM. Per Task 1.5d
  /// the bundled model emits logits, NOT softmax probabilities; this is
  /// the load-bearing host-side step that converts logits → probabilities
  /// before the two-gate abstain check.
  internal static func decodeLogits(
    _ logits: [Float]
  ) -> (bpm: Double, confidence: Double, secondMax: Double)? {
    guard !logits.isEmpty else { return nil }
    var shifted = logits
    var maxLogit: Float = 0
    vDSP_maxv(shifted, 1, &maxLogit, vDSP_Length(shifted.count))
    var negMax = -maxLogit
    vDSP_vsadd(shifted, 1, &negMax, &shifted, 1, vDSP_Length(shifted.count))

    var expanded = [Float](repeating: 0, count: shifted.count)
    vForce.exp(shifted, result: &expanded)

    var sum: Float = 0
    vDSP_sve(expanded, 1, &sum, vDSP_Length(expanded.count))
    guard sum > 0, sum.isFinite else { return nil }

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
    return (
      bpm: bpmBinOffset + Double(maxIdx),
      confidence: Double(confidence),
      secondMax: Double(secondMax)
    )
  }

  // MARK: - validateContract

  /// Asserts the compiled graph exposes argument names `"input"` /
  /// `"output"` and an output tensor with last-dim `== 256`. Throws
  /// `MLTechniqueError.invalidTensorContract` / `.binCountMismatch` on
  /// failure. Called from `init(modelURL:)` BEFORE the struct caches
  /// `srcIndex` / `dstIndex` so a contract violation aborts the
  /// constructor cleanly.
  private static func validateContract(graph: bnns_graph_t) throws {
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

    // Bin-count verification requires a temporary context to query
    // tensor metadata via BNNSGraphContextGetTensor.
    let probeContext = BNNSGraphContextMake(graph)
    defer { BNNSGraphContextDestroy(probeContext) }
    guard probeContext.data != nil else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message: "BNNSGraphContextMake returned empty context during validateContract"))
    }
    var outputTensor = BNNSTensor()
    let metaStatus = "output".withCString {
      BNNSGraphContextGetTensor(probeContext, nil, $0, true, &outputTensor)
    }
    guard metaStatus == 0 else {
      throw MLTechniqueError.modelLoadFailed(
        underlying: BNNSCompileFailure(
          message:
            "BNNSGraphContextGetTensor(output) failed during validateContract (status \(metaStatus))"
        ))
    }
    let rank = Int(outputTensor.rank)
    guard rank > 0 else {
      throw MLTechniqueError.binCountMismatch(
        expected: expectedBinCount, actual: 0)
    }
    let lastDim: Int = withUnsafePointer(to: &outputTensor.shape) { tuplePtr in
      tuplePtr.withMemoryRebound(to: Int.self, capacity: rank) { dims in
        dims[rank - 1]
      }
    }
    guard lastDim == expectedBinCount else {
      throw MLTechniqueError.binCountMismatch(
        expected: expectedBinCount, actual: lastDim)
    }
  }

  // MARK: - HALT (g) defensive log

  /// One-shot `os_log` emission for the nil-features path. Indicates the
  /// `captureMLFeatures` flag is not propagating end-to-end from
  /// `AudioAnalysisService.runPreCorroborationPipeline` →
  /// `BPMAnalyzer.estimateBPM` → `BPMDiagnosticTrace.mlFeatures`. The
  /// log fires at most once per process lifetime so noisy callers don't
  /// spam the unified log.
  private static let nilFeaturesLogger = OSLog(
    subsystem: "BoomBoomBoomKitML", category: "BNNSTechnique")
  private static let nilFeaturesLatch = OneShotLatch()

  private static func logNilFeaturesOnce() {
    guard nilFeaturesLatch.tryAcquire() else { return }
    os_log(
      .fault, log: nilFeaturesLogger,
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

  init(graph: bnns_graph_t) {
    self.graph = graph
  }

  deinit {
    // Task 1.5b verified `graph.data` is from the default malloc zone for
    // the BoomBoomBoomKit `BNNSGraphCompileFromFile(path, nil, default)`
    // path — `free` is the correct destructor primitive. See
    // `_bmad-output/implementation-artifacts/4-5-allocator-probe.log`.
    if let data = graph.data { free(data) }
  }
}

// MARK: - Helpers

/// Lightweight one-shot latch backed by an `NSLock`. Used by the
/// `logNilFeaturesOnce` HALT (g) defensive path.
private final class OneShotLatch: @unchecked Sendable {
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
