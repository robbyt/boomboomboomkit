import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Pure `nonisolated` logic tests for the Story 11.6 docs-popover infrastructure:
// the `MergeStrategyDoc` adapter catalog, real end-to-end doc resolution through
// the shipped `BoomBoomBoomKitDocs` bundle, and the GitHub source-URL builder.
// No UI, no audio, no `AudioAnalysisService`.
@Suite("HelpButton logic")
struct HelpButtonLogicTests {

  // Exact hardcoded docID literal per case — a rename of a `BPMSelectionPolicy`
  // case (which changes its rawValue) breaks this map, so the popover can never
  // silently point at the wrong doc file.
  private static let expectedDocIDs: [BPMSelectionPolicy: String] = [
    .maxConfidence: "maxConfidence",
    .dedup: "dedup",
    .quorum: "quorum",
    .average: "average",
    .median: "median",
    .weightedAverage: "weightedAverage",
    .union: "union",
    .windowVoting: "windowVoting",
  ]

  @Test("Every merge-strategy adapter has a stable kind/id + non-empty copy")
  func adapterCatalogIsStableAndComplete() throws {
    var seenIDs = Set<String>()
    for policy in BPMSelectionPolicy.allCases {
      let doc = MergeStrategyDoc(policy)
      #expect(doc.kind == "BPMSelectionPolicy")

      let expectedID = try #require(Self.expectedDocIDs[policy])
      #expect(doc.id == expectedID)
      #expect(doc.id == policy.rawValue)

      #expect(!doc.shortDescription.isEmpty)
      #expect(!doc.displayName.isEmpty)
      #expect(doc.controlName == "Merge strategy")

      seenIDs.insert(doc.id)
    }
    // Exact displayName capitalization (the only derivation in the adapter):
    // humanized rawValue with a capitalized first letter.
    #expect(MergeStrategyDoc(.maxConfidence).displayName == "Max confidence")
    #expect(MergeStrategyDoc(.windowVoting).displayName == "Window voting")
    // All 8 ids are unique (one Set).
    #expect(seenIDs.count == 8)
    #expect(seenIDs.count == BPMSelectionPolicy.allCases.count)
  }

  @Test("Every merge strategy resolves to authored docs, not the fallback sentinel")
  func docsResolveToAuthoredContent() {
    for policy in BPMSelectionPolicy.allCases {
      let rendered = String(MergeStrategyDoc(policy).docs.characters)
      // Proves real end-to-end resolution through the bundle without coupling to
      // the library's prose wording: the accessor's degraded sentinel (~55 chars)
      // is absent, and the authored 200-400-word treatment is present (length far
      // exceeds any fallback).
      #expect(!rendered.contains("Documentation unavailable"))
      #expect(rendered.count > 120)
    }
  }

  @Test("repoDocURL is valid for every merge strategy, structural slash preserved")
  func repoDocURLValidForAllCases() {
    for policy in BPMSelectionPolicy.allCases {
      let doc = MergeStrategyDoc(policy)
      let absolute = HelpButtonDocs.repoDocURL(kind: doc.kind, id: doc.id).absoluteString
      #expect(absolute.hasSuffix("/BPMSelectionPolicy/\(doc.id).md"))
      // The structural `/` separators are preserved (not encoded).
      #expect(absolute.contains("/BPMSelectionPolicy/"))
    }
  }

  // MARK: - IntensityDoc

  private static let allLevels: [AnalysisIntensity] = [
    .level1, .level2, .level3, .level4, .level5,
    .level6, .level7, .level8, .level9, .level10,
  ]

  @Test("Every intensity level adapter has a stable kind/id + non-empty copy")
  func intensityAdapterCatalogIsStableAndComplete() {
    var seenIDs = Set<String>()
    for intensity in Self.allLevels {
      let doc = IntensityDoc(intensity)
      #expect(doc.kind == "AnalysisIntensity")
      // Real drift pin: the literal "level<N>" rawValue the accessor reads
      // (asserting `== intensity.documentationID` would be tautological, since
      // the adapter defines `id` as exactly that).
      #expect(doc.id == "level\(intensity.level)")
      #expect(!doc.shortDescription.isEmpty)
      #expect(!doc.displayName.isEmpty)
      #expect(doc.controlName == "Intensity")
      seenIDs.insert(doc.id)
    }
    // Named-alias suffixes surface on the four aliased levels.
    #expect(IntensityDoc(.level1).displayName == "Level 1 (fastest)")
    #expect(IntensityDoc(.level7).displayName == "Level 7 (default)")
    #expect(IntensityDoc(.level8).displayName == "Level 8 (thorough)")
    #expect(IntensityDoc(.level10).displayName == "Level 10 (maximum)")
    #expect(IntensityDoc(.level3).displayName == "Level 3")
    #expect(seenIDs.count == 10)
  }

  @Test("Every intensity level resolves to authored docs, not the fallback sentinel")
  func intensityDocsResolveToAuthoredContent() {
    for intensity in Self.allLevels {
      let rendered = String(IntensityDoc(intensity).docs.characters)
      #expect(!rendered.contains("Documentation unavailable"))
      #expect(rendered.count > 120)
    }
  }

  // MARK: - EnsembleDoc

  @Test("Every ensemble preset adapter carries the resolved policy's doc key")
  func ensembleAdapterMapsToPolicyDoc() {
    #expect(EnsembleDoc(.default).kind == "EnsemblePolicy")
    // Exact preset -> library doc id (the resolved policy's stableKey). The two
    // weightedVoting presets intentionally share the "weightedVoting" doc.
    #expect(EnsembleDoc(.default).id == "default")
    #expect(EnsembleDoc(.dspOnly).id == "dspOnly")
    #expect(EnsembleDoc(.mlAugmented).id == "weightedVoting")
    #expect(EnsembleDoc(.trustFileTags).id == "weightedVoting")
    // The four explicit id assertions above are the drift pins; the loop
    // checks the remaining derivations (asserting id == preset.policy.documentationID
    // would be tautological — the adapter defines id as exactly that).
    for preset in EnsemblePreset.allCases {
      let doc = EnsembleDoc(preset)
      #expect(doc.displayName == preset.displayName)
      #expect(doc.shortDescription == preset.subtitle)
      #expect(doc.controlName == "Ensemble")
    }
  }

  @Test("Every ensemble preset resolves to authored docs, not the fallback sentinel")
  func ensembleDocsResolveToAuthoredContent() {
    for preset in EnsemblePreset.allCases {
      let rendered = String(EnsembleDoc(preset).docs.characters)
      #expect(!rendered.contains("Documentation unavailable"))
      #expect(rendered.count > 120)
    }
  }

  @Test("repoDocURL percent-encodes adversarial id segments without crashing")
  func repoDocURLEncodesAdversarialSegments() {
    let base =
      "https://github.com/robbyt/BoomBoomBoomKit/blob/main/Sources/BoomBoomBoomKit/Resources/Documentation/"

    // The base is a valid absolute URL, so `repoDocURL`'s `URL(string:)` guard
    // never falls through to its file-URL fallback (that branch is dead by
    // construction, not a reachable degraded path).
    #expect(URL(string: base) != nil)

    // A space in the id segment encodes to %20.
    let spaceURL = HelpButtonDocs.repoDocURL(kind: "BPMSelectionPolicy", id: "weird id")
    #expect(spaceURL.absoluteString == base + "BPMSelectionPolicy/weird%20id.md")

    // An in-segment `/` encodes to %2F (does NOT become a path separator).
    let slashURL = HelpButtonDocs.repoDocURL(kind: "BPMSelectionPolicy", id: "a/b")
    #expect(slashURL.absoluteString == base + "BPMSelectionPolicy/a%2Fb.md")
  }
}
