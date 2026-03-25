//
//  BPMPipelineConfiguration.swift
//  BoomBoomBoomKit
//
//  Internal configuration struct controlling individual pipeline stages.
//  AnalysisIntensity maps to this; tests can override individual flags.
//

import Foundation

/// Internal configuration controlling which pipeline stages are active.
/// `AnalysisIntensity` is the public API that maps to this.
struct BPMPipelineConfiguration: Sendable {
  var candidateCount: Int = 5
  var useSubBandVoting: Bool = true
  var useACFSharpening: Bool = true
  var useSubBandNormalization: Bool = true
  var useAdaptiveThreshold: Bool = true
  var useFineGridRefinement: Bool = true

  /// Baseline configuration: original pipeline before Phase 1 quick wins.
  /// Matches pre-Phase 1 behavior (3 candidates, sub-band voting, no quick wins).
  static let baseline = BPMPipelineConfiguration(
    candidateCount: 3,
    useSubBandVoting: true,
    useACFSharpening: false,
    useSubBandNormalization: false,
    useAdaptiveThreshold: false,
    useFineGridRefinement: true
  )

  /// Full pipeline with all Phase 1 improvements.
  static let full = BPMPipelineConfiguration()

  /// Creates a configuration from an AnalysisIntensity level.
  init(intensity: AnalysisIntensity) {
    candidateCount = intensity.candidateCount
    useSubBandVoting = intensity.useSubBandVoting
    useACFSharpening = intensity.useACFSharpening
    useSubBandNormalization = intensity.useSubBandNormalization
    useAdaptiveThreshold = intensity.useAdaptiveThreshold
    useFineGridRefinement = intensity.useFineGridRefinement
  }

  /// Default init with all features enabled (matches intensity 7).
  init(
    candidateCount: Int = 5,
    useSubBandVoting: Bool = true,
    useACFSharpening: Bool = true,
    useSubBandNormalization: Bool = true,
    useAdaptiveThreshold: Bool = true,
    useFineGridRefinement: Bool = true
  ) {
    self.candidateCount = candidateCount
    self.useSubBandVoting = useSubBandVoting
    self.useSubBandNormalization = useSubBandNormalization
    self.useACFSharpening = useACFSharpening
    self.useAdaptiveThreshold = useAdaptiveThreshold
    self.useFineGridRefinement = useFineGridRefinement
  }

  /// Human-readable label for this configuration.
  var label: String {
    var flags: [String] = []
    if useACFSharpening { flags.append("sharp") }
    if useAdaptiveThreshold { flags.append("thresh") }
    if useSubBandNormalization { flags.append("norm") }
    if candidateCount > 3 { flags.append("top\(candidateCount)") }
    if useFineGridRefinement { flags.append("fine") }
    if useSubBandVoting { flags.append("vote") }
    return flags.isEmpty ? "minimal" : flags.joined(separator: "+")
  }
}
