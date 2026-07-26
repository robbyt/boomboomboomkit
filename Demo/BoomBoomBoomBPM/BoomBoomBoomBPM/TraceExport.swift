import BoomBoomBoomKit
import Foundation

// Atomic snapshot of post-run state. Either nil (no successful run yet
// or just reset by analyze prologue) or fully populated. The narrow
// `RunOptionsSnapshot` projection (NOT the full `AudioAnalysisService.
// Options`) avoids retaining `Options.isCancelled` / `Options.onProgress`
// closures, which capture the per-run `cancelFlag: Atomic<Bool>`.
struct LastRunDiagnosticSnapshot: Sendable {
  let trace: BPMDiagnosticTrace
  let metadataEvidence: [MetadataBPMEvidence]
  let runOptions: RunOptionsSnapshot
  let fileName: String
  let result: AudioAnalysisResult
}

// MARK: - RunOptionsSnapshot

// Narrow value-type projection of `AudioAnalysisService.Options`. NO
// closures (those would retain the per-run `cancelFlag`); `Equatable`
// is synthesized.
struct RunOptionsSnapshot: Sendable, Equatable {
  let intensity: AnalysisIntensity
  let mergeStrategy: BPMSelectionPolicy
  let votingPolicy: VotingPolicy
  let votingThreshold: Double
  let metadataPolicyEnabledSources: Set<MetadataSource>
  let durationHint: Bool
  let durationHintMinFileSeconds: Double
  let ensemblePolicy: EnsemblePolicy
  let enableTrace: Bool
  let enableMLDiagnostics: Bool
  let maxSeconds: Double

  init(from opts: AudioAnalysisService.Options) {
    self.intensity = opts.intensity
    self.mergeStrategy = opts.mergeStrategy
    self.votingPolicy = opts.votingPolicy
    self.votingThreshold = opts.votingThreshold
    self.metadataPolicyEnabledSources = opts.metadataPolicy.enabledSources
    self.durationHint = opts.durationHint
    self.durationHintMinFileSeconds = opts.durationHintMinFileSeconds
    self.ensemblePolicy = opts.ensemblePolicy
    self.enableTrace = opts.enableTrace
    self.enableMLDiagnostics = opts.enableMLDiagnostics
    self.maxSeconds = opts.maxSeconds
  }
}

// MARK: - FinalSelectionStep

/// "Which pipeline step selected the final BPM" attribution. The library
/// does NOT carry this as a single field; `derive(from:lastBPM:)` infers
/// it from existing trace state via priority-ordered comparisons.
///
/// Cascade order reflects pipeline execution order in
/// `AudioAnalysisService.analyzeBPM`: BPMAnalyzer (clickRescore →
/// durationHint → subBandVote → fineGrid) → BPMSelectionPolicy.merge
/// → MetadataCorroborator.apply → ML ensemble combiner. Highest priority
/// = latest-executed.
enum FinalSelectionStep: String, Sendable, Equatable, CaseIterable {
  case mlEnsemble = "ml-ensemble"
  case metadataCorroboration = "metadata-corroboration"
  case fineGridRefinement = "fine-grid-refinement"
  case subBandVoting = "sub-band-voting"
  case durationHint = "duration-hint"
  case clickRescore = "click-rescore"
  case baselineDisambiguation = "baseline-disambiguation"

  /// `lastBPM` anchors tie-breaks: e.g. `.mlEnsemble` fires only when
  /// ensemble's `selectedBPM == lastBPM` — an ensemble that ran but did
  /// NOT change the BPM (winner == .dsp / .tie) falls through.
  static func derive(
    from trace: BPMDiagnosticTrace,
    lastBPM: Double
  ) -> FinalSelectionStep {
    // P_D3 / D3 resolution — short-circuit non-finite lastBPM to the
    // baseline arm. Without this, every `abs(lastBPM - …)` comparison
    // below evaluates false (NaN propagates), silently mis-attributing
    // to .baselineDisambiguation anyway — but via the wrong code path
    // (e.g., the `.fineGridRefinement` arm would trip `refined != .nan`
    // = true and falsely fire). Explicit early-return makes the intent
    // legible.
    guard lastBPM.isFinite else { return .baselineDisambiguation }

    // .mlEnsemble — tolerance 0.5 BPM matches the cascade-wide convention
    // (durationHint, clickRescore already use the same threshold). vDSP
    // fan-out can introduce LSB-level differences between decision.selectedBPM
    // and the final result.bpm even when the ML decision is what got selected.
    if let decision = trace.ensembleDecision,
      decision.winner == .ml,
      decision.selectedBPM.isFinite,
      abs(decision.selectedBPM - lastBPM) <= 0.5
    {
      return .mlEnsemble
    }

    // candidatesBefore/AfterBoost are NOT documented sort-stable across
    // MetadataCorroborator.apply, so reduce via max(by:), not [0]. Filter
    // non-finite scores AND non-finite bpms first — `max(by:)` is unsafe
    // with NaN (both lt/gt return false, so a NaN entry can win and
    // corrupt attribution); and ±Infinity (`!isNaN` but `!isFinite`) would
    // win the reduce trivially, then trip `before.bpm != after.bpm` and
    // falsely attribute to .metadataCorroboration. Tightened `!isNaN` →
    // `isFinite` to match the `.mlEnsemble` (`decision.selectedBPM.isFinite`)
    // and `.fineGridRefinement` (`refined.isFinite && disambiguation.bpm.isFinite`)
    // arms below.
    let beforeWinner = trace.candidatesBeforeBoost
      .filter { $0.score.isFinite && $0.bpm.isFinite }
      .max(by: { $0.score < $1.score })
    let afterWinner = trace.candidatesAfterBoost
      .filter { $0.score.isFinite && $0.bpm.isFinite }
      .max(by: { $0.score < $1.score })
    if let before = beforeWinner, let after = afterWinner, before.bpm != after.bpm {
      return .metadataCorroboration
    }

    // .fineGridRefinement — switch from exact-inequality to 0.5 BPM
    // tolerance (P_D3). A legitimate fine-grid no-op refinement landing
    // on the same BPM as disambiguation can produce a sub-LSB difference
    // due to vDSP fan-out; without tolerance the cascade silently
    // attributes to .fineGridRefinement when nothing meaningful changed.
    if let refined = trace.refinedBPM,
      refined.isFinite,
      trace.disambiguationResult.bpm.isFinite,
      abs(refined - trace.disambiguationResult.bpm) > 0.5
    {
      return .fineGridRefinement
    }

    if trace.subBandVoteDetail?.changed == true {
      return .subBandVoting
    }

    // boostedCandidates holds pre-fine-grid BPMs that received the
    // duration-hint multiplier; ±0.5 BPM tolerance accommodates the
    // fine-grid shift.
    if let hint = trace.durationHintDetail {
      let matched = hint.boostedCandidates.contains { abs(lastBPM - $0) <= 0.5 }
      if matched {
        return .durationHint
      }
    }

    // Click rescore is attributable when rescore ran AND the pre-rescore
    // raw winner does not match lastBPM. Anchoring to lastBPM (rather than
    // comparing "highest NCC" vs "highest raw") avoids labeling cases
    // where rescoring reshuffled the ranking but the FINAL selected BPM
    // still tracks the pre-rescore winner. ±0.5 BPM tolerance matches the
    // .durationHint branch and accommodates any fine-grid shift.
    if let click = trace.clickCorrelationDetail, !click.isEmpty {
      let highestRaw = trace.rawCandidates
        .filter { !$0.score.isNaN }
        .max(by: { $0.score < $1.score })
      if let raw = highestRaw, abs(lastBPM - raw.bpm) > 0.5 {
        return .clickRescore
      }
    }

    return .baselineDisambiguation
  }

  /// Single-sentence summary for the SelectionInfo.reasoning field.
  var reasoning: String {
    switch self {
    case .mlEnsemble:
      return "ML ensemble combiner selected the ML candidate over DSP."
    case .metadataCorroboration:
      return "File-metadata tag (TBPM / tmpo / Vorbis) promoted a different DSP candidate."
    case .fineGridRefinement:
      return "Fine-grid DFT refinement adjusted the BPM after disambiguation."
    case .subBandVoting:
      return "Sub-band voting promoted a different candidate post-disambiguation."
    case .durationHint:
      return "Duration-derived bar-count boost matched a DSP candidate."
    case .clickRescore:
      return "Click-track cross-correlation reshuffled the candidate ranking."
    case .baselineDisambiguation:
      return "Baseline DSP disambiguation (step 10 octave disambiguation) selected the final BPM."
    }
  }
}

// MARK: - TraceExport

/// Top-level Codable trace export. `schemaVersion: "v1"` is the
/// load-bearing seam for future schema evolution — bump it atomically
/// with any breaking change (field removal, type change, key rename).
struct TraceExport: Codable, Sendable, Equatable {
  let schemaVersion: String
  let generatedAt: Date
  let run: RunInfo
  let selection: SelectionInfo
  let pipeline: PipelineInfo
  let metadata: MetadataInfo
  let ml: MLInfo?

  // Both `from(...)` overloads exceed the lint default of 5 parameters;
  // a `ProjectionInputs` wrapper would be polish only.
  // swiftlint:disable function_parameter_count

  /// Convenience overload for callers (e.g., smoke tests) holding a full
  /// `AudioAnalysisService.Options`. Production callers use the
  /// `runOptions:`-flavored primary factory to avoid retaining
  /// `Options.isCancelled` closures past the analyze() lifetime.
  static func from(
    trace: BPMDiagnosticTrace,
    options: AudioAnalysisService.Options,
    result: AudioAnalysisResult,
    fileName: String,
    metadataEvidence: [MetadataBPMEvidence],
    elapsedSeconds: Double
  ) -> TraceExport {
    Self.from(
      trace: trace,
      runOptions: RunOptionsSnapshot(from: options),
      result: result,
      fileName: fileName,
      metadataEvidence: metadataEvidence,
      elapsedSeconds: elapsedSeconds
    )
  }

  /// Pure projection factory: library trace + result + run-options →
  /// Codable shape. No side effects, no throws. A future library trace
  /// field added without a corresponding projection here is caught by
  /// the `traceExportSchemaMatchesGolden` smoke test.
  static func from(
    trace: BPMDiagnosticTrace,
    runOptions: RunOptionsSnapshot,
    result: AudioAnalysisResult,
    fileName: String,
    metadataEvidence: [MetadataBPMEvidence],
    elapsedSeconds: Double
  ) -> TraceExport {
    let finalStep = FinalSelectionStep.derive(from: trace, lastBPM: result.bpm)

    let run = RunInfo(
      fileName: fileName,
      intensityRequested: runOptions.intensity.level,
      intensityEffective: result.effectiveIntensity.level,
      mergeStrategy: runOptions.mergeStrategy.rawValue,
      votingPolicy: runOptions.votingPolicy.rawValue,
      votingThreshold: runOptions.votingThreshold,
      metadataPolicyEnabledSources: runOptions.metadataPolicyEnabledSources
        .map(\.rawValue)
        .sorted(),
      durationHint: runOptions.durationHint,
      durationHintMinFileSeconds: runOptions.durationHintMinFileSeconds,
      ensemblePolicy: runOptions.ensemblePolicy.stableKey,
      enableTrace: runOptions.enableTrace,
      enableMLDiagnostics: runOptions.enableMLDiagnostics,
      maxSeconds: runOptions.maxSeconds,
      elapsedSeconds: elapsedSeconds,
      bpm: result.bpm,
      confidence: result.confidence,
      degradationReason: result.degradationReason
    )

    let selection = SelectionInfo(
      finalStep: finalStep.rawValue,
      reasoning: finalStep.reasoning
    )

    let pipeline = PipelineInfo(
      energyTransitionOffset: trace.energyTransitionOffset,
      analysisWindowDuration: trace.analysisWindowDuration,
      onsetEnvelopeLength: trace.onsetEnvelopeLength,
      subBandEnergies: SubBandEnergiesJSON(from: trace.subBandEnergies),
      acfTopLags: trace.acfTopLags.map { LagStrength(lag: $0.lag, strength: $0.strength) },
      tempogramTopBPMs: trace.tempogramTopBPMs.map {
        BPMMagnitude(bpm: $0.bpm, magnitude: $0.magnitude)
      },
      fusedTopBPMs: trace.fusedTopBPMs.map { BPMScore(bpm: $0.bpm, score: $0.score) },
      tps2TopBPMs: trace.tps2TopBPMs.map { BPMScore(bpm: $0.bpm, score: $0.score) },
      rawCandidates: trace.rawCandidates.map { CandidateScore(bpm: $0.bpm, score: $0.score) },
      disambiguation: CandidateScore(
        bpm: trace.disambiguationResult.bpm,
        score: trace.disambiguationResult.score
      ),
      clickCorrelation: trace.clickCorrelationDetail.map { entries in
        entries.map { ClickCorrelationJSON(from: $0) }
      },
      durationHint: trace.durationHintDetail.map { DurationHintJSON(from: $0) },
      harmonicRatio: trace.harmonicRatioDetail.map { HarmonicRatioJSON(from: $0) },
      subBandVote: trace.subBandVoteDetail.map { SubBandVoteJSON(from: $0) },
      refinedBPM: trace.refinedBPM
    )

    let metadata = MetadataInfo(
      evidence: metadataEvidence.map { MetadataEvidenceJSON(from: $0) },
      candidatesBeforeBoost: trace.candidatesBeforeBoost.map {
        CandidateScore(bpm: $0.bpm, score: $0.score)
      },
      candidatesAfterBoost: trace.candidatesAfterBoost.map {
        CandidateScore(bpm: $0.bpm, score: $0.score)
      }
    )

    // Emit MLInfo whenever ANY of the three ML trace fields is populated.
    // mlDiagnosticSnapshot and mlFeatures can both be non-nil on abstain
    // paths where ensembleDecision is nil — gating on decision alone
    // silently drops the most useful ML failure evidence.
    let ml: MLInfo?
    if trace.ensembleDecision != nil
      || trace.mlDiagnosticSnapshot != nil
      || trace.mlFeatures != nil
    {
      ml = MLInfo(
        ensembleDecision: trace.ensembleDecision.map { EnsembleDecisionJSON(from: $0) },
        diagnosticSnapshot: trace.mlDiagnosticSnapshot.map { MLDiagnosticSnapshotJSON(from: $0) },
        featureFramesShape: trace.mlFeatures.map { MLFeatureFramesShapeJSON(from: $0) }
      )
    } else {
      ml = nil
    }

    return TraceExport(
      schemaVersion: "v1",
      generatedAt: Date(),
      run: run,
      selection: selection,
      pipeline: pipeline,
      metadata: metadata,
      ml: ml
    )
  }

  // swiftlint:enable function_parameter_count
}

// MARK: - RunInfo

struct RunInfo: Codable, Sendable, Equatable {
  let fileName: String
  let intensityRequested: Int
  let intensityEffective: Int
  let mergeStrategy: String
  let votingPolicy: String
  let votingThreshold: Double
  let metadataPolicyEnabledSources: [String]
  let durationHint: Bool
  let durationHintMinFileSeconds: Double
  let ensemblePolicy: String
  let enableTrace: Bool
  let enableMLDiagnostics: Bool
  let maxSeconds: Double
  let elapsedSeconds: Double
  let bpm: Double
  let confidence: Double
  let degradationReason: String?
}

// MARK: - SelectionInfo

struct SelectionInfo: Codable, Sendable, Equatable {
  let finalStep: String
  let reasoning: String
}

// MARK: - PipelineInfo

struct PipelineInfo: Codable, Sendable, Equatable {
  let energyTransitionOffset: Int
  let analysisWindowDuration: Double
  let onsetEnvelopeLength: Int
  let subBandEnergies: SubBandEnergiesJSON
  let acfTopLags: [LagStrength]
  let tempogramTopBPMs: [BPMMagnitude]
  let fusedTopBPMs: [BPMScore]
  let tps2TopBPMs: [BPMScore]
  let rawCandidates: [CandidateScore]
  let disambiguation: CandidateScore
  let clickCorrelation: [ClickCorrelationJSON]?
  let durationHint: DurationHintJSON?
  let harmonicRatio: HarmonicRatioJSON?
  let subBandVote: SubBandVoteJSON?
  let refinedBPM: Double?
}

// MARK: - MetadataInfo

struct MetadataInfo: Codable, Sendable, Equatable {
  let evidence: [MetadataEvidenceJSON]
  let candidatesBeforeBoost: [CandidateScore]
  let candidatesAfterBoost: [CandidateScore]
}

// MARK: - MLInfo

struct MLInfo: Codable, Sendable, Equatable {
  let ensembleDecision: EnsembleDecisionJSON?
  let diagnosticSnapshot: MLDiagnosticSnapshotJSON?
  let featureFramesShape: MLFeatureFramesShapeJSON?
}

// MARK: - Nested Projection Types

struct CandidateScore: Codable, Sendable, Equatable {
  let bpm: Double
  let score: Float
}

struct LagStrength: Codable, Sendable, Equatable {
  let lag: Int
  let strength: Float
}

struct BPMMagnitude: Codable, Sendable, Equatable {
  let bpm: Int
  let magnitude: Float
}

struct BPMScore: Codable, Sendable, Equatable {
  let bpm: Int
  let score: Float
}

struct SubBandEnergiesJSON: Codable, Sendable, Equatable {
  let kick: Float
  let snare: Float
  let crack: Float
  let hihat: Float

  init(from energies: SubBandEnergies) {
    self.kick = energies.kick
    self.snare = energies.snare
    self.crack = energies.crack
    self.hihat = energies.hihat
  }
}

struct ClickCorrelationJSON: Codable, Sendable, Equatable {
  let candidateIndex: Int
  let bpm: Double
  let normalizedClickScore: Float

  init(from entry: ClickCorrelationEntry) {
    self.candidateIndex = entry.candidateIndex
    self.bpm = entry.bpm
    self.normalizedClickScore = entry.normalizedClickScore
  }
}

struct DurationHintJSON: Codable, Sendable, Equatable {
  let fileDurationSeconds: Double
  let barCandidates: [BarCandidateJSON]
  let boostedCandidates: [Double]

  init(from evidence: DurationHintEvidence) {
    self.fileDurationSeconds = evidence.fileDurationSeconds
    self.barCandidates = evidence.barCandidates.map {
      BarCandidateJSON(bars: $0.bars, bpm: $0.bpm)
    }
    self.boostedCandidates = evidence.boostedCandidates
  }
}

struct BarCandidateJSON: Codable, Sendable, Equatable {
  let bars: Int
  let bpm: Double
}

struct HarmonicRatioJSON: Codable, Sendable, Equatable {
  let ratio: String
  let fastBPM: Double
  let slowBPM: Double
  let winnerBPM: Double

  init(from evidence: HarmonicRatioEvidence) {
    self.ratio = evidence.ratio
    self.fastBPM = evidence.fastBPM
    self.slowBPM = evidence.slowBPM
    self.winnerBPM = evidence.winnerBPM
  }
}

struct SubBandVoteJSON: Codable, Sendable, Equatable {
  let preVoteBPM: Double
  let postVoteBPM: Double
  let changed: Bool

  init(from evidence: SubBandVoteEvidence) {
    self.preVoteBPM = evidence.preVoteBPM
    self.postVoteBPM = evidence.postVoteBPM
    self.changed = evidence.changed
  }
}

struct MetadataEvidenceJSON: Codable, Sendable, Equatable {
  let source: String
  let rawValue: String
  // Optional because the library uses `Double.nan` to mark parse-phase
  // rejections (sentinel-zero, non-numeric); encoding NaN through the
  // default `.throw` strategy would fail the whole export. The
  // rejectionReason field carries the explanatory string.
  let parsedBPM: Double?
  let corroboratedWith: Double?
  let ratioMatched: String?
  let boostApplied: Double
  let rejectionReason: String?

  init(from evidence: MetadataBPMEvidence) {
    self.source = evidence.source.rawValue
    self.rawValue = evidence.rawValue
    // Non-finite Double sentinels are nullified at the projection boundary
    // (P_D2 / D2 resolution per Codex thread 019e5812-5ce7-7840-9aae-4825dccd98ab).
    // Library types per CLAUDE.md may carry NaN/Inf in `parsedBPM` (parse
    // rejection), `corroboratedWith` (no peer matched), and `boostApplied`
    // (degenerate compute). The JSONEncoder stays at `.throw` so INTERNAL
    // coding errors (a value written into RunInfo.elapsedSeconds, etc.)
    // still abort the encode and surface the bug.
    self.parsedBPM = evidence.parsedBPM.isFinite ? evidence.parsedBPM : nil
    self.corroboratedWith = evidence.corroboratedWith.flatMap { $0.isFinite ? $0 : nil }
    self.ratioMatched = evidence.ratioMatched.map(Self.humanize)
    self.boostApplied = evidence.boostApplied.isFinite ? evidence.boostApplied : 0
    self.rejectionReason = evidence.rejectionReason
  }

  /// Stable JSON strings for `HarmonicRatio`. The library enum does not
  /// expose a `rawValue`, so map explicitly — these are consumed by
  /// external jq/plotting scripts that rely on stable spellings.
  private static func humanize(_ ratio: HarmonicRatio) -> String {
    switch ratio {
    case .one: return "one"
    case .double: return "double"
    case .half: return "half"
    case .threeHalf: return "three-half"
    case .twoThird: return "two-third"
    }
  }
}

struct EnsembleDecisionJSON: Codable, Sendable, Equatable {
  let policy: String
  let winner: String
  let dspConfidence: Double
  let mlConfidence: Double?
  let mlAbstained: Bool
  /// GH-167 item 3: the abstain discriminator (`modelAbstained` /
  /// `nonFiniteBPM` / `nonFiniteConfidence`), nil for a contested decision.
  /// Exported so the JSON distinguishes the abstain kinds the library now
  /// records; `mlAbstained` is retained as the derived summary flag.
  let abstainKind: String?
  let selectedBPM: Double

  init(from decision: EnsembleDecision) {
    self.policy = decision.policy.stableKey
    self.winner = decision.winner.rawValue
    // CLAUDE.md explicitly notes EnsembleDecision is "not Hashable
    // (unsanitized Double.nan in DSP/ML values would break the hash
    // invariant); used only as a value carrier" — meaning these three
    // Double fields may legitimately carry sentinel NaN. Sanitize at the
    // projection boundary (P_D2 / D2 resolution).
    self.dspConfidence = decision.dspConfidence.isFinite ? decision.dspConfidence : 0
    self.mlConfidence = decision.mlConfidence.flatMap { $0.isFinite ? $0 : nil }
    self.mlAbstained = decision.mlAbstained
    self.abstainKind = decision.abstainKind?.rawValue
    self.selectedBPM = decision.selectedBPM.isFinite ? decision.selectedBPM : 0
  }
}

/// Nested fold record (GH-141). A separate object rather than two sibling
/// optionals, so a decoder cannot reconstruct half a fold — the library's
/// `MLDiagnosticSnapshot.OctaveFold` carries both values or neither.
struct OctaveFoldJSON: Codable, Sendable, Equatable {
  let fromBPM: Double
  let massRatio: Double
}

struct MLDiagnosticSnapshotJSON: Codable, Sendable, Equatable {
  // Carries the load-bearing numeric fields from MLDiagnosticSnapshot.
  // Future library evolution that adds fields to MLDiagnosticSnapshot
  // surfaces in the golden-file test as a schema diff (R2 mitigation).
  let decodedBPM: Double?
  let softmaxMax: Double?
  let softmaxSecondMax: Double?
  let inputFeatureChecksum: UInt64
  let failureStage: String?
  let gateFired: String?
  /// Present only when a decode-time octave fold rewrote `decodedBPM`.
  /// Without it a folded 70 BPM is indistinguishable from a bare 70 BPM
  /// argmax in an exported trace, which is archival.
  let octaveFold: OctaveFoldJSON?

  init(from snapshot: MLDiagnosticSnapshot) {
    // Each of these Double? fields may legitimately be non-finite when
    // the ML inference path emits sentinel values during a failure stage
    // (degenerate softmax, decode rejection, etc.). Sanitize at the
    // projection boundary (P_D2 / D2 resolution) so a single sentinel
    // doesn't abort the entire trace export.
    self.decodedBPM = snapshot.decodedBPM.flatMap { $0.isFinite ? $0 : nil }
    self.softmaxMax = snapshot.softmaxMax.flatMap { $0.isFinite ? $0 : nil }
    self.softmaxSecondMax = snapshot.softmaxSecondMax.flatMap { $0.isFinite ? $0 : nil }
    self.inputFeatureChecksum = snapshot.inputFeatureChecksum
    self.failureStage = snapshot.failureStage?.rawValue
    self.gateFired = snapshot.gateFired?.rawValue
    // Sanitized like its siblings for symmetry. Technically redundant:
    // `MLDiagnosticSnapshot.OctaveFold.init?` already refuses non-finite
    // input, so an instance cannot carry one. Kept so this projection does
    // not silently depend on an invariant enforced two types away.
    self.octaveFold = snapshot.octaveFold.flatMap {
      guard $0.fromBPM.isFinite, $0.massRatio.isFinite else { return nil }
      return OctaveFoldJSON(fromBPM: $0.fromBPM, massRatio: $0.massRatio)
    }
  }
}

struct MLFeatureFramesShapeJSON: Codable, Sendable, Equatable {
  // DD #11 — SHAPE ONLY. The `logMelData: [Float]` payload is
  // intentionally absent (would inflate the JSON to 25-50 MB at
  // default intensity 7 on a 3-minute file). Future stories may add
  // an opt-in checkbox to include the payload.
  let melBands: Int
  let frames: Int
  let tensorLayout: String
  let sampleRate: Double
  let fftSize: Int
  let hopSize: Int
  let melFmin: Double
  let melFmax: Double
  let logCompressionScale: Float
  let featureSetVersion: String

  init(from frames: MLFeatureFrames) {
    self.melBands = frames.melBands
    self.frames = frames.frames
    self.tensorLayout = frames.tensorLayout.rawValue
    // Float/Double config fields are sanitized at the projection boundary
    // (P_D2 / D2 resolution). A degenerate ML featurizer that emits NaN
    // sampleRate or melFmin/melFmax shouldn't abort the trace export.
    self.sampleRate = frames.sampleRate.isFinite ? frames.sampleRate : 0
    self.fftSize = frames.fftSize
    self.hopSize = frames.hopSize
    self.melFmin = frames.melFmin.isFinite ? frames.melFmin : 0
    self.melFmax = frames.melFmax.isFinite ? frames.melFmax : 0
    self.logCompressionScale = frames.logCompressionScale.isFinite ? frames.logCompressionScale : 0
    self.featureSetVersion = frames.featureSetVersion
  }
}
