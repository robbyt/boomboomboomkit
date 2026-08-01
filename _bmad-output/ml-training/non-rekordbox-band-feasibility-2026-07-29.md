# Non-Rekordbox pool: band feasibility and a measured labelling convention

Develop-only analysis artifact. Answers the feasibility risk recorded in the Epic 12
PRD's F3: **can the ~4,700-file non-Rekordbox pool supply roughly 27 tracks in each
BPM band, so the evaluation corpus can be balanced to the scarcest band?**

Source: `_bmad-output/ml-training/non-rekordbox-survey.json`, generated
2026-06-01 by `scripts/non-rekordbox-survey.py` from
`/Users/rterhaar/Dropbox/tony-tunes/05092026.xml`. 4,766 analyzable tracks, 4,753
with a DSP estimate, 2,568 carrying an independent `fileMetadataBPM` tag. The
survey's DSP pass is metadata-blind by construction (`dsp_metadata_blind: true`),
so the tag and the DSP estimate are genuinely independent signals.

No re-run was needed; the existing survey already covers the whole pool.

## Headline

**Feasibility: yes.** Every band clears 27 tracks on the highest-confidence subset.
But the more important result is why the question was hard to answer at all.

**The pool is tagged at half tempo for 71% of tagged tracks.** The DSP estimate is
~2x the tag for 1,822 of 2,568 tagged tracks. Only 357 agree at ~1x.

That single fact means **the pool's band distribution is not a property of the
music. It is a property of which metrical convention you adopt.**

## The two distributions

Banding the same 2,568 tagged tracks two ways:

| Band | by independent tag | by our DSP (all 4,753) |
|---|---|---|
| <100 | **1,996** (78%) | 122 |
| 100-120 | 262 | 217 |
| 120-140 | 52 | 163 |
| 140-160 | 43 | 195 |
| 160-175 | 102 | **3,094** (65%) |
| 175+ | 113 | 962 |

These are not two views of a disagreement at the margins. They are near mirror
images, and they are describing the same files.

## Why: the collection tags drum-and-bass at half tempo

Ratio of DSP estimate to tag, across all 2,568 tagged tracks:

| ratio | tracks | reading |
|---|---|---|
| **~2x** | **1,822** | DSP hears full tempo, tag records half |
| ~1x | 357 | agreement |
| ~1.5x | 222 | ~~triplet relationship, a separate phenomenon~~ **CORRECTED 2026-08-01: best-supported reading is a tagging convention at two-thirds of true, not a triplet. A hypothesis, not a label — the data cannot settle it. See `q9-ratio-cluster-2026-08-01.md`.** |
| other | 164 | ~~—~~ **CORRECTED 2026-08-01: contains a structured 86-track cluster at ~1.33x, hypothesised as the mirror of the row above. Which signal is displaced is not established — the ratio alone cannot separate detector error, tag error, two valid metrical levels, or both wrong.** |
| ~0.5x | 3 | negligible |

**Window-width caveat, added 2026-08-01.** The windows above are of unequal width
(~5.5%, ~6%, ~5%, ~3.3%), so these counts are not density-comparable and the
"other" bucket hid structure. **The 1.5x count is window-dependent and no window is
privileged:** 240 at `[1.40, 1.60)`, **222** at `[1.45, 1.55)` as used above, **202**
at `[1.48, 1.52)`, 176 at `[1.49, 1.51)` — a spread of 26.7%. The Q9 artifact quotes
202 for internal consistency and says explicitly that this is a choice, not a
correction. An earlier version of this caveat said the count "is 202, not 222",
which turned a sensitivity result into a corrected population count.

Cross-tabulated, the effect is concentrated in one cell:

| tag band \ DSP band | <100 | 100-120 | 120-140 | 140-160 | 160-175 | 175+ |
|---|---|---|---|---|---|---|
| **<100** | 65 | 72 | 26 | 24 | **1,529** | 280 |
| 100-120 | 2 | 28 | 6 | 7 | 190 | 29 |
| 120-140 | 1 | 3 | 34 | 1 | 6 | 7 |
| 140-160 | 0 | 0 | 19 | 14 | 5 | 5 |
| 160-175 | 2 | 3 | 1 | 4 | 89 | 3 |
| 175+ | 1 | 2 | 3 | 0 | 36 | 71 |

1,529 tracks are tagged below 100 BPM and estimated at 160-175. That is
drum-and-bass tagged at ~87 and detected at ~174 — the same music, two metrical
levels, recorded consistently enough across 4,766 files to be a convention rather
than an error.

## This confirms AS-5, on independent evidence and at scale

The PRD's AS-5 says OA300's 80-85 and 160-175 clusters are *plausibly* the same
material annotated at different metrical levels, and marks it **UNTESTED**, with
FR-59 designed to confirm or refute it on 59 OA300 tracks.

The pool answers the same question on **1,822 tracks**, using a tag signal the DSP
never saw. The pattern AS-5 hypothesises is not merely present; it is the dominant
convention of the collection.

Two qualifications, because this is evidence *about the collection*, not proof
about OA300:

1. **Different corpus.** These are Tony's non-Rekordbox files, not OA300. The two
   are drawn from the same musical world and the same owner, which is why the
   result is relevant, and also why it is not a substitute for FR-59.
2. **Octave agreement is not label correctness.** `agreementAfterOctaveNormalization`
   is true for 2,172 tracks, meaning tag and DSP agree *once the octave is collapsed*.
   That establishes the two signals describe the same periodicity. It does not
   establish which metrical level is the right one to train toward. Choosing that is
   exactly what FR-59b has to do.

## Feasibility against the 27-per-band target

Highest-confidence subset — tracks carrying an independent tag **and** where the DSP
agrees after octave normalization — banded by the tag:

| Band | available | vs target of 27 |
|---|---|---|
| <100 | 1,873 | ample |
| **100-120** | **28** | **clears by 1** |
| 120-140 | 36 | clears by 9 |
| 140-160 | 32 | clears by 5 |
| 160-175 | 97 | ample |
| 175+ | 106 | ample |

**The target is achievable, but 100-120 has effectively no margin.** One track of
slack means any label rejected on review drops the band below target and forces the
uniform n down for every other band with it.

100-120 is also the band where tag and DSP disagree most in absolute terms: 262
tagged tracks in the band, but only 28 where the two signals agree — 234 disagree.
Every other band has a far higher agreement rate. So 100-120 is both the scarcest
band and the one whose labels are least corroborated, which is unfortunate given it
is the band the model genuinely mis-pulses (E0: Acc2 equals Acc1 at 1/35, so octave
tolerance recovers nothing there).

~~**100-120 scarcity is not an artifact of convention.** It is thin under the tag
banding (262) and under the DSP banding (217). Unlike the <100 / 160-175 pair, this
band does not move when the convention changes. The collection genuinely contains
little material there.~~

**SUPERSEDED 2026-08-01.** This section treated the band's scarcity as a settled
property of the collection. It is not settled either way, and the 262 does not mean
what was claimed. **197 of those 262 sit in the ~1.5x class**, and 27 show a 1:1
tag/DSP relation — **below the per-band target of 43**. Removing the 1.5x class
leaves 65.

**What that does and does not establish.** It establishes **greater uncertainty
about this band, not a smaller true population.** All 262 labels are unverified;
"only 27 agree" is not "only 27 are valid", and any of the 197 could be genuine
100-120 material. Under the Q9 tagging-convention hypothesis the band is the most
likely place the corpus shrinks — but that is a hypothesis-driven planning risk, not
a measurement. What follows unconditionally is that uniform n = 43 is not yet
established here. See `q9-ratio-cluster-2026-08-01.md`.

## What this means for the PRD

1. **The feasibility risk in F3 is resolved: the 27-per-band target is buildable**,
   from owner-held material, with no sourcing outside the collection.
2. **FR-59b's convention choice is now the load-bearing decision**, not a
   formality. The band distribution — and therefore which bands are scarce and how
   large the balanced corpus can be — follows from it. Declaring half-tempo and
   declaring full-tempo produce different corpora from identical files.
3. ~~**100-120 should be treated as the binding constraint** on uniform n, with a
   review margin planned in. At 28 available for a 27 target there is none.~~
   **RETRACTED 2026-08-01.** The 28-for-27 figures came from a selection filter
   FR-59a.1 forbids and were withdrawn by the PRD; the corrected constants are 43
   per band and 258 overall. The verdict is also stated too strongly: which band
   binds is hypothesis-dependent, and no label in any band is verified. Read this as
   "100-120 carries the largest workload risk and should be drawn and verified
   early", not as a settled constraint.
4. **AS-5 should be restated.** It is no longer an untested inference. It is
   confirmed as the collection's convention on independent evidence, and FR-59's job
   narrows from "confirm or refute" to "confirm it holds for OA300 specifically, and
   record which level OA300 used".
5. ~~**The ~1.5x cluster (222 tracks) is unexamined.**~~ **EXAMINED 2026-08-01 —
   `q9-ratio-cluster-2026-08-01.md`.** Best-supported reading is a tagging
   convention at two-thirds of true rather than a triplet relationship, offered as
   a hypothesis with a stated falsification test, not as a label. A second mode of
   86 tracks at ~1.33x, previously hidden in "other", is its mirror. Both sit near
   115 BPM, two-thirds of the collection's modal 173.

## Reproducing

```bash
python3 - <<'PY'
import json, collections
d = json.load(open("_bmad-output/ml-training/non-rekordbox-survey.json"))
ratios = collections.Counter()
for x in d["tracks"]:
    tag, dsp = x.get("fileMetadataBPM"), x.get("dspBPM")
    if not isinstance(tag, (int, float)) or not isinstance(dsp, (int, float)) or tag <= 0:
        continue
    r = dsp / tag
    for name, lo, hi in (("~0.5x",.45,.55),("~1x",.94,1.06),("~2x",1.9,2.1),("~1.5x",1.45,1.55)):
        if lo <= r < hi:
            ratios[name] += 1
            break
    else:
        ratios["other"] += 1
print(ratios.most_common())
PY
```

Regenerating the survey itself (slow, decodes the whole pool):
`make non-rekordbox-survey`, or `LIMIT=N` for a subset.
