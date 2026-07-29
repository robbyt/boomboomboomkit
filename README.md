# BoomBoomBoomKit

Standalone audio analysis package for BPM estimation and LUFS loudness measurement. Pure Swift using Apple's Accelerate (vDSP) and AVFoundation frameworks — no external dependencies.

**Platform:** macOS 15+ | **Swift:** 6.0 | **Dependencies:** None (Apple system frameworks only)

> **Status:** Pre-1.0, no external consumers yet. The public API may evolve as the design matures; pin an exact tag or commit if you adopt early. Semantic-version stability begins at 1.0.

## Features

- **BPM Estimation** — Mel-spectrogram onset detection + autocorrelation-based beat tracking with progressive analysis, sub-band voting disambiguation, optional click-track cross-correlation rescoring, and optional file-tag corroboration
- **LUFS Measurement** — chart-ready `LUFSReport`: ITU-R BS.1770-5 integrated loudness + max true-peak (Annex 2 polyphase), EBU Tech 3342 loudness range, and momentary/short-term time series on the 100ms EBU Tech 3341 grid
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

// LUFS Measurement (ITU-R BS.1770-5; 44.1/48/96 kHz — throws LUFSAnalysisError otherwise)
if let report = try AudioAnalysisService.analyzeLUFS(url: audioFileURL) {
  print("Integrated: \(report.integratedLUFS) LUFS, true peak: \(report.maxTruePeakDBTP) dBTP")
}

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

`intensity` is still consulted for the window sizes, so how many windows run and how
long each one is remains intensity-driven even when an explicit technique set is set.

## Intensity scale (1-10)

`AnalysisIntensity` is an ordinal control over pipeline depth: higher values never produce *less* accurate results at the same `Options`. The "Relative cost" column below sorts by per-track work — not by wall-clock — because measured wall-clock varies materially across hardware classes (the project's M5 Max baseline at intensity 7 is ~170 ms mean / ~245 ms p95 on a 3-minute track; older M-series and Intel Macs will run materially slower). Run `make perf-benchmark` against your own corpus before pinning expectations.

| `rawValue` | Constant | Use case | Window sizes | Relative cost |
|-----------|----------|----------|--------------|---------------|
| `1` | `.fastest` | Interactive previewing | `[15]` | Very fast |
| `2` | — | Light analysis (baseline technique set, 3 candidates) | `[30]` | Fast |
| `3`-`5` | — | Standard analysis (optimal technique set, 3 candidates) | `[30]` | Standard |
| `6` | — | Standard, plus a second 60 s window whose result is merged | `[30, 60]` | Standard |
| `7` | `.default` | Best DSP accuracy (three merged windows at 30/60/90 s) | `[30, 60, 90]` | Default — mean ~170 ms, p95 ~245 ms (M5 Max, 3-minute track) |
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
| Unsupported sample rate | `analyzeLUFS` only — K-weighting coefficients ship for 44.1 / 48 / 96 kHz only | `try analyzeLUFS(url:)` **throws** `LUFSAnalysisError.unsupportedSampleRate` | Resample to a supported rate before LUFS analysis. Does NOT affect `analyzeBPM`. |
| Cancelled analysis | Caller's `Task` was cancelled OR `Options.isCancelled` returned `true` between window iterations | `try analyzeBPM(url:)` **throws** `CancellationError`; `try?` collapses to `nil` | Distinguish explicitly via `do { try analyzeBPM(...) } catch is CancellationError { ... }` if cancellation needs differentiated handling. |
| No candidates found | Degenerate audio (white noise, sustained pitched material) produced zero surviving candidates after range normalization (step 9) | `try analyzeBPM(url:)` returns `nil` | Inspect with `enableTrace: true` and read `result?.candidates` (and `trace?.rawCandidates`); this is the rarest case. |

## LUFS measurement

`analyzeLUFS(url:options:)` returns a `LUFSReport?` carrying both the normative scalars and chart-ready time series:

- `integratedLUFS` — programme loudness per ITU-R BS.1770-5 (400ms gating blocks, −70 LUFS absolute / −10 LU relative gates). Analyzes the **full file by default** (integrated loudness is whole-programme by definition); bound the cost with `LUFSOptions.maxSeconds`.
- `maxTruePeakDBTP` — max true-peak per BS.1770-5 Annex 2 polyphase oversampling (4× at 44.1/48 kHz, 2× at 96 kHz). Computed post-mono-mixdown: it may **understate** per-channel inter-sample peaks, so do not use it to certify delivery compliance against a per-channel ceiling.
- `loudnessRangeLU` + `lraLowLUFS`/`lraHighLUFS` — EBU Tech 3342 loudness range (P95 − P10 of the gated short-term distribution) with the percentile band edges for charting. `nil` below 60s of gated programme (EBU R 128 reliability floor).
- `momentaryLUFS` (400ms window) and `shortTermLUFS` (exact 3.0s window) — both stepped on the shared 100ms grid per EBU Tech 3341 §2.2. Element `i` starts at `Double(i) * stepSeconds`.

Errors vs nil: a **throw** means the measurement could not run (`PCMBufferReaderError` for unreadable files, `LUFSAnalysisError.unsupportedSampleRate` for rates outside 44.1/48/96 kHz); **`nil`** means the audio was measured but produced no result (all-silence after gating, or under 400ms of input).

### Charting the loudness shape

`LUFSReport.samples` flattens both series into `(time, lufs, series)` points — Swift Charts plots it directly. Use the classic `ForEach` + `LineMark` form; the vectorized `LinePlot(x:y:series:)` initializer is known to overwhelm the preview type-checker on this shape:

```swift
import Charts
import SwiftUI

struct LoudnessChart: View {
  let report: LUFSReport
  // Materialize once — `samples` is O(n) computed, not stored.
  private var points: [LoudnessSample] { report.samples }

  var body: some View {
    Chart {
      if report.loudnessRangeLU != nil {
        RectangleMark(
          yStart: .value("LRA low", report.lraLowLUFS),
          yEnd: .value("LRA high", report.lraHighLUFS)
        )
        .foregroundStyle(.green.opacity(0.12))
      }
      ForEach(points) { sample in
        LineMark(
          x: .value("Time", sample.time),
          y: .value("LUFS", sample.lufs)
        )
        .foregroundStyle(by: .value("Series", sample.series.rawValue))
      }
      RuleMark(y: .value("Integrated", report.integratedLUFS))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 3]))
    }
    .chartXAxisLabel("Time (s)")
    .chartYAxisLabel("LUFS")
  }
}
```

## Shared decode

Use `analyzeFull(url:)` when an app needs BPM, beat-grid, and loudness for one
file. It decodes once, keeps URL-backed BPM metadata corroboration active, and
returns independent feature outcomes:

```swift
let full = try AudioAnalysisService.analyzeFull(url: audioFileURL)

if let rhythm = full.bpmAndBeatGrid {
  print("BPM: \(rhythm.bpm.bpm)")
}
switch full.loudness {
case .success(let report):
  print("LUFS: \(report?.integratedLUFS ?? -100)")
case .failure(let error):
  // BPM/grid may still be usable; this failure is loudness-specific.
  print("Loudness unavailable: \(error)")
}
```

`bpmAndBeatGrid == nil` means the BPM stage found no rhythmic result; it does
not discard a successful loudness report. Conversely, an unsupported loudness
rate appears as `loudness.failure` and does not discard BPM/grid. Reader and
cancellation failures still throw from `analyzeFull`.

For lower-level composition, `analyzeBPM(url:)` and `analyzeLUFS(url:)` each
pay their own decode. Decode once and hand the same `DecodedAudio` to both when
you explicitly want the URL-free decoded path:

```swift
let decoded = try PCMBufferReader.readDecodedAudio(from: url)
let bpm = try AudioAnalysisService.analyzeBPM(decoded: decoded)
let loudness = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
```

On decode-heavy formats (MP3, FLAC) this recovers roughly the full cost of one decode — about a third of the combined sequential wall-clock; for uncompressed payloads (WAV/AIFF) decode is trivial and the saving is small.

What you need to know about the decoded path:

- **URL-bound signals are off by design.** File-metadata BPM corroboration never runs (there is no URL to read tags from — `metadataEvidence` is always empty), and the duration-derived BPM hint is off (it is not derived from `samples.count`, which would be wrong for a capped decode). Under `metadataPolicy = .disabled` + `durationHint = false`, decoded-path output is regression-locked equal to the url path on linear-PCM and FLAC fixtures — verified by tests, not guaranteed by the platform (Apple documents no bit-stability contract for `AVAudioFile`).
- `Options.maxSeconds` / `LUFSOptions.maxSeconds` still apply on the decoded path, as a prefix slice that mirrors the reader's partial-read cap arithmetic bit-for-bit.
- `DecodedAudio.codecPriming` carries content-true provenance: the codec comes from the encoded on-disk format (an ALAC `.m4a` reads `.alac`, not `.aac`), and `trimState` is honest about priming — `.knownNone` only for linear PCM; `.unknown` for every compressed codec (the decoder either already trimmed declared priming, or a headerless stream leaked it undetectably). Nothing in the analysis pipeline branches on provenance — it is forensic context, not configuration.
- `analyzeLUFS` (both paths) supports cooperative cancellation via `LUFSOptions.isCancelled`, checked before decode and before measurement; an in-flight measurement runs to completion.

## Beat grid

`BeatGrid` is the typed result container for beat extraction: the detected beats, a tri-state downbeat outcome, the grid's own tempo estimate, an overall confidence, an extrapolation **anchor**, what span the beats cover, and how that tempo relates to the BPM stage.

```swift
public struct BeatGrid: Sendable, Hashable, Codable, CustomStringConvertible {
  public let beats: [BeatTimestamp]          // each beat's time + confidence + strength
  public let downbeats: DownbeatResult       // .notAttempted / .noneDetected / .detected(estimate:)
  public let estimatedTempo: Double          // BPM; 0.0 is the "no valid estimate" sentinel
  public let confidence: Float               // [0, 1]
  public let tempoAgreement: TempoAgreement  // .notCompared / .agree / .octaveEquivalent / .disagree
  public let gridOrigin: BeatGridAnchor?     // the Rekordbox-style extrapolation anchor (nil if no beats)
  public let coverage: BeatGridCoverage      // .analysisWindow / .window(seconds:) / .fullTrack
  public let schemaVersion: Int              // persisted-shape semantic-contract version (currentSchemaVersion)
}
```

`schemaVersion` stamps the persisted `BeatGrid` *semantic* contract (the `confidence` formula, the time/tempo provenance, the enum meanings) — not backwards compatibility, and not cache protection. If you cache a raw `BeatGrid`, compare its `schemaVersion` against `BeatGrid.currentSchemaVersion` (or the version your cache was written under) and re-index on a mismatch; the library decodes any version faithfully and never migrates old grids.

### Extrapolate from the anchor — don't trust every beat

For beat math (continuous sync, sub-beat quantize), anchor on `gridOrigin` and extrapolate the grid rather than trusting each entry of `beats`:

```swift
// n-th beat after the anchor — drift-free on constant-tempo material:
let t = anchor.presentationTime + (60.0 / grid.estimatedTempo) * Double(n)
```

`gridOrigin` is the single most-trustworthy reference beat, chosen by **phase consistency** (how well its neighbors line up to `time + k·period`), not by raw onset strength or "first beat". The dynamic-programming tracker can occasionally drop or double a beat, which corrupts sub-beat midpoints and accumulates sync error if you trust the whole array; the anchor + tempo is drift-free by construction on constant tempo. This is why `coverage` defaults to `.analysisWindow` (the beats span only the analysis window, at zero extra cost) — the anchor + tempo already covers mid-track positions. Request `.window(seconds:)` or `.fullTrack` (a second, O(track) onset pass) only when you actually need the detected-beat array across the file, e.g. for a waveform overlay.

### Tempo agreement

`TempoAgreement` reports how the grid tempo relates to the BPM stage — distinguishing a clean octave error (87 vs 174 BPM, still syncable by halving/doubling) from genuine disagreement (120 vs 137 BPM, reject):

```swift
public enum TempoAgreement: Sendable, Hashable, Codable {
  case notCompared                   // standalone grid (no BPM result compared)
  case agree                         // within ~2% relative
  case octaveEquivalent(factor: Int) // +2 = grid ≈ 2× bpm, -2 = grid ≈ ½× bpm
  case disagree                      // neither — do not auto-sync
}
```

It is `.notCompared` for a standalone `analyzeBeatGrid`; it is resolved only by the combined `analyze` entry point, which compares the grid against the full multi-window BPM result. Both raw tempos stay accessible (`result.bpm.bpm` and `result.beatGrid?.estimatedTempo`) so you can reconcile an octave case yourself.

### Combined BPM + beat grid over one decode

```swift
import BoomBoomBoomKit

if let result = try AudioAnalysisService.analyze(url: fileURL) {
    print("\(result.bpm.bpm) BPM")
    if let grid = result.beatGrid {
        switch grid.tempoAgreement {
        case .agree:                       autoSync(to: grid)
        case .octaveEquivalent(let f):     autoSync(to: grid, octaveFactor: f)
        case .disagree, .notCompared:      askForManualConfirmation()
        }
    }
}
```

`analyze` decodes once and runs both the full BPM pipeline and beat-grid extraction over that single decode — cheaper than calling `analyzeBPM` and `analyzeBeatGrid` separately. Use `analyzeFull` when loudness is also needed. `analyzeBeatGrid` remains available standalone:

```swift
let grid = try AudioAnalysisService.analyzeBeatGrid(url: fileURL)   // pays its own decode
```

`DownbeatResult` is deliberately tri-state so a consumer can tell "downbeat detection never ran" (`.notAttempted`) apart from "it ran and found nothing" (`.noneDetected`) apart from "it found a downbeat" (`.detected(estimate:)`). Every float field is clamped finite at construction (and on `Codable` decode), so the value types are soundly `Hashable`; gate tempo validity with `estimatedTempo > 0`.

### Downbeats (opt-in)

Downbeat detection is **off by default** (`downbeats` is `.notAttempted`). Set `Options.detectDownbeats = true` and `analyzeBeatGrid` / `analyze` run a conservative, fixed-4/4 downbeat-**phase** estimator: it estimates *which* beat-in-bar is beat 1 for percussive, constant-tempo, common-time music, and **abstains** (`.noneDetected`) when the rhythmic evidence is weak. A wrong downbeat on a live deck is worse than no downbeat, so it would rather say nothing than guess — gate bar-snap on `gridOrigin.source == .downbeat`.

```swift
public struct DownbeatEstimate: Sendable, Hashable, Codable {
  public let beats: [BeatTimestamp]   // the downbeat beats (bar starts), in order
  public let meter: MeterEstimate     // { beatsPerBar: 4, source: .assumed }
  public let confidence: Float        // [0, 1]
  public let phaseIndex: Int          // which beat-in-bar (0..<beatsPerBar) is the downbeat
}
```

On a confident detection `gridOrigin` is repointed to the first downbeat (`source == .downbeat`), so you can extrapolate bar lines:

```swift
var options = AudioAnalysisService.Options()
options.detectDownbeats = true
if let grid = try AudioAnalysisService.analyzeBeatGrid(url: fileURL, options: options),
   case .detected(let estimate) = grid.downbeats,
   let firstDownbeat = estimate.beats.first {
    let barSeconds = 60.0 / grid.estimatedTempo * Double(estimate.meter.beatsPerBar)
    // k-th bar start after the first downbeat (constant tempo):
    let barStart = firstDownbeat.presentationTime + barSeconds * Double(k)
}
```

The meter is **assumed** 4/4, not measured (`meter.source == .assumed`); non-4/4 meter detection and per-beat bar positions are out of scope. It assumes a constant tempo (like the beat tracker).

### Timestamp contract — decoded-PCM-relative

Beat and anchor `presentationTime`s are **relative to the decoded-PCM origin**: `t = 0` is the start of the file as decoded, energy-scan drop included, with **no codec-priming subtraction**. Two consumers that decode the same file through AVFoundation share this origin, so the grid lines up with their own playback clock without per-codec offset guesswork.

- **Lossless** input (WAV, FLAC, AIFF, CAF-LPCM) → sample-exact alignment.
- **Lossy** input (MP3, AAC) → aligned to *our* AVFoundation decode. A different decoder may differ by an undetectable encoder delay. The worst-case bound is AAC's ~2112-sample encoder priming (≈ **48 ms at 44.1 kHz**) *if a decoder does not trim it*; in practice AVFoundation pre-trims declared priming, so the practical offset is near zero. That near-zero is empirical, not a published platform guarantee, and a precise figure awaits a future release — treat the ~48 ms as a documented upper bound, not a promise.

**Applying your own offset.** For output-device latency compensation, a manual nudge, or a residual offset on an exotic headerless stream, use `BeatGrid.offset(by:)` — a non-destructive copy that shifts every beat, every detected downbeat, and the `gridOrigin` uniformly (a negative shift that would cross zero is clamped as a single delta, so beat spacing is preserved). Source the value from your own runtime (e.g. `AVAudioEngine.outputLatency`); do **not** subtract codec priming yourself — AVFoundation already removes it, so a manual priming subtraction would double-correct.

`confidence` is `0.5·meanOnsetStrength + 0.5·acfStrengthAtPeriod` (half "how strong are the beats we picked", half "how periodic is the signal at the tracked tempo"); `BeatGridAnchor.confidence` is the anchor beat's per-beat confidence. Treat these as stability contracts — compose thresholds (e.g. a `0.5` floor) against them.

`analyze` / `analyzeBeatGrid` return `nil` for silence, too-short, or non-musical input — the same contract as `analyzeBPM`.

The beat-tracker assumes a **constant tempo**: it fixes beat phase against a single tempo and does not detect or adapt to tempo changes (accelerando, rubato, tempo-change sections). On variable-tempo material the beats hold a near-constant spacing and drift out of phase with the music — supply constant-tempo audio for a meaningful grid. Variable-tempo tracking is not planned.

### Accuracy

Beat-position accuracy is measured as the standard MIR beat **F-measure** (±70 ms tolerance) of the extrapolated grid against a reference beat grid exported from DJ software, over a real-world, constant-tempo drum & bass corpus, with tempo-octave equivalence allowed (a half- or double-time grid is not penalized). The current mean F-measure is **≈ 0.37**, with a committed regression floor of **0.33** that the test suite enforces.

This is honest about the present state: agreement with an auto-analyzed DJ-software reference on heavily-produced, real-world material is moderate, and the figure reflects fine tempo and phase disagreements that accumulate across a track rather than gross errors. The opt-in downbeat detector is **deliberately conservative** — it abstains on the large majority of tracks and, when it does commit to a bar phase, its agreement with the reference is itself moderate, so treat a detected downbeat as a hint, not a guarantee. Prefer the anchor + tempo extrapolation for sync, gate on `confidence`, and validate against your own material before relying on the grid for beat-critical work.

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
| `AudioAnalysisService` | Public facade composing reader + analyzers (`analyzeBPM`, `analyzeLUFS`, `analyzeBeatGrid`, combined `analyze`, and one-decode `analyzeFull`) |
| `AudioAnalysisResult` | BPM + confidence + candidates + optional trace + optional metadata evidence |
| `PCMBufferReader` | Audio file → `[Float]` mono samples |
| `PCMBufferReaderError` | Error cases for file reading |
| `AnalysisIntensity` | Controls pipeline depth (1-10 ordinal scale) |
| `BPMSelectionPolicy` | How multi-window candidates are combined (8 strategies) |
| `DSPTechnique` | Individual DSP technique enum (closed set, `CaseIterable`) |
| `TechniqueSet` | Composable technique set with named presets (`.optimal`, `.clickAugmented`, `.full`, …) |
| `VotingPolicy` | Resolution policy for `mergeStrategy == .windowVoting` (3 cases) |
| `MetadataPolicy` | File-tag corroboration policy + parsing hygiene flags |
| `MetadataSource`, `MetadataBPMEvidence`, `HarmonicRatio` | Metadata evidence types |
| `MLTechnique` | Protocol for ML-based BPM estimation (slot on `Options.mlTechnique`; backend-agnostic — Core ML, BNNSGraph, MLX, etc.). See "Using your own tempo model" + "Model contract for `BNNSTechnique`" |
| `MLEvaluation` | ML estimate carrier (`bpm`, `confidence`, optional `modelIdentifier`) |
| `EnsemblePolicy` | DSP + ML combiner policy (5 cases: `.default`, `.dspOnly` default, `.mlOnly`, `.highestConfidence`, `.weightedVoting(SignalWeights)`) |
| `SignalWeights` | Per-source weights for `EnsemblePolicy.weightedVoting` (`dsp` / `ml` / `fileMetadata` / `beatGrid`; `.default` = equal weighting) |
| `EnsembleDecision` | Diagnostic record of the combiner outcome (`Winner` is `.dsp` / `.ml` / `.tie`) |
| `MLDiagnosticTechnique` | Opt-in capability protocol producing per-evaluation snapshots |
| `MLDiagnosticSnapshot` | Per-evaluation diagnostic carrier (decoded BPM, softmax top-2, checksum, failure stage) |
| `MLFeatureFrames` | Typed log-mel feature payload carried on the trace |
| `TensorLayout` | Tensor layout tag for `MLFeatureFrames` (`.frameMajorLogMel`, `.nchw`) |
| `MLTechniqueError` | Construction-time errors for ML conformers |
| `BPMDiagnosticTrace` | Per-step pipeline diagnostic state |
| `ProgressUpdate` | Per-window progress payload for the `Options.onProgress` callback |
| `LUFSReport` | Chart-ready loudness report (integrated, true peak, LRA + band edges, momentary/short-term series) |
| `LoudnessSample`, `LoudnessSeries` | Foundation-only plotting adapter for `LUFSReport.samples` |
| `LUFSOptions` | Options for `analyzeLUFS` (`maxSeconds`; default nil = full file; `isCancelled` cooperative-cancellation closure) |
| `LUFSAnalysisError` | Thrown for unsupported sample rates (44.1/48/96 kHz ship) |
| `BeatGrid` | Typed beat-grid result container (beats, downbeats, tempo, confidence, `gridOrigin` anchor, `coverage`, `tempoAgreement`) returned by `analyzeBeatGrid` / `analyze`; see "Beat grid" |
| `BeatTimestamp` | One detected beat: `presentationTime` + per-beat `confidence` + `strength` (all clamped finite) |
| `BeatGridAnchor` / `BeatGridAnchorSource` | The Rekordbox-style extrapolation anchor on `BeatGrid.gridOrigin` (phase-consistency selected) + its provenance |
| `BeatGridCoverage` | What span the detected `beats` cover (`.analysisWindow` default / `.window(seconds:)` / `.fullTrack`); set via `Options.beatGridCoverage` |
| `TempoAgreement` | How the grid tempo relates to the BPM stage (`.notCompared` / `.agree` / `.octaveEquivalent(factor:)` / `.disagree`) |
| `CombinedAnalysisResult` | BPM + beat grid over one shared decode, returned by `AudioAnalysisService.analyze(url:options:)` / `analyze(decoded:options:)` |
| `FullAnalysisResult` | Independent BPM/grid and loudness outcomes from `AudioAnalysisService.analyzeFull(url:options:lufsOptions:)` |
| `DownbeatResult` | Tri-state downbeat outcome (`.notAttempted` / `.noneDetected` / `.detected(estimate:)`) |
| `DownbeatEstimate` | The `.detected` payload: the downbeat beats, `meter`, `confidence`, and `phaseIndex` (opt-in via `Options.detectDownbeats`) |
| `MeterEstimate` / `MeterSource` | The assumed-or-detected meter on a `DownbeatEstimate` (always `{ beatsPerBar: 4, source: .assumed }` today) |
| `FeatureSubstrate.DecodedAudio` | Decoded mono PCM carrier for the shared-decode seam (see "Shared decode") |
| `FeatureSubstrate.PrimingInfo`, `FeatureSubstrate.AudioCodec`, `FeatureSubstrate.TrimState` | Content-true codec + trim-state provenance carried on `DecodedAudio.codecPriming` |
| `BeatGridTempoLock` | Manual tempo override for the grid stage (`.bpm(_:)` payload). Not `Hashable` — the payload can be `NaN` |
| `BeatGridAnchorRepositionMode` | Manual anchor override, the positional counterpart to `BeatGridTempoLock` |
| `DownbeatStrategy` | Which downbeat detector runs when `Options.detectDownbeats` is set. `CaseIterable` for the acceptance benchmark |
| `ModelRegistryEntry` / `ModelCapability` | Registry describing an available model and what it can do; see "Model registry" |
| `DocumentedCase` / `BoomBoomBoomKitDocs` | Per-case documentation lookup. `BoomBoomBoomKitDocs` is total: never throws, never returns `nil` or empty |

### Diagnostic trace types

Populated only when `Options.enableTrace` is set (DSP fields) or `Options.enableMLDiagnostics` is set (ML fields). Everything below hangs off `BPMDiagnosticTrace` and exists to explain a result, never to change one. Safe to ignore entirely if you only need a BPM.

| Type | What it records |
|------|------|
| `HarmonicRatioEvidence` | The octave/triplet disambiguation that ran: `ratio` (`"2:1"`, `"3:2"`, `"3:1"`), the fast and slow candidates, and the winner |
| `SubBandVoteEvidence` | Sub-band voting outcome: BPM before, BPM after, and whether it changed |
| `SubBandEnergies` | Per-band onset energy (`kick`, `snare`, `crack`, `hihat`). `.zero` when the computation was skipped |
| `ClickCorrelationEntry` | Per-candidate click-track alignment score, at full BPM precision |
| `DurationHintEvidence` / `BarCandidate` | File-duration-derived tempo hints and the bar counts they came from |
| `BeatGridTempoRefinementEvidence` | What the grid tempo-refinement pass changed, if it ran |
| `DownbeatStrategyEvidence` | Which downbeat strategy ran and what it concluded |
| `SignalParticipation` | Whether a signal was `.present`, `.demoted`, `.abstained`, or `.absent` in the selection pool |
| `AbstainReason` / `DemotionReason` | Why a signal abstained or was demoted |
| `WeightedSignal` / `SignalSource` | A participating signal's BPM, confidence, and origin (`.dsp` / `.ml` / `.fileMetadata` / `.beatGrid`) |
| `SignalParticipationTraceEntry` | Per-signal pool log: source, participation, weight, contribution |
| `EnsembleWeightResolution` | How a weighted ensemble policy resolved: per-source effective votes and the winner |

### Reserved — declared but not wired

These are public and will compile, but **nothing reads them**. Setting one changes no behaviour. They are published so the shape is stable when a consuming path lands; treat them as documentation of intent, not as configuration.

| Type | Status |
|------|------|
| `MLExecutionPolicy` | Not yet wired to `Options`. When it lands it will gate whether ML runs at all |
| `ComputeBudget` | Not yet wired to `Options`. Surfaced today only via `AnalysisIntensity.budget` |
| `OctaveEquivalencePolicy` | Accepted but reserved. Octave behaviour is still governed by `MetadataPolicy` |
| `CoreMLTechnique` | Intentional placeholder — does **not** conform to `MLTechnique` and cannot be assigned to `Options.mlTechnique`. Use `BNNSTechnique` |
| `FeatureSubstrate.WeightingProfile`, `SubBandWeights`, `SubBandCutoff` | Config types for the feature substrate; `.subBandEmphasis` throws `weightingNotYetImplemented` |
| `FeatureSubstrate.OnsetFeatures`, `OnsetFeaturesBuilder`, `FeatureSubstrateError` | The shared feature producer. `OnsetFeatures.featureSetVersion` is the train/runtime drift seam |

Intensity levels 8-10 are in the same category: they are reserved for ML and, without an `Options.mlTechnique`, fall through to level 7 and set `degradationReason` on the result.

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

A SwiftUI macOS demo app under `Demo/BoomBoomBoomBPM/` exercises the public API end-to-end — file drop, BPM display, parameter controls, and a diagnostic-trace inspector with JSON export. It's a hands-on evaluation tool. Build with `make demo-build` (no code signing required) or open `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM.xcodeproj` in Xcode. See [`Demo/BoomBoomBoomBPM/README.md`](Demo/BoomBoomBoomBPM/README.md) for App Store distribution prerequisites (bundle identity, archive workflow, privacy manifest, category decision).

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

Multi-window analysis wraps the whole pipeline at intensity 6 and above: every window in the level's window list runs (two windows at intensity 6, three at 7-10) and the per-window results are combined with the configured `mergeStrategy`.

## Using your own tempo model

BoomBoomBoomKit's production BPM path is **DSP-first**. The default analysis pipeline does not require or enable ML, and on the project's regression corpora the DSP pipeline currently outperforms every model the project has trained. Those measurements are kept with the weights on the `develop` branch, since no model ships with the library.

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

**No reference model is bundled.** Story 4-6 (2026-05-16) removed the previously-bundled `giantsteps_v1.mlmodelc` from the main-shipping path because it abstained on 100% of the internal evaluation-corpus audio at production thresholds. A later full retrain was also measured and also fell short, so the position is unchanged; the threshold sweeps and per-corpus figures live with the weights on the `develop` branch. The `BNNSTechnique` infrastructure (load, featurize, inference, two-gate, diagnostic capability) is unchanged and ready to consume a higher-quality model when one is trained. Consumers using ML today must train or supply their own checkpoint.

To convert your own PyTorch checkpoint into a `.mlmodelc` consumable by `BNNSTechnique`, see the consumer-facing `tools/coreml-convert/` CLI (self-contained `uv` Python project). It supports the reference architecture (the one the historical `giantsteps_v1` was trained on) as well as fully custom architectures via your own `nn.Module` class.

### Model contract for `BNNSTechnique`

Path A above — supplying your own weights against the built-in `BNNSTechnique` — requires the model to match this contract exactly. A mismatch throws at construction time rather than degrading silently: a wrong bin count raises `MLTechniqueError.binCountMismatch`, and unresolvable input/output arguments raise `.invalidTensorContract`.

| Property | Required value |
|---|---|
| Input shape | `(1, 1, 128, 512)` NCHW float32 — 1 channel × 128 mel bands × 512 time frames |
| Output shape | `(1, 256)` logits over 256 BPM bins |
| BPM bin schema | bin index `i` → BPM `i + 30`, so 30 to 285 BPM inclusive |
| Tensor names | `input`, `output` |
| Compute units | `CPU_ONLY` — consumed through BNNSGraph; the Neural Engine is not used |
| Compute precision | `FLOAT32` |
| Min deployment target | macOS 15 |

`BNNSTechnique` featurizes in three stages before inference: transpose the frame-major log-mel to mel-major, z-score normalize per mel band, then resample to a fixed width of 512 frames. Softmax is applied host-side, and decoding is `argmax` over the 256 bins. If your architecture needs different featurization, implement `MLTechnique` directly (Path B) instead of matching this contract.

Only 141 of the 256 bins are reachable in practice, because the library normalizes every result into 60-200 BPM. The remaining bins are decode-dead by construction; training against the full 256 is harmless but wastes capacity.

If you want the measured history of the models this project trained against that contract — including why none of them shipped — it is kept with the weights on the `develop` branch rather than here, since no model ships with the library.

## Model registry

When you ship more than one model — a bundled default, a few the user adds, a known public reference — it helps to have one place that catalogs them and checks that each one is what you think it is. `ModelRegistry` is that catalog. It hashes a model bundle's contents with SHA-256 at registration time, so a corrupted download, a wrong-version checkpoint, or a silently swapped file on disk surfaces as a typed error instead of as quietly-wrong tempo output.

It is a standalone, opt-in catalog. It is **not** wired into `analyzeBPM` — registering models does not change analysis results. Wire a registered model into analysis yourself via `Options.mlTechnique` (see *Using your own tempo model* above).

```swift
import BoomBoomBoomKit

let registry = ModelRegistry()

// Trust-on-first-use: record whatever is on disk now, detect a swap later.
let entry = try registry.register(
    url: modelURL,
    metadata: ModelMetadata(
        identifier: "my_tempo_model_v1",
        capabilities: [.tempoEstimation],
        license: "Apache-2.0"))

print(entry.digestHexString)            // e.g. "a3f1…"  (display as `Integrity: verified`)
registry.lookup(identifier: "my_tempo_model_v1")  // -> entry
```

Two integrity modes:

- **Trust-on-first-use** (`expectedDigest: nil`, the default) records the digest of whatever is on disk the first time you register. This is *pin-now-detect-later* — it can catch a later swap, but it does not vouch for the original bytes. The digest is computed once per file URL and cached for the registry's lifetime, so a swap is detected when you re-register on a fresh launch (a new registry re-hashes), not by re-registering the same URL in the same session.
- **Pinned** verifies against a digest you already know. Reconstruct it from a hash published in a manifest (or one you persisted as hex) and pass it in; a mismatch throws and the model is not registered:

```swift
let pinned = try ModelDigest(hex: publishedHexFromYourManifest)
do {
    _ = try registry.register(url: modelURL, expectedDigest: pinned,
                              metadata: ModelMetadata(identifier: "reference_v2"))
} catch let ModelRegistryError.integrityCheckFailed(expected, actual) {
    print("model on disk does not match: expected \(expected.hexString), got \(actual.hexString)")
}
```

The registry is **in-memory only** — there is no `save`/`load`. Persisting registrations across launches is your app's job (store a security-scoped bookmark for the file plus the identifier and the `ModelDigest` hex, then re-register on launch). `ModelDigest` is `Codable`, so the fingerprint persists directly; `ModelRegistryEntry` is intentionally not `Codable`, because its file URL would not round-trip a sandboxed path.

## References

- Davies, M.E.P. & Plumbley, M.D. (2007). "Context-dependent beat tracking of musical audio"
- ITU-R BS.1770-5 — Algorithms to measure audio programme loudness
- O'Shaughnessy, D. (1987). Mel-frequency scale conversion
- Schreiber, H. & Müller, M. (2018). "A Single-Step Approach to Musical Tempo Estimation Using a Convolutional Neural Network" — architecture reference for the historical `giantsteps_v1` checkpoint (pulled from the bundle in Story 4-6; remains the reference architecture for BYOW)

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
