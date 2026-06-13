//
//  DownbeatResult.swift
//  BoomBoomBoomKit
//
//  Tri-state downbeat-detection outcome carried by BeatGrid.
//

// MARK: - DownbeatResult

/// The outcome of downbeat (bar-start) detection for a ``BeatGrid``, as three
/// distinct states.
///
/// The tri-state distinction is the whole point of the type (FR-28): a consumer
/// must be able to tell "we never ran downbeat detection" apart from "we ran it
/// and found nothing".
///
/// - ``notAttempted``: downbeat detection did **not** run (e.g. the caller
///   requested beats only, or the stage was skipped). Absence of an attempt.
/// - ``noneDetected``: downbeat detection **ran** and found no downbeats.
///   A real, negative result — distinct from ``notAttempted``.
/// - ``detected(beats:)``: downbeat detection ran and produced the carried
///   beats (each a NaN-free ``BeatTimestamp`` by construction).
///
/// ## Conformance
/// Not `CaseIterable`: this is **forced, not chosen** — the compiler suppresses
/// `CaseIterable` synthesis for any enum carrying an associated value (SE-0194),
/// and `.detected`'s payload is unbounded so `.allCases` would be meaningless
/// anyway. Do not hand-roll `allCases`. `Hashable` is sound because the
/// `.detected` payload is NaN-free (every `BeatTimestamp` is clamped finite).
public enum DownbeatResult: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Downbeat detection did not run.
  case notAttempted

  /// Downbeat detection ran and found no downbeats.
  case noneDetected

  /// Downbeat detection ran and produced these downbeats. The associated value
  /// is labeled `beats:` so the `Codable` wire-shape is the stable
  /// `{"detected":{"beats":[…]}}` rather than the positional
  /// `{"detected":{"_0":[…]}}` (DD #9 / SE-0295).
  case detected(beats: [BeatTimestamp])

  // MARK: CustomStringConvertible

  /// One-line summary. Implemented as an exhaustive `switch` with **no**
  /// `default:` clause, so a future added case (e.g. `.ambiguous`) is a compile
  /// error here rather than a silent fallthrough.
  public var description: String {
    switch self {
    case .notAttempted:
      return "notAttempted"
    case .noneDetected:
      return "noneDetected"
    case .detected(let beats):
      return "detected(\(beats.count) beats)"
    }
  }
}
