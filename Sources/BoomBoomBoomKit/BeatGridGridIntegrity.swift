//
//  BeatGridGridIntegrity.swift
//  BoomBoomBoomKit
//
//  Shared grid-integrity gate for the downbeat estimators (Story 8.5a / 8.11).
//  Single home for the off-grid tolerances so `DownbeatAnalyzer` and
//  `StructuralDropAnalyzer` can't drift. Caseless-enum namespace per the
//  project's `MelFilterbank` / `BeatGridClamp` precedent.
//

import Foundation

/// Shared "is the beat grid too shredded to trust" predicate for the downbeat
/// estimators. Counts inter-beat intervals deviating from the expected beat
/// period by more than ``gridDeviationTolerance`` and reports `true` when that
/// fraction exceeds ``gridOffGridFractionLimit`` — the caller should then abstain
/// rather than fold a phase from an unreliable beat array.
enum BeatGridGridIntegrity {

  /// An inter-beat interval deviating from the beat period by more than this
  /// fraction is "off-grid" (25%).
  static let gridDeviationTolerance = 0.25

  /// If more than this fraction of inter-beat intervals are off-grid, the DP
  /// shredded the grid → caller should abstain rather than fold a phase from it
  /// (20%).
  static let gridOffGridFractionLimit = 0.20

  /// True when too many inter-beat intervals deviate from `beatPeriod`:
  /// `offGrid / intervalCount > gridOffGridFractionLimit`. Fewer than 2 beats
  /// (no intervals) is never shredded → `false`.
  ///
  /// Caller passes a finite, positive `beatPeriod` (both callers already guard
  /// `estimatedTempo` finite & `> 0` before computing `beatPeriod = 60 /
  /// estimatedTempo`, and `beats.allSatisfy { $0.presentationTime.isFinite }`),
  /// so the helper does not re-guard NaN/Inf.
  static func isShredded(beats: [BeatTimestamp], beatPeriod: Double) -> Bool {
    let intervalCount = beats.count - 1
    guard intervalCount > 0 else { return false }
    var offGrid = 0
    for i in 1..<beats.count {
      let dt = beats[i].presentationTime - beats[i - 1].presentationTime
      if abs(dt - beatPeriod) / beatPeriod > gridDeviationTolerance { offGrid += 1 }
    }
    return Double(offGrid) > gridOffGridFractionLimit * Double(intervalCount)
  }
}
