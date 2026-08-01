# Q9: the 1.5x cluster, and what it does to the 100-120 band

Develop-only analysis artifact. Answers **Q9** in the Epic 12 PRD (`prd.md:444`),
which recorded the ~1.5x cluster in the non-Rekordbox pool as unexamined and
deferred it to whoever executes FR-59b.

Source: `_bmad-output/ml-training/non-rekordbox-survey.json`, generated 2026-06-01
by `scripts/non-rekordbox-survey.py`. 4,766 tracks; **2,568** carry both a file tag
and a DSP estimate, 2,185 carry a DSP estimate with no tag, 13 carry neither. The
survey's DSP pass is metadata-blind (`dsp_metadata_blind: true`). No decoding, no
listening, and no re-run was needed.

Extends `non-rekordbox-band-feasibility-2026-07-29.md`, whose finding 5 named this
cluster as unexamined and whose finding 4 this artifact corrects.

## What this artifact can and cannot establish

**Read this before the findings.** The only two signals available are a human file
tag and our own detector's estimate. FR-59a.1 forbids treating a DSP-derived value
as ground truth, precisely because that turns an evaluation gate into a change
detector for the thing it tests. That rule binds this analysis too.

So: **the counts below are measurements; the causal reading is a hypothesis.** Two
scalar BPM numbers per track cannot establish which of them is right, cannot
establish whether a rhythm is triplet-feel, and cannot explain why a person typed a
particular number. Everything here is a prior about where to look and how much to
budget. **FR-59f's human verification is what produces labels**, and nothing in this
document should be used to decide which tracks a human gets to see.

Two evidence sources are excluded as circular and are not used below: `tier` and
`agreementAfterOctaveNormalization`. `tier` is a **perfect** function of the
agreement flag (2,172 `secondarySupervised` to True, 396 `unsupervisedPool` to
False), so both merely restate the tag/DSP relation under test.

## Findings that are measurements

### 1. There is a real peak near 1.5x, and a second near 1.33x

Constant-width bins on `log2(dsp/tag)`, 0.05 octaves, all bins with 10 or more
tracks:

| log2 | ratio | n |
|---|---|---|
| -0.05 | 0.966x | 14 |
| **+0.00** | **1.000x** | **338** |
| **+0.40** | **1.320x** | **76** |
| +0.45 | 1.366x | 11 |
| +0.55 | 1.464x | 16 |
| **+0.60** | **1.516x** | **207** |
| +0.65 | 1.569x | 12 |
| +0.95 | 1.932x | 14 |
| **+1.00** | **2.000x** | **1,784** |
| +1.05 | 2.071x | 24 |

Four modes: 1x, 1.33x, 1.5x and 2x. The gap between the 1.33x and 1.5x modes,
`[1.36, 1.45)`, holds **5** tracks across 0.0924 octaves, 54/oct, against the 1.5x
core's 5,250/oct. These are separate peaks, not one broad distribution.

**The count depends on the window and no window is privileged.** 240 at
`[1.40, 1.60)`, 222 at `[1.45, 1.55)`, 202 at `[1.48, 1.52)`, 176 at `[1.49, 1.51)`.
The PRD's 222 and the 202 used below are both defensible; the spread is ~27% and
should be quoted rather than resolved. **202 is used throughout for consistency, not
because it is more correct.** An earlier draft of this section called 202 "the
honest figure" and computed the shoulder density over `[1.30, 1.45)`, which is 86/91
the 1.33x peak. Both were wrong; the corrected shoulder makes the peak sharper, not
weaker.

### 2. The tag is multi-modal over material the detector reads as one tempo

Restrict to the 1,824 tagged tracks in the largest directory that the detector
places in `[165, 180)`:

| tag lands | n | share |
|---|---|---|
| <100 | 1,456 | 79.8% |
| 100-120 | 197 | 10.8% |
| 160-180 | 162 | 8.9% |
| 120-160 | 9 | 0.5% |

Three tag modes over a detector-homogeneous population. This is the strongest
structural observation available, and it is what the hypothesis below rests on.
It is **not** independent of the detector: the population is defined by where the
detector places tracks. It escapes the `tier` circularity, not the detector.

### 3. Class profiles

Medians. `tier` is omitted deliberately (circular, see above).

| class | window | n | tag med | DSP med | DSP conf med |
|---|---|---|---|---|---|
| 1x | [0.97, 1.03) | 352 | 170.0 | 170.1 | 0.885 |
| 1.33x | [1.30, 1.36) | 86 | 87.0 | 115.4 | 0.671 |
| 1.5x | [1.48, 1.52) | 202 | 115.0 | 172.0 | 0.836 |
| 2x | [1.94, 2.06) | 1,817 | 87.0 | 173.0 | 0.884 |
| other | remainder | 111 | 113.0 | 163.8 | 0.522 |

Detector confidence is reported as an observation. **It is not evidence of
correctness** — no calibration study establishes that 0.836 predicts a correct
reading or that 0.671 predicts this specific error direction.

### 4. Band decomposition, and the number that matters

Every tagged track by tag band, decomposed by ratio class:

| tag band | total | 2x | 1.5x | 1.33x | 1x | other |
|---|---|---|---|---|---|---|
| <100 | 1,996 | 1,816 | 4 | 72 | 57 | 47 |
| **100-120** | **262** | 1 | **197** | 4 | **27** | 33 |
| 120-140 | 52 | 0 | 1 | 7 | 36 | 8 |
| **140-160** | **43** | 0 | 0 | 3 | **32** | 8 |
| 160-175 | 102 | 0 | 0 | 0 | 95 | 7 |
| 175+ | 113 | 0 | 0 | 0 | 105 | 8 |

**This is arithmetic and does not depend on the hypothesis.** Two bands are exposed.

**100-120.** 197 of its 262 tagged tracks sit in the 1.5x class. Removing that class
leaves 65 — but "removing a class" is not "verifying". Of the 65, only **27** show a
1:1 tag/DSP relation, 33 fall in the lowest-confidence `other` class, 4 in 1.33x and
1 in 2x. **27 is below FR-59's per-band target of 43**, and **all 262 labels are
unverified** — 27 is not a lower bound on how many are valid, only the count that
two fallible signals happen to agree on.

Whether the band reaches 43 depends on human judgement of **every** class in it, not
just the 33 `other`. Any of the 197 could be genuine 100-120 material; so could the
4 at 1.33x and the 1 at 2x. Under a naive random draw with a keeper rate of 65/262,
reaching 43 keepers takes roughly 170 reviews — a budgeting scenario under an
unverified model, not a prediction, and it presumes the hypothesis.

**140-160 sits at exactly 43** and only 32 show a 1:1 relation; 3 are 1.33x and 8
`other`. Because FR-59 balances to the scarcest band, any rejection here lowers
uniform n for all six bands at once. Which of the 11 non-1x tracks a human rejects
is unknown — possibly none.

**What follows without the hypothesis: uniform n = 43 is not yet established for
either band**, because no label in either is verified. **What follows only with it:**
that 100-120 is the likelier constraint, ahead of 140-160. Treat the second as a
hypothesis-driven planning risk, not a measurement.

## The hypothesis, and how to kill it

**Best-supported reading: the 1.5x cluster is a tagging convention in which the tag
sits at two-thirds of the tempo the detector reports.** Supporting it: finding 2's
three-way tag split; the tags being quantized to 113/115/116/117 for 184 of the 202;
and 115 being close to two-thirds of the collection's modal 173.

**Everything weighing against it, stated plainly:**

- Every line of support except the tag quantization runs through the detector under
  test. Metadata blindness stops the detector copying the tag; it does not make
  either signal correct, nor their errors independent. A genre-conditioned bias
  shared by both is not excluded.
- The detector places **84.2%** of the largest directory (2,549 of 3,028) in
  `[165, 180)` regardless of tag. Two groups in that folder agreeing on ~172 is
  therefore substantially base rate. It is not vacuous — 145 tracks in the same
  folder are placed at `[108, 125)`, so the detector is not pinned — but it is much
  weaker than it first appears. An earlier draft called this evidence decisive; it
  is not, and the co-occurrence table has been removed rather than dressed up.
  95% of the cluster comes from a single broad directory, so it is one observation,
  not six.
- The 197 are not uniformly "~172": the spread is 158.7 to 178.0, p05 167.6,
  p95 175.3. The median supports "fast drum and bass", not "every track is 172".
- Integer BPM tags are ordinary metadata behaviour. Quantization shows a human typed
  a number; it does not show the number is wrong.
- **The mirror reading is weaker still.** The 86-track 1.33x cluster is described
  below as the detector erring, but the ratio alone cannot distinguish detector
  error, tag error, two valid metrical levels, or both wrong. Low confidence is not
  ground truth.
- **"Not a triplet phenomenon" is not established.** Two scalar tempo estimates
  carry no rhythmic information. Even if 115 were the wrong metrical label, that
  would say nothing about whether the material has a triplet feel.

**Falsification test.** Take stratified random samples from the 1.5x, 1.33x, 2x and
1x groups and give them to a blinded human or DAW-based annotator who sees no tag,
no detector output, no confidence and no cluster assignment, with the treatment of
halftime and metrically ambiguous cases declared in advance. The tagging-convention
reading fails if a material share of the 1.5x sample is judged near 115, ambiguous,
or triplet-dependent rather than near 172. The mirror reading fails if the 1.33x
sample is not judged near 173. A second automatic estimator is a weaker test than
annotation, because estimators may share the same fast-drum-and-bass attractor.

Separately worth testing: run this detector against independently verified drum and
bass spanning genuine 100-120 and 160-180. If it maps genuine slower material toward
~172, the base-rate confound above becomes fatal rather than merely limiting.

## The ~115 coincidence, downgraded

Three numbers sit near 115: the 1.5x cluster's tag median (115.0), the 1.33x
cluster's DSP median (115.4), and two-thirds of the collection's 173.0 (115.3).

**These are not three independent confirmations.** Defining windows at 1.5x and
1.33x over a collection concentrated near 173 induces the first two algebraically.
The observation worth keeping is structural and singular: **two distinct modes exist
at simple integer ratios of the collection's modal tempo, one reached by the tagger
and one by the detector.** That is one finding, not a convergence.

`AccuracyFloorTests`'s `robbyt_x-ray-120s` (true 174, reported ~115.6) is a
separately-established instance of a detector two-thirds error. Its metadata is
stripped, so it carries **no file tag and therefore no ratio**, and it is not a
member of the 1.33x class. It is analogous, and one fixture cannot establish
anything about 86 unrelated tracks.

## Consequences for the PRD

1. **Q9 is answered as far as this data can answer it.** The 1.5x cluster has a
   tagging-convention hypothesis strong enough to motivate annotation and to shape
   budget. **It does not retire the triplet alternative** — nothing here can, and a
   tagging convention could itself have arisen from a metrical or triplet reading of
   the material. §4 should carry the question as open, not as answered against
   triplets.
2. **The deferral's stated exposure was real.** The PRD said these tracks "shape
   which tracks are drawn and could bias selection before verification ever sees
   them." They dominate one band's draw pool at 75.2%.
3. **The 2026-07-29 artifact's finding 4 overstated its certainty.** It called
   100-120's scarcity a settled property of the collection on a tagged population of
   262. 197 of those are the 1.5x class and only 27 show a 1:1 relation. What that
   establishes is **greater uncertainty about the band, not a smaller true
   population** — "only 27 agree" is not "only 27 are valid".
4. **FR-59b's choice is narrower than it looked.** The 1.5x tags are not a third
   convention to choose among; under either half-tempo or full-tempo they need
   relabelling rather than reinterpreting — if the hypothesis holds.
5. **FR-59f's budget should change. Its selection must not, and ordering is safe
   only under a protocol the PRD does not yet state.** Sizing the annotation budget
   from aggregate `dsp/tag` statistics is defensible: being wrong costs reviewer
   time, nothing enters the corpus incorrectly.

   **Ordering the queue by `dsp/tag` is not automatically safe.** An earlier draft of
   this section said ordering "costs nothing if the hypothesis is wrong". That is
   false. If verification stops once 43 acceptable tracks are found, everything later
   in the queue is functionally excluded and the sort order has shaped the corpus —
   FR-59a.1 leakage with no explicit exclusion rule anywhere. It can also bias the
   reviewer if the sequence makes the clusters visible, and it burns the budget on a
   detector-chosen prefix.

   Ordering is safe only if all four hold: the candidate set is **fixed before** any
   DSP quantity is consulted; the **whole batch is annotated** regardless of order;
   the annotator is **blinded** to tag, DSP, confidence and cluster; and corpus
   membership is chosen **afterward** by a precommitted, DSP-independent rule.
   Without those, sort the queue at random.
6. **The 1.33x cluster is a detector lead, not a corpus finding.** 86 candidate
   instances of a two-thirds error, with `robbyt_x-ray-120s` as a verified analogue.
   That belongs to Epic 12's lever work, and it needs annotation before it is a
   result.

## Reproducing

```bash
uv run --no-project python - <<'PY'
import collections, json, math, statistics
d = json.load(open("_bmad-output/ml-training/non-rekordbox-survey.json"))
paired = []
for x in d["tracks"]:
    tag, dsp = x.get("fileMetadataBPM"), x.get("dspBPM")
    if isinstance(tag, (int, float)) and tag > 0 and isinstance(dsp, (int, float)) and dsp > 0:
        paired.append((dsp / tag, x))
print("paired:", len(paired))                                    # 2568

# Finding 1: constant-width histogram
h = collections.Counter(round(math.log2(r) / 0.05) for r, _ in paired)
print(sorted((round(b * 0.05, 2), n) for b, n in h.items() if n >= 10))
print("gap [1.36,1.45):", sum(1 for r, _ in paired if 1.36 <= r < 1.45))   # 5

# Finding 4: the 100-120 band
BANDS = {"2x": (1.94, 2.06), "1.5x": (1.48, 1.52), "1.33x": (1.30, 1.36), "1x": (0.97, 1.03)}
c = collections.Counter()
for r, x in paired:
    if 100 <= x["fileMetadataBPM"] < 120:
        c[next((k for k, (lo, hi) in BANDS.items() if lo <= r < hi), "other")] += 1
print(dict(c), "sum", sum(c.values()))
# {'other': 33, '1x': 27, '1.33x': 4, '1.5x': 197, '2x': 1} sum 262

# The confound: how concentrated is the detector in the largest directory?
import os
rows = [x for x in d["tracks"]
        if os.path.basename(os.path.dirname(x["path"])) == "Drum and Bass"
        and isinstance(x.get("dspBPM"), (int, float)) and x["dspBPM"] > 0]
inside = sum(1 for x in rows if 165 <= x["dspBPM"] < 180)
print(f"{inside}/{len(rows)} = {inside/len(rows)*100:.1f}%")      # 2549/3028 = 84.2%
PY
```

Bands are half-open `[lo, hi)` at 100 / 120 / 140 / 160 / 175, so 120.0 lands in
120-140. Regenerating the survey itself (slow, decodes the whole pool):
`make non-rekordbox-survey`, or `LIMIT=N` for a subset.
