import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Pure-logic tests for the LUFS readout: the FR-44 value formatters and the
// DD7 honest measurement-window caption. All deterministic — no audio, no UI.
// The formatters + `windowCaption` are `nonisolated static`, so these read them
// off the main actor (the demo builds `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
@Suite("LUFS readout logic")
struct LUFSReadoutLogicTests {

  // The `-100.0` sentinel floor — a value at OR below it (or non-finite) is
  // "unavailable" (silence / non-measurable), never a `-100.0` leak.
  private static let sentinel = LUFSReport.sentinelFloor  // -100.0

  // A report whose momentary series has an exact `count` on a given
  // `stepSeconds` grid — the only two fields `windowCaption` reads. The scalar
  // values are benign finite placeholders.
  private static func report(momentaryCount: Int, stepSeconds: Double) -> LUFSReport {
    LUFSReport(
      integratedLUFS: -14.0,
      maxTruePeakDBTP: -1.0,
      loudnessRangeLU: 6.0,
      lraLowLUFS: -18.0,
      lraHighLUFS: -12.0,
      momentaryLUFS: Array(repeating: -20.0, count: momentaryCount),
      shortTermLUFS: [],
      stepSeconds: stepSeconds)
  }

  // MARK: - integratedValue

  @Test("integratedValue formats a normal reading as %.1f LUFS")
  func integratedNormal() {
    #expect(LUFSReadoutView.integratedValue(-14.2) == "-14.2 LUFS")
  }

  @Test(
    "integratedValue is unavailable for non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func integratedUnavailable(_ value: Double) {
    #expect(LUFSReadoutView.integratedValue(value) == "unavailable")
  }

  // MARK: - truePeakValue

  @Test("truePeakValue formats a normal reading as %.1f dBTP")
  func truePeakNormal() {
    #expect(LUFSReadoutView.truePeakValue(-1.0) == "-1.0 dBTP")
  }

  @Test(
    "truePeakValue is unavailable for non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func truePeakUnavailable(_ value: Double) {
    #expect(LUFSReadoutView.truePeakValue(value) == "unavailable")
  }

  // MARK: - loudnessRangeValue

  @Test("loudnessRangeValue formats a normal reading as %.1f LU")
  func loudnessRangeNormal() {
    #expect(LUFSReadoutView.loudnessRangeValue(6.0) == "6.0 LU")
  }

  @Test("loudnessRangeValue is unavailable when nil (LRA absent, AC4)")
  func loudnessRangeNil() {
    #expect(LUFSReadoutView.loudnessRangeValue(nil) == "unavailable")
  }

  @Test(
    "loudnessRangeValue is unavailable for a non-nil non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func loudnessRangeUnavailable(_ value: Double) {
    #expect(LUFSReadoutView.loudnessRangeValue(value) == "unavailable")
  }

  // MARK: - sentinel boundary

  @Test("a value exactly at the sentinel floor is unavailable; just above formats normally")
  func sentinelBoundary() {
    #expect(LUFSReadoutView.integratedValue(Self.sentinel) == "unavailable")
    #expect(LUFSReadoutView.integratedValue(-99.9) == "-99.9 LUFS")
    #expect(LUFSReadoutView.truePeakValue(Self.sentinel) == "unavailable")
    #expect(LUFSReadoutView.truePeakValue(-99.9) == "-99.9 dBTP")
    #expect(LUFSReadoutView.loudnessRangeValue(Self.sentinel) == "unavailable")
    #expect(LUFSReadoutView.loudnessRangeValue(-99.9) == "-99.9 LU")
  }

  // MARK: - windowCaption (DD7)
  //
  // Counts are the values a REAL analyzer emits (400 ms blocks on a 100 ms
  // grid: count ~= 10*span - 3), NOT the naive span/step. The span is
  // reconstructed from the END of the last block: (count-1)*step + 0.4.

  @Test("windowCaption qualifies a truncated 120 s window (the DD7 regression guard)")
  func windowCaptionTruncated() {
    // count = 1197 -> measured = 1196*0.1 + 0.4 = 120.0 >= 120 - 0.1 -> truncated.
    let r = Self.report(momentaryCount: 1197, stepSeconds: 0.1)
    #expect(
      LUFSReadoutView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness (first 120 s)")
  }

  @Test("windowCaption is plain for a whole ~30 s file within a 120 s window")
  func windowCaptionWhole() {
    // count = 297 -> measured = 296*0.1 + 0.4 = 30.0; 30.0 < 119.9 -> plain.
    let r = Self.report(momentaryCount: 297, stepSeconds: 0.1)
    #expect(
      LUFSReadoutView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test("windowCaption is plain for a whole ~119 s file just under the 120 s cap (boundary)")
  func windowCaptionBoundary() {
    // count = 1187 -> measured = 1186*0.1 + 0.4 = 119.0; 119.0 < 119.9 -> plain.
    let r = Self.report(momentaryCount: 1187, stepSeconds: 0.1)
    #expect(
      LUFSReadoutView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test("windowCaption is plain for an empty momentary series")
  func windowCaptionEmptySeries() {
    let r = Self.report(momentaryCount: 0, stepSeconds: 0.1)
    #expect(
      LUFSReadoutView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test(
    "windowCaption is plain for a non-positive / non-finite analysis window",
    arguments: [0.0, -30.0, Double.nan, .infinity]
  )
  func windowCaptionBadWindow(_ window: Double) {
    let r = Self.report(momentaryCount: 1197, stepSeconds: 0.1)
    #expect(
      LUFSReadoutView.windowCaption(report: r, analysisWindowSeconds: window)
        == "Integrated loudness")
  }
}
