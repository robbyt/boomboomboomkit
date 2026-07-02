//
//  PerformanceBenchmarkTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Wall-clock analysis-time benchmark with hardware context and accuracy snapshots.
//  Env-gated on OA300_CORPUS_PATH. Accuracy section also runs GiantSteps if
//  GIANTSTEPS_CORPUS_PATH is set; soft-fails to null otherwise.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

// MARK: - Hardware Context

private struct HardwareInfo: Sendable {
  let chip: String
  let cores: Int
  let physicalMemoryBytes: UInt64
  let osVersion: String
  let buildConfiguration: String
  let swiftPackageVersion: String

  static func current() -> HardwareInfo {
    HardwareInfo(
      chip: Self.resolveChip(),
      cores: ProcessInfo.processInfo.processorCount,
      physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
      buildConfiguration: Self.resolveBuildConfiguration(),
      swiftPackageVersion: "BoomBoomBoomKit (workspace HEAD)"
    )
  }

  private static func resolveChip() -> String {
    var size: size_t = 0
    guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 else {
      return "unknown"
    }
    var buffer = [UInt8](repeating: 0, count: size)
    guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else {
      return "unknown"
    }
    // Strip the trailing NUL byte before UTF-8 decoding.
    if buffer.last == 0 { buffer.removeLast() }
    return String(bytes: buffer, encoding: .utf8) ?? "unknown"
  }

  private static func resolveBuildConfiguration() -> String {
    #if DEBUG
      return "Debug"
    #else
      return "Release"
    #endif
  }

  var physicalMemoryGiB: Int {
    Int(physicalMemoryBytes / (1024 * 1024 * 1024))
  }

  func formatted() -> String {
    """
    Chip: \(chip)
    Cores: \(cores)
    Memory: \(physicalMemoryGiB) GiB
    OS: \(osVersion)
    Build configuration: \(buildConfiguration)
    Swift package version: \(swiftPackageVersion)
    """
  }
}

// MARK: - Baseline Record (schemaVersion 2)

private struct BaselineRecord: Codable, Sendable {
  let schemaVersion: Int
  let recordedAt: String
  let gitSHA: String
  let buildConfiguration: String
  let swiftPackageVersion: String
  let hardware: Hardware
  let wallClock: WallClock
  let accuracy: Accuracy

  struct Hardware: Codable, Sendable {
    let chip: String
    let cores: Int
    let physicalMemoryGiB: Int
    let osVersion: String
  }

  struct WallClock: Codable, Sendable {
    let corpus: String
    let intensity: Int
    let trackCount: Int
    let warmupExcluded: Int
    let failedCount: Int
    let meanSeconds: Double
    let medianSeconds: Double
    let p95Seconds: Double
    let minSeconds: Double
    let maxSeconds: Double
    let totalSeconds: Double
  }

  struct Accuracy: Codable, Sendable {
    let oa300: AccuracySnapshot
    let giantsteps: AccuracySnapshot?
  }

  struct AccuracySnapshot: Codable, Sendable {
    let total: Int
    let acc1Correct: Int
    let acc2Correct: Int
    let tolerance: Double
  }
}

// MARK: - Baseline Store

private enum BaselineStore {
  private static let baselineFilenameSeparator = "--"

  static func fingerprintPrefix(chip: String, osMajor: Int) -> String {
    var sanitized = String(
      chip.map { c -> Character in
        if c.isLetter || c.isNumber || c == "-" || c == "_" {
          return c
        }
        return "_"
      })
    while sanitized.contains("__") {
      sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
    }
    sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    return "\(sanitized)-\(osMajor)"
  }

  static func buildRecordFilename(
    fingerprint: String,
    buildConfiguration: String,
    recordedAt: String,
    gitSHA: String
  ) -> String {
    let shortUUID = String(UUID().uuidString.lowercased().prefix(8))
    let s = baselineFilenameSeparator
    return
      "\(fingerprint)\(s)\(buildConfiguration)\(s)\(recordedAt)\(s)\(gitSHA)\(s)\(shortUUID).json"
  }

  static func write(_ record: BaselineRecord, fingerprint: String, to dir: URL) throws {
    let compactRecordedAt = record.recordedAt
      .replacingOccurrences(of: "-", with: "")
      .replacingOccurrences(of: ":", with: "")
    let filename = buildRecordFilename(
      fingerprint: fingerprint,
      buildConfiguration: record.buildConfiguration,
      recordedAt: compactRecordedAt,
      gitSHA: record.gitSHA)
    let finalURL = dir.appendingPathComponent(filename)
    let tempURL = dir.appendingPathComponent(filename + ".tmp")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(record)
    do {
      try data.write(to: tempURL)
    } catch {
      try? FileManager.default.removeItem(at: tempURL)
      throw error
    }
    do {
      try FileManager.default.moveItem(at: tempURL, to: finalURL)
    } catch {
      print("Warning: failed to publish baseline record (moveItem): \(error)")
      try? FileManager.default.removeItem(at: tempURL)
    }
  }

  static func readHistory(
    from dir: URL,
    fingerprint: String,
    buildConfiguration: String
  ) -> [BaselineRecord] {
    let prefix =
      "\(fingerprint)\(baselineFilenameSeparator)\(buildConfiguration)\(baselineFilenameSeparator)"
    let urls: [URL]
    do {
      urls = try FileManager.default.contentsOfDirectory(
        at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    } catch {
      return []
    }
    var records: [BaselineRecord] = []
    for url in urls {
      let name = url.lastPathComponent
      guard name.hasPrefix(prefix), name.hasSuffix(".json"), !name.hasSuffix(".tmp") else {
        continue
      }
      guard let data = try? Data(contentsOf: url) else {
        print("Warning: could not read baseline file \(name) — skipping")
        continue
      }
      let record: BaselineRecord
      do {
        record = try JSONDecoder().decode(BaselineRecord.self, from: data)
      } catch {
        print("Warning: malformed baseline file \(name) — skipping")
        continue
      }
      guard record.schemaVersion == 2 else {
        print(
          "Warning: baseline file \(name) has schemaVersion \(record.schemaVersion), expected 2 — skipping"
        )
        continue
      }
      records.append(record)
    }
    return records.sorted { $0.recordedAt < $1.recordedAt }
  }
}

// MARK: - Performance Benchmark Suite

@Suite("Performance Benchmark", .serialized)
struct PerformanceBenchmarkTests {

  private static let oa300Tolerance: Double = 0.02
  private static let giantStepsTolerance: Double = 0.02
  private static let wallClockCorpusName: String = "OA300"
  private static let wallClockIntensity: Int = 7

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"],
      !path.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      throw PerformanceBenchmarkError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")

    guard let url = jsonURL else {
      throw PerformanceBenchmarkError.groundTruthNotFound
    }

    let data = try Data(contentsOf: url)
    groundTruth = try OA300Track.loadCorpus(from: data)
  }

  @Test("benchmark wall-clock time at intensity 7 (serial) + accuracy snapshot")
  func benchmarkWallClockTime() async throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    try #require(!availableTracks.isEmpty, "OA300 corpus is empty or paths are wrong")

    enum TrackResult {
      case ok(Duration)
      case warmup(Duration)
      case failed
    }

    let clock = ContinuousClock()
    var perTrackResults: [(track: OA300Track, result: TrackResult)] = []
    var oa300Acc1 = 0
    var oa300Acc2 = 0
    var warmupAssigned = false

    for track in availableTracks {
      let url = trackURL(track)
      let start = clock.now
      var analysis: AudioAnalysisResult?
      do {
        analysis = try AudioAnalysisService.analyzeBPM(
          url: url,
          options: {
            var o = AudioAnalysisService.Options()
            o.intensity = .default
            return o
          }())
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        analysis = nil
      }
      let elapsed = clock.now - start

      let result: TrackResult
      if let a = analysis {
        // Warmup is assigned to the *first successful* track so a failed
        // track 0 doesn't silently consume the cold-cache slot. The timing
        // slot is valid even if bpm is NaN/Inf — the analyzer *did* return
        // in finite time. Only the accuracy count filters out bad bpm.
        if !warmupAssigned {
          result = .warmup(elapsed)
          warmupAssigned = true
        } else {
          result = .ok(elapsed)
        }
        // Accuracy count (warmup track is included in accuracy — only excluded from timing).
        // NaN/Inf/non-positive bpm from pathological audio would be silently
        // counted as an Acc1 miss by NaN-comparison semantics; skip the count
        // entirely so the ratio isn't poisoned.
        if a.bpm.isFinite, a.bpm > 0 {
          if isAcc1Match(a.bpm, track.bpm, tolerance: Self.oa300Tolerance) {
            oa300Acc1 += 1
            oa300Acc2 += 1
          } else if isAcc2Match(a.bpm, track.bpm, tolerance: Self.oa300Tolerance) {
            oa300Acc2 += 1
          }
        }
      } else {
        result = .failed
      }
      perTrackResults.append((track: track, result: result))
    }

    // Collect post-warmup successful durations for aggregates.
    let okDurations: [Double] = perTrackResults.compactMap { entry in
      if case .ok(let d) = entry.result { return Self.durationSeconds(d) }
      return nil
    }
    let warmupExcluded = perTrackResults.reduce(0) { acc, entry in
      if case .warmup = entry.result { return acc + 1 }
      return acc
    }
    let failedCount = perTrackResults.reduce(0) { acc, entry in
      if case .failed = entry.result { return acc + 1 }
      return acc
    }

    // Hardware-context header.
    let hardware = HardwareInfo.current()
    print("\n=== Performance Benchmark — Hardware Context ===")
    print(hardware.formatted())

    // Per-track table + aggregate footer.
    print("\n=== Performance Benchmark — Wall-Clock Time @ Intensity 7 ===")
    print("| Track | Time (s) | Status |")
    print("|-------|----------|--------|")
    for entry in perTrackResults {
      let title = String(entry.track.title.prefix(40))
      switch entry.result {
      case .ok(let d):
        let s = Self.durationSeconds(d)
        print("| \(title) | \(String(format: "%.3f", s)) | ok |")
      case .warmup(let d):
        let s = Self.durationSeconds(d)
        print("| \(title) | \(String(format: "%.3f", s)) | warmup, excluded |")
      case .failed:
        print("| \(title) | - | failed |")
      }
    }

    let stats = Self.aggregateStats(okDurations)
    print(
      "Tracks: \(perTrackResults.count) (\(warmupExcluded) warmup, \(failedCount) failed)")
    if let stats {
      print("mean: \(String(format: "%.3f", stats.mean))s")
      print("median: \(String(format: "%.3f", stats.median))s")
      print("p95: \(String(format: "%.3f", stats.p95))s")
      print("min: \(String(format: "%.3f", stats.min))s")
      print("max: \(String(format: "%.3f", stats.max))s")
      print("total: \(String(format: "%.3f", stats.total))s")
    } else {
      print("(no successful tracks — aggregate undefined)")
    }

    // GiantSteps accuracy pass (parallel; soft-fails to nil if env unset or corpus missing).
    let giantStepsSnapshot = try await Self.runGiantStepsAccuracy()

    // Accuracy summary line.
    let oa300Total = perTrackResults.count
    print("\n=== Performance Benchmark — Accuracy Snapshot ===")
    print(
      "OA300 @ \(String(format: "%.0f", Self.oa300Tolerance * 100))%: Acc1=\(oa300Acc1)/\(oa300Total), Acc2=\(oa300Acc2)/\(oa300Total)"
    )
    if let gs = giantStepsSnapshot {
      print(
        "GiantSteps @ \(String(format: "%.0f", gs.tolerance * 100))%: Acc1=\(gs.acc1Correct)/\(gs.total), Acc2=\(gs.acc2Correct)/\(gs.total)"
      )
    } else {
      print("GiantSteps @ 2%: (skipped — GIANTSTEPS_CORPUS_PATH unset or corpus unreadable)")
    }

    let oa300Snapshot = BaselineRecord.AccuracySnapshot(
      total: oa300Total,
      acc1Correct: oa300Acc1,
      acc2Correct: oa300Acc2,
      tolerance: Self.oa300Tolerance)

    // Persistence + delta printing.
    guard let stats else {
      print("Δ vs last baseline: (skipped — no successful tracks)")
      return
    }
    // Skip-persist gate: if >10% of the corpus failed to analyze, the resulting
    // aggregate is unrepresentative and persisting it poisons long-term
    // regression comparisons. Print the numbers for human review but don't
    // commit a record.
    if oa300Total > 0, Double(failedCount) / Double(oa300Total) > 0.1 {
      print(
        "WARNING: failedCount=\(failedCount)/\(oa300Total) (>10%) — skipping baseline persistence to avoid poisoning history"
      )
      return
    }
    let counts = WallClockCounts(
      trackCount: oa300Total,
      warmupExcluded: warmupExcluded,
      failedCount: failedCount)
    let record = Self.buildRecord(
      stats: stats,
      hardware: hardware,
      counts: counts,
      oa300Accuracy: oa300Snapshot,
      giantStepsAccuracy: giantStepsSnapshot)
    try Self.handleBaselinePersistence(record: record, hardware: hardware)
  }

  /// Story 4.3 AC #7 second-gate: the mock-on-abstaining ML path's
  /// wall-clock at intensity 7 must complete within
  /// `mlMockOnAbstainMaxRatio` of the `mlTechnique=nil` baseline recorded
  /// in this same suite invocation. Hard-fail.
  ///
  /// Both passes run within a single test invocation so the comparison is
  /// against the same machine state, same warm/cold-cache profile, same
  /// system load — no cross-run noise. Each pass excludes its first
  /// successful track as warmup (matches `benchmarkWallClockTime`).
  ///
  /// Threshold history and current floor are documented on
  /// ``mlMockOnAbstainMaxRatio`` below (PR #2 F2/F17 rebaseline supersedes
  /// the prior Story 4-3b tightening).
  @Test("ML mock-on-abstain wall-clock ≤ 1.60x baseline at intensity 7 (PR #2 F2/F17 rebaseline)")
  func mlMockOnAbstainPerf() async throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    try #require(!availableTracks.isEmpty, "OA300 corpus is empty or paths are wrong")

    // Counterbalanced per-track measurement (PR #2 follow-up F17): the
    // historical shape `runPass(nil); runPass(mock)` left mock always running
    // second per track, biased toward mock by OS filesystem-cache warmth from
    // the just-finished baseline read. We now interleave AND counterbalance:
    // even index (0, 2, 4 ...) measures baseline FIRST then mock; odd index
    // (1, 3, 5 ...) measures mock FIRST then baseline. The downstream metric
    // (`mockMean / baselineMean` over paired durations, with `dropFirst()`
    // symmetric warmup) is intact, so the historical 1.20x threshold still
    // means the same thing — only the per-track ordering changes.
    //
    // F2: ensemblePolicy = .mlOnly is required to actually invoke the mock.
    // Default `.dspOnly` short-circuits MLTechnique.evaluate(trace:) at
    // AudioAnalysisService.swift:333 even when `mlTechnique != nil`; the
    // gate before F2 was therefore comparing two DSP-only passes.
    let clock = ContinuousClock()
    func measureOne(
      url: URL, mlTechnique: (any MLTechnique)?, firstError: inout Error?
    ) -> Double? {
      let start = clock.now
      do {
        _ = try AudioAnalysisService.analyzeBPM(
          url: url,
          options: {
            var o = AudioAnalysisService.Options()
            o.intensity = .default
            o.mlTechnique = mlTechnique
            // Real ML invocation path (PR #2 follow-up F2). With the mock
            // returning nil (abstain) the combiner falls back to DSP, so
            // analysis result bytes stay DSP-derived; only the perf
            // measurement covers the actual abstain-path overhead.
            o.ensemblePolicy = .mlOnly
            return o
          }())
        return Self.durationSeconds(clock.now - start)
      } catch {
        if firstError == nil { firstError = error }
        return nil
      }
    }

    var baselinePerTrack: [Double?] = []
    var mockPerTrack: [Double?] = []
    var firstError: Error?
    for (i, track) in availableTracks.enumerated() {
      let url = trackURL(track)
      if i % 2 == 0 {
        let b = measureOne(url: url, mlTechnique: nil, firstError: &firstError)
        let m = measureOne(
          url: url, mlTechnique: MockMLTechnique(returning: nil),
          firstError: &firstError)
        baselinePerTrack.append(b)
        mockPerTrack.append(m)
      } else {
        let m = measureOne(
          url: url, mlTechnique: MockMLTechnique(returning: nil),
          firstError: &firstError)
        let b = measureOne(url: url, mlTechnique: nil, firstError: &firstError)
        mockPerTrack.append(m)
        baselinePerTrack.append(b)
      }
    }

    // Pair zipping + symmetric warmup unchanged from the previous shape.
    var pairedDurations: [(baseline: Double, mock: Double)] = []
    for (b, m) in zip(baselinePerTrack, mockPerTrack) {
      if let b = b, let m = m { pairedDurations.append((b, m)) }
    }

    if pairedDurations.count < 2 {
      let diag: String
      if let err = firstError {
        diag = "first analyzeBPM error: \(err)"
      } else {
        diag = "no analyzeBPM errors recorded — check OA300 corpus contents"
      }
      try #require(
        pairedDurations.count >= 2,
        "perf gate needs ≥2 tracks succeeding in BOTH passes (got \(pairedDurations.count)). \(diag)"
      )
    }

    let measured = pairedDurations.dropFirst()  // symmetric warmup drop
    let baselineMean = measured.map(\.baseline).reduce(0, +) / Double(measured.count)
    let mockMean = measured.map(\.mock).reduce(0, +) / Double(measured.count)
    let ratio = mockMean / baselineMean

    print("\n=== Performance Benchmark — ML Mock-on-Abstain Gate (Story 4.3 AC #7) ===")
    print(
      "baseline (mlTechnique=nil)        mean: \(String(format: "%.3f", baselineMean))s over \(measured.count) tracks"
    )
    print(
      "mock     (MockMLTechnique(nil))   mean: \(String(format: "%.3f", mockMean))s over \(measured.count) tracks"
    )
    print(
      "ratio = \(String(format: "%.3f", ratio))x (threshold: \(String(format: "%.2f", Self.mlMockOnAbstainMaxRatio))x)"
    )

    #expect(
      ratio <= Self.mlMockOnAbstainMaxRatio,
      "PR #2 F2/F17: mock-on-abstain ratio \(String(format: "%.3f", ratio))x exceeds threshold \(String(format: "%.2f", Self.mlMockOnAbstainMaxRatio))x (rebaselined to real ML path in be26fa5). If this fires on a clean tree, the abstain-path cost has structurally regressed — do NOT silently widen the threshold."
    )
  }

  /// PR #2 follow-up F2/F17 rebaseline (2026-05-18): widened to **1.60x**
  /// against a real measurement (the prior 1.20x was set against a
  /// degenerate gate that didn't actually invoke `MLTechnique.evaluate`
  /// — both passes ran DSP-only because the default `.dspOnly` policy
  /// short-circuited the mock at AudioAnalysisService.swift:333).
  ///
  /// New floor: 1.547x (mock 0.267s / baseline 0.173s over 81 OA300 tracks
  /// under counterbalanced per-track ordering on Apple M5 Max). Headroom
  /// 0.053 (~3% of floor). The historical 1.083x floor and Story 4-3b
  /// formula no longer apply — that measurement was of the wrong path.
  ///
  /// Story 4-3b AC #4 history (now superseded): tightened from Story
  /// 4.3's 1.30x (unmeasured) to 1.20x against a measured floor of 1.083x
  /// across `[1.042, 1.083, 1.100, 1.093, 1.083]`. Both numbers measured
  /// the degenerate gate; the 1.083x median was of `.dspOnly` vs
  /// `.dspOnly`, not of `.mlOnly` vs no-ML.
  private static let mlMockOnAbstainMaxRatio: Double = 1.60

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

  private static func durationSeconds(_ d: Duration) -> Double {
    let comps = d.components
    return Double(comps.seconds) + Double(comps.attoseconds) / 1e18
  }

  private struct AggregateStats {
    let mean: Double
    let median: Double
    let p95: Double
    let min: Double
    let max: Double
    let total: Double
  }

  private struct WallClockCounts {
    let trackCount: Int
    let warmupExcluded: Int
    let failedCount: Int
  }

  private static func aggregateStats(_ seconds: [Double]) -> AggregateStats? {
    guard !seconds.isEmpty else { return nil }
    let sorted = seconds.sorted()
    let count = sorted.count
    let total = sorted.reduce(0, +)
    let mean = total / Double(count)
    let median: Double
    if count % 2 == 0 {
      median = (sorted[count / 2 - 1] + sorted[count / 2]) / 2
    } else {
      median = sorted[count / 2]
    }
    let p95 = sorted[p95Index(count: count)]
    return AggregateStats(
      mean: mean, median: median, p95: p95,
      min: sorted.first!, max: sorted.last!, total: total)
  }

  /// Runs a GiantSteps accuracy pass in parallel (matches the upstream
  /// `GiantStepsBenchmarkTests.runBenchmark` pattern: withTaskGroup across
  /// all available tracks at intensity 7, 2% tolerance, with `tempo2`
  /// fallback for both Acc1 and Acc2). Returns nil when the env var is
  /// unset or the ground-truth JSON is missing (loud-fail-safe).
  private static func runGiantStepsAccuracy() async throws -> BaselineRecord.AccuracySnapshot? {
    guard let path = ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"],
      !path.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      return nil
    }
    let jsonPath = (path as NSString)
      .appendingPathComponent("giantsteps-tempo-ground-truth.json")
    guard FileManager.default.fileExists(atPath: jsonPath) else {
      return nil
    }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
      let tracks = try? JSONDecoder().decode([GiantStepsTrack].self, from: data)
    else {
      return nil
    }

    func trackURL(_ track: GiantStepsTrack) -> URL {
      URL(fileURLWithPath: path)
        .appendingPathComponent("audio")
        .appendingPathComponent(track.filename)
    }

    let availableTracks = tracks.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    guard !availableTracks.isEmpty else { return nil }

    let urls = availableTracks.map { trackURL($0) }

    // Throwing task group so CancellationError propagates up instead of
    // being coerced to nil by try?. Non-cancellation analysis failures are
    // still classified as nil on a per-track basis.
    let trackBPMs = try await withThrowingTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          do {
            let result = try AudioAnalysisService.analyzeBPM(
              url: url,
              options: {
                var o = AudioAnalysisService.Options()
                o.intensity = .default
                return o
              }())
            return (index, result?.bpm)
          } catch is CancellationError {
            throw CancellationError()
          } catch {
            return (index, nil)
          }
        }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for try await (i, bpm) in group { results[i] = bpm }
      return results
    }

    let tolerance = giantStepsTolerance
    var acc1 = 0
    var acc2 = 0
    for (index, track) in availableTracks.enumerated() {
      guard let detected = trackBPMs[index] else { continue }
      let acc1Hit =
        isAcc1Match(detected, track.bpm, tolerance: tolerance)
        || (track.tempo2.map { isAcc1Match(detected, $0, tolerance: tolerance) } ?? false)
      let acc2Hit =
        acc1Hit
        || isAcc2Match(detected, track.bpm, tolerance: tolerance)
        || (track.tempo2.map { isAcc2Match(detected, $0, tolerance: tolerance) } ?? false)
      if acc1Hit {
        acc1 += 1
        acc2 += 1
      } else if acc2Hit {
        acc2 += 1
      }
    }

    return BaselineRecord.AccuracySnapshot(
      total: availableTracks.count,
      acc1Correct: acc1,
      acc2Correct: acc2,
      tolerance: tolerance)
  }

  private static func buildRecord(
    stats: AggregateStats,
    hardware: HardwareInfo,
    counts: WallClockCounts,
    oa300Accuracy: BaselineRecord.AccuracySnapshot,
    giantStepsAccuracy: BaselineRecord.AccuracySnapshot?
  ) -> BaselineRecord {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime]
    // Use the non-Optional form so the UTC contract is not defeasible.
    // secondsFromGMT: 0 always produces a valid TimeZone.
    isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
    return BaselineRecord(
      schemaVersion: 2,
      recordedAt: isoFormatter.string(from: Date()),
      gitSHA: ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown",
      buildConfiguration: hardware.buildConfiguration,
      swiftPackageVersion: hardware.swiftPackageVersion,
      hardware: BaselineRecord.Hardware(
        chip: hardware.chip,
        cores: hardware.cores,
        physicalMemoryGiB: hardware.physicalMemoryGiB,
        osVersion: hardware.osVersion),
      wallClock: BaselineRecord.WallClock(
        corpus: wallClockCorpusName,
        intensity: wallClockIntensity,
        trackCount: counts.trackCount,
        warmupExcluded: counts.warmupExcluded,
        failedCount: counts.failedCount,
        meanSeconds: stats.mean,
        medianSeconds: stats.median,
        p95Seconds: stats.p95,
        minSeconds: stats.min,
        maxSeconds: stats.max,
        totalSeconds: stats.total),
      accuracy: BaselineRecord.Accuracy(
        oa300: oa300Accuracy,
        giantsteps: giantStepsAccuracy))
  }

  private static func handleBaselinePersistence(
    record: BaselineRecord,
    hardware: HardwareInfo
  ) throws {
    guard let dir = ProcessInfo.processInfo.environment["PERF_BASELINE_DIR"],
      !dir.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      print("Δ vs last baseline: (skipped — PERF_BASELINE_DIR unset or unreadable)")
      return
    }

    let dirURL = URL(fileURLWithPath: dir)
    let fingerprint = BaselineStore.fingerprintPrefix(
      chip: hardware.chip,
      osMajor: ProcessInfo.processInfo.operatingSystemVersion.majorVersion)

    // Read history BEFORE writing — load-bearing ordering so the just-written record
    // is never included in the comparison set.
    let history = BaselineStore.readHistory(
      from: dirURL,
      fingerprint: fingerprint,
      buildConfiguration: hardware.buildConfiguration)

    if let prev = history.last {
      if prev.wallClock.meanSeconds > 0 {
        let curr = record.wallClock.meanSeconds
        let deltaPct = (curr - prev.wallClock.meanSeconds) / prev.wallClock.meanSeconds * 100
        let sign = deltaPct >= 0 ? "+" : ""
        print(
          "Δ vs last baseline (SHA \(prev.gitSHA), \(prev.recordedAt)): mean \(String(format: "%.3f", prev.wallClock.meanSeconds))s → \(String(format: "%.3f", record.wallClock.meanSeconds))s (\(sign)\(String(format: "%.1f", deltaPct))%)"
        )
      } else {
        print(
          "Δ vs last baseline (SHA \(prev.gitSHA), \(prev.recordedAt)): (skipped — prior meanSeconds is 0)"
        )
      }
    } else {
      print("Δ vs last baseline: (no prior record on this machine fingerprint)")
    }

    do {
      try BaselineStore.write(record, fingerprint: fingerprint, to: dirURL)
    } catch {
      print("Warning: failed to write baseline record: \(error)")
    }
  }
}

private enum PerformanceBenchmarkError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
}

/// Nearest-rank p95 index for a sorted, non-empty array of length `count`.
/// Extracted from `aggregateStats` so the formula is unit-testable without
/// the corpus-gated integration path.
private func p95Index(count: Int) -> Int {
  precondition(count > 0, "p95Index requires a non-empty array (count > 0)")
  let rank = (Double(count - 1) * 0.95).rounded(.toNearestOrAwayFromZero)
  return Swift.min(count - 1, Swift.max(0, Int(rank)))
}

// MARK: - Baseline Store Unit Tests (no corpus required)

@Suite("Baseline Store Unit Tests")
struct BaselineStoreUnitTests {

  @Test("p95Index — nearest-rank on small and realistic N")
  func p95IndexNearestRank() {
    #expect(p95Index(count: 1) == 0)
    #expect(p95Index(count: 2) == 1)
    #expect(p95Index(count: 10) == 9)
    #expect(p95Index(count: 20) == 18)
    #expect(p95Index(count: 82) == 77)
    #expect(p95Index(count: 100) == 94)
  }

  @Test("fingerprintPrefix — sanitization")
  func fingerprintPrefixSanitization() {
    #expect(BaselineStore.fingerprintPrefix(chip: "Apple M5 Max", osMajor: 26) == "Apple_M5_Max-26")
    #expect(
      BaselineStore.fingerprintPrefix(chip: "Intel(R) Core(TM) i9", osMajor: 15)
        == "Intel_R_Core_TM_i9-15")
    #expect(
      BaselineStore.fingerprintPrefix(chip: "Intel R  Core TM  i9", osMajor: 15)
        == "Intel_R_Core_TM_i9-15")
    #expect(
      BaselineStore.fingerprintPrefix(chip: "Intel Core i9 ", osMajor: 15)
        == "Intel_Core_i9-15")
  }

  @Test("buildRecordFilename — exact template")
  func buildRecordFilenameExactTemplate() {
    let filename = BaselineStore.buildRecordFilename(
      fingerprint: "Apple_M5_Max-26",
      buildConfiguration: "Debug",
      recordedAt: "20260418T143022Z",
      gitSHA: "d224cb7")
    let base = filename.hasSuffix(".json") ? String(filename.dropLast(5)) : filename
    let parts = base.components(separatedBy: "--")
    #expect(parts.count == 5)
    #expect(parts[0] == "Apple_M5_Max-26")
    #expect(parts[1] == "Debug")
    #expect(parts[2] == "20260418T143022Z")
    #expect(parts[3] == "d224cb7")
    #expect(parts[4].count == 8)
    #expect(parts[4].allSatisfy { $0.isHexDigit })
  }

  @Test("buildRecordFilename — same inputs produce unique filenames")
  func buildRecordFilenameUniqueness() {
    let a = BaselineStore.buildRecordFilename(
      fingerprint: "Apple_M5_Max-26", buildConfiguration: "Debug",
      recordedAt: "20260418T143022Z", gitSHA: "d224cb7")
    let b = BaselineStore.buildRecordFilename(
      fingerprint: "Apple_M5_Max-26", buildConfiguration: "Debug",
      recordedAt: "20260418T143022Z", gitSHA: "d224cb7")
    #expect(a != b)
  }

  @Test("parseRecordFilename — inverse of builder")
  func parseRecordFilenameInverseOfBuilder() {
    let fingerprint = "Apple_M5_Max-26"
    let buildConfiguration = "Debug"
    let recordedAt = "20260418T143022Z"
    let gitSHA = "d224cb7"
    let filename = BaselineStore.buildRecordFilename(
      fingerprint: fingerprint, buildConfiguration: buildConfiguration,
      recordedAt: recordedAt, gitSHA: gitSHA)
    let base = filename.hasSuffix(".json") ? String(filename.dropLast(5)) : filename
    let parts = base.components(separatedBy: "--")
    #expect(parts.count == 5)
    #expect(parts[0] == fingerprint)
    #expect(parts[1] == buildConfiguration)
    #expect(parts[2] == recordedAt)
    #expect(parts[3] == gitSHA)
    #expect(parts[4].count == 8)
  }

  @Test("readHistory — 0/1/2/N files")
  func readHistoryVariousFileCounts() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"

    var history = BaselineStore.readHistory(
      from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.isEmpty)

    try BaselineStore.write(Self.stubRecord(), fingerprint: fp, to: dir)
    history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.count == 1)

    try BaselineStore.write(Self.stubRecord(), fingerprint: fp, to: dir)
    history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.count == 2)

    try BaselineStore.write(Self.stubRecord(), fingerprint: fp, to: dir)
    history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.count == 3)
  }

  @Test("readHistory — sorting by recordedAt")
  func readHistorySortsByRecordedAt() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"

    let records = [
      Self.stubRecord(recordedAt: "2026-04-19T12:00:02Z"),
      Self.stubRecord(recordedAt: "2026-04-19T12:00:00Z"),
      Self.stubRecord(recordedAt: "2026-04-19T12:00:01Z"),
    ]
    for rec in records {
      try BaselineStore.write(rec, fingerprint: fp, to: dir)
    }

    let history = BaselineStore.readHistory(
      from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.count == 3)
    #expect(history[0].recordedAt == "2026-04-19T12:00:00Z")
    #expect(history[1].recordedAt == "2026-04-19T12:00:01Z")
    #expect(history[2].recordedAt == "2026-04-19T12:00:02Z")
  }

  @Test("readHistory — one malformed file warns and skips")
  func readHistoryMalformedFileSkipped() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"
    let bc = "Debug"

    try BaselineStore.write(Self.stubRecord(), fingerprint: fp, to: dir)

    let badName = "\(fp)--\(bc)--20260419T120000Z--abc1234--ffffffff.json"
    try Data("{nonsense".utf8).write(to: dir.appendingPathComponent(badName))

    let history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: bc)
    #expect(history.count == 1)
  }

  @Test("readHistory — schemaVersion mismatch skipped")
  func readHistorySchemaVersionMismatchSkipped() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"
    let bc = "Debug"

    try BaselineStore.write(Self.stubRecord(schemaVersion: 2), fingerprint: fp, to: dir)

    let v1Name = "\(fp)--\(bc)--20260419T120000Z--abc1234--eeeeeeee.json"
    try Data(Self.stubRecordJSON(schemaVersion: 1).utf8).write(
      to: dir.appendingPathComponent(v1Name))

    let history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: bc)
    #expect(history.count == 1)
  }

  @Test("readHistory — fingerprint prefix filter")
  func readHistoryFingerprintFilter() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    try BaselineStore.write(Self.stubRecord(), fingerprint: "Apple_M5_Max-26", to: dir)
    try BaselineStore.write(Self.stubRecord(), fingerprint: "Intel_Core_i9-15", to: dir)

    let history = BaselineStore.readHistory(
      from: dir, fingerprint: "Apple_M5_Max-26", buildConfiguration: "Debug")
    #expect(history.count == 1)
  }

  @Test("readHistory — buildConfiguration prefix filter")
  func readHistoryBuildConfigFilter() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"

    try BaselineStore.write(Self.stubRecord(buildConfiguration: "Debug"), fingerprint: fp, to: dir)
    try BaselineStore.write(
      Self.stubRecord(buildConfiguration: "Release"), fingerprint: fp, to: dir)

    let debugHistory = BaselineStore.readHistory(
      from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(debugHistory.count == 1)

    let releaseHistory = BaselineStore.readHistory(
      from: dir, fingerprint: fp, buildConfiguration: "Release")
    #expect(releaseHistory.count == 1)
  }

  @Test("readHistory — skips .tmp files")
  func readHistorySkipsTmpFiles() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"
    let bc = "Debug"

    let tmpName = "\(fp)--\(bc)--20260419T120000Z--abc1234--11111111.json.tmp"
    try Data("{}".utf8).write(to: dir.appendingPathComponent(tmpName))

    let history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: bc)
    #expect(history.isEmpty)
  }

  @Test("readHistory — skips dotfiles")
  func readHistorySkipsDotfiles() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"
    let bc = "Debug"

    try Data("{}".utf8).write(to: dir.appendingPathComponent(".DS_Store"))
    try Data("{}".utf8).write(to: dir.appendingPathComponent("._foo.json"))

    let history = BaselineStore.readHistory(from: dir, fingerprint: fp, buildConfiguration: bc)
    #expect(history.isEmpty)
  }

  @Test("write → readHistory round-trip")
  func writeReadHistoryRoundTrip() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }
    let fp = "Apple_M5_Max-26"
    let original = Self.stubRecord()

    try BaselineStore.write(original, fingerprint: fp, to: dir)

    let history = BaselineStore.readHistory(
      from: dir, fingerprint: fp, buildConfiguration: "Debug")
    #expect(history.count == 1)
    let read = try #require(history.first)
    #expect(read.recordedAt == original.recordedAt)
    #expect(read.gitSHA == original.gitSHA)
    #expect(read.schemaVersion == original.schemaVersion)
    #expect(read.wallClock.meanSeconds == original.wallClock.meanSeconds)
  }

  @Test("write atomicity — temp file absent post-write")
  func writeAtomicityNoTmpOrphan() throws {
    let dir = try Self.tmpDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    try BaselineStore.write(Self.stubRecord(), fingerprint: "Apple_M5_Max-26", to: dir)

    let allFiles = try FileManager.default.contentsOfDirectory(atPath: dir.path)
    #expect(allFiles.filter { $0.hasSuffix(".tmp") }.isEmpty)
  }

  // MARK: - Fixtures

  private static func tmpDir() throws -> URL {
    let dir = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("bbbk-bl-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private static func stubRecord(
    schemaVersion: Int = 2,
    recordedAt: String = "2026-04-17T00:00:00Z",
    buildConfiguration: String = "Debug"
  ) -> BaselineRecord {
    BaselineRecord(
      schemaVersion: schemaVersion,
      recordedAt: recordedAt,
      gitSHA: "test",
      buildConfiguration: buildConfiguration,
      swiftPackageVersion: "test",
      hardware: .init(chip: "Apple M5 Max", cores: 18, physicalMemoryGiB: 128, osVersion: "Y"),
      wallClock: .init(
        corpus: "OA300", intensity: 7, trackCount: 82, warmupExcluded: 1, failedCount: 0,
        meanSeconds: 0.216, medianSeconds: 0.182, p95Seconds: 0.285, minSeconds: 0.140,
        maxSeconds: 0.331, totalSeconds: 17.49),
      accuracy: .init(
        oa300: .init(total: 82, acc1Correct: 57, acc2Correct: 73, tolerance: 0.02),
        giantsteps: nil))
  }

  private static func stubRecordJSON(schemaVersion: Int) -> String {
    """
    {
      "schemaVersion": \(schemaVersion),
      "recordedAt": "2026-04-17T00:00:00Z",
      "gitSHA": "test",
      "buildConfiguration": "Debug",
      "swiftPackageVersion": "test",
      "hardware": {"chip": "Apple M5 Max", "cores": 18, "physicalMemoryGiB": 128, "osVersion": "Y"},
      "wallClock": {"corpus": "OA300", "intensity": 7, "trackCount": 82, "warmupExcluded": 1,
        "failedCount": 0, "meanSeconds": 0.216, "medianSeconds": 0.182, "p95Seconds": 0.285,
        "minSeconds": 0.140, "maxSeconds": 0.331, "totalSeconds": 17.49},
      "accuracy": {"oa300": {"total": 82, "acc1Correct": 57, "acc2Correct": 73, "tolerance": 0.02},
        "giantsteps": null}
    }
    """
  }
}
