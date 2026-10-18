# Rekordbox-informed guidance for BoomBoomBoomKit

Investigation date: 2026-10-17. Scope: offline analysis of DJ music, prioritizing correct musical tempo, stable constant-tempo grids, and reliable 4/4 bar starts. Accuracy takes priority over speed. No source-repository changes were made.

## Findings that change the next steps

1. **An absolute timing discrepancy is demonstrated in the current Swift implementation.** Twelve synthetic click fixtures, each measured through the public grid facade and a known-tempo frontend/tracker path, produce canonical grid anchors approximately 39.98–50.00 ms early. Supplying the exact tempo reproduces it. Correct BPM and low long-track drift therefore do not establish correct grid phase. This is synthetic signal evidence, not a claim that all musical beats should align to a transient's first sample.
2. **The current model input varies its time scale.** BNNSTechnique normalizes each mel band and resamples a variable-duration segment to 512 frames. The underlying MLFeatureFrames already preserves fixed-hop frames; this resizing is a particular model contract, not an unavoidable feature-substrate constraint. A fixed-time alternative requires matching training and runtime changes, not an inference-only patch.
3. **Rekordbox's high-precision path is hybrid.** It requires an existing legacy beat result, calls learned beat/downbeat analysis, then calls legacy v2 focus analysis. It is not simply a track-level BPM classifier.
4. **The learned representation and sequence decoder are important.** The shipped models provide framewise observations. The native decoder jointly models bar position and tempo rather than asking a fixed-period tracker to repair an already-final tempo.

## Shipped artifact evidence

Target: `/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox`, version 7.2.19.0342, ARM64 slice of universal Mach-O. Original executable SHA-256: `07dcecbaf304f777e435539c83c7dcc02e41de1eaf2e0a75e8a9852e4411a244`.

The completed licensed Hopper database is preserved locally at `artifacts/rekordbox-bpm-analysis.hop` (gitignored, approximately 386 MB). Hopper confirmed that database path and `backgroundProcessActive() == False`.

REA's macOS launcher rejected saved-database targets, so focused queries used the installed REA Hopper adapter's dispatch functions from Hopper's supported Python console. This reused the loaded document without a new import. JSON evidence records explicitly identify this route; they are **not MCP Evidence envelopes**. IDs beginning `local-hopper-` are local report identifiers.

| Conclusion | Evidence |
|---|---|
| Mode dispatch distinguishes legacy/high-precision analysis | `evidence/hopper/detect.json`; native instructions in `evidence/native/rekordbox-detect.asm`. The assembly's subtract-and-unsigned-compare establishes enum values 2–4; the decompiler's simplified condition is incomplete. |
| High precision uses legacy BPM/beat count, calls `madmom::analyze`, then `BALibWrapper::CalcBeatPos_Focus` and focus getters | `evidence/hopper/high-precision.json`, entry `0x102327e50`; native call at `0x10232803c`, focus call at `0x1023282a8`. |
| TensorFlow model inference feeds `madmom::downbeat_tracking` | `evidence/hopper/learned-analyze.json`, entry `0x102307f8c`; native assembly `evidence/native/rb-beat-1.asm`. |
| Bar-state HMM with Viterbi decoding, thresholding, and peak correction | `evidence/hopper/downbeat-tracking.json`, entry `0x102300d6c`; independently retained native assembly `evidence/native/rb-beat-0.asm`. |
| Observation columns mean ordinary beat and downbeat | `evidence/hopper/observation-likelihoods.json` and `evidence/hopper/observation-state-space.json`; native `evidence/native/rb-focus-2.asm` and `evidence/native/rb-observation-constructor.asm`. The nonbeat probability comes from the remaining mass. |
| Legacy focus processing depends on constant/dynamic-tempo mode | `evidence/native/rb-analyze-focus.asm`, mode field `+0x2d`; wrapper files `evidence/native/rb-focus-0.asm`, `evidence/native/rb-focus-1.asm`. |
| Final focus BPM rounds to hundredths | `evidence/hopper/bpm-focus.json`, entry `0x1011820d4`, corroborated by native instructions. Resolution is not proof of accuracy. |

Paths in this table are relative to this document (`docs/rekordbox-analysis/`). The original artifacts lived under `/private/tmp`; `manifest.json` records every original source path alongside its SHA-256.

Resources `Contents/Resources/models/detect_beat/model7/` and `model8/` contain two distinct TensorFlow SavedModels. Static protobuf inspection establishes the same 99,003-parameter recurrent architecture: three bidirectional peephole-LSTM layers, 25 units per direction, first recurrent input width 314, followed by a 50-to-3 softmax. The serving graph retains softmax columns 1 and 2. Its frontend contains three STFT paths (1024/2048/4096 samples, hop 441) plus filtered/log spectral processing. The native decoder receives an explicit 100 fps parameter. This is consistent with the published 44.1 kHz frontend; the full native resampling contract still needs tracing before reproducing it.

Model inspection: `scripts/rekordbox-model-inspect.py`, `evidence/models/model-inspection.txt`, `evidence/models/stft-graph.txt`. Model7 protobuf SHA-256: `ea7b5e7c3567525bb9b0eff1238c13b9d4ab8336399e0f2dd3301528a9dc936a`; model8: `09baf025fb561d27264a6f26522e12037fd2f37bf1db378c7edf9366116c49dd`.

The architecture closely matches the independently published [Joint Beat and Downbeat Tracking with Recurrent Neural Networks](https://archives.ismir.net/ismir2016/paper/000186.pdf). The public [madmom implementation](https://github.com/CPJKU/madmom/blob/main/madmom/features/downbeats.py) documents fixed-time spectral features, framewise beat/downbeat observations, and a bar-state decoder. This establishes a useful published reference; it does not establish the provenance of rekordbox's weights or its training set.

## Current Swift evidence

Source checkout: `/Users/rterhaar/Dropbox/research/swift/BoomBoomBoomKit`, branch `rterhaar/12-7-eval-corpus-harness`, tracked HEAD `0f90ed8de52a9626cd47d3a263bed5af90a6c80e`. Untracked `addendum-design.md` was preserved.

### Absolute phase probe

A temporary SPM package built from that HEAD produced the probe sources preserved here as `evidence/timing/ProbePackage.swift` and `evidence/timing/TimingProbeTests.swift` (originally `boomboom-timing-probe/Package.swift` and `boomboom-timing-probe/ProbeTests/TimingProbeTests.swift`). It tests 12-second, 120 BPM signals at 44.1/48 kHz, three positions within an onset hop, and impulses versus short exponential decays. Both known-tempo and public facade paths are measured against independently specified impulse times; interior beats and canonical anchors are scored without removing a constant offset.

The public path estimated approximately 120.00007 BPM and returned 24 beats per fixture. Grid confidence was about 0.909–0.937, despite the early anchors. Across all variants, canonical-anchor and interior median errors were about -39.98 to -50.00 ms. Variation across waveform/phase means a universal +50 ms patch is not justified.

One Swift test passed and emitted 24 path/fixture measurements. This test is an investigation probe, not a newly installed regression test. Results: `evidence/timing/results.json`; source: `evidence/timing/TimingProbeTests.swift` (SPM manifest at `evidence/timing/ProbePackage.swift`); log: `evidence/timing/swift-test.log`.

Relevant source: BPMAnalyzer.swift:1181 (left-aligned unpadded STFT), :916 (spectral difference frame i stored at i-1); BeatGridAnalyzer.swift:330 (direct frame-to-time conversion). BeatGridAnalyzerTests.swift:846 permits absolute offsets up to approximately 100 ms. Existing drift tests cancel constant offsets. These explain why current green tests do not establish tight absolute phase, but do not by themselves identify a universal correction formula.

### ML and grid design

BNNSTechnique.swift:537 implements the whole-segment-to-512-frame input transform. MLTechnique.swift:143 returns one scalar MLEvaluation after tempo selection; it cannot carry timed observations. The reserved SignalSource.beatGrid and SignalWeights.beatGrid do not currently produce an independent vote. Combined analysis computes BPM first, then derives its grid. Feeding that grid's confidence back into the same BPM result would be circular evidence.

BeatGridAnalyzer.swift:49 explicitly implements constant tempo, appropriate for the main DJ use case. Its optional comb refinement maximizes support over phase but returns only tempo, then selects the grid origin from earlier observations. Returning and evaluating a fitted tempo/phase pair is a candidate experiment, not a demonstrated fix.

The raw feature version is v2. BNNSTechnique.swift:211 aliases the producer's current version constant, so changing that constant alone does not independently validate an old weights file's training contract. New models should pin frontend, timing, normalization, windowing, and output semantics explicitly.

### Recorded model comparison, independently rescored

The saved GiantSteps predictions contain matching sets of 661 track IDs. At 4% strict tolerance, v2 has 348 hits, 53 octave-recoverable misses, and 260 other misses; the reference tempo-CNN has 545 hits, 100 octave-recoverable misses, and 16 other misses. This reproduces `12-5-pipeline-differential.md`. It is a rescore of historical predictions, not new inference, not a Rekordbox comparison, and not the current combined DSP/metadata/ML product accuracy.

## Recommended order for a DJ library

1. **Make absolute grid timing a first-class check.** Establish and test the frontend's frame-time convention, including spectral differencing and padding. Use known signals at multiple phases, sample rates, BPMs, and waveform shapes; follow with DJ kick/breakbeat excerpts. Measure the actual playable anchor, absolute phase, and drift separately. Avoid a magic constant offset.
2. **Run a fixed-time model-input ablation before another major retrain.** Keep seconds per frame fixed, use fixed-duration crops, match training/inference preprocessing, and aggregate evidence across crops. Version this separately from the existing weights. The recorded 260 non-octave misses make this a higher priority than more octave rules.
3. **Prototype a separate beat/downbeat observation model and a 4/4 structured decoder.** Use a compact published architecture as an experimental reference; retain DSP as baseline/fallback. Let the decoder compare plausible tempo levels before locking a constant grid. Keep the observation-model interface internal initially, carrying frame timing and model/frontend identity. Preserve the scalar MLTechnique API.
4. **Refine a constant-tempo DJ grid over a useful span.** Evaluate tempo and phase together; validate at separated regions and through breaks. Compare low-frequency evidence with full-band evidence on syncopated music. Treat silence and weak passages as missing evidence, not reasons to force a new phase. Preserve the distinction between observations and the final regular grid.
5. **Get more value from annotation already underway.** The current SOP already anchors a DAW grid at a stable downbeat and locks at least 32 beats. Retain the original-audio time of that downbeat, metrical level, verified span, and a distant check where available. The current extractor emits tempo, not a complete phase reference. Add supplementary annotations without changing the committed evaluation membership or exposing blinded labels. Keep training and evaluation recordings separate. Do not extrapolate training beat labels beyond a verified stable span without checking it.

For evaluation, separate musical tempo-level mistakes, precise rate error, absolute phase error, bar-start errors, and long-span drift. Compare BoomBoomBoomKit and a named Rekordbox analysis mode on the same audio against independent annotations; record per-track differences, failure/abstain counts, runtime, and memory. Existing Rekordbox-derived beat references measure agreement with Rekordbox, not which system is right. Keep the tempo-CNN baseline as an additional reference, not as a claimed Rekordbox result.

## Boundaries and remaining unknowns

No proprietary application audio-analysis run or matched Rekordbox accuracy/speed benchmark was performed. Current Rekordbox UI mode, model7/model8 selection details, training data, and complete resampling behavior remain unresolved. Legacy focus analysis is large and uses floating-point/SIMD code that Hopper represents imperfectly; exact optimization objectives and thresholds are not established by the pseudocode. Do not infer least squares, sample accuracy, or perceptual superiority merely from function names or output precision.

The evidence supports concrete experiments and a measured timing investigation; it does not yet demonstrate parity with Rekordbox.
