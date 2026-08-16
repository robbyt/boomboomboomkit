# Story 12.7: the 258-track band-balanced evaluation corpus

Date: 2026-08-08, reworked 2026-08-10, 2026-08-11 after the second PR #197
review, and 2026-08-12 for the signed FR-59a.2 partition-order amendment.
Status: harness complete; corpus construction BLOCKED. The candidate commitment
minted on 2026-08-08 is SUPERSEDED and no consumer will operate on it.
Construction restarts at an explicit re-mint (`make eval-corpus-remint`), which
is now blocked on the pre-commitment fingerprint review ALONE: both operator
decisions are on record as of 2026-08-11 and supplied as machine-readable input.
No track has been verified or labelled by this run; no annotation was simulated
or invented.

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
`declared:metrical-full-tempo-v1-2026-08-08`), and the separately signed
**Amendment 2026-08-11: FR-59a.2 partition ORDER** in section 6. Where the
harness and the protocol could differ, the protocol wins.

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

## The signed 2026-08-11 amendment: FR-59a.2 partition ORDER

The operator signed an amendment on 2026-08-11 that changes the ORDER in which
the eval and training corpora are partitioned. It does not change the invariant
they are partitioned for: no track, no remix, and no artist appears in both
corpora.

**Exactly one of the three exclusion routes reverses direction.** Matching a row
in the two non-Rekordbox TRAINING MANIFESTS by audio content (`audioHash`) no
longer removes a candidate from the eval draw. The eval corpus draws it and the
training rebuild drops it. The `corpus_splits.json` tony.train and tony.val
recording-identity route and the artist-string route are UNCHANGED and still
exclude at candidate construction, so artist-level disjointness survives intact.
A confirmed fingerprint match whose training peer is a tony.train or tony.val row
also still excludes: that is the recording-identity route under another name.

The reversal is conditional on the recorded short-band policy. Under
`repartition` it applies; under every other policy candidate construction is
byte-identical to the pre-amendment harness, down to the exclusion counts and the
candidate-universe digest, and the test suite asserts that rather than assuming
it. The policy is derived on the `prepare-review` path and the mint path through
one function, because those two share `build_pool_universe` and a divergence
there would move `candidate_universe_sha256` on one path only and silently
invalidate every recorded fingerprint disposition.

**The `manifest-hash` exclusion reason is NOT removed.** Its count simply stays 0
under the reversed route. That key set is a frozen schema used by the commitment
and by superseded-record rendering, and dropping a key would make an archived
record unreadable against today's shape.

**The audit becomes two gates.** The MINT-TIME obligation gate, which this
harness runs, asserts that every eval member appearing in a current training
manifest is named on a recorded must-drop list. It is driven off the recorded
obligation set cross-checked against today's manifests, over every member
regardless of source: a manifest `audioHash` is sha256 over the raw bytes, which
is exactly the `contentSha256` bound onto every candidate row, so Tony and OA300
members are covered as well as pool ones. A re-encode sharing no bytes is
invisible to that check by construction and is covered only by the mint-time
fingerprint route, which is stated in the audit's own report line rather than
papered over. The gate is labelled as an obligation everywhere it is reported,
including the audit's success line: a clean run records that the rebuild has been
told what to drop, NOT that FR-59a.2 currently holds.

The SIGNOFF-TIME closure gate is a fresh audit against the REBUILT training
corpus finding zero overlap, which re-runs the full comparison rather than
confirming the listed rows disappeared, because a rebuild can introduce a
re-encode that was never on the list. That rebuild and that audit are FR-59d work
in a later story, so `make eval-corpus-signoff` REFUSES while the obligation is
open. Training therefore stays blocked, which is the intent: every accuracy
figure from a model trained before the rebuild is contaminated against this
corpus and must be discarded.

**The refusal has a forward path, because the rebuild and signoff must not
deadlock** (signed amendment, consequence 5). Closure is certified on any of
three bases. `no-obligation`: the corpus was not minted under the reversed route.
`obligation-vacuous`: it was, but the measured overlap is zero, so there is
nothing for the rebuild to drop and refusing forever would be a deadlock with no
work behind it. `closure-record`: a later story ran the rebuild and wrote a
closure record. That record is a separate gitignored artifact, deliberately NOT a
mutation of the minted commitment, whose archived copies must stay verifiable; it
binds the commitment digest, the mint-time must-drop digest, the member-scoped
list digest, the post-rebuild training-input digests, and a residual overlap of
zero. A record that fails any of those bindings is an AUDIT failure, because a
closure claim that does not verify is worse than none. `cmd_signoff` and
`validate_attestation` (which `train.py` gates on) both read the closure state
through one function, so the writer and the validator cannot disagree.

**The must-drop list derives from the MEMBER roster, not from all candidates.**
Dropping training rows for candidates that were rejected or ended up surplus
would starve training for nothing. Membership evolves during annotation, so the
list is provisional and regenerated by every clean audit against the
annotation-ledger head, and it records the commitment digest, the per-file
training-input digests pinned at mint, the fingerprint method, and the
dispositions digest. It carries no wall-clock field, so its digest is a pure
function of the state it describes. That digest is NOT pinned in the commitment,
which is immutable while membership is not; it is bound at closure time by the
closure record, and the audit fails if a present closure record binds a different
member set. A failing audit never rewrites the list, so an empty file always
means "no obligations" and never "the audit blew up".

**Row-level obligations never enter git.** They live in two gitignored,
generation-scoped sidecars, `must-drop-obligation.json` (the mint-time universe
over candidates, whose digest and counts the commitment pins) and
`must-drop-members.json` (the member-scoped provisional list). Only the digest
and the counts are committed, the pattern `coverage_sha256` already uses. The
privacy gate matches EXACT json paths, so a list index can never be allowlisted,
and a bare `audioHash` row id is hash-shaped and trips the gate on its own.
Generation-scoped rather than at the state root, unlike the coverage record,
because the commitment PINS the mint-time digest: a state-root file would be
clobbered by the next re-mint and make every archived commitment unverifiable.
Two sidecars rather than one because the commitment is immutable once minted
while membership is not.

**One obligation per (eval row, training row) pair.** A retained manifest-hash
candidate IS the training row it matched, so it fingerprints against itself at
cosine 1.0 and the confirmed flag records the same pair a second time.
Obligations are deduplicated on the pair and carry every route that found them,
so `must_drop_count` (pinned in the immutable commitment, and what the FR-59d
rebuild joins on) counts distinct pairs. The per-route figures are therefore
ATTRIBUTIONS, not a partition, and the rendered markdown says so rather than
presenting them as arithmetic.

**A confirmed training-fingerprint match now means something different in the
commitment.** `fingerprint_review.confirmed_same_recording` and its `cleared`
complement count confirmed matches, and under the reversed route a confirmed
match no longer implies an exclusion. The outcomes are reported explicitly in the
new `partition_obligation` block and in the rendered markdown:
`excluded_by_confirmed_disposition` with its two attributions
(`excluded_training_fingerprint_matches`, `excluded_giantsteps_matches`) versus
`enumerated_fingerprint_matches`. Those are attributions rather than a partition,
because one candidate can carry several confirmed flags. Retaining candidates
also shrinks the excluded-for-cause set that the fallback enumerator reads and
changes the generation id, since that is derived from the pool and draw bytes.
Those are expected value changes, not regressions. The commitment's
`schema_version` moves 3 to 4, because an active record now REQUIRES
`partition_obligation` and `fingerprint_review.training_input_digests` and a
reader keyed on the version has to be able to tell the two shapes apart.

**Expected post-rebuild drift.** Once the FR-59d rebuild lands, the training
inputs move and `load_dispositions` will raise on training-input drift for every
later run. The amendment anticipates that. The digest is now recorded PER FILE
and pinned into the commitment as immutable mint-time provenance, so the raise
names which manifest moved instead of reporting one opaque mismatch.

## What blocks the re-mint

Both operator decisions are now ON RECORD, dated 2026-08-11 and supplied as
machine-readable input at
`_bmad-output/ml-training/eval-corpus/12-7-operator-decisions.json` (gitignored,
its digest recorded in the commitment). The harness still refuses to mint if the
file is absent rather than inferring a policy from prose. What remains is the
pre-commitment fingerprint review, which is operator-time work because it decodes
audio.

**(a) Short-band allocation: `repartition`.** At the superseded commitment four
bands could not reach 43 candidates: 100-120 at 3 of 43, 120-140 at 28 of 43,
160-175 at 41 of 43, and 175-plus at 9 of 43. The cause is the FR-59a.2
manifest-hash exclusion, which removes nearly the whole tag-carrying
non-Rekordbox pool because the two committed training manifests cover it.

The signed exhaustion fallback does not resolve this, and an earlier version of
this artifact was wrong to present it as the next action. Its source order is
Tony as-entered rows, then OA300 rows, and both are already inside the primary
pools, so the fallback set is empty by construction and its measured net-new set
is zero for every band. Restoring Tony's unresolved audio was investigated and
abandoned on 2026-08-11: of 373 unresolved rows only 19 were recoverable and none
sat in a short band.

The operator chose the re-partition over shrinking the corpus, and the scope was
then narrowed on the same day from all three exclusion routes to the manifest
route alone, once it was measured that the narrow lift already clears 43 in every
band: 100-120 from 3 to 265, 175-plus from 9 to 113, 120-140 to 80, 140-160 to
102, 160-175 to 143, sub-100 to 2,194. Those counts are pre-dedup, so the
committed pools are re-checked against 43 at mint rather than assumed from them.
The narrowing is strictly more conservative than what was approved and preserves
the artist rule the broader version would have weakened.

The harness implements all three policies, and it ENUMERATES the signed fallback
under every one of them. That correction matters: until 2026-08-11 only
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

**(b) Cross-band duplicate rule: `pre-commitment-recording-dedup`,
scarcest-first.** The signed tie-break is "earlier in the
membership draw sequence wins", which orders rows WITHIN a band and defines no
winner BETWEEN two bands. This is not a corner case in this collection: the same
recording tagged 85 in one source and 170 in another lands in two different bands
by construction, which is the dominant half-versus-full-tempo pattern the 12.6
evidence describes. The harness implements `pre-commitment-recording-dedup` (a
recording is kept only in the highest-priority band, priority recorded) and
`audit-fails-on-cross-band-duplicate` (no pre-dedup; the audit's cross-band
duplicate check is the rule). Choosing after annotation has begun would be
improvising over frozen labels, so it is decided before the re-mint.

The operator decided `pre-commitment-recording-dedup` on 2026-08-11, bound with
the amendment signature: a recording qualifying for two bands is resolved BEFORE
annotation rather than at the audit, so no track is ever verified twice, and the
band that keeps it is chosen scarcest-first, in the order 175-plus, 100-120,
120-140, 160-175, 140-160, sub-100. Scarcest-first also happens to favour the
faster band, which is where a half-tagged track actually verifies under the
full-tempo convention.

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

## Continuous DJ mixes are not candidates (2026-08-15)

A continuous DJ set has no single verified tempo, so it cannot be annotated: put
in front of the annotator it asks for a number that does not exist, and answered
anyway it puts a meaningless label in the corpus. The training manifests already
exclude these at emission. The evaluation candidate pool did not, and 18 of them
were in it, up to 95 minutes long, most sitting in a `Drum and Bass/Mixes/`
directory. Nine were in `175-plus`, which is 8 percent of the second-scarcest
band.

The exclusion now runs inside `build_pool_universe`, so `prepare-review` and
every mint see the same pool, and it runs before content binding and long before
the fingerprint route, because there is nothing to gain by hashing or decoding a
set that is not a candidate. The predicate is `corpus_common.is_continuous_mix`,
the same function the training side excludes on, rather than a second definition
that could drift from it. Duration comes from each file's own header: reading all
2,838 takes 0.6 seconds, so the `pool-durations.json` sidecar would buy nothing
here while adding a staleness question, since it covers only the pool rows.

**An unknown duration is not read as "not a mix".** Duration is half the
predicate, so a resolvable file whose length cannot be established is one this
rule cannot answer for, and it refuses rather than guessing. Rows whose audio
does not resolve at all are left to the exclusions that already own them.

Effect on the pool: 2,838 candidates to 2,820, and `175-plus` from 113 to 104
against a 43-member target. That is the tightest ratio in the corpus and is worth
watching once a real keeper rate exists.

## The pre-commitment fingerprint review

The signed route is mandatory and runs before commitment, so it is a two-stage
gate rather than a report. `prepare-review` computes the flags: candidate audio
matching a training recording at or above the DD #3 review cosine (0.97), plus
GiantSteps normalized-title collisions, which are conservative heuristics because
`normalize_track_key` drops suffixes and parenthesized material. `commit-pools`
then refuses to mint until every flag carries a recorded human disposition. The
algorithm flags; the human disposition disposes. That is what DD #3's "never the
sole auto-exclusion signal" requires, and it does not make the route optional.

What a confirmation DOES depends on the recorded partition order. A confirmed
GiantSteps-title match always excludes. A confirmed training-fingerprint match
excludes too, except under the signed `repartition` order when the training peer
is a training-MANIFEST row, in which case the candidate is retained and the match
is enumerated as a must-drop obligation. Training-fingerprint flags therefore
carry a STRUCTURED `training_key` (namespace plus row id) alongside the prose
`evidence` string, because a prose string cannot back a machine-checkable
must-drop list and the rebuild has to join on the row id. That key is mirrored
into the disposition template so an operator's filled file round-trips it.
`peer_key` deliberately stays `None` on these flags: it carries
candidate-vs-candidate edges into `union_recording_groups`, and a training row is
not a candidate, so reusing it would inject a non-candidate node into the
recording-group graph and onto pool entries.

Each disposition set is bound to the candidate-universe digest, the fingerprint
method version, the training-input digest, and the recorded PARTITION ORDER, so a
change to the short-band allocation cannot silently reuse adjudications made
against a different universe or a different meaning of "confirmed". The order is
bound explicitly rather than inferred from the universe digest: with zero overlap
between the pool and the training manifests both orders produce an identical
universe, so the digest alone would accept a pre-amendment review under a
`repartition` mint. The training peer recorded on a flag is derived evidence, not
an operator field, and a disposition file whose `training_key` disagrees with the
harness-generated flag is rejected rather than obeyed.

The review RUN is deliberately not performed here. It decodes audio and is
operator-time work, and it must be run AFTER the decisions file is in place: the
recorded short-band policy sets the partition order, which sets the candidate
universe, so a review run under the wrong order produces dispositions the mint
refuses. The decisions file is now in place, so the review is the single
remaining blocker on the re-mint.

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

**An interrupted write is a state to recover from, not tamper evidence.** Three
crash windows were terminal until 2026-08-15, all three created by the integrity
checks above rather than by the work they guard. Staging writes the batch record
before copying audio, so an interrupted copy leaves a record rather than orphan
files, and `plan_batch` documents a resume for exactly that state; but the state
validation ran first and read the absent worklist as tampering, so every command
refused and the documented resume was unreachable. A worklist is now required
only for a batch whose annotations an event has accepted, which is the case
where it is evidence. The batch is re-stageable from its committed record, the
audit still refuses to certify a corpus while one is outstanding, and `status`
names it. Separately, ingest wrote the annotation record at its final path and
then appended the event, so a crash between the two left a record no event
referenced, which reads as an added or moved record and refuses forever, on a
file holding labels that cannot be regenerated. Records now wait in a `.pending`
sidecar and are installed only after the event naming them is on the ledger; if
the process stops between the append and the install, the next run completes it,
but only when the sidecar's bytes hash to the digest that event recorded. The
final path stays immutable in both directions: an install re-verifies the digest
immediately before the move and refuses an occupied final path outright, so the
sidecar cannot become a way around the immutability it sits behind. Nothing is
deleted and nothing is guessed.

Two things follow from a sidecar existing at all. The path an event names is not
trusted when the replay reads it, because the replay runs before the chain walk,
the commitment binding, and the transition check, so every candidate must be a
relative path landing under the root that ledger's records belong to. And a
sidecar is deliberately invisible to the scans that look for records no event
references, since an unanchored record is not an orphan; that invisibility stops
at the operator. A staged record no event names is printed by `status`, refuses
certification in the audit, blocks a re-mint, and makes `abandon` ask before
discarding it, because it is a real annotation pass someone has already done.

The third window was the tracked annotation-ledger head. `ingest` and `abandon`
append the event and then write the head, so a crash between the two left the
head recording fewer events than the ledger held, and the staleness check refused
on every command over a ledger whose events were already durable. The head is
derived from the ledger, so completing that write is a repair rather than a
judgement, but only in one direction: the ledger's own bytes must still produce
the digest the head recorded at the count it recorded. A head naming a count the
ledger no longer reaches, or a digest it no longer produces at that count, means
the ledger was truncated or rewritten behind git-committed evidence, and that
still refuses. This third window was found while fixing the first two, by asking
what else shared their shape.

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
passes, every band holds its full membership, the FR-59a.2 partition closure is
certified, and a validated blind re-pass exists, and which is bound to the active
commitment digest, the annotation-ledger head, and the re-pass record digest.
`train.py` `check_substrate_preconditions` validates that attestation, so
hand-editing the marker below buys no training run.

Under the signed `repartition` order with a non-empty must-drop list the closure
is NOT certified until a verified closure record exists, so signoff refuses and
no attestation is written. The attestation carries a `partition_closure` block
naming the basis and, where one applies, the closure record's digest. The
validator recomputes that state from the artifacts on disk through the same
function `signoff` used, so it rejects an attestation whose closure is absent or
uncertified, one that claims certification the artifacts do not support (a
commitment naming the reversed policy is enough to keep it open, whatever its
recorded status string), and one that binds a closure record that has since
changed or vanished.

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
10 percent blind re-pass has been drawn and annotated, the FR-59a.2 partition
closure is certified against the REBUILT training corpus, and
`make eval-corpus-signoff` has recorded the attestation. This marker plus that
attestation gate any substrate-v2 training run (`train.py`
`check_substrate_preconditions`, fail closed).

## Left to FR-59d (a later story)

The training-corpus rebuild and the closure gate are explicitly out of scope
here, and this story's intent contract forbids modifying
`non-rekordbox-*-manifest.json` or `corpus_splits.json`. What the later story
owes: rebuild the two training manifests with every row on the member-scoped
must-drop list removed; re-run the FR-59a.2 comparison in full against the
rebuilt corpus; and write the closure record at
`generations/<generation>/partition-closure.json` recording a residual overlap of
zero and binding the commitment digest, the mint-time must-drop digest, the
member-list digest, and the post-rebuild training-input digests. The harness
validates all of that and refuses anything less. Until then the obligation is
open by design and no model may train against this corpus.

Two consequences the rebuild should expect. The per-file training-input digests
will move, which `load_dispositions` reports by NAMING the manifests that
changed. And `training_input_paths()` resolves the manifest constants at call
time rather than freezing them at import, so pointing the harness at rebuilt
manifests actually redirects the digests instead of silently digesting the
originals.

REVIEWER_SIGNOFF: pending
