//
//  DecodedAudio.swift
//  BoomBoomBoomKit
//
//  Source-of-truth carrier for decoded PCM samples + sample rate.
//

import Foundation

extension FeatureSubstrate {

  /// Decoded mono PCM audio — the shared-decode currency every analyzer
  /// consumes (mono by KDD-S2; the KDD-C4 seam carrier).
  ///
  /// Produce one with ``PCMBufferReader/readDecodedAudio(from:maxSeconds:)``
  /// and fan it out to `AudioAnalysisService.analyzeBPM(decoded:options:)`
  /// and `analyzeLUFS(decoded:options:)` so combined analysis pays for the
  /// decode exactly once.
  public struct DecodedAudio: Sendable {

    /// Mono samples normalized to [-1.0, 1.0].
    public let samples: [Float]

    /// Sample rate of ``samples`` in Hz — finite and ≥ 8000 by the
    /// initializer's precondition.
    public let sampleRate: Double

    /// Codec + trim-state provenance of the decode that produced
    /// ``samples``. Carrier metadata only — no analysis stage branches on
    /// it (test-locked provenance invariance).
    public let codecPriming: PrimingInfo

    /// Creates a carrier from already-decoded samples.
    ///
    /// `sampleRate` must be finite and ≥ 8000 Hz; violating that is a
    /// programmer error (precondition trap). Recoverable validation of
    /// user-supplied files lives at the `PCMBufferReader` boundary.
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
