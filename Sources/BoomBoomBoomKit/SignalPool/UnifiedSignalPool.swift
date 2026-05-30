//
//  UnifiedSignalPool.swift
//  BoomBoomBoomKit
//
//  Authoritative selection-input bundle for the unified-signal-pool ensemble.
//  Story 6.5b (KDD-A6 Stage 3) flips this from the Stage-1/2 trace-only adapter
//  (`{ let entries: [SignalParticipationTraceEntry] }`, nil on the default path)
//  into the real data model consumed by `BPMSelectionPolicy.select(from:)`:
//  the per-window DSP candidate set (Phase 1 aggregation input), the parsed
//  file-metadata signal (Phase 2a corroboration input), and the pre-computed ML
//  participation. The pool is now built UNCONDITIONALLY (authoritative, not nil
//  on the default path) — the per-source trace entries it used to carry are
//  produced by `select` from the merged voice when a trace exists.
//

internal struct UnifiedSignalPool: Sendable {
  /// Per-window DSP results — the Phase 1 cross-window aggregation input.
  let dspWindows: [BPMResult]

  /// Parsed file-metadata signal — the Phase 2a multiplicative-corroboration input.
  let metadataInput: MetadataCorroborationInput

  /// Candidate cap for Phase 1 aggregation (resolved technique set's `candidateCount`).
  let candidateCount: Int

  /// Pre-computed ML participation for the per-source trace entries. The service
  /// owns this because it depends on `Options.mlTechnique` and the selected
  /// policy's `invokesMLInference`; ML inference itself runs post-selection
  /// (preserving the no-accuracy-change ordering), so the entry is `.absent`
  /// (no technique / policy without ML) or `.abstained(.sourceSpecific(
  /// AbstainReason.mlEvalDeferred))` — never `.present` at this point.
  let mlParticipation: SignalParticipation

  /// Stage weight applied to every per-source trace entry (invariant `1.0`).
  let weight: Double
}
