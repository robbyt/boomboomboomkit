//
//  UnifiedSignalPool.swift
//  BoomBoomBoomKit
//
//  Stage 1 internal-only adapter wrapping DSP, ML, file-metadata, and
//  beat-grid signals into a typed participation contract. Per Story 6.1
//  DD #6, this is constructed post-runPreCorroborationPipeline /
//  pre-MetadataCorroborator.apply in AudioAnalysisService. The pool is
//  consumed only by trace population in Stage 1; CandidateMergeStrategy.merge
//  continues to receive [BPMResult] unchanged (signature frozen — break lands
//  Story 6.4).
//

internal struct UnifiedSignalPool: Sendable {
  let entries: [SignalParticipationTraceEntry]
}
