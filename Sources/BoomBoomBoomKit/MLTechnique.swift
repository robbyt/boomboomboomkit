//
//  MLTechnique.swift
//  BoomBoomBoomKit
//
//  Public MLTechnique protocol + MLEvaluation return type + MLTechniqueError
//  for ML-augmented BPM detection. Relocated from DSPTechnique.swift in
//  Story 4.5 (chunk-4 review, 2026-05-13) so the protocol's home matches its
//  name. The protocol surface is frozen for Story 4.5 per DD #18 — the
//  library ships its bundled BNNSGraph conformance, and consumers may bring
//  their own (BYOW) via `tools/coreml-convert/` and a custom MLTechnique.
//  Pre-1.0 / no-BC framing per project-context.md.
//

import Foundation

// MARK: - MLEvaluation

/// Immutable record of an ML model's tempo estimate, returned by
/// ``MLTechnique/evaluate(trace:)``.
///
/// ``MLEvaluation`` is a pure value type — once constructed it carries one
/// candidate BPM, the model's self-reported confidence, and an optional
/// stable identifier. The ensemble combiner inside
/// ``AudioAnalysisService/analyzeBPM(url:options:)`` consumes this value
/// alongside the DSP-derived ``BPMResult`` to produce the final
/// ``AudioAnalysisResult``. Story 4.3 ships a single-case default policy
/// ("DSP wins regardless"); Story 4.4 introduces the public
/// `EnsemblePolicy` enum that switches on richer combine strategies.
///
/// Conformers (Story 4.5 BNNS, Story 4.6 CoreML) construct an
/// ``MLEvaluation`` only when the model produces a confident estimate;
/// returning `nil` from ``MLTechnique/evaluate(trace:)`` is the documented
/// abstain path.
public struct MLEvaluation: Sendable {

  /// Estimated tempo in beats per minute.
  ///
  /// Conformers should clamp predictions to `60.0...200.0` to match the
  /// DSP pipeline's range-normalized candidate space; out-of-range values
  /// surface to the ensemble combiner unchanged. A value of `0` (or any
  /// non-finite) is undefined and is rejected by future ensemble policies
  /// — return `nil` from ``MLTechnique/evaluate(trace:)`` instead.
  public let bpm: Double

  /// Self-reported confidence in `[0.0, 1.0]`.
  ///
  /// Should be the model's calibrated softmax confidence (or equivalent).
  /// Story 4.4's ensemble policies may down-weight uncalibrated values —
  /// conformers SHOULD calibrate using their training-set held-out scores
  /// rather than emit raw logits.
  public let confidence: Double

  /// Optional stable identifier of the producing model.
  ///
  /// Used for forensic trace tagging when Story 4.5 BNNS and Story 4.6
  /// CoreML conformances coexist (e.g., `"bnns_tempo_v1"`,
  /// `"coreml_resnet18_v3"`). Pass `nil` if the model has no stable
  /// identifier or the consumer does not need to distinguish models.
  public let modelIdentifier: String?

  /// Creates an immutable ML evaluation record.
  ///
  /// - Parameters:
  ///   - bpm: The model's tempo estimate. Conformers should clamp to `60.0...200.0`;
  ///     non-finite values are rejected by the ensemble combiner and treated as a
  ///     sentinel-NaN abstain.
  ///   - confidence: The model's self-reported confidence in `[0.0, 1.0]`.
  ///     Out-of-range and non-finite values are sanitized downstream — see
  ///     ``EnsembleDecision/mlConfidence`` for the contract.
  ///   - modelIdentifier: Optional stable tag for forensic logs when multiple
  ///     conformers coexist. Defaults to `nil`.
  public init(bpm: Double, confidence: Double, modelIdentifier: String? = nil) {
    self.bpm = bpm
    self.confidence = confidence
    self.modelIdentifier = modelIdentifier
  }
}

// MARK: - MLTechnique

/// Extension point for ML-augmented BPM estimation. The library invokes
/// conformers AFTER the DSP pipeline and AFTER metadata corroboration; the
/// result is consumed by the ensemble combiner per the user's selected
/// `EnsemblePolicy`. Story 4.5 ships ``BNNSTechnique`` as the default
/// implementation; consumers may bring their own conformance via
/// `Options.mlTechnique = MyCustomMLTechnique()`.
///
/// ## Pre-1.0 framing
///
/// The protocol surface is frozen at Story 4.5 close-out: parameters and
/// return type are stable for the rest of the pre-release window. Future
/// stories may add fields to ``MLEvaluation`` and extend trace surfaces,
/// but the `evaluate(trace:)` signature itself is the consumer-facing
/// contract.
///
/// ## Consumer onboarding (Story 4-4b BYOW)
///
/// Consumers wanting to plug their own tempo model into BoomBoomBoomKit can:
///
/// 1. Convert PyTorch / Core ML weights via `tools/coreml-convert/convert.py`
///    targeting the bundled tensor contract (`input` shape `[1,1,128,512]`,
///    `output` shape `[1, 256]`).
/// 2. Pass the resulting `.mlmodelc` to ``BNNSTechnique/init(modelURL:)``:
///    `Options.mlTechnique = try? BNNSTechnique(modelURL: myURL)`.
/// 3. Or implement a custom ``MLTechnique`` from scratch and assign it to
///    `Options.mlTechnique` directly — any backend works.
///
/// See `tools/coreml-convert/README.md` for the full onboarding flow.
public protocol MLTechnique: Sendable {

  /// Evaluates a candidate set against an ML model using features captured
  /// in the trace.
  ///
  /// - Parameter trace: The diagnostic trace from the just-completed merge
  ///   step. May contain ``BPMDiagnosticTrace/mlFeatures`` populated when
  ///   the library's internal `captureMLFeatures` flag was true upstream
  ///   (which the service sets when both `Options.mlTechnique != nil` and
  ///   `Options.ensemblePolicy != .dspOnly`).
  /// - Returns: An ``MLEvaluation`` when the model produced a confident
  ///   prediction; `nil` when the model abstained (low confidence, missing
  ///   features, or out-of-distribution input). Conformers SHOULD return
  ///   `nil` rather than a low-confidence ``MLEvaluation`` when the
  ///   prediction would not improve on DSP-only candidate scoring.
  /// - Note: The library currently invokes this method at most ONCE per
  ///   `analyzeBPM(url:options:)` call, on the merged-winner trace (Story
  ///   4-5 DD #17). Implementations MUST still be thread-safe — a future
  ///   intensity that fans out per-window evaluation via `withTaskGroup`
  ///   could invoke this method concurrently, and the protocol contract
  ///   already promises it. Backend conformers wrapping non-Sendable
  ///   underlying types (e.g., `MLModel` from Core ML) should declare
  ///   `@unchecked Sendable` with a documented rationale.
  /// - Note: This protocol is backend-agnostic. Conformers may use
  ///   BNNSGraph (CPU-only, low-latency), Core ML (CPU+ANE eligible),
  ///   MLX (Apple Silicon), MPS Graph, or pure Swift inference. The
  ///   library does not constrain the choice.
  func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation?
}

// MARK: - MLTechniqueError

/// Failures that an ``MLTechnique`` conformer's initializer may throw.
///
/// The four cases cover the documented failure surface for
/// ``BNNSTechnique/init(modelURL:)``; custom conformers SHOULD reuse them
/// for symmetry with the bundled implementation, but are free to define
/// their own error types if more granular reporting is needed.
///
/// Per the protocol contract, ``MLTechnique/evaluate(trace:)`` itself does
/// NOT throw — the abstain path is `nil`. Errors here describe construction
/// failures only.
public enum MLTechniqueError: Error, Sendable {

  /// The model resource at the supplied URL does not exist. For the
  /// bundled ``BNNSTechnique`` path, this fires when
  /// `Bundle.module.url(forResource:withExtension:)` returns `nil`; for
  /// consumer-supplied URLs, it fires when the path is unreadable.
  case modelResourceMissing(URL)

  /// The underlying ML framework rejected the model. For the bundled
  /// ``BNNSTechnique``, this wraps `BNNSGraphCompileFromFile` returning an
  /// empty `bnns_graph_t`. The underlying error is preserved for
  /// diagnostics; consumers SHOULD log it but generally cannot recover
  /// from it programmatically.
  case modelLoadFailed(underlying: any Error)

  /// The model's tensor contract does not match what the library expects.
  /// For the bundled ``BNNSTechnique``, this fires when
  /// `BNNSGraphGetArgumentPosition(graph, nil, name)` returns the failure
  /// sentinel for either `"input"` or `"output"`. `missing` names the
  /// argument that could not be resolved.
  case invalidTensorContract(missing: String)

  /// The model's output bin count does not match the library's BPM bin
  /// decode contract (256 bins → `bpm = 30.0 + Double(argmax)` per DD #18).
  /// Consumers shipping a different bin count must implement a custom
  /// ``MLTechnique`` conformance that decodes their own bin centers.
  case binCountMismatch(expected: Int, actual: Int)

  /// A typed-evidence payload (``MLFeatureFrames``) was constructed with
  /// dimensions outside the library's accepted range. Fires from the
  /// throwing init when `melBands <= 0`, `frames <= 0`, `logMelData.count
  /// != melBands * frames`, or the total payload exceeds the size cap
  /// (≈32 MB; defends against accidental construction of arbitrarily-
  /// large `[Float]` payloads on a public Sendable type). `reason`
  /// describes which invariant fired.
  ///
  /// Producer-side this is converted to abstain (`mlFeatures = nil`) via
  /// `try?` — an oversized feature payload routes through the standard
  /// "model can't see features" path rather than crashing the host app.
  /// Consumer-side `MLTechnique` conformances see no special signaling;
  /// `trace.mlFeatures` is simply `nil`.
  case invalidFeatureShape(reason: String)
}
