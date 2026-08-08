//
//  AccuracyTally.swift
//  BoomBoomBoomKitTestSupport
//
//  Story 12.3 (FR-61): `Acc2 - Acc1` is the standard octave-error proxy and this
//  type makes it a named field rather than something every reader subtracts by
//  hand. Also carries the shared MIREX hit helper so the previously hand-rolled
//  primary-or-`tempo2` pairings share one verdict contract.
//

import Foundation

/// An Acc1/Acc2 accuracy tally with its annotation version and the octave-error
/// proxy as first-class values.
public struct AccuracyTally: Sendable {
  public let acc1: Int
  public let acc2: Int
  public let total: Int
  public let annotationVersion: AnnotationVersion

  public enum TallyError: Error, Equatable, Sendable {
    /// Acc2 is a superset of Acc1 by definition (and both are bounded by `total`);
    /// a violation is a caller bug and is unrepresentable.
    case invalidCounts(acc1: Int, acc2: Int, total: Int)
  }

  public init(acc1: Int, acc2: Int, total: Int, annotationVersion: AnnotationVersion) throws {
    guard acc1 >= 0, acc1 <= acc2, acc2 <= total else {
      throw TallyError.invalidCounts(acc1: acc1, acc2: acc2, total: total)
    }
    self.acc1 = acc1
    self.acc2 = acc2
    self.total = total
    self.annotationVersion = annotationVersion
  }

  /// `Acc2 - Acc1` as a track COUNT — the octave-error proxy (FR-61).
  public var octaveErrorProxy: Int { acc2 - acc1 }

  /// The proxy in percentage points: `100 * (acc2 - acc1) / total`, `0.0` when
  /// `total == 0`.
  public var octaveErrorProxyPercentagePoints: Double {
    total > 0 ? 100.0 * Double(acc2 - acc1) / Double(total) : 0.0
  }

  /// Printed form showing both the count and the percentage points to one decimal
  /// place, e.g. `16 (19.5 pp)`.
  public var formattedOctaveErrorProxy: String {
    "\(octaveErrorProxy) (\(String(format: "%.1f", octaveErrorProxyPercentagePoints)) pp)"
  }

  /// The shared headline line(s) for the octave-error proxy (Story 12.3 review).
  /// Without a strict tally: the single-corpus one-line form (OA300, which has no
  /// alternate annotation, so floor and strict coincide and the label claims
  /// neither). With `strict`: the two-line GiantSteps form, both readings
  /// clearly labelled — `self` is the floor-compatible tally, `strict` the
  /// primary-annotation-only one.
  public func formattedProxyLines(strict: AccuracyTally? = nil) -> [String] {
    guard let strict else {
      return ["Acc2-Acc1 (octave-error proxy): \(formattedOctaveErrorProxy)"]
    }
    return [
      "Acc2-Acc1 octave-error proxy (floor-compatible): \(formattedOctaveErrorProxy)",
      "Acc2-Acc1 octave-error proxy (primary-strict): \(strict.formattedOctaveErrorProxy)",
    ]
  }
}

// MARK: - Shared MIREX verdict

/// The MIREX Acc1/Acc2 verdicts for one `(detected, truth)` pairing, with the
/// octave-strict (primary-annotation-only) and floor-compatible
/// (primary-or-alternate) readings kept DISTINCT.
///
/// WHAT THE ALTERNATE-ANNOTATION FALLBACK COSTS, and why an octave experiment must
/// not use the floor metric alone (relocated from `GiantStepsBenchmarkTests.mirexHit`,
/// Story 12.3). GiantSteps ground truth v2 ships a second annotation on 577 of its
/// 661 rows, and 361 of those sit within the 2% tolerance of an octave relation to
/// the primary value (303 at half, 58 at double). Accepting either value therefore
/// makes the committed Acc1 >= 537 / Acc2 >= 546 floors close to blind to octave
/// behaviour: measured, the gap between strict and floor-compatible scoring is
/// 71 tracks at the default configuration (466 strict against 537). That is the
/// right trade for a general tempo benchmark and the wrong one for any experiment
/// whose subject IS the metrical level — which is why `Acc2 - Acc1` (FR-61) is
/// meaningful only when both verdicts are available, and why this helper returns
/// both rather than pre-absorbing the octave error into the floor metric.
public struct MIREXTempoVerdict: Sendable, Equatable {
  /// Acc1 against the primary annotation only.
  public let strictAcc1: Bool
  /// Acc2 (metric-factor family) against the primary annotation only.
  public let strictAcc2: Bool
  /// Acc1 against the primary OR the alternate annotation (the committed floors).
  public let floorAcc1: Bool
  /// Acc2 against the primary OR the alternate annotation.
  public let floorAcc2: Bool

  /// The all-false verdict, e.g. for a nil-BPM (no result) pairing.
  public static let miss = MIREXTempoVerdict(
    strictAcc1: false, strictAcc2: false, floorAcc1: false, floorAcc2: false)

  public init(strictAcc1: Bool, strictAcc2: Bool, floorAcc1: Bool, floorAcc2: Bool) {
    self.strictAcc1 = strictAcc1
    self.strictAcc2 = strictAcc2
    self.floorAcc1 = floorAcc1
    self.floorAcc2 = floorAcc2
  }
}

/// The shared floor-compatible/octave-strict MIREX pairing. With `alternate == nil`
/// the floor verdicts equal the strict ones. Pure extraction of the hand-rolled
/// expressions it replaced — adopting it must not change any suite's hit count.
public func mirexTempoVerdict(
  detected: Double, primary: Double, alternate: Double?, tolerance: Double
) -> MIREXTempoVerdict {
  let strict1 = isAcc1Match(detected, primary, tolerance: tolerance)
  let strict2 = strict1 || isAcc2Match(detected, primary, tolerance: tolerance)
  let alt1 = alternate.map { isAcc1Match(detected, $0, tolerance: tolerance) } ?? false
  let alt2 = alternate.map { isAcc2Match(detected, $0, tolerance: tolerance) } ?? false
  return MIREXTempoVerdict(
    strictAcc1: strict1,
    strictAcc2: strict2,
    floorAcc1: strict1 || alt1,
    floorAcc2: strict1 || alt1 || strict2 || alt2)
}
