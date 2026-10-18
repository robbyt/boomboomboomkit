//
//  DSPStubObservationProducer.swift
//  BoomBoomBoomKit
//
//  Story 15.6: DSP-derived stub conforming to ``FramewiseObservationProducer``.
//  Converts ``BPMAnalyzer``'s existing full-band onset envelope into
//  per-frame beat and downbeat probabilities, so the whole pipeline from
//  observations through the 4/4 structured decoder can integrate end-to-end
//  before a trained observation head arrives.
//
//  Not a replacement for a learned producer. The DSP stub carries no
//  trained-model identity: `modelIdentifier` is `dsp-stub.v1` and
//  `frontendIdentifier` is `bpmanalyzer-onset.v1`, so a later diff can see
//  at a glance that this observation stream came from the DSP envelope path.
//

import Foundation

/// DSP-derived stub producer. Builds a ``FramewiseObservations`` stream
/// from the full-band onset envelope ``BPMAnalyzer`` already computes.
///
/// ## Mapping
/// For each envelope frame `f`:
///
/// - `beatProbabilities[f] = clamp01(envelope[f] / envMax)`;
/// - `downbeatProbabilities[f] = beatProbabilities[f] * downbeatBias`,
///   where `downbeatBias` is a flat 0.5 so the stub emits a sensible
///   downbeat trail without inventing bar-level evidence it does not have.
///
/// ## Frame timing
/// The emitted ``FramewiseObservations/frameRate`` is
/// `sampleRate / hopSize` (100 fps at 44.1 kHz with the default hop 441),
/// and probabilities sit on the onset-envelope grid. The producer sets
/// ``FramewiseObservations/firstFrameOriginSeconds`` to
/// `(hopSize + fftSize / 2) / sampleRate`, which absorbs the Story 15.3
/// frame-time convention: envelope index `f` carries the energy rise
/// entering STFT frame `f + 1`, whose Hann-windowed energy centers at sample
/// `(f + 1) * hopSize + fftSize / 2`. So
/// ``FramewiseObservations/timeForFrame(_:)`` already returns the same
/// instant ``BeatGridAnalyzer`` reports for that envelope index, and no
/// consumer applies the convention a second time.
internal struct DSPStubObservationProducer: FramewiseObservationProducer {

  /// Hop size used to compute the envelope. Must match the hop
  /// ``BPMAnalyzer/computeMelOnsetEnvelope(samples:sampleRate:hopSize:)``
  /// was called with.
  let hopSize: Int

  init(hopSize: Int) {
    precondition(hopSize > 0, "hopSize must be positive")
    self.hopSize = hopSize
  }

  var modelIdentifier: String { "dsp-stub.v1" }

  func produce(decoded: FeatureSubstrate.DecodedAudio) -> FramewiseObservations? {
    let envelope = BPMAnalyzer.computeMelOnsetEnvelope(
      samples: decoded.samples,
      sampleRate: decoded.sampleRate,
      hopSize: hopSize
    )
    guard !envelope.isEmpty else { return nil }

    // Story 15.3 convention: envelope index `f` carries the energy rise
    // entering STFT frame `f + 1`, whose Hann-windowed energy centers at
    // sample `(f + 1) * hopSize + fftSize / 2`. The producer absorbs that
    // offset into `firstFrameOriginSeconds` so a decoder's `timeForFrame(f)`
    // matches the convention `BeatGridAnalyzer` uses. With a zero origin a
    // fit against the stub observations would sit `hopSize + fftSize / 2`
    // samples earlier than `BeatGridAnalyzer` output on the same envelope.
    let originSeconds =
      (Double(hopSize) + Double(BPMAnalyzer.fftSize) / 2.0) / decoded.sampleRate

    let envMax = envelope.max() ?? 0
    guard envMax > 0 else {
      // Silent input: emit all-zero probabilities over the usable span so a
      // caller sees "we observed nothing" rather than nil.
      let zeros = [Float](repeating: 0, count: envelope.count)
      return FramewiseObservations(
        frameRate: decoded.sampleRate / Double(hopSize),
        firstFrameOriginSeconds: originSeconds,
        coverageWindowSeconds: Double(envelope.count) * Double(hopSize) / decoded.sampleRate,
        beatProbabilities: zeros,
        downbeatProbabilities: zeros,
        modelIdentifier: modelIdentifier,
        frontendIdentifier: Self.frontendIdentifier
      )
    }

    // Flat downbeat bias so the stub emits sensible-looking downbeat data
    // without inventing bar-level evidence it does not have.
    let downbeatBias: Float = 0.5
    var beatProbs = [Float](repeating: 0, count: envelope.count)
    var downbeatProbs = [Float](repeating: 0, count: envelope.count)
    for i in 0..<envelope.count {
      let normalized = min(1.0, max(0.0, envelope[i] / envMax))
      beatProbs[i] = normalized
      downbeatProbs[i] = normalized * downbeatBias
    }

    return FramewiseObservations(
      frameRate: decoded.sampleRate / Double(hopSize),
      firstFrameOriginSeconds: originSeconds,
      coverageWindowSeconds: Double(envelope.count) * Double(hopSize) / decoded.sampleRate,
      beatProbabilities: beatProbs,
      downbeatProbabilities: downbeatProbs,
      modelIdentifier: modelIdentifier,
      frontendIdentifier: Self.frontendIdentifier
    )
  }

  /// Opaque identifier for the DSP envelope path. Any change to
  /// ``BPMAnalyzer/computeMelOnsetEnvelope(samples:sampleRate:hopSize:)``'s
  /// algorithm must bump this: a new mel schema, a different log
  /// compression, or a different temporal-diff policy.
  static let frontendIdentifier = "bpmanalyzer-onset.v1"
}
