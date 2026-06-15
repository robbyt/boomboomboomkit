//
//  ClickTrackAIFFBuilderTests.swift
//  BoomBoomBoomKitTests
//
//  Locks the ClickTrackAIFFBuilder synthetic-AIFF encoder: chunk-size fields,
//  IEEE-80 sample-rate round-trip, and the precondition bounds hardened in
//  the "harden ClickTrackAIFFBuilder bounds" change. The death tests assert
//  that degenerate inputs trap in the guard (clean diagnostic) rather than
//  deep in the synthesis arithmetic.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("ClickTrackAIFFBuilder — encoder structure")
struct ClickTrackAIFFBuilderStructureTests {

  /// Reads the file the builder wrote and returns the raw bytes.
  private func writtenBytes(
    clickBPM: Double, durationSeconds: Double, tbpm: String, sampleRate: Double
  ) throws -> [UInt8] {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: clickBPM, durationSeconds: durationSeconds, tbpm: tbpm,
      sampleRate: sampleRate)
    defer { try? FileManager.default.removeItem(at: url) }
    return Array(try Data(contentsOf: url))
  }

  private func beUInt32(_ b: ArraySlice<UInt8>) -> UInt32 {
    b.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
  }

  /// Decodes a 10-byte AIFF IEEE-80 big-endian extended float back to a Double.
  private func decodeIEEE80(_ b: ArraySlice<UInt8>) -> Double {
    let bytes = Array(b)
    let exponent = (Int(bytes[0]) << 8 | Int(bytes[1])) & 0x7FFF
    var mantissa: UInt64 = 0
    for i in 2..<10 { mantissa = (mantissa << 8) | UInt64(bytes[i]) }
    // value = mantissa * 2^(exponent - 16383 - 63)
    return Double(mantissa) * pow(2.0, Double(exponent - 16383 - 63))
  }

  /// Walks the FORM body and returns (id, declaredSize, payloadStart) per chunk.
  private func chunks(_ aiff: [UInt8]) -> [(id: String, size: Int, payloadStart: Int)] {
    var out: [(String, Int, Int)] = []
    var i = 12  // skip "FORM" + size + "AIFF"
    while i + 8 <= aiff.count {
      let id = String(bytes: aiff[i..<i + 4], encoding: .utf8) ?? ""
      let size = Int(beUInt32(aiff[i + 4..<i + 8]))
      let payloadStart = i + 8
      out.append((id, size, payloadStart))
      i = payloadStart + size + (size & 1)  // word-aligned padding
    }
    return out
  }

  @Test("FORM header + size field match the written file")
  func formHeaderAndSize() throws {
    let aiff = try writtenBytes(
      clickBPM: 120, durationSeconds: 2.0, tbpm: "120", sampleRate: 44100)
    #expect(Array(aiff[0..<4]) == Array("FORM".utf8))
    #expect(Array(aiff[8..<12]) == Array("AIFF".utf8))
    // FORM size counts everything after the 8-byte FORM+size header.
    #expect(Int(beUInt32(aiff[4..<8])) == aiff.count - 8)
  }

  @Test("COMM numSampleFrames + SSND size reflect the truncated sample count")
  func commAndSsndSizing() throws {
    // 44100 Hz x 2.0 s -> exactly 88_200 samples (no truncation ambiguity).
    let expectedSamples = 88_200
    let aiff = try writtenBytes(
      clickBPM: 120, durationSeconds: 2.0, tbpm: "120", sampleRate: 44100)
    let parsed = chunks(aiff)

    let comm = try #require(parsed.first { $0.id == "COMM" })
    // COMM payload: channels(2) numSampleFrames(4) sampleSize(2) rate(10).
    let numFrames = Int(beUInt32(aiff[comm.payloadStart + 2..<comm.payloadStart + 6]))
    #expect(numFrames == expectedSamples)

    let ssnd = try #require(parsed.first { $0.id == "SSND" })
    // SSND payload: offset(4) blockSize(4) + sampleCount * 2 (Int16 samples).
    #expect(ssnd.size == 8 + expectedSamples * 2)
  }

  @Test(
    "IEEE-80 sample rate round-trips for common integer rates",
    arguments: [22_050.0, 44_100.0, 48_000.0, 96_000.0])
  func sampleRateRoundTrip(rate: Double) throws {
    let aiff = try writtenBytes(
      clickBPM: 120, durationSeconds: 0.1, tbpm: "120", sampleRate: rate)
    let comm = try #require(chunks(aiff).first { $0.id == "COMM" })
    // sampleRate is the trailing 10 bytes of the 18-byte COMM payload.
    let decoded = decodeIEEE80(aiff[comm.payloadStart + 8..<comm.payloadStart + 18])
    #expect(decoded == rate)
  }

  @Test("ID3 chunk carries the TBPM tag value")
  func id3ChunkPresent() throws {
    let aiff = try writtenBytes(
      clickBPM: 128, durationSeconds: 0.1, tbpm: "128", sampleRate: 44100)
    let id3 = try #require(chunks(aiff).first { $0.id == "ID3 " })
    let payload = Array(aiff[id3.payloadStart..<id3.payloadStart + id3.size])
    #expect(Array(payload[0..<3]) == Array("ID3".utf8))  // ID3 magic
    // The TBPM frame id appears somewhere in the tag body.
    let tbpmId = Array("TBPM".utf8)
    let containsTBPM = (0...(payload.count - tbpmId.count)).contains {
      Array(payload[$0..<$0 + tbpmId.count]) == tbpmId
    }
    #expect(containsTBPM)
  }
}

@Suite("ClickTrackAIFFBuilder — precondition guards")
struct ClickTrackAIFFBuilderGuardTests {

  @Test("non-finite sampleRate traps in the guard")
  func nonFiniteSampleRate() async {
    await #expect(processExitsWith: .failure) {
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: 120, durationSeconds: 1, tbpm: "120", sampleRate: .infinity)
    }
  }

  @Test("non-integer sampleRate traps in the guard")
  func nonIntegerSampleRate() async {
    await #expect(processExitsWith: .failure) {
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: 120, durationSeconds: 1, tbpm: "120", sampleRate: 44_100.5)
    }
  }

  @Test("sampleRate below 1 Hz traps in the guard")
  func subHertzSampleRate() async {
    await #expect(processExitsWith: .failure) {
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: 120, durationSeconds: 1, tbpm: "120", sampleRate: 0)
    }
  }

  @Test("non-finite clickBPM traps in the guard")
  func nonFiniteClickBPM() async {
    await #expect(processExitsWith: .failure) {
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: .nan, durationSeconds: 1, tbpm: "120", sampleRate: 44_100)
    }
  }

  @Test("negative durationSeconds traps in the guard")
  func negativeDuration() async {
    await #expect(processExitsWith: .failure) {
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: 120, durationSeconds: -1, tbpm: "120", sampleRate: 44_100)
    }
  }

  @Test("clickBPM too high for the sample rate (zero samples/beat) traps")
  func zeroSamplesPerBeat() async {
    await #expect(processExitsWith: .failure) {
      // 44100 * 60 / 1e9 << 1 sample/beat -> truncates to 0.
      _ = try ClickTrackAIFFBuilder.write(
        clickBPM: 1_000_000_000, durationSeconds: 1, tbpm: "120", sampleRate: 44_100)
    }
  }
}
