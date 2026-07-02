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
/// Beats by default; downbeats opt-in. When `detectDownbeats` is `false` (the
/// default) the returned grid carries ``DownbeatResult/notAttempted``. When
/// `true`, ``DownbeatAnalyzer`` runs over the tracked beats + sub-band envelopes
/// (Story 8.5a) and the grid carries ``DownbeatResult/detected(estimate:)`` (with
/// ``BeatGrid/gridOrigin`` repointed to the first downbeat) or an honest
/// ``DownbeatResult/noneDetected`` abstain. The analyzer always emits
/// ``TempoAgreement/notCompared``; the
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
  ///   - subBands: The four per-frame sub-band onset envelopes
  ///     `[kick, snareLow, snareCrack, hiHat]` (window-relative, frame-aligned to
  ///     `onsetEnvelope`), consumed by the Story-8.5a downbeat estimator. Empty
  ///     (default) when downbeats are not requested.
  ///   - detectDownbeats: When `true`, runs the Story-8.5a downbeat-phase
  ///     estimator over the tracked beats + `subBands` and sets
  ///     ``BeatGrid/downbeats`` to ``DownbeatResult/detected(estimate:)`` (also
  ///     repointing ``BeatGrid/gridOrigin`` to the first downbeat with
  ///     ``BeatGridAnchorSource/downbeat``) or ``DownbeatResult/noneDetected``.
  ///     When `false` (default), ``BeatGrid/downbeats`` is
  ///     ``DownbeatResult/notAttempted`` and the 8.5 phase-consistency anchor is
  ///     preserved.
  ///   - refineBeatGridTempo: When `true` (Story 8.10), the grid's reported
  ///     ``BeatGrid/estimatedTempo`` is refined to sub-0.1-BPM precision by
  ///     fitting a continuous interpolated onset-comb against the in-scope
  ///     `onsetEnvelope` (seeded by `tempoBPM`), guarded so it is never worse
  ///     than the seed. Default `false` reports `tempoBPM` verbatim
  ///     (byte-identical to Story 8.4/8.5). See ``refineTempo(seedBPM:onsetEnvelope:frames:onsetRate:acf:)``.
  ///   - refinementSink: Invoked once with the refinement diagnostic when
  ///     `refineBeatGridTempo` is `true` (regardless of acceptance). Default is a
  ///     no-op; the step-11 fan-out passes a closure that records it onto
  ///     ``BPMDiagnosticTrace/beatGridTempoRefinement`` when tracing is on.
  /// - Returns: A populated ``BeatGrid``, or `nil` for degenerate input (empty
  ///   envelope, non-positive/non-finite tempo, all-zero envelope, or a window
  ///   too short to hold at least two beats — shorter than two beat periods).
  static func estimateBeatGrid(  // swiftlint:disable:this function_parameter_count
    onsetEnvelope: [Float],
    onsetRate: Double,
    hopSize: Int,
    sampleRate: Double,
    acf: [Float],
    tempoBPM: Double,
    windowStartSample: Int,
    coverage: BeatGridCoverage = .analysisWindow,
    subBands: [[Float]] = [],
    detectDownbeats: Bool = false,
    downbeatStrategy: DownbeatStrategy = .metricalAccent,
    dropContour: StructuralDropAnalyzer.Contour? = nil,
    refineBeatGridTempo: Bool = false,
    refinementSink: (BeatGridTempoRefinementEvidence) -> Void = { _ in },
    downbeatSink: (DownbeatStrategyEvidence) -> Void = { _ in }
  ) -> BeatGrid? {
    let n = onsetEnvelope.count
    guard n > 0, hopSize > 0, sampleRate > 0, onsetRate > 0 else { return nil }
    guard tempoBPM.isFinite, tempoBPM > 0 else { return nil }

    // Beat period in onset frames. The upper bound (`period * 2 <= n`) requires
    // room for at least one full inter-beat interval, so a returned grid always
    // holds >= 2 beats (and `selectGridOrigin`'s phase-consistency path, which
    // needs `beats.count >= 2`, can run). A window of exactly one period yields
    // a degenerate single-beat grid, so it is rejected as too short. This bound
    // ALSO keeps the `Int(...)` conversions below in range: an enormous-but-finite
    // period (from a tiny-but-finite `tempoBPM`) makes `period * 2` enormous too,
    // so the guard rejects before `Int((period * 2).rounded())` can trap or drive
    // a multi-gigabyte `txCost` span.
    let period = onsetRate * 60.0 / tempoBPM
    guard period >= 1, period.isFinite, period * 2.0 <= Double(n) else { return nil }

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
    // `presentationTime` sits in silence. INTERIOR interpolated beats — the DP
    // filling a missing onset at the tracked period within the music — are
    // intentionally KEPT (a beat grid wants every beat position, onset or not);
    // only a silent head/tail is trimmed.
    //
    // The test is a CONTIGUOUS-SILENT-REGION check on the inter-beat span between an
    // edge beat and its neighbour, NOT the edge beat's salience vs the global `envMax`.
    // The old `<= envMax * 0.05` gate compared each edge beat to the loudest beat in the
    // track, so a genuine but QUIET fade-in/out beat (well below 5% of a loud drop) was
    // wrongly trimmed. A local span keeps a quiet-but-real fade beat (its span carries
    // its own onset energy) and drops only a beat extrapolated across a genuinely empty
    // span. Honest limits: an onset already zeroed by `adaptiveThreshold` can still be
    // trimmed, and low-level noise/reverb inside the span can retain a ghost — both are
    // conservative (keeping a beat is safer than dropping a real one).
    //
    // The threshold is RELATIVE to the envelope's own peak (like the `localScore`
    // normalization above), so the trim is scale-invariant — a quieter recording yields the
    // same grid. A bare absolute floor would strip every edge beat once `envMax` dropped
    // below it. `envMax > 0` is guaranteed above, so no clamp is needed; for a vanishing
    // peak the product underflows toward 0 and only an exactly-empty span is trimmed.
    let silenceEps = envMax * 1e-4
    // Max of `onsetEnvelope` over the half-open frame range `[lo, hi)` (0 if empty).
    func windowMax(_ lo: Int, _ hi: Int) -> Float {
      guard lo < hi else { return 0 }
      var m: Float = 0
      onsetEnvelope.withUnsafeBufferPointer { buf in
        vDSP_maxv(buf.baseAddress! + lo, 1, &m, vDSP_Length(hi - lo))
      }
      return m
    }
    // Trailing: drop the last beat while the span `(prev, last]` carries no onset.
    while frames.count > 1,
      windowMax(frames[frames.count - 2] + 1, frames[frames.count - 1] + 1) <= silenceEps
    {
      frames.removeLast()
    }
    // Leading: drop the first beat while the span `[first, next)` carries no onset.
    while frames.count > 1, windowMax(frames[0], frames[1]) <= silenceEps {
      frames.removeFirst()
    }

    // Map beat frames → BeatTimestamps. strength is the KDD-C2 normalised onset
    // salience at the (window-relative) beat frame; presentationTime is offset by
    // windowStartSample to be track-relative (DD #6). Per-beat confidence measures
    // how close the interval to the previous beat is to the known period.
    var beats: [BeatTimestamp] = []
    beats.reserveCapacity(frames.count)
    // The window-relative beat frames, kept parallel to `beats` so the downbeat
    // estimator samples the sub-band envelopes at exactly the beats' frames (DD
    // #5). It is ALSO the source of truth for the per-beat interval: confidence
    // reads `beatFrames.last` (the previous EMITTED beat frame), so alignment is
    // enforced by construction rather than by the enumeration index staying in
    // lockstep — correct even if the defensive guard below ever skips a frame.
    var beatFrames: [Int] = []
    beatFrames.reserveCapacity(frames.count)
    var strengthSum: Float = 0
    for f in frames {
      // f is a DP index, always in 0..<n; guard defensively per AC5.
      guard f >= 0, f < n else { continue }
      let strength = onsetEnvelope[f] / envMax
      strengthSum += strength
      let presentationTime =
        (Double(windowStartSample) + Double(f) * Double(hopSize)) / sampleRate
      let beatConfidence: Float
      if let prevFrame = beatFrames.last {
        let interval = Double(f - prevFrame)
        let r = interval > 0 ? log(interval / period) : 0
        beatConfidence = Float(exp(-r * r))
      } else {
        // First EMITTED beat: no prior interval, confidence is raw salience.
        beatConfidence = strength
      }
      beats.append(
        BeatTimestamp(
          presentationTime: presentationTime,
          confidence: beatConfidence,
          strength: strength))
      beatFrames.append(f)
    }
    guard !beats.isEmpty else { return nil }

    // The grid's tempo is the BPM-stage tempo the beats were tracked against —
    // optionally refined to sub-0.1-BPM precision (Story 8.10).
    //
    // The DP's strong period-transition penalty (`tightness`) anchors every
    // recovered inter-beat interval near `period = onsetRate·60/tempoBPM`, so the
    // beats DO follow `tempoBPM`. But `tempoBPM` is only tuned to NAME the track
    // (~2–4% — plenty to label it, far too coarse to extrapolate a grid over
    // hundreds of beats: a few-tenths-of-a-BPM rate error is a lever arm that
    // accumulates into tens of ms of within-track drift). Story 8.4 tried to
    // tighten it by RE-MEASURING from the integer-frame inter-beat-interval
    // median — but a single onset frame is ~2% of the period (1 in 47 at 127 BPM),
    // so that only re-quantized the input and ADDED ~0.2 BPM of noise; it was
    // reverted (as was the Story 8.9 DP-beat tempo+phase refit, which regressed
    // with no reject-guard). The distinguishing mechanism this time (DD #2) is a
    // CONTINUOUS interpolated onset-comb fit at sub-frame resolution — never
    // integer beat intervals — jointly over period AND phase, guarded so the
    // result is never worse than the seed (DD #4). When `refineBeatGridTempo` is
    // off, `tempoBPM` is reported verbatim (byte-identical to 8.4/8.5). Octave
    // handling stays the BPM stage's job (the DP tracks AT `tempoBPM`, and the
    // refit window is bounded well under an octave), so no octave re-snap is done.
    var estimatedTempo = tempoBPM
    if refineBeatGridTempo {
      let refit = refineTempo(
        seedBPM: tempoBPM, onsetEnvelope: onsetEnvelope, frames: beatFrames,
        onsetRate: onsetRate, acf: acf)
      estimatedTempo = refit.tempo
      refinementSink(
        BeatGridTempoRefinementEvidence(
          coarseTempo: tempoBPM, refinedTempo: refit.tempo,
          supportSeed: refit.supportSeed, supportRefined: refit.supportRefined,
          accepted: refit.accepted))
    }

    // Overall confidence: half from mean beat onset salience, half from how strong
    // the autocorrelation is at the tracked period (signal periodicity at tempo).
    let meanStrength = strengthSum / Float(beats.count)
    let periodConfidence = acfStrengthAtPeriod(acf: acf, period: period)
    let confidence = 0.5 * meanStrength + 0.5 * periodConfidence

    // The Rekordbox-style extrapolation anchor (Story 8.5, DD #11): the single
    // most-trustworthy reference beat, picked by phase consistency. On a
    // successful downbeat detection below it is repointed to the first downbeat.
    var gridOrigin = selectGridOrigin(beats: beats, estimatedTempo: estimatedTempo)

    // Story 8.5a: optional downbeat-phase estimation. When requested, run the
    // conservative estimator over the tracked beats + sub-band envelopes; on a
    // confident detection set `.detected(estimate:)` and repoint the anchor to the
    // first downbeat (`source == .downbeat`); on an honest abstain set
    // `.noneDetected` and keep the 8.5 phase-consistency anchor. When not
    // requested the grid carries `.notAttempted` exactly as Story 8.4/8.5.
    let downbeats: DownbeatResult
    if detectDownbeats {
      // Story 8.11: dispatch on the selected strategy. `.metricalAccent` is the
      // verbatim 8.5a path (default); `.structuralDrop` / `.combined` consume the
      // pre-trim energy contour the caller threaded in. The strategy is consulted
      // ONLY inside this branch, so the default-off path stays byte-identical.
      switch resolveDownbeat(
        strategy: downbeatStrategy,
        inputs: DownbeatInputs(
          beatFrames: beatFrames,
          beats: beats,
          onsetEnvelope: onsetEnvelope,
          subBands: subBands,
          periodFrames: period,
          estimatedTempo: estimatedTempo,
          dropContour: dropContour),
        sink: downbeatSink)
      {
      case .detected(let estimate, let firstIdx):
        downbeats = .detected(estimate: estimate)
        gridOrigin = BeatGridAnchor(
          beatIndex: firstIdx,
          presentationTime: beats[firstIdx].presentationTime,
          confidence: beats[firstIdx].confidence,
          strength: beats[firstIdx].strength,
          source: .downbeat)
      case .noneDetected:
        downbeats = .noneDetected
      }
    } else {
      downbeats = .notAttempted
    }

    return BeatGrid(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: .notCompared,
      gridOrigin: gridOrigin,
      coverage: coverage)
  }

  // MARK: - Downbeat-strategy dispatch (Story 8.11)

  /// The per-grid inputs the downbeat-strategy dispatch consumes (Story 8.11).
  /// Bundled into one named context so ``resolveDownbeat(strategy:inputs:sink:)``
  /// stays within the parameter-count budget and both estimators share the same
  /// inputs.
  private struct DownbeatInputs {
    let beatFrames: [Int]
    let beats: [BeatTimestamp]
    let onsetEnvelope: [Float]
    let subBands: [[Float]]
    let periodFrames: Double
    let estimatedTempo: Double
    let dropContour: StructuralDropAnalyzer.Contour?
  }

  /// Dispatches the requested ``DownbeatStrategy`` and emits the typed diagnostic
  /// evidence. `.metricalAccent` is the verbatim Story-8.5a estimator; the other
  /// two consume the pre-trim energy `dropContour` (nil → structural-drop abstains,
  /// `.combined` degrades to metrical-only). A single
  /// ``StructuralDropAnalyzer/resolve(contour:beats:estimatedTempo:beatsPerBar:)``
  /// pass feeds both the outcome and the evidence.
  private static func resolveDownbeat(
    strategy: DownbeatStrategy,
    inputs: DownbeatInputs,
    sink: (DownbeatStrategyEvidence) -> Void
  ) -> DownbeatAnalyzer.Outcome {
    func metricalOutcome() -> DownbeatAnalyzer.Outcome {
      DownbeatAnalyzer.estimate(
        beatFrames: inputs.beatFrames, beats: inputs.beats, fullBand: inputs.onsetEnvelope,
        subBands: inputs.subBands, periodFrames: inputs.periodFrames,
        estimatedTempo: inputs.estimatedTempo)
    }
    func phaseIndex(_ outcome: DownbeatAnalyzer.Outcome) -> Int? {
      if case .detected(let estimate, _) = outcome { return estimate.phaseIndex }
      return nil
    }
    func confidence(_ outcome: DownbeatAnalyzer.Outcome) -> Double {
      if case .detected(let estimate, _) = outcome { return Double(estimate.confidence) }
      return 0
    }
    func dropInfo(_ resolution: StructuralDropAnalyzer.Resolution) -> (time: Double?, phase: Int?) {
      switch resolution {
      case .confident(let phase, let dropTime, _): return (dropTime, phase)
      case .halfBarAmbiguous(let phaseA, _, let dropTime, _): return (dropTime, phaseA)
      case .none: return (nil, nil)
      }
    }

    switch strategy {
    case .metricalAccent:
      let outcome = metricalOutcome()
      sink(
        DownbeatStrategyEvidence(
          strategy: .metricalAccent, dropTimeSeconds: nil, dropPhase: nil,
          metricalAccentPhase: phaseIndex(outcome), agreement: nil,
          chosenPhase: phaseIndex(outcome), confidence: confidence(outcome)))
      return outcome

    case .structuralDrop:
      guard let contour = inputs.dropContour else {
        sink(
          DownbeatStrategyEvidence(
            strategy: .structuralDrop, dropTimeSeconds: nil, dropPhase: nil,
            metricalAccentPhase: nil, agreement: nil, chosenPhase: nil, confidence: 0))
        return .noneDetected
      }
      let resolution = StructuralDropAnalyzer.resolve(
        contour: contour, beats: inputs.beats, estimatedTempo: inputs.estimatedTempo)
      let outcome = StructuralDropAnalyzer.outcome(
        from: resolution, beats: inputs.beats, estimatedTempo: inputs.estimatedTempo)
      let drop = dropInfo(resolution)
      sink(
        DownbeatStrategyEvidence(
          strategy: .structuralDrop, dropTimeSeconds: drop.time, dropPhase: drop.phase,
          metricalAccentPhase: nil, agreement: nil,
          chosenPhase: phaseIndex(outcome), confidence: confidence(outcome)))
      return outcome

    case .combined:
      let metrical = metricalOutcome()
      let resolution =
        inputs.dropContour.map {
          StructuralDropAnalyzer.resolve(
            contour: $0, beats: inputs.beats, estimatedTempo: inputs.estimatedTempo)
        } ?? .none
      let outcome = StructuralDropAnalyzer.combine(
        metrical: metrical, drop: resolution, beats: inputs.beats,
        estimatedTempo: inputs.estimatedTempo)
      let drop = dropInfo(resolution)
      let mPhase = phaseIndex(metrical)
      // Agreement reflects whether metrical concurs with the drop's resolution. For a
      // half-bar-ambiguous drop the metrical phase agrees if it matches EITHER candidate
      // (phaseA/phaseB) — that is exactly the case `combine` resolves into a detected
      // downbeat, so reporting `false` there (the old `mPhase == phaseA`-only test) was a
      // diagnostic lie. Nil unless both sources fired.
      let agreement: Bool?
      switch resolution {
      case .confident(let dropPhase, _, _):
        agreement = mPhase.map { $0 == dropPhase }
      case .halfBarAmbiguous(let phaseA, let phaseB, _, _):
        agreement = mPhase.map { $0 == phaseA || $0 == phaseB }
      case .none:
        agreement = nil
      }
      sink(
        DownbeatStrategyEvidence(
          strategy: .combined, dropTimeSeconds: drop.time, dropPhase: drop.phase,
          metricalAccentPhase: mPhase, agreement: agreement,
          chosenPhase: phaseIndex(outcome), confidence: confidence(outcome)))
      return outcome
    }
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

  // MARK: - Continuous tempo refinement (Story 8.10)

  /// Minimum number of beats the usable span must hold for the refit to attempt a
  /// fix. A sub-0.1-BPM fit needs a long lever arm; a 2–3-beat span is unstable,
  /// so below this the refit abstains and returns the seed unconditionally.
  private static let refineMinBeats = 8

  /// Relative half-width of the period search window at WEAK periodicity. Bounded
  /// well under an octave (`0.04 ≪ 0.5`), so the window can never reach a
  /// half/double-tempo octave — the window bound IS the octave safety (DD #3), no
  /// separate octave-band check is needed (or shippable: it could never fire).
  private static let refineMaxHalfWidth = 0.04

  /// Relative half-width at STRONG periodicity (narrow — the seed is trustworthy).
  private static let refineMinHalfWidth = 0.015

  /// Minimum onset-comb CONTRAST (best-phase mean ÷ overall mean onset energy) for
  /// the seed period before the refit will attempt a fix. A signal with no comb
  /// concentration at the seed period — aperiodic noise, a flat-constant envelope
  /// — has contrast ≈ 1; there is no beat phase to sharpen, so the refit abstains
  /// (returns the seed, byte-identical to the unrefined grid). This is an abstain
  /// gate on whether to refine at all (the min-span abstain's sibling), NOT an
  /// epsilon on the accept comparison (which stays a strict `>`).
  private static let refineMinContrast = 1.5

  /// Number of candidate periods scanned across the window. Parabolic vertex
  /// interpolation around the coarse peak then resolves sub-step precision.
  private static let refinePeriodSteps = 120

  /// Sub-frame phase bins per integer period frame in the onset-comb fold (DD #2
  /// — the continuous/interpolated phase resolution that the integer-frame 8.4
  /// approach lacked).
  private static let refinePhaseOversample = 2

  /// Outcome of the continuous tempo refit: the tempo to report (seed on
  /// reject/abstain, else the refined value), the two support scores, and whether
  /// the refined value was accepted.
  private struct TempoRefitResult {
    let tempo: Double
    let supportSeed: Double
    let supportRefined: Double
    let accepted: Bool
  }

  /// Refines the grid tempo to sub-0.1-BPM precision by fitting a continuous
  /// interpolated onset-comb against the onset envelope (Story 8.10, DD #2/#4).
  ///
  /// **Not integer beat intervals.** The fitted observation is the
  /// interpolated-onset-comb SUPPORT `max_φ Σ_k onset(φ + k·period)` over a
  /// continuous period window — NEVER the integer-frame inter-beat-interval median
  /// (the reverted Story 8.4 approach, which re-quantized an already-accurate
  /// input). `frames` (the DP beat indices) are initialization ONLY: they bound
  /// the usable span; the fit derives nothing from their integer differences, and
  /// phase is a free search dimension (it is not pinned to a DP anchor, which
  /// would re-inherit the seed-phase bias that regressed Story 8.9).
  ///
  /// **Monotonic by construction.** Both the seed period and the best in-window
  /// period are scored by the SAME support objective, each at its own argmax
  /// phase; the refined tempo is accepted iff `supportRefined > supportSeed`
  /// (strict). On reject — or any abstain (too-short span, degenerate input,
  /// non-finite/≤0 refined value) — the seed's ORIGINAL `seedBPM` binding is
  /// returned (not a recomputed `60·onsetRate/period`, which would round-trip
  /// through quantization), so the rejected path is bit-pattern-identical to the
  /// unrefined grid.
  ///
  /// - Parameters:
  ///   - seedBPM: The coarse BPM-stage tempo to seed and fall back to.
  ///   - onsetEnvelope: The window-relative onset detection function (frames).
  ///   - frames: The tracked beat frames (initialization only — span bound).
  ///   - onsetRate: Onset-envelope sample rate in Hz (`sampleRate / hopSize`).
  ///   - acf: Onset-envelope autocorrelation; gauges periodicity at the seed
  ///     period to set the (adaptive) window half-width.
  /// - Returns: A ``TempoRefitResult`` — `tempo` is `seedBPM` on reject/abstain.
  private static func refineTempo(
    seedBPM: Double, onsetEnvelope: [Float], frames: [Int], onsetRate: Double, acf: [Float]
  ) -> TempoRefitResult {
    func abstain(_ supportSeed: Double = 0) -> TempoRefitResult {
      TempoRefitResult(
        tempo: seedBPM, supportSeed: supportSeed, supportRefined: supportSeed, accepted: false)
    }

    let n = onsetEnvelope.count
    guard seedBPM.isFinite, seedBPM > 0, onsetRate > 0, n > 0 else { return abstain() }
    // Usable span = first..last tracked beat frame (silent head/tail already
    // trimmed upstream). `frames` is initialization only — its integer spacing is
    // never the fitted observation.
    guard let lo = frames.first, let hi = frames.last, hi > lo, hi < n else { return abstain() }

    let seedPeriod = onsetRate * 60.0 / seedBPM
    guard seedPeriod.isFinite, seedPeriod >= 1 else { return abstain() }

    // Minimum-span abstain: the lever-arm baseline a sub-0.1-BPM fit needs.
    let spanFrames = Double(hi - lo)
    guard spanFrames / seedPeriod >= Double(refineMinBeats) else { return abstain() }

    // Score the seed period first — the reject-guard floor.
    let supportSeed = combSupport(period: seedPeriod, onset: onsetEnvelope, lo: lo, hi: hi)
    guard supportSeed.isFinite, supportSeed > 0 else { return abstain() }

    // Periodicity abstain: refuse to refine a signal with no onset-comb
    // concentration at the seed period (aperiodic noise / flat-constant → the
    // best-phase mean barely exceeds the overall mean). Returns the seed.
    var meanAll: Float = 0
    onsetEnvelope.withUnsafeBufferPointer { buf in
      vDSP_meanv(buf.baseAddress! + lo, 1, &meanAll, vDSP_Length(hi - lo + 1))
    }
    let overallMean = Double(meanAll)
    guard overallMean > 0, supportSeed >= overallMean * refineMinContrast else {
      return abstain(supportSeed)
    }

    // Adaptive window half-width: narrow when the onset signal is strongly
    // periodic at the seed period, wide when weak. The cap (`refineMaxHalfWidth`)
    // is the octave safety — the window cannot reach `2·seed` / `seed/2`.
    let periodicity = Double(acfStrengthAtPeriod(acf: acf, period: seedPeriod))
    let clampedPeriodicity = min(max(periodicity, 0), 1)
    let halfWidth =
      refineMaxHalfWidth - (refineMaxHalfWidth - refineMinHalfWidth) * clampedPeriodicity

    // Period window in frames, clamped so the longest period still spans
    // >= refineMinBeats over the usable span (DD #3 envelope-length bound).
    let maxPeriodBySpan = spanFrames / Double(refineMinBeats)
    let pLo = max(1.0, seedPeriod * (1.0 - halfWidth))
    let pHi = min(seedPeriod * (1.0 + halfWidth), maxPeriodBySpan)
    guard pHi > pLo else { return abstain(supportSeed) }

    // Coarse scan across the window; keep the full support curve for a parabolic
    // vertex refine around the peak.
    let steps = refinePeriodSteps
    var supports = [Double](repeating: 0, count: steps + 1)
    let stepSize = (pHi - pLo) / Double(steps)
    var bestIdx = 0
    var bestSupport = -Double.greatestFiniteMagnitude
    for s in 0...steps {
      let p = pLo + Double(s) * stepSize
      let support = combSupport(period: p, onset: onsetEnvelope, lo: lo, hi: hi)
      supports[s] = support
      if support > bestSupport {
        bestSupport = support
        bestIdx = s
      }
    }

    var refinedPeriod = pLo + Double(bestIdx) * stepSize
    // Parabolic vertex interpolation among (best−1, best, best+1) for sub-step
    // precision. Guard the denominator against a flat objective (vertex undefined).
    if bestIdx > 0, bestIdx < steps {
      let y0 = supports[bestIdx - 1]
      let y1 = supports[bestIdx]
      let y2 = supports[bestIdx + 1]
      let denom = y0 - 2.0 * y1 + y2
      if denom != 0 {
        let delta = 0.5 * (y0 - y2) / denom
        // A well-formed peak yields |delta| <= 0.5; clamp against a degenerate
        // (non-concave) triple that would extrapolate outside the bracket.
        if delta.isFinite, abs(delta) <= 1.0 {
          refinedPeriod = (pLo + Double(bestIdx) * stepSize) + delta * stepSize
        }
      }
    }
    refinedPeriod = min(max(refinedPeriod, pLo), pHi)

    let refinedSupport = combSupport(period: refinedPeriod, onset: onsetEnvelope, lo: lo, hi: hi)
    let refinedBPM = onsetRate * 60.0 / refinedPeriod

    // Finite-positive precheck BEFORE compare/assign: a non-finite/≤0 value would
    // otherwise launder to the `0.0` "no estimate" sentinel at `BeatGrid.init`.
    guard refinedBPM.isFinite, refinedBPM > 0, refinedSupport.isFinite else {
      return abstain(supportSeed)
    }
    // Accept iff strictly better than the seed (no epsilon that admits noise).
    guard refinedSupport > supportSeed else {
      return TempoRefitResult(
        tempo: seedBPM, supportSeed: supportSeed, supportRefined: refinedSupport, accepted: false)
    }
    return TempoRefitResult(
      tempo: refinedBPM, supportSeed: supportSeed, supportRefined: refinedSupport, accepted: true)
  }

  /// Interpolated onset-comb support for a candidate beat period: the maximum,
  /// over phase, of the mean onset energy on the comb taps `φ + k·period`
  /// (Story 8.10).
  ///
  /// Implemented by folding every frame in `[lo, hi]` onto a sub-frame phase axis
  /// (linear split between the two nearest bins — the sub-frame interpolation),
  /// then taking the best phase bin's mean. Folding is the transpose of evaluating
  /// the comb tap-by-tap and yields ALL phases in one O(span) pass. Total onset
  /// energy is conserved across periods, so the peak measures how sharply the
  /// period concentrates onset energy onto a single phase — higher = better
  /// aligned. The scatter-add over phase bins has no vDSP primitive (like the DP
  /// recurrence above), so it is an explicit control-flow loop.
  private static func combSupport(period: Double, onset: [Float], lo: Int, hi: Int) -> Double {
    guard period >= 1, hi > lo, lo >= 0, hi < onset.count else { return 0 }
    let bins = max(8, Int((period * Double(refinePhaseOversample)).rounded()))
    var energy = [Double](repeating: 0, count: bins)
    var weight = [Double](repeating: 0, count: bins)
    let binsD = Double(bins)
    var i = lo
    while i <= hi {
      // Phase of frame i within the period, in [0, period); folded onto [0, bins).
      let phase = Double(i - lo).truncatingRemainder(dividingBy: period)
      let pos = phase / period * binsD
      let b0 = min(Int(pos), bins - 1)
      let frac = pos - Double(b0)
      let b1 = (b0 + 1) % bins
      let v = Double(onset[i])
      energy[b0] += v * (1.0 - frac)
      weight[b0] += (1.0 - frac)
      energy[b1] += v * frac
      weight[b1] += frac
      i += 1
    }
    var best = 0.0
    for b in 0..<bins where weight[b] > 0 {
      let mean = energy[b] / weight[b]
      if mean > best { best = mean }
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
