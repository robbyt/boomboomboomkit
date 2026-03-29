//
//  DAWOracleBenchmarkTests.swift
//  BoomBoomBoomKitTests
//
//  Three-way BPM comparison: our detector vs Rekordbox vs DAW-verified BPMs.
//  The DAW oracle provides manually measured, 100% accurate BPMs from Bitwig.
//  Rekordbox is the benchmark TARGET; DAW oracle is the diagnostic TRUTH.
//
//  Requires: OA300_CORPUS_PATH env var and daw-oracle.json in the corpus dir.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Models

private struct OA300Track: Decodable, Sendable {
  let filename: String
  let bpm: Double
  let subdir: String?
  let title: String
}

private struct DAWOracleTrack: Decodable, Sendable {
  let filename: String
  let dawBpm: Double
  let rekordboxBpm: Double
  let subdir: String?
  let rekordboxDisagrees: Bool
  let disagreementType: String?
}

// MARK: - Error Classification

private enum ErrorCategory: String {
  case octave
  case triplet
  case other
}

private func classifyError(_ detected: Double, _ expected: Double) -> ErrorCategory? {
  guard expected > 0 else { return .other }
  if isAcc1Match(detected, expected) { return nil }
  let ratio = detected / expected
  if abs(ratio - 2.0) / 2.0 <= 0.04 || abs(ratio - 0.5) / 0.5 <= 0.04 {
    return .octave
  }
  if abs(ratio - 1.5) / 1.5 <= 0.04 || abs(ratio - 2.0 / 3.0) / (2.0 / 3.0) <= 0.04 {
    return .triplet
  }
  return .other
}

private func isAcc1Match(_ detected: Double, _ expected: Double) -> Bool {
  abs(detected - expected) / expected <= 0.02
}

private func isAcc2Match(_ detected: Double, _ expected: Double) -> Bool {
  isAcc1Match(detected, expected)
    || isAcc1Match(detected * 2, expected)
    || isAcc1Match(detected / 2, expected)
}

// MARK: - Test Suite

@Suite(
  "DAW Oracle Benchmark",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))
struct DAWOracleBenchmarkTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]
  private let dawOracle: [DAWOracleTrack]
  private let oracleByFilename: [String: DAWOracleTrack]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] else {
      throw DAWOracleError.corpusPathNotSet
    }
    corpusPath = path

    // Load Rekordbox ground truth from bundled fixture
    let gtURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = gtURL else { throw DAWOracleError.groundTruthNotFound }
    let gtData = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: gtData)

    // Load DAW oracle from corpus directory
    let oraclePath = (path as NSString).appendingPathComponent("daw-oracle.json")
    let oracleURL = URL(fileURLWithPath: oraclePath)
    guard FileManager.default.fileExists(atPath: oraclePath) else {
      throw DAWOracleError.oracleNotFound
    }
    let oracleData = try Data(contentsOf: oracleURL)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    dawOracle = try decoder.decode([DAWOracleTrack].self, from: oracleData)

    var lookup: [String: DAWOracleTrack] = [:]
    for track in dawOracle {
      lookup[track.filename] = track
    }
    oracleByFilename = lookup
  }

  private func trackURL(_ filename: String, subdir: String?) -> URL {
    var url = URL(fileURLWithPath: corpusPath)
    if let sub = subdir {
      url = url.appendingPathComponent(sub)
    }
    return url.appendingPathComponent(filename)
  }

  // MARK: - Three-Way Comparison (DAW-verified tracks only)

  @Test("three-way: ours vs Rekordbox vs DAW-verified")
  func threeWayComparison() async throws {
    #expect(dawOracle.count >= 20, "Expected at least 20 DAW oracle entries")

    print("\n=== Three-Way BPM Comparison (\(dawOracle.count) DAW-verified tracks) ===\n")

    struct TrackResult {
      let name: String
      let detected: Double?
      let rekordboxBpm: Double
      let dawBpm: Double
      let vsRkbx: String
      let vsDaw: String
      let errorVsRkbx: ErrorCategory?
      let errorVsDaw: ErrorCategory?
    }

    // Run analysis in parallel via structured concurrency
    let availableIndices: [(Int, DAWOracleTrack)] = dawOracle.enumerated().compactMap {
      (i, track) in
      let url = trackURL(track.filename, subdir: track.subdir)
      guard FileManager.default.fileExists(atPath: url.path) else { return nil }
      return (i, track)
    }

    let detectedBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (i, track) in availableIndices {
        let url = trackURL(track.filename, subdir: track.subdir)
        group.addTask { (i, (try? AudioAnalysisService.analyzeBPM(url: url))?.bpm) }
      }
      var results = [Double?](repeating: nil, count: dawOracle.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    // Collect results
    var results: [TrackResult] = []
    for (i, track) in dawOracle.enumerated() {
      let url = trackURL(track.filename, subdir: track.subdir)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let detected = detectedBPMs[i]
      let vsRkbx: String
      let vsDaw: String
      let errRkbx: ErrorCategory?
      let errDaw: ErrorCategory?

      if let d = detected {
        vsRkbx = isAcc1Match(d, track.rekordboxBpm) ? "OK" : "MISS"
        vsDaw = isAcc1Match(d, track.dawBpm) ? "OK" : "MISS"
        errRkbx = classifyError(d, track.rekordboxBpm)
        errDaw = classifyError(d, track.dawBpm)
      } else {
        vsRkbx = "FAIL"
        vsDaw = "FAIL"
        errRkbx = .other
        errDaw = .other
      }

      let name = String(track.filename.prefix(42))
      results.append(
        TrackResult(
          name: name, detected: detected,
          rekordboxBpm: track.rekordboxBpm, dawBpm: track.dawBpm,
          vsRkbx: vsRkbx, vsDaw: vsDaw,
          errorVsRkbx: errRkbx, errorVsDaw: errDaw))
    }

    // Print table
    for r in results {
      let det = r.detected.map { String(format: "%6.1f", $0) } ?? "   nil"
      let errStr: String
      if r.vsRkbx == "OK" && r.vsDaw == "OK" {
        errStr = "--"
      } else if let e = r.errorVsDaw {
        errStr = e.rawValue
      } else {
        errStr = "--"
      }
      print(
        "  \(r.name.padding(toLength: 44, withPad: " ", startingAt: 0)) "
          + "\(det) rkbx=\(String(format: "%6.1f", r.rekordboxBpm)) "
          + "daw=\(String(format: "%6.1f", r.dawBpm))  "
          + "\(r.vsRkbx.padding(toLength: 4, withPad: " ", startingAt: 0)) "
          + "\(r.vsDaw.padding(toLength: 4, withPad: " ", startingAt: 0)) "
          + "\(errStr)")
    }

    // Summary
    let analyzed = results.count
    let rkbxCorrect = results.filter { $0.vsRkbx == "OK" }.count
    let dawCorrect = results.filter { $0.vsDaw == "OK" }.count
    let disagreeCount = dawOracle.filter { $0.rekordboxDisagrees }.count
    let weMatchDaw = results.filter { r in
      guard let oracle = oracleByFilename.first(where: {
        r.name.hasPrefix(String($0.key.prefix(42)))
      })?.value else { return false }
      return oracle.rekordboxDisagrees && r.vsDaw == "OK"
    }.count
    let weMatchRkbx = results.filter { r in
      guard let oracle = oracleByFilename.first(where: {
        r.name.hasPrefix(String($0.key.prefix(42)))
      })?.value else { return false }
      return oracle.rekordboxDisagrees && r.vsRkbx == "OK"
    }.count

    print()
    print("  Acc1 vs Rekordbox: \(String(format: "%.1f", Double(rkbxCorrect) / Double(analyzed) * 100))% (\(rkbxCorrect)/\(analyzed))")
    print("  Acc1 vs DAW:       \(String(format: "%.1f", Double(dawCorrect) / Double(analyzed) * 100))% (\(dawCorrect)/\(analyzed))")
    print("  Rekordbox disagrees with DAW: \(disagreeCount) tracks")
    print("    We match DAW: \(weMatchDaw)/\(disagreeCount)")
    print("    We match Rekordbox: \(weMatchRkbx)/\(disagreeCount)")

    // Error category breakdown
    let octaveVsRkbx = results.filter { $0.errorVsRkbx == .octave }.count
    let tripletVsRkbx = results.filter { $0.errorVsRkbx == .triplet }.count
    let otherVsRkbx = results.filter { $0.errorVsRkbx == .other }.count
    let octaveVsDaw = results.filter { $0.errorVsDaw == .octave }.count
    let tripletVsDaw = results.filter { $0.errorVsDaw == .triplet }.count
    let otherVsDaw = results.filter { $0.errorVsDaw == .other }.count

    print()
    print("  Error categories vs Rekordbox: octave=\(octaveVsRkbx), triplet=\(tripletVsRkbx), other=\(otherVsRkbx)")
    print("  Error categories vs DAW:       octave=\(octaveVsDaw), triplet=\(tripletVsDaw), other=\(otherVsDaw)")
  }

  // MARK: - Full Corpus with DAW Annotations

  @Test("full corpus with DAW oracle annotations")
  func fullCorpusWithDAWAnnotation() async throws {
    let availableTracks = groundTruth.filter { track in
      let url = trackURL(track.filename, subdir: track.subdir)
      return FileManager.default.fileExists(atPath: url.path)
    }

    // Run all tracks in parallel via structured concurrency
    let urls = availableTracks.map { trackURL($0.filename, subdir: $0.subdir) }
    let trackBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask { (index, (try? AudioAnalysisService.analyzeBPM(url: url))?.bpm) }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    var acc1 = 0
    var acc2 = 0
    var failuresWithOracle: [(track: String, expected: Double, got: Double, dawBpm: Double, errType: String)] = []
    var failuresWithoutOracle: [(track: String, expected: Double, got: Double)] = []

    for (index, track) in availableTracks.enumerated() {
      guard let detected = trackBPMs[index] else {
        failuresWithoutOracle.append((track.title, track.bpm, 0))
        continue
      }

      if isAcc1Match(detected, track.bpm) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2Match(detected, track.bpm) {
        acc2 += 1
        if let oracle = oracleByFilename[track.filename] {
          let errType = classifyError(detected, track.bpm)?.rawValue ?? "unknown"
          failuresWithOracle.append((track.title, track.bpm, detected, oracle.dawBpm, errType))
        } else {
          failuresWithoutOracle.append((track.title, track.bpm, detected))
        }
      } else {
        if let oracle = oracleByFilename[track.filename] {
          let errType = classifyError(detected, track.bpm)?.rawValue ?? "unknown"
          failuresWithOracle.append((track.title, track.bpm, detected, oracle.dawBpm, errType))
        } else {
          failuresWithoutOracle.append((track.title, track.bpm, detected))
        }
      }
    }

    let total = availableTracks.count
    print("\n=== Full Corpus with DAW Oracle Annotations ===")
    print("  Corpus: \(total) tracks")
    print("  Acc1: \(String(format: "%.1f", Double(acc1) / Double(total) * 100))% (\(acc1)/\(total))")
    print("  Acc2: \(String(format: "%.1f", Double(acc2) / Double(total) * 100))% (\(acc2)/\(total))")
    print("  DAW oracle coverage: \(dawOracle.count)/\(total) tracks verified")

    if !failuresWithOracle.isEmpty {
      print("\n  Failures WITH DAW oracle data:")
      for f in failuresWithOracle {
        let dawMatch = isAcc1Match(f.got, f.dawBpm) ? "matches DAW" : "misses DAW too"
        print(
          "    \(f.track.prefix(40)): expected=\(String(format: "%.1f", f.expected)), "
            + "got=\(String(format: "%.1f", f.got)), daw=\(String(format: "%.1f", f.dawBpm)) "
            + "[\(f.errType)] \(dawMatch)")
      }
    }

    if !failuresWithoutOracle.isEmpty {
      print("\n  Failures WITHOUT DAW oracle data (\(failuresWithoutOracle.count) tracks):")
      for f in failuresWithoutOracle {
        let delta = f.got > 0 ? String(format: "%.1f%%", abs(f.got - f.expected) / f.expected * 100) : "N/A"
        print("    \(f.track.prefix(40)): expected=\(String(format: "%.1f", f.expected)), got=\(String(format: "%.1f", f.got)) [\(delta)]")
      }
    }
  }
}

private enum DAWOracleError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
  case oracleNotFound
}
