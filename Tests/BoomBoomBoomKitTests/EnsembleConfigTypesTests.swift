//
//  EnsembleConfigTypesTests.swift
//  BoomBoomBoomKitTests
//
//  Story 6.5a: the byte-inert ensemble configuration types — SignalWeights,
//  OctaveEquivalencePolicy, MLExecutionPolicy, ComputeBudget. Asserts the type
//  shapes, defaults, conformances, and (critically) the NaN-safety of the
//  Double-carrying Hashable types.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("SignalWeights")
struct SignalWeightsTests {

  @Test("default is all 1.0")
  func defaults() {
    let w = SignalWeights.default
    #expect(w.dsp == 1.0)
    #expect(w.ml == 1.0)
    #expect(w.fileMetadata == 1.0)
    #expect(w.beatGrid == 1.0)
    #expect(SignalWeights() == SignalWeights.default)
  }

  @Test("finite inputs are preserved; negatives clamp to 0")
  func finitePreserved() {
    let w = SignalWeights(dsp: 2.5, ml: 0.0, fileMetadata: 0.5, beatGrid: -3.0)
    #expect(w.dsp == 2.5)
    #expect(w.ml == 0.0)
    #expect(w.fileMetadata == 0.5)
    #expect(w.beatGrid == 0.0)  // negative → 0
  }

  @Test("non-finite inputs normalize to the 1.0 default (NaN-safety)")
  func nonFiniteNormalized() {
    let nan = SignalWeights(
      dsp: .nan, ml: .infinity, fileMetadata: -.infinity, beatGrid: .signalingNaN)
    #expect(nan.dsp == 1.0)
    #expect(nan.ml == 1.0)
    #expect(nan.fileMetadata == 1.0)
    #expect(nan.beatGrid == 1.0)
    // Every field is finite, so Hashable reflexivity holds.
    #expect(
      nan.dsp.isFinite && nan.ml.isFinite && nan.fileMetadata.isFinite && nan.beatGrid.isFinite)
  }

  @Test("Hashable reflexivity survives NaN inputs (Set membership intact)")
  func hashableReflexivity() {
    // A value built from NaN inputs must still satisfy x == x and hash stably,
    // so Set membership de-duplicates it (the reflexivity break the project's
    // NaN-Hashable rule guards against).
    let a = SignalWeights(dsp: .nan, ml: .nan, fileMetadata: .nan, beatGrid: .nan)
    let b = SignalWeights(dsp: .nan, ml: .nan, fileMetadata: .nan, beatGrid: .nan)
    #expect(a == b)
    var set: Set<SignalWeights> = []
    set.insert(a)
    set.insert(b)
    #expect(set.count == 1)
  }
}

@Suite("ComputeBudget")
struct ComputeBudgetTests {

  @Test("default is full budget (all 1.0)")
  func defaults() {
    let b = ComputeBudget.default
    #expect(b.dspFraction == 1.0)
    #expect(b.mlFraction == 1.0)
    #expect(b.beatGridFraction == 1.0)
  }

  @Test("fractions clamp to [0, 1]; non-finite normalizes to 1.0")
  func clamp() {
    let b = ComputeBudget(dspFraction: 2.0, mlFraction: -1.0, beatGridFraction: .nan)
    #expect(b.dspFraction == 1.0)  // >1 → 1
    #expect(b.mlFraction == 0.0)  // <0 → 0
    #expect(b.beatGridFraction == 1.0)  // NaN → 1.0
  }

  @Test("Hashable reflexivity survives NaN inputs")
  func hashableReflexivity() {
    let a = ComputeBudget(dspFraction: .nan, mlFraction: .infinity, beatGridFraction: -.infinity)
    var set: Set<ComputeBudget> = []
    set.insert(a)
    set.insert(
      ComputeBudget(dspFraction: .nan, mlFraction: .infinity, beatGridFraction: -.infinity))
    #expect(set.count == 1)
  }

  @Test("AnalysisIntensity.budget ships inert as the full budget (Story 6.5a)")
  func intensityBudgetInert() {
    #expect(AnalysisIntensity.fastest.budget == .default)
    #expect(AnalysisIntensity.maximum.budget == .default)
  }
}

@Suite("OctaveEquivalencePolicy")
struct OctaveEquivalencePolicyTests {

  @Test("exactly three cases with stable rawValues")
  func cases() {
    #expect(OctaveEquivalencePolicy.allCases.count == 3)
    #expect(
      Set(OctaveEquivalencePolicy.allCases.map(\.rawValue))
        == ["collapseToFundamental", "octaveAwareWithPenalty", "exactMatchOnly"])
  }
}

@Suite("MLExecutionPolicy")
struct MLExecutionPolicyTests {

  @Test("default is .whenDSPConfidenceBelow(0.85)")
  func defaultCase() {
    #expect(MLExecutionPolicy.default == .whenDSPConfidenceBelow(0.85))
  }

  @Test("the three cases are distinct (Equatable)")
  func equatable() {
    #expect(MLExecutionPolicy.never != .always)
    #expect(MLExecutionPolicy.whenDSPConfidenceBelow(0.5) != .whenDSPConfidenceBelow(0.85))
    #expect(MLExecutionPolicy.whenDSPConfidenceBelow(0.85) == .whenDSPConfidenceBelow(0.85))
  }

  @Test("Equatable stays reflexive for a non-finite threshold (NaN-safety)")
  func nanReflexive() {
    // Synthesized `==` would compare the Double payload with `==`, making
    // `.whenDSPConfidenceBelow(.nan)` non-reflexive; the hand-written
    // bitPattern compare restores `x == x`.
    #expect(MLExecutionPolicy.whenDSPConfidenceBelow(.nan) == .whenDSPConfidenceBelow(.nan))
    #expect(
      MLExecutionPolicy.whenDSPConfidenceBelow(.infinity) == .whenDSPConfidenceBelow(.infinity))
  }
}
