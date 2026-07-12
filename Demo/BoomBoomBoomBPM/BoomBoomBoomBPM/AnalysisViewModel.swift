import AppKit
import BoomBoomBoomKit
import BoomBoomBoomKitML
import Foundation
import Observation
import Synchronization
import UniformTypeIdentifiers

@MainActor
@Observable
final class AnalysisViewModel {

  // Injectable storage layer for the persisted merge-strategy
  // preference. Production callers pass nothing (`.live` defaults to
  // `UserDefaults.standard` + `.quorum` fallback); tests inject an
  // isolated `UserDefaults(suiteName:)` to avoid contaminating each
  // other or the operator's app prefs. Single-arg struct rather than a
  // bare `defaults` parameter so future prefs knobs land in the same
  // place without breaking the call sites.
  struct Configuration: Sendable {
    let defaults: UserDefaults
    let fallbackStrategy: BPMSelectionPolicy
    // First-launch ensemble preset (Story 9.1). `var` with a default so the
    // memberwise init keeps every pre-9.1 construction site compiling.
    var fallbackPreset: EnsemblePreset = .default

    static let live = Configuration(
      defaults: .standard,
      fallbackStrategy: .quorum,
      fallbackPreset: .default
    )
  }

  static let preferredMergeStrategyKey = "preferredMergeStrategy"
  static let preferredEnsemblePresetKey = "preferredEnsemblePreset"

  @ObservationIgnored
  private let configuration: Configuration

  /// Hydrate `options.mergeStrategy` from the configured UserDefaults
  /// BEFORE `ContentView.body` first renders, so the Picker shows the
  /// persisted value with no transient flash.
  ///
  /// Demo policy: when the stored value is absent, fall back to
  /// `configuration.fallbackStrategy` (`.quorum` for `.live`) without
  /// writing. When a value is present but unusable — a non-`String` type
  /// (`string(forKey:)` returns nil) or an unrecognized case
  /// (renamed/removed) — fall back AND remove the bad key, self-healing
  /// per the pre-1.0 framing in `CLAUDE.md`, so subsequent launches take
  /// the absent-key path cleanly. Presence is detected via
  /// `object(forKey:)` so a non-`String` poison value is healed rather
  /// than silently ignored on every launch.
  ///
  /// The library default at
  /// `AudioAnalysisService.Options.mergeStrategy` remains
  /// `.maxConfidence`; this seeding is demo-side only and MUST NOT
  /// leak into the library. SPM consumers receive the library default
  /// unless they opt in.
  init(
    configuration: Configuration = .live
  ) {
    self.configuration = configuration
    if configuration.defaults.object(forKey: Self.preferredMergeStrategyKey) == nil {
      // Genuinely absent (first launch) — seed the demo default, no write.
      options.mergeStrategy = configuration.fallbackStrategy
    } else if let rawValue = configuration.defaults.string(
      forKey: Self.preferredMergeStrategyKey
    ), let strategy = BPMSelectionPolicy(rawValue: rawValue) {
      options.mergeStrategy = strategy
    } else {
      // Present but unusable — a non-String type (`string(forKey:)` is nil)
      // or an unrecognized case (renamed/removed). Self-heal: remove the bad
      // key so future launches take the absent path, then fall back.
      configuration.defaults.removeObject(
        forKey: Self.preferredMergeStrategyKey
      )
      options.mergeStrategy = configuration.fallbackStrategy
    }

    // Ensemble preset (Story 9.1): same three-branch hydrate, same no-flash
    // rationale. The demo's first-launch preset is `Default` (the balanced
    // ensemble — the demo's job is proving the ensemble) and deliberately
    // diverges from the library default `Options.ensemblePolicy = .dspOnly`;
    // this seeding is demo-side only and MUST NOT leak into the library.
    // SPM consumers receive the library default unless they opt in.
    if configuration.defaults.object(forKey: Self.preferredEnsemblePresetKey) == nil {
      // Genuinely absent (first launch) — seed the demo default, no write.
      selectedEnsemblePreset = configuration.fallbackPreset
    } else if let rawValue = configuration.defaults.string(
      forKey: Self.preferredEnsemblePresetKey
    ), let preset = EnsemblePreset(rawValue: rawValue) {
      selectedEnsemblePreset = preset
    } else {
      // Present but unusable — a non-String type or an unrecognized case.
      // Self-heal: remove the bad key so future launches take the absent
      // path, then fall back.
      configuration.defaults.removeObject(
        forKey: Self.preferredEnsemblePresetKey
      )
      selectedEnsemblePreset = configuration.fallbackPreset
    }
  }

  /// Persist the current `options.mergeStrategy` to the configured
  /// UserDefaults. Called from `ContentView`'s
  /// `.onChange(of: viewModel.options.mergeStrategy)` so every Picker
  /// change survives quit/relaunch.
  func persistPreferredMergeStrategy() {
    configuration.defaults.set(
      options.mergeStrategy.rawValue,
      forKey: Self.preferredMergeStrategyKey
    )
  }

  /// Persist the current `selectedEnsemblePreset` case identifier to the
  /// configured UserDefaults. Called from `ContentView`'s
  /// `.onChange(of: viewModel.selectedEnsemblePreset)` so every picker
  /// change survives quit/relaunch (Story 9.1).
  func persistPreferredEnsemblePreset() {
    configuration.defaults.set(
      selectedEnsemblePreset.rawValue,
      forKey: Self.preferredEnsemblePresetKey
    )
  }

  // Extension-based whitelist used by `validateDropPayload`. NOT
  // `UTType.conforms(to:)` — `.m4b` / `.mp4` conform to `.mpeg4Audio`
  // and would silently widen the supported set beyond what
  // `PCMBufferReader` actually decodes.
  static let supportedExtensions: Set<String> = [
    "wav", "aiff", "mp3", "flac", "m4a", "caf",
  ]

  enum DropError: Error, Equatable {
    case empty
    case multipleFiles
    case unsupportedType(extension: String)
  }

  struct BPMResultRow: Equatable {
    let fileName: String
    let bpm: String
    let confidence: String
    let intensity: String
    let elapsed: String
  }

  // What the detached analysis task hands back: the combined BPM+grid result
  // (nil when there is no analyzable audio) plus the best-effort waveform
  // envelope (nil when the waveform decode failed — it must NOT fail the
  // analysis). Both pieces are Sendable so the value crosses the task boundary.
  private struct WaveformData: Sendable {
    let peaks: [Float]
    let duration: Double
  }
  private struct DetachedAnalysis: Sendable {
    let combined: CombinedAnalysisResult?
    let waveform: WaveformData?
    // Best-effort integrated-loudness report (Story 10.4), nil when LUFS was
    // not measured (a failure, thrown unsupportedSampleRate, nil return, or a
    // skipped cancelled run). `LUFSReport` is Sendable, so `DetachedAnalysis`
    // stays Sendable and crosses the task boundary clean.
    let lufs: LUFSReport?
  }

  // `.nonFinite` covers NaN/Inf AND out-of-range (bpm <= 0, confidence
  // outside [0, 1], elapsedSeconds < 0). `.missingFields` means partial
  // or never-run state; callers fall back to their own empty/error UI.
  enum FormatError: Error, Equatable {
    case missingFields
    case nonFinite
  }

  // Typed error displayed to the user. Replaces a raw `String?` so
  // category-driven logic (e.g. "clear stale clipboard error on
  // successful copy") can pattern-match on the case instead of
  // matching the display string. The display string is derived via
  // `LocalizedError.errorDescription`.
  enum AppError: LocalizedError, Equatable {
    case dropEmpty
    case dropMultiple
    case dropUnsupportedType(extension: String)
    case fileReadFailed(filename: String, sandboxDenied: Bool)
    case noBPMDetected
    case unexpected(String)
    case clipboardCopy
    case traceExport(detail: String)

    var errorDescription: String? {
      switch self {
      case .dropEmpty:
        return "No audio file detected in drop."
      case .dropMultiple:
        return "Drop a single audio file (batch drop is not supported)."
      case .dropUnsupportedType(let ext):
        let displayExt = ext.isEmpty ? "(no extension)" : ext
        return
          "Unsupported file type: \(displayExt). Supported: WAV, AIFF, MP3, FLAC, M4A, CAF."
      case .fileReadFailed(let filename, _):
        // sandboxDenied flag preserved on the error type (set by the heuristic
        // at :306) as a structural seam for the deferred classification
        // redesign — see 5-7 Review Findings 2026-05-24 §Deferred. UX copy
        // collapsed to a single truthful message until that redesign lands.
        return "Could not read audio file: \(filename)"
      case .noBPMDetected:
        return "No BPM detected (silence, too-short audio, or non-musical content)"
      case .unexpected(let detail):
        return "Unexpected error: \(detail)"
      case .clipboardCopy:
        return "Could not copy to clipboard"
      case .traceExport(let detail):
        return "Could not export trace JSON: \(detail)"
      }
    }
  }

  // Observed state — populated post-analysis, drives UI.
  var fileName: String?
  var detectedBPM: Double?
  var confidence: Double?
  var effectiveIntensity: AnalysisIntensity?
  var elapsedSeconds: Double?
  var error: AppError?
  var isAnalyzing: Bool = false

  /// Beat-grid + waveform overlay payload for the current result, or `nil` when
  /// no grid is available (pre-run, mid-run, no-BPM, or BPM-success-without-grid).
  /// One atomic value so the ContentView show-gate (`gridVisualization != nil`)
  /// flips without a partial render. Cleared at the analyze() prologue — UNLIKE
  /// `lastRunSnapshot`, a stale grid/waveform for the prior file is misleading
  /// while a new run is in flight.
  var gridVisualization: GridVisualizationState?

  /// Best-effort integrated-loudness report for the current result (Story 10.4),
  /// or `nil` when LUFS was not measured (silence, sub-400 ms input, an
  /// unsupported sample rate, a decode failure, or a superseded/cancelled run —
  /// all folded to `nil` by the best-effort `try?`). A plain observed `var`
  /// (Swift `Observation` auto-tracks it), NOT `@Published` (this class is
  /// `@Observable`). Committed in the SAME MainActor turn as `gridVisualization`
  /// on the success path, and cleared alongside it at every invalidate/failure/
  /// reset site — EXCEPT the BPM-success-without-grid arm, where it is
  /// deliberately RETAINED (loudness needs no beat grid; lifecycle, not textual
  /// coupling).
  var lufsReport: LUFSReport?

  /// The `maxSeconds` the LUFS measurement used, paired with `lufsReport` so
  /// `LoudnessGraphView.windowCaption` reports the analyzed window honestly
  /// (Story 10.4 DD7). Set and cleared in lockstep with `lufsReport`, in the
  /// same MainActor turn with no suspension between, so the window can never
  /// drift out of sync with its report.
  var lufsAnalysisWindowSeconds: Double?

  /// Display-layer convenience — derived from `error`. Read-only on
  /// purpose; producers assign the typed `error` case directly.
  var errorMessage: String? { error?.errorDescription }

  // Set rather than Bool — rapid drops leave N-2 prior tasks draining
  // while N is launching, so a single Bool toggles wrong.
  var pendingCancellations: Set<UUID> = []

  var isCancelling: Bool { !pendingCancellations.isEmpty }

  // Operational; not for display, not for trace JSON export.
  private(set) var selectedFileURL: URL?

  // Per-task UUID discriminator. The Task body gates observed-state
  // writes on `currentTaskID == taskID` so a superseded task does NOT
  // clobber the successor's UI, and a user-cancelled current task
  // correctly resets `isAnalyzing = false`.
  @ObservationIgnored
  private var currentTaskID: UUID?

  // Keyed by per-task UUID so the cancel-all-prior cascade can stage
  // each cancelled task's UUID into `pendingCancellations` before
  // calling `task.cancel()`.
  @ObservationIgnored
  private var inFlightTasks: [UUID: Task<Void, Never>] = [:]

  var options: AudioAnalysisService.Options = .init()

  // MARK: - Ensemble preset (Story 9.1)

  /// The active named ensemble preset (FR-36). The single source of the
  /// per-run `Options.ensemblePolicy` — `analyze()` derives the policy from
  /// this on every run. Stored + observed (deliberately NOT
  /// `@ObservationIgnored`, unlike the adjacent `configuration`): the
  /// primary-view picker binds to it. Hydrated in `init` before first
  /// render; the property default is overwritten there.
  var selectedEnsemblePreset: EnsemblePreset = .default

  // MARK: - BYOW ML (Epic 7 close-out; preset-governed since Story 9.1)
  // Bring-your-own-weights: load a compiled `.mlmodelc` and run it through
  // the production runtime path (`BNNSTechnique(modelURL:)` -> `analyzeBPM`).
  // How the model participates is governed by `selectedEnsemblePreset` —
  // weighted under `ML augmented`, short-circuited under `DSP only`. Default
  // off (no model, toggle off) keeps ML absent from the run entirely.

  /// Display name of the loaded model (the `.mlmodelc` last path component), or
  /// `nil` when no model is loaded.
  var mlModelName: String?

  /// When `true` (and a model is loaded), the model is attached to the run
  /// (`Options.mlTechnique`) and participates per the active preset's
  /// policy. Bound to the ContentView "Use loaded model" toggle; flipping it
  /// triggers a re-analyze. When `false`, ML is absent from the run while
  /// the preset stays selected and persisted.
  var mlEnabled: Bool = false

  /// Surfaces a model-load failure (e.g. raw `.mlmodel` instead of compiled
  /// `.mlmodelc`, or a tensor-contract mismatch) to the UI.
  var mlModelError: String?

  // The loaded technique. @ObservationIgnored — it is operational, not display
  // state; the observed `mlModelName`/`mlEnabled` drive the UI. `any MLTechnique`
  // (BNNSTechnique is @unchecked Sendable) so it crosses into the detached
  // analyze task on `options`.
  @ObservationIgnored
  private var mlTechnique: (any MLTechnique)?

  // CRITICAL invariant — DD #5 atomicity + DD #10 re-render coupling:
  // SwiftUI only re-renders when an OBSERVED property mutates. This
  // property is @ObservationIgnored, so every write MUST pair with a
  // same-MainActor-turn write to an observed property (e.g., `detectedBPM`,
  // `error`, `isAnalyzing`), or readers will see stale snapshots.
  // Reference write sites for the contract: success path at the post-
  // `value.trace != nil` arm (paired with `detectedBPM`/`confidence`/
  // `effectiveIntensity`); failure paths in `.success(nil)`/`.failure`
  // arms (paired with `self.error` + the shared `elapsedSeconds`/
  // `isAnalyzing = false` writes); and `clearPriorResult()` (paired with
  // `detectedBPM = nil`, etc.). P2 (code review 2026-05-23) confirmed
  // `private(set)` is the wrong access modifier here — it would block
  // `@testable import` mutation that the smoke tests rely on; the
  // atomicity contract is the load-bearing invariant, not the access
  // modifier.
  @ObservationIgnored
  var lastRunSnapshot: LastRunDiagnosticSnapshot?

  /// - Parameter autoStarted: `true` when the URL arrives via
  ///   `.onOpenURL` (Dock drop, Finder Open With, `open -a`); `false`
  ///   (window-drop default) for `.dropDestination`-delivered URLs.
  ///   The flag feeds the sandbox-denial heuristic (`!autoStarted
  ///   && !didStart` → `.fileReadFailed(sandboxDenied: true)`), but
  ///   `errorDescription` no longer surfaces the `sandboxDenied` bit
  ///   to the user (banner copy collapsed to the single
  ///   `"Could not read audio file: \(filename)"` message per the
  ///   2026-05-24 review pass — the heuristic over-classified
  ///   non-denial scenarios such as Re-analyze of LaunchServices URLs
  ///   and drops of virtualized cloud files). The flag is retained
  ///   purely as a structural seam for the deferred heuristic
  ///   redesign (see story 5-7 §Review Findings); do NOT re-wire it
  ///   into UX copy without re-doing the classification work first.
  ///   It does NOT gate the
  ///   `startAccessingSecurityScopedResource()` call — both paths
  ///   defensively call `start...` per Story 5-7 Carry-over Copilot C1.
  ///   Apple's contract: `start...` returns `true` for any security-
  ///   scoped URL (each call increments a per-process refcount that
  ///   must be balanced by a matching `stop`) and returns `false` for
  ///   non-scoped URLs. Typical LaunchServices-delivered URLs (`.onOpenURL`,
  ///   Finder Open With, `open -a`) are non-scoped file URLs — their
  ///   sandbox extension is kernel-vended, not scoped-URL-mediated — so
  ///   `start` returns `false` and no `stop` is needed. Drop-delivered
  ///   and bookmark-restored URLs are scoped; `start` returns `true` and
  ///   the defer-stop pairs with it. Calling `stop` without a matching
  ///   `start` (the pre-fix C1 / C2 imbalance) decrements the refcount
  ///   below baseline and can manifest as permission failures under
  ///   sustained use.
  func analyze(url: URL, autoStarted: Bool = false) {
    let taskID = UUID()

    // Cancel every prior in-flight analysis; stage each UUID into
    // pendingCancellations BEFORE calling cancel() so the "Cancelling
    // previous analysis…" copy renders during cancel propagation.
    for (priorTaskID, prior) in inFlightTasks {
      pendingCancellations.insert(priorTaskID)
      prior.cancel()
    }

    currentTaskID = taskID

    selectedFileURL = url
    fileName = url.lastPathComponent

    isAnalyzing = true
    error = nil
    detectedBPM = nil
    confidence = nil
    effectiveIntensity = nil
    elapsedSeconds = nil
    // Clear the grid overlay at the prologue (Codex review 019ee763 #1):
    // UNLIKE `lastRunSnapshot` (deliberately retained below to avoid a
    // gradient crossfade flash), a stale beat grid / waveform for the PRIOR
    // file is actively misleading while a new run is in flight. The fresh
    // result reassigns it atomically on success.
    gridVisualization = nil
    // LUFS (Story 10.4) rides the same prologue clear as the grid: a stale
    // loudness readout for the PRIOR file is misleading while a new run is in
    // flight. The fresh result reassigns both atomically on success.
    lufsReport = nil
    lufsAnalysisWindowSeconds = nil
    // F09 (Story 5-6 review): do NOT clear `lastRunSnapshot` at the
    // analyze() prologue. ContentView.backgroundStrategy reads
    // `lastRunSnapshot == nil ? nil : options.mergeStrategy`; clearing
    // here would flip the gradient to neutral mid-run and produce a
    // strategy→neutral→new-strategy crossfade instead of the AC #5
    // single strategy→new-strategy crossfade. Acceptable side-effect:
    // the inspector content shows the prior snapshot's TraceView during
    // in-progress analyze (Export Trace button is gated by
    // !viewModel.isAnalyzing at ContentView.swift:208 so stale export
    // remains unreachable via normal UI). `lastRunSnapshot` still
    // overwrites atomically when the new result arrives; the full
    // reset() helper at the end of this file still clears it on
    // explicit clear-state transitions.

    // Story 5-7 Carry-over Copilot C1 (deferred-work W43, addressed in
    // commit Story 5-7): defensive start/stop with refcount semantics.
    // The autoStarted path previously forced didStart=false but
    // shouldStop=true, calling stopAccessingSecurityScopedResource()
    // without a matching start... Apple's documented contract requires
    // every start to be balanced with one stop. Apple's `start...`
    // contract: returns true (refcount++) only for security-scoped URLs;
    // returns false for non-scoped URLs (typical LaunchServices delivery
    // — the sandbox extension is kernel-vended, not URL-mediated). The
    // defensive call is safe in either case: non-scoped → didStart=false
    // → no stop; scoped → didStart=true → defer-stop balances the
    // increment we just took.
    let didStart: Bool = url.startAccessingSecurityScopedResource()

    // Task.detached does NOT inherit cancellation, so the library's
    // default `Options.isCancelled = { Task.isCancelled }` would always
    // read false inside the detached body. Acquire/release ordering
    // pairs the cross-task store with the library's polling load on
    // weakly-ordered hardware.
    let cancelFlag = Atomic<Bool>(false)
    var opts = options
    // Demo-specific always-on trace capture. Override applied AFTER
    // the snapshot line to preserve snapshot-at-launch semantics and
    // remain idempotent against external mutation.
    opts.enableTrace = true
    // Beat-grid visualization: track the grid across the whole track (capped by
    // `Options.maxSeconds` — default 120 s, raised up to 600 s via the demo's
    // control) — the default `.analysisWindow` only covers ~30 s and leaves the
    // overlay sparse — and opt into downbeat detection (default off) so the
    // downbeat layer populates.
    opts.beatGridCoverage = .fullTrack
    opts.detectDownbeats = true
    // Story 9.1: the preset picker is the single writer of the per-run
    // ensemble policy — applied unconditionally so the effective policy
    // always value-equals the picker's resolved `EnsemblePolicy` (AC3),
    // including when a BYOW model is attached below.
    opts.ensemblePolicy = selectedEnsemblePreset.policy
    // BYOW ML (Epic 7; preset-governed since Story 9.1): when a model is
    // loaded AND the toggle is on, attach it — the preset's policy governs
    // how it participates (weighted under `ML augmented`, short-circuited
    // under `DSP only`). Toggle off (or no model) -> `mlTechnique` stays
    // nil and ML is absent from the run. enableMLDiagnostics surfaces the
    // decoded BPM / softmax on the trace.
    if mlEnabled, let technique = mlTechnique {
      opts.mlTechnique = technique
      opts.enableMLDiagnostics = true
    }
    opts.isCancelled = { @Sendable in cancelFlag.load(ordering: .acquiring) }
    let started = ContinuousClock.now

    let task = Task { [weak self] in
      defer {
        if didStart {
          url.stopAccessingSecurityScopedResource()
        }
      }

      let result: Result<DetachedAnalysis, Error>
      do {
        let optsForDetached = opts
        let value = try await withTaskCancellationHandler {
          try await Task.detached { @Sendable in
            // analyze() (not analyzeBPM) returns BPM + beat grid from ONE
            // shared decode; `combined.bpm` is the same AudioAnalysisResult the
            // hero already renders. URL path keeps file-metadata corroboration
            // + duration-hint live (the decoded: overload inerts them).
            let combined = try AudioAnalysisService.analyze(
              url: url, options: optsForDetached)
            // LUFS (Story 10.4) is best-effort and independent of the beat grid
            // in BOTH data source and failure handling: a thrown
            // unsupportedSampleRate, a read error, or a nil return MUST NOT fail
            // the analysis or perturb the BPM hero (mirrors the `try?` waveform
            // decode below). An added full decode is not free, so skip it
            // entirely — leaving `lufs == nil` — on an already-cancelled /
            // superseded run (the waveform pre-check pattern). Bounded to the
            // same `maxSeconds` window as the rest of the pipeline (LUFSOptions
            // has only `init()`, so `maxSeconds` is set by mutation).
            var lufsOptions = LUFSOptions()
            lufsOptions.maxSeconds = optsForDetached.maxSeconds
            // Thread the run's cancellation into the decode itself so a
            // superseded run bails at the service's checkpoints (before decode /
            // before measurement) instead of paying the full extra decode + O(n)
            // loudness pass — the added decode "is not free" (AC1). `try?` folds
            // the resulting CancellationError to nil, same as any other failure.
            lufsOptions.isCancelled = optsForDetached.isCancelled
            let lufs: LUFSReport? =
              optsForDetached.isCancelled()
              ? nil : (try? AudioAnalysisService.analyzeLUFS(url: url, options: lufsOptions))
            // A cancel can land after analyze() returns; skip the extra
            // (non-cancellation-polling) waveform decode so Cancel stays
            // responsive instead of paying a full decode that's discarded.
            if optsForDetached.isCancelled() { throw CancellationError() }
            // Waveform is best-effort: a decode failure must NOT fail the
            // analysis. Decode only when there is a grid to overlay, via the
            // library's own decoder so the waveform shares the grid's exact
            // decoded-PCM time origin / sample rate.
            var waveform: WaveformData?
            if combined?.beatGrid != nil,
              let wf = try? Waveform.decode(
                url: url, maxSeconds: optsForDetached.maxSeconds, columns: 2000)
            {
              waveform = WaveformData(peaks: wf.peaks, duration: wf.duration)
            }
            return DetachedAnalysis(combined: combined, waveform: waveform, lufs: lufs)
          }.value
        } onCancel: { @Sendable in
          cancelFlag.store(true, ordering: .releasing)
        }
        result = .success(value)
      } catch {
        result = .failure(error)
      }

      guard let self else { return }

      let elapsed = ContinuousClock.now - started
      let secs =
        Double(elapsed.components.seconds)
        + Double(elapsed.components.attoseconds) / 1e18

      // Cancellation gating: if the current task was cancelled, reset
      // isAnalyzing; if this task was superseded (currentTaskID
      // mismatch), return without touching state — the successor owns
      // the UI.
      if case .failure(let error) = result, error is CancellationError {
        if self.currentTaskID == taskID {
          self.isAnalyzing = false
        }
        return
      }

      guard self.currentTaskID == taskID else { return }

      // Codex review 019ee763 #3: a user cancel landing DURING/after the
      // (non-cancellation-polling) waveform decode leaves analyze() already
      // returned .success, so no CancellationError fires above. Re-check the
      // cancel flag before committing so a pure cancel never paints a stale
      // grid; mirror the CancellationError arm's isAnalyzing reset.
      if cancelFlag.load(ordering: .acquiring) {
        self.isAnalyzing = false
        return
      }

      switch result {
      case .success(let detached):
        if let combined = detached.combined {
          let value = combined.bpm
          // Clear any banner from an invalid drop that arrived during
          // analysis; without this it persists past the successful
          // render until the next analyze.
          self.error = nil
          self.detectedBPM = value.bpm
          self.confidence = value.confidence
          self.effectiveIntensity = value.effectiveIntensity
          // Snapshot written AFTER observed properties — SwiftUI re-render
          // is driven by the observed mutations; this @ObservationIgnored
          // write piggybacks on the same MainActor turn.
          if let trace = value.trace {
            self.lastRunSnapshot = LastRunDiagnosticSnapshot(
              trace: trace,
              metadataEvidence: value.metadataEvidence,
              runOptions: RunOptionsSnapshot(from: opts),
              fileName: url.lastPathComponent,
              result: value
            )
          }
          // BPM-success: surface the grid overlay when a grid was tracked. A
          // non-nil result with `beatGrid == nil` is BPM-success-without-grid
          // (hero renders, strip stays hidden) — NOT a no-BPM error.
          if let grid = combined.beatGrid {
            self.gridVisualization = GridVisualizationState(
              beatGrid: grid,
              peaks: detached.waveform?.peaks ?? [],
              duration: detached.waveform?.duration ?? 0,
              bpmTempo: value.bpm,
              // The analyzed file, carried atomically so the timeline scrubber loads
              // audio keyed to THIS result (Story 10.3 DD5/F4).
              sourceURL: url
            )
          } else {
            self.gridVisualization = nil
          }
          // LUFS (Story 10.4): committed in the SAME MainActor turn as the grid,
          // after the request/cancellation guard, no suspension between — so an
          // obsolete report can never be published. `opts.maxSeconds` equals the
          // `optsForDetached.maxSeconds` passed to the LUFS decode (a value copy,
          // no drift). RETAINED even on the BPM-success-without-grid arm above:
          // loudness needs no beat grid (lifecycle, not textual coupling).
          self.lufsReport = detached.lufs
          // Lockstep with the report: on BPM-success-but-LUFS-nil (e.g. an
          // LUFS-unsupported sample rate that BPM still handled) the window is
          // nil'd too, so the pair is never (nil, 120). `opts.maxSeconds` equals
          // the `optsForDetached.maxSeconds` the decode used (a value copy).
          self.lufsAnalysisWindowSeconds = detached.lufs != nil ? opts.maxSeconds : nil
        } else {
          // No analyzable audio (silence, too-short, or non-musical content).
          self.error = .noBPMDetected
          // P_D4 / D4 resolution (Codex thread 019e5812-5ce7-7840-9aae-4825dccd98ab):
          // failure / no-BPM arms must clear the prior snapshot so the
          // inspector + Export Trace button reflect the absence of a fresh
          // result. clearPriorResult() is guarded by !isAnalyzing and
          // would no-op here; the explicit nil-write at this terminal
          // point is the smallest fix for the stuck-snapshot case without
          // touching the DD #5 atomicity contract (snapshot rides with
          // the observed-state writes — `self.error` above + the shared
          // `self.elapsedSeconds`/`self.isAnalyzing = false` below — in
          // the same MainActor turn per DD #10).
          self.lastRunSnapshot = nil
          self.gridVisualization = nil
          self.lufsReport = nil
          self.lufsAnalysisWindowSeconds = nil
        }
      case .failure(let readerError as PCMBufferReaderError):
        let sandboxDenied: Bool
        if case .fileNotReadable = readerError, !autoStarted, !didStart {
          sandboxDenied = true
        } else {
          sandboxDenied = false
        }
        self.error = .fileReadFailed(
          filename: url.lastPathComponent,
          sandboxDenied: sandboxDenied
        )
        self.lastRunSnapshot = nil  // P_D4 — see comment in no-audio arm
        self.gridVisualization = nil
        self.lufsReport = nil
        self.lufsAnalysisWindowSeconds = nil
      case .failure(let other):
        self.error = .unexpected("\(other)")
        self.lastRunSnapshot = nil  // P_D4 — see comment in no-audio arm
        self.gridVisualization = nil
        self.lufsReport = nil
        self.lufsAnalysisWindowSeconds = nil
      }
      self.elapsedSeconds = secs
      self.isAnalyzing = false
    }

    inFlightTasks[taskID] = task

    // Per-analyze cleanup task: awaits this analyze's task and removes
    // its entries from inFlightTasks + pendingCancellations once the
    // body returns.
    Task { [weak self] in
      _ = await task.value
      self?.inFlightTasks.removeValue(forKey: taskID)
      self?.pendingCancellations.remove(taskID)
    }
  }

  // MARK: - Drop Handling

  static func validateDropPayload(_ urls: [URL]) -> Result<URL, DropError> {
    switch urls.count {
    case 0:
      return .failure(.empty)
    case 1:
      let url = urls[0]
      let ext = url.pathExtension.lowercased()
      // Reject non-file URLs (http://, ftp://); `.dropDestination(for:
      // URL.self)` can deliver browser URLs that PCMBufferReader can't
      // read. Route to unsupportedType for a coherent message.
      guard url.isFileURL else {
        return .failure(.unsupportedType(extension: ext))
      }
      if supportedExtensions.contains(ext) {
        return .success(url)
      }
      return .failure(.unsupportedType(extension: ext))
    default:
      return .failure(.multipleFiles)
    }
  }

  // SwiftUI window-drop entry point. Returns the Bool the drop API
  // requires (true=accepted, false=rejected). Invalid drops do NOT
  // cancel in-flight analysis (the prior run continues), but DO clear
  // the prior result + snapshot so the inspector and Export Trace
  // button don't keep advertising stale data alongside an error banner.
  @discardableResult
  func handleDrop(_ urls: [URL]) -> Bool {
    switch Self.validateDropPayload(urls) {
    case .failure(.empty):
      error = .dropEmpty
      clearPriorResult()
      return false
    case .failure(.multipleFiles):
      error = .dropMultiple
      clearPriorResult()
      return false
    case .failure(.unsupportedType(let ext)):
      error = .dropUnsupportedType(extension: ext)
      clearPriorResult()
      return false
    case .success(let url):
      analyze(url: url, autoStarted: false)
      return true
    }
  }

  // LaunchServices document-open entry point (`.onOpenURL`). Reuses
  // `validateDropPayload`; the empty / multipleFiles arms shouldn't
  // happen per Apple's contract but are handled defensively.
  func handleOpenURL(_ url: URL) {
    switch Self.validateDropPayload([url]) {
    case .failure(.empty):
      error = .dropEmpty
      clearPriorResult()
    case .failure(.multipleFiles):
      error = .dropMultiple
      clearPriorResult()
    case .failure(.unsupportedType(let ext)):
      error = .dropUnsupportedType(extension: ext)
      clearPriorResult()
    case .success:
      analyze(url: url, autoStarted: true)
    }
  }

  // Wipe prior-run observed state and the trace snapshot so the
  // inspector + Export Trace button don't advertise a result that no
  // longer corresponds to a real run. Skipped while an analysis is in
  // flight: the running task captures `url` in its closure and will
  // write fresh state into the view model when it succeeds, so
  // clearing here would race with that and leave `selectedFileURL` /
  // `fileName` nil under a populated snapshot (no Re-analyze button,
  // result row renders File: —).
  private func clearPriorResult() {
    guard !isAnalyzing else { return }
    selectedFileURL = nil
    fileName = nil
    detectedBPM = nil
    confidence = nil
    effectiveIntensity = nil
    elapsedSeconds = nil
    lastRunSnapshot = nil
    gridVisualization = nil
    lufsReport = nil
    lufsAnalysisWindowSeconds = nil
  }

  // MARK: - Humanization

  // Space-separated lowercase rendering of `BPMSelectionPolicy` for
  // the result-row caption. UI-only — the exported JSON keeps the
  // rawValue verbatim.
  static func humanize(_ strategy: BPMSelectionPolicy) -> String {
    switch strategy {
    case .maxConfidence: return "max confidence"
    case .dedup: return "dedup"
    case .quorum: return "quorum"
    case .average: return "average"
    case .median: return "median"
    case .weightedAverage: return "weighted average"
    case .union: return "union"
    case .windowVoting: return "window voting"
    }
  }

  // One-line description of a merge strategy for the demo's dynamic help line,
  // mirroring the ensemble preset's description. Verified against
  // `BPMSelectionPolicy.merge`: these policies aggregate candidate SCORES
  // within 2% BPM clusters, not the BPM values themselves.
  static func strategyDescription(_ strategy: BPMSelectionPolicy) -> String {
    switch strategy {
    case .maxConfidence: return "Uses the highest-confidence window result."
    case .dedup: return "Clusters near-match BPMs, keeping each cluster's best score."
    case .quorum: return "Ranks BPM clusters by how many windows contributed."
    case .average: return "Ranks BPM clusters by average candidate score."
    case .median: return "Ranks BPM clusters by median candidate score."
    case .weightedAverage:
      return "Ranks BPM clusters by confidence-weighted candidate score."
    case .union: return "Pools all candidates without deduplication, then sorts by score."
    case .windowVoting:
      return "Votes by each window's final BPM, falling back when no consensus forms."
    }
  }

  // Honest-degradation caption for the ensemble control (Story 9.1 DD7),
  // extracted as a pure function so it is unit-testable and so the view can
  // reserve two caption lines via `.lineLimit(2, reservesSpace:)`. Defined
  // behaviorally from observable state — returns "" when there is nothing to
  // warn about. `ML augmented` does nothing until a model is attached AND
  // enabled; `DSP only` short-circuits a loaded + enabled model.
  static func ensembleDegradationCaption(
    preset: EnsemblePreset,
    mlModelName: String?,
    mlEnabled: Bool
  ) -> String {
    switch preset {
    case .mlAugmented:
      if mlModelName == nil {
        return "No model loaded — ML signal is absent until you load one."
      } else if !mlEnabled {
        return "Model loaded but \"Use loaded model\" is off — ML signal is absent."
      }
      return ""
    case .dspOnly:
      if mlModelName != nil, mlEnabled {
        return "DSP only ignores the loaded model — ML signal is absent."
      }
      return ""
    default:
      return ""
    }
  }

  // MARK: - Parameter Controls

  // Copy-pasteable Swift snippet reflecting (intensity, mergeStrategy,
  // ensemblePreset — Story 9.1). Five lines for the DSP-only preset; the
  // three ML-invoking presets add a two-line `opts.mlTechnique` attach hint
  // before the analyze call (Story 9.1 deferred-work edge #4) so the copied
  // config reproduces the picker's run instead of silently abstaining ML.
  // The literal `yourURL` / `yourModelURL` placeholders are deliberate — the
  // demo does NOT export real sandbox URLs into copy-paste content. No
  // leading whitespace, no trailing newline.
  static func generateConfigSnippet(
    intensity: AnalysisIntensity,
    mergeStrategy: BPMSelectionPolicy,
    ensemblePreset: EnsemblePreset
  ) -> String {
    let intensityLiteral: String
    switch intensity.rawValue {
    case 1: intensityLiteral = ".fastest"
    case 7: intensityLiteral = ".default"
    case 8: intensityLiteral = ".thorough"
    case 10: intensityLiteral = ".maximum"
    default: intensityLiteral = "AnalysisIntensity(rawValue: \(intensity.rawValue))"
    }
    var lines = [
      "var opts = AudioAnalysisService.Options()",
      "opts.intensity = \(intensityLiteral)",
      "opts.mergeStrategy = .\(mergeStrategy.rawValue)",
      "opts.ensemblePolicy = \(ensemblePreset.policyLiteral)",
    ]
    // An ML-invoking policy is inert without a technique — the ML signal
    // records as absent and the copied config behaves like a DSP-weighted
    // run. Emit the attach hint so the paste matches what the picker did.
    if ensemblePreset.policy.invokesMLInference {
      lines.append(
        "// This preset uses the ML signal — attach a model "
          + "(needs import BoomBoomBoomKitML), or ML abstains:"
      )
      lines.append("opts.mlTechnique = try BNNSTechnique(modelURL: yourModelURL)")
    }
    lines.append(
      "let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)"
    )
    return lines.joined(separator: "\n")
  }

  // `clearContents()` BEFORE `setString` is mandatory per AppKit's
  // contract — without it, mixed-payload pasteboards retain stale data
  // of other types and text consumers pick the wrong representation.
  @discardableResult
  func copyConfigToPasteboard() -> Bool {
    let snippet = Self.generateConfigSnippet(
      intensity: options.intensity,
      mergeStrategy: options.mergeStrategy,
      ensemblePreset: selectedEnsemblePreset
    )
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    let didCopy = pasteboard.setString(snippet, forType: .string)
    if didCopy {
      // Clear only if the currently displayed error is our own — don't
      // stomp on a message produced by analyze() or a drop validator.
      if case .clipboardCopy = error {
        error = nil
      }
    } else {
      error = .clipboardCopy
    }
    return didCopy
  }

  // MARK: - BYOW Model Loading

  /// Construct and attach a `BNNSTechnique` for `url` — the model-load entry
  /// point (Story 10.2 Task 4), invoked from `ModelPickerView`'s "Use this model"
  /// (`ModelPickerView.addFromDisk` owns the `NSOpenPanel` flow). The construct
  /// is wrapped in ``BookmarkPersistence/withSecurityScopedAccess(to:perform:)``
  /// (DD9): restored bookmark URLs arrive with their security scope NOT started,
  /// and `BNNSTechnique.init` reads/compiles from disk. A freshly-picked
  /// `NSOpenPanel` URL is also scoped — `start...` returns `true` and the bracket
  /// balances the `stop`, so the same path serves both callers. On success the
  /// full quartet (`mlTechnique`/`mlModelName`/`mlEnabled`/`mlModelError`) is set
  /// via ``attachMLTechnique(_:named:)``; on failure ML is left disabled and
  /// `mlModelError` surfaces the reason.
  @discardableResult
  func loadModel(at url: URL) -> Bool {
    guard #available(macOS 15.0, *) else {
      mlModelError = "ML inference requires macOS 15 or later."
      return false
    }
    do {
      let technique = try BookmarkPersistence.withSecurityScopedAccess(to: url) {
        try BNNSTechnique(modelURL: url)
      }
      attachMLTechnique(technique, named: url.lastPathComponent)
      return true
    } catch {
      mlTechnique = nil
      mlModelName = nil
      mlEnabled = false
      mlModelError = "Could not load model: \(error)"
      return false
    }
  }

  /// Attach an already-constructed ML technique — the success block shared by
  /// `loadModel(at:)` (Story 9.1 DD3 testability seam). Sets the full success
  /// quartet: the toggle's visibility is gated on `mlModelName != nil`, so all
  /// four writes are load-bearing. The active preset's policy governs how the
  /// technique participates in the next run.
  func attachMLTechnique(_ technique: any MLTechnique, named name: String) {
    mlTechnique = technique
    mlModelName = name
    mlEnabled = true
    mlModelError = nil
  }

  // CRITICAL: MUST NOT reassign `currentTaskID`. The cancelled task
  // relies on `currentTaskID == taskID` to reset `isAnalyzing = false`
  // in the pure-Cancel case; a subsequent analyze() reassigns it so the
  // cancelled task sees the inequality and bails. Reassigning here
  // breaks the Cancel branch and leaves the activity indicator stuck.
  func cancelInFlight() {
    for (priorTaskID, prior) in inFlightTasks {
      pendingCancellations.insert(priorTaskID)
      prior.cancel()
    }
  }

  // `.nonFinite` covers NaN/Inf AND out-of-range; the library should
  // emit finite, in-range values or nil. `.missingFields` => partial
  // state — caller falls back to its empty/error UI.
  static func formatResultRow(
    fileName: String?,
    bpm: Double?,
    confidence: Double?,
    effectiveIntensity: AnalysisIntensity?,
    elapsedSeconds: Double?
  ) -> Result<BPMResultRow, FormatError> {
    guard let bpm,
      let confidence,
      let effectiveIntensity,
      let elapsedSeconds
    else {
      return .failure(.missingFields)
    }
    guard bpm.isFinite, bpm > 0,
      confidence.isFinite, (0.0...1.0).contains(confidence),
      elapsedSeconds.isFinite, elapsedSeconds >= 0
    else {
      return .failure(.nonFinite)
    }
    let row = BPMResultRow(
      fileName: fileName ?? "—",
      bpm: String(format: "%.1f BPM", bpm),
      confidence: String(format: "%.0f%%", confidence * 100),
      intensity: "\(effectiveIntensity.rawValue)",
      elapsed: String(format: "%.2fs", elapsedSeconds)
    )
    return .success(row)
  }

  // MARK: - Trace Export

  // Pure encode helper. Sorted keys + iso8601 dates for diff-friendly
  // output. Default `.nonConformingFloatEncodingStrategy = .throw`
  // means a stray non-finite Float/Double in the trace aborts the
  // encode loudly rather than emitting `"NaN"` / `"Infinity"` string
  // sentinels that strict-JSON consumers reject.
  static func encodeTrace(snapshot: LastRunDiagnosticSnapshot, elapsedSeconds: Double) throws
    -> Data
  {
    let export = TraceExport.from(
      trace: snapshot.trace,
      runOptions: snapshot.runOptions,
      result: snapshot.result,
      fileName: snapshot.fileName,
      metadataEvidence: snapshot.metadataEvidence,
      elapsedSeconds: elapsedSeconds
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(export)
  }

  // Strips the audio file extension and appends `-trace`. NO `.json`
  // suffix — `NSSavePanel.allowedContentTypes = [.json]` auto-appends
  // the extension; passing `"foo-trace.json"` would yield
  // `"foo-trace.json.json"` after user confirm.
  static func suggestedFilename(from fileName: String) -> String {
    let base = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
    return base.isEmpty ? "trace" : "\(base)-trace"
  }

  // Encodes the snapshot and writes atomically. Tests invoke this
  // directly with a deliberately-unwritable URL to cover the write-
  // error branch without driving NSSavePanel.
  @discardableResult
  func writeTraceJSON(to url: URL) -> Bool {
    // P3 (code review 2026-05-23): surface a banner on the silent
    // nil-snapshot path so a future programmatic / scripted caller
    // (or a snapshot-clear race interleaving between view re-render
    // and the user-initiated tap) sees feedback instead of a silent
    // `false`. NSSavePanel-driven UI flow gates visibility on
    // `lastRunSnapshot != nil`, so this is defensive.
    guard let snapshot = lastRunSnapshot else {
      error = .traceExport(detail: "no snapshot available to export")
      return false
    }
    // P3: NSSavePanel always hands back a file:// URL, but tests +
    // future programmatic callers can pass anything. data.write(to:)
    // with a non-file URL throws a misleading "unsupported URL"
    // error from Foundation; surface a clear demo-side message
    // instead.
    guard url.isFileURL else {
      error = .traceExport(detail: "invalid destination URL scheme — expected file://")
      return false
    }
    let data: Data
    do {
      data = try Self.encodeTrace(
        snapshot: snapshot,
        elapsedSeconds: elapsedSeconds ?? 0
      )
    } catch let encodeError {
      error = .traceExport(detail: encodeError.localizedDescription)
      return false
    }
    do {
      try data.write(to: url, options: .atomic)
      // Clear only if the currently displayed error is our own; don't
      // stomp on a message from analyze() or a drop validator.
      if case .traceExport = error {
        error = nil
      }
      return true
    } catch let writeError {
      error = .traceExport(detail: writeError.localizedDescription)
      return false
    }
  }

  // NSSavePanel-returned URLs are PowerBox-granted security-scoped URLs:
  // start...() returns true (refcount++) and the matching stop must run.
  // Story 5-7 Carry-over Copilot C2 (deferred-work W44, addressed in
  // commit Story 5-7): prior code called stop... without a matching
  // start..., underflowing the sandbox extension's refcount on every
  // save. Under sustained use that can manifest as later saves denying
  // write with NSFileWriteNoPermissionError despite the read-write
  // entitlement. The defensive pattern (capture didStart, defer-stop
  // on `if didStart`) repairs the imbalance — and the `if didStart`
  // guard also covers the rare case where the URL is non-scoped (start
  // returns false; no stop needed). WRITE capability is gated by
  // `com.apple.security.files.user-selected.read-write` — without that
  // entitlement the write fails with `NSFileWriteNoPermissionError`.
  @discardableResult
  func exportTrace() -> Bool {
    // P3 (code review 2026-05-23): surface a banner on the silent
    // nil-snapshot path so a user click race (button visible, then
    // snapshot cleared by a fresh analyze starting via .onOpenURL
    // before the tap lands) leaves a clear diagnostic instead of
    // a silent no-op. The button visibility predicate normally gates
    // this, but the gap window exists.
    guard let snapshot = lastRunSnapshot else {
      error = .traceExport(detail: "no snapshot available to export")
      return false
    }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = Self.suggestedFilename(from: snapshot.fileName)
    panel.canCreateDirectories = true
    let response = panel.runModal()
    guard response == .OK, let url = panel.url else { return false }
    let didStart = url.startAccessingSecurityScopedResource()
    defer {
      if didStart {
        url.stopAccessingSecurityScopedResource()
      }
    }
    return writeTraceJSON(to: url)
  }

  deinit {
    // Cancels in-flight DSP work when the view model deallocates so
    // detached tasks don't run to completion on a dead view. Plain
    // non-isolated deinit is safe: Task<Void, Never> is Sendable and
    // Task.cancel() is nonisolated.
    for (_, task) in inFlightTasks {
      task.cancel()
    }
  }
}
