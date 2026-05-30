//
//  MLPolicySweepTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 4.4 — env-gated benchmark suite for `EnsemblePolicy`.
//  Hosts the per-track baseline capture (Task 1), the corpus-paired
//  byte-identity tests (Task 5.6), and the `make ml-policy-sweep` harness
//  (Task 6.3). All tests are env-gated on `OA300_CORPUS_PATH`.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

// MARK: - JSON row schema (shared across baseline capture + paired tests)

/// Per-track baseline row written to `4-3-baseline-bpms.json` at Task 1 time
/// and read back by Task 5.6's byte-identity assertion. `bpmBits` /
/// `confidenceBits` carry `Double.bitPattern` (UInt64) so the JSON round-trip
/// preserves IEEE-754 byte identity — the informational `bpm` / `confidence`
/// fields use the lossy default `Double` encoding for human readability.
struct BaselineRow: Codable, Sendable {
  let filename: String
  let bpm: Double
  let confidence: Double
  let bpmBits: UInt64
  let confidenceBits: UInt64
  let expectedBPM: Double
}

// MARK: - Suite

@Suite(
  "MLPolicySweep",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil)
)
struct MLPolicySweepTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard
      let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"],
      !path.isEmpty
    else {
      throw MLPolicySweepError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")

    guard let url = jsonURL else {
      throw MLPolicySweepError.groundTruthNotFound
    }

    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: data)
  }

  // MARK: - Task 1: baseline capture (env-gated CAPTURE_BASELINE=1)

  /// Story 4-4 Task 1: capture per-track BPM baseline at the pre-source-change
  /// SHA. Writes `[BaselineRow]` JSON sorted by `filename` so two consecutive
  /// captures at the same SHA produce byte-identical files. Output path is
  /// `BASELINE_CAPTURE_OUT` when set; falls back to `$TMPDIR/4-3-baseline-bpms.json`.
  ///
  /// The dev runs this once at Task 1 time, copies the file to
  /// `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/4-3-baseline-bpms.json`,
  /// and commits it. Task 5.6's `dspOnlyMatchesStory4_3Baseline` reads it
  /// back via `Bundle.module.url(forResource:)` and asserts byte-identity.
  @Test(
    "Task 1: capture per-track BPM baseline (CAPTURE_BASELINE=1)",
    .enabled(
      if: ProcessInfo.processInfo.environment["CAPTURE_BASELINE"] == "1"
    )
  )
  func captureBaselineForStory4_4() async throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    let urls = availableTracks.map { trackURL($0) }

    let perTrack = await withTaskGroup(of: (Int, Double?, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          let result = try? AudioAnalysisService.analyzeBPM(
            url: url, options: AudioAnalysisService.Options())
          return (index, result?.bpm, result?.confidence)
        }
      }
      var results: [(Double?, Double?)] =
        Array(repeating: (nil, nil), count: availableTracks.count)
      for await (i, bpm, conf) in group { results[i] = (bpm, conf) }
      return results
    }

    var rows: [BaselineRow] = []
    rows.reserveCapacity(availableTracks.count)
    for (i, track) in availableTracks.enumerated() {
      let (bpm, conf) = perTrack[i]
      let bpmValue = bpm ?? .nan
      let confValue = conf ?? .nan
      rows.append(
        BaselineRow(
          filename: track.filename,
          bpm: bpmValue,
          confidence: confValue,
          bpmBits: bpmValue.bitPattern,
          confidenceBits: confValue.bitPattern,
          expectedBPM: track.bpm))
    }
    // Sort by filename for byte-stable output across runs.
    rows.sort { $0.filename < $1.filename }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let json = try encoder.encode(rows)

    let target = baselineCaptureURL()
    try json.write(to: target)
    print("Story 4-4 baseline -> \(target.path) (\(rows.count) tracks)")

    #expect(rows.count == 82, "Expected 82 OA300 tracks, got \(rows.count)")
  }

  // MARK: - Task 5.6: corpus-paired byte-identity proof (AC #5)

  /// AC #5: every OA300 track's `result.bpm.bitPattern` under
  /// `Options.ensemblePolicy = .dspOnly` + `Options.mlTechnique =
  /// MockMLTechnique(returning: MLEvaluation(bpm: 999, confidence: 1.0))`
  /// MUST match the committed baseline captured at the Story 4-4 Task 1
  /// pre-source SHA. This is the corpus-grain proof that the A1
  /// short-circuit is honored across the full corpus, not just synthetic
  /// fixtures.
  @Test("dspOnlyMatchesStory4_3Baseline (AC #5 corpus-paired)")
  func dspOnlyMatchesStory4_3Baseline() async throws {
    let baseline = try loadBaseline()
    let baselineByFilename = Dictionary(
      uniqueKeysWithValues: baseline.map { ($0.filename, $0) })

    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }

    let perTrack = await withTaskGroup(
      of: (filename: String, bpm: Double?, confidence: Double?).self
    ) { group in
      for track in availableTracks {
        let url = trackURL(track)
        let filename = track.filename
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.ensemblePolicy = .dspOnly
          opts.mlTechnique = MockMLTechnique(
            returning: MLEvaluation(bpm: 999.0, confidence: 1.0))
          let r = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
          return (filename, r?.bpm, r?.confidence)
        }
      }
      var rows: [(filename: String, bpm: Double?, confidence: Double?)] = []
      rows.reserveCapacity(availableTracks.count)
      for await row in group { rows.append(row) }
      return rows
    }

    var mismatches: [String] = []
    for row in perTrack {
      guard let baselineRow = baselineByFilename[row.filename] else {
        mismatches.append("\(row.filename): missing from baseline fixture")
        continue
      }
      let bpmValue = row.bpm ?? .nan
      let confValue = row.confidence ?? .nan
      if bpmValue.bitPattern != baselineRow.bpmBits {
        mismatches.append(
          "\(row.filename): bpm bits \(bpmValue.bitPattern) vs baseline \(baselineRow.bpmBits) (got=\(bpmValue), baseline=\(baselineRow.bpm))"
        )
      }
      if confValue.bitPattern != baselineRow.confidenceBits {
        mismatches.append(
          "\(row.filename): confidence bits \(confValue.bitPattern) vs baseline \(baselineRow.confidenceBits)"
        )
      }
    }

    #expect(perTrack.count == baseline.count, "track count drift")
    #expect(
      mismatches.isEmpty,
      "AC #5 byte-identity violation under .dspOnly: \(mismatches.prefix(5))")
  }

  /// AC #5 + DD #2: prove the policy switch actually changes outcomes (i.e.,
  /// the sweep is not a no-op against the mock). Under `.mlOnly` and
  /// `.highestConfidence` with `MockMLTechnique(returning: MLEvaluation(bpm: 128, confidence: 0.92))`,
  /// at least one of the 82 tracks MUST have a different `result.bpm` than
  /// the `.dspOnly` baseline.
  @Test("policySwitchingChangesOutcomes (AC #5 negative control)")
  func policySwitchingChangesOutcomes() async throws {
    let baseline = try loadBaseline()
    let baselineByFilename = Dictionary(
      uniqueKeysWithValues: baseline.map { ($0.filename, $0) })

    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }

    let mockBPM = 128.0
    let mockConfidence = 0.92

    for policy in [EnsemblePolicy.mlOnly, .highestConfidence] {
      let perTrack = await withTaskGroup(
        of: (filename: String, bpm: Double?).self
      ) { group in
        for track in availableTracks {
          let url = trackURL(track)
          let filename = track.filename
          let p = policy
          group.addTask {
            var opts = AudioAnalysisService.Options()
            opts.ensemblePolicy = p
            opts.mlTechnique = MockMLTechnique(
              returning: MLEvaluation(bpm: mockBPM, confidence: mockConfidence))
            let r = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
            return (filename, r?.bpm)
          }
        }
        var rows: [(filename: String, bpm: Double?)] = []
        rows.reserveCapacity(availableTracks.count)
        for await row in group { rows.append(row) }
        return rows
      }

      // Strong "policy is not a no-op" assertion. Under `.mlOnly`, the
      // combiner ALWAYS picks ML's bpm when ML did not abstain (here the
      // mock returns finite 128.0, so no abstain), so EVERY track's
      // detected bpm must equal the clamped mock bpm. Under
      // `.highestConfidence`, ML wins iff `mockConfidence > dsp.confidence`;
      // tracks where ML wins must have detected == 128, tracks where DSP
      // wins must equal the `.dspOnly` baseline. Either way the result
      // must NOT equal the baseline AND not equal 128 simultaneously.
      switch policy {
      case .mlOnly:
        let nonAbstainCount = perTrack.reduce(into: 0) { acc, row in
          guard row.bpm != nil else { return }
          acc += 1
        }
        #expect(
          nonAbstainCount > 0, "no track resolved under .mlOnly")
        for row in perTrack {
          guard let detected = row.bpm else { continue }
          let msg: Comment =
            ".mlOnly with finite mock bpm must select ML's clamped bpm for every resolved track; got \(detected) for \(row.filename)"
          #expect(detected.bitPattern == mockBPM.bitPattern, msg)
        }
      case .highestConfidence:
        // For each track, detected must be either the mock bpm (ML wins)
        // or the baseline bpm (DSP wins / tie). Anything else is a bug.
        for row in perTrack {
          guard let detected = row.bpm,
            let baselineRow = baselineByFilename[row.filename]
          else { continue }
          let mlWon = detected.bitPattern == mockBPM.bitPattern
          let dspWon = detected.bitPattern == baselineRow.bpmBits
          let msg: Comment =
            ".highestConfidence detected \(detected) is neither mock (\(mockBPM)) nor baseline (\(baselineRow.bpm)) for \(row.filename)"
          #expect(mlWon || dspWon, msg)
        }
        // Sanity: at least one track must differ from baseline
        // (else the policy degenerated to .dspOnly).
        let differingCount = perTrack.reduce(into: 0) { acc, row in
          guard let detected = row.bpm,
            let baselineRow = baselineByFilename[row.filename]
          else { return }
          if detected.bitPattern != baselineRow.bpmBits { acc += 1 }
        }
        #expect(
          differingCount >= 1,
          ".highestConfidence is a no-op vs .dspOnly baseline (every track unchanged) — mock confidence may be too low"
        )
      case .dspOnly:
        Issue.record("dspOnly should not appear in the policy switch loop")
      }
    }
  }

  // MARK: - Task 6.3: make ml-policy-sweep harness (env-gated)

  /// Per-policy accuracy row emitted to `4-4-ml-policy-sweep.json`. JSON
  /// schema mirrors AC #6: `{policy, acc1, acc2, total, default}`.
  struct SweepRow: Codable, Sendable {
    let policy: String
    let acc1: Int
    let acc2: Int
    let total: Int
    let `default`: Bool
  }

  /// Pre-policy mock evaluation echoed into the sweep's `mock_evaluation`
  /// envelope so the consumer of `4-4-ml-policy-sweep.json` can correlate
  /// the deltas to the harness shape.
  struct MockEvaluation: Codable, Sendable {
    let bpm: Double
    let confidence: Double
  }

  struct SweepEnvelope: Codable, Sendable {
    let schema_version: Int
    let snapshot_sha: String
    let mock_evaluation: MockEvaluation
    let results: [SweepRow]
  }

  /// Task 6.3 / AC #6: `make ml-policy-sweep` harness. Gated on
  /// `ML_POLICY_SWEEP=1`; iterates `EnsemblePolicy.allCases` injecting
  /// `MockMLTechnique(returning: MLEvaluation(bpm: 128, confidence: 0.92))`
  /// per case (deterministic; this is harness validation per DD #8, not
  /// model-correctness evidence). The pre-read pass over OA300 audio
  /// filters out files that `PCMBufferReader` cannot decode; the per-policy
  /// loop calls `AudioAnalysisService.analyzeBPM(url:)` which re-reads each
  /// surviving file from disk per policy. JSON output via `JSONEncoder` with
  /// `[.prettyPrinted, .sortedKeys]` for byte-stable cross-run output
  /// (HALT (c)).
  @Test(
    "policySweepReport (ML_POLICY_SWEEP=1)",
    .enabled(
      if: ProcessInfo.processInfo.environment["ML_POLICY_SWEEP"] == "1"
    )
  )
  func policySweepReport() async throws {
    struct TrackAudio: Sendable {
      let track: OA300Track
      let samples: [Float]
      let sampleRate: Double
    }

    // Pre-read each track once to filter out files that PCMBufferReader
    // cannot decode (corpus files occasionally have unsupported codecs).
    // The pre-read result is NOT reused inside the policy loop: the loop
    // calls `AudioAnalysisService.analyzeBPM(url:)`, which re-decodes the
    // file from disk per policy. That is the intended integration shape
    // (DD #8: "exercise policy switch + the inlined ensemble combiner end-to-end") —
    // wall-clock cost is per-policy DSP analysis + per-policy audio I/O,
    // and the `samples`/`sampleRate` carried in `TrackAudio` is retained
    // only so the per-track loops can iterate by index in the same shape
    // as the prior benchmark patterns.
    let candidateTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    var audioData: [TrackAudio] = []
    audioData.reserveCapacity(candidateTracks.count)
    for track in candidateTracks {
      let url = trackURL(track)
      if let (samples, sampleRate) = try? PCMBufferReader.readMonoSamples(
        from: url, maxSeconds: 120)
      {
        audioData.append(
          TrackAudio(track: track, samples: samples, sampleRate: sampleRate))
      }
    }

    let mockBPM = 128.0
    let mockConfidence = 0.92

    var rows: [SweepRow] = []
    for policy in EnsemblePolicy.allCases {
      var acc1 = 0
      var acc2 = 0

      // Use analyzeBPM (rather than calling BPMAnalyzer directly) so the
      // policy switch + the inlined ensemble combiner are exercised end-to-end.
      // analyzeBPM re-reads each track from disk per policy; wall-clock is
      // per-policy DSP analysis + per-policy audio I/O. The mock evaluate
      // is constant-time so the cost shape is dominated by DSP + I/O.
      let perTrack = await withTaskGroup(of: (Int, Double?).self) { group in
        for (idx, audio) in audioData.enumerated() {
          let url = trackURL(audio.track)
          let p = policy
          group.addTask {
            var opts = AudioAnalysisService.Options()
            opts.ensemblePolicy = p
            opts.mlTechnique = MockMLTechnique(
              returning: MLEvaluation(bpm: mockBPM, confidence: mockConfidence))
            let r = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
            return (idx, r?.bpm)
          }
        }
        var results = [Double?](repeating: nil, count: audioData.count)
        for await (i, bpm) in group { results[i] = bpm }
        return results
      }

      for (idx, audio) in audioData.enumerated() {
        guard let detected = perTrack[idx] else { continue }
        if isAcc1Match(detected, audio.track.bpm, tolerance: 0.02) {
          acc1 += 1
          acc2 += 1
        } else if isAcc2Match(detected, audio.track.bpm, tolerance: 0.02) {
          acc2 += 1
        }
      }

      rows.append(
        SweepRow(
          policy: policy.rawValue,
          acc1: acc1,
          acc2: acc2,
          total: audioData.count,
          default: policy == .dspOnly))
    }

    let snapshotSHA =
      ProcessInfo.processInfo.environment["GIT_SHA"] ?? "unknown"
    let envelope = SweepEnvelope(
      schema_version: 1,
      snapshot_sha: snapshotSHA,
      mock_evaluation: MockEvaluation(bpm: mockBPM, confidence: mockConfidence),
      results: rows)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let json = try encoder.encode(envelope)
    let target = sweepReportURL()
    try json.write(to: target)
    print("Story 4-4 ml-policy-sweep -> \(target.path) (\(rows.count) policies)")

    #expect(rows.count == EnsemblePolicy.allCases.count)
    #expect(rows.first?.policy == "dspOnly")
    #expect(rows.first?.default == true)
  }

  // MARK: - Helpers

  /// Load the per-track baseline fixture from `Bundle.module` resources.
  /// Captured at the Story 4-4 Task 1 pre-source SHA via the
  /// `captureBaselineForStory4_4` env-gated test.
  private func loadBaseline() throws -> [BaselineRow] {
    let url =
      Bundle.module.url(forResource: "4-3-baseline-bpms", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/4-3-baseline-bpms", withExtension: "json")
    guard let url else { throw MLPolicySweepError.baselineFixtureNotFound }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode([BaselineRow].self, from: data)
  }

  private func sweepReportURL() -> URL {
    if let custom = ProcessInfo.processInfo.environment["ML_POLICY_SWEEP_OUT"],
      !custom.isEmpty
    {
      return URL(fileURLWithPath: custom)
    }
    if let outDir = ProcessInfo.processInfo.environment[
      "ML_POLICY_SWEEP_OUT_DIR"], !outDir.isEmpty
    {
      return URL(fileURLWithPath: outDir)
        .appendingPathComponent("4-4-ml-policy-sweep.json")
    }
    return FileManager.default.temporaryDirectory
      .appendingPathComponent("4-4-ml-policy-sweep.json")
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

  private func baselineCaptureURL() -> URL {
    let env = ProcessInfo.processInfo.environment["BASELINE_CAPTURE_OUT"]
    if let env, !env.isEmpty {
      return URL(fileURLWithPath: env)
    }
    return FileManager.default.temporaryDirectory
      .appendingPathComponent("4-3-baseline-bpms.json")
  }
}

private enum MLPolicySweepError: Error {
  case corpusPathNotSet
  case groundTruthNotFound
  case baselineFixtureNotFound
}
