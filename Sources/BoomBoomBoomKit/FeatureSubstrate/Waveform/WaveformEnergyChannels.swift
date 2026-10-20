//
//  WaveformEnergyChannels.swift
//  BoomBoomBoomKit
//
//  Story 15.4: three-band spectral energy, one magnitude per bin per band.
//

/// Low / mid / high spectral energy per bin, computed from biquad-filtered
/// copies of the input signal. Suitable for a three-band color waveform or
/// a per-band intensity indicator.
///
/// **These are energy magnitudes, not RGB colors.** The handoff is explicit:
/// a renderer may map `low -> R`, `mid -> G`, `high -> B` as a presentation
/// choice, but this type carries no implied color or display vocabulary.
/// Each band carries its own `[0, 1+]` magnitude; no silent per-band
/// normalization is applied. The relative balance between bands is
/// preserved for the renderer to interpret.
///
/// ## Filter contract (algorithm `three-band-biquad.v1`)
/// Four second-order Butterworth biquad passes: the low band is one low-pass
/// at ``lowMidCutoffHz``; the mid band is a high-pass at ``lowMidCutoffHz``
/// cascaded with a low-pass at ``midHighCutoffHz`` (a fourth-order band-pass
/// response); the high band is one high-pass at ``midHighCutoffHz``. The
/// default crossovers are 250 Hz and 4000 Hz.
///
/// Each filter runs in Double precision for pole stability near the
/// crossovers, matching ``LUFSAnalyzer``'s K-weighting precedent. Per-bin
/// energy is the RMS of the filtered band over the bin's sample range.
///
/// ## Bin timing
/// Same convention as ``WaveformDetailEnvelope``: `binStartSamples[i]` is
/// the first sample included in bin `i`. The three outputs share the bin
/// grid for alignment.
///
/// ## NaN-free by construction
/// Every ``lowBand``, ``midBand`` and ``highBand`` value is finite: the
/// memberwise initializer traps on a `NaN` or infinity and ``init(from:)``
/// throws. The synthesized `Hashable`/`Equatable` conformance relies on
/// this; see ``BeatTimestamp`` for the rule. Values above `1.0` (clipping)
/// are allowed.
public struct WaveformEnergyChannels: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Pinned schema version.
  public static let schemaVersion = "v1"

  /// Current algorithm identifier.
  public static let algorithmIdentifier = "three-band-biquad.v1"

  /// The schema version this record was produced against.
  public let schemaVersion: String

  /// The algorithm identifier this record was produced by.
  public let algorithmIdentifier: String

  /// Sample rate of the source audio in Hz.
  public let sampleRate: Double

  /// Columns-per-second cadence used by this run (same as the detail
  /// envelope and the peak overview).
  public let columnsPerSecond: Int

  /// Low / mid crossover in Hz used for this run.
  public let lowMidCutoffHz: Double

  /// Mid / high crossover in Hz used for this run.
  public let midHighCutoffHz: Double

  /// Sample range covered on the decoded-PCM timeline.
  public let coveredSampleRange: Range<Int>

  /// Monotonically-increasing sample index of each bin's first sample.
  public let binStartSamples: [Int]

  /// Low-band RMS per bin.
  public let lowBand: [Float]

  /// Mid-band RMS per bin.
  public let midBand: [Float]

  /// High-band RMS per bin.
  public let highBand: [Float]

  /// Creates a record. Every band array must have one finite value per bin,
  /// and `binStartSamples` must be strictly increasing within
  /// `coveredSampleRange`.
  /// The crossover preconditions are programmer guards:
  /// ``WaveformAnalyzer/analyze(decoded:options:)`` validates the options
  /// and throws a ``WaveformAnalyzerError`` before constructing a record, so
  /// they are unreachable through the analyzer.
  public init(
    sampleRate: Double,
    columnsPerSecond: Int,
    lowMidCutoffHz: Double,
    midHighCutoffHz: Double,
    coveredSampleRange: Range<Int>,
    binStartSamples: [Int],
    lowBand: [Float],
    midBand: [Float],
    highBand: [Float]
  ) {
    precondition(binStartSamples.count == lowBand.count, "bin array lengths disagree")
    precondition(binStartSamples.count == midBand.count, "bin array lengths disagree")
    precondition(binStartSamples.count == highBand.count, "bin array lengths disagree")
    precondition(sampleRate.isFinite && sampleRate > 0, "sampleRate must be finite and positive")
    precondition(columnsPerSecond > 0, "columnsPerSecond must be positive")
    precondition(lowBand.allSatisfy(\.isFinite), "lowBand must be finite")
    precondition(midBand.allSatisfy(\.isFinite), "midBand must be finite")
    precondition(highBand.allSatisfy(\.isFinite), "highBand must be finite")
    precondition(
      WaveformRecordDecoding.binStartsAreValid(binStartSamples, within: coveredSampleRange),
      "binStartSamples must be strictly increasing within coveredSampleRange")
    precondition(
      lowMidCutoffHz > 0 && lowMidCutoffHz < midHighCutoffHz,
      "lowMidCutoffHz must be positive and below midHighCutoffHz")
    precondition(midHighCutoffHz < sampleRate / 2, "midHighCutoffHz must be below Nyquist")
    self.schemaVersion = Self.schemaVersion
    self.algorithmIdentifier = Self.algorithmIdentifier
    self.sampleRate = sampleRate
    self.columnsPerSecond = columnsPerSecond
    self.lowMidCutoffHz = lowMidCutoffHz
    self.midHighCutoffHz = midHighCutoffHz
    self.coveredSampleRange = coveredSampleRange
    self.binStartSamples = binStartSamples
    self.lowBand = lowBand
    self.midBand = midBand
    self.highBand = highBand
  }

  // MARK: Codable

  /// Decodes every stored property and validates it before assigning, so a
  /// persisted or corrupted payload that breaks the record's contract throws
  /// `DecodingError.dataCorrupted` instead of decoding into an invalid
  /// record (the synthesized decoder assigned fields directly and skipped
  /// these checks). It throws when the array lengths disagree, `sampleRate`
  /// is not finite or not positive, `columnsPerSecond` is below 1, a band
  /// value is not finite, ``lowMidCutoffHz`` is not finite, not positive or
  /// not below ``midHighCutoffHz``, ``midHighCutoffHz`` is not below
  /// Nyquist, or ``binStartSamples`` is not strictly increasing within
  /// ``coveredSampleRange``, matching the memberwise preconditions. It also
  /// throws when ``coveredSampleRange`` starts below sample 0; an inverted
  /// range is already rejected by the standard library's `Range` decoding.
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
    let lowMidCutoffHz = try container.decode(Double.self, forKey: .lowMidCutoffHz)
    let midHighCutoffHz = try container.decode(Double.self, forKey: .midHighCutoffHz)
    let coveredSampleRange = try container.decode(Range<Int>.self, forKey: .coveredSampleRange)
    let binStartSamples = try container.decode([Int].self, forKey: .binStartSamples)
    let lowBand = try container.decode([Float].self, forKey: .lowBand)
    let midBand = try container.decode([Float].self, forKey: .midBand)
    let highBand = try container.decode([Float].self, forKey: .highBand)

    try WaveformRecordDecoding.requireSampleRate(sampleRate, forKey: .sampleRate, in: container)
    try WaveformRecordDecoding.requireCadence(
      columnsPerSecond, forKey: .columnsPerSecond, in: container)
    guard lowMidCutoffHz.isFinite, lowMidCutoffHz > 0, lowMidCutoffHz < midHighCutoffHz else {
      throw DecodingError.dataCorruptedError(
        forKey: .lowMidCutoffHz, in: container,
        debugDescription:
          "lowMidCutoffHz must be finite, positive and below midHighCutoffHz "
          + "(got \(lowMidCutoffHz) and \(midHighCutoffHz))")
    }
    guard midHighCutoffHz < sampleRate / 2 else {
      throw DecodingError.dataCorruptedError(
        forKey: .midHighCutoffHz, in: container,
        debugDescription:
          "midHighCutoffHz must be below Nyquist (got \(midHighCutoffHz) at \(sampleRate) Hz)")
    }
    try WaveformRecordDecoding.requireNonNegativeStart(
      coveredSampleRange, forKey: .coveredSampleRange, in: container)
    let binCount = binStartSamples.count
    try WaveformRecordDecoding.requireBinCount(
      lowBand.count, binCount: binCount, forKey: .lowBand, in: container)
    try WaveformRecordDecoding.requireBinCount(
      midBand.count, binCount: binCount, forKey: .midBand, in: container)
    try WaveformRecordDecoding.requireBinCount(
      highBand.count, binCount: binCount, forKey: .highBand, in: container)
    try WaveformRecordDecoding.requireFinite(lowBand, forKey: .lowBand, in: container)
    try WaveformRecordDecoding.requireFinite(midBand, forKey: .midBand, in: container)
    try WaveformRecordDecoding.requireFinite(highBand, forKey: .highBand, in: container)
    try WaveformRecordDecoding.requireBinStarts(
      binStartSamples, within: coveredSampleRange, forKey: .binStartSamples, in: container)

    self.schemaVersion = schemaVersion
    self.algorithmIdentifier = algorithmIdentifier
    self.sampleRate = sampleRate
    self.columnsPerSecond = columnsPerSecond
    self.lowMidCutoffHz = lowMidCutoffHz
    self.midHighCutoffHz = midHighCutoffHz
    self.coveredSampleRange = coveredSampleRange
    self.binStartSamples = binStartSamples
    self.lowBand = lowBand
    self.midBand = midBand
    self.highBand = highBand
  }

  public var description: String {
    "WaveformEnergyChannels(\(lowBand.count) bins at \(columnsPerSecond) cps, "
      + "cutoffs=\(lowMidCutoffHz)/\(midHighCutoffHz) Hz)"
  }
}
