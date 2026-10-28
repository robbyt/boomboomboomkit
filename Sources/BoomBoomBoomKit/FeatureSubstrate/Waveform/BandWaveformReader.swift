//
//  BandWaveformReader.swift
//  BoomBoomBoomKit
//
//  Story 15.11: streams an audio file in fixed 65,536-frame chunks and
//  measures each 1/150 s bucket's low, mid and high band peak and RMS, every
//  channel kept, the louder channel per band.
//

@preconcurrency import AVFoundation
import Accelerate
import Foundation

/// Reads a file's three-band waveform: low, mid and high band peak and
/// RMS, 150 values per second.
///
/// What is measured: each channel is filtered into three bands (a 300 Hz
/// low-pass; a 250 Hz high-pass then a 1,200 Hz low-pass; a 3,000 Hz high-pass
/// then, above 18,000 Hz, a 9,000 Hz low-pass). For each 1/150 s bucket and
/// each band, the peak is the largest magnitude of any channel and the RMS is
/// the louder channel's root mean square. Channels are never summed or mixed.
/// Values are linear amplitude clamped to `0...1`, with no gain, floor or
/// compression. A NaN or infinite sample is measured as 0.
///
/// The cadence and the read chunk are fixed, not options: 150 buckets per
/// second (``bucketsPerSecond``) and 65,536 frames per read. The values depend
/// on both, and ``analysisVersion`` names this measurement; any change that
/// could change a value gets a new version.
///
/// The file is streamed: memory holds one 65,536-frame chunk, four 65,536-sample
/// `Double` filter buffers per channel (about 2 MiB per channel), and the two
/// output arrays, never the whole decoded file. A header that claims more than
/// 12 hours is refused before anything is allocated from it.
///
/// Caching: the library never stores anything. To keep a result, call
/// ``BandWaveform/serializedData()`` and store the bytes under a key and in a
/// store the caller chooses (a file in its own folder, a database blob,
/// memory). ``BandWaveform/init(serializedData:)`` returns `nil` for bytes that
/// cannot be used; discard them and measure again.
///
/// Cancellation: ``Options/isCancelled`` is checked before each chunk, and a
/// `true` throws `CancellationError`. A file whose header states 0 frames
/// returns an empty result without checking it.
///
/// Early end of file: when a file decodes fewer frames than its header states
/// and a read after the first chunk fails with an early-end error, the buckets
/// measured before the real end are kept, the remaining buckets
/// stay ``BandWaveform/Levels/silent``, and ``BandWaveform/framesRead`` is
/// less than ``BandWaveform/frameCount``. Two errors count as an early end,
/// because macOS versions differ: `NSOSStatusErrorDomain` -39 (`eofErr`,
/// macOS 27) and Foundation's generic nil error, a failed read with no error
/// object (macOS 26 and earlier). Any other failure, and any failure on the
/// first chunk, throws `PCMBufferReaderError.readFailed`.
///
/// Exactness: on one machine the same decoded samples always give the same
/// bits. Lossy decoders may not return identical samples on every read, and DSP
/// output can differ between macOS versions.
public enum BandWaveformReader: Sendable {
  /// Buckets per second of audio. Fixed.
  public static let bucketsPerSecond: Double = 150

  /// Names the measurement: the filter bank, the bucket rule, the read chunk,
  /// the peak and RMS rules, the louder-channel rule and the non-finite rule.
  /// Changes whenever any stored value could change, which makes every
  /// waveform serialized under an earlier version unusable
  /// (``BandWaveform/init(serializedData:)`` returns `nil`; discard and
  /// measure again).
  public static let analysisVersion = "band-peak-rms.loudest-channel.v1"

  /// Frames decoded per read. Fixed: the filter output depends on where the
  /// chunk boundaries fall.
  static let chunkFrames: AVAudioFrameCount = 65_536

  /// The longest file the reader measures, 12 hours, from the header's length.
  /// Bounds the output arrays (about 155 MB at the limit) when a damaged header
  /// claims far more frames than the file holds.
  static let maximumDurationSeconds: Double = 43_200

  /// `eofErr`, the `NSOSStatusErrorDomain` code `AVAudioFile.read(into:)`
  /// throws for a read past the frames the file really holds.
  static let endOfFileStatus = -39

  /// Configuration for ``read(url:options:)``.
  public struct Options: Sendable {
    /// Checked before each 65,536-frame chunk; `true` stops the read with
    /// `CancellationError`. Defaults to the current task's cancellation state.
    public var isCancelled: @Sendable () -> Bool = { Task.isCancelled }

    /// Creates options with the defaults.
    public init() {}
  }

  /// Reads the file at `url` and measures its band waveform.
  ///
  /// - Parameters:
  ///   - url: The audio file. Any format `AVAudioFile` decodes.
  ///   - options: ``Options``, for cancellation.
  /// - Returns: The waveform, one bucket per 1/150 s of the header's length.
  /// - Throws: `PCMBufferReaderError.fileNotReadable` when the file cannot be
  ///   opened; ``BandWaveformError/unsupportedFormat(_:sampleRate:)`` when
  ///   the sample rate is not finite or is at or below 6,000 Hz, or a filter
  ///   cannot be built; ``BandWaveformError/durationTooLong(_:seconds:)``
  ///   when the header's length is more than 12 hours;
  ///   `PCMBufferReaderError.bufferAllocationFailed` when the read buffer cannot
  ///   be allocated; `PCMBufferReaderError.readFailed` when a read fails other
  ///   other than with an early-end error after the first chunk;
  ///   `CancellationError` when ``Options/isCancelled`` returns `true`.
  public static func read(url: URL, options: Options = Options()) throws -> BandWaveform {
    let file: AVAudioFile
    do {
      file = try AVAudioFile(forReading: url)
    } catch {
      throw PCMBufferReaderError.fileNotReadable(url)
    }
    let format = file.processingFormat
    let sampleRate = format.sampleRate
    guard sampleRate.isFinite, sampleRate > BandWaveform.minimumSampleRateExclusive else {
      throw BandWaveformError.unsupportedFormat(url, sampleRate: sampleRate)
    }
    // Before any allocation the header sizes: a damaged header can claim
    // billions of frames.
    let length = file.length
    let seconds = Double(length) / sampleRate
    guard seconds <= maximumDurationSeconds else {
      throw BandWaveformError.durationTooLong(url, seconds: seconds)
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkFrames) else {
      throw PCMBufferReaderError.bufferAllocationFailed(url)
    }
    let timebase = WaveformBucketTimebase(sampleRate: sampleRate)
    let bucketCount = timebase.bucketCount(frames: length)
    var peak = [BandWaveform.Levels](repeating: .silent, count: bucketCount)
    var rms = [BandWaveform.Levels](repeating: .silent, count: bucketCount)
    let channelCount = Int(format.channelCount)
    var sums = WaveformBucketSums(channelCount: channelCount)
    var filters: [WaveformBandFilter] = []
    filters.reserveCapacity(channelCount)
    for _ in 0..<channelCount {
      guard let filter = WaveformBandFilter(sampleRate: sampleRate) else {
        throw BandWaveformError.unsupportedFormat(url, sampleRate: sampleRate)
      }
      filters.append(filter)
    }
    let encoded = file.fileFormat.streamDescription.pointee
    let source = BandWaveform.Source(
      formatID: encoded.mFormatID, processingFormat: describe(format))
    let mayContainNonFinite = mayDecodeNonFinite(encoded)

    var framesRead: Int64 = 0
    // Bounded by the length: `read(into:)` throws at the end of the file
    // rather than reading 0 frames.
    while file.framePosition < length {
      if options.isCancelled() { throw CancellationError() }
      // From the file, never a counter: a short read moves every later chunk
      // boundary, and the filter output depends on where they fall.
      let chunkStart = file.framePosition
      let requested = AVAudioFrameCount(min(length - chunkStart, Int64(chunkFrames)))
      do {
        try file.read(into: buffer, frameCount: requested)
      } catch {
        // The file decoded fewer frames than its header states: keep what was
        // read. Any other failure, or one before the first frame, is thrown.
        if chunkStart > 0, isEndOfFile(error) { break }
        throw PCMBufferReaderError.readFailed(
          url, underlyingDescription: error.localizedDescription)
      }
      let frameCount = Int(buffer.frameLength)
      guard frameCount > 0, let channels = buffer.floatChannelData else { break }
      framesRead += Int64(frameCount)
      for channel in 0..<channelCount {
        filters[channel].filter(
          UnsafeBufferPointer(start: channels[channel], count: frameCount),
          mayContainNonFinite: mayContainNonFinite)
      }
      var offset = 0
      while offset < frameCount {
        let bucket = timebase.bucket(atFrame: chunkStart + Int64(offset))
        let nextBucketStart = timebase.firstFrame(ofBucket: bucket + 1) - chunkStart
        let end = max(offset + 1, min(frameCount, Int(nextBucketStart)))
        guard bucket < bucketCount else { break }
        let span = offset..<end
        var level = peak[bucket]
        for channel in 0..<channelCount {
          level.low = max(level.low, filters[channel].low.peak(in: span))
          level.mid = max(level.mid, filters[channel].mid.peak(in: span))
          level.high = max(level.high, filters[channel].high.peak(in: span))
        }
        peak[bucket] = level
        // Always the RMS of the bucket's frames so far, so an end of file needs
        // no flush.
        sums.add(span, of: filters, toBucket: bucket)
        rms[bucket] = sums.rootMeanSquare
        offset = end
      }
    }
    return BandWaveform(
      measuredPeak: peak, rms: rms, sampleRate: sampleRate, channelCount: channelCount,
      frameCount: length, framesRead: framesRead, source: source)
  }

  // MARK: - Helpers

  /// The domain of Foundation's generic nil error, which an Objective-C call
  /// that fails without an error object bridges to. On macOS 26 and earlier,
  /// `AVAudioFile.read(into:)` reports a read past a FLAC's real end this way.
  static let nilErrorDomain = "Foundation._GenericObjCError"

  /// Whether `error` is one a read past the file's real end throws: `eofErr`
  /// (`NSOSStatusErrorDomain` -39) or Foundation's generic nil error (code 0).
  /// Tested on the raw error, before any wrapping.
  static func isEndOfFile(_ error: any Error) -> Bool {
    let error = error as NSError
    return (error.domain == NSOSStatusErrorDomain && error.code == endOfFileStatus)
      || (error.domain == nilErrorDomain && error.code == 0)
  }

  /// Whether samples decoded from a file in `encoded` format can be NaN or
  /// infinite. `false` only for integer sources: integer linear PCM, FLAC,
  /// Apple Lossless, mu-law and A-law, whose samples convert to finite floats.
  /// Float linear PCM and every lossy or unknown codec return `true`.
  static func mayDecodeNonFinite(_ encoded: AudioStreamBasicDescription) -> Bool {
    switch encoded.mFormatID {
    case kAudioFormatLinearPCM:
      return encoded.mFormatFlags & kAudioFormatFlagIsFloat != 0
    case kAudioFormatFLAC, kAudioFormatAppleLossless, kAudioFormatULaw, kAudioFormatALaw:
      return false
    default:
      return true
    }
  }

  /// `"<commonFormat> <interleaved|deinterleaved> <channelCount>ch <sampleRate>Hz"`,
  /// built from the format's fields (never its `description`). The rate uses
  /// `Double.description`, which is locale-independent.
  static func describe(_ format: AVAudioFormat) -> String {
    let common: String
    switch format.commonFormat {
    case .pcmFormatFloat32: common = "float32"
    case .pcmFormatFloat64: common = "float64"
    case .pcmFormatInt16: common = "int16"
    case .pcmFormatInt32: common = "int32"
    default: common = "other"
    }
    let layout = format.isInterleaved ? "interleaved" : "deinterleaved"
    return "\(common) \(layout) \(format.channelCount)ch \(format.sampleRate.description)Hz"
  }
}
