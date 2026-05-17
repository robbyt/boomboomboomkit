//
//  SuperFluxImpactTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 4-7 Task 6 / AC #6 / DD #7 — per-track SuperFlux impact report.
//  Compares OA300 results with `.superFluxOnset` ON (`.optimal ∪ {.superFluxOnset}`)
//  vs OFF (`.optimal`), per-track, with named-DnB / DSP-correct-control flags
//  from `4-dnb-triplet-targets.json` (schema_version 3). Emits per-track rows +
//  aggregate counts (`changedRanking`, `changedFinalBPM`, `namedDnBImproved`,
//  `controlsPreserved`, `total`) to
//  `_bmad-output/implementation-artifacts/4-7-super-flux-impact-report.json`.
//
//  Output schema is the story-tagged impact-report envelope (NOT the v3
//  harmonized perf+ml-impact envelope under perf-baselines/bnns-impact/) —
//  consistent with the Story 3-3 click-impact and Story 3-4 duration-impact
//  precedents.
//
//  Test skip discipline (per axiom-testing/skills/swift-testing.md:127-133 +
//  Story 4-6 P4/P15 lesson): suite-level `.disabled(if:)` for env-gated and
//  corpus-absent skips. Never `Issue.record + return` inside test bodies.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Suite

@Suite(
  "BPMAnalyzer — SuperFlux Impact (Story 4-7)",
  .disabled(if: ProcessInfo.processInfo.environment["SPECTRAL_FLUX_IMPACT"] != "1"),
  .disabled(if: (ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] ?? "").isEmpty)
)
struct SuperFluxImpactTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]
  private let namedDnB: [DnBTargetEntry]
  private let dspControls: [DnBControlEntry]
  private let dnbTargetsSchemaVersion: Int

  init() throws {
    let envCorpusPath = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] ?? ""
    self.corpusPath = try #require(
      envCorpusPath.isEmpty ? nil : envCorpusPath,
      "OA300_CORPUS_PATH env var required for SuperFlux impact report.")

    // OA300 ground truth.
    let gtURL = try #require(
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
        ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json"),
      "oa300-ground-truth.json fixture missing")
    let gtData = try Data(contentsOf: gtURL)
    self.groundTruth = try JSONDecoder().decode([OA300Track].self, from: gtData)

    // 4-dnb-triplet-targets.json (schema_version 3, contains named failures +
    // DSP-correct controls). Decoded with snake_case keys preserved.
    let dnbURL = try #require(
      Bundle.module.url(forResource: "4-dnb-triplet-targets", withExtension: "json")
        ?? Bundle.module.url(
          forResource: "Fixtures/4-dnb-triplet-targets", withExtension: "json"),
      "4-dnb-triplet-targets.json fixture missing")
    let dnbData = try Data(contentsOf: dnbURL)
    let dnbFile = try JSONDecoder().decode(DnBTargetsFileLite.self, from: dnbData)
    self.namedDnB = dnbFile.targets
    self.dspControls = dnbFile.dsp_correct_controls
    self.dnbTargetsSchemaVersion = dnbFile.schema_version
  }

  /// AC #6: per-track impact report. Branch decision driver — Task 7 parses
  /// this artifact to decide Branch A vs Branch B.
  @Test("per-track SuperFlux impact report on OA300", .timeLimit(.minutes(15)))
  func superFluxImpactReport() async throws {
    // Sanity: the fixture we depend on for Branch-A criterion must be at the
    // expected schema version. Refuse to run against stale or future-incompat
    // fixtures — protects the brutal-gate semantics.
    #expect(
      dnbTargetsSchemaVersion == 3,
      "4-dnb-triplet-targets.json schema_version mismatch (expected 3, got \(dnbTargetsSchemaVersion))"
    )
    #expect(namedDnB.count == 4, "Expected 4 named DnB triplets per Story 4-5/4-6")
    #expect(dspControls.count >= 4, "Expected >= 4 DSP-correct controls per Story 4-6 DD #4")

    let baselineTechniqueSet = TechniqueSet.optimal
    let variantTechniqueSet = TechniqueSet.optimal.inserting(.superFluxOnset)

    let namedDnBSet = Set(namedDnB.map(\.track_id))
    let dspControlsSet = Set(dspControls.map(\.track_id))

    struct Row: Sendable {
      let track: String
      let baselineBPM: Double?
      let variantBPM: Double?
      let groundTruth: Double
      let namedDnB: Bool
      let dspControl: Bool
    }

    let urls: [(String, URL, Double)] = groundTruth.compactMap { track in
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { return nil }
      return (track.filename, url, track.bpm)
    }

    let baseline = baselineTechniqueSet
    let variant = variantTechniqueSet

    let rows: [Row] = await withTaskGroup(of: Row?.self) { group in
      for (filename, url, gtBPM) in urls {
        group.addTask {
          do {
            let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
              from: url, maxSeconds: 120)
            let off = BPMAnalyzer.estimateBPM(
              samples: samples, sampleRate: sampleRate,
              options: .init(techniqueSet: baseline))
            let on = BPMAnalyzer.estimateBPM(
              samples: samples, sampleRate: sampleRate,
              options: .init(techniqueSet: variant))
            let trackIDStem = (filename as NSString).deletingPathExtension
            return Row(
              track: filename,
              baselineBPM: off?.bpm,
              variantBPM: on?.bpm,
              groundTruth: gtBPM,
              namedDnB: namedDnBSet.contains(trackIDStem)
                || namedDnBSet.contains(filename),
              dspControl: dspControlsSet.contains(trackIDStem)
                || dspControlsSet.contains(filename))
          } catch {
            return nil
          }
        }
      }
      var collected: [Row] = []
      for await row in group { if let row = row { collected.append(row) } }
      return collected
    }

    #expect(
      rows.count > 0,
      "SuperFlux impact report analyzed zero tracks; check OA300_CORPUS_PATH (\(corpusPath))")

    // DD #7 schema — per-track rows + aggregate counts.
    func acc1Correct(detected: Double?, expected: Double) -> Bool {
      guard let d = detected, expected > 0 else { return false }
      return abs(d - expected) / expected <= 0.02
    }
    func absErr(detected: Double?, expected: Double) -> Double {
      guard let d = detected else { return Double.infinity }
      return abs(d - expected)
    }

    var changedRanking = 0
    var changedFinalBPM = 0
    var namedDnBImproved = 0
    var controlsPreserved = 0
    var controlsTotal = 0
    var namedDnBTotal = 0

    var perTrackRows: [[String: Any]] = []
    perTrackRows.reserveCapacity(rows.count)
    for r in rows {
      let baselineCorrect = acc1Correct(detected: r.baselineBPM, expected: r.groundTruth)
      let variantCorrect = acc1Correct(detected: r.variantBPM, expected: r.groundTruth)
      let absErrBaseline = absErr(detected: r.baselineBPM, expected: r.groundTruth)
      let absErrVariant = absErr(detected: r.variantBPM, expected: r.groundTruth)

      // changedRanking proxy: any BPM change at all (post-disambiguation winner
      // changed). Mirrors the Story 3-3 click-impact pattern (changedRanking =
      // any pre-disambiguation winner change). For SuperFlux at the .optimal-set
      // level the same heuristic is appropriate — non-zero == "the variant
      // moved something".
      if r.baselineBPM != r.variantBPM {
        changedRanking += 1
      }
      if r.baselineBPM != r.variantBPM {
        changedFinalBPM += 1
      }

      if r.namedDnB {
        namedDnBTotal += 1
        // "improved" per AC #4: variant resolves a named failure that baseline
        // missed (variant correct AND baseline NOT correct).
        if variantCorrect && !baselineCorrect {
          namedDnBImproved += 1
        }
      }
      if r.dspControl {
        controlsTotal += 1
        // "preserved" per Story 4-6 / AC #4 second clause: variant remains
        // within ±0.5 BPM of ground truth (strict control-set tolerance).
        if let v = r.variantBPM, abs(v - r.groundTruth) <= 0.5 {
          controlsPreserved += 1
        }
      }

      perTrackRows.append([
        "track": r.track,
        "baseline_bpm": r.baselineBPM as Any,
        "with_variant_bpm": r.variantBPM as Any,
        "ground_truth": r.groundTruth,
        "baseline_correct": baselineCorrect,
        "variant_correct": variantCorrect,
        "named_dnb_track": r.namedDnB,
        "dsp_correct_control": r.dspControl,
        "abs_error_baseline": absErrBaseline.isFinite ? absErrBaseline : NSNull(),
        "abs_error_variant": absErrVariant.isFinite ? absErrVariant : NSNull(),
      ])
    }

    let aggregate: [String: Any] = [
      "changedRanking": changedRanking,
      "changedFinalBPM": changedFinalBPM,
      "namedDnBImproved": namedDnBImproved,
      "namedDnBTotal": namedDnBTotal,
      "controlsPreserved": controlsPreserved,
      "controlsTotal": controlsTotal,
      "total": groundTruth.count,
      "analyzed": rows.count,
      "failed": groundTruth.count - rows.count,
    ]

    // Build provenance block matching Story 4-6 fixture conventions.
    let env = ProcessInfo.processInfo.environment
    let gitSHA = env["GIT_SHA"] ?? "unknown"
    let now = ISO8601DateFormatter()
    now.formatOptions = [.withInternetDateTime]
    let provenance: [String: Any] = [
      "captured_at": now.string(from: Date()),
      "captured_by": "Story 4-7 SuperFluxImpactTests",
      "git_sha": gitSHA,
      "macos_version": ProcessInfo.processInfo.operatingSystemVersionString,
      "tool": "swift test --filter BoomBoomBoomKitBenchmarkTests.SuperFluxImpactTests",
    ]

    let payload: [String: Any] = [
      "schema_version": 1,
      "story": "4-7",
      "description":
        "Per-track SuperFlux on-vs-off impact report (Branch A/B decision driver). Compares .optimal vs .optimal ∪ {.superFluxOnset} per-track.",
      "captured_with": provenance,
      "baseline_techniqueSet": "optimal",
      "variant_techniqueSet": "optimal+superFlux",
      "aggregate": aggregate,
      "rows": perTrackRows,
    ]

    // Console summary
    print("\n=== Per-Track SuperFlux Impact Report (OA300) ===")
    print("Total tracks (ground truth): \(groundTruth.count)")
    print("Tracks analyzed:             \(rows.count)")
    print("Tracks failed/missing:       \(groundTruth.count - rows.count)")
    print("changedRanking:              \(changedRanking)")
    print("changedFinalBPM:             \(changedFinalBPM)")
    print("namedDnBImproved:            \(namedDnBImproved) / \(namedDnBTotal)")
    print("controlsPreserved:           \(controlsPreserved) / \(controlsTotal)")

    if let dir = ProcessInfo.processInfo.environment["SUPER_FLUX_IMPACT_OUT_DIR"] {
      let url = URL(fileURLWithPath: dir)
        .appendingPathComponent("4-7-super-flux-impact-report.json")
      let data = try JSONSerialization.data(
        withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
      try data.write(to: url)
      print("SuperFlux impact report written to \(url.path)")
    }
  }

  // MARK: - Helpers

  private func trackURL(_ track: OA300Track, corpusPath: String) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }
}

// MARK: - Local DnB targets decoder (lite — file is also decoded fully by BNNSImpactTests)

/// File-local decoder for `4-dnb-triplet-targets.json` that only pulls the
/// fields SuperFluxImpactTests needs. Story 4-7 explicitly avoids depending on
/// BNNSImpactTests' `DnBTargetsFile` symbol (different test file, different
/// suite) so the impact harness is self-contained.
private struct DnBTargetsFileLite: Decodable {
  let schema_version: Int  // swiftlint:disable:this identifier_name
  let targets: [DnBTargetEntry]
  let dsp_correct_controls: [DnBControlEntry]  // swiftlint:disable:this identifier_name
}

private struct DnBTargetEntry: Decodable {
  let track_id: String  // swiftlint:disable:this identifier_name
  let ground_truth_bpm: Double  // swiftlint:disable:this identifier_name
}

private struct DnBControlEntry: Decodable {
  let track_id: String  // swiftlint:disable:this identifier_name
  let ground_truth_bpm: Double  // swiftlint:disable:this identifier_name
}
