import SwiftUI

/// A compact, read-only label/value treatment for analysis metadata.
///
/// The chip deliberately has no button chrome or gesture: analysis values must
/// not suggest an editable control. Its explicit accessibility label and value
/// preserve the relationship when VoiceOver reads the compact visual layout.
struct AnalysisMetadataChip: View {
  let label: String
  let value: String
  var help: String?

  @ViewBuilder
  var body: some View {
    let accessibleChip =
      chip
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(label)
      .accessibilityValue(value)
    if let help {
      accessibleChip.accessibilityHint(help)
    } else {
      accessibleChip
    }
  }

  @ViewBuilder
  private var chip: some View {
    let content = VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.callout)
        .monospacedDigit()
    }
    .lineLimit(1)
    .padding(.horizontal, 8)
    .padding(.vertical, 5)
    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
    .overlay {
      RoundedRectangle(cornerRadius: 7)
        .strokeBorder(.quaternary, lineWidth: 0.5)
    }

    if let help {
      content.help(help)
    } else {
      content
    }
  }
}
