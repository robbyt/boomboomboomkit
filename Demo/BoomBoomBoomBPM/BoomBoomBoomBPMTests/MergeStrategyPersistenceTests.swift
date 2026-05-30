import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Each test uses a unique `UserDefaults(suiteName:)` and cleans up via
// `removePersistentDomain(forName:)` so cases run independently in any
// order, in parallel, without contaminating each other or the operator's
// `.standard` prefs. Suite names are namespaced under the test target to
// avoid colliding with the production app's UserDefaults domain.
@Suite("Merge strategy persistence")
struct MergeStrategyPersistenceTests {

  // (1) Absent key — hydration falls back to the Configuration's
  // `fallbackStrategy` (`.quorum` for the demo's `.live` config).
  @Test("hydrate falls back to fallbackStrategy when key absent")
  @MainActor
  func hydrateAbsentKey() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.persist.absent"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    // Confirm the key is absent at the start.
    #expect(defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == nil)

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )

    #expect(viewModel.options.mergeStrategy == .quorum)
    // Did NOT write — absent stays absent.
    #expect(defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == nil)
  }

  // (2) Valid stored raw value — hydrates to the matching enum case.
  @Test(
    "hydrate decodes valid stored raw value",
    arguments: BPMSelectionPolicy.allCases
  )
  @MainActor
  func hydrateValidRawValue(_ stored: BPMSelectionPolicy) throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.persist.valid.\(stored.rawValue)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    defaults.set(stored.rawValue, forKey: AnalysisViewModel.preferredMergeStrategyKey)

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )

    #expect(viewModel.options.mergeStrategy == stored)
    // Hydration must not mutate the stored raw value on the success path.
    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == stored.rawValue
    )
  }

  // (3) `persistPreferredMergeStrategy()` writes the current
  // `options.mergeStrategy.rawValue` to the configured defaults under
  // the documented key. Exercises the symmetric write path that
  // `ContentView`'s `.onChange` invokes on every Picker change.
  @Test("persist writes current options.mergeStrategy rawValue")
  @MainActor
  func persistWritesCurrentStrategy() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.persist.roundtrip"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )
    viewModel.options.mergeStrategy = .dedup
    viewModel.persistPreferredMergeStrategy()

    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == "dedup"
    )

    // Round-trip: a fresh VM against the same suite hydrates to the
    // value we just persisted.
    let rehydrated = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )
    #expect(rehydrated.options.mergeStrategy == .dedup)
  }

  // (4) Unrecognized stored raw value — self-heal: fall back to the
  // Configuration's `fallbackStrategy` AND remove the bad key. Future
  // launches take the absent-key path cleanly.
  @Test("hydrate self-heals on unrecognized stored raw value")
  @MainActor
  func hydrateSelfHealsInvalidRawValue() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.persist.invalid"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    defaults.set("bogusStrategy", forKey: AnalysisViewModel.preferredMergeStrategyKey)
    // Sanity: confirm the value really is on disk before VM init.
    #expect(
      defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == "bogusStrategy"
    )

    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults,
        fallbackStrategy: .quorum
      )
    )

    // In-memory: fell back to the configured default.
    #expect(viewModel.options.mergeStrategy == .quorum)
    // On disk: the bad key has been removed (self-heal contract).
    #expect(defaults.string(forKey: AnalysisViewModel.preferredMergeStrategyKey) == nil)
  }
}
