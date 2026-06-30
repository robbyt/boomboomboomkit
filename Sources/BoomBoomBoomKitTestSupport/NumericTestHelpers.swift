//
//  NumericTestHelpers.swift
//  BoomBoomBoomKit
//
//  Shared bit-pattern equality helpers for byte-equality regression tests.
//

/// Caseless-enum namespace for NaN-safe floating-point equality helpers used by
/// byte-equality regression tests. The namespace form (per Story 6.1 Patch M15)
/// matches the project's `MelFilterbank` / `MetadataCorroborator` /
/// `FileMetadataReader` precedent — scoped, grep-findable, no extension on a
/// stdlib type, no risk of future stdlib/Foundation collision.
public enum NumericTestHelpers {
  /// Returns true iff `lhs` and `rhs` have identical IEEE 754 bit patterns.
  /// NaN-safe: two NaNs with the same bit pattern compare equal; `==` would not.
  public static func bitEqual(_ lhs: Double, _ rhs: Double) -> Bool {
    lhs.bitPattern == rhs.bitPattern
  }

  /// Returns true iff `lhs` and `rhs` have identical IEEE 754 bit patterns.
  /// NaN-safe: two NaNs with the same bit pattern compare equal; `==` would not.
  public static func bitEqual(_ lhs: Float, _ rhs: Float) -> Bool {
    lhs.bitPattern == rhs.bitPattern
  }

  /// Absolute-tolerance comparison for cross-toolchain Float-derived values.
  ///
  /// The BPM pipeline's low mantissa bits are not portable across CPU/Accelerate
  /// versions (vectorized reduction order + FMA contraction differ), so a value
  /// computed on one machine and frozen as a baseline drifts by ~1e-5 BPM /
  /// ~1e-9 confidence on another — numerically identical, bit-different. A tight
  /// tolerance catches genuine DSP drift while surviving that noise floor. Use in
  /// place of `bitEqual` ONLY for live-vs-frozen-baseline comparisons; live-vs-live
  /// comparisons on a single host stay bit-exact via `bitEqual`.
  public static func approxEqual(_ a: Double, _ b: Double, tol: Double) -> Bool {
    a == b || abs(a - b) <= tol
  }

  /// `Float` overload — beat-grid `Float` fields (candidate `score`, beat
  /// confidence/strength) carry a coarser noise floor than `Double` confidence,
  /// so they take a separately calibrated `Float` tolerance rather than being
  /// silently widened to `Double` at the call site.
  public static func approxEqual(_ a: Float, _ b: Float, tol: Float) -> Bool {
    a == b || abs(a - b) <= tol
  }
}
