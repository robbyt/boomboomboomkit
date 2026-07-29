---
title: 'Epic 12: Model-quality redesign — octave-aware BPM model'
status: draft
created: 2026-07-26
updated: 2026-07-27
---

# PRD: Epic 12 — Octave-Aware BPM Model

## 0. Document Purpose

Turns the Epic 12 charter (`epics.md:1796+`) into scoped, gated requirements.

It **supersedes the charter's lever ordering**. Discovery research (2026-07-26) invalidated the charter's central premise and two of its supporting claims. Section 4 records what changed and why.

## 1. Vision

BoomBoomBoomKit's ML tempo path ships nothing. Epic 7 closed BYOW after three retrains failed both bundle gates; two subsequent cheap fixes were measured and removed.

The charter assumed the remedy was a better or bigger model. **Discovery found that assumption wrong.** A published tempo model roughly ten times smaller scores about thirty-five points higher, and the published reference for *our own architecture family* scores about thirty points above ours. Capacity is not the constraint.

Discovery also found the strongest lever in the epic, and it is not a model at all: **style-conditioned tempo priors lifted drum-and-bass Acc1 from 7.2% to 78.4% in published work** on the same corpus we evaluate against. We have never tried it.

Epic 12 exploits that lever first, closes the reference gap second, and ships a small model inside the demo app only if it measurably improves the ensemble. If it does not after two serious attempts, the epic stops and says so.

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
| **Octave error** | Predicting 2× or ½ the true tempo. The dominant measured failure. |
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

- **PUBLISHED.** **TempoCNN does not use Gaussian smearing.** Schreiber & Müller ISMIR 2018 uses plain categorical cross-entropy on **one-hot** targets over 256 bins — identical to ours. "Add smearing because Schreiber does" is folklore and false.
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

Highest published evidence in the epic, needs no model, no retrain, and is testable against existing fixtures today. Overlaps #172, already filed.

- **FR-53.** Make the tempo search range consumer-specifiable. All four bounds are currently `private static let` on `BPMAnalyzer` and unreachable from `Options`.
- **FR-54.** Support a style-conditioned prior that reweights (never hard-filters) candidates by plausibility for a **classified** style (§14 Q5, settled 2026-07-28), defaulting to no prior so the default path stays byte-identical. The classifier is a dependency this FR did not carry when first written. It must abstain rather than guess: an unrecognized style degrades to no prior, never to a wrong one, because a wrong prior actively misleads the detector and is worse than none.
- **FR-55.** Measure per-band and per-genre against the four `AccuracyFloorTests` known-failure fixtures, all of which are DSP-path octave errors with no model involved.

*This lever is DSP-side and overlaps Epic 13. **Ownership settled 2026-07-28: Epic 12 owns it** (§14 Q6). The overlapping Epic 13 claim is a recorded duplication to settle when that charter is next opened, and no longer gates this work.*

### 5.2 F2 — Reference-gap diagnosis

No lever should be funded before we know why a published model in our own family scores thirty points higher.

- **FR-56.** Reproduce a published TempoCNN-family baseline end to end and score it on our evaluation path at our annotation version. Establishes whether the gap is ours or the ruler's.
- **FR-57.** Produce a written differential across every axis separating our pipeline from the reference — input representation and window policy, bin schema, loss, augmentation, corpus composition, decode, evaluation protocol — each labelled *suspect*, *neutral*, or *ruled out*, with evidence.
- **FR-58.** Rank the suspected causes by expected contribution and cost to test. **That ranking, not the charter's, drives everything after F2.**

### 5.3 F3 — Measurement integrity

Two independent results say our rulers are suspect: the ~6-point annotation-version swing, and a gate whose denominator is half one tempo band.

- **FR-59.** Build a band-stratified held-out octave test set from OA300, with the 80-85 / 160-175 pairs as their own sentinel group, and confirm or refute AS-5.
- **FR-59a.** Source 100-120 BPM evaluation material from the Story 7.2 non-Rekordbox pool (§14 Q3, settled 2026-07-28), subject to two conditions that are not optional:
  1. **Labels must be established independently of our DSP.** The 7.2 survey was deliberately BPM-tag-blind and its tiering leaned on our own detector. Promoting a DSP-derived value to ground truth would turn the 100-120 gate into a change detector for the thing it is meant to test — the same trap `FIXTURES.md` already guards against for the accuracy floor.
  2. **Contamination boundary with the gate corpus.** Tony's held-out split is one of the three gate corpora under FR-68. Material mined from the same collection must be partitioned so no track, remix, or artist appears on both sides; otherwise the 100-120 evidence and the gate stop being independent. `scripts/audit-corpus-splits.py` already enforces this class of check and must cover the new material.
- **FR-60.** Tag every reported accuracy figure with its ground-truth annotation version. Untagged historical figures are marked untagged, not assumed.
- **FR-61.** Report `Acc2 − Acc1` as a first-class metric alongside Acc1. It is the standard octave-error proxy and this epic is about octave errors.
- **FR-62.** Record the metrical-level labelling convention the project trains toward, and audit the training corpus against it.
- **FR-62a.** If FR-59 confirms AS-5, re-label the affected OA300 tracks to that single convention (§14 Q4, settled 2026-07-28). Three consequences, recorded because the decision was taken before the test reported:
  1. **Every historical accuracy figure on the old labels becomes incomparable.** FR-60's version tagging is what makes this survivable; it is a precondition of re-labelling, not a parallel task.
  2. **Re-labelling is irreversible in practice** once downstream artifacts are regenerated. Snapshot the pre-relabel ground truth as its own tagged version first.
  3. **It changes what the corpus teaches, not just what it scores.** If any re-labelled track has ever been used for training or model selection, the affected runs must be re-measured rather than carried forward.

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

- **FR-68.** Define the bundle gate as **ensemble lift**: DSP+ML beats DSP alone by a stated margin on **at least two of the three evaluation corpora, with no regression on the third** (§14 Q1, settled 2026-07-28), and with **no regression** in any band DSP already handles.
- **FR-69.** State the margin in tracks, not percentages. **Settled 2026-07-28 (§14 Q2) after a statistical consult. The original wording, struck below, was wrong in both its statistic and the conclusion drawn from it.**

  ~~Existing discipline is ≥2 OA300 tracks (1 track ≈ 1.2pp against a ~5pp standard error).~~

  The ~5pp figure is `sqrt(p(1-p)/n)` for a *single* proportion at n=82 — the standard error of one system's accuracy, not of the difference between two systems scored on the same tracks. The correct frame is **exact two-sided McNemar** on discordant pairs. With `b` = tracks the ensemble fixes, `c` = tracks it breaks, `d = b + c`, and net lift `t = b - c`, the equal-accuracy null is `b ~ Binomial(d, 0.5)`. The paired standard error is `sqrt(d)/n`, which beats 5pp only when `d` is small — so "both systems see the same tracks" is not on its own enough.

  **A 2-track net lift can never be significant.** The most favourable case, `d = 2` split 2:0, gives exact `p = 0.500`. The smallest significant result on any corpus is 6:0 (`p = 0.031`). Computed independently, not taken on report.

  The threshold depends on the discordance `d`, which has not been measured. Planning values at exact two-sided `p <= 0.05`:

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
- **FR-71.** Report per-band lift, never only an aggregate. The +190 retrain gained 120-140 and lost 140-160; an aggregate hid that.

### 5.7 F7 — Delivery

- **FR-72.** Ship weights inside the demo app archive (`make demo-archive`), never in the repository.
- **FR-72a.** Bundle the model card into the demo archive and link it from the about screen (§14 Q7, settled 2026-07-28). Three gaps this does not close:
  1. **The artifact is develop-only and written for developers.** It now lives at `_bmad-output/ml-models/MODEL_CARD.md`, which never ships to `main`. The demo archive is built from `develop` so bundling is mechanically fine, but `make demo-archive` must copy it in explicitly, and its register is internal — a demo user meets story references and corpus jargon unless an end-user summary fronts it.
  2. **It documents models that are not the shipped one.** It currently covers the withdrawn v1 and the failed v2 retrain. Whatever ships under F6 must be added before the archive is cut, or the bundled card describes something the user does not have.
  3. **A card is not a runtime signal.** It states what the model scored in aggregate; it cannot tell a user whether the model contributed to the number currently on screen. If that matters, it needs a per-result indicator, which this decision explicitly did not adopt.
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
- **AST-as-regression.** Rejected on head shape; an external notebook independently reproduced the predicted mean-collapse (71 BPM → 133.5, 89 → 129.2, MAE 20.2).
- **Expectation decoding.** Contraindicated for multimodal tempo posteriors.
- **Weights in the repository.** Non-negotiable (§11).
- **Re-litigating the two measured failures.** Closed.
- **A network-fetching library.** Out of scope entirely.
- **Input-representation redesign.** Deferred, not rejected — F2 may promote it.

## 8. MVP Scope

### 8.1 In Scope

**F1** (style prior), **F2** (reference-gap diagnosis), **F3** (measurement integrity), and the gate definition in **F6**.

Rationale: none needs a retrain, all are cheap relative to training, F1 carries the highest published evidence in the epic, and together they determine whether the rest is worth funding.

### 8.2 Out of Scope for MVP

F4 and F5 are gated on F2's findings. F7 cannot start until there is a model worth shipping.

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
| Non-DnB per-genre accuracy | A style prior that helps DnB by hurting everything else |

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
| Style prior overfits to DnB | Non-DnB per-genre counter-metric (§9); reweight rather than hard-filter (FR-54) |
| The 100-120 band is unreachable | Acknowledged — OA300 has one track there; sourcing is open (Q3) |
| Bin-schema change breaks BYOW consumers | FR-67 treats it as a public contract |
| Cloud training diverges from the Swift runtime substrate | Parity tripwire non-negotiable; the exact Epic 7 mistake |

## 14. Open Questions

- ~~**Q1.** Which corpus is primary for the ensemble-lift gate — OA300, GiantSteps, or Tony's held-out split? They disagree in composition and in annotation trustworthiness.~~ **RESOLVED 2026-07-28 (operator): no single primary. Lift must appear on two of the three, with no regression on the third.** Each is compromised as a sole gate: OA300 has the most trustworthy annotations but only 1 track in 100-120 and 41 of 82 in 160-175; GiantSteps has band coverage but crowdsourced labels; Tony's split is DnB-dominant. A lift visible on only one corpus is the failure mode FR-71 exists to catch. **Two caveats raised by the Q2 consult and not yet resolved — see FR-69c.**
- ~~**Q2.** What lift margin justifies bundling? FR-69 requires a number; none proposed.~~ **RESOLVED 2026-07-28 via statistical consult — see FR-69, FR-69a, FR-69b, FR-69c.** Headline: the original note's statistic was the wrong one, and a 2-track lift can never be statistically significant.
- ~~**Q3.** Where does 100-120 BPM material come from? OA300 has one track; Tony's corpus is DnB-dominant.~~ **RESOLVED 2026-07-28 (operator): mine the non-Rekordbox pool.** The Story 7.2 survey already covered ~4,700 files outside the Rekordbox collection and tiered them into `secondarySupervised` / `unsupervisedPool` / `reject`. The material is owner-held, so no new licensing question arises. **Two conditions attach — see FR-59a.**
- ~~**Q4.** If AS-5 holds, is the fix to re-label, exclude, or model the ambiguity explicitly?~~ **RESOLVED 2026-07-28 (operator): re-label to a single convention.** Conditional on AS-5 actually holding — FR-59 still runs first, and a refutation means no re-labelling is needed. Excluding the pairs was rejected because it would drop 59 of OA300's 82 tracks and destroy the corpus as a gate. **See FR-62a for what re-labelling costs.**
- ~~**Q5.** How does a style prior get its style? User-declared, metadata-derived, or classified — each has a different failure surface.~~ **RESOLVED 2026-07-28 (operator): classified.** The prior derives style from a classifier rather than a caller-declared value or a file tag. This buys coverage with no caller input and no dependence on absent or wrong genre tags, and accepts a router-error failure surface plus a second model in the deployment path — the exact cost the 2026-06-09 roundtable cited when ranking genre-MoE last. **Consequence: FR-54 now carries a classifier dependency it did not have when written, and that deployment objection now applies to F1.** Recorded rather than smoothed over.
- ~~**Q6.** Does Epic 12 or Epic 13 own F1? Both charters claim the DSP octave levers. **Blocks F1.**~~ **RESOLVED 2026-07-28 (operator): Epic 12 owns F1.** F1 is the highest-evidence lever Discovery surfaced, needs no model and no retrain, and is testable against existing fixtures today, so keeping it here lets the epic produce value even if every ML lever fails. Epic 13's overlapping claim on the DSP octave levers is now a recorded duplication to settle when that charter is next opened; it no longer blocks F1.
- ~~**Q7.** Does the demo app expose a model-quality disclosure, and where?~~ **RESOLVED 2026-07-28 (operator): bundle the model card into the demo archive and link it from the about screen.** Reuses the relocated artifact rather than authoring a second accuracy claim, keeping one source of truth. **See FR-72a for the three gaps this leaves.**

## 15. Assumptions Index

| ID | Assumption | Risk if wrong |
|---|---|---|
| **AS-1** | The reference gap is real, not an artifact of annotation version or evaluation protocol | F2 collapses to a measurement fix and most of this PRD is unnecessary — which is why F2 is in the MVP |
| **AS-2** | Capacity is not the constraint | Non-Goals wrongly excludes the larger-backbone levers |
| **AS-3** | The ~33k parameter figure for the Böck TCN is accurate | Weakens but does not overturn AS-2; the Schreiber 82.1 comparison stands independently |
| **AS-4** | Ensemble lift is achievable where standalone parity was not | The bundle gate is unreachable and the epic ends at Gate 2 |
| **AS-5** | OA300's 80-85 and 160-175 clusters are the same material at different metrical levels | FR-59's sentinel group measures something other than what it claims |
| **AS-6** | ~~Gaussian smearing is standard for tempo and helps~~ **REFUTED during Discovery.** TempoCNN uses one-hot; no tempo paper ablates smearing. Replaced by: ordinal targets help in the general literature and are worth testing here, unvalidated for tempo | FR-63 is exploratory rather than established — which is why it ships with its own ablation |
| **AS-7** | The SMC 2015 style-prior result transfers to our corpus and pipeline | F1 loses its evidence base and drops down the ranking |
| **AS-8** | The demo app can carry weights without App Store review complications | Delivery needs rethinking; no fallback identified |
