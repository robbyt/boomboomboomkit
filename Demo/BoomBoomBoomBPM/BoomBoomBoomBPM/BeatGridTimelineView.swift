import BoomBoomBoomKit
import SwiftUI

/// The FR-39 beat-grid timeline (Story 10.3): a **waveform-free** `Canvas` of beat
/// ticks + taller downbeat marks + the anchor, a playback-driven scrubber, and a
/// labeled four-field readout. The waveform-rich inspection surface is the sibling
/// ``BeatGridView`` (Epic 8), selectable via the view-mode switch — this view is the
/// clean consumer-facing readout.
///
/// ## Explicitly NOT a waveform (AC5 / FR-39)
/// This file draws only the grid; it never samples audio for display — no envelope
/// decode, no amplitude array, no audio-file read, no per-frame sample loop. The
/// ``PlaybackController`` provides a playback clock — that is playback, not sampling,
/// and lives in its own file.
///
/// ## Static layer vs. scrubber (DD6/AC2)
/// The ticks/downbeats/anchor are drawn ONCE in a base `Canvas`; only the moving
/// scrubber lives in a `TimelineView(.animation)` overlay, so the (potentially
/// thousand-tick) static layer is not regenerated every frame. When paused / no audio,
/// a non-animating branch draws a static scrubber from the observable `currentTime`
/// snapshot (so a paused seek still redraws — DD11).
struct BeatGridTimelineView: View {
  let state: GridVisualizationState
  let controller: PlaybackController

  @State private var showLegend = false

  private var grid: BeatGrid { state.beatGrid }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      timelineCanvas
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
      transport
      readout
    }
  }

  // MARK: - Canvas

  private var timelineCanvas: some View {
    // Base layer: the static grid, drawn once (redraws only when `state`/size changes).
    Canvas { context, size in
      drawStatic(in: context, size: size)
    }
    .overlay {
      // Scrubber layer. While playing, `TimelineView(.animation)` re-reads the live
      // playhead each display frame; while paused / no audio, a plain Canvas reads the
      // observable snapshot (updated on seek), so a paused seek redraws once (DD11).
      if controller.isPlaying && controller.hasAudio {
        TimelineView(.animation) { _ in
          Canvas { context, size in
            drawScrubber(in: context, size: size, time: controller.livePlayhead)
          }
        }
      } else {
        Canvas { context, size in
          drawScrubber(in: context, size: size, time: controller.currentTime)
        }
      }
    }
  }

  private func drawStatic(in context: GraphicsContext, size: CGSize) {
    let width = size.width
    let height = size.height
    let span = Self.span(
      controllerDuration: controller.duration, hasAudio: controller.hasAudio,
      stateDuration: state.duration, lastBeatTime: grid.beats.last?.presentationTime)

    // Raw detected beats — one thin full-height tick per BeatTimestamp (DD4). Out-of-span
    // ticks are omitted (not piled at an edge).
    var beatPath = Path()
    for time in Self.visibleBeatTimes(grid.beats, span: span) {
      let bx = Self.tickX(time: time, span: span, width: width)
      beatPath.move(to: CGPoint(x: bx, y: 0))
      beatPath.addLine(to: CGPoint(x: bx, y: height))
    }
    context.stroke(beatPath, with: .color(.blue.opacity(0.7)), lineWidth: 1)

    // Downbeats — accent marks at every detected-downbeat beat time (DD4). Drawn
    // full-height like the beat ticks but distinguished by a heavier pink stroke
    // (color + line weight, not height) against the thin blue beats; the legend names them.
    let downbeats = Self.downbeatTimes(grid.downbeats)
    if !downbeats.isEmpty {
      var downPath = Path()
      for time in downbeats where time >= 0 && time <= span {
        let dx = Self.tickX(time: time, span: span, width: width)
        downPath.move(to: CGPoint(x: dx, y: 0))
        downPath.addLine(to: CGPoint(x: dx, y: height))
      }
      context.stroke(downPath, with: .color(.pink), lineWidth: 2)
    }

    // Anchor — a distinct orange marker + a small top triangle.
    if let anchorTime = grid.gridOrigin?.presentationTime, anchorTime >= 0, anchorTime <= span {
      let ax = Self.tickX(time: anchorTime, span: span, width: width)
      var line = Path()
      line.move(to: CGPoint(x: ax, y: 0))
      line.addLine(to: CGPoint(x: ax, y: height))
      context.stroke(line, with: .color(.orange), lineWidth: 2)
      var tri = Path()
      tri.move(to: CGPoint(x: ax - 4, y: 0))
      tri.addLine(to: CGPoint(x: ax + 4, y: 0))
      tri.addLine(to: CGPoint(x: ax, y: 7))
      tri.closeSubpath()
      context.fill(tri, with: .color(.orange))
    }
  }

  private func drawScrubber(in context: GraphicsContext, size: CGSize, time: Double) {
    guard controller.hasAudio else { return }
    let span = Self.span(
      controllerDuration: controller.duration, hasAudio: controller.hasAudio,
      stateDuration: state.duration, lastBeatTime: grid.beats.last?.presentationTime)
    let x = Self.scrubberX(currentTime: time, span: span, width: size.width)
    var line = Path()
    line.move(to: CGPoint(x: x, y: 0))
    line.addLine(to: CGPoint(x: x, y: size.height))
    context.stroke(line, with: .color(.primary), lineWidth: 1.5)
  }

  // MARK: - Transport

  @ViewBuilder
  private var transport: some View {
    HStack(spacing: 8) {
      Button {
        controller.togglePlayPause()
      } label: {
        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
      }
      .buttonStyle(.borderless)
      .disabled(!controller.hasAudio)
      .help(controller.hasAudio ? "Play / pause" : "Playback unavailable for this file")

      if !controller.hasAudio {
        // Labeled rationale for the disabled transport (FR-44 discipline — no bare state).
        Text(
          "Reason: \(controller.playbackError.map { _ in "audio-unavailable" } ?? "no-audio-loaded")"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Spacer()

      Button {
        showLegend.toggle()
      } label: {
        Image(systemName: "questionmark.circle")
      }
      .buttonStyle(.borderless)
      .controlSize(.small)
      .help("What do these marks mean?")
      .popover(isPresented: $showLegend, arrowEdge: .bottom) {
        legend.padding().frame(width: 300)
      }
    }
  }

  // MARK: - Legend (F4)

  @ViewBuilder
  private var legend: some View {
    VStack(alignment: .leading, spacing: 8) {
      legendRow(.blue, "Beat", "Every beat the tracker detected, at the time it landed.")
      legendRow(
        .pink, "Downbeat",
        "The start-of-bar beats (the \"1\" of each bar), shown only when detected.")
      legendRow(
        .orange, "Anchor", "The single most-trusted beat the grid is built outward from.")
    }
  }

  @ViewBuilder
  private func legendRow(_ color: Color, _ label: String, _ description: String) -> some View {
    HStack(alignment: .top, spacing: 6) {
      Rectangle().fill(color).frame(width: 12, height: 3).padding(.top, 5)
      VStack(alignment: .leading, spacing: 0) {
        Text(label).font(.caption).bold()
        Text(description).font(.caption2).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  // MARK: - Readout (AC3 / FR-44)

  @ViewBuilder
  private var readout: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Estimated tempo: \(Self.tempoValue(grid.estimatedTempo))").monospacedDigit()
      Text("Beat count: \(grid.beats.count)").monospacedDigit()
      Text("Downbeat status: \(Self.downbeatStatusLabel(grid.downbeats))")
      Text("Grid confidence: \(Self.gridConfidenceValue(grid.confidence))").monospacedDigit()
    }
    .font(.callout)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Pure derivations (nonisolated → unit-testable off the main actor)

  /// The timeline's time span. Tracks the ANALYZED coverage, NOT the full-file playback
  /// duration (DD6/F1): `.fullTrack` is `maxSeconds`-bounded, so on a long file the
  /// beats stop early while `AVAudioPlayer.duration` is the whole asset — preferring the
  /// player duration would bunch every tick into the left of the Canvas. Returns the
  /// first finite `> 0` among the analyzed decode span, the last beat time, the player
  /// duration (only as a last resort when there is audio), and `1` (division guard).
  nonisolated static func span(
    controllerDuration: Double, hasAudio: Bool, stateDuration: Double, lastBeatTime: Double?
  ) -> Double {
    for candidate in [stateDuration, lastBeatTime ?? 0, hasAudio ? controllerDuration : 0] {
      if candidate.isFinite, candidate > 0 { return candidate }
    }
    return 1
  }

  /// Maps a time to an x within `[0, width]`. Defends non-finite inputs and a
  /// non-positive span (returns 0) so a degenerate grid cannot produce NaN coordinates.
  nonisolated static func tickX(time: Double, span: Double, width: CGFloat) -> CGFloat {
    guard time.isFinite, span.isFinite, span > 0, width.isFinite, width >= 0 else { return 0 }
    return CGFloat(time / span) * width
  }

  /// Beat times within `[0, span]`, in order. Out-of-range beats are omitted (not
  /// clamped to an edge, so they don't pile up misleadingly).
  nonisolated static func visibleBeatTimes(_ beats: [BeatTimestamp], span: Double) -> [Double] {
    beats.map(\.presentationTime).filter { $0 >= 0 && $0 <= span }
  }

  /// The detected-downbeat beat times (the payload's `beats`), or `[]` for
  /// `.noneDetected`/`.notAttempted`.
  nonisolated static func downbeatTimes(_ result: DownbeatResult) -> [Double] {
    if case .detected(let estimate) = result {
      return estimate.beats.map(\.presentationTime)
    }
    return []
  }

  /// The scrubber x, clamped to `[0, width]` even if `currentTime` exceeds `span`
  /// (playback past the analyzed window pins the scrubber at the right edge — AC2/DD6).
  nonisolated static func scrubberX(currentTime: Double, span: Double, width: CGFloat) -> CGFloat {
    guard currentTime.isFinite, span.isFinite, span > 0, width.isFinite, width >= 0 else {
      return 0
    }
    let x = CGFloat(currentTime / span) * width
    return min(max(x, 0), width)
  }

  /// FR-44 value for the tempo field: `%.2f BPM`, or `unavailable` for the `0.0`
  /// "no valid estimate" sentinel (DD8).
  nonisolated static func tempoValue(_ tempo: Double) -> String {
    guard tempo.isFinite, tempo > 0 else { return "unavailable" }
    return String(format: "%.2f BPM", tempo)
  }

  /// FR-44 value for the confidence field: two decimals in `[0, 1]`.
  nonisolated static func gridConfidenceValue(_ confidence: Float) -> String {
    let clamped = min(max(confidence.isFinite ? confidence : 0, 0), 1)
    return String(format: "%.2f", clamped)
  }

  /// The tri-state downbeat label (DD2 — the real `DownbeatResult`, no "partial").
  nonisolated static func downbeatStatusLabel(_ result: DownbeatResult) -> String {
    switch result {
    case .detected: return "detected"
    case .noneDetected: return "not-detected"
    case .notAttempted: return "not-attempted"
    }
  }
}
