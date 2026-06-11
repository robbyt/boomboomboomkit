//
//  AblationFullMatrixTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Full 256-combination ablation matrix vs OA300 corpus.
//  Story 3-3 grew the matrix from 2^6 = 64 to 2^7 = 128 by adding `.clickTrackCorrelation`;
//  Story 4-7 grew it from 2^7 = 128 to 2^8 = 256 by adding `.superFluxOnset`.
//  Wall-clock on M5 Max (82-track corpus, post benchmark-infra-ablation-parallelism):
//  ~77 s at the Makefile default ABLATION_PARALLELISM=16; ~81 s unbatched (cap=128);
//  ~130 s at cap=8; ~230 s at cap=4. Per-chunk barrier cost is small at cap≥16.
//  Requires OA300_CORPUS_PATH; init throws (load-bearing fail) if unset.
//
//  The ablation suite uses a 2-factor Acc2 (`{1, 2, 1/2}`) rather than the MIREX
//  5-factor variant used by OA300 / GiantSteps / Performance benchmarks. This is
//  intentional — ablation measures relative effect of DSP techniques, and triplet
//  factors mask technique differences in DnB-heavy corpora. Keep the local
//  `isAcc1Abl` / `isAcc2Abl` helpers below rather than importing shared matchers.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Ablation-local accuracy helpers (2-factor Acc2, not MIREX)

private func isAcc1Abl(_ detected: Double, _ expected: Double) -> Bool {
  guard expected > 0 else { return false }
  return abs(detected - expected) / expected <= 0.02
}

private func isAcc2Abl(_ detected: Double, _ expected: Double) -> Bool {
  isAcc1Abl(detected, expected)
    || isAcc1Abl(detected * 2, expected)
    || isAcc1Abl(detected / 2, expected)
}

// MARK: - Full Ablation Matrix

@Suite("Ablation — Full Matrix")
struct AblationMatrixTests {

  private let corpusPath: String
  private let groundTruth: [OA300Track]

  /// File-scope source-of-truth for the 16-combo smoke ablation lane.
  /// Consumed by `smokeAblation` (corpus runner) and `SmokeAblationInvariantTests`
  /// (CI-enforced HALT-(e) gate for Story 4-7 — verifies that `.superFluxOnset`
  /// never enters the smoke combos by accident).
  ///
  /// Story 4-7 swap: the "full" and "full-click" entries pre-Story-4-7 used
  /// `TechniqueSet.full` directly. Post-Story-4-7 `.full = Set(allCases)`
  /// auto-includes `.superFluxOnset`, so the two entries use
  /// `TechniqueSet.full.removing(.superFluxOnset)` (`= preStory47Full`) to keep
  /// the smoke lane on the pre-Story-4-7 7-technique footprint per AC #5.
  static let smokeCombos: [(String, TechniqueSet)] = {
    let preStory47Full = TechniqueSet.full.removing(.superFluxOnset)
    let preStory47FullMinusClick = preStory47Full.removing(.clickTrackCorrelation)
    let optimalPlusClick = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let optimalMinusFinePlusClick = TechniqueSet.optimal
      .removing(.fineGridRefinement)
      .inserting(.clickTrackCorrelation)
    let optimalPlusClickPlusNorm = optimalPlusClick.inserting(.subBandNormalization)
    let baselinePlusClick = TechniqueSet.baseline.inserting(.clickTrackCorrelation)
    let voteOnly = TechniqueSet(dspTechniques: [.subBandVoting, .fineGridRefinement])
    let voteFineClick = voteOnly.inserting(.clickTrackCorrelation)
    let sharpVote = TechniqueSet(
      dspTechniques: [.acfSharpening, .subBandVoting, .fineGridRefinement])
    let sharpVoteClick = sharpVote.inserting(.clickTrackCorrelation)
    let dnbPlusClick = TechniqueSet.dnbOptimized.inserting(.clickTrackCorrelation)
    return [
      ("baseline", .baseline),
      ("optimal", .optimal),
      ("optimal+click", optimalPlusClick),
      ("full(-superFlux)", preStory47Full),
      ("full(-superFlux)-click", preStory47FullMinusClick),
      ("dnbOptimized", .dnbOptimized),
      ("baseline+click", baselinePlusClick),
      ("vote+fine", voteOnly),
      ("vote+fine+click", voteFineClick),
      ("sharp+vote+fine", sharpVote),
      ("sharp+vote+fine+click", sharpVoteClick),
      ("optimal-fine+click", optimalMinusFinePlusClick),
      ("optimal+click+norm", optimalPlusClickPlusNorm),
      ("dnbOptimized+click", dnbPlusClick),
      ("just sharp", TechniqueSet(dspTechniques: [.acfSharpening])),
      ("click only", TechniqueSet(dspTechniques: [.clickTrackCorrelation])),
    ]
  }()

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else {
      throw AblationError.corpusPathNotSet
    }
    corpusPath = path

    let jsonURL =
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
      ?? Bundle.module.url(
        forResource: "Fixtures/oa300-ground-truth", withExtension: "json")
    guard let url = jsonURL else { throw AblationError.groundTruthNotFound }
    let data = try Data(contentsOf: url)
    groundTruth = try JSONDecoder().decode([OA300Track].self, from: data)
  }

  @Test("full 256-combination ablation matrix", .timeLimit(.minutes(60)))
  func fullAblationMatrix() async throws {
    let allCombos = TechniqueSet.allDSPCombinations()

    let (parallelism, source) = Self.resolvedParallelism()
    print("\n=== Full 256-Combination Ablation Matrix ===")
    print("Ablation parallelism cap: \(parallelism) (source: \(source))")
    print(
      "Configuration".padding(toLength: 40, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Corr Total  Delta")
    print(String(repeating: "-", count: 72))

    typealias ComboResult = (label: String, acc1: Int, acc2: Int, total: Int)
    let gt = groundTruth
    let path = corpusPath
    let results = await Self.batchedTaskGroup(
      items: allCombos, parallelism: parallelism
    ) { techniqueSet -> ComboResult in
      do {
        let (acc1, acc2, total) = try Self.runCorpusFromDisk(
          techniqueSet: techniqueSet, groundTruth: gt, corpusPath: path)
        return (label: techniqueSet.label, acc1: acc1, acc2: acc2, total: total)
      } catch {
        // Surface the failure: prefix the label with FAILED so the
        // post-loop assertion below catches it (AC #5 requires "all
        // combinations complete").
        return (
          label: "FAILED: \(techniqueSet.label) — \(error)", acc1: 0, acc2: 0, total: 0
        )
      }
    }

    // AC #4 (Story 3-3 / Story 4-7): all 256 combinations must complete without crashing.
    let failedCombos = results.filter { $0.label.hasPrefix("FAILED:") }
    let failedSummary = failedCombos.map(\.label).joined(separator: "; ")
    #expect(
      failedCombos.isEmpty,
      "AC #4 ablation regression: \(failedCombos.count) combo(s) crashed: \(failedSummary)"
    )

    let baselineLabel = TechniqueSet.baseline.label
    let optimalLabel = TechniqueSet.optimal.label
    var bestAcc1 = 0
    var bestLabel = ""
    var baselineAcc1 = 0
    var optimalAcc1 = 0

    for r in results {
      if r.label == baselineLabel { baselineAcc1 = r.acc1 }
      if r.label == optimalLabel { optimalAcc1 = r.acc1 }
      if r.acc1 > bestAcc1 {
        bestAcc1 = r.acc1
        bestLabel = r.label
      }
    }

    // AC #4 (Story 3-3 Decision B): extend per-combo JSON with paired click-on/off
    // deltas plus a top-level regressionGate. Each combo row carries:
    //   - label, acc1, acc2, total (existing minimal contract)
    //   - clickOnVsOffDeltaAcc1: present on click-ON combos; null on click-OFF combos.
    //     Compares against the same combo with `.clickTrackCorrelation` removed.
    //   - vsStory32BaselineDeltaAcc1: null until a Story 3-2 baseline JSON exists at the
    //     well-known path; reserved for future paired comparison without code change.
    // Top-level regressionGate captures pass/fail status of the existing optimal-≥-55
    // gate plus a list of click-OFF combos whose Acc1 we want a future story to track
    // against the prior baseline.
    if let baselineDir = ProcessInfo.processInfo.environment["AblATION_RESULTS_DIR"]
      ?? ProcessInfo.processInfo.environment["ABLATION_RESULTS_DIR"]
    {
      let url = URL(fileURLWithPath: baselineDir)
        .appendingPathComponent("3-3-ablation-results.json")
      do {
        // Map label → result for paired-twin lookup. All click-OFF combos are reachable
        // by removing ".click" suffix from a click-ON label (or, equivalently, by
        // recomputing the label of a TechniqueSet with clickTrackCorrelation removed).
        let resultsByLabel: [String: ComboResult] = Dictionary(
          uniqueKeysWithValues: results.map { ($0.label, $0) })
        let clickOffCombos = TechniqueSet.allDSPCombinations()
          .filter { !$0.contains(.clickTrackCorrelation) }
          .map(\.label)

        let rows: [[String: Any]] = TechniqueSet.allDSPCombinations().map { combo in
          let label = combo.label
          let r =
            resultsByLabel[label]
            ?? ComboResult(
              label: label, acc1: 0, acc2: 0, total: 0)
          var row: [String: Any] = [
            "label": r.label,
            "acc1": r.acc1,
            "acc2": r.acc2,
            "total": r.total,
            "vsStory32BaselineDeltaAcc1": NSNull(),
          ]
          if combo.contains(.clickTrackCorrelation) {
            let twinLabel = combo.removing(.clickTrackCorrelation).label
            if let twin = resultsByLabel[twinLabel] {
              row["clickOnVsOffDeltaAcc1"] = r.acc1 - twin.acc1
            } else {
              row["clickOnVsOffDeltaAcc1"] = NSNull()
            }
          } else {
            row["clickOnVsOffDeltaAcc1"] = NSNull()
          }
          return row
        }

        let regressionGate: [String: Any] = [
          "optimalAcc1": optimalAcc1,
          "optimalAcc1Floor": 55,
          "status": optimalAcc1 >= 55 ? "pass" : "fail",
          "clickOffCombos": clickOffCombos,
          "note":
            "Story 3-2 baseline comparison reserved (vsStory32BaselineDeltaAcc1 = null) "
            + "until a stored Story 3-2 baseline JSON is added. The current gate is "
            + "optimalAcc1 >= 55 (carried from Story 3-2). Click-on combos report "
            + "clickOnVsOffDeltaAcc1 vs their click-off twins for paired comparison.",
        ]

        let payload: [String: Any] = [
          "rows": rows,
          "regressionGate": regressionGate,
        ]

        let json = try JSONSerialization.data(
          withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: url)
        print("\nAC #4: ablation results written to \(url.path)")
      } catch {
        print("\nAC #4: failed to write ablation results JSON: \(error)")
      }
    }

    let sorted = results.sorted { $0.acc1 > $1.acc1 }
    for r in sorted {
      let delta = r.acc1 - baselineAcc1
      let deltaStr = r.label == baselineLabel ? "  --" : (delta >= 0 ? " +\(delta)" : " \(delta)")
      let acc1Pct = String(format: "%5.1f%%", Double(r.acc1) / Double(r.total) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(r.acc2) / Double(r.total) * 100)
      print(
        r.label.padding(toLength: 40, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct) \(String(format: "%3d", r.acc1))   \(String(format: "%3d", r.total)) \(deltaStr)"
      )
    }

    print("\nBest combination: \(bestLabel) (Acc1=\(bestAcc1))")
    print("Baseline: \(TechniqueSet.baseline.label) (Acc1=\(baselineAcc1))")
    print("Optimal:  \(optimalLabel) (Acc1=\(optimalAcc1))")

    // AC #5 (Story 3-2): `.optimal` Acc1 must hold ≥ 67.1% (55/82). See
    // `_bmad-output/implementation-artifacts/3-2-fine-grid-precision-fix.md`
    // (acceptance criteria #5).
    #expect(
      optimalAcc1 >= 55,
      "AC #5 .optimal Acc1 regression: expected >= 55/82 (67.1%), got \(optimalAcc1)"
    )
  }

  @Test(
    "per-track technique impact — which tracks does each technique change?",
    .timeLimit(.minutes(10)))
  func perTrackImpact() async throws {
    let namedSets: [(String, TechniqueSet)] = [
      ("sharp", TechniqueSet.baseline.inserting(.acfSharpening)),
      ("thresh", TechniqueSet.baseline.inserting(.adaptiveThreshold)),
      ("norm", TechniqueSet.baseline.inserting(.subBandNormalization)),
      ("top5", TechniqueSet.baseline.inserting(.expandedCandidates)),
      ("optimal", .optimal),
      ("dnbOptimized", .dnbOptimized),
      ("full", .full),
    ]

    let allSets = [("baseline", TechniqueSet.baseline)] + namedSets
    let gt = groundTruth
    let path = corpusPath
    let allResults = await withTaskGroup(of: (Int, [String: Double]).self) { group in
      for (index, (_, techniqueSet)) in allSets.enumerated() {
        group.addTask {
          guard
            let results = try? Self.perTrackResultsFromDisk(
              techniqueSet: techniqueSet, groundTruth: gt, corpusPath: path)
          else { return (index, [:]) }
          return (index, results)
        }
      }
      var collected = [[String: Double]](repeating: [:], count: allSets.count)
      for await (i, result) in group { collected[i] = result }
      return collected
    }

    let baselineResults = allResults[0]

    print("\n=== Per-Track Technique Impact ===")
    print("(Shows tracks where technique CHANGED the result vs baseline)\n")

    for (setIndex, (name, _)) in namedSets.enumerated() {
      let results = allResults[setIndex + 1]  // +1 to skip baseline
      var improved = 0
      var regressed = 0

      for (filename, detected) in results {
        guard let baseDetected = baselineResults[filename],
          let track = groundTruth.first(where: { $0.filename == filename })
        else { continue }

        let basCorrect = isAcc1Abl(baseDetected, track.bpm)
        let newCorrect = isAcc1Abl(detected, track.bpm)

        if !basCorrect && newCorrect {
          improved += 1
          print(
            "  [\(name)] IMPROVED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))->\(String(format: "%.1f", detected)) (expected \(track.bpm))"
          )
        } else if basCorrect && !newCorrect {
          regressed += 1
          print(
            "  [\(name)] REGRESSED: \(track.title.prefix(35)) — \(String(format: "%.1f", baseDetected))->\(String(format: "%.1f", detected)) (expected \(track.bpm))"
          )
        }
      }
      print(
        "  \(name): +\(improved) improved, -\(regressed) regressed, net=\(improved - regressed)")
      print()
    }
  }

  // MARK: - Smoke Ablation (AC #8 — fast cadence)

  /// Curated 16-combo subset for fast cadence on the doubled matrix (AC #8 / Story 3-3
  /// Task 3.1). Includes `optimal` and `optimal+click` so click-technique regressions
  /// are caught without a 30-min wait. Gated by `ABLATION_SMOKE=1` so it doesn't run
  /// during ordinary `swift test --filter BoomBoomBoomKitBenchmarkTests`.
  ///
  /// **Story 4-7 invariant: zero of the 16 combos may contain `.superFluxOnset`** (per
  /// AC #5 / HALT-(e) / DD #6). The two combos that would otherwise auto-include the
  /// new case via `TechniqueSet.full = Set(DSPTechnique.allCases)` —
  /// `("full", .full)` and `("full-click", .full.removing(.clickTrackCorrelation))` —
  /// are swapped for pre-Story-4-7-equivalent variants computed via
  /// `TechniqueSet.full.removing(.superFluxOnset)`. The wall-clock impact of the swap
  /// is zero by construction (same 7-technique footprint as pre-Story-4-7 `.full`).
  /// The CI-enforced invariant lives in `SmokeAblationInvariantTests` below.
  @Test(
    "smoke ablation — 16 curated combos including optimal and optimal+click",
    .timeLimit(.minutes(10)))
  func smokeAblation() async throws {
    guard ProcessInfo.processInfo.environment["ABLATION_SMOKE"] == "1" else {
      // Quietly noop unless explicitly invoked via `make ablation-smoke`.
      return
    }

    let curated = Self.smokeCombos
    let gt = groundTruth
    let path = corpusPath
    let (parallelism, source) = Self.resolvedParallelism()
    print("\n=== Smoke Ablation (16 combos) ===")
    print("Ablation parallelism cap: \(parallelism) (source: \(source))")
    print(
      "Configuration".padding(toLength: 28, withPad: " ", startingAt: 0)
        + "  Acc1   Acc2  Corr  Total")
    print(String(repeating: "-", count: 60))

    typealias SmokeRow = (name: String, a1: Int, a2: Int, total: Int)
    let results: [SmokeRow] = await Self.batchedTaskGroup(
      items: curated, parallelism: parallelism
    ) { entry -> SmokeRow in
      let (name, techniqueSet) = entry
      do {
        let (a1, a2, total) = try Self.runCorpusFromDisk(
          techniqueSet: techniqueSet, groundTruth: gt, corpusPath: path)
        return (name: name, a1: a1, a2: a2, total: total)
      } catch {
        return (name: "FAILED:\(name)", a1: 0, a2: 0, total: 0)
      }
    }

    for r in results {
      let acc1Pct = String(format: "%5.1f%%", Double(r.a1) / Double(max(r.total, 1)) * 100)
      let acc2Pct = String(format: "%5.1f%%", Double(r.a2) / Double(max(r.total, 1)) * 100)
      print(
        r.name.padding(toLength: 28, withPad: " ", startingAt: 0)
          + " \(acc1Pct) \(acc2Pct) \(String(format: "%3d", r.a1))   \(String(format: "%3d", r.total))"
      )
    }

    let failed = results.filter { $0.name.hasPrefix("FAILED:") }
    #expect(
      failed.isEmpty, "Smoke ablation crashed: \(failed.map(\.name).joined(separator: ", "))")

    // Story 3-3 review patch P11: empty-corpus sanity guard. If OA300_CORPUS_PATH is set
    // but no audio files match ground truth, results report zero counts and pass silently.
    let totalAnalyzed = results.map(\.total).max() ?? 0
    #expect(
      totalAnalyzed > 0,
      "Smoke ablation analyzed zero tracks; check OA300_CORPUS_PATH (\(corpusPath)).")
  }

  // MARK: - α-Sweep (Task 3.3)

  /// Sweeps `alpha ∈ {0.0, 0.3, 0.5, 0.7}` across the 4 `.optimal`-family combos to
  /// finalize the default α (Story 3-3, Task 3.3). The default α changes only when a
  /// new α produces ≥ 2 OA300 tracks better than the current default on `.optimal+click`,
  /// AND no GiantSteps regression. Single-track twitches (Δ = 1) are below the binomial
  /// standard error (~5 pp on 82 tracks). Gated by `ALPHA_SWEEP=1`.
  ///
  /// **Implementation note**: production default α=0.7 lives in `BPMAnalyzer.clickRescore`.
  /// This sweep mutates the `CLICK_RESCORE_ALPHA_OVERRIDE` env hook (DEBUG-only, gated in
  /// `BPMAnalyzer.alphaOverride()`) per-iteration with a `defer` cleanup so a thrown
  /// `runCorpusFromDisk` cannot leak the override into later analyses. The whole sweep
  /// runs under `.serialized` because env mutation is process-global and would race
  /// with concurrent click-using tests in the same suite.
  @Test("α-sweep over .optimal-family combos", .timeLimit(.minutes(10)), .serialized)
  func alphaSweep() async throws {
    guard ProcessInfo.processInfo.environment["ALPHA_SWEEP"] == "1" else { return }

    // The four combos: vary which DSP techniques accompany click rescoring, hold
    // candidate-extraction baseline at .optimal (so we can intercept candidates at the
    // same upstream step across runs).
    let combos: [(String, TechniqueSet)] = [
      ("optimal", .optimal),
      ("optimal+click", TechniqueSet.optimal.inserting(.clickTrackCorrelation)),
      (
        "optimal-fine+click",
        TechniqueSet.optimal.removing(.fineGridRefinement)
          .inserting(.clickTrackCorrelation)
      ),
      (
        "optimal+click+norm",
        TechniqueSet.optimal.inserting(.clickTrackCorrelation)
          .inserting(.subBandNormalization)
      ),
    ]
    let alphas: [Float] = [0.0, 0.3, 0.5, 0.7]

    print("\n=== α-Sweep over .optimal-family combos ===")
    print("(α-sweep drives BPMAnalyzer via the CLICK_RESCORE_ALPHA_OVERRIDE env hook;")
    print(" hook is DEBUG-only and serialized; production default α=0.7.)")

    for (label, techniqueSet) in combos {
      for alpha in alphas {
        setenv("CLICK_RESCORE_ALPHA_OVERRIDE", String(alpha), 1)
        defer { unsetenv("CLICK_RESCORE_ALPHA_OVERRIDE") }
        let (a1, a2, total) = try Self.runCorpusFromDisk(
          techniqueSet: techniqueSet, groundTruth: groundTruth, corpusPath: corpusPath)
        let acc1Pct = String(format: "%5.1f%%", Double(a1) / Double(max(total, 1)) * 100)
        let acc2Pct = String(format: "%5.1f%%", Double(a2) / Double(max(total, 1)) * 100)
        print(
          "  \(label.padding(toLength: 22, withPad: " ", startingAt: 0)) α=\(alpha)  "
            + "Acc1=\(acc1Pct) (\(a1)/\(total))  Acc2=\(acc2Pct) (\(a2)/\(total))"
        )
      }
    }
  }

  // MARK: - Click-Enabled Visibility (Task 5.3) and Click-Impact Report (Task 5.6)

  /// AC #6 visibility run: `.optimal+click` against OA300 at the default α (0.7).
  /// Reported as data, not a hard gate (the click preset isn't `.default`). Gated by
  /// `CLICK_VISIBILITY=1`.
  @Test("OA300 click-enabled visibility — .optimal+click at default α", .timeLimit(.minutes(5)))
  func clickVisibilityOA300() throws {
    guard ProcessInfo.processInfo.environment["CLICK_VISIBILITY"] == "1" else { return }

    let techniqueSet = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let (a1, a2, total) = try Self.runCorpusFromDisk(
      techniqueSet: techniqueSet, groundTruth: groundTruth, corpusPath: corpusPath)
    // Story 3-3 review patch P11: empty-corpus sanity guard.
    #expect(total > 0, "Click-visibility OA300 analyzed zero tracks; check corpus path.")
    print("\n=== OA300 .optimal+click (default α=0.7) — Visibility ===")
    print(
      "Acc1: \(String(format: "%.1f", Double(a1) / Double(total) * 100))% (\(a1)/\(total))")
    print(
      "Acc2: \(String(format: "%.1f", Double(a2) / Double(total) * 100))% (\(a2)/\(total))")
  }

  /// AC #6 visibility run for GiantSteps: `.optimal+click` against the GiantSteps
  /// corpus at the default α (0.7). Also serves as the margin-gate "no GiantSteps
  /// regression" check for Task 3.3 — vs `.optimal` (no-click) baseline. Gated by
  /// `CLICK_VISIBILITY=1` AND `GIANTSTEPS_CORPUS_PATH` set.
  @Test(
    "GiantSteps click-enabled visibility — .optimal+click at default α",
    .timeLimit(.minutes(10)))
  func clickVisibilityGiantSteps() async throws {
    guard ProcessInfo.processInfo.environment["CLICK_VISIBILITY"] == "1",
      let path = ProcessInfo.processInfo.environment["GIANTSTEPS_CORPUS_PATH"], !path.isEmpty
    else { return }

    // Load GiantSteps ground truth from the corpus directory (same pattern as
    // GiantStepsBenchmarkTests).
    let jsonPath = (path as NSString).appendingPathComponent("giantsteps-tempo-ground-truth.json")
    guard FileManager.default.fileExists(atPath: jsonPath) else {
      print("GiantSteps ground-truth JSON not found at \(jsonPath); skipping visibility run")
      return
    }
    let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
    let gt = try JSONDecoder().decode([GiantStepsTrack].self, from: data)

    let optimalPlusClick = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let optimal = TechniqueSet.optimal

    func runCorpus(_ techniqueSet: TechniqueSet) async -> (Int, Int, Int) {
      let urls: [(GiantStepsTrack, URL)] = gt.compactMap { track in
        let url = URL(fileURLWithPath: path)
          .appendingPathComponent("audio")
          .appendingPathComponent(track.filename)
        return FileManager.default.fileExists(atPath: url.path) ? (track, url) : nil
      }
      let results: [(Double, Double?)] = await withTaskGroup(of: (Int, Double, Double?).self) {
        group in
        for (i, (track, url)) in urls.enumerated() {
          group.addTask {
            do {
              let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
                from: url, maxSeconds: 120)
              let r = BPMAnalyzer.estimateBPM(
                decoded: .synthetic(samples, sampleRate: sampleRate),
                options: .init(techniqueSet: techniqueSet))
              return (i, track.bpm, r?.bpm)
            } catch {
              return (i, track.bpm, nil)
            }
          }
        }
        var collected: [(Double, Double?)] = Array(
          repeating: (0, nil), count: urls.count)
        for await (i, expected, got) in group { collected[i] = (expected, got) }
        return collected
      }
      var a1 = 0
      var a2 = 0
      for (expected, got) in results {
        guard let got = got else { continue }
        if isAcc1Abl(got, expected) {
          a1 += 1
          a2 += 1
        } else if isAcc2Abl(got, expected) {
          a2 += 1
        }
      }
      return (a1, a2, results.count)
    }

    let (a1Off, a2Off, total) = await runCorpus(optimal)
    let (a1On, a2On, _) = await runCorpus(optimalPlusClick)
    print("\n=== GiantSteps .optimal vs .optimal+click (default α=0.7) ===")
    print(
      ".optimal      Acc1=\(a1Off)/\(total) (\(String(format: "%.1f", Double(a1Off)/Double(total)*100))%)  "
        + "Acc2=\(a2Off)/\(total) (\(String(format: "%.1f", Double(a2Off)/Double(total)*100))%)")
    print(
      ".optimal+click Acc1=\(a1On)/\(total) (\(String(format: "%.1f", Double(a1On)/Double(total)*100))%)  "
        + "Acc2=\(a2On)/\(total) (\(String(format: "%.1f", Double(a2On)/Double(total)*100))%)")
    print("Δ Acc1: \(a1On - a1Off), Δ Acc2: \(a2On - a2Off)")
  }

  /// Task 5.6 — per-track click-impact report. Compares OA300 results with click-on
  /// vs click-off, counting how many tracks had ranking / step-10-winner / final-BPM
  /// changes. Emits to `_bmad-output/implementation-artifacts/3-3-click-impact-report.json`.
  /// Gated by `CLICK_IMPACT=1`. DD#12 caveat: step 10 / 10b are largely score-blind;
  /// this report measures the technique's actual reach on the corpus.
  @Test("per-track click-impact report on OA300", .timeLimit(.minutes(10)))
  func clickImpactReport() async throws {
    guard ProcessInfo.processInfo.environment["CLICK_IMPACT"] == "1" else { return }

    let withoutClick = TechniqueSet.optimal
    let withClick = TechniqueSet.optimal.inserting(.clickTrackCorrelation)
    let gt = groundTruth
    let path = corpusPath

    struct Pair: Sendable {
      let filename: String
      let preTopBPMNoClick: Double?
      let preTopBPMWithClick: Double?
      let disambigBPMNoClick: Double?
      let disambigBPMWithClick: Double?
      let finalBPMNoClick: Double?
      let finalBPMWithClick: Double?
    }

    let urls: [(String, URL)] = gt.compactMap { track in
      let url = Self.trackURL(track, corpusPath: path)
      return FileManager.default.fileExists(atPath: url.path) ? (track.filename, url) : nil
    }

    let pairs = await withTaskGroup(of: Pair?.self) { group in
      for (filename, url) in urls {
        group.addTask {
          do {
            let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
              from: url, maxSeconds: 120)
            let off = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(techniqueSet: withoutClick, enableTrace: true))
            let on = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(techniqueSet: withClick, enableTrace: true))
            let preOff = off?.candidates.first?.bpm
            let preOn = on?.candidates.first?.bpm
            let disOff = off?.trace?.disambiguationResult.bpm
            let disOn = on?.trace?.disambiguationResult.bpm
            return Pair(
              filename: filename,
              preTopBPMNoClick: preOff, preTopBPMWithClick: preOn,
              disambigBPMNoClick: disOff, disambigBPMWithClick: disOn,
              finalBPMNoClick: off?.bpm, finalBPMWithClick: on?.bpm)
          } catch {
            return nil
          }
        }
      }
      var collected: [Pair] = []
      for await p in group { if let p = p { collected.append(p) } }
      return collected
    }

    var changedRanking = 0
    var changedStep10Winner = 0
    var changedFinalBPM = 0
    for p in pairs {
      if p.preTopBPMNoClick != p.preTopBPMWithClick { changedRanking += 1 }
      if p.disambigBPMNoClick != p.disambigBPMWithClick { changedStep10Winner += 1 }
      if p.finalBPMNoClick != p.finalBPMWithClick { changedFinalBPM += 1 }
    }

    // Story 3-3 review patch P11: empty-corpus sanity guard.
    #expect(pairs.count > 0, "Click-impact report analyzed zero tracks; check OA300 corpus path.")

    print("\n=== Per-Track Click-Impact Report (OA300) ===")
    print("Total tracks (ground truth): \(gt.count)")
    print("Tracks analyzed:             \(pairs.count)")
    print("Tracks failed/missing:       \(gt.count - pairs.count)")
    print("changedRanking:              \(changedRanking)")
    print("changedStep10Winner:         \(changedStep10Winner)")
    print("changedFinalBPM:             \(changedFinalBPM)")

    // Story 3-3 review patch P5: emit `total: gt.count` (the spec contract) plus
    // `analyzed` and `failed` so undercount is visible. Spec required `{..., total: 82}`;
    // the previous `pairs.count` could silently fall below 82 when files were missing
    // or analysis failed.
    let payload: [String: Any] = [
      "changedRanking": changedRanking,
      "changedStep10Winner": changedStep10Winner,
      "changedFinalBPM": changedFinalBPM,
      "total": gt.count,
      "analyzed": pairs.count,
      "failed": gt.count - pairs.count,
    ]
    if let dir = ProcessInfo.processInfo.environment["CLICK_IMPACT_OUT_DIR"] {
      let url = URL(fileURLWithPath: dir)
        .appendingPathComponent("3-3-click-impact-report.json")
      let data = try JSONSerialization.data(
        withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
      try data.write(to: url)
      print("Click-impact report written to \(url.path)")
    }
  }

  /// Story 3-4 Task 5.5 — per-track duration-impact report. Compares OA300 results with
  /// duration hint on vs off at the default `.optimal` technique set (click inactive),
  /// counting how many tracks had ranking / step-10-winner / final-BPM changes.
  /// Emits to `_bmad-output/implementation-artifacts/3-4-duration-impact-report.json`.
  /// Gated by `DURATION_IMPACT=1`. DD#12 caveat applies — step 10 / 10b are largely
  /// score-blind, so the technique's actual reach may be small. This report measures it.
  @Test("per-track duration-impact report on OA300", .timeLimit(.minutes(10)))
  func durationImpactReport() async throws {
    guard ProcessInfo.processInfo.environment["DURATION_IMPACT"] == "1" else { return }

    // Default technique set: .optimal (sharp+vote+fine, no click). Per Task 5.5 spec
    // — click must be inactive so changedRanking via rawCandidates[0] vs result.candidates[0]
    // measures only the duration boost.
    let techniqueSet = TechniqueSet.optimal
    let gt = groundTruth
    let path = corpusPath

    struct Pair: Sendable {
      let filename: String
      let preTopBPMHintOff: Double?
      let preTopBPMHintOn: Double?
      let disambigBPMHintOff: Double?
      let disambigBPMHintOn: Double?
      let finalBPMHintOff: Double?
      let finalBPMHintOn: Double?
      // For single-run changedRanking proxy with hint on:
      // rawCandidates (pre-9.5/9.7) vs result.candidates (post-everything).
      let rawTopBPMHintOn: Double?
      let candidatesTopBPMHintOn: Double?
    }

    let urls: [(String, URL)] = gt.compactMap { track in
      let url = Self.trackURL(track, corpusPath: path)
      return FileManager.default.fileExists(atPath: url.path) ? (track.filename, url) : nil
    }

    let pairs = await withTaskGroup(of: Pair?.self) { group in
      for (filename, url) in urls {
        group.addTask {
          do {
            let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
              from: url, maxSeconds: 120)
            let duration = (try? PCMBufferReader.fileDuration(url: url)).flatMap {
              $0 > 0 ? $0 : nil
            }

            let off = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(techniqueSet: techniqueSet, enableTrace: true))
            let on = BPMAnalyzer.estimateBPM(
              decoded: .synthetic(samples, sampleRate: sampleRate),
              options: .init(
                techniqueSet: techniqueSet,
                enableTrace: true,
                fileDurationSeconds: duration))

            return Pair(
              filename: filename,
              preTopBPMHintOff: off?.candidates.first?.bpm,
              preTopBPMHintOn: on?.candidates.first?.bpm,
              disambigBPMHintOff: off?.trace?.disambiguationResult.bpm,
              disambigBPMHintOn: on?.trace?.disambiguationResult.bpm,
              finalBPMHintOff: off?.bpm,
              finalBPMHintOn: on?.bpm,
              rawTopBPMHintOn: on?.trace?.rawCandidates.first?.bpm,
              candidatesTopBPMHintOn: on?.candidates.first?.bpm)
          } catch {
            return nil
          }
        }
      }
      var collected: [Pair] = []
      for await p in group { if let p = p { collected.append(p) } }
      return collected
    }

    // Tolerance-aware BPM "differs" predicate (code-review Patch #4, Story 3-4).
    // Exact `!=` on Double can inflate change counts when post-pipeline BPMs differ by
    // representation noise rather than behavior. Mirror the project's 2% accuracy
    // tolerance from BoomBoomBoomKitTestSupport/AccuracyMatchers.swift.
    func bpmDiffers(_ a: Double?, _ b: Double?) -> Bool {
      switch (a, b) {
      case (nil, nil): return false
      case (nil, _), (_, nil): return true
      case (let lhs?, let rhs?):
        let denom = max(abs(rhs), 1e-9)
        return abs(lhs - rhs) / denom > 0.02
      }
    }

    var changedRanking = 0
    var changedDisambiguationWinner = 0
    var changedFinalBPM = 0
    for p in pairs {
      if bpmDiffers(p.rawTopBPMHintOn, p.candidatesTopBPMHintOn) { changedRanking += 1 }
      if bpmDiffers(p.disambigBPMHintOff, p.disambigBPMHintOn) { changedDisambiguationWinner += 1 }
      if bpmDiffers(p.finalBPMHintOff, p.finalBPMHintOn) { changedFinalBPM += 1 }
    }

    #expect(
      pairs.count > 0, "Duration-impact report analyzed zero tracks; check OA300 corpus path.")

    print("\n=== Per-Track Duration-Impact Report (OA300, .optimal, click inactive) ===")
    print("Total tracks (ground truth):   \(gt.count)")
    print("Tracks analyzed:               \(pairs.count)")
    print("Tracks failed/missing:         \(gt.count - pairs.count)")
    print("changedRanking:                \(changedRanking)")
    print("changedDisambiguationWinner:   \(changedDisambiguationWinner)")
    print("changedFinalBPM:               \(changedFinalBPM)")

    let payload: [String: Any] = [
      "changedRanking": changedRanking,
      "changedDisambiguationWinner": changedDisambiguationWinner,
      "changedFinalBPM": changedFinalBPM,
      "total": gt.count,
      "analyzed": pairs.count,
      "failed": gt.count - pairs.count,
      "intensity": "default",
      "techniqueSet": "optimal",
    ]
    if let dir = ProcessInfo.processInfo.environment["DURATION_IMPACT_OUT_DIR"] {
      let url = URL(fileURLWithPath: dir)
        .appendingPathComponent("3-4-duration-impact-report.json")
      let data = try JSONSerialization.data(
        withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
      try data.write(to: url)
      print("Duration-impact report written to \(url.path)")
    }
  }

  // MARK: - Bounded-Parallelism Helper (benchmark-infra-ablation-parallelism)

  /// Walks `items` in chunks of `parallelism`, opening one `withTaskGroup` per chunk
  /// and awaiting all in-flight tasks before starting the next chunk. Returns results
  /// in input order. Used by `fullAblationMatrix` and `smokeAblation` to bound the
  /// in-flight PCM-decoder count and prevent peak memory pressure on small machines.
  ///
  /// `internal` (not `private`) so `BatchedTaskGroupTests` in the same target can
  /// exercise the cap directly. Production callers (`fullAblationMatrix`,
  /// `smokeAblation`) reach this only through `resolvedParallelism()`, which clamps
  /// to `[1, 128]`.
  static func batchedTaskGroup<Work: Sendable, Result: Sendable>(
    items: [Work],
    parallelism: Int,
    body: @escaping @Sendable (Work) async -> Result
  ) async -> [Result] {
    guard !items.isEmpty else { return [] }
    precondition(parallelism > 0, "parallelism must be positive")
    var collected = [Result?](repeating: nil, count: items.count)
    for chunkStart in stride(from: 0, to: items.count, by: parallelism) {
      let chunkEnd = min(chunkStart + parallelism, items.count)
      await withTaskGroup(of: (Int, Result).self) { group in
        for absoluteIndex in chunkStart..<chunkEnd {
          let item = items[absoluteIndex]
          group.addTask {
            let r = await body(item)
            return (absoluteIndex, r)
          }
        }
        for await (i, r) in group {
          collected[i] = r
        }
      }
    }
    // Force-unwrap is safe by construction: chunks tile [0, items.count) exactly,
    // every absolute index is written by exactly one task.
    return collected.map { $0! }
  }

  /// Returns the per-chunk in-flight cap and a string describing its source.
  /// Default is `min(activeProcessorCount, 32)`. Overridable via the
  /// `ABLATION_PARALLELISM` env var (positive integer in `[1, 128]`).
  /// Malformed or out-of-range values fall back to the default and log one
  /// line naming the offending value.
  private static func resolvedParallelism() -> (cap: Int, source: String) {
    let defaultCap = min(ProcessInfo.processInfo.activeProcessorCount, 32)
    guard let raw = ProcessInfo.processInfo.environment["ABLATION_PARALLELISM"] else {
      return (defaultCap, "default")
    }
    if let parsed = Int(raw), (1...128).contains(parsed) {
      return (parsed, "env=ABLATION_PARALLELISM")
    }
    print(
      "ABLATION_PARALLELISM=\(raw) is malformed (expected integer in [1, 128]); "
        + "using default \(defaultCap).")
    return (defaultCap, "default")
  }

  // MARK: - Helpers

  private func trackURL(_ track: OA300Track) -> URL {
    Self.trackURL(track, corpusPath: corpusPath)
  }

  private static func trackURL(_ track: OA300Track, corpusPath: String) -> URL {
    if let subdir = track.subdir {
      return URL(fileURLWithPath: corpusPath)
        .appendingPathComponent(subdir)
        .appendingPathComponent(track.filename)
    }
    return URL(fileURLWithPath: corpusPath).appendingPathComponent(track.filename)
  }

  private static func runCorpusFromDisk(
    techniqueSet: TechniqueSet,
    groundTruth: [OA300Track],
    corpusPath: String
  ) throws -> (acc1: Int, acc2: Int, total: Int) {
    var acc1 = 0
    var acc2 = 0
    var total = 0

    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      guard
        let result = BPMAnalyzer.estimateBPM(
          decoded: .synthetic(samples, sampleRate: sampleRate),
          options: .init(techniqueSet: techniqueSet))
      else {
        total += 1
        continue
      }

      total += 1
      if isAcc1Abl(result.bpm, track.bpm) {
        acc1 += 1
        acc2 += 1
      } else if isAcc2Abl(result.bpm, track.bpm) {
        acc2 += 1
      }
    }

    return (acc1, acc2, total)
  }

  private static func perTrackResultsFromDisk(
    techniqueSet: TechniqueSet,
    groundTruth: [OA300Track],
    corpusPath: String
  ) throws -> [String: Double] {
    var results: [String: Double] = [:]
    for track in groundTruth {
      let url = trackURL(track, corpusPath: corpusPath)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }

      let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 120)
      if let result = BPMAnalyzer.estimateBPM(
        decoded: .synthetic(samples, sampleRate: sampleRate),
        options: .init(techniqueSet: techniqueSet))
      {
        results[track.filename] = result.bpm
      }
    }
    return results
  }
}

private enum AblationError: Error {
  case groundTruthNotFound
  case corpusPathNotSet
}

// MARK: - Story 4-7 AC #1 invariant #11 — CI-enforced smoke-lane gate

/// Parameterized invariant test that converts Story 4-7 HALT-(e) from a
/// manual code-review checkpoint into a CI-enforced gate. The test runs
/// against every entry in `AblationMatrixTests.smokeCombos` and asserts
/// none of them contain `.superFluxOnset`. The suite intentionally has
/// NO `init() throws` corpus-path dependency so the invariant fires on
/// every benchmark-target invocation, not only when OA300_CORPUS_PATH is
/// set.
///
/// Parameterized form (per `axiom-testing/skills/swift-testing.md:220-228`):
/// each combo is its own test case, so the failure message names the
/// offending combo and a developer can re-run a single failing argument
/// in isolation.
@Suite("Story 4-7 — Smoke ablation invariants (AC #1 invariant #11 / HALT-(e))")
struct SmokeAblationInvariantTests {

  @Test(
    "smoke combo does NOT include .superFluxOnset",
    arguments: AblationMatrixTests.smokeCombos.map(\.1))
  func smokeComboDoesNotIncludeSuperFlux(_ combo: TechniqueSet) {
    #expect(
      !combo.contains(.superFluxOnset),
      """
      Smoke combo \(combo.label) includes .superFluxOnset — Story 4-7 HALT-(e).
      The smoke lane MUST stay on the pre-Story-4-7 7-technique footprint per
      AC #5 / DD #6. If a smoke combo legitimately needs SuperFlux, propose a
      follow-up story per DD #6's "Smoke addition path (future story authorization)".
      """)
  }

  /// Defensive cross-check that AC #1 invariant #11 itself stays at 16 combos.
  /// If the smoke lane shrinks/grows by accident, this fires before
  /// `smokeComboDoesNotIncludeSuperFlux` would surface combo-level drift.
  @Test("smoke ablation lane is exactly 16 combos")
  func smokeLaneSize() {
    #expect(AblationMatrixTests.smokeCombos.count == 16)
  }
}
