//
//  OctaveFoldImpactTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  GH-141 AC: per-band net-impact measurement for the decode-time octave
//  fold. The plan (`v2-runs/octave-bias-finding-and-plan.md`) requires this
//  before the fold's default can change, because a prefer-fundamental rule
//  can damage the 120-175 BPM bands that hold most of the corpus.
//
//  Env-gated (`OCTAVE_FOLD_IMPACT=1` + `BNNS_MODEL_URL` +
//  `GIANTSTEPS_CORPUS_PATH`); never runs in `make test`.
//
//  ONE inference pass covers every threshold. Running with the fold at
//  threshold 0.0 makes the decoder fold whenever a fold is possible at all,
//  and the resulting `MLDiagnosticSnapshot.Decode.octaveFold` carries both
//  the pre-fold BPM and the exact mass ratio. The decode any other
//  threshold `t` would have produced is therefore reconstructible offline:
//  it is the folded value when `massRatio >= t` and `fromBPM` otherwise. A
//  track with no fold record could not fold at any threshold. That turns an
//  N-threshold sweep from N corpus passes into one.
//

import BoomBoomBoomKitTestSupport
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

// MARK: - Report shapes

private struct FoldTrackRow: Codable {
  let trackID: String
  let truthBPM: Double
  /// Bare-argmax decode: the model's tempo before any fold.
  let unfoldedBPM: Double
  /// Non-nil only when a fold was possible; the ratio that a threshold is
  /// compared against.
  let massRatio: Double?
  let foldedBPM: Double?
}

private struct BandResult: Codable {
  let band: String
  let n: Int
  let acc1Unfolded: Int
  let acc1Folded: Int
  let acc2Unfolded: Int
  let acc2Folded: Int
  /// Positive means the fold helped this band; negative means it hurt.
  var acc1Delta: Int { acc1Folded - acc1Unfolded }
}

private struct ThresholdResult: Codable {
  let threshold: Double
  let foldsFired: Int
  let bands: [BandResult]
  let acc1Unfolded: Int
  let acc1Folded: Int
  var netAcc1Delta: Int { acc1Folded - acc1Unfolded }
}

private struct FoldImpactReport: Codable {
  let corpus: String
  let modelPath: String
  /// SHA-256 over the compiled bundle's contents. A path alone is mutable
  /// and cannot substantiate which weights produced these numbers.
  let modelDigest: String
  let gitSHA: String
  let tracksInGroundTruth: Int
  let tracksEvaluated: Int
  let tracksAbstained: Int
  /// Ground-truth entries whose audio was not on disk. Reported separately
  /// from abstains so a partial corpus can never read as a full one.
  let tracksMissingAudio: Int
  let thresholds: [ThresholdResult]
  let perTrack: [FoldTrackRow]
}

// MARK: - Bands (the E0 diagnostic's bands, so results are comparable)

/// Half-open BPM bands, matching the E0 diagnostic so results line up with
/// `octave-bias-finding-and-plan.md`. Expressed as bounds rather than
/// closures because a global of function values is not `Sendable`.
private struct Band: Sendable {
  let name: String
  let lower: Double
  let upper: Double
  func contains(_ bpm: Double) -> Bool { bpm >= lower && bpm < upper }
}

private let bands: [Band] = [
  Band(name: "<100", lower: 0, upper: 100),
  Band(name: "100-120", lower: 100, upper: 120),
  Band(name: "120-140", lower: 120, upper: 140),
  Band(name: "140-160", lower: 140, upper: 160),
  Band(name: "160-175", lower: 160, upper: 175),
  Band(name: "175+", lower: 175, upper: .infinity),
]

/// Acc1: within 4% of truth, the convention the calibration ladder used.
private func acc1(_ pred: Double, _ truth: Double) -> Bool {
  truth > 0 && abs(pred - truth) / truth <= 0.04
}

/// Acc2: Acc1 or octave-equivalent at half/double.
private func acc2(_ pred: Double, _ truth: Double) -> Bool {
  acc1(pred, truth) || acc1(pred * 2, truth) || acc1(pred / 2, truth)
}

/// SHA-256 over every regular file in a `.mlmodelc` bundle, folded in
/// sorted-path order so the digest is stable across filesystem enumeration
/// order.
@available(macOS 15.0, *)
private func bundleDigest(_ url: URL) -> String {
  let fm = FileManager.default
  guard
    let e = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey])
  else { return "unavailable" }
  var paths: [URL] = []
  for case let f as URL in e {
    if (try? f.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
      paths.append(f)
    }
  }
  var hasher = SHA256()
  for f in paths.sorted(by: { $0.path < $1.path }) {
    hasher.update(data: Data(f.path.replacingOccurrences(of: url.path, with: "").utf8))
    if let d = try? Data(contentsOf: f) { hasher.update(data: d) }
  }
  return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

@Suite(
  "GH-141 octave-fold per-band impact",
  .enabled(if: ProcessInfo.processInfo.environment["OCTAVE_FOLD_IMPACT"] == "1"))
struct OctaveFoldImpactTests {

  @Test("octaveFoldImpactReport (OCTAVE_FOLD_IMPACT=1)")
  @available(macOS 15.0, *)
  func octaveFoldImpactReport() async throws {
    let env = ProcessInfo.processInfo.environment
    let modelPath = try #require(
      env["BNNS_MODEL_URL"].flatMap { $0.isEmpty ? nil : $0 },
      Comment(
        rawValue:
          "BNNS_MODEL_URL must point at a compiled .mlmodelc. This harness measures a"
          + " MODEL's decode behaviour; without one there is nothing to measure and a"
          + " silent pass would read as 'no impact'."))
    let corpusPath = try #require(
      env["GIANTSTEPS_CORPUS_PATH"].flatMap { $0.isEmpty ? nil : $0 },
      Comment(
        rawValue:
          "GIANTSTEPS_CORPUS_PATH must be set — the E0 bands are GiantSteps bands."))
    let outDir = try #require(
      env["OCTAVE_FOLD_OUT_DIR"].flatMap { $0.isEmpty ? nil : $0 },
      Comment(
        rawValue:
          "OCTAVE_FOLD_OUT_DIR must be set so the report lands somewhere reviewable."))

    // Threshold 0.0: fold wherever a fold is possible, and record the
    // ratio. Every other threshold is reconstructed from those records.
    var opts = BNNSTechnique.Options()
    opts.octaveFold = .massRatio(threshold: 0.0)
    // Gates fully open: this measures DECODE, not the abstain policy. A
    // closed gate would silently shrink the denominator and make the fold
    // look better or worse than it is.
    opts.confidenceThreshold = 0.0
    opts.marginThreshold = 0.0
    let technique = try BNNSTechnique(
      modelURL: URL(fileURLWithPath: modelPath), options: opts)

    let jsonPath = (corpusPath as NSString).appendingPathComponent(
      "giantsteps-tempo-ground-truth.json")
    let tracks = try JSONDecoder().decode(
      [GiantStepsTrack].self, from: Data(contentsOf: URL(fileURLWithPath: jsonPath)))

    var rows: [FoldTrackRow] = []
    var abstained = 0
    var missingAudio = 0

    for track in tracks {
      let url = URL(fileURLWithPath: corpusPath)
        .appendingPathComponent("audio")
        .appendingPathComponent(track.filename)
      guard FileManager.default.fileExists(atPath: url.path) else {
        missingAudio += 1
        continue
      }

      var options = AudioAnalysisService.Options()
      options.enableTrace = true
      options.enableMLDiagnostics = true
      // BOTH of these are required for the trace to carry `mlFeatures` at
      // all: `AudioAnalysisService.swift:1248` gates `captureMLFeatures` on
      // `enableTrace && mlTechnique != nil && ensemblePolicy.invokesMLInference`,
      // and `.dspOnly` is the one policy for which the last term is false.
      // Setting only the diagnostics flag yields a trace with no features,
      // which abstains every track and reports a silently empty corpus.
      options.mlTechnique = technique
      options.ensemblePolicy = .mlOnly

      let analysis = try? AudioAnalysisService.analyzeBPM(url: url, options: options)
      // Read the snapshot the service already produced rather than
      // re-invoking the technique: one inference per track, and the decode
      // measured is the one the real runtime path produced.
      guard let decode = analysis?.trace?.mlDiagnosticSnapshot?.decode else {
        abstained += 1
        continue
      }
      if let fold = decode.octaveFold {
        rows.append(
          FoldTrackRow(
            trackID: track.track_id, truthBPM: track.bpm,
            unfoldedBPM: fold.fromBPM, massRatio: fold.massRatio,
            foldedBPM: decode.bpm))
      } else {
        rows.append(
          FoldTrackRow(
            trackID: track.track_id, truthBPM: track.bpm,
            unfoldedBPM: decode.bpm, massRatio: nil, foldedBPM: nil))
      }
    }

    try #require(
      !rows.isEmpty,
      Comment(
        rawValue:
          "no tracks decoded — refusing to emit a report whose every band is 0/0"))

    // Reconstruct the sweep.
    let sweep: [Double] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    var thresholdResults: [ThresholdResult] = []
    for t in sweep {
      var bandResults: [BandResult] = []
      var fired = 0
      for band in bands {
        let inBandRows = rows.filter { band.contains($0.truthBPM) }
        var a1u = 0
        var a1f = 0
        var a2u = 0
        var a2f = 0
        for r in inBandRows {
          let folded: Double
          if let ratio = r.massRatio, let fb = r.foldedBPM, ratio >= t {
            folded = fb
            fired += 1
          } else {
            folded = r.unfoldedBPM
          }
          if acc1(r.unfoldedBPM, r.truthBPM) { a1u += 1 }
          if acc1(folded, r.truthBPM) { a1f += 1 }
          if acc2(r.unfoldedBPM, r.truthBPM) { a2u += 1 }
          if acc2(folded, r.truthBPM) { a2f += 1 }
        }
        bandResults.append(
          BandResult(
            band: band.name, n: inBandRows.count, acc1Unfolded: a1u, acc1Folded: a1f,
            acc2Unfolded: a2u, acc2Folded: a2f))
      }
      thresholdResults.append(
        ThresholdResult(
          threshold: t, foldsFired: fired, bands: bandResults,
          acc1Unfolded: bandResults.reduce(0) { $0 + $1.acc1Unfolded },
          acc1Folded: bandResults.reduce(0) { $0 + $1.acc1Folded }))
    }

    // Every ground-truth entry must be accounted for in exactly one
    // bucket. Without this a partially-present corpus would produce a
    // confident-looking report over a silent subset.
    #expect(
      rows.count + abstained + missingAudio == tracks.count,
      Comment(
        rawValue:
          "accounting mismatch: \(rows.count) decoded + \(abstained) abstained +"
          + " \(missingAudio) missing != \(tracks.count) ground-truth entries"))

    let gitSHA = env["GIT_SHA"] ?? "unknown"
    #expect(
      gitSHA != "unknown",
      Comment(
        rawValue:
          "GIT_SHA is unset, so this artifact cannot be attributed to a commit."
          + " Run via `make octave-fold-impact-report`, which sets it."))

    let report = FoldImpactReport(
      corpus: "giantsteps", modelPath: modelPath,
      modelDigest: bundleDigest(URL(fileURLWithPath: modelPath)),
      gitSHA: gitSHA,
      tracksInGroundTruth: tracks.count,
      tracksEvaluated: rows.count, tracksAbstained: abstained,
      tracksMissingAudio: missingAudio,
      thresholds: thresholdResults, perTrack: rows)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let outURL = URL(fileURLWithPath: outDir)
      .appendingPathComponent("141-octave-fold-impact.json")
    try encoder.encode(report).write(to: outURL)

    // Per-band print. Never a bare aggregate: a net-positive total can hide
    // a band the fold wrecked, which is the exact failure the plan warns
    // about.
    print(
      "\nGH-141 octave-fold impact — \(rows.count) decoded, \(abstained) abstained,"
        + " \(missingAudio) missing, of \(tracks.count) ground-truth entries")
    print("model: \(modelPath)")
    for tr in thresholdResults {
      print(
        "\nthreshold \(String(format: "%.1f", tr.threshold)) — "
          + "\(tr.foldsFired) folds, net Acc1 \(tr.netAcc1Delta >= 0 ? "+" : "")\(tr.netAcc1Delta)"
          + " (\(tr.acc1Unfolded) -> \(tr.acc1Folded))")
      for b in tr.bands where b.n > 0 {
        print(
          "    \(b.band.padding(toLength: 9, withPad: " ", startingAt: 0))"
            + " n=\(b.n)  Acc1 \(b.acc1Unfolded)->\(b.acc1Folded)"
            + " (\(b.acc1Delta >= 0 ? "+" : "")\(b.acc1Delta))"
            + "  Acc2 \(b.acc2Unfolded)->\(b.acc2Folded)")
      }
    }
    print("\nReport: \(outURL.path)")
    print(
      "NOTE: this is a decode measurement at open gates. It does not by itself"
        + " authorize flipping the default — read the per-band deltas, not the net.")
  }
}
