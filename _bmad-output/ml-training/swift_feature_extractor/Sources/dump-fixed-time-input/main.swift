//
//  dump-fixed-time-input — Story 15.5.
//
//  Develop-only Swift CLI. Mirrors the fixed-time crop preprocessing in Swift so
//  the Python harness (`fixed_time/features.py`) can be checked against it:
//
//    log-mel from the real substrate (`OnsetFeaturesBuilder.build(.uniform)`,
//    single-sourced from BoomBoomBoomKit), then the crop plan (1200-frame crops
//    every 600 frames, plus one tail crop ending on the last frame when the
//    regular crops stop short), then per crop a mel-major transpose and the
//    per-band population z-score with `vDSP_normalize` (a band whose std is 0
//    or not finite is zeroed, as `BNNSTechnique.featurize` does). No resize.
//
//  It also records the library's rhythm score for each crop, the score the
//  Python harness ports to rank crops: each exact 530,807-sample crop slice is
//  passed to `RhythmicRegionSelector.probeRegions` (internal, reached through
//  `@testable import` in a debug build) with a duration covering the whole
//  slice, and the returned single region must start at 0 and span the slice.
//
//  The existing parity signals (1 s, 5 s) are shorter than one 12 s crop, so this
//  tool writes two signals to ../parity_signals/:
//    - click_120bpm_20s.f32: a 20 s 120 BPM click (generator verbatim from
//      dump-fixture / TestSignalGenerators). 1996 frames: regular crops at 0 and
//      600 and a tail crop at 796. Its crops score almost the same.
//    - rhythm_mix_40s.f32: 12 s of the 120 BPM click, 12 s of silence, then 16 s
//      of seeded uniform noise (SplitMix64 seed 20261029) at amplitude
//      0.3 x (1 + 0.3 sin(2 pi 0.5 t)), a slowly swelling noise bed. 3996 frames,
//      six crops whose scores range from the click's down to 0, with the noise
//      crops' activity factor below 1, so the ranking and the activity term are
//      both compared. (A pure-tone drone was tried first: it leaves mel bands
//      nearly constant, and the per-band z-score then magnifies float32
//      rounding past the stage-6 tolerance, as the stage-4/5 sine rows show.)
//
//  Run from `swift_feature_extractor/`:
//    swift run dump-fixed-time-input
//  Writes, per signal, out/swift_stages/<signal>_fixed_time_crops.f32
//  ([n_crops, 128, 1200] float32, row-major) and
//  out/swift_stages/<signal>_fixed_time.json (frame count, crop starts,
//  per-crop rhythm scores).
//

import Accelerate
import Foundation

@testable import BoomBoomBoomKit

let sampleRate: Double = 44_100
let melBandsExpected = 128
let hopSamples = 441
let fftSize = 2048
let cropFrames = 1200
let cropHopFrames = 600
let cropSamples = (cropFrames - 1) * hopSamples + fftSize  // 530,807

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("dump-fixed-time-input: \(message)\n".utf8))
  exit(1)
}

func writeFloats(_ values: [Float], to url: URL) throws {
  let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
  try data.write(to: url)
}

// Verbatim from Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift
// (the same copy dump-fixture carries).
func generateClickTrack(bpm: Double, sampleRate: Double, durationSeconds: Double) -> [Float] {
  let sampleCount = Int(sampleRate * durationSeconds)
  var samples = [Float](repeating: 0, count: sampleCount)
  let samplesPerBeat = Int(sampleRate * 60.0 / bpm)
  for beatStart in stride(from: 0, to: sampleCount, by: samplesPerBeat) {
    let impulseEnd = min(beatStart + 64, sampleCount)
    for i in beatStart..<impulseEnd {
      let decay = Float(exp(-Double(i - beatStart) / 10.0))
      samples[i] = decay
    }
  }
  return samples
}

/// SplitMix64 (the TestSignalGenerators PRNG), uniform in [-1, 1).
struct SplitMix64 {
  var state: UInt64
  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
  mutating func nextSigned() -> Double {
    Double(next() >> 11) * 0x1.0p-53 * 2 - 1
  }
}

/// 12 s click, 12 s silence, 16 s swelling noise (see the header).
func generateRhythmMix() -> [Float] {
  let sr = Int(sampleRate)
  var samples = [Float](repeating: 0, count: 40 * sr)
  let click = generateClickTrack(bpm: 120.0, sampleRate: sampleRate, durationSeconds: 12.0)
  samples.replaceSubrange(0..<click.count, with: click)
  var rng = SplitMix64(state: 20_261_029)
  for i in (24 * sr)..<(40 * sr) {
    let swell = 0.3 * (1 + 0.3 * sin(2 * Double.pi * 0.5 * Double(i) / sampleRate))
    samples[i] = Float(swell * rng.nextSigned())
  }
  return samples
}

/// Start frames: every 600 frames while a crop fits, plus one tail crop ending
/// on the last frame when the regular crops stop short. Empty below 1200 frames.
func cropPlan(frames: Int) -> [Int] {
  guard frames >= cropFrames else { return [] }
  var starts = Array(stride(from: 0, through: frames - cropFrames, by: cropHopFrames))
  if let last = starts.last, last + cropFrames < frames {
    starts.append(frames - cropFrames)
  }
  return starts
}

/// One crop: frame-major `[frame * M + mel]` source -> mel-major `[M, 1200]`,
/// z-scored per band.
func zscoredCrop(frameMajor: [Float], melBands: Int, start: Int) -> [Float] {
  var melMajor = [Float](repeating: 0, count: melBands * cropFrames)
  frameMajor.withUnsafeBufferPointer { src in
    melMajor.withUnsafeMutableBufferPointer { dst in
      guard let srcBase = src.baseAddress, let dstBase = dst.baseAddress else { return }
      // The crop's frames are contiguous in the frame-major source.
      vDSP_mtrans(
        srcBase + start * melBands, 1, dstBase, 1,
        vDSP_Length(melBands), vDSP_Length(cropFrames))
    }
  }
  melMajor.withUnsafeMutableBufferPointer { buf in
    guard let base = buf.baseAddress else { return }
    var mean: Float = 0
    var stddev: Float = 0
    for mel in 0..<melBands {
      let row = base + mel * cropFrames
      vDSP_normalize(row, 1, row, 1, &mean, &stddev, vDSP_Length(cropFrames))
      if stddev == 0 || !stddev.isFinite {
        vDSP_vclr(row, 1, vDSP_Length(cropFrames))
      }
    }
  }
  return melMajor
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let paritySignalsDir = cwd.appendingPathComponent("../parity_signals")
let stagesDir = cwd.appendingPathComponent("out/swift_stages")
try FileManager.default.createDirectory(at: paritySignalsDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: stagesDir, withIntermediateDirectories: true)

func dump(signalName: String, signal: [Float]) throws {
  let signalURL = paritySignalsDir.appendingPathComponent("\(signalName).f32")
  try writeFloats(signal, to: signalURL)

  let decoded = FeatureSubstrate.DecodedAudio(
    samples: signal,
    sampleRate: sampleRate,
    codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone))

  let onset: FeatureSubstrate.OnsetFeatures
  do {
    onset = try FeatureSubstrate.OnsetFeaturesBuilder.build(decoded: decoded, weighting: .uniform)
  } catch {
    fail("OnsetFeaturesBuilder.build failed: \(error)")
  }
  guard onset.melBands == melBandsExpected else {
    fail("substrate emitted \(onset.melBands) mel bands, expected \(melBandsExpected)")
  }
  guard onset.tensorLayout == .frameMajorLogMel else {
    fail("substrate layout \(onset.tensorLayout), expected frameMajorLogMel")
  }
  guard onset.parameters.hopSize == 441, onset.parameters.fftSize == 2048 else {
    fail(
      "substrate hop/fft \(onset.parameters.hopSize)/\(onset.parameters.fftSize), "
        + "the fixed-time contract needs 441/2048")
  }

  let starts = cropPlan(frames: onset.frames)
  guard !starts.isEmpty else {
    fail("\(signalName) has \(onset.frames) frames, fewer than one \(cropFrames)-frame crop")
  }
  var crops: [Float] = []
  crops.reserveCapacity(starts.count * onset.melBands * cropFrames)
  for start in starts {
    crops.append(
      contentsOf: zscoredCrop(frameMajor: onset.logMelData, melBands: onset.melBands, start: start))
  }

  /// The library's rhythm score of one exact crop slice, through `probeRegions`.
  func rhythmScore(start: Int) -> Float {
    let begin = start * hopSamples
    guard begin + cropSamples <= signal.count else {
      fail("crop at frame \(start) overruns the \(signal.count)-sample signal")
    }
    let slice = Array(signal[begin..<(begin + cropSamples)])
    // A duration longer than the slice: probeRegions caps the span at the slice.
    let regions = RhythmicRegionSelector.probeRegions(
      samples: slice, sampleRate: sampleRate,
      durationSeconds: Double(cropSamples) / sampleRate + 1)
    guard regions.count == 1, regions[0].startSample == 0,
      regions[0].sampleCount == cropSamples
    else {
      fail(
        "probeRegions on a \(cropSamples)-sample slice returned "
          + "\(regions.map { ($0.startSample, $0.sampleCount) }), expected one region (0, \(cropSamples))"
      )
    }
    return regions[0].rhythmScore
  }
  let rhythmScores = starts.map { Double(rhythmScore(start: $0)) }

  let cropsURL = stagesDir.appendingPathComponent("\(signalName)_fixed_time_crops.f32")
  try writeFloats(crops, to: cropsURL)
  let manifest: [String: Any] = [
    "signal": "\(signalName).f32",
    "samples": signal.count,
    "frames": onset.frames,
    "melBands": onset.melBands,
    "cropFrames": cropFrames,
    "cropHopFrames": cropHopFrames,
    "cropStarts": starts,
    "cropSamples": cropSamples,
    "rhythmScores": rhythmScores,
    "rhythmScoreSource": "RhythmicRegionSelector.probeRegions on each exact crop slice",
    "cropsPath": cropsURL.lastPathComponent,
    "layout": "[n_crops, mel, frame] float32 row-major, z-scored per crop per band",
    "featureSetVersion": onset.featureSetVersion,
  ]
  let manifestURL = stagesDir.appendingPathComponent("\(signalName)_fixed_time.json")
  let json = try JSONSerialization.data(
    withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
  try json.write(to: manifestURL)

  print(
    "\(signalName): \(signal.count) samples, \(onset.frames) frames -> crops at \(starts) "
      + "-> \(cropsURL.lastPathComponent); rhythm scores \(rhythmScores)")
}

try dump(
  signalName: "click_120bpm_20s",
  signal: generateClickTrack(bpm: 120.0, sampleRate: sampleRate, durationSeconds: 20.0))
try dump(signalName: "rhythm_mix_40s", signal: generateRhythmMix())
