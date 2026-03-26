# BoomBoomBoomKit

Standalone audio analysis package for BPM estimation and LUFS loudness measurement. Pure Swift using Apple's Accelerate (vDSP) and AVFoundation frameworks — no external dependencies.

**Platform:** macOS 15+ | **Swift:** 6.0 | **Dependencies:** None (Apple system frameworks only)

## Features

- **BPM Estimation** — 12-step mel-spectrogram onset detection + autocorrelation-based beat tracking with progressive analysis and sub-band voting disambiguation
- **LUFS Measurement** — ITU-R BS.1770-5 integrated loudness with K-weighting filter and dual gating
- **PCM Reading** — Universal audio file reader producing mono `[Float]` samples (WAV, AIFF, MP3, FLAC, M4A, AAC, OGG)

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

// BPM Analysis (progressive: retries at 30s/60s/90s windows)
let bpmResult = try AudioAnalysisService.analyzeBPM(url: audioFileURL)
print("BPM: \(bpmResult?.bpm ?? 0), Confidence: \(bpmResult?.confidence ?? 0)")

// BPM with explicit disambiguation strategy
let result = try AudioAnalysisService.analyzeBPM(
    url: audioFileURL, strategy: .subBandVoting)

// LUFS Measurement (ITU-R BS.1770-5)
let lufs = try AudioAnalysisService.analyzeLUFS(url: audioFileURL)
print("Loudness: \(lufs ?? 0) LUFS")

// Direct PCM reading (mono [Float] at native sample rate)
let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: audioFileURL)

// Partial read + downsampling
let (partial, rate) = try PCMBufferReader.readMonoSamples(
    from: audioFileURL, maxSeconds: 30, targetSampleRate: 22050)
```

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
| `AudioAnalysisResult` | BPM + confidence + candidates |
| `PCMBufferReader` | Audio file → `[Float]` mono samples |
| `PCMBufferReaderError` | Error cases for file reading |
| `AnalysisIntensity` | Controls pipeline depth (1-10 ordinal scale) |
| `DSPTechnique` | Individual DSP technique enum (6 cases) |
| `TechniqueSet` | Composable technique set with named presets |
| `MLTechnique` | Protocol for future ML-based estimation |
| `BPMDiagnosticTrace` | Per-step pipeline diagnostic state |

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
10. **Progressive Analysis** — Retry at 30s/60s/90s windows if confidence < 0.40

## References

- Davies, M.E.P. & Plumbley, M.D. (2007). "Context-dependent beat tracking of musical audio"
- ITU-R BS.1770-5 — Algorithms to measure audio programme loudness
- O'Shaughnessy, D. (1987). Mel-frequency scale conversion

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
