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
  /// Beat grid from the optional step-11 fan-out (Story 8.4). `nil` on the
  /// default path (`Options.computeBeatGrid == false`) — keeping it `nil`
  /// (and never entering the fan-out branch) is what makes the default-path
  /// output byte-identical to the pre-8.4 pipeline.
  let beatGrid: BeatGrid?

  /// Memberwise initializer with `beatGrid` defaulted to `nil`. Written
  /// explicitly (rather than relying on synthesis) so the ~40 existing
  /// four-argument `BPMResult(bpm:confidence:candidates:trace:)` call sites keep
  /// compiling unchanged while step 11 can supply a grid.
  init(
    bpm: Double,
    confidence: Double,
    candidates: [(bpm: Double, score: Float)],
    trace: BPMDiagnosticTrace?,
    beatGrid: BeatGrid? = nil
  ) {
    self.bpm = bpm
    self.confidence = confidence
    self.candidates = candidates
    self.trace = trace
    self.beatGrid = beatGrid
  }
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

  // MARK: - Duration-Derived BPM Hint Constants (Story 3-4)

  /// Bar counts probed by the duration-derived BPM hint at step 9.7.
  ///
  /// For a file of duration `D`, each bar count `B` yields a structurally plausible BPM
  /// of `B * 4 * 60 / D`. Only those falling within `perceptualMinBPM ... perceptualMaxBPM`
  /// participate in the boost.
  ///
  /// Source: brainstorming-session-2026-03-21-2345.md (#35 — Splice.com duration heuristic);
  /// Story 3.4 epic AC (epics.md:586-612).
  private static let durationHintBarCounts: [Int] = [32, 64, 96, 128, 192, 256]

  /// Multiplicative boost applied to DSP candidates whose BPM lies within the relative
  /// tolerance of any in-range bar-count-derived BPM (corroborative-not-authoritative —
  /// never damps unmatched candidates).
  private static let durationHintBoostWeight: Float = 0.1

  /// Relative tolerance for matching a DSP candidate to a bar-count-derived BPM.
  /// Match condition: `abs(cand.bpm - barBPM) / barBPM <= durationHintTolerance`.
  /// 2% mirrors the shared accuracy matcher in BoomBoomBoomKitTestSupport/AccuracyMatchers.swift.
  private static let durationHintTolerance: Double = 0.02

  /// Default minimum file duration (seconds) below which the duration-derived BPM hint
  /// is suppressed.
  ///
  /// Bar-count math assumes the file IS a full song — `B * 4 * 60 / D` is only musically
  /// meaningful when `D` is the song's true duration, not a clip. Short clips (loops,
  /// previews, partial tracks like the GiantSteps Tempo Dataset's 30-120s segments)
  /// produce structurally-implausible bar candidates that often reinforce octave errors.
  ///
  /// The 180-second default reflects "very few dance songs are shorter than 3 minutes"
  /// and was added in response to a measured AC #4 GiantSteps regression at the
  /// pre-threshold values. Configurable per call via
  /// `AudioAnalysisService.Options.durationHintMinFileSeconds`.
  private static let durationHintMinFileSecondsDefault: Double = 180.0

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
    /// When `nil` (default), the technique set is derived from `intensity`.
    var techniqueSet: TechniqueSet?

    /// When `true`, populates `BPMResult.trace` with per-step diagnostic data.
    var enableTrace: Bool = false

    /// Full file duration in seconds, used by the duration-derived BPM hint at step 9.7.
    /// When nil (default), no hint is applied. `AudioAnalysisService` passes the value
    /// from `PCMBufferReader.fileDuration(url:)` when `AudioAnalysisService.Options.durationHint`
    /// is true.
    var fileDurationSeconds: Double?

    /// Below this duration (seconds), the duration-derived BPM hint is suppressed.
    /// Bar-count math assumes the file IS a full song; below the threshold the file
    /// is more likely a clip/loop where `bars * 4 * 60 / D` is structurally implausible.
    /// Default 180s (3 min) — see `durationHintMinFileSecondsDefault`.
    var durationHintMinFileSeconds: Double = durationHintMinFileSecondsDefault

    /// Story 4-5 / DD #4 — when `true`, the mel-spectrogram onset pipeline retains
    /// per-frame log-mel frames into an ``MLFeatureFrames`` value and surfaces them
    /// on the result's ``BPMDiagnosticTrace/mlFeatures`` field. INTERNAL ONLY —
    /// not exposed on `AudioAnalysisService.Options`. The service sets it from
    /// `shouldBuildTrace && options.mlTechnique != nil && options.ensemblePolicy != .dspOnly`.
    /// Default `false` keeps the DSP-only path zero-cost: when the flag is off
    /// the spectrogram intermediate stays purely transient (the heavy `[Float]`
    /// payload is NEVER allocated).
    var captureMLFeatures: Bool = false

    /// Story 8.4 — when `true`, the pipeline fans out to
    /// ``BeatGridAnalyzer/estimateBeatGrid(onsetEnvelope:onsetRate:hopSize:sampleRate:acf:tempoBPM:windowStartSample:)``
    /// after step 10c (the optional step-11 beat-grid extraction) and surfaces the
    /// result on ``BPMResult/beatGrid``. Default `false` keeps the DSP path
    /// byte-identical: the fan-out branch is not entered, no beat-grid buffer is
    /// allocated, and `BPMResult.beatGrid` stays `nil`. Beat grid is a PARALLEL
    /// step-11 output — it does not feed BPM winner selection, so no
    /// ``BPMDiagnosticTrace`` field is added and KDD-T0 does not trigger.
    var computeBeatGrid: Bool = false

    /// Story 8.5a — when `true` AND `computeBeatGrid` is `true`, the step-11
    /// fan-out forces sub-band onset computation and runs the downbeat-phase
    /// estimator, populating ``BeatGrid/downbeats`` with
    /// ``DownbeatResult/detected(estimate:)`` or ``DownbeatResult/noneDetected``.
    /// Default `false` keeps ``BeatGrid/downbeats`` ``DownbeatResult/notAttempted``.
    /// Forcing sub-bands is additive: they feed only the downbeat estimator (and
    /// sub-band voting iff `.subBandVoting` is independently on), never the
    /// full-band envelope or the BPM winner — the BPM result stays byte-identical.
    var detectDownbeats: Bool = false
  }

  // MARK: - Public API

  /// Estimates the tempo (BPM) of decoded audio using multi-estimator fusion.
  ///
  /// Pipeline: energy scan → mel onset → autocorrelation + Fourier tempogram →
  /// periodicity fusion → TPS2 enhancement → peak extraction → range normalization →
  /// octave disambiguation → confidence.
  ///
  /// The single entry point since Story 8-2 (DD #4 — the
  /// `samples:sampleRate:` forms are removed, no shim). `decoded` is a pure
  /// carrier: the pipeline reads only `samples` and `sampleRate`; provenance
  /// fields (`codecPriming`) never influence output (locked by the
  /// provenance-invariance test in `SharedDecodeTests`).
  ///
  /// - Parameters:
  ///   - decoded: Decoded mono PCM carrier (up to 120s for energy scan).
  ///   - options: Configuration controlling analysis window, intensity, technique set, and tracing.
  /// - Returns: A `BPMResult` with BPM and confidence, or `nil` for
  ///   silence/noise/too-short input.
  static func estimateBPM(
    decoded: FeatureSubstrate.DecodedAudio,
    options: Options = .init()
  ) -> BPMResult? {
    let samples = decoded.samples
    let sampleRate = decoded.sampleRate
    let techniqueSet = options.techniqueSet ?? options.intensity.techniqueSet
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

    // Step 3: Mel-spectrogram onset detection with sub-band envelopes.
    // Story 4-7 gate: `.superFluxOnset` swaps the baseline log-mel spectral flux
    // for Böck & Widmer 2013 SuperFlux (frequency-axis max-filter reference frame,
    // r=1). Same step number (3), same downstream contract (`OnsetEnvelopes`),
    // same callers — only the per-frame reference construction differs. See
    // `computeSuperFluxOnsetEnvelope` and Story 4-7 DD #2 / AC #2.
    // Story 8.5a AC6: force sub-band onset computation when the step-11 fan-out
    // will run the downbeat estimator, independent of the technique set. This is
    // additive — `normalizeSubBandsInPlace` only touches the sub-band arrays, and
    // sub-band ACFs / voting stay gated on `.subBandVoting`, so the full-band
    // envelope and the BPM winner are unchanged (BPM byte-identity, AC2/AC8 d′).
    let forceSubBands = options.computeBeatGrid && options.detectDownbeats
    let onsetResult: OnsetEnvelopes
    if techniqueSet.contains(.superFluxOnset) {
      onsetResult = computeSuperFluxOnsetEnvelope(
        samples: analysisWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: techniqueSet.contains(.subBandVoting) || forceSubBands,
        normalizeSubBands: techniqueSet.contains(.subBandNormalization),
        captureMLFeatures: options.captureMLFeatures)
    } else {
      onsetResult = computeMelOnsetEnvelopeWithSubBands(
        samples: analysisWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: techniqueSet.contains(.subBandVoting) || forceSubBands,
        normalizeSubBands: techniqueSet.contains(.subBandNormalization),
        captureMLFeatures: options.captureMLFeatures)
    }
    var onsetEnvelope = onsetResult.fullBand
    guard !onsetEnvelope.isEmpty else { return nil }

    trace?.onsetEnvelopeLength = onsetEnvelope.count
    // Story 4-5: surface the retained log-mel matrix to `MLTechnique.evaluate`
    // via the trace. Nil-passthrough is the contract when `captureMLFeatures`
    // is off, which is the default DSP-only path.
    if let mlFeatures = onsetResult.mlFeatures {
      trace?.mlFeatures = mlFeatures
    }
    if options.enableTrace {
      // Story 4-3b: typed `SubBandEnergies` replaces the prior
      // `[String: Float]` keyed by `["kick", "snare", "crack", "hihat"]`.
      // The 4-iteration loop becomes 4 conditional field writes; the band
      // index → field mapping is intentionally explicit (not a closed-key
      // dict lookup) so the migration eliminates the string-hashing cost
      // and the closed-set anti-pattern in one step.
      var kick: Float = 0
      var snare: Float = 0
      var crack: Float = 0
      var hihat: Float = 0
      for (i, band) in onsetResult.subBands.enumerated() where !band.isEmpty {
        var maxVal: Float = 0
        vDSP_maxv(band, 1, &maxVal, vDSP_Length(band.count))
        switch i {
        case 0: kick = maxVal
        case 1: snare = maxVal
        case 2: crack = maxVal
        case 3: hihat = maxVal
        default: break  // Future-proof: extra sub-bands silently ignored.
        }
      }
      trace?.subBandEnergies = SubBandEnergies(
        kick: kick, snare: snare, crack: crack, hihat: hihat)
    }

    // Step 3.5: Adaptive thresholding on full-band onset envelope
    if techniqueSet.contains(.adaptiveThreshold) {
      onsetEnvelope = adaptiveThreshold(envelope: onsetEnvelope, onsetRate: onsetRate)
    }

    // Allocate shared ACF buffers (reused across full-band + sub-band calls)
    let acfPaddedLength = nextPowerOf2(onsetEnvelope.count * 2)
    let acfHalfPadded = acfPaddedLength / 2
    let acfBufs = ACFBuffers.allocate(capacity: acfHalfPadded)
    defer { acfBufs.deallocate() }

    // Step 4: FFT-based autocorrelation
    var acf = computeAutocorrelation(onsetEnvelope, acfBuffers: acfBufs)
    guard !acf.isEmpty else { return nil }

    // Step 4.1: ACF peak sharpening — element-wise square
    if techniqueSet.contains(.acfSharpening) {
      vDSP_vsq(acf, 1, &acf, 1, vDSP_Length(acf.count))
    }

    if options.enableTrace {
      trace?.acfTopLags = extractTopPeaks(from: acf, count: 5)
        .map { (lag: $0.index, strength: $0.value) }
    }

    // Step 4b: Sub-band autocorrelations (empty when sub-bands skipped at intensity 1-2)
    let subBandACFs: [[Float]] =
      techniqueSet.contains(.subBandVoting)
      ? onsetResult.subBands.map { computeAutocorrelation($0, acfBuffers: acfBufs) }
      : []

    let bpmMin = Int(minBPM)
    let bpmMax = Int(maxBPM)

    // Allocate shared pipeline buffers (Hann window + windowed onset envelope)
    let windowLength = min(onsetEnvelope.count, Int(tempogramWindowSeconds * onsetRate))
    let pipelineBuffers = PipelineBuffers.allocate(onsetLength: windowLength)
    defer { pipelineBuffers.deallocate() }

    // Pre-compute windowed onset envelope once (reused by tempogram + refinement)
    if windowLength > 0 {
      onsetEnvelope.withUnsafeBufferPointer { envPtr in
        vDSP_vmul(
          envPtr.baseAddress!, 1,
          pipelineBuffers.hannWindow, 1,
          pipelineBuffers.windowed, 1,
          vDSP_Length(windowLength))
      }
    }

    // Step 5: Fourier tempogram
    let tempogram = computeFourierTempogram(
      onsetEnvelope: onsetEnvelope, onsetRate: onsetRate,
      bpmMin: bpmMin, bpmMax: bpmMax,
      pipelineBuffers: pipelineBuffers)

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
      enhanced: enhanced, bpmMin: bpmMin, count: techniqueSet.candidateCount)
    guard !candidates.isEmpty else { return nil }

    // Trace's rawCandidates always carries the pre-rescore array (DD#11) — this is
    // the upstream signal before the optional click-track rescoring at step 9b.
    trace?.rawCandidates = candidates

    // Step 9b: Click-track cross-correlation rescoring (per Story 3-3, DD#3, DD#4).
    // When .clickTrackCorrelation is active, each candidate's score is multiplied by
    // (alpha + (1 - alpha) * normalizedClickScore). The rescored array flows into both
    // step 10 disambiguation AND back out via BPMResult.candidates so multi-window
    // BPMSelectionPolicy stays consistent with disambiguation (DD#11).
    //
    // The default α=0.7 is corroborative-not-authoritative (DD#4); the value was
    // finalized by Story 3-3 Task 3.3 — the α-sweep over `.optimal`-family combos on
    // OA300 showed α=0.7 outperforms α=0.3 by +2 Acc1 tracks on `.optimal+click`,
    // meeting the margin gate. The `CLICK_RESCORE_ALPHA_OVERRIDE` env var lets future
    // sweeps probe alternative defaults without exposing α across the public API.
    //
    // Step 9.7 (duration hint) runs immediately after click rescore and feeds into the
    // same disambiguation. The two compose in series: click damps unmatched candidates
    // toward `alpha * oldScore`; duration boosts structurally-plausible candidates by
    // `1 + durationHintBoostWeight`. Duration is corroborative-only — it never damps.
    let rescoredCandidates: [(bpm: Double, score: Float)] =
      techniqueSet.contains(.clickTrackCorrelation)
      ? clickRescore(
        candidates: candidates,
        onsetEnvelope: onsetEnvelope,
        onsetRate: onsetRate,
        alpha: alphaOverride() ?? 0.7,
        trace: &trace)
      : candidates

    // Step 9.7: Duration-derived BPM hint (Story 3-4).
    // When AudioAnalysisService passes fileDurationSeconds (default-on via
    // Options.durationHint), candidates matching common bar-count-derived BPMs
    // (within 2% relative tolerance) receive a 10% multiplicative boost — but only
    // when the file is at least `durationHintMinFileSeconds` long (default 3 min).
    // Below the threshold the file is more likely a clip/loop where bar-count math
    // is structurally meaningless. Weak corroborative prior — never damps.
    // Composes in series with click rescore.
    let hintedCandidates: [(bpm: Double, score: Float)] =
      options.fileDurationSeconds.map { duration in
        applyDurationHint(
          candidates: rescoredCandidates,
          fileDurationSeconds: duration,
          minFileSeconds: options.durationHintMinFileSeconds,
          trace: &trace)
      } ?? rescoredCandidates

    // Step 10: Octave disambiguation with sub-band voting
    let disambiguated = resolveOctaveAmbiguity(
      candidates: hintedCandidates, fused: fused, bpmMin: bpmMin,
      subBandACFs: subBandACFs, onsetRate: onsetRate)
    var winner = disambiguated.best

    if let ev = disambiguated.evidence {
      trace?.harmonicRatioDetail = ev
    }

    // Step 10b: Sub-band periodicity confirmation
    if techniqueSet.contains(.subBandVoting) && !subBandACFs.isEmpty {
      let preVoteBPM = winner.bpm
      winner = confirmWithSubBandPeaks(
        winner: winner, subBandACFs: subBandACFs, onsetRate: onsetRate)

      if options.enableTrace {
        let changed = winner.bpm != preVoteBPM
        trace?.subBandVoteDetail = SubBandVoteEvidence(
          preVoteBPM: preVoteBPM,
          postVoteBPM: winner.bpm,
          changed: changed)
      }
    }

    trace?.disambiguationResult = (bpm: winner.bpm, score: winner.score)

    // Step 10c: Fine-grid tempogram refinement
    if techniqueSet.contains(.fineGridRefinement) {
      let refinedCandidates = refineCandidates(
        candidates: [winner],
        onsetEnvelope: onsetEnvelope,
        autocorrelation: acf,
        onsetRate: onsetRate,
        bpmRange: bpmMin...bpmMax,
        pipelineBuffers: pipelineBuffers)
      if let refinedWinner = refinedCandidates.first {
        winner = refinedWinner
      }
      trace?.refinedBPM = winner.bpm
    }

    let bpm = winner.bpm
    guard bpm >= minBPM && bpm <= maxBPM else { return nil }

    // Step 11: Beat-grid extraction (optional fan-out, Story 8.4).
    // Gated by `options.computeBeatGrid` (default `false` → branch not entered →
    // byte-identical default-path output). Reuses the in-scope `onsetEnvelope`,
    // `acf`, `onsetRate`, `hopSize`, `sampleRate`, and the step-1 `dropOffset`
    // (all still alive — the `acfBufs`/`pipelineBuffers` `defer`s have not fired),
    // so no new onset/ACF buffer is allocated in the hot path. Beat grid is a
    // PARALLEL output: it does not feed BPM winner selection, so KDD-T0 does not
    // trigger and no `BPMDiagnosticTrace` field is added (W74 stays armed for a
    // future beat-grid pool producer).
    var beatGrid: BeatGrid?
    if options.computeBeatGrid {
      beatGrid = BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: onsetEnvelope,
        onsetRate: onsetRate,
        hopSize: hopSize,
        sampleRate: sampleRate,
        acf: acf,
        tempoBPM: bpm,
        windowStartSample: dropOffset,
        subBands: onsetResult.subBands,
        detectDownbeats: options.detectDownbeats)
    }

    // Step 12: Confidence
    let confidence = computeConfidence(fused: fused, winnerBPM: bpm, bpmMin: bpmMin)

    trace?.confidence = confidence

    // BPMResult.candidates carries rescored + duration-hinted values (DD#11 contract);
    // trace.rawCandidates above preserves the pre-rescore signal for diagnostics.
    return BPMResult(
      bpm: bpm, confidence: confidence, candidates: hintedCandidates, trace: trace,
      beatGrid: beatGrid)
  }

  // MARK: - Full-track beat-grid seam (Story 8.5, DD #10)

  /// Builds a ``BeatGrid`` over a coverage span LONGER than the BPM analysis
  /// window — the Story-8.5 full-track / explicit-window seam (DD #10).
  ///
  /// This is a **separate entry**, NOT a widened ``estimateBPM(decoded:options:)``:
  /// folding the 30 s window out of a single full-track envelope would change the
  /// onset/ACF the BPM pipeline sees and break the default-path byte-identity
  /// contract (DD #9). The default ``BeatGridCoverage/analysisWindow`` path never
  /// reaches here — the service reuses the cheap in-scope step-11 fan-out for it
  /// (zero second onset pass). The service calls this only for
  /// ``BeatGridCoverage/window(seconds:)`` / ``BeatGridCoverage/fullTrack`` AFTER
  /// it has resolved `tempoBPM` (the single-window DSP tempo), and checks
  /// cancellation immediately before calling — cancellation is a service concern,
  /// so this pure-DSP entry carries none.
  ///
  /// Builds the coverage-length onset envelope + ACF (mirroring the technique-set
  /// gating of ``estimateBPM(decoded:options:)`` for the full-band envelope:
  /// SuperFlux vs log-mel, adaptive threshold, ACF sharpening), then runs the same
  /// ``BeatGridAnalyzer/estimateBeatGrid(onsetEnvelope:onsetRate:hopSize:sampleRate:acf:tempoBPM:windowStartSample:coverage:)``
  /// tracker the step-11 fan-out uses. Cost is O(track) — linear in the coverage
  /// length (DD #5).
  ///
  /// - Parameters:
  ///   - decoded: The same decoded carrier the BPM pass used (already
  ///     `maxSeconds`-capped by the service); `.fullTrack` therefore spans up to
  ///     `maxSeconds` of audio, like every other decode in the library.
  ///   - tempoBPM: The tempo to track against — the single-window DSP tempo, so
  ///     the grid's reported ``BeatGrid/estimatedTempo`` stays an independent
  ///     estimate the consistency contract can compare against the full BPM
  ///     result (AC7 — NOT tautological).
  ///   - coverage: ``BeatGridCoverage/window(seconds:)`` or
  ///     ``BeatGridCoverage/fullTrack``; recorded (sanitized) on the result.
  ///   - options: Supplies `intensity` / `techniqueSet` (onset variant + gating)
  ///     and `analysisWindowSeconds` (the fallback span if a degenerate coverage
  ///     sanitizes to `.analysisWindow`).
  /// - Returns: A ``BeatGrid`` over the coverage span, or `nil` for silence,
  ///   too-short coverage, or non-musical input.
  static func estimateBeatGrid(
    decoded: FeatureSubstrate.DecodedAudio,
    tempoBPM: Double,
    coverage: BeatGridCoverage,
    options: Options = .init()
  ) -> BeatGrid? {
    let samples = decoded.samples
    let sampleRate = decoded.sampleRate
    let techniqueSet = options.techniqueSet ?? options.intensity.techniqueSet
    guard !samples.isEmpty, sampleRate > 0 else { return nil }
    guard tempoBPM.isFinite, tempoBPM > 0 else { return nil }

    // Step 1: energy scan — the SAME drop offset estimateBPM derives, so the
    // coverage span shares the BPM window's musical start and beats stay
    // track-relative (decoded-PCM-relative `t=0` = file start).
    let dropOffset = findEnergyTransition(samples: samples, sampleRate: sampleRate)

    // Resolve the coverage span (in samples) from the sanitized coverage.
    let cov = coverage.sanitized
    let spanSamples: Int
    switch cov {
    case .analysisWindow:
      spanSamples = Int(options.analysisWindowSeconds * sampleRate)
    case .window(let seconds):
      spanSamples = Int(seconds * sampleRate)
    case .fullTrack:
      spanSamples = samples.count - dropOffset
    }
    let endSample = min(dropOffset + spanSamples, samples.count)
    guard endSample > dropOffset else { return nil }
    let coverageWindow = Array(samples[dropOffset..<endSample])

    guard !isSilent(coverageWindow) else { return nil }
    let coverageDuration = Double(coverageWindow.count) / sampleRate
    guard coverageDuration >= minimumDurationSeconds else { return nil }

    let hopSize = Int(sampleRate / 100)
    let onsetRate = sampleRate / Double(hopSize)

    // Full-band onset envelope. Sub-bands are unused by the beat tracker, so they
    // are computed ONLY when the downbeat estimator needs them (Story 8.5a AC6 —
    // the `.window` / `.fullTrack` coverage paths honor `detectDownbeats` too).
    let onsetResult: OnsetEnvelopes
    if techniqueSet.contains(.superFluxOnset) {
      onsetResult = computeSuperFluxOnsetEnvelope(
        samples: coverageWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: options.detectDownbeats, normalizeSubBands: false,
        captureMLFeatures: false)
    } else {
      onsetResult = computeMelOnsetEnvelopeWithSubBands(
        samples: coverageWindow, sampleRate: sampleRate, hopSize: hopSize,
        computeSubBands: options.detectDownbeats, normalizeSubBands: false,
        captureMLFeatures: false)
    }
    var onsetEnvelope = onsetResult.fullBand
    guard !onsetEnvelope.isEmpty else { return nil }

    if techniqueSet.contains(.adaptiveThreshold) {
      onsetEnvelope = adaptiveThreshold(envelope: onsetEnvelope, onsetRate: onsetRate)
    }

    var acf = computeAutocorrelation(onsetEnvelope)
    guard !acf.isEmpty else { return nil }
    if techniqueSet.contains(.acfSharpening) {
      vDSP_vsq(acf, 1, &acf, 1, vDSP_Length(acf.count))
    }

    return BeatGridAnalyzer.estimateBeatGrid(
      onsetEnvelope: onsetEnvelope,
      onsetRate: onsetRate,
      hopSize: hopSize,
      sampleRate: sampleRate,
      acf: acf,
      tempoBPM: tempoBPM,
      windowStartSample: dropOffset,
      coverage: cov,
      subBands: onsetResult.subBands,
      detectDownbeats: options.detectDownbeats)
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
    /// Story 4-5: per-frame log-mel features retained from the pre-temporal-
    /// difference state. Non-nil ONLY when `captureMLFeatures` is true at the
    /// call site; otherwise nil so the DSP-only path allocates nothing.
    let mlFeatures: MLFeatureFrames?

    init(
      fullBand: [Float], subBands: [[Float]], mlFeatures: MLFeatureFrames? = nil
    ) {
      self.fullBand = fullBand
      self.subBands = subBands
      self.mlFeatures = mlFeatures
    }

    /// Sentinel-empty envelope returned by the helper short-circuit path when
    /// the input has fewer than 2 frames. Used by both
    /// `computeMelOnsetEnvelopeWithSubBands` and `computeSuperFluxOnsetEnvelope`
    /// to avoid duplicating the empty-envelope literal at the early-exit sites
    /// (Codex review 2026-05-17 P8). `static let` is thread-safe (Swift 6 strict
    /// concurrency) because all field types are `Sendable` and the value is
    /// immutable.
    static let empty = OnsetEnvelopes(
      fullBand: [], subBands: [[], [], [], []], mlFeatures: nil)
  }

  /// Computes onset envelopes for both full-band and 4 sub-bands from mel-spectrogram.
  /// Reuses the same STFT + mel filterbank pipeline as `computeMelOnsetEnvelope`,
  /// but also produces 4 independent sub-band onset envelopes by summing within
  /// each band's mel bin range.
  ///
  /// Story 4-7: the FFT + Hann window + mel-filterbank + log + retention chain
  /// (formerly inline) is now factored into the private helper
  /// `computeLogMelFramesAndRetention(samples:sampleRate:hopSize:captureMLFeatures:onPostVvlogf:)`
  /// so both this baseline log-mel spectral-flux variant AND the new
  /// `computeSuperFluxOnsetEnvelope` SuperFlux variant share it without duplication
  /// (Story 4-7 Task 3.2 explicit "do NOT duplicate that code" requirement).
  ///
  /// - Parameter onPostVvlogf: Test-only seam. When non-nil, invoked exactly once
  ///   immediately AFTER the per-frame `vvlogf` loop completes and BEFORE the
  ///   retention block builds `mlFeatures`. The closure receives the raw
  ///   per-frame log-mel matrix; callers should deep-copy via
  ///   `frames.map { Array($0) }` if they intend to compare against
  ///   `OnsetEnvelopes.mlFeatures.logMelData` for HALT (h) byte-identity
  ///   verification (review fix M2 — pattern: independent capture, not
  ///   shared-buffer aliasing). The closure is `nil` in all production
  ///   call paths.
  static func computeMelOnsetEnvelopeWithSubBands(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    computeSubBands: Bool = true,
    normalizeSubBands: Bool = false,
    captureMLFeatures: Bool = false,
    onPostVvlogf: (([[Float]]) -> Void)? = nil
  ) -> OnsetEnvelopes {
    guard
      let helper = computeLogMelFramesAndRetention(
        samples: samples, sampleRate: sampleRate, hopSize: hopSize,
        captureMLFeatures: captureMLFeatures, onPostVvlogf: onPostVvlogf)
    else {
      return .empty
    }
    let logMelFrames = helper.logMelFrames
    let retainedMLFeatures = helper.mlFeatures

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

    normalizeSubBandsInPlace(
      &subBandEnvelopes, frameCount: frameCount,
      apply: computeSubBands && normalizeSubBands)

    let resultSubBands = computeSubBands ? subBandEnvelopes : []
    return OnsetEnvelopes(
      fullBand: fullBandEnvelope, subBands: resultSubBands, mlFeatures: retainedMLFeatures)
  }

  // MARK: - SuperFlux Onset Detection (Story 4-7)

  /// Computes the SuperFlux onset envelope from raw PCM samples.
  ///
  /// Per Böck & Widmer (2013) "Maximum Filter Vibrato Suppression for
  /// Onset Detection" (DAFx-13), SuperFlux extends spectral flux by
  /// replacing the temporal reference value `M[t-1][k]` with a
  /// frequency-neighborhood maximum `max(M[t-1][k-r:k+r])` (r=1, window
  /// = 3 mel bins) before per-frame differencing. The widened reference
  /// trajectory suppresses vibrato — energy sloshing between adjacent
  /// mel bins frame-to-frame no longer registers as a new onset.
  ///
  /// Formula: `SF_super[t] = Σ_k max(0, M[t][k] - max(M[t-1][k-r:k+r]))`
  /// where `M` is the post-`vvlogf` log-mel matrix and `r = 1`.
  ///
  /// Algorithmic distinction from the baseline at
  /// ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:onPostVvlogf:)``
  /// (which uses `M[t-1][k]` directly as the reference): only the
  /// reference-frame construction differs. The `vDSP_vsub` →
  /// `vDSP_vthres` → `vDSP_sve` chain is byte-identical.
  ///
  /// **Composition with `.subBandNormalization`.** When both `.superFluxOnset` and
  /// `.subBandNormalization` are in the technique set, the SuperFlux variant runs
  /// first and `.subBandNormalization` applies per-band max-normalization to the
  /// SuperFlux-derived sub-bands. This composition was NOT empirically validated
  /// before Story 4-7 — the 256-combination ablation matrix covers the cell.
  ///
  /// **Pipeline step number** stays at 3 (same as the baseline). Per
  /// project-context.md:75 "Pipeline step numbers are stable identifiers" — the
  /// variant occupies the same logical position with a different algorithm.
  ///
  /// - Parameters:
  ///   - samples: Mono PCM `[Float]`, normalized to `[-1.0, 1.0]`.
  ///   - sampleRate: Hz (44.1k, 48k, 96k supported per `MelFilterbank`).
  ///   - hopSize: FFT hop in samples (typically 441 at 44.1k).
  ///   - computeSubBands: Gate for 4 sub-band envelope extraction (mirrors
  ///     `computeMelOnsetEnvelopeWithSubBands`'s contract).
  ///   - normalizeSubBands: Gate for per-band max normalization, applied
  ///     after sub-band extraction.
  ///   - captureMLFeatures: Gate for retaining the log-mel matrix in
  ///     ``OnsetEnvelopes/mlFeatures``.
  /// - Returns: An ``OnsetEnvelopes`` with `fullBand` (frame-count), four
  ///   `subBands` (each frame-count), and optional `mlFeatures`. Returns
  ///   sentinel-empty envelopes (empty `fullBand`, four empty `subBands`)
  ///   when the input has fewer than 2 frames. For silent inputs with
  ///   ≥ 2 frames, returns finite all-zero envelopes (`fullBand.count ==
  ///   frameCount`, every element exactly `0.0`). Both contracts are
  ///   tested by `SuperFluxOnsetEnvelopeTests.sentinelOnTooShortInput`
  ///   and `SuperFluxOnsetEnvelopeTests.silentInputProducesFiniteZeros`
  ///   respectively. **Does not throw** — sentinel-return semantics per
  ///   project-context.md:39.
  /// - Note: Variant of
  ///   ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:onPostVvlogf:)``.
  ///   Gated by ``DSPTechnique/superFluxOnset`` in the technique set. Frequency-axis
  ///   max-filter (canonical Böck 2013); time-axis variant is reserved for a future
  ///   story per Codex 2026-05-17 thread `019e36de`.
  /// - SeeAlso:
  ///   - ``computeMelOnsetEnvelopeWithSubBands(samples:sampleRate:hopSize:computeSubBands:normalizeSubBands:captureMLFeatures:onPostVvlogf:)``
  ///   - ``DSPTechnique/superFluxOnset``
  ///   - Böck & Widmer (2013), DAFx-13 — https://phenicx.upf.edu/system/files/publications/Boeck_DAFx-13.pdf
  static func computeSuperFluxOnsetEnvelope(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    computeSubBands: Bool = true,
    normalizeSubBands: Bool = false,
    captureMLFeatures: Bool = false
  ) -> OnsetEnvelopes {
    guard
      let helper = computeLogMelFramesAndRetention(
        samples: samples, sampleRate: sampleRate, hopSize: hopSize,
        captureMLFeatures: captureMLFeatures)
    else {
      return .empty
    }
    let logMelFrames = helper.logMelFrames
    let retainedMLFeatures = helper.mlFeatures

    let n = vDSP_Length(melBands)
    // Codex 2026-05-17 locked r=1, replicate-pad. r=1 → window = 3 mel bins.
    // Larger radii reserved for a future ablation if SuperFlux clears the
    // brutal-corpus gate.
    let r = 1
    let windowLength = vDSP_Length(2 * r + 1)
    let paddedLength = melBands + (2 * r)

    let frameCount = logMelFrames.count - 1
    var fullBandEnvelope = [Float](repeating: 0, count: frameCount)
    var subBandEnvelopes: [[Float]] = Array(
      repeating: [Float](repeating: 0, count: frameCount), count: 4)
    var paddedRef = [Float](repeating: 0, count: paddedLength)
    var maxFilteredRef = [Float](repeating: 0, count: melBands)
    var diff = [Float](repeating: 0, count: melBands)
    var rectified = [Float](repeating: 0, count: melBands)

    let bandRanges = [kickBandRange, snareLowRange, snareCrackRange, hiHatRange]

    for i in 1..<logMelFrames.count {
      let refFrame = logMelFrames[i - 1]
      // 1. Build replicate-padded reference frame from M[t-1].
      //    Codex 2026-05-17 rationale: replicate "preserves edge locality and
      //    avoids reflecting interior energy into the kick/hi-hat boundaries"
      //    (load-bearing for the 4 named DnB tracks). Zero-pad was rejected
      //    outright; reflect-pad would over-count edges.
      for k in 0..<r { paddedRef[k] = refFrame[0] }
      for k in 0..<melBands { paddedRef[r + k] = refFrame[k] }
      for k in 0..<r { paddedRef[r + melBands + k] = refFrame[melBands - 1] }

      // 2. Frequency-axis max-filter on the padded reference frame.
      //    vDSP_vswmax: C[n] = max(A[n], A[n+1], ..., A[n+WindowLength-1])
      //    A must contain N+WindowLength-1 elements (paddedRef satisfies this).
      //    A and C may NOT overlap — paddedRef and maxFilteredRef are distinct.
      //    Apple verbatim: developer.apple.com/documentation/accelerate/vdsp_vswmax
      vDSP_vswmax(paddedRef, 1, &maxFilteredRef, 1, n, windowLength)

      // 3. SuperFlux temporal difference: diff = M[t] - max_filter(M[t-1])
      //    vDSP_vsub parameter ORDER (B, A, C) computes C = A - B. Pass
      //    maxFilteredRef as B (subtrahend), currFrame as A (minuend).
      //    This is the ONLY step that differs in shape from the baseline at
      //    computeMelOnsetEnvelopeWithSubBands — baseline passes prevFrame
      //    directly as B; SuperFlux passes its max-filter.
      logMelFrames[i].withUnsafeBufferPointer { currPtr in
        vDSP_vsub(maxFilteredRef, 1, currPtr.baseAddress!, 1, &diff, 1, n)
      }

      // 4. Half-wave rectify: rectified = max(diff, 0) — byte-identical to baseline.
      var threshold: Float = 0
      vDSP_vthres(diff, 1, &threshold, &rectified, 1, n)

      // 5. Sum across mel bands (full-band) and per-sub-band — identical to baseline.
      var sum: Float = 0
      vDSP_sve(rectified, 1, &sum, n)
      fullBandEnvelope[i - 1] = sum

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

    normalizeSubBandsInPlace(
      &subBandEnvelopes, frameCount: frameCount,
      apply: computeSubBands && normalizeSubBands)

    let resultSubBands = computeSubBands ? subBandEnvelopes : []
    return OnsetEnvelopes(
      fullBand: fullBandEnvelope, subBands: resultSubBands, mlFeatures: retainedMLFeatures)
  }

  // MARK: - Shared Onset-Envelope Helpers (Story 4-7 refactor)

  /// Shared FFT + Hann window + mel-filterbank + log + MLFeatures-retention chain.
  /// Story 4-7 extracted this from `computeMelOnsetEnvelopeWithSubBands` so the
  /// baseline log-mel spectral-flux variant and the new SuperFlux variant share it
  /// without code duplication (Task 3.2 requirement).
  ///
  /// Returns `nil` for either sentinel condition:
  /// - FFT init fails (caller returns empty `OnsetEnvelopes`)
  /// - `logMelFrames.count < 2` (caller returns empty `OnsetEnvelopes`)
  ///
  /// The byte-identity contract from `Tests/.../4-3-baseline-bpms.json`
  /// (consumed by `dspOnlyMatchesStory4_3Baseline`) is preserved by this refactor:
  /// the function body below is the exact sequence of vDSP/Swift operations from
  /// pre-Story-4-7 `computeMelOnsetEnvelopeWithSubBands`, unchanged in order or
  /// argument values. Story 4-7 Task 7 / AC #3 verifies byte-identity against the
  /// Task-1 snapshot.
  ///
  /// - Parameter onPostVvlogf: Test-only seam (M2). Production callers pass `nil`.
  private static func computeLogMelFramesAndRetention(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    captureMLFeatures: Bool,
    onPostVvlogf: (([[Float]]) -> Void)? = nil
  ) -> (logMelFrames: [[Float]], mlFeatures: MLFeatureFrames?)? {
    guard
      let fft = vDSP.FFT(
        log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)
    else {
      return nil
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
    let expectedFrameCount = max(0, (samples.count - fftSize) / hopSize + 1)
    logMelFrames.reserveCapacity(expectedFrameCount)

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

      vDSP.clear(&melEnergies)
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
      return nil
    }

    // Story 4-5 review fix M2: test-only seam fires here, AFTER the per-frame
    // `vvlogf` loop completes and BEFORE the retention block reads
    // `logMelFrames`. Production callers pass `nil`.
    onPostVvlogf?(logMelFrames)

    // Story 4-5 / DD #2 / AC #4 — retain the post-`vvlogf` per-frame log-mel
    // matrix BEFORE the temporal-difference loop below mutates intermediate
    // state. Storage order: source-natural frame-major flat layout.
    // Overflow guard via `multipliedReportingOverflow`; size cap enforced
    // BEFORE allocation per review fix BH2.
    let retainedMLFeatures: MLFeatureFrames? = {
      guard captureMLFeatures, logMelFrames.count > 0 else { return nil }
      let (expectedCount, overflow) =
        melBands.multipliedReportingOverflow(by: logMelFrames.count)
      guard !overflow,
        expectedCount <= MLFeatureFrames.maximumLogMelDataCount
      else { return nil }
      var flat = [Float]()
      flat.reserveCapacity(expectedCount)
      for frame in logMelFrames {
        flat.append(contentsOf: frame)
      }
      do {
        return try MLFeatureFrames(
          melBands: melBands,
          frames: logMelFrames.count,
          tensorLayout: .frameMajorLogMel,
          logMelData: flat,
          sampleRate: sampleRate,
          fftSize: fftSize,
          hopSize: hopSize,
          melFmin: melFmin,
          melFmax: effectiveFmax,
          logCompressionScale: logCompressionScale,
          featureSetVersion: MLFeatureFrames.currentFeatureSetVersion
        )
      } catch {
        return nil
      }
    }()

    return (logMelFrames, retainedMLFeatures)
  }

  /// Per-sub-band max normalization (Story 4-7 refactor — shared by baseline and
  /// SuperFlux variants). Normalizes each band to `[0,1]` and skips bands with
  /// negligible energy (max < 1% of strongest band) to avoid amplifying noise
  /// in near-silent bands. No-op when `apply == false`.
  private static func normalizeSubBandsInPlace(
    _ subBandEnvelopes: inout [[Float]], frameCount: Int, apply: Bool
  ) {
    guard apply else { return }
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

  // MARK: - ACF Buffers (Story 1.1)

  /// Pre-allocated buffers for FFT-based autocorrelation, reused across full-band and sub-band calls.
  private struct ACFBuffers {
    let fwdRealp: UnsafeMutablePointer<Float>
    let fwdImagp: UnsafeMutablePointer<Float>
    let freqRealp: UnsafeMutablePointer<Float>
    let freqImagp: UnsafeMutablePointer<Float>
    let invRealp: UnsafeMutablePointer<Float>
    let invImagp: UnsafeMutablePointer<Float>
    let acfRealp: UnsafeMutablePointer<Float>
    let acfImagp: UnsafeMutablePointer<Float>
    let capacity: Int

    static func allocate(capacity: Int) -> ACFBuffers {
      ACFBuffers(
        fwdRealp: .allocate(capacity: capacity),
        fwdImagp: .allocate(capacity: capacity),
        freqRealp: .allocate(capacity: capacity),
        freqImagp: .allocate(capacity: capacity),
        invRealp: .allocate(capacity: capacity),
        invImagp: .allocate(capacity: capacity),
        acfRealp: .allocate(capacity: capacity),
        acfImagp: .allocate(capacity: capacity),
        capacity: capacity)
    }

    /// Zero the working range before each use. Must be called before every computeAutocorrelation invocation.
    func zeroBuffers(count: Int) {
      vDSP_vclr(fwdRealp, 1, vDSP_Length(count))
      vDSP_vclr(fwdImagp, 1, vDSP_Length(count))
      vDSP_vclr(freqRealp, 1, vDSP_Length(count))
      vDSP_vclr(freqImagp, 1, vDSP_Length(count))
      vDSP_vclr(invRealp, 1, vDSP_Length(count))
      vDSP_vclr(invImagp, 1, vDSP_Length(count))
      vDSP_vclr(acfRealp, 1, vDSP_Length(count))
      vDSP_vclr(acfImagp, 1, vDSP_Length(count))
    }

    func deallocate() {
      fwdRealp.deallocate()
      fwdImagp.deallocate()
      freqRealp.deallocate()
      freqImagp.deallocate()
      invRealp.deallocate()
      invImagp.deallocate()
      acfRealp.deallocate()
      acfImagp.deallocate()
    }
  }

  // MARK: - FFT-Based Autocorrelation (Task 4)

  /// FFT-based autocorrelation of a signal. When `acfBuffers` is provided, reuses pre-allocated
  /// split-complex buffers to avoid per-call heap allocations.
  private static func computeAutocorrelation(_ signal: [Float], acfBuffers: ACFBuffers? = nil)
    -> [Float]
  {
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

    // Use shared ACFBuffers when provided, otherwise allocate locally
    let localBuffers: ACFBuffers?
    let fwdRealp: UnsafeMutablePointer<Float>
    let fwdImagp: UnsafeMutablePointer<Float>
    let freqRealp: UnsafeMutablePointer<Float>
    let freqImagp: UnsafeMutablePointer<Float>
    let invRealp: UnsafeMutablePointer<Float>
    let invImagp: UnsafeMutablePointer<Float>
    let acfRealp: UnsafeMutablePointer<Float>
    let acfImagp: UnsafeMutablePointer<Float>

    if let shared = acfBuffers {
      precondition(shared.capacity >= halfPadded)
      shared.zeroBuffers(count: halfPadded)
      localBuffers = nil
      fwdRealp = shared.fwdRealp
      fwdImagp = shared.fwdImagp
      freqRealp = shared.freqRealp
      freqImagp = shared.freqImagp
      invRealp = shared.invRealp
      invImagp = shared.invImagp
      acfRealp = shared.acfRealp
      acfImagp = shared.acfImagp
    } else {
      let buf = ACFBuffers.allocate(capacity: halfPadded)
      buf.zeroBuffers(count: halfPadded)
      localBuffers = buf
      fwdRealp = buf.fwdRealp
      fwdImagp = buf.fwdImagp
      freqRealp = buf.freqRealp
      freqImagp = buf.freqImagp
      invRealp = buf.invRealp
      invImagp = buf.invImagp
      acfRealp = buf.acfRealp
      acfImagp = buf.acfImagp
    }
    defer { localBuffers?.deallocate() }

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
  /// from bpmMin to bpmMax over the windowed onset envelope. When `pipelineBuffers` is provided,
  /// reuses pre-computed Hann-windowed onset to avoid redundant allocation.
  static func computeFourierTempogram(
    onsetEnvelope: [Float],
    onsetRate: Double,
    bpmMin: Int,
    bpmMax: Int,
    pipelineBuffers: PipelineBuffers? = nil
  ) -> [Float] {
    let candidateCount = bpmMax - bpmMin + 1

    // 8-second Hann window over onset envelope (or full length if shorter)
    let windowLength = min(onsetEnvelope.count, Int(tempogramWindowSeconds * onsetRate))
    guard windowLength > 0 else { return [Float](repeating: 0, count: candidateCount) }

    // Use pre-computed windowed onset pointer directly (no Array copy)
    let localBufs: PipelineBuffers?
    let windowedPtr: UnsafeMutablePointer<Float>
    if let pb = pipelineBuffers {
      precondition(pb.capacity >= windowLength)
      localBufs = nil
      windowedPtr = pb.windowed
    } else {
      let lb = PipelineBuffers.allocate(onsetLength: windowLength)
      onsetEnvelope.withUnsafeBufferPointer { envPtr in
        vDSP_vmul(
          envPtr.baseAddress!, 1, lb.hannWindow, 1, lb.windowed, 1, vDSP_Length(windowLength))
      }
      localBufs = lb
      windowedPtr = lb.windowed
    }
    defer { localBufs?.deallocate() }

    // Allocate cos/sin/phase buffers using TempogramBuffers pattern
    let tempBufs = TempogramBuffers.allocate(capacity: windowLength)
    defer { tempBufs.deallocate() }

    var magnitudes = [Float](repeating: 0, count: candidateCount)

    for i in 0..<candidateCount {
      let bpm = Double(bpmMin + i)
      let freq = bpm / 60.0

      // Compute phase vector: 2*pi*freq*k/onsetRate for k = 0..<windowLength
      // via vDSP_vramp (Accelerate-required by CLAUDE.md design constraints).
      var phaseStart: Float = 0
      var phaseStep = Float(2.0 * .pi * freq / onsetRate)
      vDSP_vramp(&phaseStart, &phaseStep, tempBufs.phase, 1, vDSP_Length(windowLength))

      // Compute cos and sin via vForce (separate in/out arrays required)
      var count = Int32(windowLength)
      vvcosf(tempBufs.cos, tempBufs.phase, &count)
      vvsinf(tempBufs.sin, tempBufs.phase, &count)

      // Dot products for real and imaginary sums
      var realSum: Float = 0
      var imagSum: Float = 0
      vDSP_dotpr(windowedPtr, 1, tempBufs.cos, 1, &realSum, vDSP_Length(windowLength))
      vDSP_dotpr(windowedPtr, 1, tempBufs.sin, 1, &imagSum, vDSP_Length(windowLength))

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

  // MARK: - Pipeline Buffers (Story 1.1)

  /// Pre-allocated buffers shared across computeFourierTempogram and refineCandidates.
  /// Hann window is computed once and reused; windowed onset envelope is computed once and shared.
  ///
  /// Internal (not private) because computeFourierTempogram is test-accessible
  /// and its signature includes PipelineBuffers?.
  struct PipelineBuffers {
    let hannWindow: UnsafeMutablePointer<Float>
    let windowed: UnsafeMutablePointer<Float>
    let capacity: Int

    static func allocate(onsetLength: Int) -> PipelineBuffers {
      let buf = PipelineBuffers(
        hannWindow: .allocate(capacity: onsetLength),
        windowed: .allocate(capacity: onsetLength),
        capacity: onsetLength)
      vDSP_hann_window(buf.hannWindow, vDSP_Length(onsetLength), Int32(vDSP_HANN_DENORM))
      return buf
    }

    func deallocate() {
      hannWindow.deallocate()
      windowed.deallocate()
    }
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

  /// Computes tempogram magnitude at a single fractional BPM using a pre-windowed onset envelope pointer.
  /// Reuses pre-allocated cos/sin/phase buffers to avoid per-call allocations.
  private static func tempogramMagnitude(
    bpm: Double,
    windowed: UnsafePointer<Float>,
    windowLength: Int,
    onsetRate: Double,
    buffers: TempogramBuffers
  ) -> Float {
    let freq = bpm / 60.0
    // Phase vector via vDSP_vramp (Accelerate-required by CLAUDE.md design constraints).
    var phaseStart: Float = 0
    var phaseStep = Float(2.0 * .pi * freq / onsetRate)
    vDSP_vramp(&phaseStart, &phaseStep, buffers.phase, 1, vDSP_Length(windowLength))
    var count = Int32(windowLength)
    vvcosf(buffers.cos, buffers.phase, &count)
    vvsinf(buffers.sin, buffers.phase, &count)

    var realSum: Float = 0
    var imagSum: Float = 0
    vDSP_dotpr(windowed, 1, buffers.cos, 1, &realSum, vDSP_Length(windowLength))
    vDSP_dotpr(windowed, 1, buffers.sin, 1, &imagSum, vDSP_Length(windowLength))

    return sqrtf(realSum * realSum + imagSum * imagSum)
  }

  /// Refines coarse integer-BPM candidates to sub-BPM resolution.
  ///
  /// Note: when `.clickTrackCorrelation` is in the technique set, candidate scores
  /// are rescored at step 9b (between candidate extraction and octave disambiguation)
  /// via `clickRescore` before this refinement step ever runs.
  ///
  /// **Gated hybrid: a fused-score quadratic fit is the default refinement path; a
  /// tempogram-peak quadratic fit overrides it when a three-condition gate detects
  /// the parabolic-ACF interpolation bias signature.** Diagnostic findings showed
  /// that the parabolic-interpolated ACF used in `fusePeriodicity` has two inherent
  /// biases when scanned at 0.1 BPM resolution within a narrow window:
  /// (1) sample-anchor switching at `lag = N + 0.5` boundaries (when `lag.rounded()`
  /// flips) produces 14-75% step jumps in the BPM-domain ACF mapping; and (2) for
  /// sharp ACF peaks, the parabolic-fit apex is offset from the true continuous peak
  /// (the offset grows with |t|, the fractional position relative to the rounded
  /// lag-domain anchor — exact at integer-aligned tempos like 120/150 BPM at 44.1 kHz,
  /// but ~0.4 BPM for 126 BPM where t≈-0.38). Local max-normalization within the
  /// scan window amplifies the ACF's bias because the ACF spans ~100x the dynamic
  /// range of the Hann-windowed tempogram, so the fused product inherits the bias.
  ///
  /// The fix avoids touching the shared `parabolicInterpolateACF` (used by
  /// `fusePeriodicity` for the validated coarse pipeline). Instead it computes a
  /// fused-score quadratic fit by default — preserving the calibrated coarse-stage
  /// discriminability that real noisy tracks rely on — and conditionally substitutes
  /// a tempogram-peak quadratic fit. The tempogram is a smooth DFT magnitude that is
  /// correctly centered on the true frequency, so when the bias signature appears
  /// the tempogram peak is the better source.
  ///
  /// **Override gate (all three required):**
  /// - `|tempogramPeak − fusedWinner| ≥ 0.3 BPM` — tempogram and fused disagree
  /// - `|fusedWinner − coarseCenter| ≥ 0.3 BPM` — fused is displaced from coarse winner
  /// - `|tempogramPeak − coarseCenter| < |fusedWinner − coarseCenter|` — tempogram is
  ///   strictly closer to the coarse-pipeline center; the override must improve
  ///   center agreement, not merely avoid worsening it.
  ///
  /// The tempogram local-peak search radius is **±0.4 BPM** around the fused winner.
  /// Wider radii let distant spurious tempogram peaks (typical of noise/harmonics in
  /// real recordings) trigger the override and degrade real-track accuracy; the
  /// 0.4 BPM radius is the minimum that still recovers the diagnosed synthetic peak
  /// displacement (4 grid steps at 126 BPM, 3 at 140 BPM @ 44.1 kHz).
  ///
  /// Real tracks with significant fused-vs-coarse displacement (e.g., the Icicle DAW
  /// track) can also trigger the override; the gate identifies the displacement
  /// signature, not synthesis-vs-real. Over the OA300 and GiantSteps corpora the
  /// override fires rarely enough that Acc1/Acc2 are unchanged; per-track behavior
  /// can shift in either direction within the 2% Acc1 tolerance.
  ///
  /// **Dispatch order (priority):** override beats plateau beats default. A flat
  /// fused plateau is short-circuited to the integer-midpoint scan-grid index, but
  /// only when the override gate is NOT firing — the override path takes precedence
  /// because its three-condition gate has already verified the tempogram offers a
  /// more credible peak location than the plateau midpoint.
  ///
  /// **On override-path quadratic-fit guard failure**, the fallback is the **fused
  /// winner's** discrete BPM (the spec's "discrete winner BPM as-is"), not the
  /// tempogram peak's — falling back to the unrefined fused winner is safer than
  /// committing to a tempogram peak whose curvature was rejected.
  ///
  /// Per-fit guards (apply to both refinement paths via `quadraticPeakBPM`):
  /// - **Edge guard** falls back to `onFailure` when the chosen index has no left
  ///   or right neighbor.
  /// - **Concavity guard** (`denom < -epsD`) requires strict downward curvature.
  /// - **Conditioning guard** (`|offset| ≤ 1`) rejects ill-conditioned fits whose
  ///   apex falls beyond the immediate neighbors.
  /// - **Clamp** to `[scanMin, scanMax]` is applied to all output paths to defend
  ///   against Double quantization drift on the integer-step grid.
  ///
  /// When `pipelineBuffers` is provided, reuses pre-computed Hann-windowed onset.
  private static func refineCandidates(
    candidates: [(bpm: Double, score: Float)],
    onsetEnvelope: [Float],
    autocorrelation: [Float],
    onsetRate: Double,
    bpmRange: ClosedRange<Int>,
    pipelineBuffers: PipelineBuffers? = nil
  ) -> [(bpm: Double, score: Float)] {
    guard !candidates.isEmpty else { return candidates }

    let windowLength = min(onsetEnvelope.count, Int(tempogramWindowSeconds * onsetRate))
    guard windowLength > 0 else { return candidates }

    // Use pre-computed windowed onset pointer directly (no Array copy)
    let localBufs: PipelineBuffers?
    let windowedPtr: UnsafeMutablePointer<Float>
    if let pb = pipelineBuffers {
      precondition(pb.capacity >= windowLength)
      localBufs = nil
      windowedPtr = pb.windowed
    } else {
      let lb = PipelineBuffers.allocate(onsetLength: windowLength)
      onsetEnvelope.withUnsafeBufferPointer { envPtr in
        vDSP_vmul(
          envPtr.baseAddress!, 1, lb.hannWindow, 1, lb.windowed, 1, vDSP_Length(windowLength))
      }
      localBufs = lb
      windowedPtr = lb.windowed
    }
    defer { localBufs?.deallocate() }

    // Pre-allocate cos/sin/phase buffers once, reuse across ~80 tempogram evaluations per candidate
    let buffers = TempogramBuffers.allocate(capacity: windowLength)
    defer { buffers.deallocate() }

    let stepSize: Double = 0.1

    // Tempogram local-peak search radius around the fused winner. The minimum
    // that still recovers the diagnosed synthetic-click-track ACF-bias peak
    // displacement (4 steps at 126 BPM, 3 steps at 140 BPM @ 44.1 kHz). Wider
    // radii let distant spurious tempogram peaks (typical of noise / harmonics
    // in real recordings) trigger the override and degrade real-track accuracy.
    // Validated against OA300 (no regression) and GiantSteps corpora.
    let tempogramSearchRadiusBPM: Double = 0.4

    // Override gate displacement thresholds. Both gates require ≥ 0.3 BPM
    // displacement: T-F (tempogram disagrees with fused) and F-C (fused is
    // displaced from coarse-pipeline center). The third gate condition (T-C
    // strictly closer to center than F-C) is computed inline at the gate site.
    let overrideMinDisagreementBPM: Double = 0.3  // T-F threshold
    let overrideMinFusedOffsetBPM: Double = 0.3  // F-C threshold

    // Convert BPM-domain thresholds to grid steps. Use `floor` for the search
    // radius (max-radius semantics — the search must stay within ±radius BPM)
    // and `ceil` for the displacement thresholds (min-threshold semantics —
    // the gate must fire only when displacement meets or exceeds the BPM
    // floor). At stepSize = 0.1 these resolve to (4, 3, 3) — bit-equivalent
    // to the corpus-validated literals; the floor/ceil choice protects the
    // semantics if stepSize ever changes.
    let tempogramSearchSteps =
      Int((tempogramSearchRadiusBPM / stepSize).rounded(.down))
    let tempogramOverrideDistance =
      Int((overrideMinDisagreementBPM / stepSize).rounded(.up))
    let fusedDisplacementThreshold =
      Int((overrideMinFusedOffsetBPM / stepSize).rounded(.up))

    var refined: [(bpm: Double, score: Float)] = []
    refined.reserveCapacity(candidates.count)

    for candidate in candidates {
      let centerBPM = candidate.bpm
      let scanMin = max(Double(bpmRange.lowerBound), centerBPM - 4.0)
      let scanMax = min(Double(bpmRange.upperBound), centerBPM + 4.0)

      // Use integer step counter to avoid floating-point accumulation drift
      let stepCount = Int(((scanMax - scanMin) / stepSize).rounded()) + 1
      guard stepCount >= 1 else {
        refined.append((bpm: centerBPM, score: candidate.score))
        continue
      }

      // Pass 1: collect tempogram magnitude + parabolic-interpolated ACF at each scan point.
      var tempogramScores = [Float](repeating: 0, count: stepCount)
      var acfScores = [Float](repeating: 0, count: stepCount)
      for step in 0..<stepCount {
        let scanBPM = scanMin + Double(step) * stepSize
        let tMag = tempogramMagnitude(
          bpm: scanBPM, windowed: windowedPtr, windowLength: windowLength,
          onsetRate: onsetRate, buffers: buffers)
        let lag = 60.0 * onsetRate / scanBPM
        let acfVal = parabolicInterpolateACF(autocorrelation, at: lag)
        tempogramScores[step] = tMag
        acfScores[step] = acfVal
      }

      // Local max-normalization (matches fusePeriodicity coarse-stage behavior)
      let tMax = tempogramScores.max() ?? 0
      let aMax = acfScores.max() ?? 0

      // Pass 2: compute fused scores into a parallel array so post-scan logic
      // can read winner-neighbor values after the scan completes.
      var fusedScores = [Float](repeating: 0, count: stepCount)
      var bestFused: Float = 0
      var winnerIdx = -1
      for i in 0..<stepCount {
        let normT = tMax > 0 ? tempogramScores[i] / tMax : 0
        let normA = aMax > 0 ? acfScores[i] / aMax : 0
        let fusedVal = normT * normA
        fusedScores[i] = fusedVal
        // Strict `>` preserves "first to achieve maximum wins" semantics; the
        // tie-run handler below corrects the residual low-end plateau bias.
        if fusedVal > bestFused {
          bestFused = fusedVal
          winnerIdx = i
        }
      }

      // Preserve original behavior: if no scan point scored a positive fused
      // value (e.g., negative ACF overshoot dominates the window), return the
      // original center BPM unchanged.
      guard winnerIdx >= 0 else {
        refined.append((bpm: centerBPM, score: candidate.score))
        continue
      }

      // Detect a flat fused plateau around the winner with a relative epsilon.
      // Strict-`>` already excludes earlier indices from achieving bestFused
      // exactly; near-ties from Float quantization on adjacent indices count
      // toward the plateau. Bounds are computed eagerly but consumed only after
      // the override gate is evaluated — the override path takes precedence
      // over the plateau short-circuit when both apply.
      let absMax = max(abs(bestFused), Float(1e-30))
      let plateauEps: Float = max(Float(1e-6), Float(1e-6) * absMax)
      var lo = winnerIdx
      while lo > 0 && abs(fusedScores[lo - 1] - bestFused) <= plateauEps {
        lo -= 1
      }
      var hi = winnerIdx
      while hi < stepCount - 1 && abs(fusedScores[hi + 1] - bestFused) <= plateauEps {
        hi += 1
      }
      let hasPlateau = hi > lo

      // Tempogram local-peak search within ±tempogramSearchSteps of the fused
      // winner. Run unconditionally so the override gate can be evaluated even
      // when a fused plateau is present.
      let searchLo = max(1, winnerIdx - tempogramSearchSteps)
      let searchHi = min(stepCount - 2, winnerIdx + tempogramSearchSteps)
      var tempogramPeakIdx = -1
      var tempogramPeakValue: Float = 0
      if searchLo <= searchHi {
        for i in searchLo...searchHi {
          let v = tempogramScores[i]
          if v > tempogramScores[i - 1] && v > tempogramScores[i + 1]
            && v > tempogramPeakValue
          {
            tempogramPeakValue = v
            tempogramPeakIdx = i
          }
        }
      }

      let centerIdx = Int(((centerBPM - scanMin) / stepSize).rounded())

      // Override gate (all three required):
      //   (a) |T - F| ≥ tempogramOverrideDistance (≥ overrideMinDisagreementBPM)
      //       — tempogram and fused disagree about peak location.
      //   (b) |F - C| ≥ fusedDisplacementThreshold (≥ overrideMinFusedOffsetBPM)
      //       — fused is displaced from the integer coarse-pipeline center.
      //   (c) |T - C| < |F - C| — tempogram is strictly closer to the coarse
      //       center than fused is. The override must improve center agreement,
      //       not merely avoid worsening it.
      //
      // The synthetic 126 BPM case satisfies all three (fused at i=36,
      // tempogram at i=40, center at i=40 ⇒ |T-F|=4, |F-C|=4, |T-C|=0 < 4).
      // Real tracks with significant fused-vs-coarse displacement (e.g.,
      // Icicle in the DAW oracle) can also trigger the override; the gate
      // identifies the displacement signature, not synthesis-vs-real.
      let useTempogramOverride =
        tempogramPeakIdx >= 0
        && abs(tempogramPeakIdx - winnerIdx) >= tempogramOverrideDistance
        && abs(winnerIdx - centerIdx) >= fusedDisplacementThreshold
        && abs(tempogramPeakIdx - centerIdx) < abs(winnerIdx - centerIdx)

      // Fused-winner discrete BPM, clamped to the scan window. Used as the
      // common fallback for both the override and default refinement paths.
      let fusedFallbackBPM =
        min(max(scanMin + Double(winnerIdx) * stepSize, scanMin), scanMax)

      // Dispatch in priority order: override beats plateau beats default.
      if useTempogramOverride {
        // Override path: quadratic fit on tempogramScores at tempogramPeakIdx.
        // On any guard failure (edge / non-concave / |offset| > 1) fall back
        // to the FUSED winner's discrete BPM — not the tempogram peak's.
        let bpm = quadraticPeakBPM(
          scores: tempogramScores, idx: tempogramPeakIdx,
          scanMin: scanMin, scanMax: scanMax, stepSize: stepSize,
          stepCount: stepCount, onFailure: fusedFallbackBPM)
        refined.append((bpm: bpm, score: candidate.score))
        continue
      }

      if hasPlateau {
        // Flat-plateau case: midpoint and short-circuit (no quadratic fit).
        // Clamp guards against Double quantization drift on the integer grid.
        let midIdx = Double(lo + hi) * 0.5
        let mid = scanMin + midIdx * stepSize
        refined.append(
          (bpm: min(max(mid, scanMin), scanMax), score: candidate.score))
        continue
      }

      // Default fused path: quadratic fit on fused scores at the fused winner.
      let bpm = quadraticPeakBPM(
        scores: fusedScores, idx: winnerIdx,
        scanMin: scanMin, scanMax: scanMax, stepSize: stepSize,
        stepCount: stepCount, onFailure: fusedFallbackBPM)
      refined.append((bpm: bpm, score: candidate.score))
    }

    return refined
  }

  /// 3-point quadratic peak fit on `scores[idx-1..idx+1]`, returning a refined
  /// BPM clamped to `[scanMin, scanMax]`. Falls back to `onFailure` on any of:
  /// - **Edge guard**: `idx` at the scan-window boundary (no 3-point stencil).
  /// - **Concavity guard**: `denom < -epsD` (downward-curving parabola) not
  ///   satisfied. Positive `denom` is a valley/inflection; near-zero `denom`
  ///   is a flat plateau where the parabolic-fit offset is unstable.
  /// - **Conditioning guard**: `|offset| > 1` indicates the fit's apex falls
  ///   beyond the immediate neighbors (poorly conditioned).
  ///
  /// `epsD` is a relative epsilon scaled by `magnitudeMax` with a `1e-6` floor
  /// (above Float ULP noise on unit-normalized fused scores).
  ///
  /// 7 parameters (vs SwiftLint's default 5) is intentional: the scan-window
  /// triplet (`scanMin`, `scanMax`, `stepCount`) plus `stepSize` are all
  /// per-candidate locals already; bundling them into a struct here would add
  /// boilerplate without clarity at the single call site.
  private static func quadraticPeakBPM(  // swiftlint:disable:this function_parameter_count
    scores: [Float],
    idx: Int,
    scanMin: Double,
    scanMax: Double,
    stepSize: Double,
    stepCount: Int,
    onFailure: Double
  ) -> Double {
    if idx <= 0 || idx >= stepCount - 1 {
      return onFailure
    }
    let yPrev = Double(scores[idx - 1])
    let y0 = Double(scores[idx])
    let yNext = Double(scores[idx + 1])
    let denom = yPrev - 2.0 * y0 + yNext
    let magnitudeMax = max(abs(yPrev), abs(y0), abs(yNext))
    let epsD = max(1e-6, 1e-6 * magnitudeMax)
    guard denom < -epsD else { return onFailure }
    let offset = 0.5 * (yPrev - yNext) / denom
    guard abs(offset) <= 1.0 else { return onFailure }
    let bpm0 = scanMin + Double(idx) * stepSize
    let unclamped = bpm0 + offset * stepSize
    return min(max(unclamped, scanMin), scanMax)
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

    return withUnsafeTemporaryAllocation(of: Float.self, capacity: candidateCount) { acfBPM in
      // Zero the buffer (contents are uninitialized)
      vDSP_vclr(acfBPM.baseAddress!, 1, vDSP_Length(candidateCount))

      // Map autocorrelation from lag-domain to BPM-domain with parabolic interpolation
      // (Epic 34, C1: eliminates picket fence effect at 0.5 fractional lag positions)
      for i in 0..<candidateCount {
        let bpm = Double(bpmMin + i)
        let lag = 60.0 * onsetRate / bpm
        acfBPM[i] = parabolicInterpolateACF(autocorrelation, at: lag)
      }

      // Normalize both to [0, 1]
      var acfMax: Float = 0
      vDSP_maxv(acfBPM.baseAddress!, 1, &acfMax, vDSP_Length(candidateCount))
      if acfMax > 0 {
        vDSP_vsdiv(
          acfBPM.baseAddress!, 1, &acfMax, acfBPM.baseAddress!, 1, vDSP_Length(candidateCount))
      }

      var tempogramNorm = fourierTempogram
      var tMax: Float = 0
      vDSP_maxv(tempogramNorm, 1, &tMax, vDSP_Length(candidateCount))
      if tMax > 0 {
        vDSP_vsdiv(tempogramNorm, 1, &tMax, &tempogramNorm, 1, vDSP_Length(candidateCount))
      }

      // Element-wise multiply: peaks strong in BOTH survive
      var fused = [Float](repeating: 0, count: candidateCount)
      vDSP_vmul(acfBPM.baseAddress!, 1, tempogramNorm, 1, &fused, 1, vDSP_Length(candidateCount))

      return fused
    }
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

  // MARK: - Octave Disambiguation (Story 33-5, Task 6; updated Story 33-6, Task 4; updated Story 3-1)
  // HarmonicRatioEvidence is defined publicly in BPMDiagnosticTrace.swift (relocated by Story 3-3b).

  /// Resolves harmonic ambiguity between candidates using sub-band voting
  /// (when available) and fused periodicity heuristic.
  /// Handles 2:1 (octave), 3:2 (triplet), and 3:1 ratios.
  /// Returns typed evidence for the highest-priority detected pair.
  static func resolveOctaveAmbiguity(
    candidates: [(bpm: Double, score: Float)],
    fused: [Float],
    bpmMin: Int,
    subBandACFs: [[Float]] = [],
    onsetRate: Double = 0
  ) -> (best: (bpm: Double, score: Float), evidence: HarmonicRatioEvidence?) {
    guard candidates.count >= 2 else {
      return (best: candidates.first ?? (bpm: 0, score: 0), evidence: nil)
    }

    var best = candidates[0]
    var evidence: HarmonicRatioEvidence?

    for i in 0..<candidates.count {
      for j in (i + 1)..<candidates.count {
        let faster = candidates[i].bpm > candidates[j].bpm ? candidates[i] : candidates[j]
        let slower = candidates[i].bpm > candidates[j].bpm ? candidates[j] : candidates[i]

        let ratio = faster.bpm / slower.bpm

        if ratio > 1.92 && ratio < 2.08 {
          // 2:1 octave pair
          if subBandACFs.count == 4 && onsetRate > 0 {
            let winner = subBandVote(
              subBandACFs: subBandACFs,
              candidateFast: faster.bpm,
              candidateSlow: slower.bpm,
              onsetRate: onsetRate)
            if winner == faster.bpm {
              best = faster
              evidence = HarmonicRatioEvidence(
                ratio: "2:1", fastBPM: faster.bpm,
                slowBPM: slower.bpm, winnerBPM: faster.bpm)
              continue
            }
          }

          // Fallback: fused-periodicity heuristic (calibrated for 2:1 only)
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
                evidence = HarmonicRatioEvidence(
                  ratio: "2:1", fastBPM: faster.bpm,
                  slowBPM: slower.bpm, winnerBPM: faster.bpm)
              }
            }
          }

        } else if ratio > 1.45 && ratio < 1.55 {
          // 3:2 triplet pair — trace-only, does not modify best
          if evidence == nil || evidence?.ratio == "3:1" {
            evidence = HarmonicRatioEvidence(
              ratio: "3:2", fastBPM: faster.bpm,
              slowBPM: slower.bpm, winnerBPM: best.bpm)
          }

        } else if ratio > 2.85 && ratio < 3.15 {
          // 3:1 ratio pair — trace-only, does not modify best
          if evidence == nil {
            evidence = HarmonicRatioEvidence(
              ratio: "3:1", fastBPM: faster.bpm,
              slowBPM: slower.bpm, winnerBPM: best.bpm)
          }

        } else {
          continue
        }
      }
    }

    return (best: best, evidence: evidence)
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

  // MARK: - Click-Track Cross-Correlation (Story 3-3)

  /// Reads `CLICK_RESCORE_ALPHA_OVERRIDE` env var as `Float` for the Story 3-3 Task 3.3
  /// α-sweep. Returns `nil` when unset / unparseable / out of `[0, 1]`. Test-only hook.
  ///
  /// Gated by `#if DEBUG` so Release builds CANNOT have BPM results silently mutated
  /// by a process env var (Story 3-3 review patch P2 / Codex Blind-Hunter finding).
  private static func alphaOverride() -> Float? {
    #if DEBUG
      guard let raw = ProcessInfo.processInfo.environment["CLICK_RESCORE_ALPHA_OVERRIDE"],
        let value = Float(raw),
        value >= 0, value <= 1
      else {
        return nil
      }
      return value
    #else
      return nil
    #endif
  }

  /// Synthesizes an envelope-rate click kernel for normalized cross-correlation.
  ///
  /// The kernel is `clickCount` unit impulses spaced at `60 · onsetRate / bpm` frames.
  /// Indices are computed via `Int((Double(k) * period).rounded())` for `k ∈ 0..<clickCount`,
  /// then the array is sized to `indices.last! + 1` so every write is in bounds (DD#8;
  /// the older `Int(period * (clickCount - 1)) + 1` formula could yield `index == length`
  /// for fractional periods like 60/61 · 100 = 98.36...).
  ///
  /// **Visibility is `internal static`**: tests in `BoomBoomBoomKitTests` use
  /// `@testable import BoomBoomBoomKit` to call this directly (DD#5).
  ///
  /// Guards: returns empty `[Float]` when `bpm <= 0`, `!bpm.isFinite`, `onsetRate <= 0`,
  /// `clickCount < 4`, or `period < 1.0` (BPMs > 6000 alias at 100 Hz onset rate).
  /// The caller treats an empty kernel as "skip rescoring for this candidate; preserve
  /// the original score" (combined with DD#13b uniform-skip in `clickRescore`).
  ///
  /// - Parameters:
  ///   - bpm: Candidate beats-per-minute.
  ///   - onsetRate: Onset envelope frame rate (sampleRate / hopSize ≈ 100 Hz).
  ///   - clickCount: Number of unit impulses (default 8, minimum 4).
  /// - Returns: Click kernel as `[Float]` of length `lastIndex + 1`, or empty on guard hit.
  internal static func synthesizeClickPattern(
    bpm: Double,
    onsetRate: Double,
    clickCount: Int = 8
  ) -> [Float] {
    guard bpm > 0, bpm.isFinite, onsetRate > 0, onsetRate.isFinite, clickCount >= 4 else {
      return []
    }
    let period = 60.0 * onsetRate / bpm
    guard period >= 1.0 else { return [] }

    // Compute indices first, then size the array to indices.last! + 1 (DD#8).
    let indices = (0..<clickCount).map { Int((Double($0) * period).rounded()) }
    guard let last = indices.last else { return [] }
    let length = last + 1
    var pattern = [Float](repeating: 0, count: length)
    for idx in indices {
      pattern[idx] = 1.0
    }
    return pattern
  }

  /// Rescore candidates by normalized cross-correlation between a synthetic click
  /// kernel at each candidate BPM and the onset envelope.
  ///
  /// Per-candidate score: `oldScore * (alpha + (1 - alpha) * bestNCC)` where
  /// `bestNCC = max over lags ℓ of dot(kernel, envelope[ℓ:ℓ+L]) / (||kernel||₂ · ||envelope[ℓ:ℓ+L]||₂)`,
  /// bounded in `[0, 1]` by Cauchy–Schwarz. The blend always damps (multiplier ≤ 1) —
  /// it never boosts the absolute score; it tempers candidates that fail the
  /// rhythmic-alignment check while preserving most of the upstream-calibrated ordering.
  ///
  /// **Sparse normalized beat-search** (DD#6): the kernel is overwhelmingly zeros (8
  /// unit impulses among ~480 frames at 60 BPM × 100 Hz). The inner loop iterates the
  /// small `clickIndices` array (size = `clickCount`, default 8) — not a loop over
  /// the signal buffer. The equivalent dense `vDSP_conv` path passes the kernel as-is
  /// with `IF = +1` per `vDSP.h:2328` (correlation when `IF > 0`; pre-reversal would
  /// silently invert the operation back to convolution).
  ///
  /// **Uniform-skip guard** (DD#13b): if ANY candidate's kernel doesn't fit the
  /// envelope (`outputLen <= 0`), the function returns `candidates` unchanged for the
  /// ENTIRE candidate set. Skipping only the offending candidate would advantage it
  /// (its `oldScore × 1.0` would compete with rescored values < 1).
  ///
  /// **Zero-energy guard** (DD#13a): per-lag, if `||envelope[ℓ:ℓ+L]||₂ == 0`, the lag
  /// is skipped (treated as score 0).
  ///
  /// Trace population: when `trace` is non-nil, sets `clickCorrelationDetail` to
  /// one ``ClickCorrelationEntry`` per candidate, preserving the input-order
  /// `candidateIndex`, full-precision `bpm`, and normalized click score.
  ///
  /// **Visibility is `internal static`** (DD#5): tests use `@testable import` to call
  /// this directly.
  ///
  /// - Parameters:
  ///   - candidates: Pre-disambiguation candidates `(bpm, score)`.
  ///   - onsetEnvelope: Full-band onset envelope at `onsetRate` Hz.
  ///   - onsetRate: Onset envelope frame rate.
  ///   - alpha: Damping floor in `[0, 1]` (default 0.7, finalized by Task 3.3 α-sweep).
  ///   - trace: Optional diagnostic trace; populates `clickCorrelationDetail`.
  /// - Returns: Rescored candidates, sorted descending by score with stable index tiebreaker.
  internal static func clickRescore(
    candidates: [(bpm: Double, score: Float)],
    onsetEnvelope: [Float],
    onsetRate: Double,
    alpha: Float = 0.7,
    trace: inout BPMDiagnosticTrace?
  ) -> [(bpm: Double, score: Float)] {
    guard !candidates.isEmpty, !onsetEnvelope.isEmpty else { return candidates }

    // Defensive clamp: alpha must be in [0, 1] to preserve the "blend always damps"
    // invariant promised in the doc-comment. Direct internal callers (tests, future
    // ablation hooks) could pass out-of-range values; clamp instead of trapping so
    // the pipeline degrades gracefully.
    let alpha = max(Float(0), min(alpha, Float(1)))

    // Pre-flight: synthesize all kernels and check that every candidate's kernel
    // fits the envelope. Uniform-skip if ANY kernel is empty or doesn't fit (DD#13b).
    var kernels: [[Float]] = []
    kernels.reserveCapacity(candidates.count)
    for cand in candidates {
      let kernel = synthesizeClickPattern(bpm: cand.bpm, onsetRate: onsetRate)
      if kernel.isEmpty || onsetEnvelope.count < kernel.count {
        return candidates
      }
      kernels.append(kernel)
    }

    // Cumulative sum-of-squares of the envelope (one O(N) pass), reused across candidates.
    let envCount = onsetEnvelope.count
    var sq = [Float](repeating: 0, count: envCount)
    vDSP.square(onsetEnvelope, result: &sq)
    var cumSumSq = [Float](repeating: 0, count: envCount + 1)
    var running: Float = 0
    for i in 0..<envCount {
      running += sq[i]
      cumSumSq[i + 1] = running
    }

    // Per-candidate sparse normalized beat-search.
    var newScores: [Float] = []
    newScores.reserveCapacity(candidates.count)
    let writeTrace = trace != nil
    var entries: [ClickCorrelationEntry] = []
    if writeTrace { entries.reserveCapacity(candidates.count) }

    for (idx, cand) in candidates.enumerated() {
      let kernel = kernels[idx]
      let kernelLength = kernel.count
      let outputLen = envCount - kernelLength + 1
      // outputLen > 0 by pre-flight — but defensively guard anyway.
      guard outputLen > 0 else { return candidates }

      // Click indices (where kernel is non-zero).
      var clickIndices: [Int] = []
      clickIndices.reserveCapacity(kernel.count)
      for k in 0..<kernelLength where kernel[k] != 0 {
        clickIndices.append(k)
      }
      guard !clickIndices.isEmpty else {
        newScores.append(cand.score * alpha)
        if writeTrace {
          entries.append(
            ClickCorrelationEntry(candidateIndex: idx, bpm: cand.bpm, normalizedClickScore: 0))
        }
        continue
      }

      // Kernel L2 norm via vDSP_svesq (handles future tapered kernels too).
      var kernelSumSq: Float = 0
      kernel.withUnsafeBufferPointer { kPtr in
        vDSP_svesq(kPtr.baseAddress!, 1, &kernelSumSq, vDSP_Length(kernelLength))
      }
      let kernelL2 = sqrtf(kernelSumSq)
      guard kernelL2 > 0 else {
        newScores.append(cand.score * alpha)
        if writeTrace {
          entries.append(
            ClickCorrelationEntry(candidateIndex: idx, bpm: cand.bpm, normalizedClickScore: 0))
        }
        continue
      }

      var bestNCC: Float = 0
      onsetEnvelope.withUnsafeBufferPointer { envPtr in
        let env = envPtr.baseAddress!
        for lag in 0..<outputLen {
          var dot: Float = 0
          for offset in clickIndices {
            dot += env[lag + offset]
          }
          let segSumSq = cumSumSq[lag + kernelLength] - cumSumSq[lag]
          guard segSumSq > 0 else { continue }  // DD#13a zero-energy guard.
          let segL2 = sqrtf(segSumSq)
          let ncc = dot / (kernelL2 * segL2)
          if ncc > bestNCC { bestNCC = ncc }
        }
      }

      // Clamp bestNCC to [0, 1]. Cauchy-Schwarz guarantees this mathematically, but
      // FP rounding can push it slightly above 1.0 or produce non-finite values when
      // the envelope contains pathological data. Clamping protects the damping invariant.
      let clampedNCC = bestNCC.isFinite ? max(Float(0), min(bestNCC, Float(1))) : 0
      newScores.append(cand.score * (alpha + (1.0 - alpha) * clampedNCC))
      if writeTrace {
        entries.append(
          ClickCorrelationEntry(
            candidateIndex: idx, bpm: cand.bpm, normalizedClickScore: clampedNCC))
      }
    }

    if writeTrace {
      trace?.clickCorrelationDetail = entries
    }

    // Sort with explicit index tiebreaker for determinism (Swift Array.sort is not stable).
    let zipped: [(offset: Int, bpm: Double, newScore: Float)] = candidates.enumerated().map {
      (offset: $0.offset, bpm: $0.element.bpm, newScore: newScores[$0.offset])
    }
    let sorted = zipped.sorted { lhs, rhs in
      lhs.newScore != rhs.newScore ? lhs.newScore > rhs.newScore : lhs.offset < rhs.offset
    }
    return sorted.map { (bpm: $0.bpm, score: $0.newScore) }
  }

  // MARK: - Duration-Derived BPM Hint (Story 3-4, Step 9.7)

  /// Computes structurally-plausible BPMs from common bar counts at a given file duration.
  ///
  /// For each bar count `B` in `durationHintBarCounts`, the corresponding BPM is
  /// `B * 4 * 60 / durationSeconds` (assumes 4/4 time, 4 beats per bar). Only BPMs
  /// falling within the perceptual range (`60...200`) are returned. Out-of-range
  /// pairs are silently dropped — the helper degrades gracefully on very short and
  /// very long files (per AC #3c).
  ///
  /// When `durationSeconds < minFileSeconds`, returns `[]` immediately because
  /// bar-count math is only meaningful when the file is a full song (clips fail
  /// the structural assumption).
  ///
  /// Internal (not private) so unit tests can exercise it directly via `@testable
  /// import BoomBoomBoomKit`.
  ///
  /// - Parameters:
  ///   - durationSeconds: Full file duration in seconds (NOT analysis-window duration —
  ///     bar-count math is only musically meaningful at file-level scale).
  ///   - minFileSeconds: Threshold below which the helper returns `[]`. Defaults to
  ///     `durationHintMinFileSecondsDefault` (180s). Pass `0` in tests that exercise
  ///     the bar-count math itself rather than the threshold gate.
  /// - Returns: Pairs of `(bars, bpm)` whose `bpm` lies within the perceptual range.
  static func applyDurationHintBarCounts(
    durationSeconds: Double,
    minFileSeconds: Double = durationHintMinFileSecondsDefault
  ) -> [(bars: Int, bpm: Double)] {
    guard durationSeconds > 0, durationSeconds.isFinite else { return [] }
    // NaN / Inf threshold falls back to the documented default; negative threshold
    // clamps to 0 ("no minimum"). Validates code-review Patch #6 (Story 3-4).
    let effectiveMin: Double =
      minFileSeconds.isFinite ? max(0, minFileSeconds) : durationHintMinFileSecondsDefault
    guard durationSeconds >= effectiveMin else { return [] }
    var result: [(bars: Int, bpm: Double)] = []
    result.reserveCapacity(durationHintBarCounts.count)
    for bars in durationHintBarCounts {
      let bpm = Double(bars) * 4.0 * 60.0 / durationSeconds
      if bpm >= perceptualMinBPM && bpm <= perceptualMaxBPM {
        result.append((bars: bars, bpm: bpm))
      }
    }
    return result
  }

  /// Applies the duration-derived BPM hint to a candidate set: any candidate whose BPM
  /// matches a structurally-plausible bar-count-derived BPM (within the relative
  /// tolerance) has its score multiplied by `1 + durationHintBoostWeight` exactly once
  /// (no compounding when multiple bar counts match).
  ///
  /// Corroborative-not-authoritative: unmatched candidates are NEVER damped — distinct
  /// from click rescore's blend, which damps when NCC < 1.
  ///
  /// Trace population (when `trace` is non-nil): always populates all three fields of
  /// `DurationHintEvidence` when the helper runs (even if no boost fires) so the
  /// diagnostic distinguishes "feature off" (`trace?.durationHintDetail == nil`) from
  /// "feature on but no in-range bars"
  /// (`trace?.durationHintDetail?.barCandidates.isEmpty == true`).
  ///
  /// Internal (not private) so unit tests can exercise it directly via `@testable
  /// import BoomBoomBoomKit` — same access pattern as `clickRescore` and `subBandVote`.
  ///
  /// - Parameters:
  ///   - candidates: Pre-hint candidate array (typically the output of step 9b
  ///     click rescore, or the raw extraction when click rescore is inactive).
  ///   - fileDurationSeconds: Full file duration in seconds.
  ///   - minFileSeconds: Threshold below which the helper produces no boosts (clip
  ///     vs full-song gate). Defaults to `durationHintMinFileSecondsDefault` (180s).
  ///   - trace: Diagnostic trace inout — populated when non-nil.
  /// - Returns: Boosted candidates sorted descending by score with a tiebreaker on
  ///   original index (deterministic per Story 3-3 DD#6).
  static func applyDurationHint(
    candidates: [(bpm: Double, score: Float)],
    fileDurationSeconds: Double,
    minFileSeconds: Double = durationHintMinFileSecondsDefault,
    trace: inout BPMDiagnosticTrace?
  ) -> [(bpm: Double, score: Float)] {
    let barCandidates = applyDurationHintBarCounts(
      durationSeconds: fileDurationSeconds, minFileSeconds: minFileSeconds)

    // Trace: always set fileDurationSeconds and barCandidates when the helper runs.
    let writeTrace = trace != nil

    // Compute boosted scores (per-candidate idempotent boost).
    let boostMultiplier = 1.0 + durationHintBoostWeight
    var boostedBPMs: [Double] = []
    var newScores: [Float] = []
    newScores.reserveCapacity(candidates.count)
    for cand in candidates {
      let matched = barCandidates.contains {
        abs(cand.bpm - $0.bpm) / $0.bpm <= durationHintTolerance
      }
      if matched {
        newScores.append(cand.score * boostMultiplier)
        boostedBPMs.append(cand.bpm)
      } else {
        newScores.append(cand.score)
      }
    }

    if writeTrace {
      let typedBars = barCandidates.map { BarCandidate(bars: $0.bars, bpm: $0.bpm) }
      trace?.durationHintDetail = DurationHintEvidence(
        fileDurationSeconds: fileDurationSeconds,
        barCandidates: typedBars,
        boostedCandidates: boostedBPMs)
    }

    // No-op guard (code-review Patch #1, Story 3-4): when no candidate matched a
    // bar-count BPM, every entry of `newScores` equals the input score, so re-sorting
    // could only reorder previously-equal scores. AC #3 contracts that "the original
    // candidates array flows unchanged" on no-op paths — preserve input order verbatim.
    if boostedBPMs.isEmpty { return candidates }

    // Sort with explicit tiebreaker on original index for determinism.
    // Non-finite-score handling (code-review Patch #2): NaN scores break the comparator
    // because both `NaN > x` and `NaN < x` are false AND `NaN != x` is true, so the
    // offset tiebreaker would never fire — non-deterministic. Branch on `isNaN` first so
    // NaN scores rank below all real scores, then the offset tiebreaker resolves ties
    // (including NaN-vs-NaN). `+Inf` follows normal IEEE 754 ordering — it ranks
    // legitimately at the top, not as a defensive demotion.
    let zipped: [(offset: Int, bpm: Double, newScore: Float)] = candidates.enumerated().map {
      (offset: $0.offset, bpm: $0.element.bpm, newScore: newScores[$0.offset])
    }
    let sorted = zipped.sorted { lhs, rhs in
      if lhs.newScore.isNaN != rhs.newScore.isNaN { return !lhs.newScore.isNaN }
      if !lhs.newScore.isNaN && lhs.newScore != rhs.newScore {
        return lhs.newScore > rhs.newScore
      }
      return lhs.offset < rhs.offset
    }
    return sorted.map { (bpm: $0.bpm, score: $0.newScore) }
  }
}
