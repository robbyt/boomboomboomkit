import BoomBoomBoomKit
import SwiftUI

struct ContentView: View {
  @State private var viewModel = AnalysisViewModel()
  @State private var isDropTargeted: Bool = false

  // Persisted via @SceneStorage so the inspector preference survives
  // window-close / app-relaunch. Default false — end-user audience;
  // power users toggle via the Diagnostics button (Command-Shift-D),
  // the system View → Show Inspector menu, or Control-Command-I (both
  // provided by `InspectorCommands()` at
  // `BoomBoomBoomBPMApp.swift:14-16`).
  @SceneStorage("traceInspectorPresented") private var inspectorPresented: Bool = false

  // Accessibility gates for `StrategyBackground` — reduce-motion
  // suppresses the cross-strategy cross-fade; increased-contrast
  // switches the gradient out for a solid fill (handled inside
  // `StrategyBackground`). Read at the root so the keyed
  // `.animation(...)` modifier can disable cleanly per AC #5.
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // F03 (Story 5-6 review): @ScaledMetric drives the hero point size with
  // Dynamic Type relative to .largeTitle. Default 96pt at the user's
  // body-size; scales up at AX1-AX3 (capped by the `.dynamicTypeSize(...)`
  // modifier on the Text). Fixes KDD #4's "honors AX1-AX3" promise — bare
  // Font.system(size: 96) is fixed-point and does NOT scale.
  @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 96

  // `nil` until the first run completes — that's the cue for the
  // neutral pre-analysis gradient (KDD #8). Once a snapshot exists,
  // the user-chosen merge strategy keys the visual.
  private var backgroundStrategy: BPMSelectionPolicy? {
    viewModel.lastRunSnapshot == nil ? nil : viewModel.options.mergeStrategy
  }

  var body: some View {
    ZStack {
      // Outer-`ZStack` composition (KDD #8 / AC #4): the gradient
      // paints behind EVERY `DisplayState`, not just `.result`. A
      // result-block-scoped `.background()` would collapse to zero
      // size in `.empty` / `.analyzing` / `.errorOnly` — that's the
      // anti-pattern this design rejects.
      // F11 (Story 5-6b, option b after Codex review): the gradient
      // stops at the safe area so visual extent and `.dropDestination`
      // hit-region agree at the same boundary. The earlier attempt
      // (`.ignoresSafeArea()` on the outer ZStack) propagated to the
      // content VStack and pushed the result-view BPM hero under the
      // title bar.
      StrategyBackground(strategy: backgroundStrategy)
        .animation(
          reduceMotion ? nil : .easeInOut(duration: 0.25),
          value: backgroundStrategy
        )

      // F04 (Story 5-6b): `primaryStateView` claims the full pane height
      // so EmptyStateView (with `.frame(maxHeight: .infinity)` and a
      // VStack-default center alignment) centers vertically in the area
      // above controls. The earlier `Spacer()` between bannerView and
      // controlsSection split the space 50/50 with EmptyStateView and
      // landed the empty state in the upper half.
      VStack(spacing: 16) {
        primaryStateView
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        bannerView
        beatGridSection
        controlsSection
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    }
    // `.contentShape` AFTER `.frame()` and BEFORE `.dropDestination` so
    // padded margins register drops at the visible border edge.
    .contentShape(Rectangle())
    .dropDestination(for: URL.self) { urls, _ in
      viewModel.handleDrop(urls)
    } isTargeted: { targeted in
      isDropTargeted = targeted
    }
    .overlay(
      // `.allowsHitTesting(false)` because the right segment of this
      // stroke ring sits over the inspector divider; without opting
      // out, the decorative ring swallows the divider's resize-drag.
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color.accentColor, lineWidth: 1)
        .opacity(isDropTargeted ? 1 : 0)
        .allowsHitTesting(false)
    )
    // LaunchServices document-open events (Dock-icon drops, Finder
    // Open With, `open -a`) flow through `.onOpenURL`, not
    // `.dropDestination`.
    .onOpenURL { url in
      viewModel.handleOpenURL(url)
    }
    .toolbar {
      // AC #9: explicit toolbar toggle in addition to the system
      // `InspectorCommands()` wire. macOS routes `.toolbar` from a
      // bare `WindowGroup` ContentView to the window title-bar — no
      // `NavigationStack` wrapping required.
      ToolbarItem(placement: .primaryAction) {
        Button {
          inspectorPresented.toggle()
        } label: {
          Label("Diagnostics", systemImage: "sidebar.right")
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
        .help("Show / hide diagnostics (\u{2318}\u{21E7}D)")
        // F12 (Story 5-6b): VoiceOver announces toggle state. Without
        // this, VO reads "Diagnostics, button" regardless of whether
        // the inspector is currently shown or hidden. `Text(...)` per
        // Apple-docs MCP — the indexed `.accessibilityValue(_:)`
        // overload documents the Text form for forward-compat.
        .accessibilityValue(Text(inspectorPresented ? "Shown" : "Hidden"))
      }
    }
    // CRITICAL: `.inspectorColumnWidth(min:ideal:max:)` MUST be applied
    // to the inspector CONTENT (inside the closure), NOT chained after
    // `.inspector(...)`. Apple's documented usage:
    //   https://developer.apple.com/documentation/swiftui/view/inspectorcolumnwidth(min:ideal:max:)
    //   "Apply this modifier on the content of inspector(isPresented:content:)"
    // Chaining outside silently leaves the inspector at its default
    // non-resizable behavior — the divider renders but won't drag. The
    // Group wrapper resolves the if/else to a single view so the
    // modifier attaches unambiguously.
    .inspector(isPresented: $inspectorPresented) {
      // P_D5 / D5 resolution (code review 2026-05-23): 3-state branch
      // surfaces an explicit "Analyzing…" placeholder for the first-run
      // window (`isAnalyzing == true` AND no prior snapshot) instead of
      // flashing the empty-state view. On re-analyze F09 preserves the
      // prior snapshot (`AnalysisViewModel.swift:185-197`), so the
      // populated `TraceView` stays mounted and the placeholder doesn't
      // fire. First-run cascade: Empty → Analyzing → Populated reflects
      // the honest pipeline state; the inspector never pretends
      // "nothing happened yet" while the first run is in flight.
      Group {
        if let snapshot = viewModel.lastRunSnapshot {
          TraceView(snapshot: snapshot, gridVisualization: viewModel.gridVisualization)
        } else if viewModel.isAnalyzing {
          TraceInspectorAnalyzingView()
        } else {
          TraceInspectorEmptyView()
        }
      }
      .inspectorColumnWidth(min: 240, ideal: 320, max: 480)
    }
  }

  // MARK: - Parameter Controls

  // `Int($0.rounded())`, NOT `Int($0)` — without rounding, `Int(6.999)`
  // truncates to 6 and silently downgrades by one step. The non-finite
  // guard defends against the trap `Int.init(_: Double)` would emit if
  // a NaN/Inf somehow reached this setter.
  private var intensityBinding: Binding<Double> {
    Binding(
      get: { Double(viewModel.options.intensity.rawValue) },
      set: { newValue in
        guard newValue.isFinite else { return }
        viewModel.options.intensity = AnalysisIntensity(rawValue: Int(newValue.rounded()))
      }
    )
  }

  // The analysis time cap (`Options.maxSeconds`) — caps the decode for BPM, beat
  // grid, AND the waveform, so the visualization and the analysis stay in sync.
  private var maxSecondsBinding: Binding<Double> {
    Binding(
      get: { viewModel.options.maxSeconds },
      set: { viewModel.options.maxSeconds = $0 }
    )
  }

  // Maps the 3-case `BeatGridTempoLock` to a simple on/off toggle for the demo:
  // off <-> .off, on <-> .bpmStage (lock to the detected BPM). The `.bpm(Double)`
  // pin-an-exact-BPM case is API-only.
  private var lockToDetectedBPMBinding: Binding<Bool> {
    Binding(
      get: { viewModel.options.beatGridTempoLock == .bpmStage },
      set: { viewModel.options.beatGridTempoLock = $0 ? .bpmStage : .off }
    )
  }

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

  // Edit-end (slider drag-release) + selection-change (picker) — NOT
  // continuous on-change. Only re-runs if a file has previously been
  // dropped; options changes pre-drop still update Copy Config but
  // don't kick off analyze.
  private func triggerReanalyze() {
    guard let url = viewModel.selectedFileURL else { return }
    viewModel.analyze(url: url, autoStarted: false)
  }

  // Beat-grid + waveform overlay for the current result. Shown only when a grid
  // was tracked (`gridVisualization != nil`). The inner vertical ScrollView +
  // `maxHeight` cap are load-bearing: the beat-grid block is otherwise an
  // unbounded, incompressible view that grows the window to fill the screen and
  // starves `primaryStateView`'s `maxHeight: .infinity` share, hiding the BPM
  // hero. Capping it (and letting it scroll on overflow) keeps the block bounded
  // and the hero visible. The (?) help sits in the custom GroupBox label.
  @ViewBuilder
  private var beatGridSection: some View {
    if let grid = viewModel.gridVisualization {
      GroupBox {
        ScrollView(.vertical) {
          BeatGridView(state: grid)
        }
      } label: {
        HStack(spacing: 6) {
          Text("Beat grid")
          BeatGridHelpButton()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: 340, alignment: .topLeading)
    }
  }

  @ViewBuilder
  private var controlsSection: some View {
    GroupBox("Parameters") {
      VStack(alignment: .leading, spacing: 12) {
        // `onEditingChanged: { editing in if !editing }` is SwiftUI's
        // natural drag-release debounce — one trigger per completed
        // drag, not 10-30 per drag tick.
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

        // Analysis time cap. Re-analyzes on drag-release (same debounce as the
        // intensity slider).
        VStack(alignment: .leading, spacing: 4) {
          Text("Analyze first \(Int(viewModel.options.maxSeconds)) s")
            .font(.callout)
          Slider(
            value: maxSecondsBinding,
            in: 30...600,
            step: 30,
            onEditingChanged: { editing in
              if !editing {
                triggerReanalyze()
              }
            }
          )
          .help(
            "How many seconds of the track to decode and analyze — BPM, beat grid, AND the "
              + "waveform. Caps cost on long files (600 ≈ 10 min). The grid + waveform you see "
              + "cover exactly this span.")
        }

        // Beat-grid tempo lock. For constant-BPM electronic / DJ material, force
        // the grid to extrapolate from the clean detected BPM so it stops drifting.
        Toggle("Lock grid to detected BPM", isOn: lockToDetectedBPMBinding)
          .toggleStyle(.checkbox)
          .onChange(of: viewModel.options.beatGridTempoLock) { _, _ in
            triggerReanalyze()
          }
          .help(
            "Lock the beat grid to the clean detected BPM instead of the tracker's measured "
              + "tempo — removes the slow drift that a fraction-of-a-BPM error accumulates over a "
              + "track. Octave-normalized to the grid; ignored if the two disagree by more than "
              + "an octave. Best for constant-tempo electronic / DJ music.")

        // `.onChange(of:)` fires for any mutation, including
        // programmatic writes — today only this Picker mutates the
        // value, so a future preset feature could trigger unintended
        // re-analyzes.
        Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) {
          ForEach(BPMSelectionPolicy.allCases, id: \.self) { strategy in
            // F06 (Story 5-6 review, closes deferred-work W28): humanize
            // raw camelCase enum names ("maxConfidence", "windowVoting")
            // into space-separated lowercase ("max confidence", "window
            // voting") for the end-user Picker labels. The rawValue
            // string is preserved internally on the @Binding.
            Text(AnalysisViewModel.humanize(strategy)).tag(strategy)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: viewModel.options.mergeStrategy) { _, _ in
          viewModel.persistPreferredMergeStrategy()
          triggerReanalyze()
        }

        // BYOW ML (Epic 7): load a compiled `.mlmodelc` and run `.mlOnly`
        // inference through the production runtime path. Default off keeps the
        // demo DSP-only. The toggle appears once a model is loaded; flipping it
        // re-analyzes the current file.
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Button("Load Model…") {
              if viewModel.pickAndLoadMLModel() {
                triggerReanalyze()
              }
            }
            .buttonStyle(.bordered)
            if viewModel.mlModelName != nil {
              Toggle("ML (.mlOnly)", isOn: $viewModel.mlEnabled)
                .toggleStyle(.switch)
                .onChange(of: viewModel.mlEnabled) { _, _ in
                  triggerReanalyze()
                }
            }
          }
          if let name = viewModel.mlModelName {
            Text("Model: \(name)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
          }
          if let mlError = viewModel.mlModelError {
            Text(mlError)
              .font(.caption)
              .foregroundStyle(.red)
              .lineLimit(2)
          }
        }

        // Cancel / Re-analyze / Copy Config / Export Trace.
        // Cancel + Re-analyze are mutually exclusive (analyzing vs
        // idle); Copy Config is always visible; Export Trace requires
        // a populated snapshot.
        HStack(spacing: 8) {
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
            .buttonStyle(.borderedProminent)
            Divider().frame(height: 16)
          }
          Button("Copy Config") {
            viewModel.copyConfigToPasteboard()
          }
          .buttonStyle(.bordered)
          if viewModel.lastRunSnapshot != nil && !viewModel.isAnalyzing {
            Button("Export Trace") {
              viewModel.exportTrace()
            }
            .buttonStyle(.bordered)
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  // MARK: - State-Driven Render

  // Four primary states + a secondary banner that overlays when an
  // errorMessage co-exists with analyzing/result.
  private enum DisplayState {
    case empty
    case analyzing(filename: String?, cancelling: Bool)
    case result(AnalysisViewModel.BPMResultRow)
    case errorOnly(String)
  }

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
      // `.nonFinite` covers NaN/Inf AND out-of-range; user-facing
      // copy says "invalid numeric value" to fit both.
      return .errorOnly(
        "Internal error: analysis returned an invalid numeric value. This is a library bug — please file an issue."
      )
    case .failure(.missingFields):
      // Partial state during analysis transitions, or never-run
      // pre-drop. Fall through to errorMessage / empty.
      break
    }
    if let message = viewModel.errorMessage {
      return .errorOnly(message)
    }
    return .empty
  }

  // Banner appears only when an errorMessage is present AND the
  // primary state is analyzing/result; in errorOnly the message IS the
  // primary content (no duplicate banner).
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
      EmptyStateView()
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

  // Hero rendering per AC #2 / KDD #4. `.monospacedDigit()` (not
  // `design: .monospaced` on the full face) keeps SF Pro on the
  // " BPM" suffix while stabilising digit widths. Bounded Dynamic
  // Type (≤ AX3) + `minimumScaleFactor` + `lineLimit(1)` cooperate
  // to honor AX1–AX3 and degrade gracefully beyond — fixed 96pt
  // alone would violate Dynamic Type, pure `.relativeTo(.largeTitle)`
  // would let AX4/AX5 push the number off-canvas.
  @ViewBuilder
  private func resultView(_ row: AnalysisViewModel.BPMResultRow) -> some View {
    VStack(alignment: .trailing, spacing: 12) {
      Text(row.bpm)
        .font(.system(size: heroSize, weight: .bold).monospacedDigit().leading(.tight))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .minimumScaleFactor(0.6)
        .lineLimit(1)

      VStack(alignment: .trailing, spacing: 4) {
        secondaryMetadataRow(row.fileName)
        secondaryMetadataRow("Confidence: \(row.confidence)")
        secondaryMetadataRow("Elapsed: \(row.elapsed)")
      }
      .font(.callout)
      .foregroundStyle(.secondary)
    }
    // Single-container top-right anchoring (AC #2 — `.frame` with
    // `alignment: .topTrailing` on a single VStack, NOT nested
    // `HStack { Spacer(); VStack }`). `maxHeight: .infinity` added
    // (Story 5-6b post-Codex review) because `primaryStateView` now
    // claims the full pane height; without it the intrinsic-height
    // result block would center vertically instead of anchoring
    // top-right.
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
  }

  @ViewBuilder
  private func secondaryMetadataRow(_ value: String) -> some View {
    Text(value).monospacedDigit()
  }
}
