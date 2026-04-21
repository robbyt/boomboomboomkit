//
//  GiantStepsBenchmarkTests.swift
//  BoomBoomBoomKitTests
//
//  Env-gated benchmark using the GiantSteps Tempo Dataset (664 EDM tracks).
//  Set GIANTSTEPS_CORPUS_PATH to the dataset directory to enable these tests.
//  Ground truth: annotations_v2/tempo (crowdsourced BPM, v2 corrections).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Accuracy Metrics

private struct AccuracyMetrics: Sendable {
  let total: Int
  let acc1Correct: Int
  let acc2Correct: Int
  let failures: [(track: GiantStepsTrack, expected: Double, got: Double)]

  var acc1: Double { total > 0 ? Double(acc1Correct) / Double(total) * 100 : 0 }
  var acc2: Double { total > 0 ? Double(acc2Correct) / Double(total) * 100 : 0 }
}

// MARK: - GiantSteps Benchmark Suite

@Suite("GiantSteps Tempo Benchmark")
struct GiantStepsBenchmarkTests {

  private let corpusPath: String
  private let groundTruth: [GiantStepsTrack]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"], !path.isEmpty
    else {
      throw GiantStepsError.corpusPathNotSet
    }
    corpusPath = path

    // Load ground truth from corpus directory (same pattern as daw-oracle.json)
    let jsonPath = (path as NSString).appendingPathComponent("giantsteps-tempo-ground-truth.json")
    guard FileManager.default.fileExists(atPath: jsonPath) else {
      throw GiantStepsError.groundTruthNotFound
    }

    let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
    groundTruth = try JSONDecoder().decode([GiantStepsTrack].self, from: data)
  }

  @Test("benchmark at default intensity (7)")
  func benchmarkDefaultIntensity() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.02)
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

  @Test("benchmark Acc1 strict (2% tolerance)")
  func benchmarkAcc1Strict() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.02)
    print("\n=== GiantSteps Tempo Benchmark — Acc1 Strict (2% tolerance) ===")
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

  @Test("benchmark Acc1 MIREX (4% tolerance)")
  func benchmarkAcc1MIREX() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.04)
    print("\n=== GiantSteps Tempo Benchmark — Acc1 MIREX (4% tolerance) ===")
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
    let (metrics, perTrack) = try await runBenchmark(intensity: .default, tolerance: 0.02)

    // Group by genre using the shared `mirexHit` helper so the stratified counts
    // stay in lockstep with `runBenchmark`'s aggregate Acc1/Acc2.
    var genreStats: [String: (total: Int, acc1: Int, acc2: Int)] = [:]
    for (track, detected) in perTrack {
      let genre = track.genre.isEmpty ? "unknown" : track.genre
      var stats = genreStats[genre, default: (total: 0, acc1: 0, acc2: 0)]
      stats.total += 1
      if let detected {
        let hit = mirexHit(track: track, detected: detected, tolerance: 0.02)
        if hit.acc1 {
          stats.acc1 += 1
          stats.acc2 += 1
        } else if hit.acc2 {
          stats.acc2 += 1
        }
      }
      genreStats[genre] = stats
    }

    let buckets = genreStats.map { genre, stats in
      GenreBucket(
        genre: genre, total: stats.total,
        acc1Correct: stats.acc1, acc2Correct: stats.acc2)
    }

    let report = GenreAccuracyReporter.format(
      corpusLabel: "GiantSteps",
      intensity: AnalysisIntensity.default.rawValue,
      buckets: buckets,
      overallAcc1Percent: metrics.acc1, overallAcc2Percent: metrics.acc2)
    print("\n" + report)
  }

  // MARK: - Helpers

  private func trackURL(_ track: GiantStepsTrack) -> URL {
    URL(fileURLWithPath: corpusPath)
      .appendingPathComponent("audio")
      .appendingPathComponent(track.filename)
  }

  private func runBenchmark(
    intensity: AnalysisIntensity,
    mergeStrategy: CandidateMergeStrategy = .maxConfidence,
    tolerance: Double
  ) async throws -> (
    metrics: AccuracyMetrics, perTrack: [(track: GiantStepsTrack, detected: Double?)]
  ) {
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
    var perTrack: [(track: GiantStepsTrack, detected: Double?)] = []
    perTrack.reserveCapacity(availableTracks.count)

    for (index, track) in availableTracks.enumerated() {
      let detected = trackBPMs[index]
      perTrack.append((track: track, detected: detected))

      guard let detected else {
        failures.append((track: track, expected: track.bpm, got: 0))
        continue
      }

      let hit = mirexHit(track: track, detected: detected, tolerance: tolerance)

      if hit.acc1 {
        acc1Correct += 1
        acc2Correct += 1
      } else if hit.acc2 {
        acc2Correct += 1
        failures.append((track: track, expected: track.bpm, got: detected))
      } else {
        failures.append((track: track, expected: track.bpm, got: detected))
      }
    }

    let metrics = AccuracyMetrics(
      total: availableTracks.count, acc1Correct: acc1Correct,
      acc2Correct: acc2Correct, failures: failures)
    return (metrics: metrics, perTrack: perTrack)
  }

  /// MIREX Acc1/Acc2 hit check with optional `tempo2` fallback.
  /// Shared by `runBenchmark` and `benchmarkByGenre` so the two stay in lockstep.
  private func mirexHit(
    track: GiantStepsTrack,
    detected: Double,
    tolerance: Double
  ) -> (acc1: Bool, acc2: Bool) {
    let acc1 =
      isAcc1Match(detected, track.bpm, tolerance: tolerance)
      || (track.tempo2.map { isAcc1Match(detected, $0, tolerance: tolerance) } ?? false)
    let acc2 =
      acc1 || isAcc2Match(detected, track.bpm, tolerance: tolerance)
      || (track.tempo2.map { isAcc2Match(detected, $0, tolerance: tolerance) } ?? false)
    return (acc1, acc2)
  }
}

private enum GiantStepsError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
