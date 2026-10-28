//
//  WaveformBandLevelsFileTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.11 (DD-8, DD-9, DD-10): the waveform levels file format. Round
//  trips bit for bit, keys, slices, damaged bytes, crafted headers that carry
//  a valid checksum (so they reach the structural checks), diagnostic fields
//  that never invalidate, and the validating init's rejections.
//

import BoomBoomBoomKitTestSupport
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("WaveformBandLevels file format")
struct WaveformBandLevelsFileTests {
  private static let keyA = String(repeating: "0123456789abcdef", count: 4)
  private static let keyB = String(repeating: "fedcba9876543210", count: 4)
  private static let source = WaveformAudioSource(
    formatID: 0x6C70_636D, processingFormat: "float32 deinterleaved 2ch 44100.0Hz")

  // MARK: - Fixtures

  /// A reader result over a short stereo file of noise and tones.
  private static func readerResult() throws -> WaveformBandLevels {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "WaveformBandLevelsFileTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 70_000
    let left = SyntheticAudioFiles.noiseAndTones(frames: frames)
    let right = SyntheticAudioFiles.sine(5_000, amplitude: 0.9, frames: frames)
    let url = try SyntheticAudioFiles.writeFile(
      SyntheticAudioFile(frames: frames), samples: [left, right], in: folder)
    return try WaveformBandLevelReader.read(url: url)
  }

  /// A FLAC cut short, so `framesRead < frameCount`.
  private static func earlyEndResult() throws -> WaveformBandLevels {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "WaveformBandLevelsFileTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    let size = try #require(
      try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
    try SyntheticAudioFiles.truncate(url, to: size - SyntheticAudioFile.flacTailCut)
    return try WaveformBandLevelReader.read(url: url)
  }

  private static func emptyResult() throws -> WaveformBandLevels {
    try #require(
      WaveformBandLevels(
        peak: [], rms: [], sampleRate: 44_100, channelCount: 2, frameCount: 0, framesRead: 0,
        source: source))
  }

  /// A small valid result built without a file: 2 buckets at 44.1 kHz.
  private static func smallResult(
    peak: [WaveformBandLevel] = [
      WaveformBandLevel(low: 0.5, mid: 0.25, high: 1),
      WaveformBandLevel(low: 0, mid: 0.125, high: 0.75),
    ],
    rms: [WaveformBandLevel] = [
      WaveformBandLevel(low: 0.25, mid: 0.125, high: 0.5), .silent,
    ]
  ) throws -> WaveformBandLevels {
    try #require(
      WaveformBandLevels(
        peak: peak, rms: rms, sampleRate: 44_100, channelCount: 2, frameCount: 300,
        framesRead: 300, source: source))
  }

  /// Every value's bits, the counts, and the source, compared exactly.
  private static func expectBitIdentical(
    _ actual: WaveformBandLevels?, _ expected: WaveformBandLevels,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    guard let actual else {
      Issue.record("decoded is nil", sourceLocation: sourceLocation)
      return
    }
    #expect(actual == expected, sourceLocation: sourceLocation)
    func bits(_ levels: [WaveformBandLevel]) -> [UInt32] {
      levels.flatMap { [$0.low.bitPattern, $0.mid.bitPattern, $0.high.bitPattern] }
    }
    #expect(bits(actual.peak) == bits(expected.peak), sourceLocation: sourceLocation)
    #expect(bits(actual.rms) == bits(expected.rms), sourceLocation: sourceLocation)
    #expect(
      actual.sampleRate.bitPattern == expected.sampleRate.bitPattern, sourceLocation: sourceLocation
    )
    #expect(actual.frameCount == expected.frameCount, sourceLocation: sourceLocation)
    #expect(actual.framesRead == expected.framesRead, sourceLocation: sourceLocation)
    #expect(actual.channelCount == expected.channelCount, sourceLocation: sourceLocation)
    #expect(actual.source == expected.source, sourceLocation: sourceLocation)
    #expect(actual.analysisVersion == expected.analysisVersion, sourceLocation: sourceLocation)
    #expect(actual.bucketsPerSecond == expected.bucketsPerSecond, sourceLocation: sourceLocation)
  }

  // MARK: - Byte surgery

  /// The parts of an encoded file.
  private struct Parts {
    var prefix: [UInt8]
    var header: [String: Any]
    var payload: [UInt8]
  }

  private static func split(_ data: Data) throws -> Parts {
    let bytes = [UInt8](data)
    let headerCount =
      Int(bytes[12]) | Int(bytes[13]) << 8 | Int(bytes[14]) << 16 | Int(bytes[15]) << 24
    let headerBytes = Data(bytes[48..<(48 + headerCount)])
    let header = try #require(
      try JSONSerialization.jsonObject(with: headerBytes) as? [String: Any])
    return Parts(
      prefix: Array(bytes[0..<16]), header: header, payload: Array(bytes[(48 + headerCount)...]))
  }

  /// Reassembles `parts`, with `headerBytes` in place of the header when
  /// given, and a checksum that matches, so the result reaches every
  /// structural check.
  private static func assemble(_ parts: Parts, headerBytes: Data? = nil) throws -> Data {
    let header = try headerBytes ?? JSONSerialization.data(withJSONObject: parts.header)
    var prefix = parts.prefix
    let count = UInt32(header.count)
    prefix.replaceSubrange(
      12..<16,
      with: [
        UInt8(truncatingIfNeeded: count), UInt8(truncatingIfNeeded: count >> 8),
        UInt8(truncatingIfNeeded: count >> 16), UInt8(truncatingIfNeeded: count >> 24),
      ])
    return withChecksum(prefix: prefix, rest: [UInt8](header) + parts.payload)
  }

  /// `prefix` (16 bytes), then the SHA-256 of `prefix + rest`, then `rest`.
  private static func withChecksum(prefix: [UInt8], rest: [UInt8]) -> Data {
    var hasher = SHA256()
    hasher.update(data: prefix)
    hasher.update(data: rest)
    return Data(prefix + Array(hasher.finalize()) + rest)
  }

  /// A valid file whose header is changed by `edit`, its checksum rebuilt.
  private static func crafted(
    from levels: WaveformBandLevels, _ edit: (inout [String: Any]) -> Void
  ) throws -> Data {
    var parts = try split(try levels.encoded(forKey: keyA))
    edit(&parts.header)
    return try assemble(parts)
  }

  // MARK: - Round trips

  @Test("a reader result round-trips bit for bit")
  func readerResultRoundTrips() throws {
    let levels = try Self.readerResult()
    #expect(levels.peak.count == 239, "the premise: 70,000 frames at 44.1 kHz")
    let data = try levels.encoded(forKey: Self.keyA)
    #expect(data.count > 48 + levels.peak.count * 24)

    Self.expectBitIdentical(WaveformBandLevels.decoded(from: data, forKey: Self.keyA), levels)
  }

  @Test("the empty result round-trips")
  func emptyResultRoundTrips() throws {
    let levels = try Self.emptyResult()
    let data = try levels.encoded(forKey: Self.keyA)

    Self.expectBitIdentical(WaveformBandLevels.decoded(from: data, forKey: Self.keyA), levels)
  }

  @Test("an early-end-of-file result round-trips with framesRead unchanged")
  func earlyEOFResultRoundTrips() throws {
    let levels = try Self.earlyEndResult()
    #expect(levels.framesRead > 0 && levels.framesRead < levels.frameCount, "the premise")
    let data = try levels.encoded(forKey: Self.keyA)

    Self.expectBitIdentical(WaveformBandLevels.decoded(from: data, forKey: Self.keyA), levels)
  }

  @Test("a non-integral sample rate and a 256-byte processing format round-trip")
  func extremeHeaderValuesRoundTrip() throws {
    let format = String(repeating: "x", count: 256)
    let levels = try #require(
      WaveformBandLevels(
        peak: [.silent, .silent], rms: [.silent, .silent], sampleRate: 22_050.123456789012,
        channelCount: 64, frameCount: 200, framesRead: 17,
        source: WaveformAudioSource(formatID: .max, processingFormat: format)))
    let data = try levels.encoded(forKey: Self.keyA)

    Self.expectBitIdentical(WaveformBandLevels.decoded(from: data, forKey: Self.keyA), levels)
  }

  @Test("the header carries the diagnostic fields")
  func headerCarriesDiagnosticFields() throws {
    let levels = try Self.smallResult()
    let header = try Self.split(try levels.encoded(forKey: Self.keyA)).header

    let filterBank = try #require(header["filterBank"] as? [String: Any])
    #expect(filterBank["lowPassHz"] as? Double == 300)
    #expect(filterBank["midHighPassHz"] as? Double == 250)
    #expect(filterBank["midLowPassHz"] as? Double == 1_200)
    #expect(filterBank["highHighPassHz"] as? Double == 3_000)
    #expect(filterBank["highLowPassHz"] as? Double == 9_000)
    #expect(filterBank["highLowPassUsed"] as? Bool == true)
    #expect(filterBank["quality"] as? Double == 0.5.squareRoot())
    #expect(header["osVersion"] as? String == ProcessInfo.processInfo.operatingSystemVersionString)
    let createdAt = try #require(header["createdAt"] as? String)
    #expect(try Date(createdAt, strategy: .iso8601) <= Date())
    #expect(header["elementType"] as? String == "float32le")
    #expect(header["key"] as? String == Self.keyA)
    #expect(header["analysisVersion"] as? String == "band-peak-rms.loudest-channel.v1")
    #expect(header["bucketCount"] as? Int == 2)
    #expect(header["payloadByteCount"] as? Int == 48)
  }

  @Test("the layout: magic, version 1, header count, then the payload's little-endian bits")
  func layoutIsAsDocumented() throws {
    let levels = try Self.smallResult()
    let bytes = [UInt8](try levels.encoded(forKey: Self.keyA))

    #expect(Array(bytes[0..<8]) == Array("BBBKWAVE".utf8))
    #expect(Array(bytes[8..<12]) == [1, 0, 0, 0])
    let parts = try Self.split(Data(bytes))
    #expect(parts.payload.count == 2 * 24)
    // The first peak value, low 0.5: 0x3F000000 little-endian.
    #expect(Array(parts.payload[0..<4]) == [0x00, 0x00, 0x00, 0x3F])
    // The first RMS value starts after both peak buckets.
    #expect(Array(parts.payload[24..<28]) == [0x00, 0x00, 0x80, 0x3E])
  }

  // MARK: - Keys

  @Test("a file encoded for one key is nil for another valid key")
  func otherKeyIsNil() throws {
    let data = try Self.smallResult().encoded(forKey: Self.keyA)

    #expect(WaveformBandLevels.decoded(from: data, forKey: Self.keyB) == nil)
  }

  @Test(
    "a bad key: encoded throws invalidKey, decoded returns nil",
    arguments: [
      String(repeating: "a", count: 63), String(repeating: "A", count: 64),
      "../" + String(repeating: "a", count: 61), String(repeating: "a", count: 65),
      String(repeating: "g", count: 64), "",
    ])
  func badKeyIsRefused(key: String) throws {
    let levels = try Self.smallResult()

    let error = #expect(throws: WaveformBandLevelError.self) { try levels.encoded(forKey: key) }
    guard case .invalidKey(let reported) = error else {
      Issue.record("expected invalidKey, got \(String(describing: error))")
      return
    }
    #expect(reported == key)
    let data = try levels.encoded(forKey: Self.keyA)
    #expect(WaveformBandLevels.decoded(from: data, forKey: key) == nil)
  }

  // MARK: - Slices

  @Test("a slice that does not start at index 0: the valid one decodes, a truncated one is nil")
  func sliceInputIsParsedFromItsFirstByte() throws {
    let levels = try Self.readerResult()
    let data = try levels.encoded(forKey: Self.keyA)
    let container = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x42]) + data + Data([0x99])
    let start = 5
    let valid = container[start..<(container.count - 1)]
    #expect(valid.startIndex == start, "the premise: a slice with a nonzero start")

    Self.expectBitIdentical(WaveformBandLevels.decoded(from: valid, forKey: Self.keyA), levels)
    #expect(WaveformBandLevels.decoded(from: container[start...], forKey: Self.keyA) == nil)
    #expect(
      WaveformBandLevels.decoded(from: container[start..<(container.count - 2)], forKey: Self.keyA)
        == nil)
    #expect(
      WaveformBandLevels.decoded(from: container[start..<(start + 20)], forKey: Self.keyA) == nil)
  }

  // MARK: - Damaged bytes

  @Test("damaged bytes are nil and never trap")
  func damagedBytesAreNil() throws {
    let data = try Self.readerResult().encoded(forKey: Self.keyA)
    let bytes = [UInt8](data)
    let headerCount = Int(bytes[12]) | Int(bytes[13]) << 8
    var cases: [(String, [UInt8])] = []
    for length in [0, 1, 15, 47, 48, 48 + headerCount - 1, 48 + headerCount, bytes.count - 1] {
      cases.append(("truncated to \(length)", Array(bytes[0..<length])))
    }
    var flippedPayload = bytes
    flippedPayload[48 + headerCount + 5] ^= 0x01
    cases.append(("flipped payload byte", flippedPayload))
    var flippedLastPayload = bytes
    flippedLastPayload[bytes.count - 1] ^= 0x80
    cases.append(("flipped last payload byte", flippedLastPayload))
    var flippedHeader = bytes
    flippedHeader[48 + 3] ^= 0x01
    cases.append(("flipped header byte", flippedHeader))
    var flippedChecksum = bytes
    flippedChecksum[20] ^= 0x01
    cases.append(("flipped checksum byte", flippedChecksum))
    var version2 = bytes
    version2[8] = 2
    cases.append(("layout version 2", version2))
    cases.append(
      (
        "layout version 2, checksum rebuilt",
        [UInt8](Self.withChecksum(prefix: Array(version2[0..<16]), rest: Array(version2[48...])))
      ))
    var badMagic = bytes
    badMagic[0] = UInt8(ascii: "X")
    cases.append(("wrong magic", badMagic))
    cases.append(("one trailing byte", bytes + [0]))
    cases.append(("zeros", [UInt8](repeating: 0, count: bytes.count)))

    for (name, damaged) in cases {
      #expect(WaveformBandLevels.decoded(from: Data(damaged), forKey: Self.keyA) == nil, "\(name)")
    }
  }

  @Test("header byte counts out of range are nil, with the checksum rebuilt")
  func headerCountOutOfRangeIsNil() throws {
    let data = try Self.smallResult().encoded(forKey: Self.keyA)
    let bytes = [UInt8](data)
    for count: UInt32 in [0, 65_537, UInt32(bytes.count - 48 + 1), .max] {
      var prefix = Array(bytes[0..<16])
      prefix.replaceSubrange(
        12..<16,
        with: [
          UInt8(truncatingIfNeeded: count), UInt8(truncatingIfNeeded: count >> 8),
          UInt8(truncatingIfNeeded: count >> 16), UInt8(truncatingIfNeeded: count >> 24),
        ])
      let rebuilt = Self.withChecksum(prefix: prefix, rest: Array(bytes[48...]))
      #expect(WaveformBandLevels.decoded(from: rebuilt, forKey: Self.keyA) == nil, "H = \(count)")
    }
  }

  @Test("a header that is not JSON, with the checksum rebuilt, is nil")
  func headerNotJSONIsNil() throws {
    let parts = try Self.split(try Self.smallResult().encoded(forKey: Self.keyA))
    for header in ["not json", "{", "[]", "{\"key\": 1}", String(repeating: "[", count: 10_000)] {
      let data = try Self.assemble(parts, headerBytes: Data(header.utf8))
      #expect(
        WaveformBandLevels.decoded(from: data, forKey: Self.keyA) == nil, "\(header.prefix(20))")
    }
  }

  // MARK: - Crafted headers with a valid checksum

  private static let int64Max = NSNumber(value: Int64.max)

  @Test("crafted headers with a valid checksum are nil and never trap")
  func craftedHeadersAreNil() throws {
    let levels = try Self.smallResult()
    let edits: [(String, (inout [String: Any]) -> Void)] = [
      ("negative framesRead", { $0["framesRead"] = -1 }),
      ("framesRead above frameCount", { $0["framesRead"] = 301 }),
      ("channelCount 0", { $0["channelCount"] = 0 }),
      ("channelCount negative", { $0["channelCount"] = -2 }),
      ("wrong bucketCount", { $0["bucketCount"] = 3 }),
      ("negative bucketCount", { $0["bucketCount"] = -2 }),
      ("wrong payloadByteCount", { $0["payloadByteCount"] = 72 }),
      ("huge payloadByteCount", { $0["payloadByteCount"] = Self.int64Max }),
      (
        "sampleRate 1e-300 with frameCount 2",
        {
          $0["sampleRate"] = 1e-300
          $0["frameCount"] = 2
          $0["framesRead"] = 2
        }
      ),
      (
        "frameCount near Int64.max",
        {
          $0["frameCount"] = NSNumber(value: Int64.max - 1)
          $0["framesRead"] = 0
        }
      ),
      (
        "frameCount near Int64.max with a matching bucketCount",
        {
          let frameCount = Int64.max - 1
          $0["frameCount"] = NSNumber(value: frameCount)
          $0["framesRead"] = 0
          $0["bucketCount"] = WaveformBandLevels.bucketCount(
            frameCount: frameCount, sampleRate: 44_100)
          $0["payloadByteCount"] = Self.int64Max
        }
      ),
      (
        "the largest bucket count a header can claim, at the lowest rate",
        {
          let frameCount = Int64.max
          $0["frameCount"] = NSNumber(value: frameCount)
          $0["sampleRate"] = 6_000.000_000_001
          $0["framesRead"] = 0
          let buckets = WaveformBandLevels.bucketCount(
            frameCount: frameCount, sampleRate: 6_000.000_000_001)
          $0["bucketCount"] = buckets
          $0["payloadByteCount"] = buckets.map { $0 &* 24 }
        }
      ),
      ("negative frameCount", { $0["frameCount"] = -1 }),
      ("sampleRate at 6,000", { $0["sampleRate"] = 6_000 }),
      ("sampleRate negative", { $0["sampleRate"] = -44_100 }),
      ("bucketsPerSecond 100", { $0["bucketsPerSecond"] = 100 }),
      ("older analysisVersion", { $0["analysisVersion"] = "band-peak-rms.loudest-channel.v0" }),
      ("elementType float16le", { $0["elementType"] = "float16le" }),
      ("other key in the header", { $0["key"] = Self.keyB }),
      ("missing key", { $0["key"] = nil }),
      ("missing source", { $0["source"] = nil }),
      (
        "formatID out of UInt32 range",
        { $0["source"] = ["formatID": -1, "processingFormat": "x"] }
      ),
      ("frameCount as a string", { $0["frameCount"] = "300" }),
      (
        "processingFormat over 256 bytes",
        { $0["source"] = ["formatID": 1, "processingFormat": String(repeating: "y", count: 257)] }
      ),
    ]
    for (name, edit) in edits {
      let data = try Self.crafted(from: levels, edit)
      #expect(WaveformBandLevels.decoded(from: data, forKey: Self.keyA) == nil, "\(name)")
    }
  }

  @Test("payload values out of range, with the checksum rebuilt, are nil")
  func payloadValuesOutOfRangeAreNil() throws {
    let levels = try Self.smallResult()
    for value in [Float.nan, .infinity, -.infinity, -0.5, 1.000_001, .greatestFiniteMagnitude] {
      var parts = try Self.split(try levels.encoded(forKey: Self.keyA))
      let bits = value.bitPattern
      parts.payload.replaceSubrange(
        28..<32,
        with: [
          UInt8(truncatingIfNeeded: bits), UInt8(truncatingIfNeeded: bits >> 8),
          UInt8(truncatingIfNeeded: bits >> 16), UInt8(truncatingIfNeeded: bits >> 24),
        ])
      let data = try Self.assemble(parts)
      #expect(WaveformBandLevels.decoded(from: data, forKey: Self.keyA) == nil, "\(value)")
    }
  }

  @Test("the payload byte count is overflow-checked")
  func payloadByteCountIsOverflowChecked() {
    #expect(WaveformBandLevels.payloadByteCount(bucketCount: 2) == 48)
    #expect(WaveformBandLevels.payloadByteCount(bucketCount: Int.max / 24 + 1) == nil)
    #expect(WaveformBandLevels.payloadByteCount(bucketCount: Int.max) == nil)
    #expect(WaveformBandLevels.payloadByteCount(bucketCount: -1) == nil)
    #expect(WaveformBandLevels.bucketCount(frameCount: 2, sampleRate: 1e-300) == nil)
    #expect(WaveformBandLevels.bucketCount(frameCount: -1, sampleRate: 44_100) == nil)
    #expect(WaveformBandLevels.bucketCount(frameCount: .max, sampleRate: 1e-3) == nil)
  }

  // MARK: - Diagnostic fields

  @Test(
    "rewritten or removed diagnostic fields, with the checksum rebuilt, decode equal to the original"
  )
  func diagnosticFieldsNeverInvalidate() throws {
    let levels = try Self.readerResult()
    let edits: [(String, (inout [String: Any]) -> Void)] = [
      (
        "rewritten",
        {
          $0["osVersion"] = "Some Other OS 99"
          $0["createdAt"] = "not a date"
          $0["filterBank"] = ["lowPassHz": "anything", "extra": [1, 2, 3]]
        }
      ),
      (
        "removed",
        {
          $0["osVersion"] = nil
          $0["createdAt"] = nil
          $0["filterBank"] = nil
        }
      ),
      ("an unknown key added", { $0["somethingNew"] = ["nested": true] }),
    ]
    for (name, edit) in edits {
      let data = try Self.crafted(from: levels, edit)
      let decoded = WaveformBandLevels.decoded(from: data, forKey: Self.keyA)
      #expect(decoded != nil, "\(name)")
      Self.expectBitIdentical(decoded, levels)
    }
  }

  // MARK: - Validating init

  @Test("the validating init rejects every broken invariant")
  func validatingInitRejectsBrokenInvariants() {
    let two: [WaveformBandLevel] = [.silent, .silent]
    func make(
      peak: [WaveformBandLevel] = two, rms: [WaveformBandLevel] = two,
      sampleRate: Double = 44_100, channelCount: Int = 2, frameCount: Int64 = 300,
      framesRead: Int64 = 300, source: WaveformAudioSource = Self.source
    ) -> WaveformBandLevels? {
      WaveformBandLevels(
        peak: peak, rms: rms, sampleRate: sampleRate, channelCount: channelCount,
        frameCount: frameCount, framesRead: framesRead, source: source)
    }
    #expect(make() != nil, "the baseline is valid")
    #expect(make(frameCount: 295, framesRead: 295) != nil, "295 frames are still 2 buckets")
    #expect(make(frameCount: 0, framesRead: 0) == nil, "0 frames are 0 buckets, not 2")
    #expect(make(peak: [.silent]) == nil, "peak count")
    #expect(make(rms: [.silent, .silent, .silent]) == nil, "rms count")
    #expect(make(frameCount: 294, framesRead: 294) == nil, "294 frames are 1 bucket")
    #expect(make(sampleRate: .nan) == nil, "NaN rate")
    #expect(make(sampleRate: .infinity) == nil, "infinite rate")
    #expect(make(sampleRate: 6_000) == nil, "6 kHz")
    #expect(make(sampleRate: -44_100) == nil, "negative rate")
    #expect(make(sampleRate: 1e-300, frameCount: 2, framesRead: 2) == nil, "tiny rate")
    #expect(make(channelCount: 0) == nil, "no channels")
    #expect(make(frameCount: -1, framesRead: 0) == nil, "negative frame count")
    #expect(make(framesRead: -1) == nil, "negative framesRead")
    #expect(make(framesRead: 301) == nil, "framesRead above frameCount")
    #expect(make(framesRead: 0) != nil, "framesRead 0 is an early end, not an error")
    for bad in [Float.nan, .infinity, -.infinity, -0.001, 1.001] {
      let level = WaveformBandLevel(low: 0, mid: bad, high: 0)
      #expect(make(peak: [level, .silent]) == nil, "peak \(bad)")
      #expect(make(rms: [.silent, level]) == nil, "rms \(bad)")
    }
    let longFormat = WaveformAudioSource(
      formatID: 1, processingFormat: String(repeating: "\u{e9}", count: 129))
    #expect(make(source: longFormat) == nil, "258 UTF-8 bytes")
    let edgeFormat = WaveformAudioSource(
      formatID: 1, processingFormat: String(repeating: "z", count: 256))
    #expect(make(source: edgeFormat) != nil, "256 bytes is allowed")
    let full = make(peak: [WaveformBandLevel(low: 1, mid: 1, high: 1), .silent])
    #expect(full?.bucketsPerSecond == 150)
    #expect(full?.analysisVersion == WaveformBandLevelReader.analysisVersion)
  }

  @Test("error descriptions are readable")
  func errorDescriptionsAreReadable() {
    let url = URL(fileURLWithPath: "/tmp/track.wav")
    let unsupported = WaveformBandLevelError.unsupportedFormat(url, sampleRate: 6_000)
    #expect(unsupported.localizedDescription.contains("track.wav"))
    #expect(unsupported.localizedDescription.contains("6000.0 Hz"))
    #expect(WaveformBandLevelError.invalidKey("ABC").localizedDescription.contains("\"ABC\""))
    #expect(
      WaveformBandLevelError.headerTooLarge(byteCount: 70_000).localizedDescription.contains(
        "70000"))
  }
}
