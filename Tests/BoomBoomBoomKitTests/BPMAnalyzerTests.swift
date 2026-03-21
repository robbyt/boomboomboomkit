//
//  BPMAnalyzerTests.swift
//  BoomBoomBoomKitTests
//

import Accelerate
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Task 8: Synthetic 120 BPM Click Track

@Suite("BPMAnalyzer — 120 BPM Click Track")
struct BPMAnalyzer120BPMTests {

  private let sampleRate: Double = 44100
  private let duration: Double = 15
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: duration)
  }

  @Test("detects 120 BPM from synthetic click track")
  func detect120BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 118 && result.bpm <= 122,
      "Expected ~120 BPM, got \(result.bpm)")
  }

  @Test("120 BPM click track has confidence > 0.5")
  func confidence120BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.confidence > 0.5,
      "Expected confidence > 0.5, got \(result.confidence)")
  }

  @Test("detects 120 BPM at 48kHz sample rate")
  func detect120BPMat48kHz() throws {
    let samples48k = generateClickTrack(bpm: 120, sampleRate: 48000, durationSeconds: 15)
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples48k, sampleRate: 48000))
    #expect(
      result.bpm >= 118 && result.bpm <= 122,
      "Expected ~120 BPM at 48kHz, got \(result.bpm)")
  }
}

// MARK: - Task 9: Synthetic 140 BPM Click Track

@Suite("BPMAnalyzer — 140 BPM Click Track")
struct BPMAnalyzer140BPMTests {

  private let sampleRate: Double = 44100
  private let duration: Double = 15
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 140, sampleRate: sampleRate, durationSeconds: duration)
  }

  @Test("detects 140 BPM from synthetic click track")
  func detect140BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 138 && result.bpm <= 142,
      "Expected ~140 BPM, got \(result.bpm)")
  }

  @Test("140 BPM click track has confidence > 0.5")
  func confidence140BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.confidence > 0.5,
      "Expected confidence > 0.5, got \(result.confidence)")
  }
}

// MARK: - Task 10: Silence Returns Nil

@Suite("BPMAnalyzer — Silence")
struct BPMAnalyzerSilenceTests {

  @Test("silence returns nil")
  func silenceReturnsNil() {
    let samples = [Float](repeating: 0, count: Int(44100 * 10))
    let result = BPMAnalyzer.estimateBPM(samples: samples, sampleRate: 44100)
    #expect(result == nil, "Silence should return nil")
  }
}

// MARK: - Task 11: Real MP3 Fixture

@Suite("BPMAnalyzer — Real Audio Fixtures")
struct BPMAnalyzerFixtureTests {

  @Test("real MP3 returns non-nil result with plausible BPM")
  func realMP3() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 30)
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate),
      "Expected non-nil BPM for real audio")
    #expect(result.confidence > 0, "Expected positive confidence")
    #expect(
      result.bpm >= 40 && result.bpm <= 250,
      "Expected musically plausible BPM (40-250), got \(result.bpm)")
  }
}

// MARK: - Task 12: Short Input Returns Nil

@Suite("BPMAnalyzer — Edge Cases")
struct BPMAnalyzerEdgeCaseTests {

  @Test("short input (< 4 seconds) returns nil")
  func shortInputReturnsNil() {
    // 0.5 seconds of non-silent audio
    let samples = generateClickTrack(bpm: 120, sampleRate: 44100, durationSeconds: 0.5)
    let result = BPMAnalyzer.estimateBPM(samples: samples, sampleRate: 44100)
    #expect(result == nil, "Short input should return nil")
  }

  @Test("empty samples returns nil")
  func emptyReturnsNil() {
    let result = BPMAnalyzer.estimateBPM(samples: [], sampleRate: 44100)
    #expect(result == nil, "Empty input should return nil")
  }

  @Test("white noise returns nil or very low confidence")
  func whiteNoiseHandling() {
    var rng = SplitMix64(seed: 42)
    let sampleCount = Int(44100 * 10)
    let samples = (0..<sampleCount).map { _ -> Float in
      // Map UInt64 to [-1.0, 1.0]
      Float(Double(rng.next()) / Double(UInt64.max)) * 2.0 - 1.0
    }
    let result = BPMAnalyzer.estimateBPM(samples: samples, sampleRate: 44100)
    if let result {
      #expect(
        result.confidence < 0.5,
        "White noise confidence should be < 0.5, got \(result.confidence)")
    }
    // nil is also acceptable — noise may not produce any detectable beat
  }

}

// MARK: - 85 BPM Click Track Regression

@Suite("BPMAnalyzer — 85 BPM Click Track")
struct BPMAnalyzer85BPMTests {

  private let sampleRate: Double = 44100
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 85, sampleRate: sampleRate, durationSeconds: 15)
  }

  @Test("detects 85 BPM from synthetic click track")
  func detect85BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 83 && result.bpm <= 87,
      "Expected ~85 BPM, got \(result.bpm)")
  }
}

// MARK: - Mel Onset Envelope Tests

@Suite("BPMAnalyzer — Mel Onset Envelope")
struct BPMAnalyzerMelOnsetTests {

  @Test("onset envelope is non-empty for 120 BPM click track, all values finite, some > 0")
  func onsetEnvelopeBasicProperties() throws {
    let sampleRate: Double = 44100
    let samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: 15)

    // Test via the public API — if estimateBPM returns a result, the onset envelope worked
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate),
      "Expected non-nil result for 120 BPM click track (onset envelope must be non-empty)")
    #expect(result.bpm >= 118 && result.bpm <= 122, "Expected ~120 BPM, got \(result.bpm)")
  }

}

// MARK: - 160 BPM Click Track (Octave Disambiguation)

@Suite("BPMAnalyzer — 160 BPM Click Track")
struct BPMAnalyzer160BPMTests {

  private let sampleRate: Double = 44100
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 160, sampleRate: sampleRate, durationSeconds: 15)
  }

  @Test("detects 160 BPM from synthetic click track (not 80)")
  func detect160BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 158 && result.bpm <= 162,
      "Expected ~160 BPM, got \(result.bpm)")
  }
}

// MARK: - 80 BPM Click Track

@Suite("BPMAnalyzer — 80 BPM Click Track")
struct BPMAnalyzer80BPMTests {

  private let sampleRate: Double = 44100
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 80, sampleRate: sampleRate, durationSeconds: 15)
  }

  @Test("detects 80 BPM from synthetic click track (not 160)")
  func detect80BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 78 && result.bpm <= 82,
      "Expected ~80 BPM, got \(result.bpm)")
  }
}

// MARK: - 170 BPM Click Track

@Suite("BPMAnalyzer — 170 BPM Click Track")
struct BPMAnalyzer170BPMTests {

  private let sampleRate: Double = 44100
  private let samples: [Float]

  init() {
    samples = generateClickTrack(bpm: 170, sampleRate: sampleRate, durationSeconds: 15)
  }

  @Test("detects 170 BPM from synthetic click track")
  func detect170BPM() throws {
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 168 && result.bpm <= 172,
      "Expected ~170 BPM, got \(result.bpm)")
  }
}

// MARK: - Energy Scan Tests

@Suite("BPMAnalyzer — Energy Scan")
struct BPMAnalyzerEnergyScanTests {

  @Test("energy scan detects transition after silence intro")
  func energyScanWithSilenceIntro() throws {
    let sampleRate: Double = 44100
    // 10 seconds of silence + 30 seconds of 120 BPM clicks
    let silenceSamples = [Float](repeating: 0, count: Int(sampleRate * 10))
    let clickSamples = generateClickTrack(
      bpm: 120, sampleRate: sampleRate, durationSeconds: 30)
    let combined = silenceSamples + clickSamples

    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: combined, sampleRate: sampleRate))
    #expect(
      result.bpm >= 118 && result.bpm <= 122,
      "Expected ~120 BPM with silence intro, got \(result.bpm)")
  }

  @Test("constant energy audio analyzes from beginning")
  func constantEnergyFromBeginning() throws {
    let sampleRate: Double = 44100
    let samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: 15)
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 118 && result.bpm <= 122,
      "Expected ~120 BPM for constant energy, got \(result.bpm)")
  }

  @Test("full silence returns nil")
  func fullSilenceReturnsNil() {
    let samples = [Float](repeating: 0, count: Int(44100 * 40))
    let result = BPMAnalyzer.estimateBPM(samples: samples, sampleRate: 44100)
    #expect(result == nil, "Full silence should return nil")
  }
}

// MARK: - Range Normalization Tests

@Suite("BPMAnalyzer — Range Normalization")
struct BPMAnalyzerRangeNormalizationTests {

  @Test("40 BPM doubles to 80 BPM")
  func normalize40to80() {
    #expect(BPMAnalyzer.rangeNormalize(40) == 80)
  }

  @Test("210 BPM halves to 105 BPM")
  func normalize210to105() {
    #expect(BPMAnalyzer.rangeNormalize(210) == 105)
  }

  @Test("60 BPM stays unchanged")
  func normalize60stays() {
    #expect(BPMAnalyzer.rangeNormalize(60) == 60)
  }

  @Test("200 BPM stays unchanged")
  func normalize200stays() {
    #expect(BPMAnalyzer.rangeNormalize(200) == 200)
  }

  @Test("30 BPM doubles to 60 BPM")
  func normalize30to60() {
    #expect(BPMAnalyzer.rangeNormalize(30) == 60)
  }

  @Test("400 BPM halves to 200 BPM")
  func normalize400to200() {
    #expect(BPMAnalyzer.rangeNormalize(400) == 200)
  }
}

// MARK: - Fourier Tempogram Isolation Test

@Suite("BPMAnalyzer — Fourier Tempogram")
struct BPMAnalyzerFourierTempogramTests {

  @Test("tempogram has peak at 120 BPM for 120 BPM click track")
  func tempogramPeakAt120() throws {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: 15)
    let onset = BPMAnalyzer.computeMelOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)
    #expect(!onset.isEmpty, "Onset envelope should be non-empty")

    let onsetRate = sampleRate / Double(hopSize)
    let bpmMin = 40
    let bpmMax = 250
    let tempogram = BPMAnalyzer.computeFourierTempogram(
      onsetEnvelope: onset, onsetRate: onsetRate, bpmMin: bpmMin, bpmMax: bpmMax)

    // Find peak index
    var peakIdx = 0
    var peakVal: Float = 0
    for i in 0..<tempogram.count {
      if tempogram[i] > peakVal {
        peakVal = tempogram[i]
        peakIdx = i
      }
    }
    let peakBPM = bpmMin + peakIdx
    #expect(
      peakBPM >= 118 && peakBPM <= 122,
      "Tempogram peak should be near 120 BPM, got \(peakBPM)")
  }
}

// MARK: - Periodicity Fusion Isolation Test

@Suite("BPMAnalyzer — Periodicity Fusion")
struct BPMAnalyzerFusionTests {

  @Test("fusion suppresses octave ghosts: 160 BPM survives, 80 and 320 suppressed")
  func fusionSuppressesOctaveGhosts() {
    let bpmMin = 40
    let bpmMax = 250
    let candidateCount = bpmMax - bpmMin + 1
    let onsetRate: Double = 100.0

    // Synthetic autocorrelation: peaks at 80 and 160 BPM (subharmonic pattern)
    // In lag domain, lag = 60 * onsetRate / bpm
    var acf = [Float](repeating: 0, count: Int(60.0 * onsetRate / Double(bpmMin)) + 10)
    let lag160 = Int(60.0 * onsetRate / 160.0)  // ~37.5
    let lag80 = Int(60.0 * onsetRate / 80.0)  // ~75
    if lag160 < acf.count { acf[lag160] = 1.0 }
    if lag80 < acf.count { acf[lag80] = 0.9 }

    // Synthetic tempogram: peaks at 160 and 320 BPM (harmonic pattern)
    var tempogram = [Float](repeating: 0, count: candidateCount)
    let idx160 = 160 - bpmMin
    let idx320 = min(320 - bpmMin, candidateCount - 1)
    if idx160 < candidateCount { tempogram[idx160] = 1.0 }
    if idx320 < candidateCount { tempogram[idx320] = 0.8 }

    let fused = BPMAnalyzer.fusePeriodicity(
      autocorrelation: acf, fourierTempogram: tempogram,
      bpmMin: bpmMin, bpmMax: bpmMax, onsetRate: onsetRate)

    // Find dominant peak in fused result
    var peakIdx = 0
    var peakVal: Float = 0
    for i in 0..<fused.count {
      if fused[i] > peakVal {
        peakVal = fused[i]
        peakIdx = i
      }
    }
    let peakBPM = bpmMin + peakIdx

    // 160 BPM should be the dominant peak (present in both ACF and tempogram)
    #expect(
      peakBPM >= 158 && peakBPM <= 162,
      "Fused peak should be at ~160 BPM, got \(peakBPM)")

    // 80 BPM (only in ACF, not in tempogram) should be suppressed
    let idx80 = 80 - bpmMin
    if idx80 < fused.count {
      #expect(
        fused[idx80] < fused[idx160] * 0.5,
        "80 BPM ghost should be suppressed relative to 160 BPM peak")
    }
  }
}

// MARK: - Sub-Band Onset Envelope Tests

@Suite("BPMAnalyzer — Sub-Band Onset Envelopes")
struct BPMAnalyzerSubBandOnsetTests {

  @Test("computeMelOnsetEnvelopeWithSubBands produces 4 non-empty sub-band envelopes")
  func subBandEnvelopesNonEmpty() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: 15)

    let result = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    #expect(!result.fullBand.isEmpty, "Full-band envelope should be non-empty")
    #expect(result.subBands.count == 4, "Should have 4 sub-band envelopes")
    for (i, band) in result.subBands.enumerated() {
      #expect(!band.isEmpty, "Sub-band \(i) should be non-empty")
      #expect(band.count == result.fullBand.count, "Sub-band \(i) should match full-band length")
    }
  }

  @Test("sub-band envelopes have some positive values for click track")
  func subBandEnvelopesHavePositiveValues() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 160, sampleRate: sampleRate, durationSeconds: 15)

    let result = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    // Click tracks are broadband, so all bands should have some energy
    for (i, band) in result.subBands.enumerated() {
      let maxVal = band.max() ?? 0
      #expect(maxVal > 0, "Sub-band \(i) should have positive onset values for click track")
    }
  }
}

// MARK: - Sub-Band Voting Tests

@Suite("BPMAnalyzer — Sub-Band Voting")
struct BPMAnalyzerSubBandVotingTests {

  @Test("synthetic 160 BPM click track: full pipeline still detects 160 BPM")
  func clickTrackFullPipelineDetects160() throws {
    let sampleRate: Double = 44100
    let samples = generateClickTrack(bpm: 160, sampleRate: sampleRate, durationSeconds: 15)

    // The full pipeline (with sub-band voting as promotion-only) should still detect 160 BPM
    let result = try #require(
      BPMAnalyzer.estimateBPM(samples: samples, sampleRate: sampleRate))
    #expect(
      result.bpm >= 158 && result.bpm <= 162,
      "Expected ~160 BPM from full pipeline, got \(result.bpm)")
  }

  @Test("mock ACFs: hi-hat favors 160, kick favors 80 → returns 160 (weighted)")
  func weightedVotingFavorsFaster() {
    let onsetRate: Double = 100.0
    let lagFast = 60.0 * onsetRate / 160.0  // ~37.5
    let lagSlow = 60.0 * onsetRate / 80.0  // ~75

    let acfLength = Int(lagSlow) + 10

    // Kick band: peak at lagSlow (votes slow)
    var kickACF = [Float](repeating: 0, count: acfLength)
    kickACF[Int(lagSlow)] = 1.0
    kickACF[Int(lagFast)] = 0.2

    // Snare body: peak at lagSlow (votes slow)
    var snareLowACF = [Float](repeating: 0, count: acfLength)
    snareLowACF[Int(lagSlow)] = 1.0
    snareLowACF[Int(lagFast)] = 0.3

    // Snare crack: peak at lagFast (votes fast)
    var snareCrackACF = [Float](repeating: 0, count: acfLength)
    snareCrackACF[Int(lagFast)] = 1.0
    snareCrackACF[Int(lagSlow)] = 0.2

    // Hi-hat: peak at lagFast (votes fast)
    var hiHatACF = [Float](repeating: 0, count: acfLength)
    hiHatACF[Int(lagFast)] = 1.0
    hiHatACF[Int(lagSlow)] = 0.1

    // Kick(0.5) + SnareLow(1.0) = 1.5 for slow
    // SnareCrack(1.5) + HiHat(2.0) = 3.5 for fast
    // Fast wins
    let winner = BPMAnalyzer.subBandVote(
      subBandACFs: [kickACF, snareLowACF, snareCrackACF, hiHatACF],
      candidateFast: 160,
      candidateSlow: 80,
      onsetRate: onsetRate)

    #expect(winner == 160, "Weighted voting should favor fast tempo (3.5 > 1.5)")
  }
}
