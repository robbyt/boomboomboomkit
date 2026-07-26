//
//  PublicInputHardeningTests.swift
//  BoomBoomBoomKitTests
//
//  GH-167 item 7 (#129, #131): public configuration types must not accept
//  values that silently disable a feature or leak a sentinel into a public
//  result.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("MetadataPolicy input hardening (#129)")
struct MetadataPolicyHardeningTests {

  /// Every numeric field, every hostile input, on BOTH paths — the initializer
  /// and post-init mutation. Observers do not run during initialization, so a
  /// fix applied to only one path would pass a test that exercised only the
  /// other.
  @Test(
    "non-finite input is replaced by the documented default, at init and on assignment",
    arguments: [Double.nan, .infinity, -.infinity])
  func nonFiniteReplacedByDefault(_ bad: Double) {
    let viaInit = MetadataPolicy(
      consensusTolerance: bad, corroborationTolerance: bad,
      corroborationBoost: bad, maxBoostedConfidence: bad, skepticismPenalty: bad)
    #expect(viaInit.consensusTolerance == MetadataPolicy.defaultConsensusTolerance)
    #expect(viaInit.corroborationTolerance == MetadataPolicy.defaultCorroborationTolerance)
    #expect(viaInit.corroborationBoost == MetadataPolicy.defaultCorroborationBoost)
    #expect(viaInit.maxBoostedConfidence == MetadataPolicy.defaultMaxBoostedConfidence)
    #expect(viaInit.skepticismPenalty == MetadataPolicy.defaultSkepticismPenalty)

    var viaSetter = MetadataPolicy()
    viaSetter.consensusTolerance = bad
    viaSetter.corroborationTolerance = bad
    viaSetter.corroborationBoost = bad
    viaSetter.maxBoostedConfidence = bad
    viaSetter.skepticismPenalty = bad
    #expect(viaSetter == MetadataPolicy(), "post-init assignment must normalize too")
  }

  /// A negative value carries intent — it just makes every comparison fail —
  /// so it clamps rather than reverting to the default.
  @Test("negative values clamp to zero rather than reverting to the default")
  func negativeClampsToZero() {
    var p = MetadataPolicy(
      consensusTolerance: -5, corroborationTolerance: -0.5,
      corroborationBoost: -2, maxBoostedConfidence: -1, skepticismPenalty: -1)
    #expect(p.consensusTolerance == 0)
    #expect(p.corroborationTolerance == 0)
    #expect(p.corroborationBoost == 0)
    #expect(p.maxBoostedConfidence == 0)
    #expect(p.skepticismPenalty == 0)

    p.corroborationBoost = -99
    #expect(p.corroborationBoost == 0)
  }

  /// The two probability fields saturate at 1; the boost and tolerances do not,
  /// because a boost above 1 and a tolerance above 1 are both meaningful.
  @Test("only the probability fields are capped at 1")
  func probabilityFieldsCapAtOne() {
    let p = MetadataPolicy(
      consensusTolerance: 50, corroborationTolerance: 5,
      corroborationBoost: 4, maxBoostedConfidence: 9, skepticismPenalty: 9)
    #expect(p.maxBoostedConfidence == 1.0)
    #expect(p.skepticismPenalty == 1.0)
    #expect(p.consensusTolerance == 50, "an absolute BPM tolerance may exceed 1")
    #expect(p.corroborationTolerance == 5)
    #expect(p.corroborationBoost == 4, "a boost above 1 is the normal case")
  }

  @Test("zero and the legal boundaries survive untouched")
  func boundariesSurvive() {
    let p = MetadataPolicy(
      consensusTolerance: 0, corroborationTolerance: 0,
      corroborationBoost: 0, maxBoostedConfidence: 1.0, skepticismPenalty: 0)
    #expect(p.consensusTolerance == 0)
    #expect(p.maxBoostedConfidence == 1.0)
    #expect(p.skepticismPenalty == 0)
  }

  // MARK: - valueRange

  /// Only objectively invalid ranges are replaced.
  @Test("objectively invalid ranges fall back to the default")
  func invalidRangesFallBack() {
    // Degenerate.
    #expect(
      MetadataPolicy(valueRange: 300.0...300.0).valueRange == MetadataPolicy.defaultValueRange)
    // Infinite-ended — constructible, unlike an inverted range.
    #expect(
      MetadataPolicy(valueRange: 30.0...Double.infinity).valueRange
        == MetadataPolicy.defaultValueRange)
    #expect(
      MetadataPolicy(valueRange: -Double.infinity...300.0).valueRange
        == MetadataPolicy.defaultValueRange)
    // Negative lower bound.
    #expect(
      MetadataPolicy(valueRange: -10.0...300.0).valueRange == MetadataPolicy.defaultValueRange)
    // Upper bound nothing could match.
    #expect(
      MetadataPolicy(valueRange: -5.0 ... -1.0).valueRange == MetadataPolicy.defaultValueRange)
  }

  /// The counterpart, and the one that keeps the rule honest: a narrow but
  /// legal range is a caller's deliberate filter, not a typo the library gets
  /// to overrule.
  @Test("a legitimately narrow range is preserved")
  func narrowRangeSurvives() {
    #expect(MetadataPolicy(valueRange: 0.0...1.0).valueRange == 0.0...1.0)
    #expect(MetadataPolicy(valueRange: 120.0...130.0).valueRange == 120.0...130.0)

    var p = MetadataPolicy()
    p.valueRange = 0.0...1.0
    #expect(p.valueRange == 0.0...1.0, "assignment must not widen it either")
  }

  // MARK: - Value semantics

  /// `MetadataPolicy` is `Hashable` and used as a value. Normalization moved
  /// the stored fields behind private backing storage, so this pins that
  /// equality and hashing still behave after every mutation path.
  @Test("stays reflexive and hash-key usable after mutation")
  func valueSemanticsSurviveMutation() {
    var p = MetadataPolicy()
    p.corroborationBoost = .nan  // normalizes to the default
    #expect(p == p)
    #expect(p == MetadataPolicy(), "a normalized NaN must equal the default policy")
    #expect(p.hashValue == MetadataPolicy().hashValue)
    #expect(Set([p, MetadataPolicy()]).count == 1)
  }

  /// The defaults must not have moved. If normalization changed any shipped
  /// value, every corpus number in CLAUDE.md would be measuring a different
  /// pipeline.
  @Test("the default policy is unchanged by normalization")
  func defaultsUnchanged() {
    let d = MetadataPolicy.default
    #expect(d.consensusTolerance == 0.5)
    #expect(d.corroborationTolerance == 0.03)
    #expect(d.corroborationBoost == 1.25)
    #expect(d.maxBoostedConfidence == 0.95)
    #expect(d.skepticismPenalty == 0.85)
    #expect(d.valueRange == 30.0...300.0)
    #expect(MetadataPolicy.disabled.enabledSources.isEmpty)
  }
}

@Suite("TechniqueSet candidateCount provenance (#131)")
struct TechniqueSetCandidateCountTests {

  /// The regression the issue reports.
  @Test("an explicit count survives inserting and removing")
  func explicitCountSurvivesBuilders() {
    let base = TechniqueSet(dspTechniques: [], candidateCount: 1)
    #expect(base.candidateCount == 1)
    #expect(base.inserting(.acfSharpening).candidateCount == 1)
    #expect(base.inserting(.expandedCandidates).candidateCount == 1)
    #expect(base.inserting(.expandedCandidates).removing(.expandedCandidates).candidateCount == 1)
  }

  /// The state transition a `didSet`-flag design gets wrong: after the first
  /// builder call marks the count explicit, later membership changes stop
  /// moving it. A one-step test cannot see this.
  @Test("a derived count keeps tracking membership across a sequence")
  func derivedCountTracksMembershipAcrossSequence() {
    var s = TechniqueSet()
    #expect(s.candidateCount == 3)
    s = s.inserting(.acfSharpening)
    #expect(s.candidateCount == 3, "a non-expanding technique leaves it at 3")
    s = s.inserting(.expandedCandidates)
    #expect(s.candidateCount == 5, "this is the step a frozen flag would miss")
    s = s.removing(.expandedCandidates)
    #expect(s.candidateCount == 3)
  }

  /// Builders are not the only mutation path. A derived count must follow
  /// direct set mutation too, which a stored recomputed field cannot do.
  @Test("a derived count follows direct dspTechniques mutation")
  func derivedCountFollowsDirectMutation() {
    var s = TechniqueSet()
    #expect(s.candidateCount == 3)
    s.dspTechniques.insert(.expandedCandidates)
    #expect(s.candidateCount == 5, "bypassing the builders must not bypass derivation")
    s.dspTechniques.remove(.expandedCandidates)
    #expect(s.candidateCount == 3)
  }

  /// `extractTopCandidates(count: 0)` yields an empty candidate list, which the
  /// pipeline surfaces as a nil result indistinguishable from real silence.
  @Test("counts below one clamp, at init and on assignment", arguments: [0, -1, Int.min])
  func belowOneClamps(_ bad: Int) {
    #expect(TechniqueSet(candidateCount: bad).candidateCount == 1)
    var s = TechniqueSet()
    s.candidateCount = bad
    #expect(s.candidateCount == 1)
  }

  @Test("a no-op insert or remove changes nothing")
  func noOpBuildersAreInert() {
    let derived = TechniqueSet(dspTechniques: [.acfSharpening])
    #expect(derived.inserting(.acfSharpening) == derived)
    #expect(derived.removing(.subBandVoting) == derived)
  }

  @Test("copy-then-mutate does not alias")
  func copyThenMutateDoesNotAlias() {
    let original = TechniqueSet(dspTechniques: [.acfSharpening], candidateCount: 2)
    var copy = original
    copy.candidateCount = 4
    copy.dspTechniques.insert(.expandedCandidates)
    #expect(original.candidateCount == 2)
    #expect(!original.dspTechniques.contains(.expandedCandidates))
    #expect(copy.candidateCount == 4)
  }

  // MARK: - Identity

  /// Provenance is part of identity, deliberately. Implicit-3 and explicit-3
  /// have the same visible state today but diverge on the next `inserting`, so
  /// calling them equal would let equal values yield unequal results from the
  /// same call. Pinned so a future "cleanup" of the synthesized conformance
  /// cannot quietly reintroduce that.
  @Test("implicit and explicit counts with the same value are not equal")
  func provenanceParticipatesInIdentity() {
    let implicitThree = TechniqueSet(dspTechniques: [])
    let explicitThree = TechniqueSet(dspTechniques: [], candidateCount: 3)
    #expect(implicitThree.candidateCount == explicitThree.candidateCount)
    #expect(implicitThree != explicitThree, "they diverge on the next inserting()")
    // And that divergence is real, not hypothetical.
    #expect(implicitThree.inserting(.expandedCandidates).candidateCount == 5)
    #expect(explicitThree.inserting(.expandedCandidates).candidateCount == 3)
  }

  @Test("equal values hash equally and behave in a Set")
  func equalValuesHashEqually() {
    let a = TechniqueSet(dspTechniques: [.acfSharpening], candidateCount: 4)
    let b = TechniqueSet(dspTechniques: [.acfSharpening], candidateCount: 4)
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
    #expect(a == a)
    #expect(Set([a, b]).count == 1)
    #expect(Set([a, TechniqueSet(dspTechniques: [.acfSharpening])]).count == 2)
  }

  /// The shipped presets must not have moved.
  @Test("presets keep their documented counts")
  func presetsUnchanged() {
    #expect(TechniqueSet.baseline.candidateCount == 3)
    #expect(TechniqueSet.optimal.candidateCount == 3)
    #expect(TechniqueSet.full.candidateCount == 5)
    #expect(TechniqueSet.allDSPCombinations().count == 256)
  }
}
