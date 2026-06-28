//
//  DownbeatStrategy.swift
//  BoomBoomBoomKit
//
//  Selectable downbeat-estimation strategy (Story 8.11): which evidence source
//  places the bar phase when `detectDownbeats == true`.
//

// MARK: - DownbeatStrategy

/// Which evidence source the downbeat-phase estimator uses to place the
/// top-of-measure (Story 8.11).
///
/// Consulted **only** when ``AudioAnalysisService/Options/detectDownbeats`` (or
/// ``BPMAnalyzer/Options/detectDownbeats``) is `true` — the existing opt-in gate,
/// default `false`. The default ``metricalAccent`` reproduces the Story-8.5a
/// estimator bit-for-bit, so adding this selector is byte-identical for both the
/// default-off path AND the existing `detectDownbeats == true` path.
///
/// This is **not** a ``DSPTechnique`` (it changes no DSP feature and does not
/// expand the ablation matrix) and **not** a ``BPMSelectionPolicy`` /
/// ``EnsemblePolicy`` case — it governs only downbeat *phase* placement, never the
/// tempo, the tempo octave, or BPM winner selection.
///
/// ## NaN-free → `Hashable`
/// A payload-free enum, so the compiler-synthesized `Hashable`/`Equatable` and the
/// bare-string `Codable` are sound by construction. ``CaseIterable`` is justified
/// here (the acceptance benchmark and a future ablation enumerate the strategies);
/// the sibling provenance enums (``BeatGridAnchorSource`` / ``MeterSource``) are
/// deliberately not `CaseIterable` because no consumer enumerates them.
public enum DownbeatStrategy: Sendable, Hashable, Codable, CaseIterable {

  /// The Story-8.5a metrical-accent estimator: a low-band / kick accent marks the
  /// bar start, with a conservative four-part abstain gate. The default; ships
  /// verbatim from Story 8.5a.
  case metricalAccent

  /// The Story-8.11 structural-drop estimator: the track's main energy **drop**
  /// (which in dance music lands on a downbeat) anchors the bar phase. Sources its
  /// energy contour from the full pre-trim signal so the drop is interior, detects
  /// it with a novelty step detector, and maps it to the nearest beat's
  /// position-quantized bar phase. Abstain-heavy by design.
  case structuralDrop

  /// Cross-validate ``metricalAccent`` and ``structuralDrop``: both fire and agree
  /// → detected (boosted confidence); both fire and disagree → abstain (a phase
  /// conflict between two strong sources is a safety red flag); exactly one fires
  /// → agreement-priority single-source admission; the drop confident only at the
  /// half-bar (beat-1-vs-beat-3) → ``metricalAccent`` breaks the 1-vs-3 tie.
  case combined
}
