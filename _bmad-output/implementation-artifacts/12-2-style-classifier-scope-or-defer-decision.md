---
title: 'Story 12.2: Style-classifier decision — scope it, defer it, or reject it'
type: 'chore'
created: '2026-08-05'
status: 'review'
baseline_revision: '13135f8' # branch rterhaar/12-2, clean tree
final_revision: 'uncommitted' # commit is operator-owned, gated on the 1Password SSH signer
review_loop_iteration: 0
followup_review_recommended: true # two review passes: 21 patches (4 high) same-session, then 7 more (1 critical, 3 high) from an external Codex diff review plus a Gemini tie-break
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
warnings: ['oversized'] # 1485 words / ~1980 tokens; the evidence ledger is the deliverable's substance
---

<intent-contract>

## Intent

**Problem:** FR-54 (style-conditioned tempo prior) depends on a style classifier that FR-54a states plainly is "an unscoped second model, and this PRD does not build it" — no training corpus, no taxonomy, no accuracy gate, no size budget. Epic 12 owes a written decision, and until it lands FR-54 shadows F1 with a dependency nothing produces.

**Approach:** Record the decision as a first-class, citable artifact, then propagate it to every document that currently asserts the unresolved state. The decision is **reject the classifier**, taking the second exit FR-54a itself offers — "revisit Q5 in favour of the caller-declared option, which needs no model" — because Story 12.1 has already shipped that option. Documentation only.

## Boundaries & Constraints

**Always:**
- `Sources/` and `Tests/` are byte-identical at close. This story writes documents.
- Annotate, never delete. Retracted text stays under `~~strikethrough~~` with a bold dated clause naming what changed and why (`epics.md:175`, `:288`, `:2038`, `:2349` precedents).
- Every claim in the decision document carries a `file:line` citation to primary text. No claim sourced from a summary.
- The FR coverage count stays **26**, at **all four** count sites: `epics.md:6`, `:11`, `:391`, `:534`. FR-54 and FR-54a remain *covered by* Epic 12 — this decision is their coverage. Coverage is not implementation. State this explicitly at each count site so a later reader does not "correct" it. (An earlier draft of this spec said three sites and omitted `:11`, the `epicsDesigned` frontmatter key.)
- Reversing §14 Q5 is reversing a recorded operator decision (PRD §14 Q5, `prd.md:475` as of 2026-08-05, decided 2026-07-28). Label it as such, in those words, wherever it is annotated.
- **Q5's axis is not FR-53's axis.** Q5 asks where a style *label* comes from and offers user-declared, metadata-derived, or classified. FR-53 ships caller-declared *BPM bounds*, which bypass the style concept. FR-53 is a valid alternative octave mechanism under the reject branch; it is **not** evidence that Q5's caller-declared option already shipped, and the decision must not say it is.

**Block If:**
- Any of the four artifacts FR-54a names as absent (training corpus, style taxonomy, classifier accuracy gate, size/latency budget) is found to already exist and be specified. The reject basis collapses; HALT rather than argue around it.
- Any story 12.3–12.9 is found to depend on FR-54 or on a classifier. AC #3's "no remaining Epic 12 story depends on it" would then be false and the decision cannot land as written.

**Never:**
- No follow-on story is created and no FR count is amended — those belong to the *scope it* branch, which is not selected.
- Do not claim Story 12.1's measurement refutes Hörschläger et al. SMC 2015. ~~It tested a hard-filtered window, not a soft reweighting prior.~~ **CORRECTED 2026-08-05:** that reason is unsound. PRD §4.3 (`prd.md:101` as of 2026-08-05, cited as `:97` before this story's own PRD insertion shifted it) states the published prior as a *range* ("DnB prior 130-180 BPM"), so a hard-vs-soft mechanism distinction cannot be built on it. The sound reason is that 12.1 tested **neither axis of the published configuration**: it moved `Options.perceptualWindow` (the octave *fold*) rather than `Options.tempoScanRange` (the candidate *search*), and it moved it to `100...200` rather than `130-180`. The constraint stands; only its justification changed. Overclaiming here is the failure mode this epic exists to stop.
- No new public API, no `Options` field, no `MLTechnique` change.

</intent-contract>

## Code Map

- `_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md` -- **line numbers as of 2026-08-05, AFTER this story's own four-line insertion into §1; the named section governs if they drift again.** §5.1 FR-54 `:131`, §5.1 FR-54a `:132`, §5.1 F1 claim `:128`, §4.3 SMC evidence `:101`, §15 AS-7 `:489`, §6 gates `:339-349`, §8.1 MVP `:365`, §14 Q5 `:475`. (An earlier draft cited the pre-insertion numbers `:127`, `:128`, `:124`, `:97`, `:485`, `:335-345`, `:361`, `:471`, every one of them stale by 4.)
- `_bmad-output/planning-artifacts/epics.md` -- FR-54 `:153`, FR-54a `:154`, coverage rows `:396-397`, count sites `:6`, `:391`, `:534`, F1-splits note `:538`, Story 12.2 `:2050`
- `_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json` -- the measured genre-conditioning proxy
- `_bmad-output/implementation-artifacts/deferred-work.md` -- append at bottom, current `source_spec:` format
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- key `12-2-style-classifier-scope-or-defer-decision` at `:347`; 117 `development_status` entries must survive

## Tasks & Acceptance

**Execution:**
- [x] `_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md` -- NEW. The decision artifact. Sections: Decision / Question as posed / Evidence ledger (cited) / What replaces it / Coexistence ruling / What this decision does NOT claim / Reversal path / Consequences per document. This is the deliverable everything else cites.
- [x] `_bmad-output/planning-artifacts/epics.md` -- annotate FR-54 and FR-54a with the decision and date; update coverage rows `:396-397`; annotate the F1-splits note `:538`; append the outcome to the Story 12.2 section. Assert the 26 count is unchanged at `:391` and `:534` with the coverage-is-not-implementation reason.
- [x] `.../prd-BoomBoomBoomKit-2026-07-26/prd.md` -- annotate FR-54 `:127`, FR-54a `:128`, the F1 claim `:124`, §8.1 MVP `:361`, and §14 Q5 `:471` (Q5 reversed; label as reversing an operator decision). Beyond the letter of AC #3, which mandates only `epics.md` -- leaving the PRD asserting the unresolved state recreates the charter-vs-PRD divergence GH-166 had to clean up.
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` -- append one entry under a new `## Deferred from: Story 12.2 (2026-08-05)` heading: the residual soft-reweighting question over a *caller-declared* style needs no classifier and is untested. Re-open trigger required.
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- `12-2-...: backlog` -> `review`. Verify 117 entries survive.

**Acceptance Criteria:**
- Given the decision document, when read, then it selects exactly one of scope / defer / reject, and because the selection is *reject*, it names the alternative octave mechanism that replaces it.
- Given FR-54 mandates *reweight, never hard-filter* while Story 12.1 shipped a range that is a hard filter by construction, when the decision is read, then it states explicitly whether the two coexist or one supersedes the other, and why.
- Given the decision is *reject*, when `epics.md` is read, then FR-54 carries the decision and the date `2026-08-05`, and no remaining Epic 12 story depends on it.
- Given the coverage table and the ~~three~~ **four** count sites (`epics.md:6`, `:11`, `:391`, `:534` -- **CORRECTED 2026-08-05 (external review):** the earlier "three" omitted `:11`, the `epicsDesigned` frontmatter key, which also carries the count), when checked after the edits, then all four still read **26 FRs**, each with the reason stated inline.
- Given this story is a decision and not a build, when it closes, then `git diff --stat 13135f8 -- Sources/ Tests/` is empty.
- Given the reject basis rests on four absent artifacts, when the decision document is read, then each absence carries a citation to text asserting it, not an inference from silence.

## Spec Change Log

## Review Triage Log

### 2026-08-05 — Review pass

Two adversarial reviewers (Blind Hunter, Edge Case Hunter) ran in parallel against the
full diff from `13135f8`, untracked files included. Every finding was verified against
the live repository before triage; reviewer-assigned severity was discarded and
re-assigned by consequence for the artifact's consumer, a future reader auditing why
the classifier was rejected.

- intent_gap: 0
- bad_spec: 0
- patch: 21 (high 4, medium 10, low 7)
- defer: 2 (medium 2)
- reject: 4

**The decision itself survived unchanged.** Every verified finding was about the
quality of the supporting argument or the completeness of propagation. The four
structural grounds for rejecting the classifier (FR-54a's own exit clause, the
asserted absence of the four artifacts, the singular frozen `MLTechnique` seam, and
the measured zero downstream dependency) were untouched by review.

**Two of the four high findings trace to this spec, not to the implementation.** The
`Never` block instructed the mechanism-distinction argument, and Design Note 4
instructed the small-model argument. Both are now corrected in place above rather than
left asserting a refuted rationale. They were routed as patches rather than a
`bad_spec` loopback because both defects are additive: the fix is to supply an omitted
counter-consideration and restate the conclusion, and nothing already written needed
unwinding. Re-deriving would have discarded roughly 500 lines of verified annotation
across five files to change about 60.

- addressed_findings:
  - `[high]` `[patch]` Decision artifact 6.1 quoted PRD §4.3 (cited then as `prd.md:97`, now `:101`) for its headline figures while dropping that same line's "DnB prior 130-180 BPM" clause, then built its central escape hatch on a hard-window-versus-soft-prior distinction the cited source does not support. Rewritten to the sound argument: Story 12.1 tested neither axis of the published configuration, moving `perceptualWindow` (the octave fold) rather than `tempoScanRange` (the search), and moving it to `100...200` rather than `130-180`. The artifact now states that a range-shaped published prior makes FR-53 a closer analogue than it had implied, which cuts against its own earlier framing.
  - `[high]` `[patch]` Evidence line 3.4 argued a second model competes with the PRD's small-model intent (PRD §1, cited then as `prd.md:44`, now `:46`), a ground the operator withdrew on 2026-07-21 (`epics.md:2379`, "CPU-only inference is no longer a requirement. Larger models are acceptable if accuracy improves"). The size sub-argument is dropped; 3.4 now rests on the singular slot and the absence of any `MLEvaluation` field for a style label.
  - `[high]` `[patch]` `prd.md` risk row "Style prior overfits to DnB" named FR-54's reweight-never-hard-filter as its control. FR-54 is rejected and its replacement is a hard filter, so the mitigation was inverted rather than merely stale. Annotated.
  - `[high]` `[patch]` AS-7 was left unannotated while the decision claimed it weakened. Annotated WEAKENED, not refuted and not settled, following the AS-5 and AS-6 convention on the adjacent rows.
  - `[medium]` `[patch]` Reversal path opened "edit these five places. Nothing else depends on it" while the consequences table listed thirteen. Scoped into load-bearing and secondary items; the false universal claim is withdrawn.
  - `[medium]` `[patch]` Two of four `26` count sites were unannotated and one, `epics.md:11`, had never been identified. Both annotated.
  - `[medium]` `[patch]` `prd.md` executive summary still named style priors the epic's strongest lever, and the non-DnB per-genre success metric still guarded a style prior. Both annotated.
  - `[medium]` `[patch]` `epics.md:12` still narrated the classifier decision as outstanding. Annotated.
  - `[medium]` `[patch]` `epic-12-context.md` shipped stale on arrival, asserting the decision was pending in the same commit that resolved it. Fixed.
  - `[medium]` `[patch]` Story 12.1's deferred-work entry carried a re-open trigger naming this decision. It had fired and was unannotated. Annotated in place, and the new 12.2 entry now references it instead of duplicating its Gate 1 trigger.
  - `[medium]` `[patch]` The Verification block's sprint-status command returned 163 rather than the stated 117: `-A 200` overran the block and the prefix regex matched grep's context markers. Replaced with a block-scoped `awk`. `make test` removed, since the byte-identity check already proves the tree untouched and a hardcoded test count only adds a failure mode.
  - `[medium]` `[patch]` The ledger claimed six independent lines; items 1 and 2 share `prd.md:128`. Corrected, and the ledger now distinguishes its three structural grounds from its three contingent ones, since a reviewer correctly observed the contingent ones are defer-shaped.
  - `[medium]` `[patch]` The named replacement mechanism ships in Story 12.1, which is at `review` rather than `done`. A 12.1 review change to either type is now recorded as a re-open condition.
  - `[low]` `[patch]` Six citation and scope corrections: the `epics.md:2079-2348` range shifted to `:2081-2350` by this story's own insertion; "three occurrences" of genre in `Sources/BoomBoomBoomKit/` is nine for the directory and three for Swift source; the two tempo types were cited at their `.default` constants rather than their declarations; the spec and the artifact disagreed on the `octave-bias-finding-and-plan.md` line range; PRD §5.3's *Which corpora* review flag (cited then as `prd.md:283`, now `:287`) was cited as settling a contradiction it flags as open; and the consequences table omitted the two files this story created.

**Rejected findings**, recorded because three of them are plausible on their face:
- "128 `development_status` entries." Measured 117 by two independent methods. The reviewer's own count was wrong.
- "Annotate `implementation-readiness-report-2026-08-02.md`, which still calls FR-54a a blocker." That report is a dated point-in-time snapshot, in the same class as the superseded charter. It was accurate on 2026-08-02 and annotating it would be revisionist.
- "Frontmatter asserts review outcomes before review ran." `status`, `review_loop_iteration` and `followup_review_recommended` are workflow-managed fields written by the workflow at defined points, not authored claims.
- "Reject and defer are not mutually exclusive, since this files a re-open trigger." The classifier is rejected outright; the residual soft-prior question is a different question that needs no classifier. Sections 6.2 and 6.3 already say exactly this.

### 2026-08-05: external review pass (Codex diff review, Gemini tie-break)

A second review ran against the same diff, this time **outside the session**: a Codex
diff review over `13135f8..worktree`, plus a Gemini tie-break on the one finding the
first two lenses and Codex disagreed about (whether the evidence ledger entails
*reject* or only *defer*). Both external reviewers reached the same conclusion on that
point independently, which is why the decision artifact now carries a labelled premise
instead of implying an entailment.

- patch: 7 (critical 1, high 3, medium 3)
- defer: 0
- reject: 0
- new deferred-work entries filed: 3

**The decision is unchanged. It is still reject.** What changed is what the decision
claims about itself, and the accuracy of the citations under it.

- addressed_findings:
  - `[critical]` `[patch]` **Every PRD line citation in the decision artifact was stale by 4.** This story's own annotation inserted four lines at `prd.md` hunk `@@ -41,8 +41,12 @@`, shifting everything below line 43. The artifact, this spec, `epics.md` and `deferred-work.md` all cited pre-edit numbers: SMC 2015 at `:97` is `:101`; §14 Q5 at `:471` is `:475`; AS-7 at `:485` is `:489`; and eleven more. Every citation was re-opened and confirmed by content, not adjusted by arithmetic. **Made non-recurring:** every PRD citation now leads with a stable identifier (section, FR, question, or assumptions row) and carries the line number as a dated secondary hint, and the artifact's header states that the named section governs when the two disagree. The artifact's opening claim that all citations "were opened and read on 2026-08-05" was itself false and is restated.
  - `[high]` `[patch]` **The decision conflated two mechanisms.** PRD §14 Q5 asks how a style prior gets *its style* and offers user-declared, metadata-derived, or classified, so FR-54a's second exit means a caller-declared **style**. Story 12.1 shipped caller-declared **BPM bounds**, which bypass the style concept. Two claims built on the conflation are withdrawn: that Story 12.1 "already walked through" the exit, and that selecting it "costs no new work". FR-53 remains a valid alternative octave mechanism under the reject branch, which is all AC #1 requires.
  - `[high]` `[patch]` **"There is no style left to condition on" is false.** Q5 itself names two non-classifier style sources, and this repository already reads file-tag metadata via `FileMetadataReader`. The supersession ruling is re-grounded on a scope statement (Epic 12 builds no style-conditioned prior of any kind) rather than a logical impossibility. Corrected in the artifact, `epics.md` FR-54 and the Story 12.2 OUTCOME, and the PRD FR-54 annotation.
  - `[high]` `[patch]` **"FR-54's abstain requirement is satisfied vacuously" is an overclaim.** A rejected requirement is inapplicable, not satisfied; the wording read as though FR-54 had been delivered in attenuated form. Corrected at all three sites it had propagated to.
  - `[high]` `[patch]` **The product-policy premise was missing.** Both external reviewers found the evidence ledger supports "not now" at least as readily as "never". The artifact now carries §1.1, which states the normative ground plainly (automatic style inference is outside this library's mission; callers own their own domain constraints), labels it a judgment rather than a finding, says the ledger alone would not produce the reject, and makes overturning the premise the primary re-open trigger. The practical argument is strengthened in the same place: a caller who knows their material can set `Options.tempoScanRange` to the published `130...180` today.
  - `[high]` `[patch]` **Internal contradiction about the impact report, and the AS-7 verdict built on it.** The artifact called Story 12.1's report "the first direct test" of SMC 2015 while conceding four paragraphs later that it moved the wrong knob to the wrong values. It is not a direct test: it inferred no style, accepted no declared style, conditioned nothing by style, moved `perceptualWindow` rather than `tempoScanRange`, and used `100...200` rather than `130...180`. Restated as evidence about globally narrowing the octave-fold window. **Consequence:** the `AS-7` PRD annotation, which read WEAKENED on the strength of that claim, is re-annotated **UNTESTED** (annotation kept, not reverted). Propagated to the PRD executive summary and the `epics.md` OUTCOME.
  - `[medium]` `[patch]` **"The three count sites" is four.** `epics.md:6`, `:11`, `:391`, `:534`. AC #4 in this spec, the artifact's section 1, its reversal checklist item 4, and its consequences table all corrected.
  - `[medium]` `[patch]` `12-1-consumer-specifiable-tempo-search-range.md:18` still said in live tense that "Story 12.2 decides whether it is scoped, deferred, or rejected". Annotated as resolved, pointing at the decision artifact, with the Q5-vs-FR-53 distinction noted so the annotation does not recreate the conflation.
  - `[medium]` `[patch]` **Do not assert SMC 2015's mechanism.** The repository's only source is the secondary summary phrase "DnB prior 130-180 BPM", which establishes that the prior is a *range* and nothing about whether it constrained the search or reweighted candidates. The artifact's "SMC 2015 constrains where tempo is searched for" is replaced by an explicit unverified marker, and the whole hard-versus-soft argument is flagged as turning on it.

**Three new deferred-work entries**, under `## Deferred from: Story 12.2 external review
(2026-08-05)`: the cross-document PRD line drift this story caused, the unverified SMC
2015 mechanism, and Gemini's counter-argument to the reject recorded as the live risk
against it.

**Nothing was deleted.** Every retraction is `~~strikethrough~~` plus a dated bold
clause, and no existing deferred-work entry or open item was removed or weakened.

### 2026-08-06: external review pass (Q5 annotation)

One finding, patched.

- addressed_findings:
  - `[high]` `[patch]` **The PRD §14 Q5 annotation still carried the withdrawn basis.** The
    2026-08-05 pass struck "the caller-declared option now exists in shipped code" from the
    decision artifact's §7 (`12-2-style-classifier-decision.md:513-515`) as the same
    conflation of caller-declared *style* with caller-declared *bounds*, and corrected the
    PRD's FR-54 annotation (§5.1) accordingly. It did **not** correct the §14 Q5 annotation,
    which reproduced the withdrawn clause verbatim as its "Basis for the reversal" — so the
    PRD asserted at §14 exactly what it withdrew at §5.1. The basis is restated to match the
    decision artifact's §7: FR-54a names the exit, and the §1.1 product-policy premise is
    what converts an available exit into a taken one. FR-53's bounds pairs are named as the
    alternative octave mechanism Epic 12 ships instead of FR-54, explicitly not as Q5's
    option. Everything else in the annotation is untouched: both strikethrough spans, the
    retained original resolution, the REVERSED label, the operator-decision clause, and the
    section-8 pointer.

**Nothing else changed.** No evidence, no decision, no acceptance criterion. The decision is
still reject; only the warrant recorded at §14 Q5 was wrong, and it now matches the warrant
recorded everywhere else.

## Design Notes

**Why reject rather than defer.** ~~Six lines say the classifier's time never comes on this project's terms.~~ **CORRECTED 2026-08-05 (external review): the six lines do not say that, and the decision artifact now says so plainly.** The ledger below is an inventory of things absent, frozen, or broken *today*, and every one of them could change; read alone it supports "not now" as readily as "never". What converts "not now" into "no" is a **product-policy premise**, stated as a premise and not as a finding: **automatic style inference is outside this library's mission, and callers own their own domain constraints.** Two independent reviews reached the same conclusion about the gap, and §1.1 of the decision artifact now records the premise, labels it a judgment, and makes overturning it the primary re-open trigger. The evidence below is the cost side of that judgment, not its derivation.

~~They are not restatements of each other.~~ **CORRECTED 2026-08-05:** items 1 and 2 share a primary source, both resting on `prd.md:128`, 1 on its exit clause and 2 on its absence clause. And they are not equally durable: **1, 2 and 6 are structural** (a requirement's own text, and a measured absence of downstream dependency), while **3, 4 and 5 are contingent**: a new corpus, a story that unfreezes `MLTechnique`, or a working model would each retire one. The reject rests on the structural three; the contingent three set re-open conditions. The decision artifact carries this distinction in its evidence ledger.

1. **FR-54a names the exit in its own text.** "Either scope the classifier as its own feature with its own gates, or revisit Q5 in favour of the caller-declared option, which needs no model" (PRD §5.1 FR-54a, `prd.md:132` as of 2026-08-05). ~~`PerceptualTempoWindow` and `TempoScanRange` shipped 2026-08-02 as exactly that caller-declared option, so Story 12.1 already walked through the exit.~~ **WITHDRAWN 2026-08-05 (external review): that conflates two mechanisms.** Q5's caller-declared option is a caller-declared **style**, which the library would map to a prior. Story 12.1 shipped caller-declared **BPM bounds**, which bypass the style concept entirely. FR-53 is a valid alternative octave mechanism under the reject branch, which is all AC #1 requires; it is not the Q5 option, and selecting the exit therefore does **not** cost no new work. Only the first sentence survives as evidence, and it survives on the requirement's own text.
2. **The four artifacts are absent by assertion, not by oversight** — `prd.md:128` and `epics.md:154` both say so in as many words.
3. **The taxonomy that exists cannot support it.** 25 genre values live in a develop-only Python fixture converter; zero genre symbols exist in `Sources/`. OA300 is 67/82 drum-and-bass — it cannot train or validate a style classifier. GiantSteps has genre mass but is the evaluation corpus, and training on it is the exact contamination Epic 12 exists to eliminate.
4. **The seam is frozen and singular.** `Options.mlTechnique` is one optional slot; `MLEvaluation` carries `bpm`, `confidence`, `modelIdentifier` and no field a style label fits. `MLTechnique` is frozen at Story 4-5 DD #18 (`CLAUDE.md:183`) — a second model needs a named story to unfreeze it. ~~It also competes with the epic's explicit small-model constraint~~ **DROPPED 2026-08-05:** there is no live small-model constraint. `epics.md:2379` records "**Compute-constraint change (operator, 2026-07-21).** CPU-only inference is **no longer a requirement**. Larger models are acceptable if accuracy improves". The operator relaxed it before this decision was taken. The item rests on singularity plus the freeze, which hold at any model size. (PRD §1, `prd.md:46` as of 2026-08-05, still says "a small model"; that PRD-vs-epics contradiction is flagged, not resolved, by this story.)
5. **The first model failed.** `octave-bias-finding-and-plan.md:8-11`: "The v2 model is NOT ship-quality. Both bundle gates fail and three retrains proved the failure is structural, not a labeling-volume problem." The calibration ladder at `:16-17` records OA300 at 50/82 falling to 43/82 against a `>55/82` gate, and GiantSteps reaching 348/661 against a `>=537` gate, both FAIL. (Cited as `:9-19` in an earlier draft; that range does not resolve to the quoted text. The artifact's `:8-11` / `:16-17` are correct.) Adding a second model before the first works is not a plan.
6. **Nothing waits on it.** No §6 gate references FR-54 (PRD §6, `prd.md:339-349` as of 2026-08-05). Stories 12.3–12.9 contain zero occurrences of FR-54, "classif", "style", "genre", "taxonom", or "prior".

**The honest counterweight, which the document must carry.** Hörschläger et al. SMC 2015 is the strongest published result in the epic — DnB Acc1 7.19% to 78.42% on GiantSteps (PRD §4.3, `prd.md:101` as of 2026-08-05). AS-7 (PRD §15, `prd.md:489`) assumes it transfers to our corpus and pipeline; if it does not, "F1 loses its evidence base." ~~Story 12.1's impact report is the first direct test of AS-7 here~~ **CORRECTED 2026-08-05 (external review): it is not a test of AS-7 at all.** It inferred no style, accepted no declared style, and conditioned nothing by style; one global window ran over all 82 tracks. It came back a wash-to-negative (overall `deltaAcc1 0`, `deltaAcc2 -3`; on drum-and-bass, n=67, `-1`/`-2`), which is **evidence about globally narrowing the octave-fold window** and nothing more. **AS-7 is therefore UNTESTED, not weakened**, and the PRD row is re-annotated to say so rather than reverted to unannotated. **It does not refute SMC 2015 either.** ~~Because 12.1 moved a hard window and FR-54 specifies soft reweighting~~ **CORRECTED 2026-08-05: because 12.1 tested neither axis of the published configuration.** It moved `Options.perceptualWindow` (the octave fold) rather than `Options.tempoScanRange` (the candidate search), which the report's own `metric` field confirms ("only perceptualWindow moved"), and it moved it to `100...200` rather than the published `130-180` (`prd.md:97`). Follow-on consequence the artifact states rather than buries: the published prior being a *range* makes FR-53's caller-declared bounds a **closer** analogue of the published mechanism than the reject rationale first implied. The document says this in these terms, annotates AS-7 **UNTESTED** in the PRD §15 assumptions table (`prd.md:489` as of 2026-08-05), and files the residuals as deferred work. It also marks as **unverified** whether SMC 2015 constrained the search grid or reweighted candidates: the repository's only source is the summary phrase, and the hard-versus-soft argument turns on it.

**Coexistence ruling.** They do not coexist; FR-53 supersedes FR-54's delivery mechanism. ~~Because with the classifier rejected there is nothing left for FR-54 to condition on.~~ **CORRECTED 2026-08-05 (external review): false.** PRD §14 Q5 names two non-classifier style sources, and this repository already reads file-tag metadata, so a style source is not hypothetical. The accurate ground is a scope statement: **Epic 12 builds no style-conditioned prior of any kind**, on the product-policy premise above. ~~FR-54's "must abstain rather than guess" is satisfied vacuously.~~ **Also corrected: a rejected requirement is inapplicable, not satisfied.** What holds is that neither the reject nor FR-53 creates the failure surface the abstain clause exists to control, because a caller *declares* their material and owns the consequence where a classifier *infers* it and can be silently wrong. The hard-filter objection survives and is answered by opt-in defaults, not dismissed — FR-53 defaults to today's bounds, so the default path never acquires the failure mode, and Story 12.1 measured the cost of opting in wrongly (a moved window folds `Submerged_Lament` to ~35 and the scan guard returns nil).

## Verification

**Commands:**
- `git diff --stat 13135f8 -- Sources/ Tests/` -- expected: empty output
- `grep -c "26 FRs" _bmad-output/planning-artifacts/epics.md` -- expected: unchanged from pre-edit count
- `awk '/^development_status:/{f=1;next} /^[a-z_]+:/{f=0} f && /^  [^ #]/{n++} END{print n}' _bmad-output/implementation-artifacts/sprint-status.yaml` -- expected: `117`

  (The earlier form, `grep -n "development_status" -A 200 ... | grep -cE '^[0-9]+-\s+\S+:'`, returned **163** and was wrong twice over: the fixed `-A 200` window runs past the end of the `development_status` block into later top-level keys, and the `^[0-9]+-` prefix matches grep's own emitted line numbers rather than anything in the file. The awk form terminates the block on the next top-level key and counts only two-space-indented, non-comment entries.)

~~`make test` -- expected: 993 tests pass, 4 known issues~~ **DROPPED 2026-08-05.** It proved nothing this block does not already prove: `git diff --stat 13135f8 -- Sources/ Tests/` returning empty is direct evidence the tree is untouched, where a test run is indirect evidence at minutes of cost. The hardcoded `993`/`4` figures are also a brittle failure mode; any unrelated test added on another branch turns a passing suite into a failed verification step for a documentation-only story.

**Manual checks:**
- Every `file:line` citation in the decision document resolves to text that actually says what is claimed. Spot-check all of them; a fabricated citation in a decision artifact is worse than no artifact.
- `epics.md` and `prd.md` no longer contain an unannotated assertion that the classifier decision is outstanding.

## Auto Run Result

Status `review`, not `done`. The workflow's finalize step says to commit and set `done`;
`project-context.md:141` records the signed commit and the separate-LLM
`/bmad-code-review` as operator-owned closeout steps, and states that a story with those
pending closes in `review` with a "Pending user action" subsection. That convention
governs. Story 12.1 closed the same way on 2026-08-02.

**Decision recorded: reject.** This project does not build a style classifier. The
replacement octave mechanism the reject exit requires be named is FR-53's caller-declared
bounds, shipped by Story 12.1. The two mechanisms do not coexist: FR-53 supersedes
FR-54's delivery mechanism. The decision reverses the operator decision recorded at PRD
§14 Q5 on 2026-07-28, and says so in those words at every site where it is annotated.

**The reject rests on a stated product-policy premise, not on the evidence alone**
(decision artifact §1.1): automatic style inference is outside this library's mission,
and callers own their own domain constraints. Added 2026-08-05 after two independent
external reviews found the evidence ledger supports "not now" as readily as "never".

**Files changed** (9; nothing under `Sources/` or `Tests/`):

- `12-2-style-classifier-decision.md`: NEW. The citable decision record; §1.1 premise added and every PRD citation converted to the stable-identifier form on external review.
- `12-2-style-classifier-scope-or-defer-decision.md` — NEW. This story spec.
- `epic-12-context.md` — NEW. Compiled epic context; `:49` corrected post-decision.
- `epics.md` — 8 annotations: FR-54, FR-54a, both coverage rows, both prose count sites, the two frontmatter count sites, the F1-splits note, and an appended Story 12.2 outcome. FR-54 and the outcome paragraph were re-corrected on external review.
- `prd.md` — 10 annotations: FR-54, FR-54a, the F1 claim, §8.1 MVP, §14 Q5 (reversed), the executive summary, the small-model claim, the non-DnB success metric, the inverted risk row, and AS-7 (re-annotated from WEAKENED to UNTESTED on external review).
- `deferred-work.md`: 6 new entries in total plus one in-place annotation of Story 12.1's now-fired re-open trigger. Nothing removed or weakened.
- `12-1-consumer-specifiable-tempo-search-range.md`: 1 annotation at `:18`, retiring its live-tense reference to this decision.
- `sprint-status.yaml` — `12-2-...: backlog` to `review`. 117 entries preserved.

**Review:** two passes. Same-session adversarial pass: 21 patches (4 high), 2 deferred, 4
rejected, zero intent gaps, zero spec defects. External pass (Codex diff review plus
Gemini tie-break): 7 patches (1 critical, 3 high, 3 medium), 0 deferred, 0 rejected, 3
new deferred-work entries. The decision survived both unchanged. Full breakdown in the
two Review Triage Log entries above.

**Verification performed** (re-run 2026-08-05 after the external pass):

- `git diff --stat 13135f8 -- Sources/ Tests/` — empty. Byte-identity holds.
- ~~`make test` — 993 tests in 168 suites passed, 4 known issues.~~ **DROPPED**, per the Verification block above: byte-identity is direct evidence the tree is untouched, and the hardcoded counts are a brittle failure mode. The figure is retained here only as the record of what was run before the first review pass.
- Story 12.3 through 12.9 grep for `FR-54|classif|style|genre|taxonom|prior` over the corrected range `epics.md:2081-2350` — 0.
- `development_status` entries — 117, by two independent counting methods.
- All **four** `26` count sites (`epics.md:6`, `:11`, `:391`, `:534`) annotated and unchanged. The earlier claim of three sites is corrected in AC #4.
- **Every PRD citation re-opened and confirmed by content on 2026-08-05, not adjusted by arithmetic.** The first pass claimed this and it was untrue: this story's own four-line PRD insertion had left every PRD citation stale by 4. All are now stable-identifier-first with a dated line hint.

**Residual risks:**

1. **The decision reverses a recorded operator decision** (§14 Q5, 2026-07-28). FR-54a, written after Q5, names that reversal as one of its two exits, and Story 12.2's own acceptance criteria delegate the selection here. It remains a judgment an operator may want to take back, and section 8 of the decision artifact is the reversal path.
2. **The reject is a product judgment, not an entailment.** §1.1 of the artifact states the premise and says so. If the operator does not hold it, the decision should be re-opened rather than re-argued from the evidence. This is now the primary re-open trigger.
3. **Hard bounds have a failure mode soft reweighting does not.** `Options.tempoScanRange` never generates an out-of-range candidate, so a drum-and-bass track with a half-time or polyrhythmic section, analyzed under a declared `130...180`, loses the correct answer outright where FR-54's prior would have degraded gracefully. Recorded as the live counter-argument in `deferred-work.md`, not resolved.
4. **The named replacement ships in Story 12.1, which is at `review`.** A review change to `TempoScanRange` or `PerceptualTempoWindow` is a re-open condition for this decision. Recorded in the artifact.
5. **Three of the six evidence lines are contingent**, not structural: a new corpus, a story that unfreezes `MLTechnique`, or a working first model would each retire one. They are stated as re-open conditions rather than presented as permanent.
6. **Four documents outside this story's edit scope still carry stale PRD line citations**, two of them caused by this story's insertion and two already wrong at `13135f8`. Filed as deferred work with the per-document verification.

## Pending user action

1. **Commit.** Nothing is committed. 4 modified, 3 new, all verified. Gated on the 1Password SSH signer.
2. **`/bmad-code-review` on a separate-LLM cadence**, per project convention. Both reviewers in this run were same-session subagents.
3. **Confirm or overturn the Q5 reversal.** This is the operator's call. Overturning costs one pass through section 8 of the decision artifact.
4. **Decide whether PR #189 should carry this.** The work sits on `rterhaar/12-2`, cut from `rterhaar/epic-12` at `13135f8`. The umbrella PR tracks `rterhaar/epic-12`, so this branch needs merging there before it appears.
