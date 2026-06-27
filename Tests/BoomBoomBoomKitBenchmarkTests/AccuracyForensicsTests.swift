//
//  AccuracyForensicsTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Phase 0 forensic accuracy harness (reporting-only, env-gated on
//  ACCURACY_FORENSICS=1). Runs the DEFAULT analyzeBPM pipeline over OA300 and/or
//  GiantSteps, attributes every result (candidate-recall oracle, error-type, recall
//  split, confidence reliability, BPM-error distribution, per-genre composition,
//  label-policy), and writes a per-corpus forensic JSON to ACCURACY_FORENSICS_OUT_DIR.
//  It touches NO DSP — the corpus floors are unaffected. Skipped by `make test`.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("Accuracy Forensics")
struct AccuracyForensicsTests {

  private static var enabled: Bool {
    ProcessInfo.processInfo.environment["ACCURACY_FORENSICS"] != nil
  }

  @Test(
    "OA300 + GiantSteps forensic attribution report",
    .enabled(if: AccuracyForensicsTests.enabled))
  func forensicReport() async throws {
    let env = ProcessInfo.processInfo.environment
    let outDir = env["ACCURACY_FORENSICS_OUT_DIR"]
    var produced = 0

    if let oa300 = env["OA300_CORPUS_PATH"], !oa300.isEmpty {
      let report = try await runOA300(corpusPath: oa300)
      try emit(report, outDir: outDir)
      printSummary(report)
      produced += 1
    }

    if let giantsteps = env["GIANTSTEPS_CORPUS_PATH"], !giantsteps.isEmpty {
      let report = try await runGiantSteps(corpusPath: giantsteps)
      try emit(report, outDir: outDir)
      printSummary(report)
      produced += 1
    }

    try #require(
      produced > 0,
      "Set OA300_CORPUS_PATH and/or GIANTSTEPS_CORPUS_PATH to produce a forensic report")
  }

  // MARK: - Corpus runners

  private func runOA300(corpusPath: String) async throws -> ForensicCorpusReport {
    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    let data = try Data(contentsOf: try #require(jsonURL))
    let tracks = try OA300Track.loadCorpus(from: data)

    let inputs = await analyze(tracks) { track in
      let base = URL(fileURLWithPath: corpusPath)
      let url = track.subdir.map { base.appendingPathComponent($0) } ?? base
      return (
        url: url.appendingPathComponent(track.filename),
        id: track.title, genre: track.genre, expected: track.bpm, alternate: nil
      )
    }
    return AccuracyForensics.buildReport(corpus: "oa300", tracks: inputs)
  }

  private func runGiantSteps(corpusPath: String) async throws -> ForensicCorpusReport {
    let jsonPath = (corpusPath as NSString).appendingPathComponent(
      "giantsteps-tempo-ground-truth.json")
    let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
    let tracks = try JSONDecoder().decode([GiantStepsTrack].self, from: data)

    let inputs = await analyze(tracks) { track in
      let url = URL(fileURLWithPath: corpusPath)
        .appendingPathComponent("audio")
        .appendingPathComponent(track.filename)
      return (
        url: url, id: track.track_id, genre: track.genre, expected: track.bpm,
        alternate: track.tempo2
      )
    }
    return AccuracyForensics.buildReport(corpus: "giantsteps", tracks: inputs)
  }

  // MARK: - Shared analysis (parallel, default pipeline)

  /// Maps each track to a `ForensicInput` by running the DEFAULT `analyzeBPM` over its
  /// resolved URL. Ground truth here is crowdsourced (Rekordbox / crowdsourced tags),
  /// not Bitwig-metronomic, so `isMetronomicTruth: false`.
  private func analyze<Track: Sendable>(
    _ tracks: [Track],
    locate:
      @escaping @Sendable (Track) -> (
        url: URL, id: String, genre: String, expected: Double, alternate: Double?
      )
  ) async -> [ForensicInput] {
    // Skip tracks whose audio is missing on disk (mirrors the canonical OA300/GiantSteps
    // runners) so a partial corpus is SKIPPED, not counted as nil-result failures —
    // keeping totals comparable to the benchmark floors. Make the skip visible.
    let located = tracks.map { locate($0) }
    let present = located.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    let missing = located.count - present.count
    if missing > 0 {
      let ids = located.filter { !FileManager.default.fileExists(atPath: $0.url.path) }
        .prefix(5).map(\.id)
      print("  skipped \(missing) track(s) with missing audio (first: \(ids))")
    }

    return await withTaskGroup(of: ForensicInput.self) { group in
      for loc in present {
        group.addTask {
          let result = try? AudioAnalysisService.analyzeBPM(url: loc.url, options: .init())
          return ForensicInput(
            id: loc.id, genre: loc.genre, expectedBPM: loc.expected, alternateBPM: loc.alternate,
            detectedBPM: result?.bpm, confidence: result?.confidence,
            candidates: result?.candidates ?? [], isMetronomicTruth: false)
        }
      }
      var out: [ForensicInput] = []
      for await input in group { out.append(input) }
      return out
    }
  }

  // MARK: - Emit + print

  private func emit(_ report: ForensicCorpusReport, outDir: String?) throws {
    guard let outDir else { return }
    let url = URL(fileURLWithPath: outDir)
      .appendingPathComponent("accuracy-forensics-\(report.corpus).json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(report).write(to: url)
    print("  wrote \(url.path)")
  }

  private func printSummary(_ r: ForensicCorpusReport) {
    print("\n=== Accuracy Forensics — \(r.corpus) ===")
    print(
      "  total=\(r.total) analyzed=\(r.analyzed) nil=\(r.nilCount)  Acc1=\(r.acc1) Acc2=\(r.acc2)")
    print("  error types: \(r.errorTypeHistogram.sorted { $0.value > $1.value })")
    print(
      "  recall split — miss/true-in-top5=\(r.recallSplit.missTrueInTop5)  "
        + "miss/true-absent=\(r.recallSplit.missTrueAbsent)  "
        + "miss/true-at-rank1=\(r.recallSplit.missTrueAtRank1)")
    print(
      "  MAE raw: median=\(fmt(r.maeRawBPM.median)) p95=\(fmt(r.maeRawBPM.p95))  "
        + "octave-norm: median=\(fmt(r.maeOctaveNormBPM.median)) p95=\(fmt(r.maeOctaveNormBPM.p95))"
    )
    for bin in r.confidenceReliability where bin.count > 0 {
      print(
        "  conf [\(fmt(bin.lower)),\(fmt(bin.upper))): Acc1=\(fmt(bin.acc1Percent))% (\(bin.acc1)/\(bin.count))"
      )
    }
    print("  label policy: \(r.labelPolicyHistogram.sorted { $0.value > $1.value })")
  }

  private func fmt(_ v: Double) -> String { String(format: "%.2f", v) }
}
