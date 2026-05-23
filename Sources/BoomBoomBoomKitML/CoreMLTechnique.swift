//
//  CoreMLTechnique.swift
//  BoomBoomBoomKit
//
//  Non-conforming placeholder type — does NOT adopt `MLTechnique`.
//  Retained so `BoomBoomBoomKitML`'s `Bundle.module` symbol resolves
//  and so the public-API surface remains stable. Use `BNNSTechnique`
//  (same module) for ML augmentation today.
//

import CoreML

/// Non-conforming placeholder type. **Does NOT adopt `MLTechnique`** and
/// therefore cannot be assigned to ``AudioAnalysisService/Options/mlTechnique``.
///
/// The production ML conformer is ``BNNSTechnique`` (same module) — load a
/// `.mlmodelc` via `BNNSTechnique(modelURL:)` and assign that to
/// `Options.mlTechnique`. See [MODEL_CARD.md](../../MODEL_CARD.md) and
/// [tools/coreml-convert/](../../tools/coreml-convert/) for the BYOW
/// (bring-your-own-weights) flow.
///
/// This type exists only so this module compiles and exposes a public
/// symbol the package layout depends on. Re-introducing a CoreML-backed
/// `MLTechnique` conformer is a future-epic concern with no scheduled
/// story; if/when it returns, it will likely be a new type, not a
/// retroactive conformance on this one.
public struct CoreMLTechnique: Sendable {
  /// Creates an empty placeholder value. Construction is supported only so this
  /// type's public symbol resolves; the resulting value has no functional use —
  /// in particular it cannot be assigned to ``AudioAnalysisService/Options/mlTechnique``
  /// because ``CoreMLTechnique`` does not adopt ``MLTechnique``.
  public init() {}
}
