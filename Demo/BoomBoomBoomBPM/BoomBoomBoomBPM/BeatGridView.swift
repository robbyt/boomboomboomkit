import BoomBoomBoomKit
import SwiftUI

/// Atomic visualization payload — assigned in ONE observed write so the grid
/// strip's show-gate (`gridVisualization != nil`) flips without a partial render
/// from separately-assigned fields. `peaks` may be empty (waveform decode is
/// best-effort); the grid still renders against a beat-derived span.
struct GridVisualizationState: Equatable {
  /// The tracked grid (beats, downbeats, anchor, tempo, agreement, coverage).
  let beatGrid: BeatGrid
  /// Max-abs waveform envelope over `duration`. Empty when the waveform decode
  /// failed — the view falls back to a beat-derived span.
  let peaks: [Float]
  /// Decoded duration in seconds (0 when the waveform decode failed).
  let duration: Double
  /// The BPM stage's tempo, for the agreement label.
  let bpmTempo: Double
  /// The analyzed audio file. Carried on this ATOMIC payload (Story 10.3) so the
  /// `BeatGridView` playback scrubber loads audio keyed to the *matching*
  /// result — driven off `gridVisualization?.sourceURL`, NOT the prologue
  /// `selectedFileURL` (which is set before analysis publishes and is not cleared
  /// on the no-BPM/failure arms). Every `gridVisualization = nil` clear therefore
  /// also stops playback.
  let sourceURL: URL
}

/// The demo's single beat-grid surface: horizontal beat-grid + waveform overlay
/// with a playback scrubber, click-to-scrub, transport, and the FR-44 labeled
/// readout (Story 10.3 UX rework merged the waveform-free timeline view into
/// this one — one lane shows everything).
///
/// Layers: the **extrapolated** grid (the trustworthy `anchor + period·n` line
/// the F-measure is scored on) as the primary layer and the **raw detected
/// beats** as a faint secondary layer, so raw-vs-extrapolated drift — and drift
/// against the waveform transients — is directly visible.
///
/// Playback: clicking anywhere on the lane seeks to the **nearest raw detected
/// beat** (every click snaps — the feature exists to audition whether the beat
/// markers align with the audio) and, when stopped/paused, starts playback. The
/// scrubber follows KDD-D2: the static grid Canvas never redraws per frame —
/// while playing, only a positioned marker animates inside
/// `TimelineView(.animation)`; while paused, a static marker reads the
/// observable `currentTime` snapshot (so a paused seek redraws once).
struct BeatGridView: View {
  let state: GridVisualizationState
  let controller: PlaybackController

  @State private var pointsPerSecond: Double = 16
  @State private var showRawBeats: Bool = true
  // Captured at the start of a pinch so magnification scales from the zoom level
  // the gesture began at (nil between gestures).
  @State private var pinchBasePPS: Double?
  // The visible lane's measured WIDTH (drives the fit-to-width zoom-out floor
  // and the pinch-anchor mapping). Height is deliberately NOT stored: the lane
  // height is sourced from the parent-allocated slot via the wrapper
  // `GeometryReader` in `body` (parent -> content, one direction), never from a
  // self-measurement. Measuring the rendered height and feeding it back as the
  // scroll content's REQUIRED height (the old `height: laneHeight`) was a layout
  // feedback loop: under the window's `.windowResizability(.contentMinSize)` +
  // `.inspector` split-view host, each Update-Constraints probe recorded a
  // larger height, which the content then required, which grew the window — a
  // runaway to a ~40000pt window and an NSGenericException crash (fixed 2026-07-19).
  // `0` until the first layout pass measures it.
  @State private var laneWidth: CGFloat = 0

  // --- Pointer-anchored pinch-zoom ---
  // Drives programmatic horizontal scrolling so the content point under the cursor
  // stays fixed as `pointsPerSecond` changes (zoom-where-you-point), instead of the
  // default left-edge anchoring.
  @State private var scrollPosition = ScrollPosition()
  // The live horizontal scroll offset. Updated by `.onScrollGeometryChange`; read
  // ONLY at pinch start (to map cursor viewport-x → content-x), so the programmatic
  // scroll we issue during the pinch can't feed back into the anchor math.
  @State private var currentOffsetX: CGFloat = 0
  // Last cursor x in VIEWPORT space (`[0, laneWidth]`, scroll-independent). Viewport
  // space — not content space — so panning between hover and pinch can't stale it.
  @State private var hoverViewportX: CGFloat?
  // SpatialTapGesture supplies a location but not the modifier state. Track
  // Command separately so a Cmd-click can deliberately bypass beat snapping.
  @State private var isCommandPressed = false
  // Captured once per pinch: the content time under the cursor, and the cursor's
  // (fixed) viewport x. `newOffset = anchorTime * newPPS − anchorViewportX`.
  @State private var pinchAnchorTime: Double?
  @State private var pinchAnchorViewportX: CGFloat?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // The horizontal beat lane is wrapped in a slot `GeometryReader` so its
      // Canvas height comes from the parent-allocated analysis slot (exactly as
      // the Loudness lane fills its slot), forwarded across the horizontal-scroll
      // boundary. The GeometryReader is sized by its PARENT, never by its child
      // (it returns a flexible preferred size), so the dataflow is acyclic — this
      // is what makes the lane resize proportionally with the window WITHOUT
      // reintroducing the Update-Constraints feedback loop. (An earlier
      // container-relative-frame approach resolved against the wrong container
      // under the outer vertical ScrollView and pinned the lane at a fixed
      // oversized height — fixed 2026-07-19.)
      GeometryReader { slot in
        // Guarded slot height: a sizing probe can pass a non-finite proposal.
        let laneHeight = slot.size.height.isFinite ? max(slot.size.height, 1) : 1
        ScrollView(.horizontal, showsIndicators: true) {
          // ZStack: static grid Canvas below, animated scrubber marker above. Both live
          // INSIDE the scroll content (same contentWidth frame), so the scrubber pans
          // and zooms with the lane. KDD-D2: the Canvas never redraws per frame — only
          // the marker's offset animates.
          ZStack(alignment: .topLeading) {
            Canvas { context, size in draw(in: context, size: size) }
            scrubberLayer
          }
          // Width is the zoomed content width (drives horizontal scrolling); the
          // height is the parent-allocated slot height forwarded from the wrapper
          // `GeometryReader` above, NOT a stored self-measurement (parent ->
          // content, one direction) — so the lane resizes proportionally like the
          // Loudness lane and the old measure-then-require crash cannot recur.
          .frame(width: contentWidth, height: laneHeight)
          .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
          // `.simultaneousGesture` on the scroll content (not the ScrollView) so
          // trackpad pinch-to-zoom and click-to-scrub coexist with horizontal pan —
          // distinct input events, and a drag cancels a tap natively. `.contentShape`
          // gives both gestures a hit region across the full lane, including the
          // transparent gaps between waveform peaks.
          .contentShape(Rectangle())
          // Click-to-scrub: `.local` on the scroll CONTENT is content space, so
          // `location.x / pointsPerSecond` is the clicked time — no scroll-offset math.
          .simultaneousGesture(
            SpatialTapGesture(coordinateSpace: .local)
              .onEnded { value in
                handleTap(atContentX: value.location.x, snapToBeat: !isCommandPressed)
              }
          )
          .simultaneousGesture(
            MagnifyGesture()
              .onChanged { value in
                if pinchBasePPS == nil {
                  // Capture the anchor ONCE. Cursor viewport-x (invariant to panning),
                  // or viewport-center when there's no active hover. The content-x is
                  // derived from the offset NOW (`currentOffsetX + vx`), so a pan before
                  // the pinch can't stale it. The viewport↔content origin coincidence
                  // holds while the ZStack is the sole scroll content with no leading
                  // gutter / contentMargins — revisit this mapping (and the tap gesture's
                  // content-space assumption) if that changes.
                  pinchBasePPS = pointsPerSecond
                  let vx = min(max(hoverViewportX ?? (laneWidth / 2), 0), laneWidth)
                  let cx = currentOffsetX + vx
                  pinchAnchorTime = Double(cx) / pointsPerSecond
                  pinchAnchorViewportX = vx
                }
                let base = pinchBasePPS ?? pointsPerSecond
                let lo = minPointsPerSecond
                let hi = max(80, lo * 4)
                let newPPS = min(max(base * value.magnification, lo), hi)
                // Own the offset during the pinch: disable the scroll view's automatic
                // content-offset adjustment so it doesn't fight our explicit scrollTo
                // when contentWidth changes in the same layout pass.
                var txn = Transaction()
                txn.scrollContentOffsetAdjustmentBehavior = .disabled
                withTransaction(txn) {
                  pointsPerSecond = newPPS
                  if let t = pinchAnchorTime, let vx = pinchAnchorViewportX {
                    scrollPosition.scrollTo(x: CGFloat(max(0, t * newPPS - Double(vx))))
                  }
                }
              }
              .onEnded { _ in
                pinchBasePPS = nil
                pinchAnchorTime = nil
                pinchAnchorViewportX = nil
              }
          )
        }
        .scrollPosition($scrollPosition)
        // Track the live scroll offset for the pinch-anchor mapping. Read only at
        // pinch start, so this firing during our own scrollTo is not a feedback loop.
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.x
        } action: { _, newX in
          currentOffsetX = newX
        }
        // Cursor position in VIEWPORT space (attached to the ScrollView, so `.local`
        // is the scroll-independent container frame). Feeds the pinch anchor.
        .onContinuousHover(coordinateSpace: .local) { phase in
          switch phase {
          case .active(let location): hoverViewportX = location.x
          case .ended: hoverViewportX = nil
          }
        }
        .onModifierKeysChanged(mask: .command, initial: true) { _, modifiers in
          isCommandPressed = modifiers.contains(.command)
        }
        // Measure only the lane WIDTH (layout-neutral). Width feeds the
        // fit-to-width zoom-out floor and the pinch anchor. The height is never
        // stored, so a rendered-height measurement can never feed back as the
        // content's required height (the loop that crashed the window).
        .onGeometryChange(for: CGFloat.self) { proxy in
          proxy.size.width
        } action: { newWidth in
          laneWidth = newWidth
          // Re-clamp on resize / first layout so the displayed zoom never sits
          // below the new fit-to-width floor. Compute the floor from `newWidth`
          // directly (not the `minPointsPerSecond` computed prop) so it doesn't
          // read the just-written `laneWidth` @State one layout pass stale.
          let lo = minPointsPerSecond(for: newWidth)
          let hi = max(80, lo * 4)
          let clamped = min(max(pointsPerSecond, lo), hi)
          if pointsPerSecond != clamped { pointsPerSecond = clamped }
        }
      }
      // The wrapper GeometryReader is the sole vertically-greedy child of this
      // VStack (controls / readout stay intrinsic below). A 120pt floor matches
      // the LoudnessGraphView lane so a short window keeps a usable waveform
      // height instead of compressing it toward zero. The floor does NOT raise
      // the window's `.contentMinSize` minimum: the outer vertical ScrollView is
      // the compressible element (the same reasoning that makes the Loudness
      // floor safe), so a short window scrolls rather than the lane vanishing.
      .frame(minHeight: 120, maxHeight: .infinity)
      controls
      readout
    }
  }

  // MARK: - Scrubber (KDD-D2: only the marker animates; the grid Canvas never
  // redraws per frame)

  /// The playhead marker layer inside the scroll content. While PLAYING,
  /// `TimelineView(.animation)` re-reads the live engine playhead each display
  /// frame; while paused, a static marker reads the observable `currentTime`
  /// snapshot (written by `pause`/`seek`), so a paused seek redraws exactly once.
  /// A positioned 1.5-pt Rectangle, NOT a content-width Canvas — at high zoom the
  /// content is tens of thousands of points wide and a per-frame full-width
  /// raster would be a real cost; an offset Rectangle is layout-only per frame.
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
      // Fill the lane height from the parent: the enclosing ZStack has a definite
      // height (the slot height forwarded by the wrapper GeometryReader), so
      // `maxHeight: .infinity` resolves against that finite height — never a
      // stored self-measurement.
      .frame(width: 1.5)
      .frame(maxHeight: .infinity)
      .offset(
        x: Self.scrubberX(time: time, pointsPerSecond: pointsPerSecond, contentWidth: contentWidth)
          - 0.75
      )
      // The playhead must never swallow a click at its own position.
      .allowsHitTesting(false)
  }

  // MARK: - Click-to-scrub

  /// A plain click seeks to the nearest raw detected beat; Command-click seeks
  /// to the exact waveform time. Either starts playback when paused.
  private func handleTap(atContentX x: CGFloat, snapToBeat: Bool) {
    guard controller.hasAudio else { return }
    let beatTimes = state.beatGrid.beats.map(\.presentationTime)
    guard
      let target = Self.clickSeekTime(
        contentX: x, pointsPerSecond: pointsPerSecond, beatTimes: beatTimes,
        snapToBeat: snapToBeat)
    else { return }
    controller.seek(to: target)
    if !controller.isPlaying {
      controller.play()
    }
  }

  // MARK: - Derived geometry

  /// Fit-to-width zoom-out floor: the points-per-second at which the waveform
  /// exactly fills the visible lane. Pinch-out cannot go below this, so the
  /// waveform never shrinks narrower than the lane (no right-side dead space).
  private var minPointsPerSecond: Double { minPointsPerSecond(for: laneWidth) }

  /// The fit-to-width floor for an explicit lane width. The width-measurement
  /// callback passes its fresh `newWidth` here so the re-clamp doesn't read the
  /// just-written `laneWidth` @State one layout pass stale.
  private func minPointsPerSecond(for width: CGFloat) -> Double {
    guard width > 0, effectiveDuration > 0 else { return 4 }
    return Double(width) / effectiveDuration
  }

  /// X-axis span. Prefers the decoded waveform duration; falls back to the last
  /// detected beat when the waveform decode failed (`duration == 0`), so the
  /// grid still has a coordinate system.
  private var effectiveDuration: Double {
    if state.duration > 0 { return state.duration }
    let lastBeat = state.beatGrid.beats.last?.presentationTime ?? 0
    return max(lastBeat, 1)
  }

  private var contentWidth: CGFloat {
    max(CGFloat(effectiveDuration * pointsPerSecond), 1)
  }

  private var anchorTime: Double? { state.beatGrid.gridOrigin?.presentationTime }

  private var downbeatTimes: [Double] {
    if case .detected(let estimate) = state.beatGrid.downbeats {
      return estimate.beats.map(\.presentationTime)
    }
    return []
  }

  // MARK: - Controls (transport + raw-beats toggle)

  // Sits below the waveform (the Zoom slider was replaced by trackpad
  // pinch-to-zoom; the legend (?) lives next to the GroupBox title). The
  // play/pause button fronts the row; clicking the lane is the primary seek
  // interaction (see `handleTap`).
  @ViewBuilder
  private var controls: some View {
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
          ? "Play or pause. Click to jump to the nearest beat, or Command-click for an exact time"
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

      Toggle("Show raw beat indicators", isOn: $showRawBeats)
        .toggleStyle(.checkbox)
        .font(.caption)
    }
  }

  // MARK: - Readout (FR-44: every value behind a label)

  @ViewBuilder
  private var readout: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        AnalysisMetadataChip(
          label: "Estimated tempo", value: Self.tempoValue(state.beatGrid.estimatedTempo))
        AnalysisMetadataChip(label: "Beat count", value: "\(state.beatGrid.beats.count)")
        AnalysisMetadataChip(
          label: "Downbeat status", value: Self.downbeatStatusLabel(state.beatGrid.downbeats))
        AnalysisMetadataChip(
          label: "Grid confidence", value: Self.gridConfidenceValue(state.beatGrid.confidence))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Drawing

  private func x(for time: Double, width: CGFloat) -> CGFloat {
    CGFloat(time / effectiveDuration) * width
  }

  private func draw(in context: GraphicsContext, size: CGSize) {
    let width = size.width
    let midY = size.height / 2

    // Waveform: a single closed, filled, mirrored envelope (DAW-style) — top edge
    // left-to-right, bottom edge right-to-left, closed and filled. Much cleaner
    // than per-column ticks.
    let count = state.peaks.count
    if count > 0 {
      let amp = size.height / 2 * 0.92
      func columnX(_ i: Int) -> CGFloat { (CGFloat(i) + 0.5) / CGFloat(count) * width }
      func peak(_ i: Int) -> CGFloat {
        let p = state.peaks[i]
        return CGFloat(max(0, min(1, p.isFinite ? p : 0)))
      }
      var env = Path()
      env.move(to: CGPoint(x: columnX(0), y: midY - peak(0) * amp))
      for i in 1..<count {
        env.addLine(to: CGPoint(x: columnX(i), y: midY - peak(i) * amp))
      }
      for i in stride(from: count - 1, through: 0, by: -1) {
        env.addLine(to: CGPoint(x: columnX(i), y: midY + peak(i) * amp))
      }
      env.closeSubpath()
      context.fill(env, with: .color(.gray.opacity(0.45)))
    }

    // Raw detected beats (faint short ticks from the top) — secondary layer.
    if showRawBeats {
      var raw = Path()
      for beat in state.beatGrid.beats {
        let bx = x(for: beat.presentationTime, width: width)
        raw.move(to: CGPoint(x: bx, y: 0))
        raw.addLine(to: CGPoint(x: bx, y: size.height * 0.28))
      }
      context.stroke(raw, with: .color(.secondary.opacity(0.7)), lineWidth: 1)
    }

    // Extrapolated grid (the trustworthy layer) — full-height blue lines.
    var grid = Path()
    for t in Self.extrapolatedBeatTimes(
      anchor: anchorTime, tempo: state.beatGrid.estimatedTempo, span: effectiveDuration)
    {
      let gx = x(for: t, width: width)
      grid.move(to: CGPoint(x: gx, y: 0))
      grid.addLine(to: CGPoint(x: gx, y: size.height))
    }
    context.stroke(grid, with: .color(.blue.opacity(0.7)), lineWidth: 1)

    // Downbeats — full-height accents, distinguished from the blue grid by the
    // heavier pink stroke (color + weight, not height); the legend names them.
    var down = Path()
    for t in downbeatTimes {
      let dx = x(for: t, width: width)
      down.move(to: CGPoint(x: dx, y: 0))
      down.addLine(to: CGPoint(x: dx, y: size.height))
    }
    context.stroke(down, with: .color(.pink), lineWidth: 2)

    // Anchor — a distinct orange marker.
    if let anchorTime {
      let ax = x(for: anchorTime, width: width)
      var line = Path()
      line.move(to: CGPoint(x: ax, y: 0))
      line.addLine(to: CGPoint(x: ax, y: size.height))
      context.stroke(line, with: .color(.orange), lineWidth: 2)
      var tri = Path()
      tri.move(to: CGPoint(x: ax - 4, y: 0))
      tri.addLine(to: CGPoint(x: ax + 4, y: 0))
      tri.addLine(to: CGPoint(x: ax, y: 7))
      tri.closeSubpath()
      context.fill(tri, with: .color(.orange))
    }
  }

  // MARK: - Extrapolation (pure, unit-tested)

  /// The Rekordbox-style extrapolated grid: beat times `anchor + period·n`
  /// covering `[0, span]`, the drift-free grid the `BeatGrid` DocC says to trust
  /// over raw beats.
  ///
  /// Guards (returns `[]` on any failure, so the layer is simply absent):
  /// non-nil `anchor`, finite `tempo > 0.01`, finite `period`, finite
  /// `span > 0`; the emitted count is capped at 100k so a pathological
  /// tempo/span cannot allocate an unbounded array.
  nonisolated static func extrapolatedBeatTimes(
    anchor: Double?, tempo: Double, span: Double
  ) -> [Double] {
    guard let anchor, anchor.isFinite,
      tempo.isFinite, tempo > 0.01,
      span.isFinite, span > 0
    else { return [] }
    let period = 60.0 / tempo
    guard period.isFinite, period > 0 else { return [] }

    let cap = 100_000
    // First grid index at or below t == 0 (anchor may sit anywhere on the axis).
    // Bound the quotient before the Int conversion: a pathological-but-finite
    // anchor/period would otherwise trap `Int(_:)`, violating the helper's
    // "return [] on bad input" contract. 1e15 is well within Int range and far
    // beyond any analyzer-produced anchor.
    let startQuotient = ((0 - anchor) / period).rounded(.down)
    guard startQuotient.isFinite, abs(startQuotient) < 1e15 else { return [] }
    var n = Int(startQuotient)
    var times: [Double] = []
    while times.count < cap {
      let t = anchor + Double(n) * period
      if t > span { break }
      if t >= 0 { times.append(t) }
      n += 1
    }
    return times
  }

  // MARK: - Click / scrubber geometry (pure, unit-tested)

  /// Maps a click at content-x (the zoomed coordinate system, `x = time *
  /// pointsPerSecond`) to the seek target. When `snapToBeat` is true, it uses
  /// the nearest raw detected beat; otherwise it returns the raw clicked time.
  /// It falls back to that raw time when no beats exist. Returns `nil` for
  /// degenerate input (non-finite x, `pointsPerSecond`
  /// not finite-positive) so the tap is simply ignored. An exact-midpoint tie
  /// resolves to the earlier beat. Non-finite and negative `beatTimes` entries
  /// are ignored (unrepresentable from the production caller — `BeatTimestamp`
  /// clamps `presentationTime >= 0` at construction — but this pure helper
  /// enforces its own contract). The result is always `>= 0`;
  /// `PlaybackController.seek(to:)` owns the `[0, duration]` clamp.
  nonisolated static func clickSeekTime(
    contentX: CGFloat, pointsPerSecond: Double, beatTimes: [Double], snapToBeat: Bool = true
  ) -> Double? {
    guard contentX.isFinite, pointsPerSecond.isFinite, pointsPerSecond > 0 else {
      return nil
    }
    let rawTime = max(0, Double(contentX) / pointsPerSecond)
    guard rawTime.isFinite else { return nil }
    guard snapToBeat else { return rawTime }
    // Linear scan — beats number in the low thousands, no binary search needed.
    let nearest = beatTimes.filter { $0.isFinite && $0 >= 0 }.min { a, b in
      let da = abs(a - rawTime)
      let db = abs(b - rawTime)
      return da == db ? a < b : da < db
    }
    return nearest ?? rawTime
  }

  /// The scrubber x in the zoomed coordinate system: `time * pointsPerSecond`,
  /// clamped to `[0, contentWidth]` (playback past the analyzed span pins the
  /// marker at the right edge). Defends non-finite/degenerate input by
  /// returning 0.
  nonisolated static func scrubberX(
    time: Double, pointsPerSecond: Double, contentWidth: CGFloat
  ) -> CGFloat {
    guard time.isFinite, pointsPerSecond.isFinite, pointsPerSecond > 0,
      contentWidth.isFinite, contentWidth >= 0
    else { return 0 }
    let x = CGFloat(time * pointsPerSecond)
    return min(max(x, 0), contentWidth)
  }

  // MARK: - Readout labels (pure, unit-tested)

  /// FR-44 value for the tempo field: `%.2f BPM`, or `unavailable` for the `0.0`
  /// "no valid estimate" sentinel.
  nonisolated static func tempoValue(_ tempo: Double) -> String {
    guard tempo.isFinite, tempo > 0 else { return "unavailable" }
    return String(format: "%.2f BPM", tempo)
  }

  /// FR-44 value for the confidence field: two decimals in `[0, 1]`.
  nonisolated static func gridConfidenceValue(_ confidence: Float) -> String {
    let clamped = min(max(confidence.isFinite ? confidence : 0, 0), 1)
    return String(format: "%.2f", clamped)
  }

  /// The tri-state downbeat label (the real `DownbeatResult`, no "partial").
  nonisolated static func downbeatStatusLabel(_ result: DownbeatResult) -> String {
    switch result {
    case .detected: return "detected"
    case .noneDetected: return "not-detected"
    case .notAttempted: return "not-attempted"
    }
  }
}

/// The `(?)` help button shown next to the "Beat grid" title. Self-contained — it
/// owns the popover state and the annotated-legend content, so it can live in the
/// GroupBox label (outside `BeatGridView`).
struct BeatGridHelpButton: View {
  @State private var showLegendHelp = false

  var body: some View {
    Button {
      showLegendHelp.toggle()
    } label: {
      Image(systemName: "questionmark.circle")
    }
    .buttonStyle(.borderless)
    .controlSize(.small)
    .help("What do these layers mean?")
    .popover(isPresented: $showLegendHelp, arrowEdge: .bottom) {
      legendHelp.padding().frame(width: 360)
    }
  }

  // Full annotated legend: each layer's name + a plain-language explanation,
  // because "raw beats" vs "extrapolated grid" is meaningless without it.
  @ViewBuilder
  private var legendHelp: some View {
    VStack(alignment: .leading, spacing: 8) {
      legendRow(
        .blue, "Extrapolated grid",
        "The clean, evenly-spaced grid built from one anchor beat + the tempo. It never drifts, "
          + "and it's what the library tells a sync feature (like a DJ app) to lock onto.")
      legendRow(
        .secondary, "Raw beats",
        "Every individual beat the tracker actually detected, at the exact time it landed. These "
          + "wobble and can occasionally double or drop. Useful for spotting where detection "
          + "struggled, but not what you'd sync to. Toggle to hide.")
      legendRow(
        .pink, "Downbeats",
        "The detected start-of-bar beats (the \"1\" of each bar), shown only when the analyzer is "
          + "confident enough to mark them.")
      legendRow(
        .orange, "Anchor",
        "The single most-trusted beat that the extrapolated grid is built outward from.")
      legendRow(
        .primary, "Playhead",
        "The playback position. Click anywhere on the waveform to jump to the nearest "
          + "detected beat and start playback, or Command-click to seek to the exact waveform "
          + "time. Use either to audition whether the beat markers line up with the audio.")
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

/// The beat-grid numeric metadata, rendered as a `GroupBox` section for the trace
/// inspector — the same place the BPM-detection detail lives. Moved out of the
/// main-body waveform strip so that strip stays compact (waveform + controls only).
struct BeatGridDetailSection: View {
  let state: GridVisualizationState

  var body: some View {
    let grid = state.beatGrid
    GroupBox("Beat grid") {
      VStack(alignment: .leading, spacing: 6) {
        LabeledContent("Grid tempo") {
          Text(String(format: "%.2f BPM", grid.estimatedTempo)).monospacedDigit()
        }
        LabeledContent("BPM stage") {
          Text(String(format: "%.2f BPM", state.bpmTempo)).monospacedDigit()
        }
        LabeledContent("Agreement", value: agreementLabel)
        LabeledContent("Beats") {
          Text("\(grid.beats.count)").monospacedDigit()
        }
        LabeledContent("Downbeats", value: downbeatLabel)
        LabeledContent("Confidence") {
          Text(String(format: "%.0f%%", Double(grid.confidence) * 100)).monospacedDigit()
        }
        LabeledContent("Coverage", value: coverageLabel)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var agreementLabel: String {
    switch state.beatGrid.tempoAgreement {
    case .agree: return "agree"
    case .octaveEquivalent(let factor): return "octave ×\(factor)"
    case .disagree: return "disagree"
    case .notCompared: return "not compared"
    }
  }

  private var downbeatLabel: String {
    switch state.beatGrid.downbeats {
    case .detected(let estimate):
      return "\(estimate.beats.count) (\(estimate.meter.beatsPerBar)/4)"
    case .noneDetected: return "none"
    case .notAttempted: return "off"
    }
  }

  private var coverageLabel: String {
    switch state.beatGrid.coverage {
    case .fullTrack: return "full track"
    case .analysisWindow: return "analysis window"
    case .window(let seconds): return String(format: "window %.0fs", seconds)
    }
  }
}
