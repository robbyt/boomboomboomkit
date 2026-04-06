//
//  GiantStepsBenchmarkTests.swift
//  BoomBoomBoomKitTests
//
//  Env-gated benchmark using the GiantSteps Tempo Dataset (664 EDM tracks).
//  Set GIANTSTEPS_CORPUS_PATH to the dataset directory to enable these tests.
//  Ground truth: annotations_v2/tempo (crowdsourced BPM, v2 corrections).
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Ground Truth Model

private struct GiantStepsTrack: Decodable, Sendable {
  let filename: String
  let bpm: Double
  let track_id: String
  let genre: String
}

// MARK: - Accuracy Metrics

private struct AccuracyMetrics: Sendable {
  let total: Int
  let acc1Correct: Int
  let acc2Correct: Int
  let failures: [(track: GiantStepsTrack, expected: Double, got: Double)]

  var acc1: Double { total > 0 ? Double(acc1Correct) / Double(total) * 100 : 0 }
  var acc2: Double { total > 0 ? Double(acc2Correct) / Double(total) * 100 : 0 }
}

private func isAcc1Match(_ detected: Double, _ expected: Double) -> Bool {
  abs(detected - expected) / expected <= 0.02
}

private func isAcc2Match(_ detected: Double, _ expected: Double) -> Bool {
  isAcc1Match(detected, expected)
    || isAcc1Match(detected * 2, expected)
    || isAcc1Match(detected / 2, expected)
}

// MARK: - GiantSteps Benchmark Suite

@Suite(
  "GiantSteps Tempo Benchmark",
  .enabled(if: ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"] != nil))
struct GiantStepsBenchmarkTests {

  private let corpusPath: String
  private let groundTruth: [GiantStepsTrack]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"] else {
      throw GiantStepsError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "giantsteps-tempo-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/giantsteps-tempo-ground-truth", withExtension: "json")

    guard let url = jsonURL else {
      throw GiantStepsError.groundTruthNotFound
    }

    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([GiantStepsTrack].self, from: data)
  }

  @Test("benchmark at default intensity (7)")
  func benchmarkDefaultIntensity() async throws {
    let metrics = try await runBenchmark(intensity: .default)
    print("\n=== GiantSteps Tempo Benchmark — Intensity 7 (default) ===")
    print("Corpus: \(metrics.total) tracks, crowdsourced ground truth (v2)")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    if !metrics.failures.isEmpty {
      print("\nAcc1 Failures (first 30):")
      print("| Track ID | Genre | Expected | Got | Delta% |")
      print("|----------|-------|----------|-----|--------|")
      for f in metrics.failures.prefix(30) {
        let delta = abs(f.got - f.expected) / f.expected * 100
        print(
          "| \(f.track.track_id) | \(f.track.genre.prefix(15)) | \(String(format: "%.1f", f.expected)) | \(String(format: "%.1f", f.got)) | \(String(format: "%.1f", delta))% |"
        )
      }
      if metrics.failures.count > 30 {
        print("| ... | ... | ... | ... | ... |")
        print("(\(metrics.failures.count - 30) more failures omitted)")
      }
    }
  }

  @Test("genre-stratified accuracy")
  func benchmarkByGenre() async throws {
    let metrics = try await runBenchmark(intensity: .default)
    let allResults = try await runBenchmarkDetailed(intensity: .default)

    // Group by genre
    var genreStats: [String: (total: Int, acc1: Int, acc2: Int)] = [:]
    for (track, detected) in allResults {
      let genre = track.genre.isEmpty ? "unknown" : track.genre
      var stats = genreStats[genre, default: (total: 0, acc1: 0, acc2: 0)]
      stats.total += 1
      if let det = detected {
        if isAcc1Match(det, track.bpm) {
          stats.acc1 += 1
          stats.acc2 += 1
        } else if isAcc2Match(det, track.bpm) {
          stats.acc2 += 1
        }
      }
      genreStats[genre] = stats
    }

    print("\n=== GiantSteps Genre-Stratified Accuracy (Intensity 7) ===")
    print(
      "Genre".padding(toLength: 20, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Count")
    print(String(repeating: "-", count: 55))

    for (genre, stats) in genreStats.sorted(by: { $0.value.total > $1.value.total }) {
      let a1 = String(format: "%5.1f%%", Double(stats.acc1) / Double(stats.total) * 100)
      let a2 = String(format: "%5.1f%%", Double(stats.acc2) / Double(stats.total) * 100)
      print(
        genre.padding(toLength: 20, withPad: " ", startingAt: 0)
          + " \(a1) \(a2)  \(String(format: "%3d", stats.total))")
    }

    print(
      "\nOverall: Acc1=\(String(format: "%.1f", metrics.acc1))%, Acc2=\(String(format: "%.1f", metrics.acc2))%"
    )
  }

  // MARK: - Helpers

  private func trackURL(_ track: GiantStepsTrack) -> URL {
    URL(fileURLWithPath: corpusPath)
      .appendingPathComponent("audio")
      .appendingPathComponent(track.filename)
  }

  private func runBenchmark(
    intensity: AnalysisIntensity,
    mergeStrategy: CandidateMergeStrategy = .maxConfidence
  ) async throws -> AccuracyMetrics {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }

    let urls = availableTracks.map { trackURL($0) }

    let trackBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          (
            index,
            (try? AudioAnalysisService.analyzeBPM(
              url: url,
              options: {
                var o = AudioAnalysisService.Options()
                o.intensity = intensity
                o.mergeStrategy = mergeStrategy
                return o
              }()))?.bpm
          )
        }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    var acc1Correct = 0
    var acc2Correct = 0
    var failures: [(track: GiantStepsTrack, expected: Double, got: Double)] = []

    for (index, track) in availableTracks.enumerated() {
      guard let detected = trackBPMs[index] else {
        failures.append((track: track, expected: track.bpm, got: 0))
        continue
      }

      if isAcc1Match(detected, track.bpm) {
        acc1Correct += 1
        acc2Correct += 1
      } else if isAcc2Match(detected, track.bpm) {
        acc2Correct += 1
        failures.append((track: track, expected: track.bpm, got: detected))
      } else {
        failures.append((track: track, expected: track.bpm, got: detected))
      }
    }

    return AccuracyMetrics(
      total: availableTracks.count, acc1Correct: acc1Correct,
      acc2Correct: acc2Correct, failures: failures)
  }

  private func runBenchmarkDetailed(
    intensity: AnalysisIntensity
  ) async throws -> [(GiantStepsTrack, Double?)] {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    let urls = availableTracks.map { trackURL($0) }

    let trackBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          (
            index,
            (try? AudioAnalysisService.analyzeBPM(
              url: url,
              options: {
                var o = AudioAnalysisService.Options()
                o.intensity = intensity
                return o
              }()))?.bpm
          )
        }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    return zip(availableTracks, trackBPMs).map { ($0, $1) }
  }
}

private enum GiantStepsError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
