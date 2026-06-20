# Story 8.8c: Migrate the DnB triplet regression config to JAMS (in place)

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **library maintainer consolidating on JAMS as the canonical ground-truth format**,
I want `4-dnb-triplet-targets.json` — a nested regression-test config, not a plain corpus — migrated **in place** to a JAMS corpus that carries its per-track tempo truth as `tempo` observations and its config/provenance fields in `sandbox` (the JAMS extension point), with all consumers updated,
so that the DnB triplet challenge set joins the single canonical JAMS format without dropping its schema-v3 invariants or curator provenance.

**Depends on:** Story 8.8a (shared JAMS model + sandbox union + corpus-level sandbox + validators). **Soft-depends on** 8.8b for the `migrate-to-jams.py` scaffold (this slice adds the DnB converter to it).

## Context

See 8.8a §Context for the shared operator rulings. This is the **pressure-release-valve** slice (epic AC 8.8 valve): `4-dnb-triplet-targets.json` is `{schema_version, captured_with, targets[], dsp_correct_controls[], regression_threshold}` — a regression config, so non-tempo fields route to `sandbox` rather than being dropped.

## Acceptance Criteria

1. **DnB converter added to `migrate-to-jams.py`** (extends 8.8b's scaffold; if 8.8b has not landed, this slice creates the scaffold per 8.8b AC 1). `make oracle-migrate-to-jams` now also converts the DnB fixture.

2. **`4-dnb-triplet-targets.json` → JAMS corpus, in place.** Each `targets[]` and `dsp_correct_controls[]` element → one `entries[i]` JAMSFile: `tempo` value = `ground_truth_bpm` (`confidence:1.0`); `identifiers.track_id = track_id`; `sandbox = {partition: "target"|"control", source, currentPredictedBpm, currentAbsError, rationale?}` (rationale present for controls). The **corpus-level** fields `schema_version`, `regression_threshold`, `captured_with` are carried in the **corpus-level `sandbox`** on the `{entries, sandbox}` wrapper. No source field dropped.

3. **Idempotent + validating.** Re-running against an already-JAMS DnB file does not rewrite it but still validates the DnB minimum shape (non-empty `entries`; corpus sandbox carries `schema_version` + `regression_threshold`; every entry has a `tempo` value + a `partition`) and exits non-zero + reports loudly on failure (Codex P3).

4. **Curator/provenance.** Every entry's `annotation_metadata.curator.name = "Robert Terhaar"`, `.curator.email = robbyt@gmail.com`, `.data_source = "DnB triplet challenge set, manually verified"`.

5. **Swift consumers read JAMS, invariants preserved.** The 3 DnB readers migrate to the shared 8.8a decoder, collapsing the local mirror structs where practical: `BNNSImpactTests:272` (`DnBTargetsFile`/`DnBTarget`/`DnBControl`/`RegressionThreshold`), `SuperFluxImpactTests:61` (local `*Lite` mirrors), `DnBTargetsFileLoadingTests:47` (`BoomBoomBoomKitTests` local mirrors). The join rule (`filename == track_id` or `filename.hasPrefix(track_id + ".")`, byte-preserved) and the invariants in `DnBTargetsFileLoadingTests` (schema_version == 3, targets.count == 4, controls.count ≥ 4, no duplicate `track_id` across targets ∪ controls, controls ∈ 155–175 BPM, non-empty rationale) all still hold — `schema_version`/`regression_threshold` read from the corpus sandbox, `track_id`/`ground_truth_bpm`/`rationale`/`partition` from entries.

6. **Python consumer reads JAMS.** `curate_sentinels.py:117` reads `track_id`/`ground_truth_bpm`/`source` from the JAMS entries + sandbox (instead of `data["targets"]`). `make curate-sentinels` succeeds; `make py-lint` clean.

7. **Migration report + gauntlet.** The DnB row is appended to `8-8-migration-report.md` (input shape, namespace `tempo`, entry count = targets + controls, curator populated, corpus-level + per-entry sandbox fields). `make build`/`make test` (incl. `DnBTargetsFileLoadingTests` + `BNNSImpactTests` paths) green; manual `jams.load` spot-check of one extracted DnB entry recorded.

## Tasks / Subtasks

- [ ] **Task 1 — DnB converter (AC: 1, 2, 3, 4).** Add the DnB converter to `migrate-to-jams.py`: per-entry `tempo` + sandbox `{partition, source, currentPredictedBpm, currentAbsError, rationale}`, corpus-level sandbox `{schema_version, regression_threshold, captured_with}`; idempotent-validating; git-config curator.
- [ ] **Task 2 — Migrate fixture (AC: 2).** Run `make oracle-migrate-to-jams`; commit the rewritten `4-dnb-triplet-targets.json`; prove idempotency (no diff on re-run).
- [ ] **Task 3 — Swift consumers (AC: 5).** Migrate `BNNSImpactTests`, `SuperFluxImpactTests`, `DnBTargetsFileLoadingTests` to the shared decoder; preserve every invariant + the prefix join rule; collapse local mirrors onto the public 8.8a types where practical.
- [ ] **Task 4 — Python consumer (AC: 6).** Update `curate_sentinels.py` to read DnB JAMS.
- [ ] **Task 5 — Report + gauntlet (AC: 7).** Append the DnB report row; run the gauntlet; `jams.load` spot-check.

## Dev Notes

- **Why `sandbox`:** the DnB file is a regression harness config (targets vs dsp-correct controls + a `regression_threshold` block + `captured_with` provenance), not a per-track corpus. The epic's pressure-release valve explicitly authorizes routing non-JAMS fields to `sandbox`. Per-entry `partition` distinguishes target vs control; corpus-level sandbox holds the config.
- **Cross-target collapse:** pre-8.8a, the DnB decode types were internal to `BoomBoomBoomKitBenchmarkTests` and re-mirrored in `SuperFluxImpactTests` + `DnBTargetsFileLoadingTests` (different target). 8.8a's public decoder in `TestSupport` lets all three read one type — prefer that over re-mirroring the JAMS shape three times.
- **Consumer inventory (file:line, verified):** Swift readers (3): `BNNSImpactTests:272` (+ `DnBTargetsFile` defs at `:1023-1074`, join at `:331`), `SuperFluxImpactTests:61` (local mirrors `:382-396`), `DnBTargetsFileLoadingTests:47` (local mirrors `:22-35`, invariants `:51-71`). Python reader (1): `curate_sentinels.py:117`.
- **Accuracy/ground-truth unchanged** — `ground_truth_bpm` values byte-preserved; only the container changed. Commit: `Story 8-8c: <deliverable>`. [[feedback_commit_messages_focus_on_deliverables]]

### References

- DnB invariants + decode shapes: [Source: Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift:45-72], [Source: Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:1023-1074], [Source: Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift:331-346]
- Source fixture shape: [Source: Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json]
- Python reader: [Source: _bmad-output/ml-training/curate_sentinels.py:116-127]
- Epic AC + pressure-release valve: [Source: _bmad-output/planning-artifacts/epics.md#Story 8.8 (lines 1182-1202)]
- Codex review (P3): thread 019ee3a2

## Dev Agent Record

### Agent Model Used

claude-opus-4-8 (spec authored)

### Debug Log References

### Completion Notes List

### File List
