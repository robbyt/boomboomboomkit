import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Testing

@testable import BoomBoomBoomKitDemo

@Suite("AnalysisViewModel smoke")
struct AnalysisViewModelSmokeTest {

  @Test("public-API wrapping produces non-nil BPM for known-musical fixture")
  @MainActor
  func wrapping() async throws {
    // AudioFixtures.url(for:extension:) returns non-optional URL and throws
    // if the fixture is missing — the throw itself is the missing-fixture
    // signal, no #require wrapping needed.
    let url = try AudioFixtures.url(for: "bpm-120-click", extension: "wav")
    let viewModel = AnalysisViewModel()
    viewModel.analyze(url: url)

    // analyze(url:) launches a Task; poll observed isAnalyzing flag.
    // bpm-120-click.wav at default intensity completes in ~1-2s on M5 Max;
    // 30s ceiling fails fast on pipeline regressions.
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while viewModel.isAnalyzing && ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(50))
    }
    try #require(!viewModel.isAnalyzing, "analyze(url:) did not complete within 30s")

    #expect(viewModel.detectedBPM != nil)
    #expect((viewModel.confidence ?? 0) > 0)
    #expect(viewModel.fileName == "bpm-120-click.wav")
    #expect(viewModel.selectedFileURL == url)
    #expect(viewModel.errorMessage == nil)
    #expect((viewModel.elapsedSeconds ?? 0) > 0)
  }
}
