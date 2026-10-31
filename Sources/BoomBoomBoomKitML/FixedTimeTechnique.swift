//
//  FixedTimeTechnique.swift
//  BoomBoomBoomKitML
//
//  BNNSGraph tempo model that reads 12 s log-mel crops at 0.01 s per frame,
//  chosen from the whole track by rhythm score.
//

import BoomBoomBoomKit
import Foundation

// MARK: - FixedTimeTechnique

/// A tempo model that reads fixed 12 s crops of the whole track instead of
/// the analysis window resized to 512 columns.
///
/// For each track it builds the crops with
/// ``FeatureSubstrate/FixedTimeCrops/build(decoded:isCancelled:)`` (44.1 kHz, 1200-frame
/// log-mel crops, the at most 4 most rhythmic kept), runs the model once per
/// kept crop, averages the kept crops' softmax, and decodes
/// `bpm = 30 + argmax` of the average. The model must take input
/// `[1, 1, 128, 1200]` named `input` and return 256 logits named `output`.
///
/// The decoded BPM is returned raw, including values outside `60...200`,
/// and the ensemble combiner octave-folds an out-of-range value into that
/// window: the raw-decode option ``MLEvaluation/bpm`` allows. (``BNNSTechnique``
/// takes the other option and abstains on an out-of-range decode.) ``MLEvaluation/confidence`` is the top
/// probability of the averaged softmax. It is **not calibrated**: under a
/// weighted ``EnsemblePolicy`` it may outvote DSP often or rarely.
///
/// The technique reads the decoded track, so it votes only through
/// ``WholeTrackMLTechnique/evaluate(trace:audio:isCancelled:)``, which
/// ``AudioAnalysisService`` calls whenever the ensemble policy invokes ML.
/// Cancellation is checked before each candidate crop's score, before each
/// kept crop's tensor, between 10 s chunks of the 44.1 kHz conversion, and
/// before each inference; once it returns `true` the technique returns
/// `(nil, nil, nil)` and the service throws `CancellationError`.
/// Called without audio (``evaluate(trace:)`` or
/// ``evaluateWithDiagnostic(trace:)``) it abstains.
///
/// Abstains, naming the reason in ``MLInputCropEvidence/abstainReason``, when
/// the track is shorter than one crop, when every candidate crop scores 0,
/// when 44.1 kHz conversion fails, or when inference fails.
///
/// ```swift
/// var options = AudioAnalysisService.Options()
/// options.mlTechnique = try FixedTimeTechnique(modelURL: compiledModelURL)
/// options.ensemblePolicy = .default
/// ```
@available(macOS 15.0, *)
public struct FixedTimeTechnique: WholeTrackMLTechnique, @unchecked Sendable {

  /// Time-axis width of the model input: one crop of
  /// ``FeatureSubstrate/FixedTimeCrops/cropFrames`` frames.
  public static let inputWidth = FeatureSubstrate.FixedTimeCrops.cropFrames

  /// BPM of output bin 0: `bpm = 30 + argmax`.
  private static let bpmBinOffset: Double = 30.0

  private let graph: BNNSTempoGraph

  /// Tag carried on every ``MLEvaluation`` this technique returns: the model
  /// file's name without its extension.
  public let modelIdentifier: String

  /// Loads and compiles the model at `modelURL`.
  ///
  /// - Throws: ``MLTechniqueError/modelResourceMissing(_:)`` when the file
  ///   is absent, ``MLTechniqueError/modelLoadFailed(underlying:)`` when it
  ///   does not compile, ``MLTechniqueError/invalidTensorContract(missing:)``
  ///   when its input is not `[1, 1, 128, 1200]` (a 512-wide
  ///   ``BNNSTechnique`` model throws here), and
  ///   ``MLTechniqueError/binCountMismatch(expected:actual:)`` when its
  ///   output is not 256 elements.
  public init(modelURL: URL) throws {
    self.graph = try BNNSTempoGraph(modelURL: modelURL, inputWidth: Self.inputWidth)
    let basename = modelURL.deletingPathExtension().lastPathComponent
    self.modelIdentifier = basename.isEmpty ? "fixed-time" : basename
  }

  // MARK: - MLTechnique

  /// Abstains: this technique needs the decoded track, which only
  /// ``evaluate(trace:audio:isCancelled:)`` receives.
  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }

  // MARK: - WholeTrackMLTechnique

  public func evaluate(
    trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio,
    isCancelled: @Sendable () -> Bool
  ) -> (
    evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
  ) {
    let cropSet: FeatureSubstrate.FixedTimeCropSet
    do {
      cropSet = try FeatureSubstrate.FixedTimeCrops.build(
        decoded: audio, isCancelled: isCancelled)
    } catch is CancellationError {
      return (nil, nil, nil)
    } catch {
      return (
        nil,
        MLInputCropEvidence(candidates: [], keptCrops: [], abstainReason: .conversionFailed),
        nil
      )
    }
    if let reason = cropSet.abstainReason {
      return (
        nil,
        MLInputCropEvidence(
          candidates: cropSet.candidates, keptCrops: [], abstainReason: reason),
        nil
      )
    }
    let checksum = BNNSTechnique.computeInputFeatureChecksum(
      cropSet.keptTensors.flatMap { $0 })
    let inferenceFailed = MLInputCropEvidence(
      candidates: cropSet.candidates, keptCrops: cropSet.keptCrops,
      abstainReason: .inferenceFailed)

    var probabilities: [[Float]] = []
    for tensor in cropSet.keptTensors {
      if isCancelled() { return (nil, nil, nil) }
      guard let logits = graph.inferLogits(tensor) else {
        return (
          nil, inferenceFailed,
          MLDiagnosticSnapshot(inputFeatureChecksum: checksum, outcome: .graphFailed)
        )
      }
      guard let probs = BNNSTempoGraph.softmax(logits) else {
        return (
          nil, inferenceFailed,
          MLDiagnosticSnapshot(inputFeatureChecksum: checksum, outcome: .decodeRejectedNonFinite)
        )
      }
      probabilities.append(probs)
    }
    let decode = Self.decodeMeanOfSoftmax(probabilities)
    let snapshot = MLDiagnosticSnapshot(
      inputFeatureChecksum: checksum,
      outcome: .win(
        .init(
          bpm: decode.bpm, softmaxMax: decode.topProbability,
          softmaxSecondMax: decode.secondProbability)))
    let evaluation = MLEvaluation(
      bpm: decode.bpm, confidence: min(max(decode.topProbability, 0), 1),
      modelIdentifier: modelIdentifier)
    return (
      evaluation,
      MLInputCropEvidence(
        candidates: cropSet.candidates, keptCrops: cropSet.keptCrops, abstainReason: nil),
      snapshot
    )
  }

  /// Mean of the kept crops' class probabilities, decoded as
  /// `30 + argmax` (ties to the lower bin). Every crop weighs the same.
  /// Returns the raw BPM and the averaged top and second probabilities.
  static func decodeMeanOfSoftmax(
    _ probabilities: [[Float]]
  ) -> (bpm: Double, topProbability: Double, secondProbability: Double) {
    let bins = probabilities.first?.count ?? 0
    var mean = [Double](repeating: 0, count: bins)
    for probs in probabilities {
      for (i, p) in probs.enumerated() { mean[i] += Double(p) }
    }
    let count = Double(max(1, probabilities.count))
    var best = 0
    var top = -Double.infinity
    var second = -Double.infinity
    for (i, sum) in mean.enumerated() {
      let value = sum / count
      if value > top {
        second = top
        top = value
        best = i
      } else if value > second {
        second = value
      }
    }
    return (
      bpm: bpmBinOffset + Double(best),
      topProbability: top.isFinite ? top : 0,
      secondProbability: second.isFinite ? second : 0
    )
  }
}

// MARK: - MLDiagnosticTechnique

@available(macOS 15.0, *)
extension FixedTimeTechnique: MLDiagnosticTechnique {

  /// Abstains with no snapshot: without the decoded track there is no model
  /// input to build. The service reaches the diagnostics through
  /// ``WholeTrackMLTechnique/evaluate(trace:audio:isCancelled:)`` instead.
  public func evaluateWithDiagnostic(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?) {
    (nil, nil)
  }
}
