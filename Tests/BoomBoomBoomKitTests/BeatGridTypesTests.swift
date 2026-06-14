//
//  BeatGridTypesTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.3 + 8.5 tests for the beat-grid public value types:
//  BeatTimestamp, DownbeatResult, BeatGrid — shape, clamping, synthesized
//  Hashable soundness, Codable round-trip / hostile-decode — plus the Story-8.5
//  additions: TempoAgreement, BeatGridAnchor / BeatGridAnchorSource, and
//  BeatGridCoverage (including its NaN-free sanitization doctrine).
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("BeatGridTypesTests")
struct BeatGridTypesTests {

  // MARK: - Helpers

  /// Builds `n` representative beats with finite, in-range fields.
  private static func makeBeats(_ n: Int) -> [BeatTimestamp] {
    (0..<n).map { i -> BeatTimestamp in
      let time = Double(i) * 0.5
      let confidence: Float = (i % 2 == 0) ? 0.9 : 0.4
      let strength: Float = (i % 3 == 0) ? 0.7 : 0.2
      return BeatTimestamp(
        presentationTime: time, confidence: confidence, strength: strength)
    }
  }

  /// A representative anchor for round-trip / construction tests.
  private static let sampleAnchor = BeatGridAnchor(
    beatIndex: 2, presentationTime: 1.0, confidence: 0.8, strength: 0.6,
    source: .medianConsistentBeat)

  /// The documented canonical "no beat-grid run" sentinel (Story 8.5 shape).
  private static let noRunSentinel = BeatGrid(
    beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
    tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)

  // MARK: - AC1: shapes & sentinels

  @Test func typesConstructWithDocumentedShapes() {
    let ts = BeatTimestamp(presentationTime: 1.0, confidence: 0.8, strength: 0.5)
    #expect(ts.presentationTime == 1.0)
    #expect(ts.confidence == 0.8)
    #expect(ts.strength == 0.5)

    // 3 beats so `sampleAnchor.beatIndex == 2` is in range (the gridOrigin
    // invariant — an out-of-range anchor would be dropped to nil).
    let grid = BeatGrid(
      beats: [ts, ts, ts], downbeats: .detected(beats: [ts]), estimatedTempo: 128.0,
      confidence: 0.9, tempoAgreement: .agree, gridOrigin: Self.sampleAnchor,
      coverage: .fullTrack)
    #expect(grid.beats.count == 3)
    #expect(grid.estimatedTempo == 128.0)
    #expect(grid.confidence == 0.9)
    #expect(grid.tempoAgreement == .agree)
    #expect(grid.gridOrigin == Self.sampleAnchor)
    #expect(grid.coverage == .fullTrack)
  }

  @Test func downbeatResultHasThreeCases() {
    #expect(DownbeatResult.notAttempted.description == "notAttempted")
    #expect(DownbeatResult.noneDetected.description == "noneDetected")
    #expect(
      DownbeatResult.detected(beats: Self.makeBeats(3)).description
        == "detected(3 beats)")
  }

  @Test func noRunSentinelShape() {
    let s = Self.noRunSentinel
    #expect(s.beats.isEmpty)
    #expect(s.downbeats == .notAttempted)
    #expect(s.estimatedTempo == 0.0)
    #expect(s.confidence == 0.0)
    #expect(s.tempoAgreement == .notCompared)
    #expect(s.gridOrigin == nil)
    #expect(s.coverage == .analysisWindow)
  }

  // MARK: - AC2 / AC3: clamp tests, split per field-family

  /// `Double` fields (`presentationTime`, `estimatedTempo`) clamp non-finite
  /// and non-positive inputs to `0.0`; positive finite passes through.
  @Test(
    arguments: [
      (Double.nan, 0.0),
      (Double.infinity, 0.0),
      (-Double.infinity, 0.0),
      (-1.0, 0.0),
      (-120.0, 0.0),
      (0.0, 0.0),
      (120.0, 120.0),
    ] as [(Double, Double)])
  func doubleFieldsClamp(input: Double, expected: Double) {
    let ts = BeatTimestamp(presentationTime: input, confidence: 0.5, strength: 0.5)
    #expect(ts.presentationTime == expected)

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: input, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(grid.estimatedTempo == expected)
  }

  /// `Float` fields (`confidence`, `strength`) clamp to `[0, 1]` with non-finite
  /// mapped to `0.0`.
  @Test(
    arguments: [
      (Float.nan, Float(0.0)),
      (Float.infinity, Float(0.0)),
      (-Float.infinity, Float(0.0)),
      (Float(5.0), Float(1.0)),
      (Float(-2.0), Float(0.0)),
      (Float(0.5), Float(0.5)),
    ] as [(Float, Float)])
  func floatFieldsClamp(input: Float, expected: Float) {
    let ts = BeatTimestamp(presentationTime: 1.0, confidence: input, strength: input)
    #expect(ts.confidence == expected)
    #expect(ts.strength == expected)

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120.0, confidence: input,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(grid.confidence == expected)
  }

  /// Negative finite `estimatedTempo` is the "no estimate" sentinel `0.0`, while
  /// a high positive finite tempo passes through UNCLAMPED (no 60–200 range
  /// clamp at the type layer).
  @Test func estimatedTempoNegativeIsSentinelPositivePassesThrough() {
    let neg = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: -120.0, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(neg.estimatedTempo == 0.0)

    let high = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 250.0, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(high.estimatedTempo == 250.0)
  }

  /// `-0.0` inputs must canonicalize to `+0.0`, not leak the negative-zero bit
  /// pattern (asserted by bit pattern via `bitEqual`).
  @Test func clampCanonicalizesNegativeZero() {
    let ts = BeatTimestamp(presentationTime: -0.0, confidence: -0.0, strength: -0.0)
    #expect(NumericTestHelpers.bitEqual(ts.presentationTime, 0.0))
    #expect(NumericTestHelpers.bitEqual(ts.confidence, 0.0))
    #expect(NumericTestHelpers.bitEqual(ts.strength, 0.0))

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: -0.0, confidence: -0.0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(NumericTestHelpers.bitEqual(grid.estimatedTempo, 0.0))
    #expect(NumericTestHelpers.bitEqual(grid.confidence, 0.0))
  }

  // MARK: - AC4: synthesized Hashable/Equatable sound because clamping removed NaN

  @Test func reflexivityAndHashStabilityFromNaNInputs() {
    let ts = BeatTimestamp(
      presentationTime: .nan, confidence: .nan, strength: .nan)
    #expect(ts == ts)
    #expect(ts.hashValue == ts.hashValue)

    let ts2 = BeatTimestamp(
      presentationTime: .nan, confidence: .nan, strength: .nan)
    #expect(ts == ts2)
    #expect(ts.hashValue == ts2.hashValue)

    let grid = BeatGrid(
      beats: [ts], downbeats: .detected(beats: [ts]), estimatedTempo: .nan,
      confidence: .nan, tempoAgreement: .notCompared, gridOrigin: nil,
      coverage: .analysisWindow)
    #expect(grid == grid)
    #expect(grid.hashValue == grid.hashValue)

    let grid2 = BeatGrid(
      beats: [ts2], downbeats: .detected(beats: [ts2]), estimatedTempo: .nan,
      confidence: .nan, tempoAgreement: .notCompared, gridOrigin: nil,
      coverage: .analysisWindow)
    #expect(grid == grid2)
    #expect(grid.hashValue == grid2.hashValue)

    let dr1 = DownbeatResult.detected(beats: [ts])
    let dr2 = DownbeatResult.detected(beats: [ts2])
    #expect(dr1 == dr2)
    #expect(dr1.hashValue == dr2.hashValue)
  }

  // MARK: - AC5: exhaustive switch, no CaseIterable

  @Test func downbeatResultExhaustiveSwitchCoverage() {
    func classify(_ r: DownbeatResult) -> Int {
      switch r {
      case .notAttempted: return 0
      case .noneDetected: return 1
      case .detected: return 2
      }
    }
    #expect(classify(.notAttempted) == 0)
    #expect(classify(.noneDetected) == 1)
    #expect(classify(.detected(beats: [])) == 2)
  }

  // MARK: - AC6: Codable round-trip

  @Test(arguments: [0, 1, 200])
  func detectedRoundTrip(beatCount: Int) throws {
    let beats = Self.makeBeats(beatCount)
    let result = DownbeatResult.detected(beats: beats)
    let data = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(DownbeatResult.self, from: data)
    #expect(decoded == result)

    guard case .detected(let decodedBeats) = decoded else {
      Issue.record("expected .detected after round-trip")
      return
    }
    #expect(decodedBeats.count == beatCount)
    for (a, b) in zip(decodedBeats, beats) {
      #expect(NumericTestHelpers.bitEqual(a.presentationTime, b.presentationTime))
      #expect(NumericTestHelpers.bitEqual(a.confidence, b.confidence))
      #expect(NumericTestHelpers.bitEqual(a.strength, b.strength))
    }
  }

  @Test func beatGridRoundTrip() throws {
    let grids = [
      Self.noRunSentinel,
      BeatGrid(
        beats: Self.makeBeats(4), downbeats: .noneDetected, estimatedTempo: 174.0,
        confidence: 0.66, tempoAgreement: .disagree, gridOrigin: nil,
        coverage: .window(seconds: 60)),
      BeatGrid(
        beats: Self.makeBeats(8), downbeats: .detected(beats: Self.makeBeats(2)),
        estimatedTempo: 128.0, confidence: 0.95,
        tempoAgreement: .octaveEquivalent(factor: 2), gridOrigin: Self.sampleAnchor,
        coverage: .fullTrack),
    ]
    for grid in grids {
      let data = try JSONEncoder().encode(grid)
      let decoded = try JSONDecoder().decode(BeatGrid.self, from: data)
      #expect(decoded == grid)
      #expect(NumericTestHelpers.bitEqual(decoded.estimatedTempo, grid.estimatedTempo))
      #expect(NumericTestHelpers.bitEqual(decoded.confidence, grid.confidence))
      #expect(decoded.downbeats == grid.downbeats)
      #expect(decoded.tempoAgreement == grid.tempoAgreement)
      #expect(decoded.gridOrigin == grid.gridOrigin)
      #expect(decoded.coverage == grid.coverage)
    }
  }

  /// 4-value worst-case `Double` corpus pinned bit-exact on-toolchain (AC6).
  @Test(arguments: [
    0.1, Double.pi, Double.leastNormalMagnitude, Double.greatestFiniteMagnitude,
  ])
  func doubleBitExactCorpus(value: Double) throws {
    let ts = BeatTimestamp(presentationTime: value, confidence: 0.5, strength: 0.25)
    let tsData = try JSONEncoder().encode(ts)
    let tsBack = try JSONDecoder().decode(BeatTimestamp.self, from: tsData)
    #expect(NumericTestHelpers.bitEqual(tsBack.presentationTime, ts.presentationTime))

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: value, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    let gridData = try JSONEncoder().encode(grid)
    let gridBack = try JSONDecoder().decode(BeatGrid.self, from: gridData)
    #expect(NumericTestHelpers.bitEqual(gridBack.estimatedTempo, grid.estimatedTempo))
  }

  // MARK: - AC6: JSON wire-shape per DownbeatResult case

  @Test func downbeatResultJSONWireShapes() throws {
    func topLevel(_ r: DownbeatResult) throws -> [String: Any] {
      let data = try JSONEncoder().encode(r)
      let obj = try JSONSerialization.jsonObject(with: data)
      return try #require(obj as? [String: Any])
    }

    let na = try topLevel(.notAttempted)
    #expect(na.count == 1)
    let naPayload = try #require(na["notAttempted"] as? [String: Any])
    #expect(naPayload.isEmpty)

    let nd = try topLevel(.noneDetected)
    let ndPayload = try #require(nd["noneDetected"] as? [String: Any])
    #expect(ndPayload.isEmpty)

    let det = try topLevel(.detected(beats: Self.makeBeats(2)))
    let detPayload = try #require(det["detected"] as? [String: Any])
    let beatsArray = try #require(detPayload["beats"] as? [Any])
    #expect(beatsArray.count == 2)
    #expect(detPayload["_0"] == nil)
  }

  // MARK: - AC6: hostile-decode (finite out-of-range) re-clamps

  @Test func hostileJSONIsReclampedOnDecode() throws {
    let beatJSON = #"""
      {"presentationTime": -1.0, "confidence": 5.0, "strength": -2.0}
      """#
    let ts = try JSONDecoder().decode(
      BeatTimestamp.self, from: Data(beatJSON.utf8))
    #expect(ts.presentationTime == 0.0)
    #expect(ts.confidence == 1.0)
    #expect(ts.strength == 0.0)

    // Minimal grid JSON: omits the Story-8.5 optional-meaning fields
    // (tempoAgreement / gridOrigin / coverage), which decode leniently to their
    // "no information" defaults, while the required fields still re-clamp.
    let gridJSON = #"""
      {"beats": [], "downbeats": {"notAttempted": {}},
       "estimatedTempo": -120.0, "confidence": 5.0}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(gridJSON.utf8))
    #expect(grid.estimatedTempo == 0.0)
    #expect(grid.confidence == 1.0)
    #expect(grid.downbeats == .notAttempted)
    #expect(grid.tempoAgreement == .notCompared)
    #expect(grid.gridOrigin == nil)
    #expect(grid.coverage == .analysisWindow)
  }

  // MARK: - AC6: decode → encode → decode

  @Test func hostileDoubleRoundTrip() throws {
    let gridJSON = #"""
      {"beats": [{"presentationTime": -1.0, "confidence": 5.0, "strength": -2.0}],
       "downbeats": {"detected": {"beats":
         [{"presentationTime": 2.0, "confidence": -0.5, "strength": 3.0}]}},
       "estimatedTempo": -120.0, "confidence": 5.0}
      """#
    let first = try JSONDecoder().decode(BeatGrid.self, from: Data(gridJSON.utf8))
    let reEncoded = try JSONEncoder().encode(first)
    let second = try JSONDecoder().decode(BeatGrid.self, from: reEncoded)
    #expect(second == first)
    #expect(first.estimatedTempo == 0.0)
    #expect(first.beats.first?.confidence == 1.0)
    if case .detected(let inner) = first.downbeats {
      #expect(inner.first?.strength == 1.0)
      #expect(inner.first?.confidence == 0.0)
    } else {
      Issue.record("expected .detected downbeats")
    }
  }

  // MARK: - AC7: sentinel distinguishability

  @Test func sentinelsAreDistinguishable() {
    #expect(DownbeatResult.notAttempted != DownbeatResult.noneDetected)

    let noneGrid = BeatGrid(
      beats: [], downbeats: .noneDetected, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(Self.noRunSentinel != noneGrid)
    #expect(Self.noRunSentinel.downbeats == .notAttempted)
    #expect(noneGrid.downbeats == .noneDetected)
  }

  // MARK: - AC6: missing required key is a hard decode error (regression lock)

  @Test func beatTimestampMissingRequiredKeyThrowsKeyNotFound() throws {
    let json = #"{"presentationTime": 1.0, "strength": 0.5}"#  // no "confidence"
    let error = try #require(
      throws: DecodingError.self,
      performing: {
        _ = try JSONDecoder().decode(BeatTimestamp.self, from: Data(json.utf8))
      })
    guard case .keyNotFound(let key, _) = error else {
      Issue.record("expected .keyNotFound, got \(error)")
      return
    }
    #expect(key.stringValue == "confidence")
  }

  /// `estimatedTempo` is required; omitting it must throw `keyNotFound`. (The
  /// Story-8.5 fields are deliberately NOT in this set — they default leniently.)
  @Test func beatGridMissingRequiredKeyThrowsKeyNotFound() throws {
    let json = #"""
      {"beats": [], "downbeats": {"notAttempted": {}}, "confidence": 0.5}
      """#  // no "estimatedTempo"
    let error = try #require(
      throws: DecodingError.self,
      performing: {
        _ = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
      })
    guard case .keyNotFound(let key, _) = error else {
      Issue.record("expected .keyNotFound, got \(error)")
      return
    }
    #expect(key.stringValue == "estimatedTempo")
  }

  // MARK: - Story 8.5: TempoAgreement

  @Test func tempoAgreementDescriptions() {
    #expect(TempoAgreement.notCompared.description == "notCompared")
    #expect(TempoAgreement.agree.description == "agree")
    #expect(TempoAgreement.disagree.description == "disagree")
    #expect(
      TempoAgreement.octaveEquivalent(factor: 2).description
        == "octaveEquivalent(factor: 2)")
  }

  @Test func tempoAgreementHashableDistinguishesFactor() {
    let set: Set<TempoAgreement> = [
      .notCompared, .agree, .disagree,
      .octaveEquivalent(factor: 2), .octaveEquivalent(factor: -2),
    ]
    #expect(set.count == 5)
    #expect(TempoAgreement.octaveEquivalent(factor: 2) != .octaveEquivalent(factor: -2))
    #expect(TempoAgreement.octaveEquivalent(factor: 2) == .octaveEquivalent(factor: 2))
  }

  @Test(arguments: [
    TempoAgreement.notCompared, .agree, .disagree,
    .octaveEquivalent(factor: 2), .octaveEquivalent(factor: -2),
  ])
  func tempoAgreementRoundTrips(value: TempoAgreement) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(TempoAgreement.self, from: data)
    #expect(decoded == value)
  }

  /// The associated-value case encodes with a LABELED payload (`{"octaveEquivalent":
  /// {"factor": 2}}`), not a positional `_0` (SE-0295 — mirrors `DownbeatResult.detected`).
  @Test func tempoAgreementOctaveWireShapeIsLabeled() throws {
    let data = try JSONEncoder().encode(TempoAgreement.octaveEquivalent(factor: 2))
    let obj = try #require(
      try JSONSerialization.jsonObject(with: data) as? [String: Any])
    let payload = try #require(obj["octaveEquivalent"] as? [String: Any])
    #expect(payload["factor"] as? Int == 2)
    #expect(payload["_0"] == nil)
  }

  // MARK: - Story 8.5: BeatGridAnchor

  @Test func beatGridAnchorClampsEveryField() {
    let a = BeatGridAnchor(
      beatIndex: -7, presentationTime: -3.0, confidence: 9.0, strength: .nan,
      source: .strongestBeat)
    #expect(a.beatIndex == 0)
    #expect(a.presentationTime == 0.0)
    #expect(a.confidence == 1.0)
    #expect(a.strength == 0.0)
    #expect(a.source == .strongestBeat)
  }

  @Test func beatGridAnchorRoundTripsAndReclampsHostileJSON() throws {
    let a = BeatGridAnchor(
      beatIndex: 3, presentationTime: 2.5, confidence: 0.7, strength: 0.4,
      source: .firstBeat)
    let data = try JSONEncoder().encode(a)
    #expect(try JSONDecoder().decode(BeatGridAnchor.self, from: data) == a)

    let hostile = #"""
      {"beatIndex": -2, "presentationTime": -1.0, "confidence": 9.0,
       "strength": -1.0, "source": "downbeat"}
      """#
    let decoded = try JSONDecoder().decode(BeatGridAnchor.self, from: Data(hostile.utf8))
    #expect(decoded.beatIndex == 0)
    #expect(decoded.presentationTime == 0.0)
    #expect(decoded.confidence == 1.0)
    #expect(decoded.strength == 0.0)
    #expect(decoded.source == .downbeat)
  }

  /// `BeatGridAnchorSource` is `String`-backed → its `Codable` wire shape is a
  /// bare string, not an SE-0295 single-key object.
  @Test func beatGridAnchorSourceEncodesAsBareString() throws {
    let data = try JSONEncoder().encode(BeatGridAnchorSource.medianConsistentBeat)
    // A bare quoted string `"medianConsistentBeat"`, not `{"medianConsistentBeat":{}}`.
    #expect(data == Data(#""medianConsistentBeat""#.utf8))
    #expect(BeatGridAnchorSource.firstBeat.rawValue == "firstBeat")
    #expect(BeatGridAnchorSource.strongestBeat.rawValue == "strongestBeat")
    #expect(BeatGridAnchorSource.downbeat.rawValue == "downbeat")
  }

  // MARK: - Story 8.5: BeatGridCoverage sanitization (NaN-free → Hashable)

  /// A degenerate `.window` (non-finite, ≤ 0, or absurd) IS `.analysisWindow` by
  /// the type's own equality, so a `NaN` second-count can never be a distinct,
  /// unsound `Hashable` value — the enum analogue of the float-clamp doctrine.
  @Test(arguments: [
    Double.nan, .infinity, -.infinity, 0.0, -5.0, 1.0e12,
  ])
  func degenerateWindowFoldsToAnalysisWindow(seconds: Double) {
    let cov = BeatGridCoverage.window(seconds: seconds)
    #expect(cov.sanitized == .analysisWindow)
    #expect(cov == .analysisWindow)
    #expect(cov.hashValue == BeatGridCoverage.analysisWindow.hashValue)
    // BeatGrid records the sanitized form.
    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: cov)
    #expect(grid.coverage == .analysisWindow)
  }

  @Test func validWindowIsPreservedAndDistinct() {
    let w60 = BeatGridCoverage.window(seconds: 60)
    #expect(w60.sanitized == w60)
    #expect(w60 != .analysisWindow)
    #expect(w60 != .fullTrack)
    #expect(w60 != BeatGridCoverage.window(seconds: 30))
    #expect(BeatGridCoverage.window(seconds: 60) == BeatGridCoverage.window(seconds: 60))
  }

  @Test(arguments: [
    BeatGridCoverage.analysisWindow, .window(seconds: 45.5), .fullTrack,
  ])
  func beatGridCoverageRoundTrips(value: BeatGridCoverage) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(BeatGridCoverage.self, from: data)
    #expect(decoded == value)
  }

  @Test func beatGridCoverageDescriptions() {
    #expect(BeatGridCoverage.analysisWindow.description == "analysisWindow")
    #expect(BeatGridCoverage.fullTrack.description == "fullTrack")
    #expect(BeatGridCoverage.window(seconds: 60).description == "window(60.0s)")
    // Degenerate window renders as its sanitized meaning.
    #expect(BeatGridCoverage.window(seconds: .nan).description == "analysisWindow")
  }

  // MARK: - Story 8.5: gridOrigin beatIndex invariant (cross-field hardening)

  /// `gridOrigin` invariant: a non-nil anchor always indexes a real beat. An
  /// anchor whose `beatIndex >= beats.count` (a hostile `Codable` payload or a
  /// manual misconstruction — ``BeatGridAnchor`` clamps `≥ 0` but cannot know
  /// `beats.count`) is dropped to `nil` at construction, so a consumer can do
  /// `beats[gridOrigin!.beatIndex]` without its own bounds check.
  @Test func outOfRangeGridOriginIsDroppedToNil() throws {
    // Manual misconstruction: 2 beats but the anchor points at index 5.
    let bad = BeatGrid(
      beats: Self.makeBeats(2), downbeats: .notAttempted, estimatedTempo: 120,
      confidence: 0.5, tempoAgreement: .notCompared,
      gridOrigin: BeatGridAnchor(
        beatIndex: 5, presentationTime: 1, confidence: 0.5, strength: 0.5,
        source: .strongestBeat),
      coverage: .analysisWindow)
    #expect(bad.gridOrigin == nil)

    // Empty beats + any anchor → nil (no beat to index).
    let empty = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: Self.sampleAnchor,
      coverage: .analysisWindow)
    #expect(empty.gridOrigin == nil)

    // In-range anchor is preserved (sampleAnchor.beatIndex 2 < 8).
    let valid = BeatGrid(
      beats: Self.makeBeats(8), downbeats: .notAttempted, estimatedTempo: 120,
      confidence: 0.5, tempoAgreement: .notCompared, gridOrigin: Self.sampleAnchor,
      coverage: .analysisWindow)
    #expect(valid.gridOrigin == Self.sampleAnchor)

    // Hostile JSON: out-of-range beatIndex on decode → nil, beats intact.
    let json = #"""
      {"beats": [{"presentationTime": 0.5, "confidence": 0.9, "strength": 0.7}],
       "downbeats": {"notAttempted": {}}, "estimatedTempo": 120, "confidence": 0.5,
       "gridOrigin": {"beatIndex": 999, "presentationTime": 1.0, "confidence": 0.8,
                      "strength": 0.6, "source": "medianConsistentBeat"}}
      """#
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(decoded.gridOrigin == nil)
    #expect(decoded.beats.count == 1)
    // A consumer's documented `beats[beatIndex]` access is now safe by construction.
    if let origin = decoded.gridOrigin {
      #expect(origin.beatIndex < decoded.beats.count)
    }
  }
}
