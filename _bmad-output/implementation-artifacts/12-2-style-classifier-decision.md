# Story 12.2 decision: the style classifier is rejected

- **Date:** 2026-08-05
- **Story:** 12.2 (`12-2-style-classifier-scope-or-defer-decision.md`)
- **Scope:** documentation only. `Sources/` and `Tests/` are byte-identical to `13135f8`.
- **Status of this file:** the citable record. Every other document annotated by this story points here.

Paths below are repository-relative. `prd.md` means
`_bmad-output/planning-artifacts/prds/prd-BoomBoomBoomKit-2026-07-26/prd.md`.
`epics.md` means `_bmad-output/planning-artifacts/epics.md`.

**How to read the citations in this file.** PRD line numbers drift, and this story's own
annotations proved it: a four-line insertion into the executive summary shifted every PRD
reference below line 43 by +4, and the first draft of this artifact cited the pre-edit
numbers throughout. Every PRD citation below therefore leads with a **stable identifier**,
a section number, an FR identifier, a question number, or an assumptions-table row, and
carries the line number only as a dated secondary hint. **The named section or row
governs. Where a line number and the section it names disagree, the name is right and the
number has gone stale.**

Every citation in this file was re-opened and re-verified against the live files on
2026-08-05, during the external-review pass recorded in the story spec's Review Triage
Log. An earlier draft asserted flatly that all `file:line` citations "were opened and
read on 2026-08-05"; that was untrue of the PRD line numbers, which had been carried
over from before this story's own PRD edits. The claim is now accurate as re-verified.

## 1. Decision

**Reject.** This project does not build a style classifier.

Story 12.2's acceptance criterion offers three exits: scope it, defer it, or reject it
(`epics.md:2060`). This decision takes the third. The alternative octave mechanism that
replaces it, which the reject exit requires be named, is **FR-53's consumer-declared tempo
bounds**, already shipped by Story 12.1 as `TempoScanRange` (declared at
`Sources/BoomBoomBoomKit/TempoScanRange.swift:91`, `.default` at `:117`) and
`PerceptualTempoWindow` (declared at
`Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift:95`, `.default` at `:116`), reachable at
`Options.tempoScanRange` (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:365`) and
`Options.perceptualWindow` (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:401`).

**This replacement is not yet final.** Story 12.1 is at `review`, not `done`
(`sprint-status.yaml:346`). Any change to `TempoScanRange` or `PerceptualTempoWindow` arising
from its review changes the mechanism this decision names as the replacement, and is
therefore a re-open condition for this decision (section 8).

**Reject is not a claim that style conditioning has no value, and it is specifically not a
claim that the published SMC 2015 result failed here.** Section 6.1 is explicit that the
published configuration has never been run on this pipeline: Story 12.1 moved the octave-fold
window rather than the search range, and moved it to 100 to 200 rather than the published 130
to 180. What is rejected is **building a classifier to infer the style**, not the idea of
conditioning on one. The residual questions are filed as deferred work rather than closed.

**FR-54 and FR-54a remain covered by Epic 12.** This decision is their coverage. The FR
count stays 26 at all four sites (`epics.md:6`, `:11`, `:391`, `:534`). Coverage is not
implementation, and a later reader should not "correct" the count on the basis that no
classifier was built.

### 1.1 The product-policy premise this decision rests on

**This is a product judgment, not a finding. It is stated separately from the evidence
because the evidence does not produce it.**

The premise: **automatic style inference is outside this library's mission. Callers own
their own domain constraints.** BoomBoomBoomKit estimates tempo and loudness from audio.
A consumer who is analyzing drum-and-bass knows they are analyzing drum-and-bass; the
library's job is to accept that fact from them, not to re-derive it from the signal and
then be wrong about it in a way the consumer cannot see or override.

**Why this has to be said out loud.** The evidence ledger in section 3 is an inventory of
things that are absent, frozen, or broken today: no taxonomy, no usable training corpus, a
singular frozen ML seam, a first model that fails its gates. Every one of those could
change. Read on its own, the ledger supports **"not now"** at least as readily as it
supports **"never"**, and two independent reviews said so. What converts "not now" into
"no" is the premise above, and nothing else in this document does that work. An earlier
draft presented the reject as an entailment of the evidence. It is not one, and pretending
otherwise would leave a future reader unable to tell which part of the decision is a fact
about the repository and which part is a choice about what the library is for.

**A reader who rejects the premise should re-open the decision, not re-read the evidence.**
If the operator decides that inferring style is in fact within mission, the ledger becomes
a list of costs to pay rather than reasons to decline, and section 8 is the path.

**The practical argument, which stands independently of the premise.** Whatever mechanism
SMC 2015 used internally, a caller who knows their material can set
`Options.tempoScanRange` to the published `130...180` today, with no new type, no model,
and no taxonomy layer. Most of the practical benefit the style-prior lever promises is
reachable that way, and reaching it requires only that someone run the measurement
(section 6.2). A style taxonomy plus a classifier plus a router would be the machinery for
supplying that same range *automatically* to a caller who did not supply it. That
machinery is what is rejected.

> **Unverified, and load-bearing for the hard-versus-soft question.** This document does
> **not** assert that SMC 2015 constrained the search grid rather than reweighting
> candidates. The repository's only source on the published mechanism is the summary
> phrase "DnB prior 130-180 BPM" in PRD §4.3 (`prd.md:101` as of 2026-08-05), which
> establishes that the prior is expressed as a *range* and establishes nothing about how
> that range was applied. Settling it needs the primary paper. Filed as deferred work.

## 2. The question as posed

FR-54 requires a prior that reweights, never hard-filters, candidates by plausibility for a
**classified** style, and requires it to abstain rather than guess (PRD §5.1 FR-54,
`prd.md:131` as of 2026-08-05; `epics.md:153`).

FR-54a states that the classifier FR-54 depends on is an unscoped second model this PRD does
not build, and names four things nothing specifies: a training corpus, a style taxonomy, its
own accuracy gate, and a size and latency budget (PRD §5.1 FR-54a, `prd.md:132`;
`epics.md:154`). FR-54a offers two exits in its own text: scope the classifier as its own
feature with its own gates, or revisit §14 Q5 in favour of the caller-declared option, which
needs no model (same FR-54a line).

**§14 Q5 asks how a style prior gets *its style*, and offers three answers: user-declared,
metadata-derived, or classified** (PRD §14 Q5, `prd.md:475`). It recorded the operator
decision of 2026-07-28 that the prior derives style from a classifier rather than from a
caller-declared value or a file tag. FR-54a's second exit therefore means a **caller-declared
style**, an alternative *source for the style label*, not an alternative to the style concept.
Taking that exit reverses the operator decision. Section 7 states the reversal explicitly.

**Two mechanisms are in play here and they must not be conflated.** Q5's axis is *where the
style label comes from*. FR-53's axis, shipped by Story 12.1, is *what tempo bounds the
caller declares*, which bypasses the style concept entirely: a caller supplies numbers, not
a style, and no part of the pipeline maps a style to those numbers. FR-53 is therefore a
valid **alternative octave mechanism** under the reject branch, which is all Story 12.2's
acceptance criterion requires it to be (`epics.md:2060`). It is **not** evidence that Q5's
caller-declared-style option has already shipped. That option, a caller naming a style that
the library then maps to a prior, does not exist in this codebase and is not built by this
decision.

## 3. Evidence ledger

Six lines.

**This ledger does not, on its own, produce the reject.** It produces "not now". The step
from "not now" to "no" is the product-policy premise in section 1.1, which is a judgment and
is labelled as one. Read the ledger as the cost side of that judgment rather than as its
derivation.

**They are not fully independent, and an earlier draft's claim that they were is corrected
here (2026-08-05).** 3.1 and 3.2 share a primary source: both rest on PRD §5.1 FR-54a
(`prd.md:132` as of 2026-08-05), 3.1 on its exit clause and 3.2 on its absence clause. Treat
them as two readings of one requirement, not two witnesses.

**Three are structural and three are contingent.** The distinction matters, because a
reviewer can fairly observe that the contingent ones are defer-shaped rather than
reject-shaped.

- *Structural*: 3.1 (FR-54a names the exit in its own text), 3.2 (the four artifacts are
  absent by assertion), 3.6 (no downstream story or gate depends on FR-54). These do not
  turn on a fact that could change without someone rewriting a requirement.
- *Contingent*: 3.3 (the available corpora cannot train a classifier), 3.4 (the ML seam is
  frozen and singular), 3.5 (the first model does not work). A new corpus, a named story
  unfreezing `MLTechnique`, or a working v3 model would each retire one of these. They are
  reasons this is not worth doing **now**, and the reject rests on the structural three;
  the contingent three set the re-open conditions in section 8 rather than the basis.

The decision is unchanged by this reframing. What changes is that its basis is legible.

### 3.1 FR-54a names the exit in its own text

PRD §5.1 FR-54a (`prd.md:132` as of 2026-08-05) reads, in the requirement's own words:
"Either scope the classifier as its own feature with its own gates, or revisit Q5 in favour
of the caller-declared option, which needs no model."

The exit exists. The requirement that depends on the classifier is the same requirement that
authorizes declining to build one, so declining needs no external warrant beyond a written
decision, which is what this document is.

**~~The caller-declared option shipped on 2026-08-02 as Story 12.1 ... Selecting the exit
costs no new work.~~ WITHDRAWN 2026-08-05 (external review).** Both halves were wrong, and
they were wrong for the same reason: they conflated Q5's axis with FR-53's.

- Q5's caller-declared option is a caller-declared **style**, which the library would map to
  a prior. Story 12.1 shipped caller-declared **BPM bounds** (`TempoScanRange`,
  `PerceptualTempoWindow`), which bypass the style concept altogether. Story 12.1 did not
  walk through Q5's exit; it built something adjacent to it. Section 2 states the distinction.
- Selecting the exit therefore does **not** cost no new work. It costs whatever a
  caller-declared style prior would cost, and this decision declines to pay it on the
  product-policy ground in section 1.1, not on the ground that it is free and already done.

What survives for the ledger is the first sentence only: **FR-54a names the exit.** That is
structural, it rests on the requirement's own text, and it does not depend on Story 12.1.

**For the record, the shipped bounds pairs are real and are what section 4 names as the
replacement mechanism.** `TempoScanRange` defaults to 40 to 250
(`Sources/BoomBoomBoomKit/TempoScanRange.swift:101`, `:104`) and `PerceptualTempoWindow` to
60 to 200 (`Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift:107`, `:110`). They are a
valid alternative octave mechanism. They are not Q5's answer.

### 3.2 The four artifacts are absent by assertion, not by inference from silence

Both primary documents state the absence in as many words.

- PRD §5.1 FR-54a (`prd.md:132` as of 2026-08-05): "Nothing in F1 specifies its training
  corpus, its style taxonomy, its own accuracy gate, or its size and latency budget".
- `epics.md:154`: "No training corpus, style taxonomy, accuracy gate, or size is specified
  anywhere."

A repository-wide search for `taxonom` on 2026-08-05 returned no style-classifier taxonomy.
The only genre taxonomy that exists is covered in 3.3 and is a different artifact.

### 3.3 The taxonomy that does exist is corpus annotation, and the corpora cannot train a classifier

The 25-label genre list is `ALLOWED_GENRES` in
`Tests/BoomBoomBoomKitTests/Fixtures/convert-rekordbox-export.py:41`, a develop-only fixture
converter withheld from `main`. It labels corpus rows for stratified accuracy reporting.
`Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:11-13` records that the list is
canonical for annotation and that "Swift does not validate membership here (adding a genre
needs no library change)". No symbol in `Sources/BoomBoomBoomKit/` infers a genre or a
style; the three occurrences of the word **in Swift source under that directory**
(`Sources/BoomBoomBoomKit/DSPTechnique.swift:33`,
`Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift:14`,
`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:370`) are doc-comment prose. The
directory as a whole holds nine matching files: those three plus six per-case documentation
Markdown files under `Sources/BoomBoomBoomKit/Resources/Documentation/`, which are prose
about DSP techniques and ensemble policies, not classification code. An earlier draft said
"three occurrences ... there" without the Swift-source qualifier and undercounted the
directory.

Neither available corpus can supply classifier training data.

- OA300 is drum-and-bass dominated: 67 of the 82 analyzed tracks carry the
  `drum-and-bass` label (`_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json`,
  `perGenre` entry `genre: drum-and-bass`, `total: 67`, against top-level `analyzed: 82`).
  A single-class majority of that size cannot train or validate a multi-class style
  classifier. OA300 is also declared an evaluation corpus, not a training corpus (PRD §11
  "Corpus" paragraph, `prd.md:407` as of 2026-08-05).
- GiantSteps has genre mass, but the PRD's contamination boundary forbids a track, remix, or
  artist appearing in both the evaluation corpus and any training set (PRD §5.3, the
  numbered "Contamination boundary" item, `prd.md:184`). That is the primary citation and it
  is unambiguous. A secondary line, the *Which corpora* review flag in PRD §5.3
  (`prd.md:287`), notes that
  "§5.3 excludes GiantSteps from the balanced corpus on the contamination reason in
  FR-69c.1, while this FR keeps it as a gate arm", but that line is a **review flag
  recording an unresolved PRD self-contradiction, tracked as Q10**, not a settled exclusion.
  An earlier draft cited it as though it were settled. It is cited here only as evidence
  that GiantSteps' corpus role is itself contested, which is a reason not to build a
  classifier on it, not a reason to claim the PRD has ruled.

### 3.4 The ML seam is frozen and singular

`Options.mlTechnique` is one optional slot:
`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:239` declares
`public var mlTechnique: (any MLTechnique)?`. There is no second slot, and no list.

`MLEvaluation` (`Sources/BoomBoomBoomKit/MLTechnique.swift:34`) carries exactly three
fields: `bpm` (`:44`), `confidence` (`:52`), `modelIdentifier` (`:64`). No field carries a
style label.

The protocol is frozen. `CLAUDE.md:183` records that
`evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?` is "**frozen** at Story 4-5 DD #18
close-out", and that "field expansions on `MLEvaluation` / `EnsembleDecision` require a
named story spec". A second model in the inference path therefore requires unfreezing the
seam by named story.

**The size sub-argument is dropped (2026-08-05).** An earlier draft added that a second model
"~~competes with the PRD's stated intent to ship 'a small model inside the demo app'
(PRD §1, `prd.md:46` as of 2026-08-05) and with §7's exclusion of larger backbones
(`prd.md:353`)~~". That objection
was **relaxed by the operator before this decision was taken**: `epics.md:2379` records
"**Compute-constraint change (operator, 2026-07-21).** CPU-only inference is **no longer a
requirement**. Larger models are acceptable if accuracy improves", explicitly removing the
BNNSGraph latency objection that ruled out transformer-scale backbones. The same passage is
careful that this does *not* retire the AST-as-regression rejection, which rests on a
measured Acc1 gap rather than on model size. So size is not a live constraint on a second
model, and 3.4 does not lean on it.

What survives, and what 3.4 rests on, is **singularity plus the freeze**: one optional slot,
no field for a style label, and a protocol that cannot grow one without a named story spec.
That holds regardless of how large the model is allowed to be.

**Recorded as a pre-existing cross-document contradiction, not resolved here.** PRD §1
(`prd.md:46` as of 2026-08-05) still reads that Epic 12 "ships a small model inside the demo
app", written 2026-07-26;
`epics.md:2379` relaxed the compute constraint on 2026-07-21. The two documents disagree on
whether model size is bounded. Reconciling them is a PRD-maintenance question outside this
story's documentation-only scope, and is left visible rather than silently picked.

### 3.5 The first model failed, and has not been fixed

`_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md:8-11`: "The v2 model is NOT
ship-quality. Both bundle gates fail and three retrains proved the failure is structural, not
a labeling-volume problem." The calibration ladder at `:16-17` records OA300 falling 50/82 to
43/82 against a `>55/82` gate and GiantSteps reaching 348/661 against a `>=537` gate, both
marked FAIL.

Adding a second model to the deployment path before the first one works is not a plan this
project can defend.

### 3.6 Nothing waits on it

- No decision gate references FR-54. PRD §6's three gates, Gate 0 / Gate 1 / Gate 2, turn on
  F2, F4 and FR-58 (`prd.md:343`, `:345`, `:347` as of 2026-08-05).
- The Story 12.3 through 12.9 sections of `epics.md`, spanning **`epics.md:2081-2350`**,
  contain zero occurrences of `FR-54`, `classif`, `style`, `genre`, `taxonom`, or `prior`.
  Verified by case-insensitive grep over that range on 2026-08-05, count 0. (The range was
  `:2079-2348` as measured at `13135f8`; this story's own annotation of the Story 12.2
  section inserted two lines above it, so the corrected range is the one to re-run. The
  pre-shift range now returns 1, from text this story added.)

The reject therefore strands no downstream story. Story 12.2's own acceptance criterion,
"no remaining Epic 12 story depends on it" (`epics.md:2069`), holds as measured, not as
asserted.

## 4. What replaces it

FR-53, delivered by Story 12.1. A consumer who knows their material declares its tempo
bounds at the input instead of a model inferring a style label and a prior from them.

- `Options.tempoScanRange` sizes the candidate search grid
  (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:365`).
- `Options.perceptualWindow` sets the octave-normalization window
  (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:401`).
- Both default to the pre-story values, so the default path is unchanged
  (`Sources/BoomBoomBoomKit/TempoScanRange.swift:101`, `:104`;
  `Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift:107`, `:110`).

This is the replacement mechanism the reject exit requires be named (`epics.md:2060`). It is
narrower than FR-54 in one respect: it does not reweight candidates *within* the bounds it
sets. **It may be closer to the published mechanism than that framing suggests**, because PRD
§4.3 (`prd.md:101` as of 2026-08-05) describes the SMC 2015 prior as a BPM range ("DnB prior
130-180 BPM") and `Options.tempoScanRange` sets a BPM range. That is a similarity in how the
prior is *expressed*, not an established similarity in how it is *applied*: whether SMC 2015
constrained the search grid or reweighted candidates inside it is **unverified** here, per the
note in section 1.1. See 6.1.

**What FR-53 is and is not.** It is a valid alternative octave mechanism, which is what the
reject exit requires. It is **not** the caller-declared *style* option that PRD §14 Q5 names,
and this document does not claim it is. See section 2.

## 5. Coexistence ruling

**They do not coexist. FR-53 supersedes FR-54's delivery mechanism.**

Story 12.2's acceptance criterion requires this to be stated explicitly (`epics.md:2071-2073`),
because FR-54 mandates "reweights (never hard-filters)" (PRD §5.1 FR-54, `prd.md:131` as of
2026-08-05; `epics.md:153`) while a consumer-specifiable range is a hard filter by
construction (`epics.md:538`).

The ruling and its reasoning:

1. **Supersession, not coexistence.** ~~With the classifier rejected there is no style label
   for FR-54 to condition on, so nothing of FR-54's mechanism remains to run alongside
   FR-53.~~ **CORRECTED 2026-08-05 (external review): that reason is false.** PRD §14 Q5
   (`prd.md:475` as of 2026-08-05) names three sources for a style label and only one of them
   is a classifier; the other two, caller-declared and metadata-derived, survive this
   decision untouched. This repository already reads file metadata tags in
   `FileMetadataReader`, so a style source is not even hypothetical. The correct reason for
   supersession is narrower and is a scope statement, not a logical impossibility: **Epic 12
   builds no style-conditioned prior of any kind**, because this decision declines the
   product-policy premise in section 1.1 that would justify one, and FR-53's declared bounds
   are the octave mechanism the epic ships instead. If a later story reinstates a
   style-conditioned prior over a caller-declared or metadata-derived style, that is a
   re-open of this decision (section 8), not a coexistence question left open here.
2. **FR-54's abstain requirement is inapplicable, not satisfied.** ~~It is satisfied
   vacuously.~~ **CORRECTED 2026-08-05 (external review).** FR-54 requires the prior to
   "abstain rather than guess: an unrecognized style degrades to no prior, never to a wrong
   one" (PRD §5.1 FR-54, `prd.md:131`). A **rejected** requirement is not satisfied by
   anything; it simply does not apply, because the prior it constrains is not built. Claiming
   satisfaction reads as though FR-54 had been delivered in some attenuated form, which would
   mislead a reader auditing FR coverage. What is true, and is the substantive point the
   overclaim was reaching for: the failure surface FR-54's abstain clause exists to control,
   a classifier inferring a style and being silently wrong, is the router-error surface §14
   Q5 accepted when it settled on classified (`prd.md:475`), and rejecting the classifier
   means that surface is never created. FR-53 does not create it either, because a caller
   declares rather than infers. Neither of those facts satisfies FR-54.
3. **The hard-filter objection survives and is answered by opt-in defaults, not dismissed.**
   FR-53 defaults to today's bounds, so the library's default path never acquires the
   failure mode (`epics.md:538`; defaults at
   `Sources/BoomBoomBoomKit/TempoScanRange.swift:101`, `:104` and
   `Sources/BoomBoomBoomKit/PerceptualTempoWindow.swift:107`, `:110`).
4. **The cost of opting in wrongly is measured, not hypothetical.** Moving
   `perceptualWindow` alone can return nil for a track: `Submerged_Lament` folds to about 35
   under a `30...60` window and the default `40...250` scan guard rejects it
   (`CLAUDE.md:178`). The corpus-wide cost of the story's own motivating window is in section
   6.

## 6. What this decision does NOT claim

### 6.1 It does not refute Hörschläger et al. SMC 2015

PRD §4.3 (`prd.md:101` as of 2026-08-05) records the strongest published result in the epic:
genre-conditioned tempo priors lift drum-and-bass Acc1 from 7.19% to 78.42% and overall 45.5%
to 75.0% on GiantSteps, with no model change.

~~Story 12.1's impact report is the first direct test of that result's transfer to this
project~~ **RESTATED 2026-08-05 (external review). It is not a direct test of anything in
SMC 2015, and calling it one contradicted the four paragraphs immediately below, which
concede it moved the wrong knob to the wrong values.** Four things a direct test would have
needed, and none of which the report did:

- it did not infer a style;
- it did not accept a declared style;
- it did not condition any behaviour by style, applying one global window to all 82 tracks
  regardless of genre;
- it moved `Options.perceptualWindow` rather than `Options.tempoScanRange`, and moved it to
  `100...200` rather than the published `130-180`.

**What the report actually is: evidence about globally narrowing the octave-fold window**, on
one corpus, at one setting, with no style conditioning of any kind. That is a useful and
honestly negative result about that question, and it is not a test of style-prior transfer.

The result itself, for the record
(`_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json`): overall
`deltaAcc1: 0`, `deltaAcc2: -3`; on the `drum-and-bass` genre itself, n=67, `deltaAcc1: -1`,
`deltaAcc2: -2`.

**That measurement does not refute SMC 2015, because it did not test the published
configuration on either axis.**

An earlier draft of this section argued the mechanisms differ: that 12.1 moved a hard window
while FR-54 specifies a soft prior, so a negative for one is not a negative for the other.
**That argument is withdrawn as unsound (2026-08-05).** The line it rested on says the
opposite: PRD §4.3 (`prd.md:101`) describes the published configuration as "20% DnB, **DnB
prior 130-180 BPM**". The published prior is stated as a *range*. A mechanism distinction
cannot be built on a citation that names a range. Note that the converse does not follow
either: a range-shaped statement of the prior does not establish that the range was applied
as a search constraint rather than as a reweighting. That remains **unverified** (section
1.1).

The honest reasons the 12.1 measurement does not transfer are both concrete, and both are
readable off the report:

1. **Wrong knob.** SMC 2015 conditions tempo estimation on genre over a stated BPM range;
   whether that range constrained the search grid or reweighted candidates inside it is
   **unverified here** (section 1.1), and the argument below does not depend on which it was,
   because Story 12.1 moved neither. Story 12.1 moved
   `Options.perceptualWindow`, the octave-*normalization* window consumed by
   `BPMAnalyzer.rangeNormalize` after candidate selection
   (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:401`). It did not move
   `Options.tempoScanRange`, the pair that actually sizes the candidate search grid
   (`Sources/BoomBoomBoomKit/AudioAnalysisService.swift:365`). The report says so in its own
   `metric` field: "full AudioAnalysisService.analyzeBPM at default Options with **only
   perceptualWindow moved**"
   (`_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json`).
2. **Wrong values.** Even on the axis it did move, it moved `baselineWindow` 60 to 200 to
   `comparisonWindow` 100 to 200 (same report), not the published 130 to 180.

So the published DnB configuration has still never been run on this pipeline. The 12.1
measurement is evidence about a 100-to-200 fold window, and nothing more.

**This cuts against this document's own earlier framing, and is recorded rather than
buried.** If the published prior is a declared BPM range, then FR-53's caller-declared bounds
are a *closer* analogue of the published mechanism than section 4's "narrower than FR-54" and
section 5's hard-filter framing imply, not a more distant one. Read strictly, that makes the
replacement mechanism named in section 1 a better substitute for FR-54 than this document
originally claimed, while also removing the excuse that 12.1's negative result was measuring
something unrelated. Both consequences point the same way: the experiment that would settle
this is `tempoScanRange` at 130 to 180 over the drum-and-bass rows, and it has not been run.

**AS-7 is untested, not weakened.** ~~What the measurement does do is weaken AS-7.~~
**CORRECTED 2026-08-05 (external review).** AS-7, in the PRD §15 assumptions table
(`prd.md:489` as of 2026-08-05), assumes that "the SMC 2015 style-prior result transfers to
our corpus and pipeline", with the stated risk if wrong that "F1 loses its evidence base and
drops down the ranking". A WEAKENED verdict was claimed on the strength of the 12.1 report
being "the first direct test". That claim is withdrawn above, and the verdict cannot outlive
it: a measurement that conditioned nothing on style is not a test of *style-prior transfer*,
so it cannot move AS-7 in either direction.

AS-7's status is therefore **UNTESTED**, exactly as it was before Story 12.1 ran, and the
published configuration has never been run on this pipeline. The PRD annotation at `:489` is
kept rather than reverted, and restated to say that. What the 12.1 report does bear on is
the narrower question of whether a global fold-window narrowing helps, which is a different
assumption that AS-7 does not state, and which is already tracked in `deferred-work.md`
under the Story 12.1 entry.

### 6.2 It does not claim genre conditioning is worthless

Two residual questions survive this decision, and neither is tested anywhere in the project.

1. **The published configuration itself.** Per 6.1, `tempoScanRange` at the published 130 to
   180 over drum-and-bass has never been run. That is a measurement, not a model, and it is
   available today at `Options.tempoScanRange`.
2. **Reweighting rather than bounding.** FR-54's "reweights (never hard-filters)" language
   describes candidate *scoring*, which neither bounds pair does; both size or fold a range
   instead. Whether a scoring prior over a **caller-declared** style, which needs no
   classifier, beats a declared range is untested. PRD §14 Q5's *metadata-derived* option is
   likewise untouched by this decision, and this repository already reads file-tag metadata
   in `FileMetadataReader`.
3. **What SMC 2015 actually did.** Whether the published prior constrained the search grid
   or reweighted candidates is unverified here (section 1.1). The hard-versus-soft argument
   in section 5 turns on it, so it is filed rather than assumed.

Note that (2) is stated here as an untested difference in what the mechanism does, not as a
reason 12.1's negative result can be set aside. That inference is the one withdrawn in 6.1.

Both are filed in `deferred-work.md` under `## Deferred from: Story 12.2 (2026-08-05)` with
re-open triggers.

### 6.3 It does not amend scope beyond the reject exit

No follow-on story is created and no FR count is amended. Those belong to the scope-it
branch (`epics.md:2062-2064`), which is not selected.

## 7. This reverses an operator decision

**Reversing PRD §14 Q5 (`prd.md:475` as of 2026-08-05) is reversing an operator decision,
recorded 2026-07-28.**

Q5 asked how a style prior gets its style and resolved: "**RESOLVED 2026-07-28 (operator):
classified.** The prior derives style from a classifier rather than a caller-declared value
or a file tag." It recorded what that choice bought (coverage with no caller input, no
dependence on absent or wrong genre tags) and what it cost (a router-error failure surface
plus a second model in the deployment path).

This decision selects Q5's caller-declared answer over its classified one. It is not a
clarification of Q5 and not an implementation detail under it. It is a reversal, and Q5 is
annotated as such in the PRD.

**What "caller-declared" means here, stated precisely.** Q5's caller-declared option is a
caller-declared **style**. This decision selects it in the sense that it settles Q5 against
`classified`; it does **not** build a caller-declared style prior, and Story 12.1 did not
build one either (section 2). What Epic 12 ships in its place is FR-53's caller-declared
tempo bounds, which are a different mechanism on a different axis. ~~The caller-declared
option now exists in shipped code where in July 2026 it did not.~~ **WITHDRAWN 2026-08-05
(external review): that was the same conflation, and it is false.**

The basis for reversing is therefore FR-54a itself, which was written after Q5 and names the
reversal as one of two available exits (PRD §5.1 FR-54a, `prd.md:132`), together with the
product-policy premise in section 1.1. The premise is what does the work; the shipped bounds
pairs are the alternative octave mechanism, not the warrant.

## 8. Reversal path

To overturn this decision later, edit the places below.

**Scope of this list, stated honestly.** An earlier draft opened "edit these five places.
~~Nothing else depends on it~~" while section 9 listed thirteen documents this story
touched. That was false and is withdrawn (2026-08-05). The list below is the **complete set
of annotation sites**, reconciled against section 9. Items 1 through 5 are the *load-bearing*
edits, the ones that restore `classified` as the live answer; items 6 through 9 are the
remaining annotations that would otherwise be left contradicting a reinstated FR-54.

1. PRD §14 Q5 (`prd.md:475` as of 2026-08-05). Retract the `REVERSED 2026-08-05` clause and
   restore `classified` as the live answer.
2. PRD §5.1 FR-54 and FR-54a (`prd.md:131`, `:132`). Retract the rejection annotations. Take
   FR-54a's first exit instead: scope the classifier as its own feature naming a training
   corpus, a style taxonomy, its own accuracy gate, and a size and latency budget.
3. `epics.md:153`, `:154`, `:396`, `:397`, `:538`. Retract the same annotations on the FR
   list, the coverage rows, and the F1-splits note.
4. **All four count sites: `epics.md:6`, `:11`, `:391`, `:534`.** If scoping adds new FRs,
   amend the 26 count at every one of them. Reversal alone, without new FRs, does not change
   it. (An earlier draft named three of the four and omitted `:11`, the `epicsDesigned`
   frontmatter key.)
5. Create the follow-on story. Unfreezing `MLTechnique` for a second model needs its own
   named story spec (`CLAUDE.md:183`). Note that a size and latency budget is no longer
   constrained by `epics.md:2379`, though the unreconciled PRD §1 small-model claim
   (`prd.md:46`) would need settling either way (see 3.4).
5a. **Revisit the product-policy premise in section 1.1 first, and record the outcome.** It
   is the load-bearing item, because the evidence ledger alone never entailed the reject.
   Items 1 through 5 are downstream of it. A reversal that edits the annotations without
   restating the premise leaves the decision record incoherent.
6. `epics.md:12` (`partyModeAmendments`) and the Story 12.2 section's `OUTCOME 2026-08-05`
   paragraph. Both narrate the decision; both would need retracting.
7. PRD §1 executive summary (`prd.md:42`, `:46` as of 2026-08-05), the §9 success-metric row
   (`prd.md:388`), the §13 risk row (`prd.md:427`), and the §15 AS-7 row (`prd.md:489`).
   Retract the reject annotations; AS-7's UNTESTED verdict would need re-examining against
   whatever new evidence motivated the reversal.
8. `deferred-work.md`. The Story 12.2 entry and the fired-trigger annotation on the Story
   12.1 entry both assume the reject stands.
9. `epic-12-context.md` and this story's spec
   (`12-2-style-classifier-scope-or-defer-decision.md`). Both record the decision as taken.

**Re-open triggers.** The two Block-If conditions this story checked are the conditions under
which the reject basis collapses: any of FR-54a's four artifacts becoming specified, or any
Epic 12 story acquiring a dependency on FR-54. Three more follow from the evidence ledger's
contingent lines and from section 1:

- **The product-policy premise in section 1.1 being overturned by the operator.** This is
  the primary re-open trigger, because it is the primary ground.
- A corpus that can train and validate a multi-class style classifier without breaching PRD
  §5.3's contamination boundary (`prd.md:184` as of 2026-08-05) (retires 3.3).
- **Any story reinstating a style-conditioned prior over a caller-declared or
  metadata-derived style.** Neither needs a classifier, so neither is closed by this reject,
  and section 5's supersession ruling would have to be revisited.
- A named story that unfreezes `MLTechnique` for its own reasons (retires 3.4).
- A model that passes its bundle gates (retires 3.5).
- **Story 12.1's review changing `TempoScanRange` or `PerceptualTempoWindow`.** 12.1 is at
  `review`, not `done`; the replacement mechanism this decision names is not frozen yet.

## 9. Consequences per document

| Document | Change |
|---|---|
| `epics.md:153` (FR-54) | Annotated: rejected 2026-08-05 by this decision. |
| `epics.md:154` (FR-54a) | Annotated: the decision it demanded has landed. |
| `epics.md:396`, `:397` (coverage rows) | Annotated: still Epic 12, coverage is this decision. |
| `epics.md:6`, `:11`, `:391`, `:534` (**four** count sites) | 26 unchanged at all four, with the coverage-is-not-implementation reason stated inline. `:6` and `:11` were unannotated in the first pass and are now annotated; `:6` phrases it as "26 of 35 FRs covered by stories", which stays literally true. An earlier draft of this row, and the story spec's acceptance criterion, said "three count sites" and omitted `:11`. |
| `epics.md:12` (`partyModeAmendments`) | Annotated: the "explicit deferral plus a written decision" it left outstanding has landed. |
| `epics.md:538` (F1-splits note) | Annotated: the "later story or explicit deferral" resolved as reject. |
| `epics.md` Story 12.2 section | Outcome appended. |
| PRD §5.1 F1 claim (`prd.md:128` as of 2026-08-05) | Annotated: the "needs no model" justification is restored by rejecting the classifier, not by building it. |
| PRD §5.1 FR-54 (`prd.md:131`) | Annotated: not delivered, mechanism superseded by FR-53. |
| PRD §5.1 FR-54a (`prd.md:132`) | Annotated: second exit taken. |
| PRD §8.1 MVP (`prd.md:365`) | Annotated: F1's MVP content is FR-53 and FR-55. |
| PRD §14 Q5 (`prd.md:475`) | Annotated: reversed, and labelled as reversing an operator decision. |
| PRD §1 executive summary (`prd.md:42`, `:46`) | Annotated: the style-prior lever is not delivered by a classifier; the small-model claim at `:46` flagged against `epics.md:2379`. |
| PRD §9 success-metric row (`prd.md:388`) | Annotated: the non-DnB counter-metric guards a style prior that is not built. |
| PRD §13 risk row (`prd.md:427`) | Annotated: the mitigation is inverted, naming a rejected FR whose replacement is a hard filter. |
| PRD §15 AS-7 row (`prd.md:489`) | Annotated **UNTESTED**, restated 2026-08-05 from an unearned WEAKENED. The 12.1 report is not a test of style-prior transfer, so it cannot move AS-7. Annotation kept, not reverted. |
| `deferred-work.md` | New `## Deferred from: Story 12.2 (2026-08-05)` entry, plus a fired-trigger annotation on the Story 12.1 entry whose re-open trigger named this decision, plus a `## Deferred from: Story 12.2 external review (2026-08-05)` heading carrying three further entries. |
| `epic-12-context.md:49` | Corrected: asserted the decision was pending in the commit that resolves it. |
| `12-1-consumer-specifiable-tempo-search-range.md:18` | Annotated: its live-tense "Story 12.2 decides whether it is scoped, deferred, or rejected" is resolved, and points here. |
| `12-2-style-classifier-scope-or-defer-decision.md` (this story's spec) | Design Notes corrected; Verification block's sprint-status command fixed; acceptance criterion corrected from three count sites to four; Review Triage Log carries the external-review entry. |
| `sprint-status.yaml` | `12-2-style-classifier-scope-or-defer-decision: backlog` to `review`. |
| `Sources/`, `Tests/` | Unchanged. `git diff --stat 13135f8 -- Sources/ Tests/` is empty. |
