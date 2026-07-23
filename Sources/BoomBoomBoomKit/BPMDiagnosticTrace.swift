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

  // MARK: - Step 9b: Click-Track Cross-Correlation

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

  // MARK: - Step 11: Beat-Grid Tempo Refinement (Story 8.10)

  /// Continuous beat-grid tempo-refinement outcome (coarse seed, refined value,
  /// both support scores, accepted flag). Populated when `enableTrace: true` AND
  /// the grid pass ran with `refineBeatGridTempo: true` — on every
  /// `AudioAnalysisService.Options.beatGridCoverage` (the default `.analysisWindow`
  /// step-11 fan-out AND the `.window(seconds:)` / `.fullTrack` coverage pass, which
  /// is threaded the same sink as of ticket #71). Surfaced on the combined
  /// `AudioAnalysisService.analyze` path via `CombinedAnalysisResult.bpm.trace`. Nil
  /// when the refinement was off or the grid pass did not run. Distinguishes "refit
  /// off" from "refit ran but the reject-guard kept the seed" (`accepted: false`
  /// with `refinedTempo == coarseTempo`).
  public var beatGridTempoRefinement: BeatGridTempoRefinementEvidence?

  /// Drop-anchored downbeat-strategy outcome (Story 8.11): which strategy ran, the
  /// structural drop's time + derived phase, the metrical-accent phase, whether the
  /// two agreed (`.combined` only), and the chosen phase. Populated when
  /// `enableTrace: true` AND the grid pass ran with `detectDownbeats: true` — on
  /// every `AudioAnalysisService.Options.beatGridCoverage` (the default
  /// `.analysisWindow` step-11 fan-out AND the `.window(seconds:)` / `.fullTrack`
  /// coverage pass, threaded the same sink as of ticket #71). Nil when downbeats
  /// were off or the grid pass did not run.
  public var downbeatStrategy: DownbeatStrategyEvidence?

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
  /// returned by ``BPMSelectionPolicy/merge(windowResults:candidateCount:strategy:votingPolicy:votingThreshold:)``.
  public var candidatesBeforeBoost: [(bpm: Double, score: Float)] = []

  /// Candidate pool after the corroborator multiplied matching candidates'
  /// scores by ``MetadataPolicy/corroborationBoost``. Equal to
  /// ``candidatesBeforeBoost`` when no candidates matched any tag.
  public var candidatesAfterBoost: [(bpm: Double, score: Float)] = []

  /// The metadata policy that produced this trace.
  public var metadataPolicyUsed: MetadataPolicy = .default

  // MARK: - Story 4.4: Ensemble Decision

  /// Diagnostic record of how ``AudioAnalysisService/combineEnsemble(dspWinner:ml:policy:)``
  /// resolved the post-corroboration DSP candidate against the ML
  /// invocation outcome. Populated under ``EnsemblePolicy/mlOnly`` /
  /// ``EnsemblePolicy/highestConfidence`` whenever
  /// ``MLTechnique/evaluate(trace:)`` was actually invoked — including
  /// abstains (`nil` return or a non-finite sentinel, discriminated by
  /// ``EnsembleDecision/abstainKind``). `nil` when ML was never invoked
  /// (including under ``EnsemblePolicy/dspOnly``, where the evaluation
  /// never runs). See ``EnsembleDecision`` for the population matrix.
  public var ensembleDecision: EnsembleDecision?

  // MARK: - Story 6.5b: Weighted Ensemble Resolution (KDD-A5)

  /// Forensic record of a pool-authoritative weighted ensemble resolution.
  /// Populated by ``AudioAnalysisService`` when the selected ``EnsemblePolicy``
  /// is ``EnsemblePolicy/weightedVoting(_:)`` or ``EnsemblePolicy/default`` and
  /// the cross-signal fusion ran; `nil` for the DSP-/ML-/highest-confidence
  /// policies (which emit ``ensembleDecision`` instead) and on the default
  /// `.dspOnly` path. See ``EnsembleWeightResolution``.
  public var ensembleWeightResolution: EnsembleWeightResolution?

  // MARK: - Story 4.6: ML Diagnostic Snapshot

  /// Per-evaluation diagnostic snapshot of the most recent
  /// ``MLTechnique/evaluate(trace:)`` call when the conformer adopts the
  /// ``MLDiagnosticTechnique`` capability protocol. Carries the load-bearing
  /// numeric evidence (decoded BPM, top-2 softmax probabilities, input
  /// feature checksum) AND a categorical ``MLDiagnosticSnapshot/FailureStage``
  /// summary that identifies which abstain path fired (or `nil` on the
  /// win path). See ``MLDiagnosticSnapshot`` for the full population matrix.
  ///
  /// **Population rules.** Non-nil only when ALL of these hold:
  /// 1. ``AudioAnalysisService/Options/mlTechnique`` is non-nil AND
  ///    conforms to ``MLDiagnosticTechnique`` (consumer-supplied plain
  ///    ``MLTechnique`` wrappers without the diagnostic conformance fall
  ///    back to ``MLTechnique/evaluate(trace:)`` and leave this nil — the
  ///    documented `wontfix pre-1.0` consumer-wrapper limitation).
  /// 2. ``AudioAnalysisService/Options/ensemblePolicy`` is not
  ///    ``EnsemblePolicy/dspOnly`` (DSP-only short-circuits before the ML
  ///    helper runs at all).
  /// 3. A trace was built (`shouldBuildTrace` predicate fired upstream).
  /// 4. ``AudioAnalysisService/Options/enableMLDiagnostics`` is `true`
  ///    (ML-diagnostic-specific visibility gate; Story 4-6 code review
  ///    P17 split this out of ``enableTrace`` because two paths
  ///    converged on the same flag and the gate naming hid the ML
  ///    semantics). Note: ``enableTrace`` controls whether the trace
  ///    itself surfaces on ``AudioAnalysisResult/trace``; even with
  ///    ``enableMLDiagnostics == true``, a consumer who keeps
  ///    ``enableTrace == false`` will not receive the trace and
  ///    therefore won't see the snapshot externally — `enableTrace`
  ///    remains the master gate on trace visibility.
  /// 5. The conformer's ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)``
  ///    actually returned a non-nil snapshot — i.e., the inference reached
  ///    at least the featurize step. The two pre-featurize abstain paths
  ///    (``MLDiagnosticSnapshot/FailureStage/featuresAbsent`` and
  ///    ``MLDiagnosticSnapshot/FailureStage/featureVersionMismatch``)
  ///    return `(nil, nil)` from the conformance per the tuple invariant,
  ///    so this field stays nil on those paths. The reporting harness
  ///    derives the histogram bucket for those tracks from
  ///    `MLEvaluation == nil && mlDiagnosticSnapshot == nil` + trace
  ///    state.
  ///
  /// **Diagnostic, not load-bearing.** Consumers can ignore this field
  /// without losing functionality — it surfaces inference internals for
  /// debugging and threshold-sweep analysis (Story 4-6 DD #5). The
  /// production library never reads it; the impact-report harness at
  /// `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` is the
  /// primary consumer.
  ///
  /// **See also.** ``MLDiagnosticSnapshot`` (typed-evidence shape),
  /// ``MLDiagnosticTechnique`` (capability protocol that produces it),
  /// ``BNNSTechnique`` (Story 4-6 reference conformer).
  public var mlDiagnosticSnapshot: MLDiagnosticSnapshot?

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

  // MARK: - Story 6.1: Unified Signal Pool (SignalParticipationTraceEntry lives in SignalPool/)

  public var signalParticipationTrace: [SignalParticipationTraceEntry] = []
}

// MARK: - Trace Evidence Types (Story 3-3b)

/// Per-candidate click-track cross-correlation result emitted by
/// ``BPMDiagnosticTrace/clickCorrelationDetail`` at Step 9b.
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

  /// Compact textual representation: `ClickCorrelationEntry(idx: …, bpm: …, ncc: …)`.
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

  /// Compact textual representation: `HarmonicRatioEvidence(ratio: …, fast: …, slow: …, winner: …)`.
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

  /// Compact textual representation: `SubBandVoteEvidence(pre: …, post: …, changed: …)`.
  public var description: String {
    "SubBandVoteEvidence(pre: \(preVoteBPM), post: \(postVoteBPM), changed: \(changed))"
  }
}

/// Continuous beat-grid tempo-refinement outcome recorded at Step 11 (Story 8.10).
///
/// The step-11 beat-grid fan-out can refine the grid's tempo to sub-0.1-BPM
/// precision by fitting a continuous interpolated onset-comb against the audio's
/// own onset evidence (seeded by the coarse BPM-stage tempo). This records what
/// the refit did, so "did the reject-guard fire, and by how much" is answerable
/// from a single corpus run. Follows the ``SubBandVoteEvidence``
/// before/after/changed convention (NOT a `[String: …]` dict).
///
/// `support*` are the onset-comb support scores (mean onset energy at the best
/// beat phase, higher = better-aligned) for the seed period and the refined
/// period, both computed by the SAME objective at each period's own argmax
/// phase. The refit is accepted iff `supportRefined > supportSeed` (strict); on
/// reject/abstain ``refinedTempo`` equals ``coarseTempo`` and ``accepted`` is
/// `false`.
public struct BeatGridTempoRefinementEvidence: Sendable, CustomStringConvertible {

  /// The coarse BPM-stage tempo the refit was seeded from (`tempoBPM`).
  public let coarseTempo: Double

  /// The tempo reported on ``BeatGrid/estimatedTempo``: the refined value when
  /// accepted, else `coarseTempo` (the seed's original binding).
  public let refinedTempo: Double

  /// Onset-comb support of the seed period at its argmax phase.
  public let supportSeed: Double

  /// Onset-comb support of the refined period at its argmax phase. `<= supportSeed`
  /// exactly when the refit was rejected (the seed stood).
  public let supportRefined: Double

  /// `true` when the refit was accepted (`supportRefined > supportSeed` and the
  /// refined tempo was finite-positive over a sufficient span).
  public let accepted: Bool

  public init(
    coarseTempo: Double, refinedTempo: Double,
    supportSeed: Double, supportRefined: Double, accepted: Bool
  ) {
    self.coarseTempo = coarseTempo
    self.refinedTempo = refinedTempo
    self.supportSeed = supportSeed
    self.supportRefined = supportRefined
    self.accepted = accepted
  }

  /// Compact textual representation:
  /// `BeatGridTempoRefinementEvidence(coarse: …, refined: …, supportSeed: …, supportRefined: …, accepted: …)`.
  public var description: String {
    "BeatGridTempoRefinementEvidence(coarse: \(coarseTempo), refined: \(refinedTempo), "
      + "supportSeed: \(supportSeed), supportRefined: \(supportRefined), accepted: \(accepted))"
  }
}

// MARK: - Step 11: Drop-anchored downbeat strategy (Story 8.11)

/// Typed evidence for the drop-anchored downbeat strategy (Story 8.11): which
/// ``DownbeatStrategy`` ran, the structural drop's absolute file time and the bar
/// phase it implied, the metrical-accent phase, whether the two agreed (under
/// ``DownbeatStrategy/combined``), the chosen phase, and the chosen confidence.
///
/// A typed value carrier (never a `[String: …]` map), so the `bpm-diagnostic-trace`
/// audit recipes stay clean. Optionals distinguish "not applicable to this
/// strategy" / "abstained" from a real value: `dropTimeSeconds` / `dropPhase` are
/// nil for ``DownbeatStrategy/metricalAccent`` or when no drop was found;
/// `metricalAccentPhase` is nil for ``DownbeatStrategy/structuralDrop`` or when
/// metrical accent abstained; `agreement` is nil unless both sources fired under
/// ``DownbeatStrategy/combined``; `chosenPhase` is nil on an abstain.
///
/// Not `Hashable` (the unsanitized `confidence` `Double` follows the
/// ``EnsembleDecision`` precedent — a value carrier, never a `Set`/`Dictionary`
/// key).
public struct DownbeatStrategyEvidence: Sendable, CustomStringConvertible {

  /// Which strategy ran.
  public let strategy: DownbeatStrategy

  /// Absolute file time (seconds) of the detected structural drop, or nil
  /// (metrical-accent strategy, or no drop found).
  public let dropTimeSeconds: Double?

  /// Bar phase the structural drop implied (`0 ..< beatsPerBar`), or nil.
  public let dropPhase: Int?

  /// Bar phase the metrical-accent estimator produced, or nil (structural-drop
  /// strategy, or metrical accent abstained).
  public let metricalAccentPhase: Int?

  /// Under ``DownbeatStrategy/combined`` with both sources firing: whether their
  /// phases agreed. Nil otherwise.
  public let agreement: Bool?

  /// The emitted downbeat phase, or nil on an abstain.
  public let chosenPhase: Int?

  /// The emitted downbeat confidence (`0` on an abstain).
  public let confidence: Double

  public init(
    strategy: DownbeatStrategy,
    dropTimeSeconds: Double?,
    dropPhase: Int?,
    metricalAccentPhase: Int?,
    agreement: Bool?,
    chosenPhase: Int?,
    confidence: Double
  ) {
    self.strategy = strategy
    self.dropTimeSeconds = dropTimeSeconds
    self.dropPhase = dropPhase
    self.metricalAccentPhase = metricalAccentPhase
    self.agreement = agreement
    self.chosenPhase = chosenPhase
    self.confidence = confidence
  }

  /// Compact textual representation.
  public var description: String {
    let dropStr = dropTimeSeconds.map { "\($0)s" } ?? "nil"
    let dropPhaseStr = dropPhase.map { "\($0)" } ?? "nil"
    let metricalStr = metricalAccentPhase.map { "\($0)" } ?? "nil"
    let agreementStr = agreement.map { "\($0)" } ?? "nil"
    let chosenStr = chosenPhase.map { "\($0)" } ?? "nil"
    return "DownbeatStrategyEvidence(strategy: \(strategy), drop: \(dropStr) @\(dropPhaseStr), "
      + "metrical: \(metricalStr), agreement: \(agreementStr), chosen: \(chosenStr), "
      + "confidence: \(confidence))"
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

  /// Compact textual representation: `DurationHintEvidence(duration: …, bars: […], boosted: […])`.
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

  /// Compact textual representation: `BarCandidate(bars: …, bpm: …)`.
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

  /// Creates a snapshot of per-band maximum envelope energies.
  ///
  /// - Parameters:
  ///   - kick: Maximum onset-envelope energy in the kick band.
  ///   - snare: Maximum onset-envelope energy in the snare band.
  ///   - crack: Maximum onset-envelope energy in the crack / clap band.
  ///   - hihat: Maximum onset-envelope energy in the hi-hat band.
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

  /// Compact textual representation: `SubBandEnergies(kick: …, snare: …, crack: …, hihat: …)`.
  public var description: String {
    "SubBandEnergies(kick: \(kick), snare: \(snare), crack: \(crack), hihat: \(hihat))"
  }
}
