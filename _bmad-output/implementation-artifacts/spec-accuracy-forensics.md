---
title: 'Phase 0 — Forensic accuracy instrumentation'
type: 'feature'
created: '2026-06-27'
status: 'in-review'
baseline_commit: e79f5f6dc2a0c2d3492d249cba45486b6aac0454
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The benchmark harness reports pass/fail (Acc1/Acc2) but never *why* a track fails — it cannot distinguish an octave/triplet selection error from a track whose correct BPM was never even surfaced as a candidate (the repo's own `TODO.md:12`: 11/30 OA300 failures had the true BPM absent from the top-3). Without that attribution, accuracy experiments cannot be judged.

**Approach:** Add a reporting-only forensic layer — a candidate-recall oracle, per-(detected,truth) error-type classifier, per-corpus + per-genre error-type composition, DSP-confidence reliability curve, median/mean/P95 BPM error, and a per-failure label-policy tag — emitted as a per-corpus JSON behind an env gate (`ACCURACY_FORENSICS=1`) and a `make accuracy-forensics` target. Zero DSP code touched.

## Boundaries & Constraints

**Always:** Reporting/measurement only. Reuse the existing 2% relative band via `isAcc1Match`. Keep 3:2 and 2:3 (triplet) categories SEPARATE from 2×/0.5× (octave) — never collapse triplet into octave. Env-gated like the other benchmark suites. Swift 6, value types, Swift Testing, no new SPM deps. JSON artifact + make target mirror the existing `*-impact.json` / `make tempo-refine-impact-report` pattern.

**Ask First:** Any need to touch `Sources/BoomBoomBoomKit/` DSP code (should be none). Any change to the existing `isAcc1Match`/`isAcc2Match` signatures or the `GenreBucket` invariants.

**Never:** Modify DSP, the candidate pipeline, or any `Options` default — the OA300 (58/82 · 74/82) and GiantSteps (537/661 · 546/661) floors must reproduce byte-unchanged. No full per-stage blame harness (onset/ACF/tempogram attribution) — that is Phase 0.5+. No new dependencies.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Acc1 hit | detected≈truth (≤2%) | error category `exact` | N/A |
| Octave miss | detected≈2×truth | category `double` (not `triplet`) | N/A |
| Triplet miss | detected≈1.5×truth | category `threeHalf`, NOT `double`/`other` | N/A |
| Recall: true in top-5 | true BPM (or relative) among candidates[0..<5] | record best rank + matched factor + score-margin vs winner | N/A |
| Recall: absent | true BPM + no relative in candidates | rank=nil → "never surfaced" bucket | N/A |
| Zero/NaN truth or empty candidates | `expected ≤ 0` / `candidates == []` | category `other`, recall rank `nil`; no crash, no NaN | guard, skip row |
| `analyzeBPM` returns nil | non-musical/silent track | track excluded from rates; counted in a `nilCount` field | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` — existing `isAcc1Match`/`isAcc2Match` (DO NOT modify); add the `classifyTempoError(...) -> TempoErrorCategory` classifier here (natural home, additive).
- `Sources/BoomBoomBoomKitTestSupport/AccuracyForensics.swift` — NEW. `TempoErrorCategory` enum; the candidate-recall oracle; `Codable` forensic report structs (per-track detail + per-corpus aggregate: error-type histogram, recall split, confidence-reliability bins, MAE raw/octave-normalized, per-genre error-type composition, label-policy tags); label-policy tagger.
- `Tests/BoomBoomBoomKitBenchmarkTests/AccuracyForensicsTests.swift` — NEW. `@Suite` gated on `ACCURACY_FORENSICS=1`; runs OA300 + GiantSteps via `AudioAnalysisService.analyzeBPM` (reads `result.candidates: [(bpm, score)]`, `.bpm`, `.confidence`); builds the report; writes JSON to `ACCURACY_FORENSICS_OUT_DIR`.
- `Makefile` — add `## accuracy-forensics` target threading `OA300_CORPUS_PATH` + `GIANTSTEPS_CORPUS_PATH` + `ACCURACY_FORENSICS=1` + out dir (mirror `tempo-refine-impact-report`).

## Tasks & Acceptance

**Execution:**
- [x] `AccuracyMatchers.swift` -- add `enum TempoErrorCategory` + `classifyTempoError(_ detected:_ expected:tolerance:)` returning exact/double/half/triple/third/threeHalf/twoThird/other via `isAcc1Match` on each factor (exact wins ties; check octave before triplet before other) -- additive, existing matchers untouched.
- [x] `AccuracyForensics.swift` -- candidate-recall oracle (best rank in {1,3,5,10}, matched factor, winner-vs-oracle score margin), `Codable` per-track + per-corpus report structs, per-genre error-type composition, confidence-reliability bins, MAE (raw + octave-normalized), label-policy tagger, dual-truth (`alternateBPM`/`tempo2`) support -- the forensic model.
- [x] `AccuracyForensicsTests.swift` -- env-gated suite that runs both corpora, assembles the report, prints a summary, and writes `<corpus>` JSON to the out dir -- the harness.
- [x] `Makefile` -- `accuracy-forensics` target -- operator entry point.

**Acceptance Criteria:**
- Given `ACCURACY_FORENSICS=1` + corpus paths, when `make accuracy-forensics` runs, then a per-corpus forensic JSON is written containing the error-type histogram, recall split (in-top-5 vs absent), confidence-reliability curve, MAE, and per-genre error-type composition.
- Given a triplet relationship (1.5×), when classified, then the category is `threeHalf` and never `double` or `other`.
- Given the default pipeline unchanged, when `make benchmark` + `make benchmark-giantsteps` run, then the OA300 and GiantSteps floors reproduce exactly (reporting-only change).
- Given the standard build, when `make fmt`/`make lint`/`make test` run, then all are green and `AccuracyForensicsTests` is skipped without the env var.

## Design Notes

Per-genre error-type composition lives in the new `AccuracyForensics` report struct, NOT by mutating `GenreBucket` (its `acc1≤acc2≤total` preconditions are locked and orthogonal). `GenreAccuracyReporter` is left byte-stable.

Label-policy tagger v1 is a coarse heuristic: DAW-oracle (Bitwig-verified) tracks → `metronomic-label`; a failure whose detected BPM is a clean 2×/0.5× of a crowdsourced-corpus truth in a genre with known perceptual-tempo ambiguity → `perceptual-label-suspect`; else `ambiguous`. The tag is advisory metadata in the JSON, never a gate.

Recall oracle reads the post-merge `AudioAnalysisResult.candidates` (the set feeding final selection). "Matched factor" reuses the same five factors as `isAcc2Match` plus 3:2 / 2:3.

## Verification

**Commands:**
- `make accuracy-forensics` -- expected: writes `_bmad-output/implementation-artifacts/accuracy-forensics-*.json` with all six forensic sections per corpus.
- `make benchmark` && `make benchmark-giantsteps` -- expected: OA300 58/82·74/82, GiantSteps 537/661·546/661 unchanged.
- `make test` -- expected: green; forensic suite skipped (no env var). `make fmt` clean; `make lint` baseline only.

## Completion Notes

Implemented + verified 2026-06-27 (branch `rterhaar/accuracy-forensics`). `make accuracy-forensics` reproduces BOTH committed floors exactly — OA300 Acc1 58/Acc2 74, GiantSteps Acc1 537/Acc2 546 (a dual-truth `tempo2` fix was needed for GiantSteps to match the canonical `mirexHit`). `make fmt` clean, `make test` 719 pass (forensic suite env-gated, skipped), `make lint` 1/0-serious (LUFSAnalyzer TODO baseline). No `Sources/BoomBoomBoomKit/` DSP touched.

**First forensic read (this IS the Phase 0.5 input):**
- **OA300** (24 misses): error types double 11 + half 5 = **16 octave**, twoThird 2 (triplet), other 6. Recall split: **21/24 selection-bound** (true BPM in top-5), only 3 generation-bound, **17/24 with the correct tempo at candidate rank 1**. → The OA300 bottleneck is octave/**selection**, not candidate generation (the old `TODO.md:12` "11/30 absent" has clearly improved). Octave-resolver tuning / beat-grid rescoring is the indicated Phase 1 lever.
- **GiantSteps** (124 misses): error types **other 98** (genuine wrong-tempo), triplet 19, octave 7. Recall split: 104/124 selection-bound, 20 absent, 59 at rank 1. Octave is nearly solved here; the residual is non-harmonic wrong-tempo. Confidence reliability is cleanly monotonic (0.5→70%, 0.8→91%, 0.9→94%) — DSP confidence is meaningful on GiantSteps.
- Net: Phase 1 should attack candidate **selection** (recall is good — few truly-absent); octave-specific work pays off mostly on OA300.
