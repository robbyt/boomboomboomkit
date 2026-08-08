//
//  OctaveThresholdSweepTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 12.1 Task 1 / AC #1 — the inherited Epic-13 charter-item-1 ceiling sweep over
//  the two hand-tuned `resolveOctaveAmbiguity` thresholds (`BPMAnalyzer.swift`
//  `octaveEnergyThreshold = 0.3`, `octaveScoreThreshold = 0.5`). The covenant Epic 12
//  inherited says: do not pre-commit a DSP-path change before this sweep runs. This
//  suite is that sweep — it MEASURES the ceiling, it does not move the defaults.
//
//  Scope: the sweep drives `BPMAnalyzer.estimateBPM` directly (the ablation-harness
//  precedent), NOT `AudioAnalysisService.analyzeBPM`. That is deliberate: the two
//  thresholds are injectable only on the INTERNAL `BPMAnalyzer.Options`, because
//  Story 12.1 Tasks 2-3 own the public `AudioAnalysisService.Options` surface and a
//  sweep instrument must not pre-empt it. The consequence is that the numbers here are
//  single-window DSP-spine numbers (Acc1 ceiling ~55/82 on OA300 per the story's Dev
//  Notes), NOT the 58/82 the full multi-window + merge + metadata-corroboration
//  pipeline reaches. Read the sweep as "what does step 10 leave on the table", not as
//  a corpus-floor measurement.
//
//  Scoring uses the SHARED MIREX matchers (`isAcc1Match` / `isAcc2Match`, 5-factor Acc2
//  at 2% tolerance) rather than the ablation-local 2-factor variant, so a delta here is
//  read in the same units as the OA300 / GiantSteps corpus floors.
//
//  Decode strategy: each track is decoded ONCE and all grid points are evaluated against
//  the same `[Float]`. The grid is 49 points; re-decoding per point (the ablation
//  harness's shape) would cost 49x the file I/O for zero information.
//
//  Gated by `OCTAVE_THRESHOLD_SWEEP=1` plus `OA300_CORPUS_PATH`. Run via
//  `make octave-threshold-sweep`.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Grid

/// One point of the two-dimensional threshold grid.
private struct ThresholdPoint: Sendable, Hashable {
  let energy: Float
  let score: Float

  var label: String {
    String(format: "e=%.1f s=%.1f", Double(energy), Double(score))
  }

  var isDefault: Bool {
    energy == BPMAnalyzer.octaveEnergyThreshold && score == BPMAnalyzer.octaveScoreThreshold
  }
}

/// Accumulated Acc1/Acc2 counts for one grid point.
private struct SweepTally: Sendable {
  var acc1 = 0
  var acc2 = 0
  var total = 0
}

/// Which key of the shared report JSON a pass owns. Named explicitly so the writer
/// does not have to infer the corpus from the presence of an unused parameter.
private enum SweepCorpus: String, Sendable {
  case oa300
  case giantSteps = "giantsteps"
}

/// A full pass: the per-grid-point rows plus the corpus coverage that produced them.
///
/// Coverage is part of the result, not a print-time afterthought, because a row's
/// `total` is only interpretable against the number of tracks that were supposed to
/// be scored.
private struct SweepResult: Sendable {
  let rows: [SweepRow]
  /// Ground-truth entries whose audio file was found on disk.
  let resolvedOnDisk: Int
  /// Resolved tracks that produced a full hit vector and were scored.
  let analyzed: Int
  /// Resolved tracks whose decode failed; scored by nothing, counted here.
  let failed: Int
}

// MARK: - Suite

/// `.serialized` because both tests are full-corpus and both touch the same report JSON:
/// the OA300 grid writes it, the GiantSteps pass reads the winner back out of it and then
/// merges its own rows in. `make octave-threshold-sweep` additionally invokes the two
/// tests as separate `swift test` runs so the ordering is explicit rather than implied.
///
/// `.enabled(if:)` at the SUITE level, matching `BNNSImpactTests`: the init throws when
/// `OA300_CORPUS_PATH` is unset, so without the trait an ordinary `make test` on a
/// machine with no corpus would ERROR the suite rather than skip it.
@Suite(
  "Story 12.1 — resolveOctaveAmbiguity threshold ceiling sweep",
  .serialized,
  .enabled(if: ProcessInfo.processInfo.environment["OCTAVE_THRESHOLD_SWEEP"] == "1")
)
struct OctaveThresholdSweepTests {

  /// Strict tolerance, matching the OA300 / GiantSteps floor tests.
  private static let tolerance = 0.02

  /// Seconds of audio per track, matching every other corpus benchmark in this target.
  private static let maxSeconds = 120.0

  /// The default 7x7 grid. The `0.1...0.6` x `0.3...0.8` core brackets the shipped
  /// `(0.3, 0.5)` on both axes, and both shipped values are grid members, so the default
  /// operating point is measured by the same code path as every alternative.
  ///
  /// The trailing `1.0` on each axis is load-bearing and was added after the first run:
  /// no point in the `0.1...0.6` x `0.3...0.8` core beat the default (every point came
  /// back at or below `Acc1 = 55`), so a sweep confined to it would have reported "the
  /// default is at the ceiling" while never testing the one setting that changes the
  /// branch's behaviour — turning it off. `energy = 1.0` demands the faster candidate
  /// carry at least as much fused-periodicity energy as the slower one, and
  /// `score = 1.0` demands it beat the incumbent best outright; either one effectively
  /// closes the 2:1 fallback. A widened `{0, 0.3, 1, 2, 5, 100}` probe confirmed nothing
  /// beyond `1.0` moves further, so `1.0` is the plateau edge, not an arbitrary cap.
  ///
  /// The `1.0` row and column are also where the sweep found its result: all 13 grid
  /// points that close the fallback score OA300 `Acc1 = 56` against the default's `55`,
  /// and GiantSteps moves the same direction and further (528 -> 532). See
  /// `confirmationPoint()` for what that does and does not license.
  ///
  /// Overridable with `OCTAVE_SWEEP_ENERGY_GRID` / `OCTAVE_SWEEP_SCORE_GRID`
  /// (comma-separated floats) so a follow-up probe can rewiden the axes without a code
  /// change. A malformed override falls back to the default axis and logs the value.
  private static let defaultEnergyGrid: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 1.0]
  private static let defaultScoreGrid: [Float] = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1.0]

  private static var grid: [ThresholdPoint] {
    let energies = axis("OCTAVE_SWEEP_ENERGY_GRID", fallback: defaultEnergyGrid)
    let scores = axis("OCTAVE_SWEEP_SCORE_GRID", fallback: defaultScoreGrid)
    return energies.flatMap { energy in scores.map { ThresholdPoint(energy: energy, score: $0) } }
  }

  private static func axis(_ name: String, fallback: [Float]) -> [Float] {
    guard let raw = ProcessInfo.processInfo.environment[name], !raw.isEmpty else {
      return fallback
    }
    let parsed = raw.split(separator: ",").compactMap {
      Float($0.trimmingCharacters(in: .whitespaces))
    }
    guard parsed.count == raw.split(separator: ",").count, !parsed.isEmpty else {
      print(
        "\(name)=\(raw) is malformed (expected comma-separated floats); using the default axis.")
      return fallback
    }
    return parsed
  }

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else {
      throw OctaveSweepError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw OctaveSweepError.groundTruthNotFound }
    groundTruth = try OA300Track.loadCorpus(from: Data(contentsOf: url))
  }

  // MARK: - OA300 grid sweep

  @Test("OA300 threshold grid sweep", .timeLimit(.minutes(60)))
  func oa300ThresholdSweep() async throws {
    guard ProcessInfo.processInfo.environment["OCTAVE_THRESHOLD_SWEEP"] == "1" else { return }

    let grid = Self.grid
    let parallelism = Self.resolvedParallelism()
    print("\n=== Story 12.1 AC #1 — resolveOctaveAmbiguity ceiling sweep (OA300) ===")
    print("Grid points: \(grid.count)  parallelism: \(parallelism)")
    print("Metric: single-window BPMAnalyzer.estimateBPM, MIREX Acc1/Acc2 at 2% tolerance")

    let tracks: [(track: OA300Track, url: URL)] = groundTruth.compactMap { track in
      let url = Self.trackURL(track, corpusPath: corpusPath)
      return FileManager.default.fileExists(atPath: url.path) ? (track, url) : nil
    }

    // One decode per track; every grid point scored against the same samples.
    let result = await Self.sweepOA300(
      tracks: tracks, grid: grid, parallelism: parallelism)

    #expect(
      result.rows.first?.total ?? 0 > 0,
      "Octave threshold sweep analyzed zero tracks; check OA300_CORPUS_PATH (\(corpusPath)).")

    Self.printCoverage(
      corpus: "OA300", groundTruthCount: groundTruth.count, result: result)
    Self.printTable(rows: result.rows, corpus: "OA300")
    try Self.writeReport(corpus: .oa300, result: result, groundTruthCount: groundTruth.count)
  }

  // MARK: - GiantSteps confirmation pass

  /// Single confirmation pass on a second corpus at exactly two settings: the shipped
  /// default `(0.3, 0.5)` and the best-performing OA300 point read back from the sweep
  /// JSON (override with `OCTAVE_SWEEP_CONFIRM="<energy>,<score>"`). This is the guard
  /// against declaring an OA300 overfit the winner; it is NOT a second grid sweep.
  @Test("GiantSteps confirmation at default and best-OA300 thresholds", .timeLimit(.minutes(60)))
  func giantStepsConfirmation() async throws {
    guard ProcessInfo.processInfo.environment["OCTAVE_THRESHOLD_SWEEP"] == "1",
      let path = ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"], !path.isEmpty
    else { return }

    let jsonPath = (path as NSString).appendingPathComponent("giantsteps-tempo-ground-truth.json")
    guard FileManager.default.fileExists(atPath: jsonPath) else {
      print("GiantSteps ground truth not found at \(jsonPath); skipping confirmation pass.")
      return
    }
    let gt = try GiantStepsTrack.loadVersionedCorpus(
      from: Data(contentsOf: URL(fileURLWithPath: jsonPath))
    ).tracks

    let defaultPoint = ThresholdPoint(
      energy: BPMAnalyzer.octaveEnergyThreshold, score: BPMAnalyzer.octaveScoreThreshold)
    guard let bestPoint = Self.confirmationPoint() else {
      print(
        "No confirmation point available (set OCTAVE_SWEEP_CONFIRM=\"<energy>,<score>\" or run "
          + "the OA300 sweep first so the report JSON exists); skipping confirmation pass.")
      return
    }

    let points = bestPoint == defaultPoint ? [defaultPoint] : [defaultPoint, bestPoint]
    let parallelism = Self.resolvedParallelism()
    let tracks: [(track: GiantStepsTrack, url: URL)] = gt.compactMap { track in
      let url = URL(fileURLWithPath: path)
        .appendingPathComponent("audio")
        .appendingPathComponent(track.filename)
      return FileManager.default.fileExists(atPath: url.path) ? (track, url) : nil
    }

    print("\n=== Story 12.1 AC #1 — GiantSteps confirmation pass ===")
    print("Points: \(points.map(\.label).joined(separator: "  |  "))")

    let result = await Self.sweepGiantSteps(
      tracks: tracks, grid: points, parallelism: parallelism)

    #expect(
      result.rows.first?.total ?? 0 > 0,
      "GiantSteps confirmation analyzed zero tracks; check GIANTSTEPS_CORPUS_PATH (\(path)).")

    Self.printCoverage(corpus: "GiantSteps", groundTruthCount: gt.count, result: result)
    Self.printTable(rows: result.rows, corpus: "GiantSteps")
    try Self.writeReport(corpus: .giantSteps, result: result, groundTruthCount: gt.count)
  }

  // MARK: - Corpus runners

  private static func sweepOA300(
    tracks: [(track: OA300Track, url: URL)],
    grid: [ThresholdPoint],
    parallelism: Int
  ) async -> SweepResult {
    let perTrack = await AblationMatrixTests.batchedTaskGroup(
      items: tracks, parallelism: parallelism
    ) { entry -> [Hit] in
      guard
        let (samples, sampleRate) = try? PCMBufferReader.readMonoSamples(
          from: entry.url, maxSeconds: maxSeconds)
      else { return [] }
      return grid.map { point in
        let bpm = BPMAnalyzer.estimateBPM(
          decoded: .synthetic(samples, sampleRate: sampleRate),
          options: optionsFor(point))?.bpm
        guard let bpm else { return Hit(acc1: false, acc2: false) }
        let acc1 = isAcc1Match(bpm, entry.track.bpm, tolerance: tolerance)
        return Hit(
          acc1: acc1, acc2: acc1 || isAcc2Match(bpm, entry.track.bpm, tolerance: tolerance))
      }
    }
    return tally(perTrack: perTrack, grid: grid, requested: tracks.count)
  }

  private static func sweepGiantSteps(
    tracks: [(track: GiantStepsTrack, url: URL)],
    grid: [ThresholdPoint],
    parallelism: Int
  ) async -> SweepResult {
    let perTrack = await AblationMatrixTests.batchedTaskGroup(
      items: tracks, parallelism: parallelism
    ) { entry -> [Hit] in
      guard
        let (samples, sampleRate) = try? PCMBufferReader.readMonoSamples(
          from: entry.url, maxSeconds: maxSeconds)
      else { return [] }
      return grid.map { point in
        let bpm = BPMAnalyzer.estimateBPM(
          decoded: .synthetic(samples, sampleRate: sampleRate),
          options: optionsFor(point))?.bpm
        guard let bpm else { return Hit(acc1: false, acc2: false) }
        // MIREX hit with the crowdsourced `tempo2` fallback, via the shared
        // `mirexTempoVerdict` (Story 12.3) so the units match `GiantStepsBenchmarkTests`.
        let verdict = mirexTempoVerdict(
          detected: bpm, primary: entry.track.bpm, alternate: entry.track.tempo2,
          tolerance: tolerance)
        return Hit(acc1: verdict.floorAcc1, acc2: verdict.floorAcc2)
      }
    }
    return tally(perTrack: perTrack, grid: grid, requested: tracks.count)
  }

  /// Default `BPMAnalyzer.Options` with only the two swept thresholds moved. Every other
  /// field stays at its shipped default, so the grid isolates step 10.
  private static func optionsFor(_ point: ThresholdPoint) -> BPMAnalyzer.Options {
    var options = BPMAnalyzer.Options()
    options.octaveEnergyThreshold = point.energy
    options.octaveScoreThreshold = point.score
    return options
  }

  /// Folds per-track hit vectors into per-grid-point tallies.
  ///
  /// A track whose decode failed contributes an EMPTY hit vector, which cannot be
  /// scored and is skipped. The count of those skips is returned rather than
  /// swallowed: the project forbids silent caps, and the first version of this report
  /// wrote `total: 661` against a 664-track GiantSteps corpus with nothing anywhere
  /// recording where the other three went.
  private static func tally(
    perTrack: [[Hit]], grid: [ThresholdPoint], requested: Int
  ) -> SweepResult {
    var tallies = [SweepTally](repeating: SweepTally(), count: grid.count)
    var failed = 0
    for hits in perTrack {
      guard hits.count == grid.count else {
        failed += 1
        continue
      }
      for (index, hit) in hits.enumerated() {
        tallies[index].total += 1
        if hit.acc1 { tallies[index].acc1 += 1 }
        if hit.acc2 { tallies[index].acc2 += 1 }
      }
    }
    let rows = zip(grid, tallies).map {
      SweepRow(point: $0, acc1: $1.acc1, acc2: $1.acc2, total: $1.total)
    }
    return SweepResult(
      rows: rows, resolvedOnDisk: requested, analyzed: requested - failed, failed: failed)
  }

  /// Prints the corpus-coverage line every benchmark in this target owes the reader:
  /// how many tracks the ground truth names, how many resolved on disk, how many were
  /// actually scored, and how many failed to decode.
  private static func printCoverage(
    corpus: String, groundTruthCount: Int, result: SweepResult
  ) {
    print("")
    print("\(corpus) coverage:")
    print("  ground truth entries:   \(groundTruthCount)")
    print("  resolved on disk:       \(result.resolvedOnDisk)")
    print("  analyzed:               \(result.analyzed)")
    print("  failed to decode:       \(result.failed)")
    print("  missing from disk:      \(groundTruthCount - result.resolvedOnDisk)")
  }

  // MARK: - Reporting

  private static func printTable(rows: [SweepRow], corpus: String) {
    let defaultRow = rows.first { $0.point.isDefault }
    print("")
    print(
      "energy  score   Acc1        Acc2       total  dAcc1  dAcc2   (\(corpus), vs default 0.3/0.5)"
    )
    print(String(repeating: "-", count: 82))
    for row in rows.sorted(by: { ($0.acc1, $0.acc2) > ($1.acc1, $1.acc2) }) {
      let acc1Pct = String(format: "%5.1f%%", Double(row.acc1) / Double(max(row.total, 1)) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(row.acc2) / Double(max(row.total, 1)) * 100)
      let d1 = defaultRow.map { row.acc1 - $0.acc1 }
      let d2 = defaultRow.map { row.acc2 - $0.acc2 }
      let marker = row.point.isDefault ? "  <== shipped default" : ""
      print(
        String(format: "%6.1f  %5.1f", Double(row.point.energy), Double(row.point.score))
          + "  \(acc1Pct) \(String(format: "%3d", row.acc1))"
          + "  \(acc2Pct) \(String(format: "%3d", row.acc2))"
          + "  \(String(format: "%5d", row.total))"
          + "  \(String(format: "%+5d", d1 ?? 0))  \(String(format: "%+5d", d2 ?? 0))\(marker)")
    }
    if let best = rows.max(by: { ($0.acc1, $0.acc2) < ($1.acc1, $1.acc2) }), let defaultRow {
      let tied = rows.filter { $0.acc1 == best.acc1 && $0.acc2 == best.acc2 }
      print("")
      print(
        "Best score on the grid: Acc1=\(best.acc1)  Acc2=\(best.acc2)  "
          + "(\(tied.count) of \(rows.count) grid point(s) tie there)")
      print(
        "Shipped default: \(defaultRow.point.label)  Acc1=\(defaultRow.acc1)  "
          + "Acc2=\(defaultRow.acc2)  (ceiling headroom: "
          + "\(best.acc1 - defaultRow.acc1) Acc1 track(s), \(best.acc2 - defaultRow.acc2) Acc2)")
    }
  }

  /// Writes `12-1-octave-threshold-sweep.json` under `OCTAVE_SWEEP_OUT_DIR`.
  ///
  /// The two passes write DIFFERENT keys of the same file, so the corpus is named
  /// explicitly rather than inferred from whether an unused second parameter happened
  /// to be non-nil (which it never was — the caller passed the same rows twice).
  ///
  /// The read-modify-write is unavoidable: `make octave-threshold-sweep` runs the two
  /// passes as separate `swift test` processes, so the second cannot see the first's
  /// in-memory payload. The WRITE is made atomic (`.atomic` = write-to-temp then
  /// rename) so a crash mid-write cannot leave a truncated file that the next pass
  /// then fails to parse and silently starts over from empty, dropping the other
  /// corpus's key.
  private static func writeReport(
    corpus: SweepCorpus, result: SweepResult, groundTruthCount: Int
  ) throws {
    guard let dir = ProcessInfo.processInfo.environment["OCTAVE_SWEEP_OUT_DIR"] else { return }
    let url = URL(fileURLWithPath: dir).appendingPathComponent("12-1-octave-threshold-sweep.json")

    var payload: [String: Any] = [:]
    if let existing = try? Data(contentsOf: url),
      let decoded = try? JSONSerialization.jsonObject(with: existing) as? [String: Any]
    {
      payload = decoded
    }

    payload[corpus.rawValue] = result.rows.map(\.json)
    payload["\(corpus.rawValue)Coverage"] = [
      "groundTruthEntries": groundTruthCount,
      "resolvedOnDisk": result.resolvedOnDisk,
      "analyzed": result.analyzed,
      "failed": result.failed,
      "missingFromDisk": groundTruthCount - result.resolvedOnDisk,
    ]
    payload["defaultEnergyThreshold"] = SweepRow.rounded(BPMAnalyzer.octaveEnergyThreshold)
    payload["defaultScoreThreshold"] = SweepRow.rounded(BPMAnalyzer.octaveScoreThreshold)
    payload["metric"] =
      "single-window BPMAnalyzer.estimateBPM; MIREX Acc1/Acc2 at 2% tolerance; "
      + "maxSeconds=\(Int(maxSeconds))"

    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
    print("\nSweep report written to \(url.path) (key: \(corpus.rawValue))")
  }

  /// The point the GiantSteps pass compares against the default. `OCTAVE_SWEEP_CONFIRM`
  /// wins when set; otherwise the best NON-DEFAULT OA300 row is read back from the
  /// report JSON.
  ///
  /// The grid is not flat and the result is not a tie. Every one of the 13 grid points
  /// that closes the 2:1 fused-energy fallback (`energy >= 1.0` or `score >= 1.0`)
  /// scores OA300 `Acc1 = 56` against the shipped default's `55`, and the GiantSteps
  /// confirmation moves the same direction and further: `528 -> 532` Acc1, `537 -> 541`
  /// Acc2. That is a consistent single-window gain on both corpora, not noise cancelling
  /// out. What is flat is the INTERIOR: no point that leaves the branch active beats the
  /// default, so there is no better tuning of the two thresholds — only closing the
  /// branch moves the number.
  ///
  /// No threshold change is committed here anyway, and that is not a hedge about the
  /// measurement. Closing a pipeline branch is a materially different change from
  /// retuning two constants: every figure above is single-window `BPMAnalyzer`, the
  /// branch may behave differently under multi-window merge and metadata corroboration,
  /// and the `AccuracyFloorTests` fixture impact has not been reviewed. It needs its own
  /// story with full-pipeline measurement. Filed as an Epic 12 finding.
  ///
  /// Two deliberate tie-break rules for picking the confirmation point, because 13 grid
  /// points share the top score and a naive `max` would have made an arbitrary member of
  /// that plateau look like the unique winner:
  /// 1. The default row is excluded from candidacy. The confirmation pass exists to test
  ///    the best ALTERNATIVE on a second corpus, not to rubber-stamp the incumbent
  ///    against itself.
  /// 2. Among equally-scoring alternatives, the largest `(energy, score)` wins — the far
  ///    edge of the tied plateau, i.e. the point most divergent from the shipped default
  ///    that OA300 nonetheless rates as equal. That is the setting most likely to expose
  ///    an OA300 overfit on a second corpus.
  private static func confirmationPoint() -> ThresholdPoint? {
    if let raw = ProcessInfo.processInfo.environment["OCTAVE_SWEEP_CONFIRM"] {
      let parts = raw.split(separator: ",").map { Float($0.trimmingCharacters(in: .whitespaces)) }
      if parts.count == 2, let energy = parts[0], let score = parts[1] {
        return ThresholdPoint(energy: energy, score: score)
      }
      print("OCTAVE_SWEEP_CONFIRM=\(raw) is malformed (expected \"<energy>,<score>\").")
    }
    guard let dir = ProcessInfo.processInfo.environment["OCTAVE_SWEEP_OUT_DIR"],
      let data = try? Data(
        contentsOf: URL(fileURLWithPath: dir)
          .appendingPathComponent("12-1-octave-threshold-sweep.json")),
      let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let oa300 = payload["oa300"] as? [[String: Any]]
    else { return nil }

    let candidates: [(point: ThresholdPoint, acc1: Int, acc2: Int)] = oa300.compactMap { row in
      guard let energy = row["energyThreshold"] as? Double,
        let score = row["scoreThreshold"] as? Double
      else { return nil }
      let point = ThresholdPoint(energy: Float(energy), score: Float(score))
      guard !point.isDefault else { return nil }
      return (point, row["acc1"] as? Int ?? 0, row["acc2"] as? Int ?? 0)
    }
    let best = candidates.max {
      ($0.acc1, $0.acc2, $0.point.energy, $0.point.score)
        < ($1.acc1, $1.acc2, $1.point.energy, $1.point.score)
    }
    return best?.point
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

  /// Mirrors `AblationMatrixTests.resolvedParallelism` (which is `private` there):
  /// `min(activeProcessorCount, 32)`, overridable via `ABLATION_PARALLELISM` in `[1, 128]`.
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

// MARK: - Row types

private struct Hit: Sendable {
  let acc1: Bool
  let acc2: Bool
}

private struct SweepRow: Sendable {
  let point: ThresholdPoint
  let acc1: Int
  let acc2: Int
  let total: Int

  static func rounded(_ value: Float) -> Double {
    (Double(value) * 1_000_000).rounded() / 1_000_000
  }

  var json: [String: Any] {
    [
      // Rounded on the way out: `Double(Float(0.3))` widens to 0.30000001192092896, which
      // makes the artifact unreadable for a value the reader knows is 0.3. The round-trip
      // back through `Float` in `confirmationPoint()` is exact either way.
      "energyThreshold": Self.rounded(point.energy),
      "scoreThreshold": Self.rounded(point.score),
      "acc1": acc1,
      "acc2": acc2,
      "total": total,
    ]
  }
}

private enum OctaveSweepError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
