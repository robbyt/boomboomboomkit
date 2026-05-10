# BoomBoomBoomKit

Standalone audio analysis package for BPM estimation and LUFS loudness measurement. Pure Swift using Apple's Accelerate (vDSP) and AVFoundation frameworks — no external dependencies.

**Platform:** macOS 15+ | **Swift:** 6.0 | **Dependencies:** None (Apple system frameworks only)

## Features

- **BPM Estimation** — 10-step mel-spectrogram onset detection + autocorrelation-based beat tracking with progressive analysis, sub-band voting disambiguation, and optional click-track cross-correlation rescoring
- **LUFS Measurement** — ITU-R BS.1770-5 integrated loudness with K-weighting filter and dual gating
- **PCM Reading** — Universal audio file reader producing mono `[Float]` samples (WAV, AIFF, MP3, FLAC, M4A, CAF)

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/robbyt/BoomBoomBoomKit.git", from: "1.0.0"),
]
```

Then add `"BoomBoomBoomKit"` to your target's dependencies.

## Usage

```swift
import BoomBoomBoomKit

// BPM Analysis (default: progressive at 30s/60s/90s windows, .optimal pipeline)
let result = try AudioAnalysisService.analyzeBPM(url: audioFileURL)
print("BPM: \(result?.bpm ?? 0), Confidence: \(result?.confidence ?? 0)")

// BPM with custom options (intensity + merge strategy)
var opts = AudioAnalysisService.Options()
opts.intensity = .thorough
opts.mergeStrategy = .windowVoting
let tunedResult = try AudioAnalysisService.analyzeBPM(url: audioFileURL, options: opts)

// BPM with diagnostic trace enabled
var tracedOpts = AudioAnalysisService.Options()
tracedOpts.enableTrace = true
let traced = try AudioAnalysisService.analyzeBPM(url: audioFileURL, options: tracedOpts)
print("Candidates: \(traced?.candidates ?? [])")

// LUFS Measurement (ITU-R BS.1770-5)
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

## Commands

```bash
make help       # Show all available commands
make build      # Build the package
make test       # Run all tests
make fmt        # Format Swift source code
make clean      # Remove build artifacts
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
| `AudioAnalysisResult` | BPM + confidence + candidates + optional trace |
| `PCMBufferReader` | Audio file → `[Float]` mono samples |
| `PCMBufferReaderError` | Error cases for file reading |
| `AnalysisIntensity` | Controls pipeline depth (1-10 ordinal scale) |
| `CandidateMergeStrategy` | How multi-window candidates are combined (8 strategies) |
| `DSPTechnique` | Individual DSP technique enum (closed set, `CaseIterable`) |
| `TechniqueSet` | Composable technique set with named presets (`.optimal`, `.clickAugmented`, `.full`, …) |
| `MLTechnique` | Protocol for ML-based BPM estimation (slot on `Options.mlTechnique`; backend-agnostic — Core ML, BNNSGraph, MLX, etc.). See "Optional ML Models" section + [MODEL_CARD.md](MODEL_CARD.md) |
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

## BPM Pipeline Steps

1. **Energy Scan** — Find energy transition to skip intros/silence
2. **Silence Check** — RMS threshold guard
3. **Mel-Spectrogram Onset** — STFT → 128-band mel filterbank → log compression → temporal differencing → half-wave rectification
4. **Autocorrelation** — vDSP-based lag analysis
5. **Fourier Tempogram** — Frequency-domain periodicity
6. **Periodicity Fusion** — Geometric mean of ACF + tempogram
7. **Peak Selection** — Top candidates from fused spectrum
8. **Range Normalization** — Constrain to 60-200 BPM
9. **Octave Disambiguation** — Sub-band voting resolves 2:1 ambiguity
10. **Progressive Analysis** — Multi-window analysis at 30s/60s/90s with configurable merge strategy

## Optional ML Models (advanced, opt-in only)

BoomBoomBoomKit's production BPM path is **DSP-first**. The default analysis pipeline does not require or enable ML, and on the project's regression corpora the DSP pipeline currently outperforms every model the project has trained (see [MODEL_CARD.md](MODEL_CARD.md) for measured comparisons).

The optional `BoomBoomBoomKitML` target adds an `MLTechnique` plug-in surface for consumers who want to **bring their own tempo classifier** (BYOM) and ensemble it with the DSP results — for example, if you have a domain-specific model trained on your own corpus that beats the DSP on your distribution.

```swift
import BoomBoomBoomKit
import BoomBoomBoomKitML

var options = AudioAnalysisService.Options()

// Path A — same architecture, your own weights:
let yourModel = Bundle.main.url(forResource: "your_model", withExtension: "mlmodelc")!
options.mlTechnique = try? BNNSTechnique(modelURL: yourModel)

// Path B — different architecture, your own MLTechnique conformance:
options.mlTechnique = MyDeepRhythmTechnique()

let result = try await AudioAnalysisService.analyzeBPM(url: trackURL, options: options)
```

**A small reference model is bundled** at `Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc/` to validate the adapter pipeline end-to-end and provide a known tensor/metadata contract for BYOM workflows. **It is not a recommended accuracy default** — on the held-out OA300 corpus it scores 39.0% within ±2% BPM tolerance, while the DSP pipeline scores 70.7% on the same corpus + tolerance. See [MODEL_CARD.md](MODEL_CARD.md) for the full per-model accuracy table, known failure modes (bin collapse, half-tempo doubling on slow material), and guidance on when to enable ML vs stick with DSP-only.

To convert your own PyTorch checkpoint into a `.mlmodelc` consumable by `BNNSTechnique`, see the consumer-facing `tools/coreml-convert/` CLI (self-contained `uv` Python project; no need to clone the dev-only training pipeline). It supports the bundled reference architecture as well as fully custom architectures via your own `nn.Module` class.

## References

- Davies, M.E.P. & Plumbley, M.D. (2007). "Context-dependent beat tracking of musical audio"
- ITU-R BS.1770-5 — Algorithms to measure audio programme loudness
- O'Shaughnessy, D. (1987). Mel-frequency scale conversion
- Schreiber, H. & Müller, M. (2018). "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network" — architecture reference for the bundled `giantsteps_v1` model

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
