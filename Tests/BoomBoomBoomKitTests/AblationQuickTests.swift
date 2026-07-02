//
//  AblationQuickTests.swift
//  BoomBoomBoomKitTests
//
//  Named presets vs bundled click tracks. Always runs, <1s. No corpus required.
//  The 64-combination corpus-level ablation lives in the benchmark test target
//  (`AblationFullMatrixTests.swift`).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Ablation — Quick (presets vs click tracks)")
struct AblationQuickTests {

  @Test("TechniqueSet.allDSPCombinations generates 256 combinations (2^8; Story 4-7)")
  func allCombinationsCount() {
    let combos = TechniqueSet.allDSPCombinations()
    #expect(combos.count == 256)
  }

  @Test("DSPTechnique.allCases has 8 cases (Story 4-7 added .superFluxOnset)")
  func allCasesCount() {
    #expect(DSPTechnique.allCases.count == 8)
  }

  @Test("preset properties")
  func presetProperties() {
    #expect(TechniqueSet.optimal.contains(.acfSharpening))
    #expect(!TechniqueSet.optimal.contains(.adaptiveThreshold))
    #expect(!TechniqueSet.optimal.contains(.expandedCandidates))
    #expect(TechniqueSet.baseline.candidateCount == 3)
    #expect(TechniqueSet.full.candidateCount == 5)
    #expect(TechniqueSet(dspTechniques: [.expandedCandidates]).candidateCount == 5)
    #expect(TechniqueSet(candidateCount: 1).candidateCount == 1)
    #expect(TechniqueSet.dnbOptimized.contains(.subBandNormalization))
  }

  /// AC #7 (Story 3-3): `.optimal`-membership invariant for `.clickTrackCorrelation`.
  /// Story 3-3 Task 3.4 decided NOT to insert `.clickTrackCorrelation` into `.optimal`:
  /// at α=0.3 it regressed Acc1 by 2 tracks (53/82 vs 55/82); at α=0.7 it tied Acc1 and
  /// gained only +1 Acc2 (68/82 vs 67/82) — below the +2-track margin gate. The
  /// technique is exposed via `.clickAugmented` and `.full` for users who want it.
  /// Future refactors that flip this invariant by accident will fail here.
  @Test("invariant — .optimal does NOT contain .clickTrackCorrelation (AC #7)")
  func optimalClickInvariant() {
    #expect(TechniqueSet.optimal.contains(.clickTrackCorrelation) == false)
  }

  @Test(".clickAugmented preset is .optimal + .clickTrackCorrelation")
  func clickAugmentedPreset() {
    #expect(TechniqueSet.clickAugmented.contains(.acfSharpening))
    #expect(TechniqueSet.clickAugmented.contains(.subBandVoting))
    #expect(TechniqueSet.clickAugmented.contains(.fineGridRefinement))
    #expect(TechniqueSet.clickAugmented.contains(.clickTrackCorrelation))
    #expect(!TechniqueSet.clickAugmented.contains(.adaptiveThreshold))
    #expect(!TechniqueSet.clickAugmented.contains(.expandedCandidates))
    #expect(!TechniqueSet.clickAugmented.contains(.subBandNormalization))
    #expect(TechniqueSet.clickAugmented.candidateCount == 3)
  }

  @Test("TechniqueSet.label produces readable output")
  func labelOutput() {
    let empty = TechniqueSet()
    #expect(empty.label == "minimal")
    let label = TechniqueSet.optimal.label
    #expect(label.contains("sharp"))
    #expect(label.contains("vote"))
    #expect(label.contains("fine"))
  }

  @Test("inserting and removing techniques")
  func builders() {
    let base = TechniqueSet.baseline
    let withSharp = base.inserting(.acfSharpening)
    #expect(withSharp.contains(.acfSharpening))
    #expect(withSharp.contains(.subBandVoting))

    let withoutVote = withSharp.removing(.subBandVoting)
    #expect(!withoutVote.contains(.subBandVoting))
    #expect(withoutVote.contains(.acfSharpening))
  }

  @Test("named presets produce correct results on 120 BPM click track")
  func presetsOnClickTrack() throws {
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 44100, durationSeconds: 10)

    let presets: [(String, TechniqueSet)] = [
      ("baseline", .baseline),
      ("optimal", .optimal),
      ("full", .full),
      ("dnbOptimized", .dnbOptimized),
    ]

    for (name, techniqueSet) in presets {
      let result = BPMAnalyzer.estimateBPM(
        decoded: .synthetic(samples, sampleRate: 44100), options: .init(techniqueSet: techniqueSet))
      let r = try #require(result, "Preset \(name) returned nil")
      #expect(
        isAcc1Match(r.bpm, 120, tolerance: 0.02),
        "Preset \(name) got \(String(format: "%.1f", r.bpm)), expected ~120")
    }
  }

  @Test("MLTechnique protocol can be conformed to")
  func mlTechniqueConformance() {
    struct NoOpML: MLTechnique {
      func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
        return nil
      }
    }

    let ml = NoOpML()
    let trace = BPMDiagnosticTrace()
    let result = ml.evaluate(trace: trace)
    #expect(result == nil)
  }
}
