# KDD-B2 ablation comparison (v1 scaffolding)

> Guardrail 1: v1 features — these metrics do NOT transfer to v2 (Story 7.5).
> The decision that DOES carry forward is the relative winner below.

**decision: maskedMelPretrain**

_Acc1 within +/-2 tracks (88 vs 88); tiebreak on ECE_half_double (0.5542 vs 0.5353; qualifying tracks 92)._

| axis | supervisedAugmented | maskedMelPretrain |
|---|---|---|
| (a) tony.val Acc1 | 88/92 | 88/92 |
| (b) inference ms/file | 2.117 | 1.212 |
| (d) ECE_half_double | 0.5542 | 0.5353 |
|     ECE qualifying tracks | 92 | 92 |
| (e) leave-artist-out Acc1 | 101/104 | 101/104 |
|     random-split Acc1 | 0.8942307692307693 | 0.9134615384615384 |
|     LAO - random delta (FLOOR; see DD #6) | 0.07692307692307687 | 0.05769230769230771 |

> Axis (b) caveat: these forward-latency numbers were measured BEFORE the MPS
> synchronization fix (Copilot PR #26) and under-report real compute (MPS ops are
> async). They are disposable v1 scaffolding — do NOT promote them. A regenerated
> report would carry MPS-synced forward latency; the winner (decided by Acc1 + ECE,
> not latency) is unaffected.

(c) peak memory: **1532.5 MB** process-wide RSS (both variants evaluated in one process; not per-variant — `ru_maxrss` is a process high-water mark. The TempoCNN is ~1.3 MB either way; footprint is torch/librosa-runtime dominated. A per-variant figure would need a subprocess per arm — out of scope for v1).

Reliability-diagram bins + softmax-entropy histogram are in the sibling `kdd-b2-comparison-v1.json` (matplotlib is not a dependency; the `.png` is deferred to Story 7.7 / FR-25).

If `random-split Acc1` shows `None`, run B (DD #6 random-split) has not been executed; the LAO delta is pending. The delta is a FLOOR on the artist-generalization gap (the random split reshuffles an already-artist-disjoint pool).
