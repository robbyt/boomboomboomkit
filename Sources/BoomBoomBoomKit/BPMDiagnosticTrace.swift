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
  /// fed into ``MLTechnique/evaluate(trace:)`` as the model input.
  ///
  /// **Population rules.** The producer (``BPMAnalyzer``) populates this
  /// field on the *internally-constructed* trace whenever both of these
  /// hold: `Options.mlTechnique != nil` AND
  /// `Options.ensemblePolicy != .dspOnly`. ``Options/enableTrace`` is NOT
  /// part of the population gate — the auto-trace ML path runs even when
  /// the consumer asked `enableTrace: false` so that `evaluate(trace:)`
  /// always sees the same `mlFeatures` shape (Story 4-5 AC #14 / review
  /// fix M5). The DSP-only path remains zero-cost because both gates
  /// short-circuit before retention.
  ///
  /// **What consumers observe on the result trace.** On
  /// ``AudioAnalysisResult/trace`` (the trace returned to the caller),
  /// ``mlFeatures`` is non-nil only when the consumer ALSO set
  /// `Options.enableTrace = true` AND ML was active. With
  /// `enableTrace = false`, the consumer-visible trace is `nil` (see
  /// `runPreCorroborationPipeline` for the `shouldBuildTrace` predicate).
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

/// Tensor layout convention for ``MLFeatureFrames``. Story 4.5 ships two
/// cases — ``frameMajorLogMel`` (the on-the-wire layout the
/// ``BPMAnalyzer`` retention path emits) and ``nchw`` (reserved for
/// future producers whose retention path already emits mel-major bytes).
/// ``CaseIterable`` documents the closed set for the gating invariant
/// `TensorLayout.allCases.count == 2`. Pre-1.0 framing per
/// project-context.md "Public API Discipline" — Story 4.6 (CoreML) may
/// extend the case list (e.g., `.nhwc`) when an `MLShapedArray` consumer
/// surfaces a need.
///
/// See `tools/coreml-convert/README.md` for the canonical consumer-onboarding
/// flow (Paths A/B/C: bundled, converted, third-party) and the worked
/// example showing how a custom ``MLTechnique`` conformance reads this
/// layout tag and reshapes accordingly.
public enum TensorLayout: String, Sendable, Hashable, CaseIterable {

  /// Frame-major flat layout — the on-the-wire shape ``BPMAnalyzer``
  /// emits when capturing ``MLFeatureFrames``. Element `[frame * melBands
  /// + mel]` of ``MLFeatureFrames/logMelData``; concatenation of per-frame
  /// `logMelFrames` produces this order naturally. ``BNNSTechnique``
  /// transposes frame-major → mel-major at evaluate time (see
  /// ``BNNSTechnique`` Step 1 of `featurize`).
  ///
  /// Added Story 4-5 review pass (post-code-review 2026-05-13): the
  /// producer was originally tagging this layout as ``nchw``, which was
  /// inaccurate — third-party ``MLTechnique`` consumers reading the
  /// `.nchw` tag would reshape frame-major bytes as mel-major NCHW and
  /// feed transposed features to their models. Pre-1.0 fix introduces
  /// the truthful layout case.
  case frameMajorLogMel
  /// Row-major `[N=1, C=1, H=melBands, W=frames]` layout. Stride is
  /// contiguous: `[H*W, H*W, W, 1]`. Reserved for future producers
  /// (e.g., a CoreML conformance that consumes `MLShapedArray<Float>`
  /// directly) whose retention path emits mel-major bytes; the
  /// ``BNNSTechnique`` consumer reads this layout without transposing.
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
///
/// See `tools/coreml-convert/README.md` for the canonical consumer-onboarding
/// flow — Paths A (bundled reference model), B (your converted weights), and
/// C (third-party / AGPL caveats). The README's worked examples show how a
/// custom ``MLTechnique`` conformance consumes this struct.
public struct MLFeatureFrames: Sendable, CustomStringConvertible, Equatable {

  /// Number of mel bands per frame. Equals `128` for the Story 4.5
  /// bundled `giantsteps_v1.mlmodelc` model.
  public let melBands: Int

  /// Pre-resample source frame count along the time axis. The
  /// ``BNNSTechnique`` conformance resamples to a fixed `W=512` BEFORE
  /// feeding the graph; this is the count BEFORE that resample step so
  /// readers can audit the source-rate-derived frame budget.
  public let frames: Int

  /// Logical tensor layout for ``logMelData``. Story 4.5 ships
  /// ``TensorLayout/frameMajorLogMel`` (the ``BPMAnalyzer`` producer's
  /// actual on-the-wire shape) and ``TensorLayout/nchw`` (reserved for
  /// future producers); ``CaseIterable`` lets future stories add cases
  /// without breaking the precondition guard.
  ///
  /// **TensorLayout is a tag, not a constraint.** The initializer does
  /// not (and cannot) inspect ``logMelData`` to verify the bytes match
  /// the declared layout. Producers MUST set this field truthfully — a
  /// mislabeled payload (e.g., frame-major bytes tagged ``nchw``) will
  /// be fed transposed into a consumer ``MLTechnique`` and produce
  /// silently wrong predictions. The standard library producer
  /// (``BPMAnalyzer``) always emits ``frameMajorLogMel``.
  public let tensorLayout: TensorLayout

  /// Log-mel payload whose interpretation depends on ``tensorLayout``:
  /// - ``TensorLayout/frameMajorLogMel`` (current ``BPMAnalyzer``
  ///   producer): `[frame0_mel0, frame0_mel1, …, frame0_melLast,
  ///   frame1_mel0, …]`. Equivalent to `logMelFrames.flatMap { $0 }`
  ///   where each inner row is one frame's mel band values.
  /// - ``TensorLayout/nchw``: `[N=1, C=1, H=melBands, W=frames]`
  ///   row-major, i.e., mel-major (`[mel0_frame0, mel0_frame1, …,
  ///   mel0_frameLast, mel1_frame0, …]`).
  ///
  /// Throwing-init invariants: `count == melBands * frames`, both
  /// dimensions positive, and total element count `<= 8_388_608` (≈ 32
  /// MB on a `[Float]`; defends the public initializer against
  /// accidental construction of arbitrarily-large payloads on a
  /// `Sendable` boundary).
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

  /// Maximum allowed `logMelData.count` (= 8 Mi floats = 32 MB at
  /// 4 bytes/float). Comfortably accommodates the default
  /// `AudioAnalysisService.Options.maxSeconds = 120` budget
  /// (120 s × 100 fps × 128 mel = 1.536 Mi floats) with ~5× headroom for
  /// stories that bump `maxSeconds` toward 10 minutes. Consumers with
  /// `maxSeconds = 1800` (rare) trip the cap and route through abstain
  /// (`try?` in the producer → `mlFeatures = nil`).
  ///
  /// **Retention-side defense, not boundary defense (review fix N13):** the cap
  /// fires inside the initializer AFTER the caller has already allocated the
  /// `[Float]` payload. Its job is to defend the ``BPMAnalyzer`` retention path
  /// against pathologically-long analysis windows producing a multi-hundred-MB
  /// `mlFeatures` value (the `try`/`catch invalidFeatureShape` in the producer
  /// routes the failure through the documented abstain path). Callers that
  /// pre-allocate their own `logMelData` MUST validate the allocation size
  /// themselves — this initializer cannot.
  public static var maximumLogMelDataCount: Int {
    _testingMaximumLogMelDataCount ?? 8_388_608
  }

  /// Test-only override of ``maximumLogMelDataCount``. Implemented as a Swift
  /// `@TaskLocal` so the override is per-task — concurrent tests
  /// constructing larger ``MLFeatureFrames`` outside the
  /// ``_withTestingMaximumLogMelDataCount(_:_:)`` scope continue to see the
  /// production cap. The v1 implementation used `nonisolated(unsafe) static var`
  /// which silenced Swift 6 strict-concurrency checking but didn't actually
  /// isolate parallel tests — Codex review pass flagged this as a real bug,
  /// not just a smell (review fix N5 v2 / codex 019e28bb).
  ///
  /// **Propagation caveat (Story 4-5 review pass v3 / Edge Case Hunter #8).**
  /// Swift `@TaskLocal` values propagate to *structured* child tasks
  /// (`async let`, `TaskGroup.addTask`) but NOT to *unstructured*
  /// `Task { }` instances spawned inside the override scope. A test that
  /// wraps `analyzeBPM` in `Task { try analyzeBPM(...) }.value` from
  /// inside ``_withTestingMaximumLogMelDataCount(_:_:)`` runs on a
  /// fresh task tree that sees the production cap, not the override.
  /// Tests must call `analyzeBPM` directly inside the override (or via
  /// `async let` / `TaskGroup`).
  ///
  /// Production code MUST NOT touch this directly.
  @TaskLocal internal static var _testingMaximumLogMelDataCount: Int?

  /// Test-only helper that temporarily lowers ``maximumLogMelDataCount`` for the
  /// duration of `body`. The override is task-local — concurrent tests on
  /// other tasks see the production cap. The wrapper still uses `defer`-style
  /// scoping via `TaskLocal.withValue` semantics so the override doesn't
  /// leak past the closure even if `body` throws (review fix N5 v2).
  ///
  /// See ``_testingMaximumLogMelDataCount`` for the unstructured-`Task { }`
  /// propagation caveat.
  internal static func _withTestingMaximumLogMelDataCount<R>(
    _ cap: Int, _ body: () throws -> R
  ) rethrows -> R {
    try $_testingMaximumLogMelDataCount.withValue(cap, operation: body)
  }

  /// Throwing initializer enforcing the public-API invariants documented
  /// on each field. Replaces the pre-review `precondition()` calls so a
  /// malformed payload routes through an abstain path rather than
  /// crashing the host app.
  ///
  /// Throws `MLTechniqueError.invalidFeatureShape` when any invariant
  /// fires; see ``MLTechniqueError/invalidFeatureShape(reason:)`` for the
  /// abstain semantics.
  ///
  /// **Validation order (cheap-to-expensive).** Scalar shape and
  /// semantic-metadata checks fire first; the O(N) `allSatisfy(\.isFinite)`
  /// scan over `logMelData` runs last so a malformed-shape payload short-
  /// circuits before the cost of walking the buffer is paid.
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
  ) throws {
    // MARK: Shape invariants
    guard melBands > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melBands must be positive (got \(melBands))")
    }
    guard frames > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "frames must be positive (got \(frames))")
    }
    // Use multipliedReportingOverflow to defend against
    // `Int.max`-sized inputs that would trap on the unguarded
    // multiplication.
    let (expectedCount, overflow) = melBands.multipliedReportingOverflow(by: frames)
    guard !overflow else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melBands * frames overflowed Int (melBands=\(melBands), frames=\(frames))")
    }
    guard logMelData.count == expectedCount else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logMelData.count (\(logMelData.count)) != melBands * frames (\(expectedCount))")
    }
    guard expectedCount <= Self.maximumLogMelDataCount else {
      throw MLTechniqueError.invalidFeatureShape(
        reason:
          "logMelData.count \(expectedCount) exceeds size cap \(Self.maximumLogMelDataCount) "
          + "(≈32 MB); bump cap or trim the analysis window")
    }
    // `tensorLayout` is `CaseIterable` with closed-set membership; the
    // `switch` lets future-case extension surface as a non-exhaustive
    // compile error rather than a silent precondition trap.
    switch tensorLayout {
    case .frameMajorLogMel, .nchw:
      break
    }

    // MARK: Semantic-metadata invariants (Story 4-5 review pass v3)
    // The metadata fields are part of the tensor's typed contract per
    // DD #2 — a consumer ``MLTechnique`` aligning its training-time
    // pipeline against these values must be able to trust them. Storing
    // garbage (NaN sample rates, zero hop sizes, fmax < fmin, empty
    // version tag) without checking would silently bypass the
    // pipeline-drift detection seam ``featureSetVersion`` exists to
    // provide.
    guard sampleRate.isFinite, sampleRate > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "sampleRate must be finite and positive (got \(sampleRate))")
    }
    guard fftSize > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "fftSize must be positive (got \(fftSize))")
    }
    guard hopSize > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "hopSize must be positive (got \(hopSize))")
    }
    guard melFmin.isFinite, melFmin >= 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melFmin must be finite and non-negative (got \(melFmin))")
    }
    guard melFmax.isFinite, melFmax > melFmin else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "melFmax must be finite and strictly greater than melFmin "
          + "(melFmin=\(melFmin), melFmax=\(melFmax))")
    }
    guard logCompressionScale.isFinite, logCompressionScale > 0 else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logCompressionScale must be finite and positive (got \(logCompressionScale))")
    }
    guard !featureSetVersion.isEmpty else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "featureSetVersion must not be empty (DD #2 pipeline-drift detection)")
    }

    // MARK: Payload finiteness — O(N) scan last
    // Real-world audio with sustained loud peaks can push pre-`vvlogf`
    // mel energies into the upper `Float` range; `100.0 * x + 1.0`
    // overflows `Float.infinity` at `x ≈ 3.4e36`. Producing `+inf` /
    // `NaN` in the tensor would propagate through downstream `vDSP`
    // normalization (mean/stddev become `NaN`) and break synthesized
    // `Equatable` (`Float.nan != Float.nan`). Reject at the boundary.
    guard logMelData.allSatisfy({ $0.isFinite }) else {
      throw MLTechniqueError.invalidFeatureShape(
        reason: "logMelData contains non-finite values (NaN or Inf); upstream "
          + "DSP pre-image overflowed or produced an invalid log")
    }

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
    // `featureSetVersion` is quoted so descriptions of payloads carrying
    // malformed version tags (containing commas, colons, or other
    // separator-looking characters) remain machine-parseable in
    // benchmark logs and ablation reports.
    "MLFeatureFrames(melBands: \(melBands), frames: \(frames), "
      + "layout: \(tensorLayout), logMelData.count: \(logMelData.count), "
      + "sampleRate: \(sampleRate), fftSize: \(fftSize), hopSize: \(hopSize), "
      + "melFmin: \(melFmin), melFmax: \(melFmax), "
      + "logCompressionScale: \(logCompressionScale), "
      + "featureSetVersion: \"\(featureSetVersion)\")"
  }
}
