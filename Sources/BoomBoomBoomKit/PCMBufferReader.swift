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
  ///   - targetSampleRate: If provided, downsample output to this rate using AVAudioConverter.
  /// - Returns: A tuple of mono samples and the output sample rate.
  /// - Throws: `PCMBufferReaderError` for file access, format, or conversion failures.
  public static func readMonoSamples(
    from url: URL,
    maxSeconds: Double? = nil,
    targetSampleRate: Double? = nil
  ) throws -> (samples: [Float], sampleRate: Double) {
    // Open file — AVAudioFile handles all format decoding (MP3, AAC, FLAC → PCM)
    let file: AVAudioFile
    do {
      file = try AVAudioFile(forReading: url)
    } catch {
      throw PCMBufferReaderError.fileNotReadable(url)
    }

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

    // Calculate frames to read (partial read support — AC4)
    let framesToRead: AVAudioFrameCount
    if let maxSeconds {
      let maxFrames = AVAudioFrameCount(clamping: Int64(format.sampleRate * maxSeconds))
      framesToRead = min(maxFrames, totalFrames)
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
