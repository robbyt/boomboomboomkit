//
//  StructuralDropAnalyzerTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.11 tests for the drop-anchored downbeat estimator (StructuralDropAnalyzer),
//  the DownbeatStrategy selector, the .combined combiner, and the byte-identity /
//  containment locks.
//
//  The estimator is tested DIRECTLY with fully-controlled synthetic energy contours
//  (planted-drop independent ground truth) + synthetic beat grids — the DP tracker
//  is not in the loop, so phase assertions are deterministic. One integration test
//  exercises the real wiring through BeatGridAnalyzer. The combiner is tested with
//  constructed metrical Outcomes + drop Resolutions (no audio).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("StructuralDropAnalyzerTests")
struct StructuralDropAnalyzerTests {

  // MARK: - Synthetic fixtures (independent ground truth)

  /// 20 frames/sec contour rate (≈ the 50 ms hop computeContour uses).
  private static let rate = 20.0

  /// A constant-tempo 4/4 beat grid (file-relative `presentationTime`).
  private static func beats(tempo: Double, bars: Int, beatsPerBar: Int = 4) -> [BeatTimestamp] {
    let beatPeriod = 60.0 / tempo
    return (0..<(bars * beatsPerBar)).map {
      BeatTimestamp(presentationTime: Double($0) * beatPeriod, confidence: 1, strength: 1)
    }
  }

  /// Builds a contour where `low(frame)` is the low-band RMS level and `high(frame)`
  /// the high-band RMS level; broadband is the full mix (`low + high`).
  private static func contour(
    frames: Int, low: (Int) -> Float, high: (Int) -> Float = { _ in 0 }
  ) -> StructuralDropAnalyzer.Contour {
    var lowArr = [Float](repeating: 0, count: frames)
    var broad = [Float](repeating: 0, count: frames)
    var highArr = [Float](repeating: 0, count: frames)
    for i in 0..<frames {
      let l = low(i)
      let h = high(i)
      lowArr[i] = l
      highArr[i] = h
      broad[i] = l + h
    }
    return StructuralDropAnalyzer.Contour(
      lowBand: lowArr, broadband: broad, highBand: highArr, rate: rate)
  }

  /// A clean single-step contour: `pre` before `dropFrame`, `post` from it onward.
  private static func stepContour(
    frames: Int, dropFrame: Int, pre: Float = 0.2, post: Float = 1.0
  ) -> StructuralDropAnalyzer.Contour {
    contour(frames: frames, low: { $0 < dropFrame ? pre : post })
  }

  // MARK: - AC1: DownbeatStrategy is a closed 3-case set

  @Test func downbeatStrategyHasExactlyThreeCases() {
    #expect(DownbeatStrategy.allCases.count == 3)
    for strategy in DownbeatStrategy.allCases {
      // Exhaustive switch — a new case forces this test to be updated.
      switch strategy {
      case .metricalAccent, .structuralDrop, .combined: break
      }
    }
  }

  // MARK: - AC1: DownbeatStrategy persists as a documented bare string

  @Test func downbeatStrategyEncodesAsBareString() throws {
    // A consumer persisting the strategy in a config object must get the documented
    // bare-string form (`"structuralDrop"`), NOT the keyed-object shape a non-`String`
    // payload-free Codable enum synthesizes (`{"structuralDrop":{}}`).
    struct Wrapper: Codable, Equatable { let strategy: DownbeatStrategy }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    for (strategy, name) in [
      (DownbeatStrategy.metricalAccent, "metricalAccent"),
      (.structuralDrop, "structuralDrop"),
      (.combined, "combined"),
    ] {
      let expected = Data("{\"strategy\":\"\(name)\"}".utf8)
      #expect(try encoder.encode(Wrapper(strategy: strategy)) == expected)
      #expect(try JSONDecoder().decode(Wrapper.self, from: expected).strategy == strategy)
    }
  }

  // MARK: - AC8(a): interior drop on a known phase → confident at that phase

  @Test func detectsInteriorDropPhase() {
    // 8 bars @ 120 BPM; drop at beat 9 (t = 4.5 s → phase 1), interior (NOT at the
    // window start). frame = 4.5 * 20 = 90.
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.stepContour(frames: 320, dropFrame: 90),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    guard case .confident(let phase, let dropTime, _) = r else {
      Issue.record("expected .confident for a clean interior drop, got \(r)")
      return
    }
    #expect(phase == 1)
    #expect(abs(dropTime - 4.5) < 0.1)
  }

  // MARK: - AC8(b): flat-energy → abstain

  @Test func flatEnergyAbstains() {
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.contour(frames: 320, low: { _ in 0.2 }),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    #expect(r == .none)
  }

  // MARK: - AC8(c): off-grid drop → abstain; half-beat-ambiguous drop → abstain

  @Test func offGridDropAbstains() {
    // Drop at t = 19.0 s, beyond the last beat (t = 15.5) by > beatPeriod/2.
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.stepContour(frames: 440, dropFrame: 380),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    #expect(r == .none)
  }

  @Test func halfBeatAmbiguousDropAbstains() {
    // Drop at t = 4.25 s, ~midway between beat 8 (4.0) and beat 9 (4.5).
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.stepContour(frames: 320, dropFrame: 85),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    #expect(r == .none)
  }

  // MARK: - AC8(d): degenerate window-start (only step is the start) → abstain

  @Test func degenerateWindowStartAbstains() {
    // The contour is elevated from frame 0 with no interior step — the drop
    // coincided with the analysis start. No rising edge → abstain (no phase-0
    // tautology).
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.contour(frames: 320, low: { _ in 1.0 }),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    #expect(r == .none)
  }

  // MARK: - AC8(e): sub-beat resolution (bar not a clean multiple of the window)

  @Test func subBeatResolutionRecoversTheCorrectBeat() {
    // 128 BPM → bar ≈ 1.875 s; drop on beat 13 (t ≈ 6.094 s → phase 1). A 1 s
    // window would land ±0.5 s off (beat 12/14, phase 0/2); the 50 ms contour +
    // parabolic refine lands on beat 13.
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.stepContour(frames: 320, dropFrame: 122),
      beats: Self.beats(tempo: 128, bars: 8), estimatedTempo: 128)
    guard case .confident(let phase, _, _) = r else {
      Issue.record("expected .confident, got \(r)")
      return
    }
    #expect(phase == 1)
  }

  // MARK: - AC8(h): build-up / riser does NOT fire; the drop does

  @Test func riserDoesNotFireButTheDropDoes() {
    // A high-band-only riser (bass flat) over frames 60..<100, then a true low-band
    // drop at frame 150 (t = 7.5 s → beat 15, phase 3). The riser produces no
    // low-band novelty peak, so only the true drop is a candidate.
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.contour(
        frames: 320,
        low: { $0 < 150 ? 0.2 : 1.0 },
        high: { (60..<100).contains($0) ? 0.5 : 0.0 }),
      beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    guard case .confident(let phase, let dropTime, _) = r else {
      Issue.record("expected the true drop to fire, got \(r)")
      return
    }
    #expect(phase == 3)
    #expect(abs(dropTime - 7.5) < 0.2, "the riser at t≈3.5 s must not win")
  }

  @Test func riserWithDominantHighBandStepIsRejectedByTheDiscriminator() {
    // A candidate where the LOW band rises modestly (a dominant novelty peak that
    // CLEARS the low-band floor — lowPost == lowMax) but the HIGH band step
    // dominates: a build-up / sweep, not a bass drop. The multi-descriptor
    // discriminator (high-step > 2.5·low-step) must reject it — the lone low-band
    // floor would not. (DD #2 step 2; the #1 literature false-positive.)
    let beats = Self.beats(tempo: 120, bars: 8)
    let riser = Self.contour(
      frames: 320,
      low: { $0 < 150 ? 0.2 : 0.5 },  // modest low step 0.3, clears the 0.35·lowMax floor
      high: { $0 < 150 ? 0.2 : 2.0 })  // dominant high step 1.8 >> 2.5·0.3
    #expect(
      StructuralDropAnalyzer.resolve(contour: riser, beats: beats, estimatedTempo: 120) == .none)

    // Control: the SAME modest low rise WITHOUT the dominant high band fires — so
    // the rejection above is the high-band discriminator, not the low-band floor.
    let control = Self.contour(frames: 320, low: { $0 < 150 ? 0.2 : 0.5 })
    guard
      case .confident = StructuralDropAnalyzer.resolve(
        contour: control, beats: beats, estimatedTempo: 120)
    else {
      Issue.record(
        "control (no high-band dominance) should fire — the discriminator is what rejected the riser"
      )
      return
    }
  }

  // MARK: - Build-up → drop: a rejected riser must not mask the later real drop

  @Test func riserRankedAboveRealDropFallsThroughToTheDrop() {
    // peaks[0] is a high-band-dominated riser whose LOW-band novelty (0.4) is the LARGEST,
    // so it ranks first; it clears the contrast + low-post floors and fails ONLY the
    // high-dominance discriminator. A later genuine bass drop (low novelty 0.3, no high
    // dominance) at beat 20 (t = 10.0 s → phase 0) must be anchored, not abstained —
    // exercising the rank-ordered fall-through. Returns `.none` on the pre-fix
    // single-`peaks[0]` logic; the real drop never got a look.
    let c = Self.contour(
      frames: 320,
      low: { f in
        if f < 80 { return 0.2 }
        if f < 120 { return 0.6 }  // riser low rise — largest novelty (rank 0)
        if f < 200 { return 0.2 }  // breakdown
        return 0.5  // real bass drop — smaller novelty
      },
      high: { (80..<120).contains($0) ? 2.0 : 0.2 })
    let r = StructuralDropAnalyzer.resolve(
      contour: c, beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    guard case .confident(let phase, let dropTime, _) = r else {
      Issue.record("expected the real drop to anchor after the riser is skipped, got \(r)")
      return
    }
    #expect(phase == 0)
    #expect(abs(dropTime - 10.0) < 0.2, "the riser at t≈4 s must not win")
  }

  @Test func comparableRiserRunnerUpAtAnotherPhaseDoesNotForceAbstain() {
    // A VALID dominant drop (frame 80 → t=4.0 s → phase 0) plus a comparable RISER (low
    // novelty 0.35 ≥ 0.8·0.4) at an unrelated phase (frame 130 → t=6.5 s → phase 1). A
    // rejected riser is NOT a competing drop, so the runner-up scan must ignore it and the
    // dominant fires. Returns `.none` on the pre-fix phase-only runner-up check (the riser's
    // phase 1 was read as an unresolvable tie).
    let c = Self.contour(
      frames: 320,
      low: { f in
        if f < 80 { return 0.2 }
        if f < 120 { return 0.6 }  // real drop (rank 0), phase 0
        if f < 130 { return 0.2 }  // breakdown
        if f < 170 { return 0.55 }  // riser low — comparable novelty, phase 1
        return 0.2
      },
      high: { (130..<170).contains($0) ? 2.0 : 0.2 })
    let r = StructuralDropAnalyzer.resolve(
      contour: c, beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    guard case .confident(let phase, _, _) = r else {
      Issue.record("a rejected riser runner-up must not force an abstain, got \(r)")
      return
    }
    #expect(phase == 0)
  }

  // MARK: - AC8(i): half-bar (beat-1-vs-beat-3) → abstain; .combined resolves it

  @Test func halfBarAmbiguityAbstainsStandaloneAndResolvesCombined() {
    // Two comparable drops a half-bar apart: phase 0 (beat 8, frame 80, slightly
    // stronger) and phase 2 (beat 10, frame 100). The low band dips between them so
    // both rising edges are detectable.
    let beats = Self.beats(tempo: 120, bars: 8)
    let c = Self.contour(
      frames: 320,
      low: { f in
        if f < 80 { return 0.2 }
        if f < 90 { return 1.0 }  // first drop (phase 0)
        if f < 100 { return 0.2 }  // half-bar break
        return 0.95  // second drop (phase 2)
      })
    let r = StructuralDropAnalyzer.resolve(contour: c, beats: beats, estimatedTempo: 120)
    guard case .halfBarAmbiguous(let a, let b, _, _) = r else {
      Issue.record("expected .halfBarAmbiguous, got \(r)")
      return
    }
    #expect(a == 0)
    #expect(b == 2)

    // Standalone .structuralDrop abstains on the half-bar.
    if case .detected = StructuralDropAnalyzer.estimate(
      contour: c, beats: beats, estimatedTempo: 120)
    {
      Issue.record("standalone structuralDrop must abstain on a half-bar ambiguity")
    }

    // .combined: a metrical-accent fire at phase 0 breaks the 1-vs-3 tie.
    let metrical = Self.metricalDetected(phase: 0, beats: beats)
    guard
      case .detected(let est, _) = StructuralDropAnalyzer.combine(
        metrical: metrical, drop: r, beats: beats, estimatedTempo: 120)
    else {
      Issue.record("combined must resolve the half-bar via metrical accent")
      return
    }
    #expect(est.phaseIndex == 0)

    // But if metrical picks a phase that is NEITHER half-bar candidate → abstain.
    let metricalWrong = Self.metricalDetected(phase: 1, beats: beats)
    if case .detected = StructuralDropAnalyzer.combine(
      metrical: metricalWrong, drop: r, beats: beats, estimatedTempo: 120)
    {
      Issue.record("combined must abstain when metrical resolves to neither half-bar phase")
    }
  }

  // MARK: - AC8(j): multiple drops → runner-up-tie abstain; dominant when one wins

  @Test func multipleDropsTieAbstains() {
    // Drop at phase 0 (frame 80) and a comparable drop at phase 1 (beat 13, frame
    // 130) — unrelated phases → unresolvable double-drop tie.
    let c = Self.contour(
      frames: 320,
      low: { f in
        if f < 80 { return 0.2 }
        if f < 90 { return 1.0 }
        if f < 130 { return 0.2 }
        return 0.95
      })
    let r = StructuralDropAnalyzer.resolve(
      contour: c, beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    #expect(r == .none)
  }

  @Test func multipleDropsWithAClearWinnerDetects() {
    // A strong drop at phase 0 (frame 80) and a much weaker bump at frame 130
    // (below the comparable threshold) → the dominant drop wins.
    let c = Self.contour(
      frames: 320,
      low: { f in
        if f < 80 { return 0.2 }
        if f < 90 { return 1.0 }
        if f < 130 { return 0.2 }
        return 0.3  // weak: novelty 0.1 << 0.8·dominant
      })
    let r = StructuralDropAnalyzer.resolve(
      contour: c, beats: Self.beats(tempo: 120, bars: 8), estimatedTempo: 120)
    guard case .confident(let phase, _, _) = r else {
      Issue.record("expected the dominant drop to win, got \(r)")
      return
    }
    #expect(phase == 0)
  }

  // MARK: - AC8(g): octave-safety on a half-time-seeded grid

  @Test func placesPhaseOnAHalfTimeGridWithoutReOctaving() {
    // A half-time-seeded grid (80 BPM, bp = 0.75 s); drop on beat 8 (t = 6.0 s →
    // phase 0). The estimator places the phase on the given grid at its octave; it
    // never re-picks the tempo octave.
    let r = StructuralDropAnalyzer.resolve(
      contour: Self.stepContour(frames: 480, dropFrame: 120),
      beats: Self.beats(tempo: 80, bars: 8), estimatedTempo: 80)
    guard case .confident(let phase, _, _) = r else {
      Issue.record("expected .confident on the half-time grid, got \(r)")
      return
    }
    #expect(phase == 0)
  }

  // MARK: - AC8(f): .combined single-source + agree/conflict rules

  @Test func combinedAgreeConflictAndSingleSourceRules() {
    let beats = Self.beats(tempo: 120, bars: 8)

    // agree → detected.
    let agree = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 0, beats: beats),
      drop: .confident(phaseIndex: 0, dropTimeSeconds: 4.0, confidence: 0.6),
      beats: beats, estimatedTempo: 120)
    guard case .detected(let agreeEst, _) = agree else {
      Issue.record("agree must detect")
      return
    }
    #expect(agreeEst.phaseIndex == 0)

    // conflict → keep the conservative-proven metrical estimate (issue #61): a
    // possibly-wrong drop must NOT veto a standalone-valid 8.5a fire.
    let conflict = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 0, beats: beats),
      drop: .confident(phaseIndex: 1, dropTimeSeconds: 4.5, confidence: 0.6),
      beats: beats, estimatedTempo: 120)
    guard case .detected(let conflictEst, _) = conflict else {
      Issue.record("conflict must keep the metrical estimate, got \(conflict)")
      return
    }
    #expect(conflictEst.phaseIndex == 0)  // metrical phase preserved, drop did NOT veto it

    // lone metrical → admitted (the conservative-proven path).
    let loneMetrical = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 2, beats: beats),
      drop: .none, beats: beats, estimatedTempo: 120)
    guard case .detected(let loneEst, _) = loneMetrical else {
      Issue.record("lone metrical must be admitted")
      return
    }
    #expect(loneEst.phaseIndex == 2)

    // lone coarse structuralDrop (confidence below the strict bar) → abstain.
    let loneCoarseDrop = StructuralDropAnalyzer.combine(
      metrical: .noneDetected,
      drop: .confident(phaseIndex: 0, dropTimeSeconds: 4.0, confidence: 0.5),
      beats: beats, estimatedTempo: 120)
    if case .detected = loneCoarseDrop {
      Issue.record("a lone coarse structuralDrop must abstain at default")
    }

    // lone structuralDrop clearing the strict bar → admitted (locks the bar).
    let loneStrongDrop = StructuralDropAnalyzer.combine(
      metrical: .noneDetected,
      drop: .confident(phaseIndex: 0, dropTimeSeconds: 4.0, confidence: 0.97),
      beats: beats, estimatedTempo: 120)
    guard case .detected = loneStrongDrop else {
      Issue.record("a lone structuralDrop above the strict bar must be admitted")
      return
    }

    // neither fires → abstain.
    let neither = StructuralDropAnalyzer.combine(
      metrical: .noneDetected, drop: .none, beats: beats, estimatedTempo: 120)
    if case .detected = neither { Issue.record("neither firing must abstain") }
  }

  // MARK: - #61: .combined keeps the metrical estimate on a drop disagreement

  @Test func combinedKeepsMetricalEstimateOnDropDisagreement() {
    let beats = Self.beats(tempo: 120, bars: 8)
    let result = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 0, beats: beats),
      drop: .confident(phaseIndex: 1, dropTimeSeconds: 4.5, confidence: 0.9),
      beats: beats, estimatedTempo: 120)
    guard case .detected(let est, _) = result else {
      Issue.record("combined must keep the metrical estimate on a drop disagreement, got \(result)")
      return
    }
    #expect(est.phaseIndex == 0)  // metrical phase preserved, drop did NOT veto it
  }

  @Test func combinedKeepsLowConfidenceMetricalOverHighConfidenceDisagreeingDrop() {
    // The drop is a corroborator, not an authority: even a high-confidence drop
    // (0.99) disagreeing with a low-confidence metrical (0.1) must NOT veto it.
    let beats = Self.beats(tempo: 120, bars: 8)
    let result = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 0, beats: beats, confidence: 0.1),
      drop: .confident(phaseIndex: 1, dropTimeSeconds: 4.5, confidence: 0.99),
      beats: beats, estimatedTempo: 120)
    guard case .detected(let est, let confidence) = result else {
      Issue.record("a high-confidence disagreeing drop must NOT veto a low-confidence metrical")
      return
    }
    #expect(est.phaseIndex == 0)
    // Fall-back returns the metrical verbatim (no boost — the sources disagreed).
    #expect(confidence == 0.1)
  }

  @Test func combinedDisagreementInThreeFourKeepsMetrical() {
    // beatsPerBar != 4: the fall-back path must still return the metrical phase
    // (no `% 4` assumptions leak into the disagree branch). NOTE: combine(...) is
    // tested directly here with constructed inputs; the resolve()-side 4/4 guard
    // (issue #63) is exercised separately by nonFourFourMeterAbstains.
    let beats = Self.beats(tempo: 120, bars: 8, beatsPerBar: 3)
    let result = StructuralDropAnalyzer.combine(
      metrical: Self.metricalDetected(phase: 2, beats: beats),
      drop: .confident(phaseIndex: 0, dropTimeSeconds: 4.5, confidence: 0.9),
      beats: beats, estimatedTempo: 120, beatsPerBar: 3)
    guard case .detected(let est, _) = result else {
      Issue.record("3/4 disagreement must keep the metrical estimate, got \(result)")
      return
    }
    #expect(est.phaseIndex == 2)
  }

  // MARK: - #63: non-4/4 meters abstain at the resolve() entry

  @Test func nonFourFourMeterAbstains() {
    let contour = Self.stepContour(frames: 320, dropFrame: 90)
    // 3/4: enough beats for ≥ 3 bars (24 beats / 3 = 8 bars), odd meter (the
    // beatsPerBar/2 truncation case).
    let r3 = StructuralDropAnalyzer.resolve(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8, beatsPerBar: 3),
      estimatedTempo: 120, beatsPerBar: 3)
    #expect(r3 == .none)
    // 2/4: even but < 4 (the halfBarPartner == -1 disabled case).
    let r2 = StructuralDropAnalyzer.resolve(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8, beatsPerBar: 2),
      estimatedTempo: 120, beatsPerBar: 2)
    #expect(r2 == .none)
    // 5/4: a larger non-4 meter — proves the guard is `== 4`, not merely `< 4`.
    let r5 = StructuralDropAnalyzer.resolve(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8, beatsPerBar: 5),
      estimatedTempo: 120, beatsPerBar: 5)
    #expect(r5 == .none)
    // beatsPerBar == 0 still abstains (guard-ordering change is locked).
    let r0 = StructuralDropAnalyzer.resolve(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8),
      estimatedTempo: 120, beatsPerBar: 0)
    #expect(r0 == .none)
    // The standalone estimate(...) seam must also abstain (no .detected).
    if case .detected = StructuralDropAnalyzer.estimate(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8, beatsPerBar: 3),
      estimatedTempo: 120, beatsPerBar: 3)
    {
      Issue.record("non-4/4 meter must abstain through estimate(...)")
    }
    // 4/4 still fires (the happy path is unchanged by the guard).
    let r4 = StructuralDropAnalyzer.resolve(
      contour: contour,
      beats: Self.beats(tempo: 120, bars: 8),
      estimatedTempo: 120, beatsPerBar: 4)
    guard case .confident = r4 else {
      Issue.record("4/4 must still fire .confident on a clean interior drop, got \(r4)")
      return
    }
  }

  // MARK: - AC8(a) integration: estimateBeatGrid repoints the anchor to the drop

  @Test func estimateBeatGridStructuralDropRepointsAnchor() throws {
    // Clean impulses every 50 frames (DP recovers a beat per impulse @ 120 BPM);
    // dropContour plants the drop at t = 4.5 s (beat 9, phase 1).
    let bars = 8
    let period = 50
    let length = bars * 4 * period + period
    var onset = [Float](repeating: 0, count: length)
    for beatIndex in 0..<(bars * 4) { onset[beatIndex * period] = 1.0 }

    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: onset, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: onset, tempoBPM: 120.0, windowStartSample: 0,
        detectDownbeats: true,
        downbeatStrategy: .structuralDrop,
        dropContour: Self.stepContour(frames: 320, dropFrame: 90)))

    guard case .detected(let estimate) = grid.downbeats else {
      Issue.record("expected .detected from the planted dropContour")
      return
    }
    #expect(estimate.phaseIndex == 1)
    let anchor = try #require(grid.gridOrigin)
    #expect(anchor.source == .downbeat)

    // Firing containment (AC #2c / #5): on the SAME onset, `.metricalAccent` sees a
    // flat low band → abstains, so `.structuralDrop` FIRES and repoints gridOrigin
    // while the grid's `estimatedTempo` + `beats` stay bit-identical (the estimator
    // never re-picks the tempo — the Epic-12 boundary), exercised in the firing
    // case, not just the all-abstain case.
    let metricalGrid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: onset, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: onset, tempoBPM: 120.0, windowStartSample: 0,
        detectDownbeats: true,
        downbeatStrategy: .metricalAccent,
        dropContour: Self.stepContour(frames: 320, dropFrame: 90)))
    #expect(metricalGrid.downbeats == .noneDetected, "flat low band → metricalAccent abstains")
    #expect(metricalGrid.gridOrigin?.source != .downbeat)
    #expect(
      metricalGrid.estimatedTempo.bitPattern == grid.estimatedTempo.bitPattern,
      "firing strategy must not perturb estimatedTempo")
    try #require(metricalGrid.beats.count == grid.beats.count)
    for i in 0..<grid.beats.count {
      #expect(
        metricalGrid.beats[i].presentationTime.bitPattern
          == grid.beats[i].presentationTime.bitPattern,
        "firing strategy must not perturb the beat grid")
    }
  }

  @Test func structuralDropWithoutContourAbstains() throws {
    // No dropContour threaded → structuralDrop has nothing to detect → abstain
    // (NOT a crash), and the 8.5 phase-consistency anchor is preserved.
    let bars = 8
    let period = 50
    let length = bars * 4 * period + period
    var onset = [Float](repeating: 0, count: length)
    for beatIndex in 0..<(bars * 4) { onset[beatIndex * period] = 1.0 }
    let grid = try #require(
      BeatGridAnalyzer.estimateBeatGrid(
        onsetEnvelope: onset, onsetRate: 100.0, hopSize: 441, sampleRate: 44100.0,
        acf: onset, tempoBPM: 120.0, windowStartSample: 0,
        detectDownbeats: true, downbeatStrategy: .structuralDrop, dropContour: nil))
    #expect(grid.downbeats == .noneDetected)
    #expect(grid.gridOrigin?.source != .downbeat)
  }

  // MARK: - computeContour (Task 2): a loud low-frequency region lifts the contour

  @Test func computeContourLiftsOnLowFrequencyEnergy() throws {
    // 4 s @ 44100: a 60 Hz tone, quiet for the first 2 s, loud for the next 2 s.
    let sampleRate = 44100.0
    let total = Int(sampleRate * 4)
    let half = total / 2
    var samples = [Float](repeating: 0, count: total)
    for i in 0..<total {
      let amp: Float = i < half ? 0.05 : 0.6
      samples[i] = amp * Float(sin(2.0 * Double.pi * 60.0 * Double(i) / sampleRate))
    }
    let c = try #require(
      StructuralDropAnalyzer.computeContour(samples: samples, sampleRate: sampleRate))
    let frames = c.lowBand.count
    let early = c.lowBand[0..<(frames / 4)].reduce(0, +) / Float(frames / 4)
    let late = c.lowBand[(3 * frames / 4)..<frames].reduce(0, +) / Float(frames - 3 * frames / 4)
    #expect(late > 2 * early, "the loud low-frequency second half must lift the low-band contour")
  }

  // MARK: - Helpers

  /// A constructed metrical-accent `.detected` outcome at `phase` (no audio).
  private static func metricalDetected(
    phase: Int, beats: [BeatTimestamp], confidence: Float = 0.6
  ) -> DownbeatAnalyzer.Outcome {
    let est = DownbeatEstimate(
      beats: [beats[phase]], meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
      confidence: confidence, phaseIndex: phase)
    return .detected(estimate: est, firstDownbeatBeatIndex: phase)
  }
}
