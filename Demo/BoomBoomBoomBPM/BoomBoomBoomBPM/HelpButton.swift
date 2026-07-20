import BoomBoomBoomKit
import SwiftUI

// MARK: - DemoDocumentedCase

// A demo-local descriptor bridging a library case to its authored per-case
// documentation. Demo-owned by design (KDD-E1): a library enum is NEVER
// conformed to this protocol — it is wrapped in a demo adapter (see
// `MergeStrategyDoc`) that carries the `(kind, id)` docID pair by value.
//
// `nonisolated` so off-actor Swift Testing logic tests can reach the pure
// derivations under the demo target's `SWIFT_DEFAULT_ACTOR_ISOLATION =
// MainActor` default. The default `docs` accessor calls the shipped total
// `BoomBoomBoomKitDocs.attributedString(for:id:)` DIRECTLY — Story 11.1/11.5
// shipped that symbol, so the reverted-10.5 injected-resolver seam (an
// `@Entry docsResolver` + optional fallback) is collapsed away (Story 11.6 DD1).
nonisolated protocol DemoDocumentedCase {
  /// The documentation catalog subdirectory — the library type's `documentedKind`.
  var kind: String { get }
  /// The per-case identifier — the markdown filename stem (the case rawValue).
  var id: String { get }
  /// A one-line summary shown as the "?" button tooltip; seeds nothing else.
  var shortDescription: String { get }
  /// The human-readable case name shown as the popover heading (the front-matter
  /// title is stripped by the accessor, so the case must be named in-view).
  var displayName: String { get }
  /// The human-readable name of the control this case belongs to (e.g. "Merge
  /// strategy"), supplied by the adapter so the generic button can voice a
  /// control-qualified accessibility label without hardcoding a domain string.
  var controlName: String { get }
}

extension DemoDocumentedCase {
  /// The authored multi-paragraph documentation for this case. Total: the
  /// accessor owns its own `"Documentation unavailable for <kind>.<id>."`
  /// fallback, so this never throws and never returns `nil`.
  var docs: AttributedString {
    BoomBoomBoomKitDocs.attributedString(for: kind, id: id)
  }
}

// MARK: - HelpButton

/// A `questionmark.circle` "?" button that opens a `.popover()` explaining a
/// single ``DemoDocumentedCase`` — the case's `displayName` heading, its authored
/// prose (scrollable, width-bounded), and an always-present GitHub source link.
///
/// Chrome mirrors the shipped `BeatGridHelpButton` (`.borderless`,
/// `.controlSize(.small)`, `.help(...)`, `.popover(arrowEdge: .bottom)` +
/// `.padding().frame(width: 360)`). The view and its `@State` stay MainActor —
/// only the pure helpers (`HelpButtonDocs`, the adapter derivations) are
/// `nonisolated`.
struct HelpButton<T: DemoDocumentedCase>: View {
  // `case` is a Swift keyword; the call site reads `HelpButton(case:)` while the
  // stored property avoids backtick noise in the body.
  private let documentedCase: T
  @State private var isPresented = false

  init(case documentedCase: T) {
    self.documentedCase = documentedCase
  }

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      Image(systemName: "questionmark.circle")
    }
    .buttonStyle(.borderless)
    .controlSize(.small)
    .help(documentedCase.shortDescription)
    // Control name + case name both come from the descriptor, not a hardcoded
    // string — `HelpButton` is generic over any `DemoDocumentedCase`, so each
    // conformer supplies its own control context ("Merge strategy") and VoiceOver
    // hears "Help for Merge strategy: Max confidence". The hint carries the same
    // one-line summary VoiceOver would otherwise miss (sighted users get it via
    // `.help`).
    .accessibilityLabel("Help for \(documentedCase.controlName): \(documentedCase.displayName)")
    .accessibilityHint(documentedCase.shortDescription)
    .popover(isPresented: $isPresented, arrowEdge: .bottom) {
      popoverBody
        .padding()
        .frame(width: 360)
    }
  }

  @ViewBuilder
  private var popoverBody: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(documentedCase.displayName)
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      ScrollView {
        Text(documentedCase.docs)
          .frame(maxWidth: .infinity, alignment: .leading)
          .textSelection(.enabled)
      }
      .frame(maxHeight: 320)
      Link(
        "View source documentation on GitHub",
        destination: HelpButtonDocs.repoDocURL(kind: documentedCase.kind, id: documentedCase.id)
      )
      .font(.caption)
    }
  }
}

// MARK: - HelpButtonDocs

/// Pure helpers for the docs popover. `nonisolated` so the logic tests reach the
/// URL builder off the main actor (the demo target defaults to `MainActor`
/// isolation).
nonisolated enum HelpButtonDocs {
  /// The repo directory that per-case markdown lands under (Story 11.5).
  private static let docsBaseURLString =
    "https://github.com/robbyt/BoomBoomBoomKit/blob/main/Sources/BoomBoomBoomKit/Resources/Documentation/"

  /// Builds the stable GitHub source URL for a `(kind, id)` docID.
  ///
  /// Uses `URL.appending(component:)` PER segment so an in-segment `/` encodes to
  /// `%2F` and a space to `%20` (DD4) — `appending(path:)` on a joined string
  /// would under-encode. Returns a total non-optional `URL`: the base
  /// `Documentation/` URL is the fallback if the (compile-constant) base string
  /// somehow fails to parse — never a force-unwrap trap on a raw id.
  nonisolated static func repoDocURL(kind: String, id: String) -> URL {
    guard let baseURL = URL(string: docsBaseURLString) else {
      return URL(filePath: docsBaseURLString)
    }
    return baseURL.appending(component: kind).appending(component: "\(id).md")
  }
}

// MARK: - Preview

#Preview("Merge strategy help") {
  @Previewable @State var strategy: BPMSelectionPolicy = .maxConfidence
  VStack(alignment: .leading, spacing: 8) {
    HStack {
      Text("Merge strategy")
      HelpButton(case: MergeStrategyDoc(strategy))
      Spacer()
    }
    Picker("Merge strategy", selection: $strategy) {
      ForEach(BPMSelectionPolicy.allCases, id: \.self) { policy in
        Text(AnalysisViewModel.humanize(policy)).tag(policy)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
    Text(AnalysisViewModel.strategyDescription(strategy))
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
  .frame(width: 320)
}

#Preview("Intensity help") {
  @Previewable @State var intensity: AnalysisIntensity = .level7
  VStack(alignment: .leading, spacing: 8) {
    HStack {
      Text("Intensity: \(intensity.level)")
        .font(.callout)
      HelpButton(case: IntensityDoc(intensity))
      Spacer()
    }
    Slider(
      value: Binding(
        get: { Double(intensity.level) },
        set: { intensity = AnalysisIntensity(level: Int($0.rounded())) ?? .default }),
      in: 1.0...10.0,
      step: 1.0)
  }
  .padding()
  .frame(width: 320)
}

#Preview("Ensemble help") {
  @Previewable @State var preset: EnsemblePreset = .default
  VStack(alignment: .leading, spacing: 8) {
    HStack {
      Text("Ensemble")
      HelpButton(case: EnsembleDoc(preset))
      Spacer()
    }
    Picker("Ensemble", selection: $preset) {
      ForEach(EnsemblePreset.allCases, id: \.self) { preset in
        Text(preset.displayName).tag(preset)
      }
    }
    .labelsHidden()
    .pickerStyle(.menu)
    Text(preset.subtitle)
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
  .frame(width: 320)
}
