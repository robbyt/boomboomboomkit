//
//  DecodedAudio.swift
//  BoomBoomBoomKit
//
//  Source-of-truth carrier for decoded PCM samples + sample rate.
//

import Foundation

extension FeatureSubstrate {

  public struct DecodedAudio: Sendable {

    public let samples: [Float]
    public let sampleRate: Double
    public let codecPriming: PrimingInfo

    public init(
      samples: [Float],
      sampleRate: Double,
      codecPriming: PrimingInfo
    ) {
      // The 8 kHz floor is the audio-engineering practical minimum (G.711
      // telephone quality) AND a hard requirement of the BPM/onset pipeline:
      // `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` derives
      // `hopSize = Int(sampleRate / 100)`, so any rate `< 100` yields
      // `hopSize == 0` and the frame-stepping loop fails to advance. We
      // require `>= 8000` rather than the bare `>= 100` because anything
      // below 8 kHz makes the 2048-sample FFT frame coarser than ~256 ms,
      // which is meaningless for onset detection on real music.
      precondition(
        sampleRate.isFinite && sampleRate >= 8_000,
        "sampleRate must be finite and >= 8000 Hz (got \(sampleRate)); "
          + "recoverable user-input validation lives at PCMBufferReader.readMonoSamples")
      self.samples = samples
      self.sampleRate = sampleRate
      self.codecPriming = codecPriming
    }
  }
}
