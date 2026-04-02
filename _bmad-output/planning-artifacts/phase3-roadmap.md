---
source: party-mode discussion (2026-03-29)
participants: Winston (Architect), Amelia (Developer), Siri (Apple Platform Expert), Mary (Analyst)
validated_with: axiom-swift-performance, axiom-avfoundation-ref, apple-docs-mcp
---

# Phase 3 Roadmap: Performance + Accuracy

## Current Baselines

- **Acc1:** 69.5% (57/82 tracks on OA300, Rekordbox ground truth)
- **Acc2:** 89.0% (73/82)
- **Corpus:** 82 tracks, DnB-heavy
- **Default config:** intensity 7, `.optimal` (sharp+vote+fine), `maxConfidence` merge, 3 windows (30/60/90s)
- **Pipeline:** 10-step DSP, 6 ablation-validated techniques, 8 merge strategies

## Error Breakdown (from ablation + DAW oracle)

| Category | Est. % of misses | Root cause |
|----------|-----------------|------------|
| Octave errors | ~11% | Detecting 2x or 0.5x correct BPM |
| Triplet errors | ~5% | Detecting 1.5x or 0.67x (common in DnB, jazz) |
| Other | ~14.5% | Polyrhythmic, tempo-varying, extreme tempos |

## Phase 3A: Wall-Clock Performance (no accuracy change)

| Item | Expected Impact | Effort | Notes |
|------|----------------|--------|-------|
| Downsample to 22.05kHz at read time | -40-50% wall time | Small | BPM detection doesn't need >10kHz. Use `targetSampleRate: 22050` in PCMBufferReader. Mel filterbank concentrates energy below 8kHz already |
| Buffer pool (pre-allocate scratch arrays) | -10-15% allocations | Medium | 24 scratch buffer allocations in BPMAnalyzer, many same size. Pre-allocate once, reuse across pipeline steps |
| FFT plan reuse | -5% in mel-spectrogram loop | Small | Create vDSP.FFT plan once, reuse across frames instead of implicit per-call creation |

## Phase 3B: Accuracy -- DSP Techniques (intensity 3-7)

| Item | Expected Impact | Effort | Notes |
|------|----------------|--------|-------|
| Harmonic ratio detection (new DSPTechnique) | +3-5% Acc1 | Medium | After periodicity fusion, check if candidate ratios are 3:2 or 2:3. Prefer candidate in 80-160 BPM comfort zone. Directly targets triplet errors. From brainstorm #4 |
| Confidence-weighted window voting | +1-2% Acc1 | Small | Improve `windowVoting` merge strategy -- use confidence-weighted vote instead of simple majority. Currently falls back to maxConfidence |
| Segmented analysis (4 segments, median) | +2-3% Acc1 on variable-tempo | Medium | Analyze 4 non-overlapping segments, take median BPM. Targets tempo-varying content |
| Click-track cross-correlation | +1-2% Acc1 | Medium | For each candidate, generate synthetic click track and cross-correlate with onset envelope. Best-aligning candidate wins. From brainstorm #62 |
| Duration-derived BPM hint | +1% Acc1 | Small | Auto-read duration from AVFoundation metadata, compute structurally plausible BPMs from common bar counts. From brainstorm #35 |
| Expand DAW oracle coverage | Enables accurate measurement | Manual | DAW-verify every track where we and Rekordbox disagree |

## Phase 3C: ML Integration (intensity 8-10)

| Item | Expected Impact | Effort | Notes |
|------|----------------|--------|-------|
| Octave classifier (CoreML or BNNS) | +5-8% Acc1 | Large | Train on BPMDiagnosticTrace features (sub-band energies, ACF shape, periodicity peaks). Input: ~20 floats. Output: {half, keep, double}. BNNS lives inside Accelerate (zero new deps) |
| MLTechnique protocol conformance | Architecture only | Medium | First real conformance to the existing MLTechnique protocol |
| BoomBoomBoomKitML package split | Clean separation | Medium | Optional resource bundle. DSP-only (1-7) vs ML-enabled (8-10). From brainstorm #54 |
| Ablation with ML + DSP combinations | Validation | Medium | Verify ML + DSP is strictly additive (monotonic accuracy) |

## Phase 3D: Measurement Infrastructure

| Item | Expected Impact | Effort | Notes |
|------|----------------|--------|-------|
| DAW oracle expansion (100+ tracks) | Enables "vs truth" metric | Manual | Need DAW verification on all disputed tracks |
| Genre-stratified accuracy reporting | Find genre-specific weaknesses | Medium | Corpus is DnB-heavy. Need House, Hip-Hop, Pop, Rock coverage |
| Wall-clock benchmarks in CI | Prevent perf regressions | Small | Track analysis time per track alongside accuracy |
| Acc1-vs-DAW as primary metric | Correct success definition | Small | Rekordbox is wrong on some tracks. DAW oracle is truth |

## Key Architectural Decisions

1. **"Surpassing Rekordbox" means:** matching Rekordbox where it's correct AND beating it where the DAW oracle proves it wrong
2. **ML is additive:** intensity 8+ runs DSP + ML, never ML alone (monotonic accuracy guarantee)
3. **BNNS over CoreML initially:** lives inside Accelerate, zero new framework dependencies
4. **Merge strategies need post-disambiguation rethinking:** current strategies merge pre-disambiguation candidates. To beat maxConfidence, merge the final BPM from each window (after disambiguation)
5. **Corpus expansion is a prerequisite** for confident "surpassing Rekordbox" claims

## Specific Issues to Address

### Fine-grid precision gap (Icicle track: 126.0 BPM detected as 125.9)
The fine-grid refinement step scans ±0.5 BPM around each candidate in 0.1 BPM steps. The Icicle track from the DAW oracle set has a verified BPM of 126.0 but we detect 125.9 -- a 0.1 BPM error that falls just outside our 2% Acc1 tolerance at some BPMs but reveals a systematic rounding/interpolation issue. Investigate whether:
- The parabolic interpolation in `parabolicInterpolateACF` introduces sub-BPM bias
- The fine-grid step size (0.1 BPM) creates aliasing at certain tempos
- The range normalization (60-200 BPM doubling/halving) shifts the grid off true integer BPMs
- A finer grid (0.05 BPM) or snap-to-nearest-0.5 post-processing would fix this class of error

### CoreML as parallel detection path
Evaluate CoreML (not just BNNS) as a full parallel BPM detection path alongside the existing FFT-based pipeline, not just as a tiebreaker/octave classifier. Specifically:
- Schreiber-style CNN: single-step tempo from mel-spectrogram (from brainstorm #2/#65)
- CoreML adds the CoreML framework dependency but enables Neural Engine acceleration (~10x faster inference vs CPU)
- Could run as a parallel estimator at intensity 8+: DSP produces candidates, CoreML produces candidates, quorum vote resolves
- Training data strategy: use OA300 + DAW oracle as labeled dataset, augment with genre-diverse public datasets
- Evaluate Apple's Foundation Models / SoundAnalysis framework for pre-trained audio features
- BNNS (inside Accelerate) remains the zero-new-deps option; CoreML is the performance option

## References

- Brainstorming session: `_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md` (65 ideas)
- Ablation results: `_bmad-output/ablation-results.md`
- Project context: `_bmad-output/project-context.md` (52 validated rules)
- CLAUDE.md: architecture, design constraints, current accuracy baselines
