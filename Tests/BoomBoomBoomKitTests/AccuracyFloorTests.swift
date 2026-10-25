//
//  AccuracyFloorTests.swift
//  BoomBoomBoomKitTests
//
//  GH-167 item 5 (#154, #161): the first REAL-MUSIC accuracy floor in CI.
//
//  Be precise about the novelty here. CI was NOT previously accuracy-blind:
//  `BPMAnalyzerTests.defaultIntensityRegression` already asserted a synthetic
//  120 BPM click track within +/-2 BPM at default intensity, which is
//  octave-strict and does run on every `make test`. What CI lacked was any
//  accuracy assertion over REAL MUSIC, over MULTIPLE fixtures, against ground
//  truth established outside this library.
//
//  What was genuinely unguarded: every corpus floor (OA300 Acc1 >= 57,
//  GiantSteps >= 537, beat-grid F, consistency rate) lives in the env-gated
//  benchmark target CI never builds, so an Acc1 collapse from 58/82 to 40/82
//  merged green. This suite runs in the unit target with no corpus required.
//
//  Two properties distinguish it from the pre-existing synthetic checks:
//
//  1. REAL MUSIC, OCTAVE-STRICT. The pre-existing assertions cover synthetic
//     click tracks generated at runtime — the easy case. These 12 fixtures
//     include five real tracks, and a 2x answer is a failure. (Separately,
//     `BeatGridAnalyzerTests.recoversClickTrackTempo` was octave-TOLERANT and
//     deferred octave correctness to the benchmarks CI never runs; item 5 made
//     it strict, so the beat-grid path now has octave coverage too.)
//
//  2. GROUND TRUTH IS INDEPENDENT. Every expected BPM comes from construction
//     (synthesized clicks), the author (`robbyt_x-ray-*`), or human verification
//     recorded in `Resources/AudioFixtures/FIXTURES.md`. No expected value is a
//     number this library produced. Pinning analyzer output would build a change
//     detector that enshrines current errors — the opposite of a floor.
//
//  MEASURED HEADROOM (2026-07-25, metadataPolicy = .disabled). Relative error of
//  every fixture, so the 2% bound can be judged against evidence rather than
//  asserted. Worst passing case is 0.31% (a ~6x margin under the bound); the
//  nearest failure is 33.54%, about 17x ABOVE it. No fixture sits near the
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
    // faster octave. For ONE of them the mechanism is known — Submerged_Lament
    // had the correct 70 in its own candidate list, losing on score (0.97 against
    // 140 at 1.01), so that case is a selection failure rather than a generation
    // failure. Candidate evidence was not captured for the other two; do not
    // assume they share the mechanism.
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
    // `HarmonicRatio.twoThird` already models. The 30 s cut of the same source
    // track (identical first-30s prefix) resolves correctly at 174.3 (conf 0.92).
    // That IMPLICATES content after 0:30; it does not prove causation, since the
    // two cuts also differ in window count and aggregation.
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
  @Test("floor case list has the expected cardinality (denominator guard)")
  func floorCaseListCardinality() {
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
    // hide a far worse regression than the one it records.
    //
    // The 60...200 range is scoped to THIS suite's configuration, not to the
    // pipeline. Story 12.1 made the fold window consumer-specifiable
    // (`Options.perceptualWindow`, `PerceptualTempoWindow`), so 60...200 is the
    // DEFAULT window, not an invariant — and this suite runs at the default, which is
    // why the assertion is still correct here. Every result passes through
    // `BPMAnalyzer.rangeNormalize`, which folds into that window. Note
    // `Options.tempoScanRange` (default 40...250) is the candidate-GENERATION bound,
    // NOT an output bound — do not use it here.
    //
    // Asserted WITHOUT the window-edge tolerance that `perceptualWindowFixtureImpact`
    // below needs: step 10c can report a window-edge winner fractionally outside the
    // window, but no fixture here sits on an edge of the default 60...200, so the
    // strict form holds and is kept strict deliberately.
    #expect(detected.isFinite, "#154: BPM must be finite, got \(detected)")
    #expect(
      detected >= PerceptualTempoWindow.defaultMinBPM
        && detected <= PerceptualTempoWindow.defaultMaxBPM,
      "#154: BPM must be inside the default rangeNormalize window 60...200, got \(detected)")
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

  // MARK: - Story 12.1 / FR-55: what a perceptual window recovers, and what it cannot

  /// The three known failures whose defect IS an octave error. Each currently reports
  /// the doubled tempo; each is expected to resolve once the erroneous octave is
  /// excluded from the fold window.
  ///
  /// `robbyt_x-ray-120s` is deliberately absent. Its ~115.6 is two-thirds of 174 — a
  /// 3:2 relation, not a 2:1 one — so no choice of octave window can recover it, and
  /// its entry above already records that correctly. The target set is three fixtures,
  /// not four; that is the measurement, not a concession.
  private static let octaveRecoverable: Set<String> = [
    "Meta_Man", "Meta_Man_La_Noche_Digital_", "Submerged_Lament",
  ]

  /// A half-time window: exactly one octave, spanning the tempi the three octave
  /// failures actually sit at. It EXCLUDES their erroneous 182 / 192 / 140, so the
  /// fold brings each back to its true tempo. Chosen for that property alone — it is
  /// a measurement instrument here, not a recommended default.
  private static let halfTimeWindow = PerceptualTempoWindow(minBPM: 60, maxBPM: 120)

  /// FR-55: a per-fixture measurement of the consumer-specifiable perceptual window
  /// (Story 12.1), run over the same 12 ground-truth fixtures as the floor above.
  ///
  /// This is what makes the story's central claim checkable rather than asserted: an
  /// input constraint recovers the octave failures and does nothing for the triplet
  /// failure. It does NOT relax the floor — the default-path expectations above are
  /// untouched, and every fixture's `knownFailure` label stays as it was.
  @Test(
    "perceptual window recovers the octave failures and not the triplet one",
    arguments: cases)
  fileprivate func perceptualWindowFixtureImpact(testCase: FloorCase) throws {
    let url = try AudioFixtures.url(for: testCase.name, extension: testCase.ext)
    var options = AudioAnalysisService.Options()
    options.metadataPolicy = .disabled
    options.perceptualWindow = Self.halfTimeWindow
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: options),
      "#FR-55: analyzeBPM returned nil under the half-time window")

    // Unconditional: the reported tempo must land inside the SUPPLIED window, for
    // every fixture — including the ones this window is expected to make worse.
    //
    // The edge tolerance is not slack, it is a measured property of the pipeline.
    // `PerceptualWindowEdge` (TempoSearchRangeTests.swift) is the single place it is
    // stated and derived; do not restate the number here.
    let edgeTolerance = PerceptualWindowEdge.toleranceBPM
    #expect(result.bpm >= Self.halfTimeWindow.minBPM - edgeTolerance)
    #expect(result.bpm <= Self.halfTimeWindow.maxBPM + edgeTolerance)

    let relativeError = abs(result.bpm - testCase.trueBPM) / testCase.trueBPM
    let diagnostic = Comment(
      rawValue: """
        FR-55 perceptual-window impact — \(testCase)
          window       : \(Self.halfTimeWindow.minBPM)...\(Self.halfTimeWindow.maxBPM)
          ground truth : \(testCase.trueBPM)
          detected     : \(result.bpm) (confidence \(result.confidence))
          relative err : \(String(format: "%.2f", relativeError * 100))%
        """)

    if Self.octaveRecoverable.contains(testCase.name) {
      // AC #7: these three MUST resolve. Measured 2026-08-01 at 0.40% / 0.21% / 0.10%.
      #expect(relativeError <= Self.tolerance, diagnostic)
    } else if testCase.name == "robbyt_x-ray-120s" {
      // AC #7: this one must NOT be expected to resolve. Asserting that it still
      // fails is what stops a future reader from quietly folding it into the
      // recoverable set — a 3:2 error is not an octave error.
      #expect(relativeError > Self.tolerance, diagnostic)
    }
    // Every other fixture is out of scope for this measurement: a 128 or 170 BPM
    // track cannot survive a 60...120 window and is not expected to. Its default-path
    // accuracy is asserted by `bpmAccuracyFloor` above.
  }

  /// Denominator guard for the split above, mirroring `floorCaseListCardinality`. If a
  /// fixture were renamed, `octaveRecoverable` would silently match nothing and the
  /// FR-55 measurement would assert nothing while still reporting green.
  @Test("FR-55 recoverable set names real fixtures")
  func octaveRecoverableSetIsGrounded() {
    let names = Set(Self.cases.map(\.name))
    #expect(Self.octaveRecoverable.count == 3)
    #expect(Self.octaveRecoverable.isSubset(of: names))
    #expect(names.contains("robbyt_x-ray-120s"))
    // Every member must be a fixture the default path currently fails, or the
    // measurement would be recording a recovery that was never needed.
    for name in Self.octaveRecoverable {
      #expect(Self.cases.first { $0.name == name }?.knownFailure != nil)
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
