# Story 12.7: the 258-track band-balanced evaluation corpus

Date: 2026-08-08, reworked 2026-08-10 after the PR #197 review. Status: harness
complete; corpus construction BLOCKED, and now blocked earlier than before. The
candidate commitment minted on 2026-08-08 is SUPERSEDED and no consumer will
operate on it. Construction restarts at a re-mint, which is itself blocked on two
operator decisions and on the pre-commitment fingerprint review. No track has
been verified or labelled by this run; no annotation was simulated or invented.

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md`
section 2 (pool construction, draw sequences, batches, keep/reject, replacement,
exhaustion), section 3 (octave-sentinel rule), section 5 (annotation-version tag
`declared:metrical-full-tempo-v1-2026-08-08`). Where the harness and the protocol
could differ, the protocol wins.

Harness: `scripts/build-eval-corpus.py` (subcommands prepare-review,
commit-pools, stage-batch, ingest, abandon, status, audit, emit-manifest,
signoff), driven by the `make eval-corpus-*` targets. Row-level state is
gitignored under `_bmad-output/ml-training/eval-corpus/`; the committed records
are `12-7-candidate-commitment.{json,md}`, `12-7-annotation-ledger-head.json`,
and `12-7-signoff-attestation.json` (counts, seeds, prose, and named digests
only).

## Why the 2026-08-08 commitment is superseded

Three defects, none repairable in place:

1. It was minted without the audio-fingerprint exclusion route. The signed
   section-2 rule excludes training-overlap "by audio fingerprint, by recording
   identity, or by artist string" before commitment; only the latter two ran.
2. Its opaque row IDs encoded the draw position. Combined with a
   sequence-ordered worklist, that told an annotator who knows the first-43 rule
   which rows were likely members. It is not detector leakage, but it weakened
   blinding for nothing.
3. Its Tony and OA300 rows were bound by track identifier and filename only, not
   by audio content, so a replaced or re-encoded file would not have been
   detected.

The record is retained rather than deleted, with a dated supersession note, and
`status: superseded` is ENFORCED: every subcommand refuses while it stands.
Nothing was lost by re-minting, because the working state held only candidate
and draw files, with no batch staged and no annotation recorded. That is why the
re-mint had to happen now and not later.

## What blocks the re-mint

Both are operator decisions, and both must be supplied as machine-readable input
at `_bmad-output/ml-training/eval-corpus/12-7-operator-decisions.json`. The
harness refuses to mint while either is absent rather than inferring a policy
from prose.

**(a) Short-band allocation.** At the superseded commitment four bands could not
reach 43 candidates: 100-120 at 3 of 43, 120-140 at 28 of 43, 160-175 at 41 of
43, and 175-plus at 9 of 43. The dominant cause is the FR-59a.2 manifest-hash
exclusion, which removes nearly the whole tag-carrying non-Rekordbox pool because
the two committed training manifests cover it.

The signed exhaustion fallback does not resolve this on its own, and the earlier
version of this artifact was wrong to present it as the next action. Its source
order is Tony as-entered rows, then OA300 rows, and both are already inside the
primary pools, so the fallback set is empty by construction. It can recover at
most 25 rows for 100-120 and 44 for 120-140, and exactly zero for 160-175 and
175-plus. A precommitted primary allocation plus reserves would draw across all
three sources (satisfying the epic AC that the corpus is drawn across them) while
preserving a real fallback; shrinking the corpus by operator decision is the
other option the protocol already allows. The harness implements
`fallback-addendum` and `shrink-corpus`; it performs no auto-extension either way.

**(b) Cross-band duplicate rule.** The signed tie-break is "earlier in the
membership draw sequence wins", which orders rows WITHIN a band and defines no
winner BETWEEN two bands. This is not a corner case in this collection: the same
recording tagged 85 in one source and 170 in another lands in two different bands
by construction, which is the dominant half-versus-full-tempo pattern the 12.6
evidence describes. The harness implements `pre-commitment-recording-dedup` (a
recording is kept only in the highest-priority band, priority recorded) and
`audit-fails-on-cross-band-duplicate` (no pre-dedup; the audit's cross-band
duplicate check is the rule). Choosing after annotation has begun would be
improvising over frozen labels, so it is decided before the re-mint.

`prepare-review` supplies the evidence for this decision: it emits
`cross-band-recording` flags for candidate pairs in different bands whose
fingerprints match. Those flags exclude nothing on their own; a confirmed one
supplies the recording group that `pre-commitment-recording-dedup` collapses on,
which is the only mechanism that can see a half-tempo and a full-tempo encode of
one recording, since the two files differ byte for byte.

## The pre-commitment fingerprint review

The signed exclusion route is mandatory and runs before commitment, so it is a
two-stage gate rather than a report. `prepare-review` computes the flags:
candidate audio matching a training recording at or above the DD #3 review cosine
(0.97), plus GiantSteps normalized-title collisions, which are conservative
heuristics because `normalize_track_key` drops suffixes and parenthesized
material. `commit-pools` then refuses to mint until every flag carries a recorded
human disposition, and excludes the ones confirmed as the same recording. The
algorithm flags; the human disposition excludes. That is what DD #3's "never the
sole auto-exclusion signal" requires, and it does not make the route optional.

Each disposition set is bound to the candidate-universe digest, the fingerprint
method version, and the training-input digest, so a change to the short-band
allocation cannot silently reuse adjudications made against a different universe.

The review RUN is deliberately not performed yet: the two decisions above change
the candidate universe, so adjudicating today's universe would produce stale
dispositions.

## Annotation ledger: integrity, not backup

Batches, annotations, and membership all live under the gitignore, so before this
rework nothing detected an annotation file being edited, deleted, moved, or
duplicated: every committed digest still verified while membership silently
changed. The harness now keeps an append-only ledger under
`_bmad-output/ml-training/eval-corpus/annotation-ledger.jsonl`, and commits its
head digest and event counts to `12-7-annotation-ledger-head.json`. Each event
binds the active commitment digest, the batch record, the work order, the
annotation record, and the previous head. Corrections append a replacement event;
prior records are never overwritten. Abandoned batches are one such event, which
is how the signed "an abandoned batch yields no members" rule is represented.

**This provides integrity, not backup or recovery.** It detects tampering,
deletion, and stale-file reuse. It cannot restore a lost annotation, and these
labels cannot be regenerated: they are one annotator's DAW work.

## Signoff is an attestation, not a marker

The `REVIEWER_SIGNOFF` marker at the bottom of this file is human-editable, so it
is a courtesy gate only. The binding artifact is `12-7-signoff-attestation.json`,
which `make eval-corpus-signoff` writes only after the shared fail-closed audit
passes and every band holds its full membership, and which is bound to the active
commitment digest and the annotation-ledger head. `train.py`
`check_substrate_preconditions` validates that attestation, so hand-editing the
marker below buys no training run.

## 175+ degeneracy note (recorded, not re-litigated)

130 of the census band's 140 tracks sit within 175-179, non-separable from
160-175 at the plus-or-minus 4 percent Acc1 tolerance, with three to five
genuinely above-180 tracks in the collection
(three-source-band-census-2026-08-01.md finding 2; prd.md FR-59f (a)). A flat
175+ result must not later be read as a fast-tempo measurement.

## Per-band progress

Membership is the first 43 keepers in each band's committed draw sequence,
cumulative across batches. No batch has been staged or annotated, and no pool is
currently committed.

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
subset definition uses. This finding stands; it was measured against inputs the
re-mint does not change.

## Signoff

Flipped by the operator only after all six bands reach 43 verified members, the
shared audit passes on the final state, the manifest is emitted, and
`make eval-corpus-signoff` has recorded the attestation. This marker plus that
attestation gate any substrate-v2 training run (`train.py`
`check_substrate_preconditions`, fail closed).

REVIEWER_SIGNOFF: pending
