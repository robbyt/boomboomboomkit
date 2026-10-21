//
//  WaveformRecordDecoding.swift
//  BoomBoomBoomKit
//
//  Story 15.4: shared decode-time validation for the three Codable waveform
//  records.
//

/// Throwing checks used by the `init(from:)` of ``WaveformDetailEnvelope``,
/// ``WaveformPeakOverview``, ``WaveformEnergyChannels`` and
/// ``WaveformAnalysisResult``.
///
/// Each check mirrors a `precondition` in the matching memberwise
/// initializer, but throws `DecodingError.dataCorrupted` instead of trapping:
/// a persisted or corrupted payload is input, not a programmer error.
enum WaveformRecordDecoding {

  /// Rejects a sample rate that is not finite or not strictly positive.
  static func requireSampleRate<Key: CodingKey>(
    _ sampleRate: Double, forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    guard sampleRate.isFinite, sampleRate > 0 else {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription: "sampleRate must be finite and positive (got \(sampleRate))")
    }
  }

  /// Rejects a cadence below one column per second.
  static func requireCadence<Key: CodingKey>(
    _ columnsPerSecond: Int, forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    guard columnsPerSecond >= 1 else {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription: "columnsPerSecond must be at least 1 (got \(columnsPerSecond))")
    }
  }

  /// Rejects a covered range that starts before sample 0. An inverted range
  /// never reaches this check: the standard library's `Range` decoding
  /// already throws when `lowerBound > upperBound`.
  static func requireNonNegativeStart<Key: CodingKey>(
    _ range: Range<Int>, forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    guard range.lowerBound >= 0 else {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription: "coveredSampleRange must start at or after sample 0 (got \(range))")
    }
  }

  /// Rejects a per-bin array whose length differs from `binStartSamples`.
  static func requireBinCount<Key: CodingKey>(
    _ count: Int, binCount: Int, forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    guard count == binCount else {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue) has \(count) values but binStartSamples has \(binCount)")
    }
  }

  /// Rejects a float array holding any `NaN` or infinity. The records are
  /// `Hashable` and must stay NaN-free (see ``BeatTimestamp``).
  static func requireFinite<Key: CodingKey>(
    _ values: [Float], forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    if let index = values.firstIndex(where: { !$0.isFinite }) {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue)[\(index)] is not finite (got \(values[index]))")
    }
  }

  /// Rejects a float array holding any `NaN`, infinity or negative value.
  /// Used for the unsigned per-bin magnitudes (the detail envelope's
  /// magnitudes and the energy bands), which are peaks of `abs(sample)` or
  /// RMS values and are never below 0.
  static func requireFiniteNonNegative<Key: CodingKey>(
    _ values: [Float], forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    if let index = values.firstIndex(where: { !$0.isFinite || $0 < 0 }) {
      let problem = values[index].isFinite ? "is negative" : "is not finite"
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue)[\(index)] \(problem) (got \(values[index]))")
    }
  }

  /// Rejects a signed min/max pair where `mins[i] > maxes[i]`. The caller
  /// has already checked that both arrays have the same length.
  static func requireOrderedPairs<Key: CodingKey>(
    mins: [Float], maxes: [Float], forKey key: Key, in container: KeyedDecodingContainer<Key>
  ) throws {
    if let index = mins.indices.first(where: { mins[$0] > maxes[$0] }) {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "signedMins[\(index)] exceeds signedMaxes[\(index)] "
          + "(got \(mins[index]) and \(maxes[index]))")
    }
  }

  /// True when `binStartSamples` and `range` are both empty, or when both
  /// are non-empty, the first element equals `range.lowerBound`, the last is
  /// below `range.upperBound`, and every element is strictly greater than
  /// the previous one. A grid with no bins over a non-empty range, or bins
  /// over an empty range, is invalid. The memberwise initializers check this
  /// with `precondition` and ``requireBinStarts(_:within:forKey:in:)``
  /// checks it on decode.
  static func binStartsAreValid(_ binStartSamples: [Int], within range: Range<Int>) -> Bool {
    guard let first = binStartSamples.first, let last = binStartSamples.last else {
      return range.isEmpty
    }
    guard !range.isEmpty, first == range.lowerBound, last < range.upperBound else {
      return false
    }
    return zip(binStartSamples, binStartSamples.dropFirst()).allSatisfy { $0 < $1 }
  }

  /// Rejects a bin grid that does not start ``coveredSampleRange`` and
  /// increase strictly within it (see ``binStartsAreValid(_:within:)``). The
  /// error names the empty side when exactly one of the grid and the range
  /// is empty, and the first offending index otherwise.
  static func requireBinStarts<Key: CodingKey>(
    _ binStartSamples: [Int], within range: Range<Int>, forKey key: Key,
    in container: KeyedDecodingContainer<Key>
  ) throws {
    guard !binStartsAreValid(binStartSamples, within: range) else { return }
    if binStartSamples.isEmpty {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue) is empty but coveredSampleRange \(range) is not")
    }
    if range.isEmpty {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue) has \(binStartSamples.count) values but coveredSampleRange "
          + "\(range) is empty")
    }
    if binStartSamples[0] != range.lowerBound {
      throw DecodingError.dataCorruptedError(
        forKey: key, in: container,
        debugDescription:
          "\(key.stringValue)[0] must start at coveredSampleRange's lower bound "
          + "\(range.lowerBound) (got \(binStartSamples[0]))")
    }
    let index =
      binStartSamples.indices.first { index in
        !range.contains(binStartSamples[index])
          || (index > 0 && binStartSamples[index] <= binStartSamples[index - 1])
      } ?? 0
    throw DecodingError.dataCorruptedError(
      forKey: key, in: container,
      debugDescription:
        "\(key.stringValue)[\(index)] breaks the strictly increasing order within "
        + "coveredSampleRange \(range) (got \(binStartSamples[index]))")
  }

  /// True when a record's bin grid matches `detail`'s: the same
  /// `sampleRate`, `columnsPerSecond`, `coveredSampleRange` and
  /// `binStartSamples`. ``WaveformAnalysisResult`` checks the overview and
  /// the energy record against the detail envelope with it, in both the
  /// memberwise `precondition` and ``WaveformAnalysisResult/init(from:)``.
  static func sharesGrid(
    sampleRate: Double, columnsPerSecond: Int, coveredSampleRange: Range<Int>,
    binStartSamples: [Int], with detail: WaveformDetailEnvelope
  ) -> Bool {
    sampleRate == detail.sampleRate && columnsPerSecond == detail.columnsPerSecond
      && coveredSampleRange == detail.coveredSampleRange
      && binStartSamples == detail.binStartSamples
  }
}
