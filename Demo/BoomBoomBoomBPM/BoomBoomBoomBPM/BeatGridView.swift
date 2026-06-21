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
}

/// Horizontal beat-grid + waveform overlay. Shows the **extrapolated** grid
/// (the trustworthy `anchor + period·n` line the F-measure is scored on) as the
/// primary layer and the **raw detected beats** as a faint secondary layer, so
/// raw-vs-extrapolated drift — and drift against the waveform transients — is
/// directly visible. This is the inspection surface for refining the tracker;
/// it is the estimate against the audio, not accuracy vs a ground-truth oracle.
struct BeatGridView: View {
  let state: GridVisualizationState

  @State private var pointsPerSecond: Double = 16
  @State private var showRawBeats: Bool = true

  private let laneHeight: CGFloat = 84

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      header
      controls
      ScrollView(.horizontal, showsIndicators: true) {
        Canvas { context, size in draw(in: context, size: size) }
          .frame(width: contentWidth, height: laneHeight)
          .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
      }
      legend
    }
  }

  // MARK: - Derived geometry

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

  // MARK: - Header / controls / legend

  @ViewBuilder
  private var header: some View {
    let grid = state.beatGrid
    VStack(alignment: .leading, spacing: 2) {
      Text(
        String(
          format: "Grid tempo %.2f BPM   ·   BPM stage %.2f   ·   %@",
          grid.estimatedTempo, state.bpmTempo, agreementLabel)
      )
      .font(.caption).monospacedDigit()
      Text(
        String(
          format: "%d beats   ·   %@   ·   confidence %.0f%%   ·   %@",
          grid.beats.count, downbeatLabel, Double(grid.confidence) * 100,
          coverageLabel)
      )
      .font(.caption).foregroundStyle(.secondary).monospacedDigit()
    }
  }

  @ViewBuilder
  private var controls: some View {
    HStack(spacing: 12) {
      Toggle("Raw beats", isOn: $showRawBeats)
        .toggleStyle(.checkbox)
        .font(.caption)
      HStack(spacing: 4) {
        Text("Zoom").font(.caption).foregroundStyle(.secondary)
        Slider(value: $pointsPerSecond, in: 4...80)
          .frame(width: 140)
      }
    }
  }

  @ViewBuilder
  private var legend: some View {
    HStack(spacing: 12) {
      legendSwatch(.blue, "extrapolated grid")
      if showRawBeats { legendSwatch(.secondary, "raw beats") }
      legendSwatch(.pink, "downbeats")
      legendSwatch(.orange, "anchor")
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private func legendSwatch(_ color: Color, _ label: String) -> some View {
    HStack(spacing: 3) {
      Rectangle().fill(color).frame(width: 10, height: 3)
      Text(label)
    }
  }

  // MARK: - Labels

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
      return "\(estimate.beats.count) downbeats \(estimate.meter.beatsPerBar)/4"
    case .noneDetected: return "downbeats: none"
    case .notAttempted: return "downbeats: off"
    }
  }

  private var coverageLabel: String {
    switch state.beatGrid.coverage {
    case .fullTrack: return "full track"
    case .analysisWindow: return "analysis window"
    case .window(let seconds): return String(format: "window %.0fs", seconds)
    }
  }

  // MARK: - Drawing

  private func x(for time: Double, width: CGFloat) -> CGFloat {
    CGFloat(time / effectiveDuration) * width
  }

  private func draw(in context: GraphicsContext, size: CGSize) {
    let width = size.width
    let midY = size.height / 2

    // Waveform envelope (one path, light gray) centered on the midline.
    if !state.peaks.isEmpty {
      var wave = Path()
      let amp = size.height / 2 * 0.9
      let count = state.peaks.count
      for i in 0..<count {
        let cx = (CGFloat(i) + 0.5) / CGFloat(count) * width
        let h = CGFloat(state.peaks[i]) * amp
        wave.move(to: CGPoint(x: cx, y: midY - h))
        wave.addLine(to: CGPoint(x: cx, y: midY + h))
      }
      context.stroke(wave, with: .color(.gray.opacity(0.55)), lineWidth: 1)
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

    // Downbeats — taller accent lines.
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
}
