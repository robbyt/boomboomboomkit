//
//  BNNSTechniqueAbstainFloorTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-6 AC #9 revised: corpus-anchored abstain-floor tests on real
//  audio. Catches the regression Codex C4 identified — Story 4-5's
//  100%-abstain artifact landed without CI seeing it because the
//  impact-report harness is develop-only. These tests run in the
//  default `make test` lane under the `BNNS_IMPACT=1` env gate so the
//  fast-CI path doesn't pay the cost.
//

import BoomBoomBoomKit
import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKitML

/// Story 4-6 code review P4: suite-level `.disabled(if:)` predicate
/// resolves to `true` under Branch C (no bundled model). The previous
/// `guard let bnns = try? BNNSTechnique() else { Issue.record(...); return }`
/// pattern recorded a test FAILURE on every CI run because
/// `Issue.record` is not a skip primitive — Story 4-5 review finding
/// M12 explicitly called this out. The suite-level disabled trait skips
/// cleanly without recording any per-test issues.
@available(macOS 15.0, *)
private func abstainFloorSuiteShouldSkip() -> Bool {
  BNNSTechnique.bundledReferenceURL == nil
}

@Suite(
  "BNNSTechnique abstain floor on real audio (AC #9 revised)",
  .enabled(if: ProcessInfo.processInfo.environment["BNNS_IMPACT"] == "1"),
  .disabled(
    if: {
      if #available(macOS 15.0, *) { return abstainFloorSuiteShouldSkip() }
      return true
    }()),
  // Story 4-6 P13 follow-up (Codex post-patch review): both tests in
  // this suite mutate `BNNSTechnique.thresholdOverride` globally. The
  // atomic `effectiveThresholds` accessor (P13) closed the
  // within-evaluation two-read race, but tests still need .serialized
  // because Swift Testing's default parallel execution can have one
  // test's `defer { ... = nil }` fire while another test is mid-run,
  // resetting the override to nil and causing the running test to read
  // production defaults instead of the (0.0, 0.0) sweep value. The
  // serialized trait keeps both tests in this suite executing one at a
  // time so the override is owned by a single test at a time.
  .serialized
)
struct BNNSTechniqueAbstainFloorTests {

  /// 20 OA300 tracks where DSP currently resolves correctly at intensity
  /// 7 (Acc1 == true per `4-5-bnns-impact-report.json`). Selected per
  /// AC #9 revised: 4 from `dsp_correct_controls` + 16 more spread
  /// across BPM range. Frozen at story-authoring time; future tracks
  /// added to the corpus do NOT change this list.
  private static let dspCorrectTracks: [String] = [
    "10. Hellacopta_Assemby (Xiûa Remix).wav",
    "3. D3Z_Axons (Offish Remix).wav",
    "5. Darkgray Heart_Beating Heart Of The Summer Sun (robbyt Remix).wav",
    "6. HEFT_Fuyu (Akinsa Remix).wav",
    "03 TVR.m4a",
    "Aeon Flux - Reality (Repitch Remaster).wav",
    "Amor Satyr & Fetus - Half Half - 01 Amor Satyr & Fetus - Baby Check.mp3",
    "Echtoo - The Mummy - Seminal Sounds.wav",
    "Hooverian Blur - Cut and Dried EP - 02 Twice Removed.mp3",
    "Hooverian Blur - Cut and Dried EP - 03 Red Scare.mp3",
    "Hooverian Blur - Cut and Dried EP - 04 Slower Violence.mp3",
    "Ironik - The Calling (Remaster).wav",
    "Legal Offence - Burnin' Up (Piano Mix) (Remaster).wav",
    "Stakka & Skynet - Clockwork - Remastered 2014 - 01 Decoy.mp3",
    "Stakka & Skynet - Clockwork - Remastered 2014 - 05 TImelines.mp3",
    "Stakka & Skynet - Clockwork - Remastered 2014 - 11 9000 Series.mp3",
    "Sully - The Still - 02 Lies.mp3",
    "The Prodigy - 160 Experience - 02 Music Reach (Neekeetone 160 Rework).aiff",
    "The Prodigy - 160 Experience - 04 Your Love (Neekeetone 160 Rework).aiff",
    "The Prodigy - 160 Experience - 09 Weather Experience (Neekeetone 160 Rework).aiff",
  ]

  /// AC #9 revised — `abstainFloorOnRealAudio_DspCorrectControls`. With
  /// thresholds at 0.0/0.0 (override via the `BNNSTechnique.thresholdOverride`
  /// Mutex seam), the abstain rate across the 20 DSP-correct tracks
  /// MUST be ≤ 30% (`abstain_rate <= 0.30`).
  ///
  /// The Story 4-5 100%-abstain regression would produce abstain_rate ~=
  /// 1.0 here — caught instantly. The historical `giantsteps_v1.mlmodelc`
  /// (bundled pre-Story-4-6; pulled to develop in the Branch C close-out)
  /// emitted a confident prediction for every track at threshold 0.0/0.0
  /// (abstain_rate ≈ 0.0) even though those predictions were mostly
  /// wrong — this asymmetry is what motivated the symmetric
  /// `wrongNonAbstainCeiling` companion test below. Under Branch C, the
  /// no-arg `BNNSTechnique()` construction throws and this test skips
  /// gracefully; BYOW retrain stories that pass a real `modelURL:` will
  /// re-activate the assertion.
  @Test("abstainFloorOnRealAudio_DspCorrectControls")
  func abstainFloorOnRealAudio() async throws {
    if #available(macOS 15.0, *) {
      // Suite-level `.disabled(if:)` guards against the no-bundled-model
      // path; `try #require` here treats a still-failing init as a real
      // bug (not a skip) per the Swift Testing semantic distinction
      // between Issue.record (failure) and trait-driven skip.
      let bnns = try #require(try? BNNSTechnique())
      let corpusPath = try #require(
        ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"]
          .flatMap { $0.isEmpty ? nil : $0 },
        "OA300_CORPUS_PATH must be set under BNNS_IMPACT=1 (AC #9 requires real audio)")
      // Override thresholds to 0.0/0.0 for the duration of this test.
      BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
      defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }

      var abstainCount = 0
      var ranCount = 0
      for trackName in Self.dspCorrectTracks {
        // The corpus has tracks in different subdirectories. Try the
        // top level first; skip with `Issue.record` if not found.
        let url = URL(fileURLWithPath: corpusPath)
          .appendingPathComponent(trackName)
        guard FileManager.default.fileExists(atPath: url.path) else {
          continue
        }
        var options = AudioAnalysisService.Options()
        options.intensity = .thorough
        options.ensemblePolicy = .mlOnly
        options.mlTechnique = bnns
        options.enableTrace = true
        let result = try AudioAnalysisService.analyzeBPM(url: url, options: options)
        ranCount += 1
        // ML abstained when ensembleDecision.winner != .ml.
        let mlWon = result?.trace?.ensembleDecision?.winner == .ml
        if !mlWon { abstainCount += 1 }
      }
      // Story 4-6 code review P4: zero resolved tracks is a corpus-drift
      // bug, not a skip — the static `dspCorrectTracks` list and the
      // corpus directory at OA300_CORPUS_PATH must remain in sync.
      if ranCount == 0 {
        let driftMsg =
          "Zero DSP-correct tracks resolved on disk — the static list "
          + "in BNNSTechniqueAbstainFloorTests has drifted from the corpus at "
          + "\(corpusPath); update either the list or the corpus."
        Issue.record(Comment(rawValue: driftMsg))
      }
      #expect(ranCount > 0, "Corpus drift — see Issue.record above for details")
      guard ranCount > 0 else { return }
      let abstainRate = Double(abstainCount) / Double(ranCount)
      // AC #9 revised: abstain_rate <= 0.30 (≤ 6 of 20 abstain).
      // `Testing.Comment` is `ExpressibleByStringLiteral` only — surface the
      // runtime numbers via Issue.record before the assert.
      if abstainRate > 0.30 {
        Issue.record(
          "abstain_rate \(abstainRate) > 0.30 (\(abstainCount) of \(ranCount) DSP-correct tracks abstained at thresholds 0.0/0.0). The Story 4-5 100%-abstain regression would produce 1.0 here."
        )
      }
      #expect(
        abstainRate <= 0.30,
        "abstain_rate exceeded 0.30 ceiling (see Issue.record above for counts)")
    }
  }

  /// AC #9 revised — `wrongNonAbstainCeiling_DspCorrectControls`. Of the
  /// non-abstaining tracks, ≤ 4 are wrong (outside 4% Acc1 tolerance
  /// of DSP's correct value).
  ///
  /// **Branch C historical note (Story 4-6 close-out, 2026-05-16):** the
  /// previously-bundled `giantsteps_v1.mlmodelc` produced 54/82
  /// wrong-non-abstain predictions at threshold 0.0/0.0 across the FULL
  /// OA300 corpus — that finding is what triggered Branch C (bundle
  /// pulled). On the DSP-correct subset the ceiling of 4 was exceeded,
  /// proving this assertion is the SYMMETRIC complement to the
  /// abstain-floor: it catches "model emits confidently-wrong
  /// predictions instead of abstaining". Under Branch C (no bundled
  /// model in main), `BNNSTechnique()` throws and the test skips
  /// gracefully. A future Branch A retrain story will ship a model
  /// where this assertion holds without skipping.
  @Test("wrongNonAbstainCeiling_DspCorrectControls")
  func wrongNonAbstainCeiling() async throws {
    if #available(macOS 15.0, *) {
      // Suite-level `.disabled(if:)` (Story 4-6 P4) guards the
      // no-bundled-model path so `try #require` here is a real-bug
      // surface, not a skip.
      let bnns = try #require(try? BNNSTechnique())
      let corpusPath = try #require(
        ProcessInfo.processInfo.environment["OA300_CORPUS_PATH"]
          .flatMap { $0.isEmpty ? nil : $0 },
        "OA300_CORPUS_PATH must be set under BNNS_IMPACT=1 (AC #9 requires real audio)")
      BNNSTechnique.thresholdOverride.withLock { $0 = (0.0, 0.0) }
      defer { BNNSTechnique.thresholdOverride.withLock { $0 = nil } }

      var wrongCount = 0
      var ranCount = 0
      for trackName in Self.dspCorrectTracks {
        let url = URL(fileURLWithPath: corpusPath)
          .appendingPathComponent(trackName)
        guard FileManager.default.fileExists(atPath: url.path) else {
          continue
        }
        var dspOpts = AudioAnalysisService.Options()
        dspOpts.intensity = .default
        dspOpts.ensemblePolicy = .dspOnly
        guard
          let dspResult =
            try AudioAnalysisService.analyzeBPM(url: url, options: dspOpts)
        else { continue }

        var mlOpts = AudioAnalysisService.Options()
        mlOpts.intensity = .thorough
        mlOpts.ensemblePolicy = .mlOnly
        mlOpts.mlTechnique = bnns
        mlOpts.enableTrace = true
        let mlResult = try AudioAnalysisService.analyzeBPM(url: url, options: mlOpts)
        ranCount += 1
        guard mlResult?.trace?.ensembleDecision?.winner == .ml else {
          continue  // ML abstained — not a wrong-non-abstain case.
        }
        let mlBPM = mlResult?.bpm ?? 0.0
        let dspBPM = dspResult.bpm
        if abs(mlBPM - dspBPM) / max(dspBPM, 1.0) >= 0.04 {
          wrongCount += 1
        }
      }
      if ranCount == 0 {
        let driftMsg =
          "Zero DSP-correct tracks resolved on disk for "
          + "wrong-non-abstain check — corpus drift; update either the static "
          + "list or the corpus at \(corpusPath)."
        Issue.record(Comment(rawValue: driftMsg))
      }
      #expect(ranCount > 0, "Corpus drift — see Issue.record above for details")
      guard ranCount > 0 else { return }
      // `Testing.Comment` is `ExpressibleByStringLiteral` only — surface the
      // runtime numbers via Issue.record before the assert.
      if wrongCount > 4 {
        Issue.record(
          "wrong_non_abstain_count \(wrongCount) > 4 ceiling (\(ranCount) DSP-correct tracks evaluated at thresholds 0.0/0.0). Under Branch C (Story 4-6 close-out) the no-arg construction throws and this branch is unreachable in main; a BYOW model retrained for accuracy should hold this ceiling. The historical bundled model tripped this via bimodal-prediction at 125/175 BPM — that's what Story 4-6 documented and pulled."
        )
      }
      #expect(
        wrongCount <= 4,
        "wrong_non_abstain_count exceeded 4 ceiling (see Issue.record above for counts)")
    }
  }
}
