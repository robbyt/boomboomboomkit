---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-11-polish-final', 'step-12-complete']
classification:
  projectType: developer_tool
  domain: scientific
  complexity: medium
  projectContext: brownfield
inputDocuments:
  - '_bmad-output/planning-artifacts/phase3-roadmap.md'
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md'
  - '_bmad-output/ablation-results.md'
  - '_bmad-output/project-context.md'
  - 'CLAUDE.md'
documentCounts:
  briefs: 0
  research: 0
  brainstorming: 1
  projectDocs: 4
workflowType: 'prd'
---

# Product Requirements Document - BoomBoomBoomKit

**Author:** robbyt
**Date:** 2026-03-29

## Executive Summary

BoomBoomBoomKit is a pure-Swift audio analysis library for BPM estimation and LUFS loudness measurement, targeting the Apple ecosystem exclusively. It uses only Apple system frameworks (Accelerate/vDSP, AVFoundation, CoreML) with zero external dependencies. Phase 3 advances the library across four fronts: wall-clock performance, DSP accuracy, ML-augmented detection, and measurement infrastructure -- with the goal of matching or surpassing Rekordbox's per-track algorithmic accuracy on a genre-diverse corpus.

The library serves two immediate consumers -- Hilbert (a DJ app) and MetaMan (a metadata viewer) -- and is designed as idiomatic, open-source Swift for adoption by the broader Apple developer community. The primary user experience targets are: drop-in integration (3 lines of code to get a BPM), deep configurability via a 1-10 intensity scale for power users, cooperative cancellation and progress reporting for batch workflows, and a standalone demo macOS app for algorithm evaluation.

Current accuracy stands at Acc1=69.5%, Acc2=89.0% on an 82-track DnB-heavy corpus (Rekordbox ground truth). "Surpassing Rekordbox" is defined as: matching Rekordbox where it is correct AND beating it where a DAW-verified oracle proves Rekordbox wrong -- scoped to per-track algorithmic accuracy, not ecosystem features. This claim requires corpus expansion to 200+ tracks across 6+ genres before it can be made credibly.

### What Makes This Special

No other focused, open-source Swift package delivers competitive BPM detection using only Apple's native frameworks. The architectural stance -- zero external dependencies, Accelerate for DSP, BNNS/CoreML for ML -- means consumers inherit no transitive dependencies, no binary size surprises, and full Neural Engine acceleration on Apple Silicon. The intensity scale (1-10) unifies all improvements under a single control surface: levels 1-7 are DSP-only, 8-10 add ML via an optional `BoomBoomBoomKitML` package that exports a single `MLTechnique` conformance. ML is strictly additive -- it never runs alone, guaranteeing monotonically non-decreasing accuracy with intensity.

The competitive landscape includes essentia, librosa, and madmom (Python, cross-platform) and Rekordbox (proprietary, closed). BoomBoomBoomKit is the only option that is native Swift, SPM-distributed, and leverages Apple-specific hardware acceleration (Neural Engine, AMX) without bridging headers or C++ interop.

## Project Classification

- **Project Type:** Developer tool (Swift library / SPM package)
- **Domain:** Scientific (audio DSP, algorithmic accuracy, computational validation)
- **Complexity:** Medium (no regulatory requirements; rigorous accuracy validation against commercial competitors, reproducible ablation-validated benchmarking, DSP + ML technique interplay)
- **Project Context:** Brownfield (9 source files, 8 test files, 142 passing tests, shipped intensity API, 6 ablation-validated DSP techniques, 8 merge strategies, diagnostic trace infrastructure)

## Success Criteria

### User Success

- **Developer integration:** A new consumer can add BoomBoomBoomKit via SPM and get an accurate BPM from an audio file with minimal configuration
- **Accuracy parity:** Hilbert users experience BPM detection at least as accurate as Rekordbox on their music libraries
- **Configurability:** Power users can tune intensity, merge strategy, and technique sets to optimize for their specific genre or latency budget
- **Cooperative cancellation and progress:** Consumers get the primitives needed to build responsive batch workflows -- cancellation checks between pipeline stages and a progress reporting mechanism for both sync and async consumers. The library does not provide a task runner or batch queue; guidance is documented for consumers

### Business Success

- **Phase 3A-3B:** Wall-clock performance improved measurably relative to baseline. Acc1 improves through new and refined DSP techniques validated by ablation
- **Phase 3C:** ML integration ships at intensity 8-10. Acc1 improves further with DSP+ML ensemble. `BoomBoomBoomKitML` package published as optional add-on
- **Phase 3D (Measurement):** Corpus expanded with genre diversity and DAW-verified ground truth. Genre-stratified accuracy reporting
- **Phase 3D (Developer Experience):** Library packaged for external consumption -- public API documented, README with quick-start, demo app available as an in-repo SPM target
- **Community signal:** External adoption is a lagging indicator; the deliverable is packaging the library so it's ready for external consumers

### Technical Success

- **Accuracy regression gate:** Acc1 on current OA300 corpus must never decrease phase-over-phase
- **DSP improvement (3B):** Measurable Acc1 improvement from new DSP techniques on current corpus
- **ML additive guarantee (3C):** Intensity 8+ accuracy is strictly >= intensity 7 accuracy on every corpus run
- **Fine-grid precision:** Resolve sub-BPM precision errors identified by DAW oracle (e.g., Icicle 126.0 detected as 125.9)
- **Performance baseline:** Benchmark infrastructure established in Phase 3A. Subsequent phases target relative improvement. Benchmarks report hardware context (chip, memory) alongside results
- **Zero-dep guarantee maintained:** `BoomBoomBoomKit` (intensity 1-7) adds zero new framework dependencies. `BoomBoomBoomKitML` adds only CoreML
- **Determinism (desirable, not required):** Pipeline ideally produces the same BPM for the same file at a given intensity level. ML paths may introduce acceptable non-determinism
- **Test coverage:** All new DSP techniques added to ablation matrix. Performance regression tests. Existing tests never break

### Measurable Outcomes

| Metric | Current | Phase 3 Target | Measurement |
|--------|---------|---------------|-------------|
| Acc1 (OA300) | 69.5% | Improve each phase, no regressions | `make benchmark` |
| Acc2 (OA300) | 89.0% | Improve each phase, no regressions | `make benchmark` |
| Corpus size | 82 tracks (fast/complex electronic) | Expand with genre diversity | Track count + genre distribution |
| Wall-clock (intensity 7) | Unmeasured | Establish baseline, then improve | `make perf-benchmark` |
| Fine-grid precision | Sub-BPM errors present | Resolved on DAW oracle set | DAW oracle comparison |
| External readiness | Undocumented | API docs, README, demo app | Deliverable checklist |

## Product Scope

Phase 3 advances BoomBoomBoomKit across four sub-phases:

- **3A -- Measurement & Performance:** Pipeline compute reduction, benchmark infrastructure, cancellation/progress primitives
- **3B -- DSP Accuracy:** New ablation-validated techniques targeting octave, triplet, and fine-grid error classes
- **3C -- ML Integration:** `BoomBoomBoomKitML` package with DSP+ML ensemble at intensity 8-10
- **3D -- Developer Experience:** Demo app, public API docs, finalized accuracy claims

For detailed phase deliverables, dependencies, risk mitigation, and scope cuts, see [Project Scoping & Phased Development](#project-scoping--phased-development).

## User Journeys

### Journey 1: Library Author -- Improving Accuracy on a Difficult Track

**Persona:** robbyt -- library author, DJ app developer, audio DSP practitioner. Maintains BoomBoomBoomKit alongside Hilbert (DJ app) and MetaMan (metadata viewer).

**Opening:** robbyt notices Hilbert is displaying 87 BPM for a Prodigy remix that's clearly 174 BPM. He checks the DAW oracle -- confirmed 174. Rekordbox gets it right. This is an octave error.

**Rising Action:** He runs `make benchmark` to see the current Acc1. Then runs the track through `analyzeBPM(url:intensity:enableTrace:true)` to get the `BPMDiagnosticTrace`. The trace shows the correct 174 BPM candidate was present in the raw candidates but lost during disambiguation -- sub-band voting preferred the half-tempo. He examines the ablation matrix to see which technique combinations handle this error class. He prototypes a new DSP technique, adds it to `DSPTechnique` as a new case, and runs the full ablation matrix to validate it doesn't regress other tracks.

**Climax:** `make benchmark` shows Acc1 improved. `make oracle` confirms the Prodigy track now matches DAW-verified truth. No regressions on any other track.

**Resolution:** He commits the new technique, updates the `TechniqueSet` presets, and the improvement flows downstream to Hilbert users automatically at their next library rescan.

**This journey reveals requirements for:**
- Diagnostic trace infrastructure (already exists)
- Ablation matrix validation for every new technique
- DAW oracle three-way comparison
- Technique-gated pipeline stages (existing architecture)
- Performance benchmark to ensure new techniques don't slow the pipeline

---

### Journey 2: App Developer -- First Integration

**Persona:** Kenji -- an indie developer building a music practice app that needs to detect BPM so it can adjust a metronome click track to match the user's imported audio.

**Opening:** Kenji finds BoomBoomBoomKit on GitHub while searching for a Swift BPM detection library. He's been using a Python bridge to librosa, which works but adds complexity and crashes occasionally on iOS. He wants something native.

**Rising Action:** He reads the README, adds the SPM dependency, and writes his first call to `AudioAnalysisService.analyzeBPM(url:)`. Default intensity, default merge strategy. It returns a BPM and confidence for his test track -- a pop song at 120 BPM. It's correct. He tries a 2-second audio clip and gets `nil` back -- the documentation explains minimum duration requirements and other nil-return conditions clearly. He tries a few more tracks from different genres. Most are right. One jazz track comes back at half-tempo. He bumps intensity to 8 and tries again -- but intensity 8 requires `BoomBoomBoomKitML`, which he hasn't added. The result comes back at effective intensity 7, with an actionable message explaining why the degradation occurred and how to add the ML package.

**Climax:** He adds `BoomBoomBoomKitML` as an optional dependency, re-runs at intensity 8, and the jazz track now resolves correctly. The API surface hasn't changed -- same call, better result.

**Resolution:** Kenji ships his practice app with BoomBoomBoomKit at intensity 7 (no ML dependency for his v1) and plans to add the ML package in a future update. He never had to learn about mel spectrograms, autocorrelation, or sub-band voting. When a user later reports a wrong BPM on a specific track, Kenji's options are clear: bump intensity, try a different merge strategy, or file a GitHub issue with the audio file for investigation.

**This journey reveals requirements for:**
- Clear README with quick-start
- Sensible defaults (intensity 7, maxConfidence merge)
- Graceful ML degradation with actionable provenance (why degraded, how to fix)
- Documentation of nil-return conditions (silence, too-short, unsupported rate)
- `BoomBoomBoomKitML` as a truly optional add-on
- API that doesn't require DSP knowledge to use

---

### Journey 3: App Developer -- Batch Library Import with Cancellation

**Persona:** Kenji again -- his app now has a "scan library" feature where users import their full music collection.

**Opening:** A user imports 2,000 tracks. Kenji needs to analyze them all, show progress, and let the user cancel mid-scan.

**Rising Action:** Kenji wraps calls to `analyzeBPM` in his own task queue. He uses the progress primitive to update a progress bar per track. After 500 tracks, the user taps "Cancel." Kenji cancels his parent `Task`. The in-flight analysis checks cancellation between pipeline stages and exits cooperatively. The next queued analysis never starts because Kenji's queue checks cancellation before dispatching.

**Climax:** The UI responds promptly -- no hung analysis blocking the cancel. Results for the 500 completed tracks are retained. The user can resume later.

**Resolution:** Kenji built the batch orchestration himself using standard Swift concurrency patterns, guided by BoomBoomBoomKit's documentation on batch workflow patterns. The library gave him the cancellation and progress primitives; the queue logic is his.

**This journey reveals requirements for:**
- Cooperative cancellation (check between pipeline stages)
- Progress reporting primitive (per-track, not per-pipeline-stage)
- Consumer documentation for batch patterns
- Results for completed work preserved on cancellation
- Library does NOT own the task queue or batch orchestration

---

### Journey 4: Power User -- Algorithm Evaluation via Demo App

**Persona:** Maren -- an audio researcher evaluating BPM detection libraries for a music information retrieval project. She needs to understand how the algorithms behave on her corpus before committing.

**Opening:** Maren clones BoomBoomBoomKit and builds the demo app target. She drops an audio file into the window.

**Rising Action:** At intensity 1-3, results appear nearly instantly. She slides to intensity 7 -- still fast. She pushes to intensity 9 with the ML path enabled; the demo app shows a brief activity indicator while analysis runs, then displays the result. She switches merge strategies via a dropdown. She enables the diagnostic trace view and sees the candidate list, sub-band energies, and which disambiguation step selected the final BPM. She drops in a tricky polyrhythmic track and compares results across configurations.

**Climax:** She finds that intensity 7 with `maxConfidence` merge handles her corpus well, but a few tracks benefit from intensity 9 with the ML path. The trace view shows her exactly why -- the ML classifier resolves an octave ambiguity that DSP alone can't.

**Resolution:** Maren integrates BoomBoomBoomKit into her research pipeline, confident in which configuration works for her data. The demo app served as both evaluation tool and learning aid -- she never needed to read the DSP source code to understand the library's behavior.

**This journey reveals requirements for:**
- Demo app as in-repo SPM target
- Real-time parameter adjustment (intensity, merge strategy)
- Diagnostic trace visualization
- File drop interaction
- Responsive feedback at all intensity levels (immediate results at low intensity, activity indicator at high intensity)
- Demo app exposes all public API configuration surfaces

---

### Journey Requirements Summary

| Capability | J1 (Author) | J2 (First Use) | J3 (Batch) | J4 (Demo) |
|-----------|:-----------:|:---------------:|:----------:|:---------:|
| Diagnostic trace | x | | | x |
| Ablation validation | x | | | |
| DAW oracle comparison | x | | | |
| Sensible defaults | | x | x | |
| Graceful ML degradation | | x | | |
| Actionable degradation messages | | x | | |
| Nil-return documentation | | x | | |
| Quick-start README | | x | | |
| Cooperative cancellation | | | x | |
| Progress reporting | | | x | |
| Batch workflow docs | | | x | |
| Demo app | | | | x |
| Parameter visualization | | | | x |
| Performance benchmarks | x | | | |

## Domain-Specific Requirements

### Validation Methodology

- **Accuracy tolerance.** The current Acc1 threshold uses 2% tolerance, which is stricter than the MIREX/mir_eval standard of 4%. This is intentional -- DJ applications require higher precision than academic evaluation. Phase 3 should report both: **Acc1@2% (library standard)** and **Acc1@4% (MIREX-compatible)** so results can be compared to published MIR literature. Acc2 allows factors of 2, 3, 1/2, or 1/3 per MIREX convention (octave and triplet errors)
- **Ground truth protocol.** For the current corpus, Rekordbox is the benchmark target and DAW-verified BPM is the diagnostic truth. For corpus expansion: DAW-verified where possible, Rekordbox as fallback, disagreements flagged for manual review. When all sources disagree, the tiebreaker is perceptual ground truth: "what BPM would a DJ set the pitch fader to?"
- **Ablation as gatekeeper.** Every technique change must pass the full ablation matrix before committing. Currently manual (`make ablation`); no CI. The author runs it as part of wrapping up each story

### Corpus & Reproducibility

- **Current corpus.** 82 tracks, primarily fast/complex electronic music (DnB, footwork, breakbeat, Prodigy remixes). Mixed licensing: open-license fixtures, author's own music, commercially licensed tracks
- **GiantSteps Tempo dataset.** 664 electronic dance music tracks from Beatport with crowd-corrected tempo annotations (ISMIR 2015). BPM range 53-200, peak at 170-180 (DnB). Evaluate as a supplementary open validation corpus for Phase 3D. Note: GiantSteps uses 2-minute Beatport previews, not full tracks -- results are not directly comparable with OA300 (full-length tracks)
- **OA300 expansion.** The primary corpus continues to grow with real-world tracks from the author's collection. GiantSteps supplements but does not replace OA300 -- the library is tuned against real DJ music, not academic benchmarks
- **Author-contributed open audio.** The author is willing to open-source original music (songs and loops) to build a larger redistributable test subset
- **External reproducibility is not a goal.** Synthetic-only validation (click tracks, generated signals) should always pass and serves as the minimum external validation path

### Audio Format Considerations

- **Supported input formats:** WAV, AIFF, MP3, M4A (AAC/ALAC), FLAC, CAF (via AVAudioFile/Core Audio)
- **Target use case:** DJ-quality audio -- FLAC, Apple Lossless, high-bitrate MP3 (320kbps), AAC. Low-bitrate or voice-optimized codecs are not target formats
- **OGG/Vorbis is NOT supported** (no Core Audio codec for the OGG container)

### Numerical Precision & ML Readiness

- **Double precision for IIR filters** is an existing hard rule (K-weighting biquads). Must not regress
- **ML inference precision.** CoreML on Apple Silicon uses Float16 on the Neural Engine internally; BNNS gives explicit control. The pipeline interface remains Float32 -- ML frameworks handle internal precision transparently. The `MLTechnique` protocol's input contract (`BPMDiagnosticTrace`) must preserve Float32 precision through conversion to ML framework input types (e.g., `MLMultiArray`, `MLShapedArray`)
- **Accumulator precision.** New DSP techniques involving recursive computation (IIR filters, running statistics) should default to Double precision and only drop to Float with measured justification
- **Lay precision groundwork early.** Define the Float32 DSP/ML interface boundary in Phase 3B architecture, before ML implementation begins in 3C

### Sample Rate Strategy

- **Input stays at native sample rate** through `PCMBufferReader`. The library reads at the file's original sample rate (typically 44.1kHz or 48kHz for DJ audio)
- **Downsampling is internal and technique-specific.** When a detection method can perform well at a lower sample rate (e.g., BPM onset detection below 10kHz), the pipeline downsamples internally. This is a performance optimization, not a data reduction step
- **K-weighting (LUFS) retains full sample rate.** Pre-computed coefficients for 44.1/48/96kHz only. Unsupported rates return nil

### Duration-Derived BPM Signal

- **Technique from Splice.com and brainstorm #35.** Infer BPM candidates from file duration using common bar counts (32, 64, 96, 128, 192, 256): `BPM = (Bars x BeatsPerBar x 60) / DurationSeconds`. This produces a small set of structurally plausible BPMs
- **Use as a weak prior alongside other methods.** Not a primary detection method, but a zero-cost disambiguation signal. Auto-read duration from AVFoundation metadata
- **Particularly effective for electronic music** where song structure follows predictable bar patterns

_See the consolidated [References](#references) section at the end of this document._

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. Zero-dependency ML-augmented audio analysis on Apple platforms.** BoomBoomBoomKit is the first focused, open-source Swift library to combine traditional DSP (Accelerate/vDSP) with ML inference (BNNS/CoreML) for BPM detection -- all using only Apple system frameworks. The BNNS path lives inside Accelerate, meaning ML-augmented analysis at intensity 8+ adds zero new framework dependencies. Other tempo estimation libraries either require Python runtimes (essentia, librosa, madmom), C dependencies (aubio), or are proprietary (Rekordbox, Serato, Traktor). BoomBoomBoomKit is native Swift, SPM-distributed, and leverages Apple Silicon hardware acceleration (Neural Engine, AMX) without bridging headers or C++ interop.

**2. Monotonic accuracy as a design constraint.** Phase 3 enforces a design constraint: intensity 8+ runs DSP AND ML, never ML alone. If the ML model is wrong, the DSP result still wins. This guarantees that adding ML can only improve accuracy, never regress it. This constraint will be validated by ablation -- every technique combination must demonstrate non-negative Acc1 delta. This is an architectural guarantee to be proven, not a claimed property.

**3. Intensity scale as a unified DSP/ML control surface.** The 1-10 intensity scale abstracts technique selection, window sizing, candidate counts, and ML engagement behind a single integer. Levels 1-7 are DSP-only; 8-10 add ML. This pattern (inspired by zlib compression levels) is uncommon in audio analysis libraries. It enables consumers to trade latency for accuracy without understanding the underlying algorithms.

**4. Ablation-validated technique gating.** A 64-combination matrix (2^6 DSP techniques) gates every technique change before it ships. This level of exhaustive combinatorial validation is not standard practice in audio analysis libraries -- essentia, librosa, madmom, aubio, and the Swift alternatives do not ship with comparable validation infrastructure. This is a quality engineering innovation that ensures predictable behavior across technique configurations.

**5. Duration-derived BPM as a combined signal.** Inferring BPM from file duration using common bar counts (the Splice.com technique) is a known approach. What is novel is integrating it as an additional signal in BoomBoomBoomKit's weighted disambiguation matrix alongside DSP and ML candidates, providing structural context that purely signal-based approaches miss.

### Competitive Landscape

#### BPM Detection Libraries & Tools

| Library | Language | Dependencies | ML Support | Platform | Open Source | Stars |
|---------|----------|-------------|-----------|----------|-------------|-------|
| **BoomBoomBoomKit** | Swift | Zero (Apple frameworks) | BNNS + CoreML (Phase 3) | Apple-native (Neural Engine, AMX, vDSP) | Yes | -- |
| [spfk-tempo](https://github.com/ryanfrancesconi/spfk-tempo) | Swift | Accelerate + AVFoundation | No | Apple-native | Yes (MIT) | 1 |
| [TempiBeatDetection](https://github.com/CheckThisCodeCarefully/TempiBeatDetection) | Swift | AVFoundation | No | Apple-native | Yes | 11 |
| [BPM-Analyser](https://github.com/Luccifer/BPM-Analyser) | C/Swift | Minimal | No | Apple | Yes | 77 |
| [Superpowered SDK](https://superpowered.com/) | C++ | Proprietary | Unknown | Cross-platform (iOS/Android/Web) | No (free tier) | 1.4k |
| [aubio](https://github.com/aubio/aubio) | C | Minimal | No | Cross-platform | Yes (GPL) | 3.7k |
| [essentia](https://github.com/MTG/essentia) | C++/Python | Many (+ TensorFlow) | TensorFlow models, TempoCNN | Cross-platform | Yes | -- |
| [librosa](https://github.com/librosa/librosa) | Python | NumPy/SciPy | No built-in | Cross-platform | Yes | -- |
| [madmom](https://github.com/CPJKU/madmom) | Python | NumPy/Cython | TCN models (SOTA accuracy) | Cross-platform | Yes | -- |
| [tempnetic](https://github.com/csteinmetz1/tempnetic) | Python | PyTorch | MobileNetV2 tempo | Cross-platform | Yes | 4 |
| [Mixxx](https://github.com/mixxxdj/mixxx) | C++ | Queen Mary vamp plugins | No | Cross-platform | Yes (GPL) | 6.5k |

#### DJ Applications (Proprietary, Closed-Source)

| Application | BPM Detection | Key Detection | Beatgrid | Cloud Analysis |
|------------|:------------:|:------------:|:--------:|:-------------:|
| Rekordbox (Pioneer DJ) | Yes | Yes | Yes | Yes (fingerprint DB) |
| Serato DJ | Yes | Yes | Yes | No |
| Traktor (Native Instruments) | Yes | Yes | Yes | No |

#### LUFS / Loudness Measurement

| Library | Language | Standard | Dependencies | Notes |
|---------|----------|---------|-------------|-------|
| **BoomBoomBoomKit** | Swift | ITU-R BS.1770-5 | Zero (vDSP biquads, Double precision) | Pure Swift, K-weighting via Accelerate |
| [spfk-loudness](https://github.com/ryanfrancesconi/spfk-loudness) | C/Swift | EBU R128 | libebur128 (C dep) | Swift wrapper around C library |

#### Competitive Notes

- **spfk-tempo** is the closest direct competitor -- same tech stack (Swift + Accelerate + AVFoundation). Very new (March 2026), minimal features, no ML, no intensity scale, no ablation, no diagnostic trace or candidate inspection. Uses 3-band filterbank + harmonic template matching (vs our mel filterbank + sub-band voting). Worth monitoring
- **TempiBeatDetection** is the Swift predecessor. Known weakness: non-4/4 meters. In the author's starred repos
- **Superpowered** is the commercial cross-platform competitor with BPM + key + beatgrid in one SDK. Different market (C++, cross-platform) but comprehensive
- **Mixxx** is the most relevant open-source DJ app. Uses Queen Mary vamp plugins with tempogram-based detection. In the author's starred repos. Reference for algorithm comparison
- **aubio** is the lightweight C real-time option. In the author's starred repos. Reference for onset detection approaches
- **madmom's** TCN-based tempo estimator is among the most accurate open-source implementations and represents the real accuracy benchmark alongside Rekordbox
- **spfk-loudness** wraps libebur128 (C) vs BoomBoomBoomKit's pure-Swift ITU-R BS.1770-5 implementation. Reference for LUFS measurement comparison

### Validation Approach

- **Ablation matrix** validates every technique combination (2^N for N techniques). New techniques must demonstrate non-negative Acc1 delta
- **OA300 corpus** benchmarks against Rekordbox ground truth with DAW oracle as diagnostic truth
- **GiantSteps Tempo** (664 tracks) provides MIREX-compatible external validation
- **Dual tolerance reporting** (Acc1@2% and Acc1@4%) enables comparison with published MIR literature

### Risk Mitigation

- **ML model quality risk:** ML is additive by design constraint -- worst case, it adds nothing and DSP result carries. Validated by ablation before shipping
- **BNNS capability risk:** If BNNS proves insufficient for the model architecture, CoreML is the fallback (adds one framework dep). The `BoomBoomBoomKitML` package split isolates this from the core library
- **Corpus bias risk:** Current corpus is genre-clustered. GiantSteps and OA300 expansion mitigate. Genre-stratified reporting will reveal genre-specific weaknesses
- **Zero-dep constraint risk:** If a future technique requires something outside Apple frameworks, the constraint holds for `BoomBoomBoomKit` (intensity 1-7). ML features absorb new deps into the optional `BoomBoomBoomKitML` package
- **Accuracy benchmark risk:** madmom's TCN sets a high bar for open-source tempo estimation. If BoomBoomBoomKit's ML path can't match it on a diverse corpus, the DSP-only path still provides competitive accuracy for the target use case (DJ-quality electronic music)
- **spfk-tempo competitive risk:** A new Swift library with the same tech stack appeared in March 2026. Monitor its development. BoomBoomBoomKit's advantages are significant: intensity scale, ablation validation, diagnostic trace, ML roadmap, and broader technique set

## Developer Tool Specific Requirements

### Project-Type Overview

BoomBoomBoomKit is an SPM-distributed Swift library targeting macOS 15+ today, with planned iOS/iPadOS support in a future phase. It is consumed as a package dependency -- no IDE plugins, CLI tools, or standalone executables (the demo app is an evaluation tool, not part of the library's core deliverable).

### Platform & Language

- **Swift 6.0** with strict concurrency. macOS 15+ today. iOS/iPadOS planned for a future phase (not Phase 3). Legacy platform support is not a concern
- **SPM only.** No CocoaPods, Carthage, or other package managers
- **Three SPM targets today:** `BoomBoomBoomKit` (library), `BoomBoomBoomKitTestSupport` (shared test fixtures), `BoomBoomBoomKitTests`. Phase 3C adds `BoomBoomBoomKitML` (optional ML package)
- **Platform parity testing** (macOS vs iOS) for the ML package is a concern when iOS support ships, not during Phase 3

### API Surface

The public API is documented in the README and consists of:
- `AudioAnalysisService` -- public facade (primary entry point)
- `AudioAnalysisResult`, `AnalysisIntensity`, `CandidateMergeStrategy`, `DSPTechnique`, `TechniqueSet`, `MLTechnique`, `BPMDiagnosticTrace` -- public types
- `PCMBufferReader`, `PCMBufferReaderError` -- public file I/O

Phase 3 additions to the public API:
- Cooperative cancellation (via `Task.isCancelled` checks)
- Progress reporting primitive (callback and/or `AsyncStream`)
- `BoomBoomBoomKitML` package with `MLTechnique` conformance(s)
- Dual tolerance reporting in results (Acc1@2% and Acc1@4%)

> **For downstream agents:** To find the current `MLTechnique` protocol definition, use LSP symbol lookup on `MLTechnique` rather than hardcoding a file path. The protocol may move as the codebase evolves during Phase 3.

### Documentation Strategy

- Inline `///` doc comments on all public API (idiomatic for modern Swift packages)
- README.md kept up-to-date as the primary consumer-facing documentation
- No separate DocC site for Phase 3 -- DocC is a natural future step since it generates from existing `///` comments
- Consumer guidance for batch workflow patterns (documented in README or a USAGE section)
- **README fix needed (now, not Phase 3):** Remove OGG from supported formats list (line 12 claims OGG support; Core Audio has no OGG container codec)

### Installation & Integration

SPM one-liner in `Package.swift`:
```swift
.package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", from: "1.0.0")
```

Two products available after Phase 3C:
- `BoomBoomBoomKit` -- core library (intensity 1-7, DSP only)
- `BoomBoomBoomKitML` -- optional ML add-on (intensity 8-10, adds CoreML dependency)

### Migration

No migration guide needed. The current public release is only consumed by the author's own apps (Hilbert, MetaMan). Phase 3 API additions are additive -- no breaking changes to existing API surface.

### Code Examples

- README contains quick-start code samples (already present and current)
- Demo macOS app serves as the comprehensive integration example
- No separate example project beyond the demo app

## Project Scoping & Phased Development

### MVP Strategy

**Approach: Problem-solving MVP.** The library already works. Phase 3's MVP is the minimum that moves the needle on the two primary goals: faster analysis and better accuracy. Everything else (ML, demo app) builds on that foundation.

**Solo developer project.** robbyt is the sole contributor. Phases are primarily sequential. Each phase ships independently and delivers value before the next begins.

### Development Workflow Requirement

**Per-story gating is the primary safety net.** Every story, in every phase, must run the following before and after implementation:

1. `make fmt` -- format source code
2. `make lint` -- code quality checks
3. `make test` -- all existing tests pass
4. `make benchmark` -- Acc1/Acc2 on OA300 corpus, no regressions
5. `make ablation` -- full technique combination matrix, no regressions

This gating is more important than the phase boundaries. It guarantees that any story can land in any phase without breaking the library. The phases exist for developer focus and planning, not for technical correctness.

### Phase 3A -- Measurement & Performance (Foundation)

**Core journey supported:** J1 (Author), J3 (Batch)

**Deliverables:**
- Performance benchmark infrastructure (`make perf-benchmark`) -- measure before optimizing
- GiantSteps Tempo dataset integration (664 tracks, open, annotated) -- expands measurement corpus early, provides training data for 3C. Dataset downloaded to local research directory
- Pipeline compute reduction (downsampling to internal rate, buffer reuse, FFT plan reuse). Note: downsampling changes the signal path -- all subsequent techniques are developed against the downsampled signal
- Cooperative cancellation between pipeline stages
- Progress reporting primitive for both sync and async consumers

**Delivers:** Measurable speed improvement, measurement infrastructure for all future work, expanded corpus for validation and future ML training, cancellation/progress primitives.

### Phase 3B -- DSP Accuracy (Core Value)

**Core journey supported:** J1 (Author), J2 (First Use)

**Deliverables:**
- New DSP techniques targeting octave, triplet, and fine-grid error classes. Each technique is an independent story, ablation-validated before merging. The phase is done when promising techniques are exhausted, not when a fixed list is completed
- Fine-grid precision fix (sub-BPM errors on DAW oracle tracks)
- Duration-derived BPM as a disambiguation signal
- Dual tolerance reporting (Acc1@2% and Acc1@4%)
- Continue OA300 corpus expansion with real-world tracks for genre diversity
- Design ML package structure in late 3B (`BoomBoomBoomKitML` SPM target, `MLTechnique` protocol contract)

**Delivers:** Measurable accuracy improvement on OA300 corpus. Best possible DSP baseline for ML to augment. ML package architecture ready for 3C implementation.

### Phase 3C -- ML Integration (Differentiation)

**Core journey supported:** J1 (Author), J2 (First Use)

**Deliverables:**
- `BoomBoomBoomKitML` as a separate SPM package product
- `MLTechnique` protocol first real conformance (BNNS and/or CoreML)
- DSP + ML ensemble voting at intensity 8-10
- Training on expanded corpus (OA300 + GiantSteps, not just original 82 tracks)
- Ablation validation: ML + DSP strictly additive
- Genre-stratified accuracy reporting begins

**Delivers:** ML-augmented detection path. The "surpassing Rekordbox" aspiration becomes achievable.

### Phase 3D -- Developer Experience (Credibility)

**Core journey supported:** J4 (Demo App), J2 (First Use)

**Deliverables:**
- Standalone demo macOS app as in-repo SPM target (can start once API surface stabilizes in late 3C)
- Public API documentation and updated README
- Consumer guidance for batch workflow patterns
- Finalize corpus and accuracy claims -- genre-stratified, dual-tolerance, backed by diverse tracks

**Delivers:** External developers can evaluate the library before committing. Credible accuracy claims backed by data.

### Phase Dependencies

```
3A (Measurement + Performance)
  ├── benchmark infra (make perf-benchmark)
  ├── GiantSteps integration (664 tracks)
  ├── pipeline compute reduction
  ├── cancellation + progress primitives
  │
3B (DSP Accuracy) + corpus expansion continues
  ├── independent technique stories (each ablation-gated)
  ├── fine-grid fix, duration hint, dual tolerance
  ├── OA300 expansion with genre diversity
  ├── ML package structure design (late 3B)
  │
3C (ML Integration) + corpus expansion continues
  ├── BoomBoomBoomKitML package implementation
  ├── train on expanded corpus (OA300 + GiantSteps)
  ├── DSP + ML ensemble voting
  ├── genre-stratified reporting
  │
3D (Developer Experience)
  ├── demo app (can start late 3C)
  ├── documentation + README
  ├── finalize accuracy claims
```

### Risk Mitigation Strategy

**Technical risks:**
- Most technically challenging: ML model architecture and training. Mitigated by the additive design constraint and training on an expanded corpus
- Fine-grid precision: root cause unclear. Mitigated by investigating in 3B with diagnostic trace
- BNNS vs CoreML: if BNNS can't express the model, CoreML is the fallback. Package split isolates the decision
- Downsampling changes signal: mitigated by landing it in 3A so all subsequent work is validated against the production signal path

**Market risks:**
- spfk-tempo appeared with the same tech stack. Mitigated by being significantly more advanced. Continue shipping improvements
- "Surpassing Rekordbox" claim requires corpus diversity. Mitigated by starting corpus expansion in 3A (GiantSteps) and continuing through 3B/3C

**Resource risks:**
- Solo developer. Phases are sequential and independently shippable. If momentum stalls after 3B, the library is still significantly better than today
- Corpus expansion is manual work. GiantSteps (664 tracks, open) reduces the burden. Author's own music can be open-sourced

### Scope Cuts (Explicitly Deferred)

- iOS/iPadOS support (future phase, not Phase 3)
- Beat position array output (future -- requires beat tracking, high complexity)
- Apple Foundation Models / SoundAnalysis evaluation (future exploration)
- DocC documentation site (future -- inline `///` comments + README sufficient)
- Task runner / batch queue (consumer responsibility, documented guidance only)

_See the consolidated [References](#references) section at the end of this document._

## Functional Requirements

### BPM Analysis

- **FR1:** Consumer can analyze an audio file for BPM by providing a URL and receiving a result with BPM value, confidence score, and list of candidate BPMs with scores
- **FR2:** Consumer can specify an analysis intensity level (1-10) to control the trade-off between speed and accuracy
- **FR3:** Consumer can specify a merge strategy to control how candidates from multiple analysis windows are combined
- **FR4:** Consumer can enable a diagnostic trace to inspect per-step pipeline intermediate state for a given analysis
- **FR5:** Consumer can evaluate analysis accuracy against established MIR evaluation standards (dual-tolerance reporting)
- **FR6:** Consumer can receive the effective intensity level used when the requested intensity was unavailable (ML degradation)
- **FR7:** Consumer can receive an actionable explanation when intensity degradation occurs
- **FR8:** Consumer can analyze an audio file with no configuration beyond a URL and receive an accurate result using sensible defaults

### LUFS Measurement

- **FR9:** Consumer can analyze an audio file for integrated loudness (LUFS) conforming to ITU-R BS.1770-5
- **FR10:** Consumer can read audio files into mono PCM samples at the file's native sample rate

### Cancellation & Progress

- **FR11:** Consumer can cancel an in-flight BPM analysis cooperatively -- the analysis exits between pipeline stages without blocking
- **FR12:** Consumer can receive progress updates during analysis for both sync and async usage patterns
- **FR13:** Analysis results for completed work are preserved when cancellation occurs mid-batch
- **FR14:** A cancelled analysis returns nil -- no partial BPM results are produced

### ML-Augmented Detection

- **FR15:** Consumer can optionally add the `BoomBoomBoomKitML` package to enable ML-augmented detection at intensity 8-10
- **FR16:** ML-augmented analysis runs DSP and ML in ensemble -- ML never runs alone
- **FR17:** The library degrades gracefully to the highest supported DSP intensity when the ML package is not present
- **FR18:** Consumer can query the maximum supported intensity level based on available packages (7 without ML, 10 with ML)

### Configuration & Technique Management

- **FR19:** Consumer can inspect available DSP techniques and technique set presets
- **FR20:** Consumer can compose custom technique sets for specialized use cases
- **FR21:** Library author can add new DSP techniques that are gated by the existing technique set architecture

### Audio File Handling

- **FR22:** Consumer can read audio files in WAV, AIFF, MP3, M4A (AAC/ALAC), FLAC, and CAF formats
- **FR23:** Consumer can read a partial segment of an audio file (e.g., first 30 seconds)
- **FR24:** Consumer can downsample audio to a target sample rate at read time
- **FR25:** Library returns nil (not an error) for audio that is too short, silent, or at an unsupported sample rate for LUFS
- **FR26:** Library returns a clear error for file I/O failures (file not found, unsupported format)

### Measurement & Validation Infrastructure

- **FR27:** Library author can run accuracy benchmarks against the OA300 corpus (`make benchmark`)
- **FR28:** Library author can run the full ablation matrix (`make ablation`) to validate technique combinations
- **FR29:** Library author can run performance benchmarks (`make perf-benchmark`) to measure wall-clock analysis time
- **FR30:** Library author can run three-way DAW oracle comparison (`make oracle`)
- **FR31:** Library author can benchmark against the GiantSteps Tempo dataset (664 tracks, MIREX-compatible)
- **FR32:** Accuracy is reported at both 2% tolerance (library standard) and 4% tolerance (MIREX-compatible)
- **FR33:** Genre-stratified accuracy reporting is available once the corpus has sufficient genre diversity

### Demo Application

- **FR34:** Developer can build and run a demo macOS app from the same repository as the library
- **FR35:** Developer can drop an audio file into the demo app and see the detected BPM, confidence, and effective intensity
- **FR36:** Developer can adjust intensity level and merge strategy in the demo app and see results update
- **FR37:** Developer can view diagnostic trace data (candidates, sub-band energies, disambiguation steps) in the demo app
- **FR38:** Demo app provides responsive feedback at all intensity levels (immediate at low intensity, activity indicator at high intensity)
- **FR39:** Demo app displays wall-clock analysis time alongside detected BPM
- **FR40:** Demo app generates a copy-pasteable Swift configuration snippet reflecting the current parameter settings, enabling developers to reproduce the exact analysis configuration in their code
- **FR41:** Demo app can export diagnostic trace data in a machine-readable format (JSON or CSV) for external plotting and analysis

### Documentation & Consumer Guidance

- **FR42:** Consumer can find quick-start code samples in the README
- **FR43:** Consumer can find documentation of nil-return conditions (when and why analysis returns nil)
- **FR44:** Consumer can find guidance on batch workflow patterns (cancellation, progress, task orchestration)
- **FR45:** All public API types and methods have inline `///` documentation

## Non-Functional Requirements

### Performance

- **NFR1:** Analysis at intensity 1-3 should feel instantaneous for interactive use cases (real-time BPM display while browsing)
- **NFR2:** Analysis at intensity 7 should complete fast enough for batch library import without the user perceiving individual track delays
- **NFR3:** Analysis at intensity 8-10 (ML) may take longer but should complete within a reasonable time for batch workflows
- **NFR4:** Performance benchmarks report wall-clock time alongside hardware context (chip, memory) so results are reproducible on the same hardware
- **NFR5:** Pipeline memory usage should not grow linearly with track duration -- scratch buffers are reused, not allocated per-stage
- **NFR6:** Downsampling and buffer reuse optimizations must not degrade accuracy (validated by ablation)

Performance thresholds (NFR1-3) will be quantified after baseline measurement in Phase 3A.

### Accuracy

- **NFR7:** Acc1 on the OA300 corpus must never decrease phase-over-phase (regression gate)
- **NFR8:** ML-augmented detection (intensity 8+) must be strictly >= DSP-only accuracy on every corpus run
- **NFR9:** Fine-grid precision errors on DAW oracle tracks should be resolved (sub-BPM accuracy)
- **NFR10:** LUFS measurement conforms to ITU-R BS.1770-5 with Double-precision K-weighting (no Float degradation)
- **NFR11:** Accuracy results are reported at both 2% (library standard) and 4% (MIREX-compatible) tolerance

### Compatibility & Constraints

- **NFR12:** `BoomBoomBoomKit` (intensity 1-7) adds zero framework dependencies beyond Foundation, Accelerate, and AVFoundation
- **NFR13:** `BoomBoomBoomKitML` adds only CoreML as an additional framework dependency
- **NFR14:** Swift 6.0 strict concurrency compliance -- no data races, all public types Sendable
- **NFR15:** macOS 15+ deployment target. iOS/iPadOS support is a future concern, not a Phase 3 constraint
- **NFR16:** All bulk numeric operations on audio buffers use Accelerate/vDSP -- no manual loops over sample data

### Code Quality

- **NFR17:** All new code passes `make fmt` + `make lint` before merging
- **NFR18:** All new DSP techniques are added to the ablation matrix
- **NFR19:** Existing test suite never regresses
- **NFR20:** IIR filter coefficients (K-weighting biquads) remain Double precision -- Float causes measurable errors

Note: Security, scalability, and accessibility categories are not applicable to this library and have been intentionally excluded.

## Glossary

Concise definitions of key technical terms used throughout this PRD. Grouped by category for both human readers and downstream AI agents.

### Evaluation Metrics

- **Acc1** -- accuracy within 2% tolerance of ground truth BPM. This is the library's standard, stricter than the MIREX 4% convention
- **Acc2** -- Acc1 OR octave/triplet-correct (allows factors of 2, 3, 1/2, 1/3)
- **MIREX** -- Music Information Retrieval Evaluation eXchange. Standard evaluation framework for MIR tasks including tempo estimation
- **mir_eval** -- Python library implementing MIREX metrics (tempo, beat, onset evaluation)

### DSP Pipeline

- **Mel-spectrogram** -- time-frequency representation using perceptual mel-scale frequency bins. Compresses high frequencies relative to low frequencies per human hearing (O'Shaughnessy 1987)
- **Autocorrelation (ACF)** -- self-correlation of a signal measuring periodicity strength across lag values. FFT-based implementation in BoomBoomBoomKit
- **Fourier tempogram** -- non-uniform DFT magnitude evaluated at each integer BPM over a windowed onset envelope (8-second Hann window)
- **Periodicity fusion** -- combines ACF (lag-domain) and tempogram (BPM-domain) via element-wise product of normalized representations. Peaks strong in both domains survive
- **Sub-band voting** -- per-frequency-band (kick/snare/crack/hi-hat) autocorrelation to resolve octave ambiguities through weighted voting
- **K-weighting** -- frequency-weighting curve (high-shelf + high-pass biquad cascade) per ITU-R BS.1770-5 for perceptual loudness measurement. Requires Double precision
- **Fine-grid refinement** -- scanning +/-0.5 BPM around candidates in 0.1 BPM steps via tempogram magnitude interpolation
- **Onset detection** -- detection of sound event beginnings in the mel-spectrogram, producing an onset strength envelope

### Error Classes

- **Octave error** -- detecting half or double the correct BPM (e.g., 87 instead of 174)
- **Triplet error** -- detecting BPM off by factors of 2/3 or 3/2 (e.g., 107.5 instead of 171)
- **Fine-grid error** -- sub-BPM precision errors (e.g., 125.9 instead of 126.0)

### Corpus & Validation

- **OA300** -- author's primary test corpus (82+ tracks, fast/complex electronic music). Named for OnsetAudio300 directory
- **GiantSteps Tempo** -- public 664-track EDM dataset with crowd-corrected tempo annotations from Beatport (ISMIR 2015). Uses 2-minute previews, not full tracks
- **DAW oracle** -- BPM verified by a Digital Audio Workstation (Bitwig), used as diagnostic ground truth alongside Rekordbox benchmark target
- **Ablation matrix** -- exhaustive test of all 2^N DSP technique combinations (currently 2^6 = 64). Gates every technique change before merging
- **Ground truth** -- the correct BPM for a track. Sourced from DAW oracle (highest confidence), Rekordbox (benchmark target), or manual review

### Frameworks

- **BNNS** -- Basic Neural Network Subroutines. Apple's neural network inference library inside Accelerate (zero new framework dependencies)
- **CoreML** -- Apple's machine learning framework for on-device inference. Enables Neural Engine acceleration on Apple Silicon
- **vDSP** -- Apple's vector digital signal processing framework inside Accelerate. All bulk numeric operations on audio buffers use vDSP
- **LUFS** -- Loudness Units relative to Full Scale. Standard integrated loudness measurement per ITU-R BS.1770-5
- **Neural Engine** -- Apple Silicon's dedicated ML acceleration hardware (up to ~10x faster than CPU for supported operations)
- **AMX** -- Apple Matrix eXtensions. Apple Silicon's matrix math accelerator, used by Accelerate for vectorized operations

### Library-Specific

- **Intensity scale** -- 1-10 parameter controlling DSP/ML technique selection and computational budget. Levels 1-7 are DSP-only; 8-10 add ML. Inspired by zlib compression levels
- **TechniqueSet** -- named configuration of multiple DSP techniques (e.g., `.optimal` = sharp+fine+vote, `.full` = all 6). `CaseIterable` for ablation
- **CandidateMergeStrategy** -- strategy for combining BPM candidates from multiple analysis windows (e.g., `maxConfidence`, `windowVoting`, `quorum`). 8 strategies, `CaseIterable`
- **BPMDiagnosticTrace** -- public struct capturing per-step pipeline intermediate state. Populated when `enableTrace: true`. Input to `MLTechnique.evaluate()`
- **MLTechnique** -- public protocol for ML-based BPM evaluation. Receives candidates + trace, returns optional alternative BPM estimate. Definition only, no conformances yet (Phase 3)
- **DSPTechnique** -- public enum (6 cases): `acfSharpening`, `adaptiveThreshold`, `subBandNormalization`, `expandedCandidates`, `fineGridRefinement`, `subBandVoting`

## References

### Academic & Standards

- [MIREX Audio Tempo Estimation](https://www.music-ir.org/mirex/wiki/2019:Audio_Tempo_Estimation) -- standard tempo evaluation task and metrics
- [mir_eval tempo.py](https://github.com/mir-evaluation/mir_eval/blob/main/mir_eval/tempo.py) -- reference implementation of tempo evaluation metrics (4% default tolerance)
- [Music Tempo Estimation: Are We Done Yet? (TISMIR)](https://transactions.ismir.net/articles/10.5334/tismir.43) -- survey of tempo estimation methods and evaluation critique
- [GiantSteps Tempo Dataset](https://github.com/GiantSteps/giantsteps-tempo-dataset) -- 664 EDM tracks with crowd-corrected annotations (Knees et al., ISMIR 2015)
- [Two Data Sets for Tempo Estimation (ISMIR 2015)](https://archives.ismir.net/ismir2015/paper/000246.pdf) -- original GiantSteps dataset publication

### Tools & Competitive

- [labrosa beat tracking](http://labrosa.ee.columbia.edu/projects/beattrack/) -- Ellis DP beat tracking (tempo2.m, beat2.m). Classic algorithm, relevant for future beat position output
- [librosa 1.0.0dev](https://github.com/librosa/librosa/tree/1.0.0dev) -- active development branch with new tempo estimation work
- [tagtraum/jipes](https://www.tagtraum.com/jipes/) -- Java audio analysis framework with signal processing pipelines. Architectural reference for pipeline composition patterns
