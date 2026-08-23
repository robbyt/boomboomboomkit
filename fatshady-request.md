# Feature Request: Per-Frame Audio Features and Phase Queries for TheRealFatShady

**From:** TheRealFatShady — shader-driven music visualizer for macOS (SwiftUI + Metal)
**Date:** 2026-08-22
**Library branch consumed:** `develop` (`35c6bed`), via SwiftPM `branch: "develop"`
**Context:** TheRealFatShady v1 design (offline analysis → live preview → deterministic video export)

---

## What TheRealFatShady Is

TheRealFatShady is a native macOS app (Xcode 26, Swift 6, macOS 26 SDK) that loads an audio file, analyzes it offline, and drives Metal shaders from the audio at any frame rate. Two consumers of the analysis:

1. **Live preview** — an `AVAudioEngine` player plus a `CAMetalDisplayLink`-driven Metal view. Each display tick reads the playback clock, samples the audio features at that time, and renders one frame. 60–120 fps.
2. **Deterministic video export** — frames rendered at `t = n / fps` (24–120 fps) into `AVAssetWriter` (H.264 / HEVC / ProRes, alpha variants, PNG/EXR sequences), faster than real time, with the source audio muxed in. The same `t` must always produce the same uniforms, regardless of preview vs export or of the output frame rate.

Shader presets (MSL with an ISF-style JSON header) receive uniforms such as `sub`, `bass`, `mid`, `high`, `onset` (impulse with exponential decay), `beatPhase`, `barPhase`, `beatIndex`, `bpm`, `loudness`, plus a 1-D FFT/waveform texture. The visual style is sharp, geometric and clean: polygons flipping on beats, camera shake on onsets, fractal folds driven by band energy. **Onset timing is the product.** A flip that starts one frame late at 120 fps (8.3 ms) is visible; a kick-driven pulse that lags 20 ms reads as "floaty."

## How TheRealFatShady Plans to Use BoomBoomBoomKit Today

From a read of `develop` on 2026-08-22, the public surface gives us:

| Need | Public API used | Status |
|---|---|---|
| Decode WAV/AIFF/FLAC/MP3/M4A to mono float PCM at native rate | `PCMBufferReader.readDecodedAudio(from:maxSeconds:)` → `FeatureSubstrate.DecodedAudio` | ✅ Used as-is. One decode shared across every analysis. |
| Tempo + beat grid + downbeats | `AudioAnalysisService.analyze(decoded:options:)` with `maxSeconds` raised to the full duration, `beatGridCoverage = .fullTrack`, `detectDownbeats = true`, `refineBeatGridTempo = true` | ✅ Used as-is. |
| Loudness series for auto-gain of visual sensitivity | `AudioAnalysisService.analyzeLUFS(decoded:options:)` → `LUFSReport` momentary/short-term series | ✅ Used as-is. |
| Log-mel spectrogram, 128 bands @ 100 Hz | `FeatureSubstrate.OnsetFeaturesBuilder.build(decoded:weighting:)` → `OnsetFeatures.logMelData` | ⚠️ Usable, but see below. |
| Per-frame onset strength / spectral flux / band energies | — | ❌ Not public. `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` computes them and `OnsetFeaturesBuilder.build` discards them. |
| Discrete onset events (time, strength, band) | — | ❌ Does not exist, public or internal. `adaptiveThreshold` peak-picks but only feeds autocorrelation. |
| Beat / bar / subdivision phase at an arbitrary time | — | ❌ `BeatGrid` has no `phase(at:)`; `BarPhase` is `internal`. |
| Async entry points with cooperative cancellation | — | ❌ All entry points are synchronous `throws`; we wrap in `Task.detached` with an atomic cancel flag, as the Demo does. |

**Interim plan:** TheRealFatShady will implement its own feature extractor on top of `DecodedAudio` (time-domain sub-bass band-pass envelope; STFT at a ~5.8 ms hop; SuperFlux onsets with offline peak picking) and its own beat-phase arithmetic on top of `BeatGrid.gridOrigin` + `estimatedTempo`. Everything in this document is what would let us delete that code and rely on the library instead. Priorities are ordered by how much consumer code each one removes.

---

## Requested API Additions

### Priority 1: Public onset features — envelopes and discrete events (highest value)

The library already computes a half-wave-rectified log-mel spectral flux envelope (full-band + kick/snareLow/snareCrack/hiHat sub-bands) and a SuperFlux variant at 100 Hz. We need those arrays, plus a peak-picked event list, as public output.

**What TheRealFatShady needs from the result:**

```swift
extension FeatureSubstrate {
  public struct OnsetEnvelopes: Sendable {
    public let frameRate: Double          // frames per second (hop-derived, e.g. 100.0)
    public let frameTimeOffset: Double    // seconds added to frame*hop/sampleRate to reach the
                                          // window CENTER (see Priority 6)
    public let fullBand: [Float]          // flux per frame, unnormalized
    public let subBands: [[Float]]        // same length, one array per SubBand
    public let subBandLabels: [SubBand]   // .kick, .snareLow, .snareCrack, .hiHat
    public let variant: OnsetFunction     // .spectralFlux or .superFlux
  }

  public struct OnsetEvent: Sendable, Hashable, Codable {
    public let time: Double               // seconds, decoded-PCM-relative (same origin as BeatGrid)
    public let strength: Float            // [0, 1], normalized per track
    public let band: SubBand?             // nil = full-band detector
  }

  public struct OnsetAnalysis: Sendable {
    public let envelopes: OnsetEnvelopes
    public let events: [OnsetEvent]       // sorted by time, min inter-onset interval ≥ 20 ms
  }
}

extension FeatureSubstrate.OnsetFeaturesBuilder {
  public static func buildOnsetAnalysis(
    decoded: FeatureSubstrate.DecodedAudio,
    options: FeatureSubstrate.OnsetOptions = .init()
  ) throws -> FeatureSubstrate.OnsetAnalysis
}

public struct OnsetOptions: Sendable {
  public var frameRate: Double = 100            // see Priority 2 for finer rates
  public var function: OnsetFunction = .superFlux
  public var peakPicking: PeakPickingOptions = .init()   // threshold delta, pre/post mean window,
                                                         // pre/post max window, min inter-onset gap
  public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }
}
```

**Why this shape:** The visualizer needs both forms. The envelopes drive continuous uniforms (`flux`, per-band "energy change") and the events drive the `onset` impulse. Because our rendering is offline and seekable, we evaluate `onset(t) = max over events e with e.time ≤ t of e.strength · exp(-(t − e.time)/τ)` — a pure function of `t` that needs the event list, not a smoothed envelope. The library already has everything except the public types and the peak picker's output.

**Accuracy requirements:**
- Offline (non-causal) peak picking is expected and preferred — there is no latency constraint, so center the threshold window on the frame.
- Event `time` within ±5 ms of the true transient on a synthetic click track (the existing `generateClickTrack` in `BoomBoomBoomKitTestSupport` is the right fixture). A frame-start vs frame-center bias of half a 2048-sample window (~23 ms at 44.1 kHz) would fail this; see Priority 6.
- `strength` normalized per track so a quiet intro and a loud drop both produce usable 0–1 values. A simple "divide by 95th percentile of all event strengths, clamp to 1" is fine; we will apply our own gain on top.

**Performance budget:** Same order as the existing onset pass (it is the existing onset pass). Sub-second for a 5-minute track in Release is the target.

### Priority 2: Finer time resolution for the onset pass

100 Hz (10 ms hop) is good for tempo but coarse for a 120 fps visualizer (8.3 ms per frame). We would like the onset function to run at a selectable rate.

**What TheRealFatShady needs:**

```swift
OnsetOptions.frameRate: Double   // accepted range ≥ 100; we would use 200–400 (hop ≈ 2.5–5 ms)
```

and the resulting `OnsetEnvelopes.frameRate` / `OnsetEvent.time` to reflect it. The FFT size can stay 2048 (overlap just increases); the mel filterbank and log compression are unchanged. If the library prefers to keep BPM analysis pinned at 100 Hz, a separate rate for `buildOnsetAnalysis` only is fine.

**Accuracy requirement:** at 200 Hz, click-track events within ±3 ms.

### Priority 3: Phase queries on `BeatGrid` (removes the most consumer arithmetic)

Every consumer re-derives "phase at time t" from `gridOrigin.presentationTime` and `60 / estimatedTempo`; `docs/beatgrid-design-notes.md` §4 already specifies the formula, and `BarPhase.index` is a three-line internal helper. Please make these public methods on `BeatGrid`:

```swift
extension BeatGrid {
  /// Beat period in seconds (60 / estimatedTempo); nil when estimatedTempo == 0.
  public var beatPeriod: Double? { get }

  /// Fractional beat phase in [0, 1) at `time`, extrapolated from `gridOrigin`. nil if no origin/tempo.
  public func beatPhase(at time: Double) -> Double?

  /// Signed beat index (can be negative before the anchor), and the fractional part.
  public func beatPosition(at time: Double) -> (index: Int, phase: Double)?

  /// Phase within an M-way subdivision of the beat (M = 2 for 8ths, 4 for 16ths).
  public func subdivisionPhase(at time: Double, divisions: Int) -> Double?

  /// Bar phase in [0, 1) using `downbeats` when detected, else `assumedBeatsPerBar` aligned to
  /// the anchor (phaseIndex 0), with `source` telling the consumer which it was.
  public func barPhase(at time: Double, assumedBeatsPerBar: Int = 4)
    -> (phase: Double, beatInBar: Int, source: BarPhaseSource)?

  /// Nearest grid beat time (extrapolated grid, not raw `beats[]`) — for scrubber snapping.
  public func nearestGridBeat(to time: Double) -> Double?
}

public enum BarPhaseSource: Sendable { case detectedDownbeat, assumedFromAnchor, manual }
```

**Why:** These are the uniforms the shaders consume every frame. Having them in the library means the Demo, Hilbert and TheRealFatShady all agree on the arithmetic and on the `.downbeat` vs assumed-meter fallback, and the library's own click-track tests can pin the convention.

### Priority 4: Drift-resistant grid for long tracks

Measured (`8-7-beat-grid-hardening-benchmarks.md`): last-beat drift P95 = 1652 ms on tracks ≥ 5 min, individual tracks up to 4.4 s. A single anchor plus one tempo extrapolated over five minutes is not usable for a beat-locked visual at the end of a track, and `refineBeatGridTempo` frequently abstains on the default window.

**What TheRealFatShady needs — any one of these:**

1. **Multi-anchor grid.** `BeatGrid.anchors: [BeatGridAnchor]` placed every N bars (N configurable, default 16), each with a locally refined tempo, so `beatPhase(at:)` (Priority 3) interpolates between the nearest anchors instead of extrapolating from one. Piecewise-linear, still constant-tempo within a segment.
2. **Characterized validity window.** If (1) is out of scope, publish the number `docs/beatgrid-design-notes.md` §9 asks for: worst-case phase error as a function of distance from the anchor on the benchmark corpus, so the consumer knows when to re-anchor. Plus a public `BeatGrid.reanchored(toNearestDetectedBeatAt time:)` so consumers can re-anchor safely using the library's own `beats[]` filtering rather than trusting raw beats.
3. **Stable-clock mode** (the `expectStableClock` hint Hilbert requested). With `.fullTrack` coverage, fit one tempo + one offset to the full onset envelope by least squares / comb correlation rather than extrapolating the analysis-window estimate. For DAW-quantized material this should bring end-of-track drift under 30 ms. This is what our users' material is.

**Accuracy requirement:** beat phase within ±10 ms at the end of a 5-minute constant-tempo track. `generateClickTrack(bpm:sampleRate:durationSeconds:)` at 300 s is the fixture.

### Priority 5: One pass for everything — share the STFT

Today `analyze(decoded:)`, `analyzeLUFS(decoded:)` and `OnsetFeaturesBuilder.build(decoded:)` share the decode but each runs its own spectral pass; the BPM path computes the exact envelopes we want and throws them away. Please add an opt-in to capture them on the combined result:

```swift
AudioAnalysisService.Options.captureOnsetAnalysis: Bool = false    // default off, no cost when off
AudioAnalysisService.Options.onsetOptions: FeatureSubstrate.OnsetOptions = .init()

public struct FullAnalysisResult {
  // existing fields…
  public let onsetAnalysis: FeatureSubstrate.OnsetAnalysis?   // non-nil when captured
}
```

This makes `analyzeFull(url:options:lufsOptions:)` the single call a consumer makes, with one decode and one STFT.

### Priority 6: Timestamp convention — frame center, and a click-track assertion

`BeatGridAnalyzer` computes `presentationTime = (windowStartSample + f·hop) / sampleRate`, i.e. the **start** of a 2048-sample window that extends forward in time. For a transient that occurs mid-window this biases reported times early by up to ~23 ms at 44.1 kHz (~21 ms at 48 kHz). No test pins absolute phase against a synthetic click — only tempo and monotonicity are asserted.

**What TheRealFatShady needs:**
- Document the convention for every time the library emits (`BeatTimestamp.presentationTime`, `BeatGridAnchor.presentationTime`, `OnsetEvent.time`), and make it **window center** (`+ fftSize / 2 / sampleRate`) unless there is a reason not to. `OnsetEnvelopes.frameTimeOffset` in Priority 1 is there so the consumer never has to guess.
- One test: generate a 120 BPM click track, run `analyze` with `.fullTrack`, assert `beatPhase(at: clickTime) ≈ 0` within ±5 ms for clicks at 10 s, 60 s and 280 s.

We will measure this ourselves against the current `develop` before locking shader timing; if the offset is a constant we will compensate in the consumer until it is fixed.

### Priority 7: `async` entry points with cooperative cancellation

`docs/api-feedback.md` #2 already proposes this; we are a second consumer asking for it:

```swift
extension AudioAnalysisService {
  public nonisolated static func analyze(url: URL, options: Options = .init()) async throws -> CombinedAnalysisResult?
  public nonisolated static func analyzeFull(url: URL, options: Options = .init(),
                                             lufsOptions: LUFSOptions = .init()) async throws -> FullAnalysisResult
}
```

with `Task.checkCancellation()` at the existing window checkpoints and inside the onset pass at some block granularity (today cancellation is never checked mid-window, so a cancel during a 5-minute `.fullTrack` onset pass waits for the whole pass). `Task.detached` not inheriting cancellation is the trap every consumer hits.

### Priority 8: Linear-frequency band energies at the onset rate (nice to have)

`OnsetFeatures.logMelData` lets us compute band energies, but mel bins 0..<20 are a coarse proxy for "sub-bass 30–120 Hz" and the 2048-point FFT at 44.1 kHz has 21.5 Hz bins, so the lowest two mel bands straddle the kick fundamental. We do this in the time domain instead (4th-order band-pass → rectified peak envelope). If the library wants to own it:

```swift
public struct BandEnergySeries: Sendable {
  public let frameRate: Double
  public let bands: [ClosedRange<Double>]     // Hz
  public let values: [[Float]]               // per band, per frame; log or linear, documented
}
FeatureSubstrate.OnsetFeaturesBuilder.buildBandEnergies(decoded:, bands:, frameRate:) throws -> BandEnergySeries
```

Defaults we would request: sub 30–120, bass 60–250, lowMid 250–1000, mid 1000–4000, high 4000–16000 Hz, time-domain filtered for the two lowest.

### Priority 9: Serialization helpers (nice to have)

- `OnsetAnalysis` and `OnsetEnvelopes` `Codable` with a compact binary-friendly layout (or a documented `Data` round-trip), so consumers can cache per-file results keyed by content hash + `featureSetVersion`, the way `BeatGrid` already carries `schemaVersion`.
- `AudioAnalysisResult.candidates` as a `Codable` struct instead of a tuple array, so `AudioAnalysisResult` can be cached as a whole.

### Priority 10: Streaming onset detector (stretch — for a later live-input feature)

Not needed for v1 (file-based only). For a later "visualize system audio / microphone" mode we would want a causal detector with bounded latency:

```swift
public final class StreamingOnsetDetector: Sendable {
  public init(sampleRate: Double, options: FeatureSubstrate.OnsetOptions)
  public func push(_ samples: UnsafeBufferPointer<Float>) -> [FeatureSubstrate.OnsetEvent]   // events detected so far
  public var latencySeconds: Double { get }   // hop + peak-picking lookahead
}
```

Causal SuperFlux + online peak picking with a short post-window (≤ 20 ms). Listed so the offline types in Priority 1 are designed to be reusable by it (same `OnsetEvent`, same options).

---

## API Shape Preferences (Not Prescriptive)

- Everything `Sendable`; value types; no actors or main-thread requirements — the current library style is exactly right.
- Keep `FeatureSubstrate` as the namespace for per-frame data; keep `BeatGrid` as the home for phase queries.
- Times in seconds, `Double`, decoded-PCM-relative (the existing "Timestamp contract"), window-centered.
- Large arrays as flat `[Float]` with documented layout (as `logMelData` does today) rather than nested arrays where size matters.
- Options structs with defaults that are no-ops for existing consumers (`captureOnsetAnalysis = false`, `frameRate = 100`).

**Performance budget:** a 5-minute track, Release build, Apple Silicon: full analysis (decode + BPM + `.fullTrack` grid + LUFS + onset analysis at 200 Hz) in ≤ 2 s. We run it once per file at load and cache.

**Failure modes:** `nil`/empty where detection abstains (downbeats, tempo), never a throw for "not found"; throws reserved for I/O, unsupported input and cancellation, as today. An empty `events` array with a valid envelope is a legitimate result for ambient material.

## What We Will Contribute Back

- The click-track timing assertion in Priority 6, if useful, as a PR against `Tests/BoomBoomBoomKitTests` using `BoomBoomBoomKitTestSupport.generateClickTrack`.
- Measured frame-center offsets and long-track drift numbers from our own fixtures, once our feature extractor exists (we will have an independent onset reference to compare against).
- Any consumer-side implementation of Priorities 1, 3 or 8 that proves out, for lifting into the library.

## Timeline

TheRealFatShady v1 is being built now against `develop` at `35c6bed` with the interim plan above, so nothing here is blocking. Priorities 1–4 would let v1.1 delete the consumer-side feature extractor and beat-phase code; 5–7 are quality-of-life; 8–10 are optional. Priority 6 (timestamp convention) is the one we would most like settled early, because any constant offset we compensate for now becomes a breaking change for us later.
