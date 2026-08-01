---
title: 'Q9: characterize the 1.5x cluster and record its effect on the F3 corpus draw'
type: 'chore'
created: '2026-08-01'
status: 'done'
baseline_commit: '04642db'
review_loop_iteration: 1
context:
  - '{project-root}/_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md'
  - '{project-root}/_bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Epic 12's PRD defers Q9 — the 222-track ~1.5x cluster in the non-Rekordbox pool is unexamined, and the PRD records the exposure that these tracks "sit in the pool, not the corpus, so they shape which tracks are drawn and could bias selection before verification ever sees them." FR-59b's convention choice is supposed to be made without knowing what they are.

**Approach:** Characterize the cluster from the existing survey JSON — no decoding, no listening, no re-run — establish which side of the tag/DSP pair is wrong, quantify what that does to each band's draw pool, and write the finding into a develop-only analysis artifact plus the PRD's Q9 entry.

## Boundaries & Constraints

**Always:** Derive every number from `non-rekordbox-survey.json` and state the classification rule used, so a second person reproduces the same counts. Treat the file tag and our DSP as two fallible signals — neither is ground truth. Keep the analysis decode-free.

**Ask First:** Any change to FR-59's per-band target of 43, to the 258-track corpus size, or to FR-59b's convention. This spec reports what the cluster does to those numbers; it does not get to reset them.

**Never:** Do not declare the metrical convention — that is FR-59b's job and its owner's call. Do not re-run `make non-rekordbox-survey`. Do not touch `Sources/` or `Tests/`. Do not promote any DSP-derived value to ground truth (FR-59a.1). Nothing here ships to `main`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Ratio binning | tag and DSP both present and > 0 | track assigned to exactly one ratio class | tracks failing the guard are counted as excluded, not silently dropped |
| Missing tag | `fileMetadataBPM` absent or <= 0 | excluded from all ratio statistics | reported as a separate count |
| Missing DSP | `dspBPM` absent or <= 0 | excluded from all ratio statistics | reported as a separate count |
| Band assignment | BPM on a band boundary (100, 120, 140, 160, 175) | half-open `[lo, hi)`, so 120.0 lands in 120-140 | stated explicitly in the artifact |
| Window sensitivity | ratio near a class edge | class counts reported at more than one window width | a finding that flips with window width is reported as unstable, not as a result |

</frozen-after-approval>

## Code Map

- `_bmad-output/ml-training/non-rekordbox-survey.json` -- the only data source. 4,766 analyzable tracks; 2,568 carry both a tag and a DSP estimate. `dsp_metadata_blind: true`, so the two signals are independent.
- `_bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md` -- the 2026-07-29 write-up this extends. Its finding 5 names the 222 as unexamined; its finding 4 ("100-120 scarcity is not an artifact of convention") is the claim most at risk from this analysis.
- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- Q9 at `:442-446`, the gate row at `:19`, FR-55 at `:130`, finding 3 at `:243`, FR-59/59a/59b/59f in F3.
- `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift:126` -- the `robbyt_x-ray-120s` fixture, labelled `triplet-related`, ratio 1.5047. A live instance the PRD says costs nothing to check.

## Tasks & Acceptance

**Execution:**
- [x] `scratchpad analysis script` -- bin all 2,568 paired tracks by `log2(dsp/tag)` and report the histogram, class counts at several window widths, and per-class tag/DSP percentiles, confidence, tier, and directory concentration -- establishes whether 1.5x is a real peak or a slice of a continuum, and which signal is wrong.
- [x] `scratchpad analysis script` -- decompose each tag band by ratio class, and report what each band's draw pool becomes once a class is removed -- quantifies the PRD's stated selection-bias exposure in band counts rather than in the abstract.
- [x] `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift` -- read only; confirm the `robbyt_x-ray-120s` ratio and its `triplet-related` label, and state whether it belongs to the same phenomenon as the pool cluster -- the PRD names it as a live instance, so the artifact must either connect it or say plainly that it does not.
- [x] `_bmad-output/ml-training/q9-ratio-cluster-2026-08-01.md` -- new develop-only artifact: the finding, the reproduction recipe, and the consequences for FR-59, FR-59b and FR-59f -- the deliverable.
- [x] `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- resolve the Q9 entry, update the §14 gate row, and correct any statement the finding contradicts -- leaving Q9 deferred after answering it would strand the dependents, which is this document's documented defect mode.
- [x] `_bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md` -- amend finding 4 and finding 5 in place with a dated marker rather than a rewrite -- the earlier artifact must not keep asserting something this one refutes.
- [x] `.memlog.md` (PRD workspace) -- append one `decision` entry via `uv run _bmad/scripts/memlog.py` -- the memlog is the audit trail and a Q9 resolution belongs in it.

**Acceptance Criteria:**
- Given the survey JSON, when the ratio histogram is computed, then the artifact states whether the 1.5x cluster is a distinct peak or a continuum slice, with the density comparison that settles it.
- Given the cluster is characterized, when the artifact names a cause, then it states the best-supported hypothesis for which signal is erroneous, labels it as a hypothesis rather than a label, names the falsification test, and does not cite any quantity derived from our own detector as if it were corroboration. Amended 2026-08-01 — see Spec Change Log.
- Given any evidence line is offered, when it draws on `tier` or `agreementAfterOctaveNormalization`, then it is excluded: both are deterministic functions of the tag/DSP relation under test and are circular by construction.
- Given a density or peak comparison is made, when a reference window is called a shoulder, then it is verified to contain no other identified peak, and a constant-width histogram is shown rather than hand-picked windows.
- Given the per-band decomposition, when a band's draw pool is reported, then both the raw tagged count and the count surviving removal of each implicated class are shown, alongside FR-59's target of 43.
- Given the finding contradicts an existing claim in the 2026-07-29 feasibility artifact or the PRD, then that claim is struck or corrected in place with a date, and no document is left asserting both.
- Given a reader with only the repository, when they follow the artifact's reproduction section, then they obtain the same counts.

## Spec Change Log

### 2026-08-01, iteration 1 — bad_spec

**Triggering findings (Codex adversarial pass, all independently verified against the JSON):**
1. The original AC asked the artifact to "identify which of tag or DSP is the erroneous signal". Under the frozen block's own rule against promoting a DSP-derived value to ground truth, two scalar BPM estimates cannot license that verdict. The AC demanded something the constraints forbid, and the first draft duly overreached: it closed Q9 by asserting "the detector is right" while conceding in the same document that human verification was needed to close the counter-hypothesis.
2. `tier` and `agreementAfterOctaveNormalization` were cited as supporting evidence. Verified: `tier` is a **perfect** function of the agreement flag (2,172 `secondarySupervised` to True, 396 `unsupervisedPool` to False), so both are deterministic restatements of the tag/DSP relation under test.
3. The density comparison called `[1.30, 1.45)` a shoulder. Verified: 86 of its 91 tracks are the 1.33x peak itself. The true gap `[1.36, 1.45)` holds 5 tracks at 54/oct, not the 578/oct printed.
4. "Constant-width log-ratio bins" was claimed but hand-picked unequal windows were shown. Calling 202 "the honest figure" was post-hoc; the count runs 240 to 176 across plausible windows.
5. "Four numbers converge on ~115" counted three algebraically-induced values as independent observations.
6. `robbyt_x-ray-120s` was called a member of the 1.33x class. Its metadata is stripped, so it has no file tag and therefore no ratio.

**Amended:** the three acceptance criteria covering causal claims, circular evidence, and density presentation. Nothing inside `<frozen-after-approval>` changed.

**Known-bad state avoided:** a PRD that closes its last open question on a conclusion its own FR-59a.1 independence rule forbids, and then reorders and re-budgets human verification on the strength of it.

**KEEP — must survive re-derivation:**
- All descriptive counts. Codex confirmed these reproduce: 2,568 paired, 202 in `[1.48, 1.52)`, 86 in `[1.30, 1.36)`, 197 of 262 in the 100-120 x 1.5x cell.
- The band decomposition table and the 27-corroborated-against-43-target finding. Most consequential result in the analysis, and it is arithmetic rather than inference.
- The three-way tag split at fixed detector tempo (79.8% / 10.8% / 8.9%). Strongest non-circular structural observation available.
- The 84.2% base-rate confound disclosure and the 145 tracks showing the detector is not pinned to ~172.
- The correction that `robbyt_x-ray-120s` is not an instance of the 1.5x phenomenon.

## Design Notes

Two traps this analysis has to avoid, both of which have already produced wrong numbers in this evidence base:

1. **Selecting on our own detector.** The 2026-07-29 feasibility numbers used `agreementAfterOctaveNormalization` as a filter, which FR-59a.1 forbids, and the band counts moved substantially when it was removed. Report from the tag banding and state the filter, or report unfiltered.
2. **Reading a ratio as a phenomenon.** `dsp/tag = 1.5` is a relation between two numbers. It is only a triplet if the audio has a triplet feel. The same ratio arises when either signal sits at a different metrical layer, and the direction has to be established from evidence outside the ratio itself — absolute BPM, detector confidence, and what sibling tracks in the same directory look like.

Window widths in the earlier ratio table were unequal (~5.5%, ~6%, ~5%, ~3.3%), so class counts were not density-comparable. Use log-ratio bins of constant width.

## Verification

**Commands:**
- `uv run --no-project python <script>` -- expected: paired-track count reconciles to 2,568, and class counts sum with the excluded counts to 4,766.
- `grep -n "Q9" _bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- expected: no site still describes Q9 as deferred or unexamined.
- `grep -rn "unexamined" _bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md` -- expected: any surviving hit sits beside a dated superseded marker.
- `git status --short` -- expected: only the new artifact plus the three amended documents; no `Sources/` or `Tests/` change.

**Manual checks:**
- Every numeric claim in the new artifact traces to a printed value from the analysis script, not to a value carried over from the 2026-07-29 document.

## Suggested Review Order

**Start here — what the analysis is allowed to claim**

- Read this before any number; it bounds everything below.
  [`q9-ratio-cluster:16`](../ml-training/q9-ratio-cluster-2026-08-01.md#L16)

**The measurements (hold regardless of the causal reading)**

- Band decomposition, and the 27-against-43 finding that drives the corpus consequence.
  [`q9-ratio-cluster:101`](../ml-training/q9-ratio-cluster-2026-08-01.md#L101)

- Three tag modes over one detector-homogeneous population; the hypothesis rests here.
  [`q9-ratio-cluster:68`](../ml-training/q9-ratio-cluster-2026-08-01.md#L68)

**The hypothesis, and everything against it**

- Falsification test plus the 84.2% base-rate confound that weakens the argument.
  [`q9-ratio-cluster:139`](../ml-training/q9-ratio-cluster-2026-08-01.md#L139)

**Where the PRD absorbed it**

- The FR-59a.1 boundary: budgeting allowed, exclusion forbidden, ordering conditional on four rules.
  [`prd:206`](../planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md#L206)

- Q9 downgraded from resolved to answered-not-closed, with the withdrawal recorded.
  [`prd:461`](../planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md#L461)

- `N_BAND`/`N_EVAL` reframed as planning constants FR-59f can lower.
  [`prd:165`](../planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md#L165)

**Peripherals**

- The superseded claims, struck in place rather than rewritten.
  [`non-rekordbox-band-feasibility:150`](../ml-training/non-rekordbox-band-feasibility-2026-07-29.md#L150)

- Why the first draft was wrong and what must survive re-derivation.
  [`spec-q9-triplet-cluster:76`](spec-q9-triplet-cluster.md#L76)
