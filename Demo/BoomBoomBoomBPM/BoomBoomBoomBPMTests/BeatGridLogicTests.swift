import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Pure-logic tests for the beat-grid overlay: the extrapolated-grid generator
// (the trustworthy `anchor + period·n` line) and the waveform peak downsampler.
// Both are deterministic and need no audio file or UI.
@Suite("Beat-grid overlay logic")
struct BeatGridLogicTests {

  // MARK: - extrapolatedBeatTimes

  @Test("extrapolated grid: count, endpoints, and 0.5s spacing at 120 BPM from anchor 0")
  func extrapolatedFromZero() {
    let times = BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 120, span: 10)
    // 0.0, 0.5, … 10.0 inclusive -> 21 beats.
    #expect(times.count == 21)
    #expect(times.first == 0)
    #expect((times.last ?? -1).isApproximately(10))
    for i in 1..<times.count {
      #expect((times[i] - times[i - 1]).isApproximately(0.5))
    }
  }

  @Test("extrapolated grid includes the anchor and extends backward to cover [0, span]")
  func extrapolatedAnchorAligned() {
    let times = BeatGridView.extrapolatedBeatTimes(anchor: 1.0, tempo: 120, span: 10)
    // Anchor 1.0 with period 0.5 -> the grid lands on 1.0 and back-fills 0.5, 0.0.
    #expect(times.contains { $0.isApproximately(1.0) })
    #expect(times.contains { $0.isApproximately(0.0) })
    #expect(times.allSatisfy { $0 >= 0 && $0 <= 10 + 1e-9 })
  }

  @Test("extrapolated grid returns empty on the zero-tempo sentinel")
  func extrapolatedZeroTempo() {
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 0, span: 10).isEmpty)
  }

  @Test("extrapolated grid returns empty for nil anchor / non-finite tempo / non-positive span")
  func extrapolatedGuards() {
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: nil, tempo: 120, span: 10).isEmpty)
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: .nan, span: 10).isEmpty)
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: .infinity, span: 10).isEmpty)
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 120, span: 0).isEmpty)
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 120, span: -5).isEmpty)
    #expect(BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 120, span: .nan).isEmpty)
  }

  @Test("extrapolated grid caps the emitted count so a huge span cannot allocate unbounded")
  func extrapolatedCapped() {
    let times = BeatGridView.extrapolatedBeatTimes(anchor: 0, tempo: 120, span: 1e9)
    #expect(times.count == 100_000)
  }

  // MARK: - Waveform.peaks

  @Test("peaks: empty samples or non-positive columns yield empty")
  func peaksDegenerate() {
    #expect(Waveform.peaks(fromSamples: [], columns: 10).isEmpty)
    #expect(Waveform.peaks(fromSamples: [0.1, 0.2], columns: 0).isEmpty)
    #expect(Waveform.peaks(fromSamples: [0.1, 0.2], columns: -3).isEmpty)
  }

  @Test("peaks: max-abs fold over evenly-divided buckets")
  func peaksFold() {
    // n=4, cols=2 -> bucket0 = max(|0|,|0.5|)=0.5, bucket1 = max(|-0.8|,|0.2|)=0.8.
    let out = Waveform.peaks(fromSamples: [0, 0.5, -0.8, 0.2], columns: 2)
    #expect(out.count == 2)
    #expect(out[0].isApproximately(0.5))
    #expect(out[1].isApproximately(0.8))
  }

  @Test("peaks: fewer samples than columns returns one peak per sample, no zero padding")
  func peaksFewerSamples() {
    let out = Waveform.peaks(fromSamples: [0.1, -0.2, 0.3], columns: 10)
    #expect(out.count == 3)
    #expect(out[0].isApproximately(0.1))
    #expect(out[1].isApproximately(0.2))
    #expect(out[2].isApproximately(0.3))
  }

  // MARK: - clickSeekTime (click-to-scrub: content-x → snapped seek target)

  @Test("clickSeekTime maps content-x through pointsPerSecond and snaps to the nearest beat")
  func clickSnapsToNearestBeat() {
    let beats = [0.0, 2.0, 4.0]
    // x=160 @ 16pps -> rawTime 10 -> nearest is 4.0 (after the last beat).
    #expect(
      BeatGridView.clickSeekTime(contentX: 160, pointsPerSecond: 16, beatTimes: beats)!
        .isApproximately(4))
    // rawTime 1.9 -> nearest is 2.0 (snap forward).
    #expect(
      BeatGridView.clickSeekTime(contentX: 30.4, pointsPerSecond: 16, beatTimes: beats)!
        .isApproximately(2))
    // rawTime 0.4 -> nearest is 0.0 (snap back).
    #expect(
      BeatGridView.clickSeekTime(contentX: 6.4, pointsPerSecond: 16, beatTimes: beats)!
        .isApproximately(0))
  }

  @Test("clickSeekTime resolves an exact midpoint to the earlier beat")
  func clickMidpointTieEarlierBeat() {
    // rawTime 1.0 is exactly between 0.0 and 2.0 -> earlier beat wins.
    #expect(
      BeatGridView.clickSeekTime(contentX: 16, pointsPerSecond: 16, beatTimes: [0.0, 2.0])!
        .isApproximately(0))
  }

  @Test("clickSeekTime with no beats returns the raw clicked time; negative x clamps to 0")
  func clickWithoutBeats() {
    #expect(
      BeatGridView.clickSeekTime(contentX: 160, pointsPerSecond: 16, beatTimes: [])!
        .isApproximately(10))
    #expect(
      BeatGridView.clickSeekTime(contentX: -50, pointsPerSecond: 16, beatTimes: [])!
        .isApproximately(0))
  }

  @Test("clickSeekTime ignores non-finite and negative beat entries, rejects degenerate input")
  func clickGuards() {
    // Non-finite beats are skipped; the finite one wins.
    #expect(
      BeatGridView.clickSeekTime(
        contentX: 160, pointsPerSecond: 16, beatTimes: [.nan, .infinity, 9.0])!
        .isApproximately(9))
    // A negative entry is skipped even when it is numerically NEARER than the
    // valid beat (the `>= 0` result contract): rawTime 1, |-0.5 - 1| < |9 - 1|.
    #expect(
      BeatGridView.clickSeekTime(contentX: 16, pointsPerSecond: 16, beatTimes: [-0.5, 9.0])!
        .isApproximately(9))
    // Only invalid entries -> behaves like an empty list (raw clicked time).
    #expect(
      BeatGridView.clickSeekTime(contentX: 160, pointsPerSecond: 16, beatTimes: [-1.0, .nan])!
        .isApproximately(10))
    // Degenerate x / pps -> nil (tap ignored).
    #expect(BeatGridView.clickSeekTime(contentX: .nan, pointsPerSecond: 16, beatTimes: []) == nil)
    #expect(BeatGridView.clickSeekTime(contentX: 10, pointsPerSecond: 0, beatTimes: []) == nil)
    #expect(BeatGridView.clickSeekTime(contentX: 10, pointsPerSecond: -4, beatTimes: []) == nil)
    #expect(BeatGridView.clickSeekTime(contentX: 10, pointsPerSecond: .nan, beatTimes: []) == nil)
  }

  // MARK: - scrubberX (playhead marker in the zoomed coordinate system)

  @Test("scrubberX maps time*pointsPerSecond and clamps to [0, contentWidth]")
  func scrubberXMapsAndClamps() {
    #expect(
      BeatGridView.scrubberX(time: 5, pointsPerSecond: 16, contentWidth: 1_000)
        .isApproximately(80))
    // Playback past the analyzed span pins at the right edge.
    #expect(
      BeatGridView.scrubberX(time: 100, pointsPerSecond: 16, contentWidth: 1_000)
        .isApproximately(1_000))
    #expect(
      BeatGridView.scrubberX(time: -3, pointsPerSecond: 16, contentWidth: 1_000)
        .isApproximately(0))
  }

  @Test("scrubberX defends non-finite and degenerate input")
  func scrubberXGuards() {
    #expect(
      BeatGridView.scrubberX(time: .nan, pointsPerSecond: 16, contentWidth: 100)
        .isApproximately(0))
    #expect(
      BeatGridView.scrubberX(time: 5, pointsPerSecond: 0, contentWidth: 100).isApproximately(0))
    #expect(
      BeatGridView.scrubberX(time: 5, pointsPerSecond: 16, contentWidth: .nan).isApproximately(0))
    #expect(
      BeatGridView.scrubberX(time: 5, pointsPerSecond: 16, contentWidth: -1).isApproximately(0))
  }

  // MARK: - Readout labels (FR-44; moved from the deleted timeline view)

  @Test("downbeatStatusLabel maps the real tri-state (no 'partial')")
  func downbeatStatusLabels() {
    let est = DownbeatEstimate(
      beats: [BeatTimestamp(presentationTime: 0, confidence: 1, strength: 1)],
      meter: MeterEstimate(beatsPerBar: 4, source: .assumed), confidence: 0.8, phaseIndex: 0)
    #expect(BeatGridView.downbeatStatusLabel(.detected(estimate: est)) == "detected")
    #expect(BeatGridView.downbeatStatusLabel(.noneDetected) == "not-detected")
    #expect(BeatGridView.downbeatStatusLabel(.notAttempted) == "not-attempted")
  }

  @Test("tempoValue renders %.2f BPM, and 'unavailable' for the 0.0 sentinel")
  func tempoValues() {
    #expect(BeatGridView.tempoValue(128) == "128.00 BPM")
    #expect(BeatGridView.tempoValue(0) == "unavailable")
    #expect(BeatGridView.tempoValue(.nan) == "unavailable")
    #expect(BeatGridView.tempoValue(-5) == "unavailable")
  }

  @Test("gridConfidenceValue is %.2f clamped to [0, 1]")
  func gridConfidenceValues() {
    #expect(BeatGridView.gridConfidenceValue(0.873) == "0.87")
    #expect(BeatGridView.gridConfidenceValue(1.5) == "1.00")
    #expect(BeatGridView.gridConfidenceValue(-0.2) == "0.00")
    #expect(BeatGridView.gridConfidenceValue(.nan) == "0.00")
  }
}

extension Double {
  fileprivate func isApproximately(_ other: Double, tolerance: Double = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}

extension Float {
  fileprivate func isApproximately(_ other: Float, tolerance: Float = 1e-5) -> Bool {
    abs(self - other) <= tolerance
  }
}

extension CGFloat {
  fileprivate func isApproximately(_ other: CGFloat, tolerance: CGFloat = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}
