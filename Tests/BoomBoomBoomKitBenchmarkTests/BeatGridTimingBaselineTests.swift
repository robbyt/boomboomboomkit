//
//  BeatGridTimingBaselineTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 15.2 (Epic 15, Phase 2): reproduce the absolute grid-timing
//  discrepancy in-tree with a recorded baseline. Ports the standalone SPM
//  probe, which lives in the rekordboxReader repository at
//  ../rekordboxReader/docs/rekordbox-analysis/evidence/timing/TimingProbeTests.swift,
//  so Phase 3's frame-time-convention fix has a reproducible, in-tree
//  reference measurement to regress against.
//
//  This suite ASSERTS reproduction, not correctness. Since Story 15.3 (the
//  frame-time convention fix) each of the 24 rows must report
//  gridOriginSignedErrorMs in [-17.5, -6.0] ms and interiorMedianSignedErrorMs
//  in the same band. The residual is constant within a fixture and depends on
//  waveform shape and hop phase. The pre-15.3 band was [-50.5, -39.5] ms.
//
//  Default-off env gate (BBB_BEATGRID_TIMING_BASELINE != "1"); mirrors the
//  SuperFluxImpactTests / BNNSImpactTests convention. make test runs the
//  pre-story test count unchanged.
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite(
  "BeatGrid absolute timing baseline (Story 15.2)",
  .disabled(if: ProcessInfo.processInfo.environment["BBB_BEATGRID_TIMING_BASELINE"] != "1")
)
struct BeatGridTimingBaselineTests {

  // MARK: - Reproduction bounds

  /// Post-fix observed signed anchor error on this branch after Story 15.3
  /// (frame-time convention). The 24 rows cluster in [-16.78, -6.76] ms,
  /// with the residual dominated by a within-window peak-position bias that
  /// depends on waveform shape (single impulse vs 64-sample exp decay) and
  /// hop phase. Half-ms margins keep the band stable against small toolchain
  /// drift. Pre-15.3 numbers (held in the rekordboxReader repository at
  /// `../rekordboxReader/docs/rekordbox-analysis/evidence/timing/results.json`)
  /// sat at [-50.00, -39.98] ms; the Hann-windowed STFT's `hopSize + fftSize/2`
  /// correction accounts for the ~33 ms shift.
  private static let reproductionLowerBoundMs: Double = -17.5
  private static let reproductionUpperBoundMs: Double = -6.0

  // MARK: - Fixture matrix

  /// Baseline is level3 (matches the preserved probe). Phase 3 is free to
  /// extend the schema with additional levels; this story records exactly
  /// what the probe measured.
  private static let intensityLevel = AnalysisIntensity.level3

  /// 12 seconds of audio holds 24 beats at 120 BPM, more than enough for the
  /// interior slice (presentationTime in (1, 11)) to produce a stable median.
  private static let durationSeconds: Double = 12.0

  /// 120 BPM gives a 0.5 s beat period, which lets us measure phase in units
  /// of "fraction of a half-second" and keep the residual arithmetic simple.
  private static let tempoBPM: Double = 120.0

  private static let sampleRates: [Double] = [44_100.0, 48_000.0]
  private static let waveforms: [Waveform] = [.singleImpulse, .exponentialDecay64]
  private static let paths: [PathKind] = [.knownTempo, .publicFacade]

  enum Waveform: String {
    case singleImpulse = "single-impulse"
    case exponentialDecay64 = "64-sample-exp-decay"

    /// Number of nonzero samples written at each planted impulse.
    var sampleCount: Int { self == .singleImpulse ? 1 : 64 }
  }

  enum PathKind: String {
    case knownTempo = "known-tempo"
    case publicFacade = "public-facade"
  }

  // MARK: - Suite entry point

  @Test func reproduceAbsoluteGridTimingDiscrepancy() throws {
    var fixtures: [[String: Any]] = []
    fixtures.reserveCapacity(24)

    for sampleRate in Self.sampleRates {
      let hopSize = Int(sampleRate / 100.0)
      let beatSamples = Int(sampleRate / (Self.tempoBPM / 60.0))
      let offsets = [0, hopSize / 2, hopSize - 1]

      for offsetSamples in offsets {
        for waveform in Self.waveforms {
          let samples = synthesizeClickTrack(
            sampleRate: sampleRate,
            beatSamples: beatSamples,
            offsetSamples: offsetSamples,
            waveform: waveform
          )

          let known = try measure(
            samples: samples,
            sampleRate: sampleRate,
            hopSize: hopSize,
            offsetSamples: offsetSamples,
            waveform: waveform,
            path: .knownTempo
          )
          fixtures.append(known)
          try assertReproduces(row: known)

          let facade = try measure(
            samples: samples,
            sampleRate: sampleRate,
            hopSize: hopSize,
            offsetSamples: offsetSamples,
            waveform: waveform,
            path: .publicFacade
          )
          fixtures.append(facade)
          try assertReproduces(row: facade)
        }
      }
    }

    #expect(fixtures.count == 24, "Expected exactly 24 fixture rows; got \(fixtures.count)")

    try writeBaseline(fixtures: fixtures)
  }

  // MARK: - Measurement

  /// Builds a 12 s mono buffer, plants impulses on-grid at a known offset so
  /// each click's expected time is `(beatSamples * k + offsetSamples) / sampleRate`.
  private func synthesizeClickTrack(
    sampleRate: Double,
    beatSamples: Int,
    offsetSamples: Int,
    waveform: Waveform
  ) -> [Float] {
    var samples = [Float](repeating: 0, count: Int(sampleRate * Self.durationSeconds))
    for position in stride(
      from: beatSamples + offsetSamples,
      to: samples.count - waveform.sampleCount,
      by: beatSamples
    ) {
      for j in 0..<waveform.sampleCount {
        samples[position + j] = Float(exp(-Double(j) / 10.0))
      }
    }
    return samples
  }

  /// Runs the public facade or the internal `BeatGridAnalyzer.estimateBeatGrid`
  /// known-tempo path on the planted click track, derives the signed anchor
  /// and interior-beat residuals in milliseconds against the planted-impulse
  /// phase, and returns a fixture row that matches Story 15.2 DD #3's schema.
  /// Fixture-row builder: the parameters are the row's columns.
  private func measure(  // swiftlint:disable:this function_parameter_count
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    offsetSamples: Int,
    waveform: Waveform,
    path: PathKind
  ) throws -> [String: Any] {
    let grid = try estimateGrid(
      samples: samples,
      sampleRate: sampleRate,
      hopSize: hopSize,
      path: path
    )

    let anchor = try #require(grid.gridOrigin, "gridOrigin missing on \(path.rawValue)")
    let anchorSigned = signedPhaseResidualMs(
      time: anchor.presentationTime,
      offsetSamples: offsetSamples,
      sampleRate: sampleRate
    )

    // Interior slice: strip the first and last second so the median is not
    // perturbed by edge-of-window onset detection.
    let interiorResiduals = grid.beats
      .filter { $0.presentationTime > 1.0 && $0.presentationTime < 11.0 }
      .map {
        signedPhaseResidualMs(
          time: $0.presentationTime,
          offsetSamples: offsetSamples,
          sampleRate: sampleRate
        )
      }
      .sorted()
    try #require(!interiorResiduals.isEmpty, "No interior beats on \(path.rawValue)")

    let median = interiorResiduals[interiorResiduals.count / 2]
    let meanConfidence =
      grid.beats.reduce(0.0) { $0 + Double($1.confidence) } / Double(grid.beats.count)

    return [
      "path": path.rawValue,
      "sampleRate": sampleRate,
      "offsetSamples": offsetSamples,
      "waveform": waveform.rawValue,
      "estimatedBPM": grid.estimatedTempo,
      "gridConfidence": Double(grid.confidence),
      "beatCount": grid.beats.count,
      "interiorCount": interiorResiduals.count,
      "meanBeatConfidence": meanConfidence,
      "gridOriginSignedErrorMs": anchorSigned,
      "interiorMedianSignedErrorMs": median,
      "interiorMinSignedErrorMs": interiorResiduals.first!,
      "interiorMaxSignedErrorMs": interiorResiduals.last!,
    ]
  }

  private func estimateGrid(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    path: PathKind
  ) throws -> BeatGrid {
    switch path {
    case .knownTempo:
      let envelope = BPMAnalyzer.computeMelOnsetEnvelope(
        samples: samples,
        sampleRate: sampleRate,
        hopSize: hopSize
      )
      let grid = try #require(
        BeatGridAnalyzer.estimateBeatGrid(
          onsetEnvelope: envelope,
          onsetRate: sampleRate / Double(hopSize),
          hopSize: hopSize,
          sampleRate: sampleRate,
          acf: envelope,
          tempoBPM: Self.tempoBPM,
          windowStartSample: 0
        ),
        "BeatGridAnalyzer.estimateBeatGrid returned nil"
      )
      return grid

    case .publicFacade:
      let decoded = FeatureSubstrate.DecodedAudio(
        samples: samples,
        sampleRate: sampleRate,
        codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
      )
      var options = AudioAnalysisService.Options()
      options.intensity = Self.intensityLevel
      let grid = try #require(
        try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: options),
        "AudioAnalysisService.analyzeBeatGrid returned nil"
      )
      return grid
    }
  }

  /// Signed residual, in milliseconds, between a reported time and the nearest
  /// planted-impulse time. For a 120 BPM grid the beat period is 0.5 s, so the
  /// expected planted-click times are `(offsetSamples / sampleRate) + k * 0.5`
  /// and the residual is the (signed) distance to the nearest such time.
  private func signedPhaseResidualMs(
    time: Double,
    offsetSamples: Int,
    sampleRate: Double
  ) -> Double {
    let periodSeconds = 60.0 / Self.tempoBPM
    let plantedOffset = Double(offsetSamples) / sampleRate
    let phase = (time - plantedOffset) / periodSeconds
    return (phase - phase.rounded()) * periodSeconds * 1000.0
  }

  // MARK: - Reproduction tripwire

  private func assertReproduces(row: [String: Any]) throws {
    let gridOrigin = try #require(
      row["gridOriginSignedErrorMs"] as? Double,
      "gridOriginSignedErrorMs missing"
    )
    let interior = try #require(
      row["interiorMedianSignedErrorMs"] as? Double,
      "interiorMedianSignedErrorMs missing"
    )
    let path = row["path"] as? String ?? "<unknown>"
    let sampleRate = row["sampleRate"] as? Double ?? 0
    let offset = row["offsetSamples"] as? Int ?? -1
    let waveform = row["waveform"] as? String ?? "<unknown>"

    let location =
      "path=\(path) sr=\(sampleRate) offset=\(offset) waveform=\(waveform)"

    #expect(
      gridOrigin >= Self.reproductionLowerBoundMs
        && gridOrigin <= Self.reproductionUpperBoundMs,
      """
      gridOriginSignedErrorMs \(gridOrigin) ms outside the reproduction band \
      [\(Self.reproductionLowerBoundMs), \(Self.reproductionUpperBoundMs)] at \(location). \
      If this fails, Phase 3 may have landed or Phase 2's measurement regressed; \
      update the bounds above and \
      ../rekordboxReader/docs/rekordbox-analysis/evidence/timing/results.json together.
      """
    )
    #expect(
      interior >= Self.reproductionLowerBoundMs
        && interior <= Self.reproductionUpperBoundMs,
      """
      interiorMedianSignedErrorMs \(interior) ms outside the reproduction band \
      [\(Self.reproductionLowerBoundMs), \(Self.reproductionUpperBoundMs)] at \(location).
      """
    )
  }

  // MARK: - Baseline file

  /// Writes the per-SHA baseline to
  /// `_bmad-output/perf-baselines/beatgrid-timing/<short-sha>-<timestamp>.json`.
  /// Keys are emitted with `.sortedKeys` so a re-run on the same SHA produces a
  /// byte-identical JSON body (modulo the timestamp in the filename and the
  /// `createdAt` field, which the schema records for provenance).
  private func writeBaseline(fixtures: [[String: Any]]) throws {
    let repoRoot = try findRepoRoot()
    let (shortSHA, fullSHA) = resolveCommitSHA(repoRoot: repoRoot)

    let timestamp = ISO8601DateFormatter.string(
      from: Date(),
      timeZone: TimeZone(identifier: "UTC")!,
      formatOptions: [.withInternetDateTime]
    )
    let filenameTimestamp = timestamp.replacingOccurrences(of: ":", with: "-")

    let platform =
      "\(ProcessInfo.processInfo.operatingSystemVersionString) "
      + "arch=\(Self.hostArch())"

    let payload: [String: Any] = [
      "schemaVersion": 1,
      "commitSHA": fullSHA,
      "createdAt": timestamp,
      "platform": platform,
      "probeSource": "Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift",
      "intensityLevel": Self.intensityLevel.rawValue,
      "reproductionBoundsMs": [
        "lower": Self.reproductionLowerBoundMs,
        "upper": Self.reproductionUpperBoundMs,
      ],
      "fixtures": fixtures,
    ]

    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.sortedKeys, .prettyPrinted]
    )
    let targetDir =
      repoRoot
      .appendingPathComponent("_bmad-output", isDirectory: true)
      .appendingPathComponent("perf-baselines", isDirectory: true)
      .appendingPathComponent("beatgrid-timing", isDirectory: true)
    try FileManager.default.createDirectory(
      at: targetDir, withIntermediateDirectories: true
    )
    let filename = "\(shortSHA)-\(filenameTimestamp).json"
    let target = targetDir.appendingPathComponent(filename)
    try data.write(to: target, options: .atomic)
    print(
      "BBB_BEATGRID_TIMING_BASELINE wrote \(target.path) "
        + "(\(fixtures.count) fixtures, commit=\(shortSHA))"
    )
  }

  private func findRepoRoot() throws -> URL {
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    while directory.path != "/" {
      if FileManager.default.fileExists(atPath: directory.appendingPathComponent(".git").path) {
        return directory
      }
      directory = directory.deletingLastPathComponent()
    }
    throw TimingBaselineError.repoRootNotFound(from: #filePath)
  }

  private func resolveCommitSHA(repoRoot: URL) -> (short: String, full: String) {
    // Dirty working trees stamp the baseline with a `-dirty` suffix on both the
    // short and full SHA. Baselines are a per-SHA reproducibility artifact; a
    // dirty-tree run cannot be reproduced from the committed tree, so the
    // suffix is a load-bearing signal to anyone reading the file later.
    let dirtySuffix = isWorkingTreeDirty(repoRoot: repoRoot) ? "-dirty" : ""
    if let override = ProcessInfo.processInfo.environment["BBB_COMMIT_SHA"],
      !override.isEmpty
    {
      let full = override + dirtySuffix
      let short = String(override.prefix(10)) + dirtySuffix
      return (short, full)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "-C", repoRoot.path, "rev-parse", "HEAD"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    do {
      try process.run()
      process.waitUntilExit()
      let output =
        String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
      let full = output.trimmingCharacters(in: .whitespacesAndNewlines)
      if full.isEmpty { return ("unknown" + dirtySuffix, "unknown" + dirtySuffix) }
      let short = String(full.prefix(10)) + dirtySuffix
      return (short, full + dirtySuffix)
    } catch {
      return ("unknown" + dirtySuffix, "unknown" + dirtySuffix)
    }
  }

  private func isWorkingTreeDirty(repoRoot: URL) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    // Reports modified, staged and untracked files under Sources/, Tests/ and
    // Package.swift, the paths SwiftPM compiles into the measured binary. An
    // untracked Swift file there changes the probe, so it marks the tree
    // dirty. The scope excludes the per-SHA baseline JSON this suite writes
    // under _bmad-output/perf-baselines/beatgrid-timing/, so a fresh baseline
    // does not mark the tree dirty.
    process.arguments = [
      "git", "-C", repoRoot.path, "status", "--porcelain", "--", "Sources", "Tests",
      "Package.swift",
    ]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    do {
      try process.run()
      process.waitUntilExit()
      let output =
        String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
      return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    } catch {
      return false
    }
  }

  private static func hostArch() -> String {
    #if arch(arm64)
      return "arm64"
    #elseif arch(x86_64)
      return "x86_64"
    #else
      return "unknown"
    #endif
  }
}

private enum TimingBaselineError: Error, CustomStringConvertible {
  case repoRootNotFound(from: String)

  var description: String {
    switch self {
    case .repoRootNotFound(let path):
      return "Could not find a .git-rooted parent of \(path)"
    }
  }
}

extension ISO8601DateFormatter {
  fileprivate static func string(
    from date: Date,
    timeZone: TimeZone,
    formatOptions: ISO8601DateFormatter.Options
  ) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = timeZone
    formatter.formatOptions = formatOptions
    return formatter.string(from: date)
  }
}
