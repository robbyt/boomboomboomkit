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
}
