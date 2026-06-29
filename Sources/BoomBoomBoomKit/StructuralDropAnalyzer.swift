//
//  StructuralDropAnalyzer.swift
//  BoomBoomBoomKit
//
//  Internal drop-anchored downbeat-phase estimator (Story 8.11). The track's main
//  structural energy DROP — which in dance music lands on a downbeat (Zehren &
//  Alunno, "Automatic Detection of Cue Points for DJ Mixing", Rule 1) — anchors
//  the bar phase. Sources its energy contour from the FULL pre-trim signal (so the
//  drop is interior, not at frame 0 where the analysis window already begins),
//  detects it with a novelty step detector (difference-of-boxcar-means, after
//  Foote 2000's audio-novelty boundary mechanism — a cheap 1-D novelty, no
//  self-similarity matrix), and maps it to the nearest tracked beat's
//  position-quantized bar phase.
//
//  This is a constraint-compatible v1 (pure Swift + Accelerate, no ML, no external
//  dependency), deliberately abstain-heavy: a wrong downbeat on a live deck is
//  worse than none (the same posture as the Story-8.5a metrical-accent estimator).
//  The principled non-ML upgrade — Serrà-style structure features / timbral-SSM
//  novelty (Paulus, Müller & Klapuri 2010) — is the named, un-built v2.
//
//  aubio fence (KDD-C1): clean-room; imports stay Foundation + Accelerate. The
//  structural-drop literature (Yadati et al. 2014, "Detecting Drops in Electronic
//  Dance Music"; Foote 2000; Vande Veire & De Bie 2018 for the DnB cautionary on
//  low-band-only localization) is cited, not transcribed.
//

import Accelerate
import Foundation

/// Internal drop-anchored downbeat-phase estimator (Story 8.11), selected by
/// ``DownbeatStrategy/structuralDrop`` / ``DownbeatStrategy/combined``.
enum StructuralDropAnalyzer {

  // MARK: - Tuning constants

  /// Contour hop (≈ 50 ms). The whole-second window of the Story-8.4
  /// `findEnergyTransition` spans ~2 beats at 128 BPM and reports the window left
  /// edge → a systematic off-by-one phase. A 50 ms hop localizes to well under
  /// `beatPeriod / 4` across the supported tempo range (75 ms at 200 BPM), and the
  /// parabolic vertex refine recovers sub-hop precision (DD #2 step 4).
  private static let contourHopSeconds = 0.05

  /// Low-pass cutoff (Hz) for the primary low-band level contour — kick + bass.
  private static let lowPassCutoffHz = 160.0

  /// A real drop's post-window low-band level must reach at least this fraction of
  /// the track's peak low-band level. This is the load-bearing **riser rejection**:
  /// a build-up / riser is rising high-frequency flux with the **bass absent**, so
  /// its post-window low level stays below the floor and it never fires as a drop
  /// (DD #2 step 2; the #1 literature false-positive — Yadati's two-stage design
  /// exists precisely to reject these).
  private static let riserLowFloorFraction: Float = 0.35

  /// A candidate whose high-band RMS step exceeds this multiple of its low-band
  /// step is a high-band-dominated event (a build-up / sweep / riser), not a bass
  /// drop → reject. Commensurate (both are RMS-level steps); loudness-independent
  /// (it is a ratio of the two bands' steps, not an absolute level). The factor
  /// leaves margin so a true bass drop with bright cymbals still passes.
  private static let riserHighDominanceFactor: Float = 2.5

  /// The dominant novelty step must exceed this fraction of the peak low-band
  /// level to count as a real rising edge (else: no drop → abstain).
  private static let contrastFloorFraction: Float = 0.10

  /// A second drop candidate at a DIFFERENT bar phase with novelty ≥ this fraction
  /// of the dominant one is "comparable" → a which-drop ambiguity. When that other
  /// phase is the half-bar (`(P + 2) % 4`) it is the documented beat-1-vs-beat-3
  /// ambiguity (resolvable by metrical accent under `.combined`); at any other
  /// phase it is an unresolvable double-drop tie → abstain (DD #2 steps 5/7).
  private static let comparableRunnerUpFraction: Float = 0.8

  /// A drop closer than this fraction of `beatPeriod` to its nearest beat snaps to
  /// that beat; farther (up to `beatPeriod / 2`) is **half-beat ambiguous** →
  /// abstain (it sits ~midway between two beats). Beyond the beat span by more than
  /// `beatPeriod / 2` is **off-grid** → abstain (DD #2 step 7).
  private static let halfBeatSnapFraction = 0.35

  /// Under `.combined`, a lone ``DownbeatStrategy/structuralDrop`` fire (metrical
  /// accent abstained) is admitted only if its confidence clears this strict bar.
  /// Set high so lone drops abstain by default — blanket single-source admission
  /// is gated behind the Story-8.11 AC #7 measurement (DD #3). Until then the
  /// conservative-proven lone-metrical fire is the admitted single source.
  private static let strictSingleSourceConfidence: Float = 0.95

  /// Floor on detected confidence so a `.detected` outcome is never reported below
  /// a usable value.
  private static let minReportableConfidence: Float = 0.1

  /// Grid-integrity (parity with ``DownbeatAnalyzer``): an inter-beat interval
  /// deviating from the beat period by more than this fraction is "off-grid".
  private static let gridDeviationTolerance = 0.25

  /// Grid-integrity: if more than this fraction of inter-beat intervals are
  /// off-grid the DP shredded the grid → abstain rather than fold a phase from it.
  private static let gridOffGridFractionLimit = 0.20

  // MARK: - Energy contour

  /// Multi-descriptor energy contour over the FULL pre-trim signal (file `t = 0`).
  /// All three arrays share `rate` (frames per second) and length.
  struct Contour: Sendable {
    /// Primary signal: low-pass (~160 Hz) RMS **level** per hop — a sustained drop
    /// is a level step, not an onset-flux spike (DD #2 step 1).
    let lowBand: [Float]
    /// Full-mix RMS per hop (broadband corroboration — the whole mix entering).
    let broadband: [Float]
    /// High-band (≈ full − low) RMS level per hop. The riser discriminator: a
    /// build-up / sweep raises the high band far more than the low band, so a
    /// candidate whose high-band step dominates its low-band step is a riser, not a
    /// bass drop (DD #2 step 2 — a *level*-step comparison in commensurate units).
    let highBand: [Float]
    /// Frames per second of every contour array.
    let rate: Double
  }

  /// Computes the multi-descriptor energy contour over the full pre-trim mono
  /// samples (DD #2 step 1; the ``LUFSAnalyzer`` `vDSP.Biquad` pattern, but
  /// `ofType: Float.self` — a gentle low-pass far from the unit circle, so Float is
  /// fine here, unlike K-weighting's near-pole shelves). Returns `nil` for
  /// degenerate input (too few hops to detect a step against).
  ///
  /// - Parameters:
  ///   - samples: The full pre-trim mono PCM (NOT the drop-anchored analysis
  ///     window — the window already begins at the drop, which would put it at
  ///     frame 0, undetectable).
  ///   - sampleRate: Sample rate in Hz.
  static func computeContour(samples: [Float], sampleRate: Double) -> Contour? {
    // `sampleRate` is bounded in production (DecodedAudio's >= 8 kHz precondition), but
    // guard finiteness + a sane ceiling so `Int(sampleRate * contourHopSeconds)` can never
    // trap — the analyzers-never-crash contract (the `estimateBeatGrid` rate-bound precedent).
    guard sampleRate.isFinite, sampleRate > 0, sampleRate <= 1_000_000_000, samples.count > 0
    else { return nil }
    let hop = max(1, Int(sampleRate * contourHopSeconds))
    let frames = samples.count / hop
    // Need enough hops to define a leading/trailing novelty window against.
    guard frames >= 8 else { return nil }

    // Low-pass (Butterworth, Q = 1/√2) → low-band level contour.
    guard let coeffs = lowPassCoefficients(cutoff: lowPassCutoffHz, sampleRate: sampleRate),
      var biquad = vDSP.Biquad(
        coefficients: coeffs, channelCount: 1, sectionCount: 1, ofType: Float.self)
    else { return nil }
    let lowFiltered: [Float] = biquad.apply(input: samples)
    guard lowFiltered.count == samples.count else { return nil }

    // High band ≈ full − low (crude high-pass), for the rising-high flux.
    var highBand = [Float](repeating: 0, count: samples.count)
    // vDSP_vsub computes C = A − B with the argument order (B, A, C).
    vDSP_vsub(lowFiltered, 1, samples, 1, &highBand, 1, vDSP_Length(samples.count))

    // Per-hop RMS levels for the low band, the full mix, and the high band — three
    // commensurate *level* contours (no flux / first-difference). The riser
    // discriminator compares the high-band step to the low-band step downstream.
    var lowContour = [Float](repeating: 0, count: frames)
    var broadContour = [Float](repeating: 0, count: frames)
    var highContour = [Float](repeating: 0, count: frames)
    samples.withUnsafeBufferPointer { sp in
      lowFiltered.withUnsafeBufferPointer { lp in
        highBand.withUnsafeBufferPointer { hp in
          for i in 0..<frames {
            let start = i * hop
            var v: Float = 0
            vDSP_rmsqv(lp.baseAddress! + start, 1, &v, vDSP_Length(hop))
            lowContour[i] = v
            vDSP_rmsqv(sp.baseAddress! + start, 1, &v, vDSP_Length(hop))
            broadContour[i] = v
            vDSP_rmsqv(hp.baseAddress! + start, 1, &v, vDSP_Length(hop))
            highContour[i] = v
          }
        }
      }
    }

    return Contour(
      lowBand: lowContour, broadband: broadContour, highBand: highContour,
      rate: sampleRate / Double(hop))
  }

  // MARK: - Resolution

  /// The structural-drop verdict, rich enough for the `.combined` combiner to
  /// resolve the half-bar (beat-1-vs-beat-3) case via metrical accent.
  enum Resolution: Sendable, Equatable {
    /// A single dominant drop placed the bar phase unambiguously.
    case confident(phaseIndex: Int, dropTimeSeconds: Double, confidence: Float)
    /// The drop is confident only at the 2-beat (half-bar) level: the true
    /// downbeat is `phaseA` or its half-bar partner `phaseB = (phaseA + 2) % 4`.
    /// Standalone → abstain; `.combined` lets metrical accent break the tie.
    case halfBarAmbiguous(phaseA: Int, phaseB: Int, dropTimeSeconds: Double, confidence: Float)
    /// No usable drop (no rising edge, off-grid, half-beat ambiguous, riser, an
    /// unresolvable multi-drop tie, too few bars, or a degenerate window-start).
    case none
  }

  // MARK: - Standalone strategy (`.structuralDrop`)

  /// Runs the structural-drop estimator standalone. The half-bar-ambiguous case
  /// abstains (an off-by-2 octave-tolerant scoring would NOT catch); `.combined`
  /// is the path that resolves it.
  static func estimate(
    contour: Contour,
    beats: [BeatTimestamp],
    estimatedTempo: Double,
    beatsPerBar: Int = 4
  ) -> DownbeatAnalyzer.Outcome {
    let resolution = resolve(
      contour: contour, beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar)
    return outcome(
      from: resolution, beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar)
  }

  /// Maps a standalone ``Resolution`` to a ``DownbeatAnalyzer/Outcome`` (half-bar
  /// ambiguity → abstain). Exposed so the strategy dispatch can reuse a single
  /// ``resolve(contour:beats:estimatedTempo:beatsPerBar:)`` pass for both the
  /// outcome and the diagnostic evidence.
  static func outcome(
    from resolution: Resolution,
    beats: [BeatTimestamp],
    estimatedTempo: Double,
    beatsPerBar: Int = 4
  ) -> DownbeatAnalyzer.Outcome {
    switch resolution {
    case .confident(let phase, _, let confidence):
      return detectedOutcome(
        beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar,
        phaseIndex: phase, confidence: confidence)
    case .halfBarAmbiguous, .none:
      return .noneDetected
    }
  }

  // MARK: - Combined strategy (`.combined`)

  /// Cross-validates the metrical-accent outcome against the structural-drop
  /// resolution (DD #3). Invariants: two strong sources that DISAGREE never emit a
  /// downbeat (conflict → abstain); agreement is confidence-boosted. Single-source
  /// admission defaults to agreement-priority — a lone metrical fire is admitted
  /// (the conservative-proven path), a lone structural-drop fire abstains unless it
  /// clears the strict in-estimator bar.
  static func combine(
    metrical: DownbeatAnalyzer.Outcome,
    drop: Resolution,
    beats: [BeatTimestamp],
    estimatedTempo: Double,
    beatsPerBar: Int = 4
  ) -> DownbeatAnalyzer.Outcome {
    let metricalPhase: Int?
    let metricalConfidence: Float
    if case .detected(let estimate, _) = metrical {
      metricalPhase = estimate.phaseIndex
      metricalConfidence = estimate.confidence
    } else {
      metricalPhase = nil
      metricalConfidence = 0
    }

    switch drop {
    case .confident(let dropPhase, _, let dropConfidence):
      guard let mPhase = metricalPhase else {
        // Lone structural-drop: admit only past the strict bar (DD #3).
        guard dropConfidence >= strictSingleSourceConfidence else { return .noneDetected }
        return detectedOutcome(
          beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar,
          phaseIndex: dropPhase, confidence: dropConfidence)
      }
      // Both fire: agree → boost. Disagree → KEEP the conservative-proven
      // metrical estimate (do NOT let a possibly-wrong drop veto a standalone-valid
      // 8.5a fire). The drop is the corroborator, not an authority that can abstain
      // the metrical source. This keeps `.combined` ≥ `.metricalAccent` by
      // construction on a disagreement (issue #61).
      guard mPhase == dropPhase else { return metrical }
      return detectedOutcome(
        beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar,
        phaseIndex: dropPhase, confidence: boosted(metricalConfidence, dropConfidence))

    case .halfBarAmbiguous(let phaseA, let phaseB, _, let dropConfidence):
      // The drop nails the bar grid; metrical accent resolves the 1-vs-3 phase.
      guard let mPhase = metricalPhase, mPhase == phaseA || mPhase == phaseB else {
        return .noneDetected
      }
      return detectedOutcome(
        beats: beats, estimatedTempo: estimatedTempo, beatsPerBar: beatsPerBar,
        phaseIndex: mPhase, confidence: boosted(metricalConfidence, dropConfidence))

    case .none:
      // Lone metrical fire is admitted verbatim (preserves the 8.5a estimate);
      // neither fires → abstain.
      return metrical
    }
  }

  // MARK: - Core resolution

  static func resolve(
    contour: Contour,
    beats: [BeatTimestamp],
    estimatedTempo: Double,
    beatsPerBar: Int = 4
  ) -> Resolution {
    // --- Structural / input guards (mirror the 8.5a estimator's posture) ------
    // Story 8.11 is a 4/4-only estimator: the half-bar (beat-1-vs-beat-3)
    // resolution and `halfBarPartner` are defined only for 4/4. Any other meter
    // would half-handle incoherently (beatsPerBar/2 truncates for odd meters), so
    // abstain rather than emit a misleading phase (issue #63). A future
    // meter-detection story that lifts this must generalize the half-bar logic,
    // not just relax the guard.
    guard beatsPerBar == 4 else { return .none }
    guard beats.count / beatsPerBar >= 3 else { return .none }  // ≥ 3 complete bars
    guard estimatedTempo.isFinite, estimatedTempo > 0 else { return .none }
    guard beats.allSatisfy({ $0.presentationTime.isFinite }) else { return .none }
    let low = contour.lowBand
    let m = low.count
    guard m > 0, contour.rate.isFinite, contour.rate > 0 else { return .none }
    guard contour.broadband.count == m, contour.highBand.count == m else { return .none }

    let beatPeriod = 60.0 / estimatedTempo  // seconds

    // Grid-integrity (parity with DownbeatAnalyzer's AC3.3 gate): refuse to fold a phase
    // from a shredded beat array (too many off-period intervals). A single dropped/doubled
    // beat is one off-grid interval — well under the limit on a multi-bar window — so
    // position-quantized folding still handles that; this fires only on a shredded grid.
    let intervalCount = beats.count - 1
    if intervalCount > 0 {
      var offGrid = 0
      for i in 1..<beats.count {
        let dt = beats[i].presentationTime - beats[i - 1].presentationTime
        if abs(dt - beatPeriod) / beatPeriod > gridDeviationTolerance { offGrid += 1 }
      }
      if Double(offGrid) > gridOffGridFractionLimit * Double(intervalCount) { return .none }
    }

    let beatFrames = beatPeriod * contour.rate
    // Bound before the `Int(...)` casts below so an absurd (sub-denormal-tempo) beatFrames
    // abstains instead of trapping (analyzers-never-crash contract).
    guard beatFrames.isFinite, beatFrames >= 1, beatFrames <= 1e15 else { return .none }

    // Novelty window: 1 beat leading vs trailing — wide enough to ignore a single
    // transient, narrow enough to separate two drops a half-bar (2 beats) apart
    // (the half-bar / double-drop case). A SEPARATE 2-beat `sustain` window gates
    // the post-drop level (riser rejection + sustained-contrast).
    let window = max(1, Int(beatFrames.rounded()))
    let sustain = max(window, Int((beatFrames * 2).rounded()))
    guard m > 2 * window + 2 else { return .none }

    // Peak low-band level → contrast/riser denominators.
    var lowMax: Float = 0
    vDSP_maxv(low, 1, &lowMax, vDSP_Length(m))
    guard lowMax > 0 else { return .none }

    // --- Novelty curve: mean(post) − mean(pre) over the low-band level ---------
    // Positive at a sustained RISING edge = a drop (energy slams in). Defined for
    // i in [window, m − window).
    var novelty = [Float](repeating: 0, count: m)
    low.withUnsafeBufferPointer { lp in
      for i in window..<(m - window) {
        var pre: Float = 0
        var post: Float = 0
        vDSP_meanv(lp.baseAddress! + (i - window), 1, &pre, vDSP_Length(window))
        vDSP_meanv(lp.baseAddress! + i, 1, &post, vDSP_Length(window))
        novelty[i] = post - pre
      }
    }

    // Local maxima of the novelty curve (positive rising edges), strongest first.
    var peaks: [(frame: Int, value: Float)] = []
    for i in (window + 1)..<(m - window - 1) {
      let v = novelty[i]
      if v > 0, v >= novelty[i - 1], v > novelty[i + 1] { peaks.append((i, v)) }
    }
    guard !peaks.isEmpty else { return .none }
    peaks.sort { $0.value > $1.value }

    // --- Candidate validation: a peak is a usable drop only if it clears the riser /
    // floor / on-grid guards. Factored out so the search FALLS THROUGH a rejected riser
    // to the next-ranked real drop (the build-up→drop pattern) instead of abstaining on
    // `peaks[0]` alone, and so the runner-up scan treats only VALIDATED drops as competing
    // (a rejected riser at another phase is not a conflict — DD #2 step 2).
    struct ValidatedCandidate {
      let frame: Int
      let value: Float
      let phase: Int
      let dropTime: Double
    }
    func validate(_ peak: (frame: Int, value: Float)) -> ValidatedCandidate? {
      // Riser rejection: post-drop low-band level over the 2-beat sustain window (clamped
      // to the available tail) must reach the floor (bass present). A build-up/riser (bass
      // absent) fails this even if it nudged the novelty curve.
      let postLen = min(sustain, m - peak.frame)
      guard postLen >= 1 else { return nil }
      var lowPost: Float = 0
      low.withUnsafeBufferPointer {
        vDSP_meanv($0.baseAddress! + peak.frame, 1, &lowPost, vDSP_Length(postLen))
      }
      guard lowPost >= riserLowFloorFraction * lowMax else { return nil }
      // Multi-descriptor rejection: the full mix must not fall, and a high-band step that
      // dominates the low-band step (commensurate windows) is a build-up / sweep / riser,
      // not a bass drop. Guarded on `lowStep > 0` so a non-rising low band does not feed a
      // degenerate ratio (the contrast + post-floor gates already cover that).
      let preStart = max(0, peak.frame - window)
      let preLen = peak.frame - preStart
      let broadStep =
        meanRange(contour.broadband, from: peak.frame, count: postLen)
        - meanRange(contour.broadband, from: preStart, count: preLen)
      guard broadStep >= 0 else { return nil }
      let lowStep =
        meanRange(contour.lowBand, from: peak.frame, count: postLen)
        - meanRange(contour.lowBand, from: preStart, count: preLen)
      let highStep =
        meanRange(contour.highBand, from: peak.frame, count: postLen)
        - meanRange(contour.highBand, from: preStart, count: preLen)
      if lowStep > 0, highStep > riserHighDominanceFactor * lowStep { return nil }
      // Sub-hop-refined drop time → nearest tracked beat's bar phase (nil = off-grid /
      // half-beat ambiguous).
      let dropTime = parabolicRefine(novelty, around: peak.frame) / contour.rate
      guard
        let phase = phaseAt(
          dropTime, beats: beats, beatPeriod: beatPeriod, beatsPerBar: beatsPerBar)
      else { return nil }
      return ValidatedCandidate(
        frame: peak.frame, value: peak.value, phase: phase, dropTime: dropTime)
    }

    // Candidates above the absolute contrast floor (sorted desc ⇒ a contiguous top run; a
    // peak below the floor can never be a drop). Validate each exactly once.
    let candidates = Array(peaks.prefix { $0.value >= contrastFloorFraction * lowMax })
    guard !candidates.isEmpty else { return .none }
    let validated = candidates.map(validate)

    // First VALID candidate (falling through rejected risers) is the dominant drop.
    guard let domIndex = validated.firstIndex(where: { $0 != nil }),
      let dominant = validated[domIndex]
    else { return .none }
    let nMax = dominant.value

    // --- Runner-up scan: every comparable VALIDATED drop at a DIFFERENT bar phase ----
    // Conservative ("a wrong downbeat is worse than none"): ANY comparable valid drop at an
    // unrelated phase makes the bar phase unresolvable → `.none`; a half-bar partner alone →
    // `.halfBarAmbiguous` (which `.combined` resolves via metrical accent). A same-phase
    // valid drop is corroboration. Rejected risers (nil) and off-grid peaks are NOT
    // competing drops, so a riser ranked above the dominant does not force an abstain.
    let halfBarPartner = beatsPerBar >= 4 ? (dominant.phase + beatsPerBar / 2) % beatsPerBar : -1
    var conflictRunnerUp: Float = 0  // strongest DIFFERENT-phase valid drop (0 ⇒ a clean win)
    var sawHalfBarConflict = false
    for (i, candidate) in validated.enumerated() {
      guard i != domIndex, let cand = candidate else { continue }  // skip dominant + risers
      guard cand.value >= comparableRunnerUpFraction * nMax else { continue }  // not comparable
      if cand.phase == dominant.phase { continue }  // same phase: corroboration
      conflictRunnerUp = max(conflictRunnerUp, cand.value)
      if cand.phase == halfBarPartner {
        sawHalfBarConflict = true  // keep scanning — an unrelated conflict still wins
      } else {
        return .none  // a comparable drop at an unrelated phase: unresolvable tie
      }
    }

    let confidence = dropConfidence(nMax: nMax, runnerUp: conflictRunnerUp, lowMax: lowMax)
    if sawHalfBarConflict {
      return .halfBarAmbiguous(
        phaseA: dominant.phase, phaseB: halfBarPartner, dropTimeSeconds: dominant.dropTime,
        confidence: confidence)
    }
    return .confident(
      phaseIndex: dominant.phase, dropTimeSeconds: dominant.dropTime, confidence: confidence)
  }

  // MARK: - Helpers

  /// Position-quantized bar phase of a drop at `dropTime`, snapped to the nearest
  /// tracked beat (8.5a formula). Returns `nil` when the drop is off-grid (beyond
  /// the beat span by > `beatPeriod / 2`) or half-beat ambiguous (~midway between
  /// two beats).
  private static func phaseAt(
    _ dropTime: Double, beats: [BeatTimestamp], beatPeriod: Double, beatsPerBar: Int
  ) -> Int? {
    guard let first = beats.first?.presentationTime, let last = beats.last?.presentationTime
    else { return nil }
    // Off-grid: outside the beat span by more than half a beat.
    guard dropTime >= first - beatPeriod / 2, dropTime <= last + beatPeriod / 2 else { return nil }

    var nearest = 0
    var nearestDist = Double.greatestFiniteMagnitude
    for (i, beat) in beats.enumerated() {
      let d = abs(beat.presentationTime - dropTime)
      if d < nearestDist {
        nearestDist = d
        nearest = i
      }
    }
    // Half-beat ambiguous: ~midway between two beats (no clean snap).
    guard nearestDist <= halfBeatSnapFraction * beatPeriod else { return nil }

    let firstTime = beats[0].presentationTime
    let raw = Int(((beats[nearest].presentationTime - firstTime) / beatPeriod).rounded())
    return ((raw % beatsPerBar) + beatsPerBar) % beatsPerBar
  }

  /// Builds a `.detected` outcome at `phaseIndex` by folding every beat onto its
  /// position-quantized bar phase (8.5a `DownbeatAnalyzer.swift:194-200`) and
  /// collecting the phase's beats. Abstains if the phase carries no beat.
  private static func detectedOutcome(
    beats: [BeatTimestamp], estimatedTempo: Double, beatsPerBar: Int,
    phaseIndex: Int, confidence: Float
  ) -> DownbeatAnalyzer.Outcome {
    guard estimatedTempo.isFinite, estimatedTempo > 0, !beats.isEmpty else { return .noneDetected }
    let beatPeriod = 60.0 / estimatedTempo
    let firstTime = beats[0].presentationTime
    var downbeatBeats: [BeatTimestamp] = []
    var firstIdx = -1
    for (i, beat) in beats.enumerated() {
      let raw = Int(((beat.presentationTime - firstTime) / beatPeriod).rounded())
      let phase = ((raw % beatsPerBar) + beatsPerBar) % beatsPerBar
      if phase == phaseIndex {
        if firstIdx < 0 { firstIdx = i }
        downbeatBeats.append(beat)
      }
    }
    guard firstIdx >= 0, !downbeatBeats.isEmpty else { return .noneDetected }
    let estimate = DownbeatEstimate(
      beats: downbeatBeats,
      meter: MeterEstimate(beatsPerBar: beatsPerBar, source: .assumed),
      confidence: max(minReportableConfidence, confidence),
      phaseIndex: phaseIndex)
    return .detected(estimate: estimate, firstDownbeatBeatIndex: firstIdx)
  }

  /// Confidence in `[0, 1]` from the dominant novelty's margin over a runner-up and
  /// the step's contrast against the peak level. A coarse drop (small step, no
  /// margin) scores moderate — below the strict single-source bar by design.
  private static func dropConfidence(nMax: Float, runnerUp: Float, lowMax: Float) -> Float {
    let margin = nMax > 0 ? Double((nMax - runnerUp) / nMax) : 0
    let contrast = lowMax > 0 ? Double(nMax / lowMax) : 0
    let contrastTerm = clamp01((contrast - 0.1) / 0.4)
    return Float(clamp01(0.5 * margin + 0.5 * contrastTerm))
  }

  /// Boosted confidence when two independent sources agree.
  private static func boosted(_ a: Float, _ b: Float) -> Float {
    Float(clamp01(0.5 * (Double(a) + Double(b)) + 0.15))
  }

  /// Parabolic 3-point vertex around `i` for sub-frame precision (guarded against a
  /// non-concave / flat triple), returning a fractional frame index. Mirrors the
  /// `BeatGridAnalyzer` refinement precedent (`:679-692`).
  private static func parabolicRefine(_ curve: [Float], around i: Int) -> Double {
    guard i > 0, i < curve.count - 1 else { return Double(i) }
    let y0 = Double(curve[i - 1])
    let y1 = Double(curve[i])
    let y2 = Double(curve[i + 1])
    let denom = y0 - 2 * y1 + y2
    guard denom != 0 else { return Double(i) }
    let delta = 0.5 * (y0 - y2) / denom
    guard delta.isFinite, abs(delta) <= 1.0 else { return Double(i) }
    return Double(i) + delta
  }

  private static func clamp01(_ x: Double) -> Double {
    guard x.isFinite else { return 0 }
    return min(max(x, 0), 1)
  }

  /// Mean of `a[start ..< start + count]` via vDSP; `0` for an out-of-bounds or
  /// empty range.
  private static func meanRange(_ a: [Float], from start: Int, count: Int) -> Float {
    guard start >= 0, count > 0, start + count <= a.count else { return 0 }
    var v: Float = 0
    a.withUnsafeBufferPointer { vDSP_meanv($0.baseAddress! + start, 1, &v, vDSP_Length(count)) }
    return v
  }

  /// RBJ Butterworth (Q = 1/√2) low-pass biquad, a0-normalized to the
  /// `[b0, b1, b2, a1, a2]` order `vDSP.Biquad` consumes. Returns `nil` for a
  /// degenerate cutoff/rate.
  private static func lowPassCoefficients(cutoff: Double, sampleRate: Double) -> [Double]? {
    guard cutoff > 0, sampleRate > 0, cutoff < sampleRate / 2 else { return nil }
    let omega = 2 * Double.pi * cutoff / sampleRate
    let cosw = cos(omega)
    let sinw = sin(omega)
    let alpha = sinw / (2 * (1 / 2.0.squareRoot()))  // Q = 1/√2
    let a0 = 1 + alpha
    guard a0 != 0 else { return nil }
    let b0 = (1 - cosw) / 2
    let b1 = 1 - cosw
    let b2 = (1 - cosw) / 2
    let a1 = -2 * cosw
    let a2 = 1 - alpha
    return [b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0]
  }
}
