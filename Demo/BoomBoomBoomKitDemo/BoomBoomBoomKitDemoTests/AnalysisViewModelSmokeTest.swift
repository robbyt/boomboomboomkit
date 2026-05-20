import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
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
    // Story 5-2 AC #9 — pendingCancellations / isCancelling reach empty
    // after the single in-flight task completes. The cleanup Task removes
    // the per-task UUID from both `inFlightTasks` and
    // `pendingCancellations`, so a successful analyze() leaves
    // `isCancelling == false` and the underlying set empty.
    #expect(viewModel.isCancelling == false)
    #expect(viewModel.pendingCancellations.isEmpty)
  }

  // MARK: - Drop Validator (Story 5-2 DD #11 / DD #13)

  @Test("validateDropPayload rejects empty payload")
  @MainActor
  func rejectsEmptyDrop() {
    let result = AnalysisViewModel.validateDropPayload([])
    #expect(result == .failure(.empty))
  }

  @Test("validateDropPayload rejects multi-file payload")
  @MainActor
  func rejectsMultiFileDrop() {
    let urls = [
      URL(fileURLWithPath: "/tmp/a.wav"),
      URL(fileURLWithPath: "/tmp/b.wav"),
    ]
    let result = AnalysisViewModel.validateDropPayload(urls)
    #expect(result == .failure(.multipleFiles))
  }

  // Codex H5 — `.m4b` and `.mp4` conform to `.mpeg4Audio` and would have
  // silently widened the supported set via `UTType.conforms(to:)`.
  // Extension-matching prevents that. The 5 negative cases below cover
  // the H5 widening risk PLUS three obviously-unrelated extensions.
  @Test(
    "validateDropPayload rejects unsupported extensions",
    arguments: ["txt", "ogg", "png", "m4b", "mp4"]
  )
  @MainActor
  func rejectsUnsupportedType(_ ext: String) {
    let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
    let result = AnalysisViewModel.validateDropPayload([url])
    #expect(result == .failure(.unsupportedType(extension: ext)))
  }

  @Test(
    "validateDropPayload accepts the 6 supported extensions",
    arguments: ["wav", "aiff", "mp3", "flac", "m4a", "caf"]
  )
  @MainActor
  func acceptsSupportedTypes(_ ext: String) throws {
    let url = URL(fileURLWithPath: "/tmp/sample.\(ext)")
    let result = AnalysisViewModel.validateDropPayload([url])
    guard case .success(let resolved) = result else {
      Issue.record("expected .success for .\(ext); got \(result)")
      return
    }
    #expect(resolved == url)
  }

  @Test("validateDropPayload uppercase extensions are accepted (case-insensitive)")
  @MainActor
  func acceptsUppercaseExtensions() throws {
    let url = URL(fileURLWithPath: "/tmp/sample.WAV")
    let result = AnalysisViewModel.validateDropPayload([url])
    guard case .success(let resolved) = result else {
      Issue.record("expected .success for uppercase .WAV; got \(result)")
      return
    }
    #expect(resolved == url)
  }

  // MARK: - handleDrop State Transitions (Story 5-2 DD #11)

  // Axiom A5 — paired-args via `zip(...)` per swift-testing.md:213-217.
  // Verifies that each failure path populates `errorMessage` with the
  // verbatim AC #2 string AND leaves `isAnalyzing == false` /
  // `detectedBPM == nil` (no DSP work runs for an invalid drop).
  @Test(
    "handleDrop populates errorMessage on validation failure",
    arguments: zip(
      [
        [],
        [URL(fileURLWithPath: "/tmp/a.wav"), URL(fileURLWithPath: "/tmp/b.wav")],
        [URL(fileURLWithPath: "/tmp/sample.txt")],
      ],
      [
        "No audio file detected in drop.",
        "Drop a single audio file (batch drop is not supported).",
        "Unsupported file type: txt. Supported: WAV, AIFF, MP3, FLAC, M4A, CAF.",
      ]
    )
  )
  @MainActor
  func handleDropStateTransitions(_ urls: [URL], _ expected: String) {
    let viewModel = AnalysisViewModel()
    #expect(viewModel.handleDrop(urls) == false)
    #expect(viewModel.errorMessage == expected)
    #expect(viewModel.isAnalyzing == false)
    #expect(viewModel.detectedBPM == nil)
  }
}
