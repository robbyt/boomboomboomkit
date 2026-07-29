# Input reconciliation — `octave-bias-finding-and-plan.md` vs the Epic 12 PRD

Reconciled 2026-07-29.

**Input:** `_bmad-output/ml-training/v2-runs/octave-bias-finding-and-plan.md` (164 lines).
**Targets:** `prd.md` (366 lines), `addendum.md` (80 lines), same directory.

The input document declares its own residual purpose at line 130: *"The corrected
ranking lives in the Epic 12 charter (`epics.md`); this document is retained as
**the E0 diagnostic record**, which stands unchanged."* That is the standard this
reconciliation applies. The lever ordering is legitimately superseded twice
(doc → charter → PRD, per `prd.md:14`); the **diagnostic** is not superseded by
anything and should have survived intact. It largely did not.

---

## 1. Measured findings the PRD did not carry forward

### 1.1 The E0 table survives as corpus counts, not as a diagnostic

This is the single largest gap. The plan doc's E0 table (`:25-33`) carries six
bands × four measured quantities. The PRD reproduces **two of six rows**
(`prd.md:60`):

> **MEASURED.** E0 bands: `<100` is clean octave-doubling (n=60, Acc1 1/60, Acc2 39/60, 38 predicting exactly 2×). `100-120` is genuinely mis-pulsed (n=35, Acc1 = Acc2 = 1/35 — no octave rule reaches it).

The other four rows are dropped as performance data:

| Band | plan doc `:29-32` | in PRD? |
|---|---|---|
| 120-140 | n=309, Acc1 177 (57%), Acc2 180 (58%) | Acc1 177 survives only as a ladder endpoint at `prd.md:234`; Acc2 absent |
| 140-160 | n=88, Acc1 40 (45%), Acc2 47 (53%), *"a few octave errors"* | **absent** |
| 160-175 | n=153, Acc1 129 (84%), Acc2 133 (87%), *"strong"* | **absent** |
| 175+ | n=16, Acc1 **0/16 (0%)**, Acc2 1/16 (6%) | **absent** |
| TOTAL | Acc1 348 (53%), **Acc2 401 (61%)** | Acc1 carried (`:59`); Acc2 absent |

What makes this more than a tidiness complaint: **the PRD reuses the exact same
six band buckets and the exact same GiantSteps n-values** in its corpus-composition
table at `prd.md:124-131` (60 / 35 / 309 / 88 / 153 / 16). So the band *counts*
were transcribed and the band *accuracies* were not. The reader gets the
denominator and loses the numerator.

The consequence is operational, not cosmetic. Two requirements demand a per-band
baseline the PRD does not contain:

- **FR-68** (`prd.md:200`) requires "**no regression** in any band DSP already handles."
- **FR-71** (`prd.md:234`) requires per-band lift reporting.

Neither can be evaluated without knowing that the model currently sits at 84% in
160-175 and **0/16 in 175+**. The 175+ omission is the sharpest: `prd.md:131`
flags 175+ as one of two scarce bands to be sourced under FR-59a, and
`prd.md:173` budgets 106 available tracks for it — while never recording that the
model scores **zero** there. A band with 0/16 measured accuracy and no PRD
mention is a band nobody will notice regressing, because there is nothing left
to regress to.

Likewise 160-175: the PRD's corpus argument (`prd.md:133`, "160-175 holds 980
tracks while the two bands the model actually fails on hold 62 and 52") is
correct but under-evidenced. The reason 160-175 is not a "band the model fails
on" is E0's 129/153 (84%) — which the PRD asserts implicitly and never states.

### 1.2 The Acc2 = 401 residual decomposition

Plan doc `:51-59` decomposes the deficit precisely:

> Perfect octave decode caps at **Acc2 = 401/661 (61%)** … The gate is 537 (81%). So **+136 beyond octave-perfect is genuine error** that decode cannot touch. That residual is the representation/training problem.

The PRD never states 401 and never states +136 (`grep -c 401 prd.md` → 0). It
carries a qualitative paraphrase at `prd.md:198`: *"which is why a model that
fixed the sub-100 band would still have failed."* That sentence is true but
carries none of the arithmetic.

This matters because the PRD's headline lever is an octave lever. `prd.md:22`:
*"style-conditioned tempo priors lifted drum-and-bass Acc1 from 7.2% to 78.4%."*
E0's decomposition is the project's own measured statement of **how much of its
deficit is octave-shaped at all** — 53 tracks recoverable by perfect octave
handling versus 136 that are not. Whether that bounds F1 is arguable (the SMC
2015 result is broader than octave correction, lifting overall 45.5% → 75.0%,
`prd.md:77`), but the bound is exactly the kind of thing a stopping rule (§6)
should be sized against, and it is absent from the evidence base.

*Caveat honoured correctly elsewhere:* 401 is an **oracle** ceiling and the PRD
is right not to present it as headroom — see §2 below. The recommendation is to
carry it **with** its retraction, not to carry it bare.

### 1.3 The band-trade mechanism, and its numbers

Plan doc `:19-20`:

> Adding hand-labels improves the FED band (120-140: 113->145->177) but regresses neighbors (140-160 -16) and drags OA300 BELOW baseline. Fixed-capacity band trade.

The PRD carries the *shape* twice — `prd.md:234` ("The +190 retrain gained
120-140 and lost 140-160") and `prd.md:152` ("the three retrains already
demonstrated a fixed-capacity band trade") — but never the numbers 113 → 145 →
177 or −16.

This becomes a substantive problem at **FR-59d** (`prd.md:152`):

> Correct the distribution with oversampling or loss weighting, which costs no data.

The calibration ladder's two non-baseline columns are labelled `+90 rebal` and
`+190 rebal` (plan doc `:14`). Cross-checked against
`_bmad-output/ml-training/corpus-diagnostics-v1.md:13`, those are band-targeted
hand-label augmentations — *"100 net-new tracks over the prior +90 batch,
**120-140-weighted**"* — and `train.py` carries a `--rebalance` flag
(`train.py:375,425`) wired through `make ml-train-v2`. So **band-distribution
correction is not an untried idea; it is the project's two most recent measured
attempts, and both moved OA300 the wrong way** (50 → 48 → 43). FR-59d proposes
that lever without citing the measurement against it. The PRD uses the ladder
only in the opposite direction, as an argument against *truncating* training
data.

This is a case where the PRD is not merely under-cited but arguably tilted: it
deploys the ladder evidence for the claim it supports and omits it for the claim
it undercuts.

### 1.4 Root-cause consensus: the representation hypothesis is entirely absent

Plan doc `:62-69` is the longest single analytical passage in the document — the
`[1,1,128,512]` fixed-input hypothesis, plus the Codex correction that the naive
frame-rate reading is backwards (at ~5.7 fps a 60-BPM track gets ~5.7
frames/beat and a 174-BPM track ~2, so *fast* tempo sits nearer temporal
Nyquist), and the corrected mechanism: **the model learns the DnB-dominant
metrical level as a prior, because the representation is sharp where the corpus
lives.**

Searched across both targets: `512` → 0 hits. `tempogram` → 0. `autocorrelation`
→ 0. `frame-rate` / `frame rate` → 0. `resampl` → 1 hit in `prd.md`, at line 232,
where it means *statistical* resampling for McNemar clustering, not the input
resample.

So neither the hypothesis, nor its correction, nor the corrected mechanism
appears anywhere in the PRD. **FR-57** (`prd.md:117`) asks for a differential
across "input representation and window policy" — but hands the analyst a blank
axis. The concrete, already-reasoned suspect and the already-identified
reasoning trap are both gone. The predictable failure mode is that FR-57
re-derives the backwards frame-rate argument that this document already
corrected.

Note also that the corrected mechanism — corpus-prior leakage — is the same
mechanism the PRD independently rediscovers on the corpus side at `prd.md:133`
("Every corpus is drawn from the same musical world, so pooling deepens the skew").
The two are the same finding seen from the model side and the data side, and the
PRD only has one of them.

### 1.5 Smaller drops

- **The OA300 gate threshold.** Plan doc `:16` records `>55/82` for OA300. The
  PRD carries only the GiantSteps 537 figure (`prd.md:198,297`). Minor, but FR-18
  is described as failing "both gates" (`prd.md:59`) without ever naming one of them.
- **Ladder percentages.** Plan doc `:16-17` gives 61.0% / 58.5% / 52.4% and
  44.8% / 49.9% / 52.6%; `prd.md:59` compresses to bare counts. Acceptable
  compression.
- **The ordinal-structure diagnosis.** Plan doc `:98-99`: *"What IS unambiguously
  absent is ordinal structure: a 1-bin miss and a 100-bin miss are penalized
  identically."* This is the project's own structural diagnosis of its loss.
  FR-63 (`prd.md:187`) proposes ordinal targets justified purely by external
  literature (DLDL, Imani & White) and never cites the internal finding that
  ordinal structure is precisely what is missing. The external evidence is
  stronger, so this is a lost corroboration rather than a lost claim.
- **MoE deployment cost.** Plan doc `:100-104` itemises why genre-MoE is ranked
  last: router-error surface, N BNNSGraph loads, re-bundling weights (reverses
  Story 4-6 Branch C), likely a CoreML/ANE migration off the CPU-only BNNS path.
  `prd.md:350` references "the exact cost the 2026-06-09 roundtable cited when
  ranking genre-MoE last" but does not itemise it — and the reference appears
  inside a struck-through resolved question, which is where it is least likely to
  be read.

**One thing verified as correctly carried, contra suspicion:** `prd.md:30`
attributes "calls a 70 BPM track 140" to *the DSP path*, whereas the plan doc
uses the same phrase for the ML decode (`:136`). Checked
`Tests/BoomBoomBoomKitTests/AccuracyFloorTests.swift:118` — there is a genuine
DSP-path `knownFailure` fixture reading `"octave-doubled: reports ~140 for a 70
BPM track (2x)"`. The PRD's attribution is independently sourced and correct.

---

## 2. Fidelity to the document's own corrections and supersessions

The input carries four dated markers. PRD fidelity is **three correct, one
violated**, and the violation is internally self-contradicting.

| Marker | Plan doc | PRD treatment |
|---|---|---|
| E1 SUPERSEDED (2026-07-26, GH-166) | `:108-132` | **Correct and complete.** `prd.md:64` carries 604/661 fired, 38 helpful / 346 harmful / 220 neutral, net −308, and the nested mass-ratio ranges. `prd.md:65` carries the DSP demote-to-fundamental reversion (58 → 40/39/54/56). `prd.md:264` closes re-litigation. |
| "401 is headroom" retracted (`:45-49`) | `:45-49` | **Not violated, but not carried.** 401 appears nowhere, so the retracted framing is not repeated — at the cost of also losing the finding (§1.2). |
| Frame-rate framing superseded (`:66-69`) | `:66-69` | **Not violated, not carried.** Neither the original nor the correction survives (§1.4). |
| **"Hard cross-entropy" premise FALSE** (`:76-99`) | `:76-99` | **VIOLATED — the PRD repeats the retracted claim, twice.** |

### 2.1 The violated one, in detail

The plan doc's correction is unambiguous (`:76-81`):

> **CORRECTION 2026-07-26 (GH-166 / #146): the "hard cross-entropy" premise in the bullet above is FALSE for the authoritative v2 path.**
> `ablation/octave_aware_loss.py:42,77` sets `OCTAVE_FACTORS = (2.0, 0.5)` and `octave_mass = 0.15`, and `train.py` v2 mode routes through it … only the legacy v1 supervised path uses plain `F.cross_entropy`. So the loss DID give octave partial credit.

The PRD nonetheless asserts, in its **PUBLISHED**-tagged evidence base
(`prd.md:81`):

> **TempoCNN does not use Gaussian smearing.** Schreiber & Müller ISMIR 2018 uses plain categorical cross-entropy on **one-hot** targets over 256 bins — **identical to ours**. "Add smearing because Schreiber does" is folklore and false.

and again in **FR-63** (`prd.md:187`):

> Replace **one-hot** bin targets with ordinal targets.

Our v2 targets are not one-hot. Verified directly in source:
`_bmad-output/ml-training/ablation/octave_aware_loss.py` defines
`build_octave_soft_targets(true_bins, *, octave_mass: float = 0.15,
label_smoothing: float = 0.05, n_bins=BPM_BIN_COUNT)` — a target carrying 0.15
of octave-partner mass **and** 0.05 of uniform label smoothing.

The PRD contradicts itself twenty-four lines later. `prd.md:84`:

> **No tempo system places octave-partner mass in the training target.** **Our 0.15 split across {2T, T/2}** has zero published precedent.

and `prd.md:188` (FR-64) restates the tempo-dependent partner-dropping
behaviour accurately. So the PRD simultaneously holds "our targets are one-hot,
identical to TempoCNN" and "our targets carry a 0.15 octave split TempoCNN does
not have." Both cannot be true, and the false one sits in the evidence base
under a **PUBLISHED** tag, where §4's own framing (`prd.md:55`) says the
measured/published distinction is "load-bearing."

The practical damage lands on FR-63. Its ablation is specified as
"smearing-versus-one-hot" with a sigma sweep. Against the actual v2 baseline
that is not a two-arm comparison — the incumbent arm is
`one-hot + 0.15 octave mass + 0.05 uniform label smoothing`, which is three
factors, not one. Worse, `prd.md:83` cites DLDL specifically for beating
**uniform label smoothing** (MAE 2.51 vs 2.96) — the exact treatment already in
our target at 0.05, which the PRD nowhere records. As written, FR-63's ablation
cannot attribute its result.

**Fix:** strike "identical to ours" at `prd.md:81`; restate the actual v2 target
composition once, in §4.1 under a **MEASURED** tag with the
`octave_aware_loss.py` citation; re-scope FR-63's ablation to name all three
incumbent factors.

---

## 3. The open research item — GiantSteps' own sub-120 annotations

Plan doc `:160-163`, its own closing section:

> ## Open research item (verify the ruler)
> Check whether GiantSteps' OWN sub-120 annotations are octave-clean. If the benchmark labels are themselves octave-ambiguous, part of the 348/661 ceiling is the ruler, not the model (Mary). Pull Schreiber & Müller + Bock before E2/E3.

**Not represented in the PRD.** §14 resolves Q1-Q7 and adds Q8 (OA300
hand-annotations in training) and Q9 (the ~1.5× cluster) — neither is this.

It survived one hop and was lost on the second. `epics.md:1870` carries it
verbatim in the charter's open scoping questions:

> does GiantSteps' own sub-120 annotation set need an octave-cleanliness audit (the ruler vs the lens)?

So the charter → PRD transfer dropped a live charter question, not merely an
upstream note.

Four PRD items are adjacent but none discharges it:

- `prd.md:93` — the TISMIR 2020 re-annotation result (Acc1 58.9 → 64.8, Acc2 86.4
  → 94.0 with no algorithm change) is the *general* ruler-quality argument, and
  is strictly stronger evidence than the plan doc had. But it establishes that
  GiantSteps labels moved; it does not tell us **in which bands**, which is the
  whole question.
- **FR-60** (`prd.md:157`) tags annotation *version*, not annotation
  *octave-cleanliness*.
- **FR-62** (`prd.md:159`) audits metrical-level convention and is "retained for
  auditing the legacy corpora" — the closest hook, but its scope is the corpora
  historical figures rest on, and it is not pointed at GiantSteps' sub-120 bands.
- **FR-69c item 1** (`prd.md:228`) questions GiantSteps' *independence*
  (contamination), a different defect entirely.
- **AS-5** (`prd.md:362`) is about **OA300's** 80-85 / 160-175 clusters. Its
  2026-07-29 confirmation came from the non-Rekordbox pool. GiantSteps is not in
  scope of AS-5 at any point.

Why this is a live risk rather than a bookkeeping miss: GiantSteps remains **one
of the three gate corpora** under FR-68 (`prd.md:200`, `prd.md:346`). Its sub-120
bands are n=60 and n=35 — exactly the two bands E0 identifies as the model's
failures, and exactly the bands the epic exists to fix. If those 95 labels are
octave-ambiguous, then a third of the gate's evidence in the failing bands is
untrustworthy, and both directions of error are live: the epic could claim a win
that is a ruler artifact, or abandon at Gate 2 on a deficit that is partly the
ruler's.

There is also a visible internal tension the PRD does not resolve: `prd.md:133`
already excludes GiantSteps from the corpus-composition counts ("Excluding
GiantSteps for the contamination reason in FR-69c") while `prd.md:200` retains
it as a gate corpus. An octave-cleanliness audit of its sub-120 bands is cheap
relative to that inconsistency.

**Recommendation:** reinstate as **Q10**, or as an explicit sub-item of FR-62,
scoped to GiantSteps' `<100` and `100-120` bands, and sequence it **before**
Gate 2 rather than before E2/E3 (which no longer exist as PRD objects — §4).

---

## 4. E2 / E3 / E4 — coverage, drops, and the missing crosswalk

`grep -n 'E1\|E2\|E3\|E4' ` across both target files returns **zero matches**. The
E-identifiers do not survive into the PRD in any form, and no crosswalk table
exists. The PRD states it supersedes the charter's ordering (`prd.md:14`) but
never states its relationship to the E-ladder the charter was itself derived
from. That is the "silent renumber" the task asked about: not a renaming of
levers, but the loss of the mapping.

Reconstructed crosswalk:

| Plan doc lever | PRD disposition | Verdict |
|---|---|---|
| **E1** — octave-aware decode (`:132-140`) | `prd.md:64` (measured failure), `:264` (closed) | **Correctly retired**, with full numbers |
| **E2** — representation fix (`:142-148`) | `prd.md:266` Non-Goal: *"Input-representation redesign. Deferred, not rejected — F2 may promote it."* | **Demoted to a Non-Goal. No FR. Substance not carried** |
| **E3** — octave-aware target + rebalance (`:149-153`) | F4 (FR-63/64/65); rebalance half at FR-59d | **Partly covered, direction inverted on two of three elements** — legitimately, but the rebalance half is orphaned |
| **E4** — widen, then tempo-range ensemble, then genre-MoE (`:155-158`) | "Widen" killed by `prd.md:260` Non-Goal + AS-2. Tempo-range ensemble: **nowhere.** Genre-MoE: named once, inside a struck-through Q5 | **Partly superseded on evidence, partly dropped without record** |

### 4.1 E2 — the deferral is defensible; the silence is not

E2 is the doc's designated remedy for the residual: *"the genuine-error residual
+ 100-120 band"* (`:142`), with two concrete proposals — a tempo-invariant hop
(fixed seconds/frame, pad/crop) or a log-lag autocorrelation / tempogram input
"where 60 and 120 BPM are equidistant bins" (`:144-146`) — plus the operational
constraint that the Swift substrate must move in lockstep with Python training
(FNV parity tripwire).

Deferring it pending F2's ranking is a reasonable sequencing call and
`prd.md:266` says so honestly ("Deferred, not rejected"). Two things are still
wrong:

1. **The proposals themselves are gone.** "Tempo-invariant hop", "log-lag
   autocorrelation", "tempogram", "60 and 120 equidistant" — none appear. If F2
   promotes E2, the design work restarts from zero.
2. **The PRD acknowledges the risk while deferring its only proposed remedy,
   without connecting the two.** `prd.md:335`:

   > | The 100-120 band is unreachable | Acknowledged — OA300 has one track there; sourcing is open (Q3) |

   The mitigation column treats 100-120 as a *sourcing* problem. E0 says it is
   not: Acc2 == Acc1 == 1/35 means neither half nor double lands, and the plan
   doc is explicit (`:40-41`) that "octave-folding does nothing. This band is
   mis-pulsed and needs the representation / training fix, not decode." More
   100-120 tracks in the evaluation corpus measure the failure better; they do
   not address it. The risk row should name the deferred representation fix as
   the (deferred) mitigation, so the deferral is visible as a decision rather
   than reading as an absence.

The parity mechanism does survive (`prd.md:305`, NFR: "any substrate change bumps
`featureSetVersion`"), so E2's *guardrail* is in the PRD while E2's *content* is
not.

### 4.2 E3 — inverted on evidence (fine), orphaned on rebalance (not fine)

Two of E3's three elements are **reversed** by the PRD, and in both cases the
reversal is evidence-backed and explicitly recorded, which is the correct
handling of a superseded plan:

- E3 proposes "soft/Gaussian-blurred target around the true bin" (`:150`). The
  PRD refutes the premise: AS-6 (`prd.md:363`) is marked **REFUTED during
  Discovery** — TempoCNN uses one-hot, no tempo paper ablates smearing — and
  FR-63 re-grounds the idea on general ordinal literature with its own ablation.
  Correct handling.
- E3 proposes "explicit octave-aware loss penalizing 2x/0.5x less than random"
  (`:151`). The PRD moves the opposite way: FR-64 (`prd.md:188`) proposes
  "**Reconsider octave-partner target mass entirely** … Evaluate removing it in
  favour of a decode-side or prior-side octave mechanism", grounded in
  `prd.md:84` (no published precedent). Also correct handling — and note this is
  only coherent *because* the loss already has octave mass, which is the fact
  §2.1 shows the PRD elsewhere denies.

The third element is orphaned. E3's "oversample sub-120 so it isn't a rounding
error in the loss" (`:152-153`) lands only at FR-59d (`prd.md:152`), attached to
**corpus construction** rather than to training-target repair, and without the
counter-evidence documented in §1.3 above. There is no training-side FR that
owns tempo-class rebalance, so it will not be ablated alongside FR-63/FR-64 even
though the plan doc explicitly stacks it on the same retrain.

### 4.3 E4 — one clause killed on evidence, one clause vanished

E4 has two distinct proposals plus a ranking statement:

> widen the model before routing it; a tempo-range ensemble (octave arbiter over the existing model) before a genre-MoE. Genre-MoE is last and triggers the CoreML/ANE + re-bundling release decision (CLAUDE.md level). (`:156-158`)

- **"Widen the model"** is directly killed by `prd.md:260` ("Bigger models.
  Capacity is not the constraint") and AS-2. Legitimate, evidence-backed,
  recorded.
- **"Tempo-range ensemble (octave arbiter over the existing model)"** appears
  nowhere — no FR, no Non-Goal, no assumption, no open question. It is not
  rejected; it is absent. This is the one E-lever that vanished without any
  disposition at all. It is also the lever that survives the plan doc's own
  closing constraint at `:128-129`: *"Any surviving octave lever must source its
  evidence from OUTSIDE the signal that produced the candidate"* — an ensemble
  arbiter over DSP + ML is precisely such a lever, and the SignalPool seam for it
  already exists and sits idle at `.dspOnly`.
- **The MoE ranking** survives only inside struck-through Q5 (`prd.md:350`), and
  the four itemised deployment costs do not survive at all (§1.5). Meanwhile Q5
  resolved the style prior to be **classified** — importing exactly the
  router-error surface and second-model deployment cost that the roundtable used
  to rank MoE last. `prd.md:350` notices this ("that deployment objection now
  applies to F1") but the objection's content lives only in a document the PRD
  does not cite. F1 is the MVP's highest-evidence lever; the itemised cost of its
  now-mandatory classifier belongs in F1, not in a struck-through question.

### 4.4 F1 has no E-ancestor

Worth stating plainly: **F1 (style-conditioned tempo prior) does not descend
from this document at all.** The plan doc's ladder is E1-E4 and none of them is
a style prior; F1 comes from Discovery's SMC 2015 finding (`prd.md:77`). That is
a genuine addition and the strongest thing in the PRD. But it means the PRD's
lever set is *not* a re-ordering of the E-ladder — it is a different set with
partial overlap, and the absence of a crosswalk lets three E-levers exit without
anyone deciding they should.

---

## 5. Ranked recommendations

1. **Restore the full E0 table to §4.1** as a MEASURED block, all six bands, Acc1
   and Acc2 and the 2× count. Without it FR-68's "no regression in any band DSP
   already handles" and FR-71's per-band reporting have no baseline, and the
   model's 0/16 in 175+ is invisible. *(§1.1)*
2. **Fix the one-hot contradiction.** Strike "identical to ours" at `prd.md:81`;
   state the actual v2 target — one-hot + 0.15 octave mass + 0.05 uniform label
   smoothing, cited to `octave_aware_loss.py` — once, as MEASURED; re-scope
   FR-63's ablation to name all three incumbent factors. *(§2.1)*
3. **Reinstate the GiantSteps sub-120 octave-cleanliness audit** as Q10 or an
   FR-62 sub-item, sequenced before Gate 2. It is a live charter question
   (`epics.md:1870`) about 95 tracks in a gate corpus, in exactly the two bands
   the epic targets. *(§3)*
4. **Cite the ladder against FR-59d.** `+90 rebal` / `+190 rebal` are two measured
   band-rebalance attempts that moved OA300 50 → 48 → 43. FR-59d proposes
   oversampling/loss weighting without acknowledging them. *(§1.3)*
5. **Add an E→F crosswalk** (one table, §4 of the PRD) recording E1 retired, E2
   deferred to Non-Goal, E3 → F4 with two inversions, E4 split. Make the
   tempo-range-ensemble drop an explicit decision rather than an omission. *(§4)*
6. **Carry E2's substance into FR-57's differential** — tempo-invariant hop,
   log-lag ACF/tempogram, the `[1,1,128,512]` suspect, and the corrected
   corpus-prior mechanism with the frame-rate trap flagged — so F2 does not
   re-derive a corrected argument. *(§1.4, §4.1)*
7. **Repoint the 100-120 risk row** (`prd.md:335`) from sourcing to representation.
   E0 says that band is mis-pulsed, not under-sampled. *(§4.1)*
8. **Carry Acc2 = 401 with its retraction attached** — the oracle ceiling and the
   +136 genuine-error residual, explicitly labelled non-recoverable, so the
   figure informs the stopping rule without being mistaken for headroom. *(§1.2)*
9. Minor: record the OA300 gate threshold (`>55/82`), the ladder percentages, and
   the 113 → 145 → 177 / −16 band-trade numbers. *(§1.5)*
