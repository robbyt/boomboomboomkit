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
/// (``with(estimatedTempo:tempoLockOctaveFactor:)`` / `AudioAnalysisService.Options.beatGridTempoLock`)
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
  ///
  /// `2` since Story 8.12: ``BeatGridAnchor/beatIndex`` became optional (`Int?`),
  /// where a `nil` index now carries the "free-standing ``BeatGridAnchorSource/manual``
  /// origin" meaning and a free-standing grid omits the `beatIndex` key — a payload
  /// shape a v1 decoder's `decode(Int.self)` would have thrown on.
  public static let currentSchemaVersion = 2

  // MARK: Stored

  /// The detected beats, in playback order, spanning ``coverage``. Empty for
  /// the "no run" sentinel.
  ///
  /// **Raw observations, not the playable grid.** These are the tracker's detected
  /// beat positions; they are NOT guaranteed to be evenly spaced according to
  /// ``estimatedTempo``. They never were exactly (per-beat onset quantization, the
  /// occasional dropped/doubled beat), and they are intentionally *more* divergent
  /// after a tempo lock (``with(estimatedTempo:tempoLockOctaveFactor:)``) or auto-refinement
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
  /// overridden (``with(estimatedTempo:tempoLockOctaveFactor:)`` /
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
  /// extrapolation, or `nil` when no beats were detected — UNLESS a free-standing
  /// ``BeatGridAnchorSource/manual`` origin was placed (Story 8.12), which survives
  /// on an empty-`beats` grid. See ``BeatGridAnchor``.
  ///
  /// **Invariant (coupled anchors):** when non-`nil` AND
  /// ``BeatGridAnchor/beatIndex`` is non-`nil`, the index always addresses a real
  /// entry of ``beats`` (`0 ..< beats.count`) and the anchor's ``BeatGridAnchor/presentationTime``
  /// equals `beats[beatIndex].presentationTime`, so `beats[gridOrigin!.beatIndex!]`
  /// is safe and agrees. A *present* index out of range (a hostile `Codable`
  /// payload or a manual misconstruction) drops the whole anchor to `nil` at
  /// construction. A `nil` index marks a **free-standing** anchor whose
  /// ``BeatGridAnchor/presentationTime`` stands on its own (no coupled beat); it is
  /// kept only for ``BeatGridAnchorSource/manual`` (DD #2/#3). The cross-field check
  /// lives here — ``BeatGridAnchor`` alone clamps a present `beatIndex ≥ 0` but
  /// cannot know `beats.count`.
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

  /// The octave factor a ``BeatGridTempoLock`` applied to the lock target when it
  /// snapped that target onto this grid's octave density (issue #62).
  ///
  /// `1` (the default) means **no shift** — no lock fired (`lock == .off`), the
  /// lock left the grid unlocked (a more-than-an-octave disagreement or a
  /// non-finite/non-positive target), or the target already shared the grid's
  /// octave (``TempoAgreement/agree``). `2` means the applied tempo was the
  /// target **doubled** (the grid runs at the faster octave — the
  /// ``TempoAgreement/octaveEquivalent(factor:)`` `+2` direction); `-2` means it
  /// was **halved** (the slower octave).
  ///
  /// Because ``BeatGridTempoLock/bpm(_:)`` treats the caller's value as
  /// authoritative, a `2` / `-2` here is the one diagnostic that tells a consumer
  /// their `.bpm(value)` was octave-shifted to `value × 2` / `value × 0.5` on
  /// ``estimatedTempo`` — the consumer's original target is recoverable as
  /// `estimatedTempo` divided by the factor (treating `-2` as `0.5`). The shift
  /// itself is by design (lock to the grid's octave density); this field only
  /// surfaces it.
  ///
  /// ## Why `Int`, not a `Double` pair
  /// Mirroring ``TempoAgreement``'s octave factor, this is an `Int` (`∈
  /// {-2, 1, 2}`), not the raw requested/applied `Double`s. An `Int` cannot be
  /// `NaN`, so it adds no sanitization site to ``BeatGrid``'s NaN-free→`Hashable`
  /// doctrine, and `1` keeps default-options output byte-identical. The raw pair
  /// is derivable from `CombinedAnalysisResult.bpm.bpm` and ``estimatedTempo``.
  public let tempoLockOctaveFactor: Int

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
  ///   - gridOrigin: The extrapolation anchor, or `nil` when no beats. Sanitized by
  ///     three rules on `beatIndex` (DD #3): (a) **present and in range** → rebuilt
  ///     from `beats[beatIndex]` (time/confidence/strength), preserving `beatIndex` +
  ///     `source`, so it always agrees with the indexed beat; (b) **present and out
  ///     of range** → the whole anchor is dropped to `nil` (a claimed-but-invalid
  ///     beat relationship is hostile/stale — this holds even for `source ==
  ///     .manual`); (c) **`nil`** (free-standing) → kept iff `source == .manual`,
  ///     with the supplied `presentationTime`/`confidence`/`strength` clamped as-is
  ///     (a `nil`-index non-`.manual` anchor is incoherent and dropped).
  ///     `source` is preserved as provenance. On a decoded payload it is untrusted,
  ///     so a bar-snap consumer must gate on `source == .downbeat` AND `downbeats`
  ///     being `.detected`, never `source` alone. The one exception is `source ==
  ///     .manual`: it has **no second field to corroborate** (it coexists with
  ///     `.notAttempted`), so honoring it IS trusting `source` alone — acceptable
  ///     only because a `.manual` origin is inherited from whoever wrote the payload
  ///     (typically the consumer's own cache), unlike `.downbeat` which is
  ///     cross-checked against detection. That asymmetry is why rule (c) admits a
  ///     decoded free-standing `.manual` origin.
  ///   - coverage: What span `beats` cover (sanitized on the way in).
  ///   - schemaVersion: The persisted semantic-contract version. Defaulted to
  ///     ``currentSchemaVersion`` so every producer auto-stamps the current
  ///     version with no call-site change; stored faithfully (not range-validated).
  ///   - tempoLockOctaveFactor: The octave factor a ``BeatGridTempoLock`` applied
  ///     to the lock target (`1` no shift / `2` doubled / `-2` halved). Defaulted
  ///     to `1` so every non-lock producer is byte-identical; stored faithfully
  ///     (not range-validated — like ``schemaVersion``).
  public init(
    beats: [BeatTimestamp],
    downbeats: DownbeatResult,
    estimatedTempo: Double,
    confidence: Float,
    tempoAgreement: TempoAgreement,
    gridOrigin: BeatGridAnchor?,
    coverage: BeatGridCoverage,
    schemaVersion: Int = BeatGrid.currentSchemaVersion,
    tempoLockOctaveFactor: Int = 1
  ) {
    self.schemaVersion = schemaVersion
    self.tempoLockOctaveFactor = tempoLockOctaveFactor
    self.beats = beats
    self.downbeats = downbeats
    self.estimatedTempo = BeatGridClamp.clampNonNegative(estimatedTempo)
    self.confidence = BeatGridClamp.clampUnit(confidence)
    self.tempoAgreement = tempoAgreement
    // Enforce the gridOrigin contract via three rules on `beatIndex` (DD #3). The
    // index is the mechanical-coupling discriminator: a present index couples the
    // anchor to a detected beat (rebuild applies); `nil` marks a free-standing
    // origin whose `presentationTime` is authoritative. ``BeatGridAnchor`` clamps a
    // present `beatIndex ≥ 0` but cannot bound it above (it does not know
    // `beats.count`) nor judge coherence (it cannot see `beats`/`downbeats`), so the
    // cross-field gate lives here.
    self.gridOrigin = gridOrigin.flatMap { origin -> BeatGridAnchor? in
      guard let index = origin.beatIndex else {
        // (c) Free-standing (`nil` index): keep iff a human asserted it
        // (`.manual`); an auto source with no beat to name is incoherent → drop
        // (the safe hostile-decode posture — a payload cannot smuggle a free-standing
        // non-manual origin). The float fields are already clamped by
        // ``BeatGridAnchor/init``, so the supplied free time is authoritative as-is.
        return origin.source == .manual ? origin : nil
      }
      // (b) Present but out of range → drop the WHOLE anchor (a claimed-but-invalid
      // beat relationship is hostile/stale — do NOT promote it to a free-standing
      // anchor at its stale time; a genuinely free origin always carries `beatIndex
      // == nil` and survives via rule (c)). Holds even for `source == .manual`.
      guard index < beats.count else { return nil }
      // (a) Present and in range → rebuild from `beats[index]` (time/confidence/
      // strength), preserving `beatIndex` + `source`. The analyzer always constructs
      // anchors this way (a no-op on honest grids), but a hostile/stale decoded anchor
      // with an in-range index and a mismatched `presentationTime` would otherwise
      // break the extrapolation contract `gridOrigin.presentationTime + period·n`.
      // `source` is left as untrusted provenance on a decoded payload — a bar-snap
      // consumer must gate on `source == .downbeat` AND `downbeats` being `.detected`,
      // never `source` alone (so we do NOT invent a different source here, only repair
      // the mechanical invariant).
      let beat = beats[index]
      return BeatGridAnchor(
        beatIndex: index,
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
      schemaVersion: schemaVersion,
      tempoLockOctaveFactor: tempoLockOctaveFactor)
  }

  /// Returns a copy of this grid with both ``estimatedTempo`` and
  /// ``tempoLockOctaveFactor`` overridden and every other field forwarded from
  /// `self` (issue #62).
  ///
  /// Used by the ``BeatGridTempoLock`` path
  /// (`AudioAnalysisService.applyTempoLock`) to record, in one forwarding step,
  /// both the octave-normalized authoritative tempo and the factor that
  /// normalization applied — so a consumer can detect a `.bpm(value)` that was
  /// snapped to `value × 2` / `value × 0.5`. The new tempo routes through the
  /// clamping memberwise init (W52 forward-every-field), so a non-finite/non-positive
  /// value normalizes to the `0.0` sentinel exactly as a freshly-constructed grid would.
  func with(estimatedTempo newTempo: Double, tempoLockOctaveFactor newFactor: Int) -> BeatGrid {
    BeatGrid(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: newTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion,
      tempoLockOctaveFactor: newFactor)
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
  /// bypass the clamp). `tempoAgreement`, `gridOrigin`, `coverage`,
  /// `schemaVersion`, and `tempoLockOctaveFactor` are decoded with
  /// `decodeIfPresent` and default to their "no information" values
  /// (``TempoAgreement/notCompared`` / `nil` / ``BeatGridCoverage/analysisWindow``
  /// / `1` / `1`), mirroring how the Story-8.3 optional agreement flag defaulted
  /// to `nil` when absent. A legacy grid
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
    // Issue #62: a legacy grid serialized before `tempoLockOctaveFactor` existed
    // decodes as `1` (absent → 1, the "no shift" default), mirroring the
    // `schemaVersion` and `tempoAgreement` absent-defaulting above. An additive
    // optional-with-default field does NOT bump `schemaVersion` (no key
    // removed/redefined). Stored faithfully — an out-of-{-2,1,2} value is not
    // folded here (it is inert diagnostic provenance, not auto-sync input).
    let tempoLockOctaveFactor =
      try container.decodeIfPresent(Int.self, forKey: .tempoLockOctaveFactor) ?? 1
    self.init(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: gridOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion,
      tempoLockOctaveFactor: tempoLockOctaveFactor)
  }

  // MARK: CustomStringConvertible

  /// One-line summary.
  public var description: String {
    let origin =
      gridOrigin.map { "beat \($0.beatIndex.map { String($0) } ?? "nil")@\($0.presentationTime)s" }
      ?? "none"
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
  /// collapse early beats and distort the grid). The earliest/latest timestamp is taken
  /// over the **union** of everything that moves — ``beats``, the detected-downbeat beats,
  /// AND a free-standing (`nil`-index) ``gridOrigin`` (a coupled anchor mirrors
  /// `beats[beatIndex]`, so it is already covered). A non-finite `seconds`, a `0` shift, a
  /// grid with no movable timestamps (no beats, no detected downbeats, no free-standing
  /// anchor), or a shift that nets to zero after clamping is a no-op.
  ///
  /// ``estimatedTempo``, ``confidence``, ``tempoAgreement``, ``coverage`` (which describes
  /// the analyzed *span length*, not an absolute start time), ``schemaVersion``, and
  /// ``tempoLockOctaveFactor`` are unchanged — `offset` shifts presentation coordinates only.
  ///
  /// Use for output-device latency compensation (e.g. `AVAudioEngine.outputLatency`) or a
  /// manual nudge. Do **not** use it for codec encoder priming: AVFoundation already
  /// removes declared AAC/MP3/M4A/CAF priming, so the timestamps are already
  /// playback-aligned and subtracting priming would double-correct.
  ///
  /// - Parameter seconds: The shift to apply, in seconds (`+` later, `−` earlier).
  /// - Returns: A new grid with shifted presentation times.
  public func offset(by seconds: Double) -> BeatGrid {
    guard seconds.isFinite, seconds != 0 else { return self }

    // A free-standing (`nil`-index) `gridOrigin` is the one anchor NOT mirrored by a
    // beat — its time moves on its own and must be folded into the min/max and shifted
    // explicitly. A coupled anchor (`beatIndex != nil`) follows `beats[beatIndex]`.
    let freeStandingOrigin: BeatGridAnchor? = {
      guard let origin = gridOrigin, origin.beatIndex == nil else { return nil }
      return origin
    }()

    // Minimum/maximum presentation time across EVERY timestamp that will move — the
    // UNION of `beats`, the detected-downbeat beats, and a free-standing anchor — seeded
    // from ±∞ (not a `?? 0` fold) so a `beats: []` grid carrying only a lone free anchor
    // still seeds `minTime` from the anchor's own time and can move earlier (DD #4).
    var minTime = Double.infinity
    var maxTime = -Double.infinity
    for t in beats.lazy.map(\.presentationTime) {
      minTime = min(minTime, t)
      maxTime = max(maxTime, t)
    }
    if case .detected(let estimate) = downbeats {
      for t in estimate.beats.lazy.map(\.presentationTime) {
        minTime = min(minTime, t)
        maxTime = max(maxTime, t)
      }
    }
    if let origin = freeStandingOrigin {
      minTime = min(minTime, origin.presentationTime)
      maxTime = max(maxTime, origin.presentationTime)
    }

    // No-op when there are NO movable timestamps (no beats, no detected downbeats, no
    // free anchor) — the min/max stayed at their ±∞ seeds. Replaces the old
    // `!beats.isEmpty` guard so a `beats: []` + free-standing-manual grid still offsets.
    guard minTime.isFinite, maxTime.isFinite else { return self }

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

    // Anchor handling branches on coupling (DD #4):
    //  - FREE-STANDING (`beatIndex == nil`): `init` rule (c) does NOT rebuild it, so
    //    shift the anchor's own time HERE and pass the shifted free anchor.
    //  - COUPLED (`beatIndex != nil`) or a `nil` `gridOrigin`: pass the ORIGINAL anchor
    //    unchanged — `init` rebuilds it from the SHIFTED `beats[beatIndex]`, so its time
    //    follows the shift consistently (A4). Do NOT replace a coupled anchor with a
    //    `nil`-index one (that would strip its coupling).
    let shiftedOrigin: BeatGridAnchor?
    if let origin = freeStandingOrigin {
      shiftedOrigin = BeatGridAnchor(
        beatIndex: nil,
        presentationTime: origin.presentationTime + effective,
        confidence: origin.confidence,
        strength: origin.strength,
        source: origin.source)
    } else {
      shiftedOrigin = gridOrigin
    }

    return BeatGrid(
      beats: beats.map(shifted),
      downbeats: shiftedDownbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: shiftedOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion,
      tempoLockOctaveFactor: tempoLockOctaveFactor)
  }
}

// MARK: - Manual anchor reposition (Story 8.12)

/// How ``BeatGrid/repositioningAnchor(to:mode:)`` maps a caller-supplied time to the
/// grid's bar-origin anchor — snapping to the nearest detected beat (the default), or
/// placing a free-standing anchor at the exact time (Story 8.12).
///
/// A transient call-time parameter, never persisted in a ``BeatGrid`` — so it is
/// `Sendable, Equatable` only, **not** `Codable`/`Hashable` (the persisted provenance
/// lives on ``BeatGridAnchorSource``; this mirrors the sibling parameter-enum
/// ``BeatGridTempoLock``, the manual *tempo* half). `CaseIterable` is kept only for the
/// `allCases.count == 2` exhaustiveness lock and documented room for future
/// `.nearestDownbeat` / `.nearestBar` modes.
public enum BeatGridAnchorRepositionMode: Sendable, Equatable, CaseIterable {

  /// Map the caller's time to the **nearest detected beat** and couple the anchor to it
  /// (the default, least-surprising behavior). The returned ``BeatGrid/gridOrigin`` has
  /// ``BeatGridAnchor/beatIndex`` set to that beat and takes its time/confidence/strength
  /// from the beat. A no-op on an empty-``BeatGrid/beats`` grid (nothing to snap to).
  case snapToNearestBeat

  /// Place a **free-standing** anchor at the caller's (clamped, `≥ 0`) time, decoupled
  /// from the detected beats (``BeatGridAnchor/beatIndex`` `nil`). The truer Rekordbox
  /// edit — the bar line sits where the caller put it, not constrained to a detected
  /// beat. Works even on an empty-``BeatGrid/beats`` grid.
  case exactTime
}

extension BeatGrid {

  /// Returns a copy of this grid whose ``gridOrigin`` bar-origin anchor is repositioned to
  /// `time`, with ``BeatGridAnchorSource/manual`` provenance and every other field
  /// forwarded bit-identically from `self` (Story 8.12).
  ///
  /// The manual *anchor* (bar-origin) half of a Rekordbox-style hand-correction, the
  /// complement to the manual *tempo* half (``BeatGridTempoLock/bpm(_:)``). Use it when
  /// auto downbeat / phase-consistency anchoring placed the bar phase wrong, or abstained
  /// entirely, and a human asserts the origin. Sits beside ``offset(by:)`` (a uniform
  /// time nudge) — this one repositions the single anchor, not the whole grid.
  ///
  /// `mode` controls snapping (the operator-required toggle):
  /// - ``BeatGridAnchorRepositionMode/snapToNearestBeat`` (default): the anchor is
  ///   **coupled** to the nearest detected beat (`argmin |beat.presentationTime − time|`,
  ///   ties → the lower ``BeatGridAnchor/beatIndex``); time/confidence/strength come from
  ///   that beat.
  /// - ``BeatGridAnchorRepositionMode/exactTime``: the anchor is **free-standing** at the
  ///   clamped `time` (``BeatGridAnchor/beatIndex`` `nil`, the time authoritative).
  ///
  /// Pure, deterministic, total — never throws or traps. No-ops returning `self`
  /// unchanged: a non-finite `time`; `.snapToNearestBeat` on an empty-``beats`` grid
  /// (nothing to snap to). `.exactTime` works on an empty-``beats`` grid (a free-standing
  /// origin needs no beat). It repositions the anchor ONLY — ``downbeats`` is **not**
  /// forced to ``DownbeatResult/detected`` (a `.manual` origin asserts the bar without
  /// claiming detection ran), and ``beats`` is never re-spaced.
  ///
  /// - Parameters:
  ///   - time: The decoded-PCM-relative target time, in seconds. Clamped `≥ 0` by
  ///     ``BeatGridAnchor`` (so a negative finite time places the free anchor at `0`, or
  ///     snaps to the earliest beat).
  ///   - mode: Snap to the nearest detected beat (default) or place a free-standing anchor
  ///     at the exact time.
  /// - Returns: A new grid with the repositioned ``gridOrigin``, or `self` on a no-op.
  public func repositioningAnchor(
    to time: Double,
    mode: BeatGridAnchorRepositionMode = .snapToNearestBeat
  ) -> BeatGrid {
    // Total-function no-op: a non-finite target has no honest placement.
    guard time.isFinite else { return self }

    let newOrigin: BeatGridAnchor
    switch mode {
    case .snapToNearestBeat:
      // Couple to the nearest detected beat: `beatIndex` set, time/conf/strength taken
      // from that beat (the memberwise-init rebuild reproduces them). Nothing to snap to
      // on an empty-`beats` grid → no-op.
      guard let index = nearestBeatIndex(to: time) else { return self }
      let beat = beats[index]
      newOrigin = BeatGridAnchor(
        beatIndex: index,
        presentationTime: beat.presentationTime,
        confidence: beat.confidence,
        strength: beat.strength,
        source: .manual)
    case .exactTime:
      // Free-standing placement: `beatIndex == nil`, the caller's clamped time
      // authoritative. A human-asserted origin carries full confidence/strength (there is
      // no underlying beat to read salience from). Survives init rule (c) because
      // `source == .manual`.
      newOrigin = BeatGridAnchor(
        beatIndex: nil,
        presentationTime: time,
        confidence: 1.0,
        strength: 1.0,
        source: .manual)
    }

    // Forward every non-`gridOrigin` field from `self` (W52 forward-every-field) so only
    // the anchor changes (AC #9 self-vs-result bit-identity; `schemaVersion` forwarded,
    // not re-stamped).
    return BeatGrid(
      beats: beats,
      downbeats: downbeats,
      estimatedTempo: estimatedTempo,
      confidence: confidence,
      tempoAgreement: tempoAgreement,
      gridOrigin: newOrigin,
      coverage: coverage,
      schemaVersion: schemaVersion,
      tempoLockOctaveFactor: tempoLockOctaveFactor)
  }

  /// Index of the detected beat nearest `time` (`argmin |beat.presentationTime − time|`),
  /// ties broken to the LOWER index (the earlier beat). `nil` for an empty ``beats``.
  /// An ordinary control-flow scan over the in-memory array (not a bulk vDSP op).
  private func nearestBeatIndex(to time: Double) -> Int? {
    guard !beats.isEmpty else { return nil }
    var bestIdx = 0
    var bestDist = abs(beats[0].presentationTime - time)
    for i in 1..<beats.count {
      let d = abs(beats[i].presentationTime - time)
      // Strict `<` keeps the lower index on an exact-distance tie (earlier beat wins).
      if d < bestDist {
        bestDist = d
        bestIdx = i
      }
    }
    return bestIdx
  }
}
