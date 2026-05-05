# Story 4.2: Effective Intensity and Graceful ML Degradation

Status: done
**Depends on:** Story 4.1 (`done` 2026-05-04, SHA `29ced70`) — `BoomBoomBoomKitML` package exists so the degradation message can name it accurately. No `MLTechnique` protocol changes required (Story 4.3 owns that refactor).
**Promotion gate:** non-regression (Epic 4 plumbing camp — see `epics.md` §"Definitions used in Epic 4 acceptance criteria"). Story 4.2 adds reporting fields and one query function; it does NOT move accuracy. The DnB-triplet ground-truth verification gates 4.3/4.5/4.6 only and does NOT block 4.2 promotion.

## Story

As an app developer integrating BoomBoomBoomKit,
I want `AudioAnalysisResult` to surface the effective DSP-level depth as a reported value (`effectiveIntensity`) plus an actionable explanation when ML-augmented intensities (8-10) silently fall back to DSP-only behaviour (`degradationReason`), and I want a query function (`maximumSupportedIntensity(mlTechnique:)`) to ask up-front whether ML-augmented intensities will work in my configuration,
So that I can decide whether to add the `BoomBoomBoomKitML` package, adjust my `Options.intensity`, or surface the degradation in my own UI — without inferring it from undocumented behaviour or silently shipping intensity 9 that quietly behaves like intensity 7.

## Key Design Decisions

The Project Lead reviews this block BEFORE dev begins. Each decision is load-bearing for at least one acceptance criterion or cross-story constraint.

1. **Reporting-only — no pipeline mutation.** `effectiveIntensity` is computed AFTER `runPreCorroborationPipeline` returns and AFTER `MetadataCorroborator.apply` returns; the pipeline runs with the user's requested intensity unchanged. Levels 8-10 currently delegate to level 7 behaviour in `AnalysisIntensity.techniqueSet`, `.windowSizes`, and `.progressiveThreshold` (switch `default:` arms at `AnalysisIntensity.swift:64,76,83`), so byte-identical BPM/confidence/candidates output is guaranteed *by construction* whether `effectiveIntensity` reports 7 or 9 — note this rests on a *behavioural coincidence* (the switch-default delegation), not on a principled invariant. Mutating the requested intensity inside the pipeline (e.g., "if mlTechnique nil, set options.intensity = .default before running") would be an architectural overreach that risks future-Story-4.5/4.6 regressions when level 8-10 actually diverge from level 7. **Forward-compatibility note:** the reporting-only architecture is intentionally forward-compatible with Stories 4.5/4.6 changing level 8-10 semantics — the pipeline continues to run at the requested intensity unchanged, and only the reporting layer reads the cap, so divergence at level 8-10 propagates naturally without touching the cap-and-report logic. The phrase "actually used" is avoided in normative text because a level-9-without-ML pipeline run is *technically still a level-9 run* (today indistinguishable from level-7 by switch coincidence); `effectiveIntensity` reports the *effective DSP-level depth*, not a literal claim about which switch arm executed.

2. **`degradationReason` is `String?` (per AC), not an enum.** AC #2's example string format is `"Requested intensity 9 requires BoomBoomBoomKitML package. Running at intensity 7 (DSP-only)."`. Pre-1.0 / no-BC framing (`project-context.md` §"Public API Discipline (pre-1.0)") allows a future promotion to a typed enum (`DegradationReason.mlPackageMissing(requested: AnalysisIntensity, effective: AnalysisIntensity)`) when a downstream consumer surfaces a parsing need — Story 4.2 ships the simplest shape that the AC names. Today there is exactly one degradation path (ML missing); promoting to an enum on speculation would be premature. **Consumer-guidance corollary:** consumers needing to BRANCH on degradation reason should call `maximumSupportedIntensity(mlTechnique:)` BEFORE analysis instead of string-parsing the message field — that's the supported pre-flight branching surface, and it's stable across pre-1.0 message-wording revisions. The `degradationReason` field is display-oriented (post-facto explanation for a UI string or log line), not control-flow-oriented. A deferred-work entry tracks the future enum promotion (see `deferred-work.md`).

3. **Hard-coded DSP-only ceiling = 7.** The "DSP-only max" is 7 (intensities 8-10 are reserved for ML, per `AnalysisIntensity.swift:16-17` doc-comment and `AnalysisIntensity.thorough = 8` / `.maximum = 10`). Story 4.2 introduces `private static let dspOnlyMaxIntensity: AnalysisIntensity = .default` (== 7) inside `AudioAnalysisService` as the single source of truth. Three call sites consume it: the cap in `analyzeBPM`, the message-builder helper, and `maximumSupportedIntensity(mlTechnique: nil)`. If a future story re-tunes the ceiling, all three move together.

4. **`maximumSupportedIntensity` is `public static func` on `AudioAnalysisService`.** AC #6's text says `public func` (no `static`); this is treated as an authorial slip — the function takes no `self` state and `AudioAnalysisService` is a stateless struct (matching `analyzeBPM`'s `public static func` shape at `AudioAnalysisService.swift:181,204`). Story 4.2 ships `public static func maximumSupportedIntensity(mlTechnique: (any MLTechnique)?) -> AnalysisIntensity`. Mirror the existing surface; record the AC-text fidelity correction in Change Log.

5. **`MockMLTechnique` already exists in the test target — reuse it.** `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397` defines a file-private `MockMLTechnique` conforming to the current labeled-tuple `MLTechnique` protocol. Story 4.2's `maximumSupportedIntensity` non-nil tests reuse this mock (extracting it to file-scope or a shared helper if needed by multiple suites). Do NOT promote a mock to `BoomBoomBoomKitTestSupport` in this story — Story 4.3 owns that promotion when the protocol is rewritten to the `MLEvaluation` Sendable struct shape (Story 4.3 AC #1 + DD note in epics.md). Promoting today against the current labeled-tuple shape would be doubly wasteful: we'd write it now, then rewrite in Story 4.3, then potentially relocate.

6. **`AudioAnalysisResult` synthesized memberwise init breaks — accept it.** Adding `effectiveIntensity: AnalysisIntensity` and `degradationReason: String?` to `AudioAnalysisResult` shifts the synthesized memberwise init shape. The single internal construction site is `AudioAnalysisService.swift:217-220` (the `AudioAnalysisResult(bpm:..., metadataEvidence:)` call inside `analyzeBPM`); update it to pass the two new fields. There are zero external memberwise-init call sites in `Sources/` or `Tests/` (`AudioAnalysisResult(` returns one match — the production site). Pre-1.0 / no-BC framing welcomes this kind of public-struct shape change. Document the diff scope in Tasks so review can verify the construction-level proof.

7. **Construction-level proof shifts from "no Sources/ diff" (Story 4.1) to "no DSP-touching diff in Sources/".** Story 4.1's construction-level proof was `git diff main..HEAD -- Sources/BoomBoomBoomKit/` returns empty. Story 4.2 modifies `AudioAnalysisService.swift`, so that exact form does not hold. The Story 4.2 form is: **(a)** `git diff <pre-story-SHA>..HEAD -- Sources/BoomBoomBoomKit/` returns changes ONLY in `AudioAnalysisService.swift`; **(b)** within that file, the diff hunks are confined to: the `AudioAnalysisResult` struct (two new fields), the `analyzeBPM(url:options:)` body (compute `effectiveIntensity` and `degradationReason` after `MetadataCorroborator.apply`, pass them into the result init), and the new `maximumSupportedIntensity` + private message-builder helpers; **(c)** the `runPreCorroborationPipeline` function body (lines 261-338) is **untouched** — DSP candidate computation does not see the new fields. The boundary-proof artifact captures this scope (see AC #7 + Task 6).

8. **Snapshot file precedent — lossy `%.1f` from existing benchmark stdout, snapshot_metadata header mandatory, defense-in-depth alongside construction-level proof.** Story 4.1 established the snapshot precedent (`4-1-regression-snapshot.json` at lossy precision plus construction-level proof as the load-bearing claim). Story 4.2 follows the same pattern: capture `4-2-regression-snapshot.json` BEFORE the first dev commit (at the post-Story-4.1 SHA `8c37d64` or whatever HEAD is at story-start), reuse the existing benchmark stdout — no `Tests/` modification (still binding from AC #11 below). The snapshot is defense-in-depth; the byte-identical claim rests on the construction-level proof (DD #7).

9. **No `@available` annotations on the new public surface.** The package floor is `[.macOS(.v15)]` (`Package.swift:6`); the new fields/function are pure Foundation/Swift types. `@available(macOS 15, *)` would be redundant and would create a `@available`-cascade obligation across the rest of `AudioAnalysisService` for visual symmetry. Skip it.

10. **`degradationReason` message must NOT include implementation-internal details (DSP technique names, candidate counts, ablation flags, etc.).** The message is end-developer-facing — it tells a SwiftUI app developer what to do. Format: `"Requested intensity \(requested) requires BoomBoomBoomKitML package. Running at intensity \(effective) (DSP-only)."` where `requested` and `effective` use the integer `rawValue` (NOT the named-constant string, which would leak `.thorough`/`.maximum` into the message). The current package name (`BoomBoomBoomKitML`) is hard-coded in the message — if it is ever renamed, this message updates with it. **Exact-string contract scope:** the literal string above is the contract for Story 4.2's regression-test assertions (AC #3) — it is NOT a stable consumer-facing API. Pre-1.0 / no-BC framing accepts message-wording revision in a future story without breaking SemVer rules. Consumers must treat `degradationReason` as display text and use `maximumSupportedIntensity(mlTechnique:)` for control flow (per DD #2 consumer-guidance corollary). When the message format is revised, the regression test assertion updates with it; no consumer-side breakage because there should be no consumer-side string parsing.

## Background

Epic 4 introduces the `BoomBoomBoomKitML` package as an opt-in extension surface for ML-augmented BPM detection. Story 4.1 (`done`, SHA `29ced70`) shipped the package scaffolding — `Sources/BoomBoomBoomKitML/` with `BNNSTechnique.swift` + `CoreMLTechnique.swift` placeholders that do NOT conform to `MLTechnique` yet (per Story 4.1 DD #1; conformance lands in Story 4.5/4.6 against the post-Story-4.3 protocol shape).

Today, a consumer who passes `intensity: .thorough` (== 8) or `intensity: .maximum` (== 10) to `AudioAnalysisService.analyzeBPM` gets DSP-only level-7 behaviour silently — `AnalysisIntensity.swift:36-40` says these levels are "reserved for future ML integration" and currently behave identically to `.default`. There is no signal in the result that the requested intensity was effectively downgraded, and no way to ask up-front whether ML-augmented intensities will be honoured in the current configuration.

Story 4.2 closes this gap with three additions:

1. `AudioAnalysisResult.effectiveIntensity: AnalysisIntensity` — the effective DSP-level depth reported back to the caller. For requests in 1-7, equals the requested. For requests in 8-10 with `mlTechnique: nil`, equals 7 (the DSP-only ceiling — see DD #1 for why this is reporting-only, not pipeline-mutation). For requests in 8-10 with non-nil `mlTechnique`, equals the requested.
2. `AudioAnalysisResult.degradationReason: String?` — actionable message when degradation occurred; `nil` otherwise.
3. `AudioAnalysisService.maximumSupportedIntensity(mlTechnique:) -> AnalysisIntensity` — pre-flight query: `7` when `nil`, `10` when non-nil.

Story 4.2 is in the Epic 4 "plumbing-only" camp (per `epics.md:760` planning decision 2026-05-04): a reporting-surface story cannot move accuracy. The non-regression gate is the success criterion — `bpm`, `confidence`, and per-element `candidates` are byte-identical to a snapshot captured BEFORE the first dev commit (Epic 4 Definitions' named scope, `epics.md:766`); `trace` and `metadataEvidence` are unchanged-by-construction (per DD #7 diff scope; not in the snapshot artifact). See `epics.md:855-861` Non-regression gate text + the Story 4.1 snapshot precedent.

The architecture shift relative to Story 4.1: Story 4.1 made zero changes to `Sources/BoomBoomBoomKit/`, so its construction-level proof was `git diff` returning empty. Story 4.2 modifies `AudioAnalysisService.swift` — the construction-level proof tightens to "diff scope is confined to non-DSP surface" (DD #7). The snapshot becomes defense-in-depth.

The `MLTechnique` protocol at `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` still uses labeled tuples (Story 4.3 will rewrite it). Story 4.2 does NOT touch this file — `maximumSupportedIntensity(mlTechnique: (any MLTechnique)?)` accepts the protocol type as-is. When Story 4.3 lands the `MLEvaluation` Sendable struct shape, the function signature is unchanged because `(any MLTechnique)?` continues to refer to whatever the protocol shape happens to be.

## Acceptance Criteria

1. **Given** the public `AudioAnalysisResult` struct in `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-28`
   **When** Story 4.2 ships
   **Then** the struct has two new public stored properties added AFTER the existing `metadataEvidence` field (preserving the `bpm, confidence, candidates, trace, metadataEvidence` ordering of pre-existing fields):
   - `public let effectiveIntensity: AnalysisIntensity`
   - `public let degradationReason: String?`
   **And** both fields are `Sendable` (transitively — `AnalysisIntensity` already `Sendable`; `String` already `Sendable`)
   **And** both fields have `///` doc-comments explaining their semantics with a one-sentence note on when each is non-nil (`degradationReason`) or how it relates to `Options.intensity` (`effectiveIntensity`)

2. **Given** `Options.intensity` set to a value in 1-7 (DSP-only range — `.fastest` (1), `.default` (7), or any in-between)
   **When** `analyzeBPM(url:options:)` returns a non-nil result
   **Then** `result.effectiveIntensity == options.intensity`
   **And** `result.degradationReason == nil`
   **And** this holds whether `options.mlTechnique` is `nil` or a non-nil conformance (intensity 1-7 never engages ML, regardless of mlTechnique presence — see DD #1)

3. **Given** `Options.intensity` set to a value in 8-10 (`.thorough` (8), 9, or `.maximum` (10)) AND `Options.mlTechnique == nil`
   **When** `analyzeBPM(url:options:)` returns a non-nil result
   **Then** `result.effectiveIntensity == .default` (== `AnalysisIntensity(rawValue: 7)`)
   **And** `result.degradationReason` is non-nil and exactly equal to `"Requested intensity \(options.intensity.rawValue) requires BoomBoomBoomKitML package. Running at intensity 7 (DSP-only)."`
   **And** the message uses the integer `rawValue` of the requested intensity (e.g., `9` for `AnalysisIntensity(rawValue: 9)`, `10` for `.maximum`), NOT the named-constant string

4. **Given** `Options.intensity` set to a value in 8-10 AND `Options.mlTechnique` set to a non-nil conformance (test-target `MockMLTechnique` reused per DD #5)
   **When** `analyzeBPM(url:options:)` returns a non-nil result
   **Then** `result.effectiveIntensity == options.intensity`
   **And** `result.degradationReason == nil`

5. **Given** `Options.intensity` set to a value in 8-10 AND `Options.mlTechnique == nil`, with the analysis run on the same fixture twice (one call without and one call with the new fields read from the result)
   **When** the per-track BPM result is captured both times
   **Then** `result.bpm`, `result.confidence`, and per-element fields of `result.candidates` are byte-identical between the two runs and to the pre-Story-4.2 snapshot — this is the named scope of byte-identity per Epic 4 Definitions (`epics.md:766` — "Double.bitPattern equality on bpm and confidence, element-wise on candidates")
   **And** `result.trace` and `result.metadataEvidence` are unchanged-by-construction (the pipeline code that builds them is bypass-untouched per DD #7 diff scope; they are NOT in the snapshot-comparison surface because the lossy `%.1f` snapshot artifact does not serialize them) — this is a *static* construction-level claim, not a snapshot-comparison claim
   **And** the new fields (`effectiveIntensity`, `degradationReason`) do NOT influence any pre-existing field — they are pure post-pipeline reporting (see DD #1 and DD #7)

6. **Given** a new public function on `AudioAnalysisService`
   **When** Story 4.2 ships
   **Then** the function exists with signature exactly:
   ```swift
   /// Maximum analysis intensity supported by the current configuration.
   ///
   /// - Parameter mlTechnique: The ML technique that will be supplied via
   ///   ``Options/mlTechnique`` — pass `nil` to ask "what's the ceiling without
   ///   the BoomBoomBoomKitML package?" or pass a real conformance to ask
   ///   "what's the ceiling with my chosen ML model?"
   /// - Returns: ``AnalysisIntensity/default`` (7) when `mlTechnique` is `nil`;
   ///   ``AnalysisIntensity/maximum`` (10) when non-nil.
   public static func maximumSupportedIntensity(
     mlTechnique: (any MLTechnique)?
   ) -> AnalysisIntensity
   ```
   **And** `maximumSupportedIntensity(mlTechnique: nil) == AnalysisIntensity(rawValue: 7)` (== `.default`)
   **And** `maximumSupportedIntensity(mlTechnique: MockMLTechnique()) == AnalysisIntensity(rawValue: 10)` (== `.maximum`)
   **And** the function is `public static` (per DD #4 — the AC text in `epics.md:847` says `public func`; treated as authorial slip and reconciled to mirror `analyzeBPM`'s `public static func` shape — Change Log entry documents the reconciliation)

7. **Given** the diff scope of Story 4.2
   **When** captured at PR time as the boundary-proof artifact at `_bmad-output/implementation-artifacts/4-2-diff-scope-proof.txt`
   **Then** the artifact contains:
   - `# Section: git diff --stat <pre-story-SHA>..HEAD` — output showing exactly the expected modified files: `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` (modified), `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (modified, additions only — verify via `git diff --numstat` showing zero deletions of pre-existing test code), plus the story file + sprint-status. ZERO modifications to `BPMAnalyzer.swift`, `AnalysisIntensity.swift`, `MetadataCorroborator.swift`, `BPMDiagnosticTrace.swift`, `CandidateMergeStrategy.swift`, or any other file under `Sources/BoomBoomBoomKit/`.
   - `# Section: git diff Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — full diff showing modifications confined to: (a) the `AudioAnalysisResult` struct (two new field declarations + their doc-comments), (b) the body of `public static func analyzeBPM(url:options:)` (compute `effectiveIntensity` + `degradationReason` post-`MetadataCorroborator.apply`, pass them into the result init), (c) net-additions for the new `public static func maximumSupportedIntensity` + any private helper. ZERO modifications inside `runPreCorroborationPipeline(url:options:)` (lines 261-338 in pre-Story-4.2 SHA — line numbers will shift after edits).
   - `# Section: grep -n 'AudioAnalysisResult(' Sources/ Tests/` — output showing the single production construction site at `AudioAnalysisService.swift:217` (line number may shift) and zero new construction sites in `Tests/`. (If the dev refactors the construction call into a helper, document it in Completion Notes.)
   **And** Completion Notes link to this artifact

8. **Given** the Story 4.2 non-regression gate per Epic 4 Definitions (`epics.md:767`)
   **When** `make benchmark` and `make benchmark-giantsteps` run pre-merge
   **Then** all four asserted floors hold strict-equality:
   - OA300 Acc1 ≥ 57/82 (`OA300BenchmarkTests.swift:105,109`)
   - OA300 Acc2 ≥ 73/82 (`OA300BenchmarkTests.swift:130,134`)
   - GiantSteps Acc1 ≥ 537/661 (`GiantStepsBenchmarkTests.swift`)
   - GiantSteps Acc2 ≥ 546/661 (`GiantStepsBenchmarkTests.swift`)
   **And** per-track BPM JSON output is byte-identical to the pre-Story-4.2 snapshot at `_bmad-output/implementation-artifacts/4-2-regression-snapshot.json`:
   - Snapshot captured BEFORE the Story 4.2 first dev commit (preserves the comparison baseline)
   - Snapshot follows the Story 4.1 schema (lossy `%.1f` precision, `snapshot_metadata` header with `captured_at`, `captured_by`, `git_sha`, `macos_version`, `xcode_version`, `swift_version`; `corpus_runs[]` with `corpus`, `total`, `acc1Correct`, `acc2Correct`, `tracks_failure_subset[]`)
   - Diff-comparison at PR time excludes the `snapshot_metadata` block and operates only on `corpus_runs[*].tracks_failure_subset[*]`
   - Re-baseline policy: new toolchain → new snapshot file (`-rev2.json`), never silent overwrite (Story 4.1 precedent)
   - Byte-identical defined per Epic 4 Definitions (`epics.md:766` — "Double.bitPattern equality on bpm and confidence, element-wise on candidates"): the snapshot-comparison surface is `bpm`, `confidence`, and per-element fields of `candidates`. `trace` and `metadataEvidence` are unchanged-by-construction (the pipeline code that builds them is bypass-untouched per DD #7) but are NOT in the snapshot artifact (lossy `%.1f` schema does not serialize them) — their unchanged-ness is a static diff-scope claim, not a snapshot-derived claim. The two NEW fields (`effectiveIntensity`, `degradationReason`) are NOT in the snapshot scope (they did not exist pre-story).
   **And** Completion Notes record the live snapshot numbers AND link to BOTH the snapshot artifact and the diff-scope proof artifact

9. **Given** `make test` (the unit-test suite)
   **When** run pre-merge
   **Then** the full suite passes
   **And** Story 4.2 adds new `@Test(` declarations for: `effectiveIntensity` reflects requested 1-7 with no ML; `effectiveIntensity` reflects requested 1-7 with mock ML; `effectiveIntensity` capped at 7 for 8-10 without ML; `effectiveIntensity` reflects requested 8-10 with mock ML; `degradationReason` exact-string format for intensity 9 without ML; `degradationReason` exact-string format for intensity `.maximum` (10) without ML; `degradationReason` is nil for intensity 1-7; `degradationReason` is nil for 8-10 with mock ML; `maximumSupportedIntensity(nil) == .default`; `maximumSupportedIntensity(MockMLTechnique()) == .maximum`. Estimated 8-10 new `@Test(` declarations (no fewer than 8 — the AC scenarios above each map to at least one test; consolidation acceptable as long as every AC bullet is exercised)
   **And** existing tests are NOT modified except where the `MockMLTechnique` reuse pattern requires extracting it to file scope (e.g., from `private struct` inside one suite to file-private at the top of `AudioAnalysisServiceTests.swift`). Document any extraction in Completion Notes
   **And** the existing `mlTechniqueNonNilIsIgnoredPreStory43` test (`AudioAnalysisServiceTests.swift:421-438`) continues to pass without modification — its byte-identity assertion is on `bpm` and `confidence` only, which are unchanged

10. **Given** `make fmt` and `make lint`
    **When** run pre-merge
    **Then** `make fmt` produces no diff against the staged changes (formatter idempotent)
    **And** `make lint` reports only the pre-existing baseline (single TODO at `LUFSAnalyzer.swift:94`) — no new violations from the modifications to `AudioAnalysisService.swift` or the new tests

11. **Given** the `Tests/` directory invariant from Story 4.1 (no benchmark-side test code modifications for snapshot capture)
    **When** Story 4.2 captures its pre-story snapshot per AC #8
    **Then** the snapshot is captured by RUNNING the existing `make benchmark` + `make benchmark-giantsteps` and copy-pasting / scripting the failure-table stdout into the snapshot JSON — NOT by adding a new env-gated `@Test` to `BoomBoomBoomKitBenchmarkTests` (which would be a behavioural test surface change defeating the regression-protection invariant)
    **And** `git diff <pre-story-SHA>..HEAD -- Tests/BoomBoomBoomKitBenchmarkTests/` returns empty (no benchmark test target modifications in Story 4.2 — same constraint as Story 4.1 AC #8 / DD #5 family)

## Tasks / Subtasks

- [x] Task 1: Capture pre-Story-4.2 regression snapshot BEFORE first dev commit (AC: #8, #11)
  - [x] 1.1: Confirm the pre-story SHA (HEAD at story start). Record in Completion Notes. Verify clean working tree before snapshot.
  - [x] 1.2: Run `make benchmark` against `OA300_CORPUS_PATH`. Capture failure-table stdout (Acc1 + Acc2 sections). Record total/acc1Correct/acc2Correct in JSON.
  - [x] 1.3: Run `make benchmark-giantsteps` against `GIANTSTEPS_CORPUS_PATH`. Capture failure-table stdout (note: GiantSteps logger truncates to 30 visible failures of ~124 total — same precedent as Story 4.1, document `tracks_failure_subset_truncated_count` in the snapshot).
  - [x] 1.4: Save snapshot to `_bmad-output/implementation-artifacts/4-2-regression-snapshot.json` with mandatory `snapshot_metadata` header per Story 4.1 schema. Required keys: `captured_at` (ISO-8601), `captured_by` (`git config user.name`), `git_sha` (`git rev-parse --short HEAD` BEFORE first dev commit), `macos_version` (`sw_vers -productVersion`), `xcode_version` (`xcodebuild -version | head -1`), `swift_version` (`swift --version | head -1`).
  - [x] 1.5: JSON-validate via `python3 -m json.tool < <snapshot>` (zero-output success). Record headline numbers (OA300 Acc1=N/82, Acc2=N/82; GiantSteps Acc1=N/661, Acc2=N/661) in Completion Notes.

- [x] Task 2: Add the two new fields to `AudioAnalysisResult` (AC: #1)
  - [x] 2.1: In `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`, locate the `public struct AudioAnalysisResult: Sendable {` block (currently lines 13-28). Add `public let effectiveIntensity: AnalysisIntensity` and `public let degradationReason: String?` AFTER the existing `metadataEvidence` field. Preserve the field ordering of the pre-existing fields (`bpm, confidence, candidates, trace, metadataEvidence`).
  - [x] 2.2: Add `///` doc-comments. Suggested wording (dev may polish):
    - `effectiveIntensity`: "The effective DSP-level depth reported for this analysis. Equals ``Options/intensity`` for requests in 1-7 (DSP-only range) and for requests in 8-10 when ``Options/mlTechnique`` is non-nil. When intensity 8-10 is requested without an ``MLTechnique`` conformance, this is reported as ``AnalysisIntensity/default`` (7) and ``degradationReason`` carries the explanation. Note: today the pipeline runs at the requested intensity unchanged — levels 8-10 currently produce identical DSP output to level 7 by switch-default coincidence in ``AnalysisIntensity``; future stories may change level 8-10 semantics, in which case this field will continue to report what was effectively achieved."
    - `degradationReason`: "A display-oriented explanation when the requested intensity was not honoured (e.g., when 8-10 was requested but no ``MLTechnique`` conformance was supplied). `nil` when no degradation occurred. Today's message format is ``\"Requested intensity \\(requested) requires BoomBoomBoomKitML package. Running at intensity \\(effective) (DSP-only).\"`` — this exact text is asserted by Story 4.2's regression tests (AC #3), but consumers should treat it as display text; pre-1.0 / no-BC framing allows wording revision in a future story. **For control flow, do NOT string-parse this field — call ``AudioAnalysisService/maximumSupportedIntensity(mlTechnique:)`` BEFORE analysis to query whether the configuration supports the requested intensity.**"
  - [x] 2.3: Verify no other file in `Sources/` constructs `AudioAnalysisResult` (`grep -n 'AudioAnalysisResult(' Sources/`). Expected single match at the existing call site in `AudioAnalysisService.swift:217-220`.

- [x] Task 3: Wire `effectiveIntensity` + `degradationReason` computation in `analyzeBPM` (AC: #2, #3, #4)
  - [x] 3.1: Add a `private static let dspOnlyMaxIntensity: AnalysisIntensity = .default` constant on `AudioAnalysisService` (DD #3). Place near the top of the type, AFTER `Options` declaration, BEFORE `analyzeBPM(url:)` overload.
  - [x] 3.2: Add a `private static func computeEffectiveIntensity(requested: AnalysisIntensity, mlTechnique: (any MLTechnique)?) -> AnalysisIntensity` helper that returns: `requested` when `requested.rawValue <= dspOnlyMaxIntensity.rawValue`; `requested` when `mlTechnique != nil` (8-10 with ML supplied); `dspOnlyMaxIntensity` otherwise (8-10 with no ML).
  - [x] 3.3: Add a `private static func degradationMessage(requested: AnalysisIntensity, effective: AnalysisIntensity) -> String?` helper that returns `nil` when `requested == effective`; otherwise the exact format string from AC #3: `"Requested intensity \(requested.rawValue) requires BoomBoomBoomKitML package. Running at intensity \(effective.rawValue) (DSP-only)."`. Use `requested.rawValue` (Int), not the named-constant string (DD #10).
  - [x] 3.4: In `public static func analyzeBPM(url:options:)` (currently lines 204-221), AFTER `MetadataCorroborator.apply` returns and BEFORE constructing `AudioAnalysisResult`, compute `let effective = computeEffectiveIntensity(requested: options.intensity, mlTechnique: options.mlTechnique)` and `let reason = degradationMessage(requested: options.intensity, effective: effective)`. Pass these into the `AudioAnalysisResult(...)` initializer (which now takes seven positional args: `bpm, confidence, candidates, trace, metadataEvidence, effectiveIntensity, degradationReason`).
  - [x] 3.5: Verify the `runPreCorroborationPipeline` function body (currently lines 261-338) is UNTOUCHED — the new logic lives only in `analyzeBPM(url:options:)`. Run `git diff -U0 Sources/BoomBoomBoomKit/AudioAnalysisService.swift | grep -E '^\+\+\+|^@@'` to verify the affected hunks.
  - [x] 3.6: Verify `trace` and `metadataEvidence` construction/call wiring is untouched (closes the gap between AC #5 / #8 byte-identical scope and Task 3.5's DSP-only verification — these two fields are unchanged-by-construction, not byte-identical-to-snapshot, and that claim rests on the building code being bypass-untouched). Specifically: zero hunks in `runPreCorroborationPipeline`, zero hunks changing `BPMAnalyzer` trace construction (`Sources/BoomBoomBoomKit/BPMAnalyzer.swift` should have ZERO modifications), and zero hunks changing the `MetadataCorroborator.apply` invocation/result mapping at `AudioAnalysisService.swift:214-215` except for the addition of new positional fields to the `AudioAnalysisResult(...)` initializer at lines 217-220.

- [x] Task 4: Add `maximumSupportedIntensity` public function (AC: #6)
  - [x] 4.1: Add `public static func maximumSupportedIntensity(mlTechnique: (any MLTechnique)?) -> AnalysisIntensity` on `AudioAnalysisService`. Place AFTER `analyzeBPM(url:options:)` (lines 204-221) and BEFORE the `runPreCorroborationPipeline` MARK section (the public-API surface should cluster).
  - [x] 4.2: Body: `mlTechnique == nil ? dspOnlyMaxIntensity : .maximum`. Reuse `dspOnlyMaxIntensity` — single source of truth (DD #3).
  - [x] 4.3: Add `///` doc-comment per AC #6's suggested wording.

- [x] Task 5: Add unit tests (AC: #2-#4, #6, #9)
  - [x] 5.1: Decide MockMLTechnique reuse strategy. The existing private `MockMLTechnique` lives in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397` (file-private). Story 4.2's new tests are in the same file, so the existing definition is reachable as-is. NO promotion to `BoomBoomBoomKitTestSupport` (DD #5). If the dev places new tests in a different file, extract the mock to file-scope with `private struct MockMLTechnique` retained at file-private visibility, OR copy the definition (acceptable for test code; small surface).
  - [x] 5.2: Add a new `@Suite("AudioAnalysisService — Effective Intensity")` containing tests for ACs #2-#4. Suggested test names (dev may consolidate as long as every AC bullet is exercised):
    - `intensity1ToDefaultReportsRequestedNoReason()` — covers AC #2 for both `.fastest` and `.default` with `mlTechnique = nil`
    - `intensity1ToDefaultWithMockMLReportsRequestedNoReason()` — covers AC #2 for `.default` with `mlTechnique = MockMLTechnique()`
    - `intensity8To10NoMLCapsAt7WithReason()` — covers AC #3 for intensity 8, 9, and 10 (loop; assert `effectiveIntensity == .default`)
    - `degradationReasonExactStringForIntensity9()` — covers AC #3 exact-string match for `intensity = AnalysisIntensity(rawValue: 9)`
    - `degradationReasonExactStringForMaximum()` — covers AC #3 exact-string match for `intensity = .maximum` (asserts `"Running at intensity 7"` interpolation uses `rawValue` not name)
    - `intensity8To10WithMockMLReportsRequestedNoReason()` — covers AC #4
  - [x] 5.3: Add a new `@Suite("AudioAnalysisService — Maximum Supported Intensity")` containing two tests for AC #6:
    - `maximumSupportedIntensityNilReturnsDefault()` — `#expect(AudioAnalysisService.maximumSupportedIntensity(mlTechnique: nil) == .default)`
    - `maximumSupportedIntensityWithMockReturnsMaximum()` — `#expect(AudioAnalysisService.maximumSupportedIntensity(mlTechnique: MockMLTechnique()) == .maximum)`
  - [x] 5.4: Tests should reuse the existing fixture pattern: `let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")` for analyzeBPM tests; no fixture needed for the `maximumSupportedIntensity` tests (pure function). Keep tests fast — use `intensity = .fastest` baseline (single window) + override the field under test, except where the test specifically requires intensity 8-10.
  - [x] 5.5: Verify the existing `mlTechniqueNonNilIsIgnoredPreStory43` test at line 421-438 continues to pass without modification — its byte-identity assertion is on `bpm` and `confidence`, which are unchanged. (It already uses `intensity = .fastest`, so it does not exercise the new degradation path; no edit needed.)

- [x] Task 6: Capture diff-scope proof artifact at PR time (AC: #7)
  - [x] 6.1: After all source changes are committed, run `git diff --stat <pre-story-SHA>..HEAD` and capture to `_bmad-output/implementation-artifacts/4-2-diff-scope-proof.txt` under `# Section: git diff --stat`.
  - [x] 6.2: Add `# Section: git diff Sources/BoomBoomBoomKit/AudioAnalysisService.swift` showing the full file diff. Verify hunks are confined to the `AudioAnalysisResult` struct, the `analyzeBPM(url:options:)` body, and the new helper/maximumSupportedIntensity functions. Verify ZERO hunks inside `runPreCorroborationPipeline` (`@@ ... @@ static func runPreCorroborationPipeline` should appear nowhere in the diff).
  - [x] 6.3: Add `# Section: grep -n 'AudioAnalysisResult(' Sources/ Tests/` showing the construction-site count. Pre-story baseline: 1 (production at `AudioAnalysisService.swift:217`). Post-story: 1 (production, possibly at a shifted line number) + new test sites that construct via `analyzeBPM` (which are NOT direct construction). If the dev refactors any test to direct-construct `AudioAnalysisResult(...)`, document and justify.
  - [x] 6.4: Add `# Section: git diff Tests/BoomBoomBoomKitBenchmarkTests/` showing empty output (per AC #11).

- [x] Task 7: Validate (AC: #5, #8, #9, #10)
  - [x] 7.1: `make fmt` — verify clean, zero diff against staged changes.
  - [x] 7.2: `make lint` — `Found 1 violation, 0 serious in N files.` Single violation = pre-existing `LUFSAnalyzer.swift:94` TODO baseline. Zero new violations.
  - [x] 7.3: `make test` — full suite passes. Record `@Test(` declaration count: pre-story 307 (verified at story-authoring 2026-05-04), post-story expected 307 + N (where N = number of `@Test` declarations added in Task 5). Verify count matches expectation via `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`.
  - [x] 7.4: `make benchmark` post-changes — OA300 Acc1=N/82, Acc2=N/82 — failure subset matches snapshot at `%.1f` precision. Asserted floors hold strict-equality.
  - [x] 7.5: `make benchmark-giantsteps` post-changes — GiantSteps Acc1=N/661, Acc2=N/661 — failure subset matches snapshot. Asserted floors hold strict-equality.
  - [x] 7.6: `swift build --target BoomBoomBoomKit` and `swift build --target BoomBoomBoomKitML` both succeed independently (Story 4.1 boundary preserved — though Story 4.2 does not touch `BoomBoomBoomKitML/`, run the dual build to confirm no regression).
  - [x] 7.7: Skip `make perf-benchmark` regeneration (Story 3-6b precedent — no perf-baseline regeneration unless intentional). The reporting-only changes have no measurable wall-clock impact.
  - [x] 7.8: Sprint-status update + story-status transition handled in workflow Step 9 close-out.

### Review Findings

Code review run 2026-05-04 — three layers (Codex Blind Hunter via MCP, Edge Case Hunter, Acceptance Auditor). All 10 ACs and all 10 DDs verified PASS by the Acceptance Auditor. Most blind/edge findings dismissed as spec-authorized (DD #1 reporting-only architecture, AC #5 byte-identity-via-construction-proof, DD #10 exact-string-as-test-contract). Two test-hardening patches and one forward-compat reminder survive triage.

- [x] [Review][Patch] Pin `dspOnlyMaxIntensity == 7` invariant via public API [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:836] — applied 2026-05-04. Added paired `#expect` assertions inside both existing `MaximumSupportedIntensityTests` `@Test` declarations: `maximumSupportedIntensity(nil).rawValue == 7` and `maximumSupportedIntensity(MockMLTechnique()).rawValue == 10`. Test count delta = 0 (in-place tightening, not new declarations). Source: Codex M2 + Edge Case Hunter.
- [x] [Review][Patch] Expand `intensity1ToDefaultReportsRequestedNoReason` to cover mid-range [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:741-752] — applied 2026-05-04. Changed loop from `[1, 7]` to `[1, 4, 7]` (equivalence-class sampling: lower boundary, representative middle, ceiling — refined from full `1...7` per Codex consultation thread `019df5c3-bdce-7e81-a454-c3022d108aa3` to avoid five extra MP3 analyses for marginal fault-isolation gain). Source: Codex L5 + Edge Case Hunter mid-range gap.
- [x] [Review][Defer] Forward-compat reminder for Stories 4.5/4.6 — reporting-only architecture rests on switch-default coincidence — deferred, written to deferred-work.md. When BNNS/CoreML conformances actually diverge level 8-10 DSP semantics from level 7, the test layer must evolve (either cap requested intensity at the pipeline boundary or add behavioural pipeline-trace assertions); the current `effectiveIntensity` test surface only verifies the reporting field, not pipeline behaviour. Source: Codex H1 + M2 + M4 (consolidated).

## Dev Notes

### Architecture compliance

- **Public API boundary** (`architecture.md:455-481`): `AudioAnalysisResult` gains two new public stored properties; `AudioAnalysisService` gains one new public static function. No new public types, no new protocol changes. The `MLTechnique` protocol at `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` is unchanged — Story 4.2 references it via `(any MLTechnique)?` parameter type only. Story 4.3 owns the protocol rewrite.
- **ADR-11 (Options-first public configuration)**: not directly applicable to Story 4.2. The new fields are on the RESULT type, not the OPTIONS type. The `mlTechnique` slot on `Options` (reserved by Story 3-3a, wired by Story 4.3) is consulted by Story 4.2 *only* in `computeEffectiveIntensity` to determine the cap — no new Options fields are added.
- **Pre-1.0 / no-BC framing** (`project-context.md` §"Public API Discipline (pre-1.0)"): adding fields to `AudioAnalysisResult` shifts the synthesized memberwise init shape; this is an explicitly-allowed pre-release breaking change. `degradationReason: String?` is the AC-specified shape; future promotion to a typed enum (`DegradationReason`) is allowed when a concrete consumer surfaces.
- **Reporting-only architectural posture** (DD #1 + DD #7): Story 4.2 mutates no DSP behaviour. The new fields are computed AFTER `MetadataCorroborator.apply` returns. The `runPreCorroborationPipeline` function body is untouched. This invariant is the operational expression of "plumbing-only story cannot move accuracy."

### Source pointers (verified at story authoring 2026-05-04)

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-28` — current `AudioAnalysisResult` struct. Story 4.2 adds two fields after `metadataEvidence`.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:181-221` — current `analyzeBPM` overloads. Task 3 modifies the body of the lower one (lines 204-221) to compute `effectiveIntensity` + `degradationReason` and pass them into the result init. The single-arg overload at lines 181-185 forwards to the two-arg form unchanged.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:217-220` — the only production construction site for `AudioAnalysisResult(...)`. Two new positional args are added.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:261-338` — `runPreCorroborationPipeline`. Story 4.2 does NOT touch this body (DD #1, DD #7).
- `Sources/BoomBoomBoomKit/AnalysisIntensity.swift:18,30-40,58-66,71-78,82-84` — `AnalysisIntensity` struct, named constants, and the switch defaults that make levels 8-10 currently delegate to level 7 behaviour. Story 4.2 reads these but does NOT modify any.
- `Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201` — current `MLTechnique` labeled-tuple protocol. Story 4.2 references it via parameter type only; does NOT modify (Story 4.3 will rewrite).
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397` — existing file-private `MockMLTechnique`. Reusable as-is (DD #5).

### Why `effectiveIntensity` is post-pipeline reporting (not pre-pipeline mutation)

A natural-seeming alternative architecture: when intensity 8-10 is requested with `mlTechnique == nil`, replace `options.intensity = .default` BEFORE calling `runPreCorroborationPipeline`. This was rejected for three reasons:

1. **Today's pipeline produces identical output either way.** `AnalysisIntensity.swift:64,76,83` switch defaults make levels 8-10 indistinguishable from level 7 in `techniqueSet`, `windowSizes`, and `progressiveThreshold`. Mutating the intensity is a no-op in current behaviour — adds complexity for zero functional difference.

2. **Future Stories 4.5/4.6 will diverge levels 8-10 from level 7.** When BNNS/CoreML conformances land, levels 8-10 will gain ML-specific behaviour. If Story 4.2 hard-codes "rewrite intensity to `.default` before pipeline" today, Story 4.5/4.6 must either undo that rewrite or work around it. The post-pipeline reporting approach scales: when ML is supplied, the pipeline runs at the requested intensity (whatever level 8-10 means at the time); when ML is not supplied, the pipeline still runs at the requested intensity (which still maps to level 7 behaviour today, but Stories 4.5/4.6 can decide what level 8-10 means in the no-ML case independently).

3. **Construction-level proof is cleaner.** Pre-pipeline mutation of `options.intensity` would require justifying why bytes don't change despite the runtime mutation — a runtime claim. Post-pipeline reporting confines all changes to non-DSP code paths and lets the construction-level proof rest on "diff scope is bounded to non-DSP surface" (DD #7), which is a static claim verifiable at PR time.

### Why `degradationReason` is `String?` (not enum)

AC #2's example string is `"Requested intensity 9 requires BoomBoomBoomKitML package. Running at intensity 7 (DSP-only)."`. A typed enum (`DegradationReason.mlPackageMissing(requested: AnalysisIntensity, effective: AnalysisIntensity)`) would be more Swift-idiomatic, but:

- Today there is exactly ONE degradation path (ML missing). An enum with one case is a single-bit boolean — no information advantage over the optional string.
- The AC explicitly names `String?` as the field type. Pre-1.0 / no-BC accepts a future promotion to enum.
- A typed enum would force a `description: String` computed property anyway (consumers want a printable message); the optional-string shape skips that intermediary.
- If a SECOND degradation path ever surfaces (e.g., "requested feature requires macOS 26 — running on macOS 25 with reduced behaviour"), promoting to enum becomes natural at that point. Until then, YAGNI.

If the dev finds during implementation that a second degradation path is implicit in the codebase (currently believed not to be the case), HALT and surface to Project Lead — the enum-vs-string decision should be revisited with the second path's shape on the table.

### MockMLTechnique reuse pattern (DD #5)

`Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397` already defines:

```swift
private struct MockMLTechnique: MLTechnique {
  let name: String
  init(name: String = "Mock") { self.name = name }
  func evaluate(
    candidates: [(bpm: Double, score: Float)],
    trace: BPMDiagnosticTrace
  ) -> (bpm: Double, confidence: Double)? {
    (bpm: 999.0, confidence: 1.0)
  }
}
```

This conforms to the current labeled-tuple `MLTechnique` shape. Story 4.2's new tests can:

1. **Use it as-is** if the new tests live in the same file (`AudioAnalysisServiceTests.swift`) — `private` visibility is file-scoped, so all suites in the file can reference it.
2. **Promote to file-private at top of file** if needed — currently nested inside the `MLTechniqueSlotTests` MARK section. The dev may move it to a top-of-file `// MARK: - Test Mocks` section if multiple new suites need it.
3. **Copy the definition** if new tests live in a different file — small surface, acceptable for test code, no `BoomBoomBoomKitTestSupport` promotion (DD #5).

When Story 4.3 lands the `MLEvaluation` Sendable struct shape, this mock gets rewritten in that story. Story 4.2's reuse is intentionally throwaway-shaped.

### Story 4.3 forward-compatibility: `(any MLTechnique)?` parameter survives the protocol rewrite

`maximumSupportedIntensity(mlTechnique: (any MLTechnique)?)` accepts an existential type. Story 4.3 will rewrite the `MLTechnique` protocol body — replacing the labeled-tuple `evaluate(candidates:trace:) -> (bpm: Double, confidence: Double)?` method with `evaluate(trace:) -> MLEvaluation?` against a named Sendable struct. **This rewrite does NOT require Story 4.2's function signature to change.** The existential type `(any MLTechnique)?` means "some conformer to the `MLTechnique` protocol exists" — the meaning of "exists" is independent of *how* the protocol is shaped internally. Method signatures, associated types, and primary-associated-type clauses on the protocol body are invisible to existential storage.

**What MAY break the signature** — and is therefore worth pre-flagging for the Story 4.3 author so neither path is taken accidentally. Note that since SE-0309 ("Unlock existentials for all protocols", Swift 5.7) and SE-0353 ("Constrained existential types", Swift 5.7), the historical blanket rule "protocols with associated types or Self requirements cannot be existentials" no longer applies. SE-0335 ("Introduce existential `any`", Swift 5.6) is what made `any MLTechnique` syntactically required in the first place. The break risk today is driven by *how `AudioAnalysisService` uses the existential value*, not by the protocol shape alone:

1. **Splitting `MLTechnique` into multiple protocols** (e.g., `BNNSMLTechnique` and `CoreMLMLTechnique` as siblings of a renamed parent) — naming/identity change, not an existential-capability change. `(any MLTechnique)?` only continues to work if the renamed/umbrella protocol still exists under that exact name. If the umbrella is dropped or renamed (e.g., to `AnyMLTechnique`), the parameter type must change accordingly, or the call site must be split into two parameters when dispatch must be resolved at the call site. **HALT condition:** the protocol named `MLTechnique` no longer exists, OR a single existential can no longer represent both branches.
2. **Adding `associatedtype` requirements to `MLTechnique`** — per SE-0309, the existential `any MLTechnique` is still legal after this change. The break occurs only if `AudioAnalysisService.maximumSupportedIntensity` (or a future caller) needs to *reference* the associated type in a position where the existential cannot supply it — for example, returning a value of the associated type, or passing it to a generic function with same-type constraints. SE-0353 provides a partial escape via primary-associated-type syntax (`any MLTechnique<SomePrimaryAssoc>`), but only if the associated type is declared `primary` and the call site can name a concrete or constrained type for it. **HALT condition:** the new associated type appears in any signature reachable from `maximumSupportedIntensity` or `analyzeBPM`'s ML branch in a way that the existential's type-erasure cannot satisfy.
3. **Adding `Self` requirements to method signatures** (e.g., `func combine(with other: Self) -> Self`) — per SE-0309 the protocol remains usable as `any MLTechnique`, and such methods can be *declared*. The break occurs at the *call site*: invoking a `Self`-returning or `Self`-consuming method through an existential erases `Self` to `any MLTechnique`, which fails when the caller needs the concrete type back (e.g., to chain calls, store in a homogeneous collection, or pass to a generic constrained on `Self`). **HALT condition:** Story 4.3 introduces a `Self`-using member that `AudioAnalysisService` (or a downstream consumer reachable from the public API) needs to invoke through the existential.

Story 4.3's epic spec (`epics.md:863-938`) proposes none of these — the `MLEvaluation` struct + `evaluate(trace:) -> MLEvaluation?` rewrite stays within the existential-friendly shape (no associated types, no `Self` requirements, single protocol named `MLTechnique`). Story 4.2's `(any MLTechnique)?` parameter is therefore stable across the planned Story 4.3 changes. **If Story 4.3 author proposes any of the three shapes above, HALT and surface the compatibility impact to Project Lead before implementation — Story 4.2's `maximumSupportedIntensity` signature must be re-evaluated against the specific HALT condition triggered.**

### Construction-level proof shape (DD #7 expanded)

Story 4.1's construction-level proof was tight: `git diff main..HEAD -- Sources/BoomBoomBoomKit/` returned empty, so per-track BPM/confidence output was byte-identical *by construction*.

Story 4.2 modifies `AudioAnalysisService.swift`, so the proof shape shifts. The Story 4.2 proof has three parts:

1. **Modified-file scope**: `git diff --stat <pre-story-SHA>..HEAD -- Sources/BoomBoomBoomKit/` shows ONLY `AudioAnalysisService.swift` modified. Zero changes to `BPMAnalyzer.swift`, `AnalysisIntensity.swift`, `MetadataCorroborator.swift`, `BPMDiagnosticTrace.swift`, `CandidateMergeStrategy.swift`, `VotingPolicy.swift`, `MetadataPolicy.swift`, `LUFSAnalyzer.swift`, `MelFilterbank.swift`, `PCMBufferReader.swift`, `FileMetadataReader.swift`, `ProgressUpdate.swift`, `DSPTechnique.swift`. (13 files in `Sources/BoomBoomBoomKit/`; 1 modified, 12 untouched.)

2. **Hunk-level scope within the modified file**: the diff hunks in `AudioAnalysisService.swift` are confined to (a) the `AudioAnalysisResult` struct (two new field declarations + their doc-comments — additions only, no modifications to existing fields), (b) the body of `analyzeBPM(url:options:)` (compute new values, pass to result init — no modifications to the `runPreCorroborationPipeline` call or `MetadataCorroborator.apply` call), (c) net-additions for `dspOnlyMaxIntensity` constant, `computeEffectiveIntensity` helper, `degradationMessage` helper, and `maximumSupportedIntensity` public function. ZERO hunks inside `runPreCorroborationPipeline` (DSP candidate computation is bypass-untouched).

3. **No `Tests/` benchmark-target modifications**: `git diff <pre-story-SHA>..HEAD -- Tests/BoomBoomBoomKitBenchmarkTests/` returns empty (per AC #11; same constraint family as Story 4.1's "no @Test additions for snapshot capture").

These three claims, captured in `4-2-diff-scope-proof.txt` (AC #7), establish that `bpm`, `confidence`, and per-element `candidates` are byte-identical to pre-story output (the named scope per Epic 4 Definitions, `epics.md:766`), and that `trace` + `metadataEvidence` are unchanged-by-construction because the building code is bypass-untouched. The snapshot at `4-2-regression-snapshot.json` is defense-in-depth at lossy `%.1f` precision over the byte-identical scope only.

### Risk / out-of-scope guards

- **Do NOT** modify `Sources/BoomBoomBoomKit/AnalysisIntensity.swift`. Story 4.2 reads the type and its named constants; the cap value (7) lives in `AudioAnalysisService` as `dspOnlyMaxIntensity` (DD #3). Adding a property on `AnalysisIntensity` like `var isDSPOnly: Bool { rawValue <= 7 }` would feel symmetric, but pollutes the value-type with "what does ML look like" knowledge. Defer.
- **Do NOT** modify `Sources/BoomBoomBoomKit/DSPTechnique.swift`. The `MLTechnique` protocol stays unchanged; Story 4.3 owns the rewrite. Story 4.2 references the protocol via `(any MLTechnique)?` parameter type only.
- **Do NOT** modify the `runPreCorroborationPipeline` function body in any way. The new logic lives in `analyzeBPM(url:options:)` — Task 3.5 explicitly verifies this.
- **Do NOT** add a new field to `Options`. The trigger for degradation is `options.mlTechnique == nil`, which already exists. Story 4.2 reads it; does not extend it.
- **Do NOT** promote `MockMLTechnique` to `BoomBoomBoomKitTestSupport`. DD #5: Story 4.3 owns that promotion when the protocol shape stabilizes. Story 4.2 reuses the existing private mock at `AudioAnalysisServiceTests.swift:384-397`.
- **Do NOT** add a new env-gated `@Test` to `BoomBoomBoomKitBenchmarkTests` for snapshot capture. Per AC #11 and the Story 4.1 precedent, the snapshot is captured by RUNNING the existing benchmarks and copy-pasting / scripting the stdout. Adding a new behavioural test surface defeats the regression-protection invariant.
- **Do NOT** change the package-level platforms floor or add `@available` annotations to the new public surface (DD #9).
- **Do NOT** modify the existing `mlTechniqueNonNilIsIgnoredPreStory43` test (line 421-438). Its assertion on `bpm` and `confidence` continues to hold; the new fields are additive.
- **Do NOT** introduce a typed enum for `degradationReason` in this story (DD #2). If a second degradation path emerges in implementation, HALT and surface to Project Lead for the enum-vs-string decision.
- **Do NOT** rename or relocate `AudioAnalysisResult` or `AudioAnalysisService`. Public-API location preserved.

### Apple-platform notes

- **`Sendable` synthesis**: `AudioAnalysisResult` is already `Sendable`; adding two `Sendable` fields (`AnalysisIntensity` is `Sendable`, `String?` is `Sendable`) does not require an explicit `Sendable` conformance change. Swift 6 strict concurrency synthesizes the conformance automatically for structs with all-`Sendable` stored properties.
- **No `@MainActor` concerns**: `AudioAnalysisService` is stateless and non-isolated; the new fields and function inherit that posture. No actor/isolation annotations required.
- **No new framework imports**: Story 4.2 uses only `Foundation` (already imported by `AudioAnalysisService.swift:10`). No `import Accelerate`, no `import CoreML`, no `import BoomBoomBoomKitML` — the package boundary established by Story 4.1 is preserved trivially because Story 4.2's changes live in `Sources/BoomBoomBoomKit/`.
- **Swift Testing patterns**: continue using `@Suite`, `@Test`, `#expect`, `#require` per `project-context.md` §"Testing Rules". Use `#expect` for the new field assertions; `#require` is unnecessary for these tests since a nil result would simply mean a fixture issue (not a meaningful nil/failure case for the new fields).

### Previous Story Intelligence (Story 4.1, SHA `29ced70` — closed 2026-05-04)

1. **Snapshot precedent fully formed**. Story 4.1 invented the lossy-`%.1f` + `snapshot_metadata`-header schema after the dev-time HALT (AC #7 user-authorized amendment). Story 4.2 reuses this schema verbatim — no need to re-derive the precision contract or the metadata fields. Pattern: capture BEFORE first dev commit, verify at PR time, exclude `snapshot_metadata` block from the diff comparison.

2. **Construction-level proof is the load-bearing claim**. Story 4.1's construction-level proof was `git diff main..HEAD -- Sources/BoomBoomBoomKit/` returns empty. Story 4.2 inherits this discipline but with a tighter shape (DD #7): diff scope is bounded to non-DSP surface. The snapshot is defense-in-depth.

3. **Test count baseline 307**. Pre-Story-4.2 baseline = 307 grep-visible `@Test(` declarations (verified at story-authoring 2026-05-04 via `grep -rE '@Test\(' Tests/BoomBoomBoomKitTests/ | wc -l`). Story 4.2 will ADD ~8-10 new declarations (Task 5). Document the new count in Completion Notes — this is informational, not a binding constraint (unlike Story 4.1 which had the "ZERO new declarations" constraint).

4. **OA300 + GiantSteps baselines**: OA300 Acc1=58/82 (70.7%), Acc2=74/82 (90.2%); GiantSteps Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). Asserted floors 57/73/537/546 hold strict-equality. Story 4.2 must produce identical numbers — the failure-track subsets are the snapshot comparison surface.

5. **Pre-existing TODO baseline**: single TODO at `LUFSAnalyzer.swift:94` is the canonical "acceptable lint violation" baseline. Story 4.2 must not introduce new TODO comments.

6. **`MockMLTechnique` already exists** and is reusable for Story 4.2's `maximumSupportedIntensity` non-nil tests (DD #5). Story 3-3a's "non-disabled Sendable conformance test using a real mock" precedent is honored.

7. **AC-text wording-deviation amendment pattern**: Story 4.1 had a Change Log entry reconciling `Build complete!` (AC literal) with `Build of target: 'X' complete!` (actual SwiftPM phrasing for per-target builds). Story 4.2 has its own AC-text reconciliation: AC #6 of `epics.md` says `public func`, but the function is `public static func` (DD #4). Pre-emptively documented in Change Log to avoid review friction.

8. **HALT discipline**: if implementation surfaces a contradiction or scope question (e.g., "what if the intensity rawValue is 11+ — clamping makes it 10, but is the cap-at-7 message correct?") — HALT and surface to Project Lead, do NOT silently relax the AC. The AnalysisIntensity init clamps to 1-10 (`AnalysisIntensity.swift:25`), so 11+ inputs cannot reach `analyzeBPM`; the cap-at-7 message is correct for any 8-10 input. But if a similar edge surfaces, HALT.

### References

- [Source: _bmad-output/planning-artifacts/epics.md] — Epic 4 preamble (lines 756-771) + Story 4.2 spec (lines 821-861). Definitions used by AC #8 (asserted floors, byte-identical, non-regression gate) live in the preamble.
- [Source: _bmad-output/planning-artifacts/architecture.md] — public/internal boundary (lines 455-481), pre-1.0 / no-BC framing references.
- [Source: _bmad-output/project-context.md] — Swift 6 strict concurrency / `Sendable` rule, value-types-only, six-line file-header convention (no new files in this story; existing headers preserved), §"Public API Discipline (pre-1.0)" (load-bearing for DD #2 and DD #6).
- [Source: _bmad-output/implementation-artifacts/4-1-boomboomboomkitml-package-structure.md] — snapshot precedent (Task 1, AC #7), construction-level proof discipline (Change Log dev-time HALT entry), `MockMLTechnique` is implicitly reused. Diff-scope-proof artifact pattern adapted from Story 4.1's package-boundary-proof.
- [Source: _bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md] — `mlTechnique: (any MLTechnique)?` slot reservation pattern; `MockMLTechnique` test-target conformance precedent (architecture.md:482 — public package ships no MLTechnique conformances; mocks live in test target).
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml] — Epic 4 sequencing; Story 4.2 follows 4.1; no other 4.x story currently `done`.
- [Source: _bmad-output/implementation-artifacts/deferred-work.md] — `MLTechnique` tuple→struct entry folded into Story 4.3 (not this story).
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:13-28,181-221,261-338] — `AudioAnalysisResult` struct, `analyzeBPM` overloads, `runPreCorroborationPipeline` (untouched).
- [Source: Sources/BoomBoomBoomKit/AnalysisIntensity.swift:18,30-40,58-66,71-78,82-84] — `AnalysisIntensity` type, named constants, switch defaults that make 8-10 currently delegate to 7.
- [Source: Sources/BoomBoomBoomKit/DSPTechnique.swift:182-201] — current `MLTechnique` labeled-tuple protocol (not modified by Story 4.2; Story 4.3 will rewrite).
- [Source: Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397,421-438] — existing `MockMLTechnique` (reusable) and `mlTechniqueNonNilIsIgnoredPreStory43` (continues to pass unmodified).
- [Apple Docs: Sendable](https://developer.apple.com/documentation/swift/sendable) — `Sendable` synthesis for structs with all-`Sendable` stored properties (relevant to AC #1 transitivity claim).

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (Claude Opus 4.7, 1M context)

### Debug Log References

None — implementation followed spec directly without HALT events. Two SourceKit/IDE staleness diagnostics fired during the session (cached `[String: String]` shape claims for trace fields, plus `effectiveIntensity`/`degradationReason` member-not-found warnings post-add); both were SourceKit cache lag — `swift build` and `swift test` confirmed clean each time.

### Completion Notes List

**Pre-story baseline (snapshot SHA: `8c37d64`)**

- Captured 2026-05-04T21:34:24Z on macOS 26.5, Xcode 26.4.1, Swift 6.3.1.
- OA300 strict-tolerance: Acc1 = 58/82 (70.7%), Acc2 = 74/82 (90.2%) — 24 failure tracks recorded in snapshot.
- OA300 durationHint=false control: Acc1 = 57/82, Acc2 = 73/82 (matches asserted floors `OA300BenchmarkTests.swift:105,109`).
- GiantSteps strict-tolerance: Acc1 = 537/661 (81.2%), Acc2 = 546/661 (82.6%) — first 30 of 124 failure tracks recorded; `tracks_failure_subset_truncated_count` = 94 per Story 4.1 schema.
- Snapshot file: `_bmad-output/implementation-artifacts/4-2-regression-snapshot.json` (JSON-validated).

**Implementation summary**

- Added two `Sendable` fields to `AudioAnalysisResult`: `effectiveIntensity: AnalysisIntensity` and `degradationReason: String?`. Doc-comments ship the consumer-guidance corollary (DD #2 / spec amendment E2) — branching control flow uses `maximumSupportedIntensity(mlTechnique:)` BEFORE analysis; `degradationReason` is display text.
- Added `private static let dspOnlyMaxIntensity: AnalysisIntensity = .default` as single source of truth (DD #3). Three call sites consume it: `analyzeBPM`'s effective-intensity computation, `degradationMessage` helper, and `maximumSupportedIntensity(mlTechnique:)`.
- Added two private static helpers (`computeEffectiveIntensity`, `degradationMessage`) and one new public function (`maximumSupportedIntensity(mlTechnique:) -> AnalysisIntensity`). `maximumSupportedIntensity` ships as `public static func` per DD #4 (reconciles AC #6's `public func` to mirror `analyzeBPM`'s shape — recorded in Change Log).
- `analyzeBPM(url:options:)` body computes `effective` and `reason` AFTER `MetadataCorroborator.apply` returns and BEFORE constructing `AudioAnalysisResult` — pure post-pipeline reporting. `runPreCorroborationPipeline` body untouched.
- Reused existing file-private `MockMLTechnique` (Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-397) for non-nil mlTechnique tests per DD #5. Did NOT promote to `BoomBoomBoomKitTestSupport` — Story 4.3 owns that promotion against the post-rewrite protocol shape. No mock extraction or duplication needed (new tests live in same file).

**Construction-level proof (DD #7)**

- `git diff HEAD -- Sources/` modifies ONLY `AudioAnalysisService.swift` (87 insertions, 1 deletion). Zero modifications to `BPMAnalyzer.swift`, `AnalysisIntensity.swift`, `MetadataCorroborator.swift`, `BPMDiagnosticTrace.swift`, `CandidateMergeStrategy.swift`, `VotingPolicy.swift`, `MetadataPolicy.swift`, `LUFSAnalyzer.swift`, `MelFilterbank.swift`, `PCMBufferReader.swift`, `FileMetadataReader.swift`, `ProgressUpdate.swift`, `DSPTechnique.swift`. (12 of 13 source files untouched.)
- Hunks within `AudioAnalysisService.swift` are confined to `AudioAnalysisResult` struct, the `dspOnlyMaxIntensity` constant declaration, the `analyzeBPM(url:options:)` body, and net-additions for the three new helper/public functions.
- Only `+`/`-` line referencing `runPreCorroborationPipeline` is a comment in the new `analyzeBPM` body (verified by `grep -nE '^[+-].*runPreCorroborationPipeline'` → 1 match, all context). Function body itself is bypass-untouched, satisfying Task 3.5 + 3.6.
- `git diff HEAD -- Tests/BoomBoomBoomKitBenchmarkTests/` returns empty per AC #11.
- Boundary-proof artifact: `_bmad-output/implementation-artifacts/4-2-diff-scope-proof.txt`.

**Production construction-site count**

- Pre-story baseline: 1 production site at `AudioAnalysisService.swift:217`. Post-story: 1 production site at `AudioAnalysisService.swift:259` (line shifted due to additions). Tests use `analyzeBPM()` facade — no direct `AudioAnalysisResult(...)` construction added. Verified via `grep -n 'AudioAnalysisResult(' Sources/ Tests/`.

**Test count delta**

- Pre-story `@Test(` count: 307 (verified at story-authoring 2026-05-04 and re-verified at dev start).
- Post-story `@Test(` count: 315 (8 new declarations across two new suites — `EffectiveIntensityTests`, `MaximumSupportedIntensityTests`). Matches the AC #9 estimate of 8-10 new declarations.

**Validation results (all passing)**

- `make fmt`: clean, formatter-idempotent, zero diff against staged changes.
- `make lint`: 1 violation, 0 serious — pre-existing `LUFSAnalyzer.swift:94` TODO baseline. Two transient `type_name` warnings on overly-long suite names (`AudioAnalysisServiceEffectiveIntensityTests`, `AudioAnalysisServiceMaximumSupportedIntensityTests`) were resolved in-session by renaming to `EffectiveIntensityTests` / `MaximumSupportedIntensityTests` (matches the existing `MLTechniqueSlotTests` precedent).
- `make test`: 315 tests in 70 suites passed in 1.215s.
- `make benchmark`: post-change OA300 Acc1 = 58/82, Acc2 = 74/82, durationHint=false control = 57/82, 73/82. All four asserted floors hold strict-equality. Failure-table rows byte-identical to snapshot (verified by sorted-unique-rows comparison: 25 rows match exactly).
- `make benchmark-giantsteps`: post-change Acc1 = 537/661, Acc2 = 546/661. Asserted floors hold. Failure tables byte-identical to snapshot.
- `swift build --target BoomBoomBoomKit` and `swift build --target BoomBoomBoomKitML`: both build independently (Story 4.1 boundary preserved per Task 7.6).
- `make perf-benchmark`: skipped per Task 7.7 (Story 3-6b precedent — no perf-baseline regeneration unless intentional; reporting-only changes have no measurable wall-clock impact).

### File List

Modified:
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — added `effectiveIntensity` + `degradationReason` fields to `AudioAnalysisResult`; added `dspOnlyMaxIntensity` private constant, `computeEffectiveIntensity` + `degradationMessage` private helpers, and `maximumSupportedIntensity(mlTechnique:)` public static function; expanded `analyzeBPM(url:options:)` body to compute and pass the two new fields.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — added `EffectiveIntensityTests` and `MaximumSupportedIntensityTests` suites (8 new `@Test` declarations).

Added:
- `_bmad-output/implementation-artifacts/4-2-regression-snapshot.json` — pre-story regression snapshot at `8c37d64` (lossy `%.1f` precision per Story 4.1 schema).
- `_bmad-output/implementation-artifacts/4-2-diff-scope-proof.txt` — diff-scope boundary-proof artifact (AC #7).

## Change Log

- 2026-05-04 (Story 4.2 creation): Authored per `/bmad-create-story 4-2` invocation. Story foundation extracted from epic spec at `epics.md:821-861`; reporting-only architecture (DD #1) and construction-level proof (DD #7) directly inherited from Story 4.1 precedent. Ten Key Design Decisions captured at the top: (1) reporting-only — no pipeline mutation; (2) `degradationReason` is `String?` not enum (per AC); (3) hard-coded `dspOnlyMaxIntensity = 7` constant as single source of truth; (4) `maximumSupportedIntensity` is `public static func` (AC text reconciliation); (5) `MockMLTechnique` reuse from existing test target — no `BoomBoomBoomKitTestSupport` promotion; (6) `AudioAnalysisResult` synthesized init breaks accepted under pre-1.0 framing; (7) construction-level proof shifts to "diff scope confined to non-DSP surface"; (8) snapshot precedent from Story 4.1 with `snapshot_metadata` header and `%.1f` precision; (9) no `@available` annotations on new surface; (10) degradation message uses `rawValue` (Int) not named-constant string. Status: `ready-for-dev`.

- 2026-05-04 (Architecture-panel + Codex elicitation pass): Convened 4-persona panel via `/bmad-advanced-elicitation` ADR method (Pragmatist + Purist + Operator + Apple-platform architect) on DDs #1 (reporting-only), #2 (`String?` vs enum), #6 (memberwise-init breakage). All three ratified 4-0 with sharpening edits. Then consulted Codex via `codex:consult` agent on the panel's findings (thread `019df4cc-2ca5-70f0-8d0e-54259fd97767`) — Codex ratified all 4 panel edits, surfaced 4 NEW findings the panel missed, and recommended applying all 6 total edits without holding the story. Edits applied: **(E1)** swept "actual intensity used" wording across user story + Background §1 + Task 2.2 `effectiveIntensity` doc-comment guidance + DD #1 prose, replacing with "effective DSP-level depth" framing and adding an explicit forward-compatibility paragraph noting that the byte-identity claim rests on a behavioural coincidence (switch-default delegation) and the architecture is forward-compatible because Stories 4.5/4.6 can change level 8-10 semantics independently (Codex B1 — caught a real internal contradiction across normative text); **(E2)** appended consumer-guidance corollary to DD #2, appended branching-guidance note to Task 2.2 `degradationReason` doc-comment, and reconciled DD #10's "exact text public contract" wording with DD #2's "don't string-parse" guidance — exact string is now framed as the regression-test-assertion contract, not a stable consumer-facing API (Codex A3 — Reasoning Reconciliation); **(E3)** tightened AC #5 + AC #8 byte-identical scope to match Epic 4 Definitions' named scope (`bpm`, `confidence`, per-element `candidates` only) — `trace` and `metadataEvidence` are now framed as unchanged-by-construction (static diff-scope claim), not byte-identical-to-snapshot (Codex B2 — over-claim correction; the lossy `%.1f` snapshot artifact does not serialize trace/metadataEvidence, so the prior claim was unverifiable); **(E4)** added new Dev Notes subsection "Story 4.3 forward-compatibility" documenting that `(any MLTechnique)?` parameter survives Story 4.3's `MLEvaluation` rewrite cleanly via existential-type semantics, with three named breaking-change patterns (protocol-split, associated-type addition, `Self` requirements) flagged as halt-and-surface triggers if Story 4.3 author proposes any (Codex B4 — preemptive caveat). **(E5+E6)** Two new deferred-work entries written to `_bmad-output/implementation-artifacts/deferred-work.md`: future enum promotion of `degradationReason` when a second degradation path emerges; future explicit-init migration of `AudioAnalysisResult` when field count exceeds ~10. Status unchanged: `ready-for-dev`.

- 2026-05-04 (Edge Case Hunter elicitation pass): Walked 10 boundary classes against the amended spec — `rawValue` 7-vs-8 cap-check semantics, throwing `MLTechnique` (non-issue today and post-4.3), out-of-range intensity clamping behaviour, `==` semantics across construction modes, nil-result UX gap (covered by `maximumSupportedIntensity` pre-flight escape hatch), concurrency invariants, class-vs-struct ML conformer, error-path ordering in `analyzeBPM`. Nine boundaries clean. **One finding (Boundary 4):** `degradationMessage(requested:effective:)` helper (Task 3.3) is structurally symmetric (takes two `AnalysisIntensity` values, returns optional message) but the message *body* hardcodes `"requires BoomBoomBoomKitML package"`. When a SECOND degradation path emerges (premise of the existing deferred-work entry), promotion concomitantly requires refactoring the helper into per-case message handling. The implicit linkage was not stated in the original deferred-work entry. Edit applied: precision-added the `degradationReason` enum-promotion deferred-work entry to explicitly call out that the message-helper refactor ships together with the enum promotion (one-sentence add — "doing only one leaves either a stranded helper or a stranded enum"). Status unchanged: `ready-for-dev`.

- 2026-05-04 (Dev implementation, status `ready-for-dev` -> `review`): Pre-story snapshot captured at SHA `8c37d64` against macOS 26.5 / Xcode 26.4.1 / Swift 6.3.1 — OA300 Acc1=58/82, Acc2=74/82; GiantSteps Acc1=537/661, Acc2=546/661. Implemented Tasks 1-7 in spec order: Task 1 captured `4-2-regression-snapshot.json` (Story 4.1 schema, JSON-validated); Tasks 2-4 added two new `Sendable` fields to `AudioAnalysisResult` (`effectiveIntensity: AnalysisIntensity`, `degradationReason: String?`), introduced `dspOnlyMaxIntensity` single-source-of-truth constant, two private helpers (`computeEffectiveIntensity`, `degradationMessage`), and one new `public static func maximumSupportedIntensity(mlTechnique:) -> AnalysisIntensity`; Task 5 added 8 new `@Test(` declarations across two new suites (`EffectiveIntensityTests`, `MaximumSupportedIntensityTests`) — file-private `MockMLTechnique` reused as-is per DD #5, no mock extraction needed; Task 6 captured `4-2-diff-scope-proof.txt` boundary-proof artifact. **AC #6 text reconciliation (DD #4):** epic spec text said `public func`; shipped as `public static func` to mirror `analyzeBPM`'s shape — change-log entry per DD #4. **Suite-name reconciliation:** the dev's first-pass suite names (`AudioAnalysisServiceEffectiveIntensityTests` at 43 chars, `AudioAnalysisServiceMaximumSupportedIntensityTests` at 50 chars) violated SwiftLint's `type_name` 40-char limit; resolved in-session by shortening to `EffectiveIntensityTests` and `MaximumSupportedIntensityTests` (mirrors the existing `MLTechniqueSlotTests` precedent at 20 chars). All four asserted accuracy floors held strict-equality post-changes; failure subsets byte-identical to snapshot. Construction-level proof verified: 12 of 13 `Sources/BoomBoomBoomKit/` files untouched, `runPreCorroborationPipeline` function body is bypass-untouched, `Tests/BoomBoomBoomKitBenchmarkTests/` diff is empty per AC #11. Status: `review`.

- 2026-05-04 (Party-mode + Apple-docs MCP + Codex final review pass): Validated `(any MLTechnique)?` existential survival rules via axiom-concurrency skill (Sendable-synthesis confirmed for value types with all-Sendable storage; SE-0418 confirms tuples-of-Sendable are structurally Sendable, reconciling the existing `[(bpm: Double, score: Float)]` field with project-context.md's "no tuples in protocol signatures" rule which is about DocC/Equatable/Codable extensibility not Sendable enforcement). Apple-docs MCP queries returned no direct hits for the search terms tried; axiom-concurrency provided the relevant Sendable rules instead. Then consulted Codex via `codex:consult` (thread `019df4e0-6b94-7c23-81e6-dc48f87a82ef`) — verdict: NO HALT BLOCKERS, two small recommended edits, plus 3 named party-mode personas with concrete questions. Spawned Amelia (Sr-SWE), Siri (Apple Platform Docs), and Paige (Tech Writer) in parallel via the Agent tool with persona-embedded prompts. Findings synthesized: **(P1)** Amelia ratified dev-readiness — confirmed implementation feasibility (single-file diff scope holds, no implicit visibility shifts needed in `AnalysisIntensity`/`MLTechnique`/`MetadataCorroborator`) and test coverage adequacy (Task 5.2/5.3's ~10 tests prove ACs #2-#4/#6 cleanly, AC #11 holds for snapshot capture path). **(P2)** Siri rewrote the "Story 4.3 forward-compatibility" subsection grounded in SE-0309 / SE-0335 / SE-0353 — softened "would NOT survive" to "MAY break", added per-pattern "HALT condition" clauses tied to use-site access semantics (the actual break vector) rather than to the protocol shape alone. Preserves the HALT instruction; replaces the categorical false rule with conditional triggers. **(P3)** Paige found two remaining drift points the prior elicitation passes missed: Background §"plumbing-only" line and Dev Notes "Construction-level proof shape" line both still listed `bpm/confidence/candidates/trace/metadataEvidence` as uniformly byte-identical, conflating the two claim types that AC #5/#8 carefully split. Both lines now corrected to distinguish byte-identical-to-snapshot scope (`bpm`, `confidence`, per-element `candidates`) from unchanged-by-construction scope (`trace`, `metadataEvidence`). **(P4)** Codex's recommended Task 3.5 proof bullet added as Task 3.6 — explicitly verifies `BPMAnalyzer` and `MetadataCorroborator` trace/evidence construction sites are bypass-untouched, closing the gap between AC #5/#8 byte-identical scope claims and Task 3.5's DSP-only diff verification. Status unchanged: `ready-for-dev`. Codex thread: `019df4e0-6b94-7c23-81e6-dc48f87a82ef`.
