# SMC 2015 published-prior replication: results

Date: 2026-08-05
Branch: `rterhaar/12-2-smc-prior-replication`
Measurement revision: `da6b0f1`
Raw artifacts: `12-2-smc-prior-replication-{oa300,giantsteps,tony}.json` (same directory)

This document is self-contained. It assumes no prior context.

## 1. The question

Hoerschlaeger, Vogl, Boeck and Knees (SMC 2015, *Addressing Tempo Estimation Octave
Errors in Electronic Music*) report that genre-conditioned tempo priors lift
drum-and-bass Acc1 from 7.19% to 78.42% on GiantSteps, overall 45.5% to 75.0%, with no
model change. The published drum-and-bass prior is **130-180 BPM**. This is the single
strongest published result cited anywhere in Epic 12, and PRD assumption AS-7 states that
it transfers to this project's corpus and pipeline.

It had never been tested here. Story 12.1 moved `Options.perceptualWindow` to
`100...200`. That is the wrong knob at the wrong values: `perceptualWindow` is the octave
**fold**, `tempoScanRange` is candidate **generation**, and neither `100` nor `200` is a
bound of the published prior. Story 12.2's decision artifact filed the correct experiment
as untested (section 6.2 item 1).

This run is that experiment.

## 2. Method

Four arms, everything else at shipped defaults, measured through the full
`AudioAnalysisService.analyzeBPM` pipeline at MIREX Acc1/Acc2, 2% tolerance,
`maxSeconds=120`.

| arm | label | `tempoScanRange` | `perceptualWindow` |
|---|---|---|---|
| A | baseline | 40...250 (shipped) | 60...200 (shipped) |
| **B** | **scan-only (PRIMARY)** | **130...180** | 60...200 (shipped) |
| C | scan+window | 130...180 | 130...260 (normalized, see section 7) |
| D | window-only | 40...250 (shipped) | 130...260 (normalized, see section 7) |

Arms run over the whole corpus. The analysis slices drum-and-bass against everything
else, because the DnB rows measure whether a declared range recovers octave errors and
the non-DnB rows under the same configuration measure what a blanket or mistaken
declaration costs. Neither slice is filtered out of the runs.

Three corpora:

- **OA300**, 82 tracks, private evaluation corpus, 67 labelled drum-and-bass.
- **GiantSteps**, 661 tracks, 139 labelled drum-and-bass. This is the corpus SMC 2015
  published on, so it is the like-for-like read.
- **Tony's Rekordbox collection**, drum-and-bass slice, 883 tracks with Rekordbox-validated
  BPM truth. Membership derived from on-disk filing rather than the XML `Genre` tag,
  which is empty on 1520 of 1721 rows. DnB slice only; see section 8.

## 3. Results

`Δ` is against arm A on the same slice.

### Drum-and-bass slice (the win the prior is supposed to buy)

| corpus | n | A Acc1 | B Acc1 | Δ | A Acc2 | B Acc2 | Δ |
|---|---:|---:|---:|---:|---:|---:|---:|
| OA300 | 67 | 48 | 46 | **−2** | 61 | 61 | +0 |
| GiantSteps | 139 | 111 | 110 | **−1** | 129 | 126 | −3 |
| Tony | 883 | 743 | 791 | **+48** | 782 | 791 | +9 |

### Non-DnB slice (the cost of a blanket or mistaken declaration)

| corpus | n | A Acc1 | B Acc1 | Δ | A Acc2 | B Acc2 | Δ |
|---|---:|---:|---:|---:|---:|---:|---:|
| OA300 | 15 | 10 | 8 | −2 | 13 | 8 | −5 |
| GiantSteps | 522 | 355 | 251 | **−104** | 397 | 287 | −110 |
| Tony | not reportable, see section 8 | | | | | | |

### Whole corpus

| corpus | n | A Acc1 | B Acc1 | Δ | A Acc2 | B Acc2 | Δ |
|---|---:|---:|---:|---:|---:|---:|---:|
| OA300 | 82 | 58 | 54 | −4 | 74 | 69 | −5 |
| GiantSteps | 661 | 466 | 361 | −105 | 526 | 413 | −113 |
| Tony (DnB only) | 883 | 743 | 791 | +48 | 782 | 791 | +9 |

Arm C is identical to arm B on every slice of every corpus. Arm D is negative everywhere:
OA300 DnB −4, GiantSteps DnB −6, Tony DnB −20.

## 4. The central finding

**The published lift does not reproduce, and the sign of the result tracks the ground-truth
metrical-level convention rather than the audio.**

| corpus | DnB n | DnB truth outside 130-180 | rate | arm B DnB Δ |
|---|---:|---:|---:|---:|
| OA300 | 67 | 17 | **25.4%** | −2 |
| GiantSteps | 139 | 17 | **12.2%** | −1 |
| Tony | 883 | 8 | **0.9%** | **+48** |

The relationship is monotonic. The corpora that lose are the ones annotating half-time
drum-and-bass at the slow metrical level, where a hard 130 BPM floor makes the true tempo
unreachable by construction. Casualty truth values: OA300 79.99 to 95, GiantSteps 83 to
127, Tony 107 to 190. Tony's Rekordbox truth annotates at the fast level, so the prior has
almost nothing to clobber and the octave recoveries all count.

Two supporting facts:

1. **There is little headroom to recover.** Baseline DnB Acc1 is already 71.6% on OA300,
   79.9% on GiantSteps and 84.1% on Tony. SMC's *post-prior* figure is 78.42%. The
   GiantSteps baseline here already exceeds the published post-prior result, so on that
   corpus the prior has nothing left to fix. SMC measured against a detector with a
   drum-and-bass octave catastrophe (7.19%) that this pipeline does not have.

2. **Even the positive case is not SMC-sized.** Tony's +48 tracks is 84.1% to 89.6%, a
   gain of 5.4 points. SMC reported a gain of roughly 71 points.

## 5. Mechanism, per track

The mechanism is identical on all three corpora. Only the ratio of gains to losses moves.

| corpus | arm B gained | arm B lost | net | ratioClass over changed DnB rows |
|---|---:|---:|---:|---|
| OA300 | 1 | 3 | −2 | 2.0 x2, 1.0 x3, 1.5 x1, other x2 |
| GiantSteps | 3 | 4 | −1 | 1.0 x6, 2.0 x2, 1.5 x1, other x4 |
| Tony | 84 | 36 | +48 | 1.5 x45, 1.0 x44, 2.0 x29, other x54 |

`ratioClass` buckets `armBPM / baselineBPM`.

**Losses are exact doublings of half-time truth.** Representative rows: truth 86.0,
baseline 85.9, arm B 173.2. Truth 84.0, baseline 84.0, arm B 167.7. The 130 floor
excludes the correct answer, so the detector lands on the double.

**Gains are the half-octave recoveries the prior is meant to buy.** Representative rows:
truth 174.0, baseline 87.0, arm B 173.8. Truth 174.0, baseline 117.5, arm B 174.4.

Casualty fate from arm A to arm B: OA300 `2 correct to incorrect`, `15 incorrect to
incorrect`. GiantSteps `17 incorrect to incorrect`. Tony `3 correct to incorrect`,
`2 correct to correct`, `3 incorrect to incorrect`.

## 6. What this does and does not establish

**Established.**

- AS-7 does not hold as stated on OA300 or GiantSteps. The published configuration, run
  on the correct knob at the published values, produces no drum-and-bass lift on either.
- A hard declared range is expensive when misapplied. GiantSteps non-DnB Acc1 falls 355 to
  251 under the same configuration.
- The outcome is dominated by ground-truth annotation convention, not by the audio or the
  detector.

**Not established.**

- This does not refute SMC 2015. Their baseline detector and ours differ by roughly 70
  accuracy points on the same slice; a prior that rescues a broken detector need not help
  a working one.
- This does not test a **soft reweighting** prior. FR-54 specifies reweight-never-hard-filter,
  and `tempoScanRange` is a hard filter by construction. Whether soft reweighting would
  keep Tony's +48 while avoiding the half-time losses is untested and is the obvious
  follow-up.
- The mechanism of the published prior is still unverified. The repository's only source
  is the phrase "DnB prior 130-180 BPM". Whether SMC constrained a search grid or weighted
  candidates would need the primary paper.
- Tony's casualty count is a **lower bound**. `bpm_truth` snaps to the Rekordbox value,
  which is itself a metrical-level convention. If Rekordbox annotates half-time material
  at the fast level, some Tony tracks are half-time in the audio and are simply not
  labelled that way.

## 7. Structural result: the fold knob cannot express this prior

Recorded before any track was analyzed.

The published prior is **sub-octave**: 180 is less than 2 x 130. `PerceptualTempoWindow`
refuses to construct a sub-octave window, normalizing `maxBPM` into `(2 * minBPM)...300`,
so a requested `130...180` becomes `130...260`. That is Story 12.1's DD3 fix working as
designed, because `rangeNormalize` runs two sequential loops with no re-check and a
sub-octave window silently returned values below its own stated minimum.

The consequence for this experiment is that **arms C and D never tested the published
prior**. Only `TempoScanRange`, whose only span constraint is `minimumSpanBPM = 3`, can
express it. Every arm in the artifacts records both requested and effective bounds plus a
`normalized` flag. Reading arm C or D as "the published prior on the fold window" would be
wrong.

## 8. Corpus notes

**Tony is DnB-only and its complement is not a non-DnB slice.** Of 1721 Rekordbox survey
rows, 1520 carry an empty genre string. Membership here is derived from on-disk filing
(`local_path` containing "drum and bass"), which identifies 901 rows, 883 of which carry
`bpm_truth` and resolve on disk. The complement of those directories is a mix of other
genres and unfiled material, not a labelled non-DnB set, so reporting a non-DnB cost from
it would measure filing habits rather than genre. The artifact carries
`nonDnbReportable: false` with that reason.

**Scope.** The collection holds more drum-and-bass than this. Roughly 4,700 further files
live outside the Rekordbox `<COLLECTION>` and are covered by `non-rekordbox-survey.json`.
They are deliberately excluded: Story 7.2 tiered them precisely because they carry no
Rekordbox-validated BPM, and this experiment needs trustworthy truth rather than volume.
883 is the count with validated truth, not the count of drum-and-bass tracks the operator
owns.

## 9. Provenance and reproduction

```
make smc-prior-replication
```

Release config. Requires `OA300_CORPUS_PATH`, `GIANTSTEPS_CORPUS_PATH`, `TONY_AUDIO_ROOT`,
and for the Tony arm the outputs of `make tony-corpus`. Override the prior with
`SMC_PRIOR_BOUNDS="<min>,<max>"`.

- `GIT_SHA` = `da6b0f1`. A preflight rejects an unset, non-hex or dirty-tree SHA before
  the corpus loop, so an artifact's provenance always ties to code.
- Wall clock: OA300 13.4s, GiantSteps 101.3s, Tony 122.7s, all four arms each.
- Coverage: no corpus had missing audio. The per-arm identity
  `analyzed + nils + missing == ground truth` is asserted in-harness and held for all 12
  arm and corpus pairs.
- Nils: zero in arms A, B and C on OA300 and Tony; GiantSteps B and C each 1. Arm D
  produces nils where B does not (OA300 2, GiantSteps 6, Tony 2), the fold window pushing
  tempi outside the untouched scan range.
- `git diff --stat 4ee7cfe -- Sources/` is empty. No library code changed and no default
  moved. `make test` remains 993 tests in 168 suites, 4 known issues.

Harness: `Tests/BoomBoomBoomKitBenchmarkTests/TempoRangeImpactTests.swift`, suite
`SMCPriorReplicationTests`, env-gated behind `SMC_PRIOR_REPLICATION=1`.

## 10. Open questions for whoever consumes this

1. Does a **soft reweighting** prior keep Tony's +48 without the half-time losses? This is
   the FR-54 mechanism that was never built, and it is now the only version of the idea
   this evidence has not tested.
2. Should AS-7 be marked **refuted** rather than untested? Two corpora say the published
   configuration does not transfer. The third says it transfers only where the annotation
   convention agrees with the prior, which is arguably a statement about labels rather
   than about the claim.
3. This is direct evidence for Story 12.6. Whether a lever looks like a win or a loss here
   is decided by the metrical-level convention, and three corpora disagree with each other
   about the same genre.
4. Does the SMC primary paper describe a search constraint or candidate reweighting? The
   answer changes which of arms B and the untested soft variant is the faithful replication.
