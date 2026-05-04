//
//  FileMetadataReader.swift
//  BoomBoomBoomKit
//
//  Direct container parsing for embedded BPM tags (no AVFoundation).
//

import Foundation

/// Reads embedded BPM tags from audio container formats by walking the file
/// bytes directly. Caseless enum namespace, internal — the public surface is
/// ``MetadataPolicy`` plus the corroboration evidence on
/// ``AudioAnalysisResult``.
///
/// Format coverage:
/// - MP4/M4A: `moov/udta/meta/ilst/tmpo` int16 BPM atom (`MetadataSource.iTunesTmpo`)
/// - MP3: ID3v2.3/v2.4 `TBPM` text frame at file head (`MetadataSource.id3TBPM`)
/// - AIFF/AIFC: FORM-chunk-walk to embedded `ID3 ` chunk, then v2.3/v2.4 frame walk
/// - FLAC: Vorbis comment metadata block, all `BPM=` entries (`MetadataSource.vorbisBPM`)
///
/// Never throws. Returns `[]` for any failure (unsupported format, missing tag,
/// malformed bytes). `try?`-style swallowing is intentional — metadata absence
/// is not an error.
enum FileMetadataReader {

  // MARK: - Public Reader Entry

  /// Result of a per-source parse, ready to be promoted into
  /// ``MetadataBPMEvidence`` by the service.
  struct FoundTag: Sendable {
    let source: MetadataSource
    let rawString: String
    let parsedBPM: Double
    let rejectionReason: String?
  }

  /// Reads all enabled-source tags from the file at `url`.
  ///
  /// Dispatches by extension. Unsupported extensions (`.wav`, `.caf`, etc.)
  /// return `[]`. Disabled sources are skipped before any I/O.
  static func readTags(from url: URL, policy: MetadataPolicy) -> [FoundTag] {
    let ext = url.pathExtension.lowercased()
    switch ext {
    case "mp4", "m4a", "m4b", "m4p":
      guard policy.enabledSources.contains(.iTunesTmpo) else { return [] }
      guard let tag = readITunesTmpo(from: url, policy: policy) else { return [] }
      return [tag]
    case "mp3":
      guard policy.enabledSources.contains(.id3TBPM) else { return [] }
      return readID3TBPMFromMP3(from: url, policy: policy)
    case "aiff", "aif", "aifc":
      guard policy.enabledSources.contains(.id3TBPM) else { return [] }
      return readID3TBPMFromAIFF(from: url, policy: policy)
    case "flac":
      guard policy.enabledSources.contains(.vorbisBPM) else { return [] }
      return readVorbisBPM(from: url, policy: policy)
    default:
      return []
    }
  }

  // MARK: - MP4 / M4A: tmpo atom

  /// Walks the MP4 atom tree to `moov/udta/meta/ilst/tmpo/data` and decodes
  /// the 16-bit big-endian int16 BPM payload.
  private static func readITunesTmpo(from url: URL, policy: MetadataPolicy) -> FoundTag? {
    guard let fh = try? FileHandle(forReadingFrom: url) else { return nil }
    defer { try? fh.close() }
    guard let data = try? fh.readToEnd(), !data.isEmpty else { return nil }

    let rebased = Data(data)
    guard let moov = findAtom(named: "moov", in: rebased) else { return nil }
    guard let udta = findAtom(named: "udta", in: moov) else { return nil }
    guard let meta = findAtom(named: "meta", in: udta) else { return nil }
    // `meta` has 4-byte version/flags before children.
    guard meta.count >= 4 else { return nil }
    let metaChildren = Data(meta[meta.startIndex + 4..<meta.endIndex])
    guard
      let ilst = findAtom(named: "meta", in: metaChildren)
        ?? findAtom(named: "ilst", in: metaChildren)
    else {
      return nil
    }
    // Note: some files nest ilst directly under meta; some have ilst alongside.
    // Try walking ilst first, fall back to scanning meta children directly.
    let tmpoSearchRoots: [Data] = [ilst, metaChildren]
    var tmpoPayload: Data?
    for root in tmpoSearchRoots {
      if let tmpo = findAtom(named: "tmpo", in: root) {
        tmpoPayload = tmpo
        break
      }
    }
    guard let tmpo = tmpoPayload else { return nil }
    // tmpo body contains a `data` sub-atom: 8 header + 4 type/flags + 4 locale + 2 BE int16.
    guard let dataAtom = findAtom(named: "data", in: tmpo) else { return nil }
    guard dataAtom.count >= 10 else { return nil }
    // dataAtom payload (post-8-byte-header) = [4 type/flags][4 locale][int16 BPM]
    let bpmOffset = dataAtom.startIndex + 8
    guard bpmOffset + 2 <= dataAtom.endIndex else { return nil }
    let raw = dataAtom.withUnsafeBytes { ptr -> UInt16 in
      let bytes = ptr.baseAddress!.advanced(by: 8)
      return bytes.loadUnaligned(as: UInt16.self).bigEndian
    }
    let value = Double(Int16(bitPattern: raw))
    let rawString = String(format: "%g", value)

    if value == 0 && policy.parsing.treatZeroAsAbsent {
      return FoundTag(
        source: .iTunesTmpo, rawString: rawString,
        parsedBPM: .nan, rejectionReason: "sentinel-zero")
    }
    if !policy.valueRange.contains(value) {
      return FoundTag(
        source: .iTunesTmpo, rawString: rawString,
        parsedBPM: value, rejectionReason: "out-of-range")
    }
    return FoundTag(
      source: .iTunesTmpo, rawString: rawString,
      parsedBPM: value, rejectionReason: nil)
  }

  /// Finds the first child atom named `fourCC` directly inside `data`. Atoms
  /// are `[4-byte BE size][4-byte fourCC][payload]`. Returns the payload-only
  /// slice (excluding the 8-byte header). Bounds-checked against malformed
  /// sizes.
  private static func findAtom(named fourCC: String, in data: Data) -> Data? {
    let target = Array(fourCC.utf8)
    guard target.count == 4 else { return nil }
    var idx = data.startIndex
    while idx + 8 <= data.endIndex {
      let size = data.withUnsafeBytes { ptr -> UInt32 in
        let offset = idx - data.startIndex
        return ptr.loadUnaligned(fromByteOffset: offset, as: UInt32.self).bigEndian
      }
      let typeStart = idx + 4
      let typeBytes = Array(data[typeStart..<typeStart + 4])

      // size==1 means 64-bit extended size in the next 8 bytes.
      let actualSize: UInt64
      let headerSize: Int
      if size == 1 {
        guard typeStart + 4 + 8 <= data.endIndex else { return nil }
        actualSize = data.withUnsafeBytes { ptr -> UInt64 in
          let offset = typeStart + 4 - data.startIndex
          return ptr.loadUnaligned(fromByteOffset: offset, as: UInt64.self).bigEndian
        }
        headerSize = 16
      } else if size == 0 {
        // size==0 means "extends to end of file/parent".
        actualSize = UInt64(data.endIndex - idx)
        headerSize = 8
      } else {
        actualSize = UInt64(size)
        headerSize = 8
      }

      let remaining = data.endIndex - idx
      guard actualSize >= UInt64(headerSize), actualSize <= UInt64(remaining) else { return nil }
      let nextIdx = idx + Int(actualSize)
      guard nextIdx <= data.endIndex, nextIdx > idx else { return nil }

      if typeBytes == target {
        return Data(data[idx + headerSize..<nextIdx])
      }
      idx = nextIdx
    }
    return nil
  }

  // MARK: - MP3 / AIFF: ID3v2 TBPM

  private static func readID3TBPMFromMP3(from url: URL, policy: MetadataPolicy) -> [FoundTag] {
    guard let fh = try? FileHandle(forReadingFrom: url) else { return [] }
    defer { try? fh.close() }
    guard let header = try? fh.read(upToCount: 10), header.count == 10 else { return [] }
    guard header[0] == 0x49, header[1] == 0x44, header[2] == 0x33 else { return [] }  // "ID3"
    let versionMajor = header[3]
    let flags = header[5]
    guard versionMajor == 3 || versionMajor == 4 else { return [] }
    if flags & 0x80 != 0 { return [] }  // unsynchronisation — out of scope
    // v2.3: bit 4 reserved per spec §3.1, MUST be cleared. v2.4: bit 4 is
    // footer-present per §3.1; the footer per §3.4 sits OUTSIDE the
    // synchsafe tag-body slice we already read, so we accept and walk.
    if versionMajor == 3, flags & 0x10 != 0 { return [] }
    let tagBodySize = Int(synchsafe(header[6], header[7], header[8], header[9]))
    guard tagBodySize > 0 else { return [] }
    guard let body = try? fh.read(upToCount: tagBodySize), body.count == tagBodySize else {
      return []
    }
    return parseID3v2Body(body, versionMajor: versionMajor, flags: flags, policy: policy)
  }

  private static func readID3TBPMFromAIFF(from url: URL, policy: MetadataPolicy) -> [FoundTag] {
    guard let fh = try? FileHandle(forReadingFrom: url) else { return [] }
    defer { try? fh.close() }
    guard let data = try? fh.readToEnd(), data.count >= 12 else { return [] }
    let formMagic = Array(data[0..<4])
    guard formMagic == [0x46, 0x4F, 0x52, 0x4D] else { return [] }  // "FORM"
    let formType = Array(data[8..<12])
    guard formType == [0x41, 0x49, 0x46, 0x46] || formType == [0x41, 0x49, 0x46, 0x43] else {
      return []  // AIFF or AIFC
    }
    var idx = 12
    while idx + 8 <= data.count {
      let id = Array(data[idx..<idx + 4])
      let size = data.withUnsafeBytes { ptr -> UInt32 in
        ptr.loadUnaligned(fromByteOffset: idx + 4, as: UInt32.self).bigEndian
      }
      let payloadStart = idx + 8
      let payloadEnd = payloadStart + Int(size)
      guard payloadEnd <= data.count else { return [] }
      // "ID3 " (note trailing space) — registered AIFF ID3 chunk.
      if id == [0x49, 0x44, 0x33, 0x20] {
        let chunk = Data(data[payloadStart..<payloadEnd])
        return parseEmbeddedID3Tag(chunk, policy: policy)
      }
      // Pad to even length.
      idx = payloadEnd + (Int(size) & 1)
    }
    return []
  }

  /// Parses a full ID3v2 tag (header + body) embedded in a chunk payload.
  private static func parseEmbeddedID3Tag(_ data: Data, policy: MetadataPolicy) -> [FoundTag] {
    guard data.count >= 10 else { return [] }
    let header = Data(data[0..<10])
    guard header[0] == 0x49, header[1] == 0x44, header[2] == 0x33 else { return [] }
    let versionMajor = header[3]
    let flags = header[5]
    guard versionMajor == 3 || versionMajor == 4 else { return [] }
    if flags & 0x80 != 0 { return [] }
    // v2.3 bit 4 reserved (§3.1); v2.4 bit 4 = footer-present (§3.1, §3.4).
    // See ``readID3TBPMFromMP3`` for the rationale — the embedded-tag path
    // mirrors the same policy.
    if versionMajor == 3, flags & 0x10 != 0 { return [] }
    let tagBodySize = Int(synchsafe(header[6], header[7], header[8], header[9]))
    guard tagBodySize > 0, 10 + tagBodySize <= data.count else { return [] }
    let body = Data(data[10..<10 + tagBodySize])
    return parseID3v2Body(body, versionMajor: versionMajor, flags: flags, policy: policy)
  }

  /// Walks ID3v2 frames in `body`, decoding any `TBPM` text frames found.
  /// Caller is responsible for skipping the 10-byte tag header before
  /// invoking this. `flags` is the tag-header flags byte (bit 6 = extended
  /// header, bit 4 = v2.4 footer-present / v2.3 reserved — caller has
  /// already enforced version-specific bit-4 policy).
  private static func parseID3v2Body(
    _ body: Data, versionMajor: UInt8, flags: UInt8, policy: MetadataPolicy
  ) -> [FoundTag] {
    var idx = 0
    let count = body.count

    // Extended header: bit 6 of tag-header flags. v2.4 size is synchsafe
    // (28-bit, includes the 4-byte size field itself); v2.3 size is regular
    // BE32 (excludes the size field, must be 6 [no CRC] or 10 [with CRC]).
    // v2.3 ext-header: trust extSize as the load-bearing field; CRC flag
    // (bit 7 of the first ext-flag byte) is not consulted. Mismatch in
    // either direction (size 6 with flag set, size 10 with flag clear) is
    // accepted because the walker walks by size, not by flag claim.
    if flags & 0x40 != 0 {
      guard idx + 4 <= count else { return [] }
      let extSize: Int
      if versionMajor == 4 {
        extSize = Int(
          synchsafe(
            body[body.startIndex + idx],
            body[body.startIndex + idx + 1],
            body[body.startIndex + idx + 2],
            body[body.startIndex + idx + 3]))
        // v2.4: synchsafe size includes the 4-byte size field (min 6).
        // Reject under-sized AND over-sized headers explicitly upstream so
        // the failure mode is "explicit reject," not "silent empty result"
        // from landing mid-frame later.
        guard extSize >= 6, extSize <= count - idx else { return [] }
      } else {
        extSize = Int(
          body.withUnsafeBytes { ptr -> UInt32 in
            ptr.loadUnaligned(fromByteOffset: idx, as: UInt32.self).bigEndian
          })
        // v2.3: BE32 size excludes the 4-byte size field. Spec permits
        // exactly 6 (no CRC) or 10 (with CRC). Reject any other value AND
        // reject sizes that exceed the remaining body.
        guard extSize == 6 || extSize == 10 else { return [] }
        guard 4 + extSize <= count - idx else { return [] }
      }
      idx += versionMajor == 3 ? 4 + extSize : extSize
      guard idx <= count else { return [] }
    }

    var found: [FoundTag] = []
    while idx + 10 <= count {
      let frameIDBytes = Array(body[body.startIndex + idx..<body.startIndex + idx + 4])
      // Padding: all-zero frame ID terminates the walk.
      if frameIDBytes.allSatisfy({ $0 == 0 }) { break }
      guard frameIDBytes.allSatisfy({ ($0 >= 0x41 && $0 <= 0x5A) || ($0 >= 0x30 && $0 <= 0x39) })
      else {
        break  // non-ASCII-uppercase-digit frame ID — likely garbage past tag end
      }
      let frameSize: Int
      if versionMajor == 4 {
        frameSize = Int(
          synchsafe(
            body[body.startIndex + idx + 4],
            body[body.startIndex + idx + 5],
            body[body.startIndex + idx + 6],
            body[body.startIndex + idx + 7]))
      } else {
        frameSize = Int(
          body.withUnsafeBytes { ptr -> UInt32 in
            ptr.loadUnaligned(fromByteOffset: idx + 4, as: UInt32.self).bigEndian
          })
      }
      let payloadStart = idx + 10
      let payloadEnd = payloadStart + frameSize
      guard frameSize > 0, payloadEnd <= count else { break }

      // Frame-format flags byte 2 (the second of the two flag bytes after
      // the 4-byte frame size). v2.3 uses bits 7/6/5 for compression,
      // encryption, and grouping identity; v2.4 uses bits 6/3/2 for the
      // same unsupported payload-affecting flags. When set, these prepend
      // additional fields before the payload — decoding the raw payload as
      // text would emit silent garbage evidence. Silent-skip the frame and
      // continue the walk (aligns with the existing all-zero / non-ASCII
      // guards above).
      let frameFlags1 = body[body.startIndex + idx + 9]
      let unsupportedFormatFlags: UInt8 = versionMajor == 4 ? 0x4C : 0xE0
      if frameFlags1 & unsupportedFormatFlags != 0 {
        idx = payloadEnd
        continue
      }

      if frameIDBytes == [0x54, 0x42, 0x50, 0x4D] {  // "TBPM"
        let payload = Data(body[body.startIndex + payloadStart..<body.startIndex + payloadEnd])
        if let raw = decodeTextFrame(payload) {
          let parsed = parseRawBPM(raw, policy: policy)
          found.append(
            FoundTag(
              source: .id3TBPM, rawString: raw,
              parsedBPM: parsed.parsed, rejectionReason: parsed.rejectionReason))
        } else {
          found.append(
            FoundTag(
              source: .id3TBPM, rawString: "",
              parsedBPM: .nan, rejectionReason: "non-numeric"))
        }
      }

      idx = payloadEnd
    }
    return found
  }

  /// Decodes an ID3v2 text-frame payload. First byte is the encoding marker;
  /// remaining bytes are the text. Returns nil on decode failure.
  private static func decodeTextFrame(_ payload: Data) -> String? {
    guard !payload.isEmpty else { return nil }
    let encoding = payload[payload.startIndex]
    let textBytes = Data(payload[payload.startIndex + 1..<payload.endIndex])
    let raw: String?
    switch encoding {
    case 0x00:
      raw = String(data: textBytes, encoding: .isoLatin1)
    case 0x01:
      // UTF-16 with BOM.
      raw = String(data: textBytes, encoding: .utf16)
    case 0x02:
      raw = String(data: textBytes, encoding: .utf16BigEndian)
    case 0x03:
      raw = String(data: textBytes, encoding: .utf8)
    default:
      raw = String(data: textBytes, encoding: .isoLatin1)
    }
    guard var s = raw else { return nil }
    // Strip trailing nulls.
    while let last = s.unicodeScalars.last, last == "\0" {
      s = String(s.unicodeScalars.dropLast())
    }
    return s
  }

  /// Decodes an ID3v2 synchsafe 32-bit integer (each byte contributes 7 bits;
  /// high bit always zero).
  private static func synchsafe(_ b0: UInt8, _ b1: UInt8, _ b2: UInt8, _ b3: UInt8) -> UInt32 {
    (UInt32(b0 & 0x7F) << 21) | (UInt32(b1 & 0x7F) << 14) | (UInt32(b2 & 0x7F) << 7)
      | UInt32(b3 & 0x7F)
  }

  // MARK: - FLAC: Vorbis comment block

  private static func readVorbisBPM(from url: URL, policy: MetadataPolicy) -> [FoundTag] {
    guard let fh = try? FileHandle(forReadingFrom: url) else { return [] }
    defer { try? fh.close() }
    guard let data = try? fh.readToEnd(), data.count >= 4 else { return [] }
    guard data[0] == 0x66, data[1] == 0x4C, data[2] == 0x61, data[3] == 0x43 else {
      return []  // "fLaC"
    }
    var idx = 4
    while idx + 4 <= data.count {
      let blockHeader = data[idx]
      let isLast = (blockHeader & 0x80) != 0
      let blockType = blockHeader & 0x7F
      let length =
        (Int(data[idx + 1]) << 16)
        | (Int(data[idx + 2]) << 8)
        | Int(data[idx + 3])
      let payloadStart = idx + 4
      let payloadEnd = payloadStart + length
      guard payloadEnd <= data.count else { return [] }

      if blockType == 4 {  // VORBIS_COMMENT
        let payload = Data(data[payloadStart..<payloadEnd])
        return parseVorbisCommentPayload(payload, policy: policy)
      }
      if isLast { break }
      idx = payloadEnd
    }
    return []
  }

  /// Parses a Vorbis comment block payload (little-endian lengths).
  private static func parseVorbisCommentPayload(_ data: Data, policy: MetadataPolicy) -> [FoundTag]
  {
    var idx = data.startIndex
    guard idx + 4 <= data.endIndex else { return [] }
    let vendorLen = Int(
      data.withUnsafeBytes { ptr -> UInt32 in
        ptr.loadUnaligned(fromByteOffset: 0, as: UInt32.self).littleEndian
      })
    idx += 4
    guard idx + vendorLen <= data.endIndex else { return [] }
    idx += vendorLen
    guard idx + 4 <= data.endIndex else { return [] }
    let commentCount = Int(
      data.withUnsafeBytes { ptr -> UInt32 in
        ptr.loadUnaligned(fromByteOffset: idx - data.startIndex, as: UInt32.self).littleEndian
      })
    idx += 4

    var found: [FoundTag] = []
    for _ in 0..<commentCount {
      guard idx + 4 <= data.endIndex else { break }
      let entryLen = Int(
        data.withUnsafeBytes { ptr -> UInt32 in
          ptr.loadUnaligned(fromByteOffset: idx - data.startIndex, as: UInt32.self).littleEndian
        })
      idx += 4
      guard idx + entryLen <= data.endIndex else { break }
      let entryBytes = Data(data[idx..<idx + entryLen])
      idx += entryLen
      guard let entry = String(data: entryBytes, encoding: .utf8) else { continue }
      guard let eq = entry.firstIndex(of: "=") else { continue }
      let key = entry[entry.startIndex..<eq].lowercased()
      let value = String(entry[entry.index(after: eq)..<entry.endIndex])
      if key == "bpm" {
        let parsed = parseRawBPM(value, policy: policy)
        found.append(
          FoundTag(
            source: .vorbisBPM, rawString: value,
            parsedBPM: parsed.parsed, rejectionReason: parsed.rejectionReason))
      }
    }
    return found
  }

  // MARK: - Hygiene

  /// Applies parsing hygiene per ``MetadataPolicy/parsing``.
  ///
  /// Returns `(parsed, rejectionReason)`. On rejection, `parsed` is
  /// `Double.nan` for parse-class failures (`sentinel-zero`, `non-numeric`)
  /// and the actual numeric value for `out-of-range` (so the trace can show
  /// what was read).
  static func parseRawBPM(_ raw: String, policy: MetadataPolicy) -> (
    parsed: Double, rejectionReason: String?
  ) {
    var s = raw
    if policy.parsing.stripWhitespaceAndBOM {
      // Strip BOM (U+FEFF) anywhere it lands, then whitespace.
      s = s.replacingOccurrences(of: "\u{FEFF}", with: "")
      s = s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if s.isEmpty {
      if policy.parsing.rejectNonNumeric {
        return (.nan, "non-numeric")
      }
      return (.nan, "non-numeric")
    }
    // Range midpoint: "120-125" → 122.5.
    if policy.parsing.acceptRangeMidpoint, let dash = s.firstIndex(of: "-"),
      dash != s.startIndex
    {
      let left = String(s[s.startIndex..<dash])
      let right = String(s[s.index(after: dash)..<s.endIndex])
      if let l = parseDouble(left, policy: policy), let r = parseDouble(right, policy: policy) {
        let mid = (l + r) / 2.0
        return classify(mid, policy: policy)
      }
    }
    guard let v = parseDouble(s, policy: policy) else {
      return (.nan, "non-numeric")
    }
    return classify(v, policy: policy)
  }

  private static func parseDouble(_ s: String, policy: MetadataPolicy) -> Double? {
    var working = s
    if policy.parsing.acceptLocaleDecimalComma {
      working = working.replacingOccurrences(of: ",", with: ".")
    }
    return Double(working)
  }

  private static func classify(_ v: Double, policy: MetadataPolicy)
    -> (parsed: Double, rejectionReason: String?)
  {
    if !v.isFinite { return (.nan, "non-numeric") }
    if v == 0 && policy.parsing.treatZeroAsAbsent {
      return (.nan, "sentinel-zero")
    }
    if !policy.valueRange.contains(v) {
      return (v, "out-of-range")
    }
    return (v, nil)
  }
}
