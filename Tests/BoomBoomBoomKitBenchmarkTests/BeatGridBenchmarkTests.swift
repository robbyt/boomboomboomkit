//
//  BeatGridBenchmarkTests.swift
//  BoomBoomBoomKit
//
//  Story-8.7 beat-grid acceptance benchmark. Env-gated on the Rekordbox-derived
//  JAMS beat oracle (story DD-13): analyzes each corpus track, emits estimated
//  beats as JAMS for the `mir_eval` F-measure sidecar (DD-12 make-two-step — no
//  Process-from-test), asserts coverage-parity (DD-10), measures FR-29 last-beat
//  drift on long files (AC6), and validates the Story-8.5a downbeat detector
//  (fire rate / abstain rate reported, octave-tolerant downbeat correctness gated).
//
//  The F-measure floor itself is asserted by `BeatGridFloorTests` (a separate
//  suite the make target runs AFTER the Python sidecar emits the accuracy JSON).
//
//  Run via `make benchmark-beatgrid` (sets BEAT_GRID_ORACLE + BEAT_GRID_OUT_DIR).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Beat-matching helpers (octave-tolerant)

/// Greedy nearest-neighbor matching of estimated onsets to reference onsets within
/// `tolerance` seconds. Each reference time matches at most one estimate. Returns
/// precision / recall / F over the two sorted arrays.
enum BeatMatch {
  static let toleranceSeconds = 0.07  // +-70 ms, mir_eval's f_measure_threshold

  static func score(reference: [Double], estimated: [Double]) -> (
    precision: Double, recall: Double, f: Double
  ) {
    guard !reference.isEmpty, !estimated.isEmpty else { return (0, 0, 0) }
    let ref = reference.sorted()
    let est = estimated.sorted()
    var matched = 0
    var ri = 0
    var ei = 0
    while ri < ref.count, ei < est.count {
      let diff = est[ei] - ref[ri]
      if abs(diff) <= toleranceSeconds {
        matched += 1
        ri += 1
        ei += 1
      } else if diff < 0 {
        ei += 1
      } else {
        ri += 1
      }
    }
    let precision = Double(matched) / Double(est.count)
    let recall = Double(matched) / Double(ref.count)
    let f = (precision + recall) > 0 ? 2 * precision * recall / (precision + recall) : 0
    return (precision, recall, f)
  }

  /// Half-tempo grid: every other beat starting at `phase` (0 or 1).
  static func downsample(_ beats: [Double], phase: Int) -> [Double] {
    guard !beats.isEmpty else { return beats }
    return stride(from: phase, to: beats.count, by: 2).map { beats[$0] }
  }

  /// Double-tempo grid: original beats plus their consecutive midpoints.
  static func upsample(_ beats: [Double]) -> [Double] {
    guard beats.count >= 2 else { return beats }
    var out = beats
    for i in 0..<(beats.count - 1) { out.append((beats[i] + beats[i + 1]) / 2) }
    return out.sorted()
  }

  /// Extrapolate an infinite constant grid `anchorTime + period·m` clipped to `[0, upper]`
  /// — the consumer-contract grid (anchor + tempo), spanning the FULL track to match the
  /// full-track oracle rather than the raw detected-beat span (Codex review: a raw-span
  /// grid deflates recall when the tracker trims the intro/outro). `anchorTime` only sets
  /// the grid phase (`anchorTime mod period`); the span is governed by `upper`.
  static func extrapolate(anchorTime: Double, period: Double, upper: Double) -> [Double] {
    guard period > 0, period.isFinite, upper >= 0, anchorTime.isFinite else { return [] }
    var t = anchorTime - (anchorTime / period).rounded(.down) * period  // first beat in [0, period)
    if t < 0 { t += period }
    var beats: [Double] = []
    while t <= upper {
      beats.append(t)
      t += period
      if beats.count > 1_000_000 { break }  // pathological-tempo backstop
    }
    return beats
  }

  /// The tempo-octave-tolerant F: the max F over the estimate's tempo octaves so a
  /// correct-but-half/double grid is not penalized (story DD-15 / DD-18 — the corpus
  /// is ~77% half-time-tagged).
  static func octaveTolerantF(reference: [Double], estimated: [Double]) -> Double {
    let variants = [
      estimated,
      downsample(estimated, phase: 0),
      downsample(estimated, phase: 1),
      upsample(estimated),
    ]
    return variants.map { score(reference: reference, estimated: $0).f }.max() ?? 0
  }
}

// MARK: - Beat-grid acceptance suite

@Suite("Beat-Grid Acceptance Benchmark")
struct BeatGridBenchmarkTests {

  private let oracle: JAMSCorpus
  private let outDir: URL
  private let limit: Int

  /// A resolved corpus row: the audio URL to analyze plus the oracle beats/downbeats.
  private struct Row: Sendable {
    let trackId: String
    let basename: String
    let url: URL
    let durationSeconds: Double?
    let constantTempo: Bool
    let oracleBeats: [Double]
    let oracleDownbeats: [Double]
  }

  init() throws {
    guard let oraclePath = ProcessInfo.processInfo.environment["BEAT_GRID_ORACLE"],
      !oraclePath.isEmpty
    else { throw BeatGridBenchmarkError.oracleNotSet }
    guard let outPath = ProcessInfo.processInfo.environment["BEAT_GRID_OUT_DIR"], !outPath.isEmpty
    else { throw BeatGridBenchmarkError.outDirNotSet }
    let data = try Data(contentsOf: URL(fileURLWithPath: oraclePath))
    oracle = try JSONDecoder().decode(JAMSCorpus.self, from: data)
    outDir = URL(fileURLWithPath: outPath)
    limit = ProcessInfo.processInfo.environment["BEAT_GRID_LIMIT"].flatMap { Int($0) } ?? 0
  }

  /// Oracle entries whose audio file exists and is non-empty on disk, capped by
  /// BEAT_GRID_LIMIT. This is the coverage-parity denominator (DD-10).
  private func resolveRows() -> [Row] {
    var rows: [Row] = []
    for file in oracle.entries {
      guard let ids = file.fileMetadata.identifiers,
        let trackId = ids.trackId,
        let path = ids.localPath
      else { continue }
      let url = URL(fileURLWithPath: path)
      guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0
      else { continue }
      guard let beat = file.beatAnnotation else { continue }
      rows.append(
        Row(
          trackId: trackId,
          basename: ids.basename ?? url.lastPathComponent,
          url: url,
          durationSeconds: file.fileMetadata.duration,
          constantTempo: file.constantTempo ?? true,
          oracleBeats: beat.beatTimes,
          oracleDownbeats: beat.downbeatTimes))
      if limit > 0 && rows.count >= limit { break }
    }
    return rows
  }

  // MARK: Analyze corpus: emit beats + coverage-parity + downbeat + FR-29 drift

  @Test("analyze corpus: emit beats, assert coverage-parity, downbeat + drift")
  func analyzeAndAssert() async throws {
    let rows = resolveRows()
    try #require(!rows.isEmpty, "no resolvable corpus rows — check BEAT_GRID_ORACLE + audio paths")

    // TWO full-track passes per track (Codex review):
    //  - Pass A `detectDownbeats: false` — the STABLE default anchor for the beat-grid
    //    F-measure + FR-29 drift. (`detectDownbeats: true` repoints `gridOrigin` to the
    //    first downbeat on fired tracks — BeatGridAnalyzer.swift:354 — which would make
    //    the beat-grid phase inconsistent between fired and non-fired tracks.)
    //  - Pass B `detectDownbeats: true` — the Story-8.5a downbeats for AC7.
    // Both grids are emitted as the anchor+tempo EXTRAPOLATION over the FULL [0, duration]
    // span (the consumer contract a sync tool uses; Rekordbox's grid is the same), NOT the
    // raw detected beats whose per-onset jitter the BeatGrid DocC warns against.
    struct Analyzed: Sendable {
      let row: Row
      let beats: [Double]  // extrapolated grid over the full track span
      let downbeats: [Double]?  // nil == legitimate abstain (.noneDetected/.notAttempted)
      let downbeatPassFailed: Bool  // Pass B threw/nil despite Pass A success — a defect
      let drift: Double?  // |last RAW beat - anchor extrapolation|, nil if not computable
      let estimatedTempo: Double  // grid tempo (Pass A) — for octave stratification
      let confidence: Double  // grid confidence (Pass A) — for low-confidence stratification
    }

    let analyzed = await withTaskGroup(of: (Int, Analyzed?).self) { group in
      for (i, row) in rows.enumerated() {
        group.addTask {
          var beatOpts = AudioAnalysisService.Options()
          beatOpts.beatGridCoverage = .fullTrack
          beatOpts.maxSeconds = 1e9  // full-file read (sanitized to full-file by the reader)
          var downbeatOpts = beatOpts
          downbeatOpts.detectDownbeats = true

          // Pass A — stable anchor for the beat grid + drift.
          guard
            let gridA = try? AudioAnalysisService.analyzeBeatGrid(url: row.url, options: beatOpts),
            !gridA.beats.isEmpty,
            let anchorA = gridA.gridOrigin,
            gridA.estimatedTempo > 0
          else { return (i, nil) }
          let rawBeats = gridA.beats.map(\.presentationTime)
          let period = 60.0 / gridA.estimatedTempo
          // Span the full track: the oracle duration, else the last raw beat.
          let upper = max(row.durationSeconds ?? 0, rawBeats.last ?? 0)
          let estimatedBeats = BeatMatch.extrapolate(
            anchorTime: anchorA.presentationTime, period: period, upper: upper)

          // FR-29 last-beat drift = how far the last RAW beat strays from the anchor
          // extrapolation (the metric that justifies "extrapolate, don't trust raw").
          var drift: Double?
          if gridA.beats.count >= 2 {
            let lastIndex = gridA.beats.count - 1
            let expected = anchorA.presentationTime + period * Double(lastIndex - anchorA.beatIndex)
            drift = abs(rawBeats[lastIndex] - expected)
          }

          // Pass B — downbeats, extrapolated as a bar grid over the full span. Distinguish a
          // legitimate abstain (.noneDetected/.notAttempted) from a Pass-B analysis FAILURE
          // (nil grid) — the latter is a defect, not an abstention, since Pass A already
          // proved the track analyzable (Codex review round 2).
          var downbeats: [Double]?
          var downbeatPassFailed = false
          if let gridB = try? AudioAnalysisService.analyzeBeatGrid(
            url: row.url, options: downbeatOpts), !gridB.beats.isEmpty
          {
            if case .detected(let estimate) = gridB.downbeats,
              let first = estimate.beats.first,
              gridB.estimatedTempo > 0
            {
              let barPeriod = 60.0 / gridB.estimatedTempo * Double(estimate.meter.beatsPerBar)
              downbeats = BeatMatch.extrapolate(
                anchorTime: first.presentationTime, period: barPeriod, upper: upper)
            } else {
              downbeats = nil  // legitimate abstain
            }
          } else {
            downbeatPassFailed = true  // Pass B failed where Pass A succeeded
            downbeats = nil
          }

          return (
            i,
            Analyzed(
              row: row, beats: estimatedBeats, downbeats: downbeats,
              downbeatPassFailed: downbeatPassFailed, drift: drift,
              estimatedTempo: gridA.estimatedTempo, confidence: Double(gridA.confidence))
          )
        }
      }
      var out = [Analyzed?](repeating: nil, count: rows.count)
      for await (i, a) in group { out[i] = a }
      return out
    }

    // Evaluated = rows that produced a non-empty beat grid.
    let evaluated = analyzed.compactMap { $0 }.filter { !$0.beats.isEmpty }

    // --- Emit estimated JAMS for the sidecar (write BEFORE asserting, so a coverage
    //     failure still leaves the artifact for inspection during calibration). ---
    let estimatedFiles = evaluated.map { a in
      // JAMS 0.4 requires file_metadata.duration: use the oracle duration, falling back
      // to the last extrapolated beat so it is never nil. Per-beat value/confidence stay
      // nil (Pass A has no per-beat phase or calibrated confidence) — the strict encoder
      // writes them as JSON `null`, which the `beat` namespace permits.
      JAMSFile(
        fileMetadata: JAMSFileMetadata(
          title: nil, artist: nil,
          duration: max(a.row.durationSeconds ?? 0, a.beats.last ?? 0),
          identifiers: JAMSIdentifiers(
            basename: a.row.basename, localPath: a.row.url.path, trackId: a.row.trackId)),
        annotations: [
          JAMSAnnotation(
            namespace: .beat,
            data: a.beats.sorted().map {
              JAMSObservation(time: $0, value: nil, confidence: nil, duration: 0)
            },
            annotationMetadata: JAMSAnnotationMetadata(
              curator: nil, dataSource: "BoomBoomBoomKit DSP beat grid (anchor+tempo extrapolation)"
            ))
        ])
    }
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    let estimatedURL = outDir.appendingPathComponent("8-7-estimated-beats.jams.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(JAMSCorpus(entries: estimatedFiles)).write(to: estimatedURL)
    print("\n=== Beat-Grid Acceptance — emitted \(estimatedFiles.count) estimated tracks ===")
    print("  estimated JAMS -> \(estimatedURL.path)")

    // --- Coverage-parity (AC3 / DD-10): every analyzable row produced a grid. ---
    let trackIds = rows.map(\.trackId)
    #expect(Set(trackIds).count == trackIds.count, "oracle track_ids must be unique")
    #expect(
      evaluated.count == rows.count,
      "coverage-parity (DD-10): \(evaluated.count)/\(rows.count) rows produced a non-empty grid")
    #expect(evaluated.allSatisfy { !$0.beats.isEmpty }, "every evaluated track has beats[]")

    // A Pass-B (downbeat) analysis failure where Pass A succeeded is a defect, NOT an
    // abstain (Codex review round 2) — lock it at zero so it cannot silently inflate the
    // abstain rate.
    let downbeatFailures = evaluated.filter(\.downbeatPassFailed).count
    #expect(
      downbeatFailures == 0,
      "downbeat Pass B failed on \(downbeatFailures) track(s) that Pass A analyzed (defect)")

    // --- Downbeat validation (AC7 / Task 6): fire/abstain reported, correctness gated. ---
    // Fire/abstain are REPORTED over every track whose downbeat pass ran (8.5a is
    // conservative; a low fire rate is acceptable). Correctness-when-fired is the
    // safety-critical GATE and scopes to constant-tempo tracks — the only material the
    // 8.5a estimator (fixed 4/4, constant tempo) documents support for (DD-19).
    let downbeatEvaluated = evaluated.filter { !$0.downbeatPassFailed }
    let fired = downbeatEvaluated.filter { $0.downbeats != nil }
    let fireRate =
      downbeatEvaluated.isEmpty ? 0 : Double(fired.count) / Double(downbeatEvaluated.count)
    let abstainRate = downbeatEvaluated.isEmpty ? 0 : 1.0 - fireRate

    // Octave-tolerant downbeat F per fired track (DD-18 — same half-time reality as the
    // beat F-measure). Sustained recurring-phase agreement is captured by scoring ALL
    // detected downbeats across the track, not just the first.
    func downbeatF(_ a: Analyzed) -> Double? {
      guard let est = a.downbeats, !a.row.oracleDownbeats.isEmpty else { return nil }
      return BeatMatch.octaveTolerantF(reference: a.row.oracleDownbeats, estimated: est)
    }
    let allFs = fired.compactMap(downbeatF)
    let constantFs = fired.filter { $0.row.constantTempo }.compactMap(downbeatF)
    let meanAll = allFs.isEmpty ? 0 : allFs.reduce(0, +) / Double(allFs.count)
    let meanConstant = constantFs.isEmpty ? 0 : constantFs.reduce(0, +) / Double(constantFs.count)

    print(
      "  downbeat: fire-rate \(pct(fireRate)) (\(fired.count)/\(downbeatEvaluated.count)), "
        + "abstain-rate \(pct(abstainRate)), pass-failures \(downbeatFailures)")
    print("  downbeat correctness-when-fired (octave-tolerant F, mean):")
    print("    constant-tempo (gated): \(fmt(meanConstant)) over \(constantFs.count) tracks")
    print("    all fired (reported):   \(fmt(meanAll)) over \(allFs.count) tracks")

    let downbeatJSON: [String: Any] = [
      "n_evaluated": downbeatEvaluated.count,
      "n_pass_failures": downbeatFailures,
      "n_fired": fired.count,
      "fire_rate": fireRate,
      "abstain_rate": abstainRate,
      "n_scored_all": allFs.count,
      "n_scored_constant": constantFs.count,
      "mean_downbeat_f_octave_all": meanAll,
      "mean_downbeat_f_octave_constant": meanConstant,
      "tolerance_ms": Int(BeatMatch.toleranceSeconds * 1000),
      "gated_metric": "mean_downbeat_f_octave_constant",
      "metric": "octave-tolerant downbeat F over ALL detected downbeats vs oracle Battito==1",
    ]
    let downbeatURL = outDir.appendingPathComponent("8-7-downbeat-accuracy.json")
    try JSONSerialization.data(
      withJSONObject: downbeatJSON, options: [.prettyPrinted, .sortedKeys]
    )
    .write(to: downbeatURL)
    print("  downbeat accuracy -> \(downbeatURL.path)")

    // The single downbeat GATE (the safety-critical metric) over constant-tempo tracks.
    // Locked from the calibration run (Task 5). A BEAT_GRID_LIMIT subset scores only a
    // slice (the floor was calibrated over the full ~42 fired tracks), so a partial
    // number can't meet the full-corpus floor — report but do NOT gate under smoke,
    // mirroring the F-measure floor's SMOKE MODE (the full CI run is the real gate).
    if limit > 0 {
      print("  SMOKE MODE — downbeat floor not gated (BEAT_GRID_LIMIT=\(limit))")
    } else {
      #expect(
        meanConstant >= Self.downbeatCorrectnessFloor,
        "downbeat correctness-when-fired (constant) \(fmt(meanConstant)) below floor \(fmt(Self.downbeatCorrectnessFloor))"
      )
    }

    // --- FR-29 last-beat phase-drift (Story 8-9 AC #6). The anchor+single-tempo
    //     extrapolation is drift-free by construction only on constant-tempo
    //     material (DD-19), so the GATE scopes to constant-tempo tracks >= 5 min;
    //     the stratified breakdown is REPORTED across every analyzable track so a
    //     bucket regression is visible. Computed from the SAME full-track grids. ---

    // Oracle tempo (median inter-beat interval → BPM) for the octave strata.
    func oracleTempo(_ a: Analyzed) -> Double? {
      let beats = a.row.oracleBeats.sorted()
      guard beats.count >= 2 else { return nil }
      var ibis: [Double] = []
      ibis.reserveCapacity(beats.count - 1)
      for i in 1..<beats.count { ibis.append(beats[i] - beats[i - 1]) }
      let med = ibis.sorted()[ibis.count / 2]
      return med > 0 ? 60.0 / med : nil
    }
    // Octave classification of the grid tempo vs the oracle's: correct at unison
    // (within 4%), "octave" at a clean half/double, else off.
    func octaveClass(_ a: Analyzed) -> String {
      guard a.estimatedTempo > 0, let ot = oracleTempo(a), ot > 0 else { return "unknown" }
      let r = a.estimatedTempo / ot
      func near(_ x: Double, _ y: Double) -> Bool { abs(x - y) / y <= 0.04 }
      if near(r, 1) { return "octave-correct" }
      if near(r, 0.5) || near(r, 2) { return "octave-wrong" }
      return "octave-off"
    }

    // Stratified drift reporting (REPORTED, not gated). Each stratum prints the
    // median / P90 / P95 / P99 and the median:P95 spread ratio (diagnostic only —
    // a ratio can "improve" because the median worsens, so it never gates).
    func report(_ label: String, _ rows: [Analyzed]) {
      let d = rows.compactMap(\.drift).sorted()
      guard !d.isEmpty else {
        print("    \(label): (no tracks)")
        return
      }
      func pctile(_ q: Double) -> Double {
        let idx = max(0, Int((Double(d.count) * q).rounded(.up)) - 1)
        return d[min(d.count - 1, idx)]
      }
      let med = d[d.count / 2]
      let p95 = pctile(0.95)
      let ratio = p95 > 0 ? med / p95 : 0
      print(
        "    \(label) (n=\(d.count)): median \(fmt(med * 1000)) / P90 \(fmt(pctile(0.90) * 1000)) "
          + "/ P95 \(fmt(p95 * 1000)) / P99 \(fmt(pctile(0.99) * 1000)) ms; med:P95 ratio \(fmt(ratio))"
      )
    }

    let withDrift = evaluated.filter { $0.drift != nil }
    let constant = withDrift.filter { $0.row.constantTempo }
    print("  FR-29 last-beat drift — stratified (REPORTED):")
    report("all", withDrift)
    report("constant-tempo", constant)
    report("variable-tempo", withDrift.filter { !$0.row.constantTempo })
    report("octave-correct", withDrift.filter { octaveClass($0) == "octave-correct" })
    report("octave-wrong", withDrift.filter { octaveClass($0) == "octave-wrong" })
    report("low-confidence (<0.5)", withDrift.filter { $0.confidence < 0.5 })
    report("short (<5 min)", withDrift.filter { ($0.row.durationSeconds ?? 0) < 300 })
    report("long (>=5 min)", withDrift.filter { ($0.row.durationSeconds ?? 0) >= 300 })

    // Aspirational musical target (REPORTED, not gated): the share of gated
    // constant-tempo tracks whose drift is within the 50 ms "DJ-syncable" target
    // (Story 8-9 AC #11 — onset-asynchrony psychoacoustics). The committed gate
    // stays the coarse regression net below; this is the north star to ratchet
    // toward, never a merge blocker.
    let gatedRows = constant.filter { ($0.row.durationSeconds ?? 0) >= 300 }
    let drifts = gatedRows.compactMap(\.drift).sorted()
    if drifts.isEmpty {
      print("  FR-29 gate: no constant-tempo tracks >= 5 min in this slice; skipped")
    } else {
      let p95Index = max(0, Int((Double(drifts.count) * 0.95).rounded(.up)) - 1)
      let p95 = drifts[min(drifts.count - 1, p95Index)]
      let median = drifts[drifts.count / 2]
      let within50 =
        Double(drifts.filter { $0 <= Self.driftP95AspirationalSeconds }.count)
        / Double(drifts.count)
      print("  FR-29 GATE (\(drifts.count) constant tracks >= 5 min):")
      print(
        "    median \(fmt(median * 1000)) ms, P95 \(fmt(p95 * 1000)) ms "
          + "(regression gate <= \(fmt(Self.driftP95GateSeconds * 1000)) ms)")
      print(
        "    aspirational: \(pct(within50)) of tracks within the "
          + "\(fmt(Self.driftP95AspirationalSeconds * 1000)) ms musical target (reported, not gated)"
      )
      #expect(
        p95 <= Self.driftP95GateSeconds,
        "FR-29 P95 last-beat drift \(fmt(p95 * 1000)) ms exceeds gate \(fmt(Self.driftP95GateSeconds * 1000)) ms"
      )
    }
  }

  // MARK: Committed floors (locked from the Task-5 calibration run)

  /// Octave-tolerant downbeat correctness-when-fired floor (constant-tempo). Locked
  /// from the 2026-06-17 calibration: measured 0.1444 over 42 fired tracks − ~0.04 margin
  /// (slightly wider than the F-measure margin given the small fired-track N). This is a
  /// regression net, NOT a quality certification — see `8-7-pressure-release.md`.
  static let downbeatCorrectnessFloor = 0.10

  /// FR-29 P95 last-beat drift regression ceiling, in seconds. The epic's OA300 target is
  /// 30 ms, which the real-world Rekordbox corpus does not meet (measured P95 1.65 s — the
  /// audio's own tempo drift, not a code regression; pressure-release valve fired). This
  /// 2.0 s ceiling is a coarse regression net, NOT the 30 ms aspiration — see
  /// `8-7-pressure-release.md`. Story 8-9 retightens this committed floor to the
  /// post-refit measured−margin value once the operator's release run lands (AC #11 Task 6).
  static let driftP95GateSeconds = 2.0

  /// Aspirational "DJ-syncable" per-track phase-drift target, in seconds (50 ms). REPORTED
  /// only — never a merge gate. Justified by onset-asynchrony psychoacoustics (perceptually
  /// "tight" beat alignment is under ~20–30 ms) and the Rekordbox oracle's 1 ms beat-position
  /// quantization, which leaves a sub-50 ms target unbounded by oracle precision (Story 8-9
  /// AC #11). The committed regression net is ``driftP95GateSeconds``; this is the north star.
  static let driftP95AspirationalSeconds = 0.050

  // MARK: Formatting helpers

  private func fmt(_ x: Double) -> String { String(format: "%.4f", x) }
  private func pct(_ x: Double) -> String { String(format: "%.1f%%", x * 100) }
}

// MARK: - F-measure floor (read from the sidecar's accuracy JSON)

/// Asserts the committed octave-normalized F-measure floor against the accuracy JSON
/// the Python sidecar emits. A separate suite (not the emit suite) so `make
/// benchmark-beatgrid` can run it AFTER the sidecar (DD-12) without re-analyzing the
/// corpus. Env-gated on BEAT_GRID_ACCURACY_JSON so a bare `swift test` skips it.
@Suite("Beat-Grid F-measure Floor")
struct BeatGridFloorTests {

  /// Octave-normalized constant-tempo mean F-measure floor. Locked from the 2026-06-17
  /// calibration (full-span extrapolated grid, stable anchor — Codex-reviewed): measured
  /// 0.3718 − ~0.04 margin (the FR-10 BPM-floor precedent of committing below the measured
  /// value). The epic's 0.75 target is NOT met on the real-world Rekordbox corpus — this is
  /// a regression net; see `8-7-pressure-release.md`.
  static let fMeasureFloor = 0.33

  private let accuracy: [String: Any]

  init() throws {
    guard let path = ProcessInfo.processInfo.environment["BEAT_GRID_ACCURACY_JSON"],
      !path.isEmpty,
      FileManager.default.fileExists(atPath: path)
    else { throw BeatGridBenchmarkError.accuracyJSONNotSet }
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    accuracy = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any],
      "accuracy JSON is not an object")
  }

  @Test("octave-normalized constant-tempo mean F-measure meets the committed floor")
  func meetsFloor() throws {
    let gated = (accuracy["mean_f_measure_octave_constant"] as? Double) ?? 0
    let allOctave = (accuracy["mean_f_measure_octave_all"] as? Double) ?? 0
    let rawAll = (accuracy["mean_f_measure_raw_all"] as? Double) ?? 0
    let n = (accuracy["n_tracks"] as? Int) ?? 0
    let nConstant = (accuracy["n_tracks_constant"] as? Int) ?? 0
    print("\n=== Beat-Grid F-measure Floor (\(n) tracks, \(nConstant) constant-tempo) ===")
    print("  raw mean (all):              \(String(format: "%.4f", rawAll))")
    print("  octave-normalized (all):     \(String(format: "%.4f", allOctave))")
    print("  octave-normalized (constant, GATED): \(String(format: "%.4f", gated))")
    print("  floor: \(String(format: "%.4f", Self.fMeasureFloor))")
    // SMOKE MODE: a BEAT_GRID_LIMIT subset scores only a slice, so the full-corpus floor is
    // meaningless — report the measured F but do NOT gate. The full CI run (BEAT_GRID_LIMIT
    // unset) is the real gate; the Python sidecar likewise requires --allow-missing-constant
    // for a subset, so a partial number can never masquerade as the committed floor.
    if let limit = ProcessInfo.processInfo.environment["BEAT_GRID_LIMIT"].flatMap(Int.init),
      limit > 0
    {
      print("  SMOKE MODE — F-measure floor not gated (BEAT_GRID_LIMIT=\(limit))")
      return
    }
    #expect(
      gated >= Self.fMeasureFloor,
      "octave-normalized constant-tempo mean F-measure \(String(format: "%.4f", gated)) below floor \(String(format: "%.4f", Self.fMeasureFloor))"
    )
  }
}

// MARK: - Errors

private enum BeatGridBenchmarkError: Error {
  case oracleNotSet
  case outDirNotSet
  case accuracyJSONNotSet
}
