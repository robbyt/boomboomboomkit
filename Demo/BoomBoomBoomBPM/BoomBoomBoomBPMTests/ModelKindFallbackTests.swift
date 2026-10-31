import BoomBoomBoomKit
import CoreGraphics
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// The model-load fallback: `AnalysisViewModel.constructTechnique` tries the
// window kind (`BNNSTechnique`) first and the fixed-time kind
// (`FixedTimeTechnique`) only when the window kind rejects the tensor contract.
// The constructors are injected, so no model file is needed.
@Suite("Model kind fallback")
struct ModelKindFallbackTests {

  private struct Stub: MLTechnique {
    let tag: String
    func evaluate(trace: BPMDiagnosticTrace) -> MLEvaluation? { nil }
  }

  private struct Unrelated: Error {}

  private let url = URL(fileURLWithPath: "/models/any.mlmodelc")

  @Test("a window model loads as the window kind without trying fixed-time")
  func windowLoads() throws {
    var fixedTimeCalls = 0
    let loaded = try AnalysisViewModel.constructTechnique(
      at: url,
      window: { _ in Stub(tag: "window") },
      fixedTime: { _ in
        fixedTimeCalls += 1
        return Stub(tag: "fixed")
      })
    #expect(loaded.kind == .window)
    #expect((loaded.technique as? Stub)?.tag == "window")
    #expect(fixedTimeCalls == 0)
  }

  @Test("a tensor-contract rejection falls back to the fixed-time kind")
  func fallsBackOnContract() throws {
    let loaded = try AnalysisViewModel.constructTechnique(
      at: url,
      window: { _ in
        throw MLTechniqueError.invalidTensorContract(missing: "input.shape [1, 1, 128, 512]")
      },
      fixedTime: { _ in Stub(tag: "fixed") })
    #expect(loaded.kind == .fixedTime)
    #expect((loaded.technique as? Stub)?.tag == "fixed")
  }

  @Test("any other window error is thrown without trying fixed-time")
  func otherErrorsDoNotFallBack() {
    var fixedTimeCalls = 0
    #expect(throws: MLTechniqueError.self) {
      _ = try AnalysisViewModel.constructTechnique(
        at: url,
        window: { _ in throw MLTechniqueError.modelResourceMissing(url) },
        fixedTime: { _ in
          fixedTimeCalls += 1
          return Stub(tag: "fixed")
        })
    }
    #expect(fixedTimeCalls == 0)
  }

  @Test("when both kinds reject the model the error names both reasons")
  func bothFail() {
    #expect {
      _ = try AnalysisViewModel.constructTechnique(
        at: url,
        window: { _ in throw MLTechniqueError.invalidTensorContract(missing: "window-reason") },
        fixedTime: { _ in throw Unrelated() })
    } throws: { error in
      guard let mismatch = error as? AnalysisViewModel.ModelKindMismatch else { return false }
      return mismatch.windowReason == "window-reason"
        && mismatch.description.contains("not a fixed-time model")
    }
  }

  @Test("attach records the kind and detach clears it")
  @MainActor
  func attachRecordsKind() throws {
    let suiteName = "com.robbyt.BoomBoomBoomBPMTests.modelKind"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults, fallbackStrategy: .quorum))
    viewModel.attachMLTechnique(Stub(tag: "fixed"), named: "f.mlmodelc", kind: .fixedTime)
    #expect(viewModel.mlModelKind == .fixedTime)
    #expect(viewModel.mlModelKind?.label == "Fixed-time, 12 s crops")
    viewModel.detachMLTechnique()
    #expect(viewModel.mlModelKind == nil)
    viewModel.attachMLTechnique(Stub(tag: "window"), named: "w.mlmodelc", kind: .window)
    #expect(viewModel.mlModelKind == .window)
  }
}

@Suite("ML input crop shading")
struct CropShadeTests {

  private func crop(_ start: Double) -> MLInputCrop {
    MLInputCrop(
      startFrame: Int(start * 100), startSeconds: start, durationSeconds: 12.04, rhythmScore: 0.5)
  }

  @Test("crops map to rank-numbered x spans in rank order")
  func ranksAndSpans() {
    let shades = BeatGridView.cropShades(
      crops: [crop(72), crop(0)], span: 120, width: 1200)
    #expect(shades.map(\.rank) == [1, 2])
    #expect(abs(shades[0].minX - 720) < 1e-6)
    #expect(abs(shades[0].maxX - 840.4) < 1e-6)
    #expect(shades[1].minX == 0)
  }

  @Test("a crop past the span is dropped and one running over it is cut")
  func clamps() {
    let shades = BeatGridView.cropShades(
      crops: [crop(130), crop(115)], span: 120, width: 1200)
    #expect(shades.count == 1)
    #expect(shades[0].rank == 2)
    #expect(shades[0].maxX == 1200)
    #expect(BeatGridView.cropShades(crops: [crop(0)], span: 0, width: 100).isEmpty)
  }
}

// A fixed-time model ranks crops across the whole uncapped track, so the
// waveform decode (and with it the lane span) runs to the end of the last kept
// crop when one ends past the analysis cap, and the beat grid stops at the cap.
@Suite("Lane span past the analysis cap")
struct AnalysisCapSpanTests {

  private func crop(_ start: Double, duration: Double = 12.04) -> MLInputCrop {
    // A non-finite start would trap the Int conversion, so its frame is 0.
    MLInputCrop(
      startFrame: start.isFinite ? Int(start * 100) : 0, startSeconds: start,
      durationSeconds: duration, rhythmScore: 0.5)
  }

  @Test("a crop past the cap extends the span and its shade is kept")
  func cropPastCapExtendsSpan() {
    let crops = [crop(180)]
    #expect(BeatGridView.cropShades(crops: crops, span: 120, width: 1200).isEmpty)
    let span = BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: crops)
    #expect(span >= 180 + 12.04)
    let shades = BeatGridView.cropShades(crops: crops, span: span, width: 1200)
    #expect(shades.count == 1)
    #expect(shades.first?.rank == 1)
  }

  @Test("the span follows the latest crop end, not the first-ranked crop")
  func latestCropEndWins() {
    let span = BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: [crop(130), crop(200)])
    #expect(span == 200 + 12.04)
  }

  @Test("no crops, or crops inside the cap, leave the span at maxSeconds")
  func spanStaysAtCap() {
    #expect(BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: []) == 120)
    #expect(
      BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: [crop(0), crop(100)]) == 120)
  }

  @Test("crops with non-finite times are ignored")
  func nonFiniteCropsIgnored() {
    let crops = [crop(.nan), crop(.infinity), crop(10, duration: .infinity)]
    #expect(BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: crops) == 120)
    #expect(
      BeatGridView.waveformSpanSeconds(maxSeconds: 120, crops: crops + [crop(150)])
        == 150 + 12.04)
  }

  @Test("beat-grid lines are cut at the cap when the lane runs past it")
  func gridCutAtCap() {
    let span = 192.04
    #expect(BeatGridView.beatGridSpan(span: span, analysisCap: 120) == 120)
    #expect(
      BeatGridView.timesWithinGridSpan(
        [60, 119.5, 120, 120.5, 180], span: span, analysisCap: 120) == [60, 119.5, 120])
    let grid = BeatGridView.extrapolatedBeatTimes(
      anchor: 0.5, tempo: 120,
      span: BeatGridView.beatGridSpan(span: span, analysisCap: 120))
    #expect(!grid.isEmpty)
    #expect(grid.allSatisfy { $0 <= 120 })
  }

  @Test("without a cap past the span the grid is unchanged")
  func gridUnchangedWithoutCap() {
    let times: [Double] = [1, 60, 119.9]
    #expect(BeatGridView.beatGridSpan(span: 120, analysisCap: nil) == 120)
    #expect(BeatGridView.beatGridSpan(span: 120, analysisCap: 120) == 120)
    #expect(BeatGridView.beatGridSpan(span: 100, analysisCap: 120) == 100)
    #expect(BeatGridView.beatGridSpan(span: 120, analysisCap: .nan) == 120)
    #expect(BeatGridView.timesWithinGridSpan(times, span: 120, analysisCap: nil) == times)
    #expect(BeatGridView.timesWithinGridSpan(times, span: 120, analysisCap: 120) == times)
  }
}
