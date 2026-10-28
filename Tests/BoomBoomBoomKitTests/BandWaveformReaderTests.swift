//
//  BandWaveformReaderTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.11: `BandWaveformReader` against real WAV and FLAC files
//  written into a temporary folder: bucket placement by absolute frame, maxima
//  across channels and read chunks, clamping, the final partial bucket, a file
//  that ends before its header says, the failures, the low, mid and high
//  bands, and each band's RMS against `referenceRMS`. Then the reader rows of
//  the story's edge-case matrix: zero-frame header, cancellation, 7 kHz, the
//  18 kHz boundary, six channels and provenance.
//
//  An impulse's high band is measured against `impulsePeak`, the high peak of
//  a unit impulse fed to `WaveformBandFilter` itself, so no test here
//  reimplements the filters. The independent filter checks live in
//  `BandWaveformNumericTests`.
//

@preconcurrency import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit

@Suite("BandWaveformReader")
struct BandWaveformReaderTests {
  private typealias TestFile = SyntheticAudioFile

  private static let sampleRate = SyntheticAudioFile.sampleRate
  private static let bucketFrames = SyntheticAudioFile.bucketFrames
  private static let chunk = Int(BandWaveformReader.chunkFrames)

  private static func makeFolder() throws -> URL {
    try SyntheticAudioFiles.makeFolder(prefix: "BandWaveformReaderTests")
  }

  private static func read(_ url: URL) throws -> BandWaveform {
    try BandWaveformReader.read(url: url)
  }

  // MARK: - Peaks per second

  @Test(
    "10 s stereo with a 5 kHz burst in one channel at 4 to 5 s: 1,500 buckets, the burst in 600 to 749, its ring in 750"
  )
  func oneChannelBurstPlacedAtBucketsPerSecond() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let burst = (start: 4 * Int(Self.sampleRate), end: 5 * Int(Self.sampleRate))
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: 10 * Int(Self.sampleRate)), in: folder
    ) { channels in
      for frame in burst.start..<burst.end {
        channels[1][frame] =
          0.8 * Float(sin(2 * Double.pi * 5_000 * Double(frame) / Self.sampleRate))
      }
    }

    let waveform = try Self.read(url)

    #expect(waveform.bucketsPerSecond == 150)
    #expect(waveform.frameCount == Int64(10 * Int(Self.sampleRate)))
    #expect(waveform.bucketsPerSecond == BandWaveformReader.bucketsPerSecond)
    #expect(waveform.peak.count == 1_500)
    for (index, level) in waveform.peak.map(\.high).enumerated() {
      switch index {
      case ..<600:
        #expect(level == 0, "bucket \(index) is before the burst: \(level)")
      case 600..<750:
        #expect(level >= 0.7, "bucket \(index) is in the burst: \(level)")
      case 750:
        // The filter's ring after the burst ends, modelled 0.47.
        #expect(level >= 0.3 && level <= 0.8, "bucket 750 holds the ring: \(level)")
      default:
        #expect(level <= 1e-6, "bucket \(index) is after the ring: \(level)")
      }
    }
  }

  // MARK: - Bucket boundaries

  @Test("the timebase puts a frame in the bucket of its absolute position, and keeps a partial one")
  func timebaseFloorsAbsoluteFrame() {
    let timebase = WaveformBucketTimebase(sampleRate: Self.sampleRate)
    #expect(timebase.bucket(atFrame: 293) == 0)
    #expect(timebase.bucket(atFrame: 294) == 1)
    // The last frame of the first read chunk and the first of the second.
    #expect(timebase.bucket(atFrame: 65_535) == 222)
    #expect(timebase.bucket(atFrame: 65_536) == 222)
    // 230 whole buckets and 100 frames more.
    #expect(timebase.bucketCount(frames: 67_720) == 231)

    // At 11,025 Hz a bucket is 73.5 frames.
    let slow = WaveformBucketTimebase(sampleRate: 11_025)
    #expect(slow.bucket(atFrame: 73) == 0)
    #expect(slow.bucket(atFrame: 74) == 1)
    #expect(slow.bucket(atFrame: 146) == 1)
    #expect(slow.bucket(atFrame: 147) == 2)
    #expect(slow.bucketCount(frames: 2_300) == 32)
  }

  @Test("impulses: each channel's high peak lands in its bucket, across read chunks, never summed")
  func impulsesLandInTheirBuckets() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let bucket = Self.bucketFrames
    let chunk = Self.chunk
    let unit = try Self.impulsePeak()
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: 230 * bucket + 100), in: folder) {
      channels in
      channels[1][bucket] = -0.4  // the first frame of bucket 1, the other channel, negative
      // Bucket 222: the louder impulse in the first read chunk, the quieter one
      // at the first frame of the second, so the bucket's maximum has to carry
      // across the chunk boundary.
      channels[0][65_300] = 0.6
      channels[1][chunk] = 0.2
      channels[0][100 * bucket + bucket / 2] = 0.3  // one mid-bucket frame in both channels
      channels[1][100 * bucket + bucket / 2] = 0.6
    }

    let waveform = try Self.read(url)

    let high = waveform.peak.map { Double($0.high) }
    #expect(high[0] == 0)
    #expect(abs(high[1] - 0.4 * unit) <= 1e-6, "bucket 1: \(high[1])")
    #expect(abs(high[222] - 0.6 * unit) <= 1e-6, "bucket 222: \(high[222])")
    #expect(abs(high[100] - 0.6 * unit) <= 1e-6, "the louder channel, not the sum: \(high[100])")
    // The impulses' buckets, and 223: the chunk-start impulse is 25 frames
    // before the end of 222, so the filter's ring reaches into 223 (modelled
    // 2e-5). The others ring out in their own.
    let reached: Set = [1, 100, 222, 223]
    for (index, level) in high.enumerated() where !reached.contains(index) {
      #expect(level <= 1e-6, "bucket \(index) has no impulse: \(level)")
    }
  }

  @Test("a 5 kHz tone at 1.5: the high band is clamped to exactly 1")
  func highToneAboveFullScaleClampsToOne() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(5_000, amplitude: 1.5, in: folder)

    let waveform = try Self.read(url)

    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.high == 1, "bucket \(index): \(level)")
    }
  }

  @Test(
    "an impulse on the last frame shows in the final partial bucket's high band",
    arguments: [
      (AVAudioChannelCount(2), 44_100.0, 230 * 294 + 100),
      (AVAudioChannelCount(1), 44_100.0, 10 * 294 + 100),
      (AVAudioChannelCount(2), 11_025.0, 2_300),
    ])
  func impulseOnLastFrameShowsInFinalPartialBucket(
    channels: AVAudioChannelCount, sampleRate: Double, frames: Int
  ) throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let shape = TestFile(frames: frames, channels: channels, sampleRate: sampleRate)
    let url = try SyntheticAudioFiles.writeFile(shape, in: folder) { samples in
      samples[samples.count - 1][frames - 1] = -0.7
    }

    let waveform = try Self.read(url)

    let timebase = WaveformBucketTimebase(sampleRate: sampleRate)
    #expect(waveform.peak.count == timebase.bucketCount(frames: Int64(frames)))
    let last = try #require(waveform.peak.last)
    #expect(last.high > 0, "the final partial bucket: \(last)")
  }

  @Test("a file shorter than its header says keeps the peaks read before the real end")
  func fileShorterThanHeaderKeepsPartialPeaks() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    // A FLAC: its header states the length, and a truncated one throws
    // end-of-file part way through. (A WAV's length is measured from the bytes
    // present.)
    let url = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    // Cut the last few silent FLAC frames; the header still says 2 s. Decoding
    // then ends at about 1.4 s, well after the tone.
    let size = try #require(
      try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
    try SyntheticAudioFiles.truncate(url, to: size - SyntheticAudioFile.flacTailCut)
    // The premise: reading the cut file throws after some frames and before
    // the header's length. A runtime that decoded it to the end would leave
    // this test proving nothing.
    let file = try AVAudioFile(forReading: url)
    let buffer = try #require(
      AVAudioPCMBuffer(
        pcmFormat: file.processingFormat, frameCapacity: BandWaveformReader.chunkFrames))
    var threw = false
    while !threw, file.framePosition < file.length {
      let remaining = min(
        file.length - file.framePosition, Int64(BandWaveformReader.chunkFrames))
      do {
        try file.read(into: buffer, frameCount: AVAudioFrameCount(remaining))
      } catch {
        threw = true
      }
    }
    try #require(
      threw && file.framePosition > 0 && file.framePosition < file.length,
      "the cut file must stop decoding part way: at \(file.framePosition) of \(file.length)")

    let waveform = try Self.read(url)

    #expect(waveform.peak.count == 300, "the bucket count comes from the header's 2 s")
    for (index, level) in waveform.peak.map(\.high).enumerated() {
      if (37..<75).contains(index) {
        #expect(level > 0.1, "bucket \(index) holds the tone: \(level)")
      } else if index == 75 {
        #expect(level > 0, "bucket 75 holds the filter's ring after the tone: \(level)")
      } else {
        #expect(level <= 1e-6, "bucket \(index) is silent or past the real end: \(level)")
      }
    }
  }

  // MARK: - Bands

  /// The tone's buckets at least 20 ms from its edges, where the filters have
  /// settled.
  private static let steadyBuckets = 33..<117

  /// The amplitude of `writeTone`'s tone unless a test sets another.
  private static let toneAmplitude: Float = 0.5

  /// A 1 s stereo WAV at `sampleRate` with a tone
  /// (`writeTone(_:amplitude:antiphase:sampleRate:into:)`).
  private static func writeTone(
    _ frequency: Double, amplitude: Float = toneAmplitude, antiphase: Bool = false,
    sampleRate: Double = sampleRate, in folder: URL
  ) throws -> URL {
    let shape = TestFile(frames: Int(sampleRate), sampleRate: sampleRate)
    return try SyntheticAudioFiles.writeFile(shape, in: folder) { channels in
      writeTone(
        frequency, amplitude: amplitude, antiphase: antiphase, sampleRate: sampleRate,
        into: channels)
    }
  }

  /// A sine of `amplitude` at `frequency` in both channels over the tone
  /// seconds; the right channel inverted when `antiphase`.
  private static func writeTone(
    _ frequency: Double, amplitude: Float = toneAmplitude, antiphase: Bool,
    sampleRate: Double = sampleRate, into channels: [UnsafeMutablePointer<Float>]
  ) {
    let start = Int(SyntheticAudioFile.toneSeconds.lowerBound * sampleRate)
    let end = Int(SyntheticAudioFile.toneSeconds.upperBound * sampleRate)
    for frame in start..<end {
      let sample = amplitude * Float(sin(2 * Double.pi * frequency * Double(frame) / sampleRate))
      channels[0][frame] = sample
      channels[1][frame] = antiphase ? -sample : sample
    }
  }

  /// The steady part of a tone's peak levels.
  private static func steady(_ waveform: BandWaveform) -> ArraySlice<BandWaveform.Levels> {
    waveform.peak[steadyBuckets]
  }

  @Test("an 80 Hz tone: low about the tone, mid small")
  func bassToneLowNearToneMidSmall() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(80, in: folder)

    let waveform = try Self.read(url)

    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.low >= 0.9 * Self.toneAmplitude, "bucket \(index): \(level)")
      #expect(level.mid <= 0.15 * Self.toneAmplitude, "bucket \(index): \(level)")
    }
  }

  @Test("an 800 Hz tone: mid about the tone, low small")
  func midToneMidNearToneLowSmall() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(800, in: folder)

    let waveform = try Self.read(url)

    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.mid >= 0.85 * Self.toneAmplitude, "bucket \(index): \(level)")
      #expect(level.low <= 0.2 * Self.toneAmplitude, "bucket \(index): \(level)")
    }
  }

  @Test("a 5 kHz tone: high about 0.46, low and mid near nothing")
  func highToneHighOnly() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(5_000, in: folder)

    let waveform = try Self.read(url)

    // Modelled: 0.5 x the high band's 0.9187 gain at 5 kHz.
    let modelled: Float = 0.4594
    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(abs(level.high - modelled) <= 0.01 + 0.03 * modelled, "bucket \(index): \(level)")
      #expect(level.low <= 0.01, "bucket \(index): \(level)")
      #expect(level.mid <= 0.05, "bucket \(index): \(level)")
    }
  }

  @Test(
    "a 5 kHz tone at 16 kHz and at 11,025 Hz reads, with the 9 kHz low-pass left out",
    arguments: [(16_000.0, Float(0.45)), (11_025.0, Float(0.48))])
  func lowSampleRateHighFiniteAndMeasured(sampleRate: Double, minimumHigh: Float) throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(5_000, sampleRate: sampleRate, in: folder)

    let waveform = try Self.read(url)

    #expect(waveform.peak.allSatisfy { $0.high.isFinite })
    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.high >= minimumHigh, "bucket \(index): \(level)")
    }
  }

  @Test("a rate at or below twice the high band's 3 kHz high-pass: no filter, and the read throws")
  func sampleRateTooLowHasNoFilterAndThrows() throws {
    #expect(WaveformBandFilter(sampleRate: 6_000) == nil)
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeSilentWAV(sampleRate: 6_000, frames: 6_000, in: folder)
    #expect(try AVAudioFile(forReading: url).processingFormat.sampleRate == 6_000, "the premise")

    let error = #expect(throws: BandWaveformError.self) { try Self.read(url) }
    guard case .unsupportedFormat(let errorURL, let rate) = error else {
      Issue.record("expected unsupportedFormat, got \(String(describing: error))")
      return
    }
    #expect(errorURL == url)
    #expect(rate == 6_000)
  }

  @Test(
    "a steady sine through the band filter: the high band's gain matches the filter model",
    arguments: [
      (80.0, 0.001), (275.0, 0.008), (800.0, 0.069), (2_000.0, 0.400), (5_000.0, 0.919),
      (12_000.0, 0.388),
    ])
  func steadySineHighGainMatchesModel(frequency: Double, modelled: Double) throws {
    let frames = Int(Self.sampleRate)
    let samples = (0..<frames).map { frame in
      Float(sin(2 * Double.pi * frequency * Double(frame) / Self.sampleRate))
    }
    var filter = try #require(WaveformBandFilter(sampleRate: Self.sampleRate))
    samples.withUnsafeBufferPointer { filter.filter($0) }

    // The second half, long settled.
    let steady = (frames / 2)..<frames
    let input = samples[steady].map { Double(abs($0)) }.max() ?? 0
    let output = filter.high.samples[steady].map(abs).max() ?? 0
    let gain = output / input
    #expect(abs(gain - modelled) <= 0.01 + 0.03 * modelled, "\(frequency) Hz: \(gain)")
  }

  @Test("antiphase 80 Hz, L = -R: low about the tone, measured per channel, not summed")
  func antiphaseBassLowNearTone() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(80, antiphase: true, in: folder)

    let waveform = try Self.read(url)

    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.low >= 0.9 * Self.toneAmplitude, "bucket \(index): \(level)")
    }
  }

  @Test("an 80 Hz tone across the first read chunk's end: low about the tone on both sides of it")
  func bassToneAcrossReadChunkCarriesFilterState() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let chunk = Self.chunk
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: 2 * Int(Self.sampleRate)), in: folder
    ) { channels in
      for frame in 0..<(2 * Int(Self.sampleRate)) {
        let sample = 0.5 * Float(sin(2 * Double.pi * 80 * Double(frame) / Self.sampleRate))
        channels[0][frame] = sample
        channels[1][frame] = sample
      }
    }

    let waveform = try Self.read(url)

    // Frame 65,536 is in bucket 222; buckets 220 to 225 straddle it.
    #expect(chunk * 150 / Int(Self.sampleRate) == 222)
    for index in 220...225 {
      let level = waveform.peak[index]
      #expect(level.low >= 0.9 * Self.toneAmplitude, "bucket \(index): \(level)")
    }
  }

  @Test("an 80 Hz tone that stops at the first read chunk's end: the low band rings into the next")
  func bassToneStoppingAtReadChunkEndRingsIntoNext() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let chunk = Self.chunk
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: 2 * Int(Self.sampleRate)), in: folder
    ) { channels in
      for frame in 0..<chunk {
        let sample = 0.5 * Float(sin(2 * Double.pi * 80 * Double(frame) / Self.sampleRate))
        channels[0][frame] = sample
        channels[1][frame] = sample
      }
    }

    let waveform = try Self.read(url)

    // Bucket 223 starts 26 frames after the tone stops, all of it in the
    // second chunk: silent input, but the filters' state from the first chunk
    // still rings there. A filter reset at the chunk would leave it 0.
    let tail = waveform.peak[223]
    #expect(tail.low > 0.01, "bucket 223: \(tail)")
  }

  @Test("one 0.9 sample mid-bucket: the largest low, mid and high all land in that bucket")
  func impulseMidBucketPeaksAllBandsInIt() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let bucket = Self.bucketFrames
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: 30 * bucket), in: folder) {
      channels in
      channels[0][10 * bucket + bucket / 2] = 0.9
    }

    let waveform = try Self.read(url)

    #expect(Self.loudest(waveform, \.high) == 10)
    #expect(Self.loudest(waveform, \.mid) == 10)
    #expect(Self.loudest(waveform, \.low) == 10)
    let unit = try Self.impulsePeak()
    #expect(abs(Double(waveform.peak[10].high) - 0.9 * unit) <= 1e-6)
  }

  @Test(
    "one 0.9 sample on a bucket's last frame: high peaks in the next bucket, low and mid there or just after"
  )
  func impulseOnBucketsLastFramePeaksInItOrNext() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let bucket = Self.bucketFrames
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: 30 * bucket), in: folder) {
      channels in
      channels[1][11 * bucket - 1] = 0.9
    }

    let waveform = try Self.read(url)

    // The high band peaks 3 frames after the impulse, in the next bucket.
    #expect(Self.loudest(waveform, \.high) == 11)
    let unit = try Self.impulsePeak()
    #expect(abs(Double(waveform.peak[11].high) - 0.9 * unit) <= 1e-6)
    #expect(waveform.peak[10].high > 0)
    #expect([10, 11].contains(Self.loudest(waveform, \.mid)))
    #expect([10, 11].contains(Self.loudest(waveform, \.low)))
  }

  @Test("NaN and +-Inf, then an 80 Hz tone: the bands stay finite and the tone's low is measured")
  func badSamplesBeforeToneStayFinite() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let bad: [Float] = [.nan, .infinity, -.infinity]
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: Int(Self.sampleRate)), in: folder)
    { channels in
      for frame in 100..<400 {
        channels[0][frame] = bad[frame % bad.count]
        channels[1][frame] = bad[(frame + 1) % bad.count]
      }
      Self.writeTone(80, antiphase: false, into: channels)
    }

    let waveform = try Self.read(url)

    #expect(waveform.peak.allSatisfy { $0.low.isFinite && $0.mid.isFinite && $0.high.isFinite })
    for (index, level) in zip(Self.steadyBuckets, Self.steady(waveform)) {
      #expect(level.low >= 0.9 * Self.toneAmplitude, "bucket \(index): \(level)")
    }
  }

  @Test("silence: all three bands 0, in the peaks and the RMS")
  func silenceIsZeroInEveryBand() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: Int(Self.sampleRate)), in: folder)
    { _ in }

    let waveform = try Self.read(url)

    #expect(waveform.peak.count == 150)
    #expect(waveform.peak.allSatisfy { $0 == .silent })
    #expect(waveform.rms.count == 150)
    #expect(waveform.rms.allSatisfy { $0 == .silent })
  }

  @Test(
    "the band filter fed in pieces gives the same bands as one whole pass",
    arguments: [1, 293, 4_096, 65_536])
  func filterInPiecesMatchesWholePass(pieceFrames: Int) throws {
    let samples = SyntheticAudioFiles.noiseAndTones(frames: 150_000)
    var whole = try #require(WaveformBandFilter(sampleRate: Self.sampleRate))
    samples.withUnsafeBufferPointer { whole.filter($0) }
    let wholeLow = Array(whole.low.samples)
    let wholeMid = Array(whole.mid.samples)
    let wholeHigh = Array(whole.high.samples)

    var pieces = try #require(WaveformBandFilter(sampleRate: Self.sampleRate))
    var low: [Double] = []
    var mid: [Double] = []
    var high: [Double] = []
    samples.withUnsafeBufferPointer { buffer in
      for start in stride(from: 0, to: buffer.count, by: pieceFrames) {
        let piece = UnsafeBufferPointer(
          rebasing: buffer[start..<min(start + pieceFrames, buffer.count)])
        pieces.filter(piece)
        low += pieces.low.samples
        mid += pieces.mid.samples
        high += pieces.high.samples
      }
    }

    #expect(low.count == samples.count)
    #expect(mid.count == samples.count)
    #expect(zip(low, wholeLow).allSatisfy { abs($0 - $1) <= 1e-6 })
    #expect(high.count == samples.count)
    #expect(zip(mid, wholeMid).allSatisfy { abs($0 - $1) <= 1e-6 })
    #expect(zip(high, wholeHigh).allSatisfy { abs($0 - $1) <= 1e-6 })
  }

  /// The bucket holding the loudest `band`.
  private static func loudest(
    _ waveform: BandWaveform, _ band: KeyPath<BandWaveform.Levels, Float>
  ) -> Int? {
    waveform.peak.indices.max {
      waveform.peak[$0][keyPath: band] < waveform.peak[$1][keyPath: band]
    }
  }

  /// The high band's peak magnitude for a unit impulse, through
  /// `WaveformBandFilter` itself (modelled 0.308, 3 frames after the impulse).
  private static func impulsePeak() throws -> Double {
    var impulse = [Float](repeating: 0, count: bucketFrames)
    impulse[0] = 1
    var filter = try #require(WaveformBandFilter(sampleRate: sampleRate))
    impulse.withUnsafeBufferPointer { filter.filter($0) }
    return filter.high.samples.map(abs).max() ?? 0
  }

  // MARK: - RMS

  /// Each bucket's RMS by the rule the reader follows, worked out
  /// independently: one `WaveformBandFilter` per channel over the whole signal
  /// in a single call, the bucket of a frame floor(frame x 150 / Fs), and per
  /// band the louder channel's sqrt(mean of squared filtered samples) over the
  /// bucket's frames, clamped to 1.
  private static func referenceRMS(_ channels: [[Float]], sampleRate: Double) throws
    -> [BandWaveform.Levels]
  {
    let frames = try #require(channels.first).count
    let rate = Int(sampleRate)
    try #require(Double(rate) == sampleRate, "a whole sample rate, for the integer bucket rule")
    let perSecond = Int(BandWaveformReader.bucketsPerSecond)
    guard frames > 0 else { return [] }
    let bucketCount = (frames - 1) * perSecond / rate + 1
    var counts = [Int](repeating: 0, count: bucketCount)
    for frame in 0..<frames { counts[frame * perSecond / rate] += 1 }
    var rms = [BandWaveform.Levels](repeating: .silent, count: bucketCount)
    for samples in channels {
      var filter = try #require(WaveformBandFilter(sampleRate: sampleRate))
      samples.withUnsafeBufferPointer { filter.filter($0) }
      let bands = [filter.low.samples, filter.mid.samples, filter.high.samples]
      var sums = [[Double]](repeating: [0, 0, 0], count: bucketCount)
      for frame in 0..<frames {
        let bucket = frame * perSecond / rate
        for band in 0..<3 { sums[bucket][band] += bands[band][frame] * bands[band][frame] }
      }
      for bucket in 0..<bucketCount {
        let level = sums[bucket].map { Float(min(($0 / Double(counts[bucket])).squareRoot(), 1)) }
        rms[bucket] = BandWaveform.Levels(
          low: max(rms[bucket].low, level[0]), mid: max(rms[bucket].mid, level[1]),
          high: max(rms[bucket].high, level[2]))
      }
    }
    return rms
  }

  /// Every band of every bucket of `rms` within `tolerance` of `reference`'s.
  private static func expectRMS(
    _ rms: some Collection<BandWaveform.Levels>,
    equal reference: some Collection<BandWaveform.Levels>,
    within tolerance: Float = 1e-6, sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(rms.count == reference.count, sourceLocation: sourceLocation)
    for (index, (level, expected)) in zip(rms, reference).enumerated() {
      for band in Self.bands {
        let difference = abs(band.value(level) - band.value(expected))
        #expect(
          difference <= tolerance, "bucket \(index) \(band): \(level) against \(expected)",
          sourceLocation: sourceLocation)
      }
    }
  }

  private static let bands = Band.allCases

  /// One of the three bands, to pick a value out of a level.
  enum Band: CaseIterable, Sendable {
    case low, mid, high

    func value(_ level: BandWaveform.Levels) -> Float {
      switch self {
      case .low: level.low
      case .mid: level.mid
      case .high: level.high
      }
    }
  }

  /// Per band, sqrt(mean(x^2)) over `levels`: the aggregate the sine test
  /// compares, computed here rather than by any app code.
  private static func rootMeanSquare(of levels: some Collection<BandWaveform.Levels>)
    -> BandWaveform.Levels
  {
    guard !levels.isEmpty else { return .silent }
    let count = Double(levels.count)
    func mean(_ band: Band) -> Float {
      let sum = levels.reduce(0.0) { $0 + Double(band.value($1)) * Double(band.value($1)) }
      return Float((sum / count).squareRoot())
    }
    return BandWaveform.Levels(low: mean(.low), mid: mean(.mid), high: mean(.high))
  }

  @Test(
    "a sine's RMS in its own band is 1/sqrt(2) of its peak, bucket by bucket and over the steady buckets",
    arguments: [(80.0, Band.low), (800.0, .mid), (5_000.0, .high)])
  func sineRMSIsPeakOverRootTwo(frequency: Double, band: Band) throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try Self.writeTone(frequency, in: folder)

    let waveform = try Self.read(url)

    let ratio = 0.5.squareRoot()
    let peak = waveform.peak[Self.steadyBuckets]
    let rms = waveform.rms[Self.steadyBuckets]
    for (index, (peak, rms)) in zip(Self.steadyBuckets, zip(peak, rms)) {
      let bucket = Double(band.value(rms)) / Double(band.value(peak))
      #expect(abs(bucket - ratio) <= 0.05, "bucket \(index): \(rms) of \(peak)")
    }
    // Combined over the steady buckets, each by sqrt(mean of squares).
    let combined =
      Double(band.value(Self.rootMeanSquare(of: rms)))
      / Double(band.value(Self.rootMeanSquare(of: peak)))
    #expect(abs(combined - ratio) <= 0.015, "\(frequency) Hz combined: \(combined)")
  }

  @Test(
    "80 Hz in the left channel only: the low RMS is the left channel's, not halved by the right")
  func oneChannelToneRMSIsThatChannels() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = Int(Self.sampleRate)
    let tone = SyntheticAudioFiles.sine(80, frames: frames)
    let toneFrames =
      Int(
        SyntheticAudioFile.toneSeconds.lowerBound * Self.sampleRate)..<Int(
        SyntheticAudioFile.toneSeconds.upperBound * Self.sampleRate)
    let left = (0..<frames).map { toneFrames.contains($0) ? tone[$0] : 0 }
    let right = [Float](repeating: 0, count: frames)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames), samples: [left, right], in: folder)

    let waveform = try Self.read(url)

    let leftOnly = try Self.referenceRMS([left], sampleRate: Self.sampleRate)
    #expect(waveform.rms.count == leftOnly.count)
    for (index, (level, expected)) in zip(waveform.rms, leftOnly).enumerated() {
      #expect(
        abs(level.low - expected.low) <= 1e-6, "bucket \(index): \(level) against \(expected)")
    }
    #expect(
      waveform.rms[Self.steadyBuckets].allSatisfy { $0.low > 0.3 },
      "the premise: the tone is measured")
  }

  @Test("antiphase 80 Hz, L = -R: the low RMS equals the in-phase tone's, measured per channel")
  func antiphaseBassRMSAsInPhase() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let inPhase = try Self.writeTone(80, in: folder)
    let antiphase = try Self.writeTone(80, antiphase: true, in: folder)

    let inPhaseRMS = try Self.read(inPhase).rms
    let antiphaseRMS = try Self.read(antiphase).rms

    #expect(antiphaseRMS.count == inPhaseRMS.count)
    for (index, (level, expected)) in zip(antiphaseRMS, inPhaseRMS).enumerated() {
      #expect(
        abs(level.low - expected.low) <= 1e-6, "bucket \(index): \(level) against \(expected)")
    }
    #expect(inPhaseRMS[Self.steadyBuckets].allSatisfy { $0.low > 0.3 }, "the premise")
  }

  @Test("noise and tones: in every bucket and band the RMS is at most the peak")
  func noiseAndTonesRMSNeverAbovePeak() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = Int(Self.sampleRate)
    let samples = SyntheticAudioFiles.noiseAndTones(frames: frames)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames), samples: [samples, samples], in: folder)

    let waveform = try Self.read(url)

    #expect(!waveform.rms.isEmpty && waveform.rms.count == waveform.peak.count, "measured")
    for (index, (rms, peak)) in zip(waveform.rms, waveform.peak).enumerated() {
      for band in Self.bands {
        #expect(
          band.value(rms) <= band.value(peak) + 1e-6,
          "measured \(index) \(band): \(rms) against \(peak)")
      }
    }
    #expect(waveform.rms.allSatisfy { $0.low > 0 && $0.mid > 0 && $0.high > 0 }, "premise")
  }

  @Test(
    "a bucket split between two reads, its louder channel changing at the split: every bucket's RMS as one pass"
  )
  func bucketSplitAcrossReadsRMSAsOnePass() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 2 * Int(Self.sampleRate)
    let chunk = Self.chunk
    let left = SyntheticAudioFiles.noiseAndTones(frames: frames)
    let burst = SyntheticAudioFiles.sine(5_000, amplitude: 0.9, frames: frames)
    let right = (0..<frames).map { $0 < chunk ? 0 : burst[$0] }
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames), samples: [left, right], in: folder)
    // The premise: bucket 222 holds 268 frames of the first read and 26 of the
    // second.
    #expect(chunk - 222 * Self.bucketFrames == 268)
    #expect(223 * Self.bucketFrames - chunk == 26)
    // In the high band the left channel is the louder over the first read's
    // part of bucket 222 (the right is silent there), and the right over the
    // whole bucket.
    let leftHigh = try Self.referenceRMS([left], sampleRate: Self.sampleRate)[222].high
    let rightHigh = try Self.referenceRMS([right], sampleRate: Self.sampleRate)[222].high
    #expect(leftHigh > 0 && rightHigh > leftHigh, "premise: \(leftHigh), \(rightHigh)")

    let waveform = try Self.read(url)

    Self.expectRMS(
      waveform.rms, equal: try Self.referenceRMS([left, right], sampleRate: Self.sampleRate))
  }

  @Test(
    "44,200 frames, 80 Hz throughout: the final partial bucket's RMS is over the frames it holds")
  func finalPartialBucketRMSOverItsFrames() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 150 * Self.bucketFrames + 100
    let tone = SyntheticAudioFiles.sine(80, frames: frames)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames), samples: [tone, tone], in: folder)
    let reference = try Self.referenceRMS([tone, tone], sampleRate: Self.sampleRate)
    try #require(reference.count == 151)
    #expect(reference[150].low > 0.1, "the premise: the partial bucket holds the tone")

    let waveform = try Self.read(url)

    Self.expectRMS(waveform.rms, equal: reference)
  }

  @Test(
    "a FLAC that ends before its header says: the RMS of the frames decoded, partial last bucket included, then 0"
  )
  func fileEndingEarlyKeepsRMSOfDecodedFramesThenZero() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 2 * Int(Self.sampleRate)
    let tone = SyntheticAudioFiles.sine(80, frames: frames)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames, container: .flac), samples: [tone, tone], in: folder)
    let size = try #require(
      try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
    try SyntheticAudioFiles.truncate(url, to: size - SyntheticAudioFile.flacTailCut)
    // Decode the cut file as the reader does, keeping what each read that
    // didn't throw decoded.
    let file = try AVAudioFile(forReading: url)
    let buffer = try #require(
      AVAudioPCMBuffer(
        pcmFormat: file.processingFormat, frameCapacity: BandWaveformReader.chunkFrames))
    var decoded: [[Float]] = [[], []]
    var threw = false
    while file.framePosition < file.length {
      let remaining = min(
        file.length - file.framePosition, Int64(BandWaveformReader.chunkFrames))
      do {
        try file.read(into: buffer, frameCount: AVAudioFrameCount(remaining))
      } catch {
        threw = true
        break
      }
      let channels = try #require(buffer.floatChannelData)
      let count = Int(buffer.frameLength)
      guard count > 0 else { break }
      for channel in 0..<2 {
        decoded[channel] += UnsafeBufferPointer(start: channels[channel], count: count)
      }
    }
    let kept = decoded[0].count
    let timebase = WaveformBucketTimebase(sampleRate: Self.sampleRate)
    try #require(
      threw && kept > 0 && kept < Int(file.length),
      "the cut file must stop decoding part way: \(kept) of \(file.length)")
    let reference = try Self.referenceRMS(decoded, sampleRate: Self.sampleRate)
    let last = reference.count - 1
    #expect(
      timebase.firstFrame(ofBucket: last + 1) > Int64(kept),
      "the premise: the last kept bucket is partial (\(kept) frames)")
    #expect(reference[last].low > 0.1, "the premise: the last kept bucket holds the tone")

    let waveform = try Self.read(url)

    #expect(waveform.rms.count == 300, "the bucket count comes from the header's 2 s")
    Self.expectRMS(waveform.rms.prefix(reference.count), equal: reference)
    for (index, level) in waveform.rms.enumerated().dropFirst(reference.count) {
      #expect(level == .silent, "bucket \(index) is past the real end: \(level)")
    }
  }

  @Test("NaN and +-Inf inside a bucket of a tone: the same RMS as zeros there, and all finite")
  func badSamplesInToneRMSAsZeros() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let bad: [Float] = [.nan, .infinity, -.infinity]
    let badFrames = 10_000..<10_100
    #expect(badFrames.lowerBound / Self.bucketFrames == 34)
    #expect((badFrames.upperBound - 1) / Self.bucketFrames == 34)
    func write(_ value: (Int) -> Float) throws -> URL {
      try SyntheticAudioFiles.writeFile(TestFile(frames: Int(Self.sampleRate)), in: folder) {
        channels in
        Self.writeTone(80, antiphase: false, into: channels)
        for frame in badFrames {
          channels[0][frame] = value(frame)
          channels[1][frame] = value(frame)
        }
      }
    }
    let withBad = try write { bad[$0 % bad.count] }
    let withZeros = try write { _ in 0 }

    let badRMS = try Self.read(withBad).rms
    let zerosRMS = try Self.read(withZeros).rms

    #expect(badRMS == zerosRMS)
    #expect(badRMS.allSatisfy { $0.low.isFinite && $0.mid.isFinite && $0.high.isFinite })
    #expect(zerosRMS[34].low > 0.1, "the premise: bucket 34 holds the tone")
  }

  // MARK: - Failures

  @Test("both early-end errors count as the end of the file, and nothing else does")
  func earlyEndErrorsAreRecognized() {
    // macOS 27 reports a read past a FLAC's real end as eofErr; macOS 26 and
    // earlier as Foundation's generic nil error.
    #expect(BandWaveformReader.isEndOfFile(NSError(domain: NSOSStatusErrorDomain, code: -39)))
    #expect(
      BandWaveformReader.isEndOfFile(
        NSError(domain: BandWaveformReader.nilErrorDomain, code: 0)))
    #expect(!BandWaveformReader.isEndOfFile(NSError(domain: NSOSStatusErrorDomain, code: -40)))
    #expect(
      !BandWaveformReader.isEndOfFile(
        NSError(domain: BandWaveformReader.nilErrorDomain, code: 1)))
    #expect(
      !BandWaveformReader.isEndOfFile(
        NSError(domain: "com.apple.coreaudio.avfaudio", code: -66_567)))
    #expect(!BandWaveformReader.isEndOfFile(CancellationError()))
  }

  @Test("a FLAC whose first read throws, before any frame decodes, throws")
  func firstReadFailureThrows() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    // Only the header and the first few bytes of the first audio frame. With
    // nothing past the metadata, `AVAudioFile(forReading:)` itself refuses the
    // file; with these few bytes it opens, states the header's length, and the
    // first read throws.
    let audioStart = try SyntheticAudioFiles.flacAudioStart(of: Data(contentsOf: url))
    try SyntheticAudioFiles.truncate(
      url, to: audioStart + SyntheticAudioFile.firstFrameBytesKept)
    #expect(try AVAudioFile(forReading: url).length > 0, "the cut file still opens")
    let error = #expect(throws: PCMBufferReaderError.self) { try Self.read(url) }
    guard case .readFailed(let errorURL, _) = error else {
      Issue.record("expected readFailed, got \(String(describing: error))")
      return
    }
    #expect(errorURL == url)
  }

  @Test("a FLAC whose header claims the 36-bit maximum of frames throws durationTooLong")
  func headerClaimingTooLongThrows() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    var bytes = [UInt8](
      try Data(contentsOf: try AudioFixtures.url(for: "test-audio", extension: "flac")))
    // STREAMINFO is the first metadata block; its 36-bit total-samples field
    // is the low 4 bits of data byte 13 and data bytes 14 to 17, after the
    // 4-byte marker and the 4-byte block header.
    try #require(bytes.starts(with: Array("fLaC".utf8)) && bytes[4] & 0x7F == 0)
    bytes[8 + 13] |= 0x0F
    for index in (8 + 14)...(8 + 17) { bytes[index] = 0xFF }
    let url = folder.appending(path: "patched.flac")
    try Data(bytes).write(to: url)
    let maximum = Int64(1) << 36 - 1
    #expect(try AVAudioFile(forReading: url).length == maximum, "the premise")

    let error = #expect(throws: BandWaveformError.self) { try Self.read(url) }
    guard case .durationTooLong(let errorURL, let seconds) = error else {
      Issue.record("expected durationTooLong, got \(String(describing: error))")
      return
    }
    #expect(errorURL == url)
    #expect(seconds == Double(maximum) / 44_100)
  }

  @Test("a file that is not audio throws")
  func textFileThrows() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = folder.appending(path: "not-audio.wav")
    try Data("not audio".utf8).write(to: url)

    let error = #expect(throws: PCMBufferReaderError.self) { try Self.read(url) }
    guard case .fileNotReadable(let errorURL) = error else {
      Issue.record("expected fileNotReadable, got \(String(describing: error))")
      return
    }
    #expect(errorURL == url)
  }

  @Test("a read whose task is already cancelled throws CancellationError")
  func preCancelledTaskThrowsCancellationError() async throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: Int(Self.sampleRate)), in: folder)
    { _ in }

    let read = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return try BandWaveformReader.read(url: url)
    }

    await #expect(throws: CancellationError.self) { try await read.value }
  }

  // MARK: - Edge-case matrix: reader rows

  @Test("a header of 0 frames gives empty arrays and no error, even when already cancelled")
  func zeroFrameHeaderGivesEmptyResult() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeFile(TestFile(frames: 0), in: folder) { _ in }
    #expect(try AVAudioFile(forReading: url).length == 0, "the premise")
    var options = BandWaveformReader.Options()
    options.isCancelled = { true }

    let waveform = try BandWaveformReader.read(url: url, options: options)

    #expect(waveform.peak.isEmpty)
    #expect(waveform.rms.isEmpty)
    #expect(waveform.frameCount == 0)
    #expect(waveform.framesRead == 0)
  }

  @Test("isCancelled turning true at the second chunk check throws CancellationError")
  func cancelAfterFirstChunkThrows() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: 2 * Int(Self.sampleRate)), in: folder
    ) { _ in }
    let checks = Mutex(0)
    var options = BandWaveformReader.Options()
    options.isCancelled = {
      checks.withLock { count in
        count += 1
        return count >= 2
      }
    }

    #expect(throws: CancellationError.self) {
      try BandWaveformReader.read(url: url, options: options)
    }
    #expect(checks.withLock { $0 } == 2, "the first chunk was read before the second check")
  }

  @Test("a task group cancelled before its read starts: CancellationError")
  func taskGroupCancellationThrows() async throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: 2 * Int(Self.sampleRate)), in: folder
    ) { _ in }

    await #expect(throws: CancellationError.self) {
      try await withThrowingTaskGroup(of: BandWaveform.self) { group in
        group.cancelAll()
        group.addTask { try BandWaveformReader.read(url: url) }
        return try await group.next()
      }
    }
  }

  @Test("a 7 kHz file is measured, with the 9 kHz section left out")
  func sevenKilohertzMeasuredWithoutHighLowPass() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let rate = 7_000.0
    let tone = SyntheticAudioFiles.sine(80, frames: Int(rate), sampleRate: rate)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: Int(rate), channels: 1, sampleRate: rate), samples: [tone], in: folder)
    #expect(try AVAudioFile(forReading: url).processingFormat.sampleRate == rate, "the premise")
    #expect(try #require(WaveformBandFilter(sampleRate: rate)).highSectionCount == 1)

    let waveform = try Self.read(url)

    #expect(waveform.sampleRate == rate)
    #expect(waveform.peak.count == 150)
    #expect(waveform.peak.allSatisfy { $0.low.isFinite && $0.mid.isFinite && $0.high.isFinite })
    #expect(waveform.peak[75].low >= 0.9 * 0.5, "the tone is measured: \(waveform.peak[75])")
  }

  @Test(
    "at 18,000 Hz the high band has one section, at 18,001 Hz two; each band equals the direct-form cascade",
    arguments: [(18_000.0, 1), (18_001.0, 2)])
  func eighteenKilohertzBoundary(sampleRate: Double, highSections: Int) throws {
    #expect(
      try #require(WaveformBandFilter(sampleRate: sampleRate)).highSectionCount == highSections)
    #expect(DirectFormCascade.high(sampleRate: sampleRate).count == highSections)
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 2 * Int(sampleRate)
    let tone = SyntheticAudioFiles.sine(
      5_000, amplitude: 0.4, frames: frames, sampleRate: sampleRate)
    let noise = SyntheticAudioFiles.noiseAndTones(frames: frames, sampleRate: sampleRate)
    let left = zip(tone, noise).map { $0 + 0.5 * $1 }
    let right = SyntheticAudioFiles.noiseAndTones(
      frames: frames, sampleRate: sampleRate, seed: 0x0BAD_F00D)
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames, sampleRate: sampleRate), samples: [left, right], in: folder)
    #expect(try AVAudioFile(forReading: url).processingFormat.sampleRate == sampleRate)

    let waveform = try Self.read(url)
    let expected = DirectFormCascade.levels([left, right], sampleRate: sampleRate)

    #expect(waveform.peak.count == expected.peak.count)
    #expect(expected.peak[100].high > 0.3, "the premise: the tone is in the high band")
    DirectFormCascade.expectLevels(waveform.peak, near: expected.peak, within: 1e-6)
    DirectFormCascade.expectLevels(waveform.rms, near: expected.rms, within: 1e-6)
  }

  @Test(
    "six channels, a different channel loudest per band, the high winner changing inside the bucket split by the read chunk"
  )
  func sixChannelsEachBandFollowsItsLoudestChannel() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 2 * Int(Self.sampleRate)
    let chunk = Self.chunk
    let low = SyntheticAudioFiles.sine(80, amplitude: 0.6, frames: frames)
    let mid = SyntheticAudioFiles.sine(800, amplitude: 0.6, frames: frames)
    let highBefore = SyntheticAudioFiles.sine(5_000, amplitude: 0.5, frames: frames)
    let highAfter = SyntheticAudioFiles.sine(5_000, amplitude: 0.9, frames: frames)
    let quiet = SyntheticAudioFiles.noiseAndTones(frames: frames).map { 0.05 * $0 }
    let channels: [[Float]] = [
      low,
      mid,
      (0..<frames).map { $0 < chunk ? highBefore[$0] : 0 },
      (0..<frames).map { $0 < chunk ? 0 : highAfter[$0] },
      quiet,
      quiet.reversed(),
    ]
    let url = try SyntheticAudioFiles.writeFile(
      TestFile(frames: frames, channels: 6), samples: channels, in: folder)

    let waveform = try Self.read(url)
    let expected = DirectFormCascade.levels(channels, sampleRate: Self.sampleRate)
    let perChannel = channels.map { DirectFormCascade.levels([$0], sampleRate: Self.sampleRate) }

    #expect(waveform.channelCount == 6)
    #expect(waveform.peak.count == expected.peak.count)
    // Each band follows its own loudest channel: channel 0 for low, 1 for mid,
    // 2 for high before the read chunk's end and 3 after it.
    for bucket in [100, 250] {
      #expect(abs(waveform.peak[bucket].low - perChannel[0].peak[bucket].low) <= 1e-6)
      #expect(abs(waveform.peak[bucket].mid - perChannel[1].peak[bucket].mid) <= 1e-6)
      #expect(abs(waveform.rms[bucket].low - perChannel[0].rms[bucket].low) <= 1e-6)
      #expect(abs(waveform.rms[bucket].mid - perChannel[1].rms[bucket].mid) <= 1e-6)
    }
    #expect(abs(waveform.peak[100].high - perChannel[2].peak[100].high) <= 1e-6)
    #expect(abs(waveform.peak[250].high - perChannel[3].peak[250].high) <= 1e-6)
    // The premise: in bucket 222 the high winner changes at the split.
    let split = 222
    #expect(perChannel[2].rms[split].high > 0 && perChannel[3].rms[split].high > 0)
    #expect(perChannel[3].peak[split].high > perChannel[2].peak[split].high)
    // The split bucket equals the cascade over the whole signal.
    #expect(
      waveform.peak[split] == expected.peak[split],
      "\(waveform.peak[split]) against \(expected.peak[split])")
    DirectFormCascade.expectLevels([waveform.rms[split]], near: [expected.rms[split]], within: 1e-6)
    DirectFormCascade.expectLevels(waveform.peak, near: expected.peak, within: 1e-6)
    DirectFormCascade.expectLevels(waveform.rms, near: expected.rms, within: 1e-6)
  }

  @Test(
    "provenance: the file's codec, the processing format, and the opened file's rate and channels")
  func provenanceDescribesTheFile() throws {
    let folder = try Self.makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let flac = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    let wav = try SyntheticAudioFiles.writeFile(TestFile(frames: Int(Self.sampleRate)), in: folder)
    { _ in }

    for (url, formatID) in [(flac, kAudioFormatFLAC), (wav, kAudioFormatLinearPCM)] {
      let waveform = try Self.read(url)
      let file = try AVAudioFile(forReading: url)
      #expect(waveform.source.formatID == formatID)
      #expect(waveform.source.processingFormat == "float32 deinterleaved 2ch 44100.0Hz")
      #expect(waveform.sampleRate == file.processingFormat.sampleRate)
      #expect(waveform.channelCount == Int(file.processingFormat.channelCount))
      #expect(waveform.frameCount == file.length)
      #expect(waveform.framesRead == file.length)
      #expect(waveform.analysisVersion == BandWaveformReader.analysisVersion)
    }
  }
}
