//
//  PCMBufferReaderTests.swift
//  BoomBoomBoomKitTests
//

@preconcurrency import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Basic Reading Tests

@Suite("PCMBufferReader — Basic Reading")
struct PCMBufferReaderBasicTests {

  @Test("reads WAV file into non-empty float array")
  func readWAV() throws {
    let url = try AudioFixtures.url(for: "sample", extension: "wav")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  @Test("reads BWF WAV file into non-empty float array")
  func readBWF() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate == 44100)
  }

  @Test("all samples normalized to [-1.0, 1.0]")
  func samplesNormalized() throws {
    let url = try AudioFixtures.url(for: "sample", extension: "wav")
    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    for sample in samples {
      #expect(sample >= -1.0 && sample <= 1.0)
    }
  }

  @Test("reads MP3 with cover art")
  func readMP3() throws {
    let url = try AudioFixtures.url(for: "sample-with-cover", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  @Test("reads FLAC with cover art")
  func readFLAC() throws {
    let url = try AudioFixtures.url(for: "sample-with-cover", extension: "flac")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  @Test("reads M4A with cover art")
  func readM4A() throws {
    let url = try AudioFixtures.url(for: "sample-with-cover", extension: "m4a")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  @Test("reads AIFF with cover art")
  func readAIFF() throws {
    let url = try AudioFixtures.url(for: "sample-with-cover", extension: "aiff")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  @Test("reads bare FLAC without cover art")
  func readBareFLAC() throws {
    let url = try AudioFixtures.url(for: "sample-without-cover", extension: "flac")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate > 0)
  }

  /// GH-167 item 5 (#160): CAF is a documented supported container but this suite
  /// never read one — it was covered only incidentally via the LUFS and
  /// SharedDecode suites, so a CAF-specific reader regression would have surfaced
  /// somewhere unrelated, or not at all.
  @Test("reads CAF")
  func readCAF() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "caf")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate == 44100)
    #expect(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 })
  }

  @Test("returns empty array for zero-frame audio file")
  func zeroFrameFile() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("pcm_reader_zero_frame_test.wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
    // Write a valid WAV file with zero frames
    _ = try AVAudioFile(forWriting: tempURL, settings: format.settings)
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: tempURL)
    #expect(samples.isEmpty, "Zero-frame file should return empty samples array")
    #expect(sampleRate == 44100)
  }
}

// MARK: - Stereo Mixdown Tests

@Suite("PCMBufferReader — Stereo Mixdown")
struct PCMBufferReaderStereoTests {

  @Test("reads stereo MP3 and returns mono samples")
  func stereoToMono() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate == 44100)
    // ~31s at 44100 Hz ≈ 1,367,100 frames
    #expect(samples.count > 1_300_000, "Expected ~31s worth of samples at 44.1kHz")
  }

  @Test("stereo mixdown sample count matches expected mono frame count")
  func stereoFrameCount() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    let expectedFrames = sampleRate * 31.0
    let tolerance = sampleRate * 1.0  // ±1 second tolerance for MP3 framing
    #expect(
      Double(samples.count) > expectedFrames - tolerance
        && Double(samples.count) < expectedFrames + tolerance
    )
  }

  @Test("reads stereo MP3 with Unicode filename")
  func unicodeFilename() throws {
    let url = try AudioFixtures.url(for: "Meta_Man_Είσαι_η_Λύση_", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty)
    #expect(sampleRate == 44100)
  }

  @Test("stereo mixdown produces samples normalized to [-1.0, 1.0]")
  func stereoSamplesNormalized() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let (samples, _) = try PCMBufferReader.readMonoSamples(from: url)
    for sample in samples {
      #expect(sample >= -1.0 && sample <= 1.0)
    }
  }
}

// MARK: - Partial Read Tests

@Suite("PCMBufferReader — Partial Read")
struct PCMBufferReaderPartialReadTests {

  @Test("partial read returns approximately maxSeconds worth of samples")
  func partialRead1Second() throws {
    let url = try AudioFixtures.url(for: "Quantum_Cascade", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 1)
    let expectedCount = Int(sampleRate * 1.0)
    #expect(samples.count <= expectedCount, "Should not exceed maxSeconds worth of frames")
    #expect(samples.count > 0, "Should return some samples")
  }

  @Test("partial read with 0.5 seconds returns half-second of samples")
  func partialReadHalfSecond() throws {
    let url = try AudioFixtures.url(for: "Quantum_Cascade", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 0.5)
    let expectedCount = Int(sampleRate * 0.5)
    #expect(samples.count <= expectedCount)
    #expect(samples.count > 0)
  }

  @Test("maxSeconds larger than file returns full file without error")
  func maxSecondsExceedsFile() throws {
    let url = try AudioFixtures.url(for: "sample", extension: "wav")
    // sample.wav is ~1s, request 60s — should return full file
    let (fullSamples, _) = try PCMBufferReader.readMonoSamples(from: url)
    let (partialSamples, _) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: 60)
    #expect(partialSamples.count == fullSamples.count)
  }
}

// MARK: - Downsampled Read Tests

@Suite("PCMBufferReader — Downsampled Read")
struct PCMBufferReaderDownsampleTests {

  @Test("downsample 44.1kHz to 4410 Hz returns correct sample rate")
  func downsampleRate() throws {
    let url = try AudioFixtures.url(for: "Meta_Man_La_Noche_Digital_", extension: "mp3")
    let (_, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, targetSampleRate: 4410)
    #expect(sampleRate == 4410)
  }

  @Test("downsampled sample count is approximately duration × targetRate")
  func downsampleCount() throws {
    let url = try AudioFixtures.url(for: "Meta_Man_La_Noche_Digital_", extension: "mp3")
    let (samples, _) = try PCMBufferReader.readMonoSamples(
      from: url, targetSampleRate: 4410)
    // ~31s × 4410 ≈ 136,710 samples (±10% tolerance for converter buffering)
    let expected = 31.0 * 4410.0
    let lowerBound = expected * 0.90
    let upperBound = expected * 1.10
    #expect(
      Double(samples.count) >= lowerBound && Double(samples.count) <= upperBound,
      "Expected ~\(Int(expected)) samples, got \(samples.count)"
    )
  }

  @Test("half-rate downsampling from 44.1kHz to 22050 Hz")
  func halfRateDownsample() throws {
    let url = try AudioFixtures.url(for: "Submerged_Lament", extension: "mp3")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(
      from: url, targetSampleRate: 22050)
    #expect(sampleRate == 22050)
    // ~31s × 22050 ≈ 683,550 samples (±10% tolerance)
    let expected = 31.0 * 22050.0
    #expect(
      Double(samples.count) >= expected * 0.90 && Double(samples.count) <= expected * 1.10,
      "Expected ~\(Int(expected)) samples, got \(samples.count)"
    )
  }
}

// MARK: - Error Handling Tests

@Suite("PCMBufferReader — Error Handling")
struct PCMBufferReaderErrorTests {

  @Test("throws for non-audio file")
  func nonAudioThrows() throws {
    let url = try #require(
      Bundle.module.url(forResource: "test-image", withExtension: "png", subdirectory: "Fixtures"),
      "Required fixture missing: test-image.png"
    )
    #expect(throws: PCMBufferReaderError.self) {
      _ = try PCMBufferReader.readMonoSamples(from: url)
    }
  }

  @Test("throws for nonexistent path")
  func nonexistentThrows() {
    let url = URL(fileURLWithPath: "/tmp/nonexistent_audio_file_32_1.wav")
    #expect(throws: PCMBufferReaderError.self) {
      _ = try PCMBufferReader.readMonoSamples(from: url)
    }
  }

  // MARK: - Format + corruption contracts (GH-167 item 5, #160)
  //
  // #160: "Documented format non-support and corruption behavior is untested."
  // Measuring it found the documentation was not merely untested but WRONG —
  // see `oggDecodesDespiteBeingDocumentedUnsupported` below.
  //
  // These assert the SPECIFIC error case, not just `PCMBufferReaderError.self`,
  // which would pass on any reader error and cannot distinguish `.fileNotReadable`
  // (open failed) from the documented-and-different `.readFailed` (failed
  // mid-stream). The localized `underlyingDescription` is deliberately NOT
  // asserted — it is AVFoundation's text and varies by OS.

  /// Writes `byteCount` leading bytes of a fixture to a unique temp file.
  /// Unique names (not the fixed names elsewhere in this file, which are #158's
  /// subject) so parallel runs cannot collide.
  private static func truncatedCopy(
    of name: String, ext: String, byteCount: Int
  ) throws -> URL {
    let data = try Data(contentsOf: AudioFixtures.url(for: name, extension: ext))
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("bbbk-trunc-\(UUID().uuidString).\(ext)")
    try data.prefix(byteCount).write(to: url)
    return url
  }

  /// GH-167 item 5 (#160). The library documented in four places that OGG/Vorbis
  /// could not be decoded ("no Core Audio codec on macOS"). Nothing tested it, and
  /// it is false: AVFoundation decodes Vorbis-in-Ogg on macOS 26. This test pins
  /// the ACTUAL behaviour so the corrected documentation stays honest.
  ///
  /// Scope: verified on macOS 26 only. Earlier macOS versions are untested, and a
  /// failure here on some future OS is a platform-capability change to document,
  /// not a library regression. Note the tags are still unread — `FileMetadataReader`
  /// wires its Vorbis-comment parser to FLAC only.
  @Test("Vorbis-in-Ogg decodes (the documented non-support claim was false)")
  func oggDecodesDespiteBeingDocumentedUnsupported() throws {
    let url = try AudioFixtures.url(for: "vorbis-decodable", extension: "ogg")
    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(!samples.isEmpty, "#160: expected a real decode, got no samples")
    #expect(sampleRate == 44100)
    #expect(samples.allSatisfy { $0.isFinite }, "#160: decoded samples must be finite")
    #expect(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 }, "#160: samples must be normalized")
  }

  /// GH-167 item 5 (#160). A FLAC truncated to 10% fails to open — the one
  /// measured case where mid-stream corruption is genuinely fatal. Asserts the
  /// exact case and URL.
  @Test("severely truncated FLAC throws .fileNotReadable")
  func truncatedFLACThrowsFileNotReadable() throws {
    let url = try Self.truncatedCopy(of: "test-audio", ext: "flac", byteCount: 2032)
    defer { try? FileManager.default.removeItem(at: url) }

    do {
      _ = try PCMBufferReader.readMonoSamples(from: url)
      Issue.record("#160: expected a throw for a 10%-truncated FLAC, got a successful read")
    } catch let error as PCMBufferReaderError {
      guard case .fileNotReadable(let reported) = error else {
        Issue.record(Comment(rawValue: "#160: expected .fileNotReadable, got \(error)"))
        return
      }
      #expect(reported == url, "#160: error should carry the URL that failed")
    }
  }

  /// GH-167 item 5 (#160). Truncation is NOT reliably fatal, which is why this
  /// asserts safety rather than failure. A truncated MP3 with intact leading
  /// frames decodes at every fraction measured (10/50/90%), so the contract worth
  /// pinning is that a partial file never yields unsafe output — no NaN, no
  /// out-of-range samples, no bogus rate.
  ///
  /// Deliberately no assertion on sample COUNT: decoded length from a truncated
  /// stream is an AVFoundation implementation detail that drifts across OS
  /// versions. This portion of #160 (a *fatal* mid-stream MP3 failure) has no
  /// reachable case and stays open — see deferred-work.
  @Test("truncated MP3 decodes safely rather than failing", arguments: [10, 50, 90])
  func truncatedMP3DecodesSafely(percent: Int) throws {
    let full = try Data(contentsOf: AudioFixtures.url(for: "Meta_Man", extension: "mp3"))
    let url = try Self.truncatedCopy(
      of: "Meta_Man", ext: "mp3", byteCount: full.count * percent / 100)
    defer { try? FileManager.default.removeItem(at: url) }

    let (samples, sampleRate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(sampleRate == 44100, "#160: truncation must not corrupt the reported sample rate")
    #expect(
      samples.allSatisfy { $0.isFinite }, "#160: truncated decode produced non-finite samples")
    #expect(
      samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 },
      "#160: truncated decode produced out-of-range samples")
  }
}

// MARK: - File Duration Tests (Story 3-4)

@Suite("PCMBufferReader — File Duration")
struct PCMBufferReaderFileDurationTests {

  @Test("fileDuration returns expected seconds within one-sample tolerance")
  func fileDurationReturnsExpectedSeconds() throws {
    let sampleRate: Double = 44100
    let durationSeconds: Double = 30
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("pcm_reader_duration_30s.wav")
    defer { try? FileManager.default.removeItem(at: tempURL) }

    try createClickTrackWAVFixture(
      bpm: 120, sampleRate: sampleRate, durationSeconds: durationSeconds, url: tempURL)

    let actual = try PCMBufferReader.fileDuration(url: tempURL)
    // One-sample tolerance accounts for WAV header frame-count rounding (AC #8).
    #expect(abs(actual - durationSeconds) < 1.0 / sampleRate)
  }

  @Test("fileDuration throws PCMBufferReaderError for unreadable file")
  func fileDurationThrowsForUnreadableFile() {
    let url = URL(fileURLWithPath: "/nonexistent/duration_test_no_file_3_4.wav")
    #expect(throws: PCMBufferReaderError.self) {
      _ = try PCMBufferReader.fileDuration(url: url)
    }
  }

  // Code-review Patch #5 (Story 3-4): a malformed WAV with sampleRate=0 must throw,
  // not return `inf`. Either AVAudioFile rejects the file (existing
  // `.fileNotReadable` path) or it opens with sampleRate==0 (Patch #5 guard fires).
  // The contract is the same: throw — never return a non-finite duration.
  @Test("fileDuration throws when sampleRate is zero (Patch #5)")
  func fileDurationThrowsOnZeroSampleRate() throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("pcm_reader_zero_samplerate.wav")
    defer { try? FileManager.default.removeItem(at: url) }

    // Minimal 44-byte WAV header with the sampleRate field (offset 24-27, little-endian)
    // zeroed. Other fields are valid PCM mono 16-bit.
    var bytes: [UInt8] = []
    bytes += Array("RIFF".utf8)
    bytes += [36, 0, 0, 0]  // ChunkSize - 8 (header only, zero body)
    bytes += Array("WAVE".utf8)
    bytes += Array("fmt ".utf8)
    bytes += [16, 0, 0, 0]  // Subchunk1Size = 16 (PCM)
    bytes += [1, 0]  // AudioFormat = 1 (PCM)
    bytes += [1, 0]  // NumChannels = 1
    bytes += [0, 0, 0, 0]  // SampleRate = 0  <- malformed
    bytes += [0, 0, 0, 0]  // ByteRate
    bytes += [2, 0]  // BlockAlign
    bytes += [16, 0]  // BitsPerSample
    bytes += Array("data".utf8)
    bytes += [0, 0, 0, 0]  // Subchunk2Size = 0
    try Data(bytes).write(to: url)

    #expect(throws: PCMBufferReaderError.self) {
      _ = try PCMBufferReader.fileDuration(url: url)
    }
  }
}

// MARK: - Test fixture helper (duplicated from AudioAnalysisServiceTests.swift per Story 3-4
// Dev Notes "Test fixture access" Option A — promote to TestSupport in a follow-up hygiene story).

/// Creates a minimal WAV file with a synthetic click track.
private func createClickTrackWAVFixture(
  bpm: Double, sampleRate: Double, durationSeconds: Double, url: URL
) throws {
  let sampleCount = Int(sampleRate * durationSeconds)
  var samples = [Float](repeating: 0, count: sampleCount)
  let samplesPerBeat = Int(sampleRate * 60.0 / bpm)

  for beatStart in stride(from: 0, to: sampleCount, by: samplesPerBeat) {
    let impulseEnd = min(beatStart + 64, sampleCount)
    for i in beatStart..<impulseEnd {
      let decay = Float(exp(-Double(i - beatStart) / 10.0))
      samples[i] = decay
    }
  }

  guard
    let format = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: sampleRate,
      channels: 1,
      interleaved: false)
  else {
    throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad format"])
  }

  let file = try AVAudioFile(forWriting: url, settings: format.settings)
  guard
    let buffer = AVAudioPCMBuffer(
      pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))
  else {
    throw NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Buffer failed"])
  }

  buffer.frameLength = AVAudioFrameCount(sampleCount)
  samples.withUnsafeBufferPointer { srcPtr in
    guard let baseAddress = srcPtr.baseAddress else { return }
    buffer.floatChannelData![0].update(from: baseAddress, count: sampleCount)
  }

  try file.write(from: buffer)
}
