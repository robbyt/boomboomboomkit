//
//  BandWaveformNumericTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.11 (DD-12 b): checks of the three-band waveform measurement
//  written from its written definition, not from any other implementation:
//  the pinned bits of the filter quality, closed-form cookbook coefficients,
//  a scalar Double direct-form cascade as the filter reference, hand-computed
//  bucket boundaries, and a bucket split by the read chunk. Then a sweep over
//  every bundled codec fixture, and the bucket time queries and band subscript
//  of `BandWaveform`.
//

@preconcurrency import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - DirectFormCascade

/// A scalar Double biquad cascade, direct form I, with its coefficients
/// computed here from the cookbook formulas. The test-side reference for
/// `WaveformBandFilter`.
enum DirectFormCascade {
  /// One section, `a0` already divided out.
  struct Section {
    let b0, b1, b2, a1, a2: Double
  }

  /// Q for a Butterworth section, computed independently of the library's
  /// constant.
  private static let quality = 1 / 2.0.squareRoot()

  static func lowPass(_ cutoff: Double, sampleRate: Double) -> Section {
    let w0 = 2 * Double.pi * cutoff / sampleRate
    let alpha = sin(w0) / (2 * quality)
    let a0 = 1 + alpha
    return Section(
      b0: (1 - cos(w0)) / 2 / a0, b1: (1 - cos(w0)) / a0, b2: (1 - cos(w0)) / 2 / a0,
      a1: -2 * cos(w0) / a0, a2: (1 - alpha) / a0)
  }

  static func highPass(_ cutoff: Double, sampleRate: Double) -> Section {
    let w0 = 2 * Double.pi * cutoff / sampleRate
    let alpha = sin(w0) / (2 * quality)
    let a0 = 1 + alpha
    return Section(
      b0: (1 + cos(w0)) / 2 / a0, b1: -(1 + cos(w0)) / a0, b2: (1 + cos(w0)) / 2 / a0,
      a1: -2 * cos(w0) / a0, a2: (1 - alpha) / a0)
  }

  static func low(sampleRate: Double) -> [Section] {
    [lowPass(300, sampleRate: sampleRate)]
  }

  static func mid(sampleRate: Double) -> [Section] {
    [highPass(250, sampleRate: sampleRate), lowPass(1_200, sampleRate: sampleRate)]
  }

  /// The 9 kHz low-pass only when the rate is above 18,000 Hz.
  static func high(sampleRate: Double) -> [Section] {
    sampleRate > 18_000
      ? [highPass(3_000, sampleRate: sampleRate), lowPass(9_000, sampleRate: sampleRate)]
      : [highPass(3_000, sampleRate: sampleRate)]
  }

  /// `samples` through `sections` in order, from zero state; non-finite input
  /// is 0.
  static func filter(_ samples: [Float], _ sections: [Section]) -> [Double] {
    var signal = samples.map { $0.isFinite ? Double($0) : 0 }
    for section in sections {
      var x1 = 0.0
      var x2 = 0.0
      var y1 = 0.0
      var y2 = 0.0
      for index in signal.indices {
        let x0 = signal[index]
        let y0 =
          section.b0 * x0 + section.b1 * x1 + section.b2 * x2 - section.a1 * y1 - section.a2 * y2
        x2 = x1
        x1 = x0
        y2 = y1
        y1 = y0
        signal[index] = y0
      }
    }
    return signal
  }

  /// Peak and RMS levels of `channels` by the measurement's written rule: the
  /// bucket of frame f is floor(f x 150 / Fs); per band the peak is the largest
  /// magnitude of any channel and the RMS the louder channel's, both clamped to
  /// 1.
  static func levels(_ channels: [[Float]], sampleRate: Double) -> (
    peak: [BandWaveform.Levels], rms: [BandWaveform.Levels]
  ) {
    let frames = channels.first?.count ?? 0
    guard frames > 0 else { return ([], []) }
    func bucket(_ frame: Int) -> Int { Int((Double(frame) * 150 / sampleRate).rounded(.down)) }
    let bucketCount = bucket(frames - 1) + 1
    var counts = [Int](repeating: 0, count: bucketCount)
    for frame in 0..<frames { counts[bucket(frame)] += 1 }
    var peak = [BandWaveform.Levels](repeating: .silent, count: bucketCount)
    var rms = [BandWaveform.Levels](repeating: .silent, count: bucketCount)
    let bands: [WritableKeyPath<BandWaveform.Levels, Float>] = [\.low, \.mid, \.high]
    for samples in channels {
      let outputs = [
        filter(samples, low(sampleRate: sampleRate)),
        filter(samples, mid(sampleRate: sampleRate)),
        filter(samples, high(sampleRate: sampleRate)),
      ]
      for (band, output) in zip(bands, outputs) {
        var maxima = [Double](repeating: 0, count: bucketCount)
        var sums = [Double](repeating: 0, count: bucketCount)
        for frame in 0..<frames {
          let index = bucket(frame)
          maxima[index] = max(maxima[index], abs(output[frame]))
          sums[index] += output[frame] * output[frame]
        }
        for index in 0..<bucketCount {
          peak[index][keyPath: band] = max(
            peak[index][keyPath: band], Float(min(maxima[index], 1)))
          let level = Float(min((sums[index] / Double(counts[index])).squareRoot(), 1))
          rms[index][keyPath: band] = max(rms[index][keyPath: band], level)
        }
      }
    }
    return (peak, rms)
  }

  /// Every band of every bucket within `tolerance`, and equal counts.
  static func expectLevels(
    _ actual: [BandWaveform.Levels], near expected: [BandWaveform.Levels], within tolerance: Float,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(actual.count == expected.count, sourceLocation: sourceLocation)
    var failures = 0
    for (index, (level, reference)) in zip(actual, expected).enumerated() {
      for band in [\BandWaveform.Levels.low, \.mid, \.high]
      where abs(level[keyPath: band] - reference[keyPath: band]) > tolerance {
        failures += 1
        if failures <= 5 {
          Issue.record(
            "bucket \(index): \(level) against \(reference)", sourceLocation: sourceLocation)
        }
      }
    }
    #expect(failures == 0, "\(failures) band values off", sourceLocation: sourceLocation)
  }
}

// MARK: - Numeric checks

@Suite("BandWaveform numeric checks")
struct BandWaveformNumericTests {
  private static let rates: [Double] = [44_100, 48_000, 96_000, 18_000, 18_001]

  @Test("quality is 0.5.squareRoot(), bit for bit")
  func qualityBitsArePinned() {
    #expect(WaveformBandFilter.quality.bitPattern == 0x3FE6_A09E_667F_3BCD)
    #expect((1 / 2.0.squareRoot()).bitPattern == 0x3FE6_A09E_667F_3BCC, "the premise")
  }

  @Test("every section's coefficients equal the closed-form cookbook values", arguments: rates)
  func coefficientsMatchCookbook(sampleRate: Double) {
    let sections = WaveformBandFilter.sections(sampleRate: sampleRate)
    let expected: [(String, [Double], [DirectFormCascade.Section])] = [
      ("low", sections.low, DirectFormCascade.low(sampleRate: sampleRate)),
      ("mid", sections.mid, DirectFormCascade.mid(sampleRate: sampleRate)),
      ("high", sections.high, DirectFormCascade.high(sampleRate: sampleRate)),
    ]
    for (name, actual, cookbook) in expected {
      #expect(actual.count == cookbook.count * 5, "\(name) at \(sampleRate)")
      let flat = cookbook.flatMap { [$0.b0, $0.b1, $0.b2, $0.a1, $0.a2] }
      for (index, (value, reference)) in zip(actual, flat).enumerated() {
        // Q differs by one ulp here on purpose, so allow a few ulps.
        #expect(
          abs(value - reference) <= 1e-14 * max(1, abs(reference)),
          "\(name)[\(index)] at \(sampleRate): \(value) against \(reference)")
      }
    }
  }

  @Test(
    "each band equals the direct-form cascade on seeded noise, within 1e-9 of the signal's peak",
    arguments: [44_100.0, 48_000, 96_000, 18_000, 18_001, 11_025])
  func bandsMatchDirectFormCascade(sampleRate: Double) throws {
    var rng = SplitMix64(seed: 0x5741_5645_4241_4E44)
    let samples = (0..<150_000).map { _ in
      Float(Double(rng.next() >> 11) / Double(UInt64(1) << 53) * 1.6 - 0.8)
    }
    let peak = samples.map { Double(abs($0)) }.max() ?? 1
    var filter = try #require(WaveformBandFilter(sampleRate: sampleRate))
    // Filtered in read-sized chunks, as the reader does.
    var outputs: [[Double]] = [[], [], []]
    samples.withUnsafeBufferPointer { buffer in
      for start in stride(from: 0, to: buffer.count, by: 65_536) {
        filter.filter(
          UnsafeBufferPointer(rebasing: buffer[start..<min(start + 65_536, buffer.count)]))
        outputs[0] += filter.low.samples
        outputs[1] += filter.mid.samples
        outputs[2] += filter.high.samples
      }
    }
    let references = [
      DirectFormCascade.filter(samples, DirectFormCascade.low(sampleRate: sampleRate)),
      DirectFormCascade.filter(samples, DirectFormCascade.mid(sampleRate: sampleRate)),
      DirectFormCascade.filter(samples, DirectFormCascade.high(sampleRate: sampleRate)),
    ]
    for (band, (output, reference)) in zip(["low", "mid", "high"], zip(outputs, references)) {
      #expect(output.count == reference.count)
      let worst = zip(output, reference).map { abs($0 - $1) }.max() ?? 0
      #expect(worst <= 1e-9 * peak, "\(band) at \(sampleRate): worst difference \(worst)")
    }
  }

  @Test("bucket boundaries match hand-computed values")
  func bucketBoundariesMatchHandComputedValues() {
    // 11,025 Hz: 73.5 frames per bucket.
    let slow = WaveformBucketTimebase(sampleRate: 11_025)
    #expect(slow.bucket(atFrame: 73) == 0)
    #expect(slow.bucket(atFrame: 74) == 1)
    #expect(slow.bucket(atFrame: 220) == 2)
    #expect(slow.bucket(atFrame: 221) == 3)
    #expect(slow.firstFrame(ofBucket: 1) == 74)
    #expect(slow.firstFrame(ofBucket: 2) == 147)
    #expect(slow.firstFrame(ofBucket: 3) == 221)
    #expect(slow.bucketCount(frames: 11_025) == 150)
    #expect(slow.bucketCount(frames: 11_026) == 151)

    // 44,100 Hz: 294 frames per bucket.
    let cd = WaveformBucketTimebase(sampleRate: 44_100)
    #expect(cd.bucket(atFrame: 293) == 0)
    #expect(cd.bucket(atFrame: 294) == 1)
    #expect(cd.firstFrame(ofBucket: 222) == 65_268)
    #expect(cd.firstFrame(ofBucket: 223) == 65_562)
    #expect(cd.bucketCount(frames: 44_100) == 150)
    #expect(cd.bucketCount(frames: 44_101) == 151)
    #expect(cd.bucketCount(frames: 1) == 1)
    #expect(cd.bucketCount(frames: 0) == 0)

    // 48,000 Hz: 320 frames per bucket.
    let dat = WaveformBucketTimebase(sampleRate: 48_000)
    #expect(dat.bucket(atFrame: 319) == 0)
    #expect(dat.bucket(atFrame: 320) == 1)
    #expect(dat.bucket(atFrame: 65_535) == 204)
    #expect(dat.bucket(atFrame: 65_536) == 204)
    #expect(dat.firstFrame(ofBucket: 205) == 65_600)
    #expect(dat.bucketCount(frames: 48_000) == 150)

    // 96,000 Hz: 640 frames per bucket.
    let high = WaveformBucketTimebase(sampleRate: 96_000)
    #expect(high.bucket(atFrame: 639) == 0)
    #expect(high.bucket(atFrame: 640) == 1)
    #expect(high.bucket(atFrame: 65_536) == 102)
    #expect(high.firstFrame(ofBucket: 103) == 65_920)
    #expect(high.bucketCount(frames: 96_000) == 150)
  }

  @Test(
    "a bucket split by the read chunk: its peak and RMS equal the cascade over the whole signal")
  func bucketSplitByReadChunkMatchesCascade() throws {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "BandWaveformNumericTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    let frames = 2 * Int(SyntheticAudioFile.sampleRate)
    let chunk = Int(BandWaveformReader.chunkFrames)
    let left = SyntheticAudioFiles.noiseAndTones(frames: frames)
    let burst = SyntheticAudioFiles.sine(5_000, amplitude: 0.9, frames: frames)
    let right = (0..<frames).map { $0 < chunk ? 0 : burst[$0] }
    let url = try SyntheticAudioFiles.writeFile(
      SyntheticAudioFile(frames: frames), samples: [left, right], in: folder)
    // Bucket 222 spans frames 65,268..<65,562, across the chunk at 65,536.
    let split = 222

    let waveform = try BandWaveformReader.read(url: url)
    let expected = DirectFormCascade.levels(
      [left, right], sampleRate: SyntheticAudioFile.sampleRate)

    #expect(
      waveform.peak[split] == expected.peak[split],
      "\(waveform.peak[split]) against \(expected.peak[split])")
    for band in [\BandWaveform.Levels.low, \.mid, \.high] {
      #expect(
        abs(waveform.rms[split][keyPath: band] - expected.rms[split][keyPath: band]) <= 1e-6,
        "\(waveform.rms[split]) against \(expected.rms[split])")
    }
    DirectFormCascade.expectLevels(waveform.rms, near: expected.rms, within: 1e-6)
  }

  // MARK: - Non-finite input

  @Test("the non-finite scan finds NaN and infinities anywhere, and nothing in finite data")
  func nonFiniteScanFindsEveryKind() {
    var samples = [Float](repeating: 0.25, count: 1_000)
    samples[0] = -0.0
    samples[1] = .leastNonzeroMagnitude
    samples[2] = .greatestFiniteMagnitude
    samples[3] = -.greatestFiniteMagnitude
    #expect(!samples.withUnsafeBufferPointer(WaveformBandFilter.containsNonFinite))
    for (index, value) in [
      (0, Float.nan), (999, .infinity), (517, -.infinity), (4, .signalingNaN), (998, -Float.nan),
    ] {
      var poisoned = samples
      poisoned[index] = value
      #expect(
        poisoned.withUnsafeBufferPointer(WaveformBandFilter.containsNonFinite),
        "\(value) at \(index)")
    }
  }

  @Test("only integer sources skip the non-finite scan")
  func integerSourcesSkipTheScan() {
    func description(_ formatID: AudioFormatID, flags: AudioFormatFlags = 0)
      -> AudioStreamBasicDescription
    {
      var description = AudioStreamBasicDescription()
      description.mFormatID = formatID
      description.mFormatFlags = flags
      return description
    }
    let integerPCM = description(kAudioFormatLinearPCM, flags: kAudioFormatFlagIsSignedInteger)
    let floatPCM = description(kAudioFormatLinearPCM, flags: kAudioFormatFlagIsFloat)
    #expect(!BandWaveformReader.mayDecodeNonFinite(integerPCM))
    #expect(BandWaveformReader.mayDecodeNonFinite(floatPCM))
    for formatID in [
      kAudioFormatFLAC, kAudioFormatAppleLossless, kAudioFormatULaw, kAudioFormatALaw,
    ] {
      #expect(!BandWaveformReader.mayDecodeNonFinite(description(formatID)), "\(formatID)")
    }
    for formatID in [kAudioFormatMPEGLayer3, kAudioFormatMPEG4AAC, kAudioFormatOpus, 0x7A7A_7A7A] {
      #expect(BandWaveformReader.mayDecodeNonFinite(description(formatID)), "\(formatID)")
    }
  }

  @Test("a 16-bit WAV and the float WAV of the same signal measure alike")
  func integerWAVMeasuresLikeFloatWAV() throws {
    let folder = try SyntheticAudioFiles.makeFolder(prefix: "BandWaveformNumericTests")
    defer { try? FileManager.default.removeItem(at: folder) }
    // Whole multiples of 1/32768, so 16-bit storage keeps every sample exactly.
    let signal = SyntheticAudioFiles.noiseAndTones(frames: 70_000).map {
      ($0 * 32_768).rounded() / 32_768
    }
    let float = try SyntheticAudioFiles.writeFile(
      SyntheticAudioFile(frames: signal.count), samples: [signal, signal], in: folder)
    let integer = try SyntheticAudioFiles.writeFile(
      SyntheticAudioFile(frames: signal.count, container: .wav16), samples: [signal, signal],
      in: folder)

    let floatLevels = try BandWaveformReader.read(url: float)
    let integerLevels = try BandWaveformReader.read(url: integer)

    #expect(floatLevels.peak == integerLevels.peak)
    #expect(floatLevels.rms == integerLevels.rms)
  }

  // MARK: - Codec sweep

  private static let fixtures: [(String, String)] = [
    ("bpm-120-click", "wav"), ("sample", "wav"), ("test-bwf", "wav"),
    ("test-audio", "flac"), ("sample-with-cover", "flac"),
    ("Meta_Man", "mp3"), ("robbyt_x-ray-30s", "mp3"),
    ("test-audio", "m4a"), ("sample-with-cover", "m4a"),
    ("test-bwf", "caf"), ("test-ulaw", "caf"),
    ("sample-with-cover", "aiff"),
    ("test-alac", "m4a"),
    ("vorbis-decodable", "ogg"),
  ]

  @Test(
    "every bundled codec fixture reads: counts follow the header, values finite in 0...1, RMS at most the peak",
    arguments: fixtures)
  func bundledFixtureReads(name: String, fileExtension: String) throws {
    let url = try AudioFixtures.url(for: name, extension: fileExtension)

    let waveform = try BandWaveformReader.read(url: url)

    let file = try AVAudioFile(forReading: url)
    #expect(waveform.frameCount == file.length)
    #expect(waveform.framesRead <= waveform.frameCount)
    let expectedCount = BandWaveform.bucketCount(
      frameCount: waveform.frameCount, sampleRate: waveform.sampleRate)
    #expect(waveform.peak.count == expectedCount)
    #expect(waveform.rms.count == expectedCount)
    #expect(!waveform.peak.isEmpty)
    for (index, (peak, rms)) in zip(waveform.peak, waveform.rms).enumerated() {
      for band in [\BandWaveform.Levels.low, \.mid, \.high] {
        let p = peak[keyPath: band]
        let r = rms[keyPath: band]
        guard (0...1).contains(p), (0...1).contains(r), r <= p + 1e-6 else {
          Issue.record("\(name).\(fileExtension) bucket \(index): peak \(peak), rms \(rms)")
          return
        }
      }
    }
  }
}

// MARK: - Bucket times and bands

@Suite("BandWaveform bucket times and bands")
struct BandWaveformTimeTests {
  private static let source = BandWaveform.Source(
    formatID: 0x6C70_636D, processingFormat: "float32 deinterleaved 1ch 44100.0Hz")

  /// The four rates the bucket boundaries are hand-checked at in
  /// `bucketBoundariesMatchHandComputedValues`, plus one that is not a whole
  /// number of Hz.
  static let rates: [Double] = [11_025, 44_100, 48_000, 96_000, 22_050.123456789012]

  /// A silent waveform `seconds` long at `sampleRate`, built without a file.
  private static func waveform(seconds: Double, sampleRate: Double) throws -> BandWaveform {
    let frameCount = Int64((seconds * sampleRate).rounded(.down))
    let buckets = try #require(
      BandWaveform.bucketCount(frameCount: frameCount, sampleRate: sampleRate))
    let silent = [BandWaveform.Levels](repeating: .silent, count: buckets)
    return try #require(
      BandWaveform(
        peak: silent, rms: silent, sampleRate: sampleRate, channelCount: 1,
        frameCount: frameCount, framesRead: frameCount, source: source))
  }

  /// Rates whose bucket boundaries include frames where the reader's two
  /// rounding steps disagree (6,000.1 Hz does at bucket 31,500, 210 s), plus
  /// seeded non-integral rates across the accepted range.
  static let walkRates: [Double] = {
    var rng = SplitMix64(seed: 0x15_11_0A)
    let seeded = (0..<10).map { _ in
      6_001 + Double(rng.next() % 90_000_000) / 1_000
    }
    return [6_000.1, 6_000.3, 7_777.7, 11_025.5, 22_050.123456789012, 44_100.7] + seeded
  }()

  @Test("bucket times follow the reader's span walk frame by frame", arguments: walkRates)
  func timesFollowTheSpanWalk(sampleRate: Double) throws {
    // At most about 2 million frames per rate, and at least the 210 s that
    // reaches the known disagreement at 6,000.1 Hz.
    let seconds = min(600, max(211, 2_000_000 / sampleRate))
    let waveform = try Self.waveform(seconds: seconds, sampleRate: sampleRate)
    let frames = waveform.frameCount
    let bucketCount = waveform.peak.count
    let chunk: Int64 = 65_536
    func formulaBucket(_ frame: Int64) -> Int {
      Int((Double(frame) * 150 / sampleRate).rounded(.down))
    }
    func formulaFirstFrame(_ bucket: Int) -> Int64 {
      Int64((Double(bucket) * sampleRate / 150).rounded(.up))
    }
    // The span walk, written out from the measurement contract: chunks of
    // 65,536 frames; in each, a span starts at `offset`, takes the bucket of
    // its first frame and ends at the next bucket's first frame.
    var walkFirstFrame = [Int64](repeating: -1, count: bucketCount)
    var frameMismatches = 0
    var disagreements = 0
    var chunkStart: Int64 = 0
    while chunkStart < frames {
      let count = Int(min(frames - chunkStart, chunk))
      var offset = 0
      while offset < count {
        let bucket = formulaBucket(chunkStart + Int64(offset))
        let end = max(offset + 1, min(count, Int(formulaFirstFrame(bucket + 1) - chunkStart)))
        guard bucket < bucketCount else { break }
        if walkFirstFrame[bucket] < 0 { walkFirstFrame[bucket] = chunkStart + Int64(offset) }
        for index in offset..<end {
          let frame = chunkStart + Int64(index)
          if formulaBucket(frame) != bucket { disagreements += 1 }
          if waveform.bucket(at: Double(frame) / sampleRate) != bucket { frameMismatches += 1 }
        }
        offset = end
      }
      chunkStart += Int64(count)
    }
    var startMismatches = 0
    for bucket in 0..<bucketCount
    where waveform.startTime(ofBucket: bucket) != Double(walkFirstFrame[bucket]) / sampleRate {
      startMismatches += 1
    }
    #expect(frameMismatches == 0, "frames whose bucket(at:) differs from the walk")
    #expect(startMismatches == 0, "buckets whose startTime differs from the walk")
    if sampleRate == 6_000.1 {
      #expect(
        disagreements > 0, "the premise: this rate has a boundary where the formulas disagree")
    }
  }

  @Test("every bucket's start time maps back to that bucket (10 minutes)", arguments: rates)
  func startTimeRoundTrips(sampleRate: Double) throws {
    let waveform = try Self.waveform(seconds: 600, sampleRate: sampleRate)
    #expect(waveform.peak.count == 90_000, "the premise: 150 buckets per second")
    var previous = -Double.infinity
    var missing = 0
    var mismatches = 0
    var notIncreasing = 0
    var pastEnd = 0
    var beforeCadence = 0
    var frameOrMoreAfterCadence = 0
    for bucket in waveform.peak.indices {
      guard let start = waveform.startTime(ofBucket: bucket) else {
        missing += 1
        continue
      }
      if waveform.bucket(at: start) != bucket { mismatches += 1 }
      if start <= previous { notIncreasing += 1 }
      if start >= waveform.duration { pastEnd += 1 }
      // The first frame at or after i / 150 s: never before it, and less than
      // one frame after it.
      let cadence = Double(bucket) / 150
      if start < cadence { beforeCadence += 1 }
      if start - 1 / sampleRate >= cadence { frameOrMoreAfterCadence += 1 }
      previous = start
    }
    #expect(missing == 0)
    #expect(mismatches == 0)
    #expect(notIncreasing == 0, "start times increase")
    #expect(pastEnd == 0)
    #expect(beforeCadence == 0)
    #expect(frameOrMoreAfterCadence == 0)
    #expect(waveform.startTime(ofBucket: 0) == 0)
  }

  @Test(
    "the returned bucket starts at or before the time, and the next one after it",
    arguments: rates)
  func bucketHoldsTheTime(sampleRate: Double) throws {
    let waveform = try Self.waveform(seconds: 600, sampleRate: sampleRate)
    var times: [Double] = [0, .leastNonzeroMagnitude, waveform.duration.nextDown]
    var rng = SplitMix64(seed: 0x15_11)
    for _ in 0..<20_000 {
      let unit = Double(rng.next() >> 11) / Double(UInt64(1) << 53)
      times.append(unit * waveform.duration)
    }
    // Both sides of every 97th boundary, and of the last one.
    for bucket in Array(stride(from: 1, to: waveform.peak.count, by: 97))
      + [waveform.peak.count - 1]
    {
      let start = try #require(waveform.startTime(ofBucket: bucket))
      times += [start.nextDown, start, start.nextUp, Double(bucket) / 150]
    }
    var failures = 0
    for time in times where time >= 0 && time < waveform.duration {
      guard let bucket = waveform.bucket(at: time),
        let start = waveform.startTime(ofBucket: bucket), start <= time
      else {
        failures += 1
        continue
      }
      if let next = waveform.startTime(ofBucket: bucket + 1), next <= time { failures += 1 }
    }
    #expect(failures == 0)
  }

  @Test("bucket 1 at 11,025 Hz starts at frame 74, not at 1/150 s")
  func bucketsDoNotStartAtMultiplesOfTheCadence() throws {
    let waveform = try Self.waveform(seconds: 1, sampleRate: 11_025)
    #expect(waveform.startTime(ofBucket: 1) == 74.0 / 11_025)
    #expect(waveform.startTime(ofBucket: 1) != 1.0 / 150)
    // 1/150 s is frame 73.5, so it plays frame 73, which is in bucket 0. The
    // naive `Int(seconds * 150)` says bucket 1.
    #expect(waveform.bucket(at: 1.0 / 150) == 0)
    #expect(Int(1.0 / 150 * 150) == 1)
  }

  @Test("out-of-range and non-finite queries are nil")
  func outOfRangeQueriesAreNil() throws {
    let waveform = try Self.waveform(seconds: 2, sampleRate: 44_100)
    let count = waveform.peak.count
    #expect(count == 300)
    for bucket in [-1, Int.min, count, count + 1, Int.max] {
      #expect(waveform.startTime(ofBucket: bucket) == nil, "bucket \(bucket)")
    }
    #expect(waveform.startTime(ofBucket: count - 1) != nil)
    let times: [Double] = [
      -1, -.leastNonzeroMagnitude, waveform.duration, waveform.duration.nextUp, .nan,
      .signalingNaN, .infinity, -.infinity, .greatestFiniteMagnitude,
      -.greatestFiniteMagnitude, 1e300,
    ]
    for time in times {
      #expect(waveform.bucket(at: time) == nil, "time \(time)")
    }
    #expect(waveform.duration == 2)
    #expect(waveform.bucket(at: waveform.duration.nextDown) == count - 1)
    #expect(waveform.bucket(at: 0) == 0)
  }

  @Test("an empty waveform has duration 0 and answers every query with nil")
  func emptyWaveformQueriesAreNil() throws {
    let waveform = try #require(
      BandWaveform(
        peak: [], rms: [], sampleRate: 48_000, channelCount: 2, frameCount: 0, framesRead: 0,
        source: Self.source))
    #expect(waveform.duration == 0)
    for bucket in [-1, 0, 1, Int.max] {
      #expect(waveform.startTime(ofBucket: bucket) == nil)
    }
    for time in [0, 1e-9, 1, -1, .nan, .infinity] as [Double] {
      #expect(waveform.bucket(at: time) == nil)
    }
  }

  @Test("the band subscript reads and writes the named band")
  func bandSubscriptReadsAndWrites() {
    #expect(BandWaveform.Band.allCases == [.low, .mid, .high])
    #expect(BandWaveform.Band.allCases.map(\.rawValue) == ["low", "mid", "high"])
    var levels = BandWaveform.Levels.silent
    levels[.mid] = 0.5
    #expect(levels.mid == 0.5)
    #expect(levels.low == 0 && levels.high == 0)
    levels[.low] = 0.25
    levels[.high] = 1
    #expect(levels == BandWaveform.Levels(low: 0.25, mid: 0.5, high: 1))
    for band in BandWaveform.Band.allCases {
      let expected: Float =
        switch band {
        case .low: 0.25
        case .mid: 0.5
        case .high: 1
        }
      #expect(levels[band] == expected, "\(band)")
    }
  }
}
