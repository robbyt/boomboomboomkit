//
//  MetadataCorroborationTests.swift
//  BoomBoomBoomKitTests
//
//  Story 3.6 corroboration logic — unit tests on MetadataCorroborator.apply
//  plus integration tests on AudioAnalysisService.analyzeBPM with a synthetic
//  AIFF that embeds both PCM and an ID3v2 TBPM tag.
//

import AVFoundation
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - AIFF + ID3 Builder
// ClickTrackAIFFBuilder was promoted to BoomBoomBoomKitTestSupport in
// Story 8-2 (shared with SharedDecodeTests' divergence-by-design lock).

// MARK: - Helpers for unit tests

/// Builds a `BPMResult` for direct corroborator unit-testing.
private func makeResult(
  bpm: Double, confidence: Double,
  candidates: [(bpm: Double, score: Float)]
) -> BPMResult {
  BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: nil)
}

/// Builds a `MetadataBPMEvidence` entry matching what
/// `AudioAnalysisService.buildMetadataInput` would produce after parsing.
private func makeEvidence(
  source: MetadataSource, parsedBPM: Double, raw: String? = nil,
  rejection: String? = nil
) -> MetadataBPMEvidence {
  MetadataBPMEvidence(
    source: source, rawValue: raw ?? String(parsedBPM),
    parsedBPM: parsedBPM, rejectionReason: rejection)
}

// MARK: - MetadataCorroborator unit tests (no file I/O)

@Suite("MetadataCorroborator — unit tests")
struct MetadataCorroboratorUnitTests {

  @Test("empty participating tags pass through unchanged")
  func emptyPassThrough() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence.isEmpty)
  }

  @Test("single same-tempo tag boosts confidence and corroborates winner")
  func sameTempoCorroboration() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    // 0.6 * 1.25 = 0.75 (under the 0.95 clamp).
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(evidence.count == 1)
    #expect(evidence[0].corroboratedWith == 128.0)
    #expect(evidence[0].ratioMatched == nil)
    #expect(evidence[0].rejectionReason == nil)
    #expect(abs(evidence[0].boostApplied - 1.25) < 1e-9)
  }

  @Test("octave corroboration via .half ratio")
  func octaveCorroboration() {
    // DSP says 128 BPM, tag says 64 BPM — octave match (ratio 2.0).
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 64.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(evidence[0].ratioMatched == .double)  // candidate (128) is 2× tag (64)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("winner promotion: lower-ranked candidate gets boosted above DSP top")
  func winnerPromotion() {
    // DSP top candidate is 140 (score 0.5). Lower-ranked 128 (score 0.5).
    // After 1.25× boost on 128: 0.625 > 0.5 → 128 wins.
    let result = makeResult(
      bpm: 140.0, confidence: 0.5,
      candidates: [(140.0, 0.5), (128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .id3TBPM, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("intra-file conflict marks every valid tag")
  func intraFileConflict() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 140.0),
      ],
      conflictDetected: true, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence.count == 2)
    for e in evidence {
      #expect(e.rejectionReason == "intra-file-conflict")
      #expect(e.corroboratedWith == nil)
      #expect(abs(e.boostApplied - 1.0) < 1e-9)
    }
  }

  @Test("three-tag partial agreement: all-or-nothing rule rejects all three")
  func threeTagPartialAgreement() {
    // Two tags agree at 128, one at 174. AC #10: ALL THREE rejected.
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
        makeEvidence(source: .vorbisBPM, parsedBPM: 174.0),
      ],
      conflictDetected: true, policy: .default)
    let (_, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(evidence.count == 3)
    for e in evidence {
      #expect(e.rejectionReason == "intra-file-conflict")
      #expect(abs(e.boostApplied - 1.0) < 1e-9)
    }
  }

  @Test("unanimous consensus across two distinct sources corroborates winner")
  func unanimousConsensus() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    for e in evidence {
      #expect(e.corroboratedWith == 128.0)
      #expect(e.rejectionReason == nil)
    }
  }

  @Test("unanimous consensus disagrees with DSP applies skepticism penalty")
  func unanimousDisagreesPenalty() {
    // Both tags agree on 128, DSP detects 140 with no ratio match.
    let result = makeResult(
      bpm: 140.0, confidence: 0.7, candidates: [(140.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 140.0)
    // 0.7 * 0.85 = 0.595
    #expect(abs(out.confidence - 0.595) < 1e-9)
    for e in evidence {
      #expect(e.rejectionReason == "dsp-disagreement")
      #expect(abs(e.boostApplied - 0.85) < 1e-9)
    }
  }

  @Test("single uncorroborated tag is ignored — confidence unchanged")
  func singleUncorroboratedIgnored() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 200.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(evidence[0].rejectionReason == "uncorroborated-single-tag")
    #expect(abs(evidence[0].boostApplied - 1.0) < 1e-9)
  }

  @Test("zero or non-finite prevConfidence triggers divide-by-zero guard")
  func divideByZeroGuard() {
    // confidence=0 → boostApplied must be 1.0 and confidence stays 0.
    let zeroResult = makeResult(
      bpm: 128.0, confidence: 0.0, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: zeroResult, input: input)
    #expect(out.confidence == 0.0)
    #expect(abs(evidence[0].boostApplied - 1.0) < 1e-9)

    // NaN confidence → stays unchanged, boostApplied = 1.0
    let nanResult = makeResult(
      bpm: 128.0, confidence: .nan, candidates: [(128.0, 0.5)])
    let (nanOut, nanEv) = MetadataCorroborator.apply(to: nanResult, input: input)
    #expect(nanOut.confidence.isNaN)
    #expect(abs(nanEv[0].boostApplied - 1.0) < 1e-9)
  }

  @Test("confidence is clamped to maxBoostedConfidence (0.95)")
  func confidenceClamp() {
    // Pre-boost 0.8; 0.8 * 1.25 = 1.0 → clamped to 0.95.
    let result = makeResult(
      bpm: 128.0, confidence: 0.8, candidates: [(128.0, 0.8)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(abs(out.confidence - 0.95) < 1e-9)
    // boostApplied = 0.95 / 0.8 ≈ 1.1875
    #expect(abs(evidence[0].boostApplied - (0.95 / 0.8)) < 1e-9)
  }

  @Test("triplet ratio gate is off by default — 3:2 tag does not corroborate")
  func tripletGateOff() {
    // Tag 192 vs candidate 128: ratio = 1.5. With allowTripletCorroboration=false (default), no match.
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.confidence == 0.6)
    #expect(evidence[0].rejectionReason == "uncorroborated-single-tag")
  }

  @Test("triplet ratio gate on — 3:2 tag corroborates with .threeHalf")
  func tripletGateOn() {
    var policy = MetadataPolicy.default
    policy.allowTripletCorroboration = true
    // Tag 192 (faster), candidate 128 (slower). Ratio 192/128 = 1.5.
    let result = makeResult(
      bpm: 128.0, confidence: 0.5, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: policy)
    let (_, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(evidence[0].ratioMatched == .threeHalf)
    #expect(evidence[0].corroboratedWith == 128.0)
  }

  @Test("parse-phase rejection passes through unchanged")
  func parseRejectionPassthrough() {
    let result = makeResult(
      bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: .nan, raw: "0", rejection: "sentinel-zero")
      ],
      conflictDetected: false, policy: .default)
    let (out, evidence) = MetadataCorroborator.apply(to: result, input: input)
    #expect(out.confidence == 0.6)
    #expect(evidence[0].rejectionReason == "sentinel-zero")
    #expect(evidence[0].parsedBPM.isNaN)
  }
}

// MARK: - Service-level integration tests

@Suite("MetadataCorroboration — Service-level integration")
struct MetadataCorroborationServiceTests {

  @Test("default policy populates evidence on AIFF with TBPM tag")
  func defaultPopulatesEvidence() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    #expect(!result.metadataEvidence.isEmpty)
    #expect(result.metadataEvidence.first?.source == .id3TBPM)
    #expect(result.metadataEvidence.first?.parsedBPM == 128.0)
  }

  /// Story 6.5b: the disabled-policy service path produces empty evidence — the
  /// semantic-level replacement for the retired `.stage1Floor/.stage2Floor`
  /// byte-identity tests (the byte floor was retired; output-equivalence is now
  /// guarded at the value level + the corpus accuracy floors). Closes the
  /// service-level coverage the deleted tagged tests left (code-review LOW).
  @Test("disabled policy produces empty metadata evidence on a tagged AIFF")
  func disabledPolicyEmptyEvidenceService() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var opts = AudioAnalysisService.Options()
    opts.metadataPolicy = .disabled
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url, options: opts))
    #expect(result.metadataEvidence.isEmpty)
  }

  @Test("fastest intensity still reads metadata")
  func fastestIntensityReadsMetadata() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128")
    defer { try? FileManager.default.removeItem(at: url) }
    var opts = AudioAnalysisService.Options()
    opts.intensity = .fastest
    let result = try #require(
      try AudioAnalysisService.analyzeBPM(
        url: url, options: opts))
    #expect(!result.metadataEvidence.isEmpty)
  }

  @Test("intra-file conflict marks both tags rejected (AIFF with two TBPM frames)")
  func intraFileConflictIntegration() throws {
    let url = try ClickTrackAIFFBuilder.write(
      clickBPM: 128, durationSeconds: 10, tbpm: "128", tbpmFrames: ["128", "130"])
    defer { try? FileManager.default.removeItem(at: url) }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let conflictEvidence = result.metadataEvidence.filter { $0.source == .id3TBPM }
    #expect(conflictEvidence.count == 2)
    #expect(conflictEvidence.map(\.parsedBPM).sorted() == [128.0, 130.0])
    for evidence in conflictEvidence {
      #expect(evidence.rejectionReason == "intra-file-conflict")
      #expect(evidence.corroboratedWith == nil)
      #expect(evidence.boostApplied == 1.0)
    }
  }

}

// MARK: - OA300 reference test (env-gated)

@Suite(
  "MetadataCorroboration — OA300 TVR Reference",
  .enabled(if: ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"] != nil)
)
struct MetadataCorroborationOA300Tests {

  @Test("AC #20: TVR.m4a fixture has tmpo atom and produces evidence")
  func tvrHasTmpoAtom() throws {
    guard let path = ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"], !path.isEmpty
    else { return }
    let url = URL(fileURLWithPath: path)
      .appendingPathComponent("Bad BPM")
      .appendingPathComponent("03 TVR.m4a")
    guard FileManager.default.fileExists(atPath: url.path) else {
      Issue.record("OA300 TVR fixture not found at \(url.path) — skipping reference test")
      return
    }
    let result = try #require(try AudioAnalysisService.analyzeBPM(url: url))
    let tmpo = result.metadataEvidence.first(where: { $0.source == .iTunesTmpo })
    #expect(tmpo != nil, "Expected tmpo evidence on 03 TVR.m4a")
    if let tmpo {
      #expect(tmpo.parsedBPM == 129.0)
      #expect(tmpo.corroboratedWith == 130.0)
      #expect(tmpo.ratioMatched == nil)
      #expect(tmpo.rejectionReason == nil)
      #expect(tmpo.boostApplied > 1.0)
    }
  }
}

// MARK: - Architecture invariants (AC #17)

@Suite("Architecture Invariants — Story 3.6 regression guards")
struct ArchitectureInvariantsTests {

  @Test(
    "DSPTechnique.allCases.count == 8 (no metadata case added; Story 4-7 added .superFluxOnset)")
  func dspTechniqueCount() {
    #expect(DSPTechnique.allCases.count == 8)
  }

  @Test("TechniqueSet.allDSPCombinations().count == 256 (2^8; Story 4-7 grew from 2^7)")
  func techniqueCombinationsCount() {
    #expect(TechniqueSet.allDSPCombinations().count == 256)
  }

  @Test("MetadataSource has exactly three cases")
  func metadataSourceCases() {
    #expect(MetadataSource.allCases.count == 3)
    #expect(Set(MetadataSource.allCases) == Set([.iTunesTmpo, .id3TBPM, .vorbisBPM]))
  }

  /// Story 6.5a: the `EnsemblePolicy` facade has exactly five cases. The type
  /// dropped `String, CaseIterable` when it gained the associated-value
  /// `.weightedVoting(SignalWeights)` case (which `RawRepresentable`/`CaseIterable`
  /// cannot synthesize), so `allPolicies` is the hand-written stand-in for
  /// `allCases`. Pre-1.0 / no-BC framing allows breaking this invariant in a
  /// follow-up story — but accidental drift fails this test loudly.
  @Test("EnsemblePolicy facade has exactly five cases (Story 6.5a)")
  func ensemblePolicyCases() {
    #expect(EnsemblePolicy.allPolicies.count == 5)
    // Ordered comparison locks the iteration order so benchmark sweeps
    // consuming `EnsemblePolicy.allPolicies` produce stable, reproducible
    // policy-row order across runs.
    #expect(
      EnsemblePolicy.allPolicies
        == [.default, .dspOnly, .mlOnly, .highestConfidence, .weightedVoting(.default)])
  }

  /// Story 4.5 DD #14: `TensorLayout.allCases.count == 2` is unit-test-locked
  /// in the canonical invariant venue (review fix AA2 — the assertion
  /// originally lived in `MLFeatureFramesTests` which is the wrong location
  /// for `.allCases.count == N` invariants per the Story 4-4 close-out PSI).
  @Test("TensorLayout has exactly two cases (Story 4.5 DD #14)")
  func tensorLayoutCases() {
    #expect(TensorLayout.allCases.count == 2)
    #expect(Set(TensorLayout.allCases) == Set([.frameMajorLogMel, .nchw]))
  }

  /// Story 6.5a: `OctaveEquivalencePolicy.allCases.count == 3` is unit-test-locked
  /// in the canonical invariant venue alongside the other case-count invariants.
  @Test("OctaveEquivalencePolicy has exactly three cases (Story 6.5a)")
  func octaveEquivalencePolicyCases() {
    #expect(OctaveEquivalencePolicy.allCases.count == 3)
    #expect(
      Set(OctaveEquivalencePolicy.allCases)
        == Set([.collapseToFundamental, .octaveAwareWithPenalty, .exactMatchOnly]))
  }

  @Test("MetadataPolicy.default enables all sources, valueRange 30-300")
  func defaultPolicyShape() {
    let p = MetadataPolicy.default
    #expect(p.enabledSources == Set(MetadataSource.allCases))
    #expect(p.valueRange == 30.0...300.0)
  }

  @Test("MetadataPolicy.disabled has empty enabledSources")
  func disabledPolicyShape() {
    let p = MetadataPolicy.disabled
    #expect(p.enabledSources.isEmpty)
  }
}
