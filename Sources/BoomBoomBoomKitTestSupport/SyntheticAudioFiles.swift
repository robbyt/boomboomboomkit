//
//  SyntheticAudioFiles.swift
//  BoomBoomBoomKitTestSupport
//
//  Story 15.11: writers for the synthetic WAV and FLAC files the three-band
//  waveform level tests and benchmark read. `package` access: both test
//  targets in this package use them; consumers of the TestSupport product do
//  not see them.
//
//  Every writer reopens what it wrote and throws unless the sample rate,
//  channel count and length read back as requested.
//

@preconcurrency import AVFoundation
import Foundation

// MARK: - SyntheticAudioFile

/// The length, channel count, sample rate and container of a synthetic test
/// file.
package struct SyntheticAudioFile: Sendable {
  /// How the samples are stored.
  package enum Container: Sendable {
    /// 32-bit float samples, stored as written.
    case wav
    /// 16-bit integer samples (values outside -1...1 clip).
    case wav16
    /// Apple's FLAC encoder, which writes it from a 24-bit source.
    case flac
  }

  /// The default sample rate, 44.1 kHz.
  package static let sampleRate: Double = 44_100
  /// Frames per bucket at 44.1 kHz and 150 buckets per second.
  package static let bucketFrames = 294
  /// Bytes cut from the end of a 2 s FLAC whose last 1.5 s is silent: a few
  /// silent frames.
  package static let flacTailCut = 100
  /// Bytes of the first FLAC audio frame kept after the metadata: enough to
  /// open, too few to decode.
  package static let firstFrameBytesKept = 10
  /// Where a test tone sits in a 1 s file: 0.2 to 0.8 s, buckets 30 to 119.
  package static let toneSeconds = 0.2..<0.8

  package var frames: Int
  package var channels: AVAudioChannelCount
  package var sampleRate: Double
  package var container: Container

  package init(
    frames: Int, channels: AVAudioChannelCount = 2, sampleRate: Double = Self.sampleRate,
    container: Container = .wav
  ) {
    self.frames = frames
    self.channels = channels
    self.sampleRate = sampleRate
    self.container = container
  }

  /// The file extension for the container.
  package var fileExtension: String {
    switch container {
    case .wav, .wav16: "wav"
    case .flac: "flac"
    }
  }

  /// The writing settings for `format`, the deinterleaved Float32 processing
  /// format the samples are written from.
  func settings(_ format: AVAudioFormat) -> [String: Any] {
    switch container {
    case .wav:
      return format.settings
    case .wav16:
      var settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channels, AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
      ]
      if let layout = format.settings[AVChannelLayoutKey] {
        settings[AVChannelLayoutKey] = layout
      }
      return settings
    case .flac:
      var settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatFLAC, AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channels,
      ]
      if let layout = format.settings[AVChannelLayoutKey] {
        settings[AVChannelLayoutKey] = layout
      }
      return settings
    }
  }
}

// MARK: - Errors

/// Why a synthetic file could not be written.
package enum SyntheticAudioFileError: Error, CustomStringConvertible {
  case formatUnavailable(sampleRate: Double, channels: AVAudioChannelCount)
  case bufferUnavailable(frames: Int)
  case readBackMismatch(URL, expected: String, actual: String)
  case notFLAC
  case flacMetadataTruncated(offset: Int)
  case unsupportedFallback(String)

  package var description: String {
    switch self {
    case .formatUnavailable(let sampleRate, let channels):
      return "no Float32 format for \(channels) channels at \(sampleRate) Hz"
    case .bufferUnavailable(let frames):
      return "no PCM buffer of \(frames) frames"
    case .readBackMismatch(let url, let expected, let actual):
      return "\(url.lastPathComponent) reads back as \(actual), expected \(expected)"
    case .notFLAC:
      return "the data does not start with fLaC"
    case .flacMetadataTruncated(let offset):
      return "FLAC metadata block header past the end at \(offset)"
    case .unsupportedFallback(let reason):
      return "cannot hand-write the file: \(reason)"
    }
  }
}

// MARK: - Writers

/// Writers for synthetic audio files and the signals that fill them.
package enum SyntheticAudioFiles {

  /// A fresh, empty temporary folder; the caller removes it.
  package static func makeFolder(prefix: String = "SyntheticAudioFiles") throws -> URL {
    let folder = FileManager.default.temporaryDirectory
      .appending(path: "\(prefix)-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
  }

  /// A file of `shape`, silent except where `write` puts samples, one pointer
  /// per channel, each `shape.frames` long.
  package static func writeFile(
    _ shape: SyntheticAudioFile, in folder: URL,
    _ write: (_ channels: [UnsafeMutablePointer<Float>]) -> Void
  ) throws -> URL {
    let format = try processingFormat(for: shape)
    guard
      let buffer = AVAudioPCMBuffer(
        pcmFormat: format, frameCapacity: AVAudioFrameCount(max(shape.frames, 1)))
    else { throw SyntheticAudioFileError.bufferUnavailable(frames: shape.frames) }
    buffer.frameLength = AVAudioFrameCount(shape.frames)
    guard let data = buffer.floatChannelData else {
      throw SyntheticAudioFileError.bufferUnavailable(frames: shape.frames)
    }
    let channels = (0..<Int(shape.channels)).map { data[$0] }
    for channel in channels { channel.update(repeating: 0, count: shape.frames) }
    write(channels)
    let url = folder.appending(path: "\(UUID().uuidString).\(shape.fileExtension)")
    do {
      let file = try AVAudioFile(
        forWriting: url, settings: shape.settings(format), commonFormat: .pcmFormatFloat32,
        interleaved: false)
      if shape.frames > 0 { try file.write(from: buffer) }
    }
    if try readsBack(url, as: shape) { return url }
    // `AVAudioFile` would not write this shape as asked (it writes some rates
    // as others): write the WAV by hand instead.
    try FileManager.default.removeItem(at: url)
    let samples = channels.map { Array(UnsafeBufferPointer(start: $0, count: shape.frames)) }
    return try writeWAVByHand(shape, samples: samples, in: folder)
  }

  /// A file of `shape` holding `samples`, one array per channel.
  package static func writeFile(
    _ shape: SyntheticAudioFile, samples: [[Float]], in folder: URL
  ) throws -> URL {
    try writeFile(shape, in: folder) { channels in
      for (channel, values) in zip(channels, samples) {
        channel.update(from: values, count: values.count)
      }
    }
  }

  /// A long file of `shape` written `chunkFrames` at a time, so the whole
  /// signal is never in memory. `fill` writes `count` frames starting at
  /// absolute frame `start` into each channel pointer.
  package static func writeLongFile(
    _ shape: SyntheticAudioFile, in folder: URL, chunkFrames: Int = 1 << 18,
    _ fill: (_ start: Int, _ count: Int, _ channels: [UnsafeMutablePointer<Float>]) -> Void
  ) throws -> URL {
    let format = try processingFormat(for: shape)
    guard
      let buffer = AVAudioPCMBuffer(
        pcmFormat: format, frameCapacity: AVAudioFrameCount(chunkFrames))
    else { throw SyntheticAudioFileError.bufferUnavailable(frames: chunkFrames) }
    guard let data = buffer.floatChannelData else {
      throw SyntheticAudioFileError.bufferUnavailable(frames: chunkFrames)
    }
    let channels = (0..<Int(shape.channels)).map { data[$0] }
    let url = folder.appending(path: "\(UUID().uuidString).\(shape.fileExtension)")
    do {
      let file = try AVAudioFile(
        forWriting: url, settings: shape.settings(format), commonFormat: .pcmFormatFloat32,
        interleaved: false)
      var start = 0
      while start < shape.frames {
        let count = min(chunkFrames, shape.frames - start)
        for channel in channels { channel.update(repeating: 0, count: count) }
        fill(start, count, channels)
        buffer.frameLength = AVAudioFrameCount(count)
        try file.write(from: buffer)
        start += count
      }
    }
    guard try readsBack(url, as: shape) else {
      throw SyntheticAudioFileError.readBackMismatch(
        url, expected: describe(shape), actual: try describeFile(url))
    }
    return url
  }

  /// A 2 s stereo FLAC, silent but for a 5 kHz tone at 0.5 in channel 0 over
  /// 0.25 to 0.5 s (buckets 37 to 74).
  package static func writeToneFLAC(in folder: URL) throws -> URL {
    let sampleRate = SyntheticAudioFile.sampleRate
    let second = Int(sampleRate)
    return try writeFile(SyntheticAudioFile(frames: 2 * second, container: .flac), in: folder) {
      channels in
      for frame in (second / 4)..<(second / 2) {
        channels[0][frame] = 0.5 * Float(sin(2 * Double.pi * 5_000 * Double(frame) / sampleRate))
      }
    }
  }

  /// A silent mono 16-bit WAV at `sampleRate`, its header written by hand:
  /// `AVAudioFile` writes any rate below 8 kHz as 8 kHz, though it reads one as
  /// stated.
  package static func writeSilentWAV(sampleRate: Int, frames: Int, in folder: URL) throws -> URL {
    let bytesPerFrame = 2
    let dataSize = frames * bytesPerFrame
    var data = Data("RIFF".utf8) + little(36 + dataSize, bytes: 4) + Data("WAVEfmt ".utf8)
    data += little(16, bytes: 4) + little(1, bytes: 2) + little(1, bytes: 2)  // PCM, mono
    data += little(sampleRate, bytes: 4) + little(sampleRate * bytesPerFrame, bytes: 4)
    data += little(bytesPerFrame, bytes: 2) + little(16, bytes: 2)
    data += Data("data".utf8) + little(dataSize, bytes: 4) + Data(count: dataSize)
    let url = folder.appending(path: "\(UUID().uuidString).wav")
    try data.write(to: url)
    let shape = SyntheticAudioFile(
      frames: frames, channels: 1, sampleRate: Double(sampleRate), container: .wav16)
    guard try readsBack(url, as: shape) else {
      throw SyntheticAudioFileError.readBackMismatch(
        url, expected: describe(shape), actual: try describeFile(url))
    }
    return url
  }

  /// Cuts the file at `url` to its first `length` bytes.
  package static func truncate(_ url: URL, to length: Int) throws {
    let handle = try FileHandle(forWritingTo: url)
    try handle.truncate(atOffset: UInt64(length))
    try handle.close()
  }

  /// Where a FLAC's audio frames start: after "fLaC" and its metadata blocks,
  /// each a 1-byte type whose top bit marks the last block, then a 3-byte
  /// big-endian length.
  package static func flacAudioStart(of data: Data) throws -> Int {
    let bytes = [UInt8](data)
    guard bytes.starts(with: Array("fLaC".utf8)) else { throw SyntheticAudioFileError.notFLAC }
    var offset = 4
    var isLast = false
    while !isLast {
      guard offset + 4 <= bytes.count else {
        throw SyntheticAudioFileError.flacMetadataTruncated(offset: offset)
      }
      isLast = bytes[offset] & 0x80 != 0
      offset +=
        4
        + (Int(bytes[offset + 1]) << 16 | Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3]))
    }
    return offset
  }

  // MARK: - Signals

  /// A sine of `amplitude` at `frequency` over `frames` frames.
  package static func sine(
    _ frequency: Double, amplitude: Float = 0.5, frames: Int,
    sampleRate: Double = SyntheticAudioFile.sampleRate
  ) -> [Float] {
    (0..<frames).map { frame in
      amplitude * Float(sin(2 * Double.pi * frequency * Double(frame) / sampleRate))
    }
  }

  /// Seeded noise at 0.2 over an 80 Hz and an 800 Hz tone at 0.3 each, so all
  /// three bands carry signal.
  package static func noiseAndTones(
    frames: Int, sampleRate: Double = SyntheticAudioFile.sampleRate, seed: UInt32 = 0x1234_5678
  ) -> [Float] {
    var state = seed
    return (0..<frames).map { frame in
      state = state &* 1_664_525 &+ 1_013_904_223
      let noise = Float(state >> 8) / Float(1 << 24) - 0.5
      let time = Double(frame) / sampleRate
      return 0.2 * noise + 0.3 * Float(sin(2 * .pi * 80 * time) + sin(2 * .pi * 800 * time))
    }
  }

  // MARK: - Helpers

  /// The deinterleaved Float32 format the samples are written from. Above two
  /// channels it needs an explicit layout: a 5.1 layout for six channels,
  /// discrete channels otherwise.
  private static func processingFormat(for shape: SyntheticAudioFile) throws -> AVAudioFormat {
    if shape.channels <= 2 {
      guard
        let format = AVAudioFormat(
          standardFormatWithSampleRate: shape.sampleRate, channels: shape.channels)
      else {
        throw SyntheticAudioFileError.formatUnavailable(
          sampleRate: shape.sampleRate, channels: shape.channels)
      }
      return format
    }
    let tag =
      shape.channels == 6
      ? kAudioChannelLayoutTag_MPEG_5_1_A
      : kAudioChannelLayoutTag_DiscreteInOrder | AudioChannelLayoutTag(shape.channels)
    guard let layout = AVAudioChannelLayout(layoutTag: tag) else {
      throw SyntheticAudioFileError.formatUnavailable(
        sampleRate: shape.sampleRate, channels: shape.channels)
    }
    return AVAudioFormat(
      commonFormat: .pcmFormatFloat32, sampleRate: shape.sampleRate, interleaved: false,
      channelLayout: layout)
  }

  /// Whether `url` opens with `shape`'s sample rate, channel count and length.
  private static func readsBack(_ url: URL, as shape: SyntheticAudioFile) throws -> Bool {
    let file = try AVAudioFile(forReading: url)
    return file.processingFormat.sampleRate == shape.sampleRate
      && file.processingFormat.channelCount == shape.channels
      && file.length == Int64(shape.frames)
  }

  private static func describe(_ shape: SyntheticAudioFile) -> String {
    "\(shape.sampleRate) Hz, \(shape.channels) channels, \(shape.frames) frames"
  }

  private static func describeFile(_ url: URL) throws -> String {
    let file = try AVAudioFile(forReading: url)
    return
      "\(file.processingFormat.sampleRate) Hz, \(file.processingFormat.channelCount) channels, "
      + "\(file.length) frames"
  }

  /// A WAV written by hand from deinterleaved samples: 32-bit float for
  /// `.wav`, 16-bit integer for `.wav16`. Only for one or two channels at a
  /// whole-number rate; anything else throws.
  private static func writeWAVByHand(
    _ shape: SyntheticAudioFile, samples: [[Float]], in folder: URL
  ) throws -> URL {
    guard shape.channels <= 2, shape.container != .flac,
      let rate = Int(exactly: shape.sampleRate)
    else {
      throw SyntheticAudioFileError.unsupportedFallback(describe(shape))
    }
    let isFloat = shape.container == .wav
    let bytesPerSample = isFloat ? 4 : 2
    let channels = Int(shape.channels)
    let bytesPerFrame = bytesPerSample * channels
    let dataSize = shape.frames * bytesPerFrame
    var data = Data("RIFF".utf8) + little(36 + dataSize, bytes: 4) + Data("WAVEfmt ".utf8)
    data += little(16, bytes: 4) + little(isFloat ? 3 : 1, bytes: 2) + little(channels, bytes: 2)
    data += little(rate, bytes: 4) + little(rate * bytesPerFrame, bytes: 4)
    data += little(bytesPerFrame, bytes: 2) + little(bytesPerSample * 8, bytes: 2)
    data += Data("data".utf8) + little(dataSize, bytes: 4)
    var payload = [UInt8]()
    payload.reserveCapacity(dataSize)
    for frame in 0..<shape.frames {
      for channel in 0..<channels {
        let sample = samples[channel][frame]
        if isFloat {
          let bits = sample.bitPattern
          for shift in stride(from: 0, to: 32, by: 8) {
            payload.append(UInt8(truncatingIfNeeded: bits >> UInt32(shift)))
          }
        } else {
          let clipped = max(-1, min(1, sample.isFinite ? sample : 0))
          let value = Int16(clipped * 32_767)
          let bits = UInt16(bitPattern: value)
          payload.append(UInt8(truncatingIfNeeded: bits))
          payload.append(UInt8(truncatingIfNeeded: bits >> 8))
        }
      }
    }
    data += payload
    let url = folder.appending(path: "\(UUID().uuidString).wav")
    try data.write(to: url)
    guard try readsBack(url, as: shape) else {
      throw SyntheticAudioFileError.readBackMismatch(
        url, expected: describe(shape), actual: try describeFile(url))
    }
    return url
  }

  /// `value` as `bytes` little-endian bytes.
  private static func little(_ value: Int, bytes: Int) -> Data {
    Data((0..<bytes).map { UInt8((value >> (8 * $0)) & 0xFF) })
  }
}
