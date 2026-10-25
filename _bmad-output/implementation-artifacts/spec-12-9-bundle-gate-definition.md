---
title: 'Story 12.9: define and exercise the bundle gate'
type: 'feature'
created: '2026-10-25'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '4a74a2233ada0874b2f3bbda9fa266b80c54c77e'
context: []
---

<frozen-after-approval reason="human-owned intent, do not modify unless human renegotiates">

## Intent

**Problem:** Story 12.9's 258-track, 12-net-track bundle rule does not describe the signed 12.7 corpus: 172 members, no 100-120 members, and pending signoff. The operator wants to use additional blinded, hand-annotated DAW tracks rather than treat GiantSteps as a gate arm.

**Approach:** Define a separate, provisional gate cohort from the 172 signed members plus every sound, unique, blinded `e1`-`e5` DAW row; freeze its provenance and implement a paired DSP versus balanced-peer DSP+ML evaluator. Exercise it with the failed Epic 7 model, but keep final bundle approval blocked until the corpus and training partition obligations are signed off.

## Operator decisions (2026-10-25)

- One combined primary cohort; report the original 172 as a locked subset. Admit valid surplus and out-of-band `e` rows under the new cohort only, never by moving them into 12.7 membership. Keep detector-visible `x1` rows report-only.
- Define the gate now, with no bundle approval before the slow-band and signoff obligations clear. Use exact two-sided McNemar `p <= 0.05`, with no fixed 12-track floor; state the required net lift in tracks for observed discordance.
- For unequal bands, a band with at least 43 rows is DSP-handled when DSP gets at least `ceil(30 * n / 43)` correct; require gains >= losses there. Sparse bands are unmeasurable, not passing.
- Freeze `EnsemblePolicy.default` (equal-weight balanced peers) as the DSP+ML arm; `Options` stays `.dspOnly` by default.

## Boundaries & Constraints

**Always:** Preserve the 172 signed labels as authoritative, even if a later DAW clip is stale. The project currently suggests 73 additional stable `e` rows, for 245 proposed rows before audio and partition checks; compute and bind the actual cohort, never force that count. Every included row needs one finite verified tempo, source audio with a verified hash, precommitted opaque ID, no duplicate or unstable finding, and a declared source/verified band. Missing data fails closed. All private row data stays gitignored. Record a dated 12.6 protocol amendment and FR-69c's five risk answers.

**Never:** Change the frozen 12.7 candidate commitment, membership, annotation log, or training manifests; use `ingest-dawproject-labels.py`; admit detector-visible `x1` rows to pass/fail; tune the candidate, ensemble policy, or thresholds against gate results; treat OA300 or GiantSteps as gate arms; change `Sources/` behavior or ship model weights.

</frozen-after-approval>

## Code Map

- `scripts/build-eval-corpus.py`: `read_dawproject_clips`, `project_tracks`, `HarnessState.by_row_id`, `_resolve_audio`, audio hashing, membership and partition audit. Read its private state; leave existing 12.7 commands and signoff unchanged.
- `scripts/dawproject-bpm.py`: read-only warp BPM and file path extraction. `scripts/dawproject-annotations.py` adds downbeat/span metadata, not tempo-gate eligibility; `ingest-dawproject-labels.py` writes training labels and is forbidden here.
- `_bmad-output/ml-training/eval-corpus/generations/<gen>/`: ignored 172-member JAMS, membership, draw sequence, staging, and supplement. All 248 DAW `e` IDs occur in the committed draw sequence; 172 are members, with one signed member whose current project has a stale conflicting clip.
- `Tests/BoomBoomBoomKitBenchmarkTests/FR18EvaluationHarnessTests.swift` and `_bmad-output/ml-training/evaluate_fr18.py`: reuse the runtime producer pattern, Acc1, calibration (`ECE_half_double < 0.10`, subset N>=100), and report provenance. Its `.mlOnly` result is DSP-contaminated on abstain and cannot stand in for the combined arm.
- `_bmad-output/ml-models/giantsteps_v2_seed_42.mlmodelc`: available failed-model smoke input; seed 43/44 absent. `4-dnb-triplet-targets.json` holds four sentinels. `12-6-metrical-level-convention.md` section 6 and `deferred-work.md` carry the signed protocol and final-run obligation.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/build-bundle-gate-cohort.py` -- use existing DAW/corpus readers to freeze a private generation-bound cohort, preserve signed member labels, add only sound nonmember `e` rows, record hash/provenance/category/verified band, and fail closed on missing audio or unresolved duplicates.
- [x] `12-6-metrical-level-convention.md` and `12-9-bundle-gate.md` -- dated amendment, denominator and band rules, FR-69c risk resolutions, final-signoff block, and governance of a single frozen model/policy evaluation.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/BundleGateEvaluationTests.swift` -- env-gated production-path producer for DSP-only and `.default` DSP+ML on identical input, with model diagnostics, sentinels, full manifest accounting, and no private corpus-specific path in `Sources/`.
- [x] `_bmad-output/ml-training/evaluate_bundle_gate.py` and Makefile targets -- exact paired gate, per-band and locked-subset tables, calibration and four sentinel gates, contextual legacy-corpus reports, seed robustness, fail-closed signoff/partition conditions, and a real seed-42 negative-control run. Do not let signoff refusal alone count as negative-control rejection.
- [x] Python and Swift tests -- cover cohort exclusions, missing/stale data, abstains, exact-test boundaries, unequal/sparse bands, calibration inconclusive, substantive negative-control rejection, and refusal before closure.
- [x] `deferred-work.md` and `sprint-status.yaml` -- record final signed-corpus/model run and any unresolved dependency; mark 12.9 done when the defined-and-tested slice is complete.

**Acceptance Criteria:**
- Given the current project and 12.7 state, when the cohort is frozen, then it contains the 172 unchanged member labels plus only eligible extra `e` rows, with no `x1` row, and a digest-bound count and band table.
- Given paired predictions on that fixed cohort, when the evaluator runs, then it reports `b`, `c`, `d`, net tracks and exact two-sided p, per-band gains/losses, and the 172-member subset, with no percentage-only lift claim.
- Given sparse slow bands, missing partition closure or signoff, or inconclusive calibration, when a bundle decision is requested, then it refuses approval while still emitting an honest provisional report.
- Given the failed `giantsteps_v2_seed_42` model, when the negative control runs, then a substantive model/ensemble gate rejects it, and the report labels training-overlap limits.
- Given the branch diff, when reviewed, then no production code behavior, training manifest, frozen 12.7 corpus, model weights, or private row data is committed.

## Implementation Notes

## Verification

**Commands:** `make py-lint`, focused Python tests, `make test`, env-gated Swift producer smoke, `git diff --check`; negative-control output must show a substantive failing gate and no final bundle approval.

**Result:** 27 focused Python tests passed; direct `uv run ruff check` and `ruff format --check` passed on the touched Python files; `swift format lint --strict` passed on the producer; `make test` passed 1,205 tests with four known issues; and `git diff --check HEAD` passed. The revised production run accounted for 249 inputs and independently failed the paired, calibration, and four-sentinel gates. No review finding remained deferred; final corpus and partition closure remains deferred as listed in `deferred-work.md`.

## Review Triage Log

| Finding | Verdict and evidence | Route |
| --- | --- | --- |
| Blind 1: committed state is not validated at freeze | medium: `main` constructs `HarnessState` but never calls `require_valid_state`, so edited pools or draw bytes can enter a cohort under the old commitment hash. | patch |
| Blind 2: DAW audio association is unchecked | medium: an extra row's DAW clip can refer to `audio/<opaque-id>.<ext>` with bytes different from the committed source; tempo agreement alone does not bind the recording. A sampled current extra matches, but the guard is absent. | patch |
| Blind 3: signed member labels can change in a recomputed private cohort | medium: `load_cohort` verifies source-file hashes but does not compare locked IDs and tempos with those files. Recomputing the self-digest permits altered labels. | patch |
| Blind 4: sentinels can be substituted in the input | medium: `_read_run` checks the mutable input but not the four original sentinel fixture IDs, labels and audio. | patch |
| Blind 5: seed checkpoints need distinct identities | medium: three run directories can carry the same checkpoint hash and still pass the dispersion rule, defeating the declared three-seed check. | patch |
| Blind 6: negative control accepts another seed's failure | medium: `--negative-control` checks any collected substantive failure; an unrelated seed can make seed 42 appear rejected. | patch |
| Blind 7: ML abstentions are undercounted | low: a confidence-gate rejection retains `decodedBPM`, so `modelBPM == nil` reports a vote for an abstention. This changes the current descriptive abstention count. | patch |
| Blind 8: predictions lack a manifest digest | medium: changing prediction bytes after production is not detected by `_read_run`, although its input bytes are bound. | patch |
| Blind 9: older macOS produces a vacuous pass | low: the availability `if` has no `else`, so the env-gated test returns success without writing rows on macOS below 15. | patch |
| Blind 10: evaluator input guards lack tests | medium: `_read_run` and negative-control selection have no focused tests; the demonstrated substitution and seed-mixing cases would survive current tests. | patch |
| Edge 1: signed labels can change | medium: same changed-cohort path as Blind 3; a recomputed self-digest is accepted without signed JAMS comparison. | patch, grouped with Blind 3 |
| Edge 2: checkpoint hash omits weights | medium: compiled `.mlmodelc` stores `weights/weight.bin` separately from top-level `coremldata.bin`; the current hash can remain fixed while weights change. | patch |
| Edge 3: negative control can pass on another seed | medium: same shared-directory failure as Blind 6. | patch, grouped with Blind 6 |
| Edge 4: older macOS vacuous pass | low: same missing availability `else` as Blind 9. | patch, grouped with Blind 9 |
| Verification gap 1: policy manifest can diverge | medium: the candidate policy and its manifest string are separate literals; a policy edit could mislabel results while existing tests check only row accounting. Use the actual policy's stable key. | patch |
| Verification other 1: negative-control seed mixing | medium: same shared-directory failure as Blind 6. | patch, grouped with Blind 6 |
