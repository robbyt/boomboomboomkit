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

  // REPLACED BY Story 10.5: subtitle becomes a "?" popover wired to Epic 11 docs via BoomBoomBoomKitDocs.attributedString(for:id:)
  //
  // Inline-authored subtitle line rendered beneath the row title. The
  // authored contract strings are "<displayName> — <subtitle>" (e.g.
  // "Default — balanced ensemble"); the title carries the name, so only the
  // text after the em dash renders here. The seam is the text, not the
  // layout — Story 10.5 swaps this property for the popover accessor.
  var subtitle: String {
    switch self {
    case .default: return "balanced ensemble"
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

// Primary-view preset picker (FR-36). Four visible rows — radio group per
// Apple's two-to-five-options guidance — each with the title and the
// inline-authored caption. Lives OUTSIDE the inspector per FR-43: it must
// stay functional with the sidebar closed. No fifth raw-weights row; raw
// per-source weights are sidebar territory (Story 9.2+).
struct EnsemblePresetPicker: View {
  @Binding var selection: EnsemblePreset

  var body: some View {
    Picker("Ensemble preset", selection: $selection) {
      ForEach(EnsemblePreset.allCases, id: \.self) { preset in
        VStack(alignment: .leading, spacing: 2) {
          Text(preset.displayName)
          Text(preset.subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .tag(preset)
      }
    }
    .pickerStyle(.radioGroup)
    // The enclosing GroupBox("Ensemble") carries the visible section title;
    // the Picker label stays for accessibility only.
    .labelsHidden()
  }
}
