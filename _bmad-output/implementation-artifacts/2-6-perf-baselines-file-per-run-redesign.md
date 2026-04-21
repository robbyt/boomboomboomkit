# Story 2.6: Perf-Baselines File-Per-Run Redesign

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a library author,
I want each `make perf-benchmark` run to write an immutable per-run JSON file instead of appending to a single shared array file,
so that concurrent/repeated runs can't race or corrupt baselines, merge conflicts on a shared history file disappear, and regression comparisons become a trivial glob-and-sort at read time.

## Acceptance Criteria

1. **Given** the current Swift 6 `PerformanceBenchmarkTests.swift` that reads `_bmad-output/perf-baselines/Apple_M5_Max-26.json` as a JSON array and writes a mutated copy back,
   **When** this story lands,
   **Then** the `BaselineStore` type is redesigned so that each run writes **exactly one new file** — a single-object JSON containing the same `BaselineRecord` shape Story 2.3 already defined (schemaVersion 2, all existing fields preserved verbatim).
   **And** the writer writes to a `.tmp`-suffixed sibling in the same directory via `data.write(to: tempURL)` (plain write, no `.atomic` flag — Foundation's `.atomic` is redundant here because the subsequent `moveItem` is the single atomic publish), then `FileManager.moveItem(at:to:)` into the final `.json` name — publish is atomic; a partial write is never visible to a concurrent reader. If `moveItem` throws because the destination already exists (near-impossible given the UUID suffix), the error is caught and logged as a warning.
   **And** the previous read-modify-write `append(_:to:)` helper is removed. No code path in the repo reads-then-rewrites a baseline file.

2. **Given** the file-per-run layout,
   **When** a run persists a record,
   **Then** the filename follows this exact template:
   ```
   {fingerprint}--{buildConfiguration}--{recordedAt}--{gitSHA}--{shortUUID}.json
   ```
   Where:
   - `{fingerprint}` = the existing `BaselineStore.fingerprintFilename` output with the trailing `-{osMajor}.json` stripped (e.g. `Apple_M5_Max-26`).
   - `{buildConfiguration}` = `Debug` or `Release` (from `HardwareInfo.buildConfiguration`).
   - `{recordedAt}` = UTC ISO-8601 basic form, colons removed, seconds precision. Example: `20260418T143022Z`.
   - `{gitSHA}` = the short SHA from the `GIT_SHA` env var. Literal `unknown` when the env var is missing or empty.
   - `{shortUUID}` = lowercase hex, first 8 chars of a fresh `UUID().uuidString.lowercased()` — eliminates collision logic at construction time.
   - All segments separated by **double-hyphens** (`--`) so a downstream parser can split safely even though `{fingerprint}` and `{gitSHA}` both contain single hyphens.

   Full example: `Apple_M5_Max-26--Debug--20260418T143022Z--d224cb7--8f3a91c2.json`
   **And** the separator in the Swift source is a single named constant (e.g. `baselineFilenameSeparator = "--"`) so a future change can't drift between writer and reader.

3. **Given** the reader inside `PerformanceBenchmarkTests.swift` that previously loaded the last record from the one-array file,
   **When** this story lands,
   **Then** it globs `PERF_BASELINE_DIR/*.json` via `FileManager.contentsOfDirectory(at:includingPropertiesForKeys:options:)` with `.skipsHiddenFiles`, extracts `.lastPathComponent` from each returned URL, filters to files whose name starts with `{current-fingerprint}--{current-buildConfiguration}--` (so a Debug run is never compared to a Release record and an Intel Mac doesn't compare against the M5 Max history), decodes each, sorts by the JSON-object `recordedAt` field (not the filename), and selects the last record as the previous baseline for the `Δ vs last baseline` line.
   **And** because `readHistory` is called **before** `write`, the just-written record is never in the history — no exclusion filter is needed. The read-before-write ordering is the load-bearing invariant; do not reorder.
   **And** temp files (`*.tmp`), dotfiles (`.*`), and any file whose name does not match the double-hyphen template are skipped silently (not counted as malformed, not renamed).
   **And** a single malformed JSON file (invalid JSON, missing required field, `schemaVersion != 2`) is warned+skipped by printing a one-line warning and excluded from the comparison set — it does not abort the test, does not rename the file, does not wedge future runs. The run continues.
   **And** the Story 2.3 `BaselineStoreError.malformed` rename-to-`.corrupt-*` code path is removed — it was load-bearing for a single mutable file and is counter-productive when files are immutable per-run.

4. **Given** the Makefile `perf-benchmark` target,
   **When** this story lands,
   **Then** the staging tempdir + copy-back flow is removed. The target runs `swift test` once with `PERF_BASELINE_DIR=$(CURDIR)/_bmad-output/perf-baselines` and the Swift writer publishes directly into that directory via the atomic temp-then-rename pattern.
   **And** the target no longer invokes `scripts/perf-commit.sh`.
   **And** the `mkdir -p "$(CURDIR)/_bmad-output/perf-baselines"` line at the top of the target is preserved — first-run-on-a-fresh-clone still needs the directory to exist.
   **And** `GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown)` continues to be set — the filename depends on it.

5. **Given** `scripts/perf-commit.sh` (the mkdir-mutex + staging copy-back script),
   **When** this story lands,
   **Then** the file is **deleted**. Not moved to `scripts/archived/`. Not renamed. Deleted outright.
   **And** no other file in the repo references it (verify via `grep -r perf-commit.sh`).
   **Rationale:** user directive — no cruft; retired scripts are deleted, not archived.

6. **Given** the existing `_bmad-output/perf-baselines/Apple_M5_Max-26.json` (6 records, append-only array, Story 2.3 schema),
   **When** this story lands,
   **Then** a one-shot migration script `scripts/migrate-perf-baselines.py` is used to emit 6 per-run files using each record's existing `recordedAt` + `gitSHA` + chip + osMajor fields to build the filename per AC #2. The `{shortUUID}` for migrated records is a random one generated at migration time (the original records had no UUID — this is acceptable, migration is a one-time operation and collision is impossible for distinct `recordedAt` seconds).
   **And** the script is invoked **once** during this story's implementation. After verification the six files decode and the reader sorts them correctly, `Apple_M5_Max-26.json` and `scripts/migrate-perf-baselines.py` are both **deleted in the same commit**.
   **And** after the delete, the only files under `_bmad-output/perf-baselines/` are the 6 migrated per-run files (7 if this story's dev-run persists a new record during validation, which is fine — delete cruft in the implementation PR, not in the one-shot migrator).

7. **Given** the `.claude/skills/running-benchmarks/SKILL.md` skill doc,
   **When** this story lands,
   **Then** it is rewritten to reflect the new design. Specifically:
   - The "never rewrite the file" invariant in the Overview is replaced with: *per-run files are immutable once published; a bad file may be deleted only with an explicit reason cited in the commit.*
   - The "Core rule" about `swift test --filter <Benchmark>` vs `make perf-benchmark` is preserved — `make perf-benchmark` is still the only supported entry point because it sets `PERF_BASELINE_DIR` and `GIT_SHA`.
   - The staging-tempdir / mutex / mkdir-lock discussion is removed — those concepts no longer exist.
   - The `jq` recipes are rewritten for globbed multi-file input: `jq -s '.' _bmad-output/perf-baselines/*.json | jq ...` — the `-s` slurp flag aggregates the per-file objects into a single array the existing recipe shape can operate on. The "Most recent record", "Last 5 runs", "Delta between last two runs", "OA300 accuracy history as CSV", and "Regressions" recipes are all updated.
   - A new "Common mistakes" row is added: **"Running two `make perf-benchmark` concurrently on the same machine"** → consequence: *baselines persist correctly because filenames are unique-by-construction, but both runs' timing numbers are corrupted by CPU contention*. Fix: *run serially*.
   - The "Editing the benchmark infrastructure" section reference to `scripts/perf-commit.sh` is removed.

8. **Given** the redesigned system,
   **When** `make perf-benchmark` runs twice back-to-back on the same HEAD,
   **Then** two new files appear under `_bmad-output/perf-baselines/` — same `{fingerprint}`, same `{buildConfiguration}`, same `{gitSHA}`, different `{recordedAt}` (assuming ≥1s gap) or different `{shortUUID}` (if same-second). Neither file overwrites the other.
   **And** the second run's `Δ vs last baseline:` line references the first run's record.
   **And** no warnings, no errors, no renamed files.

9. **Given** unit-test coverage,
   **When** this story lands,
   **Then** `BaselineStoreUnitTests` is extended with tests for:
   - Filename template construction (builder given fixed inputs produces the exact AC #2 example).
   - Filename uniqueness (same inputs produce different filenames via UUID suffix).
   - Filename parser (inverse of builder — can extract fingerprint / buildConfiguration / recordedAt / gitSHA / UUID from a produced filename; used by the reader's prefix filter).
   - Reader tolerates 0, 1, 2, N files in the dir.
   - Reader sorts by `recordedAt` field (files with out-of-order timestamps are returned sorted ascending).
   - Reader tolerates exactly one malformed file (warn+skip) alongside N valid ones — asserts the N-1 valid ones are returned.
   - Reader skips `schemaVersion != 2` files with warning (structurally valid JSON, wrong schema — distinct path from malformed JSON).
   - Reader filters by `{fingerprint}--` prefix — an Intel record in the dir is not compared against a current Apple run.
   - Reader filters by `{buildConfiguration}--` prefix — a Release record is excluded from a Debug query.
   - Reader skips `.tmp` files in the directory.
   - Reader skips dotfiles (`.DS_Store`, `._*`) in the directory.
   - Round-trip: write → read-back — a single record published via the new writer is found by the new reader with identical field values.
   **And** the existing `p95Index` and `fingerprintFilename` unit tests remain passing.

10. **Given** the Makefile target surface,
    **When** this story lands,
    **Then** `make benchmark`, `make benchmark-giantsteps`, `make oracle`, `make ablation`, and `make perf-benchmark` all continue to pass without further edits. No other target references `perf-commit.sh` or the old staging flow.

## Tasks / Subtasks

**Execution order:** 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Tasks 2 and 3 can parallelize after Task 1 lands.

- [x] **Task 0: Baseline capture** (AC: #6, #8)
  - [x] 0.1 Before any edits, snapshot the current `Apple_M5_Max-26.json` byte-for-byte into a scratch location (e.g., `/tmp/pre-2-6-baseline.json`). Used at Task 6 as the migration source-of-truth and at Task 8 to verify the last record's `meanSeconds`/`gitSHA`/`recordedAt` round-trip exactly through the new reader.
  - [x] 0.2 `git log -1 --format=%H _bmad-output/perf-baselines/Apple_M5_Max-26.json` — record the SHA that last touched the old file, for the commit message.

- [x] **Task 1: Swift writer/reader redesign** (AC: #1, #2, #3, #9)
  - [x] 1.1 In `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift`, replace `BaselineStore.fingerprintFilename` with:
    - `fingerprintPrefix(chip:osMajor:) -> String` returning the chip+osMajor prefix without the `.json` extension (e.g., `Apple_M5_Max-26`).
    - `buildRecordFilename(fingerprint:buildConfiguration:recordedAt:gitSHA:) -> String` returning the full filename per AC #2. The `{shortUUID}` is generated inside this function via `UUID().uuidString.lowercased().prefix(8)`.
    - A `private static let baselineFilenameSeparator = "--"` constant used by both builder and parser (AC #2 final clause).
  - [x] 1.2 Replace `BaselineStore.loadRecords(from:)` and `BaselineStore.append(_:to:)` with:
    - `BaselineStore.write(_ record: BaselineRecord, fingerprint: String, to dir: URL) throws` — builds the filename, encodes pretty-printed sortedKeys JSON, writes to `<final>.tmp` in the same dir via `data.write(to: tempURL)` (plain write, no `.atomic` flag), then `FileManager.moveItem(at:to:)` into `<final>`. Catches `moveItem` failure on existing destination with a warning. Throws on encode/write failure.
    - `BaselineStore.readHistory(from dir: URL, fingerprint: String, buildConfiguration: String) throws -> [BaselineRecord]` — calls `FileManager.contentsOfDirectory(at:includingPropertiesForKeys:options: .skipsHiddenFiles)`, extracts `.lastPathComponent` from each URL, filters to files whose name starts with `"\(fingerprint)--\(buildConfiguration)--"` and ends with `.json` and does not end with `.tmp`, decodes each, schema-guards `schemaVersion == 2`, warns+skips malformed, returns the survivors sorted by `recordedAt` ascending.
  - [x] 1.3 Delete the `BaselineStoreError.malformed` rename-to-`.corrupt-*` path in `handleBaselinePersistence` (AC #3 final clause). A malformed-file warning lives inside `readHistory` now — the persistence path just logs it and moves on.
  - [x] 1.4 Rewrite `handleBaselinePersistence` to:
    1. Derive `fingerprint` = `fingerprintPrefix(chip:osMajor:)` from the current `HardwareInfo`.
    2. Call `readHistory(from:fingerprint:buildConfiguration:)` **before** writing — read-before-write ordering is load-bearing; the just-written record must not appear in history.
    3. If non-empty, the last element IS the previous record — print `Δ vs last baseline:` using that record's `gitSHA` + `recordedAt` + `meanSeconds`.
    4. Call `BaselineStore.write(record, fingerprint: fingerprint, to: dir)` unconditionally (skip-persist-on-failedCount gate is preserved in `benchmarkWallClockTime()` upstream — same threshold, same behavior, not touched by this story).
  - [x] 1.5 Compilation guard: `swift build` and `swift test --filter BaselineStoreUnitTests` (the unit tests don't require `OA300_CORPUS_PATH`).

- [x] **Task 2: Unit test expansion** (AC: #9)
  - [x] 2.1 In `BaselineStoreUnitTests`, add:
    - `@Test("buildRecordFilename — exact template")` asserting a fixed-input call produces `Apple_M5_Max-26--Debug--20260418T143022Z--d224cb7--<uuid>.json` with UUID matching `[0-9a-f]{8}`.
    - `@Test("buildRecordFilename — same inputs produce unique filenames")` calling `buildRecordFilename` twice with identical inputs and asserting the filenames differ (by UUID segment).
    - `@Test("parseRecordFilename — inverse of builder")` decoding back a produced filename into its components.
    - `@Test("readHistory — 0/1/2/N files")` using a throw-away tmp dir.
    - `@Test("readHistory — sorting by recordedAt")` writing files with out-of-order `recordedAt` values and asserting the returned array is sorted ascending by `recordedAt`, not by filename.
    - `@Test("readHistory — one malformed file")` writing one valid JSON + one `"{nonsense"` file and asserting the valid one is returned.
    - `@Test("readHistory — schemaVersion mismatch skipped")` writing a structurally valid JSON file with `schemaVersion: 1` alongside a valid v2 file and asserting only the v2 file is returned (distinct code path from malformed JSON).
    - `@Test("readHistory — fingerprint prefix filter")` writing a file named for an Intel fingerprint into the dir and asserting it is excluded from an Apple `readHistory` call.
    - `@Test("readHistory — buildConfiguration prefix filter")` writing a `--Release--` file into the dir and asserting it is excluded from a `--Debug--` `readHistory` call.
    - `@Test("readHistory — skips .tmp files")` placing a `.tmp` file in the directory and asserting `readHistory` excludes it.
    - `@Test("readHistory — skips dotfiles")` placing a `.DS_Store` and `._foo.json` in the directory and asserting `readHistory` excludes them.
    - `@Test("write → readHistory round-trip")` writing a record and asserting the reader finds it with equal field values.
    - `@Test("write atomicity — temp file absent post-write")` verifying no `.tmp` orphan remains after a successful write.
  - [x] 2.2 Delete `@Test("loadRecords treats missing file as empty array")` and `@Test("fingerprintFilename sanitizes chip and formats with osMajor")` — they test APIs that no longer exist. Replace the second with a `@Test("fingerprintPrefix — sanitization")` covering the same chip-sanitization cases but against the new function.
  - [x] 2.3 `swift test --filter BaselineStoreUnitTests` — all green, no corpus env required.

- [x] **Task 3: Makefile cleanup + script deletion** (AC: #4, #5)
  - [x] 3.1 In `Makefile`, rewrite the `perf-benchmark` target to:
    ```makefile
    perf-benchmark:
    	@mkdir -p "$(CURDIR)/_bmad-output/perf-baselines"
    	OA300_CORPUS_PATH="$(OA300_CORPUS_PATH)" \
    	GIANTSTEPS_CORPUS_PATH="$(GIANTSTEPS_CORPUS_PATH)" \
    	PERF_BASELINE_DIR="$(CURDIR)/_bmad-output/perf-baselines" \
    	GIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo unknown) \
    	swift test --filter BoomBoomBoomKitBenchmarkTests.PerformanceBenchmarkTests
    ```
    No staging dir, no trap, no conditional, no `perf-commit.sh` invocation. The Swift writer publishes directly.
  - [x] 3.2 Delete `scripts/perf-commit.sh` (`git rm scripts/perf-commit.sh`). Do not `mv` to `scripts/archived/`.
  - [x] 3.3 Grep the repo for any other references: `rg 'perf-commit|BENCH_STAGE|staging' --glob '!_bmad-output/implementation-artifacts/2-3-*'` — expected: zero matches outside Story 2.3's historical notes. Remove any stragglers (comments, CLAUDE.md, READMEs — there are none currently but verify).

- [x] **Task 4: Run and verify a fresh persistence (sanity pass before migration)** (AC: #8)
  - [x] 4.1 With the redesigned code in place (Tasks 1-3) but BEFORE deleting the old `Apple_M5_Max-26.json`: run `make perf-benchmark`. Confirm a new per-run file appears under `_bmad-output/perf-baselines/` matching the AC #2 template.
  - [x] 4.2 Confirm the old `Apple_M5_Max-26.json` is still present (the new code does not touch it — it reads only the new-format files). The `Δ vs last baseline:` line prints `(no prior record on this machine fingerprint)` because no new-format file existed before this run.
  - [x] 4.3 Run `make perf-benchmark` a second time. The second run's `Δ vs last baseline:` line should reference the first run's `recordedAt` + `gitSHA`.
  - [x] 4.4 Verify: the two new files sort correctly by `recordedAt`. No `.tmp` orphans. No warnings.

- [x] **Task 5: Write the migration script** (AC: #6)
  - [x] 5.1 Create `scripts/migrate-perf-baselines.py` with a `uv run` shebang header (matches other scripts in the repo, e.g., `scripts/dawproject-bpm.py`). The script:
    1. Reads `_bmad-output/perf-baselines/Apple_M5_Max-26.json` as JSON array.
    2. For each record, constructs the filename per AC #2: `{fingerprint}--{buildConfiguration}--{recordedAt-compact}--{gitSHA}--{random8hex}.json`. Derives `fingerprint` by sanitizing `record.hardware.chip` identically to the Swift `fingerprintPrefix` (letters/digits/dash/underscore kept; other chars → `_`; collapse runs of `_`) then appending `-<osMajor>` extracted from `record.hardware.osVersion` (parse the leading `"Version 26.5"` → `26`). Compact `recordedAt` by removing `:` and `-` (already UTC `Z` suffix, already seconds precision).
    3. Writes each record as a pretty-printed sortedKeys JSON object (not array) to its derived filename under `_bmad-output/perf-baselines/`.
    4. After writing all 7 files (7 records were present at migration time, not 6), deletes `_bmad-output/perf-baselines/Apple_M5_Max-26.json`.
  - [x] 5.2 Dry-run: add a `--dry-run` flag that prints the 7 filenames without writing. Sanity check each filename is well-formed and unique.
  - [x] 5.3 Real run: `uv run scripts/migrate-perf-baselines.py`. Confirm 7 new files + the array file deleted.
  - [x] 5.4 Delete `scripts/migrate-perf-baselines.py` (untracked file removed with `rm`). This is a one-shot script; it is not retained.

- [x] **Task 6: Post-migration reader regression** (AC: #6, #8)
  - [x] 6.1 Run `make perf-benchmark`. The `Δ vs last baseline:` line references the most recent record by `recordedAt`. Because Task 4 ran two perf-benchmark runs before migration (creating new-format files with later timestamps than the migrated records), the delta references the second Task 4 run (`SHA 8cf77bd, 2026-04-19T19:49:06Z`) — correct behavior; the reader sorts by `recordedAt` and the Task 4 files are more recent.
  - [x] 6.2 No debugging required — reader correctly sorted all 9 files and referenced the most recent.

- [x] **Task 7: Skill doc rewrite** (AC: #7)
  - [x] 7.1 Rewrite `.claude/skills/running-benchmarks/SKILL.md`:
    - Overview: replace the append-only framing with "per-run immutable files, glob-and-sort at read time."
    - Keep the "never use `swift test --filter <Benchmark>` directly" core rule — it remains correct because `make perf-benchmark` sets `PERF_BASELINE_DIR` and `GIT_SHA` env vars.
    - Drop the staging/mutex/lock paragraphs entirely.
    - Rewrite the perf-benchmark row in the Make targets table to drop "temp-dir staging."
    - Rewrite the "perf-benchmark JSON schema" section: the on-disk shape is now a JSON **object** per file, not an array of objects. Schema v2 content unchanged.
    - Rewrite the "jq recipes" section: every recipe becomes `jq -s '.' _bmad-output/perf-baselines/*.json | jq '<existing-recipe-body>'` or a per-file `for f in _bmad-output/perf-baselines/*.json; do jq ... "$f"; done` for the CSV/TSV cases.
    - Add a "Common mistakes" row for the concurrent-run timing caveat (AC #7 fifth bullet).
    - Remove the `scripts/perf-commit.sh` reference in "Editing the benchmark infrastructure."
  - [x] 7.2 Preserve all Chip/OS fingerprinting guidance — it still applies.
  - [x] 7.3 Re-read the rewritten skill doc end-to-end. No references to retired concepts remain.

- [x] **Task 8: Completion + sprint status** (AC: all)
  - [x] 8.1 Final verification pass: `make build && make test && make perf-benchmark`. All three pass. New per-run file appears; `Δ vs last baseline:` references the most recent prior run; no warnings about malformed or renamed files.
  - [x] 8.2 Confirm the working tree state:
    - `scripts/perf-commit.sh` — absent.
    - `scripts/migrate-perf-baselines.py` — absent.
    - `_bmad-output/perf-baselines/Apple_M5_Max-26.json` — absent.
    - `_bmad-output/perf-baselines/*.json` — 11 files (7 migrated + 4 fresh from verification runs). All match the AC #2 template.
  - [x] 8.3 Flip Status: `ready-for-dev` → `review`. Update `_bmad-output/implementation-artifacts/sprint-status.yaml` key `2-6-perf-baselines-file-per-run-redesign` from `in-progress` → `review`.
  - [ ] 8.4 Commit message pattern (matches Epic 2 convention): `Story 2-6: Perf-baselines file-per-run redesign`.

## Dev Notes

### Why file-per-run over append-only

The original append-only design (Story 2.3) required a `mkdir`-as-mutex lock plus a staging-tempdir copy-back script because two concurrent `make perf-benchmark` runs on the same machine would read-modify-write the same JSON array and drop a record. File-per-run eliminates the shared-mutable-state problem by making every write independent: each run produces a unique filename (`recordedAt`-to-the-second + 8-char UUID suffix), so there is nothing to race against.

Second-order benefits:
- **Merge conflicts disappear** — two branches each adding a record previously conflicted on the array file; now they add disjoint files.
- **Interrupted runs don't corrupt** — a SIGKILL mid-write can leave a `.tmp` sibling, which the reader ignores.
- **Bisecting a regression is easier** — each record is a self-contained commit-diffable file.

The cost is a flat directory that grows unbounded. At one run per ship-ready commit, this is negligible for years. When it isn't, the fix is a `scripts/archive-old-baselines.py` one-shot — not a redesign.

### Why delete `perf-commit.sh` (not archive)

User directive: "we don't need to keep cruft around. Delete or replace old scripts." Archived scripts rot — they stop being updated, then a future contributor re-discovers them and is confused about whether they're live or dead. A `git log scripts/perf-commit.sh` retrieves the old content if anyone ever needs it; the file itself does not need to live in HEAD.

Same rationale applies to `scripts/migrate-perf-baselines.py` — a one-shot migrator that has already done its job is cruft.

### Atomic temp-then-rename — critical correctness property

Second opinion (Codex) flagged that "filesystem operations are atomic" is too loose. Only `rename()` and `mkdir()` are atomic on POSIX; plain `write()` is not atomic at the JSON-document level. Without temp-then-rename, a concurrent reader (or Dropbox sync daemon) can observe a partial file. The writer pattern must be:

```swift
let finalURL = dir.appendingPathComponent(filename)
let tempURL = dir.appendingPathComponent(filename + ".tmp")
try data.write(to: tempURL)  // Plain write, no .atomic flag
try FileManager.default.moveItem(at: tempURL, to: finalURL)
```

**Why no `.atomic` on the `.tmp` write:** Foundation's `.atomic` already does temp+rename internally (creates a `mkstemp`-named temp in the same directory, then renames). Using `.atomic` to write the `.tmp` file would mean three filesystem ops (Foundation temp -> `.tmp` -> final) instead of two (`.tmp` -> final). On Darwin/APFS, Foundation's `.atomic` always creates its temp in the same directory as the target (not `/tmp`), so the cross-device concern originally cited is not real on macOS. The explicit two-step with plain write is clearer and sufficient.

**`moveItem` does not overwrite:** `FileManager.moveItem(at:to:)` throws if the destination already exists. The UUID suffix in the filename makes collision near-impossible, but the writer should catch the error and log a warning rather than crashing.

### Why `{buildConfiguration}` is in the filename

Story 2.3 documented "Keep committed baselines Debug-mode (current convention). For Release runs, use a separate fingerprint file name." With a per-run filename carrying `--Debug--` or `--Release--`, the filesystem enforces this: a Release run produces a distinct file set that the Debug reader won't see, and vice versa. No convention-by-prayer.

### Why read-before-write ordering (not recordedAt filtering)

The "previous record" is the last element of the history array. Because `readHistory` is called **before** `write`, the just-written record is never in the history — no exclusion filter is needed. This read-before-write ordering is the load-bearing invariant. An earlier draft used `recordedAt` inequality as the filter, but this is fragile (two runs in the same second produce identical `recordedAt`, which would wrongly exclude both). The ordering approach is simpler and correct by construction.

### Why skip temp files and dotfiles

- `*.tmp` — a partial write caught mid-atomic-swap. Reader ignores; the next `make perf-benchmark` will retry its own write (the orphan is harmless).
- `.*` — macOS resource forks (`._*`), Dropbox sync metadata (`.dropbox`), editor swap files. None of these are ever real records.

### Concurrent runs — timing caveat (preserved in skill doc)

File-per-run removes the correctness hazard of concurrent runs (no shared mutable state to corrupt). It does **not** remove the CPU contention hazard — two concurrent `make perf-benchmark` invocations will both run the full benchmark, both compete for CPU cores, and both write records whose `wallClock.meanSeconds` is roughly 1.5-2× inflated. The records persist correctly and look legitimate but are unreliable. The skill doc now documents this as a Common Mistakes row.

### Dropbox-sync interaction

The repo lives under `~/Dropbox/research/swift/BoomBoomBoomKit/`. Dropbox's sync daemon observes directory changes at roughly ~1-second granularity. Two concerns:
- **Partial-file observation.** The daemon might upload a `.tmp` file or a half-written final file. Atomic temp-then-rename mitigates this: the final file appears to Dropbox as a single fully-formed artifact.
- **Conflict files.** Previously, the append-only array could generate `Apple_M5_Max-26 (conflicted copy).json` if a branch added a record on two machines simultaneously. With file-per-run, each run writes to a unique name; Dropbox has nothing to conflict.

### Migration: a one-shot Python script, not a Swift migrator

Codex-recommended. Reasoning:
- Python's `json` + `os` are shorter and simpler than Swift at CLI dispatch.
- The migration runs exactly once on the dev machine — no need to ship it.
- A Swift migrator would require an `ArgumentParser` dep or a standalone tool target, both of which are overhead for a 6-record one-shot.
- `uv run` matches the existing pattern for `scripts/dawproject-bpm.py` per CLAUDE.md.

### Impact on Story 2.3 Dev Notes

Story 2.3 documented the append-only + staging design as load-bearing. The contemporaneous text remains correct for that story's HEAD-at-land state; this story supersedes that invariant. No edit to Story 2.3's file is required — it is historical record.

### Schema version is NOT bumped

The on-disk per-record shape (schemaVersion 2, `recordedAt`, `gitSHA`, `hardware`, `wallClock`, `accuracy`) is identical. The aggregate-shape change (single-object-per-file vs array-of-objects-in-one-file) is not a record-level schema change. Migration preserves all six records verbatim. Readers and writers continue to enforce `schemaVersion == 2`.

### Files touched in this story

- **Edited:** `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` (BaselineStore rewrite, reader rewrite, handleBaselinePersistence rewrite, unit tests updated); `Makefile` (perf-benchmark target simplified); `.claude/skills/running-benchmarks/SKILL.md` (rewritten).
- **Deleted:** `scripts/perf-commit.sh`; `scripts/migrate-perf-baselines.py` (after one-shot execution); `_bmad-output/perf-baselines/Apple_M5_Max-26.json` (after migration).
- **Created (transient):** `scripts/migrate-perf-baselines.py` (deleted in same commit as task 5.4).
- **Created (persistent):** 6 per-run JSON files under `_bmad-output/perf-baselines/` (migration output). 1-2 additional per-run files from validation runs.
- **Story/sprint:** `_bmad-output/implementation-artifacts/2-6-perf-baselines-file-per-run-redesign.md` (this file); `_bmad-output/implementation-artifacts/sprint-status.yaml` (status flip).
- **No edit required:** `_bmad-output/implementation-artifacts/2-3-performance-benchmark-infrastructure.md` (historical record); `Sources/BoomBoomBoomKit/**` (no library code change); other benchmark suites.

### Out of scope

- Hardware-fingerprint migration to subdirectory layout (e.g., `perf-baselines/Apple_M5_Max-26/*.json`). Flat dir is sufficient for one machine and sub-linear glob cost on any plausible run count. Revisit if a second machine materializes.
- Retention policy for old per-run files. No pruning in this story; all 6 migrated + N future runs accumulate in the flat dir.
- Release-mode baseline fingerprinting. The `{buildConfiguration}--` filename segment already segregates Debug and Release files — no further work needed in this story.
- Schema v3. Not introduced here.
- A shared glob-and-sort helper in `BoomBoomBoomKitTestSupport`. The reader is specific to `PerformanceBenchmarkTests` today; if a second suite ever needs the same pattern, extract then. Premature abstraction is worse than duplication for a 10-line reader.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.6] (this story's epic entry)
- [Source: _bmad-output/implementation-artifacts/2-3-performance-benchmark-infrastructure.md] (the append-only design this story replaces — read for context on why the mutex/staging flow existed)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:74-181] (`BaselineRecord` struct and the legacy `BaselineStore` — both rewritten by this story)
- [Source: Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:566-637] (`handleBaselinePersistence` — rewritten by Task 1.4)
- [Source: scripts/perf-commit.sh] (deleted by Task 3.2 — read for context on mutex design)
- [Source: Makefile:59-76] (legacy `perf-benchmark` target with staging — rewritten by Task 3.1)
- [Source: .claude/skills/running-benchmarks/SKILL.md] (rewritten by Task 7)
- [Source: _bmad-output/perf-baselines/Apple_M5_Max-26.json] (6-record source file for migration; deleted by Task 5.3)
- [Source: CLAUDE.md] (confirms `uv run` as the Python invocation pattern for scripts)

### Previous-story intelligence

Story 2.3 (`2-3-performance-benchmark-infrastructure.md`) introduced the append-only + staging + mutex design this story dismantles. Key continuity points:
- `BaselineRecord` schemaVersion 2 and all its nested shapes are preserved verbatim. No field added, none removed.
- The `Δ vs last baseline:` behavior (format, content, SHA+timestamp citation) is preserved — only the *source* of the previous record changes (glob-and-sort vs last-array-element).
- The failedCount>10% skip-persist gate is preserved.
- The malformed-file rename-to-`.corrupt-*` sidecar behavior is **removed** — it was load-bearing for a mutable shared file and is counter-productive for an immutable-per-run file. Malformed files are warn+skipped at read time; their presence is a diagnostic signal, not a wedge.

Story 2.3 landed with 14 open Patch review findings on its story file. None of those findings block or affect this story — they are code-hygiene items in `PerformanceBenchmarkTests.swift` and `Makefile`, mostly in sections rewritten wholesale by this story. After this story lands, several of those findings become moot (they reference APIs that no longer exist).

### Git intelligence (recent commits)

Recent commits on `rterhaar/epic-2`:
- `6e39893` Story 2-3: Performance benchmark infrastructure with delta-vs-last-baseline reporting
- `a97bad2` Story 2-2: Dual-tolerance accuracy reporting and MIREX-compliant Acc2 unification
- `eefdb1f` Story 2-1: GiantSteps dual-tempo integration and MIREX-compliant Acc2

Epic 2 commit pattern: single commit per story with message `Story X-Y: <imperative-summary>`. Follow same pattern here.

## Dev Agent Record

### Agent Model Used

claude-opus-4-7 (story context engine)

### Debug Log References

### Completion Notes List

- 11 per-run files under `_bmad-output/perf-baselines/` at story completion: 7 migrated from the old array file + 4 from Task 4/6/8 verification runs (2 pre-migration sanity, 1 post-migration, 1 final).
- `scripts/perf-commit.sh` absent from HEAD (deleted via `git rm`).
- `scripts/migrate-perf-baselines.py` absent from HEAD (never committed; created and deleted locally as a one-shot tool).
- `_bmad-output/perf-baselines/Apple_M5_Max-26.json` absent from HEAD (deleted by the migration script).
- The array file had 7 records at migration time (not 6 as anticipated in the story spec — a 7th record was added by Story 2-5's perf run). All 7 migrated successfully.
- Skill doc rewrite: 216 lines before → 196 lines after (staging/mutex/jq-array recipes replaced with glob-sort recipes).
- No deviations from AC #2 filename template.
- Task 4 run #1 Δ-line: `(no prior record on this machine fingerprint)` (expected — first new-format file).
- Task 4 run #2 Δ-line: `Δ vs last baseline (SHA 8cf77bd, 2026-04-19T19:48:20Z): mean 0.225s → 0.217s (-3.3%)`.
- Task 6 Δ-line: `Δ vs last baseline (SHA 8cf77bd, 2026-04-19T19:49:06Z): mean 0.217s → 0.239s (+9.9%)` (references second Task 4 run, which is more recent than all migrated records — correct behavior).
- Final Task 8 Δ-line: `Δ vs last baseline (SHA 8cf77bd, 2026-04-19T19:50:54Z): mean 0.239s → 0.223s (-6.5%)`.
- Deviation note: `write` takes an explicit `fingerprint` parameter (not derived internally from `record.hardware`) — this keeps the function testable and avoids encoding OS-version parsing logic inside `BaselineStore`. The AC spec said `BaselineStore.write(_ record: BaselineRecord, to dir: URL)` but the fingerprint parameter is the cleaner design choice and consistent with the test isolation requirement.

### File List

- Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift (modified — BaselineStore rewrite, handleBaselinePersistence rewrite, BaselineStoreError removed, unit tests expanded from 5 to 15)
- Makefile (modified — perf-benchmark target simplified: staging/trap/conditional removed)
- .claude/skills/running-benchmarks/SKILL.md (rewritten — per-run file design, updated jq recipes, concurrent-run mistake row added)
- scripts/perf-commit.sh (deleted via git rm)
- _bmad-output/perf-baselines/Apple_M5_Max-26.json (deleted by migration script)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260417T051344Z--a97bad2--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260417T051437Z--a97bad2--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260417T232021Z--6e39893--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260418T023706Z--6e39893--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260418T111200Z--5d65780--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260418T111314Z--5d65780--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260419T044456Z--e58e60a--*.json (migrated)
- _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--20260419T*.json (4 verification-run files)
- _bmad-output/implementation-artifacts/2-6-perf-baselines-file-per-run-redesign.md (this file)
- _bmad-output/implementation-artifacts/sprint-status.yaml (status → review)
- _bmad-output/implementation-artifacts/deferred-work.md (stale BENCH_STAGE item annotated as retired)

## Review Findings

- [x] [Review][Patch] `readHistory` declared `throws` but never throws — remove annotation, delete dead caller catch [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift — `readHistory` declaration and `handleBaselinePersistence` call site]
- [x] [Review][Patch] SKILL.md "guarantees filename uniqueness" overclaims — change to "makes collisions near-impossible" [.claude/skills/running-benchmarks/SKILL.md — filename template description]
- [x] [Review][Patch] jq "Last 5 runs" returns 1 row not 5 — `last(limit(5;.[]))` returns final element of stream; fix: `.[-5:] | .[]` [.claude/skills/running-benchmarks/SKILL.md — "Last 5 runs" recipe]
- [x] [Review][Patch] jq delta recipe broken — `last(limit(2;.[])) as $pair` binds scalar; `$pair[0]`/`$pair[1]` return null; fix: `.[-2:] as $pair` [.claude/skills/running-benchmarks/SKILL.md — "Delta between last two runs" recipe]
- [x] [Review][Patch] jq regressions recipe always outputs `[]` — `.[.key - 1]` indexes entry object, not outer array; fix: bind `to_entries as $entries` before map [.claude/skills/running-benchmarks/SKILL.md — "Regressions" recipe]
- [x] [Review][Patch] `.tmp` orphan left on `data.write` throw — wrap in do/catch that removes temp and rethrows [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift — `write` function] (Gemini)
- [x] [Review][Patch] Trailing underscore in `fingerprintPrefix` for chip strings with trailing non-alnum — add `trimmingCharacters` after collapse loop; add test case [Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift — `fingerprintPrefix` function] (Gemini)
- [x] [Review][Defer] compactRecordedAt: non-UTC offset (e.g. `+05:30`) would leave `+` in filename — latent, current formatter hardcoded to UTC Z [PerformanceBenchmarkTests.swift — `write` function]
- [x] [Review][Defer] recordedAt string sort breaks for non-UTC timestamps — same latent root cause as above [PerformanceBenchmarkTests.swift — `readHistory` return sort]
- [x] [Review][Defer] jq noise floor: floor-index median is wrong for even N — pre-existing methodology choice, not a regression [.claude/skills/running-benchmarks/SKILL.md — "Noise floor" recipe]
- [x] [Review][Defer] same-second `recordedAt` sort: stable but filesystem-order for equal keys — `history.last` nondeterministic for rapid same-second runs; cosmetic impact only [PerformanceBenchmarkTests.swift — `readHistory` return sort]
- [x] [Review][Defer] temp `.json.tmp` file lives in Dropbox-synced dir during atomic write window — sub-ms lifetime on APFS; acknowledged trade-off in dev notes [PerformanceBenchmarkTests.swift — `write` function]

## Change Log

- 2026-04-19 — **Code review patches applied** (claude-sonnet-4-6). P1: removed misleading `throws` from `readHistory` + dead caller catch. P2: SKILL.md "guarantees" → "near-impossible". P3-P5: fixed three broken jq recipes (last-5-runs, delta, regressions). G1: `.tmp` cleanup on `data.write` throw. G2: trailing underscore trim in `fingerprintPrefix` + test case. All 15 `BaselineStoreUnitTests` green.
- 2026-04-19 — **Story implemented** (claude-sonnet-4-6). Replaced append-only `BaselineStore` with file-per-run writer (`write`/`readHistory`), removed `BaselineStoreError`, rewrote `handleBaselinePersistence` with read-before-write ordering, expanded unit tests from 5 to 15, simplified Makefile `perf-benchmark` target, deleted `scripts/perf-commit.sh`, migrated 7 existing array records to per-run files, deleted the one-shot migration script, rewrote `.claude/skills/running-benchmarks/SKILL.md`. All 157 unit tests pass; 11 per-run baseline files confirmed present.
- 2026-04-19 — **Party-mode roundtable validation** (Winston/Amelia/Siri/Quinn). Applied 4 fixes: (1) dropped double-atomic write pattern — plain write to `.tmp` then `moveItem`; (2) replaced `recordedAt` inequality filter with read-before-write ordering as the load-bearing invariant; (3) expanded unit tests from 7 to 13 covering sorting, schema-version-skip, buildConfiguration filter, `.tmp`/dotfile exclusion, UUID uniqueness; (4) added `contentsOfDirectory` API details (`.skipsHiddenFiles`, returns `[URL]`). Added `moveItem` non-overwrite caveat.
- 2026-04-18 — **Story created** (via `/bmad-create-story 2-6`). Status: `ready-for-dev`. Replaces the Story 2.3 append-only + mutex + staging design with a file-per-run immutable layout using atomic temp-then-rename. Incorporates Codex-reviewed corrections: atomic publish is mandatory (not optional); collision-free-by-construction via UUID suffix; `{buildConfiguration}` in filename segregates Debug/Release automatically; skill doc rewrite lives in-story because current doc contains load-bearing retired invariants. User directive: delete retired scripts, do not archive.
