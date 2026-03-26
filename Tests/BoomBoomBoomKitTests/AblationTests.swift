//
//  AblationTests.swift
//  BoomBoomBoomKitTests
//
//  Systematic ablation testing: each DSP technique solo, in pairs, and combined.
//  Measures Acc1/Acc2 for each configuration against the OA300 corpus.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Ablation Ground Truth

private struct AblationTrack: Decodable {
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

// MARK: - Ablation Matrix

@Suite(
  "Ablation Matrix",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))
struct AblationMatrixTests {

  private let corpusPath: String
  private let groundTruth: [AblationTrack]

  init() throws {
    corpusPath = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"]!

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw AblationError.groundTruthNotFound }
    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([AblationTrack].self, from: data)
  }

  @Test("full ablation matrix — individual techniques and combinations", .timeLimit(.minutes(10)))
  func fullAblationMatrix() throws {

    // Define individual techniques as config toggles
    let techniques: [(name: String, apply: (inout BPMPipelineConfiguration) -> Void)] = [
      ("sharp", { $0.useACFSharpening = true }),
      ("thresh", { $0.useAdaptiveThreshold = true }),
      ("norm", { $0.useSubBandNormalization = true }),
      ("top5", { $0.candidateCount = 5 }),
    ]

    // Baseline: original pipeline (3 candidates, voting, fine-grid, no quick wins)
    var configs: [(name: String, config: BPMPipelineConfiguration)] = [
      ("baseline", .baseline)
    ]

    // Individual techniques (each added to baseline)
    for tech in techniques {
      var config = BPMPipelineConfiguration.baseline
      tech.apply(&config)
      configs.append((tech.name, config))
    }

    // All pairs
    for i in 0..<techniques.count {
      for j in (i + 1)..<techniques.count {
        var config = BPMPipelineConfiguration.baseline
        techniques[i].apply(&config)
        techniques[j].apply(&config)
        configs.append(("\(techniques[i].name)+\(techniques[j].name)", config))
      }
    }

    // All four combined
    configs.append(("all", .full))

    // Quick test: just run baseline on first track to verify no crash
    let firstTrack = groundTruth.first!
    let firstURL = trackURL(firstTrack)
    let (testSamples, testRate) = try PCMBufferReader.readMonoSamples(
      from: firstURL, maxSeconds: 120)
    print("First track loaded: \(testSamples.count) samples at \(testRate)")
    let testResult = BPMAnalyzer.estimateBPM(
      samples: testSamples, sampleRate: testRate, config: .baseline)
    print("Baseline result: \(testResult?.bpm ?? -1) BPM")

    // Run each config against corpus (reads from disk each time)
    print("\n=== Ablation Matrix ===")
    print(
      "Configuration".padding(toLength: 35, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Corr Total")
    print(String(repeating: "-", count: 62))

    var baselineAcc1 = 0

    for (name, config) in configs {
      let (acc1, acc2, total) = try runCorpusFromDisk(config: config)

      let delta = acc1 - baselineAcc1
      let deltaStr = name == "baseline" ? "" : (delta >= 0 ? "+\(delta)" : "\(delta)")

      let acc1Pct = String(format: "%5.1f%%", Double(acc1) / Double(total) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(acc2) / Double(total) * 100)
      print(
        name.padding(toLength: 35, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct) \(String(format: "%3d", acc1))   \(String(format: "%3d", total))   \(deltaStr)"
      )

      if name == "baseline" { baselineAcc1 = acc1 }
    }
  }

  @Test(
    "per-track technique impact — which tracks does each technique change?",
    .timeLimit(.minutes(10)))
  func perTrackImpact() throws {
    let namedConfigs: [(String, BPMPipelineConfiguration)] = [
      (
        "sharp",
        {
          var c = BPMPipelineConfiguration.baseline
          c.useACFSharpening = true
          return c
        }()
      ),
      (
        "thresh",
        {
          var c = BPMPipelineConfiguration.baseline
          c.useAdaptiveThreshold = true
          return c
        }()
      ),
      (
        "norm",
        {
          var c = BPMPipelineConfiguration.baseline
          c.useSubBandNormalization = true
          return c
        }()
      ),
      (
        "top5",
        {
          var c = BPMPipelineConfiguration.baseline
          c.candidateCount = 5
          return c
        }()
      ),
      ("all", .full),
    ]

    let baselineResults = try perTrackResultsFromDisk(config: .baseline)

    print("\n=== Per-Track Technique Impact ===")
    print("(Shows tracks where technique CHANGED the result vs baseline)\n")

    for (name, config) in namedConfigs {
      let results = try perTrackResultsFromDisk(config: config)
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
            "  [\(name)] IMPROVED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))→\(String(format: "%.1f", detected)) (expected \(track.bpm))"
          )
        } else if basCorrect && !newCorrect {
          regressed += 1
          print(
            "  [\(name)] REGRESSED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))→\(String(format: "%.1f", detected)) (expected \(track.bpm))"
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
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }

  private func runCorpusFromDisk(config: BPMPipelineConfiguration) throws -> (
    acc1: Int, acc2: Int, total: Int
  ) {
    var acc1 = 0
    var acc2 = 0
    var total = 0

    for track in groundTruth {
      let url = trackURL(track)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      guard
        let result = BPMAnalyzer.estimateBPM(
          samples: samples, sampleRate: sampleRate, config: config)
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

  private func perTrackResultsFromDisk(config: BPMPipelineConfiguration) throws -> [String: Double]
  {
    var results: [String: Double] = [:]
    for track in groundTruth {
      let url = trackURL(track)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      if let result = BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: sampleRate, config: config)
      {
        results[track.filename] = result.bpm
      }
    }
    return results
  }
}

private enum AblationError: Error {
  case groundTruthNotFound
}
