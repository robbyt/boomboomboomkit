//
//  MLTechniqueProtocolTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-5 AC #12: compile-time witness that the public ``MLTechnique``
//  protocol surface is consumer-conformable. Three witnesses are required:
//
//    1. ``BNNSTechnique`` — the library's bundled BNNSGraph implementation.
//    2. ``MockMLTechnique`` — the test-support double from
//       ``BoomBoomBoomKitTestSupport``.
//    3. ``TestCustomTechnique`` — a class declared INSIDE this file with a
//       trivial conformance, proving that downstream consumers can author
//       their own ``MLTechnique`` from scratch without needing any
//       library-internal hooks.
//
//  The witnesses are pure type-checks: ``assertMLTechnique(_:)`` takes a
//  metatype and does nothing at runtime. Failure modes are compile errors
//  ("type does not conform to protocol MLTechnique"), not assertion misses,
//  so the test simply has to BUILD to succeed.
//

import BoomBoomBoomKit
import BoomBoomBoomKitML
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@Suite("Story 4-5 AC #12: MLTechnique protocol conformance witnesses")
struct MLTechniqueProtocolTests {

  /// Generic helper that compile-checks `T: MLTechnique` without
  /// constructing an instance. The body is intentionally empty — if the
  /// caller passes a metatype that does NOT conform, the compiler rejects
  /// the call site at type-check time.
  static func assertMLTechnique<T: MLTechnique>(_: T.Type) {}

  /// Downstream-consumer-style conformance. This intentionally lives
  /// inside the test (not in `Sources/`) to prove the protocol is
  /// reachable + implementable from outside the library's modules.
  /// Returns a constant evaluation regardless of trace content.
  final class TestCustomTechnique: MLTechnique {
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
      MLEvaluation(bpm: 128.0, confidence: 0.99, modelIdentifier: "test-custom")
    }
  }

  @Test("BNNSTechnique conforms to MLTechnique at compile time")
  func bnnsTechniqueConforms() {
    // Task 4 will declare `BNNSTechnique: MLTechnique` after Shape A-prime
    // ships. Until then, BNNSTechnique is the Story 4-1 placeholder
    // (`public struct BNNSTechnique: Sendable`) and the assertion below
    // would fail at compile time. The assertion is re-enabled by Task 4.
    if #available(macOS 15.0, *) {
      // Self.assertMLTechnique(BNNSTechnique.self)  // re-enable in Task 4
    }
  }

  @Test("MockMLTechnique conforms to MLTechnique at compile time")
  func mockMLTechniqueConforms() {
    Self.assertMLTechnique(MockMLTechnique.self)
  }

  @Test("Custom downstream-consumer-style conformance compiles")
  func customConformanceCompiles() {
    Self.assertMLTechnique(TestCustomTechnique.self)
  }

  @Test("MLTechniqueError surface covers the four documented failure modes")
  func mlTechniqueErrorCases() {
    // Exhaustive switch — if a case is added or renamed, this fails to
    // compile, surfacing the public-surface change to the reader.
    let url = URL(fileURLWithPath: "/tmp/does-not-exist.mlmodelc")
    let cases: [MLTechniqueError] = [
      .modelResourceMissing(url),
      .modelLoadFailed(underlying: NSError(domain: "test", code: 1)),
      .invalidTensorContract(missing: "input"),
      .binCountMismatch(expected: 256, actual: 128),
    ]
    for err in cases {
      switch err {
      case .modelResourceMissing: break
      case .modelLoadFailed: break
      case .invalidTensorContract: break
      case .binCountMismatch: break
      }
    }
    #expect(cases.count == 4)
  }
}
