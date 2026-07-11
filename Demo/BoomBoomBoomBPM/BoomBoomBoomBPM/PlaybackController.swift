import AVFoundation
import Foundation
import Observation

/// The audio-playback backing the ``BeatGridTimelineView`` scrubber depends on
/// (Story 10.3). A protocol, not `AVAudioPlayer` directly, so ``PlaybackController``
/// is CI-testable with a deterministic fake: the pure state transitions (`isPlaying`,
/// the load-failure path, the generation guard) never need real audio
/// hardware or a decodable file. The production implementation is
/// ``AVAudioPlayerEngine``; tests inject their own.
///
/// `currentTime` is get/set: the `set` lets ``PlaybackController`` reset the playhead
/// (e.g. `handleFinish` returns it to `0`). `duration` may legitimately be `0` transiently
/// (unknown/short); the timeline never trusts it as the span (see ``BeatGridTimelineView``
/// span logic).
@MainActor
protocol AudioPlaybackEngine: AnyObject {
  var duration: Double { get }
  var currentTime: Double { get set }
  var isPlaying: Bool { get }
  /// Mirrors `AVAudioPlayer.play()` — returns `false` when playback could not start.
  @discardableResult func play() -> Bool
  func pause()
  func stop()
}

/// Production ``AudioPlaybackEngine`` over `AVAudioPlayer`. It OWNS the
/// `AVAudioPlayerDelegate` (Story 10.3 DD5/F5): when the track finishes it invokes
/// `onFinish` on the main actor tagged with the `generation` it was constructed
/// under, so ``PlaybackController`` can ignore a completion from a since-replaced
/// engine without ever `===`-comparing a concrete player it does not hold.
///
/// `@unchecked Sendable` mirrors the library `BNNSTechnique` precedent: the
/// `AVAudioPlayer` is only ever touched on the main actor (the delegate hop below
/// bounces straight back), but `AVAudioPlayerDelegate` conformance is a `nonisolated`
/// `NSObjectProtocol` requirement so the type cannot be a plain main-actor class.
final class AVAudioPlayerEngine: NSObject, AudioPlaybackEngine, AVAudioPlayerDelegate,
  @unchecked Sendable
{
  private let player: AVAudioPlayer
  // `generation` (`Int`) and `onFinish` (a `@Sendable` closure) are the only members the
  // `nonisolated` delegate callback reads — both immutable and `Sendable`, so a
  // nonisolated read is legal. `player` is deliberately NOT touched from the callback.
  private let generation: Int
  private let onFinish: @MainActor @Sendable (Int, Bool) -> Void

  /// - Throws: whatever `AVAudioPlayer(contentsOf:)` throws for an undecodable /
  ///   unreadable file. The caller (``PlaybackController/load(url:)``) maps a throw
  ///   to the no-audio + `playbackError` state.
  @MainActor
  init(url: URL, generation: Int, onFinish: @escaping @MainActor @Sendable (Int, Bool) -> Void)
    throws
  {
    self.player = try AVAudioPlayer(contentsOf: url)
    self.generation = generation
    self.onFinish = onFinish
    super.init()
    player.delegate = self
    player.prepareToPlay()
  }

  var duration: Double { player.duration }
  var currentTime: Double {
    get { player.currentTime }
    set { player.currentTime = newValue }
  }
  var isPlaying: Bool { player.isPlaying }

  @discardableResult func play() -> Bool { player.play() }
  func pause() { player.pause() }
  func stop() { player.stop() }

  // `AVAudioPlayerDelegate` is a `nonisolated` (Obj-C) requirement, so the callback
  // may arrive off the main actor. Hop back and forward the generation + success flag so
  // the controller applies it only if this engine is still current (F5 identity guard)
  // and can distinguish a clean end-of-track from a decode/interruption failure.
  nonisolated func audioPlayerDidFinishPlaying(
    _ player: AVAudioPlayer, successfully flag: Bool
  ) {
    let generation = self.generation
    let onFinish = self.onFinish
    Task { @MainActor in onFinish(generation, flag) }
  }
}

/// Owns the demo's audio playback so the ``BeatGridTimelineView`` scrubber has a live
/// clock (Story 10.3 — the demo's first playback substrate). `@MainActor @Observable`
/// (the demo's default isolation); `NSObject` for parity with the delegate-owning
/// engine, though the delegate itself lives on ``AVAudioPlayerEngine``.
///
/// ## Long-lived security scope (DD5)
/// `AVAudioPlayer` reads its file LAZILY during `play()`, so a short-lived
/// `withSecurityScopedAccess { AVAudioPlayer(contentsOf:) }` bracket would release the
/// sandbox scope before playback ever reads — working for a drag/dropped file (its
/// transient scope is still active) while silently failing for a restored-bookmark
/// URL. So this controller starts the scope on ``load(url:)`` and holds it for the
/// whole loaded-player lifetime, releasing it on replace / `load(nil)`. Deterministic
/// release is `load(nil)` (wired to `ContentView.onDisappear` + the nil-`sourceURL`
/// observer); `deinit` is a best-effort backstop over the `Sendable` scoped URL only —
/// a `@MainActor` `deinit` is `nonisolated` under Swift 6 and must not touch other
/// main-actor state (F3).
///
/// ## Result-paired load
/// `ContentView` drives ``load(url:)`` off `gridVisualization?.sourceURL` (the atomic
/// analysis payload), NOT the prologue `selectedFileURL`, so new audio never pairs
/// with the previous file's grid and every grid-clear stops playback (F4).
@MainActor
@Observable
final class PlaybackController: NSObject {

  /// Whether the backing engine reports it is playing.
  private(set) var isPlaying: Bool = false

  /// Loaded-file duration in seconds (`0` when no audio / unknown). The timeline does
  /// NOT use this as its span — the analyzed span (`.fullTrack` is `maxSeconds`-capped)
  /// is authoritative (DD6/F1); this is only the transport's own extent.
  private(set) var duration: Double = 0

  /// Whether an engine is currently loaded.
  private(set) var hasAudio: Bool = false

  /// Observable playhead snapshot in seconds (DD11). Written by ``pause()``, ``load(url:)``,
  /// and ``handleFinish(generation:successfully:)`` — the PAUSED-branch scrubber's only
  /// source. While PLAYING, the scrubber reads ``livePlayhead`` directly (a non-observed
  /// engine read driven by the view's `TimelineView(.animation)`), so this snapshot is not
  /// updated per frame. It exists so that when the animation branch is idle (paused / no
  /// audio) the scrubber still reads observable state and lands where playback stopped —
  /// a plain computed passthrough to `engine.currentTime` would not invalidate the view.
  private(set) var currentTime: Double = 0

  /// Labeled, FR-44-safe failure reason surfaced when a load fails (`nil` when clean).
  /// Cleared by a subsequent successful ``load(url:)``.
  private(set) var playbackError: String?

  @ObservationIgnored private var engine: (any AudioPlaybackEngine)?

  /// The URL whose security scope this controller currently holds, or `nil`. Retained
  /// so the scope can be released on replace / teardown. `Sendable`, so the `deinit`
  /// backstop can release it without touching main-actor state (F3).
  @ObservationIgnored private var scopedURL: URL?

  /// Monotonic load generation (F5). Bumped on every ``load(url:)``; the engine's
  /// end-of-track callback carries the generation it was built under and is applied
  /// only if it still equals this, so a completion from a replaced engine is inert.
  @ObservationIgnored private var generation: Int = 0

  /// Constructs the engine for a URL. Overridable seam (default = `AVAudioPlayer`); a
  /// throw is the documented undecodable/unauthorized path (→ `playbackError`).
  @ObservationIgnored
  private let makeEngine:
    @MainActor (
      _ url: URL, _ generation: Int, _ onFinish: @escaping @MainActor @Sendable (Int, Bool) -> Void
    )
      throws -> any AudioPlaybackEngine

  /// - Parameter makeEngine: engine factory; defaults to the `AVAudioPlayer`-backed
  ///   ``AVAudioPlayerEngine``. Tests inject a fake. **No I/O runs in `init`** (F7) —
  ///   the factory is only invoked from ``load(url:)`` — so a `ContentView` `@State`
  ///   default-init of this controller does not regress the 10.2 R3 catalog hoist.
  init(
    makeEngine:
      @escaping @MainActor (
        _ url: URL, _ generation: Int, _ onFinish: @escaping @MainActor (Int, Bool) -> Void
      ) throws -> any AudioPlaybackEngine = { url, generation, onFinish in
        try AVAudioPlayerEngine(url: url, generation: generation, onFinish: onFinish)
      }
  ) {
    self.makeEngine = makeEngine
    super.init()
  }

  /// Atomically replaces the loaded audio (DD5). One MainActor transition: stop + drop
  /// the old engine, **release the old scope before acquiring the new one** (so a
  /// same-URL re-entry cannot leak a refcounted grant, F6), clear state; then for a
  /// non-`nil` URL start its security scope, retain it, construct + prepare the engine,
  /// and publish the ready state. A construction throw lands in the no-audio state with
  /// a labeled `playbackError`. A `nil` URL is the deterministic teardown.
  func load(url: URL?) {
    // Tear down the old engine + scope first (idempotent; also the whole of `load(nil)`).
    engine?.stop()
    engine = nil
    isPlaying = false
    currentTime = 0
    duration = 0
    hasAudio = false
    if let previous = scopedURL {
      previous.stopAccessingSecurityScopedResource()
      scopedURL = nil
    }
    // Every load is a new generation, so a late completion from the old engine is inert.
    generation &+= 1

    guard let url else {
      playbackError = nil
      return
    }

    // Hold the scope for the player's LIFETIME (not just construction) — released on the
    // next `load` / `load(nil)` / deinit. A dropped file's transient scope makes `start`
    // return false yet still work; a restored-bookmark URL genuinely needs this grant.
    let started = url.startAccessingSecurityScopedResource()
    do {
      let generation = self.generation
      let newEngine = try makeEngine(url, generation) { [weak self] finishedGeneration, success in
        self?.handleFinish(generation: finishedGeneration, successfully: success)
      }
      engine = newEngine
      scopedURL = started ? url : nil
      duration = newEngine.duration
      hasAudio = true
      currentTime = 0
      playbackError = nil
    } catch {
      // Construction failed — release the scope we just took and surface a labeled reason.
      if started { url.stopAccessingSecurityScopedResource() }
      scopedURL = nil
      playbackError = "Reason: audio-load-failed"
    }
  }

  /// Starts playback if audio is loaded. `isPlaying` reflects the engine's own report
  /// (`AVAudioPlayer.play()`'s Bool), never a wished-for state. A successful (re)start
  /// clears a stale `playbackError` (e.g. a prior `playback-interrupted`) so the surfaced
  /// reason does not linger while audio plays again; a load failure keeps its error
  /// because `engine == nil` there and the guard returns first.
  func play() {
    guard let engine else { return }
    isPlaying = engine.play()
    if isPlaying { playbackError = nil }
  }

  func pause() {
    // Sync the observable snapshot to where playback stopped so the now-static (paused)
    // scrubber sits at the right spot — the playing branch reads `livePlayhead` per frame,
    // but the paused branch reads the observable `currentTime` (DD11/F2).
    if let engine { currentTime = engine.currentTime }
    engine?.pause()
    isPlaying = false
  }

  func togglePlayPause() {
    if isPlaying {
      pause()
    } else {
      play()
    }
  }

  func stop() {
    load(url: nil)
  }

  /// The live playhead, read directly from the engine every animation frame by the
  /// timeline's PLAYING branch (DD11). Non-observed (the engine is `@ObservationIgnored`)
  /// on purpose — `TimelineView(.animation)` drives the redraw cadence while playing, so
  /// the scrubber does not depend on observation there. Falls back to the observable
  /// `currentTime` snapshot when no engine is loaded. The PAUSED branch reads the
  /// observable `currentTime` instead, which `pause()` and `handleFinish` write (so it
  /// stays correct while the animation branch is idle).
  var livePlayhead: Double { engine?.currentTime ?? currentTime }

  /// End-of-track handler (from the engine's delegate). Applies only when the finishing
  /// engine is still current (generation guard, F5), settling to stopped-at-zero. An
  /// unsuccessful finish (`successfully == false` — a mid-track decode/interruption
  /// failure, not a clean end-of-track) surfaces a labeled `playbackError` so the stop is
  /// not a bare state (FR-44); `hasAudio` stays true (the file is still loaded).
  private func handleFinish(generation finishedGeneration: Int, successfully: Bool) {
    guard finishedGeneration == generation else { return }
    isPlaying = false
    currentTime = 0
    engine?.currentTime = 0
    if !successfully {
      playbackError = "Reason: playback-interrupted"
    }
  }

  // Best-effort scope release if the controller is torn down without a `load(nil)`
  // (F3). A `@MainActor` class's `deinit` is `nonisolated` under Swift 6, so it may
  // ONLY touch the `Sendable` scoped URL — never `engine`/`isPlaying`/other main-actor
  // state. `ContentView.onDisappear { load(nil) }` is the deterministic path; this is
  // the backstop.
  deinit {
    scopedURL?.stopAccessingSecurityScopedResource()
  }
}
