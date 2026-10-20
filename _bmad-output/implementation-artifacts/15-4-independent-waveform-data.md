# Story 15.4: Independent waveform data types with per-bin timing and channel-aware stereo

Status: review (Phase 1 of 3 landed)

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 4 of the handoff in `../rekordboxReader/docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Add typed Sendable waveform data (detail envelope, peak overview, low/mid/high energy) with explicit per-bin timing, channel-aware stereo policy, bounded-memory streaming decode, cancellation and progress, in-tree and independent of RekordboxReader.

## Shipped vs deferred

- **Phase 1 (shipped):** the public types `WaveformDetailEnvelope`, `WaveformPeakOverview`, `WaveformEnergyChannels`, `WaveformOptions`, `WaveformAnalysisResult`, and `WaveformAnalyzerError`, the `Waveform` namespace, and `WaveformAnalyzer.analyze(decoded:options:)` covering the mono in-memory path (AC #1, #2, #4, #7, #8). `WaveformOptions` carries only knobs that work today: `columnsPerSecond`, `lowMidCutoffHz`, `midHighCutoffHz`, `isCancelled`, `onProgress`.
  - **Option validation.** `analyze` throws instead of trapping on options it cannot honor: `columnsPerSecondOutOfRange` when `columnsPerSecond` is below 1 or above the sample rate, `midHighCutoffOutOfRange` when `midHighCutoffHz` is not finite, not positive, or at or above `sampleRate / 2` (the default 4000 Hz crossover throws on 8 kHz input), and `lowMidCutoffOutOfRange` when `lowMidCutoffHz` is not finite, not positive, or not below `midHighCutoffHz`. `computeBinStartSamples` also caps the bin count at the frame count, so its output stays strictly increasing on its own.
  - **Cancellation and progress (in-memory form of AC #6).** `isCancelled` is checked before the pass, before each biquad filter pass, and before each 256-bin chunk of the four per-bin passes; a cancelled run throws `WaveformAnalyzerError.cancelled` with no partial result and no further progress reports. `onProgress` reports `0.0` at the start, then once per 256-bin chunk, non-decreasing, ending at `1.0`. The streaming half of AC #6 (block-boundary checks, no disk access after cancellation) stays with Story 15.4a.
- **Phase 2, Story 15.4a (deferred):** bounded-memory streaming decode (AC #5, the streaming half of AC #6). Needs an `AVAudioFile`-backed block reader and a block-boundary cancellation checkpoint. The block-size option is added by 15.4a when it works; Phase 1 does not reserve it.
- **Phase 3, Story 15.4b (deferred):** `DecodedStereoAudio` carrier and the channel policy enum with its stereo cases (AC #3). Phase 1 does not ship a channel policy type; 15.4b adds `WaveformChannelPolicy` and `WaveformOptions.channelPolicy` with cases that work.

## Key Design Decisions

1. **New Waveform namespace under FeatureSubstrate, no new target or dependency.** Add the new types under Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/ as pure Sendable value types. No new SPM target, no RekordboxReader dependency, no SwiftUI. The namespace sits beside DecodedAudio.swift so the shared-decode currency can produce waveform outputs without crossing module boundaries.
2. **Keep raw framewise observations separate from any playable grid.** Waveform data is a raw per-bin observation surface. It carries no beat, downbeat, or grid semantics. Epic 15 Phase 6 and Phase 7 own the grid-shaped outputs; this story must not populate SignalSource.beatGrid or SignalWeights.beatGrid, and must not report confidence that a later ensemble could count as an independent vote.
3. **Explicit per-bin timing via integer math, not float accumulation.** Bin boundaries are expressed as sample indices (Int) relative to a covered frame range. Timestamps are derived as sampleIndex divided by sampleRate at the consumer boundary. Default detail resolution is 150 columns per second, configurable; the bin-count calculation uses rational arithmetic (frameCount * cps / sampleRate rounded with explicit policy) so a short file ending mid-bin keeps a correctly-sized final partial bin.
4. **Channel-aware stereo policy that does not destroy anti-phase content.** Introduce WaveformChannelPolicy with cases .mono (consume a DecodedAudio directly), .leftOnly, .rightOnly, .perChannel (two full outputs), and .mixDownRespectingPhase (sqrt((L^2 + R^2) / 2) rather than (L + R) / 2 so anti-phase stereo does not cancel). Choice is explicit; there is no silent averaging default. A new sibling carrier DecodedStereoAudio preserves L and R samples; DecodedAudio stays mono and unchanged.
5. **Three independent outputs: detail envelope, peak-preserving overview, three-band energy.** WaveformDetailEnvelope stores a magnitude value per bin (default 150 cps). WaveformPeakOverview stores signed min and max sample per bin so the true peak sample is preserved across any zoom-level reduction. WaveformEnergyChannels stores three parallel Float arrays (low, mid, high) computed from biquad-split signals over the same bin grid. The three outputs share the same bin timing so a consumer can align them without resampling.
6. **Schema and algorithm version pinned on every output.** Each public struct carries waveformSchemaVersion: String (currently v1) and algorithmIdentifier: String naming the exact envelope / overview / split code path. The band-split cutoffs, filter order, and detail reduction rule are documented and version-pinned so a future change to any of them forces a schema bump rather than silently rewriting outputs that look the same.
7. **Bounded-memory streaming decode with cancellation and progress.** WaveformAnalyzer consumes audio in fixed-size blocks (default 65536 samples per channel, configurable) from an AVAudioFile-backed reader. Peak values are retained per bin while the raw block is discarded, so peak memory stays O(bins) + O(block), not O(duration). The entry point takes an isCancelled closure (default Task.isCancelled) and an onProgress callback consistent with AudioAnalysisService.analyzeBPM. Cancellation returns promptly between blocks.
8. **No rekordbox file-format mimicry and no packed-byte quantization.** Outputs are Swift arrays of Float, not packed bytes. Energy channels are three independent magnitudes, not RGB-encoded, and carry no implied display color or height. No PWV4-shaped tags, chunk headers, or on-disk encodings. A later renderer may pack these for display; the data surface stays unquantized.

## Story

As a a BoomBoomBoomKit integrator (DJ app, metadata viewer, future beat-grid consumer),
I want a stable typed waveform surface with explicit per-bin timing and channel-aware stereo,
so that the amplitude envelope, peak overview, and three-band energy I draw stay aligned with the playback timeline the library hands me, with no renderer-side guessing about missing phase or anti-phase cancellation.

## Acceptance Criteria

1. **Given** a 10-second silent WAV at 44.1 kHz through WaveformAnalyzer with default options
   **When** the detail envelope, peak overview, and three energy channels are returned
   **Then** every value in every output is finite, every detail value is at or below a documented silence floor, and low, mid, and high energy are each at or below that floor

2. **Given** three 5-second pure sines at 44.1 kHz full-scale 0.5, one at 60 Hz, one at 1 kHz, one at 10 kHz
   **When** WaveformAnalyzer runs on each in turn
   **Then** for the 60 Hz tone low energy exceeds mid and high by at least a documented ratio, for the 1 kHz tone mid exceeds low and high, for the 10 kHz tone high exceeds low and mid, and no band is silently normalized to the same peak as the others

3. **Given** a 2-second stereo WAV whose right channel is exactly the inverse of the left (anti-phase)
   **When** WaveformAnalyzer runs under WaveformChannelPolicy.mixDownRespectingPhase and again under .perChannel
   **Then** the mixdown envelope peak is within one quantization step of the per-channel peak (phase does not cancel to zero), and the .perChannel output returns two independent envelopes with left and right peaks of equal magnitude

4. **Given** a 97-millisecond WAV at 44.1 kHz run at the default 150 columns per second
   **When** WaveformAnalyzer returns
   **Then** the detail envelope bin count equals the integer-math expected value (ceil of frameCount times 150 divided by sampleRate), the final bin covers exactly the remaining samples with no padding, and bin boundaries derived from the stored start-sample indices are strictly monotonic and sum to the covered frame range

5. **Given** the same 30-second WAV decoded through WaveformAnalyzer with streaming block sizes of 4096, 16384, and 65536 samples
   **When** the three detail envelopes, peak overviews, and energy channels are compared pairwise
   **Then** all three outputs are bit-identical, and resident memory measured across the run stays within a documented bound that is independent of file duration

6. **Given** a 10-second decode that is cancelled 50 milliseconds after start via an isCancelled closure
   **When** WaveformAnalyzer observes the cancellation at its next block boundary
   **Then** it returns a cancellation error (not a partial populated struct), does not touch disk after the cancellation point, and the onProgress callback stops firing

7. **Given** a 20-second click-track fixture with a single-sample impulse at a known time t
   **When** WaveformAnalyzer runs with default options
   **Then** the peak-preserving overview's bin containing t retains the full impulse amplitude (not an averaged-down value), the detail-envelope bin containing t has its documented peak-of-abs reduction applied, and the per-bin start-sample of that bin maps to a time within one bin width of t

8. **Given** a 3-second 1 kHz tone at 0.5 full-scale analyzed at three sample rates (44.1 / 48 / 96 kHz)
   **When** WaveformAnalyzer runs with default options at each rate
   **Then** the median detail envelope magnitude is within a documented tolerance of 0.5 at every rate, the peak-preserving overview retains the true 0.5 peak at every rate, and the band-energy winner (mid) is the same across all three rates

## Affected files

- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformData.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformDetailEnvelope.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformPeakOverview.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformEnergyChannels.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformChannelPolicy.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformOptions.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformAnalyzer.swift`
- `Sources/BoomBoomBoomKit/FeatureSubstrate/DecodedStereoAudio.swift`
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift`
- `Tests/BoomBoomBoomKitTests/Waveform/WaveformAnalyzerTests.swift`
- `Tests/BoomBoomBoomKitTests/Waveform/WaveformChannelPolicyTests.swift`
- `Tests/BoomBoomBoomKitTests/Waveform/WaveformStreamingTests.swift`
- `CLAUDE.md`

## Overlap with Epic 12

None. Epic 12 is the model-quality redesign (training, representation, retrain gate) and touches BNNSTechnique, MLFeatureFrames, and the DSP ensemble. This story adds a parallel waveform surface under FeatureSubstrate/Waveform/ that no ML or DSP BPM path depends on. The one adjacent concern is that WaveformEnergyChannels uses biquad band splits sized by Nyquist, which must not be renamed or merged with SubBandCutoff / SubBandWeights (those remain the BPM path's property); the new types are named Waveform* to prevent accidental coupling.

## Open questions for the PRD

- Does DecodedStereoAudio belong beside DecodedAudio as a sibling carrier, or should DecodedAudio grow an optional secondChannel field? Phase 4 scope only needs the data; the Phase 6 observation model has no stereo need either, so a sibling type keeps the mono-DecodedAudio contract untouched.
- What is the exact low / mid / high crossover schedule (candidates: 250 Hz and 4 kHz; or 200 Hz and 2 kHz; or something sample-rate-adaptive)? Needs a documented default plus a knob on WaveformOptions; this is the single most consequential schema choice.
- Should WaveformAnalyzer emit progress as a plain callback consistent with AudioAnalysisService.analyzeBPM, or expose an AsyncStream? Callback keeps the surface smaller and matches the existing library pattern; AsyncStream would make partial-overview previews cheap. Phase 4 picks one and version-pins the choice.
- Peak-overview bin width policy: fixed 10 columns per second, or an integer divisor of detail cps? An integer-divisor relationship keeps the two outputs trivially aligned at any zoom level.
- Does the band-split run on the mixdown or on each stereo channel under .perChannel? Running on each channel doubles cost; running on the mixdown couples band energy to the channel policy. Pick one and document it.

## Explicit scope exclusions

- Do not add a dependency on /Users/rterhaar/Dropbox/research/swift/rekordboxReader. Reference it for comparison only; copy no code and link no module.
- Do not emit PWV4 or any other rekordbox-shaped chunk tag, byte layout, or on-disk encoding. Outputs are Swift structs with Float arrays, not packed-byte formats.
- Do not ship a SwiftUI renderer or any Demo/ UI consumer in this story. That is a later-story concern once the data surface is stable.
- Do not populate SignalSource.beatGrid or SignalWeights.beatGrid, and do not emit any confidence that a KDD-A5 weighted ensemble could count as an independent vote. Those are still placeholders.
- Do not retune or re-express the existing SubBandCutoff, SubBandWeights, or SubBandEnergies types; they belong to the BPM pipeline. WaveformEnergyChannels is a separate surface with its own cutoffs.
- Do not alter runtime preprocessing of existing BPM or ML weights as a side effect of adding waveform code. Phase 4 is a pure-add on the FeatureSubstrate side.
- Do not promote any file in Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/ to the main allowlist out of sequence; Sources ships wholesale, so the files land on main automatically on the next promotion, with no edit to scripts/promote-to-main.py.
- Do not touch Story 12-7 corpus membership, the signed corpus protocol, _bmad-output/ml-training/eval-corpus/, or the untracked addendum-design.md. Phase 4 is independent of model training per the handoff.
- Do not introduce packed-byte quantization, silent per-band normalization that destroys relative balance, or any averaging policy that treats anti-phase stereo as silence.

