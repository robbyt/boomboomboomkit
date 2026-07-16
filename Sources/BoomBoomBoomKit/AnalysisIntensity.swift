//
//  AnalysisIntensity.swift
//  BoomBoomBoomKit
//
//  Controls pipeline depth for BPM analysis: a finite 10-level ordinal enum.
//
//  Story 11.2 reshaped this from a struct wrapping `Int rawValue` into a
//  `String`-backed enum so consumers can exhaustively `switch` on levels and
//  Xcode surfaces per-level documentation via `DocumentedCase`. The `String`
//  raw value (`"level7"`) is the documentation filename stem; the ordinal 1...10
//  number is exposed separately as `level`.
//

import Foundation

/// Controls the depth and thoroughness of BPM analysis.
///
/// Higher levels produce more accurate results at the cost of more computation.
/// The scale is ordinal (`Comparable`): `level1 < level2 < … < level10`, and
/// higher numbers never decrease accuracy.
///
/// Levels 1-7 are DSP-only. Levels 8-10 are reserved for future ML integration
/// and currently behave identically to level 7.
///
/// The `String` raw value (`"level1"`…`"level10"`) is the ``documentationID``
/// used to resolve per-level Markdown; the ordinal number is ``level``.
public enum AnalysisIntensity: String, CaseIterable, Sendable, Hashable, Comparable, DocumentedCase
{
  case level1, level2, level3, level4, level5, level6, level7, level8, level9, level10

  // MARK: - DocumentedCase

  /// The documentation catalog subdirectory for this type.
  public static let documentedKind = "AnalysisIntensity"

  // MARK: - Named Constants

  /// Minimal pipeline: 15s window, single candidate, no disambiguation. (~50ms)
  ///
  /// - Note: A convenience alias for ``level1``. Because it is a `static let`
  ///   (not a case), it matches in a `switch` via `case .fastest:` only as an
  ///   `Equatable` expression pattern; such a pattern does not establish enum
  ///   exhaustivity, so the remaining cases (or a `default:`) are still required.
  public static let fastest: AnalysisIntensity = .level1

  /// Full DSP pipeline with all improvements and progressive retry. (~400ms)
  ///
  /// - Note: A convenience alias for ``level7`` (see ``fastest`` for the
  ///   expression-pattern note).
  public static let `default`: AnalysisIntensity = .level7

  /// Reserved for future ML integration. Currently identical to ``default``.
  public static let thorough: AnalysisIntensity = .level8

  /// Reserved for maximum accuracy with ML quorum. Currently identical to ``default``.
  public static let maximum: AnalysisIntensity = .level10

  // MARK: - Ordinal Bridge

  /// The ordinal intensity number (`1`…`10`) for this level.
  ///
  /// Use this wherever the numeric level is needed (display, comparison,
  /// serialization); the ``RawRepresentable`` `rawValue` is the `String`
  /// documentation stem, not the number.
  public var level: Int {
    switch self {
    case .level1: return 1
    case .level2: return 2
    case .level3: return 3
    case .level4: return 4
    case .level5: return 5
    case .level6: return 6
    case .level7: return 7
    case .level8: return 8
    case .level9: return 9
    case .level10: return 10
    }
  }

  /// Creates an intensity from an ordinal level number, or `nil` when `level` is
  /// outside `1...10`.
  ///
  /// Callers that derive `level` from a bounded source (a `1...10` slider, a
  /// pre-clamped CLI argument) should clamp before calling so `nil` is
  /// unreachable — this initializer deliberately does NOT clamp, so an
  /// out-of-range value surfaces as `nil` rather than being silently coerced.
  ///
  /// - Parameter level: The ordinal level in `1...10`.
  public init?(level: Int) {
    guard let match = Self.allCases.first(where: { $0.level == level }) else {
      return nil
    }
    self = match
  }

  // MARK: - Comparable

  /// Orders intensities by ordinal ``level`` (`level1 < … < level10`).
  public static func < (lhs: AnalysisIntensity, rhs: AnalysisIntensity) -> Bool {
    lhs.level < rhs.level
  }

  // MARK: - Computed Configuration Properties

  /// The technique set for this intensity level, based on empirical ablation data.
  ///
  /// Mapping (ADR-2, Phase 2; Story 3-3 ablation revisited but did not change):
  /// - Level 1: empty (minimal pipeline, 1 candidate, no disambiguation)
  /// - Level 2: voting + fineGrid (baseline, 3 candidates)
  /// - Level 3-7: sharp + voting + fineGrid (optimal, 3 candidates, Acc1=67.1%)
  /// - Level 8-10: reserved for ML (same DSP as level 7)
  ///
  /// `.clickTrackCorrelation` is NOT in any default-mapped intensity level:
  /// Story 3-3 ablation showed it ties `.optimal` Acc1 at α=0.7 (no margin to insert).
  /// Users who want the technique can opt in by setting
  /// `AudioAnalysisService.Options.techniqueSet = .clickAugmented`, which overrides the
  /// intensity-derived default.
  public var techniqueSet: TechniqueSet {
    switch self {
    case .level1:
      return TechniqueSet(candidateCount: 1)
    case .level2:
      return .baseline
    default:  // level3 and above
      return .optimal
    }
  }

  /// Analysis window sizes for progressive analysis.
  /// `AudioAnalysisService` iterates over these, passing each to `BPMAnalyzer`.
  public var windowSizes: [Double] {
    switch self {
    case .level1: return [15]
    case .level2, .level3, .level4, .level5: return [30]
    case .level6: return [30, 60]
    default: return [30, 60, 90]  // level7 and above
    }
  }

  /// Confidence threshold below which progressive analysis retries with longer windows.
  /// Returns `nil` when progressive retry is disabled (intensity 1-5).
  public var progressiveThreshold: Double? {
    switch self {
    case .level1, .level2, .level3, .level4, .level5: return nil
    default: return 0.40  // level6 and above
    }
  }
}
