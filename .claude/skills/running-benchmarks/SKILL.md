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
| `make bnns-impact-report` | Per-track ML-vs-DSP impact snapshot + 7-bucket failure-stage histogram + corpus-distribution stats | ~50 s | stdout **and** `_bmad-output/perf-baselines/bnns-impact/<Chip>-<OSMajor>--<BuildConfig>--<recordedAt>--<gitSHA>--<uuid>.json` (schema v3 — see "bnns-impact-report JSON schema" below) | Bundled-model build: `ml_acc1 = 0/82` at production thresholds (Story 4-6 Branch C: model pulled, infra retained); BYOW builds produce a different distribution |

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

## bnns-impact-report JSON schema (v3)

The `make bnns-impact-report` target (Story 4-5 onward) writes a *different* record kind to a *sibling subdirectory* of `perf-baselines/`. It is NOT a wall-clock baseline — it is a per-run impact snapshot for the ML augmentation path, capturing per-track BPM decisions plus diagnostic + corpus-distribution stats. The two record kinds share the same filename template and write discipline but live in disjoint directories so the perf-baselines reader's prefix filter doesn't collide with impact records.

Output location: `_bmad-output/perf-baselines/bnns-impact/` (subdirectory of the canonical perf-baselines lane). Override the target dir with `BNNS_IMPACT_OUT_DIR=...`. Same filename template as perf-baselines records:

```
{fingerprint}--{buildConfig}--{recordedAt}--{gitSHA}--{shortUUID}.json
```

Full example: `Apple_M5_Max-26--Debug--20260515T034521Z--5e08319--abc12345.json`

The legacy story-tagged filenames (`4-5-bnns-impact-report.json`, `4-6-bnns-impact-report-sweep-0.10-0.02.json`, etc.) were retired when v3 schema landed — the threshold values and story tags move *inside* the file (as `applied_thresholds` and `pinned_config`), not into the filename. Per-run files are still immutable once published; a bad record may be deleted only with an explicit reason cited in the commit.

```json
{
  "schema_version": 3,
  "recorded_at": "2026-05-15T03:45:21Z",
  "git_sha": "5e08319",
  "build_configuration": "Debug",
  "swift_package_version": "BoomBoomBoomKit (workspace HEAD)",
  "hardware": {
    "chip": "Apple M5 Max", "cores": 18,
    "physical_memory_gib": 128, "os_version": "Version 26.5 (Build ...)"
  },
  "model_identifier": "bnns_tempo_v1",
  "pinned_config": { "intensity": 8, "ensemble_policy": "mlOnly" },
  "applied_thresholds": { "confidence": 0.5, "margin": 0.1 },
  "summary": {
    "total_tracks": 82,
    "dsp_acc1": 58, "ml_acc1": 0, "ensemble_acc1": 58,
    "named_dnb_resolved": 0, "named_dnb_resolved_via_dsp_fallback": 0,
    "named_dnb_total": 4,
    "dsp_correct_controls_preserved": 4, "dsp_correct_controls_total": 4
  },
  "named_dnb_track_results": [/* 4 rows: ensemble_winner_bpm, ground_truth_bpm, abs_error, resolved_within_05 */],
  "dsp_correct_control_results": [/* 4 rows: same shape, "did ML break what DSP got right?" preservation oracle */],
  "all_tracks": [/* 82 rows: per-track dsp_winner, ml_winner, ensemble_winner, ml_diagnostic_snapshot */],
  "failure_stage_histogram": { /* 7-bucket: noAbstain, featuresAbsent, featureVersionMismatch, featurizeRejected, graphFailed, decodeRejected, confidenceGateRejected */ },
  "corpus_distribution": {
    "wrong_non_abstain_count": 54, "decoded_bpm_total_count": 82,
    "decoded_bpm_histogram_5bpm_bins": [/* 28 bins */],
    "decoded_bpm_in_range_fraction": 1.0,
    "decoded_bpm_matches_dsp_within_4pct_fraction": 0.049,
    "softmax_max_p50": 0.085, "softmax_max_p95": 0.294,
    "softmax_margin_p50": 0.010, "softmax_margin_p95": 0.051,
    "input_feature_checksum_unique_count": 82
  }
}
```

Threshold-sweep workflow: invoke `make bnns-impact-report` multiple times with different `BNNS_THRESHOLD_OVERRIDE_CONFIDENCE` / `BNNS_THRESHOLD_OVERRIDE_MARGIN` env vars. Each run produces one canonical file with its own `recorded_at` + UUID. Compare across runs by reading the `applied_thresholds` field — no out-of-band sweep summary JSON is needed because the data lives in the files themselves.

### Multi-run sweep without `-dirty` self-contamination

A subtle gotcha: the Makefile's `GIT_SHA` detection runs `git status --porcelain` before each invocation and appends `-dirty` to the SHA in the filename if the working tree has any uncommitted state. When you run a multi-point threshold sweep against the canonical output directory, the FIRST run produces an untracked JSON file under `_bmad-output/perf-baselines/bnns-impact/` — the working tree is no longer clean from that point on, so every subsequent run in the sweep tags itself `-dirty` even though the underlying source SHA is unchanged. The first record has a clean SHA, the rest don't.

**The right pattern: redirect output to `/tmp/` for the duration of the sweep, then move the files in atomically at the end.**

```bash
# 1. Verify the working tree is clean before starting.
git status --porcelain  # must print nothing

# 2. Stage all the runs to a temp dir so the working tree stays clean.
mkdir -p /tmp/bnns-impact-fresh
for pair in "0.50 0.10" "0.00 0.00" "0.10 0.02" "0.20 0.04" "0.30 0.05" "0.40 0.08" "0.65 0.20"; do
  read conf margin <<< "$pair"
  if [ "$conf" = "0.50" ]; then
    # The default-threshold run skips the override env vars entirely so it
    # records production defaults in `applied_thresholds`.
    BNNS_MODEL_URL="$(pwd)/_bmad-output/ml-models/giantsteps_v1.mlmodelc" \
    BNNS_IMPACT_OUT_DIR=/tmp/bnns-impact-fresh \
      make bnns-impact-report
  else
    BNNS_MODEL_URL="$(pwd)/_bmad-output/ml-models/giantsteps_v1.mlmodelc" \
    BNNS_IMPACT_OUT_DIR=/tmp/bnns-impact-fresh \
    BNNS_THRESHOLD_OVERRIDE_CONFIDENCE="$conf" \
    BNNS_THRESHOLD_OVERRIDE_MARGIN="$margin" \
      make bnns-impact-report
  fi
done

# 3. Confirm every captured file has a clean SHA (no `-dirty` substring).
ls /tmp/bnns-impact-fresh/

# 4. Move them all into the canonical location at once.
mv /tmp/bnns-impact-fresh/*.json _bmad-output/perf-baselines/bnns-impact/

# 5. Stage and commit. The next sweep will start from a clean tree again.
git add _bmad-output/perf-baselines/bnns-impact/
git commit -m "Story X-Y: regenerate bnns-impact baselines at post-fix SHA"
```

Same principle applies to `make perf-benchmark` and any other corpus-gated benchmark that writes to `_bmad-output/perf-baselines/`: if you're doing a multi-run capture, write the runs to `/tmp/` first, then move them in. Single-run captures don't need the temp redirect.

`BNNS_MODEL_URL` (the BYOW seam introduced by Story 4-6) lets the impact-report harness load the develop-only `_bmad-output/ml-models/giantsteps_v1.mlmodelc/` model when no bundle ships from `Sources/`. Story 4-6's Branch C close-out pulled the bundle from `main`; the develop-only copy at `_bmad-output/ml-models/` is what makes baseline regeneration reproducible on `develop` without re-bundling.

**jq recipe — show all impact runs at SHA `5e08319` sorted by `confidence` threshold (sweep review):**
```bash
jq -s --arg sha "5e08319" '[.[] | select(.git_sha == $sha)] |
  sort_by(.applied_thresholds.confidence) |
  map({ thresholds: .applied_thresholds, summary: .summary, recorded: .recorded_at })' \
  _bmad-output/perf-baselines/bnns-impact/Apple_M5_Max-26--Debug--*.json
```

**jq recipe — most recent default-threshold (`confidence=0.5`, `margin=0.1`) run:**
```bash
jq -s 'map(select(.applied_thresholds.confidence == 0.5 and .applied_thresholds.margin == 0.1)) |
  sort_by(.recorded_at) | last' \
  _bmad-output/perf-baselines/bnns-impact/Apple_M5_Max-26--Debug--*.json
```

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
