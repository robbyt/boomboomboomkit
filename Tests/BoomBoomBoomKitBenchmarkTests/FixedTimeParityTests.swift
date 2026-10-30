//
//  FixedTimeParityTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Runs `FixedTimeTechnique` (the Swift runtime path: decode, 44.1 kHz,
//  crops, rhythm ranking, BNNSGraph inference, mean of softmax) on the first
//  rows of a Python scores file and records, per track, the kept crop starts
//  and the decoded BPM from both sides.
//
//  Inputs come only from the environment, so nothing develop-only is named
//  here:
//    FIXED_TIME_PARITY=1           enables the suite
//    FIXED_TIME_SCORES_JSON        the Python scores file (rows with trackId,
//                                  variantBPM, keptCrops[].startFrame)
//    FIXED_TIME_MODEL_URL          the compiled .mlmodelc the Python model was
//                                  exported to
//    GIANTSTEPS_CORPUS_PATH        where the audio lives (<root>/audio/<trackId>)
//    FIXED_TIME_PARITY_LIMIT       rows to run (default 20)
//    FIXED_TIME_PARITY_OUT         where to write the per-track JSON (optional)
//
//  Passes when at least 90 % of the rows (18 of 20) decode the same BPM.
//  Env-gated; `make test` does not run it.
//

import Foundation
import Testing

// `@testable` for `BPMDiagnosticTrace()`, whose initializer is internal.
@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

private struct ScoresFile: Decodable {
  let rows: [ScoresRow]
}

private struct ScoresRow: Decodable {
  let trackId: String
  let variantBPM: Double?
  let abstained: String?
  let keptCrops: [KeptCrop]
}

private struct KeptCrop: Decodable {
  let startFrame: Int
}

private struct ParityRow: Encodable {
  let trackId: String
  let pythonBPM: Double?
  let swiftBPM: Double?
  let pythonKeptStarts: [Int]
  let swiftKeptStarts: [Int]
  let pythonAbstained: String?
  let swiftAbstained: String?
  let bpmMatches: Bool
  let keptStartsMatch: Bool
}

private struct ParityReport: Encodable {
  let scoresFile: String
  let modelURL: String
  let rows: [ParityRow]
  let bpmMatches: Int
  let keptStartsMatches: Int
  let total: Int
}

private let env = ProcessInfo.processInfo.environment

@Suite(
  "Fixed-time Swift vs Python parity",
  .enabled(if: env["FIXED_TIME_PARITY"] == "1", "set FIXED_TIME_PARITY=1"))
struct FixedTimeParityTests {

  @Test("Swift FixedTimeTechnique matches the Python scores on GiantSteps rows")
  func parity() throws {
    let scoresPath = try #require(env["FIXED_TIME_SCORES_JSON"], "FIXED_TIME_SCORES_JSON")
    let modelPath = try #require(env["FIXED_TIME_MODEL_URL"], "FIXED_TIME_MODEL_URL")
    let corpus = try #require(env["GIANTSTEPS_CORPUS_PATH"], "GIANTSTEPS_CORPUS_PATH")
    let limit = Int(env["FIXED_TIME_PARITY_LIMIT"] ?? "") ?? 20

    let scores = try JSONDecoder().decode(
      ScoresFile.self, from: Data(contentsOf: URL(fileURLWithPath: scoresPath)))
    let technique = try FixedTimeTechnique(modelURL: URL(fileURLWithPath: modelPath))
    let rows = Array(scores.rows.prefix(limit))
    try #require(!rows.isEmpty, "no rows in \(scoresPath)")

    var out: [ParityRow] = []
    for row in rows {
      let root = URL(fileURLWithPath: corpus)
      let candidates = [
        root.appendingPathComponent("audio").appendingPathComponent(row.trackId),
        root.appendingPathComponent(row.trackId),
      ]
      let audioURL = try #require(
        candidates.first { FileManager.default.fileExists(atPath: $0.path) },
        "audio for \(row.trackId) not found under \(corpus)")
      let decoded = try PCMBufferReader.readDecodedAudio(from: audioURL)
      let result = technique.evaluate(trace: BPMDiagnosticTrace(), audio: decoded)
      let swiftStarts = result.crops?.keptCrops.map(\.startFrame) ?? []
      let pythonStarts = row.keptCrops.map(\.startFrame)
      let parity = ParityRow(
        trackId: row.trackId,
        pythonBPM: row.variantBPM,
        swiftBPM: result.evaluation?.bpm,
        pythonKeptStarts: pythonStarts,
        swiftKeptStarts: swiftStarts,
        pythonAbstained: row.abstained,
        swiftAbstained: result.crops?.abstainReason?.rawValue,
        bpmMatches: row.variantBPM == result.evaluation?.bpm,
        keptStartsMatch: pythonStarts == swiftStarts)
      out.append(parity)
      print(
        "[fixed-time-parity] \(row.trackId): python \(row.variantBPM.map { "\($0)" } ?? "nil") "
          + "\(pythonStarts), swift \(result.evaluation.map { "\($0.bpm)" } ?? "nil") "
          + "\(swiftStarts)\(parity.bpmMatches ? "" : "  MISMATCH")")
    }

    let bpmMatches = out.filter(\.bpmMatches).count
    let startMatches = out.filter(\.keptStartsMatch).count
    print(
      "[fixed-time-parity] BPM matches \(bpmMatches)/\(out.count); "
        + "kept starts match \(startMatches)/\(out.count)")
    if let outPath = env["FIXED_TIME_PARITY_OUT"], !outPath.isEmpty {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let report = ParityReport(
        scoresFile: scoresPath, modelURL: modelPath, rows: out, bpmMatches: bpmMatches,
        keptStartsMatches: startMatches, total: out.count)
      try encoder.encode(report).write(to: URL(fileURLWithPath: outPath))
      print("[fixed-time-parity] wrote \(outPath)")
    }
    let required = Int((Double(out.count) * 0.9).rounded(.up))
    #expect(
      bpmMatches >= required,
      "\(bpmMatches)/\(out.count) BPMs match Python; at least \(required) required")
  }
}
