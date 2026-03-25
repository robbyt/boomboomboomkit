//
//  OA300BenchmarkTests.swift
//  BoomBoomBoomKitTests
//
//  Env-gated benchmark using the OA300 corpus with Rekordbox ground truth.
//  Set OA300_CORPUS_PATH to the corpus directory to enable these tests.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Ground Truth Model

private struct OA300Track: Decodable {
  let filename: String
  let bpm: Double
  let subdir: String?
  let title: String
}

// MARK: - Accuracy Metrics

private struct AccuracyMetrics {
  let total: Int
  let acc1Correct: Int
  let acc2Correct: Int
  let failures: [(track: OA300Track, expected: Double, got: Double)]

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

// MARK: - OA300 Benchmark Suite

@Suite("OA300 Benchmark", .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))
struct OA300BenchmarkTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    corpusPath = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"]!

    let jsonURL = Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")

    guard let url = jsonURL else {
      throw OA300Error.groundTruthNotFound
    }

    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: data)
  }

  @Test("benchmark at default intensity (7)")
  func benchmarkDefaultIntensity() throws {
    let metrics = try runBenchmark(intensity: .default)
    print("\n=== OA300 Benchmark — Intensity 7 (default) ===")
    print("Corpus: \(metrics.total) tracks, Rekordbox ground truth")
    print("Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print("Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    if !metrics.failures.isEmpty {
      print("\nAcc1 Failures:")
      print("| Track | Expected | Got | Delta% |")
      print("|-------|----------|-----|--------|")
      for f in metrics.failures {
        let delta = abs(f.got - f.expected) / f.expected * 100
        print(
          "| \(f.track.title.prefix(40)) | \(String(format: "%.1f", f.expected)) | \(String(format: "%.1f", f.got)) | \(String(format: "%.1f", delta))% |"
        )
      }
    }
  }

  @Test("multi-intensity comparison (monotonic Acc1)")
  func benchmarkMultiIntensity() throws {
    let levels = [1, 3, 5, 7]
    var previousAcc1Count = 0
    var perTrackResults: [String: [Int: Double]] = [:]

    print("\n=== OA300 Multi-Intensity Comparison ===")

    for level in levels {
      let intensity = AnalysisIntensity(rawValue: level)
      let metrics = try runBenchmark(intensity: intensity)
      print(
        "Intensity \(level): Acc1=\(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total)), Acc2=\(String(format: "%.1f", metrics.acc2))%"
      )

      // Track per-track results for regression warnings
      for f in metrics.failures {
        perTrackResults[f.track.filename, default: [:]][level] = f.got
      }

      // Assert per-corpus monotonicity
      #expect(
        metrics.acc1Correct >= previousAcc1Count,
        "Acc1 at intensity \(level) (\(metrics.acc1Correct)) should be >= intensity at previous level (\(previousAcc1Count))"
      )
      previousAcc1Count = metrics.acc1Correct
    }

    // Print per-track regressions as warnings (not assertions)
    for (filename, results) in perTrackResults.sorted(by: { $0.key < $1.key }) {
      let levelResults = results.sorted(by: { $0.key < $1.key })
      let desc = levelResults.map { "L\($0.key)=\(String(format: "%.1f", $0.value))" }
        .joined(separator: " ")
      print("  Warning: \(filename) failed at: \(desc)")
    }
  }

  @Test("Bad BPM subset with trace")
  func benchmarkBadBPMSubset() throws {
    let badBPMTracks = groundTruth.filter { $0.subdir == "Bad BPM" }
    guard !badBPMTracks.isEmpty else {
      print("No Bad BPM tracks found in ground truth")
      return
    }

    print("\n=== Bad BPM Subset (trace-enabled) ===")
    for track in badBPMTracks {
      let url = trackURL(track)
      guard FileManager.default.fileExists(atPath: url.path) else {
        print("  SKIP: \(track.filename) not found")
        continue
      }

      let result = try? AudioAnalysisService.analyzeBPM(
        url: url, intensity: .default, enableTrace: true)

      if let r = result {
        let match = isAcc1Match(r.bpm, track.bpm) ? "OK" : "MISS"
        let candidates = r.candidates.prefix(5).map { String(format: "%.1f", $0.bpm) }
          .joined(separator: ", ")
        print(
          "  [\(match)] \(track.title.prefix(40)): expected=\(track.bpm), got=\(String(format: "%.1f", r.bpm)), conf=\(String(format: "%.2f", r.confidence)), candidates=[\(candidates)]"
        )
      } else {
        print("  [NIL] \(track.title.prefix(40)): expected=\(track.bpm), got=nil")
      }
    }
  }

  // MARK: - Helpers

  private func trackURL(_ track: OA300Track) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath)
      .appendingPathComponent(track.filename)
  }

  private func runBenchmark(intensity: AnalysisIntensity) throws -> AccuracyMetrics {
    var acc1Correct = 0
    var acc2Correct = 0
    var tested = 0
    var failures: [(track: OA300Track, expected: Double, got: Double)] = []

    for track in groundTruth {
      let url = trackURL(track)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      guard let result = try? AudioAnalysisService.analyzeBPM(url: url, intensity: intensity)
      else {
        failures.append((track: track, expected: track.bpm, got: 0))
        tested += 1
        continue
      }

      tested += 1

      if isAcc1Match(result.bpm, track.bpm) {
        acc1Correct += 1
        acc2Correct += 1
      } else if isAcc2Match(result.bpm, track.bpm) {
        acc2Correct += 1
        failures.append((track: track, expected: track.bpm, got: result.bpm))
      } else {
        failures.append((track: track, expected: track.bpm, got: result.bpm))
      }
    }

    return AccuracyMetrics(
      total: tested, acc1Correct: acc1Correct,
      acc2Correct: acc2Correct, failures: failures)
  }
}

private enum OA300Error: Error {
  case groundTruthNotFound
}
