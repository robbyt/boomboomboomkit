# Ablation Results — Full 64-Combination Matrix

**Date:** 2026-03-26
**Corpus:** OA300 (82 tracks, DnB-heavy, Rekordbox ground truth)
**Baseline:** `fine+vote` (Acc1=64.6%)

## Top Combinations (sorted by Acc1)

| Rank | Configuration | Acc1 | Acc2 | Correct | Delta |
|------|--------------|------|------|---------|-------|
| 1 | sharp+fine+vote | 67.1% | 81.7% | 55/82 | +2 |
| 1 | sharp+fine+norm+vote | 67.1% | 81.7% | 55/82 | +2 |
| 3 | sharp+vote | 65.9% | 81.7% | 54/82 | +1 |
| 3 | sharp+norm+vote | 65.9% | 81.7% | 54/82 | +1 |
| 3 | sharp+top5+fine+vote | 65.9% | 81.7% | 54/82 | +1 |
| 3 | sharp+top5+fine+norm+vote | 65.9% | 81.7% | 54/82 | +1 |
| 7 | fine+vote (baseline) | 64.6% | 79.3% | 53/82 | -- |
| 7 | fine+norm+vote | 64.6% | 79.3% | 53/82 | 0 |
| 7 | thresh+vote | 64.6% | 81.7% | 53/82 | 0 |
| 7 | thresh+norm+vote | 64.6% | 81.7% | 53/82 | 0 |

## Key Findings

1. **ACF sharpening is the only technique that improves Acc1** (+2 tracks when combined with voting+fineGrid).
2. **Sub-band normalization is neutral** -- `sharp+fine+vote` and `sharp+fine+norm+vote` tie at 67.1%.
3. **Adaptive threshold hurts** -- every combo including `thresh` performs at or below baseline.
4. **Expanded candidates (top5) hurts** -- adds noise to the candidate pool without improving octave resolution.
5. **Sub-band voting is essential** -- without it, best Acc1 drops to 57.3%.
6. **Fine-grid refinement matters** -- `sharp+vote` (65.9%) vs `sharp+fine+vote` (67.1%).

## Named Presets (validated)

| Preset | Techniques | Acc1 | Status |
|--------|-----------|------|--------|
| `.optimal` | sharp+fine+vote | 67.1% | Validated as best |
| `.dnbOptimized` | sharp+fine+norm+vote | 67.1% | Validated (ties optimal on this corpus) |
| `.baseline` | fine+vote | 64.6% | Reference |
| `.full` | all 6 | 59.8% | Confirmed worse than baseline |

## Per-Track Impact (selected presets vs baseline)

| Technique | Improved | Regressed | Net |
|-----------|----------|-----------|-----|
| sharp | +4 | -2 | +2 |
| thresh | +1 | -2 | -1 |
| norm | 0 | 0 | 0 |
| top5 | +0 | -3 | -3 |
| optimal | +4 | -2 | +2 |
| dnbOptimized | +4 | -2 | +2 |
| full | +2 | -6 | -4 |

## Bottom Combinations

| Configuration | Acc1 | Delta |
|--------------|------|-------|
| top5+norm | 47.6% | -14 |
| top5 | 47.6% | -14 |
| norm | 48.8% | -13 |
| minimal | 48.8% | -13 |

## Multi-Window Merge Strategy Ablation (2026-03-27)

**Date:** 2026-03-27
**Baseline:** `maxConfidence` at intensity 7 (Acc1=69.5%)
**Change:** Removed early exit for intensity 6+. All 3 windows (30s, 60s, 90s) now run; candidates merged via configurable strategy.

### Before vs After (early exit removal)

| Metric | Before (early exit) | After (all windows) | Delta |
|--------|--------------------|--------------------|-------|
| Acc1 | 68.3% (56/82) | 69.5% (57/82) | **+1** |
| Acc2 | 85.4% (70/82) | 89.0% (73/82) | **+3** |

Running all windows and picking the highest-confidence one improved accuracy. The early exit was cutting short before finding a better window.

### Strategy Comparison (intensity 7, all windows)

| Strategy | Acc1 | Acc2 | Correct |
|----------|------|------|---------|
| **maxConfidence** | **69.5%** | **89.0%** | **57/82** |
| quorum | 61.0% | 75.6% | 50/82 |
| dedup | 59.8% | 74.4% | 49/82 |
| average | 59.8% | 76.8% | 49/82 |
| median | 59.8% | 76.8% | 49/82 |
| weightedAverage | 59.8% | 76.8% | 49/82 |
| union | 59.8% | 74.4% | 49/82 |

### Key Findings

1. **`maxConfidence` wins decisively.** All clustering-based strategies perform worse.
2. **Why clustering hurts:** `BPMAnalyzer.estimateBPM` runs octave disambiguation per-window. Clustering raw candidates across windows loses this disambiguation. The merged candidates are pre-disambiguation values that haven't been through sub-band voting.
3. **The real win was removing early exit**, not merging candidates. Running all 3 windows gives the highest-confidence picker more options (+1 Acc1, +3 Acc2).
4. **Merge strategies need post-disambiguation rethinking.** To improve on `maxConfidence`, strategies would need to merge the *final BPM* from each window (after disambiguation), not the raw candidates (before disambiguation).

## Limitations

- OA300 is DnB-heavy. Results may differ on other genres.
- Corpus expansion needed before shipping `.optimal` as production default.
