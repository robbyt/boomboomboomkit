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
//  Story 8.8c migrated the fixture to a JAMS corpus, so this test now reads it
//  through the shared `JAMSCorpus` decoder (`BoomBoomBoomKitTestSupport`) instead of
//  a local mirror struct: `schema_version`/`regression_threshold` from the corpus
//  sandbox, per-track `ground_truth_bpm`/`rationale`/`partition` from the entries.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("DnB targets file (Story 4-6 AC #6)")
struct DnBTargetsFileLoadingTests {

  /// AC #6: load the schema-v3 fixture and assert the invariants the
  /// impact-report harness depends on:
  ///  - schema_version == 3 (corpus sandbox)
  ///  - targets.count == 4 (named-failure partition unchanged from v2)
  ///  - dsp_correct_controls.count >= 4 (DD #4 minimum)
  ///  - No duplicate track_id across targets ∪ dsp_correct_controls
  ///  - All controls in 155-175 BPM range (DD #4 mechanical-possibility)
  ///  - All controls carry non-empty rationale text
  @Test("loadsSchemaVersion3 with uniqueness invariants")
  func loadsSchemaVersion3() throws {
    let fileURL = Self.fixtureURL()
    let data = try Data(contentsOf: fileURL)
    let corpus = try JSONDecoder().decode(JAMSCorpus.self, from: data)

    #expect(corpus.sandbox?.schemaVersion == 3)

    // `dnbPartitioned()` enforces completeness + non-nil track_id + numeric tempo for
    // every entry (throws on a malformed one), so an unexpected/absent partition can no
    // longer hide under the `controls >= 4` floor.
    let (targets, controls) = try corpus.dnbPartitioned()
    #expect(targets.count == 4)
    #expect(controls.count >= 4)

    var seenIDs = Set<String>()
    for t in targets {
      #expect(
        seenIDs.insert(t.trackID).inserted,
        "duplicate track_id in targets: \(t.trackID)")
    }
    for c in controls {
      #expect(
        seenIDs.insert(c.trackID).inserted,
        "duplicate track_id across targets ∪ controls: \(c.trackID)")
      // DD #4: controls must be in 155-175 BPM range so the half-tempo
      // failure mode is mechanically possible.
      #expect(
        c.bpm >= 155.0 && c.bpm <= 175.0,
        "\(c.trackID) ground_truth_bpm \(c.bpm) outside 155-175 range")
      let rationale = c.file.sandbox?.rationale ?? ""
      #expect(!rationale.isEmpty, "\(c.trackID) missing rationale")
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
