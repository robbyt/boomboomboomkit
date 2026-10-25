---
title: 'Story 12.7: close the evaluation corpus at its current coverage'
type: 'feature'
created: '2026-10-23'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '46ef580b9268dc8cb397a27f7d3599027543f73d'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-12-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/12-7-eval-corpus.md'
  - '{project-root}/_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md'
---

<frozen-after-approval reason="human-owned intent, do not modify unless human renegotiates">

## Intent

**Problem:** The 12.7 evaluation corpus has 172 of 258 tracks verified, all at 120 BPM or faster: the 120-140, 140-160, 160-175 and 175-plus bands hold 43 each, while 100-120 and sub-100 hold none. The harness will not write the corpus file until every band holds 43, so nothing downstream (Story 12.9) can use the verified tracks, and the slow tempos where the tempo model fails most have no representation at all. The operator does not want to annotate more tracks to unblock this.

**Approach:** Use only annotation that already exists. Record the operator's annotation of the 100-120 batch 0 inside the harness, let the harness write a corpus file that states which bands are short and why, add a small labelled set of slow-tempo tracks the operator already annotated, and amend the signed protocol to say so. Filling the two slow bands to 43, the blind 10 percent re-listen, and the training-overlap sign-off move to later work. The training gate in `train.py` stays closed.

## Operator decisions (2026-10-23)

1. The operator saw, or cannot rule out having seen, BoomBoomBoomKit's per-track tempo estimates for the `x1-` files before setting their tempos. The 13 slow `x1-` tracks (11 in 100-120, 2 under 100) therefore enter the slow-tempo set tagged `detector-visible`: listed and reported, so failures in that range stay visible, but excluded from any pass or fail gate. The `e1-` track verified at 85 BPM was annotated from a blinded worklist and carries no such tag.
2. The spec is kept whole (about 3,500 tokens) because its three parts serve one goal.

## Boundaries & Constraints

**Always:**
- No new annotation by the operator. Every verified tempo comes from `/Users/rterhaar/Desktop/batch-000/hand-annotated-training.dawproject` as it exists today, read with `scripts/dawproject-bpm.py --json` (extraction only; `--match` is forbidden by the 12.6 protocol step 3).
- The 100-120 batch 0 is ingested through the existing `ingest` command, unchanged: its 40 tracks become out-of-band rejections with their tempos kept (0 members), which records the "file tags read two-thirds of the true tempo" finding inside the harness.
- `emit-manifest` writes a corpus file when the only shortfall is in bands the operator has declared short in a dated, committed declaration file; the file gains a top-level per-band block (members, target 43, short reason). Every other refusal in `emit-manifest` stays.
- `signoff`, `validate_attestation`, `repass-sample` and the `train.py` gate are unchanged and keep refusing. `REVIEWER_SIGNOFF` in `12-7-eval-corpus.md` stays `pending`.
- Slow-tempo tracks from outside the committed pool are written to a separate supplement file, never into band membership, each tagged with its source, and the `x1-` tracks also tagged `detector-visible` per operator decision 1; every one is first checked for training overlap by audio fingerprint (reuse `_fingerprint_one`, the training half of `fingerprint_coverage`, `build_review_flags`, review cosine 0.97), and any track that flags is left out.
- The protocol change is a dated amendment in `12-6-metrical-level-convention.md` section 6 in the existing format, with an unchecked operator-signoff line the operator checks at review.
- Plain vocabulary per the CLAUDE.md naming rules in all new text, identifiers and messages.

**Never:** Change the frozen candidate list, rebuild it, or edit `eval-corpus/12-7-operator-decisions.json`. Abandon sub-100 batch 0 (it stays staged so the band can resume later). Run `scripts/ingest-dawproject-labels.py` (it writes training labels). Commit anything under `_bmad-output/ml-training/eval-corpus/`. Touch `Sources/` or `Tests/`. Start Stories 12.8 or 12.9.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Export batch tempos | Bitwig project, 100-120 batch 0 worklist | ingest CSV with all 40 `e1-` row IDs, verified BPM to 2 decimals, flag columns 0 | refuse if any worklist row is missing from the project or has no tempo |
| Ingest e1 batch | that CSV | 0 members in 100-120, 40 `out-of-band` rejects with BPM kept, one entry added to the annotation log | existing ingest validation unchanged |
| Manifest, declared short | four bands at 43, 100-120 and sub-100 declared short | corpus file with 172 entries and a per-band block naming both short bands and their reasons | none |
| Manifest, undeclared short | a band under 43 not in the declaration | refuses as today, naming the band | exit nonzero |
| Declaration names a full band | declaration lists a band at 43 | refuses: a full band cannot be declared short | exit nonzero |
| Supplement, clean track | an `x1-` or `e1-` track verified in 100-120 or under 100 | entry in the supplement file with band, BPM, source tag; `x1-` entries also tagged `detector-visible` | none |
| Supplement, training match | a track whose fingerprint flags against training audio | left out, listed by row ID in the command output | none |
| Signoff after this story | any state | refuses as today | unchanged |

</frozen-after-approval>

## Code Map

- `scripts/build-eval-corpus.py` -- the harness. `emit-manifest` handler at 5661 (band check 5665, audit check 5672, manifest body 5728-5745); `ingest` via `parse_annotations_csv` 4724 with `EXPECTED_ANNOTATION_COLUMNS` 436; out-of-band rejection in `keep_or_reject` 995-997 and `compute_membership` 1001; `n_band` read from the commitment at 2353 (one value for all bands; changing it means rebuilding the frozen candidate list, which refuses); fingerprint pieces `_default_fingerprint` 1197, `cohort_stats` 1228, `_fingerprint_one` 3271, `fingerprint_coverage` 3286 (needs `load_inputs()`), `build_review_flags` 3434, `FINGERPRINT_REVIEW_COSINE` 295; `signoff` 6306, `validate_attestation` 6151, `repass_status_for_signoff` 6091-6140, `repass-sample` band check 5865 -- leave all signoff and re-pass code unchanged. `audit` is not read-only (rewrites the list of training songs to remove at 5354); run it only through the commands that already call it.
- `scripts/dawproject-bpm.py` -- tempo extraction from a .dawproject; use `--json`, never `--match`.
- `scripts/tests/test_build_eval_corpus.py` -- 220 tests; `ws` fixture near 1136, helpers `_mint`, `_annotate`, `_complete_band`, `_write_decisions`, `N_BAND_TEST = 2` at 1063; drive commands with `bec.main([...])`.
- `_bmad-output/ml-training/train.py` -- `check_substrate_preconditions` 558-604; unchanged.
- `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- section 6 signoff 442, amendments at 530 (signed 623) and 653 (signed 702): the format to follow.
- `_bmad-output/implementation-artifacts/12-7-eval-corpus.md` -- progress table and header text are stale (say no batch annotated); `REVIEWER_SIGNOFF: pending` at 637 stays.
- `_bmad-output/ml-training/eval-corpus/generations/ge94c3fc04f636363/` -- private state: `batches/100-120/batch-000.json` (40 `e1-` row IDs), `staging/100-120/batch-000/` (audio), `membership.json`, `annotation-ledger.jsonl`. Gitignored; never commit.
- `/Users/rterhaar/Music/2026-08-29-to-annotate/` -- the 132 `x1-*.flac` files; `eval-corpus/x1-dsp-prepass.json` gives each file's `local_path`.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/build-eval-corpus.py` -- add an `export-dawproject` command: for BAND and BATCH, read the worklist row IDs, take each track's verified tempo from the .dawproject by track name via `dawproject-bpm.py --json`, write a CSV in the ingest column order -- turns existing Bitwig work into ingest input without hand copying
- [x] `scripts/build-eval-corpus.py` -- `emit-manifest` reads a declaration of short bands (committed JSON: date, operator, per band a reason) and, when every under-target band is declared and no declared band is full, writes the corpus file with a top-level per-band block; otherwise refuses as today -- lets the verified 172 tracks be used without touching signoff
- [x] `scripts/build-eval-corpus.py` -- add a read-only `slow-supplement` command: take a list of extra audio files with verified tempos (the 13 `x1-` slow tracks, tagged `detector-visible`, plus `e1-` rejects verified under 120), fingerprint each against training audio with the existing functions, write `generations/<gen>/slow-tempo-supplement.jams.json` with band, BPM and source tag per kept track, print excluded row IDs -- gives the slow tempos a labelled place without changing membership
- [x] `scripts/tests/test_build_eval_corpus.py` -- tests for every row of the I/O matrix using the `ws` fixture
- [x] `_bmad-output/implementation-artifacts/12-7-short-bands.json` -- the declaration: 100-120 (pool tags read two-thirds of the true tempo; batch 0 of 40 yielded no in-band track) and sub-100 (batch 0 staged, not annotated), dated 2026-10-23
- [x] `_bmad-output/implementation-artifacts/12-6-metrical-level-convention.md` -- dated amendment 2026-10-23 in section 6: corpus closes at the four full bands plus the declared short bands; slow supplement admitted outside membership; re-listen and training-overlap sign-off deferred; train gate stays closed; unchecked operator-signoff line
- [x] Run, on the operator's machine state: export and ingest 100-120 batch 0, emit the manifest, build the supplement; record the counts in Implementation Notes
- [x] `_bmad-output/implementation-artifacts/12-7-eval-corpus.md` -- replace the stale progress text with the real per-band counts, the declared short bands and the supplement count
- [x] `_bmad-output/implementation-artifacts/deferred-work.md` -- entries for: filling 100-120 and sub-100 to 43 (sub-100 batch 0 is staged; the operator's remaining 93 `x1-` files are a source once admitted), the blind re-listen, the training-overlap sign-off, and restating Story 12.9's 12-net-track threshold and "258-track corpus" wording for 172 tracks plus short bands
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- `12-7-band-balanced-258-track-corpus` stays `in-progress` until review; this workflow sets the final value

**Acceptance Criteria:**
- Given today's state, when the run task finishes, then `membership.json` shows 43 in each of the four fast bands, 0 in 100-120 with 40 out-of-band rejects carrying their tempos, and the annotation log has one new entry for 100-120 batch 0.
- Given the corpus file, when read, then it holds 172 entries, the top-level per-band block names 100-120 and sub-100 as short with their reasons, and each entry keeps the existing fields and annotation-version tag.
- Given `make eval-corpus-signoff` and `train.py`'s precondition check after the story, when run, then both refuse exactly as before.
- Given the branch diff, then nothing under `Sources/`, `Tests/` or `_bmad-output/ml-training/eval-corpus/` is tracked, and `make scripts-tests`, `make py-lint` pass.

## Implementation Notes

Run on the operator's machine state, 2026-10-23:

- `make eval-corpus-export-dawproject BAND=100-120 BATCH=0 DAWPROJECT=/Users/rterhaar/Desktop/batch-000/hand-annotated-training.dawproject` wrote `eval-corpus/ingest-100-120-batch-000.csv`: 40 rows, every worklist row found, one tempo each (85.00 once, 140.00 to 175.00 for the other 39), flags 0.
- `make eval-corpus-ingest BAND=100-120 BATCH=0 ...`: record version 1, members 0/43, 40 out-of-band rejects with tempos kept. The annotation log went from 9 to 10 events; the tracked `12-7-annotation-ledger-head.json` moved with it.
- `make eval-corpus-status`: sub-100 0/43 (0 annotated), 100-120 0/43 (40 annotated, rate 0.00), 120-140, 140-160, 160-175 and 175-plus 43/43.
- `make eval-corpus-manifest`: corpus file written with 172 entries, sentinel per band {160-175: 1, others 0}, per-band block naming 100-120 and sub-100 short with their reasons. The first run crashed with a KeyError in `_resolve_audio` (a `dict.get` default evaluated `entry['identity']` on the identity-less OA300 lookup entries the sentinel index builds); fixed, with a regression test. 59 of 82 OA300 files do not resolve locally, so the sentinel join used its filename fallback for those (deferred-work).
- `make eval-corpus-slow-supplement DAWPROJECT=... AUDIO_DIR=/Users/rterhaar/Music/2026-08-29-to-annotate`: 5,193 training rows fingerprinted, all resolved. Supplement written with 11 tracks (10 in 100-120, 1 under 100), all `x1-` and tagged `detector-visible`. Left out: `e1-c9d77b5a97a3` (the 85 BPM reject; the same file is a training-list row), `x1-0fb9a45aed91` and `x1-51e8f1c983e2` (two clips reading different tempos).
- `make eval-corpus-signoff`: refused, "bands below 43 verified members: ['sub-100', '100-120']". `train.check_substrate_preconditions()`: raises `SubstratePreconditionError` at the 12.7 gate (marker `pending`).

Divergences from the spec's expectations, for the reviewer:

- **13 slow `x1-` tracks became 11.** The count of 13 read the first clip of each DAW track. Two tracks hold a second clip: a sliver left by a split, carrying the warp from before the operator corrected the tempo. `dawproject-bpm.py --json` reports every clip; the harness groups readings by track name and refuses to pick one when they differ by more than 0.5 BPM (the signed fine-disagreement tolerance), rather than guessing. The clip that plays reads 127.98 and 123.93, so both are probably not slow tracks at all.
- **The supplement holds no gate-eligible track.** The `e1-` track verified at 85 BPM, the one track operator decision 1 expected to carry no `detector-visible` tag, was left out because its file is a row of a training list. Under the 2026-08-11 order the eval pool is drawn from the training lists and only members are put on the list of training songs to remove, so a non-member reject stays in training. A direct file-hash check was added alongside the fingerprint check, since a byte-identical file is training overlap whatever the fingerprint says.
- **Training audio coverage is enforced for the supplement** with the same rule as the mint (`assert_training_coverage`, accepting only rows a dated operator amendment names), so an unreadable training row blocks the supplement instead of being skipped.
- The supplement takes rejects from 100-120 only (`SUPPLEMENT_REJECT_BANDS`). 160-175 holds three blinded rejects at 85 to 87 BPM; admitting them is filed in deferred-work.
- New Makefile targets `eval-corpus-export-dawproject` and `eval-corpus-slow-supplement` follow the existing `eval-corpus-*` pattern; the `eval-corpus-manifest` help text now describes the short-band declaration.

## Spec Change Log

## Review Triage Log

- 2026-10-23 review, four layers: blind hunter (14), edge-case hunter (15), verification-gap (3 plus 1 other), Codex gpt-6-astra diff review thread 01a16bba-0343-7eb0-8ac3-c3acfe709975 (8). Grouped by root cause; verdicts verified against the working tree.
  - Overlap check in `slow-supplement` is narrower than its docstring and the amendment claim ("the same checks the pre-commitment review runs"): no comparison against the 172 members or within one band; GiantSteps title check cannot fire for untitled `x1-` tracks; Tony train/val files checked by fingerprint only, not by hash; the cross-band pass standardizes over at most 11 vectors; standardization cohort differs from the review run (Codex 1, 2; edge 1-4; blind 5, 6). low as built: the cohort is 5,193 training fingerprints plus 13 extras, so training dominates the statistics (Codex's 2-D example uses 3 training vectors); every kept track is `detector-visible` and excluded from gates. Route: patch the docstring, supplement note and amendment to state exactly what is checked; defer strengthening the checks until the supplement feeds any gate.
  - Test gaps: declaration validation rules beyond the band name (verification-gap 1, blind 12); both tracks of a cross-band match left out (verification-gap 2); non-numeric or missing clip BPM, and unreadable unapproved training audio (Codex 7); signoff test matches only a generic substring (verification-gap other). low, real. Route: patch (tests only).
  - `project_tracks` reduces clip files to basenames before the one-file check, so two different files with the same name pass (Codex 3). low, real. Route: patch.
  - Export overwrite guard checks then opens with "w" (Codex 5). low, real. Route: patch (exclusive create).
  - `supplement_from_project` drops a problem track with no readings without listing it, and compares the rounded mean against the 120 ceiling (edge 5, 6). low, real. Route: patch.
  - Supplement records no provenance for the DAW project it read (blind 4). low, real. Route: patch (file name, size, SHA-256 in the supplement).
  - `slow-supplement` docstring says it writes only its file; `load_state` can finish an interrupted earlier write and the fingerprint cache is flushed (Codex 6). low. Route: patch (docstring).
  - Pool-reject source cannot yield a track until the training lists are rebuilt, since every pool row is a training row (blind 8). low, real (measured: the one candidate was left out for that reason). Route: patch (state it in code comment and amendment).
  - New prose uses "attestation check", "Mint", "closure check/record" (Codex 8). low, real. Route: patch.
  - Corpus id string still `12-7-band-balanced-258` (blind 2, edge 10). low, real. Route: patch.
  - `epic-12-context.md` regeneration dropped the FR-62a struck note, softened the train-gate wording, dropped the 12.7/12.9 split guidance, and still describes a 258-track corpus (blind 11, edge 11-15). medium, real. Route: patch (documentation).
  - Supplement entries carry no octave-sentinel tag (blind 7, edge 7); `ambiguous` flag carried into the supplement untested (verification-gap 3, pre-dispositioned defer). low. Route: defer.
  - Manifest does not mark the amendment unsigned (blind 1, edge 9). false as a lasting state: the operator signs the amendment at this workflow's close, before anything lands.
  - Declaration claimed "committed" but not checked against git (blind 3). low; the file is committed by this workflow. Rejected.
  - `dawproject-bpm.py --json` skips clips with fewer than two warps, so a track with one such clip exports its readable clip (Codex 4). low, unlikely; fix changes another script's output contract. Rejected.
  - Privacy gate refuses a short reason containing a slash (edge 8). low, unlikely, refusal message is explicit. Rejected.
  - Batch 0 blinding assumed (blind 9). false: the detector pre-pass covered only the 132 `x1-` files (`x1-dsp-prepass.json`, 132 tracks); no `e1-` estimate existed.
  - Sub-100 pool not analysed for half-tempo tags; two-thirds ratio stated without figures (blind 10). Rejected as out of intent: filling the slow bands is deferred; the 37-of-40 at 160 or above figure is recorded in the declaration.
  - Spec absent from the diff (blind 14). false: the spec is the claims file and is committed with this change.

## Design Notes

Why a declaration file instead of changing `n_band`: the target is one number in the frozen candidate list, and rebuilding that list refuses while annotations exist, so a per-band allowance must be a separate input. Making only `emit-manifest` read it keeps the failure mode safe: the corpus file becomes usable for evaluation, while signoff and training stay locked until the later story finishes the bands, the re-listen and the training-overlap sign-off.

Why the slow tracks go in a separate file: the harness only admits members from its committed pool, and `ingest` rejects foreign row IDs and never moves a tempo across bands. A supplement keeps that rule intact and keeps the 172-track figure honest, while still giving Story 12.9 and later evaluation the slow tempos where the model fails.

## Verification

**Commands:**
- `make scripts-tests` -- expected: green, 465 plus the new tests
- `make py-lint` -- expected: clean
- `make eval-corpus-status` -- expected: four bands at 43, 100-120 at 0 with 40 out-of-band rejects, sub-100 at 0
- `make eval-corpus-manifest` -- expected: writes the corpus file with 172 entries and the per-band block
- `make eval-corpus-signoff` -- expected: refuses, unchanged
- `git status --short` -- expected: no path under `_bmad-output/ml-training/eval-corpus/`
