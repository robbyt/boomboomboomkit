//
//  BeatGridAnchor.swift
//  BoomBoomBoomKit
//
//  The single most-trustworthy reference beat in a BeatGrid — the Rekordbox-
//  style anchor consumers extrapolate the infinite grid from (Story 8.5,
//  FR-29/FR-30, AC4).
//

// MARK: - BeatGridAnchor

/// The single most-trustworthy reference beat in a ``BeatGrid`` (Story 8.5).
///
/// A beat-math consumer (continuous sync, sub-beat quantize) should **not**
/// trust every entry in ``BeatGrid/beats``: the dynamic-programming tracker can
/// drop or double an occasional beat, which corrupts sub-beat midpoints and
/// accumulates sync error over a track. Instead, anchor on this one beat and
/// extrapolate the grid Rekordbox-style:
///
/// ```swift
/// // n-th beat after the anchor, drift-free on constant tempo:
/// let t = anchor.presentationTime + (60.0 / grid.estimatedTempo) * Double(n)
/// ```
///
/// The anchor is chosen by **phase consistency** — how well its neighbors line
/// up to `time + k·period` — not by raw onset strength (which can pick a snare
/// fill) or by "first beat" (which can be a weak beat at an energy transition).
/// ``source`` records which rule produced it (DD #11).
///
/// `gridOrigin` is a *beat* anchor, sufficient for beatmatch and 1/4 / 1/8
/// quantize. It is **not** a bar origin: ``BeatGridAnchorSource/downbeat`` is
/// reserved for when downbeat detection lands (Story 8.5a) and is not produced
/// by Story 8.5.
///
/// ## NaN-free by construction → `Hashable`
/// Like ``BeatTimestamp`` / ``BeatGrid``, every float field is clamped finite at
/// every init path (memberwise + `Codable` decode), and `beatIndex` is clamped
/// `≥ 0`, which is what makes the compiler-synthesized `Hashable`/`Equatable`
/// sound.
public struct BeatGridAnchor: Sendable, Hashable, Codable, CustomStringConvertible {

  // MARK: Stored

  /// Index into ``BeatGrid/beats`` of the chosen anchor beat. Clamped `≥ 0`.
  public let beatIndex: Int

  /// Decoded-PCM-relative playback time of the anchor beat, in seconds from the
  /// start of the file (same contract as ``BeatTimestamp/presentationTime``).
  /// Clamped `≥ 0` and finite.
  public let presentationTime: Double

  /// Confidence in the anchor, in `[0, 1]` (clamped). For a phase-selected or
  /// strongest-beat anchor this is the underlying beat's per-beat confidence;
  /// for a first-beat fallback it is the first beat's onset strength.
  public let confidence: Float

  /// Onset strength at the anchor beat, in `[0, 1]` (clamped).
  public let strength: Float

  /// Which selection rule produced this anchor (provenance).
  public let source: BeatGridAnchorSource

  // MARK: Init

  /// Creates an anchor, clamping `beatIndex` `≥ 0` and every float field finite.
  ///
  /// - Parameters:
  ///   - beatIndex: Index into `beats` (clamped `≥ 0`).
  ///   - presentationTime: Decoded-PCM-relative beat time (clamped `≥ 0`).
  ///   - confidence: Anchor confidence (clamped to `[0, 1]`).
  ///   - strength: Anchor onset strength (clamped to `[0, 1]`).
  ///   - source: Which selection rule fired.
  public init(
    beatIndex: Int,
    presentationTime: Double,
    confidence: Float,
    strength: Float,
    source: BeatGridAnchorSource
  ) {
    self.beatIndex = max(0, beatIndex)
    self.presentationTime = BeatGridClamp.clampNonNegative(presentationTime)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.strength = BeatGridClamp.clampUnit(strength)
    self.source = source
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the clamping
  /// memberwise init so a hostile or out-of-range JSON payload is re-clamped on
  /// the way in (it deliberately does NOT assign decoded values directly).
  /// `encode(to:)` and `CodingKeys` are compiler-synthesized.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let beatIndex = try container.decode(Int.self, forKey: .beatIndex)
    let presentationTime = try container.decode(Double.self, forKey: .presentationTime)
    let confidence = try container.decode(Float.self, forKey: .confidence)
    let strength = try container.decode(Float.self, forKey: .strength)
    let source = try container.decode(BeatGridAnchorSource.self, forKey: .source)
    self.init(
      beatIndex: beatIndex,
      presentationTime: presentationTime,
      confidence: confidence,
      strength: strength,
      source: source)
  }

  // MARK: CustomStringConvertible

  /// One-line summary for logs and trace dumps.
  public var description: String {
    "BeatGridAnchor(beat: \(beatIndex), t: \(presentationTime)s, "
      + "conf: \(confidence), str: \(strength), source: \(source.rawValue))"
  }
}

// MARK: - BeatGridAnchorSource

/// Which selection rule produced a ``BeatGridAnchor`` (Story 8.5, DD #11).
///
/// `String`-backed for a clean, stable `Codable` wire shape (a bare string, not
/// the SE-0295 single-key object). Closed set; not `CaseIterable` (no consumer
/// needs to enumerate it, and a future case must not silently widen `.allCases`).
public enum BeatGridAnchorSource: String, Sendable, Hashable, Codable {

  /// Chosen by phase consistency — the beat whose neighbors best align to
  /// `time + k·period`. The primary rule.
  case medianConsistentBeat

  /// Fallback: the highest-``BeatTimestamp/strength`` beat, when no beat scored
  /// a usable phase-consistency value.
  case strongestBeat

  /// Last-resort fallback: the first detected beat, when neither phase
  /// consistency nor strength produced a winner.
  case firstBeat

  /// Reserved for the downbeat story (Story 8.5a): the anchor coincides with a
  /// detected bar start. **Not produced by Story 8.5.**
  case downbeat
}
