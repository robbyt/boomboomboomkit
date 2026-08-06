---
title: 'Epic 12: Model-quality redesign — octave-aware BPM model'
status: draft
created: 2026-07-26
updated: 2026-07-29
---

# PRD: Epic 12 — Octave-Aware BPM Model

## Status at close (2026-07-29)

**This document is `draft`, deliberately.** Every question it can answer is answered — ten of eleven resolved, all five reviewer criticals closed. What remains is work, not specification. Flipping to `final` is a one-line change once the two items below land.

**Gate list — what must happen before this drives implementation:**

| Gate | Owner | Blocks |
|---|---|---|
| **FR-59f** — hand-verify all 258 corpus tracks | operator | corpus construction, therefore F3 and F6 |
| **Q9** — characterize the ~1.5× cluster | FR-59b executor | **ANSWERED 2026-08-01 to the limit of the data.** Tagging-convention hypothesis; **triplet status unestablished** — only the tag and our own detector exist to test it. **What binds: all 262 labels in the 100-120 band are unverified, and its ratio composition (197 of 262 in the 1.5x class, 27 at 1:1) signals workload risk.** 27 is not a bound on how many are valid. Uniform n = 43 is not yet established for any band. See `_bmad-output/ml-training/q9-ratio-cluster-2026-08-01.md` |

**Numbers that were retracted during authoring.** A reader who encounters a struck-through figure should trust the correction, not the original. Four were wrong and are corrected in place with the originals retained:

- **AST evidence** — MAE 20.2 / 4-of-10 was a ten-track subsample. The measured result is **MAE 13.50, Acc1 40.9% (27/66)**. The "mean collapse" and "head not backbone" readings are both withdrawn (addendum §A).
- **Corpus feasibility** — "100-120 binding at 28-for-27" came from a selection filter FR-59a.1 forbids. The real constraint is **140-160 at 43**, and the corpus is **258** tracks, not 162.
- **Per-band significance** — an earlier FR-59c claim was computed at n=27 and became false at n=43. Q11 supersedes the framing entirely: per-band is a **tripwire, never a significance claim**.
- **Octave dominance** — octave error is dominant on OA300 (16/24) and **not** on GiantSteps (7/124). The unqualified claim in the glossary was wrong.

**Authoring cost, recorded so the next epic can price it.** Four rounds of self-review across two days. It caught nine real defects, four of them in the load-bearing evidence, and **seven of the corrections stranded their own dependents** — an amendment moved and the requirements referencing it did not. That last number is why the corpus constants now live in one table. The reviews are in `review-rubric-walk.md`, `review-rubric-walk-2.md`, and three `reconcile-*.md` files; roughly 35 medium and low findings in them remain unaddressed and are known, not hidden.

## 0. Document Purpose

Turns the Epic 12 charter (`epics.md:1796+`) into scoped, gated requirements.

It **supersedes the charter's lever ordering**. Discovery research (2026-07-26) invalidated the charter's central premise and two of its supporting claims. Section 4 records what changed and why.

## 1. Vision

BoomBoomBoomKit's ML tempo path ships nothing. Epic 7 closed BYOW after three retrains failed both bundle gates; two subsequent cheap fixes were measured and removed.

The charter assumed the remedy was a better or bigger model. **Discovery found that assumption wrong.** A published tempo model roughly ten times smaller scores about thirty-five points higher, and the published reference for *our own architecture family* scores about thirty points above ours. Capacity is not the constraint.

Discovery also found the strongest lever in the epic, and it is not a model at all: **style-conditioned tempo priors lifted drum-and-bass Acc1 from 7.2% to 78.4% in published work** on the same corpus we evaluate against. We have never tried it.

**AMENDED 2026-08-05 (Story 12.2).** The last sentence above is still literally true and is the point: the published configuration has *still* never been run here. What changed is how the lever is reached. The **classifier** that FR-54 would have used to infer the style is **rejected** (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`); the style is declared by the caller instead, via FR-53's `Options.tempoScanRange` / `Options.perceptualWindow`, shipped by Story 12.1. Do not read "the strongest lever in the epic" as settled evidence: the one measurement taken so far, at a `100...200` fold window rather than the published `130-180` search range, came back a wash to negative, and AS-7 is annotated **UNTESTED** accordingly in the §15 assumptions table below (`:489` as of 2026-08-05). An earlier same-day version of this note said WEAKENED; external review established that the one measurement conditioned nothing on style, so it is not a test of style-prior transfer and cannot move AS-7 in either direction.

Epic 12 exploits that lever first, closes the reference gap second, and ships a small model inside the demo app only if it measurably improves the ensemble. If it does not after two serious attempts, the epic stops and says so.

> **Unreconciled, flagged 2026-08-05 (Story 12.2), not resolved here.** "Ships a **small** model" (this section, 2026-07-26) contradicts `epics.md:2379`, "**Compute-constraint change (operator, 2026-07-21).** CPU-only inference is **no longer a requirement**. Larger models are acceptable if accuracy improves." The operator relaxation predates this PRD's wording. Story 12.2 is documentation-only and does not pick between them; it records that model size is not a live constraint per the later operator decision, and that this line was never updated to match. Reconciling the two is PRD maintenance owned by whoever next revises §7.

## 2. Target User

### 2.1 Jobs To Be Done

- **The demo-app user** wants correct BPM on drum-and-bass without knowing what a model is. Today they get a DSP path that calls a 70 BPM track 140.
- **The library consumer** wants drop-in BPM detection. Today they get a BYOW seam and no weights — honest, but not the product's stated value.
- **The maintainer** wants to know whether a model is worth carrying, on evidence rather than hope. Three retrains produced no such answer.

### 2.2 Non-Users (v1)

- **Real-time and streaming consumers.** The path is file-based and offline; unchanged.
- **Non-macOS consumers.** Floor is macOS 15+, Apple Silicon.
- **Consumers wanting weights from the package.** Weights never ship in the repository (§11). Library consumers remain BYOW.

## 3. Glossary

| Term | Meaning |
|---|---|
| **Acc1** | Prediction within 4% of ground truth. Primary accuracy metric. |
| **Acc2** | Acc1 with octave-equivalent predictions counted correct. `Acc2 − Acc1` is the standard octave-error proxy. |
| **Octave error** | Predicting 2× or ½ the true tempo. **Dominant on OA300, not on GiantSteps** — the forensic harness records OA300's 24 misses as 16 octave + 2 triplet + 6 other, but GiantSteps' 124 misses as 98 other + 19 triplet + **7 octave**. Calling it "the dominant measured failure" without qualification was wrong and is corrected here; §4.1 carries the consequence. |
| **Metrical level** | Which pulse a listener counts. A 160 BPM track felt in half-time is 80. Both can be defensible ground truth. |
| **Tempo prior** | A constraint on the plausible tempo range, optionally conditioned on style. |
| **Ensemble lift** | Accuracy of DSP+ML combined minus DSP alone. The bundle bar (FR-68). |
| **BYOW** | Bring your own weights — `BNNSTechnique(modelURL:)`. |
| **Reference gap** | The ~30-point Acc1 deficit between our TempoCNN-family model and its published counterpart. |

## 4. Evidence Base

Claims are tagged **MEASURED** (we ran it), **PUBLISHED** (cited), or **UNTESTED**. The distinction is load-bearing: this epic exists partly because projections were previously carried as findings.

### 4.1 What our model does

- **MEASURED.** v2 (`maskedMelPretrain` seed 42): OA300 Acc1 43/82, GiantSteps 348/661 (52.6%). Both FR-18 gates failed. Ladder OA300 50→48→43, GiantSteps 296→330→348 — structural, not data volume.
- **MEASURED.** E0 bands: `<100` is clean octave-doubling (n=60, Acc1 1/60, Acc2 39/60, 38 predicting exactly 2×). `100-120` is genuinely mis-pulsed (n=35, Acc1 = Acc2 = 1/35 — no octave rule reaches it).

### 4.2 What we tried and it failed

- **MEASURED.** Posterior octave-fold decode (#141): net negative at every threshold. At 0.0 it fires on 604/661 for 38 helpful, 346 harmful, 220 neutral, net −308. Helpful and harmful mass-ratio ranges are fully nested. Removed.
- **MEASURED.** DSP demote-to-fundamental vote (2026-06-28): four variants, OA300 Acc1 58 → 40/39/54/56. All reverted.

### 4.3 What the literature says

**On capacity:**

- **PUBLISHED.** Böck & Davies TCN: GiantSteps Acc1 **87.0** at ~33k parameters *(figure is secondary-source — AS-3)*. Schreiber TempoCNN: **82.1 / 97.1** — the family our design copies. **Ours: 315k parameters, 52.6.** This is the reference gap.
- **PUBLISHED.** No evaluation of EfficientAT or any AudioSet-tagging CNN on tempo exists. HEAR and MARBLE contain no tempo task.
- **PUBLISHED.** Generic music embeddings are octave-blind: MULE 1-NN scores Acc1 35.9 / Acc2 96.1. Pulse present, metrical level absent.

**On style priors — the strongest result found:**

- **PUBLISHED.** Hörschläger, Vogl, Böck & Knees, SMC 2015, *Addressing Tempo Estimation Octave Errors in Electronic Music*: genre-conditioned tempo priors lift **DnB Acc1 from 7.19% to 78.42%**, overall 45.5% → 75.0%, on GiantSteps (20% DnB, DnB prior 130-180 BPM). No model change; a prior.

**On training targets — three charter/folklore corrections:**

- **PUBLISHED.** **TempoCNN does not use Gaussian smearing.** Schreiber & Müller ISMIR 2018 uses plain categorical cross-entropy on **one-hot** targets over 256 bins. "Add smearing because Schreiber does" is folklore and false. **Correction:** an earlier draft added "identical to ours" — that is false. `octave_aware_loss.py` applies `octave_mass = 0.15` split across in-range octave partners plus `label_smoothing = 0.05`, so our targets have never been one-hot. FR-64 states this correctly; the two passages contradicted each other. The live consequence is that **FR-63's ablation cannot be "smearing versus one-hot"**, because we do not have a one-hot baseline to compare against — it must construct one, or compare against the 0.15 + 0.05 target we actually train.
- **PUBLISHED.** Böck ISMIR 2019 does smear, but **triangular, ±2 BPM, neighbours 0.5 / 0.25** — about two bins, not eight — and never ablates it. **No tempo paper ablates smearing versus one-hot, or ablates sigma.**
- **PUBLISHED.** Ordinal targets do help in general, measured same-architecture: DLDL (TIP 2017) MAE 2.51 versus one-hot 3.02 **and versus uniform label smoothing 2.96** — so ordinal *structure* is the active ingredient, not smoothing. Imani & White (ICML 2018): HL-Gaussian 8.99 versus HL-OneBin 28.00.
- **PUBLISHED.** **No tempo system places octave-partner mass in the training target.** Our 0.15 split across {2T, T/2} has zero published precedent. Published practice handles octaves at **decode** (Morais 2024: three highest peaks, pick the middle when they form a half/double relation) or via **style-conditioned priors**.
- **PUBLISHED.** Expectation decoding is **contraindicated** for tempo — posteriors are multimodal across octaves, and expectation over 87 and 174 yields ~130, a tempo in neither mode. Böck's local quadratic interpolation is the safe middle.

**On multi-task beat+tempo — a charter correction:**

- **PUBLISHED.** Weaker than the charter claimed. The only clean controlled ablation (Sun et al., ISMIR 2021) reports +2.5pp, +0.7pp, **−4.1pp on GiantSteps**. Böck & Davies 2020's octave win is confounded with four simultaneous changes; the authors state there is "no magic bullet."

**On measurement:**

- **PUBLISHED.** Re-annotating GiantSteps moved Böck's Acc1 58.9 → 64.8 and Acc2 86.4 → 94.0 **with no algorithm change** (Schreiber, Urbano & Müller, TISMIR 2020). A ~6-point swing from ground truth alone.

### 4.4 What our corpus looks like

- **MEASURED.** OA300 across 82 labeled tracks: `<100` = 18 (clustered 80-85), `100-120` = **1**, `120-140` = 7, `140-160` = 15, `160-175` = **41**, `175+` = 0. Only 23 carry DAW-verified annotations.
- **UNTESTED inference.** The 18 tracks at 80-85 and the 41 at 160-175 are plausibly the same tempo octave annotated at different metrical levels. If so, the corpus encodes both halves of the octave ambiguity as ground truth. FR-59 tests this.

## 5. Features

### 5.1 F1 — Style-conditioned tempo prior

Highest published evidence in the epic, needs no model, no retrain, and is testable against existing fixtures today. Overlaps #172, already filed. **RESTORED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** FR-54a recorded that this "no model, no retrain" justification stopped holding as written once a classifier entered F1's path. Story 12.2 rejected the classifier, so the justification holds again for what F1 now contains, which is FR-53 (shipped by Story 12.1) and FR-55. It does **not** hold for a style-conditioned prior, which is no longer delivered.

- **FR-53.** Make the tempo search range consumer-specifiable. All four bounds are currently `private static let` on `BPMAnalyzer` and unreachable from `Options`.
- **FR-54.** ~~Support a style-conditioned prior that reweights (never hard-filters) candidates by plausibility for a **classified** style (§14 Q5, settled 2026-07-28), defaulting to no prior so the default path stays byte-identical. The classifier is a dependency this FR did not carry when first written. It must abstain rather than guess: an unrecognized style degrades to no prior, never to a wrong one, because a wrong prior actively misleads the detector and is worse than none.~~ **REJECTED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** this project does not build a style classifier. **CORRECTED 2026-08-05, same day, after external review:** ~~no classified style remains for the prior to condition on~~ is false, because §14 Q5 below names three style sources and only one is a classifier, and this library already reads file-tag metadata. The accurate statement is that Epic 12 builds **no style-conditioned prior of any kind**, on the product-policy premise recorded in §1.1 of the decision artifact: automatic style inference is outside this library's mission, and callers own their own domain constraints. FR-53's caller-declared bounds, shipped by Story 12.1 as `Options.tempoScanRange` and `Options.perceptualWindow`, are the alternative octave mechanism the reject exit requires be named; they are **not** Q5's caller-declared-*style* option, which is a different axis and is not built. ~~The abstain requirement is satisfied vacuously~~ **is withdrawn 2026-08-05: a rejected requirement is inapplicable, not satisfied.** What is true is that neither the reject nor FR-53 creates the failure surface the abstain clause exists to control, because nothing infers a style.   The hard-filter objection survives and is answered by opt-in defaults, since FR-53 defaults to the pre-story bounds and the default path never acquires the failure mode. FR-54 stays **covered by** Epic 12, and this decision is its coverage; coverage is not implementation.
- **FR-54a.** **The classifier F1 depends on is an unscoped second model, and this PRD does not build it.** §14 Q5 settled that the style prior derives style from a classifier rather than a caller-declared value or a file tag. Nothing in F1 specifies its training corpus, its style taxonomy, its own accuracy gate, or its size and latency budget — and the epic carries an explicit *small model* constraint that a second model competes against. F1's justification as the highest-evidence lever rests on it needing "no model and no retrain"; with a classifier in the path, **that justification no longer holds as written**. Either scope the classifier as its own feature with its own gates, or revisit Q5 in favour of the caller-declared option, which needs no model. ~~**Blocks F1's MVP claim, not F1 itself.**~~ **DISCHARGED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** the second exit was taken. The written decision this requirement demanded is **reject**, and Q5 is revisited at §14 below in favour of the caller-declared option, which shipped as FR-53 in Story 12.1. The four artifacts named above stay absent; their absence is the reject basis, not a gap to close. FR-54a stays **covered by** Epic 12, and this decision is its coverage.

- **FR-55.** Measure per-band and per-genre against the four `AccuracyFloorTests` known-failure fixtures — DSP-path errors with no model involved. **Not all four are octave errors.** `robbyt_x-ray-120s` reports ~115.6 against a true 174, a ratio of 1.5047, which is the 3:2 triplet relation; `AccuracyFloorTests.swift:126` labels it `triplet-related` in the fixture's own record. An earlier draft of this FR called all four octave errors, which the file it cites contradicts. Report the octave and triplet cases separately — a lever that fixes one need not touch the other. (The rationale here originally read "Q9 suggests triplets are their own phenomenon". Q9 was answered 2026-08-01 and leans the other way — its 1.5x cluster most likely reflects a tagging convention — but it did **not** establish that, and triplet status remains untestable from BPM scalars alone. The requirement survives on the fixture's own evidence: `robbyt_x-ray-120s` has independently established truth and is a real two-thirds detector error. Q9 found 86 structurally similar pool tracks, which are **candidates awaiting annotation**, not confirmed instances.)

*This lever is DSP-side and overlaps Epic 13. **Ownership settled 2026-07-28: Epic 12 owns it** (§14 Q6). The overlapping Epic 13 claim is a recorded duplication to settle when that charter is next opened, and no longer gates this work.*

### 5.2 F2 — Reference-gap diagnosis

No lever should be funded before we know why a published model in our own family scores thirty points higher.

- **FR-56.** Reproduce a published TempoCNN-family baseline end to end and score it on our evaluation path at our annotation version. Establishes whether the gap is ours or the ruler's.
- **FR-57.** Produce a written differential across every axis separating our pipeline from the reference — input representation and window policy, bin schema, loss, augmentation, corpus composition, decode, evaluation protocol — each labelled *suspect*, *neutral*, or *ruled out*, with evidence.
- **FR-58.** Rank the suspected causes by expected contribution and cost to test. **That ranking, not the charter's, drives everything after F2.**

### 5.3 F3 — Purpose-built corpus and measurement integrity

**Restructured 2026-07-28.** F3 previously patched the existing corpora one defect at a time. A count across every labeled source showed the defect is common to all of them, so the patches were treating symptoms.

| Band | OA300 | GiantSteps | Tony | Pooled | Excl. GiantSteps |
|---|---|---|---|---|---|
| <100 | 18 | 60 | 36 | 114 | 54 |
| **100-120** | **1** | 35 | 26 | **62** | **27** |
| 120-140 | 7 | 309 | 253 | 569 | 260 |
| 140-160 | 15 | 88 | 372 | 475 | 387 |
| 160-175 | 41 | 153 | 786 | **980** | 827 |
| **175+** | 0 | 16 | 36 | **52** | **36** |

Every corpus is drawn from the same musical world, so pooling deepens the skew instead of correcting it: 160-175 holds 980 tracks while the two bands the model actually fails on hold 62 and 52. Excluding GiantSteps for the contamination reason in FR-69c, 100-120 falls to 27.

That single fact generated four of the seven §14 questions. Q1 asked which corpus is primary because none is fit alone; Q3 asked where 100-120 material comes from because no corpus has it; Q4 asked how to resolve contradictory metrical levels; and FR-69c items 1-4 are all corpus-composition defects. F3 is therefore rebuilt around producing a corpus rather than around characterising the ones we have.

Two earlier results already said the rulers were suspect: the ~6-point annotation-version swing, and a gate whose denominator is half one tempo band.

**Corpus constants — the single source.** These seven values stranded across requirements seven times during authoring; each amendment moved one site and orphaned its dependents. **State them here and reference them elsewhere; do not restate them.** Any change is made here first, then propagated deliberately.

| Constant | Value | Set by |
|---|---|---|
| `N_BAND` — tracks per band | **43** | ~~scarcest compliant band (140-160)~~ **CORRECTED 2026-08-01: this is the scarcest band of ONE source (the non-Rekordbox pool), used as a global constant across three.** The three-source census puts the scarcest band at **175+ with 140** (104 on the strictly independent banding) — roughly 3x. So 43 is a floor set by one source, not a ceiling set by availability, and corpus size becomes a verification-budget choice. Still conditional in the other direction too: Q9 found every candidate label in 100-120 and 140-160 unverified, so FR-59f can lower it. See `_bmad-output/ml-training/three-source-band-census-2026-08-01.md`. |
| `N_BANDS` | **6** | <100 / 100-120 / 120-140 / 140-160 / 160-175 / 175+ |
| `N_EVAL` — evaluation corpus | **258** | `N_BAND × N_BANDS` |
| `ALPHA` — operative significance level | **0.05** | Q10 retired FR-69a's 0.025 with the multi-corpus gate |
| `T_MIN` — gate lift at 10% discordance | **12 net tracks** (4.7%) | exact two-sided McNemar, `d` = 26, at `ALPHA` |
| `HANDLED_MIN` — DSP-handled band threshold | **30 of 43** correct | policy choice, Q11 |
| `GATE_CORPUS` | the 258-track balanced corpus **alone** | Q10; OA300 and GiantSteps report only |

**Evaluation corpus (blocks the bundle gate):**

- **FR-59.** Build a **band-balanced evaluation corpus** drawn across OA300, Tony's Rekordbox collection, and the Story 7.2 non-Rekordbox pool. **Balanced to the scarcest band** (§14, settled 2026-07-28): every band carries the same count, **43**, for **258 tracks** total. Uniform by construction, so no band can dominate an aggregate the way 160-175 does today. (An earlier draft said 27 and 162; those came from a selection filter FR-59a.1 forbids — see the feasibility resolution below.)
  - Supersedes the former "band-stratified held-out octave test set from OA300". The AS-5 sentinel group survives as a labelled subset (FR-59b), not as the corpus design.
  - **Statistical consequence, measured not assumed.** At `N_EVAL` and 10% discordance, exact McNemar at `ALPHA` needs `T_MIN` = **12 net tracks (4.7%)** — better in relative terms than OA300's 82 tracks, which needs 8 (9.8%) at the same α. Balancing strengthens the aggregate gate. (An earlier draft said 14 tracks at α = 0.025; Q10 retired that α along with the multi-corpus gate.)
- **FR-59a.** Source the scarce bands (100-120 and 175+) from the non-Rekordbox pool (§14 Q3), subject to two conditions that are not optional:
  1. **Labels must be established independently of our DSP.** The 7.2 survey was deliberately BPM-tag-blind and its tiering leaned on our own detector. Promoting a DSP-derived value to ground truth would turn the gate into a change detector for the thing it tests — the trap `FIXTURES.md` already guards against for the accuracy floor.
  2. **Contamination boundary.** No track, remix, or artist may appear in both the evaluation corpus and any training set. `scripts/audit-corpus-splits.py` already enforces this class of check and must cover the new material.
- **FR-59b.** Declare **one metrical-level convention** for the corpus and label every track to it (this is what §14 Q4's re-labelling decision becomes). **Elevated 2026-07-29 from a hygiene step to the load-bearing decision of F3**: the pool survey showed the band distribution follows from the convention, so this choice determines which bands are scarce and how large a balanced corpus can be. The collection's own convention is half-tempo (71% of tagged tracks); adopting it and adopting full-tempo produce different corpora from identical files. **Corroborated 2026-08-01 on a second population**: Tony's own Rekordbox entries band as 889 tracks below 100 and zero at 160-175 as entered, against 36 and 786 once octave-corrected — the same 1,344 files, two near-mirror distributions. That is his own metadata rather than third-party file tags, so the two populations are independent of each other. **Caveat that must travel with it:** the octave-corrected column's octave comes from a cluster vote our detector participates in, so it describes the convention and does not establish which level is right; only the as-entered column is FR-59a.1-clean. See `_bmad-output/ml-training/three-source-band-census-2026-08-01.md`. A corpus with a single declared convention cannot encode both halves of the octave ambiguity as ground truth, which makes AS-5 a property of the *old* corpora rather than an open question about the new one. Retain the 80-85 / 160-175 pairs as a tagged sentinel subset so the old ambiguity stays measurable.
- **FR-59c.** **Per-band inference is possible but narrow.** Recomputed at the corrected *n* of 43 per band and FR-69a's α of 0.025 — an earlier draft stated this at *n* = 27 and α = 0.05, and its claim that 20% discordance is unreachable became false when the corpus grew:

  | band discordance | `d` | verdict at α = 0.025 *(stale α — see note below)* |
  |---|---|---|
  | 10% | 4 | **impossible** — no split reaches significance |
  | 20% | 9 | possible, but only at **9:0**, every discordant track one way (`p` = 0.0039) |
  | 30% | 13 | possible at 11:2, net 9 (`p` = 0.0225) |

  **Superseded in part by §14 Q11 (2026-07-29).** The table above stands as arithmetic, but the conclusion drawn from it does not: Q11 settles that per-band results are **a deterministic benchmark tripwire and never a significance or noninferiority claim**, at any split. The α shown is also stale — Q10 retired FR-69a's partial-conjunction correction along with the multi-corpus gate, so 0.05 is operative and 0.025 no longer applies here. Read this FR as evidence for *why* Q11 chose a tripwire, not as a rule of its own. **Report the exact `b:c` split per band, never a bare delta** — that requirement survives and Q11 depends on it.

- **FR-59f.** Define how a tag becomes ground truth, without using our DSP. A file tag is a single unverified assertion; FR-59a.1 rules out corroborating it with the detector under test. At least one of the following must be specified before the corpus is built, and whichever is chosen must be recorded with the corpus:
  1. **Human verification** of the balanced subset. 258 tracks is tractable by hand and is the only option that is unambiguously independent. The existing DAW-oracle workflow (`scripts/dawproject-bpm.py`) is the precedent.
  2. **A second automatic estimator that is not ours** — a published implementation, used only as a corroborating vote. Independent of our DSP, but introduces that tool's own biases.
  3. **Tag-only, declared as such**, with the corpus labelled lower-confidence and the gate's conclusions hedged accordingly.
  **SETTLED 2026-07-29 (operator): option 1, human verification of the balanced set.** Every track in the 258 is verified by hand before it counts as ground truth. This is the only option that is unambiguously independent of the detector under test.

  **Two risks recorded rather than assumed away.** *Scale is unproven*: the DAW-oracle precedent this leans on produced **23** verified tracks, not 258 — an order of magnitude smaller — so the effort is an estimate, not an extrapolation from experience. Budget it explicitly and re-plan if the rate does not hold. *The scarcest band has no slack*: 140-160 sits at exactly 43, so **any track rejected during verification lowers uniform n for all six bands at once** (see finding 1 below). Verify that band first — it is the one that can shrink the corpus.

  **Sharpened 2026-08-01 by Q9.** Three amendments to the budget and the protocol. Nothing here reclassifies a track: **all 262 labels in 100-120 and all 43 in 140-160 are unverified**, and the ratio composition below is a workload signal, not a verdict on any file.

  **(a)** ~~Both bands are more uncertain than the plan assumed.~~ **SUPERSEDED 2026-08-01 by the three-source census: 140-160 holds 430 across all three sources, not 43, so the scarcity rationale for verifying it first is void.** Its pool contribution is still thin and weakly corroborated (32 of 42 at a 1:1 tag/DSP ratio, 3 at ~1.33x, the rest lowest-confidence), but a shortfall there no longer shrinks the corpus. **Verify 100-120 first**, for the workload reason in (b) rather than for scarcity. The census also finds the `175+` band is 130-of-140 within 175-179 and non-separable from 160-175 at the ±4% Acc1 tolerance, so the band scheme's top edge needed settling before the draw. **SETTLED 2026-08-01 (operator): keep six bands.** `175+` stays separate, at the accepted cost of roughly 43 verification slots spent on a distinction the ±4% gate cannot resolve. The near-degeneracy is recorded here so a flat or noisy `175+` result is not later read as a measurement of fast-tempo performance: on this corpus that band is 175-179 with three to five genuinely above-180 tracks behind it.

  **(b) Budget 100-120 heavily, and treat the ordering claim as conditional.** Under Q9's tagging-convention hypothesis a tag-trusting draw in that band yields roughly one keeper in four, so reaching 43 keepers takes on the order of 170 reviews. That is a **scenario derived from a hypothesis**, offered so the budget is not set at 43 and then blown; it is not a measured rejection rate. Whether 100-120 or 140-160 is the binding band is likewise hypothesis-dependent and must not be written as a finding.

  **(c) The FR-59a.1 line, and why ordering is not automatically safe.** Sizing the annotation budget from aggregate `dsp/tag` statistics is permitted: if the hypothesis is wrong the cost is reviewer time and nothing enters the corpus incorrectly. **Using `dsp/tag` to exclude tracks from the draw is forbidden** — it bakes the detector under test into which material a human is ever allowed to see. **Ordering the queue by `dsp/tag` sits between the two and is only safe under all four of the following**, because if verification stops once 43 acceptable tracks are found then everything later in the queue was functionally excluded and the sort order shaped the corpus:

  1. The candidate set for each band is **fixed before** any DSP quantity is consulted.
  2. The **entire committed batch is annotated**, regardless of queue position or of reaching 43 early.
  3. The annotator is **blinded** to the file tag, the DSP estimate, its confidence, and the ratio class.
  4. Corpus membership is chosen **after** annotation, by a precommitted rule that reads no DSP output.

  If the batch will not be completed, order the queue at random and spend the budget on breadth instead.

  **Until this is done the corpus cannot be built**, because every downstream number inherits the label quality. This is the successor to the "28-for-27 margin" that the earlier draft mistakenly identified as the binding constraint.

**Training corpus (does not block the gate):**

- **FR-59d.** Build the training corpus for **volume with band-aware sampling**, explicitly **not** balanced to the scarcest band. Truncating training data to ~258 tracks would be strictly worse than the 595-1509 tracks already in use, and the three retrains already demonstrated a fixed-capacity band trade that starving the model would deepen. Correct the distribution with oversampling or loss weighting, which costs no data. The scarcest-band rule is an evaluation-side decision and does not transfer.
- **FR-59e.** Training and evaluation corpora share the convention from FR-59b and the partition from FR-59a.2. A model trained against one convention and scored against another measures the convention gap, not the model.

**Measurement integrity (unchanged in intent):**

- **FR-60.** Tag every reported accuracy figure with its ground-truth annotation version. Untagged historical figures are marked untagged, not assumed. **Now also a precondition of FR-59b**: adopting a single convention makes every figure on the old labels incomparable, and version tagging is what makes that survivable rather than silently confusing.
- **FR-61.** Report `Acc2 − Acc1` as a first-class metric alongside Acc1. It is the standard octave-error proxy and this epic is about octave errors.
- **FR-62.** Record the metrical-level labelling convention the project trains toward, and audit the training corpus against it. Subsumed into FR-59b for the new corpus; retained for auditing the legacy corpora that historical figures rest on.
- **FR-62a.** ~~If FR-59 confirms AS-5, re-label the affected OA300 tracks to that single convention.~~ **Superseded 2026-07-28 by FR-59b.** Rather than re-label OA300 in place — irreversible, and it invalidates every historical figure on those labels — the single convention is declared for the *new* corpus and OA300 is left intact as a tagged historical artifact. This keeps the old figures interpretable instead of stranding them.

**Feasibility: RESOLVED 2026-07-29.** Measured against the existing 4,766-track pool survey; full analysis in `_bmad-output/ml-training/non-rekordbox-band-feasibility-2026-07-29.md`.

**Corrected 2026-07-29 after review.** The first pass at this resolution selected tracks on "an independent tag present, **and the DSP agreeing after octave normalization**." That filter is exactly what FR-59a.1 forbids, nineteen lines above. It biases the corpus toward DSP-easy material, which inflates the DSP baseline and suppresses the very lift the gate is built to measure. It also produced the wrong headline: on the compliant basis, 100-120 is not the binding constraint and there is no one-track margin.

On the **FR-59a.1-compliant basis** — banded by the independent tag alone, with our DSP used nowhere in selection:

| Band | available | vs 27 |
|---|---|---|
| <100 | 1,996 | +1,969 |
| 100-120 | 262 | +235 |
| 120-140 | 52 | +25 |
| **140-160** | **43** | **+16** |
| 160-175 | 102 | +75 |
| 175+ | 113 | +86 |

**Within the pool, the scarcest band is 140-160 at 43, not 100-120 at 28.** Uniform *n* can therefore be **43**, for a **258-track** corpus rather than 162 — larger and better powered than the earlier figure claimed. **(CORRECTED 2026-08-01.** "Scarcest" here is ~~a property of the collection~~ **pool-only**, written before the three-source census. Across all three sources 140-160 holds **430** (368 on the strictly independent banding) and the scarcest band is **`175+` at 140** (104 independent) — see `N_BAND` in the constants table. 43 survives as the planning constant, but as a verification-budget choice rather than an availability ceiling. The α below is stale too: Q10 retired FR-69a's 0.025 along with the multi-corpus gate, and the operative figure is `T_MIN` = **12 net tracks at `ALPHA` = 0.05**.**)** Statistics as computed at the then-current α of 0.025:

| discordance | d | min net lift *(at the retired α = 0.025)* | as % of 258 |
|---|---|---|---|
| 5% | 13 | 9 | 3.5% |
| 10% | 26 | **14** | 5.4% |
| 20% | 52 | 18 | 7.0% |

**The open item this exposes is label validation, and it is now the real risk.** These 2,568 tag-carrying tracks have *unvalidated* labels: a tag is one unverified assertion by whoever wrote it. The previous draft reached for DSP agreement precisely because it is the only corroborating signal on hand, and that is the one signal FR-59a.1 rules out. **FR-59f** below governs. Three further findings, the first replacing the retracted one:

1. ~~**140-160 is the binding constraint, at 43 tracks — and its margin is zero by construction.** Balancing to the scarcest band means the scarcest band always sits exactly at *n*, so any label rejected on review during FR-59f drops uniform *n* for all six bands together. Plan the review margin here, not at 100-120.~~ **SUPERSEDED 2026-08-01 by the three-source census.** The zero-margin argument held only while the scarcest band sat exactly at *n*. Across all three sources every band clears 43 with surplus — 140-160 at 430, the scarcest `175+` at 140 — so a label rejected during FR-59f is replaced from within its own band instead of shrinking all six together. The review margin is therefore a workload question, not an availability one: **verify 100-120 first** (FR-59f note (a)), because Q9 puts 197 of its 262 pool labels in the 1.5x class against only 27 at 1:1. ~~An earlier draft named 100-120 the binding constraint at 28-for-27~~ — that followed from the forbidden DSP filter and is retracted; 100-120 has 262 compliant tracks in the pool, the second-most of any band.

2. **The pool is tagged at half tempo for 71% of tagged tracks** — the DSP estimate is ~2x the tag for 1,822 of 2,568, against only 357 agreeing at ~1x, with 1,529 tracks tagged below 100 and detected at 160-175. Consequently **the pool's band distribution is a property of the convention, not of the music**: by tag it is 78% sub-100, by DSP 65% at 160-175, describing identical files. This makes **FR-59b's convention choice load-bearing rather than a formality** — declaring half-tempo and declaring full-tempo produce different corpora from the same source.

3. ~~**A ~1.5x cluster of 222 tracks is unexamined.** Triplet relationships are a distinct phenomenon from octave errors, and §4's evidence base does not currently account for them.~~ **EXAMINED 2026-08-01 (Q9).** The cluster is 202 tracks under the window used, and its best-supported reading is a tagging convention rather than a triplet phenomenon — a hypothesis, since two scalar BPM estimates carry no rhythmic information and cannot settle it. On that reading §4 needs no triplet account on its behalf. What §4 should carry either way is the mirror observation: **86 pool tracks where our own detector reports two-thirds of what the tag implies**, structurally like the `robbyt_x-ray-120s` fixture, clustering at ~115 BPM against a ~173 collection. Those are candidate instances awaiting annotation, not confirmed detector errors.

### 5.4 F4 — Training-target repair

Retained, but with its rationale corrected. We are **ahead of the published record** here, not following it, so every element ships with its own ablation.

- **FR-63.** Replace one-hot bin targets with ordinal targets. Justified by the general ordinal literature, **not** by TempoCNN, which uses one-hot. Ship with a smearing-versus-one-hot ablation and a sigma sweep — no tempo paper has published either.
- **FR-64.** Reconsider octave-partner target mass entirely. The current symmetric 0.15 has no published precedent; `octave_partner_bins` drops out-of-range partners, so above ~142 BPM the full mass lands on the half and below ~60 on the double. Evaluate removing it in favour of a decode-side or prior-side octave mechanism (§4.3).
- **FR-65.** Log the complete loss configuration into run metadata. `model_metadata.json` records none, so which `octave_mass` prior retrains used is unrecoverable.

### 5.5 F5 — Bin-range alignment

- **FR-66.** Align the training bin range with the decode range, or fold out-of-range mass at decode. Bins 0-29 and 171-255 (**115 of 256**) can never produce a usable result against the runtime's `60.0...200.0` abstain, wasting capacity and depressing `softmax_max` toward the Gate-1 threshold.
- **FR-67.** Treat the bin schema as a **public contract**. It is declared in `tools/coreml-convert/reference_arch.py:37-39` (**ships to main**) and `dataset.py:59-62`, and `BNNSTechnique` throws `MLTechniqueError.binCountMismatch` against a hard-coded 256. All three move together; it is breaking for BYOW consumers.

### 5.6 F6 — The bundle gate

FR-18 required matching DSP standalone (GiantSteps ≥ 537/661 — DSP's own score). That asks the model to replace DSP rather than help it, which is why a model that fixed the sub-100 band would still have failed.

- **FR-68.** Define the bundle gate as **ensemble lift**: DSP+ML beats DSP alone by a stated margin **on the 258-track balanced evaluation corpus** (§14 Q10, settled 2026-07-29), with **no regression** in any band DSP already handles. OA300 and GiantSteps are **reported alongside as context, and do not gate**.

  ~~at least two of the three evaluation corpora, with no regression on the third (§14 Q1, settled 2026-07-28)~~ — superseded by Q10. With a single gate corpus, **FR-69a's partial-conjunction correction no longer applies**: there is no multi-corpus conjunction. The operative threshold reverts to exact two-sided McNemar at `p <= 0.05` on the gate corpus, which is **12 net tracks at 10% discordance** (`d` = 26), not the 14 stated for α = 0.025. FR-69's table is the reference; read the α = 0.05 column.

  **Two things this FR did not define, flagged at review and still open.**

  *Which corpora.* "The three" dates from before F3 built a purpose-built corpus, and the PRD now contradicts itself: §5.3 excludes GiantSteps from the balanced corpus on the contamination reason in FR-69c.1, while this FR keeps it as a gate arm; §9 refers to "the primary corpus" although Q1 resolved that none exists. The candidates are the new 258-track corpus alone, the three legacy corpora, or the new corpus plus legacy corpora as external validation. **Unresolved — tracked as Q10.**

  *What "no regression" means operationally.* As written it is untestable. "No statistically significant regression" is not evidence of no regression, and at per-band *n* the test has almost no power to detect one (FR-59c). It needs a predeclared **noninferiority margin per band** — a stated number of tracks a band may lose while still passing — not an absence of significance. **Unresolved — tracked as Q11.**
- **FR-69.** State the margin in tracks, not percentages. **Settled 2026-07-28 (§14 Q2) after a statistical consult. The original wording, struck below, was wrong in both its statistic and the conclusion drawn from it.**

  ~~Existing discipline is ≥2 OA300 tracks (1 track ≈ 1.2pp against a ~5pp standard error).~~

  The ~5pp figure is `sqrt(p(1-p)/n)` for a *single* proportion at n=82 — the standard error of one system's accuracy, not of the difference between two systems scored on the same tracks. The correct frame is **exact two-sided McNemar** on discordant pairs. With `b` = tracks the ensemble fixes, `c` = tracks it breaks, `d = b + c`, and net lift `t = b - c`, the equal-accuracy null is `b ~ Binomial(d, 0.5)`. The paired standard error is `sqrt(d)/n`, which beats 5pp only when `d` is small — so "both systems see the same tracks" is not on its own enough.

  **A 2-track net lift can never be significant.** The most favourable case, `d = 2` split 2:0, gives exact `p = 0.500`. The smallest significant result on any corpus is 6:0 (`p = 0.031`). Computed independently, not taken on report.

  The threshold depends on the discordance `d`, which has not been measured. **Two α values appear in this PRD and they must not be confused.** The table below is computed at `p <= 0.05`, which is the right reference for a *single* corpus considered alone. **FR-69a's partial-conjunction rule mandates `p <= 0.025`**, and that is the operative threshold for the multi-corpus gate. At 0.025 the requirements rise: `d = 25` needs **13** not 11, `d = 66` needs **20** not 18, and `d = 132` needs **28** not 24. Read the table as a floor, then apply FR-69a.

  Planning values at exact two-sided `p <= 0.05`:

  | Corpus | discordance `d` | min net lift `t` | split | exact `p` |
  |---|---|---|---|---|
  | OA300 (n=82) | 8 (10%) | **8** | 8:0 | 0.008 |
  | OA300 | 16 (20%) | **10** | 13:3 | 0.021 |
  | OA300 | 25 (30%) | **11** | 18:7 | 0.043 |
  | GiantSteps (n=661) | 66 (10%) | **18** | 42:24 | 0.036 |
  | GiantSteps | 132 (20%) | **24** | 78:54 | 0.045 |

  Large-sample planning approximation: `t >= 1.96 * sqrt(d)`, rounded up to match the parity of `d`.

  **"≥2 tracks" survives only as a product-value floor** — an assertion that 2.4pp is worth shipping — **and must never again be described as justified against noise.**

- **FR-69a.** The 2-of-3 corpus rule needs a multiplicity correction. If one corpus genuinely improves and the other two do not, an uncorrected rule falsely claims two-corpus replication with probability up to ~9.75%. Use a **partial-conjunction rule: sort the three corpus p-values and require the second-smallest to satisfy `p2 <= 0.025`.** This holds without assuming the corpora are independent. At 10% discordance it implies ~8 net tracks on OA300 and ~20 on GiantSteps.

- **FR-69b.** Seed agreement is a robustness guardrail, **not** a substitute for the paired margin. Three seeds share the same tracks, labels, and failure modes, so their results are correlated: do not multiply seed-level p-values, and do not treat 3-seed agreement as `0.05^3`. Freeze the exact weights to be shipped and test that artifact once on untouched data; the other seeds evidence development robustness only.

- **FR-69c.** **Unresolved design risks in the gate itself**, raised by the same consult and not yet answered. These bear on FR-68's 2-of-3 rule and must be settled before the gate is trusted:
  1. **GiantSteps may not count as confirmatory.** §4 records it as the distribution the reference model family was fit to. If its actual tracks or labels touched training, tuning, model selection, or repeated candidate screening, it is not independent evidence — merely sharing a distribution is weak external validation at best.
  2. **Two of the three corpora are DnB/high-BPM-heavy.** OA300 is 41 of 82 in 160-175, and Tony's split is DnB-dominant. "Two of three" therefore does not establish broad BPM-domain performance, which is the thing the gate is meant to certify.
  3. **Repeated screening inflates significance.** Re-using the same corpora to choose among candidates makes nominal p-values optimistic. Predeclare the candidate and the analysis, or hold a corpus back.
  4. **A one-track band cannot support a no-regression claim.** OA300's 100-120 band has exactly 1 track, and FR-71 requires per-band reporting. "No significant regression" is not evidence of no regression: predeclare each band's noninferiority margin and treat one-track bands as unmeasurable rather than as passing.
  5. **McNemar assumes independent tracks.** Duplicates, remixes, or clusters by artist or source need cluster-aware resampling. Annotation error is not in McNemar's uncertainty at all.
- **FR-70.** Retain the DnB triplet sentinels and a confidence-calibration floor. FR-25's calibration metric was never committed and never ran; here it is a precondition.
- **FR-71.** Report per-band lift, never only an aggregate. The +190 retrain gained 120-140 and lost 140-160; an aggregate hid that. **This is a deterministic benchmark tripwire, not a statistical claim** (§14 Q11): on the locked benchmark, `gains ≥ losses` is required in every predeclared DSP-handled band, and any band failing it blocks approval pending documented review and a recorded waiver. Report the exact `b:c` split per band and the gross `losses` on its own — a net-zero band can still have swapped many previously-correct tracks for different ones.

### 5.7 F7 — Delivery

- **FR-72.** Ship weights inside the demo app archive (`make demo-archive`), never in the repository.
- **FR-72a.** Bundle the model card into the demo archive and link it from the about screen (§14 Q7, settled 2026-07-28). Three gaps this does not close:
  1. **The artifact is develop-only and written for developers.** It now lives at `_bmad-output/ml-models/MODEL_CARD.md`, which never ships to `main`. The demo archive is built from `develop` so bundling is mechanically fine, but `make demo-archive` must copy it in explicitly, and its register is internal — a demo user meets story references and corpus jargon unless an end-user summary fronts it.
  2. **It documents models that are not the shipped one.** It currently covers the withdrawn v1 and the failed v2 retrain. Whatever ships under F6 must be added before the archive is cut, or the bundled card describes something the user does not have.
  3. **A card is not a runtime signal.** It states what the model scored in aggregate; it cannot tell a user whether the model contributed to the number currently on screen. If that matters, it needs a per-result indicator, which this decision explicitly did not adopt.
- **FR-72b.** Decide, and state, what `Options.ensemblePolicy` defaults to once a model ships. It currently defaults to `.dspOnly`, the one case that is operation-inert — `MLTechnique.evaluate` is never invoked. **A model can therefore clear every gate in F6 and change nothing any user sees.** The charter flagged this and this PRD dropped it. Three positions are available and none is free: leave `.dspOnly` and require callers to opt in, which makes the bundled model inert by default; change the library default, which alters behaviour for every existing consumer and contradicts the byte-identity contract that `.dspOnly` currently guarantees; or set a non-default policy in the demo app only, leaving the library untouched. **The third is the only one consistent with FR-73**, and should be confirmed rather than assumed.

- **FR-73.** The library keeps its BYOW seam unchanged. Absent weights degrade to DSP-only via the existing abstain path — no network, no new dependency, no behavioural change for existing consumers.
- **FR-74.** Register the bundled model through `ModelRegistry` for SHA-256 identity verification at load. The digest machinery exists and already handles `.mlmodelc` directory bundles.

## 6. Decision Gates and Stopping Rule

The charter had no stopping rule. Epic 7 ran three retrains past the point its own signal said stop; this epic is the cost of that.

**Gate 0 (after F2).** If the reference baseline also scores near 52 on our evaluation path, the problem is measurement, not modelling. Stop, fix measurement, re-plan.

**Gate 1 (after F4).** If training-target repair produces no ensemble lift, that is **failed lever one**.

**Gate 2.** If the top-ranked cause from FR-58 also produces no lift, that is **failed lever two**. **The epic stops and the premise is re-examined** — including that a bundleable model may not be reachable with this corpus, and that the effort belongs on the DSP path.

Descending the remaining lever list after two failures requires an explicit written override.

## 7. Non-Goals

- **Bigger models.** Capacity is not the constraint (§4.3). AST-as-classifier, EfficientAT fine-tunes and Core AI are out of scope. Core AI is real (WWDC 2026, macOS 27) but solves a problem we do not have.
- **AST-as-regression.** Rejected on the measured gap: an external notebook finetuning AST for BPM regression scores **Acc1 40.9% (27/66), MAE 13.50** on GiantSteps validation, against the DSP path's 81.2% on the same corpus. **Not rejected on "head shape" or on mean collapse** — an earlier draft claimed both and the addendum's CORRECTION block retracts them: the model beats a constant-mean predictor by 4.24 BPM, and no ablation isolating the head was ever run. Its 87M parameters reaching 40.9% is measured corroboration for AS-2.
- **Expectation decoding.** Contraindicated for multimodal tempo posteriors.
- **Weights in the repository.** Non-negotiable (§11).
- **Re-litigating the two measured failures.** Closed.
- **A network-fetching library.** Out of scope entirely.
- **Input-representation redesign.** Deferred, not rejected — F2 may promote it.

## 8. MVP Scope

### 8.1 In Scope

**F1** (style prior), **F2** (reference-gap diagnosis), **F3** (measurement integrity), and the gate definition in **F6**. **NARROWED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`):** F1's MVP content is FR-53 (shipped by Story 12.1) and FR-55. The style-conditioned prior of FR-54 is not in MVP and is not delivered at all, because the classifier it depends on is rejected. F1 stays in MVP scope on the strength of FR-53 and FR-55, and the rationale sentence below holds for that content.

Rationale: none needs a retrain, all are cheap relative to training, F1 carries the highest published evidence in the epic, and together they determine whether the rest is worth funding.

### 8.2 Out of Scope for MVP

F4 and F5 are gated on F2's findings. F7 cannot start until there is a model worth shipping. **F8 — the SignalPool octave arbiter — is out of scope for MVP and in scope for the epic (added 2026-08-02).** This is the Epic 12 charter's item 7(a): wire the idle `OctaveEquivalencePolicy` and the DSP `resolveOctaveAmbiguity` as an octave arbiter through the `SignalPool`, plus beat-grid-support candidate rescoring transferred from Epic 13's charter on 2026-08-01. An earlier draft of this PRD dropped item 7(a) silently — not deferred, not in §7 Non-Goals, not here, simply unmentioned — while §14 Q6 told the reader Epic 12 had won ownership of the DSP octave levers, which left the lever orphaned and `GH-138`'s three dead public knobs (`MLExecutionPolicy`, `ComputeBudget`, `OctaveEquivalencePolicy`) without an owner. It is the one surviving octave lever that satisfies the charter's outside-evidence constraint, since beat-grid support is an independent signal rather than another scalar derived from the evidence that produced the error. No story covers it; it is post-MVP by construction, because MVP is fixed at F1, F2, F3 and F6's gate definition.

## 9. Success Metrics

**Primary.** Ensemble Acc1 lift over DSP-alone on the primary corpus, at a stated annotation version, with per-band breakdown.

**Secondary.** `Acc2 − Acc1` narrowing on the `<100` band — the mechanism-level metric, which moves only if octave behaviour actually improved.

**Counter-metrics.** Each catches a way of winning that would be a loss:

| Counter-metric | Catches |
|---|---|
| Per-band regression in any band DSP already handles | Band trading — the +190 retrain's failure |
| DSP-only path byte-identical | Accidental default-path change |
| Analysis wall-clock versus baseline | Buying accuracy with latency silently |
| Abstain rate | "Improving" accuracy by declining hard cases |
| Reference-gap delta | A gain that merely re-approaches a baseline we should already have |
| Non-DnB per-genre accuracy | ~~A style prior that helps DnB by hurting everything else~~ **RETARGETED 2026-08-05 (Story 12.2).** No style prior is built; the classifier FR-54 depends on is rejected (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`). The metric itself stays, and stays useful, because the mechanism that replaced FR-54 carries the same failure mode: FR-53's caller-declared bounds are a hard filter, so a DnB-shaped range set by a consumer can hurt everything else. Read this row as guarding **FR-53's opted-in path**, not a style prior. Story 12.1's impact report already emits the `perGenre` breakdown it needs |

**Explicitly not a success metric:** matching GiantSteps 537/661 standalone. FR-68 replaces it.

## 10. Cross-Cutting NFRs

- Swift 6 strict concurrency; all new public types `Sendable`.
- Zero third-party package dependencies; Apple system frameworks only.
- DSP-only output remains byte-identical, test-locked by the existing opt-out suite.
- All bulk numeric work through vDSP.
- Swift↔Python feature parity holds via the FNV checksum tripwire; any substrate change bumps `featureSetVersion`.
- Every accuracy-affecting change ships a per-track impact report.

## 11. Constraints and Guardrails

**Distribution.** Weights are never committed to the repository. Git LFS is unusable — SPM support merged to `main` only in March 2026, needs a toolchain no macOS 15 consumer has, and needs `git-lfs` on every consumer machine; without it the package builds and fails at runtime on pointer stubs. `.binaryTarget` accepts only XCFramework and artifactbundle and cannot carry a `.mlmodelc`. Apple's native mechanisms do not fit a library: on-demand resources are iOS-only; Background Assets needs an extension in the host app's bundle.

**A library owns none of** network policy, entitlements, cache location, or user consent. This is the structural reason delivery goes through the demo app.

**Corpus.** OA300 is private and never published or referenced outward. It stays an evaluation corpus; the stratified split (FR-59) is for octave testing, not training.

**Compute.** Cloud training is permitted. Reproducibility requirements (FR-65, parity tripwire) apply identically wherever training runs.

**Literature provenance.** Every literature claim traces to primary text. During Discovery a PDF summarizer fabricated a detailed and wrong answer — inventing a sigma value, a decode method, and accuracy figures. Summaries are not sources.

## 12. Public Surface and Dependency Policy

- `MLTechnique.evaluate(trace:)` is frozen (Story 4-5 DD #18); changes need a named story.
- Pre-1.0: breaking changes are permitted and preferred over compatibility shims. Backwards compatibility is not a goal.
- The 256-bin contract (FR-67) is public via `MLTechniqueError.binCountMismatch`.
- New public types require `Sendable`; diagnostic types also require `CustomStringConvertible`.

## 13. Risk and Mitigations

| Risk | Mitigation |
|---|---|
| A third work programme fails to produce a bundleable model | §6 stopping rule, enforced at two failures rather than three |
| Gains are annotation artifacts | FR-60 version tagging; FR-56 reference baseline on the same ruler |
| Corpus teaches contradictory metrical levels | FR-59 and FR-62 test and record the convention |
| Style prior overfits to DnB | ~~Non-DnB per-genre counter-metric (§9); reweight rather than hard-filter (FR-54)~~ **MITIGATION INVERTED, 2026-08-05 (Story 12.2).** Both halves have failed. The control names **FR-54, which is rejected** (see `_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`), so "reweight rather than hard-filter" names a mechanism that will not be built. Worse, its replacement, FR-53's caller-declared bounds shipped by Story 12.1, **is a hard filter by construction** (`epics.md:538`), which is the precise thing this row was written to avoid. The control is therefore inverted, not merely stale. What still holds: the non-DnB per-genre counter-metric in §9 remains the right instrument, and Story 12.1's impact report already carries a `perGenre` breakdown. What is unmitigated: nothing prevents a consumer from setting a DnB-shaped range and degrading non-DnB material; FR-53 answers this only by defaulting to today's bounds, so the *default* path is safe and the *opted-in* path is the caller's own risk to own |
| The 100-120 band is unreachable | Acknowledged — OA300 has one track there; sourcing is open (Q3) |
| Bin-schema change breaks BYOW consumers | FR-67 treats it as a public contract |
| Cloud training diverges from the Swift runtime substrate | Parity tripwire non-negotiable; the exact Epic 7 mistake |

## 14. Open Questions

**Q1 through Q8, Q10 and Q11 are resolved and struck through below, kept for the record.** **Q9 is answered but not closed** as of 2026-08-01: the analysis it asked for is done, and its best-supported reading is a hypothesis that only FR-59f's independent verification can turn into a label. Its *measurable* consequence for the corpus is settled and is carried into FR-59f. Q8, Q10 and Q11 closed 2026-07-29. (An earlier version of this line said "Four items remain live" and was stale from the day those three landed; a later version said "No item remains live", which was premature.)

- ~~**Q8.** Do the operator's OA300 hand-annotations go into **training**?~~ **RESOLVED 2026-07-29 (operator): yes.** Made affordable by Q10 — with the gate moved to the new corpus, training on OA300 no longer costs a gate arm.

  **It does cost something, and the PRD should not pretend otherwise: OA300 can no longer be reported as *external* validation.** Once its tracks are in training it is in-distribution, and a number produced from it measures fit, not generalization. Under Q10, OA300's role therefore collapses from "gate arm" to "training data plus an in-distribution sanity number", leaving **GiantSteps as the only genuine external-validation corpus** — and FR-69c.1 already questions whether GiantSteps is confirmatory at all, since it is the reference family's own training distribution. **Net effect: the epic has one external-validation arm, and it is a compromised one.** Recorded as a live risk in §13 rather than resolved here.

  Original question retained for the record: Raised during Discovery and never settled. It cannot be waved through on FR-59a.2's general partition rule, because OA300 is not only an evaluation corpus — it is one of the three **gate** corpora under FR-68. Training on any part of it makes its contribution to the 2-of-3 gate non-confirmatory, which is FR-69c item 1 applied to a second corpus. Only 23 of 82 tracks carry DAW-verified labels, so the volume on offer is small against a 1,534-track training set. **Blocks the first training run.**
- ~~**Q10.** Which corpora does the FR-68 gate actually run on?~~ **RESOLVED 2026-07-29 (operator): the new 258-track corpus is the gate; OA300 and GiantSteps are reported as external validation and do not gate.** The balanced corpus is the only arm that is band-uniform, single-convention, hand-verified, and partitioned from training by construction, so the decision rests there and the breadth signal stays visible without carrying decision weight.

  **This supersedes Q1.** Q1 settled a two-of-three rule across OA300, GiantSteps and Tony's split; that rule is now retired, and FR-69a's partial-conjunction correction goes with it since there is no longer a multi-corpus conjunction to correct. FR-68 and FR-69a are amended below. Q1's reasoning was sound for the corpora available at the time — F3 subsequently built a better one.
- ~~**Q11.** What does FR-68's "no regression" mean operationally?~~ **RESOLVED 2026-07-29 via statistical consult, verified independently. Answer: a deterministic benchmark tripwire — explicitly NOT a noninferiority test.**

  **Why not a noninferiority test.** At 43 tracks per band the data cannot support one. A zero-margin claim needs near-unanimous discordance: `d = 4` cannot pass at any split (one-sided `p` = 0.0625), `d = 7` needs 7:0 (`p` = 0.0078), `d = 9` needs 8:1 (`p` = 0.0195). Even in the best case — **zero** observed losses across all 43 — the exact one-sided 97.5% upper bound on the population loss rate is `1 − 0.025^(1/43)` = **8.2%**, or **3.54 track-equivalents**. So perfect data rules out a four-track regression and cannot rule out three.

  Ruling out a **one**-track margin at that confidence would need roughly **157 tracks per band**; a two-track margin, **78**. Both are far beyond the 43 the corpus supports. Writing a per-band noninferiority margin and calling it evidence that regression is excluded would be theatre.

  **What the gate says instead.** Predeclare which bands count as DSP-handled from the **locked DSP-only baseline, before any ensemble result is examined**, then apply a mechanical preservation rule to those bands only:

  > On the locked 43-track-per-band benchmark, a **DSP-handled** band is one predeclared from the DSP-only baseline with at least **30 of 43** correct. Automatic approval requires `gains ≥ losses` in every such band. Any band where `losses > gains` **blocks approval** pending documented track-level review and an explicit, recorded waiver. This is a descriptive benchmark tripwire, **not** evidence of population noninferiority.

  The 30-of-43 threshold is a policy choice, not a statistical one. What matters statistically is that it is declared before results are seen, that the trigger is mechanical, and that the claim is scoped to this benchmark rather than to future tracks.

  **Three riders.**
  1. **The review must have teeth.** A tripwire whose review has no owner, no required evidence, and no recorded waiver decision is as much theatre as the fake test it replaces.
  2. **Add a heterogeneity test as a second tripwire.** A system-by-band interaction test asks whether lift is uniform across bands. It would have caught the +32/−16 case overwhelmingly (`p` well below 10⁻⁶). It is **not** a substitute: it can reject merely because bands improve by differing amounts, and failing to reject does not establish that every band is safe.
  3. **Report both net and gross.** Net band change (`gains − losses`) can be zero while many previously-correct tracks are swapped for different correct ones. Where preservation matters, report `losses` on its own, and report regression relative to what DSP had solved — one lost track out of 36 correct is not one lost out of 1.

- ~~**Q9 — DEFERRED, not resolved.** What is the **~1.5x cluster of 222 tracks** in the non-Rekordbox pool? They may be genuine triplet-feel material, a tagging convention, or detector error.~~ **ANSWERED 2026-08-01 to the limit of what the data can support.** Full analysis in `_bmad-output/ml-training/q9-ratio-cluster-2026-08-01.md`; derived from the existing survey JSON, no decode and no listening.

  **What is measured.** Constant-width log-ratio bins show four modes: 1x, 1.33x, 1.5x, 2x. The 1.5x core holds 202 tracks at `[1.48, 1.52)`; the gap between the 1.33x and 1.5x modes holds 5. **The count is window-dependent** (240 / 222 / 202 / 176 across plausible windows, a ~27% spread) and 202 is used for consistency, not because it is privileged. A second mode of 86 tracks at ~1.33x was previously hidden in the old table's "other" bucket. Restricting to the largest directory, the 1,824 tagged tracks the detector places at `[165, 180)` carry tags in three modes: 79.8% below 100, 10.8% at 100-120, 8.9% at 160-180.

  **What is hypothesised, and is not a label.** **Two paired hypotheses, neither established:** that the 1.5x cluster is a tagging convention in which the tag sits at two-thirds of the tempo the detector reports, and that the 1.33x cluster is the mirror, with the detector displaced instead. **Neither can be established from the available data and neither is claimed as established.** Only the file tag and our own detector exist here; FR-59a.1 forbids treating a DSP-derived value as ground truth, and that rule binds this analysis. Two scalar BPM estimates also carry no rhythmic information, so "not a triplet phenomenon" is unproven. The detector places 84.2% of that directory at `[165, 180)` regardless of tag, so agreement within it is substantially base rate. **The falsification test is a blinded human or DAW annotation of stratified samples**, specified in the artifact. An earlier version of this entry asserted the direction as settled; that was an FR-59a.1 violation and is withdrawn.

  **What binds regardless of the hypothesis.** The band decomposition is arithmetic: **197 of the 262 tracks in the 100-120 tag band sit in the 1.5x class**, and only **27** of the band show a 1:1 tag/DSP relation. Removing a class is not verifying it, and 27 is not a bound on how many tracks are valid — **all 262 labels are unverified**, which is the point. What follows unconditionally is that **FR-59's uniform n = 43 is not yet established for any band**, and that this band carries the largest workload risk. What follows only *under* the hypothesis is that 100-120 rather than 140-160 becomes the binding constraint; that is a planning risk, not a measurement. This is the exposure the deferral predicted, in numbers.

  **One correction to this entry's own framing.** `robbyt_x-ray-120s` (true 174, reported ~115.6) is a separately-established instance of a detector two-thirds error, but its metadata is stripped, so it carries no file tag and no ratio, and it is **not** a member of the 1.33x class — analogous, not an instance. It is also not the 1.5x phenomenon. The AST notebook pair was not re-examined here.

- ~~**Q1.** Which corpus is primary for the ensemble-lift gate — OA300, GiantSteps, or Tony's held-out split? They disagree in composition and in annotation trustworthiness.~~ **RESOLVED 2026-07-28 (operator): no single primary. Lift must appear on two of the three, with no regression on the third.** Each is compromised as a sole gate: OA300 has the most trustworthy annotations but only 1 track in 100-120 and 41 of 82 in 160-175; GiantSteps has band coverage but crowdsourced labels; Tony's split is DnB-dominant. A lift visible on only one corpus is the failure mode FR-71 exists to catch. **Two caveats raised by the Q2 consult and not yet resolved — see FR-69c.**
- ~~**Q2.** What lift margin justifies bundling? FR-69 requires a number; none proposed.~~ **RESOLVED 2026-07-28 via statistical consult — see FR-69, FR-69a, FR-69b, FR-69c.** Headline: the original note's statistic was the wrong one, and a 2-track lift can never be statistically significant.
- ~~**Q3.** Where does 100-120 BPM material come from? OA300 has one track; Tony's corpus is DnB-dominant.~~ **RESOLVED 2026-07-28 (operator): mine the non-Rekordbox pool.** The Story 7.2 survey already covered ~4,700 files outside the Rekordbox collection and tiered them into `secondarySupervised` / `unsupervisedPool` / `reject`. The material is owner-held, so no new licensing question arises. **Two conditions attach — see FR-59a.**
- ~~**Q4.** If AS-5 holds, is the fix to re-label, exclude, or model the ambiguity explicitly?~~ **RESOLVED 2026-07-28 (operator): re-label to a single convention.** Conditional on AS-5 actually holding — FR-59 still runs first, and a refutation means no re-labelling is needed. Excluding the pairs was rejected because it would drop 59 of OA300's 82 tracks and destroy the corpus as a gate. **See FR-62a for what re-labelling costs.**
- ~~**Q5.** How does a style prior get its style? User-declared, metadata-derived, or classified — each has a different failure surface.~~ ~~**RESOLVED 2026-07-28 (operator): classified.** The prior derives style from a classifier rather than a caller-declared value or a file tag. This buys coverage with no caller input and no dependence on absent or wrong genre tags, and accepts a router-error failure surface plus a second model in the deployment path — the exact cost the 2026-06-09 roundtable cited when ranking genre-MoE last. **Consequence: FR-54 now carries a classifier dependency it did not have when written, and that deployment objection now applies to F1.** Recorded rather than smoothed over.~~ **REVERSED 2026-08-05 by Story 12.2 (`_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md`). This reverses an operator decision, recorded 2026-07-28.** The answer is now **caller-declared**, not classified, and the style-conditioned prior of FR-54 is not delivered. Basis for the reversal: FR-54a, written after Q5, names it as one of two available exits ("revisit Q5 in favour of the caller-declared option, which needs no model"), and the caller-declared option now exists in shipped code as `Options.tempoScanRange` and `Options.perceptualWindow` (Story 12.1, 2026-08-02), where in July 2026 it did not. The router-error failure surface and the second model in the deployment path, which Q5 accepted as costs, are not incurred. Q5's original resolution is retained above as the record of what was decided and why. The reversal path is section 8 of the decision artifact.
- ~~**Q6.** Does Epic 12 or Epic 13 own F1? Both charters claim the DSP octave levers. **Blocks F1.**~~ **RESOLVED 2026-07-28 (operator): Epic 12 owns F1.** F1 is the highest-evidence lever Discovery surfaced, needs no model and no retrain, and is testable against existing fixtures today, so keeping it here lets the epic produce value even if every ML lever fails. Epic 13's overlapping claim on the DSP octave levers is now a recorded duplication to settle when that charter is next opened; it no longer blocks F1.
- ~~**Q7.** Does the demo app expose a model-quality disclosure, and where?~~ **RESOLVED 2026-07-28 (operator): bundle the model card into the demo archive and link it from the about screen.** Reuses the relocated artifact rather than authoring a second accuracy claim, keeping one source of truth. **See FR-72a for the three gaps this leaves.**

## 15. Assumptions Index

| ID | Assumption | Risk if wrong |
|---|---|---|
| **AS-1** | The reference gap is real, not an artifact of annotation version or evaluation protocol | F2 collapses to a measurement fix and most of this PRD is unnecessary — which is why F2 is in the MVP |
| **AS-2** | Capacity is not the constraint | Non-Goals wrongly excludes the larger-backbone levers |
| **AS-3** | The ~33k parameter figure for the Böck TCN is accurate | Weakens but does not overturn AS-2; the Schreiber 82.1 comparison stands independently |
| **AS-4** | Ensemble lift is achievable where standalone parity was not | The bundle gate is unreachable and the epic ends at Gate 2 |
| **AS-5** | ~~OA300's 80-85 and 160-175 clusters are the same material at different metrical levels~~ **LARGELY CONFIRMED 2026-07-29 on independent evidence.** The non-Rekordbox pool shows the same pattern on **1,822 tracks** using a tag signal the DSP never saw: half-tempo tagging is the collection's dominant convention, not an error. Two qualifications — it is a different corpus from OA300, and octave *agreement* is not label *correctness*, so which metrical level to train toward remains open | Largely retired. FR-59's job narrows from "confirm or refute" to "confirm it holds for OA300 specifically, and record which level OA300 used" |
| **AS-6** | ~~Gaussian smearing is standard for tempo and helps~~ **REFUTED during Discovery.** TempoCNN uses one-hot; no tempo paper ablates smearing. Replaced by: ordinal targets help in the general literature and are worth testing here, unvalidated for tempo | FR-63 is exploratory rather than established — which is why it ships with its own ablation |
| **AS-7** | The SMC 2015 style-prior result transfers to our corpus and pipeline. **STILL UNTESTED as of 2026-08-05 (Story 12.2). ~~WEAKENED~~ was claimed earlier the same day and is withdrawn on external review.** The withdrawn claim rested on treating `_bmad-output/implementation-artifacts/12-1-tempo-range-impact-report.json` as "the first direct test" of the published result. **It is not a test of style-prior transfer at all.** It inferred no style, accepted no declared style, and conditioned nothing by style: one global window was applied to all 82 tracks regardless of genre. It also moved `Options.perceptualWindow`, the octave-*normalization* window, rather than `Options.tempoScanRange`, the pair that sizes the candidate *search* (the report's own `metric` field reads "only perceptualWindow moved"), and moved it to `100...200` rather than the published `130-180` (§4.3, `prd.md:101` as of 2026-08-05). **The published configuration has never been run on this pipeline.** The report's figures, kept here because they are what the earlier verdict cited, are overall `deltaAcc1 0` / `deltaAcc2 -3`, and `drum-and-bass` at n=67, `deltaAcc1 -1` / `deltaAcc2 -2`. They are evidence about globally narrowing the octave-fold window, which is a different assumption from the one AS-7 states. Full reasoning at `_bmad-output/implementation-artifacts/12-2-style-classifier-decision.md` §6.1 | F1 loses its evidence base and drops down the ranking. **Partially realized, and not by measurement:** F1's classifier half is rejected outright by Story 12.2, on a product-policy premise rather than on evidence against AS-7. Its range half shipped as FR-53. The assumption itself is untouched and the experiment that would settle it, `tempoScanRange` at `130...180` over the drum-and-bass rows, has not been run |
| **AS-8** | The demo app can carry weights without App Store review complications | Delivery needs rethinking; no fallback identified |
