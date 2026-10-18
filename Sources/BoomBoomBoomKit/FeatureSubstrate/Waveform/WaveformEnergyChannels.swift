//
//  WaveformEnergyChannels.swift
//  BoomBoomBoomKit
//
//  Story 15.4 — three-band spectral energy, one magnitude per bin per band.
//

/// Low / mid / high spectral energy per bin, computed from biquad-filtered
/// copies of the input signal. Suitable for a three-band color waveform or
/// a per-band intensity indicator.
///
/// **These are energy magnitudes, not RGB colors.** The handoff is explicit:
/// a renderer may map `low -> R`, `mid -> G`, `high -> B` as a presentation
/// choice, but this type carries no implied color or display vocabulary.
/// Each band carries its own `[0, 1+]` magnitude; no silent per-band
/// normalization is applied — the relative balance between bands is
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

  /// Creates a record. The crossover preconditions are programmer guards:
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
    precondition(sampleRate > 0, "sampleRate must be positive")
    precondition(columnsPerSecond > 0, "columnsPerSecond must be positive")
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

  public var description: String {
    "WaveformEnergyChannels(\(lowBand.count) bins at \(columnsPerSecond) cps, "
      + "cutoffs=\(lowMidCutoffHz)/\(midHighCutoffHz) Hz)"
  }
}
