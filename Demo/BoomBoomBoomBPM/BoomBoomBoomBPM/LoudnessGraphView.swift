import BoomBoomBoomKit
import SwiftUI

/// LUFS-over-time graph (Story 10.4 UX rework): the ebu-norm-tools-style plot
/// the operator asked for — X is time, Y is loudness — rendered from the
/// chart-ready series `LUFSReport` already carries on its 100 ms grid:
///
/// - **Momentary** (400 ms window): thin red polyline.
/// - **Short-term** (3 s window): heavier light-blue polyline.
/// - **Integrated**: horizontal blue reference line.
/// - **Max true peak** (dBTP, post-mono-mixdown — see the row's help caveat):
///   horizontal green reference line on the same dB-FS-anchored axis, the
///   ebu-plot convention.
/// - **Loudness range**: translucent green band between `lraLowLUFS` and
///   `lraHighLUFS` (drawn only when ``LUFSReport/loudnessRangeLU`` is non-nil).
///
/// Fixed Y range −60…+6 (the ebu-plot axis); values below the floor — including
/// the −100 silence sentinel — pin to the bottom edge. Fit-to-width X (no
/// zoom; this pane is the loudness overview, the zoomable lane is the Beats
/// pane). Drawn with `Canvas` per the demo's KDD-D2 rendering convention; the
/// static plot never redraws per frame — only the playhead marker animates,
/// exactly like ``BeatGridView``'s scrubber split.
///
/// Playback: shares the lane's `PlaybackController`. Clicking the plot seeks
/// to the clicked time (no beat snapping here — there are no beat markers in
/// this pane) and starts playback when stopped/paused.
///
/// This view replaces the Story-10.4 bottom `LUFSReadoutView` panel; the
/// headline scalars now render as one compact FR-44-labeled caption row under
/// the plot instead of a second full-height GroupBox.
struct LoudnessGraphView: View {

  let report: LUFSReport

  /// The `maxSeconds` the analysis used — feeds the honest measurement caption
  /// (DD7). `0` / non-finite yields the plain caption via `windowCaption`.
  let analysisWindowSeconds: Double

  let controller: PlaybackController

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      graphCanvas
        .frame(minHeight: 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      transport
      readout
    }
  }

  // MARK: - Plot

  private var span: Double {
    Self.span(
      momentaryCount: report.momentaryLUFS.count,
      shortTermCount: report.shortTermLUFS.count,
      stepSeconds: report.stepSeconds)
  }

  private var graphCanvas: some View {
    ZStack(alignment: .topLeading) {
      Canvas { context, size in drawPlot(in: context, size: size) }
      scrubberLayer
    }
    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    .contentShape(Rectangle())
    // Click-to-scrub: fit-to-width lane, so viewport x IS plot x. Raw time —
    // no beat snapping in the loudness pane.
    .simultaneousGesture(
      SpatialTapGesture(coordinateSpace: .local)
        .onEnded { value in
          handleTap(atX: value.location.x)
        }
    )
    // The tap needs the lane width to invert x → time, and the playhead marker
    // needs the height; measure once per layout (layout-neutral, the
    // BeatGridView `laneSize` pattern).
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      laneSize = newSize
    }
  }

  @State private var laneSize: CGSize = .zero

  private func handleTap(atX x: CGFloat) {
    guard controller.hasAudio else { return }
    guard let time = Self.time(forX: x, span: span, width: laneSize.width) else { return }
    controller.seek(to: time)
    if !controller.isPlaying {
      controller.play()
    }
  }

  /// Playhead marker — same playing/paused branch split as ``BeatGridView``:
  /// `TimelineView(.animation)` reads the live engine playhead per display
  /// frame while playing; a static marker reads the observable `currentTime`
  /// snapshot otherwise (so a paused seek redraws once). The static plot
  /// Canvas is never inside the animated subtree (KDD-D2).
  @ViewBuilder
  private var scrubberLayer: some View {
    if controller.hasAudio {
      if controller.isPlaying {
        TimelineView(.animation) { _ in
          scrubberMarker(at: controller.livePlayhead)
        }
      } else {
        scrubberMarker(at: controller.currentTime)
      }
    }
  }

  private func scrubberMarker(at time: Double) -> some View {
    Rectangle()
      .fill(Color.primary)
      .frame(width: 1.5, height: max(laneSize.height, 1))
      .offset(x: Self.x(forTime: time, span: span, width: laneSize.width) - 0.75)
      // The playhead must never swallow a click at its own position.
      .allowsHitTesting(false)
  }

  // MARK: - Drawing (static — redraws only when the report/size changes)

  private func drawPlot(in context: GraphicsContext, size: CGSize) {
    let width = size.width
    let height = size.height

    // Horizontal dB gridlines + labels every 12 dB (−60, −48, … 0), the
    // ebu-plot grid at half its tick density so labels stay legible small.
    for dB in stride(from: Int(Self.yBottomLUFS), through: Int(Self.yTopLUFS), by: 12) {
      let y = Self.y(forLUFS: Double(dB), height: height)
      var line = Path()
      line.move(to: CGPoint(x: 0, y: y))
      line.addLine(to: CGPoint(x: width, y: y))
      context.stroke(line, with: .color(.secondary.opacity(0.15)), lineWidth: 1)
      context.draw(
        Text("\(dB)").font(.caption2).foregroundStyle(.secondary),
        at: CGPoint(x: 3, y: y - 1), anchor: .bottomLeading)
    }

    // Vertical time gridlines + M:SS labels at a "nice" step for the span.
    let tick = Self.timeTickStep(span: span)
    if tick > 0 {
      var t = tick
      while t < span {
        let x = Self.x(forTime: t, span: span, width: width)
        var line = Path()
        line.move(to: CGPoint(x: x, y: 0))
        line.addLine(to: CGPoint(x: x, y: height))
        context.stroke(line, with: .color(.secondary.opacity(0.15)), lineWidth: 1)
        context.draw(
          Text(Self.timeLabel(t)).font(.caption2).foregroundStyle(.secondary),
          at: CGPoint(x: x + 2, y: height - 2), anchor: .bottomLeading)
        t += tick
      }
    }

    // LRA band (green translucent fill between the P10/P95 short-term edges),
    // only when LRA was measurable (>= 60 s gated programme).
    if report.loudnessRangeLU != nil {
      let yHigh = Self.y(forLUFS: report.lraHighLUFS, height: height)
      let yLow = Self.y(forLUFS: report.lraLowLUFS, height: height)
      let band = Path(CGRect(x: 0, y: yHigh, width: width, height: max(yLow - yHigh, 0)))
      context.fill(band, with: .color(.green.opacity(0.12)))
    }

    // Momentary series — thin red (the ebu-plot palette).
    strokeSeries(
      report.momentaryLUFS, in: context, size: size,
      color: .red.opacity(0.55), lineWidth: 1)

    // Short-term series — heavier light blue.
    strokeSeries(
      report.shortTermLUFS, in: context, size: size,
      color: Color(red: 0.5, green: 0.55, blue: 1.0), lineWidth: 2.5)

    // Integrated loudness — horizontal blue reference line.
    if report.integratedLUFS > LUFSReport.sentinelFloor {
      let y = Self.y(forLUFS: report.integratedLUFS, height: height)
      var line = Path()
      line.move(to: CGPoint(x: 0, y: y))
      line.addLine(to: CGPoint(x: width, y: y))
      context.stroke(line, with: .color(.blue), lineWidth: 2)
    }

    // Max true peak — horizontal green reference line (dBTP on the same
    // dB-FS-anchored axis, the ebu-plot convention; mono-mixdown caveat on the
    // readout row).
    if report.maxTruePeakDBTP > LUFSReport.sentinelFloor {
      let y = Self.y(forLUFS: report.maxTruePeakDBTP, height: height)
      var line = Path()
      line.move(to: CGPoint(x: 0, y: y))
      line.addLine(to: CGPoint(x: width, y: y))
      context.stroke(line, with: .color(.green), lineWidth: 1)
    }
  }

  /// One series polyline on the shared 100 ms grid. Values below the plot
  /// floor (incl. the −100 silence sentinel) pin to the bottom edge.
  private func strokeSeries(
    _ series: [Double], in context: GraphicsContext, size: CGSize,
    color: Color, lineWidth: CGFloat
  ) {
    guard series.count > 1 else { return }
    var path = Path()
    for (i, value) in series.enumerated() {
      let point = CGPoint(
        x: Self.x(forTime: Double(i) * report.stepSeconds, span: span, width: size.width),
        y: Self.y(forLUFS: value, height: size.height))
      if i == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    context.stroke(path, with: .color(color), lineWidth: lineWidth)
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
      .buttonStyle(.bordered)
      .disabled(!controller.hasAudio)
      .help(
        controller.hasAudio
          ? "Play / pause — or click the graph to jump to that time"
          : "Playback unavailable for this file")

      if let error = controller.playbackError {
        // Rendered verbatim — the controller's reasons are already FR-44-labeled.
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      } else if !controller.hasAudio {
        Text("Reason: no-audio-loaded")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }

  // MARK: - Readout (FR-44: compact, labeled metadata chips)

  @ViewBuilder
  private var readout: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        AnalysisMetadataChip(
          label: Self.windowCaption(report: report, analysisWindowSeconds: analysisWindowSeconds),
          value: Self.integratedValue(report.integratedLUFS))
        AnalysisMetadataChip(
          label: "True peak", value: Self.truePeakValue(report.maxTruePeakDBTP),
          help:
            "Measured after mono mixdown — may understate per-channel peaks; not a delivery-compliance value."
        )
        AnalysisMetadataChip(
          label: "Loudness range", value: Self.loudnessRangeValue(report.loudnessRangeLU))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Plot geometry (pure, unit-tested)

  /// Fixed plot ceiling in LUFS/dB — the ebu-plot axis top (+6).
  nonisolated static let yTopLUFS: Double = 6
  /// Fixed plot floor in LUFS/dB — the ebu-plot axis bottom (−60). Values
  /// below (incl. the −100 silence sentinel) pin to the bottom edge.
  nonisolated static let yBottomLUFS: Double = -60

  /// The plot's X span in seconds: the start time of the last series element
  /// on the 100 ms grid, over whichever series is longer. Minimum 1 (division
  /// guard); degenerate step/counts also yield 1.
  nonisolated static func span(
    momentaryCount: Int, shortTermCount: Int, stepSeconds: Double
  ) -> Double {
    let count = max(momentaryCount, shortTermCount)
    guard count > 1, stepSeconds.isFinite, stepSeconds > 0 else { return 1 }
    return Double(count - 1) * stepSeconds
  }

  /// Maps a time to plot x, clamped to `[0, width]`. Degenerate input → 0.
  nonisolated static func x(forTime time: Double, span: Double, width: CGFloat) -> CGFloat {
    guard time.isFinite, span.isFinite, span > 0, width.isFinite, width >= 0 else { return 0 }
    let x = CGFloat(time / span) * width
    return min(max(x, 0), width)
  }

  /// Inverts a plot x back to a time in `[0, span]` for click-to-scrub.
  /// Returns `nil` for degenerate input so the tap is simply ignored.
  nonisolated static func time(forX x: CGFloat, span: Double, width: CGFloat) -> Double? {
    guard x.isFinite, span.isFinite, span > 0, width.isFinite, width > 0 else { return nil }
    return min(max(Double(x / width) * span, 0), span)
  }

  /// Maps a LUFS/dB value to plot y over the fixed −60…+6 range, clamping
  /// out-of-range values (incl. the −100 sentinel) to the edges. Non-finite
  /// values pin to the bottom edge (`height`).
  nonisolated static func y(forLUFS value: Double, height: CGFloat) -> CGFloat {
    guard height.isFinite, height > 0 else { return 0 }
    guard value.isFinite else { return height }
    let clamped = min(max(value, yBottomLUFS), yTopLUFS)
    return CGFloat((yTopLUFS - clamped) / (yTopLUFS - yBottomLUFS)) * height
  }

  /// A "nice" vertical-gridline step for `span`, chosen so the plot carries
  /// at most ~8 time ticks. Degenerate spans → 0 (no ticks).
  nonisolated static func timeTickStep(span: Double) -> Double {
    guard span.isFinite, span > 0 else { return 0 }
    for candidate in [5.0, 10, 15, 30, 60, 120, 300, 600] where span / candidate <= 8 {
      return candidate
    }
    return 1200
  }

  /// `M:SS` label for a time tick (the ebu-plot X-axis format).
  nonisolated static func timeLabel(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let whole = Int(seconds.rounded())
    return String(format: "%d:%02d", whole / 60, whole % 60)
  }

  // MARK: - Measurement window (pure, unit-tested — DD7; moved from the
  // deleted LUFSReadoutView)

  // ITU-R BS.1770 momentary window (fixed 400 ms). `LUFSReport` exposes
  // `stepSeconds` but not the block length; the standard fixes it at 400 ms,
  // so hardcoding it is honest — prefer a report field if the library ever
  // exposes one.
  private nonisolated static let momentaryBlockSeconds: Double = 0.4

  /// The FR-44 field-label caption for the integrated value, honest about the
  /// analyzed window (DD7). The momentary series is 400 ms ITU blocks on a
  /// 100 ms grid, so `count * stepSeconds` UNDER-counts the span by ~0.3 s;
  /// the true span is the END of the last block: `(count - 1) * stepSeconds +
  /// 0.4`. When that span reached the analysis budget (within one hop of the
  /// integer-count quantization) the file was truncated -> "(first N s)";
  /// otherwise the window covered the whole file -> plain caption.
  nonisolated static func windowCaption(report: LUFSReport, analysisWindowSeconds: Double)
    -> String
  {
    let count = report.momentaryLUFS.count
    guard analysisWindowSeconds.isFinite, analysisWindowSeconds > 0, count >= 1 else {
      return "Integrated loudness"
    }
    let measured = Double(count - 1) * report.stepSeconds + Self.momentaryBlockSeconds
    if measured >= analysisWindowSeconds - report.stepSeconds {
      return "Integrated loudness (first \(Int(measured.rounded())) s)"
    }
    return "Integrated loudness"
  }

  // MARK: - Value formatters (pure, unit-tested — FR-44 + sentinel discipline;
  // moved from the deleted LUFSReadoutView)

  /// `%.1f LUFS`, or `unavailable` when non-finite or at/below the `-100.0`
  /// sentinel floor (silence / non-measurable — never a `-100.0 LUFS` leak).
  nonisolated static func integratedValue(_ lufs: Double) -> String {
    guard lufs.isFinite, lufs > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f LUFS", lufs)
  }

  /// `%.1f dBTP`, or `unavailable` under the same non-finite / at-or-below-
  /// sentinel guard.
  nonisolated static func truePeakValue(_ dbtp: Double) -> String {
    guard dbtp.isFinite, dbtp > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f dBTP", dbtp)
  }

  /// `%.1f LU`, or `unavailable` when the value is `nil` (LRA absent — gated
  /// programme < 60 s), non-finite, or at/below the sentinel floor.
  nonisolated static func loudnessRangeValue(_ lra: Double?) -> String {
    guard let lra else { return "unavailable" }
    guard lra.isFinite, lra > LUFSReport.sentinelFloor else { return "unavailable" }
    return String(format: "%.1f LU", lra)
  }
}

/// The `(?)` legend for the loudness pane — same self-contained pattern as
/// ``BeatGridHelpButton`` so it can live in the GroupBox label.
struct LoudnessHelpButton: View {
  @State private var showLegendHelp = false

  var body: some View {
    Button {
      showLegendHelp.toggle()
    } label: {
      Image(systemName: "questionmark.circle")
    }
    .buttonStyle(.borderless)
    .controlSize(.small)
    .help("What do these lines mean?")
    .popover(isPresented: $showLegendHelp, arrowEdge: .bottom) {
      legendHelp.padding().frame(width: 360)
    }
  }

  @ViewBuilder
  private var legendHelp: some View {
    VStack(alignment: .leading, spacing: 8) {
      legendRow(
        .red.opacity(0.55), "Momentary",
        "Loudness over a sliding 400 ms window — the fast meter that follows every hit.")
      legendRow(
        Color(red: 0.5, green: 0.55, blue: 1.0), "Short-term",
        "Loudness over a sliding 3 s window — the musical phrase-level loudness contour.")
      legendRow(
        .blue, "Integrated",
        "The single programme-loudness number for the whole analyzed span (the horizontal "
          + "blue line — what normalization targets).")
      legendRow(
        .green, "Max true peak",
        "The loudest inter-sample peak, in dBTP on the same axis. Measured after mono "
          + "mixdown, so it can understate per-channel peaks.")
      legendRow(
        .green.opacity(0.25), "Loudness range",
        "The band between the quietest and loudest short-term loudness (P10–P95) — how "
          + "dynamic the track is. Shown only when at least ~60 s was measurable.")
      legendRow(
        .primary, "Playhead",
        "The playback position. Click anywhere on the graph to jump to that time and "
          + "start playback.")
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
}
