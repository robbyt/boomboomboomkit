//
//  WaveformAnalyzerPerfTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 15.4: wall-clock probe for `WaveformAnalyzer.analyze(decoded:options:)`.
//  Records min, median and max over five timed calls on deterministic
//  synthetic mono fixtures (30 s, 300 s, 600 s at 44.1 kHz) and writes one
//  per-SHA JSON baseline under `_bmad-output/perf-baselines/waveform/`.
//
//  This suite is a recording probe. It asserts nothing about speed. Each
//  baseline carries `WaveformAnalyzer.bandFilterImplementation`, so a timing
//  change between two files can be attributed to the band filter passes.
//
//  Default-off env gate (BBB_WAVEFORM_PERF != "1"); mirrors the
//  BeatGridTimingBaselineTests convention. make test runs the pre-story test
//  count unchanged. Run through `make waveform-perf-baseline`, which builds in
//  release config.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite(
  "WaveformAnalyzer wall-clock baseline (Story 15.4)",
  .disabled(
    if: ProcessInfo.processInfo.environment["BBB_WAVEFORM_PERF"] != "1",
    "Set BBB_WAVEFORM_PERF=1 (or run make waveform-perf-baseline) to record a baseline"
  )
)
struct WaveformAnalyzerPerfTests {

  // MARK: - Fixture matrix

  private static let sampleRate: Double = 44_100.0
  private static let durationsSeconds: [Int] = [30, 300, 600]
  private static let timedIterations = 5

  /// Sine components as (frequency Hz, amplitude). The amplitudes sum to 0.85,
  /// and the noise adds at most 0.01, so the signal stays inside [-1, 1]. The
  /// frequencies place energy in all three default bands (250 / 4000 Hz
  /// crossovers).
  private static let sineComponents: [(frequencyHz: Double, amplitude: Double)] = [
    (55.0, 0.30),
    (220.0, 0.25),
    (880.0, 0.20),
    (6_000.0, 0.10),
  ]
  private static let noiseAmplitude: Double = 0.01
  private static let noiseSeed: UInt64 = 0x5741_5645_464F_524D

  // MARK: - Suite entry point

  @Test func recordAnalyzeWallClock() throws {
    var fixtures: [[String: Any]] = []
    fixtures.reserveCapacity(Self.durationsSeconds.count)

    for durationSeconds in Self.durationsSeconds {
      let samples = Self.synthesize(durationSeconds: durationSeconds)
      let decoded = FeatureSubstrate.DecodedAudio(
        samples: samples,
        sampleRate: Self.sampleRate,
        codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
      )

      // Warm-up call: page in the input and allocator state before timing.
      _ = try WaveformAnalyzer.analyze(decoded: decoded)

      var timingsMs: [Double] = []
      timingsMs.reserveCapacity(Self.timedIterations)
      let clock = ContinuousClock()
      for _ in 0..<Self.timedIterations {
        var result: WaveformAnalysisResult?
        let elapsed = try clock.measure {
          result = try WaveformAnalyzer.analyze(decoded: decoded)
        }
        // Keeps the result observable so the call cannot be elided.
        #expect(result?.detail.magnitudes.isEmpty == false)
        timingsMs.append(Self.milliseconds(elapsed))
      }

      let sorted = timingsMs.sorted()
      let minMs = sorted.first ?? 0
      let medianMs = sorted[sorted.count / 2]
      let maxMs = sorted.last ?? 0

      print(
        "BBB_WAVEFORM_PERF duration=\(durationSeconds)s samples=\(samples.count) "
          + "min=\(Self.formatMs(minMs))ms median=\(Self.formatMs(medianMs))ms "
          + "max=\(Self.formatMs(maxMs))ms "
          + "filter=\(WaveformAnalyzer.bandFilterImplementation) "
          + "configuration=\(Self.configuration)"
      )

      fixtures.append([
        "durationSeconds": durationSeconds,
        "sampleCount": samples.count,
        "minMs": minMs,
        "medianMs": medianMs,
        "maxMs": maxMs,
      ])
    }

    try writeBaseline(fixtures: fixtures)
  }

  // MARK: - Fixture synthesis

  /// Sum of `sineComponents` plus uniform `SplitMix64` noise in
  /// `[-noiseAmplitude, noiseAmplitude]`. Deterministic for a given duration.
  private static func synthesize(durationSeconds: Int) -> [Float] {
    let count = Int(sampleRate) * durationSeconds
    var rng = SplitMix64(seed: noiseSeed)
    var samples = [Float](repeating: 0, count: count)
    let omegas = sineComponents.map { 2.0 * Double.pi * $0.frequencyHz / sampleRate }
    for index in 0..<count {
      let time = Double(index)
      var value = 0.0
      for (component, omega) in zip(sineComponents, omegas) {
        value += component.amplitude * sin(omega * time)
      }
      let unit = Double(rng.next() &>> 11) / Double(UInt64(1) << 53)
      value += noiseAmplitude * (2.0 * unit - 1.0)
      samples[index] = Float(value)
    }
    return samples
  }

  private static func milliseconds(_ duration: Duration) -> Double {
    let components = duration.components
    return Double(components.seconds) * 1_000.0
      + Double(components.attoseconds) / 1_000_000_000_000_000.0
  }

  private static func formatMs(_ value: Double) -> String {
    String(format: "%.2f", value)
  }

  private static var configuration: String {
    #if DEBUG
      return "debug"
    #else
      return "release"
    #endif
  }

  // MARK: - Baseline file

  /// Writes the per-SHA baseline to
  /// `_bmad-output/perf-baselines/waveform/<short-sha>-<timestamp>.json`.
  private func writeBaseline(fixtures: [[String: Any]]) throws {
    let repoRoot = try findRepoRoot()
    let (shortSHA, fullSHA) = resolveCommitSHA(repoRoot: repoRoot)

    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.formatOptions = [.withInternetDateTime]
    let timestamp = formatter.string(from: Date())
    let filenameTimestamp = timestamp.replacingOccurrences(of: ":", with: "-")

    let platform =
      "\(ProcessInfo.processInfo.operatingSystemVersionString) "
      + "arch=\(Self.hostArch())"

    let payload: [String: Any] = [
      "schemaVersion": 1,
      "commitSHA": fullSHA,
      "createdAt": timestamp,
      "platform": platform,
      "configuration": Self.configuration,
      "filterImplementation": WaveformAnalyzer.bandFilterImplementation,
      "probeSource": "Tests/BoomBoomBoomKitBenchmarkTests/WaveformAnalyzerPerfTests.swift",
      "sampleRate": Self.sampleRate,
      "timedIterations": Self.timedIterations,
      "fixtures": fixtures,
    ]

    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.sortedKeys, .prettyPrinted]
    )
    let targetDir =
      repoRoot
      .appendingPathComponent("_bmad-output", isDirectory: true)
      .appendingPathComponent("perf-baselines", isDirectory: true)
      .appendingPathComponent("waveform", isDirectory: true)
    try FileManager.default.createDirectory(
      at: targetDir, withIntermediateDirectories: true
    )
    let filename = "\(shortSHA)-\(filenameTimestamp).json"
    let target = targetDir.appendingPathComponent(filename)
    try data.write(to: target, options: .atomic)
    print(
      "BBB_WAVEFORM_PERF wrote \(target.path) "
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
    throw WaveformPerfError.repoRootNotFound(from: #filePath)
  }

  private func resolveCommitSHA(repoRoot: URL) -> (short: String, full: String) {
    // A dirty tree stamps both SHAs with `-dirty`: a dirty-tree timing cannot
    // be reproduced from the committed tree.
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
    // Scoped to Sources/, Tests/ and Package.swift, the paths SwiftPM
    // compiles into the measured binary. The baseline JSON this suite writes
    // under _bmad-output/ does not mark the tree dirty.
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

private enum WaveformPerfError: Error, CustomStringConvertible {
  case repoRootNotFound(from: String)

  var description: String {
    switch self {
    case .repoRootNotFound(let path):
      return "Could not find a .git-rooted parent of \(path)"
    }
  }
}
