//
//  WaveformBandLevels.swift
//  BoomBoomBoomKit
//
//  Story 15.11: the result of `WaveformBandLevelReader.read(url:options:)`.
//  Low, mid and high band peak and RMS per 1/150 s bucket, plus where the
//  decoded audio came from. The file format for these values lives in
//  `WaveformBandLevelsFile.swift`.
//

import Foundation

// MARK: - WaveformBandLevel

/// One bucket's level in each of the three bands, linear amplitude from 0 to 1.
///
/// Used for both the peak and the RMS arrays of ``WaveformBandLevels``. The
/// low band is a 300 Hz low-pass, the mid band a 250 Hz high-pass followed by
/// a 1,200 Hz low-pass, and the high band a 3,000 Hz high-pass followed by a
/// 9,000 Hz low-pass (left out at sample rates of 18,000 Hz and below).
public struct WaveformBandLevel: Sendable, Hashable {
  /// The low band's level.
  public var low: Float
  /// The mid band's level.
  public var mid: Float
  /// The high band's level.
  public var high: Float

  /// Creates a level from its three band values.
  ///
  /// - Parameters:
  ///   - low: The low band's level.
  ///   - mid: The mid band's level.
  ///   - high: The high band's level.
  public init(low: Float, mid: Float, high: Float) {
    self.low = low
    self.mid = mid
    self.high = high
  }

  /// All three bands at 0.
  public static let silent = WaveformBandLevel(low: 0, mid: 0, high: 0)
}

// MARK: - WaveformAudioSource

/// Where the decoded audio of a ``WaveformBandLevels`` result came from.
///
/// Diagnostics only: nothing in the library rejects stored levels because
/// this value differs from a fresh read.
public struct WaveformAudioSource: Sendable, Hashable {
  /// The file's encoded format (`mFormatID` of the file format, not the
  /// processing format), so a FLAC file reports the FLAC codec rather than
  /// linear PCM.
  public let formatID: UInt32
  /// The format the samples were decoded into, built from its fields:
  /// `"<commonFormat> <interleaved|deinterleaved> <channelCount>ch <sampleRate>Hz"`,
  /// for example `"float32 deinterleaved 2ch 44100.0Hz"`. `commonFormat` is
  /// one of `float32`, `float64`, `int16`, `int32` or `other`.
  public let processingFormat: String

  /// Creates a source description.
  ///
  /// - Parameters:
  ///   - formatID: The file's encoded format ID.
  ///   - processingFormat: The decoded format, as described on
  ///     ``processingFormat``.
  public init(formatID: UInt32, processingFormat: String) {
    self.formatID = formatID
    self.processingFormat = processingFormat
  }
}

// MARK: - WaveformBandLevels

/// A file's low, mid and high band peak and RMS levels, 150 buckets per
/// second, as measured by ``WaveformBandLevelReader``.
///
/// Each channel is filtered into three bands. For every bucket and band,
/// ``peak`` holds the largest magnitude of any channel and ``rms`` holds the
/// root mean square of the louder channel over the bucket's frames. Values are
/// linear amplitude, clamped to `0...1`. Bucket `i` starts at `i / 150`
/// seconds from the start of the file; the final bucket may be partial, and
/// its RMS covers the frames it holds.
///
/// ``frameCount`` comes from the file's header. When the file decodes fewer
/// frames than that and the decoder reports the end-of-file status
/// (`NSOSStatusErrorDomain` -39), ``framesRead`` is smaller, the buckets past
/// the real end stay ``WaveformBandLevel/silent``, and the bucket count still
/// follows the header. Otherwise the read throws
/// `PCMBufferReaderError.readFailed`.
///
/// On one machine the same decoded samples always give the same bits. Lossy
/// decoders may not return identical samples on every read.
///
/// ``encoded(forKey:)`` and ``decoded(from:forKey:)`` turn a result into bytes
/// and back. The caller chooses where the bytes are stored; the library never
/// writes to disk.
public struct WaveformBandLevels: Sendable, Hashable {
  /// Each bucket's largest magnitude per band over every channel.
  public let peak: [WaveformBandLevel]
  /// Each bucket's RMS per band, taken from the louder channel.
  public let rms: [WaveformBandLevel]
  /// Buckets per second of audio. Always
  /// ``WaveformBandLevelReader/bucketsPerSecond``.
  public let bucketsPerSecond: Double
  /// The file's sample rate in Hz.
  public let sampleRate: Double
  /// The file's channel count.
  public let channelCount: Int
  /// The file's length in frames, from its header.
  public let frameCount: Int64
  /// The frames that went into buckets. Less than ``frameCount`` when the file
  /// ended before its header said it would.
  public let framesRead: Int64
  /// The measurement version these values were produced under. Always
  /// ``WaveformBandLevelReader/analysisVersion``.
  public let analysisVersion: String
  /// Where the decoded audio came from.
  public let source: WaveformAudioSource

  /// The largest ``WaveformAudioSource/processingFormat`` the result accepts,
  /// in UTF-8 bytes. Keeps every accepted result's encoded header small.
  static let maximumProcessingFormatBytes = 256

  /// A result's sample rate must be above this, in Hz: the reader refuses
  /// rates at or below it.
  static let minimumSampleRateExclusive: Double = 6_000

  /// Creates a result after checking every invariant, or returns `nil`.
  ///
  /// Use it to build levels without reading a file, for example in tests.
  /// ``bucketsPerSecond`` and ``analysisVersion`` are set to the reader's
  /// current constants.
  ///
  /// Returns `nil` unless all of these hold: `sampleRate` is finite and above
  /// 6,000 Hz; `peak` and `rms` each hold exactly the bucket count
  /// `frameCount` gives at 150 buckets per second; `channelCount` is at least
  /// 1; `frameCount` is not negative; `framesRead` is between 0 and
  /// `frameCount`; every value is finite and in `0...1`; and
  /// `source.processingFormat` is at most 256 UTF-8 bytes.
  ///
  /// - Parameters:
  ///   - peak: Each bucket's peak levels.
  ///   - rms: Each bucket's RMS levels.
  ///   - sampleRate: The sample rate in Hz.
  ///   - channelCount: The channel count.
  ///   - frameCount: The length in frames, from the file's header.
  ///   - framesRead: The frames that went into buckets.
  ///   - source: Where the decoded audio came from.
  public init?(
    peak: [WaveformBandLevel],
    rms: [WaveformBandLevel],
    sampleRate: Double,
    channelCount: Int,
    frameCount: Int64,
    framesRead: Int64,
    source: WaveformAudioSource
  ) {
    guard sampleRate.isFinite, sampleRate > Self.minimumSampleRateExclusive,
      let bucketCount = Self.bucketCount(frameCount: frameCount, sampleRate: sampleRate),
      peak.count == bucketCount, rms.count == bucketCount,
      channelCount >= 1,
      frameCount >= 0,
      framesRead >= 0, framesRead <= frameCount,
      source.processingFormat.utf8.count <= Self.maximumProcessingFormatBytes,
      peak.allSatisfy(Self.isValid), rms.allSatisfy(Self.isValid)
    else { return nil }
    self.init(
      measuredPeak: peak, rms: rms, sampleRate: sampleRate, channelCount: channelCount,
      frameCount: frameCount, framesRead: framesRead, source: source)
  }

  /// The reader's init: its values are finite and clamped by construction, so
  /// only the counts are asserted.
  init(
    measuredPeak peak: [WaveformBandLevel],
    rms: [WaveformBandLevel],
    sampleRate: Double,
    channelCount: Int,
    frameCount: Int64,
    framesRead: Int64,
    source: WaveformAudioSource
  ) {
    assert(peak.count == rms.count)
    assert(peak.count == Self.bucketCount(frameCount: frameCount, sampleRate: sampleRate))
    assert(framesRead >= 0 && framesRead <= frameCount)
    self.peak = peak
    self.rms = rms
    self.bucketsPerSecond = WaveformBandLevelReader.bucketsPerSecond
    self.sampleRate = sampleRate
    self.channelCount = channelCount
    self.frameCount = frameCount
    self.framesRead = framesRead
    self.analysisVersion = WaveformBandLevelReader.analysisVersion
    self.source = source
  }

  // MARK: - Invariant helpers

  /// The bucket count of a file `frameCount` frames long at `sampleRate`, by
  /// the reader's rule, or `nil` when it cannot be represented: a negative
  /// `frameCount`, or a rate so small the count overflows `Int`. Never traps.
  static func bucketCount(frameCount: Int64, sampleRate: Double) -> Int? {
    guard frameCount >= 0 else { return nil }
    guard frameCount > 0 else { return 0 }
    let lastBucket =
      (Double(frameCount - 1) * WaveformBandLevelReader.bucketsPerSecond / sampleRate)
      .rounded(.down)
    guard let last = Int(exactly: lastBucket) else { return nil }
    let (count, overflow) = last.addingReportingOverflow(1)
    return overflow ? nil : count
  }

  /// Whether every band of `level` is finite and in `0...1`.
  private static func isValid(_ level: WaveformBandLevel) -> Bool {
    (0...1).contains(level.low) && (0...1).contains(level.mid) && (0...1).contains(level.high)
  }
}
