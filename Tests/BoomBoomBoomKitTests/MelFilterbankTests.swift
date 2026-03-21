//
//  MelFilterbankTests.swift
//  BoomBoomBoomKitTests
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("MelFilterbank")
struct MelFilterbankTests {

  // MARK: - Filterbank shape

  @Test("filterbank has correct shape: 128 * 1024 elements")
  func filterbankShape() {
    let fb = MelFilterbank.buildFilterbank(
      melBands: 128, fftSize: 2048, sampleRate: 44100, fmin: 30, fmax: 16000)
    #expect(fb.count == 128 * 1024, "Expected 131072 elements, got \(fb.count)")
  }

  // MARK: - Non-zero row sums (no dead bands)

  @Test("every mel band has non-zero sum")
  func noDeadBands() {
    let melBands = 128
    let freqBins = 1024
    let fb = MelFilterbank.buildFilterbank(
      melBands: melBands, fftSize: 2048, sampleRate: 44100, fmin: 30, fmax: 16000)

    for m in 0..<melBands {
      let row = Array(fb[(m * freqBins)..<((m + 1) * freqBins)])
      let sum = row.reduce(0, +)
      #expect(sum > 0, "Mel band \(m) has zero sum (dead band)")
    }
  }

  // MARK: - Mel conversion round-trip

  @Test("melToHz(hzToMel(440)) approximately equals 440")
  func melRoundTrip() {
    let hz = 440.0
    let roundTrip = MelFilterbank.melToHz(MelFilterbank.hzToMel(hz))
    #expect(
      abs(roundTrip - hz) < 0.01,
      "Round-trip should preserve frequency, got \(roundTrip)")
  }

  @Test("hzToMel(0) equals 0")
  func melZero() {
    #expect(MelFilterbank.hzToMel(0) == 0, "0 Hz should map to 0 mel")
  }

  // MARK: - Triangular shape (single contiguous non-zero region per row)

  @Test("each row has a single contiguous non-zero region")
  func triangularShape() {
    let melBands = 128
    let freqBins = 1024
    let fb = MelFilterbank.buildFilterbank(
      melBands: melBands, fftSize: 2048, sampleRate: 44100, fmin: 30, fmax: 16000)

    for m in 0..<melBands {
      let row = Array(fb[(m * freqBins)..<((m + 1) * freqBins)])

      // Find first and last non-zero indices
      guard let firstNonZero = row.firstIndex(where: { $0 > 0 }),
        let lastNonZero = row.lastIndex(where: { $0 > 0 })
      else {
        Issue.record("Band \(m) has no non-zero values")
        continue
      }

      // Check no zeros in between (contiguous)
      let region = row[firstNonZero...lastNonZero]
      let hasGap = region.contains(where: { $0 == 0 })
      #expect(!hasGap, "Band \(m) has gaps in non-zero region (not contiguous)")
    }
  }
}
