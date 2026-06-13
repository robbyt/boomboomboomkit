//
//  BeatGrid.swift
//  BoomBoomBoomKit
//
//  Typed beat-grid result container: beats, downbeats, tempo, and agreement.
//

// MARK: - BeatGrid

/// The result of beat-grid extraction: the detected beats, the tri-state
/// downbeat outcome, the grid's own tempo estimate, an overall confidence, and
/// whether that tempo agreed with the BPM stage.
///
/// This is a **result shape only** (Story 8.3). The beat-tracking algorithm
/// that populates it — and the `analyzeBeatGrid(url:options:)` service method
/// and pipeline step-11 insertion — land in Story 8.4. The type exists first so
/// the algorithm has a stable container to return and the demo
/// `BeatGridTimelineView` (FR-39) can design against it.
///
/// ## Canonical "no beat-grid run" sentinel
/// The exact value
/// `BeatGrid(beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0, tempoAgreedWithBPMStage: nil)`
/// is the documented sentinel for "no beat-grid analysis was performed". It is
/// distinguishable in code from a grid whose ``downbeats`` is
/// ``DownbeatResult/noneDetected`` (which means downbeat detection *ran* and
/// found none).
///
/// ## Tempo validity
/// ``estimatedTempo`` `== 0.0` is the "no valid tempo estimate" sentinel. Both
/// non-finite and non-positive inputs normalize to it at construction, so
/// consumers gate validity with `estimatedTempo > 0` (do not test `!= 0` in a
/// way that admits a negative). A positive finite tempo passes through
/// UNCLAMPED — the 60–200 BPM plausibility range is Story 8.4's algorithm
/// concern, not this value type's.
///
/// ## NaN-free by construction → `Hashable`
/// Like ``BeatTimestamp``, every float field is clamped finite at every init
/// path, which is what makes the compiler-synthesized `Hashable`/`Equatable`
/// sound. This deliberately diverges from `LUFSReport` (which clamps but drops
/// `Hashable` because it is never a key and carries huge series): clamping is
/// the precondition for `Hashable`; adding `Hashable` is a separate call made
/// here because the grid is small and keyable. See ``BeatTimestamp`` for the
/// full doctrine.
public struct BeatGrid: Sendable, Hashable, Codable, CustomStringConvertible {

  // MARK: Stored

  /// The detected beats, in playback order. Empty for the "no run" sentinel.
  public let beats: [BeatTimestamp]

  /// The tri-state downbeat outcome (see ``DownbeatResult``).
  public let downbeats: DownbeatResult

  /// The beat grid's own tempo estimate in BPM. `0.0` is the "no valid
  /// estimate" sentinel (non-finite and non-positive inputs normalize here).
  /// A positive finite estimate is NOT range-clamped — gate validity with
  /// `estimatedTempo > 0`.
  public let estimatedTempo: Double

  /// Overall confidence in the grid, in `[0.0, 1.0]` (NaN/out-of-range inputs
  /// clamp at construction).
  public let confidence: Float

  /// Whether ``estimatedTempo`` agreed with the BPM stage's result:
  /// `true`/`false` when both a BPM analysis and a beat-grid analysis ran in
  /// the same call; `nil` when no BPM analysis ran alongside (KDD-C3).
  /// Population is Story 8.4/8.5's concern.
  public let tempoAgreedWithBPMStage: Bool?

  // MARK: Init

  /// Creates a beat grid, clamping its float fields finite.
  ///
  /// - `estimatedTempo` (`Double`): non-finite (`NaN`/`±Inf`) **or**
  ///   non-positive (`≤ 0`) → `0.0` (the "no valid estimate" sentinel, DD #8);
  ///   positive finite passes through unclamped.
  /// - `confidence` (`Float`): clamped to `[0.0, 1.0]` (NaN → `0.0`).
  /// - `beats` / `downbeats` carry already-clamped ``BeatTimestamp`` values by
  ///   construction; `tempoAgreedWithBPMStage` needs no clamping.
  ///
  /// - Parameters:
  ///   - beats: Detected beats in playback order.
  ///   - downbeats: Tri-state downbeat outcome.
  ///   - estimatedTempo: Grid tempo in BPM (`0.0` sentinel for no estimate).
  ///   - confidence: Overall grid confidence (clamped to `[0, 1]`).
  ///   - tempoAgreedWithBPMStage: `nil` when no BPM stage ran alongside.
  public init(
    beats: [BeatTimestamp],
    downbeats: DownbeatResult,
    estimatedTempo: Double,
    confidence: Float,
    tempoAgreedWithBPMStage: Bool?
  ) {
    self.beats = beats
    self.downbeats = downbeats
    self.estimatedTempo = BeatGridClamp.clampNonNegative(estimatedTempo)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.tempoAgreedWithBPMStage = tempoAgreedWithBPMStage
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the clamping
  /// ``init(beats:downbeats:estimatedTempo:confidence:tempoAgreedWithBPMStage:)``
  /// so a hostile or out-of-range JSON payload is re-clamped on the way in. It
  /// deliberately does NOT assign decoded values directly to stored properties.
  /// `encode(to:)` and `CodingKeys` are compiler-synthesized; the optional
  /// `tempoAgreedWithBPMStage` is decoded with `decodeIfPresent` to match the
  /// synthesized encoder's `encodeIfPresent` (a `nil` omits the key), so the
  /// two halves cannot desync.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let beats = try container.decode([BeatTimestamp].self, forKey: .beats)
    let downbeats = try container.decode(DownbeatResult.self, forKey: .downbeats)
    let estimatedTempo = try container.decode(Double.self, forKey: .estimatedTempo)
    let confidence = try container.decode(Float.self, forKey: .confidence)
    let tempoAgreedWithBPMStage = try container.decodeIfPresent(
      Bool.self, forKey: .tempoAgreedWithBPMStage)
    self.init(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreedWithBPMStage: tempoAgreedWithBPMStage)
  }

  // MARK: CustomStringConvertible

  /// One-line summary. The `Bool?` agreement is rendered explicitly for all
  /// three states (`true`/`false`/`unknown`) — never force-unwrapped.
  public var description: String {
    let agreed: String
    switch tempoAgreedWithBPMStage {
    case .some(true):
      agreed = "true"
    case .some(false):
      agreed = "false"
    case .none:
      agreed = "unknown"
    }
    return "BeatGrid(beats: \(beats.count), downbeats: \(downbeats), "
      + "tempo: \(estimatedTempo), conf: \(confidence), tempoAgreed: \(agreed))"
  }
}
