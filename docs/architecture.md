# BoomBoomBoomKit - Architecture

## Executive Summary

BoomBoomBoomKit is a stateless DSP library for BPM estimation and LUFS loudness measurement. All types are value types (structs/enums) with static methods. Zero external dependencies -- only Apple system frameworks.

## Architecture Pattern

**Stateless pipeline with public facade.** No classes, no lifecycle, no dependency injection.

```
Consumer
  │
  ▼
AudioAnalysisService (public facade)
  ├── Options (intensity, merge strategy, cancellation, progress)
  ├── analyzeBPM(url:options:) → AudioAnalysisResult?
  │     ├── PCMBufferReader.readMonoSamples() → [Float]
  │     ├── for window in intensity.windowSizes:
  │     │     ├── isCancelled? → throw CancellationError
  │     │     ├── onProgress?(windowsCompleted, windowsTotal)
  │     │     └── BPMAnalyzer.estimateBPM() → BPMResult?
  │     └── CandidateMergeStrategy.merge(windowResults)
  │
  └── analyzeLUFS(url:) → Double?
        ├── PCMBufferReader.readMonoSamples()
        └── LUFSAnalyzer.measureLoudness()
```

## Type Architecture

### Public Types

| Type | Kind | Purpose |
|------|------|---------|
| `AudioAnalysisService` | struct (static methods) | Public facade for all analysis |
| `AudioAnalysisService.Options` | struct (Sendable) | Configuration: intensity, merge, cancellation, progress |
| `AnalysisIntensity` | struct (1-10) | Controls pipeline depth via TechniqueSet |
| `CandidateMergeStrategy` | enum (8 cases) | How multi-window candidates are combined |
| `DSPTechnique` | enum (6 cases) | Individual DSP technique flags |
| `TechniqueSet` | struct | Composable set of DSPTechniques with named presets |
| `PCMBufferReader` | struct (static methods) | Audio file I/O to mono [Float] |
| `BPMDiagnosticTrace` | struct | Per-step pipeline intermediate state |
| `ProgressUpdate` | struct (Sendable) | windowsCompleted + windowsTotal |
| `MLTechnique` | protocol | Future CoreML integration hook |

### Internal Types

| Type | Kind | Purpose |
|------|------|---------|
| `BPMAnalyzer` | struct (static methods) | 10-step DSP pipeline |
| `BPMResult` | struct | bpm + confidence + candidates |
| `LUFSAnalyzer` | struct (static methods) | ITU-R BS.1770-5 K-weighted loudness |
| `LUFSResult` | struct | integratedLoudness |
| `MelFilterbank` | enum (no cases) | Hz/mel conversion + filterbank matrix |
| `PipelineBuffers` | struct | Hann window + windowed onset (per-estimateBPM) |
| `ACFBuffers` | struct | 8 split-complex pointers for autocorrelation |
| `TempogramBuffers` | struct | cos/sin/phase pointers for Fourier tempogram |

## BPM Pipeline (10 Steps)

1. **Energy scan** -- find first significant energy transition
2. **Silence check** -- RMS threshold
3. **Mel-spectrogram onset** -- STFT + mel filterbank + log + diff + rectify (technique-gated)
4. **Adaptive thresholding** -- dynamic onset threshold (technique-gated)
5. **Autocorrelation** -- FFT-based, full-band + 4 sub-bands (technique-gated)
6. **Fourier tempogram** -- non-uniform DFT at integer BPMs
7. **Periodicity fusion** -- ACF x tempogram element-wise multiply
8. **Peak selection** -- top candidates from enhanced periodicity
9. **Range normalization** -- fold into 60-200 BPM
10. **Sub-band voting + fine-grid refinement** -- octave disambiguation + 0.1 BPM precision (technique-gated)

Steps 3/4/5/10 are gated by `TechniqueSet`. New DSP stages must identify where they fit.

## Architectural Decisions (ADRs)

| ADR | Decision | Rationale |
|-----|----------|-----------|
| ADR-1 | Cancellation between windows only | BPMAnalyzer stays stateless; per-window is sub-second |
| ADR-2 | Progress via @Sendable callback | Per-track granularity, not per-pipeline-stage |
| ADR-3 | Internal buffer management | allocate/deallocate/defer pattern for heap buffers |
| ADR-4 | Eager ML model loading at init | Future: CoreMLTechnique()/BNNSTechnique() |
| ADR-5 | Configurable ML ensemble voting | Future: DSP wins unless ML confidence high |
| ADR-6 | Always populate trace when ML present | Future: trace built internally for MLTechnique input |
| ADR-7 | Harmonic ratio detection in step 10 | Future: 3:2 and 3:1 ratio checks |
| ADR-8 | Click-track cross-correlation as DSPTechnique | Future: ablation grows to 2^7=128 |
| ADR-9 | GiantSteps as separate test suite | GIANTSTEPS_CORPUS_PATH env var |
| ADR-10 | Dual tolerance (2% and 4%) | Separate test methods per tolerance |

## Accuracy Baselines

| Corpus | Tracks | Acc1 | Acc2 | Notes |
|--------|--------|------|------|-------|
| OA300 | 82 | 69.5% | 89.0% | Rekordbox ground truth, DnB-heavy |
| GiantSteps | 664 | 70.0% | 79.1% | Crowdsourced ground truth v2, EDM genres |

## Development Roadmap

5 epics planned:
1. **Pipeline Performance & Cooperative Analysis** -- Done (buffer reuse, cancellation, progress)
2. **Measurement & Validation Infrastructure** -- Next (dual tolerance, performance benchmarks, corpus expansion)
3. **DSP Accuracy Improvement** -- Harmonic ratios, fine-grid fix, click-track correlation
4. **ML-Augmented Detection** -- BoomBoomBoomKitML package, BNNS + CoreML
5. **Developer Experience & Demo** -- Demo app, documentation, quick-start guides
