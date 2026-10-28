//
//  BandWaveformError.swift
//  BoomBoomBoomKit
//
//  Story 15.11 (DD-7): the one new error type for the three-band waveform
//  levels reader. A file that cannot be opened or read throws the existing
//  `PCMBufferReaderError` cases instead, and cancellation throws
//  `CancellationError`.
//

import Foundation

/// Errors from ``BandWaveformReader``. ``BandWaveform/serializedData()`` and
/// ``BandWaveform/init(serializedData:)`` never throw.
public enum BandWaveformError: Error, Sendable, LocalizedError {
  /// The file's sample rate cannot be measured: it is not finite, it is at or
  /// below 6,000 Hz (where the 3,000 Hz high-pass would be unstable), it is
  /// above 1,536,000 Hz (twice 768 kHz, the top of the supported range), or a
  /// band filter could not be built at it.
  case unsupportedFormat(URL, sampleRate: Double)
  /// The file's header claims more than 12 hours of audio. Refused before any
  /// memory is allocated from that length, so a damaged header cannot size the
  /// output.
  case durationTooLong(URL, seconds: Double)

  /// A readable description, suitable for a log line.
  public var errorDescription: String? {
    switch self {
    case .unsupportedFormat(let url, let sampleRate):
      return
        "Cannot measure waveform levels of \(url.lastPathComponent): sample rate "
        + "\(sampleRate.description) Hz is not supported (it must be finite, above 6000 Hz "
        + "and at most 1536000 Hz)."
    case .durationTooLong(let url, let seconds):
      return
        "Cannot measure waveform levels of \(url.lastPathComponent): its header claims "
        + "\(seconds.description) seconds, above the 43200-second (12-hour) limit."
    }
  }
}
