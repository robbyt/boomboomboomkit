import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BarPhaseTests")
struct BarPhaseTests {

  // 120 BPM → 0.5 s beat period, 4/4.

  @Test("phase 0 at the origin")
  func phaseZeroAtOrigin() {
    #expect(BarPhase.index(ofTime: 0.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 0)
  }

  @Test("one beat advances the phase; a full bar wraps to 0")
  func fullBarWrap() {
    #expect(BarPhase.index(ofTime: 0.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 1)
    #expect(BarPhase.index(ofTime: 1.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 2)
    #expect(BarPhase.index(ofTime: 1.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 3)
    #expect(BarPhase.index(ofTime: 2.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 0)
  }

  @Test("negative offset wraps into range via the sign correction")
  func negativeOffsetWraps() {
    // time before firstTime → raw negative → the `+ beatsPerBar` correction.
    // (0.0 - 0.5) / 0.5 = -1 → ((-1 % 4) + 4) % 4 == 3
    #expect(BarPhase.index(ofTime: 0.0, firstTime: 0.5, beatPeriod: 0.5, beatsPerBar: 4) == 3)
    // (0.0 - 1.5) / 0.5 = -3 → ((-3 % 4) + 4) % 4 == 1
    #expect(BarPhase.index(ofTime: 0.0, firstTime: 1.5, beatPeriod: 0.5, beatsPerBar: 4) == 1)
  }

  @Test("x.5 rounding boundary follows Int((·).rounded()) (round half away from zero)")
  func roundingBoundary() {
    // (0.25 - 0.0) / 0.5 = 0.5 → rounded() == 1.0 → Int 1 → phase 1
    #expect(BarPhase.index(ofTime: 0.25, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 1)
    // (0.75 - 0.0) / 0.5 = 1.5 → rounded() == 2.0 → Int 2 → phase 2
    #expect(BarPhase.index(ofTime: 0.75, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 2)
  }

  @Test("phase wraps across multiple bars")
  func multiBarWrap() {
    // (4.5 - 0.0) / 0.5 = 9 → 9 % 4 == 1
    #expect(BarPhase.index(ofTime: 4.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 4) == 1)
  }

  @Test("beatsPerBar == 1 collapses every input to 0")
  func singleBeatPerBar() {
    #expect(BarPhase.index(ofTime: 0.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 1) == 0)
    #expect(BarPhase.index(ofTime: 0.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 1) == 0)
    #expect(BarPhase.index(ofTime: 3.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 1) == 0)
  }

  @Test("non-4/4 beatsPerBar uses the supplied modulus")
  func nonFourFourMeter() {
    // beatsPerBar == 3: raw indices 0..5 fold to 0,1,2,0,1,2.
    #expect(BarPhase.index(ofTime: 0.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 3) == 0)
    #expect(BarPhase.index(ofTime: 1.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 3) == 2)
    #expect(BarPhase.index(ofTime: 1.5, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 3) == 0)
    #expect(BarPhase.index(ofTime: 2.0, firstTime: 0.0, beatPeriod: 0.5, beatsPerBar: 3) == 1)
  }
}
