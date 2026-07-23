//
//  PCMIngressGuardTests.swift
//  BoomBoomBoomKitTests
//
//  GH-167 item 2 — PCM ingress sanitize + trap-guard cluster
//  (#122 poisoned-decode sanitize, #121 clickRescore NaN comparator,
//  #120 dead hi-hat band, #119 builder sample-rate ceiling, #123 downsample
//  capacity overflow, #125 generateClickTrack preconditions).
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Float32 WAV fixture writer (#122)

/// Writes a canonical 44-byte-header WAVE_FORMAT_IEEE_FLOAT (format code 3)
/// WAV whose sample payload is the given Float32 bit patterns, verbatim.
/// Bit patterns (not Float values) so poisoned NaN/Inf payloads and
/// bit-identity assertions are exact — AVFoundation passes Float32 WAV
/// samples through bit-exact (verified by the #122 passthrough probe).
/// `channels > 1` interprets `bitPatterns` as interleaved frames
/// (blockAlign = channels * 4, byteRate scaled accordingly).
private func writeFloat32WAV(
  bitPatterns: [UInt32], sampleRate: UInt32, channels: UInt16 = 1, to url: URL
) throws {
  func appendLE32(_ data: inout Data, _ v: UInt32) {
    data.append(UInt8(v & 0xFF))
    data.append(UInt8((v >> 8) & 0xFF))
    data.append(UInt8((v >> 16) & 0xFF))
    data.append(UInt8((v >> 24) & 0xFF))
  }
  func appendLE16(_ data: inout Data, _ v: UInt16) {
    data.append(UInt8(v & 0xFF))
    data.append(UInt8((v >> 8) & 0xFF))
  }
  var data = Data()
  let dataSize = UInt32(bitPatterns.count * 4)
  data.append(contentsOf: Array("RIFF".utf8))
  appendLE32(&data, 36 + dataSize)
  data.append(contentsOf: Array("WAVE".utf8))
  data.append(contentsOf: Array("fmt ".utf8))
  appendLE32(&data, 16)  // fmt chunk size
  appendLE16(&data, 3)  // WAVE_FORMAT_IEEE_FLOAT
  appendLE16(&data, channels)
  appendLE32(&data, sampleRate)
  appendLE32(&data, sampleRate * UInt32(channels) * 4)  // byte rate
  appendLE16(&data, channels * 4)  // block align
  appendLE16(&data, 32)  // bits per sample
  data.append(contentsOf: Array("data".utf8))
  appendLE32(&data, dataSize)
  for bits in bitPatterns { appendLE32(&data, bits) }
  try data.write(to: url)
}

private func temporaryWAVURL(_ name: String) -> URL {
  URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("pcm-ingress-\(name)-\(UUID().uuidString).wav")
}

private let nanBits: UInt32 = 0x7FC0_0000
private let posInfBits: UInt32 = 0x7F80_0000
private let negInfBits: UInt32 = 0xFF80_0000

@Suite("PCM ingress guards (GH-167 item 2)")
struct PCMIngressGuardTests {

  // MARK: - #122 poisoned-decode sanitize

  @Test("poisoned Float32 WAV: non-finite samples zeroed, finite samples bit-identical")
  func poisonedWAVSanitized() throws {
    // NaN, +Inf, -Inf embedded among finite samples.
    let patterns: [UInt32] = [
      Float(0.5).bitPattern,
      nanBits,
      Float(-0.25).bitPattern,
      posInfBits,
      Float(0.125).bitPattern,
      negInfBits,
      Float(1.0).bitPattern,
      Float(-1.0).bitPattern,
      nanBits,
      Float(0.0625).bitPattern,
    ]
    let url = temporaryWAVURL("poisoned")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(sampleRate == 44_100)
    try #require(samples.count == patterns.count)
    let nonFiniteIndices: Set<Int> = [1, 3, 5, 8]
    for (i, sample) in samples.enumerated() {
      #expect(sample.isFinite, "sample \(i) must be finite post-sanitize")
      if nonFiniteIndices.contains(i) {
        #expect(sample == 0.0, "poisoned sample \(i) must read as 0.0")
      } else {
        #expect(
          sample.bitPattern == patterns[i],
          "finite sample \(i) must be bit-identical to source bytes")
      }
    }
  }

  @Test("clean Float32 WAV through the same writer: bit-identical throughout")
  func cleanWAVBitIdentity() throws {
    let patterns: [UInt32] = [
      Float(0.5).bitPattern,
      Float(-0.5).bitPattern,
      Float(0.25).bitPattern,
      Float(1.0).bitPattern,
      Float(-1.0).bitPattern,
      Float(0.0).bitPattern,
      Float(3.0e-8).bitPattern,
      Float(0.999).bitPattern,
    ]
    let url = temporaryWAVURL("clean")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    try #require(samples.count == patterns.count)
    for (i, sample) in samples.enumerated() {
      #expect(
        sample.bitPattern == patterns[i],
        "clean sample \(i) must be bit-identical (sanitize must not touch finite data)")
    }
  }

  @Test("fully poisoned Float32 WAV reads as all zeros (silence path, by policy)")
  func fullyPoisonedWAVReadsAsSilence() throws {
    let patterns = [UInt32](repeating: nanBits, count: 32)
      .enumerated().map { i, bits in i % 3 == 1 ? posInfBits : (i % 3 == 2 ? negInfBits : bits) }
    let url = temporaryWAVURL("fully-poisoned")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    try #require(samples.count == patterns.count)
    #expect(samples.allSatisfy { $0 == 0.0 })
  }

  @Test("Inf-only poisoned WAV (no NaN): both infinities zeroed, finite samples bit-identical")
  func infOnlyPoisonedWAVSanitized() throws {
    // Pins the Inf class independently of NaN: the sanitize must catch
    // +Inf/-Inf on its own, not only via NaN propagation.
    let patterns: [UInt32] = [
      Float(0.5).bitPattern,
      posInfBits,
      Float(-0.25).bitPattern,
      negInfBits,
      Float(0.125).bitPattern,
      posInfBits,
      Float(-1.0).bitPattern,
      negInfBits,
    ]
    let url = temporaryWAVURL("inf-only")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    try #require(samples.count == patterns.count)
    let infIndices: Set<Int> = [1, 3, 5, 7]
    for (i, sample) in samples.enumerated() {
      if infIndices.contains(i) {
        #expect(sample == 0.0, "infinite sample \(i) must read as 0.0")
      } else {
        #expect(
          sample.bitPattern == patterns[i],
          "finite sample \(i) must be bit-identical to source bytes")
      }
    }
  }

  @Test("poisoned WAV through the downsample path: every returned sample finite")
  func poisonedWAVDownsampledStaysFinite() throws {
    // Pins the sanitize's placement BEFORE the AVAudioConverter: if the
    // zeroing ran after (or not at all), NaN/Inf would smear through the
    // resampler's filter kernel into many output samples.
    var patterns: [UInt32] = (0..<4_096).map { i in
      Float(sin(Double(i) * 0.05) * 0.5).bitPattern
    }
    for i in stride(from: 7, to: patterns.count, by: 97) {
      patterns[i] = i % 3 == 0 ? nanBits : (i % 3 == 1 ? posInfBits : negInfBits)
    }
    let url = temporaryWAVURL("poisoned-downsample")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, targetSampleRate: 22_050)
    #expect(sampleRate == 22_050)
    #expect(!samples.isEmpty)
    for (i, sample) in samples.enumerated() {
      #expect(sample.isFinite, "downsampled sample \(i) must be finite post-sanitize")
    }
  }

  @Test("stereo poisoned WAV: NaN in one channel zeroes the mixed frame, others finite")
  func stereoPoisonedWAVSanitized() throws {
    // One NaN in the left channel at frame 2 makes the (L + R) / 2 mixdown
    // NaN for that frame; the sanitize (which runs on the post-mixdown mono
    // buffer) must zero exactly that frame. All values are exactly
    // representable, so the finite mixdown frames compare exactly.
    let frames: [(left: Float, right: Float)] = [
      (0.5, 0.25),  // 0.375
      (-0.25, 0.75),  // 0.25
      (Float.nan, 0.5),  // NaN -> 0.0
      (1.0, 0.5),  // 0.75
      (0.125, 0.375),  // 0.25
    ]
    let patterns: [UInt32] = frames.flatMap { [$0.left.bitPattern, $0.right.bitPattern] }
    let url = temporaryWAVURL("stereo-poisoned")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, channels: 2, to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    try #require(samples.count == frames.count)
    let expected: [Float] = [0.375, 0.25, 0.0, 0.75, 0.25]
    for (i, sample) in samples.enumerated() {
      #expect(sample.isFinite, "mixed frame \(i) must be finite post-sanitize")
      #expect(sample == expected[i], "mixed frame \(i) must equal (L + R) / 2 (poisoned -> 0.0)")
    }
  }

  // MARK: - #121 clickRescore NaN-safe comparator

  @Test("clickRescore: NaN score sorts last deterministically AND rescoring occurred")
  func clickRescoreNaNScoreSortsLast() {
    // NaN-scored candidate FIRST: the pre-fix comparator returns false for
    // every NaN comparison, so insertion sort leaves it in place (first) —
    // the post-fix NaN-last assertion bites on revert.
    let candidates: [(bpm: Double, score: Float)] = [
      (bpm: 130.0, score: Float.nan),
      (bpm: 120.0, score: 1.0),
      (bpm: 125.0, score: 0.5),
    ]
    // Envelope sized to pass the pre-flight: at onsetRate 100, the longest
    // kernel is bpm 120 (period 50 frames, 8 clicks, length 351). A constant
    // positive envelope gives every candidate a deterministic NCC well below
    // 1.0, so finite scores provably change.
    let envelope = [Float](repeating: 1.0, count: 1_000)
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: envelope,
      onsetRate: 100.0,
      trace: &trace)

    #expect(rescored.count == 3)
    // Finite candidates in descending rescored order; NaN dead last.
    #expect(rescored[0].bpm == 120.0)
    #expect(rescored[1].bpm == 125.0)
    #expect(rescored[2].bpm == 130.0)
    #expect(rescored[2].score.isNaN)
    // Rescoring provably occurred: the damping blend moved the finite scores.
    #expect(rescored[0].score.isFinite && rescored[0].score != 1.0)
    #expect(rescored[1].score.isFinite && rescored[1].score != 0.5)
  }

  @Test(
    "clickRescore: NaN in first/middle/last position and a two-NaN case all sort last",
    arguments: [[0], [2], [3], [0, 2]])
  func clickRescoreNaNPositionPermutations(nanPositions: [Int]) {
    // Same fixture recipe as the base test above; the NaN-scored candidates
    // are inserted at parameterized positions. Assertion contract: finite
    // candidates keep their descending rescored order at the head, NaN
    // candidates sort dead last with the original-index (offset) tiebreak
    // resolving NaN-vs-NaN — so the two-NaN tail preserves input order.
    let finite: [(bpm: Double, score: Float)] = [
      (bpm: 120.0, score: 1.0),
      (bpm: 125.0, score: 0.5),
      (bpm: 130.0, score: 0.25),
    ]
    let nanBPMs: [Double] = [135.0, 140.0]
    var candidates = finite
    for (n, position) in nanPositions.enumerated() {
      candidates.insert((bpm: nanBPMs[n], score: Float.nan), at: position)
    }
    // Input offsets of the NaN candidates, in insertion order, for the
    // tail-order expectation (insertions above never displace an earlier
    // NaN: positions are ascending).
    let expectedNaNTailBPMs = nanPositions.enumerated()
      .map { (offset: $1, bpm: nanBPMs[$0]) }
      .sorted { $0.offset < $1.offset }
      .map(\.bpm)

    let envelope = [Float](repeating: 1.0, count: 1_000)
    var trace: BPMDiagnosticTrace?
    let rescored = BPMAnalyzer.clickRescore(
      candidates: candidates,
      onsetEnvelope: envelope,
      onsetRate: 100.0,
      trace: &trace)

    #expect(rescored.count == candidates.count)
    // Head: finite candidates in descending rescored order (the blend keeps
    // the 1.0 / 0.5 / 0.25 separation: newScore is in [0.7 * s, s]).
    #expect(rescored[0].bpm == 120.0)
    #expect(rescored[1].bpm == 125.0)
    #expect(rescored[2].bpm == 130.0)
    #expect(rescored[0].score.isFinite && rescored[1].score.isFinite && rescored[2].score.isFinite)
    #expect(rescored[0].score > rescored[1].score)
    #expect(rescored[1].score > rescored[2].score)
    // Tail: every NaN-scored candidate, in original input-offset order.
    for (i, expectedBPM) in expectedNaNTailBPMs.enumerated() {
      let entry = rescored[finite.count + i]
      #expect(entry.score.isNaN, "tail entry \(i) must carry the NaN score")
      #expect(entry.bpm == expectedBPM, "NaN tail must preserve input-offset order")
    }
  }

  // MARK: - #120 dead hi-hat band

  @Test("confirmWithSubBandPeaks: dead hi-hat band returns winner unchanged (no Int(Inf) trap)")
  func deadHiHatBandReturnsWinner() {
    // All four bands uniformly negative: every fast-range (140-200 BPM) lag
    // interpolates to -0.5, so the scan never raises hiHatBestStrength above
    // its 0 seed and hiHatBestBPM stays 0. hiHatAtWinner is -0.5, so the
    // pre-fix `hiHatBestStrength (0) > hiHatAtWinner (-0.5)` gate passes and
    // `60.0 * onsetRate / 0` produced an infinite lag trapping at `Int(lag)`
    // in interpolateACF. At onsetRate 100 the fast-range lags span ~30-43
    // frames and the 120-BPM winner lag is 50 — all inside the 100-element ACF.
    let deadBand = [Float](repeating: -0.5, count: 100)
    let subBandACFs = [deadBand, deadBand, deadBand, deadBand]
    let winner: (bpm: Double, score: Float) = (bpm: 120.0, score: 0.8)

    let result = BPMAnalyzer.confirmWithSubBandPeaks(
      winner: winner, subBandACFs: subBandACFs, onsetRate: 100.0)

    #expect(result.bpm == winner.bpm)
    #expect(result.score == winner.score)
  }

  // MARK: - #119 OnsetFeaturesBuilder sample-rate ceiling

  private static func syntheticDecoded(sampleRate: Double, count: Int)
    -> FeatureSubstrate
    .DecodedAudio
  {
    // Simple impulse train — content is irrelevant to the ceiling guard; it
    // only needs to satisfy DecodedAudio's floor and (for the proceeds case)
    // yield at least 2 mel frames.
    var samples = [Float](repeating: 0, count: count)
    var i = 0
    while i < count {
      samples[i] = 1.0
      i += 4_096
    }
    return FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone))
  }

  @Test("build throws featurizationFailed on a huge finite rate (1e21) instead of trapping")
  func builderHugeRateThrows() {
    let decoded = Self.syntheticDecoded(sampleRate: 1.0e21, count: 1_000)
    let error = #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try FeatureSubstrate.OnsetFeaturesBuilder.build(decoded: decoded, weighting: .uniform)
    }
    guard case .featurizationFailed(let reason) = error else {
      Issue.record("expected featurizationFailed, got \(String(describing: error))")
      return
    }
    #expect(reason.contains("ceiling"), "reason must name the onset-framing ceiling")
  }

  @Test("build proceeds at the 768 kHz ceiling boundary")
  func builderAtCeilingProceeds() throws {
    // Exactly at the shared ceiling: the guard is `<=`, so 768,000 passes.
    // hopSize = 7,680; 40,000 samples yield >= 2 mel frames.
    let decoded = Self.syntheticDecoded(sampleRate: 768_000, count: 40_000)
    let features = try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: .uniform)
    #expect(features.melBands == 128)
  }

  @Test("build throws featurizationFailed naming the ceiling just over 768 kHz")
  func builderOverCeilingThrows() {
    let decoded = Self.syntheticDecoded(sampleRate: 768_001, count: 40_000)
    let error = #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try FeatureSubstrate.OnsetFeaturesBuilder.build(decoded: decoded, weighting: .uniform)
    }
    // Specific case + reason, not just "some FeatureSubstrateError": the
    // guard must fail as featurizationFailed and its reason must cite the
    // shared onset-framing ceiling.
    guard case .featurizationFailed(let reason) = error else {
      Issue.record("expected featurizationFailed, got \(String(describing: error))")
      return
    }
    #expect(reason.contains("ceiling"), "reason must name the onset-framing ceiling")
    #expect(reason.contains("768000"), "reason must cite the shared ceiling value")
  }

  // MARK: - #123 downsample output-capacity helper

  @Test("capacity helper: values straddling UInt32.max, including the +1 edge")
  func downsampleCapacityBoundary() {
    // ceil(4294967294 * 1.0) + 1 == 4294967295 == UInt32.max: representable.
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: Int(UInt32.max) - 1, ratio: 1.0) == AVAudioFrameCount(UInt32.max))
    // ceil(4294967295 * 1.0) + 1 == 4294967296: the +1 pushes past UInt32.max.
    // (The pre-fix inline form trapped converting BEFORE the +1 could apply.)
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: Int(UInt32.max), ratio: 1.0) == nil)
    // Non-finite ratio and Double-overflow products refuse representably.
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: 1_000, ratio: .infinity) == nil)
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: 1_000_000, ratio: 1.0e300) == nil)
    // Negative domain (review round 2): a finite negative capacity passed
    // the old upper-bound-only check and trapped at the UInt32 conversion.
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: 1_000, ratio: -1.0) == nil)
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: -5, ratio: 1.0) == nil)
    // Ordinary downsample shape is unchanged: ceil(1000 * 0.1) + 1 == 101.
    #expect(
      PCMBufferReader.downsampleOutputCapacity(
        inputFrames: 1_000, ratio: 0.1) == 101)
  }

  @Test("public API at a huge target rate throws (reachability check, not the bite proof)")
  func publicAPIHugeTargetRateThrows() throws {
    // Documents what the public API actually does at an extreme
    // targetSampleRate; the #123 bite proof lives on the helper test above.
    let patterns: [UInt32] = (0..<64).map { _ in Float(0.25).bitPattern }
    let url = temporaryWAVURL("huge-rate")
    try writeFloat32WAV(bitPatterns: patterns, sampleRate: 44_100, to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(throws: PCMBufferReaderError.self) {
      _ = try PCMBufferReader.readMonoSamples(from: url, targetSampleRate: 1.0e18)
    }
  }

  // MARK: - #125 generateClickTrack normal-input golden

  @Test("generateClickTrack on normal input is unchanged by the preconditions")
  func clickTrackGoldenUnchanged() {
    // Pre-fix golden: bpm 120 at 44.1 kHz for 10 s — 441,000 samples,
    // samplesPerBeat 22,050, 64-sample exponential-decay impulses.
    let samples = generateClickTrack(bpm: 120)
    #expect(samples.count == 441_000)
    #expect(samples[0] == 1.0)
    #expect(samples[22_050] == 1.0)
    #expect(samples[63] == Float(exp(-6.3)))
    #expect(samples[64] == 0.0)
    #expect(samples[100] == 0.0)
  }
}

// swift-testing exit tests (`#expect(processExitsWith:)`) require Swift 6.2+.
// Gate the suite so older CI toolchains (e.g. GitHub macos-15, whose
// swift-testing predates exit tests) compile-skip it instead of failing to
// build. It runs locally and on Swift 6.2+ runners.
#if compiler(>=6.2)
  @Suite("generateClickTrack — precondition guards (GH #125)")
  struct GenerateClickTrackGuardTests {

    // Each test observes the child process's stderr and asserts the
    // documented precondition's distinguishing message fragment is present.
    // A bare `.failure` expectation cannot tell the guard's trap apart from
    // the baseline generic trap the guard exists to prevent (stride(by: 0),
    // Int(NaN), Array(repeating:count:) with a negative count) — those
    // messages lack the "generateClickTrack:" prefix, so a precondition
    // removal makes the fragment assertion FAIL instead of silently passing
    // on the downstream trap. Fragments match the precondition messages in
    // Sources/BoomBoomBoomKitTestSupport/TestSignalGenerators.swift, cut
    // before the interpolated "(got ...)" suffix.
    private static func stderrContains(
      _ result: ExitTest.Result?, _ fragment: String
    ) -> Bool {
      guard let result else {
        // The #expect(processExitsWith:) already recorded the failure;
        // don't double-report.
        return true
      }
      return result.standardErrorContent.contains(Array(fragment.utf8))
    }

    @Test("zero bpm traps in the bpm guard")
    func zeroBPM() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: 0)
      }
      #expect(Self.stderrContains(result, "generateClickTrack: bpm must be finite and > 0"))
    }

    @Test("negative bpm traps in the bpm guard (pre-fix: silent all-zero output)")
    func negativeBPM() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: -120)
      }
      #expect(Self.stderrContains(result, "generateClickTrack: bpm must be finite and > 0"))
    }

    @Test("non-finite bpm traps in the bpm guard")
    func nonFiniteBPM() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: .nan)
      }
      #expect(Self.stderrContains(result, "generateClickTrack: bpm must be finite and > 0"))
    }

    @Test("zero sampleRate traps in the sampleRate guard")
    func zeroSampleRate() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: 120, sampleRate: 0)
      }
      #expect(
        Self.stderrContains(result, "generateClickTrack: sampleRate must be finite and > 0"))
    }

    @Test("non-finite sampleRate traps in the sampleRate guard")
    func nonFiniteSampleRate() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: 120, sampleRate: .nan)
      }
      #expect(
        Self.stderrContains(result, "generateClickTrack: sampleRate must be finite and > 0"))
    }

    @Test("negative duration traps in the duration guard")
    func negativeDuration() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: 120, durationSeconds: -1)
      }
      #expect(
        Self.stderrContains(
          result, "generateClickTrack: durationSeconds must be finite and >= 0"))
    }

    @Test("non-finite duration traps in the duration guard")
    func nonFiniteDuration() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        _ = generateClickTrack(bpm: 120, durationSeconds: .infinity)
      }
      #expect(
        Self.stderrContains(
          result, "generateClickTrack: durationSeconds must be finite and >= 0"))
    }

    @Test("bpm above sampleRate * 60 traps in the ratio guard")
    func bpmAboveSampleRateProduct() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        // 44,100 * 60 = 2,646,000 < 3,000,000: samplesPerBeat would be 0.
        _ = generateClickTrack(bpm: 3_000_000)
      }
      #expect(
        Self.stderrContains(result, "generateClickTrack: bpm must be <= sampleRate * 60"))
    }

    @Test("finite args whose derived product overflows Int trap in the derived guard")
    func derivedProductOverflow() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        // 1e12 * 1e12 = 1e24 > Int.max, though both arguments are finite.
        _ = generateClickTrack(bpm: 120, sampleRate: 1.0e12, durationSeconds: 1.0e12)
      }
      #expect(
        Self.stderrContains(
          result, "generateClickTrack: derived sampleRate * durationSeconds"))
    }

    @Test("finite args whose derived beat period overflows Int trap in the beat-period guard")
    func derivedBeatPeriodOverflow() async {
      let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
        // Zero duration keeps the sample-count product at 0 (passes guard 5);
        // 1e15 * 60 / 1e-6 = 6e22 > Int.max fails the beat-period guard 6.
        _ = generateClickTrack(bpm: 1.0e-6, sampleRate: 1.0e15, durationSeconds: 0)
      }
      #expect(
        Self.stderrContains(
          result, "generateClickTrack: derived sampleRate * 60 / bpm"))
    }
  }
#endif
