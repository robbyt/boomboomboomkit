# Story 8-5 pressure-release / post-merge reconciliation

Develop-only audit record. Story 8-5 (PR #38, squash `81f6616`) was merged into
`rterhaar/epic-8` **without** a `bmad-code-review`; the review ran post-merge and its
fixes land as the `rterhaar/8-5b` follow-up. Two epic-AC reconciliations came out of that
review and are recorded here (the epic's own escape hatch, `epics.md` Story 8.5 lines
~1046-1053, 1077).

## 1. Playback-aligned priming-trim — intentionally NOT implemented (descope confirmed)

**Epic AC (8.5):** "playback-aligned" timestamps by subtracting AAC/MP3 leading encoder
priming (`leadingTrimFrames / sampleRate`).

**Decision (2026-06-14, operator + Codex thread `019ec6e9`):** keep timestamps
**decoded-PCM-relative**; do NOT implement priming subtraction. `PrimingInfo` /
`TrimState` are NOT extended (no `leadingTrimFrames`).

**Rationale (verified against `ExtendedAudioFile.h:130` / `AudioFile.h:483`):**
`PCMBufferReader` decodes through `AVAudioFile` → `ExtAudioFile`, which **already trims
declared `mPrimingFrames`/`mRemainderFrames`** before the reader sees sample 0 for
container-declared formats (M4A/AAC, MP3 with LAME/Xing/`iTunSMPB`, CAF). So the decoded
PCM is already playback-aligned. Subtracting `mPrimingFrames` again would be a
**double-correction** — for AAC's common 2112-frame priming at 44.1 kHz it would shift
beats ~47.9 ms the *wrong* direction and *fail* a ≤5 ms oracle rather than pass it.
Residual misalignment survives only for exotic headerless/raw streams where the delay is
undeclared (and so cannot be honestly inferred from decoded PCM anyway).

**Replacement (shipped on `rterhaar/8-5b`):** a non-destructive, consumer-controlled
`BeatGrid.offset(by:)` modifier. The consumer sources the offset from its own runtime
(`AVAudioEngine.outputLatency`, a manual nudge, or a headerless-stream residual) and
applies it after detection; the analyzer stays codec-agnostic and the double-correction
trap is structurally avoided. No file-based delay-detection helpers (a file probe returns
~0 for ordinary input and would only tempt double-correction). Docs (README, `BeatGrid`
DocC, `analyzeBeatGrid` DocC) make the AVFoundation reliance + `offset(by:)` explicit.

## 2. AC2 secondary drift bound — reconciled to the extrapolation contract

**Epic AC (8.5 secondary):** the last *detected* beat's `presentationTime` drifts ≤ 30 ms
vs `firstBeatTime + (samplesPerBeat/sampleRate)·beatIndex`.

**Finding (empirical, `longFileSyncStabilityFullTrackDrift`):** the **raw detected**
`.fullTrack` beats accumulate ~46 ms of absolute drift over 5 minutes (median, late
region) from a firstBeat-anchored true grid — each beat snaps to the nearest ~10 ms onset
frame and that quantization accumulates. So the literal raw-last-detected-beat ≤30 ms bound
is **not a property the library guarantees**.

**Decision:** the drift-free guarantee is on the `gridOrigin + estimatedTempo`
**extrapolation** (proven ≤30 ms by `longFileSyncStabilityAnchorExtrapolation`), which is
the documented mid-track contract (consumers extrapolate, they do not trust each raw
`beats` entry). The `.fullTrack` test bounds the detected grid's **relative** phase
stability (early vs late median, ≤30 ms) — the faithful "no accumulating drift" realization
for the detected beats — and the absolute bound lives with the extrapolation. Documented in
the test's DocC and the `BeatGrid` type doc. No algorithm change (would be a Story-8.4
re-open, out of scope).
