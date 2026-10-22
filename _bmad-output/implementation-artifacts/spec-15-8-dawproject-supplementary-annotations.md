---
title: 'Story 15.8: supplementary downbeat and verified-span annotations from the hand-annotated .dawproject'
type: 'feature'
created: '2026-10-21'
status: 'done'
baseline_revision: '57165b67619dc6f62d6452c583e3e87dafb066e0'
review_loop_iteration: 0
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/implementation-artifacts/15-8-dawproject-supplementary-annotations.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-15-context.md'
warnings: [oversized]
deferred:
  - summary: >-
      CLAUDE.md Test Patterns names make oracle and make oracle-generate but not
      oracle-generate-annotations or daw-oracle-annotations.json.
    evidence: |-
      Blind-hunter finding; the next agent reading the project instructions will
      not know the annotations file exists. Fix edits an agent-context file, so it
      is deferred to the operator.
    location: >-
      CLAUDE.md (Test Patterns paragraph)
    severity: low
  - summary: >-
      The annotation convention has never been exercised through a Bitwig export,
      so the extractor has produced zero records on real data.
    evidence: |-
      Whether a beat marker snapped in Bitwig's clip audio editor is saved as a
      Warp whose time is within 0.02 beats of a bar line, and whether the track
      Comment field round-trips, is asserted from the schema and from the
      survival of up to 48 warps per clip in other-bpms.dawproject, not from a
      round-trip of a snapped marker. Settled by annotating one clip per the SOP
      in 15-8-notes.md, saving, running make oracle-generate-annotations, and
      confirming one entry with the expected fields. If false, the output stays
      empty for every track.
    location: >-
      scripts/dawproject-annotations.py (is_anchor) and 15-8-notes.md (SOP)
    severity: high (unverified)
  - summary: >-
      Nested Lanes[@track] under a group track would visit each child clip twice
      and attach the group's comment first.
    evidence: |-
      The traversal (Arrangement//Lanes[@track] then every Warps below) is the one
      dawproject-bpm.py uses. Bitwig 6.0.11 writes flat lanes: the corpus has 0
      Warps under its 5 group lanes. Settled by a Bitwig export with an audio
      track inside a group.
    location: >-
      scripts/dawproject-annotations.py (collect_clips)
    severity: medium (unverified)
  - summary: >-
      If Audio@duration ever exceeds the last warp's contentTime by more than
      1e-6 s, a bar-aligned end-of-file warp becomes A2 and the span extends to
      the file end unverified.
    evidence: |-
      Today the last contentTime equals Audio@duration exactly in 32 of 32 clips.
      Settled by the same Bitwig export check as the round-trip item.
    location: >-
      scripts/dawproject-annotations.py (is_anchor, END_OF_FILE_MARGIN_SEC)
    severity: medium (unverified)
---

<intent-contract>

## Intent

**Problem:** The DAW oracle (`daw-oracle.json`) carries tempo only. Story 15.9 needs, per track, a reference downbeat time in original-audio seconds, a verified stable span, the BPM over that span, and a declared metrical level, or it cannot score absolute phase, downbeat phase or long-span drift against an independent reference. The corpus `.dawproject` holds nothing that declares a downbeat today: the operator has only warped each clip to tempo. The operator wants no external sidecar file; every annotation must live inside the `.dawproject`.

**Approach:** Record the investigation of what Bitwig writes into `project.xml` (done, see Code Map), define an in-Bitwig annotation convention based on bar-line warp points plus an optional track comment, and add a develop-only extractor `scripts/dawproject-annotations.py` that reads that convention and writes a JAMS-shaped `daw-oracle-annotations.json` next to the oracle. Tracks without the convention are omitted with a logged reason, so the current corpus yields zero records until the operator adds the markers.

## Boundaries & Constraints

**Always:**
- Stdlib-only Python, `uv run` script header like `scripts/dawproject-bpm.py`; reuse that script's ground-truth matching by loading it with `importlib.util.spec_from_file_location` (precedent `scripts/tests/conftest.py`); its CLI and output stay byte-identical.
- Warp list hygiene, per clip, before any rule: parse `time` and `contentTime` as floats; every value must be finite; sort by `time`; `time` and `contentTime` must both be strictly increasing after the sort, otherwise skip the clip with reason `warps-not-monotonic`. `Audio@duration` must be finite and positive.
- Warp eligibility rule (clip-local `Warps` timeline, `timeUnit="beats"`, `contentTimeUnit="seconds"`): a warp is a declared downbeat anchor iff `warp.time >= 4`, `|warp.time/4 - round(warp.time/4)| * 4 <= 0.02` beats, `0 < contentTime < Audio@duration - 1e-6`. The origin warp, the end-of-file warp and sub-beat transient nudges never qualify. Each anchor's bar index is `b = round(warp.time / 4)` (0-based) and its `bar_position = b + 1`. By operator convention a bar-line warp at bar 2 or later IS the downbeat declaration; the file carries no separate flag, and the notes state that limitation.
- A record needs an anchor pair: `A1` = the first eligible anchor, `A2` = the last eligible anchor, with `b2 - b1 >= 8` (rounded bar indices, so 16.01 and 48.00 beats qualify). Every warp strictly between `A1` and `A2` in the sorted list must itself be eligible; one that is not skips the clip with reason `unverified-warp-inside-span`. Then `reference_downbeat_time_sec = A1.contentTime`, `bar_position = b1 + 1`, `verified_span_start_sec = A1.contentTime`, `verified_span_end_sec = A2.contentTime`, `verified_bpm = (A2.time - A1.time) / (A2.contentTime - A1.contentTime) * 60` (positive by the monotonic rule). Every eligible anchor strictly between `A1` and `A2` is an interior check: `distant_alignment_checks` lists `{time_sec, bar_position, residual_ms}` with `residual_ms = (A.contentTime - (A1.contentTime + (A.time - A1.time) * 60 / verified_bpm)) * 1000`, reported, not gated. Nothing lies outside `[A1, A2]`.
- `playStart`, `playStop`, `loopStart`, `loopEnd` and the inner clip `time` offset select or shift what the arrangement plays; they do not change the warp map from clip beats to audio-file seconds, so the extractor ignores them. `contentTime` is original-audio seconds.
- Duplicate ground-truth matches: clips are visited in document order and the first clip matched to a ground-truth `filename` reserves it (even if that clip is then skipped for another reason); a later clip matching the same filename is skipped with reason `duplicate-ground-truth-match` (the corpus has one stem present as `.mp3` and `.wav`).
- Track `comment` attribute tokens, split on `;`, `key=value` trimmed, case-insensitive keys: `level` in `{quarter, half, double}` sets `declared_metrical_level`; `unc` in `{low, medium, high}` sets `uncertainty.level`; any remaining text is `uncertainty.note`. Defaults when absent: `declared_metrical_level = "unspecified"`, `uncertainty = {"level": "medium", "note": "derived from bar-line warp pair; no operator comment"}`. An unrecognized `level` or `unc` value skips the record.
- Project must be 4/4 (`Transport/TimeSignature` numerator 4, denominator 4) with no `TimeSignatureAutomation`; otherwise every clip is skipped with reason `time-signature-not-4-4`.
- Skip reasons go to stderr as one line `skip <audio basename>: <reason>`; reasons are `no-declared-downbeat-anchor`, `verified-span-shorter-than-8-bars`, `unverified-warp-inside-span`, `warps-not-monotonic`, `unmatched-ground-truth`, `duplicate-ground-truth-match`, `invalid-comment-token`, `time-signature-not-4-4`. Exit code 0 on partial coverage and on zero records. Exit 2 with one stderr line for: a missing or non-zip `--dawproject`, a zip without `project.xml`, an XML parse error, a missing required attribute, an unreadable or invalid `--match` file, or an unwritable `--out`. Output is written to a temp file in the target directory and moved into place with `os.replace`, so a failed run leaves any existing output untouched.
- Output file: `{"entries": [...]}` sorted by matched ground-truth `filename`; each entry carries `file_metadata` with `jams_version: "0.4.0"`, `duration = Audio@duration`, and `identifiers` `{basename, local_path, track_id}` built exactly as `_daw_oracle_to_jams` builds them (so 15.9 joins on `basename` without stem heuristics); one `tempo` annotation whose single observation has `time = verified_span_start_sec`, `duration = span length`, `value = verified_bpm`, `confidence = 1.0`; one `beat_position` annotation with one observation per eligible anchor from `A1` to `A2` inclusive (`time` = audio seconds, `value = {"position": 1, "measure": bar_position, "num_beats": 4, "beat_units": 4}`); and `sandbox` holding the eight named fields plus `annotation_version: "15.8.v1"`, `source: "bitwig-warp-bar-line-pair"`, `dawproject_application` (name and version from `Application`). Every observation time lies inside `[verified_span_start_sec, verified_span_end_sec]`; no field describes beats outside it.
- Deterministic bytes: floats rounded to 6 decimals, `json.dumps(sort_keys=True, indent=2)` plus trailing newline. `--check` regenerates in memory, never writes, exits 0 when the existing `--out` is byte-identical, and exits 1 with a one-line summary (missing file, or the first differing entry basename) otherwise.
- The script sets `sys.dont_write_bytecode = True` before loading `dawproject-bpm.py`, so no `scripts/__pycache__` entry is created by a run.
- `daw-oracle-annotations.json` stays operator-local at `${OA300_CORPUS_PATH}` like `daw-oracle.json`; nothing under the corpus path is committed.
- No em dashes, no emojis, no invented vocabulary in code, tests, docs or commits.

**Never:**
- No sidecar file, no edit of `daw-oracle.json` or `daw-oracle-beats.json`, no write to `scripts/ingest-dawproject-labels.py`, `_bmad-output/ml-training/tony-corpus/tony-truth-labels.json`, `_bmad-output/ml-training/eval-corpus/`, `pools_doc`, `draws_doc`, or `candidate_universe_sha256`.
- No change to `scripts/dawproject-bpm.py` behaviour, CLI, or output; no change to `make oracle-generate`.
- No addition to `SHIPS_TO_MAIN` or `EXCLUDED_FROM_MAIN`; no edit to the sibling `rekordboxReader` repository.
- No extrapolation of beats beyond the anchor pair; no `beat` namespace grid; no inference of a downbeat from the origin warp, the inner clip offset, or the end-of-file warp.
- No `sprint-status.yaml` edit: Epic 15 is charter-only and has no sprint entries.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Annotated clip | warps `(0,0)`, `(16, 7.5)`, `(80, 37.5)`, `(end, dur)`; comment `level=half; unc=low; checked at bar 21` | one entry: bar_position 5, downbeat 7.5 s, span 7.5 to 37.5 s, bpm 128.0, level half, unc low with note, two `beat_position` observations | none |
| Interior check | warps `(0,0)`, `(16, 7.5)`, `(80, 37.49)`, `(144, 67.5)`, `(end, dur)` | span 7.5 to 67.5 s, bpm 128.0, `distant_alignment_checks` one entry bar_position 21 residual -10 ms, three `beat_position` observations | none |
| Rounded bar gap | anchors at 16.01 and 48.00 beats | accepted: bars 4 and 12 | none |
| Only origin and end warps (current corpus shape) | `(0,0)`, `(928.00006, 327.53)` | omitted; stderr `no-declared-downbeat-anchor`; exit 0 | none |
| Three-point legacy warp | middle point at 0.986 beats | omitted, same reason (fails `time >= 4`) | none |
| Single anchor | `(0,0)`, `(16, 7.5)`, `(end, dur)` | omitted; `no-declared-downbeat-anchor` (no pair) | none |
| Pair too close | anchors at 16 and 40 beats | omitted; `verified-span-shorter-than-8-bars` | none |
| Nudge inside span | `(16, 7.5)`, `(33.3, 15.6)`, `(80, 37.5)` | omitted; `unverified-warp-inside-span` | none |
| Unsorted or non-monotonic warps | `(80, 37.5)` listed before `(16, 7.5)`; or two warps with equal `contentTime` | sorted case accepted; equal-time case omitted with `warps-not-monotonic` | none |
| Non-finite value | `contentTime="nan"` | omitted; `warps-not-monotonic` | none |
| Bad comment token | `level=triplet` | omitted; `invalid-comment-token` | none |
| Not 4/4 | TimeSignature 3/4 | every clip skipped; `time-signature-not-4-4`; exit 0 | none |
| Clip not in ground truth | basename absent from `--match` file | omitted; `unmatched-ground-truth` | none |
| Duplicate match | `x.mp3` and `x.wav` both match ground-truth `x.mp3` | first in document order recorded; second `duplicate-ground-truth-match` | none |
| Zero records | corpus file as it is today | output `{"entries": []}` written; exit 0 | none |
| Re-run | identical inputs twice | byte-identical output; `--check` exits 0 | none |
| Check mismatch | `--check` against a changed or missing output | exit 1 with one summary line; output not written | expected failure path |
| Unreadable input | missing path, non-zip, zip without project.xml, XML parse error, invalid `--match` JSON | exit 2 with a one-line message; existing output untouched | error |
| Unwritable output | `--out` in a read-only directory | exit 2; no partial file left behind | error |

</intent-contract>

## Code Map

- `scripts/dawproject-bpm.py` -- read-only reuse: `_load_oa300_rows` (JAMS oa300 corpus to flat rows), `find_ground_truth_match`, `strip_audio_prefix`, `_curator`; `extract_clip_bpms` at line 139 reads only the first and last `Warp` (kept as is). Has a `__main__` guard, so loading it by path is safe.
- `scripts/ingest-dawproject-labels.py:41` -- consumer of the old script's `--json` output; untouched, proves why the old CLI must stay byte-identical.
- `scripts/tests/conftest.py` -- precedent for `importlib.util.spec_from_file_location` on a hyphenated script and for tmp-path-only workspaces.
- `scripts/tests/test_promote_to_main.py:85-105` -- parametrized develop-only path list; add `scripts/dawproject-annotations.py`.
- `scripts/promote-to-main.py:45` -- `SHIPS_TO_MAIN` excludes `scripts/`; nothing to change, only to pin.
- `Makefile:420-425` -- `oracle-generate` target to mirror; `py-lint` ty file list (search `rekordbox-beats.py`) gains the new script; `scripts-tests` already runs `scripts/tests/`.
- `/private/tmp/claude-501/-Users-rterhaar-Dropbox-research-swift-BoomBoomBoomKit/f418ec47-ce95-43b0-863e-caad7a715ce0/scratchpad/dawproject-research/` -- investigation evidence for the notes: `corpus-clips.csv` (32 clips), `other-clips.csv` (195 clips of the training-label project), `scripts/analyze.py`, `spec/Project.xsd` and `spec/README.md` fetched from github.com/bitwig/dawproject.
- Investigation findings to carry into `15-8-notes.md`: Bitwig Studio 6.0.11 wrote the corpus file; no `Marker` elements, all 38 `Track@comment` empty, 4/4 with no `TimeSignatureAutomation`; 24 clips have two warps (origin and end of file; last `contentTime` equals `Audio@duration` in 32 of 32), 8 have a third point that is collinear (same BPM within 0.007) and sits under 1 beat (five at 0.986 to 0.999, three sub-beat transient nudges), so none is a downbeat anchor; 5 inner clips carry a `time` phase nudge of -7 to +80 ms that aligns a beat but names no downbeat; `other-bpms.dawproject` (Bitwig 6.0.8, 195 clips, up to 48 warps per clip) proves the exporter keeps every warp point; the schema allows `Arrangement/Markers` but a marker has no track reference and all 38 clips start at arrangement beat 0, so cue markers cannot carry a per-track anchor; whether Bitwig exports cue markers was not verified. The guidance claim that the SOP "anchors a DAW grid at a stable downbeat" (`../rekordboxReader/docs/rekordbox-analysis/FINDINGS.md`, item 5) is wrong for the current files; the notes say so and the sibling repository is left to the operator.
- Operator SOP to write into the notes (per clip, in the clip audio editor): keep the tempo warp as now; add a beat marker on a verified downbeat and snap it to a bar line at bar 2 or later; add a second beat marker on a verified downbeat at least 8 bars further on, snapped to its bar line; optionally more bar-line markers between them as interior checks; never leave an unsnapped marker between the first and last bar-line marker; optionally type `level=half; unc=low; note text` in the track Comment field of the Inspector. The notes also state the limitation that the file carries no separate "downbeat" flag, so a bar-line warp at bar 2 or later is the declaration by convention.

## Tasks & Acceptance

**Execution:**
- `_bmad-output/implementation-artifacts/15-8-notes.md` -- write the investigation note: per-element inventory of `project.xml` (Warp, Warps, Clip outer and inner, Audio, File, Track, Transport, Markers absent, TimeSignatureAutomation absent) with, for each, whether it can recover the reference downbeat and verified span or not and why; the counts above; the three-point warp reading; the convention and parse rule; the correction to the guidance claim -- AC1 deliverable and the operator's instructions.
- `scripts/dawproject-annotations.py` -- new uv-run stdlib script: `--dawproject`, `--match`, `--out`, `--check`; parse per the Always rules; emit the JAMS-shaped file; stderr skip lines; exit codes -- the extractor.
- `scripts/tests/test_dawproject_annotations.py` -- pytest building synthetic `.dawproject` zips in `tmp_path` (project.xml only, no audio) and a synthetic oa300 ground-truth JAMS file; load the extractor in-process with the conftest loader pattern for the logic rows and cover every I/O Matrix row; assert on the parsed output that identifiers, both annotations, finite numbers and every observation time inside the span are present; idempotence by comparing bytes across two runs; a repository-walk assertion that snapshots `{path: (st_size, st_mtime_ns)}` (review pass: content hashes measured 4.2 GB per pass and were replaced by stat data) for every file under `_bmad-output/ml-training/eval-corpus/` (this covers `candidate-pools.json`, `draw-sequences.json` and the `candidate_universe_sha256` fields inside them), `_bmad-output/ml-training/tony-corpus/tony-truth-labels.json`, and `scripts/` (including any `__pycache__`), runs the extractor as a subprocess with `PYTHONDONTWRITEBYTECODE=1` against tmp paths, snapshots again, and asserts the two dicts are equal (so creations, deletions and content changes all fail) -- AC2 to AC6.
- `scripts/tests/test_promote_to_main.py` -- add `scripts/dawproject-annotations.py` to the develop-only parametrized list -- AC7.
- `Makefile` -- add `oracle-generate-annotations` after `oracle-generate` with a `##` help line, invoking the script with the corpus `.dawproject`, the oa300 fixture and `$(OA300_CORPUS_PATH)/daw-oracle-annotations.json`; add the script to the `py-lint` ty list -- operator entry point and lint coverage.
- `_bmad-output/implementation-artifacts/15-8-dawproject-supplementary-annotations.md` -- set `Status: done`, resolve the open questions (no sidecar; convention; file stays operator-local; `distant_alignment_checks` structured and interior to the span; `bar_position` is the clip-local bar number of the anchor), rewrite AC6's "sibling file if one is checked in" clause to "`--check` against the operator-local file exits 0", and add a short "Shipped" section with the zero-record result on the current corpus -- story record.

**Acceptance Criteria:**
- Given the corpus `.dawproject` as it is today, when `make oracle-generate-annotations` runs with `OA300_CORPUS_PATH` set, then the file is written with an empty `entries` list, one stderr skip line per clip, and exit code 0.
- Given a synthetic project with the convention applied, when the extractor runs, then the entry carries the eight named fields in `sandbox`, the oracle-style `identifiers`, a `tempo` observation spanning only the verified span, and `beat_position` observations only at eligible anchors inside the span, and the test asserts those fields and bounds on the parsed JSON.
- Given the new script, when `make lint` and `make scripts-tests` run, then ruff, ty and pytest pass with the new test file included and `test_promote_to_main.py` still passes.
- Given the branch diff against `develop`, when reviewed, then `scripts/dawproject-bpm.py`, `scripts/ingest-dawproject-labels.py`, `scripts/promote-to-main.py`, `_bmad-output/ml-training/eval-corpus/` and `tony-truth-labels.json` are unchanged.

## Spec Change Log

- 2026-10-21, pre-implementation Codex plan review (gpt-6-sol, thread 01a160ca): `A2` changed from "next anchor at least 32 beats on" to the last eligible anchor with a rounded 8-bar gap, so interior checks stay inside the span and nothing is emitted beyond it; added warp sorting, monotonic and finite checks, the duplicate-match policy, the `playStart`/loop statement, exit-2 input failures with an atomic write, `--check` failure rows, oracle-style identifiers, `sys.dont_write_bytecode`, and a hash-based repository walk that names the three protected corpus artifacts. Declined: moving the Make target out of the shipped `Makefile` (develop-only targets there are the documented precedent), a repository path test for `daw-oracle-annotations.json` (the file never enters the repository), and 15.9 guidance on `unspecified` levels. KEEP: the clip-local `warp.time` test and the no-sidecar decision.

## Review Triage Log

### 2026-10-21 — Review pass
- verdicts: 52 findings — high 0, medium 12, low 30, false 5, maybe-false 5
- findings:
  - `[medium]` `[patch]` Blind: the repository walk sha256-hashes `eval-corpus/` twice per run — measured 407 files, 4,160 MB, 1.37 s per pass warm; replaced the content hash with `(st_size, st_mtime_ns)` from `os.stat`, which still fails on creation, deletion and any write; spec Task text amended to match
  - `[medium]` `[patch]` Blind: the inventory evidence behind the notes lives only in a session scratch directory — copied `analyze.py`, `corpus-clips.csv` and `other-clips.csv` to `_bmad-output/implementation-artifacts/15-8-evidence/`; notes Evidence section and spec Code Map now point there
  - `[low]` `[reject]` Blind: spec Code Map states the phase-nudge sign reversed — the fix is an edit to this build's spec; the notes, which are the deliverable, carry the measured values (-79.8 to +7.2 ms)
  - `[low]` `[patch]` Blind: `epic-15-context.md` says the file's version control is undecided and lists 15.8 as remaining — both sentences corrected
  - `[medium]` `[patch]` Blind: story file KDD 6 still says `{time_sec, note}` and "32 consecutive beats", names an unreachable skip condition, and Affected files lists four untouched paths — reconciled to what shipped
  - `[low]` `[defer]` Blind: CLAUDE.md Test Patterns does not mention `oracle-generate-annotations` — fix edits an agent-context file
  - `[low]` `[reject]` Blind: no Make target for `--check` — adds a target for a documented one-line command
  - `[low]` `[patch]` Blind: non-beat `Warps` units have no test (grouped with the verification-gap and edge-case rows) — test added; a dedicated skip reason rejected because Bitwig never writes those units and the spec's reason set is closed
  - `[low]` `[reject]` Blind: `warps-not-monotonic` also covers unparsable numbers and a bad duration — splitting adds reasons and branches for inputs Bitwig does not produce
  - `[medium]` `[patch]` Blind: the `time >= 4` floor is asymmetric with the 0.02-beat snap tolerance — the corpus writes bar counts like 553.9999952 just below the integer, so a bar-2 marker at 3.99999 would be dropped; floor changed to `bar_index(warp) >= 1` after the bar-line test, with boundary tests
  - `[low]` `[reject]` Blind: curator from `git config` makes bytes machine-dependent (grouped with the edge-case and Codex rows) — by spec it mirrors `daw-oracle.json`; one operator machine runs `--check`
  - `[maybe-false]` `[defer]` Blind: the positive path has only run on synthetic XML; whether a Bitwig-snapped marker lands within 0.02 beats of a bar line is unverified — if true the output stays empty (high); settled by annotating one clip in Bitwig, exporting, and running the extractor
  - `[maybe-false]` `[defer]` Blind: nested `Lanes[@track]` would double-visit clips — Bitwig 6.0.11 writes flat lanes (0 `Warps` under the 5 group lanes); if true, medium; settled by a Bitwig export with a grouped audio track
  - `[low]` `[reject]` Blind: no DAW-side provenance field in `sandbox` — adds schema surface; the join key is the ground-truth basename by design
  - `[low]` `[patch]` Blind: duplicate comment keys and key-only comments are tested but undocumented — one sentence added to the notes SOP
  - `[low]` `[patch]` Blind: `check_summary` branches untested (grouped with the verification-gap row) — tests added for the count-mismatch and non-document branches
  - `[low]` `[patch]` Blind: no `deferred-work.md` entry for the verify-later items — W102 added
  - `[medium]` `[patch]` Edge: bar-2 marker at 3.99999 rejected — grouped with the floor row above
  - `[low]` `[reject]` Edge: two eligible warps rounding to one bar duplicate a measure — needs two snapped markers within 0.02 beats; output is benign; fix adds a branch
  - `[maybe-false]` `[defer]` Edge: if `Audio@duration` ever exceeds the last `contentTime` by more than 1e-6 the end-of-file warp can become `A2` — today 32 of 32 clips are exactly equal; if true, medium (span silently extends to the file end); settled by the same Bitwig export check
  - `[low]` `[patch]` Edge: units mismatch reported as `no-declared-downbeat-anchor` — grouped with the units test row; reason unchanged
  - `[low]` `[reject]` Edge: `--check` against `{"entries": 123}` raises `TypeError` (grouped with Codex) — only a hand-edited output file reaches it, exit code is still 1; fix adds a guard
  - `[low]` `[reject]` Edge: sibling `dawproject-bpm.py` absent gives a traceback — the file is tracked in the same directory; never met
  - `[low]` `[reject]` Edge: `--check` under a different git identity reports a diff — grouped with the curator row
  - `[low]` `[reject]` Edge: a fuzzy stem match can reserve a row before a later exact match — same precedence as the old oracle's `seen_filenames`; the corpus has 23 matched clips and 0 duplicates; fix adds a pre-pass
  - `[low]` `[reject]` Edge: `--out` as a symlink is replaced by a file — unlikely; fix adds a resolve step
  - `[low]` `[reject]` Edge: encrypted or unsupported zip compression gives a traceback — Bitwig never writes such archives
  - `[low]` `[patch]` Edge: `PYTHONPYCACHEPREFIX` in the test environment makes the no-bytecode assertion vacuous — key added to the env filter
  - `[false]` `[reject]` Edge: AC3 not confirmable because of 1Password in the sandbox — in this session `make scripts-tests` passed 159 with the signer reachable
  - `[medium]` `[patch]` Verification gap: `--check` entry-count mismatch untested — test seeds `{"entries": []}` against a one-entry regeneration and asserts exit 1 and the basename summary
  - `[medium]` `[patch]` Verification gap: `beat_timeline` guard untested — `project_xml` gains a units parameter and a `timeUnit="seconds"` row asserts no record
  - `[medium]` `[patch]` Verification gap: bar-2 lower bound untested — record test at 4.0 and 36.0 asserting `bar_position == 2`, boundary rows at 3.99994 (accepted after the floor fix) and 3.9 (rejected)
  - `[low]` `[patch]` Verification gap: `--match` basename guard untested — payload with a tempo annotation and no `identifiers.basename` added, asserting exit 2
  - `[medium]` `[patch]` Verification gap (other): floor asymmetry — grouped with the floor row
  - `[low]` `[patch]` Verification gap (other): `epic-15-context.md` contradicts the story — grouped with the context row
  - `[low]` `[reject]` Verification gap (other): `scripts-tests` is not a CI gate — pre-existing position shared with the W87 suite
  - `[false]` `[reject]` Verification gap (other): two `test_from_ref_*` failures — environmental signer failure; both pass here
  - `[maybe-false]` `[defer]` Intent: the convention has never been exercised through a Bitwig export, so the extractor yields zero records on real data — grouped with the Blind round-trip row
  - `[medium]` `[patch]` Intent: story AC2/AC3 say 32 beats while the code uses an 8-bar rounded gap — grouped with the story reconciliation row
  - `[medium]` `[patch]` Intent: KDD 6 shape differs from the shipped `distant_alignment_checks` — grouped with the story reconciliation row
  - `[medium]` `[patch]` Intent: Affected files lists untouched paths — grouped with the story reconciliation row
  - `[false]` `[reject]` Intent: AC6 was rewritten by the diff that satisfies it — the rewrite follows the operator's no-sidecar and operator-local decisions and the spec Task; the story records both
  - `[low]` `[reject]` Intent: AC4 is tested on file content rather than a consumer query — no consumer exists before Story 15.9
  - `[low]` `[reject]` Intent: the clip traversal duplicates `dawproject-bpm.py` with no same-clip-set test — the old script is untouched by design and both traversals are the same five lines
  - `[false]` `[reject]` Intent: no commits, PR, or recorded final Codex review — commits happen at finalize, the PR after the run per the intent, and this pass is the Codex diff review
  - `[low]` `[reject]` Codex: finite warp times near 1e308 can overflow BPM to `Infinity` — unreachable from a DAW export; fix adds a guard
  - `[low]` `[reject]` Codex: the reused loader opens the match file with the locale encoding — macOS coerces to UTF-8; mirrors the untouched old script
  - `[low]` `[reject]` Codex: curator makes bytes machine-dependent — grouped with the curator row
  - `[low]` `[reject]` Codex: `--check` on `{"entries": 123}` raises — grouped with the edge-case row
  - `[maybe-false]` `[reject]` Codex: automation check precedes required-attribute validation — both outcomes are error reports on a file Bitwig cannot write; if true, low
  - `[low]` `[reject]` Codex: an anchor at exactly 48.02 beats is rejected by float noise — the formula is the spec's; snapped markers sit at exact bar positions
  - `[false]` `[reject]` Codex: chmod-based test fails on Windows — macOS-only repository (Xcode toolchain) and the test already skips as root

## Design Notes

The warp timeline is the clip's own content grid, which is the ruler the operator sees in the clip audio editor when snapping a beat marker. Testing `warp.time` directly (not the arrangement position that adds the inner clip offset) keeps the rule independent of the beat-phase nudges five clips already carry. `bar_position` is therefore the clip-local bar number, 1-based, of the anchor. The 0.02-beat tolerance is about 7 ms at 170 BPM, well under the 15 to 20 ms where a snapped marker would read as unsnapped, and far from the 0.986-beat legacy points.

## Verification

**Commands:**
- `make scripts-tests` -- expected: new suite green alongside the existing three files.
- `make lint` -- expected: ruff and ty clean including the new script, SwiftLint 0 violations.
- `OA300_CORPUS_PATH=/Users/rterhaar/Dropbox/OA300_OnsetAudio300 make oracle-generate-annotations` -- expected: 32 skip lines, `{"entries": []}` written, exit 0.
- `uv run scripts/dawproject-annotations.py --dawproject <corpus> --match Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json --out <corpus>/daw-oracle-annotations.json --check` -- expected: exit 0 after the generate step.
- `uv run scripts/dawproject-bpm.py "$OA300_CORPUS_PATH/corpus/corpus.dawproject" --json | shasum` before and after -- expected: identical digest.
- `make test` -- expected: 1094 tests, the same 4 known issues as develop `57165b6`.

## Auto Run Result

Status: done

**Summary.** Story 15.8 ships a develop-only extractor, `scripts/dawproject-annotations.py`, that reads a two-bar-line-warp convention from the hand-annotated `.dawproject` (no sidecar file) and writes `daw-oracle-annotations.json` next to the oracle, plus the investigation note that defines the convention. On the corpus file as it is today the extractor writes zero records (23 clips without a declared anchor, 9 not in the ground truth), because only BPM was ever annotated; records appear once the operator adds bar-line beat markers per the SOP in `15-8-notes.md`.

**Files changed.**
- `scripts/dawproject-annotations.py` -- new stdlib extractor (`--dawproject`, `--match`, `--out`, `--check`), reuses the matching helpers of the untouched `dawproject-bpm.py`.
- `scripts/tests/test_dawproject_annotations.py` -- 50 tests: every I/O matrix row, idempotence, `--check` paths, exit-2 inputs, a subprocess repository walk over the protected paths, and a no-bytecode check.
- `scripts/tests/test_promote_to_main.py` -- pins the new script as develop-only.
- `Makefile` -- `oracle-generate-annotations` target; the script joins the `py-lint` ty list.
- `_bmad-output/implementation-artifacts/15-8-notes.md` -- `project.xml` inventory, three-point-warp reading, the operator SOP, the parse rule, the correction to the guidance claim.
- `_bmad-output/implementation-artifacts/15-8-evidence/` -- `analyze.py` and the two CSV inventories the notes' counts come from.
- `_bmad-output/implementation-artifacts/15-8-dawproject-supplementary-annotations.md` -- status done, open questions resolved, KDD 6, AC2, AC3, AC6 and Affected files reconciled, Shipped section.
- `_bmad-output/implementation-artifacts/deferred-work.md` -- W102 (Bitwig export round-trip unverified; nested-lanes shape).
- `_bmad-output/implementation-artifacts/epic-15-context.md` -- compiled epic context (new), corrected for the operator-local decision and the 15.8 status.
- This spec.

**Review findings.** 52 findings from five layers (blind hunter 17, edge case 12, verification gap 8, intent alignment 8, Codex diff review 7): high 0, medium 12, low 30, false 5, maybe-false 5.
- Patches applied (12 entries; by entry verdict medium 7, low 5): anchor floor changed from `warp.time >= 4` to `bar_index >= 1` after the bar-line test, so a bar-2 marker written as 3.99999 is accepted; repository walk switched from sha256 to `(size, mtime_ns)` (4.2 GB per pass measured); inventory evidence committed under `15-8-evidence/`; story KDD 6, AC2, AC3 and Affected files reconciled; `epic-15-context.md` corrected; tests added for the bar-2 bound and boundary, non-beat warp units, `--check` count mismatch and non-document output, the `--match` basename guard; `PYTHONPYCACHEPREFIX` filtered in the no-bytecode test; comment-parsing behaviour documented in the SOP; W102 filed.
- Deferred (4, in frontmatter): CLAUDE.md Test Patterns mention (agent-context file); the convention has never been exercised through a Bitwig export (high, unverified); nested `Lanes[@track]` double-visit (medium, unverified); end-of-file warp when `Audio@duration` differs from the last `contentTime` (medium, unverified).
- Rejected, with reasons: spec Code Map sign typo (fix is a spec edit; the notes are right); Make target for `--check` (adds a target for a one-line command); dedicated units skip reason and split monotonic reasons (branches for inputs Bitwig never writes); curator in output and `--check` under another git identity, three rows (mirrors `daw-oracle.json` by spec; one operator machine); DAW-side provenance field (schema surface); two anchors in one bar (needs two snapped markers within 0.02 beats, benign output); `--check` on `{"entries": 123}`, two rows (hand-edited file only, exit still 1); sibling script absent, encrypted zip, symlink `--out` (never met from a DAW export); fuzzy match reserving a row (same precedence as the old oracle, no such pair in the corpus); `scripts-tests` not a CI gate (pre-existing W87 position); AC4 tested on file content (no consumer before 15.9); traversal equivalence test (old script untouched, same five lines); Infinity BPM at 1e308 beats, locale decode, automation precedence, 48.02 boundary (unreachable or by-spec formula); Windows chmod (macOS-only repository); AC6 rewrite, missing PR, 1Password failures, two rows (false: directed by the operator decisions, commits at finalize, signer environmental).

**Follow-up review recommendation: true.** Seven medium entries were patched on a first pass. The specific unverified risk: the anchor floor and the snapshot now deviate from the literal spec text (`warp.time >= 4` and `sha256`), and the new boundary tests encode the tolerance-based floor without a Bitwig-exported file showing which side of the integer a snapped bar-2 marker lands on. Settled by the same one-clip Bitwig export that closes W102.

**Verification.** `make lint`: ruff, ruff format, ty clean; SwiftLint 0 violations in 202 files. `make test`: 1094 tests, 169 suites, 4 known issues (unchanged from develop `57165b6`). `scripts/tests/test_dawproject_annotations.py`: 50 passed. `make scripts-tests`: 164 passed, 2 failed in the pre-existing `test_from_ref_*` cases because the 1Password signer returned `failed to fill whole buffer` on their temp-repo commit; the same two passed earlier in the session (159 passed before the patches) with the signer reachable. `scripts/dawproject-bpm.py --json` digest `8328fd55...` identical before and after. `make oracle-generate-annotations`: exit 0, 32 skip lines, `{"entries": []}`; `--check` exit 0; no `scripts/__pycache__` entry for the new script.

**Residual risks.** The convention is untested on a real Bitwig export (W102). Output bytes carry the git curator, so `--check` on another machine reports a diff. `other-clips.csv` lists track names from the private training-label project; it stays on develop like `tony-truth-labels.json`. The sibling `rekordboxReader` FINDINGS.md item 5 still states the SOP anchors a downbeat; the correction lives in `15-8-notes.md` for the operator to carry over.
