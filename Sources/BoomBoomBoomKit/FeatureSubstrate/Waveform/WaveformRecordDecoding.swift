//
//  WaveformRecordDecoding.swift
//  BoomBoomBoomKit
//
//  Story 15.4: shared decode-time validation for the three Codable waveform
//  records.
//

/// Throwing checks used by the `init(from:)` of ``WaveformDetailEnvelope``,
/// ``WaveformPeakOverview`` and ``WaveformEnergyChannels``.
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
}
