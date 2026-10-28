//
//  WaveformBandFilter.swift
//  BoomBoomBoomKit
//
//  Story 15.11: the internal pieces of `BandWaveformReader` -- the
//  three-band filter of one channel, the bucket timebase, and the open
//  bucket's running sums of squares. Nothing here is shared with
//  `WaveformAnalyzer`, which uses a different coefficient expression, bin
//  rule, chunking and RMS accumulation.
//

import Accelerate
import Foundation

// MARK: - WaveformBandFilter

/// The low, mid and high bands of one channel: second-order IIR sections at
/// Q = 1/sqrt(2). Low is a 300 Hz low-pass; mid a 250 Hz high-pass then a
/// 1,200 Hz low-pass; high a 3,000 Hz high-pass then, above 18,000 Hz, a
/// 9,000 Hz low-pass. At 18,000 Hz and below that section would be at or past
/// Nyquist, so it is left out.
///
/// Keep one per channel for the whole read and mutate it in place: each band's
/// filter state carries from one `filter(_:)` call to the next, so a file read
/// in chunks filters as one pass. A non-finite sample goes into the filters as
/// `+0.0`.
///
/// The filters run in `Double`: a low cutoff puts the poles close to the unit
/// circle, and in `Float` the rounding differs between one long call and many
/// short ones.
struct WaveformBandFilter {
  static let lowPassCutoff: Double = 300
  static let midHighPassCutoff: Double = 250
  static let midLowPassCutoff: Double = 1_200
  static let highHighPassCutoff: Double = 3_000
  static let highLowPassCutoff: Double = 9_000
  /// Butterworth, 1/sqrt(2), written as `0.5.squareRoot()`: `1 / 2.0.squareRoot()`
  /// is one ulp lower and changes every coefficient.
  static let quality: Double = 0.5.squareRoot()

  private var lowFilter: vDSP.Biquad<Double>
  private var midFilter: vDSP.Biquad<Double>
  private var highFilter: vDSP.Biquad<Double>
  /// Sections in the high band: 2 above 18,000 Hz, 1 at or below it.
  let highSectionCount: Int

  /// The input converted to `Double` with its non-finite samples zeroed, then
  /// each band's output. Grown to the longest input seen and reused; only the
  /// first `count` samples belong to the last call.
  private var input: [Double] = []
  private var lowOutput: [Double] = []
  private var midOutput: [Double] = []
  private var highOutput: [Double] = []
  private var count = 0

  /// `nil` when `sampleRate` is at or below twice the 3,000 Hz high-pass,
  /// where that section is unstable, or when Accelerate cannot set up a filter.
  init?(sampleRate: Double) {
    guard sampleRate > 2 * Self.highHighPassCutoff else { return nil }
    let sections = Self.sections(sampleRate: sampleRate)
    let highSections = sections.high.count / 5
    guard
      let lowFilter = vDSP.Biquad(
        coefficients: sections.low, channelCount: 1, sectionCount: 1, ofType: Double.self),
      let midFilter = vDSP.Biquad(
        coefficients: sections.mid, channelCount: 1, sectionCount: 2, ofType: Double.self),
      let highFilter = vDSP.Biquad(
        coefficients: sections.high, channelCount: 1,
        sectionCount: vDSP_Length(highSections), ofType: Double.self)
    else { return nil }
    self.lowFilter = lowFilter
    self.midFilter = midFilter
    self.highFilter = highFilter
    self.highSectionCount = highSections
  }

  /// The low band of the last `filter(_:)` call's samples.
  var low: Band { Band(samples: lowOutput[..<count]) }

  /// The mid band of the last `filter(_:)` call's samples.
  var mid: Band { Band(samples: midOutput[..<count]) }

  /// The high band of the last `filter(_:)` call's samples.
  var high: Band { Band(samples: highOutput[..<count]) }

  /// Filters the next `samples` of the channel into the three bands, low then
  /// mid then high, each from the same `Double` input.
  ///
  /// `mayContainNonFinite` is `false` only when the samples were decoded from
  /// integer data, which cannot hold NaN or infinity; the non-finite scan is
  /// then skipped. The output is the same either way.
  mutating func filter(_ samples: UnsafeBufferPointer<Float>, mayContainNonFinite: Bool = true) {
    count = samples.count
    if input.count < count {
      input = [Double](repeating: 0, count: count)
      lowOutput = input
      midOutput = input
      highOutput = input
    }
    let count = count
    guard count > 0, let source = samples.baseAddress else { return }
    let hasNonFinite = mayContainNonFinite && Self.containsNonFinite(samples)
    input.withUnsafeMutableBufferPointer { input in
      guard let destination = input.baseAddress else { return }
      // Float to Double is exact, so this matches a per-sample conversion.
      vDSP_vspdp(source, 1, destination, 1, vDSP_Length(count))
      // The scalar fix-up loop runs only when a non-finite sample is present.
      guard hasNonFinite else { return }
      let converted = UnsafeMutableBufferPointer(rebasing: input[..<count])
      for index in converted.indices where !converted[index].isFinite {
        converted[index] = 0
      }
    }
    input.withUnsafeBufferPointer { input in
      let zeroed = UnsafeBufferPointer(rebasing: input[..<count])
      lowOutput.withUnsafeMutableBufferPointer { output in
        var band = UnsafeMutableBufferPointer(rebasing: output[..<count])
        lowFilter.apply(input: zeroed, output: &band)
      }
      midOutput.withUnsafeMutableBufferPointer { output in
        var band = UnsafeMutableBufferPointer(rebasing: output[..<count])
        midFilter.apply(input: zeroed, output: &band)
      }
      highOutput.withUnsafeMutableBufferPointer { output in
        var band = UnsafeMutableBufferPointer(rebasing: output[..<count])
        highFilter.apply(input: zeroed, output: &band)
      }
    }
  }

  /// Whether any sample is NaN or infinite: its exponent bits are all set.
  ///
  /// A scalar scan, by the same exemption from the vDSP-for-bulk-numerics rule
  /// as the PCMBufferReader ingress guard: vDSP has no non-finite detection or
  /// replacement primitive, and a vDSP sum check is not trusted to detect one.
  /// It visits every sample without an early exit, so the compiler can
  /// vectorize it; an early-exit scan costs about 5 percent of a read.
  static func containsNonFinite(_ samples: UnsafeBufferPointer<Float>) -> Bool {
    var found: UInt32 = 0
    for sample in samples {
      found |= (sample.bitPattern & 0x7F80_0000) == 0x7F80_0000 ? 1 : 0
    }
    return found != 0
  }

  // MARK: - Band

  /// One band's filtered samples from the last `filter(_:)` call.
  struct Band {
    let samples: ArraySlice<Double>

    /// The largest magnitude in `span`, indexes into the last call's samples,
    /// clamped to 1. The samples are always finite: the filters only see finite
    /// input, and `init` refuses a rate at which they would be unstable.
    func peak(in span: Range<Int>) -> Float {
      samples.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress, !span.isEmpty else { return 0 }
        var magnitude: Double = 0
        vDSP_maxmgvD(base + span.lowerBound, 1, &magnitude, vDSP_Length(span.count))
        return Float(min(magnitude, 1))
      }
    }

    /// The sum of the squared samples in `span`, indexes into the last call's
    /// samples.
    func sumOfSquares(in span: Range<Int>) -> Double {
      samples.withUnsafeBufferPointer { buffer in
        guard let base = buffer.baseAddress, !span.isEmpty else { return 0 }
        var sum: Double = 0
        vDSP_svesqD(base + span.lowerBound, 1, &sum, vDSP_Length(span.count))
        return sum
      }
    }
  }

  // MARK: - Coefficients

  /// Each band's sections at `sampleRate`, `[b0, b1, b2, a1, a2]` per section,
  /// high-pass first where a band has two.
  static func sections(sampleRate: Double) -> (low: [Double], mid: [Double], high: [Double]) {
    let low = lowPass(lowPassCutoff, sampleRate: sampleRate)
    let mid =
      highPass(midHighPassCutoff, sampleRate: sampleRate)
      + lowPass(midLowPassCutoff, sampleRate: sampleRate)
    var high = highPass(highHighPassCutoff, sampleRate: sampleRate)
    if keepsHighLowPass(sampleRate: sampleRate) {
      high += lowPass(highLowPassCutoff, sampleRate: sampleRate)
    }
    return (low, mid, high)
  }

  /// Whether the high band keeps its 9,000 Hz low-pass: only above 18,000 Hz.
  static func keepsHighLowPass(sampleRate: Double) -> Bool {
    sampleRate > 2 * highLowPassCutoff
  }

  /// `[b0, b1, b2, a1, a2]` for a low-pass section at `cutoff`, divided by a0.
  static func lowPass(_ cutoff: Double, sampleRate: Double) -> [Double] {
    let (cosine, alpha) = shape(cutoff, sampleRate: sampleRate)
    let b = (1 - cosine) / 2
    return normalized([b, 1 - cosine, b, -2 * cosine, 1 - alpha], alpha: alpha)
  }

  /// `[b0, b1, b2, a1, a2]` for a high-pass section at `cutoff`, divided by a0.
  static func highPass(_ cutoff: Double, sampleRate: Double) -> [Double] {
    let (cosine, alpha) = shape(cutoff, sampleRate: sampleRate)
    let b = (1 + cosine) / 2
    return normalized([b, -(1 + cosine), b, -2 * cosine, 1 - alpha], alpha: alpha)
  }

  /// cos(omega) and alpha = sin(omega) / (2Q), with omega = 2 pi f / Fs.
  private static func shape(_ cutoff: Double, sampleRate: Double) -> (
    cosine: Double, alpha: Double
  ) {
    let omega = 2 * Double.pi * cutoff / sampleRate
    return (cos(omega), sin(omega) / (2 * quality))
  }

  /// The section divided by a0 = 1 + alpha.
  private static func normalized(_ section: [Double], alpha: Double) -> [Double] {
    section.map { $0 / (1 + alpha) }
  }
}

// MARK: - WaveformBucketTimebase

/// Bucket `i` holds the frames with `floor(frame * 150 / sampleRate) == i`,
/// counted from the start of the file. Each expression is evaluated left to
/// right exactly as written.
struct WaveformBucketTimebase {
  let sampleRate: Double

  /// The bucket holding absolute frame `frame`.
  func bucket(atFrame frame: Int64) -> Int {
    Int((Double(frame) * BandWaveformReader.bucketsPerSecond / sampleRate).rounded(.down))
  }

  /// The first absolute frame of `bucket`.
  func firstFrame(ofBucket bucket: Int) -> Int64 {
    Int64((Double(bucket) * sampleRate / BandWaveformReader.bucketsPerSecond).rounded(.up))
  }

  /// Buckets for a file `frames` long, the final partial one included.
  func bucketCount(frames: Int64) -> Int {
    frames > 0 ? bucket(atFrame: frames - 1) + 1 : 0
  }
}

// MARK: - WaveformBucketSums

/// The open bucket's running sums of squared band samples, one set per
/// channel, and the frames they cover. Kept across read chunks, so a bucket
/// split between two reads gets the RMS of one; reset only when the bucket
/// changes.
struct WaveformBucketSums {
  /// One channel's sums, band by band.
  private struct Sums {
    var low: Double = 0
    var mid: Double = 0
    var high: Double = 0
  }

  /// The bucket the sums belong to; `nil` before the first span.
  private var bucket: Int?
  private var frames = 0
  private var channels: [Sums]

  init(channelCount: Int) {
    channels = [Sums](repeating: Sums(), count: channelCount)
  }

  /// Adds `span` of each channel's last filtered samples to `bucket`'s sums,
  /// starting the sums afresh when `bucket` is not the open one.
  mutating func add(_ span: Range<Int>, of filters: [WaveformBandFilter], toBucket bucket: Int) {
    if bucket != self.bucket {
      self.bucket = bucket
      frames = 0
      for channel in channels.indices { channels[channel] = Sums() }
    }
    frames += span.count
    for channel in filters.indices {
      channels[channel].low += filters[channel].low.sumOfSquares(in: span)
      channels[channel].mid += filters[channel].mid.sumOfSquares(in: span)
      channels[channel].high += filters[channel].high.sumOfSquares(in: span)
    }
  }

  /// The RMS of the frames added so far, band by band: the louder channel's,
  /// clamped to 1.
  var rootMeanSquare: BandWaveform.Levels {
    guard frames > 0 else { return .silent }
    let frames = Double(frames)
    // Every channel covers the same frames, so the larger sum is the louder
    // channel. Each band's maximum starts from 0 and visits the channels in
    // order.
    var loudest = Sums()
    for sums in channels {
      loudest.low = max(loudest.low, sums.low)
      loudest.mid = max(loudest.mid, sums.mid)
      loudest.high = max(loudest.high, sums.high)
    }
    func level(_ sum: Double) -> Float { Float(min((sum / frames).squareRoot(), 1)) }
    return BandWaveform.Levels(
      low: level(loudest.low), mid: level(loudest.mid), high: level(loudest.high))
  }
}
