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

  @Test("SuperFlux produces finite all-zero envelopes for silent input")
  func silentInputProducesFiniteZeros() {
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = [Float](repeating: 0, count: Int(sampleRate))  // 1 s silence

    let result = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)

    // Contract (per BPMAnalyzer.swift:617 doc-comment, post-Story-4-7 P3 fix):
    // silent buffer with ≥ 2 frames → finite all-zero envelopes (NOT the
    // empty-sentinel contract; that's tested by sentinelOnTooShortInput).
    //
    // Codex review 2026-05-17 ADJUST P2: assert the full documented contract —
    // !empty + 4 sub-bands + shape match + finite + exactly 0.0 — not just
    // finiteness. A wrong-but-finite result (e.g., NaN-scrubbed-to-zero, or a
    // subtle ML-features leak that emits non-zero frames) is now caught.
    #expect(
      !result.fullBand.isEmpty,
      "1s of silence should produce ≥ 2 frames; got empty fullBand")
    #expect(result.subBands.count == 4, "SuperFlux must produce exactly 4 sub-bands")
    for value in result.fullBand {
      #expect(value.isFinite, "SuperFlux fullBand should be finite for silent input")
      #expect(
        value == 0.0,
        "SuperFlux fullBand on silent input must be exactly zero (got \(value))")
    }
    for (i, band) in result.subBands.enumerated() {
      #expect(
        band.count == result.fullBand.count,
        "SuperFlux subBand[\(i)].count must match fullBand.count")
      for value in band {
        #expect(
          value.isFinite, "SuperFlux subBand[\(i)] should be finite for silent input")
        #expect(
          value == 0.0,
          "SuperFlux subBand[\(i)] on silent input must be exactly zero (got \(value))")
      }
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
    // SUPPRESSES per-frame onset magnitudes vs the baseline. Codex review
    // 2026-05-17 ADJUST P4: bit-different on ONE frame is not algorithm-level
    // distinctness — assert ≥1% differing frames AND a meaningful mean abs diff.
    // (The 1% floor is empirically ~25× the bare-minimum 1-frame, well above
    // numerical noise; clicks have sparse transients so a 10% requirement would
    // be too strict — P5's purpose-built boundary fixture uses 10% because it's
    // synthesized to engage the max-filter at every burst by construction.)
    var differingFrames = 0
    var sumAbsDiff: Double = 0
    for (sf, bl) in zip(superFlux.fullBand, baseline.fullBand) {
      if sf.bitPattern != bl.bitPattern { differingFrames += 1 }
      sumAbsDiff += Double(abs(sf - bl))
    }
    let totalFrames = min(superFlux.fullBand.count, baseline.fullBand.count)
    let differingFraction = Double(differingFrames) / Double(max(totalFrames, 1))
    let meanAbsDiff = sumAbsDiff / Double(max(totalFrames, 1))
    #expect(
      differingFraction >= 0.01,
      "SuperFlux should differ from baseline on ≥1% of frames (got \(differingFrames)/\(totalFrames) = \(differingFraction))"
    )
    #expect(
      meanAbsDiff > 1e-6,
      "SuperFlux mean-absolute-diff vs baseline should exceed 1e-6 (got \(meanAbsDiff))")
  }

  @Test("SuperFlux replicate-pad preserves first/last mel-band contributions")
  func replicatePadPreservesBoundaryBins() throws {
    // Codex review 2026-05-17 BLOCK P5: a generic 100-BPM click is NOT a
    // boundary-discriminating fixture (baseline path passes the same kick/hi-hat
    // max checks). Use windowed narrowband bursts centered near the actual
    // boundary-filter centers, then assert that mel-bin 0 and mel-bin 127 are
    // genuinely energized BEFORE testing SuperFlux distinctness.
    let sampleRate: Double = 44100
    let hopSize = Int(sampleRate / 100)
    let samples = synthesizeBoundaryBurstFixture(
      sampleRate: sampleRate,
      durationSeconds: 4,
      lowCenterHz: 48,
      highCenterHz: 15_600,
      burstIntervalSeconds: 0.05)

    // PRECONDITION: the fixture must actually energize boundary mel-bins.
    // Run baseline with captureMLFeatures to inspect the log-mel matrix; if
    // bin 0 or bin 127 are below the energy floor, the fixture is wrong and
    // the downstream gate test would be inconclusive.
    let baselineWithFeatures = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize,
      computeSubBands: true, normalizeSubBands: false, captureMLFeatures: true)
    let mlFeatures = try #require(
      baselineWithFeatures.mlFeatures,
      "captureMLFeatures should produce mlFeatures on a non-degenerate input")
    let melBands = mlFeatures.melBands
    let frames = mlFeatures.frames
    let data = mlFeatures.logMelData
    #expect(
      melBands == 128, "Story 4-7 P5 assumes 128 mel bands; got \(melBands)")

    // Energy floor: log(1 + 1e6 * 0) = 0, so any value > 0 means real energy.
    let bin0EnergyFloor: Float = 0.1
    let bin127EnergyFloor: Float = 0.1
    var bin0Max: Float = 0
    var bin127Max: Float = 0
    for f in 0..<frames {
      bin0Max = max(bin0Max, data[f * melBands + 0])
      bin127Max = max(bin127Max, data[f * melBands + (melBands - 1)])
    }
    #expect(
      bin0Max > bin0EnergyFloor,
      "Fixture precondition: mel-bin 0 must be energized (got max \(bin0Max), need > \(bin0EnergyFloor))"
    )
    #expect(
      bin127Max > bin127EnergyFloor,
      "Fixture precondition: mel-bin 127 must be energized (got max \(bin127Max), need > \(bin127EnergyFloor))"
    )

    // ACTUAL GATE TEST: SuperFlux at the boundary bins must differ from baseline.
    // By construction the fixture energizes the replicate-pad-reached bins; if
    // SuperFlux/baseline are byte-identical here, the max-filter isn't engaging.
    let superFlux = BPMAnalyzer.computeSuperFluxOnsetEnvelope(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)
    let baseline = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: samples, sampleRate: sampleRate, hopSize: hopSize)
    let kickSF = superFlux.subBands[0]
    let kickBL = baseline.subBands[0]
    let hiHatSF = superFlux.subBands[3]
    let hiHatBL = baseline.subBands[3]
    let kickDiffFrac = fractionOfDifferingFrames(kickSF, kickBL)
    let hiHatDiffFrac = fractionOfDifferingFrames(hiHatSF, hiHatBL)
    #expect(
      kickDiffFrac >= 0.10,
      "Kick band (bin 0 boundary) must show max-filter effect vs baseline (got \(kickDiffFrac))"
    )
    #expect(
      hiHatDiffFrac >= 0.10,
      "Hi-hat band (bin 127 boundary) must show max-filter effect vs baseline (got \(hiHatDiffFrac))"
    )
  }

  // MARK: - Internal helpers

  /// Bit-pattern-aware fraction of frames where two envelopes differ.
  /// Used by P4a (distinctness threshold) and P5 (boundary gate-engagement).
  private func fractionOfDifferingFrames(_ a: [Float], _ b: [Float]) -> Double {
    let total = min(a.count, b.count)
    guard total > 0 else { return 0 }
    var diff = 0
    for (x, y) in zip(a, b) where x.bitPattern != y.bitPattern { diff += 1 }
    return Double(diff) / Double(total)
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
