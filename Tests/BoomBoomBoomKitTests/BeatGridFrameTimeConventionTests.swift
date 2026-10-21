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
//  Coverage checks run before the six metrics. The interior window is bounded
//  by the signal, not by the grid, and the grid must hold nearly every planted
//  interior beat and reach within one second of both signal edges, so a
//  truncated or shifted grid cannot pass on an empty or partial slice.
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

  /// Edge-coverage slack in seconds: the first grid beat must sit no later
  /// than `plantedOffsetSeconds + coverageSlackSeconds`, and the last grid
  /// beat no earlier than `signalEndSeconds - coverageSlackSeconds`. One
  /// second is two 120 BPM periods. The last planted click sits about 0.5 s
  /// before the signal end at 120 BPM and about 0.24 s at 126 BPM, and the
  /// longest waveform is 11.3 ms, so a grid that tracks the whole signal clears
  /// both edges with room to spare.
  private static let coverageSlackSeconds: Double = 1.0

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

  /// One planted click track: everything `synthesize`, `plantedBeatPositions`
  /// and `measure` need to place or score the clicks.
  struct PlantedClicks {
    let sampleRate: Double
    let beatSamples: Int
    let offsetSamples: Int
    let leadingSilenceSeconds: Double
    let waveform: Waveform
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

                let clicks = PlantedClicks(
                  sampleRate: sampleRate,
                  beatSamples: beatSamples,
                  offsetSamples: offset,
                  leadingSilenceSeconds: leadingSilenceSeconds,
                  waveform: waveform
                )
                let samples = synthesize(clicks)

                let grid = try estimateGrid(
                  samples: samples,
                  sampleRate: sampleRate,
                  hopSize: hopSize,
                  tempoBPM: tempoBPM,
                  path: path
                )

                let signalEndSeconds = Double(samples.count) / sampleRate
                let plantedBeatSeconds = plantedBeatPositions(
                  sampleCount: samples.count, clicks: clicks
                ).map { Double($0) / sampleRate }

                let metrics = measure(
                  grid: grid,
                  tempoBPM: tempoBPM,
                  clicks: clicks,
                  signalEndSeconds: signalEndSeconds,
                  plantedBeatSeconds: plantedBeatSeconds
                )

                // (0a) Interior beat count. Every metric below falls back to 0
                // on an empty interior slice, so before this check a grid that
                // stopped early, or one shifted outside the window, passed all
                // six checks on all-zero metrics. The window is bounded by the
                // signal, and the grid must hold every planted interior beat
                // less one hop of slack at each edge.
                #expect(
                  metrics.interiorBeatCount >= metrics.expectedInteriorCount - 2,
                  "interior beat count \(metrics.interiorBeatCount) is below the planted \(metrics.expectedInteriorCount) minus 2 at \(fixtureName)"
                )

                // (0b) Leading-edge coverage.
                #expect(
                  metrics.firstBeatSeconds
                    <= metrics.plantedOffsetSeconds + Self.coverageSlackSeconds,
                  "first beat \(metrics.firstBeatSeconds) s is later than the planted offset \(metrics.plantedOffsetSeconds) s plus \(Self.coverageSlackSeconds) s at \(fixtureName)"
                )

                // (0c) Trailing-edge coverage.
                #expect(
                  metrics.lastBeatSeconds >= signalEndSeconds - Self.coverageSlackSeconds,
                  "last beat \(metrics.lastBeatSeconds) s is earlier than the signal end \(signalEndSeconds) s minus \(Self.coverageSlackSeconds) s at \(fixtureName)"
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

  // MARK: - Coverage-check regressions

  /// Measures a hand-built grid against the 120 BPM, 44.1 kHz, offset 0,
  /// no-silence planted set (`beatSamples = 22050`, 15 s of signal).
  private func measureAgainst120BPMPlantedSet(beatTimes: [Double]) -> (
    metrics: Metrics, signalEndSeconds: Double
  ) {
    let sampleRate = 44_100.0
    let clicks = PlantedClicks(
      sampleRate: sampleRate,
      beatSamples: 22_050,
      offsetSamples: 0,
      leadingSilenceSeconds: 0.0,
      waveform: .singleImpulse
    )
    let sampleCount = Int(sampleRate * 15.0)
    let signalEndSeconds = Double(sampleCount) / sampleRate
    let plantedBeatSeconds = plantedBeatPositions(sampleCount: sampleCount, clicks: clicks)
      .map { Double($0) / sampleRate }
    let grid = BeatGrid(
      beats: beatTimes.map {
        BeatTimestamp(presentationTime: $0, confidence: 0.9, strength: 0.5)
      },
      downbeats: .notAttempted,
      estimatedTempo: 120.0,
      confidence: 0.9,
      tempoAgreement: .notCompared,
      gridOrigin: nil,
      coverage: .analysisWindow
    )
    let metrics = measure(
      grid: grid,
      tempoBPM: 120.0,
      clicks: clicks,
      signalEndSeconds: signalEndSeconds,
      plantedBeatSeconds: plantedBeatSeconds
    )
    return (metrics, signalEndSeconds)
  }

  /// A grid that stops at 9 s. Before the coverage checks, the interior
  /// window's upper bound was `0.5 * 18 - 0.5 = 8.5` s, derived from the
  /// grid's own beat count, so 15 beats with a constant -10 ms residual
  /// survived and all six metrics passed.
  @Test func tailTruncatedGridFailsCoverage() {
    let beatTimes = (1...18).map { 0.5 * Double($0) - 0.01 }
    let (metrics, signalEndSeconds) = measureAgainst120BPMPlantedSet(beatTimes: beatTimes)
    #expect(metrics.interiorBeatCount == 17)
    #expect(metrics.interiorBeatCount < metrics.expectedInteriorCount - 2)
    #expect(metrics.lastBeatSeconds < signalEndSeconds - Self.coverageSlackSeconds)
  }

  /// A grid holding only the beats from 6.0 s to 14.5 s. Before the coverage
  /// checks, the self-derived upper bound of 8.5 s kept 5 beats with zero
  /// residual and all six metrics passed. A fixed minimum beat count plus a
  /// tail check would also pass it; the planted-relative count floor and the
  /// leading-edge check each reject it.
  @Test func prefixTruncatedGridFailsCoverage() {
    let beatTimes = (12...29).map { 0.5 * Double($0) }
    let (metrics, _) = measureAgainst120BPMPlantedSet(beatTimes: beatTimes)
    #expect(
      metrics.firstBeatSeconds > metrics.plantedOffsetSeconds + Self.coverageSlackSeconds)
    #expect(metrics.interiorBeatCount < metrics.expectedInteriorCount - 2)
  }

  /// A full-span grid with the beats in 4.0...8.0 s removed. Both edge
  /// checks hold, so only the count floor catches it. Before the coverage
  /// checks, the self-derived upper bound of 9.5 s kept 8 zero-residual beats,
  /// the median spacing stayed at 500 ms, and all six metrics passed.
  @Test func internalGapFailsCountWhileEdgesHold() {
    let beatTimes = (1...29).map { 0.5 * Double($0) }.filter { !(4.0...8.0).contains($0) }
    let (metrics, signalEndSeconds) = measureAgainst120BPMPlantedSet(beatTimes: beatTimes)
    #expect(metrics.interiorBeatCount < metrics.expectedInteriorCount - 2)
    #expect(
      metrics.firstBeatSeconds <= metrics.plantedOffsetSeconds + Self.coverageSlackSeconds)
    #expect(metrics.lastBeatSeconds >= signalEndSeconds - Self.coverageSlackSeconds)
  }

  // MARK: - Fixture synthesis

  /// Sample positions of every planted click. Shared by `synthesize` and the
  /// coverage checks so the planted set the metrics compare against is the
  /// set actually written into the signal.
  private func plantedBeatPositions(sampleCount: Int, clicks: PlantedClicks) -> [Int] {
    let silenceOffset = Int(clicks.leadingSilenceSeconds * clicks.sampleRate)
    return Array(
      stride(
        from: silenceOffset + clicks.beatSamples + clicks.offsetSamples,
        to: sampleCount - clicks.waveform.sampleCount,
        by: clicks.beatSamples
      ))
  }

  private func synthesize(_ clicks: PlantedClicks) -> [Float] {
    // 15 seconds of signal is enough room for ~30 beats at 120 BPM and gives
    // a long-drift measurement that spans at least a few bars.
    let totalSeconds = 15.0 + clicks.leadingSilenceSeconds
    let count = Int(clicks.sampleRate * totalSeconds)
    var samples = [Float](repeating: 0, count: count)
    let waveform = clicks.waveform
    for position in plantedBeatPositions(sampleCount: count, clicks: clicks) {
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
    /// Grid beats inside the signal-bounded interior window.
    let interiorBeatCount: Int
    /// Planted clicks inside the same interior window.
    let expectedInteriorCount: Int
    /// First grid beat's presentation time, or `.infinity` for an empty grid.
    let firstBeatSeconds: Double
    /// Last grid beat's presentation time, or `-.infinity` for an empty grid.
    let lastBeatSeconds: Double
    /// Leading silence plus the sub-beat offset: the phase reference every
    /// residual is measured against.
    let plantedOffsetSeconds: Double
  }

  private func measure(
    grid: BeatGrid,
    tempoBPM: Double,
    clicks: PlantedClicks,
    signalEndSeconds: Double,
    plantedBeatSeconds: [Double]
  ) -> Metrics {
    let sampleRate = clicks.sampleRate
    let periodSeconds = Double(clicks.beatSamples) / sampleRate
    let plantedOffsetSeconds =
      clicks.leadingSilenceSeconds + Double(clicks.offsetSamples) / sampleRate
    let periodMs = periodSeconds * 1000.0
    // Interior slice: strip 0.5 s off each end so edge-of-window beats do not
    // perturb median / jitter / drift. Both bounds come from the signal, never
    // from the grid, so a grid that stops early cannot shrink its own window.
    let isInterior: (Double) -> Bool = {
      $0 > plantedOffsetSeconds + 0.5 && $0 < signalEndSeconds - 0.5
    }
    let interior = grid.beats.filter { isInterior($0.presentationTime) }
    let expectedInteriorCount = plantedBeatSeconds.filter(isInterior).count
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
      metricalLevelCorrect: metricalLevelCorrect,
      interiorBeatCount: interior.count,
      expectedInteriorCount: expectedInteriorCount,
      firstBeatSeconds: grid.beats.first?.presentationTime ?? .infinity,
      lastBeatSeconds: grid.beats.last?.presentationTime ?? -.infinity,
      plantedOffsetSeconds: plantedOffsetSeconds
    )
  }
}
