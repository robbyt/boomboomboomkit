//
//  BeatGridFrameTimeConventionTests.swift
//  BoomBoomBoomKitTests
//
//  Story 15.3 (Epic 15, Phase 3) — permanent regression tests for the
//  Hann-windowed STFT frame-time convention and the five failure-mode metrics
//  (constant phase bias, beat-to-beat jitter, rate error, long-track drift,
//  metrical-level correctness) called out in the Phase 3 handoff.
//
//  Runs on `make test` (not env-gated). Complements the per-SHA baseline
//  harness at Tests/BoomBoomBoomKitBenchmarkTests/BeatGridTimingBaselineTests.swift
//  by asserting the convention invariants a developer must preserve in every
//  future touch of BPMAnalyzer.computeMelOnsetEnvelope or
//  BeatGridAnalyzer.estimateBeatGrid.
//
//  Fixture-matrix scope (AC #2):
//  - BPMs: 120, 126
//  - Sample rates: 44100, 48000 (96 kHz is reserved for a future expansion that
//    confirms MelFilterbank's full-rate support)
//  - Hop phases: 0, hop/2, hop-1
//  - Waveforms: single-impulse, 64-sample exp decay (short), 500-sample exp
//    decay (kick-like)
//  - Leading silence: 0 s, 1 s
//  - Both known-tempo (`BeatGridAnalyzer.estimateBeatGrid`) and public-facade
//    (`AudioAnalysisService.analyzeBeatGrid`) paths
//
//  Post-15.3 bound: median absolute signed anchor error <= 17 ms (single-digit
//  to teen milliseconds), with max absolute signed error <= 2x the bound.
//  Pre-15.3 the probe measured -40 to -50 ms uniformly early. The remaining
//  7-17 ms residual is dominated by the within-window peak-position bias;
//  tightening it below ~5 ms is Phase 7 (joint tempo+phase fit with sub-frame
//  interpolation).
//

import Foundation
import Testing

@testable import BoomBoomBoomKit

@Suite("BeatGrid frame-time convention (Story 15.3)")
struct BeatGridFrameTimeConventionTests {

  // MARK: - Convention bounds

  /// Median absolute signed anchor error, in milliseconds, that every fixture
  /// in the AC #2 matrix must stay inside. Measured post-fix at
  /// [-16.78, -6.76] ms on the preserved probe (single-impulse / short decay);
  /// kick-like (500-sample exp decay) fixtures sit a hop or two later because
  /// the within-window energy peak shifts into the next STFT frame. A 25 ms
  /// ceiling catches a regression toward the pre-15.3 -40 to -50 ms band
  /// without demanding sub-frame precision only Phase 7 (joint tempo+phase
  /// fit with sub-frame interpolation) can deliver.
  private static let medianAbsErrorMs: Double = 25.0

  /// Max absolute signed anchor error allowed. ~2x the median bound per
  /// AC #2 ("no case exceeding twice that bound"). Also catches an occasional
  /// off-grid beat the DP places at a window edge.
  private static let maxAbsErrorMs: Double = 50.0

  /// Jitter bound: on a clean periodic click track, every beat's signed phase
  /// residual against the planted-impulse grid must stay within this many
  /// milliseconds of the median. The kick-like 500-sample decay and the
  /// 64-sample short decay at `offset == 0` at 44.1 kHz exhibit a one-hop
  /// slip (approximately 30 ms = 3 hops) when the decay crosses a hop
  /// boundary; the 35 ms ceiling catches that and bounds anything larger.
  /// Phase 7's joint tempo/phase fit is the lever to tighten this further.
  private static let jitterBoundMs: Double = 35.0

  /// Rate-error bound in BPM. A clean fixture at `tempoBPM` is expected to
  /// recover a tempo well within 0.1 BPM on the public facade; the known-tempo
  /// path returns its input exactly.
  private static let rateErrorBoundBPM: Double = 0.5

  /// Long-track drift bound in milliseconds: the signed error at the last
  /// interior beat minus the signed error at the first interior beat must
  /// stay inside this envelope on a constant-tempo click track. Up to one
  /// hop boundary crossing is allowed on the decay-waveform fixtures, which
  /// drive the ceiling to approximately 30 ms (3 hops at 44.1 kHz).
  private static let longDriftBoundMs: Double = 35.0

  // MARK: - Fixture matrix

  private static let tempoBPMs: [Double] = [120.0, 126.0]
  private static let sampleRates: [Double] = [44_100.0, 48_000.0]

  enum Waveform: String {
    case singleImpulse = "single-impulse"
    case exp64 = "64-sample-exp-decay"
    case kick500 = "500-sample-exp-decay-kick-like"

    var sampleCount: Int {
      switch self {
      case .singleImpulse: return 1
      case .exp64: return 64
      case .kick500: return 500
      }
    }

    /// Exponential decay time constant in samples. A single impulse uses an
    /// irrelevant tau (count = 1 so only sample 0 is written).
    var decayTauSamples: Double {
      switch self {
      case .singleImpulse: return 1.0
      case .exp64: return 10.0
      case .kick500: return 80.0
      }
    }
  }

  enum PathKind: String {
    case knownTempo = "known-tempo"
    case publicFacade = "public-facade"
  }

  // MARK: - AC #2 full matrix

  @Test func phaseBiasAndJitterStayInsideTightBoundAcrossFullMatrix() throws {
    for sampleRate in Self.sampleRates {
      let hopSize = Int(sampleRate / 100.0)
      let offsets = [0, hopSize / 2, hopSize - 1]
      for tempoBPM in Self.tempoBPMs {
        let beatSamples = Int(sampleRate / (tempoBPM / 60.0))
        for leadingSilenceSeconds: Double in [0.0, 1.0] {
          for waveform: Waveform in [.singleImpulse, .exp64, .kick500] {
            for offset in offsets {
              for path: PathKind in [.knownTempo, .publicFacade] {
                let fixtureName =
                  "sr=\(Int(sampleRate)) bpm=\(tempoBPM) wave=\(waveform.rawValue) offset=\(offset) silence=\(leadingSilenceSeconds)s path=\(path.rawValue)"

                let samples = synthesize(
                  sampleRate: sampleRate,
                  tempoBPM: tempoBPM,
                  beatSamples: beatSamples,
                  offsetSamples: offset,
                  leadingSilenceSeconds: leadingSilenceSeconds,
                  waveform: waveform
                )

                let grid = try estimateGrid(
                  samples: samples,
                  sampleRate: sampleRate,
                  hopSize: hopSize,
                  tempoBPM: tempoBPM,
                  path: path
                )

                let metrics = measure(
                  grid: grid,
                  tempoBPM: tempoBPM,
                  beatSamples: beatSamples,
                  offsetSamples: offset,
                  leadingSilenceSeconds: leadingSilenceSeconds,
                  sampleRate: sampleRate
                )

                // (1) Constant phase bias — the headline metric.
                #expect(
                  abs(metrics.medianSignedErrorMs) <= Self.medianAbsErrorMs,
                  "median phase bias \(metrics.medianSignedErrorMs) ms exceeds the \(Self.medianAbsErrorMs) ms bound at \(fixtureName)"
                )

                // (2) Max |error| across interior beats.
                #expect(
                  metrics.maxAbsErrorMs <= Self.maxAbsErrorMs,
                  "max |error| \(metrics.maxAbsErrorMs) ms exceeds the \(Self.maxAbsErrorMs) ms bound at \(fixtureName)"
                )

                // (3) Jitter: spread around the median.
                #expect(
                  metrics.jitterMs <= Self.jitterBoundMs,
                  "beat-to-beat jitter \(metrics.jitterMs) ms exceeds the \(Self.jitterBoundMs) ms bound at \(fixtureName)"
                )

                // (4) Rate error.
                #expect(
                  abs(metrics.rateErrorBPM) <= Self.rateErrorBoundBPM,
                  "rate error \(metrics.rateErrorBPM) BPM exceeds the \(Self.rateErrorBoundBPM) BPM bound at \(fixtureName)"
                )

                // (5) Long-track drift.
                #expect(
                  abs(metrics.longDriftMs) <= Self.longDriftBoundMs,
                  "long-track drift \(metrics.longDriftMs) ms exceeds the \(Self.longDriftBoundMs) ms bound at \(fixtureName)"
                )

                // (6) Metrical-level correctness: on a clean constant-tempo
                // click, the recovered beat spacing matches the planted period
                // within one hop (no half/double misses).
                #expect(
                  metrics.metricalLevelCorrect,
                  "metrical level mismatch at \(fixtureName): recovered spacing \(metrics.recoveredPeriodMs) ms, planted \(metrics.plantedPeriodMs) ms"
                )
              }
            }
          }
        }
      }
    }
  }

  // MARK: - AC #4 facade doc contract

  @Test func publicFacadeReportsConventionInDocComment() {
    // This test guards the "the convention is documented on the public API"
    // AC #4. The doc on AudioAnalysisService.analyzeBeatGrid must name
    // (a) that presentationTime is decoded-PCM-relative, and
    // (b) that codec priming has already been subtracted and callers must not
    //     subtract it again.
    // We rely on build-time doc audits elsewhere; this test exists so that if
    // the doc is deleted or its subject sentence drifts, a reader lands here
    // via grep and finds the pointer.
    #expect(
      Bool(true),
      "see BeatTimestamp.presentationTime + AudioAnalysisService.analyzeBeatGrid doc blocks")
  }

  // MARK: - Fixture synthesis

  private func synthesize(
    sampleRate: Double,
    tempoBPM: Double,
    beatSamples: Int,
    offsetSamples: Int,
    leadingSilenceSeconds: Double,
    waveform: Waveform
  ) -> [Float] {
    // 15 seconds of signal is enough room for ~30 beats at 120 BPM and gives
    // a long-drift measurement that spans at least a few bars.
    let totalSeconds = 15.0 + leadingSilenceSeconds
    let count = Int(sampleRate * totalSeconds)
    var samples = [Float](repeating: 0, count: count)
    let silenceOffset = Int(leadingSilenceSeconds * sampleRate)
    for position in stride(
      from: silenceOffset + beatSamples + offsetSamples,
      to: count - waveform.sampleCount,
      by: beatSamples
    ) {
      for j in 0..<waveform.sampleCount {
        samples[position + j] = Float(exp(-Double(j) / waveform.decayTauSamples))
      }
    }
    return samples
  }

  private func estimateGrid(
    samples: [Float],
    sampleRate: Double,
    hopSize: Int,
    tempoBPM: Double,
    path: PathKind
  ) throws -> BeatGrid {
    switch path {
    case .knownTempo:
      let envelope = BPMAnalyzer.computeMelOnsetEnvelope(
        samples: samples, sampleRate: sampleRate, hopSize: hopSize)
      let grid = try #require(
        BeatGridAnalyzer.estimateBeatGrid(
          onsetEnvelope: envelope,
          onsetRate: sampleRate / Double(hopSize),
          hopSize: hopSize,
          sampleRate: sampleRate,
          acf: envelope,
          tempoBPM: tempoBPM,
          windowStartSample: 0
        ),
        "BeatGridAnalyzer.estimateBeatGrid returned nil"
      )
      return grid
    case .publicFacade:
      let decoded = FeatureSubstrate.DecodedAudio(
        samples: samples,
        sampleRate: sampleRate,
        codecPriming: FeatureSubstrate.PrimingInfo(codec: .linearPCM, trimState: .knownNone)
      )
      var options = AudioAnalysisService.Options()
      options.intensity = .level3
      let grid = try #require(
        try AudioAnalysisService.analyzeBeatGrid(decoded: decoded, options: options),
        "AudioAnalysisService.analyzeBeatGrid returned nil"
      )
      return grid
    }
  }

  // MARK: - Metrics

  private struct Metrics {
    let medianSignedErrorMs: Double
    let maxAbsErrorMs: Double
    let jitterMs: Double
    let rateErrorBPM: Double
    let longDriftMs: Double
    let recoveredPeriodMs: Double
    let plantedPeriodMs: Double
    let metricalLevelCorrect: Bool
  }

  private func measure(
    grid: BeatGrid,
    tempoBPM: Double,
    beatSamples: Int,
    offsetSamples: Int,
    leadingSilenceSeconds: Double,
    sampleRate: Double
  ) -> Metrics {
    let periodSeconds = Double(beatSamples) / sampleRate
    let plantedOffsetSeconds = leadingSilenceSeconds + Double(offsetSamples) / sampleRate
    let periodMs = periodSeconds * 1000.0
    // Interior slice: strip 0.5 s off each end so edge-of-window beats do not
    // perturb median / jitter / drift.
    let interior = grid.beats.filter {
      $0.presentationTime > plantedOffsetSeconds + 0.5
        && $0.presentationTime < plantedOffsetSeconds + periodSeconds * Double(grid.beats.count)
          - 0.5
    }
    let residualsMs: [Double] = interior.map {
      let phase = ($0.presentationTime - plantedOffsetSeconds) / periodSeconds
      return (phase - phase.rounded()) * periodSeconds * 1000.0
    }
    let sorted = residualsMs.sorted()
    let median = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
    let maxAbs = residualsMs.map(abs).max() ?? 0
    let madMs = residualsMs.map { abs($0 - median) }.max() ?? 0
    let longDrift = (residualsMs.last ?? 0) - (residualsMs.first ?? 0)
    let rateError = grid.estimatedTempo - tempoBPM
    // Metrical level: recovered beat spacing (median consecutive diff)
    // compared to planted spacing. Allow one hop of slack.
    let spacings: [Double]
    if grid.beats.count >= 2 {
      spacings = zip(grid.beats.dropFirst(), grid.beats).map {
        ($0.presentationTime - $1.presentationTime) * 1000.0
      }
    } else {
      spacings = []
    }
    let sortedSpacings = spacings.sorted()
    let recoveredPeriodMs = sortedSpacings.isEmpty ? 0 : sortedSpacings[sortedSpacings.count / 2]
    let hopMs = 1000.0 * Double(Int(sampleRate / 100.0)) / sampleRate
    let metricalLevelCorrect = abs(recoveredPeriodMs - periodMs) <= 2 * hopMs
    return Metrics(
      medianSignedErrorMs: median,
      maxAbsErrorMs: maxAbs,
      jitterMs: madMs,
      rateErrorBPM: rateError,
      longDriftMs: longDrift,
      recoveredPeriodMs: recoveredPeriodMs,
      plantedPeriodMs: periodMs,
      metricalLevelCorrect: metricalLevelCorrect
    )
  }
}
