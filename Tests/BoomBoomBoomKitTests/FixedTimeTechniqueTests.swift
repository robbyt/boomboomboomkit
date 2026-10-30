//
//  FixedTimeTechniqueTests.swift
//  BoomBoomBoomKitTests
//
//  The whole-track ML seam (`WholeTrackMLTechnique`) and the fixed-time
//  technique: service wiring with a stub, `.dspOnly` byte identity, and the
//  tensor contract in both directions using the committed
//  `Fixtures/FixedTimeTiny.mlmodelc` (seeded, untrained, 1200 wide; built by
//  `_bmad-output/ml-training/scripts/build-fixed-time-fixture.py`).
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

private func fixtureModel(_ name: String) -> URL? {
  guard let resourceURL = Bundle.module.resourceURL else { return nil }
  let url = resourceURL.appendingPathComponent("Fixtures").appendingPathComponent(name)
  return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

private func fixturesMissing() -> Bool {
  fixtureModel("FixedTimeTiny.mlmodelc") == nil || fixtureModel("CustomBundled.mlmodelc") == nil
}

private func decoded(_ samples: [Float], rate: Double = 44_100) -> FeatureSubstrate.DecodedAudio {
  FeatureSubstrate.DecodedAudio(
    samples: samples, sampleRate: rate,
    codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone))
}

private func clickTrack(seconds: Double) -> FeatureSubstrate.DecodedAudio {
  decoded(generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: seconds))
}

/// Writes a 120 BPM click track of `seconds` to a temporary float WAV.
private func clickTrackWAV(seconds: Double) throws -> URL {
  let samples = generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: seconds)
  let format = try #require(
    AVAudioFormat(
      commonFormat: .pcmFormatFloat32, sampleRate: 44_100, channels: 1, interleaved: false))
  let buffer = try #require(
    AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)))
  buffer.frameLength = AVAudioFrameCount(samples.count)
  let channel = try #require(buffer.floatChannelData?[0])
  samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("whole-track-\(UUID().uuidString).wav")
  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  try file.write(from: buffer)
  return url
}

/// Records each call and returns a fixed result.
private final class StubWholeTrackTechnique: WholeTrackMLTechnique, @unchecked Sendable {
  private let lock = NSLock()
  private let evaluation: MLEvaluation?

  init(evaluation: MLEvaluation? = MLEvaluation(bpm: 97, confidence: 0.9, modelIdentifier: "stub"))
  {
    self.evaluation = evaluation
  }

  private var _calls: [Int] = []
  private var _plainCalls = 0
  let crops = MLInputCropEvidence(
    candidates: [
      MLInputCrop(startFrame: 0, startSeconds: 0, durationSeconds: 12.04, rhythmScore: 0.5)
    ],
    keptCrops: [
      MLInputCrop(startFrame: 0, startSeconds: 0, durationSeconds: 12.04, rhythmScore: 0.5)
    ],
    abstainReason: nil)
  let snapshot = MLDiagnosticSnapshot(
    inputFeatureChecksum: 42,
    outcome: .win(.init(bpm: 97, softmaxMax: 0.9, softmaxSecondMax: 0.05)))

  /// Sample counts of the audio each whole-track call received.
  var audioSampleCounts: [Int] { lock.withLock { _calls } }
  var plainCalls: Int { lock.withLock { _plainCalls } }

  func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    lock.withLock { _plainCalls += 1 }
    return nil
  }

  func evaluate(
    trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio
  ) -> (
    evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
  ) {
    lock.withLock { _calls.append(audio.samples.count) }
    return (evaluation, crops, snapshot)
  }
}

@Suite("Whole-track ML seam")
struct WholeTrackMLSeamTests {

  @Test("the service passes the decoded track and the evaluation votes")
  func wiring() throws {
    let stub = StubWholeTrackTechnique()
    var options = AudioAnalysisService.Options()
    options.mlTechnique = stub
    options.ensemblePolicy = .mlOnly
    options.enableTrace = true
    options.enableMLDiagnostics = true
    let audio = clickTrack(seconds: 30)
    let result = try #require(try AudioAnalysisService.analyzeBPM(decoded: audio, options: options))
    #expect(stub.audioSampleCounts == [audio.samples.count])
    #expect(stub.plainCalls == 0)
    #expect(result.bpm == 97)
    let crops = try #require(result.trace?.mlInputCrops)
    #expect(crops.keptCrops == stub.crops.keptCrops)
    #expect(result.trace?.mlDiagnosticSnapshot == stub.snapshot)
  }

  @Test("the technique gets the full decode while DSP reads the maxSeconds prefix")
  func uncappedAudio() throws {
    let stub = StubWholeTrackTechnique()
    var options = AudioAnalysisService.Options()
    options.mlTechnique = stub
    options.ensemblePolicy = .mlOnly
    options.maxSeconds = 15
    let audio = clickTrack(seconds: 30)
    _ = try AudioAnalysisService.analyzeBPM(decoded: audio, options: options)
    _ = try AudioAnalysisService.analyze(decoded: audio, options: options)
    #expect(stub.audioSampleCounts == [audio.samples.count, audio.samples.count])
  }

  @Test("analyzeBPM(url:) hands the technique the whole file and DSP the maxSeconds prefix")
  func urlPathWholeFile() throws {
    let url = try clickTrackWAV(seconds: 30)
    defer { try? FileManager.default.removeItem(at: url) }
    let fullCount = try PCMBufferReader.readDecodedAudio(from: url).samples.count
    // The stub abstains, so `.mlOnly` falls through to the DSP result.
    let stub = StubWholeTrackTechnique(evaluation: nil)
    var withStub = AudioAnalysisService.Options()
    withStub.maxSeconds = 15
    withStub.mlTechnique = stub
    withStub.ensemblePolicy = .mlOnly
    var plain = AudioAnalysisService.Options()
    plain.maxSeconds = 15
    let a = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: withStub))
    let b = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: plain))
    #expect(stub.audioSampleCounts == [fullCount])
    #expect(a.bpm.bitPattern == b.bpm.bitPattern)
    #expect(a.confidence.bitPattern == b.confidence.bitPattern)
    #expect(a.candidates.map(\.bpm) == b.candidates.map(\.bpm))
    #expect(a.candidates.map(\.score) == b.candidates.map(\.score))
  }

  @Test("analyzeFull hands the technique the whole file; BPM, grid and loudness keep their caps")
  func analyzeFullWholeFile() throws {
    let url = try clickTrackWAV(seconds: 30)
    defer { try? FileManager.default.removeItem(at: url) }
    let fullCount = try PCMBufferReader.readDecodedAudio(from: url).samples.count
    let stub = StubWholeTrackTechnique(evaluation: nil)
    var withStub = AudioAnalysisService.Options()
    withStub.maxSeconds = 15
    withStub.mlTechnique = stub
    withStub.ensemblePolicy = .mlOnly
    var plain = AudioAnalysisService.Options()
    plain.maxSeconds = 15
    var lufs = LUFSOptions()
    lufs.maxSeconds = 15
    let a = try AudioAnalysisService.analyzeFull(url: url, options: withStub, lufsOptions: lufs)
    let b = try AudioAnalysisService.analyzeFull(url: url, options: plain, lufsOptions: lufs)
    #expect(stub.audioSampleCounts == [fullCount])
    let bpmA = try #require(a.bpmAndBeatGrid?.bpm)
    let bpmB = try #require(b.bpmAndBeatGrid?.bpm)
    #expect(bpmA.bpm.bitPattern == bpmB.bpm.bitPattern)
    #expect(bpmA.confidence.bitPattern == bpmB.confidence.bitPattern)
    #expect(bpmA.candidates.map(\.bpm) == bpmB.candidates.map(\.bpm))
    #expect(
      a.bpmAndBeatGrid?.beatGrid?.beats.map(\.presentationTime)
        == b.bpmAndBeatGrid?.beatGrid?.beats.map(\.presentationTime))
    // Loudness keeps its 15 s cap, applied to the whole decode with `applyCap`.
    // It is compared with the decoded-path measurement of the same prefix, not
    // with `b`: AVAudioFile's capped read returns fewer frames than the cap
    // (660,480 of 661,500 here), so the two prefixes differ by one 100 ms block.
    var lufsDecoded = LUFSOptions()
    lufsDecoded.maxSeconds = 15
    let expectedLoudness = try AudioAnalysisService.analyzeLUFS(
      decoded: PCMBufferReader.readDecodedAudio(from: url), options: lufsDecoded)
    #expect(try a.loudness.get() == expectedLoudness)
  }

  @Test("without enableMLDiagnostics the vote counts but no crops are written")
  func diagnosticsGate() throws {
    let stub = StubWholeTrackTechnique()
    var options = AudioAnalysisService.Options()
    options.mlTechnique = stub
    options.ensemblePolicy = .mlOnly
    options.enableTrace = true
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: clickTrack(seconds: 30), options: options))
    #expect(result.bpm == 97)
    #expect(result.trace?.mlInputCrops == nil)
    #expect(result.trace?.mlDiagnosticSnapshot == nil)
  }

  @Test(".dspOnly never calls a whole-track technique")
  func dspOnlyNoCall() throws {
    let stub = StubWholeTrackTechnique()
    var options = AudioAnalysisService.Options()
    options.mlTechnique = stub
    options.enableTrace = true
    options.enableMLDiagnostics = true
    _ = try AudioAnalysisService.analyzeBPM(decoded: clickTrack(seconds: 30), options: options)
    #expect(stub.audioSampleCounts.isEmpty)
    #expect(stub.plainCalls == 0)
  }
}

@Suite("FixedTimeTechnique")
struct FixedTimeTechniqueTests {

  @Test(
    "a 512-wide model is rejected with invalidTensorContract",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func rejects512() throws {
    let url = try #require(fixtureModel("CustomBundled.mlmodelc"))
    #expect {
      _ = try FixedTimeTechnique(modelURL: url)
    } throws: { error in
      guard case MLTechniqueError.invalidTensorContract = error else { return false }
      return true
    }
  }

  @Test(
    "BNNSTechnique rejects the 1200-wide model with invalidTensorContract",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func bnnsRejects1200() throws {
    let url = try #require(fixtureModel("FixedTimeTiny.mlmodelc"))
    #expect {
      _ = try BNNSTechnique(modelURL: url)
    } throws: { error in
      guard case MLTechniqueError.invalidTensorContract = error else { return false }
      return true
    }
  }

  @Test(
    "a missing file throws modelResourceMissing",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func missingFile() {
    #expect {
      _ = try FixedTimeTechnique(modelURL: URL(fileURLWithPath: "/nonexistent/model.mlmodelc"))
    } throws: { error in
      guard case MLTechniqueError.modelResourceMissing = error else { return false }
      return true
    }
  }

  @Test(
    "evaluates a click track: 1-4 kept crops, mean-of-softmax decode, win snapshot",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func happyPath() throws {
    let technique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    #expect(technique.modelIdentifier == "FixedTimeTiny")
    let audio = clickTrack(seconds: 40)
    let out = technique.evaluate(trace: BPMDiagnosticTrace(), audio: audio)
    let evaluation = try #require(out.evaluation)
    let crops = try #require(out.crops)
    #expect(crops.abstainReason == nil)
    #expect((1...4).contains(crops.keptCrops.count))
    #expect(crops.candidates.count == 6)
    #expect((30...285).contains(evaluation.bpm))
    #expect((0...1).contains(evaluation.confidence))
    let snapshot = try #require(out.snapshot)
    #expect(snapshot.failureStage == nil)
    #expect(snapshot.decodedBPM == evaluation.bpm)
    // Without audio the technique abstains.
    #expect(technique.evaluate(trace: BPMDiagnosticTrace()) == nil)
    #expect(technique.evaluateWithDiagnostic(trace: BPMDiagnosticTrace()).snapshot == nil)
  }

  @Test(
    "abstains shorter-than-crop and no-rhythmic-crop",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func abstains() throws {
    let technique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    let short = technique.evaluate(trace: BPMDiagnosticTrace(), audio: clickTrack(seconds: 10))
    #expect(short.evaluation == nil)
    #expect(short.crops?.abstainReason == .shorterThanCrop)
    #expect(short.snapshot == nil)
    let silent = technique.evaluate(
      trace: BPMDiagnosticTrace(), audio: decoded([Float](repeating: 0, count: 20 * 44_100)))
    #expect(silent.evaluation == nil)
    #expect(silent.crops?.abstainReason == .noRhythmicCrop)
    #expect(silent.crops?.candidates.count == 3)
  }

  @Test(
    ".dspOnly with the technique attached is byte-identical to no technique",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func dspOnlyByteIdentity() throws {
    let technique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    let audio = clickTrack(seconds: 30)
    var plain = AudioAnalysisService.Options()
    plain.enableTrace = true
    plain.enableMLDiagnostics = true
    var attached = plain
    attached.mlTechnique = technique
    let a = try #require(try AudioAnalysisService.analyzeBPM(decoded: audio, options: plain))
    let b = try #require(try AudioAnalysisService.analyzeBPM(decoded: audio, options: attached))
    #expect(a.bpm.bitPattern == b.bpm.bitPattern)
    #expect(a.confidence.bitPattern == b.confidence.bitPattern)
    #expect(a.candidates.map(\.bpm) == b.candidates.map(\.bpm))
    #expect(a.candidates.map(\.score) == b.candidates.map(\.score))
    #expect(b.trace?.mlInputCrops == nil)
    #expect(b.trace?.mlDiagnosticSnapshot == nil)
    #expect(b.trace?.mlFeatures == nil)
    #expect(a.trace?.rawCandidates.map(\.bpm) == b.trace?.rawCandidates.map(\.bpm))
  }

  @Test(
    "under an ML-invoking policy the fixed-time vote reaches the trace",
    .disabled(if: fixturesMissing(), "model fixtures missing"))
  func serviceEndToEnd() throws {
    var options = AudioAnalysisService.Options()
    options.mlTechnique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    options.ensemblePolicy = .default
    options.enableTrace = true
    options.enableMLDiagnostics = true
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: clickTrack(seconds: 30), options: options))
    let crops = try #require(result.trace?.mlInputCrops)
    #expect((1...4).contains(crops.keptCrops.count))
    #expect(result.trace?.mlDiagnosticSnapshot?.decodedBPM != nil)
    #expect(result.trace?.ensembleWeightResolution?.mlEffectiveVote != nil)
  }

  @Test("mean of softmax decodes 30 + argmax with ties to the lower bin")
  func decode() {
    var a = [Float](repeating: 0, count: 256)
    var b = [Float](repeating: 0, count: 256)
    a[90] = 0.6
    a[45] = 0.4
    b[45] = 0.6
    b[90] = 0.4
    let tie = FixedTimeTechnique.decodeMeanOfSoftmax([a, b])
    #expect(tie.bpm == 75)
    #expect(abs(tie.topProbability - 0.5) < 1e-6)
    b[90] = 0.5
    b[45] = 0.5
    let win = FixedTimeTechnique.decodeMeanOfSoftmax([a, b])
    #expect(win.bpm == 120)
  }
}
