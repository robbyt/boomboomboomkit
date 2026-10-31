//
//  RhythmicRegionIntegrationTests.swift
//  BoomBoomBoomKit
//
//  Default region selection and BPM voting behavior.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Synchronization
import Testing

@testable import BoomBoomBoomKit

@Suite("Rhythmic region consensus")
struct RhythmicRegionIntegrationTests {
  private let rate = 8_000.0

  private struct LegacySnapshot: Equatable {
    let bpmBits: UInt64
    let confidenceBits: UInt64
    let candidateBits: [String]
    let traceFingerprint: UInt64
  }

  private final class ProgressLog: Sendable {
    private let updates = Mutex<[ProgressUpdate]>([])
    func record(_ update: ProgressUpdate) { updates.withLock { $0.append(update) } }
    var values: [ProgressUpdate] { updates.withLock { $0 } }
  }

  private func clicks(bpm: Double, seconds: Int, amplitude: Float = 0.6) -> [Float] {
    var samples = [Float](repeating: 0, count: seconds * 8_000)
    let period = Int(60 / bpm * rate)
    for beat in stride(from: 0, to: samples.count, by: period) {
      for i in beat..<min(beat + 80, samples.count) {
        samples[i] = amplitude * (1 - Float(i - beat) / 80)
      }
    }
    return samples
  }

  private func fourProbes() -> [Float] {
    // Constant absolute energy has no rhythmic onsets despite being loud.
    let unpatterned = (0..<(30 * 8_000)).map { $0.isMultiple(of: 2) ? Float(0.8) : -0.8 }
    return unpatterned + clicks(bpm: 120, seconds: 90, amplitude: 0.02)
  }

  private func options() -> AudioAnalysisService.Options {
    var options = AudioAnalysisService.Options()
    options.intensity = .level7
    options.useRhythmicRegions = true
    options.mergeStrategy = .windowVoting
    options.votingPolicy = .simpleMajority
    options.enableTrace = true
    options.metadataPolicy = .disabled
    options.durationHint = false
    return options
  }

  private func legacyTraceBytes(_ trace: BPMDiagnosticTrace) -> [UInt8] {
    // Capture every legacy field in declaration order. The metadata source Set
    // needs sorting because Swift randomizes its reflection order per process.
    let fields = Mirror(reflecting: trace).children.compactMap { child -> String? in
      guard let label = child.label, label != "rhythmicRegionEvidence" else { return nil }
      if label == "metadataPolicyUsed" {
        let policy = trace.metadataPolicyUsed
        let sources = policy.enabledSources.map { String(reflecting: $0) }.sorted()
        return "\(label)=\(sources),\(policy.consensusTolerance),"
          + "\(policy.corroborationTolerance),\(policy.corroborationBoost),"
          + "\(policy.maxBoostedConfidence),\(policy.skepticismPenalty),"
          + "\(policy.allowOctaveCorroboration),\(policy.allowTripletCorroboration),"
          + "\(policy.valueRange),\(String(reflecting: policy.parsing))\n"
      }
      return "\(label)=\(String(reflecting: child.value))\n"
    }
    return Array(fields.joined().utf8)
  }

  private func byteFingerprint(_ bytes: [UInt8]) -> UInt64 {
    bytes.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
  }

  @Test("unconfigured options select rhythmic regions with simple-majority voting")
  func defaultConfiguration() throws {
    var settings = AudioAnalysisService.Options()
    #expect(settings.useRhythmicRegions)
    #expect(settings.mergeStrategy == .windowVoting)
    #expect(settings.votingPolicy == .simpleMajority)
    settings.enableTrace = true
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(
          clicks(bpm: 160, seconds: 30, amplitude: 0.01)
            + clicks(bpm: 120, seconds: 60), sampleRate: rate),
        options: settings))
    let evidence = try #require(result.trace?.rhythmicRegionEvidence)
    #expect(evidence.regions.count == 3)
    #expect(evidence.voteAccepted)
    #expect(abs(result.bpm - 120) <= 2.4)
  }

  @Test("two later regions can outvote a weak intro")
  func laterRegionsWin() throws {
    let intro = clicks(bpm: 160, seconds: 30, amplitude: 0.01)
    let audio = intro + clicks(bpm: 120, seconds: 30) + clicks(bpm: 120, seconds: 30)
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(audio, sampleRate: rate), options: options()))
    let evidence = try #require(result.trace?.rhythmicRegionEvidence)
    #expect(evidence.regions.count == 3)
    #expect(evidence.successfulRegionCount >= 2)
    #expect(evidence.largestAgreementCount >= 2)
    #expect(evidence.windowVotingRan)
    #expect(evidence.voteAccepted)
    #expect(abs(result.bpm - 120) <= 2.4)
    #expect(evidence.preMetadataBPM == result.bpm)
  }

  @Test("service selects three rhythmic probes and excludes the unpatterned probe")
  func serviceUsesRhythmicPlacement() throws {
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(fourProbes(), sampleRate: rate), options: options()))
    let regions = try #require(result.trace?.rhythmicRegionEvidence?.regions)
    #expect(regions.map(\.startSample) == [240_000, 480_000, 720_000])
    #expect(regions.count == 3)
    #expect(regions.allSatisfy { $0.rhythmScore > 0 })
  }

  @Test("opt-in progress follows selected-region order and count")
  func rhythmicProgress() throws {
    let log = ProgressLog()
    var settings = options()
    settings.onProgress = { log.record($0) }
    _ = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(fourProbes(), sampleRate: rate), options: settings))
    #expect(log.values.map(\.windowsCompleted) == [0, 1, 2])
    #expect(log.values.map(\.windowsTotal) == [3, 3, 3])
  }

  @Test("default rhythmic path can cancel between selected regions")
  func rhythmicCancellationMidFlight() throws {
    let log = ProgressLog()
    nonisolated(unsafe) var checks = 0
    var settings = AudioAnalysisService.Options()
    settings.isCancelled = {
      checks += 1
      return checks > 4  // Early, pre-scan, post-scan, and first-region checks pass.
    }
    settings.onProgress = { log.record($0) }
    #expect(throws: CancellationError.self) {
      _ = try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(fourProbes(), sampleRate: rate), options: settings)
    }
    #expect(log.values.map(\.windowsCompleted) == [0])
    #expect(log.values.map(\.windowsTotal) == [3])
  }

  @Test("one short region reports fallback, without consensus")
  func oneRegion() throws {
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(clicks(bpm: 120, seconds: 15), sampleRate: rate),
        options: options()))
    let evidence = try #require(result.trace?.rhythmicRegionEvidence)
    #expect(evidence.regions.count == 1)
    #expect(evidence.successfulRegionCount == 1)
    #expect(evidence.largestAgreementCount == 1)
    #expect(!evidence.windowVotingRan)
    #expect(!evidence.voteAccepted)
  }

  @Test("two conflicting regions use strongest-result fallback")
  func disagreement() throws {
    var settings = options()
    settings.intensity = .level6
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(
          clicks(bpm: 120, seconds: 30) + clicks(bpm: 160, seconds: 30),
          sampleRate: rate), options: settings))
    let evidence = try #require(result.trace?.rhythmicRegionEvidence)
    #expect(evidence.regions.count == 2)
    #expect(evidence.successfulRegionCount == 2)
    #expect(evidence.largestAgreementCount == 1)
    #expect(evidence.windowVotingRan)
    #expect(!evidence.voteAccepted)
    #expect(evidence.regions.contains { $0.bpm == result.bpm })
  }

  @Test("silence yields no invented region BPM")
  func silence() throws {
    let result = try AudioAnalysisService.analyzeBPM(
      decoded: .synthetic([Float](repeating: 0, count: 15 * 8_000), sampleRate: rate),
      options: options())
    #expect(result == nil)
  }

  @Test("threshold rejection is recorded even when two regions agree")
  func thresholdVoteRejected() throws {
    let results = [
      BPMResult(bpm: 120, confidence: 0.6, candidates: [(120, 0.6)], trace: nil),
      BPMResult(bpm: 120.5, confidence: 0.5, candidates: [(120.5, 0.5)], trace: nil),
      BPMResult(bpm: 160, confidence: 0.9, candidates: [(160, 0.9)], trace: nil),
    ]
    let rejected = try #require(
      BPMSelectionPolicy.mergeWithOutcome(
        windowResults: results, candidateCount: 3, strategy: .windowVoting,
        votingPolicy: .thresholdGated, votingThreshold: 0.8))
    #expect(rejected.largestAgreementCount == 2)
    #expect(rejected.windowVotingRan)
    #expect(!rejected.voteAccepted)
    #expect(rejected.result.bpm == 160)

    let accepted = try #require(
      BPMSelectionPolicy.mergeWithOutcome(
        windowResults: results, candidateCount: 3, strategy: .windowVoting,
        votingPolicy: .thresholdGated, votingThreshold: 0.5))
    #expect(accepted.voteAccepted)
    #expect(accepted.result.bpm == 120)
  }

  @Test("confidence-weighted singleton does not claim consensus")
  func weightedSingletonFallback() throws {
    let results = [
      BPMResult(bpm: 120, confidence: 0.25, candidates: [(120, 0.25)], trace: nil),
      BPMResult(bpm: 120.5, confidence: 0.25, candidates: [(120.5, 0.25)], trace: nil),
      BPMResult(bpm: 160, confidence: 0.9, candidates: [(160, 0.9)], trace: nil),
    ]
    let outcome = try #require(
      BPMSelectionPolicy.mergeWithOutcome(
        windowResults: results, candidateCount: 3, strategy: .windowVoting,
        votingPolicy: .confidenceWeighted, votingThreshold: 0))
    #expect(outcome.largestAgreementCount == 2)
    #expect(outcome.windowVotingRan)
    #expect(!outcome.voteAccepted)
    #expect(outcome.result.bpm == 160)
  }

  @Test("explicit opt-out matches the pinned pre-feature result and trace bytes")
  func explicitOptOut() throws {
    let decoded = FeatureSubstrate.DecodedAudio.synthetic(
      clicks(bpm: 120, seconds: 90), sampleRate: rate)
    var defaults = AudioAnalysisService.Options()
    defaults.enableTrace = true
    defaults.useRhythmicRegions = false
    defaults.mergeStrategy = .maxConfidence
    let optedOut = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: decoded, options: defaults))
    let trace = try #require(optedOut.trace)
    let observed = LegacySnapshot(
      bpmBits: optedOut.bpm.bitPattern,
      confidenceBits: optedOut.confidence.bitPattern,
      candidateBits: optedOut.candidates.map { "\($0.bpm.bitPattern):\($0.score.bitPattern)" },
      traceFingerprint: byteFingerprint(legacyTraceBytes(trace)))
    // The first snapshot came from a clean pre-feature archive (71d25eb).
    // CI's Accelerate build emits slightly different float bits from this Mac;
    // its observed signature is kept whole so a mixed or new result still fails.
    let baselineSnapshots = [
      LegacySnapshot(
        bpmBits: 4_638_144_675_660_280_609,
        confidenceBits: 4_606_456_729_077_308_998,
        candidateBits: [
          "4638144666238189568:1065354646",
          "4635329916471083008:990495323",
          "4639024275540410368:986859293",
        ],
        traceFingerprint: 10_676_882_851_403_586_908),
      LegacySnapshot(
        bpmBits: 4_638_144_675_089_244_788,
        confidenceBits: 4_606_456_729_120_563_475,
        candidateBits: [
          "4638144666238189568:1065354621",
          "4635329916471083008:990176138",
          "4639024275540410368:986859292",
        ],
        traceFingerprint: 6_738_896_034_119_159_393),
    ]
    #expect(baselineSnapshots.contains(observed))
    #expect(trace.rhythmicRegionEvidence == nil)
  }

  @Test("metadata-disabled URL and decoded paths use identical capped PCM")
  func urlDecodedParity() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var settings = options()
    settings.maxSeconds = 7.3
    let fromURL = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: settings))
    let decoded = try PCMBufferReader.readDecodedAudio(from: url)
    let fromDecoded = try #require(
      try AudioAnalysisService.analyzeBPM(decoded: decoded, options: settings))
    #expect(fromURL.bpm.bitPattern == fromDecoded.bpm.bitPattern)
    #expect(fromURL.confidence.bitPattern == fromDecoded.confidence.bitPattern)
    let urlRegions = try #require(fromURL.trace?.rhythmicRegionEvidence?.regions)
    let decodedRegions = try #require(fromDecoded.trace?.rhythmicRegionEvidence?.regions)
    #expect(urlRegions.map(\.startSample) == decodedRegions.map(\.startSample))
    #expect(urlRegions.map(\.sampleCount) == decodedRegions.map(\.sampleCount))
    #expect(urlRegions.map(\.bpm) == decodedRegions.map(\.bpm))
  }

  @Test("combined analysis retains region evidence and standalone grid anchor")
  func combinedGrid() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let settings = options()
    let combined = try #require(try AudioAnalysisService.analyze(url: url, options: settings))
    let full = try #require(
      try AudioAnalysisService.analyzeFull(url: url, options: settings).bpmAndBeatGrid)
    let standalone = try #require(
      try AudioAnalysisService.analyzeBeatGrid(url: url, options: settings))
    #expect(combined.bpm.trace?.rhythmicRegionEvidence != nil)
    #expect(full.bpm.trace?.rhythmicRegionEvidence != nil)
    #expect(full.bpm.bpm.bitPattern == combined.bpm.bpm.bitPattern)
    #expect(combined.beatGrid?.analysisSpan?.startSample == standalone.analysisSpan?.startSample)
    #expect(full.beatGrid?.analysisSpan?.startSample == standalone.analysisSpan?.startSample)
    #expect(
      combined.beatGrid?.gridOrigin?.presentationTime == standalone.gridOrigin?.presentationTime)
  }

  @Test("uniform control uses the same three disjoint 30-second windows")
  func uniformControlGeometry() throws {
    let audio = clicks(bpm: 120, seconds: 120)
    var settings = options()
    settings.useUniformRegionControl = true
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        decoded: .synthetic(audio, sampleRate: rate), options: settings))
    let regions = try #require(result.trace?.rhythmicRegionEvidence?.regions)
    #expect(regions.map(\.startSample) == [0, 360_000, 720_000])
    #expect(regions.map(\.sampleCount) == [240_000, 240_000, 240_000])
    #expect(regions.allSatisfy { $0.rhythmScore == 0 })
  }
}
