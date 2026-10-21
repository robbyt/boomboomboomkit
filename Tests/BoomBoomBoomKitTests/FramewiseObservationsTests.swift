//
//  FramewiseObservationsTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.6: regression tests for the internal framewise observation
//  path, DSP-derived stub producer, 4/4 structured decoder, and
//  metrical-level selector.
//
//  Tempos whose period is not an integer number of hops (128 BPM is 46.875
//  frames at 100 fps) are covered alongside 120 BPM (exactly 50 frames):
//  a decoder that steps by a fractional period without re-anchoring drifts
//  off the beats only at the former.
//
//  All types under test are `internal` to `BoomBoomBoomKit`; this file
//  uses `@testable import`.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Framewise observations + 4/4 decoder (Story 15.6)")
struct FramewiseObservationsTests {

  // MARK: - Fixtures

  private static let sampleRate: Double = 44_100
  private static let hopSize = 441
  private static let tempoBPM: Double = 120.0
  private static let durationSeconds: Double = 12.0
  private static let hopSeconds = Double(hopSize) / sampleRate

  /// Exact-tempo single-impulse click track. Beat `k` (k >= 1) sits at
  /// sample `round(k * 60 / tempoBPM * sampleRate)`, so the first click is
  /// one period in. `amplitudes` cycles per beat; samples whose time falls
  /// in `silence` are zeroed.
  static func clickTrack(
    tempoBPM: Double = tempoBPM,
    durationSeconds: Double = durationSeconds,
    amplitudes: [Float] = [1.0],
    silence: Range<Double>? = nil
  ) -> FeatureSubstrate.DecodedAudio {
    let totalCount = Int(sampleRate * durationSeconds)
    var samples = [Float](repeating: 0, count: totalCount)
    for position in plantedBeatSamples(tempoBPM: tempoBPM, totalCount: totalCount) {
      let k = Int((Double(position) / sampleRate * tempoBPM / 60.0).rounded())
      samples[position] = amplitudes[(k - 1) % amplitudes.count]
    }
    if let silence {
      let start = Int(silence.lowerBound * sampleRate)
      let end = min(totalCount, Int(silence.upperBound * sampleRate))
      for i in start..<end { samples[i] = 0 }
    }
    return FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
  }

  /// Sample positions of the planted beats in ``clickTrack``.
  static func plantedBeatSamples(tempoBPM: Double, totalCount: Int) -> [Int] {
    let periodSamples = 60.0 / tempoBPM * sampleRate
    var positions: [Int] = []
    var k = 1
    while true {
      let position = Int((Double(k) * periodSamples).rounded())
      if position >= totalCount - 1 { break }
      positions.append(position)
      k += 1
    }
    return positions
  }

  static func stubObservations(_ decoded: FeatureSubstrate.DecodedAudio) throws
    -> FramewiseObservations
  {
    try #require(DSPStubObservationProducer(hopSize: hopSize).produce(decoded: decoded))
  }

  /// Hand-built observations at 100 fps with a zero origin.
  static func handBuilt(
    beat: [Float], downbeat: [Float]? = nil
  ) -> FramewiseObservations {
    FramewiseObservations(
      frameRate: 100,
      firstFrameOriginSeconds: 0,
      coverageWindowSeconds: Double(beat.count) / 100,
      beatProbabilities: beat,
      downbeatProbabilities: downbeat ?? beat.map { $0 * 0.5 },
      modelIdentifier: "test",
      frontendIdentifier: "test"
    )
  }

  /// Observed frames of a hand-built (100 fps, zero origin) candidate.
  static func frames(_ candidate: CandidateBeatSequence) -> [Int] {
    candidate.beats.map { Int(($0.time * 100).rounded()) }
  }

  /// `count` frames at `floor` with `value` written at each of `frames`.
  static func train(
    _ frames: [Int], value: Float = 1, floor: Float = 0, count: Int
  ) -> [Float] {
    var beat = [Float](repeating: floor, count: count)
    for frame in frames { beat[frame] = value }
    return beat
  }

  // MARK: - AC #1: stub producer surface

  @Test func stubProducerReturnsFullyPopulatedObservations() throws {
    let obs = try Self.stubObservations(Self.clickTrack())
    #expect(obs.frameRate == Self.sampleRate / Double(Self.hopSize))
    // Story 15.3 convention: the stub producer bakes the Hann-window-center
    // offset into firstFrameOriginSeconds so timeForFrame returns the
    // same instant BeatGridAnalyzer reports via its +(hopSize + fftSize/2)
    // correction.
    let expectedOrigin =
      (Double(Self.hopSize) + Double(BPMAnalyzer.fftSize) / 2.0) / Self.sampleRate
    #expect(abs(obs.firstFrameOriginSeconds - expectedOrigin) < 1e-9)
    #expect(obs.timeForFrame(0) == obs.firstFrameOriginSeconds)
    #expect(obs.coverageWindowSeconds > 0)
    #expect(obs.beatProbabilities.count == obs.downbeatProbabilities.count)
    #expect(obs.beatProbabilities.allSatisfy { $0 >= 0 && $0 <= 1 })
    #expect(obs.downbeatProbabilities.allSatisfy { $0 >= 0 && $0 <= 1 })
    #expect(obs.modelIdentifier == "dsp-stub.v1")
    #expect(obs.frontendIdentifier == "bpmanalyzer-onset.v1")
  }

  @Test func silentInputProducesZeroProbabilityObservations() throws {
    let totalCount = Int(Self.sampleRate * Self.durationSeconds)
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: [Float](repeating: 0, count: totalCount),
      sampleRate: Self.sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let obs = try Self.stubObservations(decoded)
    #expect(obs.beatProbabilities.allSatisfy { $0 == 0 })
    #expect(obs.downbeatProbabilities.allSatisfy { $0 == 0 })
    #expect(obs.coverageWindowSeconds > 0)
    #expect(BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter) == nil)
  }

  // MARK: - AC #2: decoder on planted clicks

  @Test(arguments: [120.0, 128.0])
  func decoderRecoversBeatsOnPlantedClickTrack(tempoBPM: Double) throws {
    let obs = try Self.stubObservations(Self.clickTrack(tempoBPM: tempoBPM))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: tempoBPM, level: .quarter))

    #expect(candidate.metricalLevel == .quarter)
    #expect(candidate.tempoBPM == tempoBPM)
    // About 12 s of clicks: one per period, minus edge positions whose
    // windows do not fit inside the coverage.
    let plantedCount = Self.plantedBeatSamples(
      tempoBPM: tempoBPM, totalCount: Int(Self.sampleRate * Self.durationSeconds)
    ).count
    #expect(candidate.beats.count >= plantedCount - 2 && candidate.beats.count <= plantedCount)

    // Every beat lies within 2 hops of a planted click. The emitted times
    // carry the constant early bias of the onset frontend (the Story 15.3
    // residual, under one hop on single-impulse clicks), so 2 hops leaves
    // one hop of margin for the frame grid.
    let periodSeconds = 60.0 / tempoBPM
    let slack = 2 * Self.hopSeconds
    for beat in candidate.beats {
      let nearest = (beat.time / periodSeconds).rounded() * periodSeconds
      let distance = abs(beat.time - nearest)
      #expect(
        distance <= slack, "beat at \(beat.time) is \(distance) s from the nearest planted beat")
    }
    #expect(candidate.meanBeatSupport > 0.3, "stub beat support mean \(candidate.meanBeatSupport)")
  }

  @Test func decoderIntervalsMatchPeriodAt128BPM() throws {
    let tempoBPM = 128.0
    let obs = try Self.stubObservations(Self.clickTrack(tempoBPM: tempoBPM))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: tempoBPM, level: .quarter))
    let periodSeconds = 60.0 / tempoBPM
    let frameSeconds = 1.0 / obs.frameRate
    for (previous, next) in zip(candidate.beats, candidate.beats.dropFirst()) {
      #expect(next.gridIndex == previous.gridIndex + 1, "skipped a grid position")
      let interval = next.time - previous.time
      #expect(
        abs(interval - periodSeconds) <= frameSeconds + 1e-9,
        "interval \(interval) s is not within one frame of the \(periodSeconds) s period")
    }
  }

  // MARK: - AC #3: metrical-level selector

  @Test func metricalLevelSelectorPrefersCorrectLevelOnPlantedClick() throws {
    let obs = try Self.stubObservations(Self.clickTrack())
    let selection = try #require(
      MetricalLevelSelector.select(observations: obs, tempoBPM: Self.tempoBPM))

    #expect(selection.chosen.metricalLevel == .quarter)
    #expect(selection.scoreByLevel.keys.contains(.quarter))
    #expect(selection.scoreByLevel.keys.contains(.half))
    #expect(selection.scoreByLevel.keys.contains(.double))
    let quarterScore = selection.scoreByLevel[.quarter] ?? 0
    let halfScore = selection.scoreByLevel[.half] ?? 0
    let doubleScore = selection.scoreByLevel[.double] ?? 0
    #expect(
      quarterScore > halfScore,
      "quarter \(quarterScore) <= half \(halfScore) on a planted-quarter click")
    #expect(
      quarterScore > doubleScore,
      "quarter \(quarterScore) <= double \(doubleScore) on a planted-quarter click")
  }

  @Test(arguments: [120.0, 124.0, 126.0, 128.0, 130.0, 140.0, 150.0, 174.0])
  func selectorPicksQuarterOnExactTempoClicks(tempoBPM: Double) throws {
    let obs = try Self.stubObservations(Self.clickTrack(tempoBPM: tempoBPM))
    let selection = try #require(
      MetricalLevelSelector.select(observations: obs, tempoBPM: tempoBPM))
    #expect(
      selection.chosen.metricalLevel == .quarter,
      "picked \(selection.chosen.metricalLevel) at \(tempoBPM) BPM, scores \(selection.scoreByLevel)"
    )
  }

  @Test func selectorPicksDoubleWhenSeededAtHalfTempo() throws {
    // 120 BPM clicks seeded at 60 BPM: the double level is the true grid.
    let obs = try Self.stubObservations(Self.clickTrack())
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 60))
    #expect(selection.chosen.metricalLevel == .double)
    #expect(selection.chosen.tempoBPM == 120)
    let doubleScore = try #require(selection.scoreByLevel[.double])
    let quarterScore = try #require(selection.scoreByLevel[.quarter])
    let halfScore = try #require(selection.scoreByLevel[.half])
    #expect(doubleScore > 0.9, "double \(doubleScore)")
    #expect(abs(quarterScore) < 0.1, "quarter \(quarterScore)")
    #expect(abs(halfScore) < 0.1, "half \(halfScore)")
  }

  @Test func selectorPicksQuarterOnAlternatingAmplitude() throws {
    let obs = try Self.stubObservations(Self.clickTrack(amplitudes: [1.0, 0.9]))
    let selection = try #require(
      MetricalLevelSelector.select(observations: obs, tempoBPM: Self.tempoBPM))
    #expect(
      selection.chosen.metricalLevel == .quarter,
      "picked \(selection.chosen.metricalLevel), scores \(selection.scoreByLevel)")
  }

  // MARK: - Decoder drift, duplicates, gaps, downbeats

  @Test func slightlyWrongSeedDoesNotDriftOverFiveMinutes() throws {
    // 128 BPM clicks decoded at 127.7 BPM: the seed period is about 0.11
    // frame too long per beat. Over the 640 beats in five minutes that sums
    // to more than a full period, so a decoder that does not re-anchor on
    // the beats it finds would skip or duplicate beats.
    let plantedBPM = 128.0
    let obs = try Self.stubObservations(
      Self.clickTrack(tempoBPM: plantedBPM, durationSeconds: 300))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 127.7, level: .quarter))
    let plantedPeriod = 60.0 / plantedBPM
    #expect(candidate.beats.count > 600)
    for (previous, next) in zip(candidate.beats, candidate.beats.dropFirst()) {
      #expect(next.gridIndex == previous.gridIndex + 1, "skipped a beat at \(next.time) s")
      let interval = next.time - previous.time
      #expect(interval > 0, "duplicate beat at \(next.time) s")
      #expect(
        abs(interval - plantedPeriod) <= 0.5 * plantedPeriod,
        "interval \(interval) s at \(next.time) s is off the \(plantedPeriod) s period")
    }
  }

  @Test func decoderNeverEmitsTheSameFrameTwice() throws {
    // Peaks every 100 frames decoded at a 50-frame period: an empty
    // prediction between peaks must not reach back to the previous peak.
    var beat = [Float](repeating: 0, count: 300)
    for frame in [50, 150, 250] { beat[frame] = 1 }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    let times = candidate.beats.map(\.time)
    #expect(times == [0.5, 1.5, 2.5])
    #expect(candidate.beats.map(\.gridIndex) == [0, 2, 4])
    // Five predicted positions; the two empty ones score 0.
    #expect(candidate.predictedPositionCount == 5)
  }

  // MARK: - Admissible first frames and the terminal stop

  /// One beat at `frame` with value `value`, over `count` frames.
  static func peaks(_ entries: [(frame: Int, value: Float)], count: Int) -> [Float] {
    var beat = [Float](repeating: 0, count: count)
    for entry in entries { beat[entry.frame] = entry.value }
    return beat
  }

  @Test func decoderFindsFirstBeatInTrailingPartialPeriod() throws {
    // 190 frames at a 100-frame period (60 BPM): the second search period is
    // partial. Frame f is admissible while f + 75 <= 190, so frames up to 115
    // can seed the decoder.
    for (frame, expectedTime) in [(110, 1.10), (115, 1.15)] {
      let obs = Self.handBuilt(beat: Self.peaks([(frame, 1.0)], count: 190))
      let candidate = try #require(
        BarStateDecoder.decode(observations: obs, tempoBPM: 60, level: .quarter),
        "peak at frame \(frame) did not decode")
      #expect(candidate.beats.map(\.time) == [expectedTime], "peak at frame \(frame)")
      #expect(candidate.predictedPositionCount == 1)
    }
  }

  @Test func decoderSeedIgnoresStrongerPeakWhoseWindowsDoNotFit() throws {
    // 190 frames at a 100-frame period. A stronger peak past the last
    // admissible frame (115) is never chosen as the seed, whether it sits
    // outside the seed search (180) or inside the seed's would-be on-window
    // (120).
    for strongerFrame in [180, 120] {
      let obs = Self.handBuilt(
        beat: Self.peaks([(110, 0.8), (strongerFrame, 1.0)], count: 190))
      let candidate = try #require(
        BarStateDecoder.decode(observations: obs, tempoBPM: 60, level: .quarter),
        "stronger peak at \(strongerFrame) suppressed the admissible seed")
      #expect(candidate.beats.map(\.time) == [1.10], "stronger peak at \(strongerFrame)")
      #expect(candidate.beats.map(\.beatSupport) == [0.8], "stronger peak at \(strongerFrame)")
    }
  }

  @Test func decoderStopsBeforeBeatWhoseOffWindowIsClipped() throws {
    // 190 frames at a 100-frame period: on-window [p - 25, p + 25), correction
    // tier [p - 15, p + 15). Case 1: the second prediction (110) sees frame
    // 134 only in the outer tier, so 134 is observed but the clock coasts and
    // the off-window stays on 110: [135, 185) fits and is empty. Score
    // (0.5 + 1.0) / 2. Case 2: frame 122 is in the correction tier, so the
    // off-window anchors on it: [147, 197) runs past the span, and decoding
    // stops before that position. Score 0.5 alone; scoring the clipped
    // off-window would have given (0.5 + 1.0) / 2.
    let coasting = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: Self.peaks([(10, 0.5), (134, 1.0)], count: 190)),
        tempoBPM: 60, level: .quarter))
    #expect(Self.frames(coasting) == [10, 134])
    #expect(coasting.beats.map(\.correctedClock) == [true, false])
    #expect(coasting.predictedPositionCount == 2)
    #expect(coasting.contrastScore == 0.75)

    let clipped = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: Self.peaks([(10, 0.5), (122, 1.0)], count: 190)),
        tempoBPM: 60, level: .quarter))
    #expect(Self.frames(clipped) == [10])
    #expect(clipped.predictedPositionCount == 1)
    #expect(clipped.contrastScore == 0.5)
  }

  @Test func selectorReturnsNilWhenSeedLevelCannotDecode() throws {
    // The selector needs a seed-level candidate as its baseline. Case 1: 30
    // frames are shorter than one 50-frame period at the 120 BPM seed. Case
    // 2: 190 frames with one peak at 120, seeded at 60 BPM: frame 120 is
    // past the last admissible quarter frame (115) but admissible at double
    // (120 + 37.5 <= 190). In both, double decodes and the selector still
    // returns nil, by design. Case 2 is also the inadmissible-evidence
    // contract (decoderReturnsNilWhenEvidenceIsOnlyPastSeedBoundary): frame
    // 120 passes the evidence rule but lies past every admissible quarter
    // seed window, so the quarter decode is nil, not a no-evidence
    // candidate.
    let cases: [(beat: [Float], tempoBPM: Double)] = [
      (Self.peaks([(5, 1.0)], count: 30), 120),
      (Self.peaks([(120, 1.0)], count: 190), 60),
    ]
    for (beat, tempoBPM) in cases {
      let obs = Self.handBuilt(beat: beat)
      #expect(BarStateDecoder.decode(observations: obs, tempoBPM: tempoBPM, level: .quarter) == nil)
      #expect(BarStateDecoder.decode(observations: obs, tempoBPM: tempoBPM, level: .double) != nil)
      #expect(MetricalLevelSelector.select(observations: obs, tempoBPM: tempoBPM) == nil)
    }
  }

  @Test func silenceGapLeavesNoBeatsAndAdvancesGridIndex() throws {
    // Clicks every 0.5 s with 5 s to 7 s zeroed: the planted clicks at 5.0,
    // 5.5, 6.0, and 6.5 s are gone, so the grid index skips four positions
    // across the gap (4.5 s is index g, 7.0 s is index g + 5).
    let obs = try Self.stubObservations(Self.clickTrack(silence: 5.0..<7.0))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: Self.tempoBPM, level: .quarter))
    let inGap = candidate.beats.filter { $0.time > 4.8 && $0.time < 6.8 }
    #expect(inGap.isEmpty, "decoder emitted beats inside the silence: \(inGap.map(\.time))")
    let jumps = zip(candidate.beats, candidate.beats.dropFirst()).map {
      $1.gridIndex - $0.gridIndex
    }
    #expect(jumps.filter { $0 != 1 } == [5], "grid index jumps \(jumps)")
  }

  @Test func downbeatPhaseFollowsPlantedDownbeatSupport() throws {
    var beat = [Float](repeating: 0, count: 900)
    var downbeat = [Float](repeating: 0, count: 900)
    for k in 0..<17 {
      let frame = 10 + 50 * k
      beat[frame] = 1
      downbeat[frame] = k % 4 == 2 ? 0.9 : 0.1
    }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat, downbeat: downbeat),
        tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.count >= 16)
    for beat in candidate.beats {
      #expect(
        beat.isDownbeat == (beat.gridIndex % 4 == 2),
        "beat \(beat.gridIndex) isDownbeat \(beat.isDownbeat)")
    }
  }

  @Test func decoderReturnsNilOnAllZeroObservations() {
    let obs = Self.handBuilt(beat: [Float](repeating: 0, count: 1_200))
    for level in MetricalLevel.allCases {
      #expect(BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: level) == nil)
    }
    #expect(MetricalLevelSelector.select(observations: obs, tempoBPM: 120) == nil)
  }

  @Test func decoderAndSelectorHonorShortCoverageWindow() throws {
    // Peaks every 50 frames over 1200 frames, but only 6 s (600 frames) of
    // coverage: nothing past the window may be read.
    var beat = [Float](repeating: 0, count: 1_200)
    for frame in stride(from: 10, to: 1_200, by: 50) { beat[frame] = 1 }
    let obs = FramewiseObservations(
      frameRate: 100, firstFrameOriginSeconds: 0, coverageWindowSeconds: 6.0,
      beatProbabilities: beat, downbeatProbabilities: beat.map { $0 * 0.5 },
      modelIdentifier: "test", frontendIdentifier: "test")
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.allSatisfy { $0.time < 6.0 }, "\(candidate.beats.map(\.time))")
    #expect(candidate.predictedPositionCount <= 12)
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    for sequence in [selection.chosen, selection.runnerUp] {
      #expect(sequence.beats.allSatisfy { $0.time < 6.0 }, "\(sequence.metricalLevel)")
    }
  }

  /// Hand-built observations at 100 fps with an explicit coverage window.
  static func coverageObservations(
    beat: [Float], coverageWindowSeconds: Double
  ) -> FramewiseObservations {
    FramewiseObservations(
      frameRate: 100, firstFrameOriginSeconds: 0,
      coverageWindowSeconds: coverageWindowSeconds,
      beatProbabilities: beat, downbeatProbabilities: beat.map { $0 * 0.5 },
      modelIdentifier: "test", frontendIdentifier: "test")
  }

  @Test(arguments: [
    // The stub's `frameCount * hopSize / sampleRate` for 29 frames at 44.1
    // kHz, hop 441: times 100 fps this is 28.999999999999996, which a plain
    // floor turns into 28.
    (29.0 * 441.0 / 44_100.0, 29),
    // A genuinely fractional window (28.5 frames) still floors.
    (0.285, 28),
    // A window longer than the arrays clips to frameCount.
    (1.0, 29),
  ])
  func usableFrameCountToleratesRoundoff(coverageWindowSeconds: Double, expected: Int) {
    let obs = Self.coverageObservations(
      beat: [Float](repeating: 0, count: 29), coverageWindowSeconds: coverageWindowSeconds)
    #expect(obs.usableFrameCount == expected)
  }

  @Test func decoderKeepsFinalPositionThatFlooringWouldDrop() throws {
    // 116 frames at 150 BPM (40-frame period, Q = 10). Clicks at 6, 46, and
    // 86: the position at 86 is admissible only while 86 + 3Q = 116 <=
    // usableFrames. The stub-style coverage `116 * 441 / 44100` s times 100
    // fps is 115.99999999999999, so flooring would give 115 and drop the
    // third click.
    let beat = Self.train([6, 46, 86], count: 116)
    let coverage = 116.0 * 441.0 / 44_100.0
    #expect(Int((coverage * 100).rounded(.down)) == 115, "fixture no longer bites")
    let obs = Self.coverageObservations(beat: beat, coverageWindowSeconds: coverage)
    #expect(obs.usableFrameCount == 116)
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 150, level: .quarter))
    #expect(Self.frames(candidate) == [6, 46, 86])
    #expect(candidate.predictedPositionCount == 3)

    // Control: a genuinely shorter window (115.5 frames floors to 115)
    // stops before the third position.
    let short = Self.coverageObservations(beat: beat, coverageWindowSeconds: 1.155)
    #expect(short.usableFrameCount == 115)
    let shortCandidate = try #require(
      BarStateDecoder.decode(observations: short, tempoBPM: 150, level: .quarter))
    #expect(Self.frames(shortCandidate) == [6, 46])
    #expect(shortCandidate.predictedPositionCount == 2)
  }

  @Test func selectorBreaksContrastTiesTowardQuarter() throws {
    // Every frame at 1.0: on-beat and off-beat support are equal, so every
    // level scores 0 and the tie order (quarter, half, double) decides.
    let obs = Self.handBuilt(beat: [Float](repeating: 1, count: 1_200))
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    #expect(selection.scoreByLevel.values.allSatisfy { $0 == 0 }, "\(selection.scoreByLevel)")
    #expect(selection.chosen.metricalLevel == .quarter)
    #expect(selection.chosen.evidence == CandidateBeatSequence.Evidence.none)
    #expect(selection.runnerUp.metricalLevel == .half)
  }

  // MARK: - Local evidence, two tiers, coasting, and reacquisition
  //
  // Hand-built at 100 fps. Amplitudes are observation-space values (stub
  // units after span normalization), not PCM amplitudes. At period 50 the
  // on-window is [p - 12.5, p + 12.5), the correction tier [p - 7.5, p + 7.5),
  // and the off-window [a + 12.5, a + 37.5) for committed anchor a.

  /// Frames `10 + 50k` for `k` in `indices`.
  static func grid50(_ indices: some Sequence<Int>) -> [Int] {
    indices.map { 10 + 50 * $0 }
  }

  @Test(arguments: [Float(0.01), 0.05, 0.2])
  func decoderPreservesGapOverPositiveFloor(floor: Float) throws {
    // 24 clicks at 1.0 with clicks 10, 11, and 12 removed, over a positive
    // floor. The floor has prominence 0 against its own median, so the gap
    // positions are prediction-only: no beat, the clock coasts, and the
    // returning click lands exactly on the prediction, in the correction
    // tier, with no reacquisition.
    let kept = Array(0..<10) + Array(13..<24)
    let obs = Self.handBuilt(beat: Self.train(Self.grid50(kept), floor: floor, count: 1_200))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter))
    #expect(candidate.evidence == .observed)
    #expect(Self.frames(candidate) == Self.grid50(kept))
    #expect(candidate.beats.map(\.gridIndex) == kept)
    #expect(candidate.beats.allSatisfy { $0.correctedClock })
    #expect(candidate.reacquisitionCount == 0)
    #expect(candidate.predictedPositionCount == 24)
    // 21 click positions score 1 - floor; the 3 gap positions score
    // floor - floor = 0.
    #expect(abs(candidate.contrastScore - 21 * (1 - floor) / 24) < 1e-5)
    #expect(candidate.decoderIdentifier == "bar-state-decoder.v2.local-evidence")
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    #expect(selection.chosen.metricalLevel == .quarter, "\(selection.scoreByLevel)")
    // The JointTempoPhaseFit keptFraction assertion lives with the fitter
    // (Story 15.7), which this story does not contain.
  }

  /// The review counterexample: clicks at 10, 60, 110, then 260 to 560 (160 and
  /// 210 missing), a noise frame at 220, and optionally a second one at 270.
  static func rollbackFixture(secondNoise: Bool) -> FramewiseObservations {
    var beat = Self.train(
      [10, 60, 110] + Array(stride(from: 260, through: 560, by: 50)), count: 620)
    beat[220] = 0.5
    if secondNoise { beat[270] = 0.5 }
    return Self.handBuilt(beat: beat)
  }

  @Test func decoderRollsBackUnconfirmedReacquisition() throws {
    // At prediction 210 (after the prediction-only position 160) the noise at
    // 220 is outer-tier, so the decoder re-anchors provisionally and predicts
    // 270. The click at 260 is outside that correction tier [262.5, 277.5),
    // so nothing confirms: the clock rolls back to 260, 220 stays an ordinary
    // coasted beat, and the click at 260 corrects the clock.
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.rollbackFixture(secondNoise: false), tempoBPM: 120, level: .quarter))
    #expect(
      Self.frames(candidate) == [10, 60, 110, 220] + Array(stride(from: 260, through: 560, by: 50)))
    #expect(candidate.beats.map(\.gridIndex) == [0, 1, 2] + Array(4...11))
    #expect(
      candidate.beats.map(\.correctedClock) == [true, true, true, false]
        + Array(repeating: true, count: 7))
    #expect(candidate.reacquisitionCount == 0)
    // 12 positions (10 to 560 every 50): ten clicks score 1, the empty 160
    // scores 0, and 210 scores 0.5 with its off-window on 210, not 220.
    #expect(candidate.predictedPositionCount == 12)
    #expect(abs(candidate.contrastScore - 10.5 / 12) < 1e-6)
    // The fit outcome (120 BPM, the 220 beat trimmed, keptFraction 10/11)
    // is asserted with the fitter in Story 15.7.
  }

  @Test func decoderConfirmsWrongReacquisitionOnTwoAlignedTransients() throws {
    // Known limit, pinned as a tripwire (follow-up 4 owns a real
    // reacquisition hypothesis): a second noise frame at 270, one period
    // after 220, lands on the provisional prediction and confirms the wrong
    // reacquisition. The clock is then 10 frames late for good: 270 takes
    // the 260 click's position, and the real clicks from 310 on sit 10
    // frames early in the outer tier, emitted with the clock coasting. A
    // change in this behaviour must be deliberate.
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.rollbackFixture(secondNoise: true), tempoBPM: 120, level: .quarter))
    #expect(candidate.reacquisitionCount == 1)
    #expect(
      Self.frames(candidate) == [10, 60, 110, 220, 270]
        + Array(stride(from: 310, through: 560, by: 50)))
    #expect(candidate.beats.map(\.gridIndex) == [0, 1, 2] + Array(4...11))
    #expect(
      candidate.beats.map(\.correctedClock) == Array(repeating: true, count: 5)
        + Array(repeating: false, count: 6))
    // 12 positions: 10, 60, 110 score 1; 160 scores 0; 210 scores 0.5 (its
    // off-window on the confirmed 220); 270 scores 1 (the full on-window
    // holds the 260 click); 320 to 570 score 1 each.
    #expect(candidate.predictedPositionCount == 12)
    #expect(abs(candidate.contrastScore - 10.5 / 12) < 1e-6)
  }

  @Test(arguments: [Float(0.01), 0.5, 1.0])
  func decoderReturnsNoEvidenceCandidateOnPositiveConstant(level: Float) throws {
    let obs = Self.handBuilt(beat: [Float](repeating: level, count: 400))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter))
    #expect(candidate.evidence == CandidateBeatSequence.Evidence.none)
    #expect(candidate.beats.isEmpty)
    #expect(candidate.contrastScore == 0)
    #expect(candidate.meanBeatSupport == 0)
    #expect(candidate.downbeatPhaseUnique == false)
    #expect(candidate.reacquisitionCount == 0)
    // Bookkeeping positions 0, 50, ..., 350 (p + 37.5 <= 400).
    #expect(candidate.predictedPositionCount == 8)
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    #expect(selection.chosen.metricalLevel == .quarter)
    #expect(selection.scoreByLevel == [.quarter: 0, .half: 0, .double: 0])
    // The fitter abstaining on this candidate is asserted in Story 15.7.
  }

  @Test func decoderReturnsNoEvidenceCandidateOnSubthresholdRamp() throws {
    // A linear ramp from 0.01 to 0.03 over 400 frames: no frame stands 0.03
    // above its background, so every level is a no-evidence candidate. The
    // contrast is signed and nonzero: on a rising ramp each position scores
    // the on-window's last frame minus the off-window's last frame, which is
    // -25, -50, and -12 frames of slope at quarter, half, and double. The
    // least negative wins, so the selector picks double: a no-evidence
    // quarter baseline does not by itself keep the quarter level on a
    // nonconstant stream.
    let slope: Float = 0.02 / 399
    let beat = (0..<400).map { 0.01 + slope * Float($0) }
    let obs = Self.handBuilt(beat: beat)
    for level in MetricalLevel.allCases {
      let candidate = try #require(
        BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: level))
      #expect(candidate.evidence == CandidateBeatSequence.Evidence.none, "\(level)")
      #expect(candidate.beats.isEmpty, "\(level)")
    }
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    let quarter = try #require(selection.scoreByLevel[.quarter])
    let half = try #require(selection.scoreByLevel[.half])
    let double = try #require(selection.scoreByLevel[.double])
    #expect(abs(quarter - -25 * slope) < 1e-6, "quarter \(quarter)")
    #expect(abs(half - -50 * slope) < 1e-6, "half \(half)")
    #expect(abs(double - -12 * slope) < 1e-6, "double \(double)")
    #expect(selection.chosen.metricalLevel == .double)
    #expect(selection.chosen.evidence == CandidateBeatSequence.Evidence.none)
  }

  @Test(arguments: [Float(0.05), 0.02])
  func decoderQuietTrainLimitUnderOneTransient(amplitude: Float) throws {
    // 30 quiet clicks over a zero floor plus one off-grid transient at 1.0
    // (frame 535, half a period after a click). The minimum passing
    // prominence is 0.03, so a 0.05 train is observed and a 0.02 train is
    // not: the stated quiet-train limit, pinned so a change is visible.
    var beat = Self.train(Self.grid50(0..<30), value: amplitude, count: 1_500)
    beat[535] = 1.0
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(candidate.evidence == .observed)
    if amplitude == 0.05 {
      #expect(Self.frames(candidate) == Self.grid50(0..<30))
      #expect(candidate.beats.map(\.gridIndex) == Array(0..<30))
      // 29 positions score 0.05; the one whose off-window holds the
      // transient (510) scores 0.05 - 1.0.
      #expect(candidate.predictedPositionCount == 30)
      #expect(abs(candidate.contrastScore - 0.5 / 30) < 1e-6)
      // Known limit (follow-up 4): JointTempoPhaseFit's amplitude gate
      // (minSupportScore on span-normalized support) still rejects this
      // correctly decoded quiet train. Asserted with the fitter in 15.7.
    } else {
      // Only the transient is observed; it seeds the grid, and the quiet
      // clicks sit half a period off every prediction.
      #expect(Self.frames(candidate) == [535])
      #expect(candidate.predictedPositionCount == 19)
      #expect(abs(candidate.contrastScore - (0.98 - 18 * 0.02) / 19) < 1e-6)
    }
  }

  @Test func decoderAdaptsAcrossLoudToQuietSection() throws {
    // 16 beats at 1.0 then 16 at 0.08 over a 0.01 floor. The background is
    // local, so the quiet section is judged against its own floor rather
    // than against the loud onsets.
    var beat = Self.train(Self.grid50(0..<16), floor: 0.01, count: 1_600)
    for frame in Self.grid50(16..<32) { beat[frame] = 0.08 }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(Self.frames(candidate) == Self.grid50(0..<32))
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<32))
  }

  @Test func decoderPrefersBeatNearPredictionOverStrongerDistractor() throws {
    // The click at 410 is weakened to 0.6 and a 0.9 distractor sits at 420
    // (0.2 period late), both inside the on-window [397.5, 422.5). The
    // correction tier [402.5, 417.5) is searched first and its 0.6 passes.
    var beat = Self.train(Self.grid50(0..<16), count: 800)
    beat[410] = 0.6
    beat[420] = 0.9
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(Self.frames(candidate) == Self.grid50(0..<16))
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<16))
    let weak = try #require(candidate.beats.first { $0.gridIndex == 8 })
    #expect(weak.beatSupport == 0.6)
    #expect(weak.correctedClock)
  }

  @Test func decoderEmitsButDoesNotCorrectBeyondBound() throws {
    // The click at 410 is moved to 420 (0.2 period late): outside the
    // correction tier, inside the on-window. It is emitted at its true frame
    // without moving the clock, so the next prediction is 460, where the
    // next click lands in the correction tier. Had the clock moved to 420,
    // 460 would have been 10 frames early and outer-tier.
    var expected = Self.grid50(0..<16)
    expected[8] = 420
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: Self.train(expected, count: 800)),
        tempoBPM: 120, level: .quarter))
    #expect(Self.frames(candidate) == expected)
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<16))
    #expect(candidate.beats[8].correctedClock == false)
    #expect(candidate.beats[9].correctedClock)
    #expect(candidate.reacquisitionCount == 0)
  }

  @Test func decoderReacquiresAfterGapWithWrongSeed() throws {
    // 128 BPM clicks (46.875 frames) decoded at 127.7 BPM (46.985 frames),
    // with clicks 16 to 115 removed. Coasting 101 periods from the click at
    // 713 predicts 5458.5, so the returning click at 5448 is 10.5 frames
    // early: outside the 7.05-frame correction tier, inside the 11.75-frame
    // on-window. It follows a prediction-only position, so it is provisional;
    // the next click (5494) lands 1.0 frame from the provisional prediction
    // (5495.0), inside the 2.35-frame confirmation tolerance, and confirms.
    // A gap long enough for the error to exceed a quarter period would put
    // the returning click outside the on-window and can displace the grid
    // index by one, which reacquisition does not repair.
    let clickFrame = { (k: Int) in Int((10 + 46.875 * Double(k)).rounded()) }
    let kept = Array(0..<16) + Array(116..<140)
    let obs = Self.handBuilt(beat: Self.train(kept.map(clickFrame), count: 6_600))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 127.7, level: .quarter))
    #expect(Self.frames(candidate) == kept.map(clickFrame))
    #expect(candidate.beats.map(\.gridIndex) == kept)
    #expect(candidate.reacquisitionCount == 1)
    let returning = candidate.beats.filter { $0.gridIndex >= 116 }
    #expect(returning.allSatisfy { $0.correctedClock })
  }

  @Test func decoderStaysStableUnderAlternatingEarlyLatePeaks() throws {
    // Clicks alternately 2 frames early and late around an exact 50-frame
    // grid. Every residual (4 frames) is inside the correction tier, so each
    // click is observed and moves the clock, and the next prediction
    // (frame + 50) stays within 2 frames of the true grid.
    let truth = Self.grid50(0..<32)
    let clicks = truth.enumerated().map { $0.element + ($0.offset.isMultiple(of: 2) ? -2 : 2) }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: Self.train(clicks, count: 1_610)),
        tempoBPM: 120, level: .quarter))
    let observed = Self.frames(candidate)
    #expect(observed == clicks)
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<32))
    #expect(candidate.beats.allSatisfy { $0.correctedClock })
    for (frame, nextTruth) in zip(observed, truth.dropFirst()) {
      #expect(abs(frame + 50 - nextTruth) <= 2)
    }
    // The fitted tempo (planted 120 BPM within 0.1) is asserted with the
    // fitter in Story 15.7.
  }

  @Test func decoderTiePrefersFrameNearestPrediction() throws {
    // The click at 310 is replaced by two equal 0.8 maxima inside its
    // correction tier [302.5, 317.5). Nearer wins; a symmetric pair resolves
    // to the earlier frame.
    for (pair, winner) in [((305, 313), 313), ((306, 314), 306)] {
      var beat = Self.train(Self.grid50(0..<12), count: 600)
      beat[310] = 0
      beat[pair.0] = 0.8
      beat[pair.1] = 0.8
      let candidate = try #require(
        BarStateDecoder.decode(
          observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
      let observed = Self.frames(candidate)
      #expect(observed[6] == winner, "pair \(pair): \(observed)")
      #expect(!observed.contains(pair.0 == winner ? pair.1 : pair.0))
      #expect(candidate.beats.map(\.gridIndex) == Array(0..<12))
    }
  }

  @Test func decoderSeedIgnoresQuietLeadingFloor() throws {
    // Two seconds of a 0.015 / 0.02 / 0.025 floor (median 0.02, MAD 0.005,
    // so prominence at most 0.005), then clicks from frame 210. No leading
    // window passes, so the first observed beat is the first click.
    let floorPattern: [Float] = [0.015, 0.02, 0.025]
    var beat = (0..<1_000).map { floorPattern[$0 % 3] }
    let clicks = (0..<16).map { 210 + 50 * $0 }
    for frame in clicks { beat[frame] = 1 }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(Self.frames(candidate).first == 210)
    #expect(Self.frames(candidate) == clicks)
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<16))
  }

  @Test func decoderSyncopatedOffbeatDoesNotBlockBeat() throws {
    // On-beat clicks at 0.6 with louder 0.9 off-beat events half a period
    // later (from frame 85, so the first seed window holds only the on-beat).
    // Every on-beat is observed; the off-beats fall in the off-windows, so
    // the contrast is negative. Ranking that is the selector's concern, not
    // the decoder's.
    var beat = Self.train(Self.grid50(0..<24), value: 0.6, count: 1_200)
    for k in 1..<24 { beat[35 + 50 * k] = 0.9 }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(Self.frames(candidate) == Self.grid50(0..<24))
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<24))
    // The seed scores 0.6; the other 23 positions score 0.6 - 0.9.
    #expect(candidate.predictedPositionCount == 24)
    #expect(abs(candidate.contrastScore - (0.6 - 23 * 0.3) / 24) < 1e-5)
    #expect(candidate.contrastScore < 0)
  }

  @Test func decoderAnchorsOffWindowOnCommittedClock() throws {
    // 190 frames at period 100 over a 0.02 background. Frame 85 (0.04) has
    // prominence 0.02, below 0.03, so position 110 is prediction-only and
    // its off-window anchors on 110: [135, 185) holds frame 170. Score
    // (0.98 + (0.04 - 1.0)) / 2 = 0.01. Anchored on the rejected frame 85,
    // the off-window [110, 160) would have given 0.5.
    var beat = [Float](repeating: 0.02, count: 190)
    beat[10] = 1.0
    beat[85] = 0.04
    beat[170] = 1.0
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 60, level: .quarter))
    #expect(Self.frames(candidate) == [10])
    #expect(candidate.predictedPositionCount == 2)
    #expect(abs(candidate.contrastScore - 0.01) < 1e-6, "\(candidate.contrastScore)")
  }

  @Test func decoderThresholdEquality() throws {
    // Dyadic values so the rule is evaluated exactly: a 0.125 / 0.25 / 0.375
    // background has median 0.25 and MAD 0.125, so the threshold is 0.375.
    // Frame 60 at 0.625 has prominence exactly 0.375 and is observed
    // (inclusive rule); one ulp-scale step below (2^-10) is not.
    let background: [Float] = [0.125, 0.25, 0.375]
    for (value, expected) in [(Float(0.625), [10, 60]), (0.625 - 1.0 / 1_024, [10])] {
      var beat = (0..<400).map { background[$0 % 3] }
      beat[10] = 1.0
      beat[60] = value
      let candidate = try #require(
        BarStateDecoder.decode(
          observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
      #expect(Self.frames(candidate) == expected, "value \(value)")
      if expected.count == 2 {
        #expect(candidate.beats[1].prominence == 0.375)
      }
    }
  }

  // MARK: - Downbeat phase by mean support

  @Test func downbeatPhaseIgnoresBeatCountAfterGap() throws {
    // Equal beats at grid indices 0, 1, 2, 3, 5, 6, 7: phase 0 has one beat
    // and phases 1 to 3 two each, all with the same downbeat support. A
    // summed support would pick phase 1; the mean ties and keeps phase 0.
    let kept = [0, 1, 2, 3, 5, 6, 7]
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: Self.train(Self.grid50(kept), value: 0.1, count: 400)),
        tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.map(\.gridIndex) == kept)
    #expect(candidate.beats.filter(\.isDownbeat).map(\.gridIndex) == [0])
    #expect(candidate.downbeatPhaseUnique == false)
  }

  @Test func downbeatPhasePrefersStrongerMeanOverMoreBeats() throws {
    // Ten phase-0 beats with downbeat 0.6 and one phase-1 beat with 0.9.
    let phaseZero = Array(stride(from: 0, through: 36, by: 4))
    let indices = [0, 1] + phaseZero.dropFirst()
    let beat = Self.train(Self.grid50(indices), count: 1_850)
    var downbeat = [Float](repeating: 0, count: 1_850)
    for frame in Self.grid50(phaseZero) { downbeat[frame] = 0.6 }
    downbeat[60] = 0.9
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat, downbeat: downbeat),
        tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.map(\.gridIndex) == indices)
    #expect(candidate.beats.filter(\.isDownbeat).map(\.gridIndex) == [1])
    #expect(candidate.downbeatPhaseUnique)
  }

  @Test func downbeatPhaseUniqueOnUnequalStubAmplitudes() throws {
    // Beats 0.2, 0.4, 0.6, 0.8 repeating with the stub's D = 0.5 * B. Phase
    // 3 has the highest mean and is a unique winner, but that is beat
    // amplitude, not bar evidence: the stub channel carries none.
    let amplitudes: [Float] = [0.2, 0.4, 0.6, 0.8]
    var beat = [Float](repeating: 0, count: 800)
    for k in 0..<16 { beat[10 + 50 * k] = amplitudes[k % 4] }
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: Self.handBuilt(beat: beat), tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.map(\.gridIndex) == Array(0..<16))
    #expect(candidate.beats.filter(\.isDownbeat).map(\.gridIndex) == [3, 7, 11, 15])
    #expect(candidate.downbeatPhaseUnique)
  }

  // MARK: - AC #5: Public surface unchanged

  @Test func signalWeightsBeatGridStaysPlaceholder() {
    // The Framewise types are `internal`; this test touches each once so a
    // reader finds them by grep. It does not detect a promotion to `public`
    // (the test target imports with `@testable`, which sees both).
    _ = FramewiseObservations.self
    _ = CandidateBeatSequence.self
    _ = MetricalLevel.self
    _ = MetricalLevelSelection.self
    _ = DSPStubObservationProducer.self

    // SignalSource.beatGrid and SignalWeights.beatGrid remain placeholders.
    let weights = SignalWeights.default
    #expect(weights.beatGrid == 1.0, "SignalWeights.beatGrid drifted off its placeholder default")
  }

  // MARK: - Shipping beat-grid path on the same fixture

  @Test func beatGridAnalyzerPublicPathUnchangedOnClickFixture() throws {
    // The Framewise path has no caller in AudioAnalysisService; the public
    // beat-grid path still recovers the click fixture at 120 BPM.
    var options = AudioAnalysisService.Options()
    options.intensity = .level3
    let grid = try #require(
      try AudioAnalysisService.analyzeBeatGrid(decoded: Self.clickTrack(), options: options))
    #expect(grid.beats.count >= 20 && grid.beats.count <= 24)
    #expect(grid.estimatedTempo > 119 && grid.estimatedTempo < 121)
  }
}
