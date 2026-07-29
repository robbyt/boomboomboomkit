# PRD Quality Review — Epic 12: Octave-Aware BPM Model

Reviewed 2026-07-29 against `.claude/skills/bmad-prd/assets/prd-validation-checklist.md`.
Artifacts: `prd.md` (365 lines), `addendum.md` (79 lines). `.memlog.md` read as a
provenance control, not as an artifact under review.

Every numeric claim below was recomputed or grepped against the repository. Where I
say a figure checks out, I ran it.

---

## Overall verdict

**PASS WITH FINDINGS — conditional.** This is a genuinely unusual PRD: the evidence
discipline is the best I have seen in this repository, the counter-metrics are real,
the statistics in FR-69/69a/69c are correct (I verified the entire McNemar table
exactly, including the two GiantSteps rows), and the document retracts its own prior
claims in public rather than quietly editing them. That is earned, not furniture.

What is at risk is the part the epic actually turns on. The bundle gate — the MVP's
principal deliverable — has an undefined half (FR-68's no-regression condition), an
operative significance level that contradicts its own planning table (FR-69 vs FR-69a),
and an unresolved answer to *which corpora it runs on*. The corpus that unblocks it
rests on a selection rule that FR-59a.1 explicitly forbids. And the MVP contains an
untracked second model-training programme (F1's genre classifier) inside a scope
justified as "needs no retrain."

**F2 is implementation-ready today. F1, F3 and F6 are not.** Five critical findings
below should close before a Story 12.x touches them. None requires restarting the PRD;
all are amendments within the existing structure.

---

## 1. Decision-readiness — **adequate**

The trade-off honesty is strong and in places exemplary. FR-69 does not merely correct
its earlier margin claim — it prints the struck text, names the statistic that was
wrong, and states the conclusion it had hoped for and did not get ("My hypothesis that
this would make 2 tracks MORE defensible was refuted"). §14 Q5 records that the
classifier decision "accepts a router-error failure surface and a second model in the
deployment path — the exact cost the 2026-06-09 roundtable cited when ranking genre-MoE
last," rather than smoothing it. FR-72a lists three gaps its own resolution does not
close. This is not a PRD that balances everything to neutral.

Where it fails decision-readiness is at the point of decision. A maintainer asking
"what number ships a model?" cannot get an answer from this document. FR-68 says "a
stated margin"; FR-69 says the threshold depends on a discordance `d` "which has not
been measured"; FR-69a supplies an operative rule at a different α than FR-69's table;
FR-68's second condition ("no regression in any band DSP already handles") has no
operational definition at all, and FR-59c forbids the per-band inference that would be
the obvious way to adjudicate it. The gate is four documents' worth of correct
statistical reasoning that does not yet compose into a decision procedure.

### Findings

- **critical** *The gate's operative α is inconsistent with its own planning table*
  (§5.6 FR-69 / FR-69a) — FR-69's table computes minimum net lift at exact two-sided
  `p <= 0.05`, but FR-69a adopts the partial-conjunction rule `p2 <= 0.025` as the
  operative gate. Recomputed exactly: at `d = 25` the α=0.025 threshold is `t = 13`
  (19:6), not the table's 11; at `d = 132` it is `t = 28` (80:52), not 24. FR-69a
  spot-corrects only the 10% rows ("~8 on OA300 and ~20 on GiantSteps" — both verified
  correct). Two of the five table rows will be read as the gate and are too permissive
  for it. The same slip propagates to FR-59c: its "a band needs at least 6 discordant
  tracks all falling the same way" is the α=0.05 floor (6:0, p=0.03125); under FR-69a
  the floor is 7:0 (p=0.0156), because 6:0 fails `p <= 0.025`.
  *Fix:* recompute the FR-69 table at `p <= 0.025`, or state explicitly that the table
  is illustrative and FR-69a alone is normative. Restate FR-59c's floor as 7 discordant.

- **critical** *FR-68's no-regression condition has no operational definition* (§5.6) —
  "no regression in any band DSP already handles" is stated as half the gate. FR-59c
  then establishes that no per-band result at ~27 tracks can reach significance, and
  FR-69c item 4 says the remedy is to "predeclare each band's noninferiority margin and
  treat one-track bands as unmeasurable." No margin is predeclared anywhere, and FR-69c
  is itself listed as unresolved. As written, half the bundle gate cannot be evaluated.
  *Fix:* predeclare a per-band noninferiority margin in tracks (or an explicit
  "descriptive only, adjudicated by maintainer judgment" statement), and state which
  bands are declared unmeasurable in advance.

- **critical** *Which corpora the gate runs on is unresolved, and the sections
  disagree* (§5.3 FR-59 / §5.6 FR-68 / §9) — FR-59 builds a new ~162-track band-balanced
  corpus that "blocks the bundle gate" and benchmarks itself against "OA300's current 82
  tracks," implying replacement. FR-68, FR-69 and FR-69a still name three corpora
  (OA300, GiantSteps, Tony) and FR-69's table still uses `n=82` and `n=661`. §5.3
  excludes GiantSteps from its pooled count "for the contamination reason in FR-69c"
  while §5.6 retains it as a gate corpus. §9 says lift is measured "on **the primary
  corpus**" — singular — which directly contradicts Q1's resolution ("no single
  primary"). And because FR-59 draws the balanced corpus *from* OA300 and Tony, "two of
  three" is not two independent replications: the same track can score in two arms.
  *Fix:* state the gate corpus set explicitly and exhaustively — is the balanced corpus a
  fourth arm, a replacement for OA300, or the whole gate? Reconcile §9's "primary
  corpus" with Q1. If arms overlap by construction, say so and say what "two of three"
  then means.

- **high** *The ensemble-policy default — the thing that makes "ensemble lift" reachable
  by a user — is absent from the PRD* (§5.6, §5.7, §10) — `Options.ensemblePolicy`
  defaults to `.dspOnly`, under which `MLTechnique.evaluate` is never invoked. The
  charter flagged this precisely (`epics.md:1819`: "a better model changes nothing here
  until `.mlOnly` / `.highestConfidence` / `.weightedVoting` is on the default path,
  which is its own decision"). The PRD defines its gate as ensemble lift and its
  delivery as bundling weights into the demo app, and never says which policy the demo
  runs, whether the library default flips, or how a default flip reconciles with §10's
  "DSP-only output remains byte-identical" NFR and the identically-worded counter-metric
  in §9. A model can clear FR-68 and change nothing any user sees.
  *Fix:* add an FR covering the ensemble-policy configuration the gate is measured under
  and the one the demo ships with; disambiguate whether "DSP-only byte-identical" means
  "under `.dspOnly`" or "by default."

---

## 2. Substance over theater — **strong**

No persona theater: §2 has three job-shaped roles, each of which drives something
(the demo user drives F7, the consumer drives FR-73's BYOW invariance, the maintainer
drives §6). No innovation theater — the reverse, in fact: §4.3 spends four bullets
establishing that the epic is *ahead of* the published record on training targets and
therefore must ablate its own ideas, and §5.4's preamble says so explicitly. The NFRs
in §10 are product-specific to the point of being checkable (the FNV checksum tripwire,
`featureSetVersion` bump, per-track impact report) rather than "scalable/secure/
reliable." Non-Goals name seven things with reasons, including one deferred-not-rejected.

The Vision is not swappable. "BoomBoomBoomKit's ML tempo path ships nothing" is a
sentence only this project can write.

The one soft spot is that §1's headline framing is stronger than §4 supports — see H2
under Strategic coherence.

### Findings

- **low** *AS-3's caveat does not propagate to the claims that rest on it* (§1, §4.3,
  §15) — §4.3 tags the ~33k-parameter Böck figure as "secondary-source — AS-3," but §1's
  two headline claims ("roughly ten times smaller," "about thirty-five points higher")
  are both derived from it and carry no caveat. The arithmetic checks out (315k/33k ≈
  9.5; 87.0 − 52.6 = 34.4), but the Vision leads with the least-verified number in the
  evidence base. The Schreiber 82.1 comparison (~30 points, AS-3-independent) is the
  safer headline.
  *Fix:* lead §1 with the Schreiber figure and carry the TCN figure as the secondary
  amplifier, tagged.

---

## 3. Strategic coherence — **adequate**

There is a thesis and it is a bet: *capacity is not the constraint; the constraint is
implementation, training recipe, and measurement, and the cheapest unexploited lever is
a prior, not a model.* Feature ordering follows from it (F1 first on evidence, F2 before
funding anything, F4/F5 gated on F2's ranking rather than on the charter's). Non-Goals
are the thesis stated negatively. Success Metrics validate the thesis rather than
measure activity, and the counter-metric table is the strongest single section in the
document — six entries, each naming a specific way of winning that would be a loss,
including "Reference-gap delta | A gain that merely re-approaches a baseline we should
already have," which is a genuinely sophisticated guard.

Two things weaken it. First, the headline evidence for the top-ranked feature is not
reconciled against our own measured baseline. Second, the MVP as finally composed
(F1+F2+F3+gate) is dominated by F3 — a corpus programme that was not part of the
original thesis and entered by restructure on 2026-07-28. The thesis says "the
constraint is implementation, recipe, and measurement"; the MVP now spends most of its
mass on measurement. That may be correct, but the PRD does not re-argue the thesis after
the restructure changed its centre of gravity.

### Findings

- **high** *F1's headline number is not reconciled with our own DSP baseline on the same
  corpus* (§1, §4.3, AS-7) — SMC 2015 lifted GiantSteps DnB Acc1 from 7.19% to 78.42%
  and overall from 45.5% to 75.0%. Our DSP path already scores 537/661 = **81.2%** on
  GiantSteps (`epics.md:65`, the FR-10 floor, which the PRD itself cites as "DSP's own
  score"). The published *post-prior* system is therefore about six points **below** our
  current DSP baseline on the same corpus. That does not refute the lever, but it means
  the 71-point DnB swing is measured against a detector whose DnB accuracy was 7.19%,
  and ours is almost certainly far higher — the PRD nowhere reports our DSP's per-genre
  or per-band accuracy on GiantSteps, so the actual headroom is unmeasured. §1 calls this
  "the strongest lever in the epic" and §8.1 puts it in MVP on that basis. AS-7 gestures
  at transfer risk in one line but does not quantify the baseline mismatch, which is the
  specific reason to doubt transfer.
  *Fix:* measure and report DSP's per-band and (where labels exist) per-genre Acc1 on
  GiantSteps and OA300 before F1 starts. State the available headroom in points. Restate
  AS-7 in terms of the baseline gap rather than generic transfer.

- **medium** *§9's Primary metric contradicts Q1* (§9) — "Ensemble Acc1 lift over
  DSP-alone on the primary corpus" survives from a draft in which a primary corpus
  existed. Q1 resolved that none does.
  *Fix:* restate as the FR-68/FR-69a rule.

- **medium** *§9's Secondary metric is unanchored* (§9) — "`Acc2 − Acc1` narrowing on the
  `<100` band" does not say on which path (the `<100` evidence in §4.1 is the *ML*
  model's E0 analysis on GiantSteps, n=60) or on which corpus. Under FR-59 the `<100`
  band becomes ~27 tracks on a different corpus, at which point FR-59c says no per-band
  claim is inferential — so the epic's stated mechanism-level metric lands in the one
  regime the PRD declares unmeasurable.
  *Fix:* name path and corpus; state whether it is a significance claim or a tripwire.

---

## 4. Done-ness clarity — **thin**

This is the weakest dimension and the one downstream story creation will suffer for.
The PRD is unusually good at *evidence* FRs (FR-60, FR-61, FR-65, FR-67, FR-74 are all
directly testable, and I verified FR-65's premise — `model_metadata.json` has 16 keys
and none is a loss parameter). It is weak at *procedure* FRs. Several FRs in F2, F3 and
F6 describe an intent without a completion condition.

Specific unfinishable-as-written FRs:

- **FR-56** "Reproduce a published TempoCNN-family baseline end to end" — which
  implementation, which checkpoint, and what counts as reproduced? Gate 0 turns on the
  answer ("if the reference baseline also scores near 52"), so "near" is load-bearing
  and undefined.
- **FR-57** "labelled *suspect*, *neutral*, or *ruled out*, with evidence" — this one is
  actually well-specified, and is the model the others should follow.
- **FR-58** "Rank the suspected causes by expected contribution and cost to test" — no
  rule for what makes a ranking done or defensible; Gate 2 depends on "the top-ranked
  cause."
- **FR-59b** "Declare one metrical-level convention" — no decision procedure, and Q9
  says it should not be decided until the 222-track ~1.5x cluster is understood. The FR
  most explicitly labelled "the load-bearing decision of F3" has no owner, no criterion,
  and a live blocker.
- **FR-59d** "volume with band-aware sampling" with "oversampling or loss weighting" —
  no target distribution, no volume floor, and the cited range "595-1509 tracks already
  in use" silently spans two different corpora (595 is GiantSteps train; 1509 is Tony's
  labelled total).
- **FR-68/FR-69** — see the Decision-readiness criticals.
- **FR-70** "a confidence-calibration floor" — no number. FR-18's `ECE_half_double <
  0.10` exists in `epics.md:77` and would be the obvious import; the PRD says only that
  "here it is a precondition."

### Findings

- **critical** *The evaluation corpus's label rule contradicts its own integrity
  requirement* (§5.3 FR-59a.1 vs the Feasibility block) — FR-59a.1 is emphatic: "Labels
  must be established independently of our DSP … Promoting a DSP-derived value to ground
  truth would turn the gate into a change detector for the thing it tests." The
  feasibility resolution that declares the corpus buildable defines its qualifying set as
  "an independent tag present, **and the DSP agreeing after octave normalization**." That
  is selection conditioned on our DSP. It biases the evaluation corpus toward material
  our DSP already resolves correctly, which simultaneously inflates the DSP baseline and
  suppresses the measurable ensemble lift the gate exists to detect — the precise trap
  FR-59a.1 names, entering through selection rather than through labelling. The binding
  "28 available for a 27 target" figure for 100-120 is entirely an artifact of this
  filter; the same source reports 262 tag-carrying tracks in that band without it.
  *Fix:* either drop the DSP-agreement condition from the selection rule and re-derive
  availability (and accept a manual-review burden on uncorroborated tags), or amend
  FR-59a.1 to permit DSP-agreement as a *triage* signal with a stated, measured bound on
  the selection bias it introduces. Do not leave both statements standing.

- **critical** *F1 contains an unscoped second model-training programme inside an MVP
  justified as needing no training* (§5.1 FR-54, §8.1, §14 Q5) — Q5 settled that the
  style prior gets its style from a **classifier**. FR-54 discloses the new dependency
  in one sentence and requires it to abstain. Nothing else in the PRD covers it: no FR
  builds it, no corpus supplies its genre labels, no taxonomy is named, no accuracy or
  abstain-rate gate is set, no size or latency budget is stated (in direct tension with
  the operator's explicit "small model" constraint and with §9's "Analysis wall-clock
  versus baseline" counter-metric), and §13 has no risk row for router error. §8.1's
  rationale for putting F1 in MVP reads "none needs a retrain, all are cheap relative to
  training" — which is false of a genre classifier.
  *Fix:* add FRs for the classifier (training corpus, taxonomy, abstain threshold,
  accuracy gate, parameter/latency budget), add a §13 risk row, and correct §8.1's
  rationale. Or de-scope F1 to a caller-declared / metadata-derived prior for MVP and
  defer the classifier, reopening Q5 explicitly.

- **high** *FR-55 misstates the fixtures it targets* (§5.1) — "the four
  `AccuracyFloorTests` known-failure fixtures, **all of which are DSP-path octave
  errors**." Verified against `Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift`:
  there are exactly four `knownFailure` entries, but three are octave-doubled and the
  fourth (line 126) is `"triplet-related: reports ~115.6, two-thirds of 174 (3:2)"`. One
  of the four is a triplet, not an octave error — and it is the *same phenomenon* as Q9's
  unexamined 222-track ~1.5x cluster, which makes the error consequential rather than
  cosmetic: F1's success criterion silently includes a case its mechanism does not
  address. Separately, `epics.md:1819` records that one of the four (`Submerged_Lament`)
  is a *selection* failure, not a generation failure — the right answer was in the
  candidate list and lost. FR-55 does not distinguish the two classes, though a prior
  addresses only one of them.
  *Fix:* correct to "three octave and one triplet," and state which of the four F1 is
  expected to move.

- **medium** *FR-70's calibration floor has no number* (§5.6) — "a confidence-calibration
  floor … here it is a precondition." FR-18's `ECE_half_double < 0.10` exists and was
  never evaluated (`epics.md:268`).
  *Fix:* import the number or state a new one.

- **medium** *Gate 0's trigger is undefined* (§6) — "scores near 52" decides whether the
  entire epic collapses to a measurement fix.
  *Fix:* state a band (e.g. within ±5 Acc1 points of 52.6 on the same annotation version).

---

## 5. Scope honesty — **thin**

This dimension is bimodal. Where the PRD is honest, it is unusually so: §4.2 names two
of its own measured failures and keeps them; FR-69 prints its retracted text; FR-72a
lists three gaps its own decision leaves open; §11 records that a PDF summarizer
fabricated a citation during Discovery; AS-6 is stamped REFUTED and AS-5 is amended with
two qualifications rather than declared confirmed. That is real.

Where it is not honest is at the two places that determine how big this epic is: the
corpus programme and the classifier. Both entered late (the F3 restructure on 2026-07-28,
Q5 on 2026-07-28), and neither triggered a re-costing of the MVP. §8.1's one-line
rationale is the only place the PRD assesses effort, and it is wrong on both counts.

Building a band-balanced, independently-labelled, contamination-audited, single-convention
evaluation corpus of ~162 tracks, *plus* restructuring a ~1,500-track training corpus to
share that convention and partition, is plausibly the largest single work item in the
epic — larger than a retrain. The PRD never says so. It calls it "measurement
integrity," which is what it *achieves*, not what it *costs*. There is no effort
estimate, no abort condition, no staged deliverable, and no statement of who does the
manual annotation FR-59a.1 requires.

### Findings

- **high** *§14 under-reports what is open by roughly 5x* (§14) — the section opens "Q1
  through Q7 are resolved and struck through below … Two items remain live." Counting
  what the document itself calls unresolved: Q8, Q9, Q1's own trailing "**Two caveats
  raised by the Q2 consult and not yet resolved**," FR-69c items 1-5 ("must be settled
  before the gate is trusted"), FR-72a items 1-3, and FR-59b's convention (which Q9
  blocks). That is ~11 live items presented as 2. FR-69c in particular is a list of
  open questions filed under a requirement number, where a reader scanning §14 will not
  find them.
  *Fix:* promote FR-69c's five items and FR-72a's three to §14 as Q10-Q17 (or
  cross-reference them in §14's preamble), and stop describing Q1 as resolved while its
  own text says otherwise.

- **high** *F3 has no stopping rule, no estimate, and no abort condition, yet it gates
  everything downstream* (§5.3, §6, §8.1) — §6's stopping rule counts only *ML levers*
  (F4, then FR-58's top-ranked cause). F3 is not a lever and cannot fail into a stop.
  But FR-59 "blocks the bundle gate," and Gates 1 and 2 are both defined as "produces no
  ensemble lift" — a measurement that requires the FR-59 corpus, which requires FR-59b's
  convention, which Q9 blocks. So the epic can consume its entire budget on F3 without
  either stopping gate becoming *evaluable*. The stated motivation for §6 is that "Epic 7
  ran three retrains past the point its own signal said stop"; the structural analogue
  here is running a corpus programme past the point its own signal says stop, and §6 does
  not cover it.
  *Fix:* add a Gate on F3 — e.g. "if the 100-120 band cannot reach n=27 at acceptable
  label quality within N weeks, accept a smaller uniform n or declare the band
  unmeasurable and proceed" — and state F3's effort estimate in §8.1.

- **medium** *FR-59a.2's contamination boundary collides with FR-59's sourcing* (§5.3) —
  FR-59 draws the evaluation corpus from "OA300, Tony's Rekordbox collection, and the
  Story 7.2 non-Rekordbox pool," while FR-59a.2 forbids any track, remix, **or artist**
  appearing in both the evaluation corpus and any training set. Tony's Rekordbox
  collection *is* the training set (`corpus_splits.json`: tony/train 959, val 108,
  leaveArtistOut heldOut 139). Artist-level exclusion in a single-DJ, DnB-dominant
  collection could remove a large fraction of training material; the split already
  holds 27 held-out artists and 225 empty-artist track IDs. The PRD does not quantify
  the cost or say which side wins when they conflict.
  *Fix:* state the precedence rule and estimate how many training tracks artist-level
  exclusion removes.

- **medium** *The feasibility "RESOLVED" is conditional on a decision not yet made*
  (§5.3, Feasibility block) — the source analysis bands its availability table **by the
  tag**, i.e. under the half-tempo convention. The PRD reproduces the table without that
  qualifier, two paragraphs above stating (finding 2) that "the pool's band distribution
  is a property of the convention, not of the music." Under the DSP (full-tempo)
  banding the same files distribute completely differently (source doc: `<100` 1,996 by
  tag vs 122 by DSP; `160-175` 102 by tag vs 3,094 by DSP). Since FR-59b's convention is
  undecided and Q9-blocked, "Feasibility: RESOLVED 2026-07-29" overstates: what is
  resolved is feasibility *under one of the two candidate conventions*. Separately, the
  PRD's sentence "78% sub-100 by tag, by DSP 65% at 160-175, describing identical files"
  is not accurate — those percentages have different denominators (2,568 tagged vs 4,753
  DSP-estimated), an inconsistency inherited from the source document, which says both
  "the same 2,568 tagged tracks" and "(all 4,753)" about the same table.
  *Fix:* label the feasibility table "banded by tag (half-tempo convention)" and add the
  full-tempo counterpart, or downgrade the resolution to "conditionally resolved pending
  FR-59b." Fix the denominator claim in both documents.

- **medium** *§13's risk table is missing the risks this epic actually added* (§13) —
  no row for classifier router error / second model in the deployment path (the cost Q5
  explicitly accepted), none for corpus-build schedule or infeasibility, none for the
  ensemble-default flip, none for demo-archive size growth (AS-8 covers App Store review
  but not binary size, and the operator's "small model" constraint is a size constraint).
  *Fix:* add four rows.

- **medium** *No corpus signoff gate for the new corpus* (§5.3) — `train.py` fails
  closed without a signed KDD-B4 corpus signoff (`Makefile`: "Requires the KDD-B4 signoff
  signed (train.py's gate fails closed otherwise)"), and the charter's own open scoping
  questions asked "new corpus signoff on par with KDD-B4 against the new
  representation?" (`epics.md:1870`). The PRD builds two new corpora and never mentions
  a signoff. The first training run after F3 will be blocked by an existing gate the PRD
  does not acknowledge.
  *Fix:* add an FR for the new-corpus signoff, or state that the KDD-B4 signoff transfers.

---

## 6. Downstream usability — **adequate**

This PRD is chain-top: it feeds story creation directly, so traceability matters. ID
hygiene is clean — FR-53 through FR-74 plus FR-59a-e, FR-62a, FR-69a-c and FR-72a are
contiguous with no gaps or duplicates; Q1-Q9 and AS-1 through AS-8 likewise. Sections
mostly stand alone. Existing-code references are accurate: I verified
`reference_arch.py:37-39` (exactly the three bin constants), `dataset.py:59-62`,
`BNNSTechnique.swift:191` (`expectedBinCount = 256`) and `:1071` (the throw),
`ModelRegistry.swift` (`register(...)` + `SHA256`, no `URLSession`), FR-53's "four
bounds are `private static let`" (`minBPM 40`, `maxBPM 250`, `perceptualMinBPM 60.0`,
`perceptualMaxBPM 200.0`), FR-64's `octave_partner_bins` out-of-range drop behaviour
(`ablation/tests/test_octave_loss.py` asserts `octave_partner_bins(140) == [55]`), the
0.15 default (`train.py:374`), and FR-65's premise that `model_metadata.json` records
no loss configuration. FR-66's arithmetic is right (30 low bins + 85 high = 115 of 256;
bin 30 = 60 BPM, bin 170 = 200 BPM). That is a high hit rate and reflects the
"factual-claims grep before story spec" discipline.

What degrades downstream usability is the layering: FR-59 through FR-59e, FR-62/62a and
FR-69 through FR-69c were amended in place across three sittings, and the PRD now
contains struck text that is still pointed at, superseded descriptions that other
sections still cite, and one contradiction between §4 and §15.

### Findings

- **high** *§4.4 and AS-5 contradict each other, and both are cited elsewhere* (§4.4,
  §5.3 FR-59, §13, §15) — §4.4 still reads "**UNTESTED inference.** … FR-59 tests this."
  AS-5 reads "**LARGELY CONFIRMED 2026-07-29 on independent evidence**." And FR-59, as
  rewritten, contains no confirm-or-refute step at all — it is now a corpus-construction
  requirement. §13's risk row still says "FR-59 and FR-62 test and record the
  convention," though FR-62 is "subsumed into FR-59b." A story author reading §4.4 will
  scope a hypothesis test that no FR asks for.
  *Fix:* restate §4.4 as CONFIRMED with AS-5's two qualifications, point it at FR-59b,
  and update §13's row.

- **medium** *Struck text is referenced as live, and content was lost in the strike*
  (§14 Q4, §5.3 FR-62a) — Q4's resolution ends "**See FR-62a for what re-labelling
  costs.**" FR-62a's text is struck through and replaced; the replacement states the
  decision (leave OA300 intact) but not the costs. The costs recorded in `.memlog.md`
  entry 31 — that re-labelling "invalidates historical figures on old labels, is
  irreversible once artifacts regenerate, and forces re-measurement of any run that
  trained on affected tracks" — now appear nowhere in the PRD. Only the first survives,
  partially, folded into FR-60. Separately, Q4 records an **operator decision** to
  re-label OA300, and FR-62a reverses it ("Superseded 2026-07-28 by FR-59b"); the
  reversal carries no operator attribution while the decision it overturns does.
  *Fix:* restore the three costs into FR-60 or FR-59b; attribute the FR-62a reversal, or
  re-open Q4 for confirmation.

- **medium** *Superseded descriptions are still cited* (§11, §13) — §11 says "the
  stratified split (FR-59) is for octave testing, not training," which is FR-59's
  pre-2026-07-28 shape (FR-59 itself says it "Supersedes the former 'band-stratified
  held-out octave test set from OA300'"). §13's row "The 100-120 band is unreachable |
  Acknowledged … sourcing is open (Q3)" cites Q3 as open; Q3 is resolved and struck.
  *Fix:* update both.

- **medium** *Band boundaries are never defined and are not in the Glossary* (§3, §4.4,
  §5.3, §5.6) — six bands (`<100`, `100-120`, `120-140`, `140-160`, `160-175`, `175+`)
  carry FR-59's balance target, FR-59c's power analysis, FR-68's no-regression gate and
  FR-71's reporting. No inclusivity rule is stated; `160-175` and `175+` are ambiguous at
  175. A downstream implementation will pick a convention and it may not match the one
  the tables were computed under.
  *Fix:* add "Band" to the Glossary with explicit half-open intervals.

- **medium** *Track-count figures do not reconcile* (§5.3, §5.4, §14 Q8) — Q8 cites "a
  1,534-track training set." §5.3's Tony column sums to 1,509. `corpus_splits.json`
  gives tony/train 959 + val 108 + leaveArtistOut/heldOutTrackIds 139 = 1,206. FR-59d's
  "595-1509 tracks already in use" spans GiantSteps-train (595, verified) and Tony
  (1,509) without saying so.
  *Fix:* pick one denominator, state its source, use it everywhere.

- **low** *"E0" is undefined* (§4.1) — used as a bare identifier for the band analysis;
  the corpus (GiantSteps) is identifiable only by matching n=60 and n=35 against §5.3's
  table.
  *Fix:* one-line expansion at first use, or a Glossary entry.

- **low** *No inline `[ASSUMPTION:]`, `[NOTE FOR PM]`, or `[NON-GOAL for MVP]` callouts*
  — the Assumptions Index in §15 has no inline anchors to round-trip against, so AS-1,
  AS-2, AS-4 and AS-8 appear only in the index and cannot be located at the point where
  they bite. The MEASURED/PUBLISHED/UNTESTED scheme in §4 is a better substitute for the
  evidence base than the template's tags, but it stops at §4 and does not cover §5's
  requirement-level inferences.
  *Fix:* anchor AS-1/2/4/8 inline where they are load-bearing.

- **low** *Glossary gaps* (§3) — missing: band, discordance, metrical convention,
  sentinel, "Tony's split," "the pool," KDD, E0. Eight terms present; the eight most
  contested nouns in F3 are not among them.

---

## 7. Shape fit — **strong**

Correctly shaped. This is a single-operator brownfield capability spec for an R&D epic,
and the PRD behaves like one: §2 supplies three jobs-to-be-done rather than personas,
there are no user journeys (correctly — UJ density here would be pure overhead), success
metrics are operational rather than user-facing, and the load-bearing sections are the
evidence base, the gate, and the stopping rule. The addendum is used exactly as it
should be: depth that belongs to architecture or a downstream story (distribution
options, on-device inference surface, literature reference points) is pulled out of the
narrative and kept.

Brownfield discipline is met — existing-code references are accurate (see Downstream
usability), and the PRD distinguishes what exists (`ModelRegistry`, the BYOW seam, the
abstain path) from what is new.

The only shape observation: §6's stopping rule is the section that most justifies the
"launch-grade" framing, and it is three short paragraphs against 100+ lines of gate
mechanics. The imbalance is discussed below.

---

## Additional assessment 1 — Is every quantitative claim traceable?

**Mostly yes, and better than expected.** I recomputed or grepped every number I could.

**Verified correct:**

- All FR-69 McNemar values, exactly. `d=2` split 2:0 → p=0.500. Smallest significant
  result 6:0 → p=0.03125. Table rows: (8, 8:0, 0.0078), (16, 13:3, 0.0213), (25, 18:7,
  0.0433), (66, 42:24, 0.0356), (132, 78:54, 0.0449) — all correct, and in every case
  the next-smaller `t` genuinely fails at α=0.05. FR-69a's "~8 on OA300 and ~20 on
  GiantSteps" at α=0.025 is correct. FR-59's "10 tracks (6.2%)" at n=162, d=16 is
  correct, as is "8 (9.8%)" at n=82, d=8. FR-59c's "cannot reach p<=0.05 at 10% or 20%"
  is correct (d=3 and d=5 are both unreachable).
- §5.3's band table: every row and both derived columns sum correctly. GiantSteps sums
  to 661, OA300 to 82.
- §4.2's octave-fold figures: 38+346+220 = 604; 38−346 = −308.
- §4.1's 348/661 = 52.6%. §1's "~35 points" (87.0−52.6) and "~30 points" (82.1−52.6).
- FR-66's "115 of 256" and the implied 30→285 BPM bin schema.
- FR-64's "above ~142 BPM the full mass lands on the half, below ~60 on the double"
  (2T > 285 ⟺ T > 142.5; T/2 < 30 ⟺ T < 60).
- FR-69's "2.4pp" for 2/82.
- The feasibility figures (71% = 1,822/2,568; 78% = 1,996/2,568; 65% = 3,094/4,753;
  1,529; 262 vs 28) all trace to `non-rekordbox-band-feasibility-2026-07-29.md`, which
  is cited by path and includes a reproduction script.

**Not traceable — findings:**

- **medium** *Q8's "1,534-track training set"* (§14) — matches no artifact I can find
  (see the reconciliation finding above).
- **medium** *FR-59d's "595-1509 tracks already in use"* (§5.3) — unsourced as a range;
  the endpoints belong to two different corpora.
- **medium** *"about thirty-five points higher" / "roughly ten times smaller"* (§1) —
  traceable, but only through AS-3, which the Vision does not flag (see finding above).
- **medium** *The AccuracyFloorTests count and composition* (§5.1) — the count is right,
  the composition is wrong (three octave + one triplet).
- **low** *FR-69a's "~9.75%"* (§5.6) — recomputed: `1 − 0.95² = 0.0975` assumes each
  null corpus has a 5% false-positive rate. FR-68 requires the ensemble to *beat* DSP,
  so the claim is directional and the per-corpus rate is 2.5%, giving `1 − 0.975² =
  4.94%`. The stated figure overstates the inflation by about 2x. It is hedged with "up
  to" and errs conservative, so the remedy (partial conjunction at `p2 <= 0.025`) stands
  either way — and I confirmed that rule is the correct Bonferroni partial-conjunction
  form for u=2 of n=3, valid without independence.
  *Fix:* state ~4.9% for the directional case, or say explicitly that 9.75% is the
  non-directional bound.
- **low** *§4.3's "20% DnB" for GiantSteps* — from the SMC 2015 paper, not from our
  measurement; §5.3's table shows 153/661 = 23% at 160-175, which is not the same thing
  as DnB share. No conflict, but the two figures sit close enough to be conflated.

**Structural note.** The PRD's MEASURED / PUBLISHED / UNTESTED tagging in §4 is the
single best traceability device in the document and I would not change it. Its weakness
is that it stops at §4: the figures in §5.3's feasibility block, §5.6's McNemar table
and §9 carry no such tag, and several of them (the feasibility availability counts, the
discordance `d` values) are *projections* rather than measurements. FR-69 says so once
("Planning values"); the feasibility table does not.

- **medium** *The feasibility availability table carries no evidence tag* (§5.3) — it
  reads as MEASURED. It is measured availability under an unadopted convention and a
  selection rule FR-59a.1 forbids, which makes it closer to a projection.
  *Fix:* tag it, as §4 tags everything else.

---

## Additional assessment 2 — Internal consistency of the amended FRs

The three amended clusters were checked pairwise. Findings are stated above; this is
the map.

**FR-59 → FR-59e.** Two real contradictions and one unresolved dependency:
- FR-59a.1 (labels independent of DSP) vs the feasibility selection rule (DSP agreement
  required). **CRITICAL, above.**
- FR-59a.2 (no artist in both eval and any training set) vs FR-59 (draw the eval corpus
  from Tony's Rekordbox collection = the training set). **MEDIUM, above.**
- FR-59b's convention is "the load-bearing decision of F3" and is blocked by Q9, while
  FR-59, FR-59d and FR-59e all presuppose it is made. FR-59e ("training and evaluation
  share the convention from FR-59b") is coherent but inert until FR-59b resolves.
- FR-59c and FR-71 are consistent with each other and correctly reasoned; FR-59c's
  discordance floor is stated at the wrong α (see FR-69 critical).
- FR-59d correctly refuses to inherit the scarcest-band rule and says why. This is one of
  the strongest amendments in the document — it names an operator over-application
  ("balance evaluation and training together"), rejects half of it, and gives the
  measured reason. No consistency problem.

**FR-62 / FR-62a.** FR-62 is "subsumed into FR-59b … retained for auditing the legacy
corpora." FR-62a is struck and superseded. Two problems, both above: §13 still cites
FR-62 as testing the convention, and Q4 points at FR-62a for costs that were deleted with
the struck text. The struck FR-62a text is not otherwise referenced as live.

**FR-68 / FR-69 / FR-69a / FR-69b / FR-69c.** The most-layered cluster and the one with
the most residue:
- FR-69's table (α=0.05) vs FR-69a's rule (α=0.025). **CRITICAL, above.**
- FR-69's heading "State the margin in tracks, not percentages" is now vestigial: the
  body concedes the track thresholds depend on an unmeasured `d`, and FR-69a's operative
  rule is a p-value rule with no fixed track count. FR-68's "a stated margin" therefore
  has no referent. **MEDIUM.**
- FR-69b is internally clean and correct (seeds are correlated; freeze the shipped
  artifact and test it once). It is also the only FR in the cluster that names a concrete
  procedure. No conflict.
- FR-69c items 1-5 are open questions inside a requirement, three of which (1, 2, 4)
  undermine FR-68's 2-of-3 rule and one of which (3) undermines every nominal p-value in
  FR-69. FR-68 is written as though they were settled. **Reflected in the Q1/§14
  finding.** Item 1 in particular is not merely a caveat: §5.3 already *excludes*
  GiantSteps from its pooled count for this exact reason, while §5.6 retains it as a gate
  arm — the PRD acts on the contamination concern in one section and not in the other.
- FR-71 was amended to "Descriptive, not inferential" consistently with FR-59c. Clean.

**FR-72a.** Consistent with Q7 and self-aware about its three gaps. Its factual claim
that `MODEL_CARD.md` "now lives at `_bmad-output/ml-models/MODEL_CARD.md`, which never
ships to `main`" is correct on disk (that is the only copy). Note for the maintainer,
outside this PRD's scope: `CLAUDE.md`'s SHIPS_TO_MAIN allowlist still lists
`MODEL_CARD.md` at repo root, so `scripts/promote-to-main.py` and the drift test may
disagree with reality.

**Struck text referenced as live: one instance** (Q4 → FR-62a), plus two superseded-shape
references (§11 → FR-59's old form, §13 → Q3 as open) and one contradiction between a
live section and the index (§4.4 vs AS-5).

---

## Additional assessment 3 — Is the stopping rule real?

**Structurally yes; operationally not yet, and it does not cover the work the MVP
actually consists of.**

What is real about it: it is outcome-based rather than budget-based, it fires at two
failures rather than three (with the Epic 7 rationale stated), Gate 0 can terminate the
epic before any lever runs, and the override clause is explicit and written down rather
than implied. A PRD that says "the epic stops and the premise is re-examined —
including that a bundleable model may not be reachable with this corpus, and that the
effort belongs on the DSP path" is not encoding an assumption of success. That sentence
is the strongest thing in §6.

Four ways it does not bind:

1. **It does not cover the MVP.** The MVP is F1 + F2 + F3 + the gate definition. Only F2
   has a gate (Gate 0). Gate 1 is on F4 and Gate 2 is on FR-58's top-ranked cause — both
   explicitly **out of MVP scope** (§8.2). So the entire funded scope of this epic can
   execute to completion without any stopping gate being reachable. F3 in particular —
   the largest item — has no abort condition. **This is the central weakness.**

2. **A lever has no size.** "Failed lever one" is F4, which is FR-63 + FR-64 + FR-65.
   FR-63 alone ships "a smearing-versus-one-hot ablation and a sigma sweep." A sigma
   sweep is many training runs. So "two failed levers" bounds the number of *ideas*, not
   the number of *retrains* — and Epic 7's failure mode was three retrains, i.e. an
   unbounded count of attempts inside a bounded count of ideas. §11 reinforces this by
   permitting cloud training with no budget ("whatever it takes," per the memlog). A
   stopping rule written to prevent Epic 7's failure does not, as written, prevent it.

3. **The gates are not evaluable until a blocked chain resolves.** Both Gate 1 and Gate 2
   are defined as "produces no ensemble lift." Lift is measured by FR-68, which is
   blocked on FR-59's corpus, which is blocked on FR-59b's convention, which Q9 says
   should not be decided yet. So neither gate can fire before F3 completes, and F3 has no
   gate of its own. That is the loop.

4. **Gate 2's fallback is already in scope.** "The effort belongs on the DSP path" — F1
   *is* the DSP path and is in MVP. If F1 succeeds and both ML levers fail, the epic
   ends having done exactly what Gate 2 recommends, which is a good outcome but makes
   Gate 2's stated consequence non-informative.

Does the feature set encode an assumption of success? Mostly no. FR-73 ("the library
keeps its BYOW seam unchanged … no behavioural change for existing consumers") and §10's
byte-identity NFR mean a total failure costs nothing structurally. AS-4 names
non-achievability and points at Gate 2. F7 is explicitly out of MVP "until there is a
model worth shipping." That is honest design.

But two places do assume it. §8.1's rationale — "together they determine whether the rest
is worth funding" — is only true if F3 completes, which is assumed rather than gated.
And FR-59's framing of the balanced corpus as strengthening the gate ("Balancing
strengthens the aggregate gate") presumes the corpus gets built.

- **high** *Add a Gate on F3 and a per-lever attempt budget* (§6) — see the Scope-honesty
  finding. Concretely: (a) a feasibility abort for FR-59 (if 100-120 cannot reach n at
  acceptable label quality by a stated date, drop to a smaller uniform n or declare the
  band unmeasurable); (b) a stated maximum number of training runs per lever, so "two
  failed levers" cannot expand to eight retrains.

- **medium** *"Balancing strengthens the aggregate gate" attributes to balancing an
  effect of sample size* (§5.3 FR-59) — the comparison is 162 tracks needing 6.2% vs 82
  needing 9.8%. Any 162-track corpus needs the same 10 tracks; balance contributes
  nothing to that arithmetic, `n` does. Worse, the omitted consequence runs the other
  way: balancing shifts the corpus toward the bands DSP handles *worst* (away from
  160-175, which is 41 of OA300's 82), so DSP's baseline Acc1 on the balanced corpus will
  be materially lower than 70.7% and is neither predicted nor measured — while FR-68's
  gate is defined relative to it. The paragraph is labelled "measured not assumed," which
  is true of the arithmetic and not of the attribution.
  *Fix:* restate as "doubling n strengthens the aggregate gate; balancing changes which
  bands the aggregate reflects." Predict or measure DSP's baseline on the balanced corpus
  before FR-68 is finalized.

---

## Additional assessment 4 — Scope honesty on the corpus work

**The MVP scope does not match what the features require, and the mismatch is
concentrated in exactly the place the question anticipates.**

§8.1 is the PRD's only statement of effort, and it is one clause: *"none needs a
retrain, all are cheap relative to training."* Against the actual content of the MVP:

| MVP item | What §8.1 implies | What it requires |
|---|---|---|
| F1 | no retrain, cheap | a **genre classifier** — corpus, labels, taxonomy, training, evaluation, abstain threshold, size/latency budget. None specified. |
| F2 | no retrain, cheap | reproducing a published TempoCNN end-to-end on our evaluation path. Not a retrain of ours, but it is a full training-and-evaluation programme. |
| F3 | no retrain, cheap | **two purpose-built corpora**: ~162 tracks band-balanced with DSP-independent labels, a declared metrical convention applied track-by-track, artist-level contamination audit against a ~1,200-track training split; plus a restructured training corpus sharing both. |
| F6 | definition work | correct, and genuinely cheap. |

F3 alone is, by any reasonable reading, larger than a retrain. FR-59a.1 requires labels
"established independently of our DSP" for ~162 tracks; the only sources available are
file tags (which the feasibility analysis shows are 71% at half tempo and therefore
require a convention decision before they mean anything) and human annotation. The PRD
does not say which, does not name an annotator, does not estimate the time, and does not
stage the deliverable. FR-59b then requires *every* track relabelled to a single declared
convention — which for a half-tempo-tagged collection means the tags cannot simply be
adopted.

The PRD is aware of the corpus's importance — F3's preamble is a good piece of writing
about why the restructure happened, and it names the four §14 questions the band count
generated. What it never does is say the sentence "this is the largest work item in the
epic." It describes F3 as "measurement integrity," which is its *purpose*, and files it
in a scope block whose rationale is that everything in it is cheap.

The classifier is the sharper omission because it is not merely under-costed but
undocumented: Q5 introduces it, FR-54 acknowledges the dependency in one sentence, and
then it vanishes. There is no FR to build it, no gate on it, and no risk row. A second
model in the deployment path is also in direct tension with the operator's "small model"
constraint (recorded in the memlog as an explicit constraint) and with §7's "Bigger
models" Non-Goal, neither of which is reconciled.

Both are covered by the criticals above. The framing finding:

- **high** *§8.1's rationale is the PRD's only effort statement and it is wrong for two
  of the four MVP items* (§8.1) — "none needs a retrain, all are cheap relative to
  training" is false of F1 (classifier) and materially misleading about F3 (two corpora).
  A reader deciding whether to green-light the MVP is being told it is the cheap part.
  *Fix:* replace with a per-feature effort statement. Name F3 as the largest item. State
  the classifier as a distinct sub-programme or de-scope it.

---

## Mechanical notes

- **ID continuity — clean.** FR-53…FR-74 contiguous; suffixed FRs (59a-e, 62a, 69a-c,
  72a) unique and correctly positioned. Q1-Q9 contiguous. AS-1…AS-8 contiguous.
- **Cross-references — three broken/stale.** §11 → FR-59's superseded shape; §13 → Q3 as
  open; §13 → FR-62 as testing the convention. Plus §14 Q4 → struck FR-62a text.
- **Assumptions Index roundtrip — partial.** AS-3, AS-5, AS-6 and AS-7 appear inline (by
  name or in substance). AS-1, AS-2, AS-4 and AS-8 appear only in §15. No `[ASSUMPTION:]`
  tags anywhere, so there is nothing to grep.
- **Glossary drift — one real case.** "Band" is undefined and its boundaries are
  ambiguous at 175. "Metrical level" is glossed; "metrical convention" (the FR-59b term)
  is not, and the two are used near-interchangeably in §5.3.
- **UJ protagonists — N/A.** No UJs, correctly.
- **Required sections — all present** for a capability-spec-shaped brownfield PRD:
  Vision, Target User, Glossary, Evidence Base, Features, Gates, Non-Goals, MVP Scope,
  Success Metrics, NFRs, Constraints, Risks, Open Questions, Assumptions Index. The
  Evidence Base and Decision Gates sections are additions to the template and both earn
  their place.
- **Addendum** — correctly scoped, no duplication with the PRD, and §A's independent
  reproduction of the AST failure is properly caveated ("Caveats before blaming AST
  itself"). §B and §C are architecture material and belong there. §D's method warning
  duplicates §11's, which is fine — it is the one thing worth repeating.
- **Cross-artifact drift (outside this PRD):** `CLAUDE.md`'s SHIPS_TO_MAIN table lists
  `MODEL_CARD.md` at repo root; the only copy on disk is
  `_bmad-output/ml-models/MODEL_CARD.md`. FR-72a's statement is correct and the
  allowlist appears stale. Worth a separate issue.

---

## Finding count

| Severity | Count |
|---|---|
| critical | 5 |
| high | 8 |
| medium | 16 |
| low | 6 |
| **total** | **35** |

**Recommended action:** close the five criticals and H1 (ensemble-policy default) before
any Story 12.x touches F1, F3 or F6. F2 can start against the PRD as it stands, with
FR-56 and Gate 0 given completion criteria first.
