# BoomBoomBoomKit

Standalone audio analysis package for BPM estimation and LUFS loudness measurement. Pure Swift using Apple's Accelerate (vDSP) and AVFoundation frameworks — no external dependencies.

**Platform:** macOS 15+ | **Swift:** 6.0 | **Dependencies:** None (Apple system frameworks only)

> **Status:** Pre-1.0, no external consumers yet. The public API may evolve as the design matures; pin an exact tag or commit if you adopt early. Semantic-version stability begins at 1.0.

## Features

- **BPM Estimation** — Mel-spectrogram onset detection + autocorrelation-based beat tracking with progressive analysis, sub-band voting disambiguation, optional click-track cross-correlation rescoring, and optional file-tag corroboration
- **LUFS Measurement** — ITU-R BS.1770-5 integrated loudness with K-weighting filter and dual gating
- **PCM Reading** — Universal audio file reader producing mono `[Float]` samples (WAV, AIFF, MP3, FLAC, M4A, CAF)

## Installation

Add to your `Package.swift`:

```swift
// Pre-1.0: pin a specific revision or branch until 1.0 ships.
dependencies: [
    .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", branch: "main"),
]
```

For stricter reproducibility, pin to an exact commit:

```swift
dependencies: [
    .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", revision: "<commit-sha>"),
]
```

Then add `"BoomBoomBoomKit"` to your target's dependencies.

## Usage

```swift
import BoomBoomBoomKit
import Foundation

let audioFileURL = URL(fileURLWithPath: "/path/to/track.mp3")

do {
    let result = try AudioAnalysisService.analyzeBPM(url: audioFileURL)
    // nil = silence / too-short / no-candidates — see "When analyzeBPM returns nil" below.
    // Errors thrown: PCMBufferReaderError (file unreadable, etc.) or CancellationError.
    print("BPM: \(result?.bpm ?? 0)")
} catch {
    print("Analysis failed: \(error)")
}
```

A richer example showing custom options, diagnostic trace, LUFS, and direct PCM reads:

```swift
import BoomBoomBoomKit

// BPM with custom options (intensity + merge strategy)
var opts = AudioAnalysisService.Options()
opts.intensity = .thorough
opts.mergeStrategy = .windowVoting
let tunedResult = try AudioAnalysisService.analyzeBPM(url: audioFileURL, options: opts)

// BPM with diagnostic trace enabled
var tracedOpts = AudioAnalysisService.Options()
tracedOpts.enableTrace = true
let traced = try AudioAnalysisService.analyzeBPM(url: audioFileURL, options: tracedOpts)
// `result.trace` is non-nil only when enableTrace was set. Surfaces per-step intermediate state.
print("Pre-rescore candidates: \(traced?.trace?.rawCandidates ?? [])")
print("Sub-band energies: \(traced?.trace?.subBandEnergies ?? .zero)")

// LUFS Measurement (ITU-R BS.1770-5; 44.1/48/96 kHz only — returns nil otherwise)
let lufs = try AudioAnalysisService.analyzeLUFS(url: audioFileURL)
print("Loudness: \(lufs ?? 0) LUFS")

// Direct PCM reading (mono [Float] at native sample rate)
let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: audioFileURL)

// Partial read + downsampling
let (partial, rate) = try PCMBufferReader.readMonoSamples(
    from: audioFileURL, maxSeconds: 30, targetSampleRate: 22050)
```

### Customizing techniques

`AudioAnalysisService.Options.techniqueSet` overrides the technique set derived from
`intensity`, letting callers opt into public presets such as `.clickAugmented` (the
optimal pipeline plus click-track cross-correlation rescoring):

```swift
var opts = AudioAnalysisService.Options()
opts.techniqueSet = .clickAugmented   // sharp + vote + fine + click-correlation
let result = try AudioAnalysisService.analyzeBPM(url: audioFileURL, options: opts)
```

`intensity` is still consulted for window sizes and progressive-retry threshold, so
window behavior remains intensity-driven even when an explicit technique set is set.

## Intensity scale (1-10)

`AnalysisIntensity` is an ordinal control over pipeline depth: higher values never produce *less* accurate results at the same `Options`. The "Relative cost" column below sorts by per-track work — not by wall-clock — because measured wall-clock varies materially across hardware classes (the project's M5 Max baseline at intensity 7 is ~170 ms mean / ~245 ms p95 on a 3-min OA300 track; older M-series and Intel Macs will run materially slower). Run `make perf-benchmark` against your own corpus before pinning expectations.

| `rawValue` | Constant | Use case | Window sizes | Relative cost |
|-----------|----------|----------|--------------|---------------|
| `1` | `.fastest` | Interactive previewing | `[15]` | Very fast |
| `2` | — | Light analysis (baseline technique set, 3 candidates) | `[30]` | Fast |
| `3`-`5` | — | Standard analysis (optimal technique set, 3 candidates) | `[30]` | Standard |
| `6` | — | Standard + first progressive retry | `[30, 60]` | Standard |
| `7` | `.default` | Best DSP accuracy (progressive 30/60/90 s, threshold-gated retry) | `[30, 60, 90]` | Default — mean ~170 ms, p95 ~245 ms (M5 Max, 3-min OA300 track) |
| `8` | `.thorough` | Reserved for ML augmentation. Without `Options.mlTechnique`, falls through to level 7 with `degradationReason` set on the result. | `[30, 60, 90]` | Same as 7 when ML is absent |
| `9` | — | Reserved for ML quorum (future) | `[30, 60, 90]` | — |
| `10` | `.maximum` | Reserved for maximum-thoroughness ML (future) | `[30, 60, 90]` | — |

See the inline `///` docs on `AnalysisIntensity` for the authoritative mapping and the `degradationReason` semantics at levels 8-10.

## When `analyzeBPM` returns nil

`AudioAnalysisService.analyzeBPM(url:options:)` returns `AudioAnalysisResult?`. The common no-result and cancellation paths are documented below. Note the cancellation row: cancellation surfaces as a *throw*, not a `nil` — `try?` callers collapse both into `nil`.

| Condition | When it fires | What the caller sees | Mitigation |
|-----------|--------------|----------------------|------------|
| Silence | `BPMAnalyzer` step 2 RMS guard rejects below-threshold audio | `try analyzeBPM(url:)` returns `nil` | Check audio energy upstream; raise input gain if applicable. |
| Too-short audio | File contains fewer than ~4 analyzable seconds after the energy transition (the `BPMAnalyzer.minimumDurationSeconds` floor) | `try analyzeBPM(url:)` returns `nil` | Use a longer clip — at least a few seconds of continuous audio after any silent intro. |
| Unsupported sample rate | `analyzeLUFS` only — `LUFSAnalyzer` supports 44.1 / 48 / 96 kHz only | `try analyzeLUFS(url:)` returns `nil` | Resample to a supported rate before LUFS analysis. Does NOT affect `analyzeBPM`. |
| Cancelled analysis | Caller's `Task` was cancelled OR `Options.isCancelled` returned `true` between window iterations | `try analyzeBPM(url:)` **throws** `CancellationError`; `try?` collapses to `nil` | Distinguish explicitly via `do { try analyzeBPM(...) } catch is CancellationError { ... }` if cancellation needs differentiated handling. |
| No candidates found | Degenerate audio (white noise, sustained pitched material) produced zero surviving candidates after range normalization (step 9) | `try analyzeBPM(url:)` returns `nil` | Inspect with `enableTrace: true` and read `result?.candidates` (and `trace?.rawCandidates`); this is the rarest case. |

## Batch workflow patterns

The library is window-grained cancellable (between window iterations, never mid-window) and emits per-window progress via `Options.onProgress`. The three patterns below cover the cases most apps hit: sequential progress reporting, concurrent fan-out with cancellation, and preserving completed results when a batch is cancelled mid-flight.

### Sequential batch with progress callback

```swift
import BoomBoomBoomKit
import Foundation

func analyzeBatch(_ urls: [URL]) throws -> [URL: AudioAnalysisResult] {
    var results: [URL: AudioAnalysisResult] = [:]
    for url in urls {
        var opts = AudioAnalysisService.Options()
        opts.onProgress = { @Sendable update in
            print("[\(url.lastPathComponent)] \(update.windowsCompleted)/\(update.windowsTotal)")
        }
        if let result = try AudioAnalysisService.analyzeBPM(url: url, options: opts) {
            results[url] = result
        }
    }
    return results
}
```

### Concurrent batch with `TaskGroup` + cancellation

```swift
// Importing a user music library on background launch — fan out per track,
// cancel the whole batch if the user backgrounds the importer.
//
// Caller cancels via the outer Task: `importTask.cancel()`. The default
// isCancelled closure (`{ Task.isCancelled }`) propagates to each child
// analysis between window iterations.
func importLibrary(_ urls: [URL]) async throws -> [URL: AudioAnalysisResult] {
    try await withThrowingTaskGroup(of: (URL, AudioAnalysisResult?).self) { group in
        for url in urls {
            group.addTask {
                let result = try? AudioAnalysisService.analyzeBPM(url: url)
                return (url, result)
            }
        }
        var collected: [URL: AudioAnalysisResult] = [:]
        for try await (url, result) in group {
            if let result { collected[url] = result }
        }
        return collected
    }
}
```

### Preserving completed results when the batch is cancelled mid-flight

Cancelling the parent `Task` only stops *future* window iterations on each child analysis; completed analyses are preserved by accumulating into an `actor` rather than discarding mid-flight.

```swift
actor ImportAccumulator {
    private(set) var results: [URL: AudioAnalysisResult] = [:]
    func record(_ url: URL, _ result: AudioAnalysisResult) { results[url] = result }
}

func importLibraryPreservingProgress(_ urls: [URL]) async -> [URL: AudioAnalysisResult] {
    let accumulator = ImportAccumulator()
    await withTaskGroup(of: Void.self) { group in
        for url in urls {
            group.addTask {
                if let result = try? AudioAnalysisService.analyzeBPM(url: url) {
                    await accumulator.record(url, result)
                }
            }
        }
    }
    return await accumulator.results
}
```

## Commands

```bash
make help       # Show all available commands
make build      # Build the package
make test       # Run all tests
make fmt        # Format Swift source code
```

## Pipeline Architecture

```
PCMBufferReader → fan-out → BPMAnalyzer   (mel-spectrogram onset + autocorrelation)
                          → LUFSAnalyzer   (ITU-R BS.1770-5 K-weighted loudness)
```

- **Shared currency**: `[Float]` mono samples — all analyzers consume the same data
- **Stateless**: All types are structs/enums with static methods — no singletons, no global state
- **Zero dependencies**: Only Apple system frameworks (Foundation, Accelerate, AVFoundation)

## Public API

| Type | Role |
|------|------|
| `AudioAnalysisService` | Public facade composing reader + analyzers |
| `AudioAnalysisResult` | BPM + confidence + candidates + optional trace + optional metadata evidence |
| `PCMBufferReader` | Audio file → `[Float]` mono samples |
| `PCMBufferReaderError` | Error cases for file reading |
| `AnalysisIntensity` | Controls pipeline depth (1-10 ordinal scale) |
| `CandidateMergeStrategy` | How multi-window candidates are combined (8 strategies) |
| `DSPTechnique` | Individual DSP technique enum (closed set, `CaseIterable`) |
| `TechniqueSet` | Composable technique set with named presets (`.optimal`, `.clickAugmented`, `.full`, …) |
| `VotingPolicy` | Resolution policy for `mergeStrategy == .windowVoting` (3 cases) |
| `MetadataPolicy` | File-tag corroboration policy + parsing hygiene flags |
| `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio` | Metadata evidence types |
| `MLTechnique` | Protocol for ML-based BPM estimation (slot on `Options.mlTechnique`; backend-agnostic — Core ML, BNNSGraph, MLX, etc.). See "Using your own tempo model" + [MODEL_CARD.md](MODEL_CARD.md) |
| `MLEvaluation` | ML estimate carrier (`bpm`, `confidence`, optional `modelIdentifier`) |
| `EnsemblePolicy` | DSP + ML combiner policy (`.dspOnly` default, `.mlOnly`, `.highestConfidence`) |
| `EnsembleDecision` | Diagnostic record of the combiner outcome (`Winner` is `.dsp` / `.ml` / `.tie`) |
| `MLDiagnosticTechnique` | Opt-in capability protocol producing per-evaluation snapshots |
| `MLDiagnosticSnapshot` | Per-evaluation diagnostic carrier (decoded BPM, softmax top-2, checksum, failure stage) |
| `MLFeatureFrames` | Typed log-mel feature payload carried on the trace |
| `TensorLayout` | Tensor layout tag for `MLFeatureFrames` (`.frameMajorLogMel`, `.nchw`) |
| `MLTechniqueError` | Construction-time errors for ML conformers |
| `BPMDiagnosticTrace` | Per-step pipeline diagnostic state |
| `ProgressUpdate` | Per-window progress payload for the `Options.onProgress` callback |

## Test Support

`BoomBoomBoomKitTestSupport` provides shared test fixtures for consuming packages:

```swift
// In your test target's dependencies:
.product(name: "BoomBoomBoomKitTestSupport", package: "BoomBoomBoomKit")

// In test code:
import BoomBoomBoomKitTestSupport

let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
let clickTrack = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 10)
```

## Demo App

A SwiftUI macOS demo app under `Demo/BoomBoomBoomKitDemo/` exercises the public API end-to-end — file drop, BPM display, parameter controls, and a diagnostic-trace inspector with JSON export. It's a hands-on evaluation tool. Build with `make demo-build` (no code signing required) or open `Demo/BoomBoomBoomKitDemo/BoomBoomBoomKitDemo.xcodeproj` in Xcode. See [`Demo/BoomBoomBoomKitDemo/README.md`](Demo/BoomBoomBoomKitDemo/README.md) for App Store distribution prerequisites (bundle identity, archive workflow, privacy manifest, category decision).

## BPM Pipeline Steps

The DSP spine runs 9 unconditional steps. Two optional rescore stages and three post-disambiguation steps wrap it. Step numbers are stable identifiers — once a step number appears in a trace key or benchmark artifact, it does not move.

1. **Energy Scan** — Find energy transition to skip intros/silence
2. **Silence Check** — RMS threshold guard
3. **Mel-Spectrogram Onset** — STFT → 128-band mel filterbank → log compression → temporal differencing → half-wave rectification (with optional sub-band normalization)
4. **Adaptive Thresholding** — Per-frame onset peak picking (gated by `.adaptiveThreshold`)
5. **Autocorrelation** — vDSP-based lag analysis (with optional ACF sharpening)
6. **Fourier Tempogram** — Frequency-domain periodicity
7. **Periodicity Fusion** — Geometric mean of ACF + tempogram
8. **Peak Selection** — Top candidates from fused spectrum
9. **Range Normalization** — Constrain to 60-200 BPM

### Optional gated rescore stages

- **Step 9b — Click-track cross-correlation rescore** (gated by `.clickTrackCorrelation`): rescores candidate scores via normalized cross-correlation against a synthetic click pattern in onset-envelope space.
- **Step 9.7 — Duration-derived BPM hint** (gated by `Options.durationHint` AND file duration ≥ `Options.durationHintMinFileSeconds`): boosts candidates matching common bar-count BPMs (32, 64, 96, 128, 192, 256 bars).

### Post-disambiguation steps

- **Step 10 — Sub-band voting** (gated by `.subBandVoting`): octave disambiguation via per-band onset energy distribution.
- **Step 10b — Sub-band peak confirmation**: confirms the post-voting winner against its sub-band evidence.
- **Step 10c — Fine-grid refinement** (gated by `.fineGridRefinement`): high-resolution lag search around the winning candidate.

Progressive analysis (Multi-window at 30s / 60s / 90s with configurable `mergeStrategy`) wraps the whole pipeline at intensity 6+.

## Using your own tempo model

BoomBoomBoomKit's production BPM path is **DSP-first**. The default analysis pipeline does not require or enable ML, and on the project's regression corpora the DSP pipeline currently outperforms every model the project has trained (see [MODEL_CARD.md](MODEL_CARD.md) for measured comparisons).

The optional `BoomBoomBoomKitML` target adds an `MLTechnique` plug-in surface for consumers who want to **bring their own weights** (BYOW) and ensemble an on-device model with the DSP results — for example, if you have a domain-specific model trained on your own corpus that beats the DSP on your distribution. See [`tools/coreml-convert/README.md`](tools/coreml-convert/README.md) for the full PyTorch → CoreML conversion flow and the license-matrix for bundling third-party weights.

```swift
import BoomBoomBoomKit
import BoomBoomBoomKitML

var options = AudioAnalysisService.Options()

// Path A — same architecture, your own weights:
let yourModel = Bundle.main.url(forResource: "your_model", withExtension: "mlmodelc")!
options.mlTechnique = try? BNNSTechnique(modelURL: yourModel)

// Path B — different architecture, your own MLTechnique conformance:
options.mlTechnique = MyDeepRhythmTechnique()

// Ensemble policy is `.dspOnly` by default — explicit opt-in is required
// before MLTechnique.evaluate(trace:) is invoked. `.highestConfidence`
// returns whichever of DSP or ML self-reports a higher confidence; ML
// abstains (returns nil) fall back to DSP unchanged.
options.ensemblePolicy = .highestConfidence

let result = try AudioAnalysisService.analyzeBPM(url: trackURL, options: options)
```

**No reference model is bundled.** Story 4-6 (2026-05-16) removed the previously-bundled `giantsteps_v1.mlmodelc` from the main-shipping path because it abstained on 100% of OA300 audio at production thresholds — see [MODEL_CARD.md](MODEL_CARD.md) for the full Status section + threshold-sweep evidence. The `BNNSTechnique` infrastructure (load, featurize, inference, two-gate, diagnostic capability) is unchanged and ready to consume a higher-quality model when one is trained. Consumers using ML today must train or supply their own checkpoint.

To convert your own PyTorch checkpoint into a `.mlmodelc` consumable by `BNNSTechnique`, see the consumer-facing `tools/coreml-convert/` CLI (self-contained `uv` Python project). It supports the reference architecture (the one the historical `giantsteps_v1` was trained on) as well as fully custom architectures via your own `nn.Module` class.

## References

- Davies, M.E.P. & Plumbley, M.D. (2007). "Context-dependent beat tracking of musical audio"
- ITU-R BS.1770-5 — Algorithms to measure audio programme loudness
- O'Shaughnessy, D. (1987). Mel-frequency scale conversion
- Schreiber, H. & Müller, M. (2018). "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network" — architecture reference for the historical `giantsteps_v1` checkpoint (pulled from the bundle in Story 4-6; remains the reference architecture for BYOW)

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
