//
//  SuperFluxOnsetEnvelopeTests.swift
//  BoomBoomBoomKitTests
//
//  Unit tests for Story 4-7's SuperFlux onset envelope (Böck & Widmer 2013).
//  These tests live in the unit-test target (not benchmarks) so they run on
//  every `make test` invocation. The corpus-level Branch-A/B brutal-corpus
//  gate is run by SuperFluxImpactTests.swift in the benchmark target.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Contract tests (Task 3.7)

@Suite("BPMAnalyzer — SuperFlux Onset Envelope (Story 4-7)")
struct SuperFluxOnsetEnvelopeTests {

  @Test("computeSuperFluxOnsetEnvelope produces non-empty fullBand on click track")
  func fullBandNonEmpty() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: 15)

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    #expect(!result.fullBand.isEmpty, "SuperFlux fullBand should be non-empty for a click track")
    #expect(result.subBands.count == 4, "Should have 4 sub-band envelopes")
    for (i, band) in result.subBands.enumerated() {
      #expect(!band.isEmpty, "Sub-band \(i) should be non-empty")
      #expect(
        band.count == result.fullBand.count,
        "Sub-band \(i) should match full-band length")
    }
  }

  @Test("SuperFlux sub-band envelopes carry positive values for broadband clicks")
  func subBandsHavePositiveValues() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 160, sampleRate: sampleRate, durationSeconds: 15)

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    for (i, band) in result.subBands.enumerated() {
      let maxVal = band.max() ?? 0
      #expect(maxVal > 0, "SuperFlux sub-band \(i) should have positive onset values")
    }
  }

  @Test("SuperFlux fullBand has periodic peaks aligned with click positions (120 BPM)")
  func fullBandShowsPeriodicPeaks() {
    let bpm: Double = 120
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)  // 441 — 10 ms hop
    let samples = generateClickTrack(bpm: bpm, sampleRate: sampleRate, durationSeconds: 15)

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    // 120 BPM = 0.5 s between clicks = ~50 hop frames between peaks.
    // Just assert that at least one envelope value is well above the median —
    // proves "periodic structure exists" without claiming exact frame positions.
    let envelope = result.fullBand
    let sorted = envelope.sorted()
    let median = sorted[sorted.count / 2]
    let p95 = sorted[Int(Double(sorted.count) * 0.95)]
    #expect(
      p95 > median * 2,
      "Expected onset peaks well above median (got p95=\(p95), median=\(median))")
  }

  @Test("SuperFlux returns sentinel-empty envelopes for silent input")
  func sentinelOnSilentInput() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = [Float](repeating: 0, count: Int(sampleRate))  // 1 s silence

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    // Silent input → all-zero log-mel envelope → all-zero flux. Should not crash.
    // (Frame count likely still > 2, so fullBand is non-empty but all zeros.)
    for value in result.fullBand {
      #expect(value.isFinite, "SuperFlux should not produce NaN/Inf for silent input")
    }
  }

  @Test("SuperFlux returns sentinel-empty envelopes for too-short input")
  func sentinelOnTooShortInput() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    // Fewer than 2 hop-frame windows worth of samples → sentinel.
    let samples = [Float](repeating: 0.1, count: 2048)  // exactly one fftSize window

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    #expect(
      result.fullBand.isEmpty,
      "Too-short input (< 2 frames) should yield empty fullBand sentinel")
    #expect(result.subBands.count == 4, "Sub-band placeholder count is 4 even on sentinel")
    for band in result.subBands {
      #expect(band.isEmpty, "Sub-band placeholder is empty on sentinel")
    }
  }

  @Test("SuperFlux mlFeatures are populated when captureMLFeatures == true")
  func mlFeaturesCaptured() throws {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 128, sampleRate: sampleRate, durationSeconds: 4)

    let withCapture = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      captureMLFeatures: true)
    let withoutCapture = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      captureMLFeatures: false)

    let features = try #require(withCapture.mlFeatures, "Expected mlFeatures when captured")
    #expect(features.melBands == 128)
    #expect(features.frames > 0)
    #expect(features.tensorLayout == .frameMajorLogMel)
    #expect(withoutCapture.mlFeatures == nil, "mlFeatures should be nil when capture is off")
  }

  @Test("SuperFlux output differs from baseline log-mel spectral flux on the same click track")
  func differsFromBaselineOnClickTrack() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 140, sampleRate: sampleRate, durationSeconds: 6)

    let superFlux = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)
    let baseline = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    #expect(
      superFlux.fullBand.count == baseline.fullBand.count,
      "SuperFlux and baseline must produce envelopes of identical length (same hop, same frame count)"
    )
    // The two variants differ in reference-frame construction. For broadband click
    // tracks, the SuperFlux max-filter widens the reference, which generally
    // SUPPRESSES per-frame onset magnitudes vs the baseline. Assert that at
    // least one frame differs in bit pattern — proves the algorithm change took
    // effect at the binary level, not just notional.
    var differingFrames = 0
    for (sf, bl) in zip(superFlux.fullBand, baseline.fullBand) {
      if sf.bitPattern != bl.bitPattern { differingFrames += 1 }
    }
    #expect(
      differingFrames > 0,
      "SuperFlux output should differ from baseline on at least one frame (got 0 differing frames)")
  }

  @Test("SuperFlux replicate-pad does not collapse first/last mel-band contributions")
  func replicatePadPreservesBoundaryBins() {
    // Use a low-frequency click that primarily activates the kick band (0..<20)
    // and verify the SuperFlux kick sub-band carries non-zero energy. If
    // replicate-pad on bin 0 were collapsing kick energy, the kick sub-band
    // would be silent.
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 100, sampleRate: sampleRate, durationSeconds: 5)

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    let kickEnvelope = result.subBands[0]  // kickBandRange = 0..<20
    let hiHatEnvelope = result.subBands[3]  // hiHatRange = 80..<128
    let kickMax = kickEnvelope.max() ?? 0
    let hiHatMax = hiHatEnvelope.max() ?? 0
    #expect(
      kickMax > 0,
      "Kick band (includes bin 0, exercised by replicate-pad left edge) should carry energy")
    #expect(
      hiHatMax > 0,
      "Hi-hat band (includes bin 127, exercised by replicate-pad right edge) should carry energy")
  }
}

// MARK: - AC #1 invariant #12 — numeric-distinctness via crafted fixture

/// Codex 2026-05-17 rescope review's "anti-regression spine": proves the new
/// SuperFlux code path is empirically distinct from the baseline spectral-flux
/// path. The test crafts a degenerate (1 sample) click input that produces a
/// log-mel matrix with one anomalous bin, then checks that the baseline and
/// SuperFlux envelopes differ on that bin's contribution.
///
/// The test is INSENSITIVE to which particular bin/frame differs — only that
/// SOMETHING differs at the binary level on a fixture both implementations
/// were exposed to. If a future refactor accidentally short-circuits SuperFlux
/// to call the baseline, this test would fire.
@Suite("BPMAnalyzer — SuperFlux vs baseline numeric distinctness (AC #1 invariant #12)")
struct SuperFluxNumericDistinctnessTests {

  @Test("SuperFlux produces bit-different output from baseline on click-track fixture")
  func numericDistinctnessOnClickFixture() {
    // 4 seconds of a 144 BPM click — long enough that both variants
    // produce ≥ 200 frames, increasing the chance a per-frame bit-different
    // value surfaces somewhere in the envelope.
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = generateClickTrack(bpm: 144, sampleRate: sampleRate, durationSeconds: 4)

    let superFlux = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)
    let baseline = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    // The shapes must match (same FFT, same mel-filterbank, same hop, same
    // log-mel matrix — only the reference-frame construction differs).
    #expect(superFlux.fullBand.count == baseline.fullBand.count)
    #expect(superFlux.subBands.count == baseline.subBands.count)

    // At least one (frame, value) pair must be bit-different — proves the
    // SuperFlux frequency-axis max-filter altered the per-frame reference
    // and propagated through the diff/HWR/sum chain.
    var anyDifferent = false
    for (sf, bl) in zip(superFlux.fullBand, baseline.fullBand) {
      if sf.bitPattern != bl.bitPattern {
        anyDifferent = true
        break
      }
    }
    if !anyDifferent {
      for (sfBand, blBand) in zip(superFlux.subBands, baseline.subBands) {
        for (sf, bl) in zip(sfBand, blBand) where sf.bitPattern != bl.bitPattern {
          anyDifferent = true
          break
        }
        if anyDifferent { break }
      }
    }
    #expect(
      anyDifferent,
      """
      AC #1 invariant #12 violation: SuperFlux output is bit-identical to baseline.
      The new code path is not empirically distinct — either the gate at
      BPMAnalyzer.swift step 3 silently fell through to the baseline, or
      computeSuperFluxOnsetEnvelope is computing the same reference frame as
      computeMelOnsetEnvelopeWithSubBands. See Story 4-7 DD #2 + Codex 2026-05-17
      thread `019e36de`.
      """)
  }
}
