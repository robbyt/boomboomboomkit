//
//  MockMLTechnique.swift
//  BoomBoomBoomKitTestSupport
//
//  Public test-target-only mocks conforming to MLTechnique.
//

import BoomBoomBoomKit
import Foundation

/// Test-only ``MLTechnique`` mock that returns a fixed ``MLEvaluation?`` value
/// from every call to ``evaluate(trace:)``, ignoring the trace contents.
///
/// Use the deterministic-injection constructor to control the mock's return
/// value:
/// - `MockMLTechnique()` — abstain path (returns `nil`).
/// - `MockMLTechnique(returning: nil)` — explicit abstain (semantically
///   equivalent, more readable in perf tests).
/// - `MockMLTechnique(returning: MLEvaluation(bpm: 60, confidence: 0.95))`
///   — deterministic non-abstain. Story 4.4 ensemble-policy tests use this
///   pattern to drive specific ensemble outcomes.
///
/// The mock ignores its `trace` parameter — appropriate for unit-testing the
/// pipeline plumbing rather than the model. Real conformances (Story 4.5
/// BNNS, Story 4.6 CoreML) read the trace.
public struct MockMLTechnique: MLTechnique {

  private let evaluation: MLEvaluation?

  public init(returning evaluation: MLEvaluation? = nil) {
    self.evaluation = evaluation
  }

  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    evaluation
  }
}

/// Test-only ``MLTechnique`` mock that records call count and a meaningful
/// witness of trace population for direct wiring proofs (Story 4.3 AC #4).
///
/// `@unchecked Sendable` is required because the mutable `var` fields make
/// this class non-`Sendable` by default. This is a test-only mock with
/// single-threaded use; the unchecked annotation is acceptable per the
/// project-context `nonisolated(unsafe)`-discipline test-only carve-out.
public final class RecordingMockMLTechnique: MLTechnique, @unchecked Sendable {

  /// Number of times ``evaluate(trace:)`` has been called on this instance.
  /// Mutated synchronously inside ``evaluate(trace:)``.
  public var callCount = 0

  /// Number of post-pipeline DSP candidates the most recent
  /// ``evaluate(trace:)`` call observed in
  /// ``BPMDiagnosticTrace/candidatesAfterBoost``. `nil` until the first
  /// call. After the Story 4.3 review's Option 2 resolution, this field
  /// is populated unconditionally by ``MetadataCorroborator/apply(to:input:)``,
  /// so a `> 0` assertion proves the trace was both passed AND actually
  /// populated by the pipeline (not just default-initialized).
  public var capturedCandidatesAfterBoostCount: Int?

  private let evaluation: MLEvaluation?

  public init(returning evaluation: MLEvaluation? = nil) {
    self.evaluation = evaluation
  }

  public func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
    callCount += 1
    capturedCandidatesAfterBoostCount = trace.candidatesAfterBoost.count
    return evaluation
  }
}
