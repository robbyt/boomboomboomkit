//
//  main.swift
//  swift-feature-extractor (tony-dsp-prepass)
//
//  Develop-only CLI. Runs BoomBoomBoomKit's public DSP pipeline against every
//  resolved track in a Rekordbox survey JSON (output of
//  scripts/tony-tunes-survey.py) and dumps per-track {bpm, confidence,
//  candidates} to JSON. Consumed by scripts/tony-tunes-labels.py as the DSP
//  signal in the weighted-ensemble labeler.
//
//  Usage:
//    swift run tony-dsp-prepass \
//      --survey-json <survey.json> \
//      --output <tony-dsp-results.json> \
//      [--concurrency N] [--intensity 1..10] [--limit N]
//
//  Default concurrency = ProcessInfo.processInfo.activeProcessorCount.
//  Default intensity = 7 (.default — matches the consumer default).
//

import BoomBoomBoomKit
import Foundation

// ---------------------------------------------------------------------------
// CLI parsing
// ---------------------------------------------------------------------------

struct CLI: Sendable {
  var surveyJSON: URL
  var output: URL
  var concurrency: Int
  var intensity: Int
  var limit: Int?

  static func parse(_ argv: [String]) -> CLI {
    var surveyJSON: URL?
    var output: URL?
    var concurrency = ProcessInfo.processInfo.activeProcessorCount
    var intensity = 7
    var limit: Int?

    var i = 1
    while i < argv.count {
      let arg = argv[i]
      switch arg {
      case "--survey-json":
        i += 1
        surveyJSON = URL(fileURLWithPath: argv[i])
      case "--output":
        i += 1
        output = URL(fileURLWithPath: argv[i])
      case "--concurrency":
        i += 1
        concurrency = max(1, Int(argv[i]) ?? concurrency)
      case "--intensity":
        i += 1
        intensity = max(1, min(10, Int(argv[i]) ?? intensity))
      case "--limit":
        i += 1
        limit = Int(argv[i])
      case "--help", "-h":
        printUsage()
        exit(0)
      default:
        fputs("error: unknown flag: \(arg)\n", stderr)
        printUsage()
        exit(2)
      }
      i += 1
    }

    guard let surveyJSON, let output else {
      fputs("error: --survey-json and --output are required\n", stderr)
      printUsage()
      exit(2)
    }

    return CLI(
      surveyJSON: surveyJSON, output: output,
      concurrency: concurrency, intensity: intensity, limit: limit)
  }
}

func printUsage() {
  let usage = """
    usage: tony-dsp-prepass --survey-json <path> --output <path>
                            [--concurrency N] [--intensity 1..10] [--limit N]

    Reads a survey JSON produced by scripts/tony-tunes-survey.py, filters to
    tracks where resolve_status == "ok", runs AudioAnalysisService.analyzeBPM
    against each in a bounded TaskGroup, and writes per-track DSP results to
    --output.
    """
  fputs(usage + "\n", stderr)
}

// ---------------------------------------------------------------------------
// Survey JSON shape (subset we consume)
// ---------------------------------------------------------------------------

struct SurveyTrack: Decodable, Sendable {
  let trackId: String
  let name: String
  let artist: String
  let localPath: String?
  let resolveStatus: String

  enum CodingKeys: String, CodingKey {
    case trackId = "track_id"
    case name
    case artist
    case localPath = "local_path"
    case resolveStatus = "resolve_status"
  }
}

struct SurveyJSON: Decodable, Sendable {
  let tracks: [SurveyTrack]
}

// ---------------------------------------------------------------------------
// Output JSON shape
// ---------------------------------------------------------------------------

struct DSPCandidate: Encodable, Sendable {
  let bpm: Double
  let score: Double
}

struct DSPTrackResult: Encodable, Sendable {
  let trackId: String
  let localPath: String
  let bpm: Double?
  let confidence: Double?
  let candidates: [DSPCandidate]
  let error: String?

  enum CodingKeys: String, CodingKey {
    case trackId = "track_id"
    case localPath = "local_path"
    case bpm
    case confidence
    case candidates
    case error
  }
}

struct DSPRunMetadata: Encodable, Sendable {
  let schemaVersion: Int
  let generatedAt: String
  let surveySource: String
  let intensity: Int
  let concurrency: Int
  let trackCount: Int

  enum CodingKeys: String, CodingKey {
    case schemaVersion = "schema_version"
    case generatedAt = "generated_at"
    case surveySource = "survey_source"
    case intensity
    case concurrency
    case trackCount = "track_count"
  }
}

struct DSPOutput: Encodable, Sendable {
  let metadata: DSPRunMetadata
  let tracks: [DSPTrackResult]
}

// ---------------------------------------------------------------------------
// Single-track analysis (synchronous — analyzeBPM is sync `throws`)
// ---------------------------------------------------------------------------

func analyze(track: SurveyTrack, intensity: Int) -> DSPTrackResult {
  guard let path = track.localPath, track.resolveStatus == "ok" else {
    return DSPTrackResult(
      trackId: track.trackId, localPath: track.localPath ?? "",
      bpm: nil, confidence: nil, candidates: [],
      error: "skipped: resolve_status=\(track.resolveStatus)")
  }

  let url = URL(fileURLWithPath: path)
  var options = AudioAnalysisService.Options()
  options.intensity = AnalysisIntensity(rawValue: intensity)

  do {
    guard let result = try AudioAnalysisService.analyzeBPM(url: url, options: options) else {
      return DSPTrackResult(
        trackId: track.trackId, localPath: path,
        bpm: nil, confidence: nil, candidates: [],
        error: "analyzeBPM returned nil (silence / too short / non-musical)")
    }
    let topCandidates = result.candidates.prefix(5).map {
      DSPCandidate(bpm: $0.bpm, score: Double($0.score))
    }
    return DSPTrackResult(
      trackId: track.trackId, localPath: path,
      bpm: result.bpm, confidence: result.confidence,
      candidates: Array(topCandidates), error: nil)
  } catch {
    return DSPTrackResult(
      trackId: track.trackId, localPath: path,
      bpm: nil, confidence: nil, candidates: [],
      error: "\(type(of: error)): \(error)")
  }
}

// ---------------------------------------------------------------------------
// Bounded concurrent batch
// ---------------------------------------------------------------------------

func runBatch(
  tracks: [SurveyTrack], concurrency: Int, intensity: Int
) async -> [DSPTrackResult] {
  let total = tracks.count
  let completedCounter = Counter()
  var results: [DSPTrackResult?] = Array(repeating: nil, count: total)

  await withTaskGroup(of: (Int, DSPTrackResult).self) { group in
    var nextToSubmit = 0
    var inflight = 0

    func submitNext() {
      guard nextToSubmit < total else { return }
      let idx = nextToSubmit
      let track = tracks[idx]
      nextToSubmit += 1
      inflight += 1
      group.addTask {
        let started = Date()
        let result = analyze(track: track, intensity: intensity)
        let done = await completedCounter.increment()
        let elapsed = Date().timeIntervalSince(started)
        let basename = (track.localPath as NSString?)?.lastPathComponent ?? track.trackId
        fputs(
          String(
            format: "[%d/%d] %@ — %.2fs%@\n",
            done, total, basename, elapsed, result.error.map { " ERR: \($0)" } ?? ""),
          stderr)
        return (idx, result)
      }
    }

    // Prime the pump.
    for _ in 0..<min(concurrency, total) { submitNext() }

    // Drain + refill.
    while let (idx, value) = await group.next() {
      results[idx] = value
      inflight -= 1
      submitNext()
    }
    _ = inflight  // silence unused warning under release builds
  }

  return results.compactMap { $0 }
}

actor Counter {
  private(set) var value: Int = 0
  func increment() -> Int {
    value += 1
    return value
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

@main
struct App {
  static func main() async {
    let cli = CLI.parse(CommandLine.arguments)

    // Load survey JSON.
    let surveyData: Data
    do {
      surveyData = try Data(contentsOf: cli.surveyJSON)
    } catch {
      fputs("error: cannot read survey JSON at \(cli.surveyJSON.path): \(error)\n", stderr)
      exit(2)
    }

    let survey: SurveyJSON
    do {
      survey = try JSONDecoder().decode(SurveyJSON.self, from: surveyData)
    } catch {
      fputs("error: cannot parse survey JSON: \(error)\n", stderr)
      exit(2)
    }

    var resolved = survey.tracks.filter { $0.resolveStatus == "ok" && $0.localPath != nil }
    if let limit = cli.limit {
      resolved = Array(resolved.prefix(limit))
    }

    fputs(
      "tony-dsp-prepass: \(resolved.count) tracks, intensity=\(cli.intensity), "
        + "concurrency=\(cli.concurrency)\n",
      stderr)

    let started = Date()
    let results = await runBatch(
      tracks: resolved, concurrency: cli.concurrency, intensity: cli.intensity)
    let elapsed = Date().timeIntervalSince(started)

    let okCount = results.filter { $0.error == nil }.count
    let errCount = results.count - okCount
    fputs(
      String(
        format: "done in %.1fs — %d ok, %d errors\n", elapsed, okCount, errCount),
      stderr)

    let metadata = DSPRunMetadata(
      schemaVersion: 1,
      generatedAt: ISO8601DateFormatter().string(from: Date()),
      surveySource: cli.surveyJSON.path,
      intensity: cli.intensity,
      concurrency: cli.concurrency,
      trackCount: results.count)
    let output = DSPOutput(metadata: metadata, tracks: results)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
      let data = try encoder.encode(output)
      try data.write(to: cli.output, options: .atomic)
      fputs("wrote \(cli.output.path)\n", stderr)
    } catch {
      fputs("error: cannot write output JSON: \(error)\n", stderr)
      exit(2)
    }
  }
}
