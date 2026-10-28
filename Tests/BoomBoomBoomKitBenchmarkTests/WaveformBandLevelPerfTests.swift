//
//  WaveformBandLevelPerfTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 15.11: wall-clock and memory probe for
//  `WaveformBandLevelReader.read(url:options:)` and the waveform levels file
//  format. Writes one per-SHA JSON baseline under
//  `_bmad-output/perf-baselines/waveform-band/`.
//
//  Timing (warm-up, then the median of 5) on 10-minute stereo 44.1 kHz
//  synthetic files, a 16-bit WAV and a FLAC: the reader, decode only
//  (`AVAudioFile` reads in the reader's chunk size, no filtering), `encoded`,
//  and `decoded`. Plus the `AVAudioFile` open and `length` for the bundled
//  FLAC, WAV, MP3 and M4A fixtures, the check a caller can run against stored
//  levels. No speed bound is asserted.
//
//  Memory: 2-, 10- and 30-minute stereo WAVs, each read once in its own child
//  process (this test binary re-invoked with a filter and
//  BBB_WAVEFORM_BAND_MEMORY_FILE naming the file), which reports its peak
//  resident size. Asserts that the growth from 10 to 30 minutes is at most the
//  growth of the two output arrays plus 25 percent, which a whole-file decode
//  (about 21.2 MB per stereo minute in Float32) would exceed.
//
//  Default-off env gate (BBB_WAVEFORM_BAND_PERF != "1"). Run through
//  `make waveform-band-perf-baseline`, which builds in release config.
//

@preconcurrency import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite(
  "WaveformBandLevelReader wall-clock and memory baseline (Story 15.11)",
  .disabled(
    if: ProcessInfo.processInfo.environment["BBB_WAVEFORM_BAND_PERF"] != "1"
      || ProcessInfo.processInfo.environment[MemoryChild.fileVariable]
        != nil,
    "Set BBB_WAVEFORM_BAND_PERF=1 (or run make waveform-band-perf-baseline) to record a baseline"
  )
)
struct WaveformBandLevelPerfTests {
  private static let sampleRate = SyntheticAudioFile.sampleRate
  private static let timedIterations = 5
  private static let timedMinutes = 10
  private static let memoryMinutes = [2, 10, 30]
  private static let memorySlack = 0.25
  private static let key = String(repeating: "0123456789abcdef", count: 4)
  private static let headerFixtures: [(name: String, fileExtension: String)] = [
    ("test-audio", "flac"), ("sample", "wav"), ("Meta_Man", "mp3"), ("test-audio", "m4a"),
  ]

  // MARK: - Suite entry point

  @Test func recordWallClockAndMemory() throws {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "WaveformBandLevelPerfTests")
    defer { try? FileManager.default.removeItem(at: folder) }

    // Every fixture is written before any timing starts.
    let frames = Self.timedMinutes * 60 * Int(Self.sampleRate)
    let timedFiles: [(format: String, url: URL)] = [
      ("wav16", try Self.writeSignal(frames: frames, container: .wav16, in: folder)),
      ("flac", try Self.writeSignal(frames: frames, container: .flac, in: folder)),
    ]
    var memoryFiles: [(minutes: Int, url: URL)] = []
    for minutes in Self.memoryMinutes {
      let url = try Self.writeSignal(
        frames: minutes * 60 * Int(Self.sampleRate), container: .wav16, in: folder)
      memoryFiles.append((minutes, url))
    }

    var formats: [[String: Any]] = []
    for (format, url) in timedFiles {
      let fileBytes =
        (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
      var levels: WaveformBandLevels?
      let reader = try Self.time {
        levels = try WaveformBandLevelReader.read(url: url)
      }
      let measured = try #require(levels)
      #expect(measured.peak.count == Self.timedMinutes * 60 * 150)
      let decodeOnly = try Self.time { try Self.decodeOnly(url) }
      var encodedData = Data()
      let encode = try Self.time { encodedData = try measured.encoded(forKey: Self.key) }
      var decodedLevels: WaveformBandLevels?
      let decode = try Self.time {
        decodedLevels = WaveformBandLevels.decoded(from: encodedData, forKey: Self.key)
      }
      #expect(decodedLevels == measured)
      print(
        "BBB_WAVEFORM_BAND_PERF format=\(format) reader=\(Self.formatMs(reader.median))ms "
          + "decodeOnly=\(Self.formatMs(decodeOnly.median))ms "
          + "encoded=\(Self.formatMs(encode.median))ms decoded=\(Self.formatMs(decode.median))ms "
          + "configuration=\(Self.configuration)")
      formats.append([
        "format": format,
        "durationSeconds": Self.timedMinutes * 60,
        "fileBytes": fileBytes,
        "encodedBytes": encodedData.count,
        "bucketCount": measured.peak.count,
        "readerMs": reader.json,
        "decodeOnlyMs": decodeOnly.json,
        "encodedMs": encode.json,
        "decodedMs": decode.json,
      ])
    }

    var headerOpens: [[String: Any]] = []
    for fixture in Self.headerFixtures {
      let url = try AudioFixtures.url(for: fixture.name, extension: fixture.fileExtension)
      var length: Int64 = 0
      let open = try Self.time {
        let file = try AVAudioFile(forReading: url)
        length = file.length
      }
      print(
        "BBB_WAVEFORM_BAND_PERF headerOpen \(fixture.name).\(fixture.fileExtension) "
          + "median=\(Self.formatMs(open.median))ms length=\(length)")
      headerOpens.append([
        "fixture": "\(fixture.name).\(fixture.fileExtension)",
        "format": fixture.fileExtension,
        "frameCount": length,
        "openAndLengthMs": open.json,
      ])
    }

    var memory: [[String: Any]] = []
    var peakBytes: [Int: Int] = [:]
    for (minutes, url) in memoryFiles {
      let bytes = try Self.peakResidentBytesOfChildRead(url)
      peakBytes[minutes] = bytes
      print("BBB_WAVEFORM_BAND_PERF memory minutes=\(minutes) maxrss=\(bytes)")
      memory.append([
        "durationSeconds": minutes * 60,
        "bucketCount": minutes * 60 * 150,
        "maxResidentBytes": bytes,
      ])
    }
    let short = try #require(peakBytes[10])
    let long = try #require(peakBytes[30])
    let outputGrowth = (30 - 10) * 60 * 150 * WaveformBandLevels.bytesPerBucket
    let allowed = Int(Double(outputGrowth) * (1 + Self.memorySlack))
    let growth = long - short
    let wholeFileDecode = (30 - 10) * 60 * Int(Self.sampleRate) * 2 * 4
    print(
      "BBB_WAVEFORM_BAND_PERF memory growth 10->30 min=\(growth) allowed=\(allowed) "
        + "wholeFileDecode=\(wholeFileDecode)")
    #expect(
      growth <= allowed,
      "peak memory grew \(growth) bytes from 10 to 30 minutes; the output arrays account for \(outputGrowth)"
    )

    try writeBaseline(
      formats: formats, headerOpens: headerOpens, memory: memory,
      memoryCheck: [
        "growthBytes": growth, "outputArrayGrowthBytes": outputGrowth, "allowedBytes": allowed,
        "slack": Self.memorySlack, "wholeFileDecodeGrowthBytes": wholeFileDecode,
      ])
  }

  // MARK: - Fixtures

  /// A stereo signal at 44.1 kHz: seeded noise at 0.2 over 80 Hz and 800 Hz
  /// tones at 0.3 in both channels, a 5 kHz tone at 0.2 in the right, written
  /// in chunks so the whole signal is never in memory.
  private static func writeSignal(
    frames: Int, container: SyntheticAudioFile.Container, in folder: URL
  ) throws -> URL {
    var state: UInt32 = 0x1234_5678
    let rate = sampleRate
    return try SyntheticAudioFiles.writeLongFile(
      SyntheticAudioFile(frames: frames, container: container), in: folder
    ) { start, count, channels in
      for offset in 0..<count {
        state = state &* 1_664_525 &+ 1_013_904_223
        let noise = Float(state >> 8) / Float(1 << 24) - 0.5
        let time = Double(start + offset) / rate
        let tones = Float(sin(2 * .pi * 80 * time) + sin(2 * .pi * 800 * time))
        let sample = 0.2 * noise + 0.3 * tones
        channels[0][offset] = sample
        channels[1][offset] = sample + 0.2 * Float(sin(2 * .pi * 5_000 * time))
      }
    }
  }

  /// Reads the whole file in the reader's chunk size, with no filtering.
  private static func decodeOnly(_ url: URL) throws {
    let file = try AVAudioFile(forReading: url)
    guard
      let buffer = AVAudioPCMBuffer(
        pcmFormat: file.processingFormat, frameCapacity: WaveformBandLevelReader.chunkFrames)
    else { return }
    while file.framePosition < file.length {
      let requested = min(
        file.length - file.framePosition, Int64(WaveformBandLevelReader.chunkFrames))
      try file.read(into: buffer, frameCount: AVAudioFrameCount(requested))
      if buffer.frameLength == 0 { break }
    }
  }

  // MARK: - Timing

  private struct Timing {
    let min: Double
    let median: Double
    let max: Double

    var json: [String: Any] { ["min": min, "median": median, "max": max] }
  }

  /// One warm-up call, then the min, median and max of five timed calls.
  private static func time(_ body: () throws -> Void) throws -> Timing {
    try body()
    let clock = ContinuousClock()
    var timings: [Double] = []
    for _ in 0..<timedIterations {
      timings.append(milliseconds(try clock.measure(body)))
    }
    let sorted = timings.sorted()
    return Timing(min: sorted[0], median: sorted[sorted.count / 2], max: sorted[sorted.count - 1])
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

  // MARK: - Memory

  /// Runs this test binary again, filtered to the child suite, with
  /// `BBB_WAVEFORM_BAND_MEMORY_FILE` naming `url`, and returns the peak
  /// resident size the child reports after one read.
  private static func peakResidentBytesOfChildRead(_ url: URL) throws -> Int {
    let arguments = ProcessInfo.processInfo.arguments
    var childArguments: [String] = []
    var index = 1
    while index < arguments.count {
      if arguments[index] == "--filter" {
        index += 2
        continue
      }
      childArguments.append(arguments[index])
      index += 1
    }
    childArguments += ["--filter", "WaveformBandLevelMemoryChildTests"]
    let process = Process()
    process.executableURL = URL(fileURLWithPath: arguments[0])
    process.arguments = childArguments
    var environment = ProcessInfo.processInfo.environment
    environment[MemoryChild.fileVariable] = url.path
    process.environment = environment
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let text = String(decoding: data, as: UTF8.self)
    let prefix = MemoryChild.reportPrefix
    guard process.terminationStatus == 0,
      let line = text.split(separator: "\n").first(where: { $0.hasPrefix(prefix) }),
      let bytes = Int(line.dropFirst(prefix.count))
    else {
      throw WaveformBandPerfError.childReportMissing(
        status: process.terminationStatus, output: text)
    }
    return bytes
  }

  // MARK: - Baseline file

  /// Writes the per-SHA baseline to
  /// `_bmad-output/perf-baselines/waveform-band/<short-sha>-<timestamp>.json`.
  private func writeBaseline(
    formats: [[String: Any]], headerOpens: [[String: Any]], memory: [[String: Any]],
    memoryCheck: [String: Any]
  ) throws {
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
      "analysisVersion": WaveformBandLevelReader.analysisVersion,
      "probeSource": "Tests/BoomBoomBoomKitBenchmarkTests/WaveformBandLevelPerfTests.swift",
      "sampleRate": Self.sampleRate,
      "channels": 2,
      "timedIterations": Self.timedIterations,
      "formats": formats,
      "headerOpens": headerOpens,
      "memory": memory,
      "memoryCheck": memoryCheck,
    ]

    let data = try JSONSerialization.data(
      withJSONObject: payload, options: [.sortedKeys, .prettyPrinted]
    )
    let targetDir =
      repoRoot
      .appendingPathComponent("_bmad-output", isDirectory: true)
      .appendingPathComponent("perf-baselines", isDirectory: true)
      .appendingPathComponent("waveform-band", isDirectory: true)
    try FileManager.default.createDirectory(
      at: targetDir, withIntermediateDirectories: true
    )
    let filename = "\(shortSHA)-\(filenameTimestamp).json"
    let target = targetDir.appendingPathComponent(filename)
    try data.write(to: target, options: .atomic)
    print("BBB_WAVEFORM_BAND_PERF wrote \(target.path) (commit=\(shortSHA))")
  }

  private func findRepoRoot() throws -> URL {
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    while directory.path != "/" {
      if FileManager.default.fileExists(atPath: directory.appendingPathComponent(".git").path) {
        return directory
      }
      directory = directory.deletingLastPathComponent()
    }
    throw WaveformBandPerfError.repoRootNotFound(from: #filePath)
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
    let output = run(["git", "-C", repoRoot.path, "rev-parse", "HEAD"])
    let full = output.trimmingCharacters(in: .whitespacesAndNewlines)
    if full.isEmpty { return ("unknown" + dirtySuffix, "unknown" + dirtySuffix) }
    return (String(full.prefix(10)) + dirtySuffix, full + dirtySuffix)
  }

  private func isWorkingTreeDirty(repoRoot: URL) -> Bool {
    // Scoped to Sources/, Tests/ and Package.swift, the paths SwiftPM compiles
    // into the measured binary. The baseline JSON under _bmad-output/ does not
    // mark the tree dirty.
    let output = run([
      "git", "-C", repoRoot.path, "status", "--porcelain", "--", "Sources", "Tests",
      "Package.swift",
    ])
    return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func run(_ arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else { return "" }
      return String(decoding: data, as: UTF8.self)
    } catch {
      return ""
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

// MARK: - Memory child

/// Runs only in the child process the memory probe starts: one read of the
/// file named by `BBB_WAVEFORM_BAND_MEMORY_FILE`, then the process's peak
/// resident size in bytes on standard output.
@Suite(
  "WaveformBandLevelReader memory child (Story 15.11)",
  .enabled(
    if: ProcessInfo.processInfo.environment[MemoryChild.fileVariable] != nil,
    "Started by WaveformBandLevelPerfTests with BBB_WAVEFORM_BAND_MEMORY_FILE set"
  )
)
struct WaveformBandLevelMemoryChildTests {
  @Test func readOnceAndReportPeakMemory() throws {
    let path = try #require(ProcessInfo.processInfo.environment[MemoryChild.fileVariable])
    let levels = try WaveformBandLevelReader.read(url: URL(fileURLWithPath: path))
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    // On macOS ru_maxrss is in bytes.
    print("\(MemoryChild.reportPrefix)\(usage.ru_maxrss)")
    #expect(!levels.peak.isEmpty)
  }
}

/// The variable and output line the memory probe and its child share.
private enum MemoryChild {
  static let fileVariable = "BBB_WAVEFORM_BAND_MEMORY_FILE"
  static let reportPrefix = "BBB_WAVEFORM_BAND_MAXRSS="
}

private enum WaveformBandPerfError: Error, CustomStringConvertible {
  case repoRootNotFound(from: String)
  case childReportMissing(status: Int32, output: String)

  var description: String {
    switch self {
    case .repoRootNotFound(let path):
      return "Could not find a .git-rooted parent of \(path)"
    case .childReportMissing(let status, let output):
      return "The memory child exited \(status) without a report:\n\(output)"
    }
  }
}
