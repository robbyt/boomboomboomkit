//
//  WholeTrackCancellationTests.swift
//  BoomBoomBoomKitTests
//
//  Cancel stops the three long steps a whole-track model adds part way: the
//  file read (10 s chunks), the 44.1 kHz conversion (10 s chunks), and the
//  model step (between crop scores, crop tensors and inferences). Each
//  chunked step must give the same bits as the single step it replaced.
//

import AVFoundation
import Accelerate
import BoomBoomBoomKitTestSupport
import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit
@testable import BoomBoomBoomKitML

// MARK: - Helpers

/// Counts `isCancelled` calls and returns `true` from call number
/// `cancelAtCall` on (1-based); `nil` never cancels. With `once`, only call
/// `cancelAtCall` returns `true` and every later call returns `false`.
private final class CancelCounter: Sendable {
  private let state = Mutex(0)
  private let cancelAtCall: Int?
  private let once: Bool

  init(cancelAtCall: Int?, once: Bool = false) {
    self.cancelAtCall = cancelAtCall
    self.once = once
  }

  var calls: Int { state.withLock { $0 } }

  func check() -> Bool {
    state.withLock { count in
      count += 1
      guard let cancelAtCall else { return false }
      return once ? count == cancelAtCall : count >= cancelAtCall
    }
  }
}

/// Requires `url` to be longer than two read chunks: only then does the
/// reader check cancellation between chunks.
private func requireLongerThanTwoChunks(_ url: URL) throws {
  let duration = try PCMBufferReader.fileDuration(url: url)
  try #require(
    duration > 2 * PCMBufferReader.readChunkSeconds,
    "\(url.lastPathComponent) is \(duration) s; a file of two read chunks or less is read in one call and never checked"
  )
}

private func bits(_ samples: [Float]) -> [UInt32] { samples.map(\.bitPattern) }

/// The reader's output computed without the reader: one
/// `AVAudioFile.read(into:frameCount:)` of the capped span, mixed to mono
/// with the same vDSP calls the reader used before chunking.
private func singleReadMono(_ url: URL, maxSeconds: Double?) throws -> [Float] {
  let file = try AVAudioFile(forReading: url)
  let format = file.processingFormat
  let total = Int(AVAudioFrameCount(clamping: file.length))
  let frames =
    PCMBufferReader.sanitizedMaxSeconds(maxSeconds).map {
      PCMBufferReader.framesFromCap(
        sampleRate: format.sampleRate, maxSeconds: $0, total: total, zeroOnNonPositive: true)
    } ?? total
  if frames == 0 { return [] }
  let buffer = try #require(
    AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)))
  try file.read(into: buffer, frameCount: AVAudioFrameCount(frames))
  let data = try #require(buffer.floatChannelData)
  let count = Int(buffer.frameLength)
  let channels = Int(format.channelCount)
  var mono: [Float]
  if channels == 1 {
    mono = Array(UnsafeBufferPointer(start: data[0], count: count))
  } else if channels == 2 {
    mono = [Float](repeating: 0, count: count)
    vDSP.add(
      UnsafeBufferPointer(start: data[0], count: count),
      UnsafeBufferPointer(start: data[1], count: count), result: &mono)
    var divisor: Float = 2
    vDSP_vsdiv(mono, 1, &divisor, &mono, 1, vDSP_Length(count))
  } else {
    mono = [Float](repeating: 0, count: count)
    for ch in 0..<channels {
      vDSP_vadd(mono, 1, data[ch], 1, &mono, 1, vDSP_Length(count))
    }
    var divisor = Float(channels)
    vDSP_vsdiv(mono, 1, &divisor, &mono, 1, vDSP_Length(count))
  }
  for i in 0..<mono.count where !mono[i].isFinite { mono[i] = 0 }
  return mono
}

/// A float32 WAV of a 120 BPM click track. A large read of this format stops
/// at a 1,024-frame boundary, so it pins the reader's short-read behaviour.
private func floatWAV(
  seconds: Double, channels: AVAudioChannelCount, sampleRate: Double = 44_100, in folder: URL
) throws -> URL {
  let click = generateClickTrack(bpm: 120, sampleRate: sampleRate, durationSeconds: seconds)
  let samples = (0..<Int(channels)).map { ch in click.map { $0 / Float(ch + 1) } }
  return try SyntheticAudioFiles.writeFile(
    SyntheticAudioFile(
      frames: click.count, channels: channels, sampleRate: sampleRate, container: .wav),
    samples: samples, in: folder)
}

private func makeFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory
    .appendingPathComponent("whole-track-cancel-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}

private func decoded(_ samples: [Float], rate: Double = 44_100) -> FeatureSubstrate.DecodedAudio {
  FeatureSubstrate.DecodedAudio(
    samples: samples, sampleRate: rate,
    codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone))
}

private func fixtureModel(_ name: String) -> URL? {
  guard let resourceURL = Bundle.module.resourceURL else { return nil }
  let url = resourceURL.appendingPathComponent("Fixtures").appendingPathComponent(name)
  return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

private func modelMissing() -> Bool { fixtureModel("FixedTimeTiny.mlmodelc") == nil }

/// Click track with seeded noise, so a conversion has detail to get wrong.
private func noisyClick(rate: Double, seconds: Double) -> [Float] {
  var rng = SplitMix64(seed: 7)
  return generateClickTrack(bpm: 128, sampleRate: rate, durationSeconds: seconds).map {
    $0 + Float(Double(rng.next() % 2001) / 1000 - 1) * 0.05
  }
}

// MARK: - Reader

@Suite("Chunked file read")
struct ChunkedReadTests {

  /// Every bundled audio format, short and long.
  static let fixtures: [(name: String, ext: String)] = [
    ("test-bwf", "wav"), ("sample", "wav"), ("Meta_Man", "mp3"), ("robbyt_x-ray-30s", "mp3"),
    ("test-audio", "flac"), ("sample-with-cover", "flac"), ("test-audio", "m4a"),
    ("test-alac", "m4a"), ("sample-with-cover", "aiff"), ("test-bwf", "caf"),
    ("test-ulaw", "caf"), ("vorbis-decodable", "ogg"),
  ]

  @Test(
    "chunked read equals one read, capped and uncapped, for every bundled format",
    arguments: fixtures)
  func bundledFormats(fixture: (name: String, ext: String)) throws {
    let url = try AudioFixtures.url(for: fixture.name, extension: fixture.ext)
    let duration = try PCMBufferReader.fileDuration(url: url)
    for maxSeconds in [nil, duration * 0.6] as [Double?] {
      // Default (10 s), and small chunks so short fixtures span many reads.
      for chunk in [nil, 10_007, 4_096, 1_000] as [AVAudioFrameCount?] {
        try expectSameAsSingleRead(url, maxSeconds: maxSeconds) {
          try PCMBufferReader.readDecodedAudio(
            from: url, maxSeconds: maxSeconds, isCancelled: { false }, chunkFrames: chunk
          ).samples
        }
      }
      try expectSameAsSingleRead(url, maxSeconds: maxSeconds) {
        try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: maxSeconds).samples
      }
    }
  }

  /// Expects `read` to give the same bits as one plain `AVAudioFile` read.
  ///
  /// AAC decoding is not bit-reproducible inside this test process: two plain
  /// single reads of `test-audio.m4a`, with no reader code involved, have come
  /// back with two different decodes (36,543 of 44,100 samples apart, by at
  /// most 1.1e-7). So each comparison is retried with a fresh pair of reads,
  /// up to 5 times. A chunking error is systematic and fails every attempt;
  /// the deterministic formats match on the first.
  private func expectSameAsSingleRead(
    _ url: URL, maxSeconds: Double?, _ read: () throws -> [Float]
  ) throws {
    var mismatches = 0
    for _ in 0..<5 {
      let expected = bits(try singleReadMono(url, maxSeconds: maxSeconds))
      try #require(!expected.isEmpty)
      if bits(try read()) == expected { return }
      mismatches += 1
    }
    Issue.record(
      "\(url.lastPathComponent) cap \(String(describing: maxSeconds)): \(mismatches) of 5 reads differ"
    )
  }

  @Test(
    "float WAV: the chunked read keeps the single read's short end, capped and uncapped",
    arguments: [1, 2, 6] as [AVAudioChannelCount], [44_100.0, 48_000.0])
  func floatWAVShortEnd(channels: AVAudioChannelCount, sampleRate: Double) throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try floatWAV(seconds: 30, channels: channels, sampleRate: sampleRate, in: folder)
    let length = try AVAudioFile(forReading: url).length
    for maxSeconds in [nil, 15, 25] as [Double?] {
      let expected = bits(try singleReadMono(url, maxSeconds: maxSeconds))
      let requested =
        maxSeconds.map {
          PCMBufferReader.framesFromCap(
            sampleRate: sampleRate, maxSeconds: $0, total: Int(length), zeroOnNonPositive: true)
        } ?? Int(length)
      // Chunk sizes on and off the 1,024-frame boundary, and the default.
      for chunk in [1_024, 4_096, 10_007, nil] as [AVAudioFrameCount?] {
        let read = try PCMBufferReader.readDecodedAudio(
          from: url, maxSeconds: maxSeconds, isCancelled: { false }, chunkFrames: chunk)
        let label = "cap \(String(describing: maxSeconds)) chunk \(String(describing: chunk))"
        if channels == 1, chunk != nil {
          // Measured on macOS 27: small reads of a mono float WAV often come
          // back whole, so a read in small chunks can get past the 1,024-frame
          // boundary where one large read stops (at 44.1 kHz it reaches the
          // requested end; at 48 kHz with 10,007-frame chunks it stops where
          // the single read does). It never loses a sample the single read
          // keeps. The service reads only in default chunks, which match the
          // single read (below).
          #expect(Array(bits(read.samples).prefix(expected.count)) == expected, "\(label)")
          #expect(
            (expected.count...requested).contains(read.samples.count),
            "\(label): \(read.samples.count) not in \(expected.count)...\(requested)")
        } else {
          #expect(bits(read.samples) == expected, "\(label)")
        }
        if maxSeconds == nil, channels == 1, chunk == nil {
          // The premise: one large read of a mono float WAV stops short of
          // the end; otherwise this test would not pin the short end.
          #expect(Int64(read.samples.count) < length)
        }
      }
    }
  }

  @Test("a cut FLAC: the chunked read stops at the real end, as one read does")
  func cutFLAC() throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let url = try SyntheticAudioFiles.writeToneFLAC(in: folder)
    let size = try #require(
      try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
    try SyntheticAudioFiles.truncate(url, to: size - SyntheticAudioFile.flacTailCut)
    let expected = bits(try singleReadMono(url, maxSeconds: nil))
    #expect(Int64(expected.count) < (try AVAudioFile(forReading: url).length), "the premise")
    for chunk in [nil, 10_007, 4_096] as [AVAudioFrameCount?] {
      let read = try PCMBufferReader.readDecodedAudio(
        from: url, maxSeconds: nil, isCancelled: { false }, chunkFrames: chunk)
      #expect(bits(read.samples) == expected, "chunk \(String(describing: chunk))")
    }
  }

  @Test("a closure that turns true after the first chunk throws CancellationError")
  func cancelAfterFirstChunk() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    try requireLongerThanTwoChunks(url)
    let counter = CancelCounter(cancelAtCall: 1)
    #expect(throws: CancellationError.self) {
      _ = try PCMBufferReader.readDecodedAudio(
        from: url, maxSeconds: nil, isCancelled: { counter.check() })
    }
    #expect(counter.calls == 1, "the first chunk is read before the first check")
  }

  @Test("a file that fits in one read is never checked")
  func shortFileNotChecked() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let counter = CancelCounter(cancelAtCall: 1)
    _ = try PCMBufferReader.readDecodedAudio(
      from: url, maxSeconds: nil, isCancelled: { counter.check() })
    #expect(counter.calls == 0)
  }

  @Test("the public cancellable read throws CancellationError when the closure is true")
  func publicReadCancels() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    try requireLongerThanTwoChunks(url)
    // No maxSeconds and no chunkFrames: the public three-argument form.
    #expect(throws: CancellationError.self) {
      _ = try PCMBufferReader.readDecodedAudio(from: url, isCancelled: { true })
    }
  }

  @Test("the public cancellable read equals the plain read when the closure is false")
  func publicReadMatchesPlainRead() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    try requireLongerThanTwoChunks(url)
    let plain = try PCMBufferReader.readDecodedAudio(from: url)
    let cancellable = try PCMBufferReader.readDecodedAudio(from: url, isCancelled: { false })
    #expect(cancellable.sampleRate == plain.sampleRate)
    #expect(cancellable.samples.count == plain.samples.count)
    #expect(bits(cancellable.samples) == bits(plain.samples))
  }

  @Test("the service's decode checks Options.isCancelled between chunks")
  func serviceDecodeCancels() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    try requireLongerThanTwoChunks(url)
    // Call 1 is decodeOnce's check before the read; call 2 is between chunks.
    let counter = CancelCounter(cancelAtCall: 2)
    let decodes = Mutex(0)
    var options = LUFSOptions()
    options.isCancelled = { counter.check() }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(
        url: url, options: options, decodeObserver: { _ in decodes.withLock { $0 += 1 } })
    }
    #expect(decodes.withLock { $0 } == 0, "the decode stopped part way")
    #expect(counter.calls == 2)
  }

  /// A whole-track technique that records whether it was called.
  private final class CalledFlag: WholeTrackMLTechnique, @unchecked Sendable {
    private let called = Mutex(false)
    var wasCalled: Bool { called.withLock { $0 } }
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
    func evaluate(
      trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio,
      isCancelled: @Sendable () -> Bool
    ) -> (
      evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
    ) {
      called.withLock { $0 = true }
      return (nil, nil, nil)
    }
  }

  @Test("analyzeBPM(url:) with a whole-track technique stops its whole-file decode between chunks")
  func wholeTrackURLDecodeCancels() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    try requireLongerThanTwoChunks(url)
    // Call 1 is the URL inputs' check, call 2 decodeOnce's check before the
    // read, call 3 the reader's check after the first chunk.
    let counter = CancelCounter(cancelAtCall: 3)
    let stub = CalledFlag()
    let decodes = Mutex(0)
    var options = AudioAnalysisService.Options()
    options.mlTechnique = stub
    options.ensemblePolicy = .mlOnly
    // A one-chunk cap: without the whole-track decode there would be no check
    // between chunks.
    options.maxSeconds = PCMBufferReader.readChunkSeconds
    options.isCancelled = { counter.check() }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(
        url: url, options: options, decodeObserver: { _ in decodes.withLock { $0 += 1 } })
    }
    #expect(counter.calls == 3)
    #expect(decodes.withLock { $0 } == 0, "the decode stopped part way")
    #expect(!stub.wasCalled)
  }

  @Test(".dspOnly url-path output is byte-identical to analyzing a single-read decode")
  func dspOnlyURLPathIdentical() throws {
    let url = try AudioFixtures.url(for: "Meta_Man", extension: "mp3")
    let single = decoded(try singleReadMono(url, maxSeconds: nil))
    var options = AudioAnalysisService.Options()
    options.enableTrace = true
    let a = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: options))
    let b = try #require(try AudioAnalysisService.analyzeBPM(decoded: single, options: options))
    #expect(a.bpm.bitPattern == b.bpm.bitPattern)
    #expect(a.confidence.bitPattern == b.confidence.bitPattern)
    #expect(a.candidates.map(\.bpm) == b.candidates.map(\.bpm))
    #expect(a.candidates.map(\.score) == b.candidates.map(\.score))
    #expect(a.trace?.rawCandidates.map(\.bpm) == b.trace?.rawCandidates.map(\.bpm))
    let loudnessA = try AudioAnalysisService.analyzeLUFS(url: url)
    let loudnessB = try AudioAnalysisService.analyzeLUFS(decoded: single)
    #expect(loudnessA == loudnessB)
  }
}

// MARK: - Conversion

@Suite("Chunked 44.1 kHz conversion")
struct ChunkedConversionTests {

  @Test(
    "feeding the converter in chunks equals feeding it all at once",
    arguments: [
      (48_000.0, 44_100.0), (22_050.0, 44_100.0), (96_000.0, 22_050.0), (44_100.0, 16_000.0),
      (8_000.0, 44_100.0),
    ])
  func chunkedEqualsOneShot(rates: (from: Double, to: Double)) throws {
    let seconds = 25.0
    #expect(seconds > 2 * PCMBufferReader.readChunkSeconds, "longer than two default chunks")
    let samples = noisyClick(rate: rates.from, seconds: seconds)
    let oneShot = try PCMBufferReader.resampleMono(
      samples, fromRate: rates.from, toRate: rates.to, isCancelled: { false }, chunkFrames: .max)
    #expect(abs(oneShot.count - Int(seconds * rates.to)) < 64)
    for chunk in [nil, 10_007, 4_096] as [AVAudioFrameCount?] {
      let chunked = try PCMBufferReader.resampleMono(
        samples, fromRate: rates.from, toRate: rates.to, isCancelled: { false },
        chunkFrames: chunk)
      #expect(bits(chunked) == bits(oneShot), "chunk \(String(describing: chunk))")
    }
    if rates.to == 44_100 {
      let viaCrops = try FeatureSubstrate.FixedTimeCrops.samplesAt44k(
        decoded(samples, rate: rates.from))
      #expect(bits(viaCrops) == bits(oneShot))
    }
  }

  @Test("a closure that turns true after the first chunk throws CancellationError")
  func cancelAfterFirstChunk() throws {
    let samples = noisyClick(rate: 48_000, seconds: 25)
    let counter = CancelCounter(cancelAtCall: 1)
    #expect(throws: CancellationError.self) {
      _ = try FeatureSubstrate.FixedTimeCrops.samplesAt44k(
        decoded(samples, rate: 48_000), isCancelled: { counter.check() })
    }
    #expect(counter.calls == 1)
  }
}

// MARK: - Model step

@Suite("Fixed-time model step cancellation")
struct ModelStepCancellationTests {

  @Test("build throws CancellationError at every check, and is unchanged when none fires")
  func buildChecks() throws {
    let audio = decoded(generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 40))
    let reference = try FeatureSubstrate.FixedTimeCrops.build(decoded: audio)
    let checks = reference.candidates.count + reference.keptCrops.count
    #expect(reference.candidates.count == 6)
    #expect(!reference.keptCrops.isEmpty)
    for k in 1...checks {
      let counter = CancelCounter(cancelAtCall: k)
      #expect(throws: CancellationError.self, "check \(k) of \(checks)") {
        _ = try FeatureSubstrate.FixedTimeCrops.build(
          decoded: audio, isCancelled: { counter.check() })
      }
      #expect(counter.calls == k)
    }
    let counter = CancelCounter(cancelAtCall: checks + 1)
    let unchanged = try FeatureSubstrate.FixedTimeCrops.build(
      decoded: audio, isCancelled: { counter.check() })
    #expect(counter.calls == checks)
    #expect(unchanged.candidates == reference.candidates)
    #expect(unchanged.keptCrops == reference.keptCrops)
    #expect(unchanged.keptTensors.map(bits) == reference.keptTensors.map(bits))
  }

  @Test(
    "the technique returns nothing once a check between inferences fires",
    .disabled(if: modelMissing(), "model fixture missing"))
  func techniqueStopsBetweenInferences() throws {
    let technique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    let audio = decoded(generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 40))
    let crops = try FeatureSubstrate.FixedTimeCrops.build(decoded: audio)
    let buildChecks = crops.candidates.count + crops.keptCrops.count
    // Every check, through the last inference check, stops with no result.
    for k in 1...(buildChecks + crops.keptCrops.count) {
      let counter = CancelCounter(cancelAtCall: k)
      let out = technique.evaluate(
        trace: BPMDiagnosticTrace(), audio: audio, isCancelled: { counter.check() })
      #expect(out.evaluation == nil, "check \(k)")
      #expect(out.crops == nil, "check \(k)")
      #expect(out.snapshot == nil, "check \(k)")
      // It stopped at the first `true`: no check after it.
      #expect(counter.calls == k, "check \(k)")
    }
    let full = technique.evaluate(
      trace: BPMDiagnosticTrace(), audio: audio, isCancelled: { false })
    #expect(full.evaluation != nil)
  }

  /// Records how many `isCancelled` calls the service made before the model
  /// step, then abstains.
  private final class CallsBeforeModelStep: WholeTrackMLTechnique, @unchecked Sendable {
    let counter: CancelCounter
    private let recorded = Mutex<Int?>(nil)
    init(counter: CancelCounter) { self.counter = counter }
    var callsBefore: Int? { recorded.withLock { $0 } }
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
    func evaluate(
      trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio,
      isCancelled: @Sendable () -> Bool
    ) -> (
      evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
    ) {
      recorded.withLock { $0 = counter.calls }
      return (nil, nil, nil)
    }
  }

  /// Forwards to `inner`, counting the checks `inner` makes on the closure
  /// the service passes.
  private final class CountsChecks: WholeTrackMLTechnique, @unchecked Sendable {
    let inner: any WholeTrackMLTechnique
    private let count = Mutex(0)
    init(_ inner: any WholeTrackMLTechnique) { self.inner = inner }
    var checks: Int { count.withLock { $0 } }
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { inner.evaluate(trace: trace) }
    func evaluate(
      trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio,
      isCancelled: @Sendable () -> Bool
    ) -> (
      evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
    ) {
      withoutActuallyEscaping(isCancelled) { isCancelled in
        inner.evaluate(
          trace: trace, audio: audio,
          isCancelled: {
            self.count.withLock { $0 += 1 }
            return isCancelled()
          })
      }
    }
  }

  /// Checks cancellation once, records the answer, and abstains whatever it
  /// was: a technique that relies on the service to tell a stop from an
  /// abstain.
  private final class ChecksOnce: WholeTrackMLTechnique, @unchecked Sendable {
    private let answer = Mutex<Bool?>(nil)
    var answered: Bool? { answer.withLock { $0 } }
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
    func evaluate(
      trace: BPMDiagnosticTrace, audio: FeatureSubstrate.DecodedAudio,
      isCancelled: @Sendable () -> Bool
    ) -> (
      evaluation: MLEvaluation?, crops: MLInputCropEvidence?, snapshot: MLDiagnosticSnapshot?
    ) {
      let cancelled = isCancelled()
      answer.withLock { $0 = cancelled }
      return (nil, nil, nil)
    }
  }

  private static func options(
    _ technique: any WholeTrackMLTechnique, _ counter: CancelCounter
  ) -> AudioAnalysisService.Options {
    var options = AudioAnalysisService.Options()
    options.mlTechnique = technique
    options.ensemblePolicy = .default
    options.enableTrace = true
    options.enableMLDiagnostics = true
    options.isCancelled = { counter.check() }
    return options
  }

  /// How many `isCancelled` calls the service makes before the model step.
  private static func callsBeforeModelStep(_ audio: FeatureSubstrate.DecodedAudio) throws -> (
    before: Int, total: Int
  ) {
    let counter = CancelCounter(cancelAtCall: nil)
    let probe = CallsBeforeModelStep(counter: counter)
    _ = try AudioAnalysisService.analyzeBPM(decoded: audio, options: options(probe, counter))
    return (try #require(probe.callsBefore), counter.calls)
  }

  @Test(
    "analyzeBPM(decoded:) throws CancellationError when cancel fires inside the model step",
    .disabled(if: modelMissing(), "model fixture missing"))
  func serviceThrowsDuringModelStep() throws {
    let audio = decoded(generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 40))
    // Calls before the model step, measured with a stub in the same seat.
    let probe = try Self.callsBeforeModelStep(audio)

    let technique = try FixedTimeTechnique(
      modelURL: #require(fixtureModel("FixedTimeTiny.mlmodelc")))
    let crops = try FeatureSubstrate.FixedTimeCrops.build(decoded: audio)
    let modelChecks = crops.candidates.count + 2 * crops.keptCrops.count
    // Without a cancel, the technique adds exactly its own checks.
    let full = CancelCounter(cancelAtCall: nil)
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: audio, options: Self.options(technique, full)))
    #expect(full.calls == probe.total + modelChecks)
    #expect(result.trace?.mlInputCrops != nil)
    // Cancel at each check inside the model step.
    for offset in 1...modelChecks {
      let counter = CancelCounter(cancelAtCall: probe.before + offset)
      let counted = CountsChecks(technique)
      #expect(throws: CancellationError.self, "model-step check \(offset) of \(modelChecks)") {
        _ = try AudioAnalysisService.analyzeBPM(
          decoded: audio, options: Self.options(counted, counter))
      }
      // The technique stopped at its first `true` answer, and the service's
      // check after it read the latch without asking the closure again.
      #expect(counted.checks == offset, "model-step check \(offset)")
      #expect(counter.calls == probe.before + offset, "model-step check \(offset)")
    }
  }

  @Test("a closure that answers true once in the model step, then false, still cancels")
  func trueOnceDuringModelStep() throws {
    let audio = decoded(generateClickTrack(bpm: 120, sampleRate: 44_100, durationSeconds: 40))
    let probe = try Self.callsBeforeModelStep(audio)
    let counter = CancelCounter(cancelAtCall: probe.before + 1, once: true)
    let technique = ChecksOnce()
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(
        decoded: audio, options: Self.options(technique, counter))
    }
    #expect(technique.answered == true)
    #expect(
      counter.calls == probe.before + 1,
      "the check after the model step reads the latch, not the closure")
  }
}
