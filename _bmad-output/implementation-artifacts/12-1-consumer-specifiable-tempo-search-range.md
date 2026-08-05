# Story 12.1: Consumer-specifiable tempo search range

Status: review
Baseline revision: aff5286 (branch `rterhaar/epic-12`, clean tree)
Final revision: uncommitted (commit is operator-owned, gated on the 1Password SSH signer)
Followup review recommended: true

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

- [x] **Task 1 — Run the inherited ceiling sweep** (AC: #1)
  - [x] Sweep the hand-tuned `0.3` / `0.5` `resolveOctaveAmbiguity` thresholds on an OA300 dev slice; report OA300 holdout + GiantSteps once
  - [x] Record per-threshold results in Completion Notes; if skipping, write the retirement rationale instead
- [x] **Task 2 — Read before writing** (AC: #2, DD1, DD2)
  - [x] Read `BPMAnalyzer.swift` around `:71`, `:74`, `:118`, `:119`, `:2107` and every call site of all four constants
  - [x] Read `AudioAnalysisService.swift` `foldEnsembleBPM` and its three call sites (`:934`, `:996`, `:1041`)
  - [x] Enumerate which pipeline steps consume the scan pair versus the perceptual pair; record in Dev Notes
- [x] **Task 3 — Options surface** (AC: #2, #4, #5)
  - [x] Add the two pairs to `AudioAnalysisService.Options` per ADR-11, `Sendable`, property-level defaults matching today's values exactly
  - [x] Implement normalization: finite-first, clamp to `30...300`, enforce `min < max`, enforce `perceptualMax >= 2 * perceptualMin`
  - [x] Thread through to `BPMAnalyzer.Options` (internal, memberwise init retained)
- [x] **Task 4 — Byte-identity protection** (AC: #3)
  - [x] Paired opt-out test asserting `bitPattern` equality on `bpm`, `confidence`, and element-wise `candidates` at default `Options`
  - [x] No shared-helper extraction was needed — the tests compare two live pipeline runs rather than re-deriving production logic
- [x] **Task 5 — Ensemble seam coverage** (AC: #6)
  - [x] Test that a moved perceptual window changes `.mlOnly` fold output as expected
- [x] **Task 6 — Fixture measurement** (AC: #7)
  - [x] Exercise the three octave fixtures under a window that excludes the erroneous octave; assert resolution
  - [x] Assert `robbyt_x-ray-120s` remains a known failure; its label is byte-for-byte unchanged
- [x] **Task 7 — Impact report + gating gauntlet** (AC: #8)
  - [x] Env-gated per-track impact report with per-band and per-genre breakdown
  - [x] `make fmt` -> `make lint` -> `make test` -> `make benchmark` -> `make benchmark-giantsteps`; exact integer counts recorded

## Dev Notes

**Read the files before changing them.** Story 12.1's own acceptance criteria were corrected during creation because the epic AC had inverted FR-55 — it claimed `AccuracyFloorTests.swift:126` mislabels the triplet fixture as an octave error. It does not; it already says `triplet-related: reports ~115.6, two-thirds of 174 (3:2)`. Acting on the uncorrected AC would have changed correct code. Treat every cited line number as a claim to verify.

**Which pipeline steps consume which pair** (Task 2 deliverable, measured against the
live source rather than the epic's citations):

| Step | Stage | Consumes |
|---|---|---|
| 5 | Fourier tempogram (`computeFourierTempogram`) | scan (`bpmMin`/`bpmMax` size the grid) |
| 6 | Periodicity fusion (`fusePeriodicity`) | scan |
| 7 | TPS2 harmonic enhancement (`applyTPS2Enhancement`) | scan |
| 8 | Multi-peak extraction (`extractTopCandidates`) | scan (indexing) **and** perceptual (per-candidate fold) |
| 9 | Range normalization (`rangeNormalize`) | **perceptual** |
| 9.7 | Duration-derived bar-count hint (`applyDurationHintBarCounts`) | **perceptual** (in-window bar BPMs only) |
| 10 | Octave disambiguation (`resolveOctaveAmbiguity`) | scan (`fused` index mapping) |
| 10b | Sub-band peak confirmation (`confirmWithSubBandPeaks`) | **perceptual** (re-folds a promoted hi-hat tempo) |
| 10c | Fine-grid refinement (`refineCandidates`) | scan (`bpmRange:`) |
| — | Final winner guard (post-10c) | scan |
| 12 | Confidence (`computeConfidence`) | scan (`bpmMin` offset) |
| — | Ensemble fold (`AudioAnalysisService.foldEnsembleBPM`, 3 sites) | **perceptual** (DD2) |

Step 4b's sub-band ACFs, step 3's onset envelope, and the step-11 beat-grid fan-out
consume neither pair. Steps 9 and 10c are the reason the window is not a hard output
clamp: 10c re-fits the winner against the SCAN range after the fold, so a window-edge
tempo can be reported a fraction of a BPM outside the window (`bpm-120-click` measures
120.00008 under a `60...120` window). That is pre-existing behaviour at the `60...200`
default too; clamping it would move default-path DSP output, which this story may not
do, so it is documented on `PerceptualTempoWindow` instead.

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

#### Task 1 — the inherited ceiling sweep (AC #1)

The sweep ran. It did not find a better tuning of the two thresholds; it found that
the branch they gate is a net loss on both corpora.

Instrument: `Tests/BoomBoomBoomKitBenchmarkTests/OctaveThresholdSweepTests.swift`,
env-gated on `OCTAVE_THRESHOLD_SWEEP=1`, driven by `make octave-threshold-sweep`.
Raw rows in `12-1-octave-threshold-sweep.json`. Metric is single-window
`BPMAnalyzer.estimateBPM` at MIREX 2% tolerance, `maxSeconds=120` — **not**
comparable to the full-pipeline corpus floors, which come from
`AudioAnalysisService`.

OA300, 49 combinations, none dropped:

| energy | score | Acc1 | Acc2 | delta Acc1 |
|---|---|---|---|---|
| 0.1-0.6 | **1.0** | 56 | 67 | **+1** |
| **1.0** | 0.3-1.0 | 56 | 67 | **+1** |
| 0.3-0.6 | 0.4-0.8 | 55 | 67 | 0 (default plateau, 17 points) |
| 0.1-0.2 | 0.4-0.8 | 54 | 67 | -1 |
| 0.3-0.6 | 0.3 | 54 | 66 | -1 |
| 0.1 / 0.2 | 0.4 / 0.3 | 53 | 66 | -2 |
| 0.1 | 0.3 | 52 | 65 | -3 |

The grid was **extended from the specified 6x6 to 7x7** (adding `1.0` to both axes),
disclosed here rather than silently. The specified `energy 0.1-0.6 x score 0.3-0.8`
box came back completely flat at or below the default, which on its own would have
produced a false "the default is already at the ceiling" verdict. A supplementary
`{0, 0.3, 1, 2, 5, 100}^2` probe (scratch, not committed) confirmed nothing beyond
`1.0` moves further.

The default `(0.3, 0.5)` sits **1 track below** the measured single-window ceiling of
56/82. Every point that reaches 56 does so by *closing* the 2:1 fused-periodicity
fallback (`energy >= 1.0` or `score >= 1.0`), not by re-tuning it. There is no
interior optimum: no grid point beats the default while leaving the branch active.
The default row landing on exactly 55/82 independently reproduces the documented
single-window Acc1 ceiling.

GiantSteps cross-check, 661 tracks, same single-window metric:

| setting | Acc1 | Acc2 |
|---|---|---|
| `(0.3, 0.5)` shipped default | 528 (79.9%) | 537 (81.2%) |
| `(1.0, 1.0)` branch closed | 532 (+4) | 541 (+4) |

Direction agrees with OA300 and the effect is larger, so this is not an OA300
overfit. The OA300 delta of 1 track is inside the repo's own binomial-noise
convention; the GiantSteps delta of 4 is what makes the finding worth recording.

**Verdict: the inherited do-not-pre-commit rule is satisfied — the sweep ran and
reported, and no threshold change was committed.** Closing the branch is a
materially different change from retuning two constants: it needs its own spec, its
own full-pipeline measurement (every number above is single-window; the branch may
behave differently under multi-window merge and metadata corroboration), and its own
`AccuracyFloorTests` fixture-impact review. Filed as a finding for Epic 12, not acted
on here. Story 12.1 proceeds on the input-constraint axis as specified.

Thresholds remain at `0.3` / `0.5`. They are now reachable through the internal
`BPMAnalyzer.Options` (defaults unchanged, output byte-identical) so the sweep is
repeatable; the public `AudioAnalysisService.Options` was not touched by this task.


#### Tasks 2-7 — the consumer-specifiable pairs (AC #2-#8)

**Shape.** Two public `Sendable, Hashable` value types, each carried as a non-optional
`AudioAnalysisService.Options` field with a property-level default (ADR-11):
`tempoScanRange: TempoScanRange = .default` (40...250) and
`perceptualWindow: PerceptualTempoWindow = .default` (60...200). Two types rather than
four `Double` fields, because the normalization invariants are properties OF the pair,
not of either bound alone: `min < max` for the scan range, and `max >= 2 * min` for the
perceptual window. Putting them in the initializer makes an invalid value
unconstructible rather than merely unlikely, so nothing downstream has to defend.

**Normalization (DD4, AC #4/#5)** — isFinite first, then clamp; never throws. A
non-finite bound falls back to its own field default, so a bad `max` cannot silently
reset `min`. `TempoScanRange`: `min` into `30...297`, `max` into `(min + 3)...300`. The
3 BPM floor is structural, not taste — the integer scan grid rounds INWARD
(`minBPM.rounded(.up)` / `maxBPM.rounded(.down)`, which can consume a BPM at each end)
and the local-maximum scan reads `[i-1]`/`[i+1]`, so three slots must survive.
`PerceptualTempoWindow`: `min` into `30...150`, `max` into `(2 * min)...300`, which
makes DD3's defect unreachable. The named case is pinned: `min 100, max 150` normalizes
to `100...200`, and `rangeNormalize(160)` returns 160 rather than the pre-fix 80. Note
the asymmetry the review surfaced and the story now documents on the property: a
requested perceptual `min` above 150 is LOWERED, not honoured, where the scan `min` is
honoured to 297.

**Byte-identity (AC #3).** `AudioAnalysisService.analyzeBPM` and
`BPMAnalyzer.estimateBPM` at default options are `bitPattern`-identical to the same
call with the pre-story constants written out longhand, over five fixtures (two
synthetic, three real). Corroborated independently by the corpus gauntlet: OA300 came
back at exactly the pre-story 58/82 + 74/82 and GiantSteps at exactly 537/661 +
546/661. A companion test asserts the lever is NOT inert, so the byte-identity
assertions cannot pass vacuously.

**Ensemble seam (AC #6, DD2).** Confirmed by reading rather than assumed:
`foldEnsembleBPM` delegates to `rangeNormalize` at three sites inside
`combineEnsemble`, so the window governs ML-winner output too.
`combineEnsemble(dspWinner:ml:policy:)` gained a defaulted `perceptualWindow:`
parameter (its four DocC symbol references were updated with it). Tests cover
`.mlOnly` (92 stays 92 by default, folds to 184 under `100...200`),
`.highestConfidence` (240 halves to 120 by default, to 60 under `30...70`), and
`.dspOnly` being window-invariant.

**AC #7 fixture measurement.** The window that recovers the three octave failures is a
SLOW one, not a DnB one — those fixtures already report the fast octave (182 / 191.76 /
140.12) for slow tracks (92 / 96 / 70). Under `PerceptualTempoWindow(60, 120)`, which
excludes the erroneous octave:

| fixture | truth | default path | windowed | relative error |
|---|---|---|---|---|
| `Meta_Man` | 92 | 182.003 | 92.367 | 0.40% |
| `Meta_Man_La_Noche_Digital_` | 96 | 191.760 | 95.798 | 0.21% |
| `Submerged_Lament` | 70 | 140.123 | 69.928 | 0.10% |
| `robbyt_x-ray-120s` | 174 | 115.635 | 115.635 | 33.54% |

All three octave fixtures resolve inside the 2% tolerance. `robbyt_x-ray-120s` does
not, and the test ASSERTS it does not — a 3:2 relation is not reachable by any choice
of octave window, and encoding that as an expectation stops a later reader folding it
into the recoverable set. Its `AccuracyFloorTests.swift:126` `triplet-related` label is
byte-for-byte untouched, and every `withKnownIssue` wrapper on the default path still
fires (4 known issues, unchanged).

**Impact report (AC #8).** `make tempo-range-impact-report` ->
`12-1-tempo-range-impact-report.json`. Measures the FULL `AudioAnalysisService`
pipeline (not the single-window analyzer the click-impact precedent used) at default
options against the same pipeline with only `perceptualWindow` moved, default
comparison window `100...200`. OA300, 82/82 analyzed:

`changedRanking: 11`, `changedDisambiguationWinner: 11`, `changedFinalBPM: 9`,
`total: 82`. Acc1 58 -> 58 (+0), Acc2 74 -> 71 (-3).

Per band (ground-truth BPM): `<80` 1 track, 1 changed, Acc1 0->0; `80-119` 18 tracks,
3 changed, Acc1 3->1 (-2); `120-159` 22 tracks, 1 changed, Acc1 20->20; `160-199` 41
tracks, 4 changed, Acc1 35->37 (+2). Per genre: `breaks` 10 tracks Acc1 6->7 (+1),
`drum-and-bass` 67 tracks Acc1 48->47 (-1), `footwork`/`half-time-dnb`/`tech-house`/
`techno` 1-2 tracks each, unchanged.

Read honestly: a `100...200` window is a WASH on this corpus, not a win. It buys +2
Acc1 in the 160-199 band and pays -2 in the 80-119 band, because OA300 contains genuine
sub-100 material the window folds away. That is the expected behaviour of an input
constraint applied to a corpus it was not chosen for, and it is why the story ships the
lever at its pre-story default rather than moving it. The value of the lever is
demonstrated per-fixture (AC #7), where a consumer who KNOWS their material is
half-time recovers all three octave failures.

**Gauntlet** (re-run after the 2026-08-02 review patch). `make fmt` clean. `make lint`
6 violations, 0 serious, all pre-existing (5 in `Demo/`, 1 in a `build/` derived
source); zero from this story. `make test` 993 tests in 168 suites passed, 4 known
issues (the unchanged `AccuracyFloorTests` ratchet). `make benchmark` OA300 Acc1 58/82
(70.7%), Acc2 74/82 (90.2%) — floors 57/73 hold. `make benchmark-giantsteps` Acc1
537/661 (81.2%), Acc2 546/661 (82.6%) — floors 537/546 hold.

**No HALT events.** One design decision was made rather than escalated: step 10c
re-fits the winner against the scan range AFTER the fold, so the perceptual window is
not a hard output clamp (a 120 BPM click measures 120.00008 against a `60...120`
window). Clamping the refined value would have changed default-path DSP output, which
DD5/NFR-11 forbids, so the behaviour is documented on the public type and the tests
carry a 0.5 BPM edge tolerance. This is pre-existing behaviour at the `60...200`
default, not something the story introduced.

#### Review-patch pass (2026-08-02)

Two adversarial reviews produced 15 confirmed findings. All 15 were addressed; one had
a wrong derivation that was corrected rather than copied.

*Documentation accuracy.* `README.md` had never been updated and ships to `main`; it
now carries a "Constraining the tempo range" section (comparison table, worked example,
four documented properties), two `Public API` rows, a new `analyzeBPM` nil row, and the
two stale unconditional claims are fixed (step 9's "constrain to 60-200" and the ML bin
count's "the library normalizes every result into 60-200"). Three `BPMDiagnosticTrace`
doc comments that hardcoded `60...200` are now qualified as the default. The
`AccuracyFloorTests` invariant comment cited two removed privates and a stale line
number; it now names the live symbols and scopes the assertion to the default
configuration explicitly, without weakening it. `project-context.md`'s access-control
roster gained both types.

*Two doc claims were measurably false and are restated.* `TempoScanRange` justified the
`30...300` envelope with "the slowest corpus ground truth is 70, the fastest 200".
Measured: OA300 spans 79.99-172.99 and GiantSteps spans 64-197 with `tempo2` reaching
208 — the claimed ceiling is already exceeded by data in the repo. The envelope value is
fine; the evidence is now the measured spans. `PerceptualTempoWindow` claimed the
window excursion is "sub-0.1 BPM" from a single 120.00008 measurement. A sweep of the
bundled fixtures across twelve windows found 0.304 BPM (`bpm-120-click` -> 60.304 under
`30...60`), and 84.861 under `85...170` shows the excursion goes below the floor as well
as above the ceiling.

The review derived the structural bound as `tempogramSearchRadiusBPM` (0.4) plus a
parabolic sub-step, roughly 0.5. **That derivation is wrong.** 0.4 is the radius of the
tempogram-override peak search *around the fused winner*; the fused winner itself is the
argmax over `refineCandidates`' full `centerBPM +/- 4.0` scan window, so the structural
bound is 4.0 BPM, an order of magnitude wider. The documentation now states 4.0 as the
structural bound and 0.304 as the measured worst case, and says which is which. The
three magic literals (`59.5`, `120.5`, a bare `0.5`) are replaced by one
`PerceptualWindowEdge.toleranceBPM` with the derivation and a note to re-measure rather
than widen if it ever fails.

*Two undocumented behaviours.* Moving `perceptualWindow` alone can return `nil`
per-track: with the default `40...250` scan range, a `30...60` window folds
`Submerged_Lament` to roughly 35 and the final range guard rejects it while neighbours
return values. The warning now sits on `PerceptualTempoWindow`, on
`Options.perceptualWindow`, and in the README, and a test pins both the `nil` and its
fix (widen the scan range). The min-above-150 lowering is documented on the property,
the parameter, and the type, with two tests.

*One real defect.* `Int(scanRange.minBPM)` truncated fractional bounds, so the grid
generated candidates below the stated minimum that the final `Double` guard then
rejected: `TempoScanRange(120.5, 240)` over a 120 BPM click returned `nil` where
`(121, 240)` returned 121. The grid now rounds inward
(`TempoScanRange.integerLowerBound` / `integerUpperBound`). `minimumSpanBPM` rose 2 -> 3
because inward rounding can consume a BPM at each end and three grid slots must survive;
`minBPM`'s clamp ceiling moved 298 -> 297 to match. The default `40...250` is integral,
so the rounding is a no-op there — verified, not assumed: OA300 came back at exactly
58/82 + 74/82 and GiantSteps at exactly 537/661 + 546/661.

*Harness defects.* `OctaveThresholdSweepTests` described the grid as "COMPLETELY FLAT"
and the result as a tie; both comments now match the data and this file's own numbers
(13 grid points at OA300 Acc1 56 vs the default's 55, GiantSteps 528 -> 532). The "no
change committed here" recommendation stands, with the reason restated as what it
actually is: closing a pipeline branch needs its own story and full-pipeline
measurement. The silent `where hits.count == grid.count` discard now returns and
reports a decode-failure count — measured 0 on both corpora, so the 661-vs-664
GiantSteps gap is the ground-truth manifest's cardinality, not dropped tracks, which is
exactly what emitting the count was supposed to settle. `TempoRangeImpactTests` now
separates `baselineFailed` (corpus noise) from `comparisonOnlyFailed` (the moved window
annihilating a track the default handled) — 0 and 0 at the `100...200` comparison
window. Both benchmark suites gained the house `.enabled(if:)` suite trait, so an unset
corpus path skips rather than errors. `writeReport` no longer uses a parameter as an
ignored boolean flag (it takes a `SweepCorpus`), and its write is `.atomic`.

Impact-report and sweep numbers are unchanged after the patch; both artifacts were
regenerated and now carry the coverage keys.

### File List

- `Sources/BoomBoomBoomKit/TempoScanRange.swift` — NEW. Public `TempoScanRange` + the internal `TempoRangeEnvelope` (`30...300`) shared by both pairs
- `Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift` — NEW. Public `PerceptualTempoWindow`
- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — UPDATE. Four `private static let` constants removed; `Options.tempoScanRange` / `Options.perceptualWindow` added; window threaded through `rangeNormalize`, `extractTopCandidates`, `confirmWithSubBandPeaks`, `applyDurationHint`, `applyDurationHintBarCounts`
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — UPDATE. Public `Options.tempoScanRange` / `Options.perceptualWindow`; threaded into the window loop and both beat-grid passes; `foldEnsembleBPM` / `combineEnsemble` window-parameterized
- `Sources/BoomBoomBoomKit/EnsemblePolicy.swift`, `EnsembleDecision.swift`, `BPMDiagnosticTrace.swift` — UPDATE, DocC symbol reference to `combineEnsemble` only
- `Tests/BoomBoomBoomKitTests/TempoSearchRangeTests.swift` — NEW. Normalization (AC #4/#5), byte-identity (AC #3), ensemble seam (AC #6)
- `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift` — UPDATE, additive only. FR-55 per-fixture measurement + its denominator guard; the existing floor and every `knownFailure` label are unchanged
- `Tests/BoomBoomBoomKitTests/EnsembleCombinerTests.swift` — UPDATE, DocC symbol reference only
- `Tests/BoomBoomBoomKitBenchmarkTests/TempoRangeImpactTests.swift` — NEW. AC #8 impact report
- `Tests/BoomBoomBoomKitBenchmarkTests/OctaveThresholdSweepTests.swift` — NEW (Task 1)
- `Makefile` — UPDATE. `octave-threshold-sweep` (Task 1) + `tempo-range-impact-report` (Task 7)
- `_bmad-output/implementation-artifacts/12-1-octave-threshold-sweep.json` — NEW artifact (Task 1, develop-only)
- `_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json` — NEW artifact (Task 7, develop-only)
- `README.md` — UPDATE (review patch). New "Constraining the tempo range" section, two `Public API` rows, a `analyzeBPM` nil-path row, and two stale unconditional `60-200` claims corrected. Ships to `main`
- `CLAUDE.md` — UPDATE. Key Types roster gains the two new public types
- `_bmad-output/project-context.md` — UPDATE (review patch). Access-control-boundaries roster gains the two new public types

## Review Triage Log

### 2026-08-02 — Review pass

Two adversarial reviewers (Blind Hunter, Edge Case Hunter) ran in parallel against the
full diff from `aff5286`, including untracked new files. Every finding below was
verified against the actual code before triage; reviewer-assigned severity was
discarded and re-assigned by consequence to the library's consumer.

- intent_gap: 0
- bad_spec: 0
- patch: 15 (high 1, medium 8, low 6)
- defer: 3
- reject: 5
- addressed_findings:
  - `[high]` `[patch]` `README.md` was never touched, yet it ships to `main` and this
    story's entire deliverable is a consumer-facing lever. Line 554 and line 617 both
    asserted the `60-200` fold as unconditional fact, and neither new `Options` field
    appeared anywhere. Added a "Constraining the tempo range" section with a
    scan-versus-perceptual comparison table and a worked example, two `Public API`
    rows, an `analyzeBPM`-returns-nil row, and corrected both stale claims.
  - `[medium]` `[patch]` `PerceptualTempoWindow`'s "not a hard output clamp" section
    understated the step-10c excursion by roughly 5x ("sub-0.1 BPM" against a measured
    0.304), and contradicted the `0.5` tolerance its own tests used. The reviewer's
    proposed derivation was itself wrong: `tempogramSearchRadiusBPM = 0.4` bounds the
    override peak search around the fused winner, but the fused winner is the argmax
    over `refineCandidates`' full `centerBPM +/- 4.0` window, so the structural bound
    is 4.0. Docs now separate the structural bound from the measured worst case, and
    record that the excursion is bidirectional (84.861 below an `85...170` floor) —
    which the original text also missed. The three duplicated magic numbers collapse
    into one named constant.
  - `[medium]` `[patch]` `TempoScanRange`'s envelope justification cited corpus spans
    that do not exist ("slowest 70, fastest 200"). Measured: OA300 79.99-172.99,
    GiantSteps 64-197 with `tempo2` reaching 208, so the claimed ceiling is already
    exceeded by tracked ground truth. Envelope value kept, evidence corrected.
  - `[medium]` `[patch]` `BPMDiagnosticTrace.swift:93,506,537` still hardcoded
    `60...200` in public doc comments, in a file this story had already edited.
  - `[medium]` `[patch]` `AccuracyFloorTests`' range-guard comment cited
    `perceptualMinBPM`/`perceptualMaxBPM` and `BPMAnalyzer.swift:2107` — both privates
    removed by this story, line number stale. Comment corrected and the assertion
    scoped explicitly to the default configuration; the assertion itself was NOT
    weakened.
  - `[medium]` `[patch]` Moving `perceptualWindow` alone can return `nil` for
    individual tracks: `Submerged_Lament` folds to 35 under a `30...60` window, below
    the untouched scan floor of 40, while neighbours still resolve. The
    cross-interaction warning existed only on `TempoScanRange` — the type a consumer
    reaching for the perceptual lever had been told twice they did not need. Warning
    added to `PerceptualTempoWindow`, `Options.perceptualWindow`, and README, with a
    test pinning both the `nil` and its fix.
  - `[medium]` `[patch]` `PerceptualTempoWindow` silently lowered a requested minimum
    above 150 (`(160, 300)` yields `150...300`) with no mention on the property —
    asymmetric with `TempoScanRange`, whose minimum is honoured to the envelope edge.
    Documented and covered.
  - `[medium]` `[patch]` `Int(scanRange.minBPM)` truncated fractional bounds, so a
    `40.7` minimum generated grid candidates below the stated floor that the final
    `Double` guard then rejected, returning `nil` for the whole analysis. Confirmed
    exactly: `120.5...240` returned `nil`, `121...240` returned 121. Now rounds
    inward. This forced `minimumSpanBPM` from 2 to 3 and the minimum clamp from 298 to
    297, since inward rounding can consume a BPM at each end and three grid slots must
    survive the local-maximum scan. Default 40/250 path verified byte-identical.
  - `[medium]` `[patch]` The sweep harness's own prose contradicted its data, calling
    a uniform +1 OA300 / +4 GiantSteps result "COMPLETELY FLAT" and "a tie". Comments
    rewritten to match the data and this file's Completion Notes. The "no change
    committed here" recommendation was kept, since closing a pipeline branch needs its
    own story.
  - `[low]` `[patch]` `OctaveThresholdSweepTests.tally` silently discarded
    decode-failed tracks and emitted no failure count, against the project's
    no-silent-caps rule. Now reported — and reporting it settled the question: `failed`
    is 0 on both corpora, so the 661-versus-664 GiantSteps gap is the ground-truth
    manifest's cardinality, not dropped tracks.
  - `[low]` `[patch]` `TempoRangeImpactTests` could not distinguish "decode failed"
    from "the moved window annihilated a track the default handled" — the story's most
    interesting signal was invisible. Split into separate outcomes; both 0 at the
    `100...200` window.
  - `[low]` `[patch]` `leverIsNotInert`, the one test whose job is proving the lever is
    not wired to nothing, asserted against `Meta_Man` — a fixture whose 2x error is a
    `withKnownIssue` entry in the same file, and which the ratchet exists to announce a
    fix for. Retargeted at `bpm-170-click`, which folds regardless of any octave fix,
    plus a directional assertion so "different" cannot pass as "folded".
  - `[low]` `[patch]` Both new benchmark suites used throwing inits rather than the
    `.enabled(if:)` trait used across the benchmark target, so an unset corpus path
    errored the suite instead of skipping it.
  - `[low]` `[patch]` `writeReport` used a parameter as a boolean flag while ignoring
    its value, and performed a non-atomic read-modify-write of a shared file that
    re-ordered `make` sub-steps could corrupt. Signature cleaned up, write made atomic.
  - `[low]` `[patch]` `project-context.md`'s access-control-boundaries roster was not
    updated alongside CLAUDE.md's Key Types roster.

Deferred (3), recorded in `deferred-work.md`: the BNNS decode gate's hardcoded
`60.0...200.0`, unfixable without unfreezing `MLTechnique`; the sweep's
branch-closing finding, which needs its own story with full-pipeline measurement; and
the impact report's finding that the lever's motivating window is a net Acc2 loss on
OA300, which is a lever-ranking question for Epic 12 rather than an implementation
defect.

Rejected (5): the "defaulted internal parameters fail open" objection (the defaults are
what make byte-identity and existing call sites work, and are deliberate); "evidence
artifacts are untracked" (nothing is committed yet); "the review packet omitted the
story spec" (deliberately excluded); the claim that the `robbyt_x-ray-120s` assertion
is vacuous (it has a real tripwire function against someone adding the name to the
recoverable set); and an edge-case tolerance claim that the measured data contradicts.

## Pending user action

Operator-owned, not agent-completable:

1. **Commit.** Nothing has been committed. The tree carries 12 modified and 7 new
   files, all verified green. The commit is gated on the 1Password SSH signer.
2. **`/bmad-code-review` on a separate-LLM cadence**, per project convention — the two
   reviewers above ran in this session.
3. **Decide on `minimumSpanBPM` 2 -> 3.** Forced by the fractional-bounds fix. Nothing
   shipped depends on it (the type is new in this story), but it is a wider change than
   "round the two conversions" and is flagged rather than buried.
