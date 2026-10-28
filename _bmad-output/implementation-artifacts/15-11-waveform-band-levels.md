---
title: 'Story 15.11: Three-band waveform levels read from a file, and a file format for caching them'
type: 'feature'
created: '2026-10-27'
status: 'done'
route: 'dispatch'
review_loop_iteration: 1
baseline_commit: '24746dd'
context:
  - '/Users/rterhaar/Dropbox/research/swift/2manyDJs/_bmad-output/planning-artifacts/bbbk-waveform-analysis-handoff.md (the handoff; section 3 is the measurement contract)'
  - 'Reference reader: git -C /Users/rterhaar/Dropbox/research/swift/2manyDJs show 639fd62b:2manyDJs/Hilbert/Audio/Analysis/AVAudioFileWaveformReader.swift'
  - 'Reference tests: git -C /Users/rterhaar/Dropbox/research/swift/2manyDJs show 639fd62b:2manyDJs/HilbertTests/Audio/AVAudioFileWaveformReaderTests.swift'
  - '/Users/rterhaar/Dropbox/research/swift/rekordboxReader/docs/rekordbox-waveform-cache-format/README.md (background only)'
---

Epic 15, Story 15.11. New number: 15.4a and 15.4b were phases of `WaveformAnalyzer`'s own outputs, and this is a different measurement. 15.12 (planned) removes `WaveformAnalyzer` once Hilbert runs on this reader.

<frozen-after-approval reason="human-owned intent, do not modify unless human renegotiates">

## Intent

**Problem.** Hilbert measures each track's low, mid and high band peak and RMS (150 values per second) with its own reader and re-reads the whole file on every deck load: about 217 ms for a 10-minute stereo WAV and 736 ms for a FLAC at Hilbert `639fd62b`. The owner wants that measurement in BBBK and wants it cached on disk under Hilbert's existing cache limit and Clear Cache button.

**Approach.** BBBK ships two things: (1) a streaming reader, `WaveformBandLevelReader.read(url:options:)`, that matches Hilbert's reader bit for bit on the same machine, and (2) a versioned binary file format for the result, `encoded()` / `decoded(from:)`, which owns every rule for whether stored bytes are still usable. Hilbert owns the cache folder, the writes, the listing, eviction, and the buttons. The production library writes nothing to disk.

## Scope

**In:** the reader; the result types; the file format; one new error type; ported Hilbert reader tests, independent numeric checks and format tests; a benchmark; a one-off parity and timing run against Hilbert's reader from the scratchpad, never committed (DD-12); DocC, README, CLAUDE.md roster and project-context updates; sprint-status rows.

**Out:** see "Out of scope" at the end. In short: no disk store, no change to `WaveformAnalyzer`, nothing in Hilbert, no copy of Hilbert's reader anywhere in this repository.

**Done** means every check in this spec passes and the owner has the commit SHA that passed the release rehearsal. BBBK's tests are not proof of parity with Hilbert's reader; the binding bit-exact comparison and the head-to-head timing run in the Hilbert migration story, before Hilbert deletes its reader.

## Operator decisions (2026-10-27)

1. BBBK ships the reader and the file format; Hilbert owns the store, its folder, eviction and the buttons. The production library writes nothing to disk.
2. `WaveformAnalyzer` (Story 15.4) is untouched here and removed in a separate story (15.12) after Hilbert runs on this reader, once a fresh check confirms nothing uses it.
3. At spec approval: story numbers 15.11 and 15.12 kept; one new error type with distinct cases; old-version or damaged files are unusable, and Hilbert deletes and re-measures them; Float32 payload.
4. At spec approval: no copy of Hilbert's reader in BBBK, not even for tests. BBBK becomes the owner of this measurement and Hilbert's reader is deleted after migration, so BBBK's correctness is defined by its own tests, not by a frozen copy of the app's code (DD-12).

## Boundaries and constraints

**Always:** the measurement exactly as DD-3 states it. Chunk size 65,536 frames and 150 buckets per second are constants, never options. Every new public type `Sendable`. No em dashes or emojis in anything written. No third-party or app names (rekordbox, Hilbert, the rekordboxReader repo) in `Sources/`, `Tests/`, commit messages or PR text; this spec may name them.

**Ask first:** any public name other than those in DD-2 and DD-7. Handing over a SHA when the one-off scratchpad run (DD-12) shows any bit difference from Hilbert's reader, or this reader slower than it on either format. Any change to `PCMBufferReaderError`, `WaveformAnalyzer`, or the existing waveform records.

**Never:** write to disk from `Sources/BoomBoomBoomKit`; choose a folder; read `UserDefaults`; add a progress callback; reuse `WaveformAnalyzer.computeBinStartSamples` or its `vDSP_rmsqvD` RMS path; edit any Hilbert or rekordboxReader file; edit `scripts/promote-to-main.py`; copy Hilbert's reader, or any part of its DSP, into any file in this repository.

</frozen-after-approval>

## Key Design Decisions

- **DD-1 Value types, static methods.** The reader is a caseless enum with one static `read`. The format is two members on the result type (an instance `encoded()` and a static `decoded(from:)`). No instance holds state or a folder, so no second exception to project-context `:32` is needed. Rejected: the handoff's `WaveformLevelStore` struct holding a folder (operator decision 1).

- **DD-2 Public surface.** In `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/`:
  ```swift
  public struct WaveformBandLevel: Sendable, Hashable {
    public var low, mid, high: Float
    public init(low: Float, mid: Float, high: Float)
    public static let silent: WaveformBandLevel
  }
  public struct WaveformAudioSource: Sendable, Hashable {
    public let formatID: UInt32          // the file's mFormatID, from fileFormat (not processingFormat)
    public let processingFormat: String  // DD-6
    public init(formatID: UInt32, processingFormat: String)
  }
  public struct WaveformBandLevels: Sendable, Hashable {
    public let peak: [WaveformBandLevel]
    public let rms: [WaveformBandLevel]
    public let bucketsPerSecond: Double  // always WaveformBandLevelReader.bucketsPerSecond
    public let sampleRate: Double
    public let channelCount: Int
    public let frameCount: Int64         // from the file header
    public let framesRead: Int64         // frames that went into buckets; < frameCount when the file ended early
    public let analysisVersion: String   // always WaveformBandLevelReader.analysisVersion
    public let source: WaveformAudioSource
    public init?(peak:rms:sampleRate:channelCount:frameCount:framesRead:source:)  // DD-8
    public func encoded() -> Data                                        // DD-9, never throws
    public static func decoded(from data: Data) -> WaveformBandLevels?   // DD-10
  }
  public enum WaveformBandLevelReader: Sendable {
    public static let bucketsPerSecond: Double = 150
    public static let analysisVersion = "band-peak-rms.loudest-channel.v1"
    public struct Options: Sendable {
      public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }
      public init() {}
    }
    public static func read(url: URL, options: Options = Options()) throws -> WaveformBandLevels
  }
  public enum WaveformBandLevelError: Error, Sendable, LocalizedError  // DD-7
  ```
  `Hashable` is safe: the init and the decoder admit only finite values, so no NaN reaches `==`.

- **DD-3 The measurement, normatively.** Handoff section 3 and the reference reader are the provenance; this list is the contract the implementer codes against. Exactness is required on the same machine only: commit `cd422b1` records DSP output that differs by macOS version, so cross-OS equality is not a goal.
  - **Open and check, in this order.** `AVAudioFile(forReading: url)`; `format = file.processingFormat`, `Fs = format.sampleRate`; refuse unless `Fs.isFinite && Fs > 6_000` (`unsupportedFormat`); refuse when `Double(file.length) / Fs > 43_200`, 12 hours (`durationTooLong`), so a damaged header cannot size the output arrays (a FLAC header can claim 68.7 billion frames, about 5.6 GB of output); allocate one `AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 65_536)`; compute `bucketCount` from `file.length` and allocate `peak` and `rms` filled with `.silent`; build one filter set per channel (refuse when a `vDSP.Biquad` returns nil). Both refusals come before any allocation sized by the header. Only then loop, so an unusable rate throws before cancellation is checked.
  - **Chunks.** `while file.framePosition < file.length`: if `options.isCancelled()` throw `CancellationError()`; `chunkStart = file.framePosition` (never a counter); `file.read(into: buffer, frameCount: AVAudioFrameCount(min(file.length - chunkStart, 65_536)))`. On a throw: if `chunkStart > 0` and the raw error is `NSOSStatusErrorDomain` code `-39`, stop and keep everything; otherwise throw (DD-7). After the read: `n = Int(buffer.frameLength)`; if `n == 0` or `floatChannelData == nil`, stop. Otherwise add `n` to `framesRead`, filter every channel, then walk spans.
  - **Filters, per channel.** Constants: low-pass 300; mid high-pass 250 then low-pass 1,200; high high-pass 3,000 then, only when `Fs > 18_000`, low-pass 9,000; `quality = 0.5.squareRoot()` (not `1 / 2.0.squareRoot()`, one ulp lower). For a section at `cutoff`: `omega = 2 * Double.pi * cutoff / Fs`; `cosine = cos(omega)`; `alpha = sin(omega) / (2 * quality)`. Low-pass: `b = (1 - cosine) / 2`, section `[b, 1 - cosine, b, -2 * cosine, 1 - alpha]`. High-pass: `b = (1 + cosine) / 2`, section `[b, -(1 + cosine), b, -2 * cosine, 1 - alpha]`. Each section then `.map { $0 / (1 + alpha) }`. Mid and high concatenate their sections high-pass first into one array for one `vDSP.Biquad(coefficients:channelCount: 1, sectionCount:ofType: Double.self)`; low is one section. Filter sets are built once per read and keep their state across chunks. Per chunk and channel: convert the `n` samples to Double (DD-4), then `apply(input:output:)` over exactly those `n` samples, low then mid then high, each into its own Double output buffer.
  - **Buckets.** `bucket(f) = Int((Double(f) * 150 / Fs).rounded(.down))` for an absolute frame `f`; `firstFrame(b) = Int64((Double(b) * Fs / 150).rounded(.up))`; `bucketCount(n) = n > 0 ? bucket(n - 1) + 1 : 0`. Evaluate left to right exactly as written (`150` is the `bucketsPerSecond` constant). Span walk within a chunk: `offset = 0`; while `offset < n`: `b = bucket(chunkStart + offset)`; `end = max(offset + 1, min(n, Int(firstFrame(b + 1) - chunkStart)))`; stop if `b >= bucketCount`; process `offset..<end`; `offset = end`.
  - **Peak.** Per span: start from the stored `peak[b]`; for each channel in order, `low = max(low, Float(min(maxmgvD(lowSpan), 1)))`, then mid, then high (`vDSP_maxmgvD`); store.
  - **RMS.** Running state: the open bucket index, one frame count, and per channel three Double sums. Per span: if `b` differs from the open bucket, set it, zero the frame count and every sum. Then `frames += span.count`; for each channel in order, `low += svesqD(lowSpan)`, `mid += ...`, `high += ...` (`vDSP_svesqD`, one call per span; never one call over a bucket that crosses a chunk). Then write `rms[b]`: per band `loudest = channels.reduce(0) { max($0, $1.band) }`, value `Float(min((loudest / Double(frames)).squareRoot(), 1))`, `.silent` when `frames == 0`.
  - **Result.** `frameCount = file.length`; `framesRead` as above (equal to `chunkStart` of the chunk where an early end, a 0-frame chunk or a nil-data chunk stopped the loop). A 0-frame header gives empty arrays and no error even when `isCancelled` is already true, because the loop never runs.

- **DD-4 Non-finite input through vDSP.** Convert with `vDSP.convertElements(of:to:)` (or `vDSP_vspdp`) over exactly `n` samples into the reused Double input buffer, then, only if that chunk contains a non-finite sample, a scalar loop writes `+0.0` over each non-finite sample. Finite Float to Double is exact and finite signed zeros stay as they are, so the bits match the reference's `sample.isFinite ? Double(sample) : 0`. Detection is a scalar `contains(where:)` scan, as at `PCMBufferReader.swift:333-350` (which explains why a `vDSP_sve` sum check is not used). This is the same documented exemption from the vDSP rule (project-context `:22`).

- **DD-5 Internal filter types.** `WaveformBandFilter`, `WaveformBucketTimebase` and `WaveformBucketSums` (internal; names may change) mirror the reference's three helpers, so the ported tests that drive the filter and the timebase directly (`@testable import`) keep their meaning. The filter exposes its high band's section count for the 18 kHz boundary test. Rejected: sharing any helper with `WaveformAnalyzer` (different coefficient expression, bucket rule, chunking and RMS accumulation).

- **DD-6 Provenance.** `source.formatID` is `file.fileFormat.streamDescription.pointee.mFormatID` (as `PCMBufferReader.swift:111`), so a FLAC reports the FLAC codec, never linear PCM. `source.processingFormat` is built from fields, never `AVAudioFormat.description`: `"<commonFormat> <interleaved|deinterleaved> <channelCount>ch <sampleRate>Hz"`, `commonFormat` one of `float32`, `float64`, `int16`, `int32`, `other`, and `sampleRate` rendered with Swift's `Double.description` (locale-independent, shortest round-trip; `44100.0`, `11025.0`, `18001.0`). Example: `"float32 deinterleaved 2ch 44100.0Hz"`. Diagnostics only; nothing invalidates on it (owner default, handoff question 4).

- **DD-7 Errors.** One new public type, `WaveformBandLevelError`, two cases, both thrown only by the reader, with readable `errorDescription`s because Hilbert logs `localizedDescription`:
  - `unsupportedFormat(URL, sampleRate: Double)`: sample rate not finite or `<= 0`, at or below 6,000 Hz, or a `vDSP.Biquad` that fails to build.
  - `durationTooLong(URL, seconds: Double)`: the file's header claims more than 12 hours (owner decision at review, 2026-10-27). A real 4-hour mix needs about 52 MB of output; 12 hours caps it near 155 MB.

  Encoding and decoding never throw (2026-10-28): the format takes no key, and DD-8's bounds make an oversized header unreachable, so `encoded()` only `assert`s the header size. `invalidKey` and `headerTooLarge` were removed.

  Existing cases are reused where they fit: `AVAudioFile(forReading:)` failure throws `PCMBufferReaderError.fileNotReadable(url)`; a nil `AVAudioPCMBuffer` throws `.bufferAllocationFailed(url)` (the reference calls this unsupported format; BBBK's existing case is the more accurate name); any read error that is not the early-end case, including -39 at `chunkStart == 0`, throws `.readFailed(url, underlyingDescription:)`. The -39 test runs on the raw `NSError` before any wrapping. Cancellation throws `CancellationError`, never `WaveformAnalyzerError.cancelled`. `PCMBufferReaderError` itself is unchanged. Recorded per project-context `:39`.

- **DD-8 One validating init.** The public failable init enforces every invariant: `peak.count == rms.count == bucketCount(frameCount)` (DD-3 formula, through `Int(exactly:)` and a checked `+ 1`); `sampleRate` finite and `> 6_000`, checked before the bucket count is computed; `channelCount >= 1`; `frameCount >= 0`; `0 <= framesRead <= frameCount`; every value finite and in `0...1`; `source.processingFormat` at most 256 UTF-8 bytes. That bound keeps every accepted result's header far under the 65,536-byte limit (every other header field is fixed-size or bounded), so everything the init accepts encodes and decodes. `bucketsPerSecond` and `analysisVersion` are set to the current constants, never passed in. The decoder builds its result through this init. The reader builds through an internal init that skips the value scan (its values are finite and clamped by construction) and `assert`s the counts. The public init lets Hilbert's adapter tests build levels without a file.

- **DD-9 File format.** The format carries no cache key (owner change, 2026-10-28): the caller chooses the key and the store (a folder, a database blob, memory), and BBBK never stores anything or hashes the audio file. The encoding's own integrity is the checksum below. Little-endian throughout; every multi-byte value written and read byte by byte; offsets are relative to the first byte of the supplied `Data` (parse through `withUnsafeBytes`, never by `data[i]` on a slice that may not start at 0):

  | Offset | Bytes | Content |
  |---|---|---|
  | 0 | 8 | magic, ASCII `BBBKWAVE` |
  | 8 | 4 | `UInt32` layout version, `1` |
  | 12 | 4 | `UInt32` header byte count `H`, `1...65_536` |
  | 16 | 32 | SHA-256 (CryptoKit) over bytes `0..<16` followed by bytes `48..<end` |
  | 48 | H | header, UTF-8 JSON |
  | 48 + H | P | payload: `peak` then `rms`, each bucket `low, mid, high`, each value its `Float.bitPattern` as 4 LE bytes; `P = bucketCount * 24` |

  Nothing follows the payload. The checksum covers the header too, so any damage to the header or payload is caught by one comparison; the structural checks below still run, because a crafted file can carry a valid checksum. Header keys written: `analysisVersion`, `bucketsPerSecond`, `sampleRate`, `channelCount`, `frameCount`, `framesRead`, `bucketCount`, `source` (`formatID`, `processingFormat`), `elementType` (`"float32le"`), `payloadByteCount`, and three diagnostic fields: `filterBank` (`{"lowPassHz":300,"midHighPassHz":250,"midLowPassHz":1200,"highHighPassHz":3000,"highLowPassHz":9000,"highLowPassUsed":<bool>,"quality":<Double>}`), `osVersion` (`ProcessInfo.operatingSystemVersionString`), `createdAt` (ISO 8601 string). The decoder declares only the non-diagnostic keys, so the diagnostic fields can never invalidate a file; unknown keys are ignored and key order does not matter. No BBBK version or commit: there is no cheap runtime source, and `analysisVersion` decides validity. Key choice, file naming and storage are the caller's; the README shows a file-identity key and a content-hash key, a folder store and an in-memory store.

- **DD-10 nil means discard.** `decoded(from:)` never throws. It returns nil for any bytes that cannot be used, and nil always means the caller should discard the stored bytes and measure again. Every byte-based row of handoff 4.3 is a delete, and an `analysisVersion` mismatch is a delete too (the handoff left that open; one rule, and the space is freed at once). Order: `data.count >= 48`; magic; layout version `== 1`; `H` in `1...65_536` and `48 + H <= data.count`; checksum over the bytes in place; JSON decodes (allocations bounded by `H`); `elementType`; `analysisVersion` current; `bucketsPerSecond == 150`; `sampleRate` finite and `> 6_000`; recomputed bucket count (DD-8) equals the header's; `channelCount >= 1`; `frameCount >= 0`; `framesRead` in `0...frameCount`; `payloadByteCount == bucketCount * 24` (overflow-checked) and `== data.count - 48 - H`; only then allocate the two output arrays and read the floats; DD-8's init accepts them. No allocation sized by a header count happens before the payload length has matched the bytes actually present. The duplicate-key behavior of `JSONDecoder` is accepted: with the header inside the checksum, a duplicate key only appears in a deliberately crafted file, and every value still passes the checks above.

- **DD-11 The source-file check belongs to Hilbert.** The handoff's `checkingAgainst:` row (open the audio file and compare sample rate, channel count and length with the stored levels) is a "miss, keep the file" case and needs the file, so it moves to Hilbert, which compares `levels.sampleRate`, `channelCount` and `frameCount` with an `AVAudioFile` it opens. The benchmark measures that open for FLAC, WAV, MP3 and M4A so Hilbert's spec can decide whether to keep it.

- **DD-12 Verification without a copy of the app's reader.** BBBK owns this measurement from now on, and Hilbert's reader is deleted after migration, so nothing in this repository copies it (operator decision 4). Correctness here rests on three things: (a) the 31 ported behavioral tests; (b) independent numeric checks written from DD-3, not from the app's code: `quality`'s `Double.bitPattern` pinned to `0x3FE6A09E667F3BCD` (`1 / 2.0.squareRoot()` gives `...3BCC`); every section's coefficients equal to the closed-form RBJ cookbook values at 44.1, 48 and 96 kHz and at 18,000 / 18,001 Hz; each band's output on a seeded noise signal equal, within `1e-9` relative to the signal's peak, to a test-local scalar Double direct-form biquad cascade (a `Float` filter misses that by orders of magnitude); bucket boundaries from DD-3's formulas checked against hand-computed values at 11,025, 44,100, 48,000 and 96,000 Hz; a bucket split by the 65,536 boundary whose peak and RMS equal those computed by the test-local cascade over the whole signal (RMS within `1e-6`); (c) the format tests. These cannot promise to catch every one-bit change to the DSP, which is why the binding bit-exact check runs in Hilbert while both readers exist (Hilbert spec inputs).

  **One-off scratchpad run, not committed.** Before the SHA is handed over, a throwaway Swift package in the session scratchpad depends on this worktree by path, embeds Hilbert's reader read from `639fd62b` with `git show` (the scratchpad is outside both repositories), and runs both readers on the same files on this machine: the ported test signals, every bundled fixture, and synthetic files at 11,025, 18,000, 18,001, 44,100, 48,000 and 96,000 Hz, mono, stereo and six channels. It compares every peak and RMS `bitPattern` plus `bucketCount`, `frameCount` and `framesRead`, and times both readers on the 10-minute stereo WAV and FLAC (warm-up then the median of 5, Release). Its report (counts compared, mismatches, both medians per format, OS and SHAs) goes in Implementation Notes; the package is deleted afterwards. It catches a mismatch now instead of in the Hilbert story; it does not replace that story's gate.

  **Synthetic-file writers in TestSupport, `package` access.** The unit tests and the benchmark both need to write test audio, so the writers go in `Sources/BoomBoomBoomKitTestSupport/SyntheticAudioFiles.swift`, every declaration the tests call marked `package` (both test targets reach it; package consumers cannot). They are test-file writers that come with the ported tests, not measurement code, and are written as BBBK code with no app names in comments. The writers from the reference tests (`writeFile` both overloads, `writeToneFLAC`, `writeSilentWAV`, `truncate`, `flacAudioStart`, `sine`, `noiseAndTones`) are re-created there with what they depend on: the test-file description type (`TestFile` in the original), its constants (`bucketFrames`, `flacTailCut`, `firstFrameBytesKept`, `toneSeconds`), and plain throwing `guard`s in place of `#require` (TestSupport does not import Testing). Additions: (a) a 16-bit integer WAV mode for the benchmark, beside the 32-bit float mode the NaN, infinity and above-full-scale tests need; (b) more than two channels, through an explicit `AVAudioChannelLayout` (six channels: a 5.1 layout tag) and `AVAudioFormat(commonFormat:sampleRate:interleaved:channelLayout:)`, because `AVAudioFormat(standardFormatWithSampleRate:channels:)` returns nil above two channels; (c) every writer reopens its file and throws unless the sample rate, channel count and length read back as requested. If `AVAudioFile` will not write a rate the tests need (18,000 or 18,001 Hz, for example), the writer falls back to a hand-written PCM WAV header, as the original `writeSilentWAV` does for 6 kHz.

  Rejected: a copy of the app's reader in TestSupport as a permanent oracle (it would ship to `main` and define BBBK's correctness as matching a frozen copy of the app's code, after the app itself has dropped it); committed golden output values (`cd422b1` shows DSP bits change across macOS versions, and they would still be the app's answer); a develop-only copy (still a duplicate needing a planned deletion); the writers in the unit-test target (the benchmark target could not reach them); a promotion carve-out (CLAUDE.md treats every carve-out as a smell).

## I/O and edge-case matrix

| Scenario | Input | Expected |
|---|---|---|
| Silent second | 1 s zeros, stereo 44.1 kHz | 150 buckets, every peak and RMS `.silent` exactly |
| Zero-frame header | header length 0, `isCancelled` already true | empty arrays, `framesRead == 0`, no throw |
| Pre-cancelled | 1 s file, `isCancelled` true | `CancellationError` |
| Cancel after first chunk | 2 s file, `isCancelled` true from the second check | `CancellationError` |
| Rate too low | hand-written 6 kHz mono WAV | `WaveformBandLevelError.unsupportedFormat` |
| Rate 6 to 8 kHz | hand-written 7 kHz WAV | measured, 9 kHz section left out |
| 18 kHz boundary | 18,000 and 18,001 Hz, 5 kHz tone plus noise | high band has one section at 18,000 and two at 18,001; each band equals the test-local cascade (DD-12 b) |
| Not audio | `"not audio"` saved as `.wav` | `PCMBufferReaderError.fileNotReadable` |
| First read fails | FLAC cut to its audio start + 10 bytes | `PCMBufferReaderError.readFailed` |
| File ends early | FLAC cut by 100 bytes | count from header; `framesRead < frameCount`; later buckets silent |
| Six channels | 6-channel WAV, a different channel loudest per band, winner changing inside a bucket split by the 65,536 boundary | each band follows its own loudest channel, and the split bucket's peak and RMS equal the test-local cascade over the whole signal |
| Provenance | stereo FLAC, stereo WAV | `source.formatID` is the file's codec (`kAudioFormatFLAC`, `kAudioFormatLinearPCM`); `processingFormat == "float32 deinterleaved 2ch 44100.0Hz"`; `sampleRate` and `channelCount` match the opened file |
| Round trip | a reader result, the empty result, the early-EOF result | `decoded(encoded)` equals the input, every `bitPattern`, `framesRead` and `source` included |
| Largest valid header | a 256-byte `processingFormat`, a non-integral rate | encodes without error; header far under 65,536 bytes; decodes equal |
| No key in the format | any encoded result | the JSON header has no `key` field |
| Slice input | a valid file, and a truncated one, passed as `container[k...]` with `k > 0` | the valid one decodes; the truncated one is nil; no trap |
| Damaged bytes | truncated, flipped payload byte, flipped header byte, layout version 2, one trailing byte | nil, no trap |
| Crafted header, valid checksum | negative `framesRead`, `framesRead > frameCount`, `channelCount 0`, wrong `bucketCount`, wrong `payloadByteCount`, `sampleRate 1e-300` with `frameCount 2`, `frameCount` near `Int64.max`, counts that overflow `bucketCount * 24` | nil, no trap |
| Diagnostics changed, valid checksum | a valid file whose `osVersion`, `createdAt` and `filterBank` are rewritten or removed | decodes, equal to the original |

## Code Map

- Reference: R and RT at Hilbert `639fd62b` (paths in frontmatter). R line map: `read` `:37-102`, `bandFilters` `:106-115`, `isEndOfFile` `:118-121`, filter `:136-276`, timebase `:280-296`, sums `:301-345`.
- `Sources/BoomBoomBoomKit/PCMBufferReader.swift` -- `PCMBufferReaderError` `:12-34`; `mFormatID` read `:111`; non-finite scan precedent `:333-350`.
- `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/` -- home of the new files; `WaveformAnalyzer.swift`, `WaveformOptions.swift` and the record files are read-only here.
- `Sources/BoomBoomBoomKitTestSupport/` -- the synthetic-file writers (DD-12); `AudioFixtures.swift` for the bundled fixtures (WAV, FLAC, MP3, M4A, CAF, AIFF, ALAC, OGG under `Resources/AudioFixtures/`).
- `Tests/BoomBoomBoomKitBenchmarkTests/WaveformAnalyzerPerfTests.swift` and the `waveform-perf-baseline` Makefile target -- the pattern for the new benchmark.
- `_bmad-output/project-context.md:21` -- the CryptoKit import list to update.

## Tasks & Acceptance

**Execution:**
- [x] Record the baseline `make test` count at `24746dd` before the first edit.
- [x] `Sources/BoomBoomBoomKit/FeatureSubstrate/Waveform/WaveformBandLevels.swift` -- `WaveformBandLevel`, `WaveformAudioSource`, `WaveformBandLevels` with the validating init (DD-8) and the internal reader init.
- [x] `.../WaveformBandFilter.swift` -- internal filter, timebase and sums (DD-3, DD-4, DD-5).
- [x] `.../WaveformBandLevelReader.swift` -- the reader and `Options` (DD-3, DD-6, DD-7).
- [x] `.../WaveformBandLevelsFile.swift` -- `encoded()`, `decoded(from:)`, the private Codable header types (DD-9, DD-10). No key in the format (2026-10-28).
- [x] `.../WaveformBandLevelError.swift` -- DD-7.
- [x] `Sources/BoomBoomBoomKitTestSupport/SyntheticAudioFiles.swift` -- DD-12.
- [x] `Tests/BoomBoomBoomKitTests/WaveformBandLevelReaderTests.swift` -- port all 31 reference tests at `639fd62b` (20 peak and band, 8 RMS, 3 failure; signal, premises, measurement assertions and tolerances kept; handoff 8.1 and 8.2 tables), names in BBBK camelCase. Three adaptations, no others: the `url` echo assertion (reference tests line 162) becomes `bucketsPerSecond == 150` and `frameCount` equal to the file length; the RMS-never-above-peak test keeps only its measured-level check, and its smoothing, overview and viewport checks (lines 827-849) stay with the app (handoff 8.2, 8.6); the aggregate RMS the sine test computes with the app's `WaveformLevel(rootMeanSquareOf:)` (lines 767-768) becomes a test-local helper computing `sqrt(mean(x^2))` the same way. `referenceRMS`, `expectRMS`, `impulsePeak` and `loudest` port as test-local helpers. Plus the matrix's reader rows (zero-frame header, cancel after the first chunk via injected `isCancelled`, a `withThrowingTaskGroup` + `cancelAll()` smoke test, 7 kHz, 18 kHz boundary, six channels, provenance).
- [x] `Tests/BoomBoomBoomKitTests/WaveformBandLevelNumericTests.swift` -- the independent checks of DD-12 (b), plus a codec sweep: every bundled fixture (WAV, FLAC, MP3, M4A, CAF, AIFF, ALAC, OGG) reads without error, `bucketCount` matches `frameCount`, every value is finite and in `0...1`, and RMS never exceeds peak in any band.
- [x] The one-off scratchpad parity and timing run (DD-12), report in Implementation Notes, package deleted.
- [x] `Tests/BoomBoomBoomKitTests/WaveformBandLevelsFileTests.swift` -- every format row of the matrix (named tests include `emptyResultRoundTrips` and `earlyEOFResultRoundTrips`), every DD-10 check, the validating init's rejections, and a test that the encoded header contains `filterBank`, `osVersion` and `createdAt`. Crafted-header rows rebuild the checksum so they reach the structural checks.
- [x] `Tests/BoomBoomBoomKitBenchmarkTests/WaveformBandLevelPerfTests.swift` -- `BBB_WAVEFORM_BAND_PERF=1`; Release; fixtures written before any timing; 10-minute stereo 44.1 kHz synthetic WAV (16-bit) and FLAC; one warm-up then the median of 5 for: this reader, decode only (`AVAudioFile` reads, no filtering), `encoded`, `decoded`, and the `AVAudioFile` open plus `length` for FLAC, WAV, MP3 and M4A (bundled fixtures). Memory: for 2-, 10- and 30-minute stereo WAVs, each read runs in its own child process (the test binary re-invoked with a filter and an env var naming the file) that reports `ru_maxrss` in bytes after one read; the JSON records each, and the test asserts the growth from 10 to 30 minutes is at most the growth of the two output arrays (`buckets x 24` bytes) plus 25 % slack, which a whole-file decode (about 21.2 MB per stereo minute at 44.1 kHz in Float32) would exceed. Per-SHA JSON to `_bmad-output/perf-baselines/waveform-band/`.
- [x] `Makefile` -- `waveform-band-perf-baseline` target beside `waveform-perf-baseline`.
- [x] DocC on every public type: what is measured in plain words (three filtered bands, louder channel per band, linear 0 to 1, 150 per second), fixed cadence, cancellation, early end of file, the format, that the library never stores anything and the caller chooses the key and the store, that nil means discard and measure again, and that a new `analysisVersion` makes old files unusable.
- [x] `README.md` -- a short section: read, encode, store with your own code, decode.
- [x] `CLAUDE.md` -- key-types roster entries for the new public types and the error.
- [x] `_bmad-output/project-context.md:21` -- CryptoKit now also imported by the waveform file format.
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- add `15-11-waveform-band-levels` (matching this file's status) and `15-12-remove-waveform-analyzer: backlog`.

**Acceptance Criteria:**
1. Given the independent checks of DD-12 (b) and the codec sweep, then each passes; and the one-off scratchpad run reports zero `bitPattern` mismatches against Hilbert's reader over its whole matrix, with equal `bucketCount`, `frameCount` and `framesRead` (any mismatch is fixed or taken to the owner before handover).
2. Given the 31 ported tests, then each passes, and Implementation Notes carries a 31-row table pairing each test's original assertion and tolerance (with its RT line) with the ported one; the only differences are the three named adaptations.
3. Given the matrix rows, then each gives the stated result and error type.
4. Given any reader result, the empty result and the early-EOF result, then `decoded(from: encoded())` equals it bit for bit, and the encoded header carries no key.
5. Given each damaged-bytes and crafted-header row, then `decoded` is nil and the test process does not trap; Implementation Notes lists every allocation in the decoder whose size comes from the data and the check that precedes it.
6. Given `make test`, then its count is the baseline plus the new tests; `WaveformAnalyzerTests` and `WaveformRecordCodingTests` pass; and `git diff --stat 24746dd` shows no file outside the Tasks list.
7. Given the benchmark, then the medians for this reader, decode only, `encoded`, `decoded` and each header open are recorded per format in the per-SHA JSON, and the memory assertion passes. BBBK asserts no speed bound against another reader. Given the scratchpad run, if this reader's median is above Hilbert's on a format, that run is repeated twice; if the median of the three is still above, the story stops and reports the numbers to the owner, who decides.
8. Given `git diff 24746dd -- Sources Tests | grep '^+' | grep -i -E 'rekordbox|hilbert'`, then no output.

## Verification

**Commands:**
- `swift test --filter WaveformBandLevel` -- green during work.
- `make test` -- green; count recorded against the baseline.
- `make fmt && make lint` -- no changes, 0 violations.
- `make docc-validate` -- pass.
- `BBB_WAVEFORM_BAND_PERF=1 make waveform-band-perf-baseline` -- JSON written; numbers in Implementation Notes.
- Bite proofs by temporary edit, each reverted and recorded: (1) filter in `Float` instead of `Double`, the cascade comparison fails; (2) zero the RMS sums at every chunk boundary instead of only on a new bucket, the split-bucket test fails; (3) write `1 / 2.0.squareRoot()` for `quality`, the pinned `bitPattern` test fails; (4) skip the checksum comparison, the flipped-byte rows fail; (5) change the 9 kHz condition from `> 18_000` to `>= 18_000`, the 18,000 Hz section-count assertion fails. Checked by reading the code, because no test here can tell them apart: `chunkStart` comes from `file.framePosition`, never a counter (a counter differs only after a short successful read, which the fixtures cannot force; the Hilbert parity gate covers it); and the `sampleRate` guard precedes the bucket recompute (with it removed, `Int(exactly:)` still rejects the `1e-300` row).
- After commit (owner go-ahead): `uv run scripts/promote-to-main.py --from-ref HEAD` and `make release-rehearse RELEASE_REHEARSE_REF=HEAD`; hand over the SHA that passed.

## Previous Story Intelligence

- **15.10** (landed `a8d5166`, PR #205): baseline `make test` count recorded before the first edit and reconciled after; one bite proof per behavior by temporary revert, each recorded; `make docc-validate` and `make fmt && make lint` as gates; new public types listed in the roster in the same PR.
- **15.4** (`WaveformAnalyzer`): already uses `vDSP.Biquad` in Double over a Float-to-Double copy (`bandFilterImplementation`); its perf test and per-SHA JSON under `_bmad-output/perf-baselines/waveform/` are the template for the new benchmark. Its bins start at `floor(i * Fs / cps)` where this reader's buckets start at `ceil(i * Fs / 150)`, and it caps the bin count differently; do not share.
- **GH-167 item 2** (ingress guards): the scalar non-finite scan exemption and why a `vDSP_sve` check is not trusted (`PCMBufferReader.swift:333-350`).
- **`cd422b1`** (on `rterhaar/13-default-promotion`): macOS DSP output can differ by OS version, so exactness is per machine.

## Hilbert spec inputs (handed off, not built here)

- **Store.** The folder `AppDataLocation.cachesFolder/WaveformCache/`; atomic writes through a uniquely named temporary file in the same folder, renamed into place; listing (key, logical size, last used by modification date, refreshed on a hit); `remove`, `removeAll` (only its own files); temporary files swept only when older than about an hour; one eviction pass over cloud audio and waveform files under the one size limit, audio removals through the cloud cache actor; Clear Cache, Reset All and Auto-Cleanup; the source-file header check (DD-11).
- **Behavior from handoff section 5.** A failed write still returns the measured levels; a cancelled read stores nothing; a finished read is stored even if cancellation comes after; a hit counts even when refreshing its date fails; a nil from `decoded` (old `analysisVersion` or damaged bytes) deletes the file, then the track is measured again and the new result stored.
- **Acceptance there, mandatory before Hilbert deletes its reader.** BBBK holds no copy of Hilbert's reader, so this is the only binding parity check. Pin this story's SHA; run Hilbert's reader (`639fd62b`) and this reader on the same files on one machine and require exact equality of `peak` and `rms` over the matrix of handoff 8.3 (Hilbert's synthetic signals, the bundled fixtures, 11,025 / 44,100 / 48,000 / 96,000 Hz, mono, stereo, more than two channels); time both on the 10-minute stereo WAV and FLAC and decide there if BBBK's reader is slower; keep the run report (BBBK SHA, OS, fixture hashes, counts compared); then run `WaveformSmoothingTests`, `WaveformPeaksTests`, `WaveformViewportTests` and the adapter suites (`DeckCoordinatorWaveformTests`, `AppStateWaveformWiringTests`) unchanged. Delete nothing until all of it passes. Disk-hit and store timings (handoff section 7) are measured there.
- **Stays in the app.** Smoothing, overview and zoomed column building, the RMS combine, colors, blend, opacity and the in-memory overview column cache.
- **Open questions** 1, 2, 3, 6 and 10 of the handoff are Hilbert's to settle.

## Out of scope

Cache file-system work or any disk write from the production library (reading the audio file is in scope; tests and the benchmark may write fixtures and reports); full-band peak (Hilbert dropped it; the rekordbox cache-format note recommends one, and the format's layout version allows adding it later); Float16 storage; invalidating on OS version or codec; measuring at library-index time; a progress callback; beat-grid storage changes; waveform data on any network path; any `WaveformAnalyzer` change (15.12); reading rekordbox's own analysis files (the rekordboxReader repo's job).

## Implementation Notes

Implemented 2026-10-27 on `rterhaar/15-11-waveform-band-levels`, uncommitted, over `24746dd`.

**AC 7 timing (owner accepted the gap, see the Spec Change Log).** The scratchpad run timed this reader against Hilbert's three times. The median of the three is above Hilbert's on both formats, by less than 0.5 percent:

| 10-minute stereo 44.1 kHz | this reader, median per round (ms) | Hilbert reader, median per round (ms) |
|---|---|---|
| 16-bit WAV | 213.29, 213.34, 213.25 | 212.80, 212.55, 212.56 |
| FLAC | 933.33, 933.90, 933.30 | 932.01, 932.25, 932.56 |

The implementer attributed the gap to DD-4's `vDSP_vspdp` conversion, and with a fused scalar loop in its place this reader measured slightly faster than Hilbert's (WAV 207.5 / 207.8 against 208.9 / 208.9 ms; FLAC 899.6 / 905.4 against 902.0 / 907.8 ms). That attribution is not confirmed: an isolated microbenchmark of the conversion alone, at the size of a 10-minute stereo file (Release, best of 7), gave `vDSP_vspdp` 5.76 ms and the Hilbert-style loop 6.11 ms, and the whole conversion is about 6 ms of a 213 ms read. The cause of the 0.5 to 1 ms gap is unknown; run-to-run spread between sessions (207 to 213 ms) is larger than the gap. The owner accepted it (Spec Change Log).

**Two changes from DD-4's wording, same bits.** (1) The non-finite detection is a scalar loop over the `Float` bits that visits every sample (`WaveformBandFilter.containsNonFinite`), not `contains(where:)`: the early-exit scan does not vectorize and cost about 12 ms per 10-minute stereo file (5 percent); the full scan costs about 4 ms. It is still scalar code, not a vDSP check. (2) The scan is skipped when the file's encoded format is integer (integer linear PCM, FLAC, Apple Lossless, mu-law, A-law; `WaveformBandLevelReader.mayDecodeNonFinite`), since an integer sample converts to a finite float. Float PCM and every lossy or unknown codec are scanned. Both are tested (`nonFiniteScanFindsEveryKind`, `integerSourcesSkipTheScan`, `integerWAVMeasuresLikeFloatWAV`).

`WaveformBucketSums.rootMeanSquare` takes each band's channel maximum in one loop instead of a key-path `reduce`; the maximum still starts from 0 and visits channels in order, so the bits are the same. Two restructurings of the span loop (all spans of a chunk measured per channel first; peak and sum of squares in one buffer access) were tried and measured slower, so the span walk stays in the reference's shape.

**Test counts.** Baseline `make test` at `24746dd`: 1,222 tests in 180 suites, passed (4 known issues). After: 1,287 tests in 183 suites, passed (same 4 known issues): 65 new (38 reader, 9 numeric, 18 format). The review fixes add `headerClaimingTooLongThrows`, and the 2026-10-28 key removal drops the two key tests (`otherKeyIsNil`, `badKeyIsRefused`), so 64 new (39 reader, 9 numeric, 16 format) and an expected 1,286. `WaveformAnalyzerTests` and `WaveformRecordCodingTests` pass. `swift test --filter WaveformBandLevel`: 64 passed after the key removal. `make docc-validate`: pass. `make fmt`: no changes. `make lint`: 1 violation, pre-existing and untouched (`Tests/BoomBoomBoomKitBenchmarkTests/PerformanceBenchmarkTests.swift:139`, nesting). AC 8 grep over every new and changed file under `Sources/` and `Tests/`: no output.

**Ported tests (AC 2).** Hilbert test file `639fd62b`, `RT` lines. Signals, premises, assertions and tolerances are kept except where marked. Error-type assertions follow DD-7's mapping; the two failure tests now name the exact BBBK error case, where the reference accepted any error.

| RT | Original | Ported | Difference |
|---|---|---|---|
| 148 | burst: 1,500 buckets; high 0 before 600, >= 0.7 in 600..<750, 0.3...0.8 at 750, <= 1e-6 after | `oneChannelBurstPlacedAtBucketsPerSecond` | adaptation 1: `url` echo (162) becomes `bucketsPerSecond == 150` and `frameCount` == file length |
| 183 | timebase exact boundaries at 44.1 kHz and 11,025 Hz | `timebaseFloorsAbsoluteFrame` | none |
| 205 | impulses: buckets 1, 222, 100 within 1e-6 of 0.4P, 0.6P, 0.6P; others but 223 <= 1e-6 | `impulsesLandInTheirBuckets` | none |
| 237 | 5 kHz at 1.5: steady high == 1 | `highToneAboveFullScaleClampsToOne` | none |
| 256 | last-frame impulse, 3 shapes: count == bucketCount; last high > 0 | `impulseOnLastFrameShowsInFinalPartialBucket` | none |
| 276 | cut FLAC: 300 buckets; 37..<75 > 0.1; 75 > 0; others <= 1e-6 | `fileShorterThanHeaderKeepsPartialPeaks` | none |
| 366 | 80 Hz: low >= 0.45, mid <= 0.075 | `bassToneLowNearToneMidSmall` | none |
| 380 | 800 Hz: mid >= 0.425, low <= 0.1 | `midToneMidNearToneLowSmall` | none |
| 394 | 5 kHz: high within 0.01 + 3 % of 0.4594; low <= 0.01; mid <= 0.05 | `highToneHighOnly` | none |
| 413 | 16 kHz and 11,025 Hz: high finite; steady >= 0.45 / 0.48 | `lowSampleRateHighFiniteAndMeasured` | none |
| 429 | 6 kHz: no filter; read throws unsupported format | `sampleRateTooLowHasNoFilterAndThrows` | DD-7 error: `WaveformBandLevelError.unsupportedFormat` with the URL and 6,000 Hz |
| 447 | steady-sine high gain within 0.01 + 3 % of model, 6 frequencies | `steadySineHighGainMatchesModel` | none |
| 464 | antiphase 80 Hz: low >= 0.45 | `antiphaseBassLowNearTone` | none |
| 477 | 80 Hz across chunk: buckets 220...225 low >= 0.45 | `bassToneAcrossReadChunkCarriesFilterState` | none |
| 501 | 80 Hz stops at chunk: bucket 223 low > 0.01 | `bassToneStoppingAtReadChunkEndRingsIntoNext` | none |
| 524 | 0.9 mid-bucket: loudest low, mid, high in 10; high within 1e-6 of 0.9P | `impulseMidBucketPeaksAllBandsInIt` | none |
| 544 | 0.9 on bucket end: loudest high 11 within 1e-6 of 0.9P; high[10] > 0; mid, low in 10 or 11 | `impulseOnBucketsLastFramePeaksInItOrNext` | none |
| 564 | NaN/Inf then 80 Hz: all finite; steady low >= 0.45 | `badSamplesBeforeToneStayFinite` | none |
| 586 | silence: 150 buckets, peak and RMS all silent | `silenceIsZeroInEveryBand` | none |
| 602 | filter in pieces of 1, 293, 4,096, 65,536: within 1e-6 of one pass | `filterInPiecesMatchesWholePass` | none |
| 749 | sine RMS/peak within 0.05 of 1/sqrt(2) per bucket; aggregate within 0.015 | `sineRMSIsPeakOverRootTwo` | adaptation 3: aggregate (767-768) by a test-local sqrt(mean(x^2)) |
| 774 | left-only 80 Hz: low RMS within 1e-6 of `referenceRMS([L])`; premise > 0.3 | `oneChannelToneRMSIsThatChannels` | none |
| 800 | antiphase RMS within 1e-6 of in-phase; premise > 0.3 | `antiphaseBassRMSAsInPhase` | none |
| 818 | RMS <= peak + 1e-6 for measured, smoothed, overview, zoomed; premise all > 0 | `noiseAndTonesRMSNeverAbovePeak` | adaptation 2: measured levels only (827-849 stay with the app) |
| 855 | split bucket: every band within 1e-6 of `referenceRMS([L, R])`; premises 268 / 26 frames, winner changes | `bucketSplitAcrossReadsRMSAsOnePass` | none |
| 882 | 44,200 frames: 151 buckets within 1e-6; premise bucket 150 > 0.1 | `finalPartialBucketRMSOverItsFrames` | none |
| 900 | cut FLAC 80 Hz: 300 buckets; kept prefix within 1e-6; rest silent; premises | `fileEndingEarlyKeepsRMSOfDecodedFramesThenZero` | none |
| 956 | NaN/Inf in bucket 34: RMS arrays `==` the zeros file; all finite; premise > 0.1 | `badSamplesInToneRMSAsZeros` | none |
| 991 | FLAC cut to audio start + 10 bytes: opens, read throws | `firstReadFailureThrows` | DD-7: asserts `PCMBufferReaderError.readFailed` with the URL |
| 1006 | text saved as `.wav`: throws | `textFileThrows` | DD-7: asserts `PCMBufferReaderError.fileNotReadable` with the URL |
| 1016 | self-cancelled task: `CancellationError` | `preCancelledTaskThrowsCancellationError` | none |

Matrix reader rows added: `zeroFrameHeaderGivesEmptyResult`, `cancelAfterFirstChunkThrows` (asserts exactly two checks), `taskGroupCancellationThrows` (group cancelled before `addTask`, so deterministic), `sevenKilohertzMeasuredWithoutHighLowPass` (written by the hand-written WAV fallback, since `AVAudioFile` writes 7 kHz as 8 kHz), `eighteenKilohertzBoundary`, `sixChannelsEachBandFollowsItsLoudestChannel` (5.1 layout; the split bucket's peak is exactly the cascade's, RMS within 1e-6), `provenanceDescribesTheFile`.

**Decoder allocations sized by the data (AC 5).** (1) The header copy, `H` bytes: after `H` in `1...65_536`, `48 + H <= data.count`, and the checksum matching. (2) `JSONDecoder` work on that copy: bounded by `H`. (3) The two output arrays, `bucketCount` levels each (`reserveCapacity`): after the header's `bucketCount` equals the recomputed count, `payloadByteCount == bucketCount * 24` (overflow-checked) and `== data.count - 48 - H`, so `bucketCount <= data.count / 24`. The checksum (32 bytes) and the validating init's scan allocate nothing sized by the data. Every crafted-header row, including `frameCount` at `Int64.max` with a matching `bucketCount` and a huge `payloadByteCount`, returns nil without trapping.

**Bite proofs (temporary edits, each reverted; files compared byte for byte after).**

| Edit | Failing tests |
|---|---|
| 1. Filter in `Float` (`vDSP.Biquad<Float>` on the Float input) | cascade on seeded noise (all 6 rates), 18 kHz boundary, split bucket vs cascade, six channels, pieces vs whole: 71 issues |
| 2. Zero the RMS sums at every chunk start | `bucketSplitAcrossReadsRMSAsOnePass`, `bucketSplitByReadChunkMatchesCascade`, `sixChannelsEachBandFollowsItsLoudestChannel`, `fileEndingEarlyKeepsRMSOfDecodedFramesThenZero` |
| 3. `quality = 1 / 2.0.squareRoot()` | `qualityBitsArePinned`, `headerCarriesDiagnosticFields` |
| 4. Skip the checksum comparison | `damagedBytesAreNil` (flipped payload byte, flipped checksum byte) |
| 5. 9 kHz condition `>= 18_000` | `eighteenKilohertzBoundary` at 18,000 (section count), cookbook coefficients at 18,000, cascade at 18,000 |

Checked by reading: `chunkStart` is `file.framePosition` at the top of each chunk, never a counter; in the decoder the `sampleRate` finite and `> 6_000` checks precede `bucketCount(frameCount:sampleRate:)`.

**Scratchpad parity run (DD-12), deleted afterwards.** A throwaway package in the session scratchpad depended on this worktree by path and embedded Hilbert's reader from `639fd62b` (`git show`), changed only to drop type-level `nonisolated`, the async adapter and the protocol conformance, and to record `frameCount` and `framesRead` (counted after its data guard). It ran as a Swift Testing target in Release. Matrix: every reference test signal (truncated FLACs included), the 6 kHz refusal, 7 kHz, 11,025 / 18,000 / 18,001 / 44,100 / 48,000 / 96,000 Hz in mono, stereo and six channels, all 25 bundled fixtures, and every MP3 and M4A fixture decoded once to a float WAV. Result: 84 cases, 707,622 peak and RMS values compared by `bitPattern`, **0 mismatches**; every `bucketCount`, `frameCount` and `framesRead` equal; the cases where both throw (6 kHz, first read fails, not audio) throw in both. The 10-minute WAV and FLAC (90,000 buckets each) also matched exactly. OS: macOS 27.2 (26B118). BBBK: `24746dd` plus this story's uncommitted files. Hilbert: `639fd62b`. Timing in the table above.

Two observations for the Hilbert parity gate. (a) Run it under a test runner, not a command-line executable: in a command-line process the truncated FLACs end with `nilError` instead of `NSOSStatusErrorDomain` -39, so both readers throw and the early-end rows test nothing (the same file gives -39 under the test runner). (b) In that command-line process the AAC fixtures (`test-audio.m4a`, `sample-with-cover.m4a`) gave different bits for the two readers: the AAC decoder returned different samples to the two call sites (the reference's own decoded-sample hash changed when only print statements were added to it), and the DSP matched whenever the samples matched. Under the test runner the AAC fixtures matched exactly.

**Benchmark** (`make waveform-band-perf-baseline`, Release; the `-dirty` JSON from this run was deleted at review). Medians, 10-minute stereo 44.1 kHz: 16-bit WAV reader 211.7 ms, decode only 15.3 ms, `encoded` 2.4 ms, `decoded` 1.6 ms; FLAC reader 923.7 ms, decode only 728.1 ms, `encoded` 2.4 ms, `decoded` 1.6 ms; encoded size 2,160,684 bytes. `AVAudioFile` open plus `length`: FLAC 0.06 ms, WAV 0.04 ms, MP3 0.14 ms, M4A 0.07 ms, so the DD-11 check costs far less than a decode. Peak resident size of one read in a child process: 2 min 49.5 MB, 10 min 51.2 MB, 30 min 55.5 MB; growth from 10 to 30 minutes 4.39 MB against 5.40 MB allowed (output arrays 4.32 MB plus 25 percent) and 423 MB for a whole-file decode. The margin is about 1 MB; if the memory assertion ever fails, look at process noise before the reader. Rerun after the commit for a JSON tied to it.

**Code-review fixes (2026-10-27).** The reader refuses a non-finite rate or one at or below 6,000 Hz, then a header claiming more than 12 hours (`durationTooLong(URL, seconds:)`), both before the read buffer and the output arrays are allocated; `headerClaimingTooLongThrows` patches `test-audio.flac`'s STREAMINFO total samples to 2^36 - 1 and expects that error. DocC and README now say an early end keeps levels only on the -39 status (otherwise `readFailed`), that the same decoded samples give the same bits, and that memory includes four 65,536-sample Double filter buffers per channel. The codec sweep allows RMS up to peak + 1e-6. The benchmark's child processes send stderr to the null device and require exit status 0.

**Open: `firstReadFailureThrows` premise (review finding 4).** The requested premise does not hold under the test runner: a raw first read of the FLAC cut to its audio start + 10 bytes throws `com.apple.coreaudio.avfaudio` -66567 (`ExtAudioFileRead` failed), not `NSOSStatusErrorDomain` -39. As instructed, the premise check was reverted and the reader left unchanged. The test still proves a failed first read throws `readFailed`, but no fixture here reaches DD-7's "-39 at `chunkStart == 0`" path.

**Not done.** Commit, `uv run scripts/promote-to-main.py --from-ref HEAD` and `make release-rehearse RELEASE_REHEARSE_REF=HEAD` wait for the owner's go-ahead and the AC 7 decision above.

## Spec Change Log

- 2026-10-27, pre-implementation review layer 1 (failure-mode pass, Codex), 12 findings, all applied: public `WaveformAudioSource` init; six-channel writer via an explicit channel layout; strip type-level `nonisolated` (Swift 6.1 syntax) and the async adapter from the reference copy; enumerate the helpers' dependencies, drop `#require` in TestSupport, add a 16-bit WAV mode; three named adaptations of the ported tests; frame metadata recorded by the reference copy; a 256-byte bound on `processingFormat` plus a `headerTooLarge` error so every accepted result encodes; memory measured in child processes at three lengths; a timing decision rule; 18,000 and 18,001 Hz boundary coverage; bite proof 5 replaced (the old one could not fail); the out-of-scope wording narrowed to cache file-system work.
- 2026-10-27, layer 2 (three parallel Codex reviews: blind, edge case, acceptance), 22 findings, all applied. Design changes: the checksum moved out of the JSON header into a fixed 32-byte field covering the prefix, header and payload (catches header damage; makes duplicate-key headers reachable only by crafting); the timing rule returned to the handoff's "no slower", with the owner deciding if it is not met; DD-13 merged into DD-3 to keep 12 decisions. Clarifications: DD-3 now states the measurement normatively (coefficients, timebase, span walk, RMS order); decode allocation rule restated (header parsing bounded by `H`, output arrays only after the payload length matches); diagnostic header fields can never invalidate (the decoder does not declare them); `Data` slices parsed from their first byte; `sampleRate` rendered with `Double.description`; the reference copy counts `framesRead` only after its data guard and keeps its scalar conversion loop as a recorded test-only exception; writers verify rate, channels and length on reopen; provenance, empty and early-EOF round trips, diagnostics-changed and slice rows added; the key's meaning stated; AC 2, 5, 6 and 8 made checkable; the Hilbert handoff gained the parity gate, downstream suites and the app-side boundaries; `WaveformBandLevelReader: Sendable`; the memory estimate corrected to 21.2 MB per stereo minute; "done" defined for this story.
- 2026-10-27, owner review of the Key Design Decisions: DD-1 to DD-11 approved as written. DD-12 replaced at the owner's request (Codex consulted): no copy of Hilbert's reader in BBBK. Verification is now the ported tests, independent numeric checks written from DD-3 (pinned `quality` bits, closed-form coefficients, a test-local Double cascade, hand-computed bucket boundaries, a split-bucket check), and a one-off uncommitted scratchpad run against Hilbert's reader for parity and timing. The binding bit-exact and head-to-head timing gate moved to the Hilbert migration story, mandatory before it deletes its reader. `WaveformBandLevelParityTests` became `WaveformBandLevelNumericTests`; the benchmark lost its reference column; AC 1, AC 7, the bite proofs, Always, Ask first, Never and Done updated; status set to ready-for-dev.
- 2026-10-27, owner decision on AC 7: the reader is 0.1 to 0.3 percent slower than Hilbert's (WAV 213.3 vs 212.6 ms, FLAC 933.3 vs 932.3 ms, median of three runs). The cause is unconfirmed: the conversion step the implementer suspected measured no slower in isolation. The owner accepted the gap as too small to matter; DD-4 is unchanged. Hilbert's migration story times both readers again.

- 2026-10-27, code review (blind, edge case, verification gap). A damaged FLAC header can claim 68.7 billion frames (confirmed by patching a bundled fixture's STREAMINFO), and the reader sized its output from it, about 5.6 GB before the first frame; Hilbert's reader has the same behavior. Owner decision: refuse headers claiming more than 12 hours with a new error case `durationTooLong(URL, seconds:)`, and move the `> 6_000` rate refusal ahead of every header-sized allocation. DD-3's order and DD-7 amended. Applied as targeted patches rather than a full re-derivation, because the change is confined to the reader's opening checks and one error case. Known-bad state avoided: any allocation sized by an unchecked header. KEEP: everything else in the implementation, which matched Hilbert's reader bit for bit over 707,622 values.
- 2026-10-28, owner change: the caller owns the cache key and the store; the format no longer carries or validates a key; `invalidKey` and `headerTooLarge` removed; `encoded()` is non-throwing.
- 2026-10-28, owner-approved API follow-up, see `spec-15-11-waveform-api-ergonomics.md`: public names become `BandWaveform` (with nested `Levels`, `Band`, `Source`), `BandWaveformReader` and `BandWaveformError`; `encoded()` / `decoded(from:)` become `serializedData()` / `init?(serializedData:)`; bucket time queries and a band subscript added. Values and stored bytes unchanged.

## Review Triage Log

| # | Finding (reviewer) | Verdict | Evidence | Route |
|---|---|---|---|---|
| 1 | Output arrays sized from an unchecked header length; damaged FLAC allocates gigabytes (blind, edge case) | high | A patched `sample-with-cover.flac` reports `length` 68,719,476,735 at 44.1 kHz, 233.7 million buckets. A WAV cannot do this: macOS clamps its length to the data present. | owner decision, patched (12-hour cap) |
| 2 | Rate at or below 6 kHz refused only after header-sized allocation; tiny rates can trap in `Int(Double)` (blind, edge case) | medium | Same root as 1: the `> 6_000` check ran after `bucketCount`. A 1 Hz WAV opens (length clamped to 2), so the trap needs a format with a claimed length, as in 1. | patched with 1 |
| 3 | No test that a non-EOF read error after the first chunk is rethrown (verification gap) | medium | Pre-verified: no fixture produces it; needs a fault-injection seam. | defer |
| 4 | `firstReadFailureThrows` does not check that the raw first read throws -39 (verification gap) | medium | Pre-verified: the truncated-FLAC tests assert their premise, this one does not. | patch |
| 5 | Streaming-memory promise checked only by the env-gated benchmark (verification gap) | low | By design: memory needs a child process and Release. Unlikely to regress unseen; fix adds machinery. | reject |
| 6 | Early end of file kept only when the raw error is -39; in a command-line host a cut FLAC throws `nilError`, but the docs promise partial levels unconditionally (verification gap, blind, edge case) | medium | Implementation Notes observation (a). Matches Hilbert's reader; behavior unchanged, docs overpromise. | patch (DocC and README caveat) |
| 7 | DocC "same file always gives the same bits" is stronger than the evidence (blind) | low | Observation (b): AAC decode returned different samples to two call sites in one process. Direct doc correction. | patch |
| 8 | `WaveformBandLevel` is `Hashable` with a non-validating init, so NaN is reachable (blind) | low | Real but the same as `Float` itself; dropping `Hashable` ripples into `WaveformBandLevels`. Unlikely in use. | reject |
| 9 | RMS-not-above-peak checked strictly in the codec sweep but with `1e-6` elsewhere (blind) | low | Real inconsistency; one-ulp rounding can put RMS above peak on a near-constant span. Direct fix. Init enforcement not adopted. | patch (tolerance only) |
| 10 | A `-dirty` perf baseline JSON is in the tree (blind) | low | Real; numbers tie to no commit. Delete now, regenerate after commit. The dirty-tree refusal is not adopted (sibling targets lack it). | patch |
| 11 | Memory probe child: stderr pipe never drained, exit status ignored (blind, edge case) | low | Real; a child writing over 64 KiB to stderr blocks. Direct fix. | patch |
| 12 | Benchmark omits the SHA-256 of the audio file, the main cost of a cache hit (blind) | low | Key hashing is the caller's (DD-9); belongs in the Hilbert timings. | reject (noted for Hilbert) |
| 13 | Spec status disagrees with sprint-status; stale Implementation Notes paragraph (blind) | low | Bookkeeping; status sync is the workflow's. | reject |
| 14 | Memory docs omit the per-channel filter buffers, about 2 MiB per channel (blind) | low | Real: four 65,536-sample Double buffers per channel. Direct doc fix. | patch |
| 15 | First chunk reading 0 frames without throwing returns an all-silent result (blind, edge case) | maybe-false | No way shown to make `read(into:)` return 0 frames without throwing at position 0. If reachable, medium. | defer |
| 16 | Makefile help line copied a meaningless clause (blind) | low | Real; direct fix. | patch |
| 17 | `writeFile(_:samples:in:)` can write past its buffer on misuse (blind, edge case) | low | Test helper; every caller passes matching counts. Fix adds a guard. | reject |
| 18 | DocC landing page does not curate the new types (blind) | low | Pre-existing: `WaveformAnalyzer` is not curated either. | defer |
| 19 | `channelCount` 0 file passes the reader (edge case) | maybe-false | `AVAudioFormat` with 0 channels is not constructible for a readable file; if reachable, the only harm is a re-measure on each load. | reject |
| 20 | Early end inside the first chunk throws instead of keeping frames (edge case) | false | DD-7 chooses this deliberately ("-39 at `chunkStart == 0` throws"), matching Hilbert's reader. | reject |
| 21 | Non-integral rate can put a boundary frame in the other bucket than the floor rule (edge case) | maybe-false | The span walk is the normative measurement (DD-3), identical to Hilbert's; parity holds. Doc wording only. | reject |
| 22 | `flacAudioStart` can return an offset past the end (edge case) | low | Test helper used only on files it wrote. Fix adds a guard. | reject |
