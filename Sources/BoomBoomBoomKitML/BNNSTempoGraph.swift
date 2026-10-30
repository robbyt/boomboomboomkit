//
//  BNNSTempoGraph.swift
//  BoomBoomBoomKitML
//
//  The compiled BNNSGraph shared by `BNNSTechnique` (512-frame input) and
//  `FixedTimeTechnique` (1200-frame input): load, tensor-contract check, and
//  per-call inference. Moved here unchanged from `BNNSTechnique` with the
//  input width made a parameter.
//

import Accelerate
import BoomBoomBoomKit
import Darwin
import Foundation

/// A compiled tempo-classifier graph with input `[1, 1, 128, inputWidth]`
/// named `input` and a 256-element output named `output`.
@available(macOS 15.0, *)
internal struct BNNSTempoGraph: @unchecked Sendable {

  /// Mel bands every tempo model in this target reads.
  static let melBands = 128

  /// Output bins: `bpm = 30 + argmax`.
  static let binCount = 256

  /// Compiled graph + workspace ownership. Final class so its `deinit`
  /// runs when the last copy drops.
  let handle: BNNSGraphHandle

  /// Argument index for the graph's input tensor, resolved by NAME at
  /// init via `BNNSGraphGetArgumentPosition` per DD #16. Hard-coded
  /// positions are forbidden because a re-converted model with renamed
  /// arguments would silently swap input/output.
  let srcIndex: Int

  /// Argument index for the graph's output tensor.
  let dstIndex: Int

  /// Total argument count reported by `BNNSGraphGetArgumentCount` at init.
  /// Sizes the per-call argument array so a graph with auxiliary arguments
  /// doesn't cause OOB writes when `srcIndex` / `dstIndex` exceed 1.
  let argumentCount: Int

  /// The time-axis width this graph was validated against.
  let inputWidth: Int

  /// Loads, compiles, and validates the model at `modelURL`.
  ///
  /// - Throws: ``MLTechniqueError/modelResourceMissing(_:)`` when the file
  ///   is absent, ``MLTechniqueError/modelLoadFailed(underlying:)`` when the
  ///   compile fails, and the contract errors of `validateContract`.
  init(modelURL: URL, inputWidth: Int) throws {
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
    // and shape, and graph-argument-count BEFORE caching anything. Free
    // graph data on any failure so the lifecycle contract holds even on
    // the throw path.
    let validation: (src: Int, dst: Int, argumentCount: Int)
    do {
      validation = try Self.validateContract(graph: graph, inputWidth: inputWidth)
    } catch {
      BNNSTechnique.releaseGraphData(graph.data)
      throw error
    }

    self.handle = BNNSGraphHandle(graph: graph)
    self.srcIndex = validation.src
    self.dstIndex = validation.dst
    self.argumentCount = validation.argumentCount
    self.inputWidth = inputWidth
  }

  // MARK: - inferLogits

  /// Per-call BNNSGraph inference. Builds a new `bnns_graph_context_t`,
  /// runs `BNNSGraphContextExecute`, and returns the raw logit `[Float]`
  /// (length `binCount`) — or nil if any BNNS API call fails.
  ///
  /// Returns logits only; softmax and decode are the caller's. Keeping them
  /// apart lets a caller report
  /// ``MLDiagnosticSnapshot/FailureStage/graphFailed`` (this function
  /// returns nil) separately from
  /// ``MLDiagnosticSnapshot/FailureStage/decodeRejected`` (the caller's
  /// decode rejected the logits). `inputTensor` must hold
  /// `melBands * inputWidth` floats, mel-major.
  func inferLogits(
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
    var output = [Float](repeating: 0, count: Self.binCount)

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

  // MARK: - validateContract

  /// Asserts the compiled graph exposes argument names `"input"` /
  /// `"output"`, distinct positions, input rank 4 with shape
  /// `[1, 1, melBands, inputWidth]` and `data_type == .float`,
  /// and output rank `1...BNNS_MAX_TENSOR_DIMENSION` with total element
  /// count `== binCount` and `data_type == .float`. Returns the
  /// resolved `(src, dst, argumentCount)` tuple so `init(modelURL:inputWidth:)` does
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
  static func validateContract(
    graph: bnns_graph_t, inputWidth: Int
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
    // drift (the bytes won't look like [1, 1, melBands, inputWidth]); the assertion below
    // catches the rest with a debug-only sanity bound (review fix C3).
    let inputShape: [Int] = withUnsafePointer(to: &inputTensor.shape) { tuplePtr in
      tuplePtr.withMemoryRebound(to: Int.self, capacity: maxRank) { dims in
        Array(UnsafeBufferPointer(start: dims, count: inputRank))
      }
    }
    assert(
      inputShape.allSatisfy { $0 > 0 && $0 <= 1 << 30 },
      "BNNSTensor.shape element out of plausible range (got \(inputShape)) — possible import-type drift; review the C3 guards in BNNSTempoGraph"
    )
    let expectedInputShape: [Int] = [1, 1, melBands, inputWidth]
    guard inputShape == expectedInputShape else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "input.shape \(expectedInputShape) (got \(inputShape))")
    }
    guard inputTensor.data_type == BNNSDataType.float else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "input.data_type Float (got raw=\(inputTensor.data_type.rawValue))")
    }

    // Verify OUTPUT contract: rank 1...8, total element count ==
    // binCount, dtype Float.
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
      "BNNSTensor.shape element out of plausible range (got \(outputShape)) — possible import-type drift; review the C3 guards in BNNSTempoGraph"
    )
    // Total element count must match binCount — checking the
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
    guard totalElements == binCount else {
      throw MLTechniqueError.binCountMismatch(
        expected: binCount, actual: totalElements)
    }
    guard outputTensor.data_type == BNNSDataType.float else {
      throw MLTechniqueError.invalidTensorContract(
        missing: "output.data_type Float (got raw=\(outputTensor.data_type.rawValue))")
    }

    return (src: inputIdx, dst: outputIdx, argumentCount: argCount)
  }

  /// Host-side softmax of raw logits (subtract the max, exponentiate,
  /// normalize). `nil` for empty or non-finite logits, or a non-positive
  /// sum.
  static func softmax(_ logits: [Float]) -> [Float]? {
    guard !logits.isEmpty, logits.allSatisfy({ $0.isFinite }) else { return nil }
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
    return probs
  }
}
