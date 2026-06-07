//
//  dump-real-track — Story 7.5 full-run wiring (Epic 7 close-out), Phase 1.5.
//
//  Develop-only Swift CLI. Runs the FULL runtime path
//  (`AudioAnalysisService.analyzeBPM` with `.thorough` + `.mlOnly`) on ONE REAL
//  audio file, then dumps, from the SELECTED analysis window's trace:
//    - the Swift log-mel envelope (`MLFeatureFrames.logMelData`, frame-major)
//    - the post-`modelInputTensor` `[128, 512]` model-input tensor
//    - a manifest with `analysisWindowSeconds`, `energyTransitionOffset`,
//      `melBands`, `frames` (so Python reconstructs the IDENTICAL window/F).
//
//  Why dump the log-mel AND the tensor (not just re-featurize from audio): a
//  from-audio comparison would conflate the Swift AVFoundation decode + the
//  BPMAnalyzer mel with the Python librosa decode + reimplemented mel. Feeding
//  Python the EXACT Swift log-mel isolates the ONE step Phase 1.5 must verify on
//  a real multi-minute track (large F): the z-score + resample-to-512 that
//  `feature_substrate_v2` was hand-written to match but that ml-parity stage 5
//  only exercised on short (F<=496) sine/click fixtures.
//
//  Run from `swift_feature_extractor/`:
//    swift run dump-real-track --audio /path/to/track.mp3 --out out/real_track \
//        [--model ../../ml-models/giantsteps_v1.mlmodelc]
//

import Accelerate
import BoomBoomBoomKit
@_spi(FeatureParity) import BoomBoomBoomKitML
import Foundation

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("dump-real-track: \(message)\n".utf8))
  exit(1)
}

func argValue(_ name: String) -> String? {
  let args = CommandLine.arguments
  guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
  return args[i + 1]
}

func writeFloats(_ values: [Float], to url: URL) throws {
  let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
  try data.write(to: url)
}

guard #available(macOS 15.0, *) else { fail("requires macOS 15+ (BNNSTechnique availability)") }

guard let audioArg = argValue("--audio") else { fail("missing --audio <path>") }
guard let outArg = argValue("--out") else { fail("missing --out <dir>") }
// Any loadable model triggers captureMLFeatures (we only read the feature
// payload, never the prediction). Default to the develop-only v1 reference.
let modelArg =
  argValue("--model")
  ?? FileManager.default.currentDirectoryPath + "/../../ml-models/giantsteps_v1.mlmodelc"

let audioURL = URL(fileURLWithPath: audioArg)
let outDir = URL(fileURLWithPath: outArg)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let technique: BNNSTechnique
do {
  technique = try BNNSTechnique(modelURL: URL(fileURLWithPath: modelArg))
} catch {
  fail("BNNSTechnique(modelURL: \(modelArg)) failed: \(error)")
}

var opts = AudioAnalysisService.Options()
opts.intensity = .thorough  // 30/60/90 windows — the FR-18 producer intensity
opts.ensemblePolicy = .mlOnly  // triggers ML feature capture on the selected window
opts.mlTechnique = technique
opts.enableTrace = true
opts.enableMLDiagnostics = true

let result: AudioAnalysisResult?
do {
  result = try AudioAnalysisService.analyzeBPM(url: audioURL, options: opts)
} catch {
  fail("analyzeBPM failed for \(audioArg): \(error)")
}

guard let trace = result?.trace else { fail("no trace on result") }
guard let features = trace.mlFeatures else {
  fail("trace.mlFeatures nil — captureMLFeatures did not fire (model not wired?)")
}
guard let tensor = BNNSTechnique.modelInputTensor(from: features) else {
  fail("BNNSTechnique.modelInputTensor returned nil")
}

try writeFloats(features.logMelData, to: outDir.appendingPathComponent("log_mel.f32"))
try writeFloats(tensor, to: outDir.appendingPathComponent("model_input.f32"))

// Dump the EXACT vDSP_vramp control vector the runtime resample uses (mirror of
// BNNSTechnique.modelInputTensor Step 3) so the Python featurizer can match
// vDSP_vramp's true output rather than guess its accumulation behavior.
let W = 512
let F = features.frames
var controlVector = [Float](repeating: 0, count: W)
var rampStart: Float = 0
var rampStep = Float(F - 1) / Float(W - 1)
vDSP_vramp(&rampStart, &rampStep, &controlVector, 1, vDSP_Length(W))
controlVector[W - 1] = controlVector[W - 1].nextDown
try writeFloats(controlVector, to: outDir.appendingPathComponent("control.f32"))

struct Manifest: Codable {
  let audio: String
  let analysisWindowSeconds: Double
  let energyTransitionOffset: Int
  let sampleRate: Double
  let melBands: Int
  let frames: Int
  let tensorLayout: String
  let logMelCount: Int
  let modelInputCount: Int
  let resultBPM: Double?
}

let manifest = Manifest(
  audio: audioArg,
  analysisWindowSeconds: trace.analysisWindowDuration,
  energyTransitionOffset: trace.energyTransitionOffset,
  sampleRate: features.sampleRate,
  melBands: features.melBands,
  frames: features.frames,
  tensorLayout: features.tensorLayout.rawValue,
  logMelCount: features.logMelData.count,
  modelInputCount: tensor.count,
  resultBPM: result?.bpm)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
try encoder.encode(manifest).write(to: outDir.appendingPathComponent("manifest.json"))

print(
  "dump-real-track: window=\(trace.analysisWindowDuration)s "
    + "offset=\(trace.energyTransitionOffset) melBands=\(features.melBands) "
    + "frames=\(features.frames) layout=\(features.tensorLayout.rawValue) "
    + "-> \(outDir.path)")
