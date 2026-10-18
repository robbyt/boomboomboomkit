//
//  WaveformDetailEnvelope.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — amplitude envelope for a monochrome waveform.
//

/// Per-bin amplitude envelope at a fixed cadence, suitable for drawing a
/// monochrome waveform aligned to the library's own playback timeline.
///
/// ## Bin timing
/// Bin boundaries are stored as sample indices (`Int`) rather than floating
/// seconds. For each bin index `i`:
///
/// - `binStartSamples[i]` is the first sample included in the bin;
/// - `binStartSamples[i + 1]` is the first sample of the next bin
///   (or ``coveredSampleRange``'s `upperBound` for the final bin);
/// - the bin's end-exclusive sample range is
///   `binStartSamples[i] ..< (i + 1 < count ? binStartSamples[i + 1] :
///   coveredSampleRange.upperBound)`.
///
/// A consumer converts to seconds at the display boundary:
/// `Double(binStartSamples[i]) / sampleRate`. This avoids the accumulated
/// drift a repeated `+= 1/cps` loop would introduce.
///
/// ## Magnitude convention
/// Each ``magnitudes`` value is the peak of `abs(sample)` across the bin's
/// sample range, in `[0, 1]`. Silence maps to `0`; a full-scale `±1.0`
/// sample maps to `1`. Values above `1.0` (clipping) are preserved rather
/// than clamped — a consumer rendering above full scale is free to show it.
/// A silence floor (`silenceFloor` on this type) marks what the current
/// algorithm reports for a strictly-zero bin.
///
/// ## Interval semantics
/// Each bin represents the INTERVAL `[binStartSamples[i], binStartSamples[i + 1])`.
/// A renderer draws the magnitude as the column spanning that interval.
public struct WaveformDetailEnvelope: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Pinned schema version. A future algorithm change that alters the bin
  /// semantics, magnitude convention, or layout must bump this.
  public static let schemaVersion = "v1"

  /// Current algorithm identifier for the detail envelope. A caller
  /// capturing a renderer snapshot can store this and refuse to render
  /// against a non-matching library version.
  public static let algorithmIdentifier = "peak-of-abs-per-bin.v1"

  /// Floor the current algorithm reports for a strictly-zero bin. Documented
  /// so a test can distinguish silence from the tiny residual an FFT-based
  /// envelope might emit.
  public static let silenceFloor: Float = 0.0

  /// The schema version this record was produced against (always
  /// ``schemaVersion`` at construction time; carried for forward-compat).
  public let schemaVersion: String

  /// The algorithm identifier this record was produced by.
  public let algorithmIdentifier: String

  /// Sample rate of the source audio in Hz.
  public let sampleRate: Double

  /// Requested detail cadence in columns per second.
  public let columnsPerSecond: Int

  /// Sample range covered by this envelope on the decoded-PCM timeline.
  /// `lowerBound` is `0` for a run that started at the file head; the
  /// range is end-exclusive.
  public let coveredSampleRange: Range<Int>

  /// Monotonically-increasing sample index of each bin's first sample.
  /// Count equals ``magnitudes``'s count.
  public let binStartSamples: [Int]

  /// Peak of `abs(sample)` across each bin's sample range, `[0, 1]`
  /// (`> 1` preserved for clipped signals).
  public let magnitudes: [Float]

  public init(
    sampleRate: Double,
    columnsPerSecond: Int,
    coveredSampleRange: Range<Int>,
    binStartSamples: [Int],
    magnitudes: [Float]
  ) {
    precondition(binStartSamples.count == magnitudes.count, "bin array lengths disagree")
    precondition(sampleRate > 0, "sampleRate must be positive")
    precondition(columnsPerSecond > 0, "columnsPerSecond must be positive")
    self.schemaVersion = Self.schemaVersion
    self.algorithmIdentifier = Self.algorithmIdentifier
    self.sampleRate = sampleRate
    self.columnsPerSecond = columnsPerSecond
    self.coveredSampleRange = coveredSampleRange
    self.binStartSamples = binStartSamples
    self.magnitudes = magnitudes
  }

  public var description: String {
    "WaveformDetailEnvelope(\(magnitudes.count) bins at \(columnsPerSecond) cps, "
      + "covered=\(coveredSampleRange.count) samples)"
  }
}
