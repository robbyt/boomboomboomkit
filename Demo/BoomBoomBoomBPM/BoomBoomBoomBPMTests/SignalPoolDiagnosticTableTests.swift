import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomBPM

// Story 9.2 — signal-pool diagnostic table. The derivation
// (`SignalPoolDiagnostics.rows`) is pure and off the main actor, so most tests
// are plain value tests (the `BeatGridLogicTests` pattern); one real-run
// integration test proves the live `signalParticipationTrace` populates and
// derives a winning-cluster row.
@Suite("Signal pool diagnostic table")
struct SignalPoolDiagnosticTableTests {

  // MARK: - Fixtures

  private func entry(
    _ source: SignalSource,
    _ participation: SignalParticipation,
    weight: Double = 1.0,
    contribution: Double = 0.0
  ) -> SignalParticipationTraceEntry {
    SignalParticipationTraceEntry(
      source: source, participation: participation, weight: weight, contribution: contribution)
  }

  private func present(
    _ source: SignalSource, bpm: Double, confidence: Double, score: Float? = nil
  ) -> SignalParticipation {
    .present(WeightedSignal(bpm: bpm, confidence: confidence, source: source, score: score))
  }

  // MARK: - Derivation: provenance + cluster

  @Test("row count and per-column provenance for a single DSP winner")
  func flattenProvenance() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), weight: 1.0, contribution: 0.9)
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    #expect(rows.count == 1)
    let row = rows[0]
    #expect(row.source == "dsp")
    #expect(row.bpmDisplay == "120.00")
    #expect(row.bpmSortKey == 120)
    #expect(row.confidenceDisplay == "0.9000")
    #expect(row.weightDisplay == "1.000")
    #expect(row.contributionDisplay == "0.9000")
    #expect(row.clusterRank == 0)
    #expect(row.clusterLabel == "Winner")
    #expect(row.isWinningCluster)
    #expect(row.isWinner)
    #expect(row.participationKind == "present")
  }

  @Test("cluster membership: within/at/beyond the ±0.5 BPM tolerance")
  func clusterBoundary() throws {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120.5, confidence: 0.9)),  // exactly 0.5 -> in
      entry(.ml, present(.ml, bpm: 120.6, confidence: 0.8)),  // 0.6 -> out
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: nil)
    let dsp = try #require(rows.first { $0.source == "dsp" })
    let ml = try #require(rows.first { $0.source == "ml" })
    #expect(dsp.clusterRank == 0)
    #expect(dsp.clusterLabel == "Winner")
    #expect(ml.clusterRank == 1)
    #expect(ml.clusterLabel == "Rejected")
  }

  @Test("non-voters (absent / abstained) get rank 2, no BPM, zero confidence")
  func nonVoters() throws {
    let entries = [
      entry(.ml, .abstained(.sourceSpecific(AbstainReason.mlEvalDeferred))),
      entry(.fileMetadata, .absent),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: nil)
    let ml = try #require(rows.first { $0.source == "ml" })
    let meta = try #require(rows.first { $0.source == "fileMetadata" })
    #expect(ml.clusterRank == 2)
    #expect(ml.bpmDisplay == "—")
    #expect(ml.confidenceDisplay == "0.0000")
    #expect(ml.participationKind == "abstained: ml-eval-deferred")
    #expect(meta.clusterRank == 2)
    #expect(meta.participationKind == "absent")
    #expect(!ml.isWinner)
    #expect(!meta.isWinner)
  }

  // MARK: - Winner selection

  @Test("winner .dsp badges the DSP row; .ml badges the ML row")
  func winnerBySource() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), contribution: 0.9),
      entry(.ml, present(.ml, bpm: 120, confidence: 0.8), contribution: 0.8),
    ]
    let dspWin = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    #expect(dspWin.filter(\.isWinner).map(\.source) == ["dsp"])
    let mlWin = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .ml)
    #expect(mlWin.filter(\.isWinner).map(\.source) == ["ml"])
  }

  @Test("winner .tie resolves to DSP")
  func winnerTie() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), contribution: 0.9),
      entry(.ml, present(.ml, bpm: 120, confidence: 0.8), contribution: 0.8),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .tie)
    #expect(rows.filter(\.isWinner).map(\.source) == ["dsp"])
  }

  @Test("nil winner (e.g. .dspOnly) badges DSP even when a metadata tag out-contributes it")
  func winnerNilRestrictsToDsp() {
    // Live file-metadata rows carry confidence 1.0, so their contribution can
    // exceed a DSP fusion score — but under .dspOnly the library always selects
    // a DSP-sourced BPM, so the badge must stay on DSP (source restriction, not
    // raw top-contribution).
    let entries = [
      entry(.fileMetadata, present(.fileMetadata, bpm: 120, confidence: 1.0), contribution: 1.0),
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), contribution: 0.7),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: nil)
    #expect(rows.filter(\.isWinner).map(\.source) == ["dsp"])
  }

  @Test("winner .ml with an abstained (BPM-less) ML pool row badges nothing, not DSP")
  func mlWinnerAbstainedNoBadge() {
    // The real trace is built before ML inference, so a live .ml row is always
    // abstained — an .ml winner has no BPM-bearing row to badge; the summary
    // line carries the verdict instead. It must NOT fall back to the DSP row.
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), contribution: 0.9),
      entry(.ml, .abstained(.sourceSpecific(AbstainReason.mlEvalDeferred))),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .ml)
    #expect(rows.allSatisfy { !$0.isWinner })
  }

  @Test("winner tiebreak: equal contribution resolves to the smaller BPM delta")
  func winnerDeltaTiebreak() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 119.6, confidence: 0.9), contribution: 0.9),
      entry(.dsp, present(.dsp, bpm: 120.0, confidence: 0.9), contribution: 0.9),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    let winners = rows.filter(\.isWinner)
    #expect(winners.count == 1)
    // The 120.0 row (delta 0) beats 119.6 (delta 0.4) at equal contribution.
    #expect(winners.first?.bpmDisplay == "120.00")
  }

  @Test("multiple DSP rows in the winning cluster produce exactly one badge")
  func multipleDspSingleBadge() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.7), contribution: 0.7),
      entry(.dsp, present(.dsp, bpm: 120, confidence: 0.9), contribution: 0.9),
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    let winners = rows.filter(\.isWinner)
    #expect(winners.count == 1)
    // The higher-contribution row wins.
    #expect(winners.first?.contributionDisplay == "0.9000")
  }

  @Test("empty winning cluster yields no badge")
  func noWinningCluster() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: 100, confidence: 0.9), contribution: 0.9)
    ]
    // selectedBPM 120 is >0.5 from 100 -> no winning cluster.
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    #expect(rows.allSatisfy { !$0.isWinner })
    #expect(rows[0].clusterRank == 1)
  }

  // MARK: - NaN safety + empty state

  @Test("non-finite BPM displays as em dash and sinks to the sentinel sort key")
  func nanBpmSafety() {
    let entries = [
      entry(.dsp, present(.dsp, bpm: .nan, confidence: 0.9), contribution: 0.9)
    ]
    let rows = SignalPoolDiagnostics.rows(from: entries, selectedBPM: 120, winner: .dsp)
    #expect(rows[0].bpmDisplay == "—")
    #expect(rows[0].bpmSortKey == SignalPoolDiagnostics.missingSortKey)
    // Has a signal but no usable BPM -> off-cluster candidate, not a non-voter.
    #expect(rows[0].clusterRank == 1)
  }

  @Test("empty entries derive no rows (drives the table empty-state)")
  func emptyInput() {
    #expect(SignalPoolDiagnostics.rows(from: [], selectedBPM: 120, winner: nil).isEmpty)
  }

  // MARK: - Real-run integration

  @MainActor
  private static func makeViewModel(
    suiteName: String, fallbackPreset: EnsemblePreset
  ) throws -> (viewModel: AnalysisViewModel, defaults: UserDefaults) {
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    let viewModel = AnalysisViewModel(
      configuration: AnalysisViewModel.Configuration(
        defaults: defaults, fallbackStrategy: .quorum, fallbackPreset: fallbackPreset))
    return (viewModel, defaults)
  }

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

  @Test("default preset run populates signalParticipationTrace + a winning-cluster row")
  @MainActor
  func liveDefaultPresetPopulatesTable() async throws {
    let suite = "com.robbyt.BoomBoomBoomBPMTests.signalPoolDefault"
    UserDefaults.standard.removePersistentDomain(forName: suite)
    defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
    let (viewModel, _) = try Self.makeViewModel(suiteName: suite, fallbackPreset: .default)
    try await Self.runAnalysis(viewModel)

    let snapshot = try #require(viewModel.lastRunSnapshot)
    #expect(!snapshot.trace.signalParticipationTrace.isEmpty)
    // .default emits a weighted resolution.
    let resolution = try #require(snapshot.trace.ensembleWeightResolution)
    let rows = SignalPoolDiagnostics.rows(
      from: snapshot.trace.signalParticipationTrace,
      selectedBPM: resolution.selectedBPM,
      winner: resolution.winner)
    #expect(!rows.isEmpty)
    #expect(rows.contains { $0.isWinningCluster })
    #expect(rows.filter(\.isWinner).count <= 1)
  }

  @Test("DSP-only preset run still populates the pool but emits no weighted resolution")
  @MainActor
  func liveDspOnlyPresetHasPoolNoResolution() async throws {
    let suite = "com.robbyt.BoomBoomBoomBPMTests.signalPoolDspOnly"
    UserDefaults.standard.removePersistentDomain(forName: suite)
    defer { UserDefaults.standard.removePersistentDomain(forName: suite) }
    let (viewModel, _) = try Self.makeViewModel(suiteName: suite, fallbackPreset: .dspOnly)
    try await Self.runAnalysis(viewModel)

    let snapshot = try #require(viewModel.lastRunSnapshot)
    #expect(!snapshot.trace.signalParticipationTrace.isEmpty)
    #expect(snapshot.trace.ensembleWeightResolution == nil)
    // Derivation falls back to result.bpm for selectedBPM when resolution is nil.
    let rows = SignalPoolDiagnostics.rows(
      from: snapshot.trace.signalParticipationTrace,
      selectedBPM: snapshot.trace.ensembleWeightResolution?.selectedBPM ?? snapshot.result.bpm,
      winner: snapshot.trace.ensembleWeightResolution?.winner)
    #expect(!rows.isEmpty)
  }
}
