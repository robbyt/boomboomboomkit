# Story 12.7: the 258-track band-balanced evaluation corpus

Date: 2026-08-08. Status: harness complete; corpus construction BLOCKED on
operator hand-verification (FR-59f option 1). No track has been verified or
labelled by this run; no annotation was simulated or invented.

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md`
section 2 (pool construction, draw sequences, batches, keep/reject, replacement,
exhaustion), section 3 (octave-sentinel rule), section 5 (annotation-version tag
`declared:metrical-full-tempo-v1-2026-08-08`). Where the harness and the protocol
could differ, the protocol wins.

Harness: `scripts/build-eval-corpus.py` (subcommands commit-pools, stage-batch,
ingest, status, audit, emit-manifest), driven by the `make eval-corpus-*`
targets. Row-level state is gitignored under `_bmad-output/ml-training/eval-corpus/`;
the committed commitment record is `12-7-candidate-commitment.{json,md}`
(counts, seeds, and the named digests only).

## Candidate commitment outcome (2026-08-08)

`make eval-corpus-pools` ran against the real three-source inputs and HALTed:
four of the six bands CANNOT reach 43 members from the committed pools. The
per-band shortfalls are 100-120 at 3 of 43 (short 40), 120-140 at 28 of 43
(short 15), 160-175 at 41 of 43 (short 2), and 175-plus at 9 of 43 (short 34);
per-reason exclusion counts are in the commitment record. The operator's next
action for these bands is the signed fallback addendum: Tony as-entered rows,
then OA300, banded by the same face-value rule, enumerated and committed as a
dated addendum before any DSP statistic about it is consulted and before any of
its tracks is annotated. The dominant cause of the shortfall is the
FR-59a.2 manifest-hash exclusion: the two committed training manifests cover
nearly the entire tag-carrying pool, so pool rows are largely training material.
Per the signed exhaustion rule the escalation is the operator's; the fallback
source order is precommitted (Tony as-entered rows, then OA300, each banded by
the same face-value rule, committed as a dated addendum before any DSP statistic
about it is consulted). The harness performs no auto-extension.

## 175+ degeneracy note (recorded, not re-litigated)

130 of the census band's 140 tracks sit within 175-179, non-separable from
160-175 at the plus-or-minus 4 percent Acc1 tolerance, with three to five
genuinely above-180 tracks in the collection
(three-source-band-census-2026-08-01.md finding 2; prd.md FR-59f (a)). A flat
175+ result must not later be read as a fast-tempo measurement.

## Per-band progress

Membership is the first 43 keepers in each band's committed draw sequence,
cumulative across batches. No batch has been staged or annotated.

| Band | Members | Target |
|---|---|---|
| sub-100 | 0 | 43 |
| 100-120 | 0 | 43 |
| 120-140 | 0 | 43 |
| 140-160 | 0 | 43 |
| 160-175 | 0 | 43 |
| 175-plus | 0 | 43 |

## OA300 18-vs-14 reconciliation (audit outcome, 2026-08-08)

The tracked fixture bands 18 / 1 / 7 / 15 / 41 / 0 at face value; the
three-source census recorded 14 / 1 / 7 / 16 / 44 / 0 for the same 82 rows. A
half-open edge at 100 cannot remove sub-100 rows. The audit tested the
value-basis hypothesis: doubling the 18 sub-100 fixture values lands 16 in
[160, 175), 1 in [140, 160), and 1 at 175+. The census deltas (sub-100 minus 4,
140-160 plus 1, 160-175 plus 3) are consistent with the census having banded 4
of these rows at a doubled (full-tempo) value from a different value source.
The difference is a row-basis difference in the census's value source, not a
band-edge effect, and the fixture face-value count (18) is the one the sentinel
subset definition uses. The residual-overlap, FR-59a.1, and duplicate audit
passes were clean on the committed pools.

## Signoff

Flipped to `signed` by the operator only after all six bands reach 43 verified
members, the audit passes on the final state, and the manifest is emitted. This
marker gates any substrate-v2 training run (`train.py`
`check_substrate_preconditions`, fail closed).

REVIEWER_SIGNOFF: pending
