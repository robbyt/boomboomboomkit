---
baseline_commit: ca8885613424a6954af92151a45280db7f497d4d
---

# Story 8.4: Davies & Plumbley beat-tracking DP — `BeatGridAnalyzer` + step 11 insertion

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **library maintainer**,
I want **the Davies & Plumbley 2004–2005 Rayleigh-weighted causal dynamic-programming beat-tracker landed as an internal `BeatGridAnalyzer` running as pipeline step 11, reusing the in-scope onset envelope + autocorrelation `BPMAnalyzer.estimateBPM` already computes**,
so that **`analyzeBeatGrid(url:options:) -> BeatGrid?` ships as a public sibling to `analyzeBPM` with zero new dependencies, no aubio linkage, and no transcription of GPL-3.0 source**.

---

## ⚠️ Context corrections (read FIRST — three material epic-AC errors verified against the codebase)

The factual-claims grep mandated before authoring (per project memory) surfaced **three** epic-AC statements that do not hold against the actual source. Each is resolved by a DD below; the corrected wording flows into the Acceptance Criteria. Do **not** implement the literal epic AC where it conflicts with these — the codebase is authoritative.

1. **The analyzer signature in `epics.md:1013` is wrong on BOTH parameters.**
   Epic says: `estimateBeatGrid(features: FeatureSubstrate.OnsetFeatures, acf: ACFBuffers) -> BeatGrid?`.
   - `FeatureSubstrate.OnsetFeatures` (`Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeatures.swift:38-40`) is a **2-D log-mel matrix** carrier (`logMelData: [Float]` of `frames × melBands`). The Davies & Plumbley beat-tracker and the KDD-C2 `strength` formula both operate on the **1-D onset detection function** — `onsetResult.fullBand` (a `[Float]` over time at `onsetRate` Hz), exactly what `BPMAnalyzer.estimateBPM` binds to `var onsetEnvelope` at `BPMAnalyzer.swift:241`. The mel matrix is the wrong input.
   - `ACFBuffers` (`BPMAnalyzer.swift:969`) is a **`private struct` of eight raw FFT scratch pointers**, allocated and `defer`-deallocated inside a single `estimateBPM` call (`BPMAnalyzer.swift:285-286`). It is not the autocorrelation *result* and cannot be a cross-type algorithm input. The result the DP needs is the `acf: [Float]` value (`var acf = computeAutocorrelation(...)`, `BPMAnalyzer.swift:289`) plus the resolved tempo (`winner.bpm`).
   → **Corrected signature in DD #1.**

2. **`epics.md:1021` says step 11 "records a typed-evidence `BeatGridTraceEntry` per KDD-T0" — KDD-T0 does not trigger, and `BeatGridTraceEntry` is not defined anywhere.**
   `architecture.md` KDD-T0 (lines 703–744) gates a typed trace field on BOTH "affects winner selection / weight resolution / gate firing" AND "collision-prone at the call site." Beat grid is a **parallel post-disambiguation step-11 output**; it does not feed BPM winner selection. Story 8.3 already adjudicated this (its DD #6 + AC8) and recorded the re-evaluation hook **W74**: KDD-T0 is re-run **only when a beat-grid *producer* is wired into the `UnifiedSignalPool`** (making `estimatedTempo`/`confidence` weight-resolution inputs via the producerless `SignalSource.beatGrid`, W53). Story 8.4 keeps beat grid a standalone sibling of `analyzeBPM` — it does **not** enter the pool — so W74's trigger condition is still unmet.
   → **No `BPMDiagnosticTrace` field is added in 8.4. KDD-T0 still does not trigger; W74 stays armed. See DD #3.** This is the single most important author's-note: it contradicts the literal epic AC and is surfaced as Open Question #1.

3. **`epics.md:1031-1033` cites a Story-6.2 seam (`AudioAnalysisService.estimateBeatGrid(decoded:)`-style internal helper) to promote — it does not exist.**
   Grep of `AudioAnalysisService.swift` finds no `estimateBeatGrid` / `analyzeBeatGrid` member (only the public `analyzeBPM`/`analyzeLUFS` families). This is the identical "Story 6.2 seam was never built" pattern Stories 8.1, 8.2, and 8.3 each hit. As in those, the seam-mitigation obligation reduces to **adding the new public surface with DocC + a README section** (the README already carries a forward-pointing "## Beat grid" stub at `README.md:198-216` that 8.4 updates). See DD #4 + DD #12.

---

## Acceptance Criteria

> Corrected per the three Context corrections above. ACs are the contract; the epic's literal wording is superseded where noted.

**AC1 — internal `BeatGridAnalyzer` with the corrected signature.**
Given the existing placeholder `enum BeatGridAnalyzer` (`Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift`),
When the test suite runs,
Then `BeatGridAnalyzer` is **`internal`** (not public — KDD-C6 defers the engine protocol until a second concrete impl lands), exposes `static func estimateBeatGrid(onsetEnvelope: [Float], onsetRate: Double, hopSize: Int, sampleRate: Double, acf: [Float], tempoBPM: Double, windowStartSample: Int) -> BeatGrid?` (DD #1 — **NOT** `features: OnsetFeatures, acf: ACFBuffers`), imports only `Foundation` and `Accelerate`, and **retains** the `onsetFeatures(for:weighting:)` seam member that `FeatureSubstrateTests.swift:61` exercises for the KDD-C4 cross-consumer bit-equality invariant (DD #8).

**AC2 — aubio GPL-3.0 fence.**
Given the aubio GPL-3.0 license,
When code review inspects `BeatGridAnalyzer.swift`,
Then no aubio source is transcribed; `///` doc comments cite `aubio/src/tempo/beattracking.c` **for inspiration only** plus Davies & Plumbley ISMIR 2004 + AES 118 2005 academic references; the file imports only `Foundation` and `Accelerate`; and `Package.swift` carries no new dependency (verified-clean baseline: `Package.swift` has zero external `.package(...)` entries).

**AC3 — beat grid lands as stable step 11; steps 1–10c unchanged; confidence renumbers to step 12.**
Given the "pipeline step numbers are stable identifiers" rule,
When `BPMAnalyzer.estimateBPM` is updated to fan out to `BeatGridAnalyzer.estimateBeatGrid` after step 10c (gated by a new `options.computeBeatGrid` flag, default `false`),
Then beat-grid extraction is documented as **step 11**; steps 1–10c are byte-for-byte unchanged; the pre-existing inline `// Step 11: Confidence` label (`BPMAnalyzer.swift:454`) renumbers to **`// Step 12: Confidence`** in the same edit (DD #2 — resolves the collision; confidence is not in CLAUDE.md's canonical 1→10c roster, so this is a label correction, not a public renumber); and **no** `BPMDiagnosticTrace` field is added (DD #3 — KDD-T0 does not trigger; the 5-recipe `bpm-diagnostic-trace` audit A–E returns zero matches).

**AC4 — default path is byte-identical (zero cost when beat grid not requested).**
Given `options.computeBeatGrid` defaults to `false`,
When `analyzeBPM` runs with default options,
Then `BPMResult` output (bpm, confidence, candidates, trace) is byte-identical to the Story-8.3 baseline — the fan-out branch is not entered, no beat-grid buffer is allocated, and the `BPMResult.beatGrid` field is `nil` (DD #2). Locked by a byte-identity test mirroring the `.dspOnly`/`LUFSByteIdentity` precedent.

**AC5 — `BeatTimestamp` provenance per KDD-C2, no new hot-path allocation.**
Given the ADR-3 buffer-lifetime pattern,
When `estimateBeatGrid` runs inside `estimateBPM`'s scope (before the `defer` deallocations fire),
Then it reuses the in-scope `onsetEnvelope` and `acf` arrays (no new ACF/onset buffer allocation in the hot path); `onsetEnvelopeMax` is computed once via `vDSP_maxv`; each `BeatTimestamp.strength = onsetEnvelope[frame] / onsetEnvelopeMax` (clamped at construction, NaN-free); `frame = Int((presentationTime * sampleRate / Double(hopSize)).rounded())` with an in-bounds guard; and `presentationTime = (Double(windowStartSample) + Double(frame) * Double(hopSize)) / sampleRate` so beats are **track-relative**, offset by the step-1 energy-scan `dropOffset` (DD #6 — full codec-priming trim + long-file drift is Story 8.5).

**AC6 — public `analyzeBeatGrid` sibling returns a populated grid within ±5 BPM of `analyzeBPM`.**
Given `analyzeBeatGrid(url:options:) -> BeatGrid?` and `analyzeBeatGrid(decoded:options:) -> BeatGrid?` are added as public siblings to `analyzeBPM` (mirroring the `analyzeLUFS` two-overload + internal `decodeObserver` seam, DD #4),
When consumers call `analyzeBeatGrid` against the OA300 fixtures,
Then every fixture returns a non-nil `BeatGrid` with `beats.count > 0`, `estimatedTempo > 0`, and `estimatedTempo` within ±5 BPM of the corresponding `analyzeBPM` result on the same file; `downbeats == .notAttempted` (DD #9 — downbeat *detection* is out of scope for 8.4); and `tempoAgreedWithBPMStage == nil` (DD #10 — the consistency contract is Story 8.5 / KDD-C3).

**AC7 — seam-mitigation reduces to docs (no Epic-6 seam exists to promote).**
Given Mary's Epic-6 → Epic-8 seam-mitigation rule and the verified absence of any internal `estimateBeatGrid`/`analyzeBeatGrid` helper (Context correction #3),
When the PR lands,
Then (a) `analyzeBeatGrid(url:options:)` + `analyzeBeatGrid(decoded:options:)` carry DocC `///` comments; (b) the README "## Beat grid" section (`README.md:198-216`) is updated from its "lands in a later release" stub to document the live `analyzeBeatGrid` method, and a Public API table row for `analyzeBeatGrid` is added; (c) the PR description records the KDD-T0 non-trigger + W74-still-armed rationale (DD #3).

**AC8 — performance gates.**
Given `make benchmark` and the Story-8.2 `SharedDecodeImpactGateTests` perf harness,
When OA300 wall-clock is measured at default intensity with `analyzeBeatGrid` **not** requested,
Then regression vs the Story-8.2 baseline is ≤ 2% (trivially met by AC4 byte-identity; reported, not flake-gated); **and** when beat grid is invoked alongside BPM under shared decode, additional wall-clock overhead vs BPM-only is ≤ 25% — measured in release config with the alternating-order / per-file-median / noise-margin pattern of `SharedDecodeImpactGateTests` (DD #11).

**AC9 — unit coverage for the analyzer.**
Given a new `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` (Swift Testing `@Suite`/`@Test`),
When the suite runs,
Then it covers: synthetic click-track recovery (`bpm-120-click.wav`, `bpm-140-click.wav`, `bpm-170-click.wav`, `bpm-85-click.wav` from `BoomBoomBoomKitTestSupport` — recovered `estimatedTempo` within ±5 BPM and monotonically increasing `presentationTime`); the ±5-BPM-vs-`analyzeBPM` agreement on ≥2 real fixtures (`Meta_Man.mp3`, `Quantum_Cascade.mp3`); `strength`/`confidence` in `[0,1]`; degenerate inputs (empty envelope, silent/too-short file) return `nil`; and the default-path byte-identity assertion (AC4).

**FRs covered:** FR-27, FR-30 (partial — full playback alignment lands in Story 8.5).
**KDDs implemented:** C1, C2, C6 (C3 deferred to 8.5).

---

## Tasks / Subtasks

- [x] **Task 1 — Implement the DP beat-tracker in `BeatGridAnalyzer`** (AC: 1, 2, 5)
  - [x] Replace the placeholder `enum BeatGridAnalyzer` body; keep it `internal`, keep `import Foundation`, add `import Accelerate`.
  - [x] Add `static func estimateBeatGrid(onsetEnvelope:onsetRate:hopSize:sampleRate:acf:tempoBPM:windowStartSample:) -> BeatGrid?` with the corrected signature (DD #1).
  - [x] Derive the beat period in onset-frames from `tempoBPM` + `onsetRate` (period = `onsetRate * 60 / tempoBPM`); build the Rayleigh weighting over the period-transition neighborhood (Davies & Plumbley); accumulate the causal DP score over `onsetEnvelope`; backtrace to recover beat frames. **Study the technique, do not transcribe aubio.**
  - [x] Map each beat frame → `BeatTimestamp` with `presentationTime` (track-relative, DD #6), `strength` (KDD-C2 via `vDSP_maxv`, DD #5), and a per-beat `confidence` from the local DP score.
  - [x] **Preserve** `onsetFeatures(for:weighting:)` so `FeatureSubstrateTests` stays green (DD #8). Add the aubio/Davies-Plumbley reference doc comments (AC2).
  - [x] Return `nil` for empty envelope / non-positive period / degenerate input.

- [x] **Task 2 — Insert as step 11 in `BPMAnalyzer.estimateBPM`** (AC: 3, 4, 5)
  - [x] Add `var computeBeatGrid: Bool = false` to `BPMAnalyzer.Options` (and thread it from `AudioAnalysisService.Options` — add the matching field there too).
  - [x] After step 10c (`BPMAnalyzer.swift:449`), before confidence, add the gated fan-out: `if techniqueSet/options gate → let grid = BeatGridAnalyzer.estimateBeatGrid(onsetEnvelope:..., acf: acf, tempoBPM: bpm, windowStartSample: dropOffset, ...)`. Reuse in-scope `onsetEnvelope`, `acf`, `onsetRate`, `hopSize`, `sampleRate`, `dropOffset` (all still alive pre-`defer`).
  - [x] Renumber the inline `// Step 11: Confidence` → `// Step 12: Confidence` (DD #2). Add a `// Step 11: Beat-grid extraction (optional fan-out)` comment.
  - [x] Add `let beatGrid: BeatGrid?` to `BPMResult` (default `nil` on the non-fan-out path). Carry it out of `estimateBPM`.
  - [x] Confirm the default path (`computeBeatGrid == false`) never enters the branch — byte-identity (AC4).
  - [x] Run the 5 `bpm-diagnostic-trace` audit recipes (A–E); confirm zero matches (no trace field added).

- [x] **Task 3 — Public `analyzeBeatGrid` service methods** (AC: 6, 7)
  - [x] Add `public static func analyzeBeatGrid(url:options:) throws -> BeatGrid?` and `public static func analyzeBeatGrid(decoded:options:) throws -> BeatGrid?` to `AudioAnalysisService`, reusing `AudioAnalysisService.Options` (it already carries `intensity`/`techniqueSet`/`maxSeconds`/`isCancelled`).
  - [x] Internally: decode via the existing `decodeOnce` funnel (url path) or accept the shared `DecodedAudio` (decoded path); call `BPMAnalyzer.estimateBPM(decoded:options:)` with `options.computeBeatGrid = true` on a single representative window; return `result?.beatGrid`. (Single-window scope avoids producing a grid per multi-window pass — DD #2 note.)
  - [x] Thread `isCancelled` checkpoints to match `analyzeLUFS` (pre-decode + post-decode). No `onProgress` needed (single pass).
  - [x] Always emit `tempoAgreedWithBPMStage: nil` from the public method (DD #10).
  - [x] DocC `///` on both methods.

- [x] **Task 4 — README + docs** (AC: 7)
  - [x] Update `README.md` "## Beat grid" section: replace the "lands in a later release" sentence with live `analyzeBeatGrid(url:options:)` usage; note window-scoped / track-relative timestamps and that full playback alignment + BPM-agreement land in 8.5.
  - [x] Add a Public API table row for `analyzeBeatGrid`.

- [x] **Task 5 — Tests** (AC: 6, 8, 9)
  - [x] `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` per AC9 (synthetic click tracks + real-fixture ±5-BPM agreement + edge cases + byte-identity).
  - [x] Add the ≤25%-overhead shared-decode gate to the benchmark target, mirroring `SharedDecodeImpactGateTests` (release config, env-gated, alternating order, per-file medians, multiplicative + absolute-epsilon noise margin). Default-path ≤2% is reported via the existing perf baseline (AC8).
  - [x] `make test` green; `make fmt` idempotent; `make lint` clean (only the pre-existing `LUFSAnalyzer:135` TODO baseline).

- [x] **Task 6 — PR description** (AC: 3, 7)
  - [x] Enumerate the new public surface; state "no `BPMDiagnosticTrace` field added in 8.4 — KDD-T0 does not trigger (beat grid is a parallel step-11 output, not a pool participant); **W74 re-evaluation hook remains armed** for whenever a beat-grid producer enters the `UnifiedSignalPool`."

---

## Dev Notes

### Design Decisions (DDs)

**DD #1 — corrected `estimateBeatGrid` signature.** Takes the **1-D onset envelope** (`[Float]` at `onsetRate` Hz) + scalars + the **`acf: [Float]` result** + `tempoBPM` + `windowStartSample`. NOT `OnsetFeatures` (a 2-D mel matrix — wrong shape) and NOT `ACFBuffers` (a `private` FFT scratch struct, `defer`-deallocated, that cannot leave `estimateBPM`'s scope). Verified: `OnsetFeatures.swift:38-40`, `BPMAnalyzer.swift:241,289,969,285-286`.

**DD #2 — step-11 fan-out lives INSIDE `estimateBPM`; output carried on a new `BPMResult.beatGrid: BeatGrid?`.** This is the only model that satisfies "reuses ACFBuffers/`onsetEnvelope` from the caller, no new hot-path allocation" (the buffers, `onsetEnvelope`, and `acf` are only alive there, before the `defer`s at `BPMAnalyzer.swift:286,314`). Gated by `options.computeBeatGrid` (default `false`) → default path is byte-identical (AC4). The inline `// Step 11: Confidence` label (`BPMAnalyzer.swift:454`) is **not** in CLAUDE.md's canonical 1→10c step roster, so renumbering it to step 12 corrects a latent collision rather than breaking a public identifier — but it is still a real edit reviewers will see, hence called out explicitly.

**DD #3 — NO trace field in 8.4; KDD-T0 does not trigger; W74 stays armed.** Supersedes `epics.md:1021`'s `BeatGridTraceEntry`. KDD-T0 (`architecture.md:703-744`) requires the field to affect winner selection / weight resolution / gate firing AND be collision-prone — beat grid is a parallel step-11 output that does not feed BPM disambiguation. Story 8.3 (DD #6/AC8) locked this and recorded **W74**: re-run KDD-T0 only when a beat-grid *producer* is wired into the `UnifiedSignalPool` (via the producerless `SignalSource.beatGrid`, W53), at which point `estimatedTempo`/`confidence` become weight-resolution inputs and a `signalParticipationTrace`/`.beatGrid` field is warranted. 8.4 keeps beat grid a standalone sibling — not a pool participant — so the trigger is still unmet. The 5-recipe audit trivially passes (no field added). **Surfaced as Open Question #1.**

**DD #4 — public API mirrors `analyzeLUFS`.** Two overloads (`url:options:` + `decoded:options:`) + the internal `decodeObserver`-threaded seam, exactly as `analyzeLUFS` does (`AudioAnalysisService.swift:1188,1241`). Reuse `AudioAnalysisService.Options` (no new options type) — it already carries `intensity`, `techniqueSet`, `maxSeconds`, `isCancelled`. The `decoded:` overload is the shared-decode entry (KDD-C4) the ≤25% gate exercises.

**DD #5 — `BeatTimestamp.strength` per KDD-C2 (Amelia provenance).** `strength = onsetEnvelope[frame] / onsetEnvelopeMax`, `onsetEnvelopeMax` via a single `vDSP_maxv` over the in-scope envelope; `frame = round(presentationTime * sampleRate / hopSize)` with bounds guard. `BeatTimestamp.init` already clamps `strength`/`confidence` to `[0,1]` and NaN→0 — no double-clamp needed, but guard the divide against a zero/empty-envelope max (→ all-zero strengths, not NaN).

**DD #6 — track-relative `presentationTime`; full alignment deferred to 8.5.** `estimateBPM` analyzes a window starting at the step-1 energy-scan `dropOffset` (`BPMAnalyzer.swift:199-203`). Beats are therefore offset by `windowStartSample = dropOffset`: `presentationTime = (Double(dropOffset) + Double(frame) * Double(hopSize)) / sampleRate`. This makes 8.4 beats track-relative (not window-relative). Codec-priming trim (AAC/MP3 leading frames via `PrimingInfo`) and long-file drift tolerance are explicitly **Story 8.5** (FR-29/FR-30 full).

**DD #7 — aubio GPL-3.0 fence (KDD-C1).** Study only. No transcription, no linkage. `///` cites `aubio/src/tempo/beattracking.c` as inspiration + Davies & Plumbley ISMIR 2004 / AES 118 2005. Imports `Foundation` + `Accelerate` only. `Package.swift` unchanged (verified: zero external deps).

**DD #8 — `BeatGridAnalyzer` stays internal (KDD-C6) and RETAINS `onsetFeatures(for:weighting:)`.** No public engine protocol until a second concrete impl lands (mirrors `MLTechnique`-after-`BNNS`). The existing stub member `onsetFeatures(for:weighting:)` is consumed by `FeatureSubstrateTests.swift:61` for the Story-8.2 KDD-C4 cross-consumer bit-equality invariant — **preserve it** (it is also the shared-feature producer the analyzer can reuse), or migrate that test in the same PR. Do not silently drop it.

**DD #9 — `downbeats == .notAttempted` in 8.4.** The DP tracks *beats*, not bars. The 8.4 ACs require only `beats.count > 0`; downbeat (bar-start) *detection* is not in any 8.4 AC. Emitting `.notAttempted` is the honest tri-state value (FR-28's whole point: "we never ran downbeat detection" ≠ "ran and found none"). Downbeat detection is a later concern. **Surfaced as Open Question #2.**

**DD #10 — `tempoAgreedWithBPMStage == nil` in 8.4.** The standalone `analyzeBeatGrid` runs no BPM stage in the same call, so the field is `nil` by definition (KDD-C3). Setting `true`/`false` requires an orchestrated both-stages call — that is **Story 8.5** (the consistency contract). Do not populate it here.

**DD #11 — perf gates.** ≤2% default-path regression is a consequence of AC4 byte-identity (reported via the existing `PerformanceBenchmarkTests` baseline, not a flake-prone hard gate). The ≤25% beat-grid-overhead gate mirrors `SharedDecodeImpactGateTests` (`Tests/BoomBoomBoomKitBenchmarkTests/SharedDecodeImpactTests.swift`): release config, env-gated, warmups, alternating measurement order per rep, per-file paired medians then format-level median, multiplicative (`×1.10`) + absolute-epsilon (`0.020s`) noise margin.

**DD #12 — README already has the stub.** `README.md:198-216` carries the forward-pointing "## Beat grid" section from Story 8.3. 8.4 updates the "lands in a later release" sentence to live usage + adds the Public API row — it does not create the section from scratch.

### Architecture / source-tree touch points

| File | Change | Notes |
|---|---|---|
| `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` | REWRITE | placeholder enum → real internal analyzer (DP); keep `internal`, keep `onsetFeatures` member |
| `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` | UPDATE | step-11 fan-out after 10c (`:449`), `// Step 11→12` confidence label (`:454`), `BPMResult.beatGrid` field (`:12-21`), `Options.computeBeatGrid` |
| `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` | UPDATE | public `analyzeBeatGrid(url:)` + `(decoded:)`; `Options.computeBeatGrid`; reuse `decodeOnce` |
| `README.md` | UPDATE | "## Beat grid" live usage + Public API row |
| `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` | NEW | AC9 unit coverage |
| `Tests/BoomBoomBoomKitBenchmarkTests/` | NEW/UPDATE | ≤25% overhead gate (mirror `SharedDecodeImpactGateTests`) |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | UPDATE | 8-4 → ready-for-dev (this workflow) |

**Hot-path / vDSP discipline (CLAUDE.md):** all bulk numeric ops via Accelerate; no manual `[Float]` loops for the DP accumulation where a vDSP primitive exists; `[Float]` is already contiguous (no `ContiguousArray`); `reserveCapacity` on the beats array (count ≈ `windowDuration * tempoBPM / 60`).

### Pressure-release valve (from epic)

If the DP fails to land in a single dev-agent context window, split into **8.4a** (Rayleigh-weighted period-transition matrix + score accumulation) and **8.4b** (DP backtrace + `BeatGrid` population + public method). Document in `_bmad-output/implementation-artifacts/8-4-pressure-release.md`.

### Testing standards

Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`, `#require`) — never XCTest. Fixtures resolve via `AudioFixtures.url(for:extension:)` from `BoomBoomBoomKitTestSupport`; synthetic click tracks via `TestSignalGenerators.generateClickTrack(bpm:sampleRate:durationSeconds:)`. ±5-BPM agreement uses `AccuracyMatchers.isAcc1Match(_:_:tolerance:)` (2% tolerance) where MIREX-style matching is wanted. Benchmark target is env-gated (`OA300_CORPUS_PATH`); perf gate runs `-c release`.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 8.4 (lines 1003-1041)] — epic ACs (superseded where Context corrections note).
- [Source: _bmad-output/planning-artifacts/architecture.md#Epic C (KDD-C1 490-494, KDD-C2 496-522, KDD-C3 524-526, KDD-C6 545-547)] — algorithm, strength provenance, consistency, internal-analyzer decisions.
- [Source: _bmad-output/planning-artifacts/architecture.md#KDD-T0 (703-744)] — trace-field two-criteria gate (why no field in 8.4).
- [Source: _bmad-output/implementation-artifacts/8-3-beatgrid-and-tri-state-downbeatresult-public-types.md (DD #6, AC8, lines 24-27,160)] — W74 re-evaluation hook; KDD-T0 non-trigger precedent.
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift:186-463] — `estimateBPM` flow; step 10c (`:436-449`); `onsetEnvelope` (`:241`); `acf` (`:289`); `ACFBuffers` (`:969`); `PipelineBuffers` (`:1261`); `hopSize/onsetRate` (`:218-219`); `dropOffset` window (`:199-203`); `// Step 11: Confidence` (`:454`).
- [Source: Sources/BoomBoomBoomKit/FeatureSubstrate/OnsetFeatures.swift:38-40] — proof `OnsetFeatures` is a 2-D mel matrix, not the 1-D envelope.
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:1188-1255] — `analyzeLUFS` two-overload + `decodeObserver` seam to mirror; `decodeOnce` funnel (`:1045-1056`).
- [Source: Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift] — placeholder to rewrite; `onsetFeatures` member.
- [Source: Tests/BoomBoomBoomKitTests/FeatureSubstrateTests.swift:50-61] — KDD-C4 cross-consumer invariant depending on `BeatGridAnalyzer.onsetFeatures` (DD #8).
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/SharedDecodeImpactTests.swift] — ≤25% gate scaffold to mirror.
- [Source: README.md:198-216,345] — "## Beat grid" stub + Public API table to update.
- [Source: .claude/skills/bpm-diagnostic-trace/SKILL.md:162-235] — 5 audit recipes A–E (zero matches required).

### Open Questions (for the operator — do not block dev on these; the DDs above are the working resolution)

1. **Trace field (DD #3):** the epic AC literally asks for `BeatGridTraceEntry`, but KDD-T0 + Story 8.3's W74 say no field until a beat-grid producer enters the pool. The spec resolves this as **no trace field in 8.4**. Confirm this is the intended reading (it is the skeptical, rule-consistent one).
2. **Downbeats (DD #9):** 8.4 emits `.notAttempted` (beats-only DP). Confirm downbeat *detection* is intentionally a later story and not silently expected in 8.4.

---

## Dev Agent Record

### Agent Model Used

Opus 4.8 (claude-opus-4-8[1m]).

### Debug Log References

- Build: `swift build` + `swift build --build-tests` — clean (the `.serialized`-on-non-parameterized-test warning in `AblationFullMatrixTests.swift:418` is pre-existing, unrelated).
- Unit suite: `make test` → **588 tests / 125 suites passed** (was 578/124 at story start; +10 tests in the new `BeatGridAnalyzerTests` suite).
- New analyzer suite: `swift test --filter BeatGridAnalyzerTests` → 10 tests green (click recovery 4 cases, real-fixture agreement 2 cases, deterministic DP, track-relative time, 4 degenerate-input nils, default-path byte-identity).
- Trace audit (AC3): all 5 `bpm-diagnostic-trace` recipes A–E return zero matches; no `beatGrid` reference in `BPMDiagnosticTrace.swift`. KDD-T0 does not trigger.
- Perf gate (AC8): `make beat-grid-impact-report` (release, OA300) → step-11 overhead mp3 **+0.2%**, flac **+6.2%**, wav-class **−0.6%**; all under the ≤25% gate. JSON: `_bmad-output/implementation-artifacts/8-4-beat-grid-impact.json`.
- `make fmt` idempotent; `swiftlint lint .` → 1 violation (the pre-existing `LUFSAnalyzer.swift:135` TODO baseline). The 7-param `estimateBeatGrid` (AC1-mandated signature, all required args) carries `// swiftlint:disable:this function_parameter_count`, mirroring the existing `quadraticPeakBPM` precedent (`BPMAnalyzer.swift:1691`).

### Completion Notes List

- **Algorithm (AC1/AC2, KDD-C1):** implemented the Davies & Plumbley causal DP beat-tracker in the fixed-period (Ellis 2007) form — the tempo is already resolved by the BPM stage, so the original's Rayleigh tempo-induction prior is subsumed by `tempoBPM` and what remains is the log-Gaussian period-transition ("tightness") DP that fixes beat phase. Documented honestly in the type doc comment (no invented claim of a Rayleigh prior that isn't there). aubio `src/tempo/beattracking.c` cited as inspiration only; no transcription, no linkage; imports `Foundation` + `Accelerate` only; `Package.swift` unchanged (zero external deps).
- **Signature correction (DD #1):** shipped `estimateBeatGrid(onsetEnvelope:onsetRate:hopSize:sampleRate:acf:tempoBPM:windowStartSample:)` — 1-D envelope + `acf:[Float]` result + tempo, NOT the epic's `OnsetFeatures`/`ACFBuffers`. The `acf` argument is given a real role (`acfStrengthAtPeriod` → half of overall grid confidence) rather than left vestigial.
- **Step-11 fan-out (DD #2, AC3/AC4/AC5):** lives inside `estimateBPM` after step 10c, gated by `BPMAnalyzer.Options.computeBeatGrid` (default `false`); reuses the in-scope `onsetEnvelope`/`acf`/`onsetRate`/`hopSize`/`sampleRate`/`dropOffset` before the buffer `defer`s fire — no new hot-path allocation. Output carried on a new `BPMResult.beatGrid: BeatGrid?` (explicit defaulted-`beatGrid` init so the ~40 existing 4-arg call sites are untouched; `BPMResult.with()` forwards it per the W52 no-silent-drop rule). Inline `// Step 11: Confidence` renumbered to `// Step 12: Confidence`. Default-path byte-identity proven by `defaultPathLeavesBPMResultByteIdentical` (computeBeatGrid true vs false → identical bpm/confidence/candidates, grid nil on the default path).
- **No public `Options.computeBeatGrid` (deviation from Task 2's "thread it"):** deliberately NOT added to `AudioAnalysisService.Options`. `analyzeBPM` returns `AudioAnalysisResult`, which has no beat-grid channel, so a public flag there would compute a grid that is silently dropped — dead public surface. `analyzeBeatGrid` sets the internal `BPMAnalyzer.Options.computeBeatGrid = true` itself; the method's existence is the request. Minimal-surface, no dead config (pre-1.0, break freely).
- **Public API (DD #4, AC6/AC7):** `analyzeBeatGrid(url:options:)` + `analyzeBeatGrid(decoded:options:)` mirror `analyzeLUFS` — two overloads + the internal `decodeObserver`-threaded url seam + the shared `decodeOnce` funnel; cancellation checkpoints before/after decode. Runs a single representative window (direct `estimateBPM`, not the multi-window pool) since beat grid is a parallel output, not a pool participant.
- **Scope honesty (DD #9/DD #10):** `downbeats == .notAttempted` and `tempoAgreedWithBPMStage == nil` are set by the analyzer itself — beats-only DP; downbeat detection and the BPM/beat-grid consistency contract are Story 8.5. README says so plainly.
- **Open Questions resolved in-spec, surfaced for the operator:** (1) no `BPMDiagnosticTrace` field in 8.4 — KDD-T0 does not trigger (parallel step-11 output), W74 stays armed for a future beat-grid pool producer; (2) downbeat detection intentionally deferred to 8.5.

### PR description (Task 6)

New public surface: `AudioAnalysisService.analyzeBeatGrid(url:options:)` and `analyzeBeatGrid(decoded:options:)` → `BeatGrid?`. New internal: `BeatGridAnalyzer.estimateBeatGrid(...)` (Davies & Plumbley DP, step 11), `BPMAnalyzer.Options.computeBeatGrid`, `BPMResult.beatGrid`. README "## Beat grid" updated to live usage + Public API rows. Perf: step-11 overhead ≤6.2% across formats (gate ≤25%). **No `BPMDiagnosticTrace` field added in 8.4 — KDD-T0 does not trigger (beat grid is a parallel step-11 output, not a pool participant); the W74 re-evaluation hook remains armed for whenever a beat-grid producer is wired into the `UnifiedSignalPool`.** Default `analyzeBPM` output is byte-identical (test-locked).

### File List

- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift` — REWRITE: placeholder enum → internal Davies & Plumbley DP beat-tracker; `onsetFeatures` seam member retained (DD #8).
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — UPDATE: `BPMResult.beatGrid` field + explicit init; `Options.computeBeatGrid`; step-11 fan-out after 10c; `// Step 11→12: Confidence` label.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — UPDATE: public `analyzeBeatGrid(url:)` + `(decoded:)` + internal observer overload + private `beatGrid` core; `BPMResult.with()` forwards `beatGrid`.
- `README.md` — UPDATE: "## Beat grid" live `analyzeBeatGrid` usage; Public API rows (`AudioAnalysisService`, `BeatGrid`).
- `Makefile` — UPDATE: new `beat-grid-impact-report` target (mirrors `shared-decode-impact-report`).
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift` — NEW: AC9 unit coverage (10 tests).
- `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridImpactTests.swift` — NEW: AC8 ≤25% overhead gate (env-gated, release).
- `_bmad-output/implementation-artifacts/8-4-beat-grid-impact.json` — NEW (develop-only): perf gate report.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — UPDATE: 8-4 → review.

## Change Log

- 2026-06-13 — Story created (ready-for-dev). Authored against verified codebase state; three epic-AC factual errors corrected up front (signature `OnsetFeatures`/`ACFBuffers` → 1-D envelope + `acf:[Float]`; `BeatGridTraceEntry` → no trace field per KDD-T0/W74; non-existent Story-6.2 seam → docs-only mitigation). Scoped to beats-only DP (downbeats `.notAttempted`, `tempoAgreedWithBPMStage` nil — both 8.5 concerns). Step-11 fan-out inside `estimateBPM` gated by `computeBeatGrid` (default off → byte-identical). Two open questions surfaced for operator confirmation.
- 2026-06-13 — Implemented (→ review). Davies & Plumbley fixed-period DP beat-tracker in `BeatGridAnalyzer` (Ellis 2007 form; Rayleigh tempo-prior subsumed by the supplied tempo — documented honestly); step-11 fan-out + `BPMResult.beatGrid` + `Options.computeBeatGrid` (default off, byte-identical default path); public `analyzeBeatGrid(url:)/(decoded:)` mirroring `analyzeLUFS`; README + Public API rows; `beat-grid-impact-report` Makefile target. Gates: `make test` 588/125 green (+10); fmt idempotent; lint at the 1 pre-existing baseline violation; 5-recipe trace audit zero matches (no trace field — KDD-T0 non-trigger, W74 armed); AC8 step-11 overhead ≤6.2% (gate ≤25%, release/OA300). Deviation logged: did NOT add a public `Options.computeBeatGrid` (no result channel on `analyzeBPM` → dead surface); `analyzeBeatGrid` sets the internal flag itself.

## Review Findings

### Code review (2026-06-13) — Blind Hunter (Codex), Edge Case Hunter, Acceptance Auditor

- [x] [Review][Patch] Snap grid `estimatedTempo` to the BPM-stage octave (C2) [Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift] — The DP accepts inter-beat intervals in `[0.5·period, 2·period]`, so the median-interval `estimatedTempo` can land at the half/double octave of `tempoBPM`. (sources: blind+auditor; **Codex-consulted 2026-06-13, operator decision: option C2**) **Resolved:** added `internal static nearestOctaveEquivalent(of:to:)`; `estimateBeatGrid` now sets `estimatedTempo = nearestOctaveEquivalent(of: medianTempo, to: tempoBPM)` — detected `beats` unchanged, the reported scalar octave-locked to the BPM stage while preserving in-octave drift. `tempoAgreedWithBPMStage` stays `nil` (Story 8.5 / KDD-C3). **Test approach (Codex round-2 → Option 3 additive, not literal-±5-everywhere):** the `{0.5,1,2}` snap cannot pull a non-octave median within 5 BPM and the DP won't produce an octave-split median from a clean periodic input at `tightness=100`, so an end-to-end non-identity snap test would be brittle. Instead: new deterministic helper unit test `nearestOctaveEquivalentSnapsToReferenceOctave` proves the snap math; `recoversClickTrackTempo` + `agreesWithAnalyzeBPM` stay octave-tolerant with comments stating the responsibility split (octave-vs-ground-truth is the BPM stage's job, covered by corpus benchmarks).
- [x] [Review][Patch] Unbounded `period` → `Int(...)` conversion trap + oversized DP allocation [Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift] — A tiny-but-finite positive `tempoBPM` makes `period` finite yet `> Int.max`, so `Int((period * 2.0).rounded())` traps; an intermediate large-but-finite `period` drives a multi-GB `txCost` allocation. (sources: blind+edge) **Resolved:** guard is now `guard period >= 1, period.isFinite, period <= Double(n) else { return nil }`; stale "no room for a transition" / "too short to contain a beat transition" comments reworded to "shorter than one beat period." Direct regression test `absurdlySmallTempoReturnsNil` (tempoBPM `1e-17` → nil, no trap).
- [x] [Review][Patch] Byte-identity test uses `==` instead of `Double.bitPattern` [Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift `defaultPathLeavesBPMResultByteIdentical`] — (source: auditor) **Resolved:** `bpm`/`confidence`/`candidates[i].bpm`/`candidates[i].score` now compared via `.bitPattern` per the project "byte-equality opt-out" convention.

**Resolution (2026-06-13):** all 3 patches applied + plan Codex-reviewed (thread 019ec26d, 2 rounds). Gates: `make fmt` idempotent; `swiftlint` at the single pre-existing `LUFSAnalyzer.swift:135` TODO baseline; `swift test --filter BeatGridAnalyzerTests` 12/12 green; `make test` **590/125** green (588 + 2 new tests). The `doubled()`/`halved()` octave-guidance idea is deferred (`deferred-work.md` 8-4-D1).

Dismissed as noise (6): DP end-state argmax could pick a silent-tail beat — mitigated by `alpha = 0.8 < 1` decay through silence, and is the canonical Ellis-2007 global-max backtrace; per-beat `confidence = exp(-r²)` omits the DP `tightness` factor — defensible soft-salience design (applying `tightness = 100` would collapse confidence to ~binary); single-beat grid returned — spec permits `beats.count > 0`; `strengthSum / beats.count` divergence — the `f >= 0, f < n` guard never fires (backtrace indices are provably in `0..<n`) and both accumulate post-guard, staying in sync; `onsetRate`/`hopSize`/`sampleRate` mutual-consistency not validated — internal function, caller-derived from one source; DD #11 perf-gate folds the 25% AC + noise into one `1.25` constant — develop-only env-gated harness, gate is functional and non-vacuous.
