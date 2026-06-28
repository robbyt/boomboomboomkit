---
title: 'Symmetric, authoritative octave disambiguation (demote-to-fundamental fix)'
type: 'bugfix'
created: '2026-06-27'
status: 'rejected'
baseline_commit: 85932b3d9342393729f699a4338e9b5c16f260da
context: ['{project-root}/_bmad-output/implementation-artifacts/investigations/accuracy-ceiling-sweep-investigation.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BPMAnalyzer.resolveOctaveAmbiguity` can only ratchet UP in tempo: `var best = candidates[0]` and `best` is reassigned ONLY to `faster` (lines ~2148, ~2168) — there is no demote path. So when `subBandVote` correctly elects the slower fundamental (it already returns `candidateSlow` on `slowWeight >= fastWeight`), the decision is silently discarded and falls through to a faster-only fallback. On OA300 this is the dominant failure: 16/24 misses are exact octave errors (11 double + 5 half), most being the true fundamental doubled at candidate rank 1. Octave-perfect ceiling = 58 → 74/82.

**Approach:** Two changes to `resolveOctaveAmbiguity`: **(a)** add the missing demote path so a `subBandVote` slow result sets `best = slower` (the pure bug fix — a slow vote is currently discarded); **(b)** make the vote authoritative by skipping the faster-biased fallback when sub-bands are active. Resolve the octave family ONCE (anchored on `best`) to avoid a cascade, with a hard perceptual demotion floor. Ship directly to the default `.optimal` pipeline, keep-or-revert. Fold in a reporting-only `true1xRank` field so the forensic JSON quantifies the fix's reach. The demote path targets the ~11 OA300 DOUBLE misses specifically (the 5 half-misses need promotion, which this fix does NOT change and which change (b) may mildly hurt). The lift is CONTINGENT (≤ the ~11 doubles) on two UNVERIFIED facts: that `subBandVote` actually votes slow on the double-misses (busy breakbeat hi-hats may already vote fast), AND that the slow fundamental is a literal candidate (the resolver votes only over candidate pairs); the benchmark is the arbiter and `true1xRank` measures the second. Changes (a)+(b) are coupled and remove a currently load-bearing fast-override — see Ask First.

## Boundaries & Constraints

**Always:** Honor `subBandVote` as authoritative when `subBandACFs.count == 4 && onsetRate > 0` (set `best = winner` for BOTH faster and slower, then `continue` past the fallback). Resolve the 2:1 octave ONCE per octave family, anchored on the current `best` — never cascade across arbitrary pairs (e.g. `[166, 83, 42]` must NOT collapse `166→83→42`). Never demote below the perceptual floor (`>= bpmMin`). The demote MAY be gated behind a vote margin / abstain (demote only on decisive slow evidence) as the recommended robustness measure (see Design Notes / W53); start with the existing tie-favors-slow contract and tighten to a margin only if the divergence test or benchmark shows marginal false demotes. Swift 6 strict concurrency, value types, Accelerate/vDSP for bulk math. Pipeline step identifiers stay stable. `true1xRank` is additive-only (does not alter existing recall fields/aggregates).

**Ask First:** If `make benchmark` shows OA300 does NOT net-lift Acc1 by ≥2 tracks, OR `make benchmark-giantsteps` regresses below 537/546, OR any OA300 per-genre bucket / DnB sentinel regresses Acc1 → HALT and surface for the revert decision (do not silently keep). Changes (a) and (b) are COUPLED — (a) alone is a no-op because the fallback re-promotes a just-demoted candidate (`faster.score >= slower.score*0.5` is ~always true), so "ship (a) alone" is NOT a valid fallback position. If change (b) regresses currently-correct tracks, the de-risking knob is a DEMOTION VOTE-MARGIN / ABSTAIN GATE (demote only when `slowWeight − fastWeight` is decisive; else keep the current `best`); full revert is the last resort. Any change to `subBandVote`'s tie-favors-slow contract. Adding a perceptual ~120 BPM resonance prior (it is the deliberate follow-up, not this PR).

**Never:** No new `Options` flag and no new `DSPTechnique` case (quorum: this is a verified logic bug, not an experiment — flags preserve broken behavior; a case doubles the 256→512 ablation matrix). No triplet (3:2 / 2:3) winner promotion — stays trace-only. No perceptual-prior / learned-classifier this PR. No change to the no-sub-band fallback fused-energy heuristic. No new SPM deps.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Slow vote demotes | candidates `[166 (rank1), 83]`, sub-bands present, `subBandVote → 83` | `best = 83`; `HarmonicRatioEvidence(2:1, winner=83)`; fallback skipped | N/A |
| Fast vote promotes | candidates `[83 (rank1), 166]`, `subBandVote → 166` | `best = 166` (existing behavior preserved) | N/A |
| No cascade | candidates `[166, 83, 42]`, vote favors 83 over 166 | `best = 83`, NOT 42 (single family decision anchored on `best`) | N/A |
| Perceptual floor | a slow vote whose target `< bpmMin` | demotion blocked; `best` stays `>= bpmMin` | guard |
| No sub-bands | `subBandACFs == []` or `onsetRate == 0` | fallback fused-energy path byte-unchanged | N/A |
| Vote-vs-fallback divergence (regression watch) | candidates `[80 (rank1), 160]`, sub-bands present, `subBandVote → 80`, but fallback energy/score gates would currently promote 160 | NEW: `best = 80` (vote authoritative, fallback skipped) — a DELIBERATE divergence from current behavior; the corpus AC must confirm change (b) causes no net / per-genre / sentinel Acc1 regression | guard via benchmark |
| true 1× present | octave miss, fundamental is a literal candidate | `recall.true1xRank` = its 1-based rank | N/A |
| true 1× absent | octave miss, fundamental only synthesizable | `recall.true1xRank == nil` | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` -- `resolveOctaveAmbiguity` (~L2118-2199): the asymmetric 2:1 decision (FIX SITE); `subBandVote` (~L2065-2096) already returns slow correctly (do not change its contract); `confirmWithSubBandPeaks` (~L2210) is separately faster-only (out of scope, note only).
- `Sources/BoomBoomBoomKitTestSupport/AccuracyForensics.swift` -- `CandidateRecall` struct + `candidateRecall(...)`: add `true1xRank: Int?` (reporting-only).
- `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` -- add octave-resolver unit tests (`@testable` reaches the internal static).
- `Tests/BoomBoomBoomKitTests/AccuracyForensicsTests.swift` -- add a `true1xRank` present/absent unit test.
- `docs/deck-conflicts.md` -- §3 octave disambiguation: update to describe the now-symmetric authoritative vote.

## Tasks & Acceptance

**Execution:**
- [ ] `Sources/BoomBoomBoomKit/BPMAnalyzer.swift` -- restructure the 2:1 branch of `resolveOctaveAmbiguity`: make `subBandVote` authoritative+symmetric (`best = winner` for faster OR slower, then `continue`), resolve the octave once anchored on `best` (no cascade), enforce the `>= bpmMin` demotion floor; leave triplet trace + the no-sub-band fallback unchanged.
- [ ] `Sources/BoomBoomBoomKitTestSupport/AccuracyForensics.swift` -- add `true1xRank: Int?` to `CandidateRecall`; populate it with the rank of the first candidate matching ANY truth at factor exactly 1.0.
- [ ] `Tests/BoomBoomBoomKitTests/BPMAnalyzerTests.swift` -- unit-test the I/O matrix: slow-vote demotes, fast-vote promotes, no-cascade `[166,83,42]→83`, perceptual floor, no-sub-band path unchanged, AND the vote-vs-fallback divergence case (slow vote authoritative over a fallback that would promote).
- [ ] `Tests/BoomBoomBoomKitTests/AccuracyForensicsTests.swift` -- unit-test `true1xRank` present vs absent.
- [ ] `docs/deck-conflicts.md` -- update §3 to the symmetric authoritative-vote behavior.

**Acceptance Criteria:**
- Given the fix, when `make benchmark` runs, then OA300 Acc1 nets ≥ +2 tracks (60/82+, toward the 74 ceiling) and Acc2 ≥ 74/82 — else HALT for the revert decision.
- Given the fix, when `make benchmark-giantsteps` runs, then GiantSteps Acc1 ≥ 537/661 and Acc2 ≥ 546/661 (no regression).
- Given the fix, when the OA300 per-genre stratified table + the 12 DnB sentinels are inspected, then no genre bucket and no sentinel regresses Acc1 vs baseline — a net OA300 lift must NOT mask a currently-correct-track regression from change (b).
- Given the fix, when `make accuracy-forensics` runs, then the OA300 `errorTypeHistogram` `double`+`half` bucket shrinks below the committed 16, and per-track `recall.true1xRank` is populated.
- Given `make test`, then all unit tests pass including the new octave + `true1xRank` tests; `make fmt` clean; `make lint` baseline-only.

## Design Notes

- **Root cause:** `subBandVote` (~L2094) already returns `candidateSlow` on `slowWeight >= fastWeight`, but `resolveOctaveAmbiguity` only ever does `best = faster`; the slow vote is dropped and the fallback re-affirms faster. Quorum (codex + agy + MIR literature): octave choice is a tiebreak problem; the existing vote is the right signal once symmetric.
- **(a)+(b) are coupled.** (a) demote path (slow vote → `best = slower`) + (b) skip the fallback when the vote is active. (a) alone is a no-op — the fallback re-promotes the demoted candidate (`faster.score >= slower.score*0.5` ~always true). (b) is the risk: a slow vote currently falls through to a fallback that can promote-to-fast, so tracks *currently correct* via that override demote to wrong-slow.
- **Robustness knob = demotion vote-margin / abstain** (not "ship (a) alone", which is invalid): demote only when `slowWeight − fastWeight` is decisive, else keep `best`. Makes a fired demote stick, avoids marginal false demotes; mirrors W53 ("override only when evidence is decisive") + the literature's confident-tiebreak. Start at the existing tie-favors-slow contract; tighten to a margin only if the divergence test/benchmark shows false demotes.
- **Reach ≤ ~+11 (doubles), not +16.** The demote targets the ~11 doubles (needs the slow fundamental as a literal candidate — `true1xRank` — AND a slow vote); the 5 halves need promotion (unchanged) + are at mild (b)-risk.
- **Anti-cascade:** anchor on `best`, resolve the octave family once (`[166,83,42]` must not collapse); floor demotion at `bpmMin`.
- **Follow-ups (out of scope):** ~120 BPM perceptual resonance prior (Van Noorden & Moelants 1999) + learned octave classifier (Schreiber & Müller; Gkiokas SVM) — new hyperparameters; GiantSteps has zero regression margin.
- **Gating:** direct fix to default `.optimal`, keep-or-revert (unanimous quorum) — honors the Epic-13 "no default ship without a measured ≥2-track OA300 lift + no GiantSteps regression" without a flag or ablation-set expansion.

## Verification

**Commands:**
- `make test` -- expected: green, including the new octave-resolver + `true1xRank` unit tests.
- `make benchmark` -- expected: OA300 Acc1 ≥ 60/82 (net ≥ +2 over 58), Acc2 ≥ 74/82; revert if no lift.
- `make benchmark-giantsteps` -- expected: Acc1 ≥ 537/661, Acc2 ≥ 546/661 (no regression).
- `make accuracy-forensics` -- expected: OA300 `double`+`half` bucket < 16; `true1xRank` populated per track.
- `make fmt` -- expected: clean. `make lint` -- expected: baseline only (LUFSAnalyzer TODO).

## Result — REJECTED (2026-06-28, reverted to baseline 85932b3)

All FOUR demote variants regressed both corpora and were reverted; the fix premise was empirically false.

| Variant | OA300 Acc1 | GiantSteps Acc1 |
|---|---|---|
| Baseline | 58/82 | 537/661 |
| Un-gate, symmetric authoritative vote | 40/82 (−18) | 503/661 (−34) |
| Un-gate, strict-tie (Ask-First tie-contract flip) | 39/82 (−19) | 507/661 (−30) |
| Score-guarded demote @0.8 | 54/82 (−4) | 534/661 (−3) |
| Score-guarded demote @0.95 | 56/82 (−2) | 536/661 (−1) |

**Why it failed:** the faster-only ratchet is LOAD-BEARING compensation for ACF subharmonic bias (a signal periodic at `T` is also periodic at `2T`, so the slow octave autocorrelates ≥ the fundamental — measured ~25% stronger in all 4 bands for a 160 click, a strict slow win, not a tie). Un-gating the vote demoted ~18 OA300 + ~34 GS correct fast tempos to near-zero-score subharmonic ghosts (0.70-score anchor → 0.009-score demote). A score-plausibility guard blocks the ghosts (clicks stay correct) and cuts the damage ~5×, but it **asymptotes to baseline from below** (0.8→−4, 0.95→−2) and never overshoots — the empirical ceiling of any demote-based octave lever is NEUTRAL, not a lift, because the slow octave is genuinely score-competitive on enough correct-fast tracks. A unanimous codex+agy+MIR-literature quorum was wrong and conceded in post-mortem. **Do NOT re-attempt demoting periodicity candidates in ANY form.** Next levers (must not trust raw periodicity) + full citations: see `investigations/accuracy-ceiling-sweep-investigation.md` Follow-up 2026-06-28.
