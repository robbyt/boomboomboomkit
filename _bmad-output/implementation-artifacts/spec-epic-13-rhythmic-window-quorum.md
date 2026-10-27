---
title: 'Rhythmic region selection and BPM consensus'
type: 'feature'
created: '2026-10-25'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'b77aee41fa57fcc924e7a7b6831fa3024d204e62'
context:
  - '_bmad-output/implementation-artifacts/epic-13-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Every BPM pass starts at the first large energy transition. A weak intro can dominate even when later audio has a clearer beat.

**Approach:** Analyze distinct rhythmic regions and use the existing final-BPM window vote to choose one track tempo. Deliver an internal selector and opt-in integration as two stacked PRs; report whether Epic 13's gates justify a later default-promotion PR.

## Boundaries & Constraints

**Always:** Preserve the off path bit-for-bit. Bound scoring even when `maxSeconds` admits a full mix. Under simple-majority voting, quorum requires two distinct regions whose final BPMs agree within 2%; one result or disagreement uses the current strongest-result fallback. Distinguish those cases; preserve cancellation, progress, shared decoding, and grid timing.

**Never:** Detect tempo changes or output a tempo map; equate loudness alone with rhythmic strength; tune on GiantSteps; read the Story 12.7 signed holdout for this experiment; change corpus membership or default behavior without the measured gate.

## I/O & Edge-Case Matrix

| Input | Expected behavior |
|-------|-------------------|
| Weak intro, two later steady regions | Later regions can outvote intro |
| Short/noisy audio or disagreement | No fabricated quorum; return best result or nil |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` — `estimateBPM` uses the 120-second `findEnergyTransition` scan. Add an internal start seam; Step 11 passes local start to grid timing. Standalone `estimateBeatGrid` keeps its drop scan.
- `Sources/BoomBoomBoomKit/AudioAnalysisService.swift` — `preCorroborationCore` serves URL, decoded, `analyze`, and `analyzeFull`; beat-grid analysis is separate.
- `Sources/BoomBoomBoomKit/BPMSelectionPolicy.swift` — `.windowVoting` groups final BPMs; `.quorum` groups raw candidates. `select(from:)` merges, then corroborates; its current result omits the pre-metadata BPM and whether voting accepted a group. Keep `merge(...) -> BPMResult?` unchanged.
- `Sources/BoomBoomBoomKit/SignalPool/MetadataCorroborator.swift` — tags reselect within the merged candidate list: one region under `.windowVoting`/`.maxConfidence`, potentially several under clustered/union strategies. ML can change final BPM later.
- `Sources/BoomBoomBoomKit/BPMDiagnosticTrace.swift` — carries winner DSP state, not cross-region evidence.
- `Tests/BoomBoomBoomKitTests/` — unit, identity, parity, grid-span tests; `Tests/BoomBoomBoomKitBenchmarkTests/` — corpus gates and DAW oracle (`.windowVoting`).

## Tasks & Acceptance

**Execution:**
- [x] Bottom PR `rterhaar/13-rhythmic-regions`: add **internal-only** lightweight onset-regularity scoring with at most eight evenly spread probes, each capped at the selected region duration (at most 30 seconds). Do not fork `OnsetFeaturesBuilder` or change `DSPTechnique`. Test quiet beats, loud unpatterned audio, silence, ties, short clips, disjointness, bounded cost. Keep callers unchanged.
- [x] Top PR `rterhaar/13-region-consensus`: add public `AudioAnalysisService.Options.useRhythmicRegions: Bool = false`. Select up to `intensity.windowSizes.count` disjoint regions of the shortest listed duration (15 seconds at level 1, otherwise 30); short analyzable clips get one truncated region. Keep merge/voting options caller-controlled; document `.windowVoting/.simpleMajority` as the quorum pairing.
- [x] Top PR: wire explicit starts and keep standalone grid anchoring. Check cancellation around scoring; progress counts selected regions. Add public `BPMDiagnosticTrace.rhythmicRegionEvidence: RhythmicRegionEvidence?` (nil off). Public `RhythmicRegionResult: Sendable, CustomStringConvertible` has `startSample: Int`, `sampleCount: Int`, `rhythmScore: Float`, `bpm: Double?`. Public `RhythmicRegionEvidence: Sendable, CustomStringConvertible` has `regions: [RhythmicRegionResult]`, `successfulRegionCount: Int`, `largestAgreementCount: Int`, `windowVotingRan: Bool`, `voteAccepted: Bool`, `preMetadataBPM: Double`. Use an internal merge-with-outcome seam and pass failed-region rows into `select(from:)`; attach evidence before metadata corroboration without changing public `merge`'s result. Preserve it through grid stitching and ML trace delivery.
- [x] Top PR: add env-gated paired Release test and a Makefile target setting `RHYTHMIC_REGION_IMPACT=1`, `OA300_CORPUS_PATH`, and `GIANTSTEPS_CORPUS_PATH`; write `_bmad-output/implementation-artifacts/13-rhythmic-region-impact-report.json`. Compare A: shipped DSP defaults, B: old `[30,60,90]` windows with `.windowVoting/.simpleMajority`, C: rhythmic regions with the same voting, D: uniformly placed disjoint regions with C's count, duration, and voting. C−D isolates rhythmic placement/scoring; C−B includes the changed window geometry, and C−A shows total change. Measure OA300, freeze parameters, then GiantSteps. Report per-track offsets, agreement, nils, flips, Acc1/Acc2, error classes, Release timing, normal and DSP-isolated (`metadataPolicy = .disabled`, `durationHint = false`) results, GiantSteps floor-compatible and primary-strict metrics, and available DAW labels. Count old-anchor-wrong/later-region-correct cases as suggestive intro-lock evidence; report zero flips.
- [x] Document the 120-second default decode cap and keep this stack opt-in. Report whether a later default-promotion PR is justified: OA300 Acc1 gains two tracks, GiantSteps floor-compatible Acc1/Acc2 do not fall, per-track changes are reviewed, and paired Release OA300 runtime stays within 15%.

**Acceptance Criteria:**
- Given an untagged weak-intro fixture with two later regions at a known tempo, when `useRhythmicRegions` and simple-majority window voting run, then both contribute and their BPM wins.
- Given one usable region or conflict, when analysis completes, then the existing fallback applies and `rhythmicRegionEvidence` distinguishes the cases; a rejected vote is not called consensus.
- Given metadata disabled and identical capped PCM, when URL and decoded paths run, then offsets and BPM agree; tagged-file divergence remains by design.
- Given `useRhythmicRegions = false`, when representative fixtures and corpus gates run, then BPM, confidence, candidates, and traces retain prior bit patterns.
- Given combined analysis, when opt-in runs, then region evidence survives stitching and the grid keeps its anchor.

## Implementation Notes

- Bottom selector is internal and capped at eight probes of at most 30 seconds. The top option defaults to `false`; `.windowVoting` and `.simpleMajority` remain caller choices. Grid analysis retains its separate energy-transition anchor.
- Full paired Release report covers 82 OA300 and 661 GiantSteps tracks, with zero nil results. Normal OA300 Acc1/Acc2: A 58/74, B 58/73, C 60/76, D 60/77. GiantSteps floor-compatible Acc1/Acc2: A 537/546, B 537/546, C 573/579, D 564/570. Paired trace-off C/A OA300 runtime ratio is 0.677, with zero timing-run errors. The numeric promotion gate passes, but OA300 Acc1 gains eight tracks and loses six while GiantSteps gains 62 and loses 26.
- Placement attribution does not support default promotion: C and D tie on OA300 Acc1, while D wins OA300 Acc2 by one. Nine OA300 C-versus-D BPM changes exceed 2%; seven change correctness (three C wins and three D wins on Acc1, plus one C Acc2 win). The other two are misses in both arms or remain exact in both. Two C Acc1 wins at the OA label of 85 BPM contradict available DAW labels of 170 BPM. Keep opt-in until further evidence. Suggestive intro-lock counts (8 OA300, 59 GiantSteps) are diagnostic only, not causal proof. Regression lists use unique filenames because two OA300 titles repeat.

## Spec Change Log

## Review Triage Log

| Finding | Verdict and evidence | Route |
|---|---|---|
| BH1 scan tempo range | low: selector lags cover 60–200 BPM while the analyzer allows a wider scan. A 40 BPM only pulse can rank poorly, but this is an uncommon opt-in boundary and parameterizing the scorer adds cost. | reject |
| BH2 sparse-bin aliasing | low: at 44.1 kHz the score reads every sixth sample; a one-sample transient at another phase can be missed. Normal musical attacks span several samples, and exact-bin scanning raises probe cost. | reject |
| BH3 sub-threshold pattern | low: normalized score can rank a patterned region below the analyzer's RMS silence threshold. This needs both unusually quiet audio and competing probes; full-corpus runs had no nil results. A reliable RMS gate adds a second scan. | reject |
| BH4 no backfill after nil | low: selection takes the top K probes before BPM analysis and does not replace a failed pass. This could lose a vote only when a selected probe cannot produce BPM; no full-corpus nil was observed, and backfill changes progress/region-count semantics. | reject |
| BH5 opt-out identity test | medium: it compares default-false with explicit-false in the same binary, so a copied-loop regression would pass. Pin representative pre-change bytes. | patch (with VG2) |
| BH6 trace-on runtime | medium: all report arms enable trace, while production defaults trace off; the 0.687 ratio alone cannot establish the default-path 15% budget. Add a paired no-trace OA300 timing result. | patch |
| BH7 GiantSteps error class | medium: `1114156.LOFI.mp3` is floor-correct at 172.23 BPM via tempo2 but labeled `double` against its 86 BPM primary. Record which annotation matched and classify floor errors accurately. | patch |
| BH8 exact flip counts | low: exact float inequality marks 553 GiantSteps B–C rows as flips, including sub-2% changes. Add tolerance-based decision-flip counts and label exact changes. | patch |
| BH9 intro-lock causality | false: the field is explicitly `suggestiveIntroLock`; it records a later correct region coinciding with B-wrong/C-right, and the implementation notes explicitly deny causal proof. | reject |
| BH10 net promotion gate | medium: OA300 C gains eight and loses six Acc1 tracks against A; GiantSteps gains 62 and loses 26. Per-track rows exist but the summary should expose both sides before a promotion decision. | patch |
| BH11 limited-run gate | low: a smoke run still computes full-corpus promotion booleans and could report a passing gate. Suppress the gate unless all rows ran. | patch |
| VG1 placement integration | medium: three selected regions from three available probes pass even if public opt-in routes to uniform control. Add a service-level four-probe, three-selection offset assertion. | patch |
| VG2 pre-change bytes | medium: existing corpus floors and current-vs-current identity do not assert prior BPM, confidence, candidate, and trace bytes. Pin baseline fixture output. | patch (with BH5) |
| VG3 progress | low: no opt-in test observes `onProgress`; removing that call would pass existing tests. Assert the ordered selected-region updates. | patch |
| EC1 extreme sample rate | low: selector converts rate to `Int` before the analyzer's 768 kHz guard and can trap on a synthetic carrier with extreme finite rate. Add the same upper bound. | patch |
| EC2 one-sample truncation | low: a short region count such as 32,001 at 8 kHz can round down to 32,000 through seconds conversion. Losing one terminal sample is negligible; an explicit sample-count API adds complexity. | reject |
| EC3 zero-flips claim | false: the spec asks to report zero flips honestly if observed; it does not claim zero. The JSON records nonzero flip counts. | reject |

## Verification

**Commands:**
- `make fmt`, `make lint`, `make build`, `make test`, `git diff --check` — clean per layer.
- `make benchmark`, `make benchmark-giantsteps`, `make oracle` — default floors and DAW diagnostic (if corpus present).
- `make rhythmic-region-impact-report` — sets both corpus paths and `RHYTHMIC_REGION_IMPACT=1`, runs the paired A/B/C/D test in Release. `make perf-benchmark` is Debug and default-only, so is not opt-in timing evidence.

**Results (2026-10-26):** `make fmt`, `make lint`, `make build`, and `git diff --check` passed. Final `make test` passed 1,222 tests with the four known `AccuracyFloorTests` issues. Seventeen focused selector/integration tests passed after review fixes, including both matrix rows. The revised env-gated full Release impact run passed over every track; a one-track smoke run passed after the filename-only report correction, and every full-report regression list was checked against its per-track rows. Final `make benchmark` passed at OA300 58/82 Acc1 and 74/82 Acc2; `make benchmark-giantsteps` passed at 537/661 and 546/661; `make oracle` passed (its window-voting configuration reports 58/82 and 73/82). The pinned opt-out bytes were independently checked against a clean archive of `71d25eb2d3f9c997fc6856a48e64097f0aa57c74`.
