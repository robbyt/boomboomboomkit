//
//  SignalPoolTests.swift
//  BoomBoomBoomKitTests
//
//  Story 6.1 — Contract tests for SignalParticipation, SignalSource, the
//  Codable round-trip surface, and the per-source population contract that
//  AudioAnalysisService.analyzeBPM emits into BPMDiagnosticTrace.signalParticipationTrace.
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("SignalPoolTests")
struct SignalPoolTests {

  // MARK: - AC #1: shape & exhaustiveness

  /// Exhaustive switch over `SignalParticipation` — compile-time guarantee
  /// that the contract carries exactly 4 cases (DD #2). `Sendable, Codable`
  /// surface is exercised below; `SignalParticipation` does not conform to
  /// `Hashable` (post code-review D1: `Hashable`'s `x == x` invariant fails on
  /// `Double.nan` payloads exercised by `codableRoundTripAllParticipationCases`).
  @Test func fourCases() {
    let cases: [SignalParticipation] = [
      .absent,
      .abstained(.policyDisabled),
      .demoted(
        WeightedSignal(bpm: 120.0, confidence: 0.4, source: .dsp),
        reason: .implausibleForContext),
      .present(WeightedSignal(bpm: 128.0, confidence: 0.8, source: .dsp)),
    ]
    for participation in cases {
      switch participation {
      case .absent:
        #expect(participation.confidence == 0.0)
      case .abstained:
        #expect(participation.confidence == 0.0)
      case .demoted(let signal, _):
        #expect(participation.confidence == signal.confidence)
      case .present(let signal):
        #expect(participation.confidence == signal.confidence)
      }
    }
    #expect(cases.count == 4)
  }

  // MARK: - AC #7: Codable round-trip

  @Test(arguments: SignalSource.allCases)
  func codableRoundTripPerSource(source: SignalSource) throws {
    let data = try JSONEncoder().encode(source)
    let decoded = try JSONDecoder().decode(SignalSource.self, from: data)
    #expect(decoded == source)
  }

  /// Round-trips all 4 `SignalParticipation` cases through JSONEncoder /
  /// JSONDecoder configured with symmetric nonConformingFloat strategies so
  /// `Double.nan` and `Double.infinity` payloads survive (Patch C2). Decoded
  /// values are byte-equal to encoded values via `NumericTestHelpers.bitEqual`.
  @Test func codableRoundTripAllParticipationCases() throws {
    let encoder = JSONEncoder()
    encoder.nonConformingFloatEncodingStrategy = .convertToString(
      positiveInfinity: "Infinity",
      negativeInfinity: "-Infinity",
      nan: "NaN")
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: "Infinity",
      negativeInfinity: "-Infinity",
      nan: "NaN")

    let nanSignal = WeightedSignal(bpm: .nan, confidence: .nan, source: .ml)
    let infSignal = WeightedSignal(bpm: .infinity, confidence: 1.0, source: .fileMetadata)
    let cleanSignal = WeightedSignal(bpm: 128.0, confidence: 0.8, source: .dsp)

    let cases: [SignalParticipation] = [
      .absent,
      .abstained(.sourceSpecific("decode-rejected")),
      .demoted(infSignal, reason: .sourceSpecific("ratio-outlier")),
      .present(nanSignal),
      .present(cleanSignal),
    ]

    for participation in cases {
      let data = try encoder.encode(participation)
      let decoded = try decoder.decode(SignalParticipation.self, from: data)

      switch (participation, decoded) {
      case (.absent, .absent):
        break
      case (.abstained(let r1), .abstained(let r2)):
        #expect(r1 == r2)
      case (.demoted(let s1, let r1), .demoted(let s2, let r2)):
        #expect(NumericTestHelpers.bitEqual(s1.bpm, s2.bpm))
        #expect(NumericTestHelpers.bitEqual(s1.confidence, s2.confidence))
        #expect(s1.source == s2.source)
        #expect(r1 == r2)
      case (.present(let s1), .present(let s2)):
        #expect(NumericTestHelpers.bitEqual(s1.bpm, s2.bpm))
        #expect(NumericTestHelpers.bitEqual(s1.confidence, s2.confidence))
        #expect(s1.source == s2.source)
      default:
        Issue.record("Decoded case mismatch: \(participation) vs \(decoded)")
      }
    }
  }

  // MARK: - AC #6: DSP per-source contract

  /// Runs `AudioAnalysisService.analyzeBPM` against a single bundled fixture
  /// at intensities `.fastest`, `.default`, `.maximum`. The trace's
  /// `signalParticipationTrace` MUST contain at least one `.dsp`-tagged entry
  /// AND no `.dsp` entry may be `.absent` (DSP always ran when a non-nil
  /// result was produced).
  @Test func dspPerSourceContract() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")

    for intensity in [AnalysisIntensity.fastest, .default, .maximum] {
      var options = AudioAnalysisService.Options()
      options.intensity = intensity
      options.enableTrace = true
      let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: options))
      let trace = try #require(result.trace)

      let dspEntries = trace.signalParticipationTrace.filter { $0.source == .dsp }
      #expect(!dspEntries.isEmpty, "intensity=\(intensity.rawValue)")
      for entry in dspEntries {
        switch entry.participation {
        case .absent:
          Issue.record(
            "DSP source recorded .absent for non-nil result at intensity=\(intensity.rawValue)")
        case .abstained, .demoted, .present:
          break
        }
        #expect(NumericTestHelpers.bitEqual(entry.weight, 1.0))
      }
    }
  }

  // MARK: - AC #1: ML and metadata per-source contracts

  /// `Options.mlTechnique == nil` produces a trace entry with
  /// `source: .ml, participation: .absent` (DD #6 ML rule 1).
  @Test func mlAbsentWhenTechniqueNil() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = AudioAnalysisService.Options()
    options.enableTrace = true
    // Default options have mlTechnique == nil.
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: options))
    let trace = try #require(result.trace)

    let mlEntries = trace.signalParticipationTrace.filter { $0.source == .ml }
    #expect(mlEntries.count == 1)
    if let entry = mlEntries.first {
      switch entry.participation {
      case .absent:
        #expect(NumericTestHelpers.bitEqual(entry.contribution, 0.0))
      default:
        Issue.record("Expected .absent for .ml when mlTechnique == nil, got \(entry.participation)")
      }
    }
  }

  /// `Options.metadataPolicy == .disabled` produces a trace entry with
  /// `source: .fileMetadata, participation: .absent` (DD #6 metadata rule 1).
  @Test func metadataAbsentWhenDisabled() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = AudioAnalysisService.Options()
    options.enableTrace = true
    options.metadataPolicy = .disabled
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: options))
    let trace = try #require(result.trace)

    let metaEntries = trace.signalParticipationTrace.filter { $0.source == .fileMetadata }
    #expect(metaEntries.count == 1)
    if let entry = metaEntries.first {
      switch entry.participation {
      case .absent:
        #expect(NumericTestHelpers.bitEqual(entry.contribution, 0.0))
      default:
        Issue.record(
          "Expected .absent for .fileMetadata when policy disabled, got \(entry.participation)")
      }
    }
  }
}
