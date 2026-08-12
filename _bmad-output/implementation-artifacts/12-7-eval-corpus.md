# Story 12.7: the 258-track band-balanced evaluation corpus

Date: 2026-08-08, reworked 2026-08-10 and again 2026-08-11 after the second PR
#197 review. Status: harness complete; corpus construction BLOCKED. The
candidate commitment minted on 2026-08-08 is SUPERSEDED and no consumer will
operate on it. Construction restarts at an explicit re-mint
(`make eval-corpus-remint`), which is itself blocked on two operator decisions
and on the pre-commitment fingerprint review. No track has been verified or
labelled by this run; no annotation was simulated or invented.

The 2026-08-11 rework closed eight defects the 2026-08-10 rework introduced. The
pattern is worth stating plainly: that pass hardened the commitment chain and,
in doing so, built a state machine whose paths it never walked. Two of the eight
were blockers - the harness could no longer mint a corpus at all, and the
"mandatory" fingerprint route did nothing in several ordinary conditions - and
two more were policies these artifacts advertised as implemented that did
nothing. The structural answer is in "How the harness is structured" below, and
the test suite now walks the whole lifecycle end to end.

Signed protocol: `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md`
section 2 (pool construction, draw sequences, batches, keep/reject, replacement,
exhaustion), section 3 (octave-sentinel rule), section 5 (annotation-version tag
`declared:metrical-full-tempo-v1-2026-08-08`). Where the harness and the protocol
could differ, the protocol wins.

Harness: `scripts/build-eval-corpus.py` (subcommands prepare-review,
commit-pools, remint, stage-batch, ingest, abandon, status, audit,
emit-manifest, repass-sample, repass-ingest, signoff), driven by the
`make eval-corpus-*` targets. Row-level state is gitignored under
`_bmad-output/ml-training/eval-corpus/`; the committed records are
`12-7-candidate-commitment.{json,md}`, one archived
`12-7-candidate-commitment.<date>.<digest>.json` per superseded predecessor,
`12-7-fallback-addendum.json` when that policy is in force,
`12-7-annotation-ledger-head.json`, and `12-7-signoff-attestation.json` (counts,
seeds, prose, and named digests only).

## How the harness is structured

Three narrow boundaries, and deliberately not a general workflow framework. They
exist because the previous round's command functions held planning, validation,
and mutation at once, so no single place could assert the state machine was
coherent - and more tests alone would not have fixed that.

1. A **pure planning layer** (`plan_commit`, `plan_batch`, `plan_repass`) that
   returns every document a command would write and writes nothing itself.
2. An **immutable event store** with explicit event kinds and an
   allowed-transition table. `abandoned` is terminal; a correction appends a
   replacement event and a NEW record version rather than overwriting one.
3. A single **`validate_state()`** called before AND after every mutation, with
   the commitment's generation present in every private path - the pools and
   draws included, not only the annotations. Preserving an archived
   commitment's JSON is not enough on its own: if the canonical row-level files
   could be replaced in place, the archived chain would be unverifiable.

Command handlers are thin: load, validate, plan, write immutable artifacts,
validate again. The primary-annotation and blind-re-pass state machines stay
separate.

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

## The re-mint path

Until 2026-08-11 no such path existed. `commit-pools` halted unconditionally on
a superseded record, printing "present" for each satisfied prerequisite under
the headline "blocked on the following, all of which must be on record first",
so satisfying every stated gate failed identically to satisfying none. Nothing
ever wrote `active` over a superseded record. Meanwhile this artifact said
"construction restarts at a re-mint" and the harness told the operator to
"re-mint with commit-pools" - both describing something impossible. The only
escape was deleting a committed artifact.

`make eval-corpus-remint` is now the explicit operation, ordered so a crash
cannot leave an inconsistent chain:

1. validate everything first, including that the prior generation carries NO
   annotation state (every event binds the active commitment while batches,
   annotations and membership are generation-scoped, so a successor over live
   annotation state would strand labels that cannot be regenerated);
2. copy the predecessor byte-for-byte to a unique archive named with its own
   digest, refusing a collision, and verify the archive's digest;
3. build and verify every new artifact in the new generation;
4. replace the canonical commitment LAST, atomically.

The successor records `supersedes_sha256`, and commitment validation walks the
whole chain, so an archived predecessor cannot silently vanish. `commit-pools`
still halts on a superseded record, but it now lists ONLY the prerequisites
genuinely missing, and when none are missing it names the re-mint as the next
action.

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
other option the protocol already allows.

The harness implements BOTH policies, and it now ENUMERATES the signed fallback
under either of them. That correction matters: until 2026-08-11 only
`shrink-corpus` changed behaviour, `fallback-addendum` was accepted and then did
nothing, and short bands simply halted - while this artifact claimed both were
implemented. Enumerating it is what lets the operator SEE the emptiness rather
than infer it. The addendum is committed as a dated artifact
(`12-7-fallback-addendum.json`) BEFORE any DSP statistic about it is consulted
and before any of its tracks is annotated, and it receives its own draw sequence
appended after the exhausted one. Measured against today's inputs the net-new
set is ZERO for every band, because the signed source order (Tony as-entered
rows, then OA300) is already inside the primary pools, and the fallback extends
a pool without ever re-admitting a row excluded for cause. A short band still
HALTS. No auto-extension is performed either way.

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

The second policy was a no-op until 2026-08-11. Its whole purpose is catching
cross-band re-encodes, but the audit's duplicate check compared only recording
identity, the audio byte digest, and the normalized title - and a confirmed
re-encode differs in identity AND in bytes by definition. The confirmed
same-recording GROUPS are now persisted on the candidate rows at mint and the
audit fails on two members sharing one, which is the check the policy's name
promises. Those groups are also now transitive: confirmed pairs are merged with
union-find, so an A-B plus B-C confirmation yields one component. Writing each
flag's group with no merge produced `A -> g1, B -> g2, C -> g2`, letting A and B
both survive a confirmation that they are the same recording, with the winner
decided by sha256 sort order. The disposition template now also surfaces
`candidate_key` and `peer_key`, so an operator can assign a shared group by
hand rather than being pushed onto the broken default.

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

**The route failed OPEN until 2026-08-11**, in four independent ways: missing
audio was skipped by a bare `continue`; every decode failure returned `None`
through a blanket `except Exception` that `if vec:` absorbed; a missing librosa
returned `None` for EVERY file, zeroing the route entirely; and an empty
training set short-circuited so the completeness check was trivially satisfied.
The mint then recorded `"flags": 0` with no denominators, which is
indistinguishable from "ran, found nothing". Twenty lines away the advisory
GiantSteps heuristic raised loudly on a missing input, so the advisory route
failed closed while the mandatory one failed open.

It now fails closed, and the two sides are treated ASYMMETRICALLY because they
are not symmetric:

- **An unfingerprintable candidate is hard-excluded**, with the count recorded
  under its own exclusion reason. There is no human escape and none is needed:
  content binding already runs first, so such a row cannot be staged safely
  anyway.
- **An unfingerprintable training row BLOCKS certification.** It potentially
  hides re-encoded overlap with every candidate, and a human cannot infer "not
  the same recording" from a failed decode - that would turn absence of evidence
  into evidence of absence. It is unblocked only by restoring the audio,
  correcting the manifest, or a dated operator amendment naming the accepted
  row.
- **Coverage is reason-stratified** (resolved, unresolved path, missing file,
  decode-failed, too-short, non-finite) with a digest binding the private
  coverage roster, so "4,200 of 4,300" can still identify WHICH hundred after
  the inputs move. The stratification comes from
  `corpus_common.compute_fingerprint_with_reason`, which is now the single
  decode implementation both this harness and the split audit share.
- **A missing decode backend is a distinct environment failure**, raised
  immediately.

## Annotation ledger: integrity, not backup

Batches, annotations, and membership all live under the gitignore, so before this
rework nothing detected an annotation file being edited, deleted, moved, or
duplicated: every committed digest still verified while membership silently
changed. The harness now keeps an append-only ledger under
`_bmad-output/ml-training/eval-corpus/annotation-ledger.jsonl`, and commits its
head digest and event counts to `12-7-annotation-ledger-head.json`. Each event
binds the active commitment digest, the batch record, the work order, its own
annotation record path, and the previous head. Abandoned batches are one such
event, which is how the signed "an abandoned batch yields no members" rule is
represented.

**Annotation records are immutable and versioned.** Until 2026-08-11 the claim
below that "prior records are never overwritten" was false in two places: a
forced re-ingest wrote to the same unversioned path (ending in `os.replace`),
leaving only a digest of bytes that no longer existed, and `abandon --force`
unlinked the record outright. Both destroyed labels that cannot be regenerated.
A correction now writes `batch-NNN.v<K>.json` and appends a replacement event
carrying that path; `abandon` removes a batch from MEMBERSHIP and leaves every
prior record on disk, still referenced by its own event and still digest-
verified. No command overwrites or unlinks an annotation record.

**The worklist is validated BEFORE annotations are accepted.** The recorded
`work_order_sha256` was previously written and read nowhere, which is worse than
recording nothing because it reads as assurance: a worklist could be edited to
point a row id at different audio, producing labels for the wrong track, while
every check passed. Verifying the ingest-recorded digest alone would still be
too late, because a worklist altered BEFORE ingest has its altered digest
anchored as the reference. Ingest therefore validates the full worklist against
the batch record's work order, confines every path to that batch's staging
directory, and hashes every staged file against that row's committed
`contentSha256`; the recorded digest is then re-checked by the audit so
post-ingest edits are caught too.

**This provides integrity, not backup or recovery.** It detects tampering,
deletion, and stale-file reuse. It cannot restore a lost annotation, and these
labels cannot be regenerated: they are one annotator's DAW work.

## The signed 10 percent blind re-pass

The 2026-08-08 signoff bound a mitigation for "independence, not correctness"
(12-6 section 6, lines 484-492): after the corpus is complete, roughly 26 kept
tracks are re-annotated blind under the same DAW SOP and the disagreement rate
is recorded with the corpus. Until 2026-08-11 the harness had no trace of it,
and this artifact did not acknowledge it, so a corpus could have received the
training-enabling attestation without the mitigation the operator signed - from
the very artifact meant to certify the protocol was followed.

`repass-sample` draws it: a domain-separated seed over a SEPARATE permutation of
the frozen member roster, not a continuation or reuse of any membership
sequence. Seed, algorithm, population digest, sample digest and size are
persisted in an immutable record written before any re-pass annotation exists.
Blinding means what is achievable - the annotator cannot forget prior exposure,
so it means blinded to the first-pass BPM and flags, to membership position, and
to the original row id: fresh re-pass aliases, an independently randomized
order, a fresh DAW project, and a private alias map. `repass-ingest` records the
result against the operator's 2026-08-11 two-tier definition (see 12-6), keeping
the continuous absolute differences alongside the two rates.

The re-pass never feeds membership, never replaces a primary annotation, and
never appends an ordinary batch event; it has its own record, validator, and
state machine, and reuses only the low-level primitives (content-verified
staging, annotation CSV parsing). Signoff refuses without a validated re-pass
record and binds its digest and both rates into the attestation. There is no
pass/fail threshold: the signed text records the rate, and a gate would be a new
bound item requiring its own signature.

## Signoff is an attestation, not a marker

The `REVIEWER_SIGNOFF` marker at the bottom of this file is human-editable, so it
is a courtesy gate only. The binding artifact is `12-7-signoff-attestation.json`,
which `make eval-corpus-signoff` writes only after the shared fail-closed audit
passes, every band holds its full membership, and a validated blind re-pass
exists, and which is bound to the active commitment digest, the
annotation-ledger head, and the re-pass record digest. `train.py`
`check_substrate_preconditions` validates that attestation, so hand-editing the
marker below buys no training run.

The validator now READS AND HASHES every referenced artifact. Comparing the
attestation's ledger-head string against the tracked head JSON validated a
self-consistent set of copied fields rather than the artifacts themselves: it
never recomputed the actual ledger head from the event store, never verified the
head artifact's commitment binding, and would not have hashed the re-pass
record. All three are checked, and the gate has automated tests against five
attestation states (valid, missing, malformed, stale ledger, wrong re-pass).

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
shared audit passes on the final state, the manifest is emitted, the signed
10 percent blind re-pass has been drawn and annotated, and
`make eval-corpus-signoff` has recorded the attestation. This marker plus that
attestation gate any substrate-v2 training run (`train.py`
`check_substrate_preconditions`, fail closed).

REVIEWER_SIGNOFF: pending
