# Deferred Work

## Non-Octave BPM Disambiguation (3:2, 3:1 ratios)

**Deferred from:** Phase 3 batch planning (2026-03-26)
**Reason:** Split from multi-window candidate merging to keep specs single-goal

Add 3:2 and 3:1 ratio detection to `resolveOctaveAmbiguity` in `BPMAnalyzer.swift`. Currently only handles 2:1 octave pairs (ratio 1.92-2.08). Need to add:
- 3:2 ratio check (1.45-1.55 tolerance)
- 3:1 ratio check (2.85-3.15 tolerance)

Two known failing Prodigy tracks at triplet/2-3 time lock serve as validation targets. Sub-band voting mechanism already exists and can be reused for these ratios.

**Files:** `BPMAnalyzer.swift` (resolveOctaveAmbiguity, confirmWithSubBandPeaks)
**Validation:** Two Prodigy tracks + full OA300 benchmark regression check

## Confidence Semantics for Merge Strategies

**Deferred from:** Multi-window candidate merging code review (2026-03-26)
**Reason:** Design decision, not a bug -- revisit after ablation data

Currently all merge strategies report `max(confidence)` across all windows. For clustered strategies, the winning BPM may come from a low-confidence window while a high-confidence window contributed a different candidate. Consider per-cluster confidence (max confidence among windows contributing to the winning cluster) after ablation shows which strategy works best.

**Files:** `CandidateMergeStrategy.swift`

## Post-Disambiguation Merge Strategies

**Deferred from:** Merge strategy ablation (2026-03-27)
**Reason:** Ablation showed all clustering strategies hurt Acc1 vs maxConfidence

The 6 clustering-based merge strategies (dedup, quorum, average, median, weightedAverage, union) all perform worse than `maxConfidence` (59.8% vs 69.5% Acc1). Root cause: they merge raw candidates from `BPMResult.candidates` which are pre-disambiguation values. Each window's `BPMResult.bpm` has already been through sub-band voting and octave disambiguation, but the `.candidates` array contains the raw top-N peaks before that step.

To make merge strategies useful, they would need to operate on the *final disambiguated BPM* from each window rather than the raw candidates. This would mean:
1. Collect `(bpm: result.bpm, confidence: result.confidence)` from each window (post-disambiguation)
2. Cluster/vote on those final values
3. Return the winner

This is a fundamentally different approach from the current candidate-level merging.

**Files:** `CandidateMergeStrategy.swift`, `AudioAnalysisService.swift`
**Validation:** OA300 benchmark, targeting Acc1 > 69.5%
