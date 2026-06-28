import Foundation

/// Returns true when `detected` is within `tolerance` of `expected`, as a fraction of `expected`.
///
/// Acc1 ("within tolerance of ground truth") per the MIREX tempo-estimation protocol.
/// Zero-`expected` rows always return `false` to avoid NaN propagation from division by zero.
public func isAcc1Match(_ detected: Double, _ expected: Double, tolerance: Double) -> Bool {
  guard expected > 0 else { return false }
  return abs(detected - expected) / expected <= tolerance
}

/// Returns true when `detected` matches `expected` within `tolerance`, allowing for
/// octave-factor (`1, 2, 1/2`) and triplet-factor (`3, 1/3`) relationships.
///
/// Acc2 ("at any common metric factor") per MIREX — the full five-factor variant landed in
/// Story 2-2 ("Dual-tolerance accuracy reporting and MIREX-compliant Acc2 unification").
/// This helper is shared across all benchmark test suites so the semantics cannot drift.
public func isAcc2Match(_ detected: Double, _ expected: Double, tolerance: Double) -> Bool {
  isAcc1Match(detected, expected, tolerance: tolerance)
    || isAcc1Match(detected * 2, expected, tolerance: tolerance)
    || isAcc1Match(detected / 2, expected, tolerance: tolerance)
    || isAcc1Match(detected * 3, expected, tolerance: tolerance)
    || isAcc1Match(detected / 3, expected, tolerance: tolerance)
}

/// How `detected` relates to ground-truth `expected`, for forensic error attribution
/// (Phase 0). `exact` is the Acc1 hit; octave (`double`/`half`) is kept STRICTLY
/// separate from triplet (`triple`/`third`/`threeHalf`/`twoThird`) so the two failure
/// families are never conflated; `other` is a genuine non-harmonic wrong tempo.
public enum TempoErrorCategory: String, Sendable, Codable, CaseIterable {
  case exact  // detected ≈ truth (Acc1)
  case double  // detected ≈ 2× truth
  case half  // detected ≈ 0.5× truth
  case triple  // detected ≈ 3× truth
  case third  // detected ≈ ⅓× truth
  case threeHalf  // detected ≈ 1.5× truth (3:2)
  case twoThird  // detected ≈ ⅔× truth (2:3)
  case other  // genuine wrong tempo
}

/// Classifies a `(detected, expected)` pair into a ``TempoErrorCategory`` using the
/// SAME relative band as ``isAcc1Match``. Checks `exact` → octave → triplet → `other`,
/// so a track that is both (e.g. exactly on truth) reports the closest relationship.
/// Non-finite / non-positive inputs are `other` (no division-by-zero, mirrors Acc1).
public func classifyTempoError(_ detected: Double, _ expected: Double, tolerance: Double)
  -> TempoErrorCategory
{
  guard expected > 0, detected > 0, detected.isFinite else { return .other }
  if isAcc1Match(detected, expected, tolerance: tolerance) { return .exact }
  if isAcc1Match(detected, expected * 2, tolerance: tolerance) { return .double }
  if isAcc1Match(detected, expected * 0.5, tolerance: tolerance) { return .half }
  if isAcc1Match(detected, expected * 3, tolerance: tolerance) { return .triple }
  if isAcc1Match(detected, expected / 3, tolerance: tolerance) { return .third }
  if isAcc1Match(detected, expected * 1.5, tolerance: tolerance) { return .threeHalf }
  if isAcc1Match(detected, expected * (2.0 / 3.0), tolerance: tolerance) { return .twoThird }
  return .other
}
