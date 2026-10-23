//
//  PlayableBeatGridTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.10 Part B: `PlayableBeatGrid` (the constant-grid formula as a value
//  type with pure ordinal and time queries), `BeatGrid.playableGrid`, and the
//  `BeatGrid.hasTrustedBarOrigin` bar-origin gate.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("PlayableBeatGridTests")
struct PlayableBeatGridTests {

  // MARK: - Fixtures

  /// The I/O-matrix grid: origin 0.337 s at 128 BPM (period 0.46875 s).
  private static let grid = PlayableBeatGrid(originTime: 0.337, bpm: 128)!

  /// A beat grid from the production analyzer over 30 s of clicks at `bpm`.
  private static func analyzerGrid(bpm: Double) throws -> BeatGrid {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(
      generateClickTrack(bpm: bpm, sampleRate: 44_100, durationSeconds: 30),
      sampleRate: 44_100)
    return try #require(try AudioAnalysisService.analyzeBeatGrid(decoded: decoded))
  }

  /// `{ n : range.contains(time(ofBeat: n)!) }` over `ordinals`, as a closed
  /// range (`nil` when empty). Records an issue if the set is not contiguous.
  private static func bruteForce(
    _ grid: PlayableBeatGrid, _ range: ClosedRange<Double>, ordinals: ClosedRange<Int>
  ) -> ClosedRange<Int>? {
    let members = ordinals.filter { range.contains(grid.time(ofBeat: $0)!) }
    guard let first = members.first, let last = members.last else { return nil }
    #expect(members.count == last - first + 1, "membership is not contiguous for \(range)")
    return first...last
  }

  // MARK: - Construction

  @Test func validInitExposesFieldsAndPeriod() throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0.337, bpm: 128))
    #expect(grid.originTime == 0.337)
    #expect(grid.bpm == 128)
    #expect(grid.beatPeriod == 0.46875)
    // A negative origin is a finite origin.
    #expect(PlayableBeatGrid(originTime: -2.5, bpm: 90) != nil)
  }

  @Test(arguments: [
    0.0, -1.0, Double.nan, Double.infinity, -Double.infinity, Double.leastNonzeroMagnitude,
  ])
  func invalidBPMIsRejected(bpm: Double) {
    #expect(PlayableBeatGrid(originTime: 0.337, bpm: bpm) == nil)
  }

  @Test(arguments: [Double.nan, Double.infinity, -Double.infinity])
  func invalidOriginIsRejected(originTime: Double) {
    #expect(PlayableBeatGrid(originTime: originTime, bpm: 128) == nil)
  }

  // MARK: - time(ofBeat:)

  @Test(arguments: [128.0, 174.3])
  func timeIsTheClosedFormBitForBit(bpm: Double) throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0.337, bpm: bpm))
    for n in [-3, 0, 1, 1_000, 100_000] {
      let expected = 0.337 + (60.0 / bpm) * Double(n)
      let got = try #require(grid.time(ofBeat: n))
      #expect(
        NumericTestHelpers.bitEqual(got, expected), "n = \(n): \(got) vs closed form \(expected)")
    }
  }

  @Test func negativeOrdinalIsReturnedAsComputed() throws {
    let t = try #require(Self.grid.time(ofBeat: -1))
    #expect(NumericTestHelpers.bitEqual(t, 0.337 + (60.0 / 128) * -1.0))
    #expect(abs(t - -0.13175) < 1e-15)
  }

  @Test func analyzerGridPlayableTimesMatchTheDocumentedFormula() throws {
    for bpm in [120.0, 128.0] {
      let grid = try Self.analyzerGrid(bpm: bpm)
      let origin = try #require(grid.gridOrigin)
      let playable = try #require(grid.playableGrid)
      #expect(playable.originTime == origin.presentationTime)
      #expect(playable.bpm == grid.estimatedTempo)
      for n in [-3, 0, 1, 7, 1_000, 100_000] {
        let expected = origin.presentationTime + (60.0 / grid.estimatedTempo) * Double(n)
        let got = try #require(playable.time(ofBeat: n))
        #expect(NumericTestHelpers.bitEqual(got, expected), "n = \(n): \(got) vs \(expected)")
      }
    }
  }

  // MARK: - beatPosition(at:) and beatInBar

  @Test func positionInvertsTime() throws {
    for bpm in [128.0, 174.3] {
      let grid = try #require(PlayableBeatGrid(originTime: 0.337, bpm: bpm))
      for n in -1_000...1_000 {
        let t = try #require(grid.time(ofBeat: n))
        let position = try #require(grid.beatPosition(at: t))
        #expect(abs(position - Double(n)) <= 1e-9, "n = \(n), position \(position)")
      }
    }
  }

  @Test func beatInBarWrapsBothDirections() {
    #expect(Self.grid.beatInBar(ofBeat: -1, beatsPerBar: 4) == 3)
    for n in -9...9 {
      #expect(Self.grid.beatInBar(ofBeat: n, beatsPerBar: 4) == ((n % 4) + 4) % 4)
    }
    #expect(Self.grid.beatInBar(ofBeat: 5, beatsPerBar: 0) == nil)
    #expect(Self.grid.beatInBar(ofBeat: 5, beatsPerBar: -4) == nil)
    #expect(Self.grid.beatInBar(ofBeat: 5, beatsPerBar: 1) == 0)
    #expect(Self.grid.beatInBar(ofBeat: 7, beatsPerBar: 3) == 1)
  }

  // MARK: - beats(in:)

  @Test func rangeRows() {
    // Times 0.337 and 0.80575 lie in [0, 1].
    #expect(Self.grid.beats(in: 0.0...1.0) == 0...1)
    // Positions 3.55 to 3.76 hold no integer.
    #expect(Self.grid.beats(in: 2.0...2.1) == nil)
    // A degenerate range on an exact beat time holds that beat.
    let t5 = Self.grid.time(ofBeat: 5)!
    #expect(Self.grid.beats(in: t5...t5) == 5...5)
    // Ranges before the origin give negative ordinals.
    #expect(Self.grid.beats(in: -1.0...0.0) == -2...(-1))
  }

  @Test(arguments: [128.0, 174.3])
  func randomizedRangesMatchBruteForce(bpm: Double) throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0.337, bpm: bpm))
    var rng = SplitMix64(seed: 0x15_10_BEA7)
    func unit() -> Double { Double(rng.next() >> 11) / 9_007_199_254_740_992.0 }
    // An exact beat time near `seconds`, kept inside [-5, 600].
    func exactBeat(near seconds: Double) -> Double {
      var n = Int(((seconds - 0.337) / grid.beatPeriod).rounded(.down))
      while grid.time(ofBeat: n)! < -5 { n += 1 }
      while grid.time(ofBeat: n)! > 600 { n -= 1 }
      return grid.time(ofBeat: n)!
    }
    var exactBoundCount = 0
    var emptyCount = 0
    for _ in 0..<1_000 {
      let start = -5.0 + 605.0 * unit()
      let width = rng.next() % 2 == 0 ? unit() * 1.0 : unit() * 605.0
      var lower = start
      var upper = min(600.0, start + width)
      switch rng.next() % 4 {
      case 1:
        lower = exactBeat(near: lower)
        exactBoundCount += 1
      case 2:
        upper = exactBeat(near: upper)
        exactBoundCount += 1
      case 3:
        lower = exactBeat(near: lower)
        upper = exactBeat(near: upper)
        exactBoundCount += 2
      default:
        break
      }
      if lower > upper { swap(&lower, &upper) }
      let range = lower...upper
      let expected = Self.bruteForce(grid, range, ordinals: -40...2_000)
      if expected == nil { emptyCount += 1 }
      #expect(grid.beats(in: range) == expected, "range \(range)")
    }
    // The draw must exercise both exact-beat bounds and empty results.
    #expect(exactBoundCount > 300)
    #expect(emptyCount > 10)
  }

  @Test func unresolvedRangeMatchesBruteForceOrAbstains() throws {
    // ulp(1e16) is 2 s, so ordinals -2...2 (period 0.5 s) all round to 1e16.
    let grid = try #require(PlayableBeatGrid(originTime: 1e16, bpm: 120))
    let range = 1e16...1e16
    let expected = Self.bruteForce(grid, range, ordinals: -8...8)
    let got = grid.beats(in: range)
    #expect(
      got == nil || got == expected,
      "got \(String(describing: got)), brute \(String(describing: expected))")
    #expect(got == -2...2)

    // ulp(1e17) is 16 s: 33 ordinals collapse onto 1e17, more than 8 steps from
    // the estimate, so the walk cannot settle and the query abstains.
    let wide = try #require(PlayableBeatGrid(originTime: 1e17, bpm: 120))
    #expect(wide.beats(in: 1e17...1e17) == nil)
  }

  // MARK: - nearestBeat(to:)

  @Test func exactTieGoesToTheLowerOrdinal() throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0, bpm: 120))
    #expect(abs(1.25 - grid.time(ofBeat: 2)!) == abs(grid.time(ofBeat: 3)! - 1.25))
    #expect(grid.nearestBeat(to: 1.25) == 2)
  }

  @Test func positionMidpointResolvesByComputedDistance() throws {
    let t = 3.852625
    // Premise: the inverse position is exactly 7.5, yet beat 8 is nearer.
    #expect(Self.grid.beatPosition(at: t) == 7.5)
    let toSeven = abs(t - Self.grid.time(ofBeat: 7)!)
    let toEight = abs(Self.grid.time(ofBeat: 8)! - t)
    #expect(toEight < toSeven, "distance to 7: \(toSeven), to 8: \(toEight)")
    #expect(Self.grid.nearestBeat(to: t) == 8)
  }

  @Test func nearestBeatOnAndBetweenBeats() {
    for n in -20...200 {
      let t = Self.grid.time(ofBeat: n)!
      #expect(Self.grid.nearestBeat(to: t) == n)
      #expect(Self.grid.nearestBeat(to: t + 0.2) == n)
      #expect(Self.grid.nearestBeat(to: t - 0.2) == n)
    }
  }

  /// Asserts `got` is the lowest ordinal at the minimum computed distance from
  /// `time` among `got - 8 ... got + 8`, ignoring ordinals with no defined time.
  private static func expectNearestByBruteForce(
    _ grid: PlayableBeatGrid, _ time: Double, _ got: Int
  ) {
    let candidates = ((got - 8)...(got + 8)).compactMap { n in
      grid.time(ofBeat: n).map { (n, abs($0 - time)) }
    }
    let best = candidates.map(\.1).min()!
    let lowest = candidates.first { $0.1 == best }!.0
    #expect(got == lowest, "got \(got), brute-force lowest nearest \(lowest) at \(best)")
  }

  @Test func nearestBeatNeverReturnsAnOrdinalWithoutATime() throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0, bpm: 3.003849708984722e-306))
    let got = grid.nearestBeat(to: .greatestFiniteMagnitude)
    if let got {
      #expect(grid.time(ofBeat: got) != nil, "ordinal \(got) has no defined time")
      Self.expectNearestByBruteForce(grid, .greatestFiniteMagnitude, got)
    }
  }

  @Test func nearestBeatSettlesWhenThePositionLosesPrecision() throws {
    // The floor and ceiling of the position do not bracket the nearest computed beat.
    let coarse = try #require(PlayableBeatGrid(originTime: 1e15, bpm: 140))
    let t = -930114126015926.9
    let got = try #require(coarse.nearestBeat(to: t))
    #expect(got == -4_503_599_627_370_496)
    Self.expectNearestByBruteForce(coarse, t, got)

    // Ordinals -2...2 all sit at distance 0 from 1e16; the tie goes to the lowest.
    let collapsed = try #require(PlayableBeatGrid(originTime: 1e16, bpm: 120))
    #expect(collapsed.nearestBeat(to: 1e16) == -2)
    Self.expectNearestByBruteForce(collapsed, 1e16, -2)

    // 33 ordinals collapse onto 1e17, more than 8 steps: the walk abstains.
    let wide = try #require(PlayableBeatGrid(originTime: 1e17, bpm: 120))
    #expect(wide.nearestBeat(to: 1e17) == nil)
  }

  @Test func ordinalDomainEndpointsAreSupported() throws {
    let grid = try #require(PlayableBeatGrid(originTime: 0, bpm: 60))
    let limit = 1 << 53
    let top = Double(limit)
    #expect(grid.beats(in: top...top) == limit...limit)
    #expect(grid.beats(in: -top...(-top)) == (-limit)...(-limit))
    #expect(grid.beats(in: (top - 3)...top) == (limit - 3)...limit)
    #expect(grid.beats(in: -top...(-top + 3)) == (-limit)...(-limit + 3))
    #expect(grid.nearestBeat(to: top) == limit)
    #expect(grid.nearestBeat(to: top - 1) == limit - 1)
    #expect(grid.nearestBeat(to: -top) == -limit)
  }

  // MARK: - Beyond 2^53 and non-finite inputs

  @Test func beyondTwoToTheFiftyThreeIsNil() {
    let limit = 1 << 53
    #expect(Self.grid.time(ofBeat: limit) != nil)
    #expect(Self.grid.time(ofBeat: -limit) != nil)
    #expect(Self.grid.time(ofBeat: limit + 1) == nil)
    #expect(Self.grid.time(ofBeat: -limit - 1) == nil)
    #expect(Self.grid.time(ofBeat: Int.min) == nil)
    #expect(Self.grid.time(ofBeat: Int.max) == nil)

    #expect(Self.grid.beatInBar(ofBeat: limit + 1, beatsPerBar: 4) == nil)
    #expect(Self.grid.beatInBar(ofBeat: Int.min, beatsPerBar: 4) == nil)
    #expect(Self.grid.beatInBar(ofBeat: Int.max, beatsPerBar: 4) == nil)
    #expect(Self.grid.beatInBar(ofBeat: -limit, beatsPerBar: 4) == 0)

    // A time whose position exceeds 2^53 in magnitude.
    let far = 0.337 + 0.46875 * 9.1e15
    #expect(Self.grid.beatPosition(at: far) == nil)
    #expect(Self.grid.nearestBeat(to: far) == nil)
    #expect(Self.grid.nearestBeat(to: -far) == nil)
    #expect(Self.grid.beats(in: 0.0...far) == nil)
    #expect(Self.grid.beats(in: -far...0.0) == nil)
    #expect(Self.grid.beats(in: 0.0...1e300) == nil)

    // Non-finite inputs.
    #expect(Self.grid.beatPosition(at: .nan) == nil)
    #expect(Self.grid.nearestBeat(to: .nan) == nil)
    #expect(Self.grid.nearestBeat(to: .infinity) == nil)
    #expect(Self.grid.beats(in: 0.0...Double.infinity) == nil)
    #expect(Self.grid.beats(in: -Double.infinity...0.0) == nil)
    #expect(Self.grid.beats(in: -Double.greatestFiniteMagnitude...0.0) == nil)
  }

  // MARK: - Re-anchor and offset invariance

  @Test(arguments: [1, 5, 37])
  func reanchoringMovesTheOrdinalNotTheGrid(k: Int) throws {
    let g = try Self.analyzerGrid(bpm: 128)
    let playable = try #require(g.playableGrid)
    let t = try #require(playable.time(ofBeat: k))
    try #require(t >= 0)
    let g2 = g.repositioningAnchor(to: t, mode: .exactTime)
    let playable2 = try #require(g2.playableGrid)
    for n in -10...200 {
      let moved = try #require(playable2.time(ofBeat: n - k))
      let original = try #require(playable.time(ofBeat: n))
      #expect(abs(moved - original) <= 1e-9, "n = \(n): \(moved) vs \(original)")
    }
  }

  @Test func offsetShiftsEveryPlayableTime() throws {
    let g = try Self.analyzerGrid(bpm: 128)
    let playable = try #require(g.playableGrid)
    let shifted = try #require(g.offset(by: 0.0125).playableGrid)
    for n in 0...200 {
      let moved = try #require(shifted.time(ofBeat: n))
      let original = try #require(playable.time(ofBeat: n))
      let delta = moved - original
      #expect(abs(delta - 0.0125) <= 1e-12, "n = \(n): delta \(delta)")
    }
  }

  // MARK: - BeatGrid.playableGrid

  @Test func playableGridIsNilWithoutOriginOrTempo() {
    let noOrigin = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 120, confidence: 0,
      tempoAgreement: .notCompared, gridOrigin: nil, coverage: .analysisWindow)
    #expect(noOrigin.playableGrid == nil)

    let noTempo = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 0, confidence: 0,
      tempoAgreement: .notCompared,
      gridOrigin: BeatGridAnchor(
        beatIndex: nil, presentationTime: 1.0, confidence: 1, strength: 1, source: .manual),
      coverage: .analysisWindow)
    #expect(noTempo.gridOrigin != nil)
    #expect(noTempo.playableGrid == nil)

    let manual = BeatGrid(
      beats: [], downbeats: .notAttempted, estimatedTempo: 128, confidence: 0,
      tempoAgreement: .notCompared,
      gridOrigin: BeatGridAnchor(
        beatIndex: nil, presentationTime: 0.337, confidence: 1, strength: 1, source: .manual),
      coverage: .analysisWindow)
    #expect(manual.playableGrid == Self.grid)
  }

  // MARK: - BeatGrid.hasTrustedBarOrigin

  private static let beats = [
    BeatTimestamp(presentationTime: 0.5, confidence: 0.9, strength: 0.8),
    BeatTimestamp(presentationTime: 1.0, confidence: 0.9, strength: 0.8),
  ]

  private static let detected = DownbeatResult.detected(
    estimate: DownbeatEstimate(
      beats: [beats[1]], meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
      confidence: 0.7, phaseIndex: 1))

  private static func gridWith(
    source: BeatGridAnchorSource?, beatIndex: Int? = 1, downbeats: DownbeatResult
  ) -> BeatGrid {
    BeatGrid(
      beats: beats, downbeats: downbeats, estimatedTempo: 120, confidence: 0.5,
      tempoAgreement: .notCompared,
      gridOrigin: source.map {
        BeatGridAnchor(
          beatIndex: beatIndex, presentationTime: 0.75, confidence: 1, strength: 1, source: $0)
      },
      coverage: .analysisWindow)
  }

  @Test func trustGateRows() {
    // `.downbeat` corroborated by a detection.
    #expect(Self.gridWith(source: .downbeat, downbeats: Self.detected).hasTrustedBarOrigin)
    // A free-standing `.manual` origin with no detection.
    let manual = Self.gridWith(source: .manual, beatIndex: nil, downbeats: .notAttempted)
    #expect(manual.gridOrigin?.source == .manual)
    #expect(manual.hasTrustedBarOrigin)
    // A coupled `.manual` origin is trusted too.
    #expect(Self.gridWith(source: .manual, downbeats: .noneDetected).hasTrustedBarOrigin)
    // `.downbeat` without a detection is not.
    #expect(!Self.gridWith(source: .downbeat, downbeats: .noneDetected).hasTrustedBarOrigin)
    #expect(!Self.gridWith(source: .downbeat, downbeats: .notAttempted).hasTrustedBarOrigin)
    // Beat-level sources are not bar origins, detection or not.
    for source in [BeatGridAnchorSource.medianConsistentBeat, .strongestBeat, .firstBeat] {
      #expect(!Self.gridWith(source: source, downbeats: .notAttempted).hasTrustedBarOrigin)
      #expect(!Self.gridWith(source: source, downbeats: Self.detected).hasTrustedBarOrigin)
    }
    // No origin.
    #expect(!Self.gridWith(source: nil, downbeats: Self.detected).hasTrustedBarOrigin)
  }
}
