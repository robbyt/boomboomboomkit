# beatgrid-timing baselines

Per-SHA snapshots of the Story 15.2 timing probe. Each file is a complete record
of the 24 (sample rate x phase offset x waveform x path) fixture rows at the
tagged commit, produced by `Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift`.

## File naming

```
<short-sha>-<ISO-8601 timestamp>.json
```

The short SHA is `git rev-parse HEAD` truncated to 10 characters. The timestamp
is UTC, with colons replaced by hyphens so the filename is portable.

## Reading

The file is a single JSON object:

```jsonc
{
  "schemaVersion": 1,
  "commitSHA": "...",
  "createdAt": "2026-10-17T...",
  "platform": "...",
  "probeSource": "Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift",
  "intensityLevel": "level3",
  "reproductionBoundsMs": {"lower": -17.5, "upper": -6.0},
  "fixtures": [
    { "path": "known-tempo" | "public-facade",
      "sampleRate": 44100 | 48000,
      "offsetSamples": 0 | halfHop | fullHopMinusOne,
      "waveform": "single-impulse" | "64-sample-exp-decay",
      "estimatedBPM": 120.0...,
      "gridConfidence": 0...1,
      "beatCount": 24,
      "interiorCount": ~22,
      "meanBeatConfidence": 0...1,
      "gridOriginSignedErrorMs": -17.5...-6.0,
      "interiorMedianSignedErrorMs": -17.5...-6.0,
      "interiorMinSignedErrorMs": ...,
      "interiorMaxSignedErrorMs": ... },
    ...
  ]
}
```

All signed error fields are in milliseconds relative to the planted-impulse
time at 120 BPM (0.5 s beat period). A negative value means the detector
reported the beat earlier than the planted impulse.

## Reproducing

```
BBB_BEATGRID_TIMING_BASELINE=1 swift test --filter BeatGridTimingBaselineTests
```

or `make beatgrid-timing-baseline`.

## Pre-fix and post-fix baselines

`9fd205546a-2026-10-18T02-36-19Z.json` is the pre-fix snapshot. It is kept as
the historical record of the 40 to 50 ms early measurement taken before the
frame-time convention fix.

Story 15.3 (frame-time convention, landed) moved the error to the band the suite
now asserts: `[-17.5, -6.0]` ms for both `gridOriginSignedErrorMs` and
`interiorMedianSignedErrorMs`. `f117ea37a8-2026-10-18T02-55-06Z.json` is the
post-fix snapshot. The 24 rows cluster in `[-16.78, -6.76]` ms.

The remaining residual is a constant offset per fixture of about one hop (10 ms)
early. It depends on waveform shape (single impulse vs 64-sample exp decay) and
hop phase, and sub-frame interpolation cannot remove it.

A new baseline recorded on a later SHA is expected to fall inside the current
band.

Nothing in this directory is promoted to `main` (see `_bmad-output/` entry in
CLAUDE.md Release Process).
