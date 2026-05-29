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

  /// The exact operative `Float` candidate-fusion score, carried alongside the
  /// widened `confidence: Double`. Populated ONLY for DSP `.present(...)` pool
  /// entries (from the `BPMResult.candidates` tuple `.score` member); `nil` for
  /// file-metadata signals (which carry the `fileMetadataStage1TraceOnlyDefault`
  /// presence sentinel in `confidence`, not a fusion score). Story 6.4a adds
  /// this as a strictly-dead carrier — populated but read by no production code —
  /// so Story 6.4b can read the exact `Float` off the pool when it flips the
  /// merge carrier, WITHOUT a lossy `Double → Float` reconstruction across the
  /// commit where byte-equality becomes semantic-equality. Do not wire a read
  /// path in 6.4a: the `.stage2Floor` byte floor stays green precisely because
  /// nothing consumes this field.
  public let score: Float?

  public init(
    bpm: Double,
    confidence: Double,
    source: SignalSource,
    score: Float? = nil
  ) {
    self.bpm = bpm
    self.confidence = confidence
    self.source = source
    self.score = score
  }

  /// Trace-only Stage 1 placeholder. Story 6.5 must remove this when
  /// SignalWeights.fileMetadata lands — encodes metadata *presence*, not
  /// calibrated metadata confidence.
  public static let fileMetadataStage1TraceOnlyDefault: Double = 1.0
}
