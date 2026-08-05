//
//  TempoRangeImpactTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 12.1 AC #8 / NFR-14 — the per-track impact report for the
//  consumer-specifiable tempo bounds (FR-53). Schema follows the
//  `make click-impact-report` precedent — `{changedRanking,
//  changedDisambiguationWinner, changedFinalBPM, total}` — extended with the
//  per-band and per-genre breakdown FR-55 asks for.
//
//  What is measured: the FULL `AudioAnalysisService.analyzeBPM` pipeline (multi-window
//  aggregation, merge, metadata corroboration) at default options, against the same
//  pipeline with only `Options.perceptualWindow` moved. Deliberately NOT the
//  single-window `BPMAnalyzer` shortcut the click-impact report used: the window is a
//  CONSUMER lever, so it is measured through the surface a consumer actually calls,
//  and the Acc1/Acc2 columns are directly comparable to the corpus floors.
//
//  The report changes no default. The shipped `perceptualWindow` stays `60...200`; the
//  comparison window is a measurement instrument, overridable with
//  `TEMPO_RANGE_IMPACT_WINDOW="<min>,<max>"`.
//
//  Gated by `TEMPO_RANGE_IMPACT=1` plus `OA300_CORPUS_PATH`. Run via
//  `make tempo-range-impact-report`.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Row types

/// One track measured under both windows.
private struct ImpactRow: Sendable {
  let genre: String
  let trueBPM: Double
  let baselineTopCandidateBPM: Double?
  let comparisonTopCandidateBPM: Double?
  let baselineDisambiguationBPM: Double?
  let comparisonDisambiguationBPM: Double?
  let baselineBPM: Double?
  let comparisonBPM: Double?
  let baselineAcc1: Bool
  let comparisonAcc1: Bool
  let baselineAcc2: Bool
  let comparisonAcc2: Bool

  var changedRanking: Bool { baselineTopCandidateBPM != comparisonTopCandidateBPM }
  var changedDisambiguationWinner: Bool {
    baselineDisambiguationBPM != comparisonDisambiguationBPM
  }
  var changedFinalBPM: Bool { baselineBPM != comparisonBPM }
}

/// Aggregate over an arbitrary slice of rows (whole corpus, one BPM band, one genre).
private struct ImpactTally: Sendable {
  var total = 0
  var changedRanking = 0
  var changedDisambiguationWinner = 0
  var changedFinalBPM = 0
  var baselineAcc1 = 0
  var comparisonAcc1 = 0
  var baselineAcc2 = 0
  var comparisonAcc2 = 0

  init(_ rows: [ImpactRow]) {
    for row in rows {
      total += 1
      if row.changedRanking { changedRanking += 1 }
      if row.changedDisambiguationWinner { changedDisambiguationWinner += 1 }
      if row.changedFinalBPM { changedFinalBPM += 1 }
      if row.baselineAcc1 { baselineAcc1 += 1 }
      if row.comparisonAcc1 { comparisonAcc1 += 1 }
      if row.baselineAcc2 { baselineAcc2 += 1 }
      if row.comparisonAcc2 { comparisonAcc2 += 1 }
    }
  }

  var json: [String: Any] {
    [
      "total": total,
      "changedRanking": changedRanking,
      "changedDisambiguationWinner": changedDisambiguationWinner,
      "changedFinalBPM": changedFinalBPM,
      "baselineAcc1": baselineAcc1,
      "comparisonAcc1": comparisonAcc1,
      "baselineAcc2": baselineAcc2,
      "comparisonAcc2": comparisonAcc2,
      "deltaAcc1": comparisonAcc1 - baselineAcc1,
      "deltaAcc2": comparisonAcc2 - baselineAcc2,
    ]
  }
}

/// Ground-truth BPM bands. Closed at the top by an open-ended final band so every
/// track lands in exactly one, and no track is silently dropped from the breakdown.
private struct BPMBand: Sendable {
  let label: String
  let lowerBound: Double
  let upperBound: Double

  static let all: [BPMBand] = [
    BPMBand(label: "<80", lowerBound: 0, upperBound: 80),
    BPMBand(label: "80-119", lowerBound: 80, upperBound: 120),
    BPMBand(label: "120-159", lowerBound: 120, upperBound: 160),
    BPMBand(label: "160-199", lowerBound: 160, upperBound: 200),
    BPMBand(label: ">=200", lowerBound: 200, upperBound: .infinity),
  ]

  func contains(_ bpm: Double) -> Bool { bpm >= lowerBound && bpm < upperBound }
}

/// Why a track produced no `ImpactRow`.
///
/// The two cases are not interchangeable and must not be pooled into one "failed"
/// bucket. A track the BASELINE could not analyze is corpus noise (unreadable file,
/// unsupported codec, silence). A track the baseline analyzed but the COMPARISON
/// window annihilated is the story's most interesting signal: it is the moved window
/// folding a tempo outside the scan range, exactly the cross-interaction documented on
/// `PerceptualTempoWindow`. Reporting them together would hide it.
private enum ImpactOutcome: Sendable {
  case measured(ImpactRow)
  case baselineFailed
  case comparisonOnlyFailed
}

/// How much of the corpus the report actually covered, and where the rest went.
///
/// A bundled carrier rather than five loose parameters: the fields are only
/// interpretable together, and `analyzed + baselineFailed + comparisonOnlyFailed`
/// must reconcile to `resolvedOnDisk` for the report to be trustworthy.
private struct ImpactCoverage: Sendable {
  let groundTruthEntries: Int
  let resolvedOnDisk: Int
  let analyzed: Int
  let baselineFailed: Int
  let comparisonOnlyFailed: Int

  var missingFromDisk: Int { groundTruthEntries - resolvedOnDisk }

  init(groundTruthEntries: Int, resolvedOnDisk: Int, outcomes: [ImpactOutcome]) {
    self.groundTruthEntries = groundTruthEntries
    self.resolvedOnDisk = resolvedOnDisk
    var analyzed = 0
    var baselineFailed = 0
    var comparisonOnlyFailed = 0
    for outcome in outcomes {
      switch outcome {
      case .measured: analyzed += 1
      case .baselineFailed: baselineFailed += 1
      case .comparisonOnlyFailed: comparisonOnlyFailed += 1
      }
    }
    self.analyzed = analyzed
    self.baselineFailed = baselineFailed
    self.comparisonOnlyFailed = comparisonOnlyFailed
  }

  var json: [String: Any] {
    [
      "groundTruthEntries": groundTruthEntries,
      "resolvedOnDisk": resolvedOnDisk,
      "missingFromDisk": missingFromDisk,
      "analyzed": analyzed,
      // Split deliberately. `baselineFailed` is corpus noise; `comparisonOnlyFailed`
      // is the moved window folding a tempo outside the (unchanged) scan range and
      // the final range guard rejecting it — the story's own documented
      // cross-interaction, and the number a consumer evaluating this lever most
      // needs to see. Pooling them would hide it.
      "baselineFailed": baselineFailed,
      "comparisonOnlyFailed": comparisonOnlyFailed,
      "failed": baselineFailed + comparisonOnlyFailed,
    ]
  }
}

private enum TempoRangeImpactError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}

// MARK: - Suite

/// `.enabled(if:)` at the SUITE level, matching `BNNSImpactTests`: the init throws when
/// `OA300_CORPUS_PATH` is unset, so without the trait an ordinary `make test` on a
/// machine with no corpus would ERROR the suite rather than skip it.
@Suite(
  "Story 12.1 — tempo-range impact report (OA300)",
  .enabled(if: ProcessInfo.processInfo.environment["TEMPO_RANGE_IMPACT"] == "1")
)
struct TempoRangeImpactTests {

  /// MIREX Acc1 tolerance, matching every corpus benchmark in this target.
  private static let tolerance = 0.02

  private static let maxSeconds = 120.0

  /// The window the report compares against the shipped default.
  ///
  /// `100...200` is the drum-and-bass framing from the story's own user story — "stop
  /// reporting 70 for my 140 BPM tracks" — and OA300 is DnB-heavy, so it is the
  /// setting a real consumer of this corpus would reach for. Override with
  /// `TEMPO_RANGE_IMPACT_WINDOW="<min>,<max>"`.
  private static var comparisonWindow: PerceptualTempoWindow {
    guard let raw = ProcessInfo.processInfo.environment["TEMPO_RANGE_IMPACT_WINDOW"],
      !raw.isEmpty
    else { return PerceptualTempoWindow(minBPM: 100, maxBPM: 200) }
    let parts = raw.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
    guard parts.count == 2, let low = parts[0], let high = parts[1] else {
      print(
        "TEMPO_RANGE_IMPACT_WINDOW=\(raw) is malformed (expected \"<min>,<max>\"); "
          + "using the default comparison window.")
      return PerceptualTempoWindow(minBPM: 100, maxBPM: 200)
    }
    return PerceptualTempoWindow(minBPM: low, maxBPM: high)
  }

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else { throw TempoRangeImpactError.corpusPathNotSet }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw TempoRangeImpactError.groundTruthNotFound }
    groundTruth = try OA300Track.loadCorpus(from: Data(contentsOf: url))
  }

  @Test("per-track tempo-range impact", .timeLimit(.minutes(60)))
  func tempoRangeImpactReport() async throws {
    guard ProcessInfo.processInfo.environment["TEMPO_RANGE_IMPACT"] == "1" else { return }

    let window = Self.comparisonWindow
    let tracks: [(track: OA300Track, url: URL)] = groundTruth.compactMap { track in
      let url = Self.trackURL(track, corpusPath: corpusPath)
      return FileManager.default.fileExists(atPath: url.path) ? (track, url) : nil
    }

    print("\n=== Story 12.1 AC #8 — tempo-range impact report (OA300) ===")
    print("Baseline window:   60.0...200.0 (shipped default)")
    print("Comparison window: \(window.minBPM)...\(window.maxBPM)")
    print("Metric: full AudioAnalysisService.analyzeBPM, MIREX Acc1/Acc2 at 2% tolerance")

    let outcomes = await Self.measure(tracks: tracks, window: window)
    let rows = outcomes.compactMap { outcome -> ImpactRow? in
      if case .measured(let row) = outcome { return row }
      return nil
    }
    let coverage = ImpactCoverage(
      groundTruthEntries: groundTruth.count, resolvedOnDisk: tracks.count,
      outcomes: outcomes)

    #expect(
      !rows.isEmpty,
      "Tempo-range impact report analyzed zero tracks; check OA300_CORPUS_PATH (\(corpusPath)).")

    let overall = ImpactTally(rows)
    Self.printSummary(overall: overall, rows: rows, coverage: coverage)

    var payload: [String: Any] = overall.json
    payload["total"] = groundTruth.count
    for (key, value) in coverage.json { payload[key] = value }
    payload["baselineWindow"] = ["minBPM": 60.0, "maxBPM": 200.0]
    payload["comparisonWindow"] = ["minBPM": window.minBPM, "maxBPM": window.maxBPM]
    payload["metric"] =
      "full AudioAnalysisService.analyzeBPM at default Options with only "
      + "perceptualWindow moved; MIREX Acc1/Acc2 at 2% tolerance; "
      + "maxSeconds=\(Int(Self.maxSeconds))"
    payload["perBand"] = BPMBand.all.map { band in
      var entry = ImpactTally(rows.filter { band.contains($0.trueBPM) }).json
      entry["band"] = band.label
      return entry
    }
    payload["perGenre"] = Set(rows.map(\.genre)).sorted().map { genre in
      var entry = ImpactTally(rows.filter { $0.genre == genre }).json
      entry["genre"] = genre
      return entry
    }

    guard let dir = ProcessInfo.processInfo.environment["TEMPO_RANGE_IMPACT_OUT_DIR"] else {
      return
    }
    let url = URL(fileURLWithPath: dir)
      .appendingPathComponent("12-1-tempo-range-impact-report.json")
    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
    print("\nImpact report written to \(url.path)")
  }

  // MARK: - Runner

  private static func measure(
    tracks: [(track: OA300Track, url: URL)], window: PerceptualTempoWindow
  ) async -> [ImpactOutcome] {
    let parallelism = resolvedParallelism()
    return await AblationMatrixTests.batchedTaskGroup(
      items: tracks, parallelism: parallelism
    ) { entry -> ImpactOutcome in
      // Trace is enabled on BOTH runs so the disambiguation column is populated
      // symmetrically; enabling it does not change the winner.
      var baselineOptions = AudioAnalysisService.Options()
      baselineOptions.maxSeconds = maxSeconds
      baselineOptions.enableTrace = true

      var comparisonOptions = baselineOptions
      comparisonOptions.perceptualWindow = window

      // Split, not pooled: a baseline failure is corpus noise, a comparison-only
      // failure is the moved window annihilating a track the default handled.
      guard
        let baseline = try? AudioAnalysisService.analyzeBPM(
          url: entry.url, options: baselineOptions)
      else { return .baselineFailed }
      guard
        let comparison = try? AudioAnalysisService.analyzeBPM(
          url: entry.url, options: comparisonOptions)
      else { return .comparisonOnlyFailed }

      let truth = entry.track.bpm
      let baselineAcc1 = isAcc1Match(baseline.bpm, truth, tolerance: tolerance)
      let comparisonAcc1 = isAcc1Match(comparison.bpm, truth, tolerance: tolerance)
      return .measured(
        ImpactRow(
          genre: entry.track.genre,
          trueBPM: truth,
          baselineTopCandidateBPM: baseline.candidates.first?.bpm,
          comparisonTopCandidateBPM: comparison.candidates.first?.bpm,
          baselineDisambiguationBPM: baseline.trace?.disambiguationResult.bpm,
          comparisonDisambiguationBPM: comparison.trace?.disambiguationResult.bpm,
          baselineBPM: baseline.bpm,
          comparisonBPM: comparison.bpm,
          baselineAcc1: baselineAcc1,
          comparisonAcc1: comparisonAcc1,
          baselineAcc2: baselineAcc1 || isAcc2Match(baseline.bpm, truth, tolerance: tolerance),
          comparisonAcc2: comparisonAcc1
            || isAcc2Match(comparison.bpm, truth, tolerance: tolerance)))
    }
  }

  // MARK: - Reporting

  private static func printSummary(
    overall: ImpactTally, rows: [ImpactRow], coverage: ImpactCoverage
  ) {
    print("")
    print("Total tracks (ground truth):  \(coverage.groundTruthEntries)")
    print("Resolved on disk:             \(coverage.resolvedOnDisk)")
    print("Missing from disk:            \(coverage.missingFromDisk)")
    print("Tracks analyzed:              \(coverage.analyzed)")
    print("Baseline failed (corpus):     \(coverage.baselineFailed)")
    print(
      "Comparison-only failed:       \(coverage.comparisonOnlyFailed)"
        + "  <== annihilated by the moved window")
    print("changedRanking:               \(overall.changedRanking)")
    print("changedDisambiguationWinner:  \(overall.changedDisambiguationWinner)")
    print("changedFinalBPM:              \(overall.changedFinalBPM)")
    print(
      "Acc1: \(overall.baselineAcc1) -> \(overall.comparisonAcc1) "
        + "(\(signed(overall.comparisonAcc1 - overall.baselineAcc1)))")
    print(
      "Acc2: \(overall.baselineAcc2) -> \(overall.comparisonAcc2) "
        + "(\(signed(overall.comparisonAcc2 - overall.baselineAcc2)))")

    printBreakdown(
      title: "Per ground-truth BPM band",
      heading: "band",
      groups: BPMBand.all.map { band in
        (band.label, ImpactTally(rows.filter { band.contains($0.trueBPM) }))
      }
    )
    printBreakdown(
      title: "Per genre",
      heading: "genre",
      groups: Set(rows.map(\.genre)).sorted().map {
        genre in (genre, ImpactTally(rows.filter { $0.genre == genre }))
      })
  }

  private static func printBreakdown(
    title: String, heading: String, groups: [(String, ImpactTally)]
  ) {
    print("")
    print("\(title):")
    print(pad(heading) + "  total  changedFinal   Acc1        Acc2")
    print(String(repeating: "-", count: 72))
    for (label, tally) in groups where tally.total > 0 {
      print(
        pad(label)
          + String(format: "  %5d", tally.total)
          + String(format: "  %11d", tally.changedFinalBPM)
          + "   \(tally.baselineAcc1)->\(tally.comparisonAcc1) "
          + "(\(signed(tally.comparisonAcc1 - tally.baselineAcc1)))"
          + "   \(tally.baselineAcc2)->\(tally.comparisonAcc2) "
          + "(\(signed(tally.comparisonAcc2 - tally.baselineAcc2)))")
    }
  }

  private static func signed(_ value: Int) -> String { String(format: "%+d", value) }

  /// Left-pads a label to a fixed column width. `String(format: "%-22@", ...)` does
  /// not reliably honour the width for `%@`, which left the printed table ragged.
  private static func pad(_ label: String, to width: Int = 22) -> String {
    label.count >= width
      ? label : label + String(repeating: " ", count: width - label.count)
  }

  // MARK: - Helpers

  private static func trackURL(_ track: OA300Track, corpusPath: String) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }

  /// Mirrors `AblationMatrixTests.resolvedParallelism` (which is `private` there).
  private static func resolvedParallelism() -> Int {
    let defaultCap = min(ProcessInfo.processInfo.activeProcessorCount, 32)
    guard let raw = ProcessInfo.processInfo.environment["ABLATION_PARALLELISM"] else {
      return defaultCap
    }
    if let parsed = Int(raw), (1...128).contains(parsed) { return parsed }
    print(
      "ABLATION_PARALLELISM=\(raw) is malformed (expected integer in [1, 128]); "
        + "using default \(defaultCap).")
    return defaultCap
  }
}
