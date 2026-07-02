//
//  ClickTrackAIFFBuilder.swift
//  BoomBoomBoomKitTestSupport
//
//  Synthetic AIFF builder: click-track PCM + embedded ID3v2.3 TBPM tag.
//  Promoted from MetadataCorroborationTests (Story 8-2) so the shared-decode
//  divergence-by-design metadata lock can build tagged fixtures too.
//

import Foundation

/// Synthetic AIFF writer: click-track PCM plus an embedded ID3v2.3 `TBPM`
/// tag. Builds the tagged fixtures that metadata-corroboration and
/// shared-decode divergence-lock tests exercise without committing binary
/// audio files.
public enum ClickTrackAIFFBuilder {

  /// Returns the URL of a temp AIFF file with `bpm` click track and `tbpm`
  /// metadata. Caller is responsible for cleanup.
  ///
  /// Parameters are precondition-guarded (review 2026-06-11): degenerate
  /// values previously trapped deep in the synthesis arithmetic with no
  /// diagnostic (`Int(±Inf)`, zero-stride, negative array count).
  public static func write(
    clickBPM: Double,
    durationSeconds: Double,
    tbpm: String,
    sampleRate: Double = 44100,
    tbpmFrames: [String]? = nil
  ) throws -> URL {
    precondition(
      clickBPM.isFinite && clickBPM > 0,
      "clickBPM must be finite and > 0 (got \(clickBPM))")
    precondition(
      durationSeconds.isFinite && durationSeconds >= 0,
      "durationSeconds must be finite and >= 0 (got \(durationSeconds))")
    precondition(
      sampleRate.isFinite
        && sampleRate >= 1
        && sampleRate.rounded(.towardZero) == sampleRate
        && sampleRate < Double(UInt64.max),
      "sampleRate must be a finite integer Hz value with 1 <= rate < 2^64 "
        + "(got \(sampleRate)) — the ieee80 encoder is restricted to integer Hz rates. "
        + "The bound is strict: Double(UInt64.max) rounds up to 2^64, so `<= Double(UInt64.max)` "
        + "would admit 2^64 and trap in UInt64(rate)")
    let rawSampleCount = sampleRate * durationSeconds
    precondition(
      rawSampleCount.isFinite,
      "sampleRate × durationSeconds must stay finite (got \(sampleRate) × \(durationSeconds))")
    let sampleCount = boundedTruncatingInt(
      rawSampleCount, label: "sampleRate × durationSeconds")
    let maxSampleCount = Int((UInt32.max - 8) / 2)
    precondition(
      sampleCount <= maxSampleCount,
      "sampleCount must fit AIFF SSND/COMM chunk fields (max = \(maxSampleCount), got \(sampleCount))"
    )
    let rawSamplesPerBeat = sampleRate * 60.0 / clickBPM
    precondition(
      rawSamplesPerBeat.isFinite,
      "sampleRate × 60 / clickBPM must stay finite (got \(sampleRate) × 60 / \(clickBPM))")
    let samplesPerBeat = boundedTruncatingInt(
      rawSamplesPerBeat, label: "sampleRate × 60 / clickBPM")
    precondition(
      samplesPerBeat > 0,
      "clickBPM \(clickBPM) too high for sampleRate \(sampleRate) — "
        + "zero samples per beat")
    var samples = [Int16](repeating: 0, count: sampleCount)
    for beatStart in stride(from: 0, to: sampleCount, by: samplesPerBeat) {
      let impulseEnd = min(beatStart + 64, sampleCount)
      for i in beatStart..<impulseEnd {
        let decay = exp(-Double(i - beatStart) / 10.0)
        samples[i] = Int16(decay * 32000)
      }
    }

    var ssndPayload = Data()
    var offset: UInt32 = 0
    var blockSize: UInt32 = 0
    withUnsafeBytes(of: &offset) { ssndPayload.append(contentsOf: $0.reversed()) }
    withUnsafeBytes(of: &blockSize) { ssndPayload.append(contentsOf: $0.reversed()) }
    for s in samples {
      var be = s.bigEndian
      withUnsafeBytes(of: &be) { ssndPayload.append(contentsOf: $0) }
    }

    var commPayload = Data()
    // channels = 1
    commPayload.append(contentsOf: [0x00, 0x01])
    // numSampleFrames (BE 32)
    var n = UInt32(sampleCount).bigEndian
    withUnsafeBytes(of: &n) { commPayload.append(contentsOf: $0) }
    // sampleSize = 16
    commPayload.append(contentsOf: [0x00, 0x10])
    // sampleRate (10-byte IEEE 80-bit BE).
    commPayload.append(contentsOf: ieee80SampleRate(sampleRate))

    let tbpmFrameBytes = (tbpmFrames ?? [tbpm]).reduce(into: Data()) { frames, value in
      frames.append(tbpmFrame(value))
    }

    var id3Tag = Data()
    id3Tag.append(contentsOf: [0x49, 0x44, 0x33, 0x03, 0x00, 0x00])  // ID3 v2.3
    id3Tag.append(contentsOf: synchsafe(UInt32(tbpmFrameBytes.count)))
    id3Tag.append(tbpmFrameBytes)

    var aiff = Data()
    aiff.append(contentsOf: [0x46, 0x4F, 0x52, 0x4D])  // FORM
    let chunks =
      chunkBytes("COMM", payload: commPayload)
      + chunkBytes("SSND", payload: ssndPayload)
      + chunkBytes("ID3 ", payload: id3Tag)
    precondition(
      chunks.count <= Int(UInt32.max) - 4,
      "AIFF FORM size must fit UInt32 size field (got \(chunks.count + 4) bytes)")
    var formSize = UInt32(4 + chunks.count).bigEndian
    withUnsafeBytes(of: &formSize) { aiff.append(contentsOf: $0) }
    aiff.append(contentsOf: [0x41, 0x49, 0x46, 0x46])  // AIFF
    aiff.append(chunks)

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("clk-meta-\(UUID().uuidString).aiff")
    try aiff.write(to: url)
    return url
  }

  private static func chunkBytes(_ id: String, payload: Data) -> Data {
    precondition(
      payload.count <= Int(UInt32.max),
      "AIFF chunk \(id) payload must fit UInt32 size field (got \(payload.count) bytes)")
    var chunk = Data()
    chunk.append(contentsOf: Array(id.utf8))
    var sz = UInt32(payload.count).bigEndian
    withUnsafeBytes(of: &sz) { chunk.append(contentsOf: $0) }
    chunk.append(payload)
    if payload.count & 1 == 1 { chunk.append(0x00) }
    return chunk
  }

  private static func tbpmFrame(_ value: String) -> Data {
    var framePayload = Data([0x03])  // UTF-8 encoding marker
    framePayload.append(Data(value.utf8))
    var frame = Data()
    frame.append(contentsOf: Array("TBPM".utf8))
    var fsize = UInt32(framePayload.count).bigEndian
    withUnsafeBytes(of: &fsize) { frame.append(contentsOf: $0) }
    frame.append(contentsOf: [0x00, 0x00])
    frame.append(framePayload)
    return frame
  }

  /// Encodes `rate` (>0, common values like 44100/48000/96000) as an
  /// AIFF-spec 80-bit IEEE big-endian sample rate. Restricted to integer Hz
  /// in the practical range — sufficient for click-track tests.
  private static func ieee80SampleRate(_ rate: Double) -> [UInt8] {
    precondition(
      rate.isFinite
        && rate >= 1
        && rate.rounded(.towardZero) == rate
        && rate < Double(UInt64.max),
      "ieee80SampleRate requires a finite integer Hz value with 1 <= rate < 2^64 (got \(rate)) "
        + "— strict upper bound because Double(UInt64.max) rounds up to 2^64, which UInt64(rate) cannot hold"
    )
    let r = UInt64(rate)
    // Find the highest bit set.
    let highBit = 63 - r.leadingZeroBitCount
    let exponent = UInt16(16383 + highBit)
    // Mantissa: shift `r` so the high bit is at bit 63.
    let shift = 63 - highBit
    let mantissa = r << shift
    var bytes: [UInt8] = []
    bytes.append(UInt8((exponent >> 8) & 0xFF))
    bytes.append(UInt8(exponent & 0xFF))
    for i in stride(from: 56, through: 0, by: -8) {
      bytes.append(UInt8((mantissa >> i) & 0xFF))
    }
    return bytes
  }

  private static func boundedTruncatingInt(_ value: Double, label: String) -> Int {
    precondition(
      value >= 0 && value < Double(Int.max),
      "\(label) must be representable as Int before truncation (must satisfy 0 <= value < 2^63; "
        + "Int.max = \(Int.max), got \(value)) — strict upper bound because Double(Int.max) rounds "
        + "up to 2^63, which Int(value) cannot hold"
    )
    return Int(value.rounded(.towardZero))
  }

  private static func synchsafe(_ n: UInt32) -> [UInt8] {
    [
      UInt8((n >> 21) & 0x7F),
      UInt8((n >> 14) & 0x7F),
      UInt8((n >> 7) & 0x7F),
      UInt8(n & 0x7F),
    ]
  }
}
