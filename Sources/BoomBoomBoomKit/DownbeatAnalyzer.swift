//
//  DownbeatAnalyzer.swift
//  BoomBoomBoomKit
//
//  Internal downbeat-phase estimator (Story 8.5a): conservative, fixed-4/4,
//  percussive-accent estimation of which beat-in-bar is beat 1, with an honest
//  abstain path. Runs over the beats the Story-8.4 DP tracker recovered plus the
//  per-frame sub-band onset envelopes.
//

import Accelerate
import Foundation

/// Internal downbeat-phase estimator (Story 8.5a).
///
/// Estimates a single downbeat **phase** for percussive, constant-tempo, 4/4
/// material — which beat-in-bar is beat 1 — and abstains when the rhythmic
/// evidence is weak. It is deliberately conservative: a wrong downbeat on a live
/// deck is worse than no downbeat, so the success condition is "produce a
/// downbeat when the rhythmic evidence is strong; otherwise abstain", NOT "always
/// produce one". This is NOT general downbeat tracking (no variable meter, no
/// per-beat bar position, no ML — Story 8.5a DD #1 / DD #8).
///
/// ## Heuristic — metrical accent (academic grounding, aubio fence held)
/// The bar start carries a low-frequency / bass + percussive accent; the backbeat
/// (snare/clap on 2 & 4) carries a high-mid "crack". The per-beat score therefore
/// rewards low-band energy and lightly penalises the snare-crack band. The
/// approach is grounded in the published metrical-accent literature (Goto's
/// bass/drum-pattern beat tracking; Klapuri, Eronen & Astola, "Analysis of the
/// meter of acoustic musical signals"; and — as the *learned* directions this
/// MVP deliberately does NOT take — Durand, Bello, David & Richard, and Böck,
/// Krebs & Widmer, "Joint Beat and Downbeat Tracking with Recurrent Neural
/// Networks", ISMIR 2016). A clean-room implementation; imports stay `Foundation`
/// + `Accelerate`.
///
/// ## Provenance
/// Runs alongside ``BeatGridAnalyzer/estimateBeatGrid(onsetEnvelope:onsetRate:hopSize:sampleRate:acf:tempoBPM:windowStartSample:coverage:subBands:detectDownbeats:)``
/// in the same window-relative frame space the beats were tracked in (DD #5), so
/// the beat frame indices index directly into the sub-band envelopes with no
/// track↔window offset reconciliation.
enum DownbeatAnalyzer {

  // MARK: - Tuning constants

  /// Per-beat sampling half-window as a fraction of the beat period (±20%).
  private static let sampleWindowFraction = 0.20

  /// Peak-divide normalisation floor (Float), so an all-zero band divides by `ε`
  /// rather than `0`.
  private static let epsilon: Float = 1e-6

  /// Score weights (DD #7): strong low-band emphasis marks bar starts; a light
  /// full-band term breaks ties; subtract the snare-crack band to suppress
  /// backbeat phases.
  private static let lowBandWeight: Float = 1.0
  private static let fullBandWeight: Float = 0.25
  private static let snareCrackPenalty: Float = 0.25

  /// Confidence blend: margin over the runner-up dominates; separation from the
  /// mean phase score is the minority term (AC4).
  private static let marginWeight: Float = 0.7
  private static let separationWeight: Float = 0.3

  /// Abstain gate thresholds (AC4): the winner must beat the runner-up by this
  /// ratio, and the blended confidence must clear this floor.
  private static let winnerOverRunnerUpRatio: Float = 1.25
  private static let confidenceFloor: Float = 0.4

  // MARK: - Outcome

  /// The estimator's result: a populated estimate plus the index (into the
  /// tracked `beats`) of the first downbeat (the bar-extrapolation anchor), or an
  /// honest abstain.
  enum Outcome: Sendable {
    case detected(estimate: DownbeatEstimate, firstDownbeatBeatIndex: Int)
    case noneDetected
  }

  // MARK: - Estimation

  /// Estimates the downbeat phase over the tracked beats and the per-frame
  /// sub-band onset envelopes.
  ///
  /// - Parameters:
  ///   - beatFrames: Window-relative onset-envelope frame index per beat, parallel
  ///     to `beats` (the indices the sub-band envelopes are sampled at).
  ///   - beats: The tracked beats (for `presentationTime` phase-folding and to
  ///     build the downbeat `BeatTimestamp`s / anchor), parallel to `beatFrames`.
  ///   - fullBand: The full-band onset envelope over the analysis window.
  ///   - subBands: The four per-frame sub-band onset envelopes
  ///     `[kick, snareLow, snareCrack, hiHat]`; `subBands[0]` is the low/kick band
  ///     and `subBands[2]` the snare-crack band.
  ///   - periodFrames: Beat period in onset frames (`onsetRate · 60 / tempo`),
  ///     used for the ±20% sampling window.
  ///   - estimatedTempo: The grid's tempo in BPM, used for the seconds-domain
  ///     `beatPeriod = 60 / estimatedTempo` the position-quantized phase folding
  ///     and grid-integrity check use.
  ///   - beatsPerBar: Beats per bar (4 in Story 8.5a, assumed).
  /// - Returns: ``Outcome/detected(estimate:firstDownbeatBeatIndex:)`` on a strong
  ///   recurring accent, else ``Outcome/noneDetected``.
  static func estimate(  // swiftlint:disable:this function_parameter_count
    beatFrames: [Int],
    beats: [BeatTimestamp],
    fullBand: [Float],
    subBands: [[Float]],
    periodFrames: Double,
    estimatedTempo: Double,
    beatsPerBar: Int = 4
  ) -> Outcome {
    // --- Structural / input guards -------------------------------------------
    guard beatsPerBar >= 1 else { return .noneDetected }
    // AC4(a): need ≥ 3 complete bars of beats. Written `count / beatsPerBar >= 3`
    // (equivalent to `count >= 3·beatsPerBar` for the positive `beatsPerBar` just
    // guarded) so an extreme internal `beatsPerBar` cannot overflow the multiply.
    guard beats.count / beatsPerBar >= 3 else { return .noneDetected }
    guard beatFrames.count == beats.count else { return .noneDetected }
    guard periodFrames.isFinite, periodFrames > 0 else { return .noneDetected }
    guard estimatedTempo.isFinite, estimatedTempo > 0 else { return .noneDetected }
    // Defensive: `BeatTimestamp` already clamps `presentationTime` finite at every
    // construction path, so this never fires in production — but the position-fold
    // and grid-integrity steps below quantize `presentationTime` into `Int`, which
    // would trap on a non-finite value, so guard locally rather than rely on the
    // upstream invariant alone.
    guard beats.allSatisfy({ $0.presentationTime.isFinite }) else { return .noneDetected }
    // Need the low (0) and snare-crack (2) bands, each frame-aligned to fullBand.
    let n = fullBand.count
    guard n > 0, subBands.count >= 3 else { return .noneDetected }
    guard subBands[0].count == n, subBands[2].count == n else { return .noneDetected }

    let beatPeriod = 60.0 / estimatedTempo  // seconds

    // --- AC3.3 grid-integrity abstain ----------------------------------------
    // If the DP genuinely shredded the grid (too many off-period intervals),
    // refuse to fold a phase from an unreliable beat array. A single dropped or
    // doubled beat is ≈ one off-grid interval — well under the fraction limit on
    // a multi-bar window — so it does NOT trip this; position-quantized folding
    // (below) handles that. The guard fires only on a shredded grid.
    if BeatGridGridIntegrity.isShredded(beats: beats, beatPeriod: beatPeriod) {
      return .noneDetected
    }

    // --- AC3.1 peak-divide-normalise each band across the window -------------
    // (Not z-score: z-score emits negatives that would collide with the clamp ≥ 0
    // in the score and silently zero half the signal.)
    let lowNorm = peakNormalized(subBands[0])
    let crackNorm = peakNormalized(subBands[2])
    let fullNorm = peakNormalized(fullBand)

    // --- AC3.1/AC3.2 per-beat score (±20% window peak per band) --------------
    // `scores` is allocated ONCE here, not per beat; the per-beat sampling loop
    // uses vDSP_maxv over a sub-range with no per-iteration heap allocation (AC7).
    let half = Int((sampleWindowFraction * periodFrames).rounded())
    var scores = [Float](repeating: 0, count: beats.count)
    fullNorm.withUnsafeBufferPointer { fp in
      lowNorm.withUnsafeBufferPointer { lp in
        crackNorm.withUnsafeBufferPointer { cp in
          for (i, f) in beatFrames.enumerated() {
            let lo = max(0, f - half)
            let hi = min(n - 1, f + half)
            guard hi >= lo else { continue }
            let count = vDSP_Length(hi - lo + 1)
            var lowPeak: Float = 0
            var fullPeak: Float = 0
            var crackPeak: Float = 0
            vDSP_maxv(lp.baseAddress! + lo, 1, &lowPeak, count)
            vDSP_maxv(fp.baseAddress! + lo, 1, &fullPeak, count)
            vDSP_maxv(cp.baseAddress! + lo, 1, &crackPeak, count)
            let raw =
              lowBandWeight * lowPeak + fullBandWeight * fullPeak
              - snareCrackPenalty * crackPeak
            scores[i] = max(0, raw)
          }
        }
      }
    }

    // --- AC3.3 bar-phase index by quantized POSITION (not array index) -------
    let firstBeatTime = beats[0].presentationTime
    var phases = [Int](repeating: 0, count: beats.count)
    for i in 0..<beats.count {
      phases[i] = BarPhase.index(
        ofTime: beats[i].presentationTime, firstTime: firstBeatTime,
        beatPeriod: beatPeriod, beatsPerBar: beatsPerBar)
    }

    // --- AC3.4 aggregate each phase bin with a median (not a raw sum) --------
    // The per-bin reduction is O(beatsPerBar ≤ 4)-small; its sort is explicitly
    // exempt from AC7's no-per-beat-heap rule (it is a fixed-width bin reduction,
    // not a per-beat loop).
    var binScores = [[Float]](repeating: [], count: beatsPerBar)
    for i in 0..<beats.count { binScores[phases[i]].append(scores[i]) }
    let binAggregate = binScores.map { median($0) }

    // Winner = max-aggregate phase bin; runner-up = second-highest aggregate.
    var winnerPhase = 0
    var winner: Float = binAggregate[0]
    for p in 1..<beatsPerBar where binAggregate[p] > winner {
      winner = binAggregate[p]
      winnerPhase = p
    }
    var runnerUp: Float = 0
    for p in 0..<beatsPerBar where p != winnerPhase {
      runnerUp = max(runnerUp, binAggregate[p])
    }
    let meanPhaseScore = binAggregate.reduce(0, +) / Float(beatsPerBar)

    // --- AC4 confidence ------------------------------------------------------
    let eps = epsilon
    let denom = max(winner, eps)
    let margin = clamp01((winner - runnerUp) / denom)
    let separation = clamp01((winner - meanPhaseScore) / denom)
    let confidence = marginWeight * margin + separationWeight * separation

    // --- AC4 multi-bar support (gate d) -------------------------------------
    // The winner phase must carry a real *recurring* accent: its per-bar score
    // beats the global per-beat mean in ≥ ceil(bars/2) bars (not a single spike).
    let globalBeatMean = scores.reduce(0, +) / Float(beats.count)
    let supportingBars = binScores[winnerPhase].filter { $0 > globalBeatMean }.count
    let bars = beats.count / beatsPerBar
    let requiredSupport = (bars + 1) / 2  // ceil(bars / 2)

    // --- AC4 four-part abstain gate ------------------------------------------
    // Gate (a) — ≥ 3 complete bars — is enforced as the upstream input guard
    // (`beats.count / beatsPerBar >= 3`); gates (b) margin, (c) confidence, and
    // (d) multi-bar support are the three predicates here.
    let passesMargin = winner > 0 && winner >= winnerOverRunnerUpRatio * runnerUp
    let passesConfidence = confidence >= confidenceFloor
    let passesSupport = supportingBars >= requiredSupport
    guard passesMargin, passesConfidence, passesSupport else { return .noneDetected }

    // --- AC3.4 / AC5 success: build the downbeat estimate -------------------
    var downbeatBeats: [BeatTimestamp] = []
    var firstIdx = -1
    for i in 0..<beats.count where phases[i] == winnerPhase {
      if firstIdx < 0 { firstIdx = i }
      downbeatBeats.append(beats[i])
    }
    guard firstIdx >= 0 else { return .noneDetected }

    let estimate = DownbeatEstimate(
      beats: downbeatBeats,
      meter: MeterEstimate(beatsPerBar: beatsPerBar, source: .assumed),
      confidence: confidence,
      phaseIndex: winnerPhase)
    return .detected(estimate: estimate, firstDownbeatBeatIndex: firstIdx)
  }

  // MARK: - Helpers

  /// Peak-divide normalisation to `[0, 1]`: `band / max(ε, max(band))`. One vDSP
  /// max + one vDSP scalar-divide; allocates a single output array (not per beat).
  private static func peakNormalized(_ band: [Float]) -> [Float] {
    let count = band.count
    guard count > 0 else { return [] }
    var maxVal: Float = 0
    vDSP_maxv(band, 1, &maxVal, vDSP_Length(count))
    var divisor = max(epsilon, maxVal)
    var out = [Float](repeating: 0, count: count)
    vDSP_vsdiv(band, 1, &divisor, &out, 1, vDSP_Length(count))
    return out
  }

  /// True median of a small score list (the per-phase bin). `0` for an empty bin.
  /// Rejects a single transient a raw sum would be fooled by (AC3.4); over a
  /// `≤ 4`-bin fixed-width reduction, so its sort is AC7-exempt.
  ///
  /// For an even count this averages the two middle elements (the conventional
  /// median) rather than taking the upper-middle one — the upper-middle biases
  /// even-sized bins upward and can flip the winner argmax on otherwise-tied bins.
  private static func median(_ xs: [Float]) -> Float {
    guard !xs.isEmpty else { return 0 }
    let s = xs.sorted()
    let mid = s.count / 2
    if s.count % 2 == 1 { return s[mid] }
    return (s[mid - 1] + s[mid]) / 2
  }

  /// Clamps to `[0, 1]`, mapping non-finite to `0` (a divide could produce NaN if
  /// `winner` were `0`, though `max(winner, ε)` guards the denominator).
  private static func clamp01(_ x: Float) -> Float {
    guard x.isFinite else { return 0 }
    return min(max(x, 0), 1)
  }
}
