import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Deterministic, GUI-free, audio-free tests for the Story 10.3 beat-grid timeline:
// the pure Canvas geometry + label derivations, the `PlaybackController` state machine
// (via a fake `AudioPlaybackEngine`), and the persisted view-mode preference.
@Suite("Beat-grid timeline")
struct BeatGridTimelineViewTests {

  // MARK: - span (F1: analyzed coverage, not full-file playback duration)

  @Test("span prefers the analyzed span over a longer playback duration")
  func spanPrefersAnalyzed() {
    // A 540s file analyzed to 120s: ticks must map against 120, not 540 (else bunched).
    let s = BeatGridTimelineView.span(
      controllerDuration: 540, hasAudio: true, stateDuration: 120, lastBeatTime: 119)
    #expect(s.isApproximately(120))
  }

  @Test("span falls back last-beat -> controller.duration -> 1")
  func spanFallbackChain() {
    // No decode span -> last beat time.
    #expect(
      BeatGridTimelineView.span(
        controllerDuration: 540, hasAudio: true, stateDuration: 0, lastBeatTime: 118
      ).isApproximately(118))
    // No analyzed info at all -> the player duration (last resort).
    #expect(
      BeatGridTimelineView.span(
        controllerDuration: 540, hasAudio: true, stateDuration: 0, lastBeatTime: nil
      ).isApproximately(540))
    // Nothing usable -> 1 (division guard), never 0.
    #expect(
      BeatGridTimelineView.span(
        controllerDuration: 0, hasAudio: false, stateDuration: 0, lastBeatTime: nil
      ).isApproximately(1))
    // A player duration is ignored when there is no audio.
    #expect(
      BeatGridTimelineView.span(
        controllerDuration: 540, hasAudio: false, stateDuration: 0, lastBeatTime: nil
      ).isApproximately(1))
  }

  // MARK: - tickX / scrubberX

  @Test("tickX maps time/span*width and stays in [0, width]")
  func tickXMaps() {
    #expect(BeatGridTimelineView.tickX(time: 5, span: 10, width: 100).isApproximately(50))
    #expect(BeatGridTimelineView.tickX(time: 0, span: 10, width: 100).isApproximately(0))
    #expect(BeatGridTimelineView.tickX(time: 10, span: 10, width: 100).isApproximately(100))
  }

  @Test("tickX defends non-finite time/width and non-positive span")
  func tickXGuards() {
    #expect(BeatGridTimelineView.tickX(time: .nan, span: 10, width: 100).isApproximately(0))
    #expect(BeatGridTimelineView.tickX(time: 5, span: 0, width: 100).isApproximately(0))
    #expect(BeatGridTimelineView.tickX(time: 5, span: -1, width: 100).isApproximately(0))
    #expect(BeatGridTimelineView.tickX(time: 5, span: 10, width: .nan).isApproximately(0))
  }

  @Test("scrubberX clamps to [0, width] even past the span")
  func scrubberXClamps() {
    #expect(
      BeatGridTimelineView.scrubberX(currentTime: 5, span: 10, width: 100).isApproximately(50))
    // currentTime beyond span pins at the right edge (playback past the analyzed window).
    #expect(
      BeatGridTimelineView.scrubberX(currentTime: 15, span: 10, width: 100).isApproximately(100))
    #expect(
      BeatGridTimelineView.scrubberX(currentTime: -3, span: 10, width: 100).isApproximately(0))
    #expect(
      BeatGridTimelineView.scrubberX(currentTime: .nan, span: 10, width: 100).isApproximately(0))
    // Huge width, tiny span: still clamped, never NaN/overflow.
    let x = BeatGridTimelineView.scrubberX(currentTime: 1, span: 0.001, width: 10_000)
    #expect(x.isApproximately(10_000))
  }

  // MARK: - visibleBeatTimes / downbeatTimes

  @Test("visibleBeatTimes omits beats past the span")
  func visibleBeatOmits() {
    // `BeatTimestamp` clamps presentationTime >= 0 at construction, so a negative time is
    // unrepresentable — the reachable omission is a beat past the span (11 > 10).
    let beats = [0.0, 5.0, 11.0].map {
      BeatTimestamp(presentationTime: $0, confidence: 1, strength: 1)
    }
    let visible = BeatGridTimelineView.visibleBeatTimes(beats, span: 10)
    #expect(visible.count == 2)
    #expect(visible[0].isApproximately(0))
    #expect(visible[1].isApproximately(5))
  }

  @Test("downbeatTimes yields the estimate's beats for .detected, empty otherwise")
  func downbeatTimesByState() {
    let est = DownbeatEstimate(
      beats: [0.0, 2.0, 4.0].map {
        BeatTimestamp(presentationTime: $0, confidence: 1, strength: 1)
      },
      meter: MeterEstimate(beatsPerBar: 4, source: .assumed),
      confidence: 0.8, phaseIndex: 0)
    #expect(BeatGridTimelineView.downbeatTimes(.detected(estimate: est)).count == 3)
    #expect(BeatGridTimelineView.downbeatTimes(.noneDetected).isEmpty)
    #expect(BeatGridTimelineView.downbeatTimes(.notAttempted).isEmpty)
  }

  // MARK: - Readout labels (FR-44 / DD2 / DD8)

  @Test("downbeatStatusLabel maps the real tri-state (no 'partial')")
  func downbeatStatusLabels() {
    let est = DownbeatEstimate(
      beats: [BeatTimestamp(presentationTime: 0, confidence: 1, strength: 1)],
      meter: MeterEstimate(beatsPerBar: 4, source: .assumed), confidence: 0.8, phaseIndex: 0)
    #expect(BeatGridTimelineView.downbeatStatusLabel(.detected(estimate: est)) == "detected")
    #expect(BeatGridTimelineView.downbeatStatusLabel(.noneDetected) == "not-detected")
    #expect(BeatGridTimelineView.downbeatStatusLabel(.notAttempted) == "not-attempted")
  }

  @Test("tempoValue renders %.2f BPM, and 'unavailable' for the 0.0 sentinel")
  func tempoValues() {
    #expect(BeatGridTimelineView.tempoValue(128) == "128.00 BPM")
    #expect(BeatGridTimelineView.tempoValue(0) == "unavailable")
    #expect(BeatGridTimelineView.tempoValue(.nan) == "unavailable")
    #expect(BeatGridTimelineView.tempoValue(-5) == "unavailable")
  }

  @Test("gridConfidenceValue is %.2f clamped to [0, 1]")
  func gridConfidenceValues() {
    #expect(BeatGridTimelineView.gridConfidenceValue(0.873) == "0.87")
    #expect(BeatGridTimelineView.gridConfidenceValue(1.5) == "1.00")
    #expect(BeatGridTimelineView.gridConfidenceValue(-0.2) == "0.00")
    #expect(BeatGridTimelineView.gridConfidenceValue(.nan) == "0.00")
  }

  // MARK: - PlaybackController (via the fake AudioPlaybackEngine seam)

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

  @Test("load(nil) tears down to the no-audio state")
  @MainActor
  func loadNilTearsDown() {
    let controller = makeController(recorder: EngineRecorder())
    controller.load(url: url("a.wav"))
    controller.play()
    controller.load(url: nil)
    #expect(!controller.hasAudio)
    #expect(!controller.isPlaying)
    #expect(controller.currentTime.isApproximately(0))
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

  // MARK: - View-mode persistence (DD7 — same convention as merge-strategy)

  @Test("view mode hydrates to the fallback when the key is absent, without writing")
  @MainActor
  func viewModeAbsent() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.viewmode.absent"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let vm = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(defaults: defaults, fallbackStrategy: .quorum))
    #expect(vm.beatGridViewMode == .timeline)
    #expect(defaults.object(forKey: AnalysisViewModel.preferredBeatGridViewModeKey) == nil)
  }

  @Test("view mode hydrates a valid stored raw value and round-trips through persist")
  @MainActor
  func viewModeValidRoundTrip() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.viewmode.valid"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    defaults.set("waveform", forKey: AnalysisViewModel.preferredBeatGridViewModeKey)

    let vm = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(defaults: defaults, fallbackStrategy: .quorum))
    #expect(vm.beatGridViewMode == .waveform)

    vm.beatGridViewMode = .timeline
    vm.persistBeatGridViewMode()
    #expect(defaults.string(forKey: AnalysisViewModel.preferredBeatGridViewModeKey) == "timeline")
  }

  @Test("view mode self-heals a poison value: falls back AND writes back (removes the key)")
  @MainActor
  func viewModePoisonHeal() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.viewmode.poison"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    defaults.set(["not-a-mode"], forKey: AnalysisViewModel.preferredBeatGridViewModeKey)

    let vm = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(defaults: defaults, fallbackStrategy: .quorum))
    #expect(vm.beatGridViewMode == .timeline)
    // The poison value is gone (write-back heal, not merely ignored in memory).
    #expect(defaults.object(forKey: AnalysisViewModel.preferredBeatGridViewModeKey) == nil)
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
      return FakeEngine(
        tag: url.lastPathComponent, duration: 10, playReturns: playReturns, recorder: recorder)
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

extension CGFloat {
  fileprivate func isApproximately(_ other: CGFloat, tolerance: CGFloat = 1e-6) -> Bool {
    abs(self - other) <= tolerance
  }
}
