# Story 15.8: Preserve hand-annotation reference downbeat and verified stable span

Status: done

Epic: 15 (Rekordbox-informed accuracy improvements)
Phase: 8 of the handoff in `../rekordboxReader/docs/rekordbox-analysis/AGENT_GUIDANCE.md`.

Summary: Investigate what the saved .dawproject actually retains beyond tempo, then emit a develop-only supplementary annotations file next to daw-oracle.json that carries reference-downbeat time, verified BPM, declared metrical level, bar position, verified stable span, and uncertainty, without extrapolating across the track.

## Key Design Decisions

1. **Investigate project.xml before changing the extractor.** The existing extractor at scripts/dawproject-bpm.py:139 derives BPM from only the first and last Warp markers of each clip. Before changing that path, inventory what project.xml actually retains (per-warp time/contentTime pairs, Clip time/offset/duration, Track/Lanes hierarchy, Marker elements if any) and record which can recover a reference downbeat time in the original audio frame and a verified stable span. The inventory is the gate for the extractor shape; coding before it risks reading warp coordinates that do not survive a Bitwig round-trip.
2. **New extractor alongside dawproject-bpm.py, no behavior change for existing consumers.** Add scripts/dawproject-annotations.py as a separate uv-run script. scripts/dawproject-bpm.py keeps its current contract (table / --json / --match emit a JAMS tempo corpus) because scripts/ingest-dawproject-labels.py:41 and the Makefile oracle-generate target consume it. The new extractor may factor out the project.xml-reading core as a shared helper, but the existing script's CLI and output stay byte-identical.
3. **Separate output file at the corpus path, not an edit of daw-oracle.json.** Write a new JAMS-shaped file at ${OA300_CORPUS_PATH}/daw-oracle-annotations.json. Do not alter daw-oracle.json (Story 8.8 contract) or daw-oracle-beats.json (Story 8.7 contract). A separate file keeps those contracts intact, stays develop-only (same corpus path, not on scripts/promote-to-main.py's allowlist), and lets a consumer load only what it needs.
4. **Record only inside the verified span; no full-track extrapolation.** Each entry carries verified_span_start_sec and verified_span_end_sec in original-audio seconds, plus reference_downbeat_time_sec that must fall inside the span. Beat positions outside the span are not written and are not implied. Full-track playable grids remain a Phase 7 problem (Story 15.7 joint tempo+phase fit, validated against separated stable regions), not this story's.
5. **Supplementary annotations are evaluation reference, not training labels.** The new file lands at the corpus path next to the existing OA300 oracle. It is not read by scripts/ingest-dawproject-labels.py and does not touch _bmad-output/ml-training/tony-corpus/tony-truth-labels.json. The ingest path for training keeps its single writer, preserving the training vs evaluation recording separation stated in FINDINGS.md:70.
6. **First-class uncertainty and metrical-level fields.** Per-track fields: reference_downbeat_time_sec (float, original audio), verified_bpm (float), declared_metrical_level (enum: quarter, half, double, unspecified), bar_position (integer), verified_span_start_sec, verified_span_end_sec, distant_alignment_checks (list of {time_sec, bar_position, residual_ms}, one per warp strictly inside the span that sits on an arrangement bar line, possibly empty), uncertainty ({level: low/medium/high, note: free text}). All fields are validated at write time; a clip with no `bar=` token, a declared bar outside the audio, or a span of fewer than 8 bars between the start and end bar skips the record and logs the reason (15.8.v2, 2026-10-22; the original rule counted bar-line warps at bar 2 or later).
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

2. **Given** a .dawproject with a declared downbeat bar and at least 8 bars between the start and end bar of the span named by the bar comment, plus the OA300 ground-truth JAMS file
   **When** `uv run scripts/dawproject-annotations.py --dawproject <file> --match <oa300-ground-truth.json> --out ${OA300_CORPUS_PATH}/daw-oracle-annotations.json` runs
   **Then** the output file is JAMS-shaped and each matched entry carries reference_downbeat_time_sec, verified_bpm, declared_metrical_level, bar_position, verified_span_start_sec, verified_span_end_sec, optional distant_alignment_checks, and uncertainty

3. **Given** a .dawproject whose clip lacks a declared downbeat bar or that has fewer than 8 bars between the start and end bar of the span named by the bar comment
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
   **Then** the output file is byte-identical to the first, and `--check` against the operator-local file exits 0

7. **Given** scripts/promote-to-main.py is run after this story lands
   **When** the staging script computes the allowlist diff
   **Then** neither scripts/dawproject-annotations.py nor any daw-oracle-annotations.json path is staged for main; scripts/tests/test_promote_to_main.py has a case pinning this exclusion

## Affected files

- `scripts/dawproject-annotations.py`
- `scripts/tests/test_dawproject_annotations.py`
- `scripts/tests/test_promote_to_main.py`
- `Makefile`
- `_bmad-output/implementation-artifacts/15-8-notes.md`
- `_bmad-output/implementation-artifacts/15-8-evidence/`
- `_bmad-output/implementation-artifacts/15-8-dawproject-supplementary-annotations.md`

## Overlap with Epic 12

Epic 12 Story 12-7 (eval-corpus-harness WIP on rterhaar/12-7-eval-corpus-harness) owns the signed corpus protocol, pools_doc, draws_doc, and candidate_universe_sha256. This story coordinates by staying strictly additive: it writes a separate supplementary annotations file at ${OA300_CORPUS_PATH}/daw-oracle-annotations.json and never touches Story 12-7 membership, _bmad-output/ml-training/eval-corpus/, or the signed-corpus harness. The two can proceed in parallel; the Story 12-7 branch does not need to rebase for Phase 8.

## Open questions (resolved 2026-10-21)

- **Where does the metrical level live?** In the `.dawproject`, not a sidecar. The track Comment field (Inspector) takes `level=<quarter|half|double>; unc=<low|medium|high>; free text`. Since 15.8.v2 the same field also carries the required `bar=<N>` or `bar=<N>-<M>` token; a comment without it produces no record. Absent `level` and `unc`, the level is `unspecified` and the uncertainty is `medium` with a note saying no free text was given. An unrecognized `level` or `unc` value, or a malformed `bar` value, skips the record with `invalid-comment-token`.
- **Does Bitwig keep the full warp list?** Yes. `other-bpms.dawproject` (Bitwig 6.0.8) keeps up to 48 warps per clip, so every beat marker survives the save. The corpus file declares no downbeat today: 24 clips have only origin and end-of-file warps and 8 have a collinear third point under 1 beat. Details in `15-8-notes.md`.
- **Convention.** Replaced on 2026-10-22 by "15.8.v2" after a real Bitwig 6.1.4 export (W102). The operator slides the clip so a verified downbeat sits on an arrangement bar line and types `bar=<N>` (optionally `bar=<N>-<M>`, at least 8 bars) in the track comment. Bitwig saves the slide as clip offsets; the extractor maps arrangement bar N to content beat `4 * (N - 1) - offset_beats`, with `offset_beats = outer.time + inner.time - outer.playStart - inner.playStart`, and reads its seconds off the warp map. The `bar=` token is the only declaration, and the notes state that limitation.
- **Shape of `distant_alignment_checks`.** Structured: `{time_sec, bar_position, residual_ms}`, one entry per warp strictly inside the span that sits on an arrangement bar line, with `bar_position` that arrangement bar. A warp inside the span that is off every bar line skips the clip. Reported, not gated. Nothing is recorded outside the span.
- **Meaning of `bar_position`.** N from the `bar=` token: the 1-based arrangement bar as typed, read off the Bitwig ruler. The clip offsets, the inner clip phase nudge included, map it to the clip's content beat.
- **Version control.** The file stays operator-local at `${OA300_CORPUS_PATH}/daw-oracle-annotations.json`, like `daw-oracle.json`. Nothing under the corpus path is committed.

## Explicit scope exclusions

- Do not extrapolate beat labels across a full track from one 32-beat verified span.
- Do not touch Story 12-7's signed corpus protocol, pools_doc, draws_doc, candidate_universe_sha256, or _bmad-output/ml-training/eval-corpus/ as a side effect.
- Do not expose blinded labels; the training vs evaluation recording separation stated in FINDINGS.md:70 stays.
- Do not write to _bmad-output/ml-training/tony-corpus/tony-truth-labels.json from the new extractor; scripts/ingest-dawproject-labels.py remains the single writer there.
- Do not alter the daw-oracle.json (Story 8.8) or daw-oracle-beats.json (Story 8.7) contracts.
- Do not add scripts/dawproject-annotations.py or any daw-oracle-annotations.json path to scripts/promote-to-main.py's allowlist; this stays develop-only.
- Do not treat the mistakenly created BPM-sheet.csv as a data source; the hand-annotation workflow writes a .dawproject.
- Do not change scripts/dawproject-bpm.py's CLI or output shape; its downstream consumers are out of scope.

## Shipped

- `scripts/dawproject-annotations.py`: stdlib extractor (`--dawproject`, optional `--match`, `--out`, `--check`), annotation version "15.8.v2" (clip offset and `bar=` track comment) since 2026-10-22. Without `--match` the identifiers are the audio basename. Reuses the ground-truth matching in `scripts/dawproject-bpm.py` by loading it by path; that script is unchanged (its `--json` and `--match` outputs hash the same before and after).
- `scripts/tests/test_dawproject_annotations.py`: synthetic `.dawproject` zips in `tmp_path` covering every row of the spec's I/O matrix and a replay of the real Bitwig 6.1.4 export values, plus a subprocess run that records size and modification time of every file under `_bmad-output/ml-training/eval-corpus/`, `tony-truth-labels.json` and `scripts/` before and after and asserts no change.
- `scripts/tests/test_promote_to_main.py` pins `scripts/dawproject-annotations.py` as develop-only.
- `Makefile`: `oracle-generate-annotations`; the script joins the `py-lint` ty list.
- `15-8-notes.md`: the `project.xml` inventory, the convention, the real export check, the parse rule and the correction to `FINDINGS.md` item 5.
- `15-8-evidence/`: the stdlib inventory script `analyze.py` and its two CSV outputs that the notes' counts come from.
- Result on the corpus file as it is today: `{"entries": []}`, 32 skip lines (23 `no-declared-downbeat-bar`, 9 `unmatched-ground-truth`), exit 0. Records appear once the operator slides a clip onto a bar line and types its `bar=` token per the SOP in the notes.
- Not touched, by design: `sprint-status.yaml` (Epic 15 has no sprint entries), `scripts/ingest-dawproject-labels.py`, `daw-oracle.json`, `daw-oracle-beats.json`, and the sibling `rekordboxReader` repository (`AGENT_GUIDANCE.md` and `FINDINGS.md` are left to the operator).
