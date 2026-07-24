//
//  OA300BenchmarkTests.swift
//  BoomBoomBoomKitTests
//
//  Env-gated benchmark using the OA300 corpus with Rekordbox ground truth.
//  Set OA300_CORPUS_PATH to the corpus directory to enable these tests.
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
  let failures: [(track: OA300Track, expected: Double, got: Double)]

  var acc1: Double { total > 0 ? Double(acc1Correct) / Double(total) * 100 : 0 }
  var acc2: Double { total > 0 ? Double(acc2Correct) / Double(total) * 100 : 0 }
}

// MARK: - OA300 Benchmark Suite

@Suite("OA300 Benchmark")
struct OA300BenchmarkTests {

  /// The OA300 corpus resolves to 82 tracks with Rekordbox ground truth. GH-167
  /// item 4 (#155): default-run benchmarks assert this denominator so a printed
  /// percentage can never quietly change basis (unresolved tracks, silent nils,
  /// or `try?`-dropped decodes). This matches the pre-existing
  /// `windowVotingDefaultPolicyMatchesBaseline` `availableTracks.count == 82`.
  private static let analyzableTrackCount = 82

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else {
      throw OA300Error.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")

    guard let url = jsonURL else {
      throw OA300Error.groundTruthNotFound
    }

    let data = try Data(contentsOf: url)
    groundTruth = try OA300Track.loadCorpus(from: data)
  }

  // GH-167 item 4 (#155): `benchmarkDefaultIntensity` was deleted. It called
  // `runBenchmark(intensity: .default, tolerance: 0.02)` with inputs byte-identical
  // to `benchmarkAcc1Strict` below (same intensity, tolerance, merge, durationHint,
  // metadataPolicy) and asserted nothing — a second full-corpus pass that measured
  // nothing the strict test does not. Its failure-table formatting already lives in
  // `benchmarkAcc1Strict`.

  @Test("benchmark Acc1 strict (2% tolerance)")
  func benchmarkAcc1Strict() async throws {
    let (metrics, _) = try await runBenchmark(intensity: .default, tolerance: 0.02)
    print("\n=== OA300 Benchmark — Acc1 Strict (2% tolerance) ===")
    print("Corpus: \(metrics.total) tracks, Rekordbox ground truth")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    if !metrics.failures.isEmpty {
      print("\nAcc1 Failures:")
      print("| Track | Expected | Got | Delta% |")
      print("|-------|----------|-----|--------|")
      for f in metrics.failures {
        let delta = abs(f.got - f.expected) / f.expected * 100
        print(
          "| \(f.track.title.prefix(40)) | \(String(format: "%.1f", f.expected)) | \(String(format: "%.1f", f.got)) | \(String(format: "%.1f", delta))% |"
        )
      }
    }

    // AC #4 (Story 3-2 + Story 3-4): OA300 Acc1 must hold ≥ 69.5% (57/82) and Acc2 ≥ 89.0%
    // (73/82). See `_bmad-output/implementation-artifacts/3-2-fine-grid-precision-fix.md`
    // (acceptance criteria #4) and Story 3-4 AC #4 (duration-derived BPM hint default-on
    // must not regress these floors). Asserted unconditionally so wiring bugs surface
    // at the test layer regardless of whether the hint actually changed any track outcomes.
    #expect(
      metrics.acc1Correct >= 57,
      "AC #4 OA300 Acc1 regression: expected >= 57/82 (69.5%), got \(metrics.acc1Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc2Correct >= 73,
      "AC #4 OA300 Acc2 regression: expected >= 73/82 (89.0%), got \(metrics.acc2Correct)/\(metrics.total)"
    )
  }

  // Story 3-4 AC #5: opt-out regression-safety control. With `durationHint: false`,
  // OA300 must match the pre-Story-3-4 baseline EXACTLY (57/82 Acc1, 73/82 Acc2 under
  // the maxConfidence merge). Any drift means duration-related state is leaking into
  // the no-hint path. Story 3.6 AC #4: `metadataPolicy = .disabled` is required to
  // hold the same exact baseline once metadata corroboration ships default-on (the
  // metadata path has its own exact-baseline test below).
  @Test("AC #5: durationHint=false matches pre-Story-3-4 baseline EXACTLY")
  func benchmarkDurationHintOptOut() async throws {
    let (metrics, _) = try await runBenchmark(
      intensity: .default, tolerance: 0.02,
      durationHint: false, metadataPolicy: .disabled)
    print("\n=== OA300 Benchmark — durationHint=false (AC #5 control) ===")
    print(
      "Acc1: \(metrics.acc1Correct)/\(metrics.total), Acc2: \(metrics.acc2Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc1Correct == 57,
      "AC #5 OA300 Acc1 (durationHint=false) must equal 57/82 EXACTLY, got \(metrics.acc1Correct)/\(metrics.total)"
    )
    #expect(
      metrics.acc2Correct == 73,
      "AC #5 OA300 Acc2 (durationHint=false) must equal 73/82 EXACTLY, got \(metrics.acc2Correct)/\(metrics.total)"
    )
  }

  @Test("benchmark Acc1 MIREX (4% tolerance)")
  func benchmarkAcc1MIREX() async throws {
    let (metrics, perTrack) = try await runBenchmark(intensity: .default, tolerance: 0.04)
    print("\n=== OA300 Benchmark — Acc1 MIREX (4% tolerance) ===")
    print("Corpus: \(metrics.total) tracks, Rekordbox ground truth")
    print(
      "Acc1: \(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total))")
    print(
      "Acc2: \(String(format: "%.1f", metrics.acc2))% (\(metrics.acc2Correct)/\(metrics.total))")
    if !metrics.failures.isEmpty {
      print("\nAcc1 Failures:")
      print("| Track | Expected | Got | Delta% |")
      print("|-------|----------|-----|--------|")
      for f in metrics.failures {
        let delta = abs(f.got - f.expected) / f.expected * 100
        print(
          "| \(f.track.title.prefix(40)) | \(String(format: "%.1f", f.expected)) | \(String(format: "%.1f", f.got)) | \(String(format: "%.1f", delta))% |"
        )
      }
    }

    // GH-167 item 4 (#155): assert the denominator, not accuracy (item 5 owns the
    // MIREX floor). A regression that fails to resolve tracks, or one where
    // analysis silently returns nil, would otherwise print a percentage over a
    // shrunken basis and still pass.
    let nilTracks = perTrack.filter { $0.detected == nil }.map { $0.track.filename }
    #expect(
      metrics.total == Self.analyzableTrackCount,
      "#155: expected \(Self.analyzableTrackCount) OA300 tracks resolved; got \(metrics.total)")
    #expect(
      nilTracks.isEmpty, "#155: \(nilTracks.count) tracks returned nil: \(nilTracks.prefix(5))")
  }

  @Test("multi-intensity comparison (monotonic Acc1)")
  func benchmarkMultiIntensity() async throws {
    let levels = [1, 3, 5, 7]
    var previousAcc1Count = 0
    var perTrackResults: [String: [Int: Double]] = [:]

    print("\n=== OA300 Multi-Intensity Comparison ===")

    for level in levels {
      let intensity = try #require(AnalysisIntensity(level: level))
      let (metrics, _) = try await runBenchmark(intensity: intensity, tolerance: 0.02)
      print(
        "Intensity \(level): Acc1=\(String(format: "%.1f", metrics.acc1))% (\(metrics.acc1Correct)/\(metrics.total)), Acc2=\(String(format: "%.1f", metrics.acc2))%"
      )

      // Track per-track results for regression warnings
      for f in metrics.failures {
        perTrackResults[f.track.filename, default: [:]][level] = f.got
      }

      // Assert per-corpus monotonicity
      #expect(
        metrics.acc1Correct >= previousAcc1Count,
        "Acc1 at intensity \(level) (\(metrics.acc1Correct)) should be >= intensity at previous level (\(previousAcc1Count))"
      )
      previousAcc1Count = metrics.acc1Correct
    }

    // Print per-track regressions as warnings (not assertions)
    for (filename, results) in perTrackResults.sorted(by: { $0.key < $1.key }) {
      let levelResults = results.sorted(by: { $0.key < $1.key })
      let desc = levelResults.map { "L\($0.key)=\(String(format: "%.1f", $0.value))" }
        .joined(separator: " ")
      print("  Warning: \(filename) failed at: \(desc)")
    }
  }

  @Test("Bad BPM subset with trace")
  func benchmarkBadBPMSubset() throws {
    let badBPMTracks = groundTruth.filter { $0.subdir == "Bad BPM" }
    // GH-167 item 4 (#155): the subset must exist. A ground-truth reshape that
    // empties it would otherwise green-exit and silently stop exercising the
    // hardest tracks (the first place to look when debugging accuracy).
    try #require(!badBPMTracks.isEmpty, "no 'Bad BPM' subdir tracks in ground truth")

    print("\n=== Bad BPM Subset (trace-enabled) ===")
    for track in badBPMTracks {
      let url = trackURL(track)
      // GH-167 item 4 (#155): assert the file resolves and analysis runs, rather
      // than `try?`-swallowing failures into a silent SKIP/NIL print. This asserts
      // operational integrity (the diagnostic exercise ran), NOT accuracy — Bad BPM
      // tracks are deliberately hard and are allowed to miss.
      #expect(
        FileManager.default.fileExists(atPath: url.path),
        "#155: Bad BPM track missing on disk: \(track.filename)")
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      var options = AudioAnalysisService.Options()
      options.enableTrace = true
      let analyzed = try AudioAnalysisService.analyzeBPM(url: url, options: options)
      let r = try #require(
        analyzed, "#155: analyzeBPM returned nil for Bad BPM track \(track.filename)")
      let match = isAcc1Match(r.bpm, track.bpm, tolerance: 0.02) ? "OK" : "MISS"
      let candidates = r.candidates.prefix(5).map { String(format: "%.1f", $0.bpm) }
        .joined(separator: ", ")
      print(
        "  [\(match)] \(track.title.prefix(40)): expected=\(track.bpm), got=\(String(format: "%.1f", r.bpm)), conf=\(String(format: "%.2f", r.confidence)), candidates=[\(candidates)]"
      )
    }
  }

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

  @Test("merge strategy comparison (all 8 strategies)")
  func benchmarkMergeStrategies() throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    // GH-167 item 4 (#155): assert the denominator; no empty-corpus green-exit.
    #expect(
      availableTracks.count == Self.analyzableTrackCount,
      "#155: expected \(Self.analyzableTrackCount) OA300 tracks on disk; got \(availableTracks.count)"
    )

    print("\n=== OA300 Merge Strategy Comparison (Intensity 7) ===")
    print(
      "Strategy".padding(toLength: 20, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Correct  Total")
    print(String(repeating: "-", count: 60))

    // Pre-read all audio files once
    struct TrackAudio {
      let track: OA300Track
      let samples: [Float]
      let sampleRate: Double
    }
    var audioData: [TrackAudio] = []
    for track in availableTracks {
      let url = trackURL(track)
      if let (samples, sampleRate) = try? PCMBufferReader.readMonoSamples(
        from: url, maxSeconds: 120)
      {
        audioData.append(TrackAudio(track: track, samples: samples, sampleRate: sampleRate))
      }
    }
    // GH-167 item 4 (#155): every resolved track must decode. Without this, a
    // `try?`-dropped read shrinks the denominator (`audioData.count`) and every
    // printed percentage silently changes basis between runs.
    #expect(
      audioData.count == availableTracks.count,
      "#155: \(availableTracks.count - audioData.count) tracks failed to decode; denominator would shrink"
    )

    for strategy in BPMSelectionPolicy.allCases {
      var acc1 = 0
      var acc2 = 0

      for audio in audioData {
        // Run all 3 windows and collect results
        var windowResults: [BPMResult] = []
        for windowSeconds in AnalysisIntensity.default.windowSizes {
          if let result = BPMAnalyzer.estimateBPM(
            decoded: .synthetic(audio.samples, sampleRate: audio.sampleRate),
            options: .init(
              analysisWindowSeconds: windowSeconds,
              intensity: .default))
          {
            windowResults.append(result)
          }
        }

        guard
          let merged = BPMSelectionPolicy.merge(
            windowResults: windowResults,
            candidateCount: AnalysisIntensity.default.techniqueSet.candidateCount,
            strategy: strategy)
        else { continue }

        if isAcc1Match(merged.bpm, audio.track.bpm, tolerance: 0.02) {
          acc1 += 1
          acc2 += 1
        } else if isAcc2Match(merged.bpm, audio.track.bpm, tolerance: 0.02) {
          acc2 += 1
        }
      }

      let acc1Pct = String(format: "%5.1f%%", Double(acc1) / Double(audioData.count) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(acc2) / Double(audioData.count) * 100)
      print(
        strategy.rawValue.padding(toLength: 20, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct)  \(String(format: "%3d", acc1))      \(String(format: "%3d", audioData.count))"
      )
    }
  }

  // Story 3-5 Task 7 — voting-policy sweep over the windowVoting strategy.
  // Pre-reads audio once, analyzes 3 windows per track once, then iterates the
  // 6 (policy, threshold) pairs over the cached [BPMResult] (DD#18). The merge
  // step is sub-microsecond, so wall-clock is bounded by the DSP cost
  // (≈ 1/8 of benchmarkMergeStrategies's wall-clock per AC #9).
  @Test("voting policy comparison (3 policies × threshold sweep)")
  func benchmarkVotingPolicies() throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    // GH-167 item 4 (#155): assert the denominator; no empty-corpus green-exit.
    #expect(
      availableTracks.count == Self.analyzableTrackCount,
      "#155: expected \(Self.analyzableTrackCount) OA300 tracks on disk; got \(availableTracks.count)"
    )

    print("\n=== OA300 Voting Policy Comparison (Intensity 7, .windowVoting) ===")
    print(
      "Policy".padding(toLength: 28, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Correct  Total")
    print(String(repeating: "-", count: 60))

    // Pre-read all audio files once.
    struct TrackAudio {
      let track: OA300Track
      let samples: [Float]
      let sampleRate: Double
    }
    var audioData: [TrackAudio] = []
    for track in availableTracks {
      let url = trackURL(track)
      if let (samples, sampleRate) = try? PCMBufferReader.readMonoSamples(
        from: url, maxSeconds: 120)
      {
        audioData.append(TrackAudio(track: track, samples: samples, sampleRate: sampleRate))
      }
    }
    // GH-167 item 4 (#155): every resolved track must decode — no silent
    // denominator shrink from a `try?`-dropped read.
    #expect(
      audioData.count == availableTracks.count,
      "#155: \(availableTracks.count - audioData.count) tracks failed to decode; denominator would shrink"
    )

    // Pre-compute per-track [BPMResult] ONCE outside the policy loop (DD#18).
    var cachedWindows: [(track: OA300Track, results: [BPMResult])] = []
    cachedWindows.reserveCapacity(audioData.count)
    for audio in audioData {
      var windowResults: [BPMResult] = []
      for windowSeconds in AnalysisIntensity.default.windowSizes {
        if let result = BPMAnalyzer.estimateBPM(
          decoded: .synthetic(audio.samples, sampleRate: audio.sampleRate),
          options: .init(
            analysisWindowSeconds: windowSeconds,
            intensity: .default))
        {
          windowResults.append(result)
        }
      }
      cachedWindows.append((track: audio.track, results: windowResults))
    }

    let pairs: [(policy: VotingPolicy, threshold: Double, label: String)] = [
      (.simpleMajority, 0.0, "simpleMajority"),
      (.confidenceWeighted, 0.0, "confidenceWeighted"),
      (.thresholdGated, 0.0, "thresholdGated@0.00"),
      (.thresholdGated, 0.25, "thresholdGated@0.25"),
      (.thresholdGated, 0.50, "thresholdGated@0.50"),
      (.thresholdGated, 0.75, "thresholdGated@0.75"),
    ]

    let candidateCount = AnalysisIntensity.default.techniqueSet.candidateCount

    for pair in pairs {
      var acc1 = 0
      var acc2 = 0

      for entry in cachedWindows {
        guard
          let merged = BPMSelectionPolicy.merge(
            windowResults: entry.results,
            candidateCount: candidateCount,
            strategy: .windowVoting,
            votingPolicy: pair.policy,
            votingThreshold: pair.threshold)
        else { continue }

        if isAcc1Match(merged.bpm, entry.track.bpm, tolerance: 0.02) {
          acc1 += 1
          acc2 += 1
        } else if isAcc2Match(merged.bpm, entry.track.bpm, tolerance: 0.02) {
          acc2 += 1
        }
      }

      let acc1Pct = String(format: "%5.1f%%", Double(acc1) / Double(audioData.count) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(acc2) / Double(audioData.count) * 100)
      print(
        pair.label.padding(toLength: 28, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct)  \(String(format: "%3d", acc1))      \(String(format: "%3d", audioData.count))"
      )
    }
  }

  // Story 3-5 Task 8.2 — corpus regression `#expect` for AC #4.
  // Baseline captured at git SHA `ba6ba523990aecef872c0bdff96b758918609eee`
  // (post-Story-3-4 close-out, pre-Story-3-5) via the `windowVoting` row of
  // `benchmarkMergeStrategies`. Drift in either Acc1 or Acc2 indicates the
  // Story 3-5 wiring leaked state into the default windowVoting code path.
  @Test("AC #4: windowVoting + .simpleMajority matches pre-Story-3-5 baseline EXACTLY")
  func windowVotingDefaultPolicyMatchesBaseline() async throws {
    // Hardcoded from Task 0 baseline capture (see story Debug Log References).
    let oa300Acc1Baseline = 57
    let oa300Acc2Baseline = 72
    let total = 82

    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }

    let urls = availableTracks.map { trackURL($0) }
    let trackBPMs = await withTaskGroup(of: (Int, Double?).self) { group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.intensity = .default
          opts.mergeStrategy = .windowVoting
          opts.votingPolicy = .simpleMajority
          opts.votingThreshold = 0.0
          // Story 3.6 AC #4: this exact-baseline test predates metadata
          // corroboration. Setting `.disabled` preserves the pre-Story-3.6
          // pipeline so the byte-equality contract still holds.
          opts.metadataPolicy = .disabled
          return (
            index,
            (try? AudioAnalysisService.analyzeBPM(url: url, options: opts))?.bpm
          )
        }
      }
      var results = [Double?](repeating: nil, count: availableTracks.count)
      for await (i, bpm) in group { results[i] = bpm }
      return results
    }

    // Surface analyzeBPM nils explicitly — without this guard, a transient
    // AVFoundation failure would silently lower Acc1 and fail the unconditional
    // baseline check below with a misleading "Acc1 must equal 57/82" message.
    let nilTracks = zip(availableTracks, trackBPMs).filter { $0.1 == nil }
      .map { $0.0.filename }
    #expect(
      nilTracks.isEmpty,
      "AC #4 baseline: \(nilTracks.count) tracks returned nil from analyzeBPM (failure precedes Acc1/Acc2 drift): \(nilTracks.prefix(5))"
    )

    var acc1 = 0
    var acc2 = 0
    for (index, track) in availableTracks.enumerated() {
      guard let detected = trackBPMs[index] else { continue }
      if isAcc1Match(detected, track.bpm, tolerance: 0.02) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2Match(detected, track.bpm, tolerance: 0.02) {
        acc2 += 1
      }
    }

    #expect(
      availableTracks.count == total,
      "Expected \(total) OA300 tracks at baseline; got \(availableTracks.count)")
    #expect(
      acc1 == oa300Acc1Baseline,
      "AC #4: OA300 windowVoting+.simpleMajority Acc1 must equal \(oa300Acc1Baseline)/\(total) EXACTLY, got \(acc1)/\(availableTracks.count)"
    )
    #expect(
      acc2 == oa300Acc2Baseline,
      "AC #4: OA300 windowVoting+.simpleMajority Acc2 must equal \(oa300Acc2Baseline)/\(total) EXACTLY, got \(acc2)/\(availableTracks.count)"
    )
  }

  // Story 3.6 AC #19: tagged-subset breakdown reporting. Observability, not a gate.
  @Test("Story 3.6: tagged-subset metadata breakdown")
  func taggedSubsetBreakdown() async throws {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    // GH-167 item 4 (#155): assert the denominator before the report prints, so
    // the bucket counts are read against the full corpus, not a shrunken basis.
    #expect(
      availableTracks.count == Self.analyzableTrackCount,
      "#155: expected \(Self.analyzableTrackCount) OA300 tracks on disk; got \(availableTracks.count)"
    )
    let urls = availableTracks.map { trackURL($0) }

    struct TrackEvidence: Sendable {
      let filename: String
      let evidence: [MetadataBPMEvidence]
    }

    // GH-167 item 4 (#155): the task returns whether analysis actually completed,
    // not just its evidence. Without this, a `try?`-swallowed failure is
    // indistinguishable from "analyzed successfully, genuinely no metadata" —
    // both yield an empty evidence array — so a corpus where EVERY analysis fails
    // still prints "0/82 tracks with metadata" and passes. The `analyzed` flag
    // closes that measure-nothing hole (Codex diff review 2026-07-24).
    let perTrack = await withTaskGroup(of: (Int, analyzed: Bool, [MetadataBPMEvidence]).self) {
      group in
      for (index, url) in urls.enumerated() {
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.intensity = .default
          // Use default merge to avoid windowVoting interaction with metadata.
          let result = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
          return (index, result != nil, result?.metadataEvidence ?? [])
        }
      }
      var results: [(analyzed: Bool, evidence: [MetadataBPMEvidence])] =
        Array(repeating: (false, []), count: availableTracks.count)
      for await (i, analyzed, ev) in group { results[i] = (analyzed, ev) }
      return results
    }

    // Every track must have completed analysis before empty-evidence can be read
    // as "no metadata" rather than "analysis never ran".
    let failedAnalyses = zip(availableTracks, perTrack).filter { !$0.1.analyzed }.map {
      $0.0.filename
    }
    #expect(
      failedAnalyses.isEmpty,
      "#155: \(failedAnalyses.count) tracks failed to analyze — empty metadata would be miscounted as 'no tag': \(failedAnalyses.prefix(5))"
    )

    var tracksWithMetadata = 0
    var corroboratedSameTempo = 0
    var corroboratedOctave = 0
    var corroboratedTriplet = 0
    var intraFileConflict = 0
    var dspDisagreement = 0
    var uncorroborated = 0
    let total = availableTracks.count

    for entry in perTrack {
      let evidence = entry.evidence
      if evidence.isEmpty { continue }
      tracksWithMetadata += 1

      // Track-level classification: pick the strongest signal across this
      // track's evidence entries (corroboration > conflict > disagreement >
      // uncorroborated). Parse-phase rejections (sentinel-zero, out-of-range,
      // non-numeric) don't count as a metadata "outcome" for this breakdown.
      let valid = evidence.filter {
        $0.rejectionReason != "sentinel-zero"
          && $0.rejectionReason != "out-of-range"
          && $0.rejectionReason != "non-numeric"
      }
      if valid.contains(where: { $0.corroboratedWith != nil && $0.ratioMatched == nil }) {
        corroboratedSameTempo += 1
      } else if valid.contains(where: {
        $0.corroboratedWith != nil
          && ($0.ratioMatched == .double || $0.ratioMatched == .half)
      }) {
        corroboratedOctave += 1
      } else if valid.contains(where: {
        $0.corroboratedWith != nil
          && ($0.ratioMatched == .threeHalf || $0.ratioMatched == .twoThird)
      }) {
        corroboratedTriplet += 1
      } else if valid.contains(where: { $0.rejectionReason == "intra-file-conflict" }) {
        intraFileConflict += 1
      } else if valid.contains(where: { $0.rejectionReason == "dsp-disagreement" }) {
        dspDisagreement += 1
      } else if !valid.isEmpty {
        uncorroborated += 1
      }
    }

    print("\n=== Tagged-subset breakdown ===")
    print("Tracks with metadata read:       \(tracksWithMetadata) / \(total)")
    print("  Corroborated (same-tempo):     \(corroboratedSameTempo)")
    print("  Corroborated (octave ratio):   \(corroboratedOctave)")
    print("  Corroborated (triplet ratio):  \(corroboratedTriplet)")
    print("  Intra-file conflict:           \(intraFileConflict)")
    print("  DSP disagreement (unanimous):  \(dspDisagreement)")
    print("  Uncorroborated (single tag):   \(uncorroborated)")
  }

  // Story 3.6 Task 0.5 — corroboration tolerance sweep (observability, not a gate).
  // Runs the OA300 benchmark with `corroborationTolerance` ∈ {0.01, 0.02, 0.03}
  // and reports tagged-subset bucket counts for each. Env-gated to avoid wall-clock
  // overhead in the routine `make benchmark` run.
  @Test(
    "Story 3.6: corroboration tolerance sweep (CORROBORATION_SWEEP=1)",
    .enabled(if: ProcessInfo.processInfo.environment["CORROBORATION_SWEEP"] == "1")
  )
  func corroborationToleranceSweep() async throws {
    print("\n=== OA300 corroboration tolerance sweep ===")
    print("Tolerance  Acc1   Acc2   SameTempo  Octave  Uncorrob  DSPDis")

    for tol in [0.01, 0.02, 0.03] {
      var policy = MetadataPolicy.default
      policy.corroborationTolerance = tol
      let (metrics, perTrackEvidence) = try await runWithPolicy(policy: policy)

      var corrSame = 0
      var corrOctave = 0
      var uncorr = 0
      var dspDis = 0
      for evidence in perTrackEvidence {
        let valid = evidence.filter {
          $0.rejectionReason != "sentinel-zero"
            && $0.rejectionReason != "out-of-range"
            && $0.rejectionReason != "non-numeric"
        }
        if valid.contains(where: { $0.corroboratedWith != nil && $0.ratioMatched == nil }) {
          corrSame += 1
        } else if valid.contains(where: {
          $0.corroboratedWith != nil
            && ($0.ratioMatched == .double || $0.ratioMatched == .half)
        }) {
          corrOctave += 1
        } else if valid.contains(where: { $0.rejectionReason == "dsp-disagreement" }) {
          dspDis += 1
        } else if !valid.isEmpty {
          uncorr += 1
        }
      }

      print(
        String(
          format: "%.2f       %2d/%2d  %2d/%2d  %2d         %2d      %2d        %2d",
          tol, metrics.acc1Correct, metrics.total,
          metrics.acc2Correct, metrics.total,
          corrSame, corrOctave, uncorr, dspDis))
    }
  }

  /// Runs analyzeBPM at default intensity with the given metadata policy, returning
  /// per-track BPM hits AND per-track evidence for the sweep.
  private func runWithPolicy(policy: MetadataPolicy) async throws -> (
    metrics: AccuracyMetrics, perTrackEvidence: [[MetadataBPMEvidence]]
  ) {
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }
    let urls = availableTracks.map { trackURL($0) }

    let perTrack = await withTaskGroup(of: (Int, Double?, [MetadataBPMEvidence]).self) {
      group in
      for (index, url) in urls.enumerated() {
        let p = policy
        group.addTask {
          var opts = AudioAnalysisService.Options()
          opts.intensity = .default
          opts.metadataPolicy = p
          let r = try? AudioAnalysisService.analyzeBPM(url: url, options: opts)
          return (index, r?.bpm, r?.metadataEvidence ?? [])
        }
      }
      var bpms = [Double?](repeating: nil, count: availableTracks.count)
      var ev: [[MetadataBPMEvidence]] = Array(repeating: [], count: availableTracks.count)
      for await (i, b, e) in group {
        bpms[i] = b
        ev[i] = e
      }
      return (bpms, ev)
    }

    var acc1Correct = 0
    var acc2Correct = 0
    for (index, track) in availableTracks.enumerated() {
      guard let detected = perTrack.0[index] else { continue }
      if isAcc1Match(detected, track.bpm, tolerance: 0.02) {
        acc1Correct += 1
        acc2Correct += 1
      } else if isAcc2Match(detected, track.bpm, tolerance: 0.02) {
        acc2Correct += 1
      }
    }
    let metrics = AccuracyMetrics(
      total: availableTracks.count, acc1Correct: acc1Correct,
      acc2Correct: acc2Correct, failures: [])
    return (metrics, perTrack.1)
  }

  @Test("genre-stratified accuracy")
  func benchmarkByGenre() async throws {
    let (metrics, perTrack) = try await runBenchmark(intensity: .default, tolerance: 0.02)

    // Group by genre, tallying Acc1/Acc2 hits per bucket.
    var genreStats: [String: (total: Int, acc1: Int, acc2: Int)] = [:]
    for (track, detected) in perTrack {
      var stats = genreStats[track.genre, default: (total: 0, acc1: 0, acc2: 0)]
      stats.total += 1
      if let detected {
        if isAcc1Match(detected, track.bpm, tolerance: 0.02) {
          stats.acc1 += 1
          stats.acc2 += 1
        } else if isAcc2Match(detected, track.bpm, tolerance: 0.02) {
          stats.acc2 += 1
        }
      }
      genreStats[track.genre] = stats
    }

    let buckets = genreStats.map { genre, stats in
      GenreBucket(
        genre: genre, total: stats.total,
        acc1Correct: stats.acc1, acc2Correct: stats.acc2)
    }

    let report = GenreAccuracyReporter.format(
      corpusLabel: "OA300",
      intensity: AnalysisIntensity.default.level,
      buckets: buckets,
      overallAcc1Percent: metrics.acc1, overallAcc2Percent: metrics.acc2)
    print("\n" + report)

    // GH-167 item 4 (#155): structural assertions, not accuracy floors. Assert
    // the denominator, that no track silently returned nil, and that the
    // per-genre buckets reconcile EXACTLY with the aggregate metrics — so a
    // genre-stratification bug can't drop tracks between the total and the
    // buckets while both still print.
    let nilTracks = perTrack.filter { $0.detected == nil }.map { $0.track.filename }
    #expect(
      metrics.total == Self.analyzableTrackCount,
      "#155: expected \(Self.analyzableTrackCount) OA300 tracks resolved; got \(metrics.total)")
    #expect(perTrack.count == Self.analyzableTrackCount, "#155: perTrack count != corpus size")
    #expect(
      nilTracks.isEmpty, "#155: \(nilTracks.count) tracks returned nil: \(nilTracks.prefix(5))")
    #expect(
      buckets.reduce(0) { $0 + $1.total } == metrics.total,
      "#155: genre bucket totals must sum to the corpus total")
    #expect(
      buckets.reduce(0) { $0 + $1.acc1Correct } == metrics.acc1Correct,
      "#155: genre bucket Acc1 must sum to the aggregate Acc1")
    #expect(
      buckets.reduce(0) { $0 + $1.acc2Correct } == metrics.acc2Correct,
      "#155: genre bucket Acc2 must sum to the aggregate Acc2")
  }

  // MARK: - Helpers

  private func runBenchmark(
    intensity: AnalysisIntensity,
    mergeStrategy: BPMSelectionPolicy = .maxConfidence,
    tolerance: Double,
    durationHint: Bool = true,
    metadataPolicy: MetadataPolicy = .default
  ) async throws -> (metrics: AccuracyMetrics, perTrack: [(track: OA300Track, detected: Double?)]) {
    // Filter to tracks that exist on disk
    let availableTracks = groundTruth.filter { track in
      FileManager.default.fileExists(atPath: trackURL(track).path)
    }

    // Build URLs outside the task group to avoid capturing self
    let urls = availableTracks.map { trackURL($0) }

    // Run analysis in parallel via structured concurrency
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

    // Aggregate results
    var acc1Correct = 0
    var acc2Correct = 0
    var failures: [(track: OA300Track, expected: Double, got: Double)] = []
    var perTrack: [(track: OA300Track, detected: Double?)] = []
    perTrack.reserveCapacity(availableTracks.count)

    for (index, track) in availableTracks.enumerated() {
      let detected = trackBPMs[index]
      perTrack.append((track: track, detected: detected))

      guard let detected else {
        failures.append((track: track, expected: track.bpm, got: 0))
        continue
      }

      if isAcc1Match(detected, track.bpm, tolerance: tolerance) {
        acc1Correct += 1
        acc2Correct += 1
      } else if isAcc2Match(detected, track.bpm, tolerance: tolerance) {
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
}

private enum OA300Error: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}
