import BoomBoomBoomKit
import SwiftUI

// MARK: - Row model

// One display row of the signal-pool diagnostic table (Story 9.2 / FR-41).
// Flattened from a `SignalParticipationTraceEntry` plus its embedded
// `WeightedSignal`; `Identifiable` by the original trace-entry index so the
// `Table` keeps stable identity across re-sorts.
//
// The `*Display` fields are the finite-guarded strings shown in cells; the
// `*SortKey` fields are the values the `TableColumn(value:)` comparators bind
// (a raw `Double?`/`NaN` is a poor sort key — see `SignalPoolDiagnostics`).
//
// `nonisolated` (like the derivation namespace): the demo defaults to `MainActor`
// isolation, but the row is a pure value read by both the off-actor unit tests
// and the `TableColumn` keypaths — neither of which may touch actor-isolated state.
nonisolated struct SignalPoolDiagnosticRow: Identifiable {
  let id: Int
  let source: String
  let bpmDisplay: String
  let bpmSortKey: Double
  let confidenceDisplay: String
  let confidenceSortKey: Double
  let weightDisplay: String
  let weightSortKey: Double
  let contributionDisplay: String
  let contributionSortKey: Double
  // 0 = winning cluster, 1 = off-cluster candidate, 2 = non-voter (no signal).
  let clusterRank: Int
  let clusterLabel: String
  let isWinningCluster: Bool
  let isWinner: Bool
  let participationKind: String
}

// MARK: - Pure derivation

// `nonisolated` because the demo target defaults to `MainActor` isolation
// (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), but this is pure value logic
// with no shared mutable state — mirrors `nonisolated enum Waveform`, and keeps
// the unit tests off the main actor.
nonisolated enum SignalPoolDiagnostics {

  // Winning-cluster membership tolerance around the selected BPM. Absolute, not
  // octave-folded: this is a demo audit table, not a library octave resolver.
  static let clusterToleranceBPM = 0.5

  // Non-finite / missing values map here so `KeyPathComparator` ordering stays
  // total and deterministic (they sink to the bottom of a descending sort).
  static let missingSortKey = -Double.greatestFiniteMagnitude

  private struct Intermediate {
    let index: Int
    let source: SignalSource
    let bpm: Double?
    let confidence: Double
    let weight: Double
    let contribution: Double
    let clusterRank: Int
    let participationKind: String
  }

  /// The sole flatten + derive + winner-selection site. Given the library's
  /// per-source participation entries, the run's selected BPM, and the weighted
  /// ensemble winner (nil under a policy that emits no resolution, e.g.
  /// `.dspOnly`), returns one display row per entry with cluster and winner
  /// annotations derived (there is no cluster field on the trace).
  static func rows(
    from entries: [SignalParticipationTraceEntry],
    selectedBPM: Double,
    winner: EnsembleWeightResolution.Winner?
  ) -> [SignalPoolDiagnosticRow] {
    let intermediate = entries.enumerated().map { index, entry -> Intermediate in
      let bpm = bpm(of: entry.participation)
      let hasSignal = bpm != nil
      let clusterRank: Int
      if let bpm, bpm.isFinite, abs(bpm - selectedBPM) <= clusterToleranceBPM {
        clusterRank = 0
      } else if hasSignal {
        clusterRank = 1
      } else {
        clusterRank = 2
      }
      return Intermediate(
        index: index,
        source: entry.source,
        bpm: bpm,
        confidence: entry.participation.confidence,
        weight: entry.weight,
        contribution: entry.contribution,
        clusterRank: clusterRank,
        participationKind: participationKind(entry.participation))
    }

    let winnerIndex = winnerIndex(among: intermediate, selectedBPM: selectedBPM, winner: winner)

    return intermediate.map { row in
      SignalPoolDiagnosticRow(
        id: row.index,
        source: row.source.rawValue,
        bpmDisplay: bpmDisplay(row.bpm),
        bpmSortKey: sortKey(row.bpm),
        confidenceDisplay: floatDisplay(row.confidence, digits: 4),
        confidenceSortKey: finiteOr(row.confidence, missingSortKey),
        weightDisplay: floatDisplay(row.weight, digits: 3),
        weightSortKey: finiteOr(row.weight, missingSortKey),
        contributionDisplay: floatDisplay(row.contribution, digits: 4),
        contributionSortKey: finiteOr(row.contribution, missingSortKey),
        clusterRank: row.clusterRank,
        clusterLabel: clusterLabel(row.clusterRank),
        isWinningCluster: row.clusterRank == 0,
        isWinner: row.index == winnerIndex,
        participationKind: row.participationKind)
    }
  }

  // MARK: Winner selection (order-sensitive → exactly one badge)

  private static func winnerIndex(
    among rows: [Intermediate],
    selectedBPM: Double,
    winner: EnsembleWeightResolution.Winner?
  ) -> Int? {
    // The library's authoritative source: `.dsp`/`.tie` → DSP (the combiner's
    // deterministic DSP-wins tiebreak); `.ml` → ML; `nil` (no weighted
    // resolution — e.g. `.dspOnly`) → DSP, because file metadata only
    // re-weights the pool, it is never the selected candidate.
    //
    // Restrict the badge to that source and do NOT fall back to another source.
    // `signalParticipationTrace` is built inside `select()` BEFORE ML inference,
    // so the pool's `.ml` entry is always `.abstained` (no BPM, never rank 0).
    // An `.ml` winner therefore correctly yields NO badge — the row it won on
    // isn't in this pre-ML trace — rather than mis-badging a DSP row while the
    // summary line reads "Winner: ml". Likewise a corroborating file-metadata
    // tag (confidence 1.0) can no longer steal the badge from the DSP result.
    let winnerSource: SignalSource
    switch winner {
    case .dsp, .tie, nil: winnerSource = .dsp
    case .ml: winnerSource = .ml
    }
    let candidates = rows.filter { $0.clusterRank == 0 && $0.source == winnerSource }
    guard !candidates.isEmpty else { return nil }

    // Total order: greatest contribution, then smallest |bpm − selected|, then
    // smallest original index. `max(by:)` returns the single greatest element.
    return candidates.max { lhs, rhs in
      let lc = finiteOr(lhs.contribution, missingSortKey)
      let rc = finiteOr(rhs.contribution, missingSortKey)
      if lc != rc { return lc < rc }
      let ld = delta(lhs.bpm, selectedBPM)
      let rd = delta(rhs.bpm, selectedBPM)
      if ld != rd { return ld > rd }
      return lhs.index > rhs.index
    }?.index
  }

  // MARK: Helpers

  private static func bpm(of participation: SignalParticipation) -> Double? {
    switch participation {
    case .present(let signal), .demoted(let signal, _):
      return signal.bpm
    case .absent, .abstained:
      return nil
    }
  }

  private static func participationKind(_ participation: SignalParticipation) -> String {
    switch participation {
    case .present:
      return "present"
    case .demoted(_, let reason):
      return "demoted: \(demotionLabel(reason))"
    case .abstained(let reason):
      return "abstained: \(abstainLabel(reason))"
    case .absent:
      return "absent"
    }
  }

  private static func abstainLabel(_ reason: AbstainReason) -> String {
    switch reason {
    case .policyDisabled: return "policy-disabled"
    case .inputBelowMinimum: return "input-below-minimum"
    case .confidenceBelowFloor: return "confidence-below-floor"
    case .sourceSpecific(let value): return value
    }
  }

  private static func demotionLabel(_ reason: DemotionReason) -> String {
    switch reason {
    case .implausibleForContext: return "implausible-for-context"
    case .sourceSpecific(let value): return value
    }
  }

  private static func clusterLabel(_ rank: Int) -> String {
    switch rank {
    case 0: return "Winner"
    case 1: return "Rejected"
    default: return "—"
    }
  }

  // Absolute distance to the selected BPM; ∞ when the value is missing/non-finite
  // so a real match always sorts ahead of an unusable one.
  private static func delta(_ bpm: Double?, _ selectedBPM: Double) -> Double {
    guard let bpm, bpm.isFinite, selectedBPM.isFinite else { return .greatestFiniteMagnitude }
    return abs(bpm - selectedBPM)
  }

  private static func sortKey(_ bpm: Double?) -> Double {
    guard let bpm, bpm.isFinite else { return missingSortKey }
    return bpm
  }

  static func finiteOr(_ value: Double, _ fallback: Double) -> Double {
    value.isFinite ? value : fallback
  }

  static func bpmDisplay(_ bpm: Double?) -> String {
    guard let bpm, bpm.isFinite else { return "—" }
    return String(format: "%.2f", bpm)
  }

  static func floatDisplay(_ value: Double, digits: Int) -> String {
    value.isFinite ? String(format: "%.\(digits)f", value) : "—"
  }
}

// MARK: - Table view

// Read-only, sortable signal-pool diagnostic table (FR-41 / KDD-D5). Six
// columns; winning-cluster rows are accent-tinted per-cell and the decisive row
// carries a leading badge. Lives inside the advanced sidebar's `TraceView`.
struct SignalPoolDiagnosticTable: View {
  let entries: [SignalParticipationTraceEntry]
  let resolution: EnsembleWeightResolution?
  let selectedBPM: Double

  // Starts empty (a `KeyPathComparator` in a stored `@State` default is
  // non-Sendable under Swift 6 strict concurrency). The `sortOrder` binding only
  // RECORDS header taps — a SwiftUI `Table` does not auto-sort. Until the user
  // taps a column, `sortedRows` applies the default grouping (winning cluster
  // first, then contribution descending); a tap replaces it per AC3.
  @State private var sortOrder: [KeyPathComparator<SignalPoolDiagnosticRow>] = []

  private var sortedRows: [SignalPoolDiagnosticRow] {
    let rows = SignalPoolDiagnostics.rows(
      from: entries,
      selectedBPM: selectedBPM,
      winner: resolution?.winner)
    guard !sortOrder.isEmpty else {
      return rows.sorted { lhs, rhs in
        if lhs.clusterRank != rhs.clusterRank { return lhs.clusterRank < rhs.clusterRank }
        if lhs.contributionSortKey != rhs.contributionSortKey {
          return lhs.contributionSortKey > rhs.contributionSortKey
        }
        // Original trace index — a total order so equal-contribution rows have a
        // deterministic order (Swift's `sorted` is not stable).
        return lhs.id < rhs.id
      }
    }
    return rows.sorted(using: sortOrder)
  }

  var body: some View {
    if entries.isEmpty {
      Text("Enable diagnostic trace in advanced settings")
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        if let resolution {
          resolutionSummary(resolution)
        }
        Table(sortedRows, sortOrder: $sortOrder) {
          TableColumn("Source", value: \.source) { row in
            tinted(row) {
              HStack(spacing: 4) {
                if row.isWinner {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("winning signal")
                }
                Text(row.source)
              }
            }
          }
          TableColumn("BPM", value: \.bpmSortKey) { row in
            tinted(row) { Text(row.bpmDisplay).monospacedDigit() }
          }
          TableColumn("Confidence", value: \.confidenceSortKey) { row in
            tinted(row) { Text(row.confidenceDisplay).monospacedDigit() }
          }
          TableColumn("Weight", value: \.weightSortKey) { row in
            tinted(row) { Text(row.weightDisplay).monospacedDigit() }
          }
          TableColumn("Contribution", value: \.contributionSortKey) { row in
            tinted(row) { Text(row.contributionDisplay).monospacedDigit() }
          }
          TableColumn("Cluster", value: \.clusterRank) { row in
            tinted(row) { Text(row.clusterLabel) }
          }
        }
        .frame(minHeight: 160, idealHeight: 240, maxHeight: 340)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // Per-cell accent tint (a plain `Table` has no dependable row-level background;
  // `TableRow` is not a `View`). Fills the cell width so the winning cluster
  // reads as a tinted band across the row.
  @ViewBuilder
  private func tinted(
    _ row: SignalPoolDiagnosticRow,
    @ViewBuilder _ content: () -> some View
  ) -> some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(row.isWinningCluster ? Color.accentColor.opacity(0.12) : Color.clear)
  }

  @ViewBuilder
  private func resolutionSummary(_ resolution: EnsembleWeightResolution) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Text("Winner:").bold()
        Text(resolution.winner.rawValue)
      }
      .font(.caption)
      HStack(spacing: 12) {
        Text(
          "DSP vote: \(SignalPoolDiagnostics.floatDisplay(resolution.dspEffectiveVote, digits: 4))")
        if let mlVote = resolution.mlEffectiveVote {
          Text("ML vote: \(SignalPoolDiagnostics.floatDisplay(mlVote, digits: 4))")
        }
        Text("Selected BPM: \(SignalPoolDiagnostics.bpmDisplay(resolution.selectedBPM))")
      }
      .font(.caption2)
      .foregroundStyle(.secondary)
      .monospacedDigit()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
