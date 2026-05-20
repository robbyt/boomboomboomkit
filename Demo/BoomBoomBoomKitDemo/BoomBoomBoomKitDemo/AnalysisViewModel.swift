import BoomBoomBoomKit
import Foundation
import Observation
import Synchronization

@MainActor
@Observable
final class AnalysisViewModel {

  // Default-internal access; the demo test target reaches the type via
  // `@testable import BoomBoomBoomKitDemo` (AC #3 permits @testable for
  // demo-target-internal tests; the no-@testable discipline applies to
  // library internals only, not the demo's own first-party consumer).
  init() {}

  // Lowercased filename-extension whitelist used by `validateDropPayload`
  // (Story 5-2 DD #2). Switched from `UTType.conforms(to:)` to
  // extension-matching per Codex H5 — `.m4b` / `.mp4` conform to
  // `.mpeg4Audio` and would have silently widened the supported set.
  // The 6 entries map 1:1 to `PCMBufferReader`'s decoder list.
  static let supportedExtensions: Set<String> = [
    "wav", "aiff", "mp3", "flac", "m4a", "caf",
  ]

  // Drop-validation failure cases (Story 5-2 DD #11). INTERNAL access
  // (not private) so demo tests can pattern-match via `@testable import`.
  // Conforms to `Error` so it can be used as the failure type in
  // `Result<URL, DropError>` (Swift requires the Failure type to be
  // `Error`-conforming).
  enum DropError: Error, Equatable {
    case empty
    case multipleFiles
    case unsupportedType(extension: String)
  }

  // Observed state — populated post-analysis, drives UI.
  var fileName: String?
  var detectedBPM: Double?
  var confidence: Double?
  var effectiveIntensity: AnalysisIntensity?
  var elapsedSeconds: Double?
  var errorMessage: String?
  var isAnalyzing: Bool = false

  // Story 5-2 DD #6 — observed Set of task UUIDs awaiting cancellation
  // acknowledgement. The @Observable macro tracks mutations on this stored
  // property, so SwiftUI re-renders the "Cancelling previous analysis…"
  // copy via the derived `isCancelling` property. A `Bool` could not model
  // the multi-task draining scenario (rapid drops leave N-2 cancelled
  // tasks polling while N is launching — a single Bool toggles wrong).
  var pendingCancellations: Set<UUID> = []

  // Derived from `pendingCancellations`; @Observable invalidates the view
  // when the underlying set mutates because the computed property reads
  // the tracked stored property (Story 5-2 DD #6).
  var isCancelling: Bool { !pendingCancellations.isEmpty }

  // Operational state — NOT for display, NOT for trace JSON export.
  // Story 5-3 reads this to re-run analysis on the same file when
  // intensity/merge-strategy changes. Story 5-4 MUST NOT export it
  // into trace JSON (sandbox-leaky, non-portable). Per DD #16-D.
  private(set) var selectedFileURL: URL?

  // Story 5-2 DD #5 — per-task UUID discriminator. Reassigned on every
  // `analyze(url:autoStarted:)` call; the Task body's MainActor-re-entry
  // gates observed-state writes on `currentTaskID == taskID` so a
  // superseded task does NOT clobber the successor's UI state, and a
  // user-cancelled current task correctly resets `isAnalyzing = false`.
  // @ObservationIgnored: operational state, never read by a view
  // (Story 5-1 PP8 pattern).
  @ObservationIgnored
  private var currentTaskID: UUID?

  // Story 5-2 — keyed by per-task UUID so the cancel-all-prior cascade
  // can look up each prior task's UUID for insertion into
  // `pendingCancellations` before calling `task.cancel()`. Replaces
  // Story 5-1's `Set<Task<Void, Never>>` form. @ObservationIgnored
  // because this is operational state, never read by a view (PR #3
  // Copilot review 2026-05-19, Story 5-1 PP8 pattern).
  @ObservationIgnored
  private var inFlightTasks: [UUID: Task<Void, Never>] = [:]

  // Single Options bag — Story 5-3 mutates this from sliders/pickers.
  // Default is the library default; Story 5-2 does not surface controls.
  var options: AudioAnalysisService.Options = .init()

  // Entry point — invoked by `handleDrop` (window-drop, autoStarted=false)
  // and `handleOpenURL` (LaunchServices document-open, autoStarted=true).
  // Synchronous signature (no async); launches an internal Task so the
  // caller doesn't await. Cancellation semantics: a newer call
  // supersedes the prior one (DD #16-E from Story 5-1).
  //
  // - Parameters:
  //   - url: the audio file URL to analyze.
  //   - autoStarted: `true` when the URL arrives via `.onOpenURL` (Dock
  //     drop / Finder Open With / `open -a`) — the system has already
  //     called `startAccessingSecurityScopedResource()` on this URL per
  //     `axiom-macos/skills/sandbox-and-file-access.md:301-311`; the
  //     defer must call `stop` to release kernel resources, but NOT
  //     call `start` itself. `false` (the default) for window-drops
  //     from SwiftUI `.dropDestination(for: URL.self)`; defensive
  //     `start` + balanced `stop` discipline. See DD #4.
  func analyze(url: URL, autoStarted: Bool = false) {
    // Mint a fresh per-task UUID (DD #5). The Task body's MainActor
    // re-entry path uses this ID to disambiguate "superseded by newer
    // analyze() call" (return without state mutation) from "current task
    // completed / cancelled by user" (reset isAnalyzing = false).
    let taskID = UUID()

    // DD #16-E: cancel EVERY in-flight prior analysis before launching a
    // new one. The cascade inserts each prior task's UUID into
    // `pendingCancellations` BEFORE invoking `task.cancel()` (DD #6) so
    // the "Cancelling previous analysis…" copy renders during the
    // multi-second window-boundary cancel propagation (W17 close).
    for (priorTaskID, prior) in inFlightTasks {
      pendingCancellations.insert(priorTaskID)
      prior.cancel()
    }

    // Make this the current task BEFORE launching — the Task body's
    // re-entry compares against `currentTaskID` to detect supersession.
    currentTaskID = taskID

    // DD #16-D: split exposed/operational state.
    selectedFileURL = url
    fileName = url.lastPathComponent

    isAnalyzing = true
    errorMessage = nil
    detectedBPM = nil
    confidence = nil
    effectiveIntensity = nil
    elapsedSeconds = nil

    // Security-scoped resource bracket (DD #4). Two patterns per entry
    // point: window-drop (autoStarted=false) → defensive start with
    // didStart Bool gate; .onOpenURL (autoStarted=true) → no start, but
    // must stop (system auto-started per Axiom skill table at
    // sandbox-and-file-access.md:301-311). The defer below is INSIDE the
    // outer Task body so the bracket spans the ~1-30s DSP run, not the
    // synchronous prologue.
    let didStart: Bool = autoStarted ? false : url.startAccessingSecurityScopedResource()
    let shouldStop: Bool = autoStarted || didStart

    // Cancellation hand-off into the detached DSP work (D1 patch from
    // 2026-05-18 code review). Task.detached does NOT inherit cancellation
    // from its enclosing task, so the library's default
    // `Options.isCancelled = { Task.isCancelled }` would always read false
    // inside the detached task and the in-flight DSP pipeline would run to
    // completion on a stale URL. Atomic flag flipped by the outer Task's
    // cancellation handler; library polls it at window boundaries (ADR-1).
    // Acquire/release ordering pairs the cross-task store with the
    // library's polling load so the flag flip is observable across CPU
    // caches on weakly-ordered hardware (PP1 from 2026-05-19 review).
    let cancelFlag = Atomic<Bool>(false)
    var opts = options
    opts.isCancelled = { @Sendable in cancelFlag.load(ordering: .acquiring) }
    let started = ContinuousClock.now

    let task = Task { [weak self] in
      // Bracket discipline (DD #4). Fires on any exit path: success,
      // error, cancellation, or guard-let-self bailout.
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

      // DD #5: the inherited Story 5-1 `guard !Task.isCancelled` early
      // return is REMOVED here (Codex C1) — it made W1's stuck-true
      // reset unreachable. The body runs to the switch unconditionally;
      // observed-state writes are gated on `currentTaskID == taskID`.
      guard let self else { return }

      let elapsed = ContinuousClock.now - started
      let secs =
        Double(elapsed.components.seconds)
        + Double(elapsed.components.attoseconds) / 1e18

      // DD #5: handle CancellationError FIRST. If `currentTaskID ==
      // taskID`, the user cancelled the CURRENT task (deinit, scene
      // phase, or — Story 5-3 — an explicit Cancel button). Reset
      // `isAnalyzing = false`; leave `errorMessage` and result fields
      // untouched so the user sees the empty state, not stale data.
      // If NOT equal, this task was superseded by a newer analyze()
      // call; return without mutating any observed state (the
      // successor task owns the UI now).
      if case .failure(let error) = result, error is CancellationError {
        if self.currentTaskID == taskID {
          self.isAnalyzing = false
        }
        return
      }

      // All other arms gate observed-state writes on
      // `currentTaskID == taskID`. A superseded task returns without
      // touching state — the successor task owns the UI.
      guard self.currentTaskID == taskID else { return }

      switch result {
      case .success(let value?):
        // DD #16 case 1: clear any banner errorMessage from an invalid drop
        // that arrived during analysis. Without this, the red banner from
        // an intervening unsupported-type drop would persist past the
        // successful result render until the NEXT analyze() call cleared
        // it via the synchronous prologue at the top of `analyze(url:)`.
        self.errorMessage = nil
        self.detectedBPM = value.bpm
        self.confidence = value.confidence
        self.effectiveIntensity = value.effectiveIntensity
      case .success(nil):
        self.errorMessage =
          "No BPM detected (silence, too-short audio, or non-musical content)"
      case .failure(let error as PCMBufferReaderError):
        // AC #6: when sandbox refused to grant access AND the read
        // subsequently failed with `.fileNotReadable`, upgrade the
        // message so the user can tell "file doesn't exist" apart
        // from "sandbox denied". View-model-constructed template
        // (Codex M12) — NOT `String(describing: error)`.
        if case .fileNotReadable = error, !autoStarted, !didStart {
          self.errorMessage =
            "Could not read audio file: \(url.lastPathComponent) (sandbox denied)"
        } else {
          self.errorMessage = "Could not read audio file: \(url.lastPathComponent)"
        }
      case .failure(let error):
        // CancellationError was already handled above with an early
        // return; any remaining .failure is treated as an unexpected
        // library error.
        self.errorMessage = "Unexpected error: \(error)"
      }
      self.elapsedSeconds = secs
      self.isAnalyzing = false
    }

    inFlightTasks[taskID] = task

    // Self-cleanup: await this task's completion and remove it from the
    // in-flight dict AND from `pendingCancellations` so `isCancelling`
    // flips false once all draining tasks have acknowledged. Fire-and-
    // forget — the cleanup Task captures `task` strongly so the awaited
    // handle stays valid; once the task body returns, the cleanup body
    // runs on MainActor (inherited isolation) and removes its entries.
    // Bounded: one cleanup task per analyze() call.
    Task { [weak self] in
      _ = await task.value
      self?.inFlightTasks.removeValue(forKey: taskID)
      self?.pendingCancellations.remove(taskID)
    }
  }

  // MARK: - Drop Handling (Story 5-2)

  // Pure data validator for drop payloads — testable via @testable
  // import without constructing a view model (DD #11). Extension-based
  // filter per DD #2 (NOT UTType.conforms(to:) — `.m4b` / `.mp4` would
  // silently widen via `.mpeg4Audio` conformance, Codex H5).
  static func validateDropPayload(_ urls: [URL]) -> Result<URL, DropError> {
    switch urls.count {
    case 0:
      return .failure(.empty)
    case 1:
      let url = urls[0]
      let ext = url.pathExtension.lowercased()
      // Reject non-file URLs (http://, ftp://, etc.) — `.dropDestination(for:
      // URL.self)` can deliver web URLs from browsers; the analyzer only
      // reads file:// URLs via PCMBufferReader. Route to .unsupportedType
      // so the user sees a coherent message rather than a downstream
      // "Could not read audio file" with no diagnostic clarity.
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

  // SwiftUI window-drop entry point. Invoked from
  // `.dropDestination(for: URL.self)`'s closure. Returns the Bool the
  // drop API requires (true=accepted, false=rejected). On failure,
  // populates `errorMessage` per the AC #2 verbatim strings; on
  // success, kicks off `analyze(url:autoStarted: false)` so the
  // defensive security-scoped resource bracket is applied (DD #4).
  // Invalid drops do NOT cancel in-flight analysis (DD #16).
  @discardableResult
  func handleDrop(_ urls: [URL]) -> Bool {
    switch Self.validateDropPayload(urls) {
    case .failure(.empty):
      errorMessage = "No audio file detected in drop."
      return false
    case .failure(.multipleFiles):
      errorMessage = "Drop a single audio file (batch drop is not supported)."
      return false
    case .failure(.unsupportedType(let ext)):
      let displayExt = ext.isEmpty ? "(no extension)" : ext
      errorMessage =
        "Unsupported file type: \(displayExt). Supported: WAV, AIFF, MP3, FLAC, M4A, CAF."
      return false
    case .success(let url):
      analyze(url: url, autoStarted: false)
      return true
    }
  }

  // LaunchServices document-open entry point. Invoked from `.onOpenURL`
  // for Dock-icon drops, Finder "Open With", and `open -a` (DD #15).
  // Reuses `validateDropPayload` over a 1-element array; on success,
  // calls `analyze(url:autoStarted: true)` so the stop-only bracket
  // pattern is applied (the system has auto-started the URL).
  func handleOpenURL(_ url: URL) {
    switch Self.validateDropPayload([url]) {
    case .failure(.empty):
      // Shouldn't happen — .onOpenURL always delivers a URL.
      errorMessage = "No audio file detected in drop."
    case .failure(.multipleFiles):
      // Shouldn't happen — .onOpenURL is single-URL per Apple's contract.
      errorMessage = "Drop a single audio file (batch drop is not supported)."
    case .failure(.unsupportedType(let ext)):
      let displayExt = ext.isEmpty ? "(no extension)" : ext
      errorMessage =
        "Unsupported file type: \(displayExt). Supported: WAV, AIFF, MP3, FLAC, M4A, CAF."
    case .success:
      analyze(url: url, autoStarted: true)
    }
  }

  deinit {
    // Defensive cancellation backstop (PR #3 Copilot review 2026-05-19;
    // Codex thread 019e4257 validated the pattern). Cancels every
    // in-flight task when the view model deallocates — e.g., sheet
    // dismissal or multi-window close in Story 5-2+. Without this,
    // the detached DSP work continues to completion on a dead view,
    // wasting CPU and I/O. Plain non-isolated deinit is safe here:
    // Task<Void, Never> is Sendable and Task.cancel() is nonisolated,
    // so iteration of the dict from deinit on a @MainActor class
    // crosses no isolation boundary that would require an `isolated
    // deinit` (SE-0371, Swift 6.2+).
    for (_, task) in inFlightTasks {
      task.cancel()
    }
  }
}
