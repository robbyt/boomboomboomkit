//
//  dnb-triplet-baseline.swift
//  BoomBoomBoomKit
//
//  Reproducibility-load-bearing one-shot script that captures the predicted BPM
//  for the 4 named DnB-triplet tracks at the current pre-source-change pipeline
//  defaults. Used by Story 4.3 Task 1.3 to populate
//  `_bmad-output/implementation-artifacts/4-dnb-triplet-targets.json` and
//  inherited by Stories 4.5 and 4.6 for `current_predicted_bpm` refresh under
//  the `-revN` toolchain-change policy (AC #8).
//
//  The 4 named tracks come from the Epic 3 retro 2026-05-03 footnote naming
//  these as the upstream-onset-quality failure cases for clipped/limited DnB.
//
//  ## How to run
//
//  This file is committed at `_bmad-output/scripts/` rather than under
//  `Tests/BoomBoomBoomKitBenchmarkTests/` (AC #11 invariant preserves the
//  benchmark target's diff-empty status during snapshot capture). To execute:
//
//  1. Copy this file's body into a temporary test file under
//     `Tests/BoomBoomBoomKitTests/DnBTripletBaselineTests.swift` (the unit
//     test target — Tests/BoomBoomBoomKitBenchmarkTests/ is off-limits).
//  2. Run with the OA300 corpus env var set:
//     ```
//     OA300_CORPUS_PATH="/path/to/OA300_OnsetAudio300" \
//     swift test --filter BoomBoomBoomKitTests.DnBTripletBaselineTests
//     ```
//  3. Capture stdout — the test prints one JSON object per track
//     (`track_id`, `ground_truth_bpm`, `current_predicted_bpm`, `current_abs_error`).
//  4. Hand-merge the output into `4-dnb-triplet-targets.json`'s `targets` array.
//  5. Delete the temporary test file before committing.
//
//  Stories 4.5 and 4.6 dev agents repeat steps 1-5 against the post-Story-4.5
//  and post-Story-4.6 pipelines respectively, capturing `-rev2.json` /
//  `-rev3.json` per the AC #8 refresh policy.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite(
  "DnB triplet baseline (manual)",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil))
struct DnBTripletBaselineTests {

  /// The 4 named tracks plus their ground-truth BPM and source-of-truth.
  /// Sources:
  ///   - `dawproject` — present in `corpus.dawproject` and surfaces in
  ///     `daw-oracle.json` after `make oracle-generate`. Reflects manual
  ///     verification by the DAW author.
  ///   - `daw_oracle` — present in `daw-oracle.json` with a Rekordbox-vs-DAW
  ///     octave disagreement; the DAW value is the diagnostic truth.
  private struct NamedTrack {
    let trackID: String
    let relativePath: String
    let groundTruthBPM: Double
    let source: String
  }

  private let tracks: [NamedTrack] = [
    NamedTrack(
      trackID: "The Prodigy - 160 Experience - 06 Charly (Neekeetone Jungle Rework)",
      relativePath:
        "T Tunes/The Prodigy - 160 Experience - 06 Charly (Neekeetone Jungle Rework).aiff",
      groundTruthBPM: 160.0,
      source: "dawproject"),
    NamedTrack(
      trackID: "1. The Faraday_Bunker (D-Struct Remix)",
      relativePath: "1. The Faraday_Bunker (D-Struct Remix).wav",
      groundTruthBPM: 170.0,
      source: "dawproject"),
    NamedTrack(
      trackID: "4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix)",
      relativePath: "4. Yin Yang Audio_Within Cells Interlinked (Acid Lab Remix).wav",
      groundTruthBPM: 170.0,
      source: "daw_oracle"),
    NamedTrack(
      trackID: "9. HEFT_Anagram 6 (Owl Remix)",
      relativePath: "9. HEFT_Anagram 6 (Owl Remix).wav",
      groundTruthBPM: 170.0,
      source: "daw_oracle"),
  ]

  @Test("emit per-track current_predicted_bpm and current_abs_error")
  func emitBaselines() throws {
    let corpus = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] ?? ""
    let corpusURL = URL(fileURLWithPath: corpus, isDirectory: true)
    print("=== DnB triplet baseline ===")
    for t in tracks {
      let url = corpusURL.appendingPathComponent(t.relativePath)
      let result = try AudioAnalysisService.analyzeBPM(url: url)
      let predicted = result?.bpm ?? Double.nan
      let absError = abs(predicted - t.groundTruthBPM)
      print(
        """
        {
          "track_id": "\(t.trackID)",
          "ground_truth_bpm": \(t.groundTruthBPM),
          "source": "\(t.source)",
          "current_predicted_bpm": \(predicted),
          "current_abs_error": \(absError)
        }
        """)
    }
  }
}
