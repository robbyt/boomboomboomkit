//
//  BNNSImpactTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 4-5 Task 7 — env-gated impact-report harness for BNNSTechnique
//  against the OA300 corpus. Triggered by `make bnns-impact-report` (which
//  sets `BNNS_IMPACT=1` + `BNNS_IMPACT_OUT_DIR`); deliberately NOT run by
//  the unit-test `make test`.
//
//  Pinned config per Story 4-5 AC #7 (Codex MAJOR #9 resolution):
//    intensity = .thorough  (forces ML path activation at intensity 8)
//    ensemblePolicy = .mlOnly  (isolates ML signal; ML abstain falls back to DSP)
//
//  The test produces `4-5-bnns-impact-report.json` per AC #8 schema and
//  asserts ≥ 2 of 4 named DnB triplets resolved within ±0.5 BPM (HALT (b)).
//

import BoomBoomBoomKit
import BoomBoomBoomKitML
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

// MARK: - JSON schema

private struct BNNSImpactReport: Codable, Sendable {
  let schema_version: Int
  let snapshot_sha: String
  let model_identifier: String
  let pinned_config: PinnedConfig
  let named_dnb_track_results: [NamedDnBResult]
  let all_tracks: [TrackRow]
  let summary: Summary
}

private struct PinnedConfig: Codable, Sendable {
  let intensity: Int
  let ensemble_policy: String
}

private struct NamedDnBResult: Codable, Sendable {
  let track_id: String
  let ground_truth_bpm: Double
  let ensemble_winner_bpm: Double
  let abs_error_bpm: Double
  let resolved_within_05: Bool
}

private struct TrackRow: Codable, Sendable {
  let track: String
  let dsp_winner: Double
  let ml_winner: Double?
  let ensemble_winner: Double
  let ml_confidence: Double?
  let ground_truth: Double
  let dsp_correct: Bool
  let ml_correct: Bool?
  let ensemble_correct: Bool
  let named_dnb_track: Bool
  let latency_ms: Double
}

private struct Summary: Codable, Sendable {
  let total_tracks: Int
  let dsp_acc1: Int
  let ml_acc1: Int
  let ensemble_acc1: Int
  let named_dnb_resolved: Int
  let named_dnb_total: Int
}

// MARK: - Suite

@Suite(
  "Story 4-5 BNNSImpact",
  .enabled(if: ProcessInfo.processInfo.environment["BNNS_IMPACT"] == "1")
)
struct BNNSImpactTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard
      let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"],
      !path.isEmpty
    else {
      throw BNNSImpactError.corpusPathNotSet
    }
    corpusPath = path

    let url =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url else {
      throw BNNSImpactError.groundTruthNotFound
    }
    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: data)
  }

  private func trackURL(_ track: OA300Track) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath)
      .appendingPathComponent(track.filename)
  }

  /// Set of filename substrings identifying the 4 named DnB triplet tracks
  /// per `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json`.
  /// Matching is substring-based to tolerate the various filename suffixes
  /// across the corpus (.aiff vs .wav, etc.).
  private static let namedDnBPatterns: [String] = [
    "1. The Faraday_Bunker",
    "4. Yin Yang Audio",
    "9. HEFT_Anagram 6",
    "06 Charly (Neekeetone Jungle Rework)",
  ]

  private func isNamedDnB(_ filename: String) -> Bool {
    Self.namedDnBPatterns.contains { filename.contains($0) }
  }

  @Test(
    "bnnsImpactReport (BNNS_IMPACT=1)",
    .enabled(if: ProcessInfo.processInfo.environment["BNNS_IMPACT"] == "1")
  )
  func bnnsImpactReport() async throws {
    if #available(macOS 15.0, *) {
      guard (try? BNNSTechnique()) != nil else {
        let msg =
          "BNNSTechnique unavailable — model artifact missing at"
          + " Sources/BoomBoomBoomKitML/Resources/giantsteps_v1.mlmodelc"
        Issue.record(Comment(rawValue: msg))
        return
      }

      // Pre-filter the corpus to readable tracks. PCMBufferReader may
      // reject a few files with unsupported codecs; we just skip them so
      // the impact report reflects only what the pipeline can process.
      let candidateTracks = groundTruth.filter { track in
        FileManager.default.fileExists(atPath: trackURL(track).path)
      }

      var allRows: [TrackRow] = []
      allRows.reserveCapacity(candidateTracks.count)
      var dspAcc1 = 0
      var mlAcc1 = 0
      var ensembleAcc1 = 0
      var namedDnBResolved = 0

      for track in candidateTracks {
        let url = trackURL(track)

        // DSP-only baseline.
        var dspOpts = AudioAnalysisService.Options()
        dspOpts.intensity = .default  // intensity 7
        dspOpts.ensemblePolicy = .dspOnly
        let dspBPM: Double =
          (try? AudioAnalysisService.analyzeBPM(
            url: url, options: dspOpts))?.bpm ?? 0.0

        // BNNS-ML path: pinned impact-report config.
        var bnnsOpts = AudioAnalysisService.Options()
        bnnsOpts.intensity = .thorough  // intensity 8 — activates ML path
        bnnsOpts.ensemblePolicy = .mlOnly
        bnnsOpts.enableTrace = true  // trace.ensembleDecision needed for ml_winner
        bnnsOpts.mlTechnique = try? BNNSTechnique()

        let startTime = Date()
        let bnnsResult = try? AudioAnalysisService.analyzeBPM(
          url: url, options: bnnsOpts)
        let latency = Date().timeIntervalSince(startTime) * 1000.0

        let ensembleBPM = bnnsResult?.bpm ?? dspBPM
        // `EnsembleDecision` carries `selectedBPM` + winner enum but not a
        // separate `mlBPM` field — ML's BPM is the same as `selectedBPM`
        // when `winner == .ml`. When `winner == .dsp` (incl. ML abstain),
        // there's no ML BPM to surface.
        let decision = bnnsResult?.trace?.ensembleDecision
        let mlBPM: Double? = (decision?.winner == .ml) ? decision?.selectedBPM : nil
        let mlConfidence: Double? = decision?.mlConfidence

        let gt = track.bpm
        let dspCorrect = abs(dspBPM - gt) / max(gt, 1.0) < 0.02
        let mlCorrectOpt: Bool? = mlBPM.map { abs($0 - gt) / max(gt, 1.0) < 0.02 }
        let ensembleCorrect = abs(ensembleBPM - gt) / max(gt, 1.0) < 0.02

        if dspCorrect { dspAcc1 += 1 }
        if mlCorrectOpt == true { mlAcc1 += 1 }
        if ensembleCorrect { ensembleAcc1 += 1 }

        let namedDnB = isNamedDnB(track.filename)
        if namedDnB && abs(ensembleBPM - gt) < 0.5 {
          namedDnBResolved += 1
        }

        allRows.append(
          TrackRow(
            track: track.filename,
            dsp_winner: dspBPM,
            ml_winner: mlBPM,
            ensemble_winner: ensembleBPM,
            ml_confidence: mlConfidence,
            ground_truth: gt,
            dsp_correct: dspCorrect,
            ml_correct: mlCorrectOpt,
            ensemble_correct: ensembleCorrect,
            named_dnb_track: namedDnB,
            latency_ms: latency))
      }

      // Sort all_tracks by filename for byte-stable JSON output.
      allRows.sort { $0.track < $1.track }

      let namedRows = allRows.filter { $0.named_dnb_track }
      let namedResults: [NamedDnBResult] = namedRows.map { row in
        NamedDnBResult(
          track_id: row.track,
          ground_truth_bpm: row.ground_truth,
          ensemble_winner_bpm: row.ensemble_winner,
          abs_error_bpm: abs(row.ensemble_winner - row.ground_truth),
          resolved_within_05: abs(row.ensemble_winner - row.ground_truth) < 0.5)
      }

      let report = BNNSImpactReport(
        schema_version: 1,
        snapshot_sha: ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown",
        model_identifier: "bnns_tempo_v1",
        pinned_config: PinnedConfig(
          intensity: AnalysisIntensity.thorough.rawValue,
          ensemble_policy: String(describing: EnsemblePolicy.mlOnly)),
        named_dnb_track_results: namedResults,
        all_tracks: allRows,
        summary: Summary(
          total_tracks: allRows.count,
          dsp_acc1: dspAcc1,
          ml_acc1: mlAcc1,
          ensemble_acc1: ensembleAcc1,
          named_dnb_resolved: namedDnBResolved,
          named_dnb_total: namedRows.count))

      // Resolve output path. BNNS_IMPACT_OUT_DIR overrides the default;
      // falls back to TMPDIR if neither env var is set.
      let outDir: String =
        ProcessInfo.processInfo.environment["BNNS_IMPACT_OUT_DIR"]
        ?? NSTemporaryDirectory()
      let outPath = (outDir as NSString)
        .appendingPathComponent("4-5-bnns-impact-report.json")

      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(report)
      try data.write(to: URL(fileURLWithPath: outPath))

      // Console summary.
      print(
        """

        === BNNS Impact Report ===
        Output: \(outPath)
        Total tracks: \(allRows.count)
        DSP-only Acc1:    \(dspAcc1)/\(allRows.count)
        ML-only Acc1:     \(mlAcc1)/\(allRows.count)
        Ensemble Acc1:    \(ensembleAcc1)/\(allRows.count)
        Named DnB resolved (±0.5 BPM): \(namedDnBResolved)/\(namedRows.count)
        """)
      for r in namedResults {
        let line =
          "  - \(r.track_id): ensemble=\(r.ensemble_winner_bpm) gt=\(r.ground_truth_bpm)"
          + " abs_err=\(r.abs_error_bpm) resolved=\(r.resolved_within_05)"
        print(line)
      }

      // HALT (b): assert ≥ 2 of 4 named DnB triplets resolved within ±0.5 BPM.
      // Soft-record below the threshold so the JSON is still written
      // (developer needs the per-track breakdown to triage); the test
      // result still fails for ratchet enforcement.
      if namedDnBResolved < 2 {
        let msg =
          "HALT (b): only \(namedDnBResolved) of \(namedRows.count) named"
          + " DnB triplets resolved within ±0.5 BPM (required ≥ 2)."
          + " See \(outPath) for per-track failure modes."
        Issue.record(Comment(rawValue: msg))
      }
    }
  }
}

private enum BNNSImpactError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
}
