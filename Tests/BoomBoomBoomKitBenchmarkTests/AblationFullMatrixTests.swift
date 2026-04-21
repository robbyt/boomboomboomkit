//
//  AblationFullMatrixTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Full 64-combination ablation matrix vs OA300 corpus (~9 min).
//  Requires OA300_CORPUS_PATH; init throws (load-bearing fail) if unset.
//
//  The ablation suite uses a 2-factor Acc2 (`{1, 2, 1/2}`) rather than the MIREX
//  5-factor variant used by OA300 / GiantSteps / Performance benchmarks. This is
//  intentional — ablation measures relative effect of DSP techniques, and triplet
//  factors mask technique differences in DnB-heavy corpora. Keep the local
//  `isAcc1Abl` / `isAcc2Abl` helpers below rather than importing shared matchers.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Ablation-local accuracy helpers (2-factor Acc2, not MIREX)

private func isAcc1Abl(_ detected: Double, _ expected: Double) -> Bool {
  guard expected > 0 else { return false }
  return abs(detected - expected) / expected <= 0.02
}

private func isAcc2Abl(_ detected: Double, _ expected: Double) -> Bool {
  isAcc1Abl(detected, expected)
    || isAcc1Abl(detected * 2, expected)
    || isAcc1Abl(detected / 2, expected)
}

// MARK: - Full Ablation Matrix

@Suite("Ablation — Full Matrix")
struct AblationMatrixTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else {
      throw AblationError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw AblationError.groundTruthNotFound }
    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: data)
  }

  @Test("full 64-combination ablation matrix", .timeLimit(.minutes(15)))
  func fullAblationMatrix() async throws {
    let allCombos = TechniqueSet.allDSPCombinations()

    print("\n=== Full 64-Combination Ablation Matrix ===")
    print(
      "Configuration".padding(toLength: 40, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Corr Total  Delta")
    print(String(repeating: "-", count: 72))

    typealias ComboResult = (label: String, acc1: Int, acc2: Int, total: Int)
    let empty: ComboResult = (label: "", acc1: 0, acc2: 0, total: 0)
    let gt = groundTruth
    let path = corpusPath
    let results = await withTaskGroup(of: (Int, ComboResult).self) { group in
      for (index, techniques) in allCombos.enumerated() {
        group.addTask {
          guard
            let (acc1, acc2, total) = try? Self.runCorpusFromDisk(
              techniques: techniques, groundTruth: gt, corpusPath: path)
          else { return (index, empty) }
          return (index, (label: techniques.label, acc1: acc1, acc2: acc2, total: total))
        }
      }
      var collected = [ComboResult](repeating: empty, count: allCombos.count)
      for await (i, result) in group { collected[i] = result }
      return collected
    }

    let baselineLabel = TechniqueSet.baseline.label
    var bestAcc1 = 0
    var bestLabel = ""
    var baselineAcc1 = 0

    for r in results {
      if r.label == baselineLabel { baselineAcc1 = r.acc1 }
      if r.acc1 > bestAcc1 {
        bestAcc1 = r.acc1
        bestLabel = r.label
      }
    }

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

    let allSets = [("baseline", TechniqueSet.baseline)] + namedSets
    let gt = groundTruth
    let path = corpusPath
    let allResults = await withTaskGroup(of: (Int, [String: Double]).self) { group in
      for (index, (_, techniques)) in allSets.enumerated() {
        group.addTask {
          guard
            let results = try? Self.perTrackResultsFromDisk(
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

        let basCorrect = isAcc1Abl(baseDetected, track.bpm)
        let newCorrect = isAcc1Abl(detected, track.bpm)

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

  private func trackURL(_ track: OA300Track) -> URL {
    Self.trackURL(track, corpusPath: corpusPath)
  }

  private static func trackURL(_ track: OA300Track, corpusPath: String) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }

  private static func runCorpusFromDisk(
    techniques: TechniqueSet,
    groundTruth: [OA300Track],
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
          samples: samples, sampleRate: sampleRate, options: .init(techniques: techniques))
      else {
        total += 1
        continue
      }

      total += 1
      if isAcc1Abl(result.bpm, track.bpm) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2Abl(result.bpm, track.bpm) {
        acc2 += 1
      }
    }

    return (acc1, acc2, total)
  }

  private static func perTrackResultsFromDisk(
    techniques: TechniqueSet,
    groundTruth: [OA300Track],
    corpusPath: String
  ) throws -> [String: Double] {
    var results: [String: Double] = [:]
    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      if let result = BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: sampleRate, options: .init(techniques: techniques))
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
