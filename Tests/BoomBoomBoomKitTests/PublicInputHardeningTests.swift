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

  /// Only an unrepairable range falls back: a non-finite endpoint, or one
  /// still inverted after the lower bound is clamped.
  @Test("unrepairable ranges fall back, on both paths")
  func unrepairableRangesFallBack() {
    for bad in [30.0...Double.infinity, -Double.infinity...300.0, -5.0 ... -1.0] {
      #expect(
        MetadataPolicy(valueRange: bad).valueRange == MetadataPolicy.defaultValueRange,
        "init path")
      var p = MetadataPolicy()
      p.valueRange = bad
      #expect(p.valueRange == MetadataPolicy.defaultValueRange, "assignment path")
    }
  }

  /// A negative lower bound is repairable, so it clamps rather than reverting
  /// — the rule the scalar fields already follow. Reverting would silently
  /// reject tags in (0, 30) that the caller asked to accept.
  @Test("a negative lower bound clamps to zero rather than reverting")
  func negativeLowerBoundClamps() {
    #expect(MetadataPolicy(valueRange: -10.0...300.0).valueRange == 0.0...300.0)
    var p = MetadataPolicy()
    p.valueRange = -10.0...300.0
    #expect(p.valueRange == 0.0...300.0, "assignment path")
  }

  /// `-10.0 ... -1.0` is the case the evaluation order exists to protect:
  /// clamping the lower bound before checking orderability would try to form
  /// `0.0 ... -1.0`, which traps. Reaching this assertion at all is the proof.
  @Test("an unrepairable negative range does not trap")
  func negativeRangeDoesNotTrap() {
    #expect(
      MetadataPolicy(valueRange: -10.0 ... -1.0).valueRange == MetadataPolicy.defaultValueRange)
  }

  /// `valueRange` is consumed only via `contains`, so a single-point range is
  /// a working exact-match filter and a narrow one is a working narrow filter.
  /// The library cannot tell either from a typo, and widening a caller's
  /// filter would be its own bug.
  @Test("legal narrow and exact-match ranges are preserved, on both paths")
  func narrowAndExactRangesSurvive() {
    for good in [0.0...1.0, 120.0...130.0, 128.0...128.0, 0.0...0.0] {
      #expect(MetadataPolicy(valueRange: good).valueRange == good, "init path")
      var p = MetadataPolicy()
      p.valueRange = good
      #expect(p.valueRange == good, "assignment path")
    }
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

/// End-to-end: the normalized `valueRange` must produce the intended
/// accept/reject behaviour at the consumer, not merely store the intended
/// bounds. `FileMetadataReader.parseRawBPM` is the only thing that reads it.
@Suite("valueRange behaviour at the consumer (#129)")
struct ValueRangeConsumerTests {

  @Test("an exact-match range accepts its one value and rejects neighbours")
  func exactMatchRangeFilters() {
    let p = MetadataPolicy(valueRange: 128.0...128.0)
    #expect(FileMetadataReader.parseRawBPM("128", policy: p).rejectionReason == nil)
    #expect(FileMetadataReader.parseRawBPM("127", policy: p).rejectionReason == "out-of-range")
    #expect(FileMetadataReader.parseRawBPM("129", policy: p).rejectionReason == "out-of-range")
  }

  /// The clamp is the point: reverting `-10...300` to the default would have
  /// rejected 20, which the caller's floor of "no floor" asked to accept.
  @Test("a clamped negative floor accepts values the default would reject")
  func clampedFloorAcceptsBelowThirty() {
    let p = MetadataPolicy(valueRange: -10.0...300.0)
    #expect(p.valueRange == 0.0...300.0)
    #expect(FileMetadataReader.parseRawBPM("20", policy: p).rejectionReason == nil)
    #expect(
      FileMetadataReader.parseRawBPM("20", policy: MetadataPolicy()).rejectionReason
        == "out-of-range",
      "the default floor of 30 rejects it, which is what made the clamp matter")
  }

  /// `0...0` is only reachable as a filter when the zero sentinel is off.
  /// Without setting it, sentinel handling short-circuits before `contains`
  /// and this would prove the wrong path.
  @Test("a zero-only range accepts a parsed zero when the sentinel is disabled")
  func zeroOnlyRangeNeedsSentinelDisabled() {
    var parsing = MetadataPolicy.ParsingOptions()
    parsing.treatZeroAsAbsent = false
    let p = MetadataPolicy(valueRange: 0.0...0.0, parsing: parsing)
    #expect(p.valueRange == 0.0...0.0)
    #expect(FileMetadataReader.parseRawBPM("0", policy: p).rejectionReason == nil)

    // With the sentinel on, the same range never reaches the filter.
    let sentinelOn = MetadataPolicy(valueRange: 0.0...0.0)
    #expect(
      FileMetadataReader.parseRawBPM("0", policy: sentinelOn).rejectionReason == "sentinel-zero")
  }
}

@Suite("TechniqueSet candidateCount provenance (#131)")
struct TechniqueSetCandidateCountTests {

  /// The regression the issue reports.
  @Test("an explicit count survives inserting and removing")
  func explicitCountSurvivesBuilders() {
    let base = TechniqueSet(dspTechniques: [], candidateCountOverride: 1)
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
    #expect(TechniqueSet(candidateCountOverride: bad).candidateCount == 1)
    var s = TechniqueSet()
    s.candidateCountOverride = bad
    #expect(s.candidateCount == 1)
    #expect(s.candidateCountOverride == 1, "the clamp lands in storage, not at read")
  }

  @Test("a no-op insert or remove changes nothing")
  func noOpBuildersAreInert() {
    let derived = TechniqueSet(dspTechniques: [.acfSharpening])
    #expect(derived.inserting(.acfSharpening) == derived)
    #expect(derived.removing(.subBandVoting) == derived)
  }

  @Test("copy-then-mutate does not alias")
  func copyThenMutateDoesNotAlias() {
    let original = TechniqueSet(dspTechniques: [.acfSharpening], candidateCountOverride: 2)
    var copy = original
    copy.candidateCountOverride = 4
    copy.dspTechniques.insert(.expandedCandidates)
    #expect(original.candidateCount == 2)
    #expect(!original.dspTechniques.contains(.expandedCandidates))
    #expect(copy.candidateCount == 4)
  }

  /// The round trip the redesign exists to enable: pin, then return to
  /// automatic. The previous design had no route back — and its builders froze
  /// a derived count the first time one ran.
  @Test("unpinning returns the set to membership-derived behaviour")
  func unpinningRestoresAutomaticDerivation() {
    var set = TechniqueSet(candidateCountOverride: 2)
    #expect(set.candidateCount == 2)

    set.candidateCountOverride = nil
    #expect(set.candidateCount == 3, "back to derived")
    #expect(
      set.inserting(.expandedCandidates).candidateCount == 5,
      "and derivation resumes through the builders, which is where it used to freeze")

    // Round-tripping restores identity with a never-pinned set.
    #expect(set == TechniqueSet())
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
    let explicitThree = TechniqueSet(dspTechniques: [], candidateCountOverride: 3)
    #expect(implicitThree.candidateCount == explicitThree.candidateCount)
    #expect(implicitThree != explicitThree, "they diverge on the next inserting()")
    // And that divergence is real, not hypothetical.
    #expect(implicitThree.inserting(.expandedCandidates).candidateCount == 5)
    #expect(explicitThree.inserting(.expandedCandidates).candidateCount == 3)
  }

  @Test("equal values hash equally and behave in a Set")
  func equalValuesHashEqually() {
    let a = TechniqueSet(dspTechniques: [.acfSharpening], candidateCountOverride: 4)
    let b = TechniqueSet(dspTechniques: [.acfSharpening], candidateCountOverride: 4)
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
