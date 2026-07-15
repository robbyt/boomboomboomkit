import AppKit
import BoomBoomBoomKit
import SwiftUI
import UniformTypeIdentifiers

/// The model-picker sheet (Story 10.2). A `List` over the demo ``ModelCatalog``
/// (backed by the library ``ModelRegistry/entries``) plus an "Add model from
/// disk…" affordance and a "Use this model" action. This is the ONLY add-model
/// entry point after Story 10.2 relocates the primary-view "Load Model…" button
/// (AC6 / FR-43).
///
/// FR-44 discipline throughout: every status-like value is rendered behind a
/// leading label (`Source:`, `Integrity:`, `Selected:`, `Reason:`), never a bare
/// interpolation.
struct ModelPickerView: View {

  @Bindable var catalog: ModelCatalog
  let viewModel: AnalysisViewModel

  /// Called after a successful "Use this model" so the host view can re-analyze
  /// the current file if one is loaded (AC4).
  var onModelUsed: () -> Void = {}

  @Environment(\.dismiss) private var dismiss

  /// The row highlighted in the `List` — the candidate for "Use this model".
  /// Separate from ``ModelCatalog/selectedURL`` (which marks the model actually
  /// in use). Keyed by `standardizedFileURL` (DD7).
  @State private var highlightedURL: URL?

  /// Labeled `Reason:` string from the last failed `addFromDisk` (DD8), surfaced
  /// under the button.
  @State private var addDiagnostic: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("ML Models")
        .font(.title2)
        .bold()

      if catalog.isEmpty {
        emptyState
      } else {
        modelList
      }

      if let addDiagnostic {
        Text(addDiagnostic)
          .font(.caption)
          .foregroundStyle(.red)
      }
      // Restore-time diagnostics (a moved / unhashable persisted model was
      // skipped, DD8) — labeled Reason strings, surfaced honestly. Indexed id
      // because two skipped models emit the identical reason string (a `\.self`
      // id would collide → SwiftUI duplicate-ID warning + under-render).
      ForEach(Array(catalog.restoreDiagnostics.enumerated()), id: \.offset) { _, reason in
        Text(reason)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if let mlError = viewModel.mlModelError {
        Text("Reason: \(mlError)")
          .font(.caption)
          .foregroundStyle(.red)
          .lineLimit(2)
      }

      Divider()

      HStack(spacing: 8) {
        Button("Add model from disk…") {
          addFromDisk()
        }
        .buttonStyle(.bordered)

        Spacer()

        if catalog.isEmpty {
          // AC2: labeled rationale for the disabled action.
          Text("Reason: no-models-available")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Button("Cancel") {
          dismiss()
        }
        Button("Use this model") {
          useHighlightedModel()
        }
        .buttonStyle(.borderedProminent)
        .disabled(catalog.isEmpty || highlightedURL == nil)
      }
    }
    .padding(20)
    .frame(minWidth: 460, minHeight: 360)
    .onAppear {
      // A load error from a previous sheet session must not greet a fresh open.
      // The failed-load path keeps THIS sheet open (AC4), so `onAppear` fires
      // only on a genuine reopen — clearing here can't hide an in-session error.
      viewModel.mlModelError = nil
      // Default the highlight to the in-use model, else the first entry, so
      // "Use this model" is actionable without an extra click.
      highlightedURL =
        catalog.selectedURL?.standardizedFileURL
        ?? catalog.entries.first?.url.standardizedFileURL
    }
    .onDisappear {
      // Restore diagnostics are a once-per-launch event: shown on the first open
      // (above), cleared on dismiss so they don't haunt every later open all
      // session. `onDisappear` (not `onAppear`) so the first open actually shows
      // them before they're cleared.
      catalog.clearRestoreDiagnostics()
    }
  }

  // MARK: - Subviews

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "shippingbox")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      Text("No models available — add one to begin")
        .font(.headline)
      // The labeled `Reason: no-models-available` lives beside the disabled
      // "Use this model" button (AC2's mandated placement); not duplicated here.
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var modelList: some View {
    List(catalog.entries, id: \.url.standardizedFileURL, selection: $highlightedURL) { entry in
      row(entry)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func row(_ entry: ModelRegistryEntry) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.identifier)
        .font(.headline)
      Text("Source: \(catalog.source(for: entry.url).display)")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(catalog.integrityLabel(for: entry))
        .font(.caption)
        .foregroundStyle(.secondary)
      Text("Selected: \(catalog.isSelected(entry) ? "yes" : "no")")
        .font(.caption)
        .foregroundStyle(catalog.isSelected(entry) ? .green : .secondary)
    }
    .padding(.vertical, 2)
  }

  // MARK: - Actions

  private func addFromDisk() {
    // Clear any stale reason from a prior attempt so a cancelled panel doesn't
    // leave a dead "Reason: …" under the button.
    addDiagnostic = nil
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    // A `.mlmodelc` is a directory bundle, so directories are choosable (DD6);
    // the register-first validation (DD8) is the real guard against a wrong pick.
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.message = "Choose a compiled Core ML model (.mlmodelc)"
    // Constrain toward `.mlmodelc` when the UTType resolves; fall back to the
    // message-only panel otherwise (DD6).
    if let type = UTType(filenameExtension: "mlmodelc") {
      panel.allowedContentTypes = [type]
    }
    guard panel.runModal() == .OK, let url = panel.url else { return }

    switch catalog.addFromDisk(url: url) {
    case .success:
      addDiagnostic = nil
      highlightedURL = url.standardizedFileURL
    case .failure(let error):
      addDiagnostic = error.reason
    }
  }

  private func useHighlightedModel() {
    guard let key = highlightedURL,
      let entry = catalog.entries.first(where: { $0.url.standardizedFileURL == key })
    else { return }
    // The catalog resolves the entry to its token-bearing capability URL and hands
    // THAT (never the tokenless `entry.url`) to the loader — `loadModel` scopes it
    // and constructs `BNNSTechnique` (DD9). On any failure the sheet stays open with
    // the labeled error visible (AC4).
    switch catalog.useModel(entry, load: { viewModel.loadModel(at: $0) }) {
    case .loaded:
      onModelUsed()
      dismiss()
    case .loadFailed:
      // `loadModel` already detached; `useModel` cleared the selection mark. The
      // labeled `mlModelError` from `loadModel` stays visible.
      break
    case .capabilityMissing:
      // No retained capability URL (e.g. a restore whose resolve failed). Detach and
      // surface a labeled reason, consistent with the failed-load contract (FR-44).
      viewModel.failModelLoad(reason: "model-unavailable")
    }
  }
}
