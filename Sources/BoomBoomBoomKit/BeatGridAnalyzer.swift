//
//  BeatGridAnalyzer.swift
//  BoomBoomBoomKit
//
//  Internal placeholder for the Epic-8 beat-grid analyzer.
//

import Foundation

/// Story 8.4 placeholder: real beat-tracking (Davies & Plumbley dynamic
/// programming, step-11 insertion) replaces this.
///
/// The stub is not behaviorless scaffolding — its single member makes the
/// KDD-C4 cross-consumer invariant assertable TODAY (Story 8-2 AC4b): the
/// beat-grid consumer receives the SAME `DecodedAudio` the BPM and LUFS
/// analyzers share, and produces bit-equal `OnsetFeatures` through the
/// Story 6.2 Tier-1 builder facade. No `BeatGrid` public types land before
/// Story 8.3.
enum BeatGridAnalyzer {

  /// Produces the onset-feature substrate for beat tracking from decoded
  /// audio. Story 8.4 replaces the body with the real tracker; the
  /// signature (decoded carrier in, substrate out) is the seam.
  static func onsetFeatures(
    for decoded: FeatureSubstrate.DecodedAudio,
    weighting: FeatureSubstrate.WeightingProfile
  ) throws -> FeatureSubstrate.OnsetFeatures {
    try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: weighting)
  }
}
