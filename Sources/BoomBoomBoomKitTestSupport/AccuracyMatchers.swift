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
