# Story 15.8: Preserve hand-annotation reference downbeat and verified stable span

Status: backlog

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 8 of the handoff in `docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Investigate what the saved .dawproject actually retains beyond tempo, then emit a develop-only supplementary annotations file next to daw-oracle.json that carries reference-downbeat time, verified BPM, declared metrical level, bar position, verified stable span, and uncertainty, without extrapolating across the track.

## Key Design Decisions

1. **Investigate project.xml before changing the extractor.** The existing extractor at scripts/dawproject-bpm.py:139 derives BPM from only the first and last Warp markers of each clip. Before changing that path, inventory what project.xml actually retains (per-warp time/contentTime pairs, Clip time/offset/duration, Track/Lanes hierarchy, Marker elements if any) and record which can recover a reference downbeat time in the original audio frame and a verified stable span. The inventory is the gate for the extractor shape; coding before it risks reading warp coordinates that do not survive a Bitwig round-trip.
2. **New extractor alongside dawproject-bpm.py, no behavior change for existing consumers.** Add scripts/dawproject-annotations.py as a separate uv-run script. scripts/dawproject-bpm.py keeps its current contract (table / --json / --match emit a JAMS tempo corpus) because scripts/ingest-dawproject-labels.py:41 and the Makefile oracle-generate target consume it. The new extractor may factor out the project.xml-reading core as a shared helper, but the existing script's CLI and output stay byte-identical.
3. **Separate output file at the corpus path, not an edit of daw-oracle.json.** Write a new JAMS-shaped file at ${OA300_CORPUS_PATH}/daw-oracle-annotations.json. Do not alter daw-oracle.json (Story 8.8 contract) or daw-oracle-beats.json (Story 8.7 contract). A separate file keeps those contracts intact, stays develop-only (same corpus path, not on scripts/promote-to-main.py's allowlist), and lets a consumer load only what it needs.
4. **Record only inside the verified span; no full-track extrapolation.** Each entry carries verified_span_start_sec and verified_span_end_sec in original-audio seconds, plus reference_downbeat_time_sec that must fall inside the span. Beat positions outside the span are not written and are not implied. Full-track playable grids remain a Phase 7 problem (Story 15.7 joint tempo+phase fit, validated against separated stable regions), not this story's.
5. **Supplementary annotations are evaluation reference, not training labels.** The new file lands at the corpus path next to the existing OA300 oracle. It is not read by scripts/ingest-dawproject-labels.py and does not touch _bmad-output/ml-training/tony-corpus/tony-truth-labels.json. The ingest path for training keeps its single writer, preserving the training vs evaluation recording separation stated in FINDINGS.md:70.
6. **First-class uncertainty and metrical-level fields.** Per-track fields: reference_downbeat_time_sec (float, original audio), verified_bpm (float), declared_metrical_level (enum: quarter, half, double, unspecified), bar_position (integer), verified_span_start_sec, verified_span_end_sec, optional distant_alignment_checks (list of {time_sec, note}), uncertainty (enum low/medium/high plus a free-text note). All fields are validated at write time; a missing anchor, a span shorter than 32 beats, or an anchor outside its own span skips the record and logs the reason.
7. **Do not touch Story 12-7 harness as a side effect.** No write under _bmad-output/ml-training/eval-corpus/, no edit to pools_doc, draws_doc, or candidate_universe_sha256, and no change to the signed corpus protocol. All writes from this story land under ${OA300_CORPUS_PATH} or scripts/, and a test that invokes the extractor against a tmp OA300 path asserts no file outside that path is modified.
8. **Idempotent, deterministic output.** Running the extractor twice on the same inputs produces a byte-identical file (sorted entries by basename, stable float formatting), mirroring the ingest-dawproject-labels.py contract. This lets `make oracle-generate-annotations` behave like a check-in-the-tree regenerate and makes a code review diff mean something.

## Story

As a library author validating BoomBoomBoomKit against hand-annotated references,
I want a develop-only supplementary annotations file that preserves the reference downbeat, verified BPM, declared metrical level, bar position, verified stable span, and uncertainty from each hand-annotated .dawproject,
so that Phase 9's matched evaluation can score absolute phase and downbeat phase on the span that was actually verified, instead of discarding every timing fact the annotator recorded.

## Acceptance Criteria

1. **Given** a saved hand-annotated .dawproject matching one of the current corpus tracks
   **When** the Phase 8 investigation step runs and writes its findings to _bmad-output/implementation-artifacts/15-8-notes.md
   **Then** the notes list every project.xml element retained beyond tempo (Warp time/contentTime pairs, Clip time/offset/duration, Track/Lanes hierarchy, Marker elements if present) and state, for each, whether it is sufficient to recover reference_downbeat_time_sec and the verified stable span, or whether an operator-supplied sidecar is required

2. **Given** a .dawproject with a declared downbeat anchor and at least 32 consecutive verified beats, plus the OA300 ground-truth JAMS file
   **When** `uv run scripts/dawproject-annotations.py --dawproject <file> --match <oa300-ground-truth.json> --out ${OA300_CORPUS_PATH}/daw-oracle-annotations.json` runs
   **Then** the output file is JAMS-shaped and each matched entry carries reference_downbeat_time_sec, verified_bpm, declared_metrical_level, bar_position, verified_span_start_sec, verified_span_end_sec, optional distant_alignment_checks, and uncertainty

3. **Given** a .dawproject whose clip lacks a declared downbeat anchor or whose verified span is shorter than 32 beats
   **When** the extractor runs
   **Then** that entry is omitted entirely (not partially written), a stderr line names the track and the reason, and the process exit code remains zero so partial-coverage runs do not break the Makefile target

4. **Given** the generated daw-oracle-annotations.json
   **When** a consumer asks for beat labels at a time outside [verified_span_start_sec, verified_span_end_sec]
   **Then** no label is returned and the file carries no extrapolated beats; the schema has no field that implies a full-track grid

5. **Given** the extractor is invoked against a tmp OA300 path
   **When** the run finishes
   **Then** a repository-walk assertion in the test confirms no file under _bmad-output/ml-training/eval-corpus/, scripts/ other than the new extractor itself, pools_doc, draws_doc, candidate_universe_sha256, or tony-truth-labels.json has been created or modified

6. **Given** the extractor runs twice back-to-back on the same inputs
   **When** the second invocation completes
   **Then** the output file is byte-identical to the first, and `make oracle-generate-annotations` reports no diff against the sibling file if one is checked in

7. **Given** scripts/promote-to-main.py is run after this story lands
   **When** the staging script computes the allowlist diff
   **Then** neither scripts/dawproject-annotations.py nor any daw-oracle-annotations.json path is staged for main; scripts/tests/test_promote_to_main.py has a case pinning this exclusion

## Affected files

- `scripts/dawproject-annotations.py`
- `scripts/dawproject-bpm.py:139`
- `scripts/ingest-dawproject-labels.py:41`
- `Makefile:404`
- `scripts/tests/test_promote_to_main.py`
- `_bmad-output/implementation-artifacts/15-8-notes.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `docs/rekordbox-analysis/AGENT_GUIDANCE.md:67`

## Overlap with Epic 12

Epic 12 Story 12-7 (eval-corpus-harness WIP on rterhaar/12-7-eval-corpus-harness) owns the signed corpus protocol, pools_doc, draws_doc, and candidate_universe_sha256. This story coordinates by staying strictly additive: it writes a separate supplementary annotations file at ${OA300_CORPUS_PATH}/daw-oracle-annotations.json and never touches Story 12-7 membership, _bmad-output/ml-training/eval-corpus/, or the signed-corpus harness. The two can proceed in parallel; the Story 12-7 branch does not need to rebase for Phase 8.

## Open questions for the PRD

- Does the current hand-annotation SOP record declared_metrical_level as an operator-visible value in the .dawproject (track name convention, clip name, marker), or must it be captured in a sidecar? The investigation step must answer this before the schema is frozen.
- Does Bitwig's save path preserve the full Warp list and per-clip offset at round-trip, or does it collapse to first/last pairs for some operations? scripts/dawproject-bpm.py:176 only reads the first and last warp points, so this has never been exercised.
- Should distant_alignment_checks be a free list of {time_sec, note} or a structured pair of {time_sec, expected_beat_index}? Operator preference should decide; keep the schema change surface small.
- Does the DAW SOP want the anchor at bar 1 of the verified span, or at the first downbeat the annotator can confirm (which may be bar N of the track)? bar_position needs an unambiguous meaning before the schema ships.
- Should the new file land under version control, or stay operator-local like the oracle it sits next to? daw-oracle.json is at ${OA300_CORPUS_PATH} and not committed; preserving that convention is the default assumption.

## Explicit scope exclusions

- Do not extrapolate beat labels across a full track from one 32-beat verified span.
- Do not touch Story 12-7's signed corpus protocol, pools_doc, draws_doc, candidate_universe_sha256, or _bmad-output/ml-training/eval-corpus/ as a side effect.
- Do not expose blinded labels; the training vs evaluation recording separation stated in FINDINGS.md:70 stays.
- Do not write to _bmad-output/ml-training/tony-corpus/tony-truth-labels.json from the new extractor; scripts/ingest-dawproject-labels.py remains the single writer there.
- Do not alter the daw-oracle.json (Story 8.8) or daw-oracle-beats.json (Story 8.7) contracts.
- Do not add scripts/dawproject-annotations.py or any daw-oracle-annotations.json path to scripts/promote-to-main.py's allowlist; this stays develop-only.
- Do not treat the mistakenly created BPM-sheet.csv as a data source; the hand-annotation workflow writes a .dawproject.
- Do not change scripts/dawproject-bpm.py's CLI or output shape; its downstream consumers are out of scope.

