//
//  BeatGridTypesTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.3 tests for the types-only beat-grid public surface:
//  BeatTimestamp, DownbeatResult, BeatGrid — shape, clamping, synthesized
//  Hashable soundness, and Codable round-trip / hostile-decode behavior.
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

  /// The documented canonical "no beat-grid run" sentinel (AC7).
  private static let noRunSentinel = BeatGrid(
    beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
    tempoAgreedWithBPMStage: nil)

  // MARK: - AC1: shapes & sentinels

  @Test func typesConstructWithDocumentedShapes() {
    let ts = BeatTimestamp(presentationTime: 1.0, confidence: 0.8, strength: 0.5)
    #expect(ts.presentationTime == 1.0)
    #expect(ts.confidence == 0.8)
    #expect(ts.strength == 0.5)

    let grid = BeatGrid(
      beats: [ts], downbeats: .detected(beats: [ts]), estimatedTempo: 128.0,
      confidence: 0.9, tempoAgreedWithBPMStage: true)
    #expect(grid.beats.count == 1)
    #expect(grid.estimatedTempo == 128.0)
    #expect(grid.confidence == 0.9)
    #expect(grid.tempoAgreedWithBPMStage == true)
  }

  @Test func downbeatResultHasThreeCases() {
    // Exercise each case constructs and round-trips through description.
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
    #expect(s.tempoAgreedWithBPMStage == nil)
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
      tempoAgreedWithBPMStage: nil)
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
      tempoAgreedWithBPMStage: nil)
    #expect(grid.confidence == expected)
  }

  /// DD #8: negative finite `estimatedTempo` is the "no estimate" sentinel `0.0`,
  /// while a high positive finite tempo passes through UNCLAMPED (no 60–200 range
  /// clamp at the type layer).
  @Test func estimatedTempoNegativeIsSentinelPositivePassesThrough() {
    let neg = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: -120.0, confidence: 0.5,
      tempoAgreedWithBPMStage: nil)
    #expect(neg.estimatedTempo == 0.0)

    let high = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 250.0, confidence: 0.5,
      tempoAgreedWithBPMStage: nil)
    #expect(high.estimatedTempo == 250.0)
  }

  /// `-0.0` inputs must canonicalize to `+0.0`, not leak the negative-zero bit
  /// pattern. `== 0.0` cannot catch this (`-0.0 == 0.0` is true), so assert by
  /// bit pattern via `bitEqual`. `clampUnit`'s `min(max(-0.0, 0.0), 1.0)` is
  /// exactly subtle enough (signed-zero min/max behavior) that this lock earns
  /// its keep.
  @Test func clampCanonicalizesNegativeZero() {
    let ts = BeatTimestamp(presentationTime: -0.0, confidence: -0.0, strength: -0.0)
    #expect(NumericTestHelpers.bitEqual(ts.presentationTime, 0.0))
    #expect(NumericTestHelpers.bitEqual(ts.confidence, 0.0))
    #expect(NumericTestHelpers.bitEqual(ts.strength, 0.0))

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: -0.0, confidence: -0.0,
      tempoAgreedWithBPMStage: nil)
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
      confidence: .nan, tempoAgreedWithBPMStage: nil)
    #expect(grid == grid)
    #expect(grid.hashValue == grid.hashValue)

    let grid2 = BeatGrid(
      beats: [ts2], downbeats: .detected(beats: [ts2]), estimatedTempo: .nan,
      confidence: .nan, tempoAgreedWithBPMStage: nil)
    #expect(grid == grid2)
    #expect(grid.hashValue == grid2.hashValue)

    // Recursively through the .detected payload.
    let dr1 = DownbeatResult.detected(beats: [ts])
    let dr2 = DownbeatResult.detected(beats: [ts2])
    #expect(dr1 == dr2)
    #expect(dr1.hashValue == dr2.hashValue)
  }

  // MARK: - AC5: exhaustive switch, no CaseIterable

  /// Compile-tripwire: this switch has no `default:`, so a future added case
  /// (e.g. `.ambiguous`) fails to compile here rather than silently passing.
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
        confidence: 0.66, tempoAgreedWithBPMStage: false),
      BeatGrid(
        beats: Self.makeBeats(8), downbeats: .detected(beats: Self.makeBeats(2)),
        estimatedTempo: 128.0, confidence: 0.95, tempoAgreedWithBPMStage: true),
    ]
    for grid in grids {
      let data = try JSONEncoder().encode(grid)
      let decoded = try JSONDecoder().decode(BeatGrid.self, from: data)
      #expect(decoded == grid)
      #expect(NumericTestHelpers.bitEqual(decoded.estimatedTempo, grid.estimatedTempo))
      #expect(NumericTestHelpers.bitEqual(decoded.confidence, grid.confidence))
      #expect(decoded.downbeats == grid.downbeats)
      #expect(decoded.tempoAgreedWithBPMStage == grid.tempoAgreedWithBPMStage)
    }
  }

  /// 4-value worst-case `Double` corpus pinned bit-exact on-toolchain (AC6).
  @Test(arguments: [
    0.1, Double.pi, Double.leastNormalMagnitude, Double.greatestFiniteMagnitude,
  ])
  func doubleBitExactCorpus(value: Double) throws {
    // All four are positive finite, so they pass the clamp unchanged and must
    // round-trip bit-for-bit through Foundation's shortest-decimal description.
    let ts = BeatTimestamp(presentationTime: value, confidence: 0.5, strength: 0.25)
    let tsData = try JSONEncoder().encode(ts)
    let tsBack = try JSONDecoder().decode(BeatTimestamp.self, from: tsData)
    #expect(NumericTestHelpers.bitEqual(tsBack.presentationTime, ts.presentationTime))

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: value, confidence: 0.5,
      tempoAgreedWithBPMStage: nil)
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

    // .notAttempted → {"notAttempted":{}} — empty object, NOT a bare string.
    let na = try topLevel(.notAttempted)
    #expect(na.count == 1)
    let naPayload = try #require(na["notAttempted"] as? [String: Any])
    #expect(naPayload.isEmpty)

    // .noneDetected → {"noneDetected":{}}.
    let nd = try topLevel(.noneDetected)
    let ndPayload = try #require(nd["noneDetected"] as? [String: Any])
    #expect(ndPayload.isEmpty)

    // .detected(beats:) → {"detected":{"beats":[…]}} (labeled payload, DD #9).
    let det = try topLevel(.detected(beats: Self.makeBeats(2)))
    let detPayload = try #require(det["detected"] as? [String: Any])
    let beatsArray = try #require(detPayload["beats"] as? [Any])
    #expect(beatsArray.count == 2)
    // No positional "_0" key leaked.
    #expect(detPayload["_0"] == nil)
  }

  // MARK: - AC6: hostile-decode (finite out-of-range) re-clamps

  @Test func hostileJSONIsReclampedOnDecode() throws {
    // Hand-authored payload with finite-but-out-of-range scalars.
    let beatJSON = #"""
      {"presentationTime": -1.0, "confidence": 5.0, "strength": -2.0}
      """#
    let ts = try JSONDecoder().decode(
      BeatTimestamp.self, from: Data(beatJSON.utf8))
    #expect(ts.presentationTime == 0.0)
    #expect(ts.confidence == 1.0)
    #expect(ts.strength == 0.0)

    let gridJSON = #"""
      {"beats": [], "downbeats": {"notAttempted": {}},
       "estimatedTempo": -120.0, "confidence": 5.0}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(gridJSON.utf8))
    #expect(grid.estimatedTempo == 0.0)
    #expect(grid.confidence == 1.0)
    #expect(grid.downbeats == .notAttempted)
    #expect(grid.tempoAgreedWithBPMStage == nil)
  }

  // MARK: - AC6: decode → encode → decode (catches encode-side keys decoder ignores)

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
    // The clamp invariant held on the first decode and survives the cycle.
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
      tempoAgreedWithBPMStage: nil)
    #expect(Self.noRunSentinel != noneGrid)
    #expect(Self.noRunSentinel.downbeats == .notAttempted)
    #expect(noneGrid.downbeats == .noneDetected)
  }

  // MARK: - AC6: missing required key is a hard decode error (regression lock)

  /// `confidence` is decoded with non-optional `decode`, so omitting it must
  /// throw `keyNotFound` — not silently default. Locks against a
  /// `decodeIfPresent ?? 0` regression that would bypass the clamp contract.
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

  /// `estimatedTempo` (the float field most likely to regress to `?? 0`) is
  /// required; omitting it must throw `keyNotFound`.
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
}
