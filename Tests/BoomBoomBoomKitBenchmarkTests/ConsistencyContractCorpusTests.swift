//
//  ConsistencyContractCorpusTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8.5 AC8 (corpus rate): over the OA300 corpus, the combined
//  `analyze(url:)` must produce a sync-usable BPM/beat-grid agreement
//  (`.agree` or `.octaveEquivalent`, i.e. NOT `.disagree`) for >= 90% of
//  analyzable tracks — exactly 2manyDJs's `tempoAgreement != .disagree` gate.
//  The agree / octaveEquivalent(+2) / octaveEquivalent(-2) / disagree breakdown
//  is reported so a regression in the OCTAVE split is visible, not masked by the
//  headline rate.
//
//  Env-gated (needs OA300_CORPUS_PATH). Config-agnostic (accuracy, not timing):
//    OA300_CORPUS_PATH=... OA300_CONSISTENCY=1 swift test \
//      --filter BoomBoomBoomKitBenchmarkTests.ConsistencyContractCorpusTests
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite(
  "Consistency Contract — OA300 rate",
  .enabled(
    if: ProcessInfo.processInfo.environment["OA300_CONSISTENCY"] == "1"
      && SharedDecodeProbe.corpusPath() != nil),
  .serialized)
struct ConsistencyContractCorpusTests {

  @Test func consistencyAgreementRateOA300() throws {
    let corpus = try #require(SharedDecodeProbe.corpusPath())
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpus)
    let files = ProbeFormat.allCases.flatMap { byFormat[$0] ?? [] }
    try #require(!files.isEmpty, "no OA300 files resolved")

    var agree = 0
    var octaveUp = 0  // factor +2 (grid ≈ 2× bpm)
    var octaveDown = 0  // factor -2 (grid ≈ ½× bpm)
    var disagree = 0
    var notCompared = 0
    var noResult = 0  // analyze nil OR no beat grid (not counted in the rate denominator)

    for fileURL in files {
      guard let result = try? AudioAnalysisService.analyze(url: fileURL),
        let grid = result.beatGrid
      else {
        noResult += 1
        continue
      }
      switch grid.tempoAgreement {
      case .agree: agree += 1
      case .octaveEquivalent(let factor): factor > 0 ? (octaveUp += 1) : (octaveDown += 1)
      case .disagree: disagree += 1
      case .notCompared: notCompared += 1
      }
    }

    let analyzed = agree + octaveUp + octaveDown + disagree + notCompared
    try #require(analyzed > 0, "no tracks produced a BPM + beat grid")
    let usable = agree + octaveUp + octaveDown
    let rate = Double(usable) / Double(analyzed)

    print(
      """
      \n=== Story 8-5 AC8 OA300 consistency rate ===
      tracks resolved   = \(files.count)  (no BPM+grid: \(noResult))
      analyzed (denom)  = \(analyzed)
      .agree            = \(agree)
      .octaveEquivalent +2 = \(octaveUp)   -2 = \(octaveDown)
      .disagree         = \(disagree)
      .notCompared      = \(notCompared)   (must be 0 — both stages ran)
      sync-usable rate  = \(String(format: "%.1f", rate * 100))%  (gate >= 90%)
      """)

    // Both stages ran for every analyzed track → never .notCompared on this path.
    #expect(notCompared == 0, "AC8: \(notCompared) tracks were .notCompared (a stage did not run)")
    #expect(
      rate >= 0.90,
      "AC8 OA300 consistency rate \(rate * 100)% < 90% (disagree=\(disagree)/\(analyzed))")
  }
}
