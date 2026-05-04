//
//  FileMetadataReaderTests.swift
//  BoomBoomBoomKitTests
//
//  Parser unit tests against hand-crafted byte arrays.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Hygiene parser

@Suite("FileMetadataReader — parseRawBPM hygiene")
struct ParseRawBPMTests {

  private let policy = MetadataPolicy.default

  @Test("integer string parses to Double")
  func parsesInteger() {
    let r = FileMetadataReader.parseRawBPM("128", policy: policy)
    #expect(r.parsed == 128.0)
    #expect(r.rejectionReason == nil)
  }

  @Test("decimal string parses")
  func parsesDecimal() {
    let r = FileMetadataReader.parseRawBPM("128.5", policy: policy)
    #expect(r.parsed == 128.5)
    #expect(r.rejectionReason == nil)
  }

  @Test("locale decimal comma is accepted")
  func parsesLocaleComma() {
    let r = FileMetadataReader.parseRawBPM("128,5", policy: policy)
    #expect(r.parsed == 128.5)
    #expect(r.rejectionReason == nil)
  }

  @Test("range midpoint is accepted")
  func parsesRangeMidpoint() {
    let r = FileMetadataReader.parseRawBPM("120-125", policy: policy)
    #expect(r.parsed == 122.5)
    #expect(r.rejectionReason == nil)
  }

  @Test("leading/trailing whitespace is stripped")
  func stripsWhitespace() {
    let r = FileMetadataReader.parseRawBPM("  128  ", policy: policy)
    #expect(r.parsed == 128.0)
    #expect(r.rejectionReason == nil)
  }

  @Test("BOM is stripped")
  func stripsBOM() {
    let r = FileMetadataReader.parseRawBPM("\u{FEFF}128", policy: policy)
    #expect(r.parsed == 128.0)
    #expect(r.rejectionReason == nil)
  }

  @Test("non-numeric rejected as non-numeric")
  func rejectsNonNumeric() {
    let r = FileMetadataReader.parseRawBPM("fast", policy: policy)
    #expect(r.parsed.isNaN)
    #expect(r.rejectionReason == "non-numeric")
  }

  @Test("empty string rejected as non-numeric")
  func rejectsEmpty() {
    let r = FileMetadataReader.parseRawBPM("", policy: policy)
    #expect(r.parsed.isNaN)
    #expect(r.rejectionReason == "non-numeric")
  }

  @Test("out-of-range rejected, parsed value retained")
  func rejectsOutOfRange() {
    let r = FileMetadataReader.parseRawBPM("500", policy: policy)
    #expect(r.parsed == 500.0)
    #expect(r.rejectionReason == "out-of-range")
  }

  @Test("zero is treated as sentinel under default policy")
  func treatsZeroAsSentinel() {
    let r = FileMetadataReader.parseRawBPM("0", policy: policy)
    #expect(r.parsed.isNaN)
    #expect(r.rejectionReason == "sentinel-zero")
  }
}

// MARK: - MP4 tmpo

@Suite("FileMetadataReader — MP4 tmpo atom")
struct MP4TmpoTests {

  /// Wraps `payload` in a 4CC atom: `[BE size][4cc][payload]`.
  static func atom(_ fourCC: String, payload: Data) -> Data {
    var d = Data()
    var size = UInt32(8 + payload.count).bigEndian
    withUnsafeBytes(of: &size) { d.append(contentsOf: $0) }
    d.append(contentsOf: Array(fourCC.utf8))
    d.append(payload)
    return d
  }

  static func extendedSizeAtom(_ fourCC: String, actualSize: UInt64, payload: Data) -> Data {
    var d = Data()
    var size = UInt32(1).bigEndian
    withUnsafeBytes(of: &size) { d.append(contentsOf: $0) }
    d.append(contentsOf: Array(fourCC.utf8))
    var extended = actualSize.bigEndian
    withUnsafeBytes(of: &extended) { d.append(contentsOf: $0) }
    d.append(payload)
    return d
  }

  /// Builds a minimal MP4 with `moov/udta/meta/ilst/tmpo/data` containing `bpm`.
  static func makeFile(tmpo: Int16) -> Data {
    var dataPayload = Data()
    // type/flags = 0x15 (BE_SIGNED_INT) but parser ignores it; locale = 0
    dataPayload.append(contentsOf: [0x00, 0x00, 0x00, 0x15])  // type/version+flags
    dataPayload.append(contentsOf: [0x00, 0x00, 0x00, 0x00])  // locale
    var bpmBE = UInt16(bitPattern: tmpo).bigEndian
    withUnsafeBytes(of: &bpmBE) { dataPayload.append(contentsOf: $0) }

    let dataAtom = atom("data", payload: dataPayload)
    let tmpoAtom = atom("tmpo", payload: dataAtom)
    let ilst = atom("ilst", payload: tmpoAtom)
    var metaPayload = Data([0x00, 0x00, 0x00, 0x00])  // 4-byte version/flags
    metaPayload.append(ilst)
    let meta = atom("meta", payload: metaPayload)
    let udta = atom("udta", payload: meta)
    let moov = atom("moov", payload: udta)

    var file = Data()
    let ftyp = atom("ftyp", payload: Data(repeating: 0, count: 8))
    file.append(ftyp)
    file.append(moov)
    return file
  }

  static func writeTemp(_ data: Data, ext: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("metadata-test-\(UUID().uuidString).\(ext)")
    try data.write(to: url)
    return url
  }

  @Test("tmpo=128 parses to 128 BPM")
  func tmpo128() throws {
    let file = MP4TmpoTests.makeFile(tmpo: 128)
    let url = try MP4TmpoTests.writeTemp(file, ext: "m4a")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.source == .iTunesTmpo)
    #expect(tags.first?.parsedBPM == 128.0)
    #expect(tags.first?.rejectionReason == nil)
  }

  @Test("tmpo=0 emits sentinel-zero rejection (NaN)")
  func tmpoZero() throws {
    let file = MP4TmpoTests.makeFile(tmpo: 0)
    let url = try MP4TmpoTests.writeTemp(file, ext: "m4a")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    let tag = try #require(tags.first)
    #expect(tag.source == .iTunesTmpo)
    #expect(tag.parsedBPM.isNaN)
    #expect(tag.rejectionReason == "sentinel-zero")
  }

  @Test("disabled policy returns no tags")
  func disabledNoTags() throws {
    let file = MP4TmpoTests.makeFile(tmpo: 128)
    let url = try MP4TmpoTests.writeTemp(file, ext: "m4a")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .disabled)
    #expect(tags.isEmpty)
  }

  @Test("malformed MP4 extended atom size larger than Int.max returns no tags")
  func oversizedExtendedAtomReturnsNoTags() throws {
    let moov = MP4TmpoTests.extendedSizeAtom(
      "moov", actualSize: UInt64(Int.max) + 1, payload: Data())
    let file = MP4TmpoTests.atom("ftyp", payload: Data(repeating: 0, count: 8)) + moov
    let url = try MP4TmpoTests.writeTemp(file, ext: "m4a")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }
}

// MARK: - ID3v2 TBPM (MP3)

@Suite("FileMetadataReader — ID3v2 TBPM")
struct ID3TBPMTests {

  /// Encode a 32-bit synchsafe integer (each byte: high bit clear, low 7 bits used).
  static func synchsafeBytes(_ n: UInt32) -> [UInt8] {
    [
      UInt8((n >> 21) & 0x7F),
      UInt8((n >> 14) & 0x7F),
      UInt8((n >> 7) & 0x7F),
      UInt8(n & 0x7F),
    ]
  }

  /// Builds a minimal MP3 with one ID3v2.3 TBPM frame containing `value`.
  /// `versionMajor` is 3 or 4. v2.3 frame size is regular BE32; v2.4 is synchsafe.
  ///
  /// - Parameters:
  ///   - tbpm: TBPM text payload (e.g., `"128"`, `"128,5"`, `"120-125"`).
  ///   - versionMajor: 3 or 4.
  ///   - extendedHeader: emit an ext-header (sets bit 6 of tag-header flags).
  ///   - crcFlag: v2.3 only — set bit 7 of the first ext-flag byte (claims a
  ///     CRC follows). Default false.
  ///   - footerFlag: set bit 4 of the tag-header flags byte (v2.4 footer-
  ///     present per spec; v2.3 reserved/malformed). For v2.4, also appends
  ///     the 10-byte footer after the tag body. Default false.
  ///   - frameFlags: 2-byte frame-format flags (default `[0x00, 0x00]`). Bit
  ///     7 of byte 2 = compression, bit 6 = encryption, bit 5 = grouping.
  ///   - extendedHeaderSizeOverride: replaces the size value written in the
  ///     ext-header (synchsafe for v2.4, BE32 for v2.3). Used to construct
  ///     under-/over-sized cases and v2.3 size↔CRC-flag mismatches.
  static func makeMP3(
    tbpm: String,
    versionMajor: UInt8 = 3,
    extendedHeader: Bool = false,
    crcFlag: Bool = false,
    footerFlag: Bool = false,
    frameFlags: [UInt8] = [0x00, 0x00],
    extendedHeaderSizeOverride: UInt32? = nil
  ) -> Data {
    // TBPM frame body: 1 encoding byte + UTF-8 bytes
    var framePayload = Data([0x03])  // UTF-8
    framePayload.append(Data(tbpm.utf8))

    var frame = Data()
    frame.append(contentsOf: Array("TBPM".utf8))
    let frameSize = UInt32(framePayload.count)
    if versionMajor == 4 {
      frame.append(contentsOf: synchsafeBytes(frameSize))
    } else {
      var sz = frameSize.bigEndian
      withUnsafeBytes(of: &sz) { frame.append(contentsOf: $0) }
    }
    frame.append(contentsOf: frameFlags)
    frame.append(framePayload)

    var header = Data()
    header.append(contentsOf: [0x49, 0x44, 0x33])  // "ID3"
    var body = Data()
    if extendedHeader {
      if versionMajor == 4 {
        let claimedSize = extendedHeaderSizeOverride ?? UInt32(6)
        body.append(contentsOf: synchsafeBytes(claimedSize))
        body.append(contentsOf: [0x01, 0x00])
      } else {
        // v2.3 canonical: 6 (no CRC) or 10 (with CRC). Override wins.
        let claimedSize = extendedHeaderSizeOverride ?? UInt32(crcFlag ? 10 : 6)
        var extSize = claimedSize.bigEndian
        withUnsafeBytes(of: &extSize) { body.append(contentsOf: $0) }
        let flagsByte0: UInt8 = crcFlag ? 0x80 : 0x00
        body.append(contentsOf: [flagsByte0, 0x00])  // ext flags (2 bytes)
        body.append(contentsOf: [0x00, 0x00, 0x00, 0x00])  // padding-size
        // When the claimed size is 10, append 4 more bytes filling the CRC
        // region — actual CRC value when crcFlag=true, or filler bytes
        // when testing mismatch B (size=10 + flag clear). For any other
        // claimed size (6, or under/over-sized override), no extras are
        // appended; the parser must reject upstream on under/over.
        if claimedSize == 10 {
          body.append(contentsOf: [0xDE, 0xAD, 0xBE, 0xEF])
        }
      }
    }
    body.append(frame)

    var tagFlags: UInt8 = 0x00
    if extendedHeader { tagFlags |= 0x40 }
    if footerFlag { tagFlags |= 0x10 }
    header.append(contentsOf: [versionMajor, 0x00, tagFlags])
    header.append(contentsOf: synchsafeBytes(UInt32(body.count)))

    var file = Data()
    file.append(header)
    file.append(body)
    if versionMajor == 4, footerFlag {
      file.append(contentsOf: [0x33, 0x44, 0x49])  // "3DI"
      file.append(contentsOf: [versionMajor, 0x00, tagFlags])
      file.append(contentsOf: synchsafeBytes(UInt32(body.count)))
    }
    return file
  }

  @Test("v2.3 TBPM=128 parses to 128.0")
  func v23Standard() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "128", versionMajor: 3)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
    #expect(tags.first?.source == .id3TBPM)
  }

  @Test("v2.4 TBPM=128,5 parses to 128.5 (locale comma)")
  func v24LocaleComma() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "128,5", versionMajor: 4)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.5)
  }

  @Test("v2.3 extended header skips size field and parses TBPM")
  func v23ExtendedHeader() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "128", versionMajor: 3, extendedHeader: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("v2.4 extended header parses TBPM")
  func v24ExtendedHeader() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "128", versionMajor: 4, extendedHeader: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("v2.3 TBPM=fast rejected as non-numeric")
  func nonNumeric() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "fast", versionMajor: 3)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.rejectionReason == "non-numeric")
  }

  @Test("v2.3 TBPM=500 rejected as out-of-range")
  func outOfRange() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "500", versionMajor: 3)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 500.0)
    #expect(tags.first?.rejectionReason == "out-of-range")
  }

  @Test("v2.3 TBPM=120-125 parses to range midpoint 122.5")
  func rangeMidpoint() throws {
    let data = ID3TBPMTests.makeMP3(tbpm: "120-125", versionMajor: 3)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 122.5)
  }

  @Test("ID3v2.2 (3-byte frame IDs) returns zero tags")
  func v22Unsupported() throws {
    var data = Data()
    data.append(contentsOf: [0x49, 0x44, 0x33, 0x02, 0x00, 0x00])  // ID3 v2.2
    data.append(contentsOf: ID3TBPMTests.synchsafeBytes(10))
    data.append(Data(repeating: 0, count: 10))
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("Unsynchronisation flag rejects the tag")
  func unsynchronisation() throws {
    var header = Data()
    header.append(contentsOf: [0x49, 0x44, 0x33, 0x03, 0x00, 0x80])  // unsync flag
    header.append(contentsOf: ID3TBPMTests.synchsafeBytes(10))
    var data = header
    data.append(Data(repeating: 0, count: 10))
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  // MARK: - Story 3-6b: extended-header size validation (AC #1, #2)

  @Test(
    "v2.3 ext-header size not in {6, 10} rejected",
    arguments: [UInt32(0), 4, 5, 7, 11, 100])
  func v23ExtendedHeaderSizeNotInPermittedSet(_ extSize: UInt32) throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, extendedHeader: true,
      extendedHeaderSizeOverride: extSize)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test(
    "v2.4 ext-header size too small rejected",
    arguments: [UInt32(0), 4, 5])
  func v24ExtendedHeaderSizeTooSmall(_ extSize: UInt32) throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, extendedHeader: true,
      extendedHeaderSizeOverride: extSize)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.4 ext-header size beyond body rejected")
  func v24ExtendedHeaderSizeBeyondBody() throws {
    // synchsafe(32) declared size, body actually ~22 bytes (4 size + 2
    // default content + ~16 frame). Parser must reject upstream rather
    // than walk into a non-existent region.
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, extendedHeader: true,
      extendedHeaderSizeOverride: 32)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.3 ext-header size beyond body rejected")
  func v23ExtendedHeaderSizeBeyondBody() throws {
    // Hand-built body of just 4 bytes (the BE32 size field claiming 10).
    // count=4, idx=0; upper-bound check: 4 + 10 <= 4 - 0 → false → reject.
    var body = Data()
    var extSize = UInt32(10).bigEndian
    withUnsafeBytes(of: &extSize) { body.append(contentsOf: $0) }
    var header = Data()
    header.append(contentsOf: [0x49, 0x44, 0x33, 0x03, 0x00, 0x40])  // ID3 v2.3, ext-header flag
    header.append(contentsOf: ID3TBPMTests.synchsafeBytes(UInt32(body.count)))
    var data = header
    data.append(body)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  // MARK: - Story 3-6b: v2.3 ext-header CRC-flag handling (AC #3)

  @Test("v2.3 ext-header CRC flag with extSize=10 walks correctly")
  func v23CRCFlagSkipsCorrectly() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, extendedHeader: true, crcFlag: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("v2.3 ext-header mismatch A: extSize=6 + CRC flag set, parser walks 10 bytes (lenient)")
  func v23CRCFlagSetButSizeSix() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, extendedHeader: true,
      crcFlag: true, extendedHeaderSizeOverride: 6)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("v2.3 ext-header mismatch B: extSize=10 + CRC flag clear, parser walks 14 bytes (lenient)")
  func v23CRCFlagClearButSizeTen() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, extendedHeader: true,
      crcFlag: false, extendedHeaderSizeOverride: 10)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  // MARK: - Story 3-6b: tag-header bit-4 handling (AC #4)

  @Test("v2.3 tag-header bit 4 (reserved) rejected")
  func v23FooterFlagRejected() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, footerFlag: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.4 tag-header bit 4 (footer-present) accepted, body walked normally")
  func v24FooterFlagAcceptedAndWalked() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, footerFlag: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  // MARK: - Story 3-6b: TBPM frame-flag silent-skip (AC #8)

  @Test("v2.3 TBPM compression flag (frame-flags byte 2 bit 7) skipped")
  func v23TBPMCompressionFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, frameFlags: [0x00, 0x80])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.3 TBPM encryption flag (frame-flags byte 2 bit 6) skipped")
  func v23TBPMEncryptionFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, frameFlags: [0x00, 0x40])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.3 TBPM grouping flag (frame-flags byte 2 bit 5) skipped")
  func v23TBPMGroupingFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 3, frameFlags: [0x00, 0x20])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.4 TBPM compression flag (frame-flags byte 2 bit 3) skipped")
  func v24TBPMCompressionFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, frameFlags: [0x00, 0x08])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.4 TBPM encryption flag (frame-flags byte 2 bit 2) skipped")
  func v24TBPMEncryptionFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, frameFlags: [0x00, 0x04])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("v2.4 TBPM grouping flag (frame-flags byte 2 bit 6) skipped")
  func v24TBPMGroupingFlagSkipped() throws {
    let data = ID3TBPMTests.makeMP3(
      tbpm: "128", versionMajor: 4, frameFlags: [0x00, 0x40])
    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("two TBPM frames with different values both returned")
  func twoFrames() throws {
    var f1 = Data([0x03])
    f1.append(Data("128".utf8))
    var f2 = Data([0x03])
    f2.append(Data("130".utf8))

    func makeFrame(_ payload: Data) -> Data {
      var frame = Data()
      frame.append(contentsOf: Array("TBPM".utf8))
      var sz = UInt32(payload.count).bigEndian
      withUnsafeBytes(of: &sz) { frame.append(contentsOf: $0) }
      frame.append(contentsOf: [0x00, 0x00])
      frame.append(payload)
      return frame
    }
    let frames = makeFrame(f1) + makeFrame(f2)

    var header = Data()
    header.append(contentsOf: [0x49, 0x44, 0x33, 0x03, 0x00, 0x00])
    header.append(contentsOf: ID3TBPMTests.synchsafeBytes(UInt32(frames.count)))
    var data = header
    data.append(frames)

    let url = try MP4TmpoTests.writeTemp(data, ext: "mp3")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 2)
    #expect(tags.map(\.parsedBPM).sorted() == [128.0, 130.0])
  }
}

// MARK: - AIFF embedded ID3

@Suite("FileMetadataReader — AIFF FORM + ID3 chunk")
struct AIFFID3Tests {

  /// Build an AIFF FORM container with one `ID3 ` chunk carrying a v2.3 TBPM frame.
  static func makeAIFF(
    tbpm: String,
    versionMajor: UInt8 = 3,
    footerFlag: Bool = false
  ) -> Data {
    let id3 = ID3TBPMTests.makeMP3(
      tbpm: tbpm, versionMajor: versionMajor, footerFlag: footerFlag)
    var chunk = Data()
    chunk.append(contentsOf: [0x49, 0x44, 0x33, 0x20])  // "ID3 "
    var sz = UInt32(id3.count).bigEndian
    withUnsafeBytes(of: &sz) { chunk.append(contentsOf: $0) }
    chunk.append(id3)
    if id3.count & 1 == 1 { chunk.append(0x00) }  // pad to even

    var form = Data()
    form.append(contentsOf: [0x46, 0x4F, 0x52, 0x4D])  // "FORM"
    var formSize = UInt32(4 + chunk.count).bigEndian
    withUnsafeBytes(of: &formSize) { form.append(contentsOf: $0) }
    form.append(contentsOf: [0x41, 0x49, 0x46, 0x46])  // "AIFF"
    form.append(chunk)
    return form
  }

  @Test("AIFF with ID3 chunk TBPM=128 parses")
  func aiffWithID3() throws {
    let data = AIFFID3Tests.makeAIFF(tbpm: "128")
    let url = try MP4TmpoTests.writeTemp(data, ext: "aiff")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.source == .id3TBPM)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  // MARK: - Story 3-6b: tag-header bit-4 via AIFF embedded-tag path (AC #4)

  @Test("AIFF v2.3 tag-header bit 4 (reserved) rejected")
  func v23AIFFFooterFlagRejected() throws {
    let data = AIFFID3Tests.makeAIFF(tbpm: "128", versionMajor: 3, footerFlag: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "aiff")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }

  @Test("AIFF v2.4 tag-header bit 4 (footer-present) accepted, body walked normally")
  func v24AIFFFooterFlagAcceptedAndWalked() throws {
    let data = AIFFID3Tests.makeAIFF(tbpm: "128", versionMajor: 4, footerFlag: true)
    let url = try MP4TmpoTests.writeTemp(data, ext: "aiff")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("AIFF without ID3 chunk returns zero tags")
  func aiffWithoutID3() throws {
    var form = Data()
    form.append(contentsOf: [0x46, 0x4F, 0x52, 0x4D])  // FORM
    var sz = UInt32(4).bigEndian
    withUnsafeBytes(of: &sz) { form.append(contentsOf: $0) }
    form.append(contentsOf: [0x41, 0x49, 0x46, 0x46])  // AIFF
    let url = try MP4TmpoTests.writeTemp(form, ext: "aiff")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }
}

// MARK: - FLAC Vorbis comment

@Suite("FileMetadataReader — FLAC Vorbis BPM")
struct FLACVorbisTests {

  /// Build a minimal FLAC file with a Vorbis comment block (block type 4)
  /// containing the given comments. No streaminfo block is included — the
  /// reader doesn't require it.
  static func makeFLAC(comments: [String]) -> Data {
    let vendor = Data("test-vendor".utf8)
    var payload = Data()
    var vlen = UInt32(vendor.count).littleEndian
    withUnsafeBytes(of: &vlen) { payload.append(contentsOf: $0) }
    payload.append(vendor)
    var ccount = UInt32(comments.count).littleEndian
    withUnsafeBytes(of: &ccount) { payload.append(contentsOf: $0) }
    for c in comments {
      let cb = Data(c.utf8)
      var clen = UInt32(cb.count).littleEndian
      withUnsafeBytes(of: &clen) { payload.append(contentsOf: $0) }
      payload.append(cb)
    }

    var file = Data()
    file.append(contentsOf: [0x66, 0x4C, 0x61, 0x43])  // "fLaC"
    // VORBIS_COMMENT block (type=4) marked is-last
    file.append(0x84)  // 0x80 (last) | 0x04 (type)
    let len = UInt32(payload.count)
    file.append(UInt8((len >> 16) & 0xFF))
    file.append(UInt8((len >> 8) & 0xFF))
    file.append(UInt8(len & 0xFF))
    file.append(payload)
    return file
  }

  @Test("FLAC BPM=175 parses")
  func single() throws {
    let data = FLACVorbisTests.makeFLAC(comments: ["BPM=175"])
    let url = try MP4TmpoTests.writeTemp(data, ext: "flac")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.source == .vorbisBPM)
    #expect(tags.first?.parsedBPM == 175.0)
  }

  @Test("FLAC bpm=128 (lowercase) matches case-insensitively")
  func caseInsensitive() throws {
    let data = FLACVorbisTests.makeFLAC(comments: ["bpm=128"])
    let url = try MP4TmpoTests.writeTemp(data, ext: "flac")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 1)
    #expect(tags.first?.parsedBPM == 128.0)
  }

  @Test("FLAC with two BPM= entries returns both")
  func twoEntries() throws {
    let data = FLACVorbisTests.makeFLAC(comments: ["BPM=128", "BPM=130"])
    let url = try MP4TmpoTests.writeTemp(data, ext: "flac")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.count == 2)
    #expect(tags.map(\.parsedBPM).sorted() == [128.0, 130.0])
  }

  @Test("FLAC with no BPM= entries returns zero")
  func noBPM() throws {
    let data = FLACVorbisTests.makeFLAC(comments: ["TITLE=Test", "ARTIST=Tester"])
    let url = try MP4TmpoTests.writeTemp(data, ext: "flac")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }
}

// MARK: - Unsupported extensions

@Suite("FileMetadataReader — unsupported extensions")
struct UnsupportedExtensionTests {

  @Test("WAV returns zero tags")
  func wav() throws {
    let url = try MP4TmpoTests.writeTemp(Data(repeating: 0, count: 100), ext: "wav")
    defer { try? FileManager.default.removeItem(at: url) }
    let tags = FileMetadataReader.readTags(from: url, policy: .default)
    #expect(tags.isEmpty)
  }
}
