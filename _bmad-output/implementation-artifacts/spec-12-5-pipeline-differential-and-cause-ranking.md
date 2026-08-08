---
title: 'Story 12.5: Pipeline differential and cause ranking'
type: 'chore'
created: '2026-08-08'
status: 'done'
baseline_revision: '12699f4'
final_revision: 'f6f2b14'
review_loop_iteration: 0
followup_review_recommended: true
context: []
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** Story 12.4 proved the 197-track gap (reference 545/661 vs our 348/661, FR-18-strict, same rows and ruler) is attributable to our model, but nobody has written down WHICH difference between the two pipelines causes it, so the next retrain lever would be funded on a guess — the exact failure FR-57/FR-58 exist to prevent.

**Approach:** Write the differential artifact covering all eight FR-57 axes (input representation, window policy, bin schema, loss, augmentation, corpus composition, decode, evaluation protocol), each labelled exactly one of `suspect` / `neutral` / `ruled out` with cited evidence; then rank the suspected causes by expected contribution and cost to test (FR-58), record in epics.md that this ranking supersedes the charter's corrected lever ranking as the driver after F2 (annotate, never delete), and file any ranked cause outside Epic 12's scope as Epic 14 input in deferred-work.md. Analysis only.

## Boundaries & Constraints

**Always:**
- `Sources/` and `Tests/` byte-identical to the branch base (`git diff --stat 12699f4 -- Sources/ Tests/` empty).
- Every literature claim about the reference traces to primary text (the 2018 ISMIR paper, the 2019 SMC/TISMIR follow-ups, or the already-traced facts in the 12.4 report and PRD section 4.3). A fact that cannot be traced is labelled `unknown` on its axis, never invented. The PRD records that a summarizer previously fabricated figures; the 82.1/97.1 pair is annotated unconfirmed.
- Each axis carries exactly one label plus the evidence that earned it; evidence cites a measured artifact (12.4 report, predictions.json, FR-18 dumps, 12.3 octave-error data) or primary text.
- The ranking orders SUSPECT causes only, by expected contribution x cost to test, and states the expected-contribution basis per cause (measured where possible, e.g. the octave-recoverability split: 100/116 reference misses octave-recoverable vs ~53/313 of ours).
- The gap instrument stays FR-18-strict throughout; other protocols appear only as labelled context (the 12.4 precedent).
- Amend-not-erase with dated annotations (2026-08-08) for epics.md and any planning artifact touched. No emojis, no em-dashes in artifacts.
- GPL/AGPL implementation repos are never named in commits or PRs; develop-only artifacts may name them. Cite Schreiber and Mueller academically.

**Block If:**
- The evidence forces a gap verdict contradicting 12.4's `gap-attributable-to-our-model` (would re-open Gate 0 — operator call).
- The ranking's top cause cannot be stated without new measurement runs exceeding this story (the story is analysis of existing evidence; a required new experiment is a finding, not a task).

**Never:**
- No code changes anywhere (Makefile included). No new measurement harnesses or corpus runs. No re-scoring.
- Do not act on any ranked cause (no retrain, no decode change) — Epic 14 or later stories own action.
- Do not delete or rewrite the charter's corrected lever ranking; annotation only.
- Do not relabel or touch the GiantSteps ground-truth artifacts.

</intent-contract>

## Code Map

- `_bmad-output/implementation-artifacts/12-4-tempocnn-baseline-report.md` -- primary input: reference per-axis facts (11025 Hz / 40 mel 20-5000 Hz / 1024-512 STFT / 256-frame windows, hop-128 class-averaged decode, 256 classes 30-285), all scored figures, and the "per-axis observations handed to Story 12.5" section (lines 123-140)
- `_bmad-output/ml-training/tempocnn-baseline/predictions.json` -- per-track reference predictions for error-structure comparison
- `_bmad-output/ml-training/fr18-predictions-191/seed_42/predictions.json` -- our 348/661 per-track predictions (the other half of the comparison). Planning originally named `fr18-predictions/maskedMelPretrain/seed_42/predictions.json`, but that dump scores 330/661 (an older rebalanced run); the -191 dump reproduces the pre-registered 348 exactly (verified during implementation). Both dumps agree octave-recoverable = 53.
- `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md` -- E0 finding: sub-100 BPM misses are clean octave doublings; 100-120 genuinely mis-pulsed
- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- FR-57 (:143), FR-58 (:144), section 4.3 traced literature (reference loss = one-hot CE, no Gaussian smearing; our targets octave_mass 0.15 + label smoothing)
- `_bmad-output/planning-artifacts/epics.md` -- Story 12.5 ACs (:2168-2200); charter's corrected lever ranking (:~2406-2431) and its supersession header (:2369) which already says FR-58 governs once it exists
- `_bmad-output/ml-training/{dataset.py,feature_substrate_v2.py,train.py,evaluate_fr18.py}` -- our-side axis facts (44100 Hz / 128 mel / 2048 FFT / single 512-frame tensor per track, per-band z-score; CE + octave_mass 0.15; augmentation set; Tony-corpus v2 splits; argmax+30 with 60-200 abstain, 115/256 bins decode-dead per #147)
- `_bmad-output/implementation-artifacts/deferred-work.md` -- Epic 14 input entries land here (`## Deferred from: Story 12.5 (2026-08-08)` + source_spec/summary/evidence/re-open-trigger shape)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- `12-5-pipeline-differential-and-cause-ranking`

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/implementation-artifacts/12-5-pipeline-differential.md` -- write the differential: (1) a two-column per-axis table (ours vs reference) for all eight FR-57 axes; (2) one labelled verdict section per axis with evidence; (3) an error-structure section quantifying the octave-recoverable vs mis-pulsed split on both models from the two predictions.json files (recompute the ~53/313 figure exactly rather than citing the approximation); (4) the FR-58 ranking of suspect causes with per-cause expected-contribution basis and cost-to-test; (5) an Epic-14-input list naming which ranked causes are out of Epic 12 scope; (6) provenance (input artifact SHAs or commit, primary-text citation ledger following the 12.4 report's ledger format)
- [x] `_bmad-output/planning-artifacts/epics.md` -- dated annotation at the charter's corrected-lever-ranking section: the FR-58 ranking now exists (name the artifact), it supersedes this ranking as the driver after F2, per-item note where the two orderings disagree; charter text retained
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` -- one `Deferred from: Story 12.5` entry per out-of-scope ranked cause, each with evidence pointer and re-open trigger (Epic 14 scoping)
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- flip `12-5-pipeline-differential-and-cause-ranking` to `in-progress` at start (done happens post-review)

**Acceptance Criteria:**
- Given the differential artifact, when its axis sections are enumerated, then all eight FR-57 axes appear and each carries exactly one of `suspect` / `neutral` / `ruled out` with evidence; sub-facts that could not be traced are marked `unknown` inside the axis rather than silently omitted.
- Given the ranking, when read, then it orders only suspect causes, states expected contribution and cost to test per cause, and its expected-contribution claims cite measured artifacts or primary text.
- Given epics.md after the edit, when the charter ranking section is read, then the original nine-item ranking is intact and a dated annotation states the FR-58 ranking supersedes it after F2.
- Given a ranked cause outside Epic 12's scope, when the story lands, then deferred-work.md carries it as Epic 14 input and no repo change acts on it.
- Given the branch diff against `12699f4`, when restricted to `Sources/` and `Tests/`, then it is empty.
- Given every literature figure in the artifact, when checked against the citation ledger, then it traces to a named primary source or is labelled unknown/unconfirmed.

## Spec Change Log

## Review Triage Log

### 2026-08-08 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 14 (high 0, medium 5, low 9)
- defer: 1 (low 1)
- reject: 2
- addressed_findings:
  - `[medium]` `[patch]` "track-for-track equal to the published figure" overclaim reworded to count-for-count at both sites, with the 82.45-rounds-to-82.5 reconciliation
  - `[medium]` `[patch]` Section 3.7 no longer claims #141 proves posterior information absence; scoped to the tested threshold-rule family
  - `[medium]` `[patch]` Rank 1 / rank 2 non-independence cross-referenced in the differential and both deferred-work entries (rank 2 is rank 1's probe)
  - `[medium]` `[patch]` epics.md annotation: charter item 4 reclassified as an enabler unaffected by supersession; its substrate-reproducibility/backend-first invariant stated as binding FR-58 rank 3 in all three sites
  - `[medium]` `[patch]` FR-69c caveat added to section 3.6 (100-120 pool falls to 27 excluding GiantSteps)
  - `[low]` `[patch]` Full path for octave-bias-finding-and-plan.md at first use; deferred-work gate reference corrected to PRD Gate 1/2; reproduction recipe added to section 2; unbacked dump dates dropped (SHA identification only); symbol names added to line citations and BNNSTechnique lines corrected to :885/:890; zero-abstains fact added to the decode-forfeit argument; octave-mass negative existence claim labelled PRD-inherited; ledger caveat row moved to body prose; sprint-status flipped to done
- Rejected: "planning promoted ahead of story acceptance" and the sprint-status/epics contradiction — the supersession statement is an explicit AC of this story and the whole story lands in one commit with the done flip.
- Deferred: the committed 12.4 baseline report also says "track-for-track"; pre-existing, outside this story's file set.

### 2026-08-08 — Review pass (PR #194, post-done follow-up)
- intent_gap: 0
- bad_spec: 0
- patch: 7 (high 0, medium 2, low 5)
- defer: 0
- reject: 0
- addressed_findings:
  - `[medium]` `[patch]` epic-12-context "12.1 done" vs sprint-status "review": accepted with the fix INVERTED per operator confirmation — 12.1 IS done (merged as 13135f8, later stories built on it); sprint-status and the 12-1 spec status/final-revision fields updated to done; context sentence retained
  - `[medium]` `[patch]` Gate-0 present-tense text at epics.md:2001 annotated (dated, amend-not-erase): Gate 0 ran at 12.4 and did not fire, so a compile-epic-context regeneration no longer reverts the context doc's paragraph
  - `[low]` `[patch]` Reproduction recipe corrected: corpus filter applies to our dump only; the reference dump's 661 tracks rows carry no corpus key
  - `[low]` `[patch]` Rank-1 corpus evidence restated with Tony training columns leading (786/26, 30:1) at all three sites; pooled 980/62 kept as labelled context (includes the GiantSteps evaluation set)
  - `[low]` `[patch]` Falls-to-27 cite corrected to PRD 5.3; 5.3 added to the provenance ledger's PRD section list
  - `[low]` `[patch]` deferred-work gate pointer corrected from "epics.md section 6 gate table" to PRD section 6, "Decision Gates and Stopping Rule"
  - `[low]` `[patch]` Code Map charter-ranking anchor corrected from :~2450-2470 (Epic 13 charter) to :~2406-2431

## Design Notes

- The evaluation-protocol axis is `ruled out` by construction: 12.4 scored both models on identical rows, annotations, and tolerance, and the harness reproduced the published 82.5 figure exactly. Say so with the reproduction as evidence; do not re-argue it.
- The reference's training-side axes (loss, augmentation, corpus composition) are NOT in the 12.4 report — they come from the 2018/2019 primary texts. PRD section 4.3 already traces loss (one-hot CE, no smearing). Augmentation and training-corpus composition need the papers; if the exact training-set enumeration cannot be confirmed from primary text available during implementation, label those sub-facts unknown and reflect the uncertainty in the ranking's confidence.
- Expected-contribution arithmetic that exists today: octave-recoverable misses bound what a pure decode/octave fix can recover on our model (348 -> ~401 ceiling, still ~144 short of 545), which is direct evidence that octave handling alone cannot close the gap — a load-bearing input to the ranking.
- Cost-to-test should reuse the charter's Enablers list (raw-audio evaluation path, full-posterior dumps) when pricing experiments, not invent new infrastructure.

## Verification

**Commands:**
- `git diff --stat 12699f4 -- Sources/ Tests/` -- expected: empty
- `make pre-commit` -- expected: green (no Swift or Python source changes, but the gate chain runs)
- `grep -c "suspect\|neutral\|ruled out" _bmad-output/implementation-artifacts/12-5-pipeline-differential.md` -- expected: >= 8 axis labels present
- `grep -n "2026-08-08" _bmad-output/planning-artifacts/epics.md` -- expected: the supersession annotation present near the charter ranking

**Manual checks (if no CLI):**
- Read each axis verdict against its cited evidence; confirm no figure appears without a ledger row.

## Auto Run Result

Status: done.

Implemented: `12-5-pipeline-differential.md` (eight-axis FR-57 differential, exact error-structure recomputation, FR-58 ranking, Epic 14 input list, provenance + primary-text citation ledger sourced from the ISMIR 2018 paper itself); epics.md dated supersession annotation on the charter's corrected lever ranking; five Epic-14-input entries plus one defer entry in deferred-work.md; sprint-status flipped to done.

Key results: axis labels input representation/window policy/loss/augmentation/corpus composition suspect, bin schema/decode neutral, evaluation protocol ruled out. Ranking: 1 corpus composition, 2 augmentation breadth, 3 input representation, 4 multi-window aggregation, 5 loss target shape. Error structure recomputed exactly: ours 348 hits, 313 misses, 53 octave-recoverable, 260 mis-pulsed; reference 545/116/100/16. Notable: the Code Map's originally-named our-side dump scored 330/661 (older rebalanced run); the pre-registered 348 lives in `fr18-predictions-191/seed_42/` and both dumps agree octave-recoverable = 53 (Code Map corrected).

Review: two-reviewer pass, all load-bearing numbers independently reconfirmed; 14 patches applied (5 medium, 9 low), 1 defer, 2 rejects, no intent gaps, no bad_spec. Follow-up review recommended: true (patch volume and breadth across four artifacts).

Verification: `git diff --stat 12699f4 -- Sources/ Tests/` empty; `make pre-commit` green (fmt, lint, scripts-tests, ml-training-tests 37 passed); label grep >= 8; epics annotation present. Committed as f6f2b14 on rterhaar/12-5-pipeline-differential (this frontmatter/result update follows in a separate commit, the 12.4 precedent).

Residual risks: reference training-side facts rest on one primary source (ISMIR 2018); the 2019 re-annotation paper was used only for the published-figure trace. The FR-58 ranking's top cause (corpus composition) implies Epic 14 work the charter never priced.
