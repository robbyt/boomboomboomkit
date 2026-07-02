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

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Error Classification

private enum ErrorCategory: String {
  case octave
  case triplet
  case other
}

private func classifyError(_ detected: Double, _ expected: Double) -> ErrorCategory? {
  guard expected > 0 else { return .other }
  if isAcc1Match(detected, expected, tolerance: 0.02) { return nil }
  let ratio = detected / expected
  if abs(ratio - 2.0) / 2.0 <= 0.04 || abs(ratio - 0.5) / 0.5 <= 0.04 {
    return .octave
  }
  if abs(ratio - 1.5) / 1.5 <= 0.04 || abs(ratio - 2.0 / 3.0) / (2.0 / 3.0) <= 0.04 {
    return .triplet
  }
  return .other
}

// MARK: - Test Suite

@Suite("DAW Oracle Benchmark")
struct DAWOracleBenchmarkTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]
  private let dawOracle: [DAWOracleTrack]
  private let oracleByFilename: [String: DAWOracleTrack]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else {
      throw DAWOracleError.corpusPathNotSet
    }
    corpusPath = path

    // Load Rekordbox ground truth from bundled fixture
    let gtURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = gtURL else { throw DAWOracleError.groundTruthNotFound }
    let gtData = try Data(contentsOf: url)
    groundTruth = try OA300Track.loadCorpus(from: gtData)

    // Load DAW oracle from corpus directory
    let oraclePath = (path as NSString).appendingPathComponent("daw-oracle.json")
    let oracleURL = URL(fileURLWithPath: oraclePath)
    guard FileManager.default.fileExists(atPath: oraclePath) else {
      throw DAWOracleError.oracleNotFound
    }
    let oracleData = try Data(contentsOf: oracleURL)
    dawOracle = try DAWOracleTrack.loadCorpus(from: oracleData)

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

    // Story 3-5 AC #11: explicit windowVoting + simpleMajority so the new
    // policy code path is exercised (default Options uses .maxConfidence).
    let detectedBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (i, track) in availableIndices {
        let url = trackURL(track.filename, subdir: track.subdir)
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.mergeStrategy = .windowVoting
          opts.votingPolicy = .simpleMajority
          return (i, (try? AudioAnalysisService.analyzeBPM(url: url, options: opts))?.bpm)
        }
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
        vsRkbx = isAcc1Match(d, track.rekordboxBpm, tolerance: 0.02) ? "OK" : "MISS"
        vsDaw = isAcc1Match(d, track.dawBpm, tolerance: 0.02) ? "OK" : "MISS"
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
      guard
        let oracle = oracleByFilename.first(where: {
          r.name.hasPrefix(String($0.key.prefix(42)))
        })?.value
      else { return false }
      return oracle.rekordboxDisagrees && r.vsDaw == "OK"
    }.count
    let weMatchRkbx = results.filter { r in
      guard
        let oracle = oracleByFilename.first(where: {
          r.name.hasPrefix(String($0.key.prefix(42)))
        })?.value
      else { return false }
      return oracle.rekordboxDisagrees && r.vsRkbx == "OK"
    }.count

    print()
    print(
      "  Acc1 vs Rekordbox: \(String(format: "%.1f", Double(rkbxCorrect) / Double(analyzed) * 100))% (\(rkbxCorrect)/\(analyzed))"
    )
    print(
      "  Acc1 vs DAW:       \(String(format: "%.1f", Double(dawCorrect) / Double(analyzed) * 100))% (\(dawCorrect)/\(analyzed))"
    )
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
    print(
      "  Error categories vs Rekordbox: octave=\(octaveVsRkbx), triplet=\(tripletVsRkbx), other=\(otherVsRkbx)"
    )
    print(
      "  Error categories vs DAW:       octave=\(octaveVsDaw), triplet=\(tripletVsDaw), other=\(otherVsDaw)"
    )
  }

  // MARK: - Story 8.10: continuous tempo-refinement drift-rate acceptance (AC #9)

  /// Octave-normalizes `truth` (×1 / ×2 / ×½) to whichever octave lands within 6%
  /// of `ref`; returns `nil` for a more-than-octave disagreement. Isolates the
  /// refit's sub-BPM precision from the BPM stage's octave choice.
  private func octaveNormalized(_ truth: Double, to ref: Double) -> Double? {
    guard ref > 0, truth > 0 else { return nil }
    for factor in [1.0, 2.0, 0.5] where abs(truth * factor - ref) / ref <= 0.06 {
      return truth * factor
    }
    return nil
  }

  /// Scores beat-grid tempo error and predicted last-beat drift against the
  /// DAW-verified oracle with continuous tempo refinement ON vs OFF, over
  /// `.fullTrack` coverage (the long lever arm a sub-0.1-BPM fit needs). Drift is
  /// purely a function of tempo error, so a verified BPM is sufficient truth — no
  /// hand-marked beat positions. Reuses this suite's `oracleByFilename` loader
  /// (AC #9 / DD #7), gated on `TEMPO_REFINE_IMPACT=1` so only the make target runs
  /// it; emits a per-track impact JSON to `TEMPO_REFINE_IMPACT_OUT_DIR`.
  @Test(
    "tempo-refinement impact (ON vs OFF) vs DAW oracle",
    .enabled(if: ProcessInfo.processInfo.environment["TEMPO_REFINE_IMPACT"] != nil))
  func tempoRefinementImpact() async throws {
    let available = dawOracle.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track.filename, subdir: track.subdir).path)
    }
    try #require(available.count >= 20, "Expected at least 20 DAW oracle tracks on disk")

    struct Row: Sendable {
      let filename: String
      let dawBpm: Double
      let coarseTempo: Double
      let refinedTempo: Double
      let normalizedDaw: Double?
      let coverageSeconds: Double
    }

    let rows = await withTaskGroup(of: Row?.self) { group in
      for track in available {
        let url = self.trackURL(track.filename, subdir: track.subdir)
        let dawBpm = track.dawBpm
        let filename = track.filename
        group.addTask {
          guard let decoded = try? PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 300)
          else { return nil }
          var off = AudioAnalysisService.Options()
          off.beatGridCoverage = .fullTrack
          off.maxSeconds = 300
          var on = off
          on.refineBeatGridTempo = true
          guard
            let offGrid = try? AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: off),
            let onGrid = try? AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: on),
            offGrid.estimatedTempo > 0, onGrid.estimatedTempo > 0
          else { return nil }
          let coverage = Double(decoded.samples.count) / decoded.sampleRate
          return Row(
            filename: filename, dawBpm: dawBpm,
            coarseTempo: offGrid.estimatedTempo, refinedTempo: onGrid.estimatedTempo,
            normalizedDaw: self.octaveNormalized(dawBpm, to: offGrid.estimatedTempo),
            coverageSeconds: coverage)
        }
      }
      var out: [Row] = []
      for await r in group where r != nil { out.append(r!) }
      return out
    }

    func drift(grid: Double, truth: Double, seconds: Double) -> Double {
      abs(seconds * (truth / grid - 1.0))  // last-beat drift in seconds over the coverage
    }

    var details: [TempoRefineImpactDetail] = []
    var changedTempo = 0
    var improved = 0
    var worsened = 0
    var octaveMismatch = 0
    var driftOffSum = 0.0
    var driftOnSum = 0.0
    var scored = 0

    for row in rows {
      let changed = row.refinedTempo.bitPattern != row.coarseTempo.bitPattern
      if changed { changedTempo += 1 }
      guard let daw = row.normalizedDaw else {
        octaveMismatch += 1
        details.append(
          TempoRefineImpactDetail(
            filename: row.filename, dawBpm: row.dawBpm, coarseTempo: row.coarseTempo,
            refinedTempo: row.refinedTempo, tempoErrorOff: nil, tempoErrorOn: nil,
            driftOffSeconds: nil, driftOnSeconds: nil, changedTempo: changed,
            octaveMismatch: true))
        continue
      }
      let errOff = abs(row.coarseTempo - daw)
      let errOn = abs(row.refinedTempo - daw)
      let dOff = drift(grid: row.coarseTempo, truth: daw, seconds: row.coverageSeconds)
      let dOn = drift(grid: row.refinedTempo, truth: daw, seconds: row.coverageSeconds)
      if errOn < errOff - 1e-9 { improved += 1 }
      if errOn > errOff + 1e-9 { worsened += 1 }
      driftOffSum += dOff
      driftOnSum += dOn
      scored += 1
      details.append(
        TempoRefineImpactDetail(
          filename: row.filename, dawBpm: row.dawBpm, coarseTempo: row.coarseTempo,
          refinedTempo: row.refinedTempo, tempoErrorOff: errOff, tempoErrorOn: errOn,
          driftOffSeconds: dOff, driftOnSeconds: dOn, changedTempo: changed, octaveMismatch: false))
    }

    let meanDriftOff = scored > 0 ? driftOffSum / Double(scored) : 0
    let meanDriftOn = scored > 0 ? driftOnSum / Double(scored) : 0
    let report = TempoRefineImpactReport(
      total: rows.count, scored: scored, changedTempo: changedTempo,
      improvedTempoError: improved, worsenedTempoError: worsened, octaveMismatch: octaveMismatch,
      meanDriftOffSeconds: meanDriftOff, meanDriftOnSeconds: meanDriftOn, details: details)

    print("\n=== Story 8.10 tempo-refinement impact (ON vs OFF) vs DAW oracle ===")
    print("  total=\(rows.count) scored=\(scored) octaveMismatch=\(octaveMismatch)")
    print("  changedTempo=\(changedTempo)")
    print("  improvedTempoError=\(improved)  worsenedTempoError=\(worsened)")
    print(
      "  mean predicted last-beat drift: OFF=\(String(format: "%.3f", meanDriftOff))s  "
        + "ON=\(String(format: "%.3f", meanDriftOn))s")

    if let outDir = ProcessInfo.processInfo.environment["TEMPO_REFINE_IMPACT_OUT_DIR"] {
      let url = URL(fileURLWithPath: outDir).appendingPathComponent("8-10-tempo-refine-impact.json")
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      try encoder.encode(report).write(to: url)
      print("  wrote \(url.path)")
    }

    // Fail loudly rather than green-light on no data: a present-but-empty corpus,
    // universal decode failure, or all-octave-mismatch rows would otherwise leave
    // improved == worsened == 0 and meanDrift == 0, passing the monotonic gate
    // vacuously. Require real scored rows — NOT a `changedTempo` floor: the refit is
    // deliberately conservative and may legitimately abstain corpus-wide, so the
    // committed floor is the monotonic property, not a fire-rate count (Completion
    // Notes). The impact JSON is written above first, so a zero-data run still leaves
    // a diagnostic artifact before this halts.
    try #require(scored > 0, "No DAW-oracle tracks scored — the impact gate cannot run")

    // Monotonic guarantee (the reject-guard): refinement never makes the corpus
    // worse on net — improvements outnumber regressions, and mean drift does not
    // increase. The exact lift floor is recorded in Completion Notes after this
    // first measured run.
    #expect(improved >= worsened)
    #expect(meanDriftOn <= meanDriftOff + 1e-9)
  }

  // MARK: - Full Corpus with DAW Annotations

  @Test("full corpus with DAW oracle annotations")
  func fullCorpusWithDAWAnnotation() async throws {
    let availableTracks = groundTruth.filter { track in
      let url = trackURL(track.filename, subdir: track.subdir)
      return FileManager.default.fileExists(atPath: url.path)
    }

    // Story 3-5 AC #11: explicit windowVoting + simpleMajority so the new
    // policy code path is exercised (default Options uses .maxConfidence).
    let urls = availableTracks.map { trackURL($0.filename, subdir: $0.subdir) }
    let trackBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.mergeStrategy = .windowVoting
          opts.votingPolicy = .simpleMajority
          return (index, (try? AudioAnalysisService.analyzeBPM(url: url, options: opts))?.bpm)
        }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    var acc1 = 0
    var acc2 = 0
    var failuresWithOracle:
      [(track: String, expected: Double, got: Double, dawBpm: Double, errType: String)] = []
    var failuresWithoutOracle: [(track: String, expected: Double, got: Double)] = []

    for (index, track) in availableTracks.enumerated() {
      guard let detected = trackBPMs[index] else {
        failuresWithoutOracle.append((track.title, track.bpm, 0))
        continue
      }

      if isAcc1Match(detected, track.bpm, tolerance: 0.02) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2Match(detected, track.bpm, tolerance: 0.02) {
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
    print(
      "  Acc1: \(String(format: "%.1f", Double(acc1) / Double(total) * 100))% (\(acc1)/\(total))")
    print(
      "  Acc2: \(String(format: "%.1f", Double(acc2) / Double(total) * 100))% (\(acc2)/\(total))")
    print("  DAW oracle coverage: \(dawOracle.count)/\(total) tracks verified")

    if !failuresWithOracle.isEmpty {
      print("\n  Failures WITH DAW oracle data:")
      for f in failuresWithOracle {
        let dawMatch =
          isAcc1Match(f.got, f.dawBpm, tolerance: 0.02) ? "matches DAW" : "misses DAW too"
        print(
          "    \(f.track.prefix(40)): expected=\(String(format: "%.1f", f.expected)), "
            + "got=\(String(format: "%.1f", f.got)), daw=\(String(format: "%.1f", f.dawBpm)) "
            + "[\(f.errType)] \(dawMatch)")
      }
    }

    if !failuresWithoutOracle.isEmpty {
      print("\n  Failures WITHOUT DAW oracle data (\(failuresWithoutOracle.count) tracks):")
      for f in failuresWithoutOracle {
        let delta =
          f.got > 0 ? String(format: "%.1f%%", abs(f.got - f.expected) / f.expected * 100) : "N/A"
        print(
          "    \(f.track.prefix(40)): expected=\(String(format: "%.1f", f.expected)), got=\(String(format: "%.1f", f.got)) [\(delta)]"
        )
      }
    }
  }
}

private enum DAWOracleError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
  case oracleNotFound
}

// MARK: - Story 8.10 impact-report schema

private struct TempoRefineImpactDetail: Codable {
  let filename: String
  let dawBpm: Double
  let coarseTempo: Double
  let refinedTempo: Double
  let tempoErrorOff: Double?
  let tempoErrorOn: Double?
  let driftOffSeconds: Double?
  let driftOnSeconds: Double?
  let changedTempo: Bool
  let octaveMismatch: Bool
}

private struct TempoRefineImpactReport: Codable {
  let total: Int
  let scored: Int
  let changedTempo: Int
  let improvedTempoError: Int
  let worsenedTempoError: Int
  let octaveMismatch: Int
  let meanDriftOffSeconds: Double
  let meanDriftOnSeconds: Double
  let details: [TempoRefineImpactDetail]
}
