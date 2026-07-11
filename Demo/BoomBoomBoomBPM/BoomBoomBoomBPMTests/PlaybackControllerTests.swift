import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Deterministic, GUI-free, audio-free tests for the `PlaybackController` state
// machine via a fake `AudioPlaybackEngine` — load/teardown, play/pause, the seek
// clamp, the labeled error paths, and the generation guard. (Moved from the
// deleted BeatGridTimelineViewTests when the Story 10.3 UX rework merged the
// timeline into `BeatGridView`; the seek tests returned with `seek(to:)`, whose
// caller is now the view's click-to-scrub.)
@Suite("Playback controller")
struct PlaybackControllerTests {

  @Test("load populates hasAudio/duration; play reflects the engine")
  @MainActor
  func loadPlay() {
    let recorder = EngineRecorder()
    let controller = makeController(recorder: recorder)
    controller.load(url: url("a.wav"))

    #expect(controller.hasAudio)
    #expect(controller.duration.isApproximately(10))
    #expect(controller.currentTime.isApproximately(0))

    controller.play()
    #expect(controller.isPlaying)
  }

  @Test("play reflects an engine that refuses to start")
  @MainActor
  func playRespectsEngineFailure() {
    let controller = makeController(recorder: EngineRecorder(), playReturns: false)
    controller.load(url: url("a.wav"))
    controller.play()
    #expect(!controller.isPlaying)
  }

  @Test("load(nil) tears down to the no-audio state; seek is then a no-op")
  @MainActor
  func loadNilTearsDown() {
    let controller = makeController(recorder: EngineRecorder())
    controller.load(url: url("a.wav"))
    controller.play()
    controller.load(url: nil)
    #expect(!controller.hasAudio)
    #expect(!controller.isPlaying)
    #expect(controller.currentTime.isApproximately(0))
    controller.seek(to: 5)
    #expect(controller.currentTime.isApproximately(0))
  }

  @Test("seek clamps to [0, duration], sanitizes non-finite, and does not change isPlaying")
  @MainActor
  func seekClamps() {
    let controller = makeController(recorder: EngineRecorder())
    controller.load(url: url("a.wav"))  // fake duration = 10

    controller.seek(to: 99)
    #expect(controller.currentTime.isApproximately(10))
    controller.seek(to: -1)
    #expect(controller.currentTime.isApproximately(0))
    controller.seek(to: .nan)
    #expect(controller.currentTime.isApproximately(0))
    #expect(!controller.isPlaying)

    controller.play()
    controller.seek(to: 5)
    #expect(controller.isPlaying)
    #expect(controller.currentTime.isApproximately(5))
  }

  @Test("a paused seek writes BOTH the observable snapshot and the engine playhead (DD11/F2)")
  @MainActor
  func pausedSeekIsObservable() {
    let recorder = EngineRecorder()
    let controller = makeController(recorder: recorder)
    controller.load(url: url("a.wav"))
    controller.play()
    controller.pause()

    controller.seek(to: 7)
    #expect(!controller.isPlaying)
    // The observable snapshot (the paused scrubber's only source) moved…
    #expect(controller.currentTime.isApproximately(7))
    // …and so did the engine's own playhead (what a subsequent play resumes from).
    #expect(recorder.lastEngine?.currentTime.isApproximately(7) == true)
  }

  @Test("a construction throw lands in no-audio + labeled playbackError, cleared by a good load")
  @MainActor
  func loadFailureSetsLabeledError() {
    let controller = makeController(recorder: EngineRecorder(), throwOn: ["bad.wav"])
    controller.load(url: url("bad.wav"))
    #expect(!controller.hasAudio)
    #expect(controller.playbackError == "Reason: audio-load-failed")
    // A subsequent good load clears the error.
    controller.load(url: url("good.wav"))
    #expect(controller.hasAudio)
    #expect(controller.playbackError == nil)
  }

  @Test("the generation guard makes a stale completion inert (F5)")
  @MainActor
  func generationGuard() {
    let capture = CaptureBox()
    let controller = makeController(recorder: EngineRecorder(), capture: capture)
    controller.load(url: url("a.wav"))
    controller.play()
    #expect(controller.isPlaying)
    let stale = try! #require(capture.entries.first)

    // Replace the engine (bumps the generation).
    controller.load(url: url("b.wav"))
    controller.play()
    #expect(controller.isPlaying)

    // The OLD engine's completion (stale generation) must be inert.
    stale.onFinish(stale.generation, true)
    #expect(controller.isPlaying)

    // The CURRENT engine's completion settles to stopped-at-zero.
    let current = try! #require(capture.entries.last)
    current.onFinish(current.generation, true)
    #expect(!controller.isPlaying)
    #expect(controller.currentTime.isApproximately(0))
  }

  @Test(
    "an unsuccessful finish surfaces a labeled error; a stale unsuccessful finish is inert (P4)")
  @MainActor
  func unsuccessfulFinishSurfacesError() {
    let capture = CaptureBox()
    let controller = makeController(recorder: EngineRecorder(), capture: capture)
    controller.load(url: url("a.wav"))
    controller.play()
    let first = try! #require(capture.entries.first)

    // Replace the engine (bumps the generation), so `first` is now stale.
    controller.load(url: url("b.wav"))
    controller.play()
    #expect(controller.isPlaying)
    #expect(controller.playbackError == nil)

    // A STALE unsuccessful finish is inert — no error, still playing.
    first.onFinish(first.generation, false)
    #expect(controller.isPlaying)
    #expect(controller.playbackError == nil)

    // The CURRENT engine's unsuccessful finish (flag == false) stops with a labeled
    // reason; audio stays loaded (hasAudio true), distinguishing it from a clean finish.
    let current = try! #require(capture.entries.last)
    current.onFinish(current.generation, false)
    #expect(!controller.isPlaying)
    #expect(controller.currentTime.isApproximately(0))
    #expect(controller.hasAudio)
    #expect(controller.playbackError == "Reason: playback-interrupted")

    // Resuming playback clears the surfaced reason (so it does not linger while playing).
    controller.play()
    #expect(controller.isPlaying)
    #expect(controller.playbackError == nil)
  }

  @Test(
    "replacing the engine stops the old one before building the new (release-before-acquire, F6)")
  @MainActor
  func replaceStopsOldBeforeNew() {
    let recorder = EngineRecorder()
    let controller = makeController(recorder: recorder)
    controller.load(url: url("a.wav"))
    controller.load(url: url("b.wav"))

    // Ordering proxy for the scope release-before-acquire: the old engine is stopped
    // before the new engine is constructed.
    let stopA = try! #require(recorder.events.firstIndex(of: "stop(a.wav)"))
    let makeB = try! #require(recorder.events.firstIndex(of: "make(b.wav)"))
    #expect(stopA < makeB)
  }

  // MARK: - Fake engine harness

  private func url(_ name: String) -> URL {
    URL(fileURLWithPath: "/tmp/\(name)")
  }

  @MainActor
  private func makeController(
    recorder: EngineRecorder,
    capture: CaptureBox? = nil,
    playReturns: Bool = true,
    throwOn: Set<String> = []
  ) -> PlaybackController {
    PlaybackController(makeEngine: { url, generation, onFinish in
      if throwOn.contains(url.lastPathComponent) {
        throw NSError(domain: "test", code: 1)
      }
      capture?.entries.append((generation: generation, onFinish: onFinish))
      let engine = FakeEngine(
        tag: url.lastPathComponent, duration: 10, playReturns: playReturns, recorder: recorder)
      recorder.lastEngine = engine
      return engine
    })
  }
}

// A deterministic in-memory `AudioPlaybackEngine` for CI. Records make/stop into a
// shared `EngineRecorder` so ordering (release-before-acquire proxy) is assertable.
@MainActor
private final class FakeEngine: AudioPlaybackEngine {
  let tag: String
  var duration: Double
  var currentTime: Double = 0
  var isPlaying: Bool = false
  private let playReturns: Bool

  init(tag: String, duration: Double, playReturns: Bool, recorder: EngineRecorder) {
    self.tag = tag
    self.duration = duration
    self.playReturns = playReturns
    recorder.events.append("make(\(tag))")
    self.recorder = recorder
  }

  private let recorder: EngineRecorder

  func play() -> Bool {
    isPlaying = playReturns
    return playReturns
  }
  func pause() { isPlaying = false }
  func stop() {
    isPlaying = false
    recorder.events.append("stop(\(tag))")
  }
}

@MainActor
private final class EngineRecorder {
  var events: [String] = []
  // The most recently constructed engine, so a test can assert the engine-side
  // playhead a `seek` wrote (the fake is otherwise private to the factory).
  var lastEngine: FakeEngine?
}

@MainActor
private final class CaptureBox {
  var entries: [(generation: Int, onFinish: @MainActor (Int, Bool) -> Void)] = []
}

extension Double {
  fileprivate func isApproximately(_ other: Double, tolerance: Double = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}
