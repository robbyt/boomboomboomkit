//
//  DocumentedCaseTests.swift
//  BoomBoomBoomKitTests
//
//  Story 11.1: DocumentedCase protocol shape, the BoomBoomBoomKitDocs accessor
//  happy path (sentinel resource) + fallback, split-extension invariant, and
//  concurrent-access safety of the Mutex cache.
//

// Plain import (NOT @testable): every exercised symbol is public, so this
// enforces the consumer-visible surface — a lost `public` breaks the suite.
import BoomBoomBoomKit
import Foundation
import Testing

@Suite("Story 11.1 DocumentedCase")
struct DocumentedCaseTests {

  // MARK: - Fixtures

  /// String-raw conformer: derives `documentationID` from `rawValue` via the
  /// constrained extension.
  private enum FixtureCase: String, DocumentedCase {
    static let documentedKind = "FixtureCase"
    case alpha
    case beta
  }

  /// Associated-value conformer: cannot synthesize a raw value, so it
  /// hand-writes `documentationID`. Mirrors how `MLExecutionPolicy` /
  /// `AbstainReason` will conform in later stories.
  private enum PayloadCase: DocumentedCase {
    static let documentedKind = "PayloadCase"
    case tuned(Double)
    var documentationID: String { "tuned" }
  }

  // MARK: - Protocol shape

  @Test("String-raw conformer derives documentationID from rawValue")
  func stringRawDerivesDocumentationID() {
    #expect(FixtureCase.alpha.documentationID == "alpha")
    #expect(FixtureCase.beta.documentationID == "beta")
  }

  // MARK: - Happy path (sentinel resource)

  @Test("Sentinel resource resolves through Bundle.module + subdirectory + parse")
  func happyPathResolvesSentinel() {
    // The ONLY test that proves the `.copy` resource declaration, Bundle.module
    // generation, preserved subdirectory, filename lookup, and markdown parse
    // all actually work — a fallback-only suite passes even when every real
    // lookup is broken.
    let doc = BoomBoomBoomKitDocs.attributedString(for: "_Fixture", id: "_probe")
    let text = String(doc.characters)
    #expect(text.contains("Probe"))
    #expect(text.contains("Sentinel resource"))
    #expect(!text.contains("Documentation unavailable"))
  }

  // MARK: - Fallback

  @Test("Missing resource returns an informative non-empty fallback")
  func fallbackNamesKindAndID() {
    let doc = BoomBoomBoomKitDocs.attributedString(for: "NoSuchKind", id: "nope")
    let text = String(doc.characters)
    #expect(!text.isEmpty)
    #expect(text.contains("NoSuchKind"))
    #expect(text.contains("nope"))
  }

  // MARK: - Blank-parse guard

  @Test("Whitespace-only resource is a miss, not a blank string")
  func whitespaceOnlyResourceFallsBack() {
    // The `_blank` sentinel is an all-whitespace .md. Inline-only markdown
    // parsing PRESERVES whitespace, so it parses to a non-empty-but-blank
    // string; the guard must still treat it as a miss and return the fallback,
    // upholding the never-empty (non-blank) contract.
    let doc = BoomBoomBoomKitDocs.attributedString(for: "_Fixture", id: "_blank")
    let text = String(doc.characters)
    #expect(text.contains("Documentation unavailable"))
    #expect(text.contains("_blank"))
  }

  // MARK: - Front-matter stripping

  @Test("YAML front matter is stripped, not rendered as visible docs")
  func frontMatterIsStripped() {
    // Every authored 11.3 doc file carries `---`-delimited id:/title:/payload:
    // metadata (KDD-E7). The accessor must strip it so `.docs` shows only the
    // prose body — inline-only parsing would otherwise render the metadata as
    // literal text ahead of the content.
    let doc = BoomBoomBoomKitDocs.attributedString(for: "_Fixture", id: "_frontmatter")
    let text = String(doc.characters)
    // Body survives.
    #expect(text.contains("Body"))
    #expect(text.contains("visible prose"))
    // Metadata does NOT.
    #expect(!text.contains("METADATA_TITLE_SHOULD_NOT_RENDER"))
    #expect(!text.contains("id:"))
    #expect(!text.contains("payload:"))
    #expect(!text.contains("---"))
  }

  // MARK: - Split-extension invariant

  @Test("Associated-value conformer inherits docs from the unconstrained extension")
  func associatedValueConformerInheritsDocs() {
    // Guards AC #2: a refactor trapping `docs` on the constrained
    // `RawRepresentable` extension would strip `docs` from every
    // associated-value conformer and MUST fail here. No resource ships for
    // PayloadCase, so this resolves to the fallback naming (kind, id).
    let doc = PayloadCase.tuned(128.0).docs
    let text = String(doc.characters)
    #expect(!text.isEmpty)
    #expect(text.contains("PayloadCase"))
    #expect(text.contains("tuned"))
  }

  // MARK: - Concurrent-access safety

  @Test("Concurrent same-key lookups return consistent values with no crash")
  func concurrentAccessIsSafe() async {
    // Concurrent-access SAFETY smoke test only: it asserts no crash / torn read
    // and consistent values under contention. It does NOT prove single-insertion
    // or negative-caching — that would need an injectable-loader / cache-reset
    // seam (out of scope). The Mutex + double-checked locking are sound by
    // inspection; a lost double-check only causes a benign redundant parse.
    let reference = String(
      BoomBoomBoomKitDocs.attributedString(for: "_Fixture", id: "_probe").characters)

    let results = await withTaskGroup(of: String.self) { group in
      for _ in 0..<100 {
        group.addTask {
          String(
            BoomBoomBoomKitDocs.attributedString(for: "_Fixture", id: "_probe").characters)
        }
      }
      var collected: [String] = []
      for await value in group {
        collected.append(value)
      }
      return collected
    }

    #expect(results.count == 100)
    #expect(results.allSatisfy { $0 == reference })
  }
}

// MARK: - Story 11.4: FR-50 drift detection

/// One child `@Suite` per documented type, each asserting every case resolves
/// to authored prose (NOT the `"Documentation unavailable"` fallback). This is
/// the FR-50 drift check: for a `CaseIterable` type, adding a case grows
/// `allCases`, the parameterized test auto-covers it, and CI fails (fallback)
/// until the `.md` is authored. Grouped under one parent suite so
/// `make docc-validate`'s `--filter DocumentedCaseDriftTests` selects them all.
/// The registry + representative case lists live in `DocCorpus`
/// (`DocumentationValidatorTests.swift`).
@Suite("Story 11.4 DocumentedCase drift")
struct DocumentedCaseDriftTests {

  // MARK: Per-type drift (CaseIterable — mechanical runtime coverage)

  @Suite("BPMSelectionPolicy drift")
  struct BPMSelectionPolicyDrift {
    @Test("docs resolve", arguments: BPMSelectionPolicy.allCases)
    func docsResolve(_ c: BPMSelectionPolicy) {
      DocCorpus.assertResolved(c.docs, c.documentationID)
    }
  }

  @Suite("VotingPolicy drift")
  struct VotingPolicyDrift {
    @Test("docs resolve", arguments: VotingPolicy.allCases)
    func docsResolve(_ c: VotingPolicy) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("DSPTechnique drift")
  struct DSPTechniqueDrift {
    @Test("docs resolve", arguments: DSPTechnique.allCases)
    func docsResolve(_ c: DSPTechnique) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("AnalysisIntensity drift")
  struct AnalysisIntensityDrift {
    @Test("docs resolve", arguments: AnalysisIntensity.allCases)
    func docsResolve(_ c: AnalysisIntensity) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("OctaveEquivalencePolicy drift")
  struct OctaveEquivalencePolicyDrift {
    @Test("docs resolve", arguments: OctaveEquivalencePolicy.allCases)
    func docsResolve(_ c: OctaveEquivalencePolicy) {
      DocCorpus.assertResolved(c.docs, c.documentationID)
    }
  }

  // MARK: Per-type drift (hand-rostered — runtime list + compile tripwire below)

  @Suite("EnsemblePolicy drift")
  struct EnsemblePolicyDrift {
    @Test("docs resolve", arguments: EnsemblePolicy.allPolicies)
    func docsResolve(_ c: EnsemblePolicy) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("MLExecutionPolicy drift")
  struct MLExecutionPolicyDrift {
    @Test("docs resolve", arguments: DocCorpus.mlCases)
    func docsResolve(_ c: MLExecutionPolicy) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("DownbeatResult drift")
  struct DownbeatResultDrift {
    @Test("docs resolve", arguments: DocCorpus.downbeatCases)
    func docsResolve(_ c: DownbeatResult) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("AbstainReason drift")
  struct AbstainReasonDrift {
    @Test("docs resolve", arguments: DocCorpus.abstainCases)
    func docsResolve(_ c: AbstainReason) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  @Suite("DemotionReason drift")
  struct DemotionReasonDrift {
    @Test("docs resolve", arguments: DocCorpus.demotionCases)
    func docsResolve(_ c: DemotionReason) { DocCorpus.assertResolved(c.docs, c.documentationID) }
  }

  // MARK: Compile-time tripwire for the 5 hand-rostered enums (absorbs RosterDriftCanaries)

  /// These `switch`es have NO `default:` arm, so adding a case to any of the
  /// five non-`CaseIterable` enums breaks the test-target BUILD here, forcing an
  /// explicit acknowledgment.
  ///
  /// HONEST LIMIT (Story 11.4 DD-2): this forces a developer to add a `case`
  /// arm; it CANNOT mechanically force them to also add the value to
  /// `allPolicies` / the `DocCorpus` representative list. A case added to
  /// source + this switch but omitted from the list stays invisible to the
  /// runtime `.docs` drift check above, and — if no `.md` was authored for it —
  /// NO CI test catches it (the file<->id check only fires on an ORPHAN or stale
  /// `.md`, i.e. a file present with no matching case; it cannot inspect a case
  /// that has no file). Swift cannot enumerate a non-`CaseIterable` enum's cases
  /// at runtime, so this residual is inherent; it is caught only by code review
  /// (deferred-work W84) and, at runtime, by the visible production fallback if
  /// code accesses the case. Do NOT add `@frozen` to any of these enums.
  @Test("Hand-rostered enums have no undocumented cases (compile-time tripwire)")
  func handRosteredEnumsHaveNoUndocumentedCases() {
    func ens(_ p: EnsemblePolicy) {
      switch p {
      case .default, .dspOnly, .mlOnly, .highestConfidence, .weightedVoting: break
      }
    }
    func ml(_ p: MLExecutionPolicy) {
      switch p {
      case .never, .always, .whenDSPConfidenceBelow: break
      }
    }
    func db(_ p: DownbeatResult) {
      switch p {
      case .notAttempted, .noneDetected, .detected: break
      }
    }
    func ab(_ p: AbstainReason) {
      switch p {
      case .policyDisabled, .inputBelowMinimum, .confidenceBelowFloor, .sourceSpecific: break
      }
    }
    func dm(_ p: DemotionReason) {
      switch p {
      case .implausibleForContext, .sourceSpecific: break
      }
    }
    // Reference each with a representative value so the helpers are not dead code.
    ens(.dspOnly)
    ml(.never)
    db(.notAttempted)
    ab(.policyDisabled)
    dm(.implausibleForContext)
  }

  // MARK: Payload-invariant documentationID (assoc-value cases, >=2 payloads)

  @Test("Associated-value documentationID ignores the payload value")
  func payloadInvariantDocumentationID() {
    // EnsemblePolicy.weightedVoting carries a SignalWeights payload — prove the
    // ID is invariant across two DISTINCT weightings (a payload-dependent ID
    // would silently fallback for any non-default weights, since allPolicies
    // only carries .weightedVoting(.default)).
    #expect(EnsemblePolicy.weightedVoting(.default).documentationID == "weightedVoting")
    #expect(
      EnsemblePolicy.weightedVoting(SignalWeights(dsp: 2.0, ml: 0.5)).documentationID
        == "weightedVoting")
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
    #expect(
      DownbeatResult.detected(estimate: DocCorpus.sampleEstimate).documentationID == "detected")
    #expect(DownbeatResult.detected(estimate: other).documentationID == "detected")
  }
}
