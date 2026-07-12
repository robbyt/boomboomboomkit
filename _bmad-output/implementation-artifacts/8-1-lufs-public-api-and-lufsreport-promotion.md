---
baseline_commit: ae04011
---

# Story 8.1: LUFS public API — `analyzeLUFS(url:options:)` + `LUFSReport`

Status: done

## Spec validation history

- **2026-06-10 — factual-claims grep (mandatory pre-spec).** Four epic-AC errors found against the live codebase: (1) `analyzeLUFS` ALREADY EXISTS (`AudioAnalysisService.swift:1001`, `(url:maxSeconds:) throws -> Double?`) — this story is a reshape, not greenfield; (2) audio fixtures live at `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/`, not `Tests/BoomBoomBoomKitTests/Fixtures/`, and NO `.caf` fixture exists; (3) the seam-mitigation surfaces the epic cites (`analyzeShared` helpers, `BPMDiagnosticTrace.decodedAudio`) do not exist — that AC reduces to DocC + README; (4) `PCMBufferReaderError.unsupportedSampleRate` does not exist, and per panel review it is the WRONG error domain anyway (DD #8). epics.md Story 8.1 section is patched with these corrections in this story's PR.
- **2026-06-10 — operator design direction.** Operator reviewed chmaha/ebu-norm-tools charts: "LUFS as a single number doesn't really make sense" (quiet intro / loud middle); wants momentary loudest/quietest + LUFS-over-time charts. The epic's "exactly three fields" `LUFSReport` is amended to a chart-ready shape (DD #2).
- **2026-06-10 — schema proven by rendering.** `Demo/BoomBoomBoomBPM/LUFSChartSchemaProbe.swift` (untracked scratch, DO NOT COMMIT) renders the proposed schema through Swift Charts via Xcode MCP RenderPreview — ebu-plot-style chart in ~15 lines. Learned: vectorized `LinePlot(x:y:series:)` blows up the preview type-checker; classic `ForEach` + `LineMark` + `foregroundStyle(by:)` compiles instantly. P10/P95 band edges must be stored fields (chart needs edges, not just the range width).
- **2026-06-10 — Codex consult (thread 019eaffb), normative cadences.** Momentary 400ms / short-term 3s, both ≥10 Hz update (EBU Tech 3341 §2.2) → shared 100ms grid. LRA: 3s short-term distribution, abs gate −70 LUFS, rel gate −20 LU below abs-gated mean, P95−P10 (EBU Tech 3342 §3.1); unreliable < ~1 min (EBU R 128). True-peak: oversample 4× @ 48k / 2× @ 96k (BS.1770-5 Annex 2); NO normative true-peak time series — single max only. TP series deferred accordingly.
- **2026-06-10 — party-mode panel (Winston/Amelia/John, real subagents).** HEADLINE (Winston + Amelia independently): short-term from 30 overlapping 400ms blocks = 3.3s triangular window, NOT the Tech 3341 3.0s rectangle → 100ms mean-square cell primitive (DD #4). Winston: wrong error domain on the reader enum (DD #8); drop `Hashable` (DD #2); chunked oversampling, no 4N buffer (DD #6); mono-TP document-and-defer with teeth (DD #7). Amelia: nil-vs-throw contract must be pinned (DD #8); two-tier byte-identity tests (DD #11); polyphase pitfalls (Dev Notes); cancellation gap (DD #10). John: patch epics.md in same PR; demo chart = existing Story 10-4 pulled forward (DD #14); maxSeconds 30s→full-file is a correctness fix, not a default change (DD #9).

## Story

As a library consumer,
I want `AudioAnalysisService.analyzeLUFS(url:options:) -> LUFSReport?` returning ITU-R BS.1770-5 integrated loudness, max true-peak, EBU Tech 3342 loudness range, AND chart-ready momentary/short-term loudness time series on the standards-aligned 100ms grid,
so that I can both normalize against the integrated number and visualize a track's loudness shape (quiet intro / loud middle) in Swift Charts from a single call — without touching the internal `LUFSAnalyzer`.

## Key Design Decisions

1. **Reshape, not greenfield.** `analyzeLUFS(url:maxSeconds:) throws -> Double?` exists at `AudioAnalysisService.swift:1001` and discards the block time-series the analyzer already computes. New signature: `analyzeLUFS(url:options:) throws -> LUFSReport?`. Pre-1.0 break, no BC owed. The 3 existing tests (`AudioAnalysisServiceTests.swift:105-137`) migrate.
2. **`LUFSReport` is `public struct, Sendable, Equatable, CustomStringConvertible` — NOT `Hashable`** (epic AC amended; `EnsembleDecision` "value carrier, never a Set key" precedent; multi-thousand-element `[Double]` fields make hashing pointless anyway). Stored: `integratedLUFS`, `maxTruePeakDBTP`, `loudnessRangeLU: Double?` (nil < 60s of gated program), `lraLowLUFS`/`lraHighLUFS` (P10/P95 — chart band edges), `momentaryLUFS: [Double]`, `shortTermLUFS: [Double]`, `stepSeconds: Double` (0.1). Computed: `maxMomentaryLUFS`/`minMomentaryLUFS`/`maxShortTermLUFS` (nil on empty series), `samples: [LoudnessSample]`. Init clamps NaN/±Inf in every stored field to the documented `-100.0` sentinel floor (existing `blockLoudnessFloor` precedent); sentinel documented in DocC.
3. **`LoudnessSample` adapter is Foundation-only.** `public struct LoudnessSample: Sendable, Identifiable, Hashable` (`time: Double`, `lufs: Double`, `series: LoudnessSeries`); `LoudnessSeries: String, Sendable, Hashable, CaseIterable` (`.momentary`, `.shortTerm`). NO `import Charts`/`SwiftUI` anywhere in `Sources/BoomBoomBoomKit` — consumers plot via `series.rawValue` (probe-proven; no `Plottable` conformance needed in the library). `samples` is O(n) computed — DocC warns against per-frame access.
4. **100ms mean-square cell primitive (the panel's headline catch).** New internal pass: one `vDSP_measqvD` sweep per 100ms cell over the already-K-weighted Double signal. Short-term = mean of 30 consecutive cells (EXACT 3.0s rectangle, energy domain, `10·log10` last). The existing per-400ms-block `vDSP_measqvD` path is UNTOUCHED — do NOT derive 400ms blocks from cells (fp reduction order differs → byte-identity dead). Cells are additive, feeding short-term + LRA only. Never average dB values; all windowing/gating in mean-square domain.
5. **LRA per EBU Tech 3342 §3.1**, computed over the short-term distribution: absolute gate −70 LUFS, relative gate −20 LU below the absolute-gated mean (note: differs from integrated gating's −10), `LRA = P95 − P10`. `loudnessRangeLU = nil` (and band edges = sentinel) when gated program < 60s (EBU R 128 reliability floor) or the gated set is empty.
6. **True-peak per BS.1770-5 Annex 2, polyphase.** Use the ITU-published 48-tap prototype as 4 phases × 12 taps (gain pre-compensated), `vDSP_conv` per phase over the original-rate signal, chunked with running max — never materialize a 4N buffer. 4× @ 44.1/48 kHz, 2× @ 96 kHz (separate filter design, separate test). Float is fine (Double mandate is K-weighting-only). Fold `vDSP_maxmgv` of the raw signal into the max. Document: 4× @ 44.1k = 176.4 kHz, under the literal "≥192 kHz" wording — standard practice, named deviation. Stays in 8.1 (FR-26 names it); valve in AC #11 if it resists.
7. **Mono-mixdown true-peak: document-and-defer with teeth.** Pipeline currency is mono `[Float]`; BS.1770 true-peak is max over channels pre-mixdown, so ours UNDERSTATES — the dangerous direction for ceiling compliance. DocC on `maxTruePeakDBTP` must state: "computed post-mono-mixdown; may understate per-channel inter-sample peaks; not suitable for delivery-compliance certification." `deferred-work.md` entry targeting Story 8.2's per-channel `DecodedAudio` seam. (Integrated has the same pre-existing mono limitation; note it once.)
8. **Error domain: new `LUFSAnalysisError`, NOT `PCMBufferReaderError`** (epic AC corrected — the reader CAN read 22.05 kHz; the K-weighting coefficient table is what can't proceed). `public enum LUFSAnalysisError: Error, Sendable { case unsupportedSampleRate(sampleRate: Double, supported: [Double]) }`. New-error-type rule satisfied: this DD is the explicit design decision. **Pinned nil-vs-throw contract:** throw = environmental/configuration failure (`PCMBufferReaderError` for unreadable file; `LUFSAnalysisError` for unsupported rate); `nil` = measured-but-no-result (all-silence after gating, input < 400ms). Documented on the method and test-locked.
9. **`LUFSOptions` (ADR-11 options-first):** `public struct LUFSOptions: Sendable { public var maxSeconds: Double?; public init() {} }` with `maxSeconds` default **nil = full file** (was 30s). Correctness fix: integrated loudness is whole-program by definition; a 30s default returns a standard-nonconformant number under a standard-conformant name, and LRA would be nil-by-default forever. Behavior change named in README + epics.md patch. Bounded-cost escape hatch: pass `maxSeconds` explicitly. Does NOT touch BPM paths.
10. **No cancellation in 8.1** — `analyzeLUFS` runs to completion; documented in DocC. Plumbing lands with Story 8.2's shared-decode orchestration (`deferred-work.md` entry). Decode dominates wall-clock; DSP passes are O(n) vDSP.
11. **Two-tier regression tests:** (tier 1, the DSP lock) `LUFSAnalyzer`-level `bitPattern` equality on runtime-synthesized input — capture the baseline literals by running the CURRENT develop build BEFORE any analyzer edit (the old API won't exist after; the literals ARE the contract). (tier 2) fixture-level tolerance tests — lossy-codec decode output (MP3/AAC) is not byte-stable across macOS versions; never bitPattern-assert on it. Existing-fixture integrated values must also be pinned with `maxSeconds: 30` explicitly (the default changed; >30s fixtures would silently move).
12. **Reference signals are runtime-synthesized** (existing `LUFSAnalyzerTests.generateSineWave` RMS-calibrated precedent) — deviation from the epic's "committed to the test fixtures" wording, documented here: deterministic generators, zero binary bloat. Tolerances: integrated ±0.1 LU @ 48k/96k; at 44.1k MEASURE first — if the bilinear-derived coefficients miss ±0.1, do NOT touch coefficients (frozen by byte-identity); record a per-rate tolerance with the measured delta cited in Completion Notes. True-peak ±0.3 dB (4× oversampling worst-case under-read ~0.5–0.6 dB is documented in BS.1770 commentary; use an inter-sample-peak sine oracle). LRA ±0.5 LU (synthesized two-level ~70s signal). Keep the matrix at 997 Hz (no >10 kHz tones — 44.1k bilinear droop becomes real there).
13. **CAF fixture generated** via `afconvert` from `sample.wav` into `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` to complete the epic's WAV/AIFF/MP3/FLAC/M4A/CAF matrix.
14. **Demo chart follow-up = existing Story 10-4 (`LUFSReadoutView`), pulled forward.** Its real dependency is 8.1 only (not Epic 11; FR-42 degradation already allows it). The probe file is its seed. Noted in epics.md patch. This story ships ZERO demo code. *(Superseded 2026-07-11: Story 10.4 shipped as `LoudnessGraphView` — the LUFS-over-time graph this note anticipated — reworked in d3af680/#96; the chart-probe seed has been removed, its intent realized. See sprint-change-proposal-2026-07-11-story-10-4.md.)*

## Acceptance Criteria

**AC1 — `LUFSReport` type.** New file `Sources/BoomBoomBoomKit/LUFSReport.swift` (root — <5 cohesive files rule). `public struct LUFSReport: Sendable, Equatable, CustomStringConvertible` with the DD #2 stored/computed roster exactly; NO `Hashable` (deviation from epic AC documented in DD #2). Init clamps NaN/±Inf to the documented −100.0 sentinel in every stored field; clamping test-locked per field. `LoudnessSample`/`LoudnessSeries` per DD #3.

**AC2 — No UI-framework imports in the library.** `grep -rn "import SwiftUI\|import Charts" Sources/BoomBoomBoomKit/` returns zero matches (verification step, recorded in Completion Notes).

**AC3 — Service reshape.** `analyzeLUFS(url:options:) throws -> LUFSReport?` with `LUFSOptions` per DD #9 replaces the `(url:maxSeconds:) -> Double?` form. `LUFSAnalyzer` and `LUFSResult` stay internal. The 3 tests at `AudioAnalysisServiceTests.swift:105-137` are migrated.

**AC4 — Fixture matrix.** Every format in {WAV, AIFF, MP3, FLAC, M4A, CAF} — resolved via `AudioFixtures` from `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/` (CAF newly generated per DD #13) — returns a non-nil `LUFSReport` with finite `integratedLUFS` and non-empty `momentaryLUFS`.

**AC5 — Short-term series is an exact 3.0s rectangle.** Implemented via the 100ms cell primitive (DD #4). Test: a synthesized level-step signal's short-term response matches the analytic exact-rectangle expectation; an overlapping-400ms-block approximation would fail this test.

**AC6 — Byte-identity of existing measurements.** Tier-1 `bitPattern` tests (DD #11) prove `integratedLUFS` and `momentaryLUFS` (the existing `blockLoudnessValues` path) are bit-identical to pre-story values for synthesized inputs; tier-2 fixture tolerance tests pin lossy-format values with `maxSeconds: 30` explicit.

**AC7 — LRA per Tech 3342.** Gates and percentiles per DD #5; `loudnessRangeLU == nil` for gated program < 60s (test with 30s signal) and non-nil with correct P95−P10 for a synthesized two-level ~70s signal (±0.5 LU); `lraLowLUFS`/`lraHighLUFS` equal the percentile edges.

**AC8 — True-peak per Annex 2.** Polyphase per DD #6; inter-sample-peak sine oracle within ±0.3 dBTP at 44.1k and 48k; separate 96k 2× test; asymmetric-transient test locking convolution direction (correlation-vs-convolution trap); chunked processing (no 4N allocation — verified by review, not instrumentation); raw sample max folded in.

**AC9 — Error contract.** Non-{44.1, 48, 96} kHz input throws `LUFSAnalysisError.unsupportedSampleRate` (NOT `PCMBufferReaderError` — epic AC corrected per DD #8); unreadable file still throws `PCMBufferReaderError`; all-silence and <400ms inputs return nil. All three paths test-locked.

**AC10 — Perf + corpus floors.** `make benchmark` OA300 wall-clock regression ≤ 1% vs the latest `_bmad-output/perf-baselines/` entry (BPM path untouched — this is a tripwire); the four unconditional corpus floors hold (OA300 ≥ 57/82 + 73/82; GiantSteps ≥ 537/661 + 546/661).

**AC11 — Docs + governance.** DocC `///` on every new public symbol including the DD #7 mono-TP caveat and DD #8 nil-vs-throw contract; README gains a "LUFS" section (chart snippet using the classic `ForEach`+`LineMark` form per the probe's type-checker finding); epics.md Story 8.1 section patched with the four factual corrections + amended-AC pointer (same PR); `deferred-work.md` entries added for per-channel true-peak (→ 8.2) and LUFS cancellation (→ 8.2); promotion list named in the PR description per Mary's seam rule. **Valve:** if true-peak resists pure-vDSP implementation, split per the epic's 8.1a/8.1b mechanism and document in `_bmad-output/implementation-artifacts/8-1-pressure-release.md`.

## Tasks / Subtasks

- [x] T0 (AC6) — Capture byte-identity baselines FIRST: on current develop, dump `bitPattern` hex literals for integrated + block values per synthesized input and per lossless fixture (`maxSeconds: 30`); commit literals inside the new tests. Red-then-green ordering: these tests exist before any analyzer edit.
- [x] T1 (AC5) — `LUFSAnalyzer`: 100ms mean-square cell pass (additive; existing 400ms block path verbatim).
- [x] T2 (AC5) — Short-term series from 30-cell exact rectangle; `<3s input → empty shortTermLUFS` semantics test.
- [x] T3 (AC7) — LRA: abs/rel gating + P95/P10 over short-term distribution; <60s nil rule; band edges.
- [x] T4 (AC8) — True-peak polyphase: ITU taps, 4 phases via `vDSP_conv` (mind correlation direction — pre-reverse taps or negative stride; subfilters are NOT symmetric), edge zero-padding (`tapCount-1`), chunked running max, raw-max fold, 96k 2× design.
- [x] T5 (AC1, AC2) — `LUFSReport.swift` + `LoudnessSample`/`LoudnessSeries` + NaN-clamp init + `description` + computed extremes/`samples`.
- [x] T6 (AC3, AC9) — `LUFSOptions` + service reshape + `LUFSAnalysisError` + nil-vs-throw wiring.
- [x] T7 (AC3) — Migrate the 3 existing service tests.
- [x] T8 (AC4) — `afconvert` CAF fixture; fixture-matrix suite (`LUFSReportTests.swift`).
- [x] T9 (AC8 tolerances, DD #12) — Reference-signal suite: ±0.1 LU @ 48k; measure 44.1k and record; TP oracle ±0.3 dB; LRA two-level signal.
- [x] T10 (AC10, AC11) — Gates (`make fmt`, `make lint`, `make test`, `make benchmark`), DocC, README, epics.md patch, `deferred-work.md` entries, Completion Notes with exact counts.

### Review Findings

Code review 2026-06-10 (Blind Hunter via Codex thread 019eb2fc + Edge Case Hunter + Acceptance Auditor; 3 findings dismissed as noise — DD #6-authorized 176.4 kHz deviation, report-consistency assertion mislabeled tautological, T0 ordering unverifiable-but-outcome-verified).

- [x] [Review][Decision→Patch] LRA 60s reliability floor counts short-term window starts, not gated programme duration — `LUFSAnalyzer.computeLoudnessRange` guarded `Double(gated.count) * 0.1 >= 60.0`, but N short-term windows span (N−1)·0.1+3.0 s of programme, so a fully-gated 60.0–62.9s programme returned `nil` despite the DocC/README contract "nil when gated programme < 60s" (found independently by all three layers). RESOLVED (operator choice a): guard fixed to programme-coverage semantics `(Double(gated.count) - 1.0) * 0.1 + 3.0 >= 60.0`; boundary locked by new test `exactlySixtySecondsBoundary` (60.0s fully-gated → non-nil, near-zero LRA).
- [x] [Review][Decision→Patch] `LUFSOptions.maxSeconds` accepted non-finite/huge values → fatal trap, not a throw — NaN/Inf/`>~1e15` flowed verbatim into `PCMBufferReader`'s `Int64(format.sampleRate * maxSeconds)`, which traps; `<= 0` silently yielded nil/`bufferAllocationFailed` (pre-story hole, but the knob is newly public API). RESOLVED (operator choice a, `votingThreshold` silently-clamp precedent): `analyzeLUFS` forwards `maxSeconds` only if finite, > 0, and < 1e9 s, else treats as nil (full file); documented on the field; locked by parameterized test `garbageMaxSecondsSanitized` (NaN/±Inf/0/−5/1e15).
- [x] [Review][Patch] Unstage the DO-NOT-COMMIT demo probe — `LUFSChartSchemaProbe.swift` and the `project.pbxproj` membership edit were STAGED (File List claimed "untracked"/"working-tree-only"); `git restore --staged` applied — probe is now untracked, pbxproj edit working-tree-only, matching DD #14 [Demo/BoomBoomBoomBPM/]
- [x] [Review][Patch] AC11 partial: 3 new public symbols lacked DocC `///` — added to `LUFSReport.description`, `LoudnessSample.init(time:lufs:series:)`, `LUFSOptions.init()` [Sources/BoomBoomBoomKit/LUFSReport.swift]
- [x] [Review][Patch] Public `LUFSReport.init` accepted `stepSeconds <= 0`, producing colliding `LoudnessSample.id` values → SwiftUI `ForEach` undefined behavior. Fixed: non-finite OR non-positive `stepSeconds` falls back to the documented 0.1 grid (amends DD #2's blanket −100 sentinel for this one field — a time grid is not a loudness; documented in init DocC); locked by `stepSecondsGarbageFallback` [Sources/BoomBoomBoomKit/LUFSReport.swift]

Post-patch gates: `make fmt` → `make lint` (1 violation = canonical TODO), `make test` 527 tests / 115 suites green (+3 review tests); byte-identity suite untouched and green; corpus benchmarks not re-run — patches touch only the LUFS path (zero `BPMAnalyzer` changes), AC10 runs stand.
- [x] [Review][Defer] A single NaN/±Inf sample silently poisons `maxTruePeakDBTP` to the −100 sentinel — loudness path is per-block NaN-robust but the all-or-nothing true-peak fold is not (`vDSP_maxmgv` propagates NaN → `guard maxAbs > 0` fails → floor; +Inf → clamped to −100 by the report init) [Sources/BoomBoomBoomKit/LUFSAnalyzer.swift:459,503,508] — deferred, corrupt-float-input-only; entry 8-1-D4

PR #32 Copilot triage 2026-06-10 (layer 5; 4 comments, all verified against code — 0 false positives; Codex cross-check thread 019eb361 confirmed all verdicts):

- [x] [Review][Patch] Copilot 3391318119: `sentinelFloor` doc said "non-finite or below-measurable" but the init clamps non-finite ONLY (finite < −100 preserved) — doc reworded to the actual invariant; finite clamping deliberately NOT added (caller-data integrity + byte-identity contract) [Sources/BoomBoomBoomKit/LUFSReport.swift]
- [x] [Review][Patch] Copilot 3391318170: short-FLAC test's `try?` + `if let report = report ?? nil` silently swallowed unexpected throws — converted to `try` + `if let report` so infrastructure/decode regressions fail loudly (fixture verified 44.1 kHz mono via afinfo; no content flakiness) [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift]
- [x] [Review][Patch] Copilot 3391318199: archived probe still carried the stale "DO NOT COMMIT" header after its deliberate relocation in b901608 — header reworded to archived-artifact / Story 10-4 seed status [_bmad-output/implementation-artifacts/10-4-lufs-chart-probe.swift]
- [x] [Review][Patch] Copilot 3391318232: per-call `Array(truePeakMidpointTaps2x.reversed())` on the 96k path — Copilot's suggested fix (use taps directly) REJECTED (erases the documented reversed-form discipline, the AC8 correlation-vs-convolution guard); patched instead by hoisting to `truePeakMidpointTaps2xReversed` static mirroring the 4× sibling. Identical by construction (same expression hoisted); covered by the 96k ISP sine oracle + the 48k/4× asymmetric-transient reversal-convention guard [Sources/BoomBoomBoomKit/LUFSAnalyzer.swift]

## Dev Notes

**Architecture compliance.** Value types only; all bulk numerics vDSP (`vDSP_measqvD`, `vDSP_conv`, `vDSP_maxmgv`; the 30-cell sliding sum operates over block summaries, not sample buffers — a plain loop or prefix-sum is fine at that altitude); K-weighting stays `vDSP.Biquad<Double>` and is NOT touched (byte-identity contract); true-peak FIR may be Float (not the near-pole IIR case). `LUFSAnalyzer.swift:94` carries the canonical acceptable TODO — leave it. LUFS files stay at `Sources/BoomBoomBoomKit/` root (<5 files). `make fmt` BEFORE `make lint`.

**The cell/block fp-discipline rule (DD #4) is the story's central regression hazard.** `mean(4 cells)` is mathematically equal to the 400ms `measqv` but NOT bit-equal (reduction order). Any "simplification" that derives momentary or integrated from cells kills AC6. The byte-inert ÷ semantic split pattern (Epic 7 retro A3, re-armed for Epic 8) is exactly this: land additive structure under a green byte oracle; never flip semantics and structure in one motion.

**True-peak pitfalls (panel, ranked):** (1) gain — ITU per-phase taps bake in ×L; a self-designed windowed-sinc for the 96k 2× case must scale by L manually (classic silent −12 dB bug); (2) `vDSP_conv` computes correlation — the polyphase subfilters are asymmetric, so this IS a wrong answer if skipped and invisible on symmetric test signals (hence the asymmetric-transient test); (3) over-allocate input by `tapCount−1` and zero-pad both ends or the last samples' peaks are missed/garbage.

**Existing code being modified (read before editing):** `LUFSAnalyzer.swift` (217 lines — block machinery at `computeBlockMeanSquares`, gating at lines 112-152, `-100.0` display floor precedent at line 36); `AudioAnalysisService.swift:993-1011` (the method being reshaped); `AudioAnalysisServiceTests.swift:105-137`; `LUFSAnalyzerTests.swift` (sine-generator pattern to reuse, lines 14-31). Demo app does NOT call `analyzeLUFS` (verified) — no demo changes.

**Previous-story intelligence (Epic 7 retro, 2026-06-05).** A1 fail-closed discipline re-arms here: the LRA <60s rule and the unsupported-rate throw must fail CLOSED (nil/throw), never fall through to a wrong number. A3 byte-inert ÷ semantic split: applied via T0-first ordering. Epic 7's recurring failure modes (fail-open guards, weak fixtures) are the named countermeasures behind AC6/AC9.

**Git intelligence.** Recent commits are ML-harness Python (`ae04011` land epic 7); the last Sources-heavy work is Epic 6 (`988a4f5`) — its review history is the live precedent for public-type conformance debates (`Hashable`+NaN) and additive-field byte-inertness.

**Standards references for doc comments:** ITU-R BS.1770-5 (Annex 1 gating, Annex 2 true-peak), EBU R 128 (−23 LUFS target, −1 dBTP ceiling, LRA ≥1 min note), EBU Tech 3341 §2.2 (M/S windows + ≥10 Hz), EBU Tech 3342 §3.1 (LRA gates + percentiles). Cite section numbers in `///` per project rule.

**Scratch probe:** `Demo/BoomBoomBoomBPM/LUFSChartSchemaProbe.swift` is untracked and must NOT be committed by this story; it seeds Story 10-4.

### Project Structure Notes

New: `Sources/BoomBoomBoomKit/LUFSReport.swift`, `Tests/BoomBoomBoomKitTests/LUFSReportTests.swift`, CAF fixture. Modified: `LUFSAnalyzer.swift`, `AudioAnalysisService.swift`, `AudioAnalysisServiceTests.swift`, `LUFSAnalyzerTests.swift` (additive), `README.md`, `_bmad-output/planning-artifacts/epics.md`, `_bmad-output/implementation-artifacts/deferred-work.md`. `LUFSAnalysisError` may live in `LUFSReport.swift` or its own file (dev's call; <5-file root rule either way).

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 8.1] (as amended by this story's PR)
- [Source: _bmad-output/planning-artifacts/architecture.md#KDD-S2 / KDD-C4] — `DecodedAudio` wiring is Story 8.2, NOT this story
- [Source: _bmad-output/project-context.md] — ADR-11, vDSP rules, byte-equality backbone, Hashable/NaN precedents
- [Source: _bmad-output/implementation-artifacts/epic-7-retro-2026-06-05.md] — A1/A3 carry-forwards
- Codex consult thread 019eaffb (cadences); party-mode panel 2026-06-10 (this file, Spec validation history)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.x (claude-fable-5[1m]) via bmad-dev-story, 2026-06-10, on `rterhaar/8-1` off `rterhaar/epic-8`.

### Debug Log References

- **T0 dump harness** ran twice against the pre-story analyzer (develop @ `ae04011`); the second run measured `sample-with-cover.m4a` integrated differing at the 1e-7 LU level from the first (−21.822245236816986 vs −21.822245067974563) — empirical same-machine confirmation of DD #11's "AAC decode is not byte-stable". MP3 was stable across runs but stays tier-2 by rule.
- **`sample.wav` is 8 kHz** (1.0s, Int16 mono) — pre-story analyzer returns nil for it; under the new contract it throws. Two consequences: (a) the DD #13 CAF fixture is generated from `test-bwf.wav` (44.1k, 5s) instead of the spec-named `sample.wav` (an 8 kHz CAF would throw and fail AC4); (b) `sample.wav` became the real-file asset for the AC9 `unsupportedSampleRate` throw test.
- **ITU tap table verified online** against the published BS.1770-3 text (unchanged through -5) before embedding — all 48 values are dyadic multiples of 2⁻¹³, per-phase DC gain ≈ 1.0016.
- **Correlation-direction note for review:** taps are stored published-form and pre-reversed once into `truePeakPhases4xReversed` so `vDSP_conv` (correlation) computes true convolution. For the ITU table specifically, phase3 = reverse(phase0) and phase2 = reverse(phase1), so correlating with the un-reversed set would produce the same VALUE SET at shifted positions — the asymmetric-transient test therefore locks total interpolation correctness against a direct-form Double oracle (tap entry, padding, chunk seams) rather than direction alone; direction is locked by construction.
- **96k coefficient finding (DD #12 measurement step):** the bundled 96k K-weighting high-shelf has a pre-existing −0.4767 LU offset at 997 Hz (analytic biquad response: +0.214 dB vs the 48k prototype's +0.691 dB). Pre-existing — visible in the T0 baseline (sine96k −20 target measured −20.4767) and barely inside the old ±0.5 cross-rate test. Handled per the spec's own measure-and-record rule: coefficients untouched (AC6 freeze), 96k reference test pinned ±0.1 around the measured offset, deferred-work entry 8-1-D3 filed. 48k delta +0.000023 LU; 44.1k delta −0.001036 LU (both inside ±0.1 nominal — the DD #12 44.1k contingency was NOT needed).

### Completion Notes List

- **AC1** — `Sources/BoomBoomBoomKit/LUFSReport.swift`: `LUFSReport` (`Sendable, Equatable, CustomStringConvertible`, NOT `Hashable`) with the DD #2 roster exactly; NaN/±Inf → −100.0 sentinel clamping test-locked per scalar field and element-wise per series (`LUFSReportTypeTests`, 10 tests incl. `LoudnessSeries.allCases.count == 2` invariant lock). `LoudnessSample`/`LoudnessSeries`/`LUFSAnalysisError`/`LUFSOptions` co-located in the same file.
- **AC2** — `grep -rn "import SwiftUI\|import Charts" Sources/BoomBoomBoomKit/` → zero matches (verified post-implementation).
- **AC3** — `analyzeLUFS(url:options:) throws -> LUFSReport?` replaces `(url:maxSeconds:) -> Double?`; `LUFSAnalyzer`/`LUFSResult` remain internal; the 3 tests at `AudioAnalysisServiceTests.swift` migrated (the matches-direct-call test now pins `maxSeconds: 30` on both paths and additionally asserts momentary-series equality).
- **AC4** — fixture matrix green for WAV(`test-bwf`)/AIFF/MP3/FLAC/M4A(`sample-with-cover`)/CAF(`test-bwf`, newly generated via `afconvert -f caff -d LEI16`), parameterized test + a WAV↔CAF lossless-parity test. Deviation from DD #13 documented in Debug Log (spec-named source `sample.wav` is 8 kHz).
- **AC5** — 100ms cell primitive (`computeCellMeanSquares` + `computeShortTermMeanSquares`, exact 30-cell mean, energy domain, log last). `exactRectangleAtLevelStep` asserts the step-crossing window matches the analytic energy-mix within ±0.05 LU AND that the 30-overlapping-400ms-block (3.3s triangular) value computed from the actual block series deviates >0.1 LU — the test provably discriminates.
- **AC6** — `LUFSByteIdentityTests.swift` (10 tests, captured BEFORE any analyzer edit, red-green ordering honored): tier-1 bitPattern locks on 4 synthesized signals (integrated + count + first/last block + FNV-1a over the full block series) and 3 lossless fixtures (`maxSeconds: 30` pinned); tier-2 ±0.5 LU tolerance pins on 3 lossy fixtures. All green after the analyzer extension — integrated + momentary paths are bit-identical.
- **AC7** — LRA per Tech 3342 (abs −70, rel −20 energy-domain, P95−P10 linear-interpolation percentiles): 30s → nil + sentinel edges; 70s two-level → 20.0 ±0.5 LU with `lraHigh − lraLow == loudnessRangeLU` exact and edges on the plateaus. Fails CLOSED (Epic-7 A1 carry-forward).
- **AC8** — polyphase true-peak: ISP sine oracle (fs/4 @ π/4 phase: −9.03 dB samples → −6.02 dBTP truth) within ±0.3 at 44.1k AND 48k (4×, ITU taps) AND 96k (2×, self-designed Blackman-windowed sinc midpoint interpolator, explicitly DC-normalized); raw-max fold locked by the unit-impulse test (0.0 dBTP, not the −0.245 filtered value); asymmetric-transient test (bursts at 1000, at the 65534–65539 chunk seam, and at the tail edge) matches a direct-form Double oracle within 0.01 dB. Chunked processing: per-chunk `vDSP_conv` + `vDSP_maxmgv` running max with 11-sample context carry — no 4N buffer exists anywhere (verified by construction; the only allocations are one `chunkSize+11` input buffer and one `chunkSize` phase-output buffer, reused).
- **AC9** — error contract test-locked (`LUFSErrorContractTests`, 4 tests): 8 kHz real file → `LUFSAnalysisError.unsupportedSampleRate(8000, [44100, 48000, 96000])`; nonexistent file → `PCMBufferReaderError`; runtime-written temp WAVs: 2s silence → nil, 0.2s sine → nil.
- **AC10** — `make benchmark` OA300 suite GREEN (floors are unconditional `#expect`s; merge-strategy table confirms maxConfidence 57/82 on the comparison path); `make benchmark-giantsteps` GREEN; `make perf-benchmark` ×2: OA300 Acc1=58/82 Acc2=74/82, GiantSteps Acc1=537/661 Acc2=546/661 (all four floors held, counts unchanged from Epic-6 close-out); wall-clock 0.178s → 0.180s (+1.0%) then 0.180s → 0.179s (−0.2%) — net vs the pre-story 2026-05-30 baseline ≈ +0.6%, inside the ≤1% tripwire (BPM path untouched; `git diff` confirms zero BPMAnalyzer changes).
- **AC11** — DocC `///` on every new public symbol (mono-TP caveat on `maxTruePeakDBTP` verbatim per DD #7; nil-vs-throw contract on `analyzeLUFS`; standards sections cited: BS.1770-5 Annex 1/2, R 128, Tech 3341 §2.2, Tech 3342 §3.1); README: features line, usage snippet, nil-table row (now documents the throw), Public API table rows, and a new "LUFS measurement" section with the classic `ForEach`+`LineMark` chart snippet + the LinePlot type-checker warning; epics.md Story 8.1 amendment rides this PR (staged at story creation); `deferred-work.md`: 8-1-D1 (per-channel TP → 8.2), 8-1-D2 (cancellation → 8.2), 8-1-D3 (96k coefficient offset). **Valve NOT needed** — true-peak landed pure-vDSP; no 8.1a/8.1b split, no pressure-release file.
- **Gates (exact counts):** `make build` clean; `make test` 524 tests / 115 suites passed (pre-story baseline 483/105 → +41 tests, +10 suites); `make fmt` run before `make lint`; `swiftlint` 1 violation = the pre-existing canonical `LUFSAnalyzer` TODO (now line 127, was 94 — same TODO, moved by additive code above it); `make py-lint` green (within `make lint`); AC2 grep zero matches.
- **Internal→public promotions in this story (PR-description list per AC11):** `LUFSReport`, `LoudnessSample`, `LoudnessSeries`, `LUFSAnalysisError`, `LUFSOptions` — all net-new declared in AC1/DD #2/#3/#8/#9. NO existing internal type was promoted (`LUFSAnalyzer`, `LUFSResult` stay internal).
- **Red-green honesty note:** T0's byte-identity oracle was authored and verified green BEFORE any analyzer edit (the spec's red-green requirement for the regression contract). The new-feature tests (T1–T4/T9 suites) were authored alongside their implementation in one build cycle, not strictly test-first; their failure modes are locked analytically (rectangle discriminator, Double oracle, measured offsets) rather than by observed-red.
- **Pending user action (operator-owned closeout):** (1) separate-LLM `/bmad-code-review`; (2) 1Password-signed commit + PR `rterhaar/8-1` → `rterhaar/epic-8` (include the staged epics.md amendment; do NOT commit `Demo/BoomBoomBoomBPM/LUFSChartSchemaProbe.swift` or its pbxproj membership edit — they seed Story 10-4); (3) optional perf-baseline follow-up commit convention applies (two new baseline JSONs generated at `ae04011`); (4) Story 10-4 (demo LUFS chart) is pull-forwardable immediately after this story closes.

### File List

New:
- `Sources/BoomBoomBoomKit/LUFSReport.swift`
- `Sources/BoomBoomBoomKitTestSupport/Resources/AudioFixtures/test-bwf.caf`
- `Tests/BoomBoomBoomKitTests/LUFSByteIdentityTests.swift`
- `Tests/BoomBoomBoomKitTests/LUFSReportTests.swift`
- `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260610T185422Z--ae04011--8e0ca3dd.json`
- `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260610T185546Z--ae04011--a9c6f08e.json`

Modified:
- `Sources/BoomBoomBoomKit/LUFSAnalyzer.swift`
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`
- `Tests/BoomBoomBoomKitTests/LUFSAnalyzerTests.swift`
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift`
- `README.md`
- `_bmad-output/planning-artifacts/epics.md` (staged at story creation — rides this PR)
- `_bmad-output/implementation-artifacts/deferred-work.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/8-1-lufs-public-api-and-lufsreport-promotion.md` (this file)

NOT for commit (scratch, seeds Story 10-4):
- `Demo/BoomBoomBoomBPM/LUFSChartSchemaProbe.swift` (untracked)
- `Demo/BoomBoomBoomBPM/BoomBoomBoomBPM.xcodeproj/project.pbxproj` (working-tree-only probe membership edit)

## Change Log

- 2026-06-10 — PR #32 Copilot triage (layer 5): 4 comments, all valid after code verification, 0 false positives. Patched: sentinelFloor doc precision; short-FLAC test `try?` → `try` (loud failure on decode regressions); archived-probe header reword; 96k reversed-taps hoist to a static (Copilot's drop-the-reversal remedy rejected — discipline preserved). Codex cross-check (thread 019eb361) confirmed all verdicts. Gates re-run post-patch.
- 2026-06-10 — Code review (Blind Hunter via Codex + Edge Case Hunter + Acceptance Auditor): 6 findings → 5 patched in-pass (LRA 60s programme-coverage guard + boundary test; `maxSeconds` use-site sanitization; demo probe unstaged; 3 missing DocC comments; `stepSeconds` 0.1-grid fallback replacing the −100 sentinel for that field), 1 deferred (8-1-D4 NaN-poisoned true-peak), 3 dismissed. 527/115 tests green post-patch. Status → done.
- 2026-06-10 — Story 8.1 implemented (bmad-dev-story): chart-ready `analyzeLUFS(url:options:) -> LUFSReport?` reshape; 100ms cell primitive → exact-3.0s short-term series; Tech 3342 LRA with P10/P95 band edges; BS.1770-5 Annex 2 polyphase true-peak (4× ITU taps @ 44.1/48k, 2× windowed-sinc @ 96k); `LUFSAnalysisError` + `LUFSOptions` (full-file default); byte-identity locked (T0-first, 10 tests); 524/115 tests green; all four corpus floors held; wall-clock tripwire ≤1%. Reality-deltas vs spec, both documented in Debug Log: CAF fixture sourced from `test-bwf.wav` not the 8 kHz `sample.wav` (DD #13); 96k reference tolerance pinned around the measured −0.477 LU pre-existing coefficient offset per the DD #12 measure-and-record rule (deferred-work 8-1-D3). Status → review.
