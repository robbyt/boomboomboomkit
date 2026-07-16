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
