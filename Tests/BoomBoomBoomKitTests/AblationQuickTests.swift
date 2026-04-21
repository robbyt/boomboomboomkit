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

  @Test("TechniqueSet.allDSPCombinations generates 64 combinations")
  func allCombinationsCount() {
    let combos = TechniqueSet.allDSPCombinations()
    #expect(combos.count == 64)
  }

  @Test("DSPTechnique.allCases has 6 cases")
  func allCasesCount() {
    #expect(DSPTechnique.allCases.count == 6)
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

    for (name, techniques) in presets {
      let result = BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: 44100, options: .init(techniques: techniques))
      let r = try #require(result, "Preset \(name) returned nil")
      #expect(
        isAcc1Match(r.bpm, 120, tolerance: 0.02),
        "Preset \(name) got \(String(format: "%.1f", r.bpm)), expected ~120")
    }
  }

  @Test("MLTechnique protocol can be conformed to")
  func mlTechniqueConformance() {
    struct NoOpML: MLTechnique {
      let name = "noop"
      func evaluate(
        candidates: [(bpm: Double, score: Float)],
        trace: BPMDiagnosticTrace
      ) -> (bpm: Double, confidence: Double)? {
        return nil
      }
    }

    let ml = NoOpML()
    #expect(ml.name == "noop")
    let trace = BPMDiagnosticTrace()
    let result = ml.evaluate(candidates: [(bpm: 120.0, score: 0.9)], trace: trace)
    #expect(result == nil)
  }
}
