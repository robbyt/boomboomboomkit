//
//  BNNSTechnique.swift
//  BoomBoomBoomKit
//
//  Placeholder for the BNNSGraph-backed MLTechnique conformance (Story 4.5).
//

import Accelerate

/// Placeholder for the BNNSGraph-backed `MLTechnique` conformance.
///
/// Story 4.5 wires this to `BNNSGraphCompileFromFile` reading
/// `Bundle.module.url(forResource: "giantsteps_v1", withExtension: "mlmodelc")`
/// — `Bundle.module` resolves to `BoomBoomBoomKitML`'s bundle, NEVER
/// `BoomBoomBoomKit`'s (which does not exist; the core target has no
/// `resources:` declaration). The resource name was renamed from the original
/// `tempo_classifier.mlmodelc` placeholder to `giantsteps_v1.mlmodelc` during
/// Story 4-4b party-mode review (matches the bundled artifact in
/// `Sources/BoomBoomBoomKitML/Resources/`). Story 4.5 also adds `MLTechnique`
/// conformance against the post-Story-4.3 protocol shape (`MLEvaluation`
/// Sendable struct return, `BPMDiagnosticTrace` input).
///
/// Story 4.1 ships only the type stub so the package compiles and the
/// `BoomBoomBoomKitML` target's `Bundle.module` symbol resolves.
///
/// **Pre-1.0 / no-BC notice:** Story 4.5 will change `init()` to
/// `init() throws` when adding model load (per ADR-4). This signature
/// change is pre-authorized — no deprecation cycle required.
public struct BNNSTechnique: Sendable {
  public init() {}
}
