# Story 3.4: Duration-Derived BPM Hint

Status: done

## Key Design Decisions

1. **NOT a `DSPTechnique` case — gated by an `Options` field instead.** The epic explicitly forbids adding a new `DSPTechnique` case ("Duration hint is applied during step 10 disambiguation… NOT as a new `DSPTechnique` case"). The architecture rule "Anti-pattern: Adding a DSP improvement that is always-on and not gated by `TechniqueSet`" still binds in spirit — every accuracy-affecting change must be opt-out-able and measurable. Synthesis: gate via `public var durationHint: Bool = true` on `AudioAnalysisService.Options` per ADR-11 (Options-first public configuration). Default `true` because brainstorm #35 frames it as "free signal, zero PCM cost" and AC #4 enforces the no-regression gate. Internal pass-through is `BPMAnalyzer.Options.fileDurationSeconds: Double?` (nil = no hint regardless). Validation is via the four corpus floor `#expect`s (OA300+GiantSteps × Acc1+Acc2), NOT via the 128-combo ablation matrix. Bypass note: internal callers (tests, benchmarks, future `BPMAnalyzer` consumers) can set `BPMAnalyzer.Options.fileDurationSeconds` directly without going through `AudioAnalysisService.Options.durationHint` — this is intentional (tests need to drive the hint without the file-open round-trip) and matches how internal callers can also set `enableTrace` independent of any public gate.

2. **File duration, NOT window duration.** Bar-count math (`BPM = bars * 4 * 60 / durationSeconds`) only produces musically plausible candidates when the duration is the FULL file duration (typical 60–360 s). For a 30 s analysis window, 64 bars → 512 BPM (absurd). `BPMAnalyzer` operates on a windowed slice (BPMAnalyzer.swift:153: `analysisWindow = Array(samples[dropOffset..<endSample])`) so it cannot compute the file's true duration from its inputs. The duration must flow in from `AudioAnalysisService`, which holds the URL. Read it from `AVAudioFile.length / processingFormat.sampleRate` via a new `PCMBufferReader.fileDuration(url:)` helper — same metadata that `AVAudioFile(forReading:)` already exposes. Cost: one extra file open per `analyzeBPM` call (sub-millisecond on local files).

3. **Pipeline placement: step 9.7, between click rescore (9.5) and `resolveOctaveAmbiguity` (10).** The epic says "applied during step 10 disambiguation (inside or adjacent to `resolveOctaveAmbiguity`)". `resolveOctaveAmbiguity` consumes `rescoredCandidates: [(bpm, score)]` and returns `(best, evidence)`. Boosting candidate scores BEFORE it runs lets the existing fused-periodicity heuristic (BPMAnalyzer.swift:1532-1550) and the `var best = candidates[0]` initial pick (line 1505) both feel the boost. Placement AFTER step 10 would only see the already-selected `winner` and could not change the disambiguation outcome — defeats the purpose. Composes naturally with click rescoring in series: step 9.5 click → step 9.7 duration → step 10 disambiguate → step 10b sub-band confirm → step 10c fine-grid. The "9.7" number (rather than 9.6) is intentional headroom: 9.6 is left free for a future micro-stage between click and duration if one becomes warranted (e.g., a candidate-pruning pass). No semantic significance to the gap.

4. **Boost formula: `score *= (1.0 + boostWeight)` on match, `boostWeight = 0.1`.** Pure multiplicative boost when ANY duration-derived candidate is within 2% relative tolerance. The boost is **corroborative** (raises matched candidates), NOT **damping** (never lowers unmatched candidates) — explicitly different from click rescore's blend (Story 3-3 DD#4 used `oldScore * (alpha + (1-alpha) * NCC)` which damps when NCC < 1). The asymmetry is intentional: duration is a weak prior, not a denoising signal — it should nudge a tied/near-tied disambiguation toward the structurally plausible candidate without ever penalizing rhythmically-strong-but-structurally-implausible candidates. A candidate that matches multiple bar-count-derived BPMs receives the boost EXACTLY ONCE (no compounding) — `if anyMatch { score *= 1.1 }`, not `for each match { score *= 1.1 }`.

5. **Bar counts: literal `[32, 64, 96, 128, 192, 256]`, in-range filter `60...200` BPM.** Per the epic AC. Worked examples (assume `minFileSeconds: 0` — Task 7's default 180 s threshold added post-halt suppresses the hint for sub-180 s files; the worked examples below are for the bar-count math itself):
   - 240 s track → 64=64, 96=96, 128=128, 192=192 BPM in range (32→32 and 256→256 filtered out)
   - 60 s track → 32=128 BPM in range (all others out) [requires `minFileSeconds < 60`]
   - 30 s track → all bar counts produce ≥ 256 BPM → empty hint, AC #3c graceful no-op [requires `minFileSeconds < 30`]
   Hardcode as `private static let` constants on `BPMAnalyzer` near `perceptualMinBPM`/`perceptualMaxBPM` (line 70). Not exposed publicly — epic specifies literal values; configurability is premature.

6. **Tolerance is RELATIVE (2%) with `barBPM` (the structural target) as the denominator.** Match condition: `abs(cand.bpm - barBPM) / barBPM <= 0.02`. Same shape as the shared accuracy matcher (`Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift:7`: `abs(detected - expected) / expected`) — `barBPM` is the structural target ("expected"), `cand.bpm` is the detected DSP value. A 2% window at a 60 BPM target = ±1.2 BPM, at 200 BPM target = ±4 BPM — the absolute window grows with tempo target, matching musical perception (a 1 BPM swing at 60 is more salient than at 200). Do NOT use `abs(a - b) / max(a, b)` or log ratios. Earlier drafts of this story used `/cand.bpm` as the denominator; corrected post-codex review to honor the existing `AccuracyMatchers` precedent.

7. **Trace field: `durationHintDetail: [String: String]?` on `BPMDiagnosticTrace`.** Mirrors `harmonicRatioDetail` and `subBandVoteDetail` shape. Keys: `"fileDurationSeconds"` (e.g., `"243.7"`), `"barCandidates"` (comma-separated `bars=BPM` pairs in range, e.g., `"64=64.0,96=96.0,128=128.0,192=192.0"`), `"boostedCandidates"` (comma-separated DSP BPMs that received the boost, e.g., `"128.0,192.0"`). Populated only when `enableTrace == true` AND `fileDurationSeconds != nil`. Same evolving-API treatment as the other trace fields. The known `String(format: "%.1f", bpm)` key-collision issue (Story 3-3 deferred-work item) is accepted for consistency — the cross-cutting trace-API revamp is out of scope.

8. **`BPMResult.candidates` carries the boosted scores.** Same contract as Story 3-3 DD#11: when the hint is active, the boosted candidate array flows into both `resolveOctaveAmbiguity` AND back out via `BPMResult.candidates` so multi-window `CandidateMergeStrategy` (CandidateMergeStrategy.swift:107) stays consistent with disambiguation. `trace?.rawCandidates` (BPMDiagnosticTrace.swift:57) continues to carry the pre-rescore array (before BOTH click rescore AND duration boost) so the upstream signal is preserved for diagnostics. Sort the boosted array by descending score with an explicit tiebreaker on original index (Swift `Array.sort` is not contractually stable per Story 3-3 DD#6).

9. **Public API addition, not breaking change.** `PCMBufferReader.readMonoSamples(...)` keeps its current signature. Add NEW `public static func fileDuration(url: URL) throws -> Double` that opens the file, reads `length / processingFormat.sampleRate`, returns the duration. Throws `PCMBufferReaderError.fileNotReadable(url)` for unreadable files (same error as `readMonoSamples`). Returns `0.0` for zero-frame files (mirrors the existing `readMonoSamples` zero-length behavior at PCMBufferReader.swift:55). Two `AVAudioFile(forReading:)` opens per `analyzeBPM` call instead of one is acceptable — file open is fast (sub-ms on local files, kernel-cached metadata), dwarfed by the seconds-long analysis. Alternative considered: keep `fileDuration` `internal` and lift to `public` only when a public consumer requests it (Story 5.x demo app, end-user introspection). Rejected for symmetry with `readMonoSamples` (also `public static func`) and because `fileDuration` is a low-cost, side-effect-free metadata helper that callers might reasonably want for UI ("Loading 3:42 of audio…") without needing the full PCM read.

10. **Graceful no-op when duration is missing or out of range.** Three paths must all degrade silently:
    - **(a) `durationHint == false`**: `AudioAnalysisService` skips the metadata read, passes `fileDurationSeconds: nil` to `BPMAnalyzer.Options`. Trace `durationHintDetail` stays nil.
    - **(b) duration read fails**: `AudioAnalysisService` calls `try? PCMBufferReader.fileDuration(url:)`; on throw or `<= 0` return, passes nil. Trace `durationHintDetail` stays nil.
    - **(c) all bar-count candidates filter out** (e.g., 5 s clip): `applyDurationHint` produces empty bar-candidate list, returns input candidates unchanged. Trace records `barCandidates: ""` and `boostedCandidates: ""` so the diagnostic shows the hint *ran* but produced no boosts.

    AC #3 is satisfied by paths (a) and (b). Path (c) is the also-graceful "duration was readable but bar counts didn't land in range" case — same observable behavior, different trace artifact for debugging.

11. **No env-var override for `boostWeight`.** Story 3-3 introduced `CLICK_RESCORE_ALPHA_OVERRIDE` (`#if DEBUG`-gated) for α-sweeping. Story 3-4 has only one tuning knob and the epic specifies the value literally — no sweep needed. Hardcode `boostWeight = 0.1` as a `private static let` next to the bar-count constants. If a future story wants to sweep, it can re-introduce the env-var pattern then.

12. **The hint composes weakly with sub-band voting and harmonic ratio resolution.** Same caveat as Story 3-3 DD#12: `resolveOctaveAmbiguity`'s sub-band voting branch (BPMAnalyzer.swift:1518-1524) chooses winners by sub-band ACF evidence, NOT candidate scores — when sub-band voting fires for a 2:1 octave pair, the duration boost has no effect on the final winner. Same for step 10b's `confirmWithSubBandPeaks` (line 1586+) which never reads scores. The hint's effective reach is concentrated in:
    - The fused-periodicity fallback path (lines 1532-1550) where `faster.score >= best.score * octaveScoreThreshold` gates the 2:1 promotion — boosting CAN flip this gate
    - Single-candidate or non-harmonic-pair cases where `var best = candidates[0]` after sort wins — boosting can change `best`
    - The 3:2 / 3:1 trace-only branches where `best` is unchanged but the boost still influences the initial sort

    Task 5.5 measures this empirically. If `changedFinalBPM == 0` on OA300, the technique is functionally inert at the default intensity — Completion Notes must document this honestly (per Story 3-3 close-out precedent).

## Story

As a library author,
I want to use file duration as a weak prior for BPM disambiguation,
so that structurally plausible BPMs from common bar counts provide an additional zero-cost signal that nudges disambiguation toward the right answer on near-tied DSP candidates.

## Acceptance Criteria

1. **Given** `AudioAnalysisService.Options`
   **When** the new field is added
   **Then** `public var durationHint: Bool = true` exists with a doc-comment matching the existing `enableTrace`/`mergeStrategy` non-optional-with-default pattern
   **And** the Options struct doc-comment's "Field-style convention" block lists `durationHint` alongside `intensity`, `mergeStrategy`, `maxSeconds`, `enableTrace` as non-optional always-present fields with sensible defaults
   **And** the field's doc-comment explains: weak structural prior; auto-reads file duration via AVFoundation; boosts DSP candidates that match common bar-count-derived BPMs by 10%; default-on per ADR-11 because the cost is negligible and AC #4 enforces the no-regression gate; setting to `false` skips both the metadata read and the boost.

2. **Given** an audio file with a readable duration `D` (seconds) AND `options.durationHint == true`
   **When** `analyzeBPM(url:options:)` runs
   **Then** `PCMBufferReader.fileDuration(url:)` returns `D`
   **And** the value is passed to `BPMAnalyzer.Options.fileDurationSeconds`
   **And** during the new pipeline step 9.7 (between click rescore at step 9.5 and `resolveOctaveAmbiguity` at step 10), candidate BPMs are computed for `bars ∈ [32, 64, 96, 128, 192, 256]` via `barBPM = (bars * 4 * 60) / D` (gated by `D >= durationHintMinFileSeconds`; default 180 s per Task 7)
   **And** only bar candidates with `60 ≤ barBPM ≤ 200` are retained
   **And** for each retained `barBPM`, every DSP `candidates[i]` with `abs(candidates[i].bpm - barBPM) / barBPM <= 0.02` has its score multiplied by `1.0 + boostWeight` where `boostWeight = 0.1`
   **And** a candidate that matches multiple `barBPM` values receives the boost EXACTLY ONCE (no compounding)
   **And** the boosted candidate array is sorted descending by score with an explicit tiebreaker on original index (deterministic per Story 3-3 DD#6)
   **And** the boosted array flows into both `resolveOctaveAmbiguity` and back out via `BPMResult.candidates` (per Story 3-3 DD#11 contract).

3. **Given** any of the no-op paths
   **When** the hint cannot apply
   **Then** the original `candidates` array flows unchanged into `resolveOctaveAmbiguity`. The three paths and observable behaviors:
   - **3a (`durationHint: false`)**: `AudioAnalysisService` passes `fileDurationSeconds: nil` to `BPMAnalyzer.Options` (and skips the `PCMBufferReader.fileDuration` call). The "skip" is observable indirectly via `trace?.durationHintDetail == nil` since the trace is only populated inside `applyDurationHint`, which is only called when `fileDurationSeconds != nil`. The unit test asserts `trace?.durationHintDetail == nil` as the observable signal that the hint did not run; direct verification of "no `fileDuration` call" would require a reader spy/seam (out of scope for this story — the static-call architecture is intentional per the project's preference for stateless services).
   - **3b (duration read fails)**: `AudioAnalysisService` calls `try? PCMBufferReader.fileDuration(url:)`; on throw or `<= 0` return, passes `fileDurationSeconds: nil`. `trace?.durationHintDetail == nil`.
   - **3c (no in-range bar candidates)**: `BPMAnalyzer` receives a non-nil `fileDurationSeconds` but all bar-count BPMs filter out (e.g., 5 s clip yields only 384+ BPMs). The returned candidates are unchanged. `trace?.durationHintDetail` is populated with all THREE keys: `["fileDurationSeconds": "5.0", "barCandidates": "", "boostedCandidates": ""]`. Empty strings on the last two keys distinguish "ran but produced nothing" from `nil` ("did not run"). Per Task 2.3 step 2, `fileDurationSeconds` is always populated when the helper is called — only `barCandidates` and `boostedCandidates` may be empty.

4. **Given** `make benchmark` (OA300) AND `make benchmark-giantsteps`
   **When** the corpora run with `options.durationHint == true` (default) at the default intensity
   **Then** OA300 Acc1 ≥ 57/82 (69.5%) AND Acc2 ≥ 73/82 (89.0%)
   **And** GiantSteps Acc1 ≥ 537/661 (81.2%) AND Acc2 ≥ 546/661 (82.6%)
   **And** `make oracle` shows no regression on the DAW oracle set (Icicle stays within 2% Acc1; no other DAW oracle track flips from in-tolerance to out)
   **And** the same four corpus floors are unconditional `#expect` assertions (matching Story 3-3 AC #6 and Story 3-3a AC #6) so wiring bugs surface at the test layer regardless of whether the hint actually changed any track outcomes.

5. **Given** the `durationHint` opt-out path
   **When** the corpora are run with a fresh `Options` instance whose `durationHint` is set to `false`
   **Then** OA300 Acc1 == 57/82 AND Acc2 == 73/82 EXACTLY (matching the pre-Story-3-4 aggregate baseline from Story 3-3a Completion Notes; same `maxConfidence` merge)
   **And** GiantSteps Acc1 == 537/661 AND Acc2 == 546/661 EXACTLY (strict-2% tolerance, matching the Story 3-3a baseline)
   **And** if a per-track baseline JSON snapshot is captured during Task 5.0 (pre-implementation), the per-track BPM list with `durationHint: false` matches that snapshot 1:1; otherwise the aggregate-equality gate above is the sole regression-safety control and Completion Notes must document this gap. Any drift in either gate means duration-related state is leaking into the no-hint path.

6. **Given** the unit-test gauntlet exercising the helper directly via `@testable import BoomBoomBoomKit`
   **When** `applyDurationHint(candidates:fileDurationSeconds:trace:)` (or equivalently-named internal static) is called with hand-crafted inputs
   **Then** the four synthetic cases hold:
   - **6a (clean match at 240 s, all candidates match)**: `D = 240.0`, candidates `[(128.0, 1.0), (64.0, 1.0), (96.0, 1.0)]`. All three exactly match a bar count (128 = 128 bars, 64 = 64 bars, 96 = 96 bars). Assert all three scores become `1.1` and the order respects the tiebreaker on original index → `[(128.0, 1.1), (64.0, 1.1), (96.0, 1.1)]`.
   - **6b (no-match at 240 s)**: `D = 240.0`, candidates `[(100.0, 1.0), (110.0, 1.0)]`. Closest in-range bar candidate is 96 BPM (96 bars / 240 s) → `|100 - 96|/100 = 0.04 > 0.02`, no match. Assert both scores remain `1.0` and `trace.durationHintDetail["boostedCandidates"] == ""`.
   - **6c (selective boost preserves order at 240 s)**: `D = 240.0`, candidates `[(140.0, 1.0), (128.0, 0.5)]`. 140 has no in-range bar match (closest 192 → `|140-192|/192 = 0.271`, closest 128 → `|140-128|/128 = 0.0938`, both > 0.02). 128 matches 128 bars exactly → `|128-128|/128 = 0` ≤ 0.02 → boosted to `0.55`. Post-boost: `[(140.0, 1.0), (128.0, 0.55)]`. Sorted: same order. Assert this. **The boost cannot flip a 2× score gap** — corroborative-not-authoritative property in action.
   - **6d (boost flips a near-tie at 240 s)**: `D = 240.0`, candidates `[(140.0, 1.0), (128.0, 0.95)]`. 140 doesn't match; 128 matches 128 bars → boosted to `0.95 * 1.1 = 1.045`. Post-boost order: `[(128.0, 1.045), (140.0, 1.0)]`. Assert this exact order — **this is the case where the hint changes the disambiguation pick.**

7. **Given** an `applyDurationHintBarCounts` unit test
   **When** the helper computes bar candidates for various durations
   **Then** the in-range filter behavior is verified for at least three duration regimes:
   - `D = 240.0` → `[(64, 64.0), (96, 96.0), (128, 128.0), (192, 192.0)]` (4 in-range)
   - `D = 60.0` → `[(32, 128.0)]` (1 in-range; 64 bars → 256 out of range)
   - `D = 5.0` → `[]` (empty; even 32 bars → 1536 BPM is out of range — graceful no-op for AC #3c)

   Assert the EXACT expected list for each duration. Floating-point tolerance: BPMs may differ by `1e-9` in the helper's arithmetic; assert via `abs(actual - expected) < 1e-6` for each pair.

8. **Given** a `PCMBufferReader.fileDuration(url:)` unit test
   **When** the helper is called against the existing test fixtures
   **Then** for at least one fixture file (e.g., a 30 s × 120 BPM × 44.1 kHz click-track WAV synthesized via `createClickTrackWAV(bpm:sampleRate:durationSeconds:url:)` in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:442`), the returned duration is within `1.0 / sampleRate` of the requested `durationSeconds` (one-sample tolerance accounts for WAV header frame-count rounding)
   **And** for an unreadable URL (`URL(fileURLWithPath: "/nonexistent")`), the call throws `PCMBufferReaderError.fileNotReadable(url)`
   **And** the public visibility of `fileDuration` matches `readMonoSamples` (`public static func`).

9. **Given** an integration smoke test in `AudioAnalysisServiceTests.swift`
   **When** `AudioAnalysisService.analyzeBPM(url:options:)` is called on a synthetic 240 s × 128 BPM click-track WAV (via `createClickTrackWAV`) with `options.durationHint == true` AND `options.enableTrace == true`
   **Then** `result.bpm` is within 2% of 128.0 (sanity)
   **And** `result.trace?.durationHintDetail?["fileDurationSeconds"]` parses to a Double within `1e-1` of `240.0` (the `%.1f` format gives one-decimal precision)
   **And** `result.trace?.durationHintDetail?["barCandidates"]` contains `"128=128.0"` (the 128-bar match for the 240 s duration)
   **And** `result.trace?.durationHintDetail?["boostedCandidates"]` contains `"128.0"` (the DSP candidate that received the boost — formatting matches the `%.1f` pattern used by `harmonicRatioDetail`)
   **And** the corresponding test with `options.durationHint == false` produces the same BPM (within 2%) but `result.trace?.durationHintDetail == nil`.

10. **Given** Story 3-3 DD#12's caveat (the technique's effective reach may be small if disambiguation is score-blind in most paths)
    **When** Task 5.5 emits the per-track impact-style report for the duration hint at the default intensity
    **Then** the report writes `{changedRanking: N, changedDisambiguationWinner: M, changedFinalBPM: K, total: 82, analyzed: <pairs>, failed: <skipped>}` to `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json`
    **And** Completion Notes document the actual reach numbers honestly (no "by construction" hand-waving). If `changedFinalBPM == 0`, the story ships with that explicit acknowledgment plus a recommendation: keep the default `durationHint: true` for cheap insurance OR change to `false` and document the inertness — defer the call to the user during code review.

    **NOTE: AC #10 is informational, not pass/fail.** It gates that the report exists, has the documented schema, and that the numbers are honestly reproduced in Completion Notes. It does NOT impose a numeric floor on `changedFinalBPM` — the story explicitly accepts the possibility of measurable inertness (per the codex review and Story 3-3 DD#12 precedent). The pass/fail accuracy gates live in AC #4 (regression-floor `#expect`s) and AC #5 (opt-out byte-equality control).

## Tasks / Subtasks

- [x] Task 1: Add `PCMBufferReader.fileDuration(url:)` (AC: #2, #8)
  - [x] 1.1: `public static func fileDuration(url: URL) throws -> Double` added in `Sources/BoomBoomBoomKit/PCMBufferReader.swift` (mirrors the existing `readMonoSamples` open/throw pattern; returns `0.0` for zero-length files).
  - [x] 1.2: Doc-comment matches `readMonoSamples` style.
  - [x] 1.3: `PCMBufferReaderFileDurationTests` suite added with both tests; both pass.

- [x] Task 2: Add `BPMAnalyzer` constants and the `applyDurationHint` helpers (AC: #2, #3, #6, #7)
  - [x] 2.1: Three `private static let` constants added (`durationHintBarCounts`, `durationHintBoostWeight = 0.1`, `durationHintTolerance = 0.02`). Task 7 added a fourth: `durationHintMinFileSecondsDefault = 180.0`.
  - [x] 2.2: `static func applyDurationHintBarCounts(durationSeconds:minFileSeconds:)` added (internal, `@testable` access). Threshold default added in Task 7.
  - [x] 2.3: `static func applyDurationHint(candidates:fileDurationSeconds:minFileSeconds:trace:)` added (internal, `@testable`). Threshold pass-through added in Task 7. Original Task 2.3 sub-bullets:
    1. Compute `barCandidates = applyDurationHintBarCounts(durationSeconds: fileDurationSeconds)`.
    2. **Trace population (always when called)**: initialize `trace?.durationHintDetail = [:]`; set `["fileDurationSeconds"] = String(format: "%.1f", fileDurationSeconds)`; set `["barCandidates"] = barCandidates.map { "\($0.bars)=\(String(format: "%.1f", $0.bpm))" }.joined(separator: ",")`. Empty string when `barCandidates.isEmpty` — that's the AC #3c case.
    3. **Per-DSP-candidate boost (idempotent)**: for each `cand in candidates`, check `barCandidates.contains { abs(cand.bpm - $0.bpm) / $0.bpm <= durationHintTolerance }` (denominator is `barBPM`, the structural target — matches `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift:7`). Track which candidates received a boost in a `boostedBPMs: [Double]` array.
    4. Build new candidate array: `score *= (1.0 + durationHintBoostWeight)` if matched, else unchanged.
    5. Set `trace?.durationHintDetail?["boostedCandidates"] = boostedBPMs.map { String(format: "%.1f", $0) }.joined(separator: ",")` (empty string if no boosts).
    6. **Sort with explicit tiebreaker** for determinism (per Story 3-3 DD#6 — Swift `Array.sort` is not contractually stable):
       ```swift
       return boosted.enumerated()
         .map { (offset: $0.offset, bpm: $0.element.bpm, score: $0.element.score) }
         .sorted { lhs, rhs in lhs.score != rhs.score ? lhs.score > rhs.score : lhs.offset < rhs.offset }
         .map { (bpm: $0.bpm, score: $0.score) }
       ```
  - [x] 2.4: `durationHintDetail: [String: String]?` field added to `BPMDiagnosticTrace` under new `// MARK: - Step 9.7: Duration-Derived BPM Hint` section.
  - [x] 2.5: `DurationHintHelperTests` suite implemented BEFORE wiring (TDD red phase confirmed). Six tests total: 4 boost-gauntlet (6a-6d), parameterized bar-count test (AC #7), AC #3c graceful no-op. Task 7 added 2 more threshold-specific tests. All 8 pass.

- [x] Task 3: Wire the duration hint into `BPMAnalyzer.estimateBPM` (AC: #2, #3)
  - [x] 3.1: `var fileDurationSeconds: Double?` added (no `= nil` per implicit-nil rule). Task 7 added `var durationHintMinFileSeconds: Double` defaulting to the constant.
  - [x] 3.2: Step 9.7 inserted between step 9.5 (click rescore) and step 10 (resolveOctaveAmbiguity). `BPMResult.candidates` now uses `hintedCandidates`. Original Task 3.2 code:
    ```swift
    // Step 9.7: Duration-derived BPM hint (Story 3-4).
    // When AudioAnalysisService passes fileDurationSeconds (default-on via Options.durationHint),
    // candidates matching common bar-count-derived BPMs receive a 10% multiplicative score boost.
    // Weak corroborative prior — never damps. Composes in series with click rescore.
    let hintedCandidates: [(bpm: Double, score: Float)] =
      options.fileDurationSeconds.map { duration in
        applyDurationHint(
          candidates: rescoredCandidates,
          fileDurationSeconds: duration,
          trace: &trace)
      } ?? rescoredCandidates
    ```
    Then change line 304's call from `candidates: rescoredCandidates` to `candidates: hintedCandidates`. Update the BPMResult construction at line 360-361 to use `hintedCandidates` instead of `rescoredCandidates`.
  - [x] 3.3: Doc-comment block above step 9.5 updated with step 9.7 paragraph (append-only).
  - [x] 3.4: `DurationHintIntegrationTests` suite with two tests (boost-correct-candidate + nil-leaves-trace-nil) — both pass.

- [x] Task 4: Wire the duration hint into `AudioAnalysisService` (AC: #1, #2, #3a, #3b, #5)
  - [x] 4.1: `public var durationHint: Bool = true` added with doc-comment per AC #1. Task 7 added `public var durationHintMinFileSeconds: Double = 180`.
  - [x] 4.2: "Field-style convention" doc-block updated to list `durationHint` alongside non-optional always-present fields.
  - [x] 4.3: Metadata read added with `try? PCMBufferReader.fileDuration(url:)` and `flatMap { $0 > 0 ? $0 : nil }`. Original Task 4.3 code:
    ```swift
    let fileDurationSeconds: Double? =
      options.durationHint
        ? (try? PCMBufferReader.fileDuration(url: url)).flatMap { $0 > 0 ? $0 : nil }
        : nil
    ```
    `try?` swallows the throw (graceful degradation per AC #3b); `flatMap { $0 > 0 ? $0 : nil }` collapses `0.0` (zero-length file) to nil.
  - [x] 4.4: `BPMAnalyzer.Options` construction passes `fileDurationSeconds` and (per Task 7) `durationHintMinFileSeconds`. Duration is read once per `analyzeBPM` call. Original Task 4.4 code:
    ```swift
    options: .init(
      analysisWindowSeconds: windowSeconds,
      intensity: options.intensity,
      techniqueSet: options.techniqueSet,
      enableTrace: options.enableTrace,
      fileDurationSeconds: fileDurationSeconds)
    ```
    The duration is read ONCE per `analyzeBPM` call and reused for all windows (correct: file duration doesn't change per window).
  - [x] 4.5: `AudioAnalysisServiceDurationHintTests` suite with three tests (defaultsToTrue, true→boostedTrace, false→nilTrace) — all pass.

- [x] Task 5: Validate against corpora (AC: #4, #5, #10)
  - [x] 5.0: Benchmark helper plumbing — `runBenchmark(...)` on both OA300 and GiantSteps now accepts `durationHint: Bool = true`. Per-track pre-baseline JSON snapshots NOT captured pre-implementation (helper change had already landed before benchmarks ran); aggregate-equality gate is the sole regression-safety control — see Completion Notes.
  - [x] 5.1: `make benchmark` — OA300 Acc1=57/82 (69.5%), Acc2=73/82 (89.0%). AC #4 floors PASS.
  - [x] 5.2: `make benchmark-giantsteps` — Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). AC #4 floors PASS (post-Task-7 threshold; pre-threshold benchmark regressed by 1 Acc1 / 2 Acc2 — see Debug Log).
  - [x] 5.3: `make oracle` — DAW oracle test passes; Icicle stays within tolerance.
  - [x] 5.4: AC #5 opt-out controls — OA300 57/73 EXACTLY, GiantSteps 537/546 EXACTLY. Per-track snapshot gap acknowledged.
  - [x] 5.5: `make duration-impact-report` — `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json` records `{changedRanking: 0, changedDisambiguationWinner: 0, changedFinalBPM: 0, total: 82, analyzed: 82, failed: 0, intensity: "default", techniqueSet: "optimal"}`. Hint is FUNCTIONALLY INERT on OA300 (DD#12 caveat realized — score-blind disambiguation paths swallow the boost). Original Task 5.5 sub-bullets:
    - **changedRanking**: top candidate by post-hint score differs from top candidate by pre-hint score (use `trace.rawCandidates[0].bpm` vs `BPMResult.candidates[0].bpm` as the proxy — valid only when click is inactive, since `rawCandidates` is pre-click-rescore and `result.candidates` is post-everything; with click active the diff would mix click and duration effects)
    - **changedDisambiguationWinner**: `trace.disambiguationResult.bpm` differs between hint-on and hint-off runs
    - **changedFinalBPM**: `result.bpm` differs between hint-on and hint-off runs

    Emit counts to `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json` as `{changedRanking: N, changedDisambiguationWinner: M, changedFinalBPM: K, total: 82, analyzed: <pairs>, failed: <skipped>, intensity: "default", techniqueSet: "optimal"}`. Add a `make duration-impact-report` Makefile target at the same insertion point as the existing `click-impact-report` target (Makefile:84-92), gated by `DURATION_IMPACT=1` env var with `DURATION_IMPACT_OUT_DIR` env var for the output path.
  - [x] 5.6: `make perf-benchmark` — mean 0.175s vs prior 0.172s (+1.6%, well under the 5% threshold). New baseline file: `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260428T043702Z--f0c5b9e--995f3b83.json`.

- [x] Task 7: Add configurable minimum-duration threshold (post-halt directive, 2026-04-28)
  - [x] 7.1: `durationHintMinFileSecondsDefault: Double = 180.0` constant added.
  - [x] 7.2: `BPMAnalyzer.Options.durationHintMinFileSeconds: Double` added (default reads constant).
  - [x] 7.3: `public AudioAnalysisService.Options.durationHintMinFileSeconds: Double = 180` added with full doc-comment.
  - [x] 7.4: `applyDurationHintBarCounts(durationSeconds:minFileSeconds:)` — threshold guard added; tests pass `minFileSeconds: 0` to bypass.
  - [x] 7.5: `applyDurationHint(...)` accepts/forwards `minFileSeconds`; step 9.7 wiring updated.
  - [x] 7.6: `AudioAnalysisService.analyzeBPM` propagates `options.durationHintMinFileSeconds`.
  - [x] 7.7: Existing tests at D=240 still pass; AC #7 test passes `minFileSeconds: 0`. Added `durationHintRespectsThreshold` and `durationHintThresholdSuppressionWritesTrace`.
  - [x] 7.8: Re-ran corpora — both pass AC #4 floors. GiantSteps with hint=true matches baseline EXACTLY because all clips < 180s.
  - [x] 7.9: Re-ran `make duration-impact-report` — changedFinalBPM stays 0 on OA300.

- [x] Task 6: Update CLAUDE.md and gating checklist
  - [x] 6.1: `CLAUDE.md` `BPMAnalyzer` description now includes step 9.7 with the threshold note.
  - [x] 6.2: `make fmt` — clean.
  - [x] 6.3: `make lint` — only the pre-existing `LUFSAnalyzer.swift:94` TODO (acceptable per Story 3-3 close-out). No new warnings.
  - [x] 6.4: `make test` — 202 tests in 56 suites pass.
  - [x] 6.5: Final metrics recorded in Completion Notes below.

### Review Findings

Code review run via parallel Codex (gpt-5.5) layers — Blind Hunter, Edge Case Hunter, Acceptance Auditor — on 2026-04-28. 11 patch items, 2 deferred, 0 decision-needed, 0 dismissed.

#### Patch — medium severity

- [x] [Review][Patch] No-op duration hint can reorder candidates — `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2185-2192` — `applyDurationHint` always sorts by `(newScore, offset)` even when zero candidates were boosted. AC #3 contract says "the original `candidates` array flows unchanged into `resolveOctaveAmbiguity`" — re-sorting an unsorted input violates this. Fix: track `anyMatched`; if false, skip sort and return `candidates` verbatim. (source: blind)

- [x] [Review][Patch] Non-finite candidate scores break the sort tiebreaker — `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2185-2192` — `lhs.newScore != rhs.newScore ? lhs.newScore > rhs.newScore : lhs.offset < rhs.offset` is non-deterministic when either side is `NaN` (`NaN != x` is true but `NaN > x` is false, so the offset tiebreaker never runs). `+Inf` after `* 1.1` overflow produces an unbeatable rank. Fix: sanitize non-finite scores to a sentinel (or branch on `isFinite` before reaching the comparator). (source: edge)

- [x] [Review][Patch] `+Inf` file duration leaks past the service-level gate — `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:179` — `.flatMap { $0 > 0 ? $0 : nil }` admits `+Inf` because `+Inf > 0`. The hint helper then runs with a non-finite duration string in the trace. Fix: change to `.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }`. (source: edge)

#### Patch — low severity

- [x] [Review][Patch] Duration impact-report counts use exact float `!=` — `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift:642` — `if p.finalBPMHintOff != p.finalBPMHintOn { changedFinalBPM += 1 }` (and the two siblings). Float representation noise can inflate the counts. Fix: use the project's 2% tolerance policy or a small epsilon for "changed" comparison. (source: blind)

- [x] [Review][Patch] `PCMBufferReader.fileDuration(url:)` can return non-finite seconds — `Sources/BoomBoomBoomKit/PCMBufferReader.swift:145` — `Double(file.length) / file.processingFormat.sampleRate` returns `inf`/`nan` if `sampleRate == 0` for malformed metadata. The helper is `public` and contracted to return seconds. Fix: validate `sampleRate.isFinite && sampleRate > 0`, throw `PCMBufferReaderError.fileNotReadable(url)` (or a new case) on failure. (source: edge)

- [x] [Review][Patch] `durationHintMinFileSeconds` does not validate input — `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:2103` — `guard durationSeconds >= minFileSeconds else { return [] }`. `NaN` makes the comparison false, suppressing all hints silently; negative values make the hint run for short clips contrary to the option's documented intent. Fix: clamp at the AudioAnalysisService boundary (reject NaN/Inf, clamp negatives to `0` or restore the default). (source: edge)

- [x] [Review][Patch] No NaN/Inf boundary tests — `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` — no coverage for non-finite candidate scores, non-finite duration, or invalid threshold values. Tied to the four edge findings above. Fix: add focused unit tests for each. (source: edge)

#### Patch — nit (documentation / test fidelity)

- [x] [Review][Patch] Stale File List entry contradicts Task 7 outcome — `_bmad-output/implementation-artifacts/3-4-duration-derived-bpm-hint.md:416` — File List says the GiantSteps default-intensity floor "FAILS with hint on" but Completion Notes (line 363) document Task 7 restored GiantSteps to baseline EXACTLY. Fix: update the File List line to reflect the post-Task-7 result. (source: blind+auditor)

- [x] [Review][Patch] Original AC #2 / DD #5 wording does not reflect Task 7 threshold — `_bmad-output/implementation-artifacts/3-4-duration-derived-bpm-hint.md` (DD #5 worked example "60 s track → 32=128 BPM in range"; AC #2 "for `bars ∈ [32, 64, 96, 128, 192, 256]`") — the default behavior now suppresses these examples below 180s. Fix: cross-reference Task 7 amendment in DD #5 and AC #2 (or add a note that the literal worked examples assume `minFileSeconds: 0`). (source: auditor)

- [x] [Review][Patch] AC #3c test exercises threshold suppression rather than pure range filter — `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` (the 5s graceful no-op test) — uses the default 180s threshold, so the empty `barCandidates` come from threshold short-circuit, not from the `60...200` range filter that AC #3c documents. Fix: pass `minFileSeconds: 0` so the test exercises the documented path. (source: auditor)

- [x] [Review][Patch] AC #9 smoke test asserts `"128"` substring instead of spec-mandated `"128.0"` — `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:470-471` — implementation formats as `"128.0"` so behavior is correct, but the test allows `"1280"`, `"128X"`, etc. Fix: tighten to `"128.0"`. (source: auditor)

#### Deferred — pre-existing or accepted by spec

- [x] [Review][Defer] TOCTOU race between `fileDuration` and `readMonoSamples` — `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:179` — two `AVAudioFile(forReading:)` opens between which the file could be replaced. Accepted by DD #9 ("Two opens per `analyzeBPM` call instead of one is acceptable"). The race window is sub-millisecond on local files. Tracked in deferred-work.md. (source: edge)

- [x] [Review][Defer] Bar-count candidates recomputed once per window — `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:363` — multi-window analysis re-derives the same `barCandidates` per window (≤ 6 divisions). Sub-1% perf impact at intensity 6+. Hoist to AudioAnalysisService when a future story makes the cost meaningful. Tracked in deferred-work.md. (source: edge)



### Architecture context

- **ADR-11 (Options-first public configuration)** governs the placement of `durationHint`. Per `_bmad-output/planning-artifacts/architecture.md:247-258`: "All optional or defaulted configuration for public service methods MUST be passed via a single `Options` struct parameter." The Bool-with-default shape (`durationHint: Bool = true`) matches the "Non-optional `T = .default`" pattern (alongside `intensity`, `mergeStrategy`, `maxSeconds`, `enableTrace`). NOT an opt-in optional like `techniqueSet?` or `mlTechnique?` — those carry "feature inactive" semantics via nil; `durationHint: false` is an explicit "feature off" that still does work (skip the metadata read).
- **Why NOT a `DSPTechnique` case (per epic)**: the epic explicitly carves out an exception to the architecture rule "every accuracy-affecting change must be ablation-testable" because the duration hint operates at a different granularity than DSP techniques (file-level metadata vs window-level signal processing). The 128-combination ablation matrix tracks gating combinations of in-pipeline techniques; duration is a sidecar input to step 10 disambiguation. Validation gate is the four-floor regression `#expect` in AC #4 (OA300 + GiantSteps × Acc1 + Acc2), NOT ablation.
- **Why default-on (`true`)**: brainstorm #35 explicitly frames duration as a "free signal, zero PCM cost". The cost is one `AVAudioFile(forReading:)` open per `analyzeBPM` call (sub-millisecond) plus ~18 float comparisons per window. AC #4's regression gate ensures the boost cannot decrease accuracy. Default-off would mean every consumer needs to opt in to a useful free signal — anti-pattern for a library that prioritizes accuracy.
- **Pipeline composition with click rescore (Story 3-3)**: click rescore at step 9.5 produces `rescoredCandidates`; duration hint at step 9.7 takes those rescored candidates as input and produces `hintedCandidates`. The two compose in series, not in parallel. Click rescore can damp a candidate to ~70% of its original score (α=0.7 default); duration hint can boost a candidate by 10%. Worst case for a hint+click interaction: click damps to 0.7× then duration boosts to 0.77× — still below the original score. Best case: click leaves at 1.0× and duration boosts to 1.1× — net +10%. The composition is well-defined.
- **Impact reach (DD#12 caveat)**: `resolveOctaveAmbiguity`'s sub-band voting branch (BPMAnalyzer.swift:1518-1524) and step 10b's `confirmWithSubBandPeaks` (line 1586+) are score-blind — they decide on sub-band ACF evidence, not candidate scores. Boosting a candidate's score does NOT influence those branches. Task 5.5 measures the actual reach empirically. If `changedFinalBPM == 0` on OA300, the technique is functionally inert at the default intensity — Completion Notes must document this honestly (per Story 3-3 close-out precedent).

### Code-review precedents to honor

From Story 3-3 and Story 3-3a close-outs:

- **Path/line-number citations in code comments must be precise (3-3a Patch from D2)**: any cross-file reference must use the explicit relative path, not bare `architecture.md` (two `architecture.md` files exist; only `_bmad-output/planning-artifacts/architecture.md` has the ADRs). When citing ADR-11 in a doc-comment, use the explicit path.
- **`@testable import` for internal helpers (3-3 DD#5)**: `applyDurationHint` and `applyDurationHintBarCounts` must be `internal static`, not `private static`, so the unit tests can call them directly. Same access pattern as `subBandVote` (BPMAnalyzer.swift:1433) and `clickRescore` (BPMAnalyzer.swift:1891).
- **Trace-key collision on `%.1f` rounding (3-3 deferred-work)**: known cross-cutting issue. `durationHintDetail` uses the same `String(format: "%.1f", bpm)` formatting for consistency. The cross-cutting fix is out of scope; this story does not introduce a new collision class — it adds another instance of the existing pattern. Document the choice in the trace doc-comment.
- **CLAUDE.md "implicit nil" rule**: `BPMAnalyzer.Options.fileDurationSeconds: Double?` — DO NOT write `= nil`. Swift defaults optionals to nil; the explicit `= nil` is redundant per project-context.md.
- **CLAUDE.md "Options struct pattern"**: any new tunables go on the appropriate Options struct (`AudioAnalysisService.Options` for the public-facing Bool, `BPMAnalyzer.Options` for the internal Double?). Do NOT add positional parameters to `analyzeBPM` or `estimateBPM`.
- **TDD discipline (Story 3-3 Task 2.4)**: write the AC #6 + AC #7 + AC #8 unit tests BEFORE wiring the helpers into `estimateBPM` and `AudioAnalysisService`. The tests must compile against the new helper signatures first.

### Files to touch

- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` — add `fileDuration(url:)` public helper (Task 1)
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — add constants, `applyDurationHintBarCounts`, `applyDurationHint`, `Options.fileDurationSeconds`, step 9.7 wiring (Tasks 2, 3)
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — add `durationHintDetail: [String: String]?` field (Task 2.4)
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — add `Options.durationHint`, wire metadata read and pass-through (Task 4)
- `Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift` — extend with `PCMBufferReaderFileDurationTests` suite (Task 1.3)
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` (NEW) — `DurationHintHelperTests` and `DurationHintIntegrationTests` suites (Tasks 2.5, 3.4)
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — extend with `AudioAnalysisServiceDurationHintTests` suite (Task 4.5)
- `Tests/BoomBoomBoomKitBenchmarkTests/` — new env-gated `DurationImpactBenchmarkTests.swift` (or extend an existing benchmark file) for the impact report (Task 5.5)
- `Makefile` — add `duration-impact-report` target adjacent to the existing `click-impact-report` target at lines 84-92 (Task 5.5)
- `CLAUDE.md` — update `BPMAnalyzer` description to include step 9.7 (Task 6.1)

### Files NOT to touch

- `DSPTechnique.swift` — the duration hint is NOT a `DSPTechnique` case (DD#1)
- `TechniqueSet.swift` (in `DSPTechnique.swift`) — no preset changes
- `AnalysisIntensity.swift` — no intensity-mapping changes (the hint is on for ALL intensities when `durationHint: true`)
- `CandidateMergeStrategy.swift` — the hint operates within a window; multi-window merge is unchanged
- `README.md` — defer mention to Story 5.5 (DX docs)

### Performance expectations

- `PCMBufferReader.fileDuration(url:)` opens an `AVAudioFile` and reads `length`/`processingFormat.sampleRate`. On local SSD with cached metadata: ~50-200 microseconds. On first-touch cold filesystem: ~1-5 ms. Acceptable: runs once per `analyzeBPM(url:options:)` call, dwarfed by multi-second analysis.
- `applyDurationHintBarCounts`: 6 floating-point divisions and 6 range comparisons. Negligible.
- `applyDurationHint`: up to `numCandidates × numBarCandidates` (≤ 3 × 6 = 18) comparisons per window. Negligible.
- Per-window cost increment: < 0.1% of the existing pipeline. Per-call cost increment: ≤ 5 ms (one cold-cache file open). Expect `make perf-benchmark` delta < 1% on warm-cache repeat runs.

### Test fixture access

- `generateClickTrack(bpm:sampleRate:durationSeconds:)` from `BoomBoomBoomKitTestSupport` (already in scope across the test suites — see `BPMAnalyzerTests.swift:23`, `BPMAnalyzerClickTrackTests.swift:360`).
- `createClickTrackWAV(bpm:sampleRate:durationSeconds:url:)` is currently a **private** helper in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:442`. Two paths to use it from `PCMBufferReaderTests.swift` and `BPMAnalyzerDurationHintTests.swift`:
  - **Option A (recommended for this story)**: duplicate the helper into the new test files — zero cross-file impact, matches the existing duplication pattern. Add a one-line comment marking the duplication for future consolidation.
  - **Option B (defer)**: promote `createClickTrackWAV` to TestSupport — cross-cutting refactor, would touch multiple existing test files. Out of scope; if a reviewer requests this, defer to a follow-up hygiene story.

### References

- Epic AC: `_bmad-output/planning-artifacts/epics.md:586-612` (Story 3.4)
- ADR-11 (Options-first public configuration): `_bmad-output/planning-artifacts/architecture.md:247-258`
- Pipeline architecture (10-step description with click rescore at 9.5): `CLAUDE.md` `BPMAnalyzer` description line
- Story 3-3 close-out (precedent for click rescore at step 9.5, sort tiebreaker, internal helper visibility): `_bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md`
- Story 3-3a close-out (precedent for ADR-11 Options field, path-citation discipline): `_bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md`
- Brainstorm #35 (Splice.com duration-derived BPM hint): `_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md:206-207`
- Brainstorm #33 (duration + tag cross-validation, related to Story 3-6): `_bmad-output/brainstorming/brainstorming-session-2026-03-21-2345.md:209-210`
- Project context (Options struct pattern, implicit nil rule, vDSP wrapping rules): `_bmad-output/project-context.md`
- BPMAnalyzer pipeline insertion point (between `rescoredCandidates` and `resolveOctaveAmbiguity`): `Sources/BoomBoomBoomKit/BPMAnalyzer.swift:281-305`
- PCMBufferReader's existing AVAudioFile-open pattern (mirror for `fileDuration`): `Sources/BoomBoomBoomKit/PCMBufferReader.swift:43-50`
- `click-impact-report` Makefile target precedent (mirror for `duration-impact-report`): `Makefile:84-92`

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Code) on 2026-04-27

### Debug Log References

#### HALT — AC #4 GiantSteps regression at spec-literal hint values

After implementing Tasks 1-4 (helper, trace field, BPMAnalyzer wiring, AudioAnalysisService wiring) plus Task 5.0/5.4/5.5 plumbing, the corpus benchmarks produced this empirical picture:

**OA300 @ default intensity 7, durationHint=true (default):**
- Acc1: 57/82 (69.5%) — matches baseline (Story 3-3a Completion Notes)
- Acc2: 73/82 (89.0%) — matches baseline
- AC #4 OA300 floors: PASS

**OA300 duration-impact-report at `.optimal` (click inactive):**
- changedRanking: 0
- changedDisambiguationWinner: 0
- changedFinalBPM: 0
- Tracks analyzed: 82 / 82
- File: `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json`
- **Conclusion**: hint is FUNCTIONALLY INERT on OA300 — never changes the final BPM. No "insurance benefit" observed.

**OA300 @ default intensity 7, durationHint=false (AC #5 control):**
- Acc1: 57/82 EXACTLY
- Acc2: 73/82 EXACTLY
- AC #5 OA300 control: PASS (no state leakage)

**GiantSteps @ default intensity 7, durationHint=true (default):**
- Acc1: 536/661 (81.1%) — REGRESSED by 1 vs baseline 537
- Acc2: 544/661 (82.3%) — REGRESSED by 2 vs baseline 546
- **AC #4 GiantSteps floors: FAIL** (`>= 537` Acc1, `>= 546` Acc2)

**GiantSteps @ default intensity 7, durationHint=false (AC #5 control):**
- Acc1: 537/661 EXACTLY
- Acc2: 546/661 EXACTLY
- AC #5 GiantSteps control: PASS

#### Diagnosis

The empirical data inverts the story's "cheap insurance" framing:
- OA300: zero impact (no benefit available — DD#12 caveat realized: score-blind disambiguation paths swallow the boost)
- GiantSteps: net-negative impact (-1 Acc1, -2 Acc2 — the hint actively hurts on EDM-heavy material)

The DD#12 caveat anticipated `changedFinalBPM == 0` ("functionally inert — defer the call to the user"). What we have is worse: inert on OA300 and net-negative on GiantSteps. The story's premise that the hint is "free signal, zero PCM cost" with a no-regression gate (AC #4) holds the cost side correct (zero PCM cost confirmed) but fails the benefit side (no benefit measured) and breaches the regression gate (Acc1/Acc2 both drop on GiantSteps).

#### Possible paths forward (require user decision)

1. **Change default to `durationHint: false`.** Update AC #1 doc-comment to reflect empirical inertness/regression. AC #4 floor `#expect`s become trivially satisfied (default-off path bypasses the hint). Story ships with the technique behind an opt-in flag plus honest Completion Notes that the hint did not net-positive on either corpus at spec-literal values.
2. **Reduce `durationHintBoostWeight` (e.g., 0.1 → 0.05) and/or tighten `durationHintTolerance` (2% → 1%).** Re-run benchmarks. If the conservative values recover the AC #4 floor, ship with the conservative defaults and document the deviation from spec-literal values. Risk: smaller boost may not flip the GiantSteps regression cleanly because the score-blind paths dominate either way.
3. **Drop bar count `32` (and possibly `256`).** The 32-bar count only contributes for tracks ≤ 80s where music structure is partial — likely the source of half-tempo octave-boosting. Re-run benchmarks. Risk: same as #2 — may not be enough to move the needle.
4. **Withdraw the story / move to backlog.** The empirical evidence does not support shipping the technique even as default-off, since it provides no measured benefit on either corpus.
5. **Lower the AC #4 GiantSteps floor in the story spec** (e.g., `>= 535` Acc1, `>= 543` Acc2). Accept the regression as the price of the hint's structural-corroboration property. Requires explicit spec amendment by the user.

The story explicitly defers the inertness call ("keep the default `durationHint: true` for cheap insurance OR change to `false` and document the inertness — defer the call to the user during code review") but does NOT pre-authorize accepting a regression. Halting per Step 7 ("STOP and fix before continuing — identify breaking changes immediately") to surface the finding before either retrying with conservative hyperparameters or recommending Path #1 / #4.

### Completion Notes List

#### Final corpus metrics

- **OA300 default intensity 7, durationHint=true (default)**: Acc1=57/82 (69.5%), Acc2=73/82 (89.0%) — matches Story 3-3a baseline.
- **OA300 default intensity 7, durationHint=false (AC #5 control)**: Acc1=57/82, Acc2=73/82 EXACTLY — confirms no state leakage.
- **GiantSteps default intensity 7, durationHint=true (default)**: Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — matches baseline (because all GiantSteps clips are < 180s and the threshold suppresses the hint corpus-wide).
- **GiantSteps default intensity 7, durationHint=false (AC #5 control)**: Acc1=537/661, Acc2=546/661 EXACTLY.
- **DAW oracle (`make oracle`)**: PASS — Icicle stays within 2% Acc1; no DAW oracle track flips from in-tolerance to out.
- **Perf-benchmark**: mean 0.175s vs prior 0.172s (+1.6%, well under the 5% threshold). Baseline file: `_bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260428T043702Z--f0c5b9e--995f3b83.json`.
- **Duration-impact-report (OA300, .optimal, click inactive)**: `{changedRanking: 0, changedDisambiguationWinner: 0, changedFinalBPM: 0, total: 82, analyzed: 82, failed: 0, intensity: "default", techniqueSet: "optimal"}` — emitted to `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json`.
- **`make test`**: all 202 tests in 56 suites pass.

#### Honest acknowledgment of inertness (DD#12 caveat)

The duration-impact-report shows `changedFinalBPM == 0` on OA300. The technique is **functionally inert at the default intensity** on the OA300 corpus — the score-blind disambiguation paths (sub-band voting at BPMAnalyzer.swift:1518-1524, `confirmWithSubBandPeaks` at 1586+) decide on sub-band ACF evidence, not candidate scores, so the duration boost cannot influence the final winner on tracks where those branches are active.

Per the story spec's deferral language: **"keep the default `durationHint: true` for cheap insurance OR change to `false` and document the inertness — defer the call to the user during code review."** The empirical recommendation: keep default-on (the cost is sub-millisecond per call and the implementation provides a structurally-sound foundation for future work that may exercise the boost more aggressively, e.g., a DSP path that consults candidate scores after disambiguation). The trace-instrumentation is preserved for diagnostic value even when the boost is inert.

#### Honest acknowledgment of the GiantSteps regression (resolved by Task 7)

Before the Task 7 minimum-duration threshold (180s default), the spec-literal hint values (`boostWeight=0.1`, `tolerance=0.02`, no threshold) caused a measured AC #4 regression on GiantSteps: Acc1=536/661 (-1 vs baseline), Acc2=544/661 (-2). Root cause: GiantSteps clips are 30-120s segments of full songs, so bar-count math produces structurally-implausible BPMs that occasionally reinforce octave errors. Task 7 added `durationHintMinFileSeconds` (default 180s = 3 min) to suppress the hint on clips/loops/previews — restoring GiantSteps to baseline 537/546 EXACTLY while preserving the hint's run on full-song OA300 tracks.

#### Per-track 1:1 baseline gap (Task 5.0 acknowledgment)

Per-track pre-implementation BPM snapshots were NOT captured to `_bmad-output/implementation-artifacts/3-4-pre-baseline-{oa300,giantsteps}.json` because the helper change (the `durationHint` parameter on `runBenchmark`) had already landed before the benchmarks ran. The aggregate-equality gate in AC #5 (OA300==57/73 EXACTLY, GiantSteps==537/546 EXACTLY) is the sole regression-safety control. Both pass. Task 5.4 byte-equality 1:1 verification is therefore not enforced; if a future story wants stricter regression evidence, it can capture per-track snapshots before merging.

#### Spec amendments (post-halt, user-authorized)

The user directed (2026-04-28) the addition of a configurable minimum-duration threshold after Story 3-4 was halted on the AC #4 GiantSteps regression. This amendment is documented as Task 7 above and added two public Options fields:

- `AudioAnalysisService.Options.durationHintMinFileSeconds: Double = 180`
- `BPMAnalyzer.Options.durationHintMinFileSeconds: Double` (internal pass-through; default = `durationHintMinFileSecondsDefault`)

Plus an internal constant (`durationHintMinFileSecondsDefault: Double = 180.0`) and updated helper signatures (`applyDurationHintBarCounts(durationSeconds:minFileSeconds:)` and `applyDurationHint(candidates:fileDurationSeconds:minFileSeconds:trace:)` with default values reading the constant). The Key Design Decisions section of this story (#1-#12) was authored before the empirical evidence was available; Task 7 is the post-halt resolution and should be considered the definitive design-decision-13 for this story.

#### Code Review Resolution (2026-04-28)

Code review run via three parallel Codex (gpt-5.5) layers — Blind Hunter, Edge Case Hunter, Acceptance Auditor. Outcome: 11 patches landed, 2 deferred to `_bmad-output/implementation-artifacts/deferred-work.md`, 0 decision-needed, 0 dismissed.

**Patches applied:**
1. `applyDurationHint` no-op guard — input order preserved when no candidate matched a bar BPM (`BPMAnalyzer.swift`).
2. Sort comparator demotes NaN scores below all real scores while keeping `+Inf` in normal IEEE 754 ordering; offset tiebreaker always fires on ties (`BPMAnalyzer.swift`).
3. `AudioAnalysisService` finiteness gate — `flatMap { $0.isFinite && $0 > 0 ? $0 : nil }` rejects `+Inf` / `NaN` durations before they reach `BPMAnalyzer`.
4. `AblationFullMatrixTests.swift` impact-report counters now use a 2 % tolerance helper (`bpmDiffers`) instead of exact `!=`.
5. `PCMBufferReader.fileDuration` validates `sampleRate.isFinite && sampleRate > 0`; throws `.fileNotReadable(url)` on malformed metadata.
6. `applyDurationHintBarCounts` normalises `minFileSeconds` — NaN/Inf falls back to the documented 180 s default; negative clamps to 0.
7. AC #3c 5 s no-op test passes `minFileSeconds: 0` so the empty bar list comes from the documented `60..200` range filter rather than threshold suppression.
8. AC #9 smoke asserts `boosted.contains("128.0")` instead of the looser `"128"` substring.
9. Stale GiantSteps File List entry rewritten to reflect Task 7's resolution.
10. DD #5 / AC #2 worked examples annotated with `minFileSeconds: 0` precondition (default 180 s threshold added in Task 7).

**Six new boundary tests (`BPMAnalyzerDurationHintTests.swift` and `PCMBufferReaderTests.swift`):**
- `durationHintNoMatchPreservesInputOrder` (Patch #1)
- `durationHintHandlesNaNCandidateScore` + `durationHintHandlesInfiniteCandidateScore` (Patch #2)
- `durationHintHandlesInfiniteFileDuration` (Patches #1, #3, #6 combined)
- `durationHintNaNThresholdFallsBackToDefault` + `durationHintNegativeThresholdClampsToZero` (Patch #6)
- `fileDurationThrowsOnZeroSampleRate` (Patch #5)

**Verification:**
- `make fmt` clean; `make lint` clean (only pre-existing `LUFSAnalyzer.swift:94` TODO).
- `make test` — 209 tests in 56 suites pass (was 202 before patches; +7 new boundary tests).
- `make benchmark` — OA300 Acc1=57/82 (69.5%), Acc2=73/82 (89.0%) — AC #4 floors hold.
- `make benchmark-giantsteps` — Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) — matches baseline EXACTLY.
- `make oracle` — DAW oracle pass; Icicle in tolerance.
- `make duration-impact-report` — `{changedRanking: 0, changedDisambiguationWinner: 0, changedFinalBPM: 0}` on OA300 (unchanged — patches are defensive / test-only).

**Deferred to `deferred-work.md`:**
- TOCTOU race between `fileDuration` and `readMonoSamples` (accepted by DD #9; sub-millisecond window).
- Bar-count candidates recomputed once per window (≤ 6 divisions per window; sub-1 % perf cost).

### Change Log

| Date       | Description                                                                                  |
|------------|----------------------------------------------------------------------------------------------|
| 2026-04-27 | Implemented Tasks 1-4 (PCMBufferReader.fileDuration, BPMAnalyzer helpers + step 9.7 wiring, AudioAnalysisService Options.durationHint). |
| 2026-04-27 | Tasks 5.0-5.6 ran; HALTED on AC #4 GiantSteps regression at spec-literal hint values (-1 Acc1, -2 Acc2). |
| 2026-04-28 | Task 7 added per user directive — configurable minimum-duration threshold (default 180s) suppresses the hint on clips/loops/previews. |
| 2026-04-28 | Re-ran corpora: both pass AC #4 floors; OA300 confirmed inert (`changedFinalBPM=0`); GiantSteps matches baseline EXACTLY. |
| 2026-04-28 | Updated CLAUDE.md, ran fmt/lint/test (202 tests pass), recorded final metrics in Completion Notes. Story marked review. |
| 2026-04-28 | Code-review patches applied (11 patches, 6 new boundary tests, 2 deferred); all corpora green; story closed. |

### File List

Implementation (Tasks 1-4 — code complete):
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` (modified) — added `public static func fileDuration(url:)`.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` (modified) — added 3 constants, `applyDurationHintBarCounts`, `applyDurationHint`, `Options.fileDurationSeconds`, step 9.7 wiring, BPMResult uses `hintedCandidates`.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (modified) — added `durationHintDetail: [String: String]?`.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (modified) — added `public var durationHint: Bool = true`, wired duration read, updated field-style convention doc-block.

Tests (Tasks 1-5 — complete and passing where applicable):
- `Tests/BoomBoomBoomKitTests/PCMBufferReaderTests.swift` (modified) — added `PCMBufferReaderFileDurationTests` suite (2 tests, both pass).
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerDurationHintTests.swift` (NEW) — `DurationHintHelperTests` (6 tests) + `DurationHintIntegrationTests` (2 tests). All pass.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (modified) — added `AudioAnalysisServiceDurationHintTests` suite (3 tests, all pass).
- `Tests/BoomBoomBoomKitBenchmarkTests/OA300BenchmarkTests.swift` (modified) — added `durationHint` parameter to `runBenchmark`, added Story 3-4 AC #4 floor citation, added `benchmarkDurationHintOptOut` test (passes).
- `Tests/BoomBoomBoomKitBenchmarkTests/GiantStepsBenchmarkTests.swift` (modified) — added `durationHint` parameter to `runBenchmark`, added `benchmarkDurationHintOptOut` test (passes). Pre-Task-7 the default-intensity `#expect` floor (`>= 537` Acc1) FAILED with hint on (-1 Acc1, -2 Acc2 vs baseline); Task 7's `durationHintMinFileSeconds = 180` default suppresses the hint corpus-wide (all GiantSteps clips < 180 s), restoring 537/546 EXACTLY.
- `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` (modified) — added `durationImpactReport` env-gated test (passes).
- `Makefile` (modified) — added `duration-impact-report` target.
