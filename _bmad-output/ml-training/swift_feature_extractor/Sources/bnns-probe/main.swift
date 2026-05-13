//
//  bnns-probe — develop-only Story 4-5 Task 1.5b + 1.5d verification probe.
//
//  Lives outside Sources/ and Tests/ per the develop-only file-placement rule.
//  Loads a .mlmodelc via BNNSGraphCompileFromFile and answers two questions
//  the BoomBoomBoomKit BNNSTechnique conformance needs to know before the
//  destructor and the evaluate body are written:
//
//    1) Task 1.5b — Who owns `graph.data`?
//       Calls `malloc_zone_from_ptr(graph.data)` and `malloc_get_zone_name`
//       to determine if BNNSGraphCompileFromFile returns memory allocated
//       from the default malloc zone (in which case `free(graph.data)` is
//       the correct destructor primitive) or from a custom zone / read-only
//       mmap (in which case `free` is undefined behavior and we need a
//       different release primitive).
//
//    2) Task 1.5d — Does the model output probabilities or logits?
//       Feeds a deterministic input (1*1*128*512 Float(0.5)) through the
//       graph and inspects the 256-element output. If the values sum to
//       1.0 ± 1e-5 and all lie in [0, 1], the model has a softmax tail
//       and BNNSTechnique can emit confidence directly. Otherwise the
//       model emits logits and BNNSTechnique needs a host-side softmax
//       via vForce.exp + vDSP.sum + vDSP.divide.
//
//  Findings are appended to the artifact log at
//  `_bmad-output/implementation-artifacts/4-5-allocator-probe.log` for
//  Task 1.5c reference and for Task 4-5 implementation guidance.
//

import Accelerate
import Darwin
import Foundation

// MARK: - CLI argument parsing

struct ProbeOptions {
  var mlmodelcPath: String
  var outputLogPath: String
}

func parseArguments() -> ProbeOptions {
  var mlmodelc: String?
  var output: String?
  var i = 1
  let args = CommandLine.arguments
  while i < args.count {
    let arg = args[i]
    switch arg {
    case "--mlmodelc":
      guard i + 1 < args.count else {
        FileHandle.standardError.write(Data("--mlmodelc requires a path argument\n".utf8))
        exit(2)
      }
      mlmodelc = args[i + 1]
      i += 2
    case "--output":
      guard i + 1 < args.count else {
        FileHandle.standardError.write(Data("--output requires a path argument\n".utf8))
        exit(2)
      }
      output = args[i + 1]
      i += 2
    case "-h", "--help":
      print(
        """
        bnns-probe — Story 4-5 Task 1.5b/d allocator + logit probe.

        Usage:
          bnns-probe --mlmodelc <path> --output <log-path>

        Both arguments are REQUIRED. The CLI does not assume any default path
        because it runs from inside _bmad-output/ml-training/swift_feature_extractor.
        """)
      exit(0)
    default:
      FileHandle.standardError.write(Data("unknown argument: \(arg)\n".utf8))
      exit(2)
    }
  }
  guard let mlmodelc, let output else {
    FileHandle.standardError.write(
      Data("both --mlmodelc and --output are required (run with --help)\n".utf8))
    exit(2)
  }
  return ProbeOptions(mlmodelcPath: mlmodelc, outputLogPath: output)
}

// MARK: - Log helper

final class ProbeLog {
  private let url: URL
  private var lines: [String] = []
  init(path: String) {
    self.url = URL(fileURLWithPath: path)
  }
  func log(_ line: String) {
    print(line)
    lines.append(line)
  }
  func flushAppend() throws {
    let body = lines.joined(separator: "\n") + "\n"
    if FileManager.default.fileExists(atPath: url.path) {
      let fh = try FileHandle(forWritingTo: url)
      defer { try? fh.close() }
      try fh.seekToEnd()
      try fh.write(contentsOf: Data(body.utf8))
    } else {
      try body.data(using: .utf8)!.write(to: url)
    }
  }
}

// MARK: - Main

@available(macOS 15.0, *)
func runProbe(_ opts: ProbeOptions) throws {
  let log = ProbeLog(path: opts.outputLogPath)
  let isoDate = ISO8601DateFormatter().string(from: Date())
  log.log("================================================================")
  log.log("bnns-probe @ \(isoDate)")
  log.log("mlmodelc: \(opts.mlmodelcPath)")
  log.log("================================================================")

  // Verify the input artifact exists.
  guard FileManager.default.fileExists(atPath: opts.mlmodelcPath) else {
    log.log("FATAL: mlmodelc not found at supplied path")
    try log.flushAppend()
    exit(1)
  }

  // --- Compile the graph -----------------------------------------------
  let compileOptions = BNNSGraphCompileOptionsMakeDefault()
  defer { BNNSGraphCompileOptionsDestroy(compileOptions) }

  let graph: bnns_graph_t = opts.mlmodelcPath.withCString { cpath in
    BNNSGraphCompileFromFile(cpath, nil, compileOptions)
  }
  guard let graphData = graph.data, graph.size != 0 else {
    log.log(
      "FATAL: BNNSGraphCompileFromFile returned empty graph (data=\(String(describing: graph.data)), size=\(graph.size))"
    )
    try log.flushAppend()
    exit(1)
  }
  log.log(
    "BNNSGraphCompileFromFile succeeded: graph.data=\(graphData), graph.size=\(graph.size) bytes")

  // --- Task 1.5b: allocator zone probe ---------------------------------
  log.log("")
  log.log("-- Task 1.5b: allocator zone probe -----------------------------")
  let zone = malloc_zone_from_ptr(graphData)
  if let zone {
    let namePtr = malloc_get_zone_name(zone)
    let zoneName: String = namePtr.flatMap { String(validatingUTF8: $0) } ?? "(unnamed zone)"
    let defaultZone = malloc_default_zone()
    let inDefaultZone = (zone == defaultZone)
    log.log("malloc_zone_from_ptr(graph.data) returned: \(zone)")
    log.log("malloc_get_zone_name(zone)          = \(zoneName)")
    log.log("malloc_default_zone()               = \(defaultZone)")
    log.log("pointer is in default zone          = \(inDefaultZone)")
    if inDefaultZone {
      log.log(
        "VERDICT: graph.data is default-zone malloc'd; `free(graph.data)` is the correct destructor."
      )
    } else {
      log.log(
        "VERDICT: graph.data is in a NON-default zone (\(zoneName)). Apple may own the lifetime.")
      log.log(
        "         Do NOT call `free()`; use the zone's own deallocator if exposed, or accept the leak."
      )
    }
  } else {
    log.log("malloc_zone_from_ptr returned NULL — pointer is NOT in any registered malloc zone.")
    log.log("VERDICT: graph.data is likely mmap'd or owned by BNNS internals.")
    log.log(
      "         `free(graph.data)` is undefined behavior; expect mmap or another release primitive."
    )
  }

  // --- Task 1.5d: logit-vs-probability verification --------------------
  log.log("")
  log.log("-- Task 1.5d: logit-vs-probability verification ----------------")

  // Resolve argument positions by name (DD #16) so the test inputs are
  // routed by name regardless of declaration order.
  let inputIdx = "input".withCString { BNNSGraphGetArgumentPosition(graph, nil, $0) }
  let outputIdx = "output".withCString { BNNSGraphGetArgumentPosition(graph, nil, $0) }
  log.log("BNNSGraphGetArgumentPosition(input)  = \(inputIdx)")
  log.log("BNNSGraphGetArgumentPosition(output) = \(outputIdx)")
  // Apple imports `size_t` (unsigned) as Swift `Int` (signed); SIZE_T_MAX
  // surfaces as -1. Guard with `>= 0`.
  guard inputIdx >= 0, outputIdx >= 0 else {
    log.log("FATAL: argument positions did not resolve (input=\(inputIdx), output=\(outputIdx))")
    try log.flushAppend()
    exit(1)
  }

  var context = BNNSGraphContextMake(graph)
  defer { BNNSGraphContextDestroy(context) }
  guard context.data != nil, context.size != 0 else {
    log.log("FATAL: BNNSGraphContextMake returned empty context")
    try log.flushAppend()
    exit(1)
  }
  log.log("BNNSGraphContextMake succeeded: context.size=\(context.size)")

  let setArgTypeResult = BNNSGraphContextSetArgumentType(context, BNNSGraphArgumentTypeTensor)
  log.log("BNNSGraphContextSetArgumentType(.Tensor) = \(setArgTypeResult)")

  // Query workspace size. Returns SIZE_T_MAX on failure (which surfaces as
  // Int(-1) under Clang's size_t -> Swift Int import bridge).
  let workspaceSize = BNNSGraphContextGetWorkspaceSize(context, nil)
  log.log("BNNSGraphContextGetWorkspaceSize = \(workspaceSize) bytes")
  guard workspaceSize >= 0 else {
    log.log("FATAL: workspace size query failed (size_t SIZE_T_MAX = -1 in Swift)")
    try log.flushAppend()
    exit(1)
  }
  var workspace: UnsafeMutableRawPointer?
  if workspaceSize > 0 {
    // BNNSGraphContextExecute's workspace argument "MUST be page-aligned"
    // per the header. macOS page size is 16384 on Apple Silicon.
    let pageSize = Int(sysconf(Int32(_SC_PAGESIZE)))
    workspace = UnsafeMutableRawPointer.allocate(byteCount: workspaceSize, alignment: pageSize)
  }
  defer { workspace?.deallocate() }

  // Query the model's declared input + output tensors so we feed the
  // graph using the shapes IT advertises rather than hard-coded shapes.
  var inputTensor = BNNSTensor()
  let inMetaStatus = "input".withCString {
    BNNSGraphContextGetTensor(context, nil, $0, true, &inputTensor)
  }
  var outputTensor = BNNSTensor()
  let outMetaStatus = "output".withCString {
    BNNSGraphContextGetTensor(context, nil, $0, true, &outputTensor)
  }
  log.log(
    "BNNSGraphContextGetTensor(input)  status=\(inMetaStatus) rank=\(inputTensor.rank) shape=\(tensorShape(inputTensor))"
  )
  log.log(
    "BNNSGraphContextGetTensor(output) status=\(outMetaStatus) rank=\(outputTensor.rank) shape=\(tensorShape(outputTensor))"
  )
  guard inMetaStatus == 0, outMetaStatus == 0 else {
    log.log("FATAL: BNNSGraphContextGetTensor failed")
    try log.flushAppend()
    exit(1)
  }

  // Build deterministic input: 1*1*128*512 = 65536 Float(0.5)
  let inputCount = 1 * 1 * 128 * 512
  var input = [Float](repeating: 0.5, count: inputCount)
  var output = [Float](repeating: 0, count: 256)

  // Point the BNNS-supplied tensors at our caller-owned buffers. Shape /
  // stride / rank were set by BNNSGraphContextGetTensor — we only attach
  // the data pointer + byte count.
  input.withUnsafeMutableBytes { rawBuf in
    inputTensor.data = rawBuf.baseAddress
    inputTensor.data_size_in_bytes = rawBuf.count
  }
  output.withUnsafeMutableBytes { rawBuf in
    outputTensor.data = rawBuf.baseAddress
    outputTensor.data_size_in_bytes = rawBuf.count
  }

  // The graph_argument union is: tensor / descriptor / data_ptr. Apple's
  // header dictates that when SetArgumentType == .Tensor, we set .tensor
  // to a pointer to a stack BNNSTensor.
  let execStatus: Int32 = withUnsafeMutablePointer(to: &inputTensor) { inPtr in
    withUnsafeMutablePointer(to: &outputTensor) { outPtr in
      var args = [bnns_graph_argument_t](repeating: bnns_graph_argument_t(), count: 2)
      // Convention: outputs precede inputs in the arguments array per
      // BNNSGraphContextExecute's documented contract — the indices
      // returned by BNNSGraphGetArgumentPosition follow that same
      // ordering.
      args[outputIdx].tensor = outPtr
      args[outputIdx].data_ptr_size = MemoryLayout<Float>.size * 256
      args[inputIdx].tensor = inPtr
      args[inputIdx].data_ptr_size = MemoryLayout<Float>.size * inputCount
      return args.withUnsafeMutableBufferPointer { argsPtr in
        BNNSGraphContextExecute(
          context,
          nil,
          argsPtr.count,
          argsPtr.baseAddress!,
          workspaceSize,
          workspace?.assumingMemoryBound(to: CChar.self)
        )
      }
    }
  }
  log.log("BNNSGraphContextExecute status = \(execStatus)")
  guard execStatus == 0 else {
    log.log("FATAL: BNNSGraphContextExecute returned non-zero status \(execStatus)")
    try log.flushAppend()
    exit(1)
  }

  // Analyze the output.
  let sum = output.reduce(0.0) { $0 + Double($1) }
  let outMin = output.min()!
  let outMax = output.max()!
  let argmaxIdx = output.firstIndex(of: outMax) ?? -1
  let predictedBPM = 30.0 + Double(argmaxIdx)

  log.log(
    "output[0..<8]   = \(output.prefix(8).map { String(format: "%.5f", $0) }.joined(separator: ", "))"
  )
  log.log("output.sum      = \(String(format: "%.6f", sum))")
  log.log("output.min      = \(String(format: "%.6f", outMin))")
  log.log("output.max      = \(String(format: "%.6f", outMax))")
  log.log("output.argmax   = \(argmaxIdx)  → predicted_bpm = 30 + argmax = \(predictedBPM)")

  let isProbability = abs(sum - 1.0) < 1e-5 && outMin >= 0.0 && outMax <= 1.0
  if isProbability {
    log.log("VERDICT: output is a SOFTMAX/PROBABILITY distribution (sum=1, values in [0,1]).")
    log.log(
      "         BNNSTechnique.evaluate(trace:) may consume `output.max()` directly as confidence.")
  } else {
    log.log("VERDICT: output is LOGITS (sum ≠ 1 or values outside [0,1]).")
    log.log("         BNNSTechnique.evaluate(trace:) MUST insert a host-side softmax")
    log.log("         (vForce.exp + vDSP.sum + vDSP.divide, with subtract-max-for-stability).")
  }

  try log.flushAppend()
}

// MARK: - Helpers

@available(macOS 15.0, *)
func tensorShape(_ tensor: BNNSTensor) -> String {
  // BNNSTensor.shape is `ssize_t shape[BNNS_MAX_TENSOR_DIMENSION]` which
  // imports into Swift as an 8-tuple of Int. Walk only `rank` entries.
  var t = tensor
  return withUnsafePointer(to: &t.shape) { tuplePtr -> String in
    tuplePtr.withMemoryRebound(to: Int.self, capacity: Int(tensor.rank)) { dims in
      let arr = (0..<Int(tensor.rank)).map { dims[$0] }
      return arr.description
    }
  }
}

// MARK: - Entry point

if #available(macOS 15.0, *) {
  do {
    try runProbe(parseArguments())
  } catch {
    FileHandle.standardError.write(Data("probe failed: \(error)\n".utf8))
    exit(1)
  }
} else {
  FileHandle.standardError.write(Data("bnns-probe requires macOS 15.0+\n".utf8))
  exit(1)
}
