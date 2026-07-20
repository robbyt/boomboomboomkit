import BoomBoomBoomKit
import SwiftUI

struct ContentView: View {
  @State private var viewModel = AnalysisViewModel()
  @State private var isDropTargeted: Bool = false

  // Registry-backed model catalog (Story 10.2), the ONLY add-model surface after
  // the primary-view "Load Model…" button was relocated into the picker sheet
  // (AC6 / FR-43). Owned by `BoomBoomBoomBPMApp` and injected here — NOT a local
  // `@State`: `ModelCatalog.init` runs a synchronous `restore()` (bookmark
  // resolution + SHA-256 of every model), and a `@State` initial value is
  // re-evaluated on every `ContentView` construction and discarded after the
  // first, so a local `@State` would re-run restore-and-throw-away. App-level
  // ownership constructs it once at app lifetime. (Consequence: a second
  // `WindowGroup` window would share this one catalog + `selectedURL` — fine for
  // this single-window demo, deliberate.)
  private let modelCatalog: ModelCatalog
  @State private var isModelPickerPresented: Bool = false

  // Audio playback for the Story-10.3 beat-grid scrubber. A local `@State`
  // (unlike `modelCatalog`, which was App-hoisted): `PlaybackController.init` does NO
  // I/O — the file loads only when the result-paired `.onChange` below fires — so a
  // per-construction `@State` re-eval is harmless and does not regress the 10.2 R3
  // hoist lesson (that was about an expensive `restore()` in `init`). Scope is released
  // deterministically on `.onDisappear` (below); `deinit` is only a backstop.
  @State private var playback = PlaybackController()

  init(modelCatalog: ModelCatalog) {
    self.modelCatalog = modelCatalog
  }

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

  // Readability width cap for each column of the paired Ensemble | Merge-strategy
  // row, so a long caption wraps instead of driving the column wide and squeezing
  // the neighboring Picker. A flexible maximum (not a fixed width), so narrow
  // windows still compress.
  //
  // The analysis lane deliberately has NO height constant. With the result-state
  // BPM hero intrinsic (`heroFillsPane`), the lane is the sole vertically-greedy
  // child, so it fills the reclaimed height via `maxHeight: .infinity` and no
  // hardcoded cap is needed: its own minimum stays small, `.defaultSize` sets the
  // launch height, and the `.contentMinSize` window minimum tracks the small
  // content minimum — so the window stays freely shrinkable. (An earlier
  // `idealHeight` + `layoutPriority(1)` on the lane resisted compression, inflated
  // the content minimum past the screen, and wedged the window taller than the
  // display — fixed 2026-07-19.)
  private let columnWidth: CGFloat = 260

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

      // Scrollable content that is at least as tall as the viewport (the
      // standard macOS "content >= viewport" pattern). The `GeometryReader`
      // viewport height sets the inner VStack's `minHeight`, so: when everything
      // fits, the VStack is exactly viewport-tall and the result-state analysis
      // lane still fills the surplus (controls stay pinned at the bottom); when
      // the intrinsic content (controls + hero) is taller than a short window it
      // SCROLLS instead of clipping. Because the ScrollView itself is vertically
      // compressible, the window's `.contentMinSize` minimum no longer includes
      // the full non-compressible controls stack — so the window is freely
      // shrinkable. The gradient and `.dropDestination` stay on the outer ZStack
      // (they must cover the whole window, not scroll with the controls).
      //
      // Per-state vertical greed lives in `heroFillsPane`: the transient
      // analyzing / error text centers by filling; the empty-state drop prompt
      // and the result hero are intrinsic (so the prompt is a compact top prompt,
      // not a full-window-centered block — and the result hero anchors top-right
      // and hands surplus height to the analysis lane).
      GeometryReader { viewport in
        ScrollView(.vertical) {
          VStack(spacing: 16) {
            primaryStateView
              .frame(maxWidth: .infinity, maxHeight: heroFillsPane ? .infinity : nil)
            bannerView
            analysisSection
            controlsSection
          }
          .frame(maxWidth: .infinity)
          .frame(minHeight: viewport.size.height, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
      }
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
    // Playback follows the current result-paired source: beat-grid wins when
    // both results exist, and a loudness-only graph still gets seek/play.
    // Re-analysis clears both result payloads synchronously, so A -> nil -> A
    // reloads freshly analyzed audio even when the URL itself is unchanged.
    .onChange(of: viewModel.playbackSourceURL) { _, url in
      playback.load(url: url)
    }
    .onDisappear {
      playback.load(url: nil)
    }
    // Registry-backed model picker (Story 10.2). On a successful "Use this
    // model" the sheet re-analyzes the current file if one is loaded.
    .sheet(isPresented: $isModelPickerPresented) {
      ModelPickerView(
        catalog: modelCatalog,
        viewModel: viewModel,
        onModelUsed: { triggerReanalyze() }
      )
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

  // `.rounded()`, NOT a bare `Int($0)` — without rounding, `Int(6.999)`
  // truncates to 6 and silently downgrades by one step.
  private var intensityBinding: Binding<Double> {
    Binding(
      get: { Double(viewModel.options.intensity.level) },
      set: { newValue in
        guard newValue.isFinite else { return }
        // Clamp in the Double domain BEFORE the Int conversion: `Int(_:)` traps
        // on any finite value beyond Int's range too, not just NaN/Inf, so the
        // clamp must precede the conversion (not follow it). The slider is bound
        // 1...10, so this is defense-in-depth; it also keeps the failable
        // `init?(level:)` from ever returning nil here.
        let clampedLevel = Int(min(max(newValue.rounded(), 1), 10))
        viewModel.options.intensity = AnalysisIntensity(level: clampedLevel) ?? .default
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

  /// Grid refinement fits the extrapolated grid to onset evidence. It is
  /// intentionally independent from the headline BPM and leaves BPM-stage
  /// locking off, so a coarse BPM estimate cannot overwrite the refined grid.
  private var refineGridTempoBinding: Binding<Bool> {
    Binding(
      get: { viewModel.options.refineBeatGridTempo },
      set: { viewModel.options.refineBeatGridTempo = $0 }
    )
  }

  private var intensityLabelText: String {
    let intensity = viewModel.options.intensity
    // Shares the alias-suffix mapping with `IntensityDoc` (the help popover
    // heading) so the slider label and the popover cannot drift apart.
    return "\(intensity.level)\(IntensityDoc.aliasSuffix(for: intensity))"
  }

  // Edit-end (slider drag-release) + selection-change (picker) — NOT
  // continuous on-change. Only re-runs if a file has previously been
  // dropped; options changes pre-drop still update Copy Config but
  // don't kick off analyze.
  private func triggerReanalyze() {
    guard let url = viewModel.selectedFileURL else { return }
    viewModel.analyze(url: url, autoStarted: false)
  }

  // Which pane the shared analysis lane renders (Story 10.4 UX rework): the
  // Beats waveform/grid view or the LUFS-over-time graph — one lane, one
  // GroupBox, a segmented switch when both have data. Session-scoped by design
  // (no UserDefaults persistence — the 10.3 rework precedent for lane modes).
  private enum AnalysisPane: String, CaseIterable {
    case beats = "Beats"
    case loudness = "Loudness"
  }
  @State private var analysisPane: AnalysisPane = .beats

  // The pane actually rendered: the user's choice when its data exists, else
  // whichever side has data (a no-BPM file can still measure loudness, and
  // vice versa) — never an empty lane while either result exists.
  private var effectivePane: AnalysisPane {
    switch analysisPane {
    case .beats:
      return viewModel.gridVisualization != nil ? .beats : .loudness
    case .loudness:
      return viewModel.lufsReport != nil ? .loudness : .beats
    }
  }

  // Analysis lane for the current result: ONE GroupBox hosting either the
  // Beats view (waveform + grid + scrubber, Story 10.3) or the loudness graph
  // (LUFS over time, Story 10.4 UX rework — replaces the old full-height
  // bottom loudness panel). Shown when either result exists; the segmented
  // switch appears only when both do. With the result-state hero now intrinsic
  // (`heroFillsPane`), this lane is the sole vertically-greedy child, so it fills
  // the reclaimed vertical space via `maxHeight: .infinity` and grows/shrinks with
  // the window. Both lanes are compressible (BeatGridView min ~0; LoudnessGraphView
  // has a small 120 floor), so the lane adds no large minimum — the window stays
  // shrinkable under `.contentMinSize`, and `.defaultSize` fixes the launch height.
  // No hardcoded height cap here on purpose (see `columnWidth`'s note).
  @ViewBuilder
  private var analysisSection: some View {
    let grid = viewModel.gridVisualization
    let lufs = viewModel.loudnessVisualization
    if grid != nil || lufs != nil {
      GroupBox {
        switch effectivePane {
        case .beats:
          if let grid {
            BeatGridView(state: grid, controller: playback)
          }
        case .loudness:
          if let lufs {
            LoudnessGraphView(
              report: lufs.report,
              analysisWindowSeconds: lufs.analysisWindowSeconds,
              controller: playback)
          }
        }
      } label: {
        HStack(spacing: 6) {
          if grid != nil && lufs != nil {
            Picker("Analysis pane", selection: $analysisPane) {
              ForEach(AnalysisPane.allCases, id: \.self) { pane in
                Text(pane.rawValue).tag(pane)
              }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
          } else {
            // Only one side has data — a switch would be a lie; name the pane.
            Text(effectivePane == .beats ? "Beat grid" : "Loudness")
          }
          switch effectivePane {
          case .beats: BeatGridHelpButton()
          case .loudness: LoudnessHelpButton()
          }
          Spacer()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
          // Header row (mirrors the Merge strategy control): the "Intensity: N"
          // label beside a "?" HelpButton opening the authored per-level
          // `AnalysisIntensity` docs for the selected level, so the help changes
          // as the slider moves.
          HStack {
            Text("Intensity: \(intensityLabelText)")
              .font(.callout)
            HelpButton(case: IntensityDoc(viewModel.options.intensity))
            Spacer()
          }
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
            "How many seconds of the track to decode and analyze: BPM, beat grid, and the "
              + "waveform. Caps cost on long files (600 is about 10 min). The grid and waveform "
              + "you see cover exactly this span.")
        }

        // "Refine grid tempo" + a "?" popover explaining what it does, then a
        // full-width rule separating this option from the ensemble/merge
        // controls below.
        HStack(spacing: 6) {
          Toggle("Refine grid tempo", isOn: refineGridTempoBinding)
            .toggleStyle(.checkbox)
            .onChange(of: viewModel.options.refineBeatGridTempo) { _, _ in
              triggerReanalyze()
            }
            .help(
              "Map the beat grid to the onsets detected in the track. Keeps the headline BPM "
                + "unchanged. Assumes a constant tempo.")
          RefineGridTempoHelpButton()
          Spacer()
        }

        Divider()

        // Ensemble + Merge strategy share one row: Ensemble on the left, Merge
        // strategy in a column to its right (demo UX relayout). Both blocks are
        // width-bounded by `columnWidth` so their caption lines wrap rather than
        // driving the column wide and squeezing the neighboring Picker; the
        // trailing Spacer keeps the pair adjacent-left with empty space to the
        // right. These are the two "how signals combine" controls.
        HStack(alignment: .top, spacing: 24) {
          // Ensemble preset — governs how DSP / ML / metadata votes combine.
          // Preset changes never touch `options.mergeStrategy`, so the
          // merge-strategy Picker's `.onChange` cannot cascade — one persist +
          // one re-analyze per selection (the no-cascade rule from Story 9.1 DD5).
          VStack(alignment: .leading, spacing: 4) {
            EnsemblePresetPicker(selection: $viewModel.selectedEnsemblePreset)
              .onChange(of: viewModel.selectedEnsemblePreset) { _, _ in
                viewModel.persistPreferredEnsemblePreset()
                triggerReanalyze()
              }
            // Honest degradation (Story 9.1 DD7): `ML augmented` / `DSP only`
            // warn when the loaded-model state makes the ML signal absent.
            // No reserved space (was 2 lines): the caption is empty on the
            // default preset, and reserving two blank lines left a too-large gap
            // above the rule below. A degrading preset simply grows the column by
            // its 1-2 warning lines when it applies.
            Text(
              AnalysisViewModel.ensembleDegradationCaption(
                preset: viewModel.selectedEnsemblePreset,
                mlModelName: viewModel.mlModelName,
                mlEnabled: viewModel.mlEnabled)
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          }
          .frame(maxWidth: columnWidth, alignment: .topLeading)

          // Merge strategy (Story 11.6): the visible "Merge strategy" label
          // sits beside a "?" HelpButton opening the authored
          // `BPMSelectionPolicy` docs-popover for the selected strategy. The
          // visible Text is decorative and a11y-hidden — `.labelsHidden()`
          // hides the Picker's label VISUALLY but keeps it for VoiceOver, so
          // the Picker itself remains the single accessible "Merge strategy"
          // element (avoiding a duplicate announcement).
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("Merge strategy")
                .accessibilityHidden(true)
              HelpButton(case: MergeStrategyDoc(viewModel.options.mergeStrategy))
            }
            // `.onChange(of:)` fires for any mutation, including programmatic
            // writes — today only this Picker mutates the value, so a future
            // preset feature could trigger unintended re-analyzes.
            Picker("Merge strategy", selection: $viewModel.options.mergeStrategy) {
              ForEach(BPMSelectionPolicy.allCases, id: \.self) { strategy in
                // F06 (Story 5-6 review, closes deferred-work W28): humanize
                // raw camelCase enum names ("maxConfidence", "windowVoting")
                // into space-separated lowercase ("max confidence", "window
                // voting") for the end-user Picker labels. The rawValue string
                // is preserved internally on the @Binding.
                Text(AnalysisViewModel.humanize(strategy)).tag(strategy)
              }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .onChange(of: viewModel.options.mergeStrategy) { _, _ in
              viewModel.persistPreferredMergeStrategy()
              triggerReanalyze()
            }
            // One-line help mirroring the ensemble control — updates with the
            // selected policy.
            Text(AnalysisViewModel.strategyDescription(viewModel.options.mergeStrategy))
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: columnWidth, alignment: .topLeading)

          Spacer(minLength: 0)
        }

        Divider()

        // BYOW ML (Epic 7; preset-governed since Story 9.1): the "Use loaded
        // model" toggle + model name form a status line shown once a model is
        // loaded. `mlModelError` is rendered independently so a failed load is
        // never swallowed. Adding / choosing a model lives in the "Models…"
        // sheet (Story 10.2), opened from the action row below.
        if let name = viewModel.mlModelName {
          HStack(spacing: 8) {
            Toggle("Use loaded model", isOn: $viewModel.mlEnabled)
              .toggleStyle(.switch)
              .onChange(of: viewModel.mlEnabled) { _, _ in
                triggerReanalyze()
              }
            Text("Model: \(name)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
        if let mlError = viewModel.mlModelError {
          Text("Reason: \(mlError)")
            .font(.caption)
            .foregroundStyle(.red)
            .lineLimit(2)
        }

        // Bottom action row: Cancel / Re-analyze │ Models… / Copy Config /
        // Export Trace. Cancel + Re-analyze are mutually exclusive (analyzing
        // vs idle); Models… + Copy Config are always visible; Export Trace
        // requires a populated snapshot.
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
          Button("Models…") {
            isModelPickerPresented = true
          }
          .buttonStyle(.bordered)
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
        "Internal error: analysis returned an invalid numeric value. This is a library bug. Please file an issue."
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

  // Which states let the primary view greedily fill the vertical slot. ONLY the
  // transient analyzing / error text centers by filling. The empty-state drop
  // prompt and the result hero are intrinsic: the prompt stays a compact top
  // affordance (not a full-window-centered block, the "drop area too big"
  // complaint), and the result hero anchors top-right and hands surplus height
  // to the analysis lane. The analyzing / error fill and the result-state
  // analysis lane push controls to the bottom in those states; the empty state
  // has no greedy view, so its controls follow the compact prompt directly.
  private var heroFillsPane: Bool {
    switch displayState {
    case .analyzing, .errorOnly: return true
    case .empty, .result: return false
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
        // TODO(Epic 11): align with KDD-E8 style guide
        secondaryMetadataRow("BPM confidence: \(row.confidence)")
        secondaryMetadataRow("Elapsed: \(row.elapsed)")
      }
      .font(.callout)
      .foregroundStyle(.secondary)
    }
    // Single-container top-right anchoring (AC #2 — `.frame` with
    // `alignment: .topTrailing` on a single VStack, NOT nested
    // `HStack { Spacer(); VStack }`). Width-fill + trailing alignment keep the
    // hero top-right; the vertical greed (`maxHeight: .infinity`) is
    // deliberately dropped in the result state so the hero is intrinsic-height
    // and the freed space below flows to the taller analysis lane (no gap under
    // "Elapsed"). The call site (`heroFillsPane`) fills the pane only in the
    // analyzing / error states, centering their transient text; the empty
    // prompt is intrinsic.
    .frame(maxWidth: .infinity, alignment: .topTrailing)
  }

  @ViewBuilder
  private func secondaryMetadataRow(_ value: String) -> some View {
    Text(value).monospacedDigit()
  }
}

/// The `(?)` help button shown beside the "Refine grid tempo" toggle. Self-
/// contained (owns its popover state + plain-language content), mirroring the
/// chrome of `BeatGridHelpButton` / `LoudnessHelpButton` — this option is a
/// plain `Options` flag, not a documented library case, so it does not use the
/// authored-docs `HelpButton`.
struct RefineGridTempoHelpButton: View {
  @State private var showHelp = false

  var body: some View {
    Button {
      showHelp.toggle()
    } label: {
      Image(systemName: "questionmark.circle")
    }
    .buttonStyle(.borderless)
    .controlSize(.small)
    .help("What does refining the grid tempo do?")
    .accessibilityLabel("Refine grid tempo help")
    .accessibilityHint("Explains how the beat grid maps to detected onsets")
    .popover(isPresented: $showHelp, arrowEdge: .bottom) {
      helpBody
        .padding()
        .frame(width: 360)
    }
  }

  @ViewBuilder
  private var helpBody: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Refine grid tempo")
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
      Text(
        "Map the beat grid to the onsets detected in the track. The headline BPM shown above "
          + "stays unchanged.")
      Text(
        "Assumes a constant tempo. Re-runs the current analysis when a file is loaded."
      )
      .foregroundStyle(.secondary)
    }
    .font(.callout)
    .fixedSize(horizontal: false, vertical: true)
  }
}
