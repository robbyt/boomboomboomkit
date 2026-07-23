//
//  MergeSemanticEqualityTests.swift
//  BoomBoomBoomKitTests
//
//  Story 6.5b (KDD-A6 Stage 3): the SEMANTIC-equality regression backbone that
//  replaces the retired byte-equality floor (the deleted `.stage1Floor` /
//  `.stage2Floor` tagged tests + `StageFloorTags.swift`). Proves the
//  pool-authoritative `BPMSelectionPolicy.select(from:)` path reproduces the
//  pre-6.5b corroboration semantics at the VALUE level, and cross-checks it
//  against the `MetadataCorroborator.apply` oracle (DD #3 de-risk). Also covers
//  the KDD-A5 weighted-policy activation (AC #11), FR-6 source-family
//  normalization (AC #6), and the 6-3-D2 empty-edge fixtures (AC #7).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Helpers

private func makeResult(
  bpm: Double, confidence: Double,
  candidates: [(bpm: Double, score: Float)],
  trace: BPMDiagnosticTrace? = nil
) -> BPMResult {
  BPMResult(bpm: bpm, confidence: confidence, candidates: candidates, trace: trace)
}

private func makeEvidence(
  source: MetadataSource, parsedBPM: Double, raw: String? = nil, rejection: String? = nil
) -> MetadataBPMEvidence {
  MetadataBPMEvidence(
    source: source, rawValue: raw ?? String(parsedBPM),
    parsedBPM: parsedBPM, rejectionReason: rejection)
}

/// Wraps a single merged-equivalent DSP window into an authoritative pool. A
/// single window short-circuits Phase 1 (`merge` returns it unchanged), so the
/// observable output is exactly Phase 2a corroboration over `window` — the same
/// surface the deleted byte-floor tests and the `MetadataCorroboratorUnitTests`
/// exercise, now routed through the pool.
private func makePool(
  _ window: BPMResult,
  metadata: MetadataCorroborationInput,
  mlParticipation: SignalParticipation = .absent,
  candidateCount: Int = 8
) -> UnifiedSignalPool {
  UnifiedSignalPool(
    dspWindows: [window], metadataInput: metadata,
    candidateCount: candidateCount, mlParticipation: mlParticipation, weight: 1.0)
}

/// Runs the default `.maxConfidence` strategy's pool selection.
private func select(
  _ window: BPMResult, _ metadata: MetadataCorroborationInput,
  weights: SignalWeights = .default
) throws -> (result: BPMResult, evidence: [MetadataBPMEvidence]) {
  let pool = makePool(window, metadata: metadata)
  let outcome = try #require(
    BPMSelectionPolicy.maxConfidence.select(from: pool, weights: weights))
  return (outcome.result, outcome.evidence)
}

// MARK: - Semantic-equality: select path reproduces the 14 corroboration behaviors

@Suite("MergeSemanticEquality — pool select reproduces corroboration semantics")
struct MergeSemanticEqualityTests {

  /// The oracle cross-check (DD #3): for every behavior, the pool `select` path
  /// must produce the SAME bpm/confidence/candidates/evidence as the
  /// `MetadataCorroborator.apply` oracle at `metadataScale == 1.0` (default
  /// weights). This catches any divergence the pool re-expression could
  /// introduce, at the value level rather than byte level.
  private func expectMatchesOracle(
    _ window: BPMResult, _ metadata: MetadataCorroborationInput,
    _ message: Comment
  ) throws {
    let (got, gotEv) = try select(window, metadata)
    let (oracle, oracleEv) = MetadataCorroborator.apply(to: window, input: metadata)
    #expect(NumericTestHelpers.bitEqual(got.bpm, oracle.bpm), message)
    #expect(NumericTestHelpers.bitEqual(got.confidence, oracle.confidence), message)
    #expect(got.candidates.count == oracle.candidates.count, message)
    for (a, b) in zip(got.candidates, oracle.candidates) {
      #expect(NumericTestHelpers.bitEqual(a.bpm, b.bpm), message)
      #expect(NumericTestHelpers.bitEqual(a.score, b.score), message)
    }
    #expect(gotEv.count == oracleEv.count, message)
    for (a, b) in zip(gotEv, oracleEv) {
      #expect(a.rejectionReason == b.rejectionReason, message)
      #expect(a.corroboratedWith == b.corroboratedWith, message)
      #expect(a.ratioMatched == b.ratioMatched, message)
    }
  }

  @Test("1. empty participating tags pass through unchanged")
  func emptyPassThrough() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [], conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
    #expect(ev.isEmpty)
    try expectMatchesOracle(r, input, "empty pass-through")
  }

  @Test("2. single same-tempo tag boosts confidence (0.6 → 0.75) and corroborates")
  func sameTempoCorroboration() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.bpm == 128.0)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(ev[0].corroboratedWith == 128.0)
    #expect(abs(ev[0].boostApplied - 1.25) < 1e-9)
    try expectMatchesOracle(r, input, "same-tempo")
  }

  @Test("3. octave corroboration via .double ratio")
  func octaveCorroboration() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 64.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    #expect(ev[0].ratioMatched == .double)
    try expectMatchesOracle(r, input, "octave")
  }

  @Test("4. winner promotion: boosted 128 (0.5×1.25=0.625) overtakes DSP top 140")
  func winnerPromotion() throws {
    let r = makeResult(
      bpm: 140.0, confidence: 0.5, candidates: [(140.0, 0.5), (128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .id3TBPM, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.bpm == 128.0)
    #expect(ev[0].corroboratedWith == 128.0)
    try expectMatchesOracle(r, input, "winner promotion")
  }

  @Test("5. intra-file conflict marks every valid tag, no boost")
  func intraFileConflict() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 140.0),
      ], conflictDetected: true, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.confidence == 0.7)
    for e in ev { #expect(e.rejectionReason == "intra-file-conflict") }
    try expectMatchesOracle(r, input, "intra-file conflict")
  }

  @Test("6. three-tag partial agreement: all-or-nothing rejects all three")
  func threeTagPartialAgreement() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
        makeEvidence(source: .vorbisBPM, parsedBPM: 174.0),
      ], conflictDetected: true, policy: .default)
    let (_, ev) = try select(r, input)
    #expect(ev.count == 3)
    for e in ev { #expect(e.rejectionReason == "intra-file-conflict") }
    try expectMatchesOracle(r, input, "three-tag partial")
  }

  @Test("7. unanimous consensus across two sources corroborates (→0.75)")
  func unanimousConsensus() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ], conflictDetected: false, policy: .default)
    let (out, _) = try select(r, input)
    #expect(abs(out.confidence - 0.75) < 1e-9)
    try expectMatchesOracle(r, input, "unanimous consensus")
  }

  @Test("8. unanimous disagrees with DSP applies skepticism penalty (0.7 → 0.595)")
  func unanimousDisagreesPenalty() throws {
    let r = makeResult(bpm: 140.0, confidence: 0.7, candidates: [(140.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ], conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.bpm == 140.0)
    #expect(abs(out.confidence - 0.595) < 1e-9)
    for e in ev { #expect(e.rejectionReason == "dsp-disagreement") }
    try expectMatchesOracle(r, input, "unanimous disagrees")
  }

  @Test("9. single uncorroborated tag is ignored — confidence unchanged")
  func singleUncorroboratedIgnored() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 200.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.confidence == 0.7)
    #expect(ev[0].rejectionReason == "uncorroborated-single-tag")
    try expectMatchesOracle(r, input, "single uncorroborated")
  }

  @Test("10. zero / non-finite prevConfidence triggers divide-by-zero guard")
  func divideByZeroGuard() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.0, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.confidence == 0.0)
    #expect(abs(ev[0].boostApplied - 1.0) < 1e-9)
    try expectMatchesOracle(r, input, "divide-by-zero")
  }

  @Test("11. confidence clamps to maxBoostedConfidence (0.8×1.25=1.0 → 0.95)")
  func confidenceClamp() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.8, candidates: [(128.0, 0.8)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
    let (out, _) = try select(r, input)
    #expect(abs(out.confidence - 0.95) < 1e-9)
    try expectMatchesOracle(r, input, "confidence clamp")
  }

  @Test("12. triplet gate off by default — 3:2 tag does not corroborate")
  func tripletGateOff() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.confidence == 0.6)
    #expect(ev[0].rejectionReason == "uncorroborated-single-tag")
    try expectMatchesOracle(r, input, "triplet gate off")
  }

  @Test("13. triplet gate on — 3:2 tag corroborates with .threeHalf")
  func tripletGateOn() throws {
    var policy = MetadataPolicy.default
    policy.allowTripletCorroboration = true
    let r = makeResult(bpm: 128.0, confidence: 0.5, candidates: [(128.0, 0.5)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 192.0)],
      conflictDetected: false, policy: policy)
    let (_, ev) = try select(r, input)
    #expect(ev[0].ratioMatched == .threeHalf)
    try expectMatchesOracle(r, input, "triplet gate on")
  }

  @Test("14. parse-phase rejection passes through unchanged")
  func parseRejectionPassthrough() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: .nan, raw: "0", rejection: "sentinel-zero")
      ], conflictDetected: false, policy: .default)
    let (out, ev) = try select(r, input)
    #expect(out.confidence == 0.6)
    #expect(ev[0].rejectionReason == "sentinel-zero")
    try expectMatchesOracle(r, input, "parse rejection")
  }
}

// MARK: - DD #2: metadataScale parameterization (KDD-A5 weighted corroboration)

@Suite("MergeSemanticEquality — metadataScale (DD #2)")
struct MetadataScaleTests {

  private func sameTempoInput() -> MetadataCorroborationInput {
    MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0)],
      conflictDetected: false, policy: .default)
  }

  @Test("scale 1.0 reproduces ×1.25 boost exactly (0.6 → 0.75)")
  func scaleOneReproducesBoost() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let (out, _) = try select(r, sameTempoInput(), weights: SignalWeights(fileMetadata: 1.0))
    #expect(abs(out.confidence - 0.75) < 1e-9)
  }

  @Test("scale 0.0 makes metadata inert — confidence unchanged")
  func scaleZeroIsInert() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let (out, _) = try select(r, sameTempoInput(), weights: SignalWeights(fileMetadata: 0.0))
    #expect(abs(out.confidence - 0.6) < 1e-12)
  }

  @Test("scale 2.0 strengthens the boost beyond ×1.25")
  func scaleTwoStrengthensBoost() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let (out, _) = try select(r, sameTempoInput(), weights: SignalWeights(fileMetadata: 2.0))
    // boost = 1 + 2·(1.25-1) = 1.5 → 0.6×1.5 = 0.9 (under the 0.95 clamp).
    #expect(abs(out.confidence - 0.9) < 1e-9)
  }

  // MARK: Code-review HIGH — extreme `fileMetadata` weight safety (F1/F2/F3)

  /// A large `fileMetadata` weight drives the raw skepticism penalty negative
  /// (`1 − 10·0.15 = −0.5`); the `max(0, …)` floor must keep confidence ≥ 0.
  @Test("large fileMetadata weight does not drive confidence negative (penalty floored)")
  func largeScalePenaltyFloored() throws {
    let r = makeResult(bpm: 140.0, confidence: 0.7, candidates: [(140.0, 0.7)])
    let input = MetadataCorroborationInput(
      consensusBPM: 128.0,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: 128.0),
        makeEvidence(source: .id3TBPM, parsedBPM: 128.0),
      ], conflictDetected: false, policy: .default)
    let (out, _) = try select(r, input, weights: SignalWeights(fileMetadata: 10.0))
    #expect(out.confidence >= 0.0)
    #expect(out.confidence.isFinite)
  }

  /// A huge `fileMetadata` weight must not overflow boosted candidate scores to
  /// `+inf` (capped at `Float.greatestFiniteMagnitude`).
  @Test("huge fileMetadata weight keeps candidate scores + confidence finite")
  func hugeScaleScoresStayFinite() throws {
    let r = makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    let (out, _) = try select(r, sameTempoInput(), weights: SignalWeights(fileMetadata: 1e30))
    for c in out.candidates { #expect(c.score.isFinite) }
    #expect(out.confidence.isFinite)
    #expect(out.confidence >= 0.0)
  }
}

// MARK: - Code-review HIGH — weighted-resolution confidence sanitization (F3)

@Suite("MergeSemanticEquality — weighted-resolution sanitization")
struct WeightedResolutionSanitizationTests {

  /// A non-finite DSP confidence must be sanitized (→0) before the weighted
  /// comparison so it cannot poison the result — symmetric with ML sanitization.
  @Test("non-finite DSP confidence is sanitized → ML wins deterministically")
  func nonFiniteDSPConfidenceSanitized() {
    let dsp = makeResult(bpm: 128.0, confidence: .nan, candidates: [(128.0, 0.6)])
    let ml = MLEvaluation(bpm: 174.0, confidence: 0.5)
    let out = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .default)
    // DSP NaN → vote 0; ML vote 0.5 > 0 → ML wins (no NaN-poisoned DSP win).
    #expect(out.bpm == 174.0)
    #expect(out.confidence.isFinite)
  }
}

// MARK: - DD #7 / 6-3-D2: empty-pool + empty-candidate edges

@Suite("MergeSemanticEquality — empty edges (DD #7, 6-3-D2)")
struct EmptyEdgeTests {

  @Test("DD #7 / FR-8: empty pool (no DSP windows) → nil, no crash")
  func emptyPoolReturnsNil() {
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [], conflictDetected: false, policy: .default)
    let pool = UnifiedSignalPool(
      dspWindows: [], metadataInput: input, candidateCount: 8,
      mlParticipation: .absent, weight: 1.0)
    #expect(BPMSelectionPolicy.maxConfidence.select(from: pool) == nil)
  }

  @Test("6-3-D2: no-candidates merged voice → .dsp .abstained(noCandidates) entry")
  func noCandidatesDSPEntry() {
    var trace = BPMDiagnosticTrace()
    trace.confidence = 0.0
    let window = makeResult(bpm: 0.0, confidence: 0.0, candidates: [], trace: trace)
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [], conflictDetected: false, policy: .default)
    let entries = BPMSelectionPolicy.participationEntries(
      merged: window,
      pool: UnifiedSignalPool(
        dspWindows: [window], metadataInput: input, candidateCount: 8,
        mlParticipation: .absent, weight: 1.0))
    let dsp = entries.filter { $0.source == .dsp }
    #expect(dsp.count == 1)
    if case .abstained(.sourceSpecific(let reason)) = dsp.first?.participation {
      #expect(reason == AbstainReason.noCandidates)
    } else {
      Issue.record(
        "expected .dsp .abstained(noCandidates), got \(String(describing: dsp.first?.participation))"
      )
    }
  }

  @Test("6-3-D2: all-tags-rejected → .fileMetadata .absent entry")
  func allTagsRejectedMetadataAbsent() {
    let input = MetadataCorroborationInput(
      consensusBPM: nil,
      participatingTags: [
        makeEvidence(source: .iTunesTmpo, parsedBPM: .nan, raw: "0", rejection: "sentinel-zero")
      ], conflictDetected: false, policy: .default)
    let entries = MetadataCorroborator.signalParticipationEntries(for: input, weight: 1.0)
    let meta = entries.filter { $0.source == .fileMetadata }
    #expect(meta.count == 1)
    if case .absent = meta.first?.participation {
    } else {
      Issue.record("expected .fileMetadata .absent for all-rejected tags")
    }
  }
}

// MARK: - AC #6 (FR-6) + AC #11 (KDD-A5): source-family normalization + weighted activation

@Suite("MergeSemanticEquality — FR-6 normalization + KDD-A5 activation")
struct WeightedResolutionTests {

  /// FR-6: M DSP windows agreeing on BPM X collapse to ONE DSP voice in Phase 1
  /// BEFORE the cross-signal fusion, so DSP cannot win by sheer window count.
  /// Five windows agreeing on 128 produce a single merged DSP voice — the pool
  /// the cross-signal stage sees has exactly one DSP candidate cluster, not five.
  @Test("FR-6: multi-window DSP collapses to one voice before cross-signal fusion")
  func dspCollapsesToOneVoice() throws {
    let windows = (0..<5).map { _ in
      makeResult(bpm: 128.0, confidence: 0.6, candidates: [(128.0, 0.6)])
    }
    let input = MetadataCorroborationInput(
      consensusBPM: nil, participatingTags: [], conflictDetected: false, policy: .default)
    let pool = UnifiedSignalPool(
      dspWindows: windows, metadataInput: input, candidateCount: 8,
      mlParticipation: .absent, weight: 1.0)
    let outcome = try #require(BPMSelectionPolicy.dedup.select(from: pool))
    // The five 128 windows cluster to a single candidate — DSP is one voice.
    #expect(outcome.result.candidates.filter { abs($0.bpm - 128.0) < 0.5 }.count == 1)
    #expect(outcome.result.bpm == 128.0)
  }

  /// AC #11: `.weightedVoting` with `ml: 1.5` lets a confident ML voice win where
  /// `.default` (equal weights) would not, and emits an `EnsembleWeightResolution`.
  @Test("KDD-A5: ML up-weighting changes the winner vs .default")
  func mlUpWeightChangesWinner() {
    let dsp = makeResult(bpm: 128.0, confidence: 0.60, candidates: [(128.0, 0.60)])
    let ml = MLEvaluation(bpm: 174.0, confidence: 0.50, modelIdentifier: nil)

    // .default (equal weights): DSP vote 0.60 > ML vote 0.50 → DSP wins.
    let balanced = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .default)
    #expect(balanced.bpm == 128.0)

    // .weightedVoting(ml: 1.5): ML vote 0.50×1.5 = 0.75 > DSP 0.60 → ML wins.
    let weights = SignalWeights(dsp: 1.0, ml: 1.5)
    let mlFavored = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .evaluated(ml), policy: .weightedVoting(weights))
    #expect(mlFavored.bpm == 174.0)
    #expect(abs(mlFavored.confidence - 0.50) < 1e-9)
  }

  /// `.default` with no ML voice resolves to the DSP voice unchanged (the
  /// balanced peer ensemble degrades to DSP-wins when ML is absent) — output is
  /// identical bpm/confidence to `.dspOnly`.
  @Test("KDD-A5: .default with no ML voice == DSP winner unchanged")
  func defaultWithoutMLEqualsDSP() {
    let dsp = makeResult(bpm: 128.0, confidence: 0.7, candidates: [(128.0, 0.7)])
    let out = AudioAnalysisService.combineEnsemble(
      dspWinner: dsp, ml: .abstained, policy: .default)
    #expect(out.bpm == 128.0)
    #expect(out.confidence == 0.7)
  }
}
