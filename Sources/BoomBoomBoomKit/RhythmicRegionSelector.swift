import Foundation

/// A bounded, inexpensive rhythm scan over decoded PCM. The scan reads at most
/// eight regions and at most 64 samples per 10 ms energy bin. It never changes
/// the onset features or the DSP technique used by the selected BPM passes.
enum RhythmicRegionSelector {
  struct Region: Sendable {
    let startSample: Int
    let sampleCount: Int
    let rhythmScore: Float
  }

  static func select(
    samples: [Float], sampleRate: Double, durationSeconds: Double,
    maximumCount: Int
  ) -> [Region] {
    let probes = probeRegions(
      samples: samples, sampleRate: sampleRate, durationSeconds: durationSeconds)
    guard maximumCount > 0 else { return [] }
    // Stable ties favor earlier audio. The evenly spaced probes are disjoint
    // because probeCount never exceeds the number of full region spans.
    return Array(
      probes.sorted {
        if $0.rhythmScore != $1.rhythmScore {
          return $0.rhythmScore > $1.rhythmScore
        }
        return $0.startSample < $1.startSample
      }.prefix(maximumCount)
    ).sorted { $0.startSample < $1.startSample }
  }

  static func probeRegions(
    samples: [Float], sampleRate: Double, durationSeconds: Double
  ) -> [Region] {
    guard !samples.isEmpty, sampleRate.isFinite, sampleRate >= 8_000,
      durationSeconds.isFinite, durationSeconds > 0
    else { return [] }

    let requested = min(durationSeconds, 30)
    let span = min(samples.count, Int(min(requested * sampleRate, Double(samples.count))))
    guard span > 0 else { return [] }
    let probeCount = min(8, max(1, samples.count / span))
    let lastStart = samples.count - span
    let starts: [Int] =
      probeCount == 1
      ? [0]
      : (0..<probeCount).map { $0 * lastStart / (probeCount - 1) }
    return starts.map { start in
      Region(
        startSample: start, sampleCount: span,
        rhythmScore: score(
          samples: samples, start: start, count: span, sampleRate: sampleRate))
    }
  }

  private static func score(
    samples: [Float], start: Int, count: Int, sampleRate: Double
  ) -> Float {
    let binSize = max(1, Int(sampleRate / 100))
    let binCount = count / binSize
    guard binCount >= 100 else { return 0 }
    let sampleStep = max(1, binSize / 64)
    var energy = [Float](repeating: 0, count: binCount)
    for bin in 0..<binCount {
      let base = start + bin * binSize
      var sum: Float = 0
      var taken = 0
      for offset in stride(from: 0, to: binSize, by: sampleStep) {
        sum += abs(samples[base + offset])
        taken += 1
      }
      energy[bin] = sum / Float(taken)
    }
    var onset = [Float](repeating: 0, count: binCount)
    var totalEnergy: Float = 0
    var totalOnset: Float = 0
    for i in 1..<binCount {
      totalEnergy += energy[i]
      onset[i] = max(0, energy[i] - energy[i - 1])
      totalOnset += onset[i]
    }
    guard totalEnergy > 0, totalOnset > 0 else { return 0 }

    // Autocorrelation of positive energy changes measures repeated attacks,
    // independent of absolute level. Centering removes the DC term that lets
    // dense, unpatterned audio appear periodic.
    let mean = totalOnset / Float(binCount)
    let centered = onset.map { $0 - mean }
    let norm = centered.reduce(Float.zero) { $0 + $1 * $1 }
    guard norm > 0 else { return 0 }
    var best: Float = 0
    for lag in 30...100 {  // 60...200 BPM at 100 onset frames per second
      var correlation: Float = 0
      for i in lag..<binCount {
        correlation += centered[i] * centered[i - lag]
      }
      best = max(best, correlation / norm)
    }
    // A very faint but patterned pulse remains eligible, while empty and
    // nearly featureless regions cannot win on a spurious normalized peak.
    let activity = min(1, totalOnset / max(totalEnergy, Float.leastNormalMagnitude) * 8)
    return max(0, best) * activity
  }
}
