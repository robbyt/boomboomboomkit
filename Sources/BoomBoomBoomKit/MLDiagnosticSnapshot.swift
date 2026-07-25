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
//  This file holds the public typed-evidence struct + its nested `Decode`
//  payload and `Outcome` / `FailureStage` / `Gate` enums. The capability
//  protocol that produces this snapshot lives in the sibling
//  `MLDiagnosticTechnique.swift`; the trace field that carries it lives on
//  `BPMDiagnosticTrace`.
//

import Foundation

// MARK: - MLDiagnosticSnapshot

/// Per-evaluation diagnostic snapshot emitted by ``MLDiagnosticTechnique``
/// conformers (Story 4-6's ``BNNSTechnique`` adopts the protocol; consumer
/// `MLTechnique` types may opt in by adding the conformance).
///
/// Populated on the trace via ``BPMDiagnosticTrace/mlDiagnosticSnapshot``
/// when ML is active AND the inference reached at least the featurize step.
/// The two pre-featurize abstains — features absent, or feature-set version
/// drift — construct no snapshot at all: ``inputFeatureChecksum`` is
/// non-optional and those paths have no feature payload to checksum. The
/// conformance returns `(nil, nil)` from
/// ``MLDiagnosticTechnique/evaluateWithDiagnostic(trace:)`` and a reporting
/// harness that needs those buckets derives them from trace-state
/// inspection, in its own taxonomy rather than this one.
///
/// ## Shape
///
/// A snapshot is a checksum plus exactly one ``Outcome``. Every
/// field-population rule is carried by the outcome's associated values, so
/// a contradictory snapshot — a gate that fired with no decoded tempo, a
/// win with no probabilities — does not compile. There is nothing to
/// validate at construction and nothing that can trap.
///
/// ``decodedBPM``, ``softmaxMax``, ``softmaxSecondMax``, ``failureStage``
/// and ``gateFired`` remain available as computed projections for readers
/// that want the flat view.
///
/// ## What BNNSTechnique emits
///
/// This describes the reference conformer's control flow. It is
/// documentation of one producer, NOT a contract imposed on consumer
/// conformers — a different backend with different stages is free to emit
/// any outcome it likes.
///
/// | Path | Outcome |
/// |------|---------|
/// | `evaluate(trace:)` returned non-nil | ``Outcome/win(_:)`` |
/// | featurize returned nil | ``Outcome/featurizeRejected`` |
/// | graph context build / execute error | ``Outcome/graphFailed`` |
/// | logits non-finite | ``Outcome/decodeRejectedNonFinite`` |
/// | argmax mapped outside `60...200` | ``Outcome/decodeRejectedOutOfRange(_:)`` carrying the raw out-of-range tempo |
/// | two-gate abstain | ``Outcome/confidenceGateRejected(_:gate:)`` |
///
/// At investigation-time thresholds `0.0`/`0.0`, decode evidence populates
/// even on paths that would otherwise abstain — that is the point:
/// snapshot evidence survives gate disablement, so a threshold sweep can
/// answer "is the model producing useful predictions or not?".
///
/// ## Pre-1.0 framing
///
/// Per project-context.md "Public API Discipline (pre-1.0)", this struct
/// is NOT 1.0-stable. Future stories may add outcomes, add fields to
/// ``Decode``, or rename members entirely. No backwards compatibility is
/// promised in pre-release.
///
/// ## See also
///
/// - ``MLDiagnosticTechnique`` — capability protocol that produces the snapshot.
/// - ``BPMDiagnosticTrace/mlDiagnosticSnapshot`` — trace field that carries it.
/// - ``BNNSTechnique`` — Story 4-6's reference conformer.
public struct MLDiagnosticSnapshot: Sendable, Hashable, CustomStringConvertible {

  /// Cheap drift-detector: stable hash of the payload the conformer
  /// actually fed its model on this call. FNV-1a over the `Float` byte
  /// representation; cost ~50µs per evaluate, dwarfed by inference, and
  /// deterministic given the same audio. The Python reference pipeline
  /// at `_bmad-output/ml-training/` can emit the same checksum for the
  /// same fixture WAV; if they diverge, that IS the featurize bug (DD #6
  /// cheap-first methodology).
  ///
  /// **Which bytes** depends on how far the call got, so compare like
  /// with like. ``BNNSTechnique`` hashes its post-featurize tensor — the
  /// transposed, z-scored, resampled `[1, 1, 128, 512]` input — on every
  /// path that reaches inference. Only on ``Outcome/featurizeRejected``,
  /// where no tensor exists, does it fall back to hashing the source
  /// log-mel payload. A parity harness reproducing the normal-inference
  /// checksum must therefore replicate featurize, not just the log-mel
  /// stage.
  ///
  /// Non-optional by design: a snapshot exists only once there are
  /// features to checksum. That is what makes the two pre-featurize
  /// abstains unrepresentable here rather than merely discouraged.
  public let inputFeatureChecksum: UInt64

  /// Which path this evaluation took, carrying whatever numeric evidence
  /// that path produces.
  public let outcome: Outcome

  /// Constructs a snapshot. Total — every combination of arguments is a
  /// legal snapshot, so this can neither trap nor throw.
  ///
  /// Contrast ``MLFeatureFrames``, whose throwing init guards invariants
  /// that are load-bearing: its dimensions size buffers handed to
  /// Accelerate as raw pointers, so a mismatched count reads out of
  /// bounds. Nothing indexes a snapshot — it is descriptive telemetry,
  /// and the library is not the arbiter of a foreign conformer's
  /// diagnostic shape.
  ///
  /// - Parameters:
  ///   - inputFeatureChecksum: FNV-1a hash over the payload the conformer
  ///     fed its model — see ``inputFeatureChecksum`` for which bytes.
  ///   - outcome: The path taken, with its numeric evidence.
  public init(inputFeatureChecksum: UInt64, outcome: Outcome) {
    self.inputFeatureChecksum = inputFeatureChecksum
    self.outcome = outcome
  }

  // MARK: - Decode

  /// The three decode values that are only ever produced together: a
  /// host-side softmax pass yields both probabilities, and the argmax
  /// over the same logit vector yields the tempo.
  ///
  /// Grouping them is what makes a partially-populated decode
  /// unrepresentable. Previously these were three sibling `Double?`
  /// fields whose all-nil-or-all-non-nil rule had to be enforced at
  /// runtime.
  public struct Decode: Sendable, Hashable {

    /// Argmax-derived BPM. On ``Outcome/decodeRejectedOutOfRange(_:)``
    /// this is the raw out-of-range value — the snapshot reports what the
    /// model said, not what the library would have accepted (DD #2).
    public let bpm: Double

    /// Softmax-max probability after host-side softmax. Range
    /// `[0.0, 1.0]` as emitted by ``BNNSTechnique``, which clamps for
    /// public-API stability (Story 4-4 DD #4 precedent). Not enforced
    /// here — a foreign conformer reports its own values.
    public let softmaxMax: Double

    /// Softmax-second-max probability after host-side softmax.
    public let softmaxSecondMax: Double

    public init(bpm: Double, softmaxMax: Double, softmaxSecondMax: Double) {
      self.bpm = bpm
      self.softmaxMax = softmaxMax
      self.softmaxSecondMax = softmaxSecondMax
    }
  }

  // MARK: - Outcome

  /// The path an evaluation took. Payload-carrying, so each case admits
  /// exactly the evidence that path can produce.
  ///
  /// Not `CaseIterable` — associated values make synthesis impossible.
  /// ``FailureStage`` is the flat, `CaseIterable`, raw-value-bearing
  /// projection for histogram and export use.
  public enum Outcome: Sendable, Hashable {

    /// `evaluate(trace:)` returned a non-nil ``MLEvaluation``.
    case win(Decode)

    /// The conformer's featurize step returned nil (short clip, mel-band
    /// mismatch, unhandled layout). No logit vector was produced.
    case featurizeRejected

    /// Graph context build / execute / workspace error. No logit vector
    /// was produced.
    case graphFailed

    /// The logit vector contained non-finite values, so no argmax could
    /// be computed.
    case decodeRejectedNonFinite

    /// Argmax mapped to a BPM outside `60.0...200.0`. Carries the raw
    /// out-of-range decode.
    case decodeRejectedOutOfRange(Decode)

    /// Two-gate abstain fired. Carries the decode that was rejected and
    /// identifies which gate rejected it.
    case confidenceGateRejected(Decode, gate: Gate)
  }

  // MARK: - Flat projections

  /// Decode evidence, when the path produced any.
  public var decode: Decode? {
    switch outcome {
    case .win(let d), .decodeRejectedOutOfRange(let d), .confidenceGateRejected(let d, _):
      return d
    case .featurizeRejected, .graphFailed, .decodeRejectedNonFinite:
      return nil
    }
  }

  /// Argmax-derived BPM, or nil when no logit vector was decoded.
  public var decodedBPM: Double? { decode?.bpm }

  /// Softmax-max probability, or nil when no logit vector was decoded.
  public var softmaxMax: Double? { decode?.softmaxMax }

  /// Softmax-second-max probability, or nil when no logit vector was decoded.
  public var softmaxSecondMax: Double? { decode?.softmaxSecondMax }

  /// Categorical view of ``outcome``, `nil` on the win path. Use this for
  /// histogram reporting and stable string export; the numeric evidence in
  /// ``decode`` is what actually diagnoses a failure.
  ///
  /// Both decode-rejection outcomes collapse to
  /// ``FailureStage/decodeRejected`` — they differ in the evidence they
  /// carry, not in the stage that rejected them.
  public var failureStage: FailureStage? {
    switch outcome {
    case .win: return nil
    case .featurizeRejected: return .featurizeRejected
    case .graphFailed: return .graphFailed
    case .decodeRejectedNonFinite, .decodeRejectedOutOfRange: return .decodeRejected
    case .confidenceGateRejected: return .confidenceGateRejected
    }
  }

  /// Which abstain gate fired, or nil when the outcome was not a gate
  /// rejection.
  public var gateFired: Gate? {
    switch outcome {
    case .confidenceGateRejected(_, let gate): return gate
    case .win, .featurizeRejected, .graphFailed, .decodeRejectedNonFinite,
      .decodeRejectedOutOfRange:
      return nil
    }
  }

  // MARK: - FailureStage

  /// Flat abstain-path taxonomy: the stages a snapshot can represent.
  ///
  /// Four cases, one per stage that can reject an evaluation once
  /// features exist. `featuresAbsent` and `featureVersionMismatch` are
  /// deliberately absent — those are whole-evaluation outcomes that
  /// produce no snapshot at all, so a taxonomy of snapshot-representable
  /// stages cannot include them. A reporting harness that needs those
  /// buckets owns its own key type.
  ///
  /// `inferenceFailed` was split into ``graphFailed`` + ``decodeRejected``
  /// per Codex finding #2: "graph failed", "softmax became non-finite",
  /// and "decoded argmax mapped outside 60…200" point to different
  /// remediation paths — folding them into one bucket loses diagnostic
  /// information.
  public enum FailureStage: String, Sendable, Hashable, CaseIterable {

    /// The conformer's featurize step returned nil.
    case featurizeRejected

    /// BNNSGraph context build / execute / workspace error.
    case graphFailed

    /// Logit decode produced non-finite values, or argmax mapped to a BPM
    /// outside `60.0...200.0`. Inspect ``MLDiagnosticSnapshot/decode`` to
    /// tell the two apart: the out-of-range case carries evidence, the
    /// non-finite case cannot.
    case decodeRejected

    /// Two-gate abstain fired; see ``MLDiagnosticSnapshot/gateFired``.
    case confidenceGateRejected
  }

  // MARK: - Gate

  /// Two-gate sub-discriminator for
  /// ``Outcome/confidenceGateRejected(_:gate:)``.
  public enum Gate: String, Sendable, Hashable, CaseIterable {
    /// Softmax-max below the technique's `confidenceThreshold`.
    case gate1Softmax
    /// Margin between the top-2 softmax probabilities below the
    /// technique's `marginThreshold`.
    case gate2Margin
  }

  // MARK: - CustomStringConvertible

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
