import BoomBoomBoomKit
import SwiftUI

struct ContentView: View {
  @State private var viewModel = AnalysisViewModel()
  @State private var isDropTargeted: Bool = false

  var body: some View {
    VStack(spacing: 16) {
      controlsSection
      primaryStateView
      bannerView
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    // Axiom A2 — `.contentShape(Rectangle())` must come AFTER `.frame()`
    // and BEFORE `.dropDestination` so padded margins register drops at
    // the visible border edge (`transferable-ref.md:622-635`). The drop
    // region thus covers the controls section AND the result area
    // uniformly — a user dragging onto the slider still drops
    // successfully (Story 5-3 Task 2.8).
    .contentShape(Rectangle())
    .dropDestination(for: URL.self) { urls, _ in
      viewModel.handleDrop(urls)
    } isTargeted: { targeted in
      isDropTargeted = targeted
    }
    .overlay(
      // DD #12 — 1pt accent-color border on hover, lightest-touch
      // valid drop-zone signal per Apple HIG conventions.
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color.accentColor, lineWidth: 1)
        .opacity(isDropTargeted ? 1 : 0)
    )
    // DD #15 / Codex C2 — LaunchServices document-open events
    // (Dock-icon drops, Finder Open With, `open -a`) flow through
    // `.onOpenURL`, NOT `.dropDestination`. Reuses `handleOpenURL`
    // which forwards to `analyze(url:autoStarted: true)` so the
    // stop-only security-scoped resource bracket applies (DD #4).
    .onOpenURL { url in
      viewModel.handleOpenURL(url)
    }
  }

  // MARK: - Parameter Controls (Story 5-3)

  // Two-way `Binding<Double>` bridging `AnalysisIntensity.rawValue: Int`
  // and SwiftUI Slider's Double-only value type (Story 5-3 DD #2).
  // `Int($0.rounded())` — NOT `Int($0)` — because Apple's docs do NOT
  // guarantee the setter has been called with the snapped value before
  // `onEditingChanged: false` fires; `Int(6.999) == 6` would silently
  // downgrade by one step. `AnalysisIntensity.init(rawValue:)` clamps
  // to `1...10` for free.
  //
  // P2 (Story 5-3 code review 2026-05-20): `Int(newValue.rounded())`
  // traps if `newValue` is NaN or ±Infinity. Not reachable via
  // SwiftUI's constrained Slider in normal use, but matches the W20
  // hardening philosophy applied to the read side (formatResultRow).
  // Defensive symmetry — guard non-finite at the binding boundary.
  private var intensityBinding: Binding<Double> {
    Binding(
      get: { Double(viewModel.options.intensity.rawValue) },
      set: { newValue in
        guard newValue.isFinite else { return }
        viewModel.options.intensity = AnalysisIntensity(rawValue: Int(newValue.rounded()))
      }
    )
  }

  // Label suffix for the 4 named intensity constants (DD #2). Helps
  // the user understand the 1-10 scale without reading docs.
  private var intensityLabelText: String {
    let raw = viewModel.options.intensity.rawValue
    let suffix: String
    switch raw {
    case 1: suffix = " (fastest)"
    case 7: suffix = " (default)"
    case 8: suffix = " (thorough)"
    case 10: suffix = " (maximum)"
    default: suffix = ""
    }
    return "\(raw)\(suffix)"
  }

  // Re-run trigger (DD #1 chosen semantics: edit-end + selection-change,
  // NOT continuous on-change). Slider's `onEditingChanged: false`
  // callback fires once at drag-release; Picker's `.onChange` fires
  // once per selection. Both call this helper, which fires a re-analyze
  // ONLY when a file has previously been dropped (`selectedFileURL !=
  // nil`). Edit-end / selection-change with no file still mutates
  // `viewModel.options` so the Copy Config snippet reflects the
  // choices, but no analyze fires.
  private func triggerReanalyze() {
    guard let url = viewModel.selectedFileURL else { return }
    viewModel.analyze(url: url, autoStarted: false)
  }

  @ViewBuilder
  private var controlsSection: some View {
    GroupBox("Parameters") {
      VStack(alignment: .leading, spacing: 12) {
        // Intensity row — label + slider. The slider's
        // `onEditingChanged: { editing in if !editing { ... } }` is
        // SwiftUI's natural debounce (DD #1 (B)): one trigger per
        // user-completed drag, not 10-30 per drag tick.
        VStack(alignment: .leading, spacing: 4) {
          Text("Intensity: \(intensityLabelText)")
            .font(.callout)
          Slider(
            value: intensityBinding,
            in: 1.0...10.0,
            step: 1.0,
            onEditingChanged: { editing in
              if !editing {
                triggerReanalyze()
              }
            }
          )
        }

        // Merge strategy row. `.menu` picker style is the macOS default
        // dropdown (DD #3); `.segmented` or `.wheel` would consume
        // excessive horizontal space for 8 options. The `.onChange`
        // fires once per value change with no drag jitter, so re-run
        // on every change is safe. Note (P3, Story 5-3 code review
        // 2026-05-20): `.onChange(of:)` fires for ANY mutation,
        // including programmatic writes — a future preset / state-
        // restoration feature that sets `viewModel.options.mergeStrategy`
        // programmatically will also trigger a re-analyze. Today the
        // value is only mutated via this Picker, so the firing
        // coincides with user selection.
        Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) {
          ForEach(CandidateMergeStrategy.allCases, id: \.self) { strategy in
            Text(strategy.rawValue).tag(strategy)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: viewModel.options.mergeStrategy) { _, _ in
          triggerReanalyze()
        }

        // Button row — Cancel / Re-analyze / Copy Config. Visibility
        // predicates per DD #4 + DD #5: Cancel shown only when
        // analyzing (hidden-via-`if`, NOT `.disabled(true)`);
        // Re-analyze shown only when a file is dropped AND not
        // analyzing (mutually exclusive with Cancel); Copy Config
        // always visible (snippet is independent of analysis state).
        HStack {
          if viewModel.isAnalyzing {
            Button(viewModel.isCancelling ? "Cancelling…" : "Cancel") {
              viewModel.cancelInFlight()
            }
            .disabled(viewModel.isCancelling)
          }
          if viewModel.selectedFileURL != nil && !viewModel.isAnalyzing {
            Button("Re-analyze") {
              triggerReanalyze()
            }
          }
          Button("Copy Config") {
            viewModel.copyConfigToPasteboard()
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  // MARK: - State-Driven Render (Story 5-2 DD #10, DD #16)

  // Four primary states + a secondary banner that overlays when an
  // `errorMessage` co-exists with `analyzing` or `result` (DD #16).
  private enum DisplayState {
    case empty
    case analyzing(filename: String?, cancelling: Bool)
    case result(AnalysisViewModel.BPMResultRow)
    case errorOnly(String)
  }

  // Delegates to `AnalysisViewModel.formatResultRow` (Story 5-3 DD #15
  // / AC #7). The static helper is the testable boundary: smoke tests
  // exercise NaN/Inf and missing-fields without SwiftUI view-test
  // infrastructure. View remains lint-clean.
  private var displayState: DisplayState {
    if viewModel.isAnalyzing {
      return .analyzing(
        filename: viewModel.fileName,
        cancelling: viewModel.isCancelling
      )
    }
    switch AnalysisViewModel.formatResultRow(
      fileName: viewModel.fileName,
      bpm: viewModel.detectedBPM,
      confidence: viewModel.confidence,
      effectiveIntensity: viewModel.effectiveIntensity,
      elapsedSeconds: viewModel.elapsedSeconds
    ) {
    case .success(let row):
      return .result(row)
    case .failure(.nonFinite):
      // Post-P5 (Story 5-3 code review 2026-05-20): copy says
      // "invalid numeric value" because the `.nonFinite` case now
      // also covers finite-but-out-of-range values (bpm <= 0,
      // confidence outside [0, 1], elapsedSeconds < 0) in addition
      // to NaN/±Infinity. Enum case name retained for low-churn —
      // see AnalysisViewModel.formatResultRow for the rationale.
      return .errorOnly(
        "Internal error: analysis returned an invalid numeric value. This is a library bug — please file an issue."
      )
    case .failure(.missingFields):
      // Fall through to errorMessage / empty per existing semantics —
      // a partial-state read during analysis transitions, or a
      // never-run state pre-drop.
      break
    }
    if let message = viewModel.errorMessage {
      return .errorOnly(message)
    }
    return .empty
  }

  // DD #16: banner appears only when an `errorMessage` is present AND
  // the primary state is `analyzing` or `result`. In `errorOnly` the
  // message IS the primary content (no duplicate banner).
  private var bannerError: String? {
    guard let message = viewModel.errorMessage else { return nil }
    switch displayState {
    case .analyzing, .result:
      return message
    case .empty, .errorOnly:
      return nil
    }
  }

  @ViewBuilder
  private var primaryStateView: some View {
    switch displayState {
    case .empty:
      VStack(spacing: 8) {
        Text("Drop an audio file")
          .font(.title2)
        Text("Supported: WAV, AIFF, MP3, FLAC, M4A, CAF")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    case .analyzing(let filename, let cancelling):
      VStack(spacing: 8) {
        ProgressView()
        if let filename {
          Text(filename)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        if cancelling {
          Text("Cancelling previous analysis…")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    case .result(let row):
      resultView(row)
    case .errorOnly(let message):
      Text(message)
        .font(.callout)
        .foregroundStyle(.red)
        .multilineTextAlignment(.center)
    }
  }

  @ViewBuilder
  private var bannerView: some View {
    if let bannerError {
      Text(bannerError)
        .font(.callout)
        .foregroundStyle(.red)
        .multilineTextAlignment(.center)
    }
  }

  @ViewBuilder
  private func resultView(_ row: AnalysisViewModel.BPMResultRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      resultRow("File", row.fileName)
      resultRow("BPM", row.bpm)
      resultRow("Confidence", row.confidence)
      resultRow("Intensity", row.intensity)
      resultRow("Elapsed", row.elapsed)
    }
    .frame(maxWidth: 360)
  }

  @ViewBuilder
  private func resultRow(_ label: String, _ value: String) -> some View {
    HStack {
      Text("\(label):")
      Spacer()
      Text(value).monospacedDigit()
    }
  }
}
