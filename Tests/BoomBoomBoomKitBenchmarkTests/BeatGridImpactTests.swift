//
//  BeatGridImpactTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.4 AC8 beat-grid overhead gate. Mirrors SharedDecodeImpactGateTests
//  (release config, env-gated, warmups, alternating measurement order per rep,
//  per-file paired medians → format median, multiplicative + absolute-epsilon
//  noise margin). Reuses the SharedDecodeProbe plumbing from
//  SharedDecodeImpactTests (same benchmark target).
//
//  The "beat-grid overhead" is the MARGINAL cost of the optional step-11 DP
//  fan-out within a single decoded pass: `estimateBPM(computeBeatGrid: true)`
//  vs `false` on one shared `DecodedAudio`. This is the realistic consumer
//  flow for getting BPM + beat grid from one decode, and isolates the DP cost
//  from the (unrelated) decode and BPM-pipeline cost.
//
//  Run in RELEASE:
//    OA300_CORPUS_PATH=... BEAT_GRID_IMPACT=1 swift test -c release \
//      --filter BoomBoomBoomKitBenchmarkTests.BeatGridImpactGateTests
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

private struct BeatGridFormatImpact: Encodable {
  let bpmOnlyMedian: Double
  let withGridMedian: Double
  let overheadFraction: Double
  let overheadGateMet: Bool
  let fileCount: Int
}

private struct BeatGridImpactReport: Encodable {
  let gitSHA: String
  let date: String
  let configuration: String
  let matchedMaxSeconds: Double
  let measuredReps: Int
  let overheadMargin: Double
  let perFormat: [String: BeatGridFormatImpact]
}

@Suite(
  "Beat-Grid Impact Gate",
  .enabled(
    if: ProcessInfo.processInfo.environment["BEAT_GRID_IMPACT"] == "1"
      && SharedDecodeProbe.corpusPath() != nil),
  .serialized)
struct BeatGridImpactGateTests {

  /// AC8: with beat grid invoked alongside BPM under shared decode, the
  /// additional wall-clock vs BPM-only must be ≤ 25% per format (hard gate, with
  /// a measurement-noise allowance). Beat grid is a parallel step-11 output, so
  /// the marginal cost is the DP over the already-computed onset envelope + ACF.
  @Test func overheadGateAndReport() async throws {
    let corpus = try #require(SharedDecodeProbe.corpusPath())
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpus)

    let matchedSeconds = 120.0
    let measuredReps = 3
    let perFormatCap = 10
    // ≤ 25% overhead is the AC; the multiplicative margin folds in scheduler
    // noise on a shared machine. The absolute epsilon keeps the gate from
    // flaking on fast formats where the BPM-only median is small.
    let overheadMargin = 1.25
    let noiseEpsilonSeconds = 0.020

    func bpmOptions(beatGrid: Bool) -> BPMAnalyzer.Options {
      var opts = BPMAnalyzer.Options()
      opts.computeBeatGrid = beatGrid
      return opts
    }
    let bpmOnlyOptions = bpmOptions(beatGrid: false)
    let withGridOptions = bpmOptions(beatGrid: true)

    print("\n=== Story 8-4 beat-grid overhead (shared decode, maxSeconds=120) ===")
    #if DEBUG
      print("WARNING: Debug configuration — timings not representative. Use -c release.")
    #endif

    var perFormat: [String: BeatGridFormatImpact] = [:]
    for format in ProbeFormat.allCases {
      let candidates = byFormat[format] ?? []
      guard !candidates.isEmpty else { continue }
      let files = SharedDecodeProbe.select(candidates, cap: perFormatCap, seed: 0x8_4)

      var bpmOnlyMedians: [Double] = []
      var withGridMedians: [Double] = []
      for fileURL in files {
        // Decode ONCE (shared) — both paths run on the same carrier.
        let decoded = try PCMBufferReader.readDecodedAudio(
          from: fileURL, maxSeconds: matchedSeconds)

        // Warmups.
        _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: bpmOnlyOptions)
        _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: withGridOptions)

        var bpmOnly: [Double] = []
        var withGrid: [Double] = []
        for rep in 0..<measuredReps {
          // Alternate order per rep so neither path systematically benefits
          // from cache/codec state warmed by the other (SharedDecode review).
          if rep.isMultiple(of: 2) {
            bpmOnly.append(
              SharedDecodeProbe.time {
                _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: bpmOnlyOptions)
              })
            withGrid.append(
              SharedDecodeProbe.time {
                _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: withGridOptions)
              })
          } else {
            withGrid.append(
              SharedDecodeProbe.time {
                _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: withGridOptions)
              })
            bpmOnly.append(
              SharedDecodeProbe.time {
                _ = BPMAnalyzer.estimateBPM(decoded: decoded, options: bpmOnlyOptions)
              })
          }
        }
        bpmOnlyMedians.append(SharedDecodeProbe.median(bpmOnly))
        withGridMedians.append(SharedDecodeProbe.median(withGrid))
      }

      let bpmOnlyMedian = SharedDecodeProbe.median(bpmOnlyMedians)
      let withGridMedian = SharedDecodeProbe.median(withGridMedians)
      let overhead =
        bpmOnlyMedian > 0 ? (withGridMedian - bpmOnlyMedian) / bpmOnlyMedian : 0
      let gateMet = withGridMedian <= bpmOnlyMedian * overheadMargin + noiseEpsilonSeconds

      perFormat[format.rawValue] = BeatGridFormatImpact(
        bpmOnlyMedian: bpmOnlyMedian,
        withGridMedian: withGridMedian,
        overheadFraction: overhead,
        overheadGateMet: gateMet,
        fileCount: files.count)

      print(
        """
        \(format.rawValue) (n=\(files.count), reps=\(measuredReps)):
          BPM-only   = \(String(format: "%.4f", bpmOnlyMedian))s
          +beat grid = \(String(format: "%.4f", withGridMedian))s
          overhead   = \(String(format: "%.1f", overhead * 100))% (gate ≤ 25%)
          gateMet    = \(gateMet)
        """)

      #expect(
        gateMet,
        "AC8 beat-grid overhead gate FAILED for \(format.rawValue): +grid \(withGridMedian)s > BPM-only \(bpmOnlyMedian)s × \(overheadMargin) + \(noiseEpsilonSeconds)s"
      )
    }

    // Gates must not pass vacuously — the decode-heavy formats must be measured.
    #expect(perFormat["mp3"] != nil, "AC8 coverage: no mp3 files resolved from the corpus")
    #expect(perFormat["flac"] != nil, "AC8 coverage: no flac files resolved from the corpus")

    let outDir =
      ProcessInfo.processInfo.environment["BEAT_GRID_IMPACT_OUT_DIR"]
      ?? FileManager.default.currentDirectoryPath
    let report = BeatGridImpactReport(
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
      overheadMargin: overheadMargin,
      perFormat: perFormat)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let outURL = URL(fileURLWithPath: outDir)
      .appendingPathComponent("8-4-beat-grid-impact.json")
    try encoder.encode(report).write(to: outURL)
    print("beat-grid impact report written: \(outURL.path)")
  }
}
