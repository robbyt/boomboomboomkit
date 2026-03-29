//
//  AblationTests.swift
//  BoomBoomBoomKitTests
//
//  Systematic ablation testing using TechniqueSet combinations.
//  Quick mode: named presets vs bundled click tracks (always runs, <1s).
//  Full mode: all 64 DSP combinations vs OA300 corpus (env-gated, ~9 min).
//

import Foundation
import Testing

import BoomBoomBoomKitTestSupport

@testable import BoomBoomBoomKit

// MARK: - Ablation Ground Truth

private struct AblationTrack: Decodable, Sendable {
  let filename: String
  let bpm: Double
  let subdir: String?
  let title: String
}

private func isAcc1(_ detected: Double, _ expected: Double) -> Bool {
  abs(detected - expected) / expected <= 0.02
}

private func isAcc2(_ detected: Double, _ expected: Double) -> Bool {
  isAcc1(detected, expected)
    || isAcc1(detected * 2, expected)
    || isAcc1(detected / 2, expected)
}

// MARK: - Quick Ablation (always runs)

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
        samples: samples, sampleRate: 44100, techniques: techniques)
      let r = try #require(result, "Preset \(name) returned nil")
      #expect(isAcc1(r.bpm, 120), "Preset \(name) got \(String(format: "%.1f", r.bpm)), expected ~120")
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

// MARK: - Full Ablation Matrix (env-gated)

@Suite(
  "Ablation — Full Matrix",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))
struct AblationMatrixTests {

  private let corpusPath: String
  private let groundTruth: [AblationTrack]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] else {
      throw AblationError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw AblationError.groundTruthNotFound }
    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([AblationTrack].self, from: data)
  }

  @Test("full 64-combination ablation matrix", .timeLimit(.minutes(15)))
  func fullAblationMatrix() async throws {
    let allCombos = TechniqueSet.allDSPCombinations()

    print("\n=== Full 64-Combination Ablation Matrix ===")
    print(
      "Configuration".padding(toLength: 40, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Corr Total  Delta")
    print(String(repeating: "-", count: 72))

    // Run all 64 combinations in parallel via structured concurrency
    typealias ComboResult = (label: String, acc1: Int, acc2: Int, total: Int)
    let empty: ComboResult = (label: "", acc1: 0, acc2: 0, total: 0)
    let gt = groundTruth
    let path = corpusPath
    let results = await withTaskGroup(of: (Int, ComboResult).self) { group in
      for (index, techniques) in allCombos.enumerated() {
        group.addTask {
          guard let (acc1, acc2, total) = try? Self.runCorpusFromDisk(
            techniques: techniques, groundTruth: gt, corpusPath: path)
          else { return (index, empty) }
          return (index, (label: techniques.label, acc1: acc1, acc2: acc2, total: total))
        }
      }
      var collected = [ComboResult](repeating: empty, count: allCombos.count)
      for await (i, result) in group { collected[i] = result }
      return collected
    }

    // Find baseline and best
    let baselineLabel = TechniqueSet.baseline.label
    var bestAcc1 = 0
    var bestLabel = ""
    var baselineAcc1 = 0

    for r in results {
      if r.label == baselineLabel { baselineAcc1 = r.acc1 }
      if r.acc1 > bestAcc1 { bestAcc1 = r.acc1; bestLabel = r.label }
    }

    // Sort by Acc1 descending for readable output
    let sorted = results.sorted { $0.acc1 > $1.acc1 }
    for r in sorted {
      let delta = r.acc1 - baselineAcc1
      let deltaStr = r.label == baselineLabel ? "  --" : (delta >= 0 ? " +\(delta)" : " \(delta)")
      let acc1Pct = String(format: "%5.1f%%", Double(r.acc1) / Double(r.total) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(r.acc2) / Double(r.total) * 100)
      print(
        r.label.padding(toLength: 40, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct) \(String(format: "%3d", r.acc1))   \(String(format: "%3d", r.total)) \(deltaStr)"
      )
    }

    print("\nBest combination: \(bestLabel) (Acc1=\(bestAcc1))")
    print("Baseline: \(TechniqueSet.baseline.label) (Acc1=\(baselineAcc1))")
  }

  @Test(
    "per-track technique impact — which tracks does each technique change?",
    .timeLimit(.minutes(10)))
  func perTrackImpact() async throws {
    let namedSets: [(String, TechniqueSet)] = [
      ("sharp", TechniqueSet.baseline.inserting(.acfSharpening)),
      ("thresh", TechniqueSet.baseline.inserting(.adaptiveThreshold)),
      ("norm", TechniqueSet.baseline.inserting(.subBandNormalization)),
      ("top5", TechniqueSet.baseline.inserting(.expandedCandidates)),
      ("optimal", .optimal),
      ("dnbOptimized", .dnbOptimized),
      ("full", .full),
    ]

    // Run baseline + all named sets in parallel via structured concurrency
    let allSets = [("baseline", TechniqueSet.baseline)] + namedSets
    let gt = groundTruth
    let path = corpusPath
    let allResults = await withTaskGroup(of: (Int, [String: Double]).self) { group in
      for (index, (_, techniques)) in allSets.enumerated() {
        group.addTask {
          guard let results = try? Self.perTrackResultsFromDisk(
            techniques: techniques, groundTruth: gt, corpusPath: path)
          else { return (index, [:]) }
          return (index, results)
        }
      }
      var collected = [[String: Double]](repeating: [:], count: allSets.count)
      for await (i, result) in group { collected[i] = result }
      return collected
    }

    let baselineResults = allResults[0]

    print("\n=== Per-Track Technique Impact ===")
    print("(Shows tracks where technique CHANGED the result vs baseline)\n")

    for (setIndex, (name, _)) in namedSets.enumerated() {
      let results = allResults[setIndex + 1]  // +1 to skip baseline
      var improved = 0
      var regressed = 0

      for (filename, detected) in results {
        guard let baseDetected = baselineResults[filename],
          let track = groundTruth.first(where: { $0.filename == filename })
        else { continue }

        let basCorrect = isAcc1(baseDetected, track.bpm)
        let newCorrect = isAcc1(detected, track.bpm)

        if !basCorrect && newCorrect {
          improved += 1
          print(
            "  [\(name)] IMPROVED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))->\(String(format: "%.1f", detected)) (expected \(track.bpm))"
          )
        } else if basCorrect && !newCorrect {
          regressed += 1
          print(
            "  [\(name)] REGRESSED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))->\(String(format: "%.1f", detected)) (expected \(track.bpm))"
          )
        }
      }
      print(
        "  \(name): +\(improved) improved, -\(regressed) regressed, net=\(improved - regressed)")
      print()
    }
  }

  // MARK: - Helpers

  private func trackURL(_ track: AblationTrack) -> URL {
    Self.trackURL(track, corpusPath: corpusPath)
  }

  private static func trackURL(_ track: AblationTrack, corpusPath: String) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }

  private static func runCorpusFromDisk(
    techniques: TechniqueSet,
    groundTruth: [AblationTrack],
    corpusPath: String
  ) throws -> (acc1: Int, acc2: Int, total: Int) {
    var acc1 = 0
    var acc2 = 0
    var total = 0

    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      guard
        let result = BPMAnalyzer.estimateBPM(
          samples: samples, sampleRate: sampleRate, techniques: techniques)
      else {
        total += 1
        continue
      }

      total += 1
      if isAcc1(result.bpm, track.bpm) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2(result.bpm, track.bpm) {
        acc2 += 1
      }
    }

    return (acc1, acc2, total)
  }

  private static func perTrackResultsFromDisk(
    techniques: TechniqueSet,
    groundTruth: [AblationTrack],
    corpusPath: String
  ) throws -> [String: Double] {
    var results: [String: Double] = [:]
    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      if let result = BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: sampleRate, techniques: techniques)
      {
        results[track.filename] = result.bpm
      }
    }
    return results
  }
}

private enum AblationError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
