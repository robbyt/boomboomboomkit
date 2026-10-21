//
//  JointTempoPhaseFitTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.7 (Epic 15, Phase 7): regression tests for the joint
//  tempo and phase fit with sub-frame parabolic peak interpolation and
//  outlier trimming.
//
//  Measured claim: on exact-tempo single-impulse clicks at 44.1 kHz the
//  fit recovers tempo within 0.1 BPM and its phase anchor sits about one
//  hop early (measured -10.7 ms at 120 BPM, -11.4 ms at 128 BPM, hop 441;
//  the 120 and 128 BPM cases print the value). Interpolation does not
//  remove that offset; the tests pin it rather than claim it away. 128 BPM
//  (a period of 46.875 frames) is covered alongside 120 BPM (50 frames).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Joint tempo + phase fit (Story 15.7)")
struct JointTempoPhaseFitTests {

  private static let sampleRate: Double = 44_100
  private static let hopSize = 441
  private static let tempoBPM: Double = 120.0
  private static let durationSeconds: Double = 12.0
  private static let hopMs = 1000.0 * Double(hopSize) / sampleRate

  /// Exact-tempo click track: beat `k` (k >= 1) starts at sample
  /// `round(k * 60 / tempoBPM * sampleRate) + offsetSamples`.
  private func syntheticClickTrack(
    tempoBPM: Double = tempoBPM,
    offsetSamples: Int = 0,
    waveform: ClickShape = .singleImpulse
  ) -> FeatureSubstrate.DecodedAudio {
    let totalCount = Int(Self.sampleRate * Self.durationSeconds)
    var samples = [Float](repeating: 0, count: totalCount)
    for position in plantedBeatSamples(tempoBPM: tempoBPM, offsetSamples: offsetSamples)
    where position + waveform.sampleCount < totalCount {
      for j in 0..<waveform.sampleCount {
        samples[position + j] = Float(exp(-Double(j) / waveform.decayTau))
      }
    }
    return FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: Self.sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
  }

  private func plantedBeatSamples(tempoBPM: Double, offsetSamples: Int = 0) -> [Int] {
    let totalCount = Int(Self.sampleRate * Self.durationSeconds)
    let periodSamples = 60.0 / tempoBPM * Self.sampleRate
    return (1...).lazy
      .map { Int((Double($0) * periodSamples).rounded()) + offsetSamples }
      .prefix { $0 < totalCount - 1 }
      .map { $0 }
  }

  enum ClickShape {
    case singleImpulse
    case exp64
    case kick500

    var sampleCount: Int {
      switch self {
      case .singleImpulse: return 1
      case .exp64: return 64
      case .kick500: return 500
      }
    }
    var decayTau: Double {
      switch self {
      case .singleImpulse: return 1.0
      case .exp64: return 10.0
      case .kick500: return 80.0
      }
    }
  }

  private func fitForClickTrack(
    tempoBPM: Double = tempoBPM,
    offsetSamples: Int = 0,
    waveform: ClickShape = .singleImpulse
  ) throws -> (fit: FittedTempoPhase, selection: MetricalLevelSelection, firstPlantedBeat: Double) {
    let decoded = syntheticClickTrack(
      tempoBPM: tempoBPM, offsetSamples: offsetSamples, waveform: waveform)
    let observations = try #require(
      DSPStubObservationProducer(hopSize: Self.hopSize).produce(decoded: decoded))
    let selection = try #require(
      MetricalLevelSelector.select(observations: observations, tempoBPM: tempoBPM))
    let fit = try #require(
      JointTempoPhaseFit.fit(observations: observations, selection: selection))
    let firstPlanted = Double(
      plantedBeatSamples(tempoBPM: tempoBPM, offsetSamples: offsetSamples)[0])
    return (fit, selection, firstPlanted / Self.sampleRate)
  }

  /// Hand-built candidate at 120 BPM with zero-valued observations, so
  /// sub-frame refinement leaves every time unchanged.
  private func handBuiltFit(
    times: [Double], gridIndices: [Int]? = nil, support: Float = 1
  ) -> FittedTempoPhase? {
    let indices = gridIndices ?? Array(times.indices)
    let beats = zip(times, indices).map { time, index in
      CandidateBeatSequence.Beat(
        time: time, gridIndex: index, beatSupport: support, downbeatSupport: 0,
        prominence: support, correctedClock: true, isDownbeat: index % 4 == 0)
    }
    let candidate = CandidateBeatSequence(
      beats: beats, tempoBPM: 120, metricalLevel: .quarter, meanBeatSupport: support,
      contrastScore: support, predictedPositionCount: (indices.last ?? 0) + 1,
      evidence: .observed, downbeatPhaseUnique: false, reacquisitionCount: 0,
      decoderIdentifier: BarStateDecoder.decoderIdentifier)
    let observations = FramewiseObservations(
      frameRate: 100, firstFrameOriginSeconds: 0, coverageWindowSeconds: 20,
      beatProbabilities: [Float](repeating: 0, count: 2_000),
      downbeatProbabilities: [Float](repeating: 0, count: 2_000),
      modelIdentifier: "test", frontendIdentifier: "test")
    return JointTempoPhaseFit.fit(observations: observations, candidate: candidate)
  }

  // MARK: - AC #1: tempo and phase on a clean click

  @Test(arguments: [120.0, 128.0])
  func fitRecoversTempoAndPhaseOnPlantedClick(tempoBPM: Double) throws {
    let (fit, _, firstBeat) = try fitForClickTrack(tempoBPM: tempoBPM)
    #expect(abs(fit.tempoBPM - tempoBPM) <= 0.1, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction >= 0.9, "keptFraction \(fit.keptFraction)")
    #expect(fit.supportScore > 0.3, "supportScore \(fit.supportScore)")
    #expect(fit.metricalLevel == .quarter)
    #expect(fit.frontendIdentifier == "bpmanalyzer-onset.v1")
    #expect(
      fit.observationModelIdentifier
        == DSPStubObservationProducer(hopSize: Self.hopSize).modelIdentifier)

    // The anchor carries the onset frontend's constant early offset: about
    // one hop on single-impulse clicks. Pin it to [-1.5, -0.5] hops so a
    // regression in either direction (toward the pre-15.3 ~-45 ms, or a
    // spurious late shift) fails.
    let signedResidualMs = (fit.phaseAnchorSeconds - firstBeat) * 1000.0
    print("Story 15.7 anchor residual at \(tempoBPM) BPM: \(signedResidualMs) ms")
    #expect(
      signedResidualMs >= -1.5 * Self.hopMs && signedResidualMs <= -0.5 * Self.hopMs,
      "anchor residual \(signedResidualMs) ms outside [-1.5, -0.5] hops (fit \(fit.phaseAnchorSeconds) vs planted \(firstBeat))"
    )
  }

  @Test(arguments: [120.0, 124.0, 126.0, 128.0, 130.0, 140.0, 150.0, 174.0])
  func fitReturnsResultAtExactTempos(tempoBPM: Double) throws {
    let (fit, selection, _) = try fitForClickTrack(tempoBPM: tempoBPM)
    #expect(selection.chosen.metricalLevel == .quarter)
    #expect(abs(fit.tempoBPM - tempoBPM) <= 0.1, "tempo \(fit.tempoBPM) at \(tempoBPM) BPM")
  }

  // MARK: - Kick-like fixture: fit stays within one hop of the decoder

  @Test func fitResidualStaysWithinOneHopOfIntegerFrameOnKickFixture() throws {
    // Signed residual against the planted grid on a kick-like 500-sample
    // exp-decay fixture. The decoder snaps to the 10 ms frame grid; the fit
    // places a line through the refined beats. On this waveform the
    // parabolic peak can sit inside the decay plateau, so the fit is not
    // required to beat the decoder, only to stay within one hop of it and
    // within 2 hops of the planted grid.
    let (fit, selection, _) = try fitForClickTrack(waveform: .kick500)
    let plantedPeriod = 60.0 / Self.tempoBPM
    func signedResidualMs(_ time: Double) -> Double {
      let phase = time / plantedPeriod
      return (phase - phase.rounded()) * plantedPeriod * 1000.0
    }
    let beats = selection.chosen.beats
    let integerResidualsMs = beats.map { signedResidualMs($0.time) }.sorted()
    let integerMedianMs = integerResidualsMs[integerResidualsMs.count / 2]
    let fitPeriod = 60.0 / fit.tempoBPM
    let fitResidualsMs = beats.map {
      signedResidualMs(fit.phaseAnchorSeconds + Double($0.gridIndex) * fitPeriod)
    }.sorted()
    let fitMedianMs = fitResidualsMs[fitResidualsMs.count / 2]

    #expect(
      abs(fitMedianMs) <= abs(integerMedianMs) + Self.hopMs,
      "fit median \(fitMedianMs) ms vs integer-frame median \(integerMedianMs) ms"
    )
    #expect(abs(fitMedianMs) <= 2 * Self.hopMs, "fit median residual \(fitMedianMs) ms")
  }

  // MARK: - AC #2: fit holds across a silence gap

  @Test func fitHoldsAcrossShortSilenceGap() throws {
    // 12 s of 120 BPM clicks with 5 s to 7 s zeroed. The decoder emits no
    // beats inside the gap and advances the grid index across it, so the
    // fit keeps every beat and stays on the planted grid.
    let sampleRate = Self.sampleRate
    let totalCount = Int(sampleRate * Self.durationSeconds)
    var samples = [Float](repeating: 0, count: totalCount)
    for position in plantedBeatSamples(tempoBPM: Self.tempoBPM) { samples[position] = 1.0 }
    for i in Int(5.0 * sampleRate)..<Int(7.0 * sampleRate) { samples[i] = 0 }
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let obs = try #require(
      DSPStubObservationProducer(hopSize: Self.hopSize).produce(decoded: decoded))
    let selection = try #require(
      MetricalLevelSelector.select(observations: obs, tempoBPM: Self.tempoBPM))
    #expect(selection.chosen.metricalLevel == .quarter)
    #expect(selection.chosen.beats.allSatisfy { $0.time < 4.8 || $0.time > 6.8 })
    let fit = try #require(JointTempoPhaseFit.fit(observations: obs, selection: selection))

    #expect(abs(fit.tempoBPM - Self.tempoBPM) <= 0.1, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 1.0, "keptFraction \(fit.keptFraction)")
    // Same constant offset as the clean click: within [-1.5, -0.5] hops of
    // the first planted beat at 0.5 s.
    let residualMs = (fit.phaseAnchorSeconds - 0.5) * 1000.0
    #expect(
      residualMs >= -1.5 * Self.hopMs && residualMs <= -0.5 * Self.hopMs,
      "phase anchor \(fit.phaseAnchorSeconds) is \(residualMs) ms from the planted 0.5 s")
  }

  // MARK: - AC #4: trimming rejects a fill-like disturbance

  @Test func trimRejectsFillLikeDisturbance() throws {
    // 12 s of 120 BPM clicks with off-grid pulses at 6.1, 6.3, and 6.7 s
    // (6.5 s is on the grid). The fit trims any beat the decoder placed on
    // a fill pulse and stays on the clean grid.
    let sampleRate = Self.sampleRate
    let totalCount = Int(sampleRate * Self.durationSeconds)
    var samples = [Float](repeating: 0, count: totalCount)
    for position in plantedBeatSamples(tempoBPM: Self.tempoBPM) { samples[position] = 1.0 }
    for offset in [0.1, 0.3, 0.5, 0.7] {
      let position = Int((6.0 + offset) * sampleRate)
      if position < totalCount { samples[position] = 1.0 }
    }
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
    )
    let obs = try #require(
      DSPStubObservationProducer(hopSize: Self.hopSize).produce(decoded: decoded))
    let selection = try #require(
      MetricalLevelSelector.select(observations: obs, tempoBPM: Self.tempoBPM))
    let fit = try #require(JointTempoPhaseFit.fit(observations: obs, selection: selection))

    #expect(abs(fit.tempoBPM - Self.tempoBPM) <= 0.5)
    let residualMs = (fit.phaseAnchorSeconds - 0.5) * 1000.0
    #expect(
      residualMs >= -1.5 * Self.hopMs && residualMs <= -0.5 * Self.hopMs,
      "phase anchor \(fit.phaseAnchorSeconds) drifted off the planted 0.5 s under the fill")
    #expect(fit.keptFraction >= 0.5)
  }

  // MARK: - Robust seed, minimum count, zero support, degenerate regression

  @Test func robustSeedIgnoresShiftedMinority() throws {
    // 20 beats at 120 BPM: 12 on the grid, 8 shifted by half a period. The
    // median seed lands on the majority and trimming drops the shifted 8.
    let shifted: Set<Int> = [1, 3, 5, 7, 9, 11, 13, 15]
    let times = (0..<20).map { g in 0.5 + 0.5 * Double(g) + (shifted.contains(g) ? 0.25 : 0) }
    let fit = try #require(handBuiltFit(times: times))
    #expect(abs(fit.tempoBPM - 120) < 1e-9, "tempo \(fit.tempoBPM)")
    #expect(abs(fit.phaseAnchorSeconds - 0.5) < 1e-9, "phase \(fit.phaseAnchorSeconds)")
    #expect(fit.keptFraction == 0.6)
  }

  @Test func fitAbstainsBelowMinimumBeatCount() {
    #expect(handBuiltFit(times: [0.01, 1.00]) == nil)
    let sevenBeats = (0..<7).map { 0.5 + 0.5 * Double($0) }
    #expect(handBuiltFit(times: sevenBeats) == nil)
    let eightBeats = (0..<8).map { 0.5 + 0.5 * Double($0) }
    #expect(handBuiltFit(times: eightBeats) != nil)
  }

  @Test func fitAbstainsOnZeroSupport() {
    let times = (0..<20).map { 0.5 + 0.5 * Double($0) }
    #expect(handBuiltFit(times: times, support: 0) == nil)
  }

  @Test func fitUsesGridIndexAcrossGaps() throws {
    // Beats at grid indices 0...4 and 9...13 (a four-position gap). The
    // regression is over grid index, so the gap does not compress the period.
    let indices = Array(0...4) + Array(9...13)
    let times = indices.map { 0.5 + 0.5 * Double($0) }
    let fit = try #require(handBuiltFit(times: times, gridIndices: indices))
    #expect(abs(fit.tempoBPM - 120) < 1e-9, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 1.0)
  }

  @Test func linearRegressionReturnsNilWhenDegenerate() {
    #expect(JointTempoPhaseFit.linearRegression(x: [1], y: [1]) == nil)
    #expect(JointTempoPhaseFit.linearRegression(x: [2, 2, 2], y: [1, 2, 3]) == nil)
    #expect(JointTempoPhaseFit.linearRegression(x: [0, 1, 2], y: [3, 2, 1]) == nil)
    let line = JointTempoPhaseFit.linearRegression(x: [0, 1, 2], y: [0.5, 1.0, 1.5])
    #expect(line?.period == 0.5)
    #expect(line?.phase == 0.5)
  }

  @Test func fitAbstainsWhenTrimDoesNotConverge() {
    // Review counterexample (finding E). The three trim passes keep
    // {1, 6...15}, then {0, 1, 5...15}, then {0...2, 5...15}; the loop ends
    // with the set still changing. Against the line refit on that last set
    // (about 121.987 BPM, kept fraction 0.875 before the fix) beat 7 sits
    // about -77.9 ms off, outside the 75 ms threshold. The final-line
    // validation sees the kept set change and abstains.
    let offsets = [
      0.090, 0.071, 0.118, -0.084, -0.103, 0.090, 0.001, -0.050, -0.002, 0.001, 0.023, 0.011,
      -0.056, -0.015, -0.016, 0.002,
    ]
    let times = offsets.enumerated().map { 0.5 + 0.5 * Double($0.offset) + $0.element }
    #expect(handBuiltFit(times: times) == nil)
  }

  @Test func trimDropsIsolatedDisplacedOnset() throws {
    // 20 exact-grid beats with beat 10 displaced by 0.2 period (100 ms,
    // past the 75 ms trim threshold). The seed's median offset ignores it,
    // the first pass drops it, and the refit on the other 19 is exact.
    var times = (0..<20).map { 0.5 + 0.5 * Double($0) }
    times[10] += 0.2 * 0.5
    let fit = try #require(handBuiltFit(times: times))
    #expect(fit.keptFraction == 0.95)
    #expect(abs(fit.tempoBPM - 120) < 1e-9, "tempo \(fit.tempoBPM)")
    #expect(abs(fit.phaseAnchorSeconds - 0.5) < 1e-9, "phase \(fit.phaseAnchorSeconds)")
  }

  // MARK: - Robust fallback seed (seed tempo off by 3.75 to 5 percent)

  /// 100 beats at exact `60 / beatBPM` spacing on grid indices 0...99,
  /// fitted against the 120 BPM seed of ``handBuiltFit(times:gridIndices:support:)``.
  private func offSeedFit(beatBPM: Double) -> FittedTempoPhase? {
    handBuiltFit(times: (0..<100).map { 0.5 + 60.0 / beatBPM * Double($0) })
  }

  @Test func fallbackSeedRecoversTempoFourPercentOffSeed() throws {
    // Beats at 115 BPM, seed 120 (4.2 percent off). Residuals against the
    // median-phase seed grow 21.7 ms per index, so it keeps only grid
    // indices 47 to 52 (six beats, under minKeptBeats). The robust
    // fallback seeds the exact line and every beat is kept.
    let fit = try #require(offSeedFit(beatBPM: 115))
    print("Story 15.7 fallback seed: 115 BPM beats under a 120 seed fit \(fit.tempoBPM) BPM")
    #expect(abs(fit.tempoBPM - 115) <= 0.01, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 1.0, "keptFraction \(fit.keptFraction)")
  }

  @Test func medianSeedRecoversTempoThreePercentOffSeed() throws {
    // Control: beats at 116.4 BPM, seed 120 (3 percent off). The median-phase
    // seed keeps ten central beats, the refit gives the true slope, and the
    // next pass keeps everything. The fallback is not used.
    let fit = try #require(offSeedFit(beatBPM: 116.4))
    #expect(abs(fit.tempoBPM - 116.4) <= 0.01, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 1.0, "keptFraction \(fit.keptFraction)")
  }

  @Test func fallbackSeedDoesNotRescueTempoOutsideContract() {
    // Beats at 113 BPM, seed 120 (5.8 percent off, outside
    // maxTempoDeviationFraction). The robust fallback line is rejected as a
    // seed and the median-phase seed keeps too few beats, so the fit abstains.
    #expect(offSeedFit(beatBPM: 113) == nil)
  }

  /// `count` beats at exact 115 BPM spacing from 0.5 s on grid indices
  /// 0..<count, the indices in `shifted` moved 0.25 s late, fitted against
  /// the 120 BPM seed of ``handBuiltFit(times:gridIndices:support:)``.
  private func shiftedOffSeedFit(count: Int, shifted: Set<Int>) -> FittedTempoPhase? {
    handBuiltFit(
      times: (0..<count).map { 0.5 + 60.0 / 115.0 * Double($0) + (shifted.contains($0) ? 0.25 : 0) }
    )
  }

  @Test func robustFallbackSeedSurvivesSymmetricOutliers() throws {
    // Review counterexample. 20 beats at 115 BPM under a 120 seed, eight of
    // them 0.25 s late, spread across the train. A least-squares seed keeps
    // the slope but moves its intercept from 0.5 to 0.6 s, which puts every
    // beat outside the 75 ms window. The pairwise-slope median and the
    // median phase stay on the twelve on-grid beats.
    let fit = try #require(
      shiftedOffSeedFit(count: 20, shifted: [0, 3, 5, 8, 11, 14, 16, 19]))
    print(
      "Story 15.7 robust fallback seed: symmetric outliers fit \(fit.tempoBPM) BPM, phase \(fit.phaseAnchorSeconds) s"
    )
    #expect(abs(fit.tempoBPM - 115) <= 0.01, "tempo \(fit.tempoBPM)")
    #expect(abs(fit.phaseAnchorSeconds - 0.5) <= 1e-6, "phase \(fit.phaseAnchorSeconds)")
    #expect(fit.keptFraction == 0.6, "keptFraction \(fit.keptFraction)")
  }

  @Test func robustFallbackSeedSurvivesTailOutliers() throws {
    // 40 beats at 115 BPM under a 120 seed, the last eight 0.25 s late.
    let fit = try #require(shiftedOffSeedFit(count: 40, shifted: Set(32..<40)))
    #expect(abs(fit.tempoBPM - 115) <= 0.01, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 0.8, "keptFraction \(fit.keptFraction)")
  }

  @Test func robustFallbackSeedSubsamplesLongTrains() throws {
    // 2,000 beats at 115 BPM under a 120 seed, the last 400 0.25 s late.
    // Above robustSeedSampleCount the slope median is taken over an even
    // subsample, which keeps the 20 percent outlier fraction.
    let fit = try #require(shiftedOffSeedFit(count: 2_000, shifted: Set(1_600..<2_000)))
    #expect(abs(fit.tempoBPM - 115) <= 0.01, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 0.8, "keptFraction \(fit.keptFraction)")
  }

  @Test func fitRejectsNoEvidenceCandidate() {
    // A no-evidence candidate (the decoder's answer on a constant stream)
    // has no beats; the minKeptBeats guard rejects it.
    let candidate = CandidateBeatSequence(
      beats: [], tempoBPM: 120, metricalLevel: .quarter, meanBeatSupport: 0, contrastScore: 0,
      predictedPositionCount: 8, evidence: .none, downbeatPhaseUnique: false,
      reacquisitionCount: 0, decoderIdentifier: BarStateDecoder.decoderIdentifier)
    let obs = FramewiseObservationsTests.handBuilt(beat: [Float](repeating: 0.5, count: 400))
    #expect(JointTempoPhaseFit.fit(observations: obs, candidate: candidate) == nil)
  }

  // MARK: - Fit outcomes on the Story 15.6 decoder fixtures

  @Test(arguments: [Float(0.01), 0.05, 0.2])
  func fitKeepsEveryBeatAcrossGapOverPositiveFloor(floor: Float) throws {
    // FramewiseObservationsTests.decoderPreservesGapOverPositiveFloor: 24
    // clicks at 1.0 with clicks 10, 11, and 12 removed, over a positive
    // floor. The decoder emits only click frames and jumps the grid index
    // across the gap, so the fit keeps every beat.
    let kept = Array(0..<10) + Array(13..<24)
    let obs = FramewiseObservationsTests.handBuilt(
      beat: FramewiseObservationsTests.train(
        FramewiseObservationsTests.grid50(kept), floor: floor, count: 1_200))
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    #expect(selection.chosen.metricalLevel == .quarter)
    let fit = try #require(JointTempoPhaseFit.fit(observations: obs, selection: selection))
    #expect(abs(fit.tempoBPM - 120) <= 0.1, "tempo \(fit.tempoBPM)")
    #expect(fit.keptFraction == 1.0, "keptFraction \(fit.keptFraction)")
  }

  @Test func fitTrimsUnconfirmedReacquisitionBeat() throws {
    // FramewiseObservationsTests.decoderRollsBackUnconfirmedReacquisition:
    // the noise frame at 220 is emitted at grid index 4 (predicted 210)
    // without moving the clock. It sits 100 ms off the line, past the 75 ms
    // threshold, so the fit trims it and keeps the ten clicks.
    let candidate = try #require(
      BarStateDecoder.decode(
        observations: FramewiseObservationsTests.rollbackFixture(secondNoise: false),
        tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.count == 11)
    let fit = try #require(
      JointTempoPhaseFit.fit(
        observations: FramewiseObservationsTests.rollbackFixture(secondNoise: false),
        candidate: candidate))
    #expect(abs(fit.tempoBPM - 120) <= 0.1, "tempo \(fit.tempoBPM)")
    #expect(abs(fit.keptFraction - 10.0 / 11.0) < 1e-9, "keptFraction \(fit.keptFraction)")
  }

  @Test func fitRecoversTempoUnderAlternatingEarlyLatePeaks() throws {
    // FramewiseObservationsTests.decoderStaysStableUnderAlternatingEarlyLatePeaks:
    // 32 clicks alternately 2 frames early and late around an exact
    // 50-frame grid. The regression averages the alternation out.
    let truth = FramewiseObservationsTests.grid50(0..<32)
    let clicks = truth.enumerated().map { $0.element + ($0.offset.isMultiple(of: 2) ? -2 : 2) }
    let obs = FramewiseObservationsTests.handBuilt(
      beat: FramewiseObservationsTests.train(clicks, count: 1_610))
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter))
    let fit = try #require(JointTempoPhaseFit.fit(observations: obs, candidate: candidate))
    #expect(abs(fit.tempoBPM - 120) <= 0.1, "tempo \(fit.tempoBPM)")
  }

  @Test func fitAbstainsOnPositiveConstant() throws {
    // FramewiseObservationsTests.decoderReturnsNoEvidenceCandidateOnPositiveConstant:
    // the selector returns the no-evidence quarter candidate and the fit
    // abstains on it.
    let obs = FramewiseObservationsTests.handBuilt(beat: [Float](repeating: 0.5, count: 400))
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    #expect(selection.chosen.evidence == CandidateBeatSequence.Evidence.none)
    #expect(JointTempoPhaseFit.fit(observations: obs, selection: selection) == nil)
  }

  @Test func fitAbstainsOnQuietTrainBelowAmplitudeGate() throws {
    // Known limit (follow-up 4). FramewiseObservationsTests
    // .decoderQuietTrainLimitUnderOneTransient at 0.05: 30 clicks at 0.05
    // over a zero floor plus one off-grid transient at 1.0 (frame 535). The
    // decoder observes all 30 quiet clicks, but their mean support (0.05) is
    // under minSupportScore (0.1), so the fit's amplitude gate abstains on a
    // correctly decoded train. The quarter candidate is decoded directly:
    // the selector picks double here, because the transient lies on the
    // double grid.
    var beat = FramewiseObservationsTests.train(
      FramewiseObservationsTests.grid50(0..<30), value: 0.05, count: 1_500)
    beat[535] = 1.0
    let obs = FramewiseObservationsTests.handBuilt(beat: beat)
    let candidate = try #require(
      BarStateDecoder.decode(observations: obs, tempoBPM: 120, level: .quarter))
    #expect(candidate.beats.count == 30)
    #expect(candidate.meanBeatSupport < JointTempoPhaseFit.minSupportScore)
    #expect(JointTempoPhaseFit.fit(observations: obs, candidate: candidate) == nil)
  }

  // MARK: - Seeded sparse noise: false-acceptance ceiling

  /// Accepted fits across the 20 seeds of
  /// `fitFalseAcceptanceOnSparseNoiseIsBounded`, measured on the
  /// implemented code at this commit. The pre-change code (before the
  /// final-line validation) measured 13 and 4 on the same seeds. Follow-up 4
  /// (replacing the amplitude gate) must lower, not raise, these. A ceiling,
  /// not evidence that the rate is acceptable.
  private static let sparseNoiseAcceptedFitCeiling = 13

  /// Total confirmed reacquisitions on the selector's chosen candidates
  /// across the same 20 seeds, measured as above (pre-change: 4). Counted
  /// at the decoder level, accepted or not, since fit acceptance alone can
  /// hide a clock change.
  private static let sparseNoiseReacquisitionCeiling = 4

  /// Per-seed baseline behind the two ceilings. Swift Testing runs each
  /// argument as an independent case, so the totals cannot be summed across
  /// cases; instead each seed may only move from accepted to rejected and
  /// lower its reacquisition count, which bounds both totals.
  private static let sparseNoiseAcceptedSeeds: Set<Int> = [
    0, 1, 2, 3, 4, 5, 7, 8, 10, 14, 17, 18, 19,
  ]
  private static let sparseNoiseReacquisitionsBySeed: [Int: Int] = [15: 4]

  @Test(arguments: 0..<20)
  func fitFalseAcceptanceOnSparseNoiseIsBounded(seed: Int) throws {
    // 1,200 frames at 100 fps: 0.04 with probability 0.1, else 0, plus one
    // 1.0 frame at 601. No beat train is present.
    #expect(Self.sparseNoiseAcceptedSeeds.count == Self.sparseNoiseAcceptedFitCeiling)
    #expect(
      Self.sparseNoiseReacquisitionsBySeed.values.reduce(0, +)
        == Self.sparseNoiseReacquisitionCeiling)
    var rng = SplitMix64(seed: UInt64(seed))
    var beat = (0..<1_200).map { _ -> Float in
      Double(rng.next() >> 11) / Double(UInt64(1) << 53) < 0.1 ? 0.04 : 0
    }
    beat[601] = 1.0
    let obs = FramewiseObservationsTests.handBuilt(beat: beat)
    let selection = try #require(MetricalLevelSelector.select(observations: obs, tempoBPM: 120))
    let fit = JointTempoPhaseFit.fit(observations: obs, selection: selection)
    let reacquisitions = selection.chosen.reacquisitionCount
    print(
      "Story 15.7 sparse noise seed \(seed): accepted \(fit != nil), level \(selection.chosen.metricalLevel), reacquisitions \(reacquisitions)"
    )
    if fit != nil {
      #expect(Self.sparseNoiseAcceptedSeeds.contains(seed), "seed \(seed) newly accepted")
    }
    #expect(
      reacquisitions <= Self.sparseNoiseReacquisitionsBySeed[seed, default: 0],
      "seed \(seed) reacquisitions \(reacquisitions)")
  }

  @Test func identifierNamesTrimming() throws {
    #expect(
      JointTempoPhaseFit.modelIdentifier
        == "joint-tempo-phase.v4.robust-fallback-seed.final-validated")
    let (fit, _, _) = try fitForClickTrack()
    #expect(fit.modelIdentifier == JointTempoPhaseFit.modelIdentifier)
    #expect(fit.decoderIdentifier == BarStateDecoder.decoderIdentifier)
    let handBuilt = try #require(handBuiltFit(times: (0..<20).map { 0.5 + 0.5 * Double($0) }))
    #expect(handBuilt.observationModelIdentifier == "test")
  }

  // MARK: - AC #6 / #7: no public shape change

  @Test func signalWeightsBeatGridStaysPlaceholder() throws {
    _ = JointTempoPhaseFit.trimThresholdFactor
    _ = JointTempoPhaseFit.minKeptFraction
    _ = JointTempoPhaseFit.minKeptBeats
    _ = JointTempoPhaseFit.maxTempoDeviationFraction
    _ = JointTempoPhaseFit.minSupportScore
    _ = FittedTempoPhase.self
    // SignalSource.beatGrid / SignalWeights.beatGrid stay placeholders.
    #expect(SignalWeights.default.beatGrid == 1.0)
  }

  // MARK: - Sub-frame peak interpolation unit test

  @Test func parabolicPeakInterpolationCentersPeak() throws {
    // Build a synthetic observation stream with a known parabolic peak.
    let frameRate: Double = 100
    let frameCount = 100
    // Peak centered at frame 50, parabola `-((f - 50.3)^2) + 1`. The
    // true sub-frame peak is at offset 0.3 relative to frame 50.
    var beats = [Float](repeating: 0, count: frameCount)
    for f in 0..<frameCount {
      let value = -pow(Double(f) - 50.3, 2) * 0.01 + 1.0
      beats[f] = Float(max(0.0, value))
    }
    let obs = FramewiseObservations(
      frameRate: frameRate,
      firstFrameOriginSeconds: 0,
      coverageWindowSeconds: Double(frameCount) / frameRate,
      beatProbabilities: beats,
      downbeatProbabilities: beats,
      modelIdentifier: "test",
      frontendIdentifier: "test"
    )
    // Beat time at frame 50: refinement should push it toward 50.3.
    let integerTime = obs.timeForFrame(50)
    let refined = JointTempoPhaseFit.refineBeatTime(
      aroundTime: integerTime, observations: obs)
    #expect(refined > integerTime)
    let refinedFrame = (refined - obs.firstFrameOriginSeconds) * frameRate
    #expect(abs(refinedFrame - 50.3) <= 0.1, "refined frame \(refinedFrame) is not close to 50.3")
  }

  @Test func refinementLeavesMonotonicTriplesUnchanged() {
    // A rising (0.1, 0.5, 0.8) or falling (0.8, 0.5, 0.1) triple around frame
    // 50 has negative curvature but no local maximum at the centre. Without
    // the local-maximum check the interpolated offset (3.5 frames) clamps to
    // half a frame toward the larger neighbour.
    for triple: [Float] in [[0.1, 0.5, 0.8], [0.8, 0.5, 0.1]] {
      var beats = [Float](repeating: 0, count: 100)
      beats[49] = triple[0]
      beats[50] = triple[1]
      beats[51] = triple[2]
      let obs = FramewiseObservations(
        frameRate: 100, firstFrameOriginSeconds: 0, coverageWindowSeconds: 1.0,
        beatProbabilities: beats, downbeatProbabilities: beats,
        modelIdentifier: "test", frontendIdentifier: "test")
      let integerTime = obs.timeForFrame(50)
      let refined = JointTempoPhaseFit.refineBeatTime(aroundTime: integerTime, observations: obs)
      #expect(refined == integerTime, "triple \(triple) moved the beat to \(refined)")
    }
  }

  @Test func refinementReadsTrailingFrameUnderRoundoffCoverage() {
    // 29 frames at 100 fps (44.1 kHz, hop 441) with coverage reported as
    // 29 * 441 / 44100 s, which times 100 is 28.999999999999996. A plain
    // floor gives 28 usable frames and skips the peak at frame 27, whose
    // right neighbour is frame 28; usableFrameCount gives 29 and the peak
    // is interpolated.
    var beats = [Float](repeating: 0, count: 29)
    beats[26] = 0.3
    beats[27] = 1.0
    beats[28] = 0.6
    let obs = FramewiseObservations(
      frameRate: 100, firstFrameOriginSeconds: 0,
      coverageWindowSeconds: 29.0 * 441.0 / 44_100.0,
      beatProbabilities: beats, downbeatProbabilities: [Float](repeating: 0, count: 29),
      modelIdentifier: "test", frontendIdentifier: "test")
    #expect(obs.usableFrameCount == 29)
    let integerTime = obs.timeForFrame(27)
    let refined = JointTempoPhaseFit.refineBeatTime(aroundTime: integerTime, observations: obs)
    #expect(refined != integerTime, "peak at frame 27 was not interpolated")
    #expect(refined > integerTime, "refined \(refined) should move toward the larger neighbour")
  }
}
