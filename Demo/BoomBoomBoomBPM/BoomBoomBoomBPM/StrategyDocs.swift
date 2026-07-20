import BoomBoomBoomKit

// MARK: - MergeStrategyDoc

// Demo-owned adapter bridging a `BPMSelectionPolicy` case to its authored docs
// (Story 11.6). The library enum is NEVER conformed to `DemoDocumentedCase`
// (KDD-E1) — this value type wraps it and reuses the single-source demo copy
// (`AnalysisViewModel.strategyDescription` / `.humanize`, both `nonisolated`) so
// the "?" tooltip + heading never drift from the inline Picker caption.
//
// `nonisolated struct` so off-actor logic tests read its derivations under the
// demo target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` default (precedent:
// `nonisolated struct SignalPoolDiagnosticRow`).
nonisolated struct MergeStrategyDoc: DemoDocumentedCase {
  let policy: BPMSelectionPolicy

  init(_ policy: BPMSelectionPolicy) {
    self.policy = policy
  }

  // Sourced from the library's own DocumentedCase keys (not a hardcoded literal)
  // so the demo's docID cannot drift from the resource path the accessor reads.
  var kind: String { BPMSelectionPolicy.documentedKind }

  var id: String { policy.documentationID }

  var shortDescription: String { AnalysisViewModel.strategyDescription(policy) }

  var controlName: String { "Merge strategy" }

  // Humanized + first-letter-capitalized: "maxConfidence" -> "max confidence"
  // (humanize) -> "Max confidence".
  var displayName: String {
    let humanized = AnalysisViewModel.humanize(policy)
    guard let first = humanized.first else { return humanized }
    return first.uppercased() + humanized.dropFirst()
  }
}

// MARK: - IntensityDoc

// Demo-owned adapter bridging an `AnalysisIntensity` level to its authored
// per-level docs (`AnalysisIntensity/level<N>.md`). Same pattern as
// `MergeStrategyDoc`: the library type is never conformed to
// `DemoDocumentedCase`; this value type wraps it and carries only the library
// `(kind, id)` doc keys so the popover content changes per level.
//
// `nonisolated struct` so the off-actor `HelpButtonLogicTests` read its
// derivations. `AnalysisIntensity` is a library type (already nonisolated).
nonisolated struct IntensityDoc: DemoDocumentedCase {
  let intensity: AnalysisIntensity

  init(_ intensity: AnalysisIntensity) {
    self.intensity = intensity
  }

  // Library-derived keys (never a hardcoded id): `documentationID` is the
  // `"level<N>"` rawValue, `documentedKind` is `"AnalysisIntensity"`.
  var kind: String { AnalysisIntensity.documentedKind }

  var id: String { intensity.documentationID }

  var shortDescription: String { "Analysis intensity level \(intensity.level) of 10." }

  var controlName: String { "Intensity" }

  // Mirrors the on-screen slider label: the level number plus the named-alias
  // suffix. Shares `aliasSuffix(for:)` with `ContentView.intensityLabelText` so
  // the slider label and the popover heading cannot drift apart.
  var displayName: String {
    "Level \(intensity.level)\(Self.aliasSuffix(for: intensity))"
  }

  // The named-alias suffix, derived from the library's own intensity constants
  // (`.fastest`/`.default`/`.thorough`/`.maximum`) via expression-pattern
  // equality, so a future re-map of an alias to a different level moves the
  // label and heading together instead of silently diverging from the doc.
  static func aliasSuffix(for intensity: AnalysisIntensity) -> String {
    switch intensity {
    case .fastest: return " (fastest)"
    case .default: return " (default)"
    case .thorough: return " (thorough)"
    case .maximum: return " (maximum)"
    default: return ""
    }
  }
}

// MARK: - EnsembleDoc

// Demo-owned adapter bridging the demo's `EnsemblePreset` to the authored
// `EnsemblePolicy` docs. The doc id is the resolved policy's own
// `documentationID` (`stableKey`), so `mlAugmented` and `trustFileTags` (both
// `.weightedVoting`) intentionally share the single `weightedVoting.md` doc;
// the picker's per-preset subtitle line disambiguates the two weightings.
//
// `nonisolated struct` so the off-actor logic tests read it — this is why
// `EnsemblePreset` itself is `nonisolated` (its derivations are pure).
nonisolated struct EnsembleDoc: DemoDocumentedCase {
  let preset: EnsemblePreset

  init(_ preset: EnsemblePreset) {
    self.preset = preset
  }

  var kind: String { EnsemblePolicy.documentedKind }

  // Derived from the resolved library policy, never a hardcoded id map.
  var id: String { preset.policy.documentationID }

  var shortDescription: String { preset.subtitle }

  var controlName: String { "Ensemble" }

  var displayName: String { preset.displayName }
}
