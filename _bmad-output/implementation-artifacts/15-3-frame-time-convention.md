# Story 15.3: Define the frame-time convention and fix the early-anchor bias at the boundary

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 3 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Trace the STFT framing, spectral-difference indexing, and onset-to-time conversion, define the public frame-time convention, correct the 40 to 50 ms early-anchor bias at the single boundary where it is introduced, and replace the permissive absolute-phase bound with a tight regression harness.

## Key Design Decisions

1. **Trace first, patch second.** Phase 2 established that the 40 to 50 ms early anchor is reproducible on synthetic clicks. This story must first trace window centering, hop indexing, spectral-difference storage, and onset-to-time conversion across BPMAnalyzer.swift:1181 (the unpadded left-aligned STFT loop that advances position by hopSize), BPMAnalyzer.swift:916 (the per-frame reference-frame section whose frame i is stored at onset index i-1), and BeatGridAnalyzer.swift:330 (presentationTime = (windowStartSample + f * hopSize) / sampleRate). The fix location is a conclusion of the trace, not an input.
2. **No universal plus-40 or plus-50 ms shift.** The probe showed phase bias varies across waveform, hop phase, and sample rate; a constant offset is forbidden by the handoff and would mask the real bug. The correction belongs where the convention is actually inconsistent (STFT window centering, spectral-difference index assignment, or frame-to-time mapping) and is applied once.
3. **Keep BeatTimestamp and gridOrigin shape stable; clarify semantics only.** Public types in BeatGrid.swift are stable. The deliverable is a documentation + implementation pass that nails down what presentationTime means (the physical time of the detected beat at the file's playback timeline) and makes the implementation match the doc, not a new type or new field.
4. **Codec priming stays removed exactly once.** BeatGrid.swift:43 and BeatGrid.swift:475 already warn that AVFoundation subtracts declared priming during decode. The timing fix must not reintroduce an additional priming correction. Any correction derives from STFT framing, not from codec headers.
5. **Report phase bias, jitter, rate error, drift, and metrical level as separate metrics.** The regression harness emits five distinct scores per fixture: constant absolute phase bias (median signed offset), beat-to-beat jitter (median absolute deviation around that median), tempo rate error (BPM delta), long-track drift (phase offset at the last beat minus at the first), and metrical-level correctness (period ratio against ground truth). Averaging them hides the real failure modes.
6. **Replace the permissive 10 hop bound with the tight bound the fix justifies.** BeatGridAnalyzerTests.swift:846 currently allows abs(medianPhase) up to 10 * hopSize (approximately 100 ms at 44.1 kHz, hop 441). After the convention fix the bound must drop to the actual achievable floor derived from windowing, hop phase, and interpolation (a single-digit-ms target in the typical case). The exact number is a Task output; the story commits to replacing it, not to any specific value in advance.
7. **Document the beat-timestamp convention on the public facade.** Add a precise contract to the AudioAnalysisService.analyzeBeatGrid doc and the BeatGrid / BeatTimestamp doc blocks stating what instant presentationTime refers to (center-of-beat energy at the decoded-file playback timeline) and listing which upstream offsets are already applied (windowStartSample, AVFoundation priming) and which are not (none).
8. **Learned evidence is not double-counted.** SignalSource.beatGrid and SignalWeights.beatGrid remain placeholders (CLAUDE.md:213-214). This story must not wire the fixed grid back into BPM voting, even indirectly through an added confidence field, because the grid is derived from the DSP BPM.

## Story

As a library author integrating BoomBoomBoomKit's beat grid into a DJ consumer,
I want the emitted beat timestamps to match the physical playback-time of each beat within a few milliseconds and the convention to be stated in the public API doc,
so that that downstream auto-sync and visual overlays align without a hand-tuned per-track offset and so a reviewer can tell whether a disagreement is phase, jitter, rate, or drift.

## Acceptance Criteria

1. **Given** the current branch HEAD and the three cited sites (BPMAnalyzer.swift:1181 unpadded left-aligned STFT, BPMAnalyzer.swift:916 spectral-difference frame i stored at onset index i-1, BeatGridAnalyzer.swift:330 presentationTime formula)
   **When** the story's trace deliverable is written and the implementation lands
   **Then** the trace file names each site's current timing meaning, derives the single correct frame-time convention (window-center or window-start plus hop phase offset, stated explicitly with sign), and the fix is applied at exactly one boundary; no universal plus-40 or plus-50 ms constant appears anywhere in Sources/BoomBoomBoomKit

2. **Given** synthetic click fixtures at 120 and 126 BPM, at 44100, 48000, and 96000 Hz, with the first impulse placed at sample 0, half a hop, and a full hop into the file, with and without 1 second of leading silence, with and without a nonzero windowStartSample forced by the energy scan
   **When** AudioAnalysisService.analyzeBeatGrid runs the full public path
   **Then** the median signed offset between each emitted BeatTimestamp.presentationTime and the known impulse time is within a tight bound (single-digit milliseconds, exact number set from measurement) and the sign is consistent, with no case exceeding twice that bound

3. **Given** the regression harness that replaces the permissive BeatGridAnalyzerTests.swift:846 check
   **When** the suite runs on the fixture matrix in AC #2
   **Then** it reports and asserts on five separate metrics per fixture (constant phase bias, beat-to-beat jitter, rate error in BPM, long-track drift between first and last beat, metrical-level correctness) rather than only a 10 * hopSize absolute-offset bound

4. **Given** the public facade AudioAnalysisService.analyzeBeatGrid and the BeatTimestamp and BeatGrid public types
   **When** a consumer reads their doc comments after this story lands
   **Then** the doc states exactly what presentationTime means (which physical instant of a beat it marks, on which timeline), explicitly notes that AVFoundation has already subtracted declared codec priming and callers must not subtract it again, and names the single boundary where the frame-time convention is applied

5. **Given** the probe target preserved at docs/rekordbox-analysis/evidence/timing/ from Phase 2
   **When** it is re-run against this story's branch
   **Then** its recorded canonical-anchor and interior-median errors are inside the tight bound of AC #2 across all 12 preserved cases, with no removal of a constant offset in the scoring; the preserved results.json produced by Phase 2 is not altered

6. **Given** SignalSource.beatGrid, SignalWeights.beatGrid, and the BPM voting / ensemble path
   **When** this story's diff is reviewed
   **Then** no new producer wires grid-derived confidence back into BPM selection or voting, the two placeholders are unchanged in semantics, and the fix touches runtime preprocessing of existing shipped weights only if those weights are retrained or reloaded under the new contract (not applicable here, so no weights change)

7. **Given** the Phase 2 baseline tagged in _bmad-output/perf-baselines/
   **When** make benchmark and make benchmark-giantsteps run after the fix
   **Then** OA300 Acc1/Acc2 and GiantSteps Acc1/Acc2 do not regress from the Phase 2 baseline and the matched evaluation gate (Phase 9) is not pre-empted by any parity claim against rekordbox in commit messages, PR text, or source comments

## Affected files

- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:1181`
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:916`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:330`
- `Sources/BoomBoomBoomKit/BeatGrid.swift:40`
- `Sources/BoomBoomBoomKit/BeatGrid.swift:474`
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:1657`
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift:846`
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift (new regression suite)`
- `docs/rekordbox-analysis/evidence/timing/results.json (reference only, not modified)`
- `_bmad-output/implementation-artifacts/15-3-frame-time-convention.md (this spec)`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Overlap with Epic 12

Epic 12 owns model-quality redesign and any retrain gate; the frame-time convention fix is prerequisite work for the Phase 5 fixed-time ML input experiments it governs, but this story changes neither training inputs nor shipped weights. Coordination: when Epic 12 schedules a retrain under a new preprocessing contract, the frame-time convention this story pins becomes a documented invariant the retrain must honor. No overlap in affected files or in corpus membership (Story 12-7 remains untouched).

## Open questions for the PRD

- Which boundary is the correct single site to apply the correction: STFT window centering (hopSize/2 shift at BPMAnalyzer.swift:1181), the spectral-difference storage index (BPMAnalyzer.swift:916 stores frame i at onset index i-1), or the presentationTime formula at BeatGridAnalyzer.swift:330 — this is a Task output, not a planning input
- What is the achievable floor for median signed phase bias across the 44.1/48/96 kHz x 120/126 BPM x three hop phases x leading-silence matrix after the fix, and does it drop below 5 ms, 2 ms, or hit the hop quantization limit
- Should the regression harness live in BeatGridAnalyzerTests.swift or in a new TimingRegressionTests.swift target to keep the probe style distinct from unit tests
- Is any additional offset introduced by MelFilterbank window length versus hopSize (window length greater than hopSize produces overlap but may bias effective center time); the trace must confirm or exclude this
- Does the AudioAnalysisService dropOffset / windowStartSample path participate in the bias (BeatGridAnalyzer.swift:330 adds windowStartSample before dividing by sampleRate, which is correct only if the per-frame conversion itself is correct)

## Explicit scope exclusions

- Do not apply a universal +40 or +50 ms shift anywhere in Sources/BoomBoomBoomKit, nor hide one behind a per-sample-rate lookup table.
- Do not change the shape of BeatTimestamp, gridOrigin, BeatGrid, or AudioAnalysisService.analyzeBeatGrid; only their semantics may be clarified in doc comments.
- Do not wire the derived grid back into BPM voting, EnsemblePolicy, or SignalWeights; SignalSource.beatGrid and SignalWeights.beatGrid stay placeholders.
- Do not retrain or reload any ML weights to compensate for the fix; weight files are out of scope.
- Do not subtract codec priming anywhere in this fix; AVFoundation already removes declared priming during decode and BeatGrid.swift:43 and :475 are the authority.
- Do not alter the signed-corpus protocol, Story 12-7 corpus membership, or the untracked _bmad-output/ml-training/eval-corpus/ tree as a side effect.
- Do not promote any file under docs/rekordbox-analysis/ to main; scripts/promote-to-main.py allowlist is unchanged.
- Do not claim rekordbox parity in commit messages, PR text, or source comments; the matched evaluation (Phase 9) is the gate for any such claim.
- Do not use emojis, em-dashes, business jargon in commits, or invented harness vocabulary (no 'must-drop obligation', 'mint', 'attestation', 'sentinel', or 'work order') in prose.

