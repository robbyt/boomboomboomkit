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
//  Requires OA300_CORPUS_PATH (throwing init — GH-167 item 4 / #165). The suite
//  formerly used a silent `.enabled(if:)` skip, so `make consistency-rate-oa300`
//  — an accuracy-bearing AC8 gate — exited GREEN with zero measurement when the
//  corpus env var was unset. It now fails loudly, matching the five throwing-init
//  precedents in this target (OA300, GiantSteps, DAWOracle, AblationFullMatrix,
//  PerformanceBenchmark).
//
//    OA300_CORPUS_PATH=... OA300_CONSISTENCY=1 swift test \
//      --filter BoomBoomBoomKitBenchmarkTests.ConsistencyContractCorpusTests
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

private enum ConsistencyContractError: Error {
  case corpusPathNotSet
}

@Suite("Consistency Contract — OA300 rate", .serialized)
struct ConsistencyContractCorpusTests {

  private let corpusPath: String

  init() throws {
    guard let path = SharedDecodeProbe.corpusPath() else {
      throw ConsistencyContractError.corpusPathNotSet
    }
    corpusPath = path
  }

  /// Files that resolve on disk but do NOT produce a BPM + beat grid, keyed by
  /// last-path-component. GH-167 item 4 / #163: the >= 90% gate is computed over
  /// tracks that analyzed, so a regression that nils out half the corpus would
  /// pass if the survivors agree. An exact allowlist (not a `<= N` ceiling) is
  /// used deliberately — a ceiling permits substitution, where one known failure
  /// recovers while a different track regresses and the gate stays green.
  ///
  /// Baseline calibration 2026-07-24, OA300 at OA300_CORPUS_PATH: 81 files
  /// resolved (see the 81-vs-82 note in `consistencyAgreementRateOA300`), all 81
  /// produced a BPM + grid, so this set is EMPTY. If a track legitimately becomes
  /// unanalyzable, add its filename here with a comment naming the cause, so the
  /// exclusion is reviewable rather than silently absorbed into the denominator.
  private static let knownNoResultFiles: Set<String> = []

  @Test func consistencyAgreementRateOA300() throws {
    let byFormat = try SharedDecodeProbe.filesByFormat(corpusPath: corpusPath)
    let files = ProbeFormat.allCases.flatMap { byFormat[$0] ?? [] }
    try #require(!files.isEmpty, "no OA300 files resolved")

    var agree = 0
    var octaveUp = 0  // factor +2 (grid ≈ 2× bpm)
    var octaveDown = 0  // factor -2 (grid ≈ ½× bpm)
    var disagree = 0
    var notCompared = 0
    var noResultFiles: [String] = []  // resolved-on-disk but no BPM + grid

    for fileURL in files {
      guard let result = try? AudioAnalysisService.analyze(url: fileURL),
        let grid = result.beatGrid
      else {
        noResultFiles.append(fileURL.lastPathComponent)
        continue
      }
      switch grid.tempoAgreement {
      case .agree: agree += 1
      case .octaveEquivalent(let factor): factor > 0 ? (octaveUp += 1) : (octaveDown += 1)
      case .disagree: disagree += 1
      case .notCompared: notCompared += 1
      }
    }

    let noResult = noResultFiles.count
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

    // GH-167 item 4 / #163: bound the denominator. The set of files that
    // resolved-on-disk but did not analyze must exactly equal the calibrated
    // allowlist — no silent shrink, no substitution. Surface the diff both ways
    // so a mismatch names the offending file(s).
    let observed = Set(noResultFiles)
    let unexpected = observed.subtracting(Self.knownNoResultFiles).sorted()
    let recovered = Self.knownNoResultFiles.subtracting(observed).sorted()
    #expect(
      observed == Self.knownNoResultFiles,
      "#163: no-result set drifted. Newly failing: \(unexpected). Recovered (remove from allowlist): \(recovered)."
    )

    // GH-167 item 4 / #163: the corpus resolves to 81 files, not 82.
    // `SharedDecodeProbe.filesByFormat` groups by `ProbeFormat`, which has no
    // `.m4a` case (mp3/flac/wav/aiff only), so the corpus's single .m4a track
    // ("03 TVR.m4a") is silently dropped from the input. Pinned at 81 here with
    // a re-open trigger in deferred-work; not fixed in this PR because
    // `ProbeFormat` is the grouping key for the SharedDecodeImpactTests
    // wall-clock gates, which this PR does not touch.
    #expect(
      files.count == 81,
      "#163: expected 81 resolved OA300 files (82 corpus tracks minus the m4a ProbeFormat gap); got \(files.count)"
    )
    #expect(
      analyzed + noResult == files.count,
      "#163: analyzed (\(analyzed)) + noResult (\(noResult)) must equal resolved files (\(files.count))"
    )

    // Both stages ran for every analyzed track → never .notCompared on this path.
    #expect(notCompared == 0, "AC8: \(notCompared) tracks were .notCompared (a stage did not run)")
    #expect(
      rate >= 0.90,
      "AC8 OA300 consistency rate \(rate * 100)% < 90% (disagree=\(disagree)/\(analyzed))")
  }
}
