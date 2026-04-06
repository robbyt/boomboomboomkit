# Feature Request: Beat Grid Support for Hilbert

**From:** Hilbert (2manyDJs) — DJ mixing application for macOS
**Date:** 2026-04-05
**Context:** Epic 14 — Musical Sync & Beat Grid

---

## What Hilbert Is

Hilbert is a macOS DJ mixing app with real-time SharePlay collaboration. Two (or more) DJs on different machines share a session: loading tracks into a shared pool, controlling dual decks with crossfader mixing, and synchronizing playback across the network.

Hilbert already has:
- **Time-based sync** — PI-controller drift correction using position heartbeats at ~2Hz, with three-zone correction (dead zone <5ms, rate nudge 5-80ms via `RateNode`/VariSpeed, hard seek >80ms)
- **BPM detection** — via BoomBoomBoomKit, stored per-file in SwiftData with multi-detector versioning and user overrides
- **BPM display** — in deck UI, library browser, and session pool with sort-by-BPM

## How Hilbert Uses BoomBoomBoomKit Today

Single integration point — one actor wrapping the library:

```swift
actor BoomBoomBoomKitDetector: BPMDetectorProtocol {
    func detectBPM(fileURL: URL) async throws -> Float {
        guard let result = try AudioAnalysisService.analyzeBPM(url: fileURL) else { ... }
        return Float(result.bpm)
    }
    nonisolated var version: String { "boomboomboomkit-1.0" }
}
```

Called during library indexing (batch, not real-time). Results cached in SwiftData keyed by SHA256 + detector version. Re-analysis only on detector version change or file content change.

From `AudioAnalysisResult`, Hilbert currently uses:
- `bpm` — stored and displayed
- `confidence` — logged but not stored or displayed

## What Hilbert Needs for Musical Sync (Epic 14)

### The Problem

Time-based sync keeps two decks playing at roughly the same position, but it has no musical awareness. If Deck A plays a 128 BPM track and Deck B plays a 125 BPM track, time-based sync fights a losing battle — the decks drift apart because they're playing at different tempos.

Musical sync (CDJ-style auto-sync) solves this by:
1. **Tempo matching** — adjust Deck B's playback rate so both decks play at the same BPM (`rate = targetBPM / sourceBPM`)
2. **Phase alignment** — snap Deck B's beat 1 to align with Deck A's beat 1
3. **Continuous phase correction** — micro-correct drift quantized to musical divisions (nearest beat/bar boundary, not raw milliseconds)

Tempo matching only needs BPM (which we have). Phase alignment and beat-quantized correction need to know **where the beats fall** — specifically, where the first downbeat is relative to the start of the audio file.

---

## Requested API Additions

### Priority 1: First Downbeat Offset (Blocking for Epic 14)

Hilbert needs to construct a beat grid: given a BPM and a starting anchor point, compute where every beat falls in the track. The BPM is known. The missing piece is the anchor — the timestamp of the first downbeat (beat 1 of the first full bar).

**What Hilbert needs from the result:**

```
firstDownbeatOffsetMs: Double   // milliseconds from file start to first downbeat
```

This enables:
- `beatPosition(atTimeMs:)` — what beat number are we on at time T?
- `nearestBeatTime(toMs:)` — snap a seek position to the nearest beat
- Phase alignment — compute the phase difference between two decks' beat grids and correct it

**Accuracy requirements:**
- Within ~20ms is usable (a 128 BPM beat is 469ms long, so ±20ms is ~4% of a beat — DJs can hear worse)
- Within ~10ms is good
- Does not need to be perfect — Hilbert will expose a "beat grid nudge" UI for manual correction (±10ms buttons)

**Relevant internal state:** The onset detection pipeline (Step 3: mel-spectrogram, sub-band envelopes, kick/snare/crack/hihat extraction) already identifies where energy transients occur. The first downbeat is essentially "the first strong kick-band onset after the musical content begins."

### Priority 2: Time Signature (Useful, Defaultable)

Knowing beats-per-bar enables bar-level alignment (snap to bar boundaries, not just beat boundaries). Most DJ music is 4/4, so Hilbert can default to 4 if this isn't available.

**What Hilbert needs from the result:**

```
timeSignatureBeatsPerBar: Int   // 4 for 4/4, 3 for 3/4, etc.
```

**Accuracy requirements:**
- Distinguishing 4/4 from 3/4 covers the vast majority of cases
- If detection is unreliable, returning nil/0 and letting Hilbert default to 4 is fine

### Priority 3: Beat Confidence / Grid Quality (Nice to Have)

A quality signal for how trustworthy the beat grid is. If the onset pattern is irregular (live recording, ambient, spoken word), Hilbert could warn the user or fall back to time-based sync instead of musical sync.

**What Hilbert needs from the result:**

```
beatGridConfidence: Double   // 0.0–1.0, how periodic/regular the detected beats are
```

This could be derived from the existing confidence score, the periodicity clarity metric, or something beat-grid-specific. Not blocking — Hilbert can use BPM confidence as a proxy.

### Priority 4: Stable Clock Hint / DJ Mode (High Value for Accuracy)

DJ-produced music is almost universally quantized to a rigid, non-organic tempo grid. The BPM is locked to a DAW clock — it doesn't waver, drift, or breathe the way a live drummer's tempo does. Tempo changes within a DJ track are extremely rare, and when they occur they're deliberate (e.g., a breakdown that shifts BPM).

This is a strong prior that BoomBoomBoomKit could exploit. A "stable clock" or "DJ mode" hint would tell the analyzer:

- **Expect exactly one constant tempo for the entire track** — don't look for tempo changes or segments
- **Beat positions should fall on a perfectly regular grid** — deviations from the grid are noise, not musical expression
- **The first downbeat offset + BPM fully determines all beat positions** — no need for per-beat tracking
- **Onset timing jitter is instrumentation, not tempo variation** — a syncopated hi-hat at 128 BPM is still 128 BPM, even if the onset envelope looks irregular

This could improve both BPM accuracy (fewer octave errors from syncopation confusion) and downbeat detection accuracy (beat positions can be refined by finding the grid that best fits the onset envelope, rather than tracking individual onsets).

**What Hilbert needs from the API:**

An option or hint that can be passed to the analysis call, something like:

```
expectStableClock: Bool   // true = assume constant BPM, locked to DAW grid
```

Hilbert would always pass `true` — our use case is exclusively DJ/electronic music. Other consumers of BoomBoomBoomKit analyzing live recordings or classical music would leave it `false`.

**Potential benefits:**
- Constrained search space for downbeat detection (only need to find one offset, not track a moving target)
- Better octave disambiguation (a rigid 128 BPM grid that fits 500 onsets is more convincing than a wobbly 64 BPM grid)
- Simpler beat grid result (single offset + BPM, no variable-tempo handling needed)
- Possible accuracy improvement on the existing BPM pipeline for EDM/DJ content

### Priority 5: Beat Positions Array (Stretch Goal)

For tracks with tempo drift (live recordings, older tracks without click tracks), a constant-BPM beat grid is wrong. An array of actual beat timestamps would let Hilbert handle variable-tempo tracks.

**What Hilbert needs from the result:**

```
beatPositionsMs: [Double]?   // nil = constant BPM (use firstDownbeatOffset + BPM to compute grid)
```

This is genuinely a stretch goal. Constant-BPM beat grids cover 95%+ of DJ music. If the stable clock hint (Priority 4) is implemented, this becomes even less necessary for Hilbert's use case — but could be valuable for other consumers of the library analyzing live/organic recordings.

---

## API Shape Preferences (Not Prescriptive)

Hilbert doesn't care whether this is:
- A new method (`analyzeBeatGrid(url:)`) returning a new result type
- Additional fields on `AudioAnalysisResult`
- An option flag on `Options` that enables beat grid analysis alongside BPM

The wrapper in `BoomBoomBoomKitDetector.swift` is the only consumer, so any shape works. The key constraint is that the result must be `Sendable` (which all current BBBKit types already are).

**Performance budget:** Analysis happens during library indexing (batch, background). Current BPM detection takes 1-3 seconds per track. Adding a few hundred ms for downbeat detection is acceptable. Adding 5+ seconds would be noticeable for large library reindexes (10,000+ files).

**Failure mode:** If downbeat detection fails, returning nil is fine. Hilbert will let the user set the offset manually via the beat grid nudge UI. Graceful degradation, same as BPM detection failure today.

---

## Protobuf Fields (Already Reserved)

Hilbert's `TrackMetadata.proto` has these fields planned for Epic 14:

```protobuf
// Field 12: beat_grid_offset_ms (reserved for Epic 14)
// Field 13: time_signature (reserved for Epic 14)
```

The wire format is ready. We just need the analysis data to populate them.

## Timeline

Epic 14 is next in Hilbert's backlog. Story 14-1 (BeatGrid value type + downbeat detection) is the first story. No hard deadline, but having at least Priority 1 (first downbeat offset) available before Epic 14 implementation begins would unblock the entire epic.
