//
//  BPMDiagnosticTrace.swift
//  BoomBoomBoomKit
//
//  Captures intermediate pipeline state for diagnostic analysis.
//  Evolving API — fields may change across versions.
//

import Foundation

/// Diagnostic trace capturing intermediate state from each BPM pipeline step.
///
/// Populated when `enableTrace: true` is passed to `analyzeBPM`.
/// This is an evolving API — fields may change across library versions.
public struct BPMDiagnosticTrace: Sendable {

  // MARK: - Step 1: Energy Scan

  /// Sample offset where energy transition was detected (analysis starts here).
  public var energyTransitionOffset: Int = 0

  /// Actual analysis window duration in seconds.
  public var analysisWindowDuration: Double = 0

  // MARK: - Step 3: Onset Detection

  /// Frame count of the computed onset envelope.
  public var onsetEnvelopeLength: Int = 0

  /// Maximum onset-envelope energy per drum sub-band (kick, snare, crack,
  /// hihat). Equals ``SubBandEnergies/zero`` when sub-band computation was
  /// skipped (intensity 1-2 or `subBandVoting` not in the active technique
  /// set). See ``SubBandEnergies`` for shape rationale.
  public var subBandEnergies: SubBandEnergies = .zero

  // MARK: - Step 4: Autocorrelation

  /// Top ACF peaks before fusion (lag in frames, strength).
  public var acfTopLags: [(lag: Int, strength: Float)] = []

  // MARK: - Step 5: Tempogram

  /// Top tempogram peaks (BPM, magnitude).
  public var tempogramTopBPMs: [(bpm: Int, magnitude: Float)] = []

  // MARK: - Step 6: Periodicity Fusion

  /// Top fused periodicity peaks (BPM, score).
  public var fusedTopBPMs: [(bpm: Int, score: Float)] = []

  // MARK: - Step 7: TPS2 Enhancement

  /// Top peaks after TPS2 (harmonic) enhancement (BPM, score).
  public var tps2TopBPMs: [(bpm: Int, score: Float)] = []

  // MARK: - Steps 8-9: Candidate Extraction

  /// Candidates before disambiguation (BPM, normalized score).
  public var rawCandidates: [(bpm: Double, score: Float)] = []

  // MARK: - Step 10: Disambiguation

  /// Winning candidate after octave resolution (BPM, score).
  public var disambiguationResult: (bpm: Double, score: Float) = (0, 0)

  /// Sub-band voting decision recorded at Step 10b.
  /// Nil when sub-band voting was skipped.
  public var subBandVoteDetail: SubBandVoteEvidence?

  /// Harmonic-ratio evidence for the deciding pair in disambiguation
  /// (2:1 octave, 3:2 triplet, or 3:1 trace-only pair).
  /// Nil when no harmonic-ratio pair was detected.
  public var harmonicRatioDetail: HarmonicRatioEvidence?

  // MARK: - Step 9.5: Click-Track Cross-Correlation

  /// Per-candidate normalized click correlation score (pre-blend, in `[0, 1]`).
  /// Each entry carries the original candidate index, its BPM at full `Double`
  /// precision, and the normalized
  /// `bestNCC = max over lags of dot(kernel, envelope[ℓ:ℓ+L]) / (||kernel||₂ · ||envelope[ℓ:ℓ+L]||₂)`.
  ///
  /// Populated only when `enableTrace: true` AND `.clickTrackCorrelation` is in the technique set.
  /// Nil when the technique was skipped. Entries are emitted in input order, so
  /// `entries.map(\.candidateIndex) == Array(0..<entries.count)` with no gaps.
  public var clickCorrelationDetail: [ClickCorrelationEntry]?

  // MARK: - Step 9.7: Duration-Derived BPM Hint (Story 3-4)

  /// Diagnostic detail for the duration-derived BPM hint at step 9.7.
  ///
  /// Carries:
  /// - `fileDurationSeconds`: file duration at full `Double` precision.
  /// - `barCandidates`: bar-count candidates whose corresponding BPM fell within `60...200`
  ///   BPM. Empty when no bar count yields an in-range BPM (very short clips).
  /// - `boostedCandidates`: DSP candidate BPMs that received the multiplicative boost.
  ///   Empty when no candidate matched any in-range bar BPM within the relative tolerance.
  ///
  /// Populated only when `enableTrace: true` AND the helper actually ran (i.e.,
  /// `BPMAnalyzer.Options.fileDurationSeconds != nil`, which in turn requires
  /// `AudioAnalysisService.Options.durationHint == true` for the public path).
  /// Nil when the hint did not run — distinguishes "feature off" from "feature on
  /// but no bar candidates landed in range".
  public var durationHintDetail: DurationHintEvidence?

  // MARK: - Step 10c: Fine-Grid Refinement

  /// Refined BPM after fine-grid DFT. Nil when fine-grid was skipped.
  public var refinedBPM: Double?

  // MARK: - Final

  /// Final confidence score.
  public var confidence: Double = 0

  /// Intensity level that produced this trace.
  public var intensityUsed: AnalysisIntensity = .default

  // MARK: - Story 3.6: Metadata Corroboration

  /// Per-source observations as fed into ``MetadataCorroborator/apply(to:input:)``
  /// — i.e., parse-phase outcome only (`corroboratedWith == nil`,
  /// `boostApplied == 1.0`, parse rejections set). Empty when
  /// ``AudioAnalysisService/Options/metadataPolicy`` is ``MetadataPolicy/disabled``
  /// or no enabled-source tag was present.
  public var metadataEvidenceBeforeBoost: [MetadataBPMEvidence] = []

  /// Candidate pool (BPM, score) snapshot taken just before the corroborator
  /// applied any score multipliers — i.e., the merged DSP candidates as
  /// returned by ``CandidateMergeStrategy/merge(windowResults:candidateCount:strategy:votingPolicy:votingThreshold:)``.
  public var candidatesBeforeBoost: [(bpm: Double, score: Float)] = []

  /// Candidate pool after the corroborator multiplied matching candidates'
  /// scores by ``MetadataPolicy/corroborationBoost``. Equal to
  /// ``candidatesBeforeBoost`` when no candidates matched any tag.
  public var candidatesAfterBoost: [(bpm: Double, score: Float)] = []

  /// The metadata policy that produced this trace.
  public var metadataPolicyUsed: MetadataPolicy = .default

  // MARK: - Story 4.4: Ensemble Decision

  /// Diagnostic record of how ``EnsembleCombiner/combine(dspWinner:mlEvaluation:policy:)``
  /// resolved the post-corroboration DSP candidate against an
  /// ``MLEvaluation``. Populated when ``MLTechnique/evaluate(trace:)``
  /// returned a non-nil ``MLEvaluation``; otherwise `nil` (including under
  /// ``EnsemblePolicy/dspOnly``, where the evaluation never runs).
  /// See ``EnsembleDecision`` for the population matrix.
  public var ensembleDecision: EnsembleDecision?

  // MARK: - Story 4.5: ML Feature Frames

  /// Log-mel spectrogram frames retained from the DSP onset pipeline,
  /// fed into ``MLTechnique/evaluate(trace:)`` as the model input. The
  /// library populates this lazily (only when `Options.mlTechnique != nil`
  /// AND `Options.ensemblePolicy != .dspOnly` AND `Options.enableTrace`)
  /// to keep the DSP-only path zero-cost.
  ///
  /// See ``MLFeatureFrames`` for the typed-evidence shape + semantic
  /// metadata that disambiguates the tensor's contract.
  public var mlFeatures: MLFeatureFrames?
}

// MARK: - Trace Evidence Types (Story 3-3b)

/// Per-candidate click-track cross-correlation result emitted by
/// ``BPMDiagnosticTrace/clickCorrelationDetail`` at Step 9.5.
///
/// Replaces a legacy `[String: Float]` keyed by `String(format: "%.1f", bpm)`
/// — that shape collapsed distinct candidates whose BPMs rounded to the same
/// one-decimal label (e.g., `61.04` and `60.95` → `"61.0"`). Each candidate
/// is now an independent entry with full `Double` BPM precision.
public struct ClickCorrelationEntry: Sendable, CustomStringConvertible {

  /// Original index of this candidate in the input array passed to
  /// `BPMAnalyzer.clickRescore`. Entries are emitted in input order, so
  /// `entries.map(\.candidateIndex)` is `[0, 1, 2, …]` with no gaps.
  public let candidateIndex: Int

  /// Candidate BPM at full `Double` precision (no `%.1f` rounding).
  public let bpm: Double

  /// Normalized click correlation score in `[0, 1]` for this candidate.
  /// Zero when the click kernel had no positive samples or zero L2 norm.
  public let normalizedClickScore: Float

  public init(candidateIndex: Int, bpm: Double, normalizedClickScore: Float) {
    self.candidateIndex = candidateIndex
    self.bpm = bpm
    self.normalizedClickScore = normalizedClickScore
  }

  public var description: String {
    "ClickCorrelationEntry(idx: \(candidateIndex), bpm: \(bpm), ncc: \(normalizedClickScore))"
  }
}

/// Harmonic-ratio pair detected during octave disambiguation (Story 3-1).
///
/// Replaces a legacy `[String: String]` shape with fixed keys (`ratio`,
/// `fastBPM`, `slowBPM`, `winner`) — preserves full `Double` precision and
/// surfaces typed access to each field.
public struct HarmonicRatioEvidence: Sendable, CustomStringConvertible {

  /// Ratio label: `"2:1"`, `"3:2"`, or `"3:1"`.
  public let ratio: String

  /// Faster candidate's BPM in the detected pair.
  public let fastBPM: Double

  /// Slower candidate's BPM in the detected pair.
  public let slowBPM: Double

  /// BPM of the winner that disambiguation selected for this pair. For 3:2
  /// and 3:1 pairs (trace-only), this matches the current best candidate's
  /// BPM because those ratios do not modify the winner.
  public let winnerBPM: Double

  public init(ratio: String, fastBPM: Double, slowBPM: Double, winnerBPM: Double) {
    self.ratio = ratio
    self.fastBPM = fastBPM
    self.slowBPM = slowBPM
    self.winnerBPM = winnerBPM
  }

  public var description: String {
    "HarmonicRatioEvidence(ratio: \(ratio), fast: \(fastBPM), slow: \(slowBPM), winner: \(winnerBPM))"
  }
}

/// Sub-band voting decision recorded at Step 10b (Story 1-2).
///
/// Replaces a legacy `[String: String]` shape with fixed keys
/// (`preVoteBPM`, `postVoteBPM`, `changed`).
public struct SubBandVoteEvidence: Sendable, CustomStringConvertible {

  /// Winner BPM before sub-band voting ran.
  public let preVoteBPM: Double

  /// Winner BPM after sub-band voting (may equal `preVoteBPM` if the vote
  /// did not promote a different candidate).
  public let postVoteBPM: Double

  /// `true` when sub-band voting changed the winner.
  public let changed: Bool

  public init(preVoteBPM: Double, postVoteBPM: Double, changed: Bool) {
    self.preVoteBPM = preVoteBPM
    self.postVoteBPM = postVoteBPM
    self.changed = changed
  }

  public var description: String {
    "SubBandVoteEvidence(pre: \(preVoteBPM), post: \(postVoteBPM), changed: \(changed))"
  }
}

/// Duration-derived BPM hint diagnostic record from Step 9.7 (Story 3-4).
///
/// Replaces a legacy `[String: String]` shape that CSV-serialized the
/// bar-candidate and boosted-candidate arrays.
public struct DurationHintEvidence: Sendable, CustomStringConvertible {

  /// File duration in seconds at full `Double` precision.
  public let fileDurationSeconds: Double

  /// Bar-count candidates whose corresponding BPM fell within `60...200` BPM.
  /// Empty when no bar count yields an in-range BPM (very short clips).
  public let barCandidates: [BarCandidate]

  /// DSP candidate BPMs that received the multiplicative boost. Empty when
  /// no candidate matched any in-range bar BPM within the relative tolerance.
  public let boostedCandidates: [Double]

  public init(
    fileDurationSeconds: Double,
    barCandidates: [BarCandidate],
    boostedCandidates: [Double]
  ) {
    self.fileDurationSeconds = fileDurationSeconds
    self.barCandidates = barCandidates
    self.boostedCandidates = boostedCandidates
  }

  public var description: String {
    "DurationHintEvidence(duration: \(fileDurationSeconds), bars: \(barCandidates), boosted: \(boostedCandidates))"
  }
}

/// Single bar-count → BPM pair used by ``DurationHintEvidence``.
public struct BarCandidate: Sendable, CustomStringConvertible {

  /// Number of bars (e.g., `64`, `96`, `128`, `192`).
  public let bars: Int

  /// BPM derived from `bars * 4` beats / `fileDurationSeconds`. Filtered
  /// upstream to the `60...200` BPM range.
  public let bpm: Double

  public init(bars: Int, bpm: Double) {
    self.bars = bars
    self.bpm = bpm
  }

  public var description: String {
    "BarCandidate(bars: \(bars), bpm: \(bpm))"
  }
}

/// Maximum onset-envelope energy per drum sub-band, emitted on
/// ``BPMDiagnosticTrace/subBandEnergies`` at Step 3 when `enableTrace` is on.
///
/// Replaces a legacy `[String: Float]` keyed by the closed set
/// `{"kick", "snare", "crack", "hihat"}` — the dictionary shape was the last
/// surviving instance of `project-context.md` §"Banned trace-field shapes"
/// anti-pattern (1) (`[String: Float]` keyed by closed-set strings) after
/// Story 3-3b migrated four other trace fields. The dict semantically
/// treated "no entry" and "zero energy" as the same observable state — at
/// `.fastest` intensity (where `subBandVoting` is not in the technique set)
/// the dict was always empty anyway. ``zero`` preserves that semantic
/// without forcing readers through optional unwrapping.
public struct SubBandEnergies: Sendable, CustomStringConvertible, Equatable {

  /// Maximum sub-band envelope energy attributed to the kick drum band.
  public let kick: Float

  /// Maximum sub-band envelope energy attributed to the snare band.
  public let snare: Float

  /// Maximum sub-band envelope energy attributed to the crack / clap band.
  public let crack: Float

  /// Maximum sub-band envelope energy attributed to the hi-hat band.
  public let hihat: Float

  public init(kick: Float, snare: Float, crack: Float, hihat: Float) {
    self.kick = kick
    self.snare = snare
    self.crack = crack
    self.hihat = hihat
  }

  /// Default value emitted when sub-band computation was skipped (intensity
  /// 1-2, or `subBandVoting` not in the active technique set). Same observable
  /// state as the pre-Story-4-3b `[String: Float] = [:]` shape.
  public static let zero = SubBandEnergies(kick: 0, snare: 0, crack: 0, hihat: 0)

  public var description: String {
    "SubBandEnergies(kick: \(kick), snare: \(snare), crack: \(crack), hihat: \(hihat))"
  }
}

// MARK: - Trace Evidence Types (Story 4-5)

/// Tensor layout convention for ``MLFeatureFrames``. Story 4.5 ships only
/// ``nchw``; ``CaseIterable`` documents the closed set for the gating
/// invariant `TensorLayout.allCases.count == 1`. Pre-1.0 framing per
/// project-context.md "Public API Discipline" — Story 4.6 (CoreML) may
/// extend the case list (e.g., `.nhwc`) when an `MLShapedArray` consumer
/// surfaces a need.
public enum TensorLayout: String, Sendable, Hashable, CaseIterable {

  /// Row-major `[N=1, C=1, H=melBands, W=frames]` layout. Stride is
  /// contiguous: `[H*W, H*W, W, 1]`. This matches both the bundled
  /// `giantsteps_v1.mlmodelc` input contract AND the canonical
  /// Schreiber & Muller (2018) tempo-CNN architecture from which the
  /// library's reference model is derived.
  case nchw
}

/// Typed-evidence carrier for the per-frame log-mel spectrogram fed into
/// ``MLTechnique/evaluate(trace:)``. Surfaces the raw model input on the
/// trace so consumers can audit what the ML conformance actually saw —
/// and so future-story authors can detect when the pre-`vvlogf` pipeline
/// drifts away from the trained model's expected feature distribution.
///
/// The struct follows the typed-evidence pattern established by
/// ``ClickCorrelationEntry`` / ``SubBandEnergies`` / ``BarCandidate`` etc.
/// (Story 3-3b precedent): named `Sendable` value type, NO `[String: Any]`
/// payloads, NO stringified-numeric values. The accompanying
/// ``featureSetVersion`` field is the load-bearing seam that detects
/// pre-`vvlogf` pipeline drift — see project-context.md §"Banned trace-
/// field shapes" for the discipline. Story 4.5 ships `"v1"` against the
/// current `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` pre-image;
/// any change to `BPMAnalyzer.hopSize` / `melBands` / `melFmin` /
/// `melFmax` / `fftSize` / `logCompressionScale` / mel filterbank formula
/// MUST bump the version (DD #2 + DD #14 bump-trigger checklist).
public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable {

  /// Number of mel bands per frame. Equals `128` for the Story 4.5
  /// bundled `giantsteps_v1.mlmodelc` model.
  public let melBands: Int

  /// Pre-resample source frame count along the time axis. The
  /// ``BNNSTechnique`` conformance resamples to a fixed `W=512` BEFORE
  /// feeding the graph; this is the count BEFORE that resample step so
  /// readers can audit the source-rate-derived frame budget.
  public let frames: Int

  /// Logical tensor layout for ``logMelData``. ``TensorLayout/nchw`` only
  /// for Story 4.5; ``CaseIterable`` lets future stories add cases without
  /// breaking the precondition guard.
  public let tensorLayout: TensorLayout

  /// Row-major log-mel payload. Precondition (enforced in ``init``):
  /// `count == melBands * frames`. Layout follows ``tensorLayout``.
  public let logMelData: [Float]

  /// DSP source rate from which the spectrogram was derived. One of
  /// `44100.0`, `48000.0`, or `96000.0` per ``LUFSAnalyzer`` and
  /// ``BPMAnalyzer`` supported sample rates. Surfaced for completeness;
  /// `BNNSTechnique` does not resample audio.
  public let sampleRate: Double

  /// FFT window size used by `BPMAnalyzer.computeMelOnsetEnvelope...`
  /// at retention time. `2048` for Story 4.5; bump
  /// ``featureSetVersion`` if this changes.
  public let fftSize: Int

  /// Hop size in samples for the mel STFT. `441` samples (≈ 100 Hz onset
  /// rate at 44.1 kHz) for Story 4.5; bump ``featureSetVersion`` if this
  /// changes.
  public let hopSize: Int

  /// Mel filterbank low-frequency bound. `30.0` Hz for Story 4.5.
  public let melFmin: Double

  /// Mel filterbank high-frequency bound. `min(sampleRate/2, 16000)` per
  /// `BPMAnalyzer`'s current convention.
  public let melFmax: Double

  /// Linear pre-`vvlogf` scale factor. `100.0` for Story 4.5 (per
  /// `BPMAnalyzer.logCompressionScale`).
  public let logCompressionScale: Float

  /// Pre-`vvlogf` pipeline version tag. Story 4.5 ships `"v1"`. Bumps to
  /// `"v2"` (or later) per the DD #2 + DD #14 bump-trigger checklist.
  /// Consumer ``MLTechnique`` conformances SHOULD check this against the
  /// version their model was trained on and abstain (return `nil` from
  /// `evaluate(trace:)`) if the versions disagree.
  public let featureSetVersion: String

  public init(
    melBands: Int,
    frames: Int,
    tensorLayout: TensorLayout,
    logMelData: [Float],
    sampleRate: Double,
    fftSize: Int,
    hopSize: Int,
    melFmin: Double,
    melFmax: Double,
    logCompressionScale: Float,
    featureSetVersion: String
  ) {
    precondition(melBands > 0, "MLFeatureFrames: melBands must be positive (got \(melBands))")
    precondition(frames > 0, "MLFeatureFrames: frames must be positive (got \(frames))")
    precondition(
      logMelData.count == melBands * frames,
      "MLFeatureFrames: logMelData.count (\(logMelData.count)) must equal melBands * frames "
        + "(\(melBands * frames))"
    )
    precondition(
      tensorLayout == .nchw,
      "MLFeatureFrames: Story 4.5 only supports .nchw tensor layout (got \(tensorLayout))"
    )
    self.melBands = melBands
    self.frames = frames
    self.tensorLayout = tensorLayout
    self.logMelData = logMelData
    self.sampleRate = sampleRate
    self.fftSize = fftSize
    self.hopSize = hopSize
    self.melFmin = melFmin
    self.melFmax = melFmax
    self.logCompressionScale = logCompressionScale
    self.featureSetVersion = featureSetVersion
  }

  /// Compact diagnostic representation. The full ``logMelData`` payload is
  /// NOT printed (would be `melBands * frames` floats; up to hundreds of
  /// thousands of values at default intensity). Element count is shown
  /// instead so readers can verify the shape matches the metadata.
  public var description: String {
    "MLFeatureFrames(melBands: \(melBands), frames: \(frames), "
      + "layout: \(tensorLayout), logMelData.count: \(logMelData.count), "
      + "sampleRate: \(sampleRate), fftSize: \(fftSize), hopSize: \(hopSize), "
      + "melFmin: \(melFmin), melFmax: \(melFmax), "
      + "logCompressionScale: \(logCompressionScale), "
      + "featureSetVersion: \(featureSetVersion))"
  }
}
