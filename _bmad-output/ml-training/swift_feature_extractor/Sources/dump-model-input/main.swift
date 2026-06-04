//
//  dump-model-input — Story 7.5 Task 1 / AC1 / DD #15.
//
//  Develop-only Swift CLI. Dumps the POST-`featurize` model-input tensor
//  (`[1, 1, 128, 512]` NCHW row-major, mel-major + z-scored + resampled) that
//  `BNNSTechnique.evaluate(trace:)` feeds the BNNSGraph at runtime — the seam
//  FR-21 train/runtime feature identity rides on (Story 7.5 DD #15).
//
//  Unlike `dump-fixture` (which re-implements the mel DSP line-for-line and
//  stops at the z-scored log-mel envelope), this target DEPENDS on
//  BoomBoomBoomKit + BoomBoomBoomKitML and single-sources the REAL pipeline:
//  `FeatureSubstrate.OnsetFeaturesBuilder.build(.uniform)` →
//  `BNNSTechnique.modelInputTensor(from:)`. The Python parity harness
//  (test_feature_parity.py stage 5) compares its own `feature_substrate_v2.py`
//  reconstruction against this dump at the 1e-4/1e-3 tolerance, proving the
//  training feature pipeline produces the same tensor the runtime infers on.
//
//  Run from `swift_feature_extractor/`:
//    swift run dump-model-input
//  Reads the parity signals dump-fixture wrote to ../parity_signals/ and
//  writes out/swift_stages/<name>_stage5_model_input.f32 (65536 floats each).
//

import BoomBoomBoomKit
@_spi(FeatureParity) import BoomBoomBoomKitML
import Foundation

let sampleRate: Double = 44_100
let expectedMelBands = 128
let expectedWidth = 512

func readFloats(_ url: URL) throws -> [Float] {
  let data = try Data(contentsOf: url)
  return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
}

func writeFloats(_ values: [Float], to url: URL) throws {
  let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
  try data.write(to: url)
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("dump-model-input: \(message)\n".utf8))
  exit(1)
}

guard #available(macOS 15.0, *) else {
  fail("requires macOS 15+ (BNNSTechnique availability)")
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let paritySignalsDir = cwd.appendingPathComponent("../parity_signals")
let stagesDir = cwd.appendingPathComponent("out/swift_stages")
try FileManager.default.createDirectory(at: stagesDir, withIntermediateDirectories: true)

// Same deterministic parity signals dump-fixture emits (sine + click). They
// must already exist on disk — run `swift run dump-fixture` first.
let signals: [(name: String, file: String)] = [
  ("sine_440Hz_1s", "sine_440Hz_1s.f32"),
  ("click_120bpm_5s", "click_120bpm_5s.f32"),
]

for signal in signals {
  let signalURL = paritySignalsDir.appendingPathComponent(signal.file)
  guard FileManager.default.fileExists(atPath: signalURL.path) else {
    fail("missing parity signal \(signal.file) — run `swift run dump-fixture` first")
  }
  let samples = try readFloats(signalURL)

  let decoded = FeatureSubstrate.DecodedAudio(
    samples: samples,
    sampleRate: sampleRate,
    codecPriming: FeatureSubstrate.PrimingInfo(
      codec: .wav, leadingTrimFrames: 0, trailingTrimFrames: 0))

  let onset: FeatureSubstrate.OnsetFeatures
  do {
    onset = try FeatureSubstrate.OnsetFeaturesBuilder.build(decoded: decoded, weighting: .uniform)
  } catch {
    fail("OnsetFeaturesBuilder.build failed for \(signal.name): \(error)")
  }

  // Reconstruct the MLFeatureFrames the runtime producer would hand
  // `BNNSTechnique.featurize`. Only melBands/frames/tensorLayout/logMelData
  // affect `modelInputTensor`; the remaining fields are carried for fidelity.
  let frames: MLFeatureFrames
  do {
    frames = try MLFeatureFrames(
      melBands: onset.melBands,
      frames: onset.frames,
      tensorLayout: onset.tensorLayout,
      logMelData: onset.logMelData,
      sampleRate: sampleRate,
      fftSize: onset.parameters.fftSize,
      hopSize: onset.parameters.hopSize,
      melFmin: onset.parameters.melFmin,
      melFmax: onset.parameters.melFmax,
      logCompressionScale: onset.parameters.logCompressionScale,
      featureSetVersion: onset.featureSetVersion)
  } catch {
    fail("MLFeatureFrames.init failed for \(signal.name): \(error)")
  }

  guard let tensor = BNNSTechnique.modelInputTensor(from: frames) else {
    fail(
      "BNNSTechnique.modelInputTensor returned nil for \(signal.name) "
        + "(frames=\(onset.frames), melBands=\(onset.melBands)) — degenerate input")
  }
  guard tensor.count == expectedMelBands * expectedWidth else {
    fail(
      "model-input tensor for \(signal.name) is \(tensor.count) floats, "
        + "expected \(expectedMelBands * expectedWidth) (= 128 x 512)")
  }

  let outURL = stagesDir.appendingPathComponent("\(signal.name)_stage5_model_input.f32")
  try writeFloats(tensor, to: outURL)
  print(
    "\(signal.name): featureSetVersion=\(onset.featureSetVersion) "
      + "source frames=\(onset.frames) -> model-input tensor \(tensor.count) floats "
      + "([128, 512]) -> \(outURL.lastPathComponent)")
}

print("dump-model-input: stage-5 model-input tensors written to out/swift_stages/")
