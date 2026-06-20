//
//  SharedDecodeImpactTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8-2 shared-decode perf instrumentation (DD #10 / AC8).
//
//  Two env-gated lanes:
//  - T0 probe (`SHARED_DECODE_PROBE=1`): decode-vs-analysis medians per format
//    on OA300, run BEFORE the seam lands. Derives the probe-based floor
//    (>= 0.8 x measured single-decode cost D_f on the decode-heavy formats).
//  - Impact harness (`SHARED_DECODE_IMPACT=1`, T8): sequential-vs-shared
//    wall-clock gates + JSON report, run AFTER the seam lands.
//
//  Run in RELEASE config — Debug timings are not representative:
//    OA300_CORPUS_PATH=... SHARED_DECODE_PROBE=1 swift test -c release \
//      --filter BoomBoomBoomKitBenchmarkTests.SharedDecodeImpactTests
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Shared probe plumbing

/// Format buckets per DD #10: MP3 and FLAC are the decode-heavy gated formats;
/// WAV-class (LPCM payloads: wav + aiff) is reported-only (decode-trivial,
/// noise-dominated).
enum ProbeFormat: String, CaseIterable {
  case mp3
  case flac
  case wavClass = "wav-class"

  var extensions: Set<String> {
    switch self {
    case .mp3: return ["mp3"]
    case .flac: return ["flac"]
    case .wavClass: return ["wav", "aiff"]
    }
  }
}

struct ProbeSample {
  let file: String
  let decodeSeconds: Double
  let bpmSeconds: Double
  let lufsSeconds: Double
}

enum SharedDecodeProbe {

  static func corpusPath() -> String? {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"],
      !path.isEmpty
    else { return nil }
    return path
  }

  /// Resolves OA300 ground-truth rows to on-disk URLs grouped by probe format.
  static func filesByFormat(corpusPath: String) throws -> [ProbeFormat: [URL]] {
    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    let url = try #require(jsonURL, "oa300-ground-truth.json not found in bundle")
    let tracks = try OA300Track.loadCorpus(from: Data(contentsOf: url))
    let base = URL(fileURLWithPath: corpusPath)
    var result: [ProbeFormat: [URL]] = [:]
    for track in tracks {
      let ext = (track.filename as NSString).pathExtension.lowercased()
      guard let format = ProbeFormat.allCases.first(where: { $0.extensions.contains(ext) })
      else { continue }
      var fileURL = base
      if let subdir = track.subdir { fileURL.appendPathComponent(subdir) }
      fileURL.appendPathComponent(track.filename)
      result[format, default: []].append(fileURL)
    }
    return result
  }

  /// Deterministic Fisher-Yates shuffle + prefix cap via SplitMix64 — the
  /// probe's "randomized file order" without run-to-run nondeterminism.
  static func select(_ urls: [URL], cap: Int, seed: UInt64) -> [URL] {
    var rng = SplitMix64(seed: seed)
    var shuffled = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
      let j = Int(rng.next() % UInt64(i + 1))
      shuffled.swapAt(i, j)
    }
    return Array(shuffled.prefix(cap))
  }

  static func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    let mid = sorted.count / 2
    return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
  }

  static func time(_ body: () throws -> Void) rethrows -> Double {
    let start = DispatchTime.now().uptimeNanoseconds
    try body()
    return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
  }
}

// MARK: - T8 impact harness (DD #10 / AC8 — runs AFTER the seam lands)

private struct FormatImpact: Encodable {
  let sequentialMedian: Double
  let sharedMedian: Double
  let decodeMedian: Double
  let achievedSaving: Double
  let floorMet: Bool?
  let fileCount: Int
}

private struct ImpactReport: Encodable {
  let gitSHA: String
  let date: String
  let configuration: String
  let matchedMaxSeconds: Double
  let measuredReps: Int
  let perFormat: [String: FormatImpact]
  let defaultsConfig: [String: Double]
}

@Suite(
  "Shared-Decode Impact Gates",
  .enabled(
    if: ProcessInfo.processInfo.environment["SHARED_DECODE_IMPACT"] == "1"
      && SharedDecodeProbe.corpusPath() != nil),
  .serialized)
struct SharedDecodeImpactGateTests {

  /// AC8 gates over the live seam:
  /// - Hard gate 2 (directional, asserted): shared-path wall-clock must not
  ///   exceed sequential wall-clock beyond measurement noise, per format.
  /// - Probe-derived floor (reported, NOT asserted — AC8: floor misses are
  ///   findings + operator decision, not HALT-theater): achieved saving
  ///   (median of paired per-file savings) ≥ 0.8 × SAME-RUN decode median on
  ///   the decode-heavy formats (mp3, flac). wav-class is reported-only.
  ///   Deliberately the same-run D, not the frozen T0-probe numbers (story
  ///   Debug Log) — same machine, same run is the honest denominator; the T0
  ///   floors are the historical derivation (review 2026-06-11).
  /// - Secondary informational number at library defaults (BPM 120s cap,
  ///   LUFS full-file), labeled secondary — never the headline.
  /// Gate 1 (decode-count == 1) is structural and lives in the unit suite
  /// (`DecodeCountTests`), not here.
  @Test func impactGatesAndReport() async throws {
    let corpus = try #require(SharedDecodeProbe.corpusPath())
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpus)

    let matchedSeconds = 120.0
    let measuredReps = 3
    let perFormatCap = 10
    // Generous noise allowance for the HARD gate: per-file medians on a
    // shared machine jitter a few percent; the gate exists to catch the
    // seam being structurally slower, not scheduler noise.
    let noiseMargin = 1.10
    // Absolute epsilon alongside the relative margin (review 2026-06-11):
    // wav-class medians are decode-trivial, where relative-only jitter
    // bounds are routinely exceeded by scheduler noise — the hard gate must
    // not flake on a format the story classifies as reported-only.
    let noiseEpsilonSeconds = 0.020

    var bpmOptions = AudioAnalysisService.Options()
    bpmOptions.maxSeconds = matchedSeconds
    var lufsOptions = LUFSOptions()
    lufsOptions.maxSeconds = matchedSeconds

    func sequentialOnce(_ url: URL) throws -> Double {
      try SharedDecodeProbe.time {
        _ = try AudioAnalysisService.analyzeBPM(url: url, options: bpmOptions)
        _ = try AudioAnalysisService.analyzeLUFS(url: url, options: lufsOptions)
      }
    }
    func sharedOnce(_ url: URL) throws -> Double {
      try SharedDecodeProbe.time {
        let decoded = try PCMBufferReader.readDecodedAudio(
          from: url, maxSeconds: matchedSeconds)
        _ = try AudioAnalysisService.analyzeBPM(decoded: decoded, options: bpmOptions)
        _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded, options: lufsOptions)
      }
    }

    print("\n=== Story 8-2 shared-decode impact (matched maxSeconds=120) ===")
    #if DEBUG
      print("WARNING: Debug configuration — timings not representative. Use -c release.")
    #endif

    var perFormat: [String: FormatImpact] = [:]
    for format in ProbeFormat.allCases {
      let candidates = byFormat[format] ?? []
      guard !candidates.isEmpty else { continue }
      let files = SharedDecodeProbe.select(candidates, cap: perFormatCap, seed: 0x8_2)

      var sequentialMedians: [Double] = []
      var sharedMedians: [Double] = []
      var decodeMedians: [Double] = []
      var perFileSavings: [Double] = []
      for fileURL in files {
        // Warmups.
        _ = try sequentialOnce(fileURL)
        _ = try sharedOnce(fileURL)
        var seqs: [Double] = []
        var shareds: [Double] = []
        var decodes: [Double] = []
        for rep in 0..<measuredReps {
          // Review 2026-06-11: alternate measurement order per rep — a fixed
          // sequential-then-shared order let the shared path always run on
          // page-cache/codec state warmed by the immediately preceding
          // sequential pass, biasing the comparison in the seam's favor.
          if rep.isMultiple(of: 2) {
            seqs.append(try sequentialOnce(fileURL))
            shareds.append(try sharedOnce(fileURL))
          } else {
            shareds.append(try sharedOnce(fileURL))
            seqs.append(try sequentialOnce(fileURL))
          }
          decodes.append(
            try SharedDecodeProbe.time {
              _ = try PCMBufferReader.readDecodedAudio(
                from: fileURL, maxSeconds: matchedSeconds)
            })
        }
        let seqMedian = SharedDecodeProbe.median(seqs)
        let sharedMedian = SharedDecodeProbe.median(shareds)
        sequentialMedians.append(seqMedian)
        sharedMedians.append(sharedMedian)
        decodeMedians.append(SharedDecodeProbe.median(decodes))
        perFileSavings.append(seqMedian - sharedMedian)
      }

      let sequential = SharedDecodeProbe.median(sequentialMedians)
      let shared = SharedDecodeProbe.median(sharedMedians)
      let decode = SharedDecodeProbe.median(decodeMedians)
      // Review 2026-06-11: the achieved saving is the median of PAIRED
      // per-file savings, not a difference of independent format-level
      // medians — the latter can misstate the typical per-file improvement.
      let saving = SharedDecodeProbe.median(perFileSavings)
      let isGatedFormat = format == .mp3 || format == .flac
      let floorMet: Bool? = isGatedFormat ? saving >= 0.8 * decode : nil

      perFormat[format.rawValue] = FormatImpact(
        sequentialMedian: sequential,
        sharedMedian: shared,
        decodeMedian: decode,
        achievedSaving: saving,
        floorMet: floorMet,
        fileCount: files.count)

      print(
        """
        \(format.rawValue) (n=\(files.count), reps=\(measuredReps)):
          sequential = \(String(format: "%.4f", sequential))s
          shared     = \(String(format: "%.4f", shared))s
          decode D   = \(String(format: "%.4f", decode))s
          saving     = \(String(format: "%.4f", saving))s (floor 0.8*D = \(String(format: "%.4f", 0.8 * decode))s)
          floorMet   = \(floorMet.map(String.init(describing:)) ?? "n/a (reported-only)")
        """)

      // HARD gate 2: never slower than sequential beyond noise.
      #expect(
        shared <= sequential * noiseMargin + noiseEpsilonSeconds,
        "AC8 gate 2 FAILED for \(format.rawValue): shared \(shared)s > sequential \(sequential)s × \(noiseMargin) + \(noiseEpsilonSeconds)s"
      )
      if let floorMet, !floorMet {
        print(
          "FLOOR MISS (\(format.rawValue)): finding for operator decision — "
            + "saving \(String(format: "%.4f", saving))s < 0.8 × D "
            + "\(String(format: "%.4f", 0.8 * decode))s. NOT a HALT.")
      }
    }

    // Review 2026-06-11: the gates must not pass vacuously — assert the
    // decode-heavy gated formats actually resolved files and were measured.
    // A corpus-layout issue would otherwise skip mp3/flac silently while the
    // suite reports green.
    #expect(perFormat["mp3"] != nil, "AC8 coverage: no mp3 files resolved from the corpus")
    #expect(perFormat["flac"] != nil, "AC8 coverage: no flac files resolved from the corpus")

    // Secondary informational number at library defaults (BPM maxSeconds
    // 120 default, LUFS full-file default) on the mp3 set — labeled
    // secondary, never the headline.
    var defaultsConfig: [String: Double] = [:]
    if let mp3Files = byFormat[.mp3], !mp3Files.isEmpty {
      let files = SharedDecodeProbe.select(mp3Files, cap: 5, seed: 0x8_2)
      var seqs: [Double] = []
      var shareds: [Double] = []
      for (index, fileURL) in files.enumerated() {
        _ = try AudioAnalysisService.analyzeBPM(url: fileURL)
        func sequentialDefaults() throws -> Double {
          try SharedDecodeProbe.time {
            _ = try AudioAnalysisService.analyzeBPM(url: fileURL)
            _ = try AudioAnalysisService.analyzeLUFS(url: fileURL)
          }
        }
        func sharedDefaults() throws -> Double {
          try SharedDecodeProbe.time {
            // Library defaults diverge: BPM caps at 120s, LUFS is
            // full-file. A shared decode must cover the larger window
            // (full file) to serve both.
            let decoded = try PCMBufferReader.readDecodedAudio(from: fileURL)
            _ = try AudioAnalysisService.analyzeBPM(decoded: decoded)
            _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
          }
        }
        // Review 2026-06-11: alternate order per file (same warming-bias
        // rationale as the matched-window loop above).
        if index.isMultiple(of: 2) {
          seqs.append(try sequentialDefaults())
          shareds.append(try sharedDefaults())
        } else {
          shareds.append(try sharedDefaults())
          seqs.append(try sequentialDefaults())
        }
      }
      defaultsConfig["sequentialMedian"] = SharedDecodeProbe.median(seqs)
      defaultsConfig["sharedMedian"] = SharedDecodeProbe.median(shareds)
      defaultsConfig["achievedSaving"] =
        SharedDecodeProbe.median(seqs) - SharedDecodeProbe.median(shareds)
      print(
        "defaults-config (SECONDARY, mp3 n=\(files.count)): sequential "
          + "\(String(format: "%.4f", defaultsConfig["sequentialMedian"] ?? 0))s, shared "
          + "\(String(format: "%.4f", defaultsConfig["sharedMedian"] ?? 0))s")
    }

    // JSON emit.
    let outDir =
      ProcessInfo.processInfo.environment["SHARED_DECODE_IMPACT_OUT_DIR"]
      ?? FileManager.default.currentDirectoryPath
    let report = ImpactReport(
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
      perFormat: perFormat,
      defaultsConfig: defaultsConfig)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let outURL = URL(fileURLWithPath: outDir)
      .appendingPathComponent("8-2-shared-decode-impact.json")
    try encoder.encode(report).write(to: outURL)
    print("impact report written: \(outURL.path)")
  }
}

// MARK: - T0 probe (DD #10 — runs BEFORE the seam lands)

@Suite(
  "Shared-Decode T0 Probe",
  .enabled(
    if: ProcessInfo.processInfo.environment["SHARED_DECODE_PROBE"] == "1"
      && SharedDecodeProbe.corpusPath() != nil),
  .serialized)
struct SharedDecodeProbeTests {

  /// DD #10 T0: per-format medians of decode time D, url-path BPM wall-clock
  /// T_bpm, and url-path LUFS wall-clock T_lufs at matched maxSeconds = 120,
  /// default intensity. The decode share of the SEQUENTIAL composition is
  /// D / (T_bpm + T_lufs) — the upper bound on what the shared-decode seam
  /// can recover, since T_bpm and T_lufs each already contain one decode.
  @Test func decodeVsAnalysisProbe() async throws {
    let corpus = try #require(SharedDecodeProbe.corpusPath())
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpus)

    let matchedSeconds = 120.0
    let measuredReps = 3
    let perFormatCap = 10

    var bpmOptions = AudioAnalysisService.Options()
    bpmOptions.maxSeconds = matchedSeconds
    var lufsOptions = LUFSOptions()
    lufsOptions.maxSeconds = matchedSeconds

    print("\n=== Story 8-2 T0 probe — decode vs analysis (matched maxSeconds=120) ===")
    #if DEBUG
      print("WARNING: Debug configuration — timings not representative. Use -c release.")
    #endif

    for format in ProbeFormat.allCases {
      let candidates = byFormat[format] ?? []
      guard !candidates.isEmpty else {
        print("\(format.rawValue): no files — skipped")
        continue
      }
      let files = SharedDecodeProbe.select(candidates, cap: perFormatCap, seed: 0x8_2)

      var perFileSamples: [ProbeSample] = []
      for fileURL in files {
        // Warmup: one untimed pass of each operation primes the page cache
        // and any AVFoundation codec setup.
        _ = try PCMBufferReader.readMonoSamples(from: fileURL, maxSeconds: matchedSeconds)
        _ = try AudioAnalysisService.analyzeBPM(url: fileURL, options: bpmOptions)
        _ = try AudioAnalysisService.analyzeLUFS(url: fileURL, options: lufsOptions)

        var decodes: [Double] = []
        var bpms: [Double] = []
        var lufses: [Double] = []
        for _ in 0..<measuredReps {
          decodes.append(
            try SharedDecodeProbe.time {
              _ = try PCMBufferReader.readMonoSamples(
                from: fileURL, maxSeconds: matchedSeconds)
            })
          bpms.append(
            try SharedDecodeProbe.time {
              _ = try AudioAnalysisService.analyzeBPM(url: fileURL, options: bpmOptions)
            })
          lufses.append(
            try SharedDecodeProbe.time {
              _ = try AudioAnalysisService.analyzeLUFS(url: fileURL, options: lufsOptions)
            })
        }
        perFileSamples.append(
          ProbeSample(
            file: fileURL.lastPathComponent,
            decodeSeconds: SharedDecodeProbe.median(decodes),
            bpmSeconds: SharedDecodeProbe.median(bpms),
            lufsSeconds: SharedDecodeProbe.median(lufses)))
      }

      let dMedian = SharedDecodeProbe.median(perFileSamples.map(\.decodeSeconds))
      let bpmMedian = SharedDecodeProbe.median(perFileSamples.map(\.bpmSeconds))
      let lufsMedian = SharedDecodeProbe.median(perFileSamples.map(\.lufsSeconds))
      let sequential = bpmMedian + lufsMedian
      let decodeShare = sequential > 0 ? dMedian / sequential : 0

      print(
        """
        \(format.rawValue) (n=\(perFileSamples.count), reps=\(measuredReps)):
          decode D       = \(String(format: "%.4f", dMedian))s
          BPM url-path   = \(String(format: "%.4f", bpmMedian))s
          LUFS url-path  = \(String(format: "%.4f", lufsMedian))s
          sequential     = \(String(format: "%.4f", sequential))s
          D-share        = \(String(format: "%.1f", decodeShare * 100))% of sequential
          floor (0.8*D)  = \(String(format: "%.4f", 0.8 * dMedian))s saving required
        """)
      for sample in perFileSamples {
        print(
          "    \(sample.file): D=\(String(format: "%.4f", sample.decodeSeconds))s "
            + "BPM=\(String(format: "%.4f", sample.bpmSeconds))s "
            + "LUFS=\(String(format: "%.4f", sample.lufsSeconds))s")
      }
      #expect(perFileSamples.count > 0)
    }
  }
}
