//
//  SuperFluxByteIdentityTests.swift
//  BoomBoomBoomKitTests
//
//  Story 4-7 Task 5 / AC #3 / AC #8 — byte-equality opt-out tests.
//
//  These tests verify two complementary contracts:
//
//  (1) `dspOnlyByteIdenticalWithSuperFluxAbsent` — with `.superFluxOnset`
//      NOT in `Options.techniqueSet`, analyzer output is byte-identical to
//      both an explicit `.optimal` techniqueSet AND a frozen baseline
//      committed to `4-7-byte-identity-baseline.json`. Proves the default
//      path does NOT silently fall through SuperFlux.
//
//  (2) `dspOnlyDifferentWithSuperFluxPresent` — with `.superFluxOnset` in
//      `Options.techniqueSet`, analyzer output differs from the no-variant
//      run on at least one bundled fixture. Proves the gate actually does
//      something — if this test passes byte-identity instead, the
//      integration is broken (HALT-(g)).
//
//  Per project-context.md:103 — "Byte-equality opt-out tests are the
//  regression backbone for opt-in features." Pattern follows Story 3-6b's
//  `runPreCorroborationPipeline` share-with-production discipline, applied
//  here against the public `AudioAnalysisService.analyzeBPM(url:options:)`
//  facade (the share-with-production helper here IS the public facade —
//  both paths go through the same `analyzeBPM`, only `Options.techniqueSet`
//  differs).
//

import BoomBoomBoomKitTestSupport
import Foundation
import Testing

@testable import BoomBoomBoomKit

// MARK: - Frozen baseline fixture

/// Per-fixture bpm/confidence bitPatterns captured at Story 4-7 Task 5
/// authoring time. Frozen at this SHA so any future change to the default
/// DSP path that affects analyzer output across the bundled clicks will
/// fail this test, surfacing the regression at unit-test time rather
/// than via the env-gated corpus benchmark.
private struct ByteIdentityBaseline: Decodable {
  let capturedAtSHA: String
  let capturedAt: String
  let note: String
  let fixtures: [Row]

  struct Row: Decodable {
    let fixture: String
    let `extension`: String
    let bpmBits: UInt64
    let confidenceBits: UInt64
  }
}

private func loadBaseline() throws -> ByteIdentityBaseline {
  let url = try #require(
    Bundle.module.url(
      forResource: "4-7-byte-identity-baseline", withExtension: "json",
      subdirectory: "Fixtures"
    )
      ?? Bundle.module.url(forResource: "4-7-byte-identity-baseline", withExtension: "json"),
    "Missing fixture 4-7-byte-identity-baseline.json"
  )
  let data = try Data(contentsOf: url)
  return try JSONDecoder().decode(ByteIdentityBaseline.self, from: data)
}

// MARK: - Byte-equality opt-out tests (AC #3 + AC #8)

@Suite("BPMAnalyzer — SuperFlux byte-equality opt-out (Story 4-7 AC #3 + #8)")
struct SuperFluxByteIdentityTests {

  /// AC #3 first half: with `.superFluxOnset` ABSENT from `Options.techniqueSet`,
  /// the analyzer output is byte-identical to the frozen pre-Story-4-7 baseline
  /// for every bundled click fixture. If this fails, HALT-(g) fires — the new
  /// code path is leaking into the default.
  @Test("dspOnlyByteIdenticalWithSuperFluxAbsent (AC #3)")
  func dspOnlyByteIdenticalWithSuperFluxAbsent() async throws {
    let baseline = try loadBaseline()

    for row in baseline.fixtures {
      let url = try AudioFixtures.url(for: row.fixture, extension: row.extension)
      let opts = AudioAnalysisService.Options()
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts),
        "analyzeBPM returned nil — unexpected on bundled click fixture")

      #expect(
        result.bpm.bitPattern == row.bpmBits,
        """
        Byte-identity violation on \(row.fixture).\(row.extension):
        bpm bits \(result.bpm.bitPattern) vs baseline \(row.bpmBits)
        (got=\(result.bpm), captured at SHA \(baseline.capturedAtSHA))
        """)
      #expect(
        result.confidence.bitPattern == row.confidenceBits,
        """
        Byte-identity violation on \(row.fixture).\(row.extension):
        confidence bits \(result.confidence.bitPattern) vs baseline \(row.confidenceBits)
        (got=\(result.confidence), captured at SHA \(baseline.capturedAtSHA))
        """)
    }
  }

  /// AC #3 second half: an explicit `.optimal` techniqueSet (the same one
  /// `AnalysisIntensity.default` resolves to) MUST produce the same
  /// bitPatterns as the default `Options()` path. Proves both code routes
  /// converge on identical analyzer output.
  @Test("explicit .optimal techniqueSet matches default Options() byte-for-byte")
  func optimalEqualsDefault() async throws {
    let baseline = try loadBaseline()

    for row in baseline.fixtures {
      let url = try AudioFixtures.url(for: row.fixture, extension: row.extension)
      var opts = AudioAnalysisService.Options()
      opts.techniqueSet = .optimal
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts),
        "analyzeBPM returned nil — unexpected on bundled click fixture")

      #expect(
        result.bpm.bitPattern == row.bpmBits,
        "\(row.fixture).\(row.extension): explicit .optimal differs from default Options() baseline"
      )
      #expect(result.confidence.bitPattern == row.confidenceBits)
    }
  }

  /// AC #8: with `.superFluxOnset` PRESENT in the technique set, analyzer
  /// output MUST differ from the no-variant baseline on at least one bundled
  /// fixture. Proves the gate actually does something — if this test passes
  /// byte-identity, the integration is broken.
  @Test("dspOnlyDifferentWithSuperFluxPresent (AC #8 / gate-does-something)")
  func dspOnlyDifferentWithSuperFluxPresent() async throws {
    let baseline = try loadBaseline()

    var anyFixtureDiffered = false
    for row in baseline.fixtures {
      let url = try AudioFixtures.url(for: row.fixture, extension: row.extension)
      var opts = AudioAnalysisService.Options()
      opts.techniqueSet = TechniqueSet.optimal.inserting(.superFluxOnset)
      let result = try #require(
        try AudioAnalysisService.analyzeBPM(url: url, options: opts),
        "analyzeBPM returned nil — unexpected on bundled click fixture")

      if result.bpm.bitPattern != row.bpmBits
        || result.confidence.bitPattern != row.confidenceBits
      {
        anyFixtureDiffered = true
        break
      }
    }
    #expect(
      anyFixtureDiffered,
      """
      AC #8 violation: enabling .superFluxOnset produced byte-identical output
      to the no-variant baseline across ALL bundled fixtures. Either the gate
      at BPMAnalyzer.swift step 3 is unconditional in the wrong direction, or
      computeSuperFluxOnsetEnvelope is computing the same envelope as the
      baseline path. See Story 4-7 HALT-(g).
      """)
  }

  /// Codex review 2026-05-17 ADJUST P4b: the bundled-fixture test above is a
  /// "gate is wired in some direction" smoke check, NOT proof that SuperFlux
  /// engages at the replicate-pad-exercised boundary mel-bins. This test uses
  /// a purpose-built fixture (`synthesizeBoundaryBurstFixture`, P5) where the
  /// max-filter MUST produce different output by construction; identical output
  /// here means the gate composition with the rest of the pipeline is broken.
  ///
  /// Runs at the `BPMAnalyzer.estimateBPM` level (one level deeper than the
  /// bundled-fixture smoke test above) because the synthesized fixture is a
  /// `[Float]` sample buffer, not a file. The check is still at the analyzer
  /// scope — gate engagement at the same layer the AC targets.
  @Test("dspOnlyDifferentOnDiscriminatingFixture — purpose-built max-filter engagement")
  func dspOnlyDifferentOnDiscriminatingFixture() async throws {
    let sampleRate: Double = 44100
    let samples = synthesizeBoundaryBurstFixture(
      sampleRate: sampleRate,
      durationSeconds: 8,
      lowCenterHz: 48,
      highCenterHz: 15_600,
      burstIntervalSeconds: 0.05)

    let baselineOpts = BPMAnalyzer.Options(techniqueSet: .optimal)
    let variantOpts = BPMAnalyzer.Options(
      techniqueSet: TechniqueSet.optimal.inserting(.superFluxOnset))

    let baselineResult = try #require(
      BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: sampleRate, options: baselineOpts),
      "baseline BPMAnalyzer.estimateBPM returned nil on synthesized boundary fixture"
    )
    let variantResult = try #require(
      BPMAnalyzer.estimateBPM(
        samples: samples, sampleRate: sampleRate, options: variantOpts),
      "variant BPMAnalyzer.estimateBPM returned nil on synthesized boundary fixture"
    )

    #expect(
      baselineResult.bpm.bitPattern != variantResult.bpm.bitPattern
        || baselineResult.confidence.bitPattern != variantResult.confidence.bitPattern,
      """
      AC #8 STRICT: on a purpose-built boundary-discriminating fixture, the
      SuperFlux variant MUST produce bit-different output from baseline.
      Identical output here means the max-filter is not engaging at the
      replicate-pad boundaries (mel-bin 0 / mel-bin 127) under the rest of the
      analyzer pipeline. P5 validates the fixture energizes these bins; if this
      test fails, the bug is in gate composition, not the fixture.
      """)
  }
}
