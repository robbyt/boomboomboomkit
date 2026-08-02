# Story 12.1: Consumer-specifiable tempo search range

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a consumer integrating BoomBoomBoomKit into a drum-and-bass application,
I want to constrain the tempo search range at the input,
so that the detector stops reporting 140 for a 70 BPM track without my having to train or supply a model.

**Covers:** FR-53 (tempo search range consumer-specifiable), FR-55 (per-band and per-genre measurement against the `AccuracyFloorTests` fixtures).

**Explicitly NOT in this story:** FR-54 / FR-54a, the style-conditioned prior. Its classifier is an unscoped second model the PRD does not build; Story 12.2 decides whether it is scoped, deferred, or rejected. Do not add style conditioning here.

## Key Design Decisions

**DD1 — The "four bounds" are two pairs with different semantics and different blast radii.** Do not treat them as one range.

| Pair | Values | Role |
|---|---|---|
| `minBPM` / `maxBPM` (`BPMAnalyzer.swift:71,74`) | 40 / 250 | **Candidate scan range.** Bounds which tempi the ACF/tempogram search generates at all. |
| `perceptualMinBPM` / `perceptualMaxBPM` (`BPMAnalyzer.swift:118,119`) | 60.0 / 200.0 | **Octave-normalization window.** Consumed by `rangeNormalize`, which folds a BPM by doubling/halving until it lands inside. |

Expose and document them as two separate concepts. A DnB consumer wanting "don't report 70" is asking about the *perceptual* pair; a consumer wanting to detect a 30 BPM ambient track is asking about the *scan* pair.

**DD2 — `rangeNormalize` is not private to the DSP spine; it is the ensemble octave-fold authority.** `AudioAnalysisService.foldEnsembleBPM` calls it at three sites (`AudioAnalysisService.swift:934, :996, :1041`) to fold ML-winner BPMs under `.mlOnly` / `.highestConfidence`. Moving the perceptual window therefore changes ensemble output too, not only DSP output. Any test that pins ML-win BPM values is a regression surface.

**DD3 — The perceptual pair carries a hard invariant: `perceptualMax >= 2 * perceptualMin`.** `rangeNormalize` (`BPMAnalyzer.swift:2107`) is two *sequential* loops, not one:

```swift
while result < perceptualMinBPM { result *= 2.0 }
while result > perceptualMaxBPM { result /= 2.0 }
```

With a window narrower than one octave the second loop undoes the first and never re-checks. Concretely: min 100, max 150, input 160 returns **80** — below the stated minimum, silently. This does not hang; it violates the function's documented contract. Enforce the invariant at `Options` normalization time.

**DD4 — Invalid input normalizes, it does not throw.** Follow the `votingThreshold` precedent (`AudioAnalysisService.swift:260`): silently clamp, normalize NaN and infinity, document the behaviour on the property. `BPMAnalyzer` and `LUFSAnalyzer` never throw — that is a project invariant, not a preference.

**DD5 — Opt-in by default, byte-identical when untouched.** NFR-11 makes DSP-only byte-identity a hard contract for this epic. Default `Options` must produce bit-identical output to the pre-story pipeline.

**DD6 — This story inherits a covenant, not just a lever.** Epic 12 took Epic 13's charter items 1 and 2 on 2026-08-01. Item 1's sequencing rule came with it: *do not pre-commit a DSP-path change before the `resolveOctaveAmbiguity` ceiling sweep runs.* Either run the sweep first or retire the rule in writing with a stated reason. Silently dropping it is not an option — Epic 12 could not take the property and evict the covenant.

## Acceptance Criteria

1. **Given** Epic 12 inherited Epic 13's do-not-pre-commit rule with charter item 1,
   **When** the story begins,
   **Then** the `resolveOctaveAmbiguity` ceiling sweep runs first and its per-threshold OA300 + GiantSteps results are recorded in the story's Completion Notes,
   **And** if the sweep is skipped instead, the inherited rule is retired in writing with a stated reason.

2. **Given** the four bounds are `private static let` on `BPMAnalyzer` and unreachable from `Options` (FR-53),
   **When** they become consumer-specifiable,
   **Then** both pairs are reachable through `AudioAnalysisService.Options` per ADR-11 — non-optional fields with property-level defaults, mutated rather than threaded as `analyzeBPM` parameters,
   **And** the scan pair and the perceptual pair are separate, separately documented fields (DD1),
   **And** every new public type is `Sendable`.

3. **Given** default `Options`,
   **When** `analyzeBPM` runs on any fixture,
   **Then** output is byte-identical to the pre-story pipeline — `Double.bitPattern` equality on `bpm` and `confidence`, element-wise on `candidates` (NFR-11),
   **And** a paired byte-equality opt-out test ships with the story, following the precedent in `Tests/BoomBoomBoomKitTests/AudioAnalysisServiceTests.swift`.

4. **Given** an invalid range — `min >= max`, non-finite, or outside the `30...300` envelope,
   **When** `Options` carries it,
   **Then** the value is normalized following the `votingThreshold` precedent (silently clamped; NaN and infinity normalized) rather than throwing,
   **And** the normalization is documented on the property.

5. **Given** a perceptual window narrower than one octave (`perceptualMax < 2 * perceptualMin`),
   **When** `Options` carries it,
   **Then** it is normalized to satisfy `perceptualMax >= 2 * perceptualMin` before reaching `rangeNormalize` (DD3),
   **And** a test pins the concrete case: min 100, max 150, input 160 must not return a value below the effective minimum.

6. **Given** `rangeNormalize` is also the ensemble octave-fold authority via `foldEnsembleBPM` (DD2),
   **When** the perceptual pair is moved from its default,
   **Then** the effect on `.mlOnly` and `.highestConfidence` ensemble output is exercised by at least one test,
   **And** the story's Dev Notes record that this seam was considered rather than discovered later.

7. **Given** the four `AccuracyFloorTests` known-failure fixtures,
   **When** a perceptual window excluding the erroneous octave is supplied,
   **Then** `Meta_Man` (92 → 182), `Meta_Man_La_Noche_Digital_` (96 → 191.76) and `Submerged_Lament` (70 → 140.12) resolve within tolerance,
   **And** `robbyt_x-ray-120s` is **not** expected to resolve — it is a 1.5047 two-thirds relation, not an octave error, so the target set is three fixtures, not four (FR-55),
   **And** `AccuracyFloorTests.swift:126` already records it as `triplet-related` and is left unchanged.

8. **Given** this is an accuracy-affecting change (NFR-14),
   **When** the story lands,
   **Then** a per-track impact report ships with per-band and per-genre breakdown, following the `make click-impact-report` schema precedent,
   **And** the four unconditional corpus floors hold: OA300 Acc1 ≥ 57/82 and Acc2 ≥ 73/82, GiantSteps Acc1 ≥ 537/661 and Acc2 ≥ 546/661.

## Tasks / Subtasks

- [ ] **Task 1 — Run the inherited ceiling sweep** (AC: #1)
  - [ ] Sweep the hand-tuned `0.3` / `0.5` `resolveOctaveAmbiguity` thresholds on an OA300 dev slice; report OA300 holdout + GiantSteps once
  - [ ] Record per-threshold results in Completion Notes; if skipping, write the retirement rationale instead
- [ ] **Task 2 — Read before writing** (AC: #2, DD1, DD2)
  - [ ] Read `BPMAnalyzer.swift` around `:71`, `:74`, `:118`, `:119`, `:2107` and every call site of all four constants
  - [ ] Read `AudioAnalysisService.swift` `foldEnsembleBPM` and its three call sites (`:934`, `:996`, `:1041`)
  - [ ] Enumerate which pipeline steps consume the scan pair versus the perceptual pair; record in Dev Notes
- [ ] **Task 3 — Options surface** (AC: #2, #4, #5)
  - [ ] Add the two pairs to `AudioAnalysisService.Options` per ADR-11, `Sendable`, property-level defaults matching today's values exactly
  - [ ] Implement normalization: finite-first, clamp to `30...300`, enforce `min < max`, enforce `perceptualMax >= 2 * perceptualMin`
  - [ ] Thread through to `BPMAnalyzer.Options` (internal, memberwise init retained)
- [ ] **Task 4 — Byte-identity protection** (AC: #3)
  - [ ] Paired opt-out test asserting `bitPattern` equality on `bpm`, `confidence`, and element-wise `candidates` at default `Options`
  - [ ] If test code would mirror production logic, expose a shared `static` helper instead of hand-replicating (precedent: `runPreCorroborationPipeline`)
- [ ] **Task 5 — Ensemble seam coverage** (AC: #6)
  - [ ] Test that a moved perceptual window changes `.mlOnly` fold output as expected
- [ ] **Task 6 — Fixture measurement** (AC: #7)
  - [ ] Exercise the three octave fixtures under a DnB-appropriate window; assert resolution
  - [ ] Assert `robbyt_x-ray-120s` remains a known failure; do **not** edit its label
- [ ] **Task 7 — Impact report + gating gauntlet** (AC: #8)
  - [ ] Env-gated per-track impact report with per-band and per-genre breakdown
  - [ ] `make fmt` → `make lint` → `make test` → `make benchmark` → `make benchmark-giantsteps`; record exact integer counts

## Dev Notes

**Read the files before changing them.** Story 12.1's own acceptance criteria were corrected during creation because the epic AC had inverted FR-55 — it claimed `AccuracyFloorTests.swift:126` mislabels the triplet fixture as an octave error. It does not; it already says `triplet-related: reports ~115.6, two-thirds of 174 (3:2)`. Acting on the uncorrected AC would have changed correct code. Treat every cited line number as a claim to verify.

**Architecture coverage for Epic 12 is absent.** `architecture.md` is dated 2026-05-25 against the prior PRD and covers Epics 6-11 only. There is no ADR for these bounds beyond ADR-11's general Options-first rule. Design the surface deliberately and declare it in the story rather than discovering it in review — an internal-to-public promotion requires a named story spec, and this is it.

**Project invariants that bind here** (from `project-context.md`):
- Analyzers are value types with `static` methods. No instantiation, no lifecycle.
- `BPMAnalyzer` and `LUFSAnalyzer` **never throw**. Return nil for no-result. Do not add error types without an explicit design decision.
- Implicit nil — never write `var x: T? = nil`.
- Pipeline step numbers are stable identifiers and never renumber.
- All bulk numeric work through vDSP; loops over *control flow* are fine, loops over sample arrays are not.
- `DSPTechnique.allCases.count == 8` and `TechniqueSet.allDSPCombinations().count == 256` are unit-test-locked. **This story adds no `DSPTechnique` case** — a tempo range is not a DSP technique and adding one would silently break the 256-combination ablation matrix.

**The single-window Acc1 ceiling on OA300 is 55/82 and technique-tuning is at saturation.** Default `Options` reaches 58/82 through multi-window aggregation, merge, and metadata corroboration. This story operates on a different axis (input constraint), which is why it is viable where another `DSPTechnique` case would not be.

### Project Structure Notes

- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — UPDATE, the public `Options` surface
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — UPDATE, the four constants and their call sites
- `Tests/BoomBoomBoomKitTests/` — NEW byte-identity and normalization tests
- `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift` — READ ONLY for the label; may gain assertions
- Test utilities belong in `Sources/BoomBoomBoomKitTestSupport/`, not the test target

Everything here ships to `main`. No `_bmad-output/` path is touched by the implementation.

### References

- [Source: `_bmad-output/planning-artifacts/epics.md#Story 12.1`]
- [Source: `prd.md:126` FR-53 · `prd.md:130` FR-55 · `prd.md:392` NFR byte-identity · `prd.md:395` impact report]
- [Source: `BPMAnalyzer.swift:71,74,118,119,2107`]
- [Source: `AudioAnalysisService.swift:260` votingThreshold precedent · `:934,996,1041` foldEnsembleBPM]
- [Source: `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift:124-127`]
- [Source: `architecture.md` ADR-11 Options-first configuration]

## Previous Story Intelligence

Preceding story overall is **11-6** (`11-6-demo-strategy-popovers-wired-to-documentedcase-docs.md`, status `review`). Cross-epic rather than in-epic, since 12.1 is the first story of Epic 12.

1. **Story 11.1's blocker pattern.** An airtight-looking spec carried a defect (`.process` flattening `Documentation/<Type>/`) that only surfaced when someone read the actual SwiftPM semantics. This story already hit the same class twice: the inverted FR-55 AC and the `rangeNormalize` sub-octave contract violation. Assume a third.
2. **Epic 10's lesson: spec-correct is not reality-correct.** Three demo-UI stories passed spec and a clean three-layer review, then failed on the operator's live GUI. This story is library work, so the analogue is the corpus gauntlet: `make benchmark` and `make benchmark-giantsteps` are the reality check, not `make test`.
3. **Operator-owned closeout steps are explicit.** Stories closing at `review` surface a "Pending user action" subsection. The separate-LLM `/bmad-code-review` cadence and the 1Password-signed commit are not agent-completable.
4. **`deferred-work.md` is the authoritative ledger**, not story-file checkboxes.

### Git Intelligence

Last five commits are all planning-artifact work (`35c6bed`, `b2823e4`, `f644a86`, `7d96cf0`, `5783c40`) — Epic 12 scoping and PRD reconciliation. **No `Sources/` or `Tests/` change has landed since `5783c40`**, so this story starts from a clean library baseline with the corpus floors last measured at OA300 Acc1 58/82, Acc2 74/82.

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
