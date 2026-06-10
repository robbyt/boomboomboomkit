//
//  LUFSByteIdentityTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.1 T0/AC6 — byte-identity regression lock for the existing LUFS
//  measurement paths. The bitPattern literals below were captured from the
//  PRE-story analyzer (develop @ ae04011) BEFORE any Story 8.1 edit; they ARE
//  the contract. The 100ms cell primitive (DD #4) is additive — integrated
//  loudness and the 400ms block series must remain bit-identical.
//
//  Two tiers (DD #11):
//  - Tier 1 (bitPattern equality): runtime-synthesized signals + lossless
//    fixtures (WAV/AIFF/FLAC decode is byte-stable).
//  - Tier 2 (tolerance): lossy fixtures. AAC decode is NOT byte-stable — the
//    T0 capture measured sample-with-cover.m4a differing at the 1e-7 LU level
//    across two consecutive runs on the same machine. Never bitPattern-assert
//    on MP3/M4A decode output.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitTestSupport

// MARK: - Deterministic generators (mirrors LUFSAnalyzerTests pattern)

private func sineWave(
  frequencyHz: Double = 997.0,
  sampleRate: Double,
  durationSeconds: Double,
  targetLUFS: Double
) -> [Float] {
  let rms = pow(10.0, targetLUFS / 20.0)
  let amplitude = Float(rms * sqrt(2.0))
  let sampleCount = Int(sampleRate * durationSeconds)
  return (0..<sampleCount).map { i in
    amplitude * sin(Float(2.0 * .pi * frequencyHz * Double(i) / sampleRate))
  }
}

private func loudQuietLoud(sampleRate: Double) -> [Float] {
  let loud1 = sineWave(
    sampleRate: sampleRate, durationSeconds: 5.0, targetLUFS: -14.0)
  let silence = [Float](repeating: 0, count: Int(sampleRate * 5))
  let loud2 = sineWave(
    sampleRate: sampleRate, durationSeconds: 5.0, targetLUFS: -14.0)
  return loud1 + silence + loud2
}

/// FNV-1a (64-bit) over the little-endian bytes of each Double's bitPattern.
/// Locks the FULL block series element-wise without 97 inline literals.
private func fnv1a(_ values: [Double]) -> UInt64 {
  var hash: UInt64 = 0xcbf2_9ce4_8422_2325
  for value in values {
    var bits = value.bitPattern.littleEndian
    withUnsafeBytes(of: &bits) { raw in
      for byte in raw {
        hash ^= UInt64(byte)
        hash = hash &* 0x0000_0100_0000_01b3
      }
    }
  }
  return hash
}

// MARK: - Tier 1: synthesized-signal bitPattern locks

@Suite("LUFS Byte-Identity — Synthesized (Tier 1)")
struct LUFSByteIdentitySynthesizedTests {

  private struct Baseline {
    let integrated: UInt64
    let blockCount: Int
    let block0: UInt64
    let blockLast: UInt64
    let blockFNV: UInt64
  }

  private func assertBaseline(
    samples: [Float], sampleRate: Double, expected: Baseline,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: sampleRate),
      sourceLocation: sourceLocation)
    let blocks = result.blockLoudnessValues
    #expect(
      result.integratedLoudness.bitPattern == expected.integrated,
      "integrated bitPattern drifted: got 0x\(String(result.integratedLoudness.bitPattern, radix: 16))",
      sourceLocation: sourceLocation)
    #expect(blocks.count == expected.blockCount, sourceLocation: sourceLocation)
    #expect(
      blocks[0].bitPattern == expected.block0, sourceLocation: sourceLocation)
    #expect(
      blocks[blocks.count - 1].bitPattern == expected.blockLast,
      sourceLocation: sourceLocation)
    #expect(
      fnv1a(blocks) == expected.blockFNV,
      "block series FNV drifted: got 0x\(String(fnv1a(blocks), radix: 16))",
      sourceLocation: sourceLocation)
    #expect(result.blockStepSeconds == 0.1, sourceLocation: sourceLocation)
  }

  @Test("997 Hz sine @ 48k, -23 LUFS, 10s — bit-identical to pre-story analyzer")
  func sine48k() throws {
    try assertBaseline(
      samples: sineWave(sampleRate: 48000, durationSeconds: 10, targetLUFS: -23),
      sampleRate: 48000,
      expected: Baseline(
        integrated: 0xc036_fffe_7798_51ad,
        blockCount: 97,
        block0: 0xc036_ffc0_c83e_41ab,
        blockLast: 0xc037_0017_4a92_1851,
        blockFNV: 0x9207_c07d_9016_b7f1))
  }

  @Test("997 Hz sine @ 44.1k, -14 LUFS, 10s — bit-identical to pre-story analyzer")
  func sine441k() throws {
    try assertBaseline(
      samples: sineWave(sampleRate: 44100, durationSeconds: 10, targetLUFS: -14),
      sampleRate: 44100,
      expected: Baseline(
        integrated: 0xc02c_0087_c20e_092f,
        blockCount: 97,
        block0: 0xc02c_000e_217e_0159,
        blockLast: 0xc02c_00b7_2f66_f889,
        blockFNV: 0x57f0_2658_5b01_e02d))
  }

  @Test("997 Hz sine @ 96k, -20 LUFS, 10s — bit-identical to pre-story analyzer")
  func sine96k() throws {
    try assertBaseline(
      samples: sineWave(sampleRate: 96000, durationSeconds: 10, targetLUFS: -20),
      sampleRate: 96000,
      expected: Baseline(
        integrated: 0xc034_7a07_1d8a_2a7c,
        blockCount: 97,
        block0: 0xc034_79db_1eb2_e503,
        blockLast: 0xc034_7a09_f990_8334,
        blockFNV: 0x44c5_1803_84d2_4dc9))
  }

  @Test("loud-quiet-loud @ 48k (gating path) — bit-identical to pre-story analyzer")
  func loudQuietLoud48k() throws {
    try assertBaseline(
      samples: loudQuietLoud(sampleRate: 48000),
      sampleRate: 48000,
      expected: Baseline(
        integrated: 0xc02c_43b8_661c_a91e,
        blockCount: 147,
        block0: 0xc02b_ff81_8644_f121,
        blockLast: 0xc02c_002e_d7e2_0a57,
        blockFNV: 0x0c1a_8e7f_bef0_cd3b))
  }
}

// MARK: - Tier 1: lossless-fixture bitPattern locks (maxSeconds: 30 explicit)

@Suite("LUFS Byte-Identity — Lossless Fixtures (Tier 1)")
struct LUFSByteIdentityLosslessFixtureTests {

  private func measure(name: String, ext: String) throws -> LUFSResult {
    let url = try AudioFixtures.url(for: name, extension: ext)
    // maxSeconds: 30 pinned explicitly — the analyzeLUFS default changed to
    // full-file in Story 8.1 (DD #9); these literals were captured at 30s.
    let (samples, rate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 30)
    return try #require(LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: rate))
  }

  @Test("test-bwf.wav — integrated + block series bit-identical")
  func wavFixture() throws {
    let result = try measure(name: "test-bwf", ext: "wav")
    #expect(result.integratedLoudness.bitPattern == 0xc035_c1c6_15e1_b5ea)
    #expect(result.blockLoudnessValues.count == 47)
    #expect(fnv1a(result.blockLoudnessValues) == 0x5de2_d29d_c403_388d)
  }

  @Test("sample-with-cover.aiff — integrated + block series bit-identical")
  func aiffFixture() throws {
    let result = try measure(name: "sample-with-cover", ext: "aiff")
    #expect(result.integratedLoudness.bitPattern == 0xc035_c1d3_a241_237b)
    #expect(result.blockLoudnessValues.count == 7)
    #expect(fnv1a(result.blockLoudnessValues) == 0x3792_b96e_c9ee_5785)
  }

  @Test("sample-with-cover.flac — integrated + block series bit-identical")
  func flacFixture() throws {
    let result = try measure(name: "sample-with-cover", ext: "flac")
    #expect(result.integratedLoudness.bitPattern == 0xc035_c1d3_a241_237b)
    #expect(result.blockLoudnessValues.count == 7)
    #expect(fnv1a(result.blockLoudnessValues) == 0x3792_b96e_c9ee_5785)
  }
}

// MARK: - Tier 2: lossy-fixture tolerance pins (maxSeconds: 30 explicit)

@Suite("LUFS Byte-Identity — Lossy Fixtures (Tier 2, tolerance)")
struct LUFSByteIdentityLossyFixtureTests {

  private func measureIntegrated(name: String, ext: String) throws -> Double {
    let url = try AudioFixtures.url(for: name, extension: ext)
    let (samples, rate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 30)
    let result = try #require(
      LUFSAnalyzer.measureLoudness(samples: samples, sampleRate: rate))
    return result.integratedLoudness
  }

  @Test("Meta_Man.mp3 integrated within ±0.5 LU of captured baseline")
  func mp3MetaMan() throws {
    let integrated = try measureIntegrated(name: "Meta_Man", ext: "mp3")
    #expect(abs(integrated - (-15.577147897717753)) <= 0.5)
  }

  @Test("sample-with-cover.m4a integrated within ±0.5 LU of captured baseline")
  func m4aFixture() throws {
    let integrated = try measureIntegrated(name: "sample-with-cover", ext: "m4a")
    #expect(abs(integrated - (-21.822245236816986)) <= 0.5)
  }

  @Test("sample-with-cover.mp3 integrated within ±0.5 LU of captured baseline")
  func mp3Fixture() throws {
    let integrated = try measureIntegrated(name: "sample-with-cover", ext: "mp3")
    #expect(abs(integrated - (-22.222677811100834)) <= 0.5)
  }
}
