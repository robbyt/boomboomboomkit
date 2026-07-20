import SwiftUI

// Oversized drop-zone empty state per AC #12 / KDD #5. Replaces the
// inline two-line text block that the demo shipped through Story 5-5.
// First impression of the app and the App Store screenshot subject.
// The SF Symbol is marked `accessibilityHidden(true)` because the
// headline + caption already convey the affordance to VoiceOver —
// reading "music.note.list, image, Drop a track, Supported: …" is
// noisy without adding information.
struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "music.note.list")
        .font(.system(size: 96))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      Text("Drop a track")
        .font(.largeTitle)
      Text("Supported: WAV, AIFF, MP3, FLAC, M4A, CAF")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    // Intrinsic height (NOT `maxHeight: .infinity`): a compact drop affordance
    // sized to its contents + standard vertical padding, so it does not balloon
    // to fill a tall window. The call site no longer fills the empty state
    // either (see `heroFillsPane` in ContentView).
    .padding(.vertical)
    .frame(maxWidth: .infinity)
    .fixedSize(horizontal: false, vertical: true)
    .accessibilityElement(children: .combine)
    .accessibilityHint("Drag an audio file here to analyze")
  }
}
