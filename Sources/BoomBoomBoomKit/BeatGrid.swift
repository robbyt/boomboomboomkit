//
//  BeatGrid.swift
//  BoomBoomBoomKit
//
//  Typed beat-grid result container: beats, downbeats, tempo, confidence, the
//  Rekordbox-style extrapolation anchor, detected-beat coverage, and how the
//  grid tempo relates to the BPM stage.
//

// MARK: - BeatGrid

/// The result of beat-grid extraction: the detected beats, the tri-state
/// downbeat outcome, the grid's own tempo estimate, an overall confidence, the
/// Rekordbox-style extrapolation anchor (``gridOrigin``), what span the detected
/// ``beats`` cover (``coverage``), and how that tempo relates to the BPM stage
/// (``tempoAgreement``).
///
/// ## Extrapolate from the anchor, don't trust every beat
/// A beat-math consumer (continuous sync, sub-beat quantize) should anchor on
/// ``gridOrigin`` and extrapolate the grid `gridOrigin.presentationTime +
/// (60.0/estimatedTempo)·n` rather than trusting each entry of ``beats`` — the
/// dynamic-programming tracker can occasionally drop or double a beat, and that
/// corrupts sub-beat midpoints and accumulates sync error. On constant-tempo
/// material the anchor+tempo grid is drift-free by construction. See
/// ``BeatGridAnchor``.
///
/// ## Canonical "no beat-grid run" sentinel
/// The value
/// `BeatGrid(beats: [], downbeats: .notAttempted, estimatedTempo: 0,
/// confidence: 0, tempoAgreement: .notCompared, gridOrigin: nil,
/// coverage: .analysisWindow)`
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
/// UNCLAMPED — the 60–200 BPM plausibility range is the algorithm's concern,
/// not this value type's.
///
/// ## NaN-free by construction → `Hashable`
/// Like ``BeatTimestamp`` and ``BeatGridAnchor``, every float field is clamped
/// finite at every init path, which is what makes the compiler-synthesized
/// `Hashable`/`Equatable` sound. ``coverage`` is the enum analogue: its
/// ``BeatGridCoverage/sanitized`` form folds a degenerate `.window` into
/// `.analysisWindow`, and ``BeatGrid`` records that sanitized form, so a
/// `Double` second-count can never reintroduce a `NaN`. ``tempoAgreement``'s
/// only payload is an `Int` (not a `Double`), which is `Hashable`-clean.
public struct BeatGrid: Sendable, Hashable, Codable, CustomStringConvertible {

  // MARK: Stored

  /// The detected beats, in playback order, spanning ``coverage``. Empty for
  /// the "no run" sentinel.
  public let beats: [BeatTimestamp]

  /// The tri-state downbeat outcome (see ``DownbeatResult``).
  public let downbeats: DownbeatResult

  /// The beat grid's own tempo estimate in BPM. `0.0` is the "no valid
  /// estimate" sentinel (non-finite and non-positive inputs normalize here).
  /// A positive finite estimate is NOT range-clamped — gate validity with
  /// `estimatedTempo > 0`.
  public let estimatedTempo: Double

  /// Overall confidence in the grid, in `[0.0, 1.0]` (NaN/out-of-range inputs
  /// clamp at construction). Semantics: `0.5·meanOnsetStrength +
  /// 0.5·acfStrengthAtPeriod` — half "how strong are the beats we picked", half
  /// "how periodic is the signal at the tracked tempo". Treat this formula as a
  /// stability contract (don't silently redefine it).
  public let confidence: Float

  /// How the grid's ``estimatedTempo`` relates to the BPM stage's tempo:
  /// ``TempoAgreement/notCompared`` when the grid was produced standalone (no
  /// BPM result alongside — e.g. via ``AudioAnalysisService/analyzeBeatGrid(url:options:)``);
  /// otherwise ``TempoAgreement/agree`` / ``TempoAgreement/octaveEquivalent(factor:)``
  /// / ``TempoAgreement/disagree`` as set by
  /// ``AudioAnalysisService/analyze(url:options:)`` (KDD-C3 / FR-31).
  public let tempoAgreement: TempoAgreement

  /// The single most-trustworthy reference beat for Rekordbox-style
  /// extrapolation, or `nil` when no beats were detected. See ``BeatGridAnchor``.
  ///
  /// **Invariant:** when non-`nil`, ``BeatGridAnchor/beatIndex`` always indexes a
  /// real entry of ``beats`` (`0 ..< beats.count`), so `beats[gridOrigin!.beatIndex]`
  /// is safe. An anchor supplied (by a hostile `Codable` payload or a manual
  /// misconstruction) with an out-of-range index is dropped to `nil` at
  /// construction — ``BeatGridAnchor`` alone clamps `beatIndex ≥ 0` but cannot
  /// know `beats.count`, so the cross-field check lives here.
  public let gridOrigin: BeatGridAnchor?

  /// What span the detected ``beats`` cover (always the ``BeatGridCoverage/sanitized``
  /// form). The mid-track contract is ``gridOrigin`` + ``estimatedTempo``
  /// regardless of this; ``coverage`` only describes the detected-beat array.
  public let coverage: BeatGridCoverage

  // MARK: Init

  /// Creates a beat grid, clamping its float fields finite and recording the
  /// sanitized ``coverage``.
  ///
  /// - `estimatedTempo` (`Double`): non-finite (`NaN`/`±Inf`) **or**
  ///   non-positive (`≤ 0`) → `0.0` (the "no valid estimate" sentinel);
  ///   positive finite passes through unclamped.
  /// - `confidence` (`Float`): clamped to `[0.0, 1.0]` (NaN → `0.0`).
  /// - `coverage`: stored as its ``BeatGridCoverage/sanitized`` form.
  /// - `beats` / `downbeats` / `gridOrigin` carry already-clamped values by
  ///   construction; `tempoAgreement` needs no clamping (its only payload is an
  ///   `Int`).
  ///
  /// - Parameters:
  ///   - beats: Detected beats in playback order.
  ///   - downbeats: Tri-state downbeat outcome.
  ///   - estimatedTempo: Grid tempo in BPM (`0.0` sentinel for no estimate).
  ///   - confidence: Overall grid confidence (clamped to `[0, 1]`).
  ///   - tempoAgreement: How the grid tempo relates to the BPM stage
  ///     (``TempoAgreement/notCompared`` when none ran alongside).
  ///   - gridOrigin: The extrapolation anchor, or `nil` when no beats. An anchor
  ///     whose `beatIndex` is out of range for `beats` is dropped to `nil`.
  ///   - coverage: What span `beats` cover (sanitized on the way in).
  public init(
    beats: [BeatTimestamp],
    downbeats: DownbeatResult,
    estimatedTempo: Double,
    confidence: Float,
    tempoAgreement: TempoAgreement,
    gridOrigin: BeatGridAnchor?,
    coverage: BeatGridCoverage
  ) {
    self.beats = beats
    self.downbeats = downbeats
    self.estimatedTempo = BeatGridClamp.clampNonNegative(estimatedTempo)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.tempoAgreement = tempoAgreement
    // Enforce the gridOrigin invariant: a non-nil anchor always indexes a real
    // beat. ``BeatGridAnchor`` clamps `beatIndex ≥ 0` but cannot bound it above
    // (it does not know `beats.count`), so a hostile/inconsistent anchor with
    // `beatIndex >= beats.count` is dropped to `nil` here so consumers can index
    // `beats[gridOrigin.beatIndex]` without their own bounds check.
    self.gridOrigin = gridOrigin.flatMap { $0.beatIndex < beats.count ? $0 : nil }
    self.coverage = coverage.sanitized
  }

  // MARK: Value-type forwarding (W52)

  /// Returns a copy of this grid with ``tempoAgreement`` overridden and every
  /// other field forwarded from `self`.
  ///
  /// The combined ``AudioAnalysisService/analyze(url:options:)`` path uses this
  /// to stamp the resolved agreement onto a grid the analyzer produced with
  /// ``TempoAgreement/notCompared``, WITHOUT a field-enumerating re-init that
  /// would silently drop a future field (the W52 forwarding rationale shared
  /// with `BPMResult.with(...)`).
  func with(tempoAgreement newAgreement: TempoAgreement) -> BeatGrid {
    BeatGrid(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: newAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage)
  }

  // MARK: Codable

  /// Decodes raw scalars into locals and constructs `self` through the clamping
  /// memberwise ``init(beats:downbeats:estimatedTempo:confidence:tempoAgreement:gridOrigin:coverage:)``
  /// so a hostile or out-of-range JSON payload is re-clamped (and `coverage`
  /// re-sanitized) on the way in. It deliberately does NOT assign decoded values
  /// directly to stored properties. `encode(to:)` and `CodingKeys` are
  /// compiler-synthesized.
  ///
  /// `beats`, `downbeats`, `estimatedTempo`, and `confidence` are required
  /// (a missing key throws — a regression lock against a `?? 0` that would
  /// bypass the clamp). `tempoAgreement`, `gridOrigin`, and `coverage` are
  /// decoded with `decodeIfPresent` and default to their "no information"
  /// values (``TempoAgreement/notCompared`` / `nil` / ``BeatGridCoverage/analysisWindow``),
  /// mirroring how the Story-8.3 optional agreement flag defaulted to `nil` when
  /// absent. The synthesized encoder always writes the non-optional fields, so
  /// round-trips are exact; the decode is merely lenient about a partial payload.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let beats = try container.decode([BeatTimestamp].self, forKey: .beats)
    let downbeats = try container.decode(DownbeatResult.self, forKey: .downbeats)
    let estimatedTempo = try container.decode(Double.self, forKey: .estimatedTempo)
    let confidence = try container.decode(Float.self, forKey: .confidence)
    let tempoAgreement =
      try container.decodeIfPresent(TempoAgreement.self, forKey: .tempoAgreement)
      ?? .notCompared
    let gridOrigin = try container.decodeIfPresent(BeatGridAnchor.self, forKey: .gridOrigin)
    let coverage =
      try container.decodeIfPresent(BeatGridCoverage.self, forKey: .coverage)
      ?? .analysisWindow
    self.init(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage)
  }

  // MARK: CustomStringConvertible

  /// One-line summary.
  public var description: String {
    let origin = gridOrigin.map { "beat \($0.beatIndex)@\($0.presentationTime)s" } ?? "none"
    return "BeatGrid(beats: \(beats.count), downbeats: \(downbeats), "
      + "tempo: \(estimatedTempo), conf: \(confidence), "
      + "agreement: \(tempoAgreement), origin: \(origin), coverage: \(coverage))"
  }
}
