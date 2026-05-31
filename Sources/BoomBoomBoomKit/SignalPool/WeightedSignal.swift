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
  /// file-metadata signals (which record metadata *presence* in `confidence`,
  /// not a fusion score). Story 6.4a added this as a carrier; Story 6.5b makes
  /// it readable off the pool via ``SignalParticipation/score`` (DD #5) when the
  /// pool-authoritative `BPMSelectionPolicy.select` flips byte-equality to
  /// semantic-equality — no lossy `Double → Float` reconstruction.
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
}
