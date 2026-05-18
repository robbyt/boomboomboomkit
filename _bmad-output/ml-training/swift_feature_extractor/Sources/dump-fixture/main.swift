//
//  main.swift
//  swift-feature-extractor (dump-fixture)
//
//  Story 4-4b — Task 3.1. Dumps the shared feature_pipeline_v1 fixture
//  (filterbank + STFT window + DSP constants) and per-stage outputs on a
//  deterministic test signal. The Python parity harness consumes both.
//
//  Usage:
//    swift run dump-fixture            # writes raw binaries + JSON to ./out/
//

import Accelerate
import CryptoKit
import Foundation

// ---------------------------------------------------------------------------
// Constants — must match Sources/BoomBoomBoomKit/BPMAnalyzer.swift line numbers
// referenced inline. If any of these change, the parity harness fails loudly.
// ---------------------------------------------------------------------------

let sampleRate: Double = 44_100
let nFFT = 2048  // BPMAnalyzer.fftSize (line 39)
let nMels = 128  // BPMAnalyzer.melBands (line 445)
let fMin: Double = 30.0  // BPMAnalyzer.melFmin (line 448)
let fMax = min(sampleRate / 2.0, 16_000.0)  // BPMAnalyzer.effectiveFmax (line 510)
let hopSize = Int(sampleRate / 100.0)  // BPMAnalyzer line 216 → 441 at 44.1kHz
let halfN = nFFT / 2  // BPMAnalyzer.magnitudeBins (line 45) = 1024 (NOT 1025)
let featureSetVersion = "v1"

// ---------------------------------------------------------------------------
// MelFilterbank.buildFilterbank — verbatim copy from
// Sources/BoomBoomBoomKit/MelFilterbank.swift lines 32-105.
// Slaney-normalized triangular filterbank. Filterbank is row-major
// (melBands rows × halfN cols). Note halfN = fftSize / 2 = 1024 (not 1025).
// ---------------------------------------------------------------------------

func hzToMel(_ hz: Double) -> Double {
  2595.0 * log10(1.0 + hz / 700.0)
}

func melToHz(_ mel: Double) -> Double {
  700.0 * (pow(10.0, mel / 2595.0) - 1.0)
}

func buildFilterbank(
  melBands: Int, fftSize: Int, sampleRate: Double, fmin: Double, fmax: Double
) -> [Float] {
  let freqBins = fftSize / 2

  let melMin = hzToMel(fmin)
  let melMax = hzToMel(fmax)

  let numPoints = melBands + 2
  var melPoints = [Double](repeating: 0, count: numPoints)
  let melStep = (melMax - melMin) / Double(numPoints - 1)
  for i in 0..<numPoints {
    melPoints[i] = melMin + Double(i) * melStep
  }

  var binIndices = [Int](repeating: 0, count: numPoints)
  for i in 0..<numPoints {
    let hz = melToHz(melPoints[i])
    binIndices[i] = Int(floor(Double(fftSize) * hz / sampleRate))
  }

  var filterbank = [Float](repeating: 0, count: melBands * freqBins)

  for m in 0..<melBands {
    let left = binIndices[m]
    let center = binIndices[m + 1]
    let right = binIndices[m + 2]

    if center > left {
      for k in left...min(center, freqBins - 1) {
        guard k >= 0, k < freqBins else { continue }
        filterbank[m * freqBins + k] = Float(k - left) / Float(center - left)
      }
    }

    if right > center {
      for k in center...min(right, freqBins - 1) {
        guard k >= 0, k < freqBins else { continue }
        filterbank[m * freqBins + k] = Float(right - k) / Float(right - center)
      }
    }

    if right > left {
      let norm = 2.0 / Float(right - left)
      for k in max(left, 0)..<min(right + 1, freqBins) {
        filterbank[m * freqBins + k] *= norm
      }
    }
  }
  return filterbank
}

// ---------------------------------------------------------------------------
// STFT pipeline — mirrors Sources/BoomBoomBoomKit/BPMAnalyzer.swift §
// computeMelOnsetEnvelopeWithSubBands lines 490-585.
//   1. Frame audio into nFFT windows hopping by hopSize.
//   2. Apply vDSP.window(.hanningDenormalized) — IDENTICAL to BPMAnalyzer line 502.
//   3. Real-FFT via vDSP.FFT(log2n=11, .radix2, DSPSplitComplex).
//   4. vDSP_zvmags → POWER spectrum (NOT magnitude). halfN bins.
//      Note: bin 0 of split-complex packs DC^2 + Nyquist^2 (vDSP convention).
//      BPMAnalyzer does not separate them; we mirror that quirk.
//   5. vDSP_mmul: filterbank (128, halfN) × power (halfN, 1) = melEnergies (128, 1).
//   6. log compression: log1p(100 * mel) per BPMAnalyzer line 581.
// ---------------------------------------------------------------------------

let log2n = vDSP_Length(log2(Double(nFFT)))

func sttfPower(samples: [Float], window: [Float]) -> [[Float]] {
  guard
    let fft = vDSP.FFT(
      log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self
    )
  else {
    return []
  }

  let realp = UnsafeMutablePointer<Float>.allocate(capacity: halfN)
  let imagp = UnsafeMutablePointer<Float>.allocate(capacity: halfN)
  let outRealp = UnsafeMutablePointer<Float>.allocate(capacity: halfN)
  let outImagp = UnsafeMutablePointer<Float>.allocate(capacity: halfN)
  defer {
    realp.deallocate()
    imagp.deallocate()
    outRealp.deallocate()
    outImagp.deallocate()
  }
  realp.initialize(repeating: 0, count: halfN)
  imagp.initialize(repeating: 0, count: halfN)
  outRealp.initialize(repeating: 0, count: halfN)
  outImagp.initialize(repeating: 0, count: halfN)

  var windowedFrame = [Float](repeating: 0, count: nFFT)
  var powerSpectrum = [Float](repeating: 0, count: halfN)
  var frames: [[Float]] = []

  var position = 0
  while position + nFFT <= samples.count {
    samples.withUnsafeBufferPointer { samplesPtr in
      vDSP_vmul(
        samplesPtr.baseAddress! + position, 1,
        window, 1,
        &windowedFrame, 1,
        vDSP_Length(nFFT)
      )
    }

    windowedFrame.withUnsafeBufferPointer { buf in
      buf.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { ptr in
        var split = DSPSplitComplex(realp: realp, imagp: imagp)
        vDSP_ctoz(ptr, 2, &split, 1, vDSP_Length(halfN))
      }
    }

    let input = DSPSplitComplex(realp: realp, imagp: imagp)
    var output = DSPSplitComplex(realp: outRealp, imagp: outImagp)
    fft.forward(input: input, output: &output)
    vDSP_zvmags(&output, 1, &powerSpectrum, 1, vDSP_Length(halfN))

    frames.append(powerSpectrum)
    position += hopSize
  }

  return frames
}

func applyMelLogCompression(
  powerFrames: [[Float]], filterbank: [Float]
) -> [[Float]] {
  var logMelFrames: [[Float]] = []
  logMelFrames.reserveCapacity(powerFrames.count)

  var melEnergies = [Float](repeating: 0, count: nMels)
  var scaled = [Float](repeating: 0, count: nMels)
  var logOutput = [Float](repeating: 0, count: nMels)

  for ps in powerFrames {
    vDSP.clear(&melEnergies)
    filterbank.withUnsafeBufferPointer { fbPtr in
      ps.withUnsafeBufferPointer { psPtr in
        vDSP_mmul(
          fbPtr.baseAddress!, 1,
          psPtr.baseAddress!, 1,
          &melEnergies, 1,
          vDSP_Length(nMels),
          vDSP_Length(1),
          vDSP_Length(halfN)
        )
      }
    }

    var multiplier: Float = 100.0
    vDSP_vsmul(melEnergies, 1, &multiplier, &scaled, 1, vDSP_Length(nMels))
    var one: Float = 1.0
    vDSP_vsadd(scaled, 1, &one, &scaled, 1, vDSP_Length(nMels))
    var count = Int32(nMels)
    vvlogf(&logOutput, &scaled, &count)

    logMelFrames.append(logOutput)
  }

  return logMelFrames
}

// ---------------------------------------------------------------------------
// Stage 4 z-score (per-mel-band across time axis)
// ---------------------------------------------------------------------------

func zscorePerBand(_ logMelFrames: [[Float]]) -> [[Float]] {
  guard let first = logMelFrames.first else { return [] }
  let bands = first.count
  let frames = logMelFrames.count
  guard frames > 0 else { return logMelFrames }

  // Compute mean + std per band across time
  var means = [Float](repeating: 0, count: bands)
  var stds = [Float](repeating: 0, count: bands)
  for b in 0..<bands {
    var sum: Float = 0
    for f in 0..<frames { sum += logMelFrames[f][b] }
    let m = sum / Float(frames)
    means[b] = m
    var sq: Float = 0
    for f in 0..<frames { sq += (logMelFrames[f][b] - m) * (logMelFrames[f][b] - m) }
    stds[b] = (sq / Float(frames)).squareRoot()
  }

  var output = logMelFrames
  for f in 0..<frames {
    for b in 0..<bands {
      output[f][b] = (logMelFrames[f][b] - means[b]) / (stds[b] + 1e-8)
    }
  }
  return output
}

// ---------------------------------------------------------------------------
// Click-track signal generator — verbatim from
// Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// IO helpers
// ---------------------------------------------------------------------------

func writeFloats(_ values: [Float], to url: URL) throws {
  let data = values.withUnsafeBufferPointer { buf -> Data in
    Data(bytes: buf.baseAddress!, count: buf.count * MemoryLayout<Float>.size)
  }
  try data.write(to: url)
}

func writeFloats2D(_ values: [[Float]], to url: URL) throws {
  let flat = values.flatMap { $0 }
  try writeFloats(flat, to: url)
}

func sha256Hex(_ data: Data) -> String {
  let hash = SHA256.hash(data: data)
  return hash.map { String(format: "%02x", $0) }.joined()
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

@main
struct DumpFixture {
  static func main() throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let outDir = cwd.appendingPathComponent("out")
    let paritySignalsDir = cwd.appendingPathComponent("../parity_signals")
    let stagesDir = outDir.appendingPathComponent("swift_stages")
    try fm.createDirectory(at: outDir, withIntermediateDirectories: true)
    try fm.createDirectory(at: paritySignalsDir, withIntermediateDirectories: true)
    try fm.createDirectory(at: stagesDir, withIntermediateDirectories: true)

    print("== feature_pipeline_v1 fixture builder ==")

    // Build filterbank + window
    let filterbank = buildFilterbank(
      melBands: nMels, fftSize: nFFT, sampleRate: sampleRate, fmin: fMin, fmax: fMax
    )
    print("Filterbank: \(nMels) × \(halfN) = \(filterbank.count) floats")

    let window = vDSP.window(
      ofType: Float.self, usingSequence: .hanningDenormalized,
      count: nFFT, isHalfWindow: false
    )
    print("STFT window: \(window.count) floats (Hann denormalized)")

    // Persist binaries
    let filterbankURL = outDir.appendingPathComponent("mel_filterbank.f32")
    let windowURL = outDir.appendingPathComponent("stft_window.f32")
    try writeFloats(filterbank, to: filterbankURL)
    try writeFloats(window, to: windowURL)

    // Generate parity signals — 1s of 440 Hz sine + 5s of 120 BPM click
    var sine = [Float](repeating: 0, count: Int(sampleRate))
    let twoPiF = 2.0 * Double.pi * 440.0
    for i in 0..<sine.count {
      sine[i] = Float(sin(twoPiF * Double(i) / sampleRate))
    }
    let click = generateClickTrack(bpm: 120.0, sampleRate: sampleRate, durationSeconds: 5.0)

    let sineURL = paritySignalsDir.appendingPathComponent("sine_440Hz_1s.f32")
    let clickURL = paritySignalsDir.appendingPathComponent("click_120bpm_5s.f32")
    try writeFloats(sine, to: sineURL)
    try writeFloats(click, to: clickURL)
    print("Parity signals: sine=\(sine.count) samples, click=\(click.count) samples")

    // Run pipeline on each parity signal — emit Stage 2/3/4 outputs
    var stagesManifest: [String: [String: Any]] = [:]
    for (name, audio, _) in [
      ("sine_440Hz_1s", sine, sineURL),
      ("click_120bpm_5s", click, clickURL),
    ] {
      print("\nProcessing \(name) (\(audio.count) samples)...")
      let powerFrames = sttfPower(samples: audio, window: window)
      let logMelFrames = applyMelLogCompression(
        powerFrames: powerFrames, filterbank: filterbank
      )
      let zscored = zscorePerBand(logMelFrames)

      let frameCount = powerFrames.count
      print("  Frames: \(frameCount)")

      let stage2URL = stagesDir.appendingPathComponent("\(name)_stage2_raw_mel_power.f32")
      let stage3URL = stagesDir.appendingPathComponent("\(name)_stage3_log_mel.f32")
      let stage4URL = stagesDir.appendingPathComponent("\(name)_stage4_zscored.f32")

      // Stage 2: pre-log mel energies (apply filterbank to power, NO log)
      var preLogMel: [[Float]] = []
      preLogMel.reserveCapacity(powerFrames.count)
      var melEnergies = [Float](repeating: 0, count: nMels)
      for ps in powerFrames {
        vDSP.clear(&melEnergies)
        filterbank.withUnsafeBufferPointer { fbPtr in
          ps.withUnsafeBufferPointer { psPtr in
            vDSP_mmul(
              fbPtr.baseAddress!, 1,
              psPtr.baseAddress!, 1,
              &melEnergies, 1,
              vDSP_Length(nMels),
              vDSP_Length(1),
              vDSP_Length(halfN)
            )
          }
        }
        preLogMel.append(melEnergies)
      }

      try writeFloats2D(preLogMel, to: stage2URL)
      try writeFloats2D(logMelFrames, to: stage3URL)
      try writeFloats2D(zscored, to: stage4URL)

      // Bytes are written row-major as `frame_count * nMels` floats by
      // writeFloats2D(values: [[Float]]) (each "row" is one frame's
      // mel-band vector). Manifest stage shapes therefore declare
      // `[frameCount, nMels]` to match the on-disk layout — was reversed
      // (`[nMels, frameCount]`) per chunk-1 review C10. Whichever side
      // trusts the manifest would have silently transposed.
      stagesManifest[name] = [
        "audio_samples": audio.count,
        "frame_count": frameCount,
        "stage2_shape": [frameCount, nMels],
        "stage3_shape": [frameCount, nMels],
        "stage4_shape": [frameCount, nMels],
        "stage2_path": stage2URL.lastPathComponent,
        "stage3_path": stage3URL.lastPathComponent,
        "stage4_path": stage4URL.lastPathComponent,
      ]
    }

    // Compute fixture self-hash from the dumped binaries
    let fbData = try Data(contentsOf: filterbankURL)
    let winData = try Data(contentsOf: windowURL)
    var combined = Data()
    combined.append(fbData)
    combined.append(winData)
    let sha = sha256Hex(combined)
    print("\nSelf-hash (fb || window): \(sha)")

    let manifest: [String: Any] = [
      "feature_set_version": featureSetVersion,
      "sample_rate": Int(sampleRate),
      "n_fft": nFFT,
      "n_mels": nMels,
      "f_min": fMin,
      "f_max": fMax,
      "hop_size": hopSize,
      "filterbank_shape": [nMels, halfN],
      "filterbank_path": "mel_filterbank.f32",
      "stft_window_path": "stft_window.f32",
      "stft_window_length": window.count,
      "stft_window_kind": "hanningDenormalized",
      "halfN": halfN,
      "halfN_note":
        "halfN = fftSize / 2 = 1024 (NOT n_fft/2+1 = 1025). bin 0 packs DC^2 + Nyquist^2 per vDSP_zvmags convention.",
      // Endianness contract: raw .f32 binaries are written with the host's
      // native float byte order. macOS Apple Silicon is little-endian. If
      // this ever runs on a big-endian host, consumers must byte-swap.
      "byte_order": "little",
      "float_dtype": "f32",
      "sha256": sha,
      "stages": stagesManifest,
    ]

    let manifestData = try JSONSerialization.data(
      withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]
    )
    try manifestData.write(to: outDir.appendingPathComponent("manifest.json"))
    print("\nWrote: \(outDir.appendingPathComponent("manifest.json").path)")
    print("Done.")
  }
}
