//
//  DSPTechnique.swift
//  BoomBoomBoomKit
//
//  Closed enum of DSP pipeline techniques and the composable TechniqueSet.
//  The MLTechnique protocol + MLEvaluation return type live in
//  MLTechnique.swift (relocated by Story 4.5 chunk-4 review 2026-05-13;
//  Story 4.3 wired the path, Stories 4.5/4.6 ship BNNS/CoreML conformances).
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

  /// SuperFlux onset detection (Böck & Widmer 2013, DAFx).
  /// Replaces the baseline log-mel spectral flux reference frame `M[t-1][k]` with a
  /// frequency-neighborhood maximum `max(M[t-1][k-r:k+r])` (r=1, window=3 mel bins) before
  /// per-frame differencing. Targets vibrato suppression on pitched-instrument onsets;
  /// secondary hypothesis (Story 4-7) was that the widened reference helps on heavily-mastered
  /// material where limiter-flattened transients confuse the baseline differencing.
  /// Cost: one extra `vDSP_vswmax` pass per frame at the onset-envelope step (~3% of step 3).
  ///
  /// **Story 4-7 brutal-corpus-gate outcome: Branch B (inert-ship).** Per
  /// `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`, the variant
  /// changes per-track output on 82/82 OA300 tracks but resolves zero of the four named DnB
  /// triplet failures (Charly, Faraday_Bunker, Yin Yang, HEFT_Anagram 6) and regresses two
  /// of four DSP-correct controls (Hellacopta, Darkgray Heart) outside the ±0.5 BPM
  /// tolerance. Enabling this case on top of `.optimal` regresses OA300 DSP-only Acc1
  /// by 4 tracks (55 → 51); see
  /// `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json` for
  /// per-track impact. The case is NOT included in any production preset (`.optimal`,
  /// `.dnbOptimized`, `.clickAugmented`); `.full` auto-includes via `Set(allCases)`
  /// construction (per AC #4 Branch B). Available for consumer experimentation:
  /// `var opts = AudioAnalysisService.Options(); opts.techniqueSet = TechniqueSet.optimal.inserting(.superFluxOnset)`.
  case superFluxOnset

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
    case .superFluxOnset: return "superFlux"
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

  /// All 8 techniques enabled, 5 candidates. NOT recommended as default.
  /// As of Story 4-7, `Set(DSPTechnique.allCases)` auto-includes `.superFluxOnset`,
  /// which regressed OA300 Acc1 by 4 tracks on top of `.optimal` per the brutal-corpus
  /// gate — see `DSPTechnique.superFluxOnset` doc for context.
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

  /// Generates all 2^8 = 256 DSP technique combinations (power set).
  /// Grew from 2^6 = 64 (pre-Story-3-3) to 2^7 = 128 (Story 3-3 added `.clickTrackCorrelation`)
  /// to 2^8 = 256 (Story 4-7 added `.superFluxOnset`).
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
