//
//  CombinedAnalyzeImpactTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.5 AC10 combined-analyze perf gate + full-track-coverage report.
//  Mirrors SharedDecodeImpactGateTests / BeatGridImpactTests (release config,
//  env-gated, warmups, alternating measurement order, per-file paired medians →
//  format median, multiplicative + absolute-epsilon noise margin). Reuses the
//  SharedDecodeProbe plumbing from SharedDecodeImpactTests (same target).
//
//  Two lanes:
//  - Gate (asserted): `analyze(url:)` decodes ONCE, so its wall-clock must not
//    exceed `analyzeBPM(url:) + analyzeBeatGrid(url:)` (which decode TWICE)
//    beyond measurement noise — the FR-35 shared-decode saving.
//  - Report (NOT asserted): the marginal cost of `.fullTrack` coverage vs the
//    default `.analysisWindow` per format (the second O(track) onset pass).
//
//  Run in RELEASE:
//    OA300_CORPUS_PATH=... COMBINED_ANALYZE_IMPACT=1 swift test -c release \
//      --filter BoomBoomBoomKitBenchmarkTests.CombinedAnalyzeImpactGateTests
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

private struct CombinedFormatImpact: Encodable {
  let sequentialMedian: Double  // analyzeBPM + analyzeBeatGrid (two decodes)
  let combinedMedian: Double  // analyze (one decode)
  let savingFraction: Double  // (sequential - combined) / sequential
  let sharedDecodeGateMet: Bool
  let fullTrackMedian: Double  // analyze(.fullTrack) (one decode, second onset pass)
  let fullTrackOverheadFraction: Double  // (fullTrack - combined) / combined  (REPORTED)
  let fileCount: Int
}

private struct CombinedImpactReport: Encodable {
  let gitSHA: String
  let date: String
  let configuration: String
  let matchedMaxSeconds: Double
  let measuredReps: Int
  let sharedDecodeMargin: Double
  let perFormat: [String: CombinedFormatImpact]
}

@Suite(
  "Combined-Analyze Impact Gate",
  .enabled(
    if: ProcessInfo.processInfo.environment["COMBINED_ANALYZE_IMPACT"] == "1"
      && SharedDecodeProbe.corpusPath() != nil),
  .serialized)
struct CombinedAnalyzeImpactGateTests {

  /// AC10: `analyze` over one shared decode is no slower than the separate
  /// `analyzeBPM` + `analyzeBeatGrid` (two decodes), within noise; `.fullTrack`
  /// overhead is reported per format, not gated.
  @Test func sharedDecodeGateAndFullTrackReport() async throws {
    let corpus = try #require(SharedDecodeProbe.corpusPath())
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpus)

    let matchedSeconds = 120.0
    let measuredReps = 3
    let perFormatCap = 10
    // Combined must not exceed sequential beyond noise. ×1.10 multiplicative +
    // a 20 ms absolute epsilon (combined is EXPECTED to be cheaper — it skips one
    // decode — so this only guards against a noise-driven false failure).
    let sharedDecodeMargin = 1.10
    let noiseEpsilonSeconds = 0.020

    var fullTrackOptions = AudioAnalysisService.Options()
    fullTrackOptions.maxSeconds = matchedSeconds
    fullTrackOptions.beatGridCoverage = .fullTrack
    var windowOptions = AudioAnalysisService.Options()
    windowOptions.maxSeconds = matchedSeconds

    print("\n=== Story 8-5 combined-analyze impact (maxSeconds=120) ===")
    #if DEBUG
      print("WARNING: Debug configuration — timings not representative. Use -c release.")
    #endif

    var perFormat: [String: CombinedFormatImpact] = [:]
    for format in ProbeFormat.allCases {
      let candidates = byFormat[format] ?? []
      guard !candidates.isEmpty else { continue }
      let files = SharedDecodeProbe.select(candidates, cap: perFormatCap, seed: 0x8_5)

      var sequentialMedians: [Double] = []
      var combinedMedians: [Double] = []
      var fullTrackMedians: [Double] = []
      for fileURL in files {
        // Warmups (codec/page-cache).
        _ = try? AudioAnalysisService.analyzeBPM(url: fileURL, options: windowOptions)
        _ = try? AudioAnalysisService.analyze(url: fileURL, options: windowOptions)

        var sequential: [Double] = []
        var combined: [Double] = []
        var fullTrack: [Double] = []
        for rep in 0..<measuredReps {
          // Alternate order so neither path systematically benefits from state
          // the other warmed.
          if rep.isMultiple(of: 2) {
            sequential.append(
              SharedDecodeProbe.time {
                _ = try? AudioAnalysisService.analyzeBPM(url: fileURL, options: windowOptions)
                _ = try? AudioAnalysisService.analyzeBeatGrid(url: fileURL, options: windowOptions)
              })
            combined.append(
              SharedDecodeProbe.time {
                _ = try? AudioAnalysisService.analyze(url: fileURL, options: windowOptions)
              })
          } else {
            combined.append(
              SharedDecodeProbe.time {
                _ = try? AudioAnalysisService.analyze(url: fileURL, options: windowOptions)
              })
            sequential.append(
              SharedDecodeProbe.time {
                _ = try? AudioAnalysisService.analyzeBPM(url: fileURL, options: windowOptions)
                _ = try? AudioAnalysisService.analyzeBeatGrid(url: fileURL, options: windowOptions)
              })
          }
          fullTrack.append(
            SharedDecodeProbe.time {
              _ = try? AudioAnalysisService.analyze(url: fileURL, options: fullTrackOptions)
            })
        }
        sequentialMedians.append(SharedDecodeProbe.median(sequential))
        combinedMedians.append(SharedDecodeProbe.median(combined))
        fullTrackMedians.append(SharedDecodeProbe.median(fullTrack))
      }

      let sequentialMedian = SharedDecodeProbe.median(sequentialMedians)
      let combinedMedian = SharedDecodeProbe.median(combinedMedians)
      let fullTrackMedian = SharedDecodeProbe.median(fullTrackMedians)
      let saving =
        sequentialMedian > 0 ? (sequentialMedian - combinedMedian) / sequentialMedian : 0
      let gateMet = combinedMedian <= sequentialMedian * sharedDecodeMargin + noiseEpsilonSeconds
      let fullTrackOverhead =
        combinedMedian > 0 ? (fullTrackMedian - combinedMedian) / combinedMedian : 0

      perFormat[format.rawValue] = CombinedFormatImpact(
        sequentialMedian: sequentialMedian,
        combinedMedian: combinedMedian,
        savingFraction: saving,
        sharedDecodeGateMet: gateMet,
        fullTrackMedian: fullTrackMedian,
        fullTrackOverheadFraction: fullTrackOverhead,
        fileCount: files.count)

      print(
        """
        \(format.rawValue) (n=\(files.count), reps=\(measuredReps)):
          sequential (2 decodes) = \(String(format: "%.4f", sequentialMedian))s
          combined   (1 decode)  = \(String(format: "%.4f", combinedMedian))s
          saving                 = \(String(format: "%.1f", saving * 100))%  gateMet=\(gateMet)
          .fullTrack             = \(String(format: "%.4f", fullTrackMedian))s  (+\(String(format: "%.1f", fullTrackOverhead * 100))% vs window, REPORTED)
        """)

      #expect(
        gateMet,
        "AC10 shared-decode gate FAILED for \(format.rawValue): combined \(combinedMedian)s > sequential \(sequentialMedian)s × \(sharedDecodeMargin) + \(noiseEpsilonSeconds)s"
      )
    }

    #expect(perFormat["mp3"] != nil, "AC10 coverage: no mp3 files resolved from the corpus")
    #expect(perFormat["flac"] != nil, "AC10 coverage: no flac files resolved from the corpus")

    let outDir =
      ProcessInfo.processInfo.environment["COMBINED_ANALYZE_IMPACT_OUT_DIR"]
      ?? FileManager.default.currentDirectoryPath
    let report = CombinedImpactReport(
      gitSHA: ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown",
      date: ISO8601DateFormatter().string(from: Date()),
      configuration: {
        #if DEBUG
          return "debug"
        #else
          return "release"
        #endif
      }(),
      matchedMaxSeconds: matchedSeconds,
      measuredReps: measuredReps,
      sharedDecodeMargin: sharedDecodeMargin,
      perFormat: perFormat)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let outURL = URL(fileURLWithPath: outDir)
      .appendingPathComponent("8-5-combined-analyze-impact.json")
    try encoder.encode(report).write(to: outURL)
    print("combined-analyze impact report written: \(outURL.path)")
  }
}
