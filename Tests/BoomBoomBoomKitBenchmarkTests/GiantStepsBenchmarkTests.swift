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
  /// Resolved at the loader (Story 12.3, FR-60) so every figure this suite emits
  /// carries the annotation version of the ground truth it was scored against.
  private let annotationVersion: AnnotationVersion

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
    let versioned = try GiantStepsTrack.loadVersionedCorpus(from: data)
    groundTruth = versioned.tracks
    annotationVersion = versioned.annotationVersion
  }

  @Test("benchmark at default intensity (7)")
  func benchmarkDefaultIntensity() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.02)
    print("\n=== GiantSteps Tempo Benchmark — Intensity 7 (default) ===")
    print("Corpus: \(metrics.total) tracks, crowdsourced ground truth (v2)")
    print("Annotation version: \(annotationVersion)")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    // Story 12.3 (FR-61): the octave-error proxy as a named figure, not a reader derivation.
    let tally = try AccuracyTally(
      acc1: metrics.acc1Correct, acc2: metrics.acc2Correct, total: metrics.total,
      annotationVersion: annotationVersion)
    print("Acc2-Acc1 (octave-error proxy): \(tally.formattedOctaveErrorProxy)")
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

    // Story 3-3 AC #6 + Story 3-4 AC #4 floors: unconditional `#expect` on every CI
    // invocation regardless of preset membership. Catches wiring bugs that
    // "by construction" reasoning would miss.
    #expect(
      metrics.acc1Correct >= 537,
      "AC #6 GiantSteps Acc1 regression: expected >= 537/661 (81.2%), got \(metrics.acc1Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc2Correct >= 546,
      "AC #6 GiantSteps Acc2 regression: expected >= 546/661 (82.6%), got \(metrics.acc2Correct)/\(metrics.total)"
    )
  }

  // Story 3-4 AC #5: opt-out regression-safety control. With `durationHint: false`,
  // GiantSteps must match the pre-Story-3-4 baseline EXACTLY (537/661 Acc1, 546/661 Acc2
  // under strict-2% tolerance, matching Story 3-3a Completion Notes). Story 3.6 AC #4
  // also requires `metadataPolicy = .disabled` to keep the byte-equality contract.
  @Test("AC #5: durationHint=false matches pre-Story-3-4 baseline EXACTLY")
  func benchmarkDurationHintOptOut() async throws {
    let (metrics, _) = try await runBenchmark(
      intensity: .default, tolerance: 0.02,
      durationHint: false, metadataPolicy: .disabled)
    print("\n=== GiantSteps Benchmark — durationHint=false (AC #5 control) ===")
    print(
      "Acc1: \(metrics.acc1Correct)/\(metrics.total), Acc2: \(metrics.acc2Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc1Correct == 537,
      "AC #5 GiantSteps Acc1 (durationHint=false) must equal 537/661 EXACTLY, got \(metrics.acc1Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc2Correct == 546,
      "AC #5 GiantSteps Acc2 (durationHint=false) must equal 546/661 EXACTLY, got \(metrics.acc2Correct)/\(metrics.total)"
    )
  }

  // Story 3-5 Task 8.3 — corpus regression `#expect` for AC #4.
  // Baseline captured at git SHA `ba6ba523990aecef872c0bdff96b758918609eee`
  // (post-Story-3-4 close-out, pre-Story-3-5) via a temporary harness running
  // `runBenchmark(intensity: .default, mergeStrategy: .windowVoting,
  // tolerance: 0.02)`. Drift indicates the Story 3-5 wiring leaked state into
  // the default windowVoting code path.
  @Test("AC #4: windowVoting + .simpleMajority matches pre-Story-3-5 baseline EXACTLY")
  func windowVotingDefaultPolicyMatchesBaseline() async throws {
    // Hardcoded from Task 0 baseline capture (see story Debug Log References).
    let giantStepsAcc1Baseline = 537
    let giantStepsAcc2Baseline = 546
    let total = 661

    // Story 3.6 AC #4: this exact-baseline test predates metadata corroboration.
    // Setting `.disabled` preserves the pre-Story-3.6 pipeline so the byte-equality
    // contract still holds.
    let (metrics, perTrack) = try await runBenchmark(
      intensity: .default, mergeStrategy: .windowVoting, tolerance: 0.02,
      metadataPolicy: .disabled)

    // Surface analyzeBPM nils explicitly — without this guard, a transient
    // AVFoundation failure would silently lower Acc1 and fail the unconditional
    // baseline check below with a misleading "Acc1 must equal 537/661" message.
    let nilTracks = perTrack.filter { $0.detected == nil }.map { $0.track.filename }
    #expect(
      nilTracks.isEmpty,
      "AC #4 baseline: \(nilTracks.count) tracks returned nil from analyzeBPM (failure precedes Acc1/Acc2 drift): \(nilTracks.prefix(5))"
    )

    #expect(
      metrics.total == total,
      "Expected \(total) GiantSteps tracks at baseline; got \(metrics.total)")
    #expect(
      metrics.acc1Correct == giantStepsAcc1Baseline,
      "AC #4: GiantSteps windowVoting+.simpleMajority Acc1 must equal \(giantStepsAcc1Baseline)/\(total) EXACTLY, got \(metrics.acc1Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc2Correct == giantStepsAcc2Baseline,
      "AC #4: GiantSteps windowVoting+.simpleMajority Acc2 must equal \(giantStepsAcc2Baseline)/\(total) EXACTLY, got \(metrics.acc2Correct)/\(metrics.total)"
    )
  }

  @Test("benchmark Acc1 strict (2% tolerance)")
  func benchmarkAcc1Strict() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.02)
    print("\n=== GiantSteps Tempo Benchmark — Acc1 Strict (2% tolerance) ===")
    print("Corpus: \(metrics.total) tracks, crowdsourced ground truth (v2)")
    print("Annotation version: \(annotationVersion)")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    // Story 12.3 (FR-61): the octave-error proxy as a named figure, not a reader derivation.
    let tally = try AccuracyTally(
      acc1: metrics.acc1Correct, acc2: metrics.acc2Correct, total: metrics.total,
      annotationVersion: annotationVersion)
    print("Acc2-Acc1 (octave-error proxy): \(tally.formattedOctaveErrorProxy)")
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
    print("Annotation version: \(annotationVersion)")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    // Story 12.3 (FR-61): the octave-error proxy as a named figure, not a reader derivation.
    let tally = try AccuracyTally(
      acc1: metrics.acc1Correct, acc2: metrics.acc2Correct, total: metrics.total,
      annotationVersion: annotationVersion)
    print("Acc2-Acc1 (octave-error proxy): \(tally.formattedOctaveErrorProxy)")
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
      intensity: AnalysisIntensity.default.level,
      annotationVersion: annotationVersion,
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
    mergeStrategy: BPMSelectionPolicy = .maxConfidence,
    tolerance: Double,
    durationHint: Bool = true,
    metadataPolicy: MetadataPolicy = .default
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
                o.durationHint = durationHint
                o.metadataPolicy = metadataPolicy
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

  /// MIREX Acc1/Acc2 hit check with optional `tempo2` fallback — the FLOOR-compatible
  /// verdicts of the shared ``mirexTempoVerdict`` helper (Story 12.3; the strict-vs-floor
  /// rationale, including the measured 71-track gap, moved to that helper's doc comment).
  /// Shared by `runBenchmark` and `benchmarkByGenre` so the two stay in lockstep.
  private func mirexHit(
    track: GiantStepsTrack,
    detected: Double,
    tolerance: Double
  ) -> (acc1: Bool, acc2: Bool) {
    let verdict = mirexTempoVerdict(
      detected: detected, primary: track.bpm, alternate: track.tempo2, tolerance: tolerance)
    return (verdict.floorAcc1, verdict.floorAcc2)
  }
}

private enum GiantStepsError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
