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
