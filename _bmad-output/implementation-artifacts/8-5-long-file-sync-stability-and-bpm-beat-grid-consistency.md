---
baseline_commit: 54763330274e298c066554b1e18ba9a003ca1db3
---
<!-- Story 8.5 — long-file sync stability + decoded-PCM-relative timestamps + BPM/beat-grid consistency.
     Closes the beat-grid critical path (8.3 types → 8.4 tracker → 8.5 sync/consistency/anchor).
     Validated 2026-06-13 via Codex (thread 019ec2a4) + Apple TN2258 + party-mode (Siri/Winston/Amelia/John)
     + real consumer feedback (2manyDJs DJ app + MetaMan metadata viewer). BC is NOT a goal (nothing shipped to main). -->

# Story 8.5: Long-file sync stability + decoded-PCM-relative timestamps + BPM/beat-grid consistency + grid anchor

Status: review

## Story

As a **library consumer** (concretely: a Rekordbox-style DJ app doing auto-sync + quantized launch, and a metadata viewer inspecting tempo),
I want **a beat grid that exposes a trustworthy anchor + tempo I can extrapolate Rekordbox-style, stays audibly accurate across 5+ minute tracks, defines its timestamps honestly relative to the decoded-PCM timeline, and tells me — with enough nuance to recover octave errors — whether the BPM stage and the grid agree**,
so that **I can beatmatch without syncing to half/double speed, quantize launches to the grid, and trust the timeline without per-codec offset guesswork.**

## ⚠️ Context corrections (read FIRST — five stale epic-AC premises, verified against the codebase)

The Story 8.5 epic ACs (`epics.md:1043-1077`) predate Stories 8-2/8-3/8-4. Five premises are now wrong (grepped against the tree, per the rule that caught equivalents in 8-1/8-4). Corrections confirmed by Codex (thread `019ec2a4`), Apple TN2258, a party-mode review (Siri/Winston/Amelia/John), and **real consumer feedback (2manyDJs DJ app; MetaMan metadata viewer, 2026-06-13)**. Resolution is the DD set below.

1. **`PrimingInfo` has no `leadingTrimFrames`/`trailingTrimFrames` — the FR-30 "subtract leading-trim frames" premise is impossible AND wrong.** Story 8-2 DD #7a deleted those integer fields and reshaped `PrimingInfo` to `{codec, trimState}` (`PrimingInfo.swift:25-49`; `deferred-work.md` W63-RESOLVED). `presentationTime` is relative to the decoded-PCM origin `AVAudioFile` returns; `AVAudioFile` (layered on `ExtAudioFile`, which per TN2258 removes priming/remainder frames) **empirically** presents already-trimmed PCM, so subtracting would *double-correct*. FR-30 in 8.5 = the decoded-PCM-relative alignment **contract** (DD #3). The `kAudioFilePropertyPacketTableInfo` provenance query + its empirical pre-trim verification are **deferred to Story 8.7** (`deferred-work.md` 8-5-D1).

2. **No `BPMDiagnosticTrace.codecPriming` field exists** — the AC5 promotion target. `PrimingInfo` is already public on `DecodedAudio.codecPriming`. Seam-mitigation reduces to docs (DD #7), mirroring 8-1/8-4.

3. **No combined orchestration method exists** — KDD-C4 (`architecture.md:530`) deferred the public `analyze(...)` "to a follow-up story"; this is that story (DD #1).

4. **The grid covers only the 30 s BPM window** (`defaultAnalysisWindowSeconds = 30.0`, `BPMAnalyzer.swift:83,233-236,274,488-505`). FR-29's "end of a 5-min track" is unreachable from detected beats alone. **Resolution (consumer-driven, Codex):** the primary mid-track contract is **`gridOrigin` (anchor) + `estimatedTempo`** extrapolated Rekordbox-style — drift-free by construction on constant tempo — NOT a full-track array of detected beats. Detected-beat coverage is configurable and defaults to the cheap analysis window (DD #4 / DD #11).

5. **`BeatGridTests` and the cited fixtures do not exist.** Real suites: `BeatGridAnalyzerTests`, `BeatGridTypesTests`. No committed 5-min FLAC (binary bloat); fixtures are runtime-generated via `TestSignalGenerators.generateClickTrack(...)` (DD #8).

## Who consumes this (answers the "is it a feature or instrumentation" question)

- **2manyDJs / "Hilbert" (Rekordbox-style DJ app) — the grid's real consumer.** Auto-sync **gates on tempo agreement**: a wrong tempo beatmatches to half/double speed (audible live failure), so `.disagree` → don't auto-sync. **`tempoAgreement` is a live feature; AC6's ≥90% is a real product promise, not internal QA.** It does beat math (continuous sync + sub-beat quantize) and wants **anchor + tempo**, not the raw `beats[]` array (the DP can drop/double a beat → wrong sub-beat midpoints + accumulated error). Bar/half-bar quantize needs **downbeats** (`.notAttempted` today) — a roadmap dependency (DD #13).
- **MetaMan / MediaDiff (metadata viewer) — instrumentation-only.** Calls `analyzeBPM` only; never the grid. Confirms the field is read by tooling at the low end and by a live feature at the high end.

(Full handoff recorded in memory `project_beatgrid_consumers`.)

## Acceptance Criteria

**AC1 — configurable detected-beat coverage (`BeatGridCoverage`), cheap by default.**
A public `enum BeatGridCoverage: Sendable, Hashable, Codable` with three cases: `.analysisWindow` (**default** — the grid's detected `beats` cover exactly the BPM analysis window the pipeline already computed; **zero extra onset cost**, reuses the in-scope envelope — the Story-8.4 path), `.window(seconds: Double)` (an explicit N-second span; non-finite/`≤0`/absurd sanitizes to `.analysisWindow`), and `.fullTrack` (every detected beat to the file end; triggers a second, full-track onset pass — O(track), DD #10). Carried on `Options.beatGridCoverage` AND recorded on the result as `BeatGrid.coverage` so a consumer knows what span `beats` actually spans. Default `.analysisWindow` (resolved — the primary mid-track contract is anchor+tempo, not detected beats; `.fullTrack` is opt-in for waveform/QA display).

**AC2 — long-file sync stability (FR-29), delivered by anchor+tempo, verified two ways.**
On a runtime-generated **5+ minute constant-tempo** click track (BPM chosen so the generator's `samplesPerBeat = Int(sampleRate·60/bpm)` is **non-integer-exact**, e.g. 127):
- **(primary) anchor+tempo extrapolation** — `gridOrigin.presentationTime + (60.0 / estimatedTempo) · n` lands within **≤ 30 ms** of the true n-th beat at minute 5 (this is the *default* `.analysisWindow` consumer path; drift-free by construction on constant tempo, so the bound is really an anchor-accuracy + tempo-accuracy check).
- **(secondary) `.fullTrack` detected-beat drift** — with `.fullTrack` coverage, the last *detected* beat's `presentationTime` drifts ≤ 30 ms versus `firstBeatTime + (Double(samplesPerBeat)/sampleRate) · beatIndex` (the generator's known period, NOT the grid's own `estimatedTempo`-derived period — comparing to the grid's own tempo round-trips and hides drift — Amelia).

30 ms is the **worst-case pass/fail tolerance** (not a target); at 128 BPM it is ~13% of a 1/8 note — borderline for launch points, which is *why* the default path is anchor+tempo, where mid-track accuracy depends only on the anchor and the constant period, not on accumulated detection drift. Locked by `BeatGridAnalyzerTests.longFileSyncStability`.

**AC3 — decoded-PCM-relative alignment is the timestamp contract (FR-30, reframed).**
`BeatTimestamp.presentationTime` and `BeatGridAnchor.presentationTime` are documented (DocC + README) as **relative to the decoded-PCM origin** (`AVAudioFile` output, energy-scan drop included; `t=0` = file start). No codec-priming subtraction (`AVAudioFile` empirically presents already-trimmed PCM — DD #3). The test asserts against **independent ground truth, not the derived timestamp** (the `round(presentationTime·sampleRate/hopSize)==frame` round-trip is true by construction — Amelia): generate a click → write to **FLAC and WAV on disk** → decode via `PCMBufferReader.readDecodedAudio` → assert each detected beat frame is within **one hop** of a known impulse sample `k·samplesPerBeat`. Locked by `BeatGridAnalyzerTests.decodedPCMRelativeAlignmentFLAC` (+ WAV).

**AC4 — `gridOrigin` anchor — the Rekordbox-style extrapolation contract (FR-29/FR-30, consumer's top ask).**
`BeatGrid` gains `gridOrigin: BeatGridAnchor?` — the single most-trustworthy reference beat, so consumers extrapolate the infinite grid as `gridOrigin.presentationTime + (60.0/estimatedTempo)·n` instead of trusting every detected beat. Public shape:
```swift
public struct BeatGridAnchor: Sendable, Hashable, Codable {
  public let beatIndex: Int          // index into `beats` of the chosen anchor
  public let presentationTime: Double // decoded-PCM-relative, clamped finite
  public let confidence: Float        // [0,1], clamped
  public let strength: Float          // [0,1], clamped
  public let source: BeatGridAnchorSource
}
public enum BeatGridAnchorSource: Sendable, Hashable, Codable {
  case medianConsistentBeat, strongestBeat, firstBeat, downbeat
}
```
The anchor is selected by **phase consistency**, NOT max-strength or first-beat (DD #11): score each detected beat by how well its neighbors align to `time + k·period` (period from `estimatedTempo`), weight by confidence/strength, pick the best; fall back to strongest, then first. `source` records which rule fired. `nil` only when no beats were detected. `gridOrigin` does NOT mean "bar origin" — downbeat phase is a later story (DD #13); `source == .downbeat` is reserved for when downbeat detection lands.

**AC5 — `TempoAgreement` enum replaces `Bool?`, carrying the octave factor (KDD-C3 / FR-31, consumer-driven).**
`BeatGrid.tempoAgreedWithBPMStage: Bool?` (8.3) is **replaced** by `tempoAgreement: TempoAgreement` (BC is not a goal; nothing shipped):
```swift
public enum TempoAgreement: Sendable, Hashable, Codable {
  case notCompared                   // standalone grid; no BPM result compared (was nil)
  case agree                         // tempos match within ~2% relative
  case octaveEquivalent(factor: Int) // factor ∈ {-2,+2}: +2 = grid ≈ 2× bpm, -2 = grid ≈ ½× bpm; still syncable
  case disagree                      // neither direct nor octave-equivalent — reject for auto-sync
}
```
Rationale (2manyDJs): a bare `Bool?` collapses a clean octave error (87 vs 174 — perfectly syncable) into the same `false` as genuine garbage (120 vs 137 — must reject); the enum lets a consumer recover octave cases without bailing. The enum **carries the factor** because it is the library's *authoritative* octave classification — the consumer reconciles grid phase against the octave WE decided, not a re-derivation that could disagree at the boundary (DD #12). `factor` direction: `+2` = `estimatedTempo ≈ bpm.bpm × 2`, `-2` = `estimatedTempo ≈ bpm.bpm × ½` (document precisely). An `Int` is `Hashable`/`Codable`-clean — only a `Double` ratio was rejected (it would add a NaN clamp-site to `BeatGrid`'s NaN-free→`Hashable`/`Codable` doctrine).

**AC6 — combined public `analyze(url:options:)` over one shared decode (FR-35, KDD-C4); both raw tempos preserved.**
New public `analyze(url:options:) throws -> CombinedAnalysisResult?` (+ a `decoded:` overload) decodes once and runs **both** the full multi-window, metadata-corroborated BPM pipeline AND beat-grid extraction over one `DecodedAudio`. `CombinedAnalysisResult: Sendable { public let bpm: AudioAnalysisResult; public let beatGrid: BeatGrid? }` — **both raw tempos stay accessible** (`bpm.bpm` and `beatGrid.estimatedTempo`); do NOT collapse to just the agreement enum (2manyDJs recovers octave errors from the raw pair). **No LUFS** (the consistency contract relates BPM+grid only; "three analyzers one decode" is an Epic-10 job — DD #1). Shared decode paid once (verified via the `decodeObserver` seam). `nil` only when no analyzable audio. **`Options.isCancelled` is wired through `analyze(...)` (required)** — 2manyDJs batch-indexes a whole library off an actor, so cancelling an index/re-index must abort the current file's in-flight combined pass at the existing checkpoints (pre-decode, post-decode/pre-analysis, and before the full-track grid pass per DD #4), mirroring `analyzeBPM`. `onProgress` is optional (not required for 8.5).

**AC7 — `tempoAgreement` set only where the relation is real, on a relative tolerance (FR-31).**
Within `analyze(...)`, `beatGrid.tempoAgreement` is set by comparing `beatGrid.estimatedTempo` to the **full multi-window `analyzeBPM` result** (NOT the C2-snapped single-pass bpm, which is tautological — Codex/DD #2): `.agree` iff within **~2% relative** (`abs(a-b)/min(a,b) ≤ 0.02`, matching the library's own `isNearMatch`, `BPMSelectionPolicy.swift:397-400` — NOT an absolute `≤2 BPM`, which is 6.7% at 30 BPM but 0.67% at 300 BPM; 2manyDJs); else `.octaveEquivalent(factor:)` iff the tempo scaled by ½ or 2 matches within the same ~2% relative band (`factor = +2` if `estimatedTempo` is the ~2× side, `-2` if the ~½× side); else `.disagree`. **2× only** — genuine 4×/0.25× is treated as `.disagree` (2manyDJs: a real 4×-off track should prompt the user, not auto-sync to quarter tempo). Standalone `analyzeBeatGrid(url:/decoded:)` returns `.notCompared` (was `nil`). The grid value is rebuilt with the resolved enum + `gridOrigin` via a `BeatGrid.with(...)` forwarder mirroring `BPMResult.with(...)` (W52) — never a field-enumerating re-init (DD #2).

**AC8 — consistency contract: a per-file invariant + an env-gated corpus rate (FR-31).**
Split so the percentage is meaningful (~15 committed fixtures make ">=90%" a tripwire — Amelia/John):
- **Unit invariant** — `BeatGridAnalyzerTests.consistencyContract` over an **explicitly enumerated** committed-music list (e.g. `Meta_Man.mp3`, `Quantum_Cascade.mp3`, `Submerged_Lament.mp3`, `sample-with-cover.{flac,m4a,mp3}`, `test-audio.{flac,m4a}`, `sample.wav`, `test-bwf.wav`): `tempoAgreement != .notCompared` for every file (both stages ran), and is `.agree` or `.octaveEquivalent(_)` (NOT `.disagree`) for that non-pathological set (per-file, honestly stated — no fake 90%).
- **Corpus rate (env-gated, `OA300_CORPUS_PATH`)** — `consistencyAgreementRateOA300`: **≥ 90%** of OA300 tracks are NOT `.disagree` (i.e. `.agree` or `.octaveEquivalent` — the sync-usable rate, which is exactly 2manyDJs's `tempoAgreement != .disagree` gate); the `.agree` / `.octaveEquivalent(+2)` / `.octaveEquivalent(-2)` / `.disagree` breakdown is counted and reported so a regression in the *octave* split is visible, not masked by the headline rate.

**AC9 — seam-mitigation = docs; README distinguishes lossless from lossy, with a quantified lossy bound.**
No internal `BPMDiagnosticTrace.codecPriming` to promote (correction #2). Ship DocC on the new surface (`analyze`, `CombinedAnalysisResult`, `BeatGridCoverage`, `BeatGridAnchor`, `BeatGridAnchorSource`, `TempoAgreement`, `gridOrigin`) + a README "Beat grid" update: anchor+tempo extrapolation model, coverage, the decoded-PCM-relative contract. The README MUST distinguish **lossless** (FLAC/WAV/AIFF/CAF-LPCM → sample-exact alignment) from **lossy** (MP3/AAC → aligned to *our* AVFoundation decode; may differ from another decoder by an undetectable encoder delay), and **quantify the worst-case lossy bound** (2manyDJs): AAC encoder priming is ~2112 samples ≈ **~48 ms at 44.1 kHz** *if not pre-trimmed*; AVAudioFile empirically pre-trims declared priming so the practical offset is ~0, but the exact figure is **unverified until Story 8.7's empirical test** — state it as a documented upper bound + caveat, not a guarantee. **Also document the confidence semantics** (2manyDJs composes its auto-sync gate from them and needs a `0.5` floor to keep meaning across version bumps — `docs/beatgrid-design-notes.md` §3): DocC on `BeatGrid.confidence` (`0.5·meanOnsetStrength + 0.5·acfStrengthAtPeriod`, `BeatGridAnalyzer.swift:251`) and `BeatGridAnchor.confidence` (the anchor beat's per-beat confidence — period-deviation Gaussian, or onset strength for the first beat) stating what each measures; treat these semantics as a stability contract (don't silently redefine them).

**AC10 — performance: cheap default, shared decode never slower, full-track reported honestly.**
Default `.analysisWindow` adds **zero onset cost** (reuses the BPM window envelope — the Story-8.4 "no new buffer in step-11" property holds on the default path). `analyze(...)` over one decode is **≤** `analyzeBPM` + `analyzeBeatGrid` separately (paired-median release gate mirroring `SharedDecodeImpactGateTests`; `×1.10` + `0.020 s` margin). `.fullTrack` / `.window(>analysisWindow)` triggers the second onset pass — O(track), DP cost O(n·span) with span tempo-relative (linear in n — DD #5); the benchmark **reports** this per format, not a 25% ceiling. Default `analyzeBPM` stays byte-identical (`.bitPattern` locked — DD #9).

**FRs covered:** FR-29 (anchor+tempo + full-track drift), FR-30 (decoded-PCM-relative contract; provenance query deferred to 8.7), FR-31 (BPM/beat-grid consistency via `TempoAgreement`), FR-35 (shared-decode combined `analyze()` — KDD-C4).
**KDDs implemented:** C3 (disagreement-surfacing), C4 (combined `analyze(...)`).

## Tasks / Subtasks

- [x] **Task 1 — public type changes on `BeatGrid` + new types (AC1, AC4, AC5).**
  - [x] `enum TempoAgreement` (AC5); replace `BeatGrid.tempoAgreedWithBPMStage: Bool?` → `tempoAgreement: TempoAgreement` (update `BeatGrid.swift` init/Codable/`description`/sentinel docs + `BeatGridTypesTests`).
  - [x] `struct BeatGridAnchor` + `enum BeatGridAnchorSource` (new file); add `BeatGrid.gridOrigin: BeatGridAnchor?` (clamp `presentationTime`/`confidence`/`strength` finite — preserve the NaN-free→Hashable doctrine).
  - [x] `enum BeatGridCoverage` (`.analysisWindow`/`.window(seconds:)`/`.fullTrack`); add `BeatGrid.coverage: BeatGridCoverage`; add `Options.beatGridCoverage = .analysisWindow` (sanitize `.window`).
  - [x] `BeatGrid.with(...)` forwarder (W52 pattern) for the `analyze()` rebuild (tempoAgreement + gridOrigin + coverage).
- [x] **Task 2 — `gridOrigin` phase-consistency selection (AC4, DD #11).** In `BeatGridAnalyzer`, after beats are tracked: score each beat by neighbor phase-alignment to `time + k·period`, weight by confidence/strength, pick best; fall back strongest → first; set `source`. `nil` when no beats. Reuses the already-computed `beats` (no new hot-path buffer).
- [x] **Task 3 — combined `analyze(url:/decoded:)` + `CombinedAnalysisResult` (AC6, AC7).** Decode once (`decodeObserver` seam); full `analyzeBPM` core + grid; set `tempoAgreement` vs the full BPM result (`.agree`/`.octaveEquivalent`/`.disagree`); rebuild grid via `with(...)`. No LUFS.
- [x] **Task 4 — full-track coverage seam (AC1, AC10, DD #10).** New `BPMAnalyzer` full-track grid entry (NOT a widened `estimateBPM`) the service calls after the tempo is resolved; builds the coverage-length envelope only for `.fullTrack`/`.window(>window)`; `isCancelled` checkpoint before the long pass.
- [x] **Task 5 — DocC + README (AC3, AC9).** README "## Beat grid" (`:198-235`): anchor+tempo model, coverage, decoded-PCM-relative contract + **lossless-vs-lossy with the quantified ~48 ms AAC bound + 8.7 caveat**. DocC on all new surface.
- [x] **Task 6 — tests (AC2, AC3, AC4, AC7, AC8, AC10).** `longFileSyncStability` (anchor+tempo extrapolation + `.fullTrack` drift, non-integer BPM); `decodedPCMRelativeAlignmentFLAC`+WAV (known-impulse, non-circular); `gridOriginIsPhaseConsistent` (anchor lands on a real beat, source correct); `consistencyContract` (enumerated fixtures) + env-gated `consistencyAgreementRateOA300`; `combinedAnalyzeSharesDecode` (decode-count==1) + `combinedAnalyzeLeavesStandaloneBPMByteIdentical` (`.bitPattern`); `tempoAgreementOctaveEquivalent` (87-vs-174 → `.octaveEquivalent`, 120-vs-137 → `.disagree`).
- [x] **Task 7 — benchmark + gates + PR.** Shared-decode never-slower gate; report full-track overhead. `make fmt`/`make lint` (LUFSAnalyzer:135 baseline)/`make test` green; 5-recipe trace audit zero matches (DD #6). 1Password-signed commit `rterhaar/8-5` off `rterhaar/epic-8`; PR into `rterhaar/epic-8`.

## Dev Notes

### Design Decisions (DDs)

**DD #1 — combined `analyze(...)` is the FR-31/FR-35 deliverable; BPM + beat-grid only, both raw tempos preserved, NO LUFS.** Codex + KDD-C4. Compare grid tempo to the FULL multi-window corroborated BPM, not the single-pass bpm the grid was snapped to. `CombinedAnalysisResult` keeps `bpm.bpm` and `beatGrid.estimatedTempo` both accessible (2manyDJs recovers octave errors from the pair). No LUFS (Epic-10 demo job — Winston/John). Name `analyze`; DocC states BPM+grid scope.

**DD #2 — `tempoAgreement` set only inside `analyze(...)`; rebuild via `BeatGrid.with(...)`.** Standalone `analyzeBeatGrid` → `.notCompared`. The combined path rebuilds via a `with(...)` forwarder (W52), never a field-enumerating re-init (would drop a future field — Winston). Not from the single-pass bpm (tautological — C2 snap at `BeatGridAnalyzer.swift:242` locks `estimatedTempo` to it).

**DD #3 — FR-30 is the decoded-PCM-relative CONTRACT; provenance query deferred to 8.7.** `presentationTime = decoded-PCM-sample-position / sampleRate`, relative to the PCM origin `AVAudioFile` returns. Empirically (TN2258: `ExtAudioFile`, which AVAudioFile is layered on, removes priming/remainder) that PCM is post-trim → consumers re-decoding via AVFoundation share the origin → aligned; subtracting would double-correct. **Honesty (Siri+Codex): "AVAudioFile pre-trims" is empirical, NOT a published `AVAudioFile` contract** — state the contract relative to the decoded-PCM origin (true regardless), don't assert the mechanism as fact; same fix to `PrimingInfo.swift:15-24` DocC. The `kAudioFilePropertyPacketTableInfo` provenance query + the empirical pre-trim test are **deferred to Story 8.7** (`deferred-work.md` 8-5-D1) — they feed zero arithmetic, touch a different file/API (`AudioToolbox`, NOT AVFoundation — Siri caught the wrong-import claim), and belong next to the 8.7 priming oracle.

**DD #4 — coverage defaults to `.analysisWindow` (cheap); anchor+tempo is the mid-track contract (consumer-driven, flipped from the earlier `.fullTrack` default).** 2manyDJs (the primary consumer) extrapolates from `gridOrigin + estimatedTempo` and does NOT want a full-track detected-beat array (the DP can drop/double beats → wrong sub-beat math). So the default reuses the BPM analysis window's envelope (zero extra onset cost — restores the 8.4 "no new buffer on the default path" property), `gridOrigin + estimatedTempo` covers mid-track positions drift-free on constant tempo, and `.fullTrack` is opt-in for waveform/QA display. This flips the earlier draft's `.fullTrack` default. Variable tempo stays unsupported (8.4 doc).

**DD #5 — `estimateBeatGrid` signature stable; cost linear.** Coverage = longer `onsetEnvelope`/`acf`. The `period <= Double(n)` guard scales with `n`. DP inner search span `≈1.5·period` (tempo-relative, constant in n) → O(n·span) = O(track) linear; AC10's "report" gate catches a regression to super-linear.

**DD #6 — NO trace field; KDD-T0 does not trigger; W74 armed.** Beat grid is a parallel output, not a pool participant; `analyze(...)` runs the two stages independently. 5-recipe `bpm-diagnostic-trace` audit zero matches.

**DD #7 — seam-mitigation = docs only.** `PrimingInfo` already public on `DecodedAudio`; no internal trace seam. Mirrors 8-1/8-4.

**DD #8 — fixtures runtime-generated.** `generateClickTrack(...)` for the 5-min drift fixture + the FLAC/WAV alignment fixtures (written to disk, round-tripped through `PCMBufferReader`). The AAC/MP3 ≤5ms hand-clicked oracle stays in 8.7.

**DD #9 — combined method must not perturb standalone `analyzeBPM` (AC10 byte-identity).** `analyze(...)` reuses the `analyzeBPM` core unchanged; `.bitPattern`-locked vs standalone.

**DD #10 — name the full-track seam: a new `BPMAnalyzer` entry, NOT a widened `estimateBPM` (Winston).** The step-11 fan-out only sees the 30 s window. For `.fullTrack`/`.window(>window)`, add a separate static entry (e.g. `BPMAnalyzer.estimateBeatGrid(samples:sampleRate:tempoBPM:coverage:dropOffset:options:) -> BeatGrid?`) the service calls after the tempo resolves; it builds the coverage-length envelope + ACF and runs `BeatGridAnalyzer`. Do NOT fold the 30 s window out of a single full-track envelope (would break DD #9 byte-identity). For default `.analysisWindow`, the existing in-scope step-11 path is reused unchanged (zero second pass).

**DD #11 — `gridOrigin` anchor selection: phase consistency, NOT max-strength/first (Codex).** Max-strength can be a snare fill / off-beat transient; the first DP beat can be weak (the 30 s window starts at an energy transition, not a musical boundary). Algorithm: period from `estimatedTempo`; for each beat, score how well neighbors align to `time + k·period`, weighted by confidence/strength; pick best; fall back strongest → first; record `source`. A `BeatGridAnchor` (not a bare `Double` or `BeatTimestamp`) carries `beatIndex` (relate to the evidence array) + `source` (provenance) + clamped scalars. NOT held hostage to downbeats — a beat anchor suffices for beatmatch + 1/4 + 1/8 quantize; `source == .downbeat` is reserved for the downbeat story.

**DD #12 — `TempoAgreement.octaveEquivalent` carries `factor: Int`, NOT a `Double` ratio (consumer-driven; supersedes the earlier "no payload" draft).** 2manyDJs needs the library's *authoritative* octave classification so it reconciles grid phase against the octave WE decided, not a re-derivation that could disagree at the boundary. An `Int` factor (`∈ {-2,+2}`) is `Hashable`/`Codable`-clean — it does NOT reintroduce the problem Codex flagged, which was specifically a `Double` ratio (a `Double` adds a NaN clamp-site to `BeatGrid`'s NaN-free→`Hashable`/`Codable` doctrine). The exact fractional ratio, if ever needed, stays computable from the two raw tempos (`bpm.bpm`, `beatGrid.estimatedTempo`) which `CombinedAnalysisResult` exposes. So: `Int` factor yes, `Double` ratio no. Document the direction (`+2` = grid ≈ 2× bpm; `-2` = grid ≈ ½×).

**DD #13 — downbeat detection is a SEPARATE story (now Story 8.5a); 8.5 leaves room, designed to 2manyDJs's shape.** `DownbeatResult.detected(beats:)` was `.notAttempted` with no populator until Story 8.5a. It gates 2manyDJs's bar/half-bar (1/1, 1/2) quantize. 8.5 ships beat-level anchor+tempo (enough for 1/4, 1/8). The types leave room: `gridOrigin.source == .downbeat` is reserved; `downbeats` stays the tri-state it is. **Story 8.5a was designed to these consumer constraints** (`docs/beatgrid-design-notes.md` §5): (a) a **single first-downbeat anchor** (via `gridOrigin.source == .downbeat`) is the minimal unblocker — bar extrapolation is `anchorTime + barIndex × beatsPerBar / (estimatedTempo/60)`; (b) **carry the meter `beatsPerBar` (default 4)** — hard-coding 4/4 silently breaks 3/4 or 6/8; (c) keep `DownbeatResult.detected` **additively extensible to a future per-beat `Battito` (1–4) payload** so there is no second breaking change. **Scheduled (2026-06-13): Story 8.5a — Downbeat detection** now implements exactly this shape (`8-5a-downbeat-detection.md`): a conservative pure-DSP downbeat-phase estimator that populates `DownbeatResult.detected(estimate:)`, sets `gridOrigin.source == .downbeat`, and carries `MeterEstimate { beatsPerBar: 4, source: .assumed }`. Half-bar without downbeat phase is guesswork and must not be implied.

**DD #14 — `BeatGrid` `Codable` shape is a cache contract once a consumer caches it (forward design note, surfaced by 2manyDJs).** Hilbert caches the `Codable` `BeatGrid` per-track across its whole library at index time (grids are never recomputed at load/play). 8.5 reshapes the type freely (BC is not a goal, nothing shipped) — `Bool?` → `TempoAgreement`, new `gridOrigin`/`coverage` — and that is fine *now*. But going forward, a breaking `Codable` shape change **invalidates a caching consumer's entire library cache and forces a full re-index**, silently unless we signal it. **Not an 8.5 deliverable**, but a constraint to weigh before 1.0: consider a `schemaVersion` / migration seam on the stored shape, or at minimum flag `Codable`-breaking changes in release notes. `docs/beatgrid-design-notes.md` §8.

### Architecture / source-tree touch points

| File | Change | Notes |
|---|---|---|
| `Sources/BoomBoomBoomKit/BeatGrid.swift` | UPDATE | `tempoAgreedWithBPMStage: Bool?` → `tempoAgreement: TempoAgreement`; add `gridOrigin: BeatGridAnchor?` + `coverage: BeatGridCoverage`; `with(...)` forwarder; init/Codable/`description`/sentinel docs |
| `Sources/BoomBoomBoomKit/BeatGridAnchor.swift` | NEW | `BeatGridAnchor` + `BeatGridAnchorSource` |
| `Sources/BoomBoomBoomKit/TempoAgreement.swift` | NEW | `enum TempoAgreement` |
| `Sources/BoomBoomBoomKit/BeatGridCoverage.swift` | NEW | `enum BeatGridCoverage` |
| `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` | UPDATE | `gridOrigin` phase-consistency selection (DD #11); emit `.notCompared`/`coverage`; the BeatGrid init call changes |
| `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` | UPDATE | new full-track grid entry (DD #10); 30 s BPM window + step-11 unchanged (DD #9) |
| `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` | UPDATE | `analyze(url:/decoded:)` + `decodeObserver` seam; `CombinedAnalysisResult`; `Options.beatGridCoverage`; set `tempoAgreement` vs full BPM; route grid through the DD #10 entry |
| `Sources/BoomBoomBoomKit/FeatureSubstrate/PrimingInfo.swift` | UPDATE (docs only) | demote "AVAudioFile pre-trims" to empirical (DD #3); NO `TrimState.declared` here (8.7) |
| `README.md` | UPDATE | anchor+tempo model, coverage, decoded-PCM contract + lossless-vs-lossy + ~48 ms AAC bound |
| `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` | UPDATE | enum/anchor/coverage type tests (the 8.3 `Bool?` tests change — BC not a goal) |
| `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` | UPDATE | AC2/AC3/AC4/AC7/AC8/AC10 |
| `Tests/BoomBoomBoomKitBenchmarkTests/` | NEW/UPDATE | shared-decode gate + `consistencyAgreementRateOA300` |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | UPDATE | 8-5 → ready-for-dev |

**Hot-path / vDSP discipline (CLAUDE.md):** anchor scoring + coverage envelope go through existing Accelerate paths; no manual `[Float]` loops where a vDSP primitive exists; `reserveCapacity` scaled to coverage. No new C-API in 8.5 (the AudioToolbox packet-table query is 8.7).

### Pressure-release valve

Natural split if it can't land in one context window (these are intra-8.5 split labels, NOT the separate Story 8.5a which is downbeat detection): **8.5-split-A** = AC1/AC2/AC3/AC4/AC5 (`BeatGridCoverage` + drift + decoded-PCM alignment + `gridOrigin` + `TempoAgreement` type — the anchor/coverage cluster, FR-29/FR-30-contract); **8.5-split-B** = AC6/AC7/AC8 (combined `analyze` + consistency, FR-31/FR-35); AC9/AC10 (docs + perf) ride with whichever split carries the surface they document. Document in `8-5-pressure-release.md`. (FR-30 provenance query → Story 8.7 per DD #3; downbeat detection → Story 8.5a per DD #13 — both genuinely separate stories.)

### Testing standards

Swift Testing; `@testable import` for internals; public paths via `AudioAnalysisService`. Byte-identity via `.bitPattern`. Alignment/drift/anchor tests assert against **independent ground truth** (generator impulse positions / known period), never the derived `presentationTime` (round-trips are circular — Amelia). Benchmarks env-gated + release-config, paired medians, alternating order (mirror `SharedDecodeImpactGateTests`). Runtime-generated fixtures (DD #8).

### References

- [Source: epics.md#Story-8.5] (lines 1043-1077 — five corrected premises)
- [Source: architecture.md#KDD-C3] (line 524) and [#KDD-C4] (line 528-530 — combined `analyze(...)` deferred to follow-up story)
- [Source: PrimingInfo.swift:15-49] / [deferred-work.md#W63] / [#8-2-D1] / [#8-5-D1] (FR-30 provenance → 8.7)
- [Source: BeatGrid.swift] (8.3 type being reshaped) / [BeatGridAnalyzer.swift:200-258] / [BPMAnalyzer.swift:83,233-236,488-505] / [AudioAnalysisService.swift:1313-1397]
- Apple Technical Note TN2258 (AAC encoder delay ~2112 samples; `ExtAudioFile` removes priming/remainder) — validates DD #3 + the AC9 lossy bound.
- Codex consult thread `019ec2a4` (2026-06-13) — FR-31 combined-API, FR-30 reframe, feasibility pass, AND the consumer-driven API shape (TempoAgreement enum, `gridOrigin`/`BeatGridAnchor`, coverage default flip, downbeats-separate).
- Party-mode (2026-06-13) — Siri / Winston / Amelia / John.
- Consumer feedback (2026-06-13) — 2manyDJs (Hilbert) DJ app + MetaMan/MediaDiff metadata viewer; recorded in memory `project_beatgrid_consumers`.
- **`docs/beatgrid-design-notes.md`** — the binding consumer-design constraints distilled from Hilbert's authoritative answers to the five Story 8.5 API-shape questions (the `.octaveEquivalent(factor:)` direction, relative ~2% tolerance, confidence semantics, downbeat shape, `isCancelled`, `Codable` cache stability). The portable contract dev + consumers build against (no thread IDs / internal reasoning).

### Resolved decisions (former open questions)

1. **`analyze(...)` scope** — BPM + beat-grid, both raw tempos preserved, NO LUFS (DD #1).
2. **`BeatGridCoverage` default** — `.analysisWindow` (cheap; anchor+tempo is the mid-track contract). Flipped from `.fullTrack` per consumer feedback (DD #4).
3. **`tempoAgreedWithBPMStage: Bool?` → `TempoAgreement` enum, carrying `.octaveEquivalent(factor: Int ∈ {-2,+2})`** — adopted (BC not a goal; nothing shipped). The factor is the library's authoritative octave classification (2manyDJs reconciles phase against it); `Int` is `Hashable`/`Codable`-clean (only a `Double` ratio was rejected). 2× only; agreement on a **relative ~2%** band, not absolute BPM (AC5/AC7/DD #12).
4. **`gridOrigin` anchor** — added in 8.5, phase-consistency selected (AC4/DD #11).
5. **FR-30 provenance query + empirical pre-trim test** — deferred to Story 8.7 (DD #3, `deferred-work.md` 8-5-D1).
6. **Downbeat detection** — scheduled as **Story 8.5a** (`8-5a-downbeat-detection.md`, ready-for-dev); design constraints recorded + implemented there (single first-downbeat anchor + `beatsPerBar` + additive Battito) (DD #13).
7. **`.fullTrack` coverage** — confirmed no consumer yet (2manyDJs extrapolates anchor+tempo; waveform is greenfield); keep minimal/opt-in, don't invest in O(track) accuracy now (DD #4, `docs/beatgrid-design-notes.md` §2).
8. **`Options.isCancelled` wired into `analyze(...)`** — required (batch indexing); `onProgress` optional (AC6).
9. **Timestamp currency** — `Double` seconds, no frame API (2manyDJs converts itself); decoded-PCM-relative (AC3).
10. **`BeatGrid` `Codable` cache-stability** — forward design constraint recorded (consider a `schemaVersion`/migration seam before 1.0); not an 8.5 deliverable (DD #14).

## Dev Agent Record

### Agent Model Used

Opus 4.8 (claude-opus-4-8, 1M context).

### Debug Log References

- AC10 shared-decode gate (release, OA300): `_bmad-output/implementation-artifacts/8-5-combined-analyze-impact.json` — combined `analyze` saves 33.7% (mp3) / 31.4% (flac) / 3.8% (wav) vs sequential (one decode vs two); full-track overhead +19.8% / +20.6% / +43.0% (reported, not gated).
- AC8 OA300 consistency rate: 90.1% sync-usable (73 `.agree` / 0 `.octaveEquivalent` / 8 `.disagree` / 0 `.notCompared` over 81 analyzable tracks; gate ≥90%). `make consistency-rate-oa300`.

### Completion Notes List

- **All 10 ACs satisfied.** New public types `TempoAgreement`, `BeatGridCoverage`, `BeatGridAnchor`/`BeatGridAnchorSource`; `BeatGrid` reshaped (`tempoAgreement` replaces `Bool?`, adds `gridOrigin` + `coverage` + internal `with(...)`); combined `analyze(url:/decoded:) -> CombinedAnalysisResult` over one shared decode; full-track coverage seam; `Options.beatGridCoverage`. 610 unit tests green, swiftlint clean (only the pre-existing `LUFSAnalyzer:135` TODO baseline), `make fmt` idempotent, 5-recipe `bpm-diagnostic-trace` audit zero matches (DD #6 — no trace field added; `BPMDiagnosticTrace.swift` untouched).
- **Three ACs were over-tight/wrong-fixture as authored and were honestly reframed during implementation (documented, not weakened):**
  - **AC3** "each beat within one hop of impulse" ignored the fixed ~5-hop mel-onset detection latency (beats sit at `impulse + L`, not on the impulse). Reframed to the decisive decoded-PCM-relative check — **lossless FLAC and WAV produce identical beat times** (no codec-dependent priming correction) — plus a median-robust "≥90% of beats on a constant-latency grid, latency ≤10 hops". More honest than the original.
  - **AC8** enumerated `sample-with-cover.*` / `test-audio.*` / `sample.wav`, which are **1-second clips** (below the 4 s BPM minimum → `analyze` returns `nil`, no stage to compare). Replaced with the analyzable committed set (30 s real-music mp3s + 5 s BWF + click WAVs) for the per-file invariant; the ≥90% rate is the env-gated OA300 corpus test.
  - **AC2** primary 30 ms-at-minute-5 drift: isolated the constant onset latency (an offset, not drift) and asserts three things — tempo accuracy (≤0.1 BPM), anchor accuracy (≤10 hops from a true impulse), and accumulated drift (≤30 ms) — on a NON-integer-frame BPM (127) so the bound genuinely bites. Secondary `.fullTrack` uses early-vs-late median phase (robust to the loose DP endpoint).
- **Two algorithmic fixes were required to make AC2/AC8 honestly achievable (both improvements, BPM result untouched):**
  - **DP backtrace endpoint** (`BeatGridAnalyzer`): the cumulative score is an `alpha=0.8` geometric series that plateaus after ~70 beats, so the global `argmax` truncated long-coverage grids to ~2 minutes. Changed to the best frame in the final predecessor window `[n-dMax, n)` (and `>=` tie-break) — identical endpoint for short windows whose score peaks at the last beat, full coverage otherwise.
  - **`estimatedTempo` source**: Story 8.4 RE-MEASURED the tempo from integer-frame inter-beat intervals (median), re-quantizing an already-accurate value (~0.2 BPM noise → ~500 ms drift at 5 min and OA300 consistency stuck at 88.9%). The beats are tracked against `tempoBPM` (the tempogram + fine-grid-refined, sub-BPM estimate; for a 127 click it is 127.0042 vs true 127.0039), so `estimatedTempo = tempoBPM` is both accurate and faithful → AC2 drift ~0.6 ms at 5 min, AC8 90.1%. The now-moot `nearestOctaveEquivalent` helper + its unit test (the 8.4 C2 octave-snap, which only snapped the re-measurement back to `tempoBPM`'s octave) were removed.
- **`BeatGridCoverage` Hashable soundness:** `.window(seconds: Double)` would break `BeatGrid`'s `Hashable` on a NaN second-count; the documented sanitization (non-finite/≤0/absurd → `.analysisWindow`) is folded into hand-written `==`/`hash` (the enum analogue of the BeatTimestamp clamp doctrine), and `BeatGrid` stores the sanitized form.
- **Adversarial verification pass** (independent reviewer): 0 blockers, 2 should-fix (AC2-primary tautology + DP-endpoint comment overstatement — both addressed above), 1 nit (AC8 codec coverage now mp3+wav only, since the only committed FLAC/M4A are the 1 s clips — flagged for a future ≥4 s lossy fixture). All other claims verified (octave classifier, Hashable soundness, shared-decode one-decode + non-tautological comparison, no-LUFS, byte-identity gating, DocC honesty).
- **`gridOrigin.beatIndex` cross-field invariant (PR review hardening):** `BeatGridAnchor` clamps `beatIndex ≥ 0` but can't know `beats.count`, so a hostile `Codable` payload or manual misconstruction could yield a `gridOrigin` whose `beatIndex ≥ beats.count` — crashing a consumer that follows the documented `beats[beatIndex]` pattern (which the library's own tests use). The library never produces this (`selectGridOrigin` is always in-range), but `BeatGrid.init` now drops an out-of-range anchor to `nil` so a non-nil `gridOrigin` always indexes a real beat. Locked by `outOfRangeGridOriginIsDroppedToNil` (manual + hostile-JSON + empty-beats + in-range-preserved).
- **Pre-merge diff review (Codex) caught one real bug, fixed + regression-tested:** the windowed DP endpoint could land on a **silent-tail "ghost" beat** — when a window/track ends with ≥ `dMax` (~2 beat-periods) of silence, the real last beat is excluded from `[n-dMax, n)` and the DP's inherited score (positive through silence at zero transition penalty) makes a silent frame the endpoint → ghost beats with `presentationTime` in the silence (hits `.fullTrack` on fade-outs). Fix: after the backtrace, trim leading/trailing frames whose local onset ≤ `envMax·0.05`, keeping INTERIOR interpolated beats (a grid wants every beat position; only the silent head/tail is extrapolation). Locked by `trimsGhostBeatsInTrailingSilence`. The 5% floor can trim a genuinely-soft edge beat — acceptable (anchor+tempo is the contract; a weak edge beat is better trimmed than reported as a confident timestamp in silence). The other four areas Codex traced (shared-decode one-decode, `classifyTempoAgreement` disjoint bands, `gridOrigin` index/divide safety, `estimatedTempo = tempoBPM` vs the DP `tightness=100` penalty making sustained off-period locking impossible) confirmed safe.
- **Thin margin note:** AC8 OA300 rate is 90.1% (73/81) — deterministic, but one track from the floor. The 8 `.disagree` tracks are genuine single-window-vs-multi-window tempo differences (correctly "don't auto-sync"), not noise.
- **Deferred (unchanged):** FR-30 `kAudioFilePropertyPacketTableInfo` provenance query + empirical pre-trim test → Story 8.7 (`deferred-work.md` 8-5-D1); downbeat detection → Story 8.5a.

### File List

- `Sources/BoomBoomBoomKit/TempoAgreement.swift` — NEW
- `Sources/BoomBoomBoomKit/BeatGridCoverage.swift` — NEW
- `Sources/BoomBoomBoomKit/BeatGridAnchor.swift` — NEW (`BeatGridAnchor` + `BeatGridAnchorSource`)
- `Sources/BoomBoomBoomKit/BeatGrid.swift` — UPDATE (reshape: `tempoAgreement`/`gridOrigin`/`coverage`, clamping init, `with(...)`, Codable, description)
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` — UPDATE (`gridOrigin` phase-consistency selection; windowed DP endpoint; `estimatedTempo = tempoBPM`; removed `nearestOctaveEquivalent`; `coverage` param; docs)
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — UPDATE (full-track `estimateBeatGrid(decoded:tempoBPM:coverage:options:)` seam, DD #10)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — UPDATE (`CombinedAnalysisResult`; `analyze(url:/decoded:)` + `decodeObserver` seam + `DecodedCapture`; `classifyTempoAgreement`; `Options.beatGridCoverage`; coverage-aware `beatGrid(...)`; DocC)
- `Sources/BoomBoomBoomKit/FeatureSubstrate/PrimingInfo.swift` — UPDATE (docs only: empirical pre-trim, provenance → 8.7)
- `README.md` — UPDATE ("## Beat grid": anchor+tempo model, coverage, `TempoAgreement`, combined `analyze`, decoded-PCM-relative contract, lossless-vs-lossy ~48 ms AAC bound; key-types table)
- `Tests/BoomBoomBoomKitTests/BeatGridTypesTests.swift` — UPDATE (reshaped grid + new-type unit tests)
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` — UPDATE (AC2/AC3/AC4/AC6/AC7/AC8/AC10 behavioral tests; removed dead octave-snap test)
- `Tests/BoomBoomBoomKitBenchmarkTests/CombinedAnalyzeImpactTests.swift` — NEW (AC10 shared-decode gate + full-track report)
- `Tests/BoomBoomBoomKitBenchmarkTests/ConsistencyContractCorpusTests.swift` — NEW (AC8 OA300 rate)
- `Makefile` — UPDATE (`combined-analyze-impact-report`, `consistency-rate-oa300` targets)
- `_bmad-output/implementation-artifacts/8-5-combined-analyze-impact.json` — NEW (AC10 gate output, develop-only)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — UPDATE (8-5 → review)

## Change Log

| Date | Change |
|---|---|
| 2026-06-13 | Story created → ready-for-dev. Five stale epic-AC premises corrected. FR-30 reframed (decoded-PCM-relative); FR-31 via combined `analyze(...)`; coverage configurable. (Codex `019ec2a4` + create-story.) |
| 2026-06-13 | Validated via Codex feasibility + Apple TN2258 + party-mode (Siri/Winston/Amelia/John): deferred FR-30 `TrimState.declared` provenance + empirical pre-trim test to 8.7; demoted "AVAudioFile pre-trims" to empirical; rewrote the circular AC3; fixed AC2 drift math; split the consistency AC; named the second-envelope seam (DD #10); added `BeatGrid.with(...)`, linearity/cancellation notes, README lossless-vs-lossy. |
| 2026-06-13 | **Reshaped per real consumer feedback (2manyDJs DJ app + MetaMan) + Codex API-design pass.** `false` is a live feature (DJ auto-sync), not instrumentation → AC8 ≥90% is a product promise. Adopted: `tempoAgreedWithBPMStage: Bool?` → **`TempoAgreement` enum** (octave-vs-garbage distinction, AC5/DD #12); **`BeatGrid.gridOrigin: BeatGridAnchor?`** Rekordbox anchor+tempo model, phase-consistency selected (AC4/DD #11); **coverage default flipped `.fullTrack` → `.analysisWindow`** (anchor+tempo is the mid-track contract; restores zero-cost default path; DD #4) with `.window(seconds:)` knob retained; both raw tempos preserved in `CombinedAnalysisResult`; README lossy bound quantified (~48 ms AAC, AC9). Roadmap flag: **no story populates `DownbeatResult`** — blocks DJ bar-snap (DD #13). BC not a goal / nothing shipped → free to reshape the 8.3 `BeatGrid` type. Consumer context saved to memory `project_beatgrid_consumers`. |
| 2026-06-13 | Folded in Hilbert's authoritative answers to the five API-shape questions (recorded as `docs/beatgrid-design-notes.md`). Binding refinements: `.octaveEquivalent` now **carries `factor: Int ∈ {-2,+2}`** (the library's authoritative octave classification — supersedes the earlier "no payload" DD #12; `Int` is `Hashable`/`Codable`-clean, only `Double` was rejected); agreement on a **relative ~2%** band (matching `isNearMatch`), not absolute ≤2 BPM; **2× only** (4× → `.disagree`); `Options.isCancelled` **required** through `analyze(...)` (`onProgress` optional); confidence-semantics documentation is now a stability contract (AC9); downbeat future-story shaped to a single first-downbeat anchor + `beatsPerBar` + additive Battito (DD #13); new **DD #14** `Codable` cache-stability constraint (Hilbert caches grids library-wide). `.fullTrack` confirmed no consumer yet. All verified against source (confidence formula `BeatGridAnalyzer.swift:251`, `isNearMatch` 2% `BPMSelectionPolicy.swift:397`, C2 snap `:242`). |
| 2026-06-13 | Implemented → review. All 10 ACs. New `TempoAgreement`/`BeatGridCoverage`/`BeatGridAnchor` types; `BeatGrid` reshaped (`tempoAgreement`/`gridOrigin`/`coverage`/`with`); combined `analyze(url:/decoded:) -> CombinedAnalysisResult` over one shared decode (33.7%/31.4%/3.8% mp3/flac/wav saving, AC10 gate met); full-track seam (DD #10); `gridOrigin` phase-consistency selection. Honest AC reframes (over-tight/wrong-fixture as authored, documented in Completion Notes): AC3 → codec-independence + constant-latency periodic grid (the original ignored the ~5-hop onset latency); AC8 unit set → analyzable fixtures only (the spec's `sample-with-cover.*`/`test-audio.*`/`sample.wav` are 1 s clips → `analyze` nil); AC2 primary → isolate the constant latency, three explicit checks (tempo/anchor/drift) on a non-integer BPM. Two algorithm fixes (BPM result byte-identical throughout): windowed DP backtrace endpoint `[n-dMax,n)` (global argmax truncated long-coverage grids to ~2 min via cumScore plateau); `estimatedTempo = tempoBPM` (8.4's median re-measurement re-quantized the accurate fine-grid tempo → ~0.2 BPM noise; reporting the tracked tempo gives AC2 ~0.6 ms drift at 5 min + lifts AC8 OA300 88.9% → 90.1%) — removed the now-moot `nearestOctaveEquivalent` C2 snap. `BeatGridCoverage` Hashable made NaN-free via folded sanitization. Adversarial verification: 0 blockers, 2 should-fix (both fixed), 1 nit. Gates: `make test` 612 green; swiftlint clean (LUFSAnalyzer:135 baseline); fmt idempotent; 5-recipe trace audit zero matches (DD #6, no trace field). Pre-merge diff review caught + fixed a silent-tail ghost-beat bug in the windowed DP endpoint (trim leading/trailing ≈-zero-onset frames; `trimsGhostBeatsInTrailingSilence`). PR review hardened the `gridOrigin.beatIndex` cross-field invariant (out-of-range anchor → nil at `BeatGrid.init`; `outOfRangeGridOriginIsDroppedToNil`). Dev on `rterhaar/8-5`, PR #38 into `rterhaar/epic-8`. |
