//
//  WaveformChannelPolicy.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — explicit stereo handling for waveform analysis.
//

/// How ``WaveformAnalyzer`` consumes the channels of a stereo audio source.
///
/// Phase 1 of Story 15.4 ships ``mono`` only. The remaining four cases are
/// reserved public API with a documented not-yet-implemented stance
/// (follow-up Story 15.4b), the same pattern ``WeightingProfile`` uses for
/// ``WeightingProfile/subBandEmphasis``. The enum is defined up front so
/// no caller-visible API churn is required when the follow-up lands.
public enum WaveformChannelPolicy: String, Sendable, Hashable, Codable, CaseIterable {
  /// Consume a mono ``FeatureSubstrate/DecodedAudio`` directly. Implemented.
  case mono

  /// Consume only the left channel of a stereo source. Reserved.
  case leftOnly

  /// Consume only the right channel of a stereo source. Reserved.
  case rightOnly

  /// Produce two full outputs, one per channel. Reserved.
  case perChannel

  /// Mix L and R to a single stream via `sqrt((L^2 + R^2) / 2)` so an
  /// anti-phase stereo signal does not cancel to zero. Reserved; the
  /// handoff explicitly calls out that `(L + R) / 2` is wrong here.
  case mixDownRespectingPhase

  /// Whether the policy is implemented at the current library revision.
  /// Phase 1 of Story 15.4 implements only ``mono``.
  public var isImplemented: Bool { self == .mono }
}
