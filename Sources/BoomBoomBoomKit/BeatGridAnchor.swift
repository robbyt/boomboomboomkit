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
/// every init path (memberwise + `Codable` decode), and `beatIndex` is either
/// `nil` or a clamped `≥ 0` `Int` (no `Double`, no `NaN`), which is what makes the
/// compiler-synthesized `Hashable`/`Equatable` sound.
public struct BeatGridAnchor: Sendable, Hashable, Codable, CustomStringConvertible {

  // MARK: Stored

  /// The detected beat this anchor is **coupled** to — an index into
  /// ``BeatGrid/beats`` — or `nil` for a **free-standing** manual origin whose
  /// ``presentationTime`` stands on its own (Story 8.12).
  ///
  /// `!= nil` ⇒ coupled: ``BeatGrid`` rebuilds ``presentationTime`` /
  /// ``confidence`` / ``strength`` from `beats[beatIndex]` at construction, so the
  /// anchor always agrees with its beat (the verbatim auto-anchor contract). `==
  /// nil` ⇒ free-standing: a ``BeatGridAnchorSource/manual`` origin placed off the
  /// detected grid, with no beat backing it and ``presentationTime`` authoritative.
  /// A *present* index is clamped `≥ 0`; a `nil` index passes through. The index is
  /// the mechanical coupling discriminator; ``source`` is pure provenance (a
  /// `.manual` anchor may be coupled OR free-standing — DD #2).
  public let beatIndex: Int?

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

  /// Creates an anchor, clamping a *present* `beatIndex` `≥ 0` (a `nil` index — a
  /// free-standing manual origin — passes through) and every float field finite.
  ///
  /// - Parameters:
  ///   - beatIndex: Index into `beats` of the coupled beat (clamped `≥ 0`), or
  ///     `nil` for a free-standing manual origin.
  ///   - presentationTime: Decoded-PCM-relative beat time (clamped `≥ 0`).
  ///   - confidence: Anchor confidence (clamped to `[0, 1]`).
  ///   - strength: Anchor onset strength (clamped to `[0, 1]`).
  ///   - source: Which selection rule fired.
  public init(
    beatIndex: Int?,
    presentationTime: Double,
    confidence: Float,
    strength: Float,
    source: BeatGridAnchorSource
  ) {
    self.beatIndex = beatIndex.map { max(0, $0) }
    self.presentationTime = BeatGridClamp.clampNonNegative(presentationTime)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.strength = BeatGridClamp.clampUnit(strength)
    self.source = source
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the clamping
  /// memberwise init so a hostile or out-of-range JSON payload is re-clamped on
  /// the way in (it deliberately does NOT assign decoded values directly).
  /// `beatIndex` is decoded with `decodeIfPresent` (a missing/`null` key → `nil`,
  /// the free-standing manual origin; a *present* negative re-clamps to `0`); the
  /// synthesized `encode(to:)` symmetrically omits the key when `nil`. `encode(to:)`
  /// and `CodingKeys` are compiler-synthesized.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let beatIndex = try container.decodeIfPresent(Int.self, forKey: .beatIndex)
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

  /// One-line summary for logs and trace dumps. A free-standing anchor renders its
  /// `beatIndex` as `nil` (not `Optional(…)`).
  public var description: String {
    "BeatGridAnchor(beat: \(beatIndex.map { String($0) } ?? "nil"), t: \(presentationTime)s, "
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

  /// A human placed this origin by hand (Story 8.12): a deliberate user override
  /// of the bar origin, honored as bar-trustworthy. **Coupling-orthogonal** — a
  /// `.manual` anchor may be *snapped* to a detected beat
  /// (``BeatGridAnchor/beatIndex`` non-`nil`) or *free-standing*
  /// (``BeatGridAnchor/beatIndex`` `nil`, an off-beat time). Unlike ``downbeat`` it
  /// has no second field to corroborate (it coexists with
  /// ``DownbeatResult/notAttempted``), so honoring `source == .manual` alone on a
  /// decoded payload is acceptable — see ``BeatGrid`` for the trust asymmetry.
  case manual
}
