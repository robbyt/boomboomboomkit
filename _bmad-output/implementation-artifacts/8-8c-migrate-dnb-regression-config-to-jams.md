---
baseline_commit: b2f10675457d8552b6efa1fc72072387c399e627
---

# Story 8.8c: Migrate the DnB triplet regression config to JAMS (in place)

Status: done

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

- [x] **Task 1 — DnB converter (AC: 1, 2, 3, 4).** Add the DnB converter to `migrate-to-jams.py`: per-entry `tempo` + sandbox `{partition, source, currentPredictedBpm, currentAbsError, rationale}`, corpus-level sandbox `{schema_version, regression_threshold, captured_with}`; idempotent-validating; git-config curator.
- [x] **Task 2 — Migrate fixture (AC: 2).** Run `make oracle-migrate-to-jams`; commit the rewritten `4-dnb-triplet-targets.json`; prove idempotency (no diff on re-run).
- [x] **Task 3 — Swift consumers (AC: 5).** Migrate `BNNSImpactTests`, `SuperFluxImpactTests`, `DnBTargetsFileLoadingTests` to the shared decoder; preserve every invariant + the prefix join rule; collapse local mirrors onto the public 8.8a types where practical.
- [x] **Task 4 — Python consumer (AC: 6).** Update `curate_sentinels.py` to read DnB JAMS.
- [x] **Task 5 — Report + gauntlet (AC: 7).** Append the DnB report row; run the gauntlet; `jams.load` spot-check.

### Review Findings

Adversarial review of the full 8-8a/b/c branch (blind hunter + edge-case hunter + acceptance auditor). 3 patch findings (all fixed in `8c2479f`), 4 deferred (pre-existing/latent), 4 dismissed.

- [x] [Review][Patch] DnB readers silently drop unexpected/absent-partition entries under the `controls >= 4` floor [SuperFluxImpactTests.swift, DnBTargetsFileLoadingTests.swift] — fixed: assert `targets + controls == entries.count`
- [x] [Review][Patch] Migrator validated only idempotent re-runs, not its forward-conversion output; no `daw` validation branch [migrate-to-jams.py] — fixed: `validate_jams(result, artifact)` on the forward path + a `daw` branch
- [x] [Review][Patch] `convert_daw` `bool(...)`-coerced `rekordbox_disagrees` (a stray string `"false"` → True) [migrate-to-jams.py:145] — fixed: pass-through + loud non-bool rejection
- [x] [Review][Defer] `tempoBPM()` has no BPM positivity/range guard (0/negative decodes silently) [JAMSDecoder.swift] — deferred, pre-existing (flat decoder had the same gap; values benchmark-proven)
- [x] [Review][Defer] Swift `first-non-nil value` vs Python `data[0]` decode asymmetry [JAMSDecoder.swift / jams_corpus.py] — deferred, latent (single-observation today)
- [x] [Review][Defer] No `track_id` uniqueness guard for oa300/daw migration [migrate-to-jams.py] — deferred, latent (no consumer enforces; 8-8b scope)
- [x] [Review][Defer] `jams_corpus.load_oa300_rows` accepts missing required fields as None [jams_corpus.py] — deferred, pre-existing (OA300 JAMS validated; Swift loud-fails)

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

- **Task 1 — DnB converter.** Added `convert_dnb` to `migrate-to-jams.py`: the DnB file is a nested config dict (not a flat array), so `main()` now branches input-shape by artifact (`dnb` → object, `oa300`/`daw` → array). Each `targets[]`/`dsp_correct_controls[]` element → one entry with a `tempo` observation (`ground_truth_bpm`, `confidence:1.0`) and a per-entry sandbox `{partition, source, current_predicted_bpm, current_abs_error, rationale?}`; the corpus-level `{schema_version, regression_threshold, captured_with}` rides the `{entries, sandbox}` wrapper. `validate_jams` gained a DnB branch (every entry has `partition ∈ {target, control}`; corpus sandbox carries `schema_version` + `regression_threshold`) so an idempotent re-run still fails loudly on a malformed already-JAMS file. ruff + ty clean.
- **Task 2 — Migrate fixture.** Wired the `dnb` step into the `oracle-migrate-to-jams` make target; ran it. `4-dnb-triplet-targets.json` → 8 entries (4 target + 4 control) + corpus sandbox, in place. Re-run is a validated no-op (zero diff) — idempotent.
- **Task 3 — Swift consumers.** All three readers decode the shared `JAMSCorpus` (`BoomBoomBoomKitTestSupport`). `DnBTargetsFileLoadingTests` + `SuperFluxImpactTests` collapse their local mirror structs entirely (read `JAMSFile`/sandbox directly). `BNNSImpactTests` keeps thin domain structs (`DnBTarget`/`DnBControl`/`RegressionThreshold`, now plain non-`Decodable` values built from JAMS) because ~20 logic sites read their snake_case fields — `DnBTargetsFile` reduced to a namespace for `expectedSchemaVersion`; `RegressionThreshold(jams:)` adapts the optional-field corpus sandbox. Every invariant preserved (schema_version==3, 4 targets, ≥4 controls, union uniqueness, controls 155–175 BPM, non-empty rationale) and the `filename == track_id || filename.hasPrefix(track_id + ".")` join rule is byte-unchanged. New error cases: `dnbTargetsMissingTrackID`, `dnbTargetsUnknownPartition`, `dnbRegressionThresholdMissing`.
- **Task 4 — Python consumer.** `curate_sentinels.py` `load_originals()` reads the `target`-partition entries from the JAMS corpus (`track_id`/`source` from `file_metadata`/`sandbox`, BPM from the `tempo` value) instead of `data["targets"]`. `make curate-sentinels` succeeds (12 entries: 4 originals + 8 expanded). The regenerated ships-to-main `12-dnb-sentinels-expanded.json` showed a diff confined to the 8 *expanded* Tony tracks (unrelated `tony-truth-labels.json` drift); the 4 DnB-derived originals are byte-identical, so the regenerated manifest + develop-only curation MD were reverted — committing the unrelated drift is out of scope for this story.
- **Task 5 — Report + gauntlet.** DnB row appended to `8-8-migration-report.md` (input shape `nested config`, 8 entries, corpus-level + per-entry sandbox fields). Gauntlet green: `make build`, 698 unit tests, `make py-lint` (ruff + ty), SwiftLint baseline-clean (only the canonical `LUFSAnalyzer.swift:135` TODO). `jams.load('<one control entry>', validate=True, strict=True)` in a throwaway venv accepted the extracted entry (namespace=tempo, value=170.0, sandbox.partition=control, rationale present) — proves each `entries[i]` is standalone-valid JAMS 0.4.
- **Curator email note.** `get_curator()` reads git config; the local identity is `robbyt@robbyt.net`, so all three migrated artifacts (oa300/daw/dnb) consistently carry that email. The spec AC 4 literal `robbyt@gmail.com` is only the empty-config fallback; the curator *name* `Robert Terhaar` matches.
- **Adversarial review follow-ups (3 patches).** (1) Partition completeness — `SuperFluxImpactTests` and `DnBTargetsFileLoadingTests` split entries by `partition` equality, so an entry with an unexpected/absent partition (or, in SuperFlux, a missing `track_id`) was silently dropped from both sets while the `controls >= 4` floor masked the loss; both now assert `targets + controls == entries.count` and fail loudly. (`BNNSImpactTests` was already loud via `dnbTargetsUnknownPartition`.) (2) Migrator output validation — `validate_jams(result, artifact)` now also runs on the forward-conversion path (not just the idempotent re-run), so a bad migration (e.g. a present-but-blank `genre`) fails at migration time instead of benchmark time; added a `daw` branch asserting `rekordbox_bpm` numeric + `rekordbox_disagrees` bool. (3) Boolean-coercion footgun — `convert_daw` no longer wraps `rekordbox_disagrees` in `bool(...)` (which would flip a stray string `"false"` to `True`); the value passes through and the new daw validation rejects a non-bool loudly. Deferred (pre-existing/latent, not regressions of this branch): `tempoBPM()` BPM range guard, Swift-first-non-nil vs Python-`data[0]` asymmetry, oa300/daw `track_id` uniqueness, `jams_corpus.py` None-field tolerance.

### File List

- `_bmad-output/ml-training/migrate-to-jams.py` (modified — DnB converter + dict-input shape + DnB validation)
- `Makefile` (modified — `oracle-migrate-to-jams` now also migrates the DnB fixture)
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-dnb-triplet-targets.json` (migrated in place → JAMS corpus)
- `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift` (modified — JAMS loader + domain-struct adapter)
- `Tests/BoomBoomBoomKitBenchmarkTests/SuperFluxImpactTests.swift` (modified — JAMS loader, mirror structs removed)
- `Tests/BoomBoomBoomKitTests/DnBTargetsFileLoadingTests.swift` (modified — reads JAMSCorpus via shared decoder)
- `_bmad-output/ml-training/curate_sentinels.py` (modified — `load_originals` reads DnB JAMS)
- `_bmad-output/implementation-artifacts/8-8-migration-report.md` (modified — DnB row appended)

## Change Log

- 2026-06-20 — Migrated the DnB triplet regression config (`4-dnb-triplet-targets.json`) to a JAMS corpus in place: per-track `ground_truth_bpm` → `tempo` observations, per-entry config → sandbox (`partition`/`source`/predicted-bpm/abs-error/`rationale`), corpus-level config → corpus sandbox (`schema_version`/`regression_threshold`/`captured_with`). Added the DnB converter to `migrate-to-jams.py` + the make target; migrated the 3 Swift readers + `curate_sentinels.py` to the shared 8.8a decoder; all schema-v3 invariants + the prefix join rule preserved. Gauntlet green (698 unit tests, py-lint, SwiftLint baseline); `jams.load` strict spot-check passed.
