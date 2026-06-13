//
//  SharedDecodeTests.swift
//  BoomBoomBoomKitTests
//
//  Story 8-2 shared-decode seam tests: DecodedAudio currency migration locks
//  (commit 1), then the decodeOnce funnel / decoded-overload equality,
//  cancellation, and codec-tagging suites (commit 2+).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit

// MARK: - Decode-count probe (DD #9)

/// Mutex-boxed decode counter for the AC1 structural gate. `Mutex` is
/// `~Copyable`, so an escaping `@Sendable` observer closure cannot capture it
/// directly — the final-class box is the sanctioned pattern (axiom-confirmed,
/// Story 8-2 review round).
private final class DecodeProbe: Sendable {
  private let state = Mutex<(count: Int, lastSampleCount: Int?)>((0, nil))

  func record(_ decoded: FeatureSubstrate.DecodedAudio) {
    state.withLock {
      $0.count += 1
      $0.lastSampleCount = decoded.samples.count
    }
  }

  var count: Int { state.withLock { $0.count } }
  var lastSampleCount: Int? { state.withLock { $0.lastSampleCount } }
}

/// Mutex-boxed cancellation script: returns `false` for the first
/// `falseCount` calls, then `true` — deterministic mid-flight cancellation
/// without timing races.
private final class CancellationScript: Sendable {
  private let remaining: Mutex<Int>

  init(falseCount: Int) {
    remaining = Mutex(falseCount)
  }

  func isCancelled() -> Bool {
    remaining.withLock {
      if $0 > 0 {
        $0 -= 1
        return false
      }
      return true
    }
  }
}

// MARK: - Commit 1: DecodedAudio currency locks

@Suite("Shared Decode — DecodedAudio currency (commit 1)")
struct DecodedAudioCurrencyTests {

  /// DD #4 provenance-invariance: `DecodedAudio` is a carrier — nothing
  /// downstream may branch on provenance fields. Same samples under two
  /// different codec tags must produce bitPattern-identical `BPMResult`.
  @Test func bpmProvenanceInvariance() throws {
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 44100, durationSeconds: 15)
    let taggedLPCM = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 44100,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone))
    let taggedMP3 = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 44100,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .mp3, trimState: .unknown))

    let lpcmResult = try #require(BPMAnalyzer.estimateBPM(decoded: taggedLPCM))
    let mp3Result = try #require(BPMAnalyzer.estimateBPM(decoded: taggedMP3))

    #expect(lpcmResult.bpm.bitPattern == mp3Result.bpm.bitPattern)
    #expect(lpcmResult.confidence.bitPattern == mp3Result.confidence.bitPattern)
    try #require(lpcmResult.candidates.count == mp3Result.candidates.count)
    for (a, b) in zip(lpcmResult.candidates, mp3Result.candidates) {
      #expect(a.bpm.bitPattern == b.bpm.bitPattern)
      #expect(a.score.bitPattern == b.score.bitPattern)
    }
  }

  /// DD #4 provenance-invariance for the LUFS analyzer: same samples, two
  /// codec tags, bitPattern-identical integrated loudness + block series.
  @Test func lufsProvenanceInvariance() throws {
    let samples = generateClickTrack(
      bpm: 120, sampleRate: 48000, durationSeconds: 10)
    let taggedLPCM = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 48000,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .linearPCM, trimState: .knownNone))
    let taggedAAC = FeatureSubstrate.DecodedAudio(
      samples: samples, sampleRate: 48000,
      codecPriming: FeatureSubstrate.PrimingInfo(
        codec: .aac, trimState: .unknown))

    let lpcmResult = try #require(LUFSAnalyzer.measureLoudness(decoded: taggedLPCM))
    let aacResult = try #require(LUFSAnalyzer.measureLoudness(decoded: taggedAAC))

    #expect(
      lpcmResult.integratedLoudness.bitPattern == aacResult.integratedLoudness.bitPattern)
    try #require(
      lpcmResult.blockLoudnessValues.count == aacResult.blockLoudnessValues.count)
    for (a, b) in zip(lpcmResult.blockLoudnessValues, aacResult.blockLoudnessValues) {
      #expect(a.bitPattern == b.bitPattern)
    }
  }

  /// DD #5: analyzers still never throw — a `DecodedAudio` at the 8 kHz
  /// precondition boundary (valid carrier, unsupported K-weighting rate)
  /// returns nil from the analyzer. The matching SERVICE-level throw is
  /// locked in the decoded-overload suite (commit 2+).
  @Test func lufsAnalyzerUnsupportedRateReturnsNil() {
    let samples = [Float](repeating: 0.25, count: 8_000)
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(samples, sampleRate: 8_000)
    #expect(LUFSAnalyzer.measureLoudness(decoded: decoded) == nil)
  }

  /// Codex review (thread 019eb486) MAJOR regression lock: a synthetic
  /// carrier with an absurd-but-precondition-valid sample rate must not
  /// trap in the decoded overloads' cap arithmetic. BPM: the cap no-ops and
  /// the sub-minimum duration guard returns nil. LUFS: the rate guard
  /// throws `unsupportedSampleRate`.
  @Test func hugeSampleRateCarrierDoesNotTrap() throws {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(
      [Float](repeating: 0.25, count: 48_000), sampleRate: 1.0e20)
    #expect(try AudioAnalysisService.analyzeBPM(decoded: decoded) == nil)
    #expect(throws: LUFSAnalysisError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
    }
  }

  /// `synthetic` pins provenance — the single test-construction path never
  /// hand-picks codec tags (DD #4).
  @Test func syntheticPinsProvenance() {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic([0.0], sampleRate: 44100)
    #expect(decoded.codecPriming.codec == .linearPCM)
    #expect(decoded.codecPriming.trimState == .knownNone)
    #expect(decoded.sampleRate == 44100)
    #expect(decoded.samples.count == 1)
  }
}

// MARK: - AC6: readDecodedAudio producer — codec tagging + trim provenance

@Suite("Shared Decode — readDecodedAudio producer (AC6)")
struct ReadDecodedAudioProducerTests {

  private func tag(
    _ name: String, _ ext: String
  ) throws -> FeatureSubstrate.PrimingInfo {
    let url = try AudioFixtures.url(for: name, extension: ext)
    // maxSeconds: 1 — provenance comes from the header, not the payload;
    // no need to decode whole fixtures.
    return try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 1)
      .codecPriming
  }

  /// DD #7 mFormatID outcomes on real fixtures, including the mis-tagging
  /// cases the reshape exists to fix (ALAC-in-.m4a) and the unmapped
  /// fallback (µ-law-in-.caf → `.unknown`). Trim state follows the DD #7a
  /// rule in every row: `.knownNone` iff LPCM.
  @Test func codecTaggingFromEncodedFormat() throws {
    #expect(
      try tag("test-bwf", "wav")
        == .init(codec: .linearPCM, trimState: .knownNone))
    #expect(
      try tag("test-bwf", "caf")
        == .init(codec: .linearPCM, trimState: .knownNone))
    #expect(
      try tag("sample-with-cover", "aiff")
        == .init(codec: .linearPCM, trimState: .knownNone))
    #expect(
      try tag("sample-with-cover", "m4a")
        == .init(codec: .aac, trimState: .unknown))
    #expect(
      try tag("sample-with-cover", "mp3")
        == .init(codec: .mp3, trimState: .unknown))
    #expect(
      try tag("sample-with-cover", "flac")
        == .init(codec: .flac, trimState: .unknown))
    // ALAC payload in the same .m4a container that carries AAC above —
    // extension-derived tagging cannot distinguish these; mFormatID does.
    #expect(
      try tag("test-alac", "m4a")
        == .init(codec: .alac, trimState: .unknown))
    // µ-law payload in the same .caf container that carries LPCM above —
    // unmapped formats surface as .unknown, never a guess.
    #expect(
      try tag("test-ulaw", "caf")
        == .init(codec: .unknown, trimState: .unknown))
  }

  /// The producer's samples are the same bytes `readMonoSamples` produces —
  /// single shared decode core, locked on an LPCM fixture (DD #3a set).
  @Test func producerSamplesMatchReadMonoSamples() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let (samples, rate) = try PCMBufferReader.readMonoSamples(from: url)
    #expect(decoded.sampleRate == rate)
    try #require(decoded.samples.count == samples.count)
    for (a, b) in zip(decoded.samples, samples) where a.bitPattern != b.bitPattern {
      Issue.record("producer/readMonoSamples sample divergence")
      break
    }
  }

  /// DD #3b negative paths at the producer: NaN/±Inf/0/−5/1e15 sanitize to
  /// nil (full file) — the new public producer must not inherit the
  /// `Int64(Double)` trap at `PCMBufferReader.swift` cap arithmetic.
  @Test(arguments: [
    Double.nan, .infinity, -.infinity, 0.0, -5.0, 1.0e15,
  ])
  func producerSanitizesMaxSeconds(_ bad: Double) throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let full = try PCMBufferReader.readDecodedAudio(from: url)
    let sanitized = try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: bad)
    #expect(sanitized.samples.count == full.samples.count)
  }

  /// Public `readMonoSamples` (the un-sanitized entry) reads the FULL file
  /// for non-finite `maxSeconds` instead of trapping — behavior lock for
  /// the Codex-review product guard (thread 019eb486 round 2).
  @Test func readMonoSamplesNonFiniteCapReadsFullFile() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let (full, _) = try PCMBufferReader.readMonoSamples(from: url)
    let (nanCap, _) = try PCMBufferReader.readMonoSamples(from: url, maxSeconds: .nan)
    let (infCap, _) = try PCMBufferReader.readMonoSamples(
      from: url, maxSeconds: .infinity)
    #expect(nanCap.count == full.count)
    #expect(infCap.count == full.count)
  }

  /// Valid cap: maxSeconds = 1 on a 44.1 kHz fixture reads exactly 44100
  /// frames (the reader's `min(cap, total)` arithmetic).
  @Test func producerAppliesValidCap() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let capped = try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 1)
    #expect(capped.samples.count == 44_100)
    #expect(capped.sampleRate == 44_100)
  }

  /// `cappedSampleCount` mirrors the reader cap bit-for-bit, including the
  /// non-integral `sampleRate * maxSeconds` boundary (PSI #4: 8-1's review
  /// converged on a boundary-semantics bug — test the boundary, not the
  /// happy path). 44100 * 0.7 = 30869.999... → Int64 truncates to 30869,
  /// NOT 30870.
  @Test func cappedSampleCountMirrorsReaderBoundary() throws {
    // Truncation, not rounding (Int64(Double) truncates toward zero).
    #expect(
      PCMBufferReader.cappedSampleCount(
        sampleRate: 44_100, maxSeconds: 0.7, totalSamples: 1_000_000) == 30_869)
    // Cap above total is a no-op.
    #expect(
      PCMBufferReader.cappedSampleCount(
        sampleRate: 44_100, maxSeconds: 100, totalSamples: 44_100) == 44_100)
    // Invalid values sanitize to no-cap.
    for bad in [Double.nan, .infinity, -.infinity, 0.0, -5.0, 1.0e15] {
      #expect(
        PCMBufferReader.cappedSampleCount(
          sampleRate: 44_100, maxSeconds: bad, totalSamples: 123) == 123)
    }
    // Codex review (thread 019eb486) MAJOR: a huge-but-finite sampleRate
    // (DecodedAudio.init admits any finite rate >= 8 kHz) makes the
    // rate × seconds product overflow Int64 — must no-op, never trap.
    #expect(
      PCMBufferReader.cappedSampleCount(
        sampleRate: 1.0e300, maxSeconds: 120, totalSamples: 123) == 123)
    #expect(
      PCMBufferReader.cappedSampleCount(
        sampleRate: 1.0e17, maxSeconds: 120, totalSamples: 123) == 123)
    // The reader agrees with the mirror on a real file: maxSeconds 0.7 at
    // 44.1 kHz reads 30869 frames.
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url, maxSeconds: 0.7)
    #expect(decoded.samples.count == 30_869)
  }
}

// MARK: - AC1: decode happens exactly once, structurally (DD #9)

@Suite("Shared Decode — decode-count structural gate (AC1)")
struct DecodeCountTests {

  /// AC1a: the BPM url path decodes exactly once per analysis.
  @Test func bpmURLPathDecodesOnce() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let probe = DecodeProbe()
    let result = try AudioAnalysisService.analyzeBPM(
      url: url, options: .init(), decodeObserver: { probe.record($0) })
    #expect(result != nil)
    #expect(probe.count == 1)
  }

  /// AC1b: the LUFS url path decodes exactly once per analysis.
  @Test func lufsURLPathDecodesOnce() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let probe = DecodeProbe()
    let report = try AudioAnalysisService.analyzeLUFS(
      url: url, options: LUFSOptions(), decodeObserver: { probe.record($0) })
    #expect(report != nil)
    #expect(probe.count == 1)
  }

  /// AC1c: the shared pattern — one `readDecodedAudio` + both decoded
  /// overloads — cannot fire the service decode observer: the decoded
  /// overloads have no URL parameter, so they cannot decode BY CONSTRUCTION
  /// (the type system is the proof; there is no observer seam to count).
  /// This test locks the pattern end-to-end: one explicit decode, both
  /// analyses produce results.
  @Test func sharedPatternDecodesOnceByConstruction() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let bpm = try AudioAnalysisService.analyzeBPM(decoded: decoded)
    let loudness = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
    #expect(bpm != nil)
    #expect(loudness != nil)
  }

  /// The observer payload is the produced `DecodedAudio` — `maxSeconds`
  /// threads through the funnel to the actual decode (slice check).
  @Test func observerPayloadReflectsCap() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let probe = DecodeProbe()
    var options = LUFSOptions()
    options.maxSeconds = 1
    _ = try AudioAnalysisService.analyzeLUFS(
      url: url, options: options, decodeObserver: { probe.record($0) })
    #expect(probe.count == 1)
    #expect(probe.lastSampleCount == 44_100)
  }
}

// MARK: - AC2: BPM decoded-path equality (DD #2 / DD #3a / DD #3b)

@Suite("Shared Decode — BPM decoded-path equality (AC2)")
struct BPMDecodedEqualityTests {

  /// DD #2 pinned options: every URL-bound signal off, ML off — the decoded
  /// path must reproduce the url path exactly on the DD #3a fixture set.
  private func pinnedOptions() -> AudioAnalysisService.Options {
    var opts = AudioAnalysisService.Options()
    opts.metadataPolicy = .disabled
    opts.durationHint = false
    opts.ensemblePolicy = .dspOnly
    opts.enableMLDiagnostics = false
    return opts
  }

  private func expectResultsBitEqual(
    _ a: AudioAnalysisResult?, _ b: AudioAnalysisResult?,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    guard let a, let b else {
      #expect(
        a == nil && b == nil, "one path nil, the other not",
        sourceLocation: sourceLocation)
      return
    }
    #expect(a.bpm.bitPattern == b.bpm.bitPattern, sourceLocation: sourceLocation)
    #expect(
      a.confidence.bitPattern == b.confidence.bitPattern,
      sourceLocation: sourceLocation)
    try #require(
      a.candidates.count == b.candidates.count, sourceLocation: sourceLocation)
    for (x, y) in zip(a.candidates, b.candidates) {
      #expect(x.bpm.bitPattern == y.bpm.bitPattern, sourceLocation: sourceLocation)
      #expect(x.score.bitPattern == y.score.bitPattern, sourceLocation: sourceLocation)
    }
  }

  /// Result-level bitPattern equality, url path vs decoded path, on the
  /// DD #3a regression-lock set: LPCM payloads (wav, caf, aiff) + FLAC
  /// (bit-exact by format spec). "Verified by regression tests on LPCM/FLAC
  /// fixtures", never "guaranteed by the platform".
  @Test(arguments: [
    ("bpm-120-click", "wav"),
    ("test-bwf", "caf"),
    ("sample-with-cover", "aiff"),
    ("test-audio", "flac"),
  ])
  func decodedPathEqualsURLPath(_ fixture: (String, String)) throws {
    let url = try AudioFixtures.url(for: fixture.0, extension: fixture.1)
    let options = pinnedOptions()
    let viaURL = try AudioAnalysisService.analyzeBPM(url: url, options: options)
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let viaDecoded = try AudioAnalysisService.analyzeBPM(
      decoded: decoded, options: options)
    try expectResultsBitEqual(viaURL, viaDecoded)
  }

  /// DD #3b slice-edge: a non-integral `sampleRate * maxSeconds` boundary
  /// (7.3 × 44100 = 321929.99... → truncates to 321929) must produce the
  /// SAME frames whether the cap is applied at decode time (url path) or as
  /// a prefix slice on a full decode (decoded path). The locked path has no
  /// sample-rate conversion (the no-SRC carve-out — SRC is stateful and
  /// capped-vs-full reads may legitimately differ at the cap boundary).
  @Test func sliceCapBoundaryEquality() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = pinnedOptions()
    options.maxSeconds = 7.3
    let viaURL = try AudioAnalysisService.analyzeBPM(url: url, options: options)
    let decodedFull = try PCMBufferReader.readDecodedAudio(from: url)
    let viaDecoded = try AudioAnalysisService.analyzeBPM(
      decoded: decodedFull, options: options)
    try expectResultsBitEqual(viaURL, viaDecoded)
  }

  /// `maxSeconds` greater than the file length is a no-op on both paths.
  @Test func capBeyondLengthIsNoOp() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var capped = pinnedOptions()
    capped.maxSeconds = 9_999
    let viaCapped = try AudioAnalysisService.analyzeBPM(url: url, options: capped)
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let viaDecoded = try AudioAnalysisService.analyzeBPM(
      decoded: decoded, options: capped)
    try expectResultsBitEqual(viaCapped, viaDecoded)
  }

  /// DD #2 trace comparison — FIELD-WHITELIST only, never whole-trace `==`.
  /// Whitelisted: decode-invariant DSP fields. Excluded BY DESIGN:
  /// `durationHintDetail` (written below the 180s gate when the url path has
  /// a fileDuration — `BPMAnalyzer.resolveOctaveAmbiguity`'s step-9.7 write;
  /// the decoded path never has one) and the ML-trace internals
  /// (`mlFeatures` / `mlDiagnosticSnapshot` — constructed inside
  /// `AudioAnalysisService.evaluateMLIfActive` even when `enableTrace` is
  /// false on ML-active configs).
  @Test func traceFieldAllowlistEquality() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = pinnedOptions()
    options.enableTrace = true
    let viaURL = try #require(
      try AudioAnalysisService.analyzeBPM(url: url, options: options))
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let viaDecoded = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: decoded, options: options))
    let urlTrace = try #require(viaURL.trace)
    let decodedTrace = try #require(viaDecoded.trace)

    #expect(urlTrace.energyTransitionOffset == decodedTrace.energyTransitionOffset)
    #expect(urlTrace.onsetEnvelopeLength == decodedTrace.onsetEnvelopeLength)
    #expect(
      urlTrace.analysisWindowDuration.bitPattern
        == decodedTrace.analysisWindowDuration.bitPattern)
    #expect(urlTrace.intensityUsed == decodedTrace.intensityUsed)
    try #require(urlTrace.rawCandidates.count == decodedTrace.rawCandidates.count)
    for (x, y) in zip(urlTrace.rawCandidates, decodedTrace.rawCandidates) {
      #expect(x.bpm.bitPattern == y.bpm.bitPattern)
      #expect(x.score.bitPattern == y.score.bitPattern)
    }
  }

  /// DD #2 divergence-by-design lock: under the DEFAULT `metadataPolicy`,
  /// the url path corroborates a tagged file (`metadataEvidence` non-empty)
  /// and the decoded path CANNOT (no URL → `FileMetadataReader` never runs —
  /// `metadataEvidence` empty). Both asserted explicitly so nobody "fixes"
  /// the divergence later.
  @Test func metadataDivergenceByDesign() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }

    let viaURL = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    #expect(!viaURL.metadataEvidence.isEmpty)

    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let viaDecoded = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: decoded))
    #expect(viaDecoded.metadataEvidence.isEmpty)
  }
}

// MARK: - AC3: LUFS decoded-path equality + sanitize negatives (DD #3b / DD #5)

@Suite("Shared Decode — LUFS decoded-path equality (AC3)")
struct LUFSDecodedEqualityTests {

  /// `LUFSReport` is `Equatable` — url path vs decoded path on the DD #3a
  /// set at matched `maxSeconds` (nil = full file, and 30).
  @Test(arguments: [
    ("test-bwf", "wav"),
    ("test-bwf", "caf"),
    ("sample-with-cover", "flac"),
  ])
  func decodedPathEqualsURLPath(_ fixture: (String, String)) throws {
    let url = try AudioFixtures.url(for: fixture.0, extension: fixture.1)
    for maxSeconds in [Double?.none, 30.0] {
      var options = LUFSOptions()
      options.maxSeconds = maxSeconds
      let viaURL = try AudioAnalysisService.analyzeLUFS(url: url, options: options)
      let decoded = try PCMBufferReader.readDecodedAudio(from: url)
      let viaDecoded = try AudioAnalysisService.analyzeLUFS(
        decoded: decoded, options: options)
      #expect(viaURL == viaDecoded, "maxSeconds=\(String(describing: maxSeconds))")
      #expect(viaURL != nil)
    }
  }

  /// DD #3b negative paths at the SERVICE entries (the producer's own
  /// negative paths are covered in `ReadDecodedAudioProducerTests`):
  /// NaN/±Inf/0/−5/1e15 sanitize to full-file on both the url and decoded
  /// LUFS paths.
  @Test(arguments: [Double.nan, .infinity, -.infinity, 0.0, -5.0, 1.0e15])
  func serviceSanitizesMaxSeconds(_ bad: Double) throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let fullURL = try AudioAnalysisService.analyzeLUFS(url: url)
    var options = LUFSOptions()
    options.maxSeconds = bad
    let badURL = try AudioAnalysisService.analyzeLUFS(url: url, options: options)
    #expect(badURL == fullURL)

    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let fullDecoded = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
    let badDecoded = try AudioAnalysisService.analyzeLUFS(
      decoded: decoded, options: options)
    #expect(badDecoded == fullDecoded)
  }

  /// DD #5 service-level throw: the decoded overload throws
  /// `unsupportedSampleRate` for a rate with no K-weighting coefficients
  /// (the analyzer-level nil for the same carrier is locked in
  /// `DecodedAudioCurrencyTests`).
  @Test func decodedOverloadThrowsOnUnsupportedRate() {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(
      [Float](repeating: 0.25, count: 8_000), sampleRate: 8_000)
    #expect(throws: LUFSAnalysisError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded)
    }
  }
}

// MARK: - AC5: cancellation contract (DD #8)

@Suite("Shared Decode — LUFS cancellation (AC5)")
struct LUFSCancellationTests {

  /// Url path, pre-decode cancel: `CancellationError` with decode count 0.
  @Test func urlPathPreDecodeCancel() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let probe = DecodeProbe()
    var options = LUFSOptions()
    options.isCancelled = { true }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(
        url: url, options: options, decodeObserver: { probe.record($0) })
    }
    #expect(probe.count == 0)
  }

  /// Url path, post-decode / pre-measure cancel: the script returns false
  /// for the single pre-decode check, then true — throws after exactly one
  /// decode.
  @Test func urlPathPostDecodeCancel() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let probe = DecodeProbe()
    let script = CancellationScript(falseCount: 1)
    var options = LUFSOptions()
    options.isCancelled = { script.isCancelled() }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(
        url: url, options: options, decodeObserver: { probe.record($0) })
    }
    #expect(probe.count == 1)
  }

  /// Decoded path, pre-measure cancel.
  @Test func decodedPathPreMeasureCancel() {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(
      [Float](repeating: 0.25, count: 48_000), sampleRate: 48_000)
    var options = LUFSOptions()
    options.isCancelled = { true }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeLUFS(decoded: decoded, options: options)
    }
  }

  /// Non-cancelled path unaffected: an injected always-false closure
  /// produces the same report as the default options.
  @Test func nonCancelledPathUnaffected() throws {
    let url = try AudioFixtures.url(for: "test-bwf", extension: "wav")
    let baseline = try AudioAnalysisService.analyzeLUFS(url: url)
    var options = LUFSOptions()
    options.isCancelled = { false }
    let injected = try AudioAnalysisService.analyzeLUFS(url: url, options: options)
    #expect(injected == baseline)
    #expect(injected != nil)
  }
}

@Suite("Shared Decode — BPM decoded-path ordering (AC5)")
struct BPMDecodedOrderingTests {

  private final class ProgressLog: Sendable {
    private let updates = Mutex<[ProgressUpdate]>([])
    func record(_ update: ProgressUpdate) { updates.withLock { $0.append(update) } }
    var values: [ProgressUpdate] { updates.withLock { $0 } }
  }

  /// Decoded path: first `ProgressUpdate` fires before window 0 with
  /// `(windowsCompleted: 0, windowsTotal: N)` — same semantics as the url
  /// path.
  @Test func firstProgressBeforeWindowZero() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let log = ProgressLog()
    var options = AudioAnalysisService.Options()
    options.onProgress = { log.record($0) }
    _ = try AudioAnalysisService.analyzeBPM(decoded: decoded, options: options)
    let updates = log.values
    try #require(!updates.isEmpty)
    #expect(updates[0].windowsCompleted == 0)
    #expect(updates[0].windowsTotal >= 1)
    for (i, update) in updates.enumerated() {
      #expect(update.windowsCompleted == i)
      #expect(update.windowsTotal == updates[0].windowsTotal)
    }
  }

  /// Decoded path: cancellation is checked BEFORE each window — an
  /// already-cancelled call throws before any progress fires.
  @Test func cancellationBeforeFirstProgress() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let log = ProgressLog()
    var options = AudioAnalysisService.Options()
    options.isCancelled = { true }
    options.onProgress = { log.record($0) }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(decoded: decoded, options: options)
    }
    #expect(log.values.isEmpty)
  }

  /// Decoded path, MID-FLIGHT (review 2026-06-11): window 0 completes, then
  /// the per-window check cancels before window 1. The script's false budget
  /// covers exactly the decoded overload's early check + the window-0 check,
  /// so this locks the AC5 "before EACH window" claim beyond window 0 — the
  /// always-true and pre-window-0 variants above can both be satisfied by a
  /// single check site.
  @Test func cancellationMidFlightAfterWindowZero() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let log = ProgressLog()
    let script = CancellationScript(falseCount: 2)
    var options = AudioAnalysisService.Options()
    options.isCancelled = { script.isCancelled() }
    options.onProgress = { log.record($0) }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(decoded: decoded, options: options)
    }
    let updates = log.values
    // Default intensity is progressive (3 windows): exactly one progress
    // update fired (window 0 began and completed), none for window 1+.
    try #require(updates.count == 1)
    #expect(updates[0].windowsCompleted == 0)
    #expect(updates[0].windowsTotal > 1)
  }
}

// MARK: - AC6 (type-level): AudioCodec / PrimingInfo reshape invariants

@Suite("Shared Decode — AudioCodec/PrimingInfo reshape (AC6)")
struct CodecProvenanceTypeTests {

  /// SET-equality, not count (count passes when a case is swapped) — DD #7.
  @Test func audioCodecCaseSetLocked() {
    #expect(
      Set(FeatureSubstrate.AudioCodec.allCases) == [
        .linearPCM, .aac, .alac, .mp3, .flac, .unknown,
      ])
  }

  /// Codable round-trip for the reshaped PrimingInfo (AC6).
  @Test func primingInfoCodableRoundTrip() throws {
    let values: [FeatureSubstrate.PrimingInfo] = [
      .init(codec: .linearPCM, trimState: .knownNone),
      .init(codec: .aac, trimState: .unknown),
      .init(codec: .flac, trimState: .unknown),
      .init(codec: .unknown, trimState: .unknown),
    ]
    for value in values {
      let data = try JSONEncoder().encode(value)
      let decoded = try JSONDecoder().decode(
        FeatureSubstrate.PrimingInfo.self, from: data)
      #expect(decoded == value)
    }
  }
}
