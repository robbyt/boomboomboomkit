//
//  DecodedAudioFixtures.swift
//  BoomBoomBoomKitTestSupport
//
//  Test-construction helper for FeatureSubstrate.DecodedAudio.
//

import BoomBoomBoomKit
import Foundation

extension FeatureSubstrate.DecodedAudio {

  /// Wraps raw samples in a ``FeatureSubstrate/DecodedAudio`` carrier with
  /// pinned provenance — the single construction path for synthesized /
  /// pre-decoded test signals (Story 8-2 DD #4).
  ///
  /// Provenance is pinned to `.linearPCM` + `.knownNone` so tests never
  /// hand-pick codec tags: `DecodedAudio` is a carrier, nothing downstream
  /// may branch on provenance fields, and the provenance-invariance test in
  /// `SharedDecodeTests` locks that contract.
  ///
  /// Inherits the `DecodedAudio.init` precondition: `sampleRate` must be
  /// finite and >= 8000 Hz. Tests exercising sub-8 kHz rates belong at the
  /// `PCMBufferReader` boundary (the recoverable-validation layer), not here.
  public static func synthetic(
    _ samples: [Float], sampleRate: Double
  ) -> FeatureSubstrate.DecodedAudio {
    FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone))
  }
}
