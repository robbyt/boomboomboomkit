//
//  MLDiagnosticTechnique.swift
//  BoomBoomBoomKit
//
//  Story 4-6: optional capability extension for `MLTechnique` conformers
//  that want to surface per-evaluation numeric diagnostics. The protocol
//  lives in the core target so `AudioAnalysisService.evaluateMLIfActive`
//  can runtime-narrow to it without naming the sibling-target
//  `BNNSTechnique` (the package graph is one-way — Codex finding #1
//  flagged the original `as? BNNSTechnique` plan as a compile error, not
//  a smell).
//

import Foundation

// MARK: - MLDiagnosticTechnique

/// Optional capability extension that an ``MLTechnique`` conformer can
/// adopt to expose per-evaluation numeric diagnostics. Story 4-6 ships
/// the bundled ``BNNSTechnique``'s conformance; consumer-supplied
/// ``MLTechnique`` types may opt in by implementing
/// ``evaluateWithDiagnostic(trace:)``, or skip it without losing
/// correctness (the library falls back to the protocol-frozen
/// ``MLTechnique/evaluate(trace:)`` path on plain conformers).
///
/// ## Why a capability protocol, not a sibling method on a concrete type
///
/// ``AudioAnalysisService`` lives in the core `BoomBoomBoomKit` target;
/// ``BNNSTechnique`` lives in the sibling `BoomBoomBoomKitML` target
/// which depends on core. The dependency arrow is one-way, so the
/// service cannot runtime-narrow via `as? BNNSTechnique` — it would
/// create a cycle. Capability protocols declared in core (which the
/// sibling target can adopt) are the canonical resolution — and they
/// double as the consumer-extension point for any future ML backend that
/// wants the same diagnostic surface.
///
/// This pattern is now a project-wide rule (Story 4-6 close-out
/// elevation, per DD #14): **"Cross-target type narrowing always goes
/// through a protocol declared in the upstream target, never through
/// `as?` to a downstream concrete type."**
///
/// ## Two-element tuple invariant
///
/// ``evaluateWithDiagnostic(trace:)`` returns a tuple of
/// `(MLEvaluation?, MLDiagnosticSnapshot?)`. The two slots track distinct
/// concerns and follow a strict population matrix per the
/// ``MLDiagnosticSnapshot`` doc-comment:
///
/// - **Win path** — both non-nil. `evaluation` carries the model's
///   confident BPM; `snapshot` carries parallel numeric evidence
///   (decoded BPM, softmax max + second-max, input checksum). The
///   `failureStage` field on the snapshot is `nil` on this path.
/// - **Abstain (reached featurize)** — `evaluation == nil`, `snapshot`
///   non-nil. `failureStage` identifies which stage's early-return
///   fired (``MLDiagnosticSnapshot/FailureStage/featurizeRejected``,
///   ``MLDiagnosticSnapshot/FailureStage/graphFailed``,
///   ``MLDiagnosticSnapshot/FailureStage/decodeRejected``, or
///   ``MLDiagnosticSnapshot/FailureStage/confidenceGateRejected``).
/// - **Abstain (pre-featurize)** — both nil. Features were absent, or
///   the feature-set version drifted, so there is no payload to
///   checksum and ``MLDiagnosticSnapshot`` cannot represent the path at
///   all. The conformer returns a `(nil, nil)` tuple and a reporting
///   harness derives the bucket from trace-state inspection, using its
///   own key type rather than ``MLDiagnosticSnapshot/FailureStage``.
///
/// ## Consumer wrappers and diagnostics (wontfix pre-1.0)
///
/// A consumer wrapping ``BNNSTechnique`` in a forwarding ``MLTechnique``
/// type will lose diagnostics — the wrapper does not conform to
/// ``MLDiagnosticTechnique``, so the service's runtime narrowing falls
/// back to the plain ``MLTechnique/evaluate(trace:)`` path and
/// ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` stays nil. Documented as
/// wontfix for the pre-1.0 window per Codex finding #5: forwarding
/// wrappers must re-conform to ``MLDiagnosticTechnique`` if they want
/// the diagnostic path. Trade-off explicitly accepted in the Story 4-6
/// 5-reviewer party-mode pass.
///
/// ## Pre-1.0 framing
///
/// Per project-context.md "Public API Discipline (pre-1.0)", this
/// protocol is NOT 1.0-stable. A future story may promote
/// ``MLDiagnosticTechnique`` to be the primary entry point if a second
/// conformer surfaces consistent needs, rename
/// ``evaluateWithDiagnostic(trace:)``, or change the tuple shape. No
/// backwards compatibility is promised in pre-release.
///
/// ## See also
///
/// - ``MLDiagnosticSnapshot`` — typed-evidence carrier this protocol returns.
/// - ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` — trace field that carries the snapshot.
/// - ``MLTechnique`` — base protocol; frozen for Story 4-5 per DD #18.
public protocol MLDiagnosticTechnique: MLTechnique {

  /// Evaluates the trace AND returns a per-call diagnostic snapshot in
  /// addition to (or instead of) the conventional ``MLEvaluation``.
  ///
  /// - Parameter trace: The diagnostic trace from the just-completed
  ///   merge step. Identical semantics to
  ///   ``MLTechnique/evaluate(trace:)``.
  /// - Returns: Two-element tuple per the protocol's population matrix:
  ///   - `evaluation`: the model's BPM estimate, or `nil` on abstain.
  ///   - `snapshot`: per-call numeric diagnostics, or `nil` ONLY on
  ///     the two pre-featurize abstain paths (features absent, or
  ///     feature-set version drift — neither has a payload to
  ///     checksum, so neither is representable as a snapshot).
  ///     On every other path the snapshot is populated even when the
  ///     evaluation is nil — that is the load-bearing investigation
  ///     evidence the threshold-sweep harness consumes (DD #5
  ///     7-point sweep).
  func evaluateWithDiagnostic(
    trace: BPMDiagnosticTrace
  ) -> (evaluation: MLEvaluation?, snapshot: MLDiagnosticSnapshot?)
}
