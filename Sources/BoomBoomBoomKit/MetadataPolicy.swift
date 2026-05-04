//
//  MetadataPolicy.swift
//  BoomBoomBoomKit
//
//  File-tag BPM corroboration policy and evidence types.
//

import Foundation

// MARK: - MetadataSource

/// Embedded BPM tag formats consulted by file-metadata corroboration.
///
/// Closed enum — three formats cover the bulk of tagged music: iTunes-family
/// containers (`tmpo` atom in MP4/M4A), ID3v2-tagged files (`TBPM` text frame
/// in MP3, embedded in AIFF's `ID3 ` chunk), and Vorbis-comment-tagged files
/// (`BPM=` entry in FLAC). OGG/Vorbis is not supported (no Core Audio codec
/// on macOS).
public enum MetadataSource: String, CaseIterable, Sendable, Hashable {
  /// MP4/M4A `moov/udta/meta/ilst/tmpo` 16-bit big-endian integer atom.
  case iTunesTmpo
  /// ID3v2.3/v2.4 `TBPM` text frame (in MP3 headers, in AIFF/AIFC `ID3 ` chunks).
  case id3TBPM
  /// FLAC Vorbis comment `BPM=` entry (case-insensitive key, repeats permitted).
  case vorbisBPM
}

// MARK: - HarmonicRatio

/// Tempo ratio between a metadata tag and a DSP candidate.
///
/// `.one` means same-tempo (within `MetadataPolicy.corroborationTolerance`,
/// default 3% relative). `.double` and `.half` cover octave corroboration via
/// the existing 1.92-2.08 ratio window. `.threeHalf` and `.twoThird` cover
/// triplet corroboration via 1.45-1.55, gated behind
/// `MetadataPolicy.allowTripletCorroboration` (default `false`) until a
/// follow-up story validates winner-promotion through these ratios.
///
/// Detection of the 3:2 / 3:1 windows ships in `BPMAnalyzer` step 10
/// (Story 3.1) but only as trace-only evidence. Story 3.6 introduces the
/// first metadata-driven *winner-promotion* through these ratios, which is
/// why the gate stays opt-in.
public enum HarmonicRatio: Sendable, Hashable {
  /// Same tempo within `corroborationTolerance` (default 3% relative).
  case one
  /// Tag is double-time of the candidate (candidate ≈ 2× tag).
  case double
  /// Tag is half-time of the candidate (candidate ≈ tag / 2).
  case half
  /// Tag is 3/2× of the candidate (candidate ≈ tag × 2/3). Triplet, gated.
  case threeHalf
  /// Tag is 2/3× of the candidate (candidate ≈ tag × 3/2). Triplet, gated.
  case twoThird
}

// MARK: - MetadataPolicy

/// Configuration for file-metadata-driven BPM corroboration.
///
/// Set on ``AudioAnalysisService/Options/metadataPolicy``. Default
/// (``MetadataPolicy/default``) reads all three sources, corroborates DSP
/// candidates within ±3% (same-tempo) or the octave window (1.92-2.08), and
/// boosts matching candidates' confidence by 1.25× clamped at 0.95. Triplet
/// corroboration (3:2, 3:1) is opt-in via ``allowTripletCorroboration``.
///
/// Set ``MetadataPolicy/disabled`` for byte-identical pre-Story-3.6 behavior:
/// no file-metadata I/O, no merge-stage boost, empty
/// ``AudioAnalysisResult/metadataEvidence``.
public struct MetadataPolicy: Sendable, Hashable {

  // MARK: - Sources

  /// Tag formats actually consulted. An empty set fully suppresses both file
  /// I/O and the merge-stage corroboration step (the ``MetadataPolicy/disabled``
  /// preset).
  public var enabledSources: Set<MetadataSource>

  // MARK: - Tolerances

  /// Absolute BPM difference under which two enabled-source tags are treated
  /// as "unanimous consensus" (default 0.5). At 128 BPM, this means tags at
  /// `(128.0, 128.3)` agree but `(128.0, 129.0)` disagree.
  public var consensusTolerance: Double

  /// Relative tolerance for declaring a DSP candidate corroborated by a tag at
  /// the same tempo (default 0.03 = 3%). Match condition: `abs(C - T) / T <= tol`.
  public var corroborationTolerance: Double

  // MARK: - Boost / Penalty

  /// Multiplicative boost applied to a corroborated candidate's score and to
  /// the resulting confidence (default 1.25). Confidence is clamped at
  /// ``maxBoostedConfidence``.
  public var corroborationBoost: Double

  /// Hard ceiling for boosted confidence (default 0.95). Cannot reach 1.0 by
  /// construction — the library never claims certainty from tag agreement
  /// alone.
  public var maxBoostedConfidence: Double

  /// Multiplicative penalty applied to the winning candidate's confidence
  /// when a unanimous tag set disagrees with all DSP candidates (default 0.85).
  public var skepticismPenalty: Double

  // MARK: - Ratio Gates

  /// When `true` (default), corroboration accepts a tag-candidate octave pair
  /// (ratio 1.92-2.08) and may promote the matching candidate to be the
  /// winner.
  public var allowOctaveCorroboration: Bool

  /// When `true` (default `false`), corroboration accepts triplet pairs
  /// (3:2 ratio 1.45-1.55, 3:1 ratio 2.85-3.15) and may promote the matching
  /// candidate. Gated until a follow-up story validates winner-promotion via
  /// these ratios — Story 3.1 today emits triplet detection as trace-only
  /// evidence and does not modify the chosen winner.
  public var allowTripletCorroboration: Bool

  // MARK: - Parse Hygiene

  /// Acceptable BPM range after parsing (default `30.0...300.0`). Values
  /// outside this range are rejected with `rejectionReason == "out-of-range"`.
  public var valueRange: ClosedRange<Double>

  /// Per-tag string-parsing hygiene rules (whitespace/BOM stripping, locale
  /// decimal comma, range midpoint, sentinel-zero, non-numeric).
  public var parsing: ParsingOptions

  // MARK: - Init

  public init(
    enabledSources: Set<MetadataSource> = Set(MetadataSource.allCases),
    consensusTolerance: Double = 0.5,
    corroborationTolerance: Double = 0.03,
    corroborationBoost: Double = 1.25,
    maxBoostedConfidence: Double = 0.95,
    skepticismPenalty: Double = 0.85,
    allowOctaveCorroboration: Bool = true,
    allowTripletCorroboration: Bool = false,
    valueRange: ClosedRange<Double> = 30.0...300.0,
    parsing: ParsingOptions = ParsingOptions()
  ) {
    self.enabledSources = enabledSources
    self.consensusTolerance = consensusTolerance
    self.corroborationTolerance = corroborationTolerance
    self.corroborationBoost = corroborationBoost
    self.maxBoostedConfidence = maxBoostedConfidence
    self.skepticismPenalty = skepticismPenalty
    self.allowOctaveCorroboration = allowOctaveCorroboration
    self.allowTripletCorroboration = allowTripletCorroboration
    self.valueRange = valueRange
    self.parsing = parsing
  }

  // MARK: - Presets

  /// Default policy: all three sources enabled, defaults applied, triplet
  /// corroboration off.
  public static let `default` = MetadataPolicy()

  /// No-op policy: empty `enabledSources` suppresses both file I/O and the
  /// merge-stage corroboration step. Use for byte-identical pre-Story-3.6
  /// behavior.
  public static let disabled = MetadataPolicy(enabledSources: [])

  // MARK: - ParsingOptions

  /// Per-tag string-parsing hygiene flags. All default `true`.
  public struct ParsingOptions: Sendable, Hashable {
    /// Strip leading/trailing whitespace and a UTF-8/UTF-16 BOM before
    /// numeric parsing.
    public var stripWhitespaceAndBOM: Bool
    /// Accept a decimal comma in the locale form (`"128,5"` parses as 128.5).
    public var acceptLocaleDecimalComma: Bool
    /// Accept a range midpoint (`"120-125"` parses as 122.5).
    public var acceptRangeMidpoint: Bool
    /// Treat a parsed value of exactly zero as "no BPM data" (the iTunes
    /// `tmpo` sentinel) — evidence is emitted with
    /// `rejectionReason == "sentinel-zero"`.
    public var treatZeroAsAbsent: Bool
    /// Reject non-numeric strings (`"fast"`, `"?"`, empty after trimming) with
    /// `rejectionReason == "non-numeric"`.
    public var rejectNonNumeric: Bool

    public init(
      stripWhitespaceAndBOM: Bool = true,
      acceptLocaleDecimalComma: Bool = true,
      acceptRangeMidpoint: Bool = true,
      treatZeroAsAbsent: Bool = true,
      rejectNonNumeric: Bool = true
    ) {
      self.stripWhitespaceAndBOM = stripWhitespaceAndBOM
      self.acceptLocaleDecimalComma = acceptLocaleDecimalComma
      self.acceptRangeMidpoint = acceptRangeMidpoint
      self.treatZeroAsAbsent = treatZeroAsAbsent
      self.rejectNonNumeric = rejectNonNumeric
    }
  }
}

// MARK: - MetadataBPMEvidence

/// Per-source observation describing what the metadata layer found and what it
/// did with that finding.
///
/// One entry is emitted per parsed tag (including rejected ones — the
/// `rejectionReason` carries the parse-phase or decision-phase outcome).
/// Aggregated as ``AudioAnalysisResult/metadataEvidence``.
public struct MetadataBPMEvidence: Sendable {
  /// Format the tag came from.
  public let source: MetadataSource
  /// Raw string read from the tag (post-encoding-decode, pre-hygiene).
  public let rawValue: String
  /// Numeric value after parse hygiene. `Double.nan` for parse-phase
  /// rejections (`sentinel-zero`, `non-numeric`).
  public let parsedBPM: Double
  /// DSP candidate BPM that this tag was credited as corroborating (post
  /// winner re-selection). Nil when not corroborated.
  public let corroboratedWith: Double?
  /// Tempo ratio used for corroboration (when ``corroboratedWith`` is non-nil).
  public let ratioMatched: HarmonicRatio?
  /// Effective confidence multiplier this evidence contributed (1.0 means
  /// neither boost nor penalty applied — the tag was rejected, ignored, or
  /// the divide-by-zero guard short-circuited).
  public let boostApplied: Double
  /// Reason the tag was rejected, if any. Parse-phase: `"sentinel-zero"`,
  /// `"out-of-range"`, `"non-numeric"`. Decision-phase:
  /// `"intra-file-conflict"`, `"dsp-disagreement"`,
  /// `"uncorroborated-single-tag"`. Nil for accepted, corroborated tags.
  public let rejectionReason: String?

  public init(
    source: MetadataSource,
    rawValue: String,
    parsedBPM: Double,
    corroboratedWith: Double? = nil,
    ratioMatched: HarmonicRatio? = nil,
    boostApplied: Double = 1.0,
    rejectionReason: String? = nil
  ) {
    self.source = source
    self.rawValue = rawValue
    self.parsedBPM = parsedBPM
    self.corroboratedWith = corroboratedWith
    self.ratioMatched = ratioMatched
    self.boostApplied = boostApplied
    self.rejectionReason = rejectionReason
  }
}
