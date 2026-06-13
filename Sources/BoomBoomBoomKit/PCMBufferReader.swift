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
  /// cannot decode (e.g., OGG/Vorbis on macOS). The case payload does not
  /// distinguish among these causes.
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
  /// - Parameters:
  ///   - url: Path to the audio file (WAV, AIFF, MP3, FLAC, M4A, CAF, etc.)
  ///   - maxSeconds: If provided, only read the first N seconds of audio.
  ///     Non-finite or Int64-overflowing caps fall back to a full-file read
  ///     (never a trap); a FINITE non-positive value clamps to zero frames
  ///     (empty result). Use ``readDecodedAudio(from:maxSeconds:)`` for the
  ///     fully sanitized (DD #3b) entry point, where non-positive values
  ///     also collapse to a full-file read.
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
      maxSeconds: maxSeconds, targetSampleRate: targetSampleRate)
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
  /// Decoding happens exactly once per call (single `AVAudioFile` open,
  /// single PCM read — same core as ``readMonoSamples(from:maxSeconds:targetSampleRate:)``).
  /// This method does NOT check cooperative cancellation — it is a plain
  /// throwing reader call, same contract as `readMonoSamples`; cancellation
  /// checkpoints live in `AudioAnalysisService`.
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
    let file = try openFile(url)
    let codec = codec(forFormatID: file.fileFormat.streamDescription.pointee.mFormatID)
    let (samples, sampleRate) = try readMonoSamples(
      file: file, url: url,
      maxSeconds: sanitizedMaxSeconds(maxSeconds), targetSampleRate: nil)
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
    let cappedFrames = sampleRate * maxSeconds
    // `DecodedAudio.init` admits any finite rate >= 8 kHz, so the product can
    // exceed Int64's domain (e.g. a synthetic 1e20 Hz carrier) — `Int64.init`
    // would trap. A cap that large cannot bound any real buffer; no-op it.
    guard cappedFrames.isFinite, cappedFrames < Double(Int64.max) else {
      return totalSamples
    }
    let maxFrames = AVAudioFrameCount(clamping: Int64(cappedFrames))
    return min(Int(maxFrames), totalSamples)
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
  private static func codec(
    forFormatID formatID: AudioFormatID
  ) -> FeatureSubstrate.AudioCodec {
    switch formatID {
    case kAudioFormatLinearPCM: return .linearPCM
    case kAudioFormatMPEG4AAC: return .aac
    case kAudioFormatAppleLossless: return .alac
    case kAudioFormatMPEGLayer3: return .mp3
    case kAudioFormatFLAC: return .flac
    default: return .unknown
    }
  }

  /// Single-open core shared by ``readMonoSamples(from:maxSeconds:targetSampleRate:)``
  /// and ``readDecodedAudio(from:maxSeconds:)`` — the producer must not pay
  /// (or risk diverging through) a second decode path.
  private static func readMonoSamples(
    file: AVAudioFile,
    url: URL,
    maxSeconds: Double?,
    targetSampleRate: Double?
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

    // Calculate frames to read (partial read support — AC4). The product
    // guard mirrors `cappedSampleCount`: a non-finite or Int64-overflowing
    // cap (NaN/Inf `maxSeconds` reaching this un-sanitized entry, or an
    // absurd reported sample rate) cannot bound a real file — read fully
    // instead of trapping in `Int64.init`.
    let framesToRead: AVAudioFrameCount
    if let maxSeconds {
      let cappedFrames = format.sampleRate * maxSeconds
      if cappedFrames.isFinite, cappedFrames < Double(Int64.max) {
        framesToRead = min(AVAudioFrameCount(clamping: Int64(cappedFrames)), totalFrames)
      } else {
        framesToRead = totalFrames
      }
    } else {
      framesToRead = totalFrames
    }

    // Allocate buffer and read
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead) else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }

    do {
      try file.read(into: buffer, frameCount: framesToRead)
    } catch {
      throw PCMBufferReaderError.readFailed(url, underlyingDescription: error.localizedDescription)
    }

    guard let floatChannelData = buffer.floatChannelData else {
      throw PCMBufferReaderError.readFailed(
        url, underlyingDescription: "No float channel data available")
    }

    let frameCount = Int(buffer.frameLength)
    let channelCount = Int(format.channelCount)

    // Channel mixdown to mono
    let mono: [Float]
    if channelCount == 1 {
      // Mono: copy directly
      mono = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameCount))
    } else if channelCount == 2 {
      // Stereo: (L + R) / 2 using vDSP
      mono = mixStereoToMono(
        left: floatChannelData[0],
        right: floatChannelData[1],
        frameCount: frameCount
      )
    } else {
      // Multi-channel: average all channels using raw pointers (no intermediate Array copies)
      var result = [Float](repeating: 0, count: frameCount)
      for ch in 0..<channelCount {
        vDSP_vadd(result, 1, floatChannelData[ch], 1, &result, 1, vDSP_Length(frameCount))
      }
      var channelDivisor = Float(channelCount)
      vDSP_vsdiv(result, 1, &channelDivisor, &result, 1, vDSP_Length(frameCount))
      mono = result
    }

    // Downsampling via AVAudioConverter (AC5)
    if let targetSampleRate {
      let downsampled = try downsample(
        samples: mono,
        fromRate: format.sampleRate,
        toRate: targetSampleRate,
        url: url
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

  // MARK: - Channel Mixdown

  private static func mixStereoToMono(
    left: UnsafeMutablePointer<Float>,
    right: UnsafeMutablePointer<Float>,
    frameCount: Int
  ) -> [Float] {
    var mono = [Float](repeating: 0, count: frameCount)
    vDSP.add(
      UnsafeBufferPointer(start: left, count: frameCount),
      UnsafeBufferPointer(start: right, count: frameCount),
      result: &mono
    )
    var divisor: Float = 2.0
    vDSP_vsdiv(mono, 1, &divisor, &mono, 1, vDSP_Length(frameCount))
    return mono
  }

  // MARK: - Downsampling

  private static func downsample(
    samples: [Float],
    fromRate: Double,
    toRate: Double,
    url: URL
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

    let inputFrameCount = AVAudioFrameCount(samples.count)
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount)
    else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }

    // Copy samples into input buffer
    guard let inputChannelData = inputBuffer.floatChannelData else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }
    samples.withUnsafeBufferPointer { srcPtr in
      guard let baseAddress = srcPtr.baseAddress else { return }
      inputChannelData[0].update(from: baseAddress, count: samples.count)
    }
    inputBuffer.frameLength = inputFrameCount

    // Calculate output buffer size
    let ratio = toRate / fromRate
    let outputFrameCount = AVAudioFrameCount(ceil(Double(inputFrameCount) * ratio)) + 1
    guard
      let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount)
    else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }

    // Convert using AVAudioConverter (Apple TN3136 pattern)
    // Safety: converter calls the block synchronously and does not store it.
    // nonisolated(unsafe) suppresses the false-positive concurrency warning.
    nonisolated(unsafe) var inputConsumed = false
    var conversionError: NSError?
    let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
      if inputConsumed {
        outStatus.pointee = .endOfStream
        return nil
      }
      inputConsumed = true
      outStatus.pointee = .haveData
      return inputBuffer
    }

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
