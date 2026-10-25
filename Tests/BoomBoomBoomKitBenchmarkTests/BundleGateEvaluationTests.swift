// Story 12.9 develop-only paired producer. All paths and labels come from a
// private input file; no corpus or checkpoint is embedded in the library.

import BoomBoomBoomKit
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomKitML

private struct BundleGateInput: Decodable {
  let cohortSha256: String
  let seed: Int
  let tracks: [BundleGateInputTrack]
}

private struct BundleGateInputTrack: Decodable {
  let trackId: String
  let audioPath: String
  let audioSha256: String
  let groundTruthBPM: Double
  let sourceBand: String
  let verifiedBand: String
  let category: String
}

private struct BundleGateRow: Encodable {
  let trackId: String
  let groundTruthBPM: Double
  let sourceBand: String
  let verifiedBand: String
  let category: String
  let dspBPM: Double?
  let ensembleBPM: Double?
  let modelBPM: Double?
  let softmaxMax: Double?
  let mlFailureStage: String?
  let mlAbstained: Bool
  let dspCandidatesTop3: [Double]
  let dspLatencyMs: Double
  let ensembleLatencyMs: Double
}

private struct BundleGateRunManifest: Encodable {
  let harnessVersion: Int
  let cohortSha256: String
  let inputSha256: String
  let predictionsSha256: String
  let seed: Int
  let checkpointPath: String
  let checkpointSha256: String
  let modelIdentifier: String
  let gitSha: String
  let ensemblePolicy: String
  let expectedTrackCount: Int
  let actualTrackCount: Int
  let unresolvedTracks: [String]
}

@Suite(
  "Story 12.9 bundle gate paired producer",
  .enabled(if: ProcessInfo.processInfo.environment["BUNDLE_GATE_EVAL"] == "1")
)
struct BundleGateEvaluationTests {
  @Test("pairedProductionRuntime")
  func pairedProductionRuntime() throws {
    if #available(macOS 15.0, *) {
      let env = ProcessInfo.processInfo.environment
      guard let inputPath = env["BUNDLE_GATE_INPUT"], !inputPath.isEmpty,
        let modelPath = env["BNNS_MODEL_URL"], !modelPath.isEmpty,
        let outputPath = env["BUNDLE_GATE_OUT_DIR"], !outputPath.isEmpty
      else {
        throw BundleGateHarnessError.missingEnvironment
      }
      let inputData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
      let input = try JSONDecoder().decode(BundleGateInput.self, from: inputData)
      let modelURL = URL(fileURLWithPath: modelPath)
      let technique = try BNNSTechnique(modelURL: modelURL)
      var rows: [BundleGateRow] = []
      var unresolved: [String] = []
      let clock = ContinuousClock()
      var ensembleOptions = AudioAnalysisService.Options()
      ensembleOptions.intensity = .thorough
      ensembleOptions.ensemblePolicy = .default
      ensembleOptions.enableTrace = true
      ensembleOptions.enableMLDiagnostics = true
      ensembleOptions.mlTechnique = technique

      for track in input.tracks {
        let audio = URL(fileURLWithPath: track.audioPath)
        guard let data = try? Data(contentsOf: audio),
          bundleGateSha256(data) == track.audioSha256
        else {
          unresolved.append(track.trackId)
          continue
        }
        var dspOptions = AudioAnalysisService.Options()
        dspOptions.intensity = .thorough
        dspOptions.ensemblePolicy = .dspOnly
        dspOptions.enableTrace = true
        let dspStart = clock.now
        let dspResult: AudioAnalysisResult?
        do {
          dspResult = try AudioAnalysisService.analyzeBPM(url: audio, options: dspOptions)
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          unresolved.append(track.trackId)
          continue
        }
        let dspDuration = clock.now - dspStart

        let ensembleStart = clock.now
        let ensembleResult: AudioAnalysisResult?
        do {
          ensembleResult = try AudioAnalysisService.analyzeBPM(
            url: audio, options: ensembleOptions)
        } catch is CancellationError {
          throw CancellationError()
        } catch {
          unresolved.append(track.trackId)
          continue
        }
        let ensembleDuration = clock.now - ensembleStart
        let snapshot = ensembleResult?.trace?.mlDiagnosticSnapshot
        let candidates =
          dspResult?.trace?.candidatesAfterBoost
          ?? dspResult?.trace?.candidatesBeforeBoost ?? []
        let modelBPM = snapshot?.decodedBPM.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        rows.append(
          BundleGateRow(
            trackId: track.trackId,
            groundTruthBPM: track.groundTruthBPM,
            sourceBand: track.sourceBand,
            verifiedBand: track.verifiedBand,
            category: track.category,
            dspBPM: (dspResult?.bpm).flatMap { $0.isFinite && $0 > 0 ? $0 : nil },
            ensembleBPM: (ensembleResult?.bpm).flatMap { $0.isFinite && $0 > 0 ? $0 : nil },
            modelBPM: modelBPM,
            softmaxMax: snapshot?.softmaxMax.flatMap { $0.isFinite ? $0 : nil },
            mlFailureStage: snapshot?.failureStage?.rawValue,
            mlAbstained: snapshot == nil || snapshot?.failureStage != nil,
            dspCandidatesTop3: candidates.prefix(3).map(\.bpm),
            dspLatencyMs: bundleGateMilliseconds(dspDuration),
            ensembleLatencyMs: bundleGateMilliseconds(ensembleDuration)))
      }
      rows.sort { $0.trackId < $1.trackId }
      let seedDir = URL(fileURLWithPath: outputPath)
        .appendingPathComponent("seed_\(input.seed)")
      try FileManager.default.createDirectory(
        at: seedDir, withIntermediateDirectories: true)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let predictions = try encoder.encode(rows)
      let manifest = BundleGateRunManifest(
        harnessVersion: 1,
        cohortSha256: input.cohortSha256,
        inputSha256: bundleGateSha256(inputData),
        predictionsSha256: bundleGateSha256(predictions),
        seed: input.seed,
        checkpointPath: modelPath,
        checkpointSha256: try bundleGateCheckpointSha256(modelURL),
        modelIdentifier: technique.modelIdentifier,
        gitSha: env["GIT_SHA"] ?? "unknown",
        ensemblePolicy: ensembleOptions.ensemblePolicy.stableKey,
        expectedTrackCount: input.tracks.count,
        actualTrackCount: rows.count,
        unresolvedTracks: unresolved.sorted())
      try predictions.write(to: seedDir.appendingPathComponent("predictions.json"))
      try encoder.encode(manifest).write(to: seedDir.appendingPathComponent("manifest.json"))
      #expect(rows.count + unresolved.count == input.tracks.count)
      #expect(unresolved.isEmpty, "bundle gate input has unresolved audio")
    } else {
      throw BundleGateHarnessError.unsupportedPlatform
    }
  }
}

private enum BundleGateHarnessError: Error {
  case missingEnvironment
  case missingCheckpointBlob
  case unsupportedCheckpointMember
  case unsupportedPlatform
}

private func bundleGateSha256(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

private func bundleGateCheckpointSha256(_ url: URL) throws -> String {
  var isDirectory: ObjCBool = false
  guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
    throw BundleGateHarnessError.missingCheckpointBlob
  }
  if !isDirectory.boolValue {
    return try bundleGateSha256(Data(contentsOf: url))
  }
  guard
    let enumerator = FileManager.default.enumerator(
      at: url, includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey])
  else {
    throw BundleGateHarnessError.missingCheckpointBlob
  }
  var files: [URL] = []
  while let member = enumerator.nextObject() as? URL {
    let values = try member.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
    if values.isDirectory == true { continue }
    guard values.isRegularFile == true else {
      throw BundleGateHarnessError.unsupportedCheckpointMember
    }
    files.append(member)
  }
  guard !files.isEmpty else { throw BundleGateHarnessError.missingCheckpointBlob }
  var hasher = SHA256()
  for file in files.sorted(by: { $0.path < $1.path }) {
    let relative = String(file.path.dropFirst(url.path.count + 1))
    bundleGateHashChunk(Data(relative.utf8), into: &hasher)
    bundleGateHashChunk(try Data(contentsOf: file), into: &hasher)
  }
  return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

private func bundleGateHashChunk(_ data: Data, into hasher: inout SHA256) {
  var length = UInt64(data.count).littleEndian
  withUnsafeBytes(of: &length) { hasher.update(data: Data($0)) }
  hasher.update(data: data)
}

private func bundleGateMilliseconds(_ duration: Duration) -> Double {
  Double(duration.components.seconds) * 1_000
    + Double(duration.components.attoseconds) / 1_000_000_000_000_000
}
