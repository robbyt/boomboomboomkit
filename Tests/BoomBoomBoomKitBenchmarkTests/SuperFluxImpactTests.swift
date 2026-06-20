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
  /// DnB named-failure `track_id`s (the `target` partition of the JAMS corpus).
  private let namedDnB: [String]
  /// DSP-correct control `track_id`s (the `control` partition of the JAMS corpus).
  private let dspControls: [String]
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
    self.groundTruth = try OA300Track.loadCorpus(from: gtData)

    // 4-dnb-triplet-targets.json (schema_version 3, contains named failures +
    // DSP-correct controls). Story 8.8c: a JAMS corpus — `partition` discriminates
    // target vs control, `schema_version` rides the corpus sandbox.
    let dnbURL = try #require(
      Bundle.module.url(forResource: "4-dnb-triplet-targets", withExtension: "json")
        ?? Bundle.module.url(
          forResource: "Fixtures/4-dnb-triplet-targets", withExtension: "json"),
      "4-dnb-triplet-targets.json fixture missing")
    let dnbData = try Data(contentsOf: dnbURL)
    let dnbCorpus = try JSONDecoder().decode(JAMSCorpus.self, from: dnbData)
    // `dnbPartitioned()` requires every entry to carry a non-nil track_id and a known
    // partition (throws otherwise), so a partition typo or missing track_id fails loudly
    // at suite init instead of being silently dropped from the brutal-gate coverage sets.
    let (dnbTargets, dnbControls) = try dnbCorpus.dnbPartitioned()
    self.namedDnB = dnbTargets.map(\.trackID)
    self.dspControls = dnbControls.map(\.trackID)
    self.dnbTargetsSchemaVersion = try #require(
      dnbCorpus.sandbox?.schemaVersion, "DnB corpus sandbox missing schema_version")
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

    let namedDnBSet = Set(namedDnB)
    let dspControlsSet = Set(dspControls)

    // P7 (Codex review 2026-05-17): Row.baselineBPM / variantBPM are non-optional.
    // A silent analyzer abstain on a known-good fixture is a gate failure, not a
    // legitimate alternative outcome — both sides must produce a BPM or the task
    // throws ImpactReportError.analyzerAbstained.
    struct Row: Sendable {
      let track: String
      let baselineBPM: Double
      let variantBPM: Double
      let groundTruth: Double
      let namedDnB: Bool
      let dspControl: Bool
    }

    // P1a (Codex review 2026-05-17): preflight missing fixtures into an inventory
    // and surface the full list via Issue.record. Continue with whatever resolved
    // so the rest of the gate can run on the surviving subset.
    var resolvedUrls: [(String, URL, Double)] = []
    var missingFixtures: [(filename: String, expectedAt: String)] = []
    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      if FileManager.default.fileExists(atPath: url.path) {
        resolvedUrls.append((track.filename, url, track.bpm))
      } else {
        missingFixtures.append((track.filename, url.path))
      }
    }
    if !missingFixtures.isEmpty {
      let inventory = missingFixtures.map { "\($0.filename) @ \($0.expectedAt)" }
        .joined(separator: "; ")
      Issue.record(
        "Brutal-corpus gate fixture inventory failed: \(missingFixtures.count) missing files. \(inventory)"
      )
    }
    let urls = resolvedUrls

    let baseline = baselineTechniqueSet
    let variant = variantTechniqueSet

    // P1b: collect-then-fail. Each task returns Result<Row, ImpactReportError>
    // so analyzer failures are inventoried as a group rather than throwing on the
    // first race winner.
    let taskResults: [Result<Row, ImpactReportError>] = await withTaskGroup(
      of: Result<Row, ImpactReportError>.self
    ) { group in
      for (filename, url, gtBPM) in urls {
        group.addTask {
          do {
            let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
              from: url, maxSeconds: 120)
            let off = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(techniqueSet: baseline))
            let on = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(techniqueSet: variant))
            // P7: a silent abstain on a corpus fixture is a gate failure.
            guard let baselineBPM = off?.bpm else {
              return .failure(.analyzerAbstained(track: filename, side: "baseline"))
            }
            guard let variantBPM = on?.bpm else {
              return .failure(.analyzerAbstained(track: filename, side: "variant"))
            }
            let trackIDStem = (filename as NSString).deletingPathExtension
            return .success(
              Row(
                track: filename,
                baselineBPM: baselineBPM,
                variantBPM: variantBPM,
                groundTruth: gtBPM,
                namedDnB: namedDnBSet.contains(trackIDStem)
                  || namedDnBSet.contains(filename),
                dspControl: dspControlsSet.contains(trackIDStem)
                  || dspControlsSet.contains(filename)))
          } catch {
            return .failure(.analyzerFailure(track: filename, underlying: error))
          }
        }
      }
      var collected: [Result<Row, ImpactReportError>] = []
      for await item in group { collected.append(item) }
      return collected
    }

    var rows: [Row] = []
    var analyzerFailures: [ImpactReportError] = []
    for r in taskResults {
      switch r {
      case .success(let row): rows.append(row)
      case .failure(let err): analyzerFailures.append(err)
      }
    }
    rows.sort { $0.track < $1.track }  // P12: deterministic JSON ordering
    if !analyzerFailures.isEmpty {
      let inventory = analyzerFailures.map(\.description).joined(separator: "; ")
      Issue.record(
        "Brutal-corpus gate analyzer failures: \(analyzerFailures.count). \(inventory)")
    }
    let inventoryFailuresRecorded = !missingFixtures.isEmpty || !analyzerFailures.isEmpty

    #expect(
      rows.count > 0,
      "SuperFlux impact report analyzed zero tracks; check OA300_CORPUS_PATH (\(corpusPath))")

    // DD #7 schema — per-track rows + aggregate counts.
    func acc1Correct(detected: Double, expected: Double) -> Bool {
      guard expected > 0 else { return false }
      return abs(detected - expected) / expected <= 0.02
    }

    // P6 (Codex review 2026-05-17): drop fake `changedRanking` counter. The
    // earlier code incremented it under the same predicate as changedFinalBPM,
    // producing duplicate telemetry. If a future story wants real ranking
    // semantics (pre-vs-post-disambiguation winner), it must introduce a new
    // field with real distinction (re-run with `enableTrace: true` and compare
    // `trace.rawCandidates`).
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
      let absErrBaseline = abs(r.baselineBPM - r.groundTruth)
      let absErrVariant = abs(r.variantBPM - r.groundTruth)

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
        if abs(r.variantBPM - r.groundTruth) <= 0.5 {
          controlsPreserved += 1
        }
      }

      // P11 (post-P7): baseline_bpm and with_variant_bpm are plain Double now;
      // no `as Any` cast or NSNull fallback needed. abs_error_* retain
      // isFinite ? value : NSNull() in case of future ground-truth changes.
      perTrackRows.append([
        "track": r.track,
        "baseline_bpm": r.baselineBPM,
        "with_variant_bpm": r.variantBPM,
        "ground_truth": r.groundTruth,
        "baseline_correct": baselineCorrect,
        "variant_correct": variantCorrect,
        "named_dnb_track": r.namedDnB,
        "dsp_correct_control": r.dspControl,
        "abs_error_baseline": absErrBaseline.isFinite ? absErrBaseline : NSNull(),
        "abs_error_variant": absErrVariant.isFinite ? absErrVariant : NSNull(),
      ])
    }

    // P1c (Codex review 2026-05-17): assert fixture-ID coverage AFTER row
    // classification so the counters/sets are populated. Gated on no prior
    // inventory failures so one root cause doesn't fan out into multiple
    // assertions firing.
    if !inventoryFailuresRecorded {
      let actualNamedDnBIDs = Set(rows.filter(\.namedDnB).map(\.track))
      let actualControlIDs = Set(rows.filter(\.dspControl).map(\.track))
      let actualNamedDnBStems = Set(
        actualNamedDnBIDs.map { ($0 as NSString).deletingPathExtension })
      let actualControlStems = Set(
        actualControlIDs.map { ($0 as NSString).deletingPathExtension })
      let expectedNamedDnBIDs = Set(namedDnB)
      let expectedControlIDs = Set(dspControls)
      let missingNamedDnB = expectedNamedDnBIDs.subtracting(actualNamedDnBStems)
        .subtracting(actualNamedDnBIDs)
      let missingControls = expectedControlIDs.subtracting(actualControlStems)
        .subtracting(actualControlIDs)
      #expect(
        missingNamedDnB.isEmpty,
        "Brutal-corpus gate fixture coverage: \(missingNamedDnB.count) named-DnB IDs missing from rows: \(missingNamedDnB.sorted()). Check 4-dnb-triplet-targets.json filename-matching logic."
      )
      #expect(
        missingControls.isEmpty,
        "Brutal-corpus gate fixture coverage: \(missingControls.count) DSP-control IDs missing from rows: \(missingControls.sorted())."
      )
    }

    let aggregate: [String: Any] = [
      "changedFinalBPM": changedFinalBPM,
      "namedDnBImproved": namedDnBImproved,
      "namedDnBTotal": namedDnBTotal,
      "controlsPreserved": controlsPreserved,
      "controlsTotal": controlsTotal,
      "total": groundTruth.count,
      "analyzed": rows.count,
      "missing_fixtures": missingFixtures.count,
      "analyzer_failures": analyzerFailures.count,
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
      "xcode_version": env["XCODE_VERSION"] ?? "unknown",
      "swift_version": env["SWIFT_VERSION"] ?? "unknown",
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
    print("Missing fixtures:            \(missingFixtures.count)")
    print("Analyzer failures:           \(analyzerFailures.count)")
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

// MARK: - Impact-report failure inventory (Codex review 2026-05-17 P1)

/// Failure carried inside `Result<Row, ImpactReportError>` from each task in
/// the impact-report task group. Collect-then-fail semantics let the operator
/// see every failure in one inventory rather than whichever task lost the race.
private enum ImpactReportError: Error, CustomStringConvertible {
  case analyzerFailure(track: String, underlying: any Error)
  case analyzerAbstained(track: String, side: String)

  var description: String {
    switch self {
    case .analyzerFailure(let track, let err):
      return "analyzerFailure(\(track)): \(err)"
    case .analyzerAbstained(let track, let side):
      return "analyzerAbstained(\(track), side=\(side))"
    }
  }
}

// Story 8.8c: the file-local `DnBTargetsFileLite`/`DnBTargetEntry`/`DnBControlEntry`
// mirrors were removed — the suite now reads `4-dnb-triplet-targets.json` through the
// shared `JAMSCorpus` decoder (`BoomBoomBoomKitTestSupport`), splitting the named
// failures and DSP-correct controls by the per-entry sandbox `partition`.
