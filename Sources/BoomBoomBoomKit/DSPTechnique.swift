//
//  DSPTechnique.swift
//  BoomBoomBoomKit
//
//  Closed enum of DSP pipeline techniques, composable TechniqueSet,
//  and open MLTechnique protocol for ML-augmented BPM detection
//  (Story 4.3 wired the path; Stories 4.5/4.6 ship BNNS/CoreML conformances).
//

import Foundation

// MARK: - DSPTechnique

/// Individual DSP technique that can be toggled in the BPM analysis pipeline.
///
/// This is a closed set — all DSP techniques are enumerated here.
/// Use `TechniqueSet` to compose combinations for analysis or ablation.
public enum DSPTechnique: String, CaseIterable, Sendable, Hashable {

  /// Element-wise squaring of the autocorrelation function (`vDSP_vsq`).
  /// Sharpens ACF peaks to improve peak selection for ambiguous tempos.
  /// Cost: negligible (single vDSP pass over ~4K floats).
  /// Impact: +2 tracks on OA300 (best single technique). Empirically validated.
  case acfSharpening

  /// Running-mean subtraction on the onset envelope (`vDSP_vswsum`, 500ms window).
  /// Removes slow energy trends so only transient onsets survive.
  /// Cost: low (one vDSP convolution pass).
  /// Impact: -2 tracks on OA300. Hurts accuracy on this corpus — may help on non-DnB genres.
  case adaptiveThreshold

  /// Per-sub-band max normalization of mel onset envelopes before summing.
  /// Prevents loud bands from dominating the combined envelope.
  /// Cost: low (4x vDSP_maxv + vDSP_vsdiv over ~1K frames each).
  /// Impact: neutral on OA300 (0 tracks changed vs baseline). Included in `.dnbOptimized`.
  case subBandNormalization

  /// Extracts 5 candidates from the periodicity spectrum instead of 3.
  /// Gives disambiguation more options but also more noise.
  /// Cost: negligible (2 extra peak selections).
  /// Impact: -3 tracks on OA300. Extra candidates introduce harmonic confusion.
  case expandedCandidates

  /// Fine-grid DFT refinement on the winning BPM candidate.
  /// Narrows the estimate from integer BPM to fractional precision (+-0.5 BPM grid).
  /// Cost: moderate (short DFT per candidate, typically 1-3 candidates).
  /// Impact: part of baseline. Required for sub-BPM accuracy.
  case fineGridRefinement

  /// Per-sub-band autocorrelation and weighted voting for octave disambiguation.
  /// Computes separate ACFs for kick/snare/crack/hihat bands and votes on half/double tempo.
  /// Cost: moderate (4 extra ACF computations + mel onset sub-band extraction).
  /// Impact: part of baseline. Essential for octave resolution.
  case subBandVoting

  /// Per-candidate cross-correlation between a synthetic click pattern at the candidate BPM
  /// and the onset envelope. Rescoring runs at step 9.5, between candidate extraction and
  /// octave disambiguation, so candidates with strong rhythmic alignment are preferred.
  /// Cost: low (sparse normalized beat-search per candidate, ~3 candidates).
  /// Impact: TBD (validated by ablation in Story 3-3, Task 3).
  case clickTrackCorrelation

  /// Short label used in ablation output (e.g., "sharp", "vote").
  var shortName: String {
    switch self {
    case .acfSharpening: return "sharp"
    case .adaptiveThreshold: return "thresh"
    case .subBandNormalization: return "norm"
    case .expandedCandidates: return "top5"
    case .fineGridRefinement: return "fine"
    case .subBandVoting: return "vote"
    case .clickTrackCorrelation: return "click"
    }
  }
}

// MARK: - TechniqueSet

/// A composable set of DSP techniques with a candidate count.
///
/// Used by `BPMAnalyzer` to control which pipeline stages run,
/// and by ablation tests to enumerate all 2^N combinations.
public struct TechniqueSet: Sendable, Hashable {
  public var dspTechniques: Set<DSPTechnique>

  /// Number of top candidates to extract from the periodicity spectrum.
  /// Default: 5 when `.expandedCandidates` is in the set, otherwise 3.
  /// Can be overridden (e.g., intensity 1 uses 1 candidate).
  public var candidateCount: Int

  public init(dspTechniques: Set<DSPTechnique> = [], candidateCount: Int? = nil) {
    self.dspTechniques = dspTechniques
    self.candidateCount = candidateCount ?? (dspTechniques.contains(.expandedCandidates) ? 5 : 3)
  }

  // MARK: - Queries

  public func contains(_ technique: DSPTechnique) -> Bool {
    dspTechniques.contains(technique)
  }

  // MARK: - Builders

  public func inserting(_ technique: DSPTechnique) -> TechniqueSet {
    var copy = self
    copy.dspTechniques.insert(technique)
    copy.candidateCount = copy.dspTechniques.contains(.expandedCandidates) ? 5 : 3
    return copy
  }

  public func removing(_ technique: DSPTechnique) -> TechniqueSet {
    var copy = self
    copy.dspTechniques.remove(technique)
    copy.candidateCount = copy.dspTechniques.contains(.expandedCandidates) ? 5 : 3
    return copy
  }

  // MARK: - Label

  /// Human-readable label joining technique short names (e.g., "sharp+vote+fine").
  public var label: String {
    if dspTechniques.isEmpty { return "minimal" }
    // Stable ordering by rawValue for reproducible labels
    let sorted = dspTechniques.sorted { $0.rawValue < $1.rawValue }
    return sorted.map(\.shortName).joined(separator: "+")
  }

  // MARK: - Named Presets

  /// Original pipeline before Phase 1: voting + fineGrid, 3 candidates. Acc1=64.6%.
  public static let baseline = TechniqueSet(
    dspTechniques: [.subBandVoting, .fineGridRefinement]
  )

  /// Empirically best combination: sharp + voting + fineGrid, 3 candidates. Acc1=67.1%.
  public static let optimal = TechniqueSet(
    dspTechniques: [.acfSharpening, .subBandVoting, .fineGridRefinement]
  )

  /// All 7 techniques enabled, 5 candidates. NOT recommended as default.
  public static let full = TechniqueSet(
    dspTechniques: Set(DSPTechnique.allCases)
  )

  /// DnB-optimized: sharp + norm + voting + fineGrid, 3 candidates. Acc1=67.1%.
  public static let dnbOptimized = TechniqueSet(
    dspTechniques: [.acfSharpening, .subBandNormalization, .subBandVoting, .fineGridRefinement]
  )

  /// Click-augmented: optimal + clickTrackCorrelation, 3 candidates.
  /// Story 3-3 ablation at α=0.7 default: ties `.optimal` Acc1 (55/82) on OA300, +1 Acc2 (68/82
  /// vs 67/82). Useful for callers who want rhythmic-alignment rescoring on top of the
  /// optimal pipeline. Default `.optimal` was kept unchanged because the +2-track margin
  /// gate (Task 3.4) was not met.
  public static let clickAugmented = TechniqueSet(
    dspTechniques: [
      .acfSharpening, .subBandVoting, .fineGridRefinement, .clickTrackCorrelation,
    ]
  )

  // MARK: - Ablation

  /// Generates all 2^7 = 128 DSP technique combinations (power set).
  public static func allDSPCombinations() -> [TechniqueSet] {
    let allCases = DSPTechnique.allCases
    let count = allCases.count
    var combinations: [TechniqueSet] = []
    combinations.reserveCapacity(1 << count)

    for mask in 0..<(1 << count) {
      var techniques: Set<DSPTechnique> = []
      for (index, technique) in allCases.enumerated() {
        if mask & (1 << index) != 0 {
          techniques.insert(technique)
        }
      }
      combinations.append(TechniqueSet(dspTechniques: techniques))
    }
    return combinations
  }
}

// MARK: - MLEvaluation

/// Immutable record of an ML model's tempo estimate, returned by
/// ``MLTechnique/evaluate(trace:)``.
///
/// ``MLEvaluation`` is a pure value type — once constructed it carries one
/// candidate BPM, the model's self-reported confidence, and an optional
/// stable identifier. The ensemble combiner inside
/// ``AudioAnalysisService/analyzeBPM(url:options:)`` consumes this value
/// alongside the DSP-derived ``BPMResult`` to produce the final
/// ``AudioAnalysisResult``. Story 4.3 ships a single-case default policy
/// ("DSP wins regardless"); Story 4.4 introduces the public
/// `EnsemblePolicy` enum that switches on richer combine strategies.
///
/// Conformers (Story 4.5 BNNS, Story 4.6 CoreML) construct an
/// ``MLEvaluation`` only when the model produces a confident estimate;
/// returning `nil` from ``MLTechnique/evaluate(trace:)`` is the documented
/// abstain path.
public struct MLEvaluation: Sendable {

  /// Estimated tempo in beats per minute.
  ///
  /// Conformers should clamp predictions to `60.0...200.0` to match the
  /// DSP pipeline's range-normalized candidate space; out-of-range values
  /// surface to the ensemble combiner unchanged. A value of `0` (or any
  /// non-finite) is undefined and is rejected by future ensemble policies
  /// — return `nil` from ``MLTechnique/evaluate(trace:)`` instead.
  public let bpm: Double

  /// Self-reported confidence in `[0.0, 1.0]`.
  ///
  /// Should be the model's calibrated softmax confidence (or equivalent).
  /// Story 4.4's ensemble policies may down-weight uncalibrated values —
  /// conformers SHOULD calibrate using their training-set held-out scores
  /// rather than emit raw logits.
  public let confidence: Double

  /// Optional stable identifier of the producing model.
  ///
  /// Used for forensic trace tagging when Story 4.5 BNNS and Story 4.6
  /// CoreML conformances coexist (e.g., `"bnns_tempo_v1"`,
  /// `"coreml_resnet18_v3"`). Pass `nil` if the model has no stable
  /// identifier or the consumer does not need to distinguish models.
  public let modelIdentifier: String?

  public init(bpm: Double, confidence: Double, modelIdentifier: String? = nil) {
    self.bpm = bpm
    self.confidence = confidence
    self.modelIdentifier = modelIdentifier
  }
}

// MARK: - MLTechnique

/// Extension point for ML-augmented BPM estimation.
///
/// Conformers evaluate the DSP candidate set carried inside
/// ``BPMDiagnosticTrace/candidatesAfterBoost`` against an on-device model
/// and return an ``MLEvaluation`` if the model produces a confident
/// estimate, else `nil`. ML techniques run after the DSP pipeline and
/// after metadata corroboration — they do not modify DSP stages, do not
/// see raw audio samples, and do not duplicate DSP computation.
///
/// ## `nil` return semantics
///
/// Returning `nil` from ``evaluate(trace:)`` is the documented abstain
/// path. The ensemble combiner preserves the DSP result unchanged; the
/// model's silence is treated as "no opinion." Conformers SHOULD return
/// `nil` (rather than a low-confidence value) whenever the input falls
/// outside the model's training distribution.
///
/// ## Synchronous-by-design
///
/// ``evaluate(trace:)`` is intentionally synchronous. Apple's BNNS path
/// (`BNNSGraphContextExecute`, WWDC 2024 #10211) is synchronous and is
/// the canonical real-time CPU inference pattern. CoreML conformances may
/// either use the synchronous `MLModel.prediction(from:)` API or bridge
/// the async API via a semaphore — both paths run safely from
/// ``AudioAnalysisService/analyzeBPM(url:options:)`` because the service
/// is consumer-called from a background `Task`, not `MainActor`.
///
/// ## Canonical conformance shape
///
/// ```swift
/// public struct MyBNNSTechnique: MLTechnique {
///   private let context: BNNSGraph.Context
///   public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
///     // 1. Featurize from trace.onsetEnvelopeLength / candidatesAfterBoost
///     // 2. BNNSGraphContextExecute(context, ...)
///     // 3. Decode logits → (bpm, confidence)
///     // 4. Return nil to abstain when confidence < threshold
///     return MLEvaluation(bpm: 128.0, confidence: 0.92, modelIdentifier: "bnns_v1")
///   }
/// }
/// ```
public protocol MLTechnique: Sendable {

  /// Evaluate the DSP pipeline trace and optionally produce an ML estimate.
  ///
  /// - Parameter trace: Populated diagnostic trace from the just-completed
  ///   DSP pipeline (post metadata corroboration). Read DSP candidates
  ///   from ``BPMDiagnosticTrace/candidatesAfterBoost`` (post-corroboration
  ///   top-level field) or ``BPMDiagnosticTrace/rawCandidates`` (pre-rescore).
  /// - Returns: An ``MLEvaluation`` when the model produces a confident
  ///   estimate, or `nil` to abstain (the DSP result is preserved
  ///   unchanged by the ensemble combiner).
  func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?
}
