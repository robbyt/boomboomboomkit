//
//  RhythmicRegionSelectorTests.swift
//  BoomBoomBoomKit
//
//  Bounded rhythm-region selection behavior.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Rhythmic region selection")
struct RhythmicRegionSelectorTests {
  private let rate = 8_000.0

  private func beats(seconds: Int, amplitude: Float) -> [Float] {
    var samples = [Float](repeating: 0, count: seconds * 8_000)
    for beat in stride(from: 0, to: samples.count, by: 4_000) {
      for i in beat..<min(beat + 80, samples.count) {
        samples[i] = amplitude
      }
    }
    return samples
  }

  private func unpatterned(seconds: Int, amplitude: Float) -> [Float] {
    var state: UInt32 = 17
    return (0..<(seconds * 8_000)).map { _ in
      state = state &* 1_664_525 &+ 1_013_904_223
      return (state & 1 == 0 ? amplitude : -amplitude)
    }
  }

  @Test("quiet steady beats outrank loud unpatterned audio")
  func rhythmBeatsLoudness() throws {
    let samples =
      unpatterned(seconds: 15, amplitude: 0.8)
      + beats(seconds: 15, amplitude: 0.02)
      + beats(seconds: 15, amplitude: 0.02)
    let regions = RhythmicRegionSelector.select(
      samples: samples, sampleRate: rate, durationSeconds: 15, maximumCount: 2)
    #expect(regions.map(\.startSample) == [120_000, 240_000])
    #expect(regions.allSatisfy { $0.rhythmScore > 0 })
  }

  @Test("silence and tied scores select earliest disjoint regions")
  func silenceAndTies() {
    let samples = [Float](repeating: 0, count: 45 * 8_000)
    let regions = RhythmicRegionSelector.select(
      samples: samples, sampleRate: rate, durationSeconds: 15, maximumCount: 2)
    #expect(regions.map(\.startSample) == [0, 120_000])
    #expect(regions.allSatisfy { $0.rhythmScore == 0 })
    #expect(regions[0].startSample + regions[0].sampleCount <= regions[1].startSample)
  }

  @Test("short clips return one truncated probe")
  func shortClip() throws {
    let regions = RhythmicRegionSelector.select(
      samples: beats(seconds: 5, amplitude: 0.1), sampleRate: rate,
      durationSeconds: 15, maximumCount: 3)
    let region = try #require(regions.first)
    #expect(regions.count == 1)
    #expect(region.startSample == 0)
    #expect(region.sampleCount == 40_000)
  }

  @Test("a full mix costs at most eight capped disjoint probes")
  func boundedProbes() {
    let probes = RhythmicRegionSelector.probeRegions(
      samples: [Float](repeating: 0, count: 9 * 30 * 8_000),
      sampleRate: rate, durationSeconds: 45)
    #expect(probes.count == 8)
    #expect(probes.allSatisfy { $0.sampleCount <= 30 * 8_000 })
    for pair in zip(probes, probes.dropFirst()) {
      #expect(pair.0.startSample + pair.0.sampleCount <= pair.1.startSample)
    }
  }

  @Test("out-of-range finite sample rates are rejected before integer conversion")
  func excessiveSampleRate() {
    let samples = [Float](repeating: 0, count: 8_000)
    #expect(
      RhythmicRegionSelector.select(
        samples: samples, sampleRate: Double.greatestFiniteMagnitude,
        durationSeconds: 30, maximumCount: 3
      ).isEmpty)
  }
}
