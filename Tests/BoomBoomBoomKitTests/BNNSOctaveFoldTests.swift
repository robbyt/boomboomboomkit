//
//  BNNSOctaveFoldTests.swift
//  BoomBoomBoomKitTests
//
//  GH-141: decode-time octave fold. Every test here drives
//  `BNNSTechnique.decodeLogitsWithDiagnostic` directly with synthetic
//  logits, so the suite needs no model and no corpus and runs in the
//  ordinary `make test` lane.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

/// Build a 256-bin logit vector whose post-softmax mass sits where we want
/// it.
///
/// Softmax is `exp(x_i) / sum`, so the mass ratio between two bins is
/// `exp(x_b - x_a)`. Setting the argmax logit to 0 and a companion logit to
/// `ln(ratio)` therefore produces exactly that ratio after normalization.
/// The floor of -60 makes the other 254 bins contribute ~1e-26 each, which
/// is far below the precision any assertion here depends on.
@available(macOS 15.0, *)
private func logits(argmaxBin: Int, companions: [(bin: Int, ratio: Double)] = [])
  -> [Float]
{
  var v = [Float](repeating: -60.0, count: 256)
  v[argmaxBin] = 0.0
  for c in companions {
    v[c.bin] = Float(Foundation.log(c.ratio))
  }
  return v
}

@Suite("GH-141 octave-folded decode")
struct BNNSOctaveFoldTests {

  // MARK: - The behaviour the issue is about

  /// The E0 signature: a 70 BPM track decoded as 140, with real posterior
  /// mass still sitting on the fundamental. Bin 110 is 140 BPM, bin 40 is
  /// 70 BPM.
  @Test("clean doubling folds to the fundamental")
  @available(macOS 15.0, *)
  func cleanDoublingFolds() throws {
    let v = logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.5)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.4))

    guard case .success(let bpm, _, _, let fold) = outcome else {
      Issue.record("expected .success, got \(outcome)")
      return
    }
    #expect(bpm == 70.0, "140 BPM argmax with strong 70 BPM mass must decode 70")
    let f = try #require(fold, "a fold must be recorded when it happens")
    #expect(f.fromBPM == 140.0, "the record must name the pre-fold tempo")
    #expect(
      abs(f.massRatio - 0.5) < 1e-4,
      "the recorded ratio must be the one that cleared the threshold, got \(f.massRatio)")
  }

  /// The 120-175 BPM bands hold 550 of the 661 GiantSteps tracks and the
  /// model is largely right there. A confident argmax with negligible mass
  /// at the half tempo must not be touched — this is the regression the
  /// mass-ratio rule exists to avoid.
  @Test("a confident correct prediction is left alone")
  @available(macOS 15.0, *)
  func confidentPredictionDoesNotFold() {
    let v = logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.01)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.4))

    guard case .success(let bpm, _, _, let fold) = outcome else {
      Issue.record("expected .success, got \(outcome)")
      return
    }
    #expect(bpm == 140.0, "1% half-tempo mass must not move a 140 BPM decode")
    #expect(fold == nil, "no fold means no fold record")
  }

  // MARK: - Range floor

  /// Folding 60 BPM would produce 30, outside the library's accepted
  /// `60...200`. The fold must decline rather than emit an out-of-range
  /// tempo through a path whose range check has already run.
  @Test("no fold when the fundamental would fall below 60 BPM")
  @available(macOS 15.0, *)
  func belowRangeFundamentalDoesNotFold() {
    // Bin 30 is 60 BPM; its half (30 BPM) is bin 0.
    let v = logits(argmaxBin: 30, companions: [(bin: 0, ratio: 0.9)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.0))

    guard case .success(let bpm, _, _, let fold) = outcome else {
      Issue.record("expected .success, got \(outcome)")
      return
    }
    #expect(bpm == 60.0, "60 BPM must survive intact even at threshold 0.0")
    #expect(fold == nil, "a sub-60 fundamental is not a legal fold")
  }

  // MARK: - Bin parity

  /// Bins are `bpm = 30 + index`, so the half of an odd-offset bin lands
  /// between two bins. The rule sums both straddling bins; rounding to one
  /// would discard half the evidence and make sensitivity alternate bin to
  /// bin.
  ///
  /// Bin 111 is 141 BPM, whose half (70.5) sits between bin 40 (70) and
  /// bin 41 (71). Each companion alone is below the threshold; together
  /// they clear it.
  @Test("odd bins sum both straddling half-tempo bins")
  @available(macOS 15.0, *)
  func oddBinSumsStraddlingBins() throws {
    let v = logits(
      argmaxBin: 111,
      companions: [(bin: 40, ratio: 0.3), (bin: 41, ratio: 0.3)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.5))

    guard case .success(let bpm, _, _, let fold) = outcome else {
      Issue.record("expected .success, got \(outcome)")
      return
    }
    #expect(bpm == 70.5, "141 BPM folds to 70.5")
    let f = try #require(fold, "0.3 + 0.3 clears a 0.5 threshold; a single bin would not")
    #expect(
      abs(f.massRatio - 0.6) < 1e-4,
      "the ratio must be the SUM of both straddling bins, got \(f.massRatio)")
  }

  /// The other half of the parity contract: one straddling bin alone
  /// carrying 0.3 must NOT clear a 0.5 threshold. Without this, the
  /// summing test above would still pass if the implementation doubled a
  /// single bin's mass.
  @Test("a single straddling bin below threshold does not fold")
  @available(macOS 15.0, *)
  func singleStraddlingBinBelowThresholdDoesNotFold() {
    let v = logits(argmaxBin: 111, companions: [(bin: 40, ratio: 0.3)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.5))

    guard case .success(let bpm, _, _, let fold) = outcome else {
      Issue.record("expected .success, got \(outcome)")
      return
    }
    #expect(bpm == 141.0, "0.3 alone must not clear a 0.5 threshold")
    #expect(fold == nil)
  }

  // MARK: - Threshold semantics

  /// The comparison is `>=`, so a ratio exactly equal to the threshold
  /// folds. Pinned by reading the ratio the decoder actually computed and
  /// re-running at exactly that threshold. Asserting against a nominal 0.5
  /// would not constrain `>` versus `>=`: float conversion and Accelerate's
  /// exp/divide can land the real ratio fractionally either side, so a `>`
  /// implementation could pass by luck.
  @Test("a ratio exactly at the computed threshold folds (comparison is >=)")
  @available(macOS 15.0, *)
  func ratioAtThresholdFolds() throws {
    let v = logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.5)])

    // Pass 1: learn the exact ratio this decoder computes.
    guard
      case .success(_, _, _, let probe) = BNNSTechnique.decodeLogitsWithDiagnostic(
        v, policy: .massRatio(threshold: 0.0))
    else {
      Issue.record("probe pass must fold at threshold 0.0")
      return
    }
    let exact = try #require(probe).massRatio

    // Pass 2: threshold set to exactly that value must still fold.
    guard
      case .success(let bpm, _, _, let fold) = BNNSTechnique.decodeLogitsWithDiagnostic(
        v, policy: .massRatio(threshold: exact))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(bpm == 70.0, "ratio == threshold must fold; a `>` comparison would not")
    #expect(fold != nil)

    // And the next representable value above it must NOT fold, which pins
    // the boundary from the other side.
    guard
      case .success(let above, _, _, let noFold) = BNNSTechnique.decodeLogitsWithDiagnostic(
        v, policy: .massRatio(threshold: exact.nextUp))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(above == 140.0, "a threshold one ulp above the ratio must not fold")
    #expect(noFold == nil)
  }

  // MARK: - Range algebra boundaries

  /// The first legal fold. Below this the fundamental leaves the range, so
  /// this is the exact edge the 60 BPM floor sits on.
  @Test("120 BPM is the lowest source tempo that can fold")
  @available(macOS 15.0, *)
  func lowestFoldableSource() {
    // Bin 90 is 120 BPM; half is 60, exactly the floor.
    guard
      case .success(let bpm, _, _, let fold) = BNNSTechnique.decodeLogitsWithDiagnostic(
        logits(argmaxBin: 90, companions: [(bin: 30, ratio: 0.9)]),
        policy: .massRatio(threshold: 0.5))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(bpm == 60.0, "120 folds to exactly 60, which is in range")
    #expect(fold != nil)

    // One bin lower must NOT fold: 119 halves to 59.5.
    guard
      case .success(let unfolded, _, _, let none) = BNNSTechnique.decodeLogitsWithDiagnostic(
        logits(argmaxBin: 89, companions: [(bin: 29, ratio: 0.9), (bin: 30, ratio: 0.9)]),
        policy: .massRatio(threshold: 0.5))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(unfolded == 119.0, "119 halves to 59.5, below the floor")
    #expect(none == nil)
  }

  /// The highest in-range source tempo, pinning the top of the algebra.
  @Test("200 BPM folds to 100")
  @available(macOS 15.0, *)
  func highestInRangeSource() {
    guard
      case .success(let bpm, _, _, let fold) = BNNSTechnique.decodeLogitsWithDiagnostic(
        logits(argmaxBin: 170, companions: [(bin: 70, ratio: 0.9)]),
        policy: .massRatio(threshold: 0.5))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(bpm == 100.0)
    #expect(fold != nil)
  }

  // MARK: - Default inertness

  /// The shipped default must reproduce the pre-GH-141 decode exactly.
  /// `bitPattern` equality rather than `==` so a NaN or a signed zero
  /// could not slip through.
  /// The shipped default must reproduce the pre-GH-141 decode exactly.
  ///
  /// Compares `bitPattern` on all three numeric outputs across the three
  /// entry points that existed before this change — the explicit
  /// `.disabled` policy, the defaulted overload, and the legacy
  /// `decodeLogits` wrapper — and does it on inputs shaped to fold, so the
  /// test fails loudly if folding ever runs by default. Asserting only that
  /// the BPM matched a literal (and that the other two were merely finite)
  /// would not have constrained confidence or second-max at all.
  @Test("the default policy is bit-identical to bare argmax on every entry point")
  @available(macOS 15.0, *)
  func disabledPolicyIsInert() throws {
    // Each case is shaped so an active fold WOULD change the answer.
    let cases: [(name: String, v: [Float], expectedBPM: Double)] = [
      ("foldable", logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.9)]), 140.0),
      ("odd foldable", logits(argmaxBin: 111, companions: [(bin: 40, ratio: 0.9)]), 141.0),
      ("boundary", logits(argmaxBin: 90, companions: [(bin: 30, ratio: 0.9)]), 120.0),
    ]

    for c in cases {
      guard
        case .success(let b1, let c1, let s1, let f1) =
          BNNSTechnique.decodeLogitsWithDiagnostic(c.v, policy: .disabled)
      else {
        Issue.record("\(c.name): expected .success from .disabled")
        return
      }
      guard
        case .success(let b2, let c2, let s2, let f2) =
          BNNSTechnique.decodeLogitsWithDiagnostic(c.v)
      else {
        Issue.record("\(c.name): expected .success from the defaulted overload")
        return
      }
      #expect(b1.bitPattern == c.expectedBPM.bitPattern, "\(c.name): bare argmax")
      #expect(f1 == nil, "\(c.name): .disabled must not fold")
      #expect(f2 == nil, "\(c.name): omitting the policy must not fold")
      // Explicit-disabled and defaulted must agree BIT FOR BIT, not merely
      // be finite.
      #expect(b1.bitPattern == b2.bitPattern, "\(c.name): bpm")
      #expect(c1.bitPattern == c2.bitPattern, "\(c.name): confidence")
      #expect(s1.bitPattern == s2.bitPattern, "\(c.name): secondMax")

      // The legacy tuple wrapper is the third pre-GH-141 entry point.
      let legacy = try #require(
        BNNSTechnique.decodeLogits(c.v), "\(c.name): legacy wrapper must decode")
      #expect(legacy.bpm.bitPattern == b1.bitPattern, "\(c.name): legacy bpm")
      #expect(legacy.confidence.bitPattern == c1.bitPattern, "\(c.name): legacy confidence")
      #expect(legacy.secondMax.bitPattern == s1.bitPattern, "\(c.name): legacy secondMax")
    }

    // Failure outcomes are unchanged under .disabled too.
    var nonFinite = logits(argmaxBin: 110)
    nonFinite[3] = .infinity
    guard
      case .nonFiniteLogits = BNNSTechnique.decodeLogitsWithDiagnostic(
        nonFinite, policy: .disabled)
    else {
      Issue.record(".disabled must preserve the non-finite abstain")
      return
    }
    guard
      case .outOfRangeArgmax(let oob, _, _) = BNNSTechnique.decodeLogitsWithDiagnostic(
        logits(argmaxBin: 240, companions: [(bin: 105, ratio: 0.9)]), policy: .disabled)
    else {
      Issue.record(".disabled must preserve the out-of-range outcome")
      return
    }
    #expect(oob.bitPattern == (270.0 as Double).bitPattern)
  }

  /// Folding never runs on the abstain paths, so the existing hardening
  /// behaviour is unchanged no matter how aggressive the policy is.
  @Test("non-finite logits still abstain under an aggressive policy")
  @available(macOS 15.0, *)
  func nonFiniteLogitsStillAbstain() {
    var v = logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.9)])
    v[7] = .nan
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.0))
    guard case .nonFiniteLogits = outcome else {
      Issue.record("expected .nonFiniteLogits, got \(outcome)")
      return
    }
  }

  /// An out-of-range argmax keeps reporting the raw value. Folding is
  /// deliberately confined to the in-range path so `.outOfRangeArgmax`
  /// keeps meaning what the existing forensic harnesses read it to mean.
  @Test("an out-of-range argmax is not rescued by folding")
  @available(macOS 15.0, *)
  func outOfRangeArgmaxIsNotFolded() {
    // Bin 240 is 270 BPM (above the ceiling); its half, 135, is in range.
    let v = logits(argmaxBin: 240, companions: [(bin: 105, ratio: 0.9)])
    let outcome = BNNSTechnique.decodeLogitsWithDiagnostic(
      v, policy: .massRatio(threshold: 0.0))
    guard case .outOfRangeArgmax(let bpm, _, _) = outcome else {
      Issue.record("expected .outOfRangeArgmax, got \(outcome)")
      return
    }
    #expect(bpm == 270.0, "the raw out-of-range value is still what gets reported")
  }

  // MARK: - Fold-record construction

  /// `OctaveFold` is `Hashable`, and `Decode`/`Outcome`/`MLDiagnosticSnapshot`
  /// are `Hashable` through it. A non-finite field would break that
  /// invariant, and the type is public so a foreign `MLDiagnosticTechnique`
  /// can construct one. The initializer refuses rather than relying on the
  /// bundled decoder's good behaviour.
  @Test("OctaveFold refuses non-finite fields")
  @available(macOS 15.0, *)
  func octaveFoldRejectsNonFinite() {
    #expect(MLDiagnosticSnapshot.OctaveFold(fromBPM: 140.0, massRatio: 0.5) != nil)
    for bad in [Double.nan, .infinity, -.infinity] {
      #expect(
        MLDiagnosticSnapshot.OctaveFold(fromBPM: bad, massRatio: 0.5) == nil,
        "non-finite fromBPM (\(bad)) must not construct")
      #expect(
        MLDiagnosticSnapshot.OctaveFold(fromBPM: 140.0, massRatio: bad) == nil,
        "non-finite massRatio (\(bad)) must not construct")
    }
  }

  /// A folded tempo without its record would be a silent rewrite.
  ///
  /// Honest scope: this cannot currently fail, because the record's inputs
  /// are always finite and the initializer never refuses. It is a
  /// regression net for the coupling, not a proof of it — the value is in
  /// catching a future change that decouples the tempo rewrite from its
  /// provenance, and it sweeps both sides of the fold boundary so such a
  /// change would be caught wherever it landed.
  @Test("a folded BPM always carries its fold record")
  @available(macOS 15.0, *)
  func foldedBPMAlwaysCarriesItsRecord() {
    // Sweep thresholds across the fold/no-fold boundary and assert the
    // invariant holds on both sides at every step.
    for step in 0...20 {
      let threshold = Double(step) / 20.0
      let v = logits(argmaxBin: 110, companions: [(bin: 40, ratio: 0.5)])
      guard
        case .success(let bpm, _, _, let fold) = BNNSTechnique.decodeLogitsWithDiagnostic(
          v, policy: .massRatio(threshold: threshold))
      else {
        Issue.record("expected .success at threshold \(threshold)")
        return
      }
      if bpm == 70.0 {
        #expect(fold != nil, "folded to 70 at \(threshold) with no record")
        #expect(fold?.fromBPM == 140.0)
      } else {
        #expect(bpm == 140.0, "unfolded must be the bare argmax at \(threshold)")
        #expect(fold == nil, "unfolded but carried a record at \(threshold)")
      }
    }
  }

  /// The static decode is `internal` and directly callable, so it cannot
  /// assume its policy came through the clamping initializer.
  ///
  /// Probed on the HIGH side, which is the only side where the clamp is
  /// observable. Below zero it is not: `ratio >= -1.0` and `ratio >= 0.0`
  /// both accept every reachable ratio, since `halfMass` and `maxMass` are
  /// each guarded positive. Above one it is: a mass ratio can exceed 1.0
  /// when the half tempo straddles two bins whose combined mass beats the
  /// argmax bin (the corpus run recorded ratios up to 1.70), so an
  /// unclamped 4.0 would reject a fold that the clamped 1.0 accepts.
  @Test("an out-of-range threshold on the static path is clamped")
  @available(macOS 15.0, *)
  func outOfRangeThresholdIsClampedOnStaticPath() {
    // Bin 111 is 141 BPM; bins 40 and 41 straddle its half tempo. 0.6 + 0.6
    // gives a ratio of 1.2, above 1.0 and far below 4.0.
    let v = logits(
      argmaxBin: 111, companions: [(bin: 40, ratio: 0.6), (bin: 41, ratio: 0.6)])

    guard
      case .success(let high, _, _, let highFold) =
        BNNSTechnique.decodeLogitsWithDiagnostic(v, policy: .massRatio(threshold: 4.0))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(high == 70.5, "4.0 must clamp to 1.0, which a 1.2 ratio clears")
    #expect((highFold?.massRatio ?? 0) > 1.0, "the ratio must actually exceed 1.0")

    guard
      case .success(let low, _, _, _) =
        BNNSTechnique.decodeLogitsWithDiagnostic(v, policy: .massRatio(threshold: -1.0))
    else {
      Issue.record("expected .success")
      return
    }
    #expect(low == 70.5, "a negative threshold must behave as the clamped 0.0")
  }

  // MARK: - Policy value semantics

  @Test("threshold accessor reports the policy's configured value")
  @available(macOS 15.0, *)
  func policyThresholdAccessor() {
    #expect(OctaveFoldPolicy.disabled.threshold == nil)
    #expect(OctaveFoldPolicy.massRatio(threshold: 0.25).threshold == 0.25)
  }

  @Test("Options defaults to folding disabled")
  @available(macOS 15.0, *)
  func optionsDefaultsToDisabled() {
    #expect(BNNSTechnique.Options().octaveFold == .disabled)
    #expect(BNNSTechnique.Options.default.octaveFold == .disabled)
    #expect(
      BNNSTechnique.Options.default.confidenceThreshold
        == BNNSTechnique.defaultConfidenceThreshold)
    #expect(
      BNNSTechnique.Options.default.marginThreshold
        == BNNSTechnique.defaultMarginThreshold)
  }
}
