//
//  BeatGridTempoLock.swift
//  BoomBoomBoomKit
//
//  Opt-in locking of the beat-grid tempo to an authoritative constant BPM.
//

/// Controls whether the beat grid's tempo is locked to an authoritative constant
/// BPM instead of the tracker's own measured ``BeatGrid/estimatedTempo``.
///
/// The beat tracker is already constant-tempo (one ``BeatGrid/gridOrigin`` anchor
/// + one ``BeatGrid/estimatedTempo``; consumers extrapolate
/// `gridOrigin.presentationTime + (60/estimatedTempo)·n`). But the *measured*
/// tempo can be a fraction of a BPM off, and on a multi-minute track even a
/// ~0.1 BPM error accumulates into audible phase drift — the extrapolated grid
/// slides off the beat by the end. For material known to be a fixed BPM (most
/// electronic / DJ music), locking the grid to a clean tempo removes that drift.
///
/// **Octave normalization.** In every locking case the target tempo is
/// octave-normalized to the grid's own tempo (within the library's 2% agreement
/// band) before it is applied: locking a 160 BPM grid to an 80 BPM source snaps
/// to 160, NOT a halved beat density. If the target and the grid disagree by more
/// than an octave, the grid is left **unlocked** (the tracker's tempo stands)
/// rather than forced to an implausible tempo.
///
/// **Scope.** Honored only on the combined
/// ``AudioAnalysisService/analyze(url:options:)`` /
/// ``AudioAnalysisService/analyze(decoded:options:)`` path, which has the
/// authoritative BPM-stage tempo. Standalone
/// ``AudioAnalysisService/analyzeBeatGrid(url:options:)`` ignores it (there is no
/// external tempo to lock to). The grid's ``BeatGrid/tempoAgreement`` keeps the
/// **pre-lock** classification as a diagnostic — locking changes the tempo the
/// grid extrapolates from, not the record of how the tracker and BPM stage
/// originally compared.
///
/// Not `Hashable`: the ``bpm(_:)`` payload is a `Double` that could be `NaN`
/// (mirrors `MLExecutionPolicy` / `EnsembleDecision`), so it stays
/// `Equatable`-only.
public enum BeatGridTempoLock: Sendable, Equatable {

  /// No locking — the grid keeps the tracker's measured ``BeatGrid/estimatedTempo``.
  /// Byte-reproduces prior behavior.
  case off

  /// Lock to the BPM stage's detected tempo, octave-normalized to the grid.
  case bpmStage

  /// Lock to a caller-supplied exact BPM, octave-normalized to the grid. A
  /// non-finite or non-positive value (or one that disagrees with the grid by
  /// more than an octave) leaves the grid unlocked.
  case bpm(Double)
}
