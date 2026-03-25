//
//  AnalysisIntensity.swift
//  BoomBoomBoomKit
//
//  Controls pipeline depth for BPM analysis.
//  Follows UILayoutPriority pattern: struct wrapping Int, ordinal scale.
//

import Foundation

/// Controls the depth and thoroughness of BPM analysis.
///
/// Higher values produce more accurate results at the cost of more computation.
/// The scale is ordinal: higher numbers never decrease accuracy.
///
/// Levels 1-7 are DSP-only. Levels 8-10 are reserved for future ML integration
/// and currently behave identically to level 7.
public struct AnalysisIntensity: Sendable, Hashable, Comparable {

  /// The raw intensity level (1-10).
  public let rawValue: Int

  /// Creates an intensity level, clamping to the valid range 1-10.
  public init(rawValue: Int) {
    self.rawValue = min(max(rawValue, 1), 10)
  }

  // MARK: - Named Constants

  /// Minimal pipeline: 15s window, single candidate, no disambiguation. (~50ms)
  public static let fastest = AnalysisIntensity(rawValue: 1)

  /// Full DSP pipeline with all improvements and progressive retry. (~400ms)
  public static let `default` = AnalysisIntensity(rawValue: 7)

  /// Reserved for future ML integration. Currently identical to `.default`.
  public static let thorough = AnalysisIntensity(rawValue: 8)

  /// Reserved for maximum accuracy with ML quorum. Currently identical to `.default`.
  public static let maximum = AnalysisIntensity(rawValue: 10)

  // MARK: - Computed Configuration Properties

  /// Number of top candidates to extract from the periodicity spectrum.
  public var candidateCount: Int {
    switch rawValue {
    case 1: return 1
    case 2...4: return 3
    default: return 5  // 5+
    }
  }

  /// Analysis window sizes for progressive analysis.
  /// `AudioAnalysisService` iterates over these, passing each to `BPMAnalyzer`.
  public var windowSizes: [Double] {
    switch rawValue {
    case 1: return [15]
    case 2...5: return [30]
    case 6: return [30, 60]
    default: return [30, 60, 90]  // 7+
    }
  }

  /// Whether sub-band onset detection and voting should run.
  /// When false, only full-band onset envelope is computed.
  public var useSubBandVoting: Bool {
    rawValue >= 3
  }

  /// Whether to apply element-wise squaring to the ACF before fusion.
  public var useACFSharpening: Bool {
    rawValue >= 3
  }

  /// Whether to normalize each sub-band envelope to [0,1] before summing.
  public var useSubBandNormalization: Bool {
    rawValue >= 3
  }

  /// Whether to apply running-mean adaptive thresholding to the onset envelope.
  public var useAdaptiveThreshold: Bool {
    rawValue >= 4
  }

  /// Whether to run fine-grid DFT refinement on the winning candidate.
  public var useFineGridRefinement: Bool {
    rawValue >= 5
  }

  /// Confidence threshold below which progressive analysis retries with longer windows.
  /// Returns `nil` when progressive retry is disabled (intensity 1-5).
  public var progressiveThreshold: Double? {
    rawValue >= 6 ? 0.40 : nil
  }

  // MARK: - Comparable

  public static func < (lhs: AnalysisIntensity, rhs: AnalysisIntensity) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - ExpressibleByIntegerLiteral

extension AnalysisIntensity: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(rawValue: value)
  }
}
