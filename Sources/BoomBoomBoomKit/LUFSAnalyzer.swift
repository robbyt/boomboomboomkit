//
//  LUFSAnalyzer.swift
//  BoomBoomBoomKit
//
//  LUFS Loudness Analyzer (ITU-R BS.1770-5)
//

import Accelerate
import Foundation

/// Result of LUFS integrated loudness measurement.
struct LUFSResult: Sendable {
  /// Integrated loudness — the headline number (e.g., -14.2 LUFS)
  let integratedLoudness: Double

  /// Per-block momentary loudness values (400ms blocks, 100ms step).
  /// These are the L_j values BEFORE gating — retained as a zero-cost byproduct
  /// of the gating computation. Enables LUFS-over-time visualization without re-analysis.
  /// X-axis: index * blockStepSeconds gives time position.
  /// Y-axis: LUFS value for that block.
  let blockLoudnessValues: [Double]

  /// Time step between consecutive blocks in seconds (always 0.1).
  let blockStepSeconds: Double

  /// Short-term loudness series (EBU Tech 3341 §2.2): exact 3.0s rectangular
  /// window on the same 100ms grid, computed from 30 consecutive 100ms
  /// mean-square cells (energy domain; log applied last). Empty for input
  /// shorter than 3s. Values floored at -100 for display, matching
  /// `blockLoudnessValues`.
  let shortTermLoudnessValues: [Double]

  /// Loudness range in LU (EBU Tech 3342 §3.1): P95 − P10 of the gated
  /// short-term distribution (absolute gate −70 LUFS, relative gate −20 LU
  /// below the absolute-gated mean). `nil` when the gated program is shorter
  /// than 60s (EBU R 128 reliability floor) or the gated set is empty.
  let loudnessRange: Double?

  /// P10 of the gated short-term distribution (lower LRA band edge), in LUFS.
  /// Sentinel −100 when `loudnessRange` is nil.
  let lraLow: Double

  /// P95 of the gated short-term distribution (upper LRA band edge), in LUFS.
  /// Sentinel −100 when `loudnessRange` is nil.
  let lraHigh: Double

  /// Maximum true-peak level in dBTP (ITU-R BS.1770-5 Annex 2): polyphase
  /// 4× oversampling at 44.1/48 kHz (176.4 kHz at 44.1k — under the literal
  /// "≥192 kHz" wording; standard practice, named deviation), 2× at 96 kHz.
  /// Computed post-mono-mixdown — may understate per-channel inter-sample
  /// peaks (see `LUFSReport.maxTruePeakDBTP` documentation).
  let maxTruePeakDBTP: Double
}

/// Measures integrated loudness per ITU-R BS.1770-5.
///
/// Pure computation: `[Float] → LUFSResult?`. No shared state, no actors.
/// Only imports `Foundation` and `Accelerate` — no external dependencies.
struct LUFSAnalyzer {

  // MARK: - Constants

  /// Floor value for block loudness display (matches klangfreund histogram
  /// lower bound). Single source of truth: `LUFSReport.sentinelFloor` — this
  /// is an alias, not an independent literal, so the analyzer's silent/
  /// non-measurable floor can never drift from the report's non-finite clamp.
  /// `internal` (not `private`) so `LUFSReportTests` can lock the coupling
  /// directly. Stays `-100.0` (byte-identity invariant).
  static let blockLoudnessFloor: Double = LUFSReport.sentinelFloor

  /// Sample rates with pre-computed K-weighting coefficients. The service
  /// layer consults this list to throw `LUFSAnalysisError.unsupportedSampleRate`
  /// for anything else; the analyzer itself keeps its never-throws nil contract.
  static let supportedSampleRates: [Double] = [44100, 48000, 96000]

  // MARK: - K-Weighting Coefficients

  /// K-weighting filter coefficients for supported sample rates.
  /// Format per section: [b0, b1, b2, a1, a2] (a0 = 1 normalized).
  /// Two sections: high-shelf (head acoustic) → high-pass (RLB weighting).
  private static let coefficients: [Int: [Double]] = [
    // 48000 Hz — from ITU-R BS.1770-5 specification directly
    48000: [
      // Stage 1: High-Shelf Filter
      1.53512485958697, -2.69169618940638, 1.19839281085285,
      -1.69065929318241, 0.73248077421585,
      // Stage 2: High-Pass Filter
      1.0, -2.0, 1.0,
      -1.99004745483398, 0.99007225036621,
    ],
    // 44100 Hz — bilinear transform from 48kHz prototype
    44100: [
      // Stage 1: High-Shelf Filter
      1.530841230050348, -2.650979995154729, 1.169079079921587,
      -1.663655113256020, 0.712595428073225,
      // Stage 2: High-Pass Filter
      0.999560064542514, -1.999120129085029, 0.999560064542514,
      -1.989169673629796, 0.989199035787039,
    ],
    // 96000 Hz — bilinear transform from 48kHz prototype
    96000: [
      // Stage 1: High-Shelf Filter
      1.537185173610400, -2.718780265928710, 1.218990510102450,
      -1.710656503758280, 0.747317008498040,
      // Stage 2: High-Pass Filter
      0.999780299723625, -1.999560599447250, 0.999780299723625,
      -1.994582958828822, 0.994588012554209,
    ],
  ]

  // MARK: - Public API

  /// Measures integrated loudness per ITU-R BS.1770-5.
  ///
  /// Returns both the headline integrated loudness and per-block momentary
  /// loudness values (100ms step) for future time-series visualization.
  ///
  /// The single entry point since Story 8-2 (DD #5 — the
  /// `samples:sampleRate:` form is removed, no shim). `decoded` is a pure
  /// carrier: only `samples` and `sampleRate` are read; provenance fields
  /// never influence output. Analyzer contract unchanged: returns nil for
  /// no-result, never throws — unsupported-rate THROWING stays at the
  /// service layer (`LUFSAnalysisError.unsupportedSampleRate`).
  ///
  /// Layering note: this analyzer returns nil for an unsupported rate, but the
  /// public service path (`AudioAnalysisService.analyzeLUFS` →
  /// `lufsReport`) guards the rate and THROWS *before* reaching this method, so
  /// the unsupported-rate nil branch below is unreachable from the public API —
  /// it is defensive only. Do NOT "align" the two layers by making this method
  /// throw: the analyzer's never-throws nil contract is intentional and
  /// test-locked (`LUFSAnalyzerTests.unsupportedSampleRateReturnsNil`), while
  /// the service's throw contract is locked separately
  /// (`LUFSErrorContractTests`).
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier. Supported rates: 44100, 48000,
  ///     96000 — anything else returns nil (no K-weighting coefficients).
  /// - Returns: Integrated loudness + block time-series in LUFS,
  ///   or nil for silence/too-short audio/unsupported sample rate.
  static func measureLoudness(
    decoded: FeatureSubstrate.DecodedAudio
  ) -> LUFSResult? {
    let samples = decoded.samples
    let sampleRate = decoded.sampleRate
    // Task 6.1: Guard against empty samples
    guard !samples.isEmpty else { return nil }

    // Task 1.5: Guard against unsupported sample rates
    guard let filterCoeffs = coefficients[Int(sampleRate)] else {
      // TODO: bilinear transform derivation for arbitrary rates
      return nil
    }

    // Task 6.2: Guard against duration < 400ms (can't form a single block)
    let blockSize = Int(0.4 * sampleRate)
    guard samples.count >= blockSize else { return nil }

    // Task 1.6: Apply K-weighting filter using vDSP.Biquad (Double precision)
    let filtered = applyKWeighting(samples: samples, coefficients: filterCoeffs)

    // Task 2: Compute per-block mean-square values
    let stepSize = Int(0.1 * sampleRate)
    let blockResults = meanSquares(
      filtered: filtered, windowSize: blockSize, stepSize: stepSize)

    guard !blockResults.isEmpty else { return nil }

    // Task 3: Compute per-block loudness and apply absolute gating
    let blockLoudness = blockResults.map { meanSquare -> Double in
      guard meanSquare > 0 else { return -.infinity }
      return -0.691 + 10.0 * log10(meanSquare)
    }

    // Task 3.2: Absolute gate — discard blocks below -70 LUFS
    let absoluteThreshold: Double = -70.0
    let absoluteGatedIndices = blockLoudness.indices.filter { i in
      blockLoudness[i] > absoluteThreshold
    }

    // Task 6.3: All blocks gated → return nil
    guard !absoluteGatedIndices.isEmpty else { return nil }

    // Task 4: Relative gating
    let ungatedMeanSquare =
      absoluteGatedIndices.map { blockResults[$0] }.reduce(0, +)
      / Double(absoluteGatedIndices.count)

    // Task 6.4: Guard against log10(0)
    guard ungatedMeanSquare > 0 else { return nil }

    let ungatedLoudness = -0.691 + 10.0 * log10(ungatedMeanSquare)
    let relativeThreshold = ungatedLoudness - 10.0

    let relativeGatedIndices = absoluteGatedIndices.filter { i in
      blockLoudness[i] > relativeThreshold
    }

    // Task 6.3: All blocks gated after relative pass → return nil
    guard !relativeGatedIndices.isEmpty else { return nil }

    // Task 5: Compute final integrated loudness
    let finalMeanSquare =
      relativeGatedIndices.map { blockResults[$0] }.reduce(0, +)
      / Double(relativeGatedIndices.count)

    guard finalMeanSquare > 0 else { return nil }

    let integratedLoudness = -0.691 + 10.0 * log10(finalMeanSquare)

    // Task 5.4: Retain ALL per-block L_j values (pre-gating) for time-series
    // Replace -infinity with a floor value for display purposes
    let displayBlockLoudness = blockLoudness.map { value in
      value.isFinite ? value : blockLoudnessFloor
    }

    // Story 8.1 — additive passes. Everything below reads `filtered`/`samples`
    // without touching the 400ms block path above: integrated loudness and
    // `blockLoudnessValues` stay bit-identical (locked by LUFSByteIdentityTests).
    // NEVER derive the 400ms blocks from the 100ms cells — the floating-point
    // reduction order differs even though the math is equal.

    // Short-term series via the 100ms mean-square cell primitive (DD #4):
    // an exact 3.0s rectangle = mean of 30 consecutive cells, energy domain,
    // 10·log10 applied last (EBU Tech 3341 §2.2).
    let cellSize = Int(0.1 * sampleRate)
    let cellMeanSquares = meanSquares(
      filtered: filtered, windowSize: cellSize, stepSize: cellSize)
    let shortTermMeanSquares = computeShortTermMeanSquares(cells: cellMeanSquares)
    let shortTermLoudness = shortTermMeanSquares.map { ms -> Double in
      guard ms > 0 else { return -.infinity }
      return -0.691 + 10.0 * log10(ms)
    }
    let displayShortTermLoudness = shortTermLoudness.map { value in
      value.isFinite ? value : blockLoudnessFloor
    }

    // Loudness range per EBU Tech 3342 §3.1 over the short-term distribution.
    let lra = computeLoudnessRange(
      shortTermLoudness: shortTermLoudness,
      shortTermMeanSquares: shortTermMeanSquares)

    // True peak per ITU-R BS.1770-5 Annex 2 over the RAW (pre-K-weighting)
    // samples at the original rate.
    let truePeak = measureTruePeak(samples: samples, sampleRate: sampleRate)

    return LUFSResult(
      integratedLoudness: integratedLoudness,
      blockLoudnessValues: displayBlockLoudness,
      blockStepSeconds: 0.1,
      shortTermLoudnessValues: displayShortTermLoudness,
      loudnessRange: lra.range,
      lraLow: lra.low,
      lraHigh: lra.high,
      maxTruePeakDBTP: truePeak
    )
  }

  // MARK: - K-Weighting Filter (Task 1)

  /// Applies K-weighting pre-filter (high-shelf + high-pass cascade) using vDSP.Biquad.
  /// Uses Double precision throughout — Float causes measurable errors due to poles near unit circle.
  private static func applyKWeighting(
    samples: [Float], coefficients: [Double]
  ) -> [Double] {
    // Convert Float → Double using vDSP (vectorized)
    var doubleSamples = [Double](repeating: 0, count: samples.count)
    vDSP_vspdp(samples, 1, &doubleSamples, 1, vDSP_Length(samples.count))

    // Create 2-section cascade: high-shelf → high-pass
    guard
      var filter = vDSP.Biquad(
        coefficients: coefficients,
        channelCount: 1,
        sectionCount: 2,
        ofType: Double.self
      )
    else {
      return []
    }

    // Apply filter in single pass (offline analysis, not real-time)
    return filter.apply(input: doubleSamples)
  }

  // MARK: - Mean-Square Primitive (Task 2 + Story 8.1, DD #4)

  /// Mean-square over a sliding `windowSize`-sample window advanced by
  /// `stepSize`. One `vDSP_measqvD` sweep per window; energy domain (no log).
  /// Returns empty when fewer than one full window fits. Callers own the
  /// window/step contract — the 400ms blocks (overlapping) pass
  /// `stepSize < windowSize`; the non-overlapping 100ms cells pass
  /// `stepSize == windowSize`. Both call sites keep their distinct
  /// `windowSize`/`stepSize`, so the per-window `vDSP_measqvD` calls — and
  /// thus the floating-point reduction order — are identical to the prior two
  /// specialized loops (locked by LUFSByteIdentityTests). The 100ms cells are
  /// ADDITIVE: they feed the short-term series and LRA only; the 400ms block
  /// path never reads them.
  static func meanSquares(
    filtered: [Double], windowSize: Int, stepSize: Int
  ) -> [Double] {
    guard windowSize > 0, stepSize > 0 else { return [] }
    let totalSamples = filtered.count
    guard totalSamples >= windowSize else { return [] }

    let windowCount = (totalSamples - windowSize) / stepSize + 1
    var result = [Double](repeating: 0, count: windowCount)
    filtered.withUnsafeBufferPointer { bp in
      for i in 0..<windowCount {
        var ms: Double = 0
        vDSP_measqvD(bp.baseAddress! + i * stepSize, 1, &ms, vDSP_Length(windowSize))
        result[i] = ms
      }
    }
    return result
  }

  /// Short-term mean-squares: exact mean of 30 consecutive 100ms cells
  /// (= exact 3.0s rectangular window, EBU Tech 3341 §2.2), stepped on the
  /// shared 100ms grid. Plain loop is fine at this altitude — it operates on
  /// block summaries, not sample buffers. Returns empty for input < 3s.
  private static func computeShortTermMeanSquares(cells: [Double]) -> [Double] {
    let windowCells = 30
    guard cells.count >= windowCells else { return [] }

    let windowCount = cells.count - windowCells + 1
    var result = [Double](repeating: 0, count: windowCount)
    for i in 0..<windowCount {
      var sum: Double = 0
      for j in 0..<windowCells {
        sum += cells[i + j]
      }
      result[i] = sum / Double(windowCells)
    }
    return result
  }

  // MARK: - Loudness Range (Story 8.1, EBU Tech 3342 §3.1)

  /// Computes LRA over the short-term loudness distribution.
  ///
  /// Gating per EBU Tech 3342 §3.1: absolute gate −70 LUFS, then relative gate
  /// −20 LU below the mean loudness of the absolute-gated set (note: −20,
  /// not integrated gating's −10). The mean is computed in the mean-square
  /// (energy) domain — never average dB values. LRA = P95 − P10 of the gated
  /// loudness distribution; percentiles use linear interpolation over the
  /// sorted values (rank = q·(n−1)).
  ///
  /// Fails CLOSED: returns `(nil, −100, −100)` when the gated set is empty or
  /// the gated program is shorter than 60s (EBU R 128 notes LRA is unreliable
  /// below ~1 min) — never a wrong number.
  private static func computeLoudnessRange(
    shortTermLoudness: [Double],
    shortTermMeanSquares: [Double]
  ) -> (range: Double?, low: Double, high: Double) {
    let sentinel = blockLoudnessFloor

    // Absolute gate: −70 LUFS.
    let absoluteGatedIndices = shortTermLoudness.indices.filter {
      shortTermLoudness[$0] > -70.0
    }
    guard !absoluteGatedIndices.isEmpty else { return (nil, sentinel, sentinel) }

    // Relative gate: −20 LU below the absolute-gated mean (energy domain).
    let meanMS =
      absoluteGatedIndices.map { shortTermMeanSquares[$0] }.reduce(0, +)
      / Double(absoluteGatedIndices.count)
    guard meanMS > 0 else { return (nil, sentinel, sentinel) }
    let relativeThreshold = (-0.691 + 10.0 * log10(meanMS)) - 20.0

    let gated = absoluteGatedIndices.map { shortTermLoudness[$0] }
      .filter { $0 > relativeThreshold }

    // EBU R 128 reliability floor: the gated programme must cover ≥ 60s.
    // N gated 3.0s windows stepped on the 100ms grid span (N−1)·0.1 + 3.0
    // seconds of programme when contiguous — counting windows as 0.1s each
    // would make the documented 60s boundary unreachable (a fully-gated
    // 60.0–62.9s programme would wrongly return nil).
    guard !gated.isEmpty,
      (Double(gated.count) - 1.0) * 0.1 + 3.0 >= 60.0
    else {
      return (nil, sentinel, sentinel)
    }

    let sorted = gated.sorted()
    let p10 = percentile(sorted: sorted, fraction: 0.10)
    let p95 = percentile(sorted: sorted, fraction: 0.95)
    return (p95 - p10, p10, p95)
  }

  /// Linear-interpolation percentile over a pre-sorted array (rank = q·(n−1)).
  private static func percentile(sorted: [Double], fraction: Double) -> Double {
    guard sorted.count > 1 else { return sorted[0] }
    let rank = fraction * Double(sorted.count - 1)
    let lower = Int(rank)
    let upper = min(lower + 1, sorted.count - 1)
    let frac = rank - Double(lower)
    return sorted[lower] + frac * (sorted[upper] - sorted[lower])
  }

  // MARK: - True Peak (Story 8.1, ITU-R BS.1770-5 Annex 2)

  /// ITU-R BS.1770-5 Annex 2 Attachment 1 interpolation FIR: 48-tap prototype
  /// as 4 phases × 12 taps, gain pre-compensated (per-phase DC gain ≈ 1.0 —
  /// the ×L scaling is baked in). Values verbatim from the Recommendation
  /// (all are dyadic multiples of 2⁻¹³). Float is fine here — the Double
  /// mandate is K-weighting-IIR-only.
  private static let truePeakPhases4x: [[Float]] = [
    [
      0.0017089843750, 0.0109863281250, -0.0196533203125, 0.0332031250000,
      -0.0594482421875, 0.1373291015625, 0.9721679687500, -0.1022949218750,
      0.0476074218750, -0.0266113281250, 0.0148925781250, -0.0083007812500,
    ],
    [
      -0.0291748046875, 0.0292968750000, -0.0517578125000, 0.0891113281250,
      -0.1665039062500, 0.4650878906250, 0.7797851562500, -0.2003173828125,
      0.1015625000000, -0.0582275390625, 0.0330810546875, -0.0189208984375,
    ],
    [
      -0.0189208984375, 0.0330810546875, -0.0582275390625, 0.1015625000000,
      -0.2003173828125, 0.7797851562500, 0.4650878906250, -0.1665039062500,
      0.0891113281250, -0.0517578125000, 0.0292968750000, -0.0291748046875,
    ],
    [
      -0.0083007812500, 0.0148925781250, -0.0266113281250, 0.0476074218750,
      -0.1022949218750, 0.9721679687500, 0.1373291015625, -0.0594482421875,
      0.0332031250000, -0.0196533203125, 0.0109863281250, 0.0017089843750,
    ],
  ]

  /// Pre-reversed phase taps for `vDSP_conv`, which computes CORRELATION with
  /// a positive filter stride. Correlating with reversed taps == true
  /// convolution `y_p[n] = Σ_k h_p[k]·x[n−k]`. The subfilters are asymmetric,
  /// so skipping this reversal IS a wrong answer — locked by the
  /// asymmetric-transient test (AC8).
  private static let truePeakPhases4xReversed: [[Float]] = truePeakPhases4x.map {
    Array($0.reversed())
  }

  /// 2× midpoint interpolator for 96 kHz: 12-tap windowed sinc at half-sample
  /// offsets (−5.5…+5.5), Blackman-windowed, explicitly DC-normalized to
  /// gain 1.0 (the manual ×L scaling a self-designed prototype needs —
  /// BS.1770-5 Annex 2 calls for ≥192 kHz, so 96k needs only 2×). Phase 0 of
  /// a 2× interpolator is the identity (the raw-sample max covers it); only
  /// the midpoint phase is filtered. Symmetric taps — reversal-invariant,
  /// but reversed-form discipline is kept by construction.
  private static let truePeakMidpointTaps2x: [Float] = {
    var taps = [Double](repeating: 0, count: 12)
    for i in 0..<12 {
      let offset = Double(i) - 5.5  // half-sample offsets −5.5…+5.5
      let sinc = sin(.pi * offset) / (.pi * offset)  // never 0 at half offsets
      // Blackman window over the 12-tap span.
      let w =
        0.42 + 0.5 * cos(.pi * offset / 6.0) + 0.08 * cos(.pi * offset / 3.0)
      taps[i] = sinc * w
    }
    let sum = taps.reduce(0, +)
    return taps.map { Float($0 / sum) }
  }()

  /// Pre-reversed form of ``truePeakMidpointTaps2x`` for `vDSP_conv`, hoisted
  /// to match the `truePeakPhases4xReversed` sibling (no per-call reversal
  /// allocation). Value-inert for these symmetric taps; kept for the
  /// reversed-form discipline.
  private static let truePeakMidpointTaps2xReversed: [Float] = Array(
    truePeakMidpointTaps2x.reversed())

  /// Measures max true-peak in dBTP over the original-rate signal.
  ///
  /// Chunked: per chunk, each polyphase subfilter runs `vDSP_conv` over the
  /// chunk plus 11 samples of left context (`tapCount − 1`), and the running
  /// max folds via `vDSP_maxmgv` — the 4N oversampled buffer is never
  /// materialized. The signal is virtually extended with 11 trailing zeros so
  /// peaks adjacent to the final samples are not missed. The raw sample max
  /// is folded in unconditionally.
  static func measureTruePeak(samples: [Float], sampleRate: Double) -> Double {
    guard !samples.isEmpty else { return blockLoudnessFloor }

    // Raw sample max (covers the 2× identity phase at 96k as well).
    var maxAbs: Float = 0
    vDSP_maxmgv(samples, 1, &maxAbs, vDSP_Length(samples.count))

    // 4× at 44.1/48 kHz (176.4 kHz at 44.1k — named deviation from the
    // literal "≥192 kHz" wording, standard practice); 2× at 96 kHz.
    let phases: [[Float]] =
      sampleRate >= 96000
      ? [truePeakMidpointTaps2xReversed]
      : truePeakPhases4xReversed

    let tapCount = 12
    let context = tapCount - 1
    let chunkSize = 65536
    // Virtual length includes `context` trailing zeros.
    let extendedCount = samples.count + context
    var chunk = [Float](repeating: 0, count: chunkSize + context)
    var phaseOut = [Float](repeating: 0, count: chunkSize)

    var start = 0
    while start < extendedCount {
      let n = min(chunkSize, extendedCount - start)
      // Build buffer = x[start − context ..< start + n], zero-padded outside
      // the real signal. Buffer length n + context = N + P − 1 as vDSP_conv
      // requires. Zero-fill then memcpy the in-range slice (no per-element loop).
      chunk.withUnsafeMutableBufferPointer { cp in
        vDSP_vclr(cp.baseAddress!, 1, vDSP_Length(n + context))
      }
      let srcLo = max(0, start - context)
      let srcHi = min(samples.count, start + n)
      if srcLo < srcHi {
        let dstLo = srcLo - (start - context)
        chunk.replaceSubrange(dstLo..<(dstLo + srcHi - srcLo), with: samples[srcLo..<srcHi])
      }
      for taps in phases {
        chunk.withUnsafeBufferPointer { cp in
          taps.withUnsafeBufferPointer { tp in
            phaseOut.withUnsafeMutableBufferPointer { op in
              vDSP_conv(
                cp.baseAddress!, 1, tp.baseAddress!, 1,
                op.baseAddress!, 1, vDSP_Length(n), vDSP_Length(tapCount))
            }
          }
        }
        var phaseMax: Float = 0
        vDSP_maxmgv(phaseOut, 1, &phaseMax, vDSP_Length(n))
        maxAbs = max(maxAbs, phaseMax)
      }
      start += n
    }

    guard maxAbs > 0 else { return blockLoudnessFloor }
    return 20.0 * log10(Double(maxAbs))
  }
}
