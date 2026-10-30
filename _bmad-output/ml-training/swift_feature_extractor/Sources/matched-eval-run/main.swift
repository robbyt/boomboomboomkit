//
//  matched-eval-run — Story 15.9.
//
//  Develop-only Swift CLI. Runs the three Swift systems of the 15.9 evaluation
//  on every track of an input JSON and writes one record per (track, system):
//
//    boomboomboomkit-optimal   `AudioAnalysisService.analyze(url:)` at default
//                              options (TechniqueSet.optimal). Its decode is
//                              captured through the internal decode-observer seam.
//    variant-joint-fit         Story 15.7 on that same decode:
//                              DSPStubObservationProducer -> BarStateDecoder at the
//                              default BPM and level .quarter (the level the BPM
//                              stage chose; the fit never changes octave) ->
//                              JointTempoPhaseFit.fit(observations:candidate:).
//                              Grid from the fit's tempo and phase anchor; a nil
//                              decode or fit abstains. The metrical-level selector's
//                              choice is recorded as a diagnostic only.
//    variant-comb-best-phase   Story 15.10 follow-up: `analyze(decoded:)` on the
//                              default pass's own decode with
//                              `BeatGridAnalyzer.combPhaseObserver` bound; the default
//                              grid's tempo re-anchored at the onset-comb best phase.
//                              Refused (failed) when its grid differs from the
//                              default pass, its BPM differs from the same
//                              `analyze(decoded:)` call without the observer (the
//                              decoded path has no file tags, so its BPM can
//                              legitimately differ from the URL pass), or the
//                              observed tempo differs from the grid tempo. Its BPM
//                              answer is the default pass's. Runtime and memory not
//                              comparable.
//
//  Runtime and memory per system. Each pass runs alone; the physical footprint
//  (`task_info` TASK_VM_INFO `phys_footprint`) is sampled every millisecond on a
//  second thread while the pass runs, and the record holds the high-water mark
//  minus the footprint just before the pass. The joint-fit row needs the default
//  pass for its seed, so its runtime is the default pass plus the fit stage and its
//  memory the larger of the two passes' peaks; the stage alone is recorded too.
//
//  Every audio file is hashed before any analysis; a sha256 that differs from the
//  input refuses the whole run (exit 3, naming the track). The output records the
//  git SHA (with a dirty flag) of the checkout the binary sits in and the build
//  configuration, so the report can refuse a runner output from other code.
//
//  Build (release needs -enable-testing for the internal Story 15.7 types):
//    swift build -c release -Xswiftc -enable-testing --product matched-eval-run
//  Run:
//    matched-eval-run --input <runner-input.json> --output <runner-output.json> [--limit N]
//

import CryptoKit
import Darwin
import Foundation
import Synchronization

@testable import BoomBoomBoomKit

#if DEBUG
  let buildConfiguration = "debug"
#else
  let buildConfiguration = "release -Xswiftc -enable-testing"
#endif

let runnerSchema = "15.9-runner-output.v1"

func fail(_ message: String, code: Int32 = 1) -> Never {
  FileHandle.standardError.write(Data("matched-eval-run: \(message)\n".utf8))
  exit(code)
}

// MARK: - CLI

let usage = "usage: matched-eval-run --input <in.json> --output <out.json> [--limit N]"
var inputPath: String?
var outputPath: String?
var limit: Int?
do {
  var args = CommandLine.arguments.dropFirst().makeIterator()
  while let arg = args.next() {
    switch arg {
    case "--input": inputPath = args.next()
    case "--output": outputPath = args.next()
    case "--limit":
      guard let value = args.next(), let n = Int(value), n >= 0 else {
        fail("--limit needs a non-negative integer. \(usage)", code: 2)
      }
      limit = n
    default: fail("unknown argument \(arg). \(usage)", code: 2)
    }
  }
}
guard let inputPath, let outputPath else { fail(usage, code: 2) }

// MARK: - Provenance

/// `git` in the directory holding this binary, so the SHA names the checkout it was
/// built from. `nil` when git is unavailable.
func git(_ args: [String]) -> String? {
  let exe = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
  process.arguments = ["-C", exe.deletingLastPathComponent().path] + args
  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = FileHandle.nullDevice
  do { try process.run() } catch { return nil }
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  guard process.terminationStatus == 0 else { return nil }
  return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}
let runnerGitSha = git(["rev-parse", "HEAD"]) ?? "unknown"
let runnerDirty =
  git(["status", "--porcelain", "--untracked-files=no"]).map { !$0.isEmpty } ?? true

// MARK: - Input

struct TrackInput: Decodable {
  let trackId: String
  let corpus: String
  let audioPath: String
  let audioSha256: String
}

struct RunnerInput: Decodable {
  let schema: String
  let tracks: [TrackInput]
}

let inputData: Data
do {
  inputData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
} catch {
  fail("cannot read \(inputPath): \(error)", code: 2)
}
let input: RunnerInput
do {
  input = try JSONDecoder().decode(RunnerInput.self, from: inputData)
} catch {
  fail("cannot decode \(inputPath): \(error)", code: 2)
}
guard input.schema == "15.9-runner-input.v1" else {
  fail("input schema \(input.schema), expected 15.9-runner-input.v1", code: 2)
}
let tracks = limit.map { Array(input.tracks.prefix($0)) } ?? input.tracks

// MARK: - Hashing

func sha256Hex(of url: URL) throws -> String {
  let handle = try FileHandle(forReadingFrom: url)
  defer { try? handle.close() }
  var hasher = SHA256()
  while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
    hasher.update(data: chunk)
  }
  return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

// Refuse before analysing anything if any file differs from the input.
do {
  var bad: [String] = []
  for (i, track) in tracks.enumerated() {
    let url = URL(fileURLWithPath: track.audioPath)
    do {
      let actual = try sha256Hex(of: url)
      if actual != track.audioSha256 {
        bad.append("\(track.corpus)/\(track.trackId) (sha256 \(actual) != \(track.audioSha256))")
      }
    } catch {
      bad.append("\(track.corpus)/\(track.trackId) (unreadable: \(error))")
    }
    if (i + 1) % 100 == 0 {
      FileHandle.standardError.write(Data("[hash] \(i + 1)/\(tracks.count)\n".utf8))
    }
  }
  if !bad.isEmpty {
    fail("audio differs from the input manifest: " + bad.joined(separator: ", "), code: 3)
  }
}

// MARK: - Memory sampling

let taskPort = mach_task_self_

/// The task's physical footprint (`TASK_VM_INFO` `phys_footprint`), the figure the
/// system itself charges to the process; unlike the resident size it does not keep
/// freed-but-mapped pages.
@Sendable func footprintBytes() -> UInt64 {
  var info = task_vm_info_data_t()
  var count = mach_msg_type_number_t(
    MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
  let kr = withUnsafeMutablePointer(to: &info) { ptr in
    ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
      task_info(taskPort, task_flavor_t(TASK_VM_INFO), $0, &count)
    }
  }
  return kr == KERN_SUCCESS ? info.phys_footprint : 0
}

/// Samples the physical footprint every millisecond on its own thread between
/// `init` and `finish()`.
final class MemorySampler: Sendable {
  let baseline: UInt64
  private let peak: Atomic<UInt64>
  private let stopFlag = Atomic<Bool>(false)
  private let finished = DispatchSemaphore(value: 0)

  init() {
    let base = footprintBytes()
    baseline = base
    peak = Atomic<UInt64>(base)
    let thread = Thread { [self] in
      while !self.stopFlag.load(ordering: .relaxed) {
        self.record(footprintBytes())
        usleep(1_000)
      }
      self.finished.signal()
    }
    thread.start()
  }

  private func record(_ value: UInt64) {
    var current = peak.load(ordering: .relaxed)
    while value > current {
      let (exchanged, original) = peak.compareExchange(
        expected: current, desired: value, ordering: .relaxed)
      if exchanged { return }
      current = original
    }
  }

  /// Stops sampling; returns the high-water mark above the baseline, in bytes.
  func finish() -> UInt64 {
    record(footprintBytes())
    stopFlag.store(true, ordering: .relaxed)
    finished.wait()
    let top = peak.load(ordering: .relaxed)
    return top > baseline ? top - baseline : 0
  }
}

struct Measured<T> {
  let value: T
  let seconds: Double
  let peakBytes: UInt64
}

func measure<T>(_ body: () throws -> T) rethrows -> Measured<T> {
  let sampler = MemorySampler()
  let start = DispatchTime.now().uptimeNanoseconds
  let value: T
  do {
    value = try body()
  } catch {
    _ = sampler.finish()
    throw error
  }
  let end = DispatchTime.now().uptimeNanoseconds
  let peak = sampler.finish()
  return Measured(value: value, seconds: Double(end - start) / 1e9, peakBytes: peak)
}

// MARK: - Records

final class DecodeBox: @unchecked Sendable {
  private let lock = NSLock()
  private var stored: FeatureSubstrate.DecodedAudio?
  func set(_ value: FeatureSubstrate.DecodedAudio) {
    lock.lock()
    stored = value
    lock.unlock()
  }
  func take() -> FeatureSubstrate.DecodedAudio? {
    lock.lock()
    defer { lock.unlock() }
    let value = stored
    stored = nil
    return value
  }
}

final class ObservationBox: Sendable {
  let items = Mutex<[BeatGridAnalyzer.CombPhaseObservation]>([])
}

func finite(_ value: Double?) -> Any {
  guard let value, value.isFinite else { return NSNull() }
  return value
}

func gridRecord(_ grid: BeatGrid, anchorSeconds: Double, anchorSource: String) -> [String: Any] {
  var downbeat: [String: Any] = [:]
  switch grid.downbeats {
  case .notAttempted: downbeat["status"] = "not-attempted"
  case .noneDetected: downbeat["status"] = "none-detected"
  case .detected:
    downbeat["status"] = "detected"
    if let origin = grid.gridOrigin, origin.source == .downbeat {
      downbeat["anchorSeconds"] = finite(origin.presentationTime)
    }
  }
  return [
    "tempoBPM": finite(grid.estimatedTempo),
    "anchorSeconds": finite(anchorSeconds),
    "anchorSource": anchorSource,
    "beatCount": grid.beats.count,
    "analysisSpanStartSeconds": finite(grid.analysisSpan?.startSeconds),
    "analysisSpanEndSeconds": finite(grid.analysisSpan?.endSeconds),
    "downbeat": downbeat,
  ]
}

func statusRecord(
  status: String, reason: String? = nil, tempo: Double? = nil, grid: [String: Any]? = nil,
  runtime: Double?, peak: UInt64?, identity: String, extra: [String: Any] = [:]
) -> [String: Any] {
  var record: [String: Any] = [
    "status": status,
    "reason": reason.map { $0 as Any } ?? NSNull(),
    "tempoBPM": finite(tempo),
    "grid": grid.map { $0 as Any } ?? NSNull(),
    "runtimeSeconds": finite(runtime),
    "peakMemoryAboveBaselineBytes": peak.map { $0 as Any } ?? NSNull(),
    "runtimeComparable": runtime != nil && peak != nil,
    "variantIdentity": identity,
    "buildConfiguration": buildConfiguration,
  ]
  for (key, value) in extra { record[key] = value }
  return record
}

let optimalIdentity =
  "AudioAnalysisService.analyze(url:) at AudioAnalysisService.Options() defaults "
  + "(TechniqueSet.optimal, metadata corroboration on, beat grid over the analysis window, "
  + "no tempo refinement); grid = estimatedTempo extrapolated from gridOrigin"
let jointIdentity =
  "DSPStubObservationProducer(hopSize: sampleRate/100) -> BarStateDecoder.decode("
  + "tempoBPM: default BPM, level: .quarter) -> JointTempoPhaseFit.fit(observations:candidate:) "
  + "[\(JointTempoPhaseFit.modelIdentifier)] on the default pass's decode; grid = fit tempo "
  + "extrapolated from phaseAnchorSeconds"
let combIdentity =
  "default grid (estimatedTempo) re-anchored at the onset-comb best phase "
  + "(BeatGridAnalyzer.combPhaseObserver, fold at the grid period over the tracked beats), "
  + "observed by analyze(decoded:) on the default pass's decode; BPM answer = default BPM"

// MARK: - Per-track passes

func anchorSourceName(_ grid: BeatGrid) -> String {
  guard let origin = grid.gridOrigin else { return "none" }
  return String(describing: origin.source)
}

enum JointOutcome {
  case fit(FittedTempoPhase)
  case abstain(String)
}

/// The 15.7 joint fit at the BPM stage's level, plus the metrical-level selector's
/// choice on the same observations as a diagnostic (outside the timed stage).
func jointFitPass(
  decoded: FeatureSubstrate.DecodedAudio, seed: Double, passA: Measured<Void>?
) -> [String: Any] {
  let hop = Int(decoded.sampleRate / 100)
  var observations: FramewiseObservations?
  let run = measure { () -> JointOutcome in
    guard hop > 0 else { return .abstain("sample-rate-below-100-hz") }
    guard let obs = DSPStubObservationProducer(hopSize: hop).produce(decoded: decoded)
    else { return .abstain("observation-producer-returned-nil") }
    observations = obs
    guard
      let candidate = BarStateDecoder.decode(observations: obs, tempoBPM: seed, level: .quarter)
    else { return .abstain("quarter-level-decode-returned-nil") }
    guard let fit = JointTempoPhaseFit.fit(observations: obs, candidate: candidate)
    else { return .abstain("joint-fit-returned-nil") }
    return .fit(fit)
  }
  var extra: [String: Any] = [
    "stageRuntimeSeconds": run.seconds, "stagePeakMemoryAboveBaselineBytes": run.peakBytes,
    "seedBPM": seed, "fitLevel": MetricalLevel.quarter.rawValue,
  ]
  if let observations {
    let selection = MetricalLevelSelector.select(observations: observations, tempoBPM: seed)
    extra["selectorDiagnosticLevel"] =
      selection.map { $0.chosen.metricalLevel.rawValue as Any } ?? NSNull()
  }
  let runtime = passA.map { $0.seconds + run.seconds }
  let peak = passA.map { max($0.peakBytes, run.peakBytes) }
  switch run.value {
  case .fit(let fit):
    let grid: [String: Any] = [
      "tempoBPM": finite(fit.tempoBPM),
      "anchorSeconds": finite(fit.phaseAnchorSeconds),
      "anchorSource": "joint-fit-phase-anchor",
      "beatCount": NSNull(),
      "analysisSpanStartSeconds": 0.0,
      "analysisSpanEndSeconds": finite(fit.coverageWindowSeconds),
      "downbeat": ["status": "not-attempted"],
    ]
    extra["metricalLevel"] = fit.metricalLevel.rawValue
    extra["keptFraction"] = finite(fit.keptFraction)
    extra["supportScore"] = finite(Double(fit.supportScore))
    extra["decoderIdentifier"] = fit.decoderIdentifier
    extra["observationModelIdentifier"] = fit.observationModelIdentifier
    extra["frontendIdentifier"] = fit.frontendIdentifier
    return statusRecord(
      status: "ok", tempo: fit.tempoBPM, grid: grid, runtime: runtime, peak: peak,
      identity: jointIdentity, extra: extra)
  case .abstain(let reason):
    return statusRecord(
      status: "abstained", reason: reason, runtime: runtime, peak: peak,
      identity: jointIdentity, extra: extra)
  }
}

/// The comb best-phase grid, observed on the default pass's decode. Refused (failed)
/// when the observed run's output differs from the default pass.
func combPass(
  decoded: FeatureSubstrate.DecodedAudio, options: AudioAnalysisService.Options,
  defaultBPM: Double, defaultGrid: BeatGrid?
) -> [String: Any] {
  let seen = ObservationBox()
  let combObserver: @Sendable (BeatGridAnalyzer.CombPhaseObservation) -> Void = { obs in
    seen.items.withLock { $0.append(obs) }
  }
  let result: CombinedAnalysisResult?
  do {
    result = try BeatGridAnalyzer.$combPhaseObserver.withValue(combObserver) {
      try AudioAnalysisService.analyze(decoded: decoded, options: options)
    }
  } catch {
    return statusRecord(
      status: "failed", reason: "analyze(decoded:) threw: \(error)", runtime: nil, peak: nil,
      identity: combIdentity)
  }
  let observations = seen.items.withLock { $0 }
  guard let result else {
    return statusRecord(
      status: "failed", reason: "analyze(decoded:) found no analyzable audio", runtime: nil,
      peak: nil, identity: combIdentity)
  }
  // `analyze(decoded:)` has no URL, so file-tag corroboration and the duration hint
  // are inert and its BPM can differ from the default pass's for reasons unrelated
  // to the observer. The BPM check is therefore against the same call without the
  // observer bound, on the same decode; the grid does not depend on the URL and is
  // checked against the default pass itself.
  let control: CombinedAnalysisResult?
  do {
    control = try AudioAnalysisService.analyze(decoded: decoded, options: options)
  } catch {
    return statusRecord(
      status: "failed", reason: "unobserved analyze(decoded:) threw: \(error)", runtime: nil,
      peak: nil, identity: combIdentity)
  }
  if result.bpm.bpm.bitPattern != control?.bpm.bpm.bitPattern {
    return statusRecord(
      status: "failed", reason: "observed run's BPM differs from the same run unobserved",
      runtime: nil, peak: nil, identity: combIdentity,
      extra: ["observedBPM": finite(result.bpm.bpm)])
  }
  // The combined path stamps each grid's tempo agreement against that call's own
  // BPM, which differs between the URL and decoded paths for the reason above; the
  // grid is compared with that one stamp neutralized.
  func unstamped(_ grid: BeatGrid?) -> BeatGrid? { grid?.with(tempoAgreement: .notCompared) }
  if unstamped(result.beatGrid) != unstamped(defaultGrid) {
    return statusRecord(
      status: "failed", reason: "observed run's grid differs from the default pass",
      runtime: nil, peak: nil, identity: combIdentity)
  }
  guard let grid = result.beatGrid else {
    return statusRecord(
      status: "abstained", reason: "no-default-grid", runtime: nil, peak: nil,
      identity: combIdentity)
  }
  guard observations.count == 1, let obs = observations.first else {
    return statusRecord(
      status: "failed", reason: "comb observations: \(observations.count), expected 1",
      runtime: nil, peak: nil, identity: combIdentity)
  }
  guard obs.tempoBPM.bitPattern == grid.estimatedTempo.bitPattern else {
    return statusRecord(
      status: "failed", reason: "observed tempo differs from the grid tempo", runtime: nil,
      peak: nil, identity: combIdentity)
  }
  let extra: [String: Any] = [
    "bestBin": obs.bestPhase.bestBin,
    "bins": obs.bestPhase.bins,
    "periodFrames": finite(obs.bestPhase.periodFrames),
    "foldOriginFrame": obs.bestPhase.foldOriginFrame,
    "foldEndFrame": obs.bestPhase.foldEndFrame,
    "combSupport": finite(obs.bestPhase.support),
    "defaultAnchorSeconds": finite(grid.gridOrigin?.presentationTime),
  ]
  return statusRecord(
    status: "ok", tempo: defaultBPM,
    grid: gridRecord(grid, anchorSeconds: obs.phaseSeconds, anchorSource: "comb-best-phase"),
    runtime: nil, peak: nil, identity: combIdentity, extra: extra)
}

func runTrack(_ track: TrackInput) -> [String: Any] {
  let url = URL(fileURLWithPath: track.audioPath)
  let options = AudioAnalysisService.Options()
  var systems: [String: Any] = [:]

  // Pass A: the shipped pipeline at defaults, capturing its decode.
  let box = DecodeBox()
  let observer: @Sendable (FeatureSubstrate.DecodedAudio) -> Void = { box.set($0) }
  var defaultBPM: Double?
  var defaultGrid: BeatGrid?
  var passA: Measured<Void>?
  do {
    let run = try measure {
      try AudioAnalysisService.analyze(url: url, options: options, decodeObserver: observer)
    }
    passA = Measured(value: (), seconds: run.seconds, peakBytes: run.peakBytes)
    if let result = run.value {
      defaultBPM = result.bpm.bpm
      defaultGrid = result.beatGrid
      let grid = result.beatGrid.flatMap { grid in
        grid.gridOrigin.map {
          gridRecord(grid, anchorSeconds: $0.presentationTime, anchorSource: anchorSourceName(grid))
        }
      }
      systems["boomboomboomkit-optimal"] = statusRecord(
        status: "ok", tempo: result.bpm.bpm, grid: grid, runtime: run.seconds,
        peak: run.peakBytes, identity: optimalIdentity,
        extra: [
          "confidence": finite(result.bpm.confidence),
          "gridStatus": result.beatGrid == nil ? "no-grid" : "grid",
        ])
    } else {
      systems["boomboomboomkit-optimal"] = statusRecord(
        status: "abstained", reason: "no-analyzable-audio", runtime: run.seconds,
        peak: run.peakBytes, identity: optimalIdentity)
    }
  } catch {
    systems["boomboomboomkit-optimal"] = statusRecord(
      status: "failed", reason: "analyze threw: \(error)", runtime: nil, peak: nil,
      identity: optimalIdentity)
  }

  // Passes B and C both read pass A's decode; it is released when this scope ends.
  var decoded = box.take()
  if let audio = decoded, let seed = defaultBPM {
    systems["variant-joint-fit"] = jointFitPass(decoded: audio, seed: seed, passA: passA)
    systems["variant-comb-best-phase"] = combPass(
      decoded: audio, options: options, defaultBPM: seed, defaultGrid: defaultGrid)
  } else {
    let reason = decoded == nil ? "no-decode" : "no-default-bpm-seed"
    systems["variant-joint-fit"] = statusRecord(
      status: "abstained", reason: reason, runtime: nil, peak: nil, identity: jointIdentity)
    systems["variant-comb-best-phase"] = statusRecord(
      status: "abstained", reason: reason, runtime: nil, peak: nil, identity: combIdentity)
  }
  decoded = nil

  return [
    "trackId": track.trackId,
    "corpus": track.corpus,
    "audioSha256": track.audioSha256,
    "systems": systems,
  ]
}

// MARK: - Main loop

var records: [[String: Any]] = []
records.reserveCapacity(tracks.count)
let started = Date()
for (i, track) in tracks.enumerated() {
  records.append(autoreleasepool { runTrack(track) })
  if (i + 1) % 25 == 0 || i + 1 == tracks.count {
    let elapsed = Date().timeIntervalSince(started)
    FileHandle.standardError.write(
      Data(String(format: "[run] %d/%d (%.0fs)\n", i + 1, tracks.count, elapsed).utf8))
  }
}

let document: [String: Any] = [
  "schema": runnerSchema,
  "buildConfiguration": buildConfiguration,
  "gitSha": runnerGitSha,
  "dirty": runnerDirty,
  "limit": limit.map { $0 as Any } ?? NSNull(),
  "memorySampling":
    "task_info TASK_VM_INFO phys_footprint, sampled every 1 ms on a second thread while "
    + "each pass runs; value = high-water mark minus the footprint just before the pass",
  "jointFitModelIdentifier": JointTempoPhaseFit.modelIdentifier,
  "trackCount": records.count,
  "tracks": records,
]
do {
  let data = try JSONSerialization.data(
    withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
  let out = URL(fileURLWithPath: outputPath)
  let tmp = out.deletingLastPathComponent().appendingPathComponent(
    ".\(out.lastPathComponent).tmp\(getpid())")
  try data.write(to: tmp)
  guard rename(tmp.path, out.path) == 0 else {
    fail("cannot move \(tmp.path) to \(outputPath): errno \(errno)")
  }
} catch {
  fail("cannot write \(outputPath): \(error)")
}
FileHandle.standardError.write(Data("[run] wrote \(outputPath)\n".utf8))
