---
title: 'Epic 12 charter records the measured octave verdicts and the corrected lever ranking (GH-166)'
type: 'chore'
created: '2026-07-26'
status: 'done'
baseline_commit: '2f4d696'
review_loop_iteration: 1
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** #166 seeds Epic 12, but its top-ranked lever is half-disproved: GH-141 implemented the octave-folded posterior decode, measured it net-negative at every threshold, and removed it. The charter (`epics.md:1803`) still presents that step as "+53 GiantSteps tracks of headroom (348 → 401 oracle ceiling)" awaiting measurement, and `octave-bias-finding-and-plan.md:75-83` still calls it "free, this is the immediate win". Three `deferred-work.md` entries defer their correction to exactly this artifact. Anyone drafting Epic 12 from these documents today would re-implement deleted code.

**Approach:** Rewrite the Epic 12 charter as the authoritative decision record and PRD seed: the AST verdicts (regression rejected on multimodality grounds, classifier accepted as a harness experiment gated on a CoreML backend), the 2026-07-21 operator compute-constraint change, and a lever ranking corrected for **both** measured octave failures. Append dated corrections to the two satellite stale sites and mark the deferred-work entries resolved.

## Boundaries & Constraints

**Always:** Every number traceable to a named artifact: `141-octave-fold-impact.json` (fold sweep), `deferred-work.md:901` (DSP four-variant sweep), the E0 per-band table at `octave-bias-finding-and-plan.md:25-38`, `accuracy-forensics-{oa300,giantsteps}.json`. Corrections **amend**; a superseded projection stays visible and marked superseded rather than deleted (the FR-29 / FR-34 precedent GH-112 already used). Distinguish measured from projected from untested in every ranking entry. When carrying #147's dead-bin claim, verify both schema declaration sites — `tools/coreml-convert/reference_arch.py:37-39` (ships to `main`) and `_bmad-output/ml-training/dataset.py:59-62` — and note that #147's stale citation is `BNNSTechnique.swift:857` (now `:889`), not its `reference_arch.py` one. *(Amended by the human 2026-07-26 on review iteration 1; the original wording asserted `reference_arch.py` did not exist. See the Spec Change Log.)*

**Ask First:** Closing #166 on GitHub. Assigning story numbers (12.1, 12.2, ...) or promoting any lever from experiment to commitment — the charter stays charter-only until a PRD exists.

**Never:** Do not draft the Epic 12 PRD itself; the operator chose charter rewrite and a PRD is a separate `/bmad-create-prd` run. Do not resurrect the octave-folded decode or any demote-the-candidate-to-a-slower-octave DSP variant — both are measured, removed, and carry explicit re-open triggers. No changes under `Sources/`, `Tests/`, `Demo/`, `scripts/`, `Package.swift`, or `MODEL_CARD.md`. Do not re-run training or benchmarks; every number already exists.

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/epics.md` — charter `:1796-1813`; stale step-1 projection `:1803`; landed-forensics note `:1813`; Epic 13's overlapping octave levers `:1815-1828` (coordinate, do not duplicate).
- `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md` — E0 table `:25-38`; oracle-ceiling caveat `:44-50`; E1 "immediate win" + "Expected: 348 -> ~401" `:75-83`; the false "256-bin hard cross-entropy" claim `:63-64` that #146 corrects.
- `_bmad-output/implementation-artifacts/deferred-work.md` — entries to resolve at `:1184`, `:1212`, `:1224`; the DSP octave-sweep rejection `:901`; forensic substrate `:899`; `:914` shows the inline `**RESOLVED (...)**` form.
- `_bmad-output/implementation-artifacts/141-octave-fold-impact.json` — per-band fold measurement (read-only evidence).
- `Sources/BoomBoomBoomKitML/BNNSTechnique.swift` — read-only facts: `:190` 256 bins, `:193` offset 30.0, `:884` bare-argmax decode, `:889` abstain outside `60.0...200.0`.

## Tasks & Acceptance

**Execution:**
- [x] `epics.md` — rewrite the Epic 12 charter. Record: (a) AST-as-regression evaluated and rejected, AST-as-classifier as a harness experiment gated on the CoreML backend story; (b) the 2026-07-21 operator update removing the CPU-only constraint, and what it does *not* remove; (c) a lever ranking corrected for both measured failures, with the superseded step-1 projection retained and marked; (d) the enabler stories #166 names (raw-audio evaluation path, C5 tunable abstain, C3 model-bound feature version, C6 convert-tool featurize contract, D3 live technique tests); (e) cross-references to #141, #146, #147, #172 and the Epic 13 overlap.
- [x] `octave-bias-finding-and-plan.md` — append a dated correction to the E1 plan item (implemented, measured, net-negative, removed) and to the `:63-64` loss claim (#146: the authoritative v2 path trained with 0.15 octave mass, not hard cross-entropy).
- [x] `deferred-work.md` — mark the three entries whose re-open trigger this change fires as resolved in place, naming this spec; append new entries for anything the rewritten charter defers rather than resolves.
- [x] Post the corrected ranking as a comment on #166 so the issue and the charter agree.

**Acceptance Criteria:**
- Given a reader opens the Epic 12 charter with no other artifact, when they reach the lever ranking, then they can tell for each lever whether it was measured, projected, or untested, and which two were measured and failed.
- Given the charter's original "+53 tracks / 348 → 401" projection, when the file is diffed, then the claim is still present and explicitly marked superseded, not deleted.
- Given `octave-bias-finding-and-plan.md` after the change, when someone greps for `401` or `immediate win`, then every match sits adjacent to a dated correction.
- Given the three deferred-work entries whose trigger reads "the Epic 12 PRD is drafted, OR anyone cites the ~401 projection as live", when the change lands, then each is marked resolved naming this artifact.
- Given the branch diffed against `develop`, when `git diff --name-only` runs, then no path under `Sources/`, `Tests/`, `Demo/`, `scripts/` or `MODEL_CARD.md` appears.

## Spec Change Log

### 2026-07-26 — review iteration 1 (Blind Hunter + Edge Case Hunter)

**RESOLVED 2026-07-26 — human authorized the frozen-block amendment; the proposed wording below was applied verbatim.**

`## Boundaries & Constraints` > **Always** ends: *"When carrying #147's dead-bin claim, cite the schema correctly: `_bmad-output/ml-training/dataset.py:59-62`, not the nonexistent `reference_arch.py:37-39`."* **`reference_arch.py` is not nonexistent.** It is at `tools/coreml-convert/reference_arch.py:37-39`, declares the schema exactly as #147 cites, and is on the `promote-to-main.py` allowlist (line 50), so it ships to `main`. The planning-time search that produced this constraint covered `tools/` but was piped through `head -15` and truncated before reaching it. Both reviewers found this independently.

Proposed replacement wording for the human to accept or edit:

> When carrying #147's dead-bin claim, verify both schema declaration sites — `tools/coreml-convert/reference_arch.py:37-39` (ships to `main`) and `_bmad-output/ml-training/dataset.py:59-62` — and note that #147's stale citation is `BNNSTechnique.swift:857` (now `:889`), not its `reference_arch.py` one.

**Known-bad state avoided:** shipping a charter and a `deferred-work.md` entry that instruct a future engineer to distrust a correct citation, while the genuinely stale one goes unflagged — and describing bin-range alignment as a mechanical develop-only edit when it changes a file that ships to `main` plus the public `MLTechniqueError.binCountMismatch` 256-bin contract.

**KEEP on re-derivation:** the corrected-ranking order and its MEASURED/UNTESTED tags; the two-measured-failures framing; the "amend never erase" treatment of the superseded scope; the #172 selection-vs-generation argument.

**Applied as patches this iteration (outside the frozen block, no loopback needed):** octave-mass tempo-range qualifier (the 0.15 goes wholly to the half above ~142 BPM, inverting the DnB argument — corrected in 3 sites); fold denominator stated as 604 fired = 38 helpful + 346 harmful + 220 neutral; separability restated as nested ranges rather than the max-vs-min extremes; the outside-evidence constraint downgraded from law to working hypothesis scoped to n=1 model; original item 1 re-marked *partially* superseded since its SignalPool-arbiter clause was never built; `octave-bias-finding-and-plan.md` cross-reference repointed from `:63-64` to `:70` after this change shifted it; dangling `OctaveFoldPolicy` pointer noted as deleted; `deferred-work.md` PRD-trigger self-contradiction resolved by naming which trigger clause fired; E4's "only if E1-E3 plateau" precondition repaired; already-wrong step indices in Dependencies flagged rather than blessed; unsourced Core AI and ANE-triviality claims hedged; two false claims corrected publicly on #166.

## Design Notes

**Two independent cheap octave levers have now been measured, and both failed net-negative.** The ML posterior mass-ratio fold (GH-141): every threshold 0.0-1.0 negative on Acc1, best −2 by folding almost nothing; threshold 0.0 recovers exactly the +38 sub-100 tracks E0 predicted at a cost of 346 harmful folds. The DSP demote-to-fundamental vote (2026-06-28, `deferred-work.md:901`): four variants, OA300 Acc1 58 → 40 / 39 / 54 / 56, all reverted. The "cheap first move" slot #166 assumed is empty, and the charter must say so rather than let a reader discover it.

What survives from #166's item (1) is its untested half — Gaussian label smoothing and sub-100 augmentation. Both are training-side, not decode-side, so they belong with #146 (the loss puts 0.15 mass on octave partners, including the 2T bin the model already over-predicts) rather than ahead of it.

#172 moves the problem boundary and the charter should carry it: all four accuracy-floor known failures are **DSP-path** octave errors with no model involved, and on `Submerged_Lament` the correct 70 BPM was already in the candidate list, losing on score (0.97 against 140 at 1.01) — selection-bound, not generation-bound. The operator's own #166 comment draws this conclusion; carry it, do not re-litigate it.

## Verification

**Commands:**
- `git diff --name-only develop` — expected: exactly the three `_bmad-output/` files plus this spec.
- `git diff -- _bmad-output/planning-artifacts/epics.md | grep '^-' | grep -v '^---'` — expected: no removed line carries a measured number; corrections are appended.
- `grep -n '401\|immediate win' _bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md` — expected: every match adjacent to a dated superseded marker.

**Manual checks:**
- Read the rewritten charter end-to-end: a reader who has never opened #141 can tell the fold was implemented, measured, and removed, and why the mass ratio cannot work.
- Confirm no story numbers were introduced — the charter is still labelled CHARTER / UNPLANNED.

## Suggested Review Order

**The verdict itself — read this first**

- Entry point: the two measured failures and what they rule out, stated before any ranking.
  [`epics.md:1804`](../planning-artifacts/epics.md#L1804)

- The outside-evidence hypothesis, deliberately scoped to n=1 model rather than stated as law.
  [`epics.md:1812`](../planning-artifacts/epics.md#L1812)

**The corrected ranking**

- Nine levers, each tagged MEASURED/UNTESTED/BLOCKED, with the by-leverage-not-by-cost ordering stated openly.
  [`epics.md:1832`](../planning-artifacts/epics.md#L1832)

- Item 1 carries the octave-mass correction: the 0.15 goes wholly to the half above ~142 BPM.
  [`epics.md:1836`](../planning-artifacts/epics.md#L1836)

- Item 2 is where the review found the worst error; now scoped as a public-contract change.
  [`epics.md:1837`](../planning-artifacts/epics.md#L1837)

**Why the problem is wider than the model**

- The four DSP-path floor failures, and the selection-vs-generation distinction.
  [`epics.md:1815`](../planning-artifacts/epics.md#L1815)

- AST verdicts: regression rejected on head shape, classifier accepted as a gated experiment.
  [`epics.md:1825`](../planning-artifacts/epics.md#L1825)

**Amend-not-erase discipline**

- The original scope retained, item 1 marked only PARTIALLY superseded.
  [`epics.md:1857`](../planning-artifacts/epics.md#L1857)

- Plan doc: E1 status correction with the 604-fold denominator.
  [`octave-bias-finding-and-plan.md:108`](../ml-training/v2-runs/octave-bias-finding-and-plan.md#L108)

- Plan doc: the loss correction, including the tempo-range qualifier that inverts #146's mechanism.
  [`octave-bias-finding-and-plan.md:76`](../ml-training/v2-runs/octave-bias-finding-and-plan.md#L76)

**Ledger**

- Three entries resolved, three new ones opened.
  [`deferred-work.md:1216`](deferred-work.md#L1216)
