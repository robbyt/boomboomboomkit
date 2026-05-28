//
//  WeightedSignal.swift
//  BoomBoomBoomKit
//
//  Payload carried by .present / .demoted SignalParticipation cases.
//

public struct WeightedSignal: Sendable, Codable {
  public let bpm: Double
  public let confidence: Double
  public let source: SignalSource

  public init(bpm: Double, confidence: Double, source: SignalSource) {
    self.bpm = bpm
    self.confidence = confidence
    self.source = source
  }

  /// Trace-only Stage 1 placeholder. Story 6.5 must remove this when
  /// SignalWeights.fileMetadata lands — encodes metadata *presence*, not
  /// calibrated metadata confidence.
  public static let fileMetadataStage1TraceOnlyDefault: Double = 1.0
}
