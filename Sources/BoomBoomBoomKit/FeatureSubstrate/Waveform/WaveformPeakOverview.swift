//
//  WaveformPeakOverview.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — peak-preserving overview waveform.
//

/// Peak-preserving overview waveform: for each bin, the signed minimum and
/// maximum raw sample value. A renderer can draw a filled lollipop or a
/// min-max body without losing a narrow transient to an averaging step.
///
/// Shares the bin-timing convention with ``WaveformDetailEnvelope``: the
/// `binStartSamples` array holds the first sample index of each bin, in
/// strictly-increasing order over ``coveredSampleRange``. See
/// ``WaveformDetailEnvelope`` for a full description.
///
/// ## Peak preservation contract
/// `signedMins[i]` is `samples.min()` and `signedMaxes[i]` is
/// `samples.max()` over the bin's sample range. For a bin containing a
/// single-sample `+1.0` impulse against a zero background,
/// `signedMaxes[i] == 1.0` and `signedMins[i] == 0.0` — the impulse's full
/// amplitude is preserved. This differs from ``WaveformDetailEnvelope``'s
/// `peak-of-abs` reduction, which also preserves the impulse amplitude on
/// a per-bin basis.
public struct WaveformPeakOverview: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Pinned schema version.
  public static let schemaVersion = "v1"

  /// Current algorithm identifier for the overview.
  public static let algorithmIdentifier = "signed-min-max-per-bin.v1"

  /// The schema version this record was produced against.
  public let schemaVersion: String

  /// The algorithm identifier this record was produced by.
  public let algorithmIdentifier: String

  /// Sample rate of the source audio in Hz.
  public let sampleRate: Double

  /// Requested overview cadence in columns per second (same as the detail
  /// envelope by default — the two outputs share the bin grid for
  /// alignment).
  public let columnsPerSecond: Int

  /// Sample range covered by this overview on the decoded-PCM timeline.
  public let coveredSampleRange: Range<Int>

  /// Monotonically-increasing sample index of each bin's first sample.
  public let binStartSamples: [Int]

  /// Signed minimum sample value in each bin.
  public let signedMins: [Float]

  /// Signed maximum sample value in each bin.
  public let signedMaxes: [Float]

  public init(
    sampleRate: Double,
    columnsPerSecond: Int,
    coveredSampleRange: Range<Int>,
    binStartSamples: [Int],
    signedMins: [Float],
    signedMaxes: [Float]
  ) {
    precondition(binStartSamples.count == signedMins.count, "bin array lengths disagree")
    precondition(binStartSamples.count == signedMaxes.count, "bin array lengths disagree")
    precondition(sampleRate > 0, "sampleRate must be positive")
    precondition(columnsPerSecond > 0, "columnsPerSecond must be positive")
    self.schemaVersion = Self.schemaVersion
    self.algorithmIdentifier = Self.algorithmIdentifier
    self.sampleRate = sampleRate
    self.columnsPerSecond = columnsPerSecond
    self.coveredSampleRange = coveredSampleRange
    self.binStartSamples = binStartSamples
    self.signedMins = signedMins
    self.signedMaxes = signedMaxes
  }

  public var description: String {
    "WaveformPeakOverview(\(signedMins.count) bins at \(columnsPerSecond) cps, "
      + "covered=\(coveredSampleRange.count) samples)"
  }
}
