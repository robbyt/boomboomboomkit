//
//  MLDiagnosticSnapshot.swift
//  BoomBoomBoomKit
//
//  Always-on numeric diagnostic snapshot of one `MLTechnique.evaluate(trace:)`
//  call. Story 4-6 introduction: replaces the originally-proposed
//  discriminated `MLAbstainReason` enum after the 5-reviewer party-mode +
//  Codex review (2026-05-15) flagged that approach as evidence-thin at
//  thresholds 0.0/0.0 — the most useful numeric evidence disappeared
//  precisely when investigation needed it most.
//
//  This file holds the public typed-evidence struct + nested `FailureStage`
//  and `Gate` enums. The capability protocol that produces this snapshot
//  lives in the sibling `MLDiagnosticTechnique.swift`; the trace field that
//  carries it lives on `BPMDiagnosticTrace`.
//

import Foundation

// MARK: - MLDiagnosticSnapshot

/// Per-evaluation diagnostic snapshot emitted by ``MLDiagnosticTechnique``
/// conformers (Story 4-6's ``BNNSTechnique`` adopts the protocol; consumer
/// `MLTechnique` types may opt in by adding the conformance).
///
/// Populated on the trace via ``BPMDiagnosticTrace/mlDiagnosticSnapshot``
/// when ML is active AND the inference reached at least the featurize step.
/// On the two pre-featurize abstain paths (``FailureStage/featuresAbsent``
/// and ``FailureStage/featureVersionMismatch``), no snapshot is constructed
/// because there is no feature payload to checksum — the conformance
/// returns `(nil, nil)` from ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)``
/// and the harness derives the histogram bucket from
/// `MLEvaluation == nil && mlDiagnosticSnapshot == nil` plus trace-state
/// inspection (`mlFeatures == nil` → ``FailureStage/featuresAbsent``;
/// `featureSetVersion != "v2"` → ``FailureStage/featureVersionMismatch``).
///
/// ## Population matrix
///
/// | Path | `decodedBPM` | `softmaxMax` | `softmaxSecondMax` | `inputFeatureChecksum` | `failureStage` | `gateFired` |
/// |------|--------------|--------------|--------------------|------------------------|----------------|-------------|
/// | win (`evaluate(trace:)` returned non-nil) | non-nil | non-nil | non-nil | non-nil | nil | nil |
/// | `.featurizeRejected` | nil | nil | nil | non-nil (over input features) | `.featurizeRejected` | nil |
/// | `.graphFailed` | nil | nil | nil | non-nil | `.graphFailed` | nil |
/// | `.decodeRejected` (non-finite logits) | nil | nil | nil | non-nil | `.decodeRejected` | nil |
/// | `.decodeRejected` (out-of-range argmax) | non-nil (raw out-of-range value) | non-nil | non-nil | non-nil | `.decodeRejected` | nil |
/// | `.confidenceGateRejected` | non-nil | non-nil | non-nil | non-nil | `.confidenceGateRejected` | non-nil |
///
/// The numeric fields are the load-bearing evidence; ``failureStage`` is a
/// categorical summary on top. At investigation-time threshold 0.0/0.0 (DD
/// #5), ``decodedBPM`` + ``softmaxMax`` populate even on what would
/// otherwise be abstain-paths — that is the point: snapshot evidence
/// survives gate disablement so threshold sweeps can answer "is the model
/// producing useful predictions or not?".
///
/// ## Pre-1.0 framing
///
/// Per project-context.md "Public API Discipline (pre-1.0)", this struct
/// is NOT 1.0-stable. Future stories may add fields (e.g., per-bin top-K
/// probabilities), add ``FailureStage`` cases (e.g., split ``graphFailed``
/// further if a second backend lands), or rename fields entirely. No
/// backwards compatibility is promised in pre-release.
///
/// ## See also
///
/// - ``MLDiagnosticTechnique`` — capability protocol that produces the snapshot.
/// - ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` — trace field that carries it.
/// - ``BNNSTechnique`` — Story 4-6's reference conformer.
public struct MLDiagnosticSnapshot: Sendable, Hashable, CustomStringConvertible {

  /// Decoded argmax-derived BPM. `nil` only when the inference path failed
  /// BEFORE producing a logit vector (graph compile/execute/workspace
  /// error) or when the logit vector contained non-finite values (so no
  /// argmax could be computed).
  ///
  /// Out-of-range argmax (BPM ∉ 60.0...200.0) DOES populate this field
  /// with the raw out-of-range value — the snapshot reports what the model
  /// said, not what the library would have accepted (DD #2 doc-comment
  /// invariant).
  public let decodedBPM: Double?

  /// Softmax-max probability after host-side softmax. `nil` iff
  /// ``decodedBPM`` is nil (same root: no logit vector or non-finite
  /// logits). Range `[0.0, 1.0]` when present (clamped by the
  /// ``BNNSTechnique`` host-side softmax decode for public-API stability;
  /// see Story 4-4 DD #4 precedent).
  public let softmaxMax: Double?

  /// Softmax-second-max probability after host-side softmax. `nil` iff
  /// ``decodedBPM`` is nil. Range `[0.0, 1.0]` when present.
  public let softmaxSecondMax: Double?

  /// Cheap drift-detector: stable hash of the input feature payload Swift
  /// produced for this call. Amelia's framing: per-evaluation `UInt64`
  /// checksum of the post-`vvlogf` log-mel byte stream Swift fed into the
  /// model. The Python reference pipeline at `_bmad-output/ml-training/`
  /// can emit the same checksum for the same fixture WAV; if they diverge,
  /// that IS the featurize bug (DD #6 cheap-first methodology).
  ///
  /// Implementation: FNV-1a over the `Float` byte representation of the
  /// input features the conformer received. Cost ~50µs per evaluate,
  /// dwarfed by the BNNS inference path. Hash is deterministic given the
  /// same audio.
  public let inputFeatureChecksum: UInt64

  /// Categorical view derived from the inference path. `nil` on the win
  /// path (``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)`` returned
  /// a non-nil ``MLEvaluation``); on abstain, identifies which stage's
  /// early-return fired. Use this for histogram reporting (Story 4-6
  /// impact-report). The numeric fields above are the load-bearing
  /// evidence; ``failureStage`` is a categorical summary on top.
  public let failureStage: FailureStage?

  /// Sub-discriminator populated only when
  /// ``failureStage`` equals ``FailureStage/confidenceGateRejected``.
  /// Identifies which of the two abstain gates fired:
  /// ``Gate/gate1Softmax`` (softmax-max below threshold) or
  /// ``Gate/gate2Margin`` (margin between top-2 below threshold).
  public let gateFired: Gate?

  /// Abstain-path taxonomy. Six cases cover the full early-return surface
  /// of ``BNNSTechnique/evaluate(trace:)``.
  ///
  /// `inferenceFailed` was split into ``graphFailed`` + ``decodeRejected``
  /// per Codex finding #2: "graph failed", "softmax became non-finite",
  /// and "decoded argmax mapped outside 60…200" point to different
  /// remediation paths — folding them into one bucket loses diagnostic
  /// information.
  ///
  /// `featuresAbsent` and `featureVersionMismatch` are the two
  /// pre-featurize abstains. For those cases no ``MLDiagnosticSnapshot``
  /// is constructed at all (no feature payload to checksum); the
  /// trace's ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` stays nil and the
  /// reporting harness infers the bucket from trace-state inspection.
  public enum FailureStage: String, Sendable, Hashable, CaseIterable {
    /// `trace.mlFeatures == nil` — featurize never received features.
    /// No snapshot is constructed on this path; the case exists in the
    /// taxonomy for histogram completeness in the impact-report harness.
    case featuresAbsent
    /// `trace.mlFeatures.featureSetVersion != supportedFeatureSetVersion`
    /// — feature-set drift detected. No snapshot is constructed on this
    /// path; the case exists for histogram completeness.
    case featureVersionMismatch
    /// ``BNNSTechnique`` internal `featurize(_:)` returned nil (short
    /// clip, mel-band mismatch, layout case unhandled). Snapshot
    /// constructed with ``inputFeatureChecksum`` only.
    case featurizeRejected
    /// BNNSGraph context build / execute / workspace error. Snapshot
    /// constructed with ``inputFeatureChecksum`` only (decode fields nil).
    case graphFailed
    /// Logit decode produced non-finite values OR argmax mapped to a BPM
    /// outside `60.0...200.0`. Snapshot may have decode fields populated
    /// (out-of-range case carries the raw out-of-range BPM) or nil
    /// (non-finite logit case).
    case decodeRejected
    /// Two-gate abstain fired: ``Gate/gate1Softmax`` (softmax-max <
    /// confidence threshold) or ``Gate/gate2Margin`` (margin < margin
    /// threshold). Snapshot has all decode fields + ``gateFired``
    /// populated.
    case confidenceGateRejected
  }

  /// Two-gate sub-discriminator for ``FailureStage/confidenceGateRejected``.
  public enum Gate: String, Sendable, Hashable, CaseIterable {
    /// Softmax-max below ``BNNSTechnique``'s `confidenceThreshold`.
    case gate1Softmax
    /// Margin between top-2 softmax probabilities below
    /// ``BNNSTechnique``'s `marginConfidenceThreshold`.
    case gate2Margin
  }

  /// Constructs a snapshot. Preconditions enforce the population matrix
  /// per the doc-comment above. Pre-featurize abstain paths
  /// (``FailureStage/featuresAbsent`` / ``FailureStage/featureVersionMismatch``)
  /// do NOT call this initializer — the conformance short-circuits before
  /// the feature payload is checksummed.
  ///
  /// - Parameters:
  ///   - decodedBPM: Argmax-derived BPM (may be out-of-range on
  ///     `.decodeRejected`); nil when no logit vector was produced or
  ///     when logits were non-finite.
  ///   - softmaxMax: Softmax-max probability; nil iff `decodedBPM` is nil.
  ///   - softmaxSecondMax: Softmax-second-max probability; nil iff
  ///     `decodedBPM` is nil.
  ///   - inputFeatureChecksum: FNV-1a hash over the post-`vvlogf` feature
  ///     byte stream Swift fed into the conformer (DD #6 cheap-first).
  ///   - failureStage: Categorical abstain-path summary; `nil` on the
  ///     win path. The two pre-featurize stages never construct a
  ///     snapshot (no checksum possible).
  ///   - gateFired: Sub-discriminator for
  ///     ``FailureStage/confidenceGateRejected`` only.
  public init(
    decodedBPM: Double?,
    softmaxMax: Double?,
    softmaxSecondMax: Double?,
    inputFeatureChecksum: UInt64,
    failureStage: FailureStage?,
    gateFired: Gate?
  ) {
    // Pre-featurize abstain paths must NOT construct a snapshot — they
    // have no feature payload to checksum. The conformance returns
    // `(nil, nil)` instead.
    precondition(
      failureStage != .featuresAbsent && failureStage != .featureVersionMismatch,
      "Pre-featurize abstain paths must not construct an MLDiagnosticSnapshot "
        + "(failureStage=\(String(describing: failureStage)))")
    // Decode-field nil/non-nil invariant: softmaxMax and softmaxSecondMax
    // are populated together (both reflect the host-side softmax pass) and
    // are nil together (no logit vector or non-finite logits).
    let decodeFieldsAllNil =
      decodedBPM == nil && softmaxMax == nil && softmaxSecondMax == nil
    let decodeFieldsAllNonNil =
      decodedBPM != nil && softmaxMax != nil && softmaxSecondMax != nil
    precondition(
      decodeFieldsAllNil || decodeFieldsAllNonNil,
      "Decode fields must be all-nil or all-non-nil "
        + "(decodedBPM=\(String(describing: decodedBPM)), "
        + "softmaxMax=\(String(describing: softmaxMax)), "
        + "softmaxSecondMax=\(String(describing: softmaxSecondMax)))")
    switch failureStage {
    case nil:
      // Win path: all decode fields populated, no gate fired.
      precondition(
        decodeFieldsAllNonNil,
        "Win path requires all decode fields populated "
          + "(decodedBPM=\(String(describing: decodedBPM)))")
      precondition(
        gateFired == nil, "Win path must have gateFired == nil")
    case .featurizeRejected, .graphFailed:
      // Pre-decode abstains: decode fields nil, no gate fired.
      precondition(
        decodeFieldsAllNil,
        "\(failureStage!.rawValue) requires all decode fields nil")
      precondition(
        gateFired == nil,
        "\(failureStage!.rawValue) must have gateFired == nil")
    case .decodeRejected:
      // Decode failure: either non-finite logits (all decode fields nil)
      // or out-of-range argmax (all decode fields populated). Both are
      // permitted; gateFired must be nil because the gates have not run.
      precondition(
        gateFired == nil, ".decodeRejected must have gateFired == nil")
    case .confidenceGateRejected:
      // Two-gate abstain: all decode fields populated; gateFired
      // identifies which gate.
      precondition(
        decodeFieldsAllNonNil,
        ".confidenceGateRejected requires all decode fields populated")
      precondition(
        gateFired != nil,
        ".confidenceGateRejected must have non-nil gateFired")
    case .featuresAbsent, .featureVersionMismatch:
      // Handled by the leading precondition. `case` here keeps the switch
      // exhaustive without `@unknown` (closed set per CaseIterable).
      preconditionFailure(
        "unreachable — pre-featurize abstain paths construct no snapshot")
    }
    self.decodedBPM = decodedBPM
    self.softmaxMax = softmaxMax
    self.softmaxSecondMax = softmaxSecondMax
    self.inputFeatureChecksum = inputFeatureChecksum
    self.failureStage = failureStage
    self.gateFired = gateFired
  }

  /// Bounded-length diagnostic representation. Includes
  /// `failureStage?.rawValue ?? "win"` and `decodedBPM` when populated.
  /// Length capped under 200 chars for benchmark-log scanability.
  public var description: String {
    let stageLabel = failureStage?.rawValue ?? "win"
    let bpmField = decodedBPM.map { String(format: "%.2f", $0) } ?? "nil"
    let confField = softmaxMax.map { String(format: "%.3f", $0) } ?? "nil"
    let gateLabel = gateFired?.rawValue ?? "-"
    return
      "MLDiagnosticSnapshot(stage: \(stageLabel), bpm: \(bpmField), "
      + "softmaxMax: \(confField), gate: \(gateLabel), "
      + "checksum: 0x\(String(inputFeatureChecksum, radix: 16)))"
  }
}
