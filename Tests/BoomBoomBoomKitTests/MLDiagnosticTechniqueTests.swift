//
//  MLDiagnosticTechniqueTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 Task 10: capability-protocol witness + protocol-inherits-
//  MLTechnique compile-time check.
//

import BoomBoomBoomKit
import BoomBoomBoomKitML
import Foundation
import Testing

/// Story 4-6 code review P15: the compile-time witness test is
/// model-independent and ALWAYS runs. The existential runtime test
/// depends on a successful `BNNSTechnique` construction; PR #2 round 2
/// (N6) routes that through the committed `CustomBundled.mlmodelc`
/// fixture (matches the BNNSTechniqueTests.swift convention) instead of
/// gating on `bundledReferenceURL`, which is hardcoded `nil` under
/// Story 4-6 Branch C and would otherwise leave the existential cast
/// permanently untested.
@available(macOS 15.0, *)
private func fixtureURL() -> URL? {
  guard let resourceURL = Bundle.module.resourceURL else { return nil }
  let url =
    resourceURL
    .appendingPathComponent("Fixtures")
    .appendingPathComponent("CustomBundled.mlmodelc")
  return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

@available(macOS 15.0, *)
private func fixtureMissing() -> Bool {
  fixtureURL() == nil
}

@Suite("MLDiagnosticTechnique (Story 4-6 AC #3)")
struct MLDiagnosticTechniqueTests {

  /// AC #3: ``BNNSTechnique`` conforms to ``MLDiagnosticTechnique``. This
  /// is a compile-time witness — if the conformance is dropped, this
  /// test won't compile. The runtime body is trivial; the proof is
  /// the type-level relationship. Runs unconditionally regardless of
  /// bundled-model availability (the constraint is type-level).
  @Test("BNNSTechnique conforms to MLDiagnosticTechnique (compile-time witness)")
  func bnnsTechniqueConformsToMLDiagnosticTechnique() throws {
    if #available(macOS 15.0, *) {
      // Compile-time witness: this function signature requires
      // `T: MLDiagnosticTechnique`. The function call would fail to
      // compile if BNNSTechnique no longer adopted the protocol.
      assertMLDiagnosticTechnique(BNNSTechnique.self)
    }
  }

  /// AC #3: ``MLDiagnosticTechnique`` inherits ``MLTechnique`` — a
  /// conformer satisfies both. Without inheritance, runtime narrowing
  /// `as? MLDiagnosticTechnique` would lose the `evaluate(trace:)` slot.
  ///
  /// PR #2 N6: gated on `fixtureMissing()` (always false under normal
  /// `swift test` / `make test`) and constructs `BNNSTechnique` from
  /// the committed `CustomBundled.mlmodelc` fixture. Story 4-6 P15
  /// previously gated on `bundledReferenceURL == nil`, which left the
  /// existential cast permanently untested under Branch C builds.
  @Test(
    "MLDiagnosticTechnique inherits MLTechnique (existential witness)",
    .disabled(
      if: {
        if #available(macOS 15.0, *) { return fixtureMissing() }
        return true
      }())
  )
  func mlDiagnosticTechniqueInheritsMLTechnique() throws {
    if #available(macOS 15.0, *) {
      // The runtime upcast `MLDiagnosticTechnique → MLTechnique` is
      // load-bearing for `AudioAnalysisService.evaluateMLIfActive`'s
      // `as? MLDiagnosticTechnique` narrowing. Without it the service
      // could never recover the base-protocol slot from a diagnostic
      // existential. The compile-time witness above proves the type
      // relationship; this body proves the existential cast resolves
      // at runtime — fails (via try #require) rather than silently
      // returning if construction fails.
      let url = try #require(fixtureURL())
      let bnns: any MLDiagnosticTechnique = try BNNSTechnique(modelURL: url)
      let asMLTechnique: any MLTechnique = bnns
      _ = asMLTechnique  // Use the upcast result so the compiler retains it.
    }
  }
}

/// Generic helper enforcing the `T: MLDiagnosticTechnique` constraint at
/// compile time. Used by the witness test above.
private func assertMLDiagnosticTechnique<T: MLDiagnosticTechnique>(_ type: T.Type) {
  // Intentionally empty — the constraint is the proof.
}
