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

  /// Builds a representative `DownbeatEstimate` carrying `n` downbeat beats
  /// (Story 8.5a: the `.detected` payload is a `DownbeatEstimate`, not raw beats).
  private static func makeEstimate(_ n: Int, phaseIndex: Int = 0) -> DownbeatEstimate {
    DownbeatEstimate(
      beats: makeBeats(n),
      meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
      confidence: 0.8,
      phaseIndex: phaseIndex)
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
      beats: [ts, ts, ts],
      downbeats: .detected(estimate: Self.makeEstimate(1)), estimatedTempo: 128.0,
      confidence: 0.9, tempoAgreement: .agree, gridOrigin: Self.sampleAnchor,
      coverage: .fullTrack)
    #expect(grid.beats.count == 3)
    #expect(grid.estimatedTempo == 128.0)
    #expect(grid.confidence == 0.9)
    #expect(grid.tempoAgreement == .agree)
    // gridOrigin is rebuilt from beats[2] (== ts) — beatIndex + source preserved, the
    // float fields taken from the indexed beat (sampleAnchor's strength 0.6 → ts's 0.5).
    #expect(
      grid.gridOrigin
        == BeatGridAnchor(
          beatIndex: 2, presentationTime: ts.presentationTime, confidence: ts.confidence,
          strength: ts.strength, source: Self.sampleAnchor.source))
    #expect(grid.coverage == .fullTrack)
  }

  @Test func downbeatResultHasThreeCases() {
    #expect(DownbeatResult.notAttempted.description == "notAttempted")
    #expect(DownbeatResult.noneDetected.description == "noneDetected")
    #expect(
      DownbeatResult.detected(estimate: Self.makeEstimate(3, phaseIndex: 2)).description
        == "detected(3 downbeats, phase 2)")
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

    // NaN confidence on the estimate must clamp finite (Hashable soundness).
    let meter = MeterEstimate(beatsPerBar: 4, source: .assumed)
    let est1 = DownbeatEstimate(beats: [ts], meter: meter, confidence: .nan, phaseIndex: 0)
    let est2 = DownbeatEstimate(beats: [ts2], meter: meter, confidence: .nan, phaseIndex: 0)
    #expect(est1 == est2)
    #expect(est1.hashValue == est2.hashValue)

    let grid = BeatGrid(
      beats: [ts], downbeats: .detected(estimate: est1), estimatedTempo: .nan,
      confidence: .nan, tempoAgreement: .notCompared, gridOrigin: nil,
      coverage: .analysisWindow)
    #expect(grid == grid)
    #expect(grid.hashValue == grid.hashValue)

    let grid2 = BeatGrid(
      beats: [ts2], downbeats: .detected(estimate: est2), estimatedTempo: .nan,
      confidence: .nan, tempoAgreement: .notCompared, gridOrigin: nil,
      coverage: .analysisWindow)
    #expect(grid == grid2)
    #expect(grid.hashValue == grid2.hashValue)

    let dr1 = DownbeatResult.detected(estimate: est1)
    let dr2 = DownbeatResult.detected(estimate: est2)
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
    #expect(classify(.detected(estimate: Self.makeEstimate(0))) == 2)
  }

  // MARK: - AC6: Codable round-trip

  /// Only structurally-USABLE payloads round-trip as `.detected`; a `0`-beat (or
  /// otherwise invalid) payload normalizes to `.noneDetected` on decode — see
  /// ``decodedInvalidDetectedNormalizesToNoneDetected``.
  @Test(arguments: [1, 200])
  func detectedRoundTrip(beatCount: Int) throws {
    let beats = Self.makeBeats(beatCount)
    let estimate = DownbeatEstimate(
      beats: beats, meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
      confidence: 0.73, phaseIndex: 1)
    let result = DownbeatResult.detected(estimate: estimate)
    let data = try JSONEncoder().encode(result)
    let decoded = try JSONDecoder().decode(DownbeatResult.self, from: data)
    #expect(decoded == result)

    guard case .detected(let decodedEstimate) = decoded else {
      Issue.record("expected .detected after round-trip")
      return
    }
    #expect(decodedEstimate.beats.count == beatCount)
    #expect(decodedEstimate.meter == MeterEstimate(beatsPerBar: 4, source: .assumed))
    #expect(decodedEstimate.phaseIndex == 1)
    #expect(NumericTestHelpers.bitEqual(decodedEstimate.confidence, 0.73))
    for (a, b) in zip(decodedEstimate.beats, beats) {
      #expect(NumericTestHelpers.bitEqual(a.presentationTime, b.presentationTime))
      #expect(NumericTestHelpers.bitEqual(a.confidence, b.confidence))
      #expect(NumericTestHelpers.bitEqual(a.strength, b.strength))
    }
  }

  // MARK: - AC6: structurally-invalid decoded .detected normalizes to .noneDetected

  /// A stale or tampered cache is the only source of a structurally-invalid
  /// `.detected` (the estimator never emits one). `DownbeatResult.init(from:)`
  /// normalizes such a payload to `.noneDetected` rather than surface an unusable
  /// "success" (Codex-adjudicated decode doctrine, code review 2026-06-14). A VALID
  /// `.detected` still round-trips exactly.
  @Test func decodedInvalidDetectedNormalizesToNoneDetected() throws {
    func decode(_ json: String) throws -> DownbeatResult {
      try JSONDecoder().decode(DownbeatResult.self, from: Data(json.utf8))
    }

    // (1) empty beats — no bar-extrapolation anchor.
    let emptyBeats = #"""
      {"detected": {"estimate": {"beats": [],
       "meter": {"beatsPerBar": 4, "source": "assumed"},
       "confidence": 0.8, "phaseIndex": 0}}}
      """#
    #expect(try decode(emptyBeats) == .noneDetected)

    // (2) beatsPerBar < 1 — degenerate meter.
    let badMeter = #"""
      {"detected": {"estimate": {"beats": [
       {"presentationTime": 1.0, "confidence": 0.8, "strength": 0.6}],
       "meter": {"beatsPerBar": 0, "source": "assumed"},
       "confidence": 0.8, "phaseIndex": 0}}}
      """#
    #expect(try decode(badMeter) == .noneDetected)

    // (3) phaseIndex out of range (>= beatsPerBar).
    let badPhase = #"""
      {"detected": {"estimate": {"beats": [
       {"presentationTime": 1.0, "confidence": 0.8, "strength": 0.6}],
       "meter": {"beatsPerBar": 4, "source": "assumed"},
       "confidence": 0.8, "phaseIndex": 4}}}
      """#
    #expect(try decode(badPhase) == .noneDetected)

    // A structurally-valid .detected is preserved (in-range phase, non-empty beats).
    let valid = #"""
      {"detected": {"estimate": {"beats": [
       {"presentationTime": 1.0, "confidence": 0.8, "strength": 0.6}],
       "meter": {"beatsPerBar": 4, "source": "assumed"},
       "confidence": 0.8, "phaseIndex": 2}}}
      """#
    guard case .detected(let est) = try decode(valid) else {
      Issue.record("a structurally-valid .detected must be preserved on decode")
      return
    }
    #expect(est.phaseIndex == 2)
    #expect(est.beats.count == 1)
  }

  @Test func beatGridRoundTrip() throws {
    let grids = [
      Self.noRunSentinel,
      BeatGrid(
        beats: Self.makeBeats(4), downbeats: .noneDetected, estimatedTempo: 174.0,
        confidence: 0.66, tempoAgreement: .disagree, gridOrigin: nil,
        coverage: .window(seconds: 60)),
      BeatGrid(
        beats: Self.makeBeats(8),
        downbeats: .detected(estimate: Self.makeEstimate(2)),
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

    // `.detected` carries a LABELED `estimate:` payload (`{"detected":{"estimate":
    // {…}}}`), not a positional `_0` (SE-0295 / DD #3). The downbeat beats live
    // one level deeper, inside the estimate.
    let det = try topLevel(.detected(estimate: Self.makeEstimate(2, phaseIndex: 3)))
    let detPayload = try #require(det["detected"] as? [String: Any])
    #expect(detPayload["_0"] == nil)
    let estimatePayload = try #require(detPayload["estimate"] as? [String: Any])
    let beatsArray = try #require(estimatePayload["beats"] as? [Any])
    #expect(beatsArray.count == 2)
    #expect(estimatePayload["phaseIndex"] as? Int == 3)
    #expect((estimatePayload["meter"] as? [String: Any]) != nil)
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
    // The `.detected` payload is now a labeled `estimate` object whose own
    // `confidence` AND nested beats re-clamp on decode (DownbeatEstimate +
    // BeatTimestamp both route hostile JSON through their clamping inits).
    let gridJSON = #"""
      {"beats": [{"presentationTime": -1.0, "confidence": 5.0, "strength": -2.0}],
       "downbeats": {"detected": {"estimate": {
         "beats": [{"presentationTime": 2.0, "confidence": -0.5, "strength": 3.0}],
         "meter": {"beatsPerBar": 4, "source": "assumed"},
         "confidence": 9.0, "phaseIndex": 0}}},
       "estimatedTempo": -120.0, "confidence": 5.0}
      """#
    let first = try JSONDecoder().decode(BeatGrid.self, from: Data(gridJSON.utf8))
    let reEncoded = try JSONEncoder().encode(first)
    let second = try JSONDecoder().decode(BeatGrid.self, from: reEncoded)
    #expect(second == first)
    #expect(first.estimatedTempo == 0.0)
    #expect(first.beats.first?.confidence == 1.0)
    if case .detected(let estimate) = first.downbeats {
      #expect(estimate.confidence == 1.0)  // hostile 9.0 clamped to [0, 1]
      #expect(estimate.beats.first?.strength == 1.0)
      #expect(estimate.beats.first?.confidence == 0.0)
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

  /// The no-payload cases encode with the SE-0295 empty-object shape (`{"agree":{}}`),
  /// matching the synthesized conformance the hand-written `encode(to:)` replaces.
  @Test(arguments: [
    (TempoAgreement.notCompared, "notCompared"), (.agree, "agree"), (.disagree, "disagree"),
  ])
  func tempoAgreementNoPayloadWireShapes(value: TempoAgreement, key: String) throws {
    let data = try JSONEncoder().encode(value)
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(obj.count == 1)
    #expect((obj[key] as? [String: Any])?.isEmpty == true)
  }

  /// An out-of-range decoded `octaveEquivalent` factor folds to `.disagree` — only ±2
  /// are produced, so anything else is a stale/tampered cache that must NOT auto-sync.
  @Test(arguments: ["4", "0", "-3", "1", "999"])
  func hostileOctaveFactorDecodesToDisagree(factor: String) throws {
    let json = "{\"octaveEquivalent\":{\"factor\": \(factor)}}"
    let decoded = try JSONDecoder().decode(TempoAgreement.self, from: Data(json.utf8))
    #expect(decoded == .disagree)
  }

  /// The valid ±2 factors survive decode unchanged (the fold does not over-reach).
  @Test(arguments: [2, -2])
  func validOctaveFactorDecodesUnchanged(factor: Int) throws {
    let json = "{\"octaveEquivalent\":{\"factor\": \(factor)}}"
    let decoded = try JSONDecoder().decode(TempoAgreement.self, from: Data(json.utf8))
    #expect(decoded == .octaveEquivalent(factor: factor))
  }

  /// A `BeatGrid` whose decoded `tempoAgreement` carries a hostile factor inherits the
  /// fold — the fix lives on the type, so every decode site is protected for free.
  @Test func beatGridNestedHostileOctaveFactorFoldsToDisagree() throws {
    let json = #"""
      {"beats": [], "downbeats": {"notAttempted": {}}, "estimatedTempo": 120,
       "confidence": 0.5, "tempoAgreement": {"octaveEquivalent": {"factor": 7}},
       "coverage": {"analysisWindow": {}}}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(grid.tempoAgreement == .disagree)
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

  /// Each case encodes with the exact SE-0295 single-key object shape the synthesized
  /// conformance would — the hand-written `encode(to:)` must not drift the wire format.
  @Test func beatGridCoverageWireShapesAreLabeled() throws {
    func object(_ value: BeatGridCoverage) throws -> [String: Any] {
      let data = try JSONEncoder().encode(value)
      return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
    let aw = try object(.analysisWindow)
    #expect(aw.count == 1)
    #expect((aw["analysisWindow"] as? [String: Any])?.isEmpty == true)

    let ft = try object(.fullTrack)
    #expect(ft.count == 1)
    #expect((ft["fullTrack"] as? [String: Any])?.isEmpty == true)

    let payload = try #require(try object(.window(seconds: 45.5))["window"] as? [String: Any])
    #expect(payload["seconds"] as? Double == 45.5)
    #expect(payload["_0"] == nil)
  }

  /// A degenerate decoded `.window` (absurd / ≤ 0) decodes to `.analysisWindow`: the
  /// custom `init(from:)` stores the ``sanitized`` form, closing the synthesized-Codable
  /// hole that would otherwise reconstruct an unsound value from persistence.
  @Test(arguments: ["1e300", "-5", "0"])
  func degenerateWindowJSONDecodesToAnalysisWindow(seconds: String) throws {
    let json = "{\"window\":{\"seconds\": \(seconds)}}"
    let decoded = try JSONDecoder().decode(BeatGridCoverage.self, from: Data(json.utf8))
    #expect(decoded == .analysisWindow)
  }

  /// Encoding an in-memory `.window(.nan)` emits the `analysisWindow` shape — a
  /// degenerate window can never be persisted.
  @Test func nanWindowEncodesAsAnalysisWindow() throws {
    let data = try JSONEncoder().encode(BeatGridCoverage.window(seconds: .nan))
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(obj.count == 1)
    #expect(obj["analysisWindow"] != nil)
    #expect(obj["window"] == nil)
  }

  // MARK: - Decode hardening: fold an unreadable case payload to the safe sentinel

  /// A recognized `.window` case whose `seconds` is unreadable (missing / null / wrong-type
  /// / non-object payload) folds to `.analysisWindow`, never throws (tamper-resistant
  /// decode). Each variant hits a different `nestedContainer`/`decode` failure path.
  @Test(arguments: [
    #"{"window":{}}"#, #"{"window":{"seconds":"x"}}"#, #"{"window":{"seconds":null}}"#,
    #"{"window":5}"#, #"{"window":[]}"#, #"{"window":null}"#,
  ])
  func unreadableWindowPayloadDecodesToAnalysisWindow(json: String) throws {
    #expect(
      try JSONDecoder().decode(BeatGridCoverage.self, from: Data(json.utf8)) == .analysisWindow)
  }

  /// A recognized `.octaveEquivalent` case whose `factor` is unreadable folds to `.disagree`.
  @Test(arguments: [
    #"{"octaveEquivalent":{}}"#, #"{"octaveEquivalent":{"factor":"x"}}"#,
    #"{"octaveEquivalent":{"factor":null}}"#, #"{"octaveEquivalent":5}"#,
    #"{"octaveEquivalent":null}"#,
  ])
  func unreadableOctavePayloadDecodesToDisagree(json: String) throws {
    #expect(try JSONDecoder().decode(TempoAgreement.self, from: Data(json.utf8)) == .disagree)
  }

  /// A recognized `.detected` case whose `estimate` is unreadable OR structurally invalid
  /// folds to `.noneDetected` (the `{"beats":[]}` case proves `try? decode` also catches the
  /// estimate's own internal `keyNotFound`).
  @Test(arguments: [
    #"{"detected":{}}"#, #"{"detected":{"estimate":"x"}}"#, #"{"detected":{"estimate":[]}}"#,
    #"{"detected":{"estimate":null}}"#, #"{"detected":{"estimate":{"beats":[]}}}"#,
    #"{"detected":null}"#,
  ])
  func unreadableDetectedPayloadDecodesToNoneDetected(json: String) throws {
    #expect(try JSONDecoder().decode(DownbeatResult.self, from: Data(json.utf8)) == .noneDetected)
  }

  /// A `BeatGrid` whose `tempoAgreement` carries an unreadable octaveEquivalent payload
  /// inherits the fold (the fix lives on the type, protecting every decode site).
  @Test func beatGridNestedUnreadableOctaveFoldsToDisagree() throws {
    let json = #"""
      {"beats": [], "downbeats": {"notAttempted": {}}, "estimatedTempo": 120,
       "confidence": 0.5, "tempoAgreement": {"octaveEquivalent": {}},
       "coverage": {"analysisWindow": {}}}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(grid.tempoAgreement == .disagree)
  }

  /// The retained schema boundary: a no-recognized-key object, or a non-object top-level
  /// value, still THROWS (the cache is not this type at all) — locked so a future change
  /// cannot silently broaden the fold.
  @Test func unrecognizedKeyOrNonObjectStillThrows() {
    func threw<T: Decodable>(_: T.Type, _ json: String) -> Bool {
      do {
        _ = try JSONDecoder().decode(T.self, from: Data(json.utf8))
        return false
      } catch { return true }
    }
    // No recognized case key.
    #expect(threw(TempoAgreement.self, "{}"))
    #expect(threw(BeatGridCoverage.self, #"{"bogus":{}}"#))
    #expect(threw(DownbeatResult.self, #"{"future":{}}"#))
    // Non-object top-level value (container(keyedBy:) throws).
    #expect(threw(TempoAgreement.self, "5"))
    #expect(threw(BeatGridCoverage.self, "[]"))
    #expect(threw(DownbeatResult.self, #""x""#))
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

    // In-range anchor (sampleAnchor.beatIndex 2 < 8) is REBUILT from beats[2]
    // (time/confidence/strength), with beatIndex + source preserved — so it agrees with
    // the indexed beat even though sampleAnchor's own conf/strength differ.
    let beats8 = Self.makeBeats(8)
    let valid = BeatGrid(
      beats: beats8, downbeats: .notAttempted, estimatedTempo: 120,
      confidence: 0.5, tempoAgreement: .notCompared, gridOrigin: Self.sampleAnchor,
      coverage: .analysisWindow)
    let validAnchor = try #require(valid.gridOrigin)
    #expect(validAnchor.beatIndex == 2)
    #expect(validAnchor.source == Self.sampleAnchor.source)
    #expect(validAnchor.presentationTime == beats8[2].presentationTime)
    #expect(validAnchor.confidence == beats8[2].confidence)
    #expect(validAnchor.strength == beats8[2].strength)

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
    if let origin = decoded.gridOrigin, let idx = origin.beatIndex {
      #expect(idx < decoded.beats.count)
    }
  }

  /// A4: an in-range hostile `gridOrigin` (wrong time/conf/strength, and a `.downbeat`
  /// source while downbeats are NOT detected) is rebuilt from `beats[beatIndex]` —
  /// `beatIndex`/`source` preserved — so the anchor agrees with its beat. `source`
  /// stays untrusted: `.downbeat` here does not imply usable downbeats (the dual-gate).
  @Test func inRangeGridOriginRebuiltFromBeatPreservingSource() throws {
    let beats = Self.makeBeats(8)
    let hostile = BeatGridAnchor(
      beatIndex: 0, presentationTime: 999, confidence: 0.1, strength: 0.05,
      source: .downbeat)
    let grid = BeatGrid(
      beats: beats, downbeats: .noneDetected, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: hostile, coverage: .analysisWindow)
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.beatIndex == 0)
    #expect(anchor.presentationTime == beats[0].presentationTime)
    #expect(anchor.confidence == beats[0].confidence)
    #expect(anchor.strength == beats[0].strength)
    #expect(anchor.source == .downbeat)  // preserved verbatim…

    // …but `.downbeat` source ALONE is not a bar-snap signal: downbeats are not
    // `.detected`, so the documented dual-gate is false.
    var barSnapUsable = false
    if case .detected = grid.downbeats, anchor.source == .downbeat { barSnapUsable = true }
    #expect(barSnapUsable == false)

    // An honest anchor (already equal to its beat) round-trips byte-identically — the
    // rebuild is a no-op on producer output.
    let honestAnchor = BeatGridAnchor(
      beatIndex: 3, presentationTime: beats[3].presentationTime,
      confidence: beats[3].confidence, strength: beats[3].strength,
      source: .medianConsistentBeat)
    let honest = BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: honestAnchor, coverage: .analysisWindow)
    #expect(honest.gridOrigin == honestAnchor)
  }

  // MARK: - BeatGrid.offset(by:) consumer-controlled alignment

  @Test func offsetShiftsUniformlyPreservingSpacing() throws {
    // Beats at 1.0/1.5/2.0/2.5 (minTime 1.0); downbeats detected at the bar starts.
    let beats = [1.0, 1.5, 2.0, 2.5].map {
      BeatTimestamp(presentationTime: $0, confidence: 0.8, strength: 0.6)
    }
    let estimate = DownbeatEstimate(
      beats: [beats[0], beats[2]], meter: MeterEstimate(beatsPerBar: 2, source: .assumed),
      confidence: 0.7, phaseIndex: 0)
    let grid = BeatGrid(
      beats: beats, downbeats: .detected(estimate: estimate), estimatedTempo: 120,
      confidence: 0.9, tempoAgreement: .agree,
      gridOrigin: BeatGridAnchor(
        beatIndex: 0, presentationTime: 1.0, confidence: 0.8, strength: 0.6,
        source: .downbeat),
      coverage: .fullTrack, schemaVersion: 1)

    // Positive shift: every timestamp + 0.25, spacing intact; gridOrigin + downbeats move.
    let plus = grid.offset(by: 0.25)
    #expect(plus.beats.map(\.presentationTime) == [1.25, 1.75, 2.25, 2.75])
    #expect(plus.gridOrigin?.presentationTime == 1.25)
    #expect(plus.gridOrigin?.beatIndex == 0)
    #expect(plus.gridOrigin?.source == .downbeat)
    if case .detected(let e) = plus.downbeats {
      #expect(e.beats.map(\.presentationTime) == [1.25, 2.25])
      #expect(e.phaseIndex == 0)
      #expect(e.meter.beatsPerBar == 2)
    } else {
      Issue.record("downbeats should remain .detected after offset")
    }
    // Non-time fields preserved.
    #expect(plus.estimatedTempo == 120)
    #expect(plus.tempoAgreement == .agree)
    #expect(plus.coverage == .fullTrack)
    #expect(plus.schemaVersion == 1)

    // Negative shift larger than minTime (−5) lands the earliest beat at EXACTLY 0 with
    // spacing intact — NOT all collapsed to 0 (the clamp-the-delta-once contract).
    let minus = grid.offset(by: -5)
    #expect(minus.beats.map(\.presentationTime) == [0.0, 0.5, 1.0, 1.5])
    #expect(minus.gridOrigin?.presentationTime == 0.0)

    // Identity no-ops: 0 and non-finite shifts.
    let original = beats.map(\.presentationTime)
    #expect(grid.offset(by: 0).beats.map(\.presentationTime) == original)
    #expect(grid.offset(by: .nan).beats.map(\.presentationTime) == original)
    #expect(grid.offset(by: .infinity).beats.map(\.presentationTime) == original)

    // Round-trip (binary-exact 0.5, no clamp engaged) is identity.
    let roundTrip = grid.offset(by: 0.5).offset(by: -0.5)
    #expect(roundTrip.beats.map(\.presentationTime) == original)
  }

  @Test func offsetThatWouldOverflowToInfinityIsNoOp() {
    // A beat already near the finite ceiling + a huge shift would overflow to +Inf, which
    // `BeatTimestamp` clamps to 0 (a silent beat→start collapse that destroys spacing).
    // The `(maxTime + effective).isFinite` guard makes it a no-op instead. (A merely huge
    // FINITE result — an absurd offset on normal beats — is acceptable GIGO, not guarded.)
    let ceiling = BeatGrid(
      beats: [
        BeatTimestamp(presentationTime: .greatestFiniteMagnitude, confidence: 0.5, strength: 0.5)
      ],
      downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    let shifted = ceiling.offset(by: .greatestFiniteMagnitude)
    #expect(shifted.beats.first?.presentationTime == .greatestFiniteMagnitude)
  }

  @Test func offsetOnEmptyGridIsNoOp() {
    let empty = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(empty.offset(by: 1.0).beats.isEmpty)
    #expect(empty.offset(by: 1.0).gridOrigin == nil)
  }

  // MARK: - Story 8.5a: MeterEstimate / MeterSource / DownbeatEstimate (AC1 / AC8e)

  /// `MeterSource` is `String`-backed → its `Codable` wire shape is a bare string
  /// (mirrors `BeatGridAnchorSource`), not the SE-0295 single-key object.
  @Test func meterSourceEncodesAsBareString() throws {
    #expect(try JSONEncoder().encode(MeterSource.assumed) == Data(#""assumed""#.utf8))
    #expect(try JSONEncoder().encode(MeterSource.detected) == Data(#""detected""#.utf8))
    #expect(MeterSource.assumed.rawValue == "assumed")
    #expect(MeterSource.detected.rawValue == "detected")
  }

  @Test(arguments: [
    MeterEstimate(beatsPerBar: 4, source: .assumed),
    MeterEstimate(beatsPerBar: 3, source: .detected),
  ])
  func meterEstimateRoundTrips(value: MeterEstimate) throws {
    let data = try JSONEncoder().encode(value)
    #expect(try JSONDecoder().decode(MeterEstimate.self, from: data) == value)
  }

  /// `DownbeatEstimate.confidence` clamps non-finite / out-of-range at construction
  /// AND on `Codable` decode, keeping the synthesized `Hashable` sound (AC8e).
  @Test func downbeatEstimateClampsConfidence() throws {
    let meter = MeterEstimate(beatsPerBar: 4, source: .assumed)
    #expect(
      DownbeatEstimate(beats: [], meter: meter, confidence: .nan, phaseIndex: 0)
        .confidence == 0.0)
    #expect(
      DownbeatEstimate(beats: [], meter: meter, confidence: 5.0, phaseIndex: 0)
        .confidence == 1.0)

    // Hostile JSON confidence re-clamps on decode.
    let json = #"""
      {"beats": [], "meter": {"beatsPerBar": 4, "source": "assumed"},
       "confidence": -2.0, "phaseIndex": 2}
      """#
    let decoded = try JSONDecoder().decode(DownbeatEstimate.self, from: Data(json.utf8))
    #expect(decoded.confidence == 0.0)
    #expect(decoded.phaseIndex == 2)
  }

  @Test func downbeatEstimateRoundTripAndHashable() throws {
    let estimate = Self.makeEstimate(3, phaseIndex: 1)
    let data = try JSONEncoder().encode(estimate)
    let back = try JSONDecoder().decode(DownbeatEstimate.self, from: data)
    #expect(back == estimate)
    #expect(back.hashValue == estimate.hashValue)

    // phaseIndex is a real field: two estimates differing only in it are unequal.
    let other = Self.makeEstimate(3, phaseIndex: 2)
    #expect(estimate != other)
  }

  // MARK: - Story 8.5a: BeatGrid.schemaVersion semantic-contract stamp (AC9 / DD #9)

  /// The current version is pinned to `2` (bumped from `1` by Story 8.12's
  /// `BeatGridAnchor.beatIndex: Int?` persisted-contract change) so a future bump is
  /// a visible diff against this test (the closest an inert field gets to
  /// enforcement), and a default-constructed grid auto-stamps it.
  @Test func schemaVersionCurrentIsTwoAndDefaultStamped() {
    #expect(BeatGrid.currentSchemaVersion == 2)
    #expect(Self.noRunSentinel.schemaVersion == 2)
    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(grid.schemaVersion == 2)
  }

  /// A legacy payload WITHOUT the key decodes to `schemaVersion == 1` (absent → 1),
  /// and the encoder ALWAYS emits the key.
  @Test func schemaVersionAbsentDefaultsToOneAndIsAlwaysEmitted() throws {
    let legacyJSON = #"""
      {"beats": [], "downbeats": {"notAttempted": {}}, "estimatedTempo": 120,
       "confidence": 0.5}
      """#
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Data(legacyJSON.utf8))
    #expect(decoded.schemaVersion == 1)

    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    let obj = try #require(
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(grid)) as? [String: Any])
    #expect(obj["schemaVersion"] as? Int == 2)
  }

  /// An unknown FUTURE version decodes faithfully (stored as-is, no throw) — the
  /// library does not judge compatibility; the consumer gates.
  @Test func schemaVersionUnknownFutureDecodesFaithfully() throws {
    let futureJSON = #"""
      {"beats": [], "downbeats": {"notAttempted": {}}, "estimatedTempo": 120,
       "confidence": 0.5, "schemaVersion": 99}
      """#
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: Data(futureJSON.utf8))
    #expect(decoded.schemaVersion == 99)
  }

  /// `schemaVersion` is a real stored field: two grids differing only in it are
  /// unequal and hash differently.
  @Test func schemaVersionParticipatesInEqualityAndHash() {
    let v1 = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow,
      schemaVersion: 1)
    let v2 = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow,
      schemaVersion: 2)
    #expect(v1 != v2)
    #expect(v1.hashValue != v2.hashValue)
  }

  // MARK: - Story 8.12: BeatGridAnchor.beatIndex: Int? (optional provenance)

  @Test func optionalBeatIndexClampsPresentNegativeAndPassesNil() {
    // A present index clamps `≥ 0`; a `nil` index (free-standing manual origin) passes through.
    let present = BeatGridAnchor(
      beatIndex: -4, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    #expect(present.beatIndex == 0)
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    #expect(free.beatIndex == nil)
  }

  @Test func anchorDescriptionRendersOptionalBeatIndex() {
    let coupled = BeatGridAnchor(
      beatIndex: 3, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    #expect(coupled.description.contains("beat: 3"))
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    #expect(free.description.contains("beat: nil"))
    #expect(!free.description.contains("Optional"))  // not `beat: Optional(…)`
  }

  @Test func optionalBeatIndexCodableOmitsNilKeyReclampsPresentNegative() throws {
    // The synthesized encoder omits the key when `nil`; the decode treats missing/`null` as
    // `nil` and re-clamps a *present* negative to `0` (routes through the clamping init).
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 2.5, confidence: 0.7, strength: 0.4, source: .manual)
    let data = try JSONEncoder().encode(free)
    let obj = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(obj["beatIndex"] == nil)
    #expect(try JSONDecoder().decode(BeatGridAnchor.self, from: data) == free)

    let coupled = BeatGridAnchor(
      beatIndex: 5, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    let obj2 = try #require(
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(coupled)) as? [String: Any])
    #expect(obj2["beatIndex"] as? Int == 5)

    // Explicit `null`, omitted key, and a present negative on decode.
    let nullJSON =
      #"{"beatIndex": null, "presentationTime": 1.0, "confidence": 0.5, "strength": 0.5, "source": "manual"}"#
    #expect(
      try JSONDecoder().decode(BeatGridAnchor.self, from: Data(nullJSON.utf8)).beatIndex == nil)
    let omittedJSON =
      #"{"presentationTime": 1.0, "confidence": 0.5, "strength": 0.5, "source": "firstBeat"}"#
    #expect(
      try JSONDecoder().decode(BeatGridAnchor.self, from: Data(omittedJSON.utf8)).beatIndex == nil)
    let negJSON =
      #"{"beatIndex": -3, "presentationTime": 1.0, "confidence": 0.5, "strength": 0.5, "source": "manual"}"#
    #expect(
      try JSONDecoder().decode(BeatGridAnchor.self, from: Data(negJSON.utf8)).beatIndex == 0)
  }

  // MARK: - Story 8.12: BeatGridAnchorSource.manual

  @Test func manualSourceRawValueWireShapeAndExhaustiveSwitch() throws {
    #expect(BeatGridAnchorSource.manual.rawValue == "manual")
    // `String`-backed → bare-string wire shape.
    #expect(try JSONEncoder().encode(BeatGridAnchorSource.manual) == Data(#""manual""#.utf8))
    // Exhaustive 5-case switch (a future case is a compile error here).
    let all: [BeatGridAnchorSource] = [
      .medianConsistentBeat, .strongestBeat, .firstBeat, .downbeat, .manual,
    ]
    for source in all {
      switch source {
      case .medianConsistentBeat, .strongestBeat, .firstBeat, .downbeat, .manual:
        #expect(Bool(true))
      }
    }
  }

  @Test func manualAnchorRoundTripsSnappedAndFreeStanding() throws {
    let snapped = BeatGridAnchor(
      beatIndex: 2, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .manual)
    #expect(
      try JSONDecoder().decode(BeatGridAnchor.self, from: JSONEncoder().encode(snapped)) == snapped)
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 3.7, confidence: 0.9, strength: 0.8, source: .manual)
    #expect(
      try JSONDecoder().decode(BeatGridAnchor.self, from: JSONEncoder().encode(free)) == free)
  }

  // MARK: - Story 8.12: BeatGrid.init three-rule gridOrigin invariant (DD #3)

  @Test func freeStandingManualAnchorIsKeptOffTheBeatGrid() throws {
    // (c) `nil` index + `.manual` → kept; the arbitrary off-beat time is authoritative.
    let beats = Self.makeBeats(4)  // beats at 0.0/0.5/1.0/1.5
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 0.77, confidence: 1.0, strength: 1.0, source: .manual)
    let grid = BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: free, coverage: .analysisWindow)
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 0.77)  // NOT snapped to a beat
    #expect(anchor.source == .manual)
  }

  @Test func freeStandingManualAnchorValidOnEmptyBeatsWithNotAttempted() throws {
    // A `.manual` origin asserts the bar WITHOUT claiming detection ran: it coexists with
    // empty beats AND `downbeats == .notAttempted` (DD #6 coupling-orthogonal trust).
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 12.5, confidence: 1.0, strength: 1.0, source: .manual)
    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 128, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: free, coverage: .analysisWindow)
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 12.5)
    #expect(grid.downbeats == .notAttempted)
  }

  @Test func nilIndexNonManualAnchorIsDropped() {
    // (c) `nil` index + a non-`.manual` source (an auto source with no beat to name) is
    // incoherent → dropped (sanitization).
    let incoherent = BeatGridAnchor(
      beatIndex: nil, presentationTime: 1.0, confidence: 0.5, strength: 0.5, source: .firstBeat)
    let grid = BeatGrid(
      beats: Self.makeBeats(4), downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: incoherent, coverage: .analysisWindow)
    #expect(grid.gridOrigin == nil)
  }

  @Test func outOfRangeManualAnchorIsDropped() {
    // (b) present + out of range → drop the WHOLE anchor, even for `.manual` (a claimed beat
    // relationship that is invalid is stale, NOT promoted to a free placement).
    let stale = BeatGridAnchor(
      beatIndex: 99, presentationTime: 5.0, confidence: 1.0, strength: 1.0, source: .manual)
    let grid = BeatGrid(
      beats: Self.makeBeats(4), downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: stale, coverage: .analysisWindow)
    #expect(grid.gridOrigin == nil)
  }

  @Test func decodedOutOfRangeManualAnchorIsDropped() throws {
    // Codable path mirrors the memberwise (b): a decoded present-out-of-range `.manual` drops.
    let json = #"""
      {"beats": [{"presentationTime": 0.5, "confidence": 0.9, "strength": 0.7}],
       "downbeats": {"notAttempted": {}}, "estimatedTempo": 120, "confidence": 0.5,
       "gridOrigin": {"beatIndex": 50, "presentationTime": 5.0, "confidence": 1.0,
                      "strength": 1.0, "source": "manual"}}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(grid.gridOrigin == nil)
    #expect(grid.beats.count == 1)
  }

  @Test func decodedNilIndexNonManualAnchorIsDropped() throws {
    // Codable path mirrors the memberwise (c): a decoded `nil`-index (omitted key)
    // `.firstBeat` anchor is incoherent → dropped. The safe hostile-decode posture: a
    // payload cannot smuggle a free-standing NON-manual origin.
    let json = #"""
      {"beats": [{"presentationTime": 0.5, "confidence": 0.9, "strength": 0.7}],
       "downbeats": {"notAttempted": {}}, "estimatedTempo": 120, "confidence": 0.5,
       "gridOrigin": {"presentationTime": 0.5, "confidence": 0.9, "strength": 0.7,
                      "source": "firstBeat"}}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    #expect(grid.gridOrigin == nil)
  }

  @Test func decodedInRangeGridOriginRebuiltFromBeat() throws {
    // Codable path mirrors the memberwise rule (a): a decoded present + in-range anchor with a
    // MISMATCHED time/confidence/strength is rebuilt from `beats[beatIndex]` (beatIndex + source
    // preserved). Completes the AC #3 "both paths" matrix for rule (a) — the decoded sibling of
    // `inRangeGridOriginRebuiltFromBeatPreservingSource`.
    let json = #"""
      {"beats": [{"presentationTime": 0.5, "confidence": 0.9, "strength": 0.7},
                 {"presentationTime": 1.0, "confidence": 0.8, "strength": 0.6}],
       "downbeats": {"notAttempted": {}}, "estimatedTempo": 120, "confidence": 0.5,
       "gridOrigin": {"beatIndex": 1, "presentationTime": 999.0, "confidence": 0.1,
                      "strength": 0.05, "source": "medianConsistentBeat"}}
      """#
    let grid = try JSONDecoder().decode(BeatGrid.self, from: Data(json.utf8))
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.beatIndex == 1)  // preserved
    #expect(anchor.source == .medianConsistentBeat)  // preserved
    // Rebuilt from beats[1], NOT the hostile decoded values.
    #expect(anchor.presentationTime == grid.beats[1].presentationTime)
    #expect(anchor.confidence == grid.beats[1].confidence)
    #expect(anchor.strength == grid.beats[1].strength)
  }

  @Test func freeStandingManualGridCodableRoundTripPreservesArbitraryTime() throws {
    // AC #4: a free-standing manual grid round-trips with its arbitrary off-beat time intact
    // (the `nil`-index anchor is NOT rebuilt from any beat).
    let beats = Self.makeBeats(4)
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 1.234567, confidence: 0.6, strength: 0.3, source: .manual)
    let grid = BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared, gridOrigin: free, coverage: .analysisWindow)
    let decoded = try JSONDecoder().decode(BeatGrid.self, from: JSONEncoder().encode(grid))
    let anchor = try #require(decoded.gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 1.234567)
    #expect(anchor.source == .manual)
    #expect(decoded == grid)  // whole-grid round-trip identity
  }

  // MARK: - Story 8.12: repositioningAnchor(to:mode:)

  /// A grid with beats at 0.0/0.5/1.0/1.5/2.0 (uniform conf 0.8 / str 0.6) and a coupled
  /// auto-style anchor at beat 0 — independent planted ground truth for the nearest-beat math.
  private static func repositionGrid() -> BeatGrid {
    let beats = [0.0, 0.5, 1.0, 1.5, 2.0].map {
      BeatTimestamp(presentationTime: $0, confidence: 0.8, strength: 0.6)
    }
    return BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.9,
      tempoAgreement: .agree,
      gridOrigin: BeatGridAnchor(
        beatIndex: 0, presentationTime: 0.0, confidence: 0.8, strength: 0.6,
        source: .medianConsistentBeat),
      coverage: .fullTrack)
  }

  @Test func repositionModeHasTwoCasesAndExhaustiveSwitch() {
    #expect(BeatGridAnchorRepositionMode.allCases.count == 2)
    for mode in BeatGridAnchorRepositionMode.allCases {
      switch mode {
      case .snapToNearestBeat, .exactTime: #expect(Bool(true))
      }
    }
  }

  @Test func snapToNearestBeatCouplesToNearestBeatAsManual() throws {
    let grid = Self.repositionGrid()
    // 1.1 is nearest to beat 2 (1.0): distance 0.1 vs 0.4 to beat 3 (1.5).
    let result = grid.repositioningAnchor(to: 1.1)  // default .snapToNearestBeat
    let anchor = try #require(result.gridOrigin)
    #expect(anchor.beatIndex == 2)
    #expect(anchor.presentationTime == 1.0)  // taken from beats[2]
    #expect(anchor.confidence == grid.beats[2].confidence)
    #expect(anchor.strength == grid.beats[2].strength)
    #expect(anchor.source == .manual)
  }

  @Test func exactTimePlacesFreeStandingManualAnchor() throws {
    let grid = Self.repositionGrid()
    let result = grid.repositioningAnchor(to: 1.1, mode: .exactTime)
    let anchor = try #require(result.gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 1.1)  // NOT snapped
    #expect(anchor.source == .manual)
  }

  @Test func snapTieBreaksToLowerBeatIndex() throws {
    let grid = Self.repositionGrid()
    // 1.25 is exactly equidistant from beat 2 (1.0) and beat 3 (1.5) → lower index wins.
    let result = grid.repositioningAnchor(to: 1.25)
    #expect(result.gridOrigin?.beatIndex == 2)
    #expect(result.gridOrigin?.presentationTime == 1.0)
  }

  @Test func snapNegativeTimeSnapsToEarliestBeat() throws {
    let grid = Self.repositionGrid()
    let result = grid.repositioningAnchor(to: -10.0)
    #expect(result.gridOrigin?.beatIndex == 0)  // earliest beat
    #expect(result.gridOrigin?.presentationTime == 0.0)
  }

  @Test func repositionNonFiniteTimeIsNoOp() {
    let grid = Self.repositionGrid()
    #expect(grid.repositioningAnchor(to: .nan) == grid)
    #expect(grid.repositioningAnchor(to: .infinity) == grid)
    #expect(grid.repositioningAnchor(to: -.infinity, mode: .exactTime) == grid)
  }

  @Test func snapOnEmptyBeatsIsNoOp() {
    let empty = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    // Default `.snapToNearestBeat` has nothing to snap to → returns self unchanged.
    #expect(empty.repositioningAnchor(to: 5.0) == empty)
  }

  @Test func exactTimeOnEmptyBeatsPlacesFreeAnchor() throws {
    let empty = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    let result = empty.repositioningAnchor(to: 5.0, mode: .exactTime)
    let anchor = try #require(result.gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 5.0)
    #expect(anchor.source == .manual)
    #expect(result.beats.isEmpty)
  }

  @Test func exactTimeNegativeClampsToZero() throws {
    let grid = Self.repositionGrid()
    // A negative finite time under `.exactTime` clamps to 0 (BeatGridAnchor floor).
    let anchor = try #require(grid.repositioningAnchor(to: -3.0, mode: .exactTime).gridOrigin)
    #expect(anchor.beatIndex == nil)
    #expect(anchor.presentationTime == 0.0)
  }

  @Test func repositionMutatesAnchorOnlyAndDoesNotForceDetected() {
    let grid = Self.repositionGrid()
    let result = grid.repositioningAnchor(to: 1.1, mode: .exactTime)
    // Every non-gridOrigin field is bit-identical (AC #9).
    #expect(result.beats == grid.beats)
    #expect(result.downbeats == grid.downbeats)
    #expect(result.estimatedTempo.bitPattern == grid.estimatedTempo.bitPattern)
    #expect(result.confidence.bitPattern == grid.confidence.bitPattern)
    #expect(result.tempoAgreement == grid.tempoAgreement)
    #expect(result.coverage == grid.coverage)
    #expect(result.schemaVersion == grid.schemaVersion)
    // `downbeats` is NOT forced to `.detected` (a `.manual` origin does not claim detection).
    #expect(result.downbeats == .notAttempted)
  }

  // MARK: - Story 8.12: offset(by:) with a free-standing anchor (DD #4)

  @Test func offsetShiftsFreeStandingAnchorDirectly() throws {
    let beats = [1.0, 1.5, 2.0].map {
      BeatTimestamp(presentationTime: $0, confidence: 0.8, strength: 0.6)
    }
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 1.2, confidence: 0.9, strength: 0.7, source: .manual)
    let grid = BeatGrid(
      beats: beats, downbeats: .notAttempted, estimatedTempo: 120, confidence: 0.9,
      tempoAgreement: .agree, gridOrigin: free, coverage: .fullTrack)
    // +0.25: beats shift, and the free anchor shifts DIRECTLY (init does not rebuild a
    // `nil`-index anchor, so `offset` must move it itself).
    let plus = grid.offset(by: 0.25)
    #expect(plus.beats.map(\.presentationTime) == [1.25, 1.75, 2.25])
    #expect(plus.gridOrigin?.beatIndex == nil)
    // Compare against the computed shift (`1.2 + 0.25`), not the non-representable literal
    // `1.45`, so the assertion can't break by 1 ULP on an operand-order/clamp change.
    #expect(plus.gridOrigin?.presentationTime == 1.2 + 0.25)
    #expect(plus.gridOrigin?.source == .manual)
  }

  @Test func offsetFreeStandingAnchorOnEmptyBeatsSeedsFromAnchorTime() throws {
    // A lone free anchor at 100 on an empty-`beats` grid: min/max are seeded from the
    // anchor's OWN time (the union, not a `?? 0` fold), so a negative offset actually moves
    // it instead of clamping to a no-op (DD #4).
    let free = BeatGridAnchor(
      beatIndex: nil, presentationTime: 100.0, confidence: 1.0, strength: 1.0, source: .manual)
    let grid = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: free, coverage: .analysisWindow)
    // −50 → 50 (proves minTime came from the anchor, not 0 which would clamp to a no-op).
    #expect(grid.offset(by: -50).gridOrigin?.presentationTime == 50.0)
    // −150 → the (only) timestamp clamps to land exactly at 0.
    #expect(grid.offset(by: -150).gridOrigin?.presentationTime == 0.0)
    // +30 → 130.
    #expect(grid.offset(by: 30).gridOrigin?.presentationTime == 130.0)
    // The shifted anchor stays free-standing manual.
    #expect(grid.offset(by: -50).gridOrigin?.beatIndex == nil)
    #expect(grid.offset(by: -50).gridOrigin?.source == .manual)
  }
}
