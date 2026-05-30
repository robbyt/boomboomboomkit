//
//  SignalWeights.swift
//  BoomBoomBoomKit
//
//  Per-source vote weights for the unified-signal-pool ensemble.
//

import Foundation

/// Per-source multiplicative vote weights for pool-based BPM selection.
///
/// `SignalWeights` configures how strongly each signal family contributes to the
/// final BPM when ``EnsemblePolicy/weightedVoting(_:)`` selection runs. In Story
/// 6.5a it ships as configurable-but-inert config: the type is public and
/// reachable via ``EnsemblePolicy/weightedVoting(_:)``, but the pool-authoritative
/// selection that consumes it lands in Story 6.5b.
///
/// All weights default to `1.0` (every source family contributes equally).
///
/// ## NaN safety
/// Fields are immutable (`let`) and finite-normalized at construction: a
/// non-finite input (`NaN`, `±∞`) becomes the `1.0` default, and a finite input
/// is clamped to non-negative. This keeps `Hashable` reflexivity intact —
/// `Double.nan` would break `x == x` (project precedent: ``EnsembleDecision`` and
/// the Story 6.1 `SignalParticipation` family drop `Hashable` for unsanitized
/// `Double` fields; `SignalWeights` keeps it by guaranteeing finite fields). The
/// `isFinite` guard precedes the clamp because `min`/`max` propagate `NaN`.
public struct SignalWeights: Sendable, Hashable {

  /// Weight for DSP onset/autocorrelation candidates.
  public let dsp: Double
  /// Weight for the ML model's evaluation.
  public let ml: Double
  /// Weight for file-metadata (tag) corroboration.
  public let fileMetadata: Double
  /// Weight for beat-grid evidence (reserved; no producer ships before Story 6.5b).
  public let beatGrid: Double

  /// Creates per-source weights, finite-normalizing each input
  /// (non-finite → `1.0`; finite → clamped to non-negative).
  public init(
    dsp: Double = 1.0,
    ml: Double = 1.0,
    fileMetadata: Double = 1.0,
    beatGrid: Double = 1.0
  ) {
    self.dsp = SignalWeights.normalize(dsp)
    self.ml = SignalWeights.normalize(ml)
    self.fileMetadata = SignalWeights.normalize(fileMetadata)
    self.beatGrid = SignalWeights.normalize(beatGrid)
  }

  /// Equal weighting (all `1.0`) — the default ensemble behavior.
  public static let `default` = SignalWeights()

  /// `isFinite`-first guard (non-finite → `1.0`), then clamp to non-negative.
  private static func normalize(_ value: Double) -> Double {
    value.isFinite ? max(value, 0.0) : 1.0
  }
}
