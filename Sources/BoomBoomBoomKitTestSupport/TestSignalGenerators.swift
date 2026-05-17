import Foundation

/// Generate a synthetic click track with exponential-decay impulses at the given BPM.
public func generateClickTrack(
  bpm: Double, sampleRate: Double = 44100, durationSeconds: Double = 10
) -> [Float] {
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

/// Synthesize Hann-windowed narrowband bursts at two center frequencies for
/// boundary-bin discrimination tests. Used by `replicatePadPreservesBoundaryBins`
/// (Story 4-7 P5) to deliver energy at mel-bin 0 and mel-bin 127 of the project's
/// 128-band mel filterbank.
///
/// Design (per Codex review 2026-05-17): white-noise excitation through a Q≈30
/// narrow biquad bandpass at each `centerHz`, summed and Hann-windowed in 50 ms
/// bursts at `burstIntervalSeconds`. The windowing controls spectral leakage so
/// the bin-0 and bin-127 mel triangles see energy reliably even with mel-filter
/// rolloff at the boundaries. A precondition assertion via captured log-mel
/// frames verifies the synthesis worked.
public func synthesizeBoundaryBurstFixture(
  sampleRate: Double = 44100,
  durationSeconds: Double = 4,
  lowCenterHz: Double = 48,
  highCenterHz: Double = 15_600,
  burstIntervalSeconds: Double = 0.05,
  burstDurationSeconds: Double = 0.020,
  seed: UInt64 = 0xC0FF_EE_C0FF_EE
) -> [Float] {
  // Codex diff-review follow-up C1 (thread 019e3817-...): guard against
  // parameter combinations that would hang or poison the fixture instead of
  // failing loudly. precondition() is the project's idiom for "programmer
  // error in test infrastructure" (matches BPMAnalyzer.swift's sample-rate
  // and array-shape preconditions).
  precondition(
    sampleRate > 0,
    "synthesizeBoundaryBurstFixture: sampleRate must be > 0 (got \(sampleRate))")
  precondition(
    durationSeconds > 0,
    "synthesizeBoundaryBurstFixture: durationSeconds must be > 0 (got \(durationSeconds))"
  )
  precondition(
    burstIntervalSeconds > 0,
    "synthesizeBoundaryBurstFixture: burstIntervalSeconds must be > 0 (got \(burstIntervalSeconds))"
  )
  precondition(
    burstDurationSeconds > 0,
    "synthesizeBoundaryBurstFixture: burstDurationSeconds must be > 0 (got \(burstDurationSeconds))"
  )
  let nyquist = sampleRate / 2
  precondition(
    lowCenterHz > 0 && lowCenterHz < nyquist,
    "synthesizeBoundaryBurstFixture: lowCenterHz must be in (0, \(nyquist)) Hz (got \(lowCenterHz))"
  )
  precondition(
    highCenterHz > 0 && highCenterHz < nyquist,
    "synthesizeBoundaryBurstFixture: highCenterHz must be in (0, \(nyquist)) Hz (got \(highCenterHz))"
  )

  let totalSamples = Int(sampleRate * durationSeconds)
  let burstSamples = Int(sampleRate * burstDurationSeconds)
  let burstStride = Int(sampleRate * burstIntervalSeconds)

  // Derived-value preconditions: catch sub-fractional inputs that round to
  // zero/one and would otherwise produce non-terminating loops (stride=0),
  // div-by-zero in the Hann denominator (burstSamples=1), or trap-on-Array-init
  // (totalSamples<=0).
  precondition(
    totalSamples > 0,
    "synthesizeBoundaryBurstFixture: derived totalSamples must be > 0 (got \(totalSamples) — check sampleRate × durationSeconds)"
  )
  precondition(
    burstSamples >= 2,
    "synthesizeBoundaryBurstFixture: derived burstSamples must be ≥ 2 (got \(burstSamples) — Hann denominator is burstSamples-1; check sampleRate × burstDurationSeconds)"
  )
  precondition(
    burstStride > 0,
    "synthesizeBoundaryBurstFixture: derived burstStride must be > 0 (got \(burstStride) — would non-terminate; check sampleRate × burstIntervalSeconds)"
  )

  var output = [Float](repeating: 0, count: totalSamples)

  // Biquad bandpass coefficients (Robert Bristow-Johnson cookbook, BPF — constant
  // 0 dB peak gain) for the two target center frequencies. Q=30 narrowband.
  func biquadBPF(centerHz: Double, q: Double) -> (
    b0: Double, b1: Double, b2: Double, a1: Double, a2: Double
  ) {
    let omega = 2.0 * .pi * centerHz / sampleRate
    let alpha = sin(omega) / (2.0 * q)
    let a0 = 1.0 + alpha
    let b0 = alpha / a0
    let b1 = 0.0
    let b2 = -alpha / a0
    let a1 = (-2.0 * cos(omega)) / a0
    let a2 = (1.0 - alpha) / a0
    return (b0, b1, b2, a1, a2)
  }
  let bpfLow = biquadBPF(centerHz: lowCenterHz, q: 30)
  let bpfHigh = biquadBPF(centerHz: highCenterHz, q: 30)

  var rng = SplitMix64(seed: seed)
  func nextWhiteNoise() -> Double {
    // Convert UInt64 → uniform [-1, 1].
    let u = Double(rng.next() &>> 11) / Double(UInt64(1) << 53)
    return 2.0 * u - 1.0
  }

  var t = 0
  while t + burstSamples <= totalSamples {
    // Run a fresh biquad through `burstSamples` of white noise per burst, twice
    // (low + high band), Hann-window the result, write into output.
    var lowState: (x1: Double, x2: Double, y1: Double, y2: Double) = (0, 0, 0, 0)
    var highState: (x1: Double, x2: Double, y1: Double, y2: Double) = (0, 0, 0, 0)
    for k in 0..<burstSamples {
      let x = nextWhiteNoise()
      let yLow =
        bpfLow.b0 * x + bpfLow.b1 * lowState.x1 + bpfLow.b2 * lowState.x2
        - bpfLow.a1 * lowState.y1 - bpfLow.a2 * lowState.y2
      lowState = (x, lowState.x1, yLow, lowState.y1)
      let yHigh =
        bpfHigh.b0 * x + bpfHigh.b1 * highState.x1 + bpfHigh.b2 * highState.x2
        - bpfHigh.a1 * highState.y1 - bpfHigh.a2 * highState.y2
      highState = (x, highState.x1, yHigh, highState.y1)
      // Hann window over the burst duration.
      let phase = .pi * Double(k) / Double(burstSamples - 1)
      let hann = 0.5 * (1.0 - cos(2.0 * phase))
      // Sum low + high, scale into safe range (Q=30 BPF amplifies — clamp by 0.4).
      output[t + k] = Float((yLow + yHigh) * hann * 0.4)
    }
    t += burstStride
  }

  // Normalize peak amplitude to ~0.9 so the fixture is non-clipping but loud
  // enough to clear the energy-scan floor in BPMAnalyzer.
  var peak: Float = 0
  for v in output { peak = max(peak, abs(v)) }
  if peak > 0.001 {
    let scale = Float(0.9) / peak
    for i in 0..<output.count { output[i] *= scale }
  }

  return output
}

/// SplitMix64 — fast, deterministic PRNG for reproducible test data.
public struct SplitMix64 {
  private var state: UInt64

  public init(seed: UInt64) {
    state = seed
  }

  public mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z &>> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z &>> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z &>> 31)
  }
}
