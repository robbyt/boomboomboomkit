//
//  OnsetFeatures.swift
//  BoomBoomBoomKit
//
//  Substrate type-surface carrier for onset-rate log-mel features.
//

import Foundation

extension FeatureSubstrate {

  public struct OnsetFeatures: Sendable, CustomStringConvertible, Equatable {

    // swiftlint:disable:next nesting
    public struct Parameters: Sendable, Equatable, Codable {

      public let fftSize: Int
      public let hopSize: Int
      public let melFmin: Double
      public let melFmax: Double
      public let logCompressionScale: Float

      public init(
        fftSize: Int,
        hopSize: Int,
        melFmin: Double,
        melFmax: Double,
        logCompressionScale: Float
      ) {
        self.fftSize = fftSize
        self.hopSize = hopSize
        self.melFmin = melFmin
        self.melFmax = melFmax
        self.logCompressionScale = logCompressionScale
      }
    }

    public let frames: Int
    public let melBands: Int
    public let logMelData: [Float]
    public let tensorLayout: TensorLayout
    public let weighting: WeightingProfile

    /// Pre-`vvlogf` pipeline version tag. Story 6.2 ships `"v1"` against the
    /// current `BPMAnalyzer.computeMelOnsetEnvelopeWithSubBands` pre-image.
    /// ANY change to the following invalidates downstream consumer assumptions
    /// (FR-21 train/runtime parity) and MUST bump the string (`"v2"`, `"v3"`, …):
    ///
    /// - `Parameters.fftSize` default value (currently `2048`)
    /// - `Parameters.hopSize` default value (currently `441` ≈ 100 Hz at 44.1 kHz)
    /// - `Parameters.melFmin` default value (currently `30.0` Hz)
    /// - `Parameters.melFmax` formula (currently `min(sampleRate/2, 16000)`)
    /// - `Parameters.logCompressionScale` default value (currently `100.0`)
    /// - The mel filterbank construction formula in `MelFilterbank.buildFilterbank`
    /// - The pre-`vvlogf` `100.0 * x + 1.0` linear-then-log compression pre-image
    /// - `WeightingProfile` case set or default value
    /// - `OnsetFeaturesBuilder.build` algorithmic shape
    public let featureSetVersion: String

    public let parameters: Parameters

    public init(
      frames: Int,
      melBands: Int,
      logMelData: [Float],
      tensorLayout: TensorLayout,
      weighting: WeightingProfile,
      featureSetVersion: String,
      parameters: Parameters
    ) throws {
      guard melBands > 0 else {
        throw MLTechniqueError.invalidFeatureShape(
          reason: "melBands must be positive (got \(melBands))")
      }
      guard frames > 0 else {
        throw MLTechniqueError.invalidFeatureShape(
          reason: "frames must be positive (got \(frames))")
      }
      let (expectedCount, overflow) = melBands.multipliedReportingOverflow(by: frames)
      guard !overflow else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "melBands * frames overflowed Int (melBands=\(melBands), frames=\(frames))")
      }
      guard logMelData.count == expectedCount else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "logMelData.count (\(logMelData.count)) != melBands * frames (\(expectedCount))")
      }
      guard expectedCount <= MLFeatureFrames.maximumLogMelDataCount else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "logMelData.count \(expectedCount) exceeds size cap "
            + "\(MLFeatureFrames.maximumLogMelDataCount) (≈32 MB); bump cap or "
            + "trim the analysis window")
      }
      switch tensorLayout {
      case .frameMajorLogMel, .nchw:
        break
      }
      switch weighting {
      case .uniform, .subBandEmphasis:
        break
      }
      guard parameters.fftSize > 0 else {
        throw MLTechniqueError.invalidFeatureShape(
          reason: "fftSize must be positive (got \(parameters.fftSize))")
      }
      guard parameters.hopSize > 0 else {
        throw MLTechniqueError.invalidFeatureShape(
          reason: "hopSize must be positive (got \(parameters.hopSize))")
      }
      guard parameters.melFmin.isFinite, parameters.melFmin >= 0 else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "melFmin must be finite and non-negative (got \(parameters.melFmin))")
      }
      guard parameters.melFmax.isFinite, parameters.melFmax > parameters.melFmin else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "melFmax must be finite and strictly greater than melFmin "
            + "(melFmin=\(parameters.melFmin), melFmax=\(parameters.melFmax))")
      }
      guard
        parameters.logCompressionScale.isFinite,
        parameters.logCompressionScale > 0
      else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "logCompressionScale must be finite and positive "
            + "(got \(parameters.logCompressionScale))")
      }
      guard !featureSetVersion.isEmpty else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "featureSetVersion must not be empty (FR-21 pipeline-drift detection)")
      }
      guard logMelData.allSatisfy({ $0.isFinite }) else {
        throw MLTechniqueError.invalidFeatureShape(
          reason:
            "logMelData contains non-finite values (NaN or Inf); upstream "
            + "DSP pre-image overflowed or produced an invalid log")
      }

      self.frames = frames
      self.melBands = melBands
      self.logMelData = logMelData
      self.tensorLayout = tensorLayout
      self.weighting = weighting
      self.featureSetVersion = featureSetVersion
      self.parameters = parameters
    }

    public var description: String {
      "OnsetFeatures(melBands: \(melBands), frames: \(frames), "
        + "layout: \(tensorLayout), logMelData.count: \(logMelData.count), "
        + "weighting: \(weighting), "
        + "fftSize: \(parameters.fftSize), hopSize: \(parameters.hopSize), "
        + "melFmin: \(parameters.melFmin), melFmax: \(parameters.melFmax), "
        + "logCompressionScale: \(parameters.logCompressionScale), "
        + "featureSetVersion: \"\(featureSetVersion)\")"
    }
  }
}
