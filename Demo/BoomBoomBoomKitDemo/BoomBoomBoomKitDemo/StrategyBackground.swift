import BoomBoomBoomKit
import SwiftUI

// Strategy-keyed background painted at the `ContentView` root (KDD #8
// / AC #4). One `LinearGradient` per `CandidateMergeStrategy` case
// plus a 9th neutral variant for the pre-analysis state (when
// `viewModel.lastRunSnapshot == nil`, the user hasn't selected
// anything yet — the visual should be quiet, not assertive).
//
// Color choice rationale (AC #6):
//   - Hero BPM at 96pt bold qualifies as WCAG "large text" (clears
//     3:1 contrast floor).
//   - Supporting metadata at `.callout` clears the 4.5:1 body floor.
//   - Dev agent spot-checks via Digital Color Meter at close-out and
//     records the 9 measured ratios in the Completion Notes.
//   - Apple's dynamic-color anchors (`.blue`, `.teal`, etc.) adapt
//     between Light / Dark and across accessibility settings without
//     hard-coded RGB.
//
// Increased-contrast (`@Environment(\.colorSchemeContrast) ==
// .increased`) substitutes a low-opacity solid fill for the gradient
// per AC #7 — gradients can wash out contrast hot-spots on
// accessibility hardware.
struct StrategyBackground: View {
  let strategy: CandidateMergeStrategy?

  @Environment(\.colorSchemeContrast) private var contrast

  var body: some View {
    if contrast == .increased {
      solidFill
    } else {
      gradient
    }
  }

  // MARK: - Gradient variants

  // Each variant uses two-anchor `LinearGradient`s; the diagonal
  // (`topLeading` → `bottomTrailing`) reads naturally on a wide
  // window and avoids competing with the BPM hero's top-right
  // alignment by keeping the brighter anchor away from the text.
  @ViewBuilder
  private var gradient: some View {
    switch strategy {
    case .maxConfidence:
      gradientFill(top: .blue, bottom: .indigo)
    case .dedup:
      gradientFill(top: .teal, bottom: .cyan)
    case .quorum:
      gradientFill(top: .indigo, bottom: .purple)
    case .average:
      gradientFill(top: .green, bottom: .teal)
    case .median:
      gradientFill(top: .mint, bottom: .green)
    case .weightedAverage:
      gradientFill(top: .purple, bottom: .indigo)
    case .union:
      gradientFill(top: .pink, bottom: .purple)
    case .windowVoting:
      gradientFill(top: .orange, bottom: .pink)
    case .none:
      // Pre-analysis: quiet, low-saturation. Reads as "blank canvas,
      // waiting for input" rather than asserting a result-domain
      // visual identity. `Color(nsColor:)` (labeled `nsColor:` is
      // required — bare `Color(NSColor.foo)` resolves to the
      // asset-catalog overload `Color(_ name:bundle:)` and silently
      // returns a placeholder). Dynamic colors adapt Light/Dark and
      // Increased Contrast.
      gradientFill(
        top: Color(nsColor: .windowBackgroundColor),
        bottom: Color(nsColor: .underPageBackgroundColor)
      )
    }
  }

  private func gradientFill(top: Color, bottom: Color) -> some View {
    LinearGradient(
      colors: [top.opacity(0.18), bottom.opacity(0.32)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  // MARK: - Solid fill (increased contrast)

  @ViewBuilder
  private var solidFill: some View {
    Group {
      switch strategy {
      case .maxConfidence: Color.blue.opacity(0.15)
      case .dedup: Color.teal.opacity(0.15)
      case .quorum: Color.indigo.opacity(0.15)
      case .average: Color.green.opacity(0.15)
      case .median: Color.mint.opacity(0.15)
      case .weightedAverage: Color.purple.opacity(0.15)
      case .union: Color.pink.opacity(0.15)
      case .windowVoting: Color.orange.opacity(0.15)
      case .none: Color.gray.opacity(0.15)
      }
    }
  }
}
