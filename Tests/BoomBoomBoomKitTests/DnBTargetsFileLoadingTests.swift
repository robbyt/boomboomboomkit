//
//  DnBTargetsFileLoadingTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 Task 5: schema_version 3 + uniqueness invariants for the
//  `4-dnb-triplet-targets.json` fixture under `Tests/BoomBoomBoomKitBenchmarkTests/Fixtures/`.
//  The actual fixture lives in the benchmark target so this test
//  resolves the path via the SPM-known `Sources/.../` parent rather
//  than `Bundle.module` (the unit test target doesn't ship the
//  benchmark target's resources).
//

import Foundation
import Testing

@Suite("DnB targets file (Story 4-6 AC #6)")
struct DnBTargetsFileLoadingTests {

  /// Minimal mirror of the fixture's decode shape used only for this
  /// test. Mirrors `DnBTargetsFile` in `Tests/BoomBoomBoomKitBenchmarkTests/BNNSImpactTests.swift`
  /// but avoids cross-target import.
  private struct File: Decodable {
    let schema_version: Int
    let targets: [Entry]
    let dsp_correct_controls: [Control]
  }
  private struct Entry: Decodable {
    let track_id: String
    let ground_truth_bpm: Double
  }
  private struct Control: Decodable {
    let track_id: String
    let ground_truth_bpm: Double
    let rationale: String
  }

  /// AC #6: load the schema-v3 fixture and assert the invariants the
  /// impact-report harness depends on:
  ///  - schema_version == 3
  ///  - targets.count == 4 (named-failure partition unchanged from v2)
  ///  - dsp_correct_controls.count >= 4 (DD #4 minimum)
  ///  - No duplicate track_id across targets ∪ dsp_correct_controls
  ///  - All controls in 155-175 BPM range (DD #4 mechanical-possibility)
  ///  - All controls carry non-empty rationale text
  @Test("loadsSchemaVersion3 with uniqueness invariants")
  func loadsSchemaVersion3() throws {
    let fileURL = Self.fixtureURL()
    let data = try Data(contentsOf: fileURL)
    let file = try JSONDecoder().decode(File.self, from: data)

    #expect(file.schema_version == 3)
    #expect(file.targets.count == 4)
    #expect(file.dsp_correct_controls.count >= 4)

    var seenIDs = Set<String>()
    for t in file.targets {
      #expect(
        seenIDs.insert(t.track_id).inserted,
        "duplicate track_id in targets: \(t.track_id)")
    }
    for c in file.dsp_correct_controls {
      #expect(
        seenIDs.insert(c.track_id).inserted,
        "duplicate track_id across targets ∪ controls: \(c.track_id)")
      // DD #4: controls must be in 155-175 BPM range so the half-tempo
      // failure mode is mechanically possible.
      #expect(
        c.ground_truth_bpm >= 155.0 && c.ground_truth_bpm <= 175.0,
        "\(c.track_id) ground_truth_bpm \(c.ground_truth_bpm) outside 155-175 range")
      #expect(!c.rationale.isEmpty, "\(c.track_id) missing rationale")
    }
  }

  /// Resolves the on-disk path to the fixture by walking up from the
  /// current source file's directory. The fixture lives in the
  /// benchmark target's `Fixtures/` directory; unit tests can't reach
  /// it via `Bundle.module` because they're a different SPM target.
  private static func fixtureURL() -> URL {
    let sourceFileURL = URL(fileURLWithPath: #filePath)
    return
      sourceFileURL
      .deletingLastPathComponent()  // Tests/BoomBoomBoomKitTests
      .deletingLastPathComponent()  // Tests/
      .appendingPathComponent("BoomBoomBoomKitBenchmarkTests")
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("4-dnb-triplet-targets.json")
  }
}
