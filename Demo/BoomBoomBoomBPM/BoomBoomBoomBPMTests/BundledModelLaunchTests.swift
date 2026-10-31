import BoomBoomBoomKit
import CryptoKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// The bundled fixed-time model's launch step (owner decision, 2026-10-30: load
// it, leave it off). `AnalysisViewModel.loadBundledModelAtLaunch(from:load:)` is
// the seam ContentView's `.task` calls; the loader is injected so most tests need
// no compiled model. The last two tests read the real resource from the host app
// bundle (the tests run hosted in the demo app).
@MainActor
@Suite("Bundled model launch step")
struct BundledModelLaunchTests {

  private struct StubMLTechnique: MLTechnique {
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
  }

  /// sha256 of the seed-42 export's `weights/weight.bin`, pinned by the spec.
  private static let pinnedWeightSHA256 =
    "cc2c1c8a3e21411a8406f1f3e7c64059f4c8c59446b52628de4f2b6763caa327"

  private struct Harness {
    let viewModel: AnalysisViewModel
    let catalog: ModelCatalog
    let viewModelDefaults: UserDefaults
    let catalogDefaults: UserDefaults
    let suiteNames: [String]
    /// Temp folder holding the fixture bundle, removed by `cleanUp`.
    let tempParent: URL?
  }

  /// A view model and a catalog on isolated `UserDefaults` suites. `bundled`
  /// is a temp `.mlmodelc` directory when `withBundledModel` is true.
  private func makeHarness(_ suffix: String, withBundledModel: Bool = true) throws -> Harness {
    let vmSuite = "com.robbyt.BoomBoomBoomBPMTests.bundledLaunch.vm.\(suffix)"
    let catalogSuite = "com.robbyt.BoomBoomBoomBPMTests.bundledLaunch.catalog.\(suffix)"
    let vmDefaults = try #require(UserDefaults(suiteName: vmSuite))
    let catalogDefaults = try #require(UserDefaults(suiteName: catalogSuite))
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: vmDefaults, fallbackStrategy: .quorum))
    var bundled: URL?
    var tempParent: URL?
    if withBundledModel {
      let parent = FileManager.default.temporaryDirectory
        .appendingPathComponent("BundledModelLaunchTests-\(UUID().uuidString)", isDirectory: true)
      tempParent = parent
      let bundle = parent.appendingPathComponent("fixed-time-tempo-v1.mlmodelc", isDirectory: true)
      try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
      try Data("coreml-weights".utf8).write(to: bundle.appendingPathComponent("coremldata.bin"))
      bundled = bundle
    }
    let catalog = ModelCatalog(
      bookmarks: BookmarkPersistence(defaults: catalogDefaults), bundledModelURL: bundled)
    return Harness(
      viewModel: viewModel, catalog: catalog, viewModelDefaults: vmDefaults,
      catalogDefaults: catalogDefaults, suiteNames: [vmSuite, catalogSuite],
      tempParent: tempParent)
  }

  private func cleanUp(_ harness: Harness) {
    for name in harness.suiteNames {
      UserDefaults.standard.removePersistentDomain(forName: name)
    }
    if let parent = harness.tempParent {
      try? FileManager.default.removeItem(at: parent)
    }
  }

  private func storedKeys(_ defaults: UserDefaults, suite: String) -> Set<String> {
    Set(defaults.persistentDomain(forName: suite)?.keys.map { $0 } ?? [])
  }

  @Test("a successful launch load attaches the model, marks it selected, and leaves it off")
  func launchLoadLeavesModelOff() throws {
    let harness = try makeHarness("success")
    defer { cleanUp(harness) }
    let viewModel = harness.viewModel
    let catalog = harness.catalog
    let vmKeysBefore = storedKeys(harness.viewModelDefaults, suite: harness.suiteNames[0])
    let bundled = try #require(catalog.bundledEntry)

    nonisolated(unsafe) var loadedURL: URL?
    viewModel.loadBundledModelAtLaunch(from: catalog) { url in
      loadedURL = url
      viewModel.attachMLTechnique(StubMLTechnique(), named: url.lastPathComponent, kind: .fixedTime)
      return true
    }

    #expect(loadedURL?.standardizedFileURL == bundled.url.standardizedFileURL)
    #expect(viewModel.mlModelName == "fixed-time-tempo-v1.mlmodelc")
    #expect(viewModel.mlModelKind == .fixedTime)
    #expect(!viewModel.mlEnabled)  // loaded, left off
    #expect(viewModel.mlModelError == nil)
    #expect(catalog.isSelected(bundled))
    #expect(catalog.restoreDiagnostics.isEmpty)
    // Nothing persisted: no preference written, no bookmark stored.
    #expect(storedKeys(harness.viewModelDefaults, suite: harness.suiteNames[0]) == vmKeysBefore)
    #expect(storedKeys(harness.catalogDefaults, suite: harness.suiteNames[1]).isEmpty)
    // No analysis started.
    #expect(!viewModel.isAnalyzing)
  }

  @Test("a failed launch load detaches, clears selection, keeps the row, and labels the failure")
  func launchLoadFailure() throws {
    let harness = try makeHarness("failure")
    defer { cleanUp(harness) }
    let viewModel = harness.viewModel
    let catalog = harness.catalog

    viewModel.loadBundledModelAtLaunch(from: catalog) { _ in
      viewModel.failModelLoad(reason: "Could not load model: stub")
      return false
    }

    #expect(viewModel.mlModelName == nil)
    #expect(!viewModel.mlEnabled)
    #expect(catalog.selectedURL == nil)
    #expect(catalog.bundledEntry != nil)  // the row stays listed
    #expect(catalog.restoreDiagnostics == [ModelCatalog.bundledModelLoadFailedReason])
    #expect(ModelCatalog.bundledModelLoadFailedReason == "Reason: bundled-model-load-failed")
  }

  @Test("with no bundled model the launch step never calls the loader")
  func launchStepWithoutBundledModel() throws {
    let harness = try makeHarness("absent", withBundledModel: false)
    defer { cleanUp(harness) }

    nonisolated(unsafe) var loaderCalled = false
    harness.viewModel.loadBundledModelAtLaunch(from: harness.catalog) { _ in
      loaderCalled = true
      return true
    }

    #expect(!loaderCalled)
    #expect(harness.viewModel.mlModelName == nil)
    #expect(harness.catalog.selectedURL == nil)
    #expect(harness.catalog.restoreDiagnostics.isEmpty)
  }

  @Test("the launch step runs once per view model, so it never replaces a later pick")
  func launchStepRunsOnce() throws {
    let harness = try makeHarness("once")
    defer { cleanUp(harness) }

    nonisolated(unsafe) var loadCount = 0
    let load: (URL) -> Bool = { _ in
      loadCount += 1
      return true
    }
    harness.viewModel.loadBundledModelAtLaunch(from: harness.catalog, load: load)
    // The user picks another model, as the picker's "Use this model" would.
    harness.viewModel.attachMLTechnique(StubMLTechnique(), named: "user.mlmodelc", kind: .window)
    harness.viewModel.loadBundledModelAtLaunch(from: harness.catalog, load: load)

    #expect(loadCount == 1)
    #expect(harness.viewModel.mlModelName == "user.mlmodelc")
    #expect(harness.viewModel.mlEnabled)
  }

  // MARK: - The shipped resource

  @Test("the host app bundle carries the pinned fixed-time model")
  func hostBundleCarriesPinnedModel() throws {
    let url = try #require(ModelCatalog.bundledModelURL())
    #expect(url.lastPathComponent == "fixed-time-tempo-v1.mlmodelc")
    let weights = try Data(
      contentsOf: url.appendingPathComponent("weights").appendingPathComponent("weight.bin"))
    let hex = SHA256.hash(data: weights).map { String(format: "%02x", $0) }.joined()
    #expect(hex == Self.pinnedWeightSHA256)
    #expect(
      FileManager.default.fileExists(
        atPath: url.appendingPathComponent("analytics/coremldata.bin").path))
  }

  @Test("the real launch path lists, loads, and leaves off the shipped model")
  func realLaunchPathWithDefaults() throws {
    let vmSuite = "com.robbyt.BoomBoomBoomBPMTests.bundledLaunch.vm.real"
    let catalogSuite = "com.robbyt.BoomBoomBoomBPMTests.bundledLaunch.catalog.real"
    defer {
      UserDefaults.standard.removePersistentDomain(forName: vmSuite)
      UserDefaults.standard.removePersistentDomain(forName: catalogSuite)
    }
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: try #require(UserDefaults(suiteName: vmSuite)), fallbackStrategy: .quorum))
    // Default `bundledModelURL` (the `Bundle.main` lookup) and default loader.
    let catalog = ModelCatalog(
      bookmarks: BookmarkPersistence(defaults: try #require(UserDefaults(suiteName: catalogSuite))))
    let expectedURL = try #require(ModelCatalog.bundledModelURL()?.standardizedFileURL)
    let bundled = try #require(catalog.bundledEntry)
    #expect(bundled.url == expectedURL)

    viewModel.loadBundledModelAtLaunch(from: catalog)

    #expect(viewModel.mlModelKind == .fixedTime)
    #expect(viewModel.mlEnabled == false)
    #expect(catalog.isSelected(bundled))
    #expect(catalog.restoreDiagnostics.isEmpty)
  }

  @Test("the shipped model loads as the fixed-time kind")
  func hostBundleModelLoadsAsFixedTime() throws {
    let url = try #require(ModelCatalog.bundledModelURL())
    let loaded = try AnalysisViewModel.constructTechnique(at: url)
    #expect(loaded.kind == .fixedTime)
  }
}
