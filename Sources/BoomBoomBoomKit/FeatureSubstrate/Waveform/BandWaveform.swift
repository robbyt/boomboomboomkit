//
//  BandWaveform.swift
//  BoomBoomBoomKit
//
//  Story 15.11: the result of `BandWaveformReader.read(url:options:)`.
//  Low, mid and high band peak and RMS per 1/150 s bucket, plus where the
//  decoded audio came from, and the bucket time queries. The file format for
//  these values lives in `BandWaveform+Serialization.swift`.
//

import Foundation

// MARK: - BandWaveform

/// A file's low, mid and high band peak and RMS levels, 150 buckets per
/// second, as measured by ``BandWaveformReader``.
///
/// Each channel is filtered into three bands. For every bucket and band,
/// ``peak`` holds the largest magnitude of any channel and ``rms`` holds the
/// root mean square of the louder channel over the bucket's frames. Values are
/// linear amplitude, clamped to `0...1`. `waveform.peak[i]` is a ``Levels``
/// with `low`, `mid` and `high`, also reachable as `waveform.peak[i][.mid]`
/// through ``Band``.
///
/// Bucket `i` starts at the first frame at or after `i / 150` seconds, so it
/// does not start at exactly `i / 150` s unless that time falls on a whole
/// frame. Use ``startTime(ofBucket:)`` and ``bucket(at:)`` instead of dividing
/// by ``bucketsPerSecond``: they use the reader's own frame arithmetic. The
/// final bucket may be partial, and its RMS covers the frames it holds.
///
/// ``frameCount`` comes from the file's header. When the file decodes fewer
/// frames than that and the decoder reports an early end (see
/// ``BandWaveformReader``), ``framesRead`` is smaller, the buckets past
/// the real end stay ``Levels/silent``, and the bucket count still follows the
/// header. Otherwise the read throws `PCMBufferReaderError.readFailed`.
///
/// On one machine the same decoded samples always give the same bits. Lossy
/// decoders may not return identical samples on every read.
///
/// ``serializedData()`` and ``init(serializedData:)`` turn a waveform into
/// bytes and back. The library never stores anything: the caller chooses the
/// cache key and the store (a file in its own folder, a database blob,
/// memory). A `nil` from ``init(serializedData:)`` means discard the stored
/// bytes and measure again.
public struct BandWaveform: Sendable, Hashable {
  /// Each bucket's largest magnitude per band over every channel.
  public let peak: [Levels]
  /// Each bucket's RMS per band, taken from the louder channel.
  public let rms: [Levels]
  /// Buckets per second of audio. Always
  /// ``BandWaveformReader/bucketsPerSecond``.
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
  /// ``BandWaveformReader/analysisVersion``.
  public let analysisVersion: String
  /// Where the decoded audio came from.
  public let source: Source

  /// The largest ``Source/processingFormat`` the waveform accepts, in UTF-8
  /// bytes. Keeps every accepted waveform's serialized header small.
  static let maximumProcessingFormatBytes = 256

  /// A waveform's sample rate must be above this, in Hz: the reader refuses
  /// rates at or below it.
  static let minimumSampleRateExclusive: Double = 6_000

  /// Creates a waveform after checking every invariant, or returns `nil`.
  ///
  /// Use it to build a waveform without reading a file, for example in tests.
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
    peak: [Levels],
    rms: [Levels],
    sampleRate: Double,
    channelCount: Int,
    frameCount: Int64,
    framesRead: Int64,
    source: Source
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
    measuredPeak peak: [Levels],
    rms: [Levels],
    sampleRate: Double,
    channelCount: Int,
    frameCount: Int64,
    framesRead: Int64,
    source: Source
  ) {
    assert(peak.count == rms.count)
    assert(peak.count == Self.bucketCount(frameCount: frameCount, sampleRate: sampleRate))
    assert(framesRead >= 0 && framesRead <= frameCount)
    self.peak = peak
    self.rms = rms
    self.bucketsPerSecond = BandWaveformReader.bucketsPerSecond
    self.sampleRate = sampleRate
    self.channelCount = channelCount
    self.frameCount = frameCount
    self.framesRead = framesRead
    self.analysisVersion = BandWaveformReader.analysisVersion
    self.source = source
  }

  // MARK: - Time

  /// The file's length in seconds, `Double(frameCount) / sampleRate`.
  ///
  /// Follows the header's length, so it includes any frames past an early end
  /// of file. `0` for a waveform of 0 frames.
  public var duration: Double { Double(frameCount) / sampleRate }

  /// The time, in seconds from the start of the file, at which `bucket`
  /// starts: its first frame divided by ``sampleRate``.
  ///
  /// The first frame of bucket `i` is the first frame the reader put in it:
  /// the first frame at or after `i / 150` seconds, give or take one frame at
  /// a few boundaries of a non-integral sample rate, where the reader's two
  /// rounding steps disagree. So the result is not exactly `i / 150` unless
  /// that time falls on a whole frame. It is the reader's own boundary, so
  /// `bucket(at: startTime(ofBucket: i)!) == i`.
  ///
  /// Exact for a file read in full 65,536-frame chunks, which is how
  /// ``BandWaveformReader`` reads every file whose reads return all the frames
  /// asked for. If a read ever returned fewer frames without an error, a later
  /// boundary at one of those disagreeing frames could be off by one frame.
  ///
  /// Returns `nil` when `bucket` is negative or not below `peak.count`, which
  /// includes every bucket of an empty waveform.
  ///
  /// - Parameter bucket: An index into ``peak`` and ``rms``.
  /// - Returns: The start time in seconds, or `nil`.
  public func startTime(ofBucket bucket: Int) -> Double? {
    guard bucket >= 0, bucket < peak.count else { return nil }
    return Double(timebase.spanFirstFrame(ofBucket: bucket, chunkFrames: Self.chunkFrames))
      / sampleRate
  }

  /// The bucket holding the frame that plays at `seconds` from the start of
  /// the file.
  ///
  /// The frame at `seconds` is the last frame whose start time
  /// (`Double(frame) / sampleRate`) is not after `seconds`; the bucket is the
  /// one the reader put that frame in, including at the boundaries where its
  /// two rounding steps disagree. The returned bucket's
  /// ``startTime(ofBucket:)`` is never after `seconds`, and the next bucket's
  /// is after it. Bucket `i` does not cover exactly `i / 150 ..< (i + 1) / 150`
  /// seconds; see ``startTime(ofBucket:)``.
  ///
  /// Returns `nil` when `seconds` is not finite (NaN or infinite), is
  /// negative, or is at or after ``duration``, which includes every time for
  /// an empty waveform.
  ///
  /// - Parameter seconds: A time from the start of the file.
  /// - Returns: An index into ``peak`` and ``rms``, or `nil`.
  public func bucket(at seconds: Double) -> Int? {
    guard seconds.isFinite, seconds >= 0, seconds < duration,
      var frame = Int64(exactly: (seconds * sampleRate).rounded(.down))
    else { return nil }
    // `seconds * sampleRate` is rounded, so the floor can be one frame off in
    // either direction. Settle on the last frame whose start time is not after
    // `seconds`, comparing start times computed the way `startTime` does.
    if frame > 0, Double(frame) / sampleRate > seconds { frame -= 1 }
    if frame < frameCount, Double(frame + 1) / sampleRate <= seconds { frame += 1 }
    guard frame >= 0, frame < frameCount else { return nil }
    let bucket = timebase.spanBucket(atFrame: frame, chunkFrames: Self.chunkFrames)
    return bucket >= 0 && bucket < peak.count ? bucket : nil
  }

  /// The reader's frame and bucket arithmetic at this waveform's rate.
  private var timebase: WaveformBucketTimebase { WaveformBucketTimebase(sampleRate: sampleRate) }

  /// The reader's chunk size, which decides where a span can start.
  private static let chunkFrames = Int64(BandWaveformReader.chunkFrames)

  // MARK: - Invariant helpers

  /// The bucket count of a file `frameCount` frames long at `sampleRate`, by
  /// the reader's rule, or `nil` when it cannot be represented: a negative
  /// `frameCount`, or a rate so small the count overflows `Int`. Never traps.
  static func bucketCount(frameCount: Int64, sampleRate: Double) -> Int? {
    guard frameCount >= 0 else { return nil }
    guard frameCount > 0 else { return 0 }
    let lastBucket =
      (Double(frameCount - 1) * BandWaveformReader.bucketsPerSecond / sampleRate)
      .rounded(.down)
    guard let last = Int(exactly: lastBucket) else { return nil }
    let (count, overflow) = last.addingReportingOverflow(1)
    return overflow ? nil : count
  }

  /// Whether every band of `levels` is finite and in `0...1`.
  private static func isValid(_ levels: Levels) -> Bool {
    (0...1).contains(levels.low) && (0...1).contains(levels.mid)
      && (0...1).contains(levels.high)
  }
}

// MARK: - BandWaveform.Band

extension BandWaveform {
  /// One of the three bands, for code that loops over them:
  /// `for band in BandWaveform.Band.allCases { draw(levels[band]) }`.
  public enum Band: String, CaseIterable, Sendable, Hashable {
    /// A 300 Hz low-pass.
    case low
    /// A 250 Hz high-pass followed by a 1,200 Hz low-pass.
    case mid
    /// A 3,000 Hz high-pass followed by a 9,000 Hz low-pass. At sample rates of
    /// 18,000 Hz and below only the 9,000 Hz low-pass is left out; the band is
    /// still measured.
    case high
  }
}

// MARK: - BandWaveform.Levels

extension BandWaveform {
  /// One bucket's level in each of the three bands, linear amplitude from 0
  /// to 1.
  ///
  /// Used for both the ``BandWaveform/peak`` and the ``BandWaveform/rms``
  /// arrays. Read a band by name (`levels.mid`) or through
  /// ``BandWaveform/Band`` (`levels[.mid]`).
  public struct Levels: Sendable, Hashable {
    /// The low band's level.
    public var low: Float
    /// The mid band's level.
    public var mid: Float
    /// The high band's level.
    public var high: Float

    /// Creates levels from the three band values.
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
    public static let silent = Levels(low: 0, mid: 0, high: 0)

    /// The level of `band`: ``low``, ``mid`` or ``high``.
    public subscript(band: Band) -> Float {
      get {
        switch band {
        case .low: return low
        case .mid: return mid
        case .high: return high
        }
      }
      set {
        switch band {
        case .low: low = newValue
        case .mid: mid = newValue
        case .high: high = newValue
        }
      }
    }
  }
}

// MARK: - BandWaveform.Source

extension BandWaveform {
  /// Where the decoded audio of a ``BandWaveform`` came from.
  ///
  /// Diagnostics only: nothing in the library rejects a stored waveform because
  /// this value differs from a fresh read.
  public struct Source: Sendable, Hashable {
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
}
