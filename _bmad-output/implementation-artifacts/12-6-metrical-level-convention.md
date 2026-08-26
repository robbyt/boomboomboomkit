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

Revised 2026-08-08 after a second-reader protocol review, pre-signoff; the
independence architecture is unchanged, the operational rules below are pinned
tighter.

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
   pool-construction time. A track with no tag value is EXCLUDED from the banded
   candidate pools: face-value banding requires a value. The per-band exclusion
   counts are recorded with the candidate set. A tag whose numeric value is
   present but whose metrical level is unknown is banded at the numeric face
   value; that is the point of face-value banding. Level resolution happens only
   through human verification.
   **FR-59a.2 at candidate construction:** tracks matching the training
   manifests by audio fingerprint (`scripts/audit-corpus-splits.py` precedent),
   by recording identity, or by artist string are excluded from the draw pools
   before commitment, and the exclusion counts recorded.
   A track that verifies outside its pool's band is REJECTED from its band and
   is NOT reassigned anywhere in this corpus version; the verified tempo is
   retained as data. The list is committed before verification begins.
   All six band boundaries are half-open [lo, hi) at every edge (100, 120, 140,
   160, 175); this applies to pool banding, keep/reject band checks, and the
   sentinel-subset windows alike.
2. **Two named orders per band, separately recorded.**
   (a) The **membership draw sequence**: one global per-band random permutation
   of the committed candidate set, generated by a recorded seeded PRNG, fixed
   before any DSP quantity is consulted. Batches are consecutive spans of this
   sequence; batch size is an operator convenience, default 40, recorded per
   batch, and membership never depends on batch boundaries. Corpus membership is
   the first 43 tracks in this global sequence whose annotation passes
   keep/reject, cumulative across batches. The same sequence governs
   surplus-keeper selection and duplicate tie-breaks.
   (b) The **annotation work order** within an already-committed batch, which
   MAY be sorted by any `dsp/tag` quantity per FR-59f (c) because membership is
   already frozen; it influences only the order of work, never which tracks are
   seen or kept.
   The entire committed batch is annotated regardless of work-order position or
   of reaching 43 keepers early. If a batch will not be completed, its work
   order is randomized and the budget spent on breadth (prd.md FR-59f (c),
   line 217); an abandoned batch yields no members.
3. **Verify by the DAW-oracle precedent** (`scripts/dawproject-bpm.py` workflow),
   under this SOP: the annotator stages the audio in the DAW, anchors the grid
   at a downbeat in the first stable section, adjusts until at least 32
   consecutive beats lock with no audible flam against the click, and reads the
   grid tempo at the declared metrical level, recorded to two decimals with no
   integer rounding. A track whose grid will not lock over any 32-beat span is
   rejected as tempo-unstable (the existing stability criterion). The
   `dawproject-bpm.py` invocation is EXTRACTION-ONLY: the `--match` mode, which
   joins legacy ground truth, is forbidden until the batch's annotations are
   frozen, and the annotator never opens legacy labels during annotation.
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
and rejoined only after the batch is annotated. Batch audio is staged as COPIES
named by the opaque row ID only; container metadata is not displayed (the DAW
project is created fresh per batch with tag and browser panes closed); any DAW
automatic tempo or warp analysis is disabled so no estimator-derived tempo is
shown. Sorting the annotation work order within an already-committed batch by
any `dsp/tag` quantity is permitted only because all four conditions above hold
in substance: the membership draw sequence is fixed first, the whole batch is
annotated, the annotator is blinded, and membership is decided afterward by a
DSP-free rule reading the membership draw sequence, never the work order. If any
condition cannot be met, the work order is randomized instead.

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
  assigned band. A track that verifies outside its pool's band is REJECTED from
  its band and is NOT reassigned anywhere in this corpus version; the verified
  tempo is retained as data.
- The annotator did not flag the track as metrically irresolvable. Ambiguous but
  resolvable tracks are kept with the ambiguity flag (section 1).
- The audio is intact and not a duplicate/re-encode of a track already kept
  (`scripts/audit-corpus-splits.py` class of check). The FR-59a.2 training-set
  contamination boundary (fingerprint, recording identity, artist string) is
  enforced earlier, at candidate-set construction (workflow step 1).

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
  ordering condition 2), so the cumulative keeper count can exceed 43. The kept
  43 are the first 43 keepers in the band's membership draw sequence, cumulative
  across batches; keepers beyond 43 in that sequence are recorded as verified
  surplus, not corpus members. The annotation work order plays no part.
- **Duplicate tie-break.** When duplicates of one recording co-occur, the row
  earlier in the membership draw sequence is kept and the other rejected as
  duplicate.

### Blinding residual (stated limitation)

Blinding is per-track only. The annotator (the operator) has read this protocol
and carries a band-level prior, for example the Q9 1.5x ratio composition of the
100-120 pool. This residual is accepted and noted, not solved.

### Replacement rule

A rejected track is **replaced from within its own band's precommitted candidate
pool**, by continuing along the band's membership draw sequence into the
not-yet-verified remainder; no fresh draw is made. The census surplus
figures (every band clears 43; scarcest is 175+ at 140, or 104 on the strictly
independent banding; three-source-band-census-2026-08-01.md finding 1; prd.md
finding 1 supersession, line 258) were computed on the census's own legacy/mixed
banding basis; under the declared full-tempo convention the per-band pool sizes
are NOT yet re-established, so those figures bound the workload expectation
rather than guarantee it. **Exhaustion rule (fallback order precommitted
here):** if a band's precommitted pool exhausts before 43 keepers, that band
HALTS and escalates to the operator. The fallback source order is fixed now:
(1) Tony's Rekordbox as-entered rows, then (2) OA300 rows, each banded by the
same face-value rule. The extension set for a band is enumerated and committed
as a dated addendum BEFORE any DSP statistic about it is consulted and before
any of its tracks is annotated, and it receives its own membership draw
sequence, appended after the exhausted one. The alternative remains shrinking
the corpus by operator decision. Keep criteria are never relaxed. Uniform n
stays 43; the corpus never shrinks below 258 except by operator decision.

### Budget

Baseline budget: 258 verifications plus replacement churn. For 100-120, the
one-keeper-in-four scenario is carried: under Q9's tagging-convention hypothesis a
tag-trusting draw yields roughly one keeper in four, so reaching 43 keepers takes
on the order of 170 reviews (prd.md FR-59f (b), line 208). **This is a
hypothesis-derived scenario carried so the budget is not set at 43 and then blown;
it is not a measured rejection rate**, and all 262 labels in that band are
unverified. 170 is the EXPECTED review count under the one-in-four hypothesis
(43/0.25 = 172), which has roughly even odds of being exceeded; it is not a
capacity allowance. Plan contingency capacity of roughly 25 percent above it
(about 215 slots) OR stop at the re-plan checkpoint; the checkpoint is the
control. The other five bands' budgets are
unestimated: no sourced keeper-rate figure exists for them, and none is invented
here; each is sized only after its first completed batch measures a keeper rate.
**Re-plan checkpoint:** for 100-120 the first completed batch tests the
one-in-four hypothesis. For each other band the first completed batch (default
size 40) ESTIMATES its keeper rate; the band budget is then set to
ceil(43/rate) and recorded, and the operator decides continue or re-plan at
that point. The trigger is the
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

Both directions read the same closed clean-source list: an FR-59a.1-clean
legacy label is the OA300 fixture value or an as-entered tag; octave-corrected
labels and training truth labels are excluded, both directions.

- its human-verified tempo at the declared convention falls in [160, 175) AND at
  least one FR-59a.1-clean legacy label for the same recording (the OA300 fixture
  value, or an as-entered tag) falls in [80, 87.5); or
- its human-verified tempo falls in [80, 87.5) AND at least one FR-59a.1-clean
  legacy label for the same recording (the OA300 fixture value, or an as-entered
  tag) falls in [160, 175).

The reverse direction is included because the old ambiguity was two-sided: AS-5
treated both halves as ground truth. The [80, 87.5) window is the halves of
[160, 175); it is a recorded deviation that widens the "80-85" phrase used
elsewhere (prd.md line 185 and the census prose), adopted so the half window is
exactly half of the full-tempo band. Window width was resolved at signoff
(2026-08-08, operator): [80, 87.5) as written, chosen over the PRD-literal
[80, 85) for octave symmetry with [160, 175). "Same recording" means an audio-fingerprint
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
via PR #195 (squash-merged into rterhaar/epic-12 as 255a159, 2026-08-08).
If 12.3's validation rules change in PR review, the tag must be re-validated
before corpus load.

---

## 6. Operator signoff

- [x] **Operator signoff: the metrical-level convention and ground-truth rule are adopted as written above.**
  Signed 2026-08-08 by the operator (robbyt), recorded via the structured
  decision elicitation in the development session: convention full-tempo
  (perceptual) as recommended; section-2 protocol accepted as revised after the
  second-reader review; budget accepted with the expected-value framing and the
  re-plan checkpoint as the control; sentinel window [80, 87.5); 10 percent
  blind re-pass audit adopted. The section-5 tag is minted at this date:
  `declared:metrical-full-tempo-v1-2026-08-08`.

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
   (surplus-keeper selection, duplicate tie-break, annotated span); the two
   named orders (the membership draw sequence and the annotation work order);
   the precommitted exhaustion fallback order (Tony's Rekordbox as-entered
   rows, then OA300 rows); the DAW annotation SOP (32-beat lock, two-decimal
   record, extraction-only invocation); the
   faster-level tie-break; the keep/reject criteria; the replacement and
   exhaustion rules; and the blinding mechanics with the stated blinding
   residual.
3. **The budget** (section 2): 258 verifications plus churn, with roughly 170
   reviews planned for 100-120 under the hypothesis-derived one-keeper-in-four
   scenario, other bands unestimated until their first completed batch, and the
   per-band re-plan checkpoint.

Accepted risks, stated plainly and bound with the signoff:

- **Detector influence on exposure order.** Per FR-59f (a)-(b) the detector's
  aggregate statistics influence which band is verified FIRST and, if the work
  is abandoned mid-way, which tracks were ever seen. A COMPLETED corpus is
  uncontaminated because incomplete work produces no membership; the protocol
  states abandoned batches yield no members.
- **Independence, not correctness.** Option 1 guarantees independence from the
  detector, not label correctness: all 258 labels rest on one annotator's
  perceptual judgement. Mitigation adopted at signoff (2026-08-08, operator):
  a **10 percent blind re-pass** -- after the corpus is complete, a random
  sample of roughly 26 kept tracks (drawn by the same seeded-PRNG mechanism as
  the membership sequences, recorded) is re-annotated blind under the same DAW
  SOP, and the disagreement rate is recorded with the corpus. The re-pass adds
  roughly 26 verifications to the budget. It measures repeatability; it does
  not relabel -- a disagreement is data, resolved only by a dated amendment.

### Clarification 2026-08-11: what counts as a disagreement (operator)

The blind re-pass above says "the disagreement rate is recorded" without
defining a disagreement. The operator resolved that on 2026-08-11. This is a
CLARIFICATION of an underdefined term, not a change to a bound item, and it
lands before any verification begins, so it requires no re-signoff. Recorded
here because this is the binding document.

The metric is **two-tier**, and the categories are exhaustive:

- **Metrical-level disagreement.** The second reading lies within plus or minus
  4 percent of 2x or 0.5x the first. This is an octave-RATIO criterion, not the
  phrase "half or double", so nothing rests on an example.
- **Fine disagreement.** Same metrical level, absolute difference above 0.5 BPM.
  0.5 BPM is deliberately conservative: two-decimal RECORDING precision does not
  imply two-decimal measurement accuracy after a manual 32-beat lock.
- **Agreement.** Same metrical level, absolute difference at or below 0.5 BPM.
- **Non-comparable.** Reserved for NO USABLE NUMERIC RESULT on either pass:
  tempo-unstable, metrically irresolvable, or an audio defect. A stable numeric
  second reading that falls outside the track's original band is still
  comparable; it is classified as metrical-level or fine and additionally
  flagged `crossed_band`.

Both rates are recorded, and alongside them the CONTINUOUS absolute differences:
median, maximum, and every paired value. Thresholding without the underlying
distribution discards information that cannot be recovered later.

**No pass/fail threshold exists.** The signed text says the rate is RECORDED. A
gate on it would be a new bound item requiring its own signature. A disagreement
remains data, resolved only by a dated amendment; if such an amendment changes a
sampled primary label it invalidates the comparison, and the re-pass summary is
regenerated against the amended ledger head.

Changing any of the bound items mid-verification requires a dated amendment to
this document and re-signoff before verification continues.

### Amendment 2026-08-11: FR-59a.2 partition ORDER (operator, re-signed)

This amends a BOUND item, so it carries its own signoff. It changes the ORDER in
which the eval and training corpora are partitioned. It does NOT change the
invariant they are partitioned for.

**Why.** Under the original order the four short bands cannot be built. Measured
2026-08-10 against the committed pools: 100-120 held 3 candidates of 43 needed,
175-plus 9, 120-140 28, 160-175 41. The cause is that the two committed training
manifests already cover nearly the whole tag-carrying non-Rekordbox pool, so
excluding training material from the eval draw empties the bands. The signed
exhaustion fallback does not help: its sources (Tony as-entered, then OA300) are
already inside the primary pools, and its measured net-new set is zero for every
band. Restoring Tony's unresolved audio was investigated and abandoned on
2026-08-11: of 373 unresolved rows only 19 were recoverable from the shared
folder and none of those sat in a short band, and the operator judged the
remainder to be mislabelled drum and bass, clips, or bad files.

**What changes, stated narrowly.** ONE of the three exclusion routes reverses
direction: matching a row in the two non-Rekordbox TRAINING MANIFESTS by audio
content (`audioHash`) no longer removes a candidate from the eval draw. Instead
the eval corpus draws it, and the training rebuild drops it.

**The other two routes are UNCHANGED and still exclude at candidate
construction:** `corpus_splits.json` `tony.train`/`tony.val` recording identity,
and artist-string overlap with a training row.

That narrow scope is deliberate, and it is sufficient. Measured against the
committed pools, lifting the manifest route alone takes the worst band to 80
candidates, and every band clears 43 with margin: 100-120 from 3 to 265,
175-plus from 9 to 113, 120-140 to 80, 140-160 to 102, 160-175 to 143, sub-100
to 2,194. Lifting the other two routes as well would add more headroom that is
not needed, so they are left alone. (These counts are pre-dedup; the
cross-band recording dedup below collapses some rows, so the final committed
pools are re-checked against 43 at mint rather than assumed from these figures.)

**What does NOT change.** FR-59a.2's invariant stands exactly as the PRD states
it (prd.md FR-59a.2): no track, no remix, and no artist appears in both corpora.
An earlier draft of this amendment described the invariant as "share no
recording", which would have quietly narrowed the partition unit from artist to
recording while claiming nothing changed. That draft was wrong and is not what
is signed here. Artist-level disjointness survives intact, and nothing in this
amendment relaxes it.

**Consequences, bound with this signature.**

1. **The audit becomes two gates, not one.**
   - *Mint-time obligation gate:* every eval member that appears in a current
     training manifest must be named on a recorded must-drop list, with the
     training row identified STRUCTURALLY (row id and hash), never as prose
     evidence. This is an obligation audit. It does not assert that FR-59a.2
     currently holds, and it must be labelled as such.
   - *Signoff-time closure gate:* a fresh audit against the REBUILT training
     corpus must find zero overlap. It re-runs the full comparison rather than
     merely confirming the listed rows disappeared, because a rebuild can
     introduce a re-encode that was never on the list.
2. **The must-drop list is generated from the final MEMBER roster, not from all
   candidates.** Dropping training rows for candidates that were rejected or
   ended up surplus would starve training for nothing. Because membership
   evolves during annotation the list is provisional, regenerated against the
   annotation-ledger head, and bound to the final member set at signoff. It also
   binds the eval commitment digest, the digests of the training inputs it was
   computed against, and the fingerprint method and dispositions.
3. **The fingerprint review changes purpose, not rigour.** A confirmed
   same-recording match between an eval candidate and a training-manifest row no
   longer excludes the candidate; it enumerates what the rebuild must drop, and
   the training peer is recorded structurally so the list is machine-checkable.
   Coverage rules are untouched: every candidate and every training row must be
   fingerprinted, uncoverable candidate audio stays excluded, an uncoverable
   training row still blocks, and every flag still needs a human disposition
   before minting.
4. **The mint-time training inputs are preserved as immutable provenance.** The
   rebuild changes those manifests, and without pinning the originals that change
   would read as illegal input drift and make the eval commitment unauditable.
5. **The rebuild is permitted before eval signoff; model training is not.** The
   two must not deadlock: the rebuild has to be able to land so the closure gate
   can pass, while the existing gate keeps training blocked until signoff.
6. **Every accuracy figure produced by a model trained before the rebuild is
   contaminated against this corpus and must be discarded.** No such figure has
   passed a gate, so nothing is lost; the Epic 12 bundle gate will use a model
   trained after the rebuild.
7. The rebuild itself is FR-59d work, out of scope for Story 12.7, whose intent
   contract forbids modifying the training manifests. Story 12.7 commits the eval
   corpus and the must-drop list; a later story performs the rebuild and closes
   the second gate.

**Also decided 2026-08-11, and bound here:** when one recording qualifies for two
bands, it is resolved BEFORE annotation rather than at the audit, so no track is
ever verified twice; and the band that keeps it is chosen scarcest-first, in the
order 175-plus, 100-120, 120-140, 160-175, 140-160, sub-100. Scarcest-first also
happens to favour the faster band, which is where a half-tagged track actually
verifies under the full-tempo convention.

- [x] **Operator signoff on this amendment.** Signed 2026-08-11 by the operator
  (robbyt), recorded via the structured decision elicitation in the development
  session, the same mechanism as the 2026-08-08 signoff above. The operator was
  shown the per-band candidate counts under both orders, the requirement for
  this amendment and re-signoff, and the contamination consequence, and chose the
  re-partition over shrinking the corpus. The scope was narrowed AFTER that
  choice, on the same day, from all three exclusion routes to the manifest route
  alone, once it was measured that the narrow lift already clears 43 in every
  band. The narrowing is strictly more conservative than what was approved and
  preserves the artist rule the approved version would have weakened.

Dependency risk carried into signing: the section-5 tag validates against Story
12.3's scheme as committed on this stacked branch via PR #195, squash-merged
into rterhaar/epic-12 as 255a159 (2026-08-08). Its two review passes fixed only
labelling and hardening, with no validation-rule change, and pinned the digest
golden vector; the tag remains valid as validated.

The paragraph below is retained as the record of the pre-signoff state; the
signoff above (2026-08-08) closes it. The convention exists, candidate sets may
be committed under the section-2 protocol, Story 12.7 may start, and the
section-5 tag names the rule.

> Until signed, all of the following stay open: no convention exists, no candidate
> set may be committed, no track may be verified or labelled, Story 12.7 cannot
> start, and the tag in section 5 names a recommendation rather than a rule. The
> sentinel-subset rule (section 3) and the FR-62 audit (section 4) are descriptive
> and carry no gate, but the subset rule references the declared convention and so
> also floats until signing fixes it. Per epics.md Story 12.6's final AC, this story
> cannot close on agent work alone; its run status is `blocked` on this signoff.

### Amendment 2026-08-14: same-file duplicate results are recorded, not adjudicated (operator, re-signed)

This amends a BOUND item and carries its own signoff. It narrows WHICH
possible-duplicate results require a human decision. It does not relax the
partition invariant, the coverage rule, or the rule that a human decision is
what excludes a candidate.

**Why.** The 2026-08-11 re-partition deliberately draws eval candidates FROM
the training-manifest pool, so a candidate is now routinely the very training
row it is compared against. Measured on the first run under that order
(2026-08-13): the fingerprint pass emitted 2,731 results, and 2,550 of them
were a candidate compared with ITSELF, at identical `audioHash` and cosine
exactly 1.0. All 2,550 already carried a removal obligation derived from the
manifest-hash route at candidate construction, with no human decision involved
(measured: 2,550 of 2,550 already obligated, none uncovered). A human decision
on those cannot change the pools, the membership, or the obligation set. The
prior sentence therefore demanded 2,550 judgments that could not affect any
outcome, while the 176 cross-row and 5 cross-band results that CAN affect an
outcome sat behind them.

**What changes.** In consequence 3 above, the clause "and every flag still
needs a human disposition before minting" is superseded by:

> Every possible duplicate that turns on a judgment still needs a human
> decision before the song list is frozen. A result where the evaluation
> candidate and the training-list entry are THE SAME FILE (identical audio
> hash) is not put to a person: a file cannot differ from itself, and the
> requirement to remove that training entry is derived from the hash, not from
> the answer. These are recorded automatically, with their count and a
> checksum, and stay fully auditable. Only genuine same-recording questions
> between DIFFERENT files reach a human.

**What does NOT change.** Every candidate and every training row must still be
fingerprinted. Uncoverable candidate audio stays excluded. An uncoverable
training row still blocks certification. A confirmed same-recording match
between two DIFFERENT files still requires a recorded human decision, and that
decision still excludes (or, for a training-manifest peer under the 2026-08-11
order, enumerates the removal obligation) exactly as before. The exemption is
machine-verifiable identity ONLY: high fingerprint similarity is never
sufficient, because that is precisely the uncertain case a human exists to
resolve.

**Bound with this signature.** The automatic record carries the same evidentiary
weight as a recorded decision: the count and a digest of the exempted set are
written into the frozen record, and a test asserts that every exempted case is
still present in the removal obligation set. An exemption that failed to
produce an obligation would be a silent partition breach, so it is asserted
rather than assumed.

- [x] **Operator signoff on this amendment.** Signed 2026-08-14 by the operator
  (robbyt), recorded via the structured decision elicitation in the development
  session, the same mechanism as the 2026-08-08 and 2026-08-11 signoffs. The
  operator was shown the superseded clause and the replacement text verbatim,
  side by side, together with the measured effect (2,731 reviews reduced to
  181) and the statement that the song list, the selected songs, and the set of
  training songs to be removed are all unchanged. This re-signature replaces an
  earlier approval taken the same day that the operator stated they did not
  understand; that approval is withdrawn and is not the basis for this change.

**Recorded, not amended: the fingerprint window (2026-08-14).** The same run
found two training rows that could not be fingerprinted, both because the
method read 60 seconds starting at a hardcoded 10.0 second offset and neither
file has audio at 10 seconds. One is a corrupt MP3 handled as a training-data
defect; the other is a legitimate 9.4 second interlude. Making the method read
short audio SERVES the standing coverage rule rather than amending it, so it
needs no signature. It is recorded here because the method identifier is
pinned: the window becomes zero-offset for EVERY file under a new method
version. A short copy read from 0:00 while a long copy of the same recording is
read from 0:10 would be compared across different musical material and could
fail to match, which would let a genuine duplicate reach both corpora. One
comparable rule for all files is therefore required, not an adaptive one.
