# Story 12.6: Metrical-level convention and the ground-truth rule

Date: 2026-08-08. Status: DRAFT RECOMMENDATION, pending operator signoff (section 6).
Nothing in this document binds until the signoff block is checked. This artifact
declares; it does not build. No track is drawn, labelled, or re-labelled here
(corpus construction is Story 12.7).

Authority: prd.md FR-59b (line 185), FR-59f (lines 196-219), FR-62 (line 230),
epics.md Story 12.6 ACs (lines 2202-2240). Settled operator decisions transcribed,
not re-litigated: FR-59f option 1 (human verification, 2026-07-29); six bands kept
(2026-08-01); N_BAND = 43, N_EVAL = 258 (constants table, prd.md lines 165-175).

---

## 1. Convention declaration (FR-59b)

**Recommended: the full-tempo (perceptual) metrical level.** One level for every
track in the 258-track corpus: the tempo a human counts as the beat of the track
at its primary pulse, which for the drum-and-bass material that dominates all
three sources is the 160-180 BPM reading, not the 80-90 half-time reading. How
genuinely ambiguous tracks are recorded is fixed by the faster-level tie-break
rule in section 2; the flag is data, the primary value follows the convention.

This is a recommendation. The operator may overturn it in section 6; until signed,
no convention exists and Story 12.7 cannot start.

### Evidence from the two independent populations

Two populations, independent of each other, both show the collection's own tagging
convention is half-tempo, and both show the band distribution is a property of the
convention rather than of the music (prd.md feasibility resolution, lines 233-262):

1. **Pool third-party file tags** (non-Rekordbox pool, 2,568 tag-carrying tracks):
   the DSP estimate is ~2x the tag for 1,822 tracks against 357 at ~1x; 71% of
   tagged tracks are tagged at half tempo. By tag the pool is 78% sub-100; by DSP
   it is 65% at 160-175, over identical files (prd.md finding 2, line 260;
   non-rekordbox-band-feasibility-2026-07-29.md).
2. **Tony's own Rekordbox entries** (1,344 banded rows, three-source census): as
   entered, 889 tracks band below 100 and zero at 160-175. Octave-corrected, 36
   band below 100 and 786 at 160-175. Same files, two near-mirror distributions
   (three-source-band-census-2026-08-01.md, census table and finding 4).

**Caveat, which travels with every citation of the octave-corrected column (36
below 100 / 786 at 160-175): that column's octave came from a cluster vote our
detector participated in, so it describes the convention and does not establish
which level is right; only the as-entered column (889 below 100) is
FR-59a.1-clean** (epics.md Story 12.6 AC 2; census, "half independent" note).

### Why full-tempo, argued both ways

For full-tempo:

- **Comparability with the detector's output space.** The shipped perceptual
  window is 60-200 BPM (`PerceptualTempoWindow.default`), and the detector reports
  drum and bass in the 160-180 region. A half-tempo corpus would score the
  detector against 80-90 labels for material it reports at ~172, converting every
  correct full-tempo detection into a scored octave error and making Acc1 measure
  the convention gap, not the model (the exact failure FR-59e names for training).
- **Comparability with every legacy figure.** OA300's labels sit at full tempo (41
  of 82 in [160, 175), measured against the tracked fixture; section 4), GiantSteps
  bands 153 of 661 at 160-175 (prd.md F3 table, lines 150-157), and the Tony truth
  labels resolve to the full-tempo octave (786 at 160-175; section 4, with the
  FR-59a.1 caveat: that octave-corrected column came from a cluster vote our
  detector participated in, so it is evidence of what the corrected convention
  looks like, not evidence for which level is right). Under half-tempo, every
  historical Acc1/Acc2 figure becomes incomparable with the new corpus even with
  annotation-version tagging; under full-tempo the tag guards against
  label-content drift rather than a wholesale level flip. The pro-full-tempo case
  therefore rests on the FR-59a.1-clean populations (OA300 fixture, GiantSteps v2)
  plus the detector-comparability and band-design arguments, not on the corrected
  Tony column.
- **Band viability.** Under half-tempo the corpus collapses into the sub-100 band:
  the pool bands 78% sub-100 by tag, and Tony as entered is 889-of-1,344 sub-100
  with zero at 160-175. Several of the six bands (160-175 especially) would have
  almost no material at the declared level, so the band-balanced design itself
  presumes something close to the full-tempo level.
- **The verification precedent.** The DAW-oracle workflow (the FR-59f option 1
  precedent, 23 verified OA300 tracks) produced full-tempo values (e.g. the
  `robbyt_x-ray-120s` truth of 174). Hand-verification by beat placement in a DAW
  naturally lands at the counted pulse.

Against full-tempo (stated so the operator overturns with the evidence in hand):

- **The only FR-59a.1-clean population is half-tempo.** The as-entered Rekordbox
  column (889 below 100) and the 71% pool tag figure are the detector-independent
  measurements, and both say the collection's owners write half-tempo. Declaring
  full-tempo means nearly every as-entered tag in the scarce sub-100 material must
  be octave-adjusted during verification; the tag becomes a hint, never a value to
  transcribe.
- **Hand-verification workload.** Under full-tempo the annotator resolves an
  octave decision on most tracks rather than confirming a tag. This is real work,
  but it is exactly the work FR-59f option 1 exists to do: the blinding protocol
  (section 2) means the annotator never sees the tag anyway, so the workload
  difference between conventions is smaller than it first appears.
- **Interpretive honesty.** "The level a human counts" is itself a judgement for
  halftime-feel material. This is an interpretation, not a measurement; the
  sentinel subset (section 3) is what keeps the old ambiguity measurable, and the
  ambiguity flag above keeps it visible inside the new corpus.

What adopting half-tempo instead would change: the draw pools invert (sub-100
becomes the deepest band and 160-175 nearly empties), every legacy corpus figure
becomes cross-convention, the detector's default output would need folding to
sub-100 before scoring, the section-2 faster-level tie-break inverts (the slower
level of a 2:1 pair becomes primary), and the 100-120 band's Q9 contamination
question changes
shape (a 115 tag over ~172 material could become convention-conformant rather
than suspect). Neither corpus is wrong; they are different corpora from the same
files (prd.md finding 2, line 260). The recommendation is full-tempo because the
corpus exists to measure the detector and the detector's world is full-tempo.

---

## 2. Ground-truth rule (FR-59f, option 1 operationalized)

The settled method is **FR-59f option 1: human verification of the entire balanced
set** (operator, 2026-07-29; prd.md line 200). Every track counts as ground truth
only after hand verification; no file tag, no DSP estimate, and no second
estimator ever becomes a label. This rule is recorded with the corpus and does not
change once the first track is verified.

### Workflow

1. **Fix the candidate set per band before any DSP quantity is consulted.** The
   draw pool for each of the six bands is enumerated from FR-59a.1-clean signals
   only: candidate pools are banded by the as-entered tag value taken at face
   value, and by nothing else. No ratio class, no DSP estimate, and no `dsp/tag`
   quantity is consulted to assign, infer, or correct a tag's metrical level at
   pool-construction time. A tag whose metrical level is unknown or absent is
   banded at face value too. Level resolution happens only through human
   verification. A track whose verified tempo lands in a different band than its
   pool may enter that band ONLY through that band's normal random replacement
   draw from its committed candidate set; it never bypasses the set. The list is
   committed before verification begins.
   All six band boundaries are half-open [lo, hi) at every edge (100, 120, 140,
   160, 175); this applies to pool banding, keep/reject band checks, and the
   sentinel-subset windows alike.
2. **Commit a batch, then annotate the entire batch** regardless of queue position
   or of reaching 43 keepers early. A batch is committed as an ordered list (its
   committed draw order), which the surplus-keeper and duplicate rules below
   read. If a batch will not be completed, its queue is
   randomized and the budget spent on breadth (prd.md FR-59f (c), line 217).
3. **Verify by the DAW-oracle precedent** (`scripts/dawproject-bpm.py` workflow):
   the annotator places the beat grid by ear in a DAW and reads the tempo off the
   grid, at the declared metrical level.
4. **Choose corpus membership after annotation**, by the precommitted keep/reject
   rule below, which reads no DSP output.

### Blinding mechanics

During annotation the annotator sees the audio and nothing else. Specifically
blinded, per the four safe-ordering conditions (prd.md FR-59f (c), lines 210-217;
q9-ratio-cluster-2026-08-01.md consequence 5):

- the file tag and any embedded BPM metadata;
- the DSP estimate;
- the DSP confidence;
- the ratio class / cluster assignment from Q9.

Operationally: verification runs off a worklist that carries only an opaque row ID
and an audio path; tags and survey fields are stripped from the annotator's view
and rejoined only after the batch is annotated. Queue ordering by any `dsp/tag`
quantity is permitted only because all four conditions above hold in substance:
candidate set fixed first, whole batch annotated, annotator blinded, membership
decided afterward by a DSP-free rule. If any condition cannot be met, the queue is
randomized instead.

### Per-band order

**100-120 is verified first.** The reason is workload, not scarcity: Q9 places 197
of the band's 262 pool labels in the 1.5x ratio class with only 27 at 1:1
(q9-ratio-cluster-2026-08-01.md finding 4), so this band carries the highest
expected rejection-and-replacement churn and should surface its true keeper rate
before the budget is spent elsewhere. The former "verify 140-160 first" scarcity
rationale is void: that band holds 430 across the three sources, not 43
(three-source-band-census-2026-08-01.md finding 1; prd.md FR-59f (a), line 206).
After 100-120: 175+ (the other pool-sourced scarce band, and the one whose
near-degeneracy is recorded), then the remaining four in any order.

### Keep/reject criteria (precommitted, DSP-free)

A verified track is **kept** when all of the following hold:

- The DAW grid locks to a stable tempo across the annotated span; drift or a
  mid-track tempo change is a reject (a track without a single ground-truth BPM
  cannot serve, the continuous-mix principle).
- The verified tempo, at the declared metrical level, falls inside the track's
  assigned band. A track that verifies into a different band is rejected from this
  band's draw (it may be recorded as a candidate for the band it verified into,
  but band reassignment is a Story 12.7 bookkeeping decision, not a relabel).
- The annotator did not flag the track as metrically irresolvable. Ambiguous but
  resolvable tracks are kept with the ambiguity flag (section 1).
- The audio is intact and not a duplicate/re-encode of a track already kept
  (FR-59a.2 contamination boundary; `scripts/audit-corpus-splits.py` class of
  check).

No DSP quantity appears in any criterion. Agreement or disagreement with the
detector is never a reason to keep or reject.

### Faster-level tie-break (named protocol rule)

When verification finds a track genuinely ambiguous between two metrical levels
related by a 2:1 ratio, the annotator records the faster level as primary and
flags the ambiguity. The rule applies ONLY to 2:1 pairs. If the perceived pulse
relates to the candidate levels by a non-2:1 ratio, the annotator records the
counted pulse verbatim and flags the track ratio-ambiguous. If the operator
overturns the convention to half-tempo (section 6 amendment path), this
tie-break inverts: the slower level of a 2:1 pair becomes primary.

### Annotated span

The annotator verifies the full track. No fixed-excerpt policy is in effect; if
one is ever adopted it must be stated here by amendment and applied uniformly to
every track in the corpus.

### Batch mechanics: surplus keepers and duplicates

- **Surplus-keeper selection.** The entire committed batch is annotated (safe-
  ordering condition 2), so a batch can yield more than 43 keepers. The kept 43
  are taken in the batch's committed random draw order; keepers beyond 43 in that
  order are recorded as verified surplus, not corpus members.
- **Duplicate tie-break.** When duplicates of one recording co-occur in a batch,
  the earlier row in the committed draw order is kept and the other rejected as
  duplicate.

### Blinding residual (stated limitation)

Blinding is per-track only. The annotator (the operator) has read this protocol
and carries a band-level prior, for example the Q9 1.5x ratio composition of the
100-120 pool. This residual is accepted and noted, not solved.

### Replacement rule

A rejected track is **replaced from within its own band's precommitted candidate
pool**, drawn at random from the not-yet-verified remainder. The census surplus
figures (every band clears 43; scarcest is 175+ at 140, or 104 on the strictly
independent banding; three-source-band-census-2026-08-01.md finding 1; prd.md
finding 1 supersession, line 258) were computed on the census's own legacy/mixed
banding basis; under the declared full-tempo convention the per-band pool sizes
are NOT yet re-established, so those figures bound the workload expectation
rather than guarantee it. **Exhaustion rule:** if a band's precommitted pool
exhausts before 43 keepers, that band HALTS and escalates to the operator, who
either widens the source by a named order or shrinks the corpus by decision.
Keep criteria are never silently relaxed. Uniform n stays 43; the corpus never
shrinks below 258 except by operator decision.

### Budget

Baseline budget: 258 verifications plus replacement churn. For 100-120, the
one-keeper-in-four scenario is carried: under Q9's tagging-convention hypothesis a
tag-trusting draw yields roughly one keeper in four, so reaching 43 keepers takes
on the order of 170 reviews (prd.md FR-59f (b), line 208). **This is a
hypothesis-derived scenario carried so the budget is not set at 43 and then blown;
it is not a measured rejection rate**, and all 262 labels in that band are
unverified. Plan roughly 170 slots for 100-120. The other five bands' budgets are
unestimated: no sourced keeper-rate figure exists for them, and none is invented
here; each is sized only after its first completed batch measures a keeper rate.
**Re-plan checkpoint:** after each band's first completed batch, the observed
keeper rate is compared with the assumption used to size that band's budget, and
the operator (owner) decides re-plan at that checkpoint. The trigger is the
checkpoint itself; no divergence threshold is defined. The scale risk stands as
recorded: the DAW-oracle precedent produced 23 verified tracks, an order of
magnitude below 258, so the effort figure is an estimate, not an extrapolation
from experience (prd.md line 202).

### 175+ measurement note (recorded, not re-litigated)

The operator kept six bands (2026-08-01). The census finding is recorded with the
rule so a flat 175+ result is not later read as a fast-tempo measurement: 130 of
the band's 140 tracks sit within 175-179, non-separable from 160-175 at the ±4%
Acc1 tolerance, with three to five genuinely above-180 tracks in the collection
(three-source-band-census-2026-08-01.md finding 2; prd.md FR-59f (a), line 206).

---

## 3. Sentinel subset (`octave-sentinel`): the [80, 87.5) / [160, 175) pairs

Declaring one convention makes AS-5's both-halves-as-ground-truth property a fact
about the old corpora, not the new one. To keep the old ambiguity measurable, the
80-85 / 160-175 material is retained as a **tagged subset, not collapsed**
(FR-59b, prd.md line 185; epics.md Story 12.6 AC 4).

**Membership rule (DSP-free):** a corpus track belongs to the `octave-sentinel`
subset (that identifier, used everywhere in this document and in the manifest)
when EITHER direction of the octave pair holds:

- its human-verified tempo at the declared convention falls in [160, 175) AND at
  least one FR-59a.1-clean legacy label for the same recording (the OA300 fixture
  value, or an as-entered tag) falls in [80, 87.5); or
- its human-verified tempo falls in [80, 87.5) AND a legacy label for the same
  recording falls in [160, 175).

The reverse direction is included because the old ambiguity was two-sided: AS-5
treated both halves as ground truth. The [80, 87.5) window is the halves of
[160, 175); it is a recorded deviation that widens the "80-85" phrase used
elsewhere (prd.md line 185 and the census prose), adopted so the half window is
exactly half of the full-tempo band. "Same recording" means an audio-fingerprint
match per the `scripts/audit-corpus-splits.py` fingerprint, with exact-filename
match as the fallback where no fingerprint is available. The rule reads the
verified tempo and legacy static labels only; no DSP output, confidence, or
ratio class participates. If no track satisfies the rule, the subset is recorded
as size 0; an empty subset is a result, not a failure.

**Verified counts in the legacy material** (measured 2026-08-08 against the
tracked `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json`,
82 entries): 18 tracks below 100 BPM, of which 13 within [80, 85] and 16 within
the 80-89 decade; 41 tracks within [160, 175). prd.md line 121 states this as
"`<100` = 18 (clustered 80-85)" and "160-175 = 41"; the 18 and 41 verify exactly,
and "clustered 80-85" is accurate as a cluster description (13 strictly inside,
the rest of the 18 adjacent). The three-source census bands the same fixture as
14 / 44. The below-100 delta (18 vs 14) is NOT explained by band edges: a
half-open edge at 100 cannot remove four sub-100 rows. It remains an
unreconciled row-basis difference between the fixture and the census, flagged
for Story 12.7 to reconcile via the `scripts/audit-corpus-splits.py` fingerprint
join before the sentinel roster is built. Both figures are anchored, and the
fixture count above is the one this subset definition uses. Which specific pairs
land in the subset is determined by Story 12.7's verification, not here; this
section fixes the rule, not the roster.

**Tagging:** subset membership is recorded per track in the corpus manifest as
`sentinel: octave-sentinel`, alongside the corpus-level annotation-version tag
(section 5). The subset is reported per band and never dropped from aggregates.

---

## 4. FR-62 legacy audit (prd.md line 230)

Which metrical-level convention each legacy corpus follows. Recorded for
interpretation of historical figures; **no OA300 track is re-labelled in place**
(FR-62a struck, superseded by FR-59b, prd.md line 231), and no other legacy
artifact is modified by this audit.

| Legacy corpus | Convention its labels follow | Evidence anchor |
|---|---|---|
| OA300 (82 tracks, private) | **Full-tempo (perceptual), with the AS-5 ambiguity embedded**: 41 of 82 in [160, 175) and 18 below 100 clustered near 80-85, plausibly the same octave annotated at both levels (prd.md line 122, untested inference). The bulk of the corpus sits at the full-tempo level. | Tracked fixture `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` (counts measured 2026-08-08: 82 / 41 / 18); prd.md lines 121-122; 23 DAW-verified entries at full tempo (daw-oracle precedent, prd.md line 197). |
| GiantSteps Tempo (664 tracks, v2 crowdsourced annotations) | **Full-tempo (perceptual)**: the v2 re-annotation (Schreiber, Urbano and Muller, TISMIR 2020) targets the perceptually dominant tempo. The band-profile evidence (60 below 100, 153 at 160-175, 309 at 120-140) covers the 661 FR-18-strict scored rows, not all 664 tracks in the dataset; it shows fast material labelled fast, not folded to half. | prd.md F3 table lines 150-157; prd.md line 117 (re-annotation swing); corpus at `GIANTSTEPS_CORPUS_PATH`, annotation source per Story 12.4's FR-18-strict protocol. |
| Tony truth labels / training manifests | **Full-tempo after octave resolution, but the octave is detector-influenced**: `bpm_truth` takes its value from the Rekordbox entry and its octave from a cluster vote our detector participates in. Measured against the gitignored labels file (counts only): 1,509 of 1,534 labelled; bands 36 / 26 / 253 / 372 / 786 / 36, matching the census octave-corrected column. The training manifests built from these labels therefore train toward the full-tempo level, with the FR-59a.1 caveat: the octave assignment is not detector-independent, and the as-entered Rekordbox column (889 below 100) shows the collection's own convention is half-tempo. | three-source-band-census-2026-08-01.md (census table, "half independent" note, finding 4); labels file referenced by counts per the privacy rule; `_truth_value_from_winner` behaviour per the census. |

Consequence recorded: every historical accuracy figure on these labels carries the
convention of its corpus via its annotation-version tag (Story 12.3, FR-60), which
is what makes the new corpus's single declared convention survivable rather than
silently confusing (prd.md FR-60, line 228).

---

## 5. Annotation-version tag

The convention's tag under Story 12.3's scheme
(`Sources/BoomBoomBoomKitTestSupport/AnnotationVersion.swift`) follows one
naming rule, stated once for the primary recommendation, the half-tempo
fallback, and any third convention: `metrical-<level>-v1-<signoff-date>`, where
the date component is the operator SIGNOFF date, minted at signing. The string
below carries this document's draft date and is a draft value; it is re-dated at
signoff.

```
declared:metrical-full-tempo-v1-2026-08-08
```

**Validator execution record:** on 2026-08-08 the draft tag value was executed
through the validator, not merely inspected. A throwaway Swift Testing test
(deleted after running; `git diff --stat` against `Sources/`/`Tests/` clean)
called `AnnotationVersion.declared("metrical-full-tempo-v1-2026-08-08")` and
asserted the rendered tag equals the string above and that
`AnnotationVersion(parsing:)` round-trips it; the same assertions ran for
`metrical-half-tempo-v1-2026-08-08`. The test passed (`swift test --filter
ThrowawayTagValidationTests`, 1 test, passed). Because the date component
changes at signoff, the signed tag value must be re-run through
`AnnotationVersion.declared(_:)` at minting; the character class (lowercase
letters, digits, hyphens) is unchanged by a date substitution, so no new failure
mode is expected.

If the operator overturns the recommendation in section 6, the value becomes
`metrical-half-tempo-v1-<signoff-date>` under the same naming rule; the `v1`
component identifies the first declared convention either way, and any later
convention change mints a new tag rather than reusing this one. The 258-track
corpus's ground-truth file declares this tag; figures scored against it carry it
per FR-60.

**Dependency risk:** the tag validates against Story 12.3's scheme as committed
on this stacked branch (commits 0fb914b/4b66b75, re-signed 2026-08-08, not yet PR-reviewed).
If 12.3's validation rules change in PR review, the tag must be re-validated
before corpus load.

---

## 6. Operator signoff

- [ ] **Operator signoff: the metrical-level convention and ground-truth rule are adopted as written above.**

Signing binds:

1. **The convention** (section 1): full-tempo (perceptual) as the single metrical
   level for the 258-track corpus, or the operator's substituted choice, recorded
   here by amendment before checking the box.
2. **The entire section-2 protocol**, explicitly including: the four safe-ordering
   conditions (candidate set fixed before any DSP quantity is consulted; the
   entire committed batch annotated; the annotator blinded to tag, DSP estimate,
   confidence, and ratio class; membership decided afterward by a precommitted
   DSP-free rule); the face-value pool-construction rule; the per-band
   verification order (100-120 first); the batch rule and the batch mechanics
   (surplus-keeper selection, duplicate tie-break, annotated span); the
   faster-level tie-break; the keep/reject criteria; the replacement and
   exhaustion rules; and the blinding mechanics with the stated blinding
   residual.
3. **The budget** (section 2): 258 verifications plus churn, with roughly 170
   reviews planned for 100-120 under the hypothesis-derived one-keeper-in-four
   scenario, other bands unestimated until their first completed batch, and the
   per-band re-plan checkpoint.

Changing any of the bound items mid-verification requires a dated amendment to
this document and re-signoff before verification continues.

Dependency risk carried into signing: the section-5 tag validates against Story
12.3's scheme as committed on this stacked branch (commits
0fb914b/4b66b75, signed, not yet PR-reviewed); if 12.3's validation rules change in PR
review, the tag must be re-validated before corpus load.

Until signed, all of the following stay open: no convention exists, no candidate
set may be committed, no track may be verified or labelled, Story 12.7 cannot
start, and the tag in section 5 names a recommendation rather than a rule. The
sentinel-subset rule (section 3) and the FR-62 audit (section 4) are descriptive
and carry no gate, but the subset rule references the declared convention and so
also floats until signing fixes it. Per epics.md Story 12.6's final AC, this story
cannot close on agent work alone; its run status is `blocked` on this signoff.
