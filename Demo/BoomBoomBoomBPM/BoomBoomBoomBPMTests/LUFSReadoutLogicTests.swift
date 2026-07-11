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
    #expect(LoudnessGraphView.integratedValue(-14.2) == "-14.2 LUFS")
  }

  @Test(
    "integratedValue is unavailable for non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func integratedUnavailable(_ value: Double) {
    #expect(LoudnessGraphView.integratedValue(value) == "unavailable")
  }

  // MARK: - truePeakValue

  @Test("truePeakValue formats a normal reading as %.1f dBTP")
  func truePeakNormal() {
    #expect(LoudnessGraphView.truePeakValue(-1.0) == "-1.0 dBTP")
  }

  @Test(
    "truePeakValue is unavailable for non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func truePeakUnavailable(_ value: Double) {
    #expect(LoudnessGraphView.truePeakValue(value) == "unavailable")
  }

  // MARK: - loudnessRangeValue

  @Test("loudnessRangeValue formats a normal reading as %.1f LU")
  func loudnessRangeNormal() {
    #expect(LoudnessGraphView.loudnessRangeValue(6.0) == "6.0 LU")
  }

  @Test("loudnessRangeValue is unavailable when nil (LRA absent, AC4)")
  func loudnessRangeNil() {
    #expect(LoudnessGraphView.loudnessRangeValue(nil) == "unavailable")
  }

  @Test(
    "loudnessRangeValue is unavailable for a non-nil non-finite / at-or-below-sentinel",
    arguments: [Double.nan, .infinity, -.infinity, LUFSReadoutLogicTests.sentinel, -120.0]
  )
  func loudnessRangeUnavailable(_ value: Double) {
    #expect(LoudnessGraphView.loudnessRangeValue(value) == "unavailable")
  }

  // MARK: - sentinel boundary

  @Test("a value exactly at the sentinel floor is unavailable; just above formats normally")
  func sentinelBoundary() {
    #expect(LoudnessGraphView.integratedValue(Self.sentinel) == "unavailable")
    #expect(LoudnessGraphView.integratedValue(-99.9) == "-99.9 LUFS")
    #expect(LoudnessGraphView.truePeakValue(Self.sentinel) == "unavailable")
    #expect(LoudnessGraphView.truePeakValue(-99.9) == "-99.9 dBTP")
    #expect(LoudnessGraphView.loudnessRangeValue(Self.sentinel) == "unavailable")
    #expect(LoudnessGraphView.loudnessRangeValue(-99.9) == "-99.9 LU")
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
      LoudnessGraphView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness (first 120 s)")
  }

  @Test("windowCaption is plain for a whole ~30 s file within a 120 s window")
  func windowCaptionWhole() {
    // count = 297 -> measured = 296*0.1 + 0.4 = 30.0; 30.0 < 119.9 -> plain.
    let r = Self.report(momentaryCount: 297, stepSeconds: 0.1)
    #expect(
      LoudnessGraphView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test("windowCaption is plain for a whole ~119 s file just under the 120 s cap (boundary)")
  func windowCaptionBoundary() {
    // count = 1187 -> measured = 1186*0.1 + 0.4 = 119.0; 119.0 < 119.9 -> plain.
    let r = Self.report(momentaryCount: 1187, stepSeconds: 0.1)
    #expect(
      LoudnessGraphView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test("windowCaption is plain for an empty momentary series")
  func windowCaptionEmptySeries() {
    let r = Self.report(momentaryCount: 0, stepSeconds: 0.1)
    #expect(
      LoudnessGraphView.windowCaption(report: r, analysisWindowSeconds: 120)
        == "Integrated loudness")
  }

  @Test(
    "windowCaption is plain for a non-positive / non-finite analysis window",
    arguments: [0.0, -30.0, Double.nan, .infinity]
  )
  func windowCaptionBadWindow(_ window: Double) {
    let r = Self.report(momentaryCount: 1197, stepSeconds: 0.1)
    #expect(
      LoudnessGraphView.windowCaption(report: r, analysisWindowSeconds: window)
        == "Integrated loudness")
  }

  // MARK: - Plot geometry (Story 10.4 UX rework — the LUFS-over-time graph)

  @Test("span is the start time of the last element over the longer series; degenerate -> 1")
  func spanFromSeries() {
    // 1201 momentary elements on the 0.1 s grid start at 0..120 s.
    #expect(
      LoudnessGraphView.span(momentaryCount: 1201, shortTermCount: 900, stepSeconds: 0.1)
        .isApproximately(120))
    // The longer series wins.
    #expect(
      LoudnessGraphView.span(momentaryCount: 11, shortTermCount: 21, stepSeconds: 0.1)
        .isApproximately(2))
    // Degenerate: empty/singleton series or a bad step -> the 1 s division guard.
    #expect(LoudnessGraphView.span(momentaryCount: 1, shortTermCount: 0, stepSeconds: 0.1) == 1)
    #expect(LoudnessGraphView.span(momentaryCount: 100, shortTermCount: 0, stepSeconds: 0) == 1)
    #expect(
      LoudnessGraphView.span(momentaryCount: 100, shortTermCount: 0, stepSeconds: .nan) == 1)
  }

  @Test("x maps time/span*width, clamps to [0, width], and defends degenerate input")
  func xMapping() {
    #expect(LoudnessGraphView.x(forTime: 60, span: 120, width: 500).isApproximately(250))
    #expect(LoudnessGraphView.x(forTime: 500, span: 120, width: 500).isApproximately(500))
    #expect(LoudnessGraphView.x(forTime: -5, span: 120, width: 500).isApproximately(0))
    #expect(LoudnessGraphView.x(forTime: .nan, span: 120, width: 500).isApproximately(0))
    #expect(LoudnessGraphView.x(forTime: 60, span: 0, width: 500).isApproximately(0))
  }

  @Test("time inverts x over the span for click-to-scrub; degenerate -> nil")
  func timeInversion() {
    #expect(LoudnessGraphView.time(forX: 250, span: 120, width: 500)!.isApproximately(60))
    #expect(LoudnessGraphView.time(forX: -10, span: 120, width: 500)!.isApproximately(0))
    #expect(LoudnessGraphView.time(forX: 999, span: 120, width: 500)!.isApproximately(120))
    #expect(LoudnessGraphView.time(forX: .nan, span: 120, width: 500) == nil)
    #expect(LoudnessGraphView.time(forX: 250, span: 120, width: 0) == nil)
    #expect(LoudnessGraphView.time(forX: 250, span: 0, width: 500) == nil)
  }

  @Test("y maps the fixed -60..+6 range top-down and pins out-of-range values to the edges")
  func yMapping() {
    // +6 (ceiling) -> 0; -60 (floor) -> height.
    #expect(LoudnessGraphView.y(forLUFS: 6, height: 132).isApproximately(0))
    #expect(LoudnessGraphView.y(forLUFS: -60, height: 132).isApproximately(132))
    // Midpoint of the 66 dB range: -27 -> height/2.
    #expect(LoudnessGraphView.y(forLUFS: -27, height: 132).isApproximately(66))
    // The -100 silence sentinel and any below-floor value pin to the bottom edge.
    #expect(LoudnessGraphView.y(forLUFS: -100, height: 132).isApproximately(132))
    // Above-ceiling pins to the top edge; non-finite pins to the bottom.
    #expect(LoudnessGraphView.y(forLUFS: 12, height: 132).isApproximately(0))
    #expect(LoudnessGraphView.y(forLUFS: .nan, height: 132).isApproximately(132))
    // Degenerate height -> 0.
    #expect(LoudnessGraphView.y(forLUFS: -14, height: 0).isApproximately(0))
  }

  @Test("timeTickStep picks the smallest nice step yielding <= 8 ticks; degenerate -> 0")
  func tickSteps() {
    #expect(LoudnessGraphView.timeTickStep(span: 30).isApproximately(5))
    #expect(LoudnessGraphView.timeTickStep(span: 120).isApproximately(15))
    #expect(LoudnessGraphView.timeTickStep(span: 600).isApproximately(120))
    #expect(LoudnessGraphView.timeTickStep(span: 0) == 0)
    #expect(LoudnessGraphView.timeTickStep(span: .nan) == 0)
  }

  @Test("timeLabel renders M:SS")
  func timeLabels() {
    #expect(LoudnessGraphView.timeLabel(0) == "0:00")
    #expect(LoudnessGraphView.timeLabel(65) == "1:05")
    #expect(LoudnessGraphView.timeLabel(600) == "10:00")
    #expect(LoudnessGraphView.timeLabel(.nan) == "0:00")
    #expect(LoudnessGraphView.timeLabel(-3) == "0:00")
  }
}

extension Double {
  fileprivate func isApproximately(_ other: Double, tolerance: Double = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}

extension CGFloat {
  fileprivate func isApproximately(_ other: CGFloat, tolerance: CGFloat = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}
