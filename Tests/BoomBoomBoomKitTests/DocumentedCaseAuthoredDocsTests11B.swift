//
//  DocumentedCaseAuthoredDocsTests11B.swift
//  BoomBoomBoomKitTests
//
//  Story 11.3b: the budget/policy + failure-mode types (AnalysisIntensity,
//  OctaveEquivalencePolicy, MLExecutionPolicy, DownbeatResult, AbstainReason,
//  DemotionReason) ship 25 authored per-case Markdown files, and the five
//  not-yet-conformed enums conform to DocumentedCase. This suite reuses the
//  HARDENED structural validator from the 11.3a suite (same test target, static
//  helpers) so the two stories cannot drift in what "valid" means, and adds the
//  11.3b payload map, the payload-invariant `documentationID` proofs (≥2
//  payloads), and the DD-9 targeted semantic checks (level7 footgun, per-level
//  budget-honesty, sourceSpecific no-phantom-string). Story 11.4 unifies both.
//

// Plain import (NOT @testable): every exercised symbol is public.
import BoomBoomBoomKit
import Foundation
import Testing

@Suite("Story 11.3b authored docs")
struct DocumentedCaseAuthoredDocsTests11B {

  /// Reuse the hardened 11.3a validator statics (internal to this test target).
  typealias Validator = DocumentedCaseAuthoredDocsTests

  // MARK: - Expected rosters

  static let intensityStems = (1...10).map { "level\($0)" }
  static let octaveStems = ["collapseToFundamental", "octaveAwareWithPenalty", "exactMatchOnly"]
  static let mlStems = ["never", "always", "whenDSPConfidenceBelow"]
  static let downbeatStems = ["notAttempted", "noneDetected", "detected"]
  static let abstainStems = [
    "policyDisabled", "inputBelowMinimum", "confidenceBelowFloor", "sourceSpecific",
  ]
  static let demotionStems = ["implausibleForContext", "sourceSpecific"]

  /// Per-type payload map (11.3b). Every listed stem MUST carry `payload:` of the
  /// named type; every other stem MUST NOT carry `payload:`.
  static let payloads: [String: [String: String]] = [
    "MLExecutionPolicy": ["whenDSPConfidenceBelow": "Double"],
    "DownbeatResult": ["detected": "DownbeatEstimate"],
    "AbstainReason": ["sourceSpecific": "String"],
    "DemotionReason": ["sourceSpecific": "String"],
  ]

  // Sample instances for the non-CaseIterable (associated-value) enums.
  static let sampleEstimate = DownbeatEstimate(
    beats: [BeatTimestamp(presentationTime: 0.0, confidence: 1.0, strength: 1.0)],
    meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
    confidence: 0.9, phaseIndex: 0)
  static let mlCases: [MLExecutionPolicy] = [.never, .always, .whenDSPConfidenceBelow(0.85)]
  static let downbeatCases: [DownbeatResult] = [
    .notAttempted, .noneDetected, .detected(estimate: sampleEstimate),
  ]
  static let abstainCases: [AbstainReason] = [
    .policyDisabled, .inputBelowMinimum, .confidenceBelowFloor, .sourceSpecific("x"),
  ]
  static let demotionCases: [DemotionReason] = [.implausibleForContext, .sourceSpecific("x")]

  // MARK: - documentationID stem lists

  @Test("AnalysisIntensity documentationID stems match the authored files")
  func intensityIDs() {
    #expect(AnalysisIntensity.allCases.map(\.documentationID) == Self.intensityStems)
  }

  @Test("OctaveEquivalencePolicy documentationID stems match the authored files")
  func octaveIDs() {
    #expect(OctaveEquivalencePolicy.allCases.map(\.documentationID) == Self.octaveStems)
  }

  @Test("MLExecutionPolicy documentationID stems match the authored files")
  func mlIDs() { #expect(Self.mlCases.map(\.documentationID) == Self.mlStems) }

  @Test("DownbeatResult documentationID stems match the authored files")
  func downbeatIDs() { #expect(Self.downbeatCases.map(\.documentationID) == Self.downbeatStems) }

  @Test("AbstainReason documentationID stems match the authored files")
  func abstainIDs() { #expect(Self.abstainCases.map(\.documentationID) == Self.abstainStems) }

  @Test("DemotionReason documentationID stems match the authored files")
  func demotionIDs() { #expect(Self.demotionCases.map(\.documentationID) == Self.demotionStems) }

  // MARK: - Payload-invariant documentationID (AC 4: ≥2 distinct payloads)

  @Test("Associated-value documentationID ignores the payload value")
  func payloadInvariantIDs() {
    #expect(
      MLExecutionPolicy.whenDSPConfidenceBelow(0.1).documentationID == "whenDSPConfidenceBelow")
    #expect(
      MLExecutionPolicy.whenDSPConfidenceBelow(0.9).documentationID == "whenDSPConfidenceBelow")
    #expect(AbstainReason.sourceSpecific("a").documentationID == "sourceSpecific")
    #expect(AbstainReason.sourceSpecific("b").documentationID == "sourceSpecific")
    #expect(DemotionReason.sourceSpecific("a").documentationID == "sourceSpecific")
    #expect(DemotionReason.sourceSpecific("b").documentationID == "sourceSpecific")
    let other = DownbeatEstimate(
      beats: [BeatTimestamp(presentationTime: 1.0, confidence: 0.5, strength: 0.5)],
      meter: MeterEstimate(beatsPerBar: 3, source: .assumed),
      confidence: 0.7, phaseIndex: 1)
    #expect(DownbeatResult.detected(estimate: Self.sampleEstimate).documentationID == "detected")
    #expect(DownbeatResult.detected(estimate: other).documentationID == "detected")
  }

  // MARK: - `.docs` resolves to authored prose (not fallback) + strip proof

  @Test("AnalysisIntensity docs resolve to authored prose (was fallback-only in 11.2)")
  func intensityDocs() {
    for c in AnalysisIntensity.allCases { Validator.assertResolved(c.docs, c.documentationID) }
  }

  @Test("OctaveEquivalencePolicy docs resolve")
  func octaveDocs() {
    for c in OctaveEquivalencePolicy.allCases {
      Validator.assertResolved(c.docs, c.documentationID)
    }
  }

  @Test("MLExecutionPolicy docs resolve")
  func mlDocs() { for c in Self.mlCases { Validator.assertResolved(c.docs, c.documentationID) } }

  @Test("DownbeatResult docs resolve")
  func downbeatDocs() {
    for c in Self.downbeatCases { Validator.assertResolved(c.docs, c.documentationID) }
  }

  @Test("AbstainReason docs resolve")
  func abstainDocs() {
    for c in Self.abstainCases { Validator.assertResolved(c.docs, c.documentationID) }
  }

  @Test("DemotionReason docs resolve")
  func demotionDocs() {
    for c in Self.demotionCases { Validator.assertResolved(c.docs, c.documentationID) }
  }

  // MARK: - Structural validator over the 25 on-disk files

  @Test("AnalysisIntensity files satisfy the authoring contract")
  func validateIntensity() { validate("AnalysisIntensity", Self.intensityStems) }

  @Test("OctaveEquivalencePolicy files satisfy the authoring contract")
  func validateOctave() { validate("OctaveEquivalencePolicy", Self.octaveStems) }

  @Test("MLExecutionPolicy files satisfy the authoring contract")
  func validateML() { validate("MLExecutionPolicy", Self.mlStems) }

  @Test("DownbeatResult files satisfy the authoring contract")
  func validateDownbeat() { validate("DownbeatResult", Self.downbeatStems) }

  @Test("AbstainReason files satisfy the authoring contract")
  func validateAbstain() { validate("AbstainReason", Self.abstainStems) }

  @Test("DemotionReason files satisfy the authoring contract")
  func validateDemotion() { validate("DemotionReason", Self.demotionStems) }

  func validate(_ kind: String, _ stems: [String]) {
    let dir = Validator.docsRoot.appendingPathComponent(kind)
    let onDisk = Set(Validator.visibleFiles(in: dir))
    let expected = Set(stems.map { "\($0).md" })
    #expect(
      onDisk == expected, "\(kind): on-disk \(onDisk.sorted()) != expected \(expected.sorted())")
    let pmap = Self.payloads[kind] ?? [:]
    for stem in stems {
      let problems = Validator.validateFile(
        at: dir.appendingPathComponent("\(stem).md"), stem: stem, expectedPayload: pmap[stem])
      #expect(problems.isEmpty, "\(kind)/\(stem).md: \(problems.joined(separator: "; "))")
    }
  }

  // MARK: - 49-file corpus total (11.3a 24 + 11.3b 25)

  @Test("The full canonical corpus totals exactly 49 files")
  func totalCorpusIs49() {
    let entries =
      (try? FileManager.default.contentsOfDirectory(
        at: Validator.docsRoot, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
    var count = 0
    for entry in entries where !entry.lastPathComponent.hasPrefix("_") {
      let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
      guard isDir else { continue }
      count +=
        Validator.visibleFiles(in: entry).filter { $0.hasSuffix(".md") && !$0.hasPrefix("_") }.count
    }
    #expect(count == 49, "expected 49 authored files across all types, found \(count)")
  }

  // MARK: - DD-9 targeted semantic checks

  @Test("level7.md documents the case .default expression-pattern footgun")
  func level7FootgunDocumented() {
    let body = Self.bodyLowercased("AnalysisIntensity/level7.md")
    #expect(body.contains("default"), "level7: no mention of .default")
    #expect(
      body.contains("expression-pattern") || body.contains("expression pattern")
        || body.contains("exhaustiv"),
      "level7: no expression-pattern / exhaustivity footgun note")
  }

  @Test("Every AnalysisIntensity level doc is budget-honest (reserved + uniform)")
  func everyLevelBudgetHonest() {
    for stem in Self.intensityStems {
      let body = Self.bodyLowercased("AnalysisIntensity/\(stem).md")
      #expect(body.contains("budget"), "\(stem): missing budget framing")
      #expect(
        body.contains("reserved") || body.contains("uniform") || body.contains("1.0"),
        "\(stem): missing reserved/uniform budget honesty")
    }
  }

  @Test("sourceSpecific docs use no phantom quoted string value")
  func sourceSpecificNoPhantomString() {
    for path in ["AbstainReason/sourceSpecific.md", "DemotionReason/sourceSpecific.md"] {
      let raw =
        (try? String(contentsOf: Validator.docsRoot.appendingPathComponent(path), encoding: .utf8))
        ?? ""
      #expect(
        !raw.contains("\""), "\(path): contains a double-quote (possible phantom string literal)")
    }
  }

  static func bodyLowercased(_ relativePath: String) -> String {
    ((try? String(
      contentsOf: Validator.docsRoot.appendingPathComponent(relativePath), encoding: .utf8))
      ?? "")
      .lowercased()
  }
}
