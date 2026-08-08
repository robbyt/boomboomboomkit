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
import CryptoKit
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
    guard let parsed = parseBounds(raw, variable: "TEMPO_RANGE_IMPACT_WINDOW") else {
      return PerceptualTempoWindow(minBPM: 100, maxBPM: 200)
    }
    return PerceptualTempoWindow(minBPM: parsed.min, maxBPM: parsed.max)
  }

  /// Optional SCAN-range override for the comparison arm.
  ///
  /// Story 12.1 only ever moved `perceptualWindow`, which is the octave FOLD. The scan
  /// range is a different knob: it sizes candidate GENERATION. `nil` (the default) leaves
  /// the comparison arm's scan range at the shipped `40...250`, so every pre-existing
  /// invocation of this report reproduces byte-for-byte. Set
  /// `TEMPO_RANGE_IMPACT_SCAN="<min>,<max>"` to move it.
  private static var comparisonScanRange: TempoScanRange? {
    guard let raw = ProcessInfo.processInfo.environment["TEMPO_RANGE_IMPACT_SCAN"], !raw.isEmpty
    else { return nil }
    guard let parsed = parseBounds(raw, variable: "TEMPO_RANGE_IMPACT_SCAN") else { return nil }
    return TempoScanRange(minBPM: parsed.min, maxBPM: parsed.max)
  }

  /// Shared `"<min>,<max>"` parser. Returns `nil` and prints on malformed input so a
  /// typo degrades to the documented default rather than silently measuring something
  /// the operator did not ask for.
  fileprivate static func parseBounds(
    _ raw: String, variable: String
  ) -> (min: Double, max: Double)? {
    let parts = raw.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) }
    guard parts.count == 2, let low = parts[0], let high = parts[1] else {
      print("\(variable)=\(raw) is malformed (expected \"<min>,<max>\"); ignoring.")
      return nil
    }
    return (low, high)
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

    let scanRange = Self.comparisonScanRange
    if let scanRange {
      print("Comparison scan:   \(scanRange.minBPM)...\(scanRange.maxBPM) (default 40.0...250.0)")
    }

    let outcomes = await Self.measure(tracks: tracks, window: window, scanRange: scanRange)
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
    payload["baselineScanRange"] = [
      "minBPM": TempoScanRange.default.minBPM, "maxBPM": TempoScanRange.default.maxBPM,
    ]
    payload["comparisonScanRange"] =
      scanRange.map { ["minBPM": $0.minBPM, "maxBPM": $0.maxBPM] }
      ?? ["minBPM": TempoScanRange.default.minBPM, "maxBPM": TempoScanRange.default.maxBPM]
    // Which knob(s) this invocation actually moved. Without it a reader cannot tell a
    // window-only run from a window+scan run by looking at the artifact.
    payload["knobsMoved"] =
      scanRange == nil
      ? ["perceptualWindow"] : ["perceptualWindow", "tempoScanRange"]
    payload["metric"] =
      "full AudioAnalysisService.analyzeBPM at default Options with "
      + (scanRange == nil
        ? "only perceptualWindow moved" : "perceptualWindow and tempoScanRange moved")
      + "; MIREX Acc1/Acc2 at 2% tolerance; maxSeconds=\(Int(Self.maxSeconds))"
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
    tracks: [(track: OA300Track, url: URL)], window: PerceptualTempoWindow,
    scanRange: TempoScanRange?
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
      if let scanRange { comparisonOptions.tempoScanRange = scanRange }

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
      // Story 12.3: shared primary-only (octave-strict) MIREX pairing.
      let baselineVerdict = mirexTempoVerdict(
        detected: baseline.bpm, primary: truth, alternate: nil, tolerance: tolerance)
      let comparisonVerdict = mirexTempoVerdict(
        detected: comparison.bpm, primary: truth, alternate: nil, tolerance: tolerance)
      let baselineAcc1 = baselineVerdict.strictAcc1
      let comparisonAcc1 = comparisonVerdict.strictAcc1
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

// MARK: - Story 12.2 §6.2 item 1 — SMC 2015 published-prior replication

//
//  The measurement Story 12.2's decision artifact filed as untested.
//
//  Hoerschlaeger, Vogl, Boeck & Knees (SMC 2015) report genre-conditioned tempo priors
//  lifting drum-and-bass Acc1 from 7.19% to 78.42% on GiantSteps with a "DnB prior
//  130-180 BPM". Story 12.1 measured `Options.perceptualWindow` at `100...200`. That is
//  the wrong knob at the wrong values: `perceptualWindow` is the octave FOLD, and
//  `100...200` is neither bound of the published prior. Nobody has ever run
//  `Options.tempoScanRange` at `130...180`, which is candidate GENERATION and the closer
//  analogue of a search prior.
//
//  Four arms, everything else at shipped defaults:
//
//    A  baseline      shipped defaults (scan 40...250, window 60...200)
//    B  scan-only     tempoScanRange = 130...180                  [PRIMARY]
//    C  scan+window   both moved (the full "caller declares DnB" configuration)
//    D  window-only   perceptualWindow moved (12.1's knob, at published values)
//
//  STRUCTURAL RESULT, recorded before a single track was analyzed: the published prior
//  is SUB-OCTAVE (180 < 2 x 130), and `PerceptualTempoWindow` refuses to construct a
//  sub-octave window — `maxBPM` normalizes into `(2 * minBPM)...300`, so a requested
//  `130...180` becomes `130...260`. That is Story 12.1's DD3 fix working as designed
//  (`rangeNormalize` runs two sequential loops with no re-check, so a sub-octave window
//  silently returned values below its own minimum). The consequence for THIS experiment
//  is that arms C and D cannot express the published prior on the fold knob at all.
//  Only `TempoScanRange`, whose only span constraint is `minimumSpanBPM = 3`, can.
//  Every arm therefore reports BOTH its requested and its EFFECTIVE bounds, and the
//  artifact carries `normalized: true` where they differ. Reading arm C or D as "the
//  published prior on the fold window" would be wrong.
//
//  The arms run over the WHOLE corpus. DnB rows measure whether a declared range
//  recovers octave errors; non-DnB rows under the same configuration measure what a
//  blanket or mistaken declaration costs. Both are reported; neither is filtered out.
//
//  Changes no default. Gated by `SMC_PRIOR_REPLICATION=1`. Run via
//  `make smc-prior-replication`.
//

/// Corpus-agnostic track view, so one runner serves OA300 and GiantSteps.
private struct ReplicationTrack: Sendable {
  let id: String
  let genre: String
  let truthBPM: Double
  /// The corpus's SECOND annotation, where it has one. GiantSteps ground truth v2
  /// carries `tempo2` on 577 of 661 rows; 303 of those are WITHIN THE 2% SCORING
  /// TOLERANCE of half `bpm` and 58 within it of double. Under literal equality the
  /// counts are only 100 and 23 — the artifact's `tempo2Stats` block carries both, and
  /// the tolerant pair is the operative one because the shared MIREX matcher is what
  /// decides hits. `GiantStepsBenchmarkTests` counts a hit against either value, which
  /// is what the committed 537/546 floor measures. OA300 and Tony have no second
  /// annotation, so for them the two metrics coincide.
  let altTruthBPM: Double?
  let url: URL
}

/// Declares that a corpus carries a second tempo annotation, and names it.
///
/// DECLARED, never inferred. An earlier draft emitted the `tempo2Stats` block whenever
/// some track happened to carry a non-nil `altTruthBPM`, which couples the artifact's
/// schema to incidental data: a corpus that lost its second annotation would silently
/// drop the block rather than fail. The runner asserts the declaration against the data
/// in both directions — a declared source must be present on `expectedRows`, and an
/// undeclared corpus must carry none.
private struct AlternateTruthSource: Sendable {
  /// Field name in the corpus's own ground truth, for the artifact.
  let field: String
  /// Row count the declaration promises. Asserted, not recorded.
  let expectedRows: Int
}

/// Half/double census over a corpus's second annotation, under BOTH definitions.
///
/// The distinction is load-bearing and was wrong in prose for a week. Under literal
/// equality GiantSteps has 100 half and 23 double; under the 2% MIREX tolerance the
/// shared matcher actually applies, 303 and 58. The tolerant pair is operative — it is
/// what decides hits — but calling it "exactly half" states label identity where only
/// scoring equivalence holds. Both ship, so no reader has to take the word on trust.
private struct AlternateTruthCensus: Sendable {
  let field: String
  let present: Int
  let total: Int
  let literalHalf: Int
  let literalDouble: Int
  let toleranceHalf: Int
  let toleranceDouble: Int
  let tolerance: Double

  /// `literalEpsilon` is absolute; the tolerant test is relative to the primary value,
  /// matching `isAcc1Match`.
  static let literalEpsilon = 1e-6

  init(field: String, tracks: [ReplicationTrack], tolerance: Double) {
    let alts = tracks.compactMap { track in
      track.altTruthBPM.map { (primary: track.truthBPM, alt: $0) }
    }
    self.field = field
    self.total = tracks.count
    self.present = alts.count
    self.tolerance = tolerance
    self.literalHalf = alts.count { abs($0.alt * 2 - $0.primary) < Self.literalEpsilon }
    self.literalDouble = alts.count { abs($0.alt / 2 - $0.primary) < Self.literalEpsilon }
    self.toleranceHalf = alts.count { abs($0.alt * 2 - $0.primary) <= tolerance * $0.primary }
    self.toleranceDouble = alts.count { abs($0.alt / 2 - $0.primary) <= tolerance * $0.primary }
  }

  var json: [String: Any] {
    [
      "field": field,
      "present": present,
      "groundTruthRows": total,
      "literalHalf": literalHalf,
      "literalDouble": literalDouble,
      "literalEpsilon": Self.literalEpsilon,
      "toleranceHalf": toleranceHalf,
      "toleranceDouble": toleranceDouble,
      "scoringTolerance": tolerance,
      "formulas": [
        "literalHalf": "abs(alt * 2 - primary) < literalEpsilon",
        "literalDouble": "abs(alt / 2 - primary) < literalEpsilon",
        "toleranceHalf": "abs(alt * 2 - primary) <= scoringTolerance * primary",
        "toleranceDouble": "abs(alt / 2 - primary) <= scoringTolerance * primary",
      ],
      "note":
        "The tolerant pair is operative because the shared MIREX matcher decides hits at "
        + "this tolerance. It is NOT label identity: a row counted here as half may differ "
        + "from exactly half by up to the tolerance. Their sum is how many rows carry an "
        + "octave-related alternative, NOT how many the floor metric actually rescues -- "
        + "for that, compare arm A's acc1 against acc1Floor.",
    ]
  }
}

/// `gitSHA` pins the code. It says nothing about the inputs, and two of the three corpora
/// here are unpinnable by it: GiantSteps ground truth is external to this repository and
/// the Tony labels are a generated artifact that `make tony-corpus` rewrites. Recording
/// the basename and digest of every truth file makes a run reproducible rather than merely
/// attributable.
private struct InputProvenance: Sendable {
  let basename: String
  let sha256: String

  init(url: URL) throws {
    self.basename = url.lastPathComponent
    let digest = SHA256.hash(data: try Data(contentsOf: url))
    self.sha256 = digest.map { String(format: "%02x", $0) }.joined()
  }

  var json: [String: Any] { ["basename": basename, "sha256": sha256] }
}

/// One configured arm.
private struct ReplicationArm: Sendable {
  let id: String
  let label: String
  let requestedScan: (min: Double, max: Double)?
  let requestedWindow: (min: Double, max: Double)?

  var scanRange: TempoScanRange {
    requestedScan.map { TempoScanRange(minBPM: $0.min, maxBPM: $0.max) } ?? .default
  }
  var window: PerceptualTempoWindow {
    requestedWindow.map { PerceptualTempoWindow(minBPM: $0.min, maxBPM: $0.max) } ?? .default
  }

  /// True when the type's normalizing init moved a requested bound. Arms C and D trip
  /// this on the perceptual window, because the published prior is sub-octave.
  var normalized: Bool {
    if let r = requestedScan, scanRange.minBPM != r.min || scanRange.maxBPM != r.max {
      return true
    }
    if let r = requestedWindow, window.minBPM != r.min || window.maxBPM != r.max { return true }
    return false
  }

  var optionsFingerprint: [String: Any] {
    var json: [String: Any] = [
      "id": id,
      "label": label,
      "effectiveScanRange": ["minBPM": scanRange.minBPM, "maxBPM": scanRange.maxBPM],
      "effectivePerceptualWindow": ["minBPM": window.minBPM, "maxBPM": window.maxBPM],
      "normalized": normalized,
    ]
    if let r = requestedScan { json["requestedScanRange"] = ["minBPM": r.min, "maxBPM": r.max] }
    if let r = requestedWindow {
      json["requestedPerceptualWindow"] = ["minBPM": r.min, "maxBPM": r.max]
    }
    return json
  }

  static func matrix(min low: Double, max high: Double) -> [ReplicationArm] {
    [
      ReplicationArm(id: "A", label: "baseline", requestedScan: nil, requestedWindow: nil),
      ReplicationArm(
        id: "B", label: "scan-only", requestedScan: (low, high), requestedWindow: nil),
      ReplicationArm(
        id: "C", label: "scan+window", requestedScan: (low, high), requestedWindow: (low, high)),
      ReplicationArm(
        id: "D", label: "window-only", requestedScan: nil, requestedWindow: (low, high)),
    ]
  }
}

/// One track's outcome across every arm. `bpm[i] == nil` means that arm returned no
/// result: a COUNTED outcome, never dropped from a denominator.
private struct ReplicationRow: Sendable {
  let track: ReplicationTrack
  let bpm: [Double?]
  /// Octave-STRICT: scored against `truthBPM` alone.
  let acc1: [Bool]
  let acc2: [Bool]
  /// FLOOR-COMPATIBLE: scored against `truthBPM` or `altTruthBPM`, which is what the
  /// committed corpus benchmark asserts. Identical to the strict columns wherever the
  /// corpus has no second annotation.
  let acc1Floor: [Bool]
  let acc2Floor: [Bool]

  var isDnB: Bool { track.genre == "drum-and-bass" }

  /// Correctness moved in at least one configured arm relative to baseline.
  var acc1Changed: Bool { acc1.dropFirst().contains { $0 != acc1[0] } }

  /// Truth lies outside the declared prior. Hard bounds clobber these by construction;
  /// they are the soft-versus-hard evidence.
  func truthOutside(min low: Double, max high: Double) -> Bool {
    track.truthBPM < low || track.truthBPM > high
  }
}

/// Per-arm tally over one slice of rows.
private struct ReplicationTally: Sendable {
  var n = 0
  var acc1 = 0
  var acc2 = 0
  var acc1Floor = 0
  var acc2Floor = 0
  var nils = 0

  init(rows: [ReplicationRow], arm index: Int) {
    for row in rows {
      n += 1
      if row.bpm[index] == nil { nils += 1 }
      if row.acc1[index] { acc1 += 1 }
      if row.acc2[index] { acc2 += 1 }
      if row.acc1Floor[index] { acc1Floor += 1 }
      if row.acc2Floor[index] { acc2Floor += 1 }
    }
  }

  var json: [String: Any] {
    [
      "n": n,
      // Octave-strict, scored against the primary annotation alone. This is the
      // instrument for an octave experiment.
      "acc1": acc1, "acc2": acc2,
      // Floor-compatible, scored the way the committed corpus benchmark scores. Equal
      // to the strict columns wherever the corpus has no second annotation.
      "acc1Floor": acc1Floor, "acc2Floor": acc2Floor,
      "nils": nils,
    ]
  }
}

private enum ReplicationError: Error {
  case dirtyOrMissingGitSHA(String)
  case corpusPathMissing(String)
  case groundTruthNotFound(String)
}

@Suite(
  "Story 12.2 — SMC 2015 published-prior replication",
  .enabled(if: ProcessInfo.processInfo.environment["SMC_PRIOR_REPLICATION"] == "1")
)
struct SMCPriorReplicationTests {

  private static let tolerance = 0.02
  private static let maxSeconds = 120.0

  /// The published DnB prior. Override with `SMC_PRIOR_BOUNDS="<min>,<max>"`.
  private static var priorBounds: (min: Double, max: Double) {
    guard let raw = ProcessInfo.processInfo.environment["SMC_PRIOR_BOUNDS"], !raw.isEmpty,
      let parsed = TempoRangeImpactTests.parseBounds(raw, variable: "SMC_PRIOR_BOUNDS")
    else { return (130, 180) }
    return parsed
  }

  /// Fails in milliseconds, not after a full sweep. A provenance-less or dirty-tree
  /// artifact cannot be tied back to code and is worse than no artifact.
  private static func preflightGitSHA() throws -> String {
    guard let sha = ProcessInfo.processInfo.environment["GIT_SHA"], !sha.isEmpty else {
      throw ReplicationError.dirtyOrMissingGitSHA("GIT_SHA is unset")
    }
    guard !sha.contains("dirty") else {
      throw ReplicationError.dirtyOrMissingGitSHA("GIT_SHA=\(sha) reports a dirty tree")
    }
    guard sha.count >= 7, sha.allSatisfy({ $0.isHexDigit }) else {
      throw ReplicationError.dirtyOrMissingGitSHA("GIT_SHA=\(sha) is not a hex commit id")
    }
    return sha
  }

  private static func preflightCorpus(_ variable: String) throws -> String {
    guard let path = ProcessInfo.processInfo.environment[variable], !path.isEmpty else {
      throw ReplicationError.corpusPathMissing("\(variable) is unset")
    }
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue
    else { throw ReplicationError.corpusPathMissing("\(variable)=\(path) is not a directory") }
    return path
  }

  @Test("OA300 — four arms", .timeLimit(.minutes(60)))
  func oa300Replication() async throws {
    guard ProcessInfo.processInfo.environment["SMC_PRIOR_REPLICATION"] == "1" else { return }
    let sha = try Self.preflightGitSHA()
    let corpusPath = try Self.preflightCorpus("OA300_CORPUS_PATH")

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else {
      throw ReplicationError.groundTruthNotFound("oa300-ground-truth.json")
    }
    let corpus = try OA300Track.loadCorpus(from: Data(contentsOf: url))
    let tracks = corpus.map { track -> ReplicationTrack in
      var fileURL = URL(fileURLWithPath: corpusPath)
      if let subdir = track.subdir { fileURL.appendPathComponent(subdir) }
      fileURL.appendPathComponent(track.filename)
      return ReplicationTrack(
        id: track.filename, genre: track.genre, truthBPM: track.bpm, altTruthBPM: nil,
        url: fileURL)
    }
    // Committed OA300 measurement (CLAUDE.md; floors are 57/73).
    try await Self.run(
      corpus: "oa300", tracks: tracks, gitSHA: sha, floorReference: (acc1: 58, acc2: 74),
      inputs: [url])
  }

  @Test("GiantSteps — four arms", .timeLimit(.minutes(60)))
  func giantStepsReplication() async throws {
    guard ProcessInfo.processInfo.environment["SMC_PRIOR_REPLICATION"] == "1" else { return }
    let sha = try Self.preflightGitSHA()
    let corpusPath = try Self.preflightCorpus("GIANTSTEPS_CORPUS_PATH")

    let jsonPath = (corpusPath as NSString)
      .appendingPathComponent("giantsteps-tempo-ground-truth.json")
    guard FileManager.default.fileExists(atPath: jsonPath) else {
      throw ReplicationError.groundTruthNotFound(jsonPath)
    }
    let corpus = try GiantStepsTrack.loadVersionedCorpus(
      from: Data(contentsOf: URL(fileURLWithPath: jsonPath))
    ).tracks
    let tracks = corpus.map { track in
      ReplicationTrack(
        id: track.filename, genre: track.genre, truthBPM: track.bpm,
        altTruthBPM: track.tempo2,
        url: URL(fileURLWithPath: corpusPath)
          .appendingPathComponent("audio")
          .appendingPathComponent(track.filename))
    }
    // Committed GiantSteps measurement, which sits exactly on its floor.
    try await Self.run(
      corpus: "giantsteps", tracks: tracks, gitSHA: sha, floorReference: (acc1: 537, acc2: 546),
      alternateTruth: AlternateTruthSource(field: "tempo2", expectedRows: 577),
      inputs: [URL(fileURLWithPath: jsonPath)])
  }

  // MARK: - Runner

  fileprivate static func run(
    corpus: String, tracks: [ReplicationTrack], gitSHA: String,
    floorReference: (acc1: Int, acc2: Int)? = nil,
    alternateTruth: AlternateTruthSource? = nil,
    inputs: [URL] = [],
    tonyLabelStats: [String: Any]? = nil,
    nonDnbReportable: Bool = true,
    nonDnbUnreportableReason: String? = nil,
    truthCaveat: String? = nil
  ) async throws {
    // Declaration versus data, checked BOTH ways before a single track is analyzed.
    let carried = tracks.count { $0.altTruthBPM != nil }
    if let alternateTruth {
      #expect(
        carried == alternateTruth.expectedRows,
        "\(corpus) declares a `\(alternateTruth.field)` second annotation on \(alternateTruth.expectedRows) rows but the ground truth carries \(carried). The corpus changed under the experiment."
      )
    } else {
      #expect(
        carried == 0,
        "\(corpus) declares no second annotation but \(carried) rows carry one, so acc1Floor would silently diverge from acc1 with nothing in the artifact to explain it."
      )
    }
    let census = alternateTruth.map {
      AlternateTruthCensus(field: $0.field, tracks: tracks, tolerance: tolerance)
    }
    let provenance = try inputs.map { try InputProvenance(url: $0) }

    let bounds = priorBounds
    let arms = ReplicationArm.matrix(min: bounds.min, max: bounds.max)
    let onDisk = tracks.filter { FileManager.default.fileExists(atPath: $0.url.path) }
    let missingFromDisk = tracks.count - onDisk.count

    print("\n=== Story 12.2 — SMC published-prior replication (\(corpus)) ===")
    print("Requested prior: \(bounds.min)...\(bounds.max)")
    for arm in arms {
      print(
        "  \(arm.id) \(pad(arm.label, to: 13))"
          + "scan \(fmt(arm.scanRange.minBPM))...\(fmt(arm.scanRange.maxBPM))"
          + "   window \(fmt(arm.window.minBPM))...\(fmt(arm.window.maxBPM))"
          + (arm.normalized ? "   <== NORMALIZED, requested bounds not honoured" : ""))
    }
    print("Ground truth: \(tracks.count)   on disk: \(onDisk.count)   missing: \(missingFromDisk)")

    let started = Date()
    let rows = await AblationMatrixTests.batchedTaskGroup(
      items: onDisk, parallelism: resolvedParallelism()
    ) { track -> ReplicationRow in
      var bpms: [Double?] = []
      var acc1: [Bool] = []
      var acc2: [Bool] = []
      var acc1Floor: [Bool] = []
      var acc2Floor: [Bool] = []
      for arm in arms {
        var options = AudioAnalysisService.Options()
        options.maxSeconds = maxSeconds
        options.tempoScanRange = arm.scanRange
        options.perceptualWindow = arm.window
        let result = try? AudioAnalysisService.analyzeBPM(url: track.url, options: options)
        let bpm = result?.bpm
        bpms.append(bpm)
        // Story 12.3: shared strict + floor-compatible MIREX pairing. The floor
        // verdicts accept EITHER annotation, mirroring the committed GiantSteps
        // floors — without them the harness measures a stricter metric and its
        // baseline reads as a 71-track regression that does not exist.
        let verdict =
          bpm.map { detected in
            mirexTempoVerdict(
              detected: detected, primary: track.truthBPM, alternate: track.altTruthBPM,
              tolerance: tolerance)
          }
          ?? .miss
        acc1.append(verdict.strictAcc1)
        acc2.append(verdict.strictAcc2)
        acc1Floor.append(verdict.floorAcc1)
        acc2Floor.append(verdict.floorAcc2)
      }
      return ReplicationRow(
        track: track, bpm: bpms, acc1: acc1, acc2: acc2, acc1Floor: acc1Floor,
        acc2Floor: acc2Floor)
    }
    let elapsed = Date().timeIntervalSince(started)

    let dnb = rows.filter(\.isDnB)
    let nonDnb = rows.filter { !$0.isDnB }

    // Accounting identity, asserted per arm. A nil is a counted outcome; it must never
    // vanish from a denominator.
    for (index, arm) in arms.enumerated() {
      let tally = ReplicationTally(rows: rows, arm: index)
      let nonNil = tally.n - tally.nils
      #expect(
        nonNil + tally.nils + missingFromDisk == tracks.count,
        "Arm \(arm.id) accounting broken: analyzed \(nonNil) + nils \(tally.nils) + missing \(missingFromDisk) != ground truth \(tracks.count)"
      )
    }

    // Reconciliation against the committed corpus benchmark. Arm A is shipped defaults,
    // so scored the way that benchmark scores, it must reproduce its number exactly. This
    // gate exists because the first run of this harness scored octave-strict and its
    // baseline read 71 tracks below the GiantSteps floor, which is indistinguishable from
    // a real regression until someone checks. Never let that ambiguity ship again.
    if let floorReference {
      let armA = ReplicationTally(rows: rows, arm: 0)
      print(
        "\nFloor reconciliation: arm A floor-compatible "
          + "Acc1 \(armA.acc1Floor) (expect \(floorReference.acc1)), "
          + "Acc2 \(armA.acc2Floor) (expect \(floorReference.acc2))")
      #expect(
        armA.acc1Floor == floorReference.acc1 && armA.acc2Floor == floorReference.acc2,
        "Arm A does not reproduce the committed \(corpus) benchmark: got Acc1 \(armA.acc1Floor)/Acc2 \(armA.acc2Floor), expected \(floorReference.acc1)/\(floorReference.acc2). Either the harness diverges from the corpus benchmark or the default path regressed."
      )
      if armA.acc1 != armA.acc1Floor {
        print(
          "  octave-strict arm A Acc1 \(armA.acc1) is \(armA.acc1Floor - armA.acc1) below "
            + "floor-compatible; that gap is the corpus's second annotation, not a regression")
      }
    }

    printTable(arms: arms, rows: rows, dnb: dnb, nonDnb: nonDnb)
    print(String(format: "\nWall clock: %.1f s (all %d arms)", elapsed, arms.count))

    // Per-track rows for every track whose Acc1 correctness moved in any arm.
    let changed = rows.filter(\.acc1Changed).map { row -> [String: Any] in
      var json: [String: Any] = [
        "trackId": row.track.id,
        "genre": row.track.genre,
        "truthBPM": row.track.truthBPM,
        "baselineBPM": row.bpm[0] as Any,
        "acc1": Dictionary(
          uniqueKeysWithValues: zip(arms.map(\.id), row.acc1)),
      ]
      json["armBPMs"] = Dictionary(
        uniqueKeysWithValues: zip(arms.dropFirst().map(\.id), row.bpm.dropFirst().map { $0 as Any })
      )
      json["ratioClass"] = Dictionary(
        uniqueKeysWithValues: zip(
          arms.dropFirst().map(\.id),
          row.bpm.dropFirst().map { ratioClass(arm: $0, baseline: row.bpm[0]) }))
      return json
    }

    // Casualties: DnB tracks whose TRUTH lies outside the declared prior. Hard bounds
    // clobber these by construction, whether or not their correctness moved.
    let casualties = dnb.filter { $0.truthOutside(min: bounds.min, max: bounds.max) }
      .map { row -> [String: Any] in
        [
          "trackId": row.track.id,
          "genre": row.track.genre,
          "truthBPM": row.track.truthBPM,
          "armBPMs": Dictionary(
            uniqueKeysWithValues: zip(arms.map(\.id), row.bpm.map { $0 as Any })),
          "acc1": Dictionary(uniqueKeysWithValues: zip(arms.map(\.id), row.acc1)),
        ]
      }

    print("\nAcc1 changed in >=1 arm: \(changed.count) track(s)")
    print(
      "DnB casualties (truth outside \(fmt(bounds.min))...\(fmt(bounds.max))): \(casualties.count)")

    guard let dir = ProcessInfo.processInfo.environment["SMC_PRIOR_OUT_DIR"] else { return }
    let payload: [String: Any] = [
      "gitSHA": gitSHA,
      "corpus": corpus,
      "tolerance": tolerance,
      "maxSeconds": Int(maxSeconds),
      "requestedPrior": ["minBPM": bounds.min, "maxBPM": bounds.max],
      "dnbGenreLabel": "drum-and-bass",
      "metric":
        "full AudioAnalysisService.analyzeBPM at shipped defaults except the named knobs; "
        + "MIREX Acc1/Acc2 at 2% tolerance; maxSeconds=\(Int(maxSeconds))",
      "wallClockSeconds": elapsed,
      "coverage": [
        "groundTruthEntries": tracks.count,
        "resolvedOnDisk": onDisk.count,
        "missingFromDisk": missingFromDisk,
      ],
      "arms": arms.enumerated().map { index, arm -> [String: Any] in
        var json = arm.optionsFingerprint
        json["all"] = ReplicationTally(rows: rows, arm: index).json
        json["dnb"] = ReplicationTally(rows: dnb, arm: index).json
        json["nonDnb"] = ReplicationTally(rows: nonDnb, arm: index).json
        return json
      },
      "changedTracks": changed,
      "casualties": casualties,
      // A corpus whose complement is not a labelled non-DnB set says so in the artifact,
      // so its non-DnB column is never read as comparable to the other corpora.
      "metricNote":
        "acc1/acc2 are octave-STRICT, scored against the primary annotation alone. "
        + "acc1Floor/acc2Floor add the corpus's second annotation and reproduce the "
        + "committed benchmark. They differ only on GiantSteps, which carries tempo2 on "
        + "577 of 661 rows -- 303 of them WITHIN THE 2% SCORING TOLERANCE of half the "
        + "primary value, though only 100 at literal equality. See tempo2Stats.",
      "tempo2Stats": census?.json as Any,
      "inputProvenance": provenance.isEmpty ? nil as Any? as Any : provenance.map(\.json),
      "floorReference": floorReference.map { ["acc1": $0.acc1, "acc2": $0.acc2] } as Any,
      "labelProvenance": tonyLabelStats as Any,
      "nonDnbReportable": nonDnbReportable,
      "nonDnbUnreportableReason": nonDnbUnreportableReason as Any,
      "truthCaveat": truthCaveat as Any,
    ]
    let out = URL(fileURLWithPath: dir)
      .appendingPathComponent("12-2-smc-prior-replication-\(corpus).json")
    try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
      .write(to: out, options: .atomic)
    print("Artifact written to \(out.path)")
  }

  // MARK: - Reporting

  private static func printTable(
    arms: [ReplicationArm], rows: [ReplicationRow], dnb: [ReplicationRow],
    nonDnb: [ReplicationRow]
  ) {
    for (label, slice) in [("DnB", dnb), ("non-DnB", nonDnb), ("all", rows)] {
      print("\n\(label) (n=\(slice.count)):")
      print("arm  label          n     Acc1          Acc2          nils")
      print(String(repeating: "-", count: 62))
      let base = ReplicationTally(rows: slice, arm: 0)
      for (index, arm) in arms.enumerated() {
        let tally = ReplicationTally(rows: slice, arm: index)
        print(
          "\(arm.id)    " + pad(arm.label, to: 14)
            + String(format: "%4d", tally.n)
            + String(format: "   %4d", tally.acc1)
            + (index == 0 ? "        " : String(format: " (%+d)  ", tally.acc1 - base.acc1))
            + String(format: "  %4d", tally.acc2)
            + (index == 0 ? "        " : String(format: " (%+d)  ", tally.acc2 - base.acc2))
            + String(format: "  %4d", tally.nils)
            + (tally.acc1Floor == tally.acc1
              ? "" : String(format: "   [floor %d/%d]", tally.acc1Floor, tally.acc2Floor)))
      }
    }
  }

  /// Buckets `arm / baseline` into the octave and triplet relations, so the mechanism
  /// behind a changed track is attributable from the artifact alone.
  private static func ratioClass(arm: Double?, baseline: Double?) -> String {
    guard let arm, let baseline, baseline > 0 else { return "nil" }
    let ratio = arm / baseline
    for (value, name) in [(2.0, "2.0"), (0.5, "0.5"), (1.5, "1.5"), (2.0 / 3.0, "0.667")]
    where abs(ratio - value) <= 0.02 * value {
      return name
    }
    return abs(ratio - 1.0) <= 0.02 ? "1.0" : "other"
  }

  private static func fmt(_ value: Double) -> String { String(format: "%g", value) }

  private static func pad(_ label: String, to width: Int) -> String {
    label.count >= width ? label : label + String(repeating: " ", count: width - label.count)
  }

  private static func resolvedParallelism() -> Int {
    let defaultCap = min(ProcessInfo.processInfo.activeProcessorCount, 32)
    guard let raw = ProcessInfo.processInfo.environment["ABLATION_PARALLELISM"] else {
      return defaultCap
    }
    if let parsed = Int(raw), (1...128).contains(parsed) { return parsed }
    return defaultCap
  }
}

// MARK: - Tony corpus (Rekordbox) — DnB slice only

//
//  A third, independent read on the same question, added on operator prompt.
//
//  Tony's Rekordbox collection carries free-text `Genre` in the XML export, surfaced by
//  `make tony-survey` into `tony-corpus/tony-survey.json`, with `bpm_truth` alongside in
//  `tony-truth-labels.json`. Joining on `local_path` gives 1509 rows carrying truth.
//
//  MEMBERSHIP IS DERIVED FROM THE PATH, NOT THE XML `Genre` TAG. The tag is nearly
//  useless here: 1520 of 1721 survey rows carry an EMPTY genre string, and tag-matching
//  yields only 115 tracks. The collection is instead filed on disk by genre, so
//  `local_path` containing "drum and bass" identifies 901 rows, 884 of which carry
//  `bpm_truth` and resolve on disk. That is a larger DnB slice than OA300 (67) and
//  GiantSteps (139) combined, and it is the sharpest available read.
//
//  WHY THIS CORPUS IS DnB-ONLY, and must not be read as a whole-corpus arm: the
//  complement of the DnB directories is not a labelled non-DnB set. It is a mix of other
//  genre directories and unfiled material, and the empty-tag rate means it cannot be
//  partitioned reliably. Reporting a "non-DnB cost" from it would be measuring filing
//  habits, not genre, so the artifact records `nonDnbReportable: false` with the reason
//  rather than emitting a number that reads comparable to the OA300 and GiantSteps
//  non-DnB columns and is not.
//
//  SCOPE NOTE: the full collection is larger than this. `non-rekordbox-survey.json`
//  covers roughly 4,700 further files outside the Rekordbox `<COLLECTION>`, which is
//  where the rest of the DnB material lives. Those tracks are deliberately NOT used
//  here: Story 7.2 tiered them precisely because they have no Rekordbox-validated BPM,
//  and this experiment needs trustworthy truth rather than volume. 884 is the count with
//  validated truth, not the count of DnB tracks the operator owns.
//
//  CAVEAT ON THE TRUTH, carried into the artifact: `bpm_truth` snaps to the Rekordbox
//  value, which is Tony's validated truth but is itself a metrical-level CONVENTION. If
//  Rekordbox reports the fast octave for half-time material, then "truth inside
//  130...180" partly reflects the labelling convention rather than the music, which is
//  exactly the ambiguity Story 12.6 exists to settle. Casualty counts from this corpus
//  are a lower bound.
//
//  Gated by `SMC_PRIOR_REPLICATION=1` plus `TONY_AUDIO_ROOT`.
//

/// Both Tony artifacts are `{schema_version, ..., track_count, tracks: [...]}` envelopes,
/// not bare arrays. Decoding the envelope rather than the array also gives the
/// `track_count` cross-check below.
private struct TonyEnvelope<Row: Decodable>: Decodable {
  let trackCount: Int?
  let tracks: [Row]
  enum CodingKeys: String, CodingKey {
    case trackCount = "track_count"
    case tracks
  }
}

private struct TonySurveyRow: Decodable {
  let localPath: String?
  let genre: String?
  enum CodingKeys: String, CodingKey {
    case localPath = "local_path"
    case genre
  }
}

private struct TonyTruthCluster: Decodable {
  let sources: [String]?
}

private struct TonyLabelRow: Decodable {
  let truthConfidence: Double?
  let truthCluster: TonyTruthCluster?
  let localPath: String?
  let bpmTruth: Double?
  enum CodingKeys: String, CodingKey {
    case localPath = "local_path"
    case bpmTruth = "bpm_truth"
    case truthConfidence = "truth_confidence"
    case truthCluster = "truth_cluster"
  }

  /// The repo's FR-14 label tiers.
  var tier: String {
    guard let c = truthConfidence else { return "unknown" }
    if c >= 0.85 { return "strong" }
    if c >= 0.66 { return "solid" }
    return "marginal"
  }

  /// True when this library's own prepass is a member of the cluster that produced the
  /// truth centroid. The label is then not detector-independent.
  var truthUsedDSP: Bool { truthCluster?.sources?.contains("dsp") ?? false }
}

extension SMCPriorReplicationTests {

  /// DnB membership, derived from the on-disk filing rather than the XML tag. See the
  /// note above: the tag is empty on 88% of rows, the directory structure is not.
  fileprivate static func isTonyDnB(path: String, genre: String) -> Bool {
    if path.lowercased().contains("drum and bass") { return true }
    // The sparse tag is kept as a secondary signal so a correctly-tagged track filed
    // outside the DnB directories still counts.
    let tag = genre.lowercased()
    if tag == "dnb" { return true }
    return tag.contains("drum") && tag.contains("bass")
  }

  @Test("Tony Rekordbox corpus — four arms, DnB slice", .timeLimit(.minutes(60)))
  func tonyReplication() async throws {
    guard ProcessInfo.processInfo.environment["SMC_PRIOR_REPLICATION"] == "1" else { return }
    let sha = try Self.preflightGitSHA()
    _ = try Self.preflightCorpus("TONY_AUDIO_ROOT")

    let corpusDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("_bmad-output/ml-training/tony-corpus")
    let surveyURL = corpusDir.appendingPathComponent("tony-survey.json")
    let labelsURL = corpusDir.appendingPathComponent("tony-truth-labels.json")
    for url in [surveyURL, labelsURL] where !FileManager.default.fileExists(atPath: url.path) {
      throw ReplicationError.groundTruthNotFound(
        "\(url.path) (run `make tony-corpus` first)")
    }

    let decoder = JSONDecoder()
    let surveyEnvelope = try decoder.decode(
      TonyEnvelope<TonySurveyRow>.self, from: Data(contentsOf: surveyURL))
    let labelsEnvelope = try decoder.decode(
      TonyEnvelope<TonyLabelRow>.self, from: Data(contentsOf: labelsURL))
    let survey = surveyEnvelope.tracks
    let labels = labelsEnvelope.tracks

    // The envelopes carry their own counts. A mismatch means the artifact was written
    // by a different pipeline version than the one this reader assumes, which would
    // silently change the corpus under the experiment.
    if let declared = surveyEnvelope.trackCount, declared != survey.count {
      throw ReplicationError.groundTruthNotFound(
        "tony-survey.json declares track_count \(declared) but carries \(survey.count) rows")
    }
    if let declared = labelsEnvelope.trackCount, declared != labels.count {
      throw ReplicationError.groundTruthNotFound(
        "tony-truth-labels.json declares track_count \(declared) but carries \(labels.count) rows"
      )
    }

    var genreByPath: [String: String] = [:]
    for row in survey {
      guard let path = row.localPath else { continue }
      genreByPath[path] = row.genre ?? ""
    }

    // DEDUPE BY PATH. The label file carries 883 DnB rows against only 848 distinct
    // files: 35 are repeats, and counting them twice inflates the denominator and
    // double-weights whatever those tracks do. Keep first occurrence.
    var seenPaths = Set<String>()
    var duplicateRows = 0
    let minConfidence = ProcessInfo.processInfo.environment["SMC_TONY_MIN_CONFIDENCE"]
      .flatMap(Double.init)
    var tierCounts: [String: Int] = [:]
    var truthUsedDSPCount = 0

    let tracks = labels.compactMap { row -> ReplicationTrack? in
      guard let path = row.localPath, let truth = row.bpmTruth,
        Self.isTonyDnB(path: path, genre: genreByPath[path] ?? "")
      else { return nil }
      guard seenPaths.insert(path).inserted else {
        duplicateRows += 1
        return nil
      }
      if let minConfidence, (row.truthConfidence ?? 0) < minConfidence { return nil }
      tierCounts[row.tier, default: 0] += 1
      if row.truthUsedDSP { truthUsedDSPCount += 1 }
      // basename, not the absolute path: the artifact is develop-only but there is no
      // reason to bake the operator's home directory into it.
      return ReplicationTrack(
        id: (path as NSString).lastPathComponent,
        genre: "drum-and-bass",
        truthBPM: truth,
        altTruthBPM: nil,
        url: URL(fileURLWithPath: path))
    }

    print("\nTony corpus: \(survey.count) survey rows, \(labels.count) label rows")
    print(
      "DnB-labelled with truth: \(tracks.count) distinct files "
        + "(\(duplicateRows) duplicate path rows dropped)   non-DnB slice NOT reportable")
    print(
      "  label tiers: \(tierCounts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))"
    )
    print(
      "  truth cluster includes this detector's own prepass on \(truthUsedDSPCount) of "
        + "\(tracks.count) rows")
    if let minConfidence {
      print("  filtered to truth_confidence >= \(minConfidence)")
    }

    try await Self.run(
      corpus: "tony", tracks: tracks, gitSHA: sha,
      inputs: [surveyURL, labelsURL],
      tonyLabelStats: [
        "distinctFiles": tracks.count,
        "duplicatePathRowsDropped": duplicateRows,
        "tiers": tierCounts,
        "truthClusterIncludesOwnDSP": truthUsedDSPCount,
        "minConfidenceFilter": minConfidence as Any,
      ],
      nonDnbReportable: false,
      nonDnbUnreportableReason:
        "1520 of 1721 Rekordbox survey rows carry an empty genre string, so the "
        + "complement of the DnB slice is unlabelled material rather than labelled "
        + "non-DnB and would be seeded with unlabelled DnB",
      truthCaveat:
        "bpm_truth snaps to the Rekordbox value, which is a metrical-level convention; "
        + "if Rekordbox reports the fast octave for half-time material then casualty "
        + "counts from this corpus are a lower bound (see Story 12.6)")
  }
}
