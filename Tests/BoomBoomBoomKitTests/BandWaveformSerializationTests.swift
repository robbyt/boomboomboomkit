//
//  BandWaveformSerializationTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.11 (DD-8, DD-9, DD-10): the serialized `BandWaveform` format. Round
//  trips bit for bit, keys, slices, damaged bytes, crafted headers that carry
//  a valid checksum (so they reach the structural checks), diagnostic fields
//  that never invalidate, and the validating init's rejections.
//

import BoomBoomBoomKitTestSupport
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BandWaveform file format")
struct BandWaveformSerializationTests {
  private static let source = BandWaveform.Source(
    formatID: 0x6C70_636D, processingFormat: "float32 deinterleaved 2ch 44100.0Hz")

  // MARK: - Fixtures

  /// A reader result over a short stereo file of noise and tones.
  private static func readerResult() throws -> BandWaveform {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "BandWaveformSerializationTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 70_000
    let left = SyntheticAudioFiles.noiseAndTones(frames: frames)
    let right = SyntheticAudioFiles.sine(5_000, amplitude: 0.9, frames: frames)
    let url = try SyntheticAudioFiles.writeFile(
      SyntheticAudioFile(frames: frames), samples: [left, right], in: folder)
    return try BandWaveformReader.read(url: url)
  }

  /// A FLAC cut short, so `framesRead < frameCount`.
  private static func earlyEndResult() throws -> BandWaveform {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "BandWaveformSerializationTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    let size = try #require(
      try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
    try SyntheticAudioFiles.truncate(url, to: size - SyntheticAudioFile.flacTailCut)
    return try BandWaveformReader.read(url: url)
  }

  private static func emptyResult() throws -> BandWaveform {
    try #require(
      BandWaveform(
        peak: [], rms: [], sampleRate: 44_100, channelCount: 2, frameCount: 0, framesRead: 0,
        source: source))
  }

  /// A small valid result built without a file: 2 buckets at 44.1 kHz.
  private static func smallResult(
    peak: [BandWaveform.Levels] = [
      BandWaveform.Levels(low: 0.5, mid: 0.25, high: 1),
      BandWaveform.Levels(low: 0, mid: 0.125, high: 0.75),
    ],
    rms: [BandWaveform.Levels] = [
      BandWaveform.Levels(low: 0.25, mid: 0.125, high: 0.5), .silent,
    ]
  ) throws -> BandWaveform {
    try #require(
      BandWaveform(
        peak: peak, rms: rms, sampleRate: 44_100, channelCount: 2, frameCount: 300,
        framesRead: 300, source: source))
  }

  /// Every value's bits, the counts, and the source, compared exactly.
  private static func expectBitIdentical(
    _ actual: BandWaveform?, _ expected: BandWaveform,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    guard let actual else {
      Issue.record("decoded is nil", sourceLocation: sourceLocation)
      return
    }
    #expect(actual == expected, sourceLocation: sourceLocation)
    func bits(_ levels: [BandWaveform.Levels]) -> [UInt32] {
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
    from waveform: BandWaveform, _ edit: (inout [String: Any]) -> Void
  ) throws -> Data {
    var parts = try split(waveform.serializedData())
    edit(&parts.header)
    return try assemble(parts)
  }

  // MARK: - Round trips

  @Test("a reader result round-trips bit for bit")
  func readerResultRoundTrips() throws {
    let waveform = try Self.readerResult()
    #expect(waveform.peak.count == 239, "the premise: 70,000 frames at 44.1 kHz")
    let data = waveform.serializedData()
    #expect(data.count > 48 + waveform.peak.count * 24)

    Self.expectBitIdentical(BandWaveform(serializedData: data), waveform)
  }

  /// Bytes written by the format before the public names changed, kept
  /// verbatim so a later edit cannot silently change the layout. 700 frames at
  /// 44.1 kHz (3 buckets), stereo, `framesRead` 650, a FLAC source.
  private static let storedBlob =
    "QkJCS1dBVkUBAAAAIAIAANiRQ46tkHyrc4+nCq/MkkMn9ZdvX+Zm2Vm6YYPctjc6eyJhbmFseXNpc1ZlcnNpb24iOiJiYW5k"
    + "LXBlYWstcm1zLmxvdWRlc3QtY2hhbm5lbC52MSIsImJ1Y2tldENvdW50IjozLCJidWNrZXRzUGVyU2Vjb25kIjoxNTAsImNo"
    + "YW5uZWxDb3VudCI6MiwiY3JlYXRlZEF0IjoiMjAyNi0xMC0yOFQwMjo0OTo0OVoiLCJlbGVtZW50VHlwZSI6ImZsb2F0MzJs"
    + "ZSIsImZpbHRlckJhbmsiOnsiaGlnaEhpZ2hQYXNzSHoiOjMwMDAsImhpZ2hMb3dQYXNzSHoiOjkwMDAsImhpZ2hMb3dQYXNz"
    + "VXNlZCI6dHJ1ZSwibG93UGFzc0h6IjozMDAsIm1pZEhpZ2hQYXNzSHoiOjI1MCwibWlkTG93UGFzc0h6IjoxMjAwLCJxdWFs"
    + "aXR5IjowLjcwNzEwNjc4MTE4NjU0NzZ9LCJmcmFtZUNvdW50Ijo3MDAsImZyYW1lc1JlYWQiOjY1MCwib3NWZXJzaW9uIjoi"
    + "VmVyc2lvbiAyNy4yIChCdWlsZCAyNkIxMTgpIiwicGF5bG9hZEJ5dGVDb3VudCI6NzIsInNhbXBsZVJhdGUiOjQ0MTAwLCJz"
    + "b3VyY2UiOnsiZm9ybWF0SUQiOjE3MTgzNzg4NTEsInByb2Nlc3NpbmdGb3JtYXQiOiJmbG9hdDMyIGRlaW50ZXJsZWF2ZWQg"
    + "MmNoIDQ0MTAwLjBIeiJ9fQAAAD8AAIA+AACAPwAAQD8AAAA+AACAPc3MzD3NzEw+mpmZPgAAgD4AAAA+AAAAPwAAAD8AAIA9"
    + "AAAAPQAAAAAAAAAAAAAAAA=="

  @Test("bytes stored before the rename still decode, equal to the values written")
  func storedBlobStillDecodes() throws {
    let data = try #require(Data(base64Encoded: Self.storedBlob))
    let expected = try #require(
      BandWaveform(
        peak: [
          BandWaveform.Levels(low: 0.5, mid: 0.25, high: 1),
          BandWaveform.Levels(low: 0.75, mid: 0.125, high: 0.0625),
          BandWaveform.Levels(low: 0.1, mid: 0.2, high: 0.3),
        ],
        rms: [
          BandWaveform.Levels(low: 0.25, mid: 0.125, high: 0.5),
          BandWaveform.Levels(low: 0.5, mid: 0.0625, high: 0.03125), .silent,
        ],
        sampleRate: 44_100, channelCount: 2, frameCount: 700, framesRead: 650,
        source: BandWaveform.Source(
          formatID: 0x666C_6163, processingFormat: "float32 deinterleaved 2ch 44100.0Hz")))

    Self.expectBitIdentical(BandWaveform(serializedData: data), expected)
    // The payload is the same bytes the current encoder writes for these values.
    let fresh = try Self.split(expected.serializedData())
    #expect(try Self.split(data).payload == fresh.payload)
  }

  @Test("the empty result round-trips")
  func emptyResultRoundTrips() throws {
    let waveform = try Self.emptyResult()
    let data = waveform.serializedData()

    Self.expectBitIdentical(BandWaveform(serializedData: data), waveform)
  }

  @Test("an early-end-of-file result round-trips with framesRead unchanged")
  func earlyEOFResultRoundTrips() throws {
    let waveform = try Self.earlyEndResult()
    #expect(waveform.framesRead > 0 && waveform.framesRead < waveform.frameCount, "the premise")
    let data = waveform.serializedData()

    Self.expectBitIdentical(BandWaveform(serializedData: data), waveform)
  }

  @Test(
    "the largest valid header (a 256-byte processing format) and a non-integral rate round-trip")
  func largestValidHeaderRoundTrips() throws {
    let format = String(repeating: "x", count: 256)
    let waveform = try #require(
      BandWaveform(
        peak: [.silent, .silent], rms: [.silent, .silent], sampleRate: 22_050.123456789012,
        channelCount: 64, frameCount: 200, framesRead: 17,
        source: BandWaveform.Source(formatID: .max, processingFormat: format)))
    let data = waveform.serializedData()
    let headerCount = Int(data[12]) | Int(data[13]) << 8 | Int(data[14]) << 16
    #expect(headerCount < 2_048, "far under the 65,536-byte limit: \(headerCount)")

    Self.expectBitIdentical(BandWaveform(serializedData: data), waveform)
  }

  @Test("the header carries the diagnostic fields")
  func headerCarriesDiagnosticFields() throws {
    let waveform = try Self.smallResult()
    let header = try Self.split(waveform.serializedData()).header

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
    #expect(header["key"] == nil, "the format carries no key")
    #expect(header["analysisVersion"] as? String == "band-peak-rms.loudest-channel.v1")
    #expect(header["bucketCount"] as? Int == 2)
    #expect(header["payloadByteCount"] as? Int == 48)
  }

  @Test("the layout: magic, version 1, header count, then the payload's little-endian bits")
  func layoutIsAsDocumented() throws {
    let waveform = try Self.smallResult()
    let bytes = [UInt8](waveform.serializedData())

    #expect(Array(bytes[0..<8]) == Array("BBBKWAVE".utf8))
    #expect(Array(bytes[8..<12]) == [1, 0, 0, 0])
    let parts = try Self.split(Data(bytes))
    #expect(parts.payload.count == 2 * 24)
    // The first peak value, low 0.5: 0x3F000000 little-endian.
    #expect(Array(parts.payload[0..<4]) == [0x00, 0x00, 0x00, 0x3F])
    // The first RMS value starts after both peak buckets.
    #expect(Array(parts.payload[24..<28]) == [0x00, 0x00, 0x80, 0x3E])
  }

  // MARK: - Slices

  @Test("a slice that does not start at index 0: the valid one decodes, a truncated one is nil")
  func sliceInputIsParsedFromItsFirstByte() throws {
    let waveform = try Self.readerResult()
    let data = waveform.serializedData()
    let container = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x42]) + data + Data([0x99])
    let start = 5
    let valid = container[start..<(container.count - 1)]
    #expect(valid.startIndex == start, "the premise: a slice with a nonzero start")

    Self.expectBitIdentical(BandWaveform(serializedData: valid), waveform)
    #expect(BandWaveform(serializedData: container[start...]) == nil)
    #expect(
      BandWaveform(serializedData: container[start..<(container.count - 2)])
        == nil)
    #expect(
      BandWaveform(serializedData: container[start..<(start + 20)]) == nil)
  }

  // MARK: - Damaged bytes

  @Test("damaged bytes are nil and never trap")
  func damagedBytesAreNil() throws {
    let data = try Self.readerResult().serializedData()
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
      #expect(BandWaveform(serializedData: Data(damaged)) == nil, "\(name)")
    }
  }

  @Test("header byte counts out of range are nil, with the checksum rebuilt")
  func headerCountOutOfRangeIsNil() throws {
    let data = try Self.smallResult().serializedData()
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
      #expect(BandWaveform(serializedData: rebuilt) == nil, "H = \(count)")
    }
  }

  @Test("a header that is not JSON, with the checksum rebuilt, is nil")
  func headerNotJSONIsNil() throws {
    let parts = try Self.split(try Self.smallResult().serializedData())
    for header in ["not json", "{", "[]", "{\"key\": 1}", String(repeating: "[", count: 10_000)] {
      let data = try Self.assemble(parts, headerBytes: Data(header.utf8))
      #expect(
        BandWaveform(serializedData: data) == nil, "\(header.prefix(20))")
    }
  }

  // MARK: - Crafted headers with a valid checksum

  private static let int64Max = NSNumber(value: Int64.max)

  @Test("crafted headers with a valid checksum are nil and never trap")
  func craftedHeadersAreNil() throws {
    let waveform = try Self.smallResult()
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
          $0["bucketCount"] = BandWaveform.bucketCount(
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
          let buckets = BandWaveform.bucketCount(
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
      let data = try Self.crafted(from: waveform, edit)
      #expect(BandWaveform(serializedData: data) == nil, "\(name)")
    }
  }

  @Test("payload values out of range, with the checksum rebuilt, are nil")
  func payloadValuesOutOfRangeAreNil() throws {
    let waveform = try Self.smallResult()
    for value in [Float.nan, .infinity, -.infinity, -0.5, 1.000_001, .greatestFiniteMagnitude] {
      var parts = try Self.split(waveform.serializedData())
      let bits = value.bitPattern
      parts.payload.replaceSubrange(
        28..<32,
        with: [
          UInt8(truncatingIfNeeded: bits), UInt8(truncatingIfNeeded: bits >> 8),
          UInt8(truncatingIfNeeded: bits >> 16), UInt8(truncatingIfNeeded: bits >> 24),
        ])
      let data = try Self.assemble(parts)
      #expect(BandWaveform(serializedData: data) == nil, "\(value)")
    }
  }

  @Test("the payload byte count is overflow-checked")
  func payloadByteCountIsOverflowChecked() {
    #expect(BandWaveform.payloadByteCount(bucketCount: 2) == 48)
    #expect(BandWaveform.payloadByteCount(bucketCount: Int.max / 24 + 1) == nil)
    #expect(BandWaveform.payloadByteCount(bucketCount: Int.max) == nil)
    #expect(BandWaveform.payloadByteCount(bucketCount: -1) == nil)
    #expect(BandWaveform.bucketCount(frameCount: 2, sampleRate: 1e-300) == nil)
    #expect(BandWaveform.bucketCount(frameCount: -1, sampleRate: 44_100) == nil)
    #expect(BandWaveform.bucketCount(frameCount: .max, sampleRate: 1e-3) == nil)
  }

  // MARK: - Diagnostic fields

  @Test(
    "rewritten or removed diagnostic fields, with the checksum rebuilt, decode equal to the original"
  )
  func diagnosticFieldsNeverInvalidate() throws {
    let waveform = try Self.readerResult()
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
      let data = try Self.crafted(from: waveform, edit)
      let decoded = BandWaveform(serializedData: data)
      #expect(decoded != nil, "\(name)")
      Self.expectBitIdentical(decoded, waveform)
    }
  }

  // MARK: - Validating init

  @Test("the validating init rejects every broken invariant")
  func validatingInitRejectsBrokenInvariants() {
    let two: [BandWaveform.Levels] = [.silent, .silent]
    func make(
      peak: [BandWaveform.Levels] = two, rms: [BandWaveform.Levels] = two,
      sampleRate: Double = 44_100, channelCount: Int = 2, frameCount: Int64 = 300,
      framesRead: Int64 = 300, source: BandWaveform.Source = Self.source
    ) -> BandWaveform? {
      BandWaveform(
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
      let level = BandWaveform.Levels(low: 0, mid: bad, high: 0)
      #expect(make(peak: [level, .silent]) == nil, "peak \(bad)")
      #expect(make(rms: [.silent, level]) == nil, "rms \(bad)")
    }
    let longFormat = BandWaveform.Source(
      formatID: 1, processingFormat: String(repeating: "\u{e9}", count: 129))
    #expect(make(source: longFormat) == nil, "258 UTF-8 bytes")
    let edgeFormat = BandWaveform.Source(
      formatID: 1, processingFormat: String(repeating: "z", count: 256))
    #expect(make(source: edgeFormat) != nil, "256 bytes is allowed")
    let full = make(peak: [BandWaveform.Levels(low: 1, mid: 1, high: 1), .silent])
    #expect(full?.bucketsPerSecond == 150)
    #expect(full?.analysisVersion == BandWaveformReader.analysisVersion)
  }

  // MARK: - Supported range

  /// A validating-init call with the given rate and length, and silent arrays
  /// of exactly the bucket count they give, so only the supported range can
  /// reject it.
  private static func silentWaveform(sampleRate: Double, frameCount: Int64) throws -> BandWaveform?
  {
    let buckets = try #require(
      BandWaveform.bucketCount(frameCount: frameCount, sampleRate: sampleRate))
    let silent = [BandWaveform.Levels](repeating: .silent, count: buckets)
    return BandWaveform(
      peak: silent, rms: silent, sampleRate: sampleRate, channelCount: 1,
      frameCount: frameCount, framesRead: 0, source: source)
  }

  /// `Int64.max` frames at `Double(Int64.max) * 150` Hz: 2 buckets, but the
  /// boundary after bucket 1 rounds to 2^63 and does not fit in `Int64`.
  private static let int64MaxRate = Double(Int64.max) * 150

  /// 2^60 + 1 frames at 2^60 x 150 Hz: frame counts past 2^53, where `Double`
  /// no longer represents every whole number.
  private static let precisionRate = Double(UInt64(1) << 60) * 150
  private static let precisionFrames = Int64(1) << 60 + 1

  @Test("the validating init rejects a rate or length outside the supported range")
  func validatingInitRejectsOutsideTheSupportedRange() throws {
    #expect(
      try Self.silentWaveform(sampleRate: Self.int64MaxRate, frameCount: .max) == nil,
      "Int64.max frames at Int64.max x 150 Hz")
    #expect(
      try Self.silentWaveform(sampleRate: Self.precisionRate, frameCount: Self.precisionFrames)
        == nil,
      "2^60 + 1 frames at 2^60 x 150 Hz")
    #expect(
      try Self.silentWaveform(sampleRate: 1_536_000.0.nextUp, frameCount: 300) == nil,
      "just above 1,536,000 Hz")
    #expect(
      try Self.silentWaveform(sampleRate: 1_536_000, frameCount: 300) != nil,
      "1,536,000 Hz itself is accepted")
    #expect(BandWaveform.isSupported(sampleRate: 6_000.0.nextUp, frameCount: 1))
    #expect(!BandWaveform.isSupported(sampleRate: 6_000, frameCount: 1))
    #expect(!BandWaveform.isSupported(sampleRate: 44_100, frameCount: -1))
    #expect(!BandWaveform.isSupported(sampleRate: .nan, frameCount: 1))
    #expect(!BandWaveform.isSupported(sampleRate: .infinity, frameCount: 1))
  }

  @Test("the duration limit is exactly 43,200 s, checked without allocating the arrays")
  func durationLimitIsExact() {
    let limit = Int64(43_200 * 48_000)
    #expect(BandWaveform.isSupported(sampleRate: 48_000, frameCount: limit))
    #expect(!BandWaveform.isSupported(sampleRate: 48_000, frameCount: limit + 1))
    #expect(!BandWaveform.isSupported(sampleRate: 48_000, frameCount: .max))
  }

  @Test("serialized bytes outside the supported range, with the checksum rebuilt, are nil")
  func decoderRejectsOutsideTheSupportedRange() throws {
    let waveform = try Self.smallResult()
    #expect(waveform.peak.count == 2, "the premise: both crafted headers claim 2 buckets")
    let edits: [(String, (inout [String: Any]) -> Void)] = [
      (
        "Int64.max frames at Int64.max x 150 Hz",
        {
          $0["sampleRate"] = Self.int64MaxRate
          $0["frameCount"] = Self.int64Max
          $0["framesRead"] = 0
        }
      ),
      (
        "2^60 + 1 frames at 2^60 x 150 Hz",
        {
          $0["sampleRate"] = Self.precisionRate
          $0["frameCount"] = NSNumber(value: Self.precisionFrames)
          $0["framesRead"] = 0
        }
      ),
      (
        "just above 1,536,000 Hz, 20,000 frames (2 buckets)",
        {
          $0["sampleRate"] = 1_536_000.0.nextUp
          $0["frameCount"] = 20_000
          $0["framesRead"] = 0
        }
      ),
    ]
    for (name, edit) in edits {
      let data = try Self.crafted(from: waveform, edit)
      #expect(BandWaveform(serializedData: data) == nil, "\(name)")
    }
  }

  @Test("error descriptions are readable")
  func errorDescriptionsAreReadable() {
    let url = URL(fileURLWithPath: "/tmp/track.wav")
    let unsupported = BandWaveformError.unsupportedFormat(url, sampleRate: 6_000)
    #expect(unsupported.localizedDescription.contains("track.wav"))
    #expect(unsupported.localizedDescription.contains("6000.0 Hz"))
    let tooLong = BandWaveformError.durationTooLong(url, seconds: 50_000)
    #expect(tooLong.localizedDescription.contains("track.wav"))
    #expect(tooLong.localizedDescription.contains("50000.0 seconds"))
  }
}
