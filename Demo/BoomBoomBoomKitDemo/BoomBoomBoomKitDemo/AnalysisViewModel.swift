import AppKit
import BoomBoomBoomKit
import Foundation
import Observation
import Synchronization
import UniformTypeIdentifiers

@MainActor
@Observable
final class AnalysisViewModel {

  init() {}

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
      case .fileReadFailed(let filename, let sandboxDenied):
        if sandboxDenied {
          return "Could not read audio file: \(filename) (sandbox denied)"
        }
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

  // CRITICAL invariant: SwiftUI only re-renders when an OBSERVED property
  // mutates. `lastRunSnapshot` is @ObservationIgnored — always pair writes
  // to it with a write to an observed property in the same MainActor turn,
  // or readers will see stale snapshots.
  @ObservationIgnored
  var lastRunSnapshot: LastRunDiagnosticSnapshot?

  /// - Parameter autoStarted: `true` when the URL arrives via
  ///   `.onOpenURL` (Dock drop, Finder Open With, `open -a`) — the
  ///   system has already called `startAccessingSecurityScopedResource`
  ///   on this URL; the defer must `stop` but NOT `start`. `false`
  ///   (window-drop default) uses defensive start + balanced stop.
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

    let didStart: Bool = autoStarted ? false : url.startAccessingSecurityScopedResource()
    let shouldStop: Bool = autoStarted || didStart

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
    opts.isCancelled = { @Sendable in cancelFlag.load(ordering: .acquiring) }
    let started = ContinuousClock.now

    let task = Task { [weak self] in
      defer {
        if shouldStop {
          url.stopAccessingSecurityScopedResource()
        }
      }

      let result: Result<AudioAnalysisResult?, Error>
      do {
        let optsForDetached = opts
        let value = try await withTaskCancellationHandler {
          try await Task.detached { @Sendable in
            try AudioAnalysisService.analyzeBPM(url: url, options: optsForDetached)
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

      switch result {
      case .success(let value?):
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
      case .success(nil):
        self.error = .noBPMDetected
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
      case .failure(let other):
        self.error = .unexpected("\(other)")
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
  }

  // MARK: - Humanization

  // Space-separated lowercase rendering of `CandidateMergeStrategy` for
  // the result-row caption. UI-only — the exported JSON keeps the
  // rawValue verbatim.
  static func humanize(_ strategy: CandidateMergeStrategy) -> String {
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

  // MARK: - Parameter Controls

  // 4-line copy-pasteable Swift snippet reflecting (intensity,
  // mergeStrategy). The literal `yourURL` placeholder is deliberate —
  // the demo does NOT export real sandbox URLs into copy-paste content.
  // No leading whitespace, no trailing newline.
  static func generateConfigSnippet(
    intensity: AnalysisIntensity,
    mergeStrategy: CandidateMergeStrategy
  ) -> String {
    let intensityLiteral: String
    switch intensity.rawValue {
    case 1: intensityLiteral = ".fastest"
    case 7: intensityLiteral = ".default"
    case 8: intensityLiteral = ".thorough"
    case 10: intensityLiteral = ".maximum"
    default: intensityLiteral = "AnalysisIntensity(rawValue: \(intensity.rawValue))"
    }
    let line1 = "var opts = AudioAnalysisService.Options()"
    let line2 = "opts.intensity = \(intensityLiteral)"
    let line3 = "opts.mergeStrategy = .\(mergeStrategy.rawValue)"
    let line4 = "let result = try AudioAnalysisService.analyzeBPM(url: yourURL, options: opts)"
    return "\(line1)\n\(line2)\n\(line3)\n\(line4)"
  }

  // `clearContents()` BEFORE `setString` is mandatory per AppKit's
  // contract — without it, mixed-payload pasteboards retain stale data
  // of other types and text consumers pick the wrong representation.
  @discardableResult
  func copyConfigToPasteboard() -> Bool {
    let snippet = Self.generateConfigSnippet(
      intensity: options.intensity,
      mergeStrategy: options.mergeStrategy
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
    guard let snapshot = lastRunSnapshot else { return false }
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

  // NSSavePanel auto-starts security-scoped READ access via PowerBox;
  // the defer releases it on every exit path. WRITE capability is
  // gated by `com.apple.security.files.user-selected.read-write` —
  // without that entitlement the write fails with
  // `NSFileWriteNoPermissionError`.
  @discardableResult
  func exportTrace() -> Bool {
    guard let snapshot = lastRunSnapshot else { return false }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = Self.suggestedFilename(from: snapshot.fileName)
    panel.canCreateDirectories = true
    let response = panel.runModal()
    guard response == .OK, let url = panel.url else { return false }
    defer { url.stopAccessingSecurityScopedResource() }
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
