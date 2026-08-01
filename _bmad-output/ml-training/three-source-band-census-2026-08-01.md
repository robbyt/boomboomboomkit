# Three-source band census: `N_BAND` = 43 was a pool-only measurement

Develop-only analysis artifact. Establishes what each of FR-59's three corpus
sources actually contributes per BPM band, and what that does to the corpus
constants the PRD carries as settled.

Prompted by Q9 (`q9-ratio-cluster-2026-08-01.md`). Placing the 23 DAW-verified
OA300 tracks next to the pool numbers made an assumption visible that had been
carried without notice: **`N_BAND` = 43 is the scarcest band of one source, used
as a global constant across three.**

Decode-free. Every figure comes from artifacts already on disk.

## What each source can be banded by, and how independent that is

FR-59a.1 forbids treating a DSP-derived value as ground truth, so a band census
must use labels our detector did not produce. The three sources are not equally
endowed, and the shortfall lands where it hurts.

| source | rows | independent label | caveat |
|---|---|---|---|
| OA300 | 82 | Rekordbox BPM; DAW-placed tempo for 23 | the 23 are hand-verified by the operator |
| Tony's Rekordbox | 1,534 | `rekordbox_average` (1,344 rows) | **see below** |
| non-Rekordbox pool | 4,766 | file tag (2,550 after mix exclusion) | one signal only, and Q9 showed 197 of the 100-120 tags are suspect |

**Tony's banding is only half independent, and the half that is not is the half
that matters.** `bpm_truth` is built in two parts: the *value* is Tony's Rekordbox
number (`_truth_value_from_winner` takes the Rekordbox member's `canonical_bpm`,
not the weighted centroid), but the *octave* is chosen by a cluster vote that
includes our detector. Banding is an octave-sensitive operation. So the
octave-corrected column below inherits a detector-influenced octave and cannot be
quoted as independent; the as-entered column can.

The band totals are reported both ways for exactly that reason.

## The census

Counts are post continuous-mix exclusion (`corpus_common.is_continuous_mix`), which
removes 18 tagged pool rows. "OAver" is the DAW-verified subset of the OA300 column,
not an addition to it. The total uses the octave-corrected Tony banding.

| band | OA300 | of which verified | Tony as entered | Tony octave-corrected | pool | **total** |
|---|---|---|---|---|---|---|
| <100 | 14 | 0 | 889 | 36 | 1,988 | **2,038** |
| **100-120** | 1 | 0 | 8 | 26 | 262 | **289** |
| 120-140 | 7 | 5 | 137 | 253 | 52 | **312** |
| **140-160** | 16 | 3 | 310 | 372 | 42 | **430** |
| 160-175 | 44 | 15 | 0 | 786 | 102 | **932** |
| **175+** | 0 | 0 | 0 | 36 | 104 | **140** |

## Finding 1: the ceiling is roughly 3x what the PRD carries

**Scarcest band across all three sources: 175+ at 140.** On the strictly
independent banding (Tony as entered) it is also 175+, at 104. Either way, `N_BAND`
= 43 understates availability by about a factor of three.

The consequence is not "make the corpus bigger". It is that **corpus size stops
being an availability constraint and becomes a verification-budget choice.** 258
tracks was set by what the pool alone could supply; the collection supports far
more. Keeping 258 with a large rejection margin is now a decision rather than a
ceiling.

**140-160's "no slack" risk is gone.** FR-59f instructs verifying that band first
because it sits at exactly 43 and could shrink the whole corpus. Across three
sources it holds 430. That reason no longer applies, though 100-120 still wants
verifying early for the workload reason Q9 established.

## Finding 2: the 175+ band barely functions as a band

Of the 140 tracks at 175+, **130 sit between 175 and 179**. Only 19 exceeded 180
before the mix exclusion, and seven of those were the `Platinum_One` DJ mixes
blanket-tagged 180 — now excluded. Realistically **three to five genuinely
above-180 tracks exist in the entire collection**, one of them a hardcore record
where 200 is plausible.

So `175+` spans about 5 BPM of real material, where `<100` spans 100 and `100-120`
spans 20. That alone is awkward. The measurement problem is worse:

**At the ±4% tolerance Acc1 actually uses, 175+ and 160-175 are not separable.** A
track at 176 accepts 169.0-183.0. A track at 172 accepts 165.1-178.9. A model
predicting 172 scores correct on a 178 ground truth. A band-balanced corpus that
spends one sixth of its slots distinguishing 174 from 178 is buying a distinction
the metric cannot measure.

**Merging 175+ into 160-175** gives 1,072 there and moves the binding band to
**100-120 at 289** — which is where the real difficulty was all along: the band E0
showed is genuinely mis-pulsed (Acc1 = Acc2 = 1/35, so no octave rule reaches it),
and the band Q9 showed is 75% contaminated by the 1.5x tagging cluster.

Whether to merge is FR-59's call, not this artifact's. What this artifact
establishes is that leaving the scheme unexamined spends a sixth of the corpus on
a distinction the gate cannot resolve.

## Finding 3: 49 tracks appear in both OA300 and Tony's collection

Matched on basename stem. FR-59a.2 forbids any track appearing in both the
evaluation corpus and a training set, and OA300 and Tony's collection feed
different sides. **This dedup has to happen before the draw**, and
`scripts/audit-corpus-splits.py` is the natural place to assert it.

The 49 are a lower bound: basename matching misses re-encodes, remixes and
differently-named copies. The audit's existing fingerprint pass is the tool for
that, and it is report-only by design (DD #3).

## Finding 4: the half-tempo convention, measured on Tony's own entries

Tony's two bandings are near mirror images. As entered: 889 tracks below 100, zero
at 160-175. Octave-corrected: 36 below 100, 786 at 160-175.

This is the strongest evidence yet for the collection's half-tempo convention, and
unlike Q9's it comes from **Tony's own Rekordbox entries** rather than third-party
file tags. It is what FR-59b's convention declaration has to reckon with: the same
1,344 files produce two entirely different band distributions depending on which
level is declared.

The caveat from the top applies — the correction's octave came from a vote our
detector participated in, so this describes the convention rather than proving the
octave is right.

## What the PRD should change

1. **`N_BAND` = 43 and `N_EVAL` = 258 are pool-only figures.** They are already
   marked as planning constants FR-59f can lower (Q9); they should also be marked
   as *floors set by one source*, not ceilings set by availability.
2. **FR-59f's "verify 140-160 first" rationale is void.** The band holds 430, not
   43. Verify 100-120 first, for workload rather than scarcity.
3. **The six-band scheme needs its top edge reconsidered before the draw**, or one
   sixth of the corpus measures nothing.
4. **The OA300/Tony 49-track overlap is an FR-59a.2 gate** and needs asserting.
5. **FR-59b now has measured evidence from two independent populations** — Tony's
   Rekordbox entries here, third-party tags in Q9 — that the convention choice
   determines the band distribution rather than describing it.

## Reproducing

Requires the gitignored `non-rekordbox-survey.json` and the corpus-local
`daw-oracle.json`; the Tony labels and the OA300 ground truth are tracked. The
script is in the commit that added this artifact. Definitions match Q9's: bands are
half-open `[lo, hi)` at 100 / 120 / 140 / 160 / 175, so 120.0 lands in 120-140.

`daw-oracle.json` regenerates with `make oracle-generate`; the pool durations with
`make pool-durations`.
