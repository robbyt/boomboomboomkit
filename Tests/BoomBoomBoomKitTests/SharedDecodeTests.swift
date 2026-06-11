//
//  SharedDecodeTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8-2 shared-decode seam tests: DecodedAudio currency migration locks
//  (commit 1), then the decodeOnce funnel / decoded-overload equality,
//  cancellation, and codec-tagging suites (commit 2+).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Commit 1: DecodedAudio currency locks

@Suite("Shared Decode — DecodedAudio currency (commit 1)")
struct DecodedAudioCurrencyTests {

  /// DD #4 provenance-invariance: `DecodedAudio` is a carrier — nothing
  /// downstream may branch on provenance fields. Same samples under two
  /// different codec tags must produce bitPattern-identical `BPMResult`.
  @Test func bpmProvenanceInvariance() throws {
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 44100, durationSeconds: 15)
    let taggedLPCM = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 44100,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone))
    let taggedMP3 = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 44100,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .mp3, trimState: .unknown))

    let lpcmResult = try #require(BPMAnalyzer.estimateBPM(decoded: taggedLPCM))
    let mp3Result = try #require(BPMAnalyzer.estimateBPM(decoded: taggedMP3))

    #expect(lpcmResult.bpm.bitPattern == mp3Result.bpm.bitPattern)
    #expect(lpcmResult.confidence.bitPattern == mp3Result.confidence.bitPattern)
    try #require(lpcmResult.candidates.count == mp3Result.candidates.count)
    for (a, b) in zip(lpcmResult.candidates, mp3Result.candidates) {
      #expect(a.bpm.bitPattern == b.bpm.bitPattern)
      #expect(a.score.bitPattern == b.score.bitPattern)
    }
  }

  /// DD #4 provenance-invariance for the LUFS analyzer: same samples, two
  /// codec tags, bitPattern-identical integrated loudness + block series.
  @Test func lufsProvenanceInvariance() throws {
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 48000, durationSeconds: 10)
    let taggedLPCM = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 48000,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone))
    let taggedAAC = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 48000,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .aac, trimState: .unknown))

    let lpcmResult = try #require(LUFSAnalyzer.measureLoudness(decoded: taggedLPCM))
    let aacResult = try #require(LUFSAnalyzer.measureLoudness(decoded: taggedAAC))

    #expect(
      lpcmResult.integratedLoudness.bitPattern == aacResult.integratedLoudness.bitPattern)
    try #require(
      lpcmResult.blockLoudnessValues.count == aacResult.blockLoudnessValues.count)
    for (a, b) in zip(lpcmResult.blockLoudnessValues, aacResult.blockLoudnessValues) {
      #expect(a.bitPattern == b.bitPattern)
    }
  }

  /// DD #5: analyzers still never throw — a `DecodedAudio` at the 8 kHz
  /// precondition boundary (valid carrier, unsupported K-weighting rate)
  /// returns nil from the analyzer. The matching SERVICE-level throw is
  /// locked in the decoded-overload suite (commit 2+).
  @Test func lufsAnalyzerUnsupportedRateReturnsNil() {
    let samples = [Float](repeating: 0.25, count: 8_000)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 8_000)
    #expect(LUFSAnalyzer.measureLoudness(decoded: decoded) == nil)
  }

  /// `synthetic` pins provenance — the single test-construction path never
  /// hand-picks codec tags (DD #4).
  @Test func syntheticPinsProvenance() {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic([0.0], sampleRate: 44100)
    #expect(decoded.codecPriming.codec == .linearPCM)
    #expect(decoded.codecPriming.trimState == .knownNone)
    #expect(decoded.sampleRate == 44100)
    #expect(decoded.samples.count == 1)
  }
}

// MARK: - AC6 (type-level): AudioCodec / PrimingInfo reshape invariants

@Suite("Shared Decode — AudioCodec/PrimingInfo reshape (AC6)")
struct CodecProvenanceTypeTests {

  /// SET-equality, not count (count passes when a case is swapped) — DD #7.
  @Test func audioCodecCaseSetLocked() {
    #expect(
      Set(FeatureSubstrate.AudioCodec.allCases) == [
        .linearPCM, .aac, .alac, .mp3, .flac, .unknown,
      ])
  }

  /// Codable round-trip for the reshaped PrimingInfo (AC6).
  @Test func primingInfoCodableRoundTrip() throws {
    let values: [FeatureSubstrate.PrimingInfo] = [
      .init(codec: .linearPCM, trimState: .knownNone),
      .init(codec: .aac, trimState: .unknown),
      .init(codec: .flac, trimState: .unknown),
      .init(codec: .unknown, trimState: .unknown),
    ]
    for value in values {
      let data = try JSONEncoder().encode(value)
      let decoded = try JSONDecoder().decode(
        FeatureSubstrate.PrimingInfo.self, from: data)
      #expect(decoded == value)
    }
  }
}
