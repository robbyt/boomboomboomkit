//
//  BPMAnalyzer.swift
//  BoomBoomBoomKit
//
//  BPM Analyzer (Onset Detection + Beat Tracking)
//

import Accelerate
import Foundation

/// Result of BPM estimation.
struct BPMResult: Sendable {
  /// Estimated tempo in beats per minute.
  let bpm: Double
  /// Confidence score (0.0 - 1.0) indicating reliability of the estimate.
  let confidence: Double
  /// Top candidates pre-disambiguation (internal use for benchmarking).
  let candidates: [(bpm: Double, score: Float)]
  /// Diagnostic trace capturing per-step pipeline state. Nil unless `enableTrace` was true.
  let trace: BPMDiagnosticTrace?
}

/// Estimates tempo from decoded PCM audio samples using spectral flux onset
/// detection and autocorrelation-based beat tracking (Davies & Plumbley 2007).
///
/// `BPMAnalyzer` is a pure DSP component — it accepts `[Float]` mono samples,
/// not encoded audio. Codec decoding (MP3, FLAC, WAV, etc.) is handled upstream
/// by `PCMBufferReader`, which produces the shared `[Float]` currency type
/// consumed by both `BPMAnalyzer` and `LUFSAnalyzer`. This separation ensures
/// the analyzer has no knowledge of audio formats or file I/O.
///
/// Stateless struct with static methods. Only imports `Foundation` and
/// `Accelerate` — no external dependencies.
struct BPMAnalyzer {

  // MARK: - Constants

  /// FFT size: 2048 samples (~46ms at 44.1kHz). Power of 2 for vDSP radix-2 FFT.
  private static let fftSize = 2048

  /// log2(2048) = 11 for vDSP.FFT
  private static let log2n = vDSP_Length(11)

  /// Number of magnitude bins from split-complex FFT output (fftSize / 2)
  private static let magnitudeBins = fftSize / 2

  /// Minimum BPM to detect
  private static let minBPM: Double = 40

  /// Maximum BPM to detect
  private static let maxBPM: Double = 250

  /// RMS silence threshold: 10^(-60/20) ≈ 0.001
  private static let silenceThreshold: Float = 0.001

  /// Minimum audio duration in seconds for reliable BPM estimation
  private static let minimumDurationSeconds: Double = 4.0

  /// Default analysis window duration in seconds (applied after energy scan)
  private static let defaultAnalysisWindowSeconds: Double = 30.0

  /// Energy transition threshold: RMS must exceed this multiple of running average
  private static let energyTransitionMultiplier: Float = 2.0

  /// Tempogram window duration in seconds (8s Hann window over onset envelope)
  private static let tempogramWindowSeconds: Double = 8.0

  /// Perceptual BPM range for octave normalization
  private static let perceptualMinBPM: Double = 60.0
  private static let perceptualMaxBPM: Double = 200.0

  /// Octave disambiguation: minimum sub-beat energy ratio to prefer faster tempo
  private static let octaveEnergyThreshold: Float = 0.3

  /// Octave disambiguation: minimum score ratio vs current best to accept faster tempo
  private static let octaveScoreThreshold: Float = 0.5

  // MARK: - Sub-Band Constants (Story 33-6)

  /// Mel bin ranges for 4 frequency sub-bands (matching docs/bpm.md Step 3)
  private static let kickBandRange = 0..<20  // ~30-200 Hz
  private static let snareLowRange = 20..<50  // ~200-1000 Hz
  private static let snareCrackRange = 50..<80  // ~1000-4000 Hz
  private static let hiHatRange = 80..<128  // ~4000-16000 Hz

  /// Weights for sub-band voting (kick down-weighted, hi-hat up-weighted)
  private static let bandWeights: [Float] = [0.5, 1.0, 1.5, 2.0]  // kick, snare body, snare crack, hi-hat

  // MARK: - Options

  /// Configuration options for BPM estimation.
  ///
  /// All fields have sensible defaults. Most callers can use `.init()`.
  struct Options: Sendable {
    /// Duration of analysis window after energy transition (default 30s).
    var analysisWindowSeconds: Double = defaultAnalysisWindowSeconds

    /// Controls pipeline depth and is recorded in the diagnostic trace.
    var intensity: AnalysisIntensity = .default

    /// Explicit technique set, overriding `intensity.techniqueSet` for pipeline gating.
    /// When `nil` (default), techniques are derived from `intensity`.
    var techniques: TechniqueSet?

    /// When `true`, populates `BPMResult.trace` with per-step diagnostic data.
    var enableTrace: Bool = false
  }

  // MARK: - Public API

  /// Estimates the tempo (BPM) of audio samples using multi-estimator fusion.
  ///
  /// Pipeline: energy scan → mel onset → autocorrelation + Fourier tempogram →
  /// periodicity fusion → TPS2 enhancement → peak extraction → range normalization →
  /// octave disambiguation → confidence.
  ///
  /// - Parameters:
  ///   - samples: Mono PCM samples as `[Float]` (up to 120s for energy scan).
  ///   - sampleRate: Sample rate of the audio (e.g., 44100.0).
  /// - Returns: A `BPMResult` with BPM and confidence, or `nil` for
  ///   silence/noise/too-short input.
  static func estimateBPM(
    samples: [Float],
    sampleRate: Double
  ) -> BPMResult? {
    estimateBPM(samples: samples, sampleRate: sampleRate, options: .init())
  }

  /// Estimates the tempo (BPM) of audio samples using multi-estimator fusion.
  ///
  /// - Parameters:
  ///   - samples: Mono PCM samples as `[Float]` (up to 120s for energy scan).
  ///   - sampleRate: Sample rate of the audio (e.g., 44100.0).
  ///   - options: Configuration controlling analysis window, intensity, techniques, and tracing.
  /// - Returns: A `BPMResult` with BPM and confidence, or `nil` for
  ///   silence/noise/too-short input.
  static func estimateBPM(
    samples: [Float],
    sampleRate: Double,
    options: Options
  ) -> BPMResult? {
    let techniques = options.techniques ?? options.intensity.techniqueSet
    guard !samples.isEmpty else { return nil }

    let duration = Double(samples.count) / sampleRate
    guard duration >= minimumDurationSeconds else { return nil }

    // Step 1: Energy scan — find the "drop" for analysis window selection
    let dropOffset = findEnergyTransition(samples: samples, sampleRate: sampleRate)
    let windowSamples = Int(options.analysisWindowSeconds * sampleRate)
    let endSample = min(dropOffset + windowSamples, samples.count)
    guard endSample > dropOffset else { return nil }
    let analysisWindow = Array(samples[dropOffset..<endSample])

    // Step 2: Silence check on analysis window
    guard !isSilent(analysisWindow) else { return nil }

    let windowDuration = Double(analysisWindow.count) / sampleRate
    guard windowDuration >= minimumDurationSeconds else { return nil }

    // Initialize trace if requested
    var trace: BPMDiagnosticTrace? = options.enableTrace ? BPMDiagnosticTrace() : nil
    trace?.energyTransitionOffset = dropOffset
    trace?.analysisWindowDuration = windowDuration
    trace?.intensityUsed = options.intensity

    // Adaptive hop: always 10ms regardless of sample rate
    let hopSize = Int(sampleRate / 100)
    let onsetRate = sampleRate / Double(hopSize)

    // Step 3: Mel-spectrogram onset detection with sub-band envelopes
    let onsetResult = computeMelOnsetEnvelopeWithSubBands(
      samples: analysisWindow, sampleRate: sampleRate, hopSize: hopSize,
      computeSubBands: techniques.contains(.subBandVoting),
      normalizeSubBands: techniques.contains(.subBandNormalization))
    var onsetEnvelope = onsetResult.fullBand
    guard !onsetEnvelope.isEmpty else { return nil }

    trace?.onsetEnvelopeLength = onsetEnvelope.count
    if options.enableTrace {
      let bandNames = ["kick", "snare", "crack", "hihat"]
      var energies: [String: Float] = [:]
      for (i, band) in onsetResult.subBands.enumerated()
      where i < bandNames.count && !band.isEmpty {
        var maxVal: Float = 0
        vDSP_maxv(band, 1, &maxVal, vDSP_Length(band.count))
        energies[bandNames[i]] = maxVal
      }
      trace?.subBandEnergies = energies
    }

    // Step 3.5: Adaptive thresholding on full-band onset envelope
    if techniques.contains(.adaptiveThreshold) {
      onsetEnvelope = adaptiveThreshold(envelope: onsetEnvelope, onsetRate: onsetRate)
    }

    // Step 4: FFT-based autocorrelation
    var acf = computeAutocorrelation(onsetEnvelope)
    guard !acf.isEmpty else { return nil }

    // Step 4.1: ACF peak sharpening — element-wise square
    if techniques.contains(.acfSharpening) {
      vDSP_vsq(acf, 1, &acf, 1, vDSP_Length(acf.count))
    }

    if options.enableTrace {
      trace?.acfTopLags = extractTopPeaks(from: acf, count: 5)
        .map { (lag: $0.index, strength: $0.value) }
    }

    // Step 4b: Sub-band autocorrelations (empty when sub-bands skipped at intensity 1-2)
    let subBandACFs: [[Float]] =
      techniques.contains(.subBandVoting)
      ? onsetResult.subBands.map { computeAutocorrelation($0) }
      : []

    let bpmMin = Int(minBPM)
    let bpmMax = Int(maxBPM)

    // Step 5: Fourier tempogram
    let tempogram = computeFourierTempogram(
      onsetEnvelope: onsetEnvelope, onsetRate: onsetRate,
      bpmMin: bpmMin, bpmMax: bpmMax)

    if options.enableTrace {
      trace?.tempogramTopBPMs = extractTopPeaks(from: tempogram, count: 5)
        .map { (bpm: $0.index + bpmMin, magnitude: $0.value) }
    }

    // Step 6: Periodicity fusion
    let fused = fusePeriodicity(
      autocorrelation: acf, fourierTempogram: tempogram,
      bpmMin: bpmMin, bpmMax: bpmMax, onsetRate: onsetRate)

    if options.enableTrace {
      trace?.fusedTopBPMs = extractTopPeaks(from: fused, count: 5)
        .map { (bpm: $0.index + bpmMin, score: $0.value) }
    }

    // Step 7: TPS2 harmonic enhancement
    let enhanced = applyTPS2Enhancement(
      periodicity: fused, bpmMin: bpmMin, bpmMax: bpmMax)

    if options.enableTrace {
      trace?.tps2TopBPMs = extractTopPeaks(from: enhanced, count: 5)
        .map { (bpm: $0.index + bpmMin, score: $0.value) }
    }

    // Step 8-9: Multi-peak extraction + range normalization
    let candidates = extractTopCandidates(
      enhanced: enhanced, bpmMin: bpmMin, count: techniques.candidateCount)
    guard !candidates.isEmpty else { return nil }

    trace?.rawCandidates = candidates

    // Step 10: Octave disambiguation with sub-band voting
    var winner = resolveOctaveAmbiguity(
      candidates: candidates, fused: fused, bpmMin: bpmMin,
      subBandACFs: subBandACFs, onsetRate: onsetRate)

    // Step 10b: Sub-band periodicity confirmation
    if techniques.contains(.subBandVoting) && !subBandACFs.isEmpty {
      let preVoteBPM = winner.bpm
      winner = confirmWithSubBandPeaks(
        winner: winner, subBandACFs: subBandACFs, onsetRate: onsetRate)

      if options.enableTrace {
        let changed = winner.bpm != preVoteBPM
        trace?.subBandVoteDetail = [
          "preVoteBPM": String(format: "%.1f", preVoteBPM),
          "postVoteBPM": String(format: "%.1f", winner.bpm),
          "changed": changed ? "true" : "false",
        ]
      }
    }

    trace?.disambiguationResult = (bpm: winner.bpm, score: winner.score)

    // Step 10c: Fine-grid tempogram refinement
    if techniques.contains(.fineGridRefinement) {
      let refinedCandidates = refineCandidates(
        candidates: [winner],
        onsetEnvelope: onsetEnvelope,
        autocorrelation: acf,
        onsetRate: onsetRate,
        bpmRange: bpmMin...bpmMax)
      if let refinedWinner = refinedCandidates.first {
        winner = refinedWinner
      }
      trace?.refinedBPM = winner.bpm
    }

    let bpm = winner.bpm
    guard bpm >= minBPM && bpm <= maxBPM else { return nil }

    // Step 11: Confidence
    let confidence = computeConfidence(fused: fused, winnerBPM: bpm, bpmMin: bpmMin)

    trace?.confidence = confidence

    return BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: trace)
  }

  // MARK: - Mel-Spectrogram Onset Detection (Story 33-4, Tasks 2-3)

  /// Number of mel bands for onset detection.
  private static let melBands = 128

  /// Minimum frequency for mel filterbank (captures kick drum fundamentals).
  private static let melFmin: Double = 30.0

  /// Maximum frequency for mel filterbank (capped to avoid ultrasonics).
  private static let melFmax: Double = 16000.0

  /// Log compression multiplier (librosa default for power_to_db-like transforms).
  private static let logCompressionScale: Float = 100.0

  /// Computes a 1D onset strength envelope using mel-spectrogram pipeline:
  /// STFT -> mel filterbank -> log compression -> temporal differencing -> HWR -> aggregation.
  ///
  /// Delegates to `computeMelOnsetEnvelopeWithSubBands` and returns only the full-band envelope.
  ///
  /// - Parameters:
  ///   - samples: Mono PCM samples.
  ///   - sampleRate: Audio sample rate in Hz.
  ///   - hopSize: Hop size in samples.
  /// - Returns: 1D onset strength envelope at `sampleRate / hopSize` fps.
  static func computeMelOnsetEnvelope(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int
  ) -> [Float] {
    return computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize
    ).fullBand
  }

  // MARK: - Sub-Band Onset Envelopes (Story 33-6, Task 1)

  /// Result of sub-band onset extraction.
  struct OnsetEnvelopes {
    let fullBand: [Float]
    let subBands: [[Float]]  // [kick, snareLow, snareCrack, hiHat]
  }

  /// Computes onset envelopes for both full-band and 4 sub-bands from mel-spectrogram.
  /// Reuses the same STFT + mel filterbank pipeline as `computeMelOnsetEnvelope`,
  /// but also produces 4 independent sub-band onset envelopes by summing within
  /// each band's mel bin range.
  static func computeMelOnsetEnvelopeWithSubBands(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    computeSubBands: Bool = true,
    normalizeSubBands: Bool = false
  ) -> OnsetEnvelopes {
    guard
      let fft = vDSP.FFT(
        log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)
    else {
      return OnsetEnvelopes(fullBand: [], subBands: [[], [], [], []])
    }

    let window = vDSP.window(
      ofType: Float.self,
      usingSequence: .hanningDenormalized,
      count: fftSize,
      isHalfWindow: false
    )

    let halfN = magnitudeBins
    let effectiveFmax = min(sampleRate / 2.0, melFmax)

    let filterbank = MelFilterbank.buildFilterbank(
      melBands: melBands, fftSize: fftSize, sampleRate: sampleRate,
      fmin: melFmin, fmax: effectiveFmax)

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

    var windowedFrame = [Float](repeating: 0, count: fftSize)
    var powerSpectrum = [Float](repeating: 0, count: halfN)
    var melEnergies = [Float](repeating: 0, count: melBands)
    var scaled = [Float](repeating: 0, count: melBands)
    var logOutput = [Float](repeating: 0, count: melBands)
    var logMelFrames: [[Float]] = []

    var position = 0
    while position + fftSize <= samples.count {
      samples.withUnsafeBufferPointer { samplesPtr in
        vDSP_vmul(
          samplesPtr.baseAddress! + position, 1,
          window, 1,
          &windowedFrame, 1,
          vDSP_Length(fftSize)
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

      melEnergies = [Float](repeating: 0, count: melBands)
      filterbank.withUnsafeBufferPointer { fbPtr in
        powerSpectrum.withUnsafeBufferPointer { psPtr in
          vDSP_mmul(
            fbPtr.baseAddress!, 1,
            psPtr.baseAddress!, 1,
            &melEnergies, 1,
            vDSP_Length(melBands),
            vDSP_Length(1),
            vDSP_Length(halfN)
          )
        }
      }

      var multiplier = logCompressionScale
      vDSP_vsmul(melEnergies, 1, &multiplier, &scaled, 1, vDSP_Length(melBands))
      var one: Float = 1.0
      vDSP_vsadd(scaled, 1, &one, &scaled, 1, vDSP_Length(melBands))
      var count = Int32(melBands)
      vvlogf(&logOutput, &scaled, &count)

      logMelFrames.append(logOutput)
      position += hopSize
    }

    guard logMelFrames.count >= 2 else {
      return OnsetEnvelopes(fullBand: [], subBands: [[], [], [], []])
    }

    let n = vDSP_Length(melBands)
    let frameCount = logMelFrames.count - 1
    var fullBandEnvelope = [Float](repeating: 0, count: frameCount)
    var subBandEnvelopes: [[Float]] = Array(
      repeating: [Float](repeating: 0, count: frameCount), count: 4)
    var diff = [Float](repeating: 0, count: melBands)
    var rectified = [Float](repeating: 0, count: melBands)

    let bandRanges = [kickBandRange, snareLowRange, snareCrackRange, hiHatRange]

    for i in 1..<logMelFrames.count {
      logMelFrames[i - 1].withUnsafeBufferPointer { prevPtr in
        logMelFrames[i].withUnsafeBufferPointer { currPtr in
          vDSP_vsub(prevPtr.baseAddress!, 1, currPtr.baseAddress!, 1, &diff, 1, n)
        }
      }

      var threshold: Float = 0
      vDSP_vthres(diff, 1, &threshold, &rectified, 1, n)

      // Full-band sum
      var sum: Float = 0
      vDSP_sve(rectified, 1, &sum, n)
      fullBandEnvelope[i - 1] = sum

      // Sub-band sums (skipped when computeSubBands is false)
      if computeSubBands {
        rectified.withUnsafeBufferPointer { rectPtr in
          for (bandIdx, range) in bandRanges.enumerated() {
            var bandSum: Float = 0
            vDSP_sve(
              rectPtr.baseAddress! + range.lowerBound, 1,
              &bandSum, vDSP_Length(range.count))
            subBandEnvelopes[bandIdx][i - 1] = bandSum
          }
        }
      }
    }

    // Per-sub-band max normalization: normalize each band to [0,1] before returning.
    // Skip bands with negligible energy (max < 1% of strongest band) to avoid
    // amplifying noise in near-silent bands.
    if computeSubBands && normalizeSubBands {
      var bandMaxes = [Float](repeating: 0, count: subBandEnvelopes.count)
      for bandIdx in 0..<subBandEnvelopes.count {
        vDSP_maxv(subBandEnvelopes[bandIdx], 1, &bandMaxes[bandIdx], vDSP_Length(frameCount))
      }
      var overallMax: Float = 0
      vDSP_maxv(bandMaxes, 1, &overallMax, vDSP_Length(bandMaxes.count))
      let energyThreshold = overallMax * 0.01  // 1% of strongest band

      for bandIdx in 0..<subBandEnvelopes.count {
        guard bandMaxes[bandIdx] > energyThreshold else { continue }
        var maxVal = bandMaxes[bandIdx]
        vDSP_vsdiv(
          subBandEnvelopes[bandIdx], 1, &maxVal,
          &subBandEnvelopes[bandIdx], 1, vDSP_Length(frameCount))
      }
    }

    let resultSubBands = computeSubBands ? subBandEnvelopes : []
    return OnsetEnvelopes(fullBand: fullBandEnvelope, subBands: resultSubBands)
  }

  // MARK: - FFT-Based Autocorrelation (Task 4)

  static func computeAutocorrelation(_ signal: [Float]) -> [Float] {
    // Zero-pad to next power of 2 (at least double length)
    let paddedLength = nextPowerOf2(signal.count * 2)
    let log2Padded = vDSP_Length(log2(Double(paddedLength)))
    let halfPadded = paddedLength / 2

    guard
      let acfFFT = vDSP.FFT(
        log2n: log2Padded, radix: .radix2, ofType: DSPSplitComplex.self)
    else {
      return []
    }

    // Allocate stable pointer buffers for all split-complex operations
    let fwdRealp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let fwdImagp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let freqRealp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let freqImagp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let invRealp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let invImagp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let acfRealp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    let acfImagp = UnsafeMutablePointer<Float>.allocate(capacity: halfPadded)
    defer {
      fwdRealp.deallocate()
      fwdImagp.deallocate()
      freqRealp.deallocate()
      freqImagp.deallocate()
      invRealp.deallocate()
      invImagp.deallocate()
      acfRealp.deallocate()
      acfImagp.deallocate()
    }
    fwdRealp.initialize(repeating: 0, count: halfPadded)
    fwdImagp.initialize(repeating: 0, count: halfPadded)
    freqRealp.initialize(repeating: 0, count: halfPadded)
    freqImagp.initialize(repeating: 0, count: halfPadded)
    invRealp.initialize(repeating: 0, count: halfPadded)
    invImagp.initialize(repeating: 0, count: halfPadded)
    acfRealp.initialize(repeating: 0, count: halfPadded)
    acfImagp.initialize(repeating: 0, count: halfPadded)

    // Zero-pad the signal
    var padded = [Float](repeating: 0, count: paddedLength)
    for i in 0..<signal.count {
      padded[i] = signal[i]
    }

    // Pack into split-complex via vDSP_ctoz
    padded.withUnsafeBufferPointer { buf in
      buf.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfPadded) { ptr in
        var split = DSPSplitComplex(realp: fwdRealp, imagp: fwdImagp)
        vDSP_ctoz(ptr, 2, &split, 1, vDSP_Length(halfPadded))
      }
    }

    // Forward FFT
    let inputSplit = DSPSplitComplex(realp: fwdRealp, imagp: fwdImagp)
    var outputSplit = DSPSplitComplex(realp: freqRealp, imagp: freqImagp)
    acfFFT.forward(input: inputSplit, output: &outputSplit)

    // Capture DC/Nyquist before vDSP_zvmags conflates them
    // (packed format: realp[0]=DC, imagp[0]=Nyquist)
    let dcPower = freqRealp[0] * freqRealp[0]
    let nyquistPower = freqImagp[0] * freqImagp[0]

    // Power spectrum: |X(f)|² written directly to invRealp for inverse FFT
    vDSP_zvmags(&outputSplit, 1, invRealp, 1, vDSP_Length(halfPadded))

    // Restore proper packed format: bin 0 was DC²+Nyquist², separate them
    invRealp[0] = dcPower
    invImagp[0] = nyquistPower

    // Inverse FFT
    let invInput = DSPSplitComplex(realp: invRealp, imagp: invImagp)
    var acfOutput = DSPSplitComplex(realp: acfRealp, imagp: acfImagp)
    acfFFT.inverse(input: invInput, output: &acfOutput)

    // Unpack via vDSP_ztoc
    var result = [Float](repeating: 0, count: paddedLength)
    var splitResult = DSPSplitComplex(realp: acfRealp, imagp: acfImagp)
    result.withUnsafeMutableBufferPointer { resBuf in
      resBuf.baseAddress!.withMemoryRebound(
        to: DSPComplex.self, capacity: halfPadded
      ) { complexPtr in
        vDSP_ztoc(&splitResult, 1, complexPtr, 2, vDSP_Length(halfPadded))
      }
    }

    // Scale by 1/(2*N)
    var scale = 1.0 / Float(2 * paddedLength)
    vDSP_vsmul(result, 1, &scale, &result, 1, vDSP_Length(paddedLength))

    return Array(result.prefix(signal.count))
  }

  // MARK: - Energy-Based Analysis Window Selection (Story 33-5, Task 8)

  /// Finds the sample offset of the first significant energy transition ("drop").
  /// Scans up to 120 seconds using 1-second RMS windows.
  ///
  /// - Parameters:
  ///   - samples: Full audio samples.
  ///   - sampleRate: Audio sample rate in Hz.
  /// - Returns: Sample offset of the drop, or 0 if no transition found.
  private static func findEnergyTransition(
    samples: [Float],
    sampleRate: Double
  ) -> Int {
    let windowSize = Int(sampleRate)
    let maxWindows = 120
    let windowCount = min(samples.count / windowSize, maxWindows)
    guard windowCount >= 2 else { return 0 }

    var runningSum: Float = 0
    for windowIdx in 0..<windowCount {
      let start = windowIdx * windowSize
      var rms: Float = 0
      samples.withUnsafeBufferPointer { ptr in
        vDSP_rmsqv(ptr.baseAddress! + start, 1, &rms, vDSP_Length(windowSize))
      }

      if windowIdx > 0 {
        let runningAvg = runningSum / Float(windowIdx)
        if rms > energyTransitionMultiplier * max(runningAvg, silenceThreshold) {
          return start
        }
      }
      runningSum += rms
    }

    return 0
  }

  // MARK: - Fourier Tempogram (Story 33-5, Task 2)

  /// Computes a Fourier tempogram: non-uniform DFT magnitude at each integer BPM
  /// from bpmMin to bpmMax over the windowed onset envelope.
  static func computeFourierTempogram(
    onsetEnvelope: [Float],
    onsetRate: Double,
    bpmMin: Int,
    bpmMax: Int
  ) -> [Float] {
    let candidateCount = bpmMax - bpmMin + 1

    // 8-second Hann window over onset envelope (or full length if shorter)
    let windowLength = min(onsetEnvelope.count, Int(tempogramWindowSeconds * onsetRate))
    guard windowLength > 0 else { return [Float](repeating: 0, count: candidateCount) }

    var hannWindow = [Float](repeating: 0, count: windowLength)
    vDSP_hann_window(&hannWindow, vDSP_Length(windowLength), Int32(vDSP_HANN_DENORM))

    // Apply window to onset envelope
    var windowed = [Float](repeating: 0, count: windowLength)
    vDSP_vmul(onsetEnvelope, 1, hannWindow, 1, &windowed, 1, vDSP_Length(windowLength))

    // Allocate cos/sin buffers once, reuse across all candidates
    let cosBuffer = UnsafeMutablePointer<Float>.allocate(capacity: windowLength)
    let sinBuffer = UnsafeMutablePointer<Float>.allocate(capacity: windowLength)
    let phaseInput = UnsafeMutablePointer<Float>.allocate(capacity: windowLength)
    defer {
      cosBuffer.deallocate()
      sinBuffer.deallocate()
      phaseInput.deallocate()
    }

    var magnitudes = [Float](repeating: 0, count: candidateCount)

    for i in 0..<candidateCount {
      let bpm = Double(bpmMin + i)
      let freq = bpm / 60.0

      // Compute phase vector: 2*pi*freq*k/onsetRate for k = 0..<windowLength
      let phaseStep = Float(2.0 * .pi * freq / onsetRate)
      for k in 0..<windowLength {
        phaseInput[k] = phaseStep * Float(k)
      }

      // Compute cos and sin via vForce (separate in/out arrays required)
      var count = Int32(windowLength)
      vvcosf(cosBuffer, phaseInput, &count)
      vvsinf(sinBuffer, phaseInput, &count)

      // Dot products for real and imaginary sums
      var realSum: Float = 0
      var imagSum: Float = 0
      vDSP_dotpr(windowed, 1, cosBuffer, 1, &realSum, vDSP_Length(windowLength))
      vDSP_dotpr(windowed, 1, sinBuffer, 1, &imagSum, vDSP_Length(windowLength))

      magnitudes[i] = sqrtf(realSum * realSum + imagSum * imagSum)
    }

    return magnitudes
  }

  // MARK: - Parabolic ACF Interpolation (Epic 34, C1)

  /// Quadratic (3-point) interpolation of ACF at a fractional lag position.
  /// Uses parabolic fit through 3 nearest samples to eliminate the picket fence
  /// effect that causes linear interpolation to underestimate peaks at 0.5
  /// fractional lag positions (e.g., 160 BPM at 100 Hz onset rate → lag 37.500).
  private static func parabolicInterpolateACF(_ acf: [Float], at lag: Double) -> Float {
    let k = Int(lag.rounded())  // nearest integer sample
    guard k >= 1 && k + 1 < acf.count else {
      return interpolateACF(acf, at: lag)  // fallback to linear at boundaries
    }
    let y0 = acf[k - 1]
    let y1 = acf[k]
    let y2 = acf[k + 1]
    let t = Float(lag - Double(k))  // fractional offset from center sample
    // Lagrange quadratic: P(t) = y1 + 0.5*t*(y2-y0) + 0.5*t²*(y0-2y1+y2)
    return y1 + 0.5 * t * (y2 - y0) + 0.5 * t * t * (y0 - 2.0 * y1 + y2)
  }

  // MARK: - Fine-Grid Tempogram Refinement (Epic 34, S1)

  /// Pre-allocated buffers reused across tempogram magnitude evaluations.
  private struct TempogramBuffers {
    let cos: UnsafeMutablePointer<Float>
    let sin: UnsafeMutablePointer<Float>
    let phase: UnsafeMutablePointer<Float>

    static func allocate(capacity: Int) -> TempogramBuffers {
      TempogramBuffers(
        cos: .allocate(capacity: capacity),
        sin: .allocate(capacity: capacity),
        phase: .allocate(capacity: capacity))
    }

    func deallocate() {
      cos.deallocate()
      sin.deallocate()
      phase.deallocate()
    }
  }

  /// Computes tempogram magnitude at a single fractional BPM using a pre-windowed onset envelope.
  /// Reuses pre-allocated cos/sin/phase buffers to avoid per-call allocations.
  private static func tempogramMagnitude(
    bpm: Double,
    windowed: [Float],
    onsetRate: Double,
    buffers: TempogramBuffers
  ) -> Float {
    let windowLength = windowed.count
    let freq = bpm / 60.0
    let phaseStep = Float(2.0 * .pi * freq / onsetRate)
    for k in 0..<windowLength {
      buffers.phase[k] = phaseStep * Float(k)
    }
    var count = Int32(windowLength)
    vvcosf(buffers.cos, buffers.phase, &count)
    vvsinf(buffers.sin, buffers.phase, &count)

    var realSum: Float = 0
    var imagSum: Float = 0
    vDSP_dotpr(windowed, 1, buffers.cos, 1, &realSum, vDSP_Length(windowLength))
    vDSP_dotpr(windowed, 1, buffers.sin, 1, &imagSum, vDSP_Length(windowLength))

    return sqrtf(realSum * realSum + imagSum * imagSum)
  }

  /// Refines coarse integer-BPM candidates to 0.1 BPM resolution using a two-pass approach.
  /// For each candidate, evaluates the tempogram at 0.1 BPM steps in a ±4 BPM window,
  /// fuses with ACF, and returns the refined BPM with the highest fused score.
  private static func refineCandidates(
    candidates: [(bpm: Double, score: Float)],
    onsetEnvelope: [Float],
    autocorrelation: [Float],
    onsetRate: Double,
    bpmRange: ClosedRange<Int>
  ) -> [(bpm: Double, score: Float)] {
    guard !candidates.isEmpty else { return candidates }

    let windowLength = min(onsetEnvelope.count, Int(tempogramWindowSeconds * onsetRate))
    guard windowLength > 0 else { return candidates }

    // Prepare windowed onset envelope (same as computeFourierTempogram)
    var hannWindow = [Float](repeating: 0, count: windowLength)
    vDSP_hann_window(&hannWindow, vDSP_Length(windowLength), Int32(vDSP_HANN_DENORM))
    var windowed = [Float](repeating: 0, count: windowLength)
    vDSP_vmul(onsetEnvelope, 1, hannWindow, 1, &windowed, 1, vDSP_Length(windowLength))

    // Pre-allocate buffers once, reuse for all ~240 evaluations
    let buffers = TempogramBuffers.allocate(capacity: windowLength)
    defer { buffers.deallocate() }

    var refined: [(bpm: Double, score: Float)] = []

    for candidate in candidates {
      let centerBPM = candidate.bpm
      let scanMin = max(Double(bpmRange.lowerBound), centerBPM - 4.0)
      let scanMax = min(Double(bpmRange.upperBound), centerBPM + 4.0)

      // Two-pass: first collect tempogram magnitudes, then normalize and fuse
      // Use integer step counter to avoid floating-point accumulation drift
      let stepCount = Int(((scanMax - scanMin) / 0.1).rounded()) + 1
      var scanPoints: [(bpm: Double, tMag: Float, acfVal: Float)] = []
      for step in 0..<stepCount {
        let scanBPM = scanMin + Double(step) * 0.1
        let tMag = tempogramMagnitude(
          bpm: scanBPM, windowed: windowed, onsetRate: onsetRate, buffers: buffers)
        let lag = 60.0 * onsetRate / scanBPM
        let acfVal = parabolicInterpolateACF(autocorrelation, at: lag)
        scanPoints.append((bpm: scanBPM, tMag: tMag, acfVal: acfVal))
      }

      // Normalize both to [0,1] within this candidate's scan window (matching fusePeriodicity)
      let tMax = scanPoints.map(\.tMag).max() ?? 0
      let aMax = scanPoints.map(\.acfVal).max() ?? 0

      var bestBPM = centerBPM
      var bestFused: Float = 0

      for pt in scanPoints {
        let normT = tMax > 0 ? pt.tMag / tMax : 0
        let normA = aMax > 0 ? pt.acfVal / aMax : 0
        let fusedVal = normT * normA

        if fusedVal > bestFused {
          bestFused = fusedVal
          bestBPM = pt.bpm
        }
      }

      refined.append((bpm: bestBPM, score: candidate.score))
    }

    return refined
  }

  // MARK: - Periodicity Fusion (Story 33-5, Task 3)

  /// Fuses autocorrelation (lag-domain) and Fourier tempogram (BPM-domain) via
  /// element-wise product of normalized representations.
  static func fusePeriodicity(
    autocorrelation: [Float],
    fourierTempogram: [Float],
    bpmMin: Int,
    bpmMax: Int,
    onsetRate: Double
  ) -> [Float] {
    let candidateCount = bpmMax - bpmMin + 1

    // Map autocorrelation from lag-domain to BPM-domain with parabolic interpolation
    // (Epic 34, C1: eliminates picket fence effect at 0.5 fractional lag positions)
    var acfBPM = [Float](repeating: 0, count: candidateCount)
    for i in 0..<candidateCount {
      let bpm = Double(bpmMin + i)
      let lag = 60.0 * onsetRate / bpm
      acfBPM[i] = parabolicInterpolateACF(autocorrelation, at: lag)
    }

    // Normalize both to [0, 1]
    var acfMax: Float = 0
    vDSP_maxv(acfBPM, 1, &acfMax, vDSP_Length(candidateCount))
    if acfMax > 0 {
      vDSP_vsdiv(acfBPM, 1, &acfMax, &acfBPM, 1, vDSP_Length(candidateCount))
    }

    var tempogramNorm = fourierTempogram
    var tMax: Float = 0
    vDSP_maxv(tempogramNorm, 1, &tMax, vDSP_Length(candidateCount))
    if tMax > 0 {
      vDSP_vsdiv(tempogramNorm, 1, &tMax, &tempogramNorm, 1, vDSP_Length(candidateCount))
    }

    // Element-wise multiply: peaks strong in BOTH survive
    var fused = [Float](repeating: 0, count: candidateCount)
    vDSP_vmul(acfBPM, 1, tempogramNorm, 1, &fused, 1, vDSP_Length(candidateCount))

    return fused
  }

  // MARK: - TPS2 Harmonic Enhancement (Story 33-5, Task 4)

  /// Enhances periodicity by adding subharmonic contributions:
  /// TPS2(i) = P(i) + 0.5*P(i_half) + 0.25*P(i_half-1) + 0.25*P(i_half+1)
  private static func applyTPS2Enhancement(
    periodicity: [Float],
    bpmMin: Int,
    bpmMax: Int
  ) -> [Float] {
    let count = bpmMax - bpmMin + 1
    var enhanced = [Float](repeating: 0, count: count)

    for i in 0..<count {
      let bpm = Double(bpmMin + i)
      let halfBPM = bpm / 2.0
      let iHalf = Int(halfBPM) - bpmMin

      var score = periodicity[i]

      if iHalf >= 0 && iHalf < count {
        score += 0.5 * periodicity[iHalf]
      }
      if iHalf - 1 >= 0 && iHalf - 1 < count {
        score += 0.25 * periodicity[iHalf - 1]
      }
      if iHalf + 1 >= 0 && iHalf + 1 < count {
        score += 0.25 * periodicity[iHalf + 1]
      }

      enhanced[i] = score
    }

    return enhanced
  }

  // MARK: - Multi-Peak Extraction + Range Normalization (Story 33-5, Task 5)

  /// Extracts the top N peaks from the enhanced periodicity array.
  /// Each candidate is range-normalized to 60-200 BPM.
  private static func extractTopCandidates(
    enhanced: [Float],
    bpmMin: Int,
    count topN: Int
  ) -> [(bpm: Double, score: Float)] {
    // Find local maxima (value > both neighbors), track top N in-place
    var top: [(bpm: Double, score: Float)] = []

    for i in 1..<(enhanced.count - 1) {
      if enhanced[i] > enhanced[i - 1] && enhanced[i] > enhanced[i + 1] {
        let bpm = Double(bpmMin + i)
        let score = enhanced[i]
        let normalized = rangeNormalize(bpm)

        if top.count < topN {
          top.append((bpm: normalized, score: score))
          top.sort { $0.score > $1.score }
        } else if score > top[topN - 1].score {
          top[topN - 1] = (bpm: normalized, score: score)
          top.sort { $0.score > $1.score }
        }
      }
    }

    // Also check endpoints
    if enhanced.count >= 2 {
      if enhanced[0] > enhanced[1] {
        let score = enhanced[0]
        let normalized = rangeNormalize(Double(bpmMin))
        if top.count < topN {
          top.append((bpm: normalized, score: score))
          top.sort { $0.score > $1.score }
        } else if score > top[topN - 1].score {
          top[topN - 1] = (bpm: normalized, score: score)
          top.sort { $0.score > $1.score }
        }
      }
      let last = enhanced.count - 1
      if enhanced[last] > enhanced[last - 1] {
        let score = enhanced[last]
        let normalized = rangeNormalize(Double(bpmMin + last))
        if top.count < topN {
          top.append((bpm: normalized, score: score))
          top.sort { $0.score > $1.score }
        } else if score > top[topN - 1].score {
          top[topN - 1] = (bpm: normalized, score: score)
          top.sort { $0.score > $1.score }
        }
      }
    }

    return top
  }

  /// Doubles or halves a BPM value until it falls within 60-200 BPM.
  /// Returns `perceptualMinBPM` for zero, negative, or subnormal inputs.
  static func rangeNormalize(_ bpm: Double) -> Double {
    guard bpm > 0, bpm.isFinite else { return perceptualMinBPM }
    var result = bpm
    while result < perceptualMinBPM { result *= 2.0 }
    while result > perceptualMaxBPM { result /= 2.0 }
    return result
  }

  // MARK: - Sub-Band Voting (Story 33-6, Task 3)

  /// Votes between two octave-related tempo candidates using 4 sub-band autocorrelations.
  /// Each sub-band ACF votes for the candidate with the stronger peak at the corresponding lag.
  /// Votes are weighted: kick=0.5, snare body=1.0, snare crack=1.5, hi-hat=2.0.
  ///
  /// - Returns: The candidate (fast or slow) that accumulates more weighted votes.
  static func subBandVote(
    subBandACFs: [[Float]],
    candidateFast: Double,
    candidateSlow: Double,
    onsetRate: Double
  ) -> Double {
    guard subBandACFs.count == 4 else {
      return candidateFast  // Fallback if sub-bands unavailable
    }

    let lagFast = 60.0 * onsetRate / candidateFast
    let lagSlow = 60.0 * onsetRate / candidateSlow

    var fastWeight: Float = 0
    var slowWeight: Float = 0

    for (bandIdx, acf) in subBandACFs.enumerated() {
      let strengthFast = interpolateACF(acf, at: lagFast)
      let strengthSlow = interpolateACF(acf, at: lagSlow)
      let weight = bandWeights[bandIdx]

      if strengthFast > strengthSlow {
        fastWeight += weight
      } else {
        slowWeight += weight
      }
    }

    // Tie favors slow candidate (conservative — avoids false double-time)
    return fastWeight > slowWeight ? candidateFast : candidateSlow
  }

  /// Linear interpolation of ACF at a fractional lag position.
  private static func interpolateACF(_ acf: [Float], at lag: Double) -> Float {
    let lagFloor = Int(lag)
    let lagCeil = lagFloor + 1
    let frac = Float(lag - Double(lagFloor))

    if lagFloor >= 0 && lagCeil < acf.count {
      return acf[lagFloor] * (1.0 - frac) + acf[lagCeil] * frac
    } else if lagFloor >= 0 && lagFloor < acf.count {
      return acf[lagFloor]
    }
    return 0
  }

  // MARK: - Octave Disambiguation (Story 33-5, Task 6; updated Story 33-6, Task 4)

  /// Resolves octave ambiguity between candidates using sub-band voting
  /// (when available) and fused periodicity heuristic.
  private static func resolveOctaveAmbiguity(
    candidates: [(bpm: Double, score: Float)],
    fused: [Float],
    bpmMin: Int,
    subBandACFs: [[Float]] = [],
    onsetRate: Double = 0
  ) -> (bpm: Double, score: Float) {
    guard candidates.count >= 2 else {
      return candidates.first ?? (bpm: 0, score: 0)
    }

    var best = candidates[0]

    // Check for octave pairs (2:1 ratio within 4% tolerance)
    for i in 0..<candidates.count {
      for j in (i + 1)..<candidates.count {
        let faster = candidates[i].bpm > candidates[j].bpm ? candidates[i] : candidates[j]
        let slower = candidates[i].bpm > candidates[j].bpm ? candidates[j] : candidates[i]

        let ratio = faster.bpm / slower.bpm
        guard ratio > 1.92 && ratio < 2.08 else { continue }

        // Story 33-6: Sub-band voting promotes to faster tempo only.
        // If bands vote for faster, override to faster. If bands vote for
        // slower, fall through to fused-periodicity heuristic (don't demote).
        if subBandACFs.count == 4 && onsetRate > 0 {
          let winner = subBandVote(
            subBandACFs: subBandACFs,
            candidateFast: faster.bpm,
            candidateSlow: slower.bpm,
            onsetRate: onsetRate)
          if winner == faster.bpm {
            best = faster
            continue  // Sub-band vote decided, skip fused heuristic for this pair
          }
          // Bands voted slow — fall through to fused-periodicity heuristic
        }

        // Fallback: original fused-periodicity heuristic
        let fasterIdx = Int(faster.bpm.rounded()) - bpmMin
        let slowerIdx = Int(slower.bpm.rounded()) - bpmMin

        if fasterIdx >= 0 && fasterIdx < fused.count && slowerIdx >= 0
          && slowerIdx < fused.count
        {
          let fasterEnergy = fused[fasterIdx]
          let slowerEnergy = fused[slowerIdx]

          if fasterEnergy >= octaveEnergyThreshold * slowerEnergy {
            if faster.score >= best.score * octaveScoreThreshold {
              best = faster
            }
          }
        }
      }
    }

    return best
  }

  // MARK: - Sub-Band Periodicity Confirmation (Story 33-6)

  /// Checks hi-hat and snare crack sub-band ACFs for strong peaks at
  /// faster tempos. Uses Fourier tempogram on treble sub-bands to find the
  /// actual dominant periodicity in the hi-hat range.
  ///
  /// This handles the common DnB failure mode where the full-band pipeline
  /// locks onto a swing/triplet periodicity (~106 BPM) while the true
  /// breakbeat tempo (160 BPM) is visible in the hi-hat band.
  private static func confirmWithSubBandPeaks(
    winner: (bpm: Double, score: Float),
    subBandACFs: [[Float]],
    onsetRate: Double
  ) -> (bpm: Double, score: Float) {
    guard subBandACFs.count == 4 else { return winner }

    // Only try promotion when winner is in 80-130 range (suspect half/two-thirds time)
    guard winner.bpm >= 80 && winner.bpm <= 130 else { return winner }

    // Find the peak BPM in the hi-hat sub-band ACF within the fast range (140-200)
    let fastRangeMinBPM = 140
    let fastRangeMaxBPM = 200
    let hiHatACF = subBandACFs[3]

    var hiHatBestBPM: Double = 0
    var hiHatBestStrength: Float = 0

    for bpm in fastRangeMinBPM...fastRangeMaxBPM {
      let lag = 60.0 * onsetRate / Double(bpm)
      let strength = interpolateACF(hiHatACF, at: lag)
      if strength > hiHatBestStrength {
        hiHatBestStrength = strength
        hiHatBestBPM = Double(bpm)
      }
    }

    // Compare hi-hat band's fast-range peak against its value at the winner BPM
    let hiHatAtWinner = interpolateACF(hiHatACF, at: 60.0 * onsetRate / winner.bpm)

    // Hi-hat band must clearly prefer the faster tempo
    guard hiHatBestStrength > hiHatAtWinner else { return winner }

    // Confirm with snare crack band: at least check it doesn't strongly oppose
    let snareCrackACF = subBandACFs[2]
    let snareCrackAtFast = interpolateACF(snareCrackACF, at: 60.0 * onsetRate / hiHatBestBPM)
    let snareCrackAtWinner = interpolateACF(snareCrackACF, at: 60.0 * onsetRate / winner.bpm)

    // Use all 4 bands for the full vote between the hi-hat candidate and the winner
    let voteResult = subBandVote(
      subBandACFs: subBandACFs,
      candidateFast: hiHatBestBPM,
      candidateSlow: winner.bpm,
      onsetRate: onsetRate)

    if voteResult == hiHatBestBPM {
      let normalizedBPM = rangeNormalize(hiHatBestBPM)
      return (bpm: normalizedBPM, score: winner.score)
    }

    // Treble override: In DnB/jungle, kick is half-time (80 BPM) while
    // hi-hats carry the true breakbeat tempo (160 BPM). If both treble
    // bands independently prefer the faster candidate, promote even when
    // the full weighted vote disagrees (kick+snare body outweigh treble).
    if snareCrackAtFast > snareCrackAtWinner {
      let normalizedBPM = rangeNormalize(hiHatBestBPM)
      return (bpm: normalizedBPM, score: winner.score)
    }

    return winner
  }

  // MARK: - Confidence Calculation (Story 33-5, Task 7)

  /// Computes confidence using PAR (Peak-to-Average Ratio) and periodicity clarity.
  private static func computeConfidence(
    fused: [Float],
    winnerBPM: Double,
    bpmMin: Int
  ) -> Double {
    guard !fused.isEmpty else { return 0 }

    let count = vDSP_Length(fused.count)

    // PAR: max / mean of fused periodicity
    var maxVal: Float = 0
    var meanVal: Float = 0
    vDSP_maxv(fused, 1, &maxVal, count)
    vDSP_meanv(fused, 1, &meanVal, count)
    guard maxVal > 0 && meanVal > 0 else { return 0 }

    let par = Double(maxVal / meanVal)

    // Periodicity clarity: ratio of peak1 to peak2 (excluding octave-related peaks)
    let winnerIdx = Int(winnerBPM.rounded()) - bpmMin
    var peak1: Float = 0
    var peak2: Float = 0

    if winnerIdx >= 0 && winnerIdx < fused.count {
      peak1 = fused[winnerIdx]
    }

    // Find second-strongest peak that's not octave-related to the winner
    for i in 0..<fused.count {
      guard i != winnerIdx else { continue }
      let candidateBPM = Double(bpmMin + i)
      let ratio = max(winnerBPM, candidateBPM) / min(winnerBPM, candidateBPM)
      // Skip if within 4% of 2:1 ratio (octave-related)
      let isOctave = ratio > 1.92 && ratio < 2.08
      if !isOctave && fused[i] > peak2 {
        peak2 = fused[i]
      }
    }

    let clarity: Double = peak2 > 0 ? Double(peak1 / peak2) : Double(par)

    // Normalize PAR: typical range 2-20, map to [0, 1]
    let parNorm = min(1.0, max(0.0, (par - 1.0) / 10.0))

    // Normalize clarity: typical range 1-10, map to [0, 1]
    let clarityNorm = min(1.0, max(0.0, (clarity - 1.0) / 5.0))

    // Combined confidence mapped through exponential saturation
    let combined = (parNorm + clarityNorm) / 2.0
    return min(1.0 - exp(-combined * 5.0), 1.0)
  }

  // MARK: - Edge Case Helpers (Task 7)

  private static func isSilent(_ samples: [Float]) -> Bool {
    guard !samples.isEmpty else { return true }
    var rms: Float = 0
    vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
    return rms < silenceThreshold
  }

  private static func nextPowerOf2(_ n: Int) -> Int {
    var v = n - 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v |= v >> 32
    v += 1
    return max(v, 1)
  }

  // MARK: - Adaptive Thresholding (Phase 1, #60)

  /// Removes the local energy floor from an onset envelope using running mean subtraction.
  ///
  /// Computes a 500ms running mean, subtracts it from the envelope, and half-wave rectifies.
  /// This keeps only peaks that exceed the local noise floor, addressing "wall of energy"
  /// artifacts from dense snare rolls in jungle/DnB.
  ///
  /// - Parameters:
  ///   - envelope: Full-band onset envelope.
  ///   - onsetRate: Onset envelope frame rate (sampleRate / hopSize).
  /// - Returns: Adaptively thresholded envelope.
  private static func adaptiveThreshold(envelope: [Float], onsetRate: Double) -> [Float] {
    let count = envelope.count
    guard count > 1 else { return envelope }

    // 500ms window (approximately 2 beats at 120 BPM)
    let windowSize = max(2, Int(0.5 * onsetRate))
    guard count > windowSize else { return envelope }

    // Compute global mean for edge padding
    var globalMean: Float = 0
    vDSP_meanv(envelope, 1, &globalMean, vDSP_Length(count))

    // Compute running sum via vDSP_vswsum
    let swsumLength = count - windowSize + 1
    var runningSum = [Float](repeating: 0, count: swsumLength)
    envelope.withUnsafeBufferPointer { envPtr in
      let ws = vDSP_Length(windowSize)
      vDSP_vswsum(envPtr.baseAddress!, 1, &runningSum, 1, vDSP_Length(swsumLength), ws)
    }

    // Divide by window size to get running mean
    var divisor = Float(windowSize)
    vDSP_vsdiv(runningSum, 1, &divisor, &runningSum, 1, vDSP_Length(swsumLength))

    // Build full-length running mean buffer, center-aligned with edge padding
    var runningMean = [Float](repeating: globalMean, count: count)
    let offset = windowSize / 2
    for i in 0..<swsumLength {
      runningMean[offset + i] = runningSum[i]
    }

    // Subtract running mean from envelope
    var subtracted = [Float](repeating: 0, count: count)
    vDSP_vsub(runningMean, 1, envelope, 1, &subtracted, 1, vDSP_Length(count))

    // Half-wave rectify (clamp negatives to 0)
    var zero: Float = 0
    vDSP_vthres(subtracted, 1, &zero, &subtracted, 1, vDSP_Length(count))

    return subtracted
  }

  // MARK: - Trace Helpers

  /// Extracts top N peaks from a 1D array by value.
  private static func extractTopPeaks(
    from array: [Float], count topN: Int
  ) -> [(index: Int, value: Float)] {
    guard !array.isEmpty else { return [] }
    var indexed = array.enumerated().map { (index: $0.offset, value: $0.element) }
    indexed.sort { $0.value > $1.value }
    return Array(indexed.prefix(topN))
  }
}
