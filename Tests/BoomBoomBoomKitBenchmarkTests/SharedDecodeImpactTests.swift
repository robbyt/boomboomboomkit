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
    let tracks = try JSONDecoder().decode([OA300Track].self, from: Data(contentsOf: url))
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
