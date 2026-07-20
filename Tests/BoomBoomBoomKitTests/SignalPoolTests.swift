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

  // MARK: - W56: entry source / embedded WeightedSignal.source agreement

  /// W56 (Blind #19 / Copilot PR #17): `SignalParticipationTraceEntry.init`
  /// `precondition`s that a `.present` / `.demoted` participation's embedded
  /// `WeightedSignal.source` matches the entry's canonical `source`. The trap
  /// case (a `.dsp` entry wrapping a `.ml` signal) aborts the process and is not
  /// `#expect(throws:)`-catchable in Swift Testing (the documented `precondition`
  /// limitation). This positive test pins that matching-source entries — the
  /// shape every production caller emits — construct and preserve their fields,
  /// so a refactor that breaks the agreement is caught here.
  @Test func traceEntrySourceMatchesEmbeddedSignalSource() {
    let dsp = WeightedSignal(bpm: 128.0, confidence: 0.8, source: .dsp, score: 0.8)
    let present = SignalParticipationTraceEntry(
      source: .dsp, participation: .present(dsp), weight: 1.0, contribution: 0.8)
    #expect(present.source == .dsp)
    if case .present(let s) = present.participation {
      #expect(s.source == present.source)
    } else {
      Issue.record("expected .present participation")
    }

    let meta = WeightedSignal(bpm: 174.0, confidence: 1.0, source: .fileMetadata)
    let demoted = SignalParticipationTraceEntry(
      source: .fileMetadata,
      participation: .demoted(meta, reason: .sourceSpecific("intra-file-conflict")),
      weight: 1.0, contribution: 1.0)
    if case .demoted(let s, _) = demoted.participation {
      #expect(s.source == demoted.source)
    } else {
      Issue.record("expected .demoted participation")
    }

    // `.absent` carries no signal — the precondition is a no-op; any source is fine.
    let absent = SignalParticipationTraceEntry(
      source: .ml, participation: .absent, weight: 1.0, contribution: 0.0)
    #expect(absent.source == .ml)
  }

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
    // Story 6.4a: `score: Float?` round-trip. `dspScoredSignal` carries a
    // populated finite score (the DSP carrier shape); `nanScoreSignal` carries a
    // non-finite score so DD #5's Float-NaN claim is test-locked under the same
    // symmetric `nonConformingFloat` strategy that covers `bpm`/`confidence`.
    // The three signals above (nan/inf/clean) keep `score == nil` via the init
    // default — exercising the absent-key (`encodeIfPresent`/`decodeIfPresent`)
    // optional path, NOT the non-conforming-float string path.
    let dspScoredSignal = WeightedSignal(
      bpm: 174.0, confidence: 0.42, source: .dsp, score: 0.42)
    let nanScoreSignal = WeightedSignal(
      bpm: 96.0, confidence: 0.5, source: .dsp, score: .nan)

    let cases: [SignalParticipation] = [
      .absent,
      .abstained(.sourceSpecific("decode-rejected")),
      .demoted(infSignal, reason: .sourceSpecific("ratio-outlier")),
      .demoted(dspScoredSignal, reason: .sourceSpecific("scored-demote")),
      .present(nanSignal),
      .present(cleanSignal),
      .present(dspScoredSignal),
      .present(nanScoreSignal),
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
        Self.expectScoreSurvives(s1.score, s2.score)
        #expect(r1 == r2)
      case (.present(let s1), .present(let s2)):
        #expect(NumericTestHelpers.bitEqual(s1.bpm, s2.bpm))
        #expect(NumericTestHelpers.bitEqual(s1.confidence, s2.confidence))
        #expect(s1.source == s2.source)
        Self.expectScoreSurvives(s1.score, s2.score)
      default:
        Issue.record("Decoded case mismatch: \(participation) vs \(decoded)")
      }
    }
  }

  /// Asserts `WeightedSignal.score` survives encode/decode: a populated score
  /// must round-trip with an identical IEEE-754 bit pattern (NaN-safe), and a
  /// `nil` score (absent key) must stay `nil` (Story 6.4a, AC #3).
  private static func expectScoreSurvives(_ lhs: Float?, _ rhs: Float?) {
    switch (lhs, rhs) {
    case (nil, nil):
      break
    case (.some(let a), .some(let b)):
      #expect(NumericTestHelpers.bitEqual(a, b))
    default:
      Issue.record(
        "score optionality mismatch: \(String(describing: lhs)) vs \(String(describing: rhs))")
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
      #expect(!dspEntries.isEmpty, "intensity=\(intensity.level)")
      for entry in dspEntries {
        switch entry.participation {
        case .absent:
          Issue.record(
            "DSP source recorded .absent for non-nil result at intensity=\(intensity.level)")
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

  // MARK: - Story 6.4a: WeightedSignal.score population matrix

  /// AC #1(a)/(c): the DSP `.present(...)` pool entries carry the EXACT operative
  /// `Float` candidate-fusion score (`signal.score == candidate.score`), while ML
  /// constructs NO `WeightedSignal` (its entry is `.absent` under the default
  /// `mlTechnique == nil`). Verified via a real `enableTrace` run — a populated
  /// DSP pool only exists after `analyzeBPM`. The click fixture carries no
  /// embedded tag, so corroboration is a no-op and ML is absent; thus
  /// `result.candidates` equals the merged candidates that built the DSP pool,
  /// in order. The trace carrier equaling `result.candidates` score proves no
  /// drift; output-equivalence itself is locked by `MergeSemanticEqualityTests`
  /// + the accuracy benchmarks (Story 6.5b retired the byte floor).
  @Test func dspPresentCarriesCandidateScore() throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    var options = AudioAnalysisService.Options()
    options.enableTrace = true
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: options))
    let trace = try #require(result.trace)

    let dspPresentSignals: [WeightedSignal] = trace.signalParticipationTrace
      .filter { $0.source == .dsp }
      .compactMap { entry in
        if case .present(let signal) = entry.participation { return signal }
        return nil
      }
    // One .present DSP entry per merged candidate, in candidate order.
    // Fail-closed (Story 6.4a code review CR1): guard against a vacuous pass if a
    // future fixture ever yields zero candidates — the count check and zip below
    // would otherwise degenerate to 0 == 0 with the load-bearing score-equality
    // loop never running. bpm-120-click reliably produces candidates today, so
    // this never fires in practice; it locks the AC #1(a)/(c) assertions closed.
    #expect(!dspPresentSignals.isEmpty)
    #expect(dspPresentSignals.count == result.candidates.count)
    for (signal, candidate) in zip(dspPresentSignals, result.candidates) {
      #expect(NumericTestHelpers.bitEqual(signal.bpm, candidate.bpm))  // ordering sanity
      let score = try #require(signal.score, "DSP .present must carry a non-nil score")
      #expect(NumericTestHelpers.bitEqual(score, candidate.score))
    }

    // ML: no WeightedSignal is constructed when mlTechnique == nil (entry .absent).
    let mlEntries = trace.signalParticipationTrace.filter { $0.source == .ml }
    #expect(mlEntries.count == 1)
    switch mlEntries.first?.participation {
    case .present, .demoted:
      Issue.record("ML must not construct a WeightedSignal when mlTechnique == nil")
    case .absent, .abstained, nil:
      break
    }
  }

  /// AC #1(b): the file-metadata `.present(...)` pool entry DOES construct a
  /// `WeightedSignal`, and it carries `score == nil` via the init default. The
  /// 6.4b-frozen construction site at `MetadataCorroborator.swift:371` uses the
  /// positional 3-arg `WeightedSignal(bpm:confidence:source:)` form and is NOT
  /// edited by 6.4a. Driven through `signalParticipationEntries` directly so no
  /// audio fixture is required.
  @Test func fileMetadataPresentCarriesNilScore() {
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        MetadataBPMEvidence(source: .id3TBPM, rawValue: "128", parsedBPM: 128.0)
      ],
      conflictDetected: false,
      policy: .default)
    let entries = MetadataCorroborator.signalParticipationEntries(for: input, weight: 1.0)
    let present: [WeightedSignal] = entries.compactMap { entry in
      guard entry.source == .fileMetadata,
        case .present(let signal) = entry.participation
      else { return nil }
      return signal
    }
    #expect(present.count == 1)
    #expect(present.first?.score == nil)
  }
}
