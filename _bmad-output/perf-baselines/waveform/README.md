# waveform baselines

Per-SHA wall-clock snapshots of `WaveformAnalyzer.analyze(decoded:options:)`
with default options, produced by
`Tests/BoomBoomBoomKitBenchmarkTests/WaveformAnalyzerPerfTests.swift`.

Each file records three deterministic synthetic mono fixtures at 44.1 kHz
(30 s, 300 s and 600 s). Each fixture is the sum of four sines (55, 220, 880
and 6000 Hz, amplitudes 0.30, 0.25, 0.20 and 0.10) plus uniform `SplitMix64`
noise at amplitude 0.01. Per fixture the probe makes one warm-up call, then
five timed calls with `ContinuousClock`, and records min, median and max.

The suite asserts nothing about speed. It is a recording probe.

## File naming

```
<short-sha>-<ISO-8601 timestamp>.json
```

The short SHA is `git rev-parse HEAD` truncated to 10 characters, with a
`-dirty` suffix when `Sources/`, `Tests/` or `Package.swift` has uncommitted or
untracked changes. The timestamp is UTC, with colons replaced by hyphens.

## Reading

```jsonc
{
  "schemaVersion": 1,
  "commitSHA": "...",
  "createdAt": "2026-10-20T...",
  "platform": "Version 27.x (Build ...) arch=arm64",
  "configuration": "release" | "debug",
  "filterImplementation": "scalar-biquad-double.v1",
  "probeSource": "Tests/BoomBoomBoomKitBenchmarkTests/WaveformAnalyzerPerfTests.swift",
  "sampleRate": 44100,
  "timedIterations": 5,
  "fixtures": [
    { "durationSeconds": 30 | 300 | 600,
      "sampleCount": 1323000 | 13230000 | 26460000,
      "minMs": ...,
      "medianMs": ...,
      "maxMs": ... },
    ...
  ]
}
```

`filterImplementation` is `WaveformAnalyzer.bandFilterImplementation`. It names
the implementation of the four band filter passes, so two files with different
values measure different filter code. Compare `medianMs` across files with the
same `configuration` and `platform`.

## Reproducing

```
make waveform-perf-baseline
```

This builds in release config and runs
`BBB_WAVEFORM_PERF=1 swift test -c release --filter BoomBoomBoomKitBenchmarkTests.WaveformAnalyzerPerfTests`.
Without `BBB_WAVEFORM_PERF=1` the suite is skipped, so `make test` is unchanged.

## Band filter implementations

The baselines recorded so far use `scalar-biquad-double.v1`: a per-sample
biquad loop in Double (`BiquadCoefficients.apply(to:)`).

Nothing in this directory is promoted to `main` (see `_bmad-output/` entry in
CLAUDE.md Release Process).
