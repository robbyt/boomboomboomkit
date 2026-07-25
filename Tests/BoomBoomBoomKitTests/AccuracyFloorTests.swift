//
//  AccuracyFloorTests.swift
//  BoomBoomBoomKitTests
//
//  GH-167 item 5 (#154, #161): the first accuracy floor that runs in CI.
//
//  Before this file, every accuracy floor in the repo (OA300 Acc1 >= 57,
//  GiantSteps >= 537, beat-grid F, consistency rate) lived in the env-gated
//  benchmark target, which CI never builds — CI runs `swift build`, `make test`,
//  a format check, and SwiftLint. A change dropping Acc1 from 58/82 to 40/82
//  merged green. This suite runs in the unit target on every `make test`, over
//  bundled fixtures, with no corpus required.
//
//  Two properties distinguish it from what already existed:
//
//  1. OCTAVE-STRICT. `BeatGridAnalyzerTests.recoversClickTrackTempo` checks the
//     click tracks octave-TOLERANTLY (0.5x/1x/2x within +/-5) and its own comment
//     delegates octave correctness to "the OA300/GiantSteps benchmarks" — the
//     benchmarks CI never runs. Octave correctness therefore had no automated
//     coverage anywhere. Here a 2x answer is a failure.
//
//  2. GROUND TRUTH IS INDEPENDENT. Every expected BPM comes from construction
//     (synthesized clicks), the author (`robbyt_x-ray-*`), or human verification
//     recorded in `Resources/AudioFixtures/FIXTURES.md`. No expected value is a
//     number this library produced. Pinning analyzer output would build a change
//     detector that enshrines current errors — the opposite of a floor.
//
//  MEASURED HEADROOM (2026-07-25, metadataPolicy = .disabled). Relative error of
//  every fixture, so the 2% bound can be judged against evidence rather than
//  asserted. Worst passing case is 0.31%, roughly 6x margin; the nearest failure
//  is 33.54%, two orders of magnitude away. There is no fixture sitting near the
//  boundary, which is what makes 2% a credible bound rather than a lucky one.
//
//      bpm-120-click        0.00%      robbyt_x-ray-30s      0.16%
//      bpm-120-downbeat     0.00%      Quantum_Cascade       0.19%
//      bpm-140-click        0.00%      bpm-170-click         0.31%
//      Meta_Man_Είσαι…      0.04%      ---- known failures below ----
//      bpm-85-click         0.15%      robbyt_x-ray-120s    33.54%
//                                      Meta_Man             97.83%
//                                      Meta_Man_La_Noche…   99.75%
//                                      Submerged_Lament    100.18%
//
//  KNOWN FAILURES ARE A RATCHET, NOT AN EXCUSE. Four fixtures fail today and are
//  wrapped in `withKnownIssue`. That keeps `make test` green while making the debt
//  visible in code. Crucially, `withKnownIssue` FAILS IF THE ISSUE STOPS
//  OCCURRING, so when the octave work in the #167 plan (row 10 / #141) lands, this
//  suite fails and tells you to delete the wrapper. Do not add a fixture here with
//  `knownFailure` set to silence a regression: an entry is only legitimate when it
//  records a defect that predates this suite.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

/// One fixture with an independently-established tempo.
private struct FloorCase: Sendable, CustomStringConvertible {
  let name: String
  let ext: String
  /// Ground truth. Never a value this library produced — see FIXTURES.md.
  let trueBPM: Double
  /// Non-nil records a defect present when this suite was written. The assertion
  /// still runs; it is wrapped so the suite stays green until the defect is fixed,
  /// and fails loudly once it is.
  let knownFailure: String?

  var description: String { "\(name).\(ext)" }
}

@Suite("Accuracy Floor — bundled fixtures (GH-167 item 5)")
struct AccuracyFloorTests {

  /// MIREX-style relative tolerance, matching the project's Acc1 convention. No
  /// harmonic error can slip through at 2%, and the margin is range-independent:
  /// 2x = 100% error, 1/2x = 50%, 2/3x = 33 1/3%, 3/2x = 50%. Measured headroom on
  /// the passing set is 0.31% worst case (see the suite header), so the bound is
  /// ~6x wider than the largest legitimate deviation observed.
  private static let tolerance = 0.02

  private static let cases: [FloorCase] = [
    // Synthetic click tracks — tempo exact by construction. The easy case; these
    // are the control group proving the floor itself works.
    FloorCase(name: "bpm-85-click", ext: "wav", trueBPM: 85, knownFailure: nil),
    FloorCase(name: "bpm-120-click", ext: "wav", trueBPM: 120, knownFailure: nil),
    FloorCase(name: "bpm-140-click", ext: "wav", trueBPM: 140, knownFailure: nil),
    FloorCase(name: "bpm-170-click", ext: "wav", trueBPM: 170, knownFailure: nil),
    FloorCase(name: "bpm-120-downbeat", ext: "wav", trueBPM: 120, knownFailure: nil),

    // Real music. Tempos human-verified 2026-07-24 (FIXTURES.md).
    FloorCase(name: "Meta_Man_Είσαι_η_Λύση_", ext: "mp3", trueBPM: 128, knownFailure: nil),
    FloorCase(name: "Quantum_Cascade", ext: "mp3", trueBPM: 170.3, knownFailure: nil),
    FloorCase(name: "robbyt_x-ray-30s", ext: "mp3", trueBPM: 174, knownFailure: nil),

    // --- Known failures (GH-167 item 5 baseline, 2026-07-24) ---
    //
    // Three clean octave doublings, all on SLOW tracks: the pipeline prefers the
    // faster octave. In at least one case the correct answer was already in the
    // candidate list and lost on score (Submerged_Lament: 70 scored 0.97 against
    // 140 at 1.01), making these selection failures, not generation failures.
    FloorCase(
      name: "Meta_Man", ext: "mp3", trueBPM: 92,
      knownFailure: "octave-doubled: reports ~182 for a 92 BPM track (2x)"),
    FloorCase(
      name: "Meta_Man_La_Noche_Digital_", ext: "mp3", trueBPM: 96,
      knownFailure: "octave-doubled: reports ~192 for a 96 BPM track (2x)"),
    FloorCase(
      name: "Submerged_Lament", ext: "mp3", trueBPM: 70,
      knownFailure: "octave-doubled: reports ~140 for a 70 BPM track (2x)"),
    // Not an octave error: ~115.6 is two-thirds of 174, the 3:2 harmonic relation
    // `HarmonicRatio.twoThird` already models. The 30 s cut of this same track
    // resolves correctly at 174.3 (conf 0.92), so the failure is introduced by
    // musical content between 0:30 and 2:00, not by the track's tempo.
    FloorCase(
      name: "robbyt_x-ray-120s", ext: "mp3", trueBPM: 174,
      knownFailure: "triplet-related: reports ~115.6, two-thirds of 174 (3:2)"),
  ]

  /// The floor's own denominator guard (GH-167 item 4's lesson applied to item 5).
  /// A parameterized `@Test` over an EMPTY argument array runs zero invocations and
  /// reports green, and silently dropping a case from `cases` is invisible for the
  /// same reason — which is precisely the measure-nothing defect class item 4
  /// existed to close. This pins the count so a deletion or an emptied list fails
  /// loudly. Every entry must also appear in the ground-truth table in
  /// `Resources/AudioFixtures/FIXTURES.md`; the manifest and this list are kept in
  /// sync by hand, and a Codex review of the first draft caught
  /// `bpm-120-downbeat` present in the manifest but missing here.
  @Test("floor covers every ground-truth fixture (denominator guard)")
  func floorCoversEveryGroundTruthFixture() {
    #expect(
      Self.cases.count == 12,
      "#154: expected 12 ground-truth fixtures in the floor; got \(Self.cases.count). If you added or removed one, update FIXTURES.md's ground-truth table to match."
    )
    #expect(
      Set(Self.cases.map(\.description)).count == Self.cases.count,
      "#154: duplicate fixture entries in the floor case list")
  }

  @Test("BPM within 2% of independently-established truth", arguments: cases)
  fileprivate func bpmAccuracyFloor(testCase: FloorCase) throws {
    let url = try AudioFixtures.url(for: testCase.name, extension: testCase.ext)
    // `.disabled` metadata: this is a DSP floor. The default path enables file-tag
    // corroboration (MP3 `TBPM`), so a tagged fixture could pass on its metadata
    // rather than on its DSP result. Disabling it keeps tags OUT OF THE MEASUREMENT
    // — note this does not assert that fixtures carry no tag, it only stops any tag
    // from participating, which is the property the floor needs. (No bundled
    // fixture carries a BPM tag today, verified 2026-07-24; results are identical
    // with the policy enabled or disabled.) `.disabled` is a documented
    // semantic-equivalence contract, not a byte-identity one.
    var options = AudioAnalysisService.Options()
    options.metadataPolicy = .disabled
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: options),
      "#154: analyzeBPM returned nil for a fixture with known ground truth")

    let detected = result.bpm
    let truth = testCase.trueBPM

    // The ground-truth value itself must be sane, checked OUTSIDE the wrapper. A
    // future `0` or `NaN` truth on a known-failing case would make the accuracy
    // expectation fail for the wrong reason and be absorbed as "known"; it would
    // also make `relativeError` non-finite and `harmonicRelation` meaningless.
    #expect(
      truth.isFinite && truth > 0,
      "#154: ground truth must be finite and positive, got \(truth) for \(testCase)")

    // UNCONDITIONAL invariants — deliberately OUTSIDE every `withKnownIssue`
    // wrapper. A known accuracy failure must never be able to conceal a NaN, an
    // infinity, or a wildly out-of-range tempo: each of those would also fail the
    // accuracy expectation below and be absorbed as "known", so the ratchet would
    // hide a far worse regression than the one it records. Range is 60...200
    // because every result passes through `BPMAnalyzer.rangeNormalize`, which
    // folds into `perceptualMinBPM`/`perceptualMaxBPM` (BPMAnalyzer.swift:2107).
    // Note `minBPM`/`maxBPM` (40/250) are candidate-generation bounds, NOT output
    // bounds — do not use them here.
    #expect(detected.isFinite, "#154: BPM must be finite, got \(detected)")
    #expect(
      detected >= 60.0 && detected <= 200.0,
      "#154: BPM must be inside the rangeNormalize output range 60...200, got \(detected)")
    #expect(result.confidence.isFinite, "#154: confidence must be finite")
    #expect(
      result.confidence >= 0.0 && result.confidence <= 1.0,
      "#154: confidence must be in [0, 1], got \(result.confidence)")

    let relativeError = abs(detected - truth) / truth
    let within = relativeError <= Self.tolerance

    // ONE expectation per outcome, with the diagnostic riding on the expectation's
    // own comment. A separate `Issue.record` was wrong twice over: it doubled the
    // known-issue count (4 failures produced 8), and it put a second issue inside
    // the `withKnownIssue` closure, whose default matcher accepts ANY issue — so a
    // future unrelated failure there would be silently classified as this known
    // accuracy defect. `Testing.Comment` is string-literal-only, hence
    // `Comment(rawValue:)` for the interpolated form.
    let diagnostic = Comment(
      rawValue: """
        #154 accuracy floor — \(testCase)
          ground truth : \(truth)
          detected     : \(detected) (confidence \(result.confidence))
          relative err : \(String(format: "%.2f", relativeError * 100))%
          relation     : \(Self.harmonicRelation(detected: detected, truth: truth))
        """)

    if let reason = testCase.knownFailure {
      // Fails if this STOPS failing — that is the point. When it does, delete the
      // knownFailure on this case; the fix has landed.
      withKnownIssue(Comment(rawValue: "GH-167 item 5 baseline: \(reason)")) {
        #expect(within, diagnostic)
      }
    } else {
      #expect(within, diagnostic)
    }
  }

  /// Describes `detected` as a harmonic multiple of `truth` when one fits, so
  /// failures self-classify as octave / triplet / unrelated.
  private static func harmonicRelation(detected: Double, truth: Double) -> String {
    let ratios: [(Double, String)] = [
      (2.0, "2x — octave doubling"), (0.5, "1/2x — octave halving"),
      (4.0, "4x — double octave"), (0.25, "1/4x — double octave down"),
      (1.5, "3/2x — triplet"), (2.0 / 3.0, "2/3x — triplet"),
      (3.0, "3x"), (1.0 / 3.0, "1/3x"),
    ]
    for (factor, label) in ratios
    where abs(detected - truth * factor) / (truth * factor) <= tolerance {
      return label
    }
    return "no simple harmonic relation"
  }
}
