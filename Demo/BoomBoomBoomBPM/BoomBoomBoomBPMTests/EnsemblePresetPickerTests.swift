import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Story 9.1 — EnsemblePreset mapping, persistence, and per-run propagation.
// Persistence tests mirror `MergeStrategyPersistenceTests` isolation hygiene:
// unique `UserDefaults(suiteName:)` per test + `removePersistentDomain`
// cleanup, `try #require` (never force-unwrap) per PR #16 review finding.
@Suite("Ensemble preset picker")
struct EnsemblePresetPickerTests {

  // MARK: - Helpers

  @MainActor
  private static func makeViewModel(
    suiteName: String,
    fallbackPreset: EnsemblePreset = .default
  ) throws -> (viewModel: AnalysisViewModel, defaults: UserDefaults) {
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum,
        fallbackPreset: fallbackPreset
      )
    )
    return (viewModel, defaults)
  }

  private static func cleanUp(_ suiteName: String) {
    UserDefaults.standard.removePersistentDomain(forName: suiteName)
  }

  // Minimal MLTechnique conformer for the DD3 precedence tests. Returns a
  // fixed evaluation so `trace.ensembleDecision` populates whenever the
  // technique is attached AND the active policy invokes ML.
  private struct StubTechnique: MLTechnique {
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? {
      MLEvaluation(bpm: 120.0, confidence: 0.9, modelIdentifier: "stub")
    }
  }

  // Real-run helper per the established smoke-test pattern
  // (`AnalysisViewModelSmokeTest.wrapping`): analyze the click fixture and
  // poll `isAnalyzing` with a 30 s ceiling.
  @MainActor
  private static func runAnalysis(_ viewModel: AnalysisViewModel) async throws {
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    viewModel.analyze(url: url)
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "analyze(url:) did not complete within 30s")
  }

  // MARK: - KDD-D1 mapping (AC2)

  @Test("preset mapping matches KDD-D1 exactly")
  @MainActor
  func presetMappingMatchesKDDD1() {
    #expect(EnsemblePreset.default.policy == .default)
    #expect(EnsemblePreset.dspOnly.policy == .dspOnly)
    #expect(
      EnsemblePreset.mlAugmented.policy
        == .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.5, fileMetadata: 1.0, beatGrid: 1.0)))
    #expect(
      EnsemblePreset.trustFileTags.policy
        == .weightedVoting(SignalWeights(dsp: 1.0, ml: 1.0, fileMetadata: 2.0, beatGrid: 1.0)))
    // `Default` maps to the named case — behaviorally equivalent to
    // `.weightedVoting(.default)` but a DISTINCT case; the per-run
    // options-equality assertions depend on this exact spelling.
    #expect(EnsemblePreset.default.policy != .weightedVoting(.default))
    // Exactly four presets, no fifth raw-weights option (AC1).
    #expect(EnsemblePreset.allCases.count == 4)
  }

  // Drift-lock (code-review follow-up): `policyLiteral` is a hand-mirrored
  // string — a future weight change to `policy` without the matching
  // literal edit would ship an unreproducible Copy Config snippet. Derive
  // the expectation from the resolved policy itself.
  @Test("policyLiteral mirrors the resolved policy weights", arguments: EnsemblePreset.allCases)
  @MainActor
  func policyLiteralMirrorsPolicy(_ preset: EnsemblePreset) {
    switch preset.policy {
    case .default:
      #expect(preset.policyLiteral == ".default")
    case .dspOnly:
      #expect(preset.policyLiteral == ".dspOnly")
    case .weightedVoting(let weights):
      #expect(
        preset.policyLiteral
          == ".weightedVoting(SignalWeights(dsp: \(weights.dsp), ml: \(weights.ml), "
          + "fileMetadata: \(weights.fileMetadata), beatGrid: \(weights.beatGrid)))"
      )
    case .mlOnly, .highestConfidence:
      Issue.record("no preset maps to \(preset.policy.stableKey)")
    }
  }

  // MARK: - Verbatim row content (AC6)

  @Test("display names and subtitles match the authored contract verbatim")
  @MainActor
  func verbatimNamesAndSubtitles() {
    // Names and subtitles asserted independently (not just the joined
    // string) so a degenerate mis-split cannot pass — code-review follow-up.
    #expect(
      EnsemblePreset.allCases.map(\.displayName)
        == ["Default", "DSP only", "ML augmented", "Trust file tags"])
    #expect(
      EnsemblePreset.allCases.map(\.subtitle)
        == [
          "balanced ensemble",
          "disables ML, fastest",
          "adds the trained classifier",
          "prefer ID3/MP4/Vorbis tempo tags",
        ])
    // The authored AC contract strings, reconstructed exactly.
    let expected: [EnsemblePreset: String] = [
      .default: "Default — balanced ensemble",
      .dspOnly: "DSP only — disables ML, fastest",
      .mlAugmented: "ML augmented — adds the trained classifier",
      .trustFileTags: "Trust file tags — prefer ID3/MP4/Vorbis tempo tags",
    ]
    for preset in EnsemblePreset.allCases {
      #expect("\(preset.displayName) — \(preset.subtitle)" == expected[preset])
    }
  }

  // MARK: - Persistence (AC4)

  @Test("hydrate falls back to fallbackPreset when key absent")
  @MainActor
  func hydrateAbsentKey() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.absent"
    // Pre-clean BEFORE construction: a crashed prior run could have left a
    // value in this suite, and this test's premise is key absence
    // (code-review follow-up).
    Self.cleanUp(suiteName)
    let (viewModel, defaults) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    #expect(viewModel.selectedEnsemblePreset == .default)
    // Did NOT write — absent stays absent.
    #expect(defaults.string(forKey: AnalysisViewModel.preferredEnsemblePresetKey) == nil)
  }

  @Test("hydrate decodes valid stored case identifier", arguments: EnsemblePreset.allCases)
  @MainActor
  func hydrateValidRawValue(_ stored: EnsemblePreset) throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.valid.\(stored.rawValue)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { Self.cleanUp(suiteName) }
    defaults.set(stored.rawValue, forKey: AnalysisViewModel.preferredEnsemblePresetKey)

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )

    #expect(viewModel.selectedEnsemblePreset == stored)
    // Hydration must not mutate the stored value on the success path.
    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredEnsemblePresetKey) == stored.rawValue
    )
  }

  @Test("persist writes the case identifier and a fresh VM round-trips it")
  @MainActor
  func persistRoundTrip() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.roundtrip"
    let (viewModel, defaults) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    viewModel.selectedEnsemblePreset = .mlAugmented
    viewModel.persistPreferredEnsemblePreset()

    // Case identifier on disk — never raw SignalWeights floats.
    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredEnsemblePresetKey) == "mlAugmented"
    )

    let rehydrated = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )
    #expect(rehydrated.selectedEnsemblePreset == .mlAugmented)
  }

  @Test("hydrate self-heals on unrecognized stored case identifier")
  @MainActor
  func hydrateSelfHealsInvalidRawValue() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.invalid"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { Self.cleanUp(suiteName) }
    defaults.set("bogusPreset", forKey: AnalysisViewModel.preferredEnsemblePresetKey)

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )

    // In-memory: fell back to the configured default.
    #expect(viewModel.selectedEnsemblePreset == .default)
    // On disk: the bad key has been removed (self-heal contract).
    #expect(defaults.string(forKey: AnalysisViewModel.preferredEnsemblePresetKey) == nil)
  }

  @Test("preset persistence neither overwrites nor self-heals the merge-strategy key")
  @MainActor
  func dualPreferenceIsolation() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.dualpref"
    let (viewModel, defaults) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    viewModel.options.mergeStrategy = .median
    viewModel.persistPreferredMergeStrategy()
    viewModel.selectedEnsemblePreset = .trustFileTags
    viewModel.persistPreferredEnsemblePreset()

    // Both keys coexist in the same suite, each with its own value.
    #expect(defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == "median")
    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredEnsemblePresetKey) == "trustFileTags"
    )

    // A fresh VM hydrates BOTH preferences; neither self-heals the other.
    let rehydrated = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )
    #expect(rehydrated.options.mergeStrategy == .median)
    #expect(rehydrated.selectedEnsemblePreset == .trustFileTags)
    #expect(defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == "median")
  }

  // MARK: - No-cascade (DD5)

  @Test("setting the preset does not mutate options.mergeStrategy")
  @MainActor
  func presetChangeDoesNotTouchMergeStrategy() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.nocascade"
    let (viewModel, _) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    let before = viewModel.options.mergeStrategy
    for preset in EnsemblePreset.allCases {
      viewModel.selectedEnsemblePreset = preset
      #expect(viewModel.options.mergeStrategy == before)
    }
  }

  // MARK: - Per-run propagation (AC3)

  @Test(
    "per-run options carry the preset's exact policy (full-policy equality)",
    arguments: [EnsemblePreset.mlAugmented, EnsemblePreset.trustFileTags]
  )
  @MainActor
  func perRunPropagation(_ preset: EnsemblePreset) async throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.propagate.\(preset.rawValue)"
    let (viewModel, _) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    viewModel.selectedEnsemblePreset = preset
    try await Self.runAnalysis(viewModel)

    let snapshot = try #require(viewModel.lastRunSnapshot)
    // Full-policy equality — `stableKey` collapses both weightedVoting
    // presets to the same string and cannot make this distinction.
    #expect(snapshot.runOptions.ensemblePolicy == preset.policy)
  }

  // MARK: - BYOW precedence (AC8 / DD3)

  @Test("attached+enabled model no longer forces .mlOnly — preset policy wins")
  @MainActor
  func attachedModelDoesNotForceMLOnly() async throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.precedence"
    let (viewModel, _) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    viewModel.selectedEnsemblePreset = .mlAugmented
    viewModel.attachMLTechnique(StubTechnique(), named: "stub.mlmodelc")
    // attachMLTechnique sets the full success quartet (DD3).
    #expect(viewModel.mlModelName == "stub.mlmodelc")
    #expect(viewModel.mlEnabled)
    #expect(viewModel.mlModelError == nil)

    try await Self.runAnalysis(viewModel)

    let snapshot = try #require(viewModel.lastRunSnapshot)
    #expect(snapshot.runOptions.ensemblePolicy == EnsemblePreset.mlAugmented.policy)
    #expect(snapshot.runOptions.ensemblePolicy != .mlOnly)
    // AC8's full options contract: the BYOW block set the diagnostics gate.
    #expect(snapshot.runOptions.enableMLDiagnostics)
    // The stub actually participated: weighted policies emit
    // `EnsembleWeightResolution` (NOT `EnsembleDecision` — that record
    // belongs to `.mlOnly`/`.highestConfidence`), and a non-nil
    // `mlEffectiveVote` proves the ML voice was in the resolution
    // (`RunOptionsSnapshot` carries no `mlTechnique` field, so attachment
    // is proven behaviorally rather than asserted directly).
    let resolution = try #require(snapshot.trace.ensembleWeightResolution)
    #expect(resolution.mlEffectiveVote != nil)
  }

  @Test("toggle off keeps ML absent from the run while the preset stands")
  @MainActor
  func toggleOffKeepsMLAbsent() async throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.preset.toggleoff"
    let (viewModel, _) = try Self.makeViewModel(suiteName: suiteName)
    defer { Self.cleanUp(suiteName) }

    viewModel.selectedEnsemblePreset = .mlAugmented
    viewModel.attachMLTechnique(StubTechnique(), named: "stub.mlmodelc")
    viewModel.mlEnabled = false

    try await Self.runAnalysis(viewModel)

    let snapshot = try #require(viewModel.lastRunSnapshot)
    // Policy still the preset's; no technique attached -> the weighted
    // resolution records NO ML voice (`mlEffectiveVote == nil`). The paired
    // positive test above proves the same fixture+preset DOES produce an ML
    // vote when the toggle is on, so this nil is meaningful, not vacuous.
    #expect(snapshot.runOptions.ensemblePolicy == EnsemblePreset.mlAugmented.policy)
    // Toggle off -> the BYOW block never ran -> diagnostics gate stays off.
    #expect(!snapshot.runOptions.enableMLDiagnostics)
    #expect(snapshot.trace.ensembleWeightResolution?.mlEffectiveVote == nil)
    #expect(snapshot.trace.ensembleDecision == nil)
  }
}
