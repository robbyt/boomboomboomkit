//
//  BeatGridAnalysisSpan.swift
//  BoomBoomBoomKit
//
//  The decoded-PCM sample window a beat grid's onset analysis actually covered,
//  plus the length of the decoded buffer it was cut from (Story 15.10).
//

// MARK: - BeatGridAnalysisSpan

/// The span of decoded audio a ``BeatGrid``'s onset analysis covered, in integer
/// samples on the decoded-PCM timeline, plus the length of the decoded buffer.
///
/// ``BeatGrid/coverage`` records what span was *requested*; this records what was
/// *realized*. The onset analysis starts at the energy transition the analyzer
/// found (so ``startSample`` is usually greater than `0`) and runs for the
/// requested window, capped at the end of the decoded buffer. The decoded buffer
/// is itself capped by `AudioAnalysisService.Options.maxSeconds`, so a
/// ``BeatGridCoverage/fullTrack`` grid of a long file can end well before the
/// file does. ``decodedSampleCount`` records that buffer length; compare
/// ``decodedDurationSeconds`` with ``PCMBufferReader/fileDuration(url:)`` to tell
/// whether the decode was truncated.
///
/// ## Measured versus extrapolated
/// In analyzer output, on the decoded-PCM timeline before any
/// ``BeatGrid/offset(by:)``, detected ``BeatGrid/beats`` lie inside
/// `[startSeconds, endSeconds)`. A playable grid time (``BeatGrid/playableGrid``)
/// outside that interval is extrapolated from ``BeatGrid/gridOrigin`` and
/// ``BeatGrid/estimatedTempo``, not measured. ``BeatGrid/offset(by:)`` shifts
/// presentation times and leaves the span alone, so after an offset subtract the
/// applied offset from a presentation time before comparing it with the span.
/// The interval is the analyzed window, not the extent of observed beats: use
/// `beats.first` and `beats.last` for that.
///
/// ## Integer samples, one float
/// The bounds are integers, like
/// ``WaveformDetailEnvelope/coveredSampleRange``, so the window
/// is recorded exactly and cannot be `NaN`. ``sampleRate`` is the one `Double`;
/// the failable initializer rejects a non-finite or non-positive rate, so every
/// stored float is finite and the synthesized `Hashable` is sound. Seconds are
/// computed from the integers on read.
public struct BeatGridAnalysisSpan: Sendable, Hashable, Codable, CustomStringConvertible {

  /// Sample rate of the decoded audio, in Hz. Finite and positive.
  public let sampleRate: Double

  /// First analyzed sample (inclusive) on the decoded-PCM timeline. `>= 0`.
  public let startSample: Int

  /// One past the last analyzed sample (exclusive). `>= startSample`.
  public let endSample: Int

  /// Number of samples in the decoded buffer the window was cut from, after the
  /// `maxSeconds` cap. `>= endSample`.
  public let decodedSampleCount: Int

  /// Creates a span, or returns `nil` when the values are incoherent: a
  /// `sampleRate` that is not finite or not positive, `startSample < 0`,
  /// `endSample < startSample`, `decodedSampleCount < endSample`, or a
  /// `decodedSampleCount / sampleRate` that is not finite (a tiny rate would make
  /// the computed seconds infinite). Values are never clamped into range.
  public init?(sampleRate: Double, startSample: Int, endSample: Int, decodedSampleCount: Int) {
    guard
      Self.isCoherent(
        sampleRate: sampleRate, startSample: startSample, endSample: endSample,
        decodedSampleCount: decodedSampleCount)
    else { return nil }
    self.sampleRate = sampleRate
    self.startSample = startSample
    self.endSample = endSample
    self.decodedSampleCount = decodedSampleCount
  }

  /// Decodes the four fields and throws `DecodingError.dataCorrupted` when they
  /// fail the same coherence rules as ``init(sampleRate:startSample:endSample:decodedSampleCount:)``.
  /// ``BeatGrid/init(from:)`` folds any such throw to a `nil`
  /// ``BeatGrid/analysisSpan``; decoding this type on its own surfaces it.
  /// `encode(to:)` and `CodingKeys` are compiler-synthesized.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let sampleRate = try container.decode(Double.self, forKey: .sampleRate)
    let startSample = try container.decode(Int.self, forKey: .startSample)
    let endSample = try container.decode(Int.self, forKey: .endSample)
    let decodedSampleCount = try container.decode(Int.self, forKey: .decodedSampleCount)
    guard
      let span = BeatGridAnalysisSpan(
        sampleRate: sampleRate, startSample: startSample, endSample: endSample,
        decodedSampleCount: decodedSampleCount)
    else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription:
            "BeatGridAnalysisSpan requires a finite positive sampleRate and "
            + "0 <= startSample <= endSample <= decodedSampleCount, "
            + "with a finite decodedSampleCount / sampleRate"))
    }
    self = span
  }

  private static func isCoherent(
    sampleRate: Double, startSample: Int, endSample: Int, decodedSampleCount: Int
  ) -> Bool {
    // The duration check bounds `startSeconds` and `endSeconds` too (both use
    // smaller sample counts), so no computed seconds value can be infinite.
    sampleRate.isFinite && sampleRate > 0 && startSample >= 0 && endSample >= startSample
      && decodedSampleCount >= endSample
      && (Double(decodedSampleCount) / sampleRate).isFinite
  }

  // MARK: Computed seconds

  /// ``startSample`` in seconds on the decoded-PCM timeline.
  public var startSeconds: Double { Double(startSample) / sampleRate }

  /// ``endSample`` (exclusive) in seconds on the decoded-PCM timeline.
  public var endSeconds: Double { Double(endSample) / sampleRate }

  /// Length of the decoded buffer in seconds (``decodedSampleCount`` over
  /// ``sampleRate``).
  public var decodedDurationSeconds: Double { Double(decodedSampleCount) / sampleRate }

  // MARK: CustomStringConvertible

  /// One-line summary.
  public var description: String {
    "BeatGridAnalysisSpan(samples: \(startSample)..<\(endSample) of \(decodedSampleCount), "
      + "sampleRate: \(sampleRate))"
  }
}
