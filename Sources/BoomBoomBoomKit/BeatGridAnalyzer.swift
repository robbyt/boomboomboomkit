//
//  BeatGridAnalyzer.swift
//  BoomBoomBoomKit
//
//  Internal beat-grid analyzer: causal dynamic-programming beat tracking from a
//  pre-computed onset envelope and a known tempo (Story 8.4, pipeline step 11).
//

import Accelerate
import Foundation

/// Internal beat-grid analyzer (Story 8.4). Recovers the beat phase grid from a
/// 1-D onset detection function and a tempo supplied by the BPM stage, using a
/// causal dynamic-programming beat tracker.
///
/// ## Algorithm — Davies & Plumbley dynamic programming
/// The tracker is the dynamic-programming beat-alignment of the Davies & Plumbley
/// family (Davies & Plumbley, "Causal Tempo Tracking of Audio", ISMIR 2004; and
/// "Context-Dependent Beat Tracking of Musical Audio", AES 118th Convention, 2005),
/// in the fixed-period form popularised by D.P.W. Ellis, "Beat Tracking by Dynamic
/// Programming" (J. New Music Research, 2007).
///
/// Because the tempo (hence the beat period) is already resolved by the upstream
/// BPM pipeline, the *Rayleigh tempo-induction prior* central to the original
/// Davies & Plumbley tempo estimator is not needed here — its role is subsumed by
/// the supplied `tempoBPM`. What remains, and what this type implements, is the
/// period-transition–weighted DP that fixes the beat *phase*: a log-Gaussian
/// "tightness" penalty around the known period selects, for every onset frame, the
/// best predecessor beat, then a backtrace recovers the beat sequence.
///
/// ## Implementation provenance
/// A clean-room implementation from the academic papers cited above — no
/// third-party beat-tracking source is transcribed or linked. The package adds
/// no dependency: only `Foundation` and `Accelerate` are imported.
///
/// ## Scope (Story 8.4)
/// Beats only. Downbeat (bar-start) detection is not attempted, so the returned
/// grid carries ``DownbeatResult/notAttempted``. The grid runs standalone (no BPM
/// stage in the same call when reached via ``AudioAnalysisService/analyzeBeatGrid(url:options:)``),
/// so ``BeatGrid/tempoAgreedWithBPMStage`` is `nil`. Both are Story 8.5 concerns.
///
/// ## Tempo assumption — constant tempo only
/// This is a **fixed-period** tracker: it fixes beat phase against the single
/// tempo the BPM stage resolved, with a strong period-transition penalty. It
/// does **not** detect or adapt to tempo changes — accelerando, ritardando,
/// rubato, or distinct tempo-change sections. On material whose tempo genuinely
/// varies, the recovered beats hold a near-constant spacing and progressively
/// drift out of phase with the music. Variable-tempo tracking is out of scope
/// (not planned); supply constant-tempo material for meaningful grids.
enum BeatGridAnalyzer {

  // MARK: - Tuning constants

  /// Weight on the inherited (predecessor) score versus the local onset score in
  /// the cumulative-score recurrence. Ellis 2007 uses ~0.8; the period-transition
  /// penalty then dominates phase selection while the local onset term breaks ties.
  private static let alpha: Float = 0.8

  /// Strength of the log-Gaussian period-transition penalty (Ellis "tightness").
  /// Larger values penalise deviation from the supplied period more sharply, so
  /// recovered inter-beat intervals cluster tightly around the known period.
  private static let tightness: Double = 100.0

  // MARK: - Beat-grid estimation

  /// Recovers a ``BeatGrid`` from a 1-D onset envelope and a known tempo.
  ///
  /// Runs inside ``BPMAnalyzer/estimateBPM(decoded:options:)``'s scope (pipeline
  /// step 11) so it reuses the already-computed `onsetEnvelope` and `acf`; no new
  /// onset/ACF buffer is allocated in the hot path (DD #5).
  ///
  /// - Parameters:
  ///   - onsetEnvelope: The 1-D onset detection function over the analysis window,
  ///     sampled at `onsetRate` Hz (this is `BPMAnalyzer`'s full-band envelope —
  ///     non-negative after half-wave rectification). Window-relative.
  ///   - onsetRate: Onset-envelope sample rate in Hz (`sampleRate / hopSize`).
  ///   - hopSize: Onset hop in samples — maps an envelope frame to a sample offset.
  ///   - sampleRate: Audio sample rate in Hz.
  ///   - acf: The autocorrelation of the onset envelope (lag in frames), reused
  ///     from the BPM pipeline. Used to gauge how periodic the signal is at the
  ///     tracked period, feeding the overall grid confidence.
  ///   - tempoBPM: The resolved tempo from the BPM stage. Defines the beat period
  ///     `period = onsetRate * 60 / tempoBPM` (in frames).
  ///   - windowStartSample: Sample offset of the analysis window within the track
  ///     (the step-1 energy-scan drop offset). Beats are made track-relative by
  ///     adding this offset (DD #6); full codec-priming trim is Story 8.5.
  /// - Returns: A populated ``BeatGrid``, or `nil` for degenerate input (empty
  ///   envelope, non-positive/non-finite tempo, all-zero envelope, or a window
  ///   shorter than one beat period).
  static func estimateBeatGrid(  // swiftlint:disable:this function_parameter_count
    onsetEnvelope: [Float],
    onsetRate: Double,
    hopSize: Int,
    sampleRate: Double,
    acf: [Float],
    tempoBPM: Double,
    windowStartSample: Int
  ) -> BeatGrid? {
    let n = onsetEnvelope.count
    guard n > 0, hopSize > 0, sampleRate > 0, onsetRate > 0 else { return nil }
    guard tempoBPM.isFinite, tempoBPM > 0 else { return nil }

    // Beat period in onset frames. The upper bound (`period <= n`) rejects a
    // window shorter than one beat period as degenerate AND keeps the
    // `Int(...)` conversions below in range: an enormous-but-finite period
    // (from a tiny-but-finite `tempoBPM`) would otherwise trap on
    // `Int((period * 2).rounded())` or drive a multi-gigabyte `txCost` span.
    let period = onsetRate * 60.0 / tempoBPM
    guard period >= 1, period.isFinite, period <= Double(n) else { return nil }

    // Predecessor search window: an inter-beat interval lies in [period/2, 2*period]
    // frames.
    let dMin = max(1, Int((period * 0.5).rounded()))
    let dMax = max(dMin + 1, Int((period * 2.0).rounded()))
    guard n > dMin else { return nil }

    // Onset-envelope peak (single vDSP pass) → KDD-C2 strength denominator and
    // local-score normaliser. A non-positive max means no onset energy: degenerate.
    var envMax: Float = 0
    vDSP_maxv(onsetEnvelope, 1, &envMax, vDSP_Length(n))
    guard envMax > 0 else { return nil }

    // Local score: onset envelope normalised to [0, 1] (vDSP scalar divide).
    var localScore = [Float](repeating: 0, count: n)
    var divisor = envMax
    vDSP_vsdiv(onsetEnvelope, 1, &divisor, &localScore, 1, vDSP_Length(n))

    // Pre-compute the log-Gaussian period-transition penalty per interval `d` in
    // [dMin, dMax] once (it depends only on the interval, not the frame): the
    // central piece of the Davies & Plumbley DP transition weighting.
    let span = dMax - dMin + 1
    var txCost = [Float](repeating: 0, count: span)
    for k in 0..<span {
      let d = Double(dMin + k)
      let r = log(d / period)
      txCost[k] = Float(-tightness * r * r)
    }

    // Causal DP: cumulative score + backlink. The recurrence is inherently
    // sequential (cumScore[i] depends on earlier cumScore), so it is an explicit
    // loop — there is no vDSP primitive for an argmax-with-backtrace recurrence.
    var cumScore = [Float](repeating: 0, count: n)
    var backlink = [Int](repeating: -1, count: n)

    for i in 0..<n {
      // Candidate predecessors: i - dMax ... i - dMin (clamped to valid frames).
      let lo = i - dMax
      let hi = i - dMin
      if hi < 0 {
        // No valid predecessor yet — score is the (un-inherited) local onset.
        cumScore[i] = (1 - alpha) * localScore[i]
        backlink[i] = -1
        continue
      }
      let clampedLo = max(0, lo)
      var bestScore = -Float.greatestFiniteMagnitude
      var bestIdx = -1
      var j = clampedLo
      while j <= hi {
        let d = i - j
        let cost = txCost[d - dMin] + cumScore[j]
        if cost > bestScore {
          bestScore = cost
          bestIdx = j
        }
        j += 1
      }
      cumScore[i] = alpha * bestScore + (1 - alpha) * localScore[i]
      backlink[i] = bestIdx
    }

    // Backtrace from the highest cumulative score (the best beat endpoint), then
    // follow backlinks to recover the full beat sequence in playback order.
    var endIdx = 0
    var endScore = -Float.greatestFiniteMagnitude
    for i in 0..<n where cumScore[i] > endScore {
      endScore = cumScore[i]
      endIdx = i
    }

    var frames: [Int] = []
    var p = endIdx
    while p >= 0 {
      frames.append(p)
      p = backlink[p]
    }
    frames.reverse()
    guard !frames.isEmpty else { return nil }

    // Map beat frames → BeatTimestamps. strength is the KDD-C2 normalised onset
    // salience at the (window-relative) beat frame; presentationTime is offset by
    // windowStartSample to be track-relative (DD #6). Per-beat confidence measures
    // how close the interval to the previous beat is to the known period.
    var beats: [BeatTimestamp] = []
    beats.reserveCapacity(frames.count)
    var strengthSum: Float = 0
    for (k, f) in frames.enumerated() {
      // f is a DP index, always in 0..<n; guard defensively per AC5.
      guard f >= 0, f < n else { continue }
      let strength = onsetEnvelope[f] / envMax
      strengthSum += strength
      let presentationTime =
        (Double(windowStartSample) + Double(f) * Double(hopSize)) / sampleRate
      let beatConfidence: Float
      if k == 0 {
        beatConfidence = strength
      } else {
        let interval = Double(f - frames[k - 1])
        let r = interval > 0 ? log(interval / period) : 0
        beatConfidence = Float(exp(-r * r))
      }
      beats.append(
        BeatTimestamp(
          presentationTime: presentationTime,
          confidence: beatConfidence,
          strength: strength))
    }
    guard !beats.isEmpty else { return nil }

    // The grid's OWN tempo estimate: from the median inter-beat interval (not a
    // copy of tempoBPM), so it reports what was actually tracked. Falls back to
    // the supplied tempo when there is only one beat.
    let estimatedTempo: Double
    if frames.count >= 2 {
      var intervals: [Double] = []
      intervals.reserveCapacity(frames.count - 1)
      for k in 1..<frames.count {
        intervals.append(Double(frames[k] - frames[k - 1]))
      }
      intervals.sort()
      let mid = intervals.count / 2
      let medianInterval =
        intervals.count.isMultiple(of: 2)
        ? (intervals[mid - 1] + intervals[mid]) / 2
        : intervals[mid]
      // The DP search window admits intervals in [period/2, 2*period], so the
      // median-derived tempo can land at the half/double octave of the supplied
      // tempo. Octave disambiguation is the BPM stage's job — the beat grid owns
      // phase — so snap the reported tempo to the BPM-stage octave while keeping
      // the detected beats exactly as tracked.
      let medianTempo = medianInterval > 0 ? onsetRate * 60.0 / medianInterval : tempoBPM
      estimatedTempo = nearestOctaveEquivalent(of: medianTempo, to: tempoBPM)
    } else {
      estimatedTempo = tempoBPM
    }

    // Overall confidence: half from mean beat onset salience, half from how strong
    // the autocorrelation is at the tracked period (signal periodicity at tempo).
    let meanStrength = strengthSum / Float(beats.count)
    let periodConfidence = acfStrengthAtPeriod(acf: acf, period: period)
    let confidence = 0.5 * meanStrength + 0.5 * periodConfidence

    return BeatGrid(
      beats: beats,
      downbeats: .notAttempted,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreedWithBPMStage: nil)
  }

  /// Normalised autocorrelation magnitude at the beat-period lag, in `[0, 1]`:
  /// `acf[round(period)] / max(acf)`. Returns `0` when the lag is out of range or
  /// the ACF has no positive peak. A measure of how periodic the onset signal is
  /// at the tracked tempo, used as one half of the overall grid confidence.
  private static func acfStrengthAtPeriod(acf: [Float], period: Double) -> Float {
    let lag = Int(period.rounded())
    guard lag > 0, lag < acf.count else { return 0 }
    var acfMax: Float = 0
    vDSP_maxv(acf, 1, &acfMax, vDSP_Length(acf.count))
    guard acfMax > 0 else { return 0 }
    let v = acf[lag] / acfMax
    // ACF can be negative at a lag; clamp to [0, 1] for a confidence term.
    return min(max(v, 0), 1)
  }

  // MARK: - Octave snapping

  /// Returns `measured` scaled by the power of two that lands it closest to
  /// `reference`. Used to octave-lock the grid's reported tempo to the BPM
  /// stage's resolved octave (the BPM stage owns octave disambiguation; the beat
  /// grid owns phase). Checks `{0.5x, 1x, 2x}` — the DP median interval is
  /// constrained to `[0.5*period, 2*period]`, so these factors span the range.
  /// A non-octave `measured` (e.g. a 3:4 ratio) passes through unchanged: the
  /// helper only resolves octaves, it does not force agreement. `internal`
  /// (not `private`) so the snap semantics are unit-testable directly.
  static func nearestOctaveEquivalent(of measured: Double, to reference: Double) -> Double {
    guard measured.isFinite, measured > 0, reference.isFinite, reference > 0 else {
      return reference
    }
    var best = measured
    var bestErr = abs(measured - reference)
    for factor in [0.5, 2.0] {
      let scaled = measured * factor
      let err = abs(scaled - reference)
      if err < bestErr {
        best = scaled
        bestErr = err
      }
    }
    return best
  }

  // MARK: - Shared onset-feature seam (Story 8-2 KDD-C4)

  /// Produces the onset-feature substrate for beat tracking from decoded audio.
  ///
  /// Retained from the Story 8-2 stub: it is the cross-consumer bit-equality seam
  /// (`FeatureSubstrateTests.crossConsumerSharedSubstrate`) proving the beat-grid
  /// consumer receives the SAME `DecodedAudio` the BPM and LUFS analyzers share
  /// and produces bit-equal ``FeatureSubstrate/OnsetFeatures`` through the Story
  /// 6.2 builder facade. Step-11 beat tracking reuses the BPM pipeline's in-scope
  /// envelope rather than re-deriving features here, but this seam stays public
  /// to the test (DD #8).
  static func onsetFeatures(
    for decoded: FeatureSubstrate.DecodedAudio,
    weighting: FeatureSubstrate.WeightingProfile
  ) throws -> FeatureSubstrate.OnsetFeatures {
    try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: weighting)
  }
}
