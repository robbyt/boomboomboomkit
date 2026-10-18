# Timing probe artifacts

Standalone SPM package that reproduced the 2026-10-17 absolute-grid-timing
measurement before it was ported in-tree. Kept here so the measurement is
reproducible without BoomBoomBoomKit's test harness.

## Files

- `TimingProbeTests.swift` — the probe test body (24-row measurement across
  2 sample rates x 3 phase offsets x 2 waveforms x 2 paths).
- `ProbePackage.swift` — the SPM manifest the probe shipped as (renamed from
  `Package.swift` on preservation).
- `results.json` — the 24 rows the probe emitted on
  `rterhaar/12-7-eval-corpus-harness` HEAD `0f90ed8de52a9626cd47d3a263bed5af90a6c80e`.
- `swift-test.log` — the `swift test` output for that run.

## Reproducing standalone

Copy `TimingProbeTests.swift` into a fresh SPM package whose `Package.swift`
mirrors `ProbePackage.swift` (local-path dependency on this BoomBoomBoomKit
checkout), then `swift test`.

## In-tree equivalent

Story 15.2 ported the probe to
`Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift`.
The in-tree test is env-gated (`BBB_BEATGRID_TIMING_BASELINE=1`) and writes a
per-SHA baseline under `_bmad-output/perf-baselines/beatgrid-timing/`. The two
bodies share:

- the fixture matrix (`sampleRate` in {44.1, 48} kHz, offset in {0, hop/2, hop-1},
  waveform in {single-impulse, 64-sample-exp-decay}),
- the known-tempo path through `BeatGridAnalyzer.estimateBeatGrid` and the
  public facade through `AudioAnalysisService.analyzeBeatGrid`, and
- the residual math `phase = (presentationTime - offset/sampleRate) / 0.5 s`,
  `residualMs = (phase - phase.rounded()) * 0.5 * 1000`.

The in-tree test adds a reproduction tripwire (every row must fall in
[-50.5, -39.5] ms until Phase 3 lands) and a baseline writer with full
provenance headers; the standalone probe emits only `print` lines.

If these bodies drift semantically (fixture matrix, path identity, residual
math), the drift is a Story 15.2 regression and must be reconciled in both
files.
