//
//  BarPhase.swift
//  BoomBoomBoomKit
//
//  Shared bar-phase fold for the downbeat estimators (Story 8.5a / 8.11). Single
//  home for the position-quantized phase formula so `DownbeatAnalyzer` and
//  `StructuralDropAnalyzer` can't drift apart. Caseless-enum namespace per the
//  project's `MelFilterbank` / `BeatGridClamp` precedent ("declared once, reused
//  across both types").
//

/// Folds a beat's playback time onto its bar phase in `0..<beatsPerBar`.
///
/// Quantizes the offset from `firstTime` to the nearest integer beat index
/// (`Int((·).rounded())`, round-half-away-from-zero), then takes a sign-corrected
/// modulo so negative offsets wrap into range.
///
/// Callers guarantee `beatPeriod > 0` (derived `60 / tempo` from a finite,
/// positive tempo) and finite `time` / `firstTime` (`BeatTimestamp` clamps both
/// finite `≥ 0` at construction). The helper does NOT re-validate those — adding
/// defensive guards would change behavior on inputs that cannot currently occur.
enum BarPhase {

  /// Position-quantized bar-phase index of `time` relative to `firstTime`.
  ///
  /// - Parameters:
  ///   - time: The beat's playback time in seconds.
  ///   - firstTime: The grid's first beat time in seconds (the phase-0 anchor).
  ///   - beatPeriod: Seconds per beat (`60 / tempo`); caller guarantees `> 0`.
  ///   - beatsPerBar: Beats per bar (4 in 4/4); caller guarantees `>= 1`.
  /// - Returns: The bar-phase index in `0..<beatsPerBar`.
  static func index(
    ofTime time: Double, firstTime: Double, beatPeriod: Double, beatsPerBar: Int
  ) -> Int {
    let raw = Int(((time - firstTime) / beatPeriod).rounded())
    return ((raw % beatsPerBar) + beatsPerBar) % beatsPerBar
  }
}
