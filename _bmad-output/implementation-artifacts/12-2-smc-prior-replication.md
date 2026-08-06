# SMC 2015 published-prior replication: results

Date: 2026-08-05, revised 2026-08-06 after a second external review
Branch: `rterhaar/12-2-smc-prior-replication`
Measurement revision: `7474bd3` (`713e42e` for the FR-14 conformant artifact)
Raw artifacts, same directory:
`12-2-smc-prior-replication-{oa300,giantsteps,tony}.json` plus
`12-2-smc-prior-replication-tony-fr14-conformant.json`

This document is self-contained. It assumes no prior context.

**What this tested, in one sentence.** A hard `Options.tempoScanRange` bound at the
published `130...180`, which is an **analogue** of SMC 2015's drum-and-bass prior: the
repository's only source for that prior is the phrase "DnB prior 130-180 BPM", which fixes
a range but not whether it was applied as a search constraint or as a candidate
reweighting. A negative result here bounds the hard-filter reading and leaves soft
reweighting untested.

**Revision note.** v1 reported a positive result on one of the three corpora and did not
reconcile its baseline against the committed corpus benchmark; v2 fixed both, and reversed
section 4 once label quality was controlled. v3 (2026-08-06) narrows three overclaims that
survived v2: that the experiment ran "on the correct knob", that the result is negative on
"all three corpora" unqualified, and that the Marginal tier was the most DSP-circular
slice — the artifact's own `labelProvenance` says the opposite. Section 10 names every
superseded claim across both revisions.

## 1. The question

Hoerschlaeger, Vogl, Boeck and Knees (SMC 2015, *Addressing Tempo Estimation Octave
Errors in Electronic Music*) report that genre-conditioned tempo priors lift
drum-and-bass Acc1 from 7.19% to 78.42% on GiantSteps, overall 45.5% to 75.0%, with no
model change. The published drum-and-bass prior is **130-180 BPM**. This is the strongest
published result cited anywhere in Epic 12, and PRD assumption AS-7 states that it
transfers to this project's corpus and pipeline.

It had never been tested here. Story 12.1 moved `Options.perceptualWindow` to
`100...200`. That is the wrong knob at the wrong values: `perceptualWindow` is the octave
**fold**, `tempoScanRange` is candidate **generation**, and neither `100` nor `200` is a
bound of the published prior. Story 12.2's decision artifact filed the correct experiment
as untested (section 6.2 item 1). This run is that experiment.

## 2. Method

Four arms, everything else at shipped defaults, measured through the full
`AudioAnalysisService.analyzeBPM` pipeline at 2% tolerance, `maxSeconds = 120` (which is
the shipped default).

| arm | label | `tempoScanRange` | `perceptualWindow` |
|---|---|---|---|
| A | baseline | 40...250 (shipped) | 60...200 (shipped) |
| **B** | **scan-only (PRIMARY)** | **130...180** | 60...200 (shipped) |
| C | scan+window | 130...180 | 130...260 (normalized, see section 8) |
| D | window-only | 40...250 (shipped) | 130...260 (normalized, see section 8) |

Arms run over the whole corpus. The analysis slices drum-and-bass against everything
else, because the DnB rows measure whether a declared range recovers octave errors and
the non-DnB rows measure what a blanket or mistaken declaration costs.

**Two scoring metrics are reported, and the difference matters.**

- **Octave-strict**: scored against the corpus's primary BPM annotation alone.
- **Floor-compatible**: scored the way the committed corpus benchmark scores, which for
  GiantSteps means a hit against *either* `bpm` or `tempo2`.

GiantSteps ground truth v2 carries `tempo2` on 577 of 661 rows. Of those, **303 are within
the 2% scoring tolerance of half the primary value and 58 within it of double** — under
literal equality the counts are only **100 and 23**. The tolerant pair is the operative
one, because the 2% MIREX matcher is what decides hits, but the distinction is not
cosmetic: an earlier version of this document called them "exactly half", which asserts
label identity where only scoring equivalence holds. Both pairs now ship in the artifact's
`tempo2Stats` block with their formulas.

The committed metric therefore already credits the octave alternative as correct on a large
minority of rows, which makes it close to blind to the phenomenon this experiment is about.
Octave-strict is the right instrument for the question; floor-compatible is what reconciles
against the repo's gates. OA300 and Tony have no second annotation, so for them the two
coincide.

Three corpora: **OA300** (82 tracks, 67 DnB), **GiantSteps** (661, 139 DnB, the corpus
SMC published on), and the **DnB slice of Tony's Rekordbox collection** (848 distinct
files). Tony carries important caveats; see section 6.

## 3. Results

`Δ` is against arm A on the same slice and metric.

### Drum-and-bass slice

| corpus | metric | n | A | B | Δ |
|---|---|---:|---:|---:|---:|
| OA300 | Acc1 | 67 | 48 | 46 | **−2** |
| GiantSteps | Acc1 strict | 139 | 111 | 110 | **−1** |
| GiantSteps | Acc1 floor | 139 | 129 | 126 | **−3** |
| Tony, all tiers | Acc1 | 848 | 713 | 757 | **+44** |
| **Tony, FR-14 conformant** | **Acc1** | **536** | **510** | **492** | **−18** |

### Non-DnB slice (cost of a blanket or mistaken declaration)

| corpus | metric | n | A | B | Δ |
|---|---|---:|---:|---:|---:|
| OA300 | Acc1 | 15 | 10 | 8 | −2 |
| GiantSteps | Acc1 strict | 522 | 355 | 251 | **−104** |
| GiantSteps | Acc1 floor | 522 | 408 | 300 | **−108** |

Tony has no reportable non-DnB slice; see section 6.

### Whole corpus

| corpus | metric | n | A | B | Δ |
|---|---|---:|---:|---:|---:|
| OA300 | Acc1 | 82 | 58 | 54 | −4 |
| GiantSteps | Acc1 strict | 661 | 466 | 361 | −105 |
| GiantSteps | Acc1 floor | 661 | **537** | 426 | −111 |

Arm C is identical to arm B on every slice of every corpus. Arm D is negative everywhere:
OA300 DnB −4, GiantSteps DnB −6 strict, Tony DnB −20.

## 4. The central finding

**The published lift does not reproduce anywhere. Once label quality is controlled, the
prior costs accuracy on all three corpora.**

Stated precisely, because the unqualified form is false at face value: the hard-bound
analogue is negative on **OA300**, on **GiantSteps**, and on the **FR-14-conformant Tony
slice**. All-tier Tony is **+44**, and that is the only positive number in the experiment.

It does not survive the repository's own label-quality rule. Filtering to
`truth_confidence >= 0.66`, the FR-14 rule that excludes the Marginal tier, reverses it to
**−18**. The gain was carried entirely by the 312 Marginal-tier rows, the least trustworthy
labels in the set — which under FR-14 is sufficient on its own to discount the +44.

~~and the ones whose truth was most influenced by this detector's own output~~
**WITHDRAWN 2026-08-06 (external review): the artifact's own `labelProvenance` contradicts
it.** The FR-14-conformant slice is DSP-influenced on **529 of 536 rows (98.7%)**, the
Marginal tier on **271 of 312 (86.9%)** — so Marginal is the *less* circular slice, not the
more. The accurate statement is that DSP circularity is **pervasive on both slices** and
**likely biases the comparison in favour of the baseline**, because the baseline detector
contributed to how the labels were formed. Its direction is arguable, its magnitude is not
independently measurable here, and the prevalence figures demonstrate prevalence, not bias
size. The consequence for reading this document: **Tony is a weak instrument in either
direction**, and the load-bearing negative evidence is OA300 and GiantSteps-strict.

Three supporting observations.

**There is little headroom to recover.** Baseline DnB Acc1 is already 71.6% on OA300,
79.9% strict and 92.8% floor-compatible on GiantSteps, and 95.1% on Tony's FR-14
conformant slice. SMC's *post-prior* figure is 78.42%. The GiantSteps baseline here
already meets or exceeds the published post-prior result before the prior is applied. SMC
measured against a detector with a drum-and-bass octave catastrophe (7.19% Acc1) that
this pipeline does not have.

**Casualty rate explains where the losses come from, but not the whole result.** Share of
DnB ground truth falling outside 130-180: OA300 25.4% (17 of 67), GiantSteps 12.2% (17 of
139), Tony 0.9% (8 of 848). A hard 130 floor makes those tracks' true tempo unreachable by
construction. The earlier version of this document read the low Tony casualty rate as the
explanation for a positive result there; the FR-14 sensitivity shows that reading was
wrong, and low casualty exposure is necessary but not sufficient for the prior to pay.

**Misdeclaration is expensive.** GiantSteps non-DnB Acc1 falls 355 to 251 strict, 408 to
300 floor-compatible, under the same configuration.

## 5. Mechanism, per track

Identical on all three corpora; only the ratio of gains to losses moves.

| corpus | arm B gained | arm B lost | net | changed rows | ratioClass over changed DnB rows |
|---|---:|---:|---:|---:|---|
| OA300 | 1 | 3 | −2 | 8 | 1.0 x3, 2.0 x2, 1.5 x1, other x2 |
| GiantSteps | 3 | 4 | −1 | 13 | 1.0 x6, other x4, 2.0 x2, 1.5 x1 |
| Tony, all tiers | 79 | 35 | **+44** | 165 | 1.0 x43, 1.5 x42, 2.0 x28, other x52 |

`ratioClass` buckets `armBPM / baselineBPM`, computed over **all changed DnB rows** — every
row whose BPM moved in at least one non-baseline arm — which is the `changed rows` column
and the same basis on all three corpora.

**Three different row sets, and they are easy to confuse.** On Tony: **165** rows changed
in at least one non-baseline arm; **114** of those are arm-B correctness flips (79 gained +
35 lost); the remaining **51** either changed only in arms C or D, or changed BPM without
crossing the correctness threshold. `79 + 35` is not meant to equal 165.

The Tony row is recomputed from the deduped artifact. The earlier version of this document
reported **84 / 36 / +48** over 883 pre-dedupe rows; deduping to 848 distinct files gives
79 / 35 / +44 (DnB Acc1 713 → 757).

**Losses are exact doublings of half-time truth.** Truth 86.0, baseline 85.9, arm B 173.2.
Truth 84.0, baseline 84.0, arm B 167.7. The 130 floor excludes the correct answer, so the
detector lands on the double.

**Gains are the half-octave recoveries the prior is meant to buy.** Truth 174.0, baseline
87.0, arm B 173.8. Truth 174.0, baseline 117.5, arm B 174.4.

The mechanism is real in both directions. What the experiment settles is the balance.

## 6. Tony corpus: three disclosures

The corpus carrying the only positive number needs all three read together.

**1. The truth is not detector-independent.** `tony-truth-labels.json` derives `bpm_truth`
by clustering five noisy signals, and one of them is `tony-dsp-prepass`, a run of this
same library. The winning truth cluster lists `dsp` among its sources on **800 of 848
distinct files, 94%** — and on the FR-14-conformant slice, **529 of 536, 98.7%**. Circularity
is therefore *pervasive on both slices*, and slightly worse on the conformant one, which
rules out reading the FR-14 filter as a way to escape it. (The Marginal tier alone is
271 of 312, 86.9%.)

Row selection is DSP-influenced, so the slice skews toward material where this detector
already agreed with the other signals. The direction of arm B's gains is partially
insulated, because a gain is a row where the baseline *disagreed* with truth and so the
label came from the Rekordbox side. But the denominator is not independent, the effect
**likely favours the baseline**, and its magnitude is not measurable from inside this
corpus. Prevalence figures show prevalence, not bias size. The aggregate should not be
read as a clean external check in either direction.

**2. Label tiers.** Of the 848 distinct files: **Strong 48, Solid 488, Marginal 312**.
Only 5.7% is Strong and 36.8% is Marginal, the tier FR-14 excludes from training. The
FR-14 conformant sensitivity run (`...-tony-fr14-conformant.json`) is the load-bearing
number, and it is negative.

**3. Duplicates.** The label file carries 883 DnB rows against only **848 distinct
files**; 35 were repeats and were being double-counted. The harness now dedupes by path
and reports the dropped count. The pre-dedupe figure was +48; deduped it is +44. The
earlier version of this document reported 883 and +48.

**Metrical-level caveat.** `bpm_truth` snaps to the Rekordbox value, itself a
metrical-level convention. If Rekordbox annotates half-time material at the fast level,
Tony's 0.9% casualty rate is a lower bound.

**Scope.** Roughly 4,700 further files live outside the Rekordbox `<COLLECTION>` and hold
more drum-and-bass. They are excluded deliberately: Story 7.2 tiered them precisely
because they carry no Rekordbox-validated BPM. 848 is the count with validated truth, not
the count of drum-and-bass tracks the operator owns.

## 7. What this does and does not establish

**Established.**

- **A hard `tempoScanRange` bound at the published `130...180` produces no drum-and-bass
  lift on any corpus once label quality is controlled.** ~~AS-7 does not hold as stated.
  The published configuration, run on the correct knob at the published values~~
  **CORRECTED 2026-08-06 (external review): "the correct knob" overclaims.** What the
  repository knows about SMC's prior is the summary phrase "DnB prior 130-180 BPM", which
  establishes a *range* and nothing about whether it was applied as a search constraint or
  as a candidate reweighting (`epics.md:2079` says so in those words). `tempoScanRange` is
  a hard filter by construction. **So this bounds the hard-filter reading of AS-7 and not
  the published mechanism** — read this bullet together with the first "not established"
  bullet below, not three bullets apart from it.
- A hard declared range is expensive when misapplied: GiantSteps non-DnB loses 104 to 108
  tracks depending on metric.
- **The committed GiantSteps metric is a poor instrument for octave questions**, because it
  accepts `tempo2`. Stated precisely: **361 of 661 rows carry a second annotation within
  the 2% tolerance of an octave relation** (303 half + 58 double). That is latent
  ambiguity, not realized score inflation — the metric's actual effect on arm A is **71
  tracks** (466 octave-strict against 537 floor-compatible), so 290 of the 361 never come
  into play here. ~~credits the octave alternative as correct on 361 of 661 rows~~
  **CORRECTED 2026-08-06: that read the exposure as the effect.** Anyone measuring octave
  behaviour on this corpus should report the strict metric alongside the floor one.

**Not established.**

- This does not refute SMC 2015. Their baseline detector and ours differ by roughly 70
  accuracy points on the same slice. A prior that rescues a broken detector need not help
  a working one.
- This does not test a **soft reweighting** prior. FR-54 specifies
  reweight-never-hard-filter, and `tempoScanRange` is a hard filter by construction.
  Whether soft reweighting would keep the octave recoveries without the half-time losses
  is untested and is the obvious follow-up.
- The published prior's own mechanism is unverified. The repository's only source is the
  phrase "DnB prior 130-180 BPM"; whether SMC constrained a search grid or weighted
  candidates would need the primary paper, and it determines which of arm B and the
  untested soft variant is the faithful replication.
- **Tolerance mismatch.** SMC's published figures are MIREX 4% tolerance; every number
  here is 2%. The direction favours the argument in section 4, since a stricter baseline
  still meeting their post-prior number is a stronger statement, but the comparison is not
  like-for-like.

## 8. Structural result: the fold knob cannot express this prior

Recorded before any track was analyzed. The published prior is **sub-octave**: 180 is less
than 2 x 130. `PerceptualTempoWindow` refuses to construct a sub-octave window,
normalizing `maxBPM` into `(2 * minBPM)...300`, so a requested `130...180` becomes
`130...260`. That is Story 12.1's DD3 fix working as designed, because `rangeNormalize`
runs two sequential loops with no re-check and a sub-octave window silently returned
values below its own stated minimum.

**Arms C and D therefore never tested the published prior.** Only `TempoScanRange`, whose
only span constraint is `minimumSpanBPM = 3`, can express it. Every arm records requested
and effective bounds plus a `normalized` flag.

## 9. Floor reconciliation

**There is no Story 12.1 regression.** `make benchmark-giantsteps` on this branch returns
**Acc1 537/661, Acc2 546/661**, exactly the committed floor.

The first version of this experiment reported arm A at 466/661 and did not reconcile it,
which is indistinguishable from a 13% default-path regression until someone re-runs the
benchmark. The entire 71-track gap is the `tempo2` second annotation described in section
2. The harness now scores both ways and **asserts** that arm A, scored floor-compatibly,
reproduces the committed number:

```
Floor reconciliation: arm A floor-compatible Acc1 58 (expect 58), Acc2 74 (expect 74)
Floor reconciliation: arm A floor-compatible Acc1 537 (expect 537), Acc2 546 (expect 546)
```

Both pass. The gate is permanent, so this ambiguity cannot recur silently.

## 10. What changed from the first version

| claim in v1 | status |
|---|---|
| Tony DnB +48, presented as the positive pole of a monotonic casualty-rate story | **Superseded.** Deduped to +44, and reversed to **−18** on the FR-14 conformant subset. The gain was carried by Marginal-tier labels. |
| "the sign of the outcome is decided by the metrical-level convention" | **Weakened.** Convention drives the casualty rate, but label quality drove the only positive result. Casualty exposure is necessary, not sufficient. |
| GiantSteps baseline 466/661 | **Incomplete.** Correct as octave-strict; the committed metric is 537/661. Both are now reported and reconciled. |
| Tony n = 883 | **Corrected** to 848 distinct files. |
| Tony truth described only with the Rekordbox convention caveat | **Extended.** The truth is also DSP-influenced on 94% of rows. |
| No tolerance note | **Added.** Ours is 2%, SMC's is 4%. |

Superseded again on 2026-08-06, after a second external review:

| claim in v2 | status |
|---|---|
| §4: the Marginal tier holds "the ones whose truth was most influenced by this detector's own output" | **Withdrawn — backwards.** `labelProvenance` puts the conformant slice at 529/536 (98.7%) DSP-inclusive against Marginal's 271/312 (86.9%). Circularity is pervasive on both, likely favours the baseline, and its magnitude is not measurable here. Tony is a weak instrument in either direction. |
| §5 Tony row: 84 gained / 36 lost / +48 | **Corrected** to 79 / 35 / **+44** from the deduped artifact, with the 165 / 114 / 51 row sets separated so `79 + 35` is not read against 165. |
| §2 and §7: `tempo2` rows "exactly half" / "exactly double" | **Corrected.** 303/58 hold only within the 2% scoring tolerance; literal equality gives 100/23. Both now ship in the artifact's `tempo2Stats`. The harness was writing the false wording into every artifact via `metricNote`. |
| §7: the metric "credits the octave alternative as correct on 361 of 661 rows" | **Corrected.** 361 is the *exposure* — rows carrying an octave-related alternative. The realized effect on arm A is **71 tracks** (466 strict vs 537 floor). |
| §7: "run on the correct knob at the published values" | **Narrowed.** SMC's application mechanism is unverified here, so this tests a hard-bound *analogue*. It bounds the hard-filter reading of AS-7, not the published mechanism. |
| "negative on all three corpora", unqualified | **Qualified.** Negative on OA300, GiantSteps, and the FR-14-conformant Tony slice; all-tier Tony is +44 but label-compromised. |

## 11. Provenance and reproduction

```
make smc-prior-replication
SMC_PRIOR_OUT_DIR=/tmp/x SMC_TONY_MIN_CONFIDENCE=0.66 make smc-prior-replication   # sensitivity
```

Release config. Requires `OA300_CORPUS_PATH`, `GIANTSTEPS_CORPUS_PATH`, `TONY_AUDIO_ROOT`,
and for the Tony arm the outputs of `make tony-corpus`. Override the prior with
`SMC_PRIOR_BOUNDS="<min>,<max>"`.

- **Measurement revision.** The three canonical artifacts were produced at `GIT_SHA`
  `7474bd3`, the FR-14 conformant one at `713e42e`. (v1 of this document reported `d6dd8a2`,
  the pre-regeneration revision.) A preflight rejects an unset, non-hex or dirty-tree SHA
  before the corpus loop, so an artifact's provenance always ties to code. It fired
  correctly twice during this work, blocking runs against uncommitted changes.
- **Input provenance.** `gitSHA` pins the code and nothing else, and two of the three
  corpora are unpinnable by it: GiantSteps ground truth is external to this repository, and
  the Tony labels are regenerated by `make tony-corpus`. Every artifact now carries an
  `inputProvenance` block with the basename and SHA-256 of each truth file it read
  (`giantsteps-tempo-ground-truth.json` = `3dc6f375…`; `tony-survey.json` = `55b283ce…`,
  `tony-truth-labels.json` = `b33b836a…`).
- **Regeneration check.** Re-running after the harness change moved no accuracy number:
  9,839 compared leaves across the three canonical artifacts, and 1,793 in the conformant
  one, are byte-identical once `gitSHA`, `wallClockSeconds`, `metricNote` and the two new
  blocks are excluded. `tempo2Stats` was verified against an independent recomputation from
  the ground-truth file, and each `inputProvenance` digest against `shasum -a 256`.
- Coverage: no corpus had missing audio. The per-arm identity
  `analyzed + nils + missing == ground truth` is asserted in-harness and held for every arm
  and corpus.
- Nils: zero in arms A, B and C on OA300 and Tony; GiantSteps B and C each 1. Arm D
  produces nils where B does not (OA300 2, GiantSteps 6, Tony 2), the fold window pushing
  tempi outside the untouched scan range.
- `git diff --stat -- Sources/` against the branch point is empty. No library code changed
  and no default moved. `make test` remains 993 tests in 168 suites, 4 known issues.

Harness: `Tests/BoomBoomBoomKitBenchmarkTests/TempoRangeImpactTests.swift`, suite
`SMCPriorReplicationTests`, env-gated behind `SMC_PRIOR_REPLICATION=1`.

Known minor issue: Tony track IDs are basenames, so two identically-named files in
different directories would collide in the per-track rows. Harmless at this corpus size,
worth a uniquifying prefix if the harness is reused.

## 12. Recommendations for whoever consumes this

1. **AS-7: mark TESTED as a hard search-range bound, and negative — but not resolved.**
   ~~mark TESTED, does not transfer as published. Not "refuted". The assumption as written
   is measured false on three corpora~~ **CORRECTED 2026-08-06 (external review): both
   halves overclaimed.** "Does not transfer as published" asserts the published mechanism
   was tested, and §7 says it was not — only its range, as a hard filter. "On three
   corpora" is false unqualified: all-tier Tony is +44. The supportable annotation is
   *tested as a hard `tempoScanRange` bound at `130...180`; negative on OA300, on
   GiantSteps, and on the FR-14-conformant Tony slice; unresolved for soft reweighting and
   for the published mechanism.* SMC itself is untouched either way, because their baseline
   had an octave catastrophe ours does not.
2. **The 12.2 reject is vindicated and sharpened.** The published configuration buys
   nothing anywhere and costs GiantSteps non-DnB over 100 tracks. A style classifier would
   have been machinery for automatically applying a prior that measures at best neutral
   and at worst catastrophic.
3. **Soft reweighting over a declared style is the one untested version of the idea.** It
   needs no classifier and is the only remaining path by which FR-54's mechanism could pay.
4. **This is direct evidence for Story 12.6.** Three corpora disagree with each other about
   the correct metrical level for the same genre, and the committed GiantSteps metric
   papers over the disagreement by accepting both.
5. **Independently: the GiantSteps floor metric deserves scrutiny.** Accepting `tempo2`
   means 361 of 661 rows *could* be scored correct at either octave, and 71 of them
   actually are on arm A. That is defensible for a general tempo benchmark and misleading
   for octave work, and no document in the repo said so before this one.
