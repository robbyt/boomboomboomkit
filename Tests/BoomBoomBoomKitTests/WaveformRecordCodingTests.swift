//
//  WaveformRecordCodingTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.4: Codable round trip and decode-time validation for the three
//  public waveform records. A corrupt payload must throw DecodingError, never
//  decode into a record that breaks its own contract, and never trap.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Waveform record coding (Story 15.4)")
struct WaveformRecordCodingTests {

  // MARK: - Helpers

  /// One second of a two-tone signal, so every record carries non-zero,
  /// non-trivial values in each array.
  private static func analyzed() throws -> WaveformAnalysisResult {
    let sampleRate = 44_100.0
    let count = Int(sampleRate)
    var samples = [Float](repeating: 0, count: count)
    for i in 0..<count {
      let t = Double(i) / sampleRate
      samples[i] = Float(0.4 * sin(2 * .pi * 80 * t) + 0.3 * sin(2 * .pi * 6_000 * t))
    }
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    return try WaveformAnalyzer.analyze(decoded: decoded)
  }

  private static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(value)
  }

  /// Decoder that reads the string `"NaN"` as `Float.nan`, so a hand-built
  /// NaN reaches the record's validation instead of failing JSON parsing.
  private static func nonConformingDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: "+Inf", negativeInfinity: "-Inf", nan: "NaN")
    return decoder
  }

  private static func object(_ data: Data) throws -> [String: Any] {
    try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private static func data(_ object: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }

  /// Returns `data` with the last element of the array at `key` removed.
  private static func droppingLast(_ key: String, from data: Data) throws -> Data {
    var object = try object(data)
    var array = try #require(object[key] as? [Any])
    try #require(!array.isEmpty)
    array.removeLast()
    object[key] = array
    return try Self.data(object)
  }

  /// Returns `data` with the first element of the array at `key` replaced by
  /// the non-conforming string `"NaN"`.
  private static func replacingFirstWithNaN(_ key: String, in data: Data) throws -> Data {
    var object = try object(data)
    var array = try #require(object[key] as? [Any])
    try #require(!array.isEmpty)
    array[0] = "NaN"
    object[key] = array
    return try Self.data(object)
  }

  /// Returns `data` with the top-level `key` set to `value`.
  private static func setting(_ key: String, to value: Any, in data: Data) throws -> Data {
    var object = try object(data)
    object[key] = value
    return try Self.data(object)
  }

  /// Returns `data` with `edit` applied to the `binStartSamples` array.
  private static func editingBinStarts(
    in data: Data, _ edit: (inout [Int]) -> Void
  ) throws -> Data {
    var object = try object(data)
    var starts = try #require(object["binStartSamples"] as? [Int])
    try #require(starts.count >= 3)
    edit(&starts)
    object["binStartSamples"] = starts
    return try Self.data(object)
  }

  /// Returns `data` with `key` inside the nested record `record` set to
  /// `value`.
  private static func setting(
    _ key: String, to value: Any, inRecord record: String, of data: Data
  ) throws -> Data {
    var object = try object(data)
    var nested = try #require(object[record] as? [String: Any])
    nested[key] = value
    object[record] = nested
    return try Self.data(object)
  }

  /// Rewrites both stored version strings to `"v0"` in the JSON text.
  private static func rewritingVersionStrings(in data: Data, algorithm: String) throws -> Data {
    let text = try #require(String(data: data, encoding: .utf8))
    let schemaField = "\"schemaVersion\":\"v1\""
    let algorithmField = "\"algorithmIdentifier\":\"\(algorithm)\""
    try #require(text.contains(schemaField))
    try #require(text.contains(algorithmField))
    let edited =
      text
      .replacingOccurrences(of: schemaField, with: "\"schemaVersion\":\"v0\"")
      .replacingOccurrences(of: algorithmField, with: "\"algorithmIdentifier\":\"v0\"")
    return Data(edited.utf8)
  }

  // MARK: - Round trip

  @Test func detailEnvelopeRoundTrips() throws {
    let original = try Self.analyzed().detail
    #expect(!original.magnitudes.isEmpty)
    let decoded = try JSONDecoder().decode(
      WaveformDetailEnvelope.self, from: Self.encode(original))
    #expect(decoded == original)
  }

  @Test func peakOverviewRoundTrips() throws {
    let original = try Self.analyzed().overview
    #expect(!original.signedMins.isEmpty)
    let decoded = try JSONDecoder().decode(
      WaveformPeakOverview.self, from: Self.encode(original))
    #expect(decoded == original)
  }

  @Test func energyChannelsRoundTrip() throws {
    let original = try Self.analyzed().energy
    #expect(!original.lowBand.isEmpty)
    let decoded = try JSONDecoder().decode(
      WaveformEnergyChannels.self, from: Self.encode(original))
    #expect(decoded == original)
  }

  // MARK: - Control

  /// The rejection tests below re-serialize through `JSONSerialization`.
  /// An untouched re-serialized payload must still decode, so a rejection is
  /// caused by the edit and not by the re-serialization.
  @Test func reserializedPayloadsStillDecode() throws {
    let result = try Self.analyzed()
    let detail = try Self.setting("schemaVersion", to: "v1", in: Self.encode(result.detail))
    let overview = try Self.setting("schemaVersion", to: "v1", in: Self.encode(result.overview))
    let energy = try Self.setting("schemaVersion", to: "v1", in: Self.encode(result.energy))
    #expect(try JSONDecoder().decode(WaveformDetailEnvelope.self, from: detail) == result.detail)
    #expect(try JSONDecoder().decode(WaveformPeakOverview.self, from: overview) == result.overview)
    #expect(try JSONDecoder().decode(WaveformEnergyChannels.self, from: energy) == result.energy)
  }

  // MARK: - Array length mismatch

  @Test func detailEnvelopeRejectsMismatchedArrayLengths() throws {
    let data = try Self.encode(Self.analyzed().detail)
    for key in ["binStartSamples", "magnitudes"] {
      let corrupt = try Self.droppingLast(key, from: data)
      #expect(throws: DecodingError.self, "dropped from \(key)") {
        try JSONDecoder().decode(WaveformDetailEnvelope.self, from: corrupt)
      }
    }
  }

  @Test func peakOverviewRejectsMismatchedArrayLengths() throws {
    let data = try Self.encode(Self.analyzed().overview)
    for key in ["binStartSamples", "signedMins", "signedMaxes"] {
      let corrupt = try Self.droppingLast(key, from: data)
      #expect(throws: DecodingError.self, "dropped from \(key)") {
        try JSONDecoder().decode(WaveformPeakOverview.self, from: corrupt)
      }
    }
  }

  @Test func energyChannelsRejectMismatchedArrayLengths() throws {
    let data = try Self.encode(Self.analyzed().energy)
    for key in ["binStartSamples", "lowBand", "midBand", "highBand"] {
      let corrupt = try Self.droppingLast(key, from: data)
      #expect(throws: DecodingError.self, "dropped from \(key)") {
        try JSONDecoder().decode(WaveformEnergyChannels.self, from: corrupt)
      }
    }
  }

  // MARK: - Non-finite values

  @Test func detailEnvelopeRejectsNaN() throws {
    let data = try Self.encode(Self.analyzed().detail)
    // The non-conforming decoder alone must not be what rejects the payload.
    _ = try Self.nonConformingDecoder().decode(WaveformDetailEnvelope.self, from: data)
    let corrupt = try Self.replacingFirstWithNaN("magnitudes", in: data)
    #expect(throws: DecodingError.self) {
      try Self.nonConformingDecoder().decode(WaveformDetailEnvelope.self, from: corrupt)
    }
  }

  @Test func peakOverviewRejectsNaN() throws {
    let data = try Self.encode(Self.analyzed().overview)
    _ = try Self.nonConformingDecoder().decode(WaveformPeakOverview.self, from: data)
    for key in ["signedMins", "signedMaxes"] {
      let corrupt = try Self.replacingFirstWithNaN(key, in: data)
      #expect(throws: DecodingError.self, "NaN in \(key)") {
        try Self.nonConformingDecoder().decode(WaveformPeakOverview.self, from: corrupt)
      }
    }
  }

  @Test func energyChannelsRejectNaN() throws {
    let data = try Self.encode(Self.analyzed().energy)
    _ = try Self.nonConformingDecoder().decode(WaveformEnergyChannels.self, from: data)
    for key in ["lowBand", "midBand", "highBand"] {
      let corrupt = try Self.replacingFirstWithNaN(key, in: data)
      #expect(throws: DecodingError.self, "NaN in \(key)") {
        try Self.nonConformingDecoder().decode(WaveformEnergyChannels.self, from: corrupt)
      }
    }
  }

  // MARK: - Negative magnitudes and inverted peak pairs

  @Test func detailEnvelopeRejectsNegativeMagnitude() throws {
    let original = try Self.analyzed().detail
    let data = try Self.encode(original)
    var magnitudes = original.magnitudes.map(Double.init)
    // Control: a positive replacement still decodes.
    magnitudes[0] = 0.25
    let control = try Self.setting("magnitudes", to: magnitudes, in: data)
    _ = try JSONDecoder().decode(WaveformDetailEnvelope.self, from: control)
    magnitudes[0] = -0.25
    let corrupt = try Self.setting("magnitudes", to: magnitudes, in: data)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformDetailEnvelope.self, from: corrupt)
    }
  }

  @Test func energyChannelsRejectNegativeBand() throws {
    let original = try Self.analyzed().energy
    let data = try Self.encode(original)
    var midBand = original.midBand.map(Double.init)
    // Control: a positive replacement still decodes.
    midBand[0] = 0.1
    let control = try Self.setting("midBand", to: midBand, in: data)
    _ = try JSONDecoder().decode(WaveformEnergyChannels.self, from: control)
    midBand[0] = -0.1
    let corrupt = try Self.setting("midBand", to: midBand, in: data)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformEnergyChannels.self, from: corrupt)
    }
  }

  @Test func peakOverviewRejectsInvertedPair() throws {
    let original = try Self.analyzed().overview
    let index = try #require(
      original.signedMins.indices.first { original.signedMins[$0] < original.signedMaxes[$0] })
    #expect(original.signedMins[index] != original.signedMaxes[index])
    var mins = original.signedMins.map(Double.init)
    var maxes = original.signedMaxes.map(Double.init)
    swap(&mins[index], &maxes[index])
    let swappedMins = try Self.setting("signedMins", to: mins, in: Self.encode(original))
    let corrupt = try Self.setting("signedMaxes", to: maxes, in: swappedMins)
    #expect(throws: DecodingError.self, "signedMins[\(index)] > signedMaxes[\(index)]") {
      try JSONDecoder().decode(WaveformPeakOverview.self, from: corrupt)
    }
  }

  // MARK: - Scalar fields

  @Test func detailEnvelopeRejectsBadScalars() throws {
    let data = try Self.encode(Self.analyzed().detail)
    let corrupt = [
      try Self.setting("columnsPerSecond", to: 0, in: data),
      try Self.setting("sampleRate", to: 0, in: data),
      try Self.setting("coveredSampleRange", to: [-1, 44_100], in: data),
      try Self.setting("coveredSampleRange", to: [44_100, 0], in: data),
    ]
    for payload in corrupt {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WaveformDetailEnvelope.self, from: payload)
      }
    }
  }

  @Test func peakOverviewRejectsBadScalars() throws {
    let data = try Self.encode(Self.analyzed().overview)
    let corrupt = [
      try Self.setting("columnsPerSecond", to: 0, in: data),
      try Self.setting("sampleRate", to: -44_100, in: data),
    ]
    for payload in corrupt {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WaveformPeakOverview.self, from: payload)
      }
    }
  }

  @Test func energyChannelsRejectBadScalarsAndCrossovers() throws {
    let data = try Self.encode(Self.analyzed().energy)
    let corrupt = [
      try Self.setting("columnsPerSecond", to: 0, in: data),
      try Self.setting("sampleRate", to: 0, in: data),
      try Self.setting("lowMidCutoffHz", to: 0, in: data),
      try Self.setting("lowMidCutoffHz", to: 5_000, in: data),
      try Self.setting("midHighCutoffHz", to: 30_000, in: data),
    ]
    for payload in corrupt {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WaveformEnergyChannels.self, from: payload)
      }
    }
  }

  // MARK: - Bin starts

  @Test func detailEnvelopeRejectsBadBinStarts() throws {
    let original = try Self.analyzed().detail
    let data = try Self.encode(original)
    let upperBound = original.coveredSampleRange.upperBound
    let corrupt = [
      try Self.editingBinStarts(in: data) { $0[1] = $0[0] },
      try Self.editingBinStarts(in: data) { $0.swapAt(1, 2) },
      try Self.editingBinStarts(in: data) { $0[$0.count - 1] = upperBound },
    ]
    for payload in corrupt {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WaveformDetailEnvelope.self, from: payload)
      }
    }
  }

  @Test func detailEnvelopeRejectsBinGridNotStartingTheRange() throws {
    let original = try Self.analyzed().detail
    try #require(original.coveredSampleRange.lowerBound == 0)
    // Keep the grid strictly increasing so only the start check can fail.
    try #require(original.binStartSamples[1] > 10)
    let corrupt = try Self.editingBinStarts(in: Self.encode(original)) { $0[0] = 10 }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformDetailEnvelope.self, from: corrupt)
    }
  }

  @Test func detailEnvelopeRejectsEmptyBinGridOverNonEmptyRange() throws {
    let original = try Self.analyzed().detail
    try #require(!original.coveredSampleRange.isEmpty)
    let emptyStarts = try Self.setting("binStartSamples", to: [Int](), in: Self.encode(original))
    let corrupt = try Self.setting("magnitudes", to: [Double](), in: emptyStarts)
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformDetailEnvelope.self, from: corrupt)
    }
  }

  @Test func peakOverviewRejectsDescendingBinStarts() throws {
    let data = try Self.encode(Self.analyzed().overview)
    let corrupt = try Self.editingBinStarts(in: data) { $0.swapAt(1, 2) }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformPeakOverview.self, from: corrupt)
    }
  }

  @Test func energyChannelsRejectDuplicatedBinStart() throws {
    let data = try Self.encode(Self.analyzed().energy)
    let corrupt = try Self.editingBinStarts(in: data) { $0[1] = $0[0] }
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WaveformEnergyChannels.self, from: corrupt)
    }
  }

  // MARK: - Combined result shares one bin grid

  @Test func analysisResultRoundTrips() throws {
    let original = try Self.analyzed()
    let decoded = try JSONDecoder().decode(
      WaveformAnalysisResult.self, from: Self.encode(original))
    #expect(decoded == original)
  }

  @Test func zeroSampleResultRoundTrips() throws {
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: [],
      sampleRate: 44_100,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let original = try WaveformAnalyzer.analyze(decoded: decoded)
    #expect(original.detail.coveredSampleRange.isEmpty)
    #expect(original.detail.binStartSamples.isEmpty)
    let roundTripped = try JSONDecoder().decode(
      WaveformAnalysisResult.self, from: Self.encode(original))
    #expect(roundTripped == original)
  }

  @Test func analysisResultRejectsRecordsOffTheSharedGrid() throws {
    let original = try Self.analyzed()
    let data = try Self.encode(original)
    // Control: an untouched re-serialized payload still decodes.
    let control = try Self.setting("columnsPerSecond", to: 150, inRecord: "energy", of: data)
    #expect(try JSONDecoder().decode(WaveformAnalysisResult.self, from: control) == original)
    // Bin 0 stays at the range's lower bound so the energy record is valid on
    // its own and only the shared-grid check can reject it.
    let shiftedStarts = original.energy.binStartSamples.enumerated().map {
      $0.offset == 0 ? $0.element : $0.element + 1
    }
    _ = try JSONDecoder().decode(
      WaveformEnergyChannels.self,
      from: Self.setting("binStartSamples", to: shiftedStarts, in: Self.encode(original.energy)))
    let corrupt = [
      try Self.setting("columnsPerSecond", to: 100, inRecord: "energy", of: data),
      try Self.setting("binStartSamples", to: shiftedStarts, inRecord: "energy", of: data),
    ]
    for payload in corrupt {
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(WaveformAnalysisResult.self, from: payload)
      }
    }
  }

  // MARK: - Version strings carried as encoded

  @Test func detailEnvelopeCarriesEncodedVersionStrings() throws {
    let original = try Self.analyzed().detail
    let edited = try Self.rewritingVersionStrings(
      in: Self.encode(original), algorithm: WaveformDetailEnvelope.algorithmIdentifier)
    let decoded = try JSONDecoder().decode(WaveformDetailEnvelope.self, from: edited)
    #expect(decoded.schemaVersion == "v0")
    #expect(decoded.algorithmIdentifier == "v0")
    #expect(decoded.magnitudes == original.magnitudes)
  }

  @Test func peakOverviewCarriesEncodedVersionStrings() throws {
    let original = try Self.analyzed().overview
    let edited = try Self.rewritingVersionStrings(
      in: Self.encode(original), algorithm: WaveformPeakOverview.algorithmIdentifier)
    let decoded = try JSONDecoder().decode(WaveformPeakOverview.self, from: edited)
    #expect(decoded.schemaVersion == "v0")
    #expect(decoded.algorithmIdentifier == "v0")
    #expect(decoded.signedMaxes == original.signedMaxes)
  }

  @Test func energyChannelsCarryEncodedVersionStrings() throws {
    let original = try Self.analyzed().energy
    let edited = try Self.rewritingVersionStrings(
      in: Self.encode(original), algorithm: WaveformEnergyChannels.algorithmIdentifier)
    let decoded = try JSONDecoder().decode(WaveformEnergyChannels.self, from: edited)
    #expect(decoded.schemaVersion == "v0")
    #expect(decoded.algorithmIdentifier == "v0")
    #expect(decoded.highBand == original.highBand)
  }
}
