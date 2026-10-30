//
//  FixedTimeCrops.swift
//  BoomBoomBoomKit
//
//  The fixed-time model input: 12 s log-mel crops at 0.01 s per frame,
//  ranked by the rhythm score over the whole track.
//

import Accelerate
import Foundation

extension FeatureSubstrate {

  /// Builds the input for a fixed-time tempo model: 1200-frame log-mel crops
  /// at the native 0.01 s per frame, never resized, ranked by the library's
  /// rhythm score over the whole decoded track.
  ///
  /// The input contract:
  /// - Audio is converted to 44.1 kHz mono first (any other rate is resampled
  ///   inside the library).
  /// - The log-mel is the substrate's (``OnsetFeaturesBuilder``): FFT 2048,
  ///   hop 441 samples, 128 mel bands from 30 Hz to 16 kHz, uncentered frames,
  ///   `log(1 + 100 x)`.
  /// - A crop is exactly ``cropFrames`` (1200) frames, which is
  ///   ``cropSamples`` (530,807) samples, about 12.04 s.
  /// - Candidate crops start every ``cropHopFrames`` (600) frames while they
  ///   fit. When those do not reach the last frame, one tail crop ends on it.
  ///   A track with fewer than 1200 frames has no crop.
  /// - Each candidate is scored on its own samples with the rhythm score the
  ///   analyzer uses to pick its analysis regions.
  /// - At most ``maxKeptCrops`` (4) crops are kept, walking the ranking by
  ///   score (ties to the earlier start), each scoring above 0 and at least
  ///   ``keepFractionOfBest`` of the best, and skipping any crop that shares
  ///   a frame with one already kept.
  /// - Each kept crop is transposed to mel-major `[128, 1200]` and z-scored
  ///   per band (population standard deviation; a band whose standard
  ///   deviation is 0 or not finite is set to 0).
  ///
  /// A crop starting at frame `s` covers samples `[441 s, 441 s + 530,807)`,
  /// so its log-mel is computed from that slice alone.
  public enum FixedTimeCrops {

    /// Sample rate every crop is computed at.
    public static let sampleRate: Double = 44_100
    /// Mel bands per frame.
    public static let melBands = 128
    /// FFT size of the log-mel.
    public static let fftSize = 2048
    /// Hop between log-mel frames, in samples (10 ms at 44.1 kHz).
    public static let hopSamples = 441
    /// Frames per crop.
    public static let cropFrames = 1200
    /// Frames between the starts of neighbouring candidate crops.
    public static let cropHopFrames = 600
    /// Samples behind one crop: the fewest an uncentered STFT turns into
    /// 1200 frames.
    public static let cropSamples = (cropFrames - 1) * hopSamples + fftSize
    /// The most crops kept per track.
    public static let maxKeptCrops = 4
    /// A kept crop scores at least this fraction of the track's best crop.
    public static let keepFractionOfBest: Float = 0.5

    /// Log-mel frames an uncentered STFT produces for `sampleCount` samples
    /// at 44.1 kHz (0 below one FFT).
    public static func frameCount(sampleCount: Int) -> Int {
      guard sampleCount >= fftSize else { return 0 }
      return (sampleCount - fftSize) / hopSamples + 1
    }

    /// Start frames of the candidate crops for a track of `frameCount`
    /// frames: every 600 frames while a crop fits, plus one tail crop ending
    /// on the last frame when those stop short. Empty below 1200 frames.
    public static func candidateStarts(frameCount: Int) -> [Int] {
      guard frameCount >= cropFrames else { return [] }
      var starts = Array(stride(from: 0, through: frameCount - cropFrames, by: cropHopFrames))
      if let last = starts.last, last + cropFrames < frameCount {
        starts.append(frameCount - cropFrames)
      }
      return starts
    }

    /// The rhythm score of the crop starting at `startFrame` of 44.1 kHz
    /// `samples`, computed on the crop's own 530,807 samples by the same
    /// function the analyzer uses to choose its analysis regions. Returns 0
    /// when the crop overruns `samples`.
    public static func rhythmScore(samples: [Float], startFrame: Int) -> Float {
      guard cropFits(startFrame: startFrame, sampleCount: samples.count) else { return 0 }
      return RhythmicRegionSelector.score(
        samples: samples, start: startFrame * hopSamples, count: cropSamples,
        sampleRate: sampleRate)
    }

    /// Whether the crop starting at `startFrame` lies inside `sampleCount`
    /// samples. Checked before `startFrame * hopSamples` is formed, so an
    /// out-of-range frame cannot overflow.
    static func cropFits(startFrame: Int, sampleCount: Int) -> Bool {
      sampleCount >= cropSamples && startFrame >= 0
        && startFrame <= (sampleCount - cropSamples) / hopSamples
    }

    /// The kept crops in rank order: at most 4, by score with ties to the
    /// earlier start, each above 0 and at least half the best, and sharing
    /// no frame with a crop already kept. A best score of 0 keeps nothing.
    public static func rank(_ candidates: [MLInputCrop]) -> [MLInputCrop] {
      let order = candidates.sorted {
        if $0.rhythmScore != $1.rhythmScore { return $0.rhythmScore > $1.rhythmScore }
        return $0.startFrame < $1.startFrame
      }
      guard let best = order.first, best.rhythmScore > 0 else { return [] }
      let floor = keepFractionOfBest * best.rhythmScore
      var kept: [MLInputCrop] = []
      for crop in order {
        guard kept.count < maxKeptCrops, crop.rhythmScore > 0, crop.rhythmScore >= floor
        else { break }
        if kept.allSatisfy({ abs($0.startFrame - crop.startFrame) >= cropFrames }) {
          kept.append(crop)
        }
      }
      return kept
    }

    /// `decoded` as 44.1 kHz mono samples. Audio already at 44.1 kHz is
    /// returned as is; any other rate is converted with `AVAudioConverter`.
    ///
    /// - Throws: ``FeatureSubstrateError/featurizationFailed(reason:)`` when
    ///   the conversion fails.
    public static func samplesAt44k(_ decoded: DecodedAudio) throws -> [Float] {
      if decoded.sampleRate == sampleRate || decoded.samples.isEmpty { return decoded.samples }
      do {
        return try PCMBufferReader.resampleMono(
          decoded.samples, fromRate: decoded.sampleRate, toRate: sampleRate)
      } catch {
        throw FeatureSubstrateError.featurizationFailed(
          reason: "converting \(decoded.sampleRate) Hz audio to 44.1 kHz failed: \(error)")
      }
    }

    /// The z-scored mel-major `[128, 1200]` tensor (row-major, band 0 first)
    /// of the crop starting at `startFrame` of 44.1 kHz `samples`.
    ///
    /// - Throws: ``FeatureSubstrateError/featurizationFailed(reason:)`` when
    ///   the crop overruns `samples` or the log-mel does not have the
    ///   contract's shape.
    public static func cropTensor(samples: [Float], startFrame: Int) throws -> [Float] {
      guard cropFits(startFrame: startFrame, sampleCount: samples.count) else {
        throw FeatureSubstrateError.featurizationFailed(
          reason: "crop at frame \(startFrame) needs \(cropSamples) samples from sample "
            + "441 x \(startFrame); audio has \(samples.count)")
      }
      let begin = startFrame * hopSamples
      let slice = DecodedAudio(
        samples: Array(samples[begin..<(begin + cropSamples)]),
        sampleRate: sampleRate,
        codecPriming: PrimingInfo(codec: .linearPCM, trimState: .knownNone))
      let onset = try OnsetFeaturesBuilder.build(decoded: slice, weighting: .uniform)
      guard onset.melBands == melBands, onset.frames == cropFrames,
        onset.tensorLayout == .frameMajorLogMel,
        onset.parameters.hopSize == hopSamples, onset.parameters.fftSize == fftSize
      else {
        throw FeatureSubstrateError.featurizationFailed(
          reason: "crop log-mel is \(onset.melBands) x \(onset.frames) "
            + "(\(onset.tensorLayout), hop \(onset.parameters.hopSize), "
            + "FFT \(onset.parameters.fftSize)); the fixed-time contract needs "
            + "\(melBands) x \(cropFrames), frame-major, hop \(hopSamples), FFT \(fftSize)")
      }
      return zscoredMelMajor(frameMajor: onset.logMelData)
    }

    /// Scores every candidate crop of `decoded`, ranks them, and builds the
    /// kept crops' tensors.
    ///
    /// - Throws: ``FeatureSubstrateError/featurizationFailed(reason:)`` when
    ///   the 44.1 kHz conversion or a crop's log-mel fails.
    public static func build(decoded: DecodedAudio) throws -> FixedTimeCropSet {
      let samples = try samplesAt44k(decoded)
      let frames = frameCount(sampleCount: samples.count)
      let candidates = candidateStarts(frameCount: frames).map { start in
        MLInputCrop(
          startFrame: start,
          startSeconds: Double(start * hopSamples) / sampleRate,
          durationSeconds: Double(cropSamples) / sampleRate,
          rhythmScore: rhythmScore(samples: samples, startFrame: start))
      }
      let kept = rank(candidates)
      let tensors = try kept.map { try cropTensor(samples: samples, startFrame: $0.startFrame) }
      return FixedTimeCropSet(
        frameCount: frames, candidates: candidates, keptCrops: kept, keptTensors: tensors)
    }

    /// Frame-major `[1200 * 128]` log-mel to mel-major `[128 * 1200]`,
    /// z-scored per band.
    static func zscoredMelMajor(frameMajor: [Float]) -> [Float] {
      var melMajor = [Float](repeating: 0, count: melBands * cropFrames)
      frameMajor.withUnsafeBufferPointer { src in
        melMajor.withUnsafeMutableBufferPointer { dst in
          guard let srcBase = src.baseAddress, let dstBase = dst.baseAddress else { return }
          vDSP_mtrans(srcBase, 1, dstBase, 1, vDSP_Length(melBands), vDSP_Length(cropFrames))
        }
      }
      zscorePerBand(&melMajor, bands: melBands, frames: cropFrames)
      return melMajor
    }

    /// Per-band population z-score of a mel-major `[bands, frames]` buffer, in
    /// place. A band whose standard deviation is 0 or not finite is set to 0.
    static func zscorePerBand(_ melMajor: inout [Float], bands: Int, frames: Int) {
      melMajor.withUnsafeMutableBufferPointer { buf in
        guard let base = buf.baseAddress else { return }
        var mean: Float = 0
        var stddev: Float = 0
        for band in 0..<bands {
          let row = base + band * frames
          vDSP_normalize(row, 1, row, 1, &mean, &stddev, vDSP_Length(frames))
          if stddev == 0 || !stddev.isFinite {
            vDSP_vclr(row, 1, vDSP_Length(frames))
          }
        }
      }
    }
  }

  /// The output of ``FixedTimeCrops/build(decoded:)`` for one track.
  public struct FixedTimeCropSet: Sendable {
    /// Log-mel frames in the 44.1 kHz track.
    public let frameCount: Int
    /// Every candidate crop in time order, with its rhythm score.
    public let candidates: [MLInputCrop]
    /// The kept crops in rank order (best first).
    public let keptCrops: [MLInputCrop]
    /// One z-scored mel-major `[128, 1200]` tensor per kept crop, in the same
    /// order as ``keptCrops``.
    public let keptTensors: [[Float]]

    public init(
      frameCount: Int, candidates: [MLInputCrop], keptCrops: [MLInputCrop],
      keptTensors: [[Float]]
    ) {
      self.frameCount = frameCount
      self.candidates = candidates
      self.keptCrops = keptCrops
      self.keptTensors = keptTensors
    }

    /// Why a model has no input from this track: shorter than one crop, or
    /// no candidate with a rhythm score above 0. `nil` when at least one
    /// crop was kept.
    public var abstainReason: MLInputCropEvidence.AbstainReason? {
      if candidates.isEmpty { return .shorterThanCrop }
      if keptCrops.isEmpty { return .noRhythmicCrop }
      return nil
    }
  }
}
