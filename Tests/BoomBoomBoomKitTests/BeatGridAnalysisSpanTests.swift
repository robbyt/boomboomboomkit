//
//  BeatGridAnalysisSpanTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.10 Part A: `BeatGrid.analysisSpan`, the decoded-sample window the
//  onset analysis covered plus the decoded buffer length. Producer plumbing on
//  both coverage paths, the `maxSeconds` cap, the value type's coherence rules,
//  the lenient Codable fold, W52 forwarding, and byte-identical encoding of a
//  span-less grid.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BeatGridAnalysisSpanTests")
struct BeatGridAnalysisSpanTests {

  // MARK: - Fixtures

  private static let sampleRate = 44_100.0

  /// 2 s of silence followed by 60 s of clicks at `bpm`, 44.1 kHz.
  private static func silenceThenClicks(bpm: Double) -> FeatureSubstrate.DecodedAudio {
    let silence = [Float](repeating: 0, count: 2 * 44_100)
    let clicks = generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 60)
    return .synthetic(silence + clicks, sampleRate: sampleRate)
  }

  /// 60 s of clicks at `bpm`, 44.1 kHz.
  private static func clicks60(bpm: Double) -> FeatureSubstrate.DecodedAudio {
    .synthetic(
      generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 60),
      sampleRate: sampleRate)
  }

  /// The JSON a hand-built grid (below) encoded to under `.sortedKeys` at the
  /// baseline commit 424c065, before `analysisSpan` existed. A span-less grid
  /// must still encode to exactly these bytes.
  private static let baselineJSON =
    #"{"beats":[{"confidence":0.75,"presentationTime":0.5,"strength":0.5},"#
    + #"{"confidence":0.25,"presentationTime":1,"strength":1},"#
    + #"{"confidence":1,"presentationTime":1.5,"strength":0.125}],"confidence":0.625,"#
    + #""coverage":{"window":{"seconds":10}},"downbeats":{"detected":{"estimate":{"beats":"#
    + #"[{"confidence":0.25,"presentationTime":1,"strength":1}],"confidence":0.5,"#
    + #""meter":{"beatsPerBar":4,"source":"assumed"},"phaseIndex":1}}},"estimatedTempo":120,"#
    + #""gridOrigin":{"beatIndex":1,"confidence":0.25,"presentationTime":1,"source":"downbeat","#
    + #""strength":1},"schemaVersion":3,"tempoAgreement":{"octaveEquivalent":{"factor":2}},"#
    + #""tempoLockOctaveFactor":-2}"#

  /// The hand-built grid behind ``baselineJSON``, optionally carrying a span.
  private static func handBuiltGrid(analysisSpan: BeatGridAnalysisSpan? = nil) -> BeatGrid {
    let beats = [
      BeatTimestamp(presentationTime: 0.5, confidence: 0.75, strength: 0.5),
      BeatTimestamp(presentationTime: 1.0, confidence: 0.25, strength: 1.0),
      BeatTimestamp(presentationTime: 1.5, confidence: 1.0, strength: 0.125),
    ]
    return BeatGrid(
      beats: beats,
      downbeats: .detected(
        estimate: DownbeatEstimate(
          beats: [beats[1]], meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
          confidence: 0.5, phaseIndex: 1)),
      estimatedTempo: 120.0, confidence: 0.625, tempoAgreement: .octaveEquivalent(factor: 2),
      gridOrigin: BeatGridAnchor(
        beatIndex: 1, presentationTime: 1.0, confidence: 0.25, strength: 1.0, source: .downbeat),
      coverage: .window(seconds: 10), tempoLockOctaveFactor: -2,
      analysisSpan: analysisSpan)
  }

  private static let sampleSpan = BeatGridAnalysisSpan(
    sampleRate: 44_100, startSample: 4_410, endSample: 445_410, decodedSampleCount: 882_000)!

  private static func sortedJSON(_ grid: BeatGrid) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try encoder.encode(grid), as: UTF8.self)
  }

  /// The baseline JSON with an `analysisSpan` member spliced in before the closing
  /// brace (`raw` is the member's JSON value, written by hand).
  private static func baselinePayload(withSpan raw: String) -> Data {
    Data((String(baselineJSON.dropLast()) + #","analysisSpan":"# + raw + "}").utf8)
  }

  // MARK: - Producers: default coverage (AC1) and beat containment (AC4)

  @Test(arguments: [120.0, 128.0])
  func defaultCoverageSpanMatchesTrace(bpm: Double) throws {
    let decoded = Self.silenceThenClicks(bpm: bpm)
    var options = BPMAnalyzer.Options()
    options.computeBeatGrid = true
    options.enableTrace = true
    let result = try #require(BPMAnalyzer.estimateBPM(decoded: decoded, options: options))
    let trace = try #require(result.trace)
    let grid = try #require(result.beatGrid)
    let span = try #require(grid.analysisSpan)

    #expect(span.startSample == trace.energyTransitionOffset)
    #expect(
      Double(span.endSample - span.startSample) / span.sampleRate
        == trace.analysisWindowDuration)
    #expect(span.decodedSampleCount == decoded.samples.count)
    #expect(span.sampleRate == decoded.sampleRate)
    #expect(grid.coverage == .analysisWindow)

    // AC4: emitted beats stay inside the analyzed window. Only complete FFT frames
    // are produced, so no beat time reaches `endSeconds`. Printed for the record;
    // a failure reports the value rather than widening the bound.
    try #require(!grid.beats.isEmpty)
    let times = grid.beats.map(\.presentationTime)
    let minFromStart = times.map { $0 - span.startSeconds }.min()!
    let maxFromEnd = times.map { $0 - span.endSeconds }.max()!
    print(
      "AC4 \(bpm) BPM: min(beat - startSeconds) = \(minFromStart) s, "
        + "max(beat - endSeconds) = \(maxFromEnd) s, beats = \(times.count), span = \(span)")
    for t in times {
      try #require(
        t >= span.startSeconds && t < span.endSeconds,
        "beat at \(t) s lies outside [\(span.startSeconds), \(span.endSeconds))")
    }
  }

  // MARK: - Producers: explicit coverage (AC2)

  @Test(arguments: [120.0, 128.0])
  func fullTrackAndWindowSpansStartAtTheDefaultStart(bpm: Double) throws {
    let decoded = Self.silenceThenClicks(bpm: bpm)

    let defaultResult = try #require(try AudioAnalysisService.analyze(decoded: decoded))
    let defaultSpan = try #require(defaultResult.beatGrid?.analysisSpan)

    var fullOptions = AudioAnalysisService.Options()
    fullOptions.beatGridCoverage = .fullTrack
    let fullResult = try #require(
      try AudioAnalysisService.analyze(decoded: decoded, options: fullOptions))
    let fullSpan = try #require(fullResult.beatGrid?.analysisSpan)
    #expect(fullSpan.endSample == fullSpan.decodedSampleCount)
    #expect(fullSpan.startSample == defaultSpan.startSample)
    #expect(fullSpan.decodedSampleCount == decoded.samples.count)
    #expect(fullResult.beatGrid?.coverage == .fullTrack)

    var windowOptions = AudioAnalysisService.Options()
    windowOptions.beatGridCoverage = .window(seconds: 10)
    let windowResult = try #require(
      try AudioAnalysisService.analyze(decoded: decoded, options: windowOptions))
    let windowSpan = try #require(windowResult.beatGrid?.analysisSpan)
    #expect(
      windowSpan.endSample - windowSpan.startSample
        == min(441_000, windowSpan.decodedSampleCount - windowSpan.startSample))
    #expect(windowSpan.startSample == defaultSpan.startSample)
    #expect(windowSpan.decodedSampleCount == decoded.samples.count)

    // The coverage pass's beats also stay inside its own span.
    for grid in [fullResult.beatGrid, windowResult.beatGrid].compactMap({ $0 }) {
      let span = try #require(grid.analysisSpan)
      for beat in grid.beats {
        #expect(
          beat.presentationTime >= span.startSeconds && beat.presentationTime < span.endSeconds,
          "beat at \(beat.presentationTime) s lies outside \(span)")
      }
    }
  }

  // MARK: - maxSeconds cap (AC3)

  @Test(arguments: [120.0, 128.0])
  func cappedDecodeIsRecorded(bpm: Double) throws {
    let decoded = Self.clicks60(bpm: bpm)
    var options = AudioAnalysisService.Options()
    options.maxSeconds = 20

    let combined = try #require(
      try AudioAnalysisService.analyze(decoded: decoded, options: options))
    let combinedSpan = try #require(combined.beatGrid?.analysisSpan)
    let standalone = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: options))
    let standaloneSpan = try #require(standalone.analysisSpan)

    for span in [combinedSpan, standaloneSpan] {
      #expect(span.decodedSampleCount == 882_000)
      #expect(span.decodedDurationSeconds == 20.0)
    }
    #expect(combinedSpan == standaloneSpan)
  }

  // MARK: - Unit-level analyzer call carries no span

  @Test func unitLevelAnalyzerCallHasNoSpan() throws {
    var env = [Float](repeating: 0, count: 1000)
    for f in stride(from: 0, to: env.count, by: 50) { env[f] = 1 }
    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44_100,
        acf: env, tempoBPM: 120, windowStartSample: 0))
    #expect(grid.analysisSpan == nil)

    // Supplying only one of the two counts still yields no span.
    let half = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44_100,
        acf: env, tempoBPM: 120, windowStartSample: 0, windowSampleCount: 441_000))
    #expect(half.analysisSpan == nil)

    // Both counts: a span, and every other field equals the span-less grid's.
    let both = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44_100,
        acf: env, tempoBPM: 120, windowStartSample: 100, windowSampleCount: 441_000,
        decodedSampleCount: 500_000))
    #expect(
      both.analysisSpan
        == BeatGridAnalysisSpan(
          sampleRate: 44_100, startSample: 100, endSample: 441_100, decodedSampleCount: 500_000))
    let unspanned = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: env, onsetRate: 100, hopSize: 441, sampleRate: 44_100,
        acf: env, tempoBPM: 120, windowStartSample: 100))
    #expect(both == unspanned.restamped(analysisSpan: both.analysisSpan))
  }

  // MARK: - Value type

  @Test func validSpanComputesSeconds() throws {
    let span = try #require(
      BeatGridAnalysisSpan(
        sampleRate: 44_100, startSample: 88_200, endSample: 1_411_200,
        decodedSampleCount: 2_734_200))
    #expect(span.startSeconds == 2.0)
    #expect(span.endSeconds == 32.0)
    #expect(span.decodedDurationSeconds == 62.0)

    // An empty window and a window ending at the buffer end are coherent.
    #expect(
      BeatGridAnalysisSpan(sampleRate: 48_000, startSample: 0, endSample: 0, decodedSampleCount: 0)
        != nil)
    #expect(
      BeatGridAnalysisSpan(sampleRate: 48_000, startSample: 5, endSample: 9, decodedSampleCount: 9)
        != nil)
  }

  @Test(arguments: [
    (44_100.0, 10, 5, 100),  // endSample < startSample
    (44_100.0, -1, 5, 100),  // startSample < 0
    (44_100.0, 0, 200, 100),  // decodedSampleCount < endSample
    (0.0, 0, 5, 100),  // sampleRate zero
    (-44_100.0, 0, 5, 100),  // sampleRate negative
    (Double.nan, 0, 5, 100),
    (Double.infinity, 0, 5, 100),
    (-Double.infinity, 0, 5, 100),
    (1e-300, 0, 5, Int.max),  // decodedSampleCount / sampleRate not finite
  ])
  func incoherentSpanIsRejected(
    sampleRate: Double, startSample: Int, endSample: Int, decodedSampleCount: Int
  ) {
    #expect(
      BeatGridAnalysisSpan(
        sampleRate: sampleRate, startSample: startSample, endSample: endSample,
        decodedSampleCount: decodedSampleCount) == nil)
  }

  @Test(arguments: [
    #"{"sampleRate":44100,"startSample":10,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":44100,"startSample":-1,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":44100,"startSample":0,"endSample":200,"decodedSampleCount":100}"#,
    #"{"sampleRate":0,"startSample":0,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":-44100,"startSample":0,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":1e-300,"startSample":0,"endSample":5,"decodedSampleCount":9223372036854775807}"#,
  ])
  func incoherentSpanPayloadThrowsDataCorruptedOnItsOwn(json: String) {
    do {
      _ = try JSONDecoder().decode(BeatGridAnalysisSpan.self, from: Data(json.utf8))
      Issue.record("an incoherent span payload decoded")
    } catch DecodingError.dataCorrupted {
      // Expected.
    } catch {
      Issue.record("expected DecodingError.dataCorrupted, got \(error)")
    }
  }

  // MARK: - Codable on BeatGrid

  @Test func spanLessGridEncodesByteIdenticalToBaseline() throws {
    let grid = Self.handBuiltGrid()
    #expect(grid.analysisSpan == nil)
    let json = try Self.sortedJSON(grid)
    #expect(json == Self.baselineJSON)
    #expect(!json.contains("analysisSpan"))
    #expect(BeatGrid.currentSchemaVersion == 3)
  }

  @Test func legacyPayloadDecodesWithoutSpan() throws {
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Data(Self.baselineJSON.utf8))
    #expect(decoded.analysisSpan == nil)
    #expect(decoded.schemaVersion == 3)
    #expect(decoded == Self.handBuiltGrid())

    // The stored version is kept as written, not restamped.
    let v2 = Self.baselineJSON.replacingOccurrences(
      of: #""schemaVersion":3"#, with: #""schemaVersion":2"#)
    let decodedV2 = try JSONDecoder().decode(BeatGrid.self, from: Data(v2.utf8))
    #expect(decodedV2.schemaVersion == 2)
    #expect(decodedV2.analysisSpan == nil)

    // An explicit null is absent.
    let explicitNull = try JSONDecoder().decode(
      BeatGrid.self, from: Self.baselinePayload(withSpan: "null"))
    #expect(explicitNull.analysisSpan == nil)
  }

  @Test(arguments: [
    // Incoherent values.
    #"{"sampleRate":44100,"startSample":10,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":44100,"startSample":-1,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":44100,"startSample":0,"endSample":200,"decodedSampleCount":100}"#,
    #"{"sampleRate":0,"startSample":0,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":-44100,"startSample":0,"endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":1e-300,"startSample":0,"endSample":5,"decodedSampleCount":9223372036854775807}"#,
    // Unreadable structure.
    #""0..<100""#,
    #"[0,5,100]"#,
    #"{"sampleRate":44100,"startSample":"0","endSample":5,"decodedSampleCount":100}"#,
    #"{"sampleRate":44100,"startSample":0,"endSample":5}"#,
    #"{"sampleRate":44100,"startSample":0,"endSample":5,"decodedSampleCount":1e40}"#,
    #"{"sampleRate":44100,"startSample":0,"endSample":5,"decodedSampleCount":100000000000000000000000}"#,
  ])
  func unreadableSpanFoldsToNilAndTheGridDecodes(raw: String) throws {
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Self.baselinePayload(withSpan: raw))
    #expect(decoded.analysisSpan == nil)
    #expect(decoded == Self.handBuiltGrid())
  }

  @Test func spanRoundTrips() throws {
    let grid = Self.handBuiltGrid(analysisSpan: Self.sampleSpan)
    let json = try Self.sortedJSON(grid)
    #expect(
      json.contains(
        #""analysisSpan":{"decodedSampleCount":882000,"endSample":445410,"#
          + #""sampleRate":44100,"startSample":4410}"#))
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(decoded == grid)
    #expect(decoded.analysisSpan == Self.sampleSpan)

    // The one-line summary shows whether a span is present.
    #expect(grid.description.hasSuffix("span: \(Self.sampleSpan))"))
    #expect(Self.handBuiltGrid().description.hasSuffix("span: none)"))
  }

  // MARK: - Forwarding (W52)

  @Test func forwardersCarryTheSpan() throws {
    let grid = Self.handBuiltGrid(analysisSpan: Self.sampleSpan)

    #expect(grid.with(tempoAgreement: .agree).analysisSpan == Self.sampleSpan)
    #expect(
      grid.with(estimatedTempo: 121, tempoLockOctaveFactor: 1).analysisSpan == Self.sampleSpan)
    #expect(grid.repositioningAnchor(to: 1.4).analysisSpan == Self.sampleSpan)
    #expect(
      grid.repositioningAnchor(to: 1.234, mode: .exactTime).analysisSpan == Self.sampleSpan)

    // offset(by:) shifts the beats and leaves the span alone.
    let shifted = grid.offset(by: 0.0125)
    #expect(shifted.analysisSpan == Self.sampleSpan)
    try #require(shifted.beats.count == grid.beats.count)
    for (moved, original) in zip(shifted.beats, grid.beats) {
      #expect(moved.presentationTime == original.presentationTime + 0.0125)
    }
    #expect(shifted.beats != grid.beats)

    // A firing tempo lock keeps the span.
    let locked = try #require(
      AudioAnalysisService.applyTempoLock(grid, lock: .bpm(121), bpmStageTempo: 120))
    #expect(locked.estimatedTempo == 121)
    #expect(locked.analysisSpan == Self.sampleSpan)
    let stageLocked = try #require(
      AudioAnalysisService.applyTempoLock(grid, lock: .bpmStage, bpmStageTempo: 119))
    #expect(stageLocked.estimatedTempo == 119)
    #expect(stageLocked.analysisSpan == Self.sampleSpan)
  }

  @Test(arguments: [120.0, 128.0])
  func firingTempoLockInCombinedAnalysisKeepsTheSpan(bpm: Double) throws {
    let decoded = Self.silenceThenClicks(bpm: bpm)
    let unlocked = try #require(try AudioAnalysisService.analyze(decoded: decoded))
    let unlockedGrid = try #require(unlocked.beatGrid)
    let target = unlockedGrid.estimatedTempo * 1.01

    var options = AudioAnalysisService.Options()
    options.beatGridTempoLock = .bpm(target)
    let locked = try #require(try AudioAnalysisService.analyze(decoded: decoded, options: options))
    let lockedGrid = try #require(locked.beatGrid)
    #expect(lockedGrid.estimatedTempo == target)
    #expect(lockedGrid.analysisSpan != nil)
    #expect(lockedGrid.analysisSpan == unlockedGrid.analysisSpan)
  }
}

extension BeatGrid {
  /// Test-only rebuild with a replaced span, forwarding every other field.
  fileprivate func restamped(analysisSpan newSpan: BeatGridAnalysisSpan?) -> BeatGrid {
    BeatGrid(
      beats: beats, downbeats: downbeats, estimatedTempo: estimatedTempo,
      confidence: confidence, tempoAgreement: tempoAgreement, gridOrigin: gridOrigin,
      coverage: coverage, schemaVersion: schemaVersion,
      tempoLockOctaveFactor: tempoLockOctaveFactor, analysisSpan: newSpan)
  }
}
