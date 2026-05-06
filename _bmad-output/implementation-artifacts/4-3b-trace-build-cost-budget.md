# Story 4-3b: Trace-Build Cost Budget + `subBandEnergies` Typed Migration

Status: ready-for-dev
**Depends on:** Story 4.3 (lands the env-gated mock-injected perf gate in `make perf-benchmark` with hard-fail at 1.30x recorded baseline; this story does the empirical trace-cost investigation Codex deferred and tightens the threshold toward measured floor data).
**Promotion gate:** Story 4.3 must be `done` (or `review`) before 4-3b dev work begins. The 4-3b baseline reference is the `make perf-benchmark` mock-on-abstaining run captured at Story 4.3 close (logged in 4-3b Completion Notes).

## Story

As a library author,
I want `BPMDiagnosticTrace` build cost on the mock-on-abstaining hot path investigated and where cheap reduced — replacing Story 4.3's unmeasured 1.10x guess with a measured budget — and the last surviving stringly-keyed trace field (`subBandEnergies: [String: Float]`) migrated to a typed struct per Story 3-3b precedent,
So that `MLTechnique` consumers (Story 4.5 BNNS, Story 4.6 CoreML) do not inherit a compounded structural tax for opting into ML augmentation, the AC #7 perf-gate threshold can be tightened against empirical data rather than aspirational rounding, and the typed-evidence discipline (`project-context.md` §"Banned trace-field shapes") is fully enforced across `BPMDiagnosticTrace`.

## Key Design Decisions

The Project Lead reviews this block BEFORE dev begins. Each decision is load-bearing for at least one acceptance criterion.

1. **Investigation precedes optimization.** Use `xctrace` (Instruments CLI) Time Profiler + Allocations against `analyzeBPM` with `MockMLTechnique(returning: nil)` injected at intensity `.default` to name the top 3 hot functions and top 3 allocation sites. NO optimization edits land before the profile is captured. The profile artifact is committed at `_bmad-output/implementation-artifacts/4-3b-trace-profile.md` (markdown summary referencing the `.trace` bundle).

2. **`subBandEnergies: [String: Float]` migration is the lead hypothesis.** Story 3-3b migrated four trace fields from stringly-keyed dictionaries to typed evidence types (`ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`). `subBandEnergies` survived because its keys (`"kick"`, `"snare"`, `"crack"`, `"hihat"`) appeared closed-set-like but were not migrated. A 4-`Float`-field `SubBandEnergies` struct is the natural shape. Per-write cost: dict insert (string hash + 4 buckets) → struct field assignment (single store). Migration cost is bounded (4 write sites in `BPMAnalyzer.estimateBPM`).

3. **Non-`subBandEnergies` candidates surfaced by profiling.** Winston (party-mode round 2) flagged additional likely hotspots: array copies in `rawCandidates` / `candidatesAfterBoost` snapshots; evidence struct construction in tight loops; possible `enableTrace` branch leaks where construction cost is paid even when the trace is nil-bound. The profile (Task 1) names the actual hotspots; this story does NOT presume them.

4. **Threshold tightening is measured, not aspirational.** Replace Story 4.3's 1.30x `make perf-benchmark` threshold with `ceil((post_opt_ratio + 0.10) / 0.05) * 0.05` (round-up to nearest 0.05). If structural floor is 1.15x post-optimization → threshold becomes 1.25x. If floor is 1.10x → threshold becomes 1.20x. No round-number thresholds without empirical justification. The new value is recorded both in `PerformanceBenchmarkTests.swift` and in the Story 4.3 Change Log via a back-edit (the perf-gate AC reads "see Story 4-3b for the empirically-tightened threshold").

5. **Pipeline correctness invariant: zero behavioral DSP changes.** All `BPMAnalyzer` and `LUFSAnalyzer` outputs must remain byte-identical to Story 4.3's snapshot at `_bmad-output/implementation-artifacts/4-3-regression-snapshot.json` for `mlTechnique=nil` callers. Trace shape changes do not propagate into the public `AudioAnalysisResult` surface (the trace is internal to the BPM pipeline; consumers go through `BPMDiagnosticTrace`). The byte-identity test (`MetadataCorroborationTests.disabledPolicy`) holds across this story unchanged.

6. **`subBandEnergies` ABI break is permitted under pre-1.0 / no-BC.** `BPMDiagnosticTrace` is public, so its field types are part of the public surface. Renaming/retyping `subBandEnergies` from `[String: Float]` to `SubBandEnergies` is a breaking change for any external reader. Pre-1.0 framing accepts this; the Change Log records the break. No back-compat shims, no deprecated accessor.

7. **Out-of-scope guards.** Do NOT modify `MLTechnique` protocol shape, `MLEvaluation` struct, `AudioAnalysisService` public API, `EnsembleCombiner`/internal `combine` helper, `MetadataCorroborator`, or any other typed-evidence struct from Story 3-3b. The investigation may surface concerns in those areas; they go to `deferred-work.md`, not to this story.

8. **Profile artifact reproducibility.** `_bmad-output/scripts/dnb-triplet-baseline.swift` precedent applies: the `xctrace` invocation and post-processing pipeline used to generate `4-3b-trace-profile.md` are committed at `_bmad-output/scripts/profile-trace-build-cost.sh` (or `.swift`) so Story 4.5/4.6 authors can re-run against post-optimization or post-real-model state.

## Background

Story 4.3 wired the `MLTechnique` slot and surfaced an empirical fingerprint:

- `BPMDiagnosticTrace` construction adds **~22% wall-clock per `analyzeBPM` call**, constant across intensities `.fastest` (~9 ms baseline → ~11 ms with mock) and `.default` (~59 ms baseline → ~72 ms with mock). Per-call overhead = 2 ms → 13 ms scaling with pipeline depth.
- The constant ratio across two very different intensities is a fingerprint of structural cost (trace allocation/writes per pipeline stage), not noise, not implementation sloppiness.

Codex finalized Story 4.3 (party-mode 2026-05-05) with **C-modified**: drop the unit-test 1.10x ratio gate, move enforcement to env-gated mock injection in `PerformanceBenchmarkTests.swift` with hard-fail at **1.30x** recorded baseline, file a follow-up story (this one) to do the empirical investigation that the Story 4.3 spec author skipped.

The 22% structural cost is load-bearing for Story 4.5 (BNNS conformance) and Story 4.6 (CoreML conformance). Real ML conformances will add their own cost on top of this baseline; the trace-build tax compounds. This story:

- Captures the profile so future ML authors know what they're paying for.
- Migrates `subBandEnergies` (Winston's lead hypothesis from party-mode round 2) — the last surviving stringly-keyed trace field, banned by `project-context.md` §"Banned trace-field shapes" anti-pattern (1).
- Applies profile-named optimizations where reduction is cheap and correctness-preserving.
- Tightens the perf-gate threshold to a measured floor + 10% headroom.

The story is intentionally scoped to investigation + targeted reductions + threshold tightening. Larger refactors (e.g., making the trace lazy, splitting per-stage trace fields into separate evidence types, or reducing the number of trace writes) are deferred to a follow-up story if the profile surfaces them.

## Acceptance Criteria

1. **Profile artifact captured (AC #1).**

   **Given** Story 4.3 is `done` and `make perf-benchmark` with mock injection (Story 4.3 plumbing) is operational
   **When** Task 1 runs against `intensity = .default` on a 30 s click-track fixture with `MockMLTechnique(returning: nil)` injected
   **Then** `_bmad-output/implementation-artifacts/4-3b-trace-profile.md` exists with:
   - Markdown summary table naming top 3 hot functions in `BPMAnalyzer.estimateBPM` (when `enableTrace=true`) — function name, % CPU, sample count.
   - Markdown summary table naming top 3 allocation sites — call site, byte total, count total.
   - Reference to the `.trace` bundle path (the `.trace` file is gitignored — large; the markdown is the committed artifact).
   - The reproducibility recipe (`xctrace` invocation, post-processing) committed at `_bmad-output/scripts/profile-trace-build-cost.sh`.

2. **`subBandEnergies` typed migration (AC #2).**

   **Given** `BPMDiagnosticTrace.subBandEnergies: [String: Float]` at `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:32`
   **When** Story 4-3b ships
   **Then** the field is replaced with `subBandEnergies: SubBandEnergies` (or `SubBandEnergies?` — author judgement; if non-optional, defaults to `.zero`).
   **And** `SubBandEnergies` is a public `Sendable, CustomStringConvertible` struct with 4 `Float` fields: `kick`, `snare`, `crack`, `hihat`.
   **And** all 4 write sites in `BPMAnalyzer.estimateBPM` are updated to use field assignment.
   **And** `grep -nE 'subBandEnergies\[|\.subBandEnergies\.keys' Sources/ Tests/` returns zero matches post-migration.
   **And** Story 3-3b audit recipes A-E (see `.claude/skills/bpm-diagnostic-trace/SKILL.md`) return zero matches against `Sources/` and `Tests/`.
   **And** `description` of `SubBandEnergies` follows the Story 3-3b shape: `"SubBandEnergies(kick: <f>, snare: <f>, crack: <f>, hihat: <f>)"`.

3. **Profile-named optimizations applied or documented (AC #3).**

   **Given** the Task 1 profile names ≥1 hotspot beyond `subBandEnergies`
   **When** Task 3 runs
   **Then** for each named hotspot, EITHER:
   - The hotspot is optimized (e.g., `reserveCapacity` on a known-bounded array, struct copy elision, lazy init) AND the per-edit `make perf-benchmark` mock-injected delta is recorded in `4-3b-trace-profile.md` "Optimizations applied" section, OR
   - The hotspot is documented as irreducible without correctness changes (e.g., "reducing this would skip a trace write Story 4.5 needs"), with the constraint named in `4-3b-trace-profile.md` "Hotspots NOT optimized" section.
   **And** no hotspot is silently skipped.

4. **Measured threshold update in Story 4.3 perf gate (AC #4).**

   **Given** `make perf-benchmark` with mock injection re-runs against the optimized pipeline
   **When** Task 4 captures the post-optimization ratio
   **Then** `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` threshold is updated to `ceil((measured_post_opt_ratio + 0.10) / 0.05) * 0.05`.
   **And** the new value is recorded in:
   - The benchmark file's threshold constant + assertion message.
   - Story 4.3 Change Log (back-edit) referencing this story's profile artifact + Completion Notes.
   - Story 4-3b Completion Notes with the exact pre-opt and post-opt ratios.
   **And** if no optimizations land (Task 3 surfaces only irreducible hotspots), the threshold STAYS at 1.30x and Completion Notes document why no tightening occurred.

5. **Default-disabled byte-identity preserved (AC #5).**

   **Given** Story 4.3's regression snapshot at `_bmad-output/implementation-artifacts/4-3-regression-snapshot.json`
   **When** Story 4-3b ships
   **Then** `make benchmark` and `make benchmark-giantsteps` with default `Options()` (i.e., `mlTechnique=nil`) produce numbers byte-identical to the snapshot:
   - OA300 Acc1 = 58/82, Acc2 = 74/82 (or strict-equality against snapshot).
   - GiantSteps Acc1 = 537/661, Acc2 = 546/661.
   - Per-track failure subset matches `4-3-regression-snapshot.json` `tracks_failure_subset` array element-wise.
   **And** `MetadataCorroborationTests.disabledPolicy` bitPattern test continues to pass (validates the byte-identity contract via `runPreCorroborationPipeline`).
   **And** if any track shifts, HALT — investigate before tightening or relaxing.

6. **Standard gating checklist (AC #6).**

   **Given** `project-context.md` §"Build verification" gating discipline
   **When** run pre-merge
   **Then** all gates pass:
   - `make fmt` — clean (zero diff against staged changes).
   - `make lint` — single pre-existing `LUFSAnalyzer.swift:94` TODO baseline only.
   - `make test` — full suite passes; post-Story-4.3 `@Test(` count band `[318, 322]` extended to `[318, 324]` if 4-3b adds new tests for `SubBandEnergies` (record exact count in Completion Notes).
   - `make benchmark` — OA300 Acc1 ≥ 57/82, Acc2 ≥ 73/82 (asserted floors) AND strict-equality vs Story 4.3 snapshot (AC #5).
   - `make benchmark-giantsteps` — Acc1 ≥ 537/661, Acc2 ≥ 546/661 AND strict-equality vs snapshot.
   - `make ablation` — `.optimal` Acc1 ≥ 55/82 (unit-test-locked invariant from Story 3-2).
   - `make perf-benchmark` — mock-on-abstain ratio passes the (possibly-tightened) threshold.
   **And** `4-dnb-triplet-targets.json` `current_predicted_bpm` is refreshed via `_bmad-output/scripts/dnb-triplet-baseline.swift` recipe and committed in this story's diff if any of the 4 named DnB tracks shifted post-optimization.

## Tasks / Subtasks

- [ ] **Task 1: Capture the trace-build cost profile (AC: #1)**
  - [ ] 1.1: Confirm Story 4.3 is `done` (or at minimum `review` with `PerformanceBenchmarkTests.swift` mock-injection plumbing landed). Verify mock-injection invocation recipe in Story 4.3 Completion Notes.
  - [ ] 1.2: Write `_bmad-output/scripts/profile-trace-build-cost.sh` invoking `xctrace record --template "Time Profiler" --launch -- swift test --filter <fixture-test>` (or equivalent). Reuse the 30 s click-track fixture from `MLTechniquePerfTests.swift`.
  - [ ] 1.3: Run the script. Export `xctrace export --type profile --output ...` (or open in Instruments) and pull top 3 hot functions + top 3 allocation sites.
  - [ ] 1.4: Write `_bmad-output/implementation-artifacts/4-3b-trace-profile.md` with markdown tables for both. Reference the `.trace` bundle path (gitignored). Add hypotheses section listing optimization candidates per hotspot.
  - [ ] 1.5: Add `*.trace/` and `*.tracetemplate` to `.gitignore` if not already present.

- [ ] **Task 2: Migrate `subBandEnergies` to typed struct (AC: #2)**
  - [ ] 2.1: Define `public struct SubBandEnergies: Sendable, CustomStringConvertible` in `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` (placed in the `// MARK: - Trace Evidence Types (Story 3-3b)` section). Fields: `public let kick: Float`, `public let snare: Float`, `public let crack: Float`, `public let hihat: Float`. Init: `public init(kick: Float, snare: Float, crack: Float, hihat: Float)`. Description: `"SubBandEnergies(kick: \(kick), snare: \(snare), crack: \(crack), hihat: \(hihat))"`.
  - [ ] 2.2: Add `public static let zero = SubBandEnergies(kick: 0, snare: 0, crack: 0, hihat: 0)` for default-initialization sites.
  - [ ] 2.3: Replace `BPMDiagnosticTrace.subBandEnergies: [String: Float] = [:]` with `subBandEnergies: SubBandEnergies = .zero`. Decide optionality (author judgement); document in Dev Notes if optional.
  - [ ] 2.4: Update all 4 write sites in `Sources/BoomBoomBoomKit/BPMAnalyzer.estimateBPM` — replace `trace.subBandEnergies["kick"] = ...` (etc.) with field-store assignment. Construct a fresh `SubBandEnergies(kick:snare:crack:hihat:)` once per window then assign, OR mutate fields if struct is `var`-bound — author judgement.
  - [ ] 2.5: Audit: `grep -nE 'subBandEnergies\[|\.subBandEnergies\.keys|\.subBandEnergies\.values' Sources/ Tests/` returns zero matches.
  - [ ] 2.6: Audit: Story 3-3b recipes A-E from `.claude/skills/bpm-diagnostic-trace/SKILL.md` return zero matches.
  - [ ] 2.7: Add `SubBandEnergiesTests` `@Suite` in `Tests/BoomBoomBoomKitTests/BPMDiagnosticTraceTests.swift` (or new file) covering: zero default, init round-trip, `description` shape.

- [ ] **Task 3: Apply profile-named optimizations (AC: #3)**
  - [ ] 3.1: For each hotspot named in Task 1.4, propose a targeted edit. Common candidates: `reserveCapacity` on `rawCandidates` / `candidatesAfterBoost` / `acfTopLags` / `tempogramTopBPMs` / `fusedTopBPMs` / `tps2TopBPMs` (all `[(Int, Float)]` or `[(Double, Float)]`); struct copy elision (mutate-in-place on `var trace`); lazy initialization (skip writes when downstream is no-op).
  - [ ] 3.2: Apply edits one at a time. After each, run `make perf-benchmark` with mock injection. Record the per-edit delta in `4-3b-trace-profile.md` "Optimizations applied" section.
  - [ ] 3.3: For any hotspot that cannot be reduced without correctness changes (e.g., a trace write Story 4.5 BNNS needs), document the constraint in `4-3b-trace-profile.md` "Hotspots NOT optimized" section. Cite the consumer story.
  - [ ] 3.4: After all edits, run `make test` to confirm correctness (no regressions in unit tests).

- [ ] **Task 4: Re-measure and tighten threshold (AC: #4)**
  - [ ] 4.1: Run `make perf-benchmark` with mock injection (full corpus). Record the post-optimization ratio in Completion Notes (e.g., "post-opt ratio = 1.14x").
  - [ ] 4.2: Compute new threshold: `ceil((measured + 0.10) / 0.05) * 0.05`. Example: 1.14x → ceil(1.24/0.05)*0.05 = 1.25x.
  - [ ] 4.3: Update threshold constant + assertion message in `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` (the env-gated mock-injected test added by Story 4.3).
  - [ ] 4.4: Back-edit Story 4.3 Change Log: append a note "2026-MM-DD (Story 4-3b): perf-gate threshold tightened to <new>x against measured floor <ratio>x; profile artifact at `_bmad-output/implementation-artifacts/4-3b-trace-profile.md`."
  - [ ] 4.5: If no optimizations landed (Task 3 surfaced only irreducible hotspots), KEEP threshold at 1.30x. Document the no-tightening outcome explicitly in Completion Notes.

- [ ] **Task 5: Validate (AC: #5, #6)**
  - [ ] 5.1: `make fmt`, `make lint` — clean.
  - [ ] 5.2: `make test` — full suite passes. Record `@Test(` count delta vs Story 4.3's pinned 320 (band `[318, 324]`).
  - [ ] 5.3: `make benchmark` — OA300 Acc1=58/82, Acc2=74/82 (strict-equality vs Story 4.3 snapshot). Verify per-track failure subset element-wise.
  - [ ] 5.4: `make benchmark-giantsteps` — Acc1=537/661, Acc2=546/661 (strict-equality).
  - [ ] 5.5: `make ablation` — `.optimal` Acc1 ≥ 55/82.
  - [ ] 5.6: `make perf-benchmark` (mock-injected) — assertion holds against new threshold.
  - [ ] 5.7: Refresh `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` `current_predicted_bpm` for the 4 named DnB triplets via `_bmad-output/scripts/dnb-triplet-baseline.swift` recipe. If any shift, capture as `4-dnb-triplet-targets-rev2.json` (per AC #8 toolchain-change refresh policy from Story 4.3).
  - [ ] 5.8: Sprint-status update + story-status transition handled in workflow Step 9 close-out.

## Dev Notes

### Architecture compliance

- **Banned trace-field shapes** (`project-context.md` §"Banned trace-field shapes"): `[String: Float]` keyed on a closed set is anti-pattern (1) — collision risk + string-hashing cost. `subBandEnergies` is the last surviving instance after Story 3-3b. This story closes that gap.
- **Story 3-3b typed-evidence pattern** is the migration template — see `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:139-283` for `ClickCorrelationEntry`, `HarmonicRatioEvidence`, `SubBandVoteEvidence`, `DurationHintEvidence`, `BarCandidate`. All five conform to `Sendable, CustomStringConvertible`. `SubBandEnergies` follows the same shape.
- **AC #6 byte-identity (Story 4.3)** is the cross-story regression-protection contract. Trace-shape changes must not affect `mlTechnique=nil` output (which doesn't read the trace anyway, but the regression test exists to prove it).
- **Pre-1.0, no-BC framing** (`project-context.md` §"Public API Discipline (pre-1.0)") permits the `subBandEnergies` type change as a breaking change. No back-compat shims.

### Source pointers (verified at story authoring 2026-05-05)

- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:32` — `subBandEnergies: [String: Float]` definition. Replaced by Task 2.3.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:139-283` — Story 3-3b typed-evidence section. Task 2.1 places `SubBandEnergies` here.
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — write sites for `trace.subBandEnergies["kick"|"snare"|"crack"|"hihat"]` (4 sites, all in step 3 mel-spectrogram onset detection). Updated by Task 2.4.
- `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` — env-gated mock-injection assertion landed by Story 4.3. Task 4.3 updates the threshold constant.
- `_bmad-output/implementation-artifacts/4-3-regression-snapshot.json` — Story 4.3's byte-identity baseline. AC #5 cross-references.

### Why migrate `subBandEnergies` even if profile shows it's not the dominant hotspot

Three reasons survive even if Task 1 names a different top-1 hotspot:

1. **Anti-pattern (1) elimination.** `project-context.md` §"Banned trace-field shapes" lists `[String: Float]` keyed by closed-set strings as banned. Migration is required for typed-evidence discipline regardless of perf delta.
2. **Story 3-3b precedent debt.** Five other dictionary fields migrated in Story 3-3b; `subBandEnergies` survived only because keys looked closed-set-but-not-quite. Closing the gap is mechanical and cheap.
3. **Forward-compat for Story 4.5/4.6.** BNNS / CoreML feature engineering reads `subBandEnergies` to build per-band features. A typed struct gives the conformance author auto-completion + compile-time checks vs. dict-key typos.

If profile shows `subBandEnergies` is not the perf hotspot, migration still happens — but the `4-3b-trace-profile.md` "Optimizations applied" section honestly records "subBandEnergies migration: -0.5% perf, kept for typed-evidence discipline."

### Risk / out-of-scope guards

- **Do NOT** modify `MLTechnique` protocol shape, `MLEvaluation` struct, `AudioAnalysisService` public API, the internal `combine` helper, `MetadataCorroborator`, `MetadataCorroborationInput`, `MetadataPolicy`, `CandidateMergeStrategy`, `VotingPolicy`, `LUFSAnalyzer`, or any of the 5 typed-evidence structs from Story 3-3b. Concerns there → `deferred-work.md`.
- **Do NOT** introduce new `MLEvaluation` fields. Per Story 4.3 DD #2 + Epic 4 planning session 2026-05-04, fields land per-story when a downstream consumer surfaces.
- **Do NOT** make the trace lazy. Profile-driven optimization is in scope; architectural refactors (lazy trace, trace splitting) are deferred.
- **Do NOT** modify any DSP correctness behavior. The byte-identity gate (AC #5) is the regression contract.
- **Do NOT** change `BPMDiagnosticTrace.subBandEnergies` to `Sendable & Hashable` (or other extra protocols) unless a named consumer surfaces. Stick to `Sendable, CustomStringConvertible` per Story 3-3b shape.
- **Do NOT** add `subBandEnergies` to `MLEvaluation` or any other public-API surface beyond `BPMDiagnosticTrace`.
- **Do NOT** add new env-gated `@Test`s to `BoomBoomBoomKitBenchmarkTests` for snapshot capture. The existing Story 4.3 mock-injection plumbing is all that's needed.

### Apple-platform notes

- **`xctrace` CLI** — `man xctrace` for templates; `Time Profiler` and `Allocations` are the relevant ones. The `.trace` bundle is large (multi-MB); commit only the markdown summary.
- **`SubBandEnergies` `Sendable` conformance** — public struct with all-`Sendable` storage (`Float`); explicit `: Sendable` declaration required per SE-0302 ("Public non-frozen structs do NOT get implicit conformance").
- **No new framework imports** — `SubBandEnergies` lives in `BPMDiagnosticTrace.swift` which imports `Foundation` only. No `Accelerate` / `AVFoundation` needed.

### Previous Story Intelligence

**Story 4.3** — five load-bearing learnings:

1. **`make perf-benchmark` mock injection plumbing** is the venue for the Story 4-3b threshold update. The plumbing landed in Story 4.3 Task 6.5+ (post-Codex finalization). Reuse verbatim.
2. **22% structural ratio is constant across intensities** — fingerprint of per-stage trace writes. Story 4-3b's profile must explain this fingerprint, not just shave the top.
3. **AC #6 byte-identity holds** — `mlTechnique=nil` is unchanged. Story 4-3b inherits this contract.
4. **`MockMLTechnique(returning: nil)`** is the canonical no-op mock in `Sources/BoomBoomBoomKitTestSupport/MockMLTechnique.swift`. Reused for all perf measurement.
5. **Story 4.5 / 4.6 will be the first real ML consumers.** Their perf budget compounds on top of the 4-3b-tightened floor. Document the floor clearly so future authors have a starting point.

### References

- [Source: _bmad-output/implementation-artifacts/4-3-ml-technique-slot-wiring-and-tuple-to-struct-migration.md] — Story 4.3 spec; AC #7 second-gate amendment (post-Codex).
- [Source: _bmad-output/implementation-artifacts/3-3b-trace-key-namespacing.md] — typed-evidence migration precedent.
- [Source: _bmad-output/implementation-artifacts/4-3-regression-snapshot.json] — byte-identity baseline.
- [Source: _bmad-output/scripts/dnb-triplet-baseline.swift] — `current_predicted_bpm` refresh recipe.
- [Source: _bmad-output/project-context.md §"Banned trace-field shapes"] — anti-pattern (1) `[String: Float]` keyed by closed-set.
- [Source: _bmad-output/project-context.md §"Public API Discipline (pre-1.0)"] — no-BC framing.
- [Source: .claude/skills/bpm-diagnostic-trace/SKILL.md] — typed-evidence pattern + audit recipes A-E.
- [Source: Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift:32,139-283] — current dict field + typed-evidence section.
- [Source: Sources/BoomBoomBoomKit/BPMAnalyzer.swift] — 4 write sites.
- [Apple Docs: xctrace](https://developer.apple.com/documentation/xcode/xctrace) — Instruments CLI.
- [SE-0302 Sendable](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) — public-struct explicit-conformance rule.

## Dev Agent Record

### Agent Model Used

_(populated during dev)_

### Debug Log References

_(populated during dev)_

### Completion Notes List

_(populated during dev)_

### File List

_(populated during dev)_

## Change Log

- 2026-05-05 (Story 4-3b creation): Filed as the trace-build-cost investigation follow-up to Story 4.3 per Codex finalization (party-mode 2026-05-05) of the AC #7 second-gate HALT. Story 4.3 ships the perf gate at 1.30x recorded-baseline in `make perf-benchmark` venue against an unmeasured guess; Story 4-3b does the empirical investigation, migrates `subBandEnergies: [String: Float]` to typed struct (Story 3-3b precedent; closes anti-pattern (1) gap), applies profile-named optimizations, and tightens the threshold against measured floor data. Eight Key Design Decisions captured at the top: (1) investigation precedes optimization; (2) `subBandEnergies` migration is lead hypothesis; (3) profile names other candidates; (4) measured threshold tightening; (5) DSP byte-identity invariant; (6) ABI break permitted under pre-1.0; (7) explicit out-of-scope guards; (8) profile reproducibility recipe committed. Six ACs cover profile capture (#1), `subBandEnergies` migration (#2), profile-driven optimization (#3), threshold update (#4), byte-identity preservation (#5), standard gating (#6). Status: `ready-for-dev`.
