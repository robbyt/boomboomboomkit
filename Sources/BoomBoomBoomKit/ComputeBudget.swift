//
//  ComputeBudget.swift
//  BoomBoomBoomKit
//
//  Per-source compute-budget fractions derived from analysis intensity.
//

import Foundation

/// Per-source compute-budget fractions in `[0.0, 1.0]`.
///
/// `ComputeBudget` expresses how much of each signal family's full work to
/// perform — the intensity dial, re-expressed per source. In Story 6.5a it ships
/// as configurable-but-inert config; intensity-proportional budgeting is wired
/// into the pool-authoritative selection in Story 6.5b.
///
/// ## NaN safety
/// Fields are immutable (`let`) and finite-clamped at construction: a non-finite
/// input becomes `1.0`, and a finite input is clamped to `[0.0, 1.0]` (the
/// `isFinite` guard precedes the clamp because `min`/`max` propagate `NaN`). This
/// keeps `Hashable` reflexivity intact. The `let` fields close the post-init
/// mutation hole a `var` would leave open.
public struct ComputeBudget: Sendable, Hashable {

  /// Fraction of the DSP budget to spend (`[0.0, 1.0]`).
  public let dspFraction: Double
  /// Fraction of the ML budget to spend (`[0.0, 1.0]`).
  public let mlFraction: Double
  /// Fraction of the beat-grid budget to spend (`[0.0, 1.0]`).
  public let beatGridFraction: Double

  /// Creates a compute budget, finite-clamping each fraction to `[0.0, 1.0]`
  /// (non-finite → `1.0`).
  public init(
    dspFraction: Double = 1.0,
    mlFraction: Double = 1.0,
    beatGridFraction: Double = 1.0
  ) {
    self.dspFraction = ComputeBudget.clamp(dspFraction)
    self.mlFraction = ComputeBudget.clamp(mlFraction)
    self.beatGridFraction = ComputeBudget.clamp(beatGridFraction)
  }

  /// Full budget (all `1.0`).
  public static let `default` = ComputeBudget()

  /// `isFinite`-first guard (non-finite → `1.0`), then clamp to `[0.0, 1.0]`.
  private static func clamp(_ value: Double) -> Double {
    value.isFinite ? min(max(value, 0.0), 1.0) : 1.0
  }
}

extension AnalysisIntensity {

  /// The compute budget implied by this intensity level.
  ///
  /// Story 6.5a ships this mapping inert (every level maps to the full
  /// ``ComputeBudget/default``); intensity-proportional budgeting is wired into
  /// the pool-authoritative selection in Story 6.5b.
  public var budget: ComputeBudget { .default }
}
