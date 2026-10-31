//
//  FixedTimeCropsTests.swift
//  BoomBoomBoomKitTests
//
//  The fixed-time model input: crop plan, rhythm ranking, per-band z-score,
//  and conversion to 44.1 kHz.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

private typealias Crops = FeatureSubstrate.FixedTimeCrops

private func crop(_ start: Int, _ score: Float) -> MLInputCrop {
  MLInputCrop(
    startFrame: start, startSeconds: Double(start) * 0.01, durationSeconds: 12.04,
    rhythmScore: score)
}

private func decoded(_ samples: [Float], rate: Double = 44_100) -> FeatureSubstrate.DecodedAudio {
  FeatureSubstrate.DecodedAudio(
    samples: samples, sampleRate: rate,
    codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone))
}

@Suite("Fixed-time crop plan")
struct FixedTimeCropPlanTests {

  @Test("one crop is 530,807 samples and 1200 frames")
  func cropSamples() {
    #expect(Crops.cropSamples == 530_807)
    #expect(Crops.frameCount(sampleCount: Crops.cropSamples) == 1200)
    #expect(Crops.frameCount(sampleCount: Crops.cropSamples - 1) == 1199)
    #expect(Crops.frameCount(sampleCount: 2047) == 0)
  }

  @Test("a clip shorter than one crop has no candidate")
  func shortClip() {
    #expect(Crops.candidateStarts(frameCount: 0).isEmpty)
    #expect(Crops.candidateStarts(frameCount: 1199).isEmpty)
    #expect(Crops.candidateStarts(frameCount: 1200) == [0])
  }

  @Test("an exact multiple of the hop gets regular crops only")
  func exactMultiple() {
    #expect(Crops.candidateStarts(frameCount: 2400) == [0, 600, 1200])
    #expect(Crops.candidateStarts(frameCount: 1800) == [0, 600])
  }

  @Test("crops that stop short of the last frame get one tail crop ending on it")
  func tailCrop() {
    #expect(Crops.candidateStarts(frameCount: 1996) == [0, 600, 796])
    // A 120 s clip: 18 regular crops plus one tail crop.
    let starts = Crops.candidateStarts(frameCount: 11_996)
    #expect(starts.count == 19)
    #expect(Array(starts.prefix(18)) == Array(stride(from: 0, through: 10_200, by: 600)))
    #expect(starts.last == 10_796)
  }

  @Test("a short decode has no candidate and abstains shorter-than-crop")
  func shortDecode() throws {
    let set = try Crops.build(decoded: decoded([Float](repeating: 0.1, count: 44_100)))
    #expect(set.candidates.isEmpty)
    #expect(set.keptCrops.isEmpty)
    #expect(set.abstainReason == .shorterThanCrop)
  }

  @Test("silence scores 0 everywhere and abstains no-rhythmic-crop")
  func silence() throws {
    let set = try Crops.build(decoded: decoded([Float](repeating: 0, count: 20 * 44_100)))
    #expect(set.candidates.map(\.startFrame) == [0, 600, 796])
    #expect(set.candidates.allSatisfy { $0.rhythmScore == 0 })
    #expect(set.keptCrops.isEmpty)
    #expect(set.abstainReason == .noRhythmicCrop)
  }
}

@Suite("Fixed-time crop ranking")
struct FixedTimeCropRankingTests {

  @Test("keeps at most four crops")
  func capOfFour() {
    let candidates = (0..<8).map { crop($0 * 1200, 0.9) }
    let kept = Crops.rank(candidates)
    #expect(kept.map(\.startFrame) == [0, 1200, 2400, 3600])
  }

  @Test("a crop below half the best is not kept")
  func halfBestFloor() {
    let kept = Crops.rank([
      crop(0, 0.8), crop(1200, 0.5), crop(2400, 0.39), crop(3600, 0.1),
    ])
    #expect(kept.map(\.startFrame) == [0, 1200])
    // Exactly half the best is kept.
    #expect(Crops.rank([crop(0, 0.8), crop(1200, 0.4)]).map(\.startFrame) == [0, 1200])
  }

  @Test("ties go to the earlier start")
  func tiesToEarlier() {
    let kept = Crops.rank([crop(3600, 0.7), crop(1200, 0.7), crop(0, 0.5)])
    #expect(kept.map(\.startFrame) == [1200, 3600, 0])
  }

  @Test("a crop sharing a frame with a kept crop is skipped")
  func overlap() {
    let kept = Crops.rank([crop(0, 0.9), crop(600, 0.85), crop(1200, 0.8)])
    #expect(kept.map(\.startFrame) == [0, 1200])
  }

  @Test("all-zero scores keep nothing")
  func allZero() {
    #expect(Crops.rank([crop(0, 0), crop(1200, 0)]).isEmpty)
    #expect(Crops.rank([]).isEmpty)
  }
}

@Suite("Fixed-time crop tensor")
struct FixedTimeCropTensorTests {

  @Test("a constant band is zeroed and other bands get mean 0, deviation 1")
  func zscoreZeroing() {
    let frames = 8
    var buffer = [Float](repeating: 3, count: frames)  // band 0: constant
    buffer += (0..<frames).map { Float($0) }  // band 1: ramp
    buffer += [Float](repeating: .infinity, count: frames)  // band 2: not finite
    Crops.zscorePerBand(&buffer, bands: 3, frames: frames)
    #expect(buffer[0..<frames].allSatisfy { $0 == 0 })
    #expect(buffer[(2 * frames)..<(3 * frames)].allSatisfy { $0 == 0 })
    let ramp = Array(buffer[frames..<(2 * frames)])
    let mean = ramp.reduce(0, +) / Float(frames)
    let variance = ramp.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(frames)
    #expect(abs(mean) < 1e-5)
    #expect(abs(variance - 1) < 1e-4)
  }

  @Test("a kept crop's tensor is mel-major 128 x 1200 and z-scored per band")
  func keptTensor() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 20)
    let set = try Crops.build(decoded: decoded(samples))
    #expect(!set.keptCrops.isEmpty)
    #expect(set.keptTensors.count == set.keptCrops.count)
    let tensor = try #require(set.keptTensors.first)
    #expect(tensor.count == 128 * 1200)
    let band = Array(tensor[(40 * 1200)..<(41 * 1200)])
    let mean = band.reduce(0, +) / 1200
    #expect(abs(mean) < 1e-3)
    // The kept tensor equals the stand-alone tensor at the same start.
    let direct = try Crops.cropTensor(samples: samples, startFrame: set.keptCrops[0].startFrame)
    #expect(direct == tensor)
  }

  @Test("an out-of-range start frame is refused without overflowing")
  func hugeStartFrame() {
    let samples = [Float](repeating: 0.1, count: Crops.cropSamples + 441)
    #expect(Crops.rhythmScore(samples: samples, startFrame: .max) == 0)
    #expect(Crops.rhythmScore(samples: samples, startFrame: -1) == 0)
    #expect(Crops.rhythmScore(samples: samples, startFrame: 2) == 0)
    #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try Crops.cropTensor(samples: samples, startFrame: .max)
    }
    #expect(Crops.cropFits(startFrame: 1, sampleCount: samples.count))
    #expect(!Crops.cropFits(startFrame: 0, sampleCount: Crops.cropSamples - 1))
  }

  @Test("cropTensor refuses a crop that overruns the audio")
  func overrun() {
    #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try Crops.cropTensor(samples: [Float](repeating: 0, count: 1000), startFrame: 0)
    }
  }
}

@Suite("Fixed-time 44.1 kHz conversion")
struct FixedTimeConversionTests {

  @Test("44.1 kHz audio passes through unchanged")
  func passThrough() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 2)
    #expect(try Crops.samplesAt44k(decoded(samples)) == samples)
  }

  @Test("48 kHz audio is converted to 44.1 kHz before cropping")
  func fortyEightKilohertz() throws {
    let samples = generateClickTrack(bpm: 120, sampleRate: 48_000, durationSeconds: 20)
    let converted = try Crops.samplesAt44k(decoded(samples, rate: 48_000))
    // 20 s at 44.1 kHz, allowing for the converter's edge samples.
    #expect(abs(converted.count - 20 * 44_100) < 64)
    let set = try Crops.build(decoded: decoded(samples, rate: 48_000))
    #expect(set.frameCount == Crops.frameCount(sampleCount: converted.count))
    #expect(set.candidates.map(\.startFrame) == Crops.candidateStarts(frameCount: set.frameCount))
    #expect(!set.keptCrops.isEmpty)
    #expect(set.candidates.allSatisfy { $0.rhythmScore > 0 })
  }
}
