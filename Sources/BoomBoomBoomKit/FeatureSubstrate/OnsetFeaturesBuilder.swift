//
//  OnsetFeaturesBuilder.swift
//  BoomBoomBoomKit
//
//  Shared producer for FeatureSubstrate.OnsetFeatures.
//

import Foundation

// MARK: - Tier-1 facade pattern
// This builder wraps `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` and
// exposes the substrate type contract without yet inverting the dependency
// direction. Tier-3 (planned Story 6.5+ / Epic 8) flips the direction so
// `BPMAnalyzer` consumes the builder.

extension FeatureSubstrate {

  public enum OnsetFeaturesBuilder {

    public static func build(
      decoded: DecodedAudio,
      weighting: WeightingProfile
    ) throws -> OnsetFeatures {
      switch weighting {
      case .subBandEmphasis:
        throw FeatureSubstrateError.weightingNotYetImplemented(weighting)
      case .uniform:
        break
      }

      let hopSize = Int(decoded.sampleRate / 100)
      let envelopes = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
        samples: decoded.samples,
        sampleRate: decoded.sampleRate,
        hopSize: hopSize,
        computeSubBands: true,
        normalizeSubBands: false,
        captureMLFeatures: true
      )

      if envelopes.fullBand.isEmpty {
        throw FeatureSubstrateError.featurizationFailed(
          reason:
            "BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands returned empty "
            + "(input audio too short for at least 2 mel frames at hopSize=\(hopSize))")
      }
      guard let retained = envelopes.mlFeatures else {
        throw FeatureSubstrateError.featurizationFailed(
          reason:
            "retained MLFeatureFrames is nil — upstream `MLFeatureFrames.init` rejected "
            + "the payload. Common causes include size cap of "
            + "\(MLFeatureFrames.maximumLogMelDataCount) floats, integer overflow on "
            + "`melBands * frames`, count mismatch, or non-finite values in `logMelData`; "
            + "other invariants (sampleRate / fftSize / hopSize / melFmin / melFmax / "
            + "logCompressionScale / non-empty featureSetVersion) are unreachable through "
            + "the builder's current call shape but can fire on direct `MLFeatureFrames.init`")
      }

      let parameters = OnsetFeatures.Parameters(
        fftSize: retained.fftSize,
        hopSize: retained.hopSize,
        melFmin: retained.melFmin,
        melFmax: retained.melFmax,
        logCompressionScale: retained.logCompressionScale
      )
      return try OnsetFeatures(
        frames: retained.frames,
        melBands: retained.melBands,
        logMelData: retained.logMelData,
        tensorLayout: retained.tensorLayout,
        weighting: weighting,
        featureSetVersion: retained.featureSetVersion,
        parameters: parameters
      )
    }
  }
}
