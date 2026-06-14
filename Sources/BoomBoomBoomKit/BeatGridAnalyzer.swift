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
/// ## Scope
/// Beats only. Downbeat (bar-start) detection is not attempted, so the returned
/// grid carries ``DownbeatResult/notAttempted`` (downbeat detection lands in a
/// follow-up). The analyzer always emits ``TempoAgreement/notCompared``; the
/// combined ``AudioAnalysisService/analyze(url:options:)`` path re-stamps the
/// resolved agreement against the full BPM result (Story 8.5). The analyzer also
/// selects ``BeatGrid/gridOrigin`` (the phase-consistency anchor) and records the
/// supplied ``BeatGrid/coverage``.
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
  ///     adding this offset (Story 8.5: the resulting ``BeatTimestamp/presentationTime``
  ///     is decoded-PCM-relative — `t=0` is the decoded file start, with no
  ///     codec-priming subtraction).
  ///   - coverage: What span the supplied `onsetEnvelope` represents, recorded
  ///     verbatim on ``BeatGrid/coverage``. Defaults to
  ///     ``BeatGridCoverage/analysisWindow`` (the step-11 fan-out reuses the BPM
  ///     window envelope); the full-track seam passes the requested coverage.
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
    windowStartSample: Int,
    coverage: BeatGridCoverage = .analysisWindow
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

    // Pick the beat endpoint near the END of the envelope, then follow backlinks
    // to recover the full sequence in playback order.
    //
    // Two deliberate changes from a naive global `argmax` (Story 8.5, to make
    // long-coverage spans work — `.fullTrack` / `.window`):
    //
    //  - SCOPE: search only the FINAL predecessor window `[n - dMax, n)`, not all
    //    frames. The cumulative score is an `alpha = 0.8` geometric series, so at
    //    beat frames it climbs to a fixed point and then PLATEAUS (wobbling within
    //    Float precision) after ~70 beats — a global argmax then lands at an
    //    essentially arbitrary plateau frame and the backtrace truncates the grid
    //    to roughly that frame (empirically ~2 minutes regardless of true length).
    //    Anchoring the endpoint to the final window forces the backtrace to start
    //    near the end so the recovered sequence spans the whole envelope.
    //  - TIE-BREAK: `>=` (last max-scoring frame wins), not `>` (first). Within the
    //    final window this advances to the latest beat when the plateau ties,
    //    maximising coverage to the very end.
    //
    // Effect on the default `.analysisWindow` path: for the common case — a window
    // whose cumScore peaks at its last beat (monotone climb, no plateau, < ~70
    // beats) — the last beat both IS the global maximum and lies within
    // `[n - dMax, n)`, so the endpoint is unchanged. The endpoint differs from the
    // old global-`>` search only when the global maximum sat at an earlier frame
    // (a plateau, a quiet tail, or an exact cumScore tie) that the old code would
    // have backtraced from and TRUNCATED at — i.e. every divergence is a strict
    // coverage improvement, never a regression. Grid contents are not a pinned
    // contract (the beat grid is opt-in and unreleased); the BPM result is
    // untouched (byte-identity is locked separately on `BPMResult`).
    let endSearchStart = max(0, n - dMax)
    var endIdx = endSearchStart
    var endScore = -Float.greatestFiniteMagnitude
    for i in endSearchStart..<n where cumScore[i] >= endScore {
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

    // Trim "ghost" beats the DP extrapolated into LEADING/TRAILING silence. The
    // inherited cumulative score stays positive across silence (the period-
    // transition penalty is zero at the exact period), so the final-window
    // endpoint — or a backtrace through a silent head — can land on a frame past
    // the last real onset (or before the first), producing a beat whose
    // `presentationTime` sits in silence. A ghost has ~zero local onset; a real
    // beat (even a quiet one) does not. INTERIOR interpolated beats — the DP
    // filling a missing onset at the tracked period within the music — are
    // intentionally KEPT (a beat grid wants every beat position, onset or not);
    // only the silent head and tail are trimmed.
    let ghostFloor = envMax * 0.05
    while frames.count > 1, onsetEnvelope[frames[frames.count - 1]] <= ghostFloor {
      frames.removeLast()
    }
    while frames.count > 1, onsetEnvelope[frames[0]] <= ghostFloor {
      frames.removeFirst()
    }

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

    // The grid's tempo is the BPM-stage tempo the beats were tracked against.
    //
    // The DP's strong period-transition penalty (`tightness`) anchors every
    // recovered inter-beat interval near `period = onsetRate·60/tempoBPM`, so the
    // beats DO follow `tempoBPM` — reporting it directly is both the accurate
    // value and a faithful description of the grid's phase. Story 8.4 instead
    // RE-MEASURED the tempo from the integer-frame inter-beat intervals (median,
    // octave-snapped); that only re-quantized an already-accurate input — a single
    // onset frame is ~2% of the period at typical tempos (1 in 47 at 127 BPM) — so
    // the reported tempo carried ~0.2 BPM of quantization noise. That noise made a
    // consumer's anchor + tempo extrapolation drift ~500 ms over five minutes
    // (AC2) and pushed the grid tempo across the ~2% BPM/grid agreement band on
    // borderline tracks (AC8). The supplied `tempoBPM` is the tempogram +
    // fine-grid-refined estimate (sub-BPM), so it is the right value to report.
    // Octave handling stays the BPM stage's job (the grid owns phase), and the DP
    // tracks AT `tempoBPM`, not an octave of it, so no octave re-snap is needed.
    let estimatedTempo = tempoBPM

    // Overall confidence: half from mean beat onset salience, half from how strong
    // the autocorrelation is at the tracked period (signal periodicity at tempo).
    let meanStrength = strengthSum / Float(beats.count)
    let periodConfidence = acfStrengthAtPeriod(acf: acf, period: period)
    let confidence = 0.5 * meanStrength + 0.5 * periodConfidence

    // The Rekordbox-style extrapolation anchor (Story 8.5, DD #11): the single
    // most-trustworthy reference beat, picked by phase consistency.
    let gridOrigin = selectGridOrigin(beats: beats, estimatedTempo: estimatedTempo)

    return BeatGrid(
      beats: beats,
      downbeats: .notAttempted,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: .notCompared,
      gridOrigin: gridOrigin,
      coverage: coverage)
  }

  // MARK: - Grid-origin anchor selection (Story 8.5, DD #11)

  /// Neighbor half-window (in beats) for the phase-consistency scan. Bounding
  /// the scan keeps anchor selection O(beats · window) = linear in track length
  /// (DD #5) instead of O(beats²), while ±32 beats is more than enough to gauge
  /// a beat's local phase coherence.
  private static let anchorNeighborHalfWindow = 32

  /// Selects the ``BeatGridAnchor`` a consumer extrapolates the grid from
  /// (Story 8.5, AC4 / DD #11).
  ///
  /// **Phase consistency, not raw strength.** The chosen anchor is the beat
  /// whose neighbors best fall on its own extrapolated grid (`time + k·period`),
  /// weighted by both the neighbors' and the anchor's confidence/strength. Raw
  /// max-strength can pick a snare fill / off-beat transient; the first DP beat
  /// can be a weak beat at an energy transition. So:
  ///
  /// 1. score each beat by neighbor phase-alignment × its own confidence/strength;
  ///    the max positive score wins as ``BeatGridAnchorSource/medianConsistentBeat``;
  /// 2. else fall back to the strongest beat (``BeatGridAnchorSource/strongestBeat``);
  /// 3. else the first beat (``BeatGridAnchorSource/firstBeat``).
  ///
  /// Returns `nil` only for an empty `beats` array. Reuses the already-computed
  /// `beats` — no new buffer.
  private static func selectGridOrigin(
    beats: [BeatTimestamp], estimatedTempo: Double
  ) -> BeatGridAnchor? {
    guard !beats.isEmpty else { return nil }

    // Beat period in seconds. A non-positive/non-finite tempo (the "no valid
    // estimate" path) leaves us no grid to test phase against → skip straight to
    // the strength/first fallback.
    let period = estimatedTempo > 0 ? 60.0 / estimatedTempo : 0

    func anchor(_ i: Int, _ source: BeatGridAnchorSource) -> BeatGridAnchor {
      BeatGridAnchor(
        beatIndex: i,
        presentationTime: beats[i].presentationTime,
        confidence: beats[i].confidence,
        strength: beats[i].strength,
        source: source)
    }

    if period > 0, beats.count >= 2 {
      var bestScore = -1.0
      var bestIdx = -1
      for i in 0..<beats.count {
        let anchorTime = beats[i].presentationTime
        let lo = max(0, i - anchorNeighborHalfWindow)
        let hi = min(beats.count, i + anchorNeighborHalfWindow + 1)
        var alignSum = 0.0
        var weightSum = 0.0
        for j in lo..<hi where j != i {
          let dt = beats[j].presentationTime - anchorTime
          let k = (dt / period).rounded()
          let gridTime = anchorTime + k * period
          // Fractional phase error in [0, 0.5]; 1 - 2·err ∈ [0, 1] (1 = on grid).
          let err = abs(beats[j].presentationTime - gridTime) / period
          let alignment = max(0.0, 1.0 - 2.0 * err)
          let w = Double(beats[j].confidence) + Double(beats[j].strength)
          alignSum += alignment * w
          weightSum += w
        }
        let neighborAlignment = weightSum > 0 ? alignSum / weightSum : 0
        // Blend with the anchor's own salience so a strong, well-placed beat
        // outranks a weak one whose neighbors happen to fit.
        let ownWeight = (Double(beats[i].confidence) + Double(beats[i].strength)) / 2.0
        let score = neighborAlignment * ownWeight
        if score > bestScore {
          bestScore = score
          bestIdx = i
        }
      }
      if bestIdx >= 0, bestScore > 0 {
        return anchor(bestIdx, .medianConsistentBeat)
      }
    }

    // Fallback 1: strongest beat.
    var strongestIdx = 0
    var strongest = beats[0].strength
    for i in 1..<beats.count where beats[i].strength > strongest {
      strongest = beats[i].strength
      strongestIdx = i
    }
    if strongest > 0 {
      return anchor(strongestIdx, .strongestBeat)
    }

    // Fallback 2: first beat.
    return anchor(0, .firstBeat)
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
