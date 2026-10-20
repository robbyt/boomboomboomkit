//
//  WaveformPeakOverview.swift
//  BoomBoomBoomKit
//
//  Story 15.4: peak-preserving overview waveform.
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
/// `signedMaxes[i] == 1.0` and `signedMins[i] == 0.0`: the impulse's full
/// amplitude is preserved. This differs from ``WaveformDetailEnvelope``'s
/// `peak-of-abs` reduction, which also preserves the impulse amplitude on
/// a per-bin basis.
///
/// ## NaN-free by construction
/// Every ``signedMins`` and ``signedMaxes`` value is finite: the memberwise
/// initializer traps on a `NaN` or infinity and ``init(from:)`` throws. The
/// synthesized `Hashable`/`Equatable` conformance relies on this; see
/// ``BeatTimestamp`` for the rule. Values beyond `±1.0` (clipping) are
/// allowed.
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
  /// envelope by default: the two outputs share the bin grid for
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

  /// Creates a record. The preconditions are programmer guards: every
  /// array has one value per bin, `sampleRate` is finite and positive,
  /// `columnsPerSecond` is positive, and every sample value is finite.
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
    precondition(sampleRate.isFinite && sampleRate > 0, "sampleRate must be finite and positive")
    precondition(columnsPerSecond > 0, "columnsPerSecond must be positive")
    precondition(signedMins.allSatisfy(\.isFinite), "signedMins must be finite")
    precondition(signedMaxes.allSatisfy(\.isFinite), "signedMaxes must be finite")
    self.schemaVersion = Self.schemaVersion
    self.algorithmIdentifier = Self.algorithmIdentifier
    self.sampleRate = sampleRate
    self.columnsPerSecond = columnsPerSecond
    self.coveredSampleRange = coveredSampleRange
    self.binStartSamples = binStartSamples
    self.signedMins = signedMins
    self.signedMaxes = signedMaxes
  }

  // MARK: Codable

  /// Decodes every stored property and validates it before assigning, so a
  /// persisted or corrupted payload that breaks the record's contract throws
  /// `DecodingError.dataCorrupted` instead of decoding into an invalid
  /// record (the synthesized decoder assigned fields directly and skipped
  /// these checks). It throws when the array lengths disagree, `sampleRate`
  /// is not finite or not positive, `columnsPerSecond` is below 1, or a
  /// sample value is not finite, matching the memberwise preconditions. It
  /// also throws when ``coveredSampleRange`` starts below sample 0; an
  /// inverted range is already rejected by the standard library's `Range`
  /// decoding.
  ///
  /// The stored ``schemaVersion`` and ``algorithmIdentifier`` strings are
  /// kept exactly as encoded rather than replaced by the static constants,
  /// so a consumer can see which version produced the payload. That is also
  /// why this initializer assigns fields itself instead of delegating to the
  /// memberwise initializer, which stamps the current constants.
  /// `encode(to:)` and `CodingKeys` are compiler-synthesized, so the encoded
  /// JSON shape is unchanged.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
    let algorithmIdentifier = try container.decode(String.self, forKey: .algorithmIdentifier)
    let sampleRate = try container.decode(Double.self, forKey: .sampleRate)
    let columnsPerSecond = try container.decode(Int.self, forKey: .columnsPerSecond)
    let coveredSampleRange = try container.decode(Range<Int>.self, forKey: .coveredSampleRange)
    let binStartSamples = try container.decode([Int].self, forKey: .binStartSamples)
    let signedMins = try container.decode([Float].self, forKey: .signedMins)
    let signedMaxes = try container.decode([Float].self, forKey: .signedMaxes)

    try WaveformRecordDecoding.requireSampleRate(sampleRate, forKey: .sampleRate, in: container)
    try WaveformRecordDecoding.requireCadence(
      columnsPerSecond, forKey: .columnsPerSecond, in: container)
    try WaveformRecordDecoding.requireNonNegativeStart(
      coveredSampleRange, forKey: .coveredSampleRange, in: container)
    try WaveformRecordDecoding.requireBinCount(
      signedMins.count, binCount: binStartSamples.count, forKey: .signedMins, in: container)
    try WaveformRecordDecoding.requireBinCount(
      signedMaxes.count, binCount: binStartSamples.count, forKey: .signedMaxes, in: container)
    try WaveformRecordDecoding.requireFinite(signedMins, forKey: .signedMins, in: container)
    try WaveformRecordDecoding.requireFinite(signedMaxes, forKey: .signedMaxes, in: container)

    self.schemaVersion = schemaVersion
    self.algorithmIdentifier = algorithmIdentifier
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
