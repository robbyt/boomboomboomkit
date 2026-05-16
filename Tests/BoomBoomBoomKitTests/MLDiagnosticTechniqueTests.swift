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

@Suite("MLDiagnosticTechnique (Story 4-6 AC #3)")
struct MLDiagnosticTechniqueTests {

  /// AC #3: ``BNNSTechnique`` conforms to ``MLDiagnosticTechnique``. This
  /// is a compile-time witness — if the conformance is dropped, this
  /// test won't compile. The runtime body is trivial; the proof is
  /// the type-level relationship.
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
  @Test("MLDiagnosticTechnique inherits MLTechnique (existential witness)")
  func mlDiagnosticTechniqueInheritsMLTechnique() throws {
    if #available(macOS 15.0, *) {
      // Construct an existential and confirm both protocol slots
      // resolve. The cast through `any MLDiagnosticTechnique` would
      // fail at compile time if the inheritance was dropped.
      let bnns: any MLDiagnosticTechnique
      do {
        bnns = try BNNSTechnique()
      } catch {
        // Branch C / missing model is acceptable — the conformance
        // witness above already covered the type relationship. Skip
        // the existential proof gracefully so this test passes when
        // the bundled model is absent.
        return
      }
      let asMLTechnique: any MLTechnique = bnns
      _ = asMLTechnique  // Suppress unused-result warning.
    }
  }
}

/// Generic helper enforcing the `T: MLDiagnosticTechnique` constraint at
/// compile time. Used by the witness test above.
private func assertMLDiagnosticTechnique<T: MLDiagnosticTechnique>(_ type: T.Type) {
  // Intentionally empty — the constraint is the proof.
}
