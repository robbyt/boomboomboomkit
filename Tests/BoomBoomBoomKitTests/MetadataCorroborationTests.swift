//
//  MetadataCorroborationTests.swift
//  BoomBoomBoomKitTests
//
//  Story 3.6 corroboration logic — unit tests on MetadataCorroborator.apply
//  plus integration tests on AudioAnalysisService.analyzeBPM with a synthetic
//  AIFF that embeds both PCM and an ID3v2 TBPM tag.
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - AIFF + ID3 Builder (real audio + real tag)

/// Builds a click-track AIFF in memory with an embedded `ID3 ` chunk carrying
/// a v2.3 TBPM frame. AVAudioFile reads AIFF, so DSP works end-to-end.
private enum ClickTrackAIFFBuilder {

  /// Returns the URL of a temp AIFF file with `bpm` click track and `tbpm`
  /// metadata. Caller is responsible for cleanup.
  static func write(
    clickBPM: Double,
    durationSeconds: Double,
    tbpm: String,
    sampleRate: Double = 44100,
    tbpmFrames: [String]? = nil
  ) throws -> URL {
    let sampleCount = Int(sampleRate * durationSeconds)
    var samples = [Int16](repeating: 0, count: sampleCount)
    let samplesPerBeat = Int(sampleRate * 60.0 / clickBPM)
    for beatStart in stride(from: 0, to: sampleCount, by: samplesPerBeat) {
      let impulseEnd = min(beatStart + 64, sampleCount)
      for i in beatStart..<impulseEnd {
        let decay = exp(-Double(i - beatStart) / 10.0)
        samples[i] = Int16(decay * 32000)
      }
    }

    var ssndPayload = Data()
    var offset: UInt32 = 0
    var blockSize: UInt32 = 0
    withUnsafeBytes(of: &offset) { ssndPayload.append(contentsOf: $0.reversed()) }
    withUnsafeBytes(of: &blockSize) { ssndPayload.append(contentsOf: $0.reversed()) }
    for s in samples {
      var be = s.bigEndian
      withUnsafeBytes(of: &be) { ssndPayload.append(contentsOf: $0) }
    }

    var commPayload = Data()
    // channels = 1
    commPayload.append(contentsOf: [0x00, 0x01])
    // numSampleFrames (BE 32)
    var n = UInt32(sampleCount).bigEndian
    withUnsafeBytes(of: &n) { commPayload.append(contentsOf: $0) }
    // sampleSize = 16
    commPayload.append(contentsOf: [0x00, 0x10])
    // sampleRate (10-byte IEEE 80-bit BE).
    commPayload.append(contentsOf: ieee80SampleRate(sampleRate))

    let tbpmFrameBytes = (tbpmFrames ?? [tbpm]).reduce(into: Data()) { frames, value in
      frames.append(tbpmFrame(value))
    }

    var id3Tag = Data()
    id3Tag.append(contentsOf: [0x49, 0x44, 0x33, 0x03, 0x00, 0x00])  // ID3 v2.3
    id3Tag.append(contentsOf: synchsafe(UInt32(tbpmFrameBytes.count)))
    id3Tag.append(tbpmFrameBytes)

    var aiff = Data()
    aiff.append(contentsOf: [0x46, 0x4F, 0x52, 0x4D])  // FORM
    let chunks =
      chunkBytes("COMM", payload: commPayload)
      + chunkBytes("SSND", payload: ssndPayload)
      + chunkBytes("ID3 ", payload: id3Tag)
    var formSize = UInt32(4 + chunks.count).bigEndian
    withUnsafeBytes(of: &formSize) { aiff.append(contentsOf: $0) }
    aiff.append(contentsOf: [0x41, 0x49, 0x46, 0x46])  // AIFF
    aiff.append(chunks)

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("clk-meta-\(UUID().uuidString).aiff")
    try aiff.write(to: url)
    return url
  }

  private static func chunkBytes(_ id: String, payload: Data) -> Data {
    var chunk = Data()
    chunk.append(contentsOf: Array(id.utf8))
    var sz = UInt32(payload.count).bigEndian
    withUnsafeBytes(of: &sz) { chunk.append(contentsOf: $0) }
    chunk.append(payload)
    if payload.count & 1 == 1 { chunk.append(0x00) }
    return chunk
  }

  private static func tbpmFrame(_ value: String) -> Data {
    var framePayload = Data([0x03])  // UTF-8 encoding marker
    framePayload.append(Data(value.utf8))
    var frame = Data()
    frame.append(contentsOf: Array("TBPM".utf8))
    var fsize = UInt32(framePayload.count).bigEndian
    withUnsafeBytes(of: &fsize) { frame.append(contentsOf: $0) }
    frame.append(contentsOf: [0x00, 0x00])
    frame.append(framePayload)
    return frame
  }

  /// Encodes `rate` (>0, common values like 44100/48000/96000) as an
  /// AIFF-spec 80-bit IEEE big-endian sample rate. Restricted to integer Hz
  /// in the practical range — sufficient for click-track tests.
  private static func ieee80SampleRate(_ rate: Double) -> [UInt8] {
    let r = UInt64(rate)
    // Find the highest bit set.
    let highBit = 63 - r.leadingZeroBitCount
    let exponent = UInt16(16383 + highBit)
    // Mantissa: shift `r` so the high bit is at bit 63.
    let shift = 63 - highBit
    let mantissa = r << shift
    var bytes: [UInt8] = []
    bytes.append(UInt8((exponent >> 8) & 0xFF))
    bytes.append(UInt8(exponent & 0xFF))
    for i in stride(from: 56, through: 0, by: -8) {
      bytes.append(UInt8((mantissa >> i) & 0xFF))
    }
    return bytes
  }

  private static func synchsafe(_ n: UInt32) -> [UInt8] {
    [
      UInt8((n >> 21) & 0x7F),
      UInt8((n >> 14) & 0x7F),
      UInt8((n >> 7) & 0x7F),
      UInt8(n & 0x7F),
    ]
  }
}

// MARK: - Helpers for unit tests

/// Builds a `BPMResult` for direct corroborator unit-testing.
private func makeResult(
  bpm: Double, confidence: Double,
  candidates: [(bpm: Double, score: Float)]
) -> BPMResult {
  BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: nil)
}

/// Builds a `MetadataBPMEvidence` entry matching what
/// `AudioAnalysisService.buildMetadataInput` would produce after parsing.
private func makeEvidence(
  source: MetadataSource, parsedBPM: Double, raw: String? = nil,
  rejection: String? = nil
) -> MetadataBPMEvidence {
  MetadataBPMEvidence(
    source: source, rawValue: raw ?? String(parsedBPM),
    parsedBPM: parsedBPM, rejectionReason: rejection)
}

// MARK: - MetadataCorroborator unit tests (no file I/O)

@Suite("MetadataCorroborator — unit tests")
struct MetadataCorroboratorUnitTests {

  @Test("empty participating tags pass through unchanged")
  func emptyPassThrough() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence.isEmpty)
  }

  @Test("single same-tempo tag boosts confidence and corroborates winner")
  func sameTempoCorroboration() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    // 0.6 * 1.25 = 0.75 (under the 0.95 clamp).
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(evidence.count == 1)
    #expect(evidence[0].corroboratedWith == 128.0)
    #expect(evidence[0].ratioMatched == nil)
    #expect(evidence[0].rejectionReason == nil)
    #expect(abs(evidence[0].boostApplied - 1.25) < 1e-9)
  }

  @Test("octave corroboration via .half ratio")
  func octaveCorroboration() {
    // DSP says 128 BPM, tag says 64 BPM — octave match (ratio 2.0).
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 64.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(evidence[0].ratioMatched == .double)  // candidate (128) is 2× tag (64)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("winner promotion: lower-ranked candidate gets boosted above DSP top")
  func winnerPromotion() {
    // DSP top candidate is 140 (score 0.5). Lower-ranked 128 (score 0.5).
    // After 1.25× boost on 128: 0.625 > 0.5 → 128 wins.
    let result = makeResult(
      bpm: 140.0, confidence: 0.5,
      candidates: [(140.0, 0.5), (128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .id3TBPM, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("intra-file conflict marks every valid tag")
  func intraFileConflict() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 140.0),
      ],
      conflictDetected: true, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence.count == 2)
    for e in evidence {
      #expect(e.rejectionReason == "intra-file-conflict")
      #expect(e.corroboratedWith == nil)
      #expect(abs(e.boostApplied - 1.0) < 1e-9)
    }
  }

  @Test("three-tag partial agreement: all-or-nothing rule rejects all three")
  func threeTagPartialAgreement() {
    // Two tags agree at 128, one at 174. AC #10: ALL THREE rejected.
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
        makeEvidence(source: .vorbisBPM, parsedBPM: 174.0),
      ],
      conflictDetected: true, policy: .default)
    let (_, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(evidence.count == 3)
    for e in evidence {
      #expect(e.rejectionReason == "intra-file-conflict")
      #expect(abs(e.boostApplied - 1.0) < 1e-9)
    }
  }

  @Test("unanimous consensus across two distinct sources corroborates winner")
  func unanimousConsensus() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    for e in evidence {
      #expect(e.corroboratedWith == 128.0)
      #expect(e.rejectionReason == nil)
    }
  }

  @Test("unanimous consensus disagrees with DSP applies skepticism penalty")
  func unanimousDisagreesPenalty() {
    // Both tags agree on 128, DSP detects 140 with no ratio match.
    let result = makeResult(
      bpm: 140.0, confidence: 0.7, candidates: [(140.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 140.0)
    // 0.7 * 0.85 = 0.595
    #expect(abs(out.confidence - 0.595) < 1e-9)
    for e in evidence {
      #expect(e.rejectionReason == "dsp-disagreement")
      #expect(abs(e.boostApplied - 0.85) < 1e-9)
    }
  }

  @Test("single uncorroborated tag is ignored — confidence unchanged")
  func singleUncorroboratedIgnored() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 200.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence[0].rejectionReason == "uncorroborated-single-tag")
    #expect(abs(evidence[0].boostApplied - 1.0) < 1e-9)
  }

  @Test("zero or non-finite prevConfidence triggers divide-by-zero guard")
  func divideByZeroGuard() {
    // confidence=0 → boostApplied must be 1.0 and confidence stays 0.
    let zeroResult = makeResult(
      bpm: 128.0, confidence: 0.0, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: zeroResult, input: input)
    #expect(out.confidence == 0.0)
    #expect(abs(evidence[0].boostApplied - 1.0) < 1e-9)

    // NaN confidence → stays unchanged, boostApplied = 1.0
    let nanResult = makeResult(
      bpm: 128.0, confidence: .nan, candidates: [(128.0, 0.5)])
    let (nanOut, nanEv) = MetadataCorroborator.apply(to: nanResult, input: input)
    #expect(nanOut.confidence.isNaN)
    #expect(abs(nanEv[0].boostApplied - 1.0) < 1e-9)
  }

  @Test("confidence is clamped to maxBoostedConfidence (0.95)")
  func confidenceClamp() {
    // Pre-boost 0.8; 0.8 * 1.25 = 1.0 → clamped to 0.95.
    let result = makeResult(
      bpm: 128.0, confidence: 0.8, candidates: [(128.0, 0.8)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(abs(out.confidence - 0.95) < 1e-9)
    // boostApplied = 0.95 / 0.8 ≈ 1.1875
    #expect(abs(evidence[0].boostApplied - (0.95 / 0.8)) < 1e-9)
  }

  @Test("triplet ratio gate is off by default — 3:2 tag does not corroborate")
  func tripletGateOff() {
    // Tag 192 vs candidate 128: ratio = 1.5. With allowTripletCorroboration=false (default), no match.
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.confidence == 0.6)
    #expect(evidence[0].rejectionReason == "uncorroborated-single-tag")
  }

  @Test("triplet ratio gate on — 3:2 tag corroborates with .threeHalf")
  func tripletGateOn() {
    var policy = MetadataPolicy.default
    policy.allowTripletCorroboration = true
    // Tag 192 (faster), candidate 128 (slower). Ratio 192/128 = 1.5.
    let result = makeResult(
      bpm: 128.0, confidence: 0.5, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: policy)
    let (_, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(evidence[0].ratioMatched == .threeHalf)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("parse-phase rejection passes through unchanged")
  func parseRejectionPassthrough() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: .nan, raw: "0", rejection: "sentinel-zero")
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.confidence == 0.6)
    #expect(evidence[0].rejectionReason == "sentinel-zero")
    #expect(evidence[0].parsedBPM.isNaN)
  }
}

// MARK: - Service-level integration tests

@Suite("MetadataCorroboration — Service-level integration")
struct MetadataCorroborationServiceTests {

  @Test("disabled policy skips metadata I/O — empty evidence, byte-identical core fields")
  func disabledPolicy() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var optsDisabled = AudioAnalysisService.Options()
    optsDisabled.metadataPolicy = .disabled
    let resultDisabled = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url, options: optsDisabled))
    // Anchor the bitPattern equality to the SAME helper production calls.
    // `runPreCorroborationPipeline` is the single source of truth for the
    // pre-corroboration pipeline ordering invariant — discarding
    // `metadataInput` here is intentional: the disabled-policy assertion
    // is precisely that metadata I/O produces no evidence.
    let baseline = try #require(
      try AudioAnalysisService.runPreCorroborationPipeline(
        url: url, options: optsDisabled, enableTrace: optsDisabled.enableTrace
      ).result)
    #expect(resultDisabled.metadataEvidence.isEmpty)
    #expect(resultDisabled.bpm.bitPattern == baseline.bpm.bitPattern)
    #expect(resultDisabled.confidence.bitPattern == baseline.confidence.bitPattern)
    #expect(resultDisabled.candidates.count == baseline.candidates.count)
    for (actual, expected) in zip(resultDisabled.candidates, baseline.candidates) {
      #expect(actual.bpm.bitPattern == expected.bpm.bitPattern)
      #expect(actual.score.bitPattern == expected.score.bitPattern)
    }
  }

  @Test("default policy populates evidence on AIFF with TBPM tag")
  func defaultPopulatesEvidence() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    #expect(!result.metadataEvidence.isEmpty)
    #expect(result.metadataEvidence.first?.source == .id3TBPM)
    #expect(result.metadataEvidence.first?.parsedBPM == 128.0)
  }

  @Test("same-tempo corroboration boosts confidence on tagged synthetic click")
  func sameTempoBoostsConfidence() throws {
    let urlTagged = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: urlTagged) }
    let urlPlain = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "0")  // sentinel-zero, no boost
    defer { try? FileManager.default.removeItem(at: urlPlain) }

    let tagged = try #require(try AudioAnalysisService.analyzeBPM(url: urlTagged))
    var optsDisabled = AudioAnalysisService.Options()
    optsDisabled.metadataPolicy = .disabled
    let plain = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: urlPlain, options: optsDisabled))

    // Tagged confidence ≥ plain confidence (with strict > only if DSP found 128).
    if abs(tagged.bpm - 128.0) < 0.5 {
      #expect(tagged.confidence >= plain.confidence)
    }
    let corrEvidence = tagged.metadataEvidence.first(where: { $0.rejectionReason == nil })
    #expect(corrEvidence != nil)
  }

  @Test("fastest intensity still reads metadata")
  func fastestIntensityReadsMetadata() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var opts = AudioAnalysisService.Options()
    opts.intensity = .fastest
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url, options: opts))
    #expect(!result.metadataEvidence.isEmpty)
  }

  @Test("disabled policy on tagged file produces empty evidence")
  func disabledPolicyOnTaggedFile() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var opts = AudioAnalysisService.Options()
    opts.metadataPolicy = .disabled
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url, options: opts))
    #expect(result.metadataEvidence.isEmpty)
  }

  @Test("intra-file conflict marks both tags rejected (AIFF with two TBPM frames)")
  func intraFileConflictIntegration() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128", tbpmFrames: ["128", "130"])
    defer { try? FileManager.default.removeItem(at: url) }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let conflictEvidence = result.metadataEvidence.filter { $0.source == .id3TBPM }
    #expect(conflictEvidence.count == 2)
    #expect(conflictEvidence.map(\.parsedBPM).sorted() == [128.0, 130.0])
    for evidence in conflictEvidence {
      #expect(evidence.rejectionReason == "intra-file-conflict")
      #expect(evidence.corroboratedWith == nil)
      #expect(evidence.boostApplied == 1.0)
    }
  }

  @Test("metadataEvidence empty when policy disabled even with tagged AIFF")
  func evidenceEmptyWhenDisabled() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var opts = AudioAnalysisService.Options()
    opts.metadataPolicy = .disabled
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(result.metadataEvidence.isEmpty)
  }
}

// MARK: - OA300 reference test (env-gated)

@Suite(
  "MetadataCorroboration — OA300 TVR Reference",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil)
)
struct MetadataCorroborationOA300Tests {

  @Test("AC #20: TVR.m4a fixture has tmpo atom and produces evidence")
  func tvrHasTmpoAtom() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else { return }
    let url = URL(fileURLWithPath: path)
      .appendingPathComponent("Bad BPM")
      .appendingPathComponent("03 TVR.m4a")
    guard FileManager.default.fileExists(atPath: url.path) else {
      Issue.record("OA300 TVR fixture not found at \(url.path) — skipping reference test")
      return
    }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let tmpo = result.metadataEvidence.first(where: { $0.source == .iTunesTmpo })
    #expect(tmpo != nil, "Expected tmpo evidence on 03 TVR.m4a")
    if let tmpo {
      #expect(tmpo.parsedBPM == 129.0)
      #expect(tmpo.corroboratedWith == 130.0)
      #expect(tmpo.ratioMatched == nil)
      #expect(tmpo.rejectionReason == nil)
      #expect(tmpo.boostApplied > 1.0)
    }
  }
}

// MARK: - Architecture invariants (AC #17)

@Suite("Architecture Invariants — Story 3.6 regression guards")
struct ArchitectureInvariantsTests {

  @Test("DSPTechnique.allCases.count == 7 (no metadata case added)")
  func dspTechniqueCount() {
    #expect(DSPTechnique.allCases.count == 7)
  }

  @Test("TechniqueSet.allDSPCombinations().count == 128 (2^7)")
  func techniqueCombinationsCount() {
    #expect(TechniqueSet.allDSPCombinations().count == 128)
  }

  @Test("MetadataSource has exactly three cases")
  func metadataSourceCases() {
    #expect(MetadataSource.allCases.count == 3)
    #expect(Set(MetadataSource.allCases) == Set([.iTunesTmpo, .id3TBPM, .vorbisBPM]))
  }

  /// Story 4.4 AC #9: `EnsemblePolicy.allCases.count == 3` is unit-test-locked
  /// alongside the existing five architecture invariants. Pre-1.0 / no-BC
  /// framing (DD #13) allows breaking this invariant in a follow-up story
  /// — but accidental drift fails this test loudly rather than silently.
  @Test("EnsemblePolicy has exactly three cases (Story 4.4 AC #9)")
  func ensemblePolicyCases() {
    #expect(EnsemblePolicy.allCases.count == 3)
    // Ordered comparison locks the iteration order so benchmark sweeps
    // consuming `EnsemblePolicy.allCases` produce stable, reproducible
    // policy-row order across runs (and so the JSON artifacts emitted by
    // `make ml-policy-sweep` have a fixed row order regardless of how a
    // future maintainer reorders the case definitions).
    #expect(EnsemblePolicy.allCases == [.dspOnly, .mlOnly, .highestConfidence])
  }

  @Test("MetadataPolicy.default enables all sources, valueRange 30-300")
  func defaultPolicyShape() {
    let p = MetadataPolicy.default
    #expect(p.enabledSources == Set(MetadataSource.allCases))
    #expect(p.valueRange == 30.0...300.0)
  }

  @Test("MetadataPolicy.disabled has empty enabledSources")
  func disabledPolicyShape() {
    let p = MetadataPolicy.disabled
    #expect(p.enabledSources.isEmpty)
  }
}
