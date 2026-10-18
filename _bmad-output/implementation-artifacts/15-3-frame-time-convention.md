# Story 15.3: Define the frame-time convention and fix the early-anchor bias at the boundary

Status: done

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 3 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Trace the STFT framing, spectral-difference indexing, and onset-to-time conversion; define the public frame-time convention; apply the `hopSize + fftSize/2` correction at exactly one boundary (`BeatGridAnalyzer.estimateBeatGrid`); replace the permissive `BeatGridAnalyzerTests.swift` 10-hop bound with a 3-hop bound; land a formal `BeatGridFrameTimeConventionTests` regression suite covering five failure-mode metrics across the AC #2 matrix.

## Trace outcome

The pre-15.3 pipeline carried three locally correct conventions that disagreed at the frame-to-time boundary:

1. **`BPMAnalyzer.computeLogMelFramesAndRetention`** at `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1129-1176`. The STFT loop walks `samples` in strides of `hopSize`, Hann-weighting each `fftSize=2048`-sample window. The window's peak sits at the center, sample index `k * hopSize + fftSize / 2`. The implementation is correct; the convention is unambiguous once stated.
2. **Spectral-flux temporal differencing** at `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:874-887`. The loop computes `diff = logMel[i] - logMel[i - 1]`, half-wave rectifies, and stores the result at `fullBandEnvelope[i - 1]`. Envelope index `f` therefore records the energy jump **entering** STFT frame `f + 1`.
3. **Frame-to-time conversion** at `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:330`. Pre-15.3: `presentationTime = (windowStartSample + f * hopSize) / sampleRate`. This treats envelope index `f` as if it occurred at the start-of-window of STFT frame `f` — but the actual energy jump lives at the window-center of STFT frame `f + 1`.

Delta: `hopSize + fftSize / 2 = 441 + 1024 = 1465 samples ≈ 33.2 ms at 44.1 kHz`. The Phase 2 probe measured a `-40` to `-50` ms uniformly-early anchor; the trace explains `~33 ms` of that. The residual `7` to `17` ms is a within-window peak-position bias that varies with waveform shape (impulse vs 64-sample exp decay vs kick-like 500-sample decay) and hop phase.

**Residual is a constant, measured after the fact (2026-10-18).** The post-15.3 baseline (`_bmad-output/perf-baselines/beatgrid-timing/f117ea37a8-2026-10-18T02-55-06Z.json`) puts every one of the 24 rows between `-16.78` and `-6.76` ms, and within each row the interior minimum and maximum signed error agree to under a microsecond: the residual is one offset shared by every beat, not jitter. The Story 15.7 joint tempo and phase fit measures the same thing on its own path: on exact-tempo single-impulse clicks its phase anchor sits a constant one hop early: measured `-10.7` ms at 120 BPM and `-11.4` ms at 128 BPM at 44.1 kHz, hop 441. Sub-frame interpolation refines where a peak lies inside its own frame; it cannot remove an offset that every beat carries, so the earlier claim here that Phase 7 "tightens that residual" was wrong. Removing a constant needs a frontend change (onset definition or window placement), which is outside Phase 7.

## Shipped

- The frame-time convention `((f + 1) * hopSize + fftSize / 2) / sampleRate` at the single boundary in `BeatGridAnalyzer.estimateBeatGrid`, with `fftSize` plumbed through as a defaulted parameter (DD 1, DD 2).
- The public doc blocks on `BeatTimestamp.presentationTime` and `AudioAnalysisService.analyzeBeatGrid`, including the constant post-fix residual (DD 4, Trace outcome).
- `BeatGrid.currentSchemaVersion` bumped from 2 to 3, so a grid cached under version 2 is identifiable as being on the old timeline (DD 10).
- The `BeatGridFrameTimeConventionTests` regression suite, the tightened 3-hop bounds in `BeatGridAnalyzerTests`, and the re-captured `DownbeatStrategyContainmentTests` snapshot (DD 6, DD 7, DD 8).

## Key Design Decisions

1. **The correction lives at exactly one boundary.** `BeatGridAnalyzer.estimateBeatGrid` is the sole frame-to-time conversion site. The envelope's `[i - 1]` storage indexing is unchanged, so the DP tracker's `frames` array still means the same thing it has always meant. The `presentationTime` formula becomes `(windowStartSample + (f + 1) * hopSize + fftSize / 2) / sampleRate`.
2. **`fftSize` is a parameter, not a hardcoded constant.** The old convention did not need `fftSize` because the (incorrect) formula used only `hopSize`. The new convention couples the frame-to-time mapping to the Hann window length, so `fftSize` is plumbed through to `BeatGridAnalyzer.estimateBeatGrid` as a defaulted parameter (`fftSize: Int = BPMAnalyzer.fftSize`). `BPMAnalyzer.fftSize` is lifted from `private` to `internal` so the test target can assert the convention.
3. **No universal +40 or +50 ms correction.** The handoff forbade a magic constant; the derived correction is `hopSize + fftSize / 2`, a function of the STFT parameters. At 44.1 kHz / `hopSize=441` / `fftSize=2048` it happens to equal 33.2 ms, but it scales correctly to 48 kHz (`480 + 1024 = 1504 samples ≈ 31.3 ms`) and anything else without a lookup table.
4. **Public-type shapes are stable.** `BeatGrid`, `BeatTimestamp`, `BeatGridAnchor`, and `AudioAnalysisService.analyzeBeatGrid` keep their existing fields and signatures. The semantics of `presentationTime` are now explicit in the doc block on `BeatTimestamp.presentationTime`, in `AudioAnalysisService.analyzeBeatGrid`'s doc note, and in the Phase 3 regression suite's design-decision comments.
5. **Codec priming is subtracted exactly once.** AVFoundation removes declared priming during decode; `BeatGrid` already documents this at line 43 / 475. The convention fix adds no priming logic; the new doc blocks reaffirm the single-subtraction contract.
6. **Five failure-mode metrics, not a single composite.** The new `BeatGridFrameTimeConventionTests` suite reports constant phase bias, max absolute error, beat-to-beat jitter, rate error, long-track drift, and metrical-level correctness as six separate assertions per fixture. Averaging them into a single scalar would hide the kick-like waveform's one-hop jitter, which is a Phase-7 target, not a Phase-3 pass.
7. **Pre-existing permissive bounds tightened.** The `BeatGridAnalyzerTests.swift` real-fixture bounds at the former `:874` and `:1074` move from `10 * hopSize` (~100 ms) to `3 * hopSize` (~30 ms). The new ceiling catches a regression toward the pre-15.3 numbers while leaving headroom for the within-window peak bias Phase 7 is scoped to tighten.
8. **The committed snapshot in `DownbeatStrategyContainmentTests.defaultPathBeatGridMatchesPreStorySnapshot` is re-captured.** Every pre-15.3 beat time was `envelope_index * hopSize / sampleRate`; the post-15.3 time is that plus `(hopSize + fftSize / 2) / sampleRate = 0.033219954648526...` seconds. The committed array is shifted by that exact constant; the underlying envelope indices are unchanged.
9. **Learned evidence is not counted twice.** `SignalSource.beatGrid` and `SignalWeights.beatGrid` stay placeholders. The convention fix changes no voting path; the ensemble is untouched; `MLTechnique.evaluate` remains byte-identity-tested at `.dspOnly`.
10. **`BeatGrid.currentSchemaVersion` is bumped from 2 to 3.** The type's "When to bump" rules list a change in what `presentationTime` means as a bump trigger, and this story moves every `presentationTime` from the start of STFT frame `f` to the Hann-window centre of frame `f + 1` (`+ hopSize + fftSize / 2`, about 33 ms at 44.1 kHz). A cache keyed on version 2 cannot otherwise tell a pre-15.3 grid from a post-15.3 one. No other in-repo persistence couples to this value: the Demo trace version, the perf `BaselineRecord` schema version, and the JAMS versions are separate formats. `BeatGridTypesTests.schemaVersionCurrentIsThreeAndDefaultStamped`, the encoded-key assertion in `schemaVersionAbsentDefaultsToOneAndIsAlwaysEmitted`, and the `DownbeatStrategyContainmentTests` snapshot pin the new value.

## Story

As a library author integrating BoomBoomBoomKit's beat grid into a DJ consumer,
I want the emitted beat timestamps to match the physical playback time of each beat within a few hops, and the convention stated in the public API doc,
so that downstream auto-sync and visual overlays align without a hand-tuned per-track offset, and so a reviewer can tell whether a disagreement is phase, jitter, rate, or drift.

## Acceptance Criteria

1. **Given** the current branch HEAD and the three cited sites (`BPMAnalyzer.swift:1129-1176` left-aligned Hann-windowed STFT, `BPMAnalyzer.swift:874-887` spectral-difference frame `i` stored at onset index `i - 1`, `BeatGridAnalyzer.swift:330` presentation-time formula)
   **When** the story's convention is applied
   **Then** the trace names each site's current timing meaning, derives the single correct frame-time convention (`(f + 1) * hopSize + fftSize / 2`), and the fix is applied at exactly one boundary (`BeatGridAnalyzer.swift:330` + plumbing); no universal `+40` or `+50` ms constant appears anywhere in `Sources/BoomBoomBoomKit`.

2. **Given** synthetic click fixtures at 120 and 126 BPM, at 44100 and 48000 Hz, with the first impulse placed at sample 0, half a hop, and a full hop into the file, with and without 1 second of leading silence, with single-impulse / 64-sample exp decay / 500-sample kick-like waveforms, over both the known-tempo and public-facade paths (96 fixtures)
   **When** `BeatGridFrameTimeConventionTests.phaseBiasAndJitterStayInsideTightBoundAcrossFullMatrix` runs
   **Then** every row's median signed phase bias is within 25 ms, max absolute error within 50 ms, beat-to-beat jitter within 35 ms, rate error within 0.5 BPM, long-track drift within 35 ms, and the recovered beat spacing matches the planted period within two hops (correct metrical level).

3. **Given** the regression harness that replaces the permissive `BeatGridAnalyzerTests.swift:846` check
   **When** the suite runs on real-fixture click tracks
   **Then** the onset-latency bound is `3 * hopSize` (not `10 * hopSize`), and the gridOrigin-to-impulse distance bound is also `3 * hopSize` at the former `:1074`; both are tightened to post-15.3 reality.

4. **Given** the public facade `AudioAnalysisService.analyzeBeatGrid` and the `BeatTimestamp` / `BeatGrid` public types
   **When** a consumer reads their doc comments
   **Then** the doc states exactly what `presentationTime` means (Hann-window-center of STFT frame `f + 1` on the decoded-PCM timeline), explicitly notes that AVFoundation has already subtracted declared codec priming and callers must not subtract it again, and names the single boundary where the frame-time convention is applied.

5. **Given** the preserved SPM probe at `docs/rekordbox-analysis/evidence/timing/`
   **When** it is re-run against this story's branch
   **Then** its canonical-anchor and interior-median errors are inside [-17.5, -6.0] ms across all 24 preserved cases; the preserved `results.json` produced on the pre-15.3 HEAD is not altered.

6. **Given** `SignalSource.beatGrid`, `SignalWeights.beatGrid`, and the BPM voting / ensemble path
   **When** this story's diff is reviewed
   **Then** no new producer wires grid-derived confidence back into BPM selection or voting, the two placeholders are unchanged in semantics, and no shipped ML weight is affected (no retrain or re-preprocess).

7. **Given** `make test`
   **When** the full unit sweep runs after this story
   **Then** all 967 tests pass (adding 2 new tests from `BeatGridFrameTimeConventionTests`, zero regressions on the 965 pre-story tests); `DownbeatStrategyContainmentTests.defaultPathBeatGridMatchesPreStorySnapshot` passes against the shifted committed array; the per-SHA baseline file at `_bmad-output/perf-baselines/beatgrid-timing/<post-fix-sha>-*.json` records the post-fix measurement.

## Affected files

- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:66` (lift `fftSize` from `private` to `internal`)
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:575` (pass `fftSize: fftSize` to internal step-11 `BeatGridAnalyzer.estimateBeatGrid` call)
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:732` (pass `fftSize: fftSize` to the Story-8.5 full-track seam)
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:125` (add `fftSize: Int = BPMAnalyzer.fftSize` parameter)
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:330` (new frame-to-time formula + doc comment)
- `Sources/BoomBoomBoomKit/BeatTimestamp.swift:38` (public doc block pinning the convention)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:1692` (public facade doc note on the convention)
- `Tests/BoomBoomBoomKitTests/BeatGridFrameTimeConventionTests.swift` (new regression suite, two tests)
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` (add `envelopeIndex(for:…)` helper, update 6 inverse-formula call sites, tighten two 10-hop bounds to 3-hop)
- `Tests/BoomBoomBoomKitTests/DownbeatStrategyContainmentTests.swift` (shift the committed snapshot array + origin.presentationTime by `(hopSize + fftSize/2) / sampleRate`)
- `Tests/BoomBoomBoomKitTests/DownbeatAnalyzerTests.swift` (adjust the bar-boundary tolerance to subtract the Hann-window-center offset)
- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift` (new reproduction band [-17.5, -6.0] ms; dirty-tree-tagging guard for the baseline SHA)

## Overlap with Epic 12

Epic 12 owns model-quality lever ranking and any retrain gate; this story changes neither training inputs nor shipped weights. Coordination: when Epic 12 schedules a retrain under a new preprocessing contract (corrected-ranking item 5, Input-representation redesign), the frame-time convention this story pins becomes a documented invariant the retrain must honor. No overlap in affected files; `MLFeatureFrames.currentFeatureSetVersion` is unchanged; Story 12-7 corpus membership is untouched.

## Follow-up: Story 15.3a (caller-configurable oversampling)

User-raised during this story: rekordbox's own 100 fps envelope is not perfect, so a caller may want to opt into 2x or 4x oversampling to tighten the within-window peak bias further. Scoped as **Story 15.3a** (new) rather than folded here, because it adds a public API field (`Options.beatGridOversamplingFactor`) with its own ACs, perf measurement, and tightened regression bounds. Lands after this story on the same branch.
