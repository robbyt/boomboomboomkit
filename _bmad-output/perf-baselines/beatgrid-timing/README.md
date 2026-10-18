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
  "reproductionBoundsMs": {"lower": -50.5, "upper": -39.5},
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
      "gridOriginSignedErrorMs": -50.5...-39.5,
      "interiorMedianSignedErrorMs": -50.5...-39.5,
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

## When these baselines move

Phase 3 (Story 15.3) will land the frame-time convention fix. When it does,
the next baseline on that SHA records the tight new error band (expected to
be single-digit milliseconds). At that point the reproduction bounds in
`BeatGridTimingBaselineTests.swift` must be updated to the tight band and the
old baselines are kept here as the pre-fix record.

Nothing in this directory is promoted to `main` (see `_bmad-output/` entry in
CLAUDE.md Release Process).
