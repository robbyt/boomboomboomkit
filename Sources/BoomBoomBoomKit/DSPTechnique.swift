//
//  DSPTechnique.swift
//  BoomBoomBoomKit
//
//  Closed enum of DSP pipeline techniques, composable TechniqueSet,
//  and open MLTechnique protocol for future CoreML integration.
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

  /// Short label used in ablation output (e.g., "sharp", "vote").
  var shortName: String {
    switch self {
    case .acfSharpening: return "sharp"
    case .adaptiveThreshold: return "thresh"
    case .subBandNormalization: return "norm"
    case .expandedCandidates: return "top5"
    case .fineGridRefinement: return "fine"
    case .subBandVoting: return "vote"
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
    return copy
  }

  public func removing(_ technique: DSPTechnique) -> TechniqueSet {
    var copy = self
    copy.dspTechniques.remove(technique)
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

  /// All 6 techniques enabled, 5 candidates. Acc1=59.8%. NOT recommended as default.
  public static let full = TechniqueSet(
    dspTechniques: Set(DSPTechnique.allCases)
  )

  /// DnB-optimized: sharp + norm + voting + fineGrid, 3 candidates. Acc1=67.1%.
  public static let dnbOptimized = TechniqueSet(
    dspTechniques: [.acfSharpening, .subBandNormalization, .subBandVoting, .fineGridRefinement]
  )

  // MARK: - Ablation

  /// Generates all 2^6 = 64 DSP technique combinations (power set).
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

// MARK: - MLTechnique

/// Extension point for future ML-based BPM estimation (Phase 3).
///
/// ML techniques evaluate candidates post-pipeline — they do not modify DSP stages.
/// Conformances receive a `BPMDiagnosticTrace` (not raw samples) to avoid
/// duplicating DSP computation inside the ML model.
///
/// **Note:** Callers must pass `enableTrace: true` when ML techniques are present.
/// Auto-enabling trace is deferred to Phase 3.
public protocol MLTechnique: Sendable {
  var name: String { get }

  /// Evaluate pipeline candidates and optionally return an alternative BPM estimate.
  /// Returns `nil` to defer to the DSP result.
  func evaluate(
    candidates: [(bpm: Double, score: Float)],
    trace: BPMDiagnosticTrace
  ) -> (bpm: Double, confidence: Double)?
}
