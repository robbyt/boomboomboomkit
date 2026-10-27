//
//  RhythmicRegionImpactTests.swift
//  BoomBoomBoomKit
//
//  Paired corpus report for rhythmic and uniform region placement.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

private struct RegionImpactTrack {
  let id: String
  let filename: String
  let url: URL
  let primaryBPM: Double
  let alternateBPM: Double?
  let dawBPM: Double?
}

private struct RegionImpactArm {
  let result: AudioAnalysisResult?
  let elapsedSeconds: Double
  let error: String?
}

@Suite(
  "Rhythmic region impact",
  .enabled(if: ProcessInfo.processInfo.environment["RHYTHMIC_REGION_IMPACT"] == "1")
)
struct RhythmicRegionImpactTests {
  private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

  @Test("paired OA300 then GiantSteps Release report", .timeLimit(.minutes(120)))
  func pairedReport() throws {
    let env = ProcessInfo.processInfo.environment
    let oaPath = try #require(env["OA300_CORPUS_PATH"])
    let giantPath = try #require(env["GIANTSTEPS_CORPUS_PATH"])
    let oaAll = try oaTracks(path: oaPath)
    let giantAll = try giantTracks(path: giantPath)
    try #require(oaAll.count == 82, "OA300 audio coverage changed")
    try #require(giantAll.count == 661, "GiantSteps audio coverage changed")
    let limit = Int(env["RHYTHMIC_REGION_LIMIT"] ?? "") ?? 0
    let oa = limit > 0 ? Array(oaAll.prefix(limit)) : oaAll
    let giant = limit > 0 ? Array(giantAll.prefix(limit)) : giantAll
    let fullCorpus = limit <= 0

    // Freeze all arm options and process OA300 before opening GiantSteps audio.
    let oaNormal = run(
      corpus: oa, isolated: false, label: "OA300 normal", measureProductionTiming: true)
    let oaIsolated = run(corpus: oa, isolated: true, label: "OA300 isolated")
    let giantNormal = run(corpus: giant, isolated: false, label: "GiantSteps normal")
    let giantIsolated = run(corpus: giant, isolated: true, label: "GiantSteps isolated")
    let promotion = promotionDecision(oa: oaNormal, giant: giantNormal, fullCorpus: fullCorpus)
    let report: [String: Any] = [
      "configuration": [
        "maxSeconds": 120, "intensity": 7,
        "A": "shipped DSP defaults with tracing",
        "B": "old [30,60,90] windows with windowVoting/simpleMajority",
        "C": "rhythm-scored disjoint 30s regions with windowVoting/simpleMajority",
        "D": "uniform disjoint 30s regions with windowVoting/simpleMajority",
        "normal": "default metadata and duration hint",
        "dspIsolated": "metadata disabled and duration hint false",
        "timing":
          "paired Release wall clock including URL decode; traced A/B/C/D and no-trace OA300 A/C",
        "fullCorpus": fullCorpus,
      ],
      "oa300": ["normal": oaNormal, "dspIsolated": oaIsolated],
      "giantsteps": ["normal": giantNormal, "dspIsolated": giantIsolated],
      "promotion": promotion,
    ]
    let filename =
      fullCorpus
      ? "13-rhythmic-region-impact-report.json"
      : "13-rhythmic-region-impact-smoke.json"
    let output =
      env["RHYTHMIC_REGION_OUTPUT_PATH"].map { URL(fileURLWithPath: $0) }
      ?? root.appendingPathComponent("_bmad-output/implementation-artifacts/\(filename)")
    let data = try JSONSerialization.data(
      withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: output, options: .atomic)
    print("Rhythmic region impact report: \(output.path)")
    print("Promotion numeric gate: \(promotion)")
  }

  private func oaTracks(path: String) throws -> [RegionImpactTrack] {
    let fixture = try #require(
      Bundle.module.url(forResource: "oa300-ground-truth", withExtension: "json")
        ?? Bundle.module.url(forResource: "Fixtures/oa300-ground-truth", withExtension: "json"))
    let rows = try OA300Track.loadCorpus(from: Data(contentsOf: fixture))
    let base = URL(fileURLWithPath: path)
    let oracleURL = base.appendingPathComponent("daw-oracle.json")
    let oracle: [DAWOracleTrack]
    if FileManager.default.fileExists(atPath: oracleURL.path) {
      oracle = try DAWOracleTrack.loadCorpus(from: Data(contentsOf: oracleURL))
    } else {
      oracle = []
    }
    let dawByFile = Dictionary(
      oracle.map { ($0.filename, $0.dawBpm) }, uniquingKeysWith: { a, _ in a })
    return rows.compactMap { track in
      let directory = track.subdir.map { base.appendingPathComponent($0) } ?? base
      let url = directory.appendingPathComponent(track.filename)
      guard FileManager.default.fileExists(atPath: url.path) else { return nil }
      return RegionImpactTrack(
        id: track.title, filename: track.filename, url: url,
        primaryBPM: track.bpm, alternateBPM: nil, dawBPM: dawByFile[track.filename])
    }.sorted { $0.filename < $1.filename }
  }

  private func giantTracks(path: String) throws -> [RegionImpactTrack] {
    let base = URL(fileURLWithPath: path)
    let truth = base.appendingPathComponent("giantsteps-tempo-ground-truth.json")
    let rows = try GiantStepsTrack.loadCorpus(from: Data(contentsOf: truth))
    return rows.compactMap { track in
      let url = base.appendingPathComponent("audio").appendingPathComponent(track.filename)
      guard FileManager.default.fileExists(atPath: url.path) else { return nil }
      return RegionImpactTrack(
        id: track.track_id, filename: track.filename, url: url,
        primaryBPM: track.bpm, alternateBPM: track.tempo2, dawBPM: nil)
    }.sorted { $0.filename < $1.filename }
  }

  private func options(arm: Int, isolated: Bool, enableTrace: Bool = true)
    -> AudioAnalysisService.Options
  {
    var options = AudioAnalysisService.Options()
    options.enableTrace = enableTrace
    if arm >= 1 {
      options.mergeStrategy = .windowVoting
      options.votingPolicy = .simpleMajority
    }
    if arm >= 2 { options.useRhythmicRegions = true }
    if arm == 3 { options.useUniformRegionControl = true }
    if isolated {
      options.metadataPolicy = .disabled
      options.durationHint = false
    }
    return options
  }

  private func measure(
    _ track: RegionImpactTrack, arm: Int, isolated: Bool, enableTrace: Bool = true
  ) -> RegionImpactArm {
    let started = ProcessInfo.processInfo.systemUptime
    do {
      let result = try AudioAnalysisService.analyzeBPM(
        url: track.url, options: options(arm: arm, isolated: isolated, enableTrace: enableTrace))
      return RegionImpactArm(
        result: result, elapsedSeconds: ProcessInfo.processInfo.systemUptime - started,
        error: nil)
    } catch {
      return RegionImpactArm(
        result: nil, elapsedSeconds: ProcessInfo.processInfo.systemUptime - started,
        error: String(describing: error))
    }
  }

  private func decisionChanged(_ left: Double?, _ right: Double?) -> Bool {
    guard let left, let right else { return (left == nil) != (right == nil) }
    guard min(left, right) > 0 else { return left != right }
    // Match BPMSelectionPolicy's two-percent comparison against the smaller BPM.
    return abs(left - right) > 0.02 * min(left, right)
  }

  private func floorMatch(_ bpm: Double?, track: RegionImpactTrack, acc2: Bool) -> Bool {
    guard let bpm else { return false }
    let truths = [track.primaryBPM, track.alternateBPM].compactMap { $0 }
    return truths.contains {
      acc2
        ? isAcc2Match(bpm, $0, tolerance: 0.02)
        : isAcc1Match(bpm, $0, tolerance: 0.02)
    }
  }

  private func run(
    corpus: [RegionImpactTrack], isolated: Bool, label: String,
    measureProductionTiming: Bool = false
  ) -> [String: Any] {
    var rows: [[String: Any]] = []
    var counts = [
      "A": ["acc1": 0, "acc2": 0, "strictAcc1": 0, "strictAcc2": 0, "nil": 0],
      "B": ["acc1": 0, "acc2": 0, "strictAcc1": 0, "strictAcc2": 0, "nil": 0],
      "C": ["acc1": 0, "acc2": 0, "strictAcc1": 0, "strictAcc2": 0, "nil": 0],
      "D": ["acc1": 0, "acc2": 0, "strictAcc1": 0, "strictAcc2": 0, "nil": 0],
    ]
    var runtime = ["A": 0.0, "B": 0.0, "C": 0.0, "D": 0.0]
    var productionRuntime = ["A": 0.0, "C": 0.0]
    var productionTimingErrors = 0
    var flipsAB = 0
    var flipsBC = 0
    var flipsCD = 0
    var decisionsAB = 0
    var decisionsBC = 0
    var decisionsCD = 0
    var gainedAcc1IDs: [String] = []
    var lostAcc1IDs: [String] = []
    var gainedAcc2IDs: [String] = []
    var lostAcc2IDs: [String] = []
    var suggestiveIntroLocks = 0
    for (index, track) in corpus.enumerated() {
      if index.isMultiple(of: 10) {
        let message = "\(label): \(index)/\(corpus.count) tracks\n"
        FileHandle.standardError.write(Data(message.utf8))
      }
      var arms = [RegionImpactArm?](repeating: nil, count: 4)
      for offset in 0..<4 {
        let arm = (index + offset) % 4
        arms[arm] = measure(track, arm: arm, isolated: isolated)
      }
      var productionTimes: [String: Double] = [:]
      if measureProductionTiming {
        // Alternate order per track to avoid systematically favoring a warm cache.
        for arm in index.isMultiple(of: 2) ? [0, 2] : [2, 0] {
          let measured = measure(track, arm: arm, isolated: isolated, enableTrace: false)
          let armLabel = arm == 0 ? "A" : "C"
          productionTimes[armLabel] = measured.elapsedSeconds
          productionRuntime[armLabel, default: 0] += measured.elapsedSeconds
          if measured.error != nil || measured.result == nil { productionTimingErrors += 1 }
        }
      }
      let labels = ["A", "B", "C", "D"]
      var row: [String: Any] = [
        "id": track.id, "filename": track.filename,
        "primaryBPM": track.primaryBPM,
        "alternateBPM": track.alternateBPM as Any? ?? NSNull(),
        "dawBPM": track.dawBPM as Any? ?? NSNull(),
        "productionSeconds": productionTimes,
      ]
      for (arm, label) in labels.enumerated() {
        let measured = arms[arm]!
        runtime[label, default: 0] += measured.elapsedSeconds
        let bpm = measured.result?.bpm
        let strictAcc1 = bpm.map { isAcc1Match($0, track.primaryBPM, tolerance: 0.02) } ?? false
        let strictAcc2 = bpm.map { isAcc2Match($0, track.primaryBPM, tolerance: 0.02) } ?? false
        let altAcc1 =
          bpm.flatMap { value in
            track.alternateBPM.map { isAcc1Match(value, $0, tolerance: 0.02) }
          } ?? false
        let altAcc2 =
          bpm.flatMap { value in
            track.alternateBPM.map { isAcc2Match(value, $0, tolerance: 0.02) }
          } ?? false
        if bpm == nil { counts[label]?["nil", default: 0] += 1 }
        if strictAcc1 { counts[label]?["strictAcc1", default: 0] += 1 }
        if strictAcc2 { counts[label]?["strictAcc2", default: 0] += 1 }
        if strictAcc1 || altAcc1 { counts[label]?["acc1", default: 0] += 1 }
        if strictAcc2 || altAcc2 { counts[label]?["acc2", default: 0] += 1 }
        let matchedAcc1Annotation: String? =
          strictAcc1 ? "primary" : (altAcc1 ? "alternate" : nil)
        let matchedAcc2Annotation: String? =
          strictAcc1
          ? "primary"
          : altAcc1
            ? "alternate"
            : strictAcc2
              ? "primary"
              : altAcc2 ? "alternate" : nil
        let primaryCategory =
          bpm.map {
            classifyTempoError($0, track.primaryBPM, tolerance: 0.02).rawValue
          } ?? "nil"
        let matchedTruth =
          matchedAcc2Annotation == "alternate"
          ? track.alternateBPM : track.primaryBPM
        let floorCategory =
          bpm.map {
            classifyTempoError($0, matchedTruth ?? track.primaryBPM, tolerance: 0.02).rawValue
          } ?? "nil"
        row[label] = [
          "bpm": bpm as Any? ?? NSNull(),
          "confidence": measured.result?.confidence as Any? ?? NSNull(),
          "seconds": measured.elapsedSeconds,
          "error": measured.error as Any? ?? NSNull(),
          "strictAcc1": strictAcc1, "strictAcc2": strictAcc2,
          "floorAcc1": strictAcc1 || altAcc1,
          "floorAcc2": strictAcc2 || altAcc2,
          "matchedAcc1Annotation": matchedAcc1Annotation as Any? ?? NSNull(),
          "matchedAcc2Annotation": matchedAcc2Annotation as Any? ?? NSNull(),
          "strictErrorClass": primaryCategory,
          "errorClass": floorCategory,
          "analysisStartSample": measured.result?.trace?.energyTransitionOffset as Any? ?? NSNull(),
        ]
      }
      let a = arms[0]!.result?.bpm
      let b = arms[1]!.result?.bpm
      let c = arms[2]!.result?.bpm
      let d = arms[3]!.result?.bpm
      let abFlip = a != b
      let bcFlip = b != c
      let cdFlip = c != d
      let abDecision = decisionChanged(a, b)
      let bcDecision = decisionChanged(b, c)
      let cdDecision = decisionChanged(c, d)
      if abFlip { flipsAB += 1 }
      if bcFlip { flipsBC += 1 }
      if cdFlip { flipsCD += 1 }
      if abDecision { decisionsAB += 1 }
      if bcDecision { decisionsBC += 1 }
      if cdDecision { decisionsCD += 1 }
      let aAcc1 = floorMatch(a, track: track, acc2: false)
      let cAcc1 = floorMatch(c, track: track, acc2: false)
      let aAcc2 = floorMatch(a, track: track, acc2: true)
      let cAcc2 = floorMatch(c, track: track, acc2: true)
      if !aAcc1 && cAcc1 { gainedAcc1IDs.append(track.filename) }
      if aAcc1 && !cAcc1 { lostAcc1IDs.append(track.filename) }
      if !aAcc2 && cAcc2 { gainedAcc2IDs.append(track.filename) }
      if aAcc2 && !cAcc2 { lostAcc2IDs.append(track.filename) }
      let evidence = arms[2]!.result?.trace?.rhythmicRegionEvidence
      let controlEvidence = arms[3]!.result?.trace?.rhythmicRegionEvidence
      row["regionOffsets"] = evidence?.regions.map(\.startSample) ?? []
      row["regionBPMs"] = evidence?.regions.map { $0.bpm as Any? ?? NSNull() } ?? []
      row["uniformRegionOffsets"] = controlEvidence?.regions.map(\.startSample) ?? []
      row["uniformRegionBPMs"] =
        controlEvidence?.regions.map {
          $0.bpm as Any? ?? NSNull()
        } ?? []
      row["largestAgreementCount"] = evidence?.largestAgreementCount as Any? ?? NSNull()
      row["voteAccepted"] = evidence?.voteAccepted as Any? ?? NSNull()
      row["flipAB"] = abFlip
      row["flipBC"] = bcFlip
      row["flipCD"] = cdFlip
      row["decisionChangeAB"] = abDecision
      row["decisionChangeBC"] = bcDecision
      row["decisionChangeCD"] = cdDecision
      let bWrong = b.map { !isAcc1Match($0, track.primaryBPM, tolerance: 0.02) } ?? false
      let cRight = c.map { isAcc1Match($0, track.primaryBPM, tolerance: 0.02) } ?? false
      let anchor = arms[1]!.result?.trace?.energyTransitionOffset ?? 0
      let laterCorrect =
        evidence?.regions.contains {
          $0.startSample > anchor
            && ($0.bpm.map { isAcc1Match($0, track.primaryBPM, tolerance: 0.02) } ?? false)
        } ?? false
      let suggestive = bWrong && cRight && laterCorrect
      if suggestive { suggestiveIntroLocks += 1 }
      row["suggestiveIntroLock"] = suggestive
      rows.append(row)
    }
    FileHandle.standardError.write(Data("\(label): \(corpus.count)/\(corpus.count) tracks\n".utf8))
    return [
      "trackCount": corpus.count, "counts": counts, "runtimeSeconds": runtime,
      "productionRuntimeSeconds": productionRuntime,
      "productionTimingErrors": productionTimingErrors,
      "flipsAB": flipsAB, "flipsBC": flipsBC, "flipsCD": flipsCD,
      "decisionChangesAB": decisionsAB, "decisionChangesBC": decisionsBC,
      "decisionChangesCD": decisionsCD,
      "gainedAcc1AgainstA": gainedAcc1IDs.count,
      "lostAcc1AgainstA": lostAcc1IDs.count,
      "gainedAcc2AgainstA": gainedAcc2IDs.count,
      "lostAcc2AgainstA": lostAcc2IDs.count,
      "gainedAcc1IDsAgainstA": gainedAcc1IDs,
      "lostAcc1IDsAgainstA": lostAcc1IDs,
      "gainedAcc2IDsAgainstA": gainedAcc2IDs,
      "lostAcc2IDsAgainstA": lostAcc2IDs,
      "deltaAcc1CB": counts["C"]!["acc1"]! - counts["B"]!["acc1"]!,
      "deltaAcc1CD": counts["C"]!["acc1"]! - counts["D"]!["acc1"]!,
      "deltaAcc1CA": counts["C"]!["acc1"]! - counts["A"]!["acc1"]!,
      "deltaAcc2CB": counts["C"]!["acc2"]! - counts["B"]!["acc2"]!,
      "deltaAcc2CD": counts["C"]!["acc2"]! - counts["D"]!["acc2"]!,
      "deltaAcc2CA": counts["C"]!["acc2"]! - counts["A"]!["acc2"]!,
      "suggestiveIntroLocks": suggestiveIntroLocks, "tracks": rows,
    ]
  }

  private func promotionDecision(
    oa: [String: Any], giant: [String: Any], fullCorpus: Bool
  ) -> [String: Any] {
    func count(_ report: [String: Any], _ arm: String, _ metric: String) -> Int {
      let all = report["counts"] as? [String: [String: Int]]
      return all?[arm]?[metric] ?? 0
    }
    let oaGain = count(oa, "C", "acc1") - count(oa, "A", "acc1")
    let placementGain = count(oa, "C", "acc1") - count(oa, "D", "acc1")
    let giantAcc1NoFall = count(giant, "C", "acc1") >= count(giant, "A", "acc1")
    let giantAcc2NoFall = count(giant, "C", "acc2") >= count(giant, "A", "acc2")
    let times = oa["productionRuntimeSeconds"] as? [String: Double] ?? [:]
    let ratio = (times["C"] ?? 0) / max(times["A"] ?? 0, .leastNormalMagnitude)
    let timingValid =
      (oa["productionTimingErrors"] as? Int ?? 1) == 0
      && (times["A"] ?? 0) > 0 && (times["C"] ?? 0) > 0
    let numericConditionsPassed =
      oaGain >= 2 && giantAcc1NoFall && giantAcc2NoFall
      && timingValid && ratio <= 1.15
    return [
      "fullCorpusEligible": fullCorpus,
      "oa300Acc1GainTracks": oaGain,
      "oa300Acc1GainedTracks": oa["gainedAcc1AgainstA"] ?? 0,
      "oa300Acc1LostTracks": oa["lostAcc1AgainstA"] ?? 0,
      "oa300Acc1RegressionIDs": oa["lostAcc1IDsAgainstA"] ?? [],
      "oa300Acc2GainedTracks": oa["gainedAcc2AgainstA"] ?? 0,
      "oa300Acc2LostTracks": oa["lostAcc2AgainstA"] ?? 0,
      "oa300Acc2RegressionIDs": oa["lostAcc2IDsAgainstA"] ?? [],
      "oa300PlacementAcc1GainTracks": placementGain,
      "oa300GainAtLeastTwo": oaGain >= 2,
      "giantstepsFloorAcc1NoFall": giantAcc1NoFall,
      "giantstepsFloorAcc2NoFall": giantAcc2NoFall,
      "giantstepsAcc1GainedTracks": giant["gainedAcc1AgainstA"] ?? 0,
      "giantstepsAcc1LostTracks": giant["lostAcc1AgainstA"] ?? 0,
      "giantstepsAcc1RegressionIDs": giant["lostAcc1IDsAgainstA"] ?? [],
      "giantstepsAcc2GainedTracks": giant["gainedAcc2AgainstA"] ?? 0,
      "giantstepsAcc2LostTracks": giant["lostAcc2AgainstA"] ?? 0,
      "giantstepsAcc2RegressionIDs": giant["lostAcc2IDsAgainstA"] ?? [],
      "oa300ReleaseRuntimeRatio": ratio,
      "runtimeWithin15Percent": timingValid && ratio <= 1.15,
      "numericConditionsPassed": numericConditionsPassed,
      "numericGatePassed": fullCorpus && numericConditionsPassed,
      "placementAttributionSupported": placementGain > 0,
      "perTrackReviewRequired": true,
    ]
  }
}
