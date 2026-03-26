---
title: 'Phase 2 — Protocol-Based Technique System & Ablation Framework'
slug: 'phase-2-technique-protocol-ablation'
created: '2026-03-24'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: [Swift 6.0, Accelerate/vDSP, Swift Testing]
files_to_modify: [DSPTechnique.swift (new), BPMPipelineConfiguration.swift (delete), BPMAnalyzer.swift, AnalysisIntensity.swift, AblationTests.swift, ablation-results.md (new)]
code_patterns: [stateless static methods, vDSP bulk operations, Sendable structs, CaseIterable enum + Set composition]
test_patterns: [Swift Testing '@Suite/@Test/#expect/#require', env-gated OA300 benchmark, automated 2^N ablation matrix]
---

# Tech-Spec: Phase 2 — Protocol-Based Technique System & Ablation Framework

**Created:** 2026-03-24

## Overview

### Problem Statement

The current boolean-flag approach in `BPMPipelineConfiguration` doesn't support composable technique groups, automated ablation enumeration, or future ML integration. Ablation data (2026-03-24) reveals the current `.default` intensity (all techniques) is **4 tracks WORSE** than baseline — the compound effect of techniques degrades accuracy. Only ACF sharpening empirically helps (+2 tracks).

### Solution

Replace `BPMPipelineConfiguration` with a hybrid type system: `DSPTechnique` enum + `TechniqueSet` composition + `MLTechnique` protocol extension point. Update intensity mapping based on empirical ablation data. Run full 64-combination ablation matrix to validate.

### Ablation Data (Empirical Baseline)

| Configuration | Acc1 | vs Baseline |
|---------------|------|:-----------:|
| **sharp** | **67.1%** | **+2** |
| **sharp+norm** | **67.1%** | **+2** |
| sharp+top5 | 65.9% | +1 |
| **baseline** | 64.6% | — |
| norm | 64.6% | 0 |
| thresh | 62.2% | -2 |
| top5 | 61.0% | -3 |
| **all (current default)** | **59.8%** | **-4** |

### Scope

**In Scope:**
- `DSPTechnique` enum (6 cases, `CaseIterable`, `Hashable`, `Sendable`)
- `TechniqueSet` struct (composition, presets, `allDSPCombinations()`)
- `MLTechnique` protocol (extension point, no conformances)
- Replace `BPMPipelineConfiguration` with `TechniqueSet`
- Update `AnalysisIntensity` mapping based on ablation data
- Full 64-combination ablation matrix
- Commit ablation results as permanent reference
- Update CLAUDE.md, TODO.md

**Out of Scope:** CoreML conformances, core pipeline decomposition, ratio-aware disambiguation, combined BPM+LUFS API

## Architecture Decisions

### ADR-1: Hybrid Type Design (Path C)
DSP techniques as closed `CaseIterable` enum (free 2^N enumeration, `Set` semantics). ML techniques as open protocol (configurable, extensible). Sharp boundary: DSP modifies pipeline stages, ML evaluates candidates post-pipeline.

### ADR-2: Revised Intensity Mapping
Based on ablation data. Removed `adaptiveThreshold` (hurts -2) and `expandedCandidates` (hurts -3) from all levels. `.default` uses only empirically validated techniques.

| Intensity | Techniques | Candidates | Progressive |
|-----------|-----------|-----------|-------------|
| 1 | _(none)_ | 1 | No |
| 2 | voting, fineGrid | 3 | No |
| 3 | **sharp**, voting, fineGrid | 3 | No |
| 4 | sharp, norm, voting, fineGrid | 3 | No |
| 5 | sharp, norm, voting, fineGrid | 3 | No |
| 6 | sharp, norm, voting, fineGrid | 3 | 30→60s |
| 7 (default) | sharp, norm, voting, fineGrid | 3 | 30→60→90s |

Levels 4-5 are identical DSP to 7 (only progressive retry differs at 6+). This follows `UILayoutPriority` pattern — consecutive levels with identical behavior are acceptable when the contract is ordinal.

### ADR-3: Presets Validated by Data
- **baseline** — voting + fineGrid, count=3. Acc1=64.6%.
- **optimal** — sharp + voting + fineGrid, count=3. Acc1=67.1%. New `.default`.
- **full** — all 6, count=5. Acc1=59.8%. Kept for completeness, NOT default.
- **dnbOptimized** — sharp + norm + voting + fineGrid, count=3. Acc1=67.1%.

## Implementation Plan

### Tasks

- [ ] **Task 1: Create `DSPTechnique.swift`**
  - File: `Sources/BoomBoomBoomKit/DSPTechnique.swift` (new)
  - Action: Create three types in one file:
    1. `DSPTechnique` enum — 6 cases: `acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`, `subBandVoting`. Conform to `String`, `CaseIterable`, `Sendable`, `Hashable`.
    2. `TechniqueSet` struct — `var dspTechniques: Set<DSPTechnique>`, `var candidateCount: Int`. Conform to `Sendable`, `Hashable`. Methods: `contains(_:)`, `inserting(_:)`, `removing(_:)`. Static `allDSPCombinations() -> [TechniqueSet]` generating 2^6=64 combinations (power set). `candidateCount` = 5 when set contains `.expandedCandidates`, else 3. Computed `label: String` joining technique short names with "+". Named presets: `.baseline`, `.optimal`, `.full`, `.dnbOptimized`.
    3. `MLTechnique` protocol — `var name: String { get }`, `func evaluate(candidates:trace:) -> (bpm: Double, confidence: Double)?`. Takes `BPMDiagnosticTrace` instead of raw samples to avoid duplicating DSP computation inside the ML model. Pipeline enables trace internally when ML technique is present. Sendable. Definition only.

- [ ] **Task 2: Update `AnalysisIntensity` to use `TechniqueSet`**
  - File: `Sources/BoomBoomBoomKit/AnalysisIntensity.swift`
  - Action: Add `public var techniqueSet: TechniqueSet` computed property that builds a `TechniqueSet` from `rawValue` thresholds per ADR-2. Remove the 6 individual `use*` Bool computed properties and `candidateCount` — these are now derived from `techniqueSet`. Keep `windowSizes` and `progressiveThreshold` on `AnalysisIntensity` (they control `AudioAnalysisService` loop, not pipeline stages).

- [ ] **Task 3: Refactor `BPMAnalyzer` to use `TechniqueSet`**
  - File: `Sources/BoomBoomBoomKit/BPMAnalyzer.swift`
  - Action:
    1. Replace the `config: BPMPipelineConfiguration` overload (lines ~122-129) with:
       ```swift
       static func estimateBPM(
           samples: [Float], sampleRate: Double,
           analysisWindowSeconds: Double = defaultAnalysisWindowSeconds,
           techniques: TechniqueSet,
           enableTrace: Bool = false
       ) -> BPMResult?
       ```
    2. Update the `intensity:` overload to call the new one: `let techniques = intensity.techniqueSet`
    3. Replace all 9 `config.use*` references with `techniques.contains(.)`:
       - `config.useSubBandVoting` → `techniques.contains(.subBandVoting)`
       - `config.useSubBandNormalization` → `techniques.contains(.subBandNormalization)`
       - `config.useAdaptiveThreshold` → `techniques.contains(.adaptiveThreshold)`
       - `config.useACFSharpening` → `techniques.contains(.acfSharpening)`
       - `config.useFineGridRefinement` → `techniques.contains(.fineGridRefinement)`
       - `config.candidateCount` → `techniques.candidateCount`
    4. Keep `computeSubBands:` parameter gated by `techniques.contains(.subBandVoting)`
    5. Keep `normalizeSubBands:` parameter gated by `techniques.contains(.subBandNormalization)`

- [ ] **Task 4: Delete `BPMPipelineConfiguration.swift`**
  - File: `Sources/BoomBoomBoomKit/BPMPipelineConfiguration.swift`
  - Action: Delete file. All references replaced by `TechniqueSet` in Tasks 2-3.

- [ ] **Task 5: Refactor `AblationTests` to use `TechniqueSet`**
  - File: `Tests/BoomBoomBoomKitTests/AblationTests.swift`
  - Action:
    1. Replace `BPMPipelineConfiguration` references with `TechniqueSet`
    2. Replace technique mutation closures with `TechniqueSet.baseline.inserting(.acfSharpening)` pattern
    3. Replace `fullAblationMatrix` to use `TechniqueSet.allDSPCombinations()` for automated 64-combo generation
    4. Replace `runCorpusFromDisk(config:)` signature with `runCorpusFromDisk(techniques:)`
    5. Call `BPMAnalyzer.estimateBPM(techniques:)` instead of `estimateBPM(config:)`
    6. Add `perTrackImpact` test using the same `TechniqueSet` API
    7. All string formatting must use Swift interpolation — no `%s` format specifiers
    8. Two ablation modes: **Quick** (always runs, named presets vs bundled click tracks, <1s) and **Full** (env-gated, all 64 combos vs OA300, ~9 min)

- [ ] **Task 6: Run full 64-combination ablation matrix**
  - File: `_bmad-output/ablation-results.md` (new)
  - Action: Run `OA300_CORPUS_PATH=... make benchmark` (which now includes ablation). Capture the full 64-combo results table. Commit as permanent reference. Identify the empirically best combination. Verify it matches the `.optimal` preset assumption (sharp + voting + fineGrid).
  - Notes: ~10 minutes runtime. If the best combo differs from the current `.optimal` preset, update the preset definition and intensity mapping.

- [ ] **Task 7: Update docs**
  - File: `CLAUDE.md`, `TODO.md`
  - Action: Update CLAUDE.md key types to reference `DSPTechnique`, `TechniqueSet`, `MLTechnique`. Remove `BPMPipelineConfiguration` mention. Note revised intensity mapping. Update TODO.md with Phase 2 completion status and ablation results summary.

### Acceptance Criteria

- [ ] **AC 1:** `DSPTechnique.allCases.count` == 6 and all cases are `CaseIterable`, `Hashable`, `Sendable`.
- [ ] **AC 2:** `TechniqueSet.allDSPCombinations().count` == 64 (2^6 power set).
- [ ] **AC 3:** `TechniqueSet.optimal.contains(.acfSharpening)` is true, `.contains(.adaptiveThreshold)` is false.
- [ ] **AC 4:** `TechniqueSet.baseline.candidateCount` == 3, `TechniqueSet.full.candidateCount` == 5.
- [ ] **AC 5:** `AnalysisIntensity.default.techniqueSet` == `TechniqueSet.optimal` (or equivalent set contents).
- [ ] **AC 6:** `AnalysisIntensity(rawValue: 1).techniqueSet.dspTechniques.isEmpty` is true.
- [ ] **AC 7:** `BPMAnalyzer.estimateBPM(samples:sampleRate:techniques:)` produces identical results to `estimateBPM(samples:sampleRate:intensity:)` when `techniques == intensity.techniqueSet`.
- [ ] **AC 8:** All 103 existing tests pass without modification (except AblationTests).
- [ ] **AC 9:** Full 64-combination ablation matrix completes against OA300 without crashes, producing Acc1/Acc2 for each combination.
- [ ] **AC 10:** `TechniqueSet.label` produces human-readable string (e.g., "sharp+vote+fine").
- [ ] **AC 11:** `MLTechnique` protocol compiles and can be conformed to (verified by a no-op test conformance in tests).
- [ ] **AC 12:** `BPMPipelineConfiguration.swift` no longer exists in the project.

## Additional Context

### Dependencies
No external deps. Task order: 1 (types) → 2 (intensity) → 3 (analyzer) → 4 (delete old) → 5 (tests) → 6 (run matrix) → 7 (docs). Tasks 1-4 are sequential. Task 5 depends on 3. Task 6 depends on 5. Task 7 is last.

### Notes

**Risks:**
- Full 64-combo matrix may reveal that the partial ablation data (pairs only) was misleading — triples could behave differently. Run full matrix before committing to intensity mapping.
- Removing `adaptiveThreshold` and `expandedCandidates` from default improves OA300 Acc1 but these techniques may help on non-DnB corpora. Document this as a known limitation.

**Limitations:**
- OA300 is DnB-heavy. The "optimal" preset is tuned for this corpus.
- `MLTechnique` is definition-only — no conformances until Phase 3.
- Techniques not in `.optimal` are still available via explicit `TechniqueSet` construction — they're not deleted, just not in the default path.
- `adaptiveThreshold` and `expandedCandidates` implementations remain in `BPMAnalyzer.swift` — they're gated by technique set membership, not removed. Future work on different corpora may rehabilitate them.

**Required follow-up (before shipping `.optimal` as production default to MetaMan):**
- **Corpus expansion** — OA300 is DnB-heavy. The "optimal" preset is validated against breakbeat music only. Before making this the production default in MetaMan, add 20-30 tracks covering house/techno (126-132 BPM), hip-hop (80-100 BPM), pop/rock (100-140 BPM), and ambient/downtempo (60-80 BPM). Run full ablation matrix against expanded corpus. The optimal preset may differ by genre — which is exactly why `TechniqueSet` presets exist.
- **Commit existing crash fix** — The `%s` format specifier fix and formatter changes from the investigation agent need to be committed before Phase 2 implementation begins, to keep the diff clean.

**Phase 3:** CoreML/BNNS `MLTechnique` conformances, genre-aware presets, ratio-aware disambiguation, expanded corpus testing.
