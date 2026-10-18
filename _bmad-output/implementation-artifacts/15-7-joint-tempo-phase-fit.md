# Story 15.7: Joint tempo and phase fit for the constant-tempo grid

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 7 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Fit a tempo and phase pair jointly from the Phase 6 observation stream, validate it on grid timestamps across separated stable regions, and expose the fitted pair as a wrapped additive output without changing BeatGrid or BeatTimestamp.

## Key Design Decisions

1. **Fit returns a tempo and phase pair, not just tempo.** BeatGridAnalyzer.swift:49 declares the fixed-period contract and the optional comb refinement at :114 returns only tempo (the grid origin is chosen from earlier observations). This story introduces a FittedTempoPhase value carrying both tempo and a phase anchor so downstream code can evaluate against actual grid timestamps instead of a higher internal support score.
2. **Additive wrapper, no changes to BeatGrid or BeatTimestamp shape.** The scope rule from AGENT_GUIDANCE.md item 7 forbids silently rewriting public contracts around raw beats. The fitted pair surfaces through a new optional diagnostic field on the existing refinement sink or a sibling wrapper and the final playable grid still materialises through the Story 8.4 path, so BeatGrid.swift:72 and BeatTimestamp.swift:31 are untouched.
3. **Consume Phase 6 observations rather than re-running BPM.** Phase 7 depends on Story 15.5. The fit reads the framewise beat and downbeat observation stream delivered by Phase 6 (timed, with coverage) and the stable-region segmentation it carries. It does not re-derive observations from BPMAnalyzer internals and it does not touch MLTechnique's scalar API.
4. **Evaluate on grid timestamps, score alone does not merge.** FINDINGS.md section 'ML and grid design' flags that the current comb maximises support over phase but the user-visible metric is the actual anchor time. The AC gate here compares extrapolated grid timestamps against independent references at absolute phase; a higher support or likelihood score alone is explicitly rejected as a merge criterion.
5. **Robust-cost objective with explicit outlier handling.** The handoff calls out fills, missing kicks and offbeat accents. The joint fit uses a Huber-style loss on per-observation residuals with an explicit kept-fraction trimming step, so a dropped kick or a syncopated accent does not pull tempo or phase. The trimming decision is captured in the diagnostic so it is reviewable rather than hidden.
6. **Metrical-level choice stays upstream.** The joint fit refines rate and phase at the metrical level the BPM stage already resolved. It does not jump octaves. Octave decisions remain in BPMAnalyzer and in Epic 12 and 13; this story's scope is precise rate plus phase at a fixed level.
7. **No retraining and no runtime preprocessing changes to shipped weights.** AGENT_GUIDANCE.md item 'Do not alter runtime preprocessing of existing weights and claim better accuracy' applies: the fit works on the Phase 6 observation stream as published. No change to BNNSTechnique.swift:537 or any model weights file is implied. SignalSource.beatGrid and SignalWeights.beatGrid stay placeholders.
8. **No parity claim with rekordbox.** The ground rule from AGENT_GUIDANCE.md item 5 holds. Benchmarks compare the fitted pair against the current BeatGridAnalyzer output and against known-truth synthetic signals. Any rekordbox comparison waits for Phase 9's matched evaluation.

## Story

As a a BoomBoomBoomKit developer evaluating a precise constant-tempo DJ grid,
I want a joint tempo and phase fit over the Phase 6 observation stream, with validation on actual grid timestamps in separated stable regions and robust rejection of fills and offbeat accents,
so that the final playable grid holds phase through breaks and weak passages without silently rewriting the BeatGrid or BeatTimestamp contract.

## Acceptance Criteria

1. **Given** the Phase 6 framewise observation stream for a synthetic click fixture at 120 BPM at 44.1 kHz with an impulse at a known absolute time
   **When** the Phase 7 joint fit is invoked and asked for a FittedTempoPhase
   **Then** the returned tempo is within 0.01 BPM of 120.0 and the returned phase anchor is within 5 ms of the first independently specified impulse time, measured against the probe convention established in Phase 2 and 3

2. **Given** a fixture containing two separated stable regions of equal tempo bridged by a four-second silence or weak-onset passage
   **When** the joint fit runs with the Phase 6 observation stream covering both regions
   **Then** a single tempo and phase pair fits both regions and the extrapolated grid at the end of the second region is within 10 ms of truth, with the diagnostic sink reporting the bridged span and the kept-fraction

3. **Given** a syncopated fixture with strong offbeat accents and dropped downbeats
   **When** the joint fit runs with both the full-band observation stream and a low-frequency sub-band stream drawn from Phase 6
   **Then** the fitted phase lands on the true downbeat phase within 15 ms for the low-band comparison and the diagnostic records which observation stream carried the lower residual, with neither choice being hard-coded

4. **Given** a fixture with a 2-bar drum fill inserted mid-track and the rest at steady 128 BPM
   **When** the fit runs with Huber-style trimming enabled
   **Then** the kept observations exclude the fill span by at least 70 percent, the fitted tempo stays within 0.1 BPM of 128.0, and the final grid extrapolated across the fill is within 20 ms of truth at bar 32

5. **Given** the current main branch BeatGridAnalyzer path for the twelve synthetic click fixtures from evidence/timing/TimingProbeTests.swift
   **When** the joint fit path and the current comb path are both scored on actual grid timestamps using the Phase 3 absolute-phase convention
   **Then** the joint fit path reports a smaller median absolute anchor error on at least 10 of the 12 fixtures and no fixture regresses by more than 5 ms, with per-fixture numbers written to _bmad-output/perf-baselines/

6. **Given** the public BeatGrid and BeatTimestamp types
   **When** the Phase 7 story is built against main
   **Then** git diff shows no shape change to BeatGrid.swift:72 or BeatTimestamp.swift:31, no new case in any DownbeatResult or BeatGridAnchorSource enum, and the FittedTempoPhase value lives in a new file that is additive only

7. **Given** a run that returns a FittedTempoPhase
   **When** SignalSource and SignalWeights are inspected
   **Then** SignalSource.beatGrid and SignalWeights.beatGrid remain placeholder entries with no new voting weight assigned, matching the AGENT_GUIDANCE.md ground rule that learned evidence is not counted twice

## Affected files

- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:49`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:114`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:364`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:710`
- `Sources/BoomBoomBoomKit/BeatGridAnalyzer.swift:856`
- `Sources/BoomBoomBoomKit/BeatGrid.swift:72`
- `Sources/BoomBoomBoomKit/BeatTimestamp.swift:31`
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift`
- `Tests/BoomBoomBoomKitTests/BeatGridAnalyzerTests.swift`
- `docs/rekordbox-analysis/evidence/timing/TimingProbeTests.swift`
- `_bmad-output/perf-baselines/`
- `_bmad-output/implementation-artifacts/15-6-joint-tempo-phase-fit.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

## Overlap with Epic 12

Epic 12 owns metrical-level choice, model-quality lever ranking, and any retrain gate. This story depends on Epic 12's level resolution staying upstream and does not change octave rules. If Phase 6's observation stream (Story 15.5) comes from a path that also feeds Epic 12 experiments, the fit here treats it as read-only input and emits a diagnostic rather than editing it.

## Open questions for the PRD

- What exact fields does the Phase 6 observation stream carry in the current Story 15.5 draft (frame timing, origin, model and frontend identity, coverage, sub-band split)? The Phase 7 fit must consume them unchanged.
- Where does FittedTempoPhase live: a new file next to BeatGridAnalyzer.swift or inside a BeatGridRefinement namespace that Story 15.5 already added?
- What is the kept-fraction floor for the Huber trimming step before the fit is flagged untrustworthy and the seed tempo and phase are preserved verbatim?
- Is the low-band sub-band envelope guaranteed by Story 15.5 on every input or does Phase 7 need an explicit abstain when it is absent?
- Should the fitted pair also be exposed as a public diagnostic for downstream DJ auto-sync (2manyDJs AC6), or does Phase 8 package the external contract?

## Explicit scope exclusions

- Do not alter the shape of BeatGrid or BeatTimestamp public types; the new output is additive or wrapped.
- Do not touch BNNSTechnique.swift:537 preprocessing or any shipped weights file and claim better accuracy as a result.
- Do not promote any Phase 7 artifact to main; everything stays on develop per CLAUDE.md release process.
- Do not count learned evidence twice: SignalSource.beatGrid and SignalWeights.beatGrid remain placeholders.
- Do not claim parity with rekordbox before Phase 9's matched evaluation lands.
- Do not touch Story 12-7 corpus membership or the signed corpus protocol as a side effect of this story.
- Do not use metrical-level jumping to improve the fit score; keep octave decisions upstream in BPMAnalyzer and Epic 12 or 13.
- Do not add vocabulary like 'mint', 'attestation', 'sentinel', 'work order', or 'must-drop obligation' to code, tests, or docs.

