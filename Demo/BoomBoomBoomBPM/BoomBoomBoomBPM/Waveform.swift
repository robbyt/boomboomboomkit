import BoomBoomBoomKit
import Foundation

// Peak-envelope extraction for the beat-grid overlay's waveform layer.
//
// The samples come from the LIBRARY's own decoder
// (`PCMBufferReader.readDecodedAudio`), NOT a separate AVFoundation read, so the
// waveform shares the exact decoded-PCM time origin and sample rate the beat
// grid was tracked against — codec encoder priming is already removed
// identically on both paths, and `maxSeconds` is sanitized the same way. That
// guarantees a beat tick at `t` seconds lands over the same audio the analyzer
// saw at `t` seconds.
//
// `nonisolated` because the project defaults to `MainActor` isolation, but these
// pure functions are called from the detached analysis task (off the main
// actor) — and they touch no shared mutable state.
nonisolated enum Waveform {

  /// Folds `samples` into at most `columns` max-absolute-amplitude buckets.
  ///
  /// - Returns `[]` for empty input or `columns <= 0`.
  /// - When `samples.count < columns`, returns exactly `samples.count` peaks
  ///   (one per sample) rather than padding with zero columns — the caller
  ///   scales by `duration`, so a short clip stays honest.
  static func peaks(fromSamples samples: [Float], columns: Int) -> [Float] {
    // A predicate that never fires cannot throw.
    (try? peaks(fromSamples: samples, columns: columns, isCancelled: { false })) ?? []
  }

  /// ``peaks(fromSamples:columns:)`` that checks `isCancelled` once per column
  /// and throws `CancellationError` when it returns `true`.
  static func peaks(
    fromSamples samples: [Float], columns: Int, isCancelled: () -> Bool
  ) throws -> [Float] {
    guard columns > 0, !samples.isEmpty else { return [] }
    let n = samples.count
    let cols = min(columns, n)
    var out = [Float](repeating: 0, count: cols)
    for c in 0..<cols {
      if isCancelled() { throw CancellationError() }
      // Integer bucket bounds; the last bucket's `end` reaches exactly `n`.
      let start = c * n / cols
      let end = (c + 1) * n / cols
      var peak: Float = 0
      var i = start
      while i < end {
        let a = abs(samples[i])
        if a > peak { peak = a }
        i += 1
      }
      out[c] = peak
    }
    return out
  }

  /// Decodes `url` through the library decoder and returns the peak envelope
  /// plus the decoded duration in seconds. Throws `PCMBufferReaderError` if the
  /// file cannot be read; the caller treats this as best-effort and renders the
  /// grid without a waveform on failure.
  ///
  /// `isCancelled` is checked between the reader's chunks of about 10 s and
  /// once per peak column; `true` throws `CancellationError`, so a Cancel stops
  /// a long decode instead of waiting for the whole span.
  static func decode(
    url: URL, maxSeconds: Double, columns: Int, isCancelled: @Sendable () -> Bool
  ) throws -> (peaks: [Float], duration: Double) {
    let decoded = try PCMBufferReader.readDecodedAudio(
      from: url, maxSeconds: maxSeconds, isCancelled: isCancelled)
    let duration =
      decoded.sampleRate > 0 ? Double(decoded.samples.count) / decoded.sampleRate : 0
    let envelope = try peaks(
      fromSamples: decoded.samples, columns: columns, isCancelled: isCancelled)
    return (envelope, duration)
  }
}
