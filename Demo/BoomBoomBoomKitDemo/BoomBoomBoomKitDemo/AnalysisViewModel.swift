import BoomBoomBoomKit
import Foundation
import Observation
import Synchronization
import UniformTypeIdentifiers

@MainActor
@Observable
final class AnalysisViewModel {

  // Default-internal access; the demo test target reaches the type via
  // `@testable import BoomBoomBoomKitDemo` (AC #3 permits @testable for
  // demo-target-internal tests; the no-@testable discipline applies to
  // library internals only, not the demo's own first-party consumer).
  init() {}

  // CAF + FLAC UTI helpers — Apple's public UTType catalog has no .caf or
  // .flac constants (verified at build time 2026-05-18; the spec listed
  // .flac as a constant but the compiler rejected it, applying the same
  // DD #16 pattern). Named helpers localize the unavoidable force-unwrap.
  private static let cafUTType = UTType("com.apple.coreaudio-format")!
  private static let flacUTType = UTType("org.xiph.flac")!

  // Whitelist matching PCMBufferReader's supported formats verbatim per
  // DD #16-B. NOT [.audio] parent — that would accept OGG which the
  // library does not support. Story 5-2's drop handler reads this;
  // Story 5-1 declares but does not yet use it.
  static let supportedAudioContentTypes: [UTType] = [
    .wav, .aiff, .mp3, flacUTType, .mpeg4Audio, cafUTType,
  ]

  // Observed state — populated post-analysis, drives UI in Story 5-2+.
  var fileName: String?
  var detectedBPM: Double?
  var confidence: Double?
  var effectiveIntensity: AnalysisIntensity?
  var elapsedSeconds: Double?
  var errorMessage: String?
  var isAnalyzing: Bool = false

  // Operational state — NOT for display, NOT for trace JSON export.
  // Story 5-3 reads this to re-run analysis on the same file when
  // intensity/merge-strategy changes. Story 5-4 MUST NOT export it
  // into trace JSON (sandbox-leaky, non-portable). Per DD #16-D.
  private(set) var selectedFileURL: URL?

  // Latest-selection-wins cancellation per DD #16-E. Each analyze(url:)
  // call cancels ALL in-flight prior tasks before launching its own
  // (D5 patch from 2026-05-19 code review pass 2 — fixes the cascade
  // leak where N-2 prior detached tasks each captured their own
  // cancelFlag and could not be reached by a single-handle cancel).
  // Tasks self-remove from this set via a separate awaiting Task when
  // they complete. @ObservationIgnored because this is operational
  // state, never read by a view — observation tracking would be noise
  // (PR #3 Copilot review 2026-05-19, plan section 1a).
  @ObservationIgnored
  private var inFlightTasks: Set<Task<Void, Never>> = []

  // Single Options bag — Story 5-3 mutates this from sliders/pickers.
  // Default is the library default; Story 5-1 does not surface the field.
  var options: AudioAnalysisService.Options = .init()

  // Entry point — invoked by Story 5-2's drop handler.
  // Synchronous signature (no async); launches an internal Task so the
  // caller doesn't await. Cancellation semantics: a newer analyze(url:)
  // call supersedes the prior one (DD #16-E).
  func analyze(url: URL) {
    // DD #16-E: cancel EVERY in-flight prior analysis before launching a
    // new one. Each task's onCancel handler flips its own cancelFlag;
    // the library polls those flags at window boundaries and exits
    // cooperatively. The single-handle approach (analysisTask?.cancel())
    // could only reach the most recent task — N-2 earlier detached
    // tasks each held their OWN cancelFlag with no handle to flip them.
    // (D5 patch from 2026-05-19 code review pass 2.)
    for prior in inFlightTasks {
      prior.cancel()
    }

    // DD #16-D: split exposed/operational state.
    selectedFileURL = url
    fileName = url.lastPathComponent

    isAnalyzing = true
    errorMessage = nil
    detectedBPM = nil
    confidence = nil
    effectiveIntensity = nil
    elapsedSeconds = nil

    // Cancellation hand-off into the detached DSP work (D1 patch from
    // 2026-05-18 code review). Task.detached does NOT inherit cancellation
    // from its enclosing task, so the library's default
    // `Options.isCancelled = { Task.isCancelled }` would always read false
    // inside the detached task and the in-flight DSP pipeline would run to
    // completion on a stale URL. Atomic flag flipped by the outer Task's
    // cancellation handler; library polls it at window boundaries (ADR-1).
    // `@Sendable` annotations escape the project's default-MainActor
    // isolation so opts crosses cleanly into the detached task.
    // Acquire/release ordering pairs the cross-task store with the
    // library's polling load so the flag flip is observable across CPU
    // caches on weakly-ordered hardware (PP1 from 2026-05-19 review).
    let cancelFlag = Atomic<Bool>(false)
    var opts = options
    opts.isCancelled = { @Sendable in cancelFlag.load(ordering: .acquiring) }
    let started = ContinuousClock.now

    let task = Task { [weak self] in
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

      guard !Task.isCancelled, let self else { return }

      let elapsed = ContinuousClock.now - started
      let secs =
        Double(elapsed.components.seconds)
        + Double(elapsed.components.attoseconds) / 1e18

      switch result {
      case .success(let value?):
        self.detectedBPM = value.bpm
        self.confidence = value.confidence
        self.effectiveIntensity = value.effectiveIntensity
      case .success(nil):
        self.errorMessage =
          "No BPM detected (silence, too-short audio, or non-musical content)"
      case .failure(is CancellationError):
        return
      case .failure(let error as PCMBufferReaderError):
        self.errorMessage = "Could not read audio file: \(error)"
      case .failure(let error):
        self.errorMessage = "Unexpected error: \(error)"
      }
      self.elapsedSeconds = secs
      self.isAnalyzing = false
    }

    inFlightTasks.insert(task)

    // Self-cleanup: await this task's completion and remove it from the
    // in-flight set. Fire-and-forget — the cleanup Task captures `task`
    // strongly so the awaited handle stays valid; once the task body
    // returns, the cleanup body runs on MainActor (inherited isolation)
    // and removes its entry. Bounded: one cleanup task per analyze() call.
    Task { [weak self] in
      _ = await task.value
      self?.inFlightTasks.remove(task)
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
    // so iteration of the Set from deinit on a @MainActor class
    // crosses no isolation boundary that would require an `isolated
    // deinit` (SE-0371, Swift 6.2+).
    for task in inFlightTasks {
      task.cancel()
    }
  }
}
