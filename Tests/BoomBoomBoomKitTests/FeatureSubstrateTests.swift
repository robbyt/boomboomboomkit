//
//  FeatureSubstrateTests.swift
//  BoomBoomBoomKitTests
//
//  Story 6.2 tests for FeatureSubstrate namespace + OnsetFeaturesBuilder
//  + relocated MLFeatureFrames / TensorLayout public-surface invariants.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("FeatureSubstrateTests")
struct FeatureSubstrateTests {

  // MARK: - AC #4 byte-identity regression scaffold

  @Test func uniformWeightingByteIdentity() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    // Story 8-2 AC4a (additive replacement of the manual construction):
    // the PRODUCTION producer now feeds the byte-identity scaffold.
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    let produced = try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: .uniform)

    let hopSize = Int(decoded.sampleRate / 100)
    let direct = BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands(
      samples: decoded.samples,
      sampleRate: decoded.sampleRate,
      hopSize: hopSize,
      computeSubBands: true,
      normalizeSubBands: false,
      captureMLFeatures: true
    )

    let retained = try #require(direct.mlFeatures)
    try #require(produced.logMelData.count == retained.logMelData.count)
    for i in 0..<produced.logMelData.count {
      #expect(NumericTestHelpers.bitEqual(produced.logMelData[i], retained.logMelData[i]))
    }
  }

  // MARK: - Story 8-2 AC4: cross-consumer substrate assertion (epic AC6 corrected)

  /// From ONE `readDecodedAudio`-produced `DecodedAudio`: (a) the builder
  /// facade is bit-equal to the direct `BPMAnalyzer` path (covered above on
  /// the same producer), (b) the `BeatGridAnalyzer` stub returns bit-equal
  /// `OnsetFeatures` for the same input, (c) the service LUFS decoded path
  /// measures the SAME `DecodedAudio` value — LUFS shares the DECODE, not
  /// the onset features (it K-weights raw samples; no mel/onset stage).
  @Test func crossConsumerSharedSubstrate() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)

    // (b) Beat-grid stub vs builder facade: bit-equal OnsetFeatures.
    let viaBuilder = try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: .uniform)
    let viaBeatGrid = try BeatGridAnalyzer.onsetFeatures(
      for: decoded, weighting: .uniform)
    #expect(viaBeatGrid.melBands == viaBuilder.melBands)
    #expect(viaBeatGrid.frames == viaBuilder.frames)
    try #require(viaBeatGrid.logMelData.count == viaBuilder.logMelData.count)
    for i in 0..<viaBeatGrid.logMelData.count {
      #expect(
        NumericTestHelpers.bitEqual(
          viaBeatGrid.logMelData[i], viaBuilder.logMelData[i]))
    }

    // (c) LUFS consumes the same carrier value, through the SERVICE seam
    // (Codex review thread 019eb486: a direct-analyzer call plus identity
    // re-checks on immutable value data was vacuous). The service decoded
    // path must measure this exact carrier; the full url-vs-decoded
    // equality lock lives in `LUFSDecodedEqualityTests`.
    let lufs = try #require(try AudioAnalysisService.analyzeLUFS(decoded: decoded))
    #expect(lufs.integratedLUFS.isFinite)
    #expect(!lufs.momentaryLUFS.isEmpty)
  }

  // MARK: - AC #5 featureSetVersion lock

  @Test func featureSetVersionLocked() throws {
    // Bump-trigger checklist (must update both the constant AND this test):
    //  - Parameters.fftSize default (currently 2048)
    //  - Parameters.hopSize default (currently 441 ≈ 100 Hz at 44.1 kHz)
    //  - Parameters.melFmin default (currently 30.0 Hz)
    //  - Parameters.melFmax formula (currently min(sampleRate/2, 16000))
    //  - Parameters.logCompressionScale default (currently 100.0)
    //  - MelFilterbank.buildFilterbank construction formula
    //  - Pre-vvlogf 100.0 * x + 1.0 linear-then-log compression pre-image
    //  - WeightingProfile case set or default value
    //  - OnsetFeaturesBuilder.build algorithmic shape
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone)
    )
    let produced = try FeatureSubstrate.OnsetFeaturesBuilder.build(
      decoded: decoded, weighting: .uniform)
    #expect(produced.featureSetVersion == "v2")
  }

  // MARK: - AC #2 relocation: public surface unchanged

  @Test func relocatedTypePublicSurfaceUnchanged() throws {
    let frames = try MLFeatureFrames(
      melBands: 128,
      frames: 10,
      tensorLayout: .frameMajorLogMel,
      logMelData: Array(repeating: 0.0, count: 1280),
      sampleRate: 44100,
      fftSize: 2048,
      hopSize: 441,
      melFmin: 30.0,
      melFmax: 16000.0,
      logCompressionScale: 100.0,
      featureSetVersion: "v1"
    )
    #expect(frames.melBands == 128)
    #expect(frames.frames == 10)
    #expect(frames.tensorLayout == .frameMajorLogMel)
    #expect(TensorLayout.allCases.count == 2)
    #expect(TensorLayout.frameMajorLogMel != TensorLayout.nchw)
  }

  // MARK: - AC #3 builder rejects unimplemented weighting

  @Test func subBandEmphasisThrows() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples,
      sampleRate: sampleRate,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone)
    )
    let weights = FeatureSubstrate.SubBandWeights(
      kickBandWeight: 1.0,
      snareBandWeight: 1.0,
      cymbalBandWeight: 1.0,
      cutoff: .standard
    )
    #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try FeatureSubstrate.OnsetFeaturesBuilder.build(
        decoded: decoded, weighting: .subBandEmphasis(weights))
    }
  }

  // MARK: - AC #1 OnsetFeatures init invariant matrix

  @Test func onsetFeaturesInitInvariants() throws {
    let validParams = FeatureSubstrate.OnsetFeatures.Parameters(
      fftSize: 2048,
      hopSize: 441,
      melFmin: 30.0,
      melFmax: 16000.0,
      logCompressionScale: 100.0
    )
    let validLogMel: [Float] = Array(repeating: 0.0, count: 128 * 4)

    // zero melBands
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 0, logMelData: [],
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1", parameters: validParams)
    }
    // zero frames
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 0, melBands: 128, logMelData: [],
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1", parameters: validParams)
    }
    // mismatched count
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: [0.0, 0.0, 0.0],
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1", parameters: validParams)
    }
    // oversize buffer (lower cap via TaskLocal, then exceed it)
    try MLFeatureFrames._withTestingMaximumLogMelDataCount(100) {
      let tooMany: [Float] = Array(repeating: 0.0, count: 128 * 4)
      #expect(throws: MLTechniqueError.self) {
        _ = try FeatureSubstrate.OnsetFeatures(
          frames: 4, melBands: 128, logMelData: tooMany,
          tensorLayout: .frameMajorLogMel, weighting: .uniform,
          featureSetVersion: "v1", parameters: validParams)
      }
    }
    // NaN payload
    var nanPayload: [Float] = Array(repeating: 0.0, count: 128 * 4)
    nanPayload[5] = .nan
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: nanPayload,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1", parameters: validParams)
    }
    // +Inf payload
    var infPayload: [Float] = Array(repeating: 0.0, count: 128 * 4)
    infPayload[10] = .infinity
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: infPayload,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1", parameters: validParams)
    }
    // zero fftSize
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 0, hopSize: 441, melFmin: 30.0, melFmax: 16000.0,
          logCompressionScale: 100.0))
    }
    // zero hopSize
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 0, melFmin: 30.0, melFmax: 16000.0,
          logCompressionScale: 100.0))
    }
    // non-finite melFmin
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: .nan, melFmax: 16000.0,
          logCompressionScale: 100.0))
    }
    // negative melFmin
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: -1.0, melFmax: 16000.0,
          logCompressionScale: 100.0))
    }
    // non-finite melFmax
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: 30.0, melFmax: .infinity,
          logCompressionScale: 100.0))
    }
    // melFmax <= melFmin
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: 100.0, melFmax: 100.0,
          logCompressionScale: 100.0))
    }
    // non-finite logCompressionScale
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: 30.0, melFmax: 16000.0,
          logCompressionScale: .nan))
    }
    // non-positive logCompressionScale
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "v1",
        parameters: FeatureSubstrate.OnsetFeatures.Parameters(
          fftSize: 2048, hopSize: 441, melFmin: 30.0, melFmax: 16000.0,
          logCompressionScale: 0.0))
    }
    // empty featureSetVersion
    #expect(throws: MLTechniqueError.self) {
      _ = try FeatureSubstrate.OnsetFeatures(
        frames: 4, melBands: 128, logMelData: validLogMel,
        tensorLayout: .frameMajorLogMel, weighting: .uniform,
        featureSetVersion: "", parameters: validParams)
    }
  }

  // MARK: - AC #3 builder failure-path coverage

  @Test func builderFailurePathsThrow() throws {
    let priming = FeatureSubstrate.PrimingInfo(
      codec: .linearPCM, trimState: .knownNone)
    // (a) audio too short — empty samples yields .empty from
    // computeMelOnsetEnvelopeWithSubBands → builder throws featurizationFailed
    let tooShort = FeatureSubstrate.DecodedAudio(
      samples: [Float](repeating: 0.0, count: 1024),
      sampleRate: 44100.0,
      codecPriming: priming
    )
    #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
      _ = try FeatureSubstrate.OnsetFeaturesBuilder.build(
        decoded: tooShort, weighting: .uniform)
    }
    // (b) retention cap fires — lower the cap, then use a normal-length sample
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    let decoded = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: sampleRate, codecPriming: priming)
    try MLFeatureFrames._withTestingMaximumLogMelDataCount(100) {
      #expect(throws: FeatureSubstrate.FeatureSubstrateError.self) {
        _ = try FeatureSubstrate.OnsetFeaturesBuilder.build(
          decoded: decoded, weighting: .uniform)
      }
    }
  }
}
