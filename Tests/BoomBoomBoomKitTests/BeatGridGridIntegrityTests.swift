import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BeatGridGridIntegrityTests")
struct BeatGridGridIntegrityTests {

  /// Builds `count` beats whose inter-beat intervals are `beatPeriod` apart,
  /// except that the intervals at `offGridIntervals` (1-based interval index, i.e.
  /// the gap leading into beat `i`) are stretched to `1.5 * beatPeriod` so they
  /// deviate by 50% — well past the 25% off-grid tolerance.
  private func makeBeats(
    count: Int, beatPeriod: Double, offGridIntervals: Set<Int> = []
  ) -> [BeatTimestamp] {
    var beats: [BeatTimestamp] = []
    var t = 0.0
    beats.append(BeatTimestamp(presentationTime: t, confidence: 1.0, strength: 1.0))
    for i in 1..<max(1, count) {
      let gap = offGridIntervals.contains(i) ? beatPeriod * 1.5 : beatPeriod
      t += gap
      beats.append(BeatTimestamp(presentationTime: t, confidence: 1.0, strength: 1.0))
    }
    return beats
  }

  @Test("a clean grid (all intervals == beatPeriod) is never shredded")
  func cleanGrid() {
    let beatPeriod = 60.0 / 120.0  // 0.5 s
    let clean = makeBeats(count: 16, beatPeriod: beatPeriod)
    #expect(BeatGridGridIntegrity.isShredded(beats: clean, beatPeriod: beatPeriod) == false)
  }

  @Test("a shredded grid (> 20% of intervals off-grid) is shredded")
  func shreddedGrid() {
    let beatPeriod = 60.0 / 120.0
    // 16 beats → 15 intervals; 6 off-grid (40%) is well over the 20% limit.
    let shredded = makeBeats(
      count: 16, beatPeriod: beatPeriod, offGridIntervals: [2, 4, 6, 8, 10, 12])
    #expect(BeatGridGridIntegrity.isShredded(beats: shredded, beatPeriod: beatPeriod) == true)
  }

  @Test("exactly 3 of 15 off-grid (0.20, not > 0.20) is NOT shredded — locks the strict > boundary")
  func justUnderFractionLimit() {
    let beatPeriod = 60.0 / 120.0
    // 3 / 15 == 0.20, and the predicate is strict `>`, so this stays false.
    let beats = makeBeats(count: 16, beatPeriod: beatPeriod, offGridIntervals: [2, 6, 10])
    #expect(BeatGridGridIntegrity.isShredded(beats: beats, beatPeriod: beatPeriod) == false)
  }

  @Test("4 of 15 off-grid (0.266…) IS shredded")
  func justOverFractionLimit() {
    let beatPeriod = 60.0 / 120.0
    let beats = makeBeats(count: 16, beatPeriod: beatPeriod, offGridIntervals: [2, 6, 10, 14])
    #expect(BeatGridGridIntegrity.isShredded(beats: beats, beatPeriod: beatPeriod) == true)
  }

  @Test("an interval deviating by exactly 25% is NOT off-grid (predicate is > tolerance)")
  func boundaryDeviationNotCounted() {
    let beatPeriod = 60.0 / 120.0  // 0.5 s
    // Every gap stretched by exactly 25% (0.625 s). abs(dt - p)/p == 0.25, which is
    // NOT > 0.25, so zero intervals count as off-grid → not shredded.
    var beats: [BeatTimestamp] = []
    var t = 0.0
    beats.append(BeatTimestamp(presentationTime: t, confidence: 1.0, strength: 1.0))
    for _ in 1..<16 {
      t += beatPeriod * 1.25
      beats.append(BeatTimestamp(presentationTime: t, confidence: 1.0, strength: 1.0))
    }
    #expect(BeatGridGridIntegrity.isShredded(beats: beats, beatPeriod: beatPeriod) == false)
  }

  @Test("empty and single-beat arrays (no intervals) are never shredded")
  func tooFewBeats() {
    let beatPeriod = 60.0 / 120.0
    #expect(BeatGridGridIntegrity.isShredded(beats: [], beatPeriod: beatPeriod) == false)
    let single = [BeatTimestamp(presentationTime: 0.0, confidence: 1.0, strength: 1.0)]
    #expect(BeatGridGridIntegrity.isShredded(beats: single, beatPeriod: beatPeriod) == false)
  }

  @Test("the relative comparison is period-scaled (non-120 tempo)")
  func periodScaledForOtherTempo() {
    let beatPeriod = 60.0 / 174.0  // ≈ 0.3448 s (DnB-ish)
    let clean = makeBeats(count: 16, beatPeriod: beatPeriod)
    #expect(BeatGridGridIntegrity.isShredded(beats: clean, beatPeriod: beatPeriod) == false)
    let shredded = makeBeats(
      count: 16, beatPeriod: beatPeriod, offGridIntervals: [2, 4, 6, 8, 10, 12])
    #expect(BeatGridGridIntegrity.isShredded(beats: shredded, beatPeriod: beatPeriod) == true)
  }

  @Test("tuning constants are pinned so a future edit is deliberate and visible")
  func constantsPinned() {
    #expect(BeatGridGridIntegrity.gridDeviationTolerance == 0.25)
    #expect(BeatGridGridIntegrity.gridOffGridFractionLimit == 0.20)
  }
}
