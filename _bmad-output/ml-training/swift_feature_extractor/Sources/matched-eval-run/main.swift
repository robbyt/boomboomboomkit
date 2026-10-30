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
//                              DSPStubObservationProducer -> MetricalLevelSelector
//                              (seeded with the default BPM) -> JointTempoPhaseFit.
//                              Grid from the fit's tempo and phase anchor; a nil at
//                              any step abstains with the step named.
//    variant-comb-best-phase   Story 15.10 follow-up: `analyze(url:)` again with
//                              `BeatGridAnalyzer.combPhaseObserver` bound; the default
//                              grid's tempo re-anchored at the onset-comb best phase.
//                              Its BPM answer is the default BPM, unchanged.
//
//  Runtime and memory per system. Each pass runs alone; the resident size
//  (`task_info` MACH_TASK_BASIC_INFO) is sampled every millisecond on a second
//  thread while the pass runs, and the record holds the high-water mark minus the
//  resident size just before the pass. The joint-fit row needs the default pass
//  for its seed, so its runtime is the default pass plus the fit stage and its
//  memory the larger of the two passes' peaks; the stage alone is recorded too.
//
//  Every audio file is hashed before any analysis; a sha256 that differs from the
//  input refuses the whole run (exit 3, naming the track).
//
//  Build (release needs -enable-testing for the internal Story 15.7 types):
//    swift build -c release -Xswiftc -enable-testing --product matched-eval-run
//  Run:
//    matched-eval-run --input <runner-input.json> --output <runner-output.json>
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

var inputPath: String?
var outputPath: String?
var limit: Int?
do {
  var args = CommandLine.arguments.dropFirst().makeIterator()
  while let arg = args.next() {
    switch arg {
    case "--input": inputPath = args.next()
    case "--output": outputPath = args.next()
    case "--limit": limit = args.next().flatMap { Int($0) }
    default: fail("unknown argument \(arg)", code: 2)
    }
  }
}
guard let inputPath, let outputPath else {
  fail("usage: matched-eval-run --input <in.json> --output <out.json> [--limit N]", code: 2)
}

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

nonisolated(unsafe) let taskPort = mach_task_self_

func residentBytes() -> UInt64 {
  var info = mach_task_basic_info()
  var count = mach_msg_type_number_t(
    MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
  let kr = withUnsafeMutablePointer(to: &info) { ptr in
    ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
      task_info(taskPort, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
    }
  }
  return kr == KERN_SUCCESS ? info.resident_size : 0
}

/// Samples the resident size every millisecond on its own thread between
/// `init` and `finish()`.
final class MemorySampler: Sendable {
  let baseline: UInt64
  private let peak: Atomic<UInt64>
  private let stopFlag = Atomic<Bool>(false)
  private let finished = DispatchSemaphore(value: 0)

  init() {
    let base = residentBytes()
    baseline = base
    peak = Atomic<UInt64>(base)
    let thread = Thread { [self] in
      while !self.stopFlag.load(ordering: .relaxed) {
        self.record(residentBytes())
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
    record(residentBytes())
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
  runtime: Double, peak: UInt64, identity: String, extra: [String: Any] = [:]
) -> [String: Any] {
  var record: [String: Any] = [
    "status": status,
    "reason": reason.map { $0 as Any } ?? NSNull(),
    "tempoBPM": finite(tempo),
    "grid": grid.map { $0 as Any } ?? NSNull(),
    "runtimeSeconds": runtime,
    "peakMemoryAboveBaselineBytes": peak,
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
  "DSPStubObservationProducer(hopSize: sampleRate/100) -> MetricalLevelSelector.select("
  + "seed = default BPM) -> JointTempoPhaseFit.fit [\(JointTempoPhaseFit.modelIdentifier)] "
  + "on the default pass's decode; grid = fit tempo extrapolated from phaseAnchorSeconds"
let combIdentity =
  "default grid (estimatedTempo) re-anchored at the onset-comb best phase "
  + "(BeatGridAnalyzer.combPhaseObserver, fold at the grid period over the tracked beats); "
  + "BPM answer = default BPM"

// MARK: - Per-track passes

func anchorSourceName(_ grid: BeatGrid) -> String {
  guard let origin = grid.gridOrigin else { return "none" }
  return String(describing: origin.source)
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
  var passARuntime = 0.0
  var passAPeak: UInt64 = 0
  do {
    let run = try measure {
      try AudioAnalysisService.analyze(url: url, options: options, decodeObserver: observer)
    }
    passARuntime = run.seconds
    passAPeak = run.peakBytes
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
      status: "failed", reason: "analyze threw: \(error)", runtime: 0, peak: 0,
      identity: optimalIdentity)
  }

  // Pass B: the joint fit on the same decode, seeded with the default BPM.
  let decoded = box.take()
  if let decoded, let seed = defaultBPM {
    enum JointOutcome {
      case fit(FittedTempoPhase)
      case abstain(String)
    }
    let run = measure { () -> JointOutcome in
      let hop = Int(decoded.sampleRate / 100)
      guard hop > 0 else { return .abstain("sample-rate-below-100-hz") }
      guard let observations = DSPStubObservationProducer(hopSize: hop).produce(decoded: decoded)
      else { return .abstain("observation-producer-returned-nil") }
      guard let selection = MetricalLevelSelector.select(observations: observations, tempoBPM: seed)
      else { return .abstain("metrical-level-selector-returned-nil") }
      guard let fit = JointTempoPhaseFit.fit(observations: observations, selection: selection)
      else { return .abstain("joint-fit-returned-nil") }
      return .fit(fit)
    }
    let runtime = passARuntime + run.seconds
    let peak = max(passAPeak, run.peakBytes)
    let stage: [String: Any] = [
      "stageRuntimeSeconds": run.seconds, "stagePeakMemoryAboveBaselineBytes": run.peakBytes,
      "seedBPM": seed,
    ]
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
      var extra = stage
      extra["metricalLevel"] = fit.metricalLevel.rawValue
      extra["keptFraction"] = finite(fit.keptFraction)
      extra["supportScore"] = finite(Double(fit.supportScore))
      extra["decoderIdentifier"] = fit.decoderIdentifier
      extra["observationModelIdentifier"] = fit.observationModelIdentifier
      extra["frontendIdentifier"] = fit.frontendIdentifier
      systems["variant-joint-fit"] = statusRecord(
        status: "ok", tempo: fit.tempoBPM, grid: grid, runtime: runtime, peak: peak,
        identity: jointIdentity, extra: extra)
    case .abstain(let reason):
      systems["variant-joint-fit"] = statusRecord(
        status: "abstained", reason: reason, runtime: runtime, peak: peak,
        identity: jointIdentity, extra: stage)
    }
  } else {
    systems["variant-joint-fit"] = statusRecord(
      status: "abstained", reason: decoded == nil ? "no-decode" : "no-default-bpm-seed",
      runtime: passARuntime, peak: passAPeak, identity: jointIdentity)
  }

  // Pass C: the default pipeline again with the comb best-phase observer bound.
  let seen = ObservationBox()
  let combObserver: @Sendable (BeatGridAnalyzer.CombPhaseObservation) -> Void = { obs in
    seen.items.withLock { $0.append(obs) }
  }
  do {
    let run = try measure {
      try BeatGridAnalyzer.$combPhaseObserver.withValue(combObserver) {
        try AudioAnalysisService.analyze(url: url, options: options)
      }
    }
    let observations = seen.items.withLock { $0 }
    let sameAsDefault =
      run.value?.bpm.bpm.bitPattern == defaultBPM?.bitPattern && run.value?.beatGrid == defaultGrid
    var extra: [String: Any] = ["outputIdenticalToDefaultPass": sameAsDefault]
    if let result = run.value, let grid = result.beatGrid, observations.count == 1,
      let obs = observations.first
    {
      extra["bestBin"] = obs.bestPhase.bestBin
      extra["bins"] = obs.bestPhase.bins
      extra["periodFrames"] = finite(obs.bestPhase.periodFrames)
      extra["foldOriginFrame"] = obs.bestPhase.foldOriginFrame
      extra["foldEndFrame"] = obs.bestPhase.foldEndFrame
      extra["combSupport"] = finite(obs.bestPhase.support)
      extra["defaultAnchorSeconds"] = finite(grid.gridOrigin?.presentationTime)
      systems["variant-comb-best-phase"] = statusRecord(
        status: "ok", tempo: result.bpm.bpm,
        grid: gridRecord(grid, anchorSeconds: obs.phaseSeconds, anchorSource: "comb-best-phase"),
        runtime: run.seconds, peak: run.peakBytes, identity: combIdentity, extra: extra)
    } else {
      let reason: String
      if run.value == nil {
        reason = "no-analyzable-audio"
      } else if run.value?.beatGrid == nil {
        reason = "no-default-grid"
      } else {
        reason = "comb-observations-\(observations.count)"
      }
      systems["variant-comb-best-phase"] = statusRecord(
        status: "abstained", reason: reason, runtime: run.seconds, peak: run.peakBytes,
        identity: combIdentity, extra: extra)
    }
  } catch {
    systems["variant-comb-best-phase"] = statusRecord(
      status: "failed", reason: "analyze threw: \(error)", runtime: 0, peak: 0,
      identity: combIdentity)
  }

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
  "memorySampling":
    "task_info MACH_TASK_BASIC_INFO resident_size, sampled every 1 ms on a second thread "
    + "while each pass runs; value = high-water mark minus the resident size just before "
    + "the pass",
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
