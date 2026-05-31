//
//  TensorLayout.swift
//  BoomBoomBoomKit
//
//  Tensor layout convention for MLFeatureFrames.
//

import Foundation

/// Tensor layout convention for ``MLFeatureFrames``. Story 4.5 ships two
/// cases — ``frameMajorLogMel`` (the on-the-wire layout the
/// ``BPMAnalyzer`` retention path emits) and ``nchw`` (reserved for
/// future producers whose retention path already emits mel-major bytes).
/// ``CaseIterable`` documents the closed set for the gating invariant
/// `TensorLayout.allCases.count == 2`. Pre-1.0 framing per
/// project-context.md "Public API Discipline" — Story 4.6 (CoreML) may
/// extend the case list (e.g., `.nhwc`) when an `MLShapedArray` consumer
/// surfaces a need.
///
/// See `tools/coreml-convert/README.md` for the canonical consumer-onboarding
/// flow (Paths A/B/C: bundled, converted, third-party) and the worked
/// example showing how a custom ``MLTechnique`` conformance reads this
/// layout tag and reshapes accordingly.
public enum TensorLayout: String, Sendable, Hashable, CaseIterable {

  /// Frame-major flat layout — the on-the-wire shape ``BPMAnalyzer``
  /// emits when capturing ``MLFeatureFrames``. Element `[frame * melBands
  /// + mel]` of ``MLFeatureFrames/logMelData``; concatenation of per-frame
  /// `logMelFrames` produces this order naturally. ``BNNSTechnique``
  /// transposes frame-major → mel-major at evaluate time (see
  /// ``BNNSTechnique`` Step 1 of `featurize`).
  ///
  /// Added Story 4-5 review pass (post-code-review 2026-05-13): the
  /// producer was originally tagging this layout as ``nchw``, which was
  /// inaccurate — third-party ``MLTechnique`` consumers reading the
  /// `.nchw` tag would reshape frame-major bytes as mel-major NCHW and
  /// feed transposed features to their models. Pre-1.0 fix introduces
  /// the truthful layout case.
  case frameMajorLogMel
  /// Row-major `[N=1, C=1, H=melBands, W=frames]` layout. Stride is
  /// contiguous: `[H*W, H*W, W, 1]`. Reserved for future producers
  /// (e.g., a CoreML conformance that consumes `MLShapedArray<Float>`
  /// directly) whose retention path emits mel-major bytes; the
  /// ``BNNSTechnique`` consumer reads this layout without transposing.
  case nchw
}
