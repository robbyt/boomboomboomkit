import BoomBoomBoomKit
import SwiftUI

// MARK: - EnsemblePreset

// The demo's four named ensemble presets (FR-36 / KDD-D1). The raw value is
// the persisted case identifier (`preferredEnsemblePreset` in UserDefaults) —
// NEVER raw `SignalWeights` floats, so post-1.0 preset-table changes don't
// poison stored state. A demo-side enum because the library's
// `EnsemblePolicy` is not RawRepresentable (`.weightedVoting` carries an
// associated value) and its `stableKey` collapses both weight-bearing
// presets to the same "weightedVoting" string.
enum EnsemblePreset: String, CaseIterable, Sendable {
  case `default` = "default"
  case dspOnly = "dspOnly"
  case mlAugmented = "mlAugmented"
  case trustFileTags = "trustFileTags"

  // Row title, verbatim per the Story 9.1 AC — hard-coded, not humanized.
  var displayName: String {
    switch self {
    case .default: return "Default"
    case .dspOnly: return "DSP only"
    case .mlAugmented: return "ML augmented"
    case .trustFileTags: return "Trust file tags"
    }
  }

  // Inline-authored per-preset description. This IS the standalone description
  // fragment (there is no runtime em-dash parsing); EnsemblePresetPicker renders
  // it verbatim as the caption line below the pop-up, updating with the
  // selection. The "<displayName> — <subtitle>" form is only the joined *test*
  // contract (`verbatimNamesAndSubtitles`), never a runtime string. The seam is
  // the text, not the layout.
  //
  // NOTE: the earlier plan (Story 10.5) was to replace this with a "?" popover
  // wired to Epic 11 docs; this inline dynamic description supersedes that for
  // this control. Story 10.5's popovers may still cover the DSP-technique /
  // merge-strategy controls.
  var subtitle: String {
    switch self {
    case .default:
      return "Balanced weighting of DSP, ML, and file-tag signals (the recommended default)."
    case .dspOnly: return "disables ML, fastest"
    case .mlAugmented: return "adds the trained classifier"
    case .trustFileTags: return "prefer ID3/MP4/Vorbis tempo tags"
    }
  }

  // KDD-D1 preset-to-policy mapping, locked by
  // `EnsemblePresetPickerTests.presetMappingMatchesKDDD1`. `Default` maps to
  // the named `.default` case — behaviorally equivalent to
  // `.weightedVoting(.default)` but a DISTINCT case; the per-run
  // options-equality assertion depends on this exact spelling. The
  // `beatGrid: 1.0` weight is a forward seam: `SignalSource.beatGrid` has no
  // pool producer yet (deferred-work W53).
  var policy: EnsemblePolicy {
    switch self {
    case .default:
      return .default
    case .dspOnly:
      return .dspOnly
    case .mlAugmented:
      return .weightedVoting(
        SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0))
    case .trustFileTags:
      return .weightedVoting(
        SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0))
    }
  }

  // Copy-pasteable Swift literal for `generateConfigSnippet` — mirrors
  // `policy` exactly so the copied config reproduces the picker's run.
  var policyLiteral: String {
    switch self {
    case .default:
      return ".default"
    case .dspOnly:
      return ".dspOnly"
    case .mlAugmented:
      return ".weightedVoting(SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0))"
    case .trustFileTags:
      return ".weightedVoting(SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0))"
    }
  }
}

// MARK: - EnsemblePresetPicker

// Primary-view preset picker (FR-36). A pop-up menu paired with the Merge
// strategy control, with a single description line below that updates as the
// selection changes. Lives OUTSIDE the inspector per FR-43: it must stay
// functional with the sidebar closed. No fifth raw-weights row; raw
// per-source weights are sidebar territory (Story 9.2+).
struct EnsemblePresetPicker: View {
  @Binding var selection: EnsemblePreset

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Standalone title on its own line so this column matches the Merge
      // strategy layout (title / dropdown / subtitle). Decorative + a11y-hidden:
      // `.labelsHidden()` below keeps the Picker's "Ensemble" label for
      // VoiceOver, so the Picker stays the single accessible control and this
      // visible Text does not become a duplicate announcement.
      Text("Ensemble")
        .accessibilityHidden(true)
      // Label-hidden menu pop-up (matches the Merge strategy Picker it sits
      // beside — the title moved to the standalone Text above).
      Picker("Ensemble", selection: $selection) {
        ForEach(EnsemblePreset.allCases, id: \.self) { preset in
          // Visual menu title stays the terse name; VoiceOver gets the full
          // "<name>, <description>" so the per-option guidance survives the
          // radio-group → menu conversion (a11y parity while browsing).
          Text(preset.displayName)
            .tag(preset)
            .accessibilityLabel("\(preset.displayName), \(preset.subtitle)")
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      // Dynamic description — the selected preset's authored subtitle, now a
      // single caption that updates with the selection instead of four
      // always-on radio-row captions. `.fixedSize(vertical:)` matches the Merge
      // strategy description's wrap/compression resistance at narrow widths and
      // larger Dynamic Type.
      Text(selection.subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
