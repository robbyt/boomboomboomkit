import BoomBoomBoomKit
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// The uniform ML-load failure contract (PR #91 Codex P1 hardening). `loadModel`'s
// three failure entrances — unavailable macOS, `BNNSTechnique` construction throws,
// and the picker's capability-missing path — all funnel through the same two
// primitives so no failure can leave a half-attached technique the UI would render
// as `Selected: yes`. The terminal `loadModel` throw/unavailable paths themselves
// need macOS 15 + a real model (operator/GUI-gated, per ModelCatalogTests header),
// so CI proves the primitives both entrances call: `detachMLTechnique` and
// `failModelLoad`. `mlTechnique` is private; the observable trio
// (`mlEnabled`/`mlModelName`/`mlModelError`) is the load-bearing UI state.
@MainActor
@Suite("ML load failure contract")
struct ModelLoadFailureContractTests {

  // A no-op MLTechnique so a technique can be attached without a real model.
  private struct StubMLTechnique: MLTechnique {
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
  }

  private func makeViewModel(_ suffix: String) throws -> (AnalysisViewModel, String) {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.loadContract.\(suffix)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults, fallbackStrategy: .quorum))
    return (viewModel, suiteName)
  }

  // detachMLTechnique clears the observable trio and leaves mlModelError untouched
  // (a failure sets it explicitly; success clears it via attach).
  @Test("detachMLTechnique clears the attach trio without touching mlModelError")
  func detachClearsTrio() throws {
    let (viewModel, suiteName) = try makeViewModel("detach")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    viewModel.attachMLTechnique(StubMLTechnique(), named: "stub.mlmodelc")
    #expect(viewModel.mlEnabled)
    #expect(viewModel.mlModelName == "stub.mlmodelc")
    #expect(viewModel.mlModelError == nil)

    viewModel.mlModelError = "prior"  // detach must not disturb an existing error
    viewModel.detachMLTechnique()

    #expect(!viewModel.mlEnabled)
    #expect(viewModel.mlModelName == nil)
    #expect(viewModel.mlModelError == "prior")
  }

  // failModelLoad detaches AND surfaces an UNLABELED reason — the picker renders it
  // behind a leading `Reason:`, so a pre-labeled value would double it.
  @Test("failModelLoad detaches and stores an unlabeled reason")
  func failModelLoadDetachesAndLabels() throws {
    let (viewModel, suiteName) = try makeViewModel("fail")
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    viewModel.attachMLTechnique(StubMLTechnique(), named: "stub.mlmodelc")
    #expect(viewModel.mlEnabled)

    viewModel.failModelLoad(reason: "model-unavailable")

    #expect(!viewModel.mlEnabled)
    #expect(viewModel.mlModelName == nil)
    #expect(viewModel.mlModelError == "model-unavailable")
    // Unlabeled: the "Reason:" prefix belongs to the picker, not this string.
    #expect(viewModel.mlModelError?.hasPrefix("Reason:") == false)
  }
}
