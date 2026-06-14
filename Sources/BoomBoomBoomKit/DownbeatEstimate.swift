//
//  DownbeatEstimate.swift
//  BoomBoomBoomKit
//
//  Public payload of DownbeatResult.detected (Story 8.5a): the estimated
//  downbeat (bar-start) beats, the assumed meter, an overall confidence, and the
//  bar-phase index the estimator locked onto.
//

// MARK: - MeterEstimate

/// The metrical context a ``DownbeatEstimate`` was produced under: how many beats
/// make a bar, and whether that count was **assumed** or **measured**.
///
/// Story 8.5a only ever produces `{ beatsPerBar: 4, source: .assumed }`: the
/// downbeat-phase estimator assumes common time and estimates *which* beat-in-bar
/// is beat 1 — it does not measure the meter. A consumer gating bar-snap on a
/// *detected* meter must therefore check ``source`` (`.assumed` is the only value
/// 8.5a emits); ``MeterSource/detected`` is reserved for a future non-4/4
/// meter-detection story.
///
/// ## NaN-free by construction → `Hashable`
/// Both fields are integers / a `String`-backed enum, so there is no float to
/// sanitize; the compiler-synthesized `Hashable`/`Equatable` is sound by
/// construction.
public struct MeterEstimate: Sendable, Hashable, Codable {

  /// Beats per bar. Always `4` in Story 8.5a (common time, assumed).
  public let beatsPerBar: Int

  /// Whether ``beatsPerBar`` was assumed or measured. `.assumed` in Story 8.5a.
  public let source: MeterSource

  /// Creates a meter estimate.
  ///
  /// - Parameters:
  ///   - beatsPerBar: Beats per bar (4 in Story 8.5a).
  ///   - source: Whether the count was assumed or detected.
  public init(beatsPerBar: Int, source: MeterSource) {
    self.beatsPerBar = beatsPerBar
    self.source = source
  }
}

// MARK: - MeterSource

/// How a ``MeterEstimate/beatsPerBar`` was arrived at (provenance).
///
/// `String`-backed for a clean, stable `Codable` wire shape — a bare string, not
/// the SE-0295 single-key object — mirroring the sibling ``BeatGridAnchorSource``
/// convention. Closed set; not `CaseIterable` (no consumer needs to enumerate it,
/// and a future case must not silently widen `.allCases`).
public enum MeterSource: String, Sendable, Hashable, Codable {

  /// The bar length was **assumed** (common time, 4/4), not measured. The only
  /// value Story 8.5a produces.
  case assumed

  /// The bar length was **measured** from the signal. Reserved for a future
  /// non-4/4 meter-detection story; never produced by Story 8.5a.
  case detected
}

// MARK: - DownbeatEstimate

/// The populated result of downbeat (bar-start) estimation, carried by
/// ``DownbeatResult/detected(estimate:)`` (Story 8.5a).
///
/// Story 8.5a estimates a single downbeat **phase** for percussive,
/// constant-tempo, 4/4 material — i.e. which beat-in-bar is beat 1 — and an
/// abstain (``DownbeatResult/noneDetected``) when the rhythmic evidence is weak.
/// It is *not* general downbeat tracking (no variable meter, no per-beat bar
/// position, no ML).
///
/// A consumer extrapolates bar lines from the first downbeat and the grid tempo:
///
/// ```swift
/// // k-th bar start after the first downbeat (constant tempo, 4/4):
/// let barTime = estimate.beats[0].presentationTime
///   + 60.0 / grid.estimatedTempo * Double(estimate.meter.beatsPerBar) * Double(k)
/// ```
///
/// ## NaN-free by construction → `Hashable`
/// The only float field is ``confidence``, clamped finite at every init path
/// (memberwise + `Codable` decode); ``beats`` carry already-clamped
/// ``BeatTimestamp`` values. That is what makes the compiler-synthesized
/// `Hashable`/`Equatable` sound — the same doctrine ``BeatTimestamp`` /
/// ``BeatGrid`` follow.
public struct DownbeatEstimate: Sendable, Hashable, Codable {

  // MARK: Stored

  /// The detected downbeat beats (bar starts), in playback order. The first
  /// element is the first downbeat — the bar-extrapolation anchor.
  public let beats: [BeatTimestamp]

  /// The metrical context (`{ beatsPerBar: 4, source: .assumed }` in 8.5a).
  public let meter: MeterEstimate

  /// Overall confidence in the downbeat phase, in `[0, 1]` (clamped finite at
  /// construction). Combines the winning phase's margin over the runner-up with
  /// its separation from the mean phase score (Story 8.5a AC4).
  public let confidence: Float

  /// Which beat-in-bar (`0 ..< meter.beatsPerBar`) the estimator locked onto as
  /// the downbeat phase.
  public let phaseIndex: Int

  // MARK: Init

  /// Creates a downbeat estimate, clamping ``confidence`` finite to keep the
  /// synthesized `Hashable`/`Equatable` sound.
  ///
  /// - Parameters:
  ///   - beats: The downbeat beats (bar starts) in playback order.
  ///   - meter: The metrical context (4/4 assumed in 8.5a).
  ///   - confidence: Overall confidence (clamped to `[0, 1]`, NaN → `0`).
  ///   - phaseIndex: The bar-phase index the estimator locked onto.
  public init(
    beats: [BeatTimestamp], meter: MeterEstimate, confidence: Float, phaseIndex: Int
  ) {
    self.beats = beats
    self.meter = meter
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.phaseIndex = phaseIndex
  }

  // MARK: Validity

  /// Whether this estimate is structurally usable as a *detected* downbeat result:
  /// a non-empty downbeat set (`beats[0]` is the bar-extrapolation anchor a
  /// consumer needs), a sane meter (`meter.beatsPerBar >= 1`), and an in-range
  /// phase (`0 ..< meter.beatsPerBar`).
  ///
  /// The DSP producer (``DownbeatAnalyzer/estimate(beatFrames:beats:fullBand:subBands:periodFrames:estimatedTempo:beatsPerBar:)``)
  /// always satisfies this by construction. It can fail **only** for a decoded
  /// stale or tampered payload — which ``DownbeatResult/init(from:)`` normalizes to
  /// ``DownbeatResult/noneDetected`` rather than surface an unusable "success".
  /// The init deliberately does **not** enforce this (no fabricating beats / meter
  /// / phase — there is no honest repair for an empty downbeat set); the invariant
  /// is owned by the enum decode boundary, which has the safe ``DownbeatResult/noneDetected``
  /// alternative.
  var isStructurallyUsable: Bool {
    !beats.isEmpty
      && meter.beatsPerBar >= 1
      && phaseIndex >= 0
      && phaseIndex < meter.beatsPerBar
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the clamping
  /// memberwise init so a hostile or out-of-range JSON `confidence` is re-clamped
  /// on the way in. `encode(to:)` and `CodingKeys` are compiler-synthesized.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let beats = try container.decode([BeatTimestamp].self, forKey: .beats)
    let meter = try container.decode(MeterEstimate.self, forKey: .meter)
    let confidence = try container.decode(Float.self, forKey: .confidence)
    let phaseIndex = try container.decode(Int.self, forKey: .phaseIndex)
    self.init(beats: beats, meter: meter, confidence: confidence, phaseIndex: phaseIndex)
  }
}
