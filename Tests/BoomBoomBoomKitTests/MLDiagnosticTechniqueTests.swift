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
/// depends on a successful `BNNSTechnique()` construction, so it skips
/// cleanly via this suite-level predicate when the bundled model is
/// absent (Branch C). The previous `catch { return }` pattern was
/// performative — the test passed whether anything ran or not.
@available(macOS 15.0, *)
private func diagnosticTechniqueSuiteShouldSkip() -> Bool {
  BNNSTechnique.bundledReferenceURL == nil
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
  /// Skipped via `.disabled(if:)` when the bundled model is absent
  /// (Branch C); a still-failing `BNNSTechnique()` under the suite-
  /// enabled path is a real bug surfaced via `try #require`. Story 4-6
  /// code review P15 replaced the `catch { return }` pattern that
  /// silently passed regardless of whether anything ran.
  @Test(
    "MLDiagnosticTechnique inherits MLTechnique (existential witness)",
    .disabled(
      if: {
        if #available(macOS 15.0, *) { return diagnosticTechniqueSuiteShouldSkip() }
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
      // returning if `BNNSTechnique()` cannot construct.
      let bnns: any MLDiagnosticTechnique = try #require(try? BNNSTechnique())
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
