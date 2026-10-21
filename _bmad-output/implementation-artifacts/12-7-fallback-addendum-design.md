# Post-mint fallback addendum — design for review

## Problem

A band ran dry AFTER the mint. `100-120` holds 263 candidates but 96% carry tags
at 2/3 of true tempo (tag 116 -> verified 174), so it cannot reach 43 members.
Discovered by annotation, not predictable at mint time: banding is by face-value
tag only, and consulting a tempo estimate at pool construction is exactly what
FR-59a.1 forbids.

The signed protocol has `fallback-addendum` as one of three short-band policies:
enumerate an extension set, commit it as a dated addendum, give it "its own draw
sequence appended after the exhausted one".

But the harness only consults it inside `plan_commit`. Activating it needs a
mint; a mint needs supersede + remint; `prior_generation_annotation_state`
correctly refuses while annotation state exists. There are 9 ledger events and
172 hand-verified members across 4 completed bands. Those cannot be discarded.

## Constraint that shapes everything

`generation = "g" + sha256(pools_doc + draws_doc)[:16]`. Every annotation path is
generation-scoped. So the addendum must NOT touch `pools_doc` or `draws_doc`.

## Proposed design

New generation-scoped artifact `generations/<gen>/addendum-<seq>.json`, row-level,
gitignored. Committed side is `12-7-fallback-addendum.json` with counts + digest
only (privacy gate: no paths, no hashes of private audio in git).

Content per band: candidate rows in the same schema as primary rows, with
`sequencePosition` continuing after the primary length and `origin:
"fallback-addendum"`.

Single reader change:

    def sequence(self, band):
        return self.pools["bands"][band] + self.addendum_rows(band)

Everything else reads through `sequence()` / `sequence_row_ids()` / `by_row_id`:
`validate_batch_records`, `compute_membership`, `plan_batch`, `run_audit`.

## Invariants I intend to enforce and test

1. The generation id is unchanged by adding an addendum.
2. `pool_file_sha256` / `draw_file_sha256` still match; those files are untouched.
3. Addendum rows never reorder or renumber primary rows.
4. No row-id collision between primary and addendum.
5. Addendum immutable once written; a further extension appends a NEW file.
6. Addendum rows pass the SAME gates as primary: training-manifest exclusion,
   tony-split, artist, continuous-mix, content binding, fingerprint coverage.
7. The addendum digest is recorded and re-verified in `validate_state`.
8. An addendum may only extend a band whose sequence is genuinely exhausted.
9. Existing batch records still validate (their slices are a prefix).

## The problem I have not solved

The fingerprint review ran over the COMMITTED candidate universe, and
`fingerprint-dispositions.json` is bound to `candidate_universe_sha256`. Addendum
rows were not in that universe, so they have no dispositions. Options I see:

(a) A second review pass scoped to the addendum rows only, producing an addendum
    dispositions file bound to an addendum universe digest.
(b) Refuse to admit any addendum row that produces a fingerprint flag at all
    (conservative, no human review needed, may discard valid rows).
(c) Something better.

## Questions

1. Is the single-chokepoint `sequence()` change actually sufficient, or are there
   readers that bypass it and would silently see only the primary rows?
2. Does appending to the sequence break the membership tie-break? Membership is
   "first 43 keepers in draw order"; addendum rows are strictly later, which I
   believe is correct, but the surplus/duplicate logic reads sequence position.
3. Is a per-band addendum right, or should it be corpus-wide with per-band lists?
4. How should the fingerprint-disposition gap be closed? (a), (b) or something else?
5. What am I not seeing? This changes the meaning of a committed draw sequence
   after annotation has begun, which is the kind of change that has bitten this
   file repeatedly.

## Correction found while waiting for review (2026-08-26)

The "single chokepoint" claim in this document is FALSE. Two readers bypass
`HarnessState.sequence()` and go straight to `pools["bands"][name]`, and both
are in `run_audit`, on the two guarantees the corpus exists to make:

- `:5265` the FR-59a.1 allowlist over every candidate row, which is what stops a
  DSP quantity ever appearing in a candidate.
- `:5288` `all_candidates`, the FR-59a.2 residual-overlap pass, explicitly "all
  candidates, not only members".

An addendum built on the claim above would have skipped both: an addendum row
could have carried a DSP field, or overlapped the training set, and neither
check would have looked at it. Any implementation must route these two through
the extended sequence as well, and a test must fail if either regresses to the
primary rows.
