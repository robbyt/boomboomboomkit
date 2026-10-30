# Story 15.9 evaluation summary (4c88e71f0cf7eeff41e11dfd42c674b4eb18d4ee)

Git 4c88e71f0cf7eeff41e11dfd42c674b4eb18d4ee, tracked changes present: no. Swift runner build: release -Xswiftc -enable-testing. Produced by `make matched-eval`; per-track rows stay in the gitignored run directory. This file holds aggregates only.

## How to read this

- Systems:
  - `boomboomboomkit-optimal`: AudioAnalysisService.analyze(url:) at default options (TechniqueSet.optimal); grid = beat-grid tempo extrapolated from gridOrigin.
  - `variant-joint-fit`: Story 15.7: DSP stub observations -> metrical level selection seeded with the default BPM -> joint tempo and phase fit, on the default pass's decode; a nil at any step abstains.
  - `variant-comb-best-phase`: Story 15.10 follow-up: the default grid re-anchored at the onset-comb best phase (internal BeatGridAnalyzer hook); BPM answer unchanged from the default.
  - `variant-fixed-time`: Story 15.5 fixed-time model, BPM read from its scores files; tempo families only; Python inference, so runtime and memory are not comparable with the Swift rows.
  - `commercial-analyzer`: a commercial DJ analyzer's BPM as recorded in the OA300 label file; version unrecorded, analysis mode unrecorded; no grid; OA300 only; a system under test, never the reference.
  - `oracle`: the corpus's independent reference.
- A pairing whose right-hand system is `oracle` is labelled system-vs-reference; every other pairing, including the library against `commercial-analyzer`, is system-vs-system. Agreement with `commercial-analyzer` says nothing about correctness.
- GiantSteps labels are crowdsourced; every GiantSteps pairing carries the tag crowdsourced-reference.
- Metric families stay separate. Strict tempo at [0.1, 0.05, 0.02] BPM; level classes within 4% of 1, 1/2, 2, 2/3 and 3/2; beat window 70 ms.
- Paired differences are a minus b. Interval: percentile 2.5 and 97.5 of the resampled medians of paired differences, 10000 resamples, seed 20261030. p: scipy.stats.wilcoxon, two-sided, zero differences dropped.
- A stratum with n below 10 is underpowered and gets no direction. A direction is the sign of the median paired difference, stated only when the interval excludes zero, with its pairing, n, interval and p beside it.
- Families 4 to 7 (grid phase, beat precision, recall and F, downbeat phase, drift) need a Story 15.8 hand annotation; a track without one reports no-reference and is left out of those pairings.
- Memory: task_info MACH_TASK_BASIC_INFO resident_size, sampled every 1 ms on a second thread while each pass runs; value = high-water mark minus the resident size just before the pass.

## eval-12-7

n = 172; reference: verified-12.7 (`bundle-gate-input-seed-42.json`, sha256 bb3accfefb59dbdf...); hand-annotated tracks: 0.

### Per-system results, all tracks

| system | outcomes | level same | strict 0.10 | strict 0.05 | strict 0.02 | median abs error BPM | median abs error ppt | median runtime s | median peak memory MB | grid families |
|---|---|---|---|---|---|---|---|---|---|---|
| `boomboomboomkit-optimal` | ok 172 | 0.855 (n 172) | 0.628 (n 172) | 0.599 (n 172) | 0.570 (n 172) | 0 | 0 | 0.2161 | 40.39 | no-reference 172 |
| `variant-joint-fit` | abstained 40, ok 132 | 0.212 (n 132) | 0.197 (n 132) | 0.197 (n 132) | 0.174 (n 132) | 140 | 1000 | 0.2727 | 40.39 | no-reference 172 |
| `variant-comb-best-phase` | ok 172 | 0.855 (n 172) | 0.628 (n 172) | 0.599 (n 172) | 0.570 (n 172) | 0 | 0 | 0.2163 | 40.38 | no-reference 172 |
| `variant-fixed-time` | ok 172 | 0.919 (n 172) | 0.488 (n 172) | 0.488 (n 172) | 0.483 (n 172) | 0.485 | 3.689 | - | - | no-reference 172 |
| `commercial-analyzer` | not-run 172 | - | - | - | - | - | - | - | - | no-reference 172 |
| `oracle` | reference 172 | 1.000 (n 172) | 1.000 (n 172) | 1.000 (n 172) | 1.000 (n 172) | 0 | 0 | - | - | no-reference 172 |

### By tempo band

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| 110-129 | 12 | no | `boomboomboomkit-optimal` | 0.917 (n 12) | 0.333 (n 12) | 0.2307 |
| 110-129 | 12 | no | `variant-joint-fit` | 0.286 (n 7) | 0.286 (n 7) | 123.4 |
| 110-129 | 12 | no | `variant-comb-best-phase` | 0.917 (n 12) | 0.333 (n 12) | 0.2307 |
| 110-129 | 12 | no | `variant-fixed-time` | 0.917 (n 12) | 0.667 (n 12) | 0.005 |
| 130-149 | 61 | no | `boomboomboomkit-optimal` | 0.787 (n 61) | 0.557 (n 61) | 0.01 |
| 130-149 | 61 | no | `variant-joint-fit` | 0.231 (n 39) | 0.231 (n 39) | 130 |
| 130-149 | 61 | no | `variant-comb-best-phase` | 0.787 (n 61) | 0.557 (n 61) | 0.01 |
| 130-149 | 61 | no | `variant-fixed-time` | 0.902 (n 61) | 0.639 (n 61) | 0 |
| 150-179 | 99 | no | `boomboomboomkit-optimal` | 0.889 (n 99) | 0.657 (n 99) | 0 |
| 150-179 | 99 | no | `variant-joint-fit` | 0.198 (n 86) | 0.174 (n 86) | 170 |
| 150-179 | 99 | no | `variant-comb-best-phase` | 0.889 (n 99) | 0.657 (n 99) | 0 |
| 150-179 | 99 | no | `variant-fixed-time` | 0.929 (n 99) | 0.374 (n 99) | 1 |

### By style tag

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| untagged | 172 | no | `boomboomboomkit-optimal` | 0.855 (n 172) | 0.599 (n 172) | 0 |
| untagged | 172 | no | `variant-joint-fit` | 0.212 (n 132) | 0.197 (n 132) | 140 |
| untagged | 172 | no | `variant-comb-best-phase` | 0.855 (n 172) | 0.599 (n 172) | 0 |
| untagged | 172 | no | `variant-fixed-time` | 0.919 (n 172) | 0.488 (n 172) | 0.485 |

### Paired differences, all tracks

#### `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 132 | 1 | [1, 1] | 6.93e-23 | yes |
| strict_0.10 | 132 | 1 | [1, 1] | 1.47e-15 | yes |
| strict_0.05 | 132 | 1 | [0.5, 1] | 2.21e-14 | yes |
| strict_0.02 | 132 | 1 | [0, 1] | 5.94e-14 | no |
| error_bpm | 132 | -140 | [-150.2, -130] | 5.09e-15 | yes |
| abs_error_bpm | 132 | -140 | [-150, -130] | 2.89e-21 | yes |
| error_ppt | 132 | -999.9 | [-1000, -998.1] | 5.38e-15 | yes |
| abs_error_ppt | 132 | -999.8 | [-999.9, -996.6] | 2.95e-21 | yes |
| failed_or_abstained | 172 | 0 | [0, 0] | 2.54e-10 | no |
| runtime_s | 172 | -0.0562 | [-0.05641, -0.05609] | 5.62e-30 | yes |
| peak_memory_bytes | 172 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 1 | no |
| strict_0.10 | 172 | 0 | [0, 0] | 1 | no |
| strict_0.05 | 172 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 172 | 0 | [0, 0] | 1 | no |
| error_bpm | 172 | 0 | [0, 0] | 1 | no |
| abs_error_bpm | 172 | 0 | [0, 0] | 1 | no |
| error_ppt | 172 | 0 | [0, 0] | 1 | no |
| abs_error_ppt | 172 | 0 | [0, 0] | 1 | no |
| failed_or_abstained | 172 | 0 | [0, 0] | 1 | no |
| runtime_s | 172 | -0.0001331 | [-0.0002974, 5.963e-05] | 0.336 | no |
| peak_memory_bytes | 172 | 1.638e+04 | [1.638e+04, 1.638e+04] | 2.43e-31 | yes |

#### `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 0.0482 | no |
| strict_0.10 | 172 | 0 | [0, 0] | 0.00527 | no |
| strict_0.05 | 172 | 0 | [0, 0] | 0.0262 | no |
| strict_0.02 | 172 | 0 | [0, 0] | 0.0874 | no |
| error_bpm | 172 | 0 | [0, 0.2451] | 0.000677 | no |
| abs_error_bpm | 172 | 0 | [0, 0] | 0.262 | no |
| error_ppt | 172 | 0 | [0, 1.813] | 0.001 | no |
| abs_error_ppt | 172 | 0 | [0, 0] | 0.318 | no |
| failed_or_abstained | 172 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 5.73e-07 | no |
| strict_0.10 | 172 | 0 | [0, 0] | 1.24e-15 | no |
| strict_0.05 | 172 | 0 | [0, 0] | 9.85e-17 | no |
| strict_0.02 | 172 | 0 | [-1, 0] | 7.81e-18 | no |
| error_bpm | 172 | 0 | [0, 0] | 0.65 | no |
| abs_error_bpm | 172 | 0 | [0, 0.02278] | 2.45e-15 | no |
| error_ppt | 172 | 0 | [0, 0] | 0.546 | no |
| abs_error_ppt | 172 | 0 | [0, 0.1704] | 2.5e-15 | no |

#### `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 132 | -1 | [-1, -1] | 6.93e-23 | yes |
| strict_0.10 | 132 | -1 | [-1, -1] | 1.47e-15 | yes |
| strict_0.05 | 132 | -1 | [-1, -0.5] | 2.21e-14 | yes |
| strict_0.02 | 132 | -1 | [-1, 0] | 5.94e-14 | no |
| error_bpm | 132 | 140 | [130, 150.2] | 5.09e-15 | yes |
| abs_error_bpm | 132 | 140 | [130, 150] | 2.89e-21 | yes |
| error_ppt | 132 | 999.9 | [998.1, 1000] | 5.38e-15 | yes |
| abs_error_ppt | 132 | 999.8 | [997.1, 999.9] | 2.95e-21 | yes |
| failed_or_abstained | 172 | 0 | [0, 0] | 2.54e-10 | no |
| runtime_s | 172 | 0.05614 | [0.05575, 0.05651] | 5.62e-30 | yes |
| peak_memory_bytes | 172 | 1.638e+04 | [1.638e+04, 1.638e+04] | 2.43e-31 | yes |

#### `variant-joint-fit` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 132 | -1 | [-1, -1] | 2.9e-21 | yes |
| strict_0.10 | 132 | 0 | [0, 0] | 3.14e-06 | no |
| strict_0.05 | 132 | 0 | [0, 0] | 3.14e-06 | no |
| strict_0.02 | 132 | 0 | [0, 0] | 1.32e-06 | no |
| error_bpm | 132 | 140 | [130, 151.5] | 5.35e-17 | yes |
| abs_error_bpm | 132 | 140 | [130, 149.5] | 3.94e-20 | yes |
| error_ppt | 132 | 1000 | [996.6, 1000] | 5.25e-17 | yes |
| abs_error_ppt | 132 | 994.2 | [993.4, 994.3] | 3.7e-20 | yes |
| failed_or_abstained | 172 | 0 | [0, 0] | 2.54e-10 | no |

#### `variant-joint-fit` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 132 | -1 | [-1, -1] | 2.02e-24 | yes |
| strict_0.10 | 132 | -1 | [-1, -1] | 7.37e-25 | yes |
| strict_0.05 | 132 | -1 | [-1, -1] | 7.37e-25 | yes |
| strict_0.02 | 132 | -1 | [-1, -1] | 1.62e-25 | yes |
| error_bpm | 132 | 140 | [130, 150] | 3.94e-16 | yes |
| abs_error_bpm | 132 | 140 | [130, 150] | 2.09e-23 | yes |
| error_ppt | 132 | 1000 | [999.9, 1000] | 3.33e-16 | yes |
| abs_error_ppt | 132 | 1000 | [999.9, 1000] | 2.09e-23 | yes |

#### `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 0.0482 | no |
| strict_0.10 | 172 | 0 | [0, 0] | 0.00527 | no |
| strict_0.05 | 172 | 0 | [0, 0] | 0.0262 | no |
| strict_0.02 | 172 | 0 | [0, 0] | 0.0874 | no |
| error_bpm | 172 | 0 | [0, 0.2407] | 0.000677 | no |
| abs_error_bpm | 172 | 0 | [0, 0] | 0.262 | no |
| error_ppt | 172 | 0 | [0, 1.813] | 0.001 | no |
| abs_error_ppt | 172 | 0 | [0, 0] | 0.318 | no |
| failed_or_abstained | 172 | 0 | [0, 0] | 1 | no |

#### `variant-comb-best-phase` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 5.73e-07 | no |
| strict_0.10 | 172 | 0 | [0, 0] | 1.24e-15 | no |
| strict_0.05 | 172 | 0 | [0, 0] | 9.85e-17 | no |
| strict_0.02 | 172 | 0 | [-1, 0] | 7.81e-18 | no |
| error_bpm | 172 | 0 | [0, 0] | 0.65 | no |
| abs_error_bpm | 172 | 0 | [0, 0.02372] | 2.45e-15 | no |
| error_ppt | 172 | 0 | [0, 0] | 0.546 | no |
| abs_error_ppt | 172 | 0 | [0, 0.1675] | 2.5e-15 | no |

#### `variant-fixed-time` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 172 | 0 | [0, 0] | 0.000183 | no |
| strict_0.10 | 172 | -1 | [-1, 0] | 6.55e-21 | no |
| strict_0.05 | 172 | -1 | [-1, 0] | 6.55e-21 | no |
| strict_0.02 | 172 | -1 | [-1, 0] | 3.95e-21 | no |
| error_bpm | 172 | 0 | [-0.005, 0] | 4.87e-08 | no |
| abs_error_bpm | 172 | 0.485 | [0, 1] | 2.58e-18 | no |
| error_ppt | 172 | 0 | [0, 0] | 1.32e-06 | no |
| abs_error_ppt | 172 | 3.689 | [0, 5.714] | 7.88e-18 | no |

### Directions stated (all tracks)

- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), level_same: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is above zero: 1, n = 132, 95 % interval [1, 1], Wilcoxon p = 6.93e-23.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), strict_0.10: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is above zero: 1, n = 132, 95 % interval [1, 1], Wilcoxon p = 1.47e-15.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), strict_0.05: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is above zero: 1, n = 132, 95 % interval [0.5, 1], Wilcoxon p = 2.21e-14.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -140.001, n = 132, 95 % interval [-150.156, -130.004], Wilcoxon p = 5.09e-15.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -140.001, n = 132, 95 % interval [-150, -130.001], Wilcoxon p = 2.89e-21.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -999.916, n = 132, 95 % interval [-999.959, -998.129], Wilcoxon p = 5.38e-15.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -999.81, n = 132, 95 % interval [-999.938, -996.57], Wilcoxon p = 2.95e-21.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), runtime_s: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -0.0561988, n = 172, 95 % interval [-0.0564098, -0.0560855], Wilcoxon p = 5.62e-30.
- eval-12-7, `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system), peak_memory_bytes: the median paired difference (boomboomboomkit-optimal minus variant-comb-best-phase) is above zero: 16384, n = 172, 95 % interval [16384, 16384], Wilcoxon p = 2.43e-31.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), level_same: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 6.93e-23.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), strict_0.10: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 1.47e-15.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), strict_0.05: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is below zero: -1, n = 132, 95 % interval [-1, -0.5], Wilcoxon p = 2.21e-14.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), error_bpm: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 140.001, n = 132, 95 % interval [130.001, 150.156], Wilcoxon p = 5.09e-15.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 140.001, n = 132, 95 % interval [130.001, 149.998], Wilcoxon p = 2.89e-21.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), error_ppt: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 999.916, n = 132, 95 % interval [998.129, 999.959], Wilcoxon p = 5.38e-15.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 999.81, n = 132, 95 % interval [997.066, 999.939], Wilcoxon p = 2.95e-21.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), runtime_s: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 0.0561403, n = 172, 95 % interval [0.0557464, 0.0565094], Wilcoxon p = 5.62e-30.
- eval-12-7, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), peak_memory_bytes: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 16384, n = 172, 95 % interval [16384, 16384], Wilcoxon p = 2.43e-31.
- eval-12-7, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), level_same: the median paired difference (variant-joint-fit minus variant-fixed-time) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 2.9e-21.
- eval-12-7, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), error_bpm: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 139.998, n = 132, 95 % interval [130.001, 151.513], Wilcoxon p = 5.35e-17.
- eval-12-7, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 139.994, n = 132, 95 % interval [129.998, 149.499], Wilcoxon p = 3.94e-20.
- eval-12-7, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), error_ppt: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 999.958, n = 132, 95 % interval [996.571, 999.996], Wilcoxon p = 5.25e-17.
- eval-12-7, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 994.234, n = 132, 95 % interval [993.352, 994.282], Wilcoxon p = 3.7e-20.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), level_same: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 2.02e-24.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.10: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 7.37e-25.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.05: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 7.37e-25.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.02: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 132, 95 % interval [-1, -1], Wilcoxon p = 1.62e-25.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), error_bpm: the median paired difference (variant-joint-fit minus oracle) is above zero: 140.001, n = 132, 95 % interval [130.001, 150.004], Wilcoxon p = 3.94e-16.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), abs_error_bpm: the median paired difference (variant-joint-fit minus oracle) is above zero: 140.001, n = 132, 95 % interval [130.001, 150.006], Wilcoxon p = 2.09e-23.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), error_ppt: the median paired difference (variant-joint-fit minus oracle) is above zero: 999.954, n = 132, 95 % interval [999.921, 999.972], Wilcoxon p = 3.33e-16.
- eval-12-7, `variant-joint-fit` vs `oracle` (system-vs-reference), abs_error_ppt: the median paired difference (variant-joint-fit minus oracle) is above zero: 999.954, n = 132, 95 % interval [999.921, 999.972], Wilcoxon p = 2.09e-23.

Stratified pairings, each with n, interval, p and a direction only where the stratum is not underpowered, are in the JSON aggregate.

## giantsteps

n = 661; reference: crowdsourced-reference (`giantsteps-tempo-ground-truth.json`, sha256 3dc6f3759f9a6739...); tag crowdsourced-reference; hand-annotated tracks: 0.

### Per-system results, all tracks

| system | outcomes | level same | strict 0.10 | strict 0.05 | strict 0.02 | median abs error BPM | median abs error ppt | median runtime s | median peak memory MB | grid families |
|---|---|---|---|---|---|---|---|---|---|---|
| `boomboomboomkit-optimal` | ok 661 | 0.723 (n 661) | 0.071 (n 661) | 0.048 (n 661) | 0.014 (n 661) | 1.192 | 8.61 | 0.1963 | 40.39 | no-reference 661 |
| `variant-joint-fit` | abstained 243, ok 418 | 0.148 (n 418) | 0.048 (n 418) | 0.048 (n 418) | 0.043 (n 418) | 138 | 999.9 | 0.2531 | 40.39 | no-reference 661 |
| `variant-comb-best-phase` | ok 661 | 0.723 (n 661) | 0.071 (n 661) | 0.048 (n 661) | 0.014 (n 661) | 1.192 | 8.61 | 0.1964 | 40.38 | no-reference 661 |
| `variant-fixed-time` | ok 661 | 0.828 (n 661) | 0.263 (n 661) | 0.263 (n 661) | 0.263 (n 661) | 1 | 7.194 | - | - | no-reference 661 |
| `commercial-analyzer` | not-run 661 | - | - | - | - | - | - | - | - | no-reference 661 |
| `oracle` | reference 661 | 1.000 (n 661) | 1.000 (n 661) | 1.000 (n 661) | 1.000 (n 661) | 0 | 0 | - | - | no-reference 661 |

### By tempo band

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| 60-89 | 50 | no | `boomboomboomkit-optimal` | 0.000 (n 50) | 0.000 (n 50) | 84.96 |
| 60-89 | 50 | no | `variant-joint-fit` | 0.069 (n 29) | 0.000 (n 29) | 240 |
| 60-89 | 50 | no | `variant-comb-best-phase` | 0.000 (n 50) | 0.000 (n 50) | 84.96 |
| 60-89 | 50 | no | `variant-fixed-time` | 0.120 (n 50) | 0.080 (n 50) | 80.5 |
| 90-109 | 18 | no | `boomboomboomkit-optimal` | 0.222 (n 18) | 0.000 (n 18) | 90.08 |
| 90-109 | 18 | no | `variant-joint-fit` | 0.250 (n 4) | 0.000 (n 4) | 92 |
| 90-109 | 18 | no | `variant-comb-best-phase` | 0.222 (n 18) | 0.000 (n 18) | 90.08 |
| 90-109 | 18 | no | `variant-fixed-time` | 0.556 (n 18) | 0.389 (n 18) | 2.5 |
| 110-129 | 177 | no | `boomboomboomkit-optimal` | 0.706 (n 177) | 0.045 (n 177) | 1.072 |
| 110-129 | 177 | no | `variant-joint-fit` | 0.233 (n 120) | 0.092 (n 120) | 119 |
| 110-129 | 177 | no | `variant-comb-best-phase` | 0.706 (n 177) | 0.045 (n 177) | 1.072 |
| 110-129 | 177 | no | `variant-fixed-time` | 0.921 (n 177) | 0.169 (n 177) | 1 |
| 130-149 | 234 | no | `boomboomboomkit-optimal` | 0.761 (n 234) | 0.034 (n 234) | 1.107 |
| 130-149 | 234 | no | `variant-joint-fit` | 0.116 (n 146) | 0.014 (n 146) | 141 |
| 130-149 | 234 | no | `variant-comb-best-phase` | 0.761 (n 234) | 0.034 (n 234) | 1.107 |
| 130-149 | 234 | no | `variant-fixed-time` | 0.944 (n 234) | 0.179 (n 234) | 1 |
| 150-179 | 176 | no | `boomboomboomkit-optimal` | 0.938 (n 176) | 0.091 (n 176) | 1.026 |
| 150-179 | 176 | no | `variant-joint-fit` | 0.104 (n 115) | 0.061 (n 115) | 170 |
| 150-179 | 176 | no | `variant-comb-best-phase` | 0.938 (n 176) | 0.091 (n 176) | 1.026 |
| 150-179 | 176 | no | `variant-fixed-time` | 0.835 (n 176) | 0.517 (n 176) | 0 |
| 180-210 | 6 | yes | `boomboomboomkit-optimal` | 1.000 (n 6) | 0.000 (n 6) | 2.823 |
| 180-210 | 6 | yes | `variant-joint-fit` | 0.500 (n 4) | 0.000 (n 4) | 95 |
| 180-210 | 6 | yes | `variant-comb-best-phase` | 1.000 (n 6) | 0.000 (n 6) | 2.823 |
| 180-210 | 6 | yes | `variant-fixed-time` | 0.000 (n 6) | 0.000 (n 6) | 96 |

### By style tag

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| breaks | 26 | no | `boomboomboomkit-optimal` | 0.769 (n 26) | 0.000 (n 26) | 1.246 |
| breaks | 26 | no | `variant-joint-fit` | 0.000 (n 14) | 0.000 (n 14) | 140 |
| breaks | 26 | no | `variant-comb-best-phase` | 0.769 (n 26) | 0.000 (n 26) | 1.246 |
| breaks | 26 | no | `variant-fixed-time` | 1.000 (n 26) | 0.231 (n 26) | 1 |
| chill-out | 15 | no | `boomboomboomkit-optimal` | 0.533 (n 15) | 0.000 (n 15) | 1.457 |
| chill-out | 15 | no | `variant-joint-fit` | 0.200 (n 10) | 0.000 (n 10) | 132.5 |
| chill-out | 15 | no | `variant-comb-best-phase` | 0.533 (n 15) | 0.000 (n 15) | 1.457 |
| chill-out | 15 | no | `variant-fixed-time` | 0.467 (n 15) | 0.133 (n 15) | 31 |
| deep-house | 24 | no | `boomboomboomkit-optimal` | 0.958 (n 24) | 0.042 (n 24) | 0.974 |
| deep-house | 24 | no | `variant-joint-fit` | 0.375 (n 24) | 0.083 (n 24) | 119 |
| deep-house | 24 | no | `variant-comb-best-phase` | 0.958 (n 24) | 0.042 (n 24) | 0.974 |
| deep-house | 24 | no | `variant-fixed-time` | 0.875 (n 24) | 0.167 (n 24) | 1 |
| dj-tools | 8 | yes | `boomboomboomkit-optimal` | 0.250 (n 8) | 0.000 (n 8) | 35.83 |
| dj-tools | 8 | yes | `variant-joint-fit` | 0.000 (n 1) | 0.000 (n 1) | 48.25 |
| dj-tools | 8 | yes | `variant-comb-best-phase` | 0.250 (n 8) | 0.000 (n 8) | 35.83 |
| dj-tools | 8 | yes | `variant-fixed-time` | 0.875 (n 8) | 0.000 (n 8) | 1 |
| drum-and-bass | 139 | no | `boomboomboomkit-optimal` | 0.835 (n 139) | 0.094 (n 139) | 1.171 |
| drum-and-bass | 139 | no | `variant-joint-fit` | 0.099 (n 91) | 0.055 (n 91) | 172 |
| drum-and-bass | 139 | no | `variant-comb-best-phase` | 0.835 (n 139) | 0.094 (n 139) | 1.171 |
| drum-and-bass | 139 | no | `variant-fixed-time` | 0.784 (n 139) | 0.504 (n 139) | 0 |
| dubstep | 76 | no | `boomboomboomkit-optimal` | 0.671 (n 76) | 0.026 (n 76) | 1.895 |
| dubstep | 76 | no | `variant-joint-fit` | 0.163 (n 43) | 0.047 (n 43) | 139 |
| dubstep | 76 | no | `variant-comb-best-phase` | 0.671 (n 76) | 0.026 (n 76) | 1.895 |
| dubstep | 76 | no | `variant-fixed-time` | 0.750 (n 76) | 0.224 (n 76) | 1 |
| electro-house | 22 | no | `boomboomboomkit-optimal` | 0.545 (n 22) | 0.045 (n 22) | 1.802 |
| electro-house | 22 | no | `variant-joint-fit` | 0.000 (n 7) | 0.000 (n 7) | 127 |
| electro-house | 22 | no | `variant-comb-best-phase` | 0.545 (n 22) | 0.045 (n 22) | 1.802 |
| electro-house | 22 | no | `variant-fixed-time` | 0.727 (n 22) | 0.136 (n 22) | 1 |
| electronica | 52 | no | `boomboomboomkit-optimal` | 0.577 (n 52) | 0.019 (n 52) | 1.991 |
| electronica | 52 | no | `variant-joint-fit` | 0.033 (n 30) | 0.000 (n 30) | 133 |
| electronica | 52 | no | `variant-comb-best-phase` | 0.577 (n 52) | 0.019 (n 52) | 1.991 |
| electronica | 52 | no | `variant-fixed-time` | 0.654 (n 52) | 0.154 (n 52) | 1 |
| funk-r-and-b | 1 | yes | `boomboomboomkit-optimal` | 1.000 (n 1) | 0.000 (n 1) | 1.25 |
| funk-r-and-b | 1 | yes | `variant-comb-best-phase` | 1.000 (n 1) | 0.000 (n 1) | 1.25 |
| funk-r-and-b | 1 | yes | `variant-fixed-time` | 1.000 (n 1) | 0.000 (n 1) | 1 |
| glitch-hop | 17 | no | `boomboomboomkit-optimal` | 0.471 (n 17) | 0.059 (n 17) | 28.04 |
| glitch-hop | 17 | no | `variant-joint-fit` | 0.333 (n 9) | 0.222 (n 9) | 90 |
| glitch-hop | 17 | no | `variant-comb-best-phase` | 0.471 (n 17) | 0.059 (n 17) | 28.04 |
| glitch-hop | 17 | no | `variant-fixed-time` | 0.765 (n 17) | 0.412 (n 17) | 2 |
| hard-dance | 8 | yes | `boomboomboomkit-optimal` | 0.875 (n 8) | 0.000 (n 8) | 1.573 |
| hard-dance | 8 | yes | `variant-joint-fit` | 0.000 (n 7) | 0.000 (n 7) | 146 |
| hard-dance | 8 | yes | `variant-comb-best-phase` | 0.875 (n 8) | 0.000 (n 8) | 1.573 |
| hard-dance | 8 | yes | `variant-fixed-time` | 0.875 (n 8) | 0.000 (n 8) | 1 |
| hardcore-hard-techno | 14 | no | `boomboomboomkit-optimal` | 0.929 (n 14) | 0.000 (n 14) | 1.443 |
| hardcore-hard-techno | 14 | no | `variant-joint-fit` | 0.222 (n 9) | 0.000 (n 9) | 170 |
| hardcore-hard-techno | 14 | no | `variant-comb-best-phase` | 0.929 (n 14) | 0.000 (n 14) | 1.443 |
| hardcore-hard-techno | 14 | no | `variant-fixed-time` | 0.714 (n 14) | 0.429 (n 14) | 1 |
| hip-hop | 2 | yes | `boomboomboomkit-optimal` | 0.500 (n 2) | 0.000 (n 2) | 24.06 |
| hip-hop | 2 | yes | `variant-comb-best-phase` | 0.500 (n 2) | 0.000 (n 2) | 24.06 |
| hip-hop | 2 | yes | `variant-fixed-time` | 0.500 (n 2) | 0.000 (n 2) | 38.5 |
| house | 23 | no | `boomboomboomkit-optimal` | 0.478 (n 23) | 0.000 (n 23) | 38 |
| house | 23 | no | `variant-joint-fit` | 0.333 (n 9) | 0.111 (n 9) | 123 |
| house | 23 | no | `variant-comb-best-phase` | 0.478 (n 23) | 0.000 (n 23) | 38 |
| house | 23 | no | `variant-fixed-time` | 1.000 (n 23) | 0.304 (n 23) | 1 |
| indie-dance-nu-disco | 11 | no | `boomboomboomkit-optimal` | 0.273 (n 11) | 0.000 (n 11) | 77.95 |
| indie-dance-nu-disco | 11 | no | `variant-joint-fit` | 0.250 (n 4) | 0.250 (n 4) | 70.74 |
| indie-dance-nu-disco | 11 | no | `variant-comb-best-phase` | 0.273 (n 11) | 0.000 (n 11) | 77.95 |
| indie-dance-nu-disco | 11 | no | `variant-fixed-time` | 0.364 (n 11) | 0.182 (n 11) | 7 |
| minimal | 8 | yes | `boomboomboomkit-optimal` | 0.875 (n 8) | 0.000 (n 8) | 1.003 |
| minimal | 8 | yes | `variant-joint-fit` | 0.333 (n 6) | 0.167 (n 6) | 118.6 |
| minimal | 8 | yes | `variant-comb-best-phase` | 0.875 (n 8) | 0.000 (n 8) | 1.003 |
| minimal | 8 | yes | `variant-fixed-time` | 1.000 (n 8) | 0.125 (n 8) | 1 |
| pop-rock | 3 | yes | `boomboomboomkit-optimal` | 0.667 (n 3) | 0.000 (n 3) | 0.6677 |
| pop-rock | 3 | yes | `variant-joint-fit` | 0.000 (n 1) | 0.000 (n 1) | 127 |
| pop-rock | 3 | yes | `variant-comb-best-phase` | 0.667 (n 3) | 0.000 (n 3) | 0.6677 |
| pop-rock | 3 | yes | `variant-fixed-time` | 0.333 (n 3) | 0.000 (n 3) | 77 |
| progressive-house | 19 | no | `boomboomboomkit-optimal` | 0.579 (n 19) | 0.000 (n 19) | 1.164 |
| progressive-house | 19 | no | `variant-joint-fit` | 0.000 (n 9) | 0.000 (n 9) | 125 |
| progressive-house | 19 | no | `variant-comb-best-phase` | 0.579 (n 19) | 0.000 (n 19) | 1.164 |
| progressive-house | 19 | no | `variant-fixed-time` | 0.895 (n 19) | 0.211 (n 19) | 1 |
| psy-trance | 34 | no | `boomboomboomkit-optimal` | 0.941 (n 34) | 0.118 (n 34) | 0.8817 |
| psy-trance | 34 | no | `variant-joint-fit` | 0.069 (n 29) | 0.000 (n 29) | 149 |
| psy-trance | 34 | no | `variant-comb-best-phase` | 0.941 (n 34) | 0.118 (n 34) | 0.8817 |
| psy-trance | 34 | no | `variant-fixed-time` | 0.941 (n 34) | 0.176 (n 34) | 1 |
| reggae-dub | 2 | yes | `boomboomboomkit-optimal` | 0.000 (n 2) | 0.000 (n 2) | 46.28 |
| reggae-dub | 2 | yes | `variant-joint-fit` | 0.000 (n 2) | 0.000 (n 2) | 116.2 |
| reggae-dub | 2 | yes | `variant-comb-best-phase` | 0.000 (n 2) | 0.000 (n 2) | 46.28 |
| reggae-dub | 2 | yes | `variant-fixed-time` | 0.000 (n 2) | 0.000 (n 2) | 70.5 |
| tech-house | 22 | no | `boomboomboomkit-optimal` | 0.864 (n 22) | 0.045 (n 22) | 0.8638 |
| tech-house | 22 | no | `variant-joint-fit` | 0.167 (n 18) | 0.111 (n 18) | 125 |
| tech-house | 22 | no | `variant-comb-best-phase` | 0.864 (n 22) | 0.045 (n 22) | 0.8638 |
| tech-house | 22 | no | `variant-fixed-time` | 0.909 (n 22) | 0.227 (n 22) | 1 |
| techno | 61 | no | `boomboomboomkit-optimal` | 0.754 (n 61) | 0.098 (n 61) | 0.9293 |
| techno | 61 | no | `variant-joint-fit` | 0.250 (n 48) | 0.083 (n 48) | 119 |
| techno | 61 | no | `variant-comb-best-phase` | 0.754 (n 61) | 0.098 (n 61) | 0.9293 |
| techno | 61 | no | `variant-fixed-time` | 0.967 (n 61) | 0.295 (n 61) | 1 |
| trance | 74 | no | `boomboomboomkit-optimal` | 0.743 (n 74) | 0.027 (n 74) | 1.155 |
| trance | 74 | no | `variant-joint-fit` | 0.128 (n 47) | 0.000 (n 47) | 141 |
| trance | 74 | no | `variant-comb-best-phase` | 0.743 (n 74) | 0.027 (n 74) | 1.155 |
| trance | 74 | no | `variant-fixed-time` | 1.000 (n 74) | 0.108 (n 74) | 1 |

### Paired differences, all tracks

#### `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 418 | 1 | [1, 1] | 2.31e-66 | yes |
| strict_0.10 | 418 | 0 | [0, 0] | 0.000464 | no |
| strict_0.05 | 418 | 0 | [0, 0] | 0.132 | no |
| strict_0.02 | 418 | 0 | [0, 0] | 0.0606 | no |
| error_bpm | 418 | -139.5 | [-140, -128] | 2.12e-52 | yes |
| abs_error_bpm | 418 | -136.1 | [-139.8, -127.1] | 9.38e-63 | yes |
| error_ppt | 418 | -996.2 | [-998.9, -994] | 4.4e-51 | yes |
| abs_error_ppt | 418 | -988.2 | [-996.2, -978.4] | 1.61e-61 | yes |
| failed_or_abstained | 661 | 0 | [0, 0] | 8.72e-55 | no |
| runtime_s | 661 | -0.0569 | [-0.05709, -0.05676] | 6.62e-110 | yes |
| peak_memory_bytes | 661 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1 | no |
| strict_0.10 | 661 | 0 | [0, 0] | 1 | no |
| strict_0.05 | 661 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 661 | 0 | [0, 0] | 1 | no |
| error_bpm | 661 | 0 | [0, 0] | 1 | no |
| abs_error_bpm | 661 | 0 | [0, 0] | 1 | no |
| error_ppt | 661 | 0 | [0, 0] | 1 | no |
| abs_error_ppt | 661 | 0 | [0, 0] | 1 | no |
| failed_or_abstained | 661 | 0 | [0, 0] | 1 | no |
| runtime_s | 661 | -0.0001004 | [-0.000249, 8.063e-05] | 0.81 | no |
| peak_memory_bytes | 661 | 1.638e+04 | [1.638e+04, 1.638e+04] | 5.74e-124 | yes |

#### `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1.11e-07 | no |
| strict_0.10 | 661 | 0 | [0, 0] | 1.13e-25 | no |
| strict_0.05 | 661 | 0 | [0, 0] | 1.07e-30 | no |
| strict_0.02 | 661 | 0 | [0, 0] | 2.47e-37 | no |
| error_bpm | 661 | 0.1652 | [0.09501, 0.2917] | 1.11e-19 | yes |
| abs_error_bpm | 661 | 0.139 | [0.08605, 0.1925] | 9.9e-11 | yes |
| error_ppt | 661 | 1.297 | [0.7206, 2.254] | 1.46e-19 | yes |
| abs_error_ppt | 661 | 0.9651 | [0.5625, 1.404] | 1.15e-10 | yes |
| failed_or_abstained | 661 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1.07e-41 | no |
| strict_0.10 | 661 | -1 | [-1, -1] | 1.51e-135 | yes |
| strict_0.05 | 661 | -1 | [-1, -1] | 8.25e-139 | yes |
| strict_0.02 | 661 | -1 | [-1, -1] | 8.21e-144 | yes |
| error_bpm | 661 | 0.6761 | [0.4764, 0.8352] | 6.3e-17 | yes |
| abs_error_bpm | 661 | 1.192 | [1.109, 1.276] | 6.62e-110 | yes |
| error_ppt | 661 | 4.526 | [3.373, 5.576] | 3.67e-16 | yes |
| abs_error_ppt | 661 | 8.61 | [8.06, 9.083] | 6.62e-110 | yes |

#### `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 418 | -1 | [-1, -1] | 2.31e-66 | yes |
| strict_0.10 | 418 | 0 | [0, 0] | 0.000464 | no |
| strict_0.05 | 418 | 0 | [0, 0] | 0.132 | no |
| strict_0.02 | 418 | 0 | [0, 0] | 0.0606 | no |
| error_bpm | 418 | 139.5 | [127.8, 140] | 2.12e-52 | yes |
| abs_error_bpm | 418 | 136.1 | [127.1, 139.8] | 9.38e-63 | yes |
| error_ppt | 418 | 996.2 | [994, 998.9] | 4.4e-51 | yes |
| abs_error_ppt | 418 | 988.2 | [978.4, 996.2] | 1.61e-61 | yes |
| failed_or_abstained | 661 | 0 | [0, 0] | 8.72e-55 | no |
| runtime_s | 661 | 0.05702 | [0.05686, 0.05729] | 6.69e-110 | yes |
| peak_memory_bytes | 661 | 1.638e+04 | [1.638e+04, 1.638e+04] | 5.74e-124 | yes |

#### `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 418 | -1 | [-1, -1] | 1.35e-64 | yes |
| strict_0.10 | 418 | 0 | [0, 0] | 1.53e-20 | no |
| strict_0.05 | 418 | 0 | [0, 0] | 1.53e-20 | no |
| strict_0.02 | 418 | 0 | [0, 0] | 1.06e-21 | no |
| error_bpm | 418 | 140 | [128, 140] | 1.53e-55 | yes |
| abs_error_bpm | 418 | 131 | [125.5, 138.7] | 6.28e-65 | yes |
| error_ppt | 418 | 999.9 | [992.9, 1000] | 5.08e-56 | yes |
| abs_error_ppt | 418 | 982.6 | [976.4, 999.8] | 1.12e-64 | yes |
| failed_or_abstained | 661 | 0 | [0, 0] | 8.72e-55 | no |

#### `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 418 | -1 | [-1, -1] | 2.09e-79 | yes |
| strict_0.10 | 418 | -1 | [-1, -1] | 1.5e-88 | yes |
| strict_0.05 | 418 | -1 | [-1, -1] | 1.5e-88 | yes |
| strict_0.02 | 418 | -1 | [-1, -1] | 5.51e-89 | yes |
| error_bpm | 418 | 138 | [127.4, 141] | 1.52e-55 | yes |
| abs_error_bpm | 418 | 138 | [127.6, 141] | 3.13e-70 | yes |
| error_ppt | 418 | 999.9 | [985.9, 1000] | 8.31e-56 | yes |
| abs_error_ppt | 418 | 999.9 | [985.9, 1000] | 3.13e-70 | yes |

#### `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1.11e-07 | no |
| strict_0.10 | 661 | 0 | [0, 0] | 1.13e-25 | no |
| strict_0.05 | 661 | 0 | [0, 0] | 1.07e-30 | no |
| strict_0.02 | 661 | 0 | [0, 0] | 2.47e-37 | no |
| error_bpm | 661 | 0.1652 | [0.09501, 0.2917] | 1.11e-19 | yes |
| abs_error_bpm | 661 | 0.139 | [0.08605, 0.1968] | 9.9e-11 | yes |
| error_ppt | 661 | 1.297 | [0.7206, 2.09] | 1.46e-19 | yes |
| abs_error_ppt | 661 | 0.9651 | [0.5656, 1.404] | 1.15e-10 | yes |
| failed_or_abstained | 661 | 0 | [0, 0] | 1 | no |

#### `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1.07e-41 | no |
| strict_0.10 | 661 | -1 | [-1, -1] | 1.51e-135 | yes |
| strict_0.05 | 661 | -1 | [-1, -1] | 8.25e-139 | yes |
| strict_0.02 | 661 | -1 | [-1, -1] | 8.21e-144 | yes |
| error_bpm | 661 | 0.6761 | [0.4961, 0.8352] | 6.3e-17 | yes |
| abs_error_bpm | 661 | 1.192 | [1.109, 1.276] | 6.62e-110 | yes |
| error_ppt | 661 | 4.526 | [3.427, 5.576] | 3.67e-16 | yes |
| abs_error_ppt | 661 | 8.61 | [8.06, 9.094] | 6.62e-110 | yes |

#### `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 661 | 0 | [0, 0] | 1.3e-26 | no |
| strict_0.10 | 661 | -1 | [-1, -1] | 6.41e-108 | yes |
| strict_0.05 | 661 | -1 | [-1, -1] | 6.41e-108 | yes |
| strict_0.02 | 661 | -1 | [-1, -1] | 6.41e-108 | yes |
| error_bpm | 661 | 0 | [0, 0] | 0.119 | no |
| abs_error_bpm | 661 | 1 | [1, 1] | 2.78e-86 | yes |
| error_ppt | 661 | 0 | [0, 0] | 0.00351 | no |
| abs_error_ppt | 661 | 7.194 | [7.194, 7.752] | 9.46e-82 | yes |

### Directions stated (all tracks)

- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), level_same: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is above zero: 1, n = 418, 95 % interval [1, 1], Wilcoxon p = 2.31e-66.
- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -139.467, n = 418, 95 % interval [-139.955, -128.023], Wilcoxon p = 2.12e-52.
- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -136.059, n = 418, 95 % interval [-139.804, -127.07], Wilcoxon p = 9.38e-63.
- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -996.171, n = 418, 95 % interval [-998.935, -993.968], Wilcoxon p = 4.4e-51.
- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -988.211, n = 418, 95 % interval [-996.152, -978.353], Wilcoxon p = 1.61e-61.
- giantsteps, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system, crowdsourced-reference), runtime_s: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -0.0569043, n = 661, 95 % interval [-0.0570906, -0.0567557], Wilcoxon p = 6.62e-110.
- giantsteps, `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), peak_memory_bytes: the median paired difference (boomboomboomkit-optimal minus variant-comb-best-phase) is above zero: 16384, n = 661, 95 % interval [16384, 16384], Wilcoxon p = 5.74e-124.
- giantsteps, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 0.165245, n = 661, 95 % interval [0.0950148, 0.291685], Wilcoxon p = 1.11e-19.
- giantsteps, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 0.139031, n = 661, 95 % interval [0.0860544, 0.192469], Wilcoxon p = 9.9e-11.
- giantsteps, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 1.29692, n = 661, 95 % interval [0.720626, 2.25445], Wilcoxon p = 1.46e-19.
- giantsteps, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 0.965094, n = 661, 95 % interval [0.562463, 1.40399], Wilcoxon p = 1.15e-10.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.10: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 1.51e-135.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.05: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 8.25e-139.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.02: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 8.21e-144.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), error_bpm: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 0.676117, n = 661, 95 % interval [0.476371, 0.83518], Wilcoxon p = 6.3e-17.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 1.19247, n = 661, 95 % interval [1.10885, 1.27625], Wilcoxon p = 6.62e-110.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), error_ppt: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 4.52632, n = 661, 95 % interval [3.37262, 5.57567], Wilcoxon p = 3.67e-16.
- giantsteps, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 8.61018, n = 661, 95 % interval [8.06048, 9.08327], Wilcoxon p = 6.62e-110.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), level_same: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 2.31e-66.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), error_bpm: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 139.467, n = 418, 95 % interval [127.838, 139.955], Wilcoxon p = 2.12e-52.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 136.059, n = 418, 95 % interval [127.11, 139.804], Wilcoxon p = 9.38e-63.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), error_ppt: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 996.171, n = 418, 95 % interval [994.03, 998.929], Wilcoxon p = 4.4e-51.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 988.211, n = 418, 95 % interval [978.353, 996.158], Wilcoxon p = 1.61e-61.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), runtime_s: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 0.0570228, n = 661, 95 % interval [0.0568644, 0.0572865], Wilcoxon p = 6.69e-110.
- giantsteps, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system, crowdsourced-reference), peak_memory_bytes: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 16384, n = 661, 95 % interval [16384, 16384], Wilcoxon p = 5.74e-124.
- giantsteps, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), level_same: the median paired difference (variant-joint-fit minus variant-fixed-time) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 1.35e-64.
- giantsteps, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_bpm: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 139.989, n = 418, 95 % interval [128.001, 139.997], Wilcoxon p = 1.53e-55.
- giantsteps, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 131.001, n = 418, 95 % interval [125.501, 138.695], Wilcoxon p = 6.28e-65.
- giantsteps, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_ppt: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 999.922, n = 418, 95 % interval [992.911, 999.987], Wilcoxon p = 5.08e-56.
- giantsteps, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 982.611, n = 418, 95 % interval [976.387, 999.839], Wilcoxon p = 1.12e-64.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), level_same: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 2.09e-79.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.10: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 1.5e-88.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.05: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 1.5e-88.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.02: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 418, 95 % interval [-1, -1], Wilcoxon p = 5.51e-89.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), error_bpm: the median paired difference (variant-joint-fit minus oracle) is above zero: 138.001, n = 418, 95 % interval [127.394, 140.992], Wilcoxon p = 1.52e-55.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-joint-fit minus oracle) is above zero: 138.001, n = 418, 95 % interval [127.578, 140.992], Wilcoxon p = 3.13e-70.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), error_ppt: the median paired difference (variant-joint-fit minus oracle) is above zero: 999.909, n = 418, 95 % interval [985.852, 999.983], Wilcoxon p = 8.31e-56.
- giantsteps, `variant-joint-fit` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-joint-fit minus oracle) is above zero: 999.909, n = 418, 95 % interval [985.852, 999.983], Wilcoxon p = 3.13e-70.
- giantsteps, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_bpm: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 0.165245, n = 661, 95 % interval [0.0950148, 0.291685], Wilcoxon p = 1.11e-19.
- giantsteps, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 0.139031, n = 661, 95 % interval [0.0860544, 0.196761], Wilcoxon p = 9.9e-11.
- giantsteps, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), error_ppt: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 1.29692, n = 661, 95 % interval [0.720626, 2.09006], Wilcoxon p = 1.46e-19.
- giantsteps, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 0.965094, n = 661, 95 % interval [0.565637, 1.40399], Wilcoxon p = 1.15e-10.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.10: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 1.51e-135.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.05: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 8.25e-139.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.02: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 8.21e-144.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), error_bpm: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 0.676117, n = 661, 95 % interval [0.496119, 0.83518], Wilcoxon p = 6.3e-17.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 1.19247, n = 661, 95 % interval [1.10885, 1.27625], Wilcoxon p = 6.62e-110.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), error_ppt: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 4.52632, n = 661, 95 % interval [3.42713, 5.57567], Wilcoxon p = 3.67e-16.
- giantsteps, `variant-comb-best-phase` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 8.61018, n = 661, 95 % interval [8.06048, 9.09355], Wilcoxon p = 6.62e-110.
- giantsteps, `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.10: the median paired difference (variant-fixed-time minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 6.41e-108.
- giantsteps, `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.05: the median paired difference (variant-fixed-time minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 6.41e-108.
- giantsteps, `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference), strict_0.02: the median paired difference (variant-fixed-time minus oracle) is below zero: -1, n = 661, 95 % interval [-1, -1], Wilcoxon p = 6.41e-108.
- giantsteps, `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_bpm: the median paired difference (variant-fixed-time minus oracle) is above zero: 1, n = 661, 95 % interval [1, 1], Wilcoxon p = 2.78e-86.
- giantsteps, `variant-fixed-time` vs `oracle` (system-vs-reference, crowdsourced-reference), abs_error_ppt: the median paired difference (variant-fixed-time minus oracle) is above zero: 7.19424, n = 661, 95 % interval [7.19424, 7.75194], Wilcoxon p = 9.46e-82.

Stratified pairings, each with n, interval, p and a direction only where the stratum is not underpowered, are in the JSON aggregate.

## oa300

n = 22; reference: daw-verified (`daw-oracle.json`, sha256 2496ec3acd53e209...); hand-annotated tracks: 0.

Recordings listed twice under two formats counted once: 1 dropped.

### Per-system results, all tracks

| system | outcomes | level same | strict 0.10 | strict 0.05 | strict 0.02 | median abs error BPM | median abs error ppt | median runtime s | median peak memory MB | grid families |
|---|---|---|---|---|---|---|---|---|---|---|
| `boomboomboomkit-optimal` | ok 22 | 0.545 (n 22) | 0.227 (n 22) | 0.136 (n 22) | 0.136 (n 22) | 0.4178 | 2.457 | 0.1167 | 40.41 | no-reference 22 |
| `variant-joint-fit` | abstained 6, ok 16 | 0.125 (n 16) | 0.125 (n 16) | 0.125 (n 16) | 0.125 (n 16) | 125 | 875.1 | 0.1738 | 40.41 | no-reference 22 |
| `variant-comb-best-phase` | ok 22 | 0.545 (n 22) | 0.227 (n 22) | 0.136 (n 22) | 0.136 (n 22) | 0.4178 | 2.457 | 0.1166 | 40.38 | no-reference 22 |
| `variant-fixed-time` | ok 22 | 0.864 (n 22) | 0.818 (n 22) | 0.818 (n 22) | 0.818 (n 22) | 0 | 0 | - | - | no-reference 22 |
| `commercial-analyzer` | ok 22 | 0.818 (n 22) | 0.818 (n 22) | 0.818 (n 22) | 0.818 (n 22) | 0 | 0 | - | - | no-reference 22 |
| `oracle` | reference 22 | 1.000 (n 22) | 1.000 (n 22) | 1.000 (n 22) | 1.000 (n 22) | 0 | 0 | - | - | no-reference 22 |

### By tempo band

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| 110-129 | 4 | yes | `boomboomboomkit-optimal` | 1.000 (n 4) | 0.250 (n 4) | 0.1003 |
| 110-129 | 4 | yes | `variant-joint-fit` | 0.500 (n 2) | 0.500 (n 2) | 65.01 |
| 110-129 | 4 | yes | `variant-comb-best-phase` | 1.000 (n 4) | 0.250 (n 4) | 0.1003 |
| 110-129 | 4 | yes | `variant-fixed-time` | 1.000 (n 4) | 1.000 (n 4) | 0.005 |
| 110-129 | 4 | yes | `commercial-analyzer` | 1.000 (n 4) | 1.000 (n 4) | 0.005 |
| 130-149 | 2 | yes | `boomboomboomkit-optimal` | 1.000 (n 2) | 0.500 (n 2) | 0.1348 |
| 130-149 | 2 | yes | `variant-joint-fit` | 0.500 (n 2) | 0.500 (n 2) | 70 |
| 130-149 | 2 | yes | `variant-comb-best-phase` | 1.000 (n 2) | 0.500 (n 2) | 0.1348 |
| 130-149 | 2 | yes | `variant-fixed-time` | 1.000 (n 2) | 1.000 (n 2) | 0 |
| 130-149 | 2 | yes | `commercial-analyzer` | 1.000 (n 2) | 1.000 (n 2) | 0 |
| 150-179 | 16 | no | `boomboomboomkit-optimal` | 0.375 (n 16) | 0.062 (n 16) | 55.14 |
| 150-179 | 16 | no | `variant-joint-fit` | 0.000 (n 12) | 0.000 (n 12) | 135 |
| 150-179 | 16 | no | `variant-comb-best-phase` | 0.375 (n 16) | 0.062 (n 16) | 55.14 |
| 150-179 | 16 | no | `variant-fixed-time` | 0.812 (n 16) | 0.750 (n 16) | 0 |
| 150-179 | 16 | no | `commercial-analyzer` | 0.750 (n 16) | 0.750 (n 16) | 0 |

### By style tag

Rates are the share of tracks with a value; each cell shows n.

| stratum | n | underpowered | system | level same | strict 0.05 | median abs error BPM |
|---|---|---|---|---|---|---|
| breaks | 5 | yes | `boomboomboomkit-optimal` | 0.600 (n 5) | 0.200 (n 5) | 0.2696 |
| breaks | 5 | yes | `variant-joint-fit` | 0.500 (n 4) | 0.500 (n 4) | 60.02 |
| breaks | 5 | yes | `variant-comb-best-phase` | 0.600 (n 5) | 0.200 (n 5) | 0.2696 |
| breaks | 5 | yes | `variant-fixed-time` | 1.000 (n 5) | 1.000 (n 5) | 0 |
| breaks | 5 | yes | `commercial-analyzer` | 1.000 (n 5) | 1.000 (n 5) | 0 |
| drum-and-bass | 12 | no | `boomboomboomkit-optimal` | 0.417 (n 12) | 0.083 (n 12) | 43.33 |
| drum-and-bass | 12 | no | `variant-joint-fit` | 0.000 (n 10) | 0.000 (n 10) | 135 |
| drum-and-bass | 12 | no | `variant-comb-best-phase` | 0.417 (n 12) | 0.083 (n 12) | 43.33 |
| drum-and-bass | 12 | no | `variant-fixed-time` | 0.750 (n 12) | 0.667 (n 12) | 0 |
| drum-and-bass | 12 | no | `commercial-analyzer` | 0.667 (n 12) | 0.667 (n 12) | 0 |
| footwork | 1 | yes | `boomboomboomkit-optimal` | 1.000 (n 1) | 0.000 (n 1) | 0.1347 |
| footwork | 1 | yes | `variant-joint-fit` | 0.000 (n 1) | 0.000 (n 1) | 160 |
| footwork | 1 | yes | `variant-comb-best-phase` | 1.000 (n 1) | 0.000 (n 1) | 0.1347 |
| footwork | 1 | yes | `variant-fixed-time` | 1.000 (n 1) | 1.000 (n 1) | 0 |
| footwork | 1 | yes | `commercial-analyzer` | 1.000 (n 1) | 1.000 (n 1) | 0 |
| half-time-dnb | 1 | yes | `boomboomboomkit-optimal` | 0.000 (n 1) | 0.000 (n 1) | 56.53 |
| half-time-dnb | 1 | yes | `variant-comb-best-phase` | 0.000 (n 1) | 0.000 (n 1) | 56.53 |
| half-time-dnb | 1 | yes | `variant-fixed-time` | 1.000 (n 1) | 1.000 (n 1) | 0 |
| half-time-dnb | 1 | yes | `commercial-analyzer` | 1.000 (n 1) | 1.000 (n 1) | 0 |
| tech-house | 1 | yes | `boomboomboomkit-optimal` | 1.000 (n 1) | 1.000 (n 1) | 0.01 |
| tech-house | 1 | yes | `variant-joint-fit` | 0.000 (n 1) | 0.000 (n 1) | 130 |
| tech-house | 1 | yes | `variant-comb-best-phase` | 1.000 (n 1) | 1.000 (n 1) | 0.01 |
| tech-house | 1 | yes | `variant-fixed-time` | 1.000 (n 1) | 1.000 (n 1) | 0.01 |
| tech-house | 1 | yes | `commercial-analyzer` | 1.000 (n 1) | 1.000 (n 1) | 0.01 |
| techno | 2 | yes | `boomboomboomkit-optimal` | 1.000 (n 2) | 0.000 (n 2) | 0.1122 |
| techno | 2 | yes | `variant-comb-best-phase` | 1.000 (n 2) | 0.000 (n 2) | 0.1122 |
| techno | 2 | yes | `variant-fixed-time` | 1.000 (n 2) | 1.000 (n 2) | 0 |
| techno | 2 | yes | `commercial-analyzer` | 1.000 (n 2) | 1.000 (n 2) | 0 |

### Paired differences, all tracks

#### `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 16 | 0.5 | [0, 1] | 0.00781 | no |
| strict_0.10 | 16 | 0 | [0, 0.5] | 0.688 | no |
| strict_0.05 | 16 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 16 | 0 | [0, 0] | 1 | no |
| error_bpm | 16 | -65.04 | [-159.9, 39.93] | 0.0739 | no |
| abs_error_bpm | 16 | -93.29 | [-159.9, -39.99] | 0.000427 | yes |
| error_ppt | 16 | -499.2 | [-999.9, 249.6] | 0.0739 | no |
| abs_error_ppt | 16 | -665.1 | [-999.2, -249.9] | 0.000427 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 0.0312 | no |
| runtime_s | 22 | -0.05688 | [-0.05743, -0.05669] | 4.77e-07 | yes |
| peak_memory_bytes | 22 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 1 | no |
| strict_0.10 | 22 | 0 | [0, 0] | 1 | no |
| strict_0.05 | 22 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 22 | 0 | [0, 0] | 1 | no |
| error_bpm | 22 | 0 | [0, 0] | 1 | no |
| abs_error_bpm | 22 | 0 | [0, 0] | 1 | no |
| error_ppt | 22 | 0 | [0, 0] | 1 | no |
| abs_error_ppt | 22 | 0 | [0, 0] | 1 | no |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |
| runtime_s | 22 | -1.473e-05 | [-0.0003952, 0.0005771] | 0.75 | no |
| peak_memory_bytes | 22 | 1.638e+04 | [1.638e+04, 3.277e+04] | 0.000157 | yes |

#### `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [-0.5, 0] | 0.0156 | no |
| strict_0.10 | 22 | -1 | [-1, 0] | 0.000789 | no |
| strict_0.05 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| strict_0.02 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| error_bpm | 22 | -0.1031 | [-29.76, -0.00347] | 0.0266 | yes |
| abs_error_bpm | 22 | 0.2226 | [0.1012, 27.1] | 0.000134 | yes |
| error_ppt | 22 | -0.7564 | [-166.8, 0] | 0.024 | no |
| abs_error_ppt | 22 | 1.553 | [0.7558, 183.2] | 0.000134 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `commercial-analyzer` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 0.0312 | no |
| strict_0.10 | 22 | -1 | [-1, 0] | 0.000244 | no |
| strict_0.05 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| strict_0.02 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| error_bpm | 22 | -0.07917 | [-0.4381, 0.08778] | 0.245 | no |
| abs_error_bpm | 22 | 0.1305 | [0.0658, 0.4381] | 0.0121 | yes |
| error_ppt | 22 | -0.4936 | [-2.577, 0.5164] | 0.231 | no |
| abs_error_ppt | 22 | 0.9144 | [0.4386, 2.577] | 0.0121 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |

#### `boomboomboomkit-optimal` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [-1, 0] | 0.00195 | no |
| strict_0.10 | 22 | -1 | [-1, -1] | 3.74e-05 | yes |
| strict_0.05 | 22 | -1 | [-1, -1] | 1.31e-05 | yes |
| strict_0.02 | 22 | -1 | [-1, -1] | 1.31e-05 | yes |
| error_bpm | 22 | -0.2822 | [-56.58, -0.0329] | 0.00428 | yes |
| abs_error_bpm | 22 | 0.4178 | [0.1263, 56.63] | 9.54e-07 | yes |
| error_ppt | 22 | -1.782 | [-333.9, -0.2193] | 0.00375 | yes |
| abs_error_ppt | 22 | 2.457 | [0.9003, 333.9] | 9.54e-07 | yes |

#### `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 16 | -0.5 | [-1, 0] | 0.00781 | no |
| strict_0.10 | 16 | 0 | [-0.5, 0] | 0.688 | no |
| strict_0.05 | 16 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 16 | 0 | [0, 0] | 1 | no |
| error_bpm | 16 | 65.04 | [-39.93, 159.9] | 0.0739 | no |
| abs_error_bpm | 16 | 93.29 | [39.96, 159.9] | 0.000427 | yes |
| error_ppt | 16 | 499.2 | [-249.6, 999.9] | 0.0739 | no |
| abs_error_ppt | 16 | 665.1 | [249.9, 999.1] | 0.000427 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 0.0312 | no |
| runtime_s | 22 | 0.05698 | [0.05632, 0.05802] | 4.77e-07 | yes |
| peak_memory_bytes | 22 | 1.638e+04 | [1.638e+04, 3.277e+04] | 0.000157 | yes |

#### `variant-joint-fit` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 16 | -1 | [-1, -0.5] | 0.000488 | yes |
| strict_0.10 | 16 | -1 | [-1, 0] | 0.000977 | no |
| strict_0.05 | 16 | -1 | [-1, 0] | 0.000977 | no |
| strict_0.02 | 16 | -1 | [-1, 0] | 0.000977 | no |
| error_bpm | 16 | 65 | [-53.42, 160] | 0.0934 | no |
| abs_error_bpm | 16 | 125 | [106.8, 160] | 3.05e-05 | yes |
| error_ppt | 16 | 499.9 | [-333, 1000] | 0.0934 | no |
| abs_error_ppt | 16 | 871.7 | [625.1, 1000] | 3.05e-05 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 0.0312 | no |

#### `variant-joint-fit` vs `commercial-analyzer` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 16 | -1 | [-1, -0.5] | 0.000488 | yes |
| strict_0.10 | 16 | -1 | [-1, -0.5] | 0.000488 | yes |
| strict_0.05 | 16 | -1 | [-1, -0.5] | 0.000488 | yes |
| strict_0.02 | 16 | -1 | [-1, -0.5] | 0.000488 | yes |
| error_bpm | 16 | 65 | [-53.42, 160] | 0.0934 | no |
| abs_error_bpm | 16 | 125 | [74.12, 160] | 3.05e-05 | yes |
| error_ppt | 16 | 499.9 | [-166, 1000] | 0.0934 | no |
| abs_error_ppt | 16 | 875.1 | [458.1, 1000] | 3.05e-05 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 0.0312 | no |

#### `variant-joint-fit` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 16 | -1 | [-1, -1] | 0.000183 | yes |
| strict_0.10 | 16 | -1 | [-1, -1] | 0.000183 | yes |
| strict_0.05 | 16 | -1 | [-1, -1] | 0.000183 | yes |
| strict_0.02 | 16 | -1 | [-1, -1] | 0.000183 | yes |
| error_bpm | 16 | 65 | [-106.8, 160] | 0.0934 | no |
| abs_error_bpm | 16 | 125 | [113.2, 160] | 3.05e-05 | yes |
| error_ppt | 16 | 499.9 | [-666, 1000] | 0.0934 | no |
| abs_error_ppt | 16 | 875.1 | [667.7, 1000] | 3.05e-05 | yes |

#### `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [-0.5, 0] | 0.0156 | no |
| strict_0.10 | 22 | -1 | [-1, 0] | 0.000789 | no |
| strict_0.05 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| strict_0.02 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| error_bpm | 22 | -0.1031 | [-32.91, -0.003559] | 0.0266 | yes |
| abs_error_bpm | 22 | 0.2226 | [0.1012, 27.1] | 0.000134 | yes |
| error_ppt | 22 | -0.7564 | [-183.5, -0.02093] | 0.024 | yes |
| abs_error_ppt | 22 | 1.553 | [0.7564, 183.2] | 0.000134 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |

#### `variant-comb-best-phase` vs `commercial-analyzer` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 0.0312 | no |
| strict_0.10 | 22 | -1 | [-1, 0] | 0.000244 | no |
| strict_0.05 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| strict_0.02 | 22 | -1 | [-1, -0.5] | 0.000108 | yes |
| error_bpm | 22 | -0.07917 | [-0.4381, 0.08778] | 0.245 | no |
| abs_error_bpm | 22 | 0.1305 | [0.0658, 0.4381] | 0.0121 | yes |
| error_ppt | 22 | -0.4936 | [-2.577, 0.5164] | 0.231 | no |
| abs_error_ppt | 22 | 0.9144 | [0.4386, 2.577] | 0.0121 | yes |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |

#### `variant-comb-best-phase` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [-1, 0] | 0.00195 | no |
| strict_0.10 | 22 | -1 | [-1, -1] | 3.74e-05 | yes |
| strict_0.05 | 22 | -1 | [-1, -1] | 1.31e-05 | yes |
| strict_0.02 | 22 | -1 | [-1, -1] | 1.31e-05 | yes |
| error_bpm | 22 | -0.2822 | [-56.63, -0.0329] | 0.00428 | yes |
| abs_error_bpm | 22 | 0.4178 | [0.1305, 56.63] | 9.54e-07 | yes |
| error_ppt | 22 | -1.782 | [-333.9, -0.2193] | 0.00375 | yes |
| abs_error_ppt | 22 | 2.457 | [0.9003, 333.9] | 9.54e-07 | yes |

#### `variant-fixed-time` vs `commercial-analyzer` (system-vs-system)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 1 | no |
| strict_0.10 | 22 | 0 | [0, 0] | 1 | no |
| strict_0.05 | 22 | 0 | [0, 0] | 1 | no |
| strict_0.02 | 22 | 0 | [0, 0] | 1 | no |
| error_bpm | 22 | 0 | [0, 0] | 0.375 | no |
| abs_error_bpm | 22 | 0 | [0, 0] | 0.375 | no |
| error_ppt | 22 | 0 | [0, 0] | 0.625 | no |
| abs_error_ppt | 22 | 0 | [0, 0] | 0.625 | no |
| failed_or_abstained | 22 | 0 | [0, 0] | 1 | no |

#### `variant-fixed-time` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 0.25 | no |
| strict_0.10 | 22 | 0 | [0, 0] | 0.125 | no |
| strict_0.05 | 22 | 0 | [0, 0] | 0.125 | no |
| strict_0.02 | 22 | 0 | [0, 0] | 0.125 | no |
| error_bpm | 22 | 0 | [0, 0] | 0.0781 | no |
| abs_error_bpm | 22 | 0 | [0, 0.005] | 0.0156 | no |
| error_ppt | 22 | 0 | [0, 0] | 0.0781 | no |
| abs_error_ppt | 22 | 0 | [0, 0.03846] | 0.0156 | no |

#### `commercial-analyzer` vs `oracle` (system-vs-reference)

| metric | n | median | 95 % interval | Wilcoxon p | interval excludes 0 |
|---|---|---|---|---|---|
| level_same | 22 | 0 | [0, 0] | 0.125 | no |
| strict_0.10 | 22 | 0 | [0, 0] | 0.125 | no |
| strict_0.05 | 22 | 0 | [0, 0] | 0.125 | no |
| strict_0.02 | 22 | 0 | [0, 0] | 0.125 | no |
| error_bpm | 22 | 0 | [0, 0] | 0.0781 | no |
| abs_error_bpm | 22 | 0 | [0, 0.005] | 0.0156 | no |
| error_ppt | 22 | 0 | [0, 0] | 0.0781 | no |
| abs_error_ppt | 22 | 0 | [0, 0.03846] | 0.0156 | no |

### Directions stated (all tracks)

- oa300, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -93.2918, n = 16, 95 % interval [-159.858, -39.9893], Wilcoxon p = 0.000427.
- oa300, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -665.106, n = 16, 95 % interval [-999.243, -249.933], Wilcoxon p = 0.000427.
- oa300, `boomboomboomkit-optimal` vs `variant-joint-fit` (system-vs-system), runtime_s: the median paired difference (boomboomboomkit-optimal minus variant-joint-fit) is below zero: -0.0568825, n = 22, 95 % interval [-0.0574292, -0.0566925], Wilcoxon p = 4.77e-07.
- oa300, `boomboomboomkit-optimal` vs `variant-comb-best-phase` (system-vs-system), peak_memory_bytes: the median paired difference (boomboomboomkit-optimal minus variant-comb-best-phase) is above zero: 16384, n = 22, 95 % interval [16384, 32768], Wilcoxon p = 0.000157.
- oa300, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system), strict_0.05: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system), strict_0.02: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system), error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is below zero: -0.103102, n = 22, 95 % interval [-29.7573, -0.00346973], Wilcoxon p = 0.0266.
- oa300, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 0.222593, n = 22, 95 % interval [0.101195, 27.0962], Wilcoxon p = 0.000134.
- oa300, `boomboomboomkit-optimal` vs `variant-fixed-time` (system-vs-system), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus variant-fixed-time) is above zero: 1.55337, n = 22, 95 % interval [0.755824, 183.203], Wilcoxon p = 0.000134.
- oa300, `boomboomboomkit-optimal` vs `commercial-analyzer` (system-vs-system), strict_0.05: the median paired difference (boomboomboomkit-optimal minus commercial-analyzer) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `boomboomboomkit-optimal` vs `commercial-analyzer` (system-vs-system), strict_0.02: the median paired difference (boomboomboomkit-optimal minus commercial-analyzer) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `boomboomboomkit-optimal` vs `commercial-analyzer` (system-vs-system), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus commercial-analyzer) is above zero: 0.130518, n = 22, 95 % interval [0.0657966, 0.438088], Wilcoxon p = 0.0121.
- oa300, `boomboomboomkit-optimal` vs `commercial-analyzer` (system-vs-system), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus commercial-analyzer) is above zero: 0.914411, n = 22, 95 % interval [0.438644, 2.57699], Wilcoxon p = 0.0121.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), strict_0.10: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 3.74e-05.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), strict_0.05: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 1.31e-05.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), strict_0.02: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 1.31e-05.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), error_bpm: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -0.282196, n = 22, 95 % interval [-56.5814, -0.0328983], Wilcoxon p = 0.00428.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), abs_error_bpm: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 0.417756, n = 22, 95 % interval [0.126305, 56.6342], Wilcoxon p = 9.54e-07.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), error_ppt: the median paired difference (boomboomboomkit-optimal minus oracle) is below zero: -1.78187, n = 22, 95 % interval [-333.884, -0.219322], Wilcoxon p = 0.00375.
- oa300, `boomboomboomkit-optimal` vs `oracle` (system-vs-reference), abs_error_ppt: the median paired difference (boomboomboomkit-optimal minus oracle) is above zero: 2.45739, n = 22, 95 % interval [0.900254, 333.884], Wilcoxon p = 9.54e-07.
- oa300, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 93.2918, n = 16, 95 % interval [39.9643, 159.858], Wilcoxon p = 0.000427.
- oa300, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 665.106, n = 16, 95 % interval [249.933, 999.115], Wilcoxon p = 0.000427.
- oa300, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), runtime_s: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 0.0569842, n = 22, 95 % interval [0.0563223, 0.0580159], Wilcoxon p = 4.77e-07.
- oa300, `variant-joint-fit` vs `variant-comb-best-phase` (system-vs-system), peak_memory_bytes: the median paired difference (variant-joint-fit minus variant-comb-best-phase) is above zero: 16384, n = 22, 95 % interval [16384, 32768], Wilcoxon p = 0.000157.
- oa300, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), level_same: the median paired difference (variant-joint-fit minus variant-fixed-time) is below zero: -1, n = 16, 95 % interval [-1, -0.5], Wilcoxon p = 0.000488.
- oa300, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), abs_error_bpm: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 125.006, n = 16, 95 % interval [106.84, 159.993], Wilcoxon p = 3.05e-05.
- oa300, `variant-joint-fit` vs `variant-fixed-time` (system-vs-system), abs_error_ppt: the median paired difference (variant-joint-fit minus variant-fixed-time) is above zero: 871.716, n = 16, 95 % interval [625.065, 999.957], Wilcoxon p = 3.05e-05.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), level_same: the median paired difference (variant-joint-fit minus commercial-analyzer) is below zero: -1, n = 16, 95 % interval [-1, -0.5], Wilcoxon p = 0.000488.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), strict_0.10: the median paired difference (variant-joint-fit minus commercial-analyzer) is below zero: -1, n = 16, 95 % interval [-1, -0.5], Wilcoxon p = 0.000488.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), strict_0.05: the median paired difference (variant-joint-fit minus commercial-analyzer) is below zero: -1, n = 16, 95 % interval [-1, -0.5], Wilcoxon p = 0.000488.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), strict_0.02: the median paired difference (variant-joint-fit minus commercial-analyzer) is below zero: -1, n = 16, 95 % interval [-1, -0.5], Wilcoxon p = 0.000488.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), abs_error_bpm: the median paired difference (variant-joint-fit minus commercial-analyzer) is above zero: 125.015, n = 16, 95 % interval [74.1227, 159.993], Wilcoxon p = 3.05e-05.
- oa300, `variant-joint-fit` vs `commercial-analyzer` (system-vs-system), abs_error_ppt: the median paired difference (variant-joint-fit minus commercial-analyzer) is above zero: 875.065, n = 16, 95 % interval [458.135, 999.972], Wilcoxon p = 3.05e-05.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), level_same: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 16, 95 % interval [-1, -1], Wilcoxon p = 0.000183.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.10: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 16, 95 % interval [-1, -1], Wilcoxon p = 0.000183.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.05: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 16, 95 % interval [-1, -1], Wilcoxon p = 0.000183.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), strict_0.02: the median paired difference (variant-joint-fit minus oracle) is below zero: -1, n = 16, 95 % interval [-1, -1], Wilcoxon p = 0.000183.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), abs_error_bpm: the median paired difference (variant-joint-fit minus oracle) is above zero: 125.02, n = 16, 95 % interval [113.226, 159.993], Wilcoxon p = 3.05e-05.
- oa300, `variant-joint-fit` vs `oracle` (system-vs-reference), abs_error_ppt: the median paired difference (variant-joint-fit minus oracle) is above zero: 875.065, n = 16, 95 % interval [667.749, 999.972], Wilcoxon p = 3.05e-05.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), strict_0.05: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), strict_0.02: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), error_bpm: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is below zero: -0.103102, n = 22, 95 % interval [-32.9088, -0.0035587], Wilcoxon p = 0.0266.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), abs_error_bpm: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 0.222593, n = 22, 95 % interval [0.101195, 27.0962], Wilcoxon p = 0.000134.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), error_ppt: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is below zero: -0.756373, n = 22, 95 % interval [-183.513, -0.0209335], Wilcoxon p = 0.024.
- oa300, `variant-comb-best-phase` vs `variant-fixed-time` (system-vs-system), abs_error_ppt: the median paired difference (variant-comb-best-phase minus variant-fixed-time) is above zero: 1.55337, n = 22, 95 % interval [0.756373, 183.21], Wilcoxon p = 0.000134.
- oa300, `variant-comb-best-phase` vs `commercial-analyzer` (system-vs-system), strict_0.05: the median paired difference (variant-comb-best-phase minus commercial-analyzer) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `variant-comb-best-phase` vs `commercial-analyzer` (system-vs-system), strict_0.02: the median paired difference (variant-comb-best-phase minus commercial-analyzer) is below zero: -1, n = 22, 95 % interval [-1, -0.5], Wilcoxon p = 0.000108.
- oa300, `variant-comb-best-phase` vs `commercial-analyzer` (system-vs-system), abs_error_bpm: the median paired difference (variant-comb-best-phase minus commercial-analyzer) is above zero: 0.130518, n = 22, 95 % interval [0.0657966, 0.438088], Wilcoxon p = 0.0121.
- oa300, `variant-comb-best-phase` vs `commercial-analyzer` (system-vs-system), abs_error_ppt: the median paired difference (variant-comb-best-phase minus commercial-analyzer) is above zero: 0.914411, n = 22, 95 % interval [0.438644, 2.57699], Wilcoxon p = 0.0121.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), strict_0.10: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 3.74e-05.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), strict_0.05: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 1.31e-05.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), strict_0.02: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1, n = 22, 95 % interval [-1, -1], Wilcoxon p = 1.31e-05.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), error_bpm: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -0.282196, n = 22, 95 % interval [-56.6342, -0.0328983], Wilcoxon p = 0.00428.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), abs_error_bpm: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 0.417756, n = 22, 95 % interval [0.130518, 56.6342], Wilcoxon p = 9.54e-07.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), error_ppt: the median paired difference (variant-comb-best-phase minus oracle) is below zero: -1.78187, n = 22, 95 % interval [-333.884, -0.219322], Wilcoxon p = 0.00375.
- oa300, `variant-comb-best-phase` vs `oracle` (system-vs-reference), abs_error_ppt: the median paired difference (variant-comb-best-phase minus oracle) is above zero: 2.45739, n = 22, 95 % interval [0.900254, 333.884], Wilcoxon p = 9.54e-07.

Stratified pairings, each with n, interval, p and a direction only where the stratum is not underpowered, are in the JSON aggregate.

## Limitations

- `commercial-analyzer` values exist for OA300 only, where the DAW-verified reference covers 22 tracks; most of its strata are underpowered.
- Its version and analysis mode were not recorded with the values; its grid is not available, so its grid families are no-data.
- `variant-fixed-time` runs in Python from a separate scoring run; its runtime and memory are not comparable with the Swift rows.
- The 12.7 corpus carries no style tags.

## Digests

- corpusManifestSha256: "0dd695d1ef9feeafa64d0ff440d1bbb1b8238d785caa5c75675e82a983325ba6"
- runnerOutputSha256: "a6e4a644a69666e33f545824c8ec9d1b275dad2ad39655db4b21601343ba87b7"
- perTrackRowsSha256: "d566e4a9f6d72b53d39976e46255a696ef2005790a159fffdbd24f5c7a1a89f5"
- fixedTimeScoresSha256: {"eval-12-7": "a083c1fa0a8dd05cfdb0ea7c031e2e1d42dcf84891979045d7499410851273fc", "giantsteps": "3a688cf4961211905d755a24aede8adb1a4d1120194aa7aa0b09e6a05e714b62", "oa300": "2a2bb50d025bae3940aa578e584a1df85b79be005848f2e7117087dc0af22143"}
- untrackedPathsAtRun: 1
