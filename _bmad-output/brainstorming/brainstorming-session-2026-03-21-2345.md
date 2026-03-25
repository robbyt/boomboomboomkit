---
stepsCompleted: [1, 2, 3, 4]
inputDocuments: [README.md, TODO.md, _bmad-output/bpm.md]
session_topic: 'BPM detection accuracy, performance optimization, algorithm intensity control, and competitive research vs Rekordbox'
session_goals: 'Match/surpass Rekordbox accuracy, optimize wall-clock performance, expose intensity control API, research state-of-the-art BPM detection techniques, evaluate Apple ML APIs for BPM disambiguation'
selected_approach: 'ai-recommended'
techniques_used: ['cross-pollination-with-research', 'five-whys', 'constraint-mapping']
ideas_generated: 65
context_file: 'README.md, TODO.md, _bmad-output/bpm.md'
session_active: false
workflow_completed: true
---

# Brainstorming Session Results

**Facilitator:** robbyt
**Date:** 2026-03-21

## Session Overview

**Topic:** BPM detection accuracy, performance, algorithm intensity control, and competitive research vs Rekordbox
**Goals:**
1. Match/surpass Rekordbox BPM detection accuracy across diverse genres
2. Optimize wall-clock performance without sacrificing accuracy
3. Expose external API for algorithm intensity control (speed vs accuracy tradeoff)
4. Research state-of-the-art BPM detection techniques from Rekordbox, Serato, Traktor, essentia, librosa, madmom
5. Evaluate Apple ML APIs (BNNS, CoreML, SoundAnalysis, AudioFeaturePrint) for BPM disambiguation

### Context

BoomBoomBoomKit is a pure-Swift audio analysis library using Accelerate/vDSP. Current 11-step DSP pipeline with sub-band voting disambiguation. Benchmarked at 61.5% Acc1 / 80.8% Acc2 on OA300 (78 tracks, Rekordbox ground truth) and 85.7% Acc1 on Prodigy DnB (21 tracks). Core bottleneck: 11/30 OA300 failures have correct BPM absent from top 3 candidates entirely. Failure tracks are dense jungle/DnB with heavy snare rolls and complex breakbeats.

### Techniques Used

1. **Cross-Pollination with External Research** — Competitive intelligence from academic SOTA, open-source projects, Apple ML frameworks, and Rekordbox analysis
2. **Five Whys** — Root cause decomposition on the candidate generation bottleneck
3. **Constraint Mapping** — Boundaries around intensity control, hardware capabilities, binary size, latency budgets

---

## Competitive Research Findings

### Academic State-of-the-Art (2024-2025)

| Approach | Key Innovation | Status |
|----------|---------------|--------|
| TCN (Davies & Böck 2019) | Dilated convolutions over mel-spectrograms, parallelizable, small weights | Widely adopted baseline |
| BEAST (ICASSP 2024) | Streaming Transformer, +5% beat / +13% downbeat over prior SOTA | Current online SOTA |
| BeatNet (ISMIR 2021) | CRNN + particle filtering, joint beat/downbeat/tempo/meter | 80.64 F-measure on GTZAN |
| Schreiber CNN (2018) | Single-step tempo from mel-spectrogram, simulates resonant comb filters | Still widely cited |
| Dual-Path TCN+Transformer (Dec 2024) | Hybrid local+global temporal modeling | Best of both worlds |
| Self-supervised tempo (Jan 2024) | Contrastive learning on mel-spectrogram pairs without labels | Emerging approach |

### Rekordbox

- Static vs Dynamic analysis modes; High Precision mode trades speed for accuracy
- BPM range narrowing by genre (avoids octave confusion for DnB)
- Cloud fingerprint database — caches analysis results server-side for instant retrieval
- Proprietary algorithms, no published accuracy metrics

### Apple ML APIs Available (Zero External Dependencies)

| Framework | Capability | Dependency Impact |
|-----------|-----------|-------------------|
| **BNNS** (Accelerate) | Conv1D, pooling, activation, LSTM layers for inference | None — already in Accelerate |
| **Core ML** | Run .mlmodel on CPU/GPU/Neural Engine | Adds CoreML framework |
| **SoundAnalysis** | Audio classification with custom MLModel | Adds SoundAnalysis framework |
| **AudioFeaturePrint** (CreateMLComponents) | Pre-trained audio embedding extractor | Adds CreateMLComponents |
| **MLSoundClassifier** (Create ML) | Train sound classifier with AudioFeaturePrint backend | Training-time only |
| **TimeSeriesClassifier** (CreateMLComponents) | Time-series classification | Adds CreateMLComponents |

**Key insight:** BNNS lives inside Accelerate, making it possible to run neural network inference with zero new framework dependencies.

### References

- Davies & Böck (2019). "Temporal convolutional networks for musical audio beat tracking." EUSIPCO.
- Hydari et al. (2021). "BeatNet: CRNN and Particle Filtering for Online Joint Beat, Downbeat and Meter Tracking." ISMIR.
- BEAST (2024). "Online Joint Beat and Downbeat Tracking Based on Streaming Transformer." ICASSP.
- Schreiber & Müller (2018). "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network."
- Dual-Path TCN+Transformer (2024). Applied Sciences 14(24).
- tempnetic — github.com/csteinmetz1/tempnetic (MobileNetV2 tempo estimation from tempograms)

---

## Complete Idea Inventory (65 Ideas)

### Theme 1: Public API — Intensity Scale & Configuration

**#15 — Numeric Intensity Scale (1-10)** ✅ *Implemented 2026-03-24 (Phase 1) — `AnalysisIntensity` struct, levels 1-7 DSP, 8-10 reserved for ML*
Replace named presets with a numeric `AnalysisIntensity` where 1=fastest, 10=most accurate. Like zlib compression level. Universally understood, no BPM-specific jargon.

**#16 — Intensity Mapping Table**

| Intensity | Window | Candidates | Disambiguation | Fine Grid | Progressive | ML | Est. Time |
|-----------|--------|-----------|----------------|-----------|-------------|-----|-----------|
| 1 | 15s | Top 1 | None | No | No | No | ~50ms |
| 2 | 30s | Top 3 | Range normalize | No | No | No | ~100ms |
| 3 | 30s | Top 3 | Sub-band voting | No | No | No | ~150ms |
| 4 | 30s | Top 3 | Sub-band + ratio | No | No | No | ~170ms |
| 5 | 30s | Top 5 | Sub-band + ratio | Yes | No | No | ~200ms |
| 6 | 30s→60s | Top 5 | Sub-band + ratio | Yes | conf < 0.40 | No | ~300ms |
| 7 | 30→60→90s | Top 5 | Sub-band + ratio | Yes | conf < 0.40 | No | ~400ms |
| 8 | Multi-window merge | Top 5 | Full matrix | Yes | Full | BNNS | ~500ms |
| 9 | Multi-window merge | Top 5 | Full matrix | Yes | Full | CoreML | ~600ms |
| 10 | Multi-window merge | Top 7 | Full + quorum | Yes | Full + convergence | CoreML+DSP quorum | ~700ms |

Note: Intensity scale is ordinal (higher = more thorough). Exact pipeline configuration at each level may change across library versions.

**#17 — `AnalysisIntensity` as Typed Struct**
Wraps an Int (1-10) with named constants (`.fastest`, `.default`, `.thorough`, `.maximum`) and computed properties like `requiresMLModel`.

**#10 — `AnalysisConfiguration` Builder for Power Users**
Struct-based configuration exposing individual knobs (maxWindowSeconds, candidateCount, disambiguationStrategy, mlTiebreaker, fineGridRefinement, progressiveRetry). Presets are static instances of this struct.

**#52 — Dual Sync/Async API**
Both `analyzeBPM(url:intensity:)` (sync) and `async analyzeBPM(url:intensity:)`. Sync is the primitive with zero internal concurrency. Async wraps it with internal parallelism.

**#53 — Internal Concurrency Only in Async Path**
Sync path is fully sequential — safe for real-time audio threads. Async path exploits parallel sub-band ACFs and multi-window analysis.

**#34 — Hints Parameter**
Optional `hints: AnalysisHints(tagBPM: 130.0, durationSeconds: 295.4)` parameter. Library auto-reads duration from AVFoundation file metadata at all intensity levels.

**#58 — Ordinal Stability Documentation**
Document that the numeric scale is relative intensity, not a frozen algorithm specification. Semantic versioning handles breaking changes.

### Theme 2: Public API — Capability Detection & Degradation

**#8 — Capability-Aware Strategy Resolution**
Probe hardware at init time (Neural Engine? CoreML model bundled?). Resolve requested intensity to what's runnable. Auto-downgrade or throw in strict mode.

**#11 — Hardware Capability Query API**
`AudioAnalysisService.availableCapabilities()` returns hasNeuralEngine, hasCoreMLModel, recommendedProfile, supportedProfiles. Follows AVCaptureDevice.DiscoverySession pattern.

**#18 — Auto-Downgrade with Provenance**
If intensity 9 requested but CoreML model not bundled, runs at 7. Result carries `effectiveIntensity` and optional `warnings` array. Strict mode throws instead.

**#19 — Intensity Introspection**
`describeIntensity(8)` returns stages, estimatedDuration, mlRequired, mlBackend. `maximumSupportedIntensity()` returns what hardware supports.

**#13 — Graceful Degradation Chain**
`.hybrid` → `.thorough` → `.balanced` → `.fast`. Consumer always gets a result, never a hard capability failure.

**#12 — Result with Provenance Metadata**
`AudioAnalysisResult` includes `effectiveIntensity`, `techniquesUsed: [AnalysisTechnique]`, `quorumAgreement: Bool`, `hardwareFallback: Bool`, `windowsAnalyzed: Int`.

### Theme 3: Public API — Result Types & Future-Proofing

**#45 — Beat Position Array in Result**
`beatPositions: [Double]?` (seconds from start) and `downbeatPositions: [Double]?` populated at intensity 8+ when beat tracking runs. Nil at lower intensities. Enables DJ app beat-sync.

**#46 — Beat Tracking as Gold Path at Intensity 9-10**
Shift from periodicity estimation to actual beat tracking (Ellis DP or similar). Derive tempo from `60 / median(inter_beat_intervals)`. More robust for syncopated music. Beat positions are a free byproduct.

**#20 — Tag Hint as Separate API Concern**
Tag hints are cleaner as a parameter on analyzeBPM rather than overloading the intensity scale.

### Theme 4: Accuracy — Candidate Generation (Core Bottleneck)

**#24 — Expand to Top 5 Candidates** [QUICK WIN] ✅ *Implemented 2026-03-24 (Phase 1, intensity 5+)*
Change `extractTopCandidates` count from 3 to 5. If even 3-4 of the 11 failures have the correct BPM at position 4-5, this alone moves Acc1 significantly.

**#25 — Multi-Window Candidate Pool Merge**
Run pipeline independently at 30s/60s/90s, collect all candidates into a single pool, deduplicate within ±2 BPM (keep highest score), then disambiguate on the merged pool. Different from progressive retry which picks the best single-window result.

**#61 — Confidence-Weighted Progressive Analysis**
Instead of max-selection across windows, Bayesian-combine results. Two weak signals (30s: 160 BPM @ 0.35, 60s: 160 BPM @ 0.38) reinforce each other even though neither crosses 0.40 individually.

**#26 — Onset Detection Variant Ensemble**
Run onset detection with multiple parameter settings (hop sizes, mel band counts, compression scales). Each variant produces its own candidates. Pool all candidates. Like madmom's multi-model ensemble but with DSP parameter variation.

**#41 — Multi-Resolution STFT**
Run STFT at 1024, 2048, 4096 window sizes simultaneously. Short windows catch transient snares. Long windows capture sustained kick energy. Combine envelopes via geometric mean. Based on Grosche & Müller (2011) multi-resolution approach.

**#27 — Spectral Flux Onset as Parallel Signal**
L2 norm of positive spectral difference frame-to-frame, without mel compression. Preserves more frequency detail. Run alongside mel onset and pool candidates from both.

### Theme 5: Accuracy — Onset Detection for Dense Breakbeat

**#60 — Adaptive Thresholding (Median-Filtered Onset Envelope)** [QUICK WIN] ✅ *Implemented 2026-03-24 (Phase 1, intensity 4+) — uses running mean via vDSP_vswsum, not median*
Subtract running median from onset envelope before ACF. Keeps only peaks exceeding local noise floor. Specifically addresses "wall of energy" from dense snare rolls in jungle/DnB. One-line change using vDSP running median.

**#59 — Harmonic/Percussive Source Separation**
Median filtering on spectrogram (horizontal = harmonic, vertical = percussive). Run onset detection on percussive component only. Strips synth pads, vocals, bass lines. Implementable with vDSP.

**#37 — High-Pass Onset Envelope** [QUICK WIN]
High-pass filter the onset envelope before ACF to emphasize hi-hat periodicity over low-frequency snare roll energy.

**#38 — Per-Sub-Band Normalization** [QUICK WIN] ✅ *Implemented 2026-03-24 (Phase 1, intensity 3+) — max normalization with 1% energy threshold*
Normalize each sub-band onset envelope to [0,1] independently before combining. Prevents loud snare bands from drowning out kick periodicity in the full-band sum.

**#39 — ACF Peak Sharpening** [QUICK WIN] ✅ *Implemented 2026-03-24 (Phase 1, intensity 3+) — uses acf² via vDSP_vsq*
Raise ACF to a power (`acf^2` or `acf^3`) before peak picking. Amplifies sharp periodic peaks, suppresses broad noisy humps. Single `vDSP_vsq` call.

**#40 — Comb Filter Resurrection for Dense Percussion**
Previously rejected for general case. Revisit for specific jungle/DnB failure mode where `y[t] = onset[t] + 0.8 * y[t-P]` reinforces persistent periodicity through noise.

### Theme 6: Accuracy — Disambiguation Improvements

**#4 — Ratio-Aware Disambiguation (3:2, 4:3, 3:1)**
Extend `resolveOctaveAmbiguity` to check non-octave ratios. Directly addresses Prodigy failures at 171 and 107.5 BPM (3:2 relationships). No other library handles this.

**#64 — Unified Signal Matrix for Disambiguation**
All signals (sub-band ACF, fused periodicity, duration hint, tag hint, ML classification, click-track correlation, beat tracking) feed into a single weighted decision matrix. Intensity level controls which rows are active.

**#35 — Duration-Derived BPM as Weak Auto-Read Prior** [QUICK WIN]
Auto-read duration from AVFoundation metadata. Compute structurally plausible BPMs from common bar counts (32, 64, 96, 128, 192, 256). `BPM = (Bars × 4 × 60) / Duration`. Weight as weak prior (~0.1x). Free signal, zero PCM cost.

**#33 — Duration + Tag Hint Cross-Validation**
If duration-derived candidates include a BPM within ±2% of the tag hint, confidence in that value is very high. Two independent zero-cost signals corroborating each other.

**#62 — Click-Track Cross-Correlation at Candidate BPMs**
For each candidate, generate synthetic click track and cross-correlate with onset envelope. Best-aligning candidate wins. Reuses existing `generateClickTrack` from test support. Single `vDSP_conv` call per candidate.

**#44 — Reverse Analysis (Analyze from End)**
Outros often have cleaner rhythmic patterns than drops in DnB. Try the last 30s as an additional analysis window.

### Theme 7: ML Integration

**#2 — Schreiber-Style CNN Tiebreaker**
Small CNN (<2MB) trained on mel-spectrograms for BPM bin classification. Fires only when DSP confidence < 0.40. Implements via BNNS (Accelerate, zero new deps) or CoreML (Neural Engine acceleration).

**#65 — ML Model Implicitly Learns Genre-Tempo Correlation**
A CNN trained on genre-diverse tempo-labeled data learns breakbeat texture → 160-180 BPM, four-on-the-floor → 120-130 BPM. No separate genre detection step needed.

**#3 — AudioFeaturePrint as Free Feature Extractor**
Apple's pre-trained audio embeddings from CreateMLComponents. Feed buffer in, get high-dimensional features out. Only need labeled data for the final classifier layer.

**#9 — Quorum Voting (DSP + ML Ensemble)**
Run DSP and ML in parallel, vote. Agreement boosts confidence. Disagreement triggers tiebreaker policy. Consumer configurable: `.dspOnly`, `.mlOnly`, `.quorum(tiebreaker:)`.

**#55 — Training Data Strategy: Tiebreaker Not Classifier**
Reframe ML task from "classify BPM from scratch" (needs huge dataset) to "pick the right candidate from a DSP-generated shortlist" (binary/ternary, needs modest dataset).

**#54 — Separate `BoomBoomBoomKitML` Package Product**
Optional resource bundle. `BoomBoomBoomKit` = DSP only (intensity 1-7). `BoomBoomBoomKitML` = adds model, enables intensity 8-10. Consumers who don't need ML never pay binary cost.

### Theme 8: Diagnostics & Instrumentation

**#47 — Pipeline Signal Trace (Internal Debug)** [HIGHEST LEVERAGE] ✅ *Implemented 2026-03-24 (Phase 1) — `BPMDiagnosticTrace` public struct, enabled via `enableTrace: true`*
`DiagnosticTrace` struct captures intermediate state: onset envelope, sub-band envelopes, ACF peaks, tempogram peaks, fused spectrum, TPS2 output, raw candidates, final candidates, duration hints. Run the 11 failing tracks through it to see exactly where the correct BPM's energy disappears.

**#48 — Visual Diagnostic Export**
Export trace data as CSV/JSON for external plotting. Visualizing the fused spectrum with the correct BPM marked shows immediately whether it's a weak peak, split peak, or absent.

**#49 — Pipeline Stage Timing**
Instrument each stage in diagnostic mode. Identify actual wall-clock bottleneck before optimizing. Might be tempogram (211 DFT evaluations) or fine-grid refinement, not the assumed STFT.

**#36 — Diagnostic Mode Concept**
Internal-only debug capability. Not a public API. Compile-time gated with `#if DEBUG`.

**#57 — Compile-Time Gated Diagnostics**
`#if DEBUG` flag ensures zero cost in release builds. No accidental performance regression from diagnostic allocations.

### Theme 9: Performance

**#5 — Early-Exit Fast Path** [QUICK WIN]
If 30s window confidence > 0.85, skip 60s/90s retry. If ACF and tempogram independently show a strong single peak, skip fusion and go to disambiguation.

**#30 — STFT Frame Reuse Across Windows**
Cache 30s STFT frames and extend for 60s/90s windows. Saves ~40% of progressive retry wall-clock time.

**#29 — Lazy Sub-Band Computation** [QUICK WIN]
Skip sub-band onset extraction and sub-band ACF at intensity 1-2. Only compute full-band. Saves ~30% of onset detection cost.

**#6 — Downsampled Onset Detection at Low Intensity**
Downsample to 22050 Hz for intensity 1-3. Halves STFT frames and mel computation. Minimal accuracy trade-off for clearly rhythmic tracks.

**#31 — Parallel Sub-Band ACF** [QUICK WIN]
Dispatch 4 sub-band ACFs concurrently via `async let` or TaskGroup. Stateless, share no mutable state. Ideal for M-series efficiency cores.

**#50 — Batch FFT for Tempogram**
Use `vDSP_fftm_zrip` to batch DFT evaluations instead of sequential. Significant only if timing (#49) confirms tempogram is a bottleneck.

**#51 — Async Pipeline with Structured Concurrency**
Internal parallelism in the async API path — concurrent sub-band ACFs, concurrent multi-window analysis.

### Theme 10: Architecture & Internal Design

**#21 — Intensity as Pipeline Stage Composition**
Each intensity level is an array of `PipelineStage` values. Adding new stages (future transformer model) is an internal config change, not API change.

**#22 — ML Levels are Additive, Not Exclusive**
Intensity 8+ runs DSP *plus* ML, never ML alone. Guarantees monotonically non-decreasing accuracy with intensity.

**#14 — `BPMEstimator` Protocol for Testability**
Protocol that DSP and ML analyzers conform to. Enables pluggable estimators and independent testing.

**#23 — ML Model as Optional Resource Bundle**
If consumer strips resources, BNNS model unavailable. `maximumSupportedIntensity()` returns 7. Zero runtime crashes.

**#56 — Latency Budget**
Intensity 1-3 targets <100ms for real-time use case. Intensity 8-10 can take 500ms+ for batch library import.

### Uncategorized / Cross-Cutting

**#42 — Beat Tracking Instead of Tempo Estimation (at high intensity)**
Ellis DP beat tracking derives BPM from inter-beat intervals. More robust for syncopated music. Enables beat position output for DJ app.

**#43 — Perceptual Tempo via Onset Density**
Count onsets per second in sliding window, find most stable count. Orthogonal signal to ACF/tempogram.

---

## Prioritization

### Do First (Highest Impact, Unlocks Everything Else)

| Priority | Idea | Why First |
|----------|------|-----------|
| 1 | #47 — Diagnostic pipeline trace | Unlocks all accuracy work. Until you see where signal dies in 11 failures, improvements are guesswork. |
| 2 | #24 — Expand to top 5 candidates | One-line change, directly addresses biggest failure mode. |
| 3 | #15/16/17 — Intensity scale API design | Architectural spine. Every other improvement slots into an intensity level. |
| 4 | #60 — Adaptive thresholding on onset envelope | Low effort, directly targets jungle/DnB failure mode. |
| 5 | #52/53 — Dual sync/async API | Foundational API decision affecting everything downstream. |

### Quick Wins (Low Effort, Immediate Value)

| Idea | Effort | Impact |
|------|--------|--------|
| #39 — ACF peak sharpening | One vDSP call | Better candidate peaks |
| #35 — Duration-derived BPM hint | Division + AVFoundation metadata read | Free disambiguation signal |
| #5 — Early-exit fast path | Confidence threshold check | Skip unnecessary retry |
| #29 — Lazy sub-band at low intensity | Conditional skip | ~30% faster at intensity 1-2 |
| #37 — High-pass onset envelope | Simple filter | Cleaner breakbeat onsets |
| #38 — Per-sub-band normalization | Normalize before sum | Louder bands stop dominating |

### Medium-Term (Significant Accuracy Gains)

| Idea | Effort | Impact |
|------|--------|--------|
| #4 — Ratio-aware disambiguation | Medium | Fixes known 3:2 failures |
| #25 — Multi-window candidate merge | Medium | Candidates from all windows pooled |
| #59 — Harmonic/percussive separation | Medium | Clean percussion for onset detection |
| #61 — Bayesian progressive combine | Medium | Weak corroborating signals reinforce |
| #62 — Click-track cross-correlation | Low-Medium | Orthogonal disambiguation signal |
| #12 — Result provenance metadata | Medium | Consumer transparency |

### Long-Term / High-Investment

| Idea | Effort | Impact |
|------|--------|--------|
| #46 — Beat tracking at high intensity | High | Gold standard + DJ app enabler |
| #2/#65 — ML tiebreaker (BNNS/CoreML) | High | Genre-aware disambiguation |
| #64 — Unified disambiguation signal matrix | High | All signals in one weighted decision |
| #54 — BoomBoomBoomKitML package split | Medium | Clean separation of DSP vs ML |
| #14 — BPMEstimator protocol | Medium | Testability and pluggability |

---

## Session Summary

**65 ideas** generated across **10 themes** using Cross-Pollination with External Research, Five Whys, and Constraint Mapping.

**Key Breakthroughs:**
- **Duration-as-BPM-hint (#32/#35):** Electronic music song length encodes tempo via bar count. Zero-cost signal nobody else uses.
- **BNNS inside Accelerate (#2):** Neural network inference with zero new framework dependencies. Makes ML tiebreaker viable without breaking the "Apple system frameworks only" constraint.
- **Numeric intensity scale (#15):** Clean, universally understood API pattern (like compression level) that unifies all improvements under one control surface.
- **Unified signal matrix (#64):** All disambiguation signals (DSP, metadata, ML) feed one weighted decision. Intensity controls which rows activate.
- **Dual sync/async API (#52):** Respects caller's concurrency model. Sync is safe for real-time audio threads.

**Critical Next Step:** Build the diagnostic pipeline trace (#47) and run the 11 failing OA300 tracks through it. The visualization will reveal exactly which pipeline stage loses the correct BPM's signal, making all subsequent accuracy work targeted rather than speculative.
