# Story 3.3a: Public API Harmonization — mlTechnique Slot, ADR-11 Reconciliation, README Cleanup

Status: done
**Depends on:** none (Story 3-3 is `done` as of 2026-04-26; this story is now standalone)

## Story

As a library consumer (and as the next dev who will pick up Epic 4 Story 4.3),
I want the public configuration surface to (a) reserve the `mlTechnique` slot on `AudioAnalysisService.Options` ahead of Story 4.3 with a real Sendable conformance test, (b) reconcile Story 4.3's epic spec text to match ADR-11's "Options-first" convention, and (c) repair the stale README so the public quick-start sample compiles against the shipped API,
So that Story 4.3 lands its evaluation path against a known-good slot and external SPM consumers reach a working README on first contact.

## Background

The original Story 3-3a draft (authored 2026-04-26 morning) ballooned in scope and was returned by Codex (gpt-5.5) with a "Block — re-author" verdict. A multi-agent BMad party-mode review confirmed the verdict. The user's elicitation answers (2026-04-26) trimmed scope to three deliverables:

1. **Reserve the `mlTechnique` slot now.** Land `public var mlTechnique: (any MLTechnique)? = nil` on `Options` with a non-disabled Sendable conformance test using a mock `MLTechnique`. Story 4.3 will wire the evaluation path. This replaces the Codex-flagged "disabled-test placeholder" anti-pattern with a real API commitment (Siri's recommendation).
2. **Edit Story 4.3's epic spec** in `epics.md` to use `Options.mlTechnique` instead of an `analyzeBPM` method parameter. Stories 4.2/4.4/4.6 reconcile to ADR-11 when each is promoted from `backlog` to `ready-for-dev` (single source of truth in ADR-11; per-story edits at promotion time avoid stale-doc drift).
3. **README cleanup.** Repair the three known stale items: (a) shows nonexistent `analyzeBPM(url:intensity:mergeStrategy:)` API, (b) claims OGG support that PCMBufferReader doesn't have, (c) says `DSPTechnique` has 6 cases (now 7).

The broader public-API harmonization work (rename `techniques` → `techniqueSet`, add `Options` field-style convention, add ADR-11) **already shipped in the Story 3-3 close-out commit** on 2026-04-26 (`8934f5f`). This story does the remaining three discrete items, no scope creep.

User directive: **backwards compatibility is NOT a goal; consistency IS the goal.** Renames and breaking schema changes are on the table when they serve consistency.

## Acceptance Criteria

1. **Given** `AudioAnalysisService.Options`
   **When** the new field is added
   **Then** `public var mlTechnique: (any MLTechnique)? = nil` exists with a doc-comment matching the existing `techniqueSet` pattern (optional, `nil = feature inactive`, opt-in semantic)
   **And** the Options struct doc-comment's "Field-style convention" block is updated to list `mlTechnique` alongside `onProgress` and `techniqueSet` as opt-in optional fields
   **And** the field's doc-comment cross-references `MLTechnique` (the public protocol in `DSPTechnique.swift`) and Story 4.3's planned wiring in `analyzeBPM`.

2. **Given** the new field
   **When** a mock `MLTechnique` conformance is constructed in the test target
   **Then** `Options` accepts the mock without compile error
   **And** a non-disabled test in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (suite `TechniqueSetOverrideTests` or new `MLTechniqueSlotTests`) asserts:
   - `var opts = Options(); opts.mlTechnique = MockMLTechnique(); #expect(opts.mlTechnique != nil)` compiles and passes
   - `opts.mlTechnique` round-trips: setting and reading returns an instance whose `name` matches the mock
   - When `opts.mlTechnique == nil` (default), `analyzeBPM(url:options:)` produces results identical to a baseline run without the field set (proves the field is wired but not yet active)
   - The mock conformance lives in the test target ONLY (`Tests/BoomBoomBoomKitTests/`), not in `Sources/`, per architecture.md:480.

3. **Given** Story 4.3's spec text in `_bmad-output/planning-artifacts/epics.md` (lines 823-848)
   **When** the spec is edited
   **Then** every reference to `mlTechnique: (any MLTechnique)? = nil` as an `analyzeBPM` method parameter is replaced with "as a field on `AudioAnalysisService.Options`"
   **And** the spec text cites ADR-11 by name as the rationale
   **And** the AC text and supporting paragraphs are internally consistent (no remaining stray "method parameter" references).

4. **Given** Stories 4.2, 4.4, 4.6 (all `backlog`)
   **When** reviewed by this story's author
   **Then** no spec edits are made to those stories — they reconcile to ADR-11 when each promotes from `backlog` to `ready-for-dev`. This story records the intent in Completion Notes ("Stories 4.2/4.4/4.6 deferred per ADR-11 fan-out policy"). Single source of truth is ADR-11; per-story edits happen at promotion time.

5. **Given** the project README
   **When** updated
   **Then**
   - The quick-start sample uses the current public API: `AudioAnalysisService.analyzeBPM(url:)` and `AudioAnalysisService.analyzeBPM(url:options:)` with `var opts = AudioAnalysisService.Options(); opts.intensity = .fastest`. No reference to `analyzeBPM(url:intensity:mergeStrategy:)`.
   - The supported-formats list does NOT include OGG/Vorbis (PCMBufferReader does not support it; the existing CLAUDE.md correction from `ed9cc0b` is honored).
   - The `DSPTechnique` count is documented as 7 cases (or written without a hard count, which is sustainable as more cases are added).
   - A new short section "Customizing techniques" shows the `Options.techniqueSet` override pattern with `.clickAugmented` as the example. (This is the section Story 5.5 will later expand.)
   - All code samples in the README compile against the current `AudioAnalysisService` API. (No tests required for README samples; visual review against `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` is sufficient.)

6. **Given** the existing benchmark and accuracy-floor protections
   **When** this story's changes ship
   **Then** OA300 Acc1 ≥ 57/82 AND Acc2 ≥ 73/82 (per AC #6 of Story 3-3); GiantSteps Acc1 ≥ 537/661 AND Acc2 ≥ 546/661 (now asserted post-Story-3-3); `make oracle` shows no regression. Test count grows by exactly the new mlTechnique-slot tests (≥ 1 from AC#2). No DSP behavior change; this is a pure API-surface and documentation story.

## Tasks / Subtasks

- [x] Task 1: Land `mlTechnique` slot on `Options` (AC: #1, #2)
  - [x] 1.1: Add `public var mlTechnique: (any MLTechnique)?` to `AudioAnalysisService.Options` (default `nil` per Swift's implicit-nil rule; do NOT write `= nil` per CLAUDE.md project-context.md "implicit nil" rule).
  - [x] 1.2: Add doc-comment matching the `techniqueSet` precedent: explain optional-for-opt-in semantic, link to `MLTechnique` protocol, note that the actual evaluation path lands in Story 4.3.
  - [x] 1.3: Update the Options struct doc-comment's "Field-style convention" block to list `mlTechnique` alongside `techniqueSet` and `onProgress` as opt-in optional fields. Cross-reference ADR-11.
  - [x] 1.4: `analyzeBPM(url:options:)` does NOT yet read `options.mlTechnique`. Story 4.3 owns the wiring. Add a one-line code comment at the top of `analyzeBPM` noting "mlTechnique slot is reserved (Story 3-3a, ADR-11); evaluation path lands in Story 4.3."

- [x] Task 2: Add a mock `MLTechnique` conformance in tests (AC: #2)
  - [x] 2.1: Create `Tests/BoomBoomBoomKitTests/MockMLTechnique.swift` (or inline in `AudioAnalysisServiceTests.swift`). Public-only API import; `@testable import` is acceptable here since the mock is test-target-only. The mock conforms to `MLTechnique` with `var name: String = "Mock"` and `evaluate(...) -> nil`. _(Implemented inline in AudioAnalysisServiceTests.swift as `private struct MockMLTechnique`.)_
  - [x] 2.2: Add `MLTechniqueSlotTests` suite (or extend `TechniqueSetOverrideTests`) with three tests:
    - `mlTechniqueSlotAcceptsConformance` — sets the field, reads it, asserts non-nil.
    - `mlTechniqueDefaultsToNil` — fresh `Options()` has nil.
    - `mlTechniqueNilProducesIdenticalResults` — runs `analyzeBPM` with and without the field set; asserts `result.bpm` is identical (proves the field is inert until Story 4.3 lands).

- [x] Task 3: Reconcile Story 4.3's epic spec (AC: #3)
  - [x] 3.1: Edit `_bmad-output/planning-artifacts/epics.md` lines 823-848 (Story 4.3). Replace AC text "a new parameter `mlTechnique: (any MLTechnique)? = nil` is added" with "a new field `mlTechnique: (any MLTechnique)? = nil` is reserved on `AudioAnalysisService.Options` (per Story 3-3a / ADR-11) and the evaluation path is wired."
  - [x] 3.2: Sweep the rest of Story 4.3's text for stray "method parameter" / "parameter `mlTechnique`" / "via parameter injection" references; rewrite to match the Options-field model.
  - [x] 3.3: Add a "References ADR-11" footnote line at the bottom of Story 4.3's spec.

- [x] Task 4: README cleanup (AC: #5)
  - [x] 4.1: Read current `README.md`. Identify the stale quick-start sample, OGG mention, and 6-vs-7 case count.
  - [x] 4.2: Rewrite the quick-start to use `AudioAnalysisService.analyzeBPM(url:)` and the Options-mutation pattern. Confirm the sample matches `Sources/BoomBoomBoomKit/AudioAnalysisService.swift`'s public surface.
  - [x] 4.3: Remove OGG from any supported-formats list; preserve the existing AVFoundation-supported list (WAV, AIFF, MP3, FLAC, M4A, CAF) per CLAUDE.md PCMBufferReader notes.
  - [x] 4.4: Update `DSPTechnique` case-count reference to 7 (or rephrase to be count-agnostic so future additions don't bit-rot the README). _(Chose count-agnostic phrasing: "closed set, `CaseIterable`".)_
  - [x] 4.5: Add a "Customizing techniques" subsection with the `.clickAugmented` opt-in example.

- [x] Task 5: Validate (AC: #6)
  - [x] 5.1: `make fmt` clean.
  - [x] 5.2: `make lint` no new violations. _(1 TODO violation in LUFSAnalyzer.swift:94 is pre-existing.)_
  - [x] 5.3: `make test` — record final test count (current is 184 from Story 3-3 close-out; this story adds ≥ 3 tests for the mlTechnique slot, target ≥ 187). _(Final: 187 tests in 52 suites, all pass.)_
  - [x] 5.4: `make benchmark` — assert OA300 floors hold byte-for-byte. _(maxConfidence Acc1=57/82, Acc2=73/82 — floors held byte-for-byte.)_
  - [x] 5.5: `make benchmark-giantsteps` — assert GiantSteps floors hold byte-for-byte. _(Strict 2% Acc1=537/661, Acc2=546/661 — floors held byte-for-byte.)_
  - [x] 5.6: `make oracle` — no DAW oracle regression. _(Both oracle suites pass.)_

### Review Findings

_From `bmad-code-review` (2026-04-27, Blind Hunter + Edge Case Hunter + Acceptance Auditor; decisions resolved with Codex gpt-5.5 input)._

**Patch (7) — 4 original + 3 promoted from decision-needed after Codex consult:**

- [x] [Review][Patch] Test function name `mlTechniqueNilProducesIdenticalResults` exercises the **non-nil** path [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:419] — function body sets `withMock.mlTechnique = MockMLTechnique()`. Display string is correct ("non-nil produces results identical to baseline (slot is inert pre-Story-4.3)"); only the Swift identifier lies. Rename to `mlTechniqueNonNilIsIgnoredPreStory43` (or similar).

- [x] [Review][Patch] Doc-comment cross-references use ambiguous "architecture.md" relative path [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:39] — two `architecture.md` files exist (`docs/architecture.md` and `_bmad-output/planning-artifacts/architecture.md`); ADR-11 only lives in the BMad copy. Use the explicit path: `_bmad-output/planning-artifacts/architecture.md` (or pin to the section: "ADR-11 in `_bmad-output/planning-artifacts/architecture.md`").

- [x] [Review][Patch] Test comment cites `architecture.md:480` but line 480 is the unrelated dependency line [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:383] — `architecture.md:480` is `- Depends on \`BoomBoomBoomKit\` (one-way dependency)`. The boundary statement intended is `:482` (`Exports MLTechnique conformances`). Update the citation to `:482` (and consider noting that line `:483`'s "via parameter injection" is itself stale per ADR-11 — see decision-needed item above).

- [x] [Review][Patch] Dev-narrative deferred-stories list mentions Story 4.5 inconsistently with spec AC#4 [_bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md:179, :195] — Completion Notes and Change Log say "4.2/4.4/4.5/4.6 deferred"; spec AC#4 and Risk-guard list (`:47-49`, `:140`) only mention 4.2/4.4/4.6. Verified by grep: only 4.2/4.4/4.6 contain stale `mlTechnique`-as-method-parameter references in `epics.md`. Edit dev-notes to read `4.2/4.4/4.6` (or, if Story 4.5 truly has parameter-style refs, document them — but the current diff does not show any).

- [x] [Review][Patch] **(from D1)** Replace `MockMLTechnique` with a sentinel-returning conformance [Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:384-394] — change `evaluate(...)` to return `(bpm: 999.0, confidence: 1.0)` instead of `nil`. Rationale: a `nil`-returning mock cannot distinguish "field never read" from "field read but abstained"; sentinel BPM/confidence forces a future wired-but-not-Story-4.3 code path to break the existing `bpm == baseline.bpm` assertion. Keep assertion scope limited to `bpm` and `confidence` per user decision (do not widen to `candidates`/`trace`).

- [x] [Review][Patch] **(from D2)** Reconcile architecture.md to ADR-11 (Options-first) and rename sprint-status story slug — Update `_bmad-output/planning-artifacts/architecture.md` lines 74-75, 159, 355-358, 483 to remove "parameter injection" language and align with ADR-11's Options-first model. Lines 355-358 contain a stale code example calling `service.analyzeBPM(url:intensity:mlTechnique:)`; rewrite to use `var opts = AudioAnalysisService.Options()` mutation pattern. Line 483 in "ML package boundary" needs to change from "Consumer passes conformance via parameter injection" to "Consumer passes conformance via `Options.mlTechnique` (per ADR-11)." Plus rename `_bmad-output/implementation-artifacts/sprint-status.yaml:78` story key slug from `4-3-ml-technique-parameter-injection-and-trace-population` to `4-3-ml-technique-slot-wiring-and-trace-population` (matches the epics.md retitle). Per user decision (Codex recommendation): leave epics.md Stories 4.2/4.4/4.6 untouched per AC#4's promotion-time fan-out policy.

- [x] [Review][Patch] **(from D3)** Remove inline reservation comment in `analyzeBPM(url:options:)` [Sources/BoomBoomBoomKit/AudioAnalysisService.swift:141] — Delete the line `// Note: options.mlTechnique slot is reserved (Story 3-3a, ADR-11); the evaluation path lands in Story 4.3. Setting it today is a no-op.` The field doc-comment on `Options.mlTechnique` (`AudioAnalysisService.swift:69-79`) is already authoritative; project-context.md keeps TODO-style future-work comments deliberately lint-visible. The story artifact carries the future-work context.

**Defer (1):**

- [x] [Review][Defer] `MLTechnique.evaluate` tuple-typed return/parameter bypasses Swift `Sendable` enforcement [Sources/BoomBoomBoomKit/DSPTechnique.swift:197-200] — labeled tuples (`(bpm: Double, score: Float)`, `(bpm: Double, confidence: Double)?`) aren't nominal types and so don't participate in `Sendable` checking. Latent issue, NOT introduced by Story 3-3a. Track for post-Story-4.3 follow-up (consider a `MLEvaluation` struct conforming to `Sendable`).

**Dismissed (8):** Strict `==` on `Double` in identical-results test (intentional — DSP determinism is a project invariant); Blind Hunter's `any MLTechnique` Sendable concern (false positive — protocol requires `Sendable` per `DSPTechnique.swift:192-201`); README "supported formats" no longer lists AAC (M4A is the AAC container, technically correct); README `var opts` snippet style (compiles, no defect); Public API table parenthetical wording (taste); Story self-marks all tasks done in same diff (standard BMad close-out flow); `sprint-status.yaml` `last_updated` prose tag (matches existing pattern, not a duplicated header); `mlTechnique` Options copy-Sendable nuance (existential retain on copy is doc-claim precision, not a defect).

## Dev Notes

### Architecture compliance

- **ADR-11 is in force** (`_bmad-output/planning-artifacts/architecture.md`, added in commit `8934f5f`). All new public configuration knobs go on `AudioAnalysisService.Options`. Method parameters on `analyzeBPM` are reserved for required arguments (URL).
- **Public/internal boundary** (architecture.md:455-461): `MLTechnique` is already a public protocol in `Sources/BoomBoomBoomKit/DSPTechnique.swift:192`. The new field's type `(any MLTechnique)?` does NOT promote any internal type. ✅
- **Swift 6 strict concurrency** (architecture.md:62, project-context.md): `MLTechnique` requires `Sendable` (`DSPTechnique.swift:192`). `(any MLTechnique)?` is automatically Sendable. The `Options` struct's `Sendable` conformance is preserved.
- **Demo app rule** (architecture.md:469-473): the demo imports only public API. The mock `MLTechnique` lives in the test target, not in the package — confirmed acceptable per architecture.md:480 ("Mock `MLTechnique` conformance lives in test target, not in ML package").
- **Implicit-nil rule** (project-context.md "Language-Specific Rules"): Swift optionals default to nil. Write `public var mlTechnique: (any MLTechnique)?` (NOT `= nil`).

### Source pointers (verified post-Story-3-3 close-out)

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:39-86` — current public `Options` struct after Story 3-3 close-out. Field-style convention block lives in the doc-comment (lines 35-38).
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:65` — `public var techniqueSet: TechniqueSet?` (the precedent for the new `mlTechnique` field's shape).
- `Sources/BoomBoomBoomKit/DSPTechnique.swift:192-201` — public `MLTechnique` protocol. `Sendable`, has `name: String` and `evaluate(candidates:trace:) -> (bpm:confidence:)?`.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:134-138` — the override resolution helper. `mlTechnique` does NOT participate in this resolution (Story 4.3 owns its evaluation path).
- `_bmad-output/planning-artifacts/architecture.md:202` — ADR-11 entry in the decision summary table. ADR-11 full text lives in the "Public Configuration Surface" subsection.
- `_bmad-output/planning-artifacts/epics.md:823-848` — Story 4.3 spec text to reconcile.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift:204-256` — `TechniqueSetOverrideTests` suite, the structural template for the new mlTechnique tests.

### Field-style convention (post-ADR-11)

Per `Sources/BoomBoomBoomKit/AudioAnalysisService.swift:34-38` and ADR-11 in `architecture.md`:

- **Non-optional `T = .default`** — always-present configuration with a sensible default (`intensity`, `mergeStrategy`, `maxSeconds`, `enableTrace`, `isCancelled`). Apple's house style (`JSONEncoder.outputFormatting`, `URLSessionConfiguration.timeoutIntervalForRequest`).
- **Optional `T?`** — opt-in dependencies, protocol slots, overrides. `nil` carries semantic weight: "use existing default" or "feature inactive." Examples after this story: `onProgress`, `techniqueSet`, `mlTechnique`.

Naming uses the field's domain role; mirror the type only when the role IS the type identity. `mlTechnique: (any MLTechnique)?` is correct because the role IS "the ML technique to consult."

### Cross-story coordination

- **Story 4.3 (`backlog`)**: Task 3 of this story rewrites Story 4.3's epic spec text. The actual code wiring of `mlTechnique` into the pipeline is Story 4.3's responsibility, not this story's.
- **Stories 4.2 / 4.4 / 4.6 (`backlog`)**: No spec edits in this story per the user's elicitation answer (Codex finding #4 / Winston's recommendation: ADR-11 single source of truth + per-story reconciliation at promotion time).
- **Story 5.5 (`backlog`)**: Public API Documentation. This story adds a minimal "Customizing techniques" README subsection that Story 5.5 will later expand. No coordination required — additive.
- **Story 3-3b (`backlog`)**: Trace-key namespacing. Independent of this story; no interaction.
- **benchmark-infra-ablation-parallelism (`backlog`)**: Independent.

### Risk / out-of-scope guards

- **Do NOT** wire `mlTechnique` into `analyzeBPM`'s evaluation path. Story 4.3 owns that.
- **Do NOT** add Story 4.3's `degradationReason`, `effectiveIntensity`, or `maximumSupportedIntensity` field/method (Story 4.2's scope).
- **Do NOT** edit Stories 4.2/4.4/4.6 spec text. ADR-11 governs; per-story reconciliation at promotion time.
- **Do NOT** rename existing public fields (`techniqueSet`, `mergeStrategy`, etc. — those landed in Story 3-3 close-out and are stable).
- **Do NOT** add a `windowSizes` override (Codex finding #2 — explicitly out of scope per user elicitation).
- **Do NOT** change DSP behavior. This is a pure API-surface + documentation story. Any Acc1 or Acc2 delta is a bug.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md] — ADR-11 (Options-first public configuration); public API boundary at lines 455-481.
- [Source: _bmad-output/implementation-artifacts/3-3-click-track-cross-correlation.md] — Decision 1 resolution (techniqueSet override); origin of this story's narrowed scope.
- [Source: _bmad-output/planning-artifacts/epics.md:823-848] — Story 4.3 spec text to reconcile in Task 3.
- [Source: Sources/BoomBoomBoomKit/AudioAnalysisService.swift:34-86] — current public Options struct; the model for the new field.
- [Source: Sources/BoomBoomBoomKit/DSPTechnique.swift:192-201] — public MLTechnique protocol.
- [Source: README.md] — current README to clean up in Task 4.
- [Source: CLAUDE.md] — Architecture section + Design Constraints (currently lists 8 public types: AudioAnalysisService, AnalysisIntensity, CandidateMergeStrategy, DSPTechnique, TechniqueSet, MLTechnique, BPMDiagnosticTrace, ProgressUpdate, plus PCMBufferReader/PCMBufferReaderError); CLAUDE.md is correct as-is — no edit needed.
- [Source: _bmad-output/project-context.md] — Language-Specific Rules: implicit-nil rule (write `public var x: T?` NOT `= nil`); Options struct pattern.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (1M context) — bmad-dev-story workflow.

### Debug Log References

- `make fmt` — clean (no diff after run).
- `make lint` — 1 violation, 0 serious in 30 files (pre-existing TODO in `Sources/BoomBoomBoomKit/LUFSAnalyzer.swift:94`).
- `make test` — `Test run with 187 tests in 52 suites passed after 0.567 seconds.`
- `make benchmark` (OA300, 82 tracks) — `maxConfidence 69.5% 89.0% 57 82` (Acc1=57, Acc2=73; floors 57/73 held byte-for-byte).
- `make benchmark-giantsteps` (661 tracks) — Strict 2%: `Acc1: 81.2% (537/661)`, `Acc2: 82.6% (546/661)` (floors 537/546 held byte-for-byte). MIREX 4%: `Acc1: 84.1% (556/661)`, `Acc2: 85.0% (562/661)`.
- `make oracle` — both suites pass (`full corpus with DAW oracle annotations` + companion).

### Completion Notes List

- **Final test count:** 187 (baseline 184 + 3 new in `MLTechniqueSlotTests`). Target was ≥187; matched exactly.
- **OA300:** Acc1=57/82 (69.5%), Acc2=73/82 (89.0%) under default `maxConfidence` merge. Floors (57/73) held byte-for-byte.
- **GiantSteps (Strict 2%):** Acc1=537/661 (81.2%), Acc2=546/661 (82.6%). Floors (537/546) held byte-for-byte.
- **DAW oracle:** No regression; both suites pass in 2.234 s.
- **No perf-benchmark run** — story is pure API-surface + documentation; no DSP code path changed (`mlTechnique` slot is inert until Story 4.3 lands the wiring), so wall-clock impact is nil. The field doc-comment on `Options.mlTechnique` makes this contract explicit.
- **README sections changed:** Features (line 9 step-count "12-step" → "10-step" + click-correlation mention; line 11 supported-formats list normalized to canonical CLAUDE.md set, OGG and AAC removed); Usage (rewritten to use `Options()` mutation pattern, removed nonexistent `analyzeBPM(url:intensity:mergeStrategy:)` and `analyzeBPM(url:enableTrace:)` overloads); new `### Customizing techniques` subsection with `.clickAugmented` example; Public API table (DSPTechnique count made count-agnostic, TechniqueSet/MLTechnique annotations refreshed, `ProgressUpdate` row added).
- **Stories 4.2 / 4.4 / 4.6 deferred per ADR-11 fan-out policy:** Per the user's elicitation answer (Codex finding #4 / Winston's recommendation), `mlTechnique` parameter-style references in Stories 4.2 (`mlTechnique: nil` in AC text + `maximumSupportedIntensity(mlTechnique:)`), 4.4 (`analyzeBPM()` parameter), 4.6 (`analyzeBPM(mlTechnique:)`) are NOT edited by this story. Single source of truth is ADR-11 in `architecture.md`; per-story reconciliation happens at promotion time (each story's `backlog → ready-for-dev` transition).
- **Mock placement:** `MockMLTechnique` is a `private struct` inline in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` (rather than a separate `MockMLTechnique.swift` file). Both placements are sanctioned by the story; inline keeps the new test surface co-located and avoids growing the test target's file count for a single-use mock.
- **SourceKit stale-index note:** During development, the in-IDE SourceKit diagnostics flagged my new `mlTechnique` field (and pre-existing `techniqueSet`, `clickCorrelationDetail` symbols) as "no member" while the Swift compiler accepted everything cleanly and all 187 tests passed. This is a SourceKit index lag — not a real compile error.

### File List

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — added `public var mlTechnique: (any MLTechnique)?` to `Options` with full doc-comment; updated Options struct doc-comment "Field-style convention" block to list `mlTechnique` and cross-reference ADR-11.
- `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift` — added `private struct MockMLTechnique: MLTechnique` and `@Suite("AudioAnalysisService — MLTechnique Slot") struct MLTechniqueSlotTests` with three tests (`mlTechniqueSlotAcceptsConformance`, `mlTechniqueDefaultsToNil`, `mlTechniqueNilProducesIdenticalResults`).
- `_bmad-output/planning-artifacts/epics.md` — rewrote Story 4.3 (lines 823–848) to use `AudioAnalysisService.Options.mlTechnique` instead of an `analyzeBPM` method parameter; added "References ADR-11" footnote.
- `README.md` — Features step-count + supported-formats fix; rewrote Usage to use `Options()` mutation pattern; added `### Customizing techniques` subsection; refreshed Public API table.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — bumped story `3-3a-public-api-harmonization` from `ready-for-dev` → `in-progress` → `review` and updated `last_updated`.
- `_bmad-output/implementation-artifacts/3-3a-public-api-harmonization.md` — task checkboxes, Dev Agent Record, File List, Change Log, Status (this file).

## Change Log

- 2026-04-26 (Story 3-3a re-author): Re-authored from scratch after Codex (gpt-5.5) returned "Block — re-author" verdict on the original draft. Multi-agent BMad party-mode review (Siri, Winston, Amelia, Bob) confirmed all 10 of Codex's findings; user elicitation answers (8 questions across 2 batches) finalized scope. Status: `ready-for-dev`. Sprint-status entry already present from Story 3-3 close-out commit.
- 2026-04-26 (Story 3-3a implementation, claude-opus-4-7): Implemented all 5 tasks. Reserved `mlTechnique` slot on `Options` with three new `MLTechniqueSlotTests` (187 tests total, +3); reconciled Story 4.3 epic spec to ADR-11 Options-first convention (Stories 4.2/4.4/4.6 deferred per fan-out policy); cleaned README (current API in quick-start, OGG removed, count-agnostic DSPTechnique reference, new "Customizing techniques" subsection). All accuracy floors held byte-for-byte: OA300 Acc1=57/82, Acc2=73/82; GiantSteps Acc1=537/661, Acc2=546/661; DAW oracle no regression. Status: `review`.
- 2026-04-27 (Story 3-3a code-review patches, claude-opus-4-7): Multi-layer code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor) returned 3 decision-needed + 4 patch + 1 defer + 8 dismissed findings. Codex (gpt-5.5) consulted twice: once on the three decisions (recommended sentinel mock, architecture.md+slug fix, comment removal), once on the implementation plan (returned "Approve with revisions" — 5 concrete corrections applied). Applied all 7 patches: P1 test-name correction, P2 doc-comment path disambiguation, P3 architecture.md:480→:482 citation fix, P4 deferred-stories list (drop 4.5), P5 sentinel-returning MockMLTechnique, P6 architecture.md ADR-11 reconciliation (lines 74, 75, 159, 354-358, 483) + sprint-status story slug rename, P7 inline reservation comment removed + story-md cascade. Verification: `make fmt` clean; `make lint` 1 violation (pre-existing TODO); `make test` 187 pass; OA300 Acc1=57/82 (69.5%), Acc2=73/82 (89.0%) byte-for-byte; GiantSteps Strict 2% Acc1=537/661 (81.2%), Acc2=546/661 (82.6%) byte-for-byte; DAW oracle no regression. Status: `done`.
