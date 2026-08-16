---
title: 'Story 12.7: FR-59a.2 re-partition and the must-drop obligation gate'
type: 'feature'
created: '2026-08-12'
status: 'done'
review_loop_iteration: 0
final_revision: '6baaff9'
baseline_revision: '617f43e' # branch tip after the signed FR-59a.2 amendment
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md'
warnings: ['oversized']
---

<intent-contract>

## Intent

**Problem:** The operator signed an amendment on 2026-08-11 reversing one FR-59a.2
exclusion route, because four bands could not otherwise reach 43 candidates
(100-120 had 3, 175-plus 9). The harness still implements the pre-amendment order:
`SHORT_BAND_POLICIES` has no `repartition` value, `build_candidates` still drops
manifest matches, the audit still hard-fails on them, and confirmed training
fingerprint matches still exclude the candidate instead of enumerating what the
training rebuild must drop. Until the harness matches the signed text, no corpus
can be minted and the story cannot close.

**Approach:** Thread a `repartition` short-band policy through candidate
construction so the non-Rekordbox manifest route stops excluding and starts
recording an obligation; give training-fingerprint flags a structured training-row
key so the resulting must-drop list is machine-checkable; emit that list from the
member roster into a gitignored sidecar with only its digest committed; pin
mint-time training inputs per file as immutable provenance; convert the audit's
manifest assertion into a labelled obligation gate; and refuse signoff while the
obligation is open. The rebuild itself and the closure audit against it are
FR-59d work in a later story, per the amendment.

## Boundaries & Constraints

**Always:**
- The signed protocol wins. Where this spec and
  `12-6-metrical-level-convention.md` differ, the protocol is right and the
  difference is a defect. The governing text is "Amendment 2026-08-11: FR-59a.2
  partition ORDER".
- **Only the non-Rekordbox manifest `audioHash` route reverses.** The
  `tony-split` recording-identity route and the `artist` route keep excluding at
  candidate construction, unchanged. The invariant is unchanged: no track, remix,
  or artist appears in both corpora.
- The reversal is conditional on the recorded policy. Under any other
  short-band policy the pre-amendment behaviour must be byte-identical.
- `build_pool_universe` feeds both `cmd_prepare_review` and `plan_commit`; the
  conditionality must be identical on both paths or `candidate_universe_sha256`
  diverges and dispositions stop validating.
- The must-drop list derives from the **member roster**, not from all candidates,
  and is provisional until signoff binds it to the final member set.
- Committed git artifacts stay counts, seeds, band names, prose, and named
  digests only. Row-level must-drop entries live in a gitignored sidecar with its
  digest in the commitment, the pattern `coverage_sha256` already uses.
- Fingerprint coverage rules are untouched: every candidate and every training row
  fingerprinted, uncoverable candidate excluded, uncoverable training row blocks,
  every flag dispositioned before minting.
- `Sources/` and Swift `Tests/` stay byte-identical.
- No emojis. No em-dashes in artifact prose.

**Block If:**
- The amendment would have to be reinterpreted or widened to proceed, including
  any reading that lifts the `tony-split` or `artist` route.
- A band still falls short of 43 after the re-partition, which would mean the
  amendment's premise was wrong and the operator must re-decide.

**Never:**
- No modification of `non-rekordbox-*-manifest.json` or `corpus_splits.json`.
  The rebuild is a later story; the intent contract of the prior 12.7 spec
  forbids it here.
- No minting of an actual corpus, no fingerprint review run, no annotation. The
  fingerprint review decodes audio and is operator-time work.
- No closure audit against rebuilt manifests. Only the refusal that keeps signoff
  fail-closed until that audit exists.
- No new `DSPTechnique` or public Swift API.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| decisions file with `repartition` | valid three-decision doc | accepted; commitment records the policy | unknown policy value rejected |
| candidate construction under `repartition` | pool row whose `audioHash` is in a training manifest | row is KEPT as a candidate; `manifest-hash` exclusion count stays 0; the match is recorded as a partition obligation | none |
| candidate construction under any other policy | same row | excluded exactly as before, counts unchanged | none |
| tony-split / artist row, any policy | matching row | still excluded, counts unchanged | none |
| confirmed training-fingerprint disposition under `repartition` | flag with `disposition: same-recording` | candidate KEPT; its structured training key enters the must-drop set | none |
| confirmed GiantSteps-title disposition | any policy | candidate still EXCLUDED (unchanged) | none |
| must-drop emission | committed corpus with members | gitignored sidecar of `{member row id, training row key}` pairs; digest + count in the commitment | privacy gate rejects any row-level key reaching git |
| audit, mint-time | corpus minted under `repartition` | obligation gate: every member overlapping a current training manifest is on the must-drop list; output labelled as an obligation, not as FR-59a.2 holding | member missing from the list fails the audit |
| audit, non-repartition | corpus minted under another policy | pre-amendment residual-overlap assertion, unchanged | unchanged |
| signoff under `repartition` | audit clean, bands full, re-pass done | REFUSES: partition closure not certified, rebuild is a later story | nonzero exit naming the open obligation |
| training-input drift after rebuild | manifests changed | per-file digest map identifies which manifest moved | drift still raises, but names the file |

</intent-contract>

## Code Map

- `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- SIGNED; amendment at the tail is binding, read-only
- `scripts/build-eval-corpus.py:235` `SHORT_BAND_POLICIES` -- add `repartition`
- `:403-497` `build_candidates` -- manifest branch at `:428-430` becomes conditional; `EXCLUSION_REASONS` (`:250-263`) key set must NOT change, the count simply stays 0
- `:2518-2539` `build_pool_universe` -- shared by prepare-review (`:3197`) and `plan_commit` (`:2626`); policy must reach both identically
- `:2113-2159` `load_operator_decisions` -- new policy branch; `_OPERATOR_DECISIONS_KEYS` (`:1131`), commitment block (`:2769-2774`), md render (`:3152`)
- `:2434-2515` `build_review_flags` -- training flags at `:2475-2487` carry `peer_key: None` deliberately (peer_key feeds `union_recording_groups` with candidate-vs-candidate edges only); add a NEW structured `training_key` field, mirrored in the disposition template at `:3214-3232`
- `:2249-2295` `apply_dispositions` -- `:2282-2283` buckets FINGERPRINT and GIANTSTEPS together; split them so only GiantSteps still excludes
- `:2179-2188` `training_input_digest` -- becomes a per-file digest map; `load_dispositions` drift check at `:2220-2226`
- `:3705-3725` audit residual-overlap -- `:3718-3719` manifest assertion becomes the obligation gate over members (`:3715`); `:3721-3725` tony/artist and the whole GiantSteps block `:3727-3760` stay; success prose `:3843-3847` re-labelled
- `:4537-4604` `cmd_signoff` / `:4425-4535` `validate_attestation` -- closure refusal between `:4551` and `:4553`; `_ATTESTATION_KEYS` (`:1218`) gains the closure field, validated where `train.py` gates
- `:1006-1026` `_DIGEST_PATHS` + `:1034-1070` `privacy_gate` -- exact-path matching, so list indices never match; must-drop rows go to a gitignored sidecar
- `:332-341` `ARTIST_LIMITATION_NOTE` -- copied verbatim into the commitment at `:2753`; the load-bearing false claim
- `scripts/tests/test_build_eval_corpus.py` -- `ws` fixture `:832-856`, `_mint` `:895-899`; tests to update: `test_fr59a2_exclusion_accounting` `:114`, `test_audit_covers_all_candidates_not_only_members` `:1712`, `test_prepare_review_flags_a_training_fingerprint_match` `:1115`

## Tasks & Acceptance

**Execution:**
- [x] `scripts/build-eval-corpus.py` -- add `repartition` to `SHORT_BAND_POLICIES` and validate it in `load_operator_decisions`; thread the policy into `build_pool_universe` and `build_candidates` so the manifest branch is conditional and identical on the prepare-review and mint paths -- rationale: the amendment's single reversed route
- [x] `scripts/build-eval-corpus.py` -- add a structured `training_key` to training-fingerprint flags and to the disposition template; split the confirmed-flag bucket so training matches enumerate while GiantSteps matches still exclude -- rationale: a prose `evidence` string cannot back a machine-checkable must-drop list
- [x] `scripts/build-eval-corpus.py` -- emit the must-drop list from the member roster into a gitignored sidecar; record only its digest, count, and provisional status in the commitment; extend `_COMMITMENT_ACTIVE_KEYS`, `assert_commitment_schema`, `_DIGEST_PATHS`, and `render_commitment_md` -- rationale: obligation must be machine-checkable without publishing row-level private data
- [x] `scripts/build-eval-corpus.py` -- `training_input_digest` becomes a per-file digest map, pinned into the commitment as mint-time provenance -- rationale: after the rebuild, drift must be attributable to a named manifest rather than one opaque hash
- [x] `scripts/build-eval-corpus.py` -- convert the audit's manifest assertion into an obligation gate over members, keep tony/artist/GiantSteps assertions, and re-label the success output so it never claims FR-59a.2 holds -- rationale: amendment gate 1, explicitly labelled
- [x] `scripts/build-eval-corpus.py` -- `cmd_signoff` refuses while partition closure is uncertified; `_ATTESTATION_KEYS` and `validate_attestation` carry the closure field -- rationale: fail-closed until the later story lands, and `train.py` gates on the validator
- [x] `scripts/build-eval-corpus.py` -- correct every prose site that says a confirmed training match excludes: `ARTIST_LIMITATION_NOTE`, the `FINGERPRINT_REVIEW_COSINE` comment, `load_dispositions` halt text, `apply_dispositions` docstring, `render_commitment_md`, module docstring, `build_candidates` docstring -- rationale: `ARTIST_LIMITATION_NOTE` is copied into the committed artifact, so a false claim there ships
- [x] `_bmad-output/ml-training/eval-corpus/12-7-operator-decisions.json` -- write all three recorded decisions: `repartition`, `pre-commitment-recording-dedup` with scarcest-first `band_priority`, dated 2026-08-11 -- rationale: the machine-readable input the harness demands; gitignored
- [x] `scripts/tests/test_build_eval_corpus.py` -- update the three tests the reversal falsifies and add regressions per the I/O matrix -- rationale: two of them currently assert the pre-amendment behaviour
- [x] `_bmad-output/implementation-artifacts/12-7-eval-corpus.md` -- record the amendment, the new partition order, the obligation gate, and the closure work left to FR-59d -- rationale: the artifact still describes the pre-amendment order
- [x] `_bmad-output/implementation-artifacts/spec-12-7-band-balanced-258-track-corpus.md` -- append a dated pointer to this spec in its Review Triage Log; do not touch its `<intent-contract>` -- rationale: the prior spec is the story's record and must not dead-end

**Acceptance Criteria:**
- Given a decisions file recording `repartition`, when candidates are built, then a pool row matching a training manifest is retained, its `manifest-hash` exclusion count is 0, and the match is recorded as a partition obligation
- Given any other short-band policy, when candidates are built, then exclusion counts and the candidate universe digest are byte-identical to the pre-amendment harness
- Given a confirmed training-fingerprint disposition under `repartition`, when dispositions are applied, then the candidate survives and its structured training key reaches the must-drop set; given a confirmed GiantSteps disposition, the candidate is still excluded
- Given a minted corpus with members, when the audit runs, then it asserts every overlapping member is on the must-drop list and its output states it is an obligation gate rather than proof FR-59a.2 holds
- Given a complete corpus with a clean audit, full bands, and a re-pass, when signoff runs, then it refuses because partition closure is uncertified, and `validate_attestation` rejects any attestation lacking the closure field
- Given the committed artifacts, when the privacy gate runs, then no row-level must-drop entry, path, or non-digest hash appears in git
- Given the branch, when diffed against the epic-12 tip, then `Sources/` and Swift `Tests/` are byte-identical and `make py-lint`, `make scripts-tests`, `make test` pass

## Auto Run Result

Status: `done`. The harness now matches the signed FR-59a.2 amendment. Story 12.7
as a whole stays blocked on operator work, which is recorded in the prior spec
and in `12-7-eval-corpus.md`: the fingerprint review decodes audio and needs a
human disposition per flag, then 258 tracks of DAW verification.

**Implemented:** the `repartition` short-band policy and everything the
amendment binds to it. One exclusion route reverses (non-Rekordbox training
manifest by `audioHash`); `tony-split` and `artist` are untouched, and
non-repartition construction is byte-identical, which is test-locked. Training
fingerprint flags gained a structured `training_key`, so confirmed matches
enumerate an obligation instead of excluding the candidate. The must-drop list
is emitted to generation-scoped gitignored sidecars with only digests and counts
in git. Training inputs are pinned per file. The audit runs a labelled obligation
gate over every member by content digest. Signoff refuses until closure is
certified, via one of three bases, with the forward path a separate artifact the
FR-59d story writes rather than a mutation of the minted commitment.

**Also fixed, found during this run and not in the spec:** `load_inputs` read
`r.get("path")` while both committed manifests key it `relPath`, so
`manifest_paths` was EMPTY in production and the training side of the mandatory
fingerprint route silently covered only the tony-split rows, against a signed
requirement that every training row be fingerprinted. Introduced in `c2865b7`
earlier in this same PR. Now reads `relPath` then `path`, fails closed per file,
counts path-less rows as an explicit coverage gap, and carries two regression
tests including one that asserts the production manifests still use `relPath`.

**Files:** `scripts/build-eval-corpus.py`, `scripts/tests/test_build_eval_corpus.py`,
`_bmad-output/implementation-artifacts/12-7-eval-corpus.md`, a dated pointer in
the prior 12.7 spec, and the gitignored `12-7-operator-decisions.json` recording
the operator's three decisions.

**Review:** 20 patches applied (4 high, 8 medium, 8 low), 0 deferred, 1 rejected.
Four of the high findings were defects in code written during this run, including
one in the `relPath` fix itself. See the Review Triage Log.

**Verification:** `make py-lint` clean; eval-corpus suite 240 passed (was 173 at
the start of this run); `make test` 1038 tests / 170 suites passed;
`git diff --stat 31d772e -- Sources/ Tests/` empty; `make eval-corpus-pools`
still refuses and now names only the fingerprint dispositions, since the
decisions file is on record. `make scripts-tests` shows one intermittent failure
in `test_promote_to_main.py`, an environmental 1Password SSH signing error in a
scratch repo, unrelated to this diff.

**Residual risks:** under any policy other than `repartition`, a Tony or OA300
candidate whose content sits in a training manifest is still not excluded. That
is pre-existing, deliberately untouched to preserve the byte-identity guarantee
the amendment's narrow scope depends on, and it is now visible in code rather
than hidden. The FR-59d rebuild and the closure audit against it remain
unwritten, which is why signoff refuses.

## Spec Change Log

## Review Triage Log

### 2026-08-12 -- Review pass (Blind Hunter + Edge Case Hunter)
- intent_gap: 0
- bad_spec: 0
- patch: 20: (high 4, medium 8, low 8)
- defer: 0
- reject: 1
- addressed_findings:
  - `[high]` `[patch]` Must-drop double-counted every retained manifest match: a retained manifest-hash candidate IS the training row it matched, so it fingerprints against itself at cosine 1.0 and both routes recorded the same pair, inflating the commitment-pinned `must_drop_count` roughly 2x. Obligations now carry `routes` and merge on (candidate_key, training row) with fixed precedence.
  - `[high]` `[patch]` Under `repartition`, closure could never be certified: `repartitioned` was read off the immutable commitment so `certified` was permanently false, and the schema allowed no way for the FR-59d story to record closure. This deadlocked the amendment's consequence 5. Three certification bases added (`no-obligation`, `obligation-vacuous`, `closure-record`) with the forward path a separate generation-scoped artifact rather than a mutation of the minted commitment.
  - `[high]` `[patch]` The obligation gate was driven off `manifest_hashes` and restricted to pool rows, which the spec's own Design Note explicitly forbids, so Tony and OA300 members overlapping a training manifest were never gated. Now checks every member by content digest, with a matching content route added under `repartition` only so the gate stays satisfiable without widening any exclusion.
  - `[high]` `[patch]` The new manifest-path guard was half-blind: it sat inside the per-manifest loop but tested the shared accumulator, so a path-less second manifest passed, and path-less rows never entered coverage at all so `assert_training_coverage` could not block on them. Guard is now per-file and path-less rows carry a `no-path` coverage reason.
  - 8 medium patches: `excluded_fingerprint_matches` also counted GiantSteps exclusions; the rendered split did not reconcile with the total it claimed to split; the write-back digest check was a tautology comparing an object to itself; a failing audit clobbered the member listing with an empty one; the member list was claimed bound while nothing read it; the must-drop sidecar was not generation-scoped so a remint made the archived commitment unverifiable; the commitment gained required keys with no `schema_version` bump (3 to 4); `validate_attestation` and `partition_closure_state` disagreed on what "open" means.
  - 8 low patches: `training_row_key` accepted any namespace despite routing exclude-vs-enumerate through an operator-editable template; stale member sidecar and a `date.today()` stamp that churned the digest; `int()` raising on a non-numeric committed value; `AttributeError` on a non-dict decisions block; `read_mint_obligations` made a gitignored file a hard prerequisite for non-repartition corpora; `partition_order` was not bound so a pre-amendment review was silently accepted when overlap was zero; stale two-policy prose in the committed markdown; and my own regression test re-implemented the read inline instead of calling `load_inputs`.
  - Rejected: the claim that moving the decisions load earlier in `cmd_prepare_review` reversed a deliberate ordering. Failing fast before thousands of audio decodes is correct; the reviewer conflated it with the `assert_training_coverage` check, which still runs after the coverage pass.

### 2026-08-15 -- Continuous DJ mixes were never excluded from the candidate pool
- intent_gap: 0
- bad_spec: 0
- patch: 1 (high 1)
- defer: 0
- reject: 0
- addressed_findings:
  - `[high]` `[patch]` 18 continuous DJ mixes, up to 95 minutes, were in the evaluation candidate pool, most under a `Drum and Bass/Mixes/` directory, 9 of them in `175-plus` (8 percent of that band). A set has no single verified tempo, so any drawn into a batch would have asked the annotator for a number that does not exist. The predicate already existed in shared code the harness imports (`corpus_common.is_continuous_mix`) and the training manifests already excluded on it; the evaluation pool never called it. `drop_continuous_mixes` now runs inside `build_pool_universe` (so prepare-review and every mint see the same pool) ahead of content binding and the fingerprint route, reusing that predicate rather than a second definition. An unknown duration refuses rather than defaulting to "not a mix", the discipline `corpus_manifests._partition` already applies on the training side. `EXCLUSION_REASONS` gains `continuous-mix`, so the count reaches the committed accounting instead of being a silent drop. Pool 2,838 to 2,820; `175-plus` 113 to 104 against a 43-member target.
  - Found by working the operator's question -- "do the checksums match, do the lengths match, is there a fuzzy metadata match" -- rather than handing him 185 pairs to judge by ear. The same evidence pass reduced that review to four group decisions and two genuine listens, and turned up this defect on the way.
  - 5 regression tests, each verified to fail without its fix: a long set and a `Mixes/` file are both excluded; an unknown duration refuses; a row whose audio does not resolve is left to its own exclusion; the count reaches the committed accounting; and a tagless file still reports its duration.
  - Two self-corrections during the fix, both from verifying instead of asserting. The first version carried a stdlib WAV reader justified by "mutagen reports no length for plain WAV" -- false. A `mutagen` file object is dict-like over its tags, so an UNTAGGED file is falsy while still holding a good `info.length`; the harness helper checked `is None` and was already right, and it was the throwaway analysis script that used truthiness and miscounted 42 candidates as having no duration. The reader is now plain `mutagen` with a test that fails if anyone shortens the check to `if parsed:`. The second version read the `pool-durations.json` sidecar; measuring showed all 2,838 header reads take 0.6 seconds, so the sidecar was removed rather than carry a staleness question for no gain.

### 2026-08-15 -- Interrupted-write recovery (round-4 state-machine finding, operator-approved)
- intent_gap: 0
- bad_spec: 0
- patch: 6 (high 6)
- defer: 0
- reject: 0
- addressed_findings:
  - `[high]` `[patch]` Interrupted staging was terminal. `stage-batch` writes the batch record before copying audio so an interrupted copy leaves a record rather than orphan files, and `plan_batch` carries a resume for exactly that state, but `require_valid_state` ran first and `validate_worklist` read the absent worklist as tampering. Every command refused and the only documented way out was unreachable. `validate_worklist` now takes `worklist_required`, true only for a batch whose annotations an event has accepted; `interrupted_staging` names the recoverable batches, `run_audit` refuses to certify while one is outstanding, `status` prints them, and `plan_batch`'s refusal message names the `--batch N` resume.
  - `[high]` `[patch]` Ingest wrote the annotation record at its final path and then appended the event, so a crash between the two left a record no event referenced. `validate_state` reads that as an added or moved record and refuses forever, on a file holding labels that cannot be regenerated, so deleting the orphan is not an available fix. The same window existed on both re-pass writers, where a re-run on a later date would additionally hit `IMMUTABLE RECORD` on the changed date stamp. Records now stage to a `.pending` sidecar and install only after their event is appended; `replay_pending_records` completes an interrupted install from `load_state`, but only when the sidecar hashes to the digest that event recorded. The final path keeps its immutability; the unanchored sidecar does not, since a record no event anchored was never certified. `_write_json_immutable` is removed rather than left available to reopen the window.
  - `[high]` `[patch]` Found while fixing the two above, by asking what else shared their shape, and confirmed by probe: `cmd_ingest` and `cmd_abandon` append the event and then write the tracked ledger head, so a crash between the two left the head behind the ledger. Section 7's staleness check then refused on every command, over events that were already durable, with no way forward (`status` and a re-ingest both returned 1). `repair_stale_ledger_head` re-derives it from `load_state`, but in one direction only: the head must be bound to the same commitment and the ledger's own bytes must still produce the recorded digest at the recorded count, verified by `ledger_head_is_a_verified_prefix`. A head naming a count the ledger no longer reaches, or a digest it no longer produces there, is truncation or rewriting behind git-committed evidence and still refuses.
  - `[high]` `[patch]` The replay trusted the path its event named. It runs before the chain walk, the commitment binding, and the transition check, so `annotation_path` is still unvalidated JSON at that point: an absolute or traversing value steered `os.replace` anywhere on disk, and a matching sidecar was moved before tampering was reported, including inside `run_audit`. Every candidate must now be relative and land under the root that ledger's records belong to. The `_under` confinement is what bites; the `is_absolute` check in front of it is defense in depth, not an independent guard.
  - `[high]` `[patch]` `install_pending_record` called `os.replace` unconditionally, so a final path that appeared between staging and install was silently overwritten and the sidecar became a route around the immutability it sits behind. It now re-verifies the digest immediately before the move rather than trusting the earlier staging call, treats identical bytes as a completed install, and raises on different bytes. The check-then-replace race is not closed by this and is not claimed to be; this is a single-operator harness.
  - `[high]` `[patch]` A sidecar is invisible to the `*.json` orphan scans by design, and that invisibility extended to the operator: `abandon` could terminalize a batch whose complete labels sat unanchored, and `prior_generation_annotation_state` did not count one, so a re-mint could land over a real annotation pass (it also globbed no re-pass records at all). `unanchored_records` now names them, `status` prints them, `run_audit` refuses certification, the re-mint blocker counts them, and `abandon` requires `--force`.
  - 15 regression tests, each verified to fail against the source without its fix: the resume path is reachable and the batch ingests afterwards; the audit refuses while staging is interrupted; a missing worklist on an ingested batch is still tamper; a batch abandoned after ingest still requires its worklist; a batch abandoned straight out of interrupted staging does not; a record written without its event leaves no orphan, stages the submitted labels, and the ingest is re-runnable; a crash between the append and the install is recovered on the primary path and on the re-pass path; a staged-but-uninstalled record is replayed from its event; a sidecar that does not match its event is left alone; a replay will not write outside its own root; installing over an occupied final path is refused; an unanchored staged record is visible and blocks; a head left behind by an interrupted append is re-derived; a head ahead of the ledger is still tamper; a rewritten ledger under a behind head is not repaired.
  - Two test weaknesses the review caught in my own regressions, both fixed and re-proved: the record-without-event test never asserted the sidecar existed or held the submitted labels, so an implementation that wrote nothing before the append would have passed it; and the path-confinement test used a hand-written `..` chain that did not actually resolve outside the root, so it passed against an unconfined implementation. The second one passed for two independent wrong reasons before it was made to bite.
  - Provenance: the first two findings above were found by this session's own pass and confirmed independently by a Codex adversarial review of the same diff; the three new ones came from that review and were each verified against the code before being accepted. The review's remaining observations (torn ledger-line writes blocking `read_events` before recovery, and re-pass signoff not revalidating the recorded population digest after membership changes) are pre-existing and outside this diff.

## Design Notes

- **Why a new field rather than `peer_key`.** `peer_key` exists to carry a
  candidate-vs-candidate edge into `union_recording_groups`. A training row is not
  a candidate; putting it there would inject a non-candidate node into the
  recording-group graph and onto pool entries. Hence `training_key`.
- **Why the sidecar.** `_DIGEST_PATHS` matches exact JSON paths, so
  `/must_drop/0/hash` can never be allowlisted, and `manifest:<audioHash>` is
  hash-shaped and trips the gate outright. The `coverage_sha256` plus gitignored
  `COVERAGE_PATH` pattern already solves this shape.
- **Why the obligation gate reads flags, not `manifest_hashes`.** The existing
  manifest check only covers `source == "pool"`; Tony and OA300 rows that match a
  manifest by content are caught solely by the fingerprint route. Driving the gate
  off `manifest_hashes` would silently miss them.
- **Expected post-rebuild drift.** Once the rebuild lands, `load_dispositions`
  will raise on training-input drift for every later run. That is anticipated by
  amendment item 4; the per-file digest map exists so the raise names which
  manifest moved rather than reporting one opaque mismatch.
- **Knock-on effects of no longer excluding confirmed training matches**, which
  the implementer will hit and must handle deliberately rather than discover:
  `apply_dispositions` returns `confirmed`, which feeds the commitment's
  `fingerprint_review.confirmed_same_recording` and `cleared = len(flags) -
  confirmed`. Those two counts now mean "enumerated as a partition obligation",
  not "excluded", so they need renaming or re-describing in both the commitment
  and `render_commitment_md`. Retaining the candidates also shrinks
  `excluded_for_cause`, which the fallback enumerator reads, and changes the
  generation id, since that is derived from the pool and draw bytes. None of
  these is a defect; all of them change committed values and must be expected in
  tests rather than treated as regressions.

## Verification

**Commands:**
- `make py-lint` -- ruff + ty clean
- `make scripts-tests` -- all pass, including the updated and new eval-corpus cases
- `make test` -- 1038 tests / 170 suites, unchanged
- `make eval-corpus-pools` -- still refuses, now naming only the fingerprint dispositions as outstanding, since the decisions file is present
- `git diff --stat 31d772e -- Sources/ Tests/` -- empty
