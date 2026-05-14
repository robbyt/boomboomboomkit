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

  /// Total argument count reported by `BNNSGraphGetArgumentCount` at init.
  /// Used to size the per-call argument array in `inferTempoCNN` so a
  /// graph with auxiliary arguments doesn't cause OOB writes when
  /// `srcIndex` / `dstIndex` exceed 1 (review fix C1).
  private let argumentCount: Int

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
  }

  // MARK: - MLTechnique

  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    guard let features = trace.mlFeatures else {
      logNilFeaturesOnce()
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

    // `decodeLogits` already abstains for BPM outside 60-200 (review
    // fix m13), so `decoded.bpm` is guaranteed in-range here.
    // `confidence` is still clamped defensively per Story 4-4 DD #4 —
    // softmax-max in principle is in [0, 1] but `vDSP_vsdiv` precision
    // can produce values fractionally outside the range; clamp for
    // public-API stability.
    let confidence = min(max(decoded.confidence, 0.0), 1.0)
    return MLEvaluation(
      bpm: decoded.bpm, confidence: confidence,
      modelIdentifier: "bnns_tempo_v1")
  }

  // MARK: - featurize

  /// Transposes the trace's log-mel payload into mel-major
  /// `[melBands, frames]` (Step 1, when needed), z-score-normalizes each
  /// mel band across time (Step 2), and resamples each band to `W=512`
  /// frames (Step 3). Returns a flat `[1, 1, 128, 512]` NCHW row-major
  /// `Float` buffer or `nil` if the input is degenerate (too few frames,
  /// wrong mel-band count, or an unrecognized ``TensorLayout``).
  ///
  /// Step 1's behavior depends on ``MLFeatureFrames/tensorLayout``:
  /// - ``TensorLayout/frameMajorLogMel`` (current ``BPMAnalyzer``
  ///   producer): transpose `[frame * M + mel]` → `[mel * F + frame]`.
  /// - ``TensorLayout/nchw``: already mel-major; copy through as-is.
  private func featurize(_ features: MLFeatureFrames) -> [Float]? {
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

    return Self.decodeLogits(output)
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
    guard !logits.isEmpty else { return nil }
    // Reject non-finite logits up front: NaN through `vDSP_maxv` is
    // unspecified, +Inf produces NaN after subtract-max, -Inf produces
    // sum == 0 which the post-exp guard catches — but explicit
    // rejection here is faster and more diagnosable (review fix M26).
    guard logits.allSatisfy({ $0.isFinite }) else { return nil }
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
    let bpm = bpmBinOffset + Double(maxIdx)
    // Abstain when argmax maps outside the BPM range. The pipeline-wide
    // contract is 60-200 BPM; an out-of-range bin is either model
    // misconfiguration (wrong bin offset) or genuine OOD prediction,
    // both of which deserve abstain over silent clamp-to-boundary
    // (review fix m13).
    guard (60.0...200.0).contains(bpm) else { return nil }
    return (
      bpm: bpm,
      confidence: Double(confidence),
      secondMax: Double(secondMax)
    )
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
    os_log(
      .fault, log: Self.nilFeaturesLogger,
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
