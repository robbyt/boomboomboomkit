---
title: 'Story 15.11 follow-up: band waveform API ergonomics'
type: 'refactor'
created: '2026-10-28'
status: 'done'
route: 'dispatch'
baseline_commit: '9a5d90c8f1a00ccdb3e65c9528d9bbccab49d0fe'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/15-11-waveform-band-levels.md (the story this amends; DD-3 bucket arithmetic, DD-8 init, DD-9/DD-10 format)'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Story 15.11 waveform API (PR #212, unmerged) is awkward to use. `WaveformBandLevel` (one bucket) and `WaveformBandLevels` (the whole result) differ by one letter. Storage goes through a static `decoded(from:)` rather than a Foundation-style failable init. Callers must redo the bucket time arithmetic themselves, and the obvious `i / 150` is wrong by up to a sample. Drawing code cannot loop over the three bands.

**Approach:** Owner-approved 2026-10-28, four changes on the same branch, with values and stored bytes unchanged: (1) `serializedData()` / `init?(serializedData:)`; (2) time helpers built on the reader's own timebase; (3) a band enum with a subscript; (4) a clear name family, `BandWaveform`.

## Boundaries & Constraints

**Always:** Measured values, the stored byte layout (magic, layout version 1, header fields, checksum, `analysisVersion`) and every decode check stay exactly as they are. Time helpers use the internal `WaveformBucketTimebase`, so they match the reader's arithmetic. Every query is total: invalid input returns `nil`, never traps. No em dashes. No third-party or app names in `Sources/`, `Tests/`, commits or PR text.

**Never:** Parallel filtering, decode pipelining, streaming callbacks, an `async` API, or `Codable` (all deferred or declined). No change to `analysisVersion`. No new error cases.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Round trip | any reader result `w` | `BandWaveform(serializedData: w.serializedData()) == w`, bytes identical to before the rename | N/A |
| Unusable bytes | every damaged or crafted row from 15.11 | `init?(serializedData:)` is `nil` | no trap |
| Bucket start | bucket `b` in `0..<count` | `Double(firstFrame(b)) / sampleRate` | N/A |
| Round-trip time | every bucket of a 10-minute length at 11,025, 44,100, 48,000, 96,000 Hz and one non-integral rate | `bucket(at: startTime(ofBucket: b)!) == b`, and `startTime(ofBucket: b)! <= t` for the returned bucket of any finite `t` in range | N/A |
| Out of range | `b < 0`, `b >= count`, `t < 0`, `t >= duration`, NaN, infinity, huge values | `nil` | no trap |
| Empty waveform | `frameCount == 0` | `duration == 0`; every query `nil` | N/A |
| Band subscript | `levels[.mid] = 0.5` | `levels.mid == 0.5`; `Band.allCases == [.low, .mid, .high]` | N/A |

</frozen-after-approval>

## Code Map

- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformBandLevels.swift` -- `WaveformBandLevel`, `WaveformAudioSource`, `WaveformBandLevels`, DD-8 init, internal reader init, `bucketCount(frameCount:sampleRate:)`.
- `.../WaveformBandLevelsFile.swift` -- `encoded()` / `decoded(from:)` and the private header types; the byte layout is untouched.
- `.../WaveformBandLevelReader.swift`, `.../WaveformBandLevelError.swift` -- renamed types; logic untouched.
- `.../WaveformBandFilter.swift` -- internal `WaveformBucketTimebase` (`bucket(atFrame:)`, `firstFrame(ofBucket:)`); reuse it, do not duplicate the formulas. Internal type names may stay.
- `Sources/BoomBoomBoomKit/PlayableBeatGrid.swift` -- the query style to copy: failable queries returning `nil` for non-finite or out-of-range input, documented in DocC.
- Tests: `Tests/BoomBoomBoomKitTests/WaveformBandLevel{Reader,Numeric}Tests.swift`, `WaveformBandLevelsFileTests.swift`, `Tests/BoomBoomBoomKitBenchmarkTests/WaveformBandLevelPerfTests.swift` -- 51 references to the old names across Sources, Tests, README and CLAUDE.md.
- Docs: `README.md` "Waveform levels" and "Caching waveforms" sections and the Public API table; `CLAUDE.md` roster lines 238-241; `_bmad-output/project-context.md:21` names `WaveformBandLevelsFile.swift`.

## Tasks & Acceptance

**Execution:**
- [x] Rename, with files renamed to match: `WaveformBandLevels` → `BandWaveform`; `WaveformBandLevel` → `BandWaveform.Levels` (nested; `.silent` kept); `WaveformAudioSource` → `BandWaveform.Source`; `WaveformBandLevelReader` → `BandWaveformReader`; `WaveformBandLevelError` → `BandWaveformError`. Source files become `BandWaveform.swift`, `BandWaveform+Serialization.swift`, `BandWaveformReader.swift`, `BandWaveformError.swift`; test files `BandWaveform{Reader,Numeric,Serialization}Tests.swift` and `BandWaveformPerfTests.swift`. The Makefile target `waveform-band-perf-baseline`, its env var `BBB_WAVEFORM_BAND_PERF` and the `perf-baselines/waveform-band/` folder keep their names.
- [x] `BandWaveform+Serialization.swift` -- `public func serializedData() -> Data` and `public init?(serializedData data: Data)`, replacing `encoded()` / `decoded(from:)`.
- [x] `BandWaveform.swift` -- `public enum Band: String, CaseIterable, Sendable, Hashable { case low, mid, high }` nested in `BandWaveform`; `public subscript(band: Band) -> Float { get set }` on `Levels`.
- [x] `BandWaveform.swift` -- `public var duration: Double` (`Double(frameCount) / sampleRate`); `public func startTime(ofBucket bucket: Int) -> Double?`; `public func bucket(at seconds: Double) -> Int?`. `bucket(at:)` takes the frame at `seconds` (floor of `seconds * sampleRate`, corrected upward by one when that frame's own start time is not after `seconds`, so it inverts `startTime`) and maps it through `WaveformBucketTimebase`. DocC states the range rules and that bucket `i` does not start at exactly `i / 150` s.
- [x] First, before any rename: serialize a small hand-built waveform with the current code and embed its bytes (base64) in a test that must still decode them, equal, after the rename.
- [x] Tests -- every matrix row; existing tests updated to the new names with assertions unchanged.
- [x] `README.md`, `CLAUDE.md` roster, `_bmad-output/project-context.md:21`, DocC -- new names and APIs; the README bucket loop uses `startTime(ofBucket:)` instead of `i / bucketsPerSecond`.
- [x] `_bmad-output/implementation-artifacts/15-11-waveform-band-levels.md` -- one Spec Change Log entry pointing to this spec; no other edits.

**Acceptance Criteria:**
- Given the full test run, when it finishes, then the 15.11 tests pass under the new names with their assertions unchanged, plus the new tests.
- Given `grep -rn -E "WaveformBandLevels?\b|WaveformAudioSource|WaveformBandLevelReader|WaveformBandLevelError|\.encoded\(\)|decoded\(from:" Sources Tests README.md CLAUDE.md`, then no output.
- Given a waveform serialized before this change, when decoded after it, then it decodes equal (byte layout unchanged; a test keeps one fixed serialized blob).

## Design Notes

Names: one family read as "a waveform made of bands". `BandWaveformReader.read(url:)` returns a `BandWaveform`; `waveform.peak[i]` is a `BandWaveform.Levels` with `low`, `mid`, `high` and `[.mid]`. Nesting `Levels`, `Source` and `Band` keeps the top-level namespace to three types plus the error, the way `AudioAnalysisService.Options` is nested.

## Verification

**Commands:**
- `swift test --filter BandWaveform` -- green.
- `make test` -- green; count equals the previous 1,286 plus the new tests.
- `make fmt && make lint` -- no changes; only the pre-existing `PerformanceBenchmarkTests.swift:139` warning.
- `make docc-validate` -- pass.
- After commit: `make release-rehearse RELEASE_REHEARSE_REF=HEAD` -- passes on the final commit.

## Implementation Notes

- `bucket(at:)` corrects the floored frame in both directions, not only upward as the Tasks line says: `seconds * sampleRate` can round up to the next whole frame, and without the downward step the matrix row "`startTime(ofBucket: b)! <= t`" fails at all five rates. The DocC states the rule as "the last frame whose start time is not after `seconds`". Removing either correction fails the time tests (478 and 33,146 failures in the reviewer's replica).
- Kept as historical records with the old names: the perf baseline JSON (its `encodedMs` / `decodedMs` keys are kept so old baselines stay comparable) and the history sections of the 15.11 spec.

## Review Triage Log

| # | Finding (reviewer) | Verdict | Evidence | Route |
|---|---|---|---|---|
| 1 | `deferred-work.md:1539`, `:1547` still name the old types (edge case, blind, verification gap) | low | Confirmed by grep; the acceptance grep does not cover that file. Direct correction. | patch |
| 2 | Prose says "levels" / "encodes" / "decoding" where it now means a `BandWaveform` or serialization (blind) | low | Confirmed at `BandWaveformReader.swift` Returns line and the listed docs; ambiguous next to the `Levels` type. Direct rewording. | patch |
| 3 | Test locals holding a `BandWaveform` still named `levels` (blind) | low | Confirmed; reads as a field of `Levels`. Mechanical rename on touched lines. | patch |
| 4 | Time-test comment lists the wrong rates (blind) | low | The numeric suite checks 44,100, 48,000, 96,000, 18,000 and 18,001. | patch |
| 5 | Time tests only check the two queries against each other (blind) | low | The timebase is pinned separately (`BandWaveformNumericTests.swift:222-258`), but nothing ties `startTime` to the `i / 150` definition at every rate. Cheap bound check. | patch |
| 6 | No range query or bucket end time (blind) | low | Not one of the four owner-approved items. | reject (noted for the owner) |
| 7 | No helper for the silent tail after an early end of file (blind) | low | Queries follow the header's `frameCount` as documented; callers have `framesRead`. | reject |
| 8 | Spec Tasks line describes `bucket(at:)` as upward-only (blind) | low | Fix would edit this spec; recorded in Implementation Notes instead. | reject |
| 9 | Neither correction branch shown to run (blind) | false | The verification-gap reviewer removed each branch in a replica: 478 and 33,146 failures. | reject |
| 10 | `Band.high` doc reads as if the band is dropped at 18 kHz and below (blind) | low | Only the 9,000 Hz low-pass is left out. Direct correction. | patch |
| 11 | Perf JSON keys `encodedMs` / `decodedMs` now confusing (blind) | low | Kept on purpose so old baselines compare; renaming adds churn for no user. | reject |
| 12 | `startTimeRoundTrips` can record hundreds of thousands of failures (blind) | low | `#expect` inside 90,000-iteration loops. Direct fix: count and assert once. | patch |
