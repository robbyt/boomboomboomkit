import BoomBoomBoomKit
import SwiftUI

struct ContentView: View {
  @State private var viewModel = AnalysisViewModel()
  @State private var isDropTargeted: Bool = false

  var body: some View {
    VStack(spacing: 12) {
      primaryStateView
      bannerView
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    // Axiom A2 — `.contentShape(Rectangle())` must come AFTER `.frame()`
    // and BEFORE `.dropDestination` so padded margins register drops at
    // the visible border edge (`transferable-ref.md:622-635`).
    .contentShape(Rectangle())
    .dropDestination(for: URL.self) { urls, _ in
      viewModel.handleDrop(urls)
    } isTargeted: { targeted in
      isDropTargeted = targeted
    }
    .overlay(
      // DD #12 — 1pt accent-color border on hover, lightest-touch
      // valid drop-zone signal per Apple HIG conventions.
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color.accentColor, lineWidth: 1)
        .opacity(isDropTargeted ? 1 : 0)
    )
    // DD #15 / Codex C2 — LaunchServices document-open events
    // (Dock-icon drops, Finder Open With, `open -a`) flow through
    // `.onOpenURL`, NOT `.dropDestination`. Reuses `handleOpenURL`
    // which forwards to `analyze(url:autoStarted: true)` so the
    // stop-only security-scoped resource bracket applies (DD #4).
    .onOpenURL { url in
      viewModel.handleOpenURL(url)
    }
  }

  // MARK: - State-Driven Render (DD #10, #16)

  // Four primary states + a secondary banner that overlays when an
  // `errorMessage` co-exists with `analyzing` or `result` (DD #16).
  private enum DisplayState {
    case empty
    case analyzing(filename: String?, cancelling: Bool)
    case result(BPMResultRow)
    case errorOnly(String)
  }

  // Pre-formatted strings for the 5 result rows. Format choices per
  // DD #10: BPM `%.1f BPM`, confidence as percentage `%.0f%%`, elapsed
  // `%.2fs`, intensity raw integer.
  private struct BPMResultRow {
    let fileName: String
    let bpm: String
    let confidence: String
    let intensity: String
    let elapsed: String
  }

  private var displayState: DisplayState {
    if viewModel.isAnalyzing {
      return .analyzing(
        filename: viewModel.fileName,
        cancelling: viewModel.isCancelling
      )
    }
    if let bpm = viewModel.detectedBPM,
      let confidence = viewModel.confidence,
      let intensity = viewModel.effectiveIntensity,
      let elapsed = viewModel.elapsedSeconds
    {
      let row = BPMResultRow(
        fileName: viewModel.fileName ?? "—",
        bpm: String(format: "%.1f BPM", bpm),
        confidence: String(format: "%.0f%%", confidence * 100),
        intensity: "\(intensity.rawValue)",
        elapsed: String(format: "%.2fs", elapsed)
      )
      return .result(row)
    }
    if let message = viewModel.errorMessage {
      return .errorOnly(message)
    }
    return .empty
  }

  // DD #16: banner appears only when an `errorMessage` is present AND
  // the primary state is `analyzing` or `result`. In `errorOnly` the
  // message IS the primary content (no duplicate banner).
  private var bannerError: String? {
    guard let message = viewModel.errorMessage else { return nil }
    switch displayState {
    case .analyzing, .result:
      return message
    case .empty, .errorOnly:
      return nil
    }
  }

  @ViewBuilder
  private var primaryStateView: some View {
    switch displayState {
    case .empty:
      VStack(spacing: 8) {
        Text("Drop an audio file")
          .font(.title2)
        Text("Supported: WAV, AIFF, MP3, FLAC, M4A, CAF")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    case .analyzing(let filename, let cancelling):
      VStack(spacing: 8) {
        ProgressView()
        if let filename {
          Text(filename)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        if cancelling {
          Text("Cancelling previous analysis…")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    case .result(let row):
      resultView(row)
    case .errorOnly(let message):
      Text(message)
        .font(.callout)
        .foregroundStyle(.red)
        .multilineTextAlignment(.center)
    }
  }

  @ViewBuilder
  private var bannerView: some View {
    if let bannerError {
      Text(bannerError)
        .font(.callout)
        .foregroundStyle(.red)
        .multilineTextAlignment(.center)
    }
  }

  @ViewBuilder
  private func resultView(_ row: BPMResultRow) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      resultRow("File", row.fileName)
      resultRow("BPM", row.bpm)
      resultRow("Confidence", row.confidence)
      resultRow("Intensity", row.intensity)
      resultRow("Elapsed", row.elapsed)
    }
    .frame(maxWidth: 360)
  }

  @ViewBuilder
  private func resultRow(_ label: String, _ value: String) -> some View {
    HStack {
      Text("\(label):")
      Spacer()
      Text(value).monospacedDigit()
    }
  }
}
