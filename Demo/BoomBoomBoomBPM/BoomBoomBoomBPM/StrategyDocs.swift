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
