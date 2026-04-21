---
name: running-benchmarks
description: Use when running BoomBoomBoomKit BPM accuracy or wall-clock benchmarks, interpreting perf-baseline JSON records, or comparing accuracy/timing results across git SHAs — covers corpus setup, make targets, expected counts, and jq recipes for historical review.
---

# Running Benchmarks

## Overview

BoomBoomBoomKit has five benchmark suites across two test targets. Running them consistently requires (a) the right corpus env var and (b) the right `make` target. Results live in two places: stdout (accuracy counts + timing summary printed on every run) and `_bmad-output/perf-baselines/` (persisted per-run JSON files, one file per benchmark run, used for cross-run delta).

Per-run files are immutable once published; a bad file may be deleted only with an explicit reason cited in the commit.

**Core rule:** Never invoke `swift test --filter <Benchmark>` directly — always use the Makefile target. The `make perf-benchmark` target sets `PERF_BASELINE_DIR` and `GIT_SHA`; running the Swift test directly skips both, so no baseline is written and the delta line is suppressed.

## When to use

- "Run the benchmarks" / "benchmark this" / "how did accuracy change?"
- About to land a DSP change and want a regression check
- Comparing perf numbers between two git SHAs
- Reviewing `_bmad-output/perf-baselines/*.json` and wanting to decode it
- Executing a story's Task 6 validation step that calls for benchmark re-run
- Reading accuracy counts from stdout and wanting to know whether they match reference

## Corpus & env var reference

| Env var | Default path | Required by | Unset behavior |
|---------|--------------|-------------|----------------|
| `OA300_CORPUS_PATH` | `/Users/rterhaar/Dropbox/OA300_OnsetAudio300` | `benchmark`, `oracle`, `ablation`, `perf-benchmark` | Suite `init() throws .corpusPathNotSet` — fails loudly. Empty string also rejected. |
| `GIANTSTEPS_CORPUS_PATH` | `/Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset` | `benchmark-giantsteps` | Required for `benchmark-giantsteps`. For `perf-benchmark` it is optional (the inline GiantSteps accuracy pass soft-skips and writes `accuracy.giantsteps = null`). |

Ground-truth files:
- `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/oa300-ground-truth.json` — 82 tracks with Rekordbox BPMs; the OA300 + DAWOracle + Ablation + Perf suites all load this.
- `$OA300_CORPUS_PATH/daw-oracle.json` — DAW-verified BPMs, generated via `make oracle-generate` from the `.dawproject` file; used only by `make oracle`.
- GiantSteps ground truth lives inside `$GIANTSTEPS_CORPUS_PATH` — suites discover it at runtime.

## Make targets — pick the right one

| Target | Runs | Wall-clock | Writes to | Reference output |
|--------|------|------------|-----------|------------------|
| `make test` | Unit target only (`BoomBoomBoomKitTests`) | <1s | — | 157/157 pass |
| `make benchmark` | OA300 Acc1/Acc2 @ 2% + 4% tolerance, all merge strategies | ~2 min | stdout | Acc1 57/82 (69.5%), Acc2 73/82 (89.0%), plus per-genre stratified table (see "Genre-stratified output" below) |
| `make benchmark-giantsteps` | GiantSteps Acc1/Acc2 with `tempo2` fallback, genre breakdown | ~2 min | stdout | Acc1 536/661 (81.1%), Acc2 545/661 (82.5%), plus per-genre stratified table (see "Genre-stratified output" below) |
| `make oracle` | 3-way diagnostic: ours vs Rekordbox vs DAW | ~3 s | stdout | Disagreement table (small; diagnostic-only) |
| `make ablation` | 64-combination DSP ablation + per-track impact | ~9 min (parallel) | stdout | Sorted Acc1 by preset |
| `make perf-benchmark` | Wall-clock timing (serial OA300) + OA300 + GiantSteps accuracy snapshot | ~40 s | stdout **and** `_bmad-output/perf-baselines/<Chip>-<OSMajor>--<BuildConfig>--<recordedAt>--<gitSHA>--<uuid>.json` | Mean 0.2-0.25s on M5 Max; same accuracy counts as `make benchmark` + `make benchmark-giantsteps` |

All four corpus-gated targets fail loudly on unset or empty `OA300_CORPUS_PATH` / `GIANTSTEPS_CORPUS_PATH`. There is no soft-skip — an unset required env var is a test failure.

## Reference counts (commit `6e39893`, `.optimal` preset, `maxConfidence` merge, intensity 7)

Use as regression sentinels. If the numbers shift after a code change, investigate the change.

- **OA300 @ 2%**: Acc1 = 57/82, Acc2 = 73/82
- **OA300 @ 4% (MIREX)**: see `make benchmark` output (looser tolerance, higher counts)
- **GiantSteps @ 2% (MIREX 5-factor, with `tempo2` fallback)**: Acc1 = 536/661, Acc2 = 545/661
- **Ablation best (`.optimal`)**: Acc1 = 57/82 on OA300 (same; the baseline is tuned to `.optimal`)

## Genre-stratified output

Both `make benchmark` (OA300) and `make benchmark-giantsteps` include an `@Test("genre-stratified accuracy")` method (`benchmarkByGenre`) that prints one per-genre Acc1/Acc2 table to stdout — powered by the shared `GenreAccuracyReporter` in `Sources/BoomBoomBoomKitTestSupport/GenreAccuracyReporter.swift`. The stratified test runs a single analysis pass (same run `benchmarkDefaultIntensity` uses), not a second one, so turning it on has no extra wall-clock cost.

Two markers in the `Status` column:

- **`insufficient`** — bucket has `total < 5` tracks (`GenreAccuracyReporter.minSampleSize`). Replaces the numeric Acc1/Acc2 cells. These buckets never receive the `** LOW **` marker.
- **`** LOW **`** — bucket Acc1 is ≥10 percentage points below the aggregate Acc1 (`GenreAccuracyReporter.significantRegressionPercentagePoints`). Absolute percentage-point delta; only fires on buckets large enough to report a number.

Both thresholds are `public static let` on `GenreAccuracyReporter` — change them there, not at each call site.

Expected OA300 stratification at commit tip of Story 2-5 (intensity 7, `.optimal` preset, `maxConfidence` merge): two numeric rows (`drum-and-bass: 67`, `breaks: 10`), four `insufficient` rows (`techno: 2`, `footwork: 1`, `half-time-dnb: 1`, `tech-house: 1`). The `** LOW **` flag did not fire on OA300 at the Story 2-5 tip (`breaks` at 60.0% is 9.5pp below aggregate 69.5%, just below the 10pp threshold).

GiantSteps renders the same table shape; at the Story 2-5 tip the `** LOW **` flag fires on `house`, `electro-house`, `progressive-house`, and `dj-tools` — the first actionable datum for Epic 3 technique tuning.

No jq recipe is needed: the stratified output is stdout-only. If a future story persists stratified stats to JSON (by extending the perf-baseline schema), jq recipes would go here.

## perf-benchmark JSON schema (v2)

Each run writes one JSON **object** (not an array) to a uniquely-named file under `_bmad-output/perf-baselines/`. `JSONEncoder` uses `.sortedKeys`, so disk order is alphabetical (not source-code order).

Filename template: `{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json`

- `{fingerprint}` = sanitized chip name + `-` + OS major version (e.g. `Apple_M5_Max-26`)
- `{buildConfig}` = `Debug` or `Release`
- `{recordedAt}` = UTC ISO-8601 basic form, seconds precision (e.g. `20260418T143022Z`)
- `{gitSHA}` = short git SHA from `GIT_SHA` env var, or `unknown`
- `{shortUUID}` = 8 lowercase hex chars — makes filename collisions near-impossible

Full example: `Apple_M5_Max-26--Debug--20260418T143022Z--d224cb7--8f3a91c2.json`

Separating segments with `--` (double-hyphen) allows safe splitting even though `{fingerprint}` and `{gitSHA}` contain single hyphens.

```json
{
  "schemaVersion": 2,
  "recordedAt": "2026-04-17T05:14:37Z",
  "gitSHA": "a97bad2",
  "buildConfiguration": "Debug",
  "swiftPackageVersion": "BoomBoomBoomKit (workspace HEAD)",
  "hardware": {
    "chip": "Apple M5 Max", "cores": 18,
    "physicalMemoryGiB": 128, "osVersion": "Version 26.5 (Build ...)"
  },
  "wallClock": {
    "corpus": "OA300", "intensity": 7,
    "trackCount": 82, "warmupExcluded": 1, "failedCount": 0,
    "meanSeconds": 0.216, "medianSeconds": 0.182,
    "p95Seconds": 0.285, "minSeconds": 0.140,
    "maxSeconds": 0.331, "totalSeconds": 17.49
  },
  "accuracy": {
    "oa300":      { "tolerance": 0.02, "acc1Correct": 57,  "acc2Correct": 73,  "total": 82 },
    "giantsteps": { "tolerance": 0.02, "acc1Correct": 536, "acc2Correct": 545, "total": 661 }
  }
}
```

Committed baselines are Debug-mode (current convention). A Debug run and a Release run produce separate file sets because `{buildConfig}` is part of the filename — the reader filters by `{fingerprint}--{buildConfig}--` prefix, so the two sets never mix.

## jq recipes for review

All examples target all matching files for the current machine fingerprint. Adjust the glob prefix for a different chip/OS.

**Most recent record, full:**
```bash
jq -s 'sort_by(.recordedAt) | last' _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**Last 5 runs as a compact tab table (SHA, date, mean seconds, Acc1):**
```bash
jq -rs '[.[] | {sha:.gitSHA, at:.recordedAt, mean:.wallClock.meanSeconds, acc1:.accuracy.oa300.acc1Correct}]
  | sort_by(.at) | .[-5:] | .[]
  | [.sha, .at, .mean, .acc1] | @tsv' _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**Delta between the last two runs (timing and accuracy):**
```bash
jq -s 'sort_by(.recordedAt) | .[-2:] as $pair |
  {prev_sha: $pair[0].gitSHA, curr_sha: $pair[1].gitSHA,
   delta_mean_pct: (($pair[1].wallClock.meanSeconds - $pair[0].wallClock.meanSeconds)
                    / $pair[0].wallClock.meanSeconds * 100),
   delta_oa300_acc1: ($pair[1].accuracy.oa300.acc1Correct - $pair[0].accuracy.oa300.acc1Correct),
   delta_giantsteps_acc1: ($pair[1].accuracy.giantsteps.acc1Correct - $pair[0].accuracy.giantsteps.acc1Correct)
  }' _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**All records for a specific SHA:**
```bash
jq -s --arg sha "a97bad2" '[.[] | select(.gitSHA == $sha)]' \
  _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**Noise floor — median of historical means:**
```bash
jq -rs '[.[].wallClock.meanSeconds] | sort | .[length/2|floor]' \
  _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**OA300 accuracy history as CSV (for plotting / eyeballing trends):**
```bash
for f in _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json; do
  jq -r '[.gitSHA, .recordedAt, .accuracy.oa300.acc1Correct, .accuracy.oa300.acc2Correct, .accuracy.oa300.total] | @csv' "$f"
done
```

**Regressions — any run where Acc1 dropped vs its predecessor:**
```bash
jq -rs 'sort_by(.recordedAt) | to_entries as $entries |
  $entries | map(select(.key > 0)) | map({
  sha: .value.gitSHA, recordedAt: .value.recordedAt,
  acc1_delta: (.value.accuracy.oa300.acc1Correct - $entries[.key - 1].value.accuracy.oa300.acc1Correct)
}) | map(select(.acc1_delta < 0))' _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

**Two-SHA comparison (both runs must exist as files):**
```bash
jq -s --arg a SHA1 --arg b SHA2 '[.[] | select(.gitSHA == $a or .gitSHA == $b)]' \
  _bmad-output/perf-baselines/Apple_M5_Max-26--Debug--*.json
```

If a SHA is missing, add it: `git checkout <sha> && make perf-benchmark && git checkout -`.

## Comparison workflow

**Pre- and post-change accuracy check (fast, no persistence):**

```bash
git log --oneline -1
make benchmark 2>&1 | grep -E "^Acc[12]:" | head -4
make benchmark-giantsteps 2>&1 | grep -E "^(Acc[12]:|Overall:)" | head -4
# make change, commit
make benchmark 2>&1 | grep -E "^Acc[12]:" | head -4
make benchmark-giantsteps 2>&1 | grep -E "^(Acc[12]:|Overall:)" | head -4
```

**Full regression check with perf persistence (~40s per side):**

```bash
make perf-benchmark               # writes record at HEAD
# ...make and commit change...
make perf-benchmark               # writes record at new HEAD; Δ line references prior run
```

Use the `jq` delta recipe above to compare the two records structurally.

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| `swift test --filter PerformanceBenchmarkTests` (no Makefile) | `PERF_BASELINE_DIR` and `GIT_SHA` are unset; no baseline is written, delta line is suppressed | Use `make perf-benchmark` always |
| `OA300_CORPUS_PATH= make benchmark` (empty string) | Fails loudly with `.corpusPathNotSet` (correct behavior, but wastes a run) | Unset the var (`unset OA300_CORPUS_PATH`) or set a real path |
| Running two `make perf-benchmark` concurrently on the same machine | Baselines persist correctly because filenames are unique-by-construction, but both runs' timing numbers are corrupted by CPU contention — the records look legitimate but are unreliable | Run serially |
| Deleting a per-run file without a commit message explaining why | Breaks the immutable-history invariant; future readers can't tell whether the record was bad or just inconvenient | Only delete a bad record in an explicit commit that cites the reason |
| Comparing Debug-mode and Release-mode records | Release is ~30-40% faster on Apple Silicon; any Debug↔Release diff includes a build-mode confound | Committed baselines are Debug-mode (current convention). The `{buildConfig}--` filename segment keeps Debug and Release file sets disjoint. |
| Using `make test` to verify a benchmark change | Unit target does not include the benchmark test target — zero benchmark coverage | Use `make benchmark` (accuracy) and/or `make perf-benchmark` (timing) |
| Running a benchmark with local uncommitted DSP changes and not noting `gitSHA` | Record's `gitSHA` is the last commit, not your WIP; future comparisons silently attribute WIP numbers to that SHA | Commit first, then `make perf-benchmark`; OR note WIP numbers out-of-band, don't persist |
| Running `make benchmark-giantsteps` before generating the corpus | Hits `GiantStepsError` on corpus missing | Point `GIANTSTEPS_CORPUS_PATH` to the checked-out `giantsteps-tempo-dataset` repo (the `audio/` subdir lives there) |

## Chip/OS fingerprinting

The reader filters files by the prefix `{fingerprint}--{buildConfig}--` so records from different machines are never mixed. The fingerprint is derived by:
1. Mapping each character of the chip brand string to itself (if letter, digit, `-`, or `_`) or to `_` (otherwise).
2. Collapsing consecutive `_` characters to a single `_`.
3. Appending `-{osMajor}` (e.g. `-26` for macOS 26).

This means `"Apple M5 Max"` → `Apple_M5_Max` and `"Intel(R) Core(TM) i9"` → `Intel_R_Core_TM_i9`. A Debug M5 Max run on macOS 26 produces fingerprint `Apple_M5_Max-26`.

## Editing the benchmark infrastructure

- Shared matchers: `Sources/BoomBoomBoomKitTestSupport/AccuracyMatchers.swift` — single source of truth for `isAcc1Match` (with zero-guard) and `isAcc2Match` (MIREX 5-factor). Editing these changes ALL accuracy numbers across OA300/GiantSteps/DAWOracle/Perf simultaneously.
- Shared corpus structs: `Sources/BoomBoomBoomKitTestSupport/CorpusTracks.swift` — public `OA300Track` / `GiantStepsTrack` / `DAWOracleTrack`. Adding optional fields is non-breaking (`Decodable` ignores unknown JSON keys).
- Benchmark test target: `Tests/BoomBoomBoomKitBenchmarkTests/`. All suites here follow the pattern: `@Suite("Name")` (no `.enabled(if:)`) + `init() throws { guard let path = ..., !path.isEmpty else { throw ... } }`. Do not re-introduce `.enabled(if:)` — target-level separation is the load-bearing gate.
- Baseline writer/reader: `Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift` — `BaselineStore.write` (temp-then-rename atomic publish) and `BaselineStore.readHistory` (glob-filter-sort). If you change the filename template, update `buildRecordFilename` and `readHistory`'s prefix filter together, then update the jq recipes in this skill doc.
- Ablation exception: `Tests/BoomBoomBoomKitBenchmarkTests/AblationFullMatrixTests.swift` keeps local `isAcc1Abl` / `isAcc2Abl` helpers with 2-factor Acc2 (`{1, 2, 1/2}`, no triplet). This is intentional — ablation measures technique effect size; triplet factors mask differences on DnB-heavy corpora. Do not switch ablation to the shared matchers.
