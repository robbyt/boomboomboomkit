# Story 8.8b: Migrate OA300 ground-truth + DAW oracle to JAMS (in place)

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **library maintainer consolidating on JAMS as the canonical ground-truth format**,
I want the two plain per-track corpora `oa300-ground-truth.json` and `daw-oracle.json` migrated **in place** to JAMS `tempo`-namespace corpora via a reproducible script, with every Swift and Python consumer updated to read the new shape through the shared 8.8a decoder,
so that the OA300/GiantSteps BPM benchmarks and the develop-only ML-training corpus tooling read one annotation format with `mir_eval` interop and curator provenance.

**Depends on:** Story 8.8a (shared public JAMS model + `OA300Track`/`DAWOracleTrack` `loadCorpus` adapters + sandbox union). **Owns** the migration-script scaffold that 8.8c extends.

## Context

See 8.8a §Context for the shared operator rulings (nothing shipping / no BC; DD-1 decoder relocation; DD-2 in-place overwrite). This slice migrates the two **simple per-track** artifacts; the structurally-different DnB regression config is 8.8c.

## Acceptance Criteria

1. **Migration script + Makefile target.** `_bmad-output/ml-training/migrate-to-jams.py` (develop-only, stdlib-only, `uv run`) is created with a shared `_jams_entry(...)` helper and converters for oa300 + daw. The helper **always emits `file_metadata.duration` (`0` when unknown) and `jams_version: "0.4.0"`** so each `entries[i]` is standalone `jams.load`-valid (Codex P2). `make oracle-migrate-to-jams` (develop-only, fails loudly on a main-only checkout — mirrors `oracle-generate-beats`, no emojis) runs it. [[feedback_no_emojis]] [[feedback_uv_run]]

2. **`oa300-ground-truth.json` → JAMS corpus, in place.** Each row `{filename, bpm, subdir?, title, genre}` → one `entries[i]` JAMSFile: `tempo` observation `{time:0, duration:0, value:<bpm>, confidence:1.0}`; `file_metadata.title = title`; `identifiers.basename = filename`, `.local_path = subdir ? "<subdir>/<filename>" : filename`, `.track_id = title`; `sandbox.genre = genre`, `sandbox.subdir = subdir`. Row count + every genre preserved.

3. **`daw-oracle.json` → JAMS corpus, in place** at `${OA300_CORPUS_PATH}/daw-oracle.json` (uncommitted/corpus-local). `tempo` value = `daw_bpm` (manually-verified DAW truth, `confidence:1.0`); `sandbox` carries `rekordboxBpm`, `rekordboxDisagrees`, `disagreementType`; `identifiers` as in AC 2. `scripts/dawproject-bpm.py` (the `make oracle-generate` writer) is updated to emit this JAMS shape directly so a regenerate is a no-op against a migrated file.

4. **Idempotent + validating.** Re-running against an already-JAMS file does not rewrite it but still validates the artifact-specific minimum shape (non-empty `entries`; each entry has a `tempo` annotation with a non-nil numeric `value`; oa300 entries carry `sandbox.genre`) and exits non-zero + reports loudly on failure — never a blind skip (Codex P3).

5. **Curator/provenance.** Every entry's `annotation_metadata.curator.name = "Robert Terhaar"`, `.curator.email = robbyt@gmail.com` (from git config), `.data_source = "OA300 hand-labeled ground truth"` (oa300) / `"DAW manual placement"` (daw).

6. **All Swift consumers read JAMS via the shared adapter.** Every root-array decode site changes from `JSONDecoder().decode([OA300Track].self, …)` to `OA300Track.loadCorpus(from:)` (Codex P1): `OA300BenchmarkTests:62`, `AblationFullMatrixTests:100`, `PerformanceBenchmarkTests:245`, `MLPolicySweepTests:53`, `SharedDecodeImpactTests:63`, `SuperFluxImpactTests:52`, `BNNSImpactTests:257`, `DAWOracleBenchmarkTests:62` (oa300) + `DAWOracleBenchmarkTests:72` (daw via `DAWOracleTrack.loadCorpus`). `Bundle.module` lookups and `filename`/`subdir` URL-building are otherwise unchanged. `CorpusTracksDecodingTests` inline-JSON fixtures are rewritten to JAMS shape, keeping the genre loud-fail + corpus-count/genre-membership assertions.

7. **All oa300 Python consumers read JAMS.** `dataset.py`, `corpus_common.py:320`, `build_fr18_input.py:49` iterate `doc["entries"]` (root is now a dict) and read basename/local_path from `identifiers`, bpm from the tempo observation, genre/subdir from sandbox. The oa300 writer `convert-rekordbox-export.py:235` emits JAMS (and now preserves `genre`, which the flat writer dropped). `make ml-splits` succeeds; `make py-lint` clean (add `migrate-to-jams.py` to the `ty check` list).

8. **Migration report + gauntlet.** The script writes the oa300 + daw rows of `8-8-migration-report.md` (input shape, namespace `tempo`, entry count, curator populated, sandbox-routed fields). `make build`/`make test`/`make benchmark`/`make oracle`/`make benchmark-giantsteps` (env-gated) report **unchanged** Acc1/Acc2 (BPM truth is byte-preserved; only the container changed — any drift is a migration bug). Manual `jams.load` spot-check of one extracted oa300 entry recorded in the report.

## Tasks / Subtasks

- [ ] **Task 1 — Script scaffold + Makefile (AC: 1, 4, 5).** Author `migrate-to-jams.py` with `_jams_entry` (duration + jams_version), oa300 + daw converters, idempotent-validating loader, git-config curator; add `make oracle-migrate-to-jams`; add to `py-lint`.
- [ ] **Task 2 — Migrate fixtures (AC: 2, 3).** Run the script; commit the rewritten `oa300-ground-truth.json`; update `scripts/dawproject-bpm.py` to emit JAMS; regenerate `daw-oracle.json` (uncommitted) and prove idempotency (no diff on re-run).
- [ ] **Task 3 — Swift consumers (AC: 6).** Flip the 8 oa300 + 1 daw root-decode sites to `loadCorpus`; rewrite `CorpusTracksDecodingTests` inline fixtures to JAMS.
- [ ] **Task 4 — Python consumers (AC: 7).** Update the 3 oa300 readers + the convert writer to the JAMS shape.
- [ ] **Task 5 — Report + gauntlet (AC: 8).** Emit the oa300/daw report rows; run the full + env-gated gauntlet; confirm accuracy unchanged; `jams.load` spot-check.

## Dev Notes

- **JAMS mapping (per-track):** `bpm`/`daw_bpm` → `tempo` observation value; `title` → `file_metadata.title` + `identifiers.track_id`; `filename` → `identifiers.basename`; `subdir`+`filename` → `identifiers.local_path`; `subdir`/`genre`/disagreement → `sandbox.*`. (Mapping + validators land in 8.8a.)
- **Accuracy is mechanically unchanged** — only the container shape changes; benchmarks are a regression net, not a re-measurement.
- **Consumer inventory (file:line, verified):** oa300 Swift readers (9): `OA300BenchmarkTests:43`, `AblationFullMatrixTests:100`, `PerformanceBenchmarkTests:245`, `MLPolicySweepTests:53`, `SharedDecodeImpactTests:63`, `SuperFluxImpactTests:52`, `BNNSImpactTests:257`, `DAWOracleBenchmarkTests:58`, `CorpusTracksDecodingTests:173`. daw Swift reader (1): `DAWOracleBenchmarkTests:65`. oa300 Python readers (3): `dataset.py`, `corpus_common.py:320`, `build_fr18_input.py:49`. Writers: `convert-rekordbox-export.py:235` (oa300), `scripts/dawproject-bpm.py:169` (daw, `make oracle-generate`).
- Develop-only: script, report, Makefile target, all Python — must not ship to main. Commit: `Story 8-8b: <deliverable>`. [[feedback_commit_messages_focus_on_deliverables]]

### References

- Consumer ground truth: [Source: Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift:20-90], [Source: Tests/BoomBoomBoomKitBenchmarkTests/DAWOracleBenchmarkTests.swift:49-78]
- Epic AC: [Source: _bmad-output/planning-artifacts/epics.md#Story 8.8 (lines 1180-1194)]
- Makefile oracle targets: [Source: Makefile `oracle-generate` / `oracle-generate-beats` / `py-lint`]
- Codex review (P1/P2/P3): thread 019ee3a2

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (spec authored)

### Debug Log References

### Completion Notes List

### File List
