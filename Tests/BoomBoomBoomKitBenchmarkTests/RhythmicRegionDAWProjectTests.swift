import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

/// Raw rows emitted by `scripts/dawproject-bpm.py <project> --json`.
private struct DAWProjectClip: Decodable {
  let file: String
  let bpm: Double
}

private struct DAWProjectLabel {
  let file: String
  let bpm: Double
}

private struct DAWProjectConflict {
  let file: String
  let bpms: [Double]
}

private func dawProjectLabels(from clips: [DAWProjectClip]) -> (
  consistent: [DAWProjectLabel], conflicting: [DAWProjectConflict]
) {
  let grouped = Dictionary(grouping: clips, by: \.file)
  var consistent: [DAWProjectLabel] = []
  var conflicting: [DAWProjectConflict] = []
  for file in grouped.keys.sorted() {
    guard let rows = grouped[file] else { continue }
    let bpms = rows.map(\.bpm).sorted()
    // Adjacent warp readings may differ by a few hundredths due to rounding.
    // A wider spread represents conflicting annotations, not a single truth.
    if let first = bpms.first, let last = bpms.last,
      first.isFinite, last.isFinite, first > 0, last - first <= 0.1
    {
      consistent.append(DAWProjectLabel(file: file, bpm: bpms.reduce(0, +) / Double(bpms.count)))
    } else {
      conflicting.append(DAWProjectConflict(file: file, bpms: bpms))
    }
  }
  return (consistent, conflicting)
}

@Suite("DAWProject label selection")
struct DAWProjectLabelSelectionTests {
  @Test("conflicting warp labels are excluded; nearby readings are averaged")
  func conflictingLabels() throws {
    let clips = try JSONDecoder().decode(
      [DAWProjectClip].self,
      from: Data(
        """
        [{"file":"audio/steady.mp3","bpm":120.0},
         {"file":"audio/steady.mp3","bpm":120.04},
         {"file":"audio/conflict.mp3","bpm":94.68},
         {"file":"audio/conflict.mp3","bpm":133.49},
         {"file":"audio/zero.mp3","bpm":0},
         {"file":"audio/negative.mp3","bpm":-120}]
        """.utf8))
    let labels = dawProjectLabels(from: clips)
    #expect(labels.consistent.count == 1)
    #expect(labels.consistent.first?.file == "audio/steady.mp3")
    #expect(abs((labels.consistent.first?.bpm ?? 0) - 120.02) < 0.0001)
    #expect(
      labels.conflicting.map(\.file) == [
        "audio/conflict.mp3", "audio/negative.mp3", "audio/zero.mp3",
      ])
  }
}

@Suite(
  "DAWProject rhythmic region comparison",
  .enabled(if: ProcessInfo.processInfo.environment["RHYTHMIC_REGION_DAWPROJECT"] == "1")
)
struct RhythmicRegionDAWProjectTests {
  @Test("paired historical, rhythmic, and uniform results", .timeLimit(.minutes(120)))
  func compare() throws {
    let environment = ProcessInfo.processInfo.environment
    let labelsPath = try #require(environment["DAWPROJECT_LABELS_JSON"])
    let audioPath = try #require(environment["DAWPROJECT_AUDIO_DIR"])
    let outputPath = try #require(environment["DAWPROJECT_REPORT_JSON"])
    let clips = try JSONDecoder().decode(
      [DAWProjectClip].self, from: Data(contentsOf: URL(fileURLWithPath: labelsPath)))
    let labels = dawProjectLabels(from: clips)
    try #require(labels.consistent.count == 283)
    try #require(labels.conflicting.count == 4)
    var results: [[String: Any]] = []

    for (index, row) in labels.consistent.enumerated() {
      if index.isMultiple(of: 10) {
        FileHandle.standardError.write(
          Data("DAWProject: \(index)/\(labels.consistent.count)\n".utf8))
      }
      let url = URL(fileURLWithPath: audioPath).appendingPathComponent(row.file)
      try #require(FileManager.default.fileExists(atPath: url.path), "Missing \(row.file)")
      var armResults: [String: Any] = [:]
      // Rotate order to spread warm-file effects across arms.
      for shift in 0..<3 {
        let arm = (index + shift) % 3
        let name = ["A", "C", "D"][arm]
        var options = AudioAnalysisService.Options()
        options.enableTrace = false
        options.useRhythmicRegions = arm != 0
        options.useUniformRegionControl = arm == 2
        options.mergeStrategy = arm == 0 ? .maxConfidence : .windowVoting
        options.votingPolicy = .simpleMajority
        let start = ProcessInfo.processInfo.systemUptime
        do {
          let result = try AudioAnalysisService.analyzeBPM(url: url, options: options)
          let elapsed = ProcessInfo.processInfo.systemUptime - start
          armResults[name] =
            [
              "bpm": result?.bpm as Any? ?? NSNull(),
              "acc1": result.map { isAcc1Match($0.bpm, row.bpm, tolerance: 0.02) } ?? false,
              "acc2": result.map { isAcc2Match($0.bpm, row.bpm, tolerance: 0.02) } ?? false,
              "seconds": elapsed,
            ] as [String: Any]
        } catch {
          armResults[name] =
            [
              "bpm": NSNull(), "acc1": false, "acc2": false,
              "seconds": ProcessInfo.processInfo.systemUptime - start,
              "error": String(describing: error),
            ] as [String: Any]
        }
      }
      results.append(["file": row.file, "truthBPM": row.bpm, "arms": armResults])
    }

    func matching(_ arm: String, _ metric: String) -> Int {
      results.reduce(0) { count, row in
        let arms = row["arms"] as? [String: [String: Any]]
        return count + ((arms?[arm]?[metric] as? Bool) == true ? 1 : 0)
      }
    }
    let counts: [String: [String: Int]] = Dictionary(
      uniqueKeysWithValues: ["A", "C", "D"].map {
        ($0, ["acc1": matching($0, "acc1"), "acc2": matching($0, "acc2")])
      })
    let gained = results.compactMap { row -> String? in
      let arms = row["arms"] as? [String: [String: Any]]
      return (arms?["C"]?["acc1"] as? Bool) == true
        && (arms?["A"]?["acc1"] as? Bool) == false ? row["file"] as? String : nil
    }
    let lost = results.compactMap { row -> String? in
      let arms = row["arms"] as? [String: [String: Any]]
      return (arms?["A"]?["acc1"] as? Bool) == true
        && (arms?["C"]?["acc1"] as? Bool) == false ? row["file"] as? String : nil
    }
    let cVsDGained = results.compactMap { row -> String? in
      let arms = row["arms"] as? [String: [String: Any]]
      return (arms?["C"]?["acc1"] as? Bool) == true
        && (arms?["D"]?["acc1"] as? Bool) == false ? row["file"] as? String : nil
    }
    let cVsDLost = results.compactMap { row -> String? in
      let arms = row["arms"] as? [String: [String: Any]]
      return (arms?["D"]?["acc1"] as? Bool) == true
        && (arms?["C"]?["acc1"] as? Bool) == false ? row["file"] as? String : nil
    }
    // A failed or partial run must not replace the committed report.
    try #require(results.count == 283)
    for name in ["A", "C", "D"] {
      let failed = results.compactMap { row -> String? in
        let arms = row["arms"] as? [String: [String: Any]]
        let result = arms?[name]
        return result?["bpm"] is Double && result?["error"] == nil
          ? nil : row["file"] as? String
      }
      try #require(failed.isEmpty, "\(name) failed analysis for: \(failed.prefix(5))")
    }
    try #require(counts["A"]?["acc1"] == 224 && counts["A"]?["acc2"] == 238)
    try #require(counts["C"]?["acc1"] == 236 && counts["C"]?["acc2"] == 249)
    try #require(counts["D"]?["acc1"] == 238 && counts["D"]?["acc2"] == 254)
    try #require(gained.count == 25 && lost.count == 13)
    let report: [String: Any] = [
      "source": "scripts/dawproject-bpm.py --json; per-file warp BPM, consistent annotations",
      "excludedConflictingFiles": labels.conflicting.map {
        ["file": $0.file, "bpms": $0.bpms] as [String: Any]
      },
      "trackCount": labels.consistent.count,
      "counts": counts,
      "cVsAAcc1GainedFiles": gained,
      "cVsAAcc1LostFiles": lost,
      "cVsDAcc1GainedFiles": cVsDGained,
      "cVsDAcc1LostFiles": cVsDLost,
      "arms": [
        "A": "historical maxConfidence, first-transition windows",
        "C": "rhythmic disjoint regions, windowVoting/simpleMajority",
        "D": "uniform disjoint regions, windowVoting/simpleMajority",
      ],
      "rows": results,
    ]
    let data = try JSONSerialization.data(
      withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
    print("DAWProject comparison: \(outputPath)")
  }
}
