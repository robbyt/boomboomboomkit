//
//  FR18EvaluationHarnessTests.swift
//  BoomBoomBoomKitBenchmarkTests
//
//  Story 7-6 — FR-18 promotion-gate evaluation: the runtime-path PRODUCER.
//
//  This benchmark test routes audio through the PRODUCTION runtime path
//  (`BNNSTechnique(modelURL:)` → `AudioAnalysisService.analyzeBPM` with
//  `ensemblePolicy = .mlOnly`) and dumps per-track model predictions as JSON.
//  A develop-only Python orchestrator (`evaluate_fr18.py`) consumes the dump
//  and computes the 5 FR-18 gates + the KDD-B5 bundle-vs-BYOW decision.
//
//  Design (Story 7-6 DD #2 / DD #13, pre-dev review round 2):
//   - The model under evaluation MUST be invoked through the runtime path, NOT
//     a Python torch/coremltools call, so the gates measure what `main` ships.
//   - This test is corpus-AGNOSTIC: it reads an input manifest (path via
//     `FR18_EVAL_INPUT`) listing the audio files to evaluate, produced
//     Python-side. ALL corpus / sentinel / Tony-audio resolution stays develop
//     -only. The model path comes only from `BNNS_MODEL_URL`; no develop-only
//     artifact path, model filename, or holdout reference is hardcoded here
//     (grep-guarded at Story 7-6 close so nothing develop-only leaks onto main).
//   - Gates bind to the MODEL prediction `decodedBPM` (Story 7-6 DD #12): under
//     `.mlOnly`, an abstaining model makes `result.bpm` fall through to DSP, so
//     the dump separates `fr18ModelBPM` (= decodedBPM, what gates read) from
//     `runtimeResultBPM` (= result.bpm, debug only).
//   - DSP candidate top-3 (for the ECE half/double subset, DD #8) is read from
//     `trace.candidatesAfterBoost` — populated during DSP analysis BEFORE the
//     `.mlOnly` ensemble reconciliation, so it survives.
//
//  Env-gated (`FR18_EVAL=1`); deliberately NOT run by the unit-test `make test`.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomKitML

// MARK: - Wire formats

/// Input manifest produced Python-side (`evaluate_fr18.py`). Lists the audio
/// files for ONE seed's evaluation pass. The harness is told which model to
/// load via `BNNS_MODEL_URL`; the `seed` here is recorded into the output
/// manifest for the aggregator's seed-isolation check.
private struct FR18EvalInput: Decodable {
  let seed: Int
  let tracks: [FR18InputTrack]
}

private struct FR18InputTrack: Decodable {
  let trackId: String
  let audioPath: String
  let groundTruthBPM: Double
  let corpus: String  // "oa300" | "giantsteps" | "sentinel"
}

/// Per-track model prediction row. The field separation is load-bearing
/// (Story 7-6 DD #12): `fr18ModelBPM` is the ONLY field the FR-18 gates read.
private struct FR18TrackRow: Codable, Sendable {
  let trackId: String
  let corpus: String
  let groundTruthBPM: Double
  /// = `MLDiagnosticSnapshot.decodedBPM`. Nil when the model abstained before
  /// decode (no usable model prediction). The ONLY field the gates consume.
  let fr18ModelBPM: Double?
  let softmaxMax: Double?
  /// True when there is no usable model prediction (`fr18ModelBPM == nil`).
  /// Counts as model-INCORRECT for accuracy gates (DD #12).
  let mlAbstained: Bool
  /// = `result.bpm`. DSP-contaminated on abstain under `.mlOnly`. DEBUG ONLY —
  /// must NOT feed any gate.
  let runtimeResultBPM: Double?
  /// `.dsp` / `.ml` / `.tie` (nil when no ensemble decision was recorded).
  let ensembleWinner: String?
  /// Up to 3 DSP candidate BPMs (for the ECE half/double subset, DD #8).
  let dspCandidatesTop3: [Double]
  /// The exact trace field the candidates were read from.
  let candidateSource: String
  let failureStage: String?
  let latencyMs: Double
}

/// Per-seed run manifest (Story 7-6 DD #13). The aggregator validates
/// `actualTrackCount == expectedTrackCount` from THIS file, never from the
/// `swift test` exit code, and rejects two dirs that resolve to the same seed.
private struct FR18Manifest: Codable, Sendable {
  let harnessVersion: Int
  let seed: Int
  let checkpointPath: String
  let checkpointSha256: String
  let gitSha: String
  let expectedTrackCount: Int
  let actualTrackCount: Int
  let unresolvedTracks: [String]
  let modelIdentifier: String
}

// MARK: - Suite

@Suite(
  "Story 7-6 FR18 Evaluation Harness",
  .enabled(if: ProcessInfo.processInfo.environment["FR18_EVAL"] == "1")
)
struct FR18EvaluationHarnessTests {

  /// Always-on (non-corpus) build + runtime-path assertion. Runs whenever the
  /// suite is enabled, even without a model/corpus, so the benchmark target's
  /// build is verified and `AudioAnalysisService.analyzeBPM` stays callable on a
  /// synthetic click track.
  ///
  /// NOTE: no model ships, so this self-test runs `.dspOnly` and asserts only the
  /// DSP runtime executes (finite `result.bpm`). It deliberately does NOT assert
  /// `decodedBPM` — the ML/model-prediction surface requires a real checkpoint and
  /// is covered by the corpus-gated `fr18RuntimeEvaluation` test (under a model)
  /// and the operator's v1/v2 run (DD #11). Do not read this as an ML-path check.
  @Test("runtimePathIsCallable (FR18_EVAL=1)")
  func runtimePathIsCallable() async throws {
    if #available(macOS 15.0, *) {
      // Synthetic click track — no corpus needed.
      let samples = generateClickTrack(
        bpm: 174.0, sampleRate: 44_100, durationSeconds: 12.0)
      let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("fr18-selftest-\(UUID().uuidString).wav")
      defer { try? FileManager.default.removeItem(at: tmp) }
      try writeWAV(samples: samples, sampleRate: 44_100, to: tmp)

      // No model wired: the runtime still runs DSP and produces a result; the
      // ML path is exercised only when a model is present. This assertion is
      // about the API surface + DSP runtime, not model accuracy.
      var opts = AudioAnalysisService.Options()
      opts.intensity = .thorough
      opts.ensemblePolicy = .dspOnly  // self-test has no model; gate-free.
      opts.enableTrace = true
      let result = try AudioAnalysisService.analyzeBPM(url: tmp, options: opts)
      #expect(result != nil, "runtime produced no result on a 174 BPM click track")
      if let bpm = result?.bpm {
        #expect(bpm.isFinite && bpm > 0, "non-finite DSP BPM \(bpm)")
      }
    }
  }

  @Test(
    "fr18RuntimeEvaluation (FR18_EVAL=1, requires FR18_EVAL_INPUT + BNNS_MODEL_URL)",
    .disabled(
      if: {
        // Skip cleanly unless both the input manifest and a model are provided.
        let input = ProcessInfo.processInfo.environment["FR18_EVAL_INPUT"]
          .flatMap { $0.isEmpty ? nil : $0 }
        let model = ProcessInfo.processInfo.environment["BNNS_MODEL_URL"]
          .flatMap { $0.isEmpty ? nil : $0 }
        return input == nil || model == nil
      }())
  )
  func fr18RuntimeEvaluation() async throws {
    if #available(macOS 15.0, *) {
      let env = ProcessInfo.processInfo.environment
      guard let inputPath = env["FR18_EVAL_INPUT"], !inputPath.isEmpty else {
        throw FR18HarnessError.inputManifestNotSet
      }
      guard let modelPathStr = env["BNNS_MODEL_URL"], !modelPathStr.isEmpty else {
        throw FR18HarnessError.modelURLNotSet
      }
      let outDir =
        (env["FR18_EVAL_OUT_DIR"].flatMap { $0.isEmpty ? nil : $0 })
        ?? NSTemporaryDirectory()

      let input = try JSONDecoder().decode(
        FR18EvalInput.self, from: Data(contentsOf: URL(fileURLWithPath: inputPath)))
      let modelURL = URL(fileURLWithPath: modelPathStr)

      // Compile the graph ONCE per run (not per track).
      let technique: BNNSTechnique
      do {
        technique = try BNNSTechnique(modelURL: modelURL)
      } catch {
        Issue.record(
          Comment(
            rawValue:
              "BNNSTechnique(modelURL:) failed for \(modelPathStr): "
              + error.localizedDescription))
        return
      }

      let clock = ContinuousClock()
      var rows: [FR18TrackRow] = []
      rows.reserveCapacity(input.tracks.count)
      var unresolved: [String] = []

      for track in input.tracks {
        let url = URL(fileURLWithPath: track.audioPath)
        guard FileManager.default.fileExists(atPath: track.audioPath) else {
          unresolved.append(track.trackId)
          continue
        }

        var opts = AudioAnalysisService.Options()
        opts.intensity = .thorough  // intensity 8 (ML is activated by .mlOnly, not intensity)
        opts.ensemblePolicy = .mlOnly
        opts.enableTrace = true  // candidatesAfterBoost + ensembleDecision
        opts.enableMLDiagnostics = true  // mlDiagnosticSnapshot (decodedBPM/softmaxMax)
        opts.mlTechnique = technique

        let start = clock.now
        let result: AudioAnalysisResult?
        do {
          result = try AudioAnalysisService.analyzeBPM(url: url, options: opts)
        } catch is CancellationError {
          throw CancellationError()
        } catch let error as PCMBufferReaderError {
          Issue.record(
            Comment(rawValue: "skipped \(track.trackId): \(error)"))
          unresolved.append(track.trackId)
          continue
        }
        let elapsed = clock.now - start
        let latencyMs =
          Double(elapsed.components.seconds) * 1.0e3
          + Double(elapsed.components.attoseconds) / 1.0e15

        let trace = result?.trace
        let snapshot = trace?.mlDiagnosticSnapshot
        // fr18ModelBPM = the model's decoded prediction (present even when the
        // confidence gate would have rejected it — FR-18 measures the model,
        // not the gated ensemble). Nil only on pre-decode abstains. Non-finite /
        // non-positive decodes are normalized to nil (= abstain): Swift's
        // JSONEncoder rejects NaN/Inf, and a NaN must count as abstain, not as a
        // prediction (Codex diff-review). Same for softmaxMax.
        let modelBPM: Double? = snapshot?.decodedBPM.flatMap {
          $0.isFinite && $0 > 0 ? $0 : nil
        }
        let softmaxMaxFinite: Double? = snapshot?.softmaxMax.flatMap { $0.isFinite ? $0 : nil }
        // DSP candidates survive `.mlOnly` (built pre-ensemble). Prefer the
        // post-corroboration pool; fall back to pre-boost, then the winner.
        let candidatePool: [(bpm: Double, score: Float)]
        let candidateSource: String
        if let after = trace?.candidatesAfterBoost, !after.isEmpty {
          candidatePool = after
          candidateSource = "candidatesAfterBoost"
        } else if let before = trace?.candidatesBeforeBoost, !before.isEmpty {
          candidatePool = before
          candidateSource = "candidatesBeforeBoost"
        } else {
          candidatePool = []
          candidateSource = "none"
        }
        let top3 = candidatePool.prefix(3).map { $0.bpm }

        rows.append(
          FR18TrackRow(
            trackId: track.trackId,
            corpus: track.corpus,
            groundTruthBPM: track.groundTruthBPM,
            fr18ModelBPM: modelBPM,
            softmaxMax: softmaxMaxFinite,
            mlAbstained: modelBPM == nil,
            runtimeResultBPM: (result?.bpm).flatMap { $0.isFinite ? $0 : nil },
            ensembleWinner: trace?.ensembleDecision?.winner.rawValue,
            dspCandidatesTop3: Array(top3),
            candidateSource: candidateSource,
            failureStage: snapshot?.failureStage?.rawValue,
            latencyMs: latencyMs))
      }

      rows.sort { $0.trackId < $1.trackId }

      // Seed-namespaced output dir (Story 7-6 DD #13).
      let seedDir = (outDir as NSString).appendingPathComponent("seed_\(input.seed)")
      try FileManager.default.createDirectory(
        atPath: seedDir, withIntermediateDirectories: true)

      let manifest = FR18Manifest(
        harnessVersion: 1,
        seed: input.seed,
        checkpointPath: modelPathStr,
        checkpointSha256: sha256OfFile(at: modelURL) ?? "unavailable",
        gitSha: env["GIT_SHA"] ?? "unknown",
        expectedTrackCount: input.tracks.count,
        actualTrackCount: rows.count,
        unresolvedTracks: unresolved.sorted(),
        modelIdentifier: technique.modelIdentifier)

      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      try encoder.encode(rows).write(
        to: URL(fileURLWithPath: (seedDir as NSString).appendingPathComponent("predictions.json")))
      try encoder.encode(manifest).write(
        to: URL(fileURLWithPath: (seedDir as NSString).appendingPathComponent("manifest.json")))

      print(
        """

        === FR-18 Evaluation Harness (Story 7-6) ===
        Seed: \(input.seed)  Model: \(technique.modelIdentifier)
        Tracks: \(rows.count)/\(input.tracks.count) (unresolved: \(unresolved.count))
        Abstain rate: \(rows.filter { $0.mlAbstained }.count)/\(rows.count)
        Output: \(seedDir)
        """)

      // The harness asserts the runtime path produced output; the gate
      // computation + pass/fail decision is the Python orchestrator's job.
      #expect(
        rows.count + unresolved.count == input.tracks.count,
        "conservation: rows=\(rows.count) + unresolved=\(unresolved.count) != input=\(input.tracks.count)"
      )
    }
  }
}

// MARK: - Helpers

private enum FR18HarnessError: Error {
  case inputManifestNotSet
  case modelURLNotSet
}

/// Stable SHA-256 identity for the manifest's seed-isolation check (did the
/// operator point two seed dirs at the same checkpoint?). This is a
/// WEIGHTS/BLOB identity, NOT a full-bundle digest: for a `.mlmodelc` directory
/// it hashes `coremldata.bin` (the weights+architecture blob — distinct seeds
/// have distinct weights, so it discriminates the real "same checkpoint" case),
/// and for a plain file it hashes the file bytes. The path-string fallback is
/// reachable only for a malformed bundle lacking `coremldata.bin` (a real
/// `.mlmodelc` always contains it).
private func sha256OfFile(at url: URL) -> String? {
  var isDir: ObjCBool = false
  guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
    return nil
  }

  let targetURL: URL
  if isDir.boolValue {
    let candidate = url.appendingPathComponent("coremldata.bin")
    if FileManager.default.fileExists(atPath: candidate.path) {
      targetURL = candidate
    } else {
      let digest = SHA256.hash(data: Data(url.path.utf8))
      return digest.map { String(format: "%02x", $0) }.joined()
    }
  } else {
    targetURL = url
  }

  guard let data = try? Data(contentsOf: targetURL) else { return nil }
  let digest = SHA256.hash(data: data)
  return digest.map { String(format: "%02x", $0) }.joined()
}

/// Minimal 16-bit PCM WAV writer for the self-test click track.
private func writeWAV(samples: [Float], sampleRate: Int, to url: URL) throws {
  var data = Data()
  let numSamples = samples.count
  let byteRate = sampleRate * 2
  let dataSize = numSamples * 2

  func appendLE32(_ v: UInt32) {
    withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) }
  }
  func appendLE16(_ v: UInt16) {
    withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) }
  }

  data.append(contentsOf: Array("RIFF".utf8))
  appendLE32(UInt32(36 + dataSize))
  data.append(contentsOf: Array("WAVE".utf8))
  data.append(contentsOf: Array("fmt ".utf8))
  appendLE32(16)
  appendLE16(1)  // PCM
  appendLE16(1)  // mono
  appendLE32(UInt32(sampleRate))
  appendLE32(UInt32(byteRate))
  appendLE16(2)  // block align
  appendLE16(16)  // bits per sample
  data.append(contentsOf: Array("data".utf8))
  appendLE32(UInt32(dataSize))
  for sample in samples {
    let normalized = sample.isFinite ? sample : 0.0
    let clamped = max(-1.0, min(1.0, normalized))
    appendLE16(UInt16(bitPattern: Int16(clamped * 32_767.0)))
  }
  try data.write(to: url)
}
