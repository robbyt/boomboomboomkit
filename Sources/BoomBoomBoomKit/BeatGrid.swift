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
/// material the anchor+tempo grid is drift-free by construction (the raw detected
/// ``beats`` carry per-beat onset quantization that can accumulate tens of
/// milliseconds over several minutes — extrapolate, don't trust them absolutely). See
/// ``BeatGridAnchor``.
///
/// This is doubly true once the grid's tempo is **lock-overridden**
/// (``with(estimatedTempo:)`` / `AudioAnalysisService.Options.beatGridTempoLock`)
/// or **auto-refined** (`AudioAnalysisService.Options.refineBeatGridTempo`): both
/// replace ``estimatedTempo`` with an independently-derived value while leaving the
/// raw ``beats`` at their originally-tracked spacing, so ``beats`` and
/// ``estimatedTempo`` deliberately describe *different* tempos. ``gridOrigin`` is
/// re-anchored to the new tempo; ``beats`` are not. The canonical playable grid is
/// always ``gridOrigin`` + ``estimatedTempo`` — never the spacing of ``beats``.
///
/// ## Applying a presentation offset
/// Timestamps are decoded-PCM-relative; AVFoundation already removes declared AAC/MP3
/// encoder priming, so the grid is already playback-aligned. To compensate for
/// output-device latency or apply a manual nudge, use ``offset(by:)`` — a
/// non-destructive copy that shifts every beat, every detected downbeat, and the
/// ``gridOrigin`` uniformly. Do NOT subtract codec priming yourself — it would
/// double-correct.
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

  // MARK: Schema version

  /// The current ``schemaVersion`` a freshly-produced ``BeatGrid`` carries. Bump
  /// this when the persisted *semantic* contract changes (see ``schemaVersion``).
  public static let currentSchemaVersion = 1

  // MARK: Stored

  /// The detected beats, in playback order, spanning ``coverage``. Empty for
  /// the "no run" sentinel.
  ///
  /// **Raw observations, not the playable grid.** These are the tracker's detected
  /// beat positions; they are NOT guaranteed to be evenly spaced according to
  /// ``estimatedTempo``. They never were exactly (per-beat onset quantization, the
  /// occasional dropped/doubled beat), and they are intentionally *more* divergent
  /// after a tempo lock (``with(estimatedTempo:)``) or auto-refinement
  /// (`AudioAnalysisService.Options.refineBeatGridTempo`), which override
  /// ``estimatedTempo`` without re-spacing this array. A consumer that needs the
  /// playable beat grid must extrapolate from ``gridOrigin`` + ``estimatedTempo``,
  /// not iterate ``beats``.
  public let beats: [BeatTimestamp]

  /// The tri-state downbeat outcome (see ``DownbeatResult``).
  public let downbeats: DownbeatResult

  /// The beat grid's own tempo estimate in BPM. `0.0` is the "no valid
  /// estimate" sentinel (non-finite and non-positive inputs normalize here).
  /// A positive finite estimate is NOT range-clamped — gate validity with
  /// `estimatedTempo > 0`.
  ///
  /// **This is THE authoritative extrapolation tempo** — the one number a consumer
  /// pairs with ``gridOrigin`` to lay down the playable grid. It may be
  /// independently fit (`AudioAnalysisService.Options.refineBeatGridTempo`) or
  /// overridden (``with(estimatedTempo:)`` /
  /// `AudioAnalysisService.Options.beatGridTempoLock`) regardless of the raw
  /// ``beats`` spacing; when it is, ``beats`` no longer tracks it (see ``beats``).
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

  /// The persisted-shape **semantic** contract version this grid was produced
  /// under. A freshly-produced grid carries ``currentSchemaVersion``.
  ///
  /// ## What it identifies
  /// It stamps the meaning of the serialized ``BeatGrid`` graph — the top-level
  /// fields *and* the nested types (``BeatTimestamp`` / ``BeatGridAnchor`` /
  /// ``BeatGridCoverage`` / ``TempoAgreement`` / ``DownbeatResult``). A *breaking
  /// shape* change (a renamed/removed required key) already throws at
  /// ``init(from:)`` — this field does nothing there. Its only job is the
  /// orthogonal class the throw misses: a change that keeps every key decodable
  /// but **redefines meaning** (the ``confidence`` formula, the
  /// ``estimatedTempo``/``BeatTimestamp/presentationTime`` provenance or units,
  /// or the ``TempoAgreement`` octave factor sign).
  ///
  /// ## Read-side consumer contract
  /// A consumer that **caches** a raw ``BeatGrid`` should compare its
  /// ``schemaVersion`` against ``currentSchemaVersion`` (or the version its cache
  /// was written under) and **re-index on mismatch**. The library does **not**
  /// migrate old grids: ``init(from:)`` decodes the stored integer faithfully
  /// (including an unknown future value) and never throws on an unrecognized
  /// version — only the consumer can judge whether a given version is compatible
  /// with how it cached.
  ///
  /// ## When to bump (hand-maintained)
  /// Bump on a ``confidence``-formula change, an
  /// ``estimatedTempo``/``presentationTime`` provenance or units change, a
  /// ``TempoAgreement`` factor-sign change, or a nested-enum meaning change. Do
  /// **not** bump for pure accuracy improvements that preserve the contract. This
  /// is a top-level *assertion* over the nested graph: it is not compiler-enforced
  /// and does not structurally witness a change *inside* a nested type, so its
  /// correctness depends entirely on this bump discipline. It is **not**
  /// backwards-compatibility and **not** cache protection (a consumer's own cache
  /// envelope version owns that) — it is a semantic-drift / forensic stamp the
  /// consumer may gate on. It is `Int` (ordered comparison is all a version
  /// envelope needs) and stays `Hashable`-clean.
  public let schemaVersion: Int

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
  ///     whose `beatIndex` is out of range for `beats` is dropped to `nil`; an
  ///     in-range anchor is rebuilt from `beats[beatIndex]` (time/confidence/strength)
  ///     so it always agrees with the indexed beat. `source` is preserved as
  ///     provenance — on a decoded payload it is untrusted, so a bar-snap consumer
  ///     must gate on `source == .downbeat` AND `downbeats` being `.detected`, never
  ///     `source` alone.
  ///   - coverage: What span `beats` cover (sanitized on the way in).
  ///   - schemaVersion: The persisted semantic-contract version. Defaulted to
  ///     ``currentSchemaVersion`` so every producer auto-stamps the current
  ///     version with no call-site change; stored faithfully (not range-validated).
  public init(
    beats: [BeatTimestamp],
    downbeats: DownbeatResult,
    estimatedTempo: Double,
    confidence: Float,
    tempoAgreement: TempoAgreement,
    gridOrigin: BeatGridAnchor?,
    coverage: BeatGridCoverage,
    schemaVersion: Int = BeatGrid.currentSchemaVersion
  ) {
    self.schemaVersion = schemaVersion
    self.beats = beats
    self.downbeats = downbeats
    self.estimatedTempo = BeatGridClamp.clampNonNegative(estimatedTempo)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.tempoAgreement = tempoAgreement
    // Enforce the gridOrigin contract: a non-nil anchor not only indexes a real beat
    // but AGREES with it. ``BeatGridAnchor`` clamps `beatIndex ≥ 0` but cannot bound it
    // above (it does not know `beats.count`), so an out-of-range anchor drops to `nil`.
    // An IN-range anchor is rebuilt from `beats[beatIndex]` (time/confidence/strength),
    // preserving `beatIndex` + `source`. The analyzer always constructs anchors this way
    // (so this is a no-op on honest grids), but a hostile/stale decoded anchor with an
    // in-range index and a mismatched `presentationTime` would otherwise break the
    // extrapolation contract `gridOrigin.presentationTime + period·n`. `source` is left
    // as untrusted provenance on a decoded payload — a bar-snap consumer must gate on
    // `source == .downbeat` AND `downbeats` being `.detected`, never `source` alone (so
    // we do NOT invent a different source here, only repair the mechanical invariant).
    self.gridOrigin = gridOrigin.flatMap { origin -> BeatGridAnchor? in
      guard origin.beatIndex < beats.count else { return nil }
      let beat = beats[origin.beatIndex]
      return BeatGridAnchor(
        beatIndex: origin.beatIndex,
        presentationTime: beat.presentationTime,
        confidence: beat.confidence,
        strength: beat.strength,
        source: origin.source)
    }
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
      coverage: coverage,
      // Forward the instance's version (W52 forward-every-field): a
      // decoded-then-restamped grid keeps its original version, not the current
      // one.
      schemaVersion: schemaVersion)
  }

  /// Returns a copy of this grid with ``estimatedTempo`` overridden and every
  /// other field forwarded from `self`.
  ///
  /// Used by the tempo-lock path (``BeatGridTempoLock``) to replace the tracker's
  /// measured tempo with an authoritative constant BPM while keeping the existing
  /// ``gridOrigin`` anchor, raw ``beats``, and the pre-lock ``tempoAgreement``
  /// diagnostic. The new tempo routes through the clamping memberwise init, so a
  /// non-finite/non-positive value normalizes to the `0.0` sentinel exactly as a
  /// freshly-constructed grid would (W52 forward-every-field).
  func with(estimatedTempo newTempo: Double) -> BeatGrid {
    BeatGrid(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: newTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion)
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
  /// bypass the clamp). `tempoAgreement`, `gridOrigin`, `coverage`, and
  /// `schemaVersion` are decoded with `decodeIfPresent` and default to their
  /// "no information" values (``TempoAgreement/notCompared`` / `nil` /
  /// ``BeatGridCoverage/analysisWindow`` / `1`), mirroring how the Story-8.3
  /// optional agreement flag defaulted to `nil` when absent. A legacy grid
  /// serialized before ``schemaVersion`` existed therefore decodes as version `1`
  /// (absent → 1; it cannot retroactively distinguish a true v1 — the field only
  /// versions forward). The synthesized encoder always writes the non-optional
  /// fields, so round-trips are exact; the decode is merely lenient about a
  /// partial payload.
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
    // Faithful decode: store whatever integer is present (including an unknown
    // future version), defaulting absent → 1; NEVER throw on an unrecognized
    // version (the consumer gates compatibility, the library does not migrate).
    // Mirrors the in-repo `BaselineRecord.schemaVersion: Int` warn-and-skip
    // precedent and this type's decode-faithfully-then-route-through-the-clamping
    // -init doctrine.
    let schemaVersion =
      try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    self.init(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion)
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

// MARK: - Consumer-controlled alignment offset

extension BeatGrid {

  /// Returns a copy of this grid with every beat, every detected downbeat, and the
  /// ``gridOrigin`` shifted in time by `seconds` (positive = later, negative = earlier).
  ///
  /// Non-destructive — it does NOT re-run detection. The shift is applied UNIFORMLY so
  /// beat spacing is preserved: a negative `seconds` that would push the earliest
  /// timestamp below `0` is reduced (clamped as a single delta) so the earliest timestamp
  /// lands exactly at `0`, rather than clamping each timestamp independently (which would
  /// collapse early beats and distort the grid). A non-finite `seconds`, a `0` shift, an
  /// empty grid, or a shift that nets to zero after clamping is a no-op.
  ///
  /// ``estimatedTempo``, ``confidence``, ``tempoAgreement``, ``coverage`` (which describes
  /// the analyzed *span length*, not an absolute start time), and ``schemaVersion`` are
  /// unchanged — `offset` shifts presentation coordinates only.
  ///
  /// Use for output-device latency compensation (e.g. `AVAudioEngine.outputLatency`) or a
  /// manual nudge. Do **not** use it for codec encoder priming: AVFoundation already
  /// removes declared AAC/MP3/M4A/CAF priming, so the timestamps are already
  /// playback-aligned and subtracting priming would double-correct.
  ///
  /// - Parameter seconds: The shift to apply, in seconds (`+` later, `−` earlier).
  /// - Returns: A new grid with shifted presentation times.
  public func offset(by seconds: Double) -> BeatGrid {
    guard seconds.isFinite, seconds != 0, !beats.isEmpty else { return self }

    // Minimum presentation time across EVERY timestamp that will move (beats + detected
    // downbeats; `gridOrigin` mirrors `beats[beatIndex]`, so it is already covered).
    var minTime = beats.lazy.map(\.presentationTime).min() ?? 0
    var maxTime = beats.lazy.map(\.presentationTime).max() ?? 0
    if case .detected(let estimate) = downbeats {
      for t in estimate.beats.lazy.map(\.presentationTime) {
        minTime = min(minTime, t)
        maxTime = max(maxTime, t)
      }
    }

    // Clamp the DELTA once: a too-negative shift is reduced so the earliest timestamp
    // lands at 0; positive shifts pass through. Spacing is preserved either way. An
    // offset so large the latest timestamp would overflow to non-finite is
    // unrepresentable — return self rather than collapse the grid (`BeatTimestamp` would
    // clamp a `+Inf` time to 0, destroying spacing).
    let effective = max(seconds, -minTime)
    guard effective != 0, (maxTime + effective).isFinite else { return self }

    func shifted(_ b: BeatTimestamp) -> BeatTimestamp {
      BeatTimestamp(
        presentationTime: b.presentationTime + effective, confidence: b.confidence,
        strength: b.strength)
    }

    let shiftedDownbeats: DownbeatResult
    switch downbeats {
    case .notAttempted, .noneDetected:
      shiftedDownbeats = downbeats
    case .detected(let estimate):
      shiftedDownbeats = .detected(
        estimate: DownbeatEstimate(
          beats: estimate.beats.map(shifted), meter: estimate.meter,
          confidence: estimate.confidence, phaseIndex: estimate.phaseIndex))
    }

    // Pass the original `gridOrigin`: `init` rebuilds the anchor from the SHIFTED
    // `beats[beatIndex]`, so the anchor's time follows the shift consistently (A4).
    return BeatGrid(
      beats: beats.map(shifted),
      downbeats: shiftedDownbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion)
  }
}
