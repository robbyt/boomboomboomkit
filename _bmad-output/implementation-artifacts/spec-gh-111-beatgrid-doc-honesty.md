---
title: 'GH-111 — Beat-grid accuracy documentation matches measurement (PRD FR-29/FR-34 + MODEL_CARD drift)'
type: 'chore'
created: '2026-07-25'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'e3d22ac'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Epic 8 closed accept-as-shipped on 2026-07-01 with beat-grid accuracy far below its committed gates — beat-position F **0.37** vs a 0.75 target, downbeat correctness **0.14** @ 4.3% fire vs 0.65, and FR-29 P95 last-beat drift **1,652 ms** vs a 30 ms AC. Three documents still read as though that did not happen. PRD FR-29 asserts in prose that "beat timestamps remain audibly accurate at the end of long files"; PRD FR-34 commits accuracy thresholds "before Epic C is considered complete" with no record that the epic closed below them; and the PRD risk register lists "Long-file sync drift" as *mitigated by* FR-29, when that risk materialized. Worst of the three: `MODEL_CARD.md` — the only one of them that ships to `main` — discloses the F-measure and the conservative downbeat detector but is **silent on drift**, so a consumer reading the shipping accuracy disclosure sees no hint of the 1,652 ms number. The 2manyDJs auto-sync consumer plans from these documents.

**Approach:** Amend the four falsified or incomplete claims in place, using each document's own existing amendment convention, and cite the measured numbers rather than softening them. No code, no tests, no behavior change.

## Corrections to the issue's own premises

Verified before drafting; two of #111's three claims do not hold as written:

1. **#111 says epics.md Story 8.7 "keeps `mean F-measure >= 0.75` as normative AC text with the miss explained only in a blockquote 60 lines later."** Stale. `epics.md:1138` already carries a reconciliation banner as the **first** content under the Story 8.7 heading, above the ACs — landed 2026-07-21 under issue **#113, which is CLOSED**. No banner is needed; only its trailing pointer ("PRD FR-29/FR-34 amendment is tracked as issue #111") needs updating once this lands.
2. **#111 says the PRD "still asserts the original outcome unconditionally."** Imprecise. Neither FR ever carried 0.75 or 30 ms — FR-34 defers thresholds entirely, FR-29 defers the number and makes a prose claim. The defect is real but different: FR-29's *prose* is falsified, and neither FR records the accept-as-shipped outcome.
3. **#111 says "`MODEL_CARD.md` discloses this honestly."** Only partly — it covers F-measure and downbeats, not drift. This is the one gap in a document that reaches consumers, and it is in scope here even though the issue title names only the PRD.

## Boundaries & Constraints

**Always:**
- Cite the measured numbers with their corpus and conditions (Rekordbox JAMS oracle, 1264 tracks / 910 constant-tempo, ±70 ms, octave-normalized). A bare "0.37" without conditions is not a disclosure.
- Preserve original wording beneath each amendment — the audit trail of what was believed when is load-bearing (project-context.md supersession-header rule).
- Use each file's established convention: the PRD's inline `*(Amended <date>, <reason>: …)*` italic parenthetical (precedents at `prd.md:20` and `:161`); epics.md's `> **Reconciled …**` blockquote.
- `MODEL_CARD.md` is consumer-facing prose: no em-dashes as the operator has ruled, no subjective softening, no BMAD/story/issue references.

**Ask First:** Weakening or removing any FR rather than amending it. Editing `MODEL_CARD.md` beyond the beat-grid acceptance section.

**Never:** Changing any committed regression floor. Touching `Sources/`, `Tests/`, or any benchmark. Re-adding a Story 8.7 banner that already exists. Repairing `MODEL_CARD.md`'s stale "bundled `giantsteps_v1.mlmodelc`" claim — false since Story 4-6 Branch C, but already ledgered in `deferred-work.md` with a "v1 release is cut" re-open trigger, and the file does not ship today.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Consumer reads shipping accuracy disclosure | `MODEL_CARD.md` beat-grid section | Sees F ≈ 0.37, downbeat 0.14 @ 4.3%, **and** P95 last-beat drift ≈ 1.65 s with the extrapolation guidance | n/a |
| Planner reads FR-29 | `prd.md:121` | Prose claim carries an amendment naming 1,652 ms measured vs 30 ms committed, and the accept-as-shipped close | n/a |
| Planner reads FR-34 | `prd.md:131` | Hard gate carries an amendment naming F 0.37 vs 0.75 and the committed 0.33 floor | n/a |
| Planner reads the risk register | `prd.md` "Long-file sync drift" | Risk marked **materialized**, not mitigated, with the measurement | n/a |
| Reader follows epics.md 8.7 banner to #111 | `epics.md:1138` | Pointer reads as amended rather than pending | n/a |
| Reader wants the follow-up path | any amended claim | Points at the Epic 12 / Epic 13 charters (`epics.md:1787`, `:1806`) | do not imply either is scheduled |

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md` — `:121` FR-29 (prose claim + deferral), `:131` FR-34 (deferred thresholds + hard gate), `:316` "Long-file sync drift" risk. Amendment convention precedents at `:20` and `:161`.
- `MODEL_CARD.md` — "Beat-grid acceptance (DSP, not an ML model)" section; four bullets + a closing paragraph. Drift is absent.
- `_bmad-output/planning-artifacts/epics.md:1138` — Story 8.7 reconciliation banner (already correct); its last clause names #111 as pending.
- `_bmad-output/implementation-artifacts/epic-8-retro-2026-07-01.md:36` — the authoritative measured table (target / measured / committed floor).
- `_bmad-output/implementation-artifacts/8-7-pressure-release.md:18` — drift median 176 ms, n=450 ≥5 min, and the 2.0 s regression ceiling.
- `_bmad-output/planning-artifacts/epics.md:1787,:1806` — Epic 12 / Epic 13 charters, both CHARTER-ONLY and unscheduled.

## Tasks & Acceptance

**Execution:**
- [x] `MODEL_CARD.md` — added the long-file divergence bullet (median ≈ 0.18 s, P95 ≈ 1.65 s, 2.0 s ceiling), scoped to its real gate population (constant-tempo, ≥ 5 min), stating what the metric does and does not establish. Replaced the unquantified "conservative"/"moderate" wording with measured values, split by denominator (54/1,264 fired; F 0.14 over 42 fired constant-tempo tracks). Added the constant-tempo tracker limitation. Removed the section's only em-dash.
- [x] `prd.md` FR-29 — inline amendment appended; original wording retained.
- [x] `prd.md` FR-34 — inline amendment appended, including the corpus supersession (OA300 `.dawproject` → Rekordbox, Story 8.7 DD-13).
- [x] `prd.md` "Long-file sync drift" risk — marked **Unmitigated and unverified**. The planned "Materialized" wording was withdrawn in review: no shipped measurement is an end-of-file audio comparison, so the stronger claim is unsupported.
- [x] `_bmad-output/planning-artifacts/epics.md` — `:1138` trailing clause repointed and subset-scoped (banner itself untouched); `:91` and `:96` FR summaries marked UNVALIDATED / MISSED, since a summary-only reader never reaches Story 8.7.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` — three entries ledgered: the FR-29 metric mismatch, the deliberately-untouched bundled-model claim, and the two dated documents left alone.

**Acceptance Criteria:**
- Given a consumer reading only `MODEL_CARD.md`, when they reach the beat-grid section, then they learn the long-file drift magnitude without consulting any develop-only artifact.
- Given a reader of PRD FR-29 or FR-34, when they read the FR, then the measured outcome and the accept-as-shipped close are visible in the FR itself, not only in a linked epic.
- Given every number written in this change, when each is grepped against `epic-8-retro-2026-07-01.md` or `8-7-pressure-release.md`, then it matches a measured value in those artifacts — no rounded-for-comfort figures.
- Given the original FR text, when the amendment lands, then the original wording is still present and readable beneath it.
- Given `make test` and `make lint`, when they run, then results are unchanged from `e3d22ac` — this change touches no Swift, Python, or build file.

## Spec Change Log

**2026-07-25 — the drift metric does not mean what the issue assumed, and writing it up naively would have shipped a new falsehood.**
The plan was to disclose "P95 last-beat drift 1,652 ms" as an accuracy miss.
Reading `BeatGridBenchmarkTests.swift:216-222` before writing showed
`drift = abs(rawBeats[lastIndex] - expected)` where `expected` is the library's
own anchor-plus-tempo extrapolation, with the code comment naming the purpose:
"the metric that justifies 'extrapolate, don't trust raw'". So the figure is a
divergence between two views the library emits, NOT error against a reference.
Publishing "the beat grid is 1.65 s wrong" in the consumer-facing card would
have been a fresh false claim introduced by an honesty change. `MODEL_CARD.md`
now states what the number is and is not, and FR-29's amendment records that
its own acceptance gate does not test its prose.
**KEEP on re-derivation:** read the metric's implementation before disclosing a
metric. Two of #111's three premises were also stale on inspection (see
Corrections) — a documentation-honesty issue is not exempt from verification
just because its subject is honesty.

**2026-07-25 (review round) — the first draft replaced one false claim with another, in the public card.**
Two independent adversarial reviews of the diff converged on seven findings; all
seven were verified against source before being accepted. The serious one: the
new `MODEL_CARD.md` bullet said raw `beats` "follows tempo movement in the
recording." `AudioAnalysisService.swift:1676` states the tracker "does not
detect or adapt to tempo changes," and `BeatGrid.swift:89-95` states raw beats
carry per-beat onset quantization plus dropped/doubled beats and are
*deliberately more* divergent after a tempo lock. So the sentence was flatly
false, and it was headed for the one document that ships publicly. It came from
reasoning about what the divergence *implied* rather than reading what the
producer documents. Corrected to state only what the measurement establishes,
including that it does not establish which view is closer to the audio.
Six further corrections: the drift figures were scoped to their real gate
population (constant-tempo AND ≥ 5 min, not all long tracks — `BeatGridBenchmarkTests.swift:445`);
the downbeat sentence was splicing a 54/1,264 fire rate with an F-measure over
42 fired constant-tempo tracks into a bogus "14% of the 4%" success rate;
"materialized" on the risk register was downgraded to "unmitigated and
unverified", because neither measurement is an end-of-file audio comparison;
FR-29 now leads with UNVALIDATED so the retained aspiration cannot read as a
current promise; the Epic 12 pointer was dropped (it is an ML BPM-model
redesign, Epic 13 is the DSP follow-up); and "different corpus" became
"different subset of the same run".
**Note on the frozen block:** its Intent and Corrections sections still say
FR-29's prose is "falsified". That is now known to be an overclaim — the
correct word is "unvalidated". The frozen block is human-owned and was left
as-written; this entry is the correction of record.
**KEEP:** run the adversarial review even on a documentation-only diff. It was
the only thing standing between a public false claim and a merge.

## Design Notes

**Why MODEL_CARD.md leads the task list despite the issue naming the PRD.** The PRD is an internal planning artifact on `develop`; `MODEL_CARD.md` is on the ships-to-main allowlist and is described in its own footer as "the source of truth for bundled-model accuracy. If a story or marketing copy contradicts it, this card wins." A consumer who clones the library and reads the accuracy disclosure currently learns the F-measure is moderate and takes away nothing about drift. Fixing the internal document while leaving the external one incomplete would invert the priority.

**Why amend rather than rewrite the FRs.** These FRs were not wrong when written; they were unmet. Rewriting them to describe the shipped behavior would erase the evidence that the project committed to something it did not reach, which is exactly the record that makes the Epic 12/13 charters legible. The supersession-header pattern already in use across epics.md and the PRD keeps both layers.

## Verification

**Commands (all run 2026-07-25 at `e3d22ac`):**
- `make test` — **941 tests / 161 suites / 4 known issues, passed in 3.488 s.** Identical to baseline, as required for a change touching no Swift.
- `make lint` — **6 violations, 0 serious in 183 files.** Unchanged.
- `git diff --stat` — **4 files, +25 / −8** (post-review). `MODEL_CARD.md`, `prd.md`, `epics.md`, `deferred-work.md`. Zero under `Sources/`, `Tests/`, `scripts/`, `Package.swift`.
- Adversarial review: two independent passes on the diff, then a third confirming pass on the revision. Round 1 produced 7 findings (all verified against source, all accepted, none rejected); round 2 confirmed 6 of the fixes and found one residual internal contradiction, since fixed. No finding was dismissed as noise.
- `git diff MODEL_CARD.md | grep "^+" | grep "—"` — **no matches.** No em-dash entered the consumer-facing card; the section's pre-existing one was removed.

**Number provenance — every figure traced to a measured artifact:**

| Figure | Source |
|---|---|
| F 0.37 / target 0.75 / floor 0.33 | `epic-8-retro-2026-07-01.md:36`; `8-7-pressure-release.md` (0.3718 exact) |
| Downbeat 0.14 @ 4.3% fire / target 0.65 / floor 0.10 | same table; 0.1444 exact, 54/1264 fired, 95.7% abstain |
| P95 drift 1,652 ms, median 176 ms, n=450 ≥ 5 min | `8-7-pressure-release.md:18` |
| 2.0 s regression ceiling | same line, explicitly "NOT the 30 ms aspiration" |
| Corpus 1,264 tracks / 910 constant-tempo / ±70 ms | `epic-8-retro-2026-07-01.md:36` table header |

`MODEL_CARD.md` rounds 176 ms → "about 0.18 s", 1652 ms → "about 1.65 s", and 95.7/4.3/0.1444 → "about 96% / 4% / 14%", each hedged with "about". Exact figures live in the PRD amendments.

**Manual checks:**
- Read the amended `MODEL_CARD.md` section as a consumer: it now states the divergence magnitude, what the number is and is not, and which of the two grid views to use for sync, without a second document.
- `epics.md:1138` banner not duplicated — diff shows one changed line, the trailing clause only.
- Original FR wording present and readable beneath both amendments (verified in diff).

## Suggested Review Order

**The consumer-facing claim (start here)**

- Entry point. The one edit that reaches people outside this repo: the drift figure the card never carried.
  [`MODEL_CARD.md:166`](../../MODEL_CARD.md#L166)

- The sentence the review saved. States what the measurement does NOT establish, after a first draft claimed raw beats track real tempo.
  [`MODEL_CARD.md:166`](../../MODEL_CARD.md#L166)

- Downbeat figures split by denominator; "conservative"/"moderate" replaced with measured values.
  [`MODEL_CARD.md:165`](../../MODEL_CARD.md#L165)

- Recommendation now justified by the API contract, not by the measurement. Fixed in review round 2.
  [`MODEL_CARD.md:168`](../../MODEL_CARD.md#L168)

**The falsified promise**

- Leads with UNVALIDATED so the retained aspiration cannot read as a live guarantee.
  [`prd.md:121`](../../_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md#L121)

- Risk downgraded from "materialized" to "unmitigated and unverified" — the stronger claim is unsupported.
  [`prd.md:316`](../../_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md#L316)

**The missed gate**

- Records that committed thresholds were missed, and that the corpus itself was superseded mid-execution.
  [`prd.md:131`](../../_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-05-25/prd.md#L131)

**Summary-reader paths**

- The two one-line FR summaries a skimmer hits before ever reaching Story 8.7.
  [`epics.md:91`](../../_bmad-output/planning-artifacts/epics.md#L91)

- Existing #113 banner kept; only its trailing pointer and subset scoping changed.
  [`epics.md:1138`](../../_bmad-output/planning-artifacts/epics.md#L1138)

**Ledger**

- Three entries, including the finding that FR-29's gate does not test FR-29's prose.
  [`deferred-work.md:1164`](../../_bmad-output/implementation-artifacts/deferred-work.md#L1164)
