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
the implementation of the band filter passes, so two files with different
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

| `filterImplementation` | Filter code | 30 s min / median (ms) | 300 s min / median (ms) | 600 s min / median (ms) | Files |
|---|---|---|---|---|---|
| `scalar-biquad-double.v1` | Per-sample Double loop, four passes, Float output per pass, Float RMS | 10.6 / 10.6 to 10.7 | 105.9 to 106.6 / 106.4 to 106.8 | 211.8 to 214.0 / 212.1 to 227.4 | `d9066ed0b0-2026-10-21T01-58-22Z.json`, `d9066ed0b0-2026-10-21T01-58-26Z.json` |
| `vdsp-biquad-double.v1` | `vDSP.Biquad` in Double, three passes, Double RMS | 4.1 / 4.2 | 41.0 to 41.3 / 41.4 | 82.2 to 82.3 / 83.4 | `d9066ed0b0-dirty-2026-10-21T02-02-13Z.json`, `d9066ed0b0-dirty-2026-10-21T02-02-15Z.json` |

Both rows are release config on the same arm64 host. The `vdsp-biquad-double.v1`
files carry `d9066ed0b0-dirty` because they were recorded from the uncommitted
change; the code they measure lands in the commit after `d9066ed`. The minimum
drops by a factor of 2.6 at every duration.

Mechanism: the input is converted to Double once with `vDSP_vspdp`, each band
runs through a vectorised `vDSP.Biquad` IIR in Double, the mid band's high-pass
and low-pass run as one two-section cascade instead of two passes, and per-bin
RMS is taken on the Double output with `vDSP_rmsqvD`, so no pass converts the
filtered signal back to Float. Transient peak memory at 600 s rises from about 320 MB to about 530 MB, because the shared Double input copy and the one live Double band output are 8 bytes per sample; band outputs are temporaries released before the next band runs.

Nothing in this directory is promoted to `main` (see `_bmad-output/` entry in
CLAUDE.md Release Process).
