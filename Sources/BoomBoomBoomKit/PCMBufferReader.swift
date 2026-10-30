//
//  PCMBufferReader.swift
//  BoomBoomBoomKit
//
//  PCM Buffer Reading Infrastructure
//

@preconcurrency import AVFoundation
import Accelerate
import Foundation

/// Errors thrown by ``PCMBufferReader`` operations.
public enum PCMBufferReaderError: Error, Sendable {
  /// The file at the supplied URL could not be opened. Covers the union of
  /// `AVAudioFile(forReading:)` failure modes — file does not exist, lacks
  /// read permission, is empty or corrupt, or carries a format AVFoundation
  /// cannot decode (e.g., a severely truncated FLAC — measured, GH-167 item 5).
  /// The case payload does not distinguish among these causes.
  ///
  /// This example used to cite OGG/Vorbis. That was wrong: AVFoundation decodes
  /// Vorbis-in-Ogg on macOS 26, verified against a committed fixture. Behaviour
  /// on earlier macOS versions is untested.
  case fileNotReadable(URL)
  /// AVFoundation refused to allocate a PCM buffer of the requested size.
  /// Typically signals exhausted memory or a degenerate audio format.
  case bufferAllocationFailed(URL)
  /// Reading audio samples from the file failed mid-stream. The associated
  /// `underlyingDescription` carries the AVFoundation-reported failure detail.
  case readFailed(URL, underlyingDescription: String)
  /// `AVAudioConverter` failed while resampling mono Float32 to the
  /// requested `targetSampleRate`. Channel mixdown happens earlier via
  /// vDSP and does not surface through this case.
  case conversionFailed(URL)
}

/// Reads audio files into normalized mono float sample arrays.
///
/// This is the shared foundation for BPM estimation, LUFS measurement,
/// and waveform visualization. All consumers receive `[Float]` mono samples.
///
/// `PCMBufferReader` is a stateless struct with static methods.
/// It uses only Apple frameworks (AVFoundation, Accelerate) with
/// no external dependencies.
public struct PCMBufferReader {

  /// Reads an audio file and returns mono samples normalized to [-1.0, 1.0].
  ///
  /// Non-finite (NaN/Inf) decoded samples are silently read as 0.0 (GH #122
  /// ingress policy), so a fully corrupt float file reads as silence.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file (WAV, AIFF, MP3, FLAC, M4A, CAF, etc.)
  ///   - maxSeconds: If provided, only read the first N seconds of audio.
  ///     The cap is routed through ``sanitizedMaxSeconds(_:)``, so non-finite,
  ///     non-positive, or absurdly large (≥ 1e9 s) values all fall back to a
  ///     full-file read (never a trap) — the SAME single rule
  ///     ``readDecodedAudio(from:maxSeconds:)`` applies (DD #3b). A finite
  ///     non-positive value (e.g. `0` or a negative) therefore reads the full
  ///     file, matching the decoded entry point; it no longer clamps to an
  ///     empty result.
  ///   - targetSampleRate: If provided, downsample output to this rate using AVAudioConverter.
  /// - Returns: A tuple of mono samples and the output sample rate.
  /// - Throws: `PCMBufferReaderError` for file access, format, or conversion failures.
  public static func readMonoSamples(
    from url: URL,
    maxSeconds: Double? = nil,
    targetSampleRate: Double? = nil
  ) throws -> (samples: [Float], sampleRate: Double) {
    try readMonoSamples(
      file: try openFile(url), url: url,
      maxSeconds: sanitizedMaxSeconds(maxSeconds), targetSampleRate: targetSampleRate,
      isCancelled: { false }, chunkFrames: nil)
  }

  /// Reads an audio file into the ``FeatureSubstrate/DecodedAudio`` carrier:
  /// mono samples normalized to [-1.0, 1.0] plus content-true codec and
  /// trim-state provenance (Story 8-2 DD #1/#7/#7a — the public producer for
  /// the shared-decode seam).
  ///
  /// The codec tag derives from
  /// `AVAudioFile.fileFormat.streamDescription.pointee.mFormatID` — the
  /// ENCODED on-disk format. `processingFormat` would be wrong here: it
  /// describes the decoded PCM side and would tag everything `.linearPCM`.
  /// Trim state follows the DD #7a population rule: `.knownNone` iff the
  /// payload is linear PCM (no priming concept); `.unknown` for every other
  /// codec ("trim already applied by the decoder, or leaked undetectably —
  /// caller must not assume either").
  ///
  /// Decoding happens exactly once per call (single `AVAudioFile` open, the
  /// same core as ``readMonoSamples(from:maxSeconds:targetSampleRate:)``). A
  /// long file is read in chunks of about 10 s; the samples equal one read of
  /// the whole span. This method does NOT check cooperative cancellation — it
  /// is a plain throwing reader call, same contract as `readMonoSamples`.
  /// `AudioAnalysisService` reads through an internal overload that checks its
  /// ``AudioAnalysisService/Options/isCancelled`` between chunks.
  ///
  /// Non-finite (NaN/Inf) decoded samples are silently read as 0.0 (GH #122
  /// ingress policy), so a fully corrupt float file reads as silence.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file (WAV, AIFF, MP3, FLAC, M4A, CAF, etc.)
  ///   - maxSeconds: If provided, only read the first N seconds. Non-finite,
  ///     non-positive, or absurdly large (≥ 1e9 s) values are sanitized to
  ///     nil (full file) — never a trap (DD #3b).
  /// - Returns: A ``FeatureSubstrate/DecodedAudio`` carrying the mono
  ///   samples, the file's native sample rate, and codec/trim provenance.
  /// - Throws: `PCMBufferReaderError` for file access, format, or read
  ///   failures.
  public static func readDecodedAudio(
    from url: URL,
    maxSeconds: Double? = nil
  ) throws -> FeatureSubstrate.DecodedAudio {
    try readDecodedAudio(from: url, maxSeconds: maxSeconds, isCancelled: { false })
  }

  /// ``readDecodedAudio(from:maxSeconds:)`` with cancellation: `isCancelled`
  /// is checked before every read chunk after the first, and `true` throws
  /// `CancellationError`. A file that fits in one read is never checked.
  ///
  /// - Parameter chunkFrames: Frames per read; `nil` is about 10 s of the
  ///   file (``readChunkSeconds``). Tests pass a small value to exercise many
  ///   chunks on short fixtures, or `.max` for one read of the whole span.
  static func readDecodedAudio(
    from url: URL,
    maxSeconds: Double?,
    isCancelled: @Sendable () -> Bool,
    chunkFrames: AVAudioFrameCount? = nil
  ) throws -> FeatureSubstrate.DecodedAudio {
    let file = try openFile(url)
    let codec = codec(forFormatID: file.fileFormat.streamDescription.pointee.mFormatID)
    let (samples, sampleRate) = try readMonoSamples(
      file: file, url: url,
      maxSeconds: sanitizedMaxSeconds(maxSeconds), targetSampleRate: nil,
      isCancelled: isCancelled, chunkFrames: chunkFrames)
    return FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: codec,
        trimState: codec == .linearPCM ? .knownNone : .unknown))
  }

  /// DD #3b shared `maxSeconds` sanitization — the single rule applied at
  /// all three seam entry points (`readDecodedAudio`, `analyzeLUFS`, and the
  /// BPM decoded overload's prefix slice via ``cappedSampleCount(sampleRate:maxSeconds:totalSamples:)``).
  /// Non-finite, non-positive, or absurdly large (≥ 1e9 s ≈ 31.7 years)
  /// values collapse to nil (full file): unsanitized, `Int64(sampleRate *
  /// maxSeconds)` in the cap arithmetic traps on NaN/Inf/overflow.
  static func sanitizedMaxSeconds(_ value: Double?) -> Double? {
    value.flatMap { $0.isFinite && $0 > 0 && $0 < 1.0e9 ? $0 : nil }
  }

  /// Mirror of the reader's partial-read cap arithmetic (DD #3b) for the
  /// decoded-path prefix slice: `min(AVAudioFrameCount(clamping:
  /// Int64(sampleRate * maxSeconds)), total)` — bit-for-bit the same
  /// truncation/rounding the url path applies at decode time, so a capped
  /// decoded-overload analysis sees exactly the frames a capped url-path
  /// read would have produced. Sanitizes internally; nil/invalid
  /// `maxSeconds` returns `totalSamples` (no cap).
  static func cappedSampleCount(
    sampleRate: Double, maxSeconds: Double?, totalSamples: Int
  ) -> Int {
    guard let maxSeconds = sanitizedMaxSeconds(maxSeconds) else { return totalSamples }
    // Sanitization already removed non-positives, so `zeroOnNonPositive` is
    // moot for this site — `false` documents the mirror's intent (a
    // non-positive cap means no cap / full file).
    return framesFromCap(
      sampleRate: sampleRate, maxSeconds: maxSeconds,
      total: totalSamples, zeroOnNonPositive: false)
  }

  /// Single source of truth for the partial-read cap: `sampleRate *
  /// maxSeconds` truncated to a frame count, clamped to `total`. All
  /// overflow/finite/sign branches live here so the two historical call sites
  /// (``cappedSampleCount(sampleRate:maxSeconds:totalSamples:)`` and the inline
  /// block in the private `readMonoSamples` core) cannot drift apart. The
  /// `zeroOnNonPositive` flag selects the ONLY divergence between them:
  ///   - `true` (url-path inline read, un-sanitized entry): a FINITE
  ///     non-positive cap → `0` frames.
  ///   - `false` (`cappedSampleCount` mirror, sanitized entry): a non-positive
  ///     cap → no cap (`total`).
  /// Non-finite or Int64-overflowing products cannot bound a real buffer
  /// (`DecodedAudio.init` admits any finite rate >= 8 kHz, so e.g. a synthetic
  /// 1e20 Hz carrier can overflow Int64 and `Int64.init` would trap) → `total`,
  /// guarded BEFORE the `Int64(...)` conversion so it never traps.
  static func framesFromCap(
    sampleRate: Double, maxSeconds: Double, total: Int, zeroOnNonPositive: Bool
  ) -> Int {
    let cappedFrames = sampleRate * maxSeconds
    guard cappedFrames.isFinite, cappedFrames < Double(Int64.max) else {
      return total
    }
    if cappedFrames <= 0 {
      return zeroOnNonPositive ? 0 : total
    }
    return min(Int(AVAudioFrameCount(clamping: Int64(cappedFrames))), total)
  }

  /// Opens `url` for reading, folding every `AVAudioFile(forReading:)`
  /// failure mode into `PCMBufferReaderError.fileNotReadable`.
  private static func openFile(_ url: URL) throws -> AVAudioFile {
    do {
      return try AVAudioFile(forReading: url)
    } catch {
      throw PCMBufferReaderError.fileNotReadable(url)
    }
  }

  /// Maps an encoded-format `mFormatID` to the closed ``FeatureSubstrate/AudioCodec``
  /// set (DD #7). Unmapped IDs surface as `.unknown`, never a guess.
  ///
  /// The MPEG-4 AAC family (baseline LC plus the HE/LD/ELD/HE_V2 profiles) all
  /// map to `.aac` — they are AAC payloads for provenance purposes, and the
  /// closed `AudioCodec` set has no profile-distinguishing case (issue #70).
  ///
  /// Package-`internal` (not `private`) so the pure mapping can be unit-tested
  /// directly without sourcing a per-profile audio fixture for each ID.
  static func codec(
    forFormatID formatID: AudioFormatID
  ) -> FeatureSubstrate.AudioCodec {
    switch formatID {
    case kAudioFormatLinearPCM: return .linearPCM
    case kAudioFormatMPEG4AAC,
      kAudioFormatMPEG4AAC_HE,
      kAudioFormatMPEG4AAC_LD,
      kAudioFormatMPEG4AAC_ELD,
      kAudioFormatMPEG4AAC_HE_V2:
      return .aac
    case kAudioFormatAppleLossless: return .alac
    case kAudioFormatMPEGLayer3: return .mp3
    case kAudioFormatFLAC: return .flac
    default: return .unknown
    }
  }

  /// Single-open core shared by ``readMonoSamples(from:maxSeconds:targetSampleRate:)``
  /// and ``readDecodedAudio(from:maxSeconds:)`` — the producer must not pay
  /// (or risk diverging through) a second decode path.
  private static func readMonoSamples(  // swiftlint:disable:this function_parameter_count
    file: AVAudioFile,
    url: URL,
    maxSeconds: Double?,
    targetSampleRate: Double?,
    isCancelled: @Sendable () -> Bool,
    chunkFrames: AVAudioFrameCount?
  ) throws -> (samples: [Float], sampleRate: Double) {
    let format = file.processingFormat
    // Sample-rate sanity check at the file-read boundary — recoverable
    // validation lives here (not at FeatureSubstrate.DecodedAudio.init, which
    // is a pure carrier with a programmer-contract precondition). Downstream
    // consumers (BPMAnalyzer, MelFilterbank, OnsetFeaturesBuilder) trust the
    // rate from this point onward. The 8 kHz floor matches the DecodedAudio
    // precondition — anything below makes BPMAnalyzer's `hopSize = Int(rate
    // / 100)` derivation produce hopSize `<` 80 (and == 0 for rate `<` 100),
    // which is meaningless for onset detection on real music.
    guard format.sampleRate.isFinite, format.sampleRate >= 8_000 else {
      throw PCMBufferReaderError.fileNotReadable(url)
    }
    // `targetSampleRate` is a caller-driven downsample knob — the resulting
    // buffer may be fed into the BPM pipeline (will trap in DecodedAudio.init
    // if `<` 8 kHz), or used standalone for any other purpose (e.g., the
    // existing downsample-to-4410 test verifying the converter infrastructure).
    // Only check finite + positive here.
    if let targetSampleRate {
      guard targetSampleRate.isFinite, targetSampleRate > 0 else {
        throw PCMBufferReaderError.conversionFailed(url)
      }
    }
    let totalFrames = AVAudioFrameCount(clamping: file.length)

    // AC7: Zero-frame file returns empty array
    if totalFrames == 0 {
      return (samples: [], sampleRate: format.sampleRate)
    }

    // Calculate frames to read (partial read support — AC4). Both public
    // entry points now sanitize `maxSeconds` first
    // (`readMonoSamples(from:)` and `readDecodedAudio(from:)` both route
    // through `sanitizedMaxSeconds`), so this core no longer normally sees a
    // non-positive cap. The shared `framesFromCap` helper still owns every
    // finite/overflow/sign branch defensively: `zeroOnNonPositive: true`
    // preserves this site's historical "FINITE non-positive → zero frames"
    // policy if any future caller passes one un-sanitized, and the guard is
    // BEFORE the `Int64(...)` conversion so it cannot trap.
    let framesToRead: AVAudioFrameCount
    if let maxSeconds {
      framesToRead = AVAudioFrameCount(
        clamping: PCMBufferReader.framesFromCap(
          sampleRate: format.sampleRate, maxSeconds: maxSeconds,
          total: Int(totalFrames), zeroOnNonPositive: true))
    } else {
      framesToRead = totalFrames
    }

    // Defensive zero-frame guard: avoid allocating a 0-capacity
    // AVAudioPCMBuffer (mirrors the totalFrames == 0 early return above). Both
    // public entries now sanitize non-positive caps to full-file, so this is
    // only reachable if a future internal caller passes an un-sanitized
    // non-positive cap via `framesFromCap(zeroOnNonPositive: true)`. Report the
    // requested output rate when set — for an empty downsampled read the rate
    // contract still points at the target, even with no samples to convert.
    if framesToRead == 0 {
      return (samples: [], sampleRate: targetSampleRate ?? format.sampleRate)
    }

    var mono = try readMono(
      file: file, url: url, frameCount: framesToRead,
      chunkFrames: chunkFrames ?? defaultChunkFrames(sampleRate: format.sampleRate),
      isCancelled: isCancelled)

    // PCM ingress sanitize (GH #122): decoded Float32 payloads can legally
    // carry NaN/Inf bit patterns (AVFoundation passes them through verbatim
    // for float WAVs), and a single NaN makes `isSilent`'s `rms < threshold`
    // compare false, poisoning the whole pipeline. Policy: ANY count of
    // non-finite samples is zeroed silently — a fully poisoned file reads as
    // silence and takes the existing `isSilent` path (bounded blast radius,
    // no new error surface); clean audio stays bit-identical. Detection is a
    // deterministic scalar early-exit `isFinite` scan, NOT a `vDSP_sve` sum
    // check: sum propagation is mathematically airtight (any non-finite
    // element forces a non-finite IEEE 754 sum in any accumulation order),
    // but adversarial review observed the sum branch fail to fire once on a
    // fresh build (1 of 11 runs, Apple silicon) while the identical probe
    // passed standalone — and deferred-work W4 already calls vDSP non-finite
    // behavior platform-defined. Correctness of the W4 / 8-1-D4 ledger
    // closures rests on this detect being reliable, so determinism wins.
    // Both the scan and the corrective replace-with-0 loop are scalar by
    // explicit spec exemption from the vDSP-for-bulk-numerics rule
    // (spec-gh-167-item2-pcm-ingress-guards): vDSP has no
    // replace-non-finite primitive, and the corrective loop only runs on
    // corrupt input.
    if mono.contains(where: { !$0.isFinite }) {
      for i in 0..<mono.count where !mono[i].isFinite {
        mono[i] = 0
      }
    }

    // Downsampling via AVAudioConverter (AC5)
    if let targetSampleRate {
      let downsampled = try downsample(
        samples: mono,
        fromRate: format.sampleRate,
        toRate: targetSampleRate,
        url: url,
        isCancelled: isCancelled,
        chunkFrames: nil
      )
      return (samples: downsampled, sampleRate: targetSampleRate)
    }

    return (samples: mono, sampleRate: format.sampleRate)
  }

  /// Reads the duration of an audio file in seconds via AVAudioFile metadata.
  ///
  /// Cheap operation — opens the file but does not decode PCM samples.
  /// Used by the duration-derived BPM hint (Story 3-4) at step 9.7 of the BPM
  /// pipeline. Public so that callers needing the duration without the full
  /// PCM read (e.g., UI chrome like "Loading 3:42 of audio…") can use it.
  ///
  /// - Parameters:
  ///   - url: Path to the audio file.
  /// - Returns: Duration in seconds, or `0.0` for zero-length files
  ///   (mirrors `readMonoSamples` zero-frame behavior).
  /// - Throws: `PCMBufferReaderError.fileNotReadable(url)` if the file cannot be opened.
  public static func fileDuration(url: URL) throws -> Double {
    let file: AVAudioFile
    do {
      file = try AVAudioFile(forReading: url)
    } catch {
      throw PCMBufferReaderError.fileNotReadable(url)
    }

    // Validate sampleRate is a usable, finite, positive number before dividing.
    // Malformed or unusual file metadata could otherwise yield `inf` / `nan` from
    // `Double(file.length) / sampleRate`, breaking the public-API contract that
    // promises seconds. Code-review Patch #5 (Story 3-4).
    let sampleRate = file.processingFormat.sampleRate
    guard sampleRate.isFinite, sampleRate > 0 else {
      throw PCMBufferReaderError.fileNotReadable(url)
    }

    if file.length == 0 { return 0.0 }
    return Double(file.length) / sampleRate
  }

  // MARK: - Chunked Read

  /// Seconds of file frames per read when a long file is decoded, and of
  /// input frames per step of a sample-rate conversion. Cancellation is
  /// checked between chunks.
  static let readChunkSeconds: Double = 10

  /// About ``readChunkSeconds`` of frames at `sampleRate`, at least 1.
  static func defaultChunkFrames(sampleRate: Double) -> AVAudioFrameCount {
    max(1, AVAudioFrameCount(clamping: Int64(min(sampleRate * readChunkSeconds, 1.0e15))))
  }

  /// Reads `frameCount` frames from the start of `file` and mixes them to
  /// mono, `chunkFrames` at a time, checking `isCancelled` before every read
  /// after the first.
  ///
  /// The samples equal one `read(into:frameCount:)` of `frameCount` frames,
  /// including the two ways that single read returns fewer frames than asked
  /// without an error (both measured on macOS 27):
  /// - At the real end of a file whose header states more frames than it
  ///   holds (a cut FLAC, CAF or AIFF). A chunked read then gets a short
  ///   chunk, and the next read throws end-of-file or returns nothing.
  /// - At the end of a large read of a float32 WAV, which stops at a
  ///   1,024-frame boundary (a 30 s file reads 1,321,984 of 1,323,000 frames).
  ///   Reads in the middle of such a file come back short the same way.
  ///
  /// So a short read before the last one is followed by another read; an
  /// end-of-file error or an empty read after the first ends the read; and
  /// the last read asks for everything left, between one and two chunks, so
  /// it ends where the single read would and nothing is read after it. A file
  /// that fits in two chunks is read in one call, exactly as before.
  ///
  /// That equality is for the default chunk (about 10 s). Small chunks, which
  /// only tests pass, can read a mono float32 WAV past the 1,024-frame
  /// boundary where the single read stops, because small reads of it often
  /// come back whole; the samples the single read keeps are unchanged.
  private static func readMono(
    file: AVAudioFile,
    url: URL,
    frameCount: AVAudioFrameCount,
    chunkFrames: AVAudioFrameCount,
    isCancelled: @Sendable () -> Bool
  ) throws -> [Float] {
    let chunk = max(1, chunkFrames)
    // Room for the last read, which asks for up to two chunks.
    let capacity = frameCount / 2 < chunk ? frameCount : 2 * chunk
    guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: capacity)
    else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }
    let channelCount = Int(file.processingFormat.channelCount)
    var mono: [Float] = []
    var framesRead: AVAudioFrameCount = 0
    var isFirst = true
    while framesRead < frameCount {
      if !isFirst, isCancelled() { throw CancellationError() }
      let remaining = frameCount - framesRead
      let isLast = remaining / 2 < chunk
      do {
        try file.read(into: buffer, frameCount: isLast ? remaining : chunk)
      } catch {
        if !isFirst, BandWaveformReader.isEndOfFile(error) { break }
        throw PCMBufferReaderError.readFailed(
          url, underlyingDescription: error.localizedDescription)
      }
      guard let channels = buffer.floatChannelData else {
        throw PCMBufferReaderError.readFailed(
          url, underlyingDescription: "No float channel data available")
      }
      let count = Int(buffer.frameLength)
      if count == 0 { break }
      if isFirst, !isLast { mono.reserveCapacity(Int(frameCount)) }
      appendMono(of: channels, channelCount: channelCount, frameCount: count, to: &mono)
      framesRead += AVAudioFrameCount(count)
      if isLast { break }
      isFirst = false
    }
    return mono
  }

  // MARK: - Channel Mixdown

  /// Appends the mono mix of `frameCount` frames of `channels`: a copy for
  /// one channel, `(L + R) / 2` for two, the channel mean for more. Each
  /// output sample depends only on its own frame, so mixing chunk by chunk
  /// gives the same bits as mixing the whole read.
  private static func appendMono(
    of channels: UnsafePointer<UnsafeMutablePointer<Float>>,
    channelCount: Int,
    frameCount: Int,
    to mono: inout [Float]
  ) {
    let start = mono.count
    mono.append(contentsOf: repeatElement(0, count: frameCount))
    mono.withUnsafeMutableBufferPointer { buffer in
      guard let base = buffer.baseAddress else { return }
      let out = base + start
      let length = vDSP_Length(frameCount)
      if channelCount == 1 {
        out.update(from: channels[0], count: frameCount)
      } else if channelCount == 2 {
        // Stereo: (L + R) / 2 using vDSP
        vDSP_vadd(channels[0], 1, channels[1], 1, out, 1, length)
        var divisor: Float = 2.0
        vDSP_vsdiv(out, 1, &divisor, out, 1, length)
      } else {
        // Multi-channel: average all channels using raw pointers (no
        // intermediate Array copies); `out` starts at 0.
        for ch in 0..<channelCount {
          vDSP_vadd(out, 1, channels[ch], 1, out, 1, length)
        }
        var channelDivisor = Float(channelCount)
        vDSP_vsdiv(out, 1, &channelDivisor, out, 1, length)
      }
    }
  }

  // MARK: - Downsampling

  /// Pure output-capacity computation for ``downsample`` (GH #123). Computes
  /// `ceil(Double(inputFrames) * ratio) + 1` entirely in `Double` (the +1 is
  /// INSIDE the guarded domain — the pre-fix inline
  /// `AVAudioFrameCount(ceil(...)) + 1` trapped on the conversion before the
  /// +1 could even overflow) and converts only when the result is finite and
  /// `<= Double(UInt32.max)`. Returns nil otherwise; the caller throws
  /// `conversionFailed` through the existing error path.
  ///
  /// Internal (not private) so the overflow boundary is directly testable —
  /// a huge public-API `targetSampleRate` may be rejected earlier by
  /// `AVAudioFormat` construction and never reach this computation, so a
  /// public-API-only test cannot pin the guard.
  internal static func downsampleOutputCapacity(
    inputFrames: Int, ratio: Double
  ) -> AVAudioFrameCount? {
    let capacity = ceil(Double(inputFrames) * ratio) + 1
    // >= 0: a negative finite capacity (negative ratio or inputFrames)
    // passed the upper-bound check and trapped at the UInt32 conversion --
    // review round 1, confirmed by probe. nil, per this helper's contract.
    guard capacity.isFinite, capacity >= 0, capacity <= Double(UInt32.max) else { return nil }
    return AVAudioFrameCount(capacity)
  }

  /// Converts already-decoded mono samples from `fromRate` to `toRate` with
  /// the same `AVAudioConverter` path the reader uses for `targetSampleRate`.
  /// Works in either direction. ``FeatureSubstrate/FixedTimeCrops`` uses it to
  /// bring a decoded track to 44.1 kHz.
  ///
  /// The converter is fed about 10 s of input at a time, and `isCancelled` is
  /// checked before every chunk after the first. The output equals feeding
  /// the whole input at once.
  ///
  /// - Parameter chunkFrames: Input frames per chunk; `nil` is about 10 s at
  ///   `fromRate`. Tests pass `.max` to feed the whole input at once.
  /// - Throws: `CancellationError` when `isCancelled` returns `true`;
  ///   ``PCMBufferReaderError/conversionFailed(_:)`` or
  ///   ``PCMBufferReaderError/bufferAllocationFailed(_:)``, where there is no
  ///   file, so the URL payload is a fixed placeholder.
  static func resampleMono(
    _ samples: [Float], fromRate: Double, toRate: Double,
    isCancelled: @Sendable () -> Bool, chunkFrames: AVAudioFrameCount? = nil
  ) throws -> [Float] {
    try downsample(
      samples: samples, fromRate: fromRate, toRate: toRate,
      url: URL(fileURLWithPath: "decoded-audio"),
      isCancelled: isCancelled, chunkFrames: chunkFrames)
  }

  private static func downsample(  // swiftlint:disable:this function_parameter_count
    samples: [Float],
    fromRate: Double,
    toRate: Double,
    url: URL,
    isCancelled: @Sendable () -> Bool,
    chunkFrames: AVAudioFrameCount?
  ) throws -> [Float] {
    guard toRate > 0 else {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    guard
      let inputFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: fromRate,
        channels: 1,
        interleaved: false
      )
    else {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    guard
      let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: toRate,
        channels: 1,
        interleaved: false
      )
    else {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    // GH #123 rider, corrected in review round 1: `clamping:` here paired
    // with the full-count copy below would turn the (unreachable) pre-fix
    // trap at `samples.count > UInt32.max` into an out-of-bounds heap write
    // -- the capacity clamps but the copy would not. Guard-and-throw keeps
    // the conversion exact and the copy in-bounds, with no trap.
    guard samples.count <= Int(UInt32.max) else {
      throw PCMBufferReaderError.conversionFailed(url)
    }
    // One chunk of input at a time: the input buffer holds at most one.
    let chunk = Int(max(1, chunkFrames ?? defaultChunkFrames(sampleRate: fromRate)))
    let inputFrameCount = AVAudioFrameCount(min(samples.count, chunk))
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount)
    else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }
    guard inputBuffer.floatChannelData != nil else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }

    // Calculate output buffer size (GH #123): the capacity computation lives
    // in the internal `downsampleOutputCapacity` helper so its Double-domain
    // overflow guard is directly testable; nil means the requested capacity
    // cannot be represented — throw through the existing conversion error path.
    let ratio = toRate / fromRate
    guard
      let outputFrameCount = downsampleOutputCapacity(inputFrames: samples.count, ratio: ratio)
    else {
      throw PCMBufferReaderError.conversionFailed(url)
    }
    guard
      let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount)
    else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }

    // Convert using AVAudioConverter (Apple TN3136 pattern), one chunk per
    // input request. The converter consumes each chunk before asking for the
    // next, so the one buffer is refilled. The first request always gets a
    // chunk (an empty one for empty input), as the one-shot feed did; after
    // the last chunk the block reports end of stream. A cancellation found
    // between chunks stops the feed and throws once `convert` returns.
    // Safety: converter calls the block synchronously and does not store it.
    // nonisolated(unsafe) suppresses the false-positive concurrency warning.
    nonisolated(unsafe) var offset = 0
    nonisolated(unsafe) var fedFirstChunk = false
    nonisolated(unsafe) var cancelled = false
    var conversionError: NSError?
    let status = withoutActuallyEscaping(isCancelled) { isCancelled in
      converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
        if fedFirstChunk {
          if offset >= samples.count {
            outStatus.pointee = .endOfStream
            return nil
          }
          if isCancelled() {
            cancelled = true
            outStatus.pointee = .noDataNow
            return nil
          }
        }
        let count = min(chunk, samples.count - offset)
        if let channel = inputBuffer.floatChannelData?[0] {
          samples.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            channel.update(from: base + offset, count: count)
          }
        }
        inputBuffer.frameLength = AVAudioFrameCount(count)
        offset += count
        fedFirstChunk = true
        outStatus.pointee = .haveData
        return inputBuffer
      }
    }

    if cancelled { throw CancellationError() }
    if status == .error {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    guard let outputData = outputBuffer.floatChannelData else {
      throw PCMBufferReaderError.conversionFailed(url)
    }

    let resultCount = Int(outputBuffer.frameLength)
    return Array(UnsafeBufferPointer(start: outputData[0], count: resultCount))
  }
}
