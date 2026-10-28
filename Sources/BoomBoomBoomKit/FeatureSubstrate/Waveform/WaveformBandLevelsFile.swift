//
//  WaveformBandLevelsFile.swift
//  BoomBoomBoomKit
//
//  Story 15.11 (DD-9, DD-10): a versioned binary format for
//  `WaveformBandLevels`. The library turns levels into bytes and back and
//  decides whether stored bytes are still usable; the caller owns where the
//  bytes live. Nothing here touches the file system.
//
//  Layout, little-endian, offsets from the first byte of the data:
//
//    0       8  magic, ASCII "BBBKWAVE"
//    8       4  UInt32 layout version, 1
//    12      4  UInt32 header byte count H, 1...65_536
//    16     32  SHA-256 over bytes 0..<16 followed by bytes 48..<end
//    48      H  header, UTF-8 JSON
//    48 + H  P  payload: peak then rms, each bucket low, mid, high, each value
//               its Float.bitPattern as 4 bytes; P = bucketCount * 24
//

import CryptoKit
import Foundation

extension WaveformBandLevels {

  // MARK: - Public API

  /// Encodes the levels into the waveform levels file format.
  ///
  /// The caller stores the bytes wherever it likes; the library writes nothing
  /// to disk. A file name of `<key>.waveform` is a reasonable choice.
  ///
  /// The format starts with a fixed magic and a layout version, then a JSON
  /// header (the key, ``analysisVersion``, the counts, the sample rate,
  /// ``source``, and diagnostic fields: the filter bank, the OS version and the
  /// creation time), then every peak and RMS value as a little-endian
  /// `Float32`. A SHA-256 checksum covers all of it, so any damaged byte makes
  /// ``decoded(from:forKey:)`` return `nil`. Values come back bit for bit.
  ///
  /// - Parameter key: The caller's lowercase hexadecimal SHA-256 of the audio
  ///   file's bytes (64 characters). The library never hashes the audio file;
  ///   the key ties the stored levels to the file they were measured from.
  /// - Returns: The encoded bytes.
  /// - Throws: ``WaveformBandLevelError/invalidKey(_:)`` when `key` is not
  ///   exactly 64 lowercase hexadecimal characters;
  ///   ``WaveformBandLevelError/headerTooLarge(byteCount:)`` when the header
  ///   exceeds 65,536 bytes, which no result this type accepts can reach.
  public func encoded(forKey key: String) throws -> Data {
    guard Self.isValidKey(key) else { throw WaveformBandLevelError.invalidKey(key) }
    let header = EncodedHeader(
      key: key,
      analysisVersion: analysisVersion,
      bucketsPerSecond: bucketsPerSecond,
      sampleRate: sampleRate,
      channelCount: channelCount,
      frameCount: frameCount,
      framesRead: framesRead,
      bucketCount: peak.count,
      source: HeaderSource(
        formatID: source.formatID, processingFormat: source.processingFormat),
      elementType: Self.elementType,
      payloadByteCount: peak.count * Self.bytesPerBucket,
      filterBank: FilterBank(
        lowPassHz: WaveformBandFilter.lowPassCutoff,
        midHighPassHz: WaveformBandFilter.midHighPassCutoff,
        midLowPassHz: WaveformBandFilter.midLowPassCutoff,
        highHighPassHz: WaveformBandFilter.highHighPassCutoff,
        highLowPassHz: WaveformBandFilter.highLowPassCutoff,
        highLowPassUsed: WaveformBandFilter.keepsHighLowPass(sampleRate: sampleRate),
        quality: WaveformBandFilter.quality),
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
      createdAt: Date().ISO8601Format())
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let headerBytes = try encoder.encode(header)
    guard headerBytes.count <= Self.maximumHeaderBytes else {
      throw WaveformBandLevelError.headerTooLarge(byteCount: headerBytes.count)
    }

    let payloadCount = peak.count * Self.bytesPerBucket
    var bytes = [UInt8]()
    bytes.reserveCapacity(Self.prefixBytes + headerBytes.count + payloadCount)
    bytes += Self.magic
    Self.appendUInt32(Self.layoutVersion, to: &bytes)
    Self.appendUInt32(UInt32(headerBytes.count), to: &bytes)
    bytes += [UInt8](repeating: 0, count: Self.checksumBytes)
    bytes += headerBytes
    for levels in [peak, rms] {
      for level in levels {
        Self.appendUInt32(level.low.bitPattern, to: &bytes)
        Self.appendUInt32(level.mid.bitPattern, to: &bytes)
        Self.appendUInt32(level.high.bitPattern, to: &bytes)
      }
    }
    let digest = bytes.withUnsafeBytes { Self.checksum(of: $0) }
    bytes.replaceSubrange(Self.checksumOffset..<Self.prefixBytes, with: digest)
    return Data(bytes)
  }

  /// Decodes levels from bytes written by ``encoded(forKey:)``, or returns
  /// `nil` when the bytes cannot be used.
  ///
  /// Never throws. `nil` always means the stored bytes should be deleted: they
  /// are damaged, truncated, from another layout version, encoded for another
  /// key, or measured under an earlier ``WaveformBandLevelReader/analysisVersion``
  /// (a new version makes every older file unusable). After deleting, measure
  /// the file again and store the new result. An invalid `key` also returns
  /// `nil`.
  ///
  /// The diagnostic header fields (the filter bank, the OS version and the
  /// creation time) are never read, so they cannot make a file unusable.
  ///
  /// - Parameters:
  ///   - data: The stored bytes. A slice of a larger `Data` is fine.
  ///   - key: The lowercase hexadecimal SHA-256 of the audio file's bytes the
  ///     levels are wanted for.
  /// - Returns: The levels, equal bit for bit to those encoded, or `nil`.
  public static func decoded(from data: Data, forKey key: String) -> WaveformBandLevels? {
    data.withUnsafeBytes { raw in decoded(from: raw, forKey: key) }
  }

  // MARK: - Layout constants

  static let magic: [UInt8] = Array("BBBKWAVE".utf8)
  static let layoutVersion: UInt32 = 1
  static let elementType = "float32le"
  static let checksumOffset = 16
  static let checksumBytes = 32
  static let prefixBytes = 48
  static let maximumHeaderBytes = 65_536
  /// Three bands of 4 bytes, in both the peak and the RMS array.
  static let bytesPerBucket = 24

  // MARK: - Key

  /// Whether `key` is exactly 64 lowercase hexadecimal characters.
  static func isValidKey(_ key: String) -> Bool {
    key.utf8.count == 64
      && key.utf8.allSatisfy { (0x30...0x39).contains($0) || (0x61...0x66).contains($0) }
  }

  // MARK: - Decoding

  /// The decoder over the bytes in place. Every count read from the data is
  /// checked against the bytes actually present before anything is allocated
  /// from it.
  private static func decoded(
    from raw: UnsafeRawBufferPointer, forKey key: String
  ) -> WaveformBandLevels? {
    guard raw.count >= prefixBytes,
      raw[0..<magic.count].elementsEqual(magic),
      readUInt32(raw, at: 8) == layoutVersion
    else { return nil }
    let headerCount = Int(readUInt32(raw, at: 12))
    guard (1...maximumHeaderBytes).contains(headerCount),
      prefixBytes + headerCount <= raw.count,
      checksum(of: raw).elementsEqual(raw[checksumOffset..<prefixBytes])
    else { return nil }

    // Bounded by `headerCount`, which is at most 65,536 bytes.
    let headerData = Data(
      UnsafeRawBufferPointer(rebasing: raw[prefixBytes..<(prefixBytes + headerCount)]))
    guard let header = try? JSONDecoder().decode(DecodedHeader.self, from: headerData),
      header.elementType == elementType,
      isValidKey(key), header.key == key,
      header.analysisVersion == WaveformBandLevelReader.analysisVersion,
      header.bucketsPerSecond == WaveformBandLevelReader.bucketsPerSecond,
      header.sampleRate.isFinite, header.sampleRate > minimumSampleRateExclusive,
      let bucketCount = bucketCount(
        frameCount: header.frameCount, sampleRate: header.sampleRate),
      header.bucketCount == bucketCount,
      header.channelCount >= 1,
      header.frameCount >= 0,
      header.framesRead >= 0, header.framesRead <= header.frameCount,
      let payloadCount = payloadByteCount(bucketCount: bucketCount),
      header.payloadByteCount == payloadCount,
      payloadCount == raw.count - prefixBytes - headerCount
    else { return nil }

    // Only now, with the payload length matching the bytes present, are the
    // output arrays allocated.
    let payloadStart = prefixBytes + headerCount
    let rmsStart = payloadStart + bucketCount * 12
    let peak = readLevels(raw, at: payloadStart, count: bucketCount)
    let rms = readLevels(raw, at: rmsStart, count: bucketCount)
    return WaveformBandLevels(
      peak: peak, rms: rms, sampleRate: header.sampleRate, channelCount: header.channelCount,
      frameCount: header.frameCount, framesRead: header.framesRead,
      source: WaveformAudioSource(
        formatID: header.source.formatID, processingFormat: header.source.processingFormat))
  }

  /// `bucketCount * 24`, or `nil` on overflow.
  static func payloadByteCount(bucketCount: Int) -> Int? {
    guard bucketCount >= 0 else { return nil }
    let (count, overflow) = bucketCount.multipliedReportingOverflow(by: bytesPerBucket)
    return overflow ? nil : count
  }

  /// `count` levels of three little-endian `Float32` values from `offset`.
  private static func readLevels(
    _ raw: UnsafeRawBufferPointer, at offset: Int, count: Int
  ) -> [WaveformBandLevel] {
    var levels = [WaveformBandLevel]()
    levels.reserveCapacity(count)
    var position = offset
    for _ in 0..<count {
      let low = Float(bitPattern: readUInt32(raw, at: position))
      let mid = Float(bitPattern: readUInt32(raw, at: position + 4))
      let high = Float(bitPattern: readUInt32(raw, at: position + 8))
      levels.append(WaveformBandLevel(low: low, mid: mid, high: high))
      position += 12
    }
    return levels
  }

  // MARK: - Bytes

  /// SHA-256 over bytes `0..<16` followed by bytes `48..<end`.
  private static func checksum(of raw: UnsafeRawBufferPointer) -> [UInt8] {
    var hasher = SHA256()
    hasher.update(bufferPointer: UnsafeRawBufferPointer(rebasing: raw[0..<checksumOffset]))
    hasher.update(bufferPointer: UnsafeRawBufferPointer(rebasing: raw[prefixBytes...]))
    return Array(hasher.finalize())
  }

  /// A little-endian `UInt32` at `offset`, read byte by byte.
  private static func readUInt32(_ raw: UnsafeRawBufferPointer, at offset: Int) -> UInt32 {
    UInt32(raw[offset]) | UInt32(raw[offset + 1]) << 8 | UInt32(raw[offset + 2]) << 16
      | UInt32(raw[offset + 3]) << 24
  }

  /// Appends `value` little-endian, byte by byte.
  private static func appendUInt32(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
  }
}

// MARK: - Header types

/// `source` in the header.
private struct HeaderSource: Codable {
  let formatID: UInt32
  let processingFormat: String
}

/// `filterBank` in the header: a description for people, never read back.
private struct FilterBank: Encodable {
  let lowPassHz: Double
  let midHighPassHz: Double
  let midLowPassHz: Double
  let highHighPassHz: Double
  let highLowPassHz: Double
  let highLowPassUsed: Bool
  let quality: Double
}

/// Every header field written, the diagnostic ones included.
private struct EncodedHeader: Encodable {
  let key: String
  let analysisVersion: String
  let bucketsPerSecond: Double
  let sampleRate: Double
  let channelCount: Int
  let frameCount: Int64
  let framesRead: Int64
  let bucketCount: Int
  let source: HeaderSource
  let elementType: String
  let payloadByteCount: Int
  let filterBank: FilterBank
  let osVersion: String
  let createdAt: String
}

/// The header fields the decoder reads. The diagnostic fields are not
/// declared, so they can never make a file unusable; unknown keys are ignored.
private struct DecodedHeader: Decodable {
  let key: String
  let analysisVersion: String
  let bucketsPerSecond: Double
  let sampleRate: Double
  let channelCount: Int
  let frameCount: Int64
  let framesRead: Int64
  let bucketCount: Int
  let source: HeaderSource
  let elementType: String
  let payloadByteCount: Int
}
