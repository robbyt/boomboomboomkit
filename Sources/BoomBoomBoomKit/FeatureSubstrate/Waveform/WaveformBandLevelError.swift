//
//  WaveformBandLevelError.swift
//  BoomBoomBoomKit
//
//  Story 15.11 (DD-7): the one new error type for the three-band waveform
//  levels. A file that cannot be opened or read throws the existing
//  `PCMBufferReaderError` cases instead, and cancellation throws
//  `CancellationError`.
//

import Foundation

/// Errors from ``WaveformBandLevelReader`` and
/// ``WaveformBandLevels/encoded(forKey:)``.
public enum WaveformBandLevelError: Error, Sendable, LocalizedError {
  /// The file's sample rate cannot be measured: it is not finite, it is at or
  /// below 6,000 Hz (where the 3,000 Hz high-pass would be unstable), or a band
  /// filter could not be built at it.
  case unsupportedFormat(URL, sampleRate: Double)
  /// The file's header claims more than 12 hours of audio. Refused before any
  /// memory is allocated from that length, so a damaged header cannot size the
  /// output.
  case durationTooLong(URL, seconds: Double)
  /// The key is not exactly 64 lowercase hexadecimal characters.
  case invalidKey(String)
  /// The encoded header is larger than 65,536 bytes. Results that
  /// ``WaveformBandLevels`` accepts never reach it.
  case headerTooLarge(byteCount: Int)

  /// A readable description, suitable for a log line.
  public var errorDescription: String? {
    switch self {
    case .unsupportedFormat(let url, let sampleRate):
      return
        "Cannot measure waveform levels of \(url.lastPathComponent): sample rate "
        + "\(sampleRate.description) Hz is not supported (it must be finite and above 6000 Hz)."
    case .durationTooLong(let url, let seconds):
      return
        "Cannot measure waveform levels of \(url.lastPathComponent): its header claims "
        + "\(seconds.description) seconds, above the 43200-second (12-hour) limit."
    case .invalidKey(let key):
      return
        "Invalid waveform levels key \"\(key)\": a key must be exactly 64 lowercase "
        + "hexadecimal characters."
    case .headerTooLarge(let byteCount):
      return
        "Cannot encode waveform levels: the header is \(byteCount) bytes, above the "
        + "65536-byte limit."
    }
  }
}
